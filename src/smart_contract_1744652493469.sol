```solidity
/**
 * @title Decentralized Reputation and Task Marketplace
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation system and task marketplace.
 *      Users can build reputation by completing tasks successfully. Reputation unlocks access
 *      to higher-value tasks and platform features. The marketplace allows users to create tasks,
 *      bid on tasks, and get rewarded upon successful completion.
 *
 * **Contract Outline:**
 *
 * **Data Structures:**
 *   - `User`: Stores user profile information (address, reputation, registration timestamp).
 *   - `Task`: Stores task details (ID, requester, description, reward, status, assigned worker, deadline, creation timestamp).
 *   - `Bid`: Stores bid information (task ID, bidder, bid amount, timestamp).
 *
 * **State Variables:**
 *   - `users`: Mapping of user addresses to `User` structs.
 *   - `tasks`: Mapping of task IDs to `Task` structs.
 *   - `bids`: Mapping of task IDs to arrays of `Bid` structs.
 *   - `userReputation`: Mapping of user addresses to their reputation score.
 *   - `taskCounter`: Counter for generating unique task IDs.
 *   - `reputationThresholdForTaskCreation`: Minimum reputation required to create tasks.
 *   - `reputationThresholdForBidding`: Minimum reputation required to bid on tasks.
 *   - `platformFeePercentage`: Percentage of task reward taken as platform fee.
 *   - `admin`: Address of the contract administrator.
 *   - `paused`: Boolean to pause contract functionalities.
 *
 * **Modifiers:**
 *   - `onlyAdmin`: Restricts function access to the contract administrator.
 *   - `onlyRegisteredUser`: Restricts function access to registered users.
 *   - `taskExists`: Checks if a task with the given ID exists.
 *   - `taskOpen`: Checks if a task is in 'Open' status.
 *   - `taskAssigned`: Checks if a task is in 'Assigned' status.
 *   - `taskCompleted`: Checks if a task is in 'Completed' status.
 *   - `hasSufficientReputation`: Checks if a user has sufficient reputation.
 *   - `notPaused`: Checks if the contract is not paused.
 *
 * **Functions Summary:**
 *
 * **User Management:**
 *   1. `registerUser()`: Allows a user to register on the platform.
 *   2. `getUserReputation(address _user)`: Retrieves the reputation of a user.
 *   3. `getUserProfile(address _user)`: Retrieves the profile information of a user.
 *   4. `updateUserProfile(string _newProfileData)`: Allows a registered user to update their profile data (e.g., skills, bio - stored off-chain or as IPFS hash for simplicity here).
 *
 * **Task Management:**
 *   5. `createTask(string _description, uint256 _reward, uint256 _deadline)`: Allows a registered user with sufficient reputation to create a new task.
 *   6. `viewTask(uint256 _taskId)`: Retrieves detailed information about a specific task.
 *   7. `listOpenTasks()`: Returns a list of IDs of tasks that are currently open for bidding.
 *   8. `bidOnTask(uint256 _taskId, uint256 _bidAmount)`: Allows a registered user with sufficient reputation to bid on an open task.
 *   9. `assignTask(uint256 _taskId, address _worker)`: Allows the task requester to assign a task to a bidder.
 *   10. `submitTaskCompletion(uint256 _taskId, string _completionDetails)`: Allows the assigned worker to submit their completed work.
 *   11. `acceptTaskCompletion(uint256 _taskId)`: Allows the task requester to accept the completed work and reward the worker.
 *   12. `rejectTaskCompletion(uint256 _taskId, string _rejectionReason)`: Allows the task requester to reject the completed work (initiates dispute process - simplified here).
 *   13. `cancelTask(uint256 _taskId)`: Allows the task requester to cancel an open task before it's assigned.
 *   14. `getTaskStatus(uint256 _taskId)`: Retrieves the current status of a task.
 *
 * **Reputation Management:**
 *   15. `increaseUserReputation(address _user, uint256 _reputationIncrease)`: (Admin only) Increases a user's reputation.
 *   16. `decreaseUserReputation(address _user, uint256 _reputationDecrease)`: (Admin only) Decreases a user's reputation (e.g., for misconduct).
 *   17. `setReputationThresholds(uint256 _newTaskCreationThreshold, uint256 _newBiddingThreshold)`: (Admin only) Sets the reputation thresholds for task creation and bidding.
 *
 * **Platform Management & Utility:**
 *   18. `setPlatformFee(uint256 _newFeePercentage)`: (Admin only) Sets the platform fee percentage.
 *   19. `withdrawPlatformFees()`: (Admin only) Allows the admin to withdraw accumulated platform fees.
 *   20. `pauseContract()`: (Admin only) Pauses critical contract functionalities for emergency situations.
 *   21. `unpauseContract()`: (Admin only) Resumes contract functionalities after pausing.
 */
pragma solidity ^0.8.0;

contract ReputationTaskMarketplace {
    // Data Structures
    struct User {
        address userAddress;
        uint256 reputation;
        uint256 registrationTimestamp;
        string profileData; // Store profile data (e.g., IPFS hash or off-chain link)
        bool isRegistered;
    }

    struct Task {
        uint256 taskId;
        address requester;
        string description;
        uint256 reward;
        Status status;
        address assignedWorker;
        uint256 deadline; // Unix timestamp
        uint256 creationTimestamp;
        string completionDetails;
        string rejectionReason;
    }

    struct Bid {
        uint256 taskId;
        address bidder;
        uint256 bidAmount;
        uint256 timestamp;
    }

    enum Status {
        Open,
        Assigned,
        Completed,
        Rejected,
        Cancelled
    }

    // State Variables
    mapping(address => User) public users;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Bid[]) public bids; // Task ID to list of bids
    uint256 public taskCounter;
    uint256 public reputationThresholdForTaskCreation = 10;
    uint256 public reputationThresholdForBidding = 5;
    uint256 public platformFeePercentage = 5; // 5% fee
    address public admin;
    bool public paused;
    uint256 public platformFeesCollected;

    // Events
    event UserRegistered(address userAddress);
    event ReputationIncreased(address userAddress, uint256 amount);
    event ReputationDecreased(address userAddress, uint256 amount);
    event TaskCreated(uint256 taskId, address requester, string description, uint256 reward);
    event TaskBid(uint256 taskId, address bidder, uint256 bidAmount);
    event TaskAssigned(uint256 taskId, address requester, address worker);
    event TaskCompletionSubmitted(uint256 taskId, address worker);
    event TaskCompletionAccepted(uint256 taskId, address requester, address worker, uint256 reward);
    event TaskCompletionRejected(uint256 taskId, address requester, address worker, string reason);
    event TaskCancelled(uint256 taskId, address requester);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address admin, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ReputationThresholdsUpdated(uint256 newTaskCreationThreshold, uint256 newBiddingThreshold);
    event UserProfileUpdated(address userAddress);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User must be registered to call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId == _taskId, "Task does not exist.");
        _;
    }

    modifier taskOpen(uint256 _taskId) {
        require(tasks[_taskId].status == Status.Open, "Task is not open for bidding.");
        _;
    }

    modifier taskAssigned(uint256 _taskId) {
        require(tasks[_taskId].status == Status.Assigned, "Task is not assigned.");
        _;
    }

    modifier taskCompleted(uint256 _taskId) {
        require(tasks[_taskId].status == Status.Completed, "Task is not completed.");
        _;
    }

    modifier hasSufficientReputation(uint256 _threshold) {
        require(users[msg.sender].reputation >= _threshold, "Insufficient reputation.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // Constructor
    constructor() {
        admin = msg.sender;
        taskCounter = 1; // Start task IDs from 1
        paused = false;
    }

    // --- User Management Functions ---

    /// @notice Registers a user on the platform.
    function registerUser() external notPaused {
        require(!users[msg.sender].isRegistered, "User is already registered.");
        users[msg.sender] = User({
            userAddress: msg.sender,
            reputation: 0,
            registrationTimestamp: block.timestamp,
            profileData: "", // Initialize with empty profile data
            isRegistered: true
        });
        emit UserRegistered(msg.sender);
    }

    /// @notice Retrieves the reputation of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _user) external view returns (uint256) {
        return users[_user].reputation;
    }

    /// @notice Retrieves the profile information of a user.
    /// @param _user The address of the user.
    /// @return The User struct containing user profile information.
    function getUserProfile(address _user) external view returns (User memory) {
        require(users[_user].isRegistered, "User is not registered.");
        return users[_user];
    }

    /// @notice Allows a registered user to update their profile data.
    /// @param _newProfileData The new profile data (e.g., IPFS hash or off-chain link).
    function updateUserProfile(string memory _newProfileData) external onlyRegisteredUser notPaused {
        users[msg.sender].profileData = _newProfileData;
        emit UserProfileUpdated(msg.sender);
    }

    // --- Task Management Functions ---

    /// @notice Allows a registered user with sufficient reputation to create a new task.
    /// @param _description Description of the task.
    /// @param _reward Reward offered for completing the task.
    /// @param _deadline Task deadline in Unix timestamp.
    function createTask(string memory _description, uint256 _reward, uint256 _deadline) external onlyRegisteredUser notPaused hasSufficientReputation(reputationThresholdForTaskCreation) {
        require(_reward > 0, "Reward must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        uint256 taskId = taskCounter++;
        tasks[taskId] = Task({
            taskId: taskId,
            requester: msg.sender,
            description: _description,
            reward: _reward,
            status: Status.Open,
            assignedWorker: address(0),
            deadline: _deadline,
            creationTimestamp: block.timestamp,
            completionDetails: "",
            rejectionReason: ""
        });
        emit TaskCreated(taskId, msg.sender, _description, _reward);
    }

    /// @notice Retrieves detailed information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return The Task struct containing task details.
    function viewTask(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Returns a list of IDs of tasks that are currently open for bidding.
    /// @return An array of task IDs.
    function listOpenTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](taskCounter - 1); // Max possible open tasks
        uint256 openTaskCount = 0;
        for (uint256 i = 1; i < taskCounter; i++) {
            if (tasks[i].status == Status.Open) {
                openTaskIds[openTaskCount++] = i;
            }
        }
        // Resize the array to the actual number of open tasks
        assembly {
            mstore(openTaskIds, openTaskCount) // Update array length
        }
        return openTaskIds;
    }

    /// @notice Allows a registered user with sufficient reputation to bid on an open task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _bidAmount The amount the bidder is asking for (can be same as task reward for simplicity, or lower for negotiation feature).
    function bidOnTask(uint256 _taskId, uint256 _bidAmount) external onlyRegisteredUser notPaused hasSufficientReputation(reputationThresholdForBidding) taskExists(_taskId) taskOpen(_taskId) {
        require(msg.sender != tasks[_taskId].requester, "Requester cannot bid on their own task.");
        require(_bidAmount > 0, "Bid amount must be greater than zero.");

        bids[_taskId].push(Bid({
            taskId: _taskId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            timestamp: block.timestamp
        }));
        emit TaskBid(_taskId, msg.sender, _bidAmount);
    }

    /// @notice Allows the task requester to assign a task to a bidder.
    /// @param _taskId The ID of the task to assign.
    /// @param _worker The address of the worker to assign the task to.
    function assignTask(uint256 _taskId, address _worker) external onlyRegisteredUser notPaused taskExists(_taskId) taskOpen(_taskId) {
        require(msg.sender == tasks[_taskId].requester, "Only task requester can assign the task.");
        bool bidderFound = false;
        for (uint256 i = 0; i < bids[_taskId].length; i++) {
            if (bids[_taskId][i].bidder == _worker) {
                bidderFound = true;
                break;
            }
        }
        require(bidderFound, "Worker must have placed a bid on this task.");

        tasks[_taskId].status = Status.Assigned;
        tasks[_taskId].assignedWorker = _worker;
        emit TaskAssigned(_taskId, msg.sender, _worker);
    }

    /// @notice Allows the assigned worker to submit their completed work.
    /// @param _taskId The ID of the task.
    /// @param _completionDetails Details of the completed work (e.g., IPFS hash or off-chain link).
    function submitTaskCompletion(uint256 _taskId, string memory _completionDetails) external onlyRegisteredUser notPaused taskExists(_taskId) taskAssigned(_taskId) {
        require(msg.sender == tasks[_taskId].assignedWorker, "Only assigned worker can submit completion.");
        tasks[_taskId].status = Status.Completed;
        tasks[_taskId].completionDetails = _completionDetails;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows the task requester to accept the completed work and reward the worker.
    /// @param _taskId The ID of the task.
    function acceptTaskCompletion(uint256 _taskId) external onlyRegisteredUser notPaused taskExists(_taskId) taskCompleted(_taskId) {
        require(msg.sender == tasks[_taskId].requester, "Only task requester can accept completion.");

        uint256 rewardAmount = tasks[_taskId].reward;
        uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
        uint256 workerReward = rewardAmount - platformFee;

        payable(tasks[_taskId].assignedWorker).transfer(workerReward);
        platformFeesCollected += platformFee;

        increaseUserReputation(tasks[_taskId].assignedWorker, 5); // Increase worker reputation on successful completion
        increaseUserReputation(tasks[_taskId].requester, 1);      // Slightly increase requester reputation for using platform

        tasks[_taskId].status = Status.Completed; // Keep status as completed even after acceptance for record
        emit TaskCompletionAccepted(_taskId, msg.sender, tasks[_taskId].assignedWorker, workerReward);
    }

    /// @notice Allows the task requester to reject the completed work (simplified rejection/dispute).
    /// @param _taskId The ID of the task.
    /// @param _rejectionReason Reason for rejecting the work.
    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) external onlyRegisteredUser notPaused taskExists(_taskId) taskCompleted(_taskId) {
        require(msg.sender == tasks[_taskId].requester, "Only task requester can reject completion.");

        tasks[_taskId].status = Status.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;
        decreaseUserReputation(tasks[_taskId].assignedWorker, 2); // Decrease worker reputation for rejected work (simplified penalty)
        emit TaskCompletionRejected(_taskId, msg.sender, tasks[_taskId].assignedWorker, _rejectionReason);
    }

    /// @notice Allows the task requester to cancel an open task before it's assigned.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) external onlyRegisteredUser notPaused taskExists(_taskId) taskOpen(_taskId) {
        require(msg.sender == tasks[_taskId].requester, "Only task requester can cancel the task.");
        tasks[_taskId].status = Status.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }

    /// @notice Retrieves the current status of a task.
    /// @param _taskId The ID of the task.
    /// @return The status of the task (enum Status).
    function getTaskStatus(uint256 _taskId) external view taskExists(_taskId) returns (Status) {
        return tasks[_taskId].status;
    }

    // --- Reputation Management Functions (Admin Only) ---

    /// @notice (Admin only) Increases a user's reputation.
    /// @param _user The address of the user.
    /// @param _reputationIncrease The amount to increase the reputation by.
    function increaseUserReputation(address _user, uint256 _reputationIncrease) internal { // Admin only, but made internal for contract use in acceptTaskCompletion
        require(users[_user].isRegistered, "User is not registered.");
        users[_user].reputation += _reputationIncrease;
        emit ReputationIncreased(_user, _reputationIncrease);
    }

    /// @notice (Admin only) Decreases a user's reputation.
    /// @param _user The address of the user.
    /// @param _reputationDecrease The amount to decrease the reputation by.
    function decreaseUserReputation(address _user, uint256 _reputationDecrease) internal { // Admin only, but made internal for contract use in rejectTaskCompletion
        require(users[_user].isRegistered, "User is not registered.");
        users[_user].reputation -= _reputationDecrease;
        emit ReputationDecreased(_user, _reputationDecrease);
    }

    /// @notice (Admin only) Sets the reputation thresholds for task creation and bidding.
    /// @param _newTaskCreationThreshold New reputation threshold for creating tasks.
    /// @param _newBiddingThreshold New reputation threshold for bidding on tasks.
    function setReputationThresholds(uint256 _newTaskCreationThreshold, uint256 _newBiddingThreshold) external onlyAdmin notPaused {
        reputationThresholdForTaskCreation = _newTaskCreationThreshold;
        reputationThresholdForBidding = _newBiddingThreshold;
        emit ReputationThresholdsUpdated(_newTaskCreationThreshold, _newBiddingThreshold);
    }


    // --- Platform Management & Utility Functions (Admin Only) ---

    /// @notice (Admin only) Sets the platform fee percentage.
    /// @param _newFeePercentage The new platform fee percentage.
    function setPlatformFee(uint256 _newFeePercentage) external onlyAdmin notPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /// @notice (Admin only) Allows the admin to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyAdmin notPaused {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0;
        payable(admin).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(admin, amountToWithdraw);
    }

    /// @notice (Admin only) Pauses critical contract functionalities for emergency situations.
    function pauseContract() external onlyAdmin notPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice (Admin only) Resumes contract functionalities after pausing.
    function unpauseContract() external onlyAdmin notPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    // Fallback function to receive Ether for task rewards (if reward is sent directly) - not recommended for complex reward logic.
    receive() external payable {}
}
```