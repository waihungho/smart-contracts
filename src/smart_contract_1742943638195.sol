```solidity
/**
 * @title Decentralized Autonomous Organization for Collaborative AI Model Training (DAOCAI)
 * @author Your Name or Organization (Replace with your info)
 * @dev A smart contract for a DAO focused on collaborative AI model training.
 * It allows members to propose and vote on datasets, training tasks, model evaluations,
 * and reward distributions. It incorporates advanced concepts like data provenance,
 * model versioning, and decentralized model evaluation.
 *
 * **Outline and Function Summary:**
 *
 * **Core DAO Functions:**
 * 1. `joinDAO()`: Allows users to request membership in the DAO.
 * 2. `approveMember(address _member)`: DAO admin function to approve pending membership requests.
 * 3. `revokeMembership(address _member)`: DAO admin function to revoke a member's membership.
 * 4. `proposeDataset(string _datasetName, string _datasetCID, string _datasetDescription)`: Allows members to propose datasets for AI training.
 * 5. `voteOnDatasetProposal(uint _proposalId, bool _vote)`: Allows members to vote on dataset proposals.
 * 6. `proposeTrainingTask(uint _datasetProposalId, string _taskDescription, string _modelArchitecture, string _trainingParameters)`: Allows members to propose AI training tasks based on approved datasets.
 * 7. `voteOnTrainingTaskProposal(uint _proposalId, bool _vote)`: Allows members to vote on training task proposals.
 * 8. `submitTrainedModel(uint _trainingTaskId, string _modelCID, string _evaluationMetricsCID)`: Allows members to submit trained AI models for approved training tasks.
 * 9. `proposeModelEvaluation(uint _modelSubmissionId, string _evaluationCriteria)`: Allows members to propose evaluation criteria for submitted models.
 * 10. `voteOnModelEvaluationProposal(uint _proposalId, bool _vote)`: Allows members to vote on model evaluation proposals.
 * 11. `submitModelEvaluation(uint _modelSubmissionId, string _evaluationReportCID)`: Allows members to submit evaluation reports for trained models based on approved criteria.
 * 12. `proposeRewardDistribution(uint _trainingTaskId, address[] _contributors, uint[] _rewardAmounts)`: Allows DAO admins to propose reward distributions for contributors to a training task.
 * 13. `voteOnRewardDistributionProposal(uint _proposalId, bool _vote)`: Allows members to vote on reward distribution proposals.
 * 14. `distributeRewards(uint _proposalId)`: DAO admin function to distribute rewards after a reward distribution proposal is approved.
 * 15. `getParameter(string _parameterName)`: Allows retrieval of DAO parameters (e.g., voting quorum, membership fee).
 * 16. `setParameter(string _parameterName, uint _parameterValue)`: DAO admin function to set DAO parameters.
 *
 * **Advanced AI/Data Concepts:**
 * 17. `getDataProvenance(uint _datasetProposalId)`: Function to track the provenance of a dataset proposal (submitter, submission time).
 * 18. `getModelVersionHistory(uint _trainingTaskId)`: Function to retrieve the version history of models submitted for a training task.
 * 19. `getDatasetProposalsByStatus(ProposalStatus _status)`: Function to filter dataset proposals by their status (Pending, Approved, Rejected).
 * 20. `getTrainingTasksByDataset(uint _datasetProposalId)`: Function to retrieve training tasks associated with a specific dataset.
 * 21. `getBestModelForTask(uint _trainingTaskId)`: Function to retrieve the model submission deemed "best" for a given training task (based on evaluation, could be admin selected or DAO voted - Placeholder for advanced logic).
 * 22. `depositFunds()`: Allows users to deposit funds into the DAO treasury (for membership fees, task rewards, etc.).
 * 23. `withdrawFunds(uint _amount)`: DAO admin function to withdraw funds from the treasury.
 * 24. `getTreasuryBalance()`: Function to view the DAO treasury balance.
 */
pragma solidity ^0.8.0;

contract DAOCAI {

    enum ProposalStatus { Pending, Approved, Rejected }
    enum MembershipStatus { Pending, Approved, Revoked }

    struct Member {
        address memberAddress;
        MembershipStatus status;
        uint joinTimestamp;
    }

    struct DatasetProposal {
        uint proposalId;
        string datasetName;
        string datasetCID; // IPFS CID or similar content identifier
        string datasetDescription;
        address proposer;
        ProposalStatus status;
        uint submissionTimestamp;
        uint yesVotes;
        uint noVotes;
    }

    struct TrainingTaskProposal {
        uint proposalId;
        uint datasetProposalId;
        string taskDescription;
        string modelArchitecture;
        string trainingParameters;
        address proposer;
        ProposalStatus status;
        uint submissionTimestamp;
        uint yesVotes;
        uint noVotes;
    }

    struct ModelSubmission {
        uint submissionId;
        uint trainingTaskId;
        address submitter;
        string modelCID; // IPFS CID for the trained model
        string evaluationMetricsCID; // IPFS CID for evaluation metrics
        uint submissionTimestamp;
        string evaluationReportCID; // IPFS CID for evaluation report (after evaluation)
        bool isBestModel; // Flag if this model is considered the best for the task
    }

    struct ModelEvaluationProposal {
        uint proposalId;
        uint modelSubmissionId;
        string evaluationCriteria;
        address proposer;
        ProposalStatus status;
        uint submissionTimestamp;
        uint yesVotes;
        uint noVotes;
    }

    struct RewardDistributionProposal {
        uint proposalId;
        uint trainingTaskId;
        address[] contributors;
        uint[] rewardAmounts;
        address proposer; // Typically DAO admin
        ProposalStatus status;
        uint submissionTimestamp;
        uint yesVotes;
        uint noVotes;
    }

    mapping(address => Member) public members;
    mapping(uint => DatasetProposal) public datasetProposals;
    mapping(uint => TrainingTaskProposal) public trainingTaskProposals;
    mapping(uint => ModelSubmission) public modelSubmissions;
    mapping(uint => ModelEvaluationProposal) public modelEvaluationProposals;
    mapping(uint => RewardDistributionProposal) public rewardDistributionProposals;
    mapping(string => uint) public daoParameters; // Store DAO parameters like voting quorum, membership fee

    uint public nextDatasetProposalId = 1;
    uint public nextTrainingTaskProposalId = 1;
    uint public nextModelSubmissionId = 1;
    uint public nextModelEvaluationProposalId = 1;
    uint public nextRewardDistributionProposalId = 1;
    address public daoAdmin;
    uint public membershipFee; // Example DAO parameter

    event MembershipRequested(address memberAddress);
    event MembershipApproved(address memberAddress);
    event MembershipRevoked(address memberAddress);
    event DatasetProposalCreated(uint proposalId, string datasetName, address proposer);
    event DatasetProposalVoted(uint proposalId, address voter, bool vote);
    event TrainingTaskProposalCreated(uint proposalId, uint datasetProposalId, address proposer);
    event TrainingTaskProposalVoted(uint proposalId, address voter, bool vote);
    event ModelSubmitted(uint submissionId, uint trainingTaskId, address submitter);
    event ModelEvaluationProposalCreated(uint proposalId, uint modelSubmissionId, address proposer);
    event ModelEvaluationProposalVoted(uint proposalId, address voter, bool vote);
    event ModelEvaluationSubmitted(uint modelSubmissionId, string evaluationReportCID);
    event RewardDistributionProposalCreated(uint proposalId, uint trainingTaskId, address proposer);
    event RewardDistributionProposalVoted(uint proposalId, address voter, bool vote);
    event RewardsDistributed(uint proposalId, uint trainingTaskId);
    event ParameterSet(string parameterName, uint parameterValue);
    event FundsDeposited(address depositor, uint amount);
    event FundsWithdrawn(address withdrawer, uint amount);

    modifier onlyMember() {
        require(members[msg.sender].status == MembershipStatus.Approved, "Not an approved DAO member.");
        _;
    }

    modifier onlyDAOAdmin() {
        require(msg.sender == daoAdmin, "Only DAO admin can call this function.");
        _;
    }

    constructor() {
        daoAdmin = msg.sender;
        membershipFee = 1 ether; // Example initial membership fee
        daoParameters["votingQuorum"] = 50; // Example: 50% voting quorum
    }

    // **** Core DAO Functions ****

    /// @notice Allows users to request membership in the DAO.
    function joinDAO() public payable {
        require(members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Approved == false, "Membership already requested or active.");
        require(msg.value >= membershipFee, "Insufficient membership fee sent.");
        members[msg.sender] = Member(msg.sender, MembershipStatus.Pending, block.timestamp);
        emit MembershipRequested(msg.sender);
        // Optionally transfer membership fee to treasury here or in approveMember
    }

    /// @notice DAO admin function to approve pending membership requests.
    /// @param _member Address of the member to approve.
    function approveMember(address _member) public onlyDAOAdmin {
        require(members[_member].status == MembershipStatus.Pending, "Member is not in pending status.");
        members[_member].status = MembershipStatus.Approved;
        payable(address(this)).transfer(membershipFee); // Transfer membership fee to DAO treasury
        emit MembershipApproved(_member);
    }

    /// @notice DAO admin function to revoke a member's membership.
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) public onlyDAOAdmin {
        require(members[_member].status == MembershipStatus.Approved, "Member is not currently approved.");
        members[_member].status = MembershipStatus.Revoked;
        emit MembershipRevoked(_member);
    }

    /// @notice Allows members to propose datasets for AI training.
    /// @param _datasetName Name of the dataset.
    /// @param _datasetCID IPFS CID or similar identifier for the dataset.
    /// @param _datasetDescription Description of the dataset.
    function proposeDataset(string memory _datasetName, string memory _datasetCID, string memory _datasetDescription) public onlyMember {
        datasetProposals[nextDatasetProposalId] = DatasetProposal({
            proposalId: nextDatasetProposalId,
            datasetName: _datasetName,
            datasetCID: _datasetCID,
            datasetDescription: _datasetDescription,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        emit DatasetProposalCreated(nextDatasetProposalId, _datasetName, msg.sender);
        nextDatasetProposalId++;
    }

    /// @notice Allows members to vote on dataset proposals.
    /// @param _proposalId ID of the dataset proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnDatasetProposal(uint _proposalId, bool _vote) public onlyMember {
        require(datasetProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(datasetProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal.");
        DatasetProposal storage proposal = datasetProposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit DatasetProposalVoted(_proposalId, msg.sender, _vote);
        _checkProposalOutcome(_proposalId, ProposalType.Dataset);
    }

    /// @notice Allows members to propose AI training tasks based on approved datasets.
    /// @param _datasetProposalId ID of the approved dataset proposal.
    /// @param _taskDescription Description of the training task.
    /// @param _modelArchitecture Model architecture to be used for training.
    /// @param _trainingParameters Training parameters for the task.
    function proposeTrainingTask(uint _datasetProposalId, string memory _taskDescription, string memory _modelArchitecture, string memory _trainingParameters) public onlyMember {
        require(datasetProposals[_datasetProposalId].status == ProposalStatus.Approved, "Dataset proposal must be approved to propose training task.");
        trainingTaskProposals[nextTrainingTaskProposalId] = TrainingTaskProposal({
            proposalId: nextTrainingTaskProposalId,
            datasetProposalId: _datasetProposalId,
            taskDescription: _taskDescription,
            modelArchitecture: _modelArchitecture,
            trainingParameters: _trainingParameters,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        emit TrainingTaskProposalCreated(nextTrainingTaskProposalId, _datasetProposalId, msg.sender);
        nextTrainingTaskProposalId++;
    }

    /// @notice Allows members to vote on training task proposals.
    /// @param _proposalId ID of the training task proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnTrainingTaskProposal(uint _proposalId, bool _vote) public onlyMember {
        require(trainingTaskProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(trainingTaskProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal.");
        TrainingTaskProposal storage proposal = trainingTaskProposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit TrainingTaskProposalVoted(_proposalId, msg.sender, _vote);
        _checkProposalOutcome(_proposalId, ProposalType.TrainingTask);
    }

    /// @notice Allows members to submit trained AI models for approved training tasks.
    /// @param _trainingTaskId ID of the approved training task.
    /// @param _modelCID IPFS CID or similar identifier for the trained model.
    /// @param _evaluationMetricsCID IPFS CID or similar identifier for evaluation metrics of the model.
    function submitTrainedModel(uint _trainingTaskId, string memory _modelCID, string memory _evaluationMetricsCID) public onlyMember {
        require(trainingTaskProposals[_trainingTaskId].status == ProposalStatus.Approved, "Training task must be approved to submit model.");
        modelSubmissions[nextModelSubmissionId] = ModelSubmission({
            submissionId: nextModelSubmissionId,
            trainingTaskId: _trainingTaskId,
            submitter: msg.sender,
            modelCID: _modelCID,
            evaluationMetricsCID: _evaluationMetricsCID,
            submissionTimestamp: block.timestamp,
            evaluationReportCID: "", // Initially empty, filled after evaluation
            isBestModel: false // Initially false
        });
        emit ModelSubmitted(nextModelSubmissionId, _trainingTaskId, msg.sender);
        nextModelSubmissionId++;
    }

    /// @notice Allows members to propose evaluation criteria for submitted models.
    /// @param _modelSubmissionId ID of the model submission to evaluate.
    /// @param _evaluationCriteria Description of the evaluation criteria.
    function proposeModelEvaluation(uint _modelSubmissionId, string memory _evaluationCriteria) public onlyMember {
        require(modelSubmissions[_modelSubmissionId].submissionId > 0, "Invalid model submission ID.");
        modelEvaluationProposals[nextModelEvaluationProposalId] = ModelEvaluationProposal({
            proposalId: nextModelEvaluationProposalId,
            modelSubmissionId: _modelSubmissionId,
            evaluationCriteria: _evaluationCriteria,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        emit ModelEvaluationProposalCreated(nextModelEvaluationProposalId, _modelSubmissionId, msg.sender);
        nextModelEvaluationProposalId++;
    }

    /// @notice Allows members to vote on model evaluation proposals.
    /// @param _proposalId ID of the model evaluation proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnModelEvaluationProposal(uint _proposalId, bool _vote) public onlyMember {
        require(modelEvaluationProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(modelEvaluationProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal.");
        ModelEvaluationProposal storage proposal = modelEvaluationProposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ModelEvaluationProposalVoted(_proposalId, msg.sender, _vote);
        _checkProposalOutcome(_proposalId, ProposalType.ModelEvaluation);
    }

    /// @notice Allows members to submit evaluation reports for trained models based on approved criteria.
    /// @param _modelSubmissionId ID of the model submission being evaluated.
    /// @param _evaluationReportCID IPFS CID or similar identifier for the evaluation report.
    function submitModelEvaluation(uint _modelSubmissionId, string memory _evaluationReportCID) public onlyMember {
        require(modelEvaluationProposals[getLatestActiveModelEvaluationProposalId(_modelSubmissionId)].status == ProposalStatus.Approved, "Model evaluation proposal must be approved to submit report.");
        require(modelSubmissions[_modelSubmissionId].submissionId > 0, "Invalid model submission ID.");
        modelSubmissions[_modelSubmissionId].evaluationReportCID = _evaluationReportCID;
        emit ModelEvaluationSubmitted(_modelSubmissionId, _evaluationReportCID);
    }

    /// @notice Allows DAO admins to propose reward distributions for contributors to a training task.
    /// @param _trainingTaskId ID of the training task.
    /// @param _contributors Array of addresses to receive rewards.
    /// @param _rewardAmounts Array of reward amounts for each contributor.
    function proposeRewardDistribution(uint _trainingTaskId, address[] memory _contributors, uint[] memory _rewardAmounts) public onlyDAOAdmin {
        require(_contributors.length == _rewardAmounts.length, "Contributors and reward amounts arrays must have the same length.");
        rewardDistributionProposals[nextRewardDistributionProposalId] = RewardDistributionProposal({
            proposalId: nextRewardDistributionProposalId,
            trainingTaskId: _trainingTaskId,
            contributors: _contributors,
            rewardAmounts: _rewardAmounts,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        emit RewardDistributionProposalCreated(nextRewardDistributionProposalId, _trainingTaskId, msg.sender);
        nextRewardDistributionProposalId++;
    }

    /// @notice Allows members to vote on reward distribution proposals.
    /// @param _proposalId ID of the reward distribution proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnRewardDistributionProposal(uint _proposalId, bool _vote) public onlyMember {
        require(rewardDistributionProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(rewardDistributionProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal."); // Admin is proposer, members vote
        RewardDistributionProposal storage proposal = rewardDistributionProposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit RewardDistributionProposalVoted(_proposalId, msg.sender, _vote);
        _checkProposalOutcome(_proposalId, ProposalType.RewardDistribution);
    }

    /// @notice DAO admin function to distribute rewards after a reward distribution proposal is approved.
    /// @param _proposalId ID of the reward distribution proposal.
    function distributeRewards(uint _proposalId) public onlyDAOAdmin {
        require(rewardDistributionProposals[_proposalId].status == ProposalStatus.Approved, "Reward distribution proposal must be approved.");
        RewardDistributionProposal storage proposal = rewardDistributionProposals[_proposalId];
        for (uint i = 0; i < proposal.contributors.length; i++) {
            payable(proposal.contributors[i]).transfer(proposal.rewardAmounts[i]);
        }
        rewardDistributionProposals[_proposalId].status = ProposalStatus.Rejected; // Mark as rejected after distribution to prevent re-distribution. Could use other status like 'Distributed' in more complex setup
        emit RewardsDistributed(_proposalId, proposal.trainingTaskId);
    }

    /// @notice Allows retrieval of DAO parameters (e.g., voting quorum, membership fee).
    /// @param _parameterName Name of the DAO parameter.
    /// @return The value of the DAO parameter.
    function getParameter(string memory _parameterName) public view returns (uint) {
        return daoParameters[_parameterName];
    }

    /// @notice DAO admin function to set DAO parameters.
    /// @param _parameterName Name of the DAO parameter to set.
    /// @param _parameterValue New value for the DAO parameter.
    function setParameter(string memory _parameterName, uint _parameterValue) public onlyDAOAdmin {
        daoParameters[_parameterName] = _parameterValue;
        emit ParameterSet(_parameterName, _parameterValue);
    }

    // **** Advanced AI/Data Concepts ****

    /// @notice Function to track the provenance of a dataset proposal.
    /// @param _datasetProposalId ID of the dataset proposal.
    /// @return Proposer address, submission timestamp.
    function getDataProvenance(uint _datasetProposalId) public view returns (address proposer, uint submissionTimestamp) {
        require(datasetProposals[_datasetProposalId].proposalId > 0, "Invalid dataset proposal ID.");
        return (datasetProposals[_datasetProposalId].proposer, datasetProposals[_datasetProposalId].submissionTimestamp);
    }

    /// @notice Function to retrieve the version history of models submitted for a training task.
    /// @param _trainingTaskId ID of the training task.
    /// @return Array of model submission IDs.
    function getModelVersionHistory(uint _trainingTaskId) public view returns (uint[] memory) {
        uint[] memory versionHistory = new uint[](nextModelSubmissionId); // Overestimate size, will trim
        uint count = 0;
        for (uint i = 1; i < nextModelSubmissionId; i++) {
            if (modelSubmissions[i].trainingTaskId == _trainingTaskId) {
                versionHistory[count] = modelSubmissions[i].submissionId;
                count++;
            }
        }
        // Trim the array to the actual number of versions
        uint[] memory trimmedHistory = new uint[](count);
        for (uint i = 0; i < count; i++) {
            trimmedHistory[i] = versionHistory[i];
        }
        return trimmedHistory;
    }

    /// @notice Function to filter dataset proposals by their status (Pending, Approved, Rejected).
    /// @param _status Status to filter by.
    /// @return Array of dataset proposal IDs with the given status.
    function getDatasetProposalsByStatus(ProposalStatus _status) public view returns (uint[] memory) {
        uint[] memory proposals = new uint[](nextDatasetProposalId); // Overestimate size
        uint count = 0;
        for (uint i = 1; i < nextDatasetProposalId; i++) {
            if (datasetProposals[i].status == _status) {
                proposals[count] = datasetProposals[i].proposalId;
                count++;
            }
        }
        uint[] memory trimmedProposals = new uint[](count);
        for (uint i = 0; i < count; i++) {
            trimmedProposals[i] = proposals[i];
        }
        return trimmedProposals;
    }

    /// @notice Function to retrieve training tasks associated with a specific dataset.
    /// @param _datasetProposalId ID of the dataset proposal.
    /// @return Array of training task proposal IDs for the given dataset.
    function getTrainingTasksByDataset(uint _datasetProposalId) public view returns (uint[] memory) {
        uint[] memory tasks = new uint[](nextTrainingTaskProposalId); // Overestimate size
        uint count = 0;
        for (uint i = 1; i < nextTrainingTaskProposalId; i++) {
            if (trainingTaskProposals[i].datasetProposalId == _datasetProposalId) {
                tasks[count] = trainingTaskProposals[i].proposalId;
                count++;
            }
        }
        uint[] memory trimmedTasks = new uint[](count);
        for (uint i = 0; i < count; i++) {
            trimmedTasks[i] = tasks[i];
        }
        return trimmedTasks;
    }

    /// @notice Function to retrieve the model submission deemed "best" for a given training task.
    /// @param _trainingTaskId ID of the training task.
    /// @return ID of the best model submission, or 0 if none is marked as best.
    function getBestModelForTask(uint _trainingTaskId) public view returns (uint) {
        for (uint i = 1; i < nextModelSubmissionId; i++) {
            if (modelSubmissions[i].trainingTaskId == _trainingTaskId && modelSubmissions[i].isBestModel) {
                return modelSubmissions[i].submissionId;
            }
        }
        return 0; // No best model found
    }

    /// @notice Allows users to deposit funds into the DAO treasury.
    function depositFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice DAO admin function to withdraw funds from the treasury.
    /// @param _amount Amount to withdraw.
    function withdrawFunds(uint _amount) public onlyDAOAdmin {
        require(address(this).balance >= _amount, "Insufficient DAO treasury balance.");
        payable(daoAdmin).transfer(_amount);
        emit FundsWithdrawn(daoAdmin, _amount);
    }

    /// @notice Function to view the DAO treasury balance.
    /// @return The current balance of the DAO treasury.
    function getTreasuryBalance() public view returns (uint) {
        return address(this).balance;
    }

    // **** Internal Helper Functions ****

    enum ProposalType { Dataset, TrainingTask, ModelEvaluation, RewardDistribution }

    function _checkProposalOutcome(uint _proposalId, ProposalType _proposalType) internal {
        uint quorumPercentage = daoParameters["votingQuorum"];
        uint totalVotes = 0;
        uint yesVotes = 0;

        if (_proposalType == ProposalType.Dataset) {
            totalVotes = datasetProposals[_proposalId].yesVotes + datasetProposals[_proposalId].noVotes;
            yesVotes = datasetProposals[_proposalId].yesVotes;
            if (totalVotes > 0 && (yesVotes * 100) / totalVotes >= quorumPercentage) {
                datasetProposals[_proposalId].status = ProposalStatus.Approved;
            } else if (totalVotes > 0 && (datasetProposals[_proposalId].noVotes * 100) / totalVotes > (100 - quorumPercentage)) { // If no votes exceed the opposite of quorum
                datasetProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        } else if (_proposalType == ProposalType.TrainingTask) {
            totalVotes = trainingTaskProposals[_proposalId].yesVotes + trainingTaskProposals[_proposalId].noVotes;
            yesVotes = trainingTaskProposals[_proposalId].yesVotes;
            if (totalVotes > 0 && (yesVotes * 100) / totalVotes >= quorumPercentage) {
                trainingTaskProposals[_proposalId].status = ProposalStatus.Approved;
            } else if (totalVotes > 0 && (trainingTaskProposals[_proposalId].noVotes * 100) / totalVotes > (100 - quorumPercentage)) {
                trainingTaskProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        } else if (_proposalType == ProposalType.ModelEvaluation) {
            totalVotes = modelEvaluationProposals[_proposalId].yesVotes + modelEvaluationProposals[_proposalId].noVotes;
            yesVotes = modelEvaluationProposals[_proposalId].yesVotes;
            if (totalVotes > 0 && (yesVotes * 100) / totalVotes >= quorumPercentage) {
                modelEvaluationProposals[_proposalId].status = ProposalStatus.Approved;
            } else if (totalVotes > 0 && (modelEvaluationProposals[_proposalId].noVotes * 100) / totalVotes > (100 - quorumPercentage)) {
                modelEvaluationProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        } else if (_proposalType == ProposalType.RewardDistribution) {
            totalVotes = rewardDistributionProposals[_proposalId].yesVotes + rewardDistributionProposals[_proposalId].noVotes;
            yesVotes = rewardDistributionProposals[_proposalId].yesVotes;
            if (totalVotes > 0 && (yesVotes * 100) / totalVotes >= quorumPercentage) {
                rewardDistributionProposals[_proposalId].status = ProposalStatus.Approved;
            } else if (totalVotes > 0 && (rewardDistributionProposals[_proposalId].noVotes * 100) / totalVotes > (100 - quorumPercentage)) {
                rewardDistributionProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        }
    }

    function getLatestActiveModelEvaluationProposalId(uint _modelSubmissionId) internal view returns (uint) {
        uint latestProposalId = 0;
        for (uint i = 1; i < nextModelEvaluationProposalId; i++) {
            if (modelEvaluationProposals[i].modelSubmissionId == _modelSubmissionId && modelEvaluationProposals[i].status == ProposalStatus.Approved) { // Assuming only one active approved proposal per model at a time for simplicity
                latestProposalId = modelEvaluationProposals[i].proposalId;
            }
        }
        return latestProposalId;
    }
}
```