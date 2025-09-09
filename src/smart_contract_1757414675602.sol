The `AI_Agent_Guild` smart contract is designed as a decentralized platform for managing AI agents, commissioning tasks, building agent reputation, and facilitating community-driven training data contributions. It aims to foster a transparent and incentivized ecosystem where AI agents can offer their services, earn rewards, and improve over time through user feedback and training.

---

**Smart Contract: AI_Agent_Guild**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AI_Agent_Guild
 * @dev A decentralized platform for AI agent registration, task commissioning, execution,
 *      reputation building, and training data exchange.
 *      Agents (or their owners) can register their AI blueprints, accept tasks, and submit results.
 *      Commissioners post tasks with bounties and verify outcomes.
 *      A reputation system tracks agent performance.
 *      Users can contribute to and utilize training data pools, and participate in light governance.
 *      The contract assumes AI computations happen off-chain, and their verifiable outcomes
 *      (e.g., hashes of results, attestations) are committed on-chain.
 *
 * Outline and Function Summary:
 *
 * I. Core Management & Registration
 *    1. `registerAgentBlueprint(string memory _metadataURI)`: Allows a user to register a new AI agent blueprint. The `_metadataURI` typically points to an IPFS hash or URL detailing the agent's capabilities.
 *    2. `updateAgentBlueprint(uint256 _agentID, string memory _newMetadataURI)`: Updates the metadata URI of an existing agent, callable only by the agent owner.
 *    3. `deregisterAgent(uint256 _agentID)`: Marks an agent as deregistered, preventing it from accepting new tasks but keeping existing task obligations. Callable only by the agent owner.
 *    4. `stakeAgent(uint256 _agentID, uint256 _amount)`: Allows an agent owner to stake `rewardToken` for their agent. This can make the agent eligible for specific tasks or boost its visibility. Requires prior `approve` call for `rewardToken`.
 *    5. `unstakeAgent(uint256 _agentID, uint256 _amount)`: Allows an agent owner to unstake `rewardToken` from their agent.
 *
 * II. Task Commissioning & Execution
 *    6. `createTask(uint256 _agentID, string memory _descriptionURI, uint256 _bounty, uint256 _deadline)`: A commissioner creates a new task, assigns it to a specific active agent, and funds it with a `rewardToken` bounty. Requires prior `approve` call for `rewardToken`.
 *    7. `submitTaskResult(uint256 _taskID, string memory _submissionURI)`: The agent owner submits the result of an assigned task by providing a URI to the outcome. Must be done before the task deadline.
 *    8. `verifyTaskResult(uint256 _taskID, bool _success)`: The commissioner verifies the task outcome. If successful, the bounty is paid to the agent, and reputation is adjusted. If failed, the bounty remains in the contract, and reputation is negatively adjusted.
 *    9. `disputeTaskResult(uint256 _taskID, string memory _reasonURI)`: Either the commissioner or the agent owner can dispute a task's outcome or verification. A dispute fee is charged, and a formal dispute resolution process is initiated.
 *
 * III. Agent Reputation & Training
 *    10. `submitAgentFeedback(uint256 _taskID, uint8 _rating, string memory _commentURI)`: After a task is verified, the commissioner can provide feedback (a rating and comments) which further adjusts the agent's reputation score.
 *    11. `proposeTrainingDataPool(string memory _metadataURI)`: Creates a new conceptual training data pool. The `_metadataURI` describes the type of data or purpose of the pool.
 *    12. `contributeToTrainingDataPool(uint256 _poolID, string memory _contributionURI, uint256 _rewardShare)`: Users can contribute data/feedback to a pool. In this model, they stake `_rewardShare` as their contribution, which they can later claim back. `_contributionURI` points to the data.
 *    13. `claimTrainingContributionReward(uint256 _poolID)`: Allows a contributor to reclaim their `rewardToken` share from a training data pool.
 *    14. `attestAgentSkillUpdate(uint256 _agentID, string memory _attestationURI)`: Agent owner can attest to an agent's skill improvement after off-chain training. This might provide a small reputation boost.
 *
 * IV. Dispute Resolution & Governance
 *    15. `initiateDisputeResolution(uint256 _referenceID, DisputeType _type, address _initiator, address _counterparty)`: Initiates a formal dispute process for various on-chain items (tasks, feedback, etc.). Called internally or by guild owner.
 *    16. `submitDisputeEvidence(uint256 _disputeID, string memory _evidenceURI)`: Allows involved parties to submit evidence to an active dispute.
 *    17. `resolveDispute(uint256 _disputeID, address _winner)`: The Guild owner (acting as a simple arbiter in this example) resolves a dispute, declaring a winner. This impacts reputation and token transfers based on the dispute type.
 *    18. `proposeGuildParameterChange(string memory _descriptionURI, bytes memory _calldata)`: Allows any user to propose changes to the guild's configurable parameters (e.g., dispute fees, voting duration). `_calldata` specifies the function call to execute if approved.
 *    19. `voteOnProposal(uint256 _proposalID, bool _support)`: Eligible members can vote for or against an active proposal.
 *    20. `executeProposal(uint256 _proposalID)`: Executes a successfully voted-on proposal after the voting period ends.
 *
 * V. Query & Utility Functions (Read-Only)
 *    21. `getAgentDetails(uint256 _agentID)`: Returns all stored details of a specific AI agent.
 *    22. `getTaskDetails(uint256 _taskID)`: Returns all stored details of a specific task.
 *    23. `getAgentTasks(uint256 _agentID)`: Returns a list of all task IDs associated with a given agent.
 *    24. `getPendingTasksForAgent(uint256 _agentID)`: Returns a list of task IDs that are currently assigned or submitted but not yet verified for a specific agent.
 *    25. `getAgentReputation(uint256 _agentID)`: Returns an agent's current reputation score.
 *    26. `setProposalQuorumPercentage(uint256 _newPercentage)`: Allows the Guild owner to update the required percentage of votes for a proposal to pass.
 *    27. `setVotingPeriodDuration(uint256 _newDuration)`: Allows the Guild owner to update the duration for which proposals are open for voting.
 */

contract AI_Agent_Guild is Ownable {
    IERC20 public immutable rewardToken; // Token used for bounties and rewards

    // --- Enums & Structs ---

    enum AgentStatus {
        Inactive,      // Not eligible for new tasks, might be temporarily disabled
        Active,        // Eligible for tasks, no minimum stake met
        Staked,        // Eligible for tasks, minimum stake met
        Deregistered   // Permanently removed, existing tasks might still be handled
    }

    enum TaskStatus {
        Open,           // Task is created and awaiting assignment (not used in current `createTask` flow)
        Assigned,       // Task is assigned to an agent, awaiting submission
        Submitted,      // Agent has submitted results, awaiting commissioner verification
        VerifiedSuccess,// Commissioner verified successfully, bounty paid
        VerifiedFailed, // Commissioner verified as failed, bounty withheld
        Disputed        // Task outcome is under formal dispute resolution
    }

    enum DisputeType {
        TaskVerification,       // Dispute over a task's success/failure
        FeedbackQuality,        // Dispute over negative feedback (not fully implemented in logic, conceptual)
        TrainingContribution    // Dispute over a training data contribution (not fully implemented in logic, conceptual)
    }

    enum ProposalStatus {
        Pending,        // Proposal is open for voting
        Approved,       // Proposal passed voting
        Rejected,       // Proposal failed voting
        Executed        // Proposal was successfully executed
    }

    struct Agent {
        address owner;
        string metadataURI; // IPFS hash or URL to agent's blueprint/description
        uint256 reputationScore; // Starts at a base, dynamically updated
        AgentStatus status;
        uint256 totalTasksCompleted;
        uint256 totalRewardsEarned;
        uint256 currentStake; // Amount of rewardToken staked
        uint256 lastActivityTime;
    }

    struct Task {
        uint256 id;
        address commissioner;
        uint256 agentID;
        string descriptionURI; // IPFS hash or URL to task description
        uint256 bounty; // Amount in rewardToken
        TaskStatus status;
        string submissionURI; // IPFS hash or URL to agent's submission
        uint256 deadline; // Timestamp
        uint256 verificationTime; // Timestamp of verification or dispute
        bool commissionerVerifiedSuccess; // True if commissioner marked success, false if failure
    }

    struct TrainingDataPool {
        uint256 id;
        address creator;
        string metadataURI; // Description of the data pool
        uint256 totalRewardAllocated; // Total rewardToken staked by contributors (their "share")
        uint256 totalRewardDistributed; // Total rewardToken claimed by contributors
        mapping(address => uint256) contributedRewardShare; // Tracks each contributor's initial staked share
        mapping(address => bool) hasClaimed; // Tracks if a contributor has claimed their share
        uint256 creationTime;
    }

    struct Dispute {
        uint256 id;
        DisputeType disputeType;
        uint256 referenceID; // ID of the Task, Feedback, or Pool being disputed
        address initiator;
        address counterparty;
        string reasonURI; // IPFS hash or URL for dispute reason
        string[] evidenceURIs; // Array of evidence URIs
        address winner; // Address of the party who won the dispute
        bool resolved;
        uint256 initiationTime;
        uint256 resolutionTime;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string descriptionURI; // URI to proposal details
        bytes calldataToExecute; // Function call to execute if proposal passes
        ProposalStatus status;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    // --- State Variables ---

    uint256 public nextAgentID = 1;
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) public agentsByOwner; // Track agents owned by an address

    uint256 public nextTaskID = 1;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => uint256[]) public agentTasks; // Track tasks per agent

    uint256 public nextPoolID = 1;
    mapping(uint256 => TrainingDataPool) public trainingDataPools;

    uint256 public nextDisputeID = 1;
    mapping(uint256 => Dispute) public disputes;

    uint256 public nextProposalID = 1;
    mapping(uint256 => Proposal) public proposals;

    uint256 public constant BASE_REPUTATION = 1000;
    uint256 public constant MIN_AGENT_STAKE = 100 * (10**18); // Example: 100 tokens (adjust decimals as needed)
    uint256 public constant REPUTATION_GAIN_SUCCESS = 50;
    uint256 public constant REPUTATION_LOSS_FAILURE = 100;
    uint256 public constant REPUTATION_GAIN_FEEDBACK_POSITIVE = 20;
    uint256 public constant REPUTATION_LOSS_FEEDBACK_NEGATIVE = 30;
    uint256 public constant DISPUTE_FEE_PERCENTAGE = 5; // 5% of bounty for task disputes, paid by disputer
    uint256 public proposalQuorumPercentage = 51; // 51% of votes for a proposal to pass (simple vote count)
    uint256 public votingPeriodDuration = 3 days; // Duration for proposals to be voted on (in seconds)

    // --- Events ---

    event AgentRegistered(uint256 agentID, address indexed owner, string metadataURI, uint256 timestamp);
    event AgentUpdated(uint256 indexed agentID, string newMetadataURI, uint256 timestamp);
    event AgentDeregistered(uint256 indexed agentID, address indexed owner, uint256 timestamp);
    event AgentStaked(uint256 indexed agentID, address indexed staker, uint256 amount, uint256 totalStake);
    event AgentUnstaked(uint256 indexed agentID, address indexed unstaker, uint256 amount, uint256 totalStake);

    event TaskCreated(uint256 taskID, address indexed commissioner, uint256 indexed agentID, uint256 bounty, uint256 deadline);
    event TaskResultSubmitted(uint256 indexed taskID, uint256 indexed agentID, string submissionURI);
    event TaskVerified(uint256 indexed taskID, address indexed commissioner, bool success, uint256 bountyReleased);
    event TaskDisputed(uint256 indexed taskID, address indexed party, string reasonURI);

    event AgentFeedbackSubmitted(uint256 indexed taskID, uint256 indexed agentID, address indexed trainer, uint8 rating);
    event ReputationUpdated(uint256 indexed agentID, uint256 newReputationScore);
    event TrainingDataPoolProposed(uint256 poolID, address indexed creator, string metadataURI);
    event TrainingDataContributed(uint256 indexed poolID, address indexed contributor, uint256 amount);
    event TrainingContributionRewardClaimed(uint256 indexed poolID, address indexed contributor, uint256 amount);
    event AgentSkillAttested(uint256 indexed agentID, address indexed owner, string attestationURI);

    event DisputeInitiated(uint256 disputeID, DisputeType indexed disputeType, uint256 indexed referenceID, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeID, address indexed submitter, string evidenceURI);
    event DisputeResolved(uint256 indexed disputeID, address indexed winner, uint256 resolutionTime);

    event ProposalCreated(uint256 proposalID, address indexed proposer, string descriptionURI);
    event VoteCast(uint256 indexed proposalID, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalID, uint256 executionTime);

    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _agentID) {
        require(agents[_agentID].owner == msg.sender, "Caller is not the agent owner");
        _;
    }

    modifier onlyCommissioner(uint256 _taskID) {
        require(tasks[_taskID].commissioner == msg.sender, "Caller is not the task commissioner");
        _;
    }

    modifier agentExists(uint256 _agentID) {
        require(agents[_agentID].owner != address(0), "Agent does not exist");
        _;
    }

    modifier taskExists(uint256 _taskID) {
        require(tasks[_taskID].commissioner != address(0), "Task does not exist");
        _;
    }

    modifier poolExists(uint256 _poolID) {
        require(trainingDataPools[_poolID].creator != address(0), "Training data pool does not exist");
        _;
    }

    modifier disputeExists(uint256 _disputeID) {
        require(disputes[_disputeID].initiator != address(0), "Dispute does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalID) {
        require(proposals[_proposalID].proposer != address(0), "Proposal does not exist");
        _;
    }

    modifier agentMustBeActive(uint256 _agentID) {
        require(agents[_agentID].status == AgentStatus.Active || agents[_agentID].status == AgentStatus.Staked, "Agent is not active");
        _;
    }

    modifier taskMustBeAssigned(uint256 _taskID) {
        require(tasks[_taskID].status == TaskStatus.Assigned, "Task is not assigned or already submitted");
        _;
    }

    modifier taskMustBeSubmitted(uint256 _taskID) {
        require(tasks[_taskID].status == TaskStatus.Submitted, "Task has not been submitted yet");
        _;
    }

    constructor(address _rewardTokenAddress) Ownable() {
        rewardToken = IERC20(_rewardTokenAddress);
    }

    // --- I. Core Management & Registration ---

    /**
     * @dev Registers a new AI agent blueprint.
     * @param _metadataURI URI pointing to the agent's descriptive metadata (e.g., IPFS hash).
     * @return agentID The ID of the newly registered agent.
     */
    function registerAgentBlueprint(string memory _metadataURI) public returns (uint256) {
        uint256 currentAgentID = nextAgentID++;
        Agent storage newAgent = agents[currentAgentID];
        newAgent.owner = msg.sender;
        newAgent.metadataURI = _metadataURI;
        newAgent.reputationScore = BASE_REPUTATION;
        newAgent.status = AgentStatus.Active;
        newAgent.lastActivityTime = block.timestamp;

        agentsByOwner[msg.sender].push(currentAgentID);

        emit AgentRegistered(currentAgentID, msg.sender, _metadataURI, block.timestamp);
        return currentAgentID;
    }

    /**
     * @dev Updates the metadata URI of an existing agent.
     * @param _agentID The ID of the agent to update.
     * @param _newMetadataURI The new URI for the agent's metadata.
     */
    function updateAgentBlueprint(uint256 _agentID, string memory _newMetadataURI) public
        onlyAgentOwner(_agentID)
        agentExists(_agentID)
    {
        agents[_agentID].metadataURI = _newMetadataURI;
        emit AgentUpdated(_agentID, _newMetadataURI, block.timestamp);
    }

    /**
     * @dev Marks an agent as deregistered, preventing it from accepting new tasks.
     *      Active tasks assigned to it will still be valid.
     * @param _agentID The ID of the agent to deregister.
     */
    function deregisterAgent(uint256 _agentID) public
        onlyAgentOwner(_agentID)
        agentExists(_agentID)
    {
        agents[_agentID].status = AgentStatus.Deregistered;
        // Consider adding logic to automatically unstake or handle pending tasks.
        emit AgentDeregistered(_agentID, msg.sender, block.timestamp);
    }

    /**
     * @dev Stakes tokens for an agent to make it eligible for certain tasks or to boost its visibility.
     *      Requires approval of tokens beforehand via `rewardToken.approve(address(this), _amount)`.
     * @param _agentID The ID of the agent to stake for.
     * @param _amount The amount of rewardToken to stake.
     */
    function stakeAgent(uint256 _agentID, uint256 _amount) public
        onlyAgentOwner(_agentID)
        agentExists(_agentID)
    {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        agents[_agentID].currentStake += _amount;
        if (agents[_agentID].currentStake >= MIN_AGENT_STAKE) {
            agents[_agentID].status = AgentStatus.Staked;
        }

        emit AgentStaked(_agentID, msg.sender, _amount, agents[_agentID].currentStake);
    }

    /**
     * @dev Unstakes tokens from an agent.
     * @param _agentID The ID of the agent to unstake from.
     * @param _amount The amount of rewardToken to unstake.
     */
    function unstakeAgent(uint256 _agentID, uint256 _amount) public
        onlyAgentOwner(_agentID)
        agentExists(_agentID)
    {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(agents[_agentID].currentStake >= _amount, "Insufficient staked amount");

        agents[_agentID].currentStake -= _amount;
        require(rewardToken.transfer(msg.sender, _amount), "Token transfer failed");

        if (agents[_agentID].currentStake < MIN_AGENT_STAKE && agents[_agentID].status == AgentStatus.Staked) {
            agents[_agentID].status = AgentStatus.Active; // Revert to Active if below minimum stake
        }

        emit AgentUnstaked(_agentID, msg.sender, _amount, agents[_agentID].currentStake);
    }

    // --- II. Task Commissioning & Execution ---

    /**
     * @dev Commissioner creates a new task for a specific agent.
     *      Requires approval of the bounty tokens beforehand via `rewardToken.approve(address(this), _bounty)`.
     * @param _agentID The ID of the agent to assign the task to.
     * @param _descriptionURI URI for the task description.
     * @param _bounty The rewardToken amount for completing the task.
     * @param _deadline The timestamp by which the task must be completed.
     * @return taskID The ID of the newly created task.
     */
    function createTask(
        uint256 _agentID,
        string memory _descriptionURI,
        uint256 _bounty,
284        uint256 _deadline
    ) public
        agentExists(_agentID)
        agentMustBeActive(_agentID)
        returns (uint256)
    {
        require(_bounty > 0, "Bounty must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(rewardToken.transferFrom(msg.sender, address(this), _bounty), "Bounty transfer failed");

        uint256 currentTaskID = nextTaskID++;
        tasks[currentTaskID] = Task({
            id: currentTaskID,
            commissioner: msg.sender,
            agentID: _agentID,
            descriptionURI: _descriptionURI,
            bounty: _bounty,
            status: TaskStatus.Assigned, // Task is directly assigned when created this way
            submissionURI: "",
            deadline: _deadline,
            verificationTime: 0,
            commissionerVerifiedSuccess: false
        });

        agentTasks[_agentID].push(currentTaskID);

        emit TaskCreated(currentTaskID, msg.sender, _agentID, _bounty, _deadline);
        return currentTaskID;
    }

    /**
     * @dev Agent owner submits the result of an assigned task.
     * @param _taskID The ID of the task.
     * @param _submissionURI URI pointing to the task result.
     */
    function submitTaskResult(uint256 _taskID, string memory _submissionURI) public
        taskExists(_taskID)
        onlyAgentOwner(tasks[_taskID].agentID)
        taskMustBeAssigned(_taskID)
    {
        require(block.timestamp <= tasks[_taskID].deadline, "Task submission past deadline");

        tasks[_taskID].submissionURI = _submissionURI;
        tasks[_taskID].status = TaskStatus.Submitted;

        emit TaskResultSubmitted(_taskID, tasks[_taskID].agentID, _submissionURI);
    }

    /**
     * @dev Commissioner verifies the task outcome, releasing bounty or marking failure.
     * @param _taskID The ID of the task.
     * @param _success True if task was completed successfully, false otherwise.
     */
    function verifyTaskResult(uint256 _taskID, bool _success) public
        taskExists(_taskID)
        onlyCommissioner(_taskID)
        taskMustBeSubmitted(_taskID)
    {
        Task storage task = tasks[_taskID];
        Agent storage agent = agents[task.agentID];

        task.verificationTime = block.timestamp;
        task.commissionerVerifiedSuccess = _success;

        if (_success) {
            task.status = TaskStatus.VerifiedSuccess;
            require(rewardToken.transfer(agent.owner, task.bounty), "Bounty payment failed");
            agent.reputationScore += REPUTATION_GAIN_SUCCESS;
            agent.totalTasksCompleted++;
            agent.totalRewardsEarned += task.bounty;
        } else {
            task.status = TaskStatus.VerifiedFailed;
            // Bounty stays in contract if failed, commissioner can't withdraw directly.
            // It will be handled during dispute resolution if any, or locked in the contract.
            agent.reputationScore -= REPUTATION_LOSS_FAILURE;
        }
        agent.lastActivityTime = block.timestamp;

        emit TaskVerified(_taskID, msg.sender, _success, _success ? task.bounty : 0);
        emit ReputationUpdated(task.agentID, agent.reputationScore);
    }

    /**
     * @dev Commissioner or agent disputes a task's verification/outcome.
     *      A dispute fee is deducted from the disputer.
     * @param _taskID The ID of the task.
     * @param _reasonURI URI for the reason of dispute.
     */
    function disputeTaskResult(uint256 _taskID, string memory _reasonURI) public
        taskExists(_taskID)
    {
        Task storage task = tasks[_taskID];
        require(task.status == TaskStatus.VerifiedSuccess || task.status == TaskStatus.VerifiedFailed || task.status == TaskStatus.Submitted, "Task is not in a disputable state");
        require(msg.sender == task.commissioner || msg.sender == agents[task.agentID].owner, "Only commissioner or agent owner can dispute");
        
        // Define a dispute window, e.g., 7 days after submission/verification
        require(block.timestamp < tasks[_taskID].verificationTime + 7 days || tasks[_taskID].status == TaskStatus.Submitted, "Dispute window closed");

        uint256 disputeFeeAmount = (task.bounty * DISPUTE_FEE_PERCENTAGE) / 100;
        require(rewardToken.transferFrom(msg.sender, address(this), disputeFeeAmount), "Dispute fee transfer failed");

        task.status = TaskStatus.Disputed;

        emit TaskDisputed(_taskID, msg.sender, _reasonURI);
        // Automatically initiate a formal dispute, which the guild owner (arbiter) will resolve.
        initiateDisputeResolution(_taskID, DisputeType.TaskVerification, msg.sender, (msg.sender == task.commissioner ? agents[task.agentID].owner : task.commissioner));
    }

    // --- III. Agent Reputation & Training ---

    /**
     * @dev Commissioner provides feedback on an agent's performance post-verification.
     *      This impacts agent reputation.
     * @param _taskID The ID of the task for which feedback is given.
     * @param _rating A rating from 0 (very bad) to 10 (excellent).
     * @param _commentURI URI for detailed comments.
     */
    function submitAgentFeedback(uint256 _taskID, uint8 _rating, string memory _commentURI) public
        taskExists(_taskID)
        onlyCommissioner(_taskID)
    {
        Task storage task = tasks[_taskID];
        require(task.status == TaskStatus.VerifiedSuccess || task.status == TaskStatus.VerifiedFailed, "Feedback can only be given for verified tasks");
        require(task.verificationTime > 0, "Task not yet verified");
        // Ensure feedback is within a reasonable window, e.g., 30 days after verification
        require(block.timestamp < task.verificationTime + 30 days, "Feedback window closed");
        require(_rating <= 10, "Rating must be between 0 and 10");

        Agent storage agent = agents[task.agentID];

        // Adjust reputation based on rating.
        if (_rating >= 7) {
            agent.reputationScore += REPUTATION_GAIN_FEEDBACK_POSITIVE;
        } else if (_rating <= 3) {
            // Ensure reputation does not go below zero, or a minimum threshold.
            if (agent.reputationScore > REPUTATION_LOSS_FEEDBACK_NEGATIVE) {
                agent.reputationScore -= REPUTATION_LOSS_FEEDBACK_NEGATIVE;
            } else {
                agent.reputationScore = 0;
            }
        }

        emit AgentFeedbackSubmitted(_taskID, task.agentID, msg.sender, _rating);
        emit ReputationUpdated(task.agentID, agent.reputationScore);
    }

    /**
     * @dev Creates a new training data pool where users can contribute data.
     * @param _metadataURI URI for the description of the training data pool.
     * @return poolID The ID of the newly created pool.
     */
    function proposeTrainingDataPool(string memory _metadataURI) public returns (uint256) {
        uint256 currentPoolID = nextPoolID++;
        trainingDataPools[currentPoolID] = TrainingDataPool({
            id: currentPoolID,
            creator: msg.sender,
            metadataURI: _metadataURI,
            totalRewardAllocated: 0,
            totalRewardDistributed: 0,
            creationTime: block.timestamp
        });

        emit TrainingDataPoolProposed(currentPoolID, msg.sender, _metadataURI);
        return currentPoolID;
    }

    /**
     * @dev Users contribute data/feedback to a pool. They receive a share of the pool's allocated reward.
     *      In this simplified model, a contributor `_rewardShare` is their self-funded contribution that they can claim back.
     *      Requires approval of the rewardToken beforehand via `rewardToken.approve(address(this), _rewardShare)`.
     * @param _poolID The ID of the training data pool.
     * @param _contributionURI URI for the contributed data/feedback (off-chain).
     * @param _rewardShare The amount of rewardToken the contributor adds to the pool, representing their claimable share.
     */
    function contributeToTrainingDataPool(uint256 _poolID, string memory _contributionURI, uint256 _rewardShare) public
        poolExists(_poolID)
    {
        require(_rewardShare > 0, "Reward share must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _rewardShare), "Token transfer for contribution failed");

        TrainingDataPool storage pool = trainingDataPools[_poolID];
        pool.totalRewardAllocated += _rewardShare;
        pool.contributedRewardShare[msg.sender] += _rewardShare;

        // _contributionURI is noted in the event log; specific on-chain storage for it is omitted for brevity.
        emit TrainingDataContributed(_poolID, msg.sender, _rewardShare);
    }

    /**
     * @dev Allows a contributor to claim their earned reward share from a training pool.
     *      In this simplified model, the "reward" is the re-claiming of their contributed "share".
     * @param _poolID The ID of the training data pool.
     */
    function claimTrainingContributionReward(uint256 _poolID) public
        poolExists(_poolID)
    {
        TrainingDataPool storage pool = trainingDataPools[_poolID];
        uint256 shareToClaim = pool.contributedRewardShare[msg.sender];
        require(shareToClaim > 0, "No reward share to claim");
        require(!pool.hasClaimed[msg.sender], "Reward already claimed for this contribution");

        pool.totalRewardDistributed += shareToClaim;
        pool.contributedRewardShare[msg.sender] = 0; // Reset share to prevent double claiming
        pool.hasClaimed[msg.sender] = true;

        require(rewardToken.transfer(msg.sender, shareToClaim), "Reward transfer failed");
        emit TrainingContributionRewardClaimed(_poolID, msg.sender, shareToClaim);
    }

    /**
     * @dev Agent owner attests to an agent's skill update after training (off-chain).
     *      This is a conceptual function to record on-chain that training has occurred,
     *      without verifying the training itself. Could trigger reputation boosts.
     * @param _agentID The ID of the agent.
     * @param _attestationURI URI for the attestation/proof of training (e.g., ZKP hash, report).
     */
    function attestAgentSkillUpdate(uint256 _agentID, string memory _attestationURI) public
        onlyAgentOwner(_agentID)
        agentExists(_agentID)
    {
        // For simplicity, a small reputation boost. In a real system, this could involve
        // verification of training outcomes or a more complex proof.
        agents[_agentID].reputationScore += 10; // Small conceptual boost
        agents[_agentID].lastActivityTime = block.timestamp;
        emit AgentSkillAttested(_agentID, msg.sender, _attestationURI);
        emit ReputationUpdated(_agentID, agents[_agentID].reputationScore);
    }

    // --- IV. Dispute Resolution & Governance ---

    /**
     * @dev Initiates a formal dispute process for various items (tasks, feedback, etc.).
     *      This function is called internally by `disputeTaskResult` or can be called by `owner()` for other dispute types.
     * @param _referenceID The ID of the item being disputed (TaskID, PoolID, etc.).
     * @param _type The type of dispute.
     * @param _initiator The address initiating the dispute.
     * @param _counterparty The address of the other party in the dispute.
     * @return disputeID The ID of the newly created dispute.
     */
    function initiateDisputeResolution(
        uint256 _referenceID,
        DisputeType _type,
        address _initiator,
        address _counterparty
    ) internal returns (uint256) { // Changed to internal, as it's primarily triggered by `disputeTaskResult`
        uint256 currentDisputeID = nextDisputeID++;
        disputes[currentDisputeID] = Dispute({
            id: currentDisputeID,
            disputeType: _type,
            referenceID: _referenceID,
            initiator: _initiator,
            counterparty: _counterparty,
            reasonURI: "", // Reason usually set by the caller of `disputeTaskResult`
            evidenceURIs: new string[](0),
            winner: address(0),
            resolved: false,
            initiationTime: block.timestamp,
            resolutionTime: 0
        });

        emit DisputeInitiated(currentDisputeID, _type, _referenceID, _initiator);
        return currentDisputeID;
    }

    /**
     * @dev Allows parties involved in a dispute to submit evidence.
     * @param _disputeID The ID of the dispute.
     * @param _evidenceURI URI pointing to the evidence (e.g., IPFS hash of documents, recordings).
     */
    function submitDisputeEvidence(uint256 _disputeID, string memory _evidenceURI) public
        disputeExists(_disputeID)
    {
        Dispute storage dispute = disputes[_disputeID];
        require(!dispute.resolved, "Dispute already resolved");
        require(msg.sender == dispute.initiator || msg.sender == dispute.counterparty, "Only parties involved can submit evidence");

        dispute.evidenceURIs.push(_evidenceURI);

        emit DisputeEvidenceSubmitted(_disputeID, msg.sender, _evidenceURI);
    }

    /**
     * @dev Resolves a dispute. This function is typically called by a designated resolver (e.g., `owner`).
     *      Adjusts reputation and handles bounty/stake based on resolution.
     * @param _disputeID The ID of the dispute to resolve.
     * @param _winner The address of the party who won the dispute.
     */
    function resolveDispute(uint256 _disputeID, address _winner) public
        onlyOwner // Only the Guild owner can resolve disputes for this simplified version
        disputeExists(_disputeID)
    {
        Dispute storage dispute = disputes[_disputeID];
        require(!dispute.resolved, "Dispute already resolved");
        require(_winner == dispute.initiator || _winner == dispute.counterparty, "Winner must be one of the dispute parties");

        dispute.winner = _winner;
        dispute.resolved = true;
        dispute.resolutionTime = block.timestamp;

        // Apply consequences based on dispute type and winner
        if (dispute.disputeType == DisputeType.TaskVerification) {
            Task storage task = tasks[dispute.referenceID];
            Agent storage agent = agents[task.agentID];

            if (_winner == agent.owner) { // Agent won the dispute (e.g., commissioner wrongly failed)
                // If bounty was withheld, transfer to agent. If already transferred, commissioner needs to pay back.
                // For simplicity: if agent wins, bounty is released to them.
                if (task.status == TaskStatus.Disputed) { // Only transfer if bounty is still in contract.
                     require(rewardToken.transfer(agent.owner, task.bounty), "Bounty payment failed on dispute resolution");
                }
                agent.reputationScore += (REPUTATION_GAIN_SUCCESS * 2); // Bigger boost for winning dispute
                task.status = TaskStatus.VerifiedSuccess;
            } else if (_winner == task.commissioner) { // Commissioner won the dispute (e.g., agent submitted bad work)
                // If bounty was already transferred (e.g., commissioner disputed a "verified success"), agent needs to return it.
                // This requires more complex logic for clawbacks or bond usage.
                // For simplicity: agent loses reputation significantly. Bounty stays with contract if not already paid.
                agent.reputationScore -= (REPUTATION_LOSS_FAILURE * 2); // Bigger loss for losing dispute
                task.status = TaskStatus.VerifiedFailed;
            }
            emit ReputationUpdated(task.agentID, agent.reputationScore);
        }
        // Other dispute types can have their own logic for rewards/penalties

        emit DisputeResolved(_disputeID, _winner, block.timestamp);
    }

    /**
     * @dev Proposes a change to guild parameters. Requires a specific proposal structure.
     *      Only guild members with sufficient stake/reputation could propose in a real system.
     *      For simplicity, `msg.sender` can propose.
     * @param _descriptionURI URI for the proposal details.
     * @param _calldata The calldata for the function to execute if the proposal passes.
     *                  Example: `abi.encodeWithSelector(this.setProposalQuorumPercentage.selector, 60)`
     * @return proposalID The ID of the newly created proposal.
     */
    function proposeGuildParameterChange(string memory _descriptionURI, bytes memory _calldata) public returns (uint256) {
        uint256 currentProposalID = nextProposalID++;
        proposals[currentProposalID] = Proposal({
            id: currentProposalID,
            proposer: msg.sender,
            descriptionURI: _descriptionURI,
            calldataToExecute: _calldata,
            status: ProposalStatus.Pending,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)()
        });

        emit ProposalCreated(currentProposalID, msg.sender, _descriptionURI);
        return currentProposalID;
    }

    /**
     * @dev Allows eligible members to vote on an active proposal.
     *      Eligibility: e.g., having a registered agent, or holding minimum stake/tokens.
     *      For simplicity, anyone can vote.
     * @param _proposalID The ID of the proposal to vote on.
     * @param _support True for "yes", false for "no".
     */
    function voteOnProposal(uint256 _proposalID, bool _support) public
        proposalExists(_proposalID)
    {
        Proposal storage proposal = proposals[_proposalID];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in pending state");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is not active");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(_proposalID, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully voted-on proposal. Only callable after voting period ends.
     * @param _proposalID The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalID) public
        onlyOwner // For simplicity, only owner can execute after voting, to prevent griefing
        proposalExists(_proposalID)
    {
        Proposal storage proposal = proposals[_proposalID];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(block.timestamp > proposal.voteEndTime, "Voting period is not over yet");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // Check for sufficient votes (quorum) and majority
        if (totalVotes == 0 || (proposal.votesFor * 100 / totalVotes) < proposalQuorumPercentage) {
            proposal.status = ProposalStatus.Rejected;
            revert("Proposal did not meet quorum or majority");
        }

        proposal.status = ProposalStatus.Approved; // Mark as approved before execution attempt

        (bool success, ) = address(this).call(proposal.calldataToExecute);
        require(success, "Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalID, block.timestamp);
    }

    // --- V. Query & Utility Functions (Read-Only) ---

    /**
     * @dev Returns all details of a specific AI agent.
     * @param _agentID The ID of the agent.
     * @return Agent struct details.
     */
    function getAgentDetails(uint256 _agentID) public view agentExists(_agentID) returns (Agent memory) {
        return agents[_agentID];
    }

    /**
     * @dev Returns all details of a specific task.
     * @param _taskID The ID of the task.
     * @return Task struct details.
     */
    function getTaskDetails(uint256 _taskID) public view taskExists(_taskID) returns (Task memory) {
        return tasks[_taskID];
    }

    /**
     * @dev Returns a list of task IDs associated with an agent.
     * @param _agentID The ID of the agent.
     * @return An array of task IDs.
     */
    function getAgentTasks(uint256 _agentID) public view agentExists(_agentID) returns (uint256[] memory) {
        return agentTasks[_agentID];
    }

    /**
     * @dev Returns a list of tasks that are currently pending submission or verification for a specific agent.
     * @param _agentID The ID of the agent.
     * @return An array of task IDs.
     */
    function getPendingTasksForAgent(uint256 _agentID) public view agentExists(_agentID) returns (uint256[] memory) {
        uint256[] storage allAgentTasks = agentTasks[_agentID];
        uint256[] memory pending;
        uint256 count = 0;

        for (uint256 i = 0; i < allAgentTasks.length; i++) {
            TaskStatus status = tasks[allAgentTasks[i]].status;
            if (status == TaskStatus.Assigned || status == TaskStatus.Submitted) {
                count++;
            }
        }

        pending = new uint256[](count);
        uint256 current = 0;
        for (uint256 i = 0; i < allAgentTasks.length; i++) {
            TaskStatus status = tasks[allAgentTasks[i]].status;
            if (status == TaskStatus.Assigned || status == TaskStatus.Submitted) {
                pending[current++] = allAgentTasks[i];
            }
        }
        return pending;
    }

    /**
     * @dev Returns an agent's current reputation score.
     * @param _agentID The ID of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(uint256 _agentID) public view agentExists(_agentID) returns (uint256) {
        return agents[_agentID].reputationScore;
    }

    /**
     * @dev Set proposal quorum percentage. Only callable by the Guild owner.
     * @param _newPercentage New quorum percentage (0-100).
     */
    function setProposalQuorumPercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage <= 100, "Percentage cannot exceed 100");
        proposalQuorumPercentage = _newPercentage;
    }

    /**
     * @dev Set voting period duration. Only callable by the Guild owner.
     * @param _newDuration New voting period duration in seconds.
     */
    function setVotingPeriodDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Duration must be positive");
        votingPeriodDuration = _newDuration;
    }
}

```