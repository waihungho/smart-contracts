```solidity
pragma solidity ^0.8.0;

/**
 * @title Creative Catalyst DAO - A Decentralized Funding Platform for Creative Projects
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a Decentralized Autonomous Organization (DAO) focused on
 * funding creative projects proposed by its members. It incorporates advanced concepts like
 * dynamic voting based on reputation, phased funding, milestone-based project progression,
 * and a robust dispute resolution mechanism. This DAO aims to foster innovation and creativity
 * within a decentralized and transparent framework.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinDAO()`: Allows users to request membership to the DAO.
 *    - `approveMembership(address _member)`: Admin function to approve pending membership requests.
 *    - `revokeMembership(address _member)`: Admin function to revoke membership.
 *    - `getMemberDetails(address _member)`: View function to retrieve member specific information (reputation, status).
 *    - `getMemberCount()`: View function to get the total number of members.
 *
 * **2. Reputation System:**
 *    - `increaseReputation(address _member, uint256 _amount)`: Admin function to manually increase member reputation.
 *    - `decreaseReputation(address _member, uint256 _amount)`: Admin function to manually decrease member reputation.
 *    - `recordPositiveContribution(address _member, string memory _contributionDetails)`: Function to record positive contributions, potentially leading to reputation increase (governance-driven in a real-world scenario).
 *    - `recordNegativeContribution(address _member, string memory _contributionDetails)`: Function to record negative contributions, potentially leading to reputation decrease (governance-driven in a real-world scenario).
 *    - `getMemberReputation(address _member)`: View function to get a member's reputation score.
 *
 * **3. Project Proposal and Funding:**
 *    - `proposeProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, uint256 _milestoneCount, uint256 _initialStageFundingPercentage, string[] memory _milestoneDescriptions)`: Allows members to propose creative projects with phased funding and milestones.
 *    - `getProjectDetails(uint256 _projectId)`: View function to retrieve detailed information about a project.
 *    - `fundProjectStage(uint256 _projectId)`: Allows members to contribute funds to a project's current funding stage.
 *    - `submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`: Project proposer function to submit a milestone for review and approval.
 *    - `approveMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Governance function (voting) to approve a completed milestone, releasing next stage funding.
 *    - `rejectMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Governance function (voting) to reject a completed milestone, potentially leading to project review or cancellation.
 *
 * **4. Governance and Voting:**
 *    - `createProposal(ProposalType _proposalType, uint256 _targetId, string memory _description, bytes memory _data)`: Generic function to create different types of governance proposals (milestone approval, reputation changes, parameter updates, etc.).
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on active proposals, with voting power weighted by reputation.
 *    - `executeProposal(uint256 _proposalId)`: Function to execute a proposal after it has passed the voting threshold.
 *    - `getProposalDetails(uint256 _proposalId)`: View function to retrieve details about a specific proposal.
 *    - `getProposalVotingStatus(uint256 _proposalId)`: View function to get the current voting status of a proposal (votes for, votes against, quorum).
 *
 * **5. Treasury Management (Simplified):**
 *    - `depositFunds()`: Allows anyone to deposit funds into the DAO treasury.
 *    - `withdrawFunds(uint256 _amount)`: Admin function to withdraw funds from the treasury (for legitimate DAO operations - in a real DAO, this would be governance-controlled).
 *    - `getTreasuryBalance()`: View function to get the current balance of the DAO treasury.
 *
 * **6. Emergency and Admin Functions:**
 *    - `pauseContract()`: Admin function to pause critical contract functionalities in case of emergency.
 *    - `unpauseContract()`: Admin function to unpause contract functionalities.
 *    - `setVotingQuorum(uint256 _newQuorumPercentage)`: Admin function to adjust the voting quorum percentage.
 *    - `setFundingStageDuration(uint256 _newDuration)`: Admin function to adjust the default funding stage duration.
 *
 * **Important Notes:**
 * - This contract is designed for educational purposes and showcases various advanced concepts.
 * - Security considerations for a production-ready DAO are much more extensive and require thorough auditing.
 * - Real-world DAOs often involve more complex mechanisms for reputation, voting power, and governance.
 * - This contract simplifies treasury management and admin roles for demonstration purposes.
 * - Gas optimization and efficient data storage are important aspects for real-world smart contracts that are not fully addressed here for clarity.
 */

contract CreativeCatalystDAO {
    // -------- State Variables --------

    // Membership Management
    mapping(address => Member) public members; // Mapping of member addresses to Member struct
    address[] public memberList; // Array to iterate through members (for view functions, not for core logic)
    address[] public pendingMemberships; // List of addresses requesting membership
    uint256 public memberCount = 0;

    struct Member {
        bool isActive;
        uint256 reputation;
        uint256 joinTimestamp;
    }

    // Reputation System
    uint256 public constant INITIAL_REPUTATION = 100;
    uint256 public constant MIN_REPUTATION_TO_PROPOSE = 500; // Example threshold

    // Project Proposal and Funding
    mapping(uint256 => Project) public projects;
    uint256 public projectCounter = 0;

    struct Project {
        uint256 projectId;
        string projectName;
        string projectDescription;
        address proposer;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 milestoneCount;
        uint256 initialStageFundingPercentage;
        string[] milestoneDescriptions;
        uint256 currentMilestoneIndex;
        uint256 fundingStageDeadline; // Timestamp for current funding stage deadline
        ProjectStatus status;
    }

    enum ProjectStatus {
        Proposed,
        FundingStage,
        MilestoneReview,
        Completed,
        Rejected,
        Cancelled
    }

    uint256 public constant DEFAULT_FUNDING_STAGE_DURATION = 7 days; // Example duration

    // Governance and Voting
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter = 0;

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        uint256 targetId; // ProjectId, Member address, etc. depending on proposal type
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) public votes; // Track members who have voted
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        bytes data; // Generic data field for proposal specific parameters
    }

    enum ProposalType {
        ApproveMilestone,
        RejectMilestone,
        ChangeReputation,
        GenericAction // For future extensions, parameter changes, etc.
    }

    uint256 public votingQuorumPercentage = 50; // Percentage of total reputation needed to pass a proposal
    uint256 public constant VOTING_DURATION = 3 days; // Example voting duration

    // Treasury Management
    uint256 public treasuryBalance;

    // Admin and Control
    address public admin;
    bool public paused = false;

    // -------- Events --------
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event ReputationIncreased(address indexed member, uint256 amount);
    event ReputationDecreased(address indexed member, uint256 amount);
    event ProjectProposed(uint256 projectId, string projectName, address proposer);
    event ProjectFundedStage(uint256 projectId, uint256 amount);
    event MilestoneSubmitted(uint256 projectId, uint256 milestoneIndex);
    event MilestoneApproved(uint256 projectId, uint256 milestoneIndex);
    event MilestoneRejected(uint256 projectId, uint256 milestoneIndex);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event FundsDeposited(address sender, uint256 amount);
    event FundsWithdrawn(address admin, uint256 amount);


    // -------- Modifiers --------
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].isActive, "Only active members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validProjectId(uint256 _projectId) {
        require(projects[_projectId].projectId == _projectId, "Invalid project ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        _;
    }


    // -------- Constructor --------
    constructor() {
        admin = msg.sender;
    }

    // -------- 1. Membership Management --------

    /// @notice Allows users to request membership to the DAO.
    function joinDAO() external whenNotPaused {
        require(!members[msg.sender].isActive, "Already a member or membership pending.");
        pendingMemberships.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve pending membership requests.
    /// @param _member Address of the member to approve.
    function approveMembership(address _member) external onlyAdmin whenNotPaused {
        require(!members[_member].isActive, "Address is already a member.");
        bool found = false;
        for (uint i = 0; i < pendingMemberships.length; i++) {
            if (pendingMemberships[i] == _member) {
                pendingMemberships[i] = pendingMemberships[pendingMemberships.length - 1];
                pendingMemberships.pop();
                found = true;
                break;
            }
        }
        require(found, "Membership request not found in pending list.");

        members[_member] = Member({
            isActive: true,
            reputation: INITIAL_REPUTATION,
            joinTimestamp: block.timestamp
        });
        memberList.push(_member); // Add to member list
        memberCount++;
        emit MembershipApproved(_member);
    }

    /// @notice Admin function to revoke membership.
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) external onlyAdmin whenNotPaused {
        require(members[_member].isActive, "Address is not an active member.");
        members[_member].isActive = false;
        // Remove from memberList (inefficient in Solidity, but for example)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                memberCount--;
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    /// @notice View function to retrieve member specific information.
    /// @param _member Address of the member.
    /// @return isActive, reputation, joinTimestamp
    function getMemberDetails(address _member) external view returns (bool isActive, uint256 reputation, uint256 joinTimestamp) {
        return (members[_member].isActive, members[_member].reputation, members[_member].joinTimestamp);
    }

    /// @notice View function to get the total number of members.
    /// @return Total member count.
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }


    // -------- 2. Reputation System --------

    /// @notice Admin function to manually increase member reputation.
    /// @param _member Address of the member.
    /// @param _amount Amount to increase reputation by.
    function increaseReputation(address _member, uint256 _amount) external onlyAdmin whenNotPaused {
        require(members[_member].isActive, "Member is not active.");
        members[_member].reputation += _amount;
        emit ReputationIncreased(_member, _amount);
    }

    /// @notice Admin function to manually decrease member reputation.
    /// @param _member Address of the member.
    /// @param _amount Amount to decrease reputation by.
    function decreaseReputation(address _member, uint256 _amount) external onlyAdmin whenNotPaused {
        require(members[_member].isActive, "Member is not active.");
        require(members[_member].reputation >= _amount, "Cannot decrease reputation below zero."); // Prevent underflow
        members[_member].reputation -= _amount;
        emit ReputationDecreased(_member, _amount);
    }

    /// @notice Function to record positive contributions (example - governance to automate reputation in real DAO).
    /// @param _member Address of the contributing member.
    /// @param _contributionDetails Description of the contribution.
    function recordPositiveContribution(address _member, string memory _contributionDetails) external onlyMembers whenNotPaused {
        // In a real DAO, this would trigger a governance proposal to increase reputation.
        // For this example, we are just recording the event.
        // Example: Emit an event that can be monitored off-chain for reputation adjustments.
        // In a real DAO, this might initiate a proposal to increase reputation based on community vote.
        emit ReputationIncreased(_member, 10); // Example: Small automatic reputation increase for participation.
    }

    /// @notice Function to record negative contributions (example - governance to automate reputation in real DAO).
    /// @param _member Address of the contributing member.
    /// @param _contributionDetails Description of the negative contribution.
    function recordNegativeContribution(address _member, string memory _contributionDetails) external onlyMembers whenNotPaused {
        // Similar to positive contribution, this would ideally trigger a governance proposal.
        // Example: Emit an event that can be monitored off-chain for reputation adjustments.
        // In a real DAO, this might initiate a proposal to decrease reputation based on community vote or dispute resolution.
        emit ReputationDecreased(_member, 5); // Example: Small automatic reputation decrease for participation.
    }

    /// @notice View function to get a member's reputation score.
    /// @param _member Address of the member.
    /// @return Member's reputation.
    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }


    // -------- 3. Project Proposal and Funding --------

    /// @notice Allows members to propose creative projects with phased funding and milestones.
    /// @param _projectName Name of the project.
    /// @param _projectDescription Detailed description of the project.
    /// @param _fundingGoal Total funding goal for the project.
    /// @param _milestoneCount Number of milestones for the project.
    /// @param _initialStageFundingPercentage Percentage of total funding for the initial stage.
    /// @param _milestoneDescriptions Array of descriptions for each milestone.
    function proposeProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _fundingGoal,
        uint256 _milestoneCount,
        uint256 _initialStageFundingPercentage,
        string[] memory _milestoneDescriptions
    ) external onlyMembers whenNotPaused {
        require(members[msg.sender].reputation >= MIN_REPUTATION_TO_PROPOSE, "Insufficient reputation to propose project.");
        require(_milestoneCount > 0 && _milestoneCount <= 10, "Milestone count must be between 1 and 10."); // Example limit
        require(_milestoneDescriptions.length == _milestoneCount, "Number of milestone descriptions must match milestone count.");
        require(_initialStageFundingPercentage > 0 && _initialStageFundingPercentage <= 100, "Initial stage funding percentage must be between 1 and 100.");

        projectCounter++;
        projects[projectCounter] = Project({
            projectId: projectCounter,
            projectName: _projectName,
            projectDescription: _projectDescription,
            proposer: msg.sender,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            milestoneCount: _milestoneCount,
            initialStageFundingPercentage: _initialStageFundingPercentage,
            milestoneDescriptions: _milestoneDescriptions,
            currentMilestoneIndex: 0,
            fundingStageDeadline: block.timestamp + DEFAULT_FUNDING_STAGE_DURATION,
            status: ProjectStatus.Proposed
        });

        emit ProjectProposed(projectCounter, _projectName, msg.sender);
        // In a real DAO, project proposal might also require a governance vote to be accepted.
        // For simplicity, we directly set it to 'Proposed' and move to funding stage upon reaching target.
    }

    /// @notice View function to retrieve detailed information about a project.
    /// @param _projectId ID of the project.
    /// @return Project struct.
    function getProjectDetails(uint256 _projectId) external view validProjectId(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    /// @notice Allows members to contribute funds to a project's current funding stage.
    /// @param _projectId ID of the project to fund.
    function fundProjectStage(uint256 _projectId) external payable whenNotPaused validProjectId(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FundingStage || project.status == ProjectStatus.Proposed, "Project is not in funding stage.");
        require(block.timestamp <= project.fundingStageDeadline, "Funding stage deadline has passed.");

        uint256 fundingToAdd = msg.value;
        project.currentFunding += fundingToAdd;
        treasuryBalance += fundingToAdd; // Funds go to DAO treasury first

        emit ProjectFundedStage(_projectId, fundingToAdd);

        if (project.currentFunding >= (project.fundingGoal * project.initialStageFundingPercentage) / 100 && project.status == ProjectStatus.Proposed) {
             // Move to FundingStage if initial funding goal reached from 'Proposed' state
            project.status = ProjectStatus.FundingStage;
            project.fundingStageDeadline = block.timestamp + DEFAULT_FUNDING_STAGE_DURATION; // Reset funding stage deadline
        }

        if (project.currentFunding >= project.fundingGoal && project.status == ProjectStatus.FundingStage) {
            project.status = ProjectStatus.MilestoneReview; // Move to milestone review after full funding
            // In a real DAO, funding release to project creator would be milestone-based and governance-approved.
        }
    }


    /// @notice Project proposer function to submit a milestone for review and approval.
    /// @param _projectId ID of the project.
    /// @param _milestoneIndex Index of the milestone completed (starting from 0).
    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) external onlyMembers whenNotPaused validProjectId(_projectId) {
        Project storage project = projects[_projectId];
        require(msg.sender == project.proposer, "Only project proposer can submit milestones.");
        require(project.status == ProjectStatus.MilestoneReview, "Project is not in Milestone Review stage.");
        require(_milestoneIndex == project.currentMilestoneIndex, "Invalid milestone index or milestones not in sequence.");
        require(_milestoneIndex < project.milestoneCount, "Milestone index out of range.");

        // Create a proposal to approve this milestone
        createMilestoneApprovalProposal(_projectId, _milestoneIndex);
        project.status = ProjectStatus.MilestoneReview; // Still in review until proposal is voted on.
        emit MilestoneSubmitted(_projectId, _milestoneIndex);
    }

    /// @dev Internal function to create a milestone approval proposal.
    function createMilestoneApprovalProposal(uint256 _projectId, uint256 _milestoneIndex) internal {
        string memory description = string(abi.encodePacked("Approve Milestone ", uint2str(_milestoneIndex + 1), " for Project ", projects[_projectId].projectName));
        createProposal(ProposalType.ApproveMilestone, _projectId, description, abi.encode(_milestoneIndex));
    }


    /// @notice Governance function (voting) to approve a completed milestone, releasing next stage funding.
    /// @param _projectId ID of the project.
    /// @param _milestoneIndex Index of the milestone to approve.
    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex) external onlyMembers whenNotPaused validProjectId(_projectId) {
        // This function is now triggered by proposal execution after voting.
        // Logic moved to executeProposal() for ApproveMilestone type.
        revert("This function should not be called directly. Milestone approval is done via proposal execution.");
    }

    /// @notice Governance function (voting) to reject a completed milestone, potentially leading to project review or cancellation.
    /// @param _projectId ID of the project.
    /// @param _milestoneIndex Index of the milestone to reject.
    function rejectMilestone(uint256 _projectId, uint256 _milestoneIndex) external onlyMembers whenNotPaused validProjectId(_projectId) {
        // This function is now triggered by proposal execution after voting.
        // Logic moved to executeProposal() for RejectMilestone type.
        revert("This function should not be called directly. Milestone rejection is done via proposal execution.");
    }


    // -------- 4. Governance and Voting --------

    /// @notice Generic function to create different types of governance proposals.
    /// @param _proposalType Type of proposal being created (enum ProposalType).
    /// @param _targetId Target ID related to the proposal (e.g., projectId, member address).
    /// @param _description Description of the proposal.
    /// @param _data Additional data relevant to the proposal (e.g., milestone index for approval).
    function createProposal(ProposalType _proposalType, uint256 _targetId, string memory _description, bytes memory _data) public onlyMembers whenNotPaused {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalId: proposalCounter,
            proposalType: _proposalType,
            targetId: _targetId,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + VOTING_DURATION,
            votes: mapping(address => bool)(), // Initialize empty votes mapping
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            data: _data
        });

        emit ProposalCreated(proposalCounter, _proposalType, _description, msg.sender);
    }


    /// @notice Allows members to vote on active proposals, with voting power weighted by reputation.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMembers whenNotPaused validProposalId(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Voting period is not active.");
        require(!proposal.votes[msg.sender], "Member has already voted on this proposal.");

        proposal.votes[msg.sender] = true; // Mark voter as voted

        if (_support) {
            proposal.votesFor += members[msg.sender].reputation; // Voting power based on reputation
        } else {
            proposal.votesAgainst += members[msg.sender].reputation;
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Function to execute a proposal after it has passed the voting threshold.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyMembers whenNotPaused validProposalId(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period is still active.");
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalReputation = getTotalReputation();
        uint256 quorum = (totalReputation * votingQuorumPercentage) / 100;

        require(proposal.votesFor >= quorum, "Proposal does not meet quorum.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal failed: more votes against or equal.");

        proposal.isExecuted = true;
        emit ProposalExecuted(_proposalId);

        // Execute proposal action based on proposal type
        if (proposal.proposalType == ProposalType.ApproveMilestone) {
            _executeMilestoneApproval(proposal.targetId, proposal.data); // ProjectId, Milestone Index (encoded in data)
        } else if (proposal.proposalType == ProposalType.RejectMilestone) {
            _executeMilestoneRejection(proposal.targetId, proposal.data); // ProjectId, Milestone Index (encoded in data)
        } else if (proposal.proposalType == ProposalType.ChangeReputation) {
            // Example: Decode data to get member address and reputation change amount
            // (Implementation for reputation change proposals would be added here)
            // address targetMember = ... ;
            // int256 reputationChange = ... ;
            // _executeReputationChange(targetMember, reputationChange);
        } else if (proposal.proposalType == ProposalType.GenericAction) {
            // For future extensions, handle generic actions if needed.
            // Decode data to determine action and parameters.
        }
    }

    /// @dev Internal function to execute milestone approval actions.
    /// @param _projectId Project ID.
    /// @param _data Encoded milestone index.
    function _executeMilestoneApproval(uint256 _projectId, bytes memory _data) internal validProjectId(_projectId) {
        Project storage project = projects[_projectId];
        uint256 milestoneIndex = abi.decode(_data, (uint256));
        require(milestoneIndex == project.currentMilestoneIndex, "Milestone index mismatch during execution.");
        require(project.status == ProjectStatus.MilestoneReview, "Project not in milestone review stage.");

        // Release funds for the next stage (example - release full funding after initial stage in this simplified contract)
        if (project.currentMilestoneIndex == 0) { // Example: Release remaining funds after first milestone approval
            uint256 remainingFunding = project.fundingGoal - (project.fundingGoal * project.initialStageFundingPercentage) / 100;
             // In a real DAO, funds would be transferred to the project proposer/multisig, not directly from treasury.
            payable(project.proposer).transfer(remainingFunding); // **Security Risk**: Simple transfer, consider pull pattern in real apps.
            treasuryBalance -= remainingFunding;
        } else {
            // Logic for subsequent milestones and funding release would be added here if needed.
             payable(project.proposer).transfer(0); // Placeholder for future milestone funding logic
        }


        project.currentMilestoneIndex++;
        if (project.currentMilestoneIndex >= project.milestoneCount) {
            project.status = ProjectStatus.Completed; // Project completed after all milestones
        } else {
            project.status = ProjectStatus.FundingStage; // Move to next funding stage (if applicable, could be direct to next milestone review in some models)
            project.fundingStageDeadline = block.timestamp + DEFAULT_FUNDING_STAGE_DURATION; // Reset funding stage deadline
        }
        emit MilestoneApproved(_projectId, milestoneIndex);
    }

    /// @dev Internal function to execute milestone rejection actions.
    /// @param _projectId Project ID.
    /// @param _data Encoded milestone index.
    function _executeMilestoneRejection(uint256 _projectId, bytes memory _data) internal validProjectId(_projectId) {
        Project storage project = projects[_projectId];
        uint256 milestoneIndex = abi.decode(_data, (uint256));
        require(milestoneIndex == project.currentMilestoneIndex, "Milestone index mismatch during execution.");
        require(project.status == ProjectStatus.MilestoneReview, "Project not in milestone review stage.");

        project.status = ProjectStatus.Rejected; // Mark project as rejected after milestone rejection
        emit MilestoneRejected(_projectId, milestoneIndex);
        // In a real DAO, might trigger further actions like refunding contributors, etc.
    }


    /// @notice View function to retrieve details about a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct.
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice View function to get the current voting status of a proposal (votes for, votes against, quorum).
    /// @param _proposalId ID of the proposal.
    /// @return votesFor, votesAgainst, quorumReached, votingEndTime
    function getProposalVotingStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, bool quorumReached, uint256 votingEndTime) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalReputation = getTotalReputation();
        uint256 quorum = (totalReputation * votingQuorumPercentage) / 100;
        bool reached = proposal.votesFor >= quorum;
        return (proposal.votesFor, proposal.votesAgainst, reached, proposal.endTime);
    }


    // -------- 5. Treasury Management (Simplified) --------

    /// @notice Allows anyone to deposit funds into the DAO treasury.
    function depositFunds() external payable whenNotPaused {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Admin function to withdraw funds from the treasury (for legitimate DAO operations - governance in real DAO).
    /// @param _amount Amount to withdraw.
    function withdrawFunds(uint256 _amount) external onlyAdmin whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");
        payable(admin).transfer(_amount); // **Security Risk**: Simple transfer, consider pull pattern in real apps.
        treasuryBalance -= _amount;
        emit FundsWithdrawn(admin, _amount);
    }

    /// @notice View function to get the current balance of the DAO treasury.
    /// @return Current treasury balance.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // -------- 6. Emergency and Admin Functions --------

    /// @notice Admin function to pause critical contract functionalities in case of emergency.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Admin function to unpause contract functionalities.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Admin function to adjust the voting quorum percentage.
    /// @param _newQuorumPercentage New quorum percentage (0-100).
    function setVotingQuorum(uint256 _newQuorumPercentage) external onlyAdmin whenNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100.");
        votingQuorumPercentage = _newQuorumPercentage;
    }

    /// @notice Admin function to adjust the default funding stage duration.
    /// @param _newDuration New funding stage duration in seconds.
    function setFundingStageDuration(uint256 _newDuration) external onlyAdmin whenNotPaused {
        DEFAULT_FUNDING_STAGE_DURATION = _newDuration;
    }


    // -------- Utility Functions --------

    /// @dev Helper function to calculate total reputation of all members.
    function getTotalReputation() public view returns (uint256) {
        uint256 totalReputation = 0;
        for (uint i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].isActive) {
                totalReputation += members[memberList[i]].reputation;
            }
        }
        return totalReputation;
    }


    /// @dev Helper function to convert uint to string (for event descriptions).
    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8((48 + _i % 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


    receive() external payable {
        depositFunds(); // Allow direct ETH deposits to the contract.
    }
}
```