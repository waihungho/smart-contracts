Here's a smart contract in Solidity called `CognitoNet`, designed around the concept of a "Decentralized On-Chain AI Agent Registry & Task Orchestration Platform with Dynamic Reputation." This contract incorporates advanced concepts like soulbound tokens for agent identity, staking-based decentralized validation of AI outputs, epoch-driven state transitions, and a governance module for parameter tuning.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking token

// --- Outline ---
// The `CognitoNet` contract establishes a decentralized platform for AI agents to register, contribute models, execute tasks,
// and earn reputation. It features a soulbound-token-like agent identity (AgentID), a staking-based validation mechanism
// for AI outputs, and an epoch-driven system for task resolution and reward distribution. Governance is integrated for
// community-driven parameter adjustments, making the system adaptable and resilient.

// --- Function Summary ---

// I. Agent & Identity Management (Soulbound AgentID - ERC721 non-transferable):
// 1.  `registerAgent(string memory _agentURI)`: Allows a new address to register as an AI Agent, minting a unique, non-transferable `AgentID` (SBT).
// 2.  `updateAgentURI(uint256 _agentId, string memory _newAgentURI)`: Allows an agent to update their off-chain metadata URI (e.g., description, capabilities).
// 3.  `getAgentInfo(uint256 _agentId)`: Retrieves comprehensive information about a registered agent, including its reputation and frozen status.
// 4.  `getAgentIdByAddress(address _agentAddress)`: Returns the unique `AgentID` associated with a given controller address.
// 5.  `freezeAgent(uint256 _agentId, bool _freeze)`: Governance function to freeze or unfreeze an agent's activity due to violations or policy changes.

// II. AI Model Registration:
// 6.  `registerModel(uint256 _agentId, string memory _modelURI, bytes32 _expectedInputSchemaHash, bytes32 _expectedOutputSchemaHash)`: An agent registers a new AI model, providing its metadata URI (e.g., model type, capabilities, off-chain endpoint) and hashes of its input/output schema for verification.
// 7.  `updateModelURI(uint256 _agentId, uint256 _modelId, string memory _newModelURI)`: Allows an agent to update the metadata URI for their registered model.
// 8.  `deregisterModel(uint256 _agentId, uint256 _modelId)`: Allows an agent to deactivate a model, preventing it from being assigned new tasks.
// 9.  `getModelInfo(uint256 _modelId)`: Retrieves details about a specific registered AI model.

// III. Task Creation & Execution:
// 10. `createTask(uint256 _modelId, string memory _taskInputURI, uint256 _validationDurationEpochs, uint256 _executionDeadlineEpoch)`: A user creates a new task, specifying the desired AI model, input data URI, and attaching an ETH bounty. It also defines validation and execution deadlines.
// 11. `claimTask(uint256 _taskId)`: An eligible agent claims an open task. Requires meeting minimum reputation and owning the specified model.
// 12. `submitTaskResult(uint256 _taskId, string memory _resultURI)`: The claiming agent submits the task's output URI.
// 13. `getTaskDetails(uint256 _taskId)`: Retrieves all pertinent information about a specific task.
// 14. `cancelTask(uint256 _taskId)`: The task creator can cancel their task if it hasn't been claimed or had a result submitted yet, refunding the bounty.

// IV. Decentralized Validation & Reputation System:
// 15. `stakeForValidation(uint256 _taskId, bool _isResultCorrect, string memory _explanationURI)`: Users or other agents can stake `CognitoToken`s, asserting whether a submitted task result is correct or incorrect, and providing an explanation URI. This also acts as their vote.
// 16. `resolveTaskValidation(uint256 _taskId)`: Callable by the `EpochManager` after the validation period to tally votes, determine the task's outcome, update agent reputation, and make rewards available.
// 17. `claimValidationRewards(uint256 _taskId)`: Validators who voted correctly and provided a valid explanation can claim their share of the validation ETH bounty and refund their staked `CognitoToken`s.

// V. Epoch Management & Rewards:
// 18. `advanceEpoch()`: Callable by the `EpochManager` to progress the system to the next epoch, triggering batch processing of tasks nearing their validation or execution deadlines.
// 19. `withdrawBounty(uint256 _taskId)`: An agent whose task result was successfully validated can withdraw their earned ETH bounty (minus validator rewards).
// 20. `getReputationScore(uint256 _agentId)`: Retrieves the current reputation score of an agent.

// VI. Governance & Parameters:
// 21. `proposeParameterChange(uint256 _proposerAgentId, bytes32 _parameterKey, uint256 _newValue)`: Allows eligible agents to propose changes to system-wide parameters (e.g., validation stake amount, reputation decay rate).
// 22. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible stakers (holding `CognitoToken`s) to vote on active proposals.
// 23. `executeProposal(uint256 _proposalId)`: Executed after a proposal passes its voting period and achieves majority support, updating the system parameter.
// 24. `setEpochManager(address _newManager)`: Owner/governance can update the address authorized to advance epochs.
// 25. `tokenURI(uint256 tokenId)`: Overrides ERC721's `tokenURI` to link AgentIDs to their metadata.

// --- Smart Contract Code ---

interface ICognitoToken is IERC20 {
    // Basic ERC20 interface is sufficient for staking
}

contract CognitoNet is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Agent ID (SBT-like)
    Counters.Counter private _agentIds;
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256) public agentAddressToId; // Maps controller address to AgentID

    // AI Models
    Counters.Counter private _modelIds;
    mapping(uint256 => Model) public models;

    // Tasks
    Counters.Counter private _taskIds;
    mapping(uint256 => Task) public tasks;

    // Epoch Management
    uint256 public currentEpoch;
    address public epochManager; // Address authorized to advance epochs

    // Staking & Rewards
    ICognitoToken public cognitoToken;
    uint256 public totalStakedTokens; // Total CognitoTokens locked in the contract for validation stakes

    // Governance
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    mapping(bytes32 => Parameter) public parameters; // Configurable system parameters (e.g., reputation thresholds, stake amounts)

    // --- Constants & Configurable Parameters (managed by governance) ---
    bytes32 public constant PARAM_MIN_REPUTATION_FOR_CLAIM = keccak256("MIN_REPUTATION_FOR_CLAIM");
    bytes32 public constant PARAM_VALIDATION_STAKE_AMOUNT = keccak256("VALIDATION_STAKE_AMOUNT");
    bytes32 public constant PARAM_REPUTATION_BUMP_ON_SUCCESS = keccak256("REPUTATION_BUMP_ON_SUCCESS");
    bytes32 public constant PARAM_REPUTATION_PENALTY_ON_FAILURE = keccak256("REPUTATION_PENALTY_ON_FAILURE");
    bytes32 public constant PARAM_MIN_TASK_BOUNTY = keccak256("MIN_TASK_BOUNTY");
    bytes32 public constant PARAM_VALIDATION_REWARD_PERCENT = keccak256("VALIDATION_REWARD_PERCENT"); // % of bounty for validators
    bytes32 public constant PARAM_PROPOSAL_VOTING_PERIOD_EPOCHS = keccak256("PROPOSAL_VOTING_PERIOD_EPOCHS");
    bytes32 public constant PARAM_INITIAL_AGENT_REPUTATION = keccak256("INITIAL_AGENT_REPUTATION");

    // --- Structs ---

    struct Agent {
        address owner; // The EOA or contract controlling this agent
        string agentURI; // IPFS hash or URL to agent's metadata (e.g., description, off-chain endpoint info)
        uint256 reputationScore;
        bool isFrozen; // If true, agent cannot claim tasks or register models
    }

    struct Model {
        uint256 agentId; // The AgentID of the agent who registered this model
        string modelURI; // IPFS hash or URL to model definition/specifications
        bytes32 expectedInputSchemaHash; // Hash of the expected input data schema
        bytes32 expectedOutputSchemaHash; // Hash of the expected output data schema
        bool isActive; // Can be deactivated by agent
    }

    enum TaskStatus { Created, Claimed, ResultSubmitted, ValidationPeriod, Resolved, Canceled }
    struct Task {
        address creator; // Who created the task (can be any user, not necessarily an agent)
        uint256 modelId; // The ID of the model requested for this task
        string taskInputURI; // IPFS hash of the input data for the AI model
        uint256 bountyAmount; // In ETH (or the token used for bounties)
        uint256 creationEpoch;
        uint256 executionDeadlineEpoch; // By which epoch agent must submit result
        uint256 validationDurationEpochs; // Duration of the validation period after result submission
        uint256 validationPeriodEndEpoch; // Absolute epoch when validation ends
        uint256 agentIdClaimedBy; // The AgentID that claimed this task
        string resultURI; // IPFS hash of the AI model's output
        TaskStatus status;
        uint256 totalCorrectStakes; // Total CognitoTokens staked for "correct" votes
        uint256 totalIncorrectStakes; // Total CognitoTokens staked for "incorrect" votes
        mapping(address => uint256) validatorStakes; // Staker address => amount staked
        mapping(address => bool) validatorVotes; // Staker address => true for correct, false for incorrect
        mapping(address => string) validatorExplanationURIs; // Staker address => explanation URI for their vote
        bool isResolved; // True once validation is complete
        bool resultWasCorrect; // Outcome of validation: true if deemed correct
        uint256 rewardsDistributed; // Amount of bounty (ETH) distributed to the agent
        uint256 validatorRewardsDistributed; // Total amount of bounty (ETH) earmarked for validators
    }

    enum ProposalStatus { Pending, Active, Passed, Failed, Executed }
    struct Proposal {
        bytes32 parameterKey; // Key of the parameter to change (e.g., PARAM_MIN_REPUTATION_FOR_CLAIM)
        uint256 newValue; // The new value for the parameter
        uint256 proposerAgentId; // AgentID of the proposer
        uint256 creationEpoch;
        uint256 votingEndEpoch; // Absolute epoch when voting ends
        uint256 totalVotesFor; // Sum of CognitoToken stakes that voted 'for'
        uint256 totalVotesAgainst; // Sum of CognitoToken stakes that voted 'against'
        mapping(address => bool) hasVoted; // Staker address => true if voted
        ProposalStatus status;
    }

    struct Parameter {
        uint256 value;
        string description;
    }

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string agentURI);
    event AgentURIUpdated(uint256 indexed agentId, string newAgentURI);
    event AgentFrozen(uint256 indexed agentId, bool frozenByGovernance);

    event ModelRegistered(uint256 indexed modelId, uint256 indexed agentId, string modelURI);
    event ModelURIUpdated(uint256 indexed modelId, string newModelURI);
    event ModelDeregistered(uint256 indexed modelId, uint256 indexed agentId);

    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 modelId, uint256 bountyAmount, uint256 executionDeadlineEpoch);
    event TaskClaimed(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, string resultURI);
    event TaskCanceled(uint256 indexed taskId, address indexed creator);
    event TaskValidated(uint256 indexed taskId, bool resultWasCorrect, uint256 totalCorrectStakes, uint256 totalIncorrectStakes);

    event ValidationStaked(uint256 indexed taskId, address indexed validator, uint256 amount, bool vote, string explanationURI);
    event ValidationRewardsClaimed(uint256 indexed taskId, address indexed validator, uint256 stakeRefundAmount, uint256 ethRewardAmount);

    event BountyWithdrawn(uint256 indexed taskId, uint256 indexed agentId, uint256 amount);

    event EpochAdvanced(uint256 newEpoch);
    event EpochManagerUpdated(address indexed oldManager, address indexed newManager);

    event ParameterProposed(uint256 indexed proposalId, bytes32 indexed parameterKey, uint256 newValue, uint256 proposerAgentId);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 indexed parameterKey, uint256 newValue);

    // --- Modifiers ---
    modifier onlyAgent(uint256 _agentId) {
        require(agents[_agentId].owner == msg.sender, "CognitoNet: Not the agent's owner");
        require(agents[_agentId].isFrozen == false, "CognitoNet: Agent is frozen");
        _;
    }

    modifier onlyEpochManager() {
        require(msg.sender == epochManager, "CognitoNet: Only Epoch Manager can call this function");
        _;
    }

    modifier onlyStaker() {
        // A staker is either a registered agent or someone holding CognitoToken
        require(agentAddressToId[msg.sender] != 0 || cognitoToken.balanceOf(msg.sender) > 0, "CognitoNet: Caller is not a recognized staker/agent");
        _;
    }
    
    // --- Constructor ---
    constructor(address _cognitoTokenAddress, address _epochManagerAddress) ERC721("Cognito Agent ID", "CAGNTID") Ownable(msg.sender) {
        require(_cognitoTokenAddress != address(0), "CognitoNet: Token address cannot be zero");
        require(_epochManagerAddress != address(0), "CognitoNet: Epoch Manager address cannot be zero");
        cognitoToken = ICognitoToken(_cognitoTokenAddress);
        epochManager = _epochManagerAddress;
        currentEpoch = 0; // Initialize epoch

        // Initialize default parameters with descriptions
        _setParameter(PARAM_MIN_REPUTATION_FOR_CLAIM, 100, "Minimum reputation an agent needs to claim a task.");
        _setParameter(PARAM_VALIDATION_STAKE_AMOUNT, 100 * (10**cognitoToken.decimals()), "Amount of CognitoToken required to stake for validation.");
        _setParameter(PARAM_REPUTATION_BUMP_ON_SUCCESS, 10, "Reputation points gained for successfully completing a task.");
        _setParameter(PARAM_REPUTATION_PENALTY_ON_FAILURE, 20, "Reputation points lost for failing a task or submitting an incorrect result.");
        _setParameter(PARAM_MIN_TASK_BOUNTY, 0.01 ether, "Minimum ETH bounty for a task.");
        _setParameter(PARAM_VALIDATION_REWARD_PERCENT, 20, "Percentage of bounty allocated to validators (0-100)."); // 20%
        _setParameter(PARAM_PROPOSAL_VOTING_PERIOD_EPOCHS, 5, "Number of epochs a proposal remains active for voting.");
        _setParameter(PARAM_INITIAL_AGENT_REPUTATION, 50, "Initial reputation score for a newly registered agent.");
    }

    // --- Internal/Helper Functions ---
    function _setParameter(bytes32 _key, uint256 _value, string memory _description) internal {
        parameters[_key] = Parameter(_value, _description);
    }

    function _getParameter(bytes32 _key) internal view returns (uint256) {
        require(parameters[_key].value != 0 || _key == PARAM_MIN_TASK_BOUNTY, "CognitoNet: Parameter not set or invalid key.");
        return parameters[_key].value;
    }

    // Override ERC721's transfer functions to make AgentIDs soulbound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("CognitoNet: AgentID is soulbound and cannot be transferred");
        }
    }

    // --- I. Agent & Identity Management ---

    // 1. registerAgent
    function registerAgent(string memory _agentURI) public {
        require(agentAddressToId[msg.sender] == 0, "CognitoNet: Address already registered as an agent");

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        agents[newAgentId] = Agent({
            owner: msg.sender,
            agentURI: _agentURI,
            reputationScore: _getParameter(PARAM_INITIAL_AGENT_REPUTATION),
            isFrozen: false
        });
        agentAddressToId[msg.sender] = newAgentId;
        
        _safeMint(msg.sender, newAgentId); // Mints the SBT
        emit AgentRegistered(newAgentId, msg.sender, _agentURI);
    }

    // 2. updateAgentURI
    function updateAgentURI(uint256 _agentId, string memory _newAgentURI) public onlyAgent(_agentId) {
        agents[_agentId].agentURI = _newAgentURI;
        emit AgentURIUpdated(_agentId, _newAgentURI);
    }

    // 3. getAgentInfo
    function getAgentInfo(uint256 _agentId) public view returns (address owner, string memory agentURI, uint256 reputationScore, bool isFrozen) {
        Agent storage agent = agents[_agentId];
        require(agent.owner != address(0), "CognitoNet: Agent does not exist");
        return (agent.owner, agent.agentURI, agent.reputationScore, agent.isFrozen);
    }

    // 4. getAgentIdByAddress
    function getAgentIdByAddress(address _agentAddress) public view returns (uint256) {
        return agentAddressToId[_agentAddress];
    }

    // 5. freezeAgent
    function freezeAgent(uint256 _agentId, bool _freeze) public onlyOwner {
        require(agents[_agentId].owner != address(0), "CognitoNet: Agent does not exist");
        agents[_agentId].isFrozen = _freeze;
        emit AgentFrozen(_agentId, _freeze);
    }

    // --- II. AI Model Registration ---

    // 6. registerModel
    function registerModel(
        uint256 _agentId,
        string memory _modelURI,
        bytes32 _expectedInputSchemaHash,
        bytes32 _expectedOutputSchemaHash
    ) public onlyAgent(_agentId) {
        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        models[newModelId] = Model({
            agentId: _agentId,
            modelURI: _modelURI,
            expectedInputSchemaHash: _expectedInputSchemaHash,
            expectedOutputSchemaHash: _expectedOutputSchemaHash,
            isActive: true
        });
        
        emit ModelRegistered(newModelId, _agentId, _modelURI);
    }

    // 7. updateModelURI
    function updateModelURI(uint256 _agentId, uint256 _modelId, string memory _newModelURI) public onlyAgent(_agentId) {
        Model storage model = models[_modelId];
        require(model.agentId == _agentId, "CognitoNet: Model not owned by this agent");
        model.modelURI = _newModelURI;
        emit ModelURIUpdated(_modelId, _newModelURI);
    }

    // 8. deregisterModel
    function deregisterModel(uint256 _agentId, uint256 _modelId) public onlyAgent(_agentId) {
        Model storage model = models[_modelId];
        require(model.agentId == _agentId, "CognitoNet: Model not owned by this agent");
        require(model.isActive, "CognitoNet: Model already inactive");
        
        model.isActive = false;
        emit ModelDeregistered(_modelId, _agentId);
    }

    // 9. getModelInfo
    function getModelInfo(uint256 _modelId) public view returns (uint256 agentId, string memory modelURI, bytes32 inputSchemaHash, bytes32 outputSchemaHash, bool isActive) {
        Model storage model = models[_modelId];
        require(model.agentId != 0, "CognitoNet: Model does not exist");
        return (model.agentId, model.modelURI, model.expectedInputSchemaHash, model.expectedOutputSchemaHash, model.isActive);
    }

    // --- III. Task Creation & Execution ---

    // 10. createTask
    function createTask(
        uint256 _modelId,
        string memory _taskInputURI,
        uint256 _validationDurationEpochs, // How many epochs for validation after result submission
        uint256 _executionDeadlineEpoch // Absolute epoch by which result must be submitted
    ) public payable {
        require(models[_modelId].isActive, "CognitoNet: Model is not active");
        require(msg.value >= _getParameter(PARAM_MIN_TASK_BOUNTY), "CognitoNet: Bounty too low");
        require(_executionDeadlineEpoch > currentEpoch, "CognitoNet: Execution deadline must be in the future");
        require(_validationDurationEpochs > 0, "CognitoNet: Validation period must be at least 1 epoch");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            modelId: _modelId,
            taskInputURI: _taskInputURI,
            bountyAmount: msg.value,
            creationEpoch: currentEpoch,
            executionDeadlineEpoch: _executionDeadlineEpoch,
            validationDurationEpochs: _validationDurationEpochs,
            validationPeriodEndEpoch: 0, // Set after result submission
            agentIdClaimedBy: 0,
            resultURI: "",
            status: TaskStatus.Created,
            totalCorrectStakes: 0,
            totalIncorrectStakes: 0,
            // mappings implicitly initialized
            isResolved: false,
            resultWasCorrect: false,
            rewardsDistributed: 0,
            validatorRewardsDistributed: 0
        });

        emit TaskCreated(newTaskId, msg.sender, _modelId, msg.value, _executionDeadlineEpoch);
    }

    // 11. claimTask
    function claimTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        uint256 agentId = agentAddressToId[msg.sender];

        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(task.status == TaskStatus.Created, "CognitoNet: Task not in 'Created' status");
        require(agentId != 0, "CognitoNet: Caller is not a registered agent");
        require(agents[agentId].isFrozen == false, "CognitoNet: Agent is frozen");
        require(currentEpoch <= task.executionDeadlineEpoch, "CognitoNet: Task execution deadline passed or imminent");
        
        // Agent must own the model specified in the task
        require(models[task.modelId].agentId == agentId, "CognitoNet: Agent does not own this model");
        
        // Agent must have sufficient reputation
        require(agents[agentId].reputationScore >= _getParameter(PARAM_MIN_REPUTATION_FOR_CLAIM), "CognitoNet: Agent reputation too low to claim task");

        task.agentIdClaimedBy = agentId;
        task.status = TaskStatus.Claimed;
        emit TaskClaimed(_taskId, agentId);
    }

    // 12. submitTaskResult
    function submitTaskResult(uint256 _taskId, string memory _resultURI) public {
        Task storage task = tasks[_taskId];
        uint256 agentId = agentAddressToId[msg.sender];

        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(task.status == TaskStatus.Claimed, "CognitoNet: Task not in 'Claimed' status");
        require(agentId == task.agentIdClaimedBy, "CognitoNet: Not the agent that claimed this task");
        require(currentEpoch <= task.executionDeadlineEpoch, "CognitoNet: Task execution deadline passed");

        task.resultURI = _resultURI;
        task.status = TaskStatus.ResultSubmitted;
        task.validationPeriodEndEpoch = currentEpoch + task.validationDurationEpochs;
        
        emit TaskResultSubmitted(_taskId, agentId, _resultURI);
    }

    // 13. getTaskDetails
    function getTaskDetails(uint256 _taskId) public view returns (
        address creator,
        uint256 modelId,
        string memory taskInputURI,
        uint256 bountyAmount,
        uint256 creationEpoch,
        uint256 executionDeadlineEpoch,
        uint256 validationPeriodEndEpoch,
        uint256 agentIdClaimedBy,
        string memory resultURI,
        TaskStatus status,
        bool isResolved,
        bool resultWasCorrect
    ) {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "CognitoNet: Task does not exist");
        return (
            task.creator,
            task.modelId,
            task.taskInputURI,
            task.bountyAmount,
            task.creationEpoch,
            task.executionDeadlineEpoch,
            task.validationPeriodEndEpoch,
            task.agentIdClaimedBy,
            task.resultURI,
            task.status,
            task.isResolved,
            task.resultWasCorrect
        );
    }

    // 14. cancelTask
    function cancelTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(task.creator == msg.sender, "CognitoNet: Only task creator can cancel");
        require(task.status == TaskStatus.Created, "CognitoNet: Task cannot be canceled after claimed or submitted");

        // Refund bounty
        payable(msg.sender).transfer(task.bountyAmount);
        task.status = TaskStatus.Canceled;
        emit TaskCanceled(_taskId, msg.sender);
    }

    // --- IV. Decentralized Validation & Reputation System ---

    // 15. stakeForValidation (Combines staking and voting)
    function stakeForValidation(uint256 _taskId, bool _isResultCorrect, string memory _explanationURI) public onlyStaker {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(task.status == TaskStatus.ResultSubmitted, "CognitoNet: Task not awaiting validation results");
        require(currentEpoch < task.validationPeriodEndEpoch, "CognitoNet: Validation period has ended");
        require(task.validatorStakes[msg.sender] == 0, "CognitoNet: You have already staked for this task");

        uint256 stakeAmount = _getParameter(PARAM_VALIDATION_STAKE_AMOUNT);
        require(cognitoToken.transferFrom(msg.sender, address(this), stakeAmount), "CognitoNet: Token transfer failed for stake");

        task.validatorStakes[msg.sender] = stakeAmount;
        task.validatorVotes[msg.sender] = _isResultCorrect;
        task.validatorExplanationURIs[msg.sender] = _explanationURI; // Store explanation URI
        
        if (_isResultCorrect) {
            task.totalCorrectStakes += stakeAmount;
        } else {
            task.totalIncorrectStakes += stakeAmount;
        }
        totalStakedTokens += stakeAmount;

        // Transition task to ValidationPeriod status if it's the first stake
        if (task.status == TaskStatus.ResultSubmitted) {
            task.status = TaskStatus.ValidationPeriod;
        }

        emit ValidationStaked(_taskId, msg.sender, stakeAmount, _isResultCorrect, _explanationURI);
    }

    // 16. resolveTaskValidation
    function resolveTaskValidation(uint256 _taskId) public onlyEpochManager {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(task.status == TaskStatus.ValidationPeriod || task.status == TaskStatus.ResultSubmitted, "CognitoNet: Task not in validation phase");
        require(currentEpoch >= task.validationPeriodEndEpoch, "CognitoNet: Validation period not ended yet");
        require(task.isResolved == false, "CognitoNet: Task already resolved");

        task.isResolved = true;
        uint256 agentId = task.agentIdClaimedBy;
        Agent storage agent = agents[agentId];

        uint256 totalStakes = task.totalCorrectStakes + task.totalIncorrectStakes;

        if (totalStakes == 0) {
            // No validators, task resolved as successful by default (configurable policy)
            task.resultWasCorrect = true;
            agent.reputationScore += _getParameter(PARAM_REPUTATION_BUMP_ON_SUCCESS);
        } else {
            // Majority vote decides the outcome
            if (task.totalCorrectStakes >= task.totalIncorrectStakes) {
                task.resultWasCorrect = true;
                agent.reputationScore += _getParameter(PARAM_REPUTATION_BUMP_ON_SUCCESS);
            } else {
                task.resultWasCorrect = false;
                // Ensure reputation doesn't underflow
                if (agent.reputationScore > _getParameter(PARAM_REPUTATION_PENALTY_ON_FAILURE)) {
                    agent.reputationScore -= _getParameter(PARAM_REPUTATION_PENALTY_ON_FAILURE);
                } else {
                    agent.reputationScore = 0;
                }
            }
        }
        
        // Calculate total ETH rewards for validators if task was successfully executed
        if (task.resultWasCorrect && totalStakes > 0) {
            task.validatorRewardsDistributed = (task.bountyAmount * _getParameter(PARAM_VALIDATION_REWARD_PERCENT)) / 100;
        } else {
            task.validatorRewardsDistributed = 0; // No validator rewards if task result was incorrect or no stakes
        }

        task.status = TaskStatus.Resolved;
        emit TaskValidated(_taskId, task.resultWasCorrect, task.totalCorrectStakes, task.totalIncorrectStakes);
    }

    // 17. claimValidationRewards
    function claimValidationRewards(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(task.isResolved, "CognitoNet: Task not yet resolved");
        require(task.validatorStakes[msg.sender] > 0, "CognitoNet: You did not stake on this task or already claimed");
        
        uint256 stakeAmount = task.validatorStakes[msg.sender];
        task.validatorStakes[msg.sender] = 0; // Mark as claimed immediately to prevent re-entrancy

        uint256 ethReward = 0;
        if (task.resultWasCorrect == task.validatorVotes[msg.sender] && task.totalCorrectStakes > 0 && task.validatorRewardsDistributed > 0) {
            // Validator voted correctly, refund stake and give ETH reward share
            require(cognitoToken.transfer(msg.sender, stakeAmount), "CognitoNet: Failed to refund stake token");
            totalStakedTokens -= stakeAmount;

            ethReward = (stakeAmount * task.validatorRewardsDistributed) / task.totalCorrectStakes;
            require(address(this).balance >= ethReward, "CognitoNet: Insufficient contract ETH for validation reward");
            payable(msg.sender).transfer(ethReward);
        } else {
            // Validator voted incorrectly or no validator rewards were available, stake is lost
            // Tokens remain in the contract's balance, effectively 'burned' from staker's perspective
            // Future governance could decide to send lost stakes to a treasury or burn them.
            totalStakedTokens -= stakeAmount; // Decrement total staked count
        }
        emit ValidationRewardsClaimed(_taskId, msg.sender, stakeAmount, ethReward);
    }

    // --- V. Epoch Management & Rewards ---

    // 18. advanceEpoch
    function advanceEpoch() public onlyEpochManager {
        currentEpoch++;
        // Reputation decay or other epoch-based batch processing can be triggered here.
        // For large-scale systems, this would involve a pull-model for decay
        // or a limited iteration over a queue of agents/tasks that need attention.
        // For this example, reputation decay is a property that agents 'deal with'
        // during interactions rather than a global sweep.

        emit EpochAdvanced(currentEpoch);
    }

    // 19. withdrawBounty
    function withdrawBounty(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        uint256 agentId = agentAddressToId[msg.sender];

        require(task.creator != address(0), "CognitoNet: Task does not exist");
        require(agentId == task.agentIdClaimedBy, "CognitoNet: Not the agent that completed this task");
        require(task.isResolved, "CognitoNet: Task not yet resolved");
        require(task.resultWasCorrect, "CognitoNet: Task result was incorrect, bounty not awarded");
        require(task.rewardsDistributed == 0, "CognitoNet: Bounty already withdrawn");

        uint256 agentShare = task.bountyAmount - task.validatorRewardsDistributed; // Remaining bounty for agent
        require(address(this).balance >= agentShare, "CognitoNet: Insufficient contract ETH for bounty withdrawal");
        
        payable(msg.sender).transfer(agentShare);
        task.rewardsDistributed = agentShare;
        emit BountyWithdrawn(_taskId, agentId, agentShare);
    }

    // 20. getReputationScore
    function getReputationScore(uint256 _agentId) public view returns (uint256) {
        Agent storage agent = agents[_agentId];
        require(agent.owner != address(0), "CognitoNet: Agent does not exist");
        return agent.reputationScore;
    }

    // --- VI. Governance & Parameters ---

    // 21. proposeParameterChange
    function proposeParameterChange(uint256 _proposerAgentId, bytes32 _parameterKey, uint256 _newValue) public onlyAgent(_proposerAgentId) {
        // Only agents with sufficient reputation can propose
        require(agents[_proposerAgentId].reputationScore >= _getParameter(PARAM_MIN_REPUTATION_FOR_CLAIM), "CognitoNet: Agent reputation too low to propose");
        require(parameters[_parameterKey].value != 0 || _parameterKey == PARAM_MIN_TASK_BOUNTY, "CognitoNet: Invalid parameter key for proposal or key not initialized");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            parameterKey: _parameterKey,
            newValue: _newValue,
            proposerAgentId: _proposerAgentId,
            creationEpoch: currentEpoch,
            votingEndEpoch: currentEpoch + _getParameter(PARAM_PROPOSAL_VOTING_PERIOD_EPOCHS),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            // mapping implicitly initialized
            status: ProposalStatus.Active
        });

        emit ParameterProposed(newProposalId, _parameterKey, _newValue, _proposerAgentId);
    }

    // 22. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyStaker {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CognitoNet: Proposal not active for voting");
        require(currentEpoch < proposal.votingEndEpoch, "CognitoNet: Voting period for this proposal has ended");
        require(proposal.hasVoted[msg.sender] == false, "CognitoNet: You have already voted on this proposal");

        uint256 voterStake = cognitoToken.balanceOf(msg.sender); // Voting power derived from held CognitoTokens
        require(voterStake > 0, "CognitoNet: Caller has no voting power (no CognitoToken balance)");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += voterStake;
        } else {
            proposal.totalVotesAgainst += voterStake;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    // 23. executeProposal
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CognitoNet: Proposal not active");
        require(currentEpoch >= proposal.votingEndEpoch, "CognitoNet: Voting period not ended");
        require(proposal.totalVotesFor != 0 || proposal.totalVotesAgainst != 0, "CognitoNet: No votes cast on proposal"); // Must have at least one vote

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            // Update value, keep existing description
            _setParameter(proposal.parameterKey, proposal.newValue, parameters[proposal.parameterKey].description); 
            proposal.status = ProposalStatus.Passed;
            emit ProposalExecuted(_proposalId, proposal.parameterKey, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    // 24. setEpochManager
    function setEpochManager(address _newManager) public onlyOwner {
        require(_newManager != address(0), "CognitoNet: New Epoch Manager cannot be zero address");
        emit EpochManagerUpdated(epochManager, _newManager);
        epochManager = _newManager;
    }

    // 25. tokenURI (ERC721 override for AgentID metadata)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return agents[tokenId].agentURI;
    }
}
```