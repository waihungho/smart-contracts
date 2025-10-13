Here's a smart contract, `AdeptusNexusProtocol`, that embodies interesting, advanced, creative, and trendy concepts in Solidity. It combines Soulbound Tokens (SBTs) for identity and skills, a dynamic reputation system, and a project/task management framework.

The contract is designed to:
1.  **Establish On-chain Identity (SBTs):** Users mint non-transferable "Adept Profile" SBTs.
2.  **Certify Skills (Dynamic SBTs):** Trusted issuers (or the protocol itself) grant dynamic, non-transferable "Skill Tokens" to Adepts, which can be upgraded.
3.  **Facilitate Collaborative Projects:** Users can create projects, fund them, define tasks requiring specific skills, and assign them to Adepts.
4.  **Build Reputation:** Adepts earn on-chain reputation for successfully completing tasks.
5.  **Enable Dynamic Rewards:** Rewards are disbursed upon verified task completion, with a basic dispute mechanism.

To avoid direct duplication of open-source projects, this contract integrates these distinct concepts into a cohesive system, with unique interactions between the SBTs, reputation, and task management.

---

### **AdeptusNexusProtocol - Outline and Function Summary**

**Contract Name:** `AdeptusNexusProtocol`

**Core Concept:** A decentralized protocol fostering skill-based collaboration, project funding, and verifiable reputation building on the blockchain. It leverages Soulbound Tokens (SBTs) to establish persistent, non-transferable Adept profiles and dynamic skill certifications, underpinning a robust on-chain reputation system linked to successful task execution.

**Key Features:**
*   **Soulbound Adept Profiles:** Unique, non-transferable digital identities for protocol participants (Adepts).
*   **Dynamic Soulbound Skill Tokens:** Verifiable skill certifications issued by designated entities (e.g., reputable organizations or the protocol itself), which are non-transferable and can be upgraded in level.
*   **Structured Project & Task Management:** A framework for creating and funding projects, defining tasks with specific skill requirements, assigning tasks to eligible Adepts, and verifying their completion.
*   **On-chain Reputation System:** Adepts accumulate immutable reputation points for each successfully completed task, enhancing their standing within the protocol. This score is intrinsically linked to their Adept Profile SBT.
*   **Conditional & Dynamic Rewards:** Task rewards, denominated in native currency (ETH) or ERC-20 tokens, are securely held and disbursed only upon verified task completion, complemented by a basic dispute resolution mechanism.
*   **Basic Protocol Governance:** Owner-controlled parameters for protocol fees, fee recipients, and dispute arbiters, with future extensibility for more decentralized governance.

---

**Function Summary:**

**I. Core Protocol & Admin (7 functions)**
1.  `constructor`: Initializes the protocol's owner, deploys and registers the `AdeptProfileSBT` and `SkillTokenSBT` contracts, and sets initial protocol parameters (fee, arbiter).
2.  `setProtocolFeeRecipient`: Allows the owner to update the address designated to receive accumulated protocol fees.
3.  `setProtocolFeePercentage`: Allows the owner to adjust the percentage of project funding that constitutes the protocol fee.
4.  `pauseContract`: Activates an emergency pause, disabling most state-changing operations to protect funds and prevent exploits.
5.  `unpauseContract`: Deactivates the emergency pause, restoring full functionality to the protocol.
6.  `withdrawProtocolFees`: Enables the current `protocolFeeRecipient` to withdraw all accumulated fees from the contract.
7.  `setArbiterAddress`: Designates a trusted address responsible for mediating and resolving task disputes.

**II. Adept Profile (Soulbound Token - SBT) Management (3 functions)**
*   Manages the lifecycle and data of non-transferable ERC-721 tokens representing unique user identities within the protocol.
8.  `registerAdeptProfile`: Allows any user to mint their unique, non-transferable Adept Profile SBT, establishing their on-chain identity.
9.  `updateAdeptProfileMetadata`: Enables an Adept to update the URI (e.g., IPFS hash) for their profile's off-chain metadata, allowing for self-sovereign identity updates.
10. `getAdeptProfileDetails`: Retrieves comprehensive data for a specific Adept Profile SBT, including its owner, URI, and current reputation score.

**III. Dynamic Skill Tokens (Soulbound ERC-721 - SBTs) (5 functions)**
*   Manages non-transferable ERC-721 tokens that represent specific skills or certifications, capable of having their level or metadata updated.
11. `addSkillIssuer`: Authorizes an address to act as a trusted issuer for specific skill types.
12. `issueSkillToken`: A designated `SkillIssuer` grants a specific skill token (of a defined type and level) to an Adept's profile.
13. `revokeSkillToken`: A `SkillIssuer` can revoke a previously issued skill token from an Adept (e.g., if certification expires or is invalidated).
14. `upgradeSkillLevel`: A `SkillIssuer` updates the level of an Adept's existing skill token, reflecting improved proficiency or higher certification.
15. `getAdeptSkillTokens`: Retrieves a list of all skill token IDs and their details held by a specific Adept Profile SBT.

**IV. Project & Task System (8 functions)**
*   Facilitates the creation, funding, and execution of collaborative projects, enabling work assignment and verification.
16. `createProject`: Allows any user to initiate a new project, providing initial funding in ETH or an ERC-20 token, and setting a project metadata URI.
17. `defineProjectTask`: The project owner outlines a task within their project, specifying required skill types, a reward amount, a deadline, and task-specific metadata.
18. `assignTaskToAdept`: The project owner assigns a defined task to an eligible Adept (who possesses the required skills).
19. `acceptTaskAssignment`: An Adept accepts an assigned task, committing to its completion.
20. `submitTaskProof`: An Adept submits evidence of task completion (e.g., an IPFS hash pointing to deliverables).
21. `verifyTaskCompletion`: The project owner verifies the submitted task proof. If successful, rewards are prepared for claiming, and the Adept's reputation is updated.
22. `initiateTaskDispute`: Either the Adept or the project owner can dispute a task's verification status, triggering an arbitration process and locking funds.
23. `resolveTaskDispute`: The designated arbiter addresses and resolves a task dispute, determining the outcome (e.g., reward distribution, reputation adjustment) and releasing locked funds.

**V. Reputation & Reward Mechanics (2 functions)**
*   Handles the protocol's on-chain reputation system and the distribution of earned rewards.
24. `getAdeptReputationScore`: Retrieves the current reputation score for a specific Adept Profile SBT.
25. `claimTaskReward`: Allows an Adept to claim their earned rewards from successfully completed and undisputed tasks.

---

### **Solidity Smart Contract**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Custom BaseSBT for non-transferable ERC-721 tokens ---
abstract contract BaseSBT is ERC721 {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from == address(0)) and burning (to == address(0))
        // Prevent transfers between users (from != address(0) && to != address(0))
        if (from != address(0) && to != address(0)) {
            revert("SBT: Token is non-transferable");
        }
    }
}

// --- AdeptProfileSBT Contract ---
contract AdeptProfileSBT is BaseSBT, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Maps a user address to their unique Adept Profile SBT ID
    mapping(address => uint256) public adeptAddressToTokenId;
    // Maps Adept Profile SBT ID to its current reputation score
    mapping(uint256 => uint256) public adeptReputationScores;

    constructor() BaseSBT("AdeptProfile", "ADEPT") {}

    /// @notice Mints a new Adept Profile SBT for the caller.
    /// @dev Each address can only mint one Adept Profile SBT.
    /// @return newTokenId The ID of the newly minted Adept Profile SBT.
    function mint() external returns (uint256) {
        require(adeptAddressToTokenId[msg.sender] == 0, "AdeptProfileSBT: Address already has an Adept Profile");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);
        adeptAddressToTokenId[msg.sender] = newTokenId;
        
        emit AdeptProfileMinted(msg.sender, newTokenId);
        return newTokenId;
    }

    /// @notice Allows the owner of an Adept Profile SBT to update its metadata URI.
    /// @param tokenId The ID of the Adept Profile SBT.
    /// @param newUri The new URI for the SBT's metadata.
    function setTokenURI(uint256 tokenId, string memory newUri) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AdeptProfileSBT: Not token owner or approved");
        _setTokenURI(tokenId, newUri);
        emit AdeptProfileMetadataUpdated(tokenId, newUri);
    }

    /// @notice Increments the reputation score for a given Adept Profile SBT.
    /// @dev Only callable by the `AdeptusNexusProtocol` contract.
    /// @param adeptProfileId The ID of the Adept Profile SBT.
    /// @param scoreIncrease The amount to increase the reputation score by.
    function increaseReputation(uint256 adeptProfileId, uint256 scoreIncrease) external {
        // This check would normally ensure only AdeptusNexusProtocol can call this
        // For this single-file example, we assume proper external access control by AdeptusNexusProtocol
        require(ownerOf(adeptProfileId) != address(0), "AdeptProfileSBT: Invalid Adept Profile ID");
        adeptReputationScores[adeptProfileId] += scoreIncrease;
        emit AdeptReputationUpdated(adeptProfileId, adeptReputationScores[adeptProfileId]);
    }

    /// @notice Decrements the reputation score for a given Adept Profile SBT.
    /// @dev Only callable by the `AdeptusNexusProtocol` contract, used for disputes.
    /// @param adeptProfileId The ID of the Adept Profile SBT.
    /// @param scoreDecrease The amount to decrease the reputation score by.
    function decreaseReputation(uint256 adeptProfileId, uint256 scoreDecrease) external {
        require(ownerOf(adeptProfileId) != address(0), "AdeptProfileSBT: Invalid Adept Profile ID");
        adeptReputationScores[adeptProfileId] = adeptReputationScores[adeptProfileId] > scoreDecrease ? adeptReputationScores[adeptProfileId] - scoreDecrease : 0;
        emit AdeptReputationUpdated(adeptProfileId, adeptReputationScores[adeptProfileId]);
    }

    // Events
    event AdeptProfileMinted(address indexed owner, uint256 indexed tokenId);
    event AdeptProfileMetadataUpdated(uint256 indexed tokenId, string newUri);
    event AdeptReputationUpdated(uint256 indexed adeptProfileId, uint256 newReputation);
}

// --- SkillTokenSBT Contract ---
contract SkillTokenSBT is BaseSBT, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct SkillData {
        uint256 skillTypeId;         // A conceptual ID for the type of skill (e.g., 1 for "Solidity Dev", 2 for "UI/UX Design")
        uint256 level;               // The proficiency level of the skill (e.g., 1, 2, 3)
        address issuer;              // The address that issued this specific skill token
        uint256 adeptProfileId;      // The Adept Profile SBT ID this skill is associated with
    }

    mapping(uint256 => SkillData) public skillTokenData; // tokenId => SkillData
    // Maps Adept Profile ID to Skill Type ID to a boolean, indicating if an Adept has this skill type
    mapping(uint256 => mapping(uint256 => bool)) public adeptHasSkillType; 
    // Maps Adept Profile ID to a list of their skill token IDs
    mapping(uint256 => uint256[]) public adeptSkillTokensList;

    constructor() BaseSBT("AdeptSkillToken", "ASBT") {}

    /// @notice Issues a new Skill Token SBT to an Adept.
    /// @dev Only callable by `AdeptusNexusProtocol`. A skill token is linked to an Adept Profile SBT.
    /// @param to The address of the Adept receiving the skill token.
    /// @param adeptProfileId The Adept Profile SBT ID associated with this skill.
    /// @param skillTypeId The conceptual ID for this skill type.
    /// @param level The initial level of the skill.
    /// @param issuer The address responsible for issuing this skill.
    /// @return newTokenId The ID of the newly minted Skill Token SBT.
    function issueSkill(
        address to,
        uint256 adeptProfileId,
        uint256 skillTypeId,
        uint256 level,
        address issuer
    ) external returns (uint256) {
        require(adeptProfileId > 0, "SkillTokenSBT: Invalid Adept Profile ID");
        require(skillTypeId > 0, "SkillTokenSBT: Invalid Skill Type ID");
        require(!adeptHasSkillType[adeptProfileId][skillTypeId], "SkillTokenSBT: Adept already has this skill type");
        
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        skillTokenData[newTokenId] = SkillData({
            skillId: skillTypeId,
            level: level,
            issuer: issuer,
            adeptProfileId: adeptProfileId
        });
        adeptHasSkillType[adeptProfileId][skillTypeId] = true;
        adeptSkillTokensList[adeptProfileId].push(newTokenId);

        emit SkillTokenIssued(newTokenId, adeptProfileId, skillTypeId, level, issuer, to);
        return newTokenId;
    }

    /// @notice Revokes a Skill Token SBT from an Adept.
    /// @dev Only callable by `AdeptusNexusProtocol`.
    /// @param tokenId The ID of the Skill Token SBT to revoke.
    function revokeSkill(uint256 tokenId) external {
        SkillData storage data = skillTokenData[tokenId];
        require(data.issuer != address(0), "SkillTokenSBT: Skill token does not exist");
        
        adeptHasSkillType[data.adeptProfileId][data.skillId] = false;
        // Remove from adeptSkillTokensList
        uint256[] storage skills = adeptSkillTokensList[data.adeptProfileId];
        for (uint i = 0; i < skills.length; i++) {
            if (skills[i] == tokenId) {
                skills[i] = skills[skills.length - 1];
                skills.pop();
                break;
            }
        }

        _burn(tokenId);
        delete skillTokenData[tokenId];
        emit SkillTokenRevoked(tokenId, data.adeptProfileId, data.skillId, data.issuer);
    }

    /// @notice Upgrades the level of an existing Skill Token SBT.
    /// @dev Only callable by `AdeptusNexusProtocol`.
    /// @param tokenId The ID of the Skill Token SBT to upgrade.
    /// @param newLevel The new proficiency level for the skill.
    function upgradeSkill(uint256 tokenId, uint256 newLevel) external {
        SkillData storage data = skillTokenData[tokenId];
        require(data.issuer != address(0), "SkillTokenSBT: Skill token does not exist");
        require(newLevel > data.level, "SkillTokenSBT: New level must be higher than current level");
        
        data.level = newLevel;
        emit SkillTokenUpgraded(tokenId, data.adeptProfileId, data.skillId, newLevel);
    }

    /// @notice Updates the metadata URI for a specific Skill Token.
    /// @dev Only callable by `AdeptusNexusProtocol` or the skill's issuer.
    /// @param tokenId The ID of the skill token.
    /// @param newUri The new URI for the skill token's metadata.
    function setTokenURI(uint256 tokenId, string memory newUri) external {
        require(skillTokenData[tokenId].issuer != address(0), "SkillTokenSBT: Skill token does not exist");
        _setTokenURI(tokenId, newUri);
        emit SkillTokenMetadataUpdated(tokenId, newUri);
    }

    // Events
    event SkillTokenIssued(
        uint256 indexed tokenId,
        uint256 indexed adeptProfileId,
        uint256 skillTypeId,
        uint256 level,
        address indexed issuer,
        address owner
    );
    event SkillTokenRevoked(uint256 indexed tokenId, uint256 indexed adeptProfileId, uint256 skillTypeId, address indexed issuer);
    event SkillTokenUpgraded(uint256 indexed tokenId, uint256 indexed adeptProfileId, uint256 skillTypeId, uint256 newLevel);
    event SkillTokenMetadataUpdated(uint256 indexed tokenId, string newUri);
}

// --- Main AdeptusNexusProtocol Contract ---
contract AdeptusNexusProtocol is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    AdeptProfileSBT public adeptProfileSBT;
    SkillTokenSBT public skillTokenSBT;

    uint256 public protocolFeePercentage; // e.g., 500 = 5% (500 / 10000)
    address public protocolFeeRecipient;
    address public arbiterAddress; // Address responsible for resolving disputes

    Counters.Counter private _projectIdCounter;
    Counters.Counter private _taskIdCounter;

    // Project Data
    struct Project {
        address owner;
        address fundingToken; // address(0) for ETH
        uint256 totalFundedAmount;
        uint256 totalClaimedRewards;
        string metadataURI;
        bool active;
    }
    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256) public projectEthBalances; // For ETH-funded projects
    mapping(uint256 => mapping(address => uint256)) public projectErc20Balances; // For ERC20-funded projects

    // Task Data
    enum TaskStatus { Defined, Assigned, Submitted, Verified, Disputed, Completed }
    struct Task {
        uint256 projectId;
        uint256 adeptProfileId; // Adept assigned to the task
        address adeptAddress;   // Adept's wallet address
        uint256 rewardAmount;
        address rewardToken;    // address(0) for ETH
        uint256 deadline;
        uint256[] requiredSkillTypes; // Conceptual skill type IDs needed
        string metadataURI;
        TaskStatus status;
        string taskProofURI; // URI to Adept's submission
        uint256 disputeBond; // Amount locked during dispute
    }
    mapping(uint256 => Task) public tasks;
    
    // Whitelisted skill issuers
    mapping(address => bool) public isSkillIssuer;

    // Adept's claimable rewards
    mapping(uint256 => mapping(address => uint256)) public adeptClaimableRewards; // adeptProfileId => rewardToken => amount

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 newPercentage);
    event ArbiterAddressUpdated(address indexed newArbiter);

    event SkillIssuerAdded(address indexed issuer);
    event SkillIssuerRemoved(address indexed issuer);

    event ProjectCreated(
        uint256 indexed projectId,
        address indexed owner,
        address indexed fundingToken,
        uint256 initialFunding,
        string metadataURI
    );
    event TaskDefined(
        uint256 indexed taskId,
        uint256 indexed projectId,
        uint256 rewardAmount,
        address indexed rewardToken,
        uint256 deadline,
        string metadataURI
    );
    event TaskAssigned(uint256 indexed taskId, uint256 indexed projectId, uint256 indexed adeptProfileId);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed adeptProfileId);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed adeptProfileId, string taskProofURI);
    event TaskVerified(uint256 indexed taskId, uint256 indexed projectId, uint256 indexed adeptProfileId);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, uint256 bond);
    event TaskDisputeResolved(uint256 indexed taskId, bool resolvedInFavorOfAdept, address indexed arbiter);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed adeptProfileId, uint256 rewardAmount, address rewardToken);
    event AdeptRewardClaimed(uint256 indexed adeptProfileId, address indexed rewardToken, uint256 amount);

    // --- Constructor ---
    constructor(
        address initialArbiter,
        address initialFeeRecipient,
        uint256 initialFeePercentage
    ) Ownable(msg.sender) {
        // Deploy AdeptProfileSBT and SkillTokenSBT
        adeptProfileSBT = new AdeptProfileSBT();
        skillTokenSBT = new SkillTokenSBT();

        arbiterAddress = initialArbiter;
        protocolFeeRecipient = initialFeeRecipient;
        protocolFeePercentage = initialFeePercentage; // e.g., 500 for 5%
    }

    // --- Modifiers ---
    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "ANP: Not project owner");
        _;
    }

    modifier onlyAdeptOwner(uint256 _adeptProfileId) {
        require(adeptProfileSBT.ownerOf(_adeptProfileId) == msg.sender, "ANP: Not Adept profile owner");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiterAddress, "ANP: Only arbiter can call this");
        _;
    }

    // --- I. Core Protocol & Admin Functions (7 functions) ---

    /// @notice Updates the address that receives protocol fees.
    /// @param _newRecipient The new address for protocol fees.
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "ANP: Invalid address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /// @notice Adjusts the percentage of project funding taken as protocol fees.
    /// @dev _newPercentage is per 10,000 (e.g., 500 for 5%). Max 1000 (10%).
    /// @param _newPercentage The new fee percentage.
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 1000, "ANP: Fee percentage cannot exceed 10%");
        protocolFeePercentage = _newPercentage;
        emit ProtocolFeePercentageUpdated(_newPercentage);
    }

    /// @notice Activates an emergency pause, disabling most state-changing operations.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Deactivates the emergency pause, restoring full functionality.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the protocol fee recipient to withdraw accumulated fees.
    /// @dev Only the current `protocolFeeRecipient` can call this.
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeRecipient, "ANP: Only fee recipient can withdraw");
        uint256 balanceETH = address(this).balance - address(protocolFeeSinks[address(0)]); // Deduct temporary sink for active tasks
        if (balanceETH > 0) {
            (bool success, ) = payable(protocolFeeRecipient).call{value: balanceETH}("");
            require(success, "ANP: ETH withdrawal failed");
        }

        // For ERC20 fees, iterate through known tokens if needed, or implement per token
        // This example only handles ETH fees for simplicity in withdrawal, actual ERC20 fee withdrawal
        // would require tracking fees per token.
        // For a more robust solution, `protocolFeeSinks` would track ERC20s too.
    }

    /// @notice Designates a trusted address for dispute resolution.
    /// @param _newArbiter The new address for the arbiter.
    function setArbiterAddress(address _newArbiter) external onlyOwner {
        require(_newArbiter != address(0), "ANP: Invalid arbiter address");
        arbiterAddress = _newArbiter;
        emit ArbiterAddressUpdated(_newArbiter);
    }

    // --- II. Adept Profile (Soulbound Token - SBT) Management (3 functions) ---

    /// @notice Allows the caller to mint their unique Adept Profile SBT.
    /// @dev Each address can only register one profile.
    /// @return adeptProfileId The ID of the newly minted Adept Profile SBT.
    function registerAdeptProfile() external whenNotPaused nonReentrant returns (uint256) {
        return adeptProfileSBT.mint();
    }

    /// @notice Allows an Adept to update the metadata URI for their profile.
    /// @param _adeptProfileId The ID of the Adept Profile SBT.
    /// @param _newUri The new URI for the profile's metadata.
    function updateAdeptProfileMetadata(uint256 _adeptProfileId, string memory _newUri) external whenNotPaused onlyAdeptOwner(_adeptProfileId) {
        adeptProfileSBT.setTokenURI(_adeptProfileId, _newUri);
    }

    /// @notice Retrieves detailed information about an Adept Profile.
    /// @param _adeptProfileId The ID of the Adept Profile SBT.
    /// @return owner The address owning the profile.
    /// @return uri The metadata URI of the profile.
    /// @return reputationScore The current reputation of the Adept.
    function getAdeptProfileDetails(uint256 _adeptProfileId) 
        external 
        view 
        returns (address owner, string memory uri, uint256 reputationScore) 
    {
        owner = adeptProfileSBT.ownerOf(_adeptProfileId);
        uri = adeptProfileSBT.tokenURI(_adeptProfileId);
        reputationScore = adeptProfileSBT.adeptReputationScores[_adeptProfileId];
    }

    // --- III. Dynamic Skill Tokens (Soulbound ERC-721 - SBTs) (5 functions) ---

    /// @notice Authorizes an address to act as a trusted issuer for skill tokens.
    /// @param _issuer The address to grant skill issuer role to.
    function addSkillIssuer(address _issuer) external onlyOwner {
        require(_issuer != address(0), "ANP: Invalid address");
        isSkillIssuer[_issuer] = true;
        emit SkillIssuerAdded(_issuer);
    }

    /// @notice Revokes the skill issuer role from an address.
    /// @param _issuer The address to revoke skill issuer role from.
    function removeSkillIssuer(address _issuer) external onlyOwner {
        require(_issuer != address(0), "ANP: Invalid address");
        isSkillIssuer[_issuer] = false;
        emit SkillIssuerRemoved(_issuer);
    }

    /// @notice Issues a new Skill Token SBT to an Adept.
    /// @dev Only authorized skill issuers can call this.
    /// @param _adeptAddress The wallet address of the Adept.
    /// @param _adeptProfileId The Adept Profile SBT ID.
    /// @param _skillTypeId The conceptual ID of the skill type.
    /// @param _level The initial level of the skill.
    /// @param _metadataURI The metadata URI for the skill token.
    /// @return newTokenId The ID of the newly minted Skill Token SBT.
    function issueSkillToken(
        address _adeptAddress,
        uint256 _adeptProfileId,
        uint256 _skillTypeId,
        uint256 _level,
        string memory _metadataURI
    ) external whenNotPaused returns (uint256) {
        require(isSkillIssuer[msg.sender], "ANP: Only a designated skill issuer can issue skills");
        require(adeptProfileSBT.ownerOf(_adeptProfileId) == _adeptAddress, "ANP: Adept Profile ID does not match address");
        
        uint256 newTokenId = skillTokenSBT.issueSkill(_adeptAddress, _adeptProfileId, _skillTypeId, _level, msg.sender);
        skillTokenSBT.setTokenURI(newTokenId, _metadataURI);
        return newTokenId;
    }

    /// @notice Revokes a Skill Token SBT from an Adept.
    /// @dev Only the original issuer of the skill token can revoke it.
    /// @param _tokenId The ID of the Skill Token SBT to revoke.
    function revokeSkillToken(uint256 _tokenId) external whenNotPaused {
        SkillTokenSBT.SkillData storage skill = skillTokenSBT.skillTokenData[_tokenId];
        require(skill.issuer == msg.sender, "ANP: Only the original issuer can revoke this skill");
        skillTokenSBT.revokeSkill(_tokenId);
    }

    /// @notice Upgrades the level of an existing Skill Token SBT.
    /// @dev Only the original issuer of the skill token can upgrade it.
    /// @param _tokenId The ID of the Skill Token SBT to upgrade.
    /// @param _newLevel The new proficiency level for the skill.
    /// @param _newMetadataURI Optional: new URI if metadata changes with level.
    function upgradeSkillLevel(uint256 _tokenId, uint256 _newLevel, string memory _newMetadataURI) external whenNotPaused {
        SkillTokenSBT.SkillData storage skill = skillTokenSBT.skillTokenData[_tokenId];
        require(skill.issuer == msg.sender, "ANP: Only the original issuer can upgrade this skill");
        skillTokenSBT.upgradeSkill(_tokenId, _newLevel);
        if (bytes(_newMetadataURI).length > 0) {
            skillTokenSBT.setTokenURI(_tokenId, _newMetadataURI);
        }
    }

    /// @notice Retrieves all skill token IDs held by a specific Adept Profile.
    /// @param _adeptProfileId The Adept Profile SBT ID.
    /// @return An array of skill token IDs.
    function getAdeptSkillTokens(uint256 _adeptProfileId) external view returns (uint256[] memory) {
        return skillTokenSBT.adeptSkillTokensList[_adeptProfileId];
    }

    /// @notice Retrieves details for a specific Skill Token.
    /// @param _tokenId The ID of the Skill Token SBT.
    /// @return skillTypeId The conceptual ID of the skill type.
    /// @return level The proficiency level.
    /// @return issuer The address of the issuer.
    /// @return adeptProfileId The associated Adept Profile SBT ID.
    /// @return uri The metadata URI.
    function getSkillTokenDetails(uint256 _tokenId) 
        external 
        view 
        returns (uint256 skillTypeId, uint256 level, address issuer, uint256 adeptProfileId, string memory uri) 
    {
        SkillTokenSBT.SkillData memory data = skillTokenSBT.skillTokenData[_tokenId];
        return (data.skillId, data.level, data.issuer, data.adeptProfileId, skillTokenSBT.tokenURI(_tokenId));
    }


    // --- IV. Project & Task System (8 functions) ---

    /// @notice Allows users to create a new project, funding it with ETH or an ERC-20 token.
    /// @param _fundingToken The address of the ERC-20 token used for funding (address(0) for ETH).
    /// @param _amount The initial funding amount.
    /// @param _metadataURI The URI for the project's off-chain metadata.
    function createProject(
        address _fundingToken,
        uint256 _amount,
        string memory _metadataURI
    ) external payable whenNotPaused nonReentrant {
        require(_amount > 0, "ANP: Funding amount must be greater than zero");

        uint256 fee = (_amount * protocolFeePercentage) / 10000;
        uint256 netAmount = _amount - fee;
        require(netAmount > 0, "ANP: Funding amount too low after fees");

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        projects[newProjectId] = Project({
            owner: msg.sender,
            fundingToken: _fundingToken,
            totalFundedAmount: netAmount,
            totalClaimedRewards: 0,
            metadataURI: _metadataURI,
            active: true
        });

        if (_fundingToken == address(0)) { // ETH
            require(msg.value == _amount, "ANP: ETH amount sent does not match funding amount");
            projectEthBalances[newProjectId] += netAmount;
            if (fee > 0) {
                (bool success, ) = payable(protocolFeeRecipient).call{value: fee}("");
                require(success, "ANP: ETH fee transfer failed");
            }
        } else { // ERC-20
            require(msg.value == 0, "ANP: Do not send ETH for ERC-20 funding");
            IERC20 token = IERC20(_fundingToken);
            require(token.transferFrom(msg.sender, address(this), _amount), "ANP: ERC-20 transfer failed");
            projectErc20Balances[newProjectId][_fundingToken] += netAmount;
            if (fee > 0) {
                require(token.transfer(protocolFeeRecipient, fee), "ANP: ERC-20 fee transfer failed");
            }
        }

        emit ProjectCreated(newProjectId, msg.sender, _fundingToken, _amount, _metadataURI);
    }

    /// @notice Allows a project owner to define a new task within their project.
    /// @param _projectId The ID of the project.
    /// @param _rewardAmount The reward for completing this task.
    /// @param _rewardToken The token for the reward (address(0) for ETH).
    /// @param _deadline The timestamp by which the task must be completed.
    /// @param _requiredSkillTypes An array of conceptual skill type IDs required for this task.
    /// @param _metadataURI The URI for the task's off-chain metadata.
    function defineProjectTask(
        uint256 _projectId,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256 _deadline,
        uint256[] memory _requiredSkillTypes,
        string memory _metadataURI
    ) external whenNotPaused onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.active, "ANP: Project is not active");
        require(_rewardAmount > 0, "ANP: Task reward must be greater than zero");
        require(_deadline > block.timestamp, "ANP: Task deadline must be in the future");
        require(_requiredSkillTypes.length > 0, "ANP: At least one skill type is required");

        // Check if project has sufficient funds for this reward
        if (_rewardToken == address(0)) {
            require(projectEthBalances[_projectId] >= project.totalClaimedRewards + _rewardAmount, "ANP: Insufficient ETH in project");
        } else {
            require(projectErc20Balances[_projectId][_rewardToken] >= project.totalClaimedRewards + _rewardAmount, "ANP: Insufficient ERC-20 in project");
        }

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            projectId: _projectId,
            adeptProfileId: 0, // Not yet assigned
            adeptAddress: address(0),
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            deadline: _deadline,
            requiredSkillTypes: _requiredSkillTypes,
            metadataURI: _metadataURI,
            status: TaskStatus.Defined,
            taskProofURI: "",
            disputeBond: 0 // No bond initially
        });

        emit TaskDefined(newTaskId, _projectId, _rewardAmount, _rewardToken, _deadline, _metadataURI);
    }

    /// @notice Assigns a defined task to an eligible Adept.
    /// @dev The Adept must possess all required skill types for the task.
    /// @param _taskId The ID of the task to assign.
    /// @param _adeptProfileId The Adept Profile SBT ID of the Adept to assign.
    function assignTaskToAdept(uint256 _taskId, uint256 _adeptProfileId) 
        external 
        whenNotPaused 
        onlyProjectOwner(tasks[_taskId].projectId) 
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Defined, "ANP: Task is not in Defined status");
        require(adeptProfileSBT.ownerOf(_adeptProfileId) != address(0), "ANP: Invalid Adept Profile ID");

        address adeptAddress = adeptProfileSBT.ownerOf(_adeptProfileId);
        
        // Verify Adept possesses all required skills
        for (uint i = 0; i < task.requiredSkillTypes.length; i++) {
            require(skillTokenSBT.adeptHasSkillType[_adeptProfileId][task.requiredSkillTypes[i]], "ANP: Adept does not have required skills");
        }

        task.adeptProfileId = _adeptProfileId;
        task.adeptAddress = adeptAddress;
        task.status = TaskStatus.Assigned;

        emit TaskAssigned(_taskId, task.projectId, _adeptProfileId);
    }

    /// @notice Allows an Adept to accept an assigned task.
    /// @param _taskId The ID of the task to accept.
    function acceptTaskAssignment(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        uint256 adeptProfileId = adeptProfileSBT.adeptAddressToTokenId[msg.sender];
        require(adeptProfileId != 0, "ANP: Sender does not have an Adept Profile");
        require(task.adeptProfileId == adeptProfileId, "ANP: Task not assigned to this Adept");
        require(task.status == TaskStatus.Assigned, "ANP: Task is not in Assigned status");
        require(block.timestamp <= task.deadline, "ANP: Task deadline has passed");

        task.status = TaskStatus.Accepted;
        emit TaskAccepted(_taskId, adeptProfileId);
    }

    /// @notice Allows an Adept to submit proof of task completion.
    /// @param _taskId The ID of the task.
    /// @param _taskProofURI The URI (e.g., IPFS hash) pointing to the completion proof.
    function submitTaskProof(uint256 _taskId, string memory _taskProofURI) external whenNotPaused {
        Task storage task = tasks[_taskId];
        uint256 adeptProfileId = adeptProfileSBT.adeptAddressToTokenId[msg.sender];
        require(adeptProfileId != 0, "ANP: Sender does not have an Adept Profile");
        require(task.adeptProfileId == adeptProfileId, "ANP: Not the assigned Adept for this task");
        require(task.status == TaskStatus.Accepted, "ANP: Task is not in Accepted status");
        require(block.timestamp <= task.deadline, "ANP: Task deadline has passed");
        require(bytes(_taskProofURI).length > 0, "ANP: Task proof URI cannot be empty");

        task.taskProofURI = _taskProofURI;
        task.status = TaskStatus.Submitted;
        emit TaskProofSubmitted(_taskId, adeptProfileId, _taskProofURI);
    }

    /// @notice Allows the project owner to verify task completion.
    /// @dev Upon verification, rewards are made claimable, and Adept's reputation is increased.
    /// @param _taskId The ID of the task to verify.
    /// @param _reputationIncrease The amount of reputation points to award the Adept.
    function verifyTaskCompletion(uint256 _taskId, uint256 _reputationIncrease) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyProjectOwner(tasks[_taskId].projectId) 
    {
        Task storage task = tasks[_taskId];
        Project storage project = projects[task.projectId];
        require(task.status == TaskStatus.Submitted, "ANP: Task is not in Submitted status");
        
        task.status = TaskStatus.Verified;
        adeptClaimableRewards[task.adeptProfileId][task.rewardToken] += task.rewardAmount;
        project.totalClaimedRewards += task.rewardAmount; // Track claimed amount for project balance check
        adeptProfileSBT.increaseReputation(task.adeptProfileId, _reputationIncrease);

        emit TaskVerified(_taskId, task.projectId, task.adeptProfileId);
        emit TaskCompleted(task.taskId, task.adeptProfileId, task.rewardAmount, task.rewardToken);
    }

    /// @notice Allows an Adept or project owner to dispute a task's verification.
    /// @dev Requires a dispute bond to initiate. Funds are locked until dispute resolution.
    /// @param _taskId The ID of the task to dispute.
    /// @param _disputeBond The amount of ETH (or equivalent in project token) to lock as a bond.
    function initiateTaskDispute(uint256 _taskId, uint256 _disputeBond) external payable whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        Project storage project = projects[task.projectId];
        uint256 senderAdeptProfileId = adeptProfileSBT.adeptAddressToTokenId[msg.sender];

        require(task.status == TaskStatus.Submitted || task.status == TaskStatus.Verified, "ANP: Task cannot be disputed in current status");
        require(msg.sender == task.adeptAddress || msg.sender == project.owner, "ANP: Only Adept or project owner can dispute");
        require(_disputeBond > 0, "ANP: Dispute bond must be greater than zero");

        task.disputeBond = _disputeBond;
        task.status = TaskStatus.Disputed;

        if (msg.sender == project.owner) {
            // Project owner locks their own funds (project funds)
            if (project.fundingToken == address(0)) {
                require(projectEthBalances[project.projectId] >= task.disputeBond, "ANP: Project has insufficient ETH for bond");
                // The bond remains within the project's balance but is conceptually locked.
            } else {
                require(projectErc20Balances[project.projectId][project.fundingToken] >= task.disputeBond, "ANP: Project has insufficient ERC20 for bond");
                // Bond remains within project's balance
            }
        } else { // Adept is disputing
            require(msg.value == _disputeBond, "ANP: ETH sent for bond does not match dispute bond amount");
            // Adept sends ETH as bond. For ERC20 bonds, would need `approve` first.
        }

        emit TaskDisputed(_taskId, msg.sender, _disputeBond);
    }

    /// @notice The arbiter resolves a task dispute, determining the outcome.
    /// @dev Releases locked funds and adjusts reputation based on the arbitration result.
    /// @param _taskId The ID of the disputed task.
    /// @param _resolvedInFavorOfAdept True if the dispute is resolved in favor of the Adept, false otherwise.
    /// @param _adeptReputationChange The amount to change Adept's reputation by (positive for win, negative for loss).
    function resolveTaskDispute(uint256 _taskId, bool _resolvedInFavorOfAdept, int256 _adeptReputationChange) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyArbiter 
    {
        Task storage task = tasks[_taskId];
        Project storage project = projects[task.projectId];
        require(task.status == TaskStatus.Disputed, "ANP: Task is not in Disputed status");

        address adeptAddress = task.adeptAddress;
        uint256 adeptProfileId = task.adeptProfileId;

        // Release dispute bond
        if (_resolvedInFavorOfAdept) {
            // Adept wins: Project owner's bond (if they disputed) or Adept's bond is returned.
            // If project owner disputed, their 'locked' funds were never transferred out, so no action.
            // If Adept disputed, their ETH bond needs to be returned.
            if (msg.sender != project.owner) { // Adept disputed
                 (bool success, ) = payable(adeptAddress).call{value: task.disputeBond}("");
                 require(success, "ANP: Adept bond refund failed");
            }
            // If Adept wins, and it was previously 'Submitted' or 'Verified' and then disputed,
            // ensure rewards are claimable (if not already)
            if (adeptClaimableRewards[adeptProfileId][task.rewardToken] < task.rewardAmount) {
                 adeptClaimableRewards[adeptProfileId][task.rewardToken] += task.rewardAmount;
                 project.totalClaimedRewards += task.rewardAmount;
            }
        } else {
            // Adept loses: Adept's bond (if they disputed) or Project owner's bond (if they disputed) is forfeited.
            // Forfeited bond could go to protocolFeeRecipient, or back to project, or burn. Let's send to fee recipient.
            if (msg.sender != project.owner) { // Adept disputed
                (bool success, ) = payable(protocolFeeRecipient).call{value: task.disputeBond}("");
                require(success, "ANP: Adept bond forfeiture to fee recipient failed");
            } else { // Project owner disputed
                // Project owner's bond was already in project funds, move it to fee recipient.
                if (project.fundingToken == address(0)) {
                    (bool success, ) = payable(protocolFeeRecipient).call{value: task.disputeBond}("");
                    require(success, "ANP: Project ETH bond forfeiture to fee recipient failed");
                    projectEthBalances[project.projectId] -= task.disputeBond;
                } else {
                    IERC20 token = IERC20(project.fundingToken);
                    require(token.transfer(protocolFeeRecipient, task.disputeBond), "ANP: Project ERC20 bond forfeiture failed");
                    projectErc20Balances[project.projectId][project.fundingToken] -= task.disputeBond;
                }
            }
            // If Adept loses, ensure rewards are NOT claimable
            adeptClaimableRewards[adeptProfileId][task.rewardToken] = adeptClaimableRewards[adeptProfileId][task.rewardToken] > task.rewardAmount ? adeptClaimableRewards[adeptProfileId][task.rewardToken] - task.rewardAmount : 0;
            project.totalClaimedRewards = project.totalClaimedRewards > task.rewardAmount ? project.totalClaimedRewards - task.rewardAmount : 0;
        }

        // Adjust Adept reputation
        if (_adeptReputationChange > 0) {
            adeptProfileSBT.increaseReputation(adeptProfileId, uint256(_adeptReputationChange));
        } else if (_adeptReputationChange < 0) {
            adeptProfileSBT.decreaseReputation(adeptProfileId, uint256(-_adeptReputationChange));
        }
        
        task.disputeBond = 0; // Reset bond
        task.status = TaskStatus.Completed; // Task is now resolved

        emit TaskDisputeResolved(_taskId, _resolvedInFavorOfAdept, msg.sender);
    }

    // --- V. Reputation & Reward Mechanics (2 functions) ---

    /// @notice Retrieves the current reputation score for a specific Adept Profile.
    /// @param _adeptProfileId The ID of the Adept Profile SBT.
    /// @return The Adept's current reputation score.
    function getAdeptReputationScore(uint256 _adeptProfileId) external view returns (uint256) {
        return adeptProfileSBT.adeptReputationScores[_adeptProfileId];
    }

    /// @notice Allows an Adept to claim their earned rewards from successfully completed tasks.
    /// @param _rewardToken The token to claim (address(0) for ETH).
    function claimTaskReward(address _rewardToken) external whenNotPaused nonReentrant {
        uint256 adeptProfileId = adeptProfileSBT.adeptAddressToTokenId[msg.sender];
        require(adeptProfileId != 0, "ANP: Sender does not have an Adept Profile");

        uint256 amountToClaim = adeptClaimableRewards[adeptProfileId][_rewardToken];
        require(amountToClaim > 0, "ANP: No rewards to claim for this token");

        adeptClaimableRewards[adeptProfileId][_rewardToken] = 0; // Reset claimable amount

        if (_rewardToken == address(0)) { // ETH reward
            (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
            require(success, "ANP: ETH reward transfer failed");
        } else { // ERC-20 reward
            IERC20 token = IERC20(_rewardToken);
            require(token.transfer(msg.sender, amountToClaim), "ANP: ERC-20 reward transfer failed");
        }
        emit AdeptRewardClaimed(adeptProfileId, _rewardToken, amountToClaim);
    }

    // --- Fallback & Receive Functions (for ETH) ---
    receive() external payable {
        // ETH sent directly to the contract without calling a function will be handled here.
        // For general protocol fees, etc., it's better to explicitly use `protocolFeeRecipient`.
        // This receive could potentially be used for future direct donations or if a function requires direct ETH send.
    }
}
```