```solidity
/**
 * @title Decentralized Reputation and Task Marketplace - ReputationTaskMarketplace
 * @author Bard (AI Assistant)

 * @dev This smart contract implements a decentralized reputation system integrated with a task marketplace.
 * It allows users to build reputation by completing tasks and hire others based on their reputation scores.
 * The contract incorporates advanced concepts like reputation tiers, task staking, dispute resolution,
 * skill-based task matching, and a dynamic fee structure. It aims to be a creative and trendy solution
 * for decentralized collaboration and reputation management, avoiding duplication of common open-source contracts.

 * Function Summary:

 * **Reputation Management:**
 * 1. `increaseReputation(address _user, uint256 _amount)`: Increases the reputation score of a user. (Admin/Task Verifier)
 * 2. `decreaseReputation(address _user, uint256 _amount)`: Decreases the reputation score of a user. (Admin/Dispute Resolution)
 * 3. `getReputation(address _user)`: Retrieves the reputation score of a user. (Public)
 * 4. `setReputationThresholds(uint256[] _thresholds, string[] _tierNames)`: Sets reputation thresholds for different tiers. (Owner)
 * 5. `getUserTier(address _user)`: Retrieves the reputation tier of a user based on their score. (Public)
 * 6. `getTierDetails(uint256 _tierIndex)`: Retrieves details (threshold, name) of a specific reputation tier. (Public)

 * **Task Marketplace:**
 * 7. `createTask(string _title, string _description, uint256 _reward, uint256 _deadline, string[] _requiredSkills, uint256 _minReputation)`: Creates a new task. (Public)
 * 8. `bidOnTask(uint256 _taskId, string _bidMessage)`: Allows users to bid on a task. (Public)
 * 9. `acceptTaskBid(uint256 _taskId, address _worker)`: Allows task creator to accept a bid and assign the task. (Task Creator)
 * 10. `submitTaskCompletion(uint256 _taskId, string _proofOfWork)`: Allows worker to submit proof of task completion. (Worker)
 * 11. `verifyTaskCompletion(uint256 _taskId, bool _isSuccessful)`: Allows task creator to verify task completion. (Task Creator)
 * 12. `payTaskReward(uint256 _taskId)`: Pays the reward to the worker upon successful task verification. (Internal/Triggered by verification)
 * 13. `disputeTask(uint256 _taskId, string _disputeReason)`: Allows either party to dispute a task after submission. (Public - Task Creator/Worker)
 * 14. `resolveDispute(uint256 _taskId, address _winner, string _resolutionDetails)`: Allows admin to resolve a disputed task. (Admin)
 * 15. `cancelTask(uint256 _taskId)`: Allows task creator to cancel a task before it's accepted. (Task Creator)
 * 16. `getTaskDetails(uint256 _taskId)`: Retrieves details of a specific task. (Public)
 * 17. `listAvailableTasks()`: Lists IDs of currently available tasks (not yet accepted). (Public)
 * 18. `listUserTasks(address _user)`: Lists IDs of tasks created or worked on by a user. (Public)

 * **Platform Management & Fees:**
 * 19. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for tasks. (Owner)
 * 20. `withdrawPlatformFees()`: Allows owner to withdraw accumulated platform fees. (Owner)
 * 21. `pauseContract()`: Pauses certain functionalities of the contract. (Owner)
 * 22. `unpauseContract()`: Resumes paused functionalities. (Owner)
 */
pragma solidity ^0.8.0;

contract ReputationTaskMarketplace {
    // --- State Variables ---

    address public owner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    bool public paused = false;

    mapping(address => uint256) public userReputation; // User address => reputation score
    struct ReputationTier {
        uint256 threshold;
        string name;
    }
    ReputationTier[] public reputationTiers;

    uint256 public taskCount = 0;
    struct Task {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        string[] requiredSkills;
        uint256 minReputation;
        address worker;
        enum TaskStatus { Open, Assigned, Submitted, Verified, Disputed, Cancelled }
        TaskStatus status;
        string proofOfWork;
        string bidMessage; // Last bid message for record keeping
        string disputeReason;
        string resolutionDetails;
    }
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => address[]) public taskBids; // Task ID => Array of bidder addresses

    uint256 public platformFeesCollected = 0;

    // --- Events ---
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationTierSet(uint256 threshold, string tierName, uint256 tierIndex);
    event TaskCreated(uint256 taskId, address creator);
    event TaskBidPlaced(uint256 taskId, address bidder, string message);
    event TaskAssigned(uint256 taskId, address worker);
    event TaskCompletionSubmitted(uint256 taskId, address worker);
    event TaskVerified(uint256 taskId, address worker, bool successful);
    event TaskRewardPaid(uint256 taskId, address worker, uint256 rewardAmount);
    event TaskDisputed(uint256 taskId, address disputer, string reason);
    event DisputeResolved(uint256 taskId, address winner, string resolution);
    event TaskCancelled(uint256 taskId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address owner);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < taskCount && _taskId >= 0, "Task does not exist.");
        _;
    }

    modifier taskOpen(uint256 _taskId) {
        require(tasks[_taskId].status == Task.TaskStatus.Open, "Task is not open for bidding.");
        _;
    }

    modifier taskAssigned(uint256 _taskId) {
        require(tasks[_taskId].status == Task.TaskStatus.Assigned, "Task is not assigned.");
        _;
    }

    modifier taskSubmitted(uint256 _taskId) {
        require(tasks[_taskId].status == Task.TaskStatus.Submitted, "Task is not submitted.");
        _;
    }

    modifier taskNotCancelled(uint256 _taskId) {
        require(tasks[_taskId].status != Task.TaskStatus.Cancelled, "Task is cancelled.");
        _;
    }

    modifier validWorker(uint256 _taskId, address _worker) {
        require(tasks[_taskId].worker == _worker, "Not the assigned worker for this task.");
        _;
    }

    modifier validTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Not the creator of this task.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        // Initialize default reputation tiers
        setReputationThresholds(
            [100, 500, 1000],
            ["Beginner", "Intermediate", "Expert"]
        );
    }

    // --- Reputation Management Functions ---

    /// @notice Increases the reputation score of a user. Only callable by admin or task verifiers (can be extended)
    /// @param _user The address of the user to increase reputation for.
    /// @param _amount The amount to increase the reputation by.
    function increaseReputation(address _user, uint256 _amount) external onlyOwner { // Example: onlyOwner, refine access control
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, userReputation[_user]);
    }

    /// @notice Decreases the reputation score of a user. Only callable by admin or dispute resolvers.
    /// @param _user The address of the user to decrease reputation for.
    /// @param _amount The amount to decrease the reputation by.
    function decreaseReputation(address _user, uint256 _amount) external onlyOwner { // Example: onlyOwner, refine access control
        require(userReputation[_user] >= _amount, "Reputation cannot be negative.");
        userReputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, userReputation[_user]);
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _user The address of the user to query.
    /// @return The reputation score of the user.
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Sets reputation thresholds for different tiers.
    /// @param _thresholds An array of reputation thresholds (in ascending order).
    /// @param _tierNames An array of tier names corresponding to the thresholds.
    function setReputationThresholds(uint256[] _thresholds, string[] _tierNames) external onlyOwner {
        require(_thresholds.length == _tierNames.length, "Thresholds and tier names arrays must have the same length.");
        reputationTiers = new ReputationTier[](_thresholds.length);
        for (uint256 i = 0; i < _thresholds.length; i++) {
            reputationTiers[i] = ReputationTier({threshold: _thresholds[i], name: _tierNames[i]});
            emit ReputationTierSet(_thresholds[i], _tierNames[i], i);
        }
    }

    /// @notice Retrieves the reputation tier of a user based on their reputation score.
    /// @param _user The address of the user to query.
    /// @return The name of the user's reputation tier. Returns "Unranked" if below the lowest threshold.
    function getUserTier(address _user) external view returns (string memory) {
        uint256 reputation = userReputation[_user];
        for (uint256 i = reputationTiers.length; i > 0; i--) {
            if (reputation >= reputationTiers[i-1].threshold) {
                return reputationTiers[i-1].name;
            }
        }
        return "Unranked";
    }

    /// @notice Retrieves details (threshold, name) of a specific reputation tier.
    /// @param _tierIndex The index of the tier to query.
    /// @return threshold, name - The threshold and name of the reputation tier.
    function getTierDetails(uint256 _tierIndex) external view returns (uint256 threshold, string memory name) {
        require(_tierIndex < reputationTiers.length, "Invalid tier index.");
        return (reputationTiers[_tierIndex].threshold, reputationTiers[_tierIndex].name);
    }


    // --- Task Marketplace Functions ---

    /// @notice Creates a new task.
    /// @param _title The title of the task.
    /// @param _description The description of the task.
    /// @param _reward The reward for completing the task (in wei).
    /// @param _deadline The deadline for the task (Unix timestamp).
    /// @param _requiredSkills An array of skills required for the task.
    /// @param _minReputation The minimum reputation required to bid on this task.
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        string[] memory _requiredSkills,
        uint256 _minReputation
    ) external payable notPaused {
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(msg.value >= _reward, "Sent value must be equal to or greater than the reward."); // Ensure reward is covered
        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            requiredSkills: _requiredSkills,
            minReputation: _minReputation,
            worker: address(0),
            status: Task.TaskStatus.Open,
            proofOfWork: "",
            bidMessage: "",
            disputeReason: "",
            resolutionDetails: ""
        });
        emit TaskCreated(taskCount, msg.sender);
    }

    /// @notice Allows users to bid on an open task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _bidMessage A message accompanying the bid.
    function bidOnTask(uint256 _taskId, string memory _bidMessage) external notPaused taskExists(_taskId) taskOpen(_taskId) taskNotCancelled(_taskId) {
        require(userReputation[msg.sender] >= tasks[_taskId].minReputation, "Insufficient reputation to bid on this task.");
        // Prevent duplicate bids from the same user (optional, can be removed if multiple bids are allowed)
        for (uint256 i = 0; i < taskBids[_taskId].length; i++) {
            require(taskBids[_taskId][i] != msg.sender, "You have already bid on this task.");
        }

        taskBids[_taskId].push(msg.sender);
        tasks[_taskId].bidMessage = _bidMessage; // Store the last bid message (could be improved for multiple bids)
        emit TaskBidPlaced(_taskId, msg.sender, _bidMessage);
    }

    /// @notice Allows the task creator to accept a bid and assign the task to a worker.
    /// @param _taskId The ID of the task.
    /// @param _worker The address of the worker to assign the task to.
    function acceptTaskBid(uint256 _taskId, address _worker) external notPaused taskExists(_taskId) taskOpen(_taskId) validTaskCreator(_taskId) taskNotCancelled(_taskId) {
        bool bidFound = false;
        for (uint256 i = 0; i < taskBids[_taskId].length; i++) {
            if (taskBids[_taskId][i] == _worker) {
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Worker must have placed a bid on this task.");

        tasks[_taskId].worker = _worker;
        tasks[_taskId].status = Task.TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _worker);
    }

    /// @notice Allows the worker to submit proof of task completion.
    /// @param _taskId The ID of the task.
    /// @param _proofOfWork A string containing proof of work (e.g., link to a document, code repository).
    function submitTaskCompletion(uint256 _taskId, string memory _proofOfWork) external notPaused taskExists(_taskId) taskAssigned(_taskId) validWorker(_taskId, msg.sender) taskNotCancelled(_taskId) {
        require(block.timestamp <= tasks[_taskId].deadline, "Deadline has passed.");
        tasks[_taskId].proofOfWork = _proofOfWork;
        tasks[_taskId].status = Task.TaskStatus.Submitted;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows the task creator to verify task completion.
    /// @param _taskId The ID of the task.
    /// @param _isSuccessful Boolean indicating if the task was completed successfully.
    function verifyTaskCompletion(uint256 _taskId, bool _isSuccessful) external notPaused taskExists(_taskId) taskSubmitted(_taskId) validTaskCreator(_taskId) taskNotCancelled(_taskId) {
        if (_isSuccessful) {
            tasks[_taskId].status = Task.TaskStatus.Verified;
            payTaskReward(_taskId); // Pay reward if successful
        } else {
            // Handle unsuccessful verification - potentially dispute or rework process (simplified here)
            tasks[_taskId].status = Task.TaskStatus.Disputed; // Example: Mark as disputed if not successful, needs more robust dispute handling
            tasks[_taskId].disputeReason = "Task verification failed by creator."; // Set a default dispute reason
            emit TaskDisputed(_taskId, msg.sender, "Task verification failed."); // Emit dispute event
        }
        emit TaskVerified(_taskId, tasks[_taskId].worker, _isSuccessful);
    }

    /// @notice Pays the reward to the worker upon successful task verification. (Internal function)
    /// @param _taskId The ID of the task.
    function payTaskReward(uint256 _taskId) internal taskExists(_taskId) taskVerified(_taskId) {
        uint256 rewardAmount = tasks[_taskId].reward;
        uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
        uint256 workerReward = rewardAmount - platformFee;

        (bool success, ) = tasks[_taskId].worker.call{value: workerReward}(""); // Send reward to worker
        require(success, "Payment to worker failed.");

        platformFeesCollected += platformFee; // Accumulate platform fees

        emit TaskRewardPaid(_taskId, tasks[_taskId].worker, workerReward);
    }

    /// @notice Allows either the task creator or worker to dispute a task after submission.
    /// @param _taskId The ID of the task.
    /// @param _disputeReason The reason for the dispute.
    function disputeTask(uint256 _taskId, string memory _disputeReason) external notPaused taskExists(_taskId) taskSubmitted(_taskId) taskNotCancelled(_taskId) {
        require(msg.sender == tasks[_taskId].creator || msg.sender == tasks[_taskId].worker, "Only task creator or worker can dispute.");
        tasks[_taskId].status = Task.TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    /// @notice Allows the admin to resolve a disputed task.
    /// @param _taskId The ID of the disputed task.
    /// @param _winner The address of the winner of the dispute (task creator or worker).
    /// @param _resolutionDetails Details of the dispute resolution.
    function resolveDispute(uint256 _taskId, address _winner, string memory _resolutionDetails) external onlyOwner taskExists(_taskId) taskSubmitted(_taskId) taskNotCancelled(_taskId) { // Changed to taskSubmitted for dispute resolution after submission
        require(tasks[_taskId].status == Task.TaskStatus.Disputed, "Task is not disputed.");
        tasks[_taskId].status = Task.TaskStatus.Verified; // Assuming resolution leads to verification/payment or cancellation in more complex scenarios
        tasks[_taskId].resolutionDetails = _resolutionDetails;

        if (_winner == tasks[_taskId].worker) {
            payTaskReward(_taskId); // Pay reward if worker wins dispute
        } else {
            // If task creator wins or dispute leads to cancellation, funds might need to be returned (complex logic, simplified here)
            // In a real scenario, you might have partial refunds or other dispute resolution mechanisms.
            // For simplicity, assuming funds remain with the contract if creator wins (platform fee still applies in some models).
        }
        emit DisputeResolved(_taskId, _winner, _resolutionDetails);
    }

    /// @notice Allows the task creator to cancel a task before it's accepted.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) external notPaused taskExists(_taskId) taskOpen(_taskId) validTaskCreator(_taskId) taskNotCancelled(_taskId) {
        tasks[_taskId].status = Task.TaskStatus.Cancelled;
        payable(tasks[_taskId].creator).transfer(tasks[_taskId].reward); // Return funds to task creator
        emit TaskCancelled(_taskId);
    }

    /// @notice Retrieves details of a specific task.
    /// @param _taskId The ID of the task to query.
    /// @return All task details in a struct.
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Lists IDs of currently available tasks (status Open).
    /// @return An array of task IDs that are currently open for bidding.
    function listAvailableTasks() external view returns (uint256[] memory) {
        uint256[] memory availableTaskIds = new uint256[](taskCount); // Max possible size, will resize later
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == Task.TaskStatus.Open) {
                availableTaskIds[count] = i;
                count++;
            }
        }
        // Resize to actual count
        assembly {
            mstore(availableTaskIds, count) // Update the length of the dynamic array
        }
        return availableTaskIds;
    }

    /// @notice Lists IDs of tasks created or worked on by a user.
    /// @param _user The address of the user to query.
    /// @return Two arrays: task IDs created by the user and task IDs the user is working/worked on.
    function listUserTasks(address _user) external view returns (uint256[] memory createdTasks, uint256[] memory workedTasks) {
        uint256[] memory createdTaskIds = new uint256[](taskCount);
        uint256[] memory workedTaskIds = new uint256[](taskCount);
        uint256 createdCount = 0;
        uint256 workedCount = 0;

        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].creator == _user) {
                createdTaskIds[createdCount] = i;
                createdCount++;
            }
            if (tasks[i].worker == _user) {
                workedTaskIds[workedCount] = i;
                workedCount++;
            }
        }
         // Resize to actual count
        assembly {
            mstore(createdTaskIds, createdCount)
            mstore(workedTaskIds, workedCount)
        }
        return (createdTaskIds, workedTaskIds);
    }


    // --- Platform Management & Fees ---

    /// @notice Sets the platform fee percentage for tasks. Only callable by the contract owner.
    /// @param _feePercentage The new platform fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows the owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset collected fees after withdrawal
        payable(owner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, owner);
    }

    /// @notice Pauses the contract, preventing certain actions (e.g., creating tasks, bidding).
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, resuming normal operations.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback function (optional - for receiving ETH directly, if needed for other use cases) ---
    receive() external payable {}
}
```