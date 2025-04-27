Okay, let's create a smart contract that embodies a decentralized marketplace for off-chain AI/computation tasks. This involves concepts like staking, reputation, task management, disputes, and timeouts, going beyond typical ERC-based contracts.

Here's the outline and function summary followed by the Solidity code.

---

**Decentralized AI Worker Marketplace**

**Outline:**

This smart contract acts as a decentralized platform where users ("Task Creators") can submit tasks requiring off-chain AI or computational work, and registered entities ("Workers") can claim, perform, and submit results for these tasks in exchange for rewards. The contract manages the task lifecycle, worker registration and staking, result verification, reputation scoring, and a dispute resolution mechanism, incorporating timeouts to handle unresponsive participants.

**Key Concepts:**

1.  **Workers:** Entities (identified by their address) that register and stake collateral to signal their willingness and reliability to perform tasks. They have a profile URI and reputation score.
2.  **Task Creators:** Users who submit tasks, providing a description URI, a reward amount, and setting requirements like minimum worker stake and timeouts.
3.  **Tasks:** Represent off-chain work requests, with states indicating their lifecycle (Open, Claimed, ResultSubmitted, Completed, Failed, Cancelled, Disputed, Resolved).
4.  **Staking:** Workers stake Ether (or a token) as collateral. A minimum stake might be required to claim tasks. Stake can be slashed in case of disputes.
5.  **Reputation:** A basic score for workers, influenced by successful task completions and ratings.
6.  **Disputes:** A mechanism allowing Task Creators or Workers to challenge a task result or state, requiring admin intervention to resolve.
7.  **Timeouts:** Crucial for liveness; ensure tasks don't get stuck indefinitely if a Worker or Creator becomes unresponsive. Anyone can call timeout functions after the specified time has passed.
8.  **Fees:** Small fees for task submission and dispute initiation, collected by the contract admin.

**Function Summary (27 Functions):**

*   **Worker Management:**
    1.  `registerWorker(string memory profileURI, uint256 minTaskFee)`: Registers a new worker with their profile URI and minimum fee expectation. Requires staking first.
    2.  `updateWorkerProfile(string memory profileURI)`: Allows a registered worker to update their profile URI.
    3.  `stakeWorker()`: Allows a registered worker to add more stake to their balance. `payable` function.
    4.  `withdrawWorkerStake(uint256 amount)`: Allows a worker to withdraw excess stake, provided they meet the minimum required stake and have no pending tasks.
    5.  `pauseWorker()`: Sets a worker's status to Paused, preventing them from claiming new tasks.
    6.  `unpauseWorker()`: Sets a worker's status back to Active if they are paused.
*   **Task Management:**
    7.  `submitTask(string memory taskURI, uint256 rewardAmount, uint256 requiredWorkerStake, uint256 resultSubmissionTimeout, uint256 verificationTimeout)`: Submits a new task request, requiring a fee. `payable` function.
    8.  `claimTask(uint256 taskId)`: Allows an eligible worker to claim an open task. Checks worker status and required stake.
    9.  `submitTaskResult(uint256 taskId, string memory resultURI)`: Called by the assigned worker to submit the URI of the result after performing the task.
    10. `verifyTaskResult(uint256 taskId, bool success)`: Called by the task creator to verify the submitted result. Releases payment on success, marks as failed on failure. Must be called within the verification timeout.
    11. `rateWorker(uint256 taskId, uint8 rating)`: Allows the task creator to rate the worker after successful completion (optional).
    12. `cancelTask(uint256 taskId)`: Allows the task creator to cancel an Open task, refunding the submission fee.
*   **Dispute Resolution:**
    13. `raiseDispute(uint256 taskId, string memory reasonURI)`: Allows task creator or assigned worker to raise a dispute after result submission or verification failure. Requires a dispute fee.
    14. `resolveDispute(uint256 taskId, DisputeResolution resolution)`: Admin-only function to resolve a disputed task, determining outcome and financial penalties/rewards.
*   **Timeout Handling:**
    15. `timeoutResultSubmission(uint256 taskId)`: Callable by anyone if a worker fails to submit a result within `resultSubmissionTimeout` after claiming. Marks the task as failed.
    16. `timeoutTaskVerification(uint256 taskId)`: Callable by anyone if the task creator fails to verify (or raise a dispute) within `verificationTimeout` after result submission. Automatically completes the task and pays the worker.
*   **Admin/Parameter Management:**
    17. `setAdmin(address newAdmin)`: Sets the admin address (Owner only).
    18. `setMinimumWorkerStake(uint256 amount)`: Sets the minimum stake required for all workers (Admin only).
    19. `setTaskSubmissionFee(uint256 amount)`: Sets the fee required to submit a task (Admin only).
    20. `setDisputeFee(uint256 amount)`: Sets the fee required to raise a dispute (Admin only).
    21. `setResultTimeoutDefault(uint256 duration)`: Sets a default result submission timeout for tasks (Admin only).
    22. `setVerificationTimeoutDefault(uint256 duration)`: Sets a default verification timeout for tasks (Admin only).
    23. `withdrawAdminFees(uint256 amount)`: Allows the admin to withdraw accumulated task submission and dispute fees (Admin only).
    24. `withdrawContractBalance()`: Allows the admin to withdraw *any* balance held by the contract (use with caution, Admin only).
*   **View/Helper Functions:**
    25. `getWorkerDetails(address workerAddress)`: Returns details of a specific worker.
    26. `getTaskDetails(uint256 taskId)`: Returns details of a specific task.
    27. `getAvailableTasks()`: Returns a list of task IDs that are currently in the `Open` state. (Note: Returning large arrays from view functions can be costly/impossible off-chain, this is a simplified helper).
    28. `getTasksByWorker(address workerAddress)`: Returns a list of task IDs claimed by a worker.
    29. `getTasksByCreator(address creatorAddress)`: Returns a list of task IDs created by a user.
    30. `getTaskCount()`: Returns the total number of tasks submitted.
    31. `getWorkerCount()`: Returns the total number of registered workers.
    32. `getTaskState(uint256 taskId)`: Returns the current state of a task.
    33. `getWorkerStatus(address workerAddress)`: Returns the current status of a worker.

*(Self-correction: The summary listed 27 functions, but counting the detailed list results in 33. This meets the requirement of at least 20 functions comfortably.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIWorker
 * @dev A decentralized marketplace for off-chain AI/computation tasks.
 * Users submit tasks with rewards, workers register, stake, claim tasks,
 * submit results, get rated, and participate in a dispute mechanism.
 * Incorporates timeouts for robust task flow.
 */

// Outline:
// 1. State Variables & Constants
// 2. Enums & Structs
// 3. Events
// 4. Modifiers
// 5. Constructor
// 6. Worker Management Functions (Register, Update, Stake, Withdraw, Pause, Unpause)
// 7. Task Management Functions (Submit, Claim, Submit Result, Verify Result, Rate, Cancel)
// 8. Dispute Resolution Functions (Raise, Resolve)
// 9. Timeout Handling Functions (Result Submission Timeout, Verification Timeout)
// 10. Admin/Parameter Management Functions (Set Admin, Set Fees, Set Timeouts, Withdraw Fees)
// 11. View/Helper Functions (Get Details, Lists, Counts, Status)

// Function Summary (Detailed):
// - registerWorker(string memory profileURI, uint256 minTaskFee): Register a new worker. Requires prior staking.
// - updateWorkerProfile(string memory profileURI): Update registered worker's profile URI.
// - stakeWorker(): Add stake.
// - withdrawWorkerStake(uint256 amount): Withdraw excess stake if eligible.
// - pauseWorker(): Pause worker status.
// - unpauseWorker(): Unpause worker status.
// - submitTask(string memory taskURI, uint256 rewardAmount, uint256 requiredWorkerStake, uint256 resultSubmissionTimeout, uint256 verificationTimeout): Submit a new task. Requires task fee and reward amount.
// - claimTask(uint256 taskId): Worker claims an open task.
// - submitTaskResult(uint256 taskId, string memory resultURI): Worker submits task result URI.
// - verifyTaskResult(uint256 taskId, bool success): Task creator verifies result.
// - rateWorker(uint256 taskId, uint8 rating): Task creator rates worker after completion.
// - cancelTask(uint256 taskId): Task creator cancels an open task.
// - raiseDispute(uint256 taskId, string memory reasonURI): Raise a dispute. Requires dispute fee.
// - resolveDispute(uint256 taskId, DisputeResolution resolution): Admin resolves a dispute.
// - timeoutResultSubmission(uint256 taskId): Handle worker not submitting result in time.
// - timeoutTaskVerification(uint256 taskId): Handle creator not verifying/disputing in time.
// - setAdmin(address newAdmin): Set the contract admin (Owner only).
// - setMinimumWorkerStake(uint256 amount): Set global minimum worker stake (Admin only).
// - setTaskSubmissionFee(uint256 amount): Set fee for task submission (Admin only).
// - setDisputeFee(uint256 amount): Set fee for raising a dispute (Admin only).
// - setResultTimeoutDefault(uint256 duration): Set default result submission timeout (Admin only).
// - setVerificationTimeoutDefault(uint256 duration): Set default verification timeout (Admin only).
// - withdrawAdminFees(uint256 amount): Admin withdraws accumulated fees.
// - withdrawContractBalance(): Admin withdraws any contract balance (use with caution).
// - getWorkerDetails(address workerAddress): View worker info.
// - getTaskDetails(uint256 taskId): View task info.
// - getAvailableTasks(): View list of open task IDs (simplified).
// - getTasksByWorker(address workerAddress): View list of task IDs for a worker.
// - getTasksByCreator(address creatorAddress): View list of task IDs for a creator.
// - getTaskCount(): View total task count.
// - getWorkerCount(): View total worker count.
// - getTaskState(uint256 taskId): View task state.
// - getWorkerStatus(address workerAddress): View worker status.

contract DecentralizedAIWorker {

    address public owner;
    address public admin;

    uint256 public minWorkerStake;
    uint256 public taskSubmissionFee;
    uint256 public disputeFee;
    uint256 public defaultResultSubmissionTimeout; // in seconds
    uint256 public defaultVerificationTimeout; // in seconds

    uint256 private nextTaskId;
    uint256 private registeredWorkerCount;

    // --- Enums ---

    enum WorkerStatus {
        Inactive,   // Not registered or stake too low
        Active,     // Registered and sufficient stake
        Paused      // Temporarily unavailable
    }

    enum TaskState {
        Open,               // Waiting for a worker to claim
        Claimed,            // Claimed by a worker, waiting for result
        ResultSubmitted,    // Worker submitted result, waiting for verification/dispute
        VerificationFailed, // Creator marked result as failed
        Completed,          // Result verified successfully, payment released
        Cancelled,          // Creator cancelled task
        Disputed,           // Task is under dispute
        Resolved            // Dispute has been resolved
    }

    enum DisputeResolution {
        WinCreator_SlashWorker, // Creator wins, worker stake is slashed, creator reward & fee refunded
        WinWorker_PayWorker     // Worker wins, worker is paid, creator loses fee, worker keeps stake
    }

    // --- Structs ---

    struct Worker {
        bool isRegistered;
        string profileURI; // URI to off-chain worker profile/details
        uint256 stake;
        WorkerStatus status;
        uint256 reputationScore; // Simple sum/average, e.g., sum of ratings
        uint256 totalTasksCompleted;
        uint256 minTaskFee; // Worker's minimum fee expectation (informative)
        uint256[] taskIds; // List of tasks claimed by this worker
    }

    struct Task {
        uint256 id;
        address creator;
        string taskURI; // URI to off-chain task data/description
        uint256 rewardAmount;
        uint256 requiredWorkerStake;
        address worker; // Assigned worker address (0x0 if Open/Cancelled)
        string resultURI; // URI to off-chain result data
        TaskState state;
        uint64 claimTime;
        uint64 resultSubmissionTime;
        uint64 verificationTime; // Time creator needs to verify by (claimTime + verificationTimeout) or (resultSubmissionTime + verificationTimeout)
        uint64 resultSubmissionTimeoutDuration; // Specific timeout for this task
        uint64 verificationTimeoutDuration; // Specific timeout for this task
        uint256 taskFee; // Fee paid by creator
        uint256 disputeFee; // Fee paid if dispute raised
    }

    // --- State Variables ---

    mapping(address => Worker) public workers;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint265[] override) public taskIdsByCreator; // Override needed for external view calls with arrays
    mapping(address => uint265[] override) public taskIdsByWorker; // Override needed for external view calls with arrays

    uint256 public totalAdminFees;
    uint256 public totalDisputeFees;

    // --- Events ---

    event WorkerRegistered(address indexed worker, string profileURI, uint256 initialStake);
    event WorkerProfileUpdated(address indexed worker, string newProfileURI);
    event WorkerStaked(address indexed worker, uint256 amount, uint256 totalStake);
    event WorkerStakeWithdrawn(address indexed worker, uint256 amount, uint256 totalStake);
    event WorkerPaused(address indexed worker);
    event WorkerUnpaused(address indexed worker);

    event TaskSubmitted(uint256 indexed taskId, address indexed creator, uint256 rewardAmount, string taskURI);
    event TaskClaimed(uint256 indexed taskId, address indexed worker);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed worker, string resultURI);
    event TaskVerified(uint256 indexed taskId, address indexed creator, bool success);
    event TaskCompleted(uint256 indexed taskId, address indexed worker, uint256 rewardAmount); // Explicit success
    event TaskVerificationFailed(uint256 indexed taskId, address indexed creator); // Explicit failure by creator
    event TaskCancelled(uint256 indexed taskId, address indexed creator);

    event WorkerRated(uint256 indexed taskId, address indexed worker, address indexed rater, uint8 rating);

    event DisputeRaised(uint256 indexed taskId, address indexed participant, string reasonURI);
    event DisputeResolved(uint256 indexed taskId, DisputeResolution resolution);

    event ResultSubmissionTimeout(uint256 indexed taskId);
    event VerificationTimeout(uint256 indexed taskId);

    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event ParameterSet(string indexed parameterName, uint256 value);
    event AdminFeesWithdrawn(address indexed admin, uint256 amount);
    event ContractBalanceWithdrawn(address indexed admin, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyRegisteredWorker() {
        require(workers[msg.sender].isRegistered, "Caller is not a registered worker");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Caller is not the task creator");
        _;
    }

    modifier onlyAssignedWorker(uint256 _taskId) {
        require(tasks[_taskId].worker == msg.sender, "Caller is not the assigned worker");
        _;
    }

    modifier whenTaskStateIs(uint256 _taskId, TaskState _expectedState) {
        require(tasks[_taskId].state == _expectedState, "Task is not in the expected state");
        _;
    }

    modifier whenTaskStateIsNot(uint256 _taskId, TaskState _excludedState) {
        require(tasks[_taskId].state != _excludedState, "Task is in an excluded state");
        _;
    }

    // --- Constructor ---

    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin; // Can be different from owner
        minWorkerStake = 1 ether; // Example default
        taskSubmissionFee = 0.01 ether; // Example default
        disputeFee = 0.05 ether; // Example default
        defaultResultSubmissionTimeout = 3 days; // Example default
        defaultVerificationTimeout = 1 days; // Example default
        nextTaskId = 1;
    }

    // --- Worker Management ---

    /**
     * @dev Registers a new worker. Requires the worker to have staked the minimum amount first.
     * @param profileURI URI pointing to the worker's profile details off-chain.
     * @param minTaskFee Worker's minimum expected fee per task (informative).
     */
    function registerWorker(string memory profileURI, uint256 minTaskFee) external {
        require(!workers[msg.sender].isRegistered, "Worker already registered");
        require(workers[msg.sender].stake >= minWorkerStake, "Insufficient stake to register");

        workers[msg.sender] = Worker({
            isRegistered: true,
            profileURI: profileURI,
            stake: workers[msg.sender].stake, // Keep stake already present
            status: WorkerStatus.Active,
            reputationScore: 0,
            totalTasksCompleted: 0,
            minTaskFee: minTaskFee,
            taskIds: new uint256[](0)
        });

        registeredWorkerCount++;
        emit WorkerRegistered(msg.sender, profileURI, workers[msg.sender].stake);
    }

    /**
     * @dev Allows a registered worker to update their profile URI.
     * @param profileURI New URI for the worker's profile.
     */
    function updateWorkerProfile(string memory profileURI) external onlyRegisteredWorker {
        workers[msg.sender].profileURI = profileURI;
        emit WorkerProfileUpdated(msg.sender, profileURI);
    }

    /**
     * @dev Allows a registered worker to increase their stake.
     */
    function stakeWorker() external payable onlyRegisteredWorker {
        require(msg.value > 0, "Must send Ether to stake");
        workers[msg.sender].stake += msg.value;
        // If stake crosses min stake, update status
        if (workers[msg.sender].stake >= minWorkerStake && workers[msg.sender].status == WorkerStatus.Inactive) {
             workers[msg.sender].status = WorkerStatus.Active;
        }
        emit WorkerStaked(msg.sender, msg.value, workers[msg.sender].stake);
    }

    /**
     * @dev Allows a registered worker to withdraw excess stake.
     * Cannot withdraw below min stake or while assigned to a pending task.
     * @param amount The amount of stake to withdraw.
     */
    function withdrawWorkerStake(uint256 amount) external onlyRegisteredWorker {
        Worker storage worker = workers[msg.sender];
        require(amount > 0, "Amount must be positive");
        require(worker.stake >= minWorkerStake + amount, "Cannot withdraw below minimum required stake");

        // Prevent withdrawal if the worker is currently assigned to a task that is not yet completed or cancelled
        bool assignedToPendingTask = false;
        for (uint i = 0; i < worker.taskIds.length; i++) {
            uint256 taskId = worker.taskIds[i];
            if (tasks[taskId].worker == msg.sender) { // Double check assignment
                TaskState state = tasks[taskId].state;
                 if (state != TaskState.Completed && state != TaskState.Cancelled && state != TaskState.Resolved && state != TaskState.VerificationFailed) {
                    assignedToPendingTask = true;
                    break;
                }
            }
        }
        require(!assignedToPendingTask, "Cannot withdraw stake while assigned to a pending task");

        worker.stake -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Stake withdrawal failed");

        emit WorkerStakeWithdrawn(msg.sender, amount, worker.stake);
    }

    /**
     * @dev Sets the worker's status to Paused, preventing new task claims.
     */
    function pauseWorker() external onlyRegisteredWorker {
        workers[msg.sender].status = WorkerStatus.Paused;
        emit WorkerPaused(msg.sender);
    }

    /**
     * @dev Sets the worker's status back to Active if they were Paused.
     */
    function unpauseWorker() external onlyRegisteredWorker {
         // Optionally add checks if needed, e.g., re-check stake
        if (workers[msg.sender].status == WorkerStatus.Paused) {
             workers[msg.sender].status = WorkerStatus.Active;
             emit WorkerUnpaused(msg.sender);
        }
    }

    // --- Task Management ---

    /**
     * @dev Submits a new task request. Requires payment covering the task fee and reward amount.
     * @param taskURI URI pointing to the task data/description off-chain.
     * @param rewardAmount The reward offered to the worker upon successful completion.
     * @param requiredWorkerStake Minimum stake a worker needs to claim this specific task.
     * @param resultSubmissionTimeout Duration for worker to submit result (overrides default).
     * @param verificationTimeout Duration for creator to verify result (overrides default).
     */
    function submitTask(
        string memory taskURI,
        uint256 rewardAmount,
        uint256 requiredWorkerStake,
        uint256 resultSubmissionTimeout,
        uint256 verificationTimeout
    ) external payable {
        require(msg.value >= taskSubmissionFee + rewardAmount, "Insufficient funds sent for task fee and reward");

        uint256 taskId = nextTaskId++;
        uint256 fee = taskSubmissionFee;
        uint256 reward = rewardAmount;

        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            taskURI: taskURI,
            rewardAmount: reward,
            requiredWorkerStake: requiredWorkerStake,
            worker: address(0), // No worker assigned yet
            resultURI: "",
            state: TaskState.Open,
            claimTime: 0,
            resultSubmissionTime: 0,
            verificationTime: 0,
            resultSubmissionTimeoutDuration: resultSubmissionTimeout > 0 ? uint64(resultSubmissionTimeout) : uint64(defaultResultSubmissionTimeout),
            verificationTimeoutDuration: verificationTimeout > 0 ? uint64(verificationTimeout) : uint64(defaultVerificationTimeout),
            taskFee: fee,
            disputeFee: 0 // No dispute fee yet
        });

        totalAdminFees += fee;
        taskIdsByCreator[msg.sender].push(taskId);

        emit TaskSubmitted(taskId, msg.sender, reward, taskURI);
    }

    /**
     * @dev Allows an eligible worker to claim an open task.
     * @param taskId The ID of the task to claim.
     */
    function claimTask(uint256 taskId) external onlyRegisteredWorker whenTaskStateIs(taskId, TaskState.Open) {
        Task storage task = tasks[taskId];
        Worker storage worker = workers[msg.sender];

        require(worker.status == WorkerStatus.Active, "Worker status must be Active");
        require(worker.stake >= task.requiredWorkerStake, "Worker stake is below required stake for this task");
        // Optional: Add checks to prevent worker claiming too many tasks simultaneously

        task.worker = msg.sender;
        task.state = TaskState.Claimed;
        task.claimTime = uint64(block.timestamp);
        task.verificationTime = task.claimTime + task.verificationTimeoutDuration; // Verification starts timer from claim

        worker.taskIds.push(taskId);

        emit TaskClaimed(taskId, msg.sender);
    }

    /**
     * @dev Called by the assigned worker to submit the result URI.
     * @param taskId The ID of the task.
     * @param resultURI URI pointing to the result data off-chain.
     */
    function submitTaskResult(uint256 taskId, string memory resultURI)
        external
        onlyAssignedWorker(taskId)
        whenTaskStateIs(taskId, TaskState.Claimed)
    {
        Task storage task = tasks[taskId];

        // Check for result submission timeout before allowing submission
        require(block.timestamp <= task.claimTime + task.resultSubmissionTimeoutDuration, "Result submission timeout passed");

        task.resultURI = resultURI;
        task.state = TaskState.ResultSubmitted;
        task.resultSubmissionTime = uint64(block.timestamp);
        task.verificationTime = task.resultSubmissionTime + task.verificationTimeoutDuration; // Verification timer resets from submission

        emit TaskResultSubmitted(taskId, msg.sender, resultURI);
    }

    /**
     * @dev Called by the task creator to verify the submitted result.
     * Releases payment on success, marks as failed on failure.
     * @param taskId The ID of the task.
     * @param success True if the result is successful, false otherwise.
     */
    function verifyTaskResult(uint256 taskId, bool success)
        external
        onlyTaskCreator(taskId)
        whenTaskStateIs(taskId, TaskState.ResultSubmitted)
    {
        Task storage task = tasks[taskId];
        Worker storage worker = workers[task.worker];

        // Check for verification timeout before allowing verification
        require(block.timestamp <= task.resultSubmissionTime + task.verificationTimeoutDuration, "Verification timeout passed");

        if (success) {
            task.state = TaskState.Completed;
            // Transfer reward to worker
            (bool paymentSuccess, ) = payable(task.worker).call{value: task.rewardAmount}("");
            // Handle potential failure? For simplicity, we let it revert or emit and rely on off-chain monitoring
            require(paymentSuccess, "Reward payment failed");

            // Update worker stats/reputation - simplified
            worker.totalTasksCompleted++;
            // Reputation updated later by rating function

            emit TaskVerified(taskId, msg.sender, true);
            emit TaskCompleted(taskId, task.worker, task.rewardAmount);

        } else {
            task.state = TaskState.VerificationFailed;
            // Task reward remains in the contract
            emit TaskVerified(taskId, msg.sender, false);
            emit TaskVerificationFailed(taskId, msg.sender);
        }
    }

    /**
     * @dev Allows the task creator to rate the worker after a task is completed.
     * Simple reputation scoring: adds rating points directly.
     * @param taskId The ID of the completed task.
     * @param rating The rating (e.g., 1-5).
     */
    function rateWorker(uint256 taskId, uint8 rating)
        external
        onlyTaskCreator(taskId)
    {
        Task storage task = tasks[taskId];
        require(task.state == TaskState.Completed, "Task must be in Completed state to rate");
        require(task.worker != address(0), "Task was not completed by a worker");
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        // Optional: Add a mapping to prevent multiple ratings for the same task

        workers[task.worker].reputationScore += rating; // Simplified: just sum ratings

        emit WorkerRated(taskId, task.worker, msg.sender, rating);
    }

    /**
     * @dev Allows the task creator to cancel an Open task.
     * Refunds the task submission fee.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 taskId)
        external
        onlyTaskCreator(taskId)
        whenTaskStateIs(taskId, TaskState.Open)
    {
        Task storage task = tasks[taskId];

        task.state = TaskState.Cancelled;

        // Refund task fee to creator
        (bool success, ) = payable(msg.sender).call{value: task.taskFee}("");
        require(success, "Task fee refund failed");

        // The reward amount remains in the contract until admin withdrawal or new use case
        // Can be modified to refund reward too if desired

        emit TaskCancelled(taskId, msg.sender);
    }

    // --- Dispute Resolution ---

    /**
     * @dev Allows task creator or the assigned worker to raise a dispute.
     * Requires a dispute fee.
     * @param taskId The ID of the task.
     * @param reasonURI URI pointing to the reason/evidence for the dispute off-chain.
     */
    function raiseDispute(uint256 taskId, string memory reasonURI)
        external
        payable
        whenTaskStateIsNot(taskId, TaskState.Open)
        whenTaskStateIsNot(taskId, TaskState.Completed)
        whenTaskStateIsNot(taskId, TaskState.Cancelled)
        whenTaskStateIsNot(taskId, TaskState.Resolved)
    {
        Task storage task = tasks[taskId];

        require(msg.sender == task.creator || msg.sender == task.worker, "Only task creator or assigned worker can raise a dispute");
        require(msg.value >= disputeFee, "Insufficient funds sent for dispute fee");

        task.state = TaskState.Disputed;
        task.disputeFee += disputeFee;
        totalDisputeFees += disputeFee;

        // Optional: Store reasonURI if needed
        // task.disputeReasonURI = reasonURI;

        emit DisputeRaised(taskId, msg.sender, reasonURI);
    }

    /**
     * @dev Admin function to resolve a dispute.
     * Based on the resolution, distributes funds (reward, fees) and potentially slashes worker stake.
     * @param taskId The ID of the disputed task.
     * @param resolution The outcome of the dispute (WinCreator_SlashWorker or WinWorker_PayWorker).
     */
    function resolveDispute(uint256 taskId, DisputeResolution resolution)
        external
        onlyAdmin
        whenTaskStateIs(taskId, TaskState.Disputed)
    {
        Task storage task = tasks[taskId];
        Worker storage worker = workers[task.worker];

        task.state = TaskState.Resolved;

        if (resolution == DisputeResolution.WinCreator_SlashWorker) {
            // Creator wins:
            // 1. Slash worker stake (configurable amount, for simplicity slash dispute fee amount from worker stake)
            uint256 slashAmount = task.requiredWorkerStake > 0 ? task.requiredWorkerStake : minWorkerStake; // Example slash amount
            if (worker.stake >= slashAmount) {
                worker.stake -= slashAmount;
                // The slashed stake could be burned, sent to admin, or used for protocol treasury
                // For simplicity, it stays in the contract and can be withdrawn by admin
            } else {
                 // Worker didn't have enough stake to slash the required amount
                 // Handle accordingly (e.g., slash all remaining stake)
                 slashAmount = worker.stake; // Slash whatever is left
                 worker.stake = 0;
            }

            // 2. Refund task creator's original reward amount (which was held) and task fee
            uint256 refundAmount = task.rewardAmount + task.taskFee;
             (bool success, ) = payable(task.creator).call{value: refundAmount}("");
             require(success, "Creator refund failed during dispute resolution");

            // 3. Admin keeps the dispute fee(s) (already added to totalDisputeFees)

        } else if (resolution == DisputeResolution.WinWorker_PayWorker) {
            // Worker wins:
            // 1. Pay worker the task reward
            (bool success, ) = payable(task.worker).call{value: task.rewardAmount}("");
            require(success, "Worker payment failed during dispute resolution");

            // 2. Task creator loses the task fee (already collected) and dispute fee (if they raised it)
            // 3. Admin keeps all fees (task fee + dispute fee(s))
        }
        // Note: disputeFee field in task struct just tracks fees paid for THIS dispute.
        // totalDisputeFees tracks all fees across all disputes.

        emit DisputeResolved(taskId, resolution);
    }

    // --- Timeout Handling ---

    /**
     * @dev Callable by anyone if the worker fails to submit a result within the timeout after claiming.
     * Sets task state to VerificationFailed, indicating the worker failed.
     * @param taskId The ID of the task.
     */
    function timeoutResultSubmission(uint256 taskId)
        external
        whenTaskStateIs(taskId, TaskState.Claimed)
    {
        Task storage task = tasks[taskId];
        require(block.timestamp > task.claimTime + task.resultSubmissionTimeoutDuration, "Result submission timeout has not passed yet");

        task.state = TaskState.VerificationFailed;
        // Worker stake could be automatically slashed here, but it's more flexible to leave
        // it for a dispute/admin resolution if needed, or implement a separate auto-slash mechanism.
        // For this contract, failure leaves task state as VerificationFailed, allowing manual cancellation or dispute.

        emit ResultSubmissionTimeout(taskId);
    }

    /**
     * @dev Callable by anyone if the task creator fails to verify (or raise a dispute)
     * within the timeout after result submission. Automatically completes the task and pays the worker.
     * @param taskId The ID of the task.
     */
    function timeoutTaskVerification(uint256 taskId)
        external
        whenTaskStateIs(taskId, TaskState.ResultSubmitted)
    {
        Task storage task = tasks[taskId];
        require(block.timestamp > task.resultSubmissionTime + task.verificationTimeoutDuration, "Verification timeout has not passed yet");

        // Creator failed to act, worker wins
        task.state = TaskState.Completed; // Treat as successful verification

        // Pay worker the reward
        (bool success, ) = payable(task.worker).call{value: task.rewardAmount}("");
        require(success, "Worker payment failed during verification timeout");

        // Update worker stats/reputation - simplified
        workers[task.worker].totalTasksCompleted++;
        // Reputation could be boosted slightly here too

        emit VerificationTimeout(taskId);
        emit TaskCompleted(taskId, task.worker, task.rewardAmount); // Emit completed event as if verified
    }


    // --- Admin / Parameter Management ---

    /**
     * @dev Sets the address of the contract admin.
     * The admin is responsible for dispute resolution and parameter settings.
     * Only the owner can set the admin.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminSet(oldAdmin, newAdmin);
    }

     /**
     * @dev Sets the minimum stake required for a worker to be Active and claim tasks.
     * @param amount The new minimum stake amount.
     */
    function setMinimumWorkerStake(uint256 amount) external onlyAdmin {
        minWorkerStake = amount;
        emit ParameterSet("minWorkerStake", amount);
        // Note: Workers already registered below this might need to stake more to become Active again
        // This requires off-chain logic or another on-chain function to manage status change based on new min stake
        // For simplicity here, active workers retain status, but new claims might fail if stake is now insufficient.
    }

    /**
     * @dev Sets the fee required from task creators to submit a task.
     * @param amount The new task submission fee.
     */
    function setTaskSubmissionFee(uint256 amount) external onlyAdmin {
        taskSubmissionFee = amount;
        emit ParameterSet("taskSubmissionFee", amount);
    }

    /**
     * @dev Sets the fee required to raise a dispute.
     * @param amount The new dispute fee.
     */
    function setDisputeFee(uint256 amount) external onlyAdmin {
        disputeFee = amount;
        emit ParameterSet("disputeFee", amount);
    }

    /**
     * @dev Sets the default duration for workers to submit results.
     * Applies to tasks submitted *after* this is set, unless overridden in `submitTask`.
     * @param duration The new default timeout duration in seconds.
     */
    function setResultTimeoutDefault(uint256 duration) external onlyAdmin {
        defaultResultSubmissionTimeout = duration;
        emit ParameterSet("defaultResultSubmissionTimeout", duration);
    }

     /**
     * @dev Sets the default duration for task creators to verify results.
     * Applies to tasks submitted *after* this is set, unless overridden in `submitTask`.
     * @param duration The new default timeout duration in seconds.
     */
    function setVerificationTimeoutDefault(uint256 duration) external onlyAdmin {
        defaultVerificationTimeout = duration;
        emit ParameterSet("defaultVerificationTimeout", duration);
    }

    /**
     * @dev Allows the admin to withdraw accumulated task submission and dispute fees.
     * @param amount The amount of fees to withdraw.
     */
    function withdrawAdminFees(uint256 amount) external onlyAdmin {
        require(amount > 0 && amount <= totalAdminFees + totalDisputeFees, "Invalid amount to withdraw");
        uint256 withdrawable = totalAdminFees + totalDisputeFees;
        uint256 actualAmount = amount > withdrawable ? withdrawable : amount;

        totalAdminFees = 0; // Simple fee accounting: withdraw clears the pot
        totalDisputeFees = 0;

        (bool success, ) = payable(admin).call{value: actualAmount}("");
        require(success, "Fee withdrawal failed");

        emit AdminFeesWithdrawn(admin, actualAmount);
    }

    /**
     * @dev Allows the admin to withdraw *any* balance held by the contract.
     * Use with extreme caution, this allows withdrawing funds that might be locked
     * as task rewards or worker stakes if not managed carefully off-chain.
     */
    function withdrawContractBalance() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no balance to withdraw");

        (bool success, ) = payable(admin).call{value: balance}("");
        require(success, "Contract balance withdrawal failed");

        emit ContractBalanceWithdrawn(admin, balance);
    }


    // --- View / Helper Functions ---

    /**
     * @dev Returns details of a specific worker.
     * @param workerAddress The address of the worker.
     * @return Worker struct details.
     */
    function getWorkerDetails(address workerAddress)
        external
        view
        returns (
            bool isRegistered,
            string memory profileURI,
            uint256 stake,
            WorkerStatus status,
            uint256 reputationScore,
            uint256 totalTasksCompleted,
            uint256 minTaskFee,
            uint256[] memory claimedTaskIds // Note: Returns array, gas costs for large arrays in clients
        )
    {
        Worker storage worker = workers[workerAddress];
        require(worker.isRegistered, "Worker not registered");
        return (
            worker.isRegistered,
            worker.profileURI,
            worker.stake,
            worker.status,
            worker.reputationScore,
            worker.totalTasksCompleted,
            worker.minTaskFee,
            worker.taskIds
        );
    }

    /**
     * @dev Returns details of a specific task.
     * @param taskId The ID of the task.
     * @return Task struct details.
     */
    function getTaskDetails(uint256 taskId)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory taskURI,
            uint256 rewardAmount,
            uint256 requiredWorkerStake,
            address worker,
            string memory resultURI,
            TaskState state,
            uint64 claimTime,
            uint64 resultSubmissionTime,
            uint64 verificationTime,
            uint64 resultSubmissionTimeoutDuration,
            uint64 verificationTimeoutDuration,
            uint256 taskFee,
            uint256 disputeFeePaid // Note: This is disputeFee field in task struct, not total dispute fees
        )
    {
        Task storage task = tasks[taskId];
        require(task.id != 0, "Task does not exist"); // Check if task exists based on non-zero ID

        return (
            task.id,
            task.creator,
            task.taskURI,
            task.rewardAmount,
            task.requiredWorkerStake,
            task.worker,
            task.resultURI,
            task.state,
            task.claimTime,
            task.resultSubmissionTime,
            task.verificationTime,
            task.resultSubmissionTimeoutDuration,
            task.verificationTimeoutDuration,
            task.taskFee,
            task.disputeFee // Fee paid for this specific dispute if raised
        );
    }

     /**
     * @dev Returns a list of IDs for tasks that are currently in the Open state.
     * Note: Iterating large ranges in view functions can be expensive/impossible off-chain.
     * This is a simplified implementation; a real DApp would likely use events and off-chain indexing.
     * @return An array of Open task IDs.
     */
    function getAvailableTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](nextTaskId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].state == TaskState.Open) {
                openTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTaskIds[i];
        }
        return result;
    }

    /**
     * @dev Returns the list of task IDs claimed by a specific worker.
     * @param workerAddress The address of the worker.
     * @return An array of task IDs.
     */
    function getTasksByWorker(address workerAddress) external view returns (uint256[] memory) {
        return taskIdsByWorker[workerAddress]; // Direct access to mapped array
    }

    /**
     * @dev Returns the list of task IDs created by a specific address.
     * @param creatorAddress The address of the task creator.
     * @return An array of task IDs.
     */
    function getTasksByCreator(address creatorAddress) external view returns (uint256[] memory) {
        return taskIdsByCreator[creatorAddress]; // Direct access to mapped array
    }

    /**
     * @dev Returns the total number of tasks submitted to the contract.
     * @return Total task count.
     */
    function getTaskCount() external view returns (uint256) {
        return nextTaskId - 1;
    }

    /**
     * @dev Returns the total number of registered workers.
     * @return Total registered worker count.
     */
    function getWorkerCount() external view returns (uint256) {
        return registeredWorkerCount;
    }

     /**
     * @dev Returns the current state of a specific task.
     * @param taskId The ID of the task.
     * @return The TaskState enum value.
     */
    function getTaskState(uint256 taskId) external view returns (TaskState) {
         require(tasks[taskId].id != 0, "Task does not exist");
         return tasks[taskId].state;
    }

    /**
     * @dev Returns the current status of a specific worker.
     * @param workerAddress The address of the worker.
     * @return The WorkerStatus enum value.
     */
    function getWorkerStatus(address workerAddress) external view returns (WorkerStatus) {
         require(workers[workerAddress].isRegistered, "Worker not registered");
         return workers[workerAddress].status;
    }

    /**
     * @dev Returns the current balance of the contract.
     * Admin-only view function for monitoring funds.
     * @return The contract's balance in wei.
     */
    function getContractBalance() external view onlyAdmin returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether (e.g., direct sends, although not encouraged)
    receive() external payable {}
    fallback() external payable {}
}
```