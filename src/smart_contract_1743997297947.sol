```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Bard (Example - Conceptual Smart Contract)
 * @notice This contract outlines a DAO designed for collaborative AI model training. It allows members to propose, vote on, and contribute to AI model training initiatives, incentivizing participation and decentralizing AI development.
 *
 * Function Summary:
 * 1.  initializeDAO(string _daoName, string _daoDescription, address[] _initialMembers, uint256 _proposalQuorumPercentage, uint256 _votingDurationDays): Initialize the DAO with basic parameters.
 * 2.  addMember(address _newMember): Allows admins to add new members to the DAO.
 * 3.  removeMember(address _memberToRemove): Allows admins to remove members from the DAO.
 * 4.  submitTrainingProposal(string _proposalTitle, string _proposalDescription, string _datasetCID, string _modelArchitecture, uint256 _targetAccuracy, uint256 _budgetInTokens, uint256 _rewardPerContributor): Members can submit proposals for AI model training.
 * 5.  voteOnProposal(uint256 _proposalId, bool _vote): Members can vote on active training proposals.
 * 6.  executeProposal(uint256 _proposalId): Executes a proposal if it passes the voting and budget is available.
 * 7.  contributeData(uint256 _proposalId, string _dataCID): Members can contribute data to approved training proposals.
 * 8.  contributeCompute(uint256 _proposalId, string _computeResourceDescription): Members can register their compute resources for approved proposals.
 * 9.  reportTrainingProgress(uint256 _proposalId, string _progressReportCID): Members can report training progress (potentially by designated trainers).
 * 10. submitModelEvaluation(uint256 _proposalId, string _evaluationReportCID, uint256 _achievedAccuracy): Members can submit model evaluation reports.
 * 11. approveModelEvaluation(uint256 _proposalId): Allows members to approve a submitted model evaluation if it meets criteria.
 * 12. distributeRewards(uint256 _proposalId): Distributes rewards to contributors of data and compute for a successfully completed proposal.
 * 13. depositToken(uint256 _amount): Allows members to deposit tokens into the DAO treasury.
 * 14. withdrawToken(uint256 _amount): Allows admins to withdraw tokens from the DAO treasury (governance controlled in real-world scenarios).
 * 15. setProposalQuorumPercentage(uint256 _newQuorumPercentage): Allows admins to change the proposal quorum percentage.
 * 16. setVotingDurationDays(uint256 _newVotingDurationDays): Allows admins to change the voting duration.
 * 17. cancelProposal(uint256 _proposalId): Allows admins to cancel a proposal if necessary.
 * 18. getProposalDetails(uint256 _proposalId): Returns detailed information about a specific proposal.
 * 19. getMemberDetails(address _memberAddress): Returns details about a specific member.
 * 20. getDAODetails(): Returns general information about the DAO.
 * 21. proposeParameterChange(string _parameterName, uint256 _newValue, string _reason): Allows members to propose changes to DAO parameters (quorum, voting duration, etc.).
 * 22. voteOnParameterChangeProposal(uint256 _proposalId, bool _vote): Members can vote on parameter change proposals.
 * 23. executeParameterChangeProposal(uint256 _proposalId): Executes a parameter change proposal if it passes.
 */

contract AIDao {
    // --- State Variables ---

    string public daoName;
    string public daoDescription;
    address public daoAdmin; // Address that initialized the DAO
    mapping(address => bool) public members;
    address[] public memberList;
    uint256 public proposalQuorumPercentage; // Percentage of members needed to reach quorum
    uint256 public votingDurationDays; // Duration of voting period in days
    IERC20 public daoToken; // ERC20 token for incentives and treasury

    uint256 public proposalCount;
    struct TrainingProposal {
        uint256 id;
        string title;
        string description;
        string datasetCID; // CID of the dataset (e.g., IPFS)
        string modelArchitecture;
        uint256 targetAccuracy;
        uint256 budgetInTokens;
        uint256 rewardPerContributor;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) public hasVoted;
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
        address[] dataContributors;
        address[] computeContributors;
        string progressReportCID;
        string evaluationReportCID;
        uint256 achievedAccuracy;
        address evaluationSubmitter;
        mapping(address => bool) public evaluationApprovals;
        uint256 evaluationApprovalCount;
    }

    enum ProposalStatus {
        Pending,
        Voting,
        Active,
        Completed,
        Failed,
        Cancelled
    }

    mapping(uint256 => TrainingProposal) public proposals;
    mapping(address => MemberDetails) public memberDetails;

    struct MemberDetails {
        uint256 joinTime;
        string memberProfileCID; // Optional: Link to member profile (e.g., IPFS)
    }

    uint256 public parameterChangeProposalCount;
    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) public hasVoted;
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;


    // --- Events ---
    event DAOCreated(string daoName, address admin);
    event MemberAdded(address memberAddress);
    event MemberRemoved(address memberAddress);
    event TrainingProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event DataContributed(uint256 proposalId, address contributor, string dataCID);
    event ComputeContributed(uint256 proposalId, address contributor, string computeDescription);
    event TrainingProgressReported(uint256 proposalId, string reportCID);
    event ModelEvaluationSubmitted(uint256 proposalId, string reportCID, uint256 accuracy, address submitter);
    event ModelEvaluationApproved(uint256 proposalId, address approver);
    event RewardsDistributed(uint256 proposalId);
    event TokensDeposited(address depositor, uint256 amount);
    event TokensWithdrawn(address withdrawer, uint256 amount);
    event ProposalQuorumPercentageChanged(uint256 newQuorumPercentage);
    event VotingDurationDaysChanged(uint256 newVotingDurationDays);
    event ProposalCancelled(uint256 proposalId);
    event ParameterChangeProposalSubmitted(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == daoAdmin, "Only DAO admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier validParameterChangeProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= parameterChangeProposalCount, "Invalid parameter change proposal ID.");
        _;
    }

    modifier proposalInVoting(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Voting, "Proposal is not in voting stage.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        _;
    }

    modifier parameterChangeProposalInVoting(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Voting, "Parameter change proposal is not in voting stage.");
        _;
    }

    modifier parameterChangeProposalPending(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Pending, "Parameter change proposal is not pending.");
        _;
    }


    // --- Constructor ---
    constructor(address _tokenAddress) payable {
        daoAdmin = msg.sender;
        daoToken = IERC20(_tokenAddress); // Set the DAO token contract address
        proposalCount = 0;
        parameterChangeProposalCount = 0;
        proposalQuorumPercentage = 50; // Default quorum percentage
        votingDurationDays = 7; // Default voting duration
        emit DAOCreated("Default AIDao", daoAdmin); // Default name, can be changed via initializeDAO
    }

    // --- Initialization Functions ---
    function initializeDAO(string memory _daoName, string memory _daoDescription, address[] memory _initialMembers, uint256 _proposalQuorumPercentage, uint256 _votingDurationDays) external onlyAdmin {
        require(bytes(daoName).length > 0, "DAO name cannot be empty.");
        require(bytes(_daoDescription).length > 0, "DAO description cannot be empty.");
        require(_proposalQuorumPercentage <= 100, "Quorum percentage must be <= 100.");
        require(_votingDurationDays > 0, "Voting duration must be greater than 0 days.");

        daoName = _daoName;
        daoDescription = _daoDescription;
        proposalQuorumPercentage = _proposalQuorumPercentage;
        votingDurationDays = _votingDurationDays;

        for (uint256 i = 0; i < _initialMembers.length; i++) {
            addMember(_initialMembers[i]);
        }

        emit DAOCreated(_daoName, daoAdmin);
    }


    // --- Membership Functions ---
    function addMember(address _newMember) public onlyAdmin {
        require(_newMember != address(0), "Invalid member address.");
        require(!members[_newMember], "Address is already a member.");
        members[_newMember] = true;
        memberList.push(_newMember);
        memberDetails[_newMember].joinTime = block.timestamp;
        emit MemberAdded(_newMember);
    }

    function removeMember(address _memberToRemove) public onlyAdmin {
        require(members[_memberToRemove], "Address is not a member.");
        require(_memberToRemove != daoAdmin, "Cannot remove the DAO admin through this function."); // Prevent accidental admin removal
        members[_memberToRemove] = false;

        // Efficiently remove from memberList (order doesn't matter in this example)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _memberToRemove) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        delete memberDetails[_memberToRemove]; // Clean up member details
        emit MemberRemoved(_memberToRemove);
    }

    function setMemberProfileCID(string memory _profileCID) public onlyMember {
        memberDetails[msg.sender].memberProfileCID = _profileCID;
    }


    // --- Training Proposal Functions ---
    function submitTrainingProposal(
        string memory _proposalTitle,
        string memory _proposalDescription,
        string memory _datasetCID,
        string memory _modelArchitecture,
        uint256 _targetAccuracy,
        uint256 _budgetInTokens,
        uint256 _rewardPerContributor
    ) public onlyMember {
        require(bytes(_proposalTitle).length > 0, "Proposal title cannot be empty.");
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty.");
        require(bytes(_datasetCID).length > 0, "Dataset CID cannot be empty.");
        require(bytes(_modelArchitecture).length > 0, "Model architecture cannot be empty.");
        require(_budgetInTokens > 0, "Budget must be greater than 0.");
        require(_rewardPerContributor > 0, "Reward per contributor must be greater than 0.");

        proposalCount++;
        TrainingProposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = _proposalTitle;
        newProposal.description = _proposalDescription;
        newProposal.datasetCID = _datasetCID;
        newProposal.modelArchitecture = _modelArchitecture;
        newProposal.targetAccuracy = _targetAccuracy;
        newProposal.budgetInTokens = _budgetInTokens;
        newProposal.rewardPerContributor = _rewardPerContributor;
        newProposal.status = ProposalStatus.Voting;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDurationDays * 1 days; // Voting duration in seconds

        emit TrainingProposalSubmitted(proposalCount, _proposalTitle, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyMember validProposalId(_proposalId) proposalInVoting(_proposalId) {
        TrainingProposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Member has already voted on this proposal.");
        proposal.hasVoted[msg.sender] = true;

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period is over and execute if quorum is met
        if (block.timestamp >= proposal.endTime) {
            _checkAndExecuteProposal(_proposalId);
        }
    }

    function executeProposal(uint256 _proposalId) public validProposalId(_proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Voting, "Proposal must be in voting to be executed.");
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period is not over yet. Cannot execute prematurely.");
        _checkAndExecuteProposal(_proposalId);
    }

    function _checkAndExecuteProposal(uint256 _proposalId) private validProposalId(_proposalId) proposalInVoting(_proposalId) {
        TrainingProposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredVotes = (memberList.length * proposalQuorumPercentage) / 100;

        if (totalVotes >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            // Check if DAO has enough tokens in treasury
            uint256 treasuryBalance = daoToken.balanceOf(address(this));
            if (treasuryBalance >= proposal.budgetInTokens) {
                proposal.status = ProposalStatus.Active;
                emit ProposalExecuted(_proposalId);
            } else {
                proposal.status = ProposalStatus.Failed; // Not enough funds
            }
        } else {
            proposal.status = ProposalStatus.Failed; // Voting failed
        }
    }

    function contributeData(uint256 _proposalId, string memory _dataCID) public onlyMember validProposalId(_proposalId) proposalActive(_proposalId) {
        TrainingProposal storage proposal = proposals[_proposalId];
        // Basic check - prevent duplicate contributions from same member (can be enhanced)
        bool alreadyContributed = false;
        for (uint256 i = 0; i < proposal.dataContributors.length; i++) {
            if (proposal.dataContributors[i] == msg.sender) {
                alreadyContributed = true;
                break;
            }
        }
        require(!alreadyContributed, "You have already contributed data to this proposal.");

        proposal.dataContributors.push(msg.sender);
        emit DataContributed(_proposalId, msg.sender, _dataCID);
    }

    function contributeCompute(uint256 _proposalId, string memory _computeResourceDescription) public onlyMember validProposalId(_proposalId) proposalActive(_proposalId) {
        TrainingProposal storage proposal = proposals[_proposalId];
        // Basic check - prevent duplicate contributions from same member (can be enhanced)
        bool alreadyContributed = false;
        for (uint256 i = 0; i < proposal.computeContributors.length; i++) {
            if (proposal.computeContributors[i] == msg.sender) {
                alreadyContributed = true;
                break;
            }
        }
        require(!alreadyContributed, "You have already contributed compute to this proposal.");

        proposal.computeContributors.push(msg.sender);
        emit ComputeContributed(_proposalId, msg.sender, _computeResourceDescription);
    }

    function reportTrainingProgress(uint256 _proposalId, string memory _progressReportCID) public onlyMember validProposalId(_proposalId) proposalActive(_proposalId) {
        proposals[_proposalId].progressReportCID = _progressReportCID;
        emit TrainingProgressReported(_proposalId, _progressReportCID);
    }

    function submitModelEvaluation(uint256 _proposalId, string memory _evaluationReportCID, uint256 _achievedAccuracy) public onlyMember validProposalId(_proposalId) proposalActive(_proposalId) {
        require(proposals[_proposalId].evaluationSubmitter == address(0), "Evaluation already submitted for this proposal."); // Only submit once
        require(_achievedAccuracy <= 100, "Accuracy must be <= 100.");

        proposals[_proposalId].evaluationReportCID = _evaluationReportCID;
        proposals[_proposalId].achievedAccuracy = _achievedAccuracy;
        proposals[_proposalId].evaluationSubmitter = msg.sender;
        emit ModelEvaluationSubmitted(_proposalId, _evaluationReportCID, _achievedAccuracy, msg.sender);
    }

    function approveModelEvaluation(uint256 _proposalId) public onlyMember validProposalId(_proposalId) proposalActive(_proposalId) {
        TrainingProposal storage proposal = proposals[_proposalId];
        require(proposal.evaluationSubmitter != address(0), "No evaluation submitted yet.");
        require(!proposal.evaluationApprovals[msg.sender], "You have already approved this evaluation.");

        proposal.evaluationApprovals[msg.sender] = true;
        proposal.evaluationApprovalCount++;
        emit ModelEvaluationApproved(_proposalId, msg.sender);

        // Check if evaluation is approved by enough members (e.g., majority or quorum - can be configurable)
        uint256 requiredApprovals = (memberList.length * proposalQuorumPercentage) / 100; // Example: quorum-based approval
        if (proposal.evaluationApprovalCount >= requiredApprovals) {
            distributeRewards(_proposalId);
            proposals[_proposalId].status = ProposalStatus.Completed;
        }
    }

    function distributeRewards(uint256 _proposalId) public validProposalId(_proposalId) proposalActive(_proposalId) {
        TrainingProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal must be active to distribute rewards.");
        require(proposal.evaluationSubmitter != address(0), "Model evaluation must be submitted before distributing rewards.");
        require(proposal.achievedAccuracy >= proposal.targetAccuracy, "Achieved accuracy is below target. Rewards might be conditional in real scenarios."); // Example: reward only if target accuracy is met

        uint256 totalRewardAmount = (proposal.dataContributors.length + proposal.computeContributors.length) * proposal.rewardPerContributor;
        require(daoToken.balanceOf(address(this)) >= totalRewardAmount, "Insufficient DAO tokens for rewards."); // Double check treasury balance

        for (uint256 i = 0; i < proposal.dataContributors.length; i++) {
            daoToken.transfer(proposal.dataContributors[i], proposal.rewardPerContributor);
        }
        for (uint256 i = 0; i < proposal.computeContributors.length; i++) {
            daoToken.transfer(proposal.computeContributors[i], proposal.rewardPerContributor);
        }

        emit RewardsDistributed(_proposalId);
    }

    // --- Treasury Functions ---
    function depositToken(uint256 _amount) public onlyMember {
        require(_amount > 0, "Deposit amount must be greater than 0.");
        daoToken.transferFrom(msg.sender, address(this), _amount); // Assuming member has approved DAO to spend tokens
        emit TokensDeposited(msg.sender, _amount);
    }

    function withdrawToken(uint256 _amount) public onlyAdmin { // In real DAO, withdrawal should be governed by proposals
        require(_amount > 0, "Withdrawal amount must be greater than 0.");
        require(daoToken.balanceOf(address(this)) >= _amount, "Insufficient DAO treasury balance.");
        daoToken.transfer(msg.sender, _amount); // Admin address receives withdrawal in this simplified example
        emit TokensWithdrawn(msg.sender, _amount);
    }

    // --- DAO Parameter Change Functions ---
    function setProposalQuorumPercentage(uint256 _newQuorumPercentage) public onlyAdmin { // In real DAO, this should be a governance proposal
        require(_newQuorumPercentage <= 100, "Quorum percentage must be <= 100.");
        proposalQuorumPercentage = _newQuorumPercentage;
        emit ProposalQuorumPercentageChanged(_newQuorumPercentage);
    }

    function setVotingDurationDays(uint256 _newVotingDurationDays) public onlyAdmin { // In real DAO, this should be a governance proposal
        require(_newVotingDurationDays > 0, "Voting duration must be greater than 0 days.");
        votingDurationDays = _newVotingDurationDays;
        emit VotingDurationDaysChanged(_newVotingDurationDays);
    }

    function proposeParameterChange(string memory _parameterName, uint256 _newValue, string memory _reason) public onlyMember {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        require(bytes(_reason).length > 0, "Reason cannot be empty.");

        parameterChangeProposalCount++;
        ParameterChangeProposal storage newProposal = parameterChangeProposals[parameterChangeProposalCount];
        newProposal.id = parameterChangeProposalCount;
        newProposal.parameterName = _parameterName;
        newProposal.newValue = _newValue;
        newProposal.reason = _reason;
        newProposal.status = ProposalStatus.Voting;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDurationDays * 1 days;

        emit ParameterChangeProposalSubmitted(parameterChangeProposalCount, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) public onlyMember validParameterChangeProposalId(_proposalId) parameterChangeProposalInVoting(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Member has already voted on this proposal.");
        proposal.hasVoted[msg.sender] = true;

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.endTime) {
            _checkAndExecuteParameterChangeProposal(_proposalId);
        }
    }

    function executeParameterChangeProposal(uint256 _proposalId) public validParameterChangeProposalId(_proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Voting, "Parameter change proposal must be in voting to be executed.");
        require(block.timestamp >= parameterChangeProposals[_proposalId].endTime, "Voting period is not over yet.");
        _checkAndExecuteParameterChangeProposal(_proposalId);
    }

    function _checkAndExecuteParameterChangeProposal(uint256 _proposalId) private validParameterChangeProposalId(_proposalId) parameterChangeProposalInVoting(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredVotes = (memberList.length * proposalQuorumPercentage) / 100;

        if (totalVotes >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Active; // Mark as active before applying change

            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("proposalQuorumPercentage"))) {
                setProposalQuorumPercentage(uint256(proposal.newValue)); // Cast to uint256
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("votingDurationDays"))) {
                setVotingDurationDays(uint256(proposal.newValue));     // Cast to uint256
            } else {
                proposal.status = ProposalStatus.Failed; // Invalid parameter name
                return;
            }

            proposal.status = ProposalStatus.Completed; // Mark as completed after successful change
            emit ParameterChangeProposalExecuted(_proposalId, proposal.parameterName, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }


    // --- Utility Functions ---
    function cancelProposal(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Voting || proposals[_proposalId].status == ProposalStatus.Pending, "Proposal cannot be cancelled in its current state.");
        proposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (TrainingProposal memory) {
        return proposals[_proposalId];
    }

    function getMemberDetails(address _memberAddress) public view returns (MemberDetails memory) {
        return memberDetails[_memberAddress];
    }

    function getDAODetails() public view returns (string memory name, string memory description, address admin, uint256 quorumPercentage, uint256 durationDays, uint256 currentProposalCount, uint256 currentParameterChangeProposalCount, uint256 treasuryBalance) {
        return (daoName, daoDescription, daoAdmin, proposalQuorumPercentage, votingDurationDays, proposalCount, parameterChangeProposalCount, daoToken.balanceOf(address(this)));
    }

    // --- Fallback and Receive (Optional, for receiving Ether if needed, not directly used in this token-based DAO) ---
    receive() external payable {}
    fallback() external payable {}
}

// --- Interface for ERC20 Token ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```