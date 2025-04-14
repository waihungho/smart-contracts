```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a DAO for collaborative AI model training.
 *
 * **Outline & Function Summary:**
 *
 * **1. DAO Initialization & Governance Setup:**
 *   - `initializeDAO(string _daoName, string _tokenName, string _tokenSymbol, uint256 _initialSupply, address[] _initialMembers)`: Initializes the DAO with basic information, token, and initial members.
 *   - `setGovernanceParameters(uint256 _quorumPercentage, uint256 _votingDuration)`: Allows DAO owner to set governance parameters like quorum and voting duration.
 *   - `transferDAOwnership(address _newOwner)`: Transfers DAO ownership to a new address.
 *   - `addMember(address _member)`: Allows DAO owner to add new members to the DAO.
 *   - `removeMember(address _member)`: Allows DAO owner to remove members from the DAO.
 *
 * **2. Data Contribution & Management:**
 *   - `contributeData(string _datasetCID, string _dataType)`: Allows members to contribute datasets (represented by CID) with associated data type.
 *   - `getDataContributionCount(address _member)`: Returns the number of datasets contributed by a member.
 *   - `getDataContributionByIndex(address _member, uint256 _index)`: Returns the details of a specific dataset contribution of a member.
 *   - `setDataContributionReward(string _datasetCID, uint256 _rewardAmount)`: Allows DAO owner to set reward for specific datasets.
 *   - `claimDataContributionReward(string _datasetCID)`: Allows members to claim rewards for their data contributions.
 *
 * **3. Model Training Proposal & Execution:**
 *   - `proposeTrainingRun(string _modelType, string _trainingParametersCID, string[] _datasetCIDs)`: Allows members to propose a new AI model training run with parameters and datasets.
 *   - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on active training proposals.
 *   - `executeTrainingRun(uint256 _proposalId)`: Executes a training run if a proposal passes (DAO owner initiated). *Note: Actual training is off-chain, this function manages on-chain state.*
 *   - `getProposalDetails(uint256 _proposalId)`: Returns details of a specific training proposal.
 *   - `getProposalVoteCount(uint256 _proposalId)`: Returns vote counts for a specific proposal.
 *
 * **4. Model Evaluation & Reward Distribution:**
 *   - `submitModelEvaluation(uint256 _proposalId, string _evaluationMetricsCID)`: Allows members to submit evaluation metrics for a completed training run.
 *   - `voteOnEvaluation(uint256 _proposalId, uint256 _evaluationId, bool _vote)`: Allows members to vote on submitted model evaluations.
 *   - `distributeTrainingRewards(uint256 _proposalId)`: Distributes rewards to contributors based on successful training runs and potentially evaluation votes.
 *   - `claimTrainingReward(uint256 _proposalId)`: Allows members to claim their training rewards.
 *
 * **5. DAO Token & Utility Functions:**
 *   - `transferTokens(address _recipient, uint256 _amount)`: Allows members to transfer DAO tokens to other members.
 *   - `getTokenBalance(address _member)`: Returns the token balance of a DAO member.
 *   - `getDAOInfo()`: Returns basic information about the DAO (name, token, governance parameters).
 *   - `withdrawContractBalance(address _recipient)`: Allows DAO owner to withdraw any accumulated contract balance (e.g., from fees - if implemented).
 */
contract AIDaoContract {
    // --- State Variables ---

    string public daoName;
    string public tokenName;
    string public tokenSymbol;
    uint256 public totalSupply;
    address public daoOwner;

    mapping(address => bool) public isMember;
    address[] public members;
    mapping(address => uint256) public memberTokenBalance;

    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals
    uint256 public votingDuration = 7 days; // Default voting duration

    struct DataContribution {
        string datasetCID;
        string dataType;
        uint256 rewardAmount;
        bool rewardClaimed;
    }
    mapping(address => DataContribution[]) public memberDataContributions;
    mapping(string => address) public datasetContributor; // Track contributor for each dataset CID

    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    struct TrainingProposal {
        ProposalStatus status;
        string modelType;
        string trainingParametersCID;
        string[] datasetCIDs;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes; // Members who voted and their vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
    }
    TrainingProposal[] public trainingProposals;

    struct ModelEvaluation {
        string evaluationMetricsCID;
        address evaluator;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ModelEvaluation[]) public proposalEvaluations; // Proposal ID => Array of Evaluations

    mapping(uint256 => mapping(address => uint256)) public trainingRewards; // proposalId => member => rewardAmount
    mapping(uint256 => mapping(address => bool)) public rewardClaimed; // proposalId => member => claimed

    // --- Events ---
    event DAOOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event DataContributed(address indexed member, string datasetCID, string dataType);
    event DataContributionRewardSet(string datasetCID, uint256 rewardAmount);
    event DataContributionRewardClaimed(address indexed member, string datasetCID, uint256 rewardAmount);
    event TrainingProposalCreated(uint256 proposalId, string modelType, address proposer);
    event VoteCast(uint256 proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ModelEvaluationSubmitted(uint256 proposalId, uint256 evaluationId, address evaluator);
    event EvaluationVoteCast(uint256 proposalId, uint256 evaluationId, address voter, bool vote);
    event TrainingRewardsDistributed(uint256 proposalId);
    event TrainingRewardClaimed(uint256 proposalId, address indexed member, uint256 rewardAmount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);


    // --- Modifiers ---
    modifier onlyDAOOwner() {
        require(msg.sender == daoOwner, "Only DAO owner can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only DAO members can perform this action.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId < trainingProposals.length, "Invalid proposal ID.");
        _;
    }

    modifier onlyPendingOrActiveProposal(uint256 _proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Pending || trainingProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not pending or active.");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        _;
    }

    modifier proposalVotingNotEnded(uint256 _proposalId) {
        require(block.timestamp < trainingProposals[_proposalId].endTime, "Voting for this proposal has ended.");
        _;
    }

    modifier proposalVotingEnded(uint256 _proposalId) {
        require(block.timestamp >= trainingProposals[_proposalId].endTime, "Voting for this proposal has not ended yet.");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!trainingProposals[_proposalId].votes[msg.sender], "You have already voted on this proposal.");
        _;
    }


    // --- Functions ---

    // 1. DAO Initialization & Governance Setup

    constructor() payable {
        daoOwner = msg.sender; // Contract deployer is the initial DAO owner.
    }

    function initializeDAO(string memory _daoName, string memory _tokenName, string memory _tokenSymbol, uint256 _initialSupply, address[] memory _initialMembers) external onlyDAOOwner {
        require(bytes(daoName).length == 0, "DAO already initialized."); // Prevent re-initialization
        daoName = _daoName;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        totalSupply = _initialSupply;

        for (uint256 i = 0; i < _initialMembers.length; i++) {
            _addMember(_initialMembers[i]);
            _mintTokens(_initialMembers[i], _initialSupply / _initialMembers.length); // Distribute initial tokens evenly
        }
    }

    function setGovernanceParameters(uint256 _quorumPercentage, uint256 _votingDuration) external onlyDAOOwner {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _quorumPercentage;
        votingDuration = _votingDuration;
    }

    function transferDAOwnership(address _newOwner) external onlyDAOOwner {
        require(_newOwner != address(0), "New owner address cannot be zero.");
        emit DAOOwnershipTransferred(daoOwner, _newOwner);
        daoOwner = _newOwner;
    }

    function addMember(address _member) external onlyDAOOwner {
        _addMember(_member);
    }

    function _addMember(address _member) internal {
        require(_member != address(0), "Member address cannot be zero.");
        require(!isMember[_member], "Member already exists.");
        isMember[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyDAOOwner {
        require(isMember[_member], "Member does not exist.");
        isMember[_member] = false;
        // Option to remove from members array - but might affect indexing if order matters.
        emit MemberRemoved(_member);
    }


    // 2. Data Contribution & Management

    function contributeData(string memory _datasetCID, string memory _dataType) external onlyMember {
        require(bytes(_datasetCID).length > 0 && bytes(_dataType).length > 0, "Dataset CID and Data Type cannot be empty.");
        require(datasetContributor[_datasetCID] == address(0), "Dataset CID already contributed."); // Prevent duplicate contribution

        DataContribution memory contribution = DataContribution({
            datasetCID: _datasetCID,
            dataType: _dataType,
            rewardAmount: 0, // Initial reward is 0, DAO owner can set later
            rewardClaimed: false
        });
        memberDataContributions[msg.sender].push(contribution);
        datasetContributor[_datasetCID] = msg.sender; // Track who contributed this dataset
        emit DataContributed(msg.sender, _datasetCID, _dataType);
    }

    function getDataContributionCount(address _member) external view onlyMember returns (uint256) {
        return memberDataContributions[_member].length;
    }

    function getDataContributionByIndex(address _member, uint256 _index) external view onlyMember returns (string memory datasetCID, string memory dataType, uint256 rewardAmount, bool rewardClaimed) {
        require(_index < memberDataContributions[_member].length, "Invalid contribution index.");
        DataContribution storage contribution = memberDataContributions[_member][_index];
        return (contribution.datasetCID, contribution.dataType, contribution.rewardAmount, contribution.rewardClaimed);
    }

    function setDataContributionReward(string memory _datasetCID, uint256 _rewardAmount) external onlyDAOOwner {
        require(datasetContributor[_datasetCID] != address(0), "Dataset CID not contributed yet.");
        address contributor = datasetContributor[_datasetCID];
        for (uint256 i = 0; i < memberDataContributions[contributor].length; i++) {
            if (keccak256(bytes(memberDataContributions[contributor][i].datasetCID)) == keccak256(bytes(_datasetCID))) {
                memberDataContributions[contributor][i].rewardAmount = _rewardAmount;
                emit DataContributionRewardSet(_datasetCID, _rewardAmount);
                return;
            }
        }
        revert("Dataset CID not found in contributor's list."); // Should not happen if datasetContributor mapping is correct
    }

    function claimDataContributionReward(string memory _datasetCID) external onlyMember {
        address contributor = datasetContributor[_datasetCID];
        require(contributor == msg.sender, "Only contributor can claim reward.");

        for (uint256 i = 0; i < memberDataContributions[msg.sender].length; i++) {
            if (keccak256(bytes(memberDataContributions[msg.sender][i].datasetCID)) == keccak256(bytes(_datasetCID))) {
                DataContribution storage contribution = memberDataContributions[msg.sender][i];
                require(!contribution.rewardClaimed, "Reward already claimed for this dataset.");
                require(contribution.rewardAmount > 0, "No reward set for this dataset.");

                contribution.rewardClaimed = true;
                _transferTokens(address(this), msg.sender, contribution.rewardAmount); // Assuming contract holds tokens for rewards
                emit DataContributionRewardClaimed(msg.sender, _datasetCID, contribution.rewardAmount);
                return;
            }
        }
        revert("Dataset CID not found in your contributions."); // Should not happen if datasetContributor mapping is correct
    }


    // 3. Model Training Proposal & Execution

    function proposeTrainingRun(string memory _modelType, string memory _trainingParametersCID, string[] memory _datasetCIDs) external onlyMember {
        require(bytes(_modelType).length > 0 && bytes(_trainingParametersCID).length > 0 && _datasetCIDs.length > 0, "Model Type, Parameters CID, and Datasets cannot be empty.");

        TrainingProposal memory newProposal = TrainingProposal({
            status: ProposalStatus.Pending,
            modelType: _modelType,
            trainingParametersCID: _trainingParametersCID,
            datasetCIDs: _datasetCIDs,
            startTime: 0,
            endTime: 0,
            votes: mapping(address => bool)(),
            yesVotes: 0,
            noVotes: 0
        });
        trainingProposals.push(newProposal);
        uint256 proposalId = trainingProposals.length - 1;
        emit TrainingProposalCreated(proposalId, _modelType, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember validProposal(_proposalId) onlyActiveProposal(_proposalId) proposalVotingNotEnded(_proposalId) notVoted(_proposalId) {
        TrainingProposal storage proposal = trainingProposals[_proposalId];
        proposal.votes[msg.sender] = _vote;

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeTrainingRun(uint256 _proposalId) external onlyDAOOwner validProposal(_proposalId) onlyPendingOrActiveProposal(_proposalId) proposalVotingEnded(_proposalId) {
        TrainingProposal storage proposal = trainingProposals[_proposalId];

        require(proposal.status != ProposalStatus.Executed, "Proposal already executed.");

        uint256 totalMembers = members.length;
        uint256 quorumNeeded = (totalMembers * quorumPercentage) / 100;
        require(proposal.yesVotes >= quorumNeeded, "Proposal does not meet quorum.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal not approved (more no votes or tie).");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
        // Note: Actual training execution is assumed to be handled off-chain, triggered by this event.
        // This function primarily updates the proposal status on-chain.
    }

    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (ProposalStatus status, string memory modelType, string memory trainingParametersCID, string[] memory datasetCIDs, uint256 yesVotes, uint256 noVotes) {
        TrainingProposal storage proposal = trainingProposals[_proposalId];
        return (proposal.status, proposal.modelType, proposal.trainingParametersCID, proposal.datasetCIDs, proposal.yesVotes, proposal.noVotes);
    }

    function getProposalVoteCount(uint256 _proposalId) external view validProposal(_proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        TrainingProposal storage proposal = trainingProposals[_proposalId];
        return (proposal.yesVotes, proposal.noVotes);
    }


    function startProposalVoting(uint256 _proposalId) external onlyDAOOwner validProposal(_proposalId onlyPendingOrActiveProposal(_proposalId) {
        TrainingProposal storage proposal = trainingProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal voting already started or proposal not in pending state.");
        proposal.status = ProposalStatus.Active;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
    }


    // 4. Model Evaluation & Reward Distribution

    function submitModelEvaluation(uint256 _proposalId, string memory _evaluationMetricsCID) external onlyMember validProposal(_proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Executed, "Training run must be executed before evaluation.");
        require(bytes(_evaluationMetricsCID).length > 0, "Evaluation Metrics CID cannot be empty.");

        ModelEvaluation memory newEvaluation = ModelEvaluation({
            evaluationMetricsCID: _evaluationMetricsCID,
            evaluator: msg.sender,
            yesVotes: 0,
            noVotes: 0
        });
        proposalEvaluations[_proposalId].push(newEvaluation);
        uint256 evaluationId = proposalEvaluations[_proposalId].length - 1;
        emit ModelEvaluationSubmitted(_proposalId, evaluationId, msg.sender);
    }

    function voteOnEvaluation(uint256 _proposalId, uint256 _evaluationId, bool _vote) external onlyMember validProposal(_proposalId) {
        require(_evaluationId < proposalEvaluations[_proposalId].length, "Invalid evaluation ID.");
        require(proposalEvaluations[_proposalId][_evaluationId].evaluator != msg.sender, "Evaluator cannot vote on their own evaluation."); // Prevent self-voting on evaluations

        ModelEvaluation storage evaluation = proposalEvaluations[_proposalId][_evaluationId];
        if (_vote) {
            evaluation.yesVotes++;
        } else {
            evaluation.noVotes++;
        }
        emit EvaluationVoteCast(_proposalId, _evaluationId, msg.sender, _vote);
    }

    function distributeTrainingRewards(uint256 _proposalId) external onlyDAOOwner validProposal(_proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Executed, "Training run must be executed before reward distribution.");
        require(trainingRewards[_proposalId][msg.sender] == 0, "Rewards already distributed for this proposal."); // Basic check, more sophisticated logic might be needed

        uint256 totalRewardPool = 1000 * (trainingProposals[_proposalId].datasetCIDs.length); // Example reward logic - adjust as needed
        uint256 rewardPerContributor = totalRewardPool / members.length; // Example: Divide equally among members - can be based on contribution weight

        for (uint256 i = 0; i < members.length; i++) {
            trainingRewards[_proposalId][members[i]] = rewardPerContributor;
        }
        emit TrainingRewardsDistributed(_proposalId);
    }

    function claimTrainingReward(uint256 _proposalId) external onlyMember validProposal(_proposalId) {
        require(trainingRewards[_proposalId][msg.sender] > 0, "No reward available for this proposal.");
        require(!rewardClaimed[_proposalId][msg.sender], "Reward already claimed for this proposal.");

        uint256 rewardAmount = trainingRewards[_proposalId][msg.sender];
        rewardClaimed[_proposalId][msg.sender] = true;
        _transferTokens(address(this), msg.sender, rewardAmount);
        emit TrainingRewardClaimed(_proposalId, msg.sender, rewardAmount);
    }


    // 5. DAO Token & Utility Functions

    function transferTokens(address _recipient, uint256 _amount) external onlyMember {
        _transferTokens(msg.sender, _recipient, _amount);
    }

    function _transferTokens(address _sender, address _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(isMember[_recipient], "Recipient must be a DAO member."); // Optional: Restrict transfers to DAO members
        require(memberTokenBalance[_sender] >= _amount, "Insufficient token balance.");

        memberTokenBalance[_sender] -= _amount;
        memberTokenBalance[_recipient] += _amount;
        emit TokensTransferred(_sender, _recipient, _amount);
    }

    function _mintTokens(address _recipient, uint256 _amount) internal onlyDAOOwner { // Internal function for initial minting
        require(_recipient != address(0), "Recipient address cannot be zero.");
        totalSupply += _amount;
        memberTokenBalance[_recipient] += _amount;
        emit TokensTransferred(address(0), _recipient, _amount); // Mint event might be useful too
    }

    function getTokenBalance(address _member) external view onlyMember returns (uint256) {
        return memberTokenBalance[_member];
    }

    function getDAOInfo() external view returns (string memory name, string memory token, string memory symbol, uint256 quorum, uint256 voteDuration) {
        return (daoName, tokenName, tokenSymbol, quorumPercentage, votingDuration / 1 days); // Return duration in days for readability
    }

    function withdrawContractBalance(address _recipient) external onlyDAOOwner {
        uint256 balance = address(this).balance;
        payable(_recipient).transfer(balance);
    }

    receive() external payable {} // Allow contract to receive Ether (e.g., for fees or funding)
}
```