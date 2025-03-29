```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Task Management System
 * @author Bard (Example Smart Contract)
 * @dev A smart contract for managing tasks and user reputation dynamically.
 *
 * Function Outline:
 * -----------------
 * 1.  initializeContract(address _admin) - Initializes the contract, sets admin.
 * 2.  setReputationThreshold(uint256 _threshold) - Sets the reputation threshold for task eligibility.
 * 3.  getUserReputation(address _user) view returns (uint256) - Retrieves a user's reputation score.
 * 4.  increaseUserReputation(address _user, uint256 _amount) - Increases a user's reputation (Admin only).
 * 5.  decreaseUserReputation(address _user, uint256 _amount) - Decreases a user's reputation (Admin only).
 * 6.  createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline, uint256 _requiredReputationLevel) - Creates a new task.
 * 7.  updateTaskDetails(uint256 _taskId, string memory _title, string memory _description, uint256 _reward, uint256 _deadline, uint256 _requiredReputationLevel) - Updates task details (Creator only).
 * 8.  cancelTask(uint256 _taskId) - Cancels a task (Creator only).
 * 9.  acceptTask(uint256 _taskId) - Allows a user to accept an open task (Reputation check).
 * 10. submitTaskSolution(uint256 _taskId, string memory _solutionUri) - Allows a user to submit a solution to an accepted task (Assignee only).
 * 11. approveTaskSolution(uint256 _taskId) - Approves a submitted task solution (Creator only).
 * 12. rejectTaskSolution(uint256 _taskId, string memory _rejectionReason) - Rejects a submitted task solution (Creator only).
 * 13. withdrawReward(uint256 _taskId) - Allows the task assignee to withdraw the reward after approval.
 * 14. reportUser(address _reportedUser, string memory _reportReason) - Allows users to report other users for malicious activity.
 * 15. reviewUserReport(uint256 _reportId, bool _isMalicious) - Admin function to review user reports and penalize malicious users.
 * 16. getTaskDetails(uint256 _taskId) view returns (Task memory) - Retrieves detailed information about a specific task.
 * 17. getOpenTasks() view returns (uint256[] memory) - Retrieves an array of IDs for open tasks.
 * 18. getTasksAssignedToUser(address _user) view returns (uint256[] memory) - Retrieves an array of IDs for tasks assigned to a user.
 * 19. getTasksCreatedByUser(address _user) view returns (uint256[] memory) - Retrieves an array of IDs for tasks created by a user.
 * 20. getTaskStatus(uint256 _taskId) view returns (TaskStatus) - Retrieves the status of a task.
 * 21. pauseContract() - Pauses the contract (Admin only).
 * 22. unpauseContract() - Unpauses the contract (Admin only).
 * 23. getContractBalance() view returns (uint256) - Returns the contract's ETH balance.
 * 24. setAdmin(address _newAdmin) - Changes the contract administrator (Admin only).
 * 25. getAdmin() view returns (address) - Retrieves the current contract administrator.
 *
 * Function Summary:
 * -----------------
 * This smart contract implements a dynamic reputation and task management system.
 * It allows users to create tasks, assign them based on reputation, submit solutions,
 * get rewarded, and build reputation within the system. It also includes a reporting
 * mechanism and admin controls for reputation management and contract pausing.
 * The system is designed to be flexible and adaptable to various decentralized
 * task-based platforms.
 */

contract DynamicReputationTaskSystem {
    // --- Structs & Enums ---

    enum TaskStatus { Open, Assigned, Submitted, Approved, Rejected, Cancelled }

    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        TaskStatus status;
        address assignee;
        string solutionUri;
        string rejectionReason;
        uint256 requiredReputationLevel;
        uint256 createdAt;
    }

    struct UserReport {
        uint256 reportId;
        address reporter;
        address reportedUser;
        string reportReason;
        bool isReviewed;
        bool isMalicious;
        uint256 reportedAt;
    }

    // --- State Variables ---

    address public admin;
    uint256 public reputationThreshold = 10; // Minimum reputation to be eligible for tasks
    mapping(address => uint256) public userReputations; // User address to reputation score
    Task[] public tasks;
    uint256 public taskCount;
    UserReport[] public userReports;
    uint256 public reportCount;
    bool public paused;

    // --- Events ---

    event ContractInitialized(address admin);
    event ReputationThresholdUpdated(uint256 newThreshold);
    event ReputationIncreased(address user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address user, uint256 amount, uint256 newReputation);
    event TaskCreated(uint256 taskId, address creator);
    event TaskDetailsUpdated(uint256 taskId);
    event TaskCancelled(uint256 taskId);
    event TaskAccepted(uint256 taskId, address assignee);
    event TaskSolutionSubmitted(uint256 taskId, address assignee);
    event TaskSolutionApproved(uint256 taskId, uint256 reward, address assignee);
    event TaskSolutionRejected(uint256 taskId, address assignee, string rejectionReason);
    event RewardWithdrawn(uint256 taskId, address assignee, uint256 amount);
    event UserReported(uint256 reportId, address reporter, address reportedUser);
    event UserReportReviewed(uint256 reportId, bool isMalicious);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address newAdmin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < tasks.length, "Task does not exist.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier onlyTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not the required status.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Functions ---

    /// @dev Initializes the contract and sets the initial admin.
    /// @param _admin The address of the initial administrator.
    function initializeContract(address _admin) public initializer {
        require(admin == address(0), "Contract already initialized."); // Prevent re-initialization
        admin = _admin;
        emit ContractInitialized(_admin);
    }

    /// @dev Sets the reputation threshold required to be eligible for tasks.
    /// @param _threshold The new reputation threshold.
    function setReputationThreshold(uint256 _threshold) public onlyAdmin notPaused {
        reputationThreshold = _threshold;
        emit ReputationThresholdUpdated(_threshold);
    }

    /// @dev Retrieves a user's reputation score.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputations[_user];
    }

    /// @dev Increases a user's reputation score. Only callable by the admin.
    /// @param _user The address of the user to increase reputation for.
    /// @param _amount The amount to increase the reputation by.
    function increaseUserReputation(address _user, uint256 _amount) public onlyAdmin notPaused {
        userReputations[_user] += _amount;
        emit ReputationIncreased(_user, _amount, userReputations[_user]);
    }

    /// @dev Decreases a user's reputation score. Only callable by the admin.
    /// @param _user The address of the user to decrease reputation for.
    /// @param _amount The amount to decrease the reputation by.
    function decreaseUserReputation(address _user, uint256 _amount) public onlyAdmin notPaused {
        require(userReputations[_user] >= _amount, "Cannot decrease reputation below zero.");
        userReputations[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, userReputations[_user]);
    }

    /// @dev Creates a new task.
    /// @param _title The title of the task.
    /// @param _description The detailed description of the task.
    /// @param _reward The reward amount for completing the task (in wei).
    /// @param _deadline The deadline for the task (Unix timestamp).
    /// @param _requiredReputationLevel The minimum reputation level required to accept this task.
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        uint256 _requiredReputationLevel
    ) public payable notPaused {
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        tasks.push(Task({
            taskId: taskCount,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.Open,
            assignee: address(0),
            solutionUri: "",
            rejectionReason: "",
            requiredReputationLevel: _requiredReputationLevel,
            createdAt: block.timestamp
        }));
        taskCount++;
        payable(address(this)).transfer(msg.value); // Accept ETH for reward
        emit TaskCreated(taskCount - 1, msg.sender);
    }

    /// @dev Updates the details of an existing task. Only callable by the task creator.
    /// @param _taskId The ID of the task to update.
    /// @param _title The new title of the task.
    /// @param _description The new description of the task.
    /// @param _reward The new reward amount for the task.
    /// @param _deadline The new deadline for the task.
    /// @param _requiredReputationLevel The new required reputation level.
    function updateTaskDetails(
        uint256 _taskId,
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        uint256 _requiredReputationLevel
    ) public onlyTaskCreator(_taskId) taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) notPaused {
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        tasks[_taskId].title = _title;
        tasks[_taskId].description = _description;
        tasks[_taskId].reward = _reward;
        tasks[_taskId].deadline = _deadline;
        tasks[_taskId].requiredReputationLevel = _requiredReputationLevel;
        emit TaskDetailsUpdated(_taskId);
    }

    /// @dev Cancels a task. Only callable by the task creator when the task is open.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) public onlyTaskCreator(_taskId) taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) notPaused {
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
        payable(tasks[_taskId].creator).transfer(tasks[_taskId].reward); // Return reward to creator
    }

    /// @dev Allows a user to accept an open task if they meet the reputation requirement.
    /// @param _taskId The ID of the task to accept.
    function acceptTask(uint256 _taskId) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) notPaused {
        require(userReputations[msg.sender] >= tasks[_taskId].requiredReputationLevel, "Insufficient reputation to accept this task.");
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignee = msg.sender;
        emit TaskAccepted(_taskId, msg.sender);
    }

    /// @dev Allows the assignee to submit a solution for an assigned task.
    /// @param _taskId The ID of the task to submit a solution for.
    /// @param _solutionUri URI pointing to the solution (e.g., IPFS hash, URL).
    function submitTaskSolution(uint256 _taskId, string memory _solutionUri) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Assigned) onlyTaskAssignee(_taskId) notPaused {
        tasks[_taskId].status = TaskStatus.Submitted;
        tasks[_taskId].solutionUri = _solutionUri;
        emit TaskSolutionSubmitted(_taskId, msg.sender);
    }

    /// @dev Allows the task creator to approve a submitted solution.
    /// @param _taskId The ID of the task to approve the solution for.
    function approveTaskSolution(uint256 _taskId) public onlyTaskCreator(_taskId) taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) notPaused {
        tasks[_taskId].status = TaskStatus.Approved;
        emit TaskSolutionApproved(_taskId, tasks[_taskId].reward, tasks[_taskId].assignee);
        increaseUserReputation(tasks[_taskId].assignee, 5); // Example: Reward reputation for successful task completion
    }

    /// @dev Allows the task creator to reject a submitted solution.
    /// @param _taskId The ID of the task to reject the solution for.
    /// @param _rejectionReason Reason for rejecting the solution.
    function rejectTaskSolution(uint256 _taskId, string memory _rejectionReason) public onlyTaskCreator(_taskId) taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) notPaused {
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;
        tasks[_taskId].assignee = address(0); // Task becomes open again? Or needs reassignment logic. For now, assignee is cleared.
        emit TaskSolutionRejected(_taskId, msg.sender, _rejectionReason);
    }

    /// @dev Allows the task assignee to withdraw their reward after the solution is approved.
    /// @param _taskId The ID of the task to withdraw the reward for.
    function withdrawReward(uint256 _taskId) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Approved) onlyTaskAssignee(_taskId) notPaused {
        uint256 rewardAmount = tasks[_taskId].reward;
        tasks[_taskId].reward = 0; // Prevent double withdrawal
        payable(tasks[_taskId].assignee).transfer(rewardAmount);
        emit RewardWithdrawn(_taskId, tasks[_taskId].assignee, rewardAmount);
    }

    /// @dev Allows users to report another user for malicious activity.
    /// @param _reportedUser The address of the user being reported.
    /// @param _reportReason The reason for reporting the user.
    function reportUser(address _reportedUser, string memory _reportReason) public notPaused {
        userReports.push(UserReport({
            reportId: reportCount,
            reporter: msg.sender,
            reportedUser: _reportedUser,
            reportReason: _reportReason,
            isReviewed: false,
            isMalicious: false,
            reportedAt: block.timestamp
        }));
        reportCount++;
        emit UserReported(reportCount - 1, msg.sender, _reportedUser);
    }

    /// @dev Admin function to review a user report and penalize the reported user if deemed malicious.
    /// @param _reportId The ID of the user report.
    /// @param _isMalicious Boolean indicating if the reported user is deemed malicious.
    function reviewUserReport(uint256 _reportId, bool _isMalicious) public onlyAdmin notPaused {
        require(_reportId < userReports.length, "Report does not exist.");
        require(!userReports[_reportId].isReviewed, "Report already reviewed.");
        userReports[_reportId].isReviewed = true;
        userReports[_reportId].isMalicious = _isMalicious;
        if (_isMalicious) {
            decreaseUserReputation(userReports[_reportId].reportedUser, 10); // Example penalty: decrease reputation
        }
        emit UserReportReviewed(_reportId, _isMalicious);
    }

    /// @dev Retrieves detailed information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @dev Retrieves an array of task IDs for all open tasks.
    /// @return Array of task IDs.
    function getOpenTasks() public view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                openTaskIds[count] = tasks[i].taskId;
                count++;
            }
        }
        // Resize the array to the actual number of open tasks
        assembly {
            mstore(openTaskIds, count) // First slot of array stores length in memory
        }
        return openTaskIds;
    }

    /// @dev Retrieves an array of task IDs for tasks assigned to a specific user.
    /// @param _user The address of the user.
    /// @return Array of task IDs.
    function getTasksAssignedToUser(address _user) public view returns (uint256[] memory) {
        uint256[] memory assignedTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].assignee == _user) {
                assignedTaskIds[count] = tasks[i].taskId;
                count++;
            }
        }
        assembly {
            mstore(assignedTaskIds, count)
        }
        return assignedTaskIds;
    }

    /// @dev Retrieves an array of task IDs for tasks created by a specific user.
    /// @param _user The address of the user.
    /// @return Array of task IDs.
    function getTasksCreatedByUser(address _user) public view returns (uint256[] memory) {
        uint256[] memory createdTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].creator == _user) {
                createdTaskIds[count] = tasks[i].taskId;
                count++;
            }
        }
        assembly {
            mstore(createdTaskIds, count)
        }
        return createdTaskIds;
    }

    /// @dev Retrieves the status of a specific task.
    /// @param _taskId The ID of the task.
    /// @return TaskStatus enum value.
    function getTaskStatus(uint256 _taskId) public view taskExists(_taskId) returns (TaskStatus) {
        return tasks[_taskId].status;
    }

    /// @dev Pauses the contract, preventing most state-changing operations. Only callable by admin.
    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Unpauses the contract, restoring normal operation. Only callable by admin.
    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    /// @dev Gets the contract's current ETH balance.
    /// @return The contract's ETH balance in wei.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Sets a new admin address. Only callable by the current admin.
    /// @param _newAdmin The address of the new administrator.
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Admin address cannot be zero address.");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /// @dev Gets the current admin address.
    /// @return The current admin address.
    function getAdmin() public view returns (address) {
        return admin;
    }

    // --- Fallback and Receive (Optional but good practice) ---

    receive() external payable {} // To accept ETH in createTask function
    fallback() external {}
}
```