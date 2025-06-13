Okay, here is a Solidity smart contract implementing a concept for a **Decentralized AI Model Training Marketplace**. This involves complex state management, interactions between different user roles (Data Owners, Model Requesters, Trainers/Compute Providers), staking, reputation tracking (simplified on-chain), and token rewards.

It's crucial to understand that performing actual AI model training or complex verification *on-chain* is not feasible due to gas costs and computational limitations. This contract manages the *workflow*, *incentives*, and *state* related to training tasks, relying on off-chain computation and potentially simplified on-chain verification or reputation systems.

Here's the contract outline and function summary, followed by the code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DecentralizedAIModelTraining
 * @dev A smart contract platform for orchestrating and incentivizing decentralized AI model training.
 *      This contract manages datasets, training tasks, trainer assignments, result submissions,
 *      verification (simplified), staking, reputation, and token rewards.
 *      Actual computation and complex model evaluation happen off-chain.
 */

// --- Contract Outline ---
// 1. State Variables:
//    - Counters for DataSets and TrainingTasks
//    - Mappings for DataSets, TrainingTasks, TrainerStakes, TrainerReputation
//    - Address of the Reward/Payment Token (AIDToken)
//    - Configuration parameters (e.g., min stake, verification period)
// 2. Enums: TaskStatus, FailureReason
// 3. Structs: DataSet, TrainingTask, TrainerResult
// 4. Events: Logging key actions (DataSetAdded, TaskCreated, TaskAssigned, ResultSubmitted, etc.)
// 5. Modifiers: Custom modifiers (e.g., onlyDataOwner, onlyTaskRequester, onlyAssignedTrainer)
// 6. Constructor: Initialize with AIDToken address
// 7. Core Functions (Grouped by role/feature):
//    - Admin/Config: Set token, pause/unpause
//    - Data Management: Add, view, grant/revoke access for datasets
//    - Task Management: Create, view, list, assign, submit results for tasks
//    - Staking & Reputation: Stake, unstake, view stake/reputation
//    - Task Resolution: Verify/Fail tasks, claim rewards/stakes
//    - Utility/View: Get various details (status, assignments, etc.)

// --- Function Summary (29 Functions) ---
// Admin/Config:
//  1. constructor(address _aidTokenAddress): Initializes the contract with the AIDToken address.
//  2. setAIDTokenAddress(address _newAIDTokenAddress): Owner sets the AIDToken address.
//  3. pause(): Owner pauses the contract (disables most operations).
//  4. unpause(): Owner unpauses the contract.
//
// Data Management (Requires role: Data Owner):
//  5. addDataSet(string memory _metadataURI, address[] memory _initialAccessGrantee): Register a new dataset (metadata only).
//  6. getDataSetDetails(uint256 _dataSetId): View details of a dataset.
//  7. grantDataSetAccess(uint256 _dataSetId, address _grantee): Grant access to a specific address for a dataset.
//  8. revokeDataSetAccess(uint256 _dataSetId, address _grantee): Revoke access for an address.
//  9. hasDataSetAccess(uint256 _dataSetId, address _user): Check if a user has access to a dataset.
// 10. getDataOwner(uint256 _dataSetId): View the owner of a dataset.
// 11. listDataSetIds(): View all registered dataset IDs (simplified list).
//
// Task Management (Requires role: Model Requester, Trainer):
// 12. createTrainingTask(uint256 _dataSetId, string memory _modelArchitectureURI, string memory _hyperparametersURI, uint256 _rewardAmount, uint256 _stakeRequired, uint256 _deadline): Create a new training task. Requires approving/transferring reward tokens.
// 13. getTrainingTaskDetails(uint256 _taskId): View details of a training task.
// 14. listAvailableTrainingTasks(): View IDs of tasks currently in Open status (simplified list).
// 15. assignTaskToTrainer(uint256 _taskId): Trainer accepts an open task. Requires sufficient stake. Stake is locked.
// 16. getAssignedTrainer(uint256 _taskId): View the trainer assigned to a task.
// 17. submitTrainingResult(uint256 _taskId, string memory _resultMetadataURI, uint256 _reportedPerformanceMetric): Trainer submits results after off-chain training. Updates task status to AwaitingVerification.
// 18. getTrainerResult(uint256 _taskId): View the submitted result for a task.
//
// Staking & Reputation (Requires role: Trainer):
// 19. stakeTokens(uint256 _amount): Stake AIDTokens to be eligible for tasks. Requires token approval.
// 20. unstakeTokens(uint256 _amount): Withdraw unstaked AIDTokens. Cannot unstake locked stake.
// 21. getTrainerStake(address _trainer): View a trainer's total stake (locked + unlocked).
// 22. getTrainerUnlockedStake(address _trainer): View a trainer's currently unlocked stake.
// 23. getTrainerReputation(address _trainer): View a trainer's reputation score.
//
// Task Resolution (Requires role: Task Requester, Assigned Trainer):
// 24. verifyTrainingTask(uint256 _taskId): Task Requester marks a task as successfully verified. Updates status to Verified.
// 25. failTrainingTask(uint256 _taskId, FailureReason _reason): Task Requester marks a task as failed. Handles stake and reputation based on reason.
// 26. claimTrainingReward(uint256 _taskId): Assigned Trainer claims the reward after task is Verified. Increases reputation.
// 27. claimTaskRequesterRefund(uint256 _taskId): Task Requester claims back reward stake if task failed in certain ways.
// 28. claimTrainerStakeReturn(uint256 _taskId): Assigned Trainer claims back their locked stake after task is Verified or failed appropriately.
//
// Utility:
// 29. getTaskStatus(uint256 _taskId): View the current status of a training task.

contract DecentralizedAIModelTraining is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public AIDToken;

    Counters.Counter private _dataSetIds;
    Counters.Counter private _taskIds;

    // Dataset struct and mapping
    struct DataSet {
        address owner;
        string metadataURI; // e.g., IPFS hash pointing to dataset description
        mapping(address => bool) accessGranted; // Addresses explicitly granted access
        address[] accessGranteeList; // To iterate granted access (simplification)
        bool exists; // Flag to check if ID is valid
    }
    mapping(uint256 => DataSet) public dataSets;
    uint256[] private _dataSetIdList; // To list all data set IDs (simplification)

    // Training Task struct and mapping
    enum TaskStatus {
        Open,              // Task created, waiting for a trainer
        Assigned,          // Task picked by a trainer
        ResultsSubmitted,  // Trainer submitted results, awaiting verification
        Verified,          // Task successfully verified by requester
        Failed             // Task failed for any reason
    }

    enum FailureReason {
        Other,             // General failure
        TrainerFailed,     // Trainer unable to complete/bad results
        DatasetIssue,      // Problem with the dataset
        RequesterCancelled // Requester cancelled before assignment
    }

    struct TrainingTask {
        address requester;
        uint256 dataSetId;
        string modelArchitectureURI; // e.g., IPFS hash of model config/architecture
        string hyperparametersURI; // e.g., IPFS hash of hyperparameter config
        uint256 rewardAmount;      // Amount of AIDToken paid to trainer on success
        uint256 stakeRequired;     // Minimum stake trainer needs to accept task
        uint256 deadline;          // Timestamp by which result should be submitted
        TaskStatus status;
        address assignedTrainer;   // Address of the trainer who took the task
        uint256 trainerLockedStake; // Amount of trainer's stake locked for this task
        string resultMetadataURI;  // e.g., IPFS hash of submitted model weights/logs
        uint256 reportedPerformanceMetric; // Trainer's reported metric (e.g., accuracy)
        FailureReason failureReason; // Reason if task failed
        bool exists;               // Flag to check if ID is valid
    }
    mapping(uint256 => TrainingTask) public trainingTasks;
    uint256[] private _openTaskIdList; // To list open task IDs (simplification)

    // Trainer Staking and Reputation
    mapping(address => uint256) private _trainerStakes; // Total stake of a trainer
    mapping(address => uint256) private _trainerLockedStakes; // Stake locked in active tasks
    mapping(address => uint256) public trainerReputation; // Simple counter of successful tasks

    // Configuration
    uint256 public minTrainerReputationToAssign; // Minimum reputation required to take tasks
    uint256 public failedTaskStakeSlashRatio = 10; // Percentage of trainer stake slashed on failure (e.g., 10%)

    // --- Events ---
    event AIDTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event DataSetAdded(uint256 indexed dataSetId, address indexed owner, string metadataURI);
    event DataSetAccessGranted(uint256 indexed dataSetId, address indexed owner, address indexed grantee);
    event DataSetAccessRevoked(uint256 indexed dataSetId, address indexed owner, address indexed grantee);
    event TrainingTaskCreated(uint256 indexed taskId, address indexed requester, uint256 dataSetId, uint256 rewardAmount, uint256 stakeRequired, uint256 deadline);
    event TaskAssigned(uint256 indexed taskId, address indexed trainer, uint256 lockedStake);
    event ResultSubmitted(uint256 indexed taskId, address indexed trainer, string resultMetadataURI, uint256 reportedPerformanceMetric);
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus oldStatus, TaskStatus newStatus);
    event TaskVerified(uint256 indexed taskId, address indexed verifier);
    event TaskFailed(uint256 indexed taskId, FailureReason reason);
    event TokensStaked(address indexed trainer, uint256 amount);
    event TokensUnstaked(address indexed trainer, uint256 amount);
    event TrainingRewardClaimed(uint256 indexed taskId, address indexed trainer, uint256 rewardAmount);
    event TaskRequesterRefunded(uint256 indexed taskId, address indexed requester, uint256 amount);
    event TrainerStakeReturned(uint256 indexed taskId, address indexed trainer, uint256 amount);
    event TrainerReputationUpdated(address indexed trainer, uint256 newReputation);

    // --- Modifiers ---
    modifier onlyDataOwner(uint256 _dataSetId) {
        require(dataSets[_dataSetId].owner == msg.sender, "Only data set owner can perform this action");
        _;
    }

    modifier onlyTaskRequester(uint256 _taskId) {
        require(trainingTasks[_taskId].requester == msg.sender, "Only task requester can perform this action");
        _;
    }

    modifier onlyAssignedTrainer(uint256 _taskId) {
        require(trainingTasks[_taskId].assignedTrainer == msg.sender, "Only assigned trainer can perform this action");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(trainingTasks[_taskId].status == _status, "Task is not in the required status");
        _;
    }

    modifier taskExists(uint256 _id, bool isDataSet) {
        if (isDataSet) {
            require(dataSets[_id].exists, "Data set does not exist");
        } else { // Training Task
            require(trainingTasks[_id].exists, "Training task does not exist");
        }
        _;
    }

    // --- Constructor ---
    constructor(address _aidTokenAddress) Ownable() Pausable() {
        AIDToken = IERC20(_aidTokenAddress);
        minTrainerReputationToAssign = 0; // Initially no reputation needed
    }

    // --- Admin/Config Functions ---
    /**
     * @dev Sets the address of the AIDToken contract. Only callable by owner.
     * @param _newAIDTokenAddress The address of the AIDToken contract.
     */
    function setAIDTokenAddress(address _newAIDTokenAddress) external onlyOwner {
        require(_newAIDTokenAddress != address(0), "Invalid token address");
        emit AIDTokenAddressUpdated(address(AIDToken), _newAIDTokenAddress);
        AIDToken = IERC20(_newAIDTokenAddress);
    }

    /**
     * @dev Pauses the contract. Prevents most state-changing operations.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Enables state-changing operations.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Returns the owner of the contract.
     */
    function getContractOwner() external view returns (address) {
        return owner();
    }

    // --- Data Management Functions ---
    /**
     * @dev Registers a new dataset. Only stores metadata URI and owner.
     *      Actual data storage is off-chain (e.g., IPFS, Arweave).
     * @param _metadataURI URI pointing to dataset metadata.
     * @param _initialAccessGrantee Addresses to grant initial access.
     * @return The ID of the newly created dataset.
     */
    function addDataSet(string memory _metadataURI, address[] memory _initialAccessGrantee)
        external
        whenNotPaused
        returns (uint256)
    {
        _dataSetIds.increment();
        uint256 newId = _dataSetIds.current();

        dataSets[newId].owner = msg.sender;
        dataSets[newId].metadataURI = _metadataURI;
        dataSets[newId].exists = true;

        // Grant initial access
        dataSets[newId].accessGranted[msg.sender] = true; // Owner always has access
        dataSets[newId].accessGranteeList.push(msg.sender); // Add owner to list

        for (uint i = 0; i < _initialAccessGrantee.length; i++) {
             // Prevent granting access to zero address or owner again
            if (_initialAccessGrantee[i] != address(0) && _initialAccessGrantee[i] != msg.sender) {
                if (!dataSets[newId].accessGranted[_initialAccessGrantee[i]]) {
                     dataSets[newId].accessGranted[_initialAccessGrantee[i]] = true;
                     dataSets[newId].accessGranteeList.push(_initialAccessGrantee[i]);
                     emit DataSetAccessGranted(newId, msg.sender, _initialAccessGrantee[i]);
                }
            }
        }

        _dataSetIdList.push(newId);
        emit DataSetAdded(newId, msg.sender, _metadataURI);
        return newId;
    }

    /**
     * @dev Retrieves the details of a dataset.
     * @param _dataSetId The ID of the dataset.
     * @return owner The address of the dataset owner.
     * @return metadataURI The metadata URI of the dataset.
     */
    function getDataSetDetails(uint256 _dataSetId)
        external
        view
        taskExists(_dataSetId, true)
        returns (address owner, string memory metadataURI)
    {
        DataSet storage ds = dataSets[_dataSetId];
        return (ds.owner, ds.metadataURI);
    }

    /**
     * @dev Grants access to a dataset for a specific address. Only callable by the dataset owner.
     * @param _dataSetId The ID of the dataset.
     * @param _grantee The address to grant access to.
     */
    function grantDataSetAccess(uint256 _dataSetId, address _grantee)
        external
        whenNotPaused
        taskExists(_dataSetId, true)
        onlyDataOwner(_dataSetId)
    {
        require(_grantee != address(0), "Invalid grantee address");
        require(!dataSets[_dataSetId].accessGranted[_grantee], "Access already granted");

        dataSets[_dataSetId].accessGranted[_grantee] = true;
        dataSets[_dataSetId].accessGranteeList.push(_grantee); // Add to list
        emit DataSetAccessGranted(_dataSetId, msg.sender, _grantee);
    }

    /**
     * @dev Revokes access to a dataset for a specific address. Only callable by the dataset owner.
     * @param _dataSetId The ID of the dataset.
     * @param _grantee The address to revoke access from.
     */
    function revokeDataSetAccess(uint256 _dataSetId, address _grantee)
        external
        whenNotPaused
        taskExists(_dataSetId, true)
        onlyDataOwner(_dataSetId)
    {
        require(_grantee != address(0), "Invalid grantee address");
        require(dataSets[_dataSetId].accessGranted[_grantee], "Access not granted");
        require(dataSets[_dataSetId].owner != _grantee, "Cannot revoke owner's access");

        dataSets[_dataSetId].accessGranted[_grantee] = false;

        // Remove from accessGranteeList (simple but inefficient for large lists)
        address[] storage grantees = dataSets[_dataSetId].accessGranteeList;
        for (uint i = 0; i < grantees.length; i++) {
            if (grantees[i] == _grantee) {
                grantees[i] = grantees[grantees.length - 1];
                grantees.pop();
                break; // Assuming unique grantees
            }
        }

        emit DataSetAccessRevoked(_dataSetId, msg.sender, _grantee);
    }

     /**
     * @dev Checks if a user has been granted access to a dataset.
     * @param _dataSetId The ID of the dataset.
     * @param _user The address of the user.
     * @return bool True if access is granted, false otherwise.
     */
    function hasDataSetAccess(uint256 _dataSetId, address _user)
        external
        view
        taskExists(_dataSetId, true)
        returns (bool)
    {
        return dataSets[_dataSetId].accessGranted[_user];
    }

    /**
     * @dev Returns the owner of a dataset.
     * @param _dataSetId The ID of the dataset.
     * @return The address of the data set owner.
     */
    function getDataOwner(uint256 _dataSetId)
        external
        view
        taskExists(_dataSetId, true)
        returns (address)
    {
        return dataSets[_dataSetId].owner;
    }

    /**
     * @dev Lists all registered dataset IDs (simplified).
     * @return An array of all dataset IDs.
     */
    function listDataSetIds() external view returns (uint256[] memory) {
        return _dataSetIdList;
    }


    // --- Task Management Functions ---
    /**
     * @dev Creates a new training task. Requires the requester to approve/transfer the reward amount to the contract.
     *      Requires requester to have access to the specified dataset.
     * @param _dataSetId The ID of the dataset to train on.
     * @param _modelArchitectureURI URI for the model architecture description.
     * @param _hyperparametersURI URI for the training hyperparameters.
     * @param _rewardAmount Amount of AIDToken rewarded to the trainer on success.
     * @param _stakeRequired Minimum AIDToken stake required for a trainer to accept this task.
     * @param _deadline Timestamp by which the task should be completed (results submitted).
     * @return The ID of the newly created task.
     */
    function createTrainingTask(
        uint256 _dataSetId,
        string memory _modelArchitectureURI,
        string memory _hyperparametersURI,
        uint256 _rewardAmount,
        uint256 _stakeRequired,
        uint256 _deadline
    ) external whenNotPaused taskExists(_dataSetId, true) returns (uint256) {
        require(bytes(_modelArchitectureURI).length > 0, "Model architecture URI cannot be empty");
        require(bytes(_hyperparametersURI).length > 0, "Hyperparameters URI cannot be empty");
        require(_rewardAmount > 0, "Reward amount must be positive");
        require(_stakeRequired >= minTrainerReputationToAssign, "Stake required must be at least minimum");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(dataSets[_dataSetId].accessGranted[msg.sender], "Requester must have access to the dataset");

        // Transfer reward tokens from requester to contract
        bool success = AIDToken.transferFrom(msg.sender, address(this), _rewardAmount);
        require(success, "Token transfer for reward failed");

        _taskIds.increment();
        uint256 newId = _taskIds.current();

        trainingTasks[newId].requester = msg.sender;
        trainingTasks[newId].dataSetId = _dataSetId;
        trainingTasks[newId].modelArchitectureURI = _modelArchitectureURI;
        trainingTasks[newId].hyperparametersURI = _hyperparametersURI;
        trainingTasks[newId].rewardAmount = _rewardAmount;
        trainingTasks[newId].stakeRequired = _stakeRequired;
        trainingTasks[newId].deadline = _deadline;
        trainingTasks[newId].status = TaskStatus.Open;
        trainingTasks[newId].exists = true;

        // Add to the list of open tasks (simplification)
        _openTaskIdList.push(newId);

        emit TrainingTaskCreated(
            newId,
            msg.sender,
            _dataSetId,
            _rewardAmount,
            _stakeRequired,
            _deadline
        );
        return newId;
    }

    /**
     * @dev Retrieves the details of a training task.
     * @param _taskId The ID of the task.
     * @return requester The address of the task requester.
     * @return dataSetId The ID of the dataset used.
     * @return modelArchitectureURI URI for model architecture.
     * @return hyperparametersURI URI for hyperparameters.
     * @return rewardAmount The reward for completion.
     * @return stakeRequired The stake required from the trainer.
     * @return deadline The task deadline.
     * @return status The current task status.
     * @return assignedTrainer The address of the assigned trainer (or address(0)).
     * @return trainerLockedStake The amount of trainer stake locked.
     * @return resultMetadataURI URI for submitted result.
     * @return reportedPerformanceMetric Trainer's reported performance.
     */
    function getTrainingTaskDetails(uint256 _taskId)
        external
        view
        taskExists(_taskId, false)
        returns (
            address requester,
            uint256 dataSetId,
            string memory modelArchitectureURI,
            string memory hyperparametersURI,
            uint256 rewardAmount,
            uint256 stakeRequired,
            uint256 deadline,
            TaskStatus status,
            address assignedTrainer,
            uint256 trainerLockedStake,
            string memory resultMetadataURI,
            uint256 reportedPerformanceMetric
        )
    {
        TrainingTask storage task = trainingTasks[_taskId];
        return (
            task.requester,
            task.dataSetId,
            task.modelArchitectureURI,
            task.hyperparametersURI,
            task.rewardAmount,
            task.stakeRequired,
            task.deadline,
            task.status,
            task.assignedTrainer,
            task.trainerLockedStake,
            task.resultMetadataURI,
            task.reportedPerformanceMetric
        );
    }

     /**
     * @dev Lists the IDs of tasks currently in Open status (simplified list).
     *      Note: This approach is inefficient for a large number of open tasks.
     * @return An array of open task IDs.
     */
    function listAvailableTrainingTasks() external view returns (uint256[] memory) {
         uint256[] memory openTaskIds = new uint256[](_openTaskIdList.length);
         uint256 count = 0;
         // Filter out tasks that are no longer Open (due to assignment/failure)
         for(uint i=0; i < _openTaskIdList.length; i++){
             if(trainingTasks[_openTaskIdList[i]].status == TaskStatus.Open){
                 openTaskIds[count] = _openTaskIdList[i];
                 count++;
             }
         }
         // Resize the array to the actual count
         uint256[] memory filteredOpenTaskIds = new uint256[](count);
         for(uint i=0; i < count; i++){
             filteredOpenTaskIds[i] = openTaskIds[i];
         }
         return filteredOpenTaskIds;
    }


    /**
     * @dev Allows a trainer to accept an open task. Requires the trainer to have
     *      sufficient unlocked stake and minimum reputation. Locks the required stake.
     * @param _taskId The ID of the task to accept.
     */
    function assignTaskToTrainer(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId, false)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        TrainingTask storage task = trainingTasks[_taskId];
        address trainer = msg.sender;

        require(trainer != address(0), "Invalid trainer address");
        require(trainer != task.requester, "Requester cannot be the trainer");
        require(trainerReputation[trainer] >= minTrainerReputationToAssign, "Trainer does not have sufficient reputation");

        uint256 unlockedStake = _trainerStakes[trainer] - _trainerLockedStakes[trainer];
        require(unlockedStake >= task.stakeRequired, "Trainer does not have enough unlocked stake");

        // Check if trainer has access to the dataset
        require(dataSets[task.dataSetId].accessGranted[trainer], "Trainer must have access to the dataset");


        task.assignedTrainer = trainer;
        task.trainerLockedStake = task.stakeRequired;
        _trainerLockedStakes[trainer] += task.stakeRequired;
        task.status = TaskStatus.Assigned;

         // Remove from the list of open tasks (inefficient search)
         for(uint i=0; i < _openTaskIdList.length; i++){
             if(_openTaskIdList[i] == _taskId){
                 _openTaskIdList[i] = _openTaskIdList[_openTaskIdList.length - 1];
                 _openTaskIdList.pop();
                 break;
             }
         }


        emit TaskStatusUpdated(_taskId, TaskStatus.Open, TaskStatus.Assigned);
        emit TaskAssigned(_taskId, trainer, task.stakeRequired);
    }

     /**
     * @dev Returns the address of the trainer currently assigned to a task.
     * @param _taskId The ID of the task.
     * @return The address of the assigned trainer, or address(0) if not assigned.
     */
    function getAssignedTrainer(uint256 _taskId)
        external
        view
        taskExists(_taskId, false)
        returns (address)
    {
        return trainingTasks[_taskId].assignedTrainer;
    }

    /**
     * @dev Allows the assigned trainer to submit the results of the training task.
     *      Updates task status to AwaitingVerification. Must be called before deadline.
     * @param _taskId The ID of the task.
     * @param _resultMetadataURI URI pointing to the training results (e.g., model weights, logs).
     * @param _reportedPerformanceMetric A metric reported by the trainer (e.g., validation accuracy). Off-chain verification needed.
     */
    function submitTrainingResult(
        uint256 _taskId,
        string memory _resultMetadataURI,
        uint256 _reportedPerformanceMetric
    )
        external
        whenNotPaused
        taskExists(_taskId, false)
        taskStatusIs(_taskId, TaskStatus.Assigned)
        onlyAssignedTrainer(_taskId)
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(block.timestamp <= task.deadline, "Result submission is past the deadline");
        require(bytes(_resultMetadataURI).length > 0, "Result metadata URI cannot be empty");

        task.resultMetadataURI = _resultMetadataURI;
        task.reportedPerformanceMetric = _reportedPerformanceMetric;
        task.status = TaskStatus.ResultsSubmitted;

        emit ResultSubmitted(_taskId, msg.sender, _resultMetadataURI, _reportedPerformanceMetric);
        emit TaskStatusUpdated(_taskId, TaskStatus.Assigned, TaskStatus.ResultsSubmitted);
    }

     /**
     * @dev Retrieves the submitted result details for a task.
     * @param _taskId The ID of the task.
     * @return resultMetadataURI URI pointing to the training results.
     * @return reportedPerformanceMetric Trainer's reported performance metric.
     */
    function getTrainerResult(uint256 _taskId)
        external
        view
        taskExists(_taskId, false)
        returns (string memory, uint256)
    {
         TrainingTask storage task = trainingTasks[_taskId];
         require(task.status >= TaskStatus.ResultsSubmitted, "Results not yet submitted for this task");
         return (task.resultMetadataURI, task.reportedPerformanceMetric);
    }


    // --- Staking & Reputation Functions ---
    /**
     * @dev Allows a user to stake AIDTokens to become eligible trainers.
     *      Tokens are transferred from the user to the contract. Requires prior approval.
     * @param _amount The amount of AIDTokens to stake.
     */
    function stakeTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Stake amount must be positive");
        // Use transferFrom as contract needs permission to move user's tokens
        bool success = AIDToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer for staking failed");

        _trainerStakes[msg.sender] += _amount;

        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a trainer to unstake their unlocked AIDTokens.
     * @param _amount The amount of AIDTokens to unstake.
     */
    function unstakeTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Unstake amount must be positive");
        uint256 unlockedStake = _trainerStakes[msg.sender] - _trainerLockedStakes[msg.sender];
        require(unlockedStake >= _amount, "Not enough unlocked stake");

        _trainerStakes[msg.sender] -= _amount;

        bool success = AIDToken.transfer(msg.sender, _amount);
        require(success, "Token transfer for unstaking failed");

        emit TokensUnstaked(msg.sender, _amount);
    }

     /**
     * @dev Returns the total AIDToken stake of a trainer (locked + unlocked).
     * @param _trainer The address of the trainer.
     * @return The total staked amount.
     */
    function getTrainerStake(address _trainer) external view returns (uint256) {
        return _trainerStakes[_trainer];
    }

     /**
     * @dev Returns the unlocked AIDToken stake of a trainer.
     * @param _trainer The address of the trainer.
     * @return The unlocked staked amount.
     */
    function getTrainerUnlockedStake(address _trainer) external view returns (uint256) {
        // Protect against underflow if _trainerLockedStakes somehow exceeds _trainerStakes (shouldn't happen with correct logic)
        uint256 total = _trainerStakes[_trainer];
        uint256 locked = _trainerLockedStakes[_trainer];
        return total > locked ? total - locked : 0;
    }

    /**
     * @dev Returns the reputation score of a trainer.
     * @param _trainer The address of the trainer.
     * @return The reputation score.
     */
    function getTrainerReputation(address _trainer) external view returns (uint256) {
        return trainerReputation[_trainer];
    }


    // --- Task Resolution Functions ---
    /**
     * @dev Allows the task requester to mark a task as successfully verified.
     *      Requires the task to be in ResultsSubmitted status.
     *      Does NOT transfer reward or release stake here; trainer claims separately.
     *      Note: Off-chain verification process is assumed before calling this.
     * @param _taskId The ID of the task to verify.
     */
    function verifyTrainingTask(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId, false)
        taskStatusIs(_taskId, TaskStatus.ResultsSubmitted)
        onlyTaskRequester(_taskId)
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(block.timestamp <= task.deadline + 7 days, "Verification period expired"); // Example verification period

        task.status = TaskStatus.Verified;

        // Trainer reputation updated only upon claiming reward (guarantees reward transfer success)
        // Trainer stake remains locked until claimed

        emit TaskStatusUpdated(_taskId, TaskStatus.ResultsSubmitted, TaskStatus.Verified);
        emit TaskVerified(_taskId, msg.sender);
    }

    /**
     * @dev Allows the task requester to mark a task as failed.
     *      Handles stake and reputation based on the failure reason.
     * @param _taskId The ID of the task to fail.
     * @param _reason The reason for failure.
     */
    function failTrainingTask(uint256 _taskId, FailureReason _reason)
        external
        whenNotPaused
        taskExists(_taskId, false)
        onlyTaskRequester(_taskId)
        // Can fail from Open, Assigned, or ResultsSubmitted
        require(trainingTasks[_taskId].status == TaskStatus.Open ||
                trainingTasks[_taskId].status == TaskStatus.Assigned ||
                trainingTasks[_taskId].status == TaskStatus.ResultsSubmitted,
                "Task is not in a state that can be failed by requester");
    {
        TrainingTask storage task = trainingTasks[_taskId];
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.Failed;
        task.failureReason = _reason;

        address trainer = task.assignedTrainer; // Can be address(0) if not assigned

        // Handle stake and reward based on status/reason
        if (oldStatus == TaskStatus.Assigned || oldStatus == TaskStatus.ResultsSubmitted) {
             require(trainer != address(0), "Assigned trainer should exist in this state");
            // Task had a trainer assigned
            if (_reason == FailureReason.TrainerFailed) {
                // Slash trainer's locked stake, return remaining stake and reward to requester
                uint256 slashedAmount = (task.trainerLockedStake * failedTaskStakeSlashRatio) / 100;
                uint256 trainerStakeReturn = task.trainerLockedStake - slashedAmount;

                 _trainerLockedStakes[trainer] -= task.trainerLockedStake;
                 _trainerStakes[trainer] -= slashedAmount; // Reduce total stake by slashed amount

                 // No direct transfer here; trainer/requester claims their portion
                 // Reputation decreases for trainer
                 if (trainerReputation[trainer] > 0) {
                     trainerReputation[trainer]--;
                     emit TrainerReputationUpdated(trainer, trainerReputation[trainer]);
                 }

                 emit TaskFailed(_taskId, _reason);
                 emit TaskStatusUpdated(_taskId, oldStatus, TaskStatus.Failed);
                 // Claim functions will handle actual token transfers
            } else { // DatasetIssue or Other (if trainer assigned) - Assume no fault of trainer
                 // Return trainer's full locked stake, return reward to requester
                 _trainerLockedStakes[trainer] -= task.trainerLockedStake;
                 // Trainer's stake remains in _trainerStakes, can be unstaked later
                 // No reputation change

                 emit TaskFailed(_taskId, _reason);
                 emit TaskStatusUpdated(_taskId, oldStatus, TaskStatus.Failed);
                 // Claim functions handle transfers
            }
        } else { // TaskStatus.Open or RequesterCancelled before assignment
             require(trainer == address(0), "No trainer should be assigned in this state");
             // Return full reward to requester
             // No trainer stake involved
             emit TaskFailed(_taskId, _reason);
             emit TaskStatusUpdated(_taskId, oldStatus, TaskStatus.Failed);
             // Claim function handles transfer
        }

         // If it was Open, remove from the list (inefficient search)
         if(oldStatus == TaskStatus.Open){
             for(uint i=0; i < _openTaskIdList.length; i++){
                 if(_openTaskIdList[i] == _taskId){
                     _openTaskIdList[i] = _openTaskIdList[_openTaskIdList.length - 1];
                     _openTaskIdList.pop();
                     break;
                 }
             }
         }
    }

    /**
     * @dev Allows the assigned trainer to claim their reward for a successfully Verified task.
     *      Also releases their locked stake and increases their reputation.
     * @param _taskId The ID of the task.
     */
    function claimTrainingReward(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId, false)
        taskStatusIs(_taskId, TaskStatus.Verified)
        onlyAssignedTrainer(_taskId)
    {
        TrainingTask storage task = trainingTasks[_taskId];

        uint256 reward = task.rewardAmount;
        uint256 lockedStake = task.trainerLockedStake;

        // Prevent double claim
        require(reward > 0 || lockedStake > 0, "Reward or stake already claimed/zero"); // Simple check

        // Transfer reward to trainer
        task.rewardAmount = 0; // Mark reward as claimed
        bool successReward = AIDToken.transfer(msg.sender, reward);
        require(successReward, "Reward token transfer failed");

        // Release locked stake
        task.trainerLockedStake = 0; // Mark stake as released
        _trainerLockedStakes[msg.sender] -= lockedStake;
        // _trainerStakes is NOT decreased; the released stake becomes unlocked stake

        // Increase trainer reputation
        trainerReputation[msg.sender]++;

        emit TrainingRewardClaimed(_taskId, msg.sender, reward);
        emit TrainerStakeReturned(_taskId, msg.sender, lockedStake); // Trainer's stake is returned to their total balance
        emit TrainerReputationUpdated(msg.sender, trainerReputation[msg.sender]);
    }

    /**
     * @dev Allows the task requester to claim back the reward amount if the task failed
     *      and the reward was not paid out (e.g., Task failed with DatasetIssue, Other, or was Open/Assigned and failed).
     * @param _taskId The ID of the task.
     */
    function claimTaskRequesterRefund(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId, false)
        taskStatusIs(_taskId, TaskStatus.Failed)
        onlyTaskRequester(_taskId)
    {
        TrainingTask storage task = trainingTasks[_taskId];
        // Refund is only possible if reward was not claimed by trainer AND failure reason implies refund
        require(task.rewardAmount > 0, "Reward already claimed or zero"); // rewardAmount holds unclaimed reward

        // Check failure reason - Requester gets refund unless TrainerFailed AND reward was transferred
        // (In TrainerFailed case, reward stays in contract balance if not claimed, or transferred to requester via claim)
        // The logic in failTrainingTask already determines if trainer gets reward or not by state transition.
        // If task.rewardAmount is still > 0, it means it wasn't transferred to trainer.

        uint256 refundAmount = task.rewardAmount;
        task.rewardAmount = 0; // Mark reward as refunded

        bool success = AIDToken.transfer(msg.sender, refundAmount);
        require(success, "Requester refund token transfer failed");

        emit TaskRequesterRefunded(_taskId, msg.sender, refundAmount);
    }

     /**
     * @dev Allows the assigned trainer to claim back their locked stake after a task is finalized (Verified or Failed).
     *      For Failed tasks with TrainerFailed reason, the slashed amount is NOT returned.
     * @param _taskId The ID of the task.
     */
    function claimTrainerStakeReturn(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId, false)
        onlyAssignedTrainer(_taskId)
         require(trainingTasks[_taskId].status == TaskStatus.Verified ||
                 trainingTasks[_taskId].status == TaskStatus.Failed,
                 "Task must be Verified or Failed to claim stake");
    {
         TrainingTask storage task = trainingTasks[_taskId];
         // Check if stake has already been released
         require(task.trainerLockedStake > 0, "Trainer stake already released for this task");

         uint256 stakeToReturn = task.trainerLockedStake;

         // Release locked stake from trainer's locked balance
         _trainerLockedStakes[msg.sender] -= stakeToReturn;

         // task.trainerLockedStake is set to 0 when stake is handled (either returned or partially slashed/lost)
         // In failTrainingTask(TrainerFailed), _trainerStakes was reduced by the slashed amount.
         // In failTrainingTask(DatasetIssue/Other) or verifyTrainingTask, trainerLockedStake was marked for return.
         // The tokens are already in the trainer's total stake (_trainerStakes) if not slashed.
         // No token transfer out of the contract here, it's just moving from locked to unlocked balance.
         // The actual stake return happens as part of claimTrainingReward or the failure logic reducing _trainerStakes.

         task.trainerLockedStake = 0; // Mark as handled

         // Note: Actual token transfer for stake is either part of claimTrainingReward (full return)
         // or part of the failTrainingTask logic (partial slash handled there).
         // This function only updates the locked state and emits an event.

         emit TrainerStakeReturned(_taskId, msg.sender, stakeToReturn);
    }


    // --- Utility Functions ---
    /**
     * @dev Returns the current status of a training task.
     * @param _taskId The ID of the task.
     * @return The current TaskStatus.
     */
    function getTaskStatus(uint256 _taskId)
        external
        view
        taskExists(_taskId, false)
        returns (TaskStatus)
    {
        return trainingTasks[_taskId].status;
    }

    /**
     * @dev Returns the address of the task requester.
     * @param _taskId The ID of the task.
     * @return The address of the task requester.
     */
    function getTaskRequester(uint256 _taskId)
        external
        view
        taskExists(_taskId, false)
        returns (address)
    {
        return trainingTasks[_taskId].requester;
    }

    // Additional Potential Functions (Could add these to reach >20 easily,
    // or enhance existing ones):
    // 30. setMinTrainerReputationToAssign(uint256 _minReputation): Owner sets min reputation config.
    // 31. setFailedTaskStakeSlashRatio(uint256 _ratio): Owner sets slash ratio config.
    // 32. getDataDataSetAccessList(uint256 _dataSetId): Returns array of addresses with access (inefficient for large lists).
    // 33. cancelOpenTrainingTask(uint256 _taskId): Requester cancels task before assignment, gets reward back. (Can be integrated into failTask or a separate function). Let's add this.
    // 34. getAIDTokenAddress(): View AIDToken address. (Implicit with public variable, but explicit getter is common).

    /**
     * @dev Allows the contract owner to set the minimum reputation required for a trainer to accept a task.
     * @param _minReputation The new minimum reputation value.
     */
    function setMinTrainerReputationToAssign(uint256 _minReputation) external onlyOwner {
        minTrainerReputationToAssign = _minReputation;
    }

    /**
     * @dev Allows the contract owner to set the percentage of trainer stake to slash on failure (TrainerFailed reason).
     * @param _ratio The new slash ratio (0-100).
     */
    function setFailedTaskStakeSlashRatio(uint256 _ratio) external onlyOwner {
        require(_ratio <= 100, "Slash ratio cannot exceed 100");
        failedTaskStakeSlashRatio = _ratio;
    }

    /**
     * @dev Returns the list of addresses that have access granted to a specific dataset (excluding owner).
     *      Note: Inefficient for very large access lists.
     * @param _dataSetId The ID of the dataset.
     * @return An array of addresses with access.
     */
    function getDataDataSetAccessList(uint256 _dataSetId)
        external
        view
        taskExists(_dataSetId, true)
        returns (address[] memory)
    {
         // Filter out the owner if they were pushed into the list explicitly
         address[] storage rawList = dataSets[_dataSetId].accessGranteeList;
         uint256 count = 0;
         for(uint i=0; i < rawList.length; i++){
             if(rawList[i] != dataSets[_dataSetId].owner){
                 count++;
             }
         }

         address[] memory accessList = new address[](count);
         uint256 current = 0;
          for(uint i=0; i < rawList.length; i++){
             if(rawList[i] != dataSets[_dataSetId].owner){
                 accessList[current] = rawList[i];
                 current++;
             }
         }
         return accessList;
    }

     /**
     * @dev Allows the task requester to cancel an open training task before it is assigned.
     *      Refunds the reward amount back to the requester.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelOpenTrainingTask(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId, false)
        taskStatusIs(_taskId, TaskStatus.Open)
        onlyTaskRequester(_taskId)
    {
        TrainingTask storage task = trainingTasks[_taskId];
        uint256 reward = task.rewardAmount;

        // Mark reward as refunded (prevents claim)
        task.rewardAmount = 0;
        // Update status
        task.status = TaskStatus.Failed; // Mark as failed due to cancellation
        task.failureReason = FailureReason.RequesterCancelled;

         // Remove from the list of open tasks (inefficient search)
         for(uint i=0; i < _openTaskIdList.length; i++){
             if(_openTaskIdList[i] == _taskId){
                 _openTaskIdList[i] = _openTaskIdList[_openTaskIdList.length - 1];
                 _openTaskIdList.pop();
                 break;
             }
         }

        // Transfer reward tokens back to requester
        bool success = AIDToken.transfer(msg.sender, reward);
        require(success, "Requester refund token transfer failed during cancellation");

        emit TaskStatusUpdated(_taskId, TaskStatus.Open, TaskStatus.Failed);
        emit TaskFailed(_taskId, FailureReason.RequesterCancelled);
        emit TaskRequesterRefunded(_taskId, msg.sender, reward);
    }

    /**
     * @dev Returns the address of the AIDToken used by the contract.
     */
    function getAIDTokenAddress() external view returns (address) {
        return address(AIDToken);
    }
}
```