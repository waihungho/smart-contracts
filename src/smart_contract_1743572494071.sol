```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Collaborative AI Model Training DAO
 * @author Gemini AI (Example - Replace with your name/org)
 * @dev A smart contract implementing a Decentralized Autonomous Organization (DAO)
 * for collaborative AI model training. This DAO allows members to contribute data,
 * propose AI model training tasks, vote on proposals, train models, validate results,
 * and earn rewards. It incorporates advanced concepts like data tokenization, reputation
 * scoring, dynamic task allocation, and on-chain model verification (simplified).
 *
 * **Outline and Function Summary:**
 *
 * **Data Contribution & Management:**
 * 1. `contributeData(string _datasetCID, string _metadataCID)`: Allows members to contribute datasets by providing IPFS CIDs for data and metadata.
 * 2. `stakeData(uint256 _contributionId, uint256 _stakeAmount)`:  Members can stake tokens on their data contributions to signal quality and earn rewards.
 * 3. `unStakeData(uint256 _contributionId, uint256 _unstakeAmount)`: Allows unstaking data tokens after a cooling period or if data is deemed invalid.
 * 4. `validateDataContribution(uint256 _contributionId, bool _isValid)`: Admin function to validate data contributions, impacting contributor reputation.
 * 5. `getDataContributionDetails(uint256 _contributionId)`:  Retrieves details of a specific data contribution.
 * 6. `getDataContributorReputation(address _contributor)`:  Returns the reputation score of a data contributor.
 *
 * **Model Training Task Management:**
 * 7. `proposeModelTrainingTask(string _taskDescription, string _datasetRequirements, uint256 _rewardAmount)`: Allows members to propose new AI model training tasks.
 * 8. `voteOnTrainingTaskProposal(uint256 _proposalId, bool _vote)`: DAO members can vote on proposed training tasks.
 * 9. `executeTrainingTask(uint256 _proposalId)`:  Admin/Designated role function to initiate the execution of an approved training task.
 * 10. `submitTrainedModel(uint256 _proposalId, string _modelCID, string _validationReportCID)`: Model trainers submit their trained models and validation reports.
 * 11. `validateTrainedModel(uint256 _proposalId, bool _isAcceptable)`:  Validators assess submitted models and vote on their acceptability.
 * 12. `finalizeTrainingTask(uint256 _proposalId)`: Admin function to finalize a training task, distribute rewards, and update reputations.
 * 13. `getTrainingTaskDetails(uint256 _proposalId)`: Retrieves details of a specific training task proposal.
 *
 * **Governance & DAO Management:**
 * 14. `deposit()`: Allows DAO members to deposit tokens into the DAO treasury.
 * 15. `withdraw(uint256 _amount)`:  Allows DAO members to withdraw tokens from their DAO balance (subject to governance or conditions).
 * 16. `proposeParameterChange(string _parameterName, uint256 _newValue)`:  Members can propose changes to DAO parameters (e.g., voting periods, reward ratios).
 * 17. `voteOnParameterChange(uint256 _proposalId, bool _vote)`: DAO members vote on parameter change proposals.
 * 18. `executeParameterChange(uint256 _proposalId)`:  Admin function to enact approved parameter changes.
 * 19. `getDAOParameter(string _parameterName)`: Retrieves the current value of a DAO parameter.
 * 20. `setValidatorRole(address _validator, bool _isValidator)`: Admin function to assign or revoke validator roles.
 * 21. `getValidatorStatus(address _validator)`: Check if an address has validator role.
 * 22. `setAdminRole(address _admin, bool _isAdmin)`: Admin function to assign or revoke admin roles.
 * 23. `getAdminStatus(address _admin)`: Check if an address has admin role.
 * 24. `pauseContract()`: Admin function to pause core functionalities of the contract for emergency situations.
 * 25. `unpauseContract()`: Admin function to resume contract functionalities after pausing.
 */
contract DecentralizedAIModelDAO {
    // **** Structs and Enums ****

    struct DataContribution {
        address contributor;
        string datasetCID;
        string metadataCID;
        uint256 stakeAmount;
        uint256 contributionTimestamp;
        bool isValid;
    }

    struct TrainingTaskProposal {
        address proposer;
        string taskDescription;
        string datasetRequirements;
        uint256 rewardAmount;
        uint256 proposalTimestamp;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isApproved;
        bool isExecuted;
        address trainer; // Address of the trainer assigned to the task
        string modelCID;
        string validationReportCID;
        bool modelAccepted;
    }

    struct ParameterChangeProposal {
        address proposer;
        string parameterName;
        uint256 newValue;
        uint256 proposalTimestamp;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isApproved;
        bool isExecuted;
    }

    // **** State Variables ****

    address public admin;
    mapping(address => bool) public isAdminRole;
    mapping(address => bool) public isValidatorRole;

    uint256 public nextContributionId = 1;
    mapping(uint256 => DataContribution) public dataContributions;
    mapping(address => uint256) public contributorReputation;

    uint256 public nextTrainingTaskId = 1;
    mapping(uint256 => TrainingTaskProposal) public trainingTaskProposals;

    uint256 public nextParameterProposalId = 1;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    mapping(address => uint256) public daoTokenBalance; // Token balances of DAO members

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public dataStakeCoolingPeriod = 30 days; // Time before data can be unstaked

    bool public paused = false;

    // **** Events ****

    event DataContributed(uint256 contributionId, address contributor, string datasetCID);
    event DataStaked(uint256 contributionId, address staker, uint256 stakeAmount);
    event DataUnstaked(uint256 contributionId, address unstaker, uint256 unstakeAmount);
    event DataContributionValidated(uint256 contributionId, bool isValid);
    event TrainingTaskProposed(uint256 proposalId, address proposer, string taskDescription);
    event TrainingTaskVoteCast(uint256 proposalId, address voter, bool vote);
    event TrainingTaskExecuted(uint256 proposalId);
    event TrainedModelSubmitted(uint256 proposalId, address trainer, string modelCID);
    event ModelValidationVoteCast(uint256 proposalId, address validator, bool vote);
    event TrainingTaskFinalized(uint256 proposalId, bool modelAccepted);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoteCast(uint256 proposalId, uint256 newValue, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event Deposit(address depositor, uint256 amount);
    event Withdrawal(address withdrawer, uint256 amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // **** Modifiers ****

    modifier onlyAdmin() {
        require(isAdminRole[msg.sender] || msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyValidator() {
        require(isValidatorRole[msg.sender], "Only validators can call this function.");
        _;
    }

    modifier onlyDAO मेंबर() {
        require(daoTokenBalance[msg.sender] > 0, "Must be a DAO member to perform this action.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // **** Constructor ****

    constructor() payable {
        admin = msg.sender;
        isAdminRole[admin] = true;
        // Optionally set initial validators here
    }

    // **** Data Contribution & Management Functions ****

    /// @notice Allows members to contribute datasets.
    /// @param _datasetCID IPFS CID of the dataset.
    /// @param _metadataCID IPFS CID of the dataset metadata.
    function contributeData(string memory _datasetCID, string memory _metadataCID) external onlyDAO मेंबर notPaused {
        require(bytes(_datasetCID).length > 0 && bytes(_metadataCID).length > 0, "Dataset and metadata CIDs cannot be empty.");

        dataContributions[nextContributionId] = DataContribution({
            contributor: msg.sender,
            datasetCID: _datasetCID,
            metadataCID: _metadataCID,
            stakeAmount: 0,
            contributionTimestamp: block.timestamp,
            isValid: false // Initially set to false, needs validation
        });

        emit DataContributed(nextContributionId, msg.sender, _datasetCID);
        nextContributionId++;
    }

    /// @notice Allows members to stake tokens on their data contributions.
    /// @param _contributionId ID of the data contribution.
    /// @param _stakeAmount Amount of tokens to stake.
    function stakeData(uint256 _contributionId, uint256 _stakeAmount) external onlyDAO मेंबर notPaused {
        require(dataContributions[_contributionId].contributor == msg.sender, "You are not the contributor of this data.");
        require(_stakeAmount > 0, "Stake amount must be greater than zero.");
        require(daoTokenBalance[msg.sender] >= _stakeAmount, "Insufficient DAO tokens.");

        dataContributions[_contributionId].stakeAmount += _stakeAmount;
        daoTokenBalance[msg.sender] -= _stakeAmount; // Deduct tokens (replace with token transfer if using ERC20)
        emit DataStaked(_contributionId, msg.sender, _stakeAmount);
    }

    /// @notice Allows members to unstake tokens from their data contributions after a cooling period.
    /// @param _contributionId ID of the data contribution.
    /// @param _unstakeAmount Amount of tokens to unstake.
    function unStakeData(uint256 _contributionId, uint256 _unstakeAmount) external onlyDAO मेंबर notPaused {
        require(dataContributions[_contributionId].contributor == msg.sender, "You are not the contributor of this data.");
        require(_unstakeAmount > 0, "Unstake amount must be greater than zero.");
        require(_unstakeAmount <= dataContributions[_contributionId].stakeAmount, "Unstake amount exceeds staked amount.");
        require(block.timestamp >= dataContributions[_contributionId].contributionTimestamp + dataStakeCoolingPeriod, "Data stake cooling period not over.");

        dataContributions[_contributionId].stakeAmount -= _unstakeAmount;
        daoTokenBalance[msg.sender] += _unstakeAmount; // Return tokens (replace with token transfer if using ERC20)
        emit DataUnstaked(_contributionId, msg.sender, _unstakeAmount);
    }

    /// @notice Admin function to validate a data contribution.
    /// @param _contributionId ID of the data contribution.
    /// @param _isValid Boolean indicating if the data contribution is valid.
    function validateDataContribution(uint256 _contributionId, bool _isValid) external onlyAdmin notPaused {
        require(dataContributions[_contributionId].contributor != address(0), "Invalid contribution ID.");

        dataContributions[_contributionId].isValid = _isValid;
        if (_isValid) {
            contributorReputation[dataContributions[_contributionId].contributor] += 1; // Increase reputation for valid data
        } else {
            contributorReputation[dataContributions[_contributionId].contributor] -= 1; // Decrease reputation for invalid data
        }
        emit DataContributionValidated(_contributionId, _isValid);
    }

    /// @notice Retrieves details of a specific data contribution.
    /// @param _contributionId ID of the data contribution.
    /// @return DataContribution struct containing contribution details.
    function getDataContributionDetails(uint256 _contributionId) external view returns (DataContribution memory) {
        return dataContributions[_contributionId];
    }

    /// @notice Retrieves the reputation score of a data contributor.
    /// @param _contributor Address of the data contributor.
    /// @return Reputation score of the contributor.
    function getDataContributorReputation(address _contributor) external view returns (uint256) {
        return contributorReputation[_contributor];
    }

    // **** Model Training Task Management Functions ****

    /// @notice Allows members to propose a new AI model training task.
    /// @param _taskDescription Description of the training task.
    /// @param _datasetRequirements Requirements for the dataset needed for training.
    /// @param _rewardAmount Reward amount in DAO tokens for completing the task.
    function proposeModelTrainingTask(string memory _taskDescription, string memory _datasetRequirements, uint256 _rewardAmount) external onlyDAO मेंबर notPaused {
        require(bytes(_taskDescription).length > 0 && bytes(_datasetRequirements).length > 0, "Task description and dataset requirements cannot be empty.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");

        trainingTaskProposals[nextTrainingTaskId] = TrainingTaskProposal({
            proposer: msg.sender,
            taskDescription: _taskDescription,
            datasetRequirements: _datasetRequirements,
            rewardAmount: _rewardAmount,
            proposalTimestamp: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isApproved: false,
            isExecuted: false,
            trainer: address(0), // Initially no trainer assigned
            modelCID: "",
            validationReportCID: "",
            modelAccepted: false
        });

        emit TrainingTaskProposed(nextTrainingTaskId, msg.sender, _taskDescription);
        nextTrainingTaskId++;
    }

    /// @notice Allows DAO members to vote on a proposed training task.
    /// @param _proposalId ID of the training task proposal.
    /// @param _vote Boolean vote (true for yes, false for no).
    function voteOnTrainingTaskProposal(uint256 _proposalId, bool _vote) external onlyDAO मेंबर notPaused {
        require(trainingTaskProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < trainingTaskProposals[_proposalId].voteEndTime, "Voting period is over.");

        if (_vote) {
            trainingTaskProposals[_proposalId].yesVotes++;
        } else {
            trainingTaskProposals[_proposalId].noVotes++;
        }
        emit TrainingTaskVoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Admin function to execute an approved training task.
    /// @param _proposalId ID of the training task proposal.
    function executeTrainingTask(uint256 _proposalId) external onlyAdmin notPaused {
        require(trainingTaskProposals[_proposalId].isApproved, "Proposal is not approved.");
        require(!trainingTaskProposals[_proposalId].isExecuted, "Proposal already executed.");
        require(trainingTaskProposals[_proposalId].yesVotes > trainingTaskProposals[_proposalId].noVotes, "Proposal did not receive enough yes votes."); // Example approval criteria

        trainingTaskProposals[_proposalId].isExecuted = true;
        trainingTaskProposals[_proposalId].isActive = false; // Deactivate proposal after execution
        // In a real scenario, task assignment logic would be more sophisticated here.
        // For simplicity, we can assume the first person to call submitTrainedModel becomes the trainer.

        emit TrainingTaskExecuted(_proposalId);
    }

    /// @notice Model trainers submit their trained models and validation reports.
    /// @param _proposalId ID of the training task proposal.
    /// @param _modelCID IPFS CID of the trained AI model.
    /// @param _validationReportCID IPFS CID of the model validation report.
    function submitTrainedModel(uint256 _proposalId, string memory _modelCID, string memory _validationReportCID) external onlyDAO मेंबर notPaused {
        require(trainingTaskProposals[_proposalId].isExecuted, "Training task is not executed yet.");
        require(trainingTaskProposals[_proposalId].trainer == address(0) || trainingTaskProposals[_proposalId].trainer == msg.sender, "Only the assigned trainer can submit."); // Allow first submitter to be trainer
        require(bytes(_modelCID).length > 0 && bytes(_validationReportCID).length > 0, "Model and validation report CIDs cannot be empty.");

        if (trainingTaskProposals[_proposalId].trainer == address(0)) {
            trainingTaskProposals[_proposalId].trainer = msg.sender; // Assign first submitter as trainer
        }
        trainingTaskProposals[_proposalId].modelCID = _modelCID;
        trainingTaskProposals[_proposalId].validationReportCID = _validationReportCID;

        emit TrainedModelSubmitted(_proposalId, msg.sender, _modelCID);
    }

    /// @notice Validators assess submitted models and vote on their acceptability.
    /// @param _proposalId ID of the training task proposal.
    /// @param _isAcceptable Boolean vote indicating if the model is acceptable.
    function validateTrainedModel(uint256 _proposalId, bool _isAcceptable) external onlyValidator notPaused {
        require(trainingTaskProposals[_proposalId].isExecuted, "Training task is not executed yet.");
        require(trainingTaskProposals[_proposalId].trainer != address(0), "No trainer assigned yet or model not submitted.");
        require(!trainingTaskProposals[_proposalId].modelAccepted, "Model validation already finalized."); // Prevent re-validation

        trainingTaskProposals[_proposalId].modelAccepted = _isAcceptable; // Simple approval based on first validator vote for example.  In real-world, more voting/consensus needed.
        emit ModelValidationVoteCast(_proposalId, msg.sender, _isAcceptable);
    }

    /// @notice Admin function to finalize a training task, distribute rewards, and update reputations.
    /// @param _proposalId ID of the training task proposal.
    function finalizeTrainingTask(uint256 _proposalId) external onlyAdmin notPaused {
        require(trainingTaskProposals[_proposalId].isExecuted, "Training task is not executed yet.");
        require(trainingTaskProposals[_proposalId].trainer != address(0), "No trainer assigned yet or model not submitted.");
        require(!trainingTaskProposals[_proposalId].isActive, "Proposal is not active."); // Ensure proposal is not active anymore.

        if (trainingTaskProposals[_proposalId].modelAccepted) {
            uint256 rewardAmount = trainingTaskProposals[_proposalId].rewardAmount;
            require(daoTokenBalance[address(this)] >= rewardAmount, "DAO treasury insufficient for rewards.");

            daoTokenBalance[trainingTaskProposals[_proposalId].trainer] += rewardAmount; // Reward trainer (replace with token transfer if using ERC20)
            daoTokenBalance[address(this)] -= rewardAmount;

            contributorReputation[trainingTaskProposals[_proposalId].trainer] += 5; // Increase trainer reputation for successful task
            emit TrainingTaskFinalized(_proposalId, true);
        } else {
            emit TrainingTaskFinalized(_proposalId, false); // Model rejected, no rewards
        }
        trainingTaskProposals[_proposalId].isActive = false; // Ensure proposal is no longer active.
    }

    /// @notice Retrieves details of a specific training task proposal.
    /// @param _proposalId ID of the training task proposal.
    /// @return TrainingTaskProposal struct containing proposal details.
    function getTrainingTaskDetails(uint256 _proposalId) external view returns (TrainingTaskProposal memory) {
        return trainingTaskProposals[_proposalId];
    }


    // **** Governance & DAO Management Functions ****

    /// @notice Allows DAO members to deposit tokens into the DAO treasury.
    function deposit() external payable notPaused {
        daoTokenBalance[msg.sender] += msg.value; // Assuming native tokens for DAO membership/rewards. Use ERC20 transfer for ERC20 tokens.
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows DAO members to withdraw tokens from their DAO balance.
    /// @param _amount Amount to withdraw.
    function withdraw(uint256 _amount) external onlyDAO मेंबर notPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(daoTokenBalance[msg.sender] >= _amount, "Insufficient DAO balance.");

        daoTokenBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount); // Transfer native tokens. Use ERC20 transfer for ERC20 tokens.
        emit Withdrawal(msg.sender, _amount);
    }

    /// @notice Allows members to propose a change to a DAO parameter.
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyAdmin notPaused { // Admin can propose parameter changes in this example - can be DAO member in a real DAO
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");

        parameterChangeProposals[nextParameterProposalId] = ParameterChangeProposal({
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isApproved: false,
            isExecuted: false
        });

        emit ParameterChangeProposed(nextParameterProposalId, _parameterName, _newValue);
        nextParameterProposalId++;
    }

    /// @notice Allows DAO members to vote on a parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _vote Boolean vote (true for yes, false for no).
    function voteOnParameterChange(uint256 _proposalId, bool _vote) external onlyDAO मेंबर notPaused {
        require(parameterChangeProposals[_proposalId].isActive, "Parameter change proposal is not active.");
        require(block.timestamp < parameterChangeProposals[_proposalId].voteEndTime, "Voting period is over.");

        if (_vote) {
            parameterChangeProposals[_proposalId].yesVotes++;
        } else {
            parameterChangeProposals[_proposalId].noVotes++;
        }
        emit ParameterChangeVoteCast(_proposalId, parameterChangeProposals[_proposalId].newValue, _vote);
    }

    /// @notice Admin function to execute an approved parameter change.
    /// @param _proposalId ID of the parameter change proposal.
    function executeParameterChange(uint256 _proposalId) external onlyAdmin notPaused {
        require(parameterChangeProposals[_proposalId].isApproved, "Parameter change proposal is not approved.");
        require(!parameterChangeProposals[_proposalId].isExecuted, "Parameter change proposal already executed.");
        require(parameterChangeProposals[_proposalId].yesVotes > parameterChangeProposals[_proposalId].noVotes, "Proposal did not receive enough yes votes."); // Example approval criteria

        string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
        uint256 newValue = parameterChangeProposals[_proposalId].newValue;

        if (keccak256(bytes(parameterName)) == keccak256(bytes("votingPeriod"))) {
            votingPeriod = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("dataStakeCoolingPeriod"))) {
            dataStakeCoolingPeriod = newValue;
        } else {
            revert("Invalid parameter name for change.");
        }

        parameterChangeProposals[_proposalId].isExecuted = true;
        parameterChangeProposals[_proposalId].isActive = false; // Deactivate proposal after execution

        emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
    }

    /// @notice Retrieves the current value of a DAO parameter.
    /// @param _parameterName Name of the parameter to retrieve.
    /// @return Current value of the parameter.
    function getDAOParameter(string memory _parameterName) external view returns (uint256) {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingPeriod"))) {
            return votingPeriod;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("dataStakeCoolingPeriod"))) {
            return dataStakeCoolingPeriod;
        } else {
            revert("Invalid parameter name.");
        }
    }

    /// @notice Admin function to assign or revoke validator roles.
    /// @param _validator Address of the validator.
    /// @param _isValidator Boolean to set or revoke validator role.
    function setValidatorRole(address _validator, bool _isValidator) external onlyAdmin notPaused {
        isValidatorRole[_validator] = _isValidator;
        emit ValidatorRoleSet(_validator, _isValidator); // Assuming you add this event
    }
        event ValidatorRoleSet(address indexed validator, bool isValidator);

    /// @notice Check if an address has validator role.
    /// @param _validator Address to check.
    /// @return True if the address has validator role, false otherwise.
    function getValidatorStatus(address _validator) external view returns (bool) {
        return isValidatorRole[_validator];
    }

    /// @notice Admin function to assign or revoke admin roles.
    /// @param _admin Address of the admin.
    /// @param _isAdmin Boolean to set or revoke admin role.
    function setAdminRole(address _admin, bool _isAdmin) external onlyAdmin notPaused {
        require(_admin != address(0), "Invalid admin address."); // Prevent setting admin to zero address
        isAdminRole[_admin] = _isAdmin;
        emit AdminRoleSet(_admin, _isAdmin); // Assuming you add this event
    }
        event AdminRoleSet(address indexed adminAddress, bool isAdmin);

    /// @notice Check if an address has admin role.
    /// @param _admin Address to check.
    /// @return True if the address has admin role, false otherwise.
    function getAdminStatus(address _admin) external view returns (bool) {
        return isAdminRole[_admin];
    }

    /// @notice Admin function to pause core functionalities of the contract.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to resume contract functionalities after pausing.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }
}
```