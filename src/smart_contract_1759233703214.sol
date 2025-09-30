This smart contract, `AethermindNexus`, envisions a decentralized ecosystem for autonomous digital agents. It integrates concepts of dynamic reputation, AI oracle interaction, task orchestration, granular delegated authority, and an on-chain dispute resolution mechanism. The goal is to facilitate a network where agents (owned by users) can accept and complete tasks, have their performance evaluated (potentially by AI oracles), and earn reputation and rewards, all governed by the community.

We've focused on creating a unique blend of these concepts, with specific logic for each, to avoid direct duplication of existing open-source projects. For instance, `delegateAgentPermission` uses function selectors for granular control, and the AI oracle interactions are designed to integrate off-chain AI outputs with on-chain verification and challenge mechanisms.

---

### **AethermindNexus: Outline and Function Summary**

**Contract Name:** `AethermindNexus`

**Purpose:** A sophisticated, AI-augmented decentralized agent ecosystem that facilitates task orchestration, dynamic reputation management, and resource allocation. It aims to bridge off-chain AI capabilities with on-chain trust and verification, enabling a network of autonomous digital agents.

**Key Concepts:**
*   **Aether Agents:** Unique, evolving digital identities registered by users, each with dynamic attributes, capabilities, and reputation.
*   **Aether Tasks:** On-chain task requests that agents can fulfill, ranging from data processing to complex computations, with defined rewards and verification mechanisms.
*   **AI Oracle Integration:** Mechanisms to receive and potentially verify AI-generated insights, parameters, or evaluations from a designated off-chain AI oracle.
*   **Dynamic Reputation:** A constantly adjusting reputation score for each agent, influenced by task performance, dispute outcomes, and community feedback, impacting future task eligibility and rewards.
*   **Resource Pools:** Tokenized resources (e.g., computation credits, storage units) managed by agents for task execution.
*   **Delegated Authority:** Agents can securely delegate specific permissions (identified by function selectors) to other entities.
*   **Dispute Resolution:** A modular system for resolving disagreements regarding task outcomes or oracle data.
*   **Parameter Governance:** A decentralized process for updating the core parameters of the `AethermindNexus`.

---

**Function Summary:**

**I. Core Setup & Roles (1 function)**
1.  `constructor()`: Initializes the contract with the deployer as the initial admin and sets default system parameters.

**II. Agent Management (7 functions)**
2.  `registerAetherAgent(string calldata _agentName)`: Allows any user to register a new unique Aether Agent, generating a new agent ID.
3.  `updateAgentProfile(uint256 _agentId, string calldata _newAgentName, string calldata _metadataURI)`: Enables an agent's owner to update its name and an optional metadata URI.
4.  `setAgentCapability(uint256 _agentId, uint256 _capabilityType, bool _hasCapability)`: Allows an agent's owner to declare or revoke a specific capability for their agent.
5.  `getAgentDetails(uint256 _agentId)`: Retrieves comprehensive details about a specific Aether Agent.
6.  `transferAgentOwnership(uint256 _agentId, address _newOwner)`: Transfers ownership of an Aether Agent to a new address.
7.  `delegateAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector, bool _allow)`: Grants or revokes permission for a `_delegatee` to call a specific function (`_selector`) on behalf of the agent.
8.  `revokeAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector)`: Explicitly revokes a specific delegated permission.

**III. Task Orchestration (7 functions)**
9.  `proposeAetherTask(string calldata _taskDescription, uint256 _rewardAmount, uint256 _deadline, uint256 _requiredCapabilityType)`: Allows any user to propose a new task with requirements and a specified reward.
10. `acceptAetherTask(uint256 _taskId, uint256 _agentId)`: Enables an eligible Aether Agent to accept a proposed task.
11. `submitTaskOutput(uint256 _taskId, uint256 _agentId, string calldata _outputURI)`: Allows the task-assigned agent to submit the output/results of a task.
12. `submitAIOracleEvaluation(uint256 _taskId, uint256 _agentId, uint256 _qualityScore)`: A designated AI Oracle submits an evaluation score for a completed task, impacting agent reputation.
13. `claimTaskReward(uint256 _taskId)`: Allows the agent whose task was successfully evaluated to claim its reward.
14. `cancelAetherTask(uint256 _taskId)`: Allows the task proposer to cancel a task if it hasn't been accepted or completed.
15. `registerTaskVerifier(address _verifierAddress, bool _isVerifier)`: Admin function to register or unregister an address as a valid task verifier (can submit evaluations manually if no AI oracle).

**IV. AI Oracle & Reputation Management (3 functions)**
16. `submitAIOracleSuggestion(uint256 _agentId, uint256 _newCapabilityScore, int256 _reputationDelta)`: A designated AI Oracle provides suggestions for updating an agent's internal capability score and reputation.
17. `challengeOracleOutput(uint256 _challengeType, uint256 _entityId, uint256 _referenceId, string calldata _reasonURI)`: Allows any participant to challenge an AI oracle's evaluation or reputation suggestion, initiating a dispute.
18. `resolveChallenge(uint256 _challengeId, bool _challengerWins, int256 _reputationImpact)`: An admin/governance function to resolve a dispute, determining if the challenger wins and the impact on involved parties' reputation.

**V. Agent Resource & Authorization (3 functions)**
19. `depositAgentResources(uint256 _agentId) payable`: Allows an agent owner to deposit native tokens into their agent's internal resource pool.
20. `withdrawAgentResources(uint256 _agentId, uint256 _amount)`: Allows an agent owner to withdraw native tokens from their agent's resource pool.
21. `authorizeResourceSpend(uint256 _agentId, address _spender, uint256 _amount)`: Allows an agent owner to authorize another address (`_spender`) to spend a specific amount from their agent's resource pool.

**VI. Governance & System Parameters (4 functions)**
22. `proposeSystemParamUpdate(bytes32 _paramKey, uint256 _newValue)`: Allows any stakeholder (e.g., agent owner, or with some staked tokens) to propose a change to a core system parameter.
23. `voteOnParamUpdate(uint256 _proposalId, bool _approve)`: Allows stakeholders to vote on an active system parameter update proposal.
24. `executeParamUpdate(uint256 _proposalId)`: Executes a system parameter update if the voting period has ended and the proposal has passed.
25. `getSystemParameter(bytes32 _paramKey)`: Retrieves the current value of a specific system parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future token integration

/// @title AethermindNexus
/// @author YourName (or an AI collective)
/// @notice A sophisticated, AI-augmented decentralized agent ecosystem that facilitates task orchestration,
///         dynamic reputation management, and resource allocation. It aims to bridge off-chain AI capabilities
///         with on-chain trust and verification, enabling a network of autonomous digital agents.
/// @dev This contract is designed with advanced concepts like granular delegated authority, AI oracle integration
///      with dispute mechanisms, and a dynamic governance system. It aims to be creative and avoid
///      duplication of common open-source patterns by combining these features uniquely.

contract AethermindNexus is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum TaskStatus {
        Proposed,
        Accepted,
        OutputSubmitted,
        Evaluated,
        Rewarded,
        Cancelled
    }

    enum ChallengeType {
        OracleEvaluation,
        AgentReputationSuggestion,
        TaskOutputQuality // For manual evaluation disputes
    }

    enum ChallengeStatus {
        Pending,
        Resolved
    }

    // --- Structs ---

    struct Agent {
        address owner;
        string name;
        string metadataURI; // IPFS hash or similar for extended profile data
        uint256 capabilityScore; // A general score indicating overall competence, potentially AI-influenced
        int256 reputation; // Can be positive or negative
        uint256 resourceBalance; // Native token balance for agent operations
        uint256[] activeTaskIds; // Tasks currently accepted by this agent
        mapping(uint256 => bool) capabilities; // Specific capabilities (e.g., image processing: 1, NLP: 2)
        mapping(address => mapping(bytes4 => bool)) delegatedPermissions; // delegatee => function selector => allowed
        mapping(address => uint256) authorizedSpends; // spender => amount (for resource tokens)
    }

    struct Task {
        address proposer;
        uint256 agentId; // 0 if not yet accepted
        string description;
        uint256 rewardAmount; // Native token
        uint256 deadline; // Unix timestamp
        uint256 requiredCapabilityType; // e.g., 1 for image processing
        string outputURI; // IPFS hash or similar for submitted output
        uint256 qualityScore; // 0-100, set by verifier/oracle
        TaskStatus status;
        address currentVerifier; // The address designated to verify this specific task
    }

    struct Challenge {
        address challenger;
        address challengee; // Address against whom the challenge is made (e.g., oracle address)
        uint256 challengeType; // From ChallengeType enum
        uint256 referenceId; // e.g., taskId, agentId, or oracle suggestion ID
        string reasonURI; // IPFS hash or similar for detailed reason
        ChallengeStatus status;
        bool challengerWins; // Set upon resolution
        int256 reputationImpact; // How much reputation change applied to involved parties
    }

    struct SystemParamProposal {
        address proposer;
        bytes32 paramKey;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted; // voter => true if voted
    }

    // --- State Variables ---

    uint256 public nextAgentId;
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) public ownerToAgentIds; // Map owner to their agents

    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;

    mapping(address => bool) public isAIOracle;
    mapping(address => bool) public isTaskVerifier; // Human verifiers, can also submit evaluation

    uint256 public nextChallengeId;
    mapping(uint256 => Challenge) public challenges;

    mapping(bytes32 => uint256) public systemParameters; // Key-value for global parameters

    uint256 public nextProposalId;
    mapping(uint256 => SystemParamProposal) public proposals;

    // --- Events ---

    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, uint256 timestamp);
    event AgentProfileUpdated(uint256 indexed agentId, string newName, string metadataURI, uint256 timestamp);
    event AgentCapabilitySet(uint256 indexed agentId, uint256 capabilityType, bool hasCapability, uint256 timestamp);
    event AgentOwnershipTransferred(uint256 indexed agentId, address indexed oldOwner, address indexed newOwner, uint256 timestamp);
    event PermissionDelegated(uint256 indexed agentId, address indexed delegatee, bytes4 indexed selector, bool allowed, uint256 timestamp);
    event PermissionRevoked(uint256 indexed agentId, address indexed delegatee, bytes4 indexed selector, uint256 timestamp);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, uint256 deadline, uint256 requiredCapability, uint256 timestamp);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed agentId, uint256 timestamp);
    event TaskOutputSubmitted(uint256 indexed taskId, uint256 indexed agentId, string outputURI, uint256 timestamp);
    event AIOracleEvaluationSubmitted(uint256 indexed taskId, uint256 indexed agentId, uint256 qualityScore, uint256 timestamp);
    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardAmount, uint256 timestamp);
    event TaskCancelled(uint256 indexed taskId, address indexed proposer, uint256 timestamp);
    event TaskVerifierUpdated(address indexed verifierAddress, bool isVerifier, uint256 timestamp);

    event AIOracleSuggestionSubmitted(uint256 indexed agentId, uint256 newCapabilityScore, int256 reputationDelta, uint256 timestamp);
    event ChallengeProposed(uint256 indexed challengeId, uint256 indexed challengeType, uint256 referenceId, address indexed challenger, uint256 timestamp);
    event ChallengeResolved(uint256 indexed challengeId, bool challengerWins, int256 reputationImpact, uint256 timestamp);

    event AgentResourcesDeposited(uint256 indexed agentId, address indexed depositor, uint256 amount, uint256 timestamp);
    event AgentResourcesWithdrawn(uint256 indexed agentId, address indexed recipient, uint256 amount, uint256 timestamp);
    event ResourceSpendAuthorized(uint256 indexed agentId, address indexed spender, uint256 amount, uint256 timestamp);

    event SystemParamUpdateProposed(uint256 indexed proposalId, bytes32 indexed paramKey, uint256 newValue, address indexed proposer, uint256 timestamp);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool approve, uint256 timestamp);
    event SystemParamUpdateExecuted(uint256 indexed proposalId, bytes32 indexed paramKey, uint256 newValue, uint256 timestamp);


    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_agentId > 0 && _agentId <= nextAgentId, "AethermindNexus: Invalid agent ID");
        require(agents[_agentId].owner == _msgSender(), "AethermindNexus: Not agent owner");
        _;
    }

    modifier onlyAIOracle() {
        require(isAIOracle[_msgSender()], "AethermindNexus: Caller is not an AI Oracle");
        _;
    }

    modifier onlyTaskVerifier() {
        require(isTaskVerifier[_msgSender()], "AethermindNexus: Caller is not a Task Verifier");
        _;
    }

    modifier onlyCallableByAgentOrDelegate(uint256 _agentId, bytes4 _selector) {
        require(_agentId > 0 && _agentId <= nextAgentId, "AethermindNexus: Invalid agent ID");
        require(
            agents[_agentId].owner == _msgSender() || agents[_agentId].delegatedPermissions[_msgSender()][_selector],
            "AethermindNexus: Not agent owner or authorized delegatee"
        );
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= nextTaskId, "AethermindNexus: Invalid task ID");
        _;
    }

    modifier agentExists(uint256 _agentId) {
        require(_agentId > 0 && _agentId <= nextAgentId, "AethermindNexus: Invalid agent ID");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(_msgSender()) {
        // Set initial system parameters (can be updated via governance)
        systemParameters[keccak256("MIN_REPUTATION_FOR_TASK_ACCEPTANCE")] = 0;
        systemParameters[keccak256("TASK_ACCEPTANCE_GRACE_PERIOD")] = 1 days; // Time for agent to accept after proposal
        systemParameters[keccak256("TASK_SUBMISSION_GRACE_PERIOD")] = 7 days; // Default time for agent to submit output
        systemParameters[keccak256("REPUTATION_DECAY_RATE")] = 1; // e.g., 1% per period (not yet implemented time-decay)
        systemParameters[keccak256("CHALLENGE_STAKE_AMOUNT")] = 0.1 ether; // Stake required to initiate a challenge
        systemParameters[keccak256("VOTING_PERIOD_DURATION")] = 3 days; // For governance proposals
        systemParameters[keccak256("REQUIRED_VOTES_TO_PASS_PROPOSAL_PERCENT")] = 51; // 51% to pass

        // Register deployer as an initial task verifier and AI oracle (for testing/initial setup)
        isAIOracle[_msgSender()] = true;
        isTaskVerifier[_msgSender()] = true;
    }

    // --- I. Agent Management ---

    /// @notice Registers a new Aether Agent for the caller.
    /// @param _agentName The desired name for the new agent.
    /// @return The ID of the newly registered agent.
    function registerAetherAgent(string calldata _agentName) external returns (uint256) {
        require(bytes(_agentName).length > 0, "AethermindNexus: Agent name cannot be empty");
        nextAgentId++;
        agents[nextAgentId] = Agent({
            owner: _msgSender(),
            name: _agentName,
            metadataURI: "",
            capabilityScore: 100, // Initial score
            reputation: 0,
            resourceBalance: 0,
            activeTaskIds: new uint256[](0),
            capabilities: new mapping(uint256 => bool)(), // Initializing mappings in structs is tricky, will be accessed as agents[id].capabilities[type]
            delegatedPermissions: new mapping(address => mapping(bytes4 => bool))(),
            authorizedSpends: new mapping(address => uint256)()
        });
        ownerToAgentIds[_msgSender()].push(nextAgentId);
        emit AgentRegistered(nextAgentId, _msgSender(), _agentName, block.timestamp);
        return nextAgentId;
    }

    /// @notice Updates an Aether Agent's profile information.
    /// @param _agentId The ID of the agent to update.
    /// @param _newAgentName The new name for the agent.
    /// @param _metadataURI A new URI for additional metadata (e.g., IPFS hash).
    function updateAgentProfile(uint256 _agentId, string calldata _newAgentName, string calldata _metadataURI)
        external
        onlyAgentOwner(_agentId)
    {
        require(bytes(_newAgentName).length > 0, "AethermindNexus: Agent name cannot be empty");
        agents[_agentId].name = _newAgentName;
        agents[_agentId].metadataURI = _metadataURI;
        emit AgentProfileUpdated(_agentId, _newAgentName, _metadataURI, block.timestamp);
    }

    /// @notice Sets or revokes a specific capability for an Aether Agent.
    /// @param _agentId The ID of the agent.
    /// @param _capabilityType An identifier for the capability (e.g., a specific enum value or ID).
    /// @param _hasCapability True to add the capability, false to remove it.
    function setAgentCapability(uint256 _agentId, uint256 _capabilityType, bool _hasCapability)
        external
        onlyAgentOwner(_agentId)
    {
        agents[_agentId].capabilities[_capabilityType] = _hasCapability;
        emit AgentCapabilitySet(_agentId, _capabilityType, _hasCapability, block.timestamp);
    }

    /// @notice Retrieves details for a specific Aether Agent.
    /// @param _agentId The ID of the agent.
    /// @return owner_ The owner's address.
    /// @return name_ The agent's name.
    /// @return metadataURI_ The agent's metadata URI.
    /// @return capabilityScore_ The agent's capability score.
    /// @return reputation_ The agent's reputation.
    /// @return resourceBalance_ The agent's native token resource balance.
    /// @return activeTaskIds_ An array of IDs for tasks currently accepted by the agent.
    function getAgentDetails(uint256 _agentId)
        external
        view
        agentExists(_agentId)
        returns (
            address owner_,
            string memory name_,
            string memory metadataURI_,
            uint256 capabilityScore_,
            int256 reputation_,
            uint256 resourceBalance_,
            uint256[] memory activeTaskIds_
        )
    {
        Agent storage agent = agents[_agentId];
        owner_ = agent.owner;
        name_ = agent.name;
        metadataURI_ = agent.metadataURI;
        capabilityScore_ = agent.capabilityScore;
        reputation_ = agent.reputation;
        resourceBalance_ = agent.resourceBalance;
        activeTaskIds_ = agent.activeTaskIds;
    }

    /// @notice Transfers ownership of an Aether Agent to a new address.
    /// @param _agentId The ID of the agent to transfer.
    /// @param _newOwner The address of the new owner.
    function transferAgentOwnership(uint256 _agentId, address _newOwner) external onlyAgentOwner(_agentId) {
        require(_newOwner != address(0), "AethermindNexus: New owner cannot be zero address");
        address oldOwner = agents[_agentId].owner;
        agents[_agentId].owner = _newOwner;

        // Update ownerToAgentIds mappings (simplified: remove from old owner, add to new)
        // Note: For efficiency in a real system, `ownerToAgentIds` might be optimized or removed if agents are ERC721.
        uint256[] storage oldOwnerAgents = ownerToAgentIds[oldOwner];
        for (uint256 i = 0; i < oldOwnerAgents.length; i++) {
            if (oldOwnerAgents[i] == _agentId) {
                oldOwnerAgents[i] = oldOwnerAgents[oldOwnerAgents.length - 1];
                oldOwnerAgents.pop();
                break;
            }
        }
        ownerToAgentIds[_newOwner].push(_agentId);

        emit AgentOwnershipTransferred(_agentId, oldOwner, _newOwner, block.timestamp);
    }

    /// @notice Delegates permission for a specific function call to another address.
    /// @param _agentId The ID of the agent.
    /// @param _delegatee The address to delegate permission to.
    /// @param _selector The function selector (e.g., `this.updateAgentProfile.selector`).
    /// @param _allow True to grant permission, false to revoke.
    function delegateAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector, bool _allow)
        external
        onlyAgentOwner(_agentId)
    {
        require(_delegatee != address(0), "AethermindNexus: Delegatee cannot be zero address");
        agents[_agentId].delegatedPermissions[_delegatee][_selector] = _allow;
        emit PermissionDelegated(_agentId, _delegatee, _selector, _allow, block.timestamp);
    }

    /// @notice Revokes a previously granted delegated permission.
    /// @param _agentId The ID of the agent.
    /// @param _delegatee The address whose permission is being revoked.
    /// @param _selector The function selector for which permission is revoked.
    function revokeAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector)
        external
        onlyAgentOwner(_agentId)
    {
        agents[_agentId].delegatedPermissions[_delegatee][_selector] = false;
        emit PermissionRevoked(_agentId, _delegatee, _selector, block.timestamp);
    }

    // --- II. Task Orchestration ---

    /// @notice Proposes a new Aether Task that agents can accept.
    /// @param _taskDescription A description of the task.
    /// @param _rewardAmount The native token reward for completing the task.
    /// @param _deadline The Unix timestamp by which the task must be completed.
    /// @param _requiredCapabilityType The capability ID required to perform this task.
    /// @return The ID of the newly proposed task.
    function proposeAetherTask(
        string calldata _taskDescription,
        uint256 _rewardAmount,
        uint256 _deadline,
        uint256 _requiredCapabilityType
    ) external payable returns (uint256) {
        require(bytes(_taskDescription).length > 0, "AethermindNexus: Task description cannot be empty");
        require(_rewardAmount > 0, "AethermindNexus: Reward must be greater than zero");
        require(_deadline > block.timestamp, "AethermindNexus: Deadline must be in the future");
        require(msg.value == _rewardAmount, "AethermindNexus: Sent value must match reward amount");

        nextTaskId++;
        tasks[nextTaskId] = Task({
            proposer: _msgSender(),
            agentId: 0, // Not yet accepted
            description: _taskDescription,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            requiredCapabilityType: _requiredCapabilityType,
            outputURI: "",
            qualityScore: 0,
            status: TaskStatus.Proposed,
            currentVerifier: address(0) // Will be set upon acceptance or explicit assignment
        });
        emit TaskProposed(nextTaskId, _msgSender(), _rewardAmount, _deadline, _requiredCapabilityType, block.timestamp);
        return nextTaskId;
    }

    /// @notice Allows an eligible Aether Agent to accept a proposed task.
    /// @param _taskId The ID of the task to accept.
    /// @param _agentId The ID of the agent accepting the task.
    function acceptAetherTask(uint256 _taskId, uint256 _agentId)
        external
        nonReentrant
        onlyCallableByAgentOrDelegate(_agentId, this.acceptAetherTask.selector)
        taskExists(_taskId)
        agentExists(_agentId)
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.status == TaskStatus.Proposed, "AethermindNexus: Task not in proposed state");
        require(
            block.timestamp < task.deadline - systemParameters[keccak256("TASK_SUBMISSION_GRACE_PERIOD")],
            "AethermindNexus: Task acceptance deadline passed"
        );
        require(agent.capabilities[task.requiredCapabilityType], "AethermindNexus: Agent lacks required capability");
        require(agent.reputation >= int256(systemParameters[keccak256("MIN_REPUTATION_FOR_TASK_ACCEPTANCE")]), "AethermindNexus: Agent reputation too low");

        task.agentId = _agentId;
        task.status = TaskStatus.Accepted;
        agent.activeTaskIds.push(_taskId);
        emit TaskAccepted(_taskId, _agentId, block.timestamp);
    }

    /// @notice Submits the output for an accepted task.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent submitting the output.
    /// @param _outputURI A URI (e.g., IPFS hash) pointing to the task output.
    function submitTaskOutput(uint256 _taskId, uint256 _agentId, string calldata _outputURI)
        external
        nonReentrant
        onlyCallableByAgentOrDelegate(_agentId, this.submitTaskOutput.selector)
        taskExists(_taskId)
        agentExists(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.agentId == _agentId, "AethermindNexus: Agent not assigned to this task");
        require(task.status == TaskStatus.Accepted, "AethermindNexus: Task not in accepted state");
        require(block.timestamp < task.deadline, "AethermindNexus: Task submission deadline passed");

        task.outputURI = _outputURI;
        task.status = TaskStatus.OutputSubmitted;
        emit TaskOutputSubmitted(_taskId, _agentId, _outputURI, block.timestamp);
    }

    /// @notice A designated AI Oracle submits an evaluation for a completed task.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent who completed the task.
    /// @param _qualityScore The quality score (0-100) assigned by the AI.
    function submitAIOracleEvaluation(uint256 _taskId, uint256 _agentId, uint256 _qualityScore)
        external
        nonReentrant
        onlyAIOracle
        taskExists(_taskId)
        agentExists(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.agentId == _agentId, "AethermindNexus: Task not assigned to this agent");
        require(task.status == TaskStatus.OutputSubmitted, "AethermindNexus: Task output not submitted");
        require(_qualityScore <= 100, "AethermindNexus: Quality score must be between 0 and 100");

        task.qualityScore = _qualityScore;
        task.status = TaskStatus.Evaluated;

        // Apply reputation impact
        int256 reputationChange = _qualityScore >= 70 ? int256(_qualityScore / 5) : -int256((100 - _qualityScore) / 2); // Example logic
        agents[_agentId].reputation += reputationChange;

        emit AIOracleEvaluationSubmitted(_taskId, _agentId, _qualityScore, block.timestamp);
    }

    /// @notice Allows the agent to claim the reward for a successfully evaluated task.
    /// @param _taskId The ID of the task.
    function claimTaskReward(uint256 _taskId) external nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Evaluated, "AethermindNexus: Task not yet evaluated or already rewarded");
        require(agents[task.agentId].owner == _msgSender(), "AethermindNexus: Only agent owner can claim reward");

        // Mark task as rewarded before transfer to prevent reentrancy
        task.status = TaskStatus.Rewarded;

        // Remove task from agent's active tasks
        uint256[] storage activeTaskIds = agents[task.agentId].activeTaskIds;
        for (uint256 i = 0; i < activeTaskIds.length; i++) {
            if (activeTaskIds[i] == _taskId) {
                activeTaskIds[i] = activeTaskIds[activeTaskIds.length - 1];
                activeTaskIds.pop();
                break;
            }
        }

        (bool success, ) = payable(_msgSender()).call{value: task.rewardAmount}("");
        require(success, "AethermindNexus: Failed to send reward");

        emit TaskRewardClaimed(_taskId, task.agentId, task.rewardAmount, block.timestamp);
    }

    /// @notice Allows the task proposer to cancel a task if it hasn't been accepted or completed.
    /// @param _taskId The ID of the task to cancel.
    function cancelAetherTask(uint256 _taskId) external nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.proposer == _msgSender(), "AethermindNexus: Only proposer can cancel task");
        require(
            task.status == TaskStatus.Proposed || task.status == TaskStatus.Accepted,
            "AethermindNexus: Task cannot be cancelled in its current state"
        );

        if (task.status == TaskStatus.Accepted) {
            // Remove from agent's active tasks if it was accepted
            uint256[] storage activeTaskIds = agents[task.agentId].activeTaskIds;
            for (uint256 i = 0; i < activeTaskIds.length; i++) {
                if (activeTaskIds[i] == _taskId) {
                    activeTaskIds[i] = activeTaskIds[activeTaskIds.length - 1];
                    activeTaskIds.pop();
                    break;
                }
            }
            // Penalty for agent for accepted but cancelled task? Or only reputation impact
            agents[task.agentId].reputation -= 5; // Example penalty
        }

        task.status = TaskStatus.Cancelled;

        (bool success, ) = payable(task.proposer).call{value: task.rewardAmount}("");
        require(success, "AethermindNexus: Failed to refund proposer");

        emit TaskCancelled(_taskId, _msgSender(), block.timestamp);
    }

    /// @notice Allows the contract owner to register or unregister an address as a valid task verifier.
    /// @param _verifierAddress The address to set as a verifier.
    /// @param _isVerifier True to register, false to unregister.
    function registerTaskVerifier(address _verifierAddress, bool _isVerifier) external onlyOwner {
        require(_verifierAddress != address(0), "AethermindNexus: Verifier address cannot be zero");
        isTaskVerifier[_verifierAddress] = _isVerifier;
        emit TaskVerifierUpdated(_verifierAddress, _isVerifier, block.timestamp);
    }

    // --- III. AI Oracle & Reputation Management ---

    /// @notice A designated AI Oracle provides suggestions for updating an agent's internal capability score and reputation.
    /// @param _agentId The ID of the agent for whom the suggestion is made.
    /// @param _newCapabilityScore The AI's suggested new capability score.
    /// @param _reputationDelta The AI's suggested change to the agent's reputation.
    function submitAIOracleSuggestion(uint256 _agentId, uint256 _newCapabilityScore, int256 _reputationDelta)
        external
        onlyAIOracle
        agentExists(_agentId)
    {
        Agent storage agent = agents[_agentId];
        agent.capabilityScore = _newCapabilityScore;
        agent.reputation += _reputationDelta;
        emit AIOracleSuggestionSubmitted(_agentId, _newCapabilityScore, _reputationDelta, block.timestamp);
    }

    /// @notice Allows any participant to challenge an AI oracle's evaluation or reputation suggestion, initiating a dispute.
    /// @param _challengeType The type of challenge (e.g., OracleEvaluation, AgentReputationSuggestion).
    /// @param _entityId The ID of the primary entity involved (e.g., taskId, agentId).
    /// @param _referenceId An additional ID for context (e.g., specific evaluation ID if applicable, or 0).
    /// @param _reasonURI A URI (e.g., IPFS hash) linking to detailed reasons for the challenge.
    function challengeOracleOutput(uint256 _challengeType, uint256 _entityId, uint256 _referenceId, string calldata _reasonURI)
        external
        payable
        nonReentrant
    {
        require(msg.value >= systemParameters[keccak256("CHALLENGE_STAKE_AMOUNT")], "AethermindNexus: Insufficient stake to challenge");
        require(bytes(_reasonURI).length > 0, "AethermindNexus: Reason URI cannot be empty");

        nextChallengeId++;
        challenges[nextChallengeId] = Challenge({
            challenger: _msgSender(),
            challengee: _challengeType == uint256(ChallengeType.OracleEvaluation) ? tasks[_entityId].currentVerifier : address(0), // Placeholder, could be specific AI oracle address
            challengeType: _challengeType,
            referenceId: _entityId,
            reasonURI: _reasonURI,
            status: ChallengeStatus.Pending,
            challengerWins: false,
            reputationImpact: 0
        });
        emit ChallengeProposed(nextChallengeId, _challengeType, _entityId, _msgSender(), block.timestamp);
    }

    /// @notice An admin/governance function to resolve a dispute, determining if the challenger wins and the impact on involved parties' reputation.
    /// @dev This function assumes an off-chain governance or arbitration process resolves the challenge.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _challengerWins True if the challenger's claim is upheld, false otherwise.
    /// @param _reputationImpact The absolute value of reputation points to apply (positive for winner, negative for loser).
    function resolveChallenge(uint256 _challengeId, bool _challengerWins, int256 _reputationImpact)
        external
        onlyOwner // For now, only owner can resolve; ideally, this would be a DAO/governance vote.
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Pending, "AethermindNexus: Challenge not pending");
        require(_reputationImpact >= 0, "AethermindNexus: Reputation impact must be non-negative");

        challenge.status = ChallengeStatus.Resolved;
        challenge.challengerWins = _challengerWins;
        challenge.reputationImpact = _reputationImpact;

        // Apply reputation changes and manage stake
        if (_challengerWins) {
            // Challenger wins: Challenger gets stake back, opponent (e.g., oracle) loses reputation.
            // If the challengee is an agent, their reputation is impacted.
            if (challenge.challengeType == uint256(ChallengeType.AgentReputationSuggestion)) {
                 // The entityId for AgentReputationSuggestion should be the agent's ID
                agents[challenge.referenceId].reputation -= _reputationImpact;
            } else if (challenge.challengee != address(0)) {
                // If there's a specific challengee (like an oracle/verifier address), it could lose reputation
                // For simplicity here, we assume only agents have mutable on-chain reputation for now
            }
            (bool success, ) = payable(challenge.challenger).call{value: systemParameters[keccak256("CHALLENGE_STAKE_AMOUNT")]}("");
            require(success, "AethermindNexus: Failed to refund challenger stake");

        } else {
            // Challenger loses: Challenger loses stake, opponent (if any) gains reputation.
            // If challenger is an agent, their reputation is impacted.
            uint256[] storage challengerAgentIds = ownerToAgentIds[challenge.challenger];
            if (challengerAgentIds.length > 0) { // If challenger has an agent, impact its reputation
                agents[challengerAgentIds[0]].reputation -= _reputationImpact; // Assume first agent, or specify which agent
            }
            // The stake stays in the contract or is distributed to verifiers/governance pool.
            // For now, it stays in the contract.
        }

        emit ChallengeResolved(_challengeId, _challengerWins, _reputationImpact, block.timestamp);
    }

    // --- IV. Agent Resource & Authorization ---

    /// @notice Allows an agent's owner to deposit native tokens into their agent's internal resource pool.
    /// @param _agentId The ID of the agent.
    function depositAgentResources(uint256 _agentId) external payable nonReentrant onlyAgentOwner(_agentId) {
        require(msg.value > 0, "AethermindNexus: Deposit amount must be greater than zero");
        agents[_agentId].resourceBalance += msg.value;
        emit AgentResourcesDeposited(_agentId, _msgSender(), msg.value, block.timestamp);
    }

    /// @notice Allows an agent's owner to withdraw native tokens from their agent's resource pool.
    /// @param _agentId The ID of the agent.
    /// @param _amount The amount of native tokens to withdraw.
    function withdrawAgentResources(uint256 _agentId, uint256 _amount)
        external
        nonReentrant
        onlyAgentOwner(_agentId)
    {
        require(_amount > 0, "AethermindNexus: Withdraw amount must be greater than zero");
        require(agents[_agentId].resourceBalance >= _amount, "AethermindNexus: Insufficient resource balance");
        agents[_agentId].resourceBalance -= _amount;
        (bool success, ) = payable(_msgSender()).call{value: _amount}("");
        require(success, "AethermindNexus: Failed to send withdrawal");
        emit AgentResourcesWithdrawn(_agentId, _msgSender(), _amount, block.timestamp);
    }

    /// @notice Allows an agent owner to authorize another address to spend a specific amount from their agent's resource pool.
    /// @param _agentId The ID of the agent.
    /// @param _spender The address authorized to spend.
    /// @param _amount The maximum amount `_spender` can spend.
    function authorizeResourceSpend(uint256 _agentId, address _spender, uint256 _amount)
        external
        onlyAgentOwner(_agentId)
    {
        require(_spender != address(0), "AethermindNexus: Spender cannot be zero address");
        agents[_agentId].authorizedSpends[_spender] = _amount;
        emit ResourceSpendAuthorized(_agentId, _spender, _amount, block.timestamp);
    }

    // A helper function for spending authorized resources (could be externalized to another contract)
    function _spendAuthorizedResources(uint256 _agentId, address _spender, uint256 _amount) internal returns (bool) {
        require(agents[_agentId].authorizedSpends[_spender] >= _amount, "AethermindNexus: Spender not authorized for this amount");
        require(agents[_agentId].resourceBalance >= _amount, "AethermindNexus: Agent has insufficient resources");

        agents[_agentId].resourceBalance -= _amount;
        agents[_agentId].authorizedSpends[_spender] -= _amount; // Reduce allowance
        (bool success, ) = payable(_spender).call{value: _amount}("");
        return success;
    }


    // --- V. Governance & System Parameters ---

    /// @notice Allows any stakeholder (or agent owner) to propose a change to a core system parameter.
    /// @param _paramKey The keccak256 hash of the parameter name (e.g., `keccak256("MIN_REPUTATION_FOR_TASK_ACCEPTANCE")`).
    /// @param _newValue The new value proposed for the parameter.
    /// @return The ID of the newly created proposal.
    function proposeSystemParamUpdate(bytes32 _paramKey, uint256 _newValue) external returns (uint256) {
        // Basic check for parameter validity (e.g., must be an existing key, or within reasonable bounds)
        // For simplicity, any bytes32 can be proposed, but real governance would limit this.
        require(_newValue > 0 || _paramKey == keccak256("MIN_REPUTATION_FOR_TASK_ACCEPTANCE"), "AethermindNexus: New value must be positive (except for min_rep which can be 0)");

        nextProposalId++;
        proposals[nextProposalId] = SystemParamProposal({
            proposer: _msgSender(),
            paramKey: _paramKey,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + systemParameters[keccak256("VOTING_PERIOD_DURATION")],
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool)()
        });
        emit SystemParamUpdateProposed(nextProposalId, _paramKey, _newValue, _msgSender(), block.timestamp);
        return nextProposalId;
    }

    /// @notice Allows stakeholders to vote on an active system parameter update proposal.
    /// @dev For simplicity, voting power is 1 address = 1 vote. In a real DAO, this would be token-weighted.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _approve True to vote 'Yes', false to vote 'No'.
    function voteOnParamUpdate(uint256 _proposalId, bool _approve) external {
        SystemParamProposal storage proposal = proposals[_proposalId];
        require(proposal.paramKey != bytes32(0), "AethermindNexus: Invalid proposal ID");
        require(!proposal.executed, "AethermindNexus: Proposal already executed");
        require(block.timestamp >= proposal.voteStartTime, "AethermindNexus: Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "AethermindNexus: Voting has ended");
        require(!proposal.hasVoted[_msgSender()], "AethermindNexus: Already voted on this proposal");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[_msgSender()] = true;
        emit VoteCast(_proposalId, _msgSender(), _approve, block.timestamp);
    }

    /// @notice Executes a system parameter update if the voting period has ended and the proposal has passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeParamUpdate(uint256 _proposalId) external onlyOwner {
        SystemParamProposal storage proposal = proposals[_proposalId];
        require(proposal.paramKey != bytes32(0), "AethermindNexus: Invalid proposal ID");
        require(!proposal.executed, "AethermindNexus: Proposal already executed");
        require(block.timestamp >= proposal.voteEndTime, "AethermindNexus: Voting period has not ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "AethermindNexus: No votes cast for this proposal");

        uint256 requiredYesVotes = (totalVotes * systemParameters[keccak256("REQUIRED_VOTES_TO_PASS_PROPOSAL_PERCENT")]) / 100;

        if (proposal.yesVotes >= requiredYesVotes) {
            systemParameters[proposal.paramKey] = proposal.newValue;
            proposal.executed = true;
            emit SystemParamUpdateExecuted(_proposalId, proposal.paramKey, proposal.newValue, block.timestamp);
        } else {
            // Proposal failed, mark as executed (or just leave it unexecuted) to prevent re-execution attempts
            proposal.executed = true; // Mark as processed
        }
    }

    /// @notice Retrieves the current value of a specific system parameter.
    /// @param _paramKey The keccak256 hash of the parameter name.
    /// @return The current value of the parameter.
    function getSystemParameter(bytes32 _paramKey) external view returns (uint256) {
        return systemParameters[_paramKey];
    }
}
```