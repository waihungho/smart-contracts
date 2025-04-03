```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Task Marketplace
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation system and task marketplace.
 *      This contract allows users to build reputation by completing tasks and utilize that reputation
 *      to access higher-value tasks and potentially governance within the system.
 *
 * Function Summary:
 * -----------------
 * **Core Reputation System:**
 * 1. `registerUser()`: Registers a new user in the system.
 * 2. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 3. `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation (admin/task completion).
 * 4. `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation (admin/negative feedback).
 * 5. `setReputationThreshold(uint256 _threshold)`: Sets the reputation threshold for accessing certain features.
 * 6. `getReputationThreshold()`: Retrieves the current reputation threshold.
 * 7. `isReputationSufficient(address _user)`: Checks if a user's reputation meets the threshold.
 *
 * **Decentralized Task Marketplace:**
 * 8. `createTask(string memory _title, string memory _description, uint256 _reward, uint256 _requiredReputation)`: Creates a new task with details and requirements.
 * 9. `getTaskDetails(uint256 _taskId)`: Retrieves details of a specific task.
 * 10. `applyForTask(uint256 _taskId)`: Allows a user to apply for a task.
 * 11. `approveTaskApplication(uint256 _taskId, address _applicant)`: Approves a user's application for a task (task creator only).
 * 12. `rejectTaskApplication(uint256 _taskId, address _applicant)`: Rejects a user's application for a task (task creator only).
 * 13. `startTask(uint256 _taskId)`: Allows the assigned user to start a task (after approval).
 * 14. `submitTask(uint256 _taskId, string memory _submissionDetails)`: Allows the assigned user to submit a completed task.
 * 15. `completeTask(uint256 _taskId)`: Marks a task as completed and distributes reward (task creator only, after verification).
 * 16. `cancelTask(uint256 _taskId)`: Cancels a task and refunds the reward (task creator only, before completion).
 * 17. `getAvailableTasks()`: Retrieves a list of available tasks (not yet started).
 * 18. `getMyAppliedTasks()`: Retrieves a list of tasks the caller has applied for.
 * 19. `getMyCreatedTasks()`: Retrieves a list of tasks created by the caller.
 * 20. `getMyAssignedTasks()`: Retrieves a list of tasks assigned to the caller.
 *
 * **Admin & Utility Functions:**
 * 21. `setAdmin(address _newAdmin)`: Changes the contract administrator.
 * 22. `pauseContract()`: Pauses the contract, disabling most functions (admin only).
 * 23. `unpauseContract()`: Resumes the contract (admin only).
 * 24. `isContractPaused()`: Checks if the contract is currently paused.
 */
contract DecentralizedReputationTaskMarketplace {
    // --- State Variables ---
    address public admin;
    bool public paused;
    uint256 public reputationThreshold = 100; // Default reputation threshold

    mapping(address => uint256) public userReputation;
    mapping(address => bool) public isUserRegistered;

    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;

    enum TaskStatus { Open, Applied, Assigned, InProgress, Submitted, Completed, Cancelled }
    enum ApplicationStatus { Pending, Approved, Rejected }

    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 requiredReputation;
        TaskStatus status;
        address assignedUser;
        string submissionDetails;
        mapping(address => ApplicationStatus) applications; // User address to application status
        address[] applicants; // List of applicants for easier iteration
    }

    // --- Events ---
    event UserRegistered(address user);
    event ReputationIncreased(address user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address user, uint256 amount, uint256 newReputation);
    event ReputationThresholdUpdated(uint256 newThreshold);
    event TaskCreated(uint256 taskId, address creator, string title);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationApproved(uint256 taskId, address applicant);
    event TaskApplicationRejected(uint256 taskId, address applicant);
    event TaskStarted(uint256 taskId, address assignedUser);
    event TaskSubmitted(uint256 taskId, address assignedUser);
    event TaskCompleted(uint256 taskId, uint256 reward);
    event TaskCancelled(uint256 taskId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier onlyAssignedUser(uint256 _taskId) {
        require(tasks[_taskId].assignedUser == msg.sender, "Only assigned user can call this function.");
        _;
    }

    modifier validTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Invalid task status.");
        _;
    }

    modifier reputationSufficient(address _user, uint256 _requiredReputation) {
        require(userReputation[_user] >= _requiredReputation, "Insufficient reputation.");
        _;
    }

    modifier userRegistered(address _user) {
        require(isUserRegistered[_user], "User not registered.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Reputation System Functions ---
    function registerUser() external whenNotPaused {
        require(!isUserRegistered[msg.sender], "User already registered.");
        isUserRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender);
    }

    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function increaseReputation(address _user, uint256 _amount) external onlyAdmin whenNotPaused {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, userReputation[_user]);
    }

    function decreaseReputation(address _user, uint256 _amount) external onlyAdmin whenNotPaused {
        require(userReputation[_user] >= _amount, "Reputation cannot be negative.");
        userReputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, userReputation[_user]);
    }

    function setReputationThreshold(uint256 _threshold) external onlyAdmin whenNotPaused {
        reputationThreshold = _threshold;
        emit ReputationThresholdUpdated(_threshold);
    }

    function getReputationThreshold() external view returns (uint256) {
        return reputationThreshold;
    }

    function isReputationSufficient(address _user) external view returns (bool) {
        return userReputation[_user] >= reputationThreshold;
    }

    // --- Task Marketplace Functions ---
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _requiredReputation
    ) external whenNotPaused userRegistered(msg.sender) {
        taskCounter++;
        tasks[taskCounter] = Task({
            taskId: taskCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            requiredReputation: _requiredReputation,
            status: TaskStatus.Open,
            assignedUser: address(0),
            submissionDetails: "",
            applicants: new address[](0) // Initialize empty applicants array
        });
        emit TaskCreated(taskCounter, msg.sender, _title);
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function applyForTask(uint256 _taskId) external whenNotPaused userRegistered(msg.sender) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) reputationSufficient(msg.sender, tasks[_taskId].requiredReputation) {
        require(tasks[_taskId].applications[msg.sender] != ApplicationStatus.Pending && tasks[_taskId].applications[msg.sender] != ApplicationStatus.Approved, "Already applied or approved for this task.");
        tasks[_taskId].applications[msg.sender] = ApplicationStatus.Pending;
        tasks[_taskId].applicants.push(msg.sender); // Add applicant to the list
        tasks[_taskId].status = TaskStatus.Applied; // Move to applied status after first application
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function approveTaskApplication(uint256 _taskId, address _applicant) external whenNotPaused onlyTaskCreator(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Applied) {
        require(tasks[_taskId].applications[_applicant] == ApplicationStatus.Pending, "Application is not pending.");
        tasks[_taskId].applications[_applicant] = ApplicationStatus.Approved;
        tasks[_taskId].assignedUser = _applicant;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskApplicationApproved(_taskId, _applicant);
    }

    function rejectTaskApplication(uint256 _taskId, address _applicant) external whenNotPaused onlyTaskCreator(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Applied) {
        require(tasks[_taskId].applications[_applicant] == ApplicationStatus.Pending, "Application is not pending.");
        tasks[_taskId].applications[_applicant] = ApplicationStatus.Rejected;
        // Remove applicant from applicants array (optional, for cleaner data, but gas intensive for removal in Solidity)
        emit TaskApplicationRejected(_taskId, _applicant);
    }

    function startTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Assigned) onlyAssignedUser(_taskId) {
        tasks[_taskId].status = TaskStatus.InProgress;
        emit TaskStarted(_taskId, msg.sender);
    }

    function submitTask(uint256 _taskId, string memory _submissionDetails) external whenNotPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.InProgress) onlyAssignedUser(_taskId) {
        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function completeTask(uint256 _taskId) external whenNotPaused onlyTaskCreator(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Submitted) {
        // In a real application, you'd add verification logic here based on submission details.
        // For simplicity, we just distribute the reward.
        payable(tasks[_taskId].assignedUser).transfer(tasks[_taskId].reward); // Assuming reward is in native token (ETH)
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, tasks[_taskId].reward);
        increaseReputation(tasks[_taskId].assignedUser, 50); // Example: Reward reputation for task completion
    }

    function cancelTask(uint256 _taskId) external whenNotPaused onlyTaskCreator(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        // Refund logic could be added if creator needs to deposit reward upfront.
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }

    function getAvailableTasks() external view returns (uint256[] memory) {
        uint256[] memory availableTaskIds = new uint256[](taskCounter); // Max size, will trim later
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                availableTaskIds[count] = i;
                count++;
            }
        }
        // Trim the array to actual size
        uint256[] memory trimmedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTaskIds[i] = availableTaskIds[i];
        }
        return trimmedTaskIds;
    }

    function getMyAppliedTasks() external view userRegistered(msg.sender) returns (uint256[] memory) {
        uint256[] memory appliedTaskIds = new uint256[](taskCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].applications[msg.sender] == ApplicationStatus.Pending || tasks[i].applications[msg.sender] == ApplicationStatus.Approved) {
                appliedTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory trimmedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTaskIds[i] = appliedTaskIds[i];
        }
        return trimmedTaskIds;
    }

    function getMyCreatedTasks() external view userRegistered(msg.sender) returns (uint256[] memory) {
        uint256[] memory createdTaskIds = new uint256[](taskCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].creator == msg.sender) {
                createdTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory trimmedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTaskIds[i] = createdTaskIds[i];
        }
        return trimmedTaskIds;
    }

    function getMyAssignedTasks() external view userRegistered(msg.sender) returns (uint256[] memory) {
        uint256[] memory assignedTaskIds = new uint256[](taskCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].assignedUser == msg.sender) {
                assignedTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory trimmedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTaskIds[i] = assignedTaskIds[i];
        }
        return trimmedTaskIds;
    }


    // --- Admin Functions ---
    function setAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    function isContractPaused() external view returns (bool) {
        return paused;
    }

    // --- Fallback and Receive (for receiving ETH rewards - optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```