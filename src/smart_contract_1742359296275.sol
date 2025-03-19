```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Reputation and Skill-Based Task Assignment
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a DAO with a dynamic reputation system and skill-based task assignment.
 *      It focuses on decentralized task management, member skill verification, and reputation-driven governance.
 *      This is a conceptual example and requires thorough security audits and testing before production use.
 *
 * Function Summary:
 *
 * **Membership & Reputation:**
 * 1. `joinDAO()`: Allows a new member to join the DAO.
 * 2. `leaveDAO()`: Allows a member to leave the DAO.
 * 3. `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 * 4. `increaseReputation(address _member, uint256 _amount)`: Increases a member's reputation (Admin/Task Reviewer).
 * 5. `decreaseReputation(address _member, uint256 _amount)`: Decreases a member's reputation (Admin/Task Reviewer).
 * 6. `reportMember(address _member, string _reason)`: Allows members to report other members for misconduct (Admin review).
 * 7. `getReportCount(address _member)`: Retrieves the report count for a member.
 *
 * **Skill Management:**
 * 8. `addSkill(string _skillName)`: Adds a new skill to the DAO's skill list (Admin).
 * 9. `removeSkill(uint256 _skillId)`: Removes a skill from the DAO's skill list (Admin).
 * 10. `getSkillName(uint256 _skillId)`: Retrieves the name of a skill.
 * 11. `declareSkill(uint256 _skillId)`: Allows a member to declare proficiency in a skill.
 * 12. `undeclareSkill(uint256 _skillId)`: Allows a member to remove a declared skill.
 * 13. `getMemberSkills(address _member)`: Retrieves the list of skills declared by a member.
 *
 * **Task Management:**
 * 14. `createTask(string _title, string _description, uint256 _reward, uint256[] _requiredSkills)`: Creates a new task (Admin/Reputable Members).
 * 15. `assignTask(uint256 _taskId, address _assignee)`: Assigns a task to a member based on skills (Automated/Admin).
 * 16. `claimTask(uint256 _taskId)`: Allows a member to claim an open task if they possess the required skills.
 * 17. `submitTask(uint256 _taskId, string _submissionDetails)`: Allows a member to submit their work for a task.
 * 18. `reviewTaskSubmission(uint256 _taskId, bool _isApproved, string _reviewComment)`: Reviews a task submission and approves or rejects it (Task Reviewer/Admin).
 * 19. `getTaskDetails(uint256 _taskId)`: Retrieves details of a specific task.
 * 20. `getOpenTasks()`: Retrieves a list of open tasks.
 * 21. `getMemberAssignedTasks(address _member)`: Retrieves a list of tasks assigned to a member.
 *
 * **Governance & Admin:**
 * 22. `addAdmin(address _newAdmin)`: Adds a new admin (Current Admin).
 * 23. `removeAdmin(address _adminToRemove)`: Removes an admin (Current Admin - cannot remove self if only admin).
 * 24. `pauseContract()`: Pauses critical contract functions (Admin).
 * 25. `unpauseContract()`: Unpauses contract functions (Admin).
 * 26. `isPaused()`: Checks if the contract is paused.
 * 27. `setTaskReviewerRole(address _reviewer, bool _isReviewer)`: Assigns or removes Task Reviewer role (Admin).
 * 28. `isTaskReviewer(address _account)`: Checks if an account is a Task Reviewer.
 * 29. `getDAOMembers()`: Retrieves a list of all DAO members.
 * 30. `getDAOAdmins()`: Retrieves a list of all DAO admins.
 * 31. `getTotalMembers()`: Retrieves the total number of DAO members.
 * 32. `getTotalTasks()`: Retrieves the total number of tasks created.
 * 33. `getTotalSkills()`: Retrieves the total number of skills defined.
 * 34. `getContractBalance()`: Retrieves the contract's ETH balance.
 * 35. `withdrawFunds(address _recipient, uint256 _amount)`: Allows admin to withdraw funds from the contract (Admin).
 */
contract DynamicSkillDAO {
    // --- Structs & Enums ---

    struct Member {
        uint256 reputation;
        uint256 joinTimestamp;
        uint256 reportCount;
        mapping(uint256 => bool) declaredSkills; // skillId => isDeclared
    }

    struct Skill {
        string name;
    }

    struct Task {
        string title;
        string description;
        uint256 reward;
        TaskStatus status;
        address assignee;
        address creator;
        uint256 creationTimestamp;
        string submissionDetails;
        string reviewComment;
        bool isApproved;
        uint256[] requiredSkills;
    }

    enum TaskStatus {
        OPEN,
        ASSIGNED,
        SUBMITTED,
        REVIEWED,
        COMPLETED,
        CLOSED
    }

    // --- State Variables ---

    mapping(address => Member) public members;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Task) public tasks;

    address[] public daoMembers;
    address[] public daoAdmins;
    uint256[] public skillList;
    uint256[] public taskList;

    uint256 public nextSkillId = 1;
    uint256 public nextTaskId = 1;

    mapping(address => bool) public taskReviewers;
    bool public paused = false;

    uint256 public constant INITIAL_REPUTATION = 100;
    uint256 public constant MIN_REPUTATION_FOR_TASK_CREATION = 200; // Example value

    // --- Events ---

    event MemberJoined(address memberAddress, uint256 timestamp);
    event MemberLeft(address memberAddress, uint256 timestamp);
    event ReputationIncreased(address memberAddress, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address memberAddress, uint256 amount, uint256 newReputation);
    event MemberReported(address reporter, address reportedMember, string reason, uint256 reportCount);

    event SkillAdded(uint256 skillId, string skillName);
    event SkillRemoved(uint256 skillId);
    event SkillDeclared(address memberAddress, uint256 skillId);
    event SkillUndeclared(address memberAddress, uint256 skillId);

    event TaskCreated(uint256 taskId, string title, address creator, uint256 timestamp);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskClaimed(uint256 taskId, addressclaimer);
    event TaskSubmitted(uint256 taskId, address submitter, string submissionDetails);
    event TaskReviewed(uint256 taskId, address reviewer, bool isApproved, string reviewComment);
    event TaskCompleted(uint256 taskId, address assignee);

    event AdminAdded(address newAdmin, address addedBy);
    event AdminRemoved(address removedAdmin, address removedBy);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);
    event TaskReviewerSet(address reviewerAddress, bool isReviewer, address setBy);
    event FundsWithdrawn(address recipient, uint256 amount, address withdrawnBy);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admins can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can perform this action.");
        _;
    }

    modifier onlyTaskReviewer() {
        require(isTaskReviewer(msg.sender) || isAdmin(msg.sender), "Only task reviewers or admins can perform this action.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].creationTimestamp != 0, "Task does not exist.");
        _;
    }

    modifier skillExists(uint256 _skillId) {
        require(skills[_skillId].name.length > 0, "Skill does not exist.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---

    constructor() {
        daoAdmins.push(msg.sender); // Deployer is the first admin
        emit AdminAdded(msg.sender, address(0));
    }

    // --- Membership & Reputation Functions ---

    function joinDAO() external notPaused {
        require(!isMember(msg.sender), "Already a member.");
        members[msg.sender] = Member({
            reputation: INITIAL_REPUTATION,
            joinTimestamp: block.timestamp,
            reportCount: 0,
            declaredSkills: mapping(uint256 => bool)()
        });
        daoMembers.push(msg.sender);
        emit MemberJoined(msg.sender, block.timestamp);
    }

    function leaveDAO() external onlyMember notPaused {
        require(isMember(msg.sender), "Not a member.");
        // Remove from member array (inefficient for large arrays in real-world - consider better data structure)
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == msg.sender) {
                daoMembers[i] = daoMembers[daoMembers.length - 1];
                daoMembers.pop();
                break;
            }
        }
        delete members[msg.sender];
        emit MemberLeft(msg.sender, block.timestamp);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }

    function increaseReputation(address _member, uint256 _amount) external onlyTaskReviewer notPaused {
        require(isMember(_member), "Not a member.");
        members[_member].reputation += _amount;
        emit ReputationIncreased(_member, _amount, members[_member].reputation);
    }

    function decreaseReputation(address _member, uint256 _amount) external onlyAdmin notPaused {
        require(isMember(_member), "Not a member.");
        require(members[_member].reputation >= _amount, "Reputation cannot be negative.");
        members[_member].reputation -= _amount;
        emit ReputationDecreased(_member, _amount, members[_member].reputation);
    }

    function reportMember(address _member, string memory _reason) external onlyMember notPaused {
        require(isMember(_member) && _member != msg.sender, "Invalid member to report.");
        members[_member].reportCount++;
        emit MemberReported(msg.sender, _member, _reason, members[_member].reportCount);
        // Admin can review reports and take action (e.g., decrease reputation, ban - not implemented here)
    }

    function getReportCount(address _member) external view returns (uint256) {
        return members[_member].reportCount;
    }

    // --- Skill Management Functions ---

    function addSkill(string memory _skillName) external onlyAdmin notPaused {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        skills[nextSkillId] = Skill({name: _skillName});
        skillList.push(nextSkillId);
        emit SkillAdded(nextSkillId, _skillName);
        nextSkillId++;
    }

    function removeSkill(uint256 _skillId) external onlyAdmin skillExists(_skillId) notPaused {
        delete skills[_skillId];
        // Remove from skill list (inefficient for large arrays - consider better data structure)
        for (uint256 i = 0; i < skillList.length; i++) {
            if (skillList[i] == _skillId) {
                skillList[i] = skillList[skillList.length - 1];
                skillList.pop();
                break;
            }
        }
        emit SkillRemoved(_skillId);
    }

    function getSkillName(uint256 _skillId) external view skillExists(_skillId) returns (string memory) {
        return skills[_skillId].name;
    }

    function declareSkill(uint256 _skillId) external onlyMember skillExists(_skillId) notPaused {
        members[msg.sender].declaredSkills[_skillId] = true;
        emit SkillDeclared(msg.sender, _skillId);
    }

    function undeclareSkill(uint256 _skillId) external onlyMember skillExists(_skillId) notPaused {
        delete members[msg.sender].declaredSkills[_skillId];
        emit SkillUndeclared(msg.sender, _skillId);
    }

    function getMemberSkills(address _member) external view onlyMember returns (uint256[] memory) {
        require(isMember(_member), "Not a member.");
        uint256[] memory declaredSkillIds = new uint256[](skillList.length); // Max possible size, will trim later
        uint256 count = 0;
        for (uint256 i = 1; i < nextSkillId; i++) { // Iterate through possible skill IDs
            if (members[_member].declaredSkills[i]) {
                declaredSkillIds[count] = i;
                count++;
            }
        }
        // Trim the array to actual size
        uint256[] memory trimmedSkillIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedSkillIds[i] = declaredSkillIds[i];
        }
        return trimmedSkillIds;
    }

    // --- Task Management Functions ---

    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256[] memory _requiredSkills
    ) external onlyMember notPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(members[msg.sender].reputation >= MIN_REPUTATION_FOR_TASK_CREATION || isAdmin(msg.sender), "Insufficient reputation to create tasks.");

        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            require(skillExists(_requiredSkills[i]), "Required skill does not exist.");
        }

        tasks[nextTaskId] = Task({
            title: _title,
            description: _description,
            reward: _reward,
            status: TaskStatus.OPEN,
            assignee: address(0),
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            submissionDetails: "",
            reviewComment: "",
            isApproved: false,
            requiredSkills: _requiredSkills
        });
        taskList.push(nextTaskId);
        emit TaskCreated(nextTaskId, _title, msg.sender, block.timestamp);
        nextTaskId++;
    }

    function assignTask(uint256 _taskId, address _assignee) external onlyAdmin taskExists(_taskId) notPaused {
        require(tasks[_taskId].status == TaskStatus.OPEN, "Task is not open for assignment.");
        require(isMember(_assignee), "Assignee is not a member.");

        // Basic skill check (can be more sophisticated)
        bool hasRequiredSkills = true;
        for (uint256 i = 0; i < tasks[_taskId].requiredSkills.length; i++) {
            if (!members[_assignee].declaredSkills[tasks[_taskId].requiredSkills[i]]) {
                hasRequiredSkills = false;
                break;
            }
        }
        require(hasRequiredSkills, "Assignee does not possess required skills.");

        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.ASSIGNED;
        emit TaskAssigned(_taskId, _assignee);
    }

    function claimTask(uint256 _taskId) external onlyMember taskExists(_taskId) notPaused {
        require(tasks[_taskId].status == TaskStatus.OPEN, "Task is not open for claiming.");
        require(tasks[_taskId].assignee == address(0), "Task is already assigned.");

        // Skill check
        bool hasRequiredSkills = true;
        for (uint256 i = 0; i < tasks[_taskId].requiredSkills.length; i++) {
            if (!members[msg.sender].declaredSkills[tasks[_taskId].requiredSkills[i]]) {
                hasRequiredSkills = false;
                break;
            }
        }
        require(hasRequiredSkills, "You do not possess required skills for this task.");

        tasks[_taskId].assignee = msg.sender;
        tasks[_taskId].status = TaskStatus.ASSIGNED;
        emit TaskClaimed(_taskId, msg.sender);
        emit TaskAssigned(_taskId, msg.sender); // Also emit Assigned event for consistency
    }

    function submitTask(uint256 _taskId, string memory _submissionDetails) external onlyMember taskExists(_taskId) notPaused {
        require(tasks[_taskId].status == TaskStatus.ASSIGNED, "Task is not assigned to be submitted.");
        require(tasks[_taskId].assignee == msg.sender, "Task is not assigned to you.");
        require(bytes(_submissionDetails).length > 0, "Submission details cannot be empty.");

        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].status = TaskStatus.SUBMITTED;
        emit TaskSubmitted(_taskId, msg.sender, _submissionDetails);
    }

    function reviewTaskSubmission(uint256 _taskId, bool _isApproved, string memory _reviewComment) external onlyTaskReviewer taskExists(_taskId) notPaused {
        require(tasks[_taskId].status == TaskStatus.SUBMITTED, "Task is not submitted for review.");

        tasks[_taskId].isApproved = _isApproved;
        tasks[_taskId].reviewComment = _reviewComment;
        tasks[_taskId].status = TaskStatus.REVIEWED;

        if (_isApproved) {
            tasks[_taskId].status = TaskStatus.COMPLETED;
            payable(tasks[_taskId].assignee).transfer(tasks[_taskId].reward); // Pay reward
            increaseReputation(tasks[_taskId].assignee, tasks[_taskId].reward); // Increase reputation based on reward (example)
            emit TaskCompleted(_taskId, tasks[_taskId].assignee);
        } else {
            tasks[_taskId].status = TaskStatus.OPEN; // Reopen task if not approved
            tasks[_taskId].assignee = address(0); // Unassign task
        }
        emit TaskReviewed(_taskId, msg.sender, _isApproved, _reviewComment);
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](taskList.length); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < taskList.length; i++) {
            if (tasks[taskList[i]].status == TaskStatus.OPEN) {
                openTaskIds[count] = taskList[i];
                count++;
            }
        }
        // Trim the array
        uint256[] memory trimmedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTaskIds[i] = openTaskIds[i];
        }
        return trimmedTaskIds;
    }

    function getMemberAssignedTasks(address _member) external view onlyMember returns (uint256[] memory) {
        require(isMember(_member), "Not a member.");
        uint256[] memory assignedTaskIds = new uint256[](taskList.length); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < taskList.length; i++) {
            if (tasks[taskList[i]].assignee == _member && tasks[taskList[i]].status == TaskStatus.ASSIGNED) {
                assignedTaskIds[count] = taskList[i];
                count++;
            }
        }
        // Trim the array
        uint256[] memory trimmedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTaskIds[i] = assignedTaskIds[i];
        }
        return trimmedTaskIds;
    }


    // --- Governance & Admin Functions ---

    function addAdmin(address _newAdmin) external onlyAdmin notPaused {
        require(!isAdmin(_newAdmin), "Address is already an admin.");
        daoAdmins.push(_newAdmin);
        emit AdminAdded(_newAdmin, msg.sender);
    }

    function removeAdmin(address _adminToRemove) external onlyAdmin notPaused {
        require(isAdmin(_adminToRemove), "Address is not an admin.");
        require(daoAdmins.length > 1 || _adminToRemove != msg.sender, "Cannot remove the only admin (or yourself if you are the only admin).");
        // Remove from admin array (inefficient for large arrays - consider better data structure)
        for (uint256 i = 0; i < daoAdmins.length; i++) {
            if (daoAdmins[i] == _adminToRemove) {
                daoAdmins[i] = daoAdmins[daoAdmins.length - 1];
                daoAdmins.pop();
                break;
            }
        }
        emit AdminRemoved(_adminToRemove, msg.sender);
    }

    function pauseContract() external onlyAdmin notPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function isPaused() external view returns (bool) {
        return paused;
    }

    function setTaskReviewerRole(address _reviewer, bool _isReviewer) external onlyAdmin notPaused {
        taskReviewers[_reviewer] = _isReviewer;
        emit TaskReviewerSet(_reviewer, _isReviewer, msg.sender);
    }

    function isTaskReviewer(address _account) public view returns (bool) {
        return taskReviewers[_account];
    }

    // --- Getter Functions for Lists and Counts ---

    function getDAOMembers() external view onlyAdmin returns (address[] memory) {
        return daoMembers;
    }

    function getDAOAdmins() external view onlyAdmin returns (address[] memory) {
        return daoAdmins;
    }

    function getTotalMembers() external view returns (uint256) {
        return daoMembers.length;
    }

    function getTotalTasks() external view returns (uint256) {
        return taskList.length;
    }

    function getTotalSkills() external view returns (uint256) {
        return skillList.length;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFunds(address _recipient, uint256 _amount) external onlyAdmin notPaused {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount, msg.sender);
    }


    // --- Internal Helper Functions ---

    function isMember(address _account) internal view returns (bool) {
        return members[_account].joinTimestamp != 0; // Check if member struct is initialized
    }

    function isAdmin(address _account) internal view returns (bool) {
        for (uint256 i = 0; i < daoAdmins.length; i++) {
            if (daoAdmins[i] == _account) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {} // Allow contract to receive ETH
}
```