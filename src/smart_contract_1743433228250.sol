```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Advanced Decentralized Autonomous Organization (DAO) Contract
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a sophisticated DAO with advanced features beyond typical governance,
 * including dynamic task management, skill-based roles, reputation system, project-based funding,
 * and decentralized communication channels. It aims to be a creative and trendy example, avoiding
 * duplication of common open-source DAO implementations.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinDAO()`: Allows users to request membership.
 *    - `approveMembership(address _member)`: Admin function to approve pending membership requests.
 *    - `rejectMembership(address _member)`: Admin function to reject pending membership requests.
 *    - `revokeMembership(address _member)`: Admin function to remove a member from the DAO.
 *    - `isMember(address _account)`: Checks if an address is a member.
 *    - `getMemberCount()`: Returns the current number of members.
 *
 * **2. Role and Skill Management:**
 *    - `addRole(string memory _roleName)`: Admin function to add a new role to the DAO.
 *    - `assignRole(address _member, string memory _roleName)`: Admin function to assign a role to a member.
 *    - `removeRoleFromMember(address _member, string memory _roleName)`: Admin function to remove a role from a member.
 *    - `hasRole(address _member, string memory _roleName)`: Checks if a member has a specific role.
 *    - `getMemberRoles(address _member)`: Returns a list of roles assigned to a member.
 *
 * **3. Task Management System:**
 *    - `createTask(string memory _title, string memory _description, uint256 _reward)`: Member function to create a new task proposal.
 *    - `applyForTask(uint256 _taskId)`: Member function to apply for an open task.
 *    - `approveTaskApplication(uint256 _taskId, address _applicant)`: Admin/Task Creator function to approve a task application.
 *    - `startTask(uint256 _taskId)`: Assigned member function to start working on a task.
 *    - `submitTaskForReview(uint256 _taskId)`: Assigned member function to submit completed task for review.
 *    - `approveTaskCompletion(uint256 _taskId)`: Admin/Task Creator function to approve task completion and pay reward.
 *    - `rejectTaskCompletion(uint256 _taskId)`: Admin/Task Creator function to reject task completion (with feedback).
 *    - `getTaskDetails(uint256 _taskId)`: Returns details of a specific task.
 *    - `getOpenTasks()`: Returns a list of IDs of open tasks.
 *
 * **4. Reputation and Contribution Tracking:**
 *    - `increaseReputation(address _member, uint256 _amount)`: Admin function to manually increase member reputation.
 *    - `decreaseReputation(address _member, uint256 _amount)`: Admin function to manually decrease member reputation.
 *    - `getMemberReputation(address _member)`: Returns the reputation score of a member.
 *
 * **5. Decentralized Communication (Simplified Example - On-chain Messaging):**
 *    - `sendMessage(address _recipient, string memory _message)`: Member function to send an on-chain message to another member.
 *    - `getMessages(address _account)`: Member function to retrieve received on-chain messages.
 *
 * **6. Treasury and Rewards (Simplified Example - Direct Reward Payment):**
 *    - `fundTreasury() payable`: Allows anyone to contribute ETH to the DAO treasury.
 *    - `getTreasuryBalance()` view returns (uint256)`: Returns the current balance of the DAO treasury.
 *
 * **7. Admin and Security:**
 *    - `setAdmin(address _newAdmin)`: Function to change the DAO administrator.
 *    - `isAdmin(address _account)`: Checks if an address is the DAO administrator.
 *    - `emergencyStop()`: Admin function to halt critical functionalities in case of emergency.
 *    - `resumeFunctionality()`: Admin function to resume functionality after emergency stop.
 */

contract AdvancedDAO {
    // --- State Variables ---
    address public admin;
    bool public functionalityPaused;

    mapping(address => bool) public members;
    mapping(address => bool) public pendingMemberships;
    address[] public memberList;

    mapping(string => bool) public roles;
    mapping(address => string[]) public memberRoles;

    uint256 public taskCount;
    struct Task {
        string title;
        string description;
        uint256 reward;
        address creator;
        TaskStatus status;
        address assignedMember;
        address[] applicants;
        string feedback; // For rejection feedback
    }
    enum TaskStatus { Open, Applied, Assigned, InProgress, Submitted, Completed, Rejected }
    mapping(uint256 => Task) public tasks;

    mapping(address => uint256) public reputation;

    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }
    mapping(address => Message[]) public messages;

    // --- Events ---
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed member);
    event MembershipRevoked(address indexed member);

    event RoleAdded(string roleName);
    event RoleAssigned(address indexed member, string roleName);
    event RoleRemovedFromMember(address indexed member, string roleName);

    event TaskCreated(uint256 taskId, string title, address creator);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationApproved(uint256 taskId, address applicant);
    event TaskStarted(uint256 taskId, address member);
    event TaskSubmittedForReview(uint256 taskId, address member);
    event TaskCompletionApproved(uint256 taskId, uint256 reward, address member);
    event TaskCompletionRejected(uint256 taskId, string feedback, address member);

    event ReputationIncreased(address indexed member, uint256 amount);
    event ReputationDecreased(address indexed member, uint256 amount);

    event MessageSent(address indexed sender, address indexed recipient, string message);
    event TreasuryFunded(address sender, uint256 amount);
    event EmergencyStopTriggered();
    event FunctionalityResumed();


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier functionalityActive() {
        require(!functionalityPaused, "Functionality is currently paused.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < taskCount && _taskId >= 0, "Task does not exist.");
        _;
    }

    modifier onlyTaskCreatorOrAdmin(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender || msg.sender == admin, "Only task creator or admin can call this.");
        _;
    }

    modifier onlyAssignedMember(uint256 _taskId) {
        require(tasks[_taskId].assignedMember == msg.sender, "Only assigned member can call this.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not as expected.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        functionalityPaused = false;
    }

    // --- 1. Membership Management ---
    function joinDAO() external functionalityActive {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMemberships[msg.sender], "Membership request already pending.");
        pendingMemberships[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin functionalityActive {
        require(pendingMemberships[_member], "No pending membership request.");
        require(!members[_member], "Already a member.");
        pendingMemberships[_member] = false;
        members[_member] = true;
        memberList.push(_member);
        emit MembershipApproved(_member);
    }

    function rejectMembership(address _member) external onlyAdmin functionalityActive {
        require(pendingMemberships[_member], "No pending membership request.");
        pendingMemberships[_member] = false;
        emit MembershipRejected(_member);
    }

    function revokeMembership(address _member) external onlyAdmin functionalityActive {
        require(members[_member], "Not a member.");
        members[_member] = false;
        // Remove from memberList (inefficient for large lists, consider optimization in real-world)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    // --- 2. Role and Skill Management ---
    function addRole(string memory _roleName) external onlyAdmin functionalityActive {
        require(!roles[_roleName], "Role already exists.");
        roles[_roleName] = true;
        emit RoleAdded(_roleName);
    }

    function assignRole(address _member, string memory _roleName) external onlyAdmin functionalityActive {
        require(members[_member], "Address is not a member.");
        require(roles[_roleName], "Role does not exist.");
        bool roleExists = false;
        for(uint i=0; i < memberRoles[_member].length; i++){
            if(keccak256(bytes(memberRoles[_member][i])) == keccak256(bytes(_roleName))){
                roleExists = true;
                break;
            }
        }
        require(!roleExists, "Member already has this role.");

        memberRoles[_member].push(_roleName);
        emit RoleAssigned(_member, _roleName);
    }

    function removeRoleFromMember(address _member, string memory _roleName) external onlyAdmin functionalityActive {
        require(members[_member], "Address is not a member.");
        bool roleFound = false;
        uint256 roleIndex = 0;
        for(uint i=0; i < memberRoles[_member].length; i++){
            if(keccak256(bytes(memberRoles[_member][i])) == keccak256(bytes(_roleName))){
                roleFound = true;
                roleIndex = i;
                break;
            }
        }
        require(roleFound, "Member does not have this role.");

        if (memberRoles[_member].length > 1) {
            memberRoles[_member][roleIndex] = memberRoles[_member][memberRoles[_member].length - 1];
            memberRoles[_member].pop();
        } else {
            delete memberRoles[_member]; // Clear mapping if only one role
        }


        emit RoleRemovedFromMember(_member, _roleName);
    }

    function hasRole(address _member, string memory _roleName) external view returns (bool) {
        for(uint i=0; i < memberRoles[_member].length; i++){
            if(keccak256(bytes(memberRoles[_member][i])) == keccak256(bytes(_roleName))){
                return true;
            }
        }
        return false;
    }

    function getMemberRoles(address _member) external view returns (string[] memory) {
        return memberRoles[_member];
    }

    // --- 3. Task Management System ---
    function createTask(string memory _title, string memory _description, uint256 _reward) external onlyMember functionalityActive {
        require(_reward > 0, "Reward must be positive.");
        taskCount++;
        tasks[taskCount] = Task({
            title: _title,
            description: _description,
            reward: _reward,
            creator: msg.sender,
            status: TaskStatus.Open,
            assignedMember: address(0),
            applicants: new address[](0),
            feedback: ""
        });
        emit TaskCreated(taskCount, _title, msg.sender);
    }

    function applyForTask(uint256 _taskId) external onlyMember functionalityActive taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) {
        require(tasks[_taskId].assignedMember == address(0), "Task already assigned.");
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            require(tasks[_taskId].applicants[i] != msg.sender, "Already applied for this task.");
        }
        tasks[_taskId].applicants.push(msg.sender);
        tasks[_taskId].status = TaskStatus.Applied; // Change status to Applied when first application is made
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function approveTaskApplication(uint256 _taskId, address _applicant) external onlyTaskCreatorOrAdmin(_taskId) functionalityActive taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Applied) {
        bool applicantFound = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _applicant) {
                applicantFound = true;
                break;
            }
        }
        require(applicantFound, "Applicant did not apply for this task.");
        require(tasks[_taskId].assignedMember == address(0), "Task already assigned.");

        tasks[_taskId].assignedMember = _applicant;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskApplicationApproved(_taskId, _applicant);
    }

    function startTask(uint256 _taskId) external onlyAssignedMember(_taskId) functionalityActive taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Assigned) {
        tasks[_taskId].status = TaskStatus.InProgress;
        emit TaskStarted(_taskId, msg.sender);
    }

    function submitTaskForReview(uint256 _taskId) external onlyAssignedMember(_taskId) functionalityActive taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.InProgress) {
        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmittedForReview(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external onlyTaskCreatorOrAdmin(_taskId) functionalityActive taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) {
        require(address(this).balance >= tasks[_taskId].reward, "Insufficient DAO treasury balance to pay reward.");
        payable(tasks[_taskId].assignedMember).transfer(tasks[_taskId].reward);
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionApproved(_taskId, tasks[_taskId].reward, tasks[_taskId].assignedMember);
        increaseReputation(tasks[_taskId].assignedMember, 10); // Example reputation increase on task completion
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _feedback) external onlyTaskCreatorOrAdmin(_taskId) functionalityActive taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) {
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].feedback = _feedback;
        emit TaskCompletionRejected(_taskId, _feedback, tasks[_taskId].assignedMember);
        decreaseReputation(tasks[_taskId].assignedMember, 5); // Example reputation decrease on rejected task
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](taskCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                openTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of open tasks
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTaskIds[i];
        }
        return result;
    }

    // --- 4. Reputation and Contribution Tracking ---
    function increaseReputation(address _member, uint256 _amount) internal onlyAdmin functionalityActive { // Internal to be controlled within contract logic
        reputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount);
    }

    function decreaseReputation(address _member, uint256 _amount) internal onlyAdmin functionalityActive { // Internal to be controlled within contract logic
        reputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return reputation[_member];
    }

    // --- 5. Decentralized Communication (Simplified Example - On-chain Messaging) ---
    function sendMessage(address _recipient, string memory _message) external onlyMember functionalityActive {
        require(_recipient != address(0), "Invalid recipient address.");
        messages[_recipient].push(Message({
            sender: msg.sender,
            content: _message,
            timestamp: block.timestamp
        }));
        emit MessageSent(msg.sender, _recipient, _message);
    }

    function getMessages(address _account) external view onlyMember returns (Message[] memory) {
        return messages[_account];
    }

    // --- 6. Treasury and Rewards (Simplified Example - Direct Reward Payment) ---
    function fundTreasury() external payable functionalityActive {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- 7. Admin and Security ---
    function setAdmin(address _newAdmin) external onlyAdmin functionalityActive {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
    }

    function isAdmin(address _account) external view returns (bool) {
        return _account == admin;
    }

    function emergencyStop() external onlyAdmin {
        functionalityPaused = true;
        emit EmergencyStopTriggered();
    }

    function resumeFunctionality() external onlyAdmin {
        functionalityPaused = false;
        emit FunctionalityResumed();
    }

    // Fallback function to receive ETH
    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }
}
```