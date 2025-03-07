```solidity
/**
 * @title Decentralized Collaborative AI Model Training DAO
 * @author Bard (AI Model, inspired by user request)
 * @dev A smart contract enabling a DAO to collaboratively train AI models,
 *      incentivizing data contribution, model training, and evaluation.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 *   - **Data Contribution & Management:** Allows users to contribute datasets and manage their contributions.
 *   - **Training Proposal & Execution:** Enables proposing, voting on, and executing AI model training tasks.
 *   - **Model Evaluation & Validation:** Facilitates evaluation of trained models and validation of results.
 *   - **Reward & Incentive System:** Distributes rewards to contributors, trainers, and evaluators based on DAO governance.
 *   - **DAO Governance & Parameter Management:** Manages DAO membership, voting, and configurable parameters.
 *
 * **Functions:**
 *
 * **Data Contribution & Management:**
 *   1. `registerDataset(string _datasetURI, string _datasetDescription)`: Allows users to register datasets they are contributing.
 *   2. `getDatasetInfo(uint256 _datasetId)`: Retrieves information about a specific registered dataset.
 *   3. `getDataContributorDatasets(address _contributor)`: Lists datasets contributed by a specific address.
 *   4. `updateDatasetDescription(uint256 _datasetId, string _newDescription)`: Allows dataset owners to update their dataset descriptions.
 *   5. `reportDatasetIssue(uint256 _datasetId, string _issueDescription)`: Allows anyone to report issues with a dataset for DAO review.
 *
 * **Training Proposal & Execution:**
 *   6. `proposeTrainingTask(uint256 _datasetId, string _modelArchitecture, string _trainingParameters, uint256 _rewardAmount)`: Proposes a new AI model training task to the DAO.
 *   7. `voteOnTrainingTaskProposal(uint256 _proposalId, bool _vote)`: DAO members can vote on pending training task proposals.
 *   8. `executeTrainingTask(uint256 _proposalId)`: Executes an approved training task (triggers off-chain training process).
 *   9. `submitTrainedModel(uint256 _taskId, string _modelURI, string _evaluationMetrics)`: Allows the trainer to submit a trained model and evaluation metrics.
 *  10. `reportTrainingProgress(uint256 _taskId, string _progressUpdate)`: Allows trainers to report progress updates on ongoing training tasks.
 *
 * **Model Evaluation & Validation:**
 *  11. `proposeModelEvaluation(uint256 _taskId, address _evaluator, uint256 _evaluationReward)`: Proposes an evaluator for a trained model and sets an evaluation reward.
 *  12. `voteOnEvaluatorProposal(uint256 _proposalId, bool _vote)`: DAO members vote on proposed evaluators.
 *  13. `submitEvaluationReport(uint256 _evaluationProposalId, string _evaluationReportURI)`: Evaluator submits their evaluation report for a trained model.
 *  14. `validateEvaluationReport(uint256 _evaluationProposalId)`: DAO members can validate a submitted evaluation report, approving the model.
 *
 * **Reward & Incentive System:**
 *  15. `claimDatasetContributionReward(uint256 _datasetId)`: Allows data contributors to claim rewards for their datasets (governed by DAO).
 *  16. `claimTrainingReward(uint256 _taskId)`: Allows trainers to claim rewards upon successful model training and validation.
 *  17. `claimEvaluationReward(uint256 _evaluationProposalId)`: Allows evaluators to claim rewards upon successful evaluation and report validation.
 *  18. `depositDAOFunds(uint256 _amount)`: Allows depositing funds into the DAO treasury for rewards and operations.
 *
 * **DAO Governance & Parameter Management:**
 *  19. `proposeDAOParameterChange(string _parameterName, uint256 _newValue)`: Allows DAO members to propose changes to DAO parameters (e.g., voting thresholds, reward rates).
 *  20. `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: DAO members vote on DAO parameter change proposals.
 *  21. `executeParameterChange(uint256 _proposalId)`: Executes an approved DAO parameter change.
 *  22. `addDAOMember(address _newMember)`: Allows adding new members to the DAO (governed by existing DAO members).
 *  23. `removeDAOMember(address _memberToRemove)`: Allows removing members from the DAO (governed by existing DAO members).
 *  24. `pauseContract()`: Allows DAO to pause the contract in case of emergency.
 *  25. `unpauseContract()`: Allows DAO to unpause the contract.
 */
pragma solidity ^0.8.0;

contract DecentralizedAIMLDAO {

    // --- Structs and Enums ---

    struct Dataset {
        uint256 id;
        address contributor;
        string datasetURI;
        string description;
        uint256 registrationTimestamp;
        bool isActive;
    }

    struct TrainingTaskProposal {
        uint256 id;
        uint256 datasetId;
        string modelArchitecture;
        string trainingParameters;
        uint256 rewardAmount;
        uint256 proposalTimestamp;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isApproved;
        bool isExecuted;
        address trainer; // Assigned trainer after execution
    }

    struct EvaluationProposal {
        uint256 id;
        uint256 taskId;
        address evaluator;
        uint256 evaluationReward;
        uint256 proposalTimestamp;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isApproved;
        bool isEvaluated;
        bool isValidated;
    }

    struct DAOParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        uint256 proposalTimestamp;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isApproved;
        bool isExecuted;
    }

    // --- State Variables ---

    address public daoGovernor;
    address[] public daoMembers;
    mapping(address => bool) public isDAOMember;

    uint256 public datasetCounter;
    mapping(uint256 => Dataset) public datasets;

    uint256 public trainingTaskProposalCounter;
    mapping(uint256 => TrainingTaskProposal) public trainingTaskProposals;
    mapping(uint256 => string[]) public trainingTaskProgressUpdates;
    mapping(uint256 => string) public trainedModelURIs;
    mapping(uint256 => string) public modelEvaluationMetrics;

    uint256 public evaluationProposalCounter;
    mapping(uint256 => EvaluationProposal) public evaluationProposals;
    mapping(uint256 => string) public evaluationReports;

    uint256 public parameterChangeProposalCounter;
    mapping(uint256 => DAOParameterChangeProposal) public parameterChangeProposals;

    uint256 public daoTreasuryBalance;
    uint256 public daoVotingThresholdPercentage = 50; // Default 50% for proposals to pass
    uint256 public datasetContributionReward = 10 ether; // Example reward per dataset
    uint256 public baseTrainingReward = 50 ether; // Base reward for training tasks

    bool public contractPaused = false;

    // --- Events ---

    event DatasetRegistered(uint256 datasetId, address contributor, string datasetURI);
    event DatasetDescriptionUpdated(uint256 datasetId, string newDescription);
    event DatasetIssueReported(uint256 datasetId, address reporter, string issueDescription);

    event TrainingTaskProposed(uint256 proposalId, uint256 datasetId, string modelArchitecture, uint256 rewardAmount);
    event TrainingTaskProposalVoted(uint256 proposalId, address voter, bool vote);
    event TrainingTaskExecuted(uint256 taskId, uint256 proposalId, address trainer);
    event TrainedModelSubmitted(uint256 taskId, string modelURI, string evaluationMetrics);
    event TrainingProgressUpdated(uint256 taskId, string progressUpdate);

    event EvaluationProposed(uint256 proposalId, uint256 taskId, address evaluator, uint256 rewardAmount);
    event EvaluatorProposalVoted(uint256 proposalId, address voter, bool vote);
    event EvaluationReportSubmitted(uint256 proposalId, string reportURI);
    event EvaluationValidated(uint256 proposalId);

    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChanged(string parameterName, uint256 newValue);

    event DAOMemberAdded(address newMember);
    event DAOMemberRemoved(address removedMember);
    event ContractPaused();
    event ContractUnpaused();
    event FundsDeposited(uint256 amount);

    // --- Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == daoGovernor, "Only DAO Governor can call this function.");
        _;
    }

    modifier onlyDAOMember() {
        require(isDAOMember[msg.sender], "Only DAO members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }


    // --- Constructor ---

    constructor() payable {
        daoGovernor = msg.sender;
        daoMembers.push(msg.sender);
        isDAOMember[msg.sender] = true;
        daoTreasuryBalance = msg.value;
        emit FundsDeposited(msg.value);
    }

    // --- Data Contribution & Management Functions ---

    /// @notice Registers a new dataset for contribution.
    /// @param _datasetURI URI pointing to the dataset (e.g., IPFS hash).
    /// @param _datasetDescription Description of the dataset.
    function registerDataset(string memory _datasetURI, string memory _datasetDescription) external whenNotPaused {
        datasetCounter++;
        datasets[datasetCounter] = Dataset({
            id: datasetCounter,
            contributor: msg.sender,
            datasetURI: _datasetURI,
            description: _datasetDescription,
            registrationTimestamp: block.timestamp,
            isActive: true
        });
        emit DatasetRegistered(datasetCounter, msg.sender, _datasetURI);
    }

    /// @notice Retrieves information about a dataset.
    /// @param _datasetId ID of the dataset.
    /// @return Dataset struct containing dataset information.
    function getDatasetInfo(uint256 _datasetId) external view returns (Dataset memory) {
        require(datasets[_datasetId].id != 0, "Dataset not found.");
        return datasets[_datasetId];
    }

    /// @notice Gets a list of dataset IDs contributed by a specific address.
    /// @param _contributor Address of the contributor.
    /// @return Array of dataset IDs.
    function getDataContributorDatasets(address _contributor) external view returns (uint256[] memory) {
        uint256[] memory contributorDatasets = new uint256[](datasetCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= datasetCounter; i++) {
            if (datasets[i].contributor == _contributor && datasets[i].id != 0) {
                contributorDatasets[count] = i;
                count++;
            }
        }
        // Resize to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = contributorDatasets[i];
        }
        return result;
    }

    /// @notice Updates the description of a dataset (only by the contributor).
    /// @param _datasetId ID of the dataset.
    /// @param _newDescription New description for the dataset.
    function updateDatasetDescription(uint256 _datasetId, string memory _newDescription) external whenNotPaused {
        require(datasets[_datasetId].id != 0, "Dataset not found.");
        require(datasets[_datasetId].contributor == msg.sender, "Only dataset contributor can update description.");
        datasets[_datasetId].description = _newDescription;
        emit DatasetDescriptionUpdated(_datasetId, _newDescription);
    }

    /// @notice Allows anyone to report an issue with a dataset.
    /// @param _datasetId ID of the dataset.
    /// @param _issueDescription Description of the issue.
    function reportDatasetIssue(uint256 _datasetId, string memory _issueDescription) external whenNotPaused {
        require(datasets[_datasetId].id != 0, "Dataset not found.");
        emit DatasetIssueReported(_datasetId, msg.sender, _issueDescription);
        // DAO can review reported issues and take actions (e.g., deactivate dataset)
        // Implementation for issue resolution is beyond the scope of function listing.
    }


    // --- Training Proposal & Execution Functions ---

    /// @notice Proposes a new training task for an AI model.
    /// @param _datasetId ID of the dataset to be used for training.
    /// @param _modelArchitecture Description of the model architecture (e.g., "CNN", "Transformer").
    /// @param _trainingParameters Training parameters (e.g., epochs, batch size).
    /// @param _rewardAmount Reward offered for completing the training task.
    function proposeTrainingTask(
        uint256 _datasetId,
        string memory _modelArchitecture,
        string memory _trainingParameters,
        uint256 _rewardAmount
    ) external onlyDAOMember whenNotPaused {
        require(datasets[_datasetId].id != 0 && datasets[_datasetId].isActive, "Dataset not found or inactive.");
        require(_rewardAmount > 0, "Reward amount must be positive.");

        trainingTaskProposalCounter++;
        trainingTaskProposals[trainingTaskProposalCounter] = TrainingTaskProposal({
            id: trainingTaskProposalCounter,
            datasetId: _datasetId,
            modelArchitecture: _modelArchitecture,
            trainingParameters: _trainingParameters,
            rewardAmount: _rewardAmount,
            proposalTimestamp: block.timestamp,
            voteCountYes: 0,
            voteCountNo: 0,
            isApproved: false,
            isExecuted: false,
            trainer: address(0) // No trainer assigned initially
        });

        emit TrainingTaskProposed(trainingTaskProposalCounter, _datasetId, _modelArchitecture, _rewardAmount);
    }

    /// @notice Allows DAO members to vote on a training task proposal.
    /// @param _proposalId ID of the training task proposal.
    /// @param _vote 'true' for yes, 'false' for no.
    function voteOnTrainingTaskProposal(uint256 _proposalId, bool _vote) external onlyDAOMember whenNotPaused {
        require(trainingTaskProposals[_proposalId].id != 0 && !trainingTaskProposals[_proposalId].isApproved && !trainingTaskProposals[_proposalId].isExecuted, "Invalid proposal or already decided.");

        if (_vote) {
            trainingTaskProposals[_proposalId].voteCountYes++;
        } else {
            trainingTaskProposals[_proposalId].voteCountNo++;
        }
        emit TrainingTaskProposalVoted(_proposalId, msg.sender, _vote);

        uint256 totalVotes = trainingTaskProposals[_proposalId].voteCountYes + trainingTaskProposals[_proposalId].voteCountNo;
        if (totalVotes == daoMembers.length) { // Simple voting, all members voted
            uint256 yesPercentage = (trainingTaskProposals[_proposalId].voteCountYes * 100) / totalVotes;
            if (yesPercentage >= daoVotingThresholdPercentage) {
                trainingTaskProposals[_proposalId].isApproved = true;
            }
        }
        // In a real DAO, voting might have deadlines and more complex mechanisms.
    }

    /// @notice Executes an approved training task proposal (assigns trainer, sets status).
    /// @param _proposalId ID of the approved training task proposal.
    function executeTrainingTask(uint256 _proposalId) external onlyDAOMember whenNotPaused {
        require(trainingTaskProposals[_proposalId].id != 0 && trainingTaskProposals[_proposalId].isApproved && !trainingTaskProposals[_proposalId].isExecuted, "Proposal not approved or already executed.");
        require(daoTreasuryBalance >= trainingTaskProposals[_proposalId].rewardAmount, "Insufficient DAO funds for training reward.");

        trainingTaskProposals[_proposalId].isExecuted = true;
        trainingTaskProposals[_proposalId].trainer = msg.sender; // In a real system, trainer assignment might be more complex (bidding, reputation etc.)
        daoTreasuryBalance -= trainingTaskProposals[_proposalId].rewardAmount; // Reserve funds for reward (actual transfer on completion)

        emit TrainingTaskExecuted(_proposalId, _proposalId, msg.sender); // Assuming msg.sender is the trainer for simplicity.
        // In a real system, you'd need a mechanism for trainers to accept tasks and be assigned.
        // This function would likely trigger off-chain processes to initiate the actual AI model training.
    }

    /// @notice Allows the assigned trainer to submit a trained model and evaluation metrics.
    /// @param _taskId ID of the training task (same as proposal ID for simplicity here).
    /// @param _modelURI URI pointing to the trained model (e.g., IPFS hash).
    /// @param _evaluationMetrics String describing the evaluation metrics achieved by the model.
    function submitTrainedModel(uint256 _taskId, string memory _modelURI, string memory _evaluationMetrics) external whenNotPaused {
        require(trainingTaskProposals[_taskId].id != 0 && trainingTaskProposals[_taskId].isExecuted && trainingTaskProposals[_taskId].trainer == msg.sender, "Invalid task or not assigned trainer.");

        trainedModelURIs[_taskId] = _modelURI;
        modelEvaluationMetrics[_taskId] = _evaluationMetrics;

        emit TrainedModelSubmitted(_taskId, _modelURI, _evaluationMetrics);
        // Next step would be to propose and execute model evaluation.
    }

    /// @notice Allows trainers to report progress updates during training.
    /// @param _taskId ID of the training task.
    /// @param _progressUpdate String describing the training progress.
    function reportTrainingProgress(uint256 _taskId, string memory _progressUpdate) external whenNotPaused {
        require(trainingTaskProposals[_taskId].id != 0 && trainingTaskProposals[_taskId].isExecuted && trainingTaskProposals[_taskId].trainer == msg.sender, "Invalid task or not assigned trainer.");
        trainingTaskProgressUpdates[_taskId].push(_progressUpdate);
        emit TrainingProgressUpdated(_taskId, _progressUpdate);
    }


    // --- Model Evaluation & Validation Functions ---

    /// @notice Proposes an evaluator for a trained model.
    /// @param _taskId ID of the training task for which to evaluate the model.
    /// @param _evaluator Address of the proposed evaluator.
    /// @param _evaluationReward Reward offered to the evaluator.
    function proposeModelEvaluation(uint256 _taskId, address _evaluator, uint256 _evaluationReward) external onlyDAOMember whenNotPaused {
        require(trainingTaskProposals[_taskId].id != 0 && trainingTaskProposals[_taskId].isExecuted && bytes(trainedModelURIs[_taskId]).length > 0, "Invalid task or model not submitted.");
        require(_evaluationReward > 0, "Evaluation reward must be positive.");
        require(_evaluator != trainingTaskProposals[_taskId].trainer, "Evaluator cannot be the trainer."); // Basic conflict of interest check

        evaluationProposalCounter++;
        evaluationProposals[evaluationProposalCounter] = EvaluationProposal({
            id: evaluationProposalCounter,
            taskId: _taskId,
            evaluator: _evaluator,
            evaluationReward: _evaluationReward,
            proposalTimestamp: block.timestamp,
            voteCountYes: 0,
            voteCountNo: 0,
            isApproved: false,
            isEvaluated: false,
            isValidated: false
        });

        emit EvaluationProposed(evaluationProposalCounter, _taskId, _evaluator, _evaluationReward);
    }

    /// @notice Allows DAO members to vote on an evaluator proposal.
    /// @param _proposalId ID of the evaluator proposal.
    /// @param _vote 'true' for yes, 'false' for no.
    function voteOnEvaluatorProposal(uint256 _proposalId, bool _vote) external onlyDAOMember whenNotPaused {
        require(evaluationProposals[_proposalId].id != 0 && !evaluationProposals[_proposalId].isApproved && !evaluationProposals[_proposalId].isEvaluated, "Invalid proposal or already decided.");

        if (_vote) {
            evaluationProposals[_proposalId].voteCountYes++;
        } else {
            evaluationProposals[_proposalId].voteCountNo++;
        }
        emit EvaluatorProposalVoted(_proposalId, msg.sender, _vote);

        uint256 totalVotes = evaluationProposals[_proposalId].voteCountYes + evaluationProposals[_proposalId].voteCountNo;
        if (totalVotes == daoMembers.length) { // Simple voting, all members voted
            uint256 yesPercentage = (evaluationProposals[_proposalId].voteCountYes * 100) / totalVotes;
            if (yesPercentage >= daoVotingThresholdPercentage) {
                evaluationProposals[_proposalId].isApproved = true;
            }
        }
    }

    /// @notice Allows the approved evaluator to submit their evaluation report.
    /// @param _evaluationProposalId ID of the evaluation proposal.
    /// @param _evaluationReportURI URI pointing to the evaluation report (e.g., IPFS hash).
    function submitEvaluationReport(uint256 _evaluationProposalId, string memory _evaluationReportURI) external whenNotPaused {
        require(evaluationProposals[_evaluationProposalId].id != 0 && evaluationProposals[_evaluationProposalId].isApproved && !evaluationProposals[_evaluationProposalId].isEvaluated, "Invalid proposal or not approved/executed.");
        require(evaluationProposals[_evaluationProposalId].evaluator == msg.sender, "Only approved evaluator can submit report.");

        evaluationProposals[_evaluationProposalId].isEvaluated = true;
        evaluationReports[_evaluationProposalId] = _evaluationReportURI;

        emit EvaluationReportSubmitted(_evaluationProposalId, _evaluationReportURI);
        // Next step is DAO validation of the evaluation report.
    }

    /// @notice Allows DAO members to validate an evaluation report.
    /// @param _evaluationProposalId ID of the evaluation proposal.
    function validateEvaluationReport(uint256 _evaluationProposalId) external onlyDAOMember whenNotPaused {
        require(evaluationProposals[_evaluationProposalId].id != 0 && evaluationProposals[_evaluationProposalId].isEvaluated && !evaluationProposals[_evaluationProposalId].isValidated, "Invalid proposal or evaluation not submitted.");

        evaluationProposals[_evaluationProposalId].isValidated = true;
        emit EvaluationValidated(_evaluationProposalId);
        // Once validated, rewards can be distributed.
    }


    // --- Reward & Incentive System Functions ---

    /// @notice Allows data contributors to claim rewards for their datasets.
    /// @param _datasetId ID of the dataset.
    function claimDatasetContributionReward(uint256 _datasetId) external whenNotPaused {
        require(datasets[_datasetId].id != 0 && datasets[_datasetId].contributor == msg.sender, "Invalid dataset or not contributor.");
        require(daoTreasuryBalance >= datasetContributionReward, "Insufficient DAO funds for dataset reward.");
        require(datasets[_datasetId].isActive, "Dataset is not active and cannot claim reward."); // Example condition, DAO can define criteria

        datasets[_datasetId].isActive = false; // Example: Deactivate dataset after claiming reward (can be different logic)
        daoTreasuryBalance -= datasetContributionReward;
        payable(msg.sender).transfer(datasetContributionReward);

        // Consider adding event for reward claim.
    }

    /// @notice Allows trainers to claim rewards upon successful model training and validation.
    /// @param _taskId ID of the training task.
    function claimTrainingReward(uint256 _taskId) external whenNotPaused {
        require(trainingTaskProposals[_taskId].id != 0 && trainingTaskProposals[_taskId].isExecuted && trainingTaskProposals[_taskId].trainer == msg.sender, "Invalid task or not trainer.");
        require(evaluationProposals[getEvaluationProposalIdForTask(_taskId)].isValidated, "Evaluation not validated yet."); // Ensure evaluation is validated.
        require(daoTreasuryBalance >= trainingTaskProposals[_taskId].rewardAmount, "Insufficient DAO funds for training reward.");

        uint256 rewardAmount = trainingTaskProposals[_taskId].rewardAmount; // Or calculate based on performance etc.
        daoTreasuryBalance -= rewardAmount;
        payable(msg.sender).transfer(rewardAmount);

        // Consider adding event for reward claim.
    }

    /// @notice Allows evaluators to claim rewards upon successful evaluation and report validation.
    /// @param _evaluationProposalId ID of the evaluation proposal.
    function claimEvaluationReward(uint256 _evaluationProposalId) external whenNotPaused {
        require(evaluationProposals[_evaluationProposalId].id != 0 && evaluationProposals[_evaluationProposalId].isEvaluated && evaluationProposals[_evaluationProposalId].evaluator == msg.sender, "Invalid proposal or not evaluator.");
        require(evaluationProposals[_evaluationProposalId].isValidated, "Evaluation not validated yet.");
        require(daoTreasuryBalance >= evaluationProposals[_evaluationProposalId].evaluationReward, "Insufficient DAO funds for evaluation reward.");

        uint256 rewardAmount = evaluationProposals[_evaluationProposalId].evaluationReward;
        daoTreasuryBalance -= rewardAmount;
        payable(msg.sender).transfer(rewardAmount);

        // Consider adding event for reward claim.
    }

    /// @notice Allows depositing funds into the DAO treasury.
    function depositDAOFunds(uint256 _amount) external payable whenNotPaused onlyDAOMember {
        require(msg.value == _amount, "Amount sent does not match deposit amount.");
        daoTreasuryBalance += _amount;
        emit FundsDeposited(_amount);
    }


    // --- DAO Governance & Parameter Management Functions ---

    /// @notice Proposes a change to a DAO parameter.
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeDAOParameterChange(string memory _parameterName, uint256 _newValue) external onlyDAOMember whenNotPaused {
        parameterChangeProposalCounter++;
        parameterChangeProposals[parameterChangeProposalCounter] = DAOParameterChangeProposal({
            id: parameterChangeProposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            voteCountYes: 0,
            voteCountNo: 0,
            isApproved: false,
            isExecuted: false
        });
        emit ParameterChangeProposed(parameterChangeProposalCounter, _parameterName, _newValue);
    }

    /// @notice Allows DAO members to vote on a parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _vote 'true' for yes, 'false' for no.
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external onlyDAOMember whenNotPaused {
        require(parameterChangeProposals[_proposalId].id != 0 && !parameterChangeProposals[_proposalId].isApproved && !parameterChangeProposals[_proposalId].isExecuted, "Invalid proposal or already decided.");

        if (_vote) {
            parameterChangeProposals[_proposalId].voteCountYes++;
        } else {
            parameterChangeProposals[_proposalId].voteCountNo++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);

        uint256 totalVotes = parameterChangeProposals[_proposalId].voteCountYes + parameterChangeProposals[_proposalId].voteCountNo;
        if (totalVotes == daoMembers.length) { // Simple voting, all members voted
            uint256 yesPercentage = (parameterChangeProposals[_proposalId].voteCountYes * 100) / totalVotes;
            if (yesPercentage >= daoVotingThresholdPercentage) {
                parameterChangeProposals[_proposalId].isApproved = true;
            }
        }
    }

    /// @notice Executes an approved parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    function executeParameterChange(uint256 _proposalId) external onlyDAOMember whenNotPaused {
        require(parameterChangeProposals[_proposalId].id != 0 && parameterChangeProposals[_proposalId].isApproved && !parameterChangeProposals[_proposalId].isExecuted, "Proposal not approved or already executed.");

        string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
        uint256 newValue = parameterChangeProposals[_proposalId].newValue;

        if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("daoVotingThresholdPercentage"))) {
            daoVotingThresholdPercentage = newValue;
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("datasetContributionReward"))) {
            datasetContributionReward = newValue;
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("baseTrainingReward"))) {
            baseTrainingReward = newValue;
        } else {
            revert("Invalid parameter name for change.");
        }

        parameterChangeProposals[_proposalId].isExecuted = true;
        emit ParameterChanged(parameterName, newValue);
    }

    /// @notice Adds a new member to the DAO.
    /// @param _newMember Address of the new DAO member.
    function addDAOMember(address _newMember) external onlyDAOMember whenNotPaused {
        require(!isDAOMember[_newMember], "Address is already a DAO member.");
        daoMembers.push(_newMember);
        isDAOMember[_newMember] = true;
        emit DAOMemberAdded(_newMember);
    }

    /// @notice Removes a member from the DAO.
    /// @param _memberToRemove Address of the member to remove.
    function removeDAOMember(address _memberToRemove) external onlyDAOMember whenNotPaused {
        require(isDAOMember[_memberToRemove], "Address is not a DAO member.");
        require(_memberToRemove != daoGovernor, "Cannot remove DAO Governor."); // Prevent removing governor without new governor assignment logic

        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == _memberToRemove) {
                delete daoMembers[i]; // Remove from array (leaves a gap, consider array compaction for production)
                isDAOMember[_memberToRemove] = false;
                emit DAOMemberRemoved(_memberToRemove);
                return;
            }
        }
        revert("DAO Member not found in list."); // Should not reach here due to initial check, but for safety.
    }

    /// @notice Pauses the contract, preventing most functions from being called.
    function pauseContract() external onlyGovernor whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing functions to be called again.
    function unpauseContract() external onlyGovernor whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // --- Helper/Utility Functions ---

    /// @dev Internal function to get the evaluation proposal ID for a given task ID (assuming 1:1 mapping for simplicity).
    function getEvaluationProposalIdForTask(uint256 _taskId) internal view returns (uint256) {
        for (uint256 i = 1; i <= evaluationProposalCounter; i++) {
            if (evaluationProposals[i].taskId == _taskId) {
                return i;
            }
        }
        return 0; // No evaluation proposal found for this task.
    }

    function getDAOMemberCount() external view returns (uint256) {
        return daoMembers.length;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getDAOTreasuryBalance() external view returns (uint256) {
        return daoTreasuryBalance;
    }

    function isContractPaused() external view returns (bool) {
        return contractPaused;
    }
}
```