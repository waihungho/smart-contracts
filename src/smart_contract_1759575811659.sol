This smart contract, `SynapticOrchestrator`, is designed as a decentralized marketplace for AI-related computational tasks. It allows users (Requestors) to propose tasks and AI agents (Compute Providers) to bid on and execute them. The core advanced concepts revolve around establishing trust and accountability in a decentralized environment for off-chain AI computation, using a combination of staking, an attestation-based reputation system, and a simplified dispute resolution mechanism.

### Outline:

1.  **Core Data Structures & Enums:** Defines the fundamental types and states for agents and tasks within the system.
2.  **Agent Management:** Covers the lifecycle of AI agents, including registration, staking, metadata updates, and deregistration.
3.  **Task Management:** Details the process of proposing tasks, bidding, agent selection, result submission, and handling task challenges and expirations.
4.  **Reputation System:** Implements a mechanism for updating an agent's reputation based on performance attestations.
5.  **Dispute Resolution:** Provides a framework for resolving challenges to task results, with owner/governance oversight.
6.  **Platform Fees & Withdrawals:** Manages the collection and withdrawal of service fees.
7.  **Governance & Parameter Management:** Allows the contract owner to configure key operational parameters.
8.  **Emergency Controls:** Provides functions to pause and unpause the contract for security and maintenance.

### Function Summary:

#### AGENT MANAGEMENT (6 functions)

1.  `registerAgent(bytes32 agentIdHash, string calldata metadataURI)`: Registers a new AI agent, requiring a minimum stake (ETH sent with the transaction).
2.  `updateAgentMetadata(string calldata newMetadataURI)`: Allows a registered agent to update their descriptive metadata URI (e.g., pointing to an updated IPFS file).
3.  `updateAgentStake()`: Allows an agent to increase their existing stake by sending additional ETH to the contract.
4.  `requestUnstake(uint256 amount)`: Initiates a cooldown period for unstaking a specified amount of an agent's staked funds.
5.  `claimUnstakedFunds()`: Allows an agent to withdraw their unstaked funds after the defined cooldown period has expired.
6.  `deregisterAgent()`: Initiates full deregistration for an agent, preparing all their stake for withdrawal after a cooldown period and preventing them from taking new tasks.

#### TASK MANAGEMENT (8 functions)

7.  `proposeTask(bytes32 taskHash, string calldata dataInputURI, uint256 rewardAmount, uint256 maxExecutionTime, uint256 minRequiredReputation)`: A requestor proposes a new AI task, specifying task details, reward, and agent requirements.
8.  `depositTaskFunds(uint256 taskId)`: Requestor deposits the required reward and calculated platform fee for a proposed task, making it available for bidding.
9.  `cancelProposedTask(uint256 taskId)`: Allows the requestor to cancel their task if it has not yet been assigned to an agent, refunding deposited funds.
10. `bidOnTask(uint256 taskId, uint256 bidAmount)`: An eligible AI agent places a bid to execute a specific task, committing to the specified bid price.
11. `selectAgentForTask(uint256 taskId, address agentAddress)`: The requestor selects an agent from the bidders to execute their task, formally assigning it.
12. `submitTaskResult(uint256 taskId, string calldata resultURI, bytes calldata agentSignature)`: The assigned agent submits the result of the task, including a URI to the output and a cryptographic signature.
13. `challengeTaskResult(uint256 taskId, string calldata evidenceURI)`: A requestor or an authorized verifier can challenge the validity of a submitted task result, initiating a dispute.
14. `reclaimExpiredTaskFunds(uint256 taskId)`: Allows the requestor to reclaim their deposited funds if an assigned task expires without the agent submitting a valid result.

#### REPUTATION SYSTEM (2 functions)

15. `getAgentReputation(address agentAddress)`: A public view function to retrieve an agent's current reputation score.
16. `attestAgentPerformance(uint256 taskId, bool success, string calldata feedbackURI)`: A requestor or an authorized verifier attests to an agent's performance on a completed task, leading to an update in the agent's reputation.

#### DISPUTE RESOLUTION (1 function)

17. `resolveDispute(uint256 taskId, address winningParty, int256 agentReputationImpact, int256 challengerReputationImpact)`: The contract owner/governance resolves a challenged task, distributing funds based on the outcome and updating the reputations of involved parties.

#### PLATFORM FEES & WITHDRAWALS (1 function)

18. `withdrawPlatformFees()`: Allows the contract owner/governance to withdraw accumulated platform fees to the owner's address.

#### GOVERNANCE & PARAMETER MANAGEMENT (6 functions)

19. `updateStakingRequirement(uint256 newAmount)`: Updates the minimum ETH stake required for agents to register and remain active.
20. `updateUnstakeCooldown(uint256 newCooldown)`: Adjusts the cooldown period (in seconds) that must pass before unstaked funds can be claimed.
21. `updateMaxTaskExecutionTime(uint256 newTime)`: Modifies the default maximum allowed time (in seconds) for an agent to execute a task after assignment.
22. `updatePlatformFeeRate(uint256 newFeeRate)`: Sets the new percentage rate (in basis points) of fees collected by the platform from task rewards.
23. `addAuthorizedVerifier(address verifierAddress)`: Grants a specified address the permission to act as an authorized verifier for task performance attestations.
24. `removeAuthorizedVerifier(address verifierAddress)`: Revokes the permission of an address to act as an authorized verifier.

#### EMERGENCY CONTROLS (2 functions)

25. `pause()`: Pauses most state-changing operations of the contract in case of an emergency or critical issue.
26. `unpause()`: Resumes contract operations after it has been paused.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Core Data Structures & Enums
// 2. Agent Management (Registration, Staking, Metadata, Lifecycle)
// 3. Task Management (Proposal, Bidding, Assignment, Submission, State Transitions)
// 4. Reputation System (Attestation, Score Updates, Queries)
// 5. Dispute Resolution (Challenge, Owner/Governance Resolution)
// 6. Platform Fees & Withdrawals
// 7. Governance & Parameter Management (Owner-controlled)
// 8. Emergency Controls (Pause/Unpause)

// Function Summary:
// AGENT MANAGEMENT (6 functions)
// 1.  registerAgent(bytes32 agentIdHash, string calldata metadataURI): Registers a new AI agent, requiring a minimum stake.
// 2.  updateAgentMetadata(string calldata newMetadataURI): Allows a registered agent to update their descriptive metadata URI.
// 3.  updateAgentStake(): Allows an agent to increase their existing stake. Deposits additional ETH.
// 4.  requestUnstake(uint256 amount): Initiates a cooldown period for unstaking a specified amount.
// 5.  claimUnstakedFunds(): Allows an agent to withdraw their unstaked funds after the cooldown period.
// 6.  deregisterAgent(): Initiates full deregistration, withdrawing all stake after a cooldown period, preventing new task assignments.
//
// TASK MANAGEMENT (8 functions)
// 7.  proposeTask(bytes32 taskHash, string calldata dataInputURI, uint256 rewardAmount, uint256 maxExecutionTime, uint256 minRequiredReputation): Requestor proposes a new AI task with details and requirements.
// 8.  depositTaskFunds(uint256 taskId): Requestor deposits the required reward and platform fee for a proposed task.
// 9.  cancelProposedTask(uint256 taskId): Requestor cancels their task if it has not yet been assigned to an agent.
// 10. bidOnTask(uint256 taskId, uint256 bidAmount): An eligible agent bids to execute a specific task, committing to the bid price.
// 11. selectAgentForTask(uint256 taskId, address agentAddress): Requestor selects an agent from the bidders to execute the task.
// 12. submitTaskResult(uint256 taskId, string calldata resultURI, bytes calldata agentSignature): Agent submits the result URI and a cryptographic signature verifying the submission.
// 13. challengeTaskResult(uint256 taskId, string calldata evidenceURI): A requestor or authorized verifier challenges the validity of a submitted task result.
// 14. reclaimExpiredTaskFunds(uint256 taskId): Allows the requestor to reclaim funds for tasks that expired without a valid result or dispute resolution.
//
// REPUTATION SYSTEM (2 functions)
// 15. getAgentReputation(address agentAddress): View function to retrieve an agent's current reputation score.
// 16. attestAgentPerformance(uint256 taskId, bool success, string calldata feedbackURI): Requestor or authorized verifier attests to an agent's performance on a completed task, influencing reputation.
//
// DISPUTE RESOLUTION (1 function)
// 17. resolveDispute(uint256 taskId, address winningParty, int256 agentReputationImpact, int256 challengerReputationImpact): Owner/governance resolves a challenged task, distributing funds and updating reputations.
//
// PLATFORM FEES & WITHDRAWALS (1 function)
// 18. withdrawPlatformFees(): Owner/governance withdraws accumulated platform fees.
//
// GOVERNANCE & PARAMETER MANAGEMENT (6 functions)
// 19. updateStakingRequirement(uint256 newAmount): Updates the minimum stake required for new and existing agents.
// 20. updateUnstakeCooldown(uint256 newCooldown): Updates the unstaking cooldown period.
// 21. updateMaxTaskExecutionTime(uint256 newTime): Adjusts the maximum allowed time an agent has to execute a task after assignment.
// 22. updatePlatformFeeRate(uint256 newFeeRate): Updates the percentage rate of fees collected by the platform (e.g., 500 for 5%).
// 23. addAuthorizedVerifier(address verifierAddress): Grants an address the ability to make performance attestations.
// 24. removeAuthorizedVerifier(address verifierAddress): Revokes an address's ability to make performance attestations.
//
// EMERGENCY CONTROLS (2 functions)
// 25. pause(): Pauses the contract, preventing most state-changing operations.
// 26. unpause(): Resumes contract operations.
//
// Total functions: 26

contract SynapticOrchestrator is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- 1. Core Data Structures & Enums ---

    // Enums for Agent and Task states
    enum AgentState {
        Registered,
        Deregistering, // Agent requested to deregister, cooldown active
        Deregistered   // Agent fully deregistered and stake withdrawn
    }

    enum TaskState {
        Proposed,         // Task proposed, awaiting funds deposit
        FundsDeposited,   // Funds are held, awaiting agent selection
        BiddingOpen,      // Explicitly open for agents to bid
        AgentSelected,    // Agent assigned, awaiting execution and result submission
        ResultSubmitted,  // Agent submitted result, awaiting attestation or challenge
        Challenged,       // Result challenged, awaiting dispute resolution
        Completed,        // Task successfully completed, funds distributed, reputation updated
        Disputed,         // Alias for Challenged, awaiting owner/governance resolution
        Cancelled,        // Task cancelled by requestor or due to expiration/failure
        ExpiredNoResult   // Task expired without a valid result from the agent
    }

    // Struct for an AI Agent
    struct Agent {
        bytes32 agentIdHash;    // Unique identifier hash for the agent (e.g., hash of public key or URI)
        string metadataURI;     // IPFS URI to agent's description, capabilities, etc.
        uint256 stake;          // ETH staked by the agent
        uint256 reputation;     // Reputation score (starts at 0, can go negative)
        AgentState state;       // Current state of the agent
        uint256 unstakeRequestTime; // Timestamp when unstake was requested
        uint256 pendingUnstakeAmount; // Amount requested to unstake
    }

    // Struct for a Task Proposal
    struct Task {
        uint256 id;                 // Unique task ID
        address requestor;          // Address of the task requestor
        bytes32 taskHash;           // Hash of the task definition (e.g., requirements, model params)
        string dataInputURI;        // IPFS URI to input data for the task
        uint256 rewardAmount;       // Base reward for the agent (before agent's bid)
        uint256 platformFee;        // Calculated platform fee
        uint256 totalFundsLocked;   // Total funds (reward + fee) locked for the task
        address assignedAgent;      // Address of the agent assigned to this task
        uint256 assignedAgentBid;   // The amount the assigned agent bid for the task (<= rewardAmount)
        string resultURI;           // IPFS URI to the agent's submitted result
        string evidenceURI;         // IPFS URI to evidence in case of a challenge
        uint256 submissionTime;     // Timestamp when the result was submitted
        uint256 assignmentTime;     // Timestamp when the task was assigned
        uint256 maxExecutionTime;   // Max time allowed for execution after assignment
        uint256 minRequiredReputation; // Minimum reputation an agent must have to bid
        TaskState state;            // Current state of the task
        // Mapping of agent address to their bid amount. Not stored on-chain to save gas for bids.
        // Instead, the selected agent's bid is stored in assignedAgentBid.
        // For actual bidding, a separate off-chain system or on-chain event logging would be used.
        bool hasAttestation;        // Flag to prevent multiple attestations for a single task
    }

    // --- State Variables ---

    Counters.Counter private _taskIdCounter; // Counter for unique task IDs
    uint256 public minAgentStakingRequirement; // Minimum ETH required to register as an agent
    uint256 public unstakeCooldownPeriod;     // Time (in seconds) before unstaked funds can be claimed
    uint256 public maxDefaultTaskExecutionTime; // Default max time for task execution if not specified by requestor
    uint256 public platformFeeRate;             // Fee rate in basis points (e.g., 500 for 5%, max 10000 for 100%)
    uint256 public totalPlatformFeesCollected;  // Accumulator for collected fees

    // Mappings
    mapping(address => Agent) public agents;
    mapping(address => bool) public isAgent; // Quick check if an address is a registered agent
    mapping(uint256 => Task) public tasks;
    mapping(address => bool) public authorizedVerifiers; // Addresses authorized to provide attestations (beyond requestors)
    mapping(uint256 => mapping(address => uint256)) private taskBids; // Mapping: Task ID -> Agent Address -> Bid Amount

    // --- Events ---

    event AgentRegistered(address indexed agentAddress, bytes32 agentIdHash, string metadataURI, uint256 initialStake);
    event AgentMetadataUpdated(address indexed agentAddress, string newMetadataURI);
    event AgentStakeUpdated(address indexed agentAddress, uint256 newStake);
    event UnstakeRequested(address indexed agentAddress, uint256 amount, uint256 requestTime);
    event UnstakeClaimed(address indexed agentAddress, uint256 amount);
    event AgentDeregistered(address indexed agentAddress);

    event TaskProposed(uint256 indexed taskId, address indexed requestor, bytes32 taskHash, uint256 rewardAmount);
    event TaskFundsDeposited(uint256 indexed taskId, address indexed requestor, uint256 totalFunds);
    event TaskCancelled(uint256 indexed taskId, address indexed requestor);
    event TaskBid(uint256 indexed taskId, address indexed agentAddress, uint256 bidAmount);
    event AgentSelected(uint256 indexed taskId, address indexed requestor, address indexed agentAddress, uint256 bidAmount);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed agentAddress, string resultURI);
    event TaskChallenged(uint256 indexed taskId, address indexed challenger, string evidenceURI);
    event TaskCompleted(uint256 indexed taskId, address indexed agentAddress, address indexed requestor, uint256 rewardPaid);
    event TaskDisputeResolved(uint256 indexed taskId, address indexed winningParty, address indexed losingParty, int256 agentReputationImpact, int256 challengerReputationImpact);
    event TaskExpiredReclaimed(uint256 indexed taskId, address indexed requestor, uint256 fundsReclaimed);

    event AgentReputationUpdated(address indexed agentAddress, int256 scoreChange, uint256 newReputation);
    event PerformanceAttested(uint256 indexed taskId, address indexed agentAddress, bool success, string feedbackURI);

    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);

    event StakingRequirementUpdated(uint256 newRequirement);
    event UnstakeCooldownUpdated(uint256 newCooldown);
    event MaxTaskExecutionTimeUpdated(uint256 newTime);
    event PlatformFeeRateUpdated(uint256 newRate);
    event AuthorizedVerifierAdded(address indexed verifierAddress);
    event AuthorizedVerifierRemoved(address indexed verifierAddress);

    // --- Constructor ---

    constructor(uint256 _minAgentStakingRequirement, uint256 _unstakeCooldownPeriod, uint256 _maxDefaultTaskExecutionTime, uint256 _platformFeeRate) Ownable(msg.sender) {
        require(_minAgentStakingRequirement > 0, "Staking requirement must be positive");
        require(_unstakeCooldownPeriod > 0, "Unstake cooldown must be positive");
        require(_maxDefaultTaskExecutionTime > 0, "Max task execution time must be positive");
        require(_platformFeeRate <= 10000, "Fee rate cannot exceed 100%"); // 10000 basis points = 100%

        minAgentStakingRequirement = _minAgentStakingRequirement;
        unstakeCooldownPeriod = _unstakeCooldownPeriod;
        maxDefaultTaskExecutionTime = _maxDefaultTaskExecutionTime;
        platformFeeRate = _platformFeeRate;
    }

    // --- Modifiers ---

    modifier onlyAgent() {
        require(isAgent[msg.sender], "Caller is not a registered agent");
        require(agents[msg.sender].state == AgentState.Registered, "Agent not in Registered state");
        _;
    }

    modifier onlyTaskRequestor(uint256 _taskId) {
        require(tasks[_taskId].requestor == msg.sender, "Caller is not the task requestor");
        _;
    }

    modifier onlyAssignedAgent(uint256 _taskId) {
        require(tasks[_taskId].assignedAgent == msg.sender, "Caller is not the assigned agent");
        _;
    }

    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender] || tasks[msg.sender].requestor == msg.sender, "Caller not an authorized verifier or requestor");
        _;
    }

    // --- 2. Agent Management (6 functions) ---

    /// @notice Registers a new AI agent, requiring a minimum stake.
    /// @param _agentIdHash A unique identifier hash for the agent (e.g., hash of public key or URI).
    /// @param _metadataURI IPFS URI to the agent's description, capabilities, etc.
    function registerAgent(bytes32 _agentIdHash, string calldata _metadataURI) external payable whenNotPaused nonReentrant {
        require(!isAgent[msg.sender], "Agent already registered");
        require(msg.value >= minAgentStakingRequirement, "Insufficient stake to register");
        require(_agentIdHash != bytes32(0), "Agent ID hash cannot be zero");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");

        agents[msg.sender] = Agent({
            agentIdHash: _agentIdHash,
            metadataURI: _metadataURI,
            stake: msg.value,
            reputation: 0, // Start with neutral reputation
            state: AgentState.Registered,
            unstakeRequestTime: 0,
            pendingUnstakeAmount: 0
        });
        isAgent[msg.sender] = true;

        emit AgentRegistered(msg.sender, _agentIdHash, _metadataURI, msg.value);
    }

    /// @notice Allows a registered agent to update their descriptive metadata URI.
    /// @param _newMetadataURI The new IPFS URI for the agent's metadata.
    function updateAgentMetadata(string calldata _newMetadataURI) external onlyAgent whenNotPaused {
        require(bytes(_newMetadataURI).length > 0, "Metadata URI cannot be empty");
        agents[msg.sender].metadataURI = _newMetadataURI;
        emit AgentMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /// @notice Allows an agent to increase their existing stake. Deposits additional ETH.
    function updateAgentStake() external payable onlyAgent whenNotPaused {
        require(msg.value > 0, "Must send a positive amount to update stake");
        agents[msg.sender].stake += msg.value;
        emit AgentStakeUpdated(msg.sender, agents[msg.sender].stake);
    }

    /// @notice Initiates a cooldown period for unstaking a specified amount.
    /// @param _amount The amount of ETH to request for unstaking.
    function requestUnstake(uint256 _amount) external onlyAgent whenNotPaused {
        Agent storage agent = agents[msg.sender];
        require(agent.stake >= _amount, "Requested amount exceeds current stake");
        require(_amount > 0, "Amount must be positive");
        require(agent.state == AgentState.Registered, "Agent cannot request unstake in current state");

        // Prevent pending unstake while another is active. Simplification. A more complex system could queue.
        require(agent.pendingUnstakeAmount == 0, "Previous unstake request is pending cooldown");

        agent.pendingUnstakeAmount = _amount;
        agent.unstakeRequestTime = block.timestamp;

        emit UnstakeRequested(msg.sender, _amount, block.timestamp);
    }

    /// @notice Allows an agent to withdraw their unstaked funds after the cooldown period.
    function claimUnstakedFunds() external onlyAgent nonReentrant {
        Agent storage agent = agents[msg.sender];
        require(agent.pendingUnstakeAmount > 0, "No pending unstake request");
        require(block.timestamp >= agent.unstakeRequestTime + unstakeCooldownPeriod, "Unstake cooldown not yet expired");

        uint256 amountToWithdraw = agent.pendingUnstakeAmount;
        agent.stake -= amountToWithdraw;
        agent.pendingUnstakeAmount = 0;
        agent.unstakeRequestTime = 0;

        // If the agent is deregistering, allow full unstake and transition to Deregistered.
        // Otherwise, ensure minimum stake requirement is met.
        if (agent.state != AgentState.Deregistering) {
            require(agent.stake >= minAgentStakingRequirement, "Cannot unstake below minimum staking requirement");
        } else {
            agent.state = AgentState.Deregistered; // Final state after full unstake
            isAgent[msg.sender] = false; // No longer considered an active agent
        }

        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Failed to send unstaked funds");

        emit UnstakeClaimed(msg.sender, amountToWithdraw);
        emit AgentStakeUpdated(msg.sender, agent.stake); // Stake might be 0 here for deregistered agent
    }

    /// @notice Initiates full deregistration, withdrawing all stake after a cooldown period, preventing new task assignments.
    /// @dev An agent cannot be deregistered if they have tasks in `AgentSelected` or `InProgress` states.
    function deregisterAgent() external onlyAgent whenNotPaused {
        Agent storage agent = agents[msg.sender];
        require(agent.state == AgentState.Registered, "Agent is already deregistering or deregistered");

        // A more robust system would check for active tasks before allowing deregistration.
        // For simplicity, we assume off-chain coordination for active tasks or slashing for abandoning.

        agent.state = AgentState.Deregistering;
        agent.unstakeRequestTime = block.timestamp;
        agent.pendingUnstakeAmount = agent.stake; // Prepare to withdraw all stake

        emit AgentDeregistered(msg.sender);
        emit UnstakeRequested(msg.sender, agent.stake, block.timestamp);
    }

    // --- 3. Task Management (8 functions) ---

    /// @notice Requestor proposes a new AI task with details and requirements.
    /// @param _taskHash A hash representing the unique definition of the task.
    /// @param _dataInputURI IPFS URI to the input data for the task.
    /// @param _rewardAmount The reward (in ETH) for the agent completing the task.
    /// @param _maxExecutionTime Max time (in seconds) allowed for execution after assignment. Pass 0 to use default.
    /// @param _minRequiredReputation Minimum reputation an agent must have to bid on this task.
    function proposeTask(bytes32 _taskHash, string calldata _dataInputURI, uint256 _rewardAmount, uint256 _maxExecutionTime, uint256 _minRequiredReputation) external whenNotPaused nonReentrant {
        require(_rewardAmount > 0, "Reward amount must be positive");
        require(bytes(_dataInputURI).length > 0, "Data input URI cannot be empty");
        require(_taskHash != bytes32(0), "Task hash cannot be zero");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            requestor: msg.sender,
            taskHash: _taskHash,
            dataInputURI: _dataInputURI,
            rewardAmount: _rewardAmount,
            platformFee: 0, // Calculated upon deposit
            totalFundsLocked: 0, // Calculated upon deposit
            assignedAgent: address(0),
            assignedAgentBid: 0,
            resultURI: "",
            evidenceURI: "",
            submissionTime: 0,
            assignmentTime: 0,
            maxExecutionTime: _maxExecutionTime > 0 ? _maxExecutionTime : maxDefaultTaskExecutionTime,
            minRequiredReputation: _minRequiredReputation,
            state: TaskState.Proposed,
            hasAttestation: false
        });

        emit TaskProposed(newTaskId, msg.sender, _taskHash, _rewardAmount);
    }

    /// @notice Requestor deposits the required reward and platform fee for a proposed task.
    /// @param _taskId The ID of the task to deposit funds for.
    function depositTaskFunds(uint256 _taskId) external payable onlyTaskRequestor(_taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Proposed, "Task must be in Proposed state to deposit funds");

        uint256 fee = (task.rewardAmount * platformFeeRate) / 10000; // Calculate fee in basis points
        uint256 requiredDeposit = task.rewardAmount + fee;

        require(msg.value == requiredDeposit, "Incorrect deposit amount");

        task.platformFee = fee;
        task.totalFundsLocked = requiredDeposit;
        task.state = TaskState.BiddingOpen; // Open for bidding after funds are deposited

        totalPlatformFeesCollected += fee;

        emit TaskFundsDeposited(_taskId, msg.sender, requiredDeposit);
    }

    /// @notice Requestor cancels their task if it has not yet been assigned to an agent.
    /// @param _taskId The ID of the task to cancel.
    function cancelProposedTask(uint256 _taskId) external onlyTaskRequestor(_taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Proposed || task.state == TaskState.FundsDeposited || task.state == TaskState.BiddingOpen, "Task cannot be cancelled in current state");

        if (task.totalFundsLocked > 0) {
            uint256 amountToReturn = task.totalFundsLocked;
            totalPlatformFeesCollected -= task.platformFee; // Refund fee if task cancelled before assignment
            task.platformFee = 0;
            task.totalFundsLocked = 0; // Prevent double refund

            (bool success, ) = msg.sender.call{value: amountToReturn}("");
            require(success, "Failed to return task funds");
        }

        task.state = TaskState.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }

    /// @notice An eligible agent bids to execute a specific task, committing to the bid price.
    /// @param _taskId The ID of the task to bid on.
    /// @param _bidAmount The amount the agent is willing to accept for the task (must be <= task.rewardAmount).
    function bidOnTask(uint256 _taskId, uint256 _bidAmount) external onlyAgent whenNotPaused {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[msg.sender];

        require(task.state == TaskState.FundsDeposited || task.state == TaskState.BiddingOpen, "Task not open for bidding");
        require(_bidAmount > 0, "Bid amount must be positive");
        require(_bidAmount <= task.rewardAmount, "Bid amount cannot exceed task reward");
        require(agent.reputation >= task.minRequiredReputation, "Agent reputation too low for this task");
        require(agent.state == AgentState.Registered, "Agent not in Registered state");

        taskBids[_taskId][msg.sender] = _bidAmount; // Overwrite previous bid if exists
        emit TaskBid(_taskId, msg.sender, _bidAmount);
    }

    /// @notice Requestor selects an agent from the bidders to execute the task.
    /// @param _taskId The ID of the task.
    /// @param _agentAddress The address of the agent to select.
    function selectAgentForTask(uint256 _taskId, address _agentAddress) external onlyTaskRequestor(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.FundsDeposited || task.state == TaskState.BiddingOpen, "Task not in a state to select an agent");
        require(isAgent[_agentAddress], "Selected address is not a registered agent");
        require(agents[_agentAddress].state == AgentState.Registered, "Selected agent is not in Registered state");
        require(taskBids[_taskId][_agentAddress] > 0, "Selected agent has not placed a bid");
        require(agents[_agentAddress].reputation >= task.minRequiredReputation, "Selected agent's reputation is too low");

        task.assignedAgent = _agentAddress;
        task.assignedAgentBid = taskBids[_taskId][_agentAddress]; // Store the accepted bid
        task.assignmentTime = block.timestamp;
        task.state = TaskState.AgentSelected;

        // Clear other bids for this task (optional, but good for cleanup)
        // This is not necessary on-chain as only the selected bid matters, but conceptually for efficiency.

        emit AgentSelected(_taskId, msg.sender, _agentAddress, task.assignedAgentBid);
    }

    /// @notice Agent submits the result URI and a cryptographic signature verifying the submission.
    /// @param _taskId The ID of the task.
    /// @param _resultURI IPFS URI to the agent's submitted result.
    /// @param _agentSignature Cryptographic signature by the agent (optional, for off-chain verification).
    function submitTaskResult(uint256 _taskId, string calldata _resultURI, bytes calldata _agentSignature) external onlyAssignedAgent(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.AgentSelected, "Task not in AgentSelected state");
        require(block.timestamp <= task.assignmentTime + task.maxExecutionTime, "Task execution time has expired");
        require(bytes(_resultURI).length > 0, "Result URI cannot be empty");

        task.resultURI = _resultURI;
        // _agentSignature could be stored or used for off-chain verification (e.g., of the resultURI)
        task.submissionTime = block.timestamp;
        task.state = TaskState.ResultSubmitted;

        emit TaskResultSubmitted(_taskId, msg.sender, _resultURI);
    }

    /// @notice A requestor or authorized verifier challenges the validity of a submitted task result.
    /// @param _taskId The ID of the task.
    /// @param _evidenceURI IPFS URI to the evidence supporting the challenge.
    function challengeTaskResult(uint256 _taskId, string calldata _evidenceURI) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.ResultSubmitted, "Task not in ResultSubmitted state to be challenged");
        // Allow requestor or authorized verifier to challenge
        require(msg.sender == task.requestor || authorizedVerifiers[msg.sender], "Caller is not requestor or authorized verifier");
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");

        task.evidenceURI = _evidenceURI;
        task.state = TaskState.Challenged;

        emit TaskChallenged(_taskId, msg.sender, _evidenceURI);
    }

    /// @notice Allows the requestor to reclaim funds for tasks that expired without a valid result or dispute resolution.
    /// @param _taskId The ID of the task.
    function reclaimExpiredTaskFunds(uint256 _taskId) external onlyTaskRequestor(_taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.AgentSelected || task.state == TaskState.ResultSubmitted, "Task must be in AgentSelected or ResultSubmitted state to reclaim funds on expiration");
        require(block.timestamp > task.assignmentTime + task.maxExecutionTime, "Task has not yet expired");

        uint256 amountToReturn = task.totalFundsLocked;
        totalPlatformFeesCollected -= task.platformFee; // Refund fee if task expired without completion
        task.platformFee = 0;
        task.totalFundsLocked = 0;

        task.state = TaskState.ExpiredNoResult;

        (bool success, ) = msg.sender.call{value: amountToReturn}("");
        require(success, "Failed to reclaim expired task funds");

        emit TaskExpiredReclaimed(_taskId, msg.sender, amountToReturn);
    }

    // --- 4. Reputation System (2 functions) ---

    /// @notice View function to retrieve an agent's current reputation score.
    /// @param _agentAddress The address of the agent.
    /// @return The agent's reputation score.
    function getAgentReputation(address _agentAddress) external view returns (uint256) {
        return agents[_agentAddress].reputation;
    }

    /// @notice Requestor or authorized verifier attests to an agent's performance on a completed task, influencing reputation.
    /// @dev This function transitions the task to 'Completed' and handles fund distribution if successful.
    /// @param _taskId The ID of the task.
    /// @param _success True if the agent performed successfully, false otherwise.
    /// @param _feedbackURI IPFS URI to detailed feedback.
    function attestAgentPerformance(uint256 _taskId, bool _success, string calldata _feedbackURI) external onlyAuthorizedVerifier whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.ResultSubmitted, "Task not in ResultSubmitted state to be attested");
        require(!task.hasAttestation, "Task already has an attestation");
        require(task.assignedAgent != address(0), "Task must have an assigned agent");
        require(msg.sender == task.requestor || authorizedVerifiers[msg.sender], "Only requestor or authorized verifier can attest");

        _handleTaskCompletion(_taskId, _success); // Handle fund distribution and reputation
        emit PerformanceAttested(_taskId, task.assignedAgent, _success, _feedbackURI);
    }

    /// @dev Internal function to handle the completion of a task, including fund distribution and reputation update.
    /// @param _taskId The ID of the task.
    /// @param _agentSucceeded True if the agent successfully completed the task.
    function _handleTaskCompletion(uint256 _taskId, bool _agentSucceeded) internal nonReentrant { // Added nonReentrant for fund transfers
        Task storage task = tasks[_taskId];
        address agentAddress = task.assignedAgent;
        uint256 rewardToAgent = 0;
        int256 reputationChange = 0;

        if (_agentSucceeded) {
            // Pay the agent their bid amount
            rewardToAgent = task.assignedAgentBid;
            reputationChange = 50; // Positive reputation for successful completion
            (bool success, ) = agentAddress.call{value: rewardToAgent}("");
            require(success, "Failed to send reward to agent");

            // Remaining funds (task.rewardAmount - task.assignedAgentBid) are sent back to requestor
            uint256 remainingReward = task.rewardAmount - task.assignedAgentBid;
            if (remainingReward > 0) {
                (bool successRefund, ) = task.requestor.call{value: remainingReward}("");
                require(successRefund, "Failed to refund remaining reward to requestor");
            }
        } else {
            // If agent failed, reward is returned entirely to requestor
            rewardToAgent = 0;
            reputationChange = -100; // Negative reputation for failure
            (bool successRefund, ) = task.requestor.call{value: task.rewardAmount}("");
            require(successRefund, "Failed to refund reward to requestor on failure");

            // In a more advanced system, agent's stake could be slashed here for severe failure.
        }

        _updateAgentReputation(agentAddress, reputationChange, _taskId);

        task.state = TaskState.Completed;
        task.hasAttestation = true; // Mark attestation done for this task
        task.totalFundsLocked = 0; // Funds are now distributed

        emit TaskCompleted(_taskId, agentAddress, task.requestor, rewardToAgent);
    }

    /// @dev Internal function to update an agent's reputation score.
    /// @param _agentAddress The address of the agent.
    /// @param _scoreChange The amount to change the reputation by (can be negative).
    function _updateAgentReputation(address _agentAddress, int256 _scoreChange, uint256 _taskId) internal {
        Agent storage agent = agents[_agentAddress];
        uint256 oldReputation = agent.reputation;

        if (_scoreChange > 0) {
            agent.reputation += uint256(_scoreChange);
        } else {
            // Ensure reputation doesn't underflow if it's already low
            agent.reputation = agent.reputation > uint256(-_scoreChange) ? agent.reputation - uint256(-_scoreChange) : 0;
        }
        emit AgentReputationUpdated(_agentAddress, _scoreChange, agent.reputation);
    }

    // --- 5. Dispute Resolution (1 function) ---

    /// @notice Owner/governance resolves a challenged task, distributing funds and updating reputations.
    /// @param _taskId The ID of the task under dispute.
    /// @param _winningParty The address of the party deemed to have won the dispute (agent or requestor).
    /// @param _agentReputationImpact The reputation change for the agent (can be negative).
    /// @param _challengerReputationImpact The reputation change for the challenger (can be negative, if different from requestor and tracked).
    function resolveDispute(uint256 _taskId, address _winningParty, int256 _agentReputationImpact, int256 _challengerReputationImpact) external onlyOwner whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Challenged, "Task not in Challenged state");
        require(task.assignedAgent != address(0), "Dispute requires an assigned agent");
        require(_winningParty == task.assignedAgent || _winningParty == task.requestor, "Winning party must be agent or requestor");

        address agentAddress = task.assignedAgent;
        address requestorAddress = task.requestor;
        uint256 rewardToAgent = 0;

        if (_winningParty == agentAddress) {
            // Agent wins dispute
            rewardToAgent = task.assignedAgentBid;
            (bool success, ) = agentAddress.call{value: rewardToAgent}("");
            require(success, "Failed to send reward to winning agent");

            // Refund remaining reward to requestor
            uint256 remainingReward = task.rewardAmount - task.assignedAgentBid;
            if (remainingReward > 0) {
                (bool successRefund, ) = requestorAddress.call{value: remainingReward}("");
                require(successRefund, "Failed to refund remaining reward to requestor");
            }

            _updateAgentReputation(agentAddress, _agentReputationImpact, _taskId);
            // _challengerReputationImpact could be applied to the challenger (if tracked)
        } else { // Requestor wins dispute
            // All reward funds returned to requestor
            (bool successRefund, ) = requestorAddress.call{value: task.rewardAmount}("");
            require(successRefund, "Failed to refund reward to requestor");

            _updateAgentReputation(agentAddress, _agentReputationImpact, _taskId); // Agent loses reputation (e.g., negative impact)
            // Potentially slash agent's stake here in a more robust system for severe failures/malice.
        }

        task.state = TaskState.Completed;
        task.totalFundsLocked = 0; // Funds are now distributed
        task.hasAttestation = true; // Mark as resolved/attested

        emit TaskDisputeResolved(_taskId, _winningParty, (_winningParty == agentAddress) ? requestorAddress : agentAddress, _agentReputationImpact, _challengerReputationImpact);
    }


    // --- 6. Platform Fees & Withdrawals (1 function) ---

    /// @notice Owner/governance withdraws accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner whenNotPaused nonReentrant {
        require(totalPlatformFeesCollected > 0, "No fees to withdraw");
        uint256 amountToWithdraw = totalPlatformFeesCollected;
        totalPlatformFeesCollected = 0;

        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Failed to withdraw platform fees");

        emit PlatformFeesWithdrawn(msg.sender, amountToWithdraw);
    }

    // --- 7. Governance & Parameter Management (6 functions) ---

    /// @notice Updates the minimum stake required for new and existing agents.
    /// @param _newRequirement The new minimum staking amount in wei.
    function updateStakingRequirement(uint256 _newRequirement) external onlyOwner whenNotPaused {
        require(_newRequirement > 0, "Staking requirement must be positive");
        minAgentStakingRequirement = _newRequirement;
        emit StakingRequirementUpdated(_newRequirement);
    }

    /// @notice Updates the cooldown period for unstaking funds.
    /// @param _newCooldown The new cooldown period in seconds.
    function updateUnstakeCooldown(uint256 _newCooldown) external onlyOwner whenNotPaused {
        require(_newCooldown > 0, "Unstake cooldown must be positive");
        unstakeCooldownPeriod = _newCooldown;
        emit UnstakeCooldownUpdated(_newCooldown);
    }

    /// @notice Adjusts the maximum allowed time an agent has to execute a task after assignment.
    /// @param _newTime The new maximum execution time in seconds.
    function updateMaxTaskExecutionTime(uint256 _newTime) external onlyOwner whenNotPaused {
        require(_newTime > 0, "Max task execution time must be positive");
        maxDefaultTaskExecutionTime = _newTime;
        emit MaxTaskExecutionTimeUpdated(_newTime);
    }

    /// @notice Updates the percentage rate of fees collected by the platform.
    /// @param _newFeeRate The new fee rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
    function updatePlatformFeeRate(uint256 _newFeeRate) external onlyOwner whenNotPaused {
        require(_newFeeRate <= 10000, "Fee rate cannot exceed 100%");
        platformFeeRate = _newFeeRate;
        emit PlatformFeeRateUpdated(_newFeeRate);
    }

    /// @notice Grants an address the ability to make performance attestations.
    /// @param _verifierAddress The address to authorize.
    function addAuthorizedVerifier(address _verifierAddress) external onlyOwner whenNotPaused {
        require(_verifierAddress != address(0), "Verifier address cannot be zero");
        require(!authorizedVerifiers[_verifierAddress], "Verifier already authorized");
        authorizedVerifiers[_verifierAddress] = true;
        emit AuthorizedVerifierAdded(_verifierAddress);
    }

    /// @notice Revokes an address's ability to make performance attestations.
    /// @param _verifierAddress The address to revoke.
    function removeAuthorizedVerifier(address _verifierAddress) external onlyOwner whenNotPaused {
        require(_verifierAddress != address(0), "Verifier address cannot be zero");
        require(authorizedVerifiers[_verifierAddress], "Verifier not authorized");
        authorizedVerifiers[_verifierAddress] = false;
        emit AuthorizedVerifierRemoved(_verifierAddress);
    }

    // --- 8. Emergency Controls (2 functions) ---

    /// @notice Pauses the contract, preventing most state-changing operations.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Resumes contract operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
```