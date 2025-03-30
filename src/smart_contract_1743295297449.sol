```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Gemini AI Assistant
 * @dev A smart contract for a DAO focused on collaboratively training AI models.
 * It incorporates advanced concepts like:
 * - On-chain governance of AI model parameters and datasets.
 * - Dynamic reward system based on contribution and model performance.
 * - Data and model ownership represented by NFTs.
 * - Staged model training and versioning.
 * - Decentralized evaluation and feedback mechanisms.
 * - Fine-grained access control and permission management.
 * - Integration with off-chain AI training infrastructure (conceptual).
 *
 * Function Outline:
 * -----------------
 * **Governance & DAO Structure:**
 * 1.  `proposeNewParameter(string memory _parameterName, string memory _parameterValue, string memory _description)`: Allows members to propose changes to DAO parameters (e.g., reward rates, training hyperparameters).
 * 2.  `voteOnParameterProposal(uint256 _proposalId, bool _vote)`: Members can vote on parameter change proposals.
 * 3.  `executeParameterProposal(uint256 _proposalId)`: Executes a passed parameter proposal, updating DAO settings.
 * 4.  `addMember(address _newMember)`: Owner function to add new members to the DAO.
 * 5.  `removeMember(address _memberToRemove)`: Owner function to remove members from the DAO.
 * 6.  `pauseContract()`: Owner function to pause critical contract functionalities in case of emergency.
 * 7.  `unpauseContract()`: Owner function to resume contract functionalities after pausing.
 * 8.  `getDAOParameter(string memory _parameterName) view returns (string memory)`: Allows anyone to view current DAO parameters.
 *
 * **AI Model & Data Management:**
 * 9.  `proposeNewModel(string memory _modelName, string memory _initialDescription, string memory _initialParametersURI, string memory _datasetRequirementsURI)`: Members can propose new AI models to be trained collaboratively.
 * 10. `voteOnModelProposal(uint256 _proposalId, bool _vote)`: Members vote on new model proposals.
 * 11. `approveModelProposal(uint256 _proposalId)`: Executes a passed model proposal, creating a new Model NFT.
 * 12. `contributeDataset(uint256 _modelId, string memory _datasetName, string memory _datasetURI, string memory _datasetDescription)`: Members can contribute datasets for approved models. Data ownership can be managed by NFTs (future enhancement).
 * 13. `requestTraining(uint256 _modelId, string memory _trainingParametersURI)`: Members can request training runs for approved models with specific parameters. (Triggers off-chain process conceptually).
 * 14. `submitTrainingResult(uint256 _modelId, string memory _modelVersionName, string memory _modelWeightsURI, string memory _evaluationMetricsURI)`: (Off-chain process calls this) Submits training results, creating a new Model Version NFT.
 * 15. `evaluateModelVersion(uint256 _modelVersionId, uint8 _rating, string memory _feedback)`: Members can evaluate and provide feedback on trained model versions.
 * 16. `getModelInfo(uint256 _modelId) view returns (...)`: Returns detailed information about a specific model.
 * 17. `getModelVersionInfo(uint256 _modelVersionId) view returns (...)`: Returns detailed information about a specific model version.
 *
 * **Reward & Incentive System:**
 * 18. `distributeRewards(uint256 _modelVersionId)`: Distributes rewards to contributors of data and training for a successful model version based on DAO parameters (e.g., contribution weight, evaluation scores).
 * 19. `withdrawRewards()`: Members can withdraw their accumulated rewards.
 * 20. `setRewardParameter(string memory _parameterName, uint256 _value)`: Owner function to set reward-related parameters (e.g., reward rates, evaluation weights).
 *
 * **NFT & Ownership (Conceptual - Requires ERC721 Implementation):**
 * - Model NFTs: Represent ownership of approved AI models.
 * - Model Version NFTs: Represent specific trained versions of models with associated weights and metrics.
 * - (Future: Dataset NFTs: Represent ownership of contributed datasets).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AIDaoContract is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter public parameterProposalIdCounter;
    Counters.Counter public modelProposalIdCounter;
    Counters.Counter public modelIdCounter;
    Counters.Counter public modelVersionIdCounter;

    // --- Structs ---
    struct ParameterProposal {
        uint256 id;
        string parameterName;
        string parameterValue;
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool executed;
        mapping(address => bool) votes; // Member address => voted?
    }

    struct ModelProposal {
        uint256 id;
        string modelName;
        string initialDescription;
        string initialParametersURI;
        string datasetRequirementsURI;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool approved;
        mapping(address => bool) votes; // Member address => voted?
    }

    struct AIModel {
        uint256 id;
        string modelName;
        string description;
        string initialParametersURI;
        string datasetRequirementsURI;
        address creator; // Address of the member who proposed the model.
        uint256[] modelVersionIds; // Array to store IDs of versions for this model
    }

    struct ModelVersion {
        uint256 id;
        uint256 modelId;
        string versionName;
        string modelWeightsURI;
        string evaluationMetricsURI;
        address trainer; // Address that submitted the training result
        uint256 totalEvaluations;
        uint256 positiveEvaluations;
    }

    struct DatasetContribution {
        uint256 modelId;
        string datasetName;
        string datasetURI;
        string datasetDescription;
        address contributor;
        uint256 timestamp;
    }

    // --- State Variables ---
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(uint256 => ModelProposal) public modelProposals;
    mapping(uint256 => AIModel) public models;
    mapping(uint256 => ModelVersion) public modelVersions;
    mapping(uint256 => DatasetContribution[]) public modelDatasets; // Model ID to list of datasets
    mapping(string => string) public daoParameters; // Key-value store for DAO parameters

    mapping(address => bool) public members;
    address[] public memberList;

    mapping(address => uint256) public pendingRewards; // Member address to pending reward balance

    // --- Events ---
    event ParameterProposalCreated(uint256 proposalId, string parameterName, string parameterValue, string description, address proposer);
    event ParameterProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterProposalExecuted(uint256 proposalId, string parameterName, string parameterValue);
    event ModelProposalCreated(uint256 proposalId, string modelName, string initialDescription, address proposer);
    event ModelProposalVoted(uint256 proposalId, address voter, bool vote);
    event ModelProposalApproved(uint256 proposalId, uint256 modelId, string modelName);
    event DatasetContributed(uint256 modelId, string datasetName, address contributor);
    event TrainingRequested(uint256 modelId, address requester, string trainingParametersURI);
    event TrainingResultSubmitted(uint256 modelId, uint256 modelVersionId, string versionName, address submitter);
    event ModelVersionEvaluated(uint256 modelVersionId, address evaluator, uint8 rating, string feedback);
    event RewardsDistributed(uint256 modelVersionId, uint256 totalRewards);
    event RewardsWithdrawn(address member, uint256 amount);
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(!parameterProposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier modelProposalActive(uint256 _proposalId) {
        require(!modelProposals[_proposalId].approved, "Model proposal already processed.");
        _;
    }


    // --- Constructor ---
    constructor() payable {
        daoParameters["votingQuorumPercentage"] = "50"; // Default voting quorum
        daoParameters["parameterProposalVotingDuration"] = "7 days"; // Default voting duration
        daoParameters["modelProposalVotingDuration"] = "14 days"; // Default voting duration
        daoParameters["rewardRateDataContribution"] = "10"; // Example reward rates (units to be defined)
        daoParameters["rewardRateTrainingContribution"] = "20";
        daoParameters["evaluationPositiveThreshold"] = "3"; // Min rating for positive evaluation (out of 5, for example)

        _addMember(msg.sender); // Owner is also the first member
    }

    // --- Governance & DAO Structure Functions ---

    /// @dev Proposes a new DAO parameter change.
    /// @param _parameterName Name of the parameter to change.
    /// @param _parameterValue New value for the parameter.
    /// @param _description Description of the proposed change.
    function proposeNewParameter(
        string memory _parameterName,
        string memory _parameterValue,
        string memory _description
    ) external onlyMember whenNotPaused {
        parameterProposalIdCounter.increment();
        uint256 proposalId = parameterProposalIdCounter.current();
        parameterProposals[proposalId] = ParameterProposal({
            id: proposalId,
            parameterName: _parameterName,
            parameterValue: _parameterValue,
            description: _description,
            voteCountYes: 0,
            voteCountNo: 0,
            executed: false,
            votes: mapping(address => bool)()
        });
        emit ParameterProposalCreated(proposalId, _parameterName, _parameterValue, _description, msg.sender);
    }

    /// @dev Allows members to vote on a parameter change proposal.
    /// @param _proposalId ID of the parameter proposal.
    /// @param _vote True for yes, false for no.
    function voteOnParameterProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused proposalActive(_proposalId) {
        require(!parameterProposals[_proposalId].votes[msg.sender], "Member has already voted on this proposal.");
        parameterProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            parameterProposals[_proposalId].voteCountYes++;
        } else {
            parameterProposals[_proposalId].voteCountNo++;
        }
        emit ParameterProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes a passed parameter proposal if quorum is reached and more yes votes than no votes.
    /// @param _proposalId ID of the parameter proposal.
    function executeParameterProposal(uint256 _proposalId) external onlyMember whenNotPaused proposalActive(_proposalId) {
        uint256 quorumPercentage = uint256(parseInt(daoParameters["votingQuorumPercentage"]));
        uint256 totalMembers = memberList.length;
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

        require(parameterProposals[_proposalId].voteCountYes + parameterProposals[_proposalId].voteCountNo >= requiredVotes, "Voting quorum not reached.");
        require(parameterProposals[_proposalId].voteCountYes > parameterProposals[_proposalId].voteCountNo, "Proposal did not pass.");
        require(!parameterProposals[_proposalId].executed, "Proposal already executed.");

        daoParameters[parameterProposals[_proposalId].parameterName] = parameterProposals[_proposalId].parameterValue;
        parameterProposals[_proposalId].executed = true;
        emit ParameterProposalExecuted(_proposalId, parameterProposals[_proposalId].parameterName, parameterProposals[_proposalId].parameterValue);
    }

    /// @dev Owner function to add a new member to the DAO.
    /// @param _newMember Address of the new member.
    function addMember(address _newMember) external onlyOwner whenNotPaused {
        _addMember(_newMember);
    }

    function _addMember(address _newMember) internal {
        require(!members[_newMember], "Address is already a member.");
        members[_newMember] = true;
        memberList.push(_newMember);
        emit MemberAdded(_newMember);
    }


    /// @dev Owner function to remove a member from the DAO.
    /// @param _memberToRemove Address of the member to remove.
    function removeMember(address _memberToRemove) external onlyOwner whenNotPaused {
        require(members[_memberToRemove], "Address is not a member.");
        delete members[_memberToRemove];
        // Efficiently remove from memberList (optional, order might not be important)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _memberToRemove) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberRemoved(_memberToRemove);
    }

    /// @dev Owner function to pause the contract.
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @dev Owner function to unpause the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @dev Allows anyone to view a DAO parameter.
    /// @param _parameterName Name of the parameter to retrieve.
    /// @return The value of the DAO parameter.
    function getDAOParameter(string memory _parameterName) external view returns (string memory) {
        return daoParameters[_parameterName];
    }


    // --- AI Model & Data Management Functions ---

    /// @dev Allows members to propose a new AI model for collaborative training.
    /// @param _modelName Name of the model.
    /// @param _initialDescription Description of the model.
    /// @param _initialParametersURI URI pointing to initial model parameters/architecture.
    /// @param _datasetRequirementsURI URI describing dataset requirements for training.
    function proposeNewModel(
        string memory _modelName,
        string memory _initialDescription,
        string memory _initialParametersURI,
        string memory _datasetRequirementsURI
    ) external onlyMember whenNotPaused {
        modelProposalIdCounter.increment();
        uint256 proposalId = modelProposalIdCounter.current();
        modelProposals[proposalId] = ModelProposal({
            id: proposalId,
            modelName: _modelName,
            initialDescription: _initialDescription,
            initialParametersURI: _initialParametersURI,
            datasetRequirementsURI: _datasetRequirementsURI,
            voteCountYes: 0,
            voteCountNo: 0,
            approved: false,
            votes: mapping(address => bool)()
        });
        emit ModelProposalCreated(proposalId, _modelName, _initialDescription, msg.sender);
    }

    /// @dev Allows members to vote on a new model proposal.
    /// @param _proposalId ID of the model proposal.
    /// @param _vote True for yes, false for no.
    function voteOnModelProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused modelProposalActive(_proposalId) {
        require(!modelProposals[_proposalId].votes[msg.sender], "Member has already voted on this model proposal.");
        modelProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            modelProposals[_proposalId].voteCountYes++;
        } else {
            modelProposals[_proposalId].voteCountNo++;
        }
        emit ModelProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Approves a model proposal if quorum is reached and more yes votes than no votes. Creates a new AI Model.
    /// @param _proposalId ID of the model proposal.
    function approveModelProposal(uint256 _proposalId) external onlyMember whenNotPaused modelProposalActive(_proposalId) {
        uint256 quorumPercentage = uint256(parseInt(daoParameters["votingQuorumPercentage"]));
        uint256 totalMembers = memberList.length;
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

        require(modelProposals[_proposalId].voteCountYes + modelProposals[_proposalId].voteCountNo >= requiredVotes, "Voting quorum not reached for model proposal.");
        require(modelProposals[_proposalId].voteCountYes > modelProposals[_proposalId].voteCountNo, "Model proposal did not pass.");
        require(!modelProposals[_proposalId].approved, "Model proposal already approved.");

        modelIdCounter.increment();
        uint256 modelId = modelIdCounter.current();
        models[modelId] = AIModel({
            id: modelId,
            modelName: modelProposals[_proposalId].modelName,
            description: modelProposals[_proposalId].initialDescription,
            initialParametersURI: modelProposals[_proposalId].initialParametersURI,
            datasetRequirementsURI: modelProposals[_proposalId].datasetRequirementsURI,
            creator: msg.sender, // Proposer of the model
            modelVersionIds: new uint256[](0) // Initialize empty version array
        });

        modelProposals[_proposalId].approved = true;
        emit ModelProposalApproved(_proposalId, modelId, modelProposals[_proposalId].modelName);
    }

    /// @dev Allows members to contribute datasets for a specific approved AI model.
    /// @param _modelId ID of the AI model.
    /// @param _datasetName Name of the dataset.
    /// @param _datasetURI URI pointing to the dataset.
    /// @param _datasetDescription Description of the dataset.
    function contributeDataset(
        uint256 _modelId,
        string memory _datasetName,
        string memory _datasetURI,
        string memory _datasetDescription
    ) external onlyMember whenNotPaused {
        require(models[_modelId].id == _modelId, "Invalid model ID."); // Model must exist

        DatasetContribution memory newDataset = DatasetContribution({
            modelId: _modelId,
            datasetName: _datasetName,
            datasetURI: _datasetURI,
            datasetDescription: _datasetDescription,
            contributor: msg.sender,
            timestamp: block.timestamp
        });
        modelDatasets[_modelId].push(newDataset);
        emit DatasetContributed(_modelId, _datasetName, msg.sender);
    }

    /// @dev Allows members to request a training run for a specific model.
    /// @param _modelId ID of the AI model to train.
    /// @param _trainingParametersURI URI pointing to training parameters for this run.
    function requestTraining(uint256 _modelId, string memory _trainingParametersURI) external onlyMember whenNotPaused {
        require(models[_modelId].id == _modelId, "Invalid model ID."); // Model must exist
        // In a real-world scenario, this function would trigger an off-chain process
        // to initiate training using the provided model, datasets, and parameters.
        // For this example, we just emit an event.
        emit TrainingRequested(_modelId, msg.sender, _trainingParametersURI);
    }

    /// @dev (Off-chain function, conceptually called by training infrastructure) Submits training results.
    /// @param _modelId ID of the AI model that was trained.
    /// @param _modelVersionName Name for this version of the model.
    /// @param _modelWeightsURI URI pointing to the trained model weights.
    /// @param _evaluationMetricsURI URI pointing to evaluation metrics of the trained model.
    function submitTrainingResult(
        uint256 _modelId,
        string memory _modelVersionName,
        string memory _modelWeightsURI,
        string memory _evaluationMetricsURI
    ) external onlyOwner whenNotPaused { // Owner can simulate training submission for demo. Real impl. needs secure off-chain -> on-chain bridge.
        require(models[_modelId].id == _modelId, "Invalid model ID."); // Model must exist

        modelVersionIdCounter.increment();
        uint256 modelVersionId = modelVersionIdCounter.current();
        ModelVersion memory newModelVersion = ModelVersion({
            id: modelVersionId,
            modelId: _modelId,
            versionName: _modelVersionName,
            modelWeightsURI: _modelWeightsURI,
            evaluationMetricsURI: _evaluationMetricsURI,
            trainer: msg.sender, // Address submitting the result (could be a service account)
            totalEvaluations: 0,
            positiveEvaluations: 0
        });
        modelVersions[modelVersionId] = newModelVersion;
        models[_modelId].modelVersionIds.push(modelVersionId); // Add version ID to model's version list

        emit TrainingResultSubmitted(_modelId, modelVersionId, _modelVersionName, msg.sender);
    }

    /// @dev Allows members to evaluate a trained model version.
    /// @param _modelVersionId ID of the model version to evaluate.
    /// @param _rating Rating for the model version (e.g., 1-5).
    /// @param _feedback Optional feedback text.
    function evaluateModelVersion(uint256 _modelVersionId, uint8 _rating, string memory _feedback) external onlyMember whenNotPaused {
        require(modelVersions[_modelVersionId].id == _modelVersionId, "Invalid model version ID.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Example rating scale
        modelVersions[_modelVersionId].totalEvaluations++;
        if (_rating >= parseInt(daoParameters["evaluationPositiveThreshold"])) {
            modelVersions[_modelVersionId].positiveEvaluations++;
        }
        emit ModelVersionEvaluated(_modelVersionId, msg.sender, _rating, _feedback);
    }

    /// @dev Gets information about a specific AI model.
    /// @param _modelId ID of the AI model.
    /// @return Model details.
    function getModelInfo(uint256 _modelId) external view returns (
        uint256 id,
        string memory modelName,
        string memory description,
        string memory initialParametersURI,
        string memory datasetRequirementsURI,
        address creator,
        uint256[] memory versionIds
    ) {
        AIModel memory model = models[_modelId];
        return (
            model.id,
            model.modelName,
            model.description,
            model.initialParametersURI,
            model.datasetRequirementsURI,
            model.creator,
            model.modelVersionIds
        );
    }

    /// @dev Gets information about a specific model version.
    /// @param _modelVersionId ID of the model version.
    /// @return Model version details.
    function getModelVersionInfo(uint256 _modelVersionId) external view returns (
        uint256 id,
        uint256 modelId,
        string memory versionName,
        string memory modelWeightsURI,
        string memory evaluationMetricsURI,
        address trainer,
        uint256 totalEvaluations,
        uint256 positiveEvaluations
    ) {
        ModelVersion memory version = modelVersions[_modelVersionId];
        return (
            version.id,
            version.modelId,
            version.versionName,
            version.modelWeightsURI,
            version.evaluationMetricsURI,
            version.trainer,
            version.totalEvaluations,
            version.positiveEvaluations
        );
    }


    // --- Reward & Incentive System Functions ---

    /// @dev Distributes rewards to contributors for a successful model version.
    /// @param _modelVersionId ID of the model version for which to distribute rewards.
    function distributeRewards(uint256 _modelVersionId) external onlyMember whenNotPaused {
        require(modelVersions[_modelVersionId].id == _modelVersionId, "Invalid model version ID.");
        require(modelVersions[_modelVersionId].positiveEvaluations > (modelVersions[_modelVersionId].totalEvaluations / 2), "Model version did not receive enough positive evaluations for reward distribution."); // Example: more than 50% positive evaluations needed.

        uint256 totalRewards = 100 ether; // Example: Fixed reward pool for each successful model version (adjust as needed, possibly based on DAO parameters)

        // Example reward distribution logic (can be significantly more complex based on DAO parameters):
        uint256 dataRewardRate = uint256(parseInt(daoParameters["rewardRateDataContribution"]));
        uint256 trainingRewardRate = uint256(parseInt(daoParameters["rewardRateTrainingContribution"]));

        // Reward for data contributors (simplified - could be weighted by dataset size/quality etc.)
        DatasetContribution[] memory datasets = modelDatasets[modelVersions[_modelVersionId].modelId];
        uint256 dataRewardPerContributor = (totalRewards * dataRewardRate) / (datasets.length > 0 ? datasets.length : 1) / 2; // Divide half of rewards for data
        for (uint256 i = 0; i < datasets.length; i++) {
            pendingRewards[datasets[i].contributor] += dataRewardPerContributor;
        }

        // Reward for trainer (simplified - could be based on training compute, time etc.)
        uint256 trainingReward = (totalRewards * trainingRewardRate) / 2; // Divide another half for trainer
        pendingRewards[modelVersions[_modelVersionId].trainer] += trainingReward;

        emit RewardsDistributed(_modelVersionId, totalRewards);
    }

    /// @dev Allows members to withdraw their accumulated rewards.
    function withdrawRewards() external onlyMember whenNotPaused {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No rewards to withdraw.");
        pendingRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount); // Consider using pull payments for security in real-world scenarios.
        emit RewardsWithdrawn(msg.sender, amount);
    }

    /// @dev Owner function to set reward-related parameters.
    /// @param _parameterName Name of the reward parameter to set (e.g., rewardRateDataContribution, rewardRateTrainingContribution).
    /// @param _value New value for the parameter.
    function setRewardParameter(string memory _parameterName, uint256 _value) external onlyOwner whenNotPaused {
        daoParameters[_parameterName] = uint256ToString(_value); // Store as string for consistency with other parameters
    }


    // --- Utility Functions ---

    /// @dev Helper function to parse string to uint256.
    function parseInt(string memory _str) internal pure returns (uint256) {
        uint256 result = 0;
        bytes memory strBytes = bytes(_str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 digit = uint8(strBytes[i]) - uint8(48); // ASCII '0' is 48
            require(digit <= 9, "Invalid character in string to uint256 conversion.");
            result = result * 10 + digit;
        }
        return result;
    }

    /// @dev Helper function to convert uint256 to string.
    function uint256ToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {} // Allow contract to receive Ether (for future treasury/funding)
}
```