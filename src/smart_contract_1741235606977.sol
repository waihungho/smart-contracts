```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CreativeProjectDAO - Decentralized Autonomous Organization for Creative Projects
 * @author Bard (AI Assistant)
 * @dev This contract implements a DAO focused on funding, managing, and rewarding creative projects.
 *      It incorporates advanced concepts like dynamic membership, skill-based roles, milestone-based funding,
 *      reputation system, decentralized dispute resolution, and tokenized rewards.
 *
 * **Outline and Function Summary:**
 *
 * **Core DAO Functions:**
 * 1. `joinDAO(string _profileURI)`: Allows users to request membership in the DAO, providing a profile URI.
 * 2. `approveMembership(address _member)`: Admin-only function to approve a pending membership request.
 * 3. `rejectMembership(address _member)`: Admin-only function to reject a pending membership request.
 * 4. `leaveDAO()`: Allows a member to voluntarily leave the DAO.
 * 5. `proposeProject(string _projectName, string _projectDescriptionURI, uint256 _fundingGoal, string[] memory _milestoneDescriptions, uint256[] memory _milestoneFunding)`: Members can propose creative projects with milestones and funding goals.
 * 6. `voteOnProjectProposal(uint256 _projectId, bool _vote)`: Members can vote on project proposals.
 * 7. `executeProject(uint256 _projectId)`: Admin/Project Lead can execute a project after proposal passes.
 * 8. `submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`: Project Lead submits a milestone for review.
 * 9. `voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _vote)`: Members vote on milestone completion.
 * 10. `releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex)`: Admin/Project Lead releases funds for a completed and approved milestone.
 * 11. `cancelProject(uint256 _projectId)`: Admin-only function to cancel a project and return remaining funds.
 * 12. `depositFunds()`: Allows anyone to deposit funds into the DAO treasury.
 * 13. `withdrawFunds(uint256 _amount)`: Admin-only function to withdraw funds from the treasury (for DAO operations, etc.).
 *
 * **Advanced & Creative Functions:**
 * 14. `assignSkillRole(address _member, string _skill)`: Admin-only function to assign a skill role to a member (e.g., 'Artist', 'Developer', 'Marketing').
 * 15. `requestSkillRole(string _skill)`: Members can request a specific skill role.
 * 16. `approveSkillRoleRequest(address _member, string _skill)`: Admin-only function to approve a skill role request.
 * 17. `endorseMemberSkill(address _member, string _skill)`: Members can endorse another member's skill, contributing to their reputation.
 * 18. `reportProjectIssue(uint256 _projectId, string _issueDescriptionURI)`: Members can report issues with a project, triggering dispute resolution.
 * 19. `startDisputeResolution(uint256 _projectId)`: Admin-only function to initiate dispute resolution for a project.
 * 20. `voteOnDisputeResolution(uint256 _projectId, bool _resolution)`: Members vote on a proposed resolution for a project dispute.
 * 21. `rewardContributor(address _contributor, uint256 _amount, string _rewardReason)`: Project Lead can reward contributors for their work (beyond milestone completion).
 * 22. `setAdmin(address _newAdmin)`: Admin-only function to change the DAO administrator.
 * 23. `getMemberProfileURI(address _member)`:  View function to retrieve a member's profile URI.
 * 24. `getProjectDetails(uint256 _projectId)`: View function to retrieve detailed information about a project.
 * 25. `getSkillRolesOfMember(address _member)`: View function to get skill roles assigned to a member.
 * 26. `getMemberReputation(address _member)`: View function to get a member's reputation score.
 *
 * **Events:**
 * - `MembershipRequested(address member)`
 * - `MembershipApproved(address member)`
 * - `MembershipRejected(address member)`
 * - `MemberLeft(address member)`
 * - `ProjectProposed(uint256 projectId, address proposer, string projectName)`
 * - `ProjectVoteCast(uint256 projectId, address voter, bool vote)`
 * - `ProjectExecuted(uint256 projectId)`
 * - `MilestoneSubmitted(uint256 projectId, uint256 milestoneIndex)`
 * - `MilestoneVoteCast(uint256 projectId, uint256 milestoneIndex, address voter, bool vote)`
 * - `MilestoneFundsReleased(uint256 projectId, uint256 milestoneIndex)`
 * - `ProjectCancelled(uint256 projectId)`
 * - `FundsDeposited(address depositor, uint256 amount)`
 * - `FundsWithdrawn(address admin, uint256 amount)`
 * - `SkillRoleAssigned(address member, string skill)`
 * - `SkillRoleRequested(address member, string skill)`
 * - `SkillRoleRequestApproved(address member, string skill)`
 * - `SkillEndorsed(address endorser, address endorsedMember, string skill)`
 * - `ProjectIssueReported(uint256 projectId, address reporter, string issueDescriptionURI)`
 * - `DisputeResolutionStarted(uint256 projectId)`
 * - `DisputeResolutionVoteCast(uint256 projectId, address voter, bool resolution)`
 * - `ContributorRewarded(address contributor, uint256 amount, string rewardReason)`
 * - `AdminChanged(address newAdmin)`
 */
contract CreativeProjectDAO {
    address public admin;
    uint256 public projectIdCounter;
    uint256 public treasuryBalance;

    mapping(address => bool) public members;
    mapping(address => bool) public pendingMemberships;
    mapping(address => string) public memberProfileURIs;
    mapping(address => mapping(string => bool)) public memberSkillRoles; // Member -> Skill -> HasRole
    mapping(address => uint256) public memberReputation; // Basic reputation score

    struct Project {
        uint256 id;
        address proposer;
        string name;
        string descriptionURI;
        uint256 fundingGoal;
        uint256 fundedAmount;
        bool executed;
        bool cancelled;
        Milestone[] milestones;
        mapping(address => bool) votes; // For project proposal voting
        uint256 yesVotes;
        uint256 noVotes;
        bool proposalPassed;
        bool disputeResolutionActive;
        mapping(address => bool) disputeResolutionVotes; // For dispute resolution voting
        uint256 disputeResolutionYesVotes;
        uint256 disputeResolutionNoVotes;
        bool disputeResolutionPassed;
    }

    struct Milestone {
        string description;
        uint256 fundingAmount;
        bool completed;
        bool fundsReleased;
        mapping(address => bool) completionVotes; // For milestone completion voting
        uint256 completionYesVotes;
        uint256 completionNoVotes;
        bool completionPassed;
    }

    mapping(uint256 => Project) public projects;
    mapping(address => mapping(string => bool)) public skillRoleRequests; // Member -> Skill -> Requested

    uint256 public votingDuration = 7 days; // Example voting duration
    uint256 public quorumPercentage = 50; // Example quorum percentage for proposals

    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRejected(address member);
    event MemberLeft(address member);
    event ProjectProposed(uint256 projectId, address proposer, string projectName);
    event ProjectVoteCast(uint256 projectId, address voter, bool vote);
    event ProjectExecuted(uint256 projectId);
    event MilestoneSubmitted(uint256 projectId, uint256 milestoneIndex);
    event MilestoneVoteCast(uint256 projectId, uint256 milestoneIndex, address voter, bool vote);
    event MilestoneFundsReleased(uint256 projectId, uint256 milestoneIndex);
    event ProjectCancelled(uint256 projectId);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address admin, uint256 amount);
    event SkillRoleAssigned(address member, string skill);
    event SkillRoleRequested(address member, string skill);
    event SkillRoleRequestApproved(address member, string skill);
    event SkillEndorsed(address endorser, address endorsedMember, string skill);
    event ProjectIssueReported(uint256 projectId, address reporter, string issueDescriptionURI);
    event DisputeResolutionStarted(uint256 projectId);
    event DisputeResolutionVoteCast(uint256 projectId, address voter, bool resolution);
    event ContributorRewarded(address contributor, uint256 amount, string rewardReason);
    event AdminChanged(address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only DAO members can call this function.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId < projectIdCounter && projects[_projectId].id == _projectId, "Project does not exist.");
        _;
    }

    modifier milestoneExists(uint256 _projectId, uint256 _milestoneIndex) {
        require(_milestoneIndex < projects[_projectId].milestones.length, "Milestone does not exist.");
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "Only project proposer can call this function.");
        _;
    }

    modifier projectNotExecuted(uint256 _projectId) {
        require(!projects[_projectId].executed, "Project already executed.");
        _;
    }

    modifier projectNotCancelled(uint256 _projectId) {
        require(!projects[_projectId].cancelled, "Project already cancelled.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /**
     * @dev Allows users to request membership in the DAO.
     * @param _profileURI URI pointing to the member's profile information (e.g., IPFS hash).
     */
    function joinDAO(string memory _profileURI) external {
        require(!members[msg.sender] && !pendingMemberships[msg.sender], "Already a member or membership pending.");
        pendingMemberships[msg.sender] = true;
        memberProfileURIs[msg.sender] = _profileURI;
        emit MembershipRequested(msg.sender);
    }

    /**
     * @dev Admin-only function to approve a pending membership request.
     * @param _member Address of the member to approve.
     */
    function approveMembership(address _member) external onlyAdmin {
        require(pendingMemberships[_member], "Membership not pending for this address.");
        delete pendingMemberships[_member];
        members[_member] = true;
        emit MembershipApproved(_member);
    }

    /**
     * @dev Admin-only function to reject a pending membership request.
     * @param _member Address of the member to reject.
     */
    function rejectMembership(address _member) external onlyAdmin {
        require(pendingMemberships[_member], "Membership not pending for this address.");
        delete pendingMemberships[_member];
        delete memberProfileURIs[_member]; // Optionally remove profile URI on rejection
        emit MembershipRejected(_member);
    }

    /**
     * @dev Allows a member to voluntarily leave the DAO.
     */
    function leaveDAO() external onlyMembers {
        delete members[msg.sender];
        delete memberProfileURIs[msg.sender];
        // Optionally remove skill roles and reputation?  Decide based on DAO logic
        emit MemberLeft(msg.sender);
    }

    /**
     * @dev Members can propose creative projects with milestones and funding goals.
     * @param _projectName Name of the project.
     * @param _projectDescriptionURI URI pointing to the project description (e.g., IPFS hash).
     * @param _fundingGoal Total funding goal for the project.
     * @param _milestoneDescriptions Array of descriptions for each milestone.
     * @param _milestoneFunding Array of funding amounts for each milestone, corresponding to descriptions.
     */
    function proposeProject(
        string memory _projectName,
        string memory _projectDescriptionURI,
        uint256 _fundingGoal,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneFunding
    ) external onlyMembers {
        require(_milestoneDescriptions.length == _milestoneFunding.length, "Milestone descriptions and funding arrays must have the same length.");
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(_milestoneDescriptions.length > 0, "At least one milestone is required.");

        Project storage newProject = projects[projectIdCounter];
        newProject.id = projectIdCounter;
        newProject.proposer = msg.sender;
        newProject.name = _projectName;
        newProject.descriptionURI = _projectDescriptionURI;
        newProject.fundingGoal = _fundingGoal;
        newProject.milestones = new Milestone[](_milestoneDescriptions.length);

        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            newProject.milestones[i] = Milestone({
                description: _milestoneDescriptions[i],
                fundingAmount: _milestoneFunding[i],
                completed: false,
                fundsReleased: false,
                completionYesVotes: 0,
                completionNoVotes: 0,
                completionPassed: false
            });
        }

        projectIdCounter++;
        emit ProjectProposed(newProject.id, msg.sender, _projectName);
    }

    /**
     * @dev Members can vote on project proposals.
     * @param _projectId ID of the project to vote on.
     * @param _vote Boolean vote - true for yes, false for no.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _vote) external onlyMembers projectExists(_projectId) projectNotExecuted(_projectId) projectNotCancelled(_projectId) {
        Project storage project = projects[_projectId];
        require(!project.votes[msg.sender], "Member already voted on this project.");
        project.votes[msg.sender] = true;

        if (_vote) {
            project.yesVotes++;
        } else {
            project.noVotes++;
        }
        emit ProjectVoteCast(_projectId, msg.sender, _vote);

        // Check if voting period is over (simplified example, in real contract use block.timestamp and a voting deadline)
        // For simplicity, auto-pass if enough votes are cast (not ideal for real-world, but demonstrates functionality)
        uint256 totalVotes = project.yesVotes + project.noVotes;
        uint256 memberCount = 0;
        for(address memberAddress in members) { // Iterate through members - inefficient in practice for large DAO, use better membership tracking
            if (members[memberAddress]) {
                memberCount++;
            }
        }
        if (totalVotes >= (memberCount * quorumPercentage) / 100) { // Simple quorum check
            if (project.yesVotes > project.noVotes) {
                project.proposalPassed = true;
            }
        }
    }

    /**
     * @dev Admin/Project Lead can execute a project after proposal passes.
     * @param _projectId ID of the project to execute.
     */
    function executeProject(uint256 _projectId) external projectExists(_projectId) projectNotExecuted(_projectId) projectNotCancelled(_projectId) {
        Project storage project = projects[_projectId];
        require(project.proposalPassed, "Project proposal has not passed voting.");
        require(msg.sender == admin || project.proposer == msg.sender, "Only admin or project proposer can execute."); // Allow admin or proposer to execute
        project.executed = true;
        emit ProjectExecuted(_projectId);
    }

    /**
     * @dev Project Lead submits a milestone for review.
     * @param _projectId ID of the project.
     * @param _milestoneIndex Index of the milestone to submit for completion review.
     */
    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) external onlyMembers projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) milestoneExists(_projectId, _milestoneIndex) onlyProjectProposer(_projectId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(!milestone.completed, "Milestone already marked as completed.");
        milestone.completed = true;
        emit MilestoneSubmitted(_projectId, _milestoneIndex);
    }

    /**
     * @dev Members vote on milestone completion.
     * @param _projectId ID of the project.
     * @param _milestoneIndex Index of the milestone to vote on.
     * @param _vote Boolean vote - true for yes, false for no.
     */
    function voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _vote) external onlyMembers projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) milestoneExists(_projectId, _milestoneIndex) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.completed, "Milestone not yet submitted for completion.");
        require(!milestone.completionVotes[msg.sender], "Member already voted on this milestone completion.");
        milestone.completionVotes[msg.sender] = true;

        if (_vote) {
            milestone.completionYesVotes++;
        } else {
            milestone.completionNoVotes++;
        }
        emit MilestoneVoteCast(_projectId, _milestoneIndex, msg.sender, _vote);

        // Simple auto-pass milestone logic (for demo purposes)
        uint256 totalVotes = milestone.completionYesVotes + milestone.completionNoVotes;
        uint256 memberCount = 0;
        for(address memberAddress in members) {
            if (members[memberAddress]) {
                memberCount++;
            }
        }
        if (totalVotes >= (memberCount * quorumPercentage) / 100) {
            if (milestone.completionYesVotes > milestone.completionNoVotes) {
                milestone.completionPassed = true;
            }
        }
    }

    /**
     * @dev Admin/Project Lead releases funds for a completed and approved milestone.
     * @param _projectId ID of the project.
     * @param _milestoneIndex Index of the milestone to release funds for.
     */
    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) milestoneExists(_projectId, _milestoneIndex) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.completionPassed, "Milestone completion not yet approved by vote.");
        require(!milestone.fundsReleased, "Milestone funds already released.");
        require(treasuryBalance >= milestone.fundingAmount, "Insufficient funds in treasury to release milestone funds.");
        require(msg.sender == admin || project.proposer == msg.sender, "Only admin or project proposer can release funds."); // Allow admin or proposer to release

        treasuryBalance -= milestone.fundingAmount;
        project.fundedAmount += milestone.fundingAmount;
        milestone.fundsReleased = true;
        payable(project.proposer).transfer(milestone.fundingAmount); // Transfer funds to project proposer (project lead)
        emit MilestoneFundsReleased(_projectId, _milestoneIndex);
    }

    /**
     * @dev Admin-only function to cancel a project and return remaining funds to treasury.
     * @param _projectId ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) external onlyAdmin projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) {
        Project storage project = projects[_projectId];
        require(!project.executed, "Cannot cancel an executed project.");
        project.cancelled = true;

        // Return remaining funds to treasury (if any were deposited specifically for this project - not implemented in this basic example)
        // In a more complex scenario, you might track project-specific deposits and return those.
        emit ProjectCancelled(_projectId);
    }

    /**
     * @dev Allows anyone to deposit funds into the DAO treasury.
     */
    function depositFunds() external payable {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Admin-only function to withdraw funds from the treasury (for DAO operations, etc.).
     * @param _amount Amount to withdraw.
     */
    function withdrawFunds(uint256 _amount) external onlyAdmin {
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");
        treasuryBalance -= _amount;
        payable(admin).transfer(_amount);
        emit FundsWithdrawn(admin, _amount);
    }

    /**
     * @dev Admin-only function to assign a skill role to a member.
     * @param _member Address of the member to assign the skill role to.
     * @param _skill Name of the skill role (e.g., 'Artist', 'Developer', 'Marketing').
     */
    function assignSkillRole(address _member, string memory _skill) external onlyAdmin {
        memberSkillRoles[_member][_skill] = true;
        delete skillRoleRequests[_member][_skill]; // Remove any pending request
        emit SkillRoleAssigned(_member, _skill);
    }

    /**
     * @dev Members can request a specific skill role.
     * @param _skill Name of the skill role being requested.
     */
    function requestSkillRole(string memory _skill) external onlyMembers {
        require(!memberSkillRoles[msg.sender][_skill], "Member already has this skill role.");
        require(!skillRoleRequests[msg.sender][_skill], "Skill role request already pending.");
        skillRoleRequests[msg.sender][_skill] = true;
        emit SkillRoleRequested(msg.sender, _skill);
    }

    /**
     * @dev Admin-only function to approve a skill role request.
     * @param _member Address of the member who requested the skill role.
     * @param _skill Name of the skill role being approved.
     */
    function approveSkillRoleRequest(address _member, string memory _skill) external onlyAdmin {
        require(skillRoleRequests[_member][_skill], "Skill role request not pending for this member and skill.");
        assignSkillRole(_member, _skill); // Re-use assignSkillRole for approval logic
        emit SkillRoleRequestApproved(_member, _skill);
    }

    /**
     * @dev Members can endorse another member's skill, contributing to their reputation.
     * @param _member Address of the member whose skill is being endorsed.
     * @param _skill Name of the skill being endorsed.
     */
    function endorseMemberSkill(address _member, string memory _skill) external onlyMembers {
        require(_member != msg.sender, "Cannot endorse your own skill.");
        // In a more advanced system, you might limit endorsements per member/skill/timeframe to prevent abuse.
        memberReputation[_member]++; // Simple reputation increase - can be made more sophisticated
        emit SkillEndorsed(msg.sender, _member, _skill);
    }

    /**
     * @dev Members can report issues with a project, triggering dispute resolution.
     * @param _projectId ID of the project with the issue.
     * @param _issueDescriptionURI URI pointing to the issue description (e.g., IPFS hash).
     */
    function reportProjectIssue(uint256 _projectId, string memory _issueDescriptionURI) external onlyMembers projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) {
        require(!projects[_projectId].disputeResolutionActive, "Dispute resolution already active for this project.");
        // In a real system, you might want to limit issue reporting to specific project phases or roles.
        // For simplicity, any member can report an issue.
        projects[_projectId].disputeResolutionActive = true;
        emit ProjectIssueReported(_projectId, msg.sender, _issueDescriptionURI);
    }

    /**
     * @dev Admin-only function to initiate dispute resolution for a project.
     * @param _projectId ID of the project to start dispute resolution for.
     */
    function startDisputeResolution(uint256 _projectId) external onlyAdmin projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) {
        Project storage project = projects[_projectId];
        require(project.disputeResolutionActive, "No active dispute reported for this project."); // Ensure issue was reported first
        emit DisputeResolutionStarted(_projectId);
        // Dispute resolution process would involve further steps, potentially with external oracles or dispute resolvers.
        // This example implements a simple DAO vote for resolution.
    }

    /**
     * @dev Members vote on a proposed resolution for a project dispute.
     * @param _projectId ID of the project in dispute.
     * @param _resolution Boolean vote - true for approving the resolution, false for rejecting.
     */
    function voteOnDisputeResolution(uint256 _projectId, bool _resolution) external onlyMembers projectExists(_projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) {
        Project storage project = projects[_projectId];
        require(project.disputeResolutionActive, "Dispute resolution is not active for this project.");
        require(!project.disputeResolutionVotes[msg.sender], "Member already voted on this dispute resolution.");
        project.disputeResolutionVotes[msg.sender] = true;

        if (_resolution) {
            project.disputeResolutionYesVotes++;
        } else {
            project.disputeResolutionNoVotes++;
        }
        emit DisputeResolutionVoteCast(_projectId, msg.sender, _resolution);

        // Simple dispute resolution outcome logic (for demo purposes)
        uint256 totalVotes = project.disputeResolutionYesVotes + project.disputeResolutionNoVotes;
        uint256 memberCount = 0;
        for(address memberAddress in members) {
            if (members[memberAddress]) {
                memberCount++;
            }
        }
        if (totalVotes >= (memberCount * quorumPercentage) / 100) {
            if (project.disputeResolutionYesVotes > project.disputeResolutionNoVotes) {
                project.disputeResolutionPassed = true;
                // Dispute resolution passed - implement resolution logic here (e.g., refund, project modification, etc.)
                // For this example, just set a flag.
            } else {
                project.disputeResolutionPassed = false;
                // Dispute resolution failed - handle accordingly
            }
            project.disputeResolutionActive = false; // End dispute resolution process after voting
        }
    }

    /**
     * @dev Project Lead can reward contributors for their work (beyond milestone completion).
     * @param _contributor Address of the contributor to reward.
     * @param _amount Amount to reward.
     * @param _rewardReason Reason for the reward (e.g., 'Exceptional contribution', 'Bug fix').
     */
    function rewardContributor(address _contributor, uint256 _amount, string memory _rewardReason) external onlyMembers projectExists(uint256 _projectId) projectNotCancelled(_projectId) projectNotExecuted(_projectId) onlyProjectProposer(_projectId) {
        require(treasuryBalance >= _amount, "Insufficient funds in treasury for reward.");
        treasuryBalance -= _amount;
        payable(_contributor).transfer(_amount);
        emit ContributorRewarded(_contributor, _amount, _rewardReason);
    }

    /**
     * @dev Admin-only function to change the DAO administrator.
     * @param _newAdmin Address of the new administrator.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev View function to retrieve a member's profile URI.
     * @param _member Address of the member.
     * @return Profile URI of the member.
     */
    function getMemberProfileURI(address _member) external view returns (string memory) {
        return memberProfileURIs[_member];
    }

    /**
     * @dev View function to retrieve detailed information about a project.
     * @param _projectId ID of the project.
     * @return Project struct containing project details.
     */
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    /**
     * @dev View function to get skill roles assigned to a member.
     * @param _member Address of the member.
     * @return Array of skill role names.
     */
    function getSkillRolesOfMember(address _member) external view returns (string[] memory) {
        string[] memory roles = new string[](0);
        uint256 roleCount = 0;
        for (uint256 i = 0; i < 20; i++) { // Iterate through a reasonable number of potential skill names - not ideal for scalability, use better approach in real system
            string memory skillName;
            if (i == 0) skillName = "Artist";
            else if (i == 1) skillName = "Developer";
            else if (i == 2) skillName = "Marketing";
            else if (i == 3) skillName = "Writer";
            else if (i == 4) skillName = "Designer";
            else if (i == 5) skillName = "Musician";
            else if (i == 6) skillName = "Producer";
            else if (i == 7) skillName = "Animator";
            else if (i == 8) skillName = "Illustrator";
            else if (i == 9) skillName = "SoundEngineer";
            else if (i == 10) skillName = "CommunityManager";
            else if (i == 11) skillName = "Strategist";
            else if (i == 12) skillName = "Analyst";
            else if (i == 13) skillName = "Editor";
            else if (i == 14) skillName = "Curator";
            else if (i == 15) skillName = "SocialMedia";
            else if (i == 16) skillName = "ProjectManager";
            else if (i == 17) skillName = "Researcher";
            else if (i == 18) skillName = "Tester";
            else if (i == 19) skillName = "UXDesigner";
            else break; // Exit if skillName is not set (reached end of predefined skills)


            if (memberSkillRoles[_member][skillName]) {
                assembly {
                    let arrayPtr := mload(roles)
                    let arrayLen := mload(arrayPtr)
                    mstore(arrayPtr, add(arrayLen, 1)) // Increment array length
                    let newElementPtr := add(arrayPtr, mul(add(arrayLen, 1), 0x20)) // Calculate pointer to new element
                    mstore(newElementPtr, mload(skillName)) // Copy string data (assuming 32-byte string representation)
                    mstore(add(newElementPtr, 0x20), mload(add(skillName, 0x20))) // Copy string data (assuming 32-byte string representation) - adjust for string length if needed
                }
                roleCount++;
            }
        }
        return roles;
    }


    /**
     * @dev View function to get a member's reputation score.
     * @param _member Address of the member.
     * @return Member's reputation score.
     */
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }
}
```