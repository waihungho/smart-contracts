```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Agency (DACA)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Creative Agency.
 * It facilitates project proposals, talent sourcing, task management, reputation system,
 * and decentralized governance for creative projects within a DAO framework.
 *
 * Function Summary:
 * -----------------
 * **Membership & Roles:**
 * 1. `requestMembership()`: Allows users to request membership in the DACA.
 * 2. `approveMembership(address _user)`: Admin function to approve a membership request.
 * 3. `revokeMembership(address _user)`: Admin function to revoke a member's membership.
 * 4. `getMemberDetails(address _user)`: Retrieves detailed information about a member.
 * 5. `isMember(address _user)`: Checks if an address is a member of the DACA.
 * 6. `isAdmin(address _user)`: Checks if an address is an admin of the DACA.
 * 7. `addAdmin(address _newAdmin)`: Owner function to add a new admin.
 * 8. `removeAdmin(address _adminToRemove)`: Owner function to remove an admin.
 *
 * **Project & Proposal Management:**
 * 9. `createProjectProposal(string memory _title, string memory _description, uint256 _budget)`: Members propose new creative projects.
 * 10. `voteOnProposal(uint256 _proposalId, bool _vote)`: Members vote on project proposals.
 * 11. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific project proposal.
 * 12. `acceptProposal(uint256 _proposalId)`: Admin function to accept a proposal after successful voting.
 * 13. `rejectProposal(uint256 _proposalId)`: Admin function to reject a proposal after unsuccessful voting or other reasons.
 * 14. `getProjectProposals()`: Retrieves a list of all project proposal IDs.
 * 15. `getApprovedProjects()`: Retrieves a list of IDs of approved projects.
 *
 * **Task & Contribution Management:**
 * 16. `applyForTask(uint256 _projectId, string memory _taskName, string memory _applicationDetails)`: Members apply to work on tasks within approved projects.
 * 17. `assignTask(uint256 _projectId, string memory _taskName, address _assignee)`: Project admin assigns tasks to members.
 * 18. `submitTaskWork(uint256 _projectId, string memory _taskName, string memory _workDetails)`: Members submit their work for assigned tasks.
 * 19. `approveTaskWork(uint256 _projectId, string memory _taskName)`: Project admin approves submitted task work.
 * 20. `requestTaskReview(uint256 _projectId, string memory _taskName)`: Member can request a review for their submitted work.
 * 21. `provideTaskReview(uint256 _projectId, string memory _taskName, string memory _reviewDetails)`: Admin or designated reviewers provide feedback on task submissions.
 * 22. `getTaskDetails(uint256 _projectId, string memory _taskName)`: Retrieves details of a specific task within a project.
 *
 * **Reputation & Rewards (Conceptual - can be expanded):**
 * 23. `contributeToReputation(address _member, uint256 _reputationPoints)`: (Internal/Admin) Function to adjust member's reputation based on contributions.
 * 24. `getMemberReputation(address _member)`: Retrieves a member's reputation score.
 *
 * **Governance & Settings:**
 * 25. `setVotingDuration(uint256 _durationInBlocks)`: Owner function to set the voting duration for proposals.
 * 26. `getVotingDuration()`: Retrieves the current voting duration.
 * 27. `setMembershipFee(uint256 _feeInWei)`: Owner function to set a membership fee (conceptual, not implemented in this example).
 * 28. `withdrawContractBalance(address payable _recipient)`: Owner function to withdraw contract balance (treasury management).
 */
contract DecentralizedAutonomousCreativeAgency {

    // --- Structs ---

    struct Member {
        bool isActive;
        uint256 reputation;
        string profileDetails; // e.g., skills, portfolio links
        uint256 joinTimestamp;
    }

    struct ProjectProposal {
        string title;
        string description;
        uint256 budget;
        address proposer;
        uint256 proposalTimestamp;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isApproved;
        bool isActive;
        mapping(address => bool) votes; // Track who voted and how
    }

    struct Task {
        string name;
        string description; // Detailed task description
        address assignee;
        string workDetails; // Link to submitted work, IPFS hash, etc.
        string reviewDetails;
        TaskStatus status;
        uint256 creationTimestamp;
        uint256 deadlineTimestamp; // Optional deadline for tasks
    }

    enum TaskStatus {
        Open,
        Applied,
        Assigned,
        WorkSubmitted,
        UnderReview,
        Approved,
        Rejected
    }

    struct Project {
        string title;
        string description;
        uint256 budget;
        address creator; // Who proposed and got it approved
        uint256 creationTimestamp;
        mapping(string => Task) tasks; // Task name to Task struct
        ProjectStatus status;
    }

    enum ProjectStatus {
        Proposal,
        Approved,
        InProgress,
        Completed,
        Cancelled
    }


    // --- State Variables ---

    address public owner;
    mapping(address => Member) public members;
    mapping(address => bool) public admins;
    address[] public memberList; // Keep track of members for iteration if needed

    uint256 public membershipFee; // Conceptual - fee to join DACA (not implemented payment in this example)
    uint256 public proposalVotingDurationBlocks = 100; // Default voting duration

    uint256 public proposalCounter;
    mapping(uint256 => ProjectProposal) public projectProposals;
    uint256[] public proposalList; // Keep track of proposal IDs

    uint256 public projectCounter;
    mapping(uint256 => Project) public projects;
    uint256[] public projectList; // Keep track of project IDs
    uint256[] public approvedProjectList; // Track approved project IDs


    // --- Events ---

    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed user, address indexed approver);
    event MembershipRevoked(address indexed user, address indexed revoker);
    event AdminAdded(address indexed newAdmin, address indexed addedBy);
    event AdminRemoved(address indexed removedAdmin, address indexed removedBy);

    event ProposalCreated(uint256 proposalId, address indexed proposer, string title);
    event ProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event ProposalAccepted(uint256 proposalId, address indexed acceptor);
    event ProposalRejected(uint256 proposalId, address indexed rejector);

    event ProjectCreated(uint256 projectId, address indexed creator, string title);
    event TaskApplied(uint256 projectId, string taskName, address indexed applicant);
    event TaskAssigned(uint256 projectId, string taskName, address indexed assignee);
    event TaskWorkSubmitted(uint256 projectId, string taskName, address indexed submitter);
    event TaskWorkApproved(uint256 projectId, string taskName, address indexed approver);
    event TaskReviewRequested(uint256 projectId, string taskName, address indexed requester);
    event TaskReviewProvided(uint256 projectId, string taskName, address indexed reviewer);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "Only admin or owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validProjectId(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= projectCounter, "Invalid project ID.");
        _;
    }

    modifier validTaskName(uint256 _projectId, string memory _taskName) {
        require(bytes(_taskName).length > 0, "Task name cannot be empty.");
        require(projects[_projectId].tasks[_taskName].creationTimestamp != 0, "Task does not exist in this project.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        admins[owner] = true; // Owner is initially an admin
    }


    // --- Membership & Roles Functions ---

    /**
     * @dev Allows a user to request membership to the DACA.
     * Emits a MembershipRequested event.
     */
    function requestMembership() external {
        require(!members[msg.sender].isActive, "Already a member.");
        require(!isMembershipRequested(msg.sender), "Membership already requested."); // Prevent duplicate requests
        members[msg.sender].isActive = false; // Mark as requested but not yet active
        emit MembershipRequested(msg.sender);
    }

    function isMembershipRequested(address _user) private view returns (bool) {
        return !members[_user].isActive && members[_user].joinTimestamp == 0; // Check if not active and joinTimestamp is default (0)
    }


    /**
     * @dev Admin function to approve a membership request.
     * @param _user Address of the user to approve for membership.
     * Emits a MembershipApproved event.
     */
    function approveMembership(address _user) external onlyAdmin {
        require(!members[_user].isActive, "User is already a member.");
        require(isMembershipRequested(_user), "Membership not requested.");
        members[_user].isActive = true;
        members[_user].joinTimestamp = block.timestamp;
        memberList.push(_user);
        emit MembershipApproved(_user, msg.sender);
    }

    /**
     * @dev Admin function to revoke a member's membership.
     * @param _user Address of the member to revoke membership from.
     * Emits a MembershipRevoked event.
     */
    function revokeMembership(address _user) external onlyAdmin {
        require(members[_user].isActive, "User is not a member.");
        members[_user].isActive = false;
        // Optionally remove from memberList if order is not important, or handle removal carefully for order maintenance
        emit MembershipRevoked(_user, msg.sender);
    }

    /**
     * @dev Retrieves detailed information about a member.
     * @param _user Address of the member.
     * @return isActive, reputation, profileDetails, joinTimestamp
     */
    function getMemberDetails(address _user) external view returns (bool isActive, uint256 reputation, string memory profileDetails, uint256 joinTimestamp) {
        return (members[_user].isActive, members[_user].reputation, members[_user].profileDetails, members[_user].joinTimestamp);
    }

    /**
     * @dev Checks if an address is a member of the DACA.
     * @param _user Address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _user) external view returns (bool) {
        return members[_user].isActive;
    }

    /**
     * @dev Checks if an address is an admin of the DACA.
     * @param _user Address to check.
     * @return True if the address is an admin, false otherwise.
     */
    function isAdmin(address _user) external view returns (bool) {
        return admins[_user];
    }

    /**
     * @dev Owner function to add a new admin.
     * @param _newAdmin Address of the new admin to add.
     * Emits an AdminAdded event.
     */
    function addAdmin(address _newAdmin) external onlyOwner {
        require(!admins[_newAdmin], "Address is already an admin.");
        admins[_newAdmin] = true;
        emit AdminAdded(_newAdmin, msg.sender);
    }

    /**
     * @dev Owner function to remove an admin.
     * @param _adminToRemove Address of the admin to remove.
     * Emits an AdminRemoved event.
     */
    function removeAdmin(address _adminToRemove) external onlyOwner {
        require(admins[_adminToRemove], "Address is not an admin.");
        require(_adminToRemove != owner, "Cannot remove the owner as admin.");
        delete admins[_adminToRemove];
        emit AdminRemoved(_adminToRemove, msg.sender);
    }


    // --- Project & Proposal Management Functions ---

    /**
     * @dev Allows members to propose new creative projects.
     * @param _title Title of the project proposal.
     * @param _description Detailed description of the project.
     * @param _budget Budget allocated for the project.
     * Emits a ProposalCreated event.
     */
    function createProjectProposal(string memory _title, string memory _description, uint256 _budget) external onlyMember {
        proposalCounter++;
        ProjectProposal storage newProposal = projectProposals[proposalCounter];
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.budget = _budget;
        newProposal.proposer = msg.sender;
        newProposal.proposalTimestamp = block.timestamp;
        newProposal.isActive = true;
        proposalList.push(proposalCounter);
        emit ProposalCreated(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on project proposals.
     * @param _proposalId ID of the project proposal.
     * @param _vote True for yes, false for no.
     * Emits a ProposalVoted event.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember validProposalId(_proposalId) {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.votes[msg.sender], "Already voted on this proposal.");
        require(block.number <= proposal.proposalTimestamp + proposalVotingDurationBlocks, "Voting period has ended.");

        proposal.votes[msg.sender] = true; // Mark voter as voted

        if (_vote) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Retrieves details of a specific project proposal.
     * @param _proposalId ID of the project proposal.
     * @return title, description, budget, proposer, proposalTimestamp, voteCountYes, voteCountNo, isApproved, isActive
     */
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId)
        returns (string memory title, string memory description, uint256 budget, address proposer, uint256 proposalTimestamp, uint256 voteCountYes, uint256 voteCountNo, bool isApproved, bool isActive)
    {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        return (proposal.title, proposal.description, proposal.budget, proposal.proposer, proposal.proposalTimestamp, proposal.voteCountYes, proposal.voteCountNo, proposal.isApproved, proposal.isActive);
    }

    /**
     * @dev Admin function to accept a proposal after successful voting.
     * @param _proposalId ID of the project proposal to accept.
     * Emits a ProposalAccepted event and ProjectCreated event.
     */
    function acceptProposal(uint256 _proposalId) external onlyAdmin validProposalId(_proposalId) {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.isApproved, "Proposal already accepted.");
        require(block.number > proposal.proposalTimestamp + proposalVotingDurationBlocks, "Voting period is not yet ended.");
        // Example acceptance criteria: more yes votes than no votes (can be customized)
        require(proposal.voteCountYes > proposal.voteCountNo, "Proposal did not pass voting.");

        proposal.isApproved = true;
        proposal.isActive = false; // Mark proposal as inactive after decision
        emit ProposalAccepted(_proposalId, msg.sender);

        // Create a project based on the accepted proposal
        projectCounter++;
        Project storage newProject = projects[projectCounter];
        newProject.title = proposal.title;
        newProject.description = proposal.description;
        newProject.budget = proposal.budget;
        newProject.creator = proposal.proposer;
        newProject.creationTimestamp = block.timestamp;
        newProject.status = ProjectStatus.Approved; // Initial status for approved project
        projectList.push(projectCounter);
        approvedProjectList.push(projectCounter);
        emit ProjectCreated(projectCounter, proposal.proposer, proposal.title);
    }

    /**
     * @dev Admin function to reject a proposal after unsuccessful voting or other reasons.
     * @param _proposalId ID of the project proposal to reject.
     * Emits a ProposalRejected event.
     */
    function rejectProposal(uint256 _proposalId) external onlyAdmin validProposalId(_proposalId) {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.isApproved, "Proposal already accepted or rejected.");
        proposal.isActive = false; // Mark proposal as inactive after decision
        emit ProposalRejected(_proposalId, msg.sender);
    }

    /**
     * @dev Retrieves a list of all project proposal IDs.
     * @return Array of proposal IDs.
     */
    function getProjectProposals() external view returns (uint256[] memory) {
        return proposalList;
    }

    /**
     * @dev Retrieves a list of IDs of approved projects.
     * @return Array of approved project IDs.
     */
    function getApprovedProjects() external view returns (uint256[] memory) {
        return approvedProjectList;
    }


    // --- Task & Contribution Management Functions ---

    /**
     * @dev Members apply to work on tasks within approved projects.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task to apply for.
     * @param _applicationDetails Details of the application (e.g., why they are suitable).
     * Emits a TaskApplied event.
     */
    function applyForTask(uint256 _projectId, string memory _taskName, string memory _applicationDetails) external onlyMember validProjectId(_projectId) {
        require(projects[_projectId].status == ProjectStatus.Approved || projects[_projectId].status == ProjectStatus.InProgress, "Project is not in a state to accept task applications.");
        require(projects[_projectId].tasks[_taskName].status == TaskStatus.Open, "Task is not open for applications.");
        projects[_projectId].tasks[_taskName].status = TaskStatus.Applied; // Mark task as applied (can be more complex application tracking later)
        // In a real system, might want to store application details and applicant address in a separate mapping
        emit TaskApplied(_projectId, _taskName, msg.sender);
    }


    /**
     * @dev Project admin assigns tasks to members.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task to assign.
     * @param _assignee Address of the member to assign the task to.
     * Emits a TaskAssigned event.
     */
    function assignTask(uint256 _projectId, string memory _taskName, address _assignee) external onlyAdmin validProjectId(_projectId) validTaskName(_projectId, _taskName) {
        require(projects[_projectId].status == ProjectStatus.Approved || projects[_projectId].status == ProjectStatus.InProgress, "Project is not in progress.");
        require(projects[_projectId].tasks[_taskName].status != TaskStatus.Assigned && projects[_projectId].tasks[_taskName].status != TaskStatus.WorkSubmitted && projects[_projectId].tasks[_taskName].status != TaskStatus.Approved, "Task is not in assignable state.");
        require(members[_assignee].isActive, "Assignee is not a member.");

        projects[_projectId].tasks[_taskName].assignee = _assignee;
        projects[_projectId].tasks[_taskName].status = TaskStatus.Assigned;
        emit TaskAssigned(_projectId, _taskName, _assignee);
    }

    /**
     * @dev Members submit their work for assigned tasks.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task.
     * @param _workDetails Details of the submitted work (e.g., link to files, IPFS hash).
     * Emits a TaskWorkSubmitted event.
     */
    function submitTaskWork(uint256 _projectId, string memory _taskName, string memory _workDetails) external onlyMember validProjectId(_projectId) validTaskName(_projectId, _taskName) {
        require(projects[_projectId].tasks[_taskName].assignee == msg.sender, "Not assigned to this task.");
        require(projects[_projectId].tasks[_taskName].status == TaskStatus.Assigned, "Task is not in Assigned state.");

        projects[_projectId].tasks[_taskName].workDetails = _workDetails;
        projects[_projectId].tasks[_taskName].status = TaskStatus.WorkSubmitted;
        emit TaskWorkSubmitted(_projectId, _taskName, msg.sender);
    }

    /**
     * @dev Project admin approves submitted task work.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task.
     * Emits a TaskWorkApproved event.
     */
    function approveTaskWork(uint256 _projectId, string memory _taskName) external onlyAdmin validProjectId(_projectId) validTaskName(_projectId, _taskName) {
        require(projects[_projectId].tasks[_taskName].status == TaskStatus.WorkSubmitted || projects[_projectId].tasks[_taskName].status == TaskStatus.UnderReview, "Task work is not submitted or under review.");

        projects[_projectId].tasks[_taskName].status = TaskStatus.Approved;
        emit TaskWorkApproved(_projectId, _taskName, msg.sender);
        // Here you would implement payment logic if applicable, based on project budget and task completion
    }

    /**
     * @dev Member can request a review for their submitted work.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task.
     * Emits a TaskReviewRequested event.
     */
    function requestTaskReview(uint256 _projectId, string memory _taskName) external onlyMember validProjectId(_projectId) validTaskName(_projectId, _taskName) {
        require(projects[_projectId].tasks[_taskName].assignee == msg.sender, "Not assigned to this task.");
        require(projects[_projectId].tasks[_taskName].status == TaskStatus.WorkSubmitted, "Task work is not submitted.");

        projects[_projectId].tasks[_taskName].status = TaskStatus.UnderReview;
        emit TaskReviewRequested(_projectId, _taskName, msg.sender);
    }

    /**
     * @dev Admin or designated reviewers provide feedback on task submissions.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task.
     * @param _reviewDetails Review feedback.
     * Emits a TaskReviewProvided event.
     */
    function provideTaskReview(uint256 _projectId, string memory _taskName, string memory _reviewDetails) external onlyAdmin validProjectId(_projectId) validTaskName(_projectId, _taskName) {
        require(projects[_projectId].tasks[_taskName].status == TaskStatus.UnderReview || projects[_projectId].tasks[_taskName].status == TaskStatus.WorkSubmitted, "Task work is not under review or submitted.");

        projects[_projectId].tasks[_taskName].reviewDetails = _reviewDetails;
        projects[_projectId].tasks[_taskName].status = TaskStatus.UnderReview; // Still under review after feedback, can change to different status flow
        emit TaskReviewProvided(_projectId, _taskName, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific task within a project.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task.
     * @return name, description, assignee, workDetails, reviewDetails, status, creationTimestamp, deadlineTimestamp
     */
    function getTaskDetails(uint256 _projectId, string memory _taskName) external view validProjectId(_projectId) validTaskName(_projectId, _taskName)
        returns (string memory name, string memory description, address assignee, string memory workDetails, string memory reviewDetails, TaskStatus status, uint256 creationTimestamp, uint256 deadlineTimestamp)
    {
        Task storage task = projects[_projectId].tasks[_taskName];
        return (task.name, task.description, task.assignee, task.workDetails, task.reviewDetails, task.status, task.creationTimestamp, task.deadlineTimestamp);
    }


    // --- Reputation & Rewards Functions --- (Conceptual - can be expanded)

    /**
     * @dev (Internal/Admin) Function to adjust member's reputation based on contributions.
     * @param _member Address of the member to adjust reputation for.
     * @param _reputationPoints Points to add or subtract (use negative for subtraction).
     */
    function contributeToReputation(address _member, uint256 _reputationPoints) internal onlyAdmin {
        members[_member].reputation += _reputationPoints;
    }

    /**
     * @dev Retrieves a member's reputation score.
     * @param _member Address of the member.
     * @return Reputation score.
     */
    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }


    // --- Governance & Settings Functions ---

    /**
     * @dev Owner function to set the voting duration for proposals.
     * @param _durationInBlocks Duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        proposalVotingDurationBlocks = _durationInBlocks;
    }

    /**
     * @dev Retrieves the current voting duration.
     * @return Voting duration in blocks.
     */
    function getVotingDuration() external view returns (uint256) {
        return proposalVotingDurationBlocks;
    }

    /**
     * @dev Owner function to set a membership fee (conceptual, not implemented payment in this example).
     * @param _feeInWei Fee amount in Wei.
     */
    function setMembershipFee(uint256 _feeInWei) external onlyOwner {
        membershipFee = _feeInWei;
    }

    /**
     * @dev Owner function to withdraw contract balance (treasury management).
     * @param _recipient Address to receive the withdrawn funds.
     */
    function withdrawContractBalance(address payable _recipient) external onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    /**
     * @dev Function to create a new task within a project.
     * @param _projectId ID of the project.
     * @param _taskName Name of the task.
     * @param _taskDescription Description of the task.
     */
    function createTask(uint256 _projectId, string memory _taskName, string memory _taskDescription) external onlyAdmin validProjectId(_projectId) {
        require(bytes(_taskName).length > 0, "Task name cannot be empty.");
        require(projects[_projectId].tasks[_taskName].creationTimestamp == 0, "Task with this name already exists in project."); // Ensure no task name collision

        Task storage newTask = projects[_projectId].tasks[_taskName];
        newTask.name = _taskName;
        newTask.description = _taskDescription;
        newTask.status = TaskStatus.Open;
        newTask.creationTimestamp = block.timestamp;
        // Deadline can be added later or during task creation

        // Optionally emit an event for task creation
    }
}
```