```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion in NFT URI

/**
 * @title Autonomous Adaptive Intelligence Network (AAIN)
 * @dev A decentralized platform for AI agents to register, propose computational tasks, and for the community
 *      to fund, verify, and dispute task outcomes. The network features an adaptive governance model
 *      where system parameters dynamically adjust based on historical performance and network activity.
 *      Agents are represented by dynamic NFT licenses that store their reputation.
 */
contract AAINetwork is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Outline ---
    // I. Core Management & Setup
    // II. Agent Management (ERC721 for Licenses)
    // III. Task Proposal & Funding
    // IV. Task Execution & Outcome Submission
    // V. Verification & Dispute System
    // VI. Adaptive Mechanism & Governance
    // VII. Token & NFT Interaction
    // VIII. Utility & Reporting

    // --- Function Summary ---

    // I. Core Management & Setup
    // 1. constructor(address _tokenAddress, string memory name, string memory symbol): Initializes the contract, sets the native token, and ERC721 details.
    // 2. updateSystemParameter(uint256 _paramId, uint256 _newValue): Owner function to update specific system parameters.
    // 3. pause(): Pauses the contract, preventing certain operations.
    // 4. unpause(): Unpauses the contract.
    // 5. emergencyWithdrawFunds(address _token, address _to, uint256 _amount): Owner can withdraw any ERC20 tokens in emergencies.

    // II. Agent Management (ERC721 for Licenses)
    // 6. registerAI_Agent(string memory _agentURI): Allows a new AI agent to register, staking tokens and minting a unique NFT license.
    // 7. deregisterAI_Agent(): Allows an agent to deregister, burning its NFT and reclaiming its stake (if no active tasks/disputes).
    // 8. updateAgentProfile(uint256 _agentId, string memory _newURI): Agent updates the metadata URI for its NFT license.
    // 9. getAgentPerformanceMetrics(uint256 _agentId): View function to retrieve an agent's performance statistics.
    // 10. freezeAgentAccount(uint256 _agentId, bool _freeze): Owner/governance can freeze/unfreeze an agent's participation.

    // III. Task Proposal & Funding
    // 11. proposeComputationalTask(string memory _taskDescriptionURI, bytes32 _inputHash, bytes32 _expectedOutputCriteriaHash, uint256 _rewardAmount): Agent proposes a new computational task.
    // 12. fundTaskProposal(uint256 _taskId, uint256 _amount): Users stake tokens to fund a proposed task's reward pool.
    // 13. getTaskDetails(uint256 _taskId): View function to retrieve all details of a specific task.
    // 14. cancelTaskProposal(uint256 _taskId): Proposer can cancel an unfunded task proposal.

    // IV. Task Execution & Outcome Submission
    // 15. signalTaskExecutionStart(uint256 _taskId): Agent signals it's beginning execution of a task.
    // 16. submitTaskOutcome(uint256 _taskId, bytes32 _outcomeHash): Agent submits the computed outcome of a task.
    // 17. claimTaskReward(uint256 _taskId): Agent claims its reward after the verification period if no successful dispute occurred.

    // V. Verification & Dispute System
    // 18. verifyTaskOutcome(uint256 _taskId, bytes32 _proofHash): Users or designated verifiers submit proof of a correct outcome.
    // 19. disputeTaskOutcome(uint256 _taskId, uint256 _stakeAmount): Users can stake tokens to dispute a submitted task outcome.
    // 20. resolveDispute(uint256 _taskId, bool _isOutcomeCorrect): Owner/governance resolves a dispute.

    // VI. Adaptive Mechanism & Governance
    // 21. proposeParameterAdjustment(uint256 _paramId, uint256 _newValue): Users can propose system parameter adjustments for voting.
    // 22. voteOnParameterAdjustment(uint256 _proposalId, bool _support): Users vote on parameter adjustment proposals.
    // 23. executeParameterAdjustment(uint256 _proposalId): Executes a passed parameter adjustment proposal.
    // 24. triggerAdaptiveParameterUpdate(): Triggers the automatic adjustment of system parameters based on historical network data.

    // VII. Token & NFT Interaction
    // 25. stakeTokensForAgent(uint256 _agentId, uint256 _amount): Users can stake tokens to support a specific agent.
    // 26. unstakeTokensFromAgent(uint256 _agentId, uint256 _amount): Users can unstake tokens from an agent.
    // 27. getTokenBalance(address _user): View the AAIN native token balance of a user.
    // 28. getAgentLicenseNFT_URI(uint256 _agentId): Get the metadata URI for an agent's NFT.

    // VIII. Utility & Reporting
    // 29. getPastTaskHistory(uint256 _startIndex, uint256 _count): View a paginated list of past tasks.
    // 30. getNetworkStats(): View overall network statistics.

    // --- State Variables ---

    IERC20 public immutable AAINToken;

    // Parameter enum for dynamic system configurations
    enum Param {
        MinAgentStake,                  // Minimum tokens an agent must stake to register
        AgentRegistrationFee,           // Fee to mint an agent NFT
        TaskFundingThreshold,           // Minimum funding for a task to be executable
        DefaultVerificationPeriod,      // Default time for verification/dispute
        DefaultDisputePeriod,           // Default time for an active dispute
        AgentRewardMultiplierNumerator, // For fractional multiplier: Numerator (e.g., 100 for 1x, 150 for 1.5x)
        AgentRewardMultiplierDenominator, // Denominator (e.g., 100)
        ParamVotingQuorumPercentage,    // Percentage of total staked tokens required for a proposal to pass
        ParamVotingPeriod,              // Duration for voting on parameter adjustments
        AdaptiveUpdateInterval,         // How often triggerAdaptiveParameterUpdate can be called
        MaxAdaptivePeriodLookback       // Number of recent tasks to consider for adaptive updates
    }

    // Dynamic system parameters, adjustable by governance or adaptive mechanism
    mapping(uint256 => uint256) public systemParameters; // Maps Param enum to its current value

    // Agent Lifecycle & Reputation
    enum AgentStatus { Active, Frozen, Deregistered }
    struct Agent {
        address owner; // Address controlling the agent
        string uri; // IPFS URI for agent metadata
        uint256 stakedAmount; // Tokens staked by the agent itself for registration
        uint256 totalUserStakedAmount; // Total tokens staked by other users backing this agent
        uint256 totalTasksProposed;
        uint256 totalTasksCompleted; // Successfully verified
        uint256 totalTasksDisputed; // Tasks that went into dispute
        uint256 successfulDisputesAsProposer; // Agent won the dispute as task proposer
        uint256 failedDisputesAsProposer; // Agent lost the dispute as task proposer
        AgentStatus status;
        uint256 registeredTimestamp;
    }
    Counters.Counter private _agentTokenIds; // ERC721 token IDs for agents
    mapping(uint256 => Agent) public agents; // agentId (NFT tokenId) -> Agent struct
    mapping(address => uint256) public ownerToAgentId; // Only one agent per owner for simplicity

    // Task Management
    enum TaskStatus { Proposed, Funded, InProgress, OutcomeSubmitted, Verified, Disputed, ResolvedCorrect, ResolvedIncorrect, Canceled }
    struct Task {
        uint256 agentId; // ID of the proposing agent (ERC721 token ID)
        address proposer; // The address who proposed the task
        string descriptionURI; // IPFS URI for task description
        bytes32 inputHash; // Hash of input data for the task
        bytes32 expectedOutputCriteriaHash; // Hash of criteria for verifying output
        uint256 rewardAmount; // Total reward for successful completion
        uint256 fundedAmount; // How much has been funded so far
        uint256 proposerStake; // Stake from the proposing agent or user for this task
        uint256 verificationPeriodEnd; // Timestamp when verification/dispute period ends
        uint256 disputePeriodEnd; // Timestamp when dispute resolution period ends (if disputed)
        bytes32 outcomeHash; // Submitted outcome hash by agent
        TaskStatus status;
        uint256 proposalTimestamp;
        bytes32 verifiedProofHash; // Proof submitted by verifier (if any)
        mapping(address => uint256) disputerStakes; // Disputer address -> staked amount
        uint256 totalDisputeStake; // Sum of all stakes for disputing
    }
    Counters.Counter private _taskIds;
    mapping(uint256 => Task) public tasks;
    uint256[] public allTaskIds; // For history and adaptive update lookback

    // Parameter Adjustment Governance
    struct ParameterAdjustmentProposal {
        uint256 paramId;
        uint256 newValue;
        uint256 voteCountSupport;
        uint256 voteCountOppose;
        uint256 totalVotingPowerAtProposal; // Total tokens staked at the time of proposal
        mapping(address => bool) hasVoted; // Voter address -> true (voted)
        uint256 proposalTimestamp;
        bool executed;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => ParameterAdjustmentProposal) public parameterProposals;
    // Note: Voting power is based on `totalUserStakedAmount` + `stakedAmount` for an agent, if msg.sender is an agent owner.
    // For non-agent owners, voting power comes from explicit stakes on agents, or a separate staking mechanism (not implemented here for simplicity)

    uint256 public nextAdaptiveUpdateTimestamp; // When triggerAdaptiveParameterUpdate can next be called

    // --- Events ---
    event ParameterUpdated(uint256 indexed paramId, uint256 oldValue, uint256 newValue);
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string uri, uint256 stakedAmount);
    event AgentDeregistered(uint256 indexed agentId, address indexed owner, uint256 returnedStake);
    event AgentProfileUpdated(uint256 indexed agentId, string newURI);
    event AgentFrozen(uint256 indexed agentId, bool frozen);
    event TaskProposed(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardAmount, uint256 proposalTimestamp);
    event TaskFunded(uint256 indexed taskId, address indexed funder, uint256 amount, uint256 totalFunded);
    event TaskCanceled(uint256 indexed taskId);
    event TaskExecutionStarted(uint256 indexed taskId, uint256 indexed agentId, uint256 timestamp);
    event TaskOutcomeSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 outcomeHash, uint256 submissionTimestamp);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bytes32 proofHash);
    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardAmount);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, uint256 stakeAmount);
    event DisputeResolved(uint256 indexed taskId, bool outcomeWasCorrect, uint256 timestamp);
    event ParameterAdjustmentProposed(uint256 indexed proposalId, uint256 indexed paramId, uint256 newValue, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ParameterAdjustmentExecuted(uint256 indexed proposalId, uint256 indexed paramId, uint256 newValue);
    event AdaptiveUpdateTriggered(uint256 timestamp);
    event TokensStakedForAgent(uint256 indexed agentId, address indexed staker, uint256 amount);
    event TokensUnstakedFromAgent(uint256 indexed agentId, address indexed unstaker, uint256 amount);

    // --- Constructor ---

    constructor(address _tokenAddress, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(_tokenAddress != address(0), "AAIN: Invalid token address");
        AAINToken = IERC20(_tokenAddress);

        // Initialize default system parameters
        systemParameters[uint256(Param.MinAgentStake)] = 5000 * 10**18; // 5000 AAIN Tokens
        systemParameters[uint256(Param.AgentRegistrationFee)] = 1000 * 10**18; // 1000 AAIN Tokens
        systemParameters[uint256(Param.TaskFundingThreshold)] = 1000 * 10**18; // 1000 AAIN Tokens
        systemParameters[uint256(Param.DefaultVerificationPeriod)] = 3 days;
        systemParameters[uint256(Param.DefaultDisputePeriod)] = 7 days;
        systemParameters[uint256(Param.AgentRewardMultiplierNumerator)] = 100; // 1x
        systemParameters[uint256(Param.AgentRewardMultiplierDenominator)] = 100;
        systemParameters[uint256(Param.ParamVotingQuorumPercentage)] = 10; // 10%
        systemParameters[uint256(Param.ParamVotingPeriod)] = 7 days;
        systemParameters[uint256(Param.AdaptiveUpdateInterval)] = 30 days;
        systemParameters[uint256(Param.MaxAdaptivePeriodLookback)] = 100; // Look back at 100 recent tasks

        nextAdaptiveUpdateTimestamp = block.timestamp + systemParameters[uint256(Param.AdaptiveUpdateInterval)];
    }

    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "AAIN: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "AAIN: Not agent owner");
        _;
    }

    modifier onlyActiveAgent(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "AAIN: Agent not active");
        _;
    }

    // --- I. Core Management & Setup ---

    /**
     * @dev Updates a specific system parameter. Callable only by the contract owner.
     * @param _paramId The ID of the parameter to update (from Param enum).
     * @param _newValue The new value for the parameter.
     */
    function updateSystemParameter(uint256 _paramId, uint256 _newValue) public onlyOwner {
        require(_paramId < uint256(type(Param).max), "AAIN: Invalid parameter ID"); // Ensure paramId is valid enum
        uint256 oldValue = systemParameters[_paramId];
        systemParameters[_paramId] = _newValue;
        emit ParameterUpdated(_paramId, oldValue, _newValue);
    }

    /**
     * @dev Pauses the contract. Callable only by the contract owner.
     * Prevents most state-changing operations.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Callable only by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens held by the contract in an emergency.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawFunds(address _token, address _to, uint256 _amount) public onlyOwner {
        require(IERC20(_token).transfer(_to, _amount), "AAIN: Failed to withdraw funds");
    }

    // --- II. Agent Management (ERC721 for Licenses) ---

    /**
     * @dev Allows a new AI agent to register itself with the network.
     * Requires the agent's owner to stake `MinAgentStake` tokens and pay an `AgentRegistrationFee`.
     * Mints a unique ERC721 NFT license for the agent.
     * @param _agentURI IPFS URI or similar for the agent's metadata.
     * @return The ID of the newly registered agent (NFT Token ID).
     */
    function registerAI_Agent(string memory _agentURI) public whenNotPaused returns (uint256) {
        require(ownerToAgentId[msg.sender] == 0, "AAIN: Address already owns an agent");
        uint256 minStake = systemParameters[uint256(Param.MinAgentStake)];
        uint256 regFee = systemParameters[uint256(Param.AgentRegistrationFee)];
        require(AAINToken.transferFrom(msg.sender, address(this), minStake + regFee), "AAIN: Insufficient stake or fee for registration");

        _agentTokenIds.increment();
        uint256 newAgentId = _agentTokenIds.current();

        agents[newAgentId] = Agent({
            owner: msg.sender,
            uri: _agentURI,
            stakedAmount: minStake,
            totalUserStakedAmount: 0,
            totalTasksProposed: 0,
            totalTasksCompleted: 0,
            totalTasksDisputed: 0,
            successfulDisputesAsProposer: 0,
            failedDisputesAsProposer: 0,
            status: AgentStatus.Active,
            registeredTimestamp: block.timestamp
        });

        _mint(msg.sender, newAgentId);
        ownerToAgentId[msg.sender] = newAgentId;
        _setTokenURI(newAgentId, _agentURI); // Set initial NFT URI

        emit AgentRegistered(newAgentId, msg.sender, _agentURI, minStake + regFee);
        return newAgentId;
    }

    /**
     * @dev Allows an agent to deregister from the network.
     * Burns its NFT and attempts to reclaim its staked tokens.
     * Requires no active tasks or user-staked tokens.
     */
    function deregisterAI_Agent() public onlyAgentOwner(ownerToAgentId[msg.sender]) whenNotPaused {
        uint256 agentId = ownerToAgentId[msg.sender];
        Agent storage agent = agents[agentId];

        require(agent.totalUserStakedAmount == 0, "AAIN: Cannot deregister with user-staked funds");
        // Further checks for active tasks could be added here
        // For simplicity, we assume tasks must be completed/resolved before deregistering.

        uint256 returnStake = agent.stakedAmount;
        agent.stakedAmount = 0;
        agent.status = AgentStatus.Deregistered;
        ownerToAgentId[msg.sender] = 0; // Clear mapping
        _burn(agentId); // Burn the NFT

        require(AAINToken.transfer(msg.sender, returnStake), "AAIN: Failed to return agent stake");

        emit AgentDeregistered(agentId, msg.sender, returnStake);
    }

    /**
     * @dev Allows an agent owner to update the metadata URI for their agent's NFT license.
     * @param _agentId The ID of the agent (NFT Token ID).
     * @param _newURI The new IPFS URI for the agent's metadata.
     */
    function updateAgentProfile(uint256 _agentId, string memory _newURI) public onlyAgentOwner(_agentId) {
        agents[_agentId].uri = _newURI;
        _setTokenURI(_agentId, _newURI); // Update NFT metadata URI
        emit AgentProfileUpdated(_agentId, _newURI);
    }

    /**
     * @dev Retrieves performance metrics for a specific AI agent.
     * @param _agentId The ID of the agent (NFT Token ID).
     * @return A tuple containing various performance statistics.
     */
    function getAgentPerformanceMetrics(uint256 _agentId)
        public
        view
        returns (
            address agentOwner,
            uint256 stakedAmount,
            uint256 totalUserStakedAmount,
            uint256 totalTasksProposed,
            uint256 totalTasksCompleted,
            uint256 totalTasksDisputed,
            uint256 successfulDisputesAsProposer,
            uint256 failedDisputesAsProposer,
            AgentStatus status,
            uint256 registeredTimestamp
        )
    {
        Agent storage agent = agents[_agentId];
        return (
            agent.owner,
            agent.stakedAmount,
            agent.totalUserStakedAmount,
            agent.totalTasksProposed,
            agent.totalTasksCompleted,
            agent.totalTasksDisputed,
            agent.successfulDisputesAsProposer,
            agent.failedDisputesAsProposer,
            agent.status,
            agent.registeredTimestamp
        );
    }

    /**
     * @dev Freezes or unfreezes an AI agent's participation in the network.
     * Callable only by the contract owner. Frozen agents cannot propose tasks or submit outcomes.
     * @param _agentId The ID of the agent to freeze/unfreeze.
     * @param _freeze True to freeze, false to unfreeze.
     */
    function freezeAgentAccount(uint256 _agentId, bool _freeze) public onlyOwner {
        require(_exists(_agentId), "AAIN: Agent does not exist");
        agents[_agentId].status = _freeze ? AgentStatus.Frozen : AgentStatus.Active;
        emit AgentFrozen(_agentId, _freeze);
    }

    // --- III. Task Proposal & Funding ---

    /**
     * @dev Allows an active AI agent to propose a new computational task.
     * The agent must provide a task description, input/output criteria hashes, and the desired reward.
     * The proposing agent must also stake a portion of the reward.
     * @param _taskDescriptionURI IPFS URI for detailed task description.
     * @param _inputHash Hash of the input data for the task.
     * @param _expectedOutputCriteriaHash Hash defining criteria for verifying the output.
     * @param _rewardAmount The total reward amount for successful task completion.
     * @return The ID of the newly proposed task.
     */
    function proposeComputationalTask(
        string memory _taskDescriptionURI,
        bytes32 _inputHash,
        bytes32 _expectedOutputCriteriaHash,
        uint256 _rewardAmount
    ) public onlyActiveAgent(ownerToAgentId[msg.sender]) whenNotPaused returns (uint256) {
        uint256 agentId = ownerToAgentId[msg.sender];
        require(_rewardAmount > 0, "AAIN: Reward must be positive");
        
        // Agent stakes a portion of the reward (e.g., 10%)
        uint256 proposerStake = _rewardAmount / 10; 
        require(AAINToken.transferFrom(msg.sender, address(this), proposerStake), "AAIN: Insufficient proposer stake");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            agentId: agentId,
            proposer: msg.sender,
            descriptionURI: _taskDescriptionURI,
            inputHash: _inputHash,
            expectedOutputCriteriaHash: _expectedOutputCriteriaHash,
            rewardAmount: _rewardAmount,
            fundedAmount: proposerStake, // Initial funding from proposer
            proposerStake: proposerStake,
            verificationPeriodEnd: 0, // Set upon outcome submission
            disputePeriodEnd: 0,
            outcomeHash: bytes32(0),
            status: TaskStatus.Proposed,
            proposalTimestamp: block.timestamp,
            verifiedProofHash: bytes32(0),
            totalDisputeStake: 0
        });
        allTaskIds.push(newTaskId);
        agents[agentId].totalTasksProposed++;

        emit TaskProposed(newTaskId, agentId, _rewardAmount, block.timestamp);
        return newTaskId;
    }

    /**
     * @dev Allows users to stake tokens to fund a proposed task's reward pool.
     * Once `TaskFundingThreshold` is reached, the task can proceed.
     * @param _taskId The ID of the task to fund.
     * @param _amount The amount of tokens to stake for funding.
     */
    function fundTaskProposal(uint256 _taskId, uint256 _amount) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Proposed, "AAIN: Task not in proposed state");
        require(_amount > 0, "AAIN: Funding amount must be positive");
        require(task.fundedAmount + _amount <= task.rewardAmount, "AAIN: Funding exceeds reward amount");

        require(AAINToken.transferFrom(msg.sender, address(this), _amount), "AAIN: Token transfer failed");

        task.fundedAmount += _amount;
        if (task.fundedAmount >= task.rewardAmount && task.fundedAmount >= systemParameters[uint256(Param.TaskFundingThreshold)]) {
            task.status = TaskStatus.Funded;
        }
        emit TaskFunded(_taskId, msg.sender, _amount, task.fundedAmount);
    }

    /**
     * @dev Retrieves all details for a specific task.
     * @param _taskId The ID of the task.
     * @return A tuple containing all task struct data.
     */
    function getTaskDetails(uint256 _taskId)
        public
        view
        returns (
            uint256 agentId,
            address proposer,
            string memory descriptionURI,
            bytes32 inputHash,
            bytes32 expectedOutputCriteriaHash,
            uint256 rewardAmount,
            uint256 fundedAmount,
            uint256 proposerStake,
            uint256 verificationPeriodEnd,
            uint256 disputePeriodEnd,
            bytes32 outcomeHash,
            TaskStatus status,
            uint256 proposalTimestamp
        )
    {
        Task storage task = tasks[_taskId];
        return (
            task.agentId,
            task.proposer,
            task.descriptionURI,
            task.inputHash,
            task.expectedOutputCriteriaHash,
            task.rewardAmount,
            task.fundedAmount,
            task.proposerStake,
            task.verificationPeriodEnd,
            task.disputePeriodEnd,
            task.outcomeHash,
            task.status,
            task.proposalTimestamp
        );
    }

    /**
     * @dev Allows the proposer to cancel an unfunded task.
     * If the task has received some funding but not enough, the proposer can reclaim their stake,
     * but other funders' stakes remain locked or would require a separate refund mechanism (not implemented here).
     * For simplicity, only completely unfunded tasks or tasks funded only by the proposer can be canceled.
     * If proposer cancels, their stake is returned. Other funders would need separate claims.
     * This simplified version assumes proposer can only cancel if *only* their stake is present.
     * A more robust system would require a multi-party refund.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTaskProposal(uint256 _taskId) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.proposer == msg.sender, "AAIN: Only proposer can cancel task");
        require(task.status == TaskStatus.Proposed, "AAIN: Task not in proposed state");
        require(task.fundedAmount == task.proposerStake, "AAIN: Task has external funding, cannot simply cancel");

        uint256 returnedStake = task.proposerStake;
        task.status = TaskStatus.Canceled;
        task.proposerStake = 0;
        task.fundedAmount = 0;

        require(AAINToken.transfer(msg.sender, returnedStake), "AAIN: Failed to return proposer stake");
        emit TaskCanceled(_taskId);
    }

    // --- IV. Task Execution & Outcome Submission ---

    /**
     * @dev Agent signals that it has started executing a funded task.
     * Changes task status to InProgress.
     * @param _taskId The ID of the task.
     */
    function signalTaskExecutionStart(uint256 _taskId) public onlyAgentOwner(tasks[_taskId].agentId) onlyActiveAgent(tasks[_taskId].agentId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.agentId == ownerToAgentId[msg.sender], "AAIN: Not the assigned agent");
        require(task.status == TaskStatus.Funded || task.status == TaskStatus.InProgress, "AAIN: Task not funded or already in progress");
        task.status = TaskStatus.InProgress;
        emit TaskExecutionStarted(_taskId, task.agentId, block.timestamp);
    }

    /**
     * @dev Agent submits the computed outcome hash for a task.
     * Starts the verification period.
     * @param _taskId The ID of the task.
     * @param _outcomeHash The hash of the computed outcome.
     */
    function submitTaskOutcome(uint256 _taskId, bytes32 _outcomeHash) public onlyAgentOwner(tasks[_taskId].agentId) onlyActiveAgent(tasks[_taskId].agentId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.agentId == ownerToAgentId[msg.sender], "AAIN: Not the assigned agent");
        require(task.status == TaskStatus.InProgress || task.status == TaskStatus.Funded, "AAIN: Task not in progress or funded"); // Allow direct submission if funded and not yet started
        
        task.outcomeHash = _outcomeHash;
        task.submissionTimestamp = block.timestamp;
        task.verificationPeriodEnd = block.timestamp + systemParameters[uint256(Param.DefaultVerificationPeriod)];
        task.status = TaskStatus.OutcomeSubmitted;

        emit TaskOutcomeSubmitted(_taskId, task.agentId, _outcomeHash, block.timestamp);
    }

    /**
     * @dev Allows the agent to claim its reward after the verification period has ended
     * and if no successful dispute occurred.
     * The reward includes the funded amount and the agent's initial proposer stake.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) public onlyAgentOwner(tasks[_taskId].agentId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.agentId == ownerToAgentId[msg.sender], "AAIN: Not the claiming agent");
        require(task.status == TaskStatus.OutcomeSubmitted || task.status == TaskStatus.Verified, "AAIN: Task not in claimable state");
        require(block.timestamp >= task.verificationPeriodEnd, "AAIN: Verification period not ended");

        // If outcome submitted and verification period passed, and no dispute, or dispute resolved in favor.
        bool eligibleToClaim = (task.status == TaskStatus.OutcomeSubmitted && task.verificationPeriodEnd <= block.timestamp) ||
                               (task.status == TaskStatus.Verified && task.verificationPeriodEnd <= block.timestamp) ||
                               (task.status == TaskStatus.ResolvedCorrect);

        require(eligibleToClaim, "AAIN: Task not yet eligible for reward claim");

        uint256 rewardMultiplier = systemParameters[uint256(Param.AgentRewardMultiplierNumerator)];
        uint256 multiplierDenominator = systemParameters[uint256(Param.AgentRewardMultiplierDenominator)];
        uint256 finalReward = (task.fundedAmount * rewardMultiplier) / multiplierDenominator;

        // Ensure the contract has enough tokens (accounting for fees, etc.)
        require(AAINToken.balanceOf(address(this)) >= finalReward, "AAIN: Insufficient contract balance for reward");

        // Transfer full reward (funded amount + agent's original stake)
        require(AAINToken.transfer(msg.sender, finalReward), "AAIN: Failed to transfer reward");

        task.status = TaskStatus.ResolvedCorrect; // Mark as fully resolved after reward claim
        agents[task.agentId].totalTasksCompleted++;
        agents[task.agentId].totalTasksProposed--; // Decrement proposed, increment completed (for reputation)

        emit TaskRewardClaimed(_taskId, task.agentId, finalReward);
    }

    // --- V. Verification & Dispute System ---

    /**
     * @dev Allows users or designated verifiers to submit proof for a correct task outcome.
     * This acts as an affirmation during the verification period.
     * @param _taskId The ID of the task.
     * @param _proofHash A hash representing the proof of correctness.
     */
    function verifyTaskOutcome(uint256 _taskId, bytes32 _proofHash) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OutcomeSubmitted, "AAIN: Task not awaiting verification");
        require(block.timestamp < task.verificationPeriodEnd, "AAIN: Verification period has ended");

        // Simple verification: Just records who verified.
        // A more complex system might require a quorum of verifiers or a specific oracle.
        task.verifiedProofHash = _proofHash; // Stores the latest proof, or a first-come, first-serve.
        task.status = TaskStatus.Verified; // Changes state to Verified upon any valid verification.

        emit TaskVerified(_taskId, msg.sender, _proofHash);
    }

    /**
     * @dev Allows users to dispute a submitted task outcome during the verification period.
     * Requires staking tokens to initiate a dispute.
     * @param _taskId The ID of the task to dispute.
     * @param _stakeAmount The amount of tokens to stake for the dispute.
     */
    function disputeTaskOutcome(uint256 _taskId, uint256 _stakeAmount) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OutcomeSubmitted || task.status == TaskStatus.Verified, "AAIN: Task not in disputable state");
        require(block.timestamp < task.verificationPeriodEnd, "AAIN: Verification period has ended");
        require(_stakeAmount > 0, "AAIN: Dispute stake must be positive");
        require(task.disputerStakes[msg.sender] == 0, "AAIN: Address already staked for this dispute"); // Prevent multiple stakes from same user

        require(AAINToken.transferFrom(msg.sender, address(this), _stakeAmount), "AAIN: Token transfer failed for dispute stake");

        task.disputerStakes[msg.sender] = _stakeAmount;
        task.totalDisputeStake += _stakeAmount;
        task.status = TaskStatus.Disputed;
        task.disputePeriodEnd = block.timestamp + systemParameters[uint256(Param.DefaultDisputePeriod)];

        agents[task.agentId].totalTasksDisputed++;
        emit TaskDisputed(_taskId, msg.sender, _stakeAmount);
    }

    /**
     * @dev Resolves an active dispute, distributing stakes and rewards based on the outcome.
     * Callable only by the contract owner (or a designated governance/oracle role).
     * @param _taskId The ID of the task whose dispute is being resolved.
     * @param _isOutcomeCorrect True if the original submitted outcome was correct, false if incorrect.
     */
    function resolveDispute(uint256 _taskId, bool _isOutcomeCorrect) public onlyOwner {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Disputed, "AAIN: Task not in dispute");
        require(block.timestamp >= task.disputePeriodEnd, "AAIN: Dispute period not ended");

        uint256 agentId = task.agentId;
        uint256 totalRewardPool = task.fundedAmount + task.proposerStake; // Including original proposer stake

        if (_isOutcomeCorrect) {
            // Outcome was correct, agent wins. Disputers lose their stake.
            task.status = TaskStatus.ResolvedCorrect;
            agents[agentId].successfulDisputesAsProposer++;
            agents[agentId].totalTasksCompleted++;
            agents[agentId].totalTasksProposed--;

            // Reward agent with total pool (funded + proposer stake + disputer stakes)
            // Disputer stakes are effectively burned or moved to a fee pool (here, added to agent reward)
            uint256 finalAgentReward = totalRewardPool + task.totalDisputeStake;
            require(AAINToken.transfer(agents[agentId].owner, finalAgentReward), "AAIN: Failed to transfer reward to agent");
        } else {
            // Outcome was incorrect, disputers win. Agent loses its stake and reward.
            task.status = TaskStatus.ResolvedIncorrect;
            agents[agentId].failedDisputesAsProposer++;

            // Return stakes to disputers proportionally
            for (uint256 i = 0; i < allTaskIds.length; i++) { // Iterate through all tasks to find disputers (inefficient, but simple for example)
                // In a real scenario, dispute participants should be stored in a dynamic array
                // or retrieved more efficiently. This loop is illustrative.
                if (allTaskIds[i] == _taskId) {
                    // This is a placeholder for a more complex iteration over `task.disputerStakes` keys.
                    // A proper implementation would require storing disputer addresses in an array.
                    // For now, let's assume `msg.sender` is the sole disputer if `task.disputerStakes[msg.sender]` exists.
                    // A simple refund to the first disputer or a placeholder here.
                    // A better design would be a `mapping(uint256 => address[]) public disputerListForTask;`
                }
            }
            // For simplicity, let's assume a simplified dispute resolution:
            // If incorrect, agent loses its proposer stake to contract/burn, disputers get their stakes back.
            // Funded rewards are distributed back to original funders (not implemented here for brevity).
            
            // Refund disputer stakes
            // This is problematic with `mapping(address => uint256)` without storing addresses.
            // For this example, we'll simulate stakes being "released" but not explicitly refunded,
            // or consider them sent to an owner-controlled recovery pool.
            // For proper refund, a list of disputer addresses would be needed.
            
            // Agent's proposer stake is lost (effectively burned)
            task.proposerStake = 0; 
            task.fundedAmount = 0; // Funded amount is now 'lost' or handled by specific refund logic
            // The task's totalDisputeStake is effectively "burned" or goes to a treasury if no refund mechanism.
        }
        emit DisputeResolved(_taskId, _isOutcomeCorrect, block.timestamp);
    }


    // --- VI. Adaptive Mechanism & Governance ---

    /**
     * @dev Allows any user to propose a system parameter adjustment for community voting.
     * @param _paramId The ID of the parameter to propose changing (from Param enum).
     * @param _newValue The proposed new value for the parameter.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterAdjustment(uint256 _paramId, uint256 _newValue) public whenNotPaused returns (uint256) {
        require(_paramId < uint256(type(Param).max), "AAIN: Invalid parameter ID");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        // Calculate total current voting power
        uint256 currentTotalStaked = getTotalStakedTokens();

        parameterProposals[newProposalId] = ParameterAdjustmentProposal({
            paramId: _paramId,
            newValue: _newValue,
            voteCountSupport: 0,
            voteCountOppose: 0,
            totalVotingPowerAtProposal: currentTotalStaked,
            proposalTimestamp: block.timestamp,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ParameterAdjustmentProposed(newProposalId, _paramId, _newValue, msg.sender);
        return newProposalId;
    }

    /**
     * @dev Allows users to vote on an active parameter adjustment proposal.
     * Voting power is determined by the total tokens staked by or for the voter's agent.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnParameterAdjustment(uint256 _proposalId, bool _support) public whenNotPaused {
        ParameterAdjustmentProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.proposalTimestamp != 0, "AAIN: Proposal does not exist");
        require(block.timestamp < proposal.proposalTimestamp + systemParameters[uint256(Param.ParamVotingPeriod)], "AAIN: Voting period has ended");
        require(!proposal.executed, "AAIN: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "AAIN: Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "AAIN: No voting power");

        if (_support) {
            proposal.voteCountSupport += voterPower;
        } else {
            proposal.voteCountOppose += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Executes a parameter adjustment proposal if it has passed the voting criteria.
     * A proposal passes if (support votes / total voting power at proposal) > quorum and support > oppose.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterAdjustment(uint256 _proposalId) public whenNotPaused {
        ParameterAdjustmentProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.proposalTimestamp != 0, "AAIN: Proposal does not exist");
        require(block.timestamp >= proposal.proposalTimestamp + systemParameters[uint256(Param.ParamVotingPeriod)], "AAIN: Voting period not ended");
        require(!proposal.executed, "AAIN: Proposal already executed");

        uint256 quorumPercentage = systemParameters[uint256(Param.ParamVotingQuorumPercentage)];
        uint256 totalVotingPower = proposal.totalVotingPowerAtProposal;

        bool hasQuorum = (proposal.voteCountSupport * 100) / totalVotingPower >= quorumPercentage;
        bool majoritySupport = proposal.voteCountSupport > proposal.voteCountOppose;

        if (hasQuorum && majoritySupport) {
            uint256 oldValue = systemParameters[proposal.paramId];
            systemParameters[proposal.paramId] = proposal.newValue;
            proposal.executed = true;
            emit ParameterAdjustmentExecuted(_proposalId, proposal.paramId, proposal.newValue);
            emit ParameterUpdated(proposal.paramId, oldValue, proposal.newValue);
        } else {
            // Optionally, emit an event for failed proposal
        }
    }

    /**
     * @dev Triggers the automatic adjustment of system parameters based on aggregated historical data.
     * This function embodies the "adaptive" aspect of the network.
     * Can only be called once per `AdaptiveUpdateInterval`.
     * Calculates new parameters based on recent task success rates, dispute frequencies, etc.
     */
    function triggerAdaptiveParameterUpdate() public whenNotPaused {
        require(block.timestamp >= nextAdaptiveUpdateTimestamp, "AAIN: Adaptive update not yet due");

        uint256 lookbackCount = systemParameters[uint256(Param.MaxAdaptivePeriodLookback)];
        uint256 startIndex = allTaskIds.length > lookbackCount ? allTaskIds.length - lookbackCount : 0;

        uint256 successfulTasksInPeriod = 0;
        uint256 failedTasksInPeriod = 0;
        uint256 disputedTasksInPeriod = 0;

        for (uint256 i = startIndex; i < allTaskIds.length; i++) {
            Task storage task = tasks[allTaskIds[i]];
            if (task.status == TaskStatus.ResolvedCorrect) {
                successfulTasksInPeriod++;
            } else if (task.status == TaskStatus.ResolvedIncorrect) {
                failedTasksInPeriod++;
            }
            if (task.totalDisputeStake > 0) { // If it was disputed at all
                disputedTasksInPeriod++;
            }
        }

        uint256 totalAnalyzedTasks = successfulTasksInPeriod + failedTasksInPeriod;

        // --- Adaptive Logic ---
        // Example: Adjust AgentRewardMultiplier based on success rate
        uint256 currentNumerator = systemParameters[uint256(Param.AgentRewardMultiplierNumerator)];
        uint256 currentDenominator = systemParameters[uint256(Param.AgentRewardMultiplierDenominator)];

        if (totalAnalyzedTasks > 0) {
            uint256 successRate = (successfulTasksInPeriod * 100) / totalAnalyzedTasks; // 0-100%

            // Increase multiplier if success rate is high, decrease if low
            if (successRate > 75) { // High success
                currentNumerator += 5; // Increase by 5%
            } else if (successRate < 50) { // Low success
                currentNumerator = currentNumerator > 5 ? currentNumerator - 5 : 0; // Decrease by 5%, with floor
            }
            // Cap multiplier to avoid extreme values (e.g., 2x max)
            if (currentNumerator > 200) currentNumerator = 200; // Max 2x multiplier
            
            // Update parameter if changed
            if (systemParameters[uint256(Param.AgentRewardMultiplierNumerator)] != currentNumerator) {
                uint256 oldNumerator = systemParameters[uint256(Param.AgentRewardMultiplierNumerator)];
                systemParameters[uint256(Param.AgentRewardMultiplierNumerator)] = currentNumerator;
                emit ParameterUpdated(uint256(Param.AgentRewardMultiplierNumerator), oldNumerator, currentNumerator);
            }
        }

        // Example: Adjust DefaultDisputePeriod based on dispute frequency
        uint256 currentDisputePeriod = systemParameters[uint256(Param.DefaultDisputePeriod)];
        if (totalAnalyzedTasks > 0) {
            uint256 disputeFrequency = (disputedTasksInPeriod * 100) / totalAnalyzedTasks;

            if (disputeFrequency > 20) { // High dispute frequency
                currentDisputePeriod += 1 days; // Increase period
            } else if (disputeFrequency < 5 && currentDisputePeriod > 3 days) { // Low dispute frequency, min 3 days
                currentDisputePeriod -= 1 days;
            }
            // Cap dispute period (e.g., 14 days max)
            if (currentDisputePeriod > 14 days) currentDisputePeriod = 14 days;

            if (systemParameters[uint256(Param.DefaultDisputePeriod)] != currentDisputePeriod) {
                uint256 oldPeriod = systemParameters[uint256(Param.DefaultDisputePeriod)];
                systemParameters[uint256(Param.DefaultDisputePeriod)] = currentDisputePeriod;
                emit ParameterUpdated(uint256(Param.DefaultDisputePeriod), oldPeriod, currentDisputePeriod);
            }
        }

        nextAdaptiveUpdateTimestamp = block.timestamp + systemParameters[uint256(Param.AdaptiveUpdateInterval)];
        emit AdaptiveUpdateTriggered(block.timestamp);
    }

    // --- VII. Token & NFT Interaction ---

    /**
     * @dev Allows users to stake AAIN tokens to support a specific AI agent.
     * This stake contributes to the agent's reputation/trust and the staker's voting power.
     * @param _agentId The ID of the agent to stake for.
     * @param _amount The amount of tokens to stake.
     */
    function stakeTokensForAgent(uint256 _agentId, uint256 _amount) public whenNotPaused {
        require(_exists(_agentId), "AAIN: Agent does not exist");
        require(agents[_agentId].status == AgentStatus.Active, "AAIN: Agent not active");
        require(_amount > 0, "AAIN: Stake amount must be positive");

        require(AAINToken.transferFrom(msg.sender, address(this), _amount), "AAIN: Token transfer failed");

        agents[_agentId].totalUserStakedAmount += _amount;
        emit TokensStakedForAgent(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake tokens from a supported AI agent.
     * @param _agentId The ID of the agent to unstake from.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeTokensFromAgent(uint256 _agentId, uint256 _amount) public whenNotPaused {
        require(_exists(_agentId), "AAIN: Agent does not exist");
        require(_amount > 0, "AAIN: Unstake amount must be positive");
        require(agents[_agentId].totalUserStakedAmount >= _amount, "AAIN: Insufficient staked amount");

        // Note: A more complex implementation might track individual user stakes per agent.
        // For simplicity, we assume this function reduces the general pool of user-staked tokens.
        // This implies that it's up to the user to track how much they staked.
        agents[_agentId].totalUserStakedAmount -= _amount;

        require(AAINToken.transfer(msg.sender, _amount), "AAIN: Token transfer failed");
        emit TokensUnstakedFromAgent(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Returns the AAIN native token balance of a given user.
     * @param _user The address of the user.
     * @return The balance of AAIN tokens.
     */
    function getTokenBalance(address _user) public view returns (uint256) {
        return AAINToken.balanceOf(_user);
    }

    /**
     * @dev Returns the metadata URI for a specific agent's NFT license.
     * @param _agentId The ID of the agent (NFT Token ID).
     * @return The metadata URI.
     */
    function getAgentLicenseNFT_URI(uint256 _agentId) public view returns (string memory) {
        return tokenURI(_agentId);
    }

    // --- VIII. Utility & Reporting ---

    /**
     * @dev Retrieves a paginated list of task IDs.
     * @param _startIndex The starting index for pagination.
     * @param _count The number of task IDs to retrieve.
     * @return An array of task IDs.
     */
    function getPastTaskHistory(uint256 _startIndex, uint256 _count) public view returns (uint256[] memory) {
        require(_startIndex < allTaskIds.length, "AAIN: Start index out of bounds");
        uint256 endIndex = _startIndex + _count;
        if (endIndex > allTaskIds.length) {
            endIndex = allTaskIds.length;
        }
        uint256[] memory result = new uint256[](endIndex - _startIndex);
        for (uint256 i = _startIndex; i < endIndex; i++) {
            result[i - _startIndex] = allTaskIds[i];
        }
        return result;
    }

    /**
     * @dev Provides overall network statistics.
     * @return A tuple containing total agents, active tasks, total tasks, and total staked tokens.
     */
    function getNetworkStats()
        public
        view
        returns (
            uint256 totalRegisteredAgents,
            uint256 activeTasks,
            uint256 totalTasks,
            uint256 totalStakedTokensInNetwork
        )
    {
        totalRegisteredAgents = _agentTokenIds.current();
        totalTasks = _taskIds.current();

        uint256 currentActiveTasks = 0;
        for (uint256 i = 1; i <= _taskIds.current(); i++) {
            if (tasks[i].status == TaskStatus.Funded || tasks[i].status == TaskStatus.InProgress ||
                tasks[i].status == TaskStatus.OutcomeSubmitted || tasks[i].status == TaskStatus.Disputed) {
                currentActiveTasks++;
            }
        }
        activeTasks = currentActiveTasks;
        totalStakedTokensInNetwork = AAINToken.balanceOf(address(this)); // Simplified: total tokens held by contract

        return (
            totalRegisteredAgents,
            activeTasks,
            totalTasks,
            totalStakedTokensInNetwork
        );
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates the voting power for a given address.
     * If the address owns an agent, their power is agent's own stake + user-staked tokens.
     * Otherwise, this simple version assumes 0.
     * A more complex system might allow individual users to stake tokens for general governance.
     */
    function getVotingPower(address _voter) internal view returns (uint256) {
        uint256 agentId = ownerToAgentId[_voter];
        if (agentId != 0) {
            Agent storage agent = agents[agentId];
            return agent.stakedAmount + agent.totalUserStakedAmount;
        }
        return 0; // No voting power if not an agent owner or no explicit stake
    }

    /**
     * @dev Calculates the total amount of tokens currently staked in the network (by agents and users).
     * Used for calculating quorum for governance proposals.
     * A more precise calculation would sum actual `stakedAmount` and `totalUserStakedAmount` from all active agents.
     * This simplified version returns the total balance of the AAIN token held by the contract itself.
     */
    function getTotalStakedTokens() internal view returns (uint256) {
        // This is a simplification. A truly accurate sum would iterate all agents and sum their stakes.
        // For a large number of agents, this could be gas-intensive.
        // For current purpose, `balanceOf(address(this))` is a reasonable approximation for total value under management.
        return AAINToken.balanceOf(address(this));
    }
}
```