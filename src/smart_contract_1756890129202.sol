This smart contract, **CognitionNet**, is a decentralized AI Model Co-creation & Verification Protocol. It creates an ecosystem for participants to collaborate on AI tasks, ensuring verifiability and incentivizing honest contributions through staking, reputation, and a challenge-based resolution system. It integrates concepts like decentralized AI marketplaces, verifiable computation (simulated on-chain), dynamic roles, and a simplified DAO governance for parameter adjustments.

---

## Outline and Function Summary for CognitionNet

CognitionNet is a decentralized platform enabling the collaborative creation, training, and inference of AI models. It connects AI model proposers, data providers, and computation providers (workers) in a verifiable and incentivized ecosystem. The protocol leverages staking, reputation, and a challenge-based verification system to ensure the integrity of AI task executions. A simplified DAO governance oversees key protocol parameters.

**I. Core Setup & Role Management**
1.  `constructor(address _cognitionToken)`: Initializes the protocol with the ERC20 token address and sets up the initial admin (acting as the simplified DAO).
2.  `registerAsDataProvider(uint256 stakeAmount)`: Allows a user to register as a data provider by staking tokens. Data providers make datasets available for AI tasks.
3.  `registerAsComputationProvider(uint256 stakeAmount)`: Allows a user to register as a computation provider (worker) by staking tokens. Workers execute AI training/inference tasks.
4.  `registerAsModelProposer(uint256 stakeAmount)`: Allows a user to register as an AI model proposer by staking tokens. Proposers define and fund AI tasks.
5.  `deregisterRole(Role role)`: Allows a user to deregister from a specific role and unstake their tokens after a cooldown period, preventing rapid sybil attacks.
6.  `updateStakingAmount(Role role, uint256 newStakeAmount)`: Allows a user to increase or decrease their stake for an active role, subject to minimums.

**II. Model & Dataset Management**
7.  `proposeModelBlueprint(string calldata name, string calldata description, string calldata ipfsCid, bytes32 contentHash, string[] calldata requiredSkills)`: A model proposer submits metadata (including IPFS CID and content hash for off-chain files) for a new AI model blueprint, which requires DAO approval.
8.  `approveModelBlueprint(uint256 modelId)`: An authorized entity (e.g., DAO admin) approves a proposed model, making it usable for tasks.
9.  `proposeDataset(string calldata name, string calldata description, string calldata ipfsCid, bytes32 contentHash, bool isPrivate, uint256 rewardShare)`: A data provider submits metadata for a new dataset, specifying its privacy, off-chain location, and a reward share for its use. Also requires DAO approval.
10. `approveDataset(uint256 datasetId)`: An authorized entity approves a proposed dataset.

**III. Task Management**
11. `createTrainingTask(uint256 modelId, uint256 datasetId, uint256 workerReward, uint256 verificationStake, uint256 maxExecutionTime, uint256 challengePeriod)`: A model proposer creates a training task, funding it with rewards, specifying the model, dataset, and task parameters.
12. `createInferenceTask(uint256 modelId, string calldata inputIpfsCid, uint256 workerReward, uint256 verificationStake, uint256 maxExecutionTime, uint256 challengePeriod)`: A model proposer creates an inference task for an approved model, providing input data (via IPFS CID) and funding.
13. `claimTask(uint256 taskId)`: A computation provider claims an available task, committing to its execution and implicitly locking a portion of their stake.
14. `submitTaskResult(uint256 taskId, string calldata resultIpfsCid, bytes32 resultHash)`: The computation provider submits the task result's hash and IPFS CID, signifying completion.
15. `challengeTaskResult(uint256 taskId, string calldata reasonIpfsCid)`: Any registered participant can challenge a submitted task result within a defined period, providing off-chain evidence.
16. `resolveChallenge(uint256 taskId, address challenger, bool isChallengerCorrect)`: An authorized entity (e.g., DAO admin, acting as an oracle) resolves a challenge, determining if the worker's result or the challenger's claim was correct, leading to rewards or slashing.
17. `finalizeTask(uint256 taskId)`: Allows anyone to trigger reward distribution for a task if its challenge period has passed without any challenge.

**IV. Reward & Reputation**
18. `distributeTaskReward(uint256 taskId)`: **Internal function** (exposed via `finalizeTask` and `resolveChallenge`). Distributes rewards to the successful computation provider, data provider (if applicable), and updates their reputation.
19. `claimEarnedRewards()`: Users can claim their accumulated rewards from completed tasks and verified contributions, transferring tokens from the contract.
20. `_updateReputation(address user, int256 change)`: **Internal function** to adjust a user's reputation score (positive for success, negative for failure/fraud).
21. `_slashStake(address user, Role role, uint256 amount)`: **Internal function** to slash a user's staked tokens due to fraudulent or malicious activity, reducing their commitment to the protocol.

**V. Governance (Simplified DAO Integration)**
22. `proposeProtocolParameterChange(bytes4 targetSelector, bytes calldata data, string calldata description)`: Allows an authorized entity (e.g., DAO admin) to propose changes to core protocol parameters (e.g., fee rates, stake amounts) by encoding a function call.
23. `voteOnProposal(uint256 proposalId, bool support)`: Allows authorized entities (e.g., DAO admin) to vote on active proposals. (Simplified: one vote per admin/owner in this example).
24. `executeProposal(uint256 proposalId)`: Executes a passed proposal if it achieves a simple majority (for this example).

**VI. Utilities & Views**
25. `getRoleStakeAmount(Role role)`: Returns the current minimum staking requirement for a given role.
26. `getUserReputation(address user)`: Returns the current reputation score of a user.
27. `getTaskDetails(uint256 taskId)`: Returns all relevant details of a specific task.
28. `getAvailableTasks(TaskType taskType)`: Returns a list of tasks that are currently available to be claimed by computation providers, filtered by type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable as a simplified DAO administrator for this example.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CognitionNet is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public immutable cognitionToken; // The token used for staking and rewards

    // Protocol parameters (can be adjusted by DAO)
    uint256 public minDataProviderStake;
    uint256 public minComputationProviderStake;
    uint256 public minModelProposerStake;
    uint256 public challengePeriodDuration; // Minimum duration in seconds for challenge phase
    uint256 public taskExecutionTimeout;    // Minimum duration in seconds for worker to complete task
    uint256 public deregisterCooldownPeriod; // In seconds, after deregister request
    uint256 public protocolFeeRate; // Basis points (e.g., 500 for 5%)

    // Unique IDs for various entities
    Counters.Counter private _modelIds;
    Counters.Counter private _datasetIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    // --- Enums ---
    enum Role { None, DataProvider, ComputationProvider, ModelProposer }
    enum TaskType { Training, Inference }
    enum TaskStatus { Created, Claimed, Submitted, Challenged, Resolved_Success, Resolved_Failure }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // --- Structs ---
    struct UserProfile {
        uint256 reputation; // Higher is better
        uint256 rewardsAccumulated; // Tokens awaiting claim
        uint256 lastDeregisterRequestTime; // For cooldown
        mapping(Role => bool) registeredRoles; // True if registered for a specific role
        mapping(Role => uint256) roleStake; // Stake per role
    }

    struct ModelBlueprint {
        address proposer;
        string name;
        string description;
        string ipfsCid; // IPFS CID pointing to model architecture/config file
        bytes32 contentHash; // Hash of the model file for integrity check
        string[] requiredSkills; // e.g., "GPU", "TensorFlow", "PyTorch"
        bool approved;
    }

    struct Dataset {
        address provider;
        string name;
        string description;
        string ipfsCid; // IPFS CID pointing to dataset location
        bytes32 contentHash; // Hash of the dataset for integrity check
        bool isPrivate; // If true, access requires explicit grant (handled off-chain)
        uint256 rewardShare; // Basis points for data provider (e.g., 500 for 5% of worker reward)
        bool approved;
    }

    struct Task {
        TaskType taskType;
        uint256 modelId;
        uint256 datasetId; // 0 for inference tasks without a specific training dataset
        address proposer;
        address worker; // Computation Provider
        uint256 workerReward; // Reward allocated to the worker
        uint256 verificationStake; // Stake required from worker, and locked from proposer, for integrity
        uint256 maxExecutionTime; // Max time for worker to execute
        uint256 challengePeriod; // Time window for challenges
        uint256 claimedTime;
        uint256 submittedTime;
        string resultIpfsCid; // IPFS CID of the computed result
        bytes32 resultHash; // Hash of the computed result for integrity
        TaskStatus status;
        address challenger; // Address of the challenger, if any
        string challengeReasonIpfsCid; // IPFS CID of the challenge reason/proof
        uint256 protocolFee; // Fee collected by the protocol
    }

    struct Proposal {
        address proposer;
        string description;
        bytes4 targetSelector; // Function selector to call on execution
        bytes callData; // Encoded data for the function call
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        mapping(address => bool) hasVoted; // Tracks unique voters. For this simple DAO, only owner can vote.
        ProposalStatus status;
    }

    // --- Mappings ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => ModelBlueprint) public modelBlueprints;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public pendingRewards; // Rewards accumulated by users for claiming

    // --- Events ---
    event UserRegistered(address indexed user, Role indexed role, uint256 stake);
    event UserDeregistered(address indexed user, Role indexed role);
    event StakeUpdated(address indexed user, Role indexed role, uint256 newStake);
    event ModelBlueprintProposed(uint256 indexed modelId, address indexed proposer, string name);
    event ModelBlueprintApproved(uint256 indexed modelId, address indexed approver);
    event DatasetProposed(uint256 indexed datasetId, address indexed provider, string name);
    event DatasetApproved(uint256 indexed datasetId, address indexed approver);
    event TaskCreated(uint256 indexed taskId, TaskType indexed taskType, address indexed proposer, uint256 workerReward);
    event TaskClaimed(uint256 indexed taskId, address indexed worker);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed worker, string resultIpfsCid);
    event TaskResultChallenged(uint256 indexed taskId, address indexed challenger);
    event ChallengeResolved(uint256 indexed taskId, address indexed resolver, bool challengerCorrect);
    event TaskFinalized(uint256 indexed taskId, TaskStatus finalStatus);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event StakeSlahsed(address indexed user, Role indexed role, uint256 amount);

    // --- Modifiers ---
    modifier onlyRegistered(Role requiredRole) {
        require(userProfiles[msg.sender].registeredRoles[requiredRole], "CognitionNet: Caller is not registered for this role");
        _;
    }

    // This modifier simplifies DAO interaction. In a real DAO, this would check
    // if the call originated from the DAO's governance or executor contract.
    modifier onlyDAO() {
        require(msg.sender == owner(), "CognitionNet: Not authorized by DAO (only owner)");
        _;
    }

    // --- Constructor ---
    constructor(address _cognitionToken) Ownable(msg.sender) {
        require(_cognitionToken != address(0), "CognitionNet: Invalid token address");
        cognitionToken = IERC20(_cognitionToken);

        // Initial protocol parameters (can be adjusted by DAO proposals)
        minDataProviderStake = 1000 ether; // Example: 1000 tokens
        minComputationProviderStake = 5000 ether; // Example: 5000 tokens
        minModelProposerStake = 2000 ether; // Example: 2000 tokens
        challengePeriodDuration = 3 days; // Minimum 3 days for challenge
        taskExecutionTimeout = 7 days; // Minimum 7 days for task execution
        deregisterCooldownPeriod = 14 days; // 14-day cooldown for deregistration
        protocolFeeRate = 500; // 5% (500 basis points out of 10,000)
    }

    // --- I. Core Setup & Role Management ---

    /// @notice Registers the caller as a Data Provider by staking tokens.
    /// @param stakeAmount The amount of tokens to stake for this role.
    function registerAsDataProvider(uint256 stakeAmount) external nonReentrant {
        require(stakeAmount >= minDataProviderStake, "CognitionNet: Insufficient stake for Data Provider");
        require(!userProfiles[msg.sender].registeredRoles[Role.DataProvider], "CognitionNet: Already registered as Data Provider");

        _stakeTokens(msg.sender, stakeAmount);
        userProfiles[msg.sender].registeredRoles[Role.DataProvider] = true;
        userProfiles[msg.sender].roleStake[Role.DataProvider] = stakeAmount;
        emit UserRegistered(msg.sender, Role.DataProvider, stakeAmount);
    }

    /// @notice Registers the caller as a Computation Provider by staking tokens.
    /// @param stakeAmount The amount of tokens to stake for this role.
    function registerAsComputationProvider(uint256 stakeAmount) external nonReentrant {
        require(stakeAmount >= minComputationProviderStake, "CognitionNet: Insufficient stake for Computation Provider");
        require(!userProfiles[msg.sender].registeredRoles[Role.ComputationProvider], "CognitionNet: Already registered as Computation Provider");

        _stakeTokens(msg.sender, stakeAmount);
        userProfiles[msg.sender].registeredRoles[Role.ComputationProvider] = true;
        userProfiles[msg.sender].roleStake[Role.ComputationProvider] = stakeAmount;
        emit UserRegistered(msg.sender, Role.ComputationProvider, stakeAmount);
    }

    /// @notice Registers the caller as an AI Model Proposer by staking tokens.
    /// @param stakeAmount The amount of tokens to stake for this role.
    function registerAsModelProposer(uint256 stakeAmount) external nonReentrant {
        require(stakeAmount >= minModelProposerStake, "CognitionNet: Insufficient stake for Model Proposer");
        require(!userProfiles[msg.sender].registeredRoles[Role.ModelProposer], "CognitionNet: Already registered as Model Proposer");

        _stakeTokens(msg.sender, stakeAmount);
        userProfiles[msg.sender].registeredRoles[Role.ModelProposer] = true;
        userProfiles[msg.sender].roleStake[Role.ModelProposer] = stakeAmount;
        emit UserRegistered(msg.sender, Role.ModelProposer, stakeAmount);
    }

    /// @notice Allows a user to deregister from a specific role and unstake their tokens after a cooldown period.
    /// @param role The role to deregister from.
    function deregisterRole(Role role) external nonReentrant {
        require(role != Role.None, "CognitionNet: Invalid role");
        require(userProfiles[msg.sender].registeredRoles[role], "CognitionNet: Not registered for this role");

        // Enforce cooldown if a request was made recently
        if (userProfiles[msg.sender].lastDeregisterRequestTime > 0 && 
            block.timestamp < userProfiles[msg.sender].lastDeregisterRequestTime + deregisterCooldownPeriod) {
            revert("CognitionNet: Deregistration cooldown period active");
        }

        uint256 stakeToReturn = userProfiles[msg.sender].roleStake[role];
        _unstakeTokens(msg.sender, stakeToReturn); // Return the staked tokens
        userProfiles[msg.sender].registeredRoles[role] = false;
        userProfiles[msg.sender].roleStake[role] = 0;
        userProfiles[msg.sender].lastDeregisterRequestTime = block.timestamp; // Reset cooldown timer for next deregister action
        emit UserDeregistered(msg.sender, role);
    }

    /// @notice Allows a user to increase or decrease their stake for an active role.
    /// @param role The role for which to update the stake.
    /// @param newStakeAmount The new total stake amount for this role.
    function updateStakingAmount(Role role, uint256 newStakeAmount) external nonReentrant {
        require(role != Role.None, "CognitionNet: Invalid role");
        require(userProfiles[msg.sender].registeredRoles[role], "CognitionNet: Not registered for this role");

        uint256 currentStake = userProfiles[msg.sender].roleStake[role];
        uint256 minRequiredStake;

        if (role == Role.DataProvider) {
            minRequiredStake = minDataProviderStake;
        } else if (role == Role.ComputationProvider) {
            minRequiredStake = minComputationProviderStake;
        } else if (role == Role.ModelProposer) {
            minRequiredStake = minModelProposerStake;
        } else {
            revert("CognitionNet: Invalid role for staking update");
        }

        require(newStakeAmount >= minRequiredStake, "CognitionNet: New stake amount is below minimum required for role");

        if (newStakeAmount > currentStake) {
            _stakeTokens(msg.sender, newStakeAmount - currentStake); // Stake more
        } else if (newStakeAmount < currentStake) {
            _unstakeTokens(msg.sender, currentStake - newStakeAmount); // Unstake some
        }
        userProfiles[msg.sender].roleStake[role] = newStakeAmount;
        emit StakeUpdated(msg.sender, role, newStakeAmount);
    }

    // --- II. Model & Dataset Management ---

    /// @notice A model proposer submits metadata for a new AI model blueprint.
    /// @param name Name of the model.
    /// @param description Description of the model.
    /// @param ipfsCid IPFS CID pointing to model architecture/config.
    /// @param contentHash Hash of the model file for integrity check.
    /// @param requiredSkills Array of strings specifying skills/requirements (e.g., "GPU", "TensorFlow").
    /// @return modelId The ID of the newly proposed model blueprint.
    function proposeModelBlueprint(
        string calldata name,
        string calldata description,
        string calldata ipfsCid,
        bytes32 contentHash,
        string[] calldata requiredSkills
    ) external onlyRegistered(Role.ModelProposer) returns (uint256 modelId) {
        _modelIds.increment();
        modelId = _modelIds.current();

        modelBlueprints[modelId] = ModelBlueprint({
            proposer: msg.sender,
            name: name,
            description: description,
            ipfsCid: ipfsCid,
            contentHash: contentHash,
            requiredSkills: requiredSkills,
            approved: false // Requires DAO/admin approval
        });
        emit ModelBlueprintProposed(modelId, msg.sender, name);
        return modelId;
    }

    /// @notice An authorized entity (e.g., DAO admin) approves a proposed model, making it usable for tasks.
    /// @param modelId The ID of the model blueprint to approve.
    function approveModelBlueprint(uint256 modelId) external onlyDAO {
        require(modelBlueprints[modelId].proposer != address(0), "CognitionNet: Model blueprint does not exist");
        require(!modelBlueprints[modelId].approved, "CognitionNet: Model blueprint already approved");
        modelBlueprints[modelId].approved = true;
        emit ModelBlueprintApproved(modelId, msg.sender);
    }

    /// @notice A data provider submits metadata for a new dataset, specifying its privacy and potential reward share.
    /// @param name Name of the dataset.
    /// @param description Description of the dataset.
    /// @param ipfsCid IPFS CID pointing to dataset location.
    /// @param contentHash Hash of the dataset for integrity check.
    /// @param isPrivate If true, access requires explicit grant (off-chain metadata).
    /// @param rewardShare Basis points for data provider (e.g., 500 for 5% of task worker reward).
    /// @return datasetId The ID of the newly proposed dataset.
    function proposeDataset(
        string calldata name,
        string calldata description,
        string calldata ipfsCid,
        bytes32 contentHash,
        bool isPrivate,
        uint256 rewardShare
    ) external onlyRegistered(Role.DataProvider) returns (uint256 datasetId) {
        require(rewardShare <= 10000, "CognitionNet: Reward share cannot exceed 100%"); // Max 100%
        _datasetIds.increment();
        datasetId = _datasetIds.current();

        datasets[datasetId] = Dataset({
            provider: msg.sender,
            name: name,
            description: description,
            ipfsCid: ipfsCid,
            contentHash: contentHash,
            isPrivate: isPrivate,
            rewardShare: rewardShare,
            approved: false // Requires DAO/admin approval
        });
        emit DatasetProposed(datasetId, msg.sender, name);
        return datasetId;
    }

    /// @notice An authorized entity approves a proposed dataset.
    /// @param datasetId The ID of the dataset to approve.
    function approveDataset(uint256 datasetId) external onlyDAO {
        require(datasets[datasetId].provider != address(0), "CognitionNet: Dataset does not exist");
        require(!datasets[datasetId].approved, "CognitionNet: Dataset already approved");
        datasets[datasetId].approved = true;
        emit DatasetApproved(datasetId, msg.sender);
    }

    // --- III. Task Management ---

    /// @notice A model proposer creates a training task, funding it and defining parameters.
    /// @param modelId The ID of the approved model blueprint to train.
    /// @param datasetId The ID of the approved dataset to use for training.
    /// @param workerReward Amount of tokens to reward the computation provider.
    /// @param verificationStake Amount of tokens required from the worker as a commitment (also locked from proposer).
    /// @param maxExecutionTime Maximum time in seconds for the worker to complete the task.
    /// @param challengePeriod Duration in seconds for which results can be challenged.
    /// @return taskId The ID of the newly created training task.
    function createTrainingTask(
        uint256 modelId,
        uint256 datasetId,
        uint256 workerReward,
        uint256 verificationStake,
        uint256 maxExecutionTime,
        uint256 challengePeriod
    ) external nonReentrant onlyRegistered(Role.ModelProposer) returns (uint256 taskId) {
        require(modelBlueprints[modelId].approved, "CognitionNet: Model not approved");
        require(datasets[datasetId].approved, "CognitionNet: Dataset not approved");
        require(workerReward > 0, "CognitionNet: Worker reward must be positive");
        require(verificationStake > 0, "CognitionNet: Verification stake must be positive");
        require(challengePeriod >= challengePeriodDuration, "CognitionNet: Challenge period too short");
        require(maxExecutionTime >= taskExecutionTimeout, "CognitionNet: Max execution time too short");

        // Calculate total amount needed from proposer
        uint256 datasetRewardShare = (workerReward * datasets[datasetId].rewardShare) / 10000;
        uint256 totalRewardPool = workerReward + datasetRewardShare;
        uint256 protocolFee = (totalRewardPool * protocolFeeRate) / 10000;
        // Proposer funds: workerReward + datasetReward + protocolFee + verificationStake
        uint256 totalAmountToLock = totalRewardPool + protocolFee + verificationStake; 

        _depositFunds(msg.sender, totalAmountToLock); // Proposer funds the task
        
        _taskIds.increment();
        taskId = _taskIds.current();

        tasks[taskId] = Task({
            taskType: TaskType.Training,
            modelId: modelId,
            datasetId: datasetId,
            proposer: msg.sender,
            worker: address(0), // No worker assigned yet
            workerReward: workerReward,
            verificationStake: verificationStake,
            maxExecutionTime: maxExecutionTime,
            challengePeriod: challengePeriod,
            claimedTime: 0,
            submittedTime: 0,
            resultIpfsCid: "",
            resultHash: 0x0,
            status: TaskStatus.Created,
            challenger: address(0),
            challengeReasonIpfsCid: "",
            protocolFee: protocolFee
        });
        emit TaskCreated(taskId, TaskType.Training, msg.sender, workerReward);
        return taskId;
    }

    /// @notice A model proposer creates an inference task for an approved model, funding it.
    /// @param modelId The ID of the approved model blueprint to use for inference.
    /// @param inputIpfsCid IPFS CID of the input data for inference.
    /// @param workerReward Amount of tokens to reward the computation provider.
    /// @param verificationStake Amount of tokens required from the worker as a commitment (also locked from proposer).
    /// @param maxExecutionTime Maximum time in seconds for the worker to complete the task.
    /// @param challengePeriod Duration in seconds for which results can be challenged.
    /// @return taskId The ID of the newly created inference task.
    function createInferenceTask(
        uint256 modelId,
        string calldata inputIpfsCid,
        uint256 workerReward,
        uint256 verificationStake,
        uint256 maxExecutionTime,
        uint256 challengePeriod
    ) external nonReentrant onlyRegistered(Role.ModelProposer) returns (uint256 taskId) {
        require(modelBlueprints[modelId].approved, "CognitionNet: Model not approved");
        require(workerReward > 0, "CognitionNet: Worker reward must be positive");
        require(verificationStake > 0, "CognitionNet: Verification stake must be positive");
        require(challengePeriod >= challengePeriodDuration, "CognitionNet: Challenge period too short");
        require(maxExecutionTime >= taskExecutionTimeout, "CognitionNet: Max execution time too short");

        uint256 totalRewardPool = workerReward;
        uint256 protocolFee = (totalRewardPool * protocolFeeRate) / 10000;
        uint256 totalAmountToLock = totalRewardPool + protocolFee + verificationStake; 

        _depositFunds(msg.sender, totalAmountToLock); // Proposer funds the task

        _taskIds.increment();
        taskId = _taskIds.current();

        tasks[taskId] = Task({
            taskType: TaskType.Inference,
            modelId: modelId,
            datasetId: 0, // Not applicable for inference without specific dataset
            proposer: msg.sender,
            worker: address(0),
            workerReward: workerReward,
            verificationStake: verificationStake,
            maxExecutionTime: maxExecutionTime,
            challengePeriod: challengePeriod,
            claimedTime: 0,
            submittedTime: 0,
            resultIpfsCid: inputIpfsCid, // Using this field for input for inference
            resultHash: 0x0,
            status: TaskStatus.Created,
            challenger: address(0),
            challengeReasonIpfsCid: "",
            protocolFee: protocolFee
        });
        emit TaskCreated(taskId, TaskType.Inference, msg.sender, workerReward);
        return taskId;
    }

    /// @notice A computation provider claims an available task, locking a portion of their stake as commitment.
    /// @param taskId The ID of the task to claim.
    function claimTask(uint256 taskId) external nonReentrant onlyRegistered(Role.ComputationProvider) {
        Task storage task = tasks[taskId];
        require(task.proposer != address(0), "CognitionNet: Task does not exist");
        require(task.status == TaskStatus.Created, "CognitionNet: Task not available for claiming");
        require(userProfiles[msg.sender].roleStake[Role.ComputationProvider] >= task.verificationStake, "CognitionNet: Insufficient stake to claim task");

        // Worker's `verificationStake` is conceptually locked. It's not transferred
        // to the contract, but its availability is a pre-requisite, and it's at risk of slashing.
        task.worker = msg.sender;
        task.claimedTime = block.timestamp;
        task.status = TaskStatus.Claimed;

        emit TaskClaimed(taskId, msg.sender);
    }

    /// @notice The computation provider submits the task result hash and off-chain proof link.
    /// @param taskId The ID of the task.
    /// @param resultIpfsCid IPFS CID of the computed result.
    /// @param resultHash Hash of the computed result for integrity.
    function submitTaskResult(
        uint256 taskId,
        string calldata resultIpfsCid,
        bytes32 resultHash
    ) external nonReentrant {
        Task storage task = tasks[taskId];
        require(task.proposer != address(0), "CognitionNet: Task does not exist");
        require(task.worker == msg.sender, "CognitionNet: Only task worker can submit result");
        require(task.status == TaskStatus.Claimed, "CognitionNet: Task not in claimed state");
        require(block.timestamp <= task.claimedTime + task.maxExecutionTime, "CognitionNet: Task execution timed out");

        task.resultIpfsCid = resultIpfsCid;
        task.resultHash = resultHash;
        task.submittedTime = block.timestamp;
        task.status = TaskStatus.Submitted;
        emit TaskResultSubmitted(taskId, msg.sender, resultIpfsCid);
    }

    /// @notice Any participant can challenge a submitted task result, providing evidence.
    /// @param taskId The ID of the task.
    /// @param reasonIpfsCid IPFS CID pointing to the challenge reason/proof.
    function challengeTaskResult(uint256 taskId, string calldata reasonIpfsCid) external nonReentrant {
        Task storage task = tasks[taskId];
        require(task.proposer != address(0), "CognitionNet: Task does not exist");
        require(task.status == TaskStatus.Submitted, "CognitionNet: Task not in submitted state or already resolved");
        require(block.timestamp <= task.submittedTime + task.challengePeriod, "CognitionNet: Challenge period has ended");
        require(msg.sender != task.worker, "CognitionNet: Worker cannot challenge their own result");
        
        // Challenger must be registered in a role that allows them to stake and participate in dispute resolution.
        require(userProfiles[msg.sender].registeredRoles[Role.ComputationProvider] || 
                userProfiles[msg.sender].registeredRoles[Role.ModelProposer] ||
                userProfiles[msg.sender].registeredRoles[Role.DataProvider], 
                "CognitionNet: Challenger must have an active stake in a relevant role.");
        
        // For a more advanced system, challengers would also stake tokens.
        // For simplicity, we assume the verificationStake by the worker is sufficient for dispute resolution.

        task.challenger = msg.sender;
        task.challengeReasonIpfsCid = reasonIpfsCid;
        task.status = TaskStatus.Challenged;
        emit TaskResultChallenged(taskId, msg.sender);
    }

    /// @notice An authorized entity resolves a challenge, leading to rewards, slashing, and reputation adjustments.
    /// @dev This function assumes an off-chain dispute resolution mechanism or a trusted oracle/DAO decision.
    /// @param taskId The ID of the task.
    /// @param isChallengerCorrect True if the challenger's claim is valid and the worker's submission was incorrect.
    function resolveChallenge(
        uint256 taskId,
        bool isChallengerCorrect
    ) external onlyDAO nonReentrant {
        Task storage task = tasks[taskId];
        require(task.proposer != address(0), "CognitionNet: Task does not exist");
        require(task.status == TaskStatus.Challenged, "CognitionNet: Task not in challenged state");
        require(block.timestamp > task.submittedTime + task.challengePeriod, "CognitionNet: Challenge period not yet ended for resolution"); // Ensure challenge period is over before resolution

        if (isChallengerCorrect) {
            // Challenger was correct: Worker gets slashed, task fails. Proposer's funds returned.
            _slashStake(task.worker, Role.ComputationProvider, task.verificationStake);
            _updateReputation(task.worker, -100); // Decrease worker reputation
            _updateReputation(task.challenger, 50); // Increase challenger reputation
            
            // Return worker reward and proposer's verification stake to proposer
            pendingRewards[task.proposer] += task.workerReward; // Worker's reward is returned to proposer as task failed
            pendingRewards[task.proposer] += task.verificationStake; // Proposer's locked stake is returned
            if (task.taskType == TaskType.Training) { // Also return dataset reward if it was a training task
                pendingRewards[task.proposer] += (task.workerReward * datasets[task.datasetId].rewardShare) / 10000;
            }

            task.status = TaskStatus.Resolved_Failure;
            emit TaskFinalized(taskId, TaskStatus.Resolved_Failure);
        } else {
            // Challenger was incorrect: Worker was correct, task succeeds.
            // Challenger's reputation decreases. Worker and Data Provider get rewards.
            _updateReputation(task.challenger, -50); // Decrease challenger reputation for false challenge
            
            _distributeTaskReward(taskId); // Distribute rewards for successful completion
            task.status = TaskStatus.Resolved_Success;
            emit TaskFinalized(taskId, TaskStatus.Resolved_Success);
        }
    }

    /// @notice Allows anyone to finalize a task and trigger reward distribution if the challenge period has passed without a challenge.
    /// @param taskId The ID of the task to finalize.
    function finalizeTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        require(task.proposer != address(0), "CognitionNet: Task does not exist");
        require(task.status == TaskStatus.Submitted, "CognitionNet: Task not in submitted state or already finalized/challenged");
        require(block.timestamp > task.submittedTime + task.challengePeriod, "CognitionNet: Challenge period not yet ended");

        _distributeTaskReward(taskId); // Distribute rewards for successful completion
        task.status = TaskStatus.Resolved_Success; // Mark as success after distribution
        emit TaskFinalized(taskId, TaskStatus.Resolved_Success);
    }

    // --- IV. Reward & Reputation ---

    /// @dev Internal function to distribute rewards to the successful Computation Providers and Data Providers.
    /// @param taskId The ID of the task.
    function _distributeTaskReward(uint256 taskId) internal {
        Task storage task = tasks[taskId];
        
        // 1. Worker Reward
        pendingRewards[task.worker] += task.workerReward;
        _updateReputation(task.worker, 10); // Increase worker reputation

        // 2. Data Provider Reward (if applicable)
        if (task.taskType == TaskType.Training && datasets[task.datasetId].provider != address(0)) {
            uint256 datasetReward = (task.workerReward * datasets[task.datasetId].rewardShare) / 10000;
            pendingRewards[datasets[task.datasetId].provider] += datasetReward;
            _updateReputation(datasets[task.datasetId].provider, 5); // Increase data provider reputation
        }
        
        // 3. Proposer's verification stake is returned
        pendingRewards[task.proposer] += task.verificationStake;

        // Protocol fee is implicitly retained by the contract as it was part of the initial deposit.
        // It is not distributed to anyone here.
    }

    /// @notice Users can claim their accumulated rewards from completed tasks and verified contributions.
    function claimEarnedRewards() external nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "CognitionNet: No rewards to claim");

        pendingRewards[msg.sender] = 0;
        bool success = cognitionToken.transfer(msg.sender, amount);
        require(success, "CognitionNet: Token transfer failed");

        emit RewardsClaimed(msg.sender, amount);
    }

    /// @dev Internal function to adjust a user's reputation score.
    /// @param user The address of the user.
    /// @param change The amount to change the reputation by (can be positive or negative).
    function _updateReputation(address user, int256 change) internal {
        int256 currentRep = int256(userProfiles[user].reputation);
        int256 newRep = currentRep + change;
        if (newRep < 0) newRep = 0; // Reputation cannot go below zero
        userProfiles[user].reputation = uint256(newRep);
        // Event for reputation update could be added here if detailed tracking is needed.
    }

    /// @dev Internal function to slash a user's staked tokens.
    /// @param user The address of the user to slash.
    /// @param role The role for which the stake is being slashed.
    /// @param amount The amount of tokens to slash.
    function _slashStake(address user, Role role, uint252 amount) internal {
        require(userProfiles[user].roleStake[role] >= amount, "CognitionNet: Insufficient stake to slash");
        userProfiles[user].roleStake[role] -= amount;
        // The slashed tokens remain in the contract. They could be explicitly burned or sent to a DAO treasury.
        // For this example, they simply reduce the user's effective stake within the protocol's accounting.
        emit StakeSlahsed(user, role, amount);
    }

    // --- V. Governance (Simplified DAO Integration) ---

    /// @notice Allows an admin/DAO member to propose a change to a protocol parameter.
    /// @dev This is a simplified proposal system. In a real DAO, voting power would be stake-weighted.
    /// @param targetSelector The function selector of the function to call for the change (e.g., `this.setMinDataProviderStake.selector`).
    /// @param data The encoded call data for the target function.
    /// @param description A description of the proposed change.
    /// @return proposalId The ID of the newly created proposal.
    function proposeProtocolParameterChange(
        bytes4 targetSelector,
        bytes calldata data,
        string calldata description
    ) external onlyDAO returns (uint256 proposalId) { // Only owner (acting as DAO admin) can propose for this example
        _proposalIds.increment();
        proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            targetSelector: targetSelector,
            callData: data,
            voteCountFor: 0,
            voteCountAgainst: 0,
            hasVoted: new mapping(address => bool),
            status: ProposalStatus.Pending
        });
        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    /// @notice Allows DAO members to vote on active proposals.
    /// @dev For simplicity, each unique address gets one vote. In a real DAO, voting power would be stake-weighted.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 proposalId, bool support) external onlyDAO { // Only owner can vote for this example
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "CognitionNet: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "CognitionNet: Proposal not in pending state");
        require(!proposal.hasVoted[msg.sender], "CognitionNet: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.voteCountFor++;
        } else {
            proposal.voteCountAgainst++;
        }
        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes a passed proposal.
    /// @dev Simple majority rule for this example.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external onlyDAO nonReentrant { // Only owner can execute
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "CognitionNet: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "CognitionNet: Proposal not in pending state");
        
        // Simple majority: more 'for' votes than 'against' votes.
        // In a real DAO, there would be a quorum, minimum votes, etc.
        require(proposal.voteCountFor > proposal.voteCountAgainst, "CognitionNet: Proposal not passed");

        // Update the status before calling the target function to prevent reentrancy issues if target calls back.
        proposal.status = ProposalStatus.Approved;

        // Execute the proposed function call on this contract instance
        (bool success, ) = address(this).call(abi.encodePacked(proposal.targetSelector, proposal.callData));
        require(success, "CognitionNet: Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(proposalId);
    }

    // Functions to be called by DAO proposals to change parameters (example)
    function setMinDataProviderStake(uint256 _newStake) public onlyDAO { minDataProviderStake = _newStake; }
    function setMinComputationProviderStake(uint256 _newStake) public onlyDAO { minComputationProviderStake = _newStake; }
    function setMinModelProposerStake(uint256 _newStake) public onlyDAO { minModelProposerStake = _newStake; }
    function setChallengePeriodDuration(uint256 _newDuration) public onlyDAO { challengePeriodDuration = _newDuration; }
    function setTaskExecutionTimeout(uint256 _newTimeout) public onlyDAO { taskExecutionTimeout = _newTimeout; }
    function setDeregisterCooldownPeriod(uint256 _newCooldown) public onlyDAO { deregisterCooldownPeriod = _newCooldown; }
    function setProtocolFeeRate(uint256 _newRate) public onlyDAO { 
        require(_newRate <= 10000, "CognitionNet: Fee rate cannot exceed 100%");
        protocolFeeRate = _newRate; 
    }
    
    // --- VI. Utilities & Views ---

    /// @notice Returns the current minimum staking requirement for a given role.
    /// @param role The role to query.
    /// @return The minimum stake amount in tokens.
    function getRoleStakeAmount(Role role) external view returns (uint256) {
        if (role == Role.DataProvider) {
            return minDataProviderStake;
        } else if (role == Role.ComputationProvider) {
            return minComputationProviderStake;
        } else if (role == Role.ModelProposer) {
            return minModelProposerStake;
        } else {
            revert("CognitionNet: Invalid role");
        }
    }

    /// @notice Returns the current reputation score of a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address user) external view returns (uint252) {
        return userProfiles[user].reputation;
    }

    /// @notice Returns all relevant details of a specific task.
    /// @param taskId The ID of the task.
    /// @return A tuple containing all task details.
    function getTaskDetails(uint256 taskId)
        external
        view
        returns (
            TaskType taskType,
            uint256 modelId,
            uint256 datasetId,
            address proposer,
            address worker,
            uint256 workerReward,
            uint256 verificationStake,
            uint256 maxExecutionTime,
            uint256 challengePeriod,
            uint256 claimedTime,
            uint256 submittedTime,
            string memory resultIpfsCid,
            bytes32 resultHash,
            TaskStatus status,
            address challenger,
            string memory challengeReasonIpfsCid,
            uint256 protocolFee
        )
    {
        Task storage task = tasks[taskId];
        require(task.proposer != address(0), "CognitionNet: Task does not exist");
        return (
            task.taskType,
            task.modelId,
            task.datasetId,
            task.proposer,
            task.worker,
            task.workerReward,
            task.verificationStake,
            task.maxExecutionTime,
            task.challengePeriod,
            task.claimedTime,
            task.submittedTime,
            task.resultIpfsCid,
            task.resultHash,
            task.status,
            task.challenger,
            task.challengeReasonIpfsCid,
            task.protocolFee
        );
    }

    /// @notice Returns a list of tasks that are currently available to be claimed by computation providers.
    /// @param taskType The type of task to filter by (Training or Inference).
    /// @return An array of task IDs.
    function getAvailableTasks(TaskType taskType) external view returns (uint256[] memory) {
        uint256[] memory tempTaskIds = new uint256[](_taskIds.current()); // Max possible size
        uint256 counter = 0;
        for (uint256 i = 1; i <= _taskIds.current(); i++) {
            if (tasks[i].status == TaskStatus.Created && tasks[i].taskType == taskType) {
                tempTaskIds[counter] = i;
                counter++;
            }
        }
        // Resize array to actual number of tasks found
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = tempTaskIds[i];
        }
        return result;
    }

    // --- Internal/Private Helpers ---

    /// @dev Handles staking tokens for a user. Assumes approval has been granted to this contract.
    function _stakeTokens(address user, uint256 amount) internal {
        require(cognitionToken.transferFrom(user, address(this), amount), "CognitionNet: Token transferFrom failed for staking");
    }

    /// @dev Handles unstaking tokens for a user.
    function _unstakeTokens(address user, uint256 amount) internal {
        require(cognitionToken.transfer(user, amount), "CognitionNet: Token transfer failed for unstaking");
    }

    /// @dev Handles depositing funds for a task. Assumes approval has been granted to this contract.
    function _depositFunds(address depositor, uint256 amount) internal {
        require(cognitionToken.transferFrom(depositor, address(this), amount), "CognitionNet: Token transferFrom failed for task funding");
    }
}
```