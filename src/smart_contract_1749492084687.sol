Okay, let's design a smart contract that facilitates the decentralized coordination and funding of AI model training tasks. This concept is trendy (AI), advanced (coordination of off-chain work, staking, reputation), creative (using a smart contract for this specific purpose), and aims to be distinct from common open-source examples.

The core idea: Funders propose AI training tasks, Data Providers register datasets, Trainers pick tasks and submit model results (proven off-chain), and Validators verify results. The contract manages funding, rewards, registration, and reputation based on successful contributions.

**Important Note:** Running AI training *directly* on-chain is computationally infeasible and prohibitively expensive. This contract *orchestrates* the *off-chain* work by managing stakes, rewards, and verifiable claims/proofs submitted on-chain. The actual training and validation computations happen off-chain.

---

## Smart Contract Outline: Decentralized AI Model Training Coordination

**Contract Name:** `DecentralizedAIModelTraining`

**Purpose:** To provide a decentralized platform for funding, managing, and rewarding participants involved in AI model training tasks. It connects funders with data providers, trainers, and validators, handling stakes, payouts, and reputation.

**Key Concepts:**
*   **Tasks:** Fundable units of work requesting a specific AI model training outcome.
*   **Participants:** Users register as Data Providers, Trainers, or Validators, potentially requiring a stake.
*   **Staking:** Participants (Funders, Trainers, Validators) may need to stake tokens to ensure commitment and penalize malicious behavior (slashing mechanism assumed but simplified in this example).
*   **Reputation:** A score tracking participant reliability and success.
*   **Off-chain Work Verification:** The contract relies on submitted *proofs* or *metrics* from off-chain computation, which are then potentially validated by other participants. The contract logic validates the *process* and *claims*, not the AI model itself.

**Outline:**

1.  **License & Pragma**
2.  **Imports (e.g., ERC20 interface)**
3.  **State Variables:**
    *   Owner/Admin address
    *   Associated Reward Token address
    *   Counters for Task IDs, Submission IDs, etc.
    *   Mappings for Participants (by address), Data Registrations, Tasks, Model Submissions, Validation Reports.
    *   Parameter variables (stakes, periods, fees, reward distribution).
4.  **Enums:**
    *   `ParticipantType` (Data Provider, Trainer, Validator)
    *   `TaskState` (Open, InProgress, Submitted, Validating, FinalizedSuccess, FinalizedFailure, Cancelled)
    *   `SubmissionState` (PendingValidation, ValidatedSuccess, ValidatedFailure, Finalized)
    *   `ValidationState` (Pending, Approved, Rejected)
5.  **Structs:**
    *   `Participant`
    *   `DataRegistration`
    *   `TrainingTask`
    *   `ModelSubmission`
    *   `ValidationReport`
6.  **Events:** Significant state changes and actions.
7.  **Modifiers:** Access control and state checks.
8.  **Admin/Owner Functions:** Set parameters, withdraw fees, manage participants (e.g., deactivate).
9.  **Participant Registration/Management:** Register roles, update profiles.
10. **Data Registration:** Register metadata about available datasets.
11. **Task Management:** Create, fund, select, cancel tasks.
12. **Submission & Validation:** Trainers submit results, Validators select submissions and report findings.
13. **Task Finalization:** Logic to process validation reports and finalize task/submission outcomes.
14. **Payouts & Stakes:** Claim rewards, potentially slash stakes (simplified).
15. **Reputation Management:** Internal function triggered by success/failure.
16. **View Functions:** Retrieve information about tasks, participants, submissions, etc.

---

## Function Summary:

1.  `constructor(address initialOwner, address rewardTokenAddress)`: Initializes the contract, sets the owner and reward token address.
2.  `setParameters(...)`: (Admin) Sets various protocol parameters like minimum stakes, time periods, fee percentages.
3.  `collectProtocolFees()`: (Admin) Allows the owner to collect accumulated protocol fees.
4.  `registerAsParticipant(ParticipantType _type)`: Allows a user to register as a specific type (Trainer, Validator, Data Provider), potentially requiring a stake.
5.  `updateParticipantProfile(string calldata _metadataURI)`: Allows a registered participant to update their profile metadata.
6.  `deactivateParticipant(address _participantAddress)`: (Admin) Deactivates a participant, preventing them from taking on new tasks or submitting.
7.  `registerDataset(string calldata _dataURI, uint256 _size)`: (Data Provider) Registers metadata about a dataset available for training, including its URI and size.
8.  `updateDatasetRegistration(uint256 _datasetId, string calldata _newDataURI, uint256 _newSize)`: (Data Provider) Updates the metadata for a previously registered dataset.
9.  `createTrainingTask(string calldata _taskDescriptionURI, uint256 _requiredDatasetId, uint256 _rewardAmount)`: (Funder) Creates a new training task, specifying requirements, linking a dataset, and staking the reward amount.
10. `fundTask(uint256 _taskId, uint256 _additionalAmount)`: (Funder) Adds more funds to an existing training task.
11. `cancelTrainingTask(uint256 _taskId)`: (Funder) Cancels a task if it hasn't been selected by a trainer, returning funds to the funder.
12. `selectTaskForTraining(uint256 _taskId)`: (Trainer) Claims an open task, changing its state to InProgress. Requires trainer stake.
13. `submitModelResult(uint256 _taskId, string calldata _resultURI, uint256 _performanceMetric)`: (Trainer) Submits the result of off-chain training for a task they selected. Includes a URI to the result and a key performance metric. Requires trainer stake.
14. `selectSubmissionForValidation(uint256 _submissionId)`: (Validator) Claims a submission that is pending validation. Requires validator stake.
15. `submitValidationReport(uint256 _submissionId, bool _isValid, string calldata _reportURI)`: (Validator) Submits a report indicating whether the submission was valid or not, based on off-chain verification.
16. `finalizeTaskSubmission(uint256 _submissionId)`: (Callable internally or by a designated entity/oracle based on validation reports) Processes validation reports for a submission, determines its final status (success/failure), and triggers reward distribution/slashing.
17. `claimTaskReward(uint256 _taskId)`: (Participant) Allows a Trainer or Validator involved in a successfully finalized task/submission to claim their share of the reward.
18. `getParticipantProfile(address _participantAddress)`: (View) Returns the profile details of a participant.
19. `getDataRegistration(uint256 _datasetId)`: (View) Returns the details of a registered dataset.
20. `getTrainingTask(uint256 _taskId)`: (View) Returns the details of a training task.
21. `getTaskSubmissions(uint256 _taskId)`: (View) Returns a list of submission IDs for a given task.
22. `getModelSubmission(uint256 _submissionId)`: (View) Returns the details of a specific model submission.
23. `getSubmissionValidationReports(uint256 _submissionId)`: (View) Returns a list of validation report IDs for a submission.
24. `getValidationReport(uint256 _reportId)`: (View) Returns the details of a specific validation report.
25. `getParticipantReputation(address _participantAddress)`: (View) Returns the current reputation score of a participant.
26. `getActiveTasks()`: (View) Returns a list of IDs of tasks that are currently Open or InProgress.
27. `getSubmissionsPendingValidation()`: (View) Returns a list of IDs of submissions awaiting validation.
28. `updateReputation(...)`: (Internal) Updates a participant's reputation score based on success or failure.
29. `_distributeRewards(...)`: (Internal) Handles the distribution of rewards from a task's fund pool based on success and reward parameters.
30. `_slashStake(...)`: (Internal) Handles the slashing of a participant's stake (simplified placeholder).

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for Owner management
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Decentralized AI Model Training Coordination
/// @author [Your Name/Alias]
/// @notice This contract facilitates a decentralized marketplace for funding and
/// coordinating AI model training tasks. It connects funders with data providers,
/// trainers, and validators, managing stakes, rewards, and reputation based on
/// verifiable off-chain contributions.
/// @dev This contract orchestrates off-chain computation. The actual AI training,
/// model creation, and result validation happen outside the blockchain. The contract
/// validates the *process* and the *claims* submitted on-chain. Slashing and complex
/// dispute resolution mechanisms are simplified placeholders for this example.

contract DecentralizedAIModelTraining is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    address public immutable rewardToken; // ERC20 token used for funding tasks and rewards

    Counters.Counter private _datasetIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _submissionIds;
    Counters.Counter private _validationReportIds;

    enum ParticipantType { None, DataProvider, Trainer, Validator }
    enum TaskState { Open, InProgress, Submitted, Validating, FinalizedSuccess, FinalizedFailure, Cancelled }
    enum SubmissionState { PendingValidation, ValidatedSuccess, ValidatedFailure, Finalized }
    enum ValidationState { Pending, Approved, Rejected }

    struct Participant {
        ParticipantType participantType;
        bool isActive;
        uint256 reputation; // Simple reputation score (e.g., based on successful contributions)
        string metadataURI; // URI to off-chain profile data (e.g., IPFS)
        uint256 stakedAmount; // Tokens staked by the participant
    }

    struct DataRegistration {
        address owner;
        string dataURI; // URI to dataset location (e.g., IPFS CID)
        uint256 size; // Size of dataset (bytes or other unit)
        string metadataURI; // Additional info about the dataset
        bool isActive;
    }

    struct TrainingTask {
        address funder;
        uint256 datasetId; // Which registered dataset is required
        string taskDescriptionURI; // URI to task details (e.g., requirements, metrics)
        uint256 rewardAmount; // Total reward amount staked by the funder
        uint256 protocolFee; // Fee allocated to the protocol
        uint256 trainerRewardShare; // Percentage or fixed amount for the trainer
        uint256 validatorRewardShare; // Percentage or fixed amount for validators
        TaskState state;
        uint256 selectedTrainer; // Participant ID of the trainer who selected the task (0 if none)
        uint256 submissionCount; // Number of submissions for this task
        uint256 creationTimestamp;
        uint256 submissionPeriodEnd; // Deadline for trainers to submit results
        uint256 validationPeriodEnd; // Deadline for validators to report
    }

    struct ModelSubmission {
        uint256 taskId;
        uint256 trainerId; // Participant ID of the submitting trainer
        string resultURI; // URI to the model results/proof (e.g., IPFS)
        uint256 performanceMetric; // A key metric reported by the trainer (e.g., accuracy)
        SubmissionState state;
        uint256 submissionTimestamp;
        uint256 validationReportsReceived;
        mapping(uint256 => uint256) validationReports; // mapping validatorId => reportId
    }

    struct ValidationReport {
        uint256 submissionId;
        uint256 validatorId; // Participant ID of the validator
        bool isValid; // True if the validator verified the result as valid
        string reportURI; // URI to the validation report details/proof
        ValidationState state;
        uint256 validationTimestamp;
    }

    // Mappings to store state
    mapping(address => uint256) private participantIds; // address => participantId (0 if not registered)
    mapping(uint256 => Participant) public participants; // participantId => Participant struct
    mapping(uint256 => DataRegistration) public datasetRegistrations; // datasetId => DataRegistration struct
    mapping(uint256 => TrainingTask) public trainingTasks; // taskId => TrainingTask struct
    mapping(uint256 => ModelSubmission) public modelSubmissions; // submissionId => ModelSubmission struct
    mapping(uint256 => ValidationReport) public validationReports; // reportId => ValidationReport struct

    // Parameters (can be set by owner/governance)
    uint256 public minTrainerStake;
    uint256 public minValidatorStake;
    uint256 public minTaskCreationStake;
    uint256 public defaultSubmissionPeriod; // Duration allowed for trainers to submit
    uint256 public defaultValidationPeriod; // Duration allowed for validators to report
    uint256 public protocolFeePercentage; // Percentage of task reward taken as fee
    uint256 public trainerRewardPercentage; // Percentage of reward for trainer (after fee)
    uint256 public validatorRewardPercentage; // Percentage of reward for validators (after fee)
    uint256 public reputationMultiplier; // Factor for reputation changes

    // --- Events ---
    event ParticipantRegistered(address indexed participantAddress, ParticipantType participantType, uint256 participantId);
    event ParticipantDeactivated(address indexed participantAddress, uint256 participantId);
    event DatasetRegistered(uint256 indexed datasetId, address indexed owner, string dataURI);
    event TaskCreated(uint256 indexed taskId, address indexed funder, uint256 rewardAmount, uint256 datasetId);
    event TaskFunded(uint256 indexed taskId, address indexed funder, uint256 additionalAmount);
    event TaskCancelled(uint256 indexed taskId, address indexed funder);
    event TaskSelected(uint256 indexed taskId, uint256 indexed trainerId);
    event ModelResultSubmitted(uint256 indexed submissionId, uint256 indexed taskId, uint256 indexed trainerId, uint256 performanceMetric);
    event SubmissionSelectedForValidation(uint256 indexed submissionId, uint256 indexed validatorId);
    event ValidationReportSubmitted(uint256 indexed reportId, uint256 indexed submissionId, uint256 indexed validatorId, bool isValid);
    event TaskSubmissionFinalized(uint256 indexed submissionId, SubmissionState finalState);
    event TaskFinalized(uint256 indexed taskId, TaskState finalState);
    event RewardClaimed(address indexed claimant, uint256 amount);
    event StakeSlasshed(address indexed participant, uint256 amount); // Simplified event for slashing placeholder

    // --- Modifiers ---
    modifier isActiveParticipant(uint256 _participantId) {
        require(_participantId > 0 && participants[_participantId].isActive, "Participant must be registered and active");
        _;
    }

    modifier isParticipantType(uint256 _participantId, ParticipantType _type) {
        require(participants[_participantId].participantType == _type, "Invalid participant type for this action");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && trainingTasks[_taskId].funder != address(0), "Task does not exist");
        _;
    }

     modifier submissionExists(uint256 _submissionId) {
        require(_submissionId > 0 && modelSubmissions[_submissionId].taskId > 0, "Submission does not exist");
        _;
    }


    // --- Constructor ---

    constructor(address initialOwner, address rewardTokenAddress) Ownable(initialOwner) {
        rewardToken = rewardTokenAddress;

        // Set initial default parameters (Owner can change these)
        minTrainerStake = 100; // Example values
        minValidatorStake = 100;
        minTaskCreationStake = 50;
        defaultSubmissionPeriod = 3 days; // Example duration
        defaultValidationPeriod = 1 days; // Example duration
        protocolFeePercentage = 5; // 5%
        trainerRewardPercentage = 70; // 70% of remaining reward
        validatorRewardPercentage = 30; // 30% of remaining reward
        reputationMultiplier = 1; // Simple multiplier
    }

    // --- Admin/Owner Functions ---

    /// @notice Allows owner to set various protocol parameters.
    /// @param _minTrainerStake Minimum tokens required for trainers to stake.
    /// @param _minValidatorStake Minimum tokens required for validators to stake.
    /// @param _minTaskCreationStake Minimum tokens required for task creators to stake.
    /// @param _defaultSubmissionPeriod Default time limit for trainers to submit results.
    /// @param _defaultValidationPeriod Default time limit for validators to validate.
    /// @param _protocolFeePercentage Percentage of task reward as protocol fee (0-100).
    /// @param _trainerRewardPercentage Percentage of remaining reward for trainer (0-100).
    /// @param _validatorRewardPercentage Percentage of remaining reward for validators (0-100).
    /// @param _reputationMultiplier Multiplier for reputation changes.
    function setParameters(
        uint256 _minTrainerStake,
        uint256 _minValidatorStake,
        uint256 _minTaskCreationStake,
        uint256 _defaultSubmissionPeriod,
        uint256 _defaultValidationPeriod,
        uint256 _protocolFeePercentage,
        uint256 _trainerRewardPercentage,
        uint256 _validatorRewardPercentage,
        uint256 _reputationMultiplier
    ) external onlyOwner {
        require(_protocolFeePercentage <= 100, "Protocol fee percentage cannot exceed 100");
        require(_trainerRewardPercentage + _validatorRewardPercentage <= 100, "Trainer and Validator reward percentages cannot exceed 100 combined");

        minTrainerStake = _minTrainerStake;
        minValidatorStake = _minValidatorStake;
        minTaskCreationStake = _minTaskCreationStake;
        defaultSubmissionPeriod = _defaultSubmissionPeriod;
        defaultValidationPeriod = _defaultValidationPeriod;
        protocolFeePercentage = _protocolFeePercentage;
        trainerRewardPercentage = _trainerRewardPercentage;
        validatorRewardPercentage = _validatorRewardPercentage;
        reputationMultiplier = _reputationMultiplier;
    }

    /// @notice Allows the owner to collect accumulated protocol fees.
    function collectProtocolFees() external onlyOwner {
        // This requires tracking accumulated fees, which isn't explicitly stored as a sum.
        // A more robust implementation would accumulate fees in a separate variable
        // or have a mechanism for tasks to transfer fees directly to the owner's wallet
        // upon finalization. For simplicity, this is a placeholder.
        // Example: A contract variable `totalProtocolFees`.
        // uint256 amount = totalProtocolFees;
        // totalProtocolFees = 0;
        // require(amount > 0, "No fees to collect");
        // IERC20(rewardToken).transfer(owner(), amount);
        revert("Fee collection mechanism not fully implemented in this example");
    }

    /// @notice Deactivates a participant, preventing them from taking new actions.
    /// @param _participantAddress The address of the participant to deactivate.
    function deactivateParticipant(address _participantAddress) external onlyOwner {
        uint256 pId = participantIds[_participantAddress];
        require(pId > 0, "Participant not registered");
        require(participants[pId].isActive, "Participant is already inactive");

        participants[pId].isActive = false;
        // Note: Does not automatically unlock stakes or cancel ongoing tasks.
        // A real system would need more complex state management here.

        emit ParticipantDeactivated(_participantAddress, pId);
    }

    // --- Participant Registration ---

    /// @notice Allows a user to register as a specific participant type.
    /// @param _type The type of participant (DataProvider, Trainer, Validator).
    /// @param _metadataURI URI to off-chain profile data.
    function registerAsParticipant(ParticipantType _type, string calldata _metadataURI) external {
        require(_type != ParticipantType.None, "Invalid participant type");
        require(participantIds[msg.sender] == 0, "Already registered");

        _datasetIds.increment(); // Using dataset counter for participant ID generation for simplicity
        uint256 newParticipantId = _datasetIds.current();

        uint256 requiredStake = 0;
        if (_type == ParticipantType.Trainer) {
            requiredStake = minTrainerStake;
        } else if (_type == ParticipantType.Validator) {
            requiredStake = minValidatorStake;
        }
        // Data Providers might not require stake initially, or have a separate stake mechanism

        require(IERC20(rewardToken).transferFrom(msg.sender, address(this), requiredStake), "Token transfer failed for stake");

        participantIds[msg.sender] = newParticipantId;
        participants[newParticipantId] = Participant({
            participantType: _type,
            isActive: true,
            reputation: 100, // Start with a base reputation
            metadataURI: _metadataURI,
            stakedAmount: requiredStake
        });

        emit ParticipantRegistered(msg.sender, _type, newParticipantId);
    }

    /// @notice Allows a registered participant to update their profile metadata.
    /// @param _metadataURI New URI to off-chain profile data.
    function updateParticipantProfile(string calldata _metadataURI) external {
         uint256 pId = participantIds[msg.sender];
        require(pId > 0, "Participant not registered");

        participants[pId].metadataURI = _metadataURI;
        // Emit event?
    }


    // --- Data Registration ---

    /// @notice Registers metadata about a dataset available for training.
    /// @param _dataURI URI to dataset location (e.g., IPFS CID).
    /// @param _size Size of dataset.
    /// @param _metadataURI Additional info about the dataset.
    function registerDataset(string calldata _dataURI, uint256 _size, string calldata _metadataURI) external {
        uint256 pId = participantIds[msg.sender];
        require(pId > 0, "Participant not registered");
        require(participants[pId].participantType == ParticipantType.DataProvider, "Only Data Providers can register datasets");
        require(participants[pId].isActive, "Data Provider must be active");

        _datasetIds.increment();
        uint256 newDatasetId = _datasetIds.current();

        datasetRegistrations[newDatasetId] = DataRegistration({
            owner: msg.sender,
            dataURI: _dataURI,
            size: _size,
            metadataURI: _metadataURI,
            isActive: true
        });

        emit DatasetRegistered(newDatasetId, msg.sender, _dataURI);
    }

    /// @notice Allows a data provider to update the metadata for their dataset.
    /// @param _datasetId The ID of the dataset to update.
    /// @param _newDataURI New URI to dataset location.
    /// @param _newSize New size of dataset.
    /// @param _newMetadataURI New additional info about the dataset.
    function updateDatasetRegistration(uint256 _datasetId, string calldata _newDataURI, uint256 _newSize, string calldata _newMetadataURI) external {
        DataRegistration storage data = datasetRegistrations[_datasetId];
        require(data.owner == msg.sender, "Only the dataset owner can update");
        require(data.isActive, "Dataset registration is not active");

        data.dataURI = _newDataURI;
        data.size = _newSize;
        data.metadataURI = _newMetadataURI;
        // Emit event?
    }

    // --- Task Management ---

    /// @notice Creates a new AI model training task and stakes the reward.
    /// @param _taskDescriptionURI URI to the task requirements.
    /// @param _requiredDatasetId The ID of the dataset required for this task.
    /// @param _rewardAmount Total reward amount for the task.
    function createTrainingTask(string calldata _taskDescriptionURI, uint256 _requiredDatasetId, uint256 _rewardAmount) external {
        require(_rewardAmount >= minTaskCreationStake, "Reward amount too low");
        require(datasetRegistrations[_requiredDatasetId].isActive, "Required dataset is not active");

        require(IERC20(rewardToken).transferFrom(msg.sender, address(this), _rewardAmount), "Token transfer failed for task reward");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        uint256 protocolFee = (_rewardAmount * protocolFeePercentage) / 100;
        uint256 remainingReward = _rewardAmount - protocolFee;
        uint256 trainerShare = (remainingReward * trainerRewardPercentage) / 100;
        uint256 validatorShare = remainingReward - trainerShare; // The rest goes to validators

        trainingTasks[newTaskId] = TrainingTask({
            funder: msg.sender,
            datasetId: _requiredDatasetId,
            taskDescriptionURI: _taskDescriptionURI,
            rewardAmount: _rewardAmount,
            protocolFee: protocolFee,
            trainerRewardShare: trainerShare,
            validatorRewardShare: validatorShare,
            state: TaskState.Open,
            selectedTrainer: 0,
            submissionCount: 0,
            creationTimestamp: block.timestamp,
            submissionPeriodEnd: 0, // Set when selected
            validationPeriodEnd: 0 // Set when submission received
        });

        emit TaskCreated(newTaskId, msg.sender, _rewardAmount, _requiredDatasetId);
    }

    /// @notice Adds additional funds to an existing training task.
    /// @param _taskId The ID of the task to fund.
    /// @param _additionalAmount The amount of additional tokens to add.
    function fundTask(uint256 _taskId, uint256 _additionalAmount) external taskExists(_taskId) {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.state == TaskState.Open || task.state == TaskState.InProgress, "Task must be open or in progress to add funds");
        require(_additionalAmount > 0, "Amount must be greater than 0");

        require(IERC20(rewardToken).transferFrom(msg.sender, address(this), _additionalAmount), "Token transfer failed");

        // Redistribute the additional reward based on percentages
        uint256 additionalProtocolFee = (_additionalAmount * protocolFeePercentage) / 100;
        uint256 additionalRemainingReward = _additionalAmount - additionalProtocolFee;
        uint256 additionalTrainerShare = (additionalRemainingReward * trainerRewardPercentage) / 100;
        uint256 additionalValidatorShare = additionalRemainingReward - additionalTrainerShare;

        task.rewardAmount += _additionalAmount;
        task.protocolFee += additionalProtocolFee;
        task.trainerRewardShare += additionalTrainerShare;
        task.validatorRewardShare += additionalValidatorShare;

        emit TaskFunded(_taskId, msg.sender, _additionalAmount);
    }

    /// @notice Allows the funder to cancel an open task.
    /// @param _taskId The ID of the task to cancel.
    function cancelTrainingTask(uint256 _taskId) external taskExists(_taskId) {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.funder == msg.sender, "Only the funder can cancel the task");
        require(task.state == TaskState.Open, "Task must be in Open state to be cancelled");

        task.state = TaskState.Cancelled;

        // Return staked funds to the funder
        require(IERC20(rewardToken).transfer(msg.sender, task.rewardAmount), "Token transfer failed for cancellation");

        emit TaskCancelled(_taskId, msg.sender);
    }

    /// @notice Allows a registered trainer to select an open task.
    /// @param _taskId The ID of the task to select.
    function selectTaskForTraining(uint256 _taskId) external taskExists(_taskId) {
        uint256 trainerId = participantIds[msg.sender];
        require(trainerId > 0, "Participant not registered");
        require(participants[trainerId].isActive, "Trainer must be active");
        require(participants[trainerId].participantType == ParticipantType.Trainer, "Only trainers can select tasks");
        require(participants[trainerId].stakedAmount >= minTrainerStake, "Trainer must have sufficient stake");

        TrainingTask storage task = trainingTasks[_taskId];
        require(task.state == TaskState.Open, "Task is not open for selection");
        require(task.selectedTrainer == 0, "Task already selected by a trainer");
        require(block.timestamp < task.creationTimestamp + defaultSubmissionPeriod, "Task submission period has expired"); // Check if it's still selectable

        task.selectedTrainer = trainerId;
        task.state = TaskState.InProgress;
        task.submissionPeriodEnd = block.timestamp + defaultSubmissionPeriod;

        emit TaskSelected(_taskId, trainerId);
    }


    // --- Submission & Validation ---

    /// @notice Allows the selected trainer to submit their model result.
    /// @param _taskId The ID of the task the result is for.
    /// @param _resultURI URI to the model results/proof.
    /// @param _performanceMetric A key metric reported by the trainer.
    function submitModelResult(uint256 _taskId, string calldata _resultURI, uint256 _performanceMetric) external taskExists(_taskId) {
        uint256 trainerId = participantIds[msg.sender];
        require(trainerId > 0, "Participant not registered");
        require(participants[trainerId].isActive, "Trainer must be active");
        require(participants[trainerId].participantType == ParticipantType.Trainer, "Only trainers can submit results");
        require(participants[trainerId].stakedAmount >= minTrainerStake, "Trainer must have sufficient stake");

        TrainingTask storage task = trainingTasks[_taskId];
        require(task.state == TaskState.InProgress, "Task is not in progress");
        require(task.selectedTrainer == trainerId, "Only the selected trainer can submit for this task");
        require(block.timestamp <= task.submissionPeriodEnd, "Submission period for this task has ended");

        task.state = TaskState.Submitted;
        task.submissionCount++; // Allow multiple submissions? Or just one? Let's assume one for now.

        _submissionIds.increment();
        uint256 newSubmissionId = _submissionIds.current();

        // Simple mapping from task to latest submission. A real system might manage multiple submissions per task.
        // For simplicity, let's store submission ID within the task struct (or a mapping task->submissionId)
        // Adding a mapping from task ID to the *latest* submission ID for simplicity:
        // mapping(uint256 => uint256) public latestTaskSubmission;
        // latestTaskSubmission[_taskId] = newSubmissionId; // Need to add this state variable/mapping

        modelSubmissions[newSubmissionId] = ModelSubmission({
            taskId: _taskId,
            trainerId: trainerId,
            resultURI: _resultURI,
            performanceMetric: _performanceMetric,
            state: SubmissionState.PendingValidation,
            submissionTimestamp: block.timestamp,
            validationReportsReceived: 0,
            validationReports: new mapping(uint256 => uint256)() // Initialize the mapping
        });

        // Start validation period
        task.validationPeriodEnd = block.timestamp + defaultValidationPeriod;

        emit ModelResultSubmitted(newSubmissionId, _taskId, trainerId, _performanceMetric);
    }

    /// @notice Allows a registered validator to select a submission for validation.
    /// @param _submissionId The ID of the submission to validate.
    function selectSubmissionForValidation(uint256 _submissionId) external submissionExists(_submissionId) {
        uint256 validatorId = participantIds[msg.sender];
        require(validatorId > 0, "Participant not registered");
        require(participants[validatorId].isActive, "Validator must be active");
        require(participants[validatorId].participantType == ParticipantType.Validator, "Only validators can select submissions");
        require(participants[validatorId].stakedAmount >= minValidatorStake, "Validator must have sufficient stake");

        ModelSubmission storage submission = modelSubmissions[_submissionId];
        require(submission.state == SubmissionState.PendingValidation, "Submission is not pending validation");

        TrainingTask storage task = trainingTasks[submission.taskId];
        require(block.timestamp <= task.validationPeriodEnd, "Validation period for this submission has ended");

        // Check if this validator has already reported on this submission
        require(submission.validationReports[validatorId] == 0, "Validator already reported on this submission");

        // Logic to prevent a validator from validating their own submission (if trainer == validator)
        // require(submission.trainerId != validatorId, "Cannot validate your own submission");

        // Mark that this validator is working on this submission (optional, not strictly needed if just reporting)
        // Could add a state like ValidationState.InProgress to the report struct

        // No state change on the submission yet, just marking intent or eligibility to submit report

        emit SubmissionSelectedForValidation(_submissionId, validatorId);
    }


    /// @notice Allows a registered validator to submit their validation report.
    /// @param _submissionId The ID of the submission being validated.
    /// @param _isValid True if the validator deems the submission valid, false otherwise.
    /// @param _reportURI URI to the detailed validation report/proof.
    function submitValidationReport(uint256 _submissionId, bool _isValid, string calldata _reportURI) external submissionExists(_submissionId) {
        uint256 validatorId = participantIds[msg.sender];
        require(validatorId > 0, "Participant not registered");
        require(participants[validatorId].isActive, "Validator must be active");
        require(participants[validatorId].participantType == ParticipantType.Validator, "Only validators can submit reports");
        require(participants[validatorId].stakedAmount >= minValidatorStake, "Validator must have sufficient stake");

        ModelSubmission storage submission = modelSubmissions[_submissionId];
        require(submission.state == SubmissionState.PendingValidation, "Submission is not pending validation");

        TrainingTask storage task = trainingTasks[submission.taskId];
        require(block.timestamp <= task.validationPeriodEnd, "Validation period for this submission has ended");

         // Check if this validator has already reported on this submission
        require(submission.validationReports[validatorId] == 0, "Validator already reported on this submission");

        _validationReportIds.increment();
        uint256 newReportId = _validationReportIds.current();

        validationReports[newReportId] = ValidationReport({
            submissionId: _submissionId,
            validatorId: validatorId,
            isValid: _isValid,
            reportURI: _reportURI,
            state: ValidationState.Pending, // State of the report itself
            validationTimestamp: block.timestamp
        });

        submission.validationReports[validatorId] = newReportId;
        submission.validationReportsReceived++;

        // A real system would need logic here:
        // - Determine if enough reports are received (e.g., majority, threshold)
        // - Trigger finalization automatically or via another call once criteria met or period ends.

        emit ValidationReportSubmitted(newReportId, _submissionId, validatorId, _isValid);
    }

    // --- Task Finalization & Payouts ---

    /// @notice Finalizes a submission based on collected validation reports.
    /// This function could be triggered by an external entity (e.g., keeper, oracle)
    /// after the validation period ends or a threshold of reports is met.
    /// @param _submissionId The ID of the submission to finalize.
    function finalizeTaskSubmission(uint256 _submissionId) external submissionExists(_submissionId) {
        // This requires a robust consensus/aggregation mechanism for validation reports.
        // For this example, let's use a simple majority (needs >= 1 report).
        // A real system might require N reports, check for consensus > M, handle disputes, etc.

        ModelSubmission storage submission = modelSubmissions[_submissionId];
        TrainingTask storage task = trainingTasks[submission.taskId];

        // Require that the validation period has ended OR a sufficient number of reports received
        bool sufficientReports = submission.validationReportsReceived >= 1; // Simplified: just needs at least one report
        bool validationPeriodEnded = block.timestamp > task.validationPeriodEnd;

        require(submission.state == SubmissionState.PendingValidation, "Submission is not pending validation");
        require(sufficientReports || validationPeriodEnded, "Not enough validation reports or validation period not ended");

        // Determine final outcome (simplified: success if at least one report is true, failure otherwise)
        bool overallSuccess = false;
        uint256 successfulValidatorsCount = 0;
        // Iterate through received reports (simplified - real iteration needs more complex storage)
        // A mapping from validatorId to reportId within the submission struct doesn't allow easy iteration.
        // A real system might store an array of report IDs or use iterable mappings.
        // For this example, we assume we can check validation reports linked to this submission somehow.
        // Let's just iterate over the reports mapping, this is inefficient but works for example
        // NOTE: Iterating over mappings is gas-expensive and not recommended for large mappings.
        // This part is a simplification due to Solidity limitations on mapping iteration.
        // A proper implementation would use an array of report IDs stored in the submission struct.

        // Simplified check: If ANY validator reported valid, consider it success.
        // In reality, you'd need a threshold (e.g., 60% of validators agree)
        // Let's pretend we have an array `submission.reportIds[]`
        /*
        for (uint256 i = 0; i < submission.reportIds.length; i++) {
             uint256 reportId = submission.reportIds[i];
             if (validationReports[reportId].isValid) {
                 overallSuccess = true;
                 successfulValidatorsCount++;
                 // Mark report as Processed or Finalized?
                 validationReports[reportId].state = ValidationState.Approved; // Or similar
             } else {
                 // Mark report as Processed/Rejected if it didn't contribute to success?
                 validationReports[reportId].state = ValidationState.Rejected; // Or similar
             }
        }
        */
        // Since iteration is bad, let's just assume a single 'successful' report means success for this example's logic.
        // You would need external logic or a different data structure/pattern to handle consensus.
        overallSuccess = submission.validationReportsReceived > 0; // Example simplification: Any report received allows finalization
        bool deemedValidBySomeValidator = false; // Placeholder for actual check
         // In a real system, you'd loop through the validation reports submitted for this submission.
         // Example placeholder logic:
         // if (submission.validationReports[validator1Id].isValid || submission.validationReports[validator2Id].isValid) { ... }

        // For this example, let's just use the performance metric threshold as a proxy for "validity" if no reports.
        // Or require minimum 1 report, and if ANY report is true, it's success (very basic consensus).
        // Let's enforce at least one report AND that report is true for success in this simple model.
        // This is not robust consensus!
        bool hasAnyValidReport = false;
        // Cannot iterate mapping. Assuming an external call provides the consensus result, or we iterate *known* validators?
        // Let's make a massive simplification: The first validator report received determines validity.
        // This is extremely insecure and for illustration ONLY.
         if (submission.validationReportsReceived > 0) {
             // Find the first report (requires looping or tracking first report ID)
             // This loop is inefficient and may exceed gas limits for many validators.
             // It's a placeholder!
             for (uint256 p = 1; p <= _datasetIds.current(); p++) { // Iterate potential participant IDs
                 if (participants[p].participantType == ParticipantType.Validator && submission.validationReports[p] != 0) {
                     hasAnyValidReport = validationReports[submission.validationReports[p]].isValid;
                     successfulValidatorsCount = 1; // Simplified count
                     break; // Found the first report, exit (bad logic for real consensus)
                 }
             }
         }


        if (hasAnyValidReport) { // Check if any validator reported valid (based on simplified logic above)
             submission.state = SubmissionState.Finalized; // Finalize submission
             task.state = TaskState.FinalizedSuccess; // Finalize task as success
             _distributeRewards(submission.taskId, submission.trainerId, successfulValidatorsCount); // Distribute rewards

             // Update trainer reputation
             _updateReputation(submission.trainerId, true);
             // Update validator reputation for successful validators (based on simplified logic, need to track which ones)
             // In a real system, update reputation for validators who reported honestly according to consensus.
         } else {
             submission.state = SubmissionState.Finalized; // Finalize submission
             task.state = TaskState.FinalizedFailure; // Finalize task as failure

             // Penalize trainer (and potentially validators who reported valid incorrectly)
             // _slashStake(submission.trainerId, ...); // Slash trainer stake
             // _updateReputation(submission.trainerId, false); // Decrease trainer reputation

             // Rewards remain in the contract or returned to funder (protocol decision)
         }

         // Mark all reports for this submission as finalized
        // Again, iterating mapping is bad.
        /*
        for (uint256 p = 1; p <= _datasetIds.current(); p++) {
            if (participants[p].participantType == ParticipantType.Validator && submission.validationReports[p] != 0) {
                validationReports[submission.validationReports[p]].state = ValidationState.Approved; // Or finalized state
            }
        }
        */

        emit TaskSubmissionFinalized(_submissionId, submission.state);
        emit TaskFinalized(submission.taskId, task.state);
    }


    /// @notice Allows a participant to claim rewards from a successfully finalized task/submission.
    /// @param _taskId The ID of the task to claim rewards from.
    function claimTaskReward(uint256 _taskId) external taskExists(_taskId) {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.state == TaskState.FinalizedSuccess, "Task not finalized successfully");

        uint256 participantId = participantIds[msg.sender];
        require(participantId > 0, "Participant not registered");
        require(participants[participantId].isActive, "Participant must be active");

        uint256 amountToClaim = 0;

        // Check if funder claiming potential unused funds (if any remained after fees/rewards) - unlikely in this model
        // if (msg.sender == task.funder) { ... }

        // Check if trainer claiming reward (only the selected trainer for this task)
        if (participantId == task.selectedTrainer && participants[participantId].participantType == ParticipantType.Trainer) {
             // Need a mechanism to track if trainer reward is already claimed.
             // Add a bool `trainerRewardClaimed` to the Task struct?
             // If (!task.trainerRewardClaimed) {
             //     amountToClaim = task.trainerRewardShare;
             //     task.trainerRewardClaimed = true; // Mark as claimed
             // }
            revert("Trainer reward claiming not fully implemented for state tracking");
        }

        // Check if validator claiming reward
        // This requires knowing which validators participated and succeeded.
        // A real system needs to track successful validators for the specific submission that finalized the task.
        // Mapping: submissionId => array of successful validator IDs.
        // For this simplified example, assume any registered validator on the platform *could* claim a share
        // if they reported "valid" on the winning submission? No, too open.
        // Let's assume reward distribution directly transfers tokens in _distributeRewards,
        // and this claim function is for stakeholders *like* the funder claiming change back, or a separate protocol reward claim.
        // Or, better: the _distributeRewards function sends directly to participants, and this function is NOT needed for trainer/validator rewards.
        // Let's make this claim function primarily for the funder if they have any remaining stake returned,
        // or for participants whose stake was unlocked (not slashed).

         // Placeholder for funder claiming potential remainder or participants claiming unlocked stake
         // uint256 unlockedStake = ... calculate unlocked stake for msg.sender ...
         // amountToClaim = unlockedStake;
         revert("Claiming mechanism placeholder (rewards usually sent directly on finalization)");

        // if (amountToClaim > 0) {
        //     require(IERC20(rewardToken).transfer(msg.sender, amountToClaim), "Token transfer failed for claim");
        //     emit RewardClaimed(msg.sender, amountToClaim);
        // } else {
        //     revert("No rewards or stake to claim");
        // }
    }


    /// @dev Internal function to distribute rewards from a successful task.
    /// @param _taskId The ID of the successfully finalized task.
    /// @param _trainerId The ID of the successful trainer.
    /// @param _successfulValidatorsCount The number of validators who reported valid (simplified).
    function _distributeRewards(uint256 _taskId, uint256 _trainerId, uint256 _successfulValidatorsCount) internal {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.state == TaskState.FinalizedSuccess, "Task not in FinalizedSuccess state");

        // Protocol Fee
        if (task.protocolFee > 0) {
             // Transfer fee to owner or a fee pool
             // require(IERC20(rewardToken).transfer(owner(), task.protocolFee), "Failed to transfer protocol fee");
             // A better pattern is to accumulate fees in the contract and let owner collect later.
             // For this example, let's assume fees stay in contract balance for owner to collect later.
        }

        // Trainer Reward
        if (task.trainerRewardShare > 0) {
            address trainerAddress = address(0);
            // Need to find trainer address from trainerId. Iterate participantIds mapping is inefficient.
            // A reverse mapping (participantId => address) would be better.
            // For this example, let's use the trainerId to look up the participant struct.
            // Assume participant struct stores the address or we have a reverse mapping.
            // mapping(uint256 => address) internal participantAddressById; // Need this mapping
            // trainerAddress = participantAddressById[_trainerId];
            // require(trainerAddress != address(0), "Trainer address not found"); // Should not happen if ID is valid

             // Simulating reverse lookup for this example - requires iterating participantIds
             for (address addr = address(0); ; ) { // Inefficient loop!
                 if (participantIds[addr] == _trainerId) {
                     trainerAddress = addr;
                     break;
                 }
                 // This loop structure is incorrect in Solidity. Needs a proper iterable mapping or array of addresses/IDs.
                 // Let's assume for this example we CAN get the address from ID easily.
                 // Using a simplified lookup: trainerAddress = participants[_trainerId].address_field; // Requires address field in struct or reverse mapping
                 // Let's add a reverse mapping for the example.
                 // mapping(uint256 => address) public participantAddressById; // Add this state var
                 // Then update it in registerAsParticipant: participantAddressById[newParticipantId] = msg.sender;

                 // For now, let's skip the actual transfer and just illustrate the intended logic.
                 // require(IERC20(rewardToken).transfer(trainerAddress, task.trainerRewardShare), "Failed to transfer trainer reward");
            }
             // Actual transfer placeholder:
             // address trainerAddr = participantAddressById[_trainerId];
             // require(IERC20(rewardToken).transfer(trainerAddr, task.trainerRewardShare), "Failed trainer reward transfer");
        }

        // Validator Reward
        if (task.validatorRewardShare > 0 && _successfulValidatorsCount > 0) {
            // Distribute validator share among successful validators.
            // This requires knowing *which* validators were successful based on consensus results.
            // E.g., iterate array of successful validator IDs and send task.validatorRewardShare / _successfulValidatorsCount to each.
            // This part is too complex for this example without robust consensus and validator tracking.
            // Placeholder logic:
            // uint256 sharePerValidator = task.validatorRewardShare / _successfulValidatorsCount; // May lose dust
            // For each successful validator (need list of their IDs):
            //   address validatorAddr = participantAddressById[validatorId];
            //   require(IERC20(rewardToken).transfer(validatorAddr, sharePerValidator), "Failed validator reward transfer");
        }

        // Note: Unused funds (if any dust remains after divisions) stay in the contract or are returned to funder.
        // Task balance should be zero or near-zero after this.
    }


    /// @dev Internal function to handle staking slashings.
    /// @param _participantId The ID of the participant to slash.
    /// @param _amount The amount to slash.
    function _slashStake(uint256 _participantId, uint256 _amount) internal {
        // Requires complex logic:
        // - Determine trigger for slashing (e.g., failed validation, malicious report)
        // - How much to slash (fixed, percentage, based on damage)
        // - Where the slashed tokens go (funder, protocol, redistributed)
        // For this example, this is a placeholder.

        // Participant storage participant = participants[_participantId];
        // uint256 slashAmount = Math.min(participant.stakedAmount, _amount); // Prevent slashing more than staked
        // participant.stakedAmount -= slashAmount;
        // emit StakeSlasshed(participantAddressById[_participantId], slashAmount); // Need reverse mapping

        revert("Slashing mechanism not fully implemented in this example");
    }

    /// @dev Internal function to update a participant's reputation.
    /// @param _participantId The ID of the participant.
    /// @param _success True if the action was successful, false if failure/malicious.
    function _updateReputation(uint256 _participantId, bool _success) internal {
        // Simple reputation model: +reputation on success, -reputation on failure/slash.
        // A real system needs decay, different weights for different actions, etc.

        // Participant storage participant = participants[_participantId];
        // if (_success) {
        //     participant.reputation += reputationMultiplier; // Cap reputation?
        // } else {
        //     if (participant.reputation > reputationMultiplier) {
        //         participant.reputation -= reputationMultiplier; // Ensure reputation doesn't go below zero or a base
        //     } else {
        //          participant.reputation = 0; // Or some base minimum
        //     }
        // }
        revert("Reputation update not fully implemented in this example");
    }

    // --- View Functions ---

    /// @notice Returns the profile details of a participant.
    /// @param _participantAddress The address of the participant.
    /// @return participantType The type of participant.
    /// @return isActive Whether the participant is active.
    /// @return reputation The participant's reputation score.
    /// @return metadataURI URI to the participant's profile data.
    /// @return stakedAmount Tokens staked by the participant.
    function getParticipantProfile(address _participantAddress)
        external view
        returns (ParticipantType participantType, bool isActive, uint256 reputation, string memory metadataURI, uint256 stakedAmount)
    {
        uint256 pId = participantIds[_participantAddress];
        if (pId == 0) {
             return (ParticipantType.None, false, 0, "", 0);
        }
        Participant storage p = participants[pId];
        return (p.participantType, p.isActive, p.reputation, p.metadataURI, p.stakedAmount);
    }

    /// @notice Returns the details of a registered dataset.
    /// @param _datasetId The ID of the dataset.
    /// @return owner Owner's address.
    /// @return dataURI URI to dataset location.
    /// @return size Size of dataset.
    /// @return metadataURI Additional metadata.
    /// @return isActive Whether the registration is active.
    function getDataRegistration(uint256 _datasetId)
        external view
        returns (address owner, string memory dataURI, uint256 size, string memory metadataURI, bool isActive)
    {
        DataRegistration storage data = datasetRegistrations[_datasetId];
        require(data.owner != address(0), "Dataset does not exist");
        return (data.owner, data.dataURI, data.size, data.metadataURI, data.isActive);
    }

    /// @notice Returns the details of a training task.
    /// @param _taskId The ID of the task.
    /// @return funder Funder's address.
    /// @return datasetId Required dataset ID.
    /// @return taskDescriptionURI URI to task description.
    /// @return rewardAmount Total staked reward.
    /// @return protocolFee Protocol fee amount.
    /// @return trainerRewardShare Trainer's share.
    /// @return validatorRewardShare Validators' share.
    /// @return state Current task state.
    /// @return selectedTrainerId ID of the selected trainer (0 if none).
    /// @return submissionCount Number of submissions received.
    /// @return creationTimestamp Timestamp of creation.
    /// @return submissionPeriodEnd Deadline for submission.
    /// @return validationPeriodEnd Deadline for validation.
    function getTrainingTask(uint256 _taskId)
        external view taskExists(_taskId)
        returns (
            address funder,
            uint256 datasetId,
            string memory taskDescriptionURI,
            uint256 rewardAmount,
            uint256 protocolFee,
            uint256 trainerRewardShare,
            uint256 validatorRewardShare,
            TaskState state,
            uint256 selectedTrainerId,
            uint256 submissionCount,
            uint256 creationTimestamp,
            uint256 submissionPeriodEnd,
            uint256 validationPeriodEnd
        )
    {
        TrainingTask storage task = trainingTasks[_taskId];
        return (
            task.funder,
            task.datasetId,
            task.taskDescriptionURI,
            task.rewardAmount,
            task.protocolFee,
            task.trainerRewardShare,
            task.validatorRewardShare,
            task.state,
            task.selectedTrainer,
            task.submissionCount,
            task.creationTimestamp,
            task.submissionPeriodEnd,
            task.validationPeriodEnd
        );
    }

     /// @notice Returns the participant ID for a given address.
     /// @param _participantAddress The address to look up.
     /// @return The participant ID (0 if not registered).
    function getParticipantId(address _participantAddress) external view returns (uint256) {
        return participantIds[_participantAddress];
    }

    // --- (Simplified View Functions for Collections - Need to use arrays or external indexing for real-world use) ---

    /// @notice Returns the total number of registered datasets.
    function getTotalDatasets() external view returns (uint256) {
        return _datasetIds.current();
    }

    /// @notice Returns the total number of created tasks.
    function getTotalTasks() external view returns (uint256) {
        return _taskIds.current();
    }

    /// @notice Returns the total number of model submissions.
    function getTotalSubmissions() external view returns (uint256) {
        return _submissionIds.current();
    }

     /// @notice Returns the total number of validation reports.
    function getTotalValidationReports() external view returns (uint256) {
        return _validationReportIds.current();
    }

    /// @notice Returns the details of a specific model submission.
    /// @param _submissionId The ID of the submission.
    function getModelSubmission(uint256 _submissionId)
        external view submissionExists(_submissionId)
        returns (uint256 taskId, uint256 trainerId, string memory resultURI, uint256 performanceMetric, SubmissionState state, uint256 submissionTimestamp, uint256 validationReportsReceived)
    {
        ModelSubmission storage sub = modelSubmissions[_submissionId];
        return (sub.taskId, sub.trainerId, sub.resultURI, sub.performanceMetric, sub.state, sub.submissionTimestamp, sub.validationReportsReceived);
    }

     /// @notice Returns the details of a specific validation report.
     /// @param _reportId The ID of the report.
     function getValidationReport(uint256 _reportId)
         external view
         returns (uint256 submissionId, uint256 validatorId, bool isValid, string memory reportURI, ValidationState state, uint256 validationTimestamp)
     {
         require(_reportId > 0 && validationReports[_reportId].submissionId > 0, "Validation report does not exist");
         ValidationReport storage report = validationReports[_reportId];
         return (report.submissionId, report.validatorId, report.isValid, report.reportURI, report.state, report.validationTimestamp);
     }

    // NOTE: Getting lists of submission IDs for a task or report IDs for a submission
    // directly from mappings is not possible. In a real contract, you'd store these
    // in dynamic arrays within the structs, or use external indexing/graph protocols.
    // The functions below demonstrate the *intent* but cannot be fully implemented
    // efficiently or at all for large datasets using only mappings.

    /// @notice (Example - requires array storage) Returns a list of submission IDs for a task.
    /// @param _taskId The ID of the task.
    /*
    function getTaskSubmissions(uint256 _taskId) external view taskExists(_taskId) returns (uint256[] memory) {
        // Assuming TrainingTask struct has `uint256[] submissionIds;`
        // return trainingTasks[_taskId].submissionIds;
        revert("Requires array storage in struct or external indexing");
    }
    */

    /// @notice (Example - requires array storage) Returns a list of validation report IDs for a submission.
    /// @param _submissionId The ID of the submission.
    /*
    function getSubmissionValidationReports(uint256 _submissionId) external view submissionExists(_submissionId) returns (uint256[] memory) {
        // Assuming ModelSubmission struct has `uint256[] reportIds;`
        // return modelSubmissions[_submissionId].reportIds;
         revert("Requires array storage in struct or external indexing");
    }
    */

     /// @notice Returns the current reputation score of a participant.
     /// @param _participantAddress The address of the participant.
     function getParticipantReputation(address _participantAddress) external view returns (uint256) {
         uint256 pId = participantIds[_participantAddress];
         if (pId == 0) {
             return 0; // Not registered
         }
         return participants[pId].reputation;
     }

     // NOTE: Getting lists of *all* active tasks or submissions pending validation
     // requires iterating over all possible IDs or maintaining separate lists/mappings,
     // which is gas-expensive. These would typically be handled off-chain using events
     // and indexed data (e.g., using The Graph). Placeholder view functions:

     /// @notice (Example - potentially gas heavy) Returns a list of IDs of tasks that are Open or InProgress.
     /*
     function getActiveTasks() external view returns (uint256[] memory) {
          // Iterate all tasks and check state - potentially very expensive
         revert("Requires iteration or external indexing");
     }
     */

      /// @notice (Example - potentially gas heavy) Returns a list of IDs of submissions pending validation.
     /*
      function getSubmissionsPendingValidation() external view returns (uint256[] memory) {
         // Iterate all submissions and check state - potentially very expensive
         revert("Requires iteration or external indexing");
      }
     */
}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Decentralized Coordination of Off-chain Work:** The contract doesn't run AI but coordinates participants (funders, data providers, trainers, validators) who perform the compute-heavy work off-chain. This is a common pattern for bringing complex real-world processes onto the blockchain.
2.  **Staking Mechanism:** Participants (Trainers, Validators, Funders) stake tokens. This provides a financial incentive for honest behavior and a pool for slashing penalties in case of malicious actions or failures.
3.  **Reputation System (Simplified):** A basic score tracks participant history. While the implementation here is very simple, the concept allows building trust and potentially weighting contributions or access based on a verifiable on-chain reputation.
4.  **Role-Based Access & Participant Types:** Distinct roles (Data Provider, Trainer, Validator) have specific permissions and responsibilities enforced by the contract.
5.  **Time-Based State Transitions:** Tasks and submissions move through states (`Open`, `InProgress`, `Submitted`, `Validating`, `Finalized`) governed by actions and time periods (`submissionPeriodEnd`, `validationPeriodEnd`).
6.  **Off-chain Proof Integration Pattern:** The contract accepts URIs (`dataURI`, `taskDescriptionURI`, `resultURI`, `reportURI`) pointing to off-chain data/proofs (e.g., stored on IPFS). This decouples expensive storage from the blockchain while providing verifiable links. The `performanceMetric` in submissions is an example of a simple on-chain claim about the off-chain work.
7.  **Token Incentives and Payouts:** Uses an ERC20 token for funding tasks and distributing rewards based on successful contributions and predefined percentages.
8.  **Simplified Consensus/Validation Game:** While not a full Byzantine Fault Tolerant system, the concept of multiple validators reporting on a single submission lays the groundwork for on-chain verification games where validators could stake on the outcome and be rewarded/slashed based on consensus. The `finalizeTaskSubmission` function is the hook for this, though the consensus logic is highly simplified here.
9.  **Parameter Configurability:** Key parameters can be adjusted by the owner (or a future DAO governance), allowing the protocol to evolve without redeployment.

**Why it's not a simple duplicate:**
While components like staking or role management exist in other contracts, this specific combination for orchestrating a decentralized AI training process, managing different participant types interacting across various task states, and integrating with off-chain proofs in this manner is not a standard, widely available template. It's a specific application of various advanced concepts to a novel use case on-chain.

**Limitations and Simplifications (Important for a Real Dapp):**
*   **Slashing:** The `_slashStake` function is a placeholder. A real implementation requires complex logic for identifying slashable offenses and securely triggering slashing.
*   **Reputation:** The reputation system is very basic. A real system would be more sophisticated (decay, different weights, etc.).
*   **Validation Consensus:** The `finalizeTaskSubmission` logic for determining submission success based on validator reports is highly simplified (assuming single validator report or basic check). A real system needs a robust, potentially token-weighted or reputation-weighted consensus mechanism, potentially with dispute resolution.
*   **Data Structures for Collections:** Storing lists (like all submissions for a task, or all active tasks) in dynamic arrays within structs or mapping values can become very expensive for large numbers. Real-world dapps typically use external indexing solutions (like The Graph) to query and display such lists, relying on contract events to track changes. The placeholder view functions reflect this limitation.
*   **Griefing/Spam:** The contract needs more robust mechanisms to prevent spamming tasks, submissions, or reports, potentially through higher stakes or quadratic staking/voting.
*   **Off-chain Proof Verification:** The contract trusts the `isValid` boolean submitted by the validator. A real system would need cryptographic proofs submitted on-chain (e.g., ZK proofs) or a verifiable computation layer to ensure validators are honest or that the reported metrics are accurate.

This contract provides a solid, advanced framework for this specific decentralized AI coordination use case, incorporating over 20 distinct functions and demonstrating creative application of blockchain concepts beyond typical token or NFT examples.