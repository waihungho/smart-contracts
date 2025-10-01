This smart contract, **"Decentralized Adaptive Skill Passport (DASP)"**, introduces an innovative concept of a soulbound ERC-721 NFT that serves as an individual's evolving, verifiable skill and reputation profile. It dynamically adapts based on on-chain actions, oracle-verified external proofs, and peer endorsements, with skills potentially decaying over time to reflect relevance. This passport can then be used to grant access or privileges within other decentralized applications based on attained skill levels.

---

### **Outline and Function Summary**

**Core Concept:** A non-transferable (soulbound) NFT that represents a user's skill profile. This profile updates dynamically based on various inputs (on-chain activity, verified off-chain proofs, peer endorsements) and can decay over time. It provides verifiable on-chain proof of expertise and can gate access to DApps or services.

**I. Core DASP Management (ERC-721 Soulbound)**
*   **`mintSkillPassport(address _owner, string calldata _initialCategoryName)`**: Creates a new soulbound passport for a specified address.
*   **`getPassportDetails(uint256 _tokenId)`**: Retrieves comprehensive details of a passport, including its owner, active skills, and their levels.
*   **`revokeSkillPassport(uint256 _tokenId)`**: Allows either the passport owner or an authorized administrator to revoke (burn) a passport.
*   **`tokenURI(uint256 _tokenId)`**: Dynamically generates a data URI (base64 encoded JSON) for the NFT metadata, reflecting its current skill levels, badges, and status.
*   **`hasPassport(address _user)`**: Checks if a given address currently possesses an active DASP.

**II. Skill Definition & Configuration**
*   **`defineSkillCategory(bytes32 _skillId, string calldata _name, string calldata _description, bool _decayEnabled)`**: (Admin) Defines a new skill category, its description, and whether its points will decay over time.
*   **`setSkillLevelThresholds(bytes32 _skillId, uint256[] calldata _thresholds)`**: (Admin) Sets the point thresholds required to achieve each successive level for a specific skill.
*   **`updateSkillCategory(bytes32 _skillId, string calldata _newName, string calldata _newDescription, bool _newDecayEnabled)`**: (Admin) Modifies the name, description, or decay status of an existing skill category.
*   **`setSkillDecayRate(bytes32 _skillId, uint256 _decayRatePerBlock)`**: (Admin) Configures the rate at which points for a specific skill decay per block.

**III. Skill Point Accumulation & Decay**
*   **`addSkillPoints(uint256 _tokenId, bytes32 _skillId, uint256 _points)`**: (Authorized Verifier/Oracle) Adds a specified amount of points to a particular skill for a given passport. This can trigger a level-up.
*   **`requestProofVerification(uint256 _tokenId, bytes32 _skillId, string calldata _proofUrl, bytes32 _proofHash) payable`**: Allows a user to submit an off-chain proof (e.g., a link to a certificate or work) for verification, paying a fee.
*   **`fulfillProofVerification(uint256 _requestId, uint256 _awardedPoints, bytes32 _proofHash, string calldata _ipfsMetadataHash)`**: (Oracle) Callback function to award points to a skill after an external proof has been successfully verified.
*   **`endorseSkill(uint256 _passportId, bytes32 _skillId, string calldata _justification)`**: Allows users to endorse another user's skill, providing a small point boost and recording the endorsement. Subject to a cooldown.
*   **`triggerPassportSkillDecay(uint256 _tokenId)`**: Any user can call this function to process the decay of all decay-enabled skills for a specific passport, based on the last update block and configured decay rates.

**IV. Skill-Based Access & Reputation**
*   **`getSkillLevel(uint256 _tokenId, bytes32 _skillId)`**: Retrieves the current level of a specific skill for a given passport.
*   **`isPassportQualified(uint256 _tokenId, bytes32 _skillId, uint256 _minLevel)`**: Checks if a passport meets or exceeds a minimum required skill level for a specific skill.
*   **`defineAccessRole(bytes32 _roleId, string calldata _roleName, bytes32 _requiredSkillId, uint256 _requiredLevel)`**: (Admin) Defines a named access role that is contingent upon a specific skill reaching a minimum level.
*   **`grantAccessBadge(uint256 _tokenId, bytes32 _roleId)`**: Grants an internal "access badge" to a passport if it meets the requirements of a defined access role. This can be used by other DApps for permissioning.

**V. Oracle & System Configuration**
*   **`setOracleAddress(address _newOracleAddress)`**: (Admin) Updates the address of the trusted oracle responsible for verifying off-chain proofs.
*   **`setVerificationFee(uint256 _fee)`**: (Admin) Sets the fee required for users to submit proof verification requests.
*   **`setEndorsementCooldown(uint256 _seconds)`**: (Admin) Configures the time period an endorser must wait before endorsing the same skill again.

**VI. Administrative & Treasury**
*   **`pause()`**: (Admin) Temporarily halts core functionalities of the contract in case of emergencies or upgrades.
*   **`unpause()`**: (Admin) Resumes normal contract operations after a pause.
*   **`withdrawFees()`**: (Admin) Allows the contract owner to withdraw accumulated verification fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title Decentralized Adaptive Skill Passport (DASP)
 * @dev An ERC-721 Soulbound NFT representing an individual's evolving skill profile.
 *      Skills gain points and level up based on on-chain actions, oracle-verified external proofs,
 *      and peer endorsements. Skills can also decay over time.
 *      The passport can grant access to DApps based on attained skill levels.
 *
 * Outline and Function Summary:
 *
 * Core Concept: A non-transferable (soulbound) NFT that represents a user's skill profile.
 * It updates dynamically based on various inputs (on-chain activity, verified off-chain proofs,
 * peer endorsements) and can decay over time. It provides verifiable on-chain proof of expertise
 * and can gate access to DApps or services.
 *
 * I. Core DASP Management (ERC-721 Soulbound)
 *   1.  `mintSkillPassport(address _owner, string calldata _initialCategoryName)`: Creates a new soulbound passport for a specified address.
 *   2.  `getPassportDetails(uint256 _tokenId)`: Retrieves comprehensive details of a passport (owner, active skills, levels).
 *   3.  `revokeSkillPassport(uint256 _tokenId)`: Allows owner or admin to revoke (burn) a passport.
 *   4.  `tokenURI(uint256 _tokenId)`: Dynamically generates data URI for NFT metadata, reflecting current skill levels and badges.
 *   5.  `hasPassport(address _user)`: Checks if an address has an active DASP.
 *
 * II. Skill Definition & Configuration
 *   6.  `defineSkillCategory(bytes32 _skillId, string calldata _name, string calldata _description, bool _decayEnabled)`: (Admin) Defines a new skill category, description, and if it decays.
 *   7.  `setSkillLevelThresholds(bytes32 _skillId, uint256[] calldata _thresholds)`: (Admin) Sets point thresholds for each level of a skill.
 *   8.  `updateSkillCategory(bytes32 _skillId, string calldata _newName, string calldata _newDescription, bool _newDecayEnabled)`: (Admin) Modifies existing skill metadata.
 *   9.  `setSkillDecayRate(bytes32 _skillId, uint256 _decayRatePerBlock)`: (Admin) Configures the rate at which points for a specific skill decay per block.
 *
 * III. Skill Point Accumulation & Decay
 *   10. `addSkillPoints(uint256 _tokenId, bytes32 _skillId, uint256 _points)`: (Authorized Verifier/Oracle) Adds points to a specific skill for a passport. Can trigger level-up.
 *   11. `requestProofVerification(uint256 _tokenId, bytes32 _skillId, string calldata _proofUrl, bytes32 _proofHash) payable`: User submits off-chain proof for verification, paying a fee.
 *   12. `fulfillProofVerification(uint256 _requestId, uint256 _awardedPoints, bytes32 _proofHash, string calldata _ipfsMetadataHash)`: (Oracle) Callback to award points after external proof verification.
 *   13. `endorseSkill(uint256 _passportId, bytes32 _skillId, string calldata _justification)`: Users can endorse another user's skill, providing a small point boost and recording the endorsement. Subject to cooldown.
 *   14. `triggerPassportSkillDecay(uint256 _tokenId)`: Allows anyone to process the decay of all decay-enabled skills for a specific passport.
 *
 * IV. Skill-Based Access & Reputation
 *   15. `getSkillLevel(uint256 _tokenId, bytes32 _skillId)`: Retrieves the current level of a specific skill for a passport.
 *   16. `isPassportQualified(uint256 _tokenId, bytes32 _skillId, uint256 _minLevel)`: Checks if a passport meets or exceeds a minimum skill level.
 *   17. `defineAccessRole(bytes32 _roleId, string calldata _roleName, bytes32 _requiredSkillId, uint256 _requiredLevel)`: (Admin) Defines a named access role contingent upon a specific skill reaching a minimum level.
 *   18. `grantAccessBadge(uint256 _tokenId, bytes32 _roleId)`: Grants an internal "access badge" if a passport meets the requirements of a defined access role.
 *
 * V. Oracle & System Configuration
 *   19. `setOracleAddress(address _newOracleAddress)`: (Admin) Updates the address of the trusted oracle.
 *   20. `setVerificationFee(uint256 _fee)`: (Admin) Sets the fee required for proof verification requests.
 *   21. `setEndorsementCooldown(uint256 _seconds)`: (Admin) Configures the time period an endorser must wait before endorsing the same skill again.
 *
 * VI. Administrative & Treasury
 *   22. `pause()`: (Admin) Temporarily halts core functionalities.
 *   23. `unpause()`: (Admin) Resumes normal contract operations.
 *   24. `withdrawFees()`: (Admin) Allows the contract owner to withdraw accumulated verification fees.
 */
contract DecentralizedAdaptiveSkillPassport is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- Structs ---

    struct Skill {
        string name;
        string description;
        bool decayEnabled;
        uint256[] levelThresholds; // Points required for level 1, level 2, ...
        uint256 decayRatePerBlock; // How many points decay per block (0 if decayEnabled is false)
    }

    struct PassportSkill {
        uint256 points;
        uint256 lastUpdateBlock; // Block number when points were last added or decay was applied
    }

    struct ProofVerificationRequest {
        uint256 tokenId;
        bytes32 skillId;
        string proofUrl;
        bytes32 proofHash;
        address requester;
        bool fulfilled;
        uint256 timestamp;
    }

    struct Endorsement {
        address endorser;
        string justification;
        uint256 timestamp;
    }

    struct AccessRole {
        string name;
        bytes32 requiredSkillId;
        uint256 requiredLevel;
    }

    // --- State Variables & Mappings ---

    // NFT Management
    uint256 private _nextTokenId; // Counter for unique token IDs
    mapping(uint256 => address) public passportOwners; // tokenId => owner address (redundant with ERC721 but useful for direct lookup)
    mapping(address => uint256) public userPassports; // owner address => tokenId (each user gets only one DASP)
    mapping(uint256 => bytes32[]) public passportActiveSkills; // tokenId => array of active skillIds

    // Skill Definitions
    mapping(bytes32 => Skill) public skills; // skillId => Skill struct
    bytes32[] public allSkillIds; // Array of all defined skill IDs

    // Passport Skill Data
    mapping(uint256 => mapping(bytes32 => PassportSkill)) public passportSkills; // tokenId => skillId => PassportSkill struct

    // Proof Verification
    address public oracleAddress;
    uint256 public verificationFee;
    uint256 public nextRequestId;
    mapping(uint256 => ProofVerificationRequest) public verificationRequests; // requestId => ProofVerificationRequest struct

    // Endorsements
    uint256 public endorsementCooldownSeconds;
    mapping(uint256 => mapping(bytes32 => Endorsement[])) public skillEndorsements; // tokenId => skillId => array of endorsements
    mapping(address => mapping(uint256 => uint256)) public lastEndorsementTimestamp; // endorser => tokenId => timestamp

    // Access Roles
    mapping(bytes32 => AccessRole) public accessRoles; // roleId => AccessRole struct
    mapping(uint256 => mapping(bytes32 => bool)) public hasAccessBadge; // tokenId => roleId => bool

    // --- Events ---

    event PassportMinted(uint256 indexed tokenId, address indexed owner, bytes32 initialSkillId);
    event PassportRevoked(uint256 indexed tokenId, address indexed owner);
    event SkillPointsAdded(uint256 indexed tokenId, bytes32 indexed skillId, uint256 pointsAdded, address indexed by);
    event SkillLevelUp(uint256 indexed tokenId, bytes32 indexed skillId, uint256 oldLevel, uint256 newLevel);
    event SkillDecayed(uint256 indexed tokenId, bytes32 indexed skillId, uint256 oldPoints, uint256 newPoints);
    event ProofVerificationRequested(uint256 indexed requestId, uint256 indexed tokenId, bytes32 indexed skillId, string proofUrl);
    event ProofVerificationFulfilled(uint256 indexed requestId, uint256 indexed tokenId, bytes32 indexed skillId, uint256 awardedPoints);
    event SkillEndorsed(uint256 indexed passportId, bytes32 indexed skillId, address indexed endorser, string justification);
    event AccessBadgeGranted(uint256 indexed tokenId, bytes32 indexed roleId);
    event SkillCategoryDefined(bytes32 indexed skillId, string name, bool decayEnabled);
    event SkillCategoryUpdated(bytes32 indexed skillId, string name, bool decayEnabled);
    event OracleAddressUpdated(address indexed newOracle);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "DASP: Only oracle can call this function");
        _;
    }

    modifier onlyVerifier() {
        // For 'addSkillPoints', we can expand this to include a dedicated verifier role if needed
        require(msg.sender == oracleAddress || msg.sender == owner(), "DASP: Only authorized verifier or owner can add points");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address _initialOracle) ERC721(name, symbol) Ownable(msg.sender) {
        oracleAddress = _initialOracle;
        verificationFee = 0.01 ether; // Default verification fee
        endorsementCooldownSeconds = 1 days; // Default endorsement cooldown
        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- I. Core DASP Management (ERC-721 Soulbound) ---

    /**
     * @dev Prevents transfer of DASP tokens, making them soulbound.
     * Overrides ERC721's _beforeTokenTransfer to revert if not minting or burning.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("DASP: Passports are soulbound and cannot be transferred.");
        }
        // Allows minting (from == address(0)) and burning (to == address(0))
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Mints a new soulbound skill passport for a given address. Each address can only have one passport.
     * @param _owner The address to whom the passport will be minted.
     * @param _initialCategoryName The name of the initial skill category to assign points to (e.g., "Web3 Basic").
     */
    function mintSkillPassport(address _owner, string calldata _initialCategoryName) public whenNotPaused onlyOwner {
        require(_owner != address(0), "DASP: Cannot mint to zero address");
        require(userPassports[_owner] == 0, "DASP: Address already has a passport");

        uint256 tokenId = _nextTokenId++;
        _mint(_owner, tokenId);

        passportOwners[tokenId] = _owner;
        userPassports[_owner] = tokenId;

        bytes32 initialSkillId = keccak256(abi.encodePacked(_initialCategoryName));
        require(skills[initialSkillId].name != "", "DASP: Initial skill category does not exist.");

        passportSkills[tokenId][initialSkillId] = PassportSkill({
            points: 1, // Start with 1 point
            lastUpdateBlock: block.number
        });
        passportActiveSkills[tokenId].push(initialSkillId);

        emit PassportMinted(tokenId, _owner, initialSkillId);
    }

    /**
     * @dev Retrieves comprehensive details of a skill passport.
     * @param _tokenId The ID of the skill passport.
     * @return owner Address of the passport owner.
     * @return currentActiveSkills Array of active skill IDs.
     */
    function getPassportDetails(uint256 _tokenId) public view returns (address owner, bytes32[] memory currentActiveSkills) {
        owner = passportOwners[_tokenId];
        currentActiveSkills = passportActiveSkills[_tokenId];
        return (owner, currentActiveSkills);
    }

    /**
     * @dev Allows the passport owner or contract owner to revoke (burn) a skill passport.
     * @param _tokenId The ID of the skill passport to revoke.
     */
    function revokeSkillPassport(uint256 _tokenId) public whenNotPaused {
        address currentOwner = ownerOf(_tokenId);
        require(msg.sender == currentOwner || msg.sender == owner(), "DASP: Only passport owner or contract owner can revoke.");

        _burn(_tokenId);
        delete passportOwners[_tokenId];
        delete userPassports[currentOwner];
        // Note: Skill data and endorsements are retained for historical record, but the passport itself is gone.
        // For a full data purge, additional logic would be needed.

        emit PassportRevoked(_tokenId, currentOwner);
    }

    /**
     * @dev Checks if an address has an active skill passport.
     * @param _user The address to check.
     * @return True if the address has a passport, false otherwise.
     */
    function hasPassport(address _user) public view returns (bool) {
        return userPassports[_user] != 0;
    }

    /**
     * @dev Generates the dynamic metadata URI for a given token ID.
     * The metadata includes the passport's name, description, image, and its current skills with levels.
     * @param _tokenId The ID of the NFT.
     * @return A base64 encoded JSON string representing the NFT metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        address owner = passportOwners[_tokenId];
        string memory name = string(abi.encodePacked("Skill Passport #", _tokenId.toString()));
        string memory description = string(abi.encodePacked("Decentralized Adaptive Skill Passport for ", Strings.toHexString(uint160(owner), 20), "."));
        string memory image = "ipfs://Qmbn3HhW9Xq6Q9T9R2Y9Z9J9K9L9M9N9O9P9Q9R9S9T9"; // Placeholder IPFS image hash

        string memory skillsJson = "[";
        bytes32[] memory activeSkillIds = passportActiveSkills[_tokenId];
        for (uint256 i = 0; i < activeSkillIds.length; i++) {
            bytes32 skillId = activeSkillIds[i];
            Skill storage s = skills[skillId];
            uint256 level = getSkillLevel(_tokenId, skillId);
            skillsJson = string(abi.encodePacked(
                skillsJson,
                '{"trait_type": "', s.name, '", "value": "Level ', level.toString(), ' (', passportSkills[_tokenId][skillId].points.toString(), ' points)"}',
                (i == activeSkillIds.length - 1 ? "" : ",")
            ));
        }
        skillsJson = string(abi.encodePacked(skillsJson, "]"));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"owner": "', Strings.toHexString(uint160(owner), 20), '",',
            '"attributes": ', skillsJson,
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- II. Skill Definition & Configuration ---

    /**
     * @dev Defines a new skill category that can be associated with passports.
     * @param _skillId A unique identifier for the skill (e.g., keccak256("web3_dev")).
     * @param _name The human-readable name of the skill.
     * @param _description A detailed description of the skill.
     * @param _decayEnabled Whether points for this skill should decay over time.
     */
    function defineSkillCategory(bytes32 _skillId, string calldata _name, string calldata _description, bool _decayEnabled) public onlyOwner whenNotPaused {
        require(skills[_skillId].name == "", "DASP: Skill with this ID already exists.");
        require(bytes(_name).length > 0, "DASP: Skill name cannot be empty.");

        skills[_skillId] = Skill({
            name: _name,
            description: _description,
            decayEnabled: _decayEnabled,
            levelThresholds: new uint256[](0), // Initialize empty
            decayRatePerBlock: 0 // Default, can be set later
        });
        allSkillIds.push(_skillId);

        emit SkillCategoryDefined(_skillId, _name, _decayEnabled);
    }

    /**
     * @dev Sets the point thresholds for each level of a specific skill.
     * E.g., `[10, 50, 200]` means Level 1 requires 10 points, Level 2 requires 50, Level 3 requires 200.
     * @param _skillId The ID of the skill.
     * @param _thresholds An array of point thresholds for each level. Must be strictly increasing.
     */
    function setSkillLevelThresholds(bytes32 _skillId, uint256[] calldata _thresholds) public onlyOwner whenNotPaused {
        require(skills[_skillId].name != "", "DASP: Skill does not exist.");
        for (uint256 i = 0; i < _thresholds.length; i++) {
            if (i > 0) {
                require(_thresholds[i] > _thresholds[i - 1], "DASP: Thresholds must be strictly increasing.");
            }
        }
        skills[_skillId].levelThresholds = _thresholds;
    }

    /**
     * @dev Updates the name, description, or decay status of an existing skill category.
     * @param _skillId The ID of the skill to update.
     * @param _newName The new human-readable name of the skill.
     * @param _newDescription The new detailed description of the skill.
     * @param _newDecayEnabled The new decay status of the skill.
     */
    function updateSkillCategory(bytes32 _skillId, string calldata _newName, string calldata _newDescription, bool _newDecayEnabled) public onlyOwner whenNotPaused {
        require(skills[_skillId].name != "", "DASP: Skill does not exist.");
        require(bytes(_newName).length > 0, "DASP: Skill name cannot be empty.");

        skills[_skillId].name = _newName;
        skills[_skillId].description = _newDescription;
        skills[_skillId].decayEnabled = _newDecayEnabled;

        emit SkillCategoryUpdated(_skillId, _newName, _newDecayEnabled);
    }

    /**
     * @dev Sets the decay rate for a specific skill.
     * Only applies if `decayEnabled` is true for the skill.
     * @param _skillId The ID of the skill.
     * @param _decayRatePerBlock The number of points to decay per block.
     */
    function setSkillDecayRate(bytes32 _skillId, uint256 _decayRatePerBlock) public onlyOwner whenNotPaused {
        require(skills[_skillId].name != "", "DASP: Skill does not exist.");
        skills[_skillId].decayRatePerBlock = _decayRatePerBlock;
    }

    // --- III. Skill Point Accumulation & Decay ---

    /**
     * @dev Adds points to a specific skill for a given passport. This function also handles skill decay.
     * Can be called by the oracle or contract owner (acting as a verifier).
     * @param _tokenId The ID of the passport.
     * @param _skillId The ID of the skill to update.
     * @param _points The number of points to add.
     */
    function addSkillPoints(uint256 _tokenId, bytes32 _skillId, uint256 _points) public onlyVerifier whenNotPaused {
        require(_exists(_tokenId), "DASP: Passport does not exist.");
        require(skills[_skillId].name != "", "DASP: Skill does not exist.");

        // First, apply any pending decay
        _applySkillDecay(_tokenId, _skillId);

        PassportSkill storage ps = passportSkills[_tokenId][_skillId];
        uint256 oldLevel = getSkillLevel(_tokenId, _skillId);
        uint256 oldPoints = ps.points;

        ps.points += _points;
        ps.lastUpdateBlock = block.number;

        uint256 newLevel = getSkillLevel(_tokenId, _skillId);

        if (ps.points == _points && oldPoints == 0) { // If it's the first time points are added for this skill
            bool found = false;
            for(uint i = 0; i < passportActiveSkills[_tokenId].length; i++) {
                if (passportActiveSkills[_tokenId][i] == _skillId) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                passportActiveSkills[_tokenId].push(_skillId);
            }
        }


        emit SkillPointsAdded(_tokenId, _skillId, _points, msg.sender);
        if (newLevel > oldLevel) {
            emit SkillLevelUp(_tokenId, _skillId, oldLevel, newLevel);
        }
    }

    /**
     * @dev Allows a user to submit an off-chain proof for verification, paying a fee.
     * The oracle will then review and call `fulfillProofVerification`.
     * @param _tokenId The ID of the passport requesting verification.
     * @param _skillId The ID of the skill this proof relates to.
     * @param _proofUrl A URL pointing to the proof (e.g., certificate link, project repo).
     * @param _proofHash A hash of the proof content for integrity verification by the oracle.
     */
    function requestProofVerification(
        uint256 _tokenId,
        bytes32 _skillId,
        string calldata _proofUrl,
        bytes32 _proofHash
    ) public payable whenNotPaused {
        require(_exists(_tokenId), "DASP: Passport does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "DASP: Only passport owner can request verification.");
        require(skills[_skillId].name != "", "DASP: Skill does not exist.");
        require(msg.value >= verificationFee, "DASP: Insufficient verification fee.");

        uint256 requestId = nextRequestId++;
        verificationRequests[requestId] = ProofVerificationRequest({
            tokenId: _tokenId,
            skillId: _skillId,
            proofUrl: _proofUrl,
            proofHash: _proofHash,
            requester: msg.sender,
            fulfilled: false,
            timestamp: block.timestamp
        });

        emit ProofVerificationRequested(requestId, _tokenId, _skillId, _proofUrl);
    }

    /**
     * @dev Callback function used by the oracle to fulfill a proof verification request.
     * Awards points to the specified skill upon successful verification.
     * @param _requestId The ID of the proof verification request.
     * @param _awardedPoints The number of points to award for the verified proof.
     * @param _proofHash The hash of the proof provided by the oracle (for verification against original request).
     * @param _ipfsMetadataHash An optional IPFS hash for a richer, immutable record of the verification.
     */
    function fulfillProofVerification(
        uint256 _requestId,
        uint256 _awardedPoints,
        bytes32 _proofHash,
        string calldata _ipfsMetadataHash // Can store a hash of a JSON file with full verification details
    ) public onlyOracle whenNotPaused {
        ProofVerificationRequest storage req = verificationRequests[_requestId];
        require(!req.fulfilled, "DASP: Request already fulfilled.");
        require(req.proofHash == _proofHash, "DASP: Proof hash mismatch."); // Ensure oracle verified the correct proof

        req.fulfilled = true;
        // Optionally, store _ipfsMetadataHash in the request or a separate mapping for auditability.

        addSkillPoints(req.tokenId, req.skillId, _awardedPoints); // Use addSkillPoints for level-up logic
        emit ProofVerificationFulfilled(_requestId, req.tokenId, req.skillId, _awardedPoints);
    }

    /**
     * @dev Allows a user to endorse another user's skill, adding a small amount of points and a record.
     * Subject to a cooldown period to prevent spam.
     * @param _passportId The ID of the passport being endorsed.
     * @param _skillId The ID of the skill being endorsed.
     * @param _justification A brief explanation for the endorsement.
     */
    function endorseSkill(uint256 _passportId, bytes32 _skillId, string calldata _justification) public whenNotPaused {
        require(_exists(_passportId), "DASP: Passport does not exist.");
        require(skills[_skillId].name != "", "DASP: Skill does not exist.");
        require(msg.sender != ownerOf(_passportId), "DASP: Cannot endorse your own passport.");
        require(block.timestamp >= lastEndorsementTimestamp[msg.sender][_passportId] + endorsementCooldownSeconds,
            "DASP: Endorsement cooldown active for this passport.");

        // Add a small fixed amount of points for endorsement
        addSkillPoints(_passportId, _skillId, 1); // Each endorsement adds 1 point

        skillEndorsements[_passportId][_skillId].push(Endorsement({
            endorser: msg.sender,
            justification: _justification,
            timestamp: block.timestamp
        }));
        lastEndorsementTimestamp[msg.sender][_passportId] = block.timestamp;

        emit SkillEndorsed(_passportId, _skillId, msg.sender, _justification);
    }

    /**
     * @dev Triggers the decay calculation for all decay-enabled skills on a given passport.
     * Anyone can call this to ensure passport skill data is up-to-date.
     * @param _tokenId The ID of the passport to process decay for.
     */
    function triggerPassportSkillDecay(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "DASP: Passport does not exist.");

        bytes32[] memory activeSkills = passportActiveSkills[_tokenId];
        for (uint256 i = 0; i < activeSkills.length; i++) {
            _applySkillDecay(_tokenId, activeSkills[i]);
        }
    }

    /**
     * @dev Internal function to apply decay to a specific skill on a passport.
     * @param _tokenId The ID of the passport.
     * @param _skillId The ID of the skill.
     */
    function _applySkillDecay(uint256 _tokenId, bytes32 _skillId) internal {
        Skill storage s = skills[_skillId];
        PassportSkill storage ps = passportSkills[_tokenId][_skillId];

        if (s.decayEnabled && s.decayRatePerBlock > 0 && ps.points > 0 && ps.lastUpdateBlock < block.number) {
            uint256 blocksSinceLastUpdate = block.number - ps.lastUpdateBlock;
            uint256 decayAmount = blocksSinceLastUpdate * s.decayRatePerBlock;

            uint256 oldPoints = ps.points;
            if (decayAmount >= ps.points) {
                ps.points = 0;
            } else {
                ps.points -= decayAmount;
            }
            ps.lastUpdateBlock = block.number; // Update last update block after decay

            if (oldPoints != ps.points) {
                emit SkillDecayed(_tokenId, _skillId, oldPoints, ps.points);
            }
        }
    }

    // --- IV. Skill-Based Access & Reputation ---

    /**
     * @dev Retrieves the current level of a specific skill for a given passport.
     * Automatically applies any pending decay before returning the level.
     * @param _tokenId The ID of the passport.
     * @param _skillId The ID of the skill.
     * @return The current level of the skill (0 if no points or skill doesn't exist).
     */
    function getSkillLevel(uint256 _tokenId, bytes32 _skillId) public view returns (uint256) {
        // Use a temporary variable for PassportSkill to apply decay logic without modifying storage in a view function
        PassportSkill memory currentPs = passportSkills[_tokenId][_skillId];
        Skill storage s = skills[_skillId];

        if (s.decayEnabled && s.decayRatePerBlock > 0 && currentPs.points > 0 && currentPs.lastUpdateBlock < block.number) {
            uint256 blocksSinceLastUpdate = block.number - currentPs.lastUpdateBlock;
            uint256 decayAmount = blocksSinceLastUpdate * s.decayRatePerBlock;
            if (decayAmount >= currentPs.points) {
                currentPs.points = 0;
            } else {
                currentPs.points -= decayAmount;
            }
        }

        if (currentPs.points == 0) {
            return 0;
        }

        uint256 level = 0;
        for (uint256 i = 0; i < s.levelThresholds.length; i++) {
            if (currentPs.points >= s.levelThresholds[i]) {
                level = i + 1; // Level 1 for 0th threshold, Level 2 for 1st, etc.
            } else {
                break;
            }
        }
        return level;
    }

    /**
     * @dev Checks if a passport meets a minimum skill level requirement.
     * @param _tokenId The ID of the passport.
     * @param _skillId The ID of the required skill.
     * @param _minLevel The minimum required level.
     * @return True if the passport qualifies, false otherwise.
     */
    function isPassportQualified(uint256 _tokenId, bytes32 _skillId, uint256 _minLevel) public view returns (bool) {
        return getSkillLevel(_tokenId, _skillId) >= _minLevel;
    }

    /**
     * @dev Defines a new access role linked to a specific skill and minimum level.
     * These roles can be used by external DApps to grant conditional access.
     * @param _roleId A unique identifier for the access role.
     * @param _roleName The human-readable name of the role.
     * @param _requiredSkillId The ID of the skill required for this role.
     * @param _requiredLevel The minimum level of the required skill.
     */
    function defineAccessRole(bytes32 _roleId, string calldata _roleName, bytes32 _requiredSkillId, uint256 _requiredLevel) public onlyOwner whenNotPaused {
        require(accessRoles[_roleId].name == "", "DASP: Access role with this ID already exists.");
        require(skills[_requiredSkillId].name != "", "DASP: Required skill does not exist.");
        require(bytes(_roleName).length > 0, "DASP: Role name cannot be empty.");

        accessRoles[_roleId] = AccessRole({
            name: _roleName,
            requiredSkillId: _requiredSkillId,
            requiredLevel: _requiredLevel
        });
    }

    /**
     * @dev Grants an internal "access badge" to a passport if it meets the requirements of a defined access role.
     * This badge is an on-chain flag that other DApps can check.
     * @param _tokenId The ID of the passport.
     * @param _roleId The ID of the access role to grant.
     */
    function grantAccessBadge(uint256 _tokenId, bytes32 _roleId) public whenNotPaused {
        require(_exists(_tokenId), "DASP: Passport does not exist.");
        require(accessRoles[_roleId].name != "", "DASP: Access role does not exist.");
        require(ownerOf(_tokenId) == msg.sender || msg.sender == owner(), "DASP: Only passport owner or contract owner can grant badges.");

        AccessRole storage role = accessRoles[_roleId];
        require(isPassportQualified(_tokenId, role.requiredSkillId, role.requiredLevel), "DASP: Passport does not meet role requirements.");
        require(!hasAccessBadge[_tokenId][_roleId], "DASP: Passport already has this access badge.");

        hasAccessBadge[_tokenId][_roleId] = true;
        emit AccessBadgeGranted(_tokenId, _roleId);
    }

    // --- V. Oracle & System Configuration ---

    /**
     * @dev Sets the address of the trusted oracle. Only callable by the contract owner.
     * @param _newOracleAddress The new address for the oracle.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "DASP: Oracle address cannot be zero.");
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @dev Sets the fee required for users to submit proof verification requests.
     * @param _fee The new verification fee in Wei.
     */
    function setVerificationFee(uint256 _fee) public onlyOwner {
        verificationFee = _fee;
    }

    /**
     * @dev Sets the cooldown period (in seconds) for skill endorsements.
     * @param _seconds The new cooldown duration in seconds.
     */
    function setEndorsementCooldown(uint256 _seconds) public onlyOwner {
        endorsementCooldownSeconds = _seconds;
    }

    // --- VI. Administrative & Treasury ---

    /**
     * @dev Pauses the contract. Only callable by the contract owner.
     * Prevents most state-changing operations during emergencies or upgrades.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the contract owner.
     * Resumes normal operations.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated verification fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "DASP: No fees to withdraw.");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "DASP: Failed to withdraw fees.");
    }

    // --- Helper Views ---

    /**
     * @dev Returns all endorsement records for a specific skill on a passport.
     * @param _passportId The ID of the passport.
     * @param _skillId The ID of the skill.
     * @return An array of Endorsement structs.
     */
    function getSkillEndorsements(uint256 _passportId, bytes32 _skillId) public view returns (Endorsement[] memory) {
        return skillEndorsements[_passportId][_skillId];
    }
}
```