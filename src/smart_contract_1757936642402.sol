The smart contract presented here, **CognitoNet**, is designed to be a decentralized AI agent and task orchestration network. It allows users to post tasks requiring AI computation, and registered AI agents to bid on and execute these tasks. A core advanced concept is its "Challenge & Consensus" mechanism for verifying AI outputs, using a system of whitelisted "jury members" to resolve disputes. Agent identities are conceptualized as Soulbound Tokens (SBTs), linked to performance and staking.

This contract integrates elements of decentralized identity, verifiable computation (via challenge system), staking, escrow, and dynamic parameter governance, all centered around facilitating decentralized AI services.

---

### **Contract: CognitoNet**

**Outline and Function Summary:**

**I. Token & Core System Setup**
This section manages foundational parameters and the underlying native token (`CognitoToken`).

1.  `constructor(address _cognitoTokenAddress)`: Initializes the CognitoNet with its native token address and sets initial configurable parameters like minimum agent stake, challenge fee, and dispute durations.
2.  `updateMinAgentStake(uint256 _newAmount)`: Allows the contract owner (governance) to adjust the minimum token stake required for AI agents to register and participate.
3.  `updateChallengeFee(uint256 _newAmount)`: Allows the contract owner to adjust the fee required from challengers to initiate a dispute over a submitted task result.
4.  `updateChallengePeriod(uint256 _newDuration)`: Allows the contract owner to modify the duration (in seconds) during which a submitted task result can be challenged.
5.  `updateUnstakeCooldown(uint256 _newDuration)`: Allows the contract owner to change the cooldown period before an agent's requested unstaked funds can be withdrawn.
6.  `setJuryMember(address _member, bool _isJury)`: Allows the contract owner to add or remove addresses from the whitelist of jury members who can vote on challenges.

**II. AI Agent Management (SBT-like identities)**
This section focuses on the lifecycle and management of AI agents, whose identities are conceptually soulbound (unique and tied to an address).

7.  `registerAgent(string memory _name, string memory _metadataURI)`: Registers a new AI agent, conceptually minting a Soulbound Token (SBT) as its identity. Requires the `minAgentStake` to be approved and transferred.
8.  `updateAgentProfile(uint256 _agentId, string memory _newName, string memory _newMetadataURI)`: Allows an agent's owner to update its public-facing name and metadata URI.
9.  `stakeAgentFunds(uint256 _agentId, uint256 _amount)`: Enables an agent's owner to increase the agent's total staked amount, potentially boosting its reputation or eligibility for more demanding tasks.
10. `requestUnstakeAgentFunds(uint256 _agentId, uint256 _amount)`: Initiates a request to unstake a specified amount from an agent's stake, triggering a cooldown period.
11. `withdrawUnstakedFunds(uint256 _agentId)`: Allows an agent's owner to withdraw funds that have passed their `unstakeCooldownDuration`.
12. `slashAgent(uint256 _agentId, uint256 _amount, string memory _reasonURI)`: (Internal) Penalizes an agent by reducing its stake, typically called as part of the `finalizeChallenge` process for proven misbehavior.
13. `deactivateAgent(uint256 _agentId)`: Allows an agent's owner to temporarily deactivate their agent, making it ineligible for new tasks.
14. `reactivateAgent(uint256 _agentId)`: Allows an agent's owner to reactivate their agent, making it eligible for new tasks again.

**III. Task Management**
This section handles the creation, funding, bidding, and assignment of AI tasks.

15. `createTask(string memory _descriptionURI, uint256 _rewardAmount, uint256 _deadline, bytes32 _inputHash)`: Allows any user to create a new AI task, defining its parameters, reward, deadline, and a hash of the input data.
16. `fundTask(uint256 _taskId)`: Enables the task creator to transfer the specified `rewardAmount` for an open task to the contract, putting it into escrow.
17. `bidForTask(uint256 _taskId, uint256 _agentId)`: Allows a registered AI agent to express interest in executing an open and funded task.
18. `selectAgentForTask(uint256 _taskId, uint256 _agentId)`: The task creator selects one of the bidding agents to execute the task.
19. `submitTaskResult(uint255 _taskId, bytes32 _outputHash, string memory _proofURI)`: The selected agent submits the hash of its computed output and an optional proof, starting the `challengePeriodDuration`.
20. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel an open or funded task if no agent has been selected, reclaiming any locked funds.

**IV. Verification & Dispute Resolution (Advanced Concept)**
This is the innovative core, providing a mechanism for verifying AI outputs and resolving disputes.

21. `challengeTaskResult(uint256 _taskId, string memory _challengeProofURI)`: Any network participant can initiate a challenge against a submitted task result during its challenge period, paying a `challengeFee`.
22. `submitChallengeVote(uint256 _challengeId, bool _isAgentCorrect)`: A designated jury member casts their vote on whether the challenged agent's result is correct or incorrect.
23. `finalizeChallenge(uint256 _challengeId)`: Resolves a challenge based on the aggregated jury votes after the challenge period. If the challenge is successful, the agent is slashed; otherwise, the challenger loses their fee.
24. `claimTaskReward(uint256 _taskId)`: The assigned agent claims its `rewardAmount` after successfully completing a task and either passing the challenge period unchallenged or winning a challenge.
25. `reclaimTaskFunds(uint256 _taskId)`: Allows the task creator to reclaim the `rewardAmount` if the task was canceled, expired without completion, or the assigned agent failed and was slashed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// SafeMath is implicitly included in Solidity 0.8+ for uint256 operations,
// but explicitly importing for clarity or if using older Solidity versions.
// However, the standard practice in 0.8+ is to remove it unless for specific scenarios.
// For this contract, native overflow checks are relied upon.

// Custom Errors for better UX and gas efficiency
error InvalidAgentId();
error AgentAlreadyRegistered();
error AgentNotRegistered();
error InsufficientStake();
error NotAgentOwner();
error NotTaskCreator();
error TaskNotFound();
error TaskNotFunded();
error TaskAlreadyFunded();
error TaskAlreadyAssigned();
error TaskNotAssigned();
error TaskDeadlinePassed();
error TaskAlreadySubmitted();
error TaskNotSubmitted();
error NoActiveBid();
error AgentAlreadyBid();
error TaskStillChallenging();
error ChallengeNotFound();
error ChallengePeriodNotOver();
error ChallengePeriodActive();
error AlreadyVoted();
error NotJuryMember();
error UnstakeAmountTooHigh();
error UnstakeCooldownActive();
error NoPendingUnstake();
error TaskCannotBeCanceled();
error TaskCannotBeReclaimed();
error InsufficientBalance();
error InsufficientJuryVotes(); // Custom error for not enough jury votes to finalize

// Interface for the CognitoToken, assumed to be a standard ERC20 token
interface ICognitoToken is IERC20 {}

contract CognitoNet is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token contract instance that CognitoNet will interact with
    ICognitoToken public immutable cognitoToken;

    // Counters for unique IDs across different entities
    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _challengeIds;

    // --- Configuration Parameters (Governance Controlled by Owner) ---
    uint256 public minAgentStake;            // Minimum token amount an AI agent must stake
    uint256 public challengeFee;             // Fee required to challenge a task result
    uint256 public challengePeriodDuration;  // Duration (in seconds) for which results can be challenged
    uint256 public unstakeCooldownDuration;  // Duration (in seconds) before unstaked funds can be withdrawn
    uint256 public minJuryVotesRequired;     // Minimum number of jury votes needed to finalize a challenge

    // --- Data Structures ---

    // Enum to represent the current status of a task
    enum TaskStatus {
        Open,               // Task created, not yet funded
        Funded,             // Task funded, open for bids
        Assigned,           // Agent selected, awaiting result
        ResultSubmitted,    // Result submitted, challenge period active
        Challenged,         // Result is under dispute
        Verified,           // Result verified (either unchallenged or won challenge)
        Failed,             // Agent failed or task creator reclaimed funds
        Canceled            // Task canceled by creator
    }

    // Struct to store information about an AI agent
    struct Agent {
        string name;            // Name of the AI agent
        string metadataURI;     // URI (e.g., IPFS hash) for detailed agent/model description
        address owner;          // Wallet address of the agent owner
        uint256 stake;          // Total staked amount by this agent
        bool isActive;          // True if the agent is active and eligible for tasks
    }

    // Struct to store information about an AI task
    struct Task {
        string descriptionURI;      // URI for off-chain task details
        uint256 rewardAmount;       // Reward for the agent upon successful completion
        uint256 deadline;           // Timestamp by which agent must submit result
        bytes32 inputHash;          // Hash of the input data for the AI task
        address creator;            // Wallet address of the task creator
        uint256 selectedAgentId;    // ID of the selected agent (0 if none)
        bytes32 outputHash;         // Hash of the output data submitted by agent
        string proofURI;            // URI to proof of execution/verification
        uint252 resultSubmissionTime; // Timestamp when result was submitted
        TaskStatus status;          // Current status of the task
        uint256 activeChallengeId;  // ID of the current active challenge for this task (0 if none)
    }

    // Struct to store information about a challenge to a task result
    struct Challenge {
        uint256 taskId;                 // ID of the task being challenged
        uint256 agentId;                // ID of the agent whose result is challenged
        string challengeProofURI;       // URI to challenger's proof/reasoning
        uint256 challengeStartTime;     // Timestamp when the challenge was initiated
        address challenger;             // Address of the challenger
        mapping(address => bool) juryVotes; // Maps jury member address to a boolean (true if voted for agent, false for challenger)
        uint256 votesForChallenger;     // Count of votes supporting the challenge
        uint256 votesForAgent;          // Count of votes supporting the agent's result
        bool resolved;                  // True if the challenge has been finalized
        bool challengeSuccessful;       // True if the challenge was successful (challenger won)
    }

    // Struct to represent a pending unstake request from an agent
    struct UnstakeRequest {
        uint256 amount;        // Amount requested to unstake
        uint256 cooldownEnd;   // Timestamp when the cooldown period ends
    }

    // --- Mappings ---

    mapping(uint256 => Agent) public agents;              // agentId => Agent struct
    mapping(address => uint256) public agentOfOwner;      // owner address => agentId (assuming one agent per owner for simplicity)
    mapping(uint256 => mapping(address => bool)) public agentBids; // taskId => owner address => true (if agent bid)
    mapping(uint256 => uint256[]) public taskBidsByAgentId; // taskId => array of agentIds that have bid

    mapping(uint256 => Task) public tasks;                // taskId => Task struct
    mapping(uint256 => Challenge) public challenges;      // challengeId => Challenge struct

    mapping(uint256 => UnstakeRequest[]) public agentPendingUnstakes; // agentId => array of pending unstake requests

    mapping(address => bool) public isJuryMember;         // Whitelisted jury members (address => true)

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, string metadataURI);
    event AgentProfileUpdated(uint256 indexed agentId, string newName, string newMetadataURI);
    event AgentStaked(uint256 indexed agentId, uint256 amount, uint256 newTotalStake);
    event UnstakeRequested(uint256 indexed agentId, uint256 amount, uint256 cooldownEnd);
    event UnstakeWithdrawn(uint256 indexed agentId, uint256 amount);
    event AgentSlashing(uint256 indexed agentId, uint256 amount, string reasonURI);
    event AgentDeactivated(uint256 indexed agentId);
    event AgentReactivated(uint256 indexed agentId);

    event TaskCreated(uint256 indexed taskId, address indexed creator, string descriptionURI, uint256 rewardAmount, uint256 deadline, bytes32 inputHash);
    event TaskFunded(uint256 indexed taskId, uint256 amount);
    event TaskBid(uint256 indexed taskId, uint256 indexed agentId);
    event AgentSelected(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 outputHash, string proofURI);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bytes32 outputHash);
    event TaskCanceled(uint256 indexed taskId);
    event TaskFundsReclaimed(uint256 indexed taskId, address indexed recipient, uint256 amount);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed taskId, address indexed challenger, string challengeProofURI);
    event ChallengeVoteSubmitted(uint256 indexed challengeId, address indexed voter, bool isAgentCorrect);
    event ChallengeFinalized(uint256 indexed challengeId, uint256 indexed taskId, bool challengeSuccessful);
    event JuryMemberAdded(address indexed member);
    event JuryMemberRemoved(address indexed member);


    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        if (agents[_agentId].owner != msg.sender) revert NotAgentOwner();
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        if (tasks[_taskId].creator != msg.sender) revert NotTaskCreator();
        _;
    }

    modifier onlyJury() {
        if (!isJuryMember[msg.sender]) revert NotJuryMember();
        _;
    }


    // --- Constructor ---
    /**
     * @dev Initializes the CognitoNet contract.
     * @param _cognitoTokenAddress The address of the CognitoToken (ERC20) contract.
     */
    constructor(address _cognitoTokenAddress) Ownable(msg.sender) {
        require(_cognitoTokenAddress != address(0), "Invalid token address");
        cognitoToken = ICognitoToken(_cognitoTokenAddress);

        // Set initial default parameters (can be changed by owner/governance)
        minAgentStake = 1000 ether; // Example: 1000 CTK
        challengeFee = 100 ether;   // Example: 100 CTK
        challengePeriodDuration = 2 days; // 2 days
        unstakeCooldownDuration = 7 days; // 7 days
        minJuryVotesRequired = 3;   // At least 3 jury votes for a challenge decision
    }

    // --- I. Token & Core System Setup ---

    /**
     * @dev Updates the minimum stake required for AI agents to register and participate.
     * Callable only by the contract owner (governance).
     * @param _newAmount The new minimum stake amount.
     */
    function updateMinAgentStake(uint256 _newAmount) external onlyOwner {
        minAgentStake = _newAmount;
    }

    /**
     * @dev Updates the fee required to challenge a task result.
     * Callable only by the contract owner (governance).
     * @param _newAmount The new challenge fee.
     */
    function updateChallengeFee(uint256 _newAmount) external onlyOwner {
        challengeFee = _newAmount;
    }

    /**
     * @dev Updates the duration of the challenge period for task results.
     * Callable only by the contract owner (governance).
     * @param _newDuration The new challenge period duration in seconds.
     */
    function updateChallengePeriod(uint256 _newDuration) external onlyOwner {
        challengePeriodDuration = _newDuration;
    }

    /**
     * @dev Updates the cooldown duration for unstaking agent funds.
     * Callable only by the contract owner (governance).
     * @param _newDuration The new unstake cooldown duration in seconds.
     */
    function updateUnstakeCooldown(uint256 _newDuration) external onlyOwner {
        unstakeCooldownDuration = _newDuration;
    }
    
    /**
     * @dev Adds or removes an address from the jury whitelist.
     * Only whitelisted addresses can submit votes on challenges.
     * Callable only by the contract owner (governance).
     * @param _member The address of the jury member.
     * @param _isJury True to add as a jury member, false to remove.
     */
    function setJuryMember(address _member, bool _isJury) external onlyOwner {
        isJuryMember[_member] = _isJury;
        if (_isJury) {
            emit JuryMemberAdded(_member);
        } else {
            emit JuryMemberRemoved(_member);
        }
    }

    // --- II. AI Agent Management ---

    /**
     * @dev Registers a new AI agent with the network.
     * Mints a conceptual Soulbound Token (SBT) identity, where the `_agentId`
     * represents this unique, non-transferable identity tied to the `msg.sender`.
     * Requires `minAgentStake` to be approved and transferred to this contract.
     * @param _name The human-readable name of the AI agent.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS) for the agent's model/capabilities.
     */
    function registerAgent(string memory _name, string memory _metadataURI) external {
        if (agentOfOwner[msg.sender] != 0) revert AgentAlreadyRegistered();
        // Check if sender has enough tokens AND has approved this contract.
        // transferFrom will revert if balance or allowance is insufficient.
        if (!cognitoToken.transferFrom(msg.sender, address(this), minAgentStake)) revert InsufficientBalance();

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        agents[newAgentId] = Agent({
            name: _name,
            metadataURI: _metadataURI,
            owner: msg.sender,
            stake: minAgentStake,
            isActive: true
        });
        agentOfOwner[msg.sender] = newAgentId; // Link owner to agent ID

        emit AgentRegistered(newAgentId, msg.sender, _name, _metadataURI);
        emit AgentStaked(newAgentId, minAgentStake, minAgentStake);
    }

    /**
     * @dev Allows an agent's owner to update its profile information.
     * @param _agentId The ID of the agent to update.
     * @param _newName The new name for the agent.
     * @param _newMetadataURI The new URI for agent metadata.
     */
    function updateAgentProfile(uint256 _agentId, string memory _newName, string memory _newMetadataURI) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        agent.name = _newName;
        agent.metadataURI = _newMetadataURI;
        emit AgentProfileUpdated(_agentId, _newName, _newMetadataURI);
    }

    /**
     * @dev Allows an agent's owner to increase its stake.
     * Requires `_amount` to be approved and transferred to this contract.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of tokens to stake.
     */
    function stakeAgentFunds(uint256 _agentId, uint256 _amount) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (!cognitoToken.transferFrom(msg.sender, address(this), _amount)) revert InsufficientBalance();
        agent.stake += _amount; // Using native addition (0.8.0+ has overflow checks)
        emit AgentStaked(_agentId, _amount, agent.stake);
    }

    /**
     * @dev Agent's owner requests to unstake funds, initiating a cooldown period.
     * The funds are not immediately available for withdrawal.
     * @param _agentId The ID of the agent.
     * @param _amount The amount to request for unstaking.
     */
    function requestUnstakeAgentFunds(uint256 _agentId, uint256 _amount) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.stake < _amount) revert UnstakeAmountTooHigh();
        
        agent.stake -= _amount; // Reduce active stake
        agentPendingUnstakes[_agentId].push(UnstakeRequest({
            amount: _amount,
            cooldownEnd: block.timestamp + unstakeCooldownDuration
        }));
        emit UnstakeRequested(_agentId, _amount, block.timestamp + unstakeCooldownDuration);
    }

    /**
     * @dev Allows an agent's owner to withdraw funds after their unstake cooldown period has ended.
     * Iterates through pending requests and processes all eligible ones.
     * @param _agentId The ID of the agent.
     */
    function withdrawUnstakedFunds(uint256 _agentId) external onlyAgentOwner(_agentId) {
        UnstakeRequest[] storage requests = agentPendingUnstakes[_agentId];
        uint256 totalWithdrawn = 0;
        uint256 i = 0;
        // Iterate and remove eligible requests
        while (i < requests.length) {
            if (block.timestamp >= requests[i].cooldownEnd) {
                totalWithdrawn += requests[i].amount;
                // Efficiently remove element by swapping with last and popping
                requests[i] = requests[requests.length - 1];
                requests.pop();
            } else {
                i++;
            }
        }

        if (totalWithdrawn == 0) revert NoPendingUnstake();
        if (!cognitoToken.transfer(msg.sender, totalWithdrawn)) revert InsufficientBalance();
        emit UnstakeWithdrawn(_agentId, totalWithdrawn);
    }

    /**
     * @dev Internally slashes an agent's stake. Used within `finalizeChallenge`.
     * The slashed funds are sent to the zero address (burned in this implementation).
     * @param _agentId The ID of the agent to slash.
     * @param _amount The amount of stake to remove.
     * @param _reasonURI URI explaining the reason for slashing.
     */
    function slashAgent(uint256 _agentId, uint256 _amount, string memory _reasonURI) internal {
        Agent storage agent = agents[_agentId];
        uint256 actualSlashAmount = _amount;
        if (agent.stake < _amount) {
            actualSlashAmount = agent.stake; // Cap slash amount to available stake
        }
        agent.stake -= actualSlashAmount;
        // Funds from slashing are burned in this example. Could be sent to a treasury.
        if (!cognitoToken.transfer(address(0xdead), actualSlashAmount)) revert InsufficientBalance(); // Simulate burning
        emit AgentSlashing(_agentId, actualSlashAmount, _reasonURI);
    }
    
    /**
     * @dev Allows an agent owner to deactivate their agent.
     * A deactivated agent cannot bid on new tasks.
     * @param _agentId The ID of the agent to deactivate.
     */
    function deactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        agents[_agentId].isActive = false;
        emit AgentDeactivated(_agentId);
    }

    /**
     * @dev Allows an agent owner to reactivate their agent.
     * A reactivated agent becomes eligible for new tasks.
     * @param _agentId The ID of the agent to reactivate.
     */
    function reactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        agents[_agentId].isActive = true;
        emit AgentReactivated(_agentId);
    }

    // --- III. Task Management ---

    /**
     * @dev Creates a new AI task. The reward can be funded later using `fundTask`.
     * @param _descriptionURI URI pointing to off-chain task description (e.g., IPFS).
     * @param _rewardAmount The total reward for the agent upon successful completion.
     * @param _deadline The timestamp by which the agent must submit the result.
     * @param _inputHash Hash of the input data for the task, to ensure integrity.
     */
    function createTask(
        string memory _descriptionURI,
        uint256 _rewardAmount,
        uint256 _deadline,
        bytes32 _inputHash
    ) external {
        if (_deadline <= block.timestamp) revert TaskDeadlinePassed();

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            descriptionURI: _descriptionURI,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            inputHash: _inputHash,
            creator: msg.sender,
            selectedAgentId: 0,
            outputHash: bytes32(0),
            proofURI: "",
            resultSubmissionTime: 0,
            status: TaskStatus.Open,
            activeChallengeId: 0
        });

        emit TaskCreated(newTaskId, msg.sender, _descriptionURI, _rewardAmount, _deadline, _inputHash);
    }

    /**
     * @dev Funds an existing task created earlier. Required before an agent can be selected.
     * Requires the `rewardAmount` for the task to be approved and transferred from the creator.
     * @param _taskId The ID of the task to fund.
     */
    function fundTask(uint256 _taskId) external onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Open) revert TaskAlreadyFunded();
        if (task.rewardAmount == 0) revert TaskNotFound(); // Should imply task doesn't exist or is invalid if reward is 0

        if (!cognitoToken.transferFrom(msg.sender, address(this), task.rewardAmount)) revert InsufficientBalance();
        task.status = TaskStatus.Funded;

        emit TaskFunded(_taskId, task.rewardAmount);
    }

    /**
     * @dev Allows a registered and active AI agent to bid for an open and funded task.
     * @param _taskId The ID of the task to bid on.
     * @param _agentId The ID of the agent bidding.
     */
    function bidForTask(uint256 _taskId, uint256 _agentId) external onlyAgentOwner(_agentId) {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        if (task.status != TaskStatus.Funded) revert TaskNotFunded();
        if (block.timestamp >= task.deadline) revert TaskDeadlinePassed(); // Bidding should stop by deadline
        if (!agent.isActive || agent.stake < minAgentStake) revert InsufficientStake(); // Agent must be active and staked
        if (agentBids[_taskId][msg.sender]) revert AgentAlreadyBid(); // Prevent multiple bids from same agent owner

        taskBidsByAgentId[_taskId].push(_agentId);
        agentBids[_taskId][msg.sender] = true;

        emit TaskBid(_taskId, _agentId);
    }

    /**
     * @dev Task creator selects one of the bidding agents to execute the task.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent selected.
     */
    function selectAgentForTask(uint256 _taskId, uint256 _agentId) external onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId]; // Get agent details

        if (task.status != TaskStatus.Funded) revert TaskNotFunded();
        if (block.timestamp >= task.deadline) revert TaskDeadlinePassed();
        if (task.selectedAgentId != 0) revert TaskAlreadyAssigned(); // Task already has an agent
        if (!agentBids[_taskId][agent.owner]) revert NoActiveBid(); // Selected agent must have actually bid
        if (!agent.isActive) revert InvalidAgentId(); // Agent must be active at selection time

        task.selectedAgentId = _agentId;
        task.status = TaskStatus.Assigned;

        // In a more complex system, a portion of the agent's stake might be
        // explicitly locked here. For simplicity, we rely on the overall stake
        // and slashing for accountability.

        emit AgentSelected(_taskId, _agentId);
    }

    /**
     * @dev The selected agent submits its computed result for the task.
     * This action starts the `challengePeriodDuration`.
     * @param _taskId The ID of the task.
     * @param _outputHash Hash of the output data produced by the AI.
     * @param _proofURI URI pointing to any proof of computation/execution.
     */
    function submitTaskResult(uint256 _taskId, bytes32 _outputHash, string memory _proofURI) external {
        Task storage task = tasks[_taskId];
        // Ensure sender is the owner of the selected agent for this task
        if (task.selectedAgentId == 0 || agents[task.selectedAgentId].owner != msg.sender) revert TaskNotAssigned();
        if (task.status != TaskStatus.Assigned) revert TaskAlreadySubmitted();
        if (block.timestamp > task.deadline) revert TaskDeadlinePassed(); // Agent missed deadline

        task.outputHash = _outputHash;
        task.proofURI = _proofURI;
        task.resultSubmissionTime = block.timestamp;
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(_taskId, task.selectedAgentId, _outputHash, _proofURI);
    }

    /**
     * @dev Allows the task creator to cancel an open or funded task if no agent has been selected.
     * If the task was funded, the `rewardAmount` is returned to the creator.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Open && task.status != TaskStatus.Funded) revert TaskCannotBeCanceled();
        if (task.selectedAgentId != 0) revert TaskCannotBeCanceled(); // Cannot cancel if an agent is selected

        if (task.status == TaskStatus.Funded) {
            if (!cognitoToken.transfer(task.creator, task.rewardAmount)) revert InsufficientBalance();
            emit TaskFundsReclaimed(_taskId, task.creator, task.rewardAmount);
        }
        task.status = TaskStatus.Canceled;
        emit TaskCanceled(_taskId);
    }

    // --- IV. Verification & Dispute Resolution ---

    /**
     * @dev Any network participant can challenge a submitted result during the challenge period.
     * Requires `challengeFee` to be approved and transferred from the challenger to this contract.
     * @param _taskId The ID of the task whose result is being challenged.
     * @param _challengeProofURI URI pointing to evidence supporting the challenge.
     */
    function challengeTaskResult(uint256 _taskId, string memory _challengeProofURI) external {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.ResultSubmitted) revert TaskNotSubmitted();
        // The challenge period must be active (not yet ended)
        if (block.timestamp >= task.resultSubmissionTime + challengePeriodDuration) revert ChallengePeriodNotOver();

        if (!cognitoToken.transferFrom(msg.sender, address(this), challengeFee)) revert InsufficientBalance();

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            taskId: _taskId,
            agentId: task.selectedAgentId,
            challengeProofURI: _challengeProofURI,
            challengeStartTime: block.timestamp,
            challenger: msg.sender,
            votesForChallenger: 0, // juryVotes mapping is initialized empty
            votesForAgent: 0,
            resolved: false,
            challengeSuccessful: false
        });

        task.status = TaskStatus.Challenged;
        task.activeChallengeId = newChallengeId;

        emit ChallengeInitiated(newChallengeId, _taskId, msg.sender, _challengeProofURI);
    }

    /**
     * @dev A designated jury member submits their vote on the validity of a challenge.
     * Callable only by whitelisted jury members.
     * @param _challengeId The ID of the challenge.
     * @param _isAgentCorrect True if the jury member believes the agent's result is correct,
     *                        false if they believe the challenger is correct (agent's result is incorrect).
     */
    function submitChallengeVote(uint256 _challengeId, bool _isAgentCorrect) external onlyJury {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.resolved) revert ChallengeNotFound(); // Challenge must be active
        if (challenge.juryVotes[msg.sender]) revert AlreadyVoted(); // Jury member can only vote once

        challenge.juryVotes[msg.sender] = true; // Mark that this jury member has voted
        if (_isAgentCorrect) {
            challenge.votesForAgent += 1;
        } else {
            challenge.votesForChallenger += 1;
        }

        emit ChallengeVoteSubmitted(_challengeId, msg.sender, _isAgentCorrect);
    }

    /**
     * @dev Finalizes a challenge based on jury votes after the challenge period.
     * Distributes rewards/penalties accordingly.
     * This can be called by anyone once the challenge period (for voting) is over and
     * minimum votes are met.
     * @param _challengeId The ID of the challenge to finalize.
     */
    function finalizeChallenge(uint256 _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        Task storage task = tasks[challenge.taskId];

        if (challenge.resolved) revert ChallengeNotFound(); // Already resolved
        // Challenge period (for initial result submission) needs to be over before jury decision is final
        if (block.timestamp < challenge.challengeStartTime + challengePeriodDuration) revert ChallengePeriodActive();
        // Ensure minimum jury participation for a valid decision
        if (challenge.votesForAgent + challenge.votesForChallenger < minJuryVotesRequired) {
            revert InsufficientJuryVotes();
        }

        challenge.resolved = true;

        if (challenge.votesForChallenger > challenge.votesForAgent) {
            // Challenger wins: Agent's stake is slashed, challenger gets their fee back.
            challenge.challengeSuccessful = true;
            slashAgent(challenge.agentId, agents[challenge.agentId].stake / 2, "Task result incorrect"); // Slash 50% of stake for incorrect result

            // Return challenger's fee
            if (!cognitoToken.transfer(challenge.challenger, challengeFee)) revert InsufficientBalance();

            task.status = TaskStatus.Failed; // Mark task as failed due to incorrect agent submission
        } else {
            // Agent wins (or draw in votes): Challenger loses fee, agent proceeds to claim reward.
            challenge.challengeSuccessful = false;
            // Challenger's fee is burned in this example. Could be distributed to jury/treasury.
            if (!cognitoToken.transfer(address(0xdead), challengeFee)) revert InsufficientBalance(); // Simulate burning

            task.status = TaskStatus.Verified; // Task result is verified
        }

        emit ChallengeFinalized(_challengeId, challenge.taskId, challenge.challengeSuccessful);
    }
    
    /**
     * @dev Allows the selected agent to claim their reward after successful task completion and no successful challenge.
     * Or, after winning a challenge.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        // Ensure task is verified and sender is the owner of the selected agent
        if (task.status != TaskStatus.Verified) revert TaskCannotBeReclaimed();
        if (task.selectedAgentId == 0 || agents[task.selectedAgentId].owner != msg.sender) revert NotAgentOwner();
        
        // Transfer reward from contract escrow to agent owner
        if (!cognitoToken.transfer(msg.sender, task.rewardAmount)) revert InsufficientBalance();
        task.status = TaskStatus.Verified; // Keep status as verified, but now reward is processed

        emit TaskVerified(_taskId, task.selectedAgentId, task.outputHash);
    }

    /**
     * @dev Allows the task creator to reclaim funds if the task is canceled, expired,
     * or the assigned agent failed (e.g., missed deadline, was slashed).
     * @param _taskId The ID of the task.
     */
    function reclaimTaskFunds(uint256 _taskId) external onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];

        // Case 1: Task was funded but either no agent was selected or agent failed
        // and was already marked as Failed (e.g., after a challenge)
        if (task.status == TaskStatus.Failed || 
           (task.status == TaskStatus.Assigned && block.timestamp > task.deadline) ||
           (task.status == TaskStatus.Funded && block.timestamp > task.deadline) // If task was funded but no agent was selected before deadline
        ) {
            if (!cognitoToken.transfer(task.creator, task.rewardAmount)) revert InsufficientBalance();
            emit TaskFundsReclaimed(_taskId, task.creator, task.rewardAmount);
            task.status = TaskStatus.Failed; // Finalize state
        } else if (task.status == TaskStatus.Canceled) {
             // If already explicitly canceled, funds might have been reclaimed there.
             // This path ensures idempotence or handles edge cases where task was marked Canceled
             // but funds not yet transferred (e.g., if initial transfer failed for some reason).
             // However, `cancelTask` already handles the transfer. This else-if might be redundant
             // if `cancelTask` is robust, but provides a fallback.
             revert TaskCannotBeReclaimed(); // Assume funds already handled by `cancelTask`
        }
        else {
            revert TaskCannotBeReclaimed(); // Task is still active, submitted, or verified.
        }
    }
}
```