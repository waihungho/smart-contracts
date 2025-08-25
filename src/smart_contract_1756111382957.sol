This smart contract, `AdaptiveCognitiveDigitalTwinNetwork`, introduces a novel system for managing dynamic, AI-influenced Digital Twins (ACDTs) as NFTs. It aims to create a decentralized network where these digital entities can evolve, perform tasks, and collaborate, bringing together concepts of dynamic NFTs, reputation systems, AI integration (via oracles), and decentralized task management.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AdaptiveCognitiveDigitalTwinNetwork (ACDTN)
 * @author GPT-4
 * @notice This contract introduces a novel concept of dynamic, AI-influenced Digital Twins (ACDTs)
 *         represented as NFTs. ACDTs evolve based on tasks, external AI computations (via oracles),
 *         and user interactions. They can attach modules, form collaborations, and earn reputation.
 *         The network supports a task/bounty system, reputation-based access, and a simplified
 *         governance mechanism.
 *
 * Outline:
 * I. Core Data Structures & Events: Defines the building blocks for ACDTs, Modules, Tasks, and Bonds.
 * II. Storage: Mappings to store and retrieve all entities and their states.
 * III. Access Control: Basic roles for governance and oracle.
 * IV. ACDT Management: Functions for minting, viewing, and changing the status of Digital Twins.
 * V. ACDT Evolution & Attributes: Logic for experience gain, leveling up, reputation adjustment, and attribute updates (oracle-controlled).
 * VI. Module Management: System for defining, minting, attaching, and detaching functional modules (ERC1155-like components) to ACDTs.
 * VII. Task & Bounty System: Mechanism for proposing, accepting, verifying (via oracle), and rewarding off-chain AI tasks.
 * VIII. ACDT Collaboration/Bonding: Allows ACDTs to form temporary or long-term collaborative bonds.
 * IX. Governance & System Management: Functions for treasury management and updating critical system addresses.
 * X. Internal Helpers: Utility functions for common operations.
 *
 * Function Summary:
 *
 * A. ACDT Management (ERC721-like, custom logic)
 * 1.  mintACDT(string memory name, bytes memory initialAttributes): Mints a new ACDT NFT for the caller with initial, encoded attributes. Each ACDT is a unique digital entity.
 * 2.  getACDTDetails(uint256 acdtId): Retrieves comprehensive details (owner, name, level, experience, reputation, attributes, status, creation time) about a specific ACDT.
 * 3.  tokenURI(uint256 acdtId): Generates a dynamic URI for an ACDT's metadata, reflecting its current on-chain state (e.g., level, reputation, status).
 * 4.  setACDTStatus(uint256 acdtId, ACDTStatus newStatus): Allows an ACDT's owner to change its operational status (e.g., Active, Training, Dormant).
 *
 * B. ACDT Evolution & Attributes
 * 5.  updateACDTAttributes(uint256 acdtId, bytes memory encodedAttributes): (Oracle/Gov only) Updates an ACDT's core attributes. This is a key function for AI integration, typically called by a trusted oracle after verifiable off-chain AI computations.
 * 6.  gainExperience(uint256 acdtId, uint256 amount): Awards experience points to an ACDT. Experience contributes to leveling up and unlocking new capabilities.
 * 7.  _levelUpACDT(uint256 acdtId): (Internal) Increments an ACDT's level if its experience meets the threshold. Called automatically by `gainExperience`.
 * 8.  adjustReputation(uint256 acdtId, int256 delta): Modifies an ACDT's reputation score (can be positive or negative). Reputation impacts eligibility for tasks and collaborations.
 * 9.  getACDTLevelAndReputation(uint256 acdtId): Returns the current level and reputation of an ACDT.
 *
 * C. Module Management (ERC1155-like for shared component assets)
 * 10. createModuleDefinition(string memory name, string memory description, bytes memory effect): (Gov only) Defines a new type of functional module that can enhance ACDT capabilities.
 * 11. mintModuleTokens(uint256 moduleId, address recipient, uint256 amount): (Gov only) Mints new quantities of an existing module type for a recipient. Modules are fungible components.
 * 12. attachModule(uint256 acdtId, uint256 moduleId, uint256 quantity): Attaches owned module tokens to a specified ACDT, consuming them from the owner's balance.
 * 13. detachModule(uint256 acdtId, uint256 moduleId, uint256 quantity): Detaches modules from an ACDT, returning them to the owner's module token balance.
 * 14. getACDTAttachedModules(uint256 acdtId): Lists all module types and quantities currently attached to a specific ACDT.
 *
 * D. Task & Bounty System
 * 15. proposeTask(string memory taskCID, uint256 rewardAmount, uint256 minReputation, uint256 completionDeadline): Allows users to propose and fund tasks (e.g., AI compute jobs) for ACDTs. The reward is funded in Ether.
 * 16. acceptTask(uint256 taskId, uint256 acdtId): An ACDT owner assigns their ACDT to an open task, provided the ACDT meets the minimum reputation requirements.
 * 17. submitTaskResultHash(uint256 taskId, bytes32 resultHash, uint256 acdtId): (ACDT owner only) Submits a cryptographic hash of the off-chain task result, awaiting oracle verification.
 * 18. verifyTaskCompletion(uint256 taskId, bool success, uint256 acdtId, uint256 actualGasCost, bytes memory verifiableProof): (Oracle only) Verifies the off-chain task result based on the submitted hash and potentially `verifiableProof`. Distributes rewards, adjusts ACDT reputation, and awards experience.
 * 19. cancelTask(uint256 taskId): (Proposer or Gov only) Cancels an unassigned or overdue task, refunding the reward to the proposer.
 *
 * E. ACDT Collaboration/Bonding
 * 20. initiateACDTBond(uint256 acdtIdA, uint256 acdtIdB, uint256 durationInDays): Initiates a collaborative bond proposal between two ACDTs.
 * 21. acceptACDTBond(uint256 bondId): The owner of the second ACDT accepts a bond proposal, formalizing the collaboration.
 * 22. dissolveACDTBond(uint256 bondId): Allows either party to dissolve an active bond.
 * 23. getACDTBonds(uint256 acdtId): Retrieves a list of all active or pending bonds associated with a specific ACDT.
 *
 * F. Governance & System Management
 * 24. fundTreasury(): Allows any user to contribute Ether to the contract's treasury.
 * 25. withdrawTreasuryFunds(address recipient, uint256 amount): (Gov only) Allows the governance entity to withdraw funds from the contract treasury.
 * 26. setOracleAddress(address newOracle): (Gov only) Updates the address of the trusted oracle, a critical role for task verification.
 * 27. setGovernanceAddress(address newGovernance): (Gov only) Updates the governance address, transferring administrative control of the contract.
 */
contract AdaptiveCognitiveDigitalTwinNetwork {

    // --- I. Core Data Structures & Events ---

    enum ACDTStatus { Active, Training, Dormant, Deactivated }
    enum TaskStatus { Open, Assigned, ResultSubmitted, VerifiedSuccess, VerifiedFailure, Cancelled }
    enum BondStatus { Pending, Active, Dissolved }

    struct ACDT {
        address owner;
        string name;
        uint256 level;
        uint256 experience;
        int256 reputation; // Can be negative for poor performance
        bytes attributes; // Encoded data representing the ACDT's cognitive traits, skills, etc.
        ACDTStatus status;
        uint256 creationTime;
    }

    struct ModuleDefinition {
        string name;
        string description;
        bytes effect; // Encoded data describing the module's function/impact
        uint256 totalMinted;
    }

    struct Task {
        uint256 id;
        address proposer;
        string taskCID; // Content Identifier for task details (e.g., IPFS hash)
        uint256 rewardAmount;
        uint256 minReputation;
        uint256 completionDeadline;
        uint256 assignedACDTId; // 0 if not assigned
        bytes32 resultHash; // Hash of the off-chain result, verified by oracle
        TaskStatus status;
    }

    struct Bond {
        uint256 id;
        uint256 acdtIdA;
        uint256 acdtIdB;
        uint256 startTime;
        uint256 endTime;
        BondStatus status;
    }

    event ACDTMinted(uint256 indexed acdtId, address indexed owner, string name, bytes initialAttributes);
    event ACDTStatusUpdated(uint256 indexed acdtId, ACDTStatus newStatus);
    event ACDTAttributesUpdated(uint256 indexed acdtId, bytes newAttributes);
    event ACDTExperienceGained(uint256 indexed acdtId, uint256 amount, uint256 newExperience, uint256 newLevel);
    event ACDTReputationAdjusted(uint256 indexed acdtId, int256 delta, int256 newReputation);

    event ModuleDefinitionCreated(uint256 indexed moduleId, string name);
    event ModuleTokensMinted(uint256 indexed moduleId, address indexed recipient, uint256 amount);
    event ModuleAttached(uint256 indexed acdtId, uint256 indexed moduleId, uint256 quantity);
    event ModuleDetached(uint256 indexed acdtId, uint256 indexed moduleId, uint256 quantity);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, string taskCID, uint256 rewardAmount);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed acdtId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed acdtId, bytes32 resultHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed acdtId, bool success, uint256 rewardGiven);
    event TaskCancelled(uint256 indexed taskId);

    event ACDTBondInitiated(uint256 indexed bondId, uint256 indexed acdtIdA, uint256 indexed acdtIdB, uint256 durationInDays);
    event ACDTBondAccepted(uint256 indexed bondId);
    event ACDTBondDissolved(uint256 indexed bondId);

    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event GovernanceAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // --- II. Storage ---

    uint256 private _nextTokenId; // For ACDTs (ERC721-like)
    mapping(uint256 => ACDT) private _acdtData;
    mapping(uint256 => address) private _acdtOwners;
    mapping(address => uint256) private _acdtBalances; // ERC721-like balance

    uint256 private _nextModuleId; // For Module Definitions (ERC1155-like)
    mapping(uint256 => ModuleDefinition) private _moduleDefinitions;
    mapping(address => mapping(uint256 => uint256)) private _moduleBalances; // ERC1155-like module token balances
    mapping(uint256 => mapping(uint256 => uint256)) private _acdtAttachedModules; // ACDT ID => Module ID => Quantity

    uint256 private _nextTaskId;
    mapping(uint256 => Task) private _tasks;

    uint256 private _nextBondId;
    mapping(uint256 => Bond) private _bonds;
    mapping(uint256 => uint256[]) private _acdtBondList; // ACDT ID => list of Bond IDs it's involved in

    // --- III. Access Control ---

    address public governanceAddress;
    address public oracleAddress;

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "ACDTN: Caller is not the governance");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ACDTN: Caller is not the oracle");
        _;
    }

    modifier onlyACDTOwner(uint256 acdtId) {
        require(_acdtOwners[acdtId] == msg.sender, "ACDTN: Caller is not the ACDT owner");
        _;
    }

    modifier acdtExists(uint256 acdtId) {
        require(_acdtOwners[acdtId] != address(0), "ACDTN: ACDT does not exist");
        _;
    }

    constructor(address initialGovernance, address initialOracle) {
        require(initialGovernance != address(0), "ACDTN: Initial governance address cannot be zero");
        require(initialOracle != address(0), "ACDTN: Initial oracle address cannot be zero");
        governanceAddress = initialGovernance;
        oracleAddress = initialOracle;
        _nextTokenId = 1; // Start ACDT IDs from 1
        _nextModuleId = 1; // Start Module IDs from 1
        _nextTaskId = 1; // Start Task IDs from 1
        _nextBondId = 1; // Start Bond IDs from 1
    }

    // --- IV. ACDT Management ---

    /**
     * @notice Mints a new Adaptive Cognitive Digital Twin (ACDT) NFT for the caller.
     * @dev Each ACDT is a unique NFT representing an evolving digital entity.
     * @param name The human-readable name for the ACDT.
     * @param initialAttributes Initial encoded attributes for the ACDT. These attributes can represent
     *                          its baseline cognitive traits or initial capabilities.
     * @return The ID of the newly minted ACDT.
     */
    function mintACDT(string memory name, bytes memory initialAttributes) external returns (uint256) {
        uint256 newACDTId = _nextTokenId++;
        _acdtData[newACDTId] = ACDT({
            owner: msg.sender,
            name: name,
            level: 1, // Start at Level 1
            experience: 0,
            reputation: 0,
            attributes: initialAttributes,
            status: ACDTStatus.Active,
            creationTime: block.timestamp
        });
        _acdtOwners[newACDTId] = msg.sender;
        _acdtBalances[msg.sender]++;

        emit ACDTMinted(newACDTId, msg.sender, name, initialAttributes);
        return newACDTId;
    }

    /**
     * @notice Retrieves all stored details of a specific ACDT.
     * @param acdtId The ID of the ACDT.
     * @return owner The current owner's address.
     * @return name The name of the ACDT.
     * @return level The current level of the ACDT.
     * @return experience The current experience points of the ACDT.
     * @return reputation The current reputation score of the ACDT.
     * @return attributes The encoded attributes of the ACDT.
     * @return status The current operational status of the ACDT.
     * @return creationTime The timestamp of ACDT creation.
     */
    function getACDTDetails(uint256 acdtId) external view acdtExists(acdtId) returns (
        address owner,
        string memory name,
        uint256 level,
        uint256 experience,
        int256 reputation,
        bytes memory attributes,
        ACDTStatus status,
        uint256 creationTime
    ) {
        ACDT storage acdt = _acdtData[acdtId];
        return (
            acdt.owner,
            acdt.name,
            acdt.level,
            acdt.experience,
            acdt.reputation,
            acdt.attributes,
            acdt.status,
            acdt.creationTime
        );
    }

    /**
     * @notice Generates a dynamic URI for an ACDT's metadata, reflecting its current state.
     * @dev In a real application, this would point to an off-chain service that
     *      constructs JSON metadata based on the on-chain state, or utilize an
     *      on-chain base64 encoder for full data URI compliance.
     * @param acdtId The ID of the ACDT.
     * @return A string representing the token URI.
     */
    function tokenURI(uint256 acdtId) external view acdtExists(acdtId) returns (string memory) {
        ACDT storage acdt = _acdtData[acdtId];
        // Simplified JSON construction for demonstration.
        // A full implementation would encode this to Base64 and prefix with "data:application/json;base64,"
        // or point to an off-chain API.
        bytes memory json = abi.encodePacked(
            '{"name": "', acdt.name, ' #', _toString(acdtId), '",',
            '"description": "An Adaptive Cognitive Digital Twin (ACDT), evolving based on tasks and interactions.",',
            '"image": "ipfs://QmdyC3qD19mK2j9wE9z4h6G7x8L5pB0v0u1s2t3r4a5",', // Placeholder for an image representing an ACDT
            '"attributes": [',
                '{"trait_type": "Level", "value": ', _toString(acdt.level), '},',
                '{"trait_type": "Reputation", "value": ', _toString(acdt.reputation), '},',
                '{"trait_type": "Status", "value": "', _statusToString(acdt.status), '"}',
            ']}'
        );
        return string(abi.encodePacked("data:application/json;utf8,", json)); // Using utf8 for direct json string
    }

    /**
     * @notice Allows an ACDT's owner to change its operational status.
     * @dev For example, an ACDT could be set to `Dormant` to save resources or `Training` when actively learning.
     * @param acdtId The ID of the ACDT.
     * @param newStatus The desired new status (e.g., Active, Training, Dormant, Deactivated).
     */
    function setACDTStatus(uint256 acdtId, ACDTStatus newStatus) external onlyACDTOwner(acdtId) acdtExists(acdtId) {
        _acdtData[acdtId].status = newStatus;
        emit ACDTStatusUpdated(acdtId, newStatus);
    }

    // --- V. ACDT Evolution & Attributes ---

    /**
     * @notice Updates the core attributes of an ACDT.
     * @dev This function is intended to be called by a trusted oracle after verifiable off-chain
     *      AI computations or governance decisions. These attributes (e.g., skill parameters,
     *      personality traits) define the ACDT's capabilities and influence its behavior.
     * @param acdtId The ID of the ACDT.
     * @param encodedAttributes The new, encoded attributes. The format of these bytes
     *                          is application-specific and interpreted off-chain.
     */
    function updateACDTAttributes(uint256 acdtId, bytes memory encodedAttributes) external onlyOracle acdtExists(acdtId) {
        _acdtData[acdtId].attributes = encodedAttributes;
        emit ACDTAttributesUpdated(acdtId, encodedAttributes);
    }

    /**
     * @notice Awards experience points to an ACDT.
     * @dev Experience contributes to leveling up the ACDT, unlocking new capabilities and potentially
     *      influencing attribute development. This is an internal function, typically called after
     *      successful task completion.
     * @param acdtId The ID of the ACDT.
     * @param amount The amount of experience to add.
     */
    function gainExperience(uint256 acdtId, uint256 amount) internal acdtExists(acdtId) {
        ACDT storage acdt = _acdtData[acdtId];
        acdt.experience += amount;
        emit ACDTExperienceGained(acdtId, amount, acdt.experience, acdt.level);
        // Automatically check and trigger level up if threshold reached
        if (acdt.experience >= _experienceToNextLevel(acdt.level)) {
            _levelUpACDT(acdtId);
        }
    }

    /**
     * @notice Increments an ACDT's level if its experience meets the threshold.
     * @dev This is an internal function, called automatically by `gainExperience` when conditions are met.
     * @param acdtId The ID of the ACDT.
     */
    function _levelUpACDT(uint256 acdtId) internal acdtExists(acdtId) {
        ACDT storage acdt = _acdtData[acdtId];
        uint256 requiredExp = _experienceToNextLevel(acdt.level);
        while (acdt.experience >= requiredExp) {
            acdt.level++;
            // Carry over excess experience to the next level's progression
            acdt.experience -= requiredExp;
            requiredExp = _experienceToNextLevel(acdt.level);
            // Additional logic for level up rewards, attribute boosts, etc., can be added here.
            // For instance, triggering an oracle call to update attributes based on new level.
        }
        // Emit an event to indicate a level-up, even if no new experience was added directly.
        emit ACDTExperienceGained(acdtId, 0, acdt.experience, acdt.level);
    }

    /**
     * @notice Modifies an ACDT's reputation score.
     * @dev Reputation impacts eligibility for more complex tasks and collaborations. It can be positive (for success)
     *      or negative (for failure or poor performance). This is an internal function, usually called by the oracle.
     * @param acdtId The ID of the ACDT.
     * @param delta The amount to adjust reputation by (positive or negative).
     */
    function adjustReputation(uint256 acdtId, int256 delta) internal acdtExists(acdtId) {
        ACDT storage acdt = _acdtData[acdtId];
        acdt.reputation += delta;
        emit ACDTReputationAdjusted(acdtId, delta, acdt.reputation);
    }

    /**
     * @notice Returns the current level and reputation of an ACDT.
     * @param acdtId The ID of the ACDT.
     * @return level The current level of the ACDT.
     * @return reputation The current reputation score of the ACDT.
     */
    function getACDTLevelAndReputation(uint256 acdtId) external view acdtExists(acdtId) returns (uint256 level, int256 reputation) {
        ACDT storage acdt = _acdtData[acdtId];
        return (acdt.level, acdt.reputation);
    }

    // --- VI. Module Management ---

    /**
     * @notice Creates a new definition for a module type.
     * @dev Only governance can define new module types. Modules are ERC1155-like fungible components
     *      that can be attached to ACDTs to enhance their capabilities (e.g., "Language Pack," "Compute Unit").
     * @param name The name of the module (e.g., "Advanced Vision Module").
     * @param description A brief description of the module's function or utility.
     * @param effect Encoded data describing the module's specific impact or functionality,
     *               interpreted by off-chain AI models or ACDT logic.
     * @return The ID of the newly created module definition.
     */
    function createModuleDefinition(string memory name, string memory description, bytes memory effect) external onlyGovernance returns (uint256) {
        uint256 newModuleId = _nextModuleId++;
        _moduleDefinitions[newModuleId] = ModuleDefinition({
            name: name,
            description: description,
            effect: effect,
            totalMinted: 0
        });
        emit ModuleDefinitionCreated(newModuleId, name);
        return newModuleId;
    }

    /**
     * @notice Mints new tokens for a specific module type and sends them to a recipient.
     * @dev Only governance can mint new quantities of existing modules. These are fungible,
     *      allowing for shared ownership and trading.
     * @param moduleId The ID of the module definition to mint.
     * @param recipient The address to receive the minted module tokens.
     * @param amount The quantity of module tokens to mint.
     */
    function mintModuleTokens(uint256 moduleId, address recipient, uint256 amount) external onlyGovernance {
        require(_moduleDefinitions[moduleId].name != "", "ACDTN: Module definition does not exist");
        _moduleBalances[recipient][moduleId] += amount;
        _moduleDefinitions[moduleId].totalMinted += amount; // Track total supply
        emit ModuleTokensMinted(moduleId, recipient, amount);
    }

    /**
     * @notice Attaches a specified quantity of an owned module to an ACDT.
     * @dev The module tokens are moved from the owner's balance to be "attached" to the ACDT.
     *      Requires the caller to own both the module tokens and the ACDT.
     * @param acdtId The ID of the ACDT to attach modules to.
     * @param moduleId The ID of the module type to attach.
     * @param quantity The quantity of modules to attach.
     */
    function attachModule(uint256 acdtId, uint256 moduleId, uint256 quantity) external onlyACDTOwner(acdtId) acdtExists(acdtId) {
        require(_moduleDefinitions[moduleId].name != "", "ACDTN: Module definition does not exist");
        require(_moduleBalances[msg.sender][moduleId] >= quantity, "ACDTN: Insufficient module tokens");
        require(quantity > 0, "ACDTN: Quantity must be positive");

        _moduleBalances[msg.sender][moduleId] -= quantity;
        _acdtAttachedModules[acdtId][moduleId] += quantity;

        emit ModuleAttached(acdtId, moduleId, quantity);
    }

    /**
     * @notice Detaches modules from an ACDT, returning them to the owner's balance.
     * @dev The module tokens are moved from the ACDT's attached state back to the owner's fungible balance.
     * @param acdtId The ID of the ACDT to detach modules from.
     * @param moduleId The ID of the module type to detach.
     * @param quantity The quantity of modules to detach.
     */
    function detachModule(uint256 acdtId, uint256 moduleId, uint256 quantity) external onlyACDTOwner(acdtId) acdtExists(acdtId) {
        require(_moduleDefinitions[moduleId].name != "", "ACDTN: Module definition does not exist");
        require(_acdtAttachedModules[acdtId][moduleId] >= quantity, "ACDTN: ACDT does not have enough of this module attached");
        require(quantity > 0, "ACDTN: Quantity must be positive");

        _acdtAttachedModules[acdtId][moduleId] -= quantity;
        _moduleBalances[msg.sender][moduleId] += quantity;

        emit ModuleDetached(acdtId, moduleId, quantity);
    }

    /**
     * @notice Lists all module types and quantities currently attached to an ACDT.
     * @param acdtId The ID of the ACDT.
     * @return An array of `moduleId`s and a corresponding array of `quantity`s.
     */
    function getACDTAttachedModules(uint256 acdtId) external view acdtExists(acdtId) returns (uint256[] memory moduleIds, uint256[] memory quantities) {
        uint256 count = 0;
        // Iterate through possible module IDs to find attached ones.
        // This could be optimized if the number of modules is very large by tracking attached module IDs.
        for (uint256 i = 1; i < _nextModuleId; i++) {
            if (_acdtAttachedModules[acdtId][i] > 0) {
                count++;
            }
        }

        moduleIds = new uint256[](count);
        quantities = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 1; i < _nextModuleId; i++) {
            if (_acdtAttachedModules[acdtId][i] > 0) {
                moduleIds[idx] = i;
                quantities[idx] = _acdtAttachedModules[acdtId][i];
                idx++;
            }
        }
        return (moduleIds, quantities);
    }

    // --- VII. Task & Bounty System ---

    /**
     * @notice Proposes a new task for an ACDT to perform.
     * @dev The task proposer must fund the reward in Ether when calling this function.
     *      Task details (description, requirements) are referenced by a Content Identifier (CID),
     *      which typically points to off-chain storage like IPFS.
     * @param taskCID Content Identifier (e.g., IPFS hash) pointing to the detailed task description.
     * @param rewardAmount The amount of Ether to reward for successful completion.
     * @param minReputation The minimum reputation an ACDT needs to be eligible to accept this task.
     * @param completionDeadline The timestamp by which the task must be completed.
     * @return The ID of the newly proposed task.
     */
    function proposeTask(
        string memory taskCID,
        uint256 rewardAmount,
        uint256 minReputation,
        uint256 completionDeadline
    ) external payable returns (uint256) {
        require(msg.value == rewardAmount, "ACDTN: Sent Ether must match reward amount");
        require(completionDeadline > block.timestamp, "ACDTN: Deadline must be in the future");
        require(rewardAmount > 0, "ACDTN: Reward amount must be positive");

        uint256 newTaskId = _nextTaskId++;
        _tasks[newTaskId] = Task({
            id: newTaskId,
            proposer: msg.sender,
            taskCID: taskCID,
            rewardAmount: rewardAmount,
            minReputation: minReputation,
            completionDeadline: completionDeadline,
            assignedACDTId: 0, // Not assigned initially
            resultHash: bytes32(0),
            status: TaskStatus.Open
        });

        emit TaskProposed(newTaskId, msg.sender, taskCID, rewardAmount);
        return newTaskId;
    }

    /**
     * @notice Assigns an ACDT (owned by the caller) to an open task.
     * @dev The ACDT must meet the minimum reputation requirement for the task, and the task must be
     *      `Open` and not yet expired. The ACDT's status is temporarily set to `Training`.
     * @param taskId The ID of the task to accept.
     * @param acdtId The ID of the ACDT to assign to the task.
     */
    function acceptTask(uint256 taskId, uint256 acdtId) external onlyACDTOwner(acdtId) acdtExists(acdtId) {
        Task storage task = _tasks[taskId];
        require(task.id != 0, "ACDTN: Task does not exist");
        require(task.status == TaskStatus.Open, "ACDTN: Task is not open");
        require(block.timestamp < task.completionDeadline, "ACDTN: Task has expired");
        require(_acdtData[acdtId].reputation >= int256(task.minReputation), "ACDTN: ACDT does not meet minimum reputation");
        require(_acdtData[acdtId].status == ACDTStatus.Active, "ACDTN: ACDT must be active to accept tasks");

        task.assignedACDTId = acdtId;
        task.status = TaskStatus.Assigned;
        _acdtData[acdtId].status = ACDTStatus.Training; // ACDT is now occupied with the task

        emit TaskAccepted(taskId, acdtId);
    }

    /**
     * @notice Submits a cryptographic hash of the off-chain task result for later oracle verification.
     * @dev Only the owner of the assigned ACDT can submit the result. The actual task computation
     *      and result generation occur off-chain.
     * @param taskId The ID of the task.
     * @param resultHash A hash (e.g., Keccak256) representing the completed task's output or proof.
     * @param acdtId The ID of the ACDT that completed the task.
     */
    function submitTaskResultHash(uint256 taskId, bytes32 resultHash, uint256 acdtId) external onlyACDTOwner(acdtId) acdtExists(acdtId) {
        Task storage task = _tasks[taskId];
        require(task.id != 0, "ACDTN: Task does not exist");
        require(task.assignedACDTId == acdtId, "ACDTN: ACDT not assigned to this task");
        require(task.status == TaskStatus.Assigned, "ACDTN: Task is not in Assigned status");
        require(block.timestamp < task.completionDeadline, "ACDTN: Task deadline passed");
        require(resultHash != bytes32(0), "ACDTN: Result hash cannot be zero");

        task.resultHash = resultHash;
        task.status = TaskStatus.ResultSubmitted;
        _acdtData[acdtId].status = ACDTStatus.Active; // ACDT is free while awaiting verification

        emit TaskResultSubmitted(taskId, acdtId, resultHash);
    }

    /**
     * @notice Verifies the off-chain task result and distributes rewards.
     * @dev This function is called by the trusted oracle after external verification of the `resultHash`
     *      and `verifiableProof`. If successful, the ACDT's owner receives the reward, and the ACDT
     *      gains experience and reputation.
     * @param taskId The ID of the task.
     * @param success True if the task was successfully completed, false otherwise.
     * @param acdtId The ID of the ACDT that performed the task.
     * @param actualGasCost The actual gas/computation cost incurred by the ACDT off-chain (can influence experience/reputation).
     * @param verifiableProof An encoded proof for the oracle's verification (e.g., ZK-proof, cryptographic signature).
     *                        The verification itself happens off-chain, and the oracle asserts the outcome.
     */
    function verifyTaskCompletion(
        uint256 taskId,
        bool success,
        uint256 acdtId,
        uint256 actualGasCost,
        bytes memory verifiableProof // Placeholder for a complex proof used by the oracle
    ) external onlyOracle acdtExists(acdtId) {
        Task storage task = _tasks[taskId];
        require(task.id != 0, "ACDTN: Task does not exist");
        require(task.assignedACDTId == acdtId, "ACDTN: ACDT not assigned to this task");
        require(task.status == TaskStatus.ResultSubmitted, "ACDTN: Task result not submitted or already verified");

        // The 'verifiableProof' would be used by the oracle (off-chain) to confirm the hash.
        // On-chain, we simply trust the oracle's decision based on their provided proof.

        uint256 rewardToGive = 0;
        int256 reputationChange = 0;
        uint256 experienceGain = 0;

        if (success) {
            rewardToGive = task.rewardAmount;
            reputationChange = 10; // Positive reputation for success
            experienceGain = 100 + (actualGasCost / 1000); // Base exp + bonus for complex/costly tasks
            task.status = TaskStatus.VerifiedSuccess;
            // Transfer reward to ACDT owner from contract's balance (which holds task rewards)
            _transferEther(address(this), acdtId, _acdtOwners[acdtId], rewardToGive);
        } else {
            reputationChange = -5; // Negative reputation for failure
            task.status = TaskStatus.VerifiedFailure;
            // For now, if task fails, reward is kept in contract treasury (could be burned or returned to proposer)
        }

        adjustReputation(acdtId, reputationChange);
        if (experienceGain > 0) {
            gainExperience(acdtId, experienceGain);
        }

        emit TaskVerified(taskId, acdtId, success, rewardToGive);
    }

    /**
     * @notice Cancels an unassigned or overdue task, refunding the reward to the proposer.
     * @dev Only the task proposer or governance can cancel a task. A task can be cancelled
     *      if it's `Open` or if its `completionDeadline` has passed.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 taskId) external {
        Task storage task = _tasks[taskId];
        require(task.id != 0, "ACDTN: Task does not exist");
        require(task.proposer == msg.sender || governanceAddress == msg.sender, "ACDTN: Only proposer or governance can cancel");
        require(task.status == TaskStatus.Open || block.timestamp > task.completionDeadline, "ACDTN: Task cannot be cancelled in its current state or before deadline");
        require(task.status != TaskStatus.VerifiedSuccess && task.status != TaskStatus.VerifiedFailure, "ACDTN: Task already completed");

        if (task.status == TaskStatus.Assigned) {
            // If assigned, revert ACDT status from 'Training' back to 'Active'
            _acdtData[task.assignedACDTId].status = ACDTStatus.Active;
        }

        task.status = TaskStatus.Cancelled;
        // Refund the reward amount from the contract's balance back to the proposer
        _transferEther(address(this), 0, task.proposer, task.rewardAmount);
        emit TaskCancelled(taskId);
    }

    // --- VIII. ACDT Collaboration/Bonding ---

    /**
     * @notice Initiates a collaborative bond proposal between two ACDTs.
     * @dev For simplicity, this assumes both ACDTs are owned by the `msg.sender`.
     *      In a more complex system, `acdtIdB` could be owned by another user,
     *      requiring an ERC721 `approve` or similar delegation mechanism.
     * @param acdtIdA The ID of the first ACDT. The caller must own this ACDT.
     * @param acdtIdB The ID of the second ACDT. The caller must also own this ACDT for this simplified example.
     * @param durationInDays The proposed duration for which the bond will be active, in days.
     * @return The ID of the newly created bond proposal.
     */
    function initiateACDTBond(uint256 acdtIdA, uint256 acdtIdB, uint256 durationInDays) external onlyACDTOwner(acdtIdA) returns (uint256) {
        require(acdtIdA != acdtIdB, "ACDTN: Cannot bond an ACDT with itself");
        require(_acdtOwners[acdtIdB] == msg.sender, "ACDTN: Caller must own both ACDTs to initiate bond for now"); // Simplified
        // Check if a similar bond already exists or is pending
        for (uint256 i = 0; i < _acdtBondList[acdtIdA].length; i++) {
            Bond storage existingBond = _bonds[_acdtBondList[acdtIdA][i]];
            if ((existingBond.acdtIdA == acdtIdB && existingBond.acdtIdB == acdtIdA) ||
                (existingBond.acdtIdA == acdtIdA && existingBond.acdtIdB == acdtIdB)) {
                require(existingBond.status != BondStatus.Pending && existingBond.status != BondStatus.Active, "ACDTN: Existing pending or active bond found between these ACDTs");
            }
        }


        uint256 newBondId = _nextBondId++;
        _bonds[newBondId] = Bond({
            id: newBondId,
            acdtIdA: acdtIdA,
            acdtIdB: acdtIdB,
            startTime: 0, // Set upon acceptance
            endTime: block.timestamp + (durationInDays * 1 days),
            status: BondStatus.Pending
        });

        _acdtBondList[acdtIdA].push(newBondId);
        _acdtBondList[acdtIdB].push(newBondId);

        emit ACDTBondInitiated(newBondId, acdtIdA, acdtIdB, durationInDays);
        return newBondId;
    }

    /**
     * @notice The owner of the second ACDT accepts a bond proposal.
     * @dev In the simplified model where both are owned by `msg.sender`, this would still be called
     *      to finalize the bond if `initiateACDTBond` only proposed (e.g., if there were a UI with two steps).
     *      If `acdtIdB` were owned by another user, this would be their action.
     * @param bondId The ID of the bond to accept.
     */
    function acceptACDTBond(uint256 bondId) external {
        Bond storage bond = _bonds[bondId];
        require(bond.id != 0, "ACDTN: Bond does not exist");
        require(bond.status == BondStatus.Pending, "ACDTN: Bond is not pending");
        require(_acdtOwners[bond.acdtIdB] == msg.sender, "ACDTN: Caller is not the owner of ACDT B to accept");

        bond.status = BondStatus.Active;
        bond.startTime = block.timestamp; // Start the bond timer now
        emit ACDTBondAccepted(bondId);
    }

    /**
     * @notice Allows either party to dissolve an active bond.
     * @dev This function could include penalties for early dissolution or specific rules for
     *      resource distribution if the bond involved shared resources.
     * @param bondId The ID of the bond to dissolve.
     */
    function dissolveACDTBond(uint256 bondId) external {
        Bond storage bond = _bonds[bondId];
        require(bond.id != 0, "ACDTN: Bond does not exist");
        require(bond.status == BondStatus.Active, "ACDTN: Bond is not active");
        require(_acdtOwners[bond.acdtIdA] == msg.sender || _acdtOwners[bond.acdtIdB] == msg.sender, "ACDTN: Caller is not a party to this bond");

        bond.status = BondStatus.Dissolved;
        // Optionally, implement penalties or effects of dissolution (e.g., reputation penalty)
        emit ACDTBondDissolved(bondId);
    }

    /**
     * @notice Retrieves a list of all active or pending bonds associated with an ACDT.
     * @param acdtId The ID of the ACDT.
     * @return An array of bond IDs that this ACDT is involved in.
     */
    function getACDTBonds(uint256 acdtId) external view acdtExists(acdtId) returns (uint256[] memory) {
        return _acdtBondList[acdtId];
    }

    // --- IX. Governance & System Management ---

    /**
     * @notice Allows any user to contribute Ether to the contract's treasury.
     * @dev This treasury can be used to fund various network initiatives, research, or bounties.
     */
    function fundTreasury() external payable {
        require(msg.value > 0, "ACDTN: Amount must be positive");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows governance to withdraw funds from the contract treasury.
     * @dev This function is critical and protected by `onlyGovernance`.
     * @param recipient The address to send the funds to.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawTreasuryFunds(address recipient, uint256 amount) external onlyGovernance {
        _transferEther(address(this), 0, recipient, amount);
        emit FundsWithdrawn(recipient, amount);
    }

    /**
     * @notice Updates the trusted oracle address.
     * @dev Only governance can change the oracle, which is a critical role for task verification
     *      and ACDT attribute updates.
     * @param newOracle The address of the new oracle.
     */
    function setOracleAddress(address newOracle) external onlyGovernance {
        require(newOracle != address(0), "ACDTN: New oracle address cannot be zero");
        address oldOracle = oracleAddress;
        oracleAddress = newOracle;
        emit OracleAddressUpdated(oldOracle, newOracle);
    }

    /**
     * @notice Updates the governance address.
     * @dev This is a critical function, effectively transferring control of the contract
     *      to a new governance entity.
     * @param newGovernance The address of the new governance entity.
     */
    function setGovernanceAddress(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "ACDTN: New governance address cannot be zero");
        address oldGovernance = governanceAddress;
        governanceAddress = newGovernance;
        emit GovernanceAddressUpdated(oldGovernance, newGovernance);
    }

    // --- X. Internal Helpers ---

    /**
     * @dev Calculates the experience required for the next level.
     * @param currentLevel The current level of the ACDT.
     * @return The experience points needed to reach the next level.
     */
    function _experienceToNextLevel(uint256 currentLevel) internal pure returns (uint256) {
        // Simple linear progression for demonstration.
        // Can be an exponential function or more complex formula for difficulty scaling.
        return 1000 + (currentLevel * 200);
    }

    /**
     * @dev Converts an unsigned integer to its string representation.
     * @param val The unsigned integer to convert.
     * @return The string representation of the integer.
     */
    function _toString(uint256 val) internal pure returns (string memory) {
        if (val == 0) return "0";
        uint256 temp = val;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (val != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (val % 10)));
            val /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a signed integer (int256) to its string representation, handling negative values.
     * @param val The signed integer to convert.
     * @return The string representation of the integer.
     */
    function _toString(int256 val) internal pure returns (string memory) {
        if (val == 0) return "0";
        bool negative = false;
        uint256 absVal;
        if (val < 0) {
            negative = true;
            absVal = uint256(-val);
        } else {
            absVal = uint256(val);
        }

        uint256 temp = absVal;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer;
        if (negative) {
            buffer = new bytes(digits + 1); // +1 for the '-' sign
            buffer[0] = '-';
        } else {
            buffer = new bytes(digits);
        }

        uint256 idx = digits;
        if (negative) idx++; // Adjust starting index for negative sign
        while (absVal != 0) {
            idx--;
            buffer[idx] = bytes1(uint8(48 + (absVal % 10)));
            absVal /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts an ACDTStatus enum value to its human-readable string representation.
     * @param status The ACDTStatus enum value.
     * @return The string representation of the status.
     */
    function _statusToString(ACDTStatus status) internal pure returns (string memory) {
        if (status == ACDTStatus.Active) return "Active";
        if (status == ACDTStatus.Training) return "Training";
        if (status == ACDTStatus.Dormant) return "Dormant";
        if (status == ACDTStatus.Deactivated) return "Deactivated";
        return "Unknown"; // Should ideally not be reached
    }

    /**
     * @dev Internal function to handle Ether transfers, with basic re-entrancy protection.
     * @param source The address from which to transfer Ether (can be `address(this)` for contract balance).
     * @param fromACDTId Optional: The ACDT ID from which funds are conceptually coming (for tracking, not actual transfer logic).
     * @param recipient The address to receive the Ether.
     * @param amount The amount of Ether to transfer.
     */
    function _transferEther(address source, uint256 fromACDTId, address recipient, uint256 amount) internal {
        // State changes should ideally happen before this call in the calling functions
        // to mitigate re-entrancy risks.
        require(amount > 0, "ACDTN: Amount must be positive");
        require(source.balance >= amount, "ACDTN: Insufficient balance for transfer from source");
        
        // Using call for flexibility and to avoid gas limit issues with transfer/send,
        // while also being the recommended pattern for external calls.
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ACDTN: Ether transfer failed");
    }

    // --- Fallback function to receive Ether ---
    /**
     * @notice Allows the contract to receive Ether directly, primarily for funding the treasury.
     */
    receive() external payable {
        fundTreasury();
    }
}
```