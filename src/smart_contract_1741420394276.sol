```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill-Based Task & Reputation Platform - SkillDAO
 * @author Bard (AI Assistant)
 * @dev A smart contract for creating a decentralized platform where users can offer and request tasks based on skills,
 *      build reputation through successful task completion, and participate in a dynamic skill marketplace.
 *
 * **Outline & Function Summary:**
 *
 * **1. User & Profile Management:**
 *    - `registerUser(string _username, string _profileDescription)`: Allows a user to register on the platform, creating a profile.
 *    - `updateProfile(string _profileDescription)`: Allows a registered user to update their profile description.
 *    - `setUsername(string _newUsername)`: Allows a registered user to change their username.
 *    - `getUserProfile(address _userAddress) view returns (string username, string profileDescription, uint256 reputationScore)`: Retrieves a user's profile information and reputation score.
 *    - `getUserReputation(address _userAddress) view returns (uint256 reputationScore)`: Retrieves only the reputation score of a user.
 *
 * **2. Skill Management:**
 *    - `addSkill(string _skillName)`: Allows the contract owner to add new skills to the platform.
 *    - `getSkill(uint256 _skillId) view returns (string skillName)`: Retrieves the name of a skill by its ID.
 *    - `getAllSkills() view returns (string[] skillNames)`: Retrieves a list of all skills available on the platform.
 *    - `getUserSkills(address _userAddress) view returns (uint256[] skillIds)`: Retrieves the IDs of skills associated with a user.
 *    - `addUserSkill(uint256 _skillId)`: Allows a registered user to add a skill to their profile.
 *    - `removeUserSkill(uint256 _skillId)`: Allows a registered user to remove a skill from their profile.
 *
 * **3. Task Management:**
 *    - `createTask(string _taskTitle, string _taskDescription, uint256 _skillId, uint256 _rewardAmount)`: Allows a registered user to create a new task, specifying required skill and reward.
 *    - `getTaskDetails(uint256 _taskId) view returns (TaskDetails)`: Retrieves detailed information about a specific task.
 *    - `getAllTasks() view returns (uint256[] taskIds)`: Retrieves a list of all task IDs.
 *    - `getTasksBySkill(uint256 _skillId) view returns (uint256[] taskIds)`: Retrieves a list of task IDs filtered by a specific skill.
 *    - `assignTask(uint256 _taskId, address _assignee)`: Allows a task creator to assign a task to a specific registered user.
 *    - `submitTask(uint256 _taskId)`: Allows the assigned user to submit a completed task.
 *    - `verifyTaskCompletion(uint256 _taskId)`: Allows the task creator to verify that a submitted task is completed successfully.
 *    - `disputeTask(uint256 _taskId, string _disputeReason)`: Allows either the task creator or assignee to dispute a task (e.g., for non-completion or unfair verification).
 *    - `resolveDispute(uint256 _taskId, bool _taskCompleted)`: Allows the contract owner (or a designated arbitrator - can be further decentralized) to resolve a disputed task.
 *    - `cancelTask(uint256 _taskId)`: Allows the task creator to cancel a task before it's assigned.
 *
 * **4. Reputation & Reward System:**
 *    - `increaseReputation(address _userAddress, uint256 _reputationIncrease)`: Allows the contract owner to manually increase a user's reputation (e.g., for initial seeding or special contributions).
 *    - `decreaseReputation(address _userAddress, uint256 _reputationDecrease)`: Allows the contract owner to manually decrease a user's reputation (e.g., for platform rule violations).
 *    - `distributeReward(address _recipient, uint256 _amount)`: Allows the contract owner to distribute rewards (e.g., platform tokens) to users (can be extended for task rewards, staking rewards, etc.).
 *
 * **5. Platform Administration & Configuration:**
 *    - `setPlatformFee(uint256 _newFee)`: Allows the contract owner to set a platform fee (e.g., for task creation or completion - not implemented in this basic version but can be added).
 *    - `getPlatformFee() view returns (uint256 platformFee)`: Retrieves the current platform fee.
 *    - `transferOwnership(address newOwner)`: Allows the contract owner to transfer ownership of the contract.
 *    - `withdrawPlatformBalance()`: Allows the contract owner to withdraw any accumulated platform balance (e.g., fees - not implemented in this basic version but related to `setPlatformFee`).
 */
contract SkillDAO {
    // Structs
    struct UserProfile {
        string username;
        string profileDescription;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Skill {
        string skillName;
    }

    struct TaskDetails {
        string taskTitle;
        string taskDescription;
        uint256 skillId;
        address creator;
        address assignee;
        uint256 rewardAmount;
        TaskStatus status;
        string disputeReason;
    }

    enum TaskStatus {
        Open,
        Assigned,
        Submitted,
        Verified,
        Disputed,
        Cancelled
    }

    // State Variables
    mapping(address => UserProfile) public users;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => TaskDetails) public tasks;
    mapping(address => uint256[]) public userTasks; // Tasks associated with a user
    mapping(uint256 => uint256[]) public skillTasks; // Tasks associated with a skill

    uint256 public skillCount;
    uint256 public taskCount;
    address public owner;
    uint256 public platformFee; // Example of a platform fee (not used in this basic version)

    // Events
    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event UsernameUpdated(address userAddress, string newUsername);
    event SkillAdded(uint256 skillId, string skillName);
    event UserSkillAdded(address userAddress, uint256 skillId);
    event UserSkillRemoved(address userAddress, uint256 skillId);
    event TaskCreated(uint256 taskId, address creator, uint256 skillId, uint256 rewardAmount);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskSubmitted(uint256 taskId, address submitter);
    event TaskVerified(uint256 taskId, address verifier);
    event TaskDisputed(uint256 taskId, address disputer, string reason);
    event TaskDisputeResolved(uint256 taskId, bool taskCompleted, address resolver);
    event TaskCancelled(uint256 taskId, address canceller);
    event ReputationIncreased(address userAddress, uint256 increaseAmount, uint256 newReputation);
    event ReputationDecreased(address userAddress, uint256 decreaseAmount, uint256 newReputation);
    event RewardDistributed(address recipient, uint256 amount);
    event PlatformFeeSet(uint256 newFee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User not registered.");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID.");
        _;
    }

    modifier taskCreatorOnly(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier taskAssigneeOnly(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }

    modifier taskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not valid for this action.");
        _;
    }


    // Constructor
    constructor() {
        owner = msg.sender;
        skillCount = 0;
        taskCount = 0;
        platformFee = 0; // Initial platform fee is 0
    }

    // -------------------------------------------------------------------------
    // 1. User & Profile Management
    // -------------------------------------------------------------------------

    function registerUser(string memory _username, string memory _profileDescription) public {
        require(!users[msg.sender].isRegistered, "User already registered.");
        require(bytes(_username).length > 0, "Username cannot be empty.");
        users[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            reputationScore: 0,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileDescription) public onlyRegisteredUser {
        users[msg.sender].profileDescription = _profileDescription;
        emit ProfileUpdated(msg.sender);
    }

    function setUsername(string memory _newUsername) public onlyRegisteredUser {
        require(bytes(_newUsername).length > 0, "Username cannot be empty.");
        users[msg.sender].username = _newUsername;
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    function getUserProfile(address _userAddress) public view returns (string memory username, string memory profileDescription, uint256 reputationScore) {
        require(users[_userAddress].isRegistered, "User not registered.");
        UserProfile memory profile = users[_userAddress];
        return (profile.username, profile.profileDescription, profile.reputationScore);
    }

    function getUserReputation(address _userAddress) public view returns (uint256 reputationScore) {
        require(users[_userAddress].isRegistered, "User not registered.");
        return users[_userAddress].reputationScore;
    }


    // -------------------------------------------------------------------------
    // 2. Skill Management
    // -------------------------------------------------------------------------

    function addSkill(string memory _skillName) public onlyOwner {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        skillCount++;
        skills[skillCount] = Skill({skillName: _skillName});
        emit SkillAdded(skillCount, _skillName);
    }

    function getSkill(uint256 _skillId) public view returns (string memory skillName) {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        return skills[_skillId].skillName;
    }

    function getAllSkills() public view returns (string[] memory skillNames) {
        skillNames = new string[](skillCount);
        for (uint256 i = 1; i <= skillCount; i++) {
            skillNames[i-1] = skills[i].skillName;
        }
        return skillNames;
    }

    function getUserSkills(address _userAddress) public view returns (uint256[] memory skillIds) {
        return userTasks[_userAddress]; // Reusing userTasks mapping for skills (potential naming improvement needed)
    }

    function addUserSkill(uint256 _skillId) public onlyRegisteredUser {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        bool skillExists = false;
        uint256[] storage userSkillList = userTasks[msg.sender]; // Reusing userTasks mapping for skills
        for(uint256 i=0; i < userSkillList.length; i++){
            if(userSkillList[i] == _skillId){
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added to user profile.");

        userTasks[msg.sender].push(_skillId); // Reusing userTasks mapping for skills
        emit UserSkillAdded(msg.sender, _skillId);
    }

    function removeUserSkill(uint256 _skillId) public onlyRegisteredUser {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        uint256[] storage userSkillList = userTasks[msg.sender]; // Reusing userTasks mapping for skills
        bool skillRemoved = false;
        for (uint256 i = 0; i < userSkillList.length; i++) {
            if (userSkillList[i] == _skillId) {
                userSkillList[i] = userSkillList[userSkillList.length - 1];
                userSkillList.pop();
                skillRemoved = true;
                break;
            }
        }
        require(skillRemoved, "Skill not found in user profile.");
        emit UserSkillRemoved(msg.sender, _skillId);
    }


    // -------------------------------------------------------------------------
    // 3. Task Management
    // -------------------------------------------------------------------------

    function createTask(string memory _taskTitle, string memory _taskDescription, uint256 _skillId, uint256 _rewardAmount) public onlyRegisteredUser {
        require(bytes(_taskTitle).length > 0 && bytes(_taskDescription).length > 0, "Task title and description cannot be empty.");
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");

        taskCount++;
        tasks[taskCount] = TaskDetails({
            taskTitle: _taskTitle,
            taskDescription: _taskDescription,
            skillId: _skillId,
            creator: msg.sender,
            assignee: address(0), // Initially no assignee
            rewardAmount: _rewardAmount,
            status: TaskStatus.Open,
            disputeReason: ""
        });
        skillTasks[_skillId].push(taskCount);
        emit TaskCreated(taskCount, msg.sender, _skillId, _rewardAmount);
    }

    function getTaskDetails(uint256 _taskId) public view validTask(_taskId) returns (TaskDetails memory) {
        return tasks[_taskId];
    }

    function getAllTasks() public view returns (uint256[] memory taskIds) {
        taskIds = new uint256[](taskCount);
        for (uint256 i = 1; i <= taskCount; i++) {
            taskIds[i-1] = i;
        }
        return taskIds;
    }

    function getTasksBySkill(uint256 _skillId) public view returns (uint256[] memory taskIds) {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        return skillTasks[_skillId];
    }

    function assignTask(uint256 _taskId, address _assignee) public onlyRegisteredUser taskCreatorOnly(_taskId) validTask(_taskId) taskStatus(_taskId, TaskStatus.Open) {
        require(users[_assignee].isRegistered, "Assignee must be a registered user.");
        bool hasSkill = false;
        uint256 taskSkillId = tasks[_taskId].skillId;
        uint256[] storage assigneeSkills = userTasks[_assignee]; // Reusing userTasks mapping for skills
        for(uint256 i=0; i < assigneeSkills.length; i++){
            if(assigneeSkills[i] == taskSkillId){
                hasSkill = true;
                break;
            }
        }
        require(hasSkill, "Assignee does not have the required skill for this task.");

        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _assignee);
    }

    function submitTask(uint256 _taskId) public onlyRegisteredUser taskAssigneeOnly(_taskId) validTask(_taskId) taskStatus(_taskId, TaskStatus.Assigned) {
        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function verifyTaskCompletion(uint256 _taskId) public onlyRegisteredUser taskCreatorOnly(_taskId) validTask(_taskId) taskStatus(_taskId, TaskStatus.Submitted) {
        tasks[_taskId].status = TaskStatus.Verified;
        // Reward distribution and reputation increase logic here (simplified for example)
        distributeReward(tasks[_taskId].assignee, tasks[_taskId].rewardAmount);
        increaseReputation(tasks[_taskId].assignee, 50); // Example reputation increase on successful task
        emit TaskVerified(_taskId, msg.sender);
    }

    function disputeTask(uint256 _taskId, string memory _disputeReason) public onlyRegisteredUser validTask(_taskId) taskStatus(_taskId, TaskStatus.Submitted) {
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].assignee == msg.sender, "Only creator or assignee can dispute task.");
        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint256 _taskId, bool _taskCompleted) public onlyOwner validTask(_taskId) taskStatus(_taskId, TaskStatus.Disputed) {
        if (_taskCompleted) {
            tasks[_taskId].status = TaskStatus.Verified;
             // Reward distribution and reputation increase logic here (simplified for example)
            distributeReward(tasks[_taskId].assignee, tasks[_taskId].rewardAmount);
            increaseReputation(tasks[_taskId].assignee, 50); // Example reputation increase on successful task
        } else {
            tasks[_taskId].status = TaskStatus.Cancelled; // Or Re-opened for reassignment, depending on desired logic
            decreaseReputation(tasks[_taskId].assignee, 20); // Example reputation decrease for failed task
        }
        emit TaskDisputeResolved(_taskId, _taskCompleted, msg.sender);
    }

    function cancelTask(uint256 _taskId) public onlyRegisteredUser taskCreatorOnly(_taskId) validTask(_taskId) taskStatus(_taskId, TaskStatus.Open) {
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }


    // -------------------------------------------------------------------------
    // 4. Reputation & Reward System
    // -------------------------------------------------------------------------

    function increaseReputation(address _userAddress, uint256 _reputationIncrease) public onlyOwner {
        require(users[_userAddress].isRegistered, "User not registered.");
        users[_userAddress].reputationScore += _reputationIncrease;
        emit ReputationIncreased(_userAddress, _reputationIncrease, users[_userAddress].reputationScore);
    }

    function decreaseReputation(address _userAddress, uint256 _reputationDecrease) public onlyOwner {
        require(users[_userAddress].isRegistered, "User not registered.");
        // Prevent reputation from going below zero (optional, can be adjusted)
        users[_userAddress].reputationScore = users[_userAddress].reputationScore >= _reputationDecrease ? users[_userAddress].reputationScore - _reputationDecrease : 0;
        emit ReputationDecreased(_userAddress, _reputationDecrease, users[_userAddress].reputationScore);
    }

    function distributeReward(address _recipient, uint256 _amount) public onlyOwner {
        // In a real application, this would likely involve transferring tokens
        // (e.g., ERC20 tokens) from the contract to the recipient.
        // For simplicity in this example, we're just emitting an event.
        emit RewardDistributed(_recipient, _amount);
        // In a real scenario, you'd integrate with a token contract:
        // IERC20(platformTokenAddress).transfer(_recipient, _amount);
    }


    // -------------------------------------------------------------------------
    // 5. Platform Administration & Configuration
    // -------------------------------------------------------------------------

    function setPlatformFee(uint256 _newFee) public onlyOwner {
        platformFee = _newFee;
        emit PlatformFeeSet(_newFee);
    }

    function getPlatformFee() public view onlyOwner returns (uint256 platformFee) {
        return platformFee;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function withdrawPlatformBalance() public onlyOwner {
        // In a real application with fees, you would accumulate Ether or tokens in the contract.
        // This function would allow the owner to withdraw those funds.
        // For this example, it's a placeholder.
        // (Implementation would depend on how fees are collected and what currency is used)
        // Example for Ether withdrawal (if fees were collected in Ether):
        // payable(owner).transfer(address(this).balance);
    }

    // Fallback and Receive functions (optional, for receiving Ether if needed)
    receive() external payable {}
    fallback() external payable {}
}
```