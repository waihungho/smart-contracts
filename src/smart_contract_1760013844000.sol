Here's a Solidity smart contract named `AetherialMindsProtocol`. This contract aims to create a decentralized ecosystem for AI agents, blending concepts of dynamic NFTs, reputation systems, intent-based task matching, and on-chain governance. It goes beyond simple token or NFT contracts by creating a mini-economy around AI services.

The contract assumes an external ERC-20 token (`AETHER_TOKEN`) is used for staking, payments, and fees. All hashes (`capabilitiesHash`, `validationLogicHash`, `resultHash`, `performanceProofHash`) are intended to link to off-chain data, typically stored on IPFS or similar decentralized storage, allowing for rich metadata and verifiable proofs without bloating on-chain storage.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // For initial admin, can be replaced by a DAO later
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For the utility token (AETHER_TOKEN)

// Custom Errors for enhanced user experience and clarity
error Unauthorized();
error AgentNotFound(uint256 agentId);
error AgentInactive(uint256 agentId);
error AgentActive(uint256 agentId);
error NotAgentOwner(uint256 agentId, address caller);
error SkillModuleNotFound(uint256 moduleId);
error SkillModuleNotApproved(uint256 moduleId);
error SkillAlreadyAdded(uint256 agentId, uint256 moduleId);
error SkillNotPossessed(uint256 agentId, uint256 moduleId);
error InsufficientStake(uint256 agentId, uint256 requiredStake, uint256 currentStake);
error InvalidIntent(uint256 intentId);
error IntentNotOpen(uint256 intentId);
error IntentNotAccepted(uint256 intentId);
error IntentAlreadyFinalized(uint256 intentId);
error AgentMismatch(uint256 intentId, uint256 agentId);
error InsufficientPayment(uint256 requiredAmount, uint256 sentAmount);
error SelfVerificationNotAllowed(); // Placeholder for future stricter verification
error NoFeesToWithdraw();
error ParameterKeyNotFound(string key);
error CapabilityMismatch();
error SkillModuleAlreadyApproved();
error SkillModuleNotYetApproved();
error DeadlinePassed();
error PaymentAmountTooLow();


/**
 * @title AetherialMindsProtocol
 * @dev A decentralized ecosystem for AI agents, featuring dynamic capabilities, reputation,
 *      an intent-based task marketplace, and on-chain governance.
 *      This contract manages the registration, lifecycle, and interaction of AI agents
 *      represented as Dynamic Capability NFTs (DC-NFTs), facilitates task assignments,
 *      and tracks agent performance through a reputation system.
 *
 *      Key advanced concepts:
 *      - **Dynamic Capability NFTs (DC-NFTs):** Agents are NFTs whose capabilities and reputation
 *        can evolve on-chain (though the NFT itself isn't a standard ERC721, its data is dynamic).
 *      - **Intent-based Task Matching:** Users express 'what' they need (via capabilities hash),
 *        and the system helps match them with suitable agents.
 *      - **Reputation System:** Agents earn/lose reputation based on task performance and dispute outcomes,
 *        influencing their visibility and reliability.
 *      - **Skill Module Marketplace:** A decentralized way to extend agent functionalities.
 *      - **On-chain Governance Integration:** Protocol parameters and dispute resolution can be governed
 *        by a designated address, representing a DAO or trusted entity.
 *      - **Verifiable Proofs (via Hashes):** Encourages off-chain computation with on-chain verification
 *        by requiring hashes of results and performance proofs.
 */
contract AetherialMindsProtocol is Ownable {

    // --- Outline and Function Summary ---

    // I. Agent Management (Dynamic Capability NFTs - DC-NFTs): Core functions for AI agent lifecycle.
    //    1.  registerAIAgent: Registers a new AI agent with initial metadata and stake, creating its unique identity.
    //    2.  updateAIAgentProfile: Allows agent owners to update their agent's name, description, and core capabilities hash.
    //    3.  deactivateAIAgent: Puts an agent into an inactive state, preventing it from accepting new tasks.
    //    4.  reactivateAIAgent: Brings an inactive agent back to an active state, requiring minimum stake.
    //    5.  transferAIAgentOwnership: Transfers the ownership (and control) of an agent's identity to a new address.
    //    6.  burnAIAgentNFT: Allows an owner to permanently remove their agent from the system, refunding stakes.

    // II. Skill Module Registry: Functions for managing extensible agent capabilities.
    //    7.  proposeSkillModule: Submits a new AI skill module for potential inclusion in the ecosystem.
    //    8.  approveSkillModule: Approves a proposed skill module, making it available for agents to acquire.
    //    9.  revokeSkillModuleApproval: Revokes the approval of an existing skill module.

    // III. Agent Skill Integration: How agents acquire and manage new skills.
    //    10. acquireAgentSkill: Enables an agent owner to purchase and integrate an approved skill module into their agent.
    //    11. removeAgentSkill: Allows an agent owner to remove a skill module from their agent.

    // IV. Task & Intent System: The core marketplace for AI services.
    //    12. postTaskIntent: A user posts a task description (intent) and a maximum bid, securing funds in escrow.
    //    13. acceptTaskIntent: An eligible AI agent accepts a posted task, committing to its completion.
    //    14. submitTaskResultHash: The agent submits cryptographic hashes of the task result and proof of work.
    //    15. verifyTaskCompletion: The task requester verifies the submitted result, impacting agent reputation and payment.
    //    16. disputeTaskResult: Initiates a formal dispute over a task's outcome, escalating to a resolver.
    //    17. finalizeTaskIntent: An internal function to conclude a task, distribute payments, and update reputation.

    // V. Reputation & Staking: Mechanisms for agent reliability and security.
    //    18. depositStakeForAgent: Agent owners can increase their agent's stake for improved credibility.
    //    19. withdrawStakeFromAgent: Agent owners can reduce their agent's stake, subject to minimums for active agents.
    //    20. adjustAgentReputation: A governance function to manually adjust an agent's reputation, often used in disputes or sanctions.

    // VI. Protocol Governance & Fees: Administrative controls and fee management.
    //    21. setProtocolParameter: Allows the designated governance address to update system-wide configurations.
    //    22. withdrawProtocolFees: Enables the governance address to collect accumulated operational fees.
    //    23. nominateDisputeResolver: Designates an address responsible for mediating task disputes.
    //    24. resolveDispute: The dispute resolver's function to issue a final verdict on a disputed task.

    // VII. View & Utility Functions: Publicly accessible read-only functions to query the contract state.
    //    25. getAIAgentDetails: Retrieves comprehensive information about a specific AI agent.
    //    26. getSkillModuleDetails: Fetches detailed information about a registered skill module.
    //    27. getAgentSkills: Lists all skill modules currently possessed by a given agent.
    //    28. findMatchingAgents: Provides a basic search for active agents matching specified capabilities.
    //    29. getTaskIntentDetails: Retrieves all relevant data for a particular task intent.
    //    30. getProtocolParameter: Queries the value of any specified protocol configuration parameter.


    // --- State Variables ---

    // External token for payments and staking (e.g., AETHER_TOKEN)
    IERC20 public immutable AETHER_TOKEN;

    // Agent Counter and Struct
    uint256 public nextAgentId;
    struct AIAgent {
        address owner;
        string name;
        string description;
        bytes32 capabilitiesHash; // IPFS hash or similar for detailed core capabilities
        uint256 currentStake;
        int256 reputation; // Can be positive or negative, reflecting performance and reliability
        bool isActive;
        mapping(uint256 => bool) skills; // Mapping of skillId => hasSkill for quick lookup
        uint256[] possessedSkills; // Array for easy iteration of skills (denormalized for views)
    }
    mapping(uint256 => AIAgent) public agents;
    mapping(address => uint256[]) public ownerAgents; // Track agents by owner for easy retrieval

    // Skill Module Counter and Struct
    uint256 public nextSkillModuleId;
    struct SkillModule {
        string name;
        string description;
        bytes32 capabilitiesSchemaHash; // Defines the input/output schema of this skill
        bytes32 validationLogicHash; // IPFS hash for off-chain validation logic/AI model for this skill
        uint256 baseCostToAcquire; // Cost for an agent to "learn" this skill (in AETHER_TOKEN)
        bool isApproved; // Only approved skills can be acquired by agents
    }
    mapping(uint256 => SkillModule) public skillModules;

    // Task Intent Counter and Struct
    uint256 public nextIntentId;
    enum IntentStatus { Open, Accepted, ResultSubmitted, Verified, Disputed, Finalized }
    struct TaskIntent {
        address requester;
        bytes32 desiredCapabilitiesHash; // Capabilities required for the task
        uint256 maxBid; // Maximum payment requester is willing to make (in AETHER_TOKEN)
        uint256 acceptedAgentId;
        uint256 acceptedPayment; // Actual payment to agent after fees
        uint256 deadline; // Timestamp by which task result must be submitted
        bytes32 resultHash; // Hash of the task result from the agent (e.g., IPFS CID)
        bytes32 performanceProofHash; // Hash of the proof accompanying the result (e.g., ZKP proof CID)
        IntentStatus status;
        bool resultVerifiedSuccessful; // True if verified successfully, false if failed/disputed-failed
        uint256 createdAt; // Timestamp of intent creation
    }
    mapping(uint256 => TaskIntent) public taskIntents;

    // Protocol Parameters (governed by `governanceAddress`)
    mapping(string => uint256) public protocolParameters;
    address public governanceAddress; // Address that can change protocol parameters and withdraw fees
    address public disputeResolverAddress; // Address empowered to resolve disputes

    // Protocol accumulated fees
    uint256 public protocolFees; // Accumulated fees in AETHER_TOKEN

    // --- Events ---
    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string name, bytes32 capabilitiesHash);
    event AIAgentUpdated(uint256 indexed agentId, string newName, string newDescription, bytes32 newCapabilitiesHash);
    event AIAgentDeactivated(uint256 indexed agentId);
    event AIAgentReactivated(uint256 indexed agentId);
    event AIAgentOwnershipTransferred(uint256 indexed agentId, address indexed oldOwner, address indexed newOwner);
    event AIAgentBurned(uint256 indexed agentId, address indexed owner);

    event SkillModuleProposed(uint256 indexed moduleId, string name, bytes32 capabilitiesSchemaHash);
    event SkillModuleApproved(uint256 indexed moduleId, address indexed approver);
    event SkillModuleApprovalRevoked(uint256 indexed moduleId, address indexed revoker);

    event AgentSkillAcquired(uint256 indexed agentId, uint256 indexed moduleId);
    event AgentSkillRemoved(uint256 indexed agentId, uint256 indexed moduleId);

    event TaskIntentPosted(uint256 indexed intentId, address indexed requester, bytes32 desiredCapabilitiesHash, uint256 maxBid);
    event TaskIntentAccepted(uint256 indexed intentId, uint256 indexed agentId, uint256 acceptedPayment);
    event TaskResultSubmitted(uint256 indexed intentId, uint256 indexed agentId, bytes32 resultHash, bytes32 performanceProofHash);
    event TaskCompletionVerified(uint256 indexed intentId, uint256 indexed agentId, bool isSuccessful, address indexed verifier);
    event TaskDisputeInitiated(uint256 indexed intentId, uint256 indexed agentId, address indexed disputer);
    event TaskIntentFinalized(uint256 indexed intentId, IntentStatus finalStatus, uint256 agentId, int256 reputationChange);

    event AgentStakeDeposited(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AgentStakeWithdrawn(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AgentReputationAdjusted(uint256 indexed agentId, int256 oldReputation, int256 newReputation, address indexed adjuster);

    event ProtocolParameterSet(string indexed key, uint256 value);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event DisputeResolverNominated(address indexed newResolver);

    // --- Constructor ---
    /**
     * @dev Initializes the AetherialMindsProtocol with the addresses of the utility token, governance, and dispute resolver.
     * @param _aetherTokenAddress The address of the ERC-20 token used for payments and staking.
     * @param _governanceAddress The address authorized to manage protocol parameters and fees.
     * @param _disputeResolverAddress The address authorized to resolve task disputes.
     */
    constructor(address _aetherTokenAddress, address _governanceAddress, address _disputeResolverAddress) Ownable(msg.sender) {
        require(_aetherTokenAddress != address(0), "Invalid token address");
        require(_governanceAddress != address(0), "Invalid governance address");
        require(_disputeResolverAddress != address(0), "Invalid dispute resolver address");

        AETHER_TOKEN = IERC20(_aetherTokenAddress);
        governanceAddress = _governanceAddress;
        disputeResolverAddress = _disputeResolverAddress;

        // Set initial recommended protocol parameters (can be adjusted by governance)
        protocolParameters["minAgentStake"] = 1000 * 10**18; // Example: 1000 AETHER tokens (assuming 18 decimals)
        protocolParameters["taskAcceptanceFeeBPS"] = 100; // Example: 1% (100 basis points out of 10000)
        protocolParameters["reputationRewardFactor"] = 10; // Reputation points gained on success
        protocolParameters["reputationPenaltyFactor"] = 20; // Reputation points lost on failure
        protocolParameters["disputeFee"] = 100 * 10**18; // Cost to initiate a dispute
        protocolParameters["agentRegistrationFee"] = 10 * 10**18; // Cost to register an agent
    }

    // --- Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != governanceAddress) revert Unauthorized();
        _;
    }

    modifier onlyDisputeResolver() {
        if (msg.sender != disputeResolverAddress) revert Unauthorized();
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        if (agents[_agentId].owner == address(0)) revert AgentNotFound(_agentId); // Recheck if agent exists implicitly
        if (agents[_agentId].owner != msg.sender) revert NotAgentOwner(_agentId, msg.sender);
        _;
    }

    modifier agentExists(uint256 _agentId) {
        if (agents[_agentId].owner == address(0)) revert AgentNotFound(_agentId);
        _;
    }

    modifier skillModuleExists(uint256 _moduleId) {
        if (skillModules[_moduleId].capabilitiesSchemaHash == bytes32(0)) revert SkillModuleNotFound(_moduleId);
        _;
    }

    modifier taskIntentExists(uint256 _intentId) {
        if (taskIntents[_intentId].requester == address(0)) revert InvalidIntent(_intentId);
        _;
    }

    // --- I. Agent Management (DC-NFTs) ---

    /**
     * @dev Registers a new AI agent and establishes its identity within the protocol.
     *      Requires an initial stake and a registration fee, both paid in AETHER_TOKEN.
     * @param _name The human-readable name of the AI agent.
     * @param _description A brief description outlining the agent's general purpose.
     * @param _capabilitiesHash An IPFS/content hash pointing to a detailed specification of the agent's core capabilities.
     * @param _initialStake An initial amount of AETHER_TOKEN to stake for the agent, must meet `minAgentStake`.
     * @return The ID of the newly registered agent.
     */
    function registerAIAgent(
        string calldata _name,
        string calldata _description,
        bytes32 _capabilitiesHash,
        uint256 _initialStake
    ) external returns (uint256) {
        uint256 agentId = nextAgentId++;
        uint256 minStake = protocolParameters["minAgentStake"];
        uint256 registrationFee = protocolParameters["agentRegistrationFee"];
        require(_initialStake >= minStake, "Initial stake too low");

        uint256 totalAmount = _initialStake + registrationFee;
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), totalAmount), "Token transfer failed for registration fee/stake");

        protocolFees += registrationFee;

        AIAgent storage newAgent = agents[agentId];
        newAgent.owner = msg.sender;
        newAgent.name = _name;
        newAgent.description = _description;
        newAgent.capabilitiesHash = _capabilitiesHash;
        newAgent.currentStake = _initialStake;
        newAgent.reputation = 0; // Agents start with neutral reputation
        newAgent.isActive = true;

        ownerAgents[msg.sender].push(agentId); // Add agent ID to the owner's list

        emit AIAgentRegistered(agentId, msg.sender, _name, _capabilitiesHash);
        return agentId;
    }

    /**
     * @dev Allows the agent owner to update their agent's profile metadata.
     *      This includes name, description, and the hash pointing to its detailed capabilities.
     * @param _agentId The ID of the agent to update.
     * @param _newName The new name for the agent.
     * @param _newDescription The new description for the agent.
     * @param _newCapabilitiesHash The new capabilities hash, linking to updated off-chain data.
     */
    function updateAIAgentProfile(
        uint256 _agentId,
        string calldata _newName,
        string calldata _newDescription,
        bytes32 _newCapabilitiesHash
    ) external onlyAgentOwner(_agentId) agentExists(_agentId) {
        AIAgent storage agent = agents[_agentId];
        agent.name = _newName;
        agent.description = _newDescription;
        agent.capabilitiesHash = _newCapabilitiesHash;
        emit AIAgentUpdated(_agentId, _newName, _newDescription, _newCapabilitiesHash);
    }

    /**
     * @dev Deactivates an AI agent, preventing it from accepting new tasks or participating in the marketplace.
     *      The agent's staked tokens remain locked until reactivated or burned.
     * @param _agentId The ID of the agent to deactivate.
     */
    function deactivateAIAgent(uint256 _agentId) external onlyAgentOwner(_agentId) agentExists(_agentId) {
        if (!agents[_agentId].isActive) revert AgentInactive(_agentId);
        agents[_agentId].isActive = false;
        emit AIAgentDeactivated(_agentId);
    }

    /**
     * @dev Reactivates an AI agent, allowing it to resume accepting new tasks.
     *      Requires the agent's stake to be at or above the minimum required stake.
     * @param _agentId The ID of the agent to reactivate.
     */
    function reactivateAIAgent(uint256 _agentId) external onlyAgentOwner(_agentId) agentExists(_agentId) {
        if (agents[_agentId].isActive) revert AgentActive(_agentId);
        require(agents[_agentId].currentStake >= protocolParameters["minAgentStake"], "Insufficient stake to reactivate");
        agents[_agentId].isActive = true;
        emit AIAgentReactivated(_agentId);
    }

    /**
     * @dev Transfers ownership of an AI agent (its DC-NFT representation) to a new address.
     *      The new owner gains full control over the agent.
     * @param _agentId The ID of the agent to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferAIAgentOwnership(
        uint256 _agentId,
        address _newOwner
    ) external onlyAgentOwner(_agentId) agentExists(_agentId) {
        require(_newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = agents[_agentId].owner;
        agents[_agentId].owner = _newOwner;

        // Remove from old owner's list and add to new owner's list
        _removeAgentFromOwnerList(oldOwner, _agentId);
        ownerAgents[_newOwner].push(_agentId);

        emit AIAgentOwnershipTransferred(_agentId, oldOwner, _newOwner);
    }

    /**
     * @dev Allows an agent owner to permanently remove their agent from the system.
     *      The agent must be inactive. All staked funds are returned to the owner.
     * @param _agentId The ID of the agent to burn.
     */
    function burnAIAgentNFT(uint256 _agentId) external onlyAgentOwner(_agentId) agentExists(_agentId) {
        AIAgent storage agent = agents[_agentId];
        if (agent.isActive) revert AgentActive(_agentId); // Agent must be inactive to burn

        // Return staked tokens
        if (agent.currentStake > 0) {
            require(AETHER_TOKEN.transfer(msg.sender, agent.currentStake), "Failed to return stake");
            agent.currentStake = 0;
        }

        // Clear agent data (effectively 'burning' the NFT and its state)
        delete agents[_agentId];

        // Remove from owner's list
        _removeAgentFromOwnerList(msg.sender, _agentId);

        emit AIAgentBurned(_agentId, msg.sender);
    }

    /**
     * @dev Internal helper to remove an agent ID from an owner's list.
     *      (Note: This is an O(n) operation. For high-throughput scenarios, a more complex data structure
     *      like a linked list or mapping `owner => agentId => index` would be more efficient).
     */
    function _removeAgentFromOwnerList(address _owner, uint256 _agentId) internal {
        uint256[] storage ownerAgentsList = ownerAgents[_owner];
        for (uint i = 0; i < ownerAgentsList.length; i++) {
            if (ownerAgentsList[i] == _agentId) {
                ownerAgentsList[i] = ownerAgentsList[ownerAgentsList.length - 1]; // Swap with last element
                ownerAgentsList.pop(); // Remove last element
                break;
            }
        }
    }

    // --- II. Skill Module Registry ---

    /**
     * @dev Proposes a new AI skill module for review. Once proposed, it needs to be approved by governance
     *      before agents can acquire it.
     * @param _name The name of the skill module (e.g., "Image Classification v2").
     * @param _description A description of the skill and its utility.
     * @param _capabilitiesSchemaHash IPFS/content hash describing the detailed input/output schema for this skill.
     * @param _validationLogicHash IPFS/content hash pointing to off-chain logic/model for validating this skill's output.
     * @param _baseCostToAcquire The base cost (in AETHER_TOKEN) for an agent to acquire this skill.
     * @return The ID of the proposed skill module.
     */
    function proposeSkillModule(
        string calldata _name,
        string calldata _description,
        bytes32 _capabilitiesSchemaHash,
        bytes32 _validationLogicHash,
        uint256 _baseCostToAcquire
    ) external returns (uint256) {
        uint256 moduleId = nextSkillModuleId++;
        SkillModule storage newModule = skillModules[moduleId];
        newModule.name = _name;
        newModule.description = _description;
        newModule.capabilitiesSchemaHash = _capabilitiesSchemaHash;
        newModule.validationLogicHash = _validationLogicHash;
        newModule.baseCostToAcquire = _baseCostToAcquire;
        newModule.isApproved = false; // Requires governance approval

        emit SkillModuleProposed(moduleId, _name, _capabilitiesSchemaHash);
        return moduleId;
    }

    /**
     * @dev Approves a proposed skill module, making it available for agents to acquire.
     *      Only callable by the designated governance address.
     * @param _moduleId The ID of the skill module to approve.
     */
    function approveSkillModule(uint256 _moduleId) external onlyGovernance skillModuleExists(_moduleId) {
        if (skillModules[_moduleId].isApproved) revert SkillModuleAlreadyApproved();
        skillModules[_moduleId].isApproved = true;
        emit SkillModuleApproved(_moduleId, msg.sender);
    }

    /**
     * @dev Revokes approval for an existing skill module.
     *      Agents already possessing this skill can continue to use it, but no new acquisitions are allowed.
     *      Only callable by the designated governance address.
     * @param _moduleId The ID of the skill module to revoke approval for.
     */
    function revokeSkillModuleApproval(uint256 _moduleId) external onlyGovernance skillModuleExists(_moduleId) {
        if (!skillModules[_moduleId].isApproved) revert SkillModuleNotYetApproved();
        skillModules[_moduleId].isApproved = false;
        emit SkillModuleApprovalRevoked(_moduleId, msg.sender);
    }

    // --- III. Agent Skill Integration ---

    /**
     * @dev Allows an agent owner to acquire an approved skill module for their agent.
     *      The acquisition cost (in AETHER_TOKEN) is paid by the agent owner.
     * @param _agentId The ID of the agent acquiring the skill.
     * @param _moduleId The ID of the skill module to acquire.
     */
    function acquireAgentSkill(uint256 _agentId, uint256 _moduleId)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
        skillModuleExists(_moduleId)
    {
        SkillModule storage skill = skillModules[_moduleId];
        if (!skill.isApproved) revert SkillModuleNotApproved(_moduleId);
        if (agents[_agentId].skills[_moduleId]) revert SkillAlreadyAdded(_agentId, _moduleId);

        // Pay the acquisition cost
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), skill.baseCostToAcquire), "Skill acquisition payment failed");
        protocolFees += skill.baseCostToAcquire; // Acquisition fees contribute to protocol revenue

        agents[_agentId].skills[_moduleId] = true;
        agents[_agentId].possessedSkills.push(_moduleId);

        emit AgentSkillAcquired(_agentId, _moduleId);
    }

    /**
     * @dev Allows an agent owner to remove a skill module from their agent.
     *      This does not refund the acquisition cost.
     * @param _agentId The ID of the agent removing the skill.
     * @param _moduleId The ID of the skill module to remove.
     */
    function removeAgentSkill(uint256 _agentId, uint256 _moduleId)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
        skillModuleExists(_moduleId)
    {
        if (!agents[_agentId].skills[_moduleId]) revert SkillNotPossessed(_agentId, _moduleId);

        agents[_agentId].skills[_moduleId] = false;

        // Remove from possessedSkills array (O(n) operation)
        uint256[] storage possessed = agents[_agentId].possessedSkills;
        for (uint i = 0; i < possessed.length; i++) {
            if (possessed[i] == _moduleId) {
                possessed[i] = possessed[possessed.length - 1]; // Swap with last element
                possessed.pop(); // Remove last element
                break;
            }
        }
        emit AgentSkillRemoved(_agentId, _moduleId);
    }

    // --- IV. Task & Intent System ---

    /**
     * @dev A user posts a task intent, specifying desired capabilities and their maximum bid.
     *      The `maxBid` amount for the task is transferred to the contract and held in escrow.
     * @param _desiredCapabilitiesHash An IPFS/content hash describing the task's required capabilities.
     * @param _maxBid The maximum amount (in AETHER_TOKEN) the requester is willing to pay.
     * @param _deadline The timestamp by which the task result must be submitted.
     * @return The ID of the newly posted task intent.
     */
    function postTaskIntent(
        bytes32 _desiredCapabilitiesHash,
        uint256 _maxBid,
        uint256 _deadline
    ) external returns (uint256) {
        if (_maxBid == 0) revert PaymentAmountTooLow();
        if (_deadline <= block.timestamp) revert DeadlinePassed();
        
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), _maxBid), "Payment transfer for intent failed");

        uint256 intentId = nextIntentId++;
        TaskIntent storage newIntent = taskIntents[intentId];
        newIntent.requester = msg.sender;
        newIntent.desiredCapabilitiesHash = _desiredCapabilitiesHash;
        newIntent.maxBid = _maxBid;
        newIntent.deadline = _deadline;
        newIntent.status = IntentStatus.Open;
        newIntent.createdAt = block.timestamp;

        emit TaskIntentPosted(intentId, msg.sender, _desiredCapabilitiesHash, _maxBid);
        return intentId;
    }

    /**
     * @dev An eligible AI agent accepts a posted task intent. Requires the agent to be active, have sufficient stake,
     *      and possess the required capabilities (currently simplified to a direct hash match).
     *      A small fee is deducted from the `maxBid` and added to protocol fees.
     * @param _intentId The ID of the task intent to accept.
     * @param _agentId The ID of the agent accepting the task.
     */
    function acceptTaskIntent(uint256 _intentId, uint256 _agentId)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
        taskIntentExists(_intentId)
    {
        TaskIntent storage intent = taskIntents[_intentId];
        AIAgent storage agent = agents[_agentId];

        if (intent.status != IntentStatus.Open) revert IntentNotOpen(_intentId);
        if (!agent.isActive) revert AgentInactive(_agentId);
        if (agent.currentStake < protocolParameters["minAgentStake"]) revert InsufficientStake(_agentId, protocolParameters["minAgentStake"], agent.currentStake);

        // Capability matching (simplified: direct hash comparison of core capabilities).
        // In a more advanced system, this would involve semantic matching or verifying skill modules.
        if (agent.capabilitiesHash != intent.desiredCapabilitiesHash) revert CapabilityMismatch();

        uint256 acceptanceFee = (intent.maxBid * protocolParameters["taskAcceptanceFeeBPS"]) / 10000; // e.g., 100/10000 = 1%
        uint256 paymentToAgent = intent.maxBid - acceptanceFee;
        if (paymentToAgent == 0) revert PaymentAmountTooLow();

        protocolFees += acceptanceFee;

        intent.acceptedAgentId = _agentId;
        intent.acceptedPayment = paymentToAgent;
        intent.status = IntentStatus.Accepted;

        emit TaskIntentAccepted(_intentId, _agentId, paymentToAgent);
    }

    /**
     * @dev The agent submits cryptographic hashes of the task result and an optional performance proof.
     *      This marks the task as `ResultSubmitted` but does not finalize it; awaiting requester verification.
     * @param _intentId The ID of the task intent.
     * @param _resultHash IPFS/content hash of the task result data.
     * @param _performanceProofHash IPFS/content hash of the proof of work or a verifiable credential.
     */
    function submitTaskResultHash(
        uint256 _intentId,
        bytes32 _resultHash,
        bytes32 _performanceProofHash
    ) external taskIntentExists(_intentId) {
        TaskIntent storage intent = taskIntents[_intentId];
        if (intent.status != IntentStatus.Accepted) revert IntentNotAccepted(_intentId);
        if (agents[intent.acceptedAgentId].owner != msg.sender) revert NotAgentOwner(intent.acceptedAgentId, msg.sender);

        if (block.timestamp > intent.deadline) revert DeadlinePassed();

        intent.resultHash = _resultHash;
        intent.performanceProofHash = _performanceProofHash;
        intent.status = IntentStatus.ResultSubmitted;

        emit TaskResultSubmitted(_intentId, intent.acceptedAgentId, _resultHash, _performanceProofHash);
    }

    /**
     * @dev The task requester verifies the submitted result. Based on this verification,
     *      payment is released (to agent or back to requester) and agent reputation is adjusted.
     *      This function automatically calls `_finalizeTaskIntent`.
     * @param _intentId The ID of the task intent.
     * @param _isSuccessful True if the result is verified as successful, false otherwise.
     */
    function verifyTaskCompletion(
        uint256 _intentId,
        bool _isSuccessful
    ) external taskIntentExists(_intentId) {
        TaskIntent storage intent = taskIntents[_intentId];
        if (intent.requester != msg.sender) revert Unauthorized(); // Only requester can verify
        if (intent.status != IntentStatus.ResultSubmitted) revert("Intent not in result submitted state");

        // Consider a stricter check here if _isSuccessful could be manipulated by agent/requester collusion
        // if (intent.requester == agents[intent.acceptedAgentId].owner) revert SelfVerificationNotAllowed();

        intent.resultVerifiedSuccessful = _isSuccessful;
        intent.status = IntentStatus.Verified;

        emit TaskCompletionVerified(_intentId, intent.acceptedAgentId, _isSuccessful, msg.sender);

        _finalizeTaskIntent(_intentId); // Finalize the task immediately after verification
    }

    /**
     * @dev Initiates a dispute over a task result. Requires a dispute fee to be paid by the disputer.
     *      The dispute will need to be resolved by the `disputeResolverAddress`.
     * @param _intentId The ID of the task intent to dispute.
     */
    function disputeTaskResult(uint256 _intentId) external taskIntentExists(_intentId) {
        TaskIntent storage intent = taskIntents[_intentId];
        // Only requester or the accepted agent's owner can dispute
        if (intent.requester != msg.sender && agents[intent.acceptedAgentId].owner != msg.sender) revert Unauthorized();
        // Can dispute results that are submitted or already verified (if the verification is challenged)
        if (intent.status != IntentStatus.ResultSubmitted && intent.status != IntentStatus.Verified) revert("Can only dispute submitted or verified results");
        if (intent.status == IntentStatus.Disputed || intent.status == IntentStatus.Finalized) revert IntentAlreadyFinalized(_intentId);

        // Pay dispute fee
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), protocolParameters["disputeFee"]), "Dispute fee payment failed");
        protocolFees += protocolParameters["disputeFee"];

        intent.status = IntentStatus.Disputed;
        emit TaskDisputeInitiated(_intentId, intent.acceptedAgentId, msg.sender);
    }

    /**
     * @dev Internal function to conclude a task intent, distributing payment and adjusting agent reputation.
     *      This is called after `verifyTaskCompletion` or `resolveDispute`.
     * @param _intentId The ID of the task intent to finalize.
     */
    function _finalizeTaskIntent(uint256 _intentId) internal taskIntentExists(_intentId) {
        TaskIntent storage intent = taskIntents[_intentId];
        if (intent.status == IntentStatus.Finalized) revert IntentAlreadyFinalized(_intentId);
        if (intent.status != IntentStatus.Verified && intent.status != IntentStatus.Disputed) revert("Intent not in verifiable or disputed state for finalization");

        AIAgent storage agent = agents[intent.acceptedAgentId];
        int256 reputationChange = 0;

        if (intent.resultVerifiedSuccessful) {
            // Success: release payment to agent's owner, reward reputation
            require(AETHER_TOKEN.transfer(agent.owner, intent.acceptedPayment), "Failed to transfer payment to agent owner");
            reputationChange = int256(protocolParameters["reputationRewardFactor"]);
        } else {
            // Failure: return payment to requester, penalize reputation
            require(AETHER_TOKEN.transfer(intent.requester, intent.maxBid), "Failed to return payment to requester");
            reputationChange = -int256(protocolParameters["reputationPenaltyFactor"]);
        }

        // Apply reputation change
        int256 oldReputation = agent.reputation;
        agent.reputation += reputationChange;
        emit AgentReputationAdjusted(intent.acceptedAgentId, oldReputation, agent.reputation, address(this));

        intent.status = IntentStatus.Finalized;
        emit TaskIntentFinalized(_intentId, intent.status, intent.acceptedAgentId, reputationChange);
    }


    // --- V. Reputation & Staking ---

    /**
     * @dev Agent owner deposits additional AETHER_TOKEN as stake for their agent.
     *      Higher stakes can imply higher commitment and potentially influence matching algorithms.
     * @param _agentId The ID of the agent to stake for.
     * @param _amount The amount of AETHER_TOKEN to deposit.
     */
    function depositStakeForAgent(uint256 _agentId, uint256 _amount)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
    {
        if (_amount == 0) revert("Stake amount must be positive");
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for stake deposit");
        agents[_agentId].currentStake += _amount;
        emit AgentStakeDeposited(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Agent owner withdraws stake from their agent.
     *      Cannot withdraw below `minAgentStake` if the agent is currently active.
     * @param _agentId The ID of the agent to withdraw from.
     * @param _amount The amount of AETHER_TOKEN to withdraw.
     */
    function withdrawStakeFromAgent(uint256 _agentId, uint256 _amount)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
    {
        if (_amount == 0) revert("Withdrawal amount must be positive");
        AIAgent storage agent = agents[_agentId];
        require(agent.currentStake >= _amount, "Insufficient stake to withdraw");

        uint256 remainingStake = agent.currentStake - _amount;
        if (agent.isActive && remainingStake < protocolParameters["minAgentStake"]) {
            revert("Cannot withdraw below min stake for an active agent");
        }

        agent.currentStake = remainingStake;
        require(AETHER_TOKEN.transfer(msg.sender, _amount), "Failed to transfer stake to owner");
        emit AgentStakeWithdrawn(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Protocol-level adjustment of an agent's reputation.
     *      Primarily used by the dispute resolver or governance for special cases like slashing.
     * @param _agentId The ID of the agent whose reputation to adjust.
     * @param _reputationDelta The amount to add or subtract from reputation. Can be negative.
     * @param _reasonHash A hash linking to an off-chain explanation for the adjustment.
     */
    function adjustAgentReputation(uint256 _agentId, int256 _reputationDelta, bytes32 _reasonHash)
        external
        onlyGovernance
        agentExists(_agentId)
    {
        // This is a direct adjustment, separate from task verification.
        int256 oldReputation = agents[_agentId].reputation;
        agents[_agentId].reputation += _reputationDelta;
        emit AgentReputationAdjusted(_agentId, oldReputation, agents[_agentId].reputation, msg.sender);
        // _reasonHash is for off-chain logging/transparency.
    }

    // --- VI. Protocol Governance & Fees ---

    /**
     * @dev Allows the designated governance address to update key protocol parameters.
     *      This provides flexibility for the protocol to evolve over time.
     * @param _key The string key of the parameter to update (e.g., "minAgentStake", "taskAcceptanceFeeBPS").
     * @param _value The new uint256 value for the parameter.
     */
    function setProtocolParameter(string calldata _key, uint256 _value) external onlyGovernance {
        protocolParameters[_key] = _value;
        emit ProtocolParameterSet(_key, _value);
    }

    /**
     * @dev Allows the governance address to withdraw accumulated protocol fees.
     *      Fees are collected from agent registrations, skill acquisitions, and task acceptance.
     * @param _recipient The address to send the collected fees to.
     */
    function withdrawProtocolFees(address _recipient) external onlyGovernance {
        if (protocolFees == 0) revert NoFeesToWithdraw();
        uint256 amount = protocolFees;
        protocolFees = 0;
        require(AETHER_TOKEN.transfer(_recipient, amount), "Failed to withdraw protocol fees");
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }

    /**
     * @dev Nominates a new dispute resolver address.
     *      This address is responsible for mediating and resolving task disputes.
     * @param _newResolver The address of the new dispute resolver.
     */
    function nominateDisputeResolver(address _newResolver) external onlyGovernance {
        require(_newResolver != address(0), "New resolver cannot be zero address");
        disputeResolverAddress = _newResolver;
        emit DisputeResolverNominated(_newResolver);
    }

    /**
     * @dev The dispute resolver's function to issue a final verdict on a disputed task.
     *      This overrides any previous verification and triggers `_finalizeTaskIntent`.
     * @param _intentId The ID of the disputed task intent.
     * @param _isSuccessful True if the agent is deemed successful by the resolver, false otherwise.
     */
    function resolveDispute(uint256 _intentId, bool _isSuccessful)
        external
        onlyDisputeResolver
        taskIntentExists(_intentId)
    {
        TaskIntent storage intent = taskIntents[_intentId];
        if (intent.status != IntentStatus.Disputed) revert("Intent not in disputed state");

        // The dispute resolver's decision sets the final outcome.
        intent.resultVerifiedSuccessful = _isSuccessful;
        intent.status = IntentStatus.Verified; // Transition to Verified state, then finalize.

        _finalizeTaskIntent(_intentId);
        // Note: The dispute fee paid by the disputer is retained as protocol fees.
    }

    // --- VII. View & Utility Functions ---

    /**
     * @dev Retrieves comprehensive details about an AI agent.
     * @param _agentId The ID of the agent.
     * @return owner, name, description, capabilitiesHash, currentStake, reputation, isActive, possessedSkills.
     */
    function getAIAgentDetails(uint256 _agentId)
        external
        view
        agentExists(_agentId)
        returns (
            address owner,
            string memory name,
            string memory description,
            bytes32 capabilitiesHash,
            uint256 currentStake,
            int256 reputation,
            bool isActive,
            uint256[] memory possessedSkills // Returns a copy of the array
        )
    {
        AIAgent storage agent = agents[_agentId];
        return (
            agent.owner,
            agent.name,
            agent.description,
            agent.capabilitiesHash,
            agent.currentStake,
            agent.reputation,
            agent.isActive,
            agent.possessedSkills
        );
    }

    /**
     * @dev Retrieves details about a registered skill module.
     * @param _moduleId The ID of the skill module.
     * @return name, description, capabilitiesSchemaHash, validationLogicHash, baseCostToAcquire, isApproved.
     */
    function getSkillModuleDetails(uint256 _moduleId)
        external
        view
        skillModuleExists(_moduleId)
        returns (
            string memory name,
            string memory description,
            bytes32 capabilitiesSchemaHash,
            bytes32 validationLogicHash,
            uint256 baseCostToAcquire,
            bool isApproved
        )
    {
        SkillModule storage skill = skillModules[_moduleId];
        return (
            skill.name,
            skill.description,
            skill.capabilitiesSchemaHash,
            skill.validationLogicHash,
            skill.baseCostToAcquire,
            skill.isApproved
        );
    }

    /**
     * @dev Lists all skill module IDs currently possessed by a specific agent.
     * @param _agentId The ID of the agent.
     * @return An array of skill module IDs.
     */
    function getAgentSkills(uint256 _agentId)
        external
        view
        agentExists(_agentId)
        returns (uint256[] memory)
    {
        return agents[_agentId].possessedSkills;
    }

    /**
     * @dev Finds active agents that conceptually match the desired capabilities hash.
     *      (Simplified: direct hash match. A real-world solution would involve off-chain indexed search or more complex on-chain registry).
     * @param _desiredCapabilitiesHash The capabilities hash to match.
     * @param _limit The maximum number of agents to return.
     * @return An array of agent IDs that match.
     */
    function findMatchingAgents(bytes32 _desiredCapabilitiesHash, uint256 _limit) external view returns (uint256[] memory) {
        uint256[] memory matchingAgents = new uint256[](_limit);
        uint256 count = 0;
        for (uint256 i = 0; i < nextAgentId && count < _limit; i++) {
            AIAgent storage agent = agents[i];
            // Check if agent exists, is active, and matches capabilities
            if (agent.owner != address(0) && agent.isActive && agent.capabilitiesHash == _desiredCapabilitiesHash) {
                matchingAgents[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(matchingAgents, count)
        }
        return matchingAgents;
    }

    /**
     * @dev Retrieves details about a posted task intent.
     * @param _intentId The ID of the task intent.
     * @return requester, desiredCapabilitiesHash, maxBid, acceptedAgentId, acceptedPayment, deadline, resultHash, performanceProofHash, status, resultVerifiedSuccessful, createdAt.
     */
    function getTaskIntentDetails(uint256 _intentId)
        external
        view
        taskIntentExists(_intentId)
        returns (
            address requester,
            bytes32 desiredCapabilitiesHash,
            uint256 maxBid,
            uint256 acceptedAgentId,
            uint256 acceptedPayment,
            uint256 deadline,
            bytes32 resultHash,
            bytes32 performanceProofHash,
            IntentStatus status,
            bool resultVerifiedSuccessful,
            uint256 createdAt
        )
    {
        TaskIntent storage intent = taskIntents[_intentId];
        return (
            intent.requester,
            intent.desiredCapabilitiesHash,
            intent.maxBid,
            intent.acceptedAgentId,
            intent.acceptedPayment,
            intent.deadline,
            intent.resultHash,
            intent.performanceProofHash,
            intent.status,
            intent.resultVerifiedSuccessful,
            intent.createdAt
        );
    }

    /**
     * @dev Retrieves the value of a specific protocol parameter.
     * @param _key The string key of the parameter.
     * @return The uint256 value of the parameter.
     */
    function getProtocolParameter(string calldata _key) external view returns (uint256) {
        // While `mapping` returns 0 for non-existent keys, this explicit check
        // improves clarity for users by differentiating between a 0 value and a non-existent key.
        // It's a simplified check; a more robust solution would check against a list of known keys.
        if (protocolParameters[_key] == 0 &&
            !(keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("minAgentStake")) ||
              keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("taskAcceptanceFeeBPS")) ||
              keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("reputationRewardFactor")) ||
              keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("reputationPenaltyFactor")) ||
              keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("disputeFee")) ||
              keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("agentRegistrationFee")))) {
            revert ParameterKeyNotFound(_key);
        }
        return protocolParameters[_key];
    }
}
```