Here's a Solidity smart contract for a "QuantumForge AI Collective," designed with advanced, creative, and trendy concepts, ensuring a unique implementation beyond typical open-source projects.

This contract establishes a decentralized ecosystem for Artificial Intelligence agents (referred to as "Quantum Agents"). These agents, represented on-chain by their unique IDs and metadata, can register, stake collateral, claim and execute tasks, and earn reputation and rewards based on their performance. The system incorporates an oracle for result verification, a dynamic reputation system, and a flexible DAO governance model for adaptive parameter tuning and dispute resolution.

---

## QuantumForge AI Collective

**Contract Name:** `QuantumForgeAICollective`

**Concept Overview:**
The `QuantumForgeAICollective` is a decentralized autonomous organization (DAO) that facilitates the deployment, management, and incentivization of off-chain AI models, termed "Quantum Agents." Users can propose tasks, and registered Quantum Agents can claim and execute these tasks. An oracle network (or a trusted single oracle in this simplified version) verifies the results, impacting the agent's on-chain reputation and distributing rewards. The entire system's parameters are adjustable via a flexible governance mechanism.

**Key Advanced Concepts:**
1.  **Decentralized AI Agents:** On-chain representation and lifecycle management for off-chain AI models, fostering a competitive and collaborative AI ecosystem.
2.  **Reputation System:** Agents earn or lose reputation based on verified task performance, influencing their standing and potential for future task claims.
3.  **Task Market with Collateral:** Proposers stake rewards, and agents stake collateral, aligning incentives and ensuring accountability.
4.  **Adaptive Governance:** A flexible DAO mechanism allows the community to propose and vote on changes to core protocol parameters (e.g., minimum stake, fees, reputation multipliers), enabling the protocol to evolve.
5.  **Dynamic Metadata:** Agents can update their `metadataURI` (pointing to new model versions or off-chain data), allowing for "evolution" or "upgrades" of their underlying AI.
6.  **Dispute Resolution Mechanism:** A structured process for challenging and resolving task outcomes, critical for a trustless environment.

---

### Outline & Function Summary:

**I. Core Management & Setup**
    *   `constructor()`: Initializes the contract, setting the deployer as the initial owner and a placeholder for the oracle.
    *   `setOracleAddress(address _newOracle)`: Allows the DAO to designate a new trusted oracle address.
    *   `updateMinAgentStake(uint256 _newMinStake)`: Updates the minimum ETH an agent must stake to register or maintain activity.
    *   `updateTaskFee(uint256 _newTaskFee)`: Adjusts the fee percentage charged on task rewards, contributing to the collective treasury.
    *   `updateReputationMultiplier(uint256 _newMultiplier)`: Changes the scalar applied to reputation changes after task verification.
    *   `withdrawTreasuryFunds(address _to, uint256 _amount)`: Allows the DAO to withdraw accumulated fees from the contract's treasury.

**II. Agent Lifecycle Management**
    *   `registerAgent(string calldata _metadataURI)`: Registers a new Quantum Agent, requiring `minAgentStake` as initial collateral.
    *   `stakeAgent(uint256 _agentId)`: Allows an agent owner to add more ETH to their agent's collateral stake.
    *   `requestUnstake(uint256 _agentId, uint256 _amount)`: Initiates a cooldown period for withdrawing staked funds.
    *   `finalizeUnstake(uint256 _agentId)`: Completes the unstaking process after the cooldown, releasing funds to the agent owner.
    *   `updateAgentMetadata(uint256 _agentId, string calldata _newMetadataURI)`: Allows an agent owner to update the URI pointing to their agent's off-chain AI model/details.
    *   `getAgentDetails(uint256 _agentId)`: Retrieves detailed information about a specific Quantum Agent.
    *   `deregisterAgent(uint256 _agentId)`: Marks an agent as inactive, preventing it from claiming new tasks, typically initiated by governance or the owner after unstaking all funds.

**III. Task Management & Execution**
    *   `proposeTask(string calldata _inputDataURI, uint256 _reward, uint256 _deadline)`: A user proposes a new task, locking the specified reward amount in the contract.
    *   `claimTask(uint256 _taskId, uint256 _agentId)`: A registered and active Quantum Agent claims an available task.
    *   `submitTaskResult(uint256 _taskId, uint256 _agentId, string calldata _outputDataURI, bytes32 _resultHash)`: The claimed agent submits the off-chain result URI and a hash of the result for verification.
    *   `verifyTaskResult(uint256 _taskId, bool _successful)`: The trusted oracle verifies the submitted task result, updating agent reputation and distributing rewards.
    *   `challengeTaskResult(uint256 _taskId, string calldata _reason)`: A user or another agent can challenge a submitted result before verification, initiating a dispute.
    *   `resolveTaskDispute(uint256 _taskId, bool _proposerWins, bool _agentWins)`: The DAO (or oracle) resolves a challenged task, determining who wins the dispute and affecting reputation/funds.
    *   `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.

**IV. Reward & Reputation**
    *   `claimAgentRewards(uint256 _agentId)`: Allows an agent owner to claim accumulated ETH rewards from successfully completed tasks.

**V. Governance (Simplified for Brevity)**
    *   `submitProposal(string calldata _description, bytes calldata _callData, address _target)`: Allows a minimum-staked agent owner to propose a governance action (e.g., parameter change, oracle update).
    *   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows agent owners to vote on active proposals (simple 1-token-1-vote model for simplicity).
    *   `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumForgeAICollective
/// @author YourName (or an anonymous collective)
/// @notice A decentralized ecosystem for AI agents (Quantum Agents) to register, stake, claim tasks, execute them, and earn reputation and rewards.
/// @dev This contract implements agent lifecycle management, a task marketplace, reputation system, and a basic DAO governance.
///      Off-chain AI models are represented by metadata URIs. Verification is handled by a trusted oracle.

contract QuantumForgeAICollective {

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI, uint256 stake);
    event AgentStaked(uint256 indexed agentId, uint256 amount);
    event UnstakeRequested(uint256 indexed agentId, uint256 amount, uint256 unlockTime);
    event UnstakeFinalized(uint256 indexed agentId, uint256 amount);
    event AgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI);
    event AgentDeregistered(uint256 indexed agentId);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, string inputDataURI, uint256 reward, uint256 deadline);
    event TaskClaimed(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, string outputDataURI, bytes32 resultHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool successful, int256 reputationChange);
    event TaskChallenged(uint256 indexed taskId, address indexed challenger, string reason);
    event TaskDisputeResolved(uint256 indexed taskId, bool proposerWins, bool agentWins);

    event RewardsClaimed(uint256 indexed agentId, address indexed owner, uint256 amount);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    event OracleAddressUpdated(address indexed newOracle);
    event MinAgentStakeUpdated(uint256 newMinStake);
    event TaskFeeUpdated(uint256 newTaskFee);
    event ReputationMultiplierUpdated(uint256 newMultiplier);
    event TreasuryFundsWithdrawn(address indexed to, uint256 amount);

    // --- Errors ---
    error AgentNotFound(uint256 agentId);
    error NotAgentOwner(uint256 agentId);
    error InsufficientStake();
    error AgentInactive(uint256 agentId);
    error StakeLocked(uint256 agentId);
    error UnstakeCooldownNotPassed(uint256 agentId);
    error NoUnstakeRequestPending();

    error TaskNotFound(uint256 taskId);
    error TaskNotOpen(uint256 taskId);
    error TaskAlreadyClaimed(uint256 taskId);
    error TaskAlreadySubmitted(uint256 taskId);
    error TaskDeadlinePassed(uint256 taskId);
    error TaskNotClaimedByAgent(uint256 taskId, uint256 agentId);
    error TaskNotSubmitted(uint256 taskId);
    error TaskAlreadyVerified(uint256 taskId);
    error TaskAlreadyChallenged(uint256 taskId);
    error TaskNotChallenged(uint256 taskId);

    error NotOracle();
    error NotGovernor(); // For DAO-like functions, initially owner, later can be a token-governed system.
    error NotProposer();
    error UnauthorizedAction();

    error ProposalNotFound(uint256 proposalId);
    error ProposalAlreadyVoted();
    error ProposalNotYetExecutable();
    error ProposalAlreadyExecuted();
    error ProposalFailed();
    error InsufficientVotingPower();

    // --- Enums ---
    enum AgentStatus { Active, Inactive, Deregistered }
    enum TaskStatus { Proposed, Claimed, ResultSubmitted, Verified, Challenged, Resolved }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct Agent {
        address owner;
        string metadataURI; // IPFS hash or URL to the AI model's description/code/API
        uint256 stake; // Collateral staked by the agent
        int256 reputation; // Agent's performance reputation
        AgentStatus status;
        uint256 rewardsAccumulated; // ETH accumulated from successful tasks
        // For unstaking cooldown
        uint256 unstakeAmountPending;
        uint256 unstakeUnlockTime;
    }

    struct Task {
        address proposer;
        uint256 agentId; // 0 if not claimed
        string inputDataURI; // IPFS hash or URL for task input data
        string outputDataURI; // IPFS hash or URL for agent's submitted output data
        bytes32 resultHash; // Hash of the result submitted by the agent
        uint256 reward; // Reward for successful completion
        uint256 deadline; // Timestamp by which the task must be completed/verified
        TaskStatus status;
        address challenger; // Address of the challenging party if any
        string challengeReason;
    }

    struct Proposal {
        string description;
        bytes callData; // Encoded function call for the action (e.g., setMinStake)
        address target; // Target contract for the call (this contract or another)
        uint256 voteCountSupport;
        uint256 voteCountOppose;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalState state;
        uint256 quorumThreshold; // Minimum total stake required to vote
        uint256 votingDeadline;
    }

    // --- State Variables ---
    address public owner; // Initial deployer, can be transferred or become part of DAO
    address public trustedOracle; // Address of the oracle service

    uint256 public nextAgentId;
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256) public agentOwnerToId; // For quick lookup of agent by owner (if owner has only one agent)

    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Protocol parameters, adjustable via governance
    uint256 public minAgentStake; // Minimum ETH required to register an agent
    uint256 public taskFeePercentage; // Percentage of task reward taken as fee (e.g., 500 for 5%)
    uint256 public reputationMultiplier; // Multiplier for reputation changes
    uint256 public unstakeCooldownPeriod; // Time in seconds for unstaking cooldown
    uint256 public proposalVotingPeriod; // Time in seconds for proposals to be open for voting
    uint256 public minStakeForProposal; // Minimum stake an agent needs to submit a proposal
    uint256 public minStakeForVoting; // Minimum stake an agent needs to vote

    uint256 public totalTreasuryFunds; // Accumulated fees

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert UnauthorizedAction();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != trustedOracle) revert NotOracle();
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        if (agents[_agentId].owner != msg.sender) revert NotAgentOwner(_agentId);
        _;
    }

    modifier onlyActiveAgent(uint256 _agentId) {
        if (agents[_agentId].status != AgentStatus.Active) revert AgentInactive(_agentId);
        _;
    }

    modifier onlyGovernor() {
        // In a full DAO, this would check if msg.sender has voting power
        // For now, it's simplified to owner or could be extended to a specific governance contract
        if (msg.sender != owner) revert NotGovernor();
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        trustedOracle = msg.sender; // Deployer is initial oracle, should be changed by governance
        nextAgentId = 1;
        nextTaskId = 1;
        nextProposalId = 1;

        minAgentStake = 1 ether; // Example: 1 ETH
        taskFeePercentage = 500; // Example: 5% (500 basis points)
        reputationMultiplier = 1; // Base multiplier for reputation points
        unstakeCooldownPeriod = 7 days; // Example: 7 days
        proposalVotingPeriod = 3 days; // Example: 3 days
        minStakeForProposal = 5 ether; // Example: 5 ETH
        minStakeForVoting = 1 ether; // Example: 1 ETH
    }

    // --- I. Core Management & Setup ---

    /// @notice Sets the address of the trusted oracle. This should ideally be a DAO-controlled function.
    /// @dev Only callable by the current governor (owner initially, then DAO).
    /// @param _newOracle The address of the new oracle.
    function setOracleAddress(address _newOracle) external onlyGovernor {
        trustedOracle = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /// @notice Updates the minimum ETH required to register and maintain an active agent.
    /// @dev Only callable by the current governor (owner initially, then DAO).
    /// @param _newMinStake The new minimum stake amount.
    function updateMinAgentStake(uint256 _newMinStake) external onlyGovernor {
        minAgentStake = _newMinStake;
        emit MinAgentStakeUpdated(_newMinStake);
    }

    /// @notice Adjusts the percentage of task rewards taken as a fee, which goes to the collective treasury.
    /// @dev Only callable by the current governor (owner initially, then DAO).
    /// @param _newTaskFee The new fee percentage (e.g., 500 for 5%).
    function updateTaskFee(uint256 _newTaskFee) external onlyGovernor {
        if (_newTaskFee > 10000) revert UnauthorizedAction(); // Max 100%
        taskFeePercentage = _newTaskFee;
        emit TaskFeeUpdated(_newTaskFee);
    }

    /// @notice Updates the multiplier used when calculating reputation changes for agents.
    /// @dev Only callable by the current governor (owner initially, then DAO).
    /// @param _newMultiplier The new reputation multiplier.
    function updateReputationMultiplier(uint256 _newMultiplier) external onlyGovernor {
        reputationMultiplier = _newMultiplier;
        emit ReputationMultiplierUpdated(_newMultiplier);
    }

    /// @notice Allows the governor to withdraw accumulated fees from the contract's treasury.
    /// @dev Only callable by the current governor (owner initially, then DAO).
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawTreasuryFunds(address _to, uint256 _amount) external onlyGovernor {
        if (_amount == 0 || _amount > totalTreasuryFunds) revert InsufficientStake(); // Reusing error
        totalTreasuryFunds -= _amount;
        payable(_to).transfer(_amount);
        emit TreasuryFundsWithdrawn(_to, _amount);
    }

    // --- II. Agent Lifecycle Management ---

    /// @notice Registers a new Quantum Agent. Requires `minAgentStake` to be sent with the transaction.
    /// @dev The `metadataURI` should point to off-chain data describing the AI model.
    /// @param _metadataURI The URI for the agent's off-chain AI model description.
    /// @return The ID of the newly registered agent.
    function registerAgent(string calldata _metadataURI) external payable returns (uint256) {
        if (msg.value < minAgentStake) revert InsufficientStake();
        if (agentOwnerToId[msg.sender] != 0) revert UnauthorizedAction(); // Owner can only have one agent for now.

        uint256 agentId = nextAgentId++;
        agents[agentId] = Agent({
            owner: msg.sender,
            metadataURI: _metadataURI,
            stake: msg.value,
            reputation: 0,
            status: AgentStatus.Active,
            rewardsAccumulated: 0,
            unstakeAmountPending: 0,
            unstakeUnlockTime: 0
        });
        agentOwnerToId[msg.sender] = agentId; // Map owner to agent ID
        emit AgentRegistered(agentId, msg.sender, _metadataURI, msg.value);
        return agentId;
    }

    /// @notice Allows an agent owner to add more stake to their agent's collateral.
    /// @param _agentId The ID of the agent to stake more funds for.
    function stakeAgent(uint256 _agentId) external payable onlyAgentOwner(_agentId) {
        if (msg.value == 0) revert InsufficientStake();
        agents[_agentId].stake += msg.value;
        emit AgentStaked(_agentId, msg.value);
    }

    /// @notice Initiates a request to unstake a portion of an agent's collateral.
    /// @dev A cooldown period must pass before `finalizeUnstake` can be called.
    /// @param _agentId The ID of the agent to unstake from.
    /// @param _amount The amount to request for unstaking.
    function requestUnstake(uint256 _agentId, uint256 _amount) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.stake < minAgentStake + _amount) revert InsufficientStake(); // Must maintain min stake
        if (agent.unstakeAmountPending > 0) revert StakeLocked(_agentId); // Only one request at a time

        agent.unstakeAmountPending = _amount;
        agent.unstakeUnlockTime = block.timestamp + unstakeCooldownPeriod;
        emit UnstakeRequested(_agentId, _amount, agent.unstakeUnlockTime);
    }

    /// @notice Finalizes an unstaking request after the cooldown period has passed.
    /// @param _agentId The ID of the agent to finalize unstaking for.
    function finalizeUnstake(uint256 _agentId) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.unstakeAmountPending == 0) revert NoUnstakeRequestPending();
        if (block.timestamp < agent.unstakeUnlockTime) revert UnstakeCooldownNotPassed(_agentId);

        uint256 amountToTransfer = agent.unstakeAmountPending;
        agent.stake -= amountToTransfer;
        agent.unstakeAmountPending = 0;
        agent.unstakeUnlockTime = 0;

        payable(agent.owner).transfer(amountToTransfer);
        emit UnstakeFinalized(_agentId, amountToTransfer);
    }

    /// @notice Allows an agent owner to update the `metadataURI` for their agent.
    /// @dev This can represent an upgrade or "evolution" of the underlying AI model.
    /// @param _agentId The ID of the agent to update.
    /// @param _newMetadataURI The new URI pointing to the updated AI model description.
    function updateAgentMetadata(uint256 _agentId, string calldata _newMetadataURI) external onlyAgentOwner(_agentId) {
        agents[_agentId].metadataURI = _newMetadataURI;
        emit AgentMetadataUpdated(_agentId, _newMetadataURI);
    }

    /// @notice Retrieves detailed information about a specific Quantum Agent.
    /// @param _agentId The ID of the agent.
    /// @return A tuple containing agent details.
    function getAgentDetails(uint256 _agentId)
        external
        view
        returns (
            address owner_,
            string memory metadataURI_,
            uint256 stake_,
            int256 reputation_,
            AgentStatus status_,
            uint256 rewardsAccumulated_,
            uint256 unstakeAmountPending_,
            uint256 unstakeUnlockTime_
        )
    {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        return (
            agent.owner,
            agent.metadataURI,
            agent.stake,
            agent.reputation,
            agent.status,
            agent.rewardsAccumulated,
            agent.unstakeAmountPending,
            agent.unstakeUnlockTime
        );
    }

    /// @notice Marks an agent as `Deregistered`. It can no longer claim tasks.
    /// @dev Requires all stake to be unstaked. Can be called by owner or governance.
    /// @param _agentId The ID of the agent to deregister.
    function deregisterAgent(uint256 _agentId) external {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        // Only owner if no pending stake
        if (msg.sender == agent.owner) {
            if (agent.stake > 0 || agent.unstakeAmountPending > 0) revert StakeLocked(_agentId);
        } else if (msg.sender != owner) { // Only owner (governance) can deregister with stake still present.
            revert UnauthorizedAction();
        }

        agent.status = AgentStatus.Deregistered;
        emit AgentDeregistered(_agentId);
    }


    // --- III. Task Management & Execution ---

    /// @notice Proposes a new task, locking the reward amount.
    /// @dev Requires the reward amount to be sent with the transaction.
    /// @param _inputDataURI URI for the task's input data.
    /// @param _reward The amount of ETH reward for successful completion.
    /// @param _deadline Timestamp by which the task must be completed and verified.
    /// @return The ID of the newly proposed task.
    function proposeTask(string calldata _inputDataURI, uint256 _reward, uint256 _deadline) external payable returns (uint256) {
        if (msg.value < _reward) revert InsufficientStake(); // Funds for reward
        if (_deadline <= block.timestamp) revert TaskDeadlinePassed(_nextTaskId);

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            proposer: msg.sender,
            agentId: 0, // Not claimed yet
            inputDataURI: _inputDataURI,
            outputDataURI: "",
            resultHash: bytes32(0),
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.Proposed,
            challenger: address(0),
            challengeReason: ""
        });
        emit TaskProposed(taskId, msg.sender, _inputDataURI, _reward, _deadline);
        return taskId;
    }

    /// @notice Allows an active Quantum Agent to claim an open task.
    /// @param _taskId The ID of the task to claim.
    /// @param _agentId The ID of the agent claiming the task.
    function claimTask(uint256 _taskId, uint256 _agentId) external onlyAgentOwner(_agentId) onlyActiveAgent(_agentId) {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.Proposed) revert TaskNotOpen(_taskId);
        if (block.timestamp >= task.deadline) revert TaskDeadlinePassed(_taskId);

        task.agentId = _agentId;
        task.status = TaskStatus.Claimed;
        emit TaskClaimed(_taskId, _agentId);
    }

    /// @notice An agent submits the results of a claimed task.
    /// @dev The `_outputDataURI` points to the off-chain result, and `_resultHash` is a cryptographic hash of it.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent submitting.
    /// @param _outputDataURI URI for the task's output data.
    /// @param _resultHash Hash of the output data for integrity verification.
    function submitTaskResult(uint256 _taskId, uint256 _agentId, string calldata _outputDataURI, bytes32 _resultHash)
        external
        onlyAgentOwner(_agentId)
    {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.Claimed) revert TaskNotClaimedByAgent(_taskId, _agentId); // Or TaskNotOpen
        if (task.agentId != _agentId) revert TaskNotClaimedByAgent(_taskId, _agentId);
        if (block.timestamp >= task.deadline) revert TaskDeadlinePassed(_taskId);

        task.outputDataURI = _outputDataURI;
        task.resultHash = _resultHash;
        task.status = TaskStatus.ResultSubmitted;
        emit TaskResultSubmitted(_taskId, _agentId, _outputDataURI, _resultHash);
    }

    /// @notice The trusted oracle verifies the submitted task result, updating reputation and distributing rewards.
    /// @dev Only callable by the `trustedOracle`.
    /// @param _taskId The ID of the task to verify.
    /// @param _successful True if the result is successful, false otherwise.
    function verifyTaskResult(uint256 _taskId, bool _successful) external onlyOracle {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.ResultSubmitted && task.status != TaskStatus.Challenged) revert TaskNotSubmitted(_taskId);
        if (task.agentId == 0) revert TaskNotClaimedByAgent(_taskId, 0); // Should be claimed and submitted

        Agent storage agent = agents[task.agentId];
        int256 reputationChange = _successful ? int256(1) : int256(-1);
        reputationChange *= int256(reputationMultiplier);

        agent.reputation += reputationChange;
        task.status = TaskStatus.Verified;

        if (_successful) {
            uint256 feeAmount = (task.reward * taskFeePercentage) / 10000;
            uint256 agentReward = task.reward - feeAmount;
            agent.rewardsAccumulated += agentReward;
            totalTreasuryFunds += feeAmount;
        } else {
            // Penalize agent stake or reward proposer if task failed
            // For simplicity, agent just loses reputation for now. Can implement more complex penalties.
        }

        emit TaskVerified(_taskId, task.agentId, _successful, reputationChange);
    }

    /// @notice Allows any user or agent to challenge a submitted task result before it's verified.
    /// @dev Initiates a dispute which must be resolved by governance/oracle.
    /// @param _taskId The ID of the task to challenge.
    /// @param _reason A description of why the result is being challenged.
    function challengeTaskResult(uint256 _taskId, string calldata _reason) external {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.ResultSubmitted) revert TaskNotSubmitted(_taskId);
        if (task.challenger != address(0)) revert TaskAlreadyChallenged(_taskId);

        task.challenger = msg.sender;
        task.challengeReason = _reason;
        task.status = TaskStatus.Challenged;
        emit TaskChallenged(_taskId, msg.sender, _reason);
    }

    /// @notice Resolves a challenged task, determining who wins the dispute.
    /// @dev Only callable by the current governor (owner initially, then DAO) or trusted oracle.
    /// @param _taskId The ID of the task in dispute.
    /// @param _proposerWins True if the task proposer wins the dispute.
    /// @param _agentWins True if the agent wins the dispute. (Note: These can be mutually exclusive, or both false for a draw/cancellation).
    function resolveTaskDispute(uint256 _taskId, bool _proposerWins, bool _agentWins) external onlyGovernor { // Can be `onlyOracle` too
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.Challenged) revert TaskNotChallenged(_taskId);

        Agent storage agent = agents[task.agentId];

        if (_agentWins) {
            // Agent wins, treat as successful verification
            int256 reputationChange = int256(1) * int256(reputationMultiplier);
            agent.reputation += reputationChange;
            uint256 feeAmount = (task.reward * taskFeePercentage) / 10000;
            uint256 agentReward = task.reward - feeAmount;
            agent.rewardsAccumulated += agentReward;
            totalTreasuryFunds += feeAmount;
        } else if (_proposerWins) {
            // Proposer wins, agent loses
            int256 reputationChange = int256(-1) * int256(reputationMultiplier);
            agent.reputation += reputationChange;
            // Optionally, penalize agent stake, or refund proposer.
            // For now, task reward funds stay in contract treasury.
            totalTreasuryFunds += task.reward; // Forfeit by agent/unclaimed
        } else {
            // Neither wins, possibly cancel task and refund proposer (or partially)
            // For simplicity, rewards go to treasury if neither wins.
            totalTreasuryFunds += task.reward;
        }
        task.status = TaskStatus.Resolved;
        emit TaskDisputeResolved(_taskId, _proposerWins, _agentWins);
    }

    /// @notice Retrieves detailed information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return A tuple containing task details.
    function getTaskDetails(uint256 _taskId)
        external
        view
        returns (
            address proposer_,
            uint256 agentId_,
            string memory inputDataURI_,
            string memory outputDataURI_,
            bytes32 resultHash_,
            uint256 reward_,
            uint256 deadline_,
            TaskStatus status_,
            address challenger_,
            string memory challengeReason_
        )
    {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) revert TaskNotFound(_taskId);
        return (
            task.proposer,
            task.agentId,
            task.inputDataURI,
            task.outputDataURI,
            task.resultHash,
            task.reward,
            task.deadline,
            task.status,
            task.challenger,
            task.challengeReason
        );
    }


    // --- IV. Reward & Reputation ---

    /// @notice Allows an agent owner to claim accumulated ETH rewards from successful tasks.
    /// @param _agentId The ID of the agent whose rewards are being claimed.
    function claimAgentRewards(uint256 _agentId) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        uint256 amount = agent.rewardsAccumulated;
        if (amount == 0) revert InsufficientStake(); // Reusing error
        agent.rewardsAccumulated = 0;
        payable(agent.owner).transfer(amount);
        emit RewardsClaimed(_agentId, agent.owner, amount);
    }

    // --- V. Governance (Simplified for Brevity) ---

    /// @notice Allows an agent owner with sufficient stake to propose a governance action.
    /// @dev Proposals consist of a description and an encoded function call to be executed if passed.
    /// @param _description A human-readable description of the proposal.
    /// @param _callData The ABI-encoded function call to be executed (e.g., `abi.encodeWithSelector(this.updateMinAgentStake.selector, 2 ether)`).
    /// @param _target The address of the contract to call (usually `this`).
    /// @return The ID of the new proposal.
    function submitProposal(string calldata _description, bytes calldata _callData, address _target) external returns (uint256) {
        uint256 agentId = agentOwnerToId[msg.sender];
        if (agentId == 0 || agents[agentId].stake < minStakeForProposal) revert InsufficientVotingPower();

        uint256 proposalId = nextProposalId++;
        proposals[proposalId].description = _description;
        proposals[proposalId].callData = _callData;
        proposals[proposalId].target = _target;
        proposals[proposalId].state = ProposalState.Pending;
        proposals[proposalId].votingDeadline = block.timestamp + proposalVotingPeriod;
        proposals[proposalId].quorumThreshold = 100 ether; // Example: requires a total of 100 ETH stake to be voted on
                                                         // In a real DAO, this would be dynamic or a percentage of total stake.

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    /// @notice Allows agent owners with sufficient stake to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes' vote, false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.description == "") revert ProposalNotFound(_proposalId); // Check if proposal exists
        if (proposal.state != ProposalState.Pending && proposal.state != ProposalState.Active) revert ProposalFailed(); // Or state not voteable
        if (block.timestamp > proposal.votingDeadline) revert ProposalFailed(); // Voting period ended

        uint256 agentId = agentOwnerToId[msg.sender];
        if (agentId == 0 || agents[agentId].stake < minStakeForVoting) revert InsufficientVotingPower();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        if (_support) {
            proposal.voteCountSupport += agents[agentId].stake; // Simple stake-weighted voting
        } else {
            proposal.voteCountOppose += agents[agentId].stake;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a successfully passed proposal.
    /// @dev Requires the voting period to have ended and the proposal to have passed its thresholds.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernor { // Can be any account once proposal passed
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.description == "") revert ProposalNotFound(_proposalId);
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.votingDeadline) revert ProposalNotYetExecutable();

        if (proposal.voteCountSupport > proposal.voteCountOppose &&
            (proposal.voteCountSupport + proposal.voteCountOppose) >= proposal.quorumThreshold) {
            // Proposal passed
            (bool success, ) = proposal.target.call(proposal.callData);
            if (!success) revert ProposalFailed();
            proposal.state = ProposalState.Executed;
        } else {
            proposal.state = ProposalState.Failed;
            revert ProposalFailed();
        }
        emit ProposalExecuted(_proposalId);
    }

    // Fallback function to receive Ether for the treasury (e.g., direct donations)
    receive() external payable {
        totalTreasuryFunds += msg.value;
    }
}
```