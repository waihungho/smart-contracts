```solidity
/**
 * @title SkillBasedDAO - Decentralized Autonomous Organization for Skill-Based Collaboration
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a Decentralized Autonomous Organization (DAO) focused on skill-based contributions and reputation.
 *      This DAO allows members to register their skills, propose projects requiring specific skill sets, and collaborate on tasks.
 *      It features a reputation system based on contributions and task completions, and incorporates advanced concepts like skill-based access control,
 *      dynamic roles, and potentially quadratic voting for resource allocation (though voting is simplified in this example for clarity, expansion is possible).
 *
 * **Outline:**
 * 1. **Member Management:** Onboarding, Offboarding, Skill Registration, Profile Management.
 * 2. **Skill Management:** Skill creation, Skill listing, Skill verification.
 * 3. **Project Management:** Project proposal, Project approval, Project cancellation, Project funding (simplified in this example), Project completion.
 * 4. **Task Management:** Task creation within projects, Task assignment based on skills, Task application, Task completion, Task verification, Task rewards.
 * 5. **Reputation System:** Reputation points based on task completion and contributions, reputation-based access control (potential expansion).
 * 6. **Governance (Simplified):** Basic project approval mechanism, potential for future expansion to more complex governance models.
 * 7. **Utility Functions:** Getters for various data, contract information, emergency functions.
 *
 * **Function Summary:**
 * 1. `joinDAO()`: Allows a user to become a member of the DAO.
 * 2. `leaveDAO()`: Allows a member to leave the DAO.
 * 3. `addSkill(string _skillName)`: Allows the contract admin to add a new skill to the DAO's skill registry.
 * 4. `updateSkill(uint _skillId, string _newSkillName)`: Allows the contract admin to update an existing skill name.
 * 5. `registerSkills(uint[] _skillIds)`: Allows a member to register their skills from the DAO's skill registry.
 * 6. `updateRegisteredSkills(uint[] _skillIds)`: Allows a member to update their registered skills.
 * 7. `getMemberProfile(address _member)`: Retrieves the profile information of a DAO member.
 * 8. `getSkillDetails(uint _skillId)`: Retrieves details of a specific skill.
 * 9. `proposeProject(string _projectName, string _projectDescription, uint[] _requiredSkillIds, uint _projectBudget)`: Allows a member to propose a new project.
 * 10. `approveProject(uint _projectId)`: Allows the contract admin (or DAO governance in a more advanced version) to approve a project.
 * 11. `cancelProject(uint _projectId)`: Allows the contract admin to cancel a project.
 * 12. `createTask(uint _projectId, string _taskDescription, uint[] _requiredSkillIds, uint _taskReward)`: Allows a project proposer or admin to create a task within a project.
 * 13. `assignTask(uint _taskId, address _assignee)`: Allows a project proposer or admin to assign a task to a member.
 * 14. `applyForTask(uint _taskId)`: Allows a member to apply for an open task.
 * 15. `completeTask(uint _taskId)`: Allows a member to mark a task as completed.
 * 16. `verifyTaskCompletion(uint _taskId)`: Allows the project proposer or admin to verify a completed task and distribute rewards.
 * 17. `increaseReputation(address _member, uint _points)`: Allows the contract admin to manually increase a member's reputation.
 * 18. `decreaseReputation(address _member, uint _points)`: Allows the contract admin to manually decrease a member's reputation.
 * 19. `viewReputation(address _member)`: Allows anyone to view a member's reputation points.
 * 20. `getProjectDetails(uint _projectId)`: Retrieves details of a specific project.
 * 21. `getTaskDetails(uint _taskId)`: Retrieves details of a specific task.
 * 22. `emergencyWithdraw(address payable _recipient)`: Emergency function for the admin to withdraw contract funds.
 */
pragma solidity ^0.8.0;

contract SkillBasedDAO {

    // -------- State Variables --------

    address public admin; // Contract administrator
    uint public memberCount;

    struct Member {
        address memberAddress;
        uint joinedTimestamp;
        uint[] registeredSkillIds;
        uint reputation;
        bool isActive;
    }

    struct Skill {
        string skillName;
        bool isActive;
    }

    struct Project {
        string projectName;
        string projectDescription;
        uint[] requiredSkillIds;
        uint projectBudget; // Simplified budget in Wei, could be expanded to token handling
        ProjectStatus status;
        address proposer;
        uint creationTimestamp;
    }

    enum ProjectStatus { Proposed, Approved, Active, Completed, Cancelled }

    struct Task {
        uint projectId;
        string taskDescription;
        uint[] requiredSkillIds;
        address assignee;
        TaskStatus status;
        uint taskReward; // Reward in Wei for task completion
        uint creationTimestamp;
    }

    enum TaskStatus { Open, Applied, Assigned, Completed, Verified, Cancelled }

    mapping(address => Member) public members;
    mapping(uint => Skill) public skills;
    uint public skillCount;
    mapping(uint => Project) public projects;
    uint public projectCount;
    mapping(uint => Task) public tasks;
    uint public taskCount;
    mapping(address => uint) public reputation; // Reputation points for members

    // -------- Events --------

    event MemberJoined(address memberAddress, uint joinedTimestamp);
    event MemberLeft(address memberAddress);
    event SkillAdded(uint skillId, string skillName);
    event SkillUpdated(uint skillId, string newSkillName);
    event SkillsRegistered(address memberAddress, uint[] skillIds);
    event SkillsUpdated(address memberAddress, uint[] skillIds);
    event ProjectProposed(uint projectId, string projectName, address proposer, uint creationTimestamp);
    event ProjectApproved(uint projectId);
    event ProjectCancelled(uint projectId);
    event TaskCreated(uint taskId, uint projectId, string taskDescription, address creator, uint creationTimestamp);
    event TaskAssigned(uint taskId, address assignee);
    event TaskApplied(uint taskId, address applicant);
    event TaskCompleted(uint taskId, address completer);
    event TaskVerified(uint taskId, address verifier);
    event ReputationIncreased(address memberAddress, uint points, string reason);
    event ReputationDecreased(address memberAddress, uint points, string reason);
    event EmergencyWithdrawal(address recipient, uint amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can call this function.");
        _;
    }

    modifier skillExists(uint _skillId) {
        require(_skillId > 0 && _skillId <= skillCount && skills[_skillId].isActive, "Skill does not exist.");
        _;
    }

    modifier projectExists(uint _projectId) {
        require(_projectId > 0 && _projectId <= projectCount, "Project does not exist.");
        _;
    }

    modifier taskExists(uint _taskId) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        _;
    }

    modifier validProjectStatus(uint _projectId, ProjectStatus _status) {
        require(projects[_projectId].status == _status, "Invalid project status for this action.");
        _;
    }

    modifier validTaskStatus(uint _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Invalid task status for this action.");
        _;
    }

    modifier hasRequiredSkills(address _member, uint[] _requiredSkillIds) {
        Member storage member = members[_member];
        require(member.isActive, "Member is not active.");
        for (uint i = 0; i < _requiredSkillIds.length; i++) {
            bool hasSkill = false;
            for (uint j = 0; j < member.registeredSkillIds.length; j++) {
                if (member.registeredSkillIds[j] == _requiredSkillIds[i]) {
                    hasSkill = true;
                    break;
                }
            }
            require(hasSkill, "Member does not have required skills.");
        }
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        memberCount = 0;
        skillCount = 0;
        projectCount = 0;
        taskCount = 0;
    }

    // -------- Member Management Functions --------

    function joinDAO() public payable {
        require(!members[msg.sender].isActive, "Already a member.");
        memberCount++;
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            joinedTimestamp: block.timestamp,
            registeredSkillIds: new uint[](0),
            reputation: 0,
            isActive: true
        });
        emit MemberJoined(msg.sender, block.timestamp);
    }

    function leaveDAO() public onlyMember {
        members[msg.sender].isActive = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    // -------- Skill Management Functions --------

    function addSkill(string memory _skillName) public onlyAdmin {
        skillCount++;
        skills[skillCount] = Skill({
            skillName: _skillName,
            isActive: true
        });
        emit SkillAdded(skillCount, _skillName);
    }

    function updateSkill(uint _skillId, string memory _newSkillName) public onlyAdmin skillExists(_skillId) {
        skills[_skillId].skillName = _newSkillName;
        emit SkillUpdated(_skillId, _newSkillName);
    }

    function registerSkills(uint[] memory _skillIds) public onlyMember {
        for (uint i = 0; i < _skillIds.length; i++) {
            skillExists(_skillIds[i]); // Check if skill exists before registering
        }
        members[msg.sender].registeredSkillIds = _skillIds;
        emit SkillsRegistered(msg.sender, _skillIds);
    }

    function updateRegisteredSkills(uint[] memory _skillIds) public onlyMember {
        registerSkills(_skillIds); // Reuses registerSkills logic for update
        emit SkillsUpdated(msg.sender, _skillIds);
    }

    function getSkillDetails(uint _skillId) public view skillExists(_skillId) returns (string memory skillName) {
        return skills[_skillId].skillName;
    }

    // -------- Member Profile Function --------
    function getMemberProfile(address _member) public view returns (address memberAddress, uint joinedTimestamp, uint[] memory registeredSkillIds, uint reputationPoints, bool isActive) {
        require(members[_member].isActive || members[_member].joinedTimestamp != 0, "Member profile not found."); // Check if member ever existed
        Member storage member = members[_member];
        return (member.memberAddress, member.joinedTimestamp, member.registeredSkillIds, member.reputation, member.isActive);
    }


    // -------- Project Management Functions --------

    function proposeProject(string memory _projectName, string memory _projectDescription, uint[] memory _requiredSkillIds, uint _projectBudget) public onlyMember {
        require(_requiredSkillIds.length > 0, "Project must require at least one skill.");
        for (uint i = 0; i < _requiredSkillIds.length; i++) {
            skillExists(_requiredSkillIds[i]); // Ensure required skills exist
        }

        projectCount++;
        projects[projectCount] = Project({
            projectName: _projectName,
            projectDescription: _projectDescription,
            requiredSkillIds: _requiredSkillIds,
            projectBudget: _projectBudget,
            status: ProjectStatus.Proposed,
            proposer: msg.sender,
            creationTimestamp: block.timestamp
        });
        emit ProjectProposed(projectCount, _projectName, msg.sender, block.timestamp);
    }

    function approveProject(uint _projectId) public onlyAdmin projectExists(_projectId) validProjectStatus(_projectId, ProjectStatus.Proposed) {
        projects[_projectId].status = ProjectStatus.Approved;
        emit ProjectApproved(_projectId);
    }

    function cancelProject(uint _projectId) public onlyAdmin projectExists(_projectId) {
        require(projects[_projectId].status != ProjectStatus.Completed, "Cannot cancel a completed project.");
        projects[_projectId].status = ProjectStatus.Cancelled;
        emit ProjectCancelled(_projectId);
    }

    function getProjectDetails(uint _projectId) public view projectExists(_projectId) returns (string memory projectName, string memory projectDescription, uint[] memory requiredSkillIds, uint projectBudget, ProjectStatus status, address proposer, uint creationTimestamp) {
        Project storage project = projects[_projectId];
        return (project.projectName, project.projectDescription, project.requiredSkillIds, project.projectBudget, project.status, project.proposer, project.creationTimestamp);
    }


    // -------- Task Management Functions --------

    function createTask(uint _projectId, string memory _taskDescription, uint[] memory _requiredSkillIds, uint _taskReward) public onlyMember projectExists(_projectId) validProjectStatus(_projectId, ProjectStatus.Approved) {
        require(projects[_projectId].proposer == msg.sender || msg.sender == admin, "Only project proposer or admin can create tasks.");
        require(_requiredSkillIds.length > 0, "Task must require at least one skill.");
        for (uint i = 0; i < _requiredSkillIds.length; i++) {
            skillExists(_requiredSkillIds[i]); // Ensure required skills exist
        }
        taskCount++;
        tasks[taskCount] = Task({
            projectId: _projectId,
            taskDescription: _taskDescription,
            requiredSkillIds: _requiredSkillIds,
            assignee: address(0), // Initially unassigned
            status: TaskStatus.Open,
            taskReward: _taskReward,
            creationTimestamp: block.timestamp
        });
        emit TaskCreated(taskCount, _projectId, _taskDescription, msg.sender, block.timestamp);
    }

    function assignTask(uint _taskId, address _assignee) public onlyMember taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(projects[tasks[_taskId].projectId].proposer == msg.sender || msg.sender == admin, "Only project proposer or admin can assign tasks.");
        require(members[_assignee].isActive, "Assignee must be an active member.");
        require(checkMemberSkillsForTask(_assignee, _taskId), "Assignee does not have required skills for this task.");

        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _assignee);
    }

    function applyForTask(uint _taskId) public onlyMember taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(tasks[_taskId].assignee == address(0), "Task is already assigned.");
        require(checkMemberSkillsForTask(msg.sender, _taskId), "You do not have the required skills for this task.");

        tasks[_taskId].status = TaskStatus.Applied; // Can be expanded for application management
        emit TaskApplied(_taskId, msg.sender);
        // In a more advanced version, applications could be tracked and proposer can choose from applicants.
        // For simplicity, in this version, application just marks the task as 'Applied' - manual assignment by proposer is still needed.
    }

    function completeTask(uint _taskId) public onlyMember taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Assigned) {
        require(tasks[_taskId].assignee == msg.sender, "Only assigned member can complete this task.");
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function verifyTaskCompletion(uint _taskId) public onlyMember taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) {
        require(projects[tasks[_taskId].projectId].proposer == msg.sender || msg.sender == admin, "Only project proposer or admin can verify tasks.");

        tasks[_taskId].status = TaskStatus.Verified;
        address assignee = tasks[_taskId].assignee;
        uint taskReward = tasks[_taskId].taskReward;

        // Transfer reward to assignee (simplified ETH transfer)
        payable(assignee).transfer(taskReward);

        // Increase reputation of the member
        increaseReputation(assignee, 10, "Task completion reward"); // Example reputation points

        emit TaskVerified(_taskId, msg.sender);
    }

    function getTaskDetails(uint _taskId) public view taskExists(_taskId) returns (uint projectId, string memory taskDescription, uint[] memory requiredSkillIds, address assignee, TaskStatus status, uint taskReward, uint creationTimestamp) {
        Task storage task = tasks[_taskId];
        return (task.projectId, task.taskDescription, task.requiredSkillIds, task.assignee, task.status, task.taskReward, task.creationTimestamp);
    }


    // -------- Reputation System Functions --------

    function increaseReputation(address _member, uint _points, string memory _reason) public onlyAdmin {
        reputation[_member] += _points;
        emit ReputationIncreased(_member, _points, _reason);
    }

    function decreaseReputation(address _member, uint _points, string memory _reason) public onlyAdmin {
        reputation[_member] -= _points;
        emit ReputationDecreased(_member, _points, _reason);
    }

    function viewReputation(address _member) public view returns (uint) {
        return reputation[_member];
    }

    // -------- Utility and Emergency Functions --------

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function emergencyWithdraw(address payable _recipient) public onlyAdmin {
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Emergency withdrawal failed.");
        emit EmergencyWithdrawal(_recipient, balance);
    }

    function getSkillCount() public view returns (uint) {
        return skillCount;
    }

    function getProjectCount() public view returns (uint) {
        return projectCount;
    }

    function getTaskCount() public view returns (uint) {
        return taskCount;
    }

    // -------- Internal Helper Functions --------

    function checkMemberSkillsForTask(address _member, uint _taskId) internal view returns (bool) {
        uint[] memory requiredSkills = tasks[_taskId].requiredSkillIds;
        uint[] memory memberSkills = members[_member].registeredSkillIds;

        for (uint i = 0; i < requiredSkills.length; i++) {
            bool hasSkill = false;
            for (uint j = 0; j < memberSkills.length; j++) {
                if (requiredSkills[i] == memberSkills[j]) {
                    hasSkill = true;
                    break;
                }
            }
            if (!hasSkill) {
                return false; // Member is missing a required skill
            }
        }
        return true; // Member has all required skills
    }
}
```