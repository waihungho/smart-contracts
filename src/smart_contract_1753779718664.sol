The following Solidity smart contract, `SkillBoundProtocol`, introduces a unique concept centered around dynamic, non-transferable Soulbound Tokens (SBTs) that represent a user's on-chain skills, achievements, and contributions within the Web3 ecosystem. It integrates gamification elements, a community-driven challenge system, and an attestation mechanism.

**Core Advanced Concepts & Trendy Features:**

1.  **Soulbound Tokens (SBTs):** Implements a non-transferable ERC-721 token representing a user's digital identity and accumulated skills, aligning with the "soulbound" concept.
2.  **Dynamic NFTs/Metadata:** The SBT's metadata (`tokenURI`) is designed to be dynamic, evolving based on the owner's achievements (Skill Modules, Proficiency Points, Mastery Levels). This requires an off-chain metadata server that queries the contract for the latest data.
3.  **On-chain Reputation & Gamification:**
    *   **Skill Modules:** Defines categories of skills (e.g., "DeFi Architect," "Solidity Grandmaster").
    *   **Proficiency Points:** Earned by completing challenges or direct contribution, tracked per skill module.
    *   **Mastery Levels:** Calculated dynamically based on proficiency points within a module, providing a progression path.
    *   **Overall Reputation Score:** An aggregated metric reflecting a user's total contributions.
4.  **Decentralized Challenge & Attestation System:**
    *   **Challenges:** Community-creatable tasks with defined reward points, potentially requiring manual verification.
    *   **Attestation:** A designated role (`Attester`) can verify challenge completions, adding a layer of trust and decentralization to achievement validation. This implies the need for off-chain proof verification (e.g., via IPFS links or APIs).
5.  **Role-Based Access Control:** Simple roles for contract `Owner` and `Attester` to manage critical functions and facilitate decentralized verification.

---

### **Outline and Function Summary**

**Contract Name:** `SkillBoundProtocol`

**Purpose:** A decentralized protocol for dynamic, non-transferable Soulbound Tokens (SBTs) representing on-chain skills, achievements, and contributions within Web3.

**I. Core SBT Management (ERC721 compliant, but non-transferable)**

1.  `mintPersonaSBT(address _to)`: Mints a new non-transferable Soulbound Token (SBT) for a user. An address can only mint one SBT.
2.  `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an SBT. This URI typically points to a JSON file (on IPFS or an API endpoint) that describes the SBT's current state (skills, mastery levels, etc.).
3.  `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: An internal override from ERC721 that prevents any token transfers, enforcing the soulbound nature.
4.  `getPersonaSBTId(address _owner)`: Retrieves the SBT ID associated with an owner's address.

**II. Skill Module Management**

5.  `createSkillModule(string memory _name, string memory _description, uint256 _requiredPointsForMastery, uint256 _masteryLevelsCount)`: Creates a new skill category (e.g., "Solidity Development"). Callable only by the contract owner.
6.  `updateSkillModule(uint256 _moduleId, string memory _newName, string memory _newDescription, uint256 _newRequiredPoints, uint256 _newMasteryLevelsCount, bool _isActive)`: Updates an existing skill module's properties. Callable only by the contract owner.
7.  `getSkillModuleDetails(uint256 _moduleId)`: Retrieves comprehensive details about a specific skill module. (View function)

**III. Challenge & Attestation System**

8.  `createChallenge(uint256 _moduleId, string memory _name, string memory _description, uint256 _rewardPoints, bool _requiresAttestation)`: Defines a new on-chain or off-chain verifiable challenge that contributes to a skill module. Callable only by the contract owner.
9.  `updateChallenge(uint256 _challengeId, uint256 _moduleId, string memory _newName, string memory _newDescription, uint256 _newRewardPoints, bool _newRequiresAttestation, bool _isActive)`: Modifies an existing challenge's properties. Callable only by the contract owner.
10. `getChallengeDetails(uint256 _challengeId)`: Fetches details of a specific challenge. (View function)
11. `submitChallengeCompletion(uint256 _personaSBTId, uint256 _challengeId, string memory _proofURI)`: Allows a user to submit proof for a completed challenge. If attestation is not required, points are awarded immediately; otherwise, it enters a pending state.
12. `attestChallengeCompletion(uint256 _completionId, bool _isVerified)`: A designated attester verifies a submitted challenge completion. If verified, proficiency points are awarded. Callable only by addresses with the attester role.
13. `getChallengeCompletionDetails(uint256 _completionId)`: Retrieves details about a specific challenge completion submission. (View function)
14. `getPendingChallengeCompletions()`: Lists all challenge completions that are currently awaiting attestation. (View function)

**IV. Proficiency & Mastery Progression**

15. `_awardProficiencyPoints(uint256 _personaSBTId, uint256 _moduleId, uint256 _points)`: An internal function used to award proficiency points to an SBT for a specific skill module (primarily called by `attestChallengeCompletion`).
16. `getProficiencyPoints(uint256 _personaSBTId, uint256 _moduleId)`: Returns the current proficiency points for an SBT in a specific skill module. (View function)
17. `getCurrentMasteryLevel(uint256 _personaSBTId, uint256 _moduleId)`: Dynamically calculates the current mastery level based on accumulated proficiency points within a module. (View function)
18. `getAllSkillProficiencies(uint256 _personaSBTId)`: Returns a list of all skill modules and their respective proficiency points for an SBT. (View function)
19. `calculateOverallReputation(uint256 _personaSBTId)`: Aggregates proficiency points across all modules into an overall reputation score. (View function)

**V. Dynamic Metadata & Configuration**

20. `setBaseURI(string memory _newBaseURI)`: Sets the base URI for NFT metadata. This URI will be prefixed to the token ID to form the full metadata URI for `tokenURI`. Callable only by the contract owner.
21. `getPersonaMetadata(uint256 _personaSBTId)`: A helper function that provides the raw on-chain data necessary for an off-chain service to generate the dynamic SBT metadata JSON. (View function)

**VI. Access Control & Utility**

22. `grantAttesterRole(address _attester)`: Grants the attester role to an address, allowing them to verify challenge completions. Callable only by the contract owner.
23. `revokeAttesterRole(address _attester)`: Revokes the attester role from an address. Callable only by the contract owner.
24. `hasAttesterRole(address _address)`: Checks if a given address has the attester role. (View function)
25. `pause()`: Pauses certain contract functionalities (e.g., minting, challenge submissions). Callable only by the contract owner. (Inherited from `Pausable`)
26. `unpause()`: Unpauses the contract, resuming normal functionality. Callable only by the contract owner. (Inherited from `Pausable`)
27. `withdrawStuckEth(address _to)`: Allows the contract owner to withdraw any ETH accidentally sent to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom errors for clarity and gas efficiency
error PersonaForge__SBTAlreadyMinted(address owner);
error PersonaForge__SBTNotMinted(address owner); // Used when an address doesn't own an SBT but is expected to.
error PersonaForge__InvalidSBTId(); // Used when an SBT ID doesn't exist or is 0.
error PersonaForge__UnauthorizedAttester();
error PersonaForge__SkillModuleNotFound(uint256 moduleId);
error PersonaForge__ChallengeNotFound(uint256 challengeId);
error PersonaForge__ChallengeNotPending(uint256 completionId);
error PersonaForge__ChallengeAlreadyVerified(uint256 completionId);
error PersonaForge__ModuleNotActive(uint256 moduleId);
error PersonaForge__ChallengeNotActive(uint256 challengeId);
error PersonaForge__CannotTransferSoulboundToken();
error PersonaForge__AttesterCannotBeOwner(); // Prevents owner from also being an attester for clearer role separation.
error PersonaForge__ZeroAddress();
error PersonaForge__WithdrawFailed();
error PersonaForge__InvalidMasteryPointsConfiguration(); // For requiredPointsForMastery == 0 or masteryLevelsCount == 0

/**
 * @title SkillBound Protocol (SBP)
 * @author [Your Name/Alias]
 * @notice A decentralized protocol for dynamic, non-transferable Soulbound Tokens (SBTs)
 *         representing on-chain skills, achievements, and contributions within Web3.
 *         It incorporates gamification through Skill Modules, Proficiency Points, and Mastery Levels,
 *         alongside a community-driven Challenge and Attestation system.
 */
contract SkillBoundProtocol is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---
    // I. Core SBT Management (ERC721 compliant, but non-transferable)
    //    1.  `mintPersonaSBT(address _to)`: Mints a new non-transferable Soulbound Token (SBT) for a user.
    //    2.  `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an SBT, reflecting its current state.
    //    3.  `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: Overrides ERC721 transfer to enforce non-transferability.
    //    4.  `getPersonaSBTId(address _owner)`: Retrieves the SBT ID associated with an owner's address.
    //
    // II. Skill Module Management
    //    5.  `createSkillModule(string memory _name, string memory _description, uint256 _requiredPointsForMastery, uint256 _masteryLevelsCount)`: Creates a new skill category. (Owner-only)
    //    6.  `updateSkillModule(uint256 _moduleId, string memory _newName, string memory _newDescription, uint256 _newRequiredPoints, uint256 _newMasteryLevelsCount, bool _isActive)`: Updates an existing skill module. (Owner-only)
    //    7.  `getSkillModuleDetails(uint256 _moduleId)`: Retrieves comprehensive details about a specific skill module. (View function)
    //
    // III. Challenge & Attestation System
    //    8.  `createChallenge(uint256 _moduleId, string memory _name, string memory _description, uint256 _rewardPoints, bool _requiresAttestation)`: Defines a new on-chain or off-chain verifiable challenge. (Owner-only)
    //    9.  `updateChallenge(uint256 _challengeId, uint256 _moduleId, string memory _newName, string memory _newDescription, uint256 _newRewardPoints, bool _newRequiresAttestation, bool _isActive)`: Modifies an existing challenge. (Owner-only)
    //    10. `getChallengeDetails(uint256 _challengeId)`: Fetches details of a specific challenge. (View function)
    //    11. `submitChallengeCompletion(uint256 _personaSBTId, uint256 _challengeId, string memory _proofURI)`: Allows a user to submit proof for a completed challenge.
    //    12. `attestChallengeCompletion(uint256 _completionId, bool _isVerified)`: A designated attester verifies a submitted challenge completion, awarding points upon success. (Attester-only)
    //    13. `getChallengeCompletionDetails(uint256 _completionId)`: Retrieves details about a specific challenge completion submission. (View function)
    //    14. `getPendingChallengeCompletions()`: Lists all challenge completions awaiting attestation. (View function)
    //
    // IV. Proficiency & Mastery Progression
    //    15. `_awardProficiencyPoints(uint256 _personaSBTId, uint256 _moduleId, uint256 _points)`: Internal function to award proficiency points. Called by `attestChallengeCompletion`.
    //    16. `getProficiencyPoints(uint256 _personaSBTId, uint256 _moduleId)`: Returns current proficiency points for an SBT in a specific skill module. (View function)
    //    17. `getCurrentMasteryLevel(uint256 _personaSBTId, uint256 _moduleId)`: Calculates the current mastery level based on accumulated proficiency points. (View function)
    //    18. `getAllSkillProficiencies(uint256 _personaSBTId)`: Returns a list of all skill modules and their respective proficiency points for an SBT. (View function)
    //    19. `calculateOverallReputation(uint256 _personaSBTId)`: Aggregates proficiency points across all modules into an overall reputation score. (View function)
    //
    // V. Dynamic Metadata & Configuration
    //    20. `setBaseURI(string memory _newBaseURI)`: Sets the base URI for NFT metadata, used by `tokenURI`. (Owner-only)
    //    21. `getPersonaMetadata(uint256 _personaSBTId)`: Helper function providing the raw data for generating dynamic SBT metadata. (View function)
    //
    // VI. Access Control & Utility
    //    22. `grantAttesterRole(address _attester)`: Grants the attester role to an address. (Owner-only)
    //    23. `revokeAttesterRole(address _attester)`: Revokes the attester role from an address. (Owner-only)
    //    24. `hasAttesterRole(address _address)`: Checks if an address has the attester role. (View function)
    //    25. `pause()`: Pauses certain contract functionalities (e.g., minting, challenge submissions). (Owner-only)
    //    26. `unpause()`: Unpauses the contract. (Owner-only)
    //    27. `withdrawStuckEth(address _to)`: Allows the owner to withdraw any accidentally sent ETH. (Owner-only)

    // --- Struct Definitions ---
    struct SkillModule {
        uint256 id;
        string name;
        string description;
        uint256 requiredPointsForMastery; // Total points needed to reach the highest mastery level
        uint256 masteryLevelsCount;       // Number of distinct mastery levels (e.g., 5 levels)
        bool isActive;                    // Indicates if the module is currently active and can accrue points
    }

    struct Challenge {
        uint256 id;
        uint256 moduleId;          // Which skill module this challenge contributes to
        string name;
        string description;
        uint256 rewardPoints;
        bool requiresAttestation;   // Does this challenge need manual verification?
        bool isActive;              // Indicates if the challenge is currently active and can be submitted
    }

    struct ChallengeCompletion {
        uint256 id;
        uint256 challengeId;
        uint256 personaSBTId;
        string proofURI;            // Link to off-chain proof (e.g., IPFS CID, GitHub URL)
        bool isVerified;            // True if attester verified it (or auto-verified)
        bool isPending;             // True if awaiting attestation
        address submitter;
        uint256 submittedAt;
        uint256 verifiedAt;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _skillModuleIdCounter;
    Counters.Counter private _challengeIdCounter;
    Counters.Counter private _challengeCompletionIdCounter;

    // Mapping from owner address to their Persona SBT ID
    mapping(address => uint256) private _ownerToSBTId;
    // Mapping from SBT ID to its owner address (for reverse lookup, crucial for dynamic metadata)
    mapping(uint256 => address) private _sbtIdToOwner;

    // Skill Module Data: moduleId => SkillModule
    mapping(uint256 => SkillModule) private _skillModules;
    // Array to store all created skill module IDs for iteration
    uint256[] private _allSkillModuleIds;

    // Challenge Data: challengeId => Challenge
    mapping(uint256 => Challenge) private _challenges;

    // Challenge Completion Data: completionId => ChallengeCompletion
    mapping(uint256 => ChallengeCompletion) private _challengeCompletions;
    // List of challenge completion IDs that are currently awaiting attestation
    uint256[] private _pendingChallengeCompletions;

    // Persona Proficiency: sbtId => moduleId => points
    mapping(uint256 => mapping(uint256 => uint256)) private _personaSkillProficiency;

    // Role-based access control for Attesters
    mapping(address => bool) private _isAttester;

    // Base URI for dynamic metadata (e.g., "https://api.example.com/sbt/")
    string private _baseURI;

    // --- Events ---
    event PersonaSBTMinted(uint256 indexed tokenId, address indexed owner);
    event SkillModuleCreated(uint256 indexed moduleId, string name, address indexed creator);
    event SkillModuleUpdated(uint256 indexed moduleId, string newName, bool isActive);
    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed moduleId, string name, uint256 rewardPoints);
    event ChallengeUpdated(uint256 indexed challengeId, string newName, bool isActive);
    event ChallengeSubmitted(uint256 indexed completionId, uint256 indexed personaSBTId, uint256 indexed challengeId);
    event ChallengeAttested(uint256 indexed completionId, uint256 indexed personaSBTId, uint256 indexed challengeId, bool isVerified, address indexed attester);
    event ProficiencyPointsAwarded(uint256 indexed personaSBTId, uint256 indexed moduleId, uint256 points);
    event AttesterRoleGranted(address indexed attester, address indexed granter);
    event AttesterRoleRevoked(address indexed attester, address indexed revoker);

    /**
     * @dev Initializes the contract. Sets the ERC721 name and symbol.
     *      The deployer is automatically granted the owner role from Ownable.
     */
    constructor() ERC721("PersonaForge SBT", "PF-SBT") Ownable(msg.sender) {}

    // --- I. Core SBT Management ---

    /**
     * @notice Mints a new non-transferable Soulbound Token (SBT) for a specified address.
     *         An address can only mint one Persona SBT.
     * @param _to The address to mint the SBT for.
     */
    function mintPersonaSBT(address _to) external whenNotPaused {
        if (_to == address(0)) revert PersonaForge__ZeroAddress();
        if (_ownerToSBTId[_to] != 0) revert PersonaForge__SBTAlreadyMinted(_to);

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_to, newItemId); // Mints the ERC721 token

        _ownerToSBTId[_to] = newItemId;
        _sbtIdToOwner[newItemId] = _to;

        emit PersonaSBTMinted(newItemId, _to);
    }

    /**
     * @notice Overrides the default ERC721 transfer mechanism to prevent transfers,
     *         making the tokens soulbound. Allows minting (from == address(0)) and burning (to == address(0)).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert PersonaForge__CannotTransferSoulboundToken();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice Returns the dynamic metadata URI for a given Persona SBT.
     *         This URI typically points to a JSON file (on IPFS or an API endpoint)
     *         that describes the SBT's current state (skills, mastery levels, etc.).
     * @param _tokenId The ID of the Persona SBT.
     * @return A string representing the URI to the metadata JSON.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert PersonaForge__InvalidSBTId();
        // Assumes an off-chain server will serve dynamic JSON at `_baseURI/{tokenId}.json`
        return string(abi.encodePacked(_baseURI, Strings.toString(_tokenId), ".json"));
    }

    /**
     * @notice Retrieves the Persona SBT ID associated with an owner's address.
     * @param _owner The address of the SBT owner.
     * @return The SBT ID. Returns 0 if no SBT is minted for the address.
     */
    function getPersonaSBTId(address _owner) external view returns (uint256) {
        return _ownerToSBTId[_owner];
    }

    // --- II. Skill Module Management ---

    /**
     * @notice Creates a new skill module. Only callable by the contract owner.
     * @param _name The name of the skill module (e.g., "Solidity Development").
     * @param _description A brief description of the skill module.
     * @param _requiredPointsForMastery The total points needed to achieve the highest mastery level in this module.
     * @param _masteryLevelsCount The number of distinct mastery levels for this skill. Must be at least 1.
     */
    function createSkillModule(
        string memory _name,
        string memory _description,
        uint256 _requiredPointsForMastery,
        uint256 _masteryLevelsCount
    ) external onlyOwner whenNotPaused {
        if (_requiredPointsForMastery == 0 || _masteryLevelsCount == 0) {
            revert PersonaForge__InvalidMasteryPointsConfiguration();
        }

        _skillModuleIdCounter.increment();
        uint256 newModuleId = _skillModuleIdCounter.current();

        _skillModules[newModuleId] = SkillModule({
            id: newModuleId,
            name: _name,
            description: _description,
            requiredPointsForMastery: _requiredPointsForMastery,
            masteryLevelsCount: _masteryLevelsCount,
            isActive: true
        });
        _allSkillModuleIds.push(newModuleId); // Add to iterable list

        emit SkillModuleCreated(newModuleId, _name, msg.sender);
    }

    /**
     * @notice Updates an existing skill module. Only callable by the contract owner.
     * @param _moduleId The ID of the skill module to update.
     * @param _newName The new name of the skill module.
     * @param _newDescription The new description.
     * @param _newRequiredPoints The new total points for mastery.
     * @param _newMasteryLevelsCount The new number of mastery levels.
     * @param _isActive Whether the module should be active.
     */
    function updateSkillModule(
        uint256 _moduleId,
        string memory _newName,
        string memory _newDescription,
        uint256 _newRequiredPoints,
        uint256 _newMasteryLevelsCount,
        bool _isActive
    ) external onlyOwner whenNotPaused {
        SkillModule storage module = _skillModules[_moduleId];
        if (module.id == 0) revert PersonaForge__SkillModuleNotFound(_moduleId);
        if (_newRequiredPoints == 0 || _newMasteryLevelsCount == 0) {
            revert PersonaForge__InvalidMasteryPointsConfiguration();
        }

        module.name = _newName;
        module.description = _newDescription;
        module.requiredPointsForMastery = _newRequiredPoints;
        module.masteryLevelsCount = _newMasteryLevelsCount;
        module.isActive = _isActive;

        emit SkillModuleUpdated(_moduleId, _newName, _isActive);
    }

    /**
     * @notice Retrieves comprehensive details about a specific skill module.
     * @param _moduleId The ID of the skill module.
     * @return A tuple containing the module's details.
     */
    function getSkillModuleDetails(
        uint256 _moduleId
    ) external view returns (uint256 id, string memory name, string memory description, uint256 requiredPointsForMastery, uint256 masteryLevelsCount, bool isActive) {
        SkillModule storage module = _skillModules[_moduleId];
        if (module.id == 0) revert PersonaForge__SkillModuleNotFound(_moduleId);
        return (module.id, module.name, module.description, module.requiredPointsForMastery, module.masteryLevelsCount, module.isActive);
    }

    // --- III. Challenge & Attestation System ---

    /**
     * @notice Creates a new challenge. Only callable by the contract owner.
     * @param _moduleId The ID of the skill module this challenge contributes to.
     * @param _name The name of the challenge.
     * @param _description A description of the challenge.
     * @param _rewardPoints The proficiency points awarded upon successful completion.
     * @param _requiresAttestation True if the challenge requires manual attestation by an Attester.
     */
    function createChallenge(
        uint256 _moduleId,
        string memory _name,
        string memory _description,
        uint256 _rewardPoints,
        bool _requiresAttestation
    ) external onlyOwner whenNotPaused {
        if (_skillModules[_moduleId].id == 0 || !_skillModules[_moduleId].isActive) revert PersonaForge__ModuleNotActive(_moduleId);

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        _challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            moduleId: _moduleId,
            name: _name,
            description: _description,
            rewardPoints: _rewardPoints,
            requiresAttestation: _requiresAttestation,
            isActive: true
        });

        emit ChallengeCreated(newChallengeId, _moduleId, _name, _rewardPoints);
    }

    /**
     * @notice Updates an existing challenge. Only callable by the contract owner.
     * @param _challengeId The ID of the challenge to update.
     * @param _moduleId The new skill module ID this challenge contributes to.
     * @param _newName The new name.
     * @param _newDescription The new description.
     * @param _newRewardPoints The new reward points.
     * @param _newRequiresAttestation The new attestation requirement.
     * @param _isActive Whether the challenge should be active.
     */
    function updateChallenge(
        uint256 _challengeId,
        uint256 _moduleId,
        string memory _newName,
        string memory _newDescription,
        uint256 _newRewardPoints,
        bool _newRequiresAttestation,
        bool _isActive
    ) external onlyOwner whenNotPaused {
        Challenge storage challenge = _challenges[_challengeId];
        if (challenge.id == 0) revert PersonaForge__ChallengeNotFound(_challengeId);
        if (_skillModules[_moduleId].id == 0 || !_skillModules[_moduleId].isActive) revert PersonaForge__ModuleNotActive(_moduleId);

        challenge.moduleId = _moduleId;
        challenge.name = _newName;
        challenge.description = _newDescription;
        challenge.rewardPoints = _newRewardPoints;
        challenge.requiresAttestation = _newRequiresAttestation;
        challenge.isActive = _isActive;

        emit ChallengeUpdated(_challengeId, _newName, _isActive);
    }

    /**
     * @notice Fetches details of a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return A tuple containing the challenge's details.
     */
    function getChallengeDetails(
        uint256 _challengeId
    ) external view returns (uint256 id, uint256 moduleId, string memory name, string memory description, uint256 rewardPoints, bool requiresAttestation, bool isActive) {
        Challenge storage challenge = _challenges[_challengeId];
        if (challenge.id == 0) revert PersonaForge__ChallengeNotFound(_challengeId);
        return (challenge.id, challenge.moduleId, challenge.name, challenge.description, challenge.rewardPoints, challenge.requiresAttestation, challenge.isActive);
    }

    /**
     * @notice Allows a user to submit proof for a completed challenge.
     *         If the challenge doesn't require attestation, points are awarded immediately.
     *         Otherwise, it enters a pending state for attestation by a designated attester.
     * @param _personaSBTId The ID of the user's Persona SBT.
     * @param _challengeId The ID of the completed challenge.
     * @param _proofURI A URI pointing to off-chain proof (e.g., IPFS CID, GitHub link).
     */
    function submitChallengeCompletion(
        uint256 _personaSBTId,
        uint256 _challengeId,
        string memory _proofURI
    ) external whenNotPaused {
        // Ensure the sender owns the SBT they are submitting for
        if (_sbtIdToOwner[_personaSBTId] != msg.sender) revert PersonaForge__InvalidSBTId();

        Challenge storage challenge = _challenges[_challengeId];
        if (challenge.id == 0 || !challenge.isActive) revert PersonaForge__ChallengeNotActive(_challengeId);

        _challengeCompletionIdCounter.increment();
        uint256 newCompletionId = _challengeCompletionIdCounter.current();

        _challengeCompletions[newCompletionId] = ChallengeCompletion({
            id: newCompletionId,
            challengeId: _challengeId,
            personaSBTId: _personaSBTId,
            proofURI: _proofURI,
            isVerified: false,
            isPending: challenge.requiresAttestation, // Set to true if attestation is required
            submitter: msg.sender,
            submittedAt: block.timestamp,
            verifiedAt: 0
        });

        if (challenge.requiresAttestation) {
            _pendingChallengeCompletions.push(newCompletionId);
        } else {
            // Auto-verify if no attestation needed
            _challengeCompletions[newCompletionId].isVerified = true;
            _challengeCompletions[newCompletionId].verifiedAt = block.timestamp;
            _awardProficiencyPoints(_personaSBTId, challenge.moduleId, challenge.rewardPoints);
        }

        emit ChallengeSubmitted(newCompletionId, _personaSBTId, _challengeId);
    }

    /**
     * @notice A designated attester verifies a submitted challenge completion.
     *         If verified, proficiency points are awarded to the user's SBT.
     * @param _completionId The ID of the challenge completion submission.
     * @param _isVerified True if the attester confirms the completion is valid, false otherwise.
     */
    function attestChallengeCompletion(uint256 _completionId, bool _isVerified) external whenNotPaused {
        if (!_isAttester[msg.sender]) revert PersonaForge__UnauthorizedAttester();

        ChallengeCompletion storage completion = _challengeCompletions[_completionId];
        // Using ChallengeNotFound error for completion as it also signifies ID not found.
        if (completion.id == 0) revert PersonaForge__ChallengeNotFound(0); 
        if (!completion.isPending) revert PersonaForge__ChallengeNotPending(_completionId);
        if (completion.isVerified) revert PersonaForge__ChallengeAlreadyVerified(_completionId); 

        completion.isVerified = _isVerified;
        completion.isPending = false; // No longer pending after attestation attempt
        completion.verifiedAt = block.timestamp;

        if (_isVerified) {
            Challenge storage challenge = _challenges[completion.challengeId];
            // Award points only if the challenge is active at the time of attestation.
            if (challenge.isActive) {
                _awardProficiencyPoints(completion.personaSBTId, challenge.moduleId, challenge.rewardPoints);
            }
        }

        // Remove from pending list (NOTE: This is O(N) for large arrays. For production, consider using
        // a more gas-efficient removal like swapping with last element and popping, or linked lists.)
        for (uint i = 0; i < _pendingChallengeCompletions.length; i++) {
            if (_pendingChallengeCompletions[i] == _completionId) {
                _pendingChallengeCompletions[i] = _pendingChallengeCompletions[_pendingChallengeCompletions.length - 1];
                _pendingChallengeCompletions.pop();
                break;
            }
        }

        emit ChallengeAttested(_completionId, completion.personaSBTId, completion.challengeId, _isVerified, msg.sender);
    }

    /**
     * @notice Retrieves details about a specific challenge completion submission.
     * @param _completionId The ID of the challenge completion.
     * @return A tuple containing the completion's details.
     */
    function getChallengeCompletionDetails(
        uint256 _completionId
    ) external view returns (uint256 id, uint256 challengeId, uint256 personaSBTId, string memory proofURI, bool isVerified, bool isPending, address submitter, uint256 submittedAt, uint256 verifiedAt) {
        ChallengeCompletion storage completion = _challengeCompletions[_completionId];
        if (completion.id == 0) revert PersonaForge__ChallengeNotFound(0); // Using ChallengeNotFound error for completion as it also signifies ID not found.
        return (completion.id, completion.challengeId, completion.personaSBTId, completion.proofURI, completion.isVerified, completion.isPending, completion.submitter, completion.submittedAt, completion.verifiedAt);
    }

    /**
     * @notice Lists all challenge completions that are currently awaiting attestation.
     * @return An array of challenge completion IDs.
     */
    function getPendingChallengeCompletions() external view returns (uint256[] memory) {
        return _pendingChallengeCompletions;
    }

    // --- IV. Proficiency & Mastery Progression ---

    /**
     * @dev Internal function to award proficiency points to a Persona SBT for a specific skill module.
     *      Only callable internally (e.g., after challenge attestation) or potentially by admin if manual awarding is desired.
     * @param _personaSBTId The ID of the Persona SBT.
     * @param _moduleId The ID of the skill module.
     * @param _points The number of points to award.
     */
    function _awardProficiencyPoints(uint256 _personaSBTId, uint256 _moduleId, uint256 _points) internal {
        // SBT existence is checked implicitly by submitChallengeCompletion or assumed for admin calls
        if (_personaSBTId == 0 || !_exists(_personaSBTId)) revert PersonaForge__InvalidSBTId();
        if (_skillModules[_moduleId].id == 0 || !_skillModules[_moduleId].isActive) revert PersonaForge__ModuleNotActive(_moduleId);

        _personaSkillProficiency[_personaSBTId][_moduleId] += _points;
        emit ProficiencyPointsAwarded(_personaSBTId, _moduleId, _points);
    }

    /**
     * @notice Returns the current proficiency points for an SBT in a specific skill module.
     * @param _personaSBTId The ID of the Persona SBT.
     * @param _moduleId The ID of the skill module.
     * @return The current proficiency points.
     */
    function getProficiencyPoints(uint256 _personaSBTId, uint256 _moduleId) external view returns (uint256) {
        if (_personaSBTId == 0 || !_exists(_personaSBTId)) revert PersonaForge__InvalidSBTId();
        if (_skillModules[_moduleId].id == 0) revert PersonaForge__SkillModuleNotFound(_moduleId);
        return _personaSkillProficiency[_personaSBTId][_moduleId];
    }

    /**
     * @notice Calculates the current mastery level for an SBT in a specific skill module.
     *         Mastery levels are determined proportionally based on `requiredPointsForMastery` and `masteryLevelsCount`.
     * @param _personaSBTId The ID of the Persona SBT.
     * @param _moduleId The ID of the skill module.
     * @return The current mastery level (0-indexed). Returns 0 if no points, up to `masteryLevelsCount - 1`.
     */
    function getCurrentMasteryLevel(uint256 _personaSBTId, uint256 _moduleId) public view returns (uint256) {
        if (_personaSBTId == 0 || !_exists(_personaSBTId)) revert PersonaForge__InvalidSBTId();
        SkillModule storage module = _skillModules[_moduleId];
        if (module.id == 0) revert PersonaForge__SkillModuleNotFound(_moduleId);
        if (module.masteryLevelsCount == 0 || module.requiredPointsForMastery == 0) return 0; // Prevent division by zero or invalid config

        uint256 currentPoints = _personaSkillProficiency[_personaSBTId][_moduleId];
        if (currentPoints == 0) return 0;

        // Calculate mastery level: (currentPoints * max_level_index) / total_required_points
        // Example: 100 points needed for 5 levels (0-4).
        // Max level index is 4. So (currentPoints * 4) / 100
        uint256 masteryLevel = (currentPoints * (module.masteryLevelsCount - 1)) / module.requiredPointsForMastery;

        // Cap the mastery level at the maximum defined level index
        if (masteryLevel >= module.masteryLevelsCount) {
            return module.masteryLevelsCount - 1;
        }
        return masteryLevel;
    }

    /**
     * @notice Returns a list of all skill modules and their respective proficiency points for an SBT.
     * @param _personaSBTId The ID of the Persona SBT.
     * @return An array of tuples, each containing moduleId, module name, and proficiency points.
     */
    function getAllSkillProficiencies(uint256 _personaSBTId)
        external
        view
        returns (uint256[] memory moduleIds, string[] memory moduleNames, uint256[] memory proficiencies)
    {
        if (_personaSBTId == 0 || !_exists(_personaSBTId)) revert PersonaForge__InvalidSBTId();

        uint256 activeModulesCount = 0;
        for(uint256 i = 0; i < _allSkillModuleIds.length; i++) {
            if (_skillModules[_allSkillModuleIds[i]].isActive) {
                activeModulesCount++;
            }
        }

        moduleIds = new uint256[](activeModulesCount);
        moduleNames = new string[](activeModulesCount);
        proficiencies = new uint256[](activeModulesCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _allSkillModuleIds.length; i++) {
            uint256 moduleId = _allSkillModuleIds[i];
            if (_skillModules[moduleId].isActive) {
                 moduleIds[index] = moduleId;
                 moduleNames[index] = _skillModules[moduleId].name;
                 proficiencies[index] = _personaSkillProficiency[_personaSBTId][moduleId];
                 index++;
            }
        }
        return (moduleIds, moduleNames, proficiencies);
    }

    /**
     * @notice Aggregates proficiency points across all modules into an overall reputation score.
     *         This is a simple sum of points; could be weighted or more complex in a real scenario.
     * @param _personaSBTId The ID of the Persona SBT.
     * @return The overall reputation score.
     */
    function calculateOverallReputation(uint256 _personaSBTId) external view returns (uint256) {
        if (_personaSBTId == 0 || !_exists(_personaSBTId)) revert PersonaForge__InvalidSBTId();
        uint256 totalReputation = 0;
        for (uint256 i = 0; i < _allSkillModuleIds.length; i++) {
            uint256 moduleId = _allSkillModuleIds[i];
            // Only count points from active modules for overall reputation
            if (_skillModules[moduleId].isActive) {
                totalReputation += _personaSkillProficiency[_personaSBTId][moduleId];
            }
        }
        return totalReputation;
    }

    // --- V. Dynamic Metadata & Configuration ---

    /**
     * @notice Sets the base URI for NFT metadata. This is prefixed to the tokenId to form the full URI.
     *         For example, "https://api.example.com/sbt/" would lead to "https://api.example.com/sbt/123.json".
     *         This function is callable only by the contract owner.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI = _newBaseURI;
    }

    /**
     * @notice Helper function that provides the raw data needed to generate the dynamic SBT metadata.
     *         An off-chain service (e.g., a backend API) would call this to construct the JSON.
     * @param _personaSBTId The ID of the Persona SBT.
     * @return A tuple containing various data points for metadata generation.
     */
    function getPersonaMetadata(
        uint256 _personaSBTId
    )
        external
        view
        returns (
            uint256 sbtId,
            address ownerAddress,
            uint256 overallReputation,
            (uint256 moduleId, string memory moduleName, uint256 currentPoints, uint256 currentMasteryLevel)[] memory skillProficiencies
        )
    {
        if (_personaSBTId == 0 || !_exists(_personaSBTId)) revert PersonaForge__InvalidSBTId();

        ownerAddress = _sbtIdToOwner[_personaSBTId];
        overallReputation = calculateOverallReputation(_personaSBTId);

        uint256 activeModulesCount = 0;
        for(uint256 i = 0; i < _allSkillModuleIds.length; i++) {
            if (_skillModules[_allSkillModuleIds[i]].isActive) {
                activeModulesCount++;
            }
        }

        skillProficiencies = new (uint256, string memory, uint256, uint256)[activeModulesCount];
        uint256 index = 0;

        for (uint256 i = 0; i < _allSkillModuleIds.length; i++) {
            uint256 moduleId = _allSkillModuleIds[i];
            SkillModule storage module = _skillModules[moduleId];
            if (module.isActive) {
                skillProficiencies[index] = (
                    moduleId,
                    module.name,
                    _personaSkillProficiency[_personaSBTId][moduleId],
                    getCurrentMasteryLevel(_personaSBTId, moduleId)
                );
                index++;
            }
        }

        return (
            _personaSBTId,
            ownerAddress,
            overallReputation,
            skillProficiencies
        );
    }

    // --- VI. Access Control & Utility ---

    /**
     * @notice Grants the attester role to an address. Attesters can verify challenge completions.
     *         Only callable by the contract owner.
     * @param _attester The address to grant the role to.
     */
    function grantAttesterRole(address _attester) external onlyOwner {
        if (_attester == address(0)) revert PersonaForge__ZeroAddress();
        // Owner has full control and can directly award points if needed, no need for redundant attester role
        if (_attester == owner()) revert PersonaForge__AttesterCannotBeOwner();
        _isAttester[_attester] = true;
        emit AttesterRoleGranted(_attester, msg.sender);
    }

    /**
     * @notice Revokes the attester role from an address.
     *         Only callable by the contract owner.
     * @param _attester The address to revoke the role from.
     */
    function revokeAttesterRole(address _attester) external onlyOwner {
        if (_attester == address(0)) revert PersonaForge__ZeroAddress();
        _isAttester[_attester] = false;
        emit AttesterRoleRevoked(_attester, msg.sender);
    }

    /**
     * @notice Checks if an address has the attester role.
     * @param _address The address to check.
     * @return True if the address is an attester, false otherwise.
     */
    function hasAttesterRole(address _address) external view returns (bool) {
        return _isAttester[_address];
    }

    /**
     * @notice Pauses contract functionality that interacts with state changes (e.g., minting, challenge submissions).
     *         Only callable by the contract owner. Inherited from OpenZeppelin's Pausable.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, resuming normal functionality.
     *         Only callable by the contract owner. Inherited from OpenZeppelin's Pausable.
     */
    function unpause() public override onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the contract owner to withdraw any ETH accidentally sent to the contract.
     * @param _to The address to send the ETH to.
     */
    function withdrawStuckEth(address _to) external onlyOwner {
        if (_to == address(0)) revert PersonaForge__ZeroAddress();
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = _to.call{value: balance}("");
            if (!success) revert PersonaForge__WithdrawFailed();
        }
    }
}
```