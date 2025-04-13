```solidity
/**
 * @title Decentralized Reputation and Task Management Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform that combines reputation management with task-based interactions.
 *
 * **Outline and Function Summary:**
 *
 * **I. Core Reputation System:**
 *   1. `awardReputation(address _user, uint256 _amount, string _reason)`: Allows an admin to award reputation points to a user for positive contributions.
 *   2. `revokeReputation(address _user, uint256 _amount, string _reason)`: Allows an admin to revoke reputation points from a user for negative actions.
 *   3. `getReputation(address _user)`: Returns the current reputation score of a user.
 *   4. `getUserReputationDetails(address _user)`: Returns detailed reputation history (awards and revocations) for a user.
 *   5. `getGlobalReputationStats()`: Returns global statistics related to the reputation system (e.g., total reputation awarded).
 *
 * **II. Decentralized Task Management:**
 *   6. `createTask(string _title, string _description, uint256 _reward, uint256 _deadline)`: Allows a user to create a new task with details, reward, and deadline.
 *   7. `submitBid(uint256 _taskId, uint256 _bidAmount, string _bidDetails)`: Allows users to submit bids on open tasks.
 *   8. `acceptBid(uint256 _taskId, address _bidderAddress)`: Allows the task creator to accept a bid for their task.
 *   9. `markTaskComplete(uint256 _taskId)`: Allows the task executor to mark a task as completed.
 *   10. `confirmTaskCompletion(uint256 _taskId)`: Allows the task creator to confirm the completion of a task and release the reward.
 *   11. `disputeTask(uint256 _taskId, string _disputeReason)`: Allows either task creator or executor to dispute a task if there's disagreement.
 *   12. `resolveDispute(uint256 _taskId, address _winner)`: Allows an admin/dispute resolver to resolve a disputed task and potentially award the reward.
 *   13. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel a task before it's accepted.
 *   14. `getTaskDetails(uint256 _taskId)`: Returns detailed information about a specific task.
 *   15. `getActiveTasks()`: Returns a list of currently active tasks (not yet completed or cancelled).
 *   16. `getTasksByStatus(TaskStatus _status)`: Returns a list of tasks based on their status (e.g., Open, Bidding, InProgress, Completed).
 *   17. `getTasksAssignedToUser(address _user)`: Returns a list of tasks assigned to a specific user (tasks they are executing).
 *   18. `getTasksCreatedByUser(address _user)`: Returns a list of tasks created by a specific user.
 *
 * **III. User Profile and Settings (Advanced Concept):**
 *   19. `createUserProfile(string _username, string _bio)`: Allows a user to create a profile with a username and bio (could be extended with NFTs for avatars, etc.).
 *   20. `updateUserProfile(string _bio)`: Allows a user to update their profile bio.
 *   21. `getUserProfile(address _user)`: Returns the profile information for a user.
 *
 * **IV. Governance and Admin Functions (Trendy - DAO aspects):**
 *   22. `setDisputeResolver(address _resolver)`: Allows the contract owner to set a dispute resolver address.
 *   23. `pauseContract()`: Allows the contract owner to pause core functionalities in case of emergency.
 *   24. `unpauseContract()`: Allows the contract owner to unpause the contract.
 *
 * **Advanced Concepts Implemented:**
 * - **Decentralized Reputation:**  Beyond simple voting, this contract implements a reputation system tied to actions within the platform (task completion, positive contributions).
 * - **Task Management:** Creates a decentralized marketplace for tasks, enabling collaboration and value exchange.
 * - **Dispute Resolution:** Includes a mechanism for handling disagreements in a decentralized manner.
 * - **User Profiles:** Introduces a basic user profile system, which can be expanded for richer user identities and interactions within the platform.
 * - **Governance (Basic):** Includes admin functions for dispute resolution, pausing, and unpausing, hinting at potential DAO integration for future governance.
 * - **Events for Transparency:** All important actions emit events for off-chain monitoring and indexing.
 */
pragma solidity ^0.8.0;

contract DecentralizedReputationTask {
    // --- Enums and Structs ---

    enum TaskStatus { Open, Bidding, InProgress, Completed, Disputed, Cancelled }

    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        TaskStatus status;
        address executor;
        uint256 acceptedBidAmount;
        string disputeReason;
    }

    struct Bid {
        uint256 bidId;
        uint256 taskId;
        address bidder;
        uint256 bidAmount;
        string bidDetails;
        uint256 bidTime; // Timestamp
    }

    struct ReputationRecord {
        uint256 amount;
        string reason;
        uint256 timestamp;
        bool isAward; // true for award, false for revocation
    }

    struct UserProfile {
        string username;
        string bio;
        bool exists;
    }

    // --- State Variables ---

    address public owner;
    address public disputeResolver;

    mapping(address => int256) public reputationScores; // User address => Reputation score
    mapping(address => ReputationRecord[]) public reputationHistory; // User address => Array of reputation records

    mapping(uint256 => Task) public tasks;
    uint256 public taskCounter;

    mapping(uint256 => Bid[]) public taskBids; // Task ID => Array of bids
    uint256 public bidCounter;

    mapping(address => UserProfile) public userProfiles;

    bool public paused;

    // --- Events ---

    event ReputationAwarded(address indexed user, uint256 amount, string reason);
    event ReputationRevoked(address indexed user, uint256 amount, string reason);

    event TaskCreated(uint256 taskId, address creator, string title);
    event BidSubmitted(uint256 bidId, uint256 taskId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 taskId, address creator, address bidder, uint256 acceptedBidAmount);
    event TaskMarkedComplete(uint256 taskId, address executor);
    event TaskCompletionConfirmed(uint256 taskId, address creator, address executor, uint256 reward);
    event TaskDisputed(uint256 taskId, address disputer, string reason);
    event DisputeResolved(uint256 taskId, address resolver, address winner);
    event TaskCancelled(uint256 taskId, address creator);

    event UserProfileCreated(address user, string username);
    event UserProfileUpdated(address user, string bio);

    event ContractPaused(address owner);
    event ContractUnpaused(address owner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyDisputeResolver() {
        require(msg.sender == disputeResolver, "Only dispute resolver can call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier validTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not valid for this action.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        taskCounter = 1; // Start task IDs from 1
        bidCounter = 1; // Start bid IDs from 1
        paused = false;
    }

    // --- I. Core Reputation System ---

    /// @notice Awards reputation points to a user. Only callable by the contract owner.
    /// @param _user The address of the user to award reputation to.
    /// @param _amount The amount of reputation points to award.
    /// @param _reason A brief reason for awarding reputation.
    function awardReputation(address _user, uint256 _amount, string memory _reason) public onlyOwner notPaused {
        require(_user != address(0), "Invalid user address.");
        require(_amount > 0, "Amount must be greater than zero.");

        reputationScores[_user] += int256(_amount);
        reputationHistory[_user].push(ReputationRecord({
            amount: _amount,
            reason: _reason,
            timestamp: block.timestamp,
            isAward: true
        }));

        emit ReputationAwarded(_user, _amount, _reason);
    }

    /// @notice Revokes reputation points from a user. Only callable by the contract owner.
    /// @param _user The address of the user to revoke reputation from.
    /// @param _amount The amount of reputation points to revoke.
    /// @param _reason A brief reason for revoking reputation.
    function revokeReputation(address _user, uint256 _amount, string memory _reason) public onlyOwner notPaused {
        require(_user != address(0), "Invalid user address.");
        require(_amount > 0, "Amount must be greater than zero.");

        reputationScores[_user] -= int256(_amount);
        reputationHistory[_user].push(ReputationRecord({
            amount: _amount,
            reason: _reason,
            timestamp: block.timestamp,
            isAward: false
        }));

        emit ReputationRevoked(_user, _amount, _reason);
    }

    /// @notice Gets the current reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getReputation(address _user) public view returns (int256) {
        return reputationScores[_user];
    }

    /// @notice Gets the detailed reputation history for a user.
    /// @param _user The address of the user.
    /// @return An array of reputation records for the user.
    function getUserReputationDetails(address _user) public view returns (ReputationRecord[] memory) {
        return reputationHistory[_user];
    }

    /// @notice Gets global reputation statistics (currently just total reputation awarded, could be expanded).
    /// @return The total reputation awarded.
    function getGlobalReputationStats() public view returns (uint256 totalAwards) {
        // In a real-world scenario, you might want to track more global stats.
        // For simplicity, we're just calculating total awards based on history.
        for (address user in reputationScores) {
            for (uint256 i = 0; i < reputationHistory[user].length; i++) {
                if (reputationHistory[user][i].isAward) {
                    totalAwards += reputationHistory[user][i].amount;
                }
            }
        }
        return totalAwards;
    }

    // --- II. Decentralized Task Management ---

    /// @notice Creates a new task.
    /// @param _title The title of the task.
    /// @param _description The description of the task.
    /// @param _reward The reward offered for completing the task (in native token, e.g., ETH).
    /// @param _deadline The deadline for the task (Unix timestamp).
    function createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline) public notPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        tasks[taskCounter] = Task({
            taskId: taskCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.Open,
            executor: address(0),
            acceptedBidAmount: 0,
            disputeReason: ""
        });

        emit TaskCreated(taskCounter, msg.sender, _title);
        taskCounter++;
    }

    /// @notice Submits a bid for an open task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _bidAmount The amount the bidder is bidding for (should be less than or equal to task reward).
    /// @param _bidDetails Optional details about the bid.
    function submitBid(uint256 _taskId, uint256 _bidAmount, string memory _bidDetails) public notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot bid on their own task.");
        require(_bidAmount > 0 && _bidAmount <= tasks[_taskId].reward, "Bid amount must be valid and within reward limit.");

        Bid memory newBid = Bid({
            bidId: bidCounter,
            taskId: _taskId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            bidDetails: _bidDetails,
            bidTime: block.timestamp
        });

        taskBids[_taskId].push(newBid);
        emit BidSubmitted(bidCounter, _taskId, msg.sender, _bidAmount);
        bidCounter++;
        tasks[_taskId].status = TaskStatus.Bidding; // Transition to bidding status after first bid.
    }

    /// @notice Accepts a bid for a task. Only callable by the task creator.
    /// @param _taskId The ID of the task.
    /// @param _bidderAddress The address of the bidder to accept.
    function acceptBid(uint256 _taskId, address _bidderAddress) public notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Bidding) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can accept bids.");
        bool bidFound = false;
        uint256 acceptedBidAmount = 0;
        for (uint256 i = 0; i < taskBids[_taskId].length; i++) {
            if (taskBids[_taskId][i].bidder == _bidderAddress) {
                bidFound = true;
                acceptedBidAmount = taskBids[_taskId][i].bidAmount;
                break;
            }
        }
        require(bidFound, "Bidder address not found in bids for this task.");

        tasks[_taskId].status = TaskStatus.InProgress;
        tasks[_taskId].executor = _bidderAddress;
        tasks[_taskId].acceptedBidAmount = acceptedBidAmount;

        emit BidAccepted(_taskId, msg.sender, _bidderAddress, acceptedBidAmount);
    }

    /// @notice Marks a task as complete. Only callable by the task executor.
    /// @param _taskId The ID of the task.
    function markTaskComplete(uint256 _taskId) public notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.InProgress) {
        require(tasks[_taskId].executor == msg.sender, "Only task executor can mark task as complete.");
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskMarkedComplete(_taskId, msg.sender);
    }

    /// @notice Confirms the completion of a task and releases the reward to the executor. Only callable by the task creator.
    /// @param _taskId The ID of the task.
    function confirmTaskCompletion(uint256 _taskId) public payable notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can confirm task completion.");
        require(msg.value >= tasks[_taskId].acceptedBidAmount, "Insufficient funds sent to pay the reward."); // Ensure creator pays at least the accepted bid amount

        payable(tasks[_taskId].executor).transfer(tasks[_taskId].acceptedBidAmount); // Transfer reward to executor
        tasks[_taskId].reward = tasks[_taskId].reward - tasks[_taskId].acceptedBidAmount; // Reduce remaining reward pool (optional, can be removed if reward is fixed)

        tasks[_taskId].status = TaskStatus.Open; // Reset task status to open for potential re-use or new tasks.  Or can be finalized to another status like "Finalized".

        emit TaskCompletionConfirmed(_taskId, msg.sender, tasks[_taskId].executor, tasks[_taskId].acceptedBidAmount);
    }

    /// @notice Disputes a task if there is disagreement. Callable by either task creator or executor.
    /// @param _taskId The ID of the task.
    /// @param _disputeReason The reason for the dispute.
    function disputeTask(uint256 _taskId, string memory _disputeReason) public notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.InProgress) { // Can dispute from InProgress or Completed depending on desired flow
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].executor == msg.sender, "Only creator or executor can dispute.");
        require(bytes(_disputeReason).length > 0, "Dispute reason cannot be empty.");
        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    /// @notice Resolves a disputed task. Only callable by the dispute resolver.
    /// @param _taskId The ID of the disputed task.
    /// @param _winner The address of the winner of the dispute (either creator or executor).
    function resolveDispute(uint256 _taskId, address _winner) public onlyDisputeResolver notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Disputed) {
        require(_winner == tasks[_taskId].creator || _winner == tasks[_taskId].executor, "Winner must be either creator or executor.");

        if (_winner == tasks[_taskId].executor) {
            payable(tasks[_taskId].executor).transfer(tasks[_taskId].acceptedBidAmount); // Award reward to executor if they win dispute.
            tasks[_taskId].reward = tasks[_taskId].reward - tasks[_taskId].acceptedBidAmount; // Reduce remaining reward pool (optional).
        }
        // If creator wins, reward remains with creator (or can be returned to a pool, etc., depending on design).

        tasks[_taskId].status = TaskStatus.Open; // Reset status after dispute resolution. Or finalize status.
        emit DisputeResolved(_taskId, msg.sender, _winner);
    }

    /// @notice Cancels a task. Only callable by the task creator before a bid is accepted.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) public notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) { // Can allow cancellation in Bidding status as well.
        require(tasks[_taskId].creator == msg.sender, "Only task creator can cancel task.");
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }

    /// @notice Gets detailed information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Gets a list of currently active tasks (Open, Bidding, InProgress).
    /// @return An array of task IDs for active tasks.
    function getActiveTasks() public view returns (uint256[] memory) {
        uint256[] memory activeTaskIds = new uint256[](taskCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < taskCounter; i++) {
            if (tasks[i].status == TaskStatus.Open || tasks[i].status == TaskStatus.Bidding || tasks[i].status == TaskStatus.InProgress) {
                activeTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of active tasks
        uint256[] memory resizedActiveTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedActiveTaskIds[i] = activeTaskIds[i];
        }
        return resizedActiveTaskIds;
    }

    /// @notice Gets a list of tasks by their status.
    /// @param _status The task status to filter by.
    /// @return An array of task IDs with the specified status.
    function getTasksByStatus(TaskStatus _status) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < taskCounter; i++) {
            if (tasks[i].status == _status) {
                taskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of tasks with given status
        uint256[] memory resizedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedTaskIds[i] = taskIds[i];
        }
        return resizedTaskIds;
    }

    /// @notice Gets a list of tasks assigned to a specific user (tasks they are executing).
    /// @param _user The address of the user.
    /// @return An array of task IDs assigned to the user.
    function getTasksAssignedToUser(address _user) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < taskCounter; i++) {
            if (tasks[i].executor == _user) {
                taskIds[count] = i;
                count++;
            }
        }
        // Resize array
        uint256[] memory resizedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedTaskIds[i] = taskIds[i];
        }
        return resizedTaskIds;
    }

    /// @notice Gets a list of tasks created by a specific user.
    /// @param _user The address of the user.
    /// @return An array of task IDs created by the user.
    function getTasksCreatedByUser(address _user) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < taskCounter; i++) {
            if (tasks[i].creator == _user) {
                taskIds[count] = i;
                count++;
            }
        }
        // Resize array
        uint256[] memory resizedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedTaskIds[i] = taskIds[i];
        }
        return resizedTaskIds;
    }

    // --- III. User Profile and Settings ---

    /// @notice Creates a user profile.
    /// @param _username The desired username for the profile.
    /// @param _bio A short bio for the user.
    function createUserProfile(string memory _username, string memory _bio) public notPaused {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this address.");
        require(bytes(_username).length > 0, "Username cannot be empty.");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            exists: true
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /// @notice Updates the user's profile bio.
    /// @param _bio The new bio for the user.
    function updateUserProfile(string memory _bio) public notPaused {
        require(userProfiles[msg.sender].exists, "Profile does not exist. Create profile first.");
        userProfiles[msg.sender].bio = _bio;
        emit UserProfileUpdated(msg.sender, _bio);
    }

    /// @notice Gets the profile information for a user.
    /// @param _user The address of the user.
    /// @return UserProfile struct containing profile details.
    function getUserProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    // --- IV. Governance and Admin Functions ---

    /// @notice Sets the address of the dispute resolver. Only callable by the contract owner.
    /// @param _resolver The address of the new dispute resolver.
    function setDisputeResolver(address _resolver) public onlyOwner notPaused {
        require(_resolver != address(0), "Invalid resolver address.");
        disputeResolver = _resolver;
    }

    /// @notice Pauses the contract, preventing most core functionalities. Only callable by the contract owner.
    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring core functionalities. Only callable by the contract owner.
    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Fallback and Receive (Optional - for receiving ETH for task rewards) ---

    receive() external payable {} // To allow contract to receive ETH for task rewards (if needed, depends on reward payment flow)
    fallback() external {}
}
```