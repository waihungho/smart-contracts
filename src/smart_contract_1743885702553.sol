```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Marketplace - "RepuTask"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized task marketplace with a built-in reputation system.
 *      Users can build reputation by completing tasks successfully, and reputation influences
 *      their access to certain types of tasks and platform features.
 *
 * **Outline and Function Summary:**
 *
 * **Reputation Management:**
 *   1. `getReputationScore(address user)`: Retrieves the reputation score of a user.
 *   2. `getReputationLevel(address user)`: Retrieves the reputation level of a user based on their score.
 *   3. `increaseReputation(address user, uint256 amount)`: Increases a user's reputation score (admin/task completer).
 *   4. `decreaseReputation(address user, uint256 amount)`: Decreases a user's reputation score (admin/reporting).
 *   5. `setReputationLevelThreshold(uint256 level, uint256 threshold)`: Sets the reputation score threshold for a specific level (admin).
 *   6. `getReputationLevelThreshold(uint256 level)`: Retrieves the reputation score threshold for a specific level.
 *   7. `reportWorker(uint256 taskId, address worker, string reason)`: Allows a task requester to report a worker for task misconduct.
 *   8. `appealReport(uint256 reportId)`: Allows a worker to appeal a report against them.
 *   9. `resolveReport(uint256 reportId, bool isUpheld)`: Admin function to resolve a worker report and adjust reputation.
 *
 * **Task Management:**
 *  10. `createTask(string memory title, string memory description, uint256 reward, string[] memory requiredSkills, uint256 reputationRequirement)`: Allows users to create a new task.
 *  11. `getTaskDetails(uint256 taskId)`: Retrieves detailed information about a specific task.
 *  12. `applyForTask(uint256 taskId)`: Allows users to apply for a task, checking reputation and skills.
 *  13. `acceptWorkerForTask(uint256 taskId, address worker)`: Task requester to accept a worker's application.
 *  14. `submitTaskCompletion(uint256 taskId, string memory submissionDetails)`: Worker submits their completed task.
 *  15. `approveTaskCompletion(uint256 taskId)`: Task requester approves a completed task and rewards the worker.
 *  16. `rejectTaskCompletion(uint256 taskId, string memory rejectionReason)`: Task requester rejects a completed task.
 *  17. `cancelTask(uint256 taskId)`: Task requester can cancel a task before completion (with potential penalty).
 *  18. `listTasksByCategory(string memory category)`: Lists tasks belonging to a specific category/skill.
 *  19. `searchTasks(string memory keywords)`: Searches tasks based on keywords in title or description.
 *  20. `getAvailableTasksForUser(address user)`: Retrieves a list of tasks available for a user based on their reputation and skills.
 *
 * **Platform Utility:**
 *  21. `setPlatformFee(uint256 feePercentage)`: Sets the platform fee percentage (admin).
 *  22. `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated fees (admin).
 *  23. `addCategory(string memory categoryName)`: Adds a new task category (admin).
 *  24. `removeCategory(string memory categoryName)`: Removes a task category (admin).
 */
contract RepuTaskMarketplace {

    // --- State Variables ---

    address public platformOwner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public nextTaskId = 1;
    uint256 public nextReportId = 1;

    mapping(address => uint256) public reputationScores;
    mapping(uint256 => uint256) public reputationLevelThresholds; // Level => Score Threshold
    uint256 public constant MAX_REPUTATION_LEVEL = 5; // Example: Levels 1-5

    struct Task {
        uint256 taskId;
        address requester;
        string title;
        string description;
        uint256 reward;
        string[] requiredSkills;
        uint256 reputationRequirement;
        TaskStatus status;
        address assignedWorker;
        string submissionDetails;
        string rejectionReason;
        uint256 creationTimestamp;
    }

    enum TaskStatus { Open, Applied, Assigned, Completed, Approved, Rejected, Cancelled }

    mapping(uint256 => Task) public tasks;
    mapping(uint256 => address[]) public taskApplications; // taskId => array of applicant addresses
    mapping(uint256 => Report) public reports;

    struct Report {
        uint256 reportId;
        uint256 taskId;
        address reporter;
        address worker;
        string reason;
        ReportStatus status;
        uint256 reportTimestamp;
    }

    enum ReportStatus { Pending, Upheld, Rejected }

    string[] public taskCategories;

    // --- Events ---

    event ReputationIncreased(address user, uint256 amount, uint256 newScore);
    event ReputationDecreased(address user, uint256 amount, uint256 newScore);
    event ReputationLevelThresholdSet(uint256 level, uint256 threshold);
    event TaskCreated(uint256 taskId, address requester, string title);
    event TaskApplicationSubmitted(uint256 taskId, address worker);
    event WorkerAcceptedForTask(uint256 taskId, address requester, address worker);
    event TaskCompletionSubmitted(uint256 taskId, address worker);
    event TaskCompletionApproved(uint256 taskId, uint256 reward, address worker);
    event TaskCompletionRejected(uint256 taskId, address worker, string reason);
    event TaskCancelled(uint256 taskId, address requester);
    event WorkerReported(uint256 reportId, uint256 taskId, address reporter, address worker, string reason);
    event ReportAppealSubmitted(uint256 reportId);
    event ReportResolved(uint256 reportId, bool isUpheld, address worker);
    event PlatformFeePercentageSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event CategoryAdded(string categoryName);
    event CategoryRemoved(string categoryName);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier taskExists(uint256 taskId) {
        require(tasks[taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier validTaskStatus(uint256 taskId, TaskStatus expectedStatus) {
        require(tasks[taskId].status == expectedStatus, "Invalid task status for this action.");
        _;
    }

    modifier requesterOnly(uint256 taskId) {
        require(tasks[taskId].requester == msg.sender, "Only task requester can call this function.");
        _;
    }

    modifier workerOnly(uint256 taskId, address worker) {
        require(tasks[taskId].assignedWorker == worker && tasks[taskId].assignedWorker == msg.sender, "Only assigned worker can call this function.");
        _;
    }

    modifier applicationNotExists(uint256 taskId, address worker) {
        bool exists = false;
        for (uint256 i = 0; i < taskApplications[taskId].length; i++) {
            if (taskApplications[taskId][i] == worker) {
                exists = true;
                break;
            }
        }
        require(!exists, "Application already exists for this worker.");
        _;
    }


    // --- Constructor ---
    constructor() {
        platformOwner = msg.sender;
        // Initialize default reputation level thresholds
        setReputationLevelThreshold(1, 100);
        setReputationLevelThreshold(2, 300);
        setReputationLevelThreshold(3, 700);
        setReputationLevelThreshold(4, 1500);
        setReputationLevelThreshold(5, 3000);
    }

    // --- Reputation Management Functions ---

    /**
     * @dev Retrieves the reputation score of a user.
     * @param user The address of the user.
     * @return The reputation score of the user.
     */
    function getReputationScore(address user) public view returns (uint256) {
        return reputationScores[user];
    }

    /**
     * @dev Retrieves the reputation level of a user based on their score.
     * @param user The address of the user.
     * @return The reputation level of the user (1 to MAX_REPUTATION_LEVEL).
     */
    function getReputationLevel(address user) public view returns (uint256) {
        uint256 score = reputationScores[user];
        for (uint256 level = MAX_REPUTATION_LEVEL; level >= 1; level--) {
            if (score >= reputationLevelThresholds[level]) {
                return level;
            }
        }
        return 0; // Level 0 if below level 1 threshold
    }

    /**
     * @dev Increases a user's reputation score. Can be called by admin or internally after task completion.
     * @param user The address of the user to increase reputation for.
     * @param amount The amount to increase the reputation score by.
     */
    function increaseReputation(address user, uint256 amount) internal { // Internal function, used after task approval
        reputationScores[user] += amount;
        emit ReputationIncreased(user, amount, reputationScores[user]);
    }

    /**
     * @dev Decreases a user's reputation score. Can be called by admin after report resolution.
     * @param user The address of the user to decrease reputation for.
     * @param amount The amount to decrease the reputation score by.
     */
    function decreaseReputation(address user, uint256 amount) internal { // Internal function, used after report upheld
        if (reputationScores[user] >= amount) {
            reputationScores[user] -= amount;
        } else {
            reputationScores[user] = 0; // Minimum reputation is 0
        }
        emit ReputationDecreased(user, amount, reputationScores[user]);
    }

    /**
     * @dev Sets the reputation score threshold for a specific level. Only callable by the platform owner.
     * @param level The reputation level (1 to MAX_REPUTATION_LEVEL).
     * @param threshold The reputation score threshold for this level.
     */
    function setReputationLevelThreshold(uint256 level, uint256 threshold) public onlyOwner {
        require(level >= 1 && level <= MAX_REPUTATION_LEVEL, "Invalid reputation level.");
        reputationLevelThresholds[level] = threshold;
        emit ReputationLevelThresholdSet(level, threshold);
    }

    /**
     * @dev Retrieves the reputation score threshold for a specific level.
     * @param level The reputation level.
     * @return The reputation score threshold for the given level.
     */
    function getReputationLevelThreshold(uint256 level) public view returns (uint256) {
        return reputationLevelThresholds[level];
    }

    /**
     * @dev Allows a task requester to report a worker for task misconduct.
     * @param taskId The ID of the task related to the report.
     * @param worker The address of the worker being reported.
     * @param reason A string describing the reason for the report.
     */
    function reportWorker(uint256 taskId, address worker, string memory reason)
        public
        taskExists(taskId)
        requesterOnly(taskId)
        validTaskStatus(taskId, TaskStatus.Assigned) // Can only report after worker is assigned
    {
        require(tasks[taskId].assignedWorker == worker, "Worker is not assigned to this task.");
        reports[nextReportId] = Report({
            reportId: nextReportId,
            taskId: taskId,
            reporter: msg.sender,
            worker: worker,
            reason: reason,
            status: ReportStatus.Pending,
            reportTimestamp: block.timestamp
        });
        emit WorkerReported(nextReportId, taskId, msg.sender, worker, reason);
        nextReportId++;
    }

    /**
     * @dev Allows a worker to appeal a report filed against them.
     * @param reportId The ID of the report to appeal.
     */
    function appealReport(uint256 reportId) public {
        require(reports[reportId].reportId != 0, "Report does not exist.");
        require(reports[reportId].worker == msg.sender, "Only the reported worker can appeal.");
        require(reports[reportId].status == ReportStatus.Pending, "Report is not pending.");
        reports[reportId].status = ReportStatus.Pending; // Status remains pending, but appeal is noted (can add appeal details if needed)
        emit ReportAppealSubmitted(reportId);
    }

    /**
     * @dev Admin function to resolve a worker report and adjust reputation.
     * @param reportId The ID of the report to resolve.
     * @param isUpheld True if the report is upheld (worker is penalized), false if rejected.
     */
    function resolveReport(uint256 reportId, bool isUpheld) public onlyOwner {
        require(reports[reportId].reportId != 0, "Report does not exist.");
        require(reports[reportId].status == ReportStatus.Pending, "Report is not pending.");

        if (isUpheld) {
            reports[reportId].status = ReportStatus.Upheld;
            decreaseReputation(reports[reportId].worker, 50); // Example penalty: 50 reputation points
        } else {
            reports[reportId].status = ReportStatus.Rejected;
        }
        emit ReportResolved(reportId, isUpheld, reports[reportId].worker);
    }


    // --- Task Management Functions ---

    /**
     * @dev Allows users to create a new task.
     * @param title The title of the task.
     * @param description A detailed description of the task.
     * @param reward The reward offered for completing the task (in wei).
     * @param requiredSkills An array of strings representing required skills for the task.
     * @param reputationRequirement Minimum reputation level required to apply for the task.
     */
    function createTask(
        string memory title,
        string memory description,
        uint256 reward,
        string[] memory requiredSkills,
        uint256 reputationRequirement
    ) public payable {
        require(reward > 0, "Reward must be greater than zero.");

        tasks[nextTaskId] = Task({
            taskId: nextTaskId,
            requester: msg.sender,
            title: title,
            description: description,
            reward: reward,
            requiredSkills: requiredSkills,
            reputationRequirement: reputationRequirement,
            status: TaskStatus.Open,
            assignedWorker: address(0),
            submissionDetails: "",
            rejectionReason: "",
            creationTimestamp: block.timestamp
        });

        payable(address(this)).transfer(msg.value); // Escrow reward amount to the contract

        emit TaskCreated(nextTaskId, msg.sender, title);
        nextTaskId++;
    }

    /**
     * @dev Retrieves detailed information about a specific task.
     * @param taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint256 taskId) public view taskExists(taskId) returns (Task memory) {
        return tasks[taskId];
    }

    /**
     * @dev Allows users to apply for a task, checking reputation and skills.
     * @param taskId The ID of the task to apply for.
     */
    function applyForTask(uint256 taskId)
        public
        taskExists(taskId)
        validTaskStatus(taskId, TaskStatus.Open)
        applicationNotExists(taskId, msg.sender)
    {
        require(getReputationLevel(msg.sender) >= tasks[taskId].reputationRequirement, "Reputation level too low for this task.");
        taskApplications[taskId].push(msg.sender);
        tasks[taskId].status = TaskStatus.Applied; // Change status to Applied when first application arrives - could be more complex logic
        emit TaskApplicationSubmitted(taskId, msg.sender);
    }

    /**
     * @dev Task requester to accept a worker's application for a task.
     * @param taskId The ID of the task.
     * @param worker The address of the worker to accept.
     */
    function acceptWorkerForTask(uint256 taskId, address worker)
        public
        taskExists(taskId)
        requesterOnly(taskId)
        validTaskStatus(taskId, TaskStatus.Applied) // Can only accept from 'Applied' status
    {
        bool isApplicant = false;
        for (uint256 i = 0; i < taskApplications[taskId].length; i++) {
            if (taskApplications[taskId][i] == worker) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Worker did not apply for this task.");

        tasks[taskId].assignedWorker = worker;
        tasks[taskId].status = TaskStatus.Assigned;
        emit WorkerAcceptedForTask(taskId, msg.sender, worker);
    }

    /**
     * @dev Worker submits their completed task.
     * @param taskId The ID of the task.
     * @param submissionDetails String containing details of the task completion.
     */
    function submitTaskCompletion(uint256 taskId, string memory submissionDetails)
        public
        taskExists(taskId)
        workerOnly(taskId, msg.sender)
        validTaskStatus(taskId, TaskStatus.Assigned)
    {
        tasks[taskId].submissionDetails = submissionDetails;
        tasks[taskId].status = TaskStatus.Completed;
        emit TaskCompletionSubmitted(taskId, msg.sender);
    }

    /**
     * @dev Task requester approves a completed task and rewards the worker.
     * @param taskId The ID of the task.
     */
    function approveTaskCompletion(uint256 taskId)
        public
        taskExists(taskId)
        requesterOnly(taskId)
        validTaskStatus(taskId, TaskStatus.Completed)
    {
        uint256 rewardAmount = tasks[taskId].reward;
        uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
        uint256 workerReward = rewardAmount - platformFee;

        payable(tasks[taskId].assignedWorker).transfer(workerReward);
        payable(platformOwner).transfer(platformFee); // Send platform fee to owner

        increaseReputation(tasks[taskId].assignedWorker, 25); // Example reputation reward for task completion
        tasks[taskId].status = TaskStatus.Approved;
        emit TaskCompletionApproved(taskId, workerReward, tasks[taskId].assignedWorker);
    }

    /**
     * @dev Task requester rejects a completed task.
     * @param taskId The ID of the task.
     * @param rejectionReason String describing the reason for rejection.
     */
    function rejectTaskCompletion(uint256 taskId, string memory rejectionReason)
        public
        taskExists(taskId)
        requesterOnly(taskId)
        validTaskStatus(taskId, TaskStatus.Completed)
    {
        tasks[taskId].status = TaskStatus.Rejected;
        tasks[taskId].rejectionReason = rejectionReason;
        // Consider reputation penalty for worker on rejection? (Optional, could be implemented)
        emit TaskCompletionRejected(taskId, tasks[taskId].assignedWorker, rejectionReason);
        // Refund reward back to requester if task is rejected? (Depends on desired logic)
        payable(tasks[taskId].requester).transfer(tasks[taskId].reward); // Refund reward
    }

    /**
     * @dev Task requester can cancel a task before completion.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 taskId)
        public
        taskExists(taskId)
        requesterOnly(taskId)
        validTaskStatus(taskId, TaskStatus.Open) // Can cancel if Open or Applied (adjust as needed)
    {
        tasks[taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(taskId, msg.sender);
        payable(tasks[taskId].requester).transfer(tasks[taskId].reward); // Refund reward
    }

    /**
     * @dev Lists tasks belonging to a specific category/skill. (Basic implementation - can be improved with indexing)
     * @param category The category/skill to search for.
     * @return An array of task IDs belonging to the category.
     */
    function listTasksByCategory(string memory category) public view returns (uint256[] memory) {
        uint256[] memory taskIdsInCategory = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].taskId != 0) { // Ensure task exists
                for (uint256 j = 0; j < tasks[i].requiredSkills.length; j++) {
                    if (keccak256(bytes(tasks[i].requiredSkills[j])) == keccak256(bytes(category))) {
                        taskIdsInCategory[count] = i;
                        count++;
                        break; // Move to next task if category found
                    }
                }
            }
        }
        // Resize the array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIdsInCategory[i];
        }
        return result;
    }

    /**
     * @dev Searches tasks based on keywords in title or description. (Basic keyword search)
     * @param keywords Space-separated keywords to search for.
     * @return An array of task IDs matching the keywords.
     */
    function searchTasks(string memory keywords) public view returns (uint256[] memory) {
        uint256[] memory matchingTaskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        string[] memory keywordList = _splitString(keywords, " ");

        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].taskId != 0) {
                bool match = false;
                for (uint256 j = 0; j < keywordList.length; j++) {
                    string memory keyword = keywordList[j];
                    if (_stringContains(tasks[i].title, keyword) || _stringContains(tasks[i].description, keyword)) {
                        match = true;
                        break;
                    }
                }
                if (match) {
                    matchingTaskIds[count] = i;
                    count++;
                }
            }
        }
        // Resize the array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingTaskIds[i];
        }
        return result;
    }

    /**
     * @dev Retrieves a list of tasks available for a user based on their reputation and skills. (Simplified)
     *      Currently just checks reputation - skill matching would require more complex user skill management.
     * @param user The address of the user.
     * @return An array of task IDs available for the user.
     */
    function getAvailableTasksForUser(address user) public view returns (uint256[] memory) {
        uint256[] memory availableTaskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        uint256 userReputationLevel = getReputationLevel(user);

        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].taskId != 0 && tasks[i].status == TaskStatus.Open) { // Only open tasks
                if (userReputationLevel >= tasks[i].reputationRequirement) {
                    availableTaskIds[count] = i;
                    count++;
                }
            }
        }
        // Resize the array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = availableTaskIds[i];
        }
        return result;
    }


    // --- Platform Utility Functions ---

    /**
     * @dev Sets the platform fee percentage. Only callable by the platform owner.
     * @param feePercentage The new platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 feePercentage) public onlyOwner {
        require(feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = feePercentage;
        emit PlatformFeePercentageSet(feePercentage);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 platformFees = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].taskId != 0 && tasks[i].status == TaskStatus.Approved) {
                platformFees += (tasks[i].reward * platformFeePercentage) / 100;
            }
        }
        uint256 withdrawableAmount = balance - (balance - platformFees); // Basic calculation - needs refinement for precise fee tracking

        require(withdrawableAmount > 0, "No platform fees to withdraw.");
        payable(platformOwner).transfer(withdrawableAmount);
        emit PlatformFeesWithdrawn(platformOwner, withdrawableAmount);
    }

    /**
     * @dev Adds a new task category. Only callable by the platform owner.
     * @param categoryName The name of the category to add.
     */
    function addCategory(string memory categoryName) public onlyOwner {
        for (uint256 i = 0; i < taskCategories.length; i++) {
            require(keccak256(bytes(taskCategories[i])) != keccak256(bytes(categoryName)), "Category already exists.");
        }
        taskCategories.push(categoryName);
        emit CategoryAdded(categoryName);
    }

    /**
     * @dev Removes a task category. Only callable by the platform owner.
     * @param categoryName The name of the category to remove.
     */
    function removeCategory(string memory categoryName) public onlyOwner {
        bool removed = false;
        for (uint256 i = 0; i < taskCategories.length; i++) {
            if (keccak256(bytes(taskCategories[i])) == keccak256(bytes(categoryName))) {
                // Remove category by replacing with the last element and popping
                taskCategories[i] = taskCategories[taskCategories.length - 1];
                taskCategories.pop();
                removed = true;
                emit CategoryRemoved(categoryName);
                break;
            }
        }
        require(removed, "Category not found.");
    }


    // --- Helper/Utility Functions (Internal) ---

    /**
     * @dev Internal helper function to split a string by a delimiter.
     * @param str The string to split.
     * @param delimiter The delimiter.
     * @return An array of strings.
     */
    function _splitString(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);
        uint256 delimiterLength = delimiterBytes.length;

        if (delimiterLength == 0 || strBytes.length == 0) {
            return new string[](0);
        }

        uint256 wordCount = 1;
        for (uint256 i = 0; i < strBytes.length - (delimiterLength - 1); i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiterLength; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                wordCount++;
                i += delimiterLength - 1;
            }
        }

        string[] memory result = new string[](wordCount);
        uint256 wordIndex = 0;
        uint256 startIndex = 0;

        for (uint256 i = 0; i < strBytes.length - (delimiterLength - 1); i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiterLength; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                result[wordIndex] = string(slice(strBytes, startIndex, i));
                wordIndex++;
                startIndex = i + delimiterLength;
                i += delimiterLength - 1;
            }
        }
        result[wordIndex] = string(slice(strBytes, startIndex, strBytes.length));
        return result;
    }

    /**
     * @dev Internal helper function to check if a string contains a substring (case-insensitive).
     * @param _string The string to search in.
     * @param _substring The substring to search for.
     * @return True if the string contains the substring, false otherwise.
     */
    function _stringContains(string memory _string, string memory _substring) internal pure returns (bool) {
        bytes memory stringBytes = bytes(_string);
        bytes memory substringBytes = bytes(_substring);
        uint256 stringLength = stringBytes.length;
        uint256 substringLength = substringBytes.length;

        if (substringLength == 0) {
            return true; // Empty substring is always contained
        }
        if (substringLength > stringLength) {
            return false; // Substring longer than string cannot be contained
        }

        for (uint256 i = 0; i <= stringLength - substringLength; i++) {
            bool match = true;
            for (uint256 j = 0; j < substringLength; j++) {
                if (stringBytes[i + j] != substringBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true;
            }
        }
        return false;
    }

    // Internal function to slice bytes (needed for string splitting)
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length <= _bytes.length - _start, "Slice bounds out of range");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    tempBytes := mload(0x40)
                    let endPtr := add(_bytes, _start)
                    mstore(0x40,add(tempBytes, add(_length, 0x20)))
                    mstore(tempBytes,_length)
                    let dataPtr := add(tempBytes, 0x20)
                    for {let i := 0} lt(i, _length) { i := add(i, 0x20) } {
                        mstore(add(dataPtr, i), mload(add(endPtr, i)))
                    }
                }
                default {
                    tempBytes := mload(0x40)
                    mstore(0x40,add(tempBytes, 0x20))
                    mstore(tempBytes, 0)
                }
        }

        return tempBytes;
    }
}
```