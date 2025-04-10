```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Your Name or Organization Name
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO)
 *      with advanced features for research project management, intellectual property,
 *      decentralized funding, reputation system, and collaborative research.
 *
 * Function Summary:
 *
 * **Governance & Membership:**
 * 1. joinDARO(): Allows users to request membership in the DARO.
 * 2. approveMembership(address _user): Governor function to approve membership requests.
 * 3. revokeMembership(address _user): Governor function to revoke membership.
 * 4. proposeGovernanceChange(string _description, bytes _calldata): Allows members to propose governance changes.
 * 5. voteOnGovernanceProposal(uint256 _proposalId, bool _support): Allows members to vote on governance proposals.
 * 6. executeGovernanceProposal(uint256 _proposalId): Governor function to execute approved governance proposals.
 * 7. setQuorum(uint256 _newQuorum): Governor function to set the voting quorum for proposals.
 * 8. delegateVote(address _delegatee): Allows members to delegate their voting power to another member.
 *
 * **Research Project Management:**
 * 9. createResearchProject(string _title, string _description, uint256 _fundingGoal, string _ipfsHash): Allows members to propose new research projects.
 * 10. fundResearchProject(uint256 _projectId) payable: Allows members to contribute funds to a research project.
 * 11. submitResearchMilestone(uint256 _projectId, string _milestoneDescription, string _ipfsHash): Allows project leaders to submit milestones.
 * 12. approveResearchMilestone(uint256 _projectId, uint256 _milestoneId): Allows reviewers to approve research milestones, releasing funds.
 * 13. submitResearchOutput(uint256 _projectId, string _outputDescription, string _ipfsHash): Allows project leaders to submit final research outputs.
 * 14. reviewResearchOutput(uint256 _projectId, uint256 _rating): Allows members to review and rate research outputs.
 * 15. withdrawProjectFunds(uint256 _projectId): Allows project leaders to withdraw project funds after milestones are approved.
 * 16. proposeProjectCancellation(uint256 _projectId, string _reason): Allows members to propose cancellation of a project.
 * 17. voteOnProjectCancellation(uint256 _projectId, bool _support): Allows members to vote on project cancellation proposals.
 *
 * **Intellectual Property & Reputation:**
 * 18. registerIntellectualProperty(uint256 _projectId, string _ipDescription, string _ipfsHash): Allows project leaders to register IP associated with a project.
 * 19. getResearcherReputation(address _researcher): Returns the reputation score of a researcher based on project contributions and reviews.
 * 20. incentivizeReviewers(uint256 _projectId): Distributes rewards to reviewers who participated in a project's milestone or output reviews.
 * 21. setReviewerReward(uint256 _rewardAmount): Governor function to set the reward amount for reviewers.
 * 22. proposeDataSharingPolicy(uint256 _projectId, string _policyDescription, string _ipfsHash):  Allows project leaders to propose data sharing policies for research data.
 * 23. voteOnDataSharingPolicy(uint256 _projectId, bool _support): Allows members to vote on data sharing policies for a project.
 */

contract DecentralizedAutonomousResearchOrganization {

    // -------- Structs and Enums --------

    enum ProposalType { GOVERNANCE, PROJECT_CANCELLATION, DATA_POLICY }
    enum ProposalStatus { PENDING, ACTIVE, PASSED, FAILED, EXECUTED }
    enum ProjectStatus { PROPOSED, FUNDING, ACTIVE, COMPLETED, CANCELLED }
    enum MilestoneStatus { PENDING, APPROVED, REJECTED }

    struct GovernanceProposal {
        uint256 id;
        ProposalType proposalType;
        string description;
        bytes calldata; // Calldata for execution if proposal passes
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct ResearchProject {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        ProjectStatus status;
        string ipfsHash; // IPFS hash for project details
        address[] leaders; // Addresses of project leaders
        Milestone[] milestones;
        ResearchOutput[] outputs;
        DataSharingPolicy dataPolicy;
    }

    struct Milestone {
        uint256 id;
        string description;
        string ipfsHash;
        MilestoneStatus status;
        uint256 rewardAmount; // Reward to be released upon approval
        address[] reviewers; // Reviewers assigned to this milestone
        uint256 approvals;
        uint256 rejections;
    }

    struct ResearchOutput {
        uint256 id;
        string description;
        string ipfsHash;
        uint256 ratingSum;
        uint256 ratingCount;
    }

    struct DataSharingPolicy {
        string description;
        string ipfsHash;
        bool approved;
    }


    struct Researcher {
        address account;
        uint256 reputationScore;
        bool isMember;
        address delegate; // Address this member delegates their vote to
    }

    // -------- State Variables --------

    address public governor;
    uint256 public membershipFee; // Fee to become a DARO member (optional)
    uint256 public proposalQuorumPercentage = 50; // Percentage of members needed to vote for quorum
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public reviewerRewardAmount = 1 ether; // Reward for reviewing milestones/outputs
    uint256 public proposalCounter;
    uint256 public projectCounter;

    mapping(address => Researcher) public researchers;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ResearchProject) public researchProjects;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter => hasVoted
    mapping(uint256 => mapping(address => bool)) public hasReviewedMilestone; // projectId => reviewer => hasReviewed
    mapping(uint256 => mapping(address => bool)) public hasReviewedOutput;   // projectId => reviewer => hasReviewed

    address[] public daroMembers;
    address[] public membershipRequests;

    // -------- Events --------

    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed user);
    event MembershipRevoked(address indexed user);
    event GovernanceProposalCreated(uint256 indexed proposalId, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ResearchProjectCreated(uint256 indexed projectId, string title, address proposer);
    event ResearchProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ResearchMilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneId, string description);
    event ResearchMilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneId);
    event ResearchOutputSubmitted(uint256 indexed projectId, uint256 indexed outputId, string description);
    event ResearchOutputReviewed(uint256 indexed projectId, uint256 indexed outputId, address indexed reviewer, uint256 rating);
    event ProjectFundsWithdrawn(uint256 indexed projectId, address indexed withdrawer, uint256 amount);
    event ProjectCancellationProposed(uint256 indexed projectId, string reason);
    event ProjectCancellationVoted(uint256 indexed projectId, uint256 indexed projectId, address indexed voter, bool support);
    event IntellectualPropertyRegistered(uint256 indexed projectId, string description);
    event ReviewerRewardDistributed(uint256 indexed projectId, address indexed reviewer, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event DataSharingPolicyProposed(uint256 indexed projectId, string description);
    event DataSharingPolicyVoted(uint256 indexed projectId, uint256 indexed projectId, address indexed voter, bool support);
    event DataSharingPolicyApproved(uint256 indexed projectId, uint256 indexed projectId);


    // -------- Modifiers --------

    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor can call this function.");
        _;
    }

    modifier onlyDAROMember() {
        require(researchers[msg.sender].isMember, "Only DARO members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier validProject(uint256 _projectId) {
        require(researchProjects[_projectId].id == _projectId, "Invalid project ID.");
        _;
    }

    modifier projectInStatus(uint256 _projectId, ProjectStatus _status) {
        require(researchProjects[_projectId].status == _status, "Project is not in the required status.");
        _;
    }

    modifier milestoneExists(uint256 _projectId, uint256 _milestoneId) {
        require(_milestoneId < researchProjects[_projectId].milestones.length, "Invalid milestone ID.");
        _;
    }

    modifier milestoneInStatus(uint256 _projectId, uint256 _milestoneId, MilestoneStatus _status) {
        require(researchProjects[_projectId].milestones[_milestoneId].status == _status, "Milestone is not in the required status.");
        _;
    }

    modifier outputExists(uint256 _projectId, uint256 _outputId) {
        require(_outputId < researchProjects[_projectId].outputs.length, "Invalid output ID.");
        _;
    }

    modifier notVotedOnProposal(uint256 _proposalId) {
        require(!hasVotedOnProposal[_proposalId][msg.sender], "Already voted on this proposal.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        governor = msg.sender;
        researchers[governor].isMember = true; // Governor is automatically a member
        daroMembers.push(governor);
    }

    // -------- Governance & Membership Functions --------

    function joinDARO() external {
        require(!researchers[msg.sender].isMember, "Already a member or membership requested.");
        require(!isMembershipRequested(msg.sender), "Membership already requested.");
        membershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    function isMembershipRequested(address _user) private view returns (bool) {
        for (uint256 i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function approveMembership(address _user) external onlyGovernor {
        require(isMembershipRequested(_user), "Membership not requested.");
        researchers[_user].isMember = true;
        daroMembers.push(_user);
        // Remove from membership requests array
        for (uint256 i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] == _user) {
                membershipRequests[i] = membershipRequests[membershipRequests.length - 1];
                membershipRequests.pop();
                break;
            }
        }
        emit MembershipApproved(_user);
    }

    function revokeMembership(address _user) external onlyGovernor {
        require(researchers[_user].isMember, "User is not a member.");
        researchers[_user].isMember = false;
        // Remove from daroMembers array
        for (uint256 i = 0; i < daroMembers.length; i++) {
            if (daroMembers[i] == _user) {
                daroMembers[i] = daroMembers[daroMembers.length - 1];
                daroMembers.pop();
                break;
            }
        }
        emit MembershipRevoked(_user);
    }

    function proposeGovernanceChange(string memory _description, bytes memory _calldata) external onlyDAROMember {
        proposalCounter++;
        GovernanceProposal storage proposal = governanceProposals[proposalCounter];
        proposal.id = proposalCounter;
        proposal.proposalType = ProposalType.GOVERNANCE;
        proposal.description = _description;
        proposal.calldata = _calldata;
        proposal.status = ProposalStatus.ACTIVE;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        emit GovernanceProposalCreated(proposalCounter, _description);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyDAROMember validProposal(_proposalId) notVotedOnProposal(_proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        require(block.timestamp <= governanceProposals[_proposalId].endTime, "Voting period ended.");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        address voter = msg.sender;
        address delegate = researchers[voter].delegate;
        address effectiveVoter = (delegate != address(0)) ? delegate : voter; // Use delegate if set, otherwise voter

        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, effectiveVoter, _support);

        // Check if proposal passed after vote
        _checkProposalOutcome(_proposalId);
    }

    function _checkProposalOutcome(uint256 _proposalId) private {
        if (governanceProposals[_proposalId].status != ProposalStatus.ACTIVE) return; // Already checked

        uint256 totalVotes = governanceProposals[_proposalId].votesFor + governanceProposals[_proposalId].votesAgainst;
        uint256 quorum = (daroMembers.length * proposalQuorumPercentage) / 100;

        if (totalVotes >= quorum) {
            if (governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst) {
                governanceProposals[_proposalId].status = ProposalStatus.PASSED;
            } else {
                governanceProposals[_proposalId].status = ProposalStatus.FAILED;
            }
        }
    }


    function executeGovernanceProposal(uint256 _proposalId) external onlyGovernor validProposal(_proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.PASSED, "Proposal not passed.");
        governanceProposals[_proposalId].status = ProposalStatus.EXECUTED;
        (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].calldata);
        require(success, "Governance proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId);
    }

    function setQuorum(uint256 _newQuorum) external onlyGovernor {
        require(_newQuorum <= 100, "Quorum percentage must be <= 100.");
        proposalQuorumPercentage = _newQuorum;
    }

    function delegateVote(address _delegatee) external onlyDAROMember {
        require(researchers[_delegatee].isMember, "Delegatee must be a DARO member.");
        require(_delegatee != msg.sender, "Cannot delegate to yourself.");
        researchers[msg.sender].delegate = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }


    // -------- Research Project Management Functions --------

    function createResearchProject(string memory _title, string memory _description, uint256 _fundingGoal, string memory _ipfsHash) external onlyDAROMember {
        projectCounter++;
        ResearchProject storage project = researchProjects[projectCounter];
        project.id = projectCounter;
        project.proposer = msg.sender;
        project.title = _title;
        project.description = _description;
        project.fundingGoal = _fundingGoal;
        project.status = ProjectStatus.PROPOSED;
        project.ipfsHash = _ipfsHash;
        project.leaders.push(msg.sender); // Proposer is automatically a leader
        emit ResearchProjectCreated(projectCounter, _title, msg.sender);
    }

    function fundResearchProject(uint256 _projectId) external payable validProject(_projectId) projectInStatus(_projectId, ProjectStatus.PROPOSED) {
        ResearchProject storage project = researchProjects[_projectId];
        project.currentFunding += msg.value;
        emit ResearchProjectFunded(_projectId, msg.sender, msg.value);

        if (project.currentFunding >= project.fundingGoal) {
            project.status = ProjectStatus.FUNDING; // Transition to FUNDING state after reaching goal
        }
    }

    function submitResearchMilestone(uint256 _projectId, string memory _milestoneDescription, string memory _ipfsHash) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        ResearchProject storage project = researchProjects[_projectId];
        require(_isProjectLeader(_projectId, msg.sender), "Only project leaders can submit milestones.");

        uint256 milestoneId = project.milestones.length;
        Milestone memory newMilestone;
        newMilestone.id = milestoneId;
        newMilestone.description = _milestoneDescription;
        newMilestone.ipfsHash = _ipfsHash;
        newMilestone.status = MilestoneStatus.PENDING;
        newMilestone.rewardAmount = project.fundingGoal / 5; // Example: 20% of funding per milestone
        // Assign reviewers -  Simple example: all DARO members are potential reviewers. In real-world, could be more sophisticated selection
        newMilestone.reviewers = daroMembers; // Assign all members as reviewers for simplicity
        project.milestones.push(newMilestone);

        emit ResearchMilestoneSubmitted(_projectId, milestoneId, _milestoneDescription);
    }

    function approveResearchMilestone(uint256 _projectId, uint256 _milestoneId) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) milestoneExists(_projectId, _milestoneId) milestoneInStatus(_projectId, _milestoneId, MilestoneStatus.PENDING) {
        require(!hasReviewedMilestone[_projectId][msg.sender], "Already reviewed this milestone.");

        Milestone storage milestone = researchProjects[_projectId].milestones[_milestoneId];
        bool isReviewer = false;
        for(uint i=0; i < milestone.reviewers.length; i++) {
            if (milestone.reviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        require(isReviewer, "You are not assigned as a reviewer for this milestone.");


        milestone.approvals++;
        hasReviewedMilestone[_projectId][msg.sender] = true;

        if (milestone.approvals >= (milestone.reviewers.length / 2) + 1 ) { // Simple majority for approval
            milestone.status = MilestoneStatus.APPROVED;
            emit ResearchMilestoneApproved(_projectId, _milestoneId);
        }
    }

    function submitResearchOutput(uint256 _projectId, string memory _outputDescription, string memory _ipfsHash) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        ResearchProject storage project = researchProjects[_projectId];
        require(_isProjectLeader(_projectId, msg.sender), "Only project leaders can submit outputs.");

        uint256 outputId = project.outputs.length;
        ResearchOutput memory newOutput;
        newOutput.id = outputId;
        newOutput.description = _outputDescription;
        newOutput.ipfsHash = _ipfsHash;
        project.outputs.push(newOutput);

        emit ResearchOutputSubmitted(_projectId, outputId, _outputDescription);
    }

    function reviewResearchOutput(uint256 _projectId, uint256 _outputId, uint256 _rating) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) outputExists(_projectId, _outputId) {
        require(!hasReviewedOutput[_projectId][msg.sender], "Already reviewed this output.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Example rating scale 1-5

        ResearchOutput storage output = researchProjects[_projectId].outputs[_outputId];
        output.ratingSum += _rating;
        output.ratingCount++;
        hasReviewedOutput[_projectId][msg.sender] = true;

        emit ResearchOutputReviewed(_projectId, _outputId, msg.sender, _rating);
    }

    function withdrawProjectFunds(uint256 _projectId) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        require(_isProjectLeader(_projectId, msg.sender), "Only project leaders can withdraw funds.");
        uint256 withdrawableAmount = 0;
        for (uint256 i = 0; i < researchProjects[_projectId].milestones.length; i++) {
            if (researchProjects[_projectId].milestones[i].status == MilestoneStatus.APPROVED) {
                withdrawableAmount += researchProjects[_projectId].milestones[i].rewardAmount;
            }
        }

        require(withdrawableAmount > 0, "No approved milestones to withdraw funds from.");
        require(researchProjects[_projectId].currentFunding >= withdrawableAmount, "Insufficient funds in project to withdraw.");

        payable(msg.sender).transfer(withdrawableAmount);
        researchProjects[_projectId].currentFunding -= withdrawableAmount;
        emit ProjectFundsWithdrawn(_projectId, msg.sender, withdrawableAmount);
    }

    function proposeProjectCancellation(uint256 _projectId, string memory _reason) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        proposalCounter++;
        GovernanceProposal storage proposal = governanceProposals[proposalCounter];
        proposal.id = proposalCounter;
        proposal.proposalType = ProposalType.PROJECT_CANCELLATION;
        proposal.description = _reason;
        proposal.calldata = abi.encodeWithSignature("cancelProject(uint256)", _projectId); // Encoded call to cancelProject
        proposal.status = ProposalStatus.ACTIVE;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        emit ProjectCancellationProposed(_projectId, _reason);
    }

    function voteOnProjectCancellation(uint256 _proposalId, bool _support) external onlyDAROMember validProposal(_proposalId) notVotedOnProposal(_proposalId) {
        require(governanceProposals[_proposalId].proposalType == ProposalType.PROJECT_CANCELLATION, "Proposal is not for project cancellation.");
        require(governanceProposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        require(block.timestamp <= governanceProposals[_proposalId].endTime, "Voting period ended.");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit ProjectCancellationVoted(_proposalId, governanceProposals[_proposalId].id, msg.sender, _support);

        // Check if proposal passed after vote
        _checkProposalOutcome(_proposalId);
    }

    function cancelProject(uint256 _projectId) external onlyGovernor {
        // This function is called via delegatecall after project cancellation proposal passes
        require(governanceProposals[proposalCounter].proposalType == ProposalType.PROJECT_CANCELLATION, "Invalid call context."); // Ensure called from proposal execution
        researchProjects[_projectId].status = ProjectStatus.CANCELLED;
    }


    // -------- Intellectual Property & Reputation Functions --------

    function registerIntellectualProperty(uint256 _projectId, string memory _ipDescription, string memory _ipfsHash) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        require(_isProjectLeader(_projectId, msg.sender), "Only project leaders can register IP.");
        // In a real-world scenario, this would likely interact with a more robust IP registry system (off-chain or another smart contract).
        // This is a simplified example to record IP related to the project.
        // ... (Logic to interact with IP registry system or store IP details) ...
        emit IntellectualPropertyRegistered(_projectId, _ipDescription);
    }

    function getResearcherReputation(address _researcher) public view returns (uint256) {
        return researchers[_researcher].reputationScore;
    }

    function incentivizeReviewers(uint256 _projectId) external onlyGovernor validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        uint256 rewardPerReviewer = reviewerRewardAmount;
        uint256 totalReward = 0;
        uint256 reviewerCount = 0;

        // Milestone Reviewers
        for (uint256 i = 0; i < researchProjects[_projectId].milestones.length; i++) {
            Milestone storage milestone = researchProjects[_projectId].milestones[i];
            if (milestone.status == MilestoneStatus.APPROVED) { // Only reward reviewers of approved milestones
                for(uint j=0; j < milestone.reviewers.length; j++) {
                    if (hasReviewedMilestone[_projectId][milestone.reviewers[j]]) { // Only reward those who actually reviewed
                        totalReward += rewardPerReviewer;
                        reviewerCount++;
                        payable(milestone.reviewers[j]).transfer(rewardPerReviewer);
                        emit ReviewerRewardDistributed(_projectId, milestone.reviewers[j], rewardPerReviewer);
                    }
                }
            }
        }

        // Output Reviewers (Example - could be adapted based on output review process)
        for (uint256 i = 0; i < researchProjects[_projectId].outputs.length; i++) {
             ResearchOutput storage output = researchProjects[_projectId].outputs[i];
             if (output.ratingCount > 0) { // Example: Reward reviewers if there are ratings
                 for(uint j=0; j < daroMembers.length; j++) { // Assuming all members could review outputs
                     if (hasReviewedOutput[_projectId][daroMembers[j]]) {
                         totalReward += rewardPerReviewer;
                         reviewerCount++;
                         payable(daroMembers[j]).transfer(rewardPerReviewer);
                         emit ReviewerRewardDistributed(_projectId, daroMembers[j], rewardPerReviewer);
                     }
                 }
             }
         }


        require(address(this).balance >= totalReward, "Contract balance too low to reward reviewers.");
    }

    function setReviewerReward(uint256 _rewardAmount) external onlyGovernor {
        reviewerRewardAmount = _rewardAmount;
    }

    function proposeDataSharingPolicy(uint256 _projectId, string memory _policyDescription, string memory _ipfsHash) external onlyDAROMember validProject(_projectId) projectInStatus(_projectId, ProjectStatus.FUNDING) {
        proposalCounter++;
        GovernanceProposal storage proposal = governanceProposals[proposalCounter];
        proposal.id = proposalCounter;
        proposal.proposalType = ProposalType.DATA_POLICY;
        proposal.description = _policyDescription;
        proposal.calldata = abi.encodeWithSignature("setDataSharingPolicyForProject(uint256,string,string)", _projectId, _policyDescription, _ipfsHash); // Encoded call to set data policy
        proposal.status = ProposalStatus.ACTIVE;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        emit DataSharingPolicyProposed(_projectId, _policyDescription);
    }


    function voteOnDataSharingPolicy(uint256 _proposalId, bool _support) external onlyDAROMember validProposal(_proposalId) notVotedOnProposal(_proposalId) {
        require(governanceProposals[_proposalId].proposalType == ProposalType.DATA_POLICY, "Proposal is not for data policy.");
        require(governanceProposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        require(block.timestamp <= governanceProposals[_proposalId].endTime, "Voting period ended.");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit DataSharingPolicyVoted(_proposalId, governanceProposals[_proposalId].id, msg.sender, _support);

        _checkProposalOutcome(_proposalId);
    }

    function setDataSharingPolicyForProject(uint256 _projectId, string memory _policyDescription, string memory _ipfsHash) external onlyGovernor {
        // This function is called via delegatecall after data policy proposal passes
        require(governanceProposals[proposalCounter].proposalType == ProposalType.DATA_POLICY, "Invalid call context."); // Ensure called from proposal execution
        researchProjects[_projectId].dataPolicy = DataSharingPolicy({
            description: _policyDescription,
            ipfsHash: _ipfsHash,
            approved: true
        });
        emit DataSharingPolicyApproved(_projectId, _projectId);
    }


    // -------- Internal Helper Functions --------

    function _isProjectLeader(uint256 _projectId, address _account) private view returns (bool) {
        ResearchProject storage project = researchProjects[_projectId];
        for (uint256 i = 0; i < project.leaders.length; i++) {
            if (project.leaders[i] == _account) {
                return true;
            }
        }
        return false;
    }

    // Fallback function to receive Ether for project funding
    receive() external payable {}
}
```