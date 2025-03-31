```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Bard (Example Smart Contract - Educational Purposes Only)
 *
 * @dev This contract outlines a DAO designed for collaborative AI model training.
 * It incorporates advanced concepts like on-chain governance of AI model development,
 * decentralized data contribution with NFTs, compute resource pooling, and dynamic reward mechanisms.
 *
 * Function Summary:
 *
 * 1.  initializeDAO(string _daoName, address[] _initialMembers, uint256 _votingPeriod, uint256 _quorumPercentage):
 *     Initializes the DAO with a name, initial members, voting period, and quorum percentage. Only callable once by the contract deployer.
 *
 * 2.  proposeNewModel(string _modelName, string _modelDescription, string _initialDataRequirements):
 *     Allows DAO members to propose new AI model training projects.
 *
 * 3.  voteOnProposal(uint256 _proposalId, bool _support):
 *     Allows DAO members to vote on active proposals.
 *
 * 4.  executeProposal(uint256 _proposalId):
 *     Executes a passed proposal, transitioning the model project to 'Active' state.
 *
 * 5.  contributeData(uint256 _modelId, string _dataDescription, string _dataHash):
 *     Allows members to contribute data to an active model project, minting a Data NFT in return.
 *
 * 6.  getContributedDataNFT(uint256 _modelId, address _contributorAddress):
 *     Retrieves the Data NFT ID for a specific contributor and model.
 *
 * 7.  stakeComputeResources(uint256 _modelId, uint256 _computeUnits, uint256 _durationInBlocks):
 *     Members can stake compute resources for a specific model project and duration.
 *
 * 8.  unStakeComputeResources(uint256 _stakeId):
 *     Allows members to unstake their compute resources after the duration.
 *
 * 9.  reportTrainingProgress(uint256 _modelId, string _progressReport, string _metrics):
 *     Designated trainers (initially DAO members, can be governed later) can report training progress.
 *
 * 10. evaluateModelPerformance(uint256 _modelId, string _evaluationReport, string _finalMetrics):
 *     Allows designated evaluators to submit model performance evaluations.
 *
 * 11. rewardDataContributors(uint256 _modelId):
 *     Distributes rewards to data contributors of a successfully trained model, based on pre-defined reward mechanism (example: equal split).
 *
 * 12. rewardComputeProviders(uint256 _modelId):
 *     Distributes rewards to compute providers of a successfully trained model, proportional to their staked compute and duration.
 *
 * 13. finalizeModelTraining(uint256 _modelId):
 *     Finalizes the training process for a model after successful evaluation and distributes rewards.
 *
 * 14. getModelDetails(uint256 _modelId):
 *     Retrieves detailed information about a specific AI model project.
 *
 * 15. getProposalDetails(uint256 _proposalId):
 *     Retrieves details about a specific governance proposal.
 *
 * 16. addDAOMember(address _newMember):
 *     Allows DAO governance to add new members (governance function).
 *
 * 17. removeDAOMember(address _memberToRemove):
 *     Allows DAO governance to remove members (governance function).
 *
 * 18. updateVotingPeriod(uint256 _newVotingPeriod):
 *     Allows DAO governance to update the voting period (governance function).
 *
 * 19. updateQuorumPercentage(uint256 _newQuorumPercentage):
 *     Allows DAO governance to update the quorum percentage (governance function).
 *
 * 20. withdrawContractBalance():
 *     Allows the contract owner (or designated governance role) to withdraw any accumulated contract balance (e.g., for operational costs).
 *
 * 21. getDAOName():
 *     Returns the name of the DAO.
 *
 * 22. getDAOMembers():
 *     Returns the list of current DAO members.
 *
 * 23. getActiveProposals():
 *     Returns a list of IDs of currently active proposals.
 *
 * 24. getCompletedModels():
 *     Returns a list of IDs of models that have completed the training process.
 */

contract AIDaoCollaborativeTraining {
    string public daoName;
    address public daoOwner;
    address[] public daoMembers;
    uint256 public votingPeriod; // In blocks
    uint256 public quorumPercentage; // Percentage of members needed to reach quorum

    uint256 public proposalCounter;
    uint256 public modelCounter;
    uint256 public stakeCounter;
    uint256 public dataNFTCounter;

    struct Proposal {
        string proposalName;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => address[]) public proposalVoters;

    enum ModelStatus { Proposed, Active, Training, Evaluated, Completed, Failed }
    struct AIModel {
        string modelName;
        string description;
        string initialDataRequirements;
        ModelStatus status;
        uint256 proposalId; // Proposal ID that initiated this model
        address[] dataContributors;
        mapping(address => uint256) dataContributorToNFTId; // Mapping contributor address to their Data NFT ID for this model
        address[] computeProviders;
        mapping(address => uint256) computeProviderToStakeId; // Mapping provider address to their Stake ID for this model
        string trainingProgressReports;
        string evaluationReports;
        string finalMetrics;
    }
    mapping(uint256 => AIModel) public aiModels;

    struct ComputeStake {
        uint256 modelId;
        address staker;
        uint256 computeUnits;
        uint256 stakeStartTime;
        uint256 stakeEndTime;
        bool unstaked;
    }
    mapping(uint256 => ComputeStake) public computeStakes;

    struct DataNFT {
        uint256 modelId;
        address contributor;
        string dataDescription;
        string dataHash;
        uint256 mintTime;
    }
    mapping(uint256 => DataNFT) public dataNFTs;

    event DAOInitialized(string daoName, address daoOwner);
    event MemberAdded(address memberAddress);
    event MemberRemoved(address memberAddress);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);

    event ProposalCreated(uint256 proposalId, string proposalName, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    event ModelProposed(uint256 modelId, string modelName, uint256 proposalId);
    event DataContributed(uint256 modelId, address contributor, uint256 dataNFTId);
    event ComputeResourcesStaked(uint256 stakeId, uint256 modelId, address staker, uint256 computeUnits, uint256 duration);
    event ComputeResourcesUnstaked(uint256 stakeId);
    event TrainingProgressReported(uint256 modelId, string report, string metrics);
    event ModelEvaluated(uint256 modelId, string report, string metrics);
    event ModelTrainingFinalized(uint256 modelId);
    event RewardsDistributed(uint256 modelId);
    event ContractBalanceWithdrawn(address recipient, uint256 amount);

    modifier onlyDAOMember() {
        bool isMember = false;
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Only DAO members can perform this action.");
        _;
    }

    modifier onlyDAOOwner() {
        require(msg.sender == daoOwner, "Only DAO owner can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCounter && proposals[_proposalId].startTime != 0, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.number >= proposals[_proposalId].startTime && block.number <= proposals[_proposalId].endTime, "Proposal is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(_modelId < modelCounter && aiModels[_modelId].status != ModelStatus.Proposed, "Model does not exist.");
        _;
    }

    modifier modelInStatus(uint256 _modelId, ModelStatus _status) {
        require(aiModels[_modelId].status == _status, "Model is not in the required status.");
        _;
    }

    modifier stakeExists(uint256 _stakeId) {
        require(_stakeId < stakeCounter && computeStakes[_stakeId].stakeStartTime != 0, "Stake does not exist.");
        _;
    }

    modifier stakeNotUnstaked(uint256 _stakeId) {
        require(!computeStakes[_stakeId].unstaked, "Stake already unstaked.");
        _;
    }

    modifier stakeDurationElapsed(uint256 _stakeId) {
        require(block.number >= computeStakes[_stakeId].stakeEndTime, "Stake duration not elapsed yet.");
        _;
    }

    bool private daoInitialized = false;

    constructor() {
        daoOwner = msg.sender;
    }

    function initializeDAO(string memory _daoName, address[] memory _initialMembers, uint256 _votingPeriod, uint256 _quorumPercentage) public onlyDAOOwner {
        require(!daoInitialized, "DAO already initialized.");
        daoName = _daoName;
        daoMembers = _initialMembers;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        daoInitialized = true;
        emit DAOInitialized(_daoName, daoOwner);
        for (uint256 i = 0; i < _initialMembers.length; i++) {
            emit MemberAdded(_initialMembers[i]);
        }
    }

    function proposeNewModel(string memory _modelName, string memory _modelDescription, string memory _initialDataRequirements) public onlyDAOMember {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalName: string(abi.encodePacked("Propose Model: ", _modelName)),
            description: string(abi.encodePacked(_modelDescription, " - Initial Data Requirements: ", _initialDataRequirements)),
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCounter, proposals[proposalCounter].proposalName, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyDAOMember proposalExists(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        bool alreadyVoted = false;
        for (uint256 i = 0; i < proposalVoters[_proposalId].length; i++) {
            if (proposalVoters[_proposalId][i] == msg.sender) {
                alreadyVoted = true;
                break;
            }
        }
        require(!alreadyVoted, "Member has already voted on this proposal.");

        proposalVoters[_proposalId].push(msg.sender);
        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public proposalExists(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        uint256 quorum = (daoMembers.length * quorumPercentage) / 100;
        require(proposalVoters[_proposalId].length >= quorum, "Quorum not reached.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal failed to pass.");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);

        if (string.startsWith(proposals[_proposalId].proposalName, "Propose Model: ")) {
            modelCounter++;
            string memory modelName = substringAfter(proposals[_proposalId].proposalName, "Propose Model: ");
            string memory modelDescription = proposals[_proposalId].description;
            string memory initialDataReq = substringAfter(modelDescription, " - Initial Data Requirements: ");
            aiModels[modelCounter] = AIModel({
                modelName: modelName,
                description: substringBefore(modelDescription, " - Initial Data Requirements: "),
                initialDataRequirements: initialDataReq,
                status: ModelStatus.Active, // Initially Active after proposal passes
                proposalId: _proposalId,
                dataContributors: new address[](0),
                computeProviders: new address[](0),
                trainingProgressReports: "",
                evaluationReports: "",
                finalMetrics: "",
                dataContributorToNFTId: mapping(address => uint256)(),
                computeProviderToStakeId: mapping(address => uint256)()
            });
            emit ModelProposed(modelCounter, modelName, _proposalId);
        } else if (string.startsWith(proposals[_proposalId].proposalName, "Add Member: ")) {
            address newMember = stringToAddress(substringAfter(proposals[_proposalId].proposalName, "Add Member: "));
            addDAOMemberInternal(newMember);
        } else if (string.startsWith(proposals[_proposalId].proposalName, "Remove Member: ")) {
            address memberToRemove = stringToAddress(substringAfter(proposals[_proposalId].proposalName, "Remove Member: "));
            removeDAOMemberInternal(memberToRemove);
        } else if (string.startsWith(proposals[_proposalId].proposalName, "Update Voting Period: ")) {
            uint256 newPeriod = stringToUint(substringAfter(proposals[_proposalId].proposalName, "Update Voting Period: "));
            updateVotingPeriodInternal(newPeriod);
        } else if (string.startsWith(proposals[_proposalId].proposalName, "Update Quorum Percentage: ")) {
            uint256 newQuorum = stringToUint(substringAfter(proposals[_proposalId].proposalName, "Update Quorum Percentage: "));
            updateQuorumPercentageInternal(newQuorum);
        }
        // Add more proposal execution logic here for other proposal types as needed
    }

    function contributeData(uint256 _modelId, string memory _dataDescription, string memory _dataHash) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Active) {
        require(aiModels[_modelId].dataContributorToNFTId[msg.sender] == 0, "Member has already contributed data to this model.");

        dataNFTCounter++;
        dataNFTs[dataNFTCounter] = DataNFT({
            modelId: _modelId,
            contributor: msg.sender,
            dataDescription: _dataDescription,
            dataHash: _dataHash,
            mintTime: block.number
        });
        aiModels[_modelId].dataContributors.push(msg.sender);
        aiModels[_modelId].dataContributorToNFTId[msg.sender] = dataNFTCounter;
        emit DataContributed(_modelId, msg.sender, dataNFTCounter);
    }

    function getContributedDataNFT(uint256 _modelId, address _contributorAddress) public view modelExists(_modelId) returns (uint256) {
        return aiModels[_modelId].dataContributorToNFTId[_contributorAddress];
    }

    function stakeComputeResources(uint256 _modelId, uint256 _computeUnits, uint256 _durationInBlocks) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Active) {
        stakeCounter++;
        computeStakes[stakeCounter] = ComputeStake({
            modelId: _modelId,
            staker: msg.sender,
            computeUnits: _computeUnits,
            stakeStartTime: block.number,
            stakeEndTime: block.number + _durationInBlocks,
            unstaked: false
        });
        aiModels[_modelId].computeProviders.push(msg.sender);
        aiModels[_modelId].computeProviderToStakeId[msg.sender] = stakeCounter;
        emit ComputeResourcesStaked(stakeCounter, _modelId, msg.sender, _computeUnits, _durationInBlocks);
    }

    function unStakeComputeResources(uint256 _stakeId) public onlyDAOMember stakeExists(_stakeId) stakeNotUnstaked(_stakeId) stakeDurationElapsed(_stakeId) {
        require(computeStakes[_stakeId].staker == msg.sender, "Only staker can unstake.");
        computeStakes[_stakeId].unstaked = true;
        emit ComputeResourcesUnstaked(_stakeId);
    }

    function reportTrainingProgress(uint256 _modelId, string memory _progressReport, string memory _metrics) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Active) {
        // In a real-world scenario, access control for reporting progress might be more granular (e.g., designated trainers)
        aiModels[_modelId].trainingProgressReports = string(abi.encodePacked(aiModels[_modelId].trainingProgressReports, "\n", block.timestamp, " - ", msg.sender, ": ", _progressReport, " Metrics: ", _metrics));
        aiModels[_modelId].status = ModelStatus.Training;
        emit TrainingProgressReported(_modelId, _progressReport, _metrics);
    }

    function evaluateModelPerformance(uint256 _modelId, string memory _evaluationReport, string memory _finalMetrics) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Training) {
        // In a real-world scenario, access control for evaluation might be more granular (e.g., designated evaluators)
        aiModels[_modelId].evaluationReports = string(abi.encodePacked(aiModels[_modelId].evaluationReports, "\n", block.timestamp, " - ", msg.sender, ": ", _evaluationReport, " Final Metrics: ", _finalMetrics));
        aiModels[_modelId].finalMetrics = _finalMetrics;
        aiModels[_modelId].status = ModelStatus.Evaluated;
        emit ModelEvaluated(_modelId, _evaluationReport, _finalMetrics);
    }

    function rewardDataContributors(uint256 _modelId) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Evaluated) {
        // Example reward mechanism: Equal split of contract balance among data contributors
        uint256 rewardPerContributor = address(this).balance / aiModels[_modelId].dataContributors.length;
        for (uint256 i = 0; i < aiModels[_modelId].dataContributors.length; i++) {
            payable(aiModels[_modelId].dataContributors[i]).transfer(rewardPerContributor);
        }
        emit RewardsDistributed(_modelId);
    }

    function rewardComputeProviders(uint256 _modelId) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Evaluated) {
        // Example reward mechanism: Proportional to compute units and duration
        uint256 totalComputeUnitsDuration = 0;
        for (uint256 i = 0; i < aiModels[_modelId].computeProviders.length; i++) {
            uint256 stakeId = aiModels[_modelId].computeProviderToStakeId[aiModels[_modelId].computeProviders[i]];
            totalComputeUnitsDuration += computeStakes[stakeId].computeUnits * (computeStakes[stakeId].stakeEndTime - computeStakes[stakeId].stakeStartTime);
        }

        for (uint256 i = 0; i < aiModels[_modelId].computeProviders.length; i++) {
            uint256 stakeId = aiModels[_modelId].computeProviderToStakeId[aiModels[_modelId].computeProviders[i]];
            uint256 providerComputeUnitsDuration = computeStakes[stakeId].computeUnits * (computeStakes[stakeId].stakeEndTime - computeStakes[stakeId].stakeStartTime);
            uint256 rewardAmount = (address(this).balance * providerComputeUnitsDuration) / totalComputeUnitsDuration; // Proportional reward
            payable(aiModels[_modelId].computeProviders[i]).transfer(rewardAmount);
        }
        emit RewardsDistributed(_modelId);
    }

    function finalizeModelTraining(uint256 _modelId) public onlyDAOMember modelExists(_modelId) modelInStatus(_modelId, ModelStatus.Evaluated) {
        // Example: After evaluation and reward distribution, mark model as completed.
        aiModels[_modelId].status = ModelStatus.Completed;
        emit ModelTrainingFinalized(_modelId);
    }

    function getModelDetails(uint256 _modelId) public view modelExists(_modelId) returns (AIModel memory) {
        return aiModels[_modelId];
    }

    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // --- Governance Functions ---

    function addDAOMember(address _newMember) public onlyDAOMember {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalName: string(abi.encodePacked("Add Member: ", addressToString(_newMember))),
            description: string(abi.encodePacked("Proposal to add new DAO member: ", addressToString(_newMember))),
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCounter, proposals[proposalCounter].proposalName, msg.sender);
    }

    function addDAOMemberInternal(address _newMember) private {
        bool isAlreadyMember = false;
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == _newMember) {
                isAlreadyMember = true;
                break;
            }
        }
        require(!isAlreadyMember, "Address is already a DAO member.");
        daoMembers.push(_newMember);
        emit MemberAdded(_newMember);
    }


    function removeDAOMember(address _memberToRemove) public onlyDAOMember {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalName: string(abi.encodePacked("Remove Member: ", addressToString(_memberToRemove))),
            description: string(abi.encodePacked("Proposal to remove DAO member: ", addressToString(_memberToRemove))),
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCounter, proposals[proposalCounter].proposalName, msg.sender);
    }

    function removeDAOMemberInternal(address _memberToRemove) private {
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == _memberToRemove) {
                // Remove member by swapping with the last element and popping
                daoMembers[i] = daoMembers[daoMembers.length - 1];
                daoMembers.pop();
                emit MemberRemoved(_memberToRemove);
                return;
            }
        }
        require(false, "Member address not found in DAO members.");
    }

    function updateVotingPeriod(uint256 _newVotingPeriod) public onlyDAOMember {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalName: string(abi.encodePacked("Update Voting Period: ", uintToString(_newVotingPeriod))),
            description: string(abi.encodePacked("Proposal to update voting period to ", uintToString(_newVotingPeriod), " blocks.")),
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriod, // Use current voting period for proposal duration
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCounter, proposals[proposalCounter].proposalName, msg.sender);
    }

    function updateVotingPeriodInternal(uint256 _newVotingPeriod) private {
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodUpdated(_newVotingPeriod);
    }

    function updateQuorumPercentage(uint256 _newQuorumPercentage) public onlyDAOMember {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be less than or equal to 100.");
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalName: string(abi.encodePacked("Update Quorum Percentage: ", uintToString(_newQuorumPercentage))),
            description: string(abi.encodePacked("Proposal to update quorum percentage to ", uintToString(_newQuorumPercentage), "%.")),
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCounter, proposals[proposalCounter].proposalName, msg.sender);
    }

    function updateQuorumPercentageInternal(uint256 _newQuorumPercentage) private {
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageUpdated(_newQuorumPercentage);
    }

    function withdrawContractBalance() public onlyDAOOwner {
        uint256 balance = address(this).balance;
        payable(daoOwner).transfer(balance);
        emit ContractBalanceWithdrawn(daoOwner, balance);
    }

    // --- Utility/Getter Functions ---

    function getDAOName() public view returns (string memory) {
        return daoName;
    }

    function getDAOMembers() public view returns (address[] memory) {
        return daoMembers;
    }

    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (block.number >= proposals[i].startTime && block.number <= proposals[i].endTime && !proposals[i].executed) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize array to the actual number of active proposals
        assembly {
            mstore(activeProposalIds, count) // Update array length
        }
        return activeProposalIds;
    }

    function getCompletedModels() public view returns (uint256[] memory) {
        uint256[] memory completedModelIds = new uint256[](modelCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= modelCounter; i++) {
            if (aiModels[i].status == ModelStatus.Completed) {
                completedModelIds[count] = i;
                count++;
            }
        }
         // Resize array to the actual number of completed models
        assembly {
            mstore(completedModelIds, count) // Update array length
        }
        return completedModelIds;
    }


    // --- Internal Helper Functions ---

    function stringToAddress(string memory _str) internal pure returns (address) {
        bytes memory bytesValue = bytes(_str);
        require(bytesValue.length == 42, "Invalid address string length."); // 42 bytes for hex address with 0x prefix
        address addr;
        assembly {
            addr := mload(add(bytesValue, 21)) // Load address from bytes (skip "0x" prefix, 20 bytes offset)
        }
        return addr;
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes memory strBytes = new bytes(40); // Address string length is 40 hex characters (without 0x)
        uint256 tempAddr = uint256(_addr);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 byteValue = bytes1(uint8(tempAddr & 0xff));
            uint8 highNibble = uint8(byteValue) >> 4;
            uint8 lowNibble = uint8(byteValue) & 0x0f;

            strBytes[39 - (2 * i + 1)] = nibbleToHex(highNibble);
            strBytes[39 - (2 * i)]     = nibbleToHex(lowNibble);

            tempAddr = tempAddr >> 8;
        }
        return string(abi.encodePacked("0x", string(strBytes)));
    }

    function nibbleToHex(uint8 _nibble) internal pure returns (bytes1) {
        if (_nibble < 10) {
            return bytes1(uint8(48 + _nibble)); // 0-9 are ASCII 48-57
        } else {
            return bytes1(uint8(87 + _nibble)); // a-f are ASCII 97-102, but we want lower case hex, so 87 instead of 97
        }
    }

    function uintToString(uint256 _i) internal pure returns (string memory) {
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
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8(48 + (_i % 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function substringBefore(string memory str, string memory delimiter) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);
        uint len = strBytes.length;
        uint delimLen = delimiterBytes.length;

        if (delimLen == 0) {
            return str; // If delimiter is empty, return the original string
        }

        for (uint i = 0; i <= len - delimLen; i++) {
            bool match = true;
            for (uint j = 0; j < delimLen; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                bytes memory result = new bytes(i);
                for (uint k = 0; k < i; k++) {
                    result[k] = strBytes[k];
                }
                return string(result);
            }
        }
        return str; // Delimiter not found, return the original string
    }


    function substringAfter(string memory str, string memory delimiter) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);
        uint len = strBytes.length;
        uint delimLen = delimiterBytes.length;

        if (delimLen == 0) {
            return str; // If delimiter is empty, return the original string
        }

        for (uint i = 0; i <= len - delimLen; i++) {
            bool match = true;
            for (uint j = 0; j < delimLen; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                bytes memory result = new bytes(len - (i + delimLen));
                for (uint k = 0; k < result.length; k++) {
                    result[k] = strBytes[i + delimLen + k];
                }
                return string(result);
            }
        }
        return ""; // Delimiter not found, return an empty string
    }
}
```