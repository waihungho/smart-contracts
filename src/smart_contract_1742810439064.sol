```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DynamicSkillDAO - Decentralized Autonomous Organization with Dynamic Governance & Skill-Based Roles
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO with advanced features including dynamic governance parameters,
 *      skill-based roles, reputation system, project-based task management, and on-chain dispute resolution.
 *
 * Function Summary:
 *
 * **Core DAO Functions:**
 * 1. initializeDAO(string _name, uint256 _initialVotingPeriod, uint256 _initialQuorumPercentage, address _admin) - Initializes the DAO with name, initial governance parameters and admin.
 * 2. joinDAO(string _profileHash) - Allows users to join the DAO by registering their profile (e.g., IPFS hash).
 * 3. leaveDAO() - Allows members to leave the DAO.
 * 4. isMember(address _member) - Checks if an address is a member of the DAO.
 * 5. getMemberProfile(address _member) - Retrieves the profile hash of a member.
 *
 * **Role & Skill Management:**
 * 6. defineRole(string _roleName, string _roleDescription) - Defines a new role within the DAO. Only admin can call.
 * 7. assignRole(address _member, uint256 _roleId) - Assigns a role to a member. Only members with 'Role Manager' role can call.
 * 8. revokeRole(address _member, uint256 _roleId) - Revokes a role from a member. Only members with 'Role Manager' role can call.
 * 9. getMemberRoles(address _member) - Retrieves the list of roles assigned to a member.
 * 10. registerSkill(string _skillName, string _skillDescription) - Allows members to register their skills.
 * 11. endorseSkill(address _member, uint256 _skillId) - Allows members to endorse skills of other members.
 * 12. getSkillEndorsements(uint256 _skillId) - Retrieves the number of endorsements for a specific skill.
 * 13. getMemberSkills(address _member) - Retrieves the list of skills registered by a member.
 *
 * **Dynamic Governance & Voting:**
 * 14. proposeGovernanceChange(string _proposalDescription, bytes _calldata) - Allows members to propose changes to governance parameters.
 * 15. proposeProject(string _projectTitle, string _projectDescription, uint256 _fundingGoal, address _projectLead) - Allows members to propose new projects for the DAO.
 * 16. voteOnProposal(uint256 _proposalId, bool _support) - Allows members to vote on active proposals.
 * 17. executeProposal(uint256 _proposalId) - Executes a passed proposal. Only callable after voting period ends and quorum is met.
 * 18. getProposalStatus(uint256 _proposalId) - Retrieves the status of a proposal (active, passed, rejected, executed).
 * 19. adjustQuorumDynamically(uint256 _targetParticipationRate, uint256 _quorumAdjustmentFactor) - Dynamically adjusts the quorum based on recent voting participation. Admin can call.
 * 20. setVotingPeriod(uint256 _newVotingPeriod) - Sets a new voting period for proposals. Admin can call.
 * 21. emergencyPauseDAO(string _reason) - Pauses critical DAO functions in case of emergency. Admin can call.
 * 22. emergencyUnpauseDAO() - Unpauses the DAO after emergency pause. Admin can call.
 *
 * **Reputation & Rewards (Conceptual - Basic Implementation):**
 * 23. awardReputation(address _member, uint256 _reputationPoints, string _reason) - Awards reputation points to a member for contributions. Only members with 'Rewarder' role can call.
 * 24. burnReputation(address _member, uint256 _reputationPoints, string _reason) - Burns reputation points from a member. Only members with 'Rewarder' role can call.
 * 25. getMemberReputation(address _member) - Retrieves the reputation points of a member.
 *
 * **Project & Task Management (Conceptual - Basic Implementation):**
 * 26. assignTaskToProject(uint256 _projectId, string _taskDescription, address _assignee) - Assigns a task to a member for a specific project. Project Lead can call.
 * 27. markTaskCompleted(uint256 _taskId) - Marks a task as completed. Assignee can call.
 * 28. getProjectTasks(uint256 _projectId) - Retrieves the list of tasks for a project.
 *
 * **Dispute Resolution (Conceptual - Basic Implementation):**
 * 29. raiseDispute(uint256 _projectId, string _disputeDescription) - Allows members to raise a dispute on a project.
 * 30. resolveDispute(uint256 _disputeId, bool _resolution) - Allows DAO members to vote to resolve a dispute. (Simplified - needs more robust mechanism in real world).
 */
contract DynamicSkillDAO {
    // --- State Variables ---

    string public daoName;
    address public admin;
    uint256 public votingPeriod; // In blocks
    uint256 public quorumPercentage; // Percentage of total members required for quorum
    bool public paused; // Emergency pause state

    uint256 public memberCount;
    mapping(address => bool) public isMember;
    mapping(address => string) public memberProfiles;
    address[] public members;

    uint256 public nextRoleId = 1;
    struct Role {
        string name;
        string description;
    }
    mapping(uint256 => Role) public roles;
    mapping(address => uint256[]) public memberRoles;

    uint256 public nextSkillId = 1;
    struct Skill {
        string name;
        string description;
    }
    mapping(uint256 => Skill) public skills;
    mapping(address => uint256[]) public memberSkills;
    mapping(uint256 => uint256) public skillEndorsements; // skillId => endorsementCount

    uint256 public nextProposalId = 1;
    struct Proposal {
        string description;
        bytes calldataData; // Calldata for governance changes
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalStatus status;
    }
    enum ProposalStatus {
        Active,
        Passed,
        Rejected,
        Executed,
        Cancelled
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public memberVotes; // proposalId => member => voted

    uint256 public nextProjectId = 1;
    struct Project {
        string title;
        string description;
        uint256 fundingGoal;
        uint256 fundingRaised;
        address projectLead;
        ProjectStatus status;
    }
    enum ProjectStatus {
        Proposed,
        Funded,
        InProgress,
        Completed,
        Cancelled
    }
    mapping(uint256 => Project) public projects;

    uint256 public nextTaskId = 1;
    struct Task {
        uint256 projectId;
        string description;
        address assignee;
        bool completed;
    }
    mapping(uint256 => Task) public tasks;

    uint256 public nextDisputeId = 1;
    struct Dispute {
        uint256 projectId;
        string description;
        DisputeStatus status;
        uint256 votesForResolution;
        uint256 votesAgainstResolution;
    }
    enum DisputeStatus {
        Open,
        Resolved,
        Rejected
    }
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public disputeVotes; // disputeId => member => voted

    mapping(address => uint256) public memberReputation;

    // --- Events ---
    event DAOInitialized(string name, address admin);
    event MemberJoined(address member, string profileHash);
    event MemberLeft(address member);
    event RoleDefined(uint256 roleId, string roleName);
    event RoleAssigned(address member, uint256 roleId);
    event RoleRevoked(address member, uint256 roleId);
    event SkillRegistered(address member, uint256 skillId, string skillName);
    event SkillEndorsed(address endorser, address member, uint256 skillId);
    event GovernanceChangeProposed(uint256 proposalId, string description, address proposer);
    event ProjectProposed(uint256 proposalId, string title, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event QuorumAdjusted(uint256 newQuorumPercentage);
    event VotingPeriodSet(uint256 newVotingPeriod);
    event DAOPaused(string reason);
    event DAOUnpaused();
    event ReputationAwarded(address member, uint256 points, string reason);
    event ReputationBurned(address member, uint256 points, string reason);
    event TaskAssigned(uint256 taskId, uint256 projectId, address assignee);
    event TaskCompleted(uint256 taskId);
    event DisputeRaised(uint256 disputeId, uint256 projectId, string description);
    event DisputeResolved(uint256 disputeId, bool resolution);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only DAO members can call this function.");
        _;
    }

    modifier onlyRole(uint256 _roleId) {
        bool hasRole = false;
        for (uint256 i = 0; i < memberRoles[msg.sender].length; i++) {
            if (memberRoles[msg.sender][i] == _roleId) {
                hasRole = true;
                break;
            }
        }
        require(hasRole, "Member does not have required role.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "DAO is not paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validProject(uint256 _projectId) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID.");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(_taskId > 0 && _taskId < nextTaskId, "Invalid task ID.");
        _;
    }

    modifier validDispute(uint256 _disputeId) {
        require(_disputeId > 0 && _disputeId < nextDisputeId, "Invalid dispute ID.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier votingPeriodNotEnded(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier votingPeriodEnded(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period has not ended.");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!memberVotes[_proposalId][msg.sender], "Member has already voted on this proposal.");
        _;
    }

    // --- Core DAO Functions ---

    constructor() {
        // No direct constructor initialization for security reasons.
        // Use initializeDAO function after deployment.
    }

    function initializeDAO(string memory _name, uint256 _initialVotingPeriod, uint256 _initialQuorumPercentage, address _admin) public onlyAdmin {
        require(bytes(_name).length > 0, "DAO name cannot be empty.");
        require(_initialVotingPeriod > 0, "Voting period must be greater than 0.");
        require(_initialQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        require(_admin != address(0), "Admin address cannot be zero.");
        require(bytes(daoName).length == 0, "DAO already initialized."); // Prevent re-initialization

        daoName = _name;
        votingPeriod = _initialVotingPeriod;
        quorumPercentage = _initialQuorumPercentage;
        admin = _admin;
        paused = false;

        emit DAOInitialized(_name, _admin);

        // Define initial roles (example - can be extended)
        defineRole("Member", "Basic DAO membership role."); // Role ID 1
        defineRole("Role Manager", "Role for managing other members' roles."); // Role ID 2
        defineRole("Rewarder", "Role for awarding reputation points."); // Role ID 3

        // Assign admin initial roles (example - can be extended)
        assignRole(_admin, 2); // Role Manager
        assignRole(_admin, 3); // Rewarder
    }

    function joinDAO(string memory _profileHash) public whenNotPaused {
        require(!isMember[msg.sender], "Already a member.");
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty.");

        isMember[msg.sender] = true;
        memberProfiles[msg.sender] = _profileHash;
        members.push(msg.sender);
        memberCount++;

        // Assign default 'Member' role on joining (Role ID 1)
        assignRole(msg.sender, 1);

        emit MemberJoined(msg.sender, _profileHash);
    }

    function leaveDAO() public onlyMember whenNotPaused {
        require(isMember[msg.sender], "Not a member.");

        isMember[msg.sender] = false;
        delete memberProfiles[msg.sender];

        // Remove from members array (more gas-efficient way could be used for large member lists if needed)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                delete members[i];
                // To maintain array compactness in simpler cases, you could shift elements down,
                // but for gas optimization in larger lists, consider using a different data structure.
                // For this example, we'll leave a "hole" in the array.
                break;
            }
        }
        memberCount--;

        // Revoke all roles (optional - decide DAO policy)
        delete memberRoles[msg.sender];

        emit MemberLeft(msg.sender);
    }

    function getMemberProfile(address _member) public view returns (string memory) {
        require(isMember[_member], "Not a member.");
        return memberProfiles[_member];
    }

    // --- Role & Skill Management ---

    function defineRole(string memory _roleName, string memory _roleDescription) public onlyAdmin whenNotPaused {
        require(bytes(_roleName).length > 0, "Role name cannot be empty.");
        roles[nextRoleId] = Role({name: _roleName, description: _roleDescription});
        emit RoleDefined(nextRoleId, _roleName);
        nextRoleId++;
    }

    function assignRole(address _member, uint256 _roleId) public onlyMember onlyRole(2) whenNotPaused { // Role Manager role (ID 2)
        require(isMember[_member], "Target address is not a member.");
        require(roles[_roleId].name.length > 0, "Invalid role ID.");

        // Prevent duplicate role assignment (optional - based on DAO policy)
        bool alreadyHasRole = false;
        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (memberRoles[_member][i] == _roleId) {
                alreadyHasRole = true;
                break;
            }
        }
        require(!alreadyHasRole, "Member already has this role.");


        memberRoles[_member].push(_roleId);
        emit RoleAssigned(_member, _roleId);
    }

    function revokeRole(address _member, uint256 _roleId) public onlyMember onlyRole(2) whenNotPaused { // Role Manager role (ID 2)
        require(isMember[_member], "Target address is not a member.");
        require(roles[_roleId].name.length > 0, "Invalid role ID.");

        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (memberRoles[_member][i] == _roleId) {
                delete memberRoles[_member][i]; // Remove the role (leaves a "hole" - similar array removal as in leaveDAO)
                emit RoleRevoked(_member, _roleId);
                return;
            }
        }
        require(false, "Member does not have this role to revoke."); // Should not reach here unless role not found
    }

    function getMemberRoles(address _member) public view onlyMember returns (uint256[] memory) {
        return memberRoles[_member];
    }

    function registerSkill(string memory _skillName, string memory _skillDescription) public onlyMember whenNotPaused {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        skills[nextSkillId] = Skill({name: _skillName, description: _skillDescription});
        memberSkills[msg.sender].push(nextSkillId);
        emit SkillRegistered(msg.sender, nextSkillId, _skillName);
        nextSkillId++;
    }

    function endorseSkill(address _member, uint256 _skillId) public onlyMember whenNotPaused {
        require(isMember[_member], "Target address is not a member.");
        require(skills[_skillId].name.length > 0, "Invalid skill ID.");

        // Prevent self-endorsement (optional - based on DAO policy)
        require(_member != msg.sender, "Cannot endorse your own skill.");

        skillEndorsements[_skillId]++;
        emit SkillEndorsed(msg.sender, _member, _skillId);
    }

    function getSkillEndorsements(uint256 _skillId) public view returns (uint256) {
        return skillEndorsements[_skillId];
    }

    function getMemberSkills(address _member) public view onlyMember returns (uint256[] memory) {
        return memberSkills[_member];
    }

    // --- Dynamic Governance & Voting ---

    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) public onlyMember whenNotPaused {
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty.");
        require(_calldata.length > 0, "Calldata cannot be empty for governance changes."); // Ensure some action is proposed

        proposals[nextProposalId] = Proposal({
            description: _proposalDescription,
            calldataData: _calldata,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            status: ProposalStatus.Active
        });

        emit GovernanceChangeProposed(nextProposalId, _proposalDescription, msg.sender);
        nextProposalId++;
    }

    function proposeProject(string memory _projectTitle, string memory _projectDescription, uint256 _fundingGoal, address _projectLead) public onlyMember whenNotPaused {
        require(bytes(_projectTitle).length > 0, "Project title cannot be empty.");
        require(bytes(_projectDescription).length > 0, "Project description cannot be empty.");
        require(_fundingGoal > 0, "Funding goal must be greater than 0.");
        require(isMember[_projectLead], "Project lead must be a DAO member.");

        proposals[nextProposalId] = Proposal({
            description: _projectDescription, // Reusing proposal structure for projects for simplicity - can be separated if needed
            calldataData: bytes(""), // No calldata needed for project proposals directly - actions happen after funding
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            status: ProposalStatus.Active
        });

        projects[nextProjectId] = Project({
            title: _projectTitle,
            description: _projectDescription,
            fundingGoal: _fundingGoal,
            fundingRaised: 0,
            projectLead: _projectLead,
            status: ProjectStatus.Proposed
        });

        emit ProjectProposed(nextProposalId, _projectTitle, msg.sender);
        nextProposalId++;
        nextProjectId++;
    }


    function voteOnProposal(uint256 _proposalId, bool _support)
        public
        onlyMember
        whenNotPaused
        validProposal(_proposalId)
        proposalActive(_proposalId)
        votingPeriodNotEnded(_proposalId)
        notVoted(_proposalId)
    {
        memberVotes[_proposalId][msg.sender] = true;
        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId)
        public
        onlyMember // Or potentially admin/role based on DAO policy
        whenNotPaused
        validProposal(_proposalId)
        proposalActive(_proposalId)
        proposalNotExecuted(_proposalId)
        votingPeriodEnded(_proposalId)
    {
        uint256 quorumRequired = (memberCount * quorumPercentage) / 100;
        require((proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst) >= quorumRequired, "Quorum not met.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal rejected.");

        proposals[_proposalId].status = ProposalStatus.Executed;
        proposals[_proposalId].executed = true;

        if (proposals[_proposalId].calldataData.length > 0) {
            // Execute governance change - WARNING: Be extremely careful with arbitrary calldata execution!
            // Consider adding safety checks and limitations for real-world scenarios.
            (bool success, ) = address(this).call(proposals[_proposalId].calldataData);
            require(success, "Governance change execution failed.");
        }

        emit ProposalExecuted(_proposalId);
    }

    function getProposalStatus(uint256 _proposalId) public view validProposal(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    function adjustQuorumDynamically(uint256 _targetParticipationRate, uint256 _quorumAdjustmentFactor) public onlyAdmin whenNotPaused {
        require(_targetParticipationRate <= 100 && _targetParticipationRate >= 0, "Target participation rate must be between 0 and 100.");
        require(_quorumAdjustmentFactor > 0 && _quorumAdjustmentFactor <= 100, "Quorum adjustment factor must be between 1 and 100.");

        // Simplified dynamic quorum adjustment - can be made more sophisticated based on DAO needs
        uint256 recentParticipationRate = calculateRecentVotingParticipation(); // Placeholder - needs implementation

        if (recentParticipationRate < _targetParticipationRate) {
            quorumPercentage = quorumPercentage * (100 - _quorumAdjustmentFactor) / 100; // Decrease quorum if participation is low
        } else if (recentParticipationRate > _targetParticipationRate) {
            quorumPercentage = quorumPercentage * (100 + _quorumAdjustmentFactor) / 100; // Increase quorum if participation is high
        }

        // Ensure quorum percentage stays within valid range (0-100)
        if (quorumPercentage > 100) {
            quorumPercentage = 100;
        }
        if (quorumPercentage < 0) {
            quorumPercentage = 0;
        }

        emit QuorumAdjusted(quorumPercentage);
    }

    // Placeholder for calculating recent voting participation - needs implementation based on DAO history/tracking
    function calculateRecentVotingParticipation() internal view returns (uint256) {
        // In a real DAO, you'd need to track voting history and calculate participation rate
        // over a recent period (e.g., last X proposals, last Y blocks, etc.).
        // For simplicity in this example, we return a fixed value.
        return 50; // Example: 50% participation
    }

    function setVotingPeriod(uint256 _newVotingPeriod) public onlyAdmin whenNotPaused {
        require(_newVotingPeriod > 0, "Voting period must be greater than 0.");
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodSet(_newVotingPeriod);
    }

    function emergencyPauseDAO(string memory _reason) public onlyAdmin whenNotPaused {
        paused = true;
        emit DAOPaused(_reason);
    }

    function emergencyUnpauseDAO() public onlyAdmin whenPaused {
        paused = false;
        emit DAOUnpaused();
    }

    // --- Reputation & Rewards (Conceptual - Basic Implementation) ---

    function awardReputation(address _member, uint256 _reputationPoints, string memory _reason) public onlyMember onlyRole(3) whenNotPaused { // Rewarder role (ID 3)
        require(isMember[_member], "Target address is not a member.");
        require(_reputationPoints > 0, "Reputation points must be greater than 0.");

        memberReputation[_member] += _reputationPoints;
        emit ReputationAwarded(_member, _reputationPoints, _reason);
    }

    function burnReputation(address _member, uint256 _reputationPoints, string memory _reason) public onlyMember onlyRole(3) whenNotPaused { // Rewarder role (ID 3)
        require(isMember[_member], "Target address is not a member.");
        require(_reputationPoints > 0, "Reputation points must be greater than 0.");
        require(memberReputation[_member] >= _reputationPoints, "Not enough reputation points to burn.");

        memberReputation[_member] -= _reputationPoints;
        emit ReputationBurned(_member, _reputationPoints, _reason);
    }

    function getMemberReputation(address _member) public view onlyMember returns (uint256) {
        return memberReputation[_member];
    }

    // --- Project & Task Management (Conceptual - Basic Implementation) ---

    function assignTaskToProject(uint256 _projectId, string memory _taskDescription, address _assignee) public onlyMember validProject(_projectId) whenNotPaused {
        require(projects[_projectId].projectLead == msg.sender, "Only project lead can assign tasks.");
        require(isMember[_assignee], "Assignee must be a DAO member.");
        require(bytes(_taskDescription).length > 0, "Task description cannot be empty.");

        tasks[nextTaskId] = Task({
            projectId: _projectId,
            description: _taskDescription,
            assignee: _assignee,
            completed: false
        });
        emit TaskAssigned(nextTaskId, _projectId, _assignee);
        nextTaskId++;
    }

    function markTaskCompleted(uint256 _taskId) public onlyMember validTask(_taskId) whenNotPaused {
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can mark task as completed.");
        require(!tasks[_taskId].completed, "Task already completed.");

        tasks[_taskId].completed = true;
        emit TaskCompleted(_taskId);

        // Potentially trigger reputation reward or project funding release upon task completion
        // (Implementation depends on DAO's reward/funding mechanism)
    }

    function getProjectTasks(uint256 _projectId) public view validProject(_projectId) returns (Task[] memory) {
        uint256 taskCount = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].projectId == _projectId) {
                taskCount++;
            }
        }

        Task[] memory projectTasks = new Task[](taskCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].projectId == _projectId) {
                projectTasks[index] = tasks[i];
                index++;
            }
        }
        return projectTasks;
    }

    // --- Dispute Resolution (Conceptual - Basic Implementation) ---

    function raiseDispute(uint256 _projectId, string memory _disputeDescription) public onlyMember validProject(_projectId) whenNotPaused {
        require(bytes(_disputeDescription).length > 0, "Dispute description cannot be empty.");

        disputes[nextDisputeId] = Dispute({
            projectId: _projectId,
            description: _disputeDescription,
            status: DisputeStatus.Open,
            votesForResolution: 0,
            votesAgainstResolution: 0
        });
        emit DisputeRaised(nextDisputeId, _projectId, _disputeDescription);
        nextDisputeId++;
    }

    function resolveDispute(uint256 _disputeId, bool _resolution) public onlyMember validDispute(_disputeId) whenNotPaused {
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not open.");
        require(!disputeVotes[_disputeId][msg.sender], "Member has already voted on this dispute.");

        disputeVotes[_disputeId][msg.sender] = true;
        if (_resolution) {
            disputes[_disputeId].votesForResolution++;
        } else {
            disputes[_disputeId].votesAgainstResolution++;
        }

        uint256 quorumRequired = (memberCount * quorumPercentage) / 100; // Reuse DAO quorum for dispute resolution (can be separate)
        if ((disputes[_disputeId].votesForResolution + disputes[_disputeId].votesAgainstResolution) >= quorumRequired) {
            if (disputes[_disputeId].votesForResolution > disputes[_disputeId].votesAgainstResolution) {
                disputes[_disputeId].status = DisputeStatus.Resolved;
                emit DisputeResolved(_disputeId, true);
                // Implement dispute resolution logic here (e.g., revert project progress, refund funds, etc.)
            } else {
                disputes[_disputeId].status = DisputeStatus.Rejected;
                emit DisputeResolved(_disputeId, false);
            }
        }
    }
}
```