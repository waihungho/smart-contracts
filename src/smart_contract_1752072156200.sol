Okay, let's design a smart contract for a **Decentralized AI Compute Marketplace**. This involves requesters paying workers to perform AI/ML computation tasks off-chain, with the smart contract managing the escrow, task parameters, result submission, and basic reputation/collateral staking.

This is a complex concept to implement fully on-chain (especially validation of AI results), so this contract will focus on the *marketplace and escrow logic*. Off-chain components would be needed for data storage, computation, and advanced result verification.

It incorporates concepts like:
*   **Escrow:** Holding funds until tasks are completed and verified.
*   **Staking:** Workers stake collateral to participate, subject to potential slashing (simplified here).
*   **Task Management:** Defining, assigning, submitting, and reviewing compute tasks.
*   **Reputation (Basic):** Tracking successful task completions for workers.
*   **Parameterization:** Using off-chain pointers (like IPFS hashes or URLs) for data and code.

This contract aims for novelty by combining these elements specifically for AI compute tasks, differentiating it from generic marketplaces or simple escrow services.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIComputeMarketplace
 * @author Your Name/Alias
 * @dev A decentralized marketplace for AI/ML compute tasks.
 * Requesters submit tasks with payment, Workers stake collateral to pick up tasks,
 * execute them off-chain, and submit results. The contract manages escrow and state transitions.
 * Advanced features like robust result verification and complex slashing require off-chain systems.
 */
contract DecentralizedAIComputeMarketplace {

    // --- Outline and Function Summary ---
    // State Variables: Store contract data like workers, tasks, settings.
    // Enums: Define possible states for tasks.
    // Structs: Define data structures for workers and tasks.
    // Events: Announce key actions for off-chain monitoring.
    // Modifiers: Restrict function access (owner, paused state).

    // Admin Functions:
    // 1. constructor: Initializes contract owner and basic settings.
    // 2. pause(): Pauses the contract in case of emergency.
    // 3. unpause(): Unpauses the contract.
    // 4. setMinWorkerStake(): Sets the minimum required stake for workers.
    // 5. setTaskFeePercentage(): Sets the fee percentage taken from task payments.
    // 6. withdrawAdminFees(): Allows owner to withdraw accumulated fees.
    // 7. transferOwnership(): Transfers ownership to a new address.

    // Worker Management Functions:
    // 8. registerWorker(): Registers a new worker with their capabilities.
    // 9. stakeWorker(): Allows a worker to stake ETH collateral.
    // 10. unstakeWorker(): Allows a worker to unstake available ETH collateral.
    // 11. updateWorkerCapabilities(): Updates the capabilities of a registered worker.
    // 12. getWorkerInfo(): Retrieves information about a specific worker. (View)
    // 13. getWorkerCount(): Gets the total number of registered workers. (View)
    // 14. withdrawWorkerFunds(): Allows workers to withdraw earned task payments and unstaked collateral.

    // Task Management (Requester Side) Functions:
    // 15. createTask(): Creates a new AI compute task with parameters and payment. (Payable)
    // 16. getTaskDetails(): Retrieves detailed information about a specific task. (View)
    // 17. cancelTask(): Allows the requester to cancel an open task.
    // 18. acceptTaskResult(): Allows the requester to accept a submitted result. Triggers payment.
    // 19. rejectTaskResult(): Allows the requester to reject a submitted result. (Simplified slashing logic)

    // Task Management (Worker Side) Functions:
    // 20. findAvailableTasks(): Retrieves IDs of tasks currently open and matching worker capabilities. (View)
    // 21. assignTaskToSelf(): Allows a worker to claim an open task. Locks collateral.
    // 22. submitTaskResult(): Allows the assigned worker to submit the task result.

    // Internal Helper Functions (Not callable externally, assist main logic):
    // _payoutWorker(): Handles payment and stake release upon task acceptance.
    // _slashWorker(): Handles slashing of worker stake (simplified).

    // --- State Variables ---
    address private _owner;
    bool private _paused;

    uint256 public minWorkerStake; // Minimum ETH required for a worker to stake
    uint256 public taskFeePercentage; // Percentage of task payment taken as fee (e.g., 5 for 5%)
    uint256 public totalAdminFees; // Accumulated fees

    uint256 private _nextTaskId = 1;
    mapping(uint256 => TaskInfo) public tasks;
    mapping(address => WorkerInfo) public workers;

    // Maps Worker address to their available and locked staked balance
    mapping(address => uint256) private workerTotalStake; // Total ETH staked by worker
    mapping(address => uint256) private workerLockedStake; // ETH locked for assigned tasks

    // Stores balances earned from completed tasks waiting for withdrawal
    mapping(address => uint256) private workerEarnedBalance;

    // --- Enums ---
    enum TaskState { Open, Assigned, InProgress, AwaitingReview, Accepted, Rejected, Cancelled }

    // --- Structs ---
    struct WorkerInfo {
        address workerAddress;
        bool isRegistered;
        string[] capabilities; // e.g., ["GPU", "TensorFlow", "DataSize_Large"]
        uint256 reputationScore; // Basic metric: number of successfully completed tasks
        uint256 activeTasksCount; // Number of tasks currently assigned to this worker
    }

    struct TaskInfo {
        uint256 taskId;
        address requester;
        address worker; // Assigned worker address (0x0 if not assigned)
        TaskState state;
        uint256 paymentAmount; // Amount paid by requester for the task
        uint256 collateralRequired; // Amount of worker stake to lock for this task
        uint256 submissionDeadline; // Timestamp by which the result must be submitted
        string inputDataPointer; // e.g., IPFS hash or URL for input data/code
        string outputDataPointer; // e.g., IPFS hash or URL for output data
        string requiredCapabilitiesHash; // Hash of required capabilities string[] for easy matching
        uint256 creationTime;
        uint256 assignmentTime;
        uint256 completionTime; // Time result was submitted/accepted/rejected
        string rejectionReason; // Reason if task was rejected
    }

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event WorkerRegistered(address indexed workerAddress, string[] capabilities);
    event WorkerStaked(address indexed workerAddress, uint256 amount, uint256 totalStake);
    event WorkerUnstaked(address indexed workerAddress, uint256 amount, uint256 totalStake);
    event WorkerCapabilitiesUpdated(address indexed workerAddress, string[] capabilities);
    event WorkerFundsWithdrawn(address indexed workerAddress, uint256 amount);

    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 paymentAmount, uint256 collateralRequired, string inputDataPointer);
    event TaskAssigned(uint256 indexed taskId, address indexed worker);
    event ResultSubmitted(uint256 indexed taskId, address indexed worker, string outputDataPointer);
    event TaskAccepted(uint256 indexed taskId, address indexed requester, address indexed worker, uint256 paymentAmount);
    event TaskRejected(uint256 indexed taskId, address indexed requester, address indexed worker, string rejectionReason);
    event TaskCancelled(uint256 indexed taskId, address indexed requester);

    event AdminFeesWithdrawn(address indexed owner, uint256 amount);
    event WorkerSlashing(address indexed workerAddress, uint256 amount, uint256 taskId, string reason);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _minWorkerStake, uint256 _taskFeePercentage) {
        require(_taskFeePercentage <= 100, "Fee percentage cannot exceed 100");
        _owner = msg.sender;
        minWorkerStake = _minWorkerStake;
        taskFeePercentage = _taskFeePercentage;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- Admin Functions ---

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the minimum required stake for a worker. Only owner can call.
     * @param _minStake The new minimum stake amount in wei.
     */
    function setMinWorkerStake(uint256 _minStake) external onlyOwner {
        minWorkerStake = _minStake;
    }

    /**
     * @dev Sets the percentage of task payment taken as a fee. Only owner can call.
     * @param _feePercentage The new fee percentage (e.g., 5 for 5%).
     */
    function setTaskFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        taskFeePercentage = _feePercentage;
    }

    /**
     * @dev Allows the owner to withdraw accumulated fees.
     */
    function withdrawAdminFees() external onlyOwner {
        uint256 feeAmount = totalAdminFees;
        require(feeAmount > 0, "No fees accumulated");
        totalAdminFees = 0;
        // Use transfer for security, consider call/send with re-entrancy guard for larger amounts
        (bool success, ) = payable(msg.sender).call{value: feeAmount}("");
        require(success, "Fee withdrawal failed");
        emit AdminFeesWithdrawn(msg.sender, feeAmount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    // --- Worker Management Functions ---

    /**
     * @dev Registers a new address as a worker with specified capabilities.
     * A worker must be registered before staking or taking tasks.
     * @param capabilities The list of AI/compute capabilities the worker possesses.
     */
    function registerWorker(string[] calldata capabilities) external whenNotPaused {
        require(!workers[msg.sender].isRegistered, "Worker already registered");
        require(capabilities.length > 0, "Capabilities cannot be empty");

        workers[msg.sender] = WorkerInfo({
            workerAddress: msg.sender,
            isRegistered: true,
            capabilities: capabilities,
            reputationScore: 0,
            activeTasksCount: 0
        });

        emit WorkerRegistered(msg.sender, capabilities);
    }

    /**
     * @dev Allows a registered worker to stake ETH collateral.
     * The amount staked contributes to their total stake.
     * Workers must meet the minimum stake requirement to accept tasks.
     */
    function stakeWorker() external payable whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        require(msg.value > 0, "Stake amount must be greater than 0");

        workerTotalStake[msg.sender] += msg.value;

        emit WorkerStaked(msg.sender, msg.value, workerTotalStake[msg.sender]);
    }

    /**
     * @dev Allows a registered worker to unstake available ETH collateral.
     * Cannot unstake funds that are currently locked in active tasks.
     * @param amount The amount of ETH to unstake.
     */
    function unstakeWorker(uint256 amount) external whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        uint256 availableStake = workerTotalStake[msg.sender] - workerLockedStake[msg.sender];
        require(amount > 0 && amount <= availableStake, "Insufficient available stake");

        workerTotalStake[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Unstake transfer failed"); // Basic transfer check

        emit WorkerUnstaked(msg.sender, amount, workerTotalStake[msg.sender]);
    }

    /**
     * @dev Updates the capabilities of a registered worker.
     * @param capabilities The new list of AI/compute capabilities.
     */
    function updateWorkerCapabilities(string[] calldata capabilities) external whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        require(capabilities.length > 0, "Capabilities cannot be empty");

        workers[msg.sender].capabilities = capabilities;
        emit WorkerCapabilitiesUpdated(msg.sender, capabilities);
    }

     /**
      * @dev Retrieves the information for a specific worker address.
      * @param workerAddress The address of the worker.
      * @return WorkerInfo struct containing the worker's details.
      */
    function getWorkerInfo(address workerAddress) external view returns (WorkerInfo memory) {
        return workers[workerAddress];
    }

    /**
     * @dev Gets the total number of registered workers. Note: This is just a counter.
     * Iterating through all workers is not feasible on-chain.
     * Off-chain systems should track WorkerRegistered events.
     */
    function getWorkerCount() external view returns (uint256) {
        // Cannot reliably count map elements on-chain.
        // This is a placeholder or requires tracking worker addresses in an array (gas intensive).
        // For this example, let's indicate it requires off-chain enumeration or a different pattern.
        // A simple approach for demo: just return a value indicating not easily available.
        // Or, if we tracked them in a dynamic array (less gas efficient): return workersArray.length;
        // Sticking to the spirit of showing the *concept* without overly complex patterns here:
        // Return a value indicating it's not a simple count. A better approach would involve
        // tracking addresses in an array, which adds significant gas cost. Let's skip the array
        // and just explain this is an off-chain indexing task, or provide a placeholder.
        // Let's provide a placeholder value like 0 and a note, or remove if it misleads.
        // Better yet, let's remove this function as it's hard to implement correctly/efficiently.
        // Re-reading requirement: must have 20+ functions. Let's re-add with a warning or simplify.
        // A simple counter incremented on registration is feasible, but doesn't give the *list*.
        // Let's add it as a simple counter for function count, with the caveat.
        return 0; // Placeholder - Actual count requires off-chain indexing or different contract pattern.
                 // A dynamic array `address[] private registeredWorkers;` populated in registerWorker
                 // would allow `return registeredWorkers.length;` but is less gas efficient.
                 // Let's choose the array approach to meet the function count.
    }
    // Let's actually add the dynamic array to enable getWorkerCount properly for the function count req.
    address[] private registeredWorkersArray; // To track registered workers for getWorkerCount


    /**
     * @dev Allows a worker to withdraw their accumulated earned balance and released stake.
     */
    function withdrawWorkerFunds() external whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        uint256 amount = workerEarnedBalance[msg.sender];
        require(amount > 0, "No funds available to withdraw");

        workerEarnedBalance[msg.sender] = 0;
        // Use transfer for security
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Worker withdrawal failed");

        emit WorkerFundsWithdrawn(msg.sender, amount);
    }


    // --- Task Management (Requester Side) Functions ---

    /**
     * @dev Creates a new AI compute task. The requester pays the task amount upfront.
     * @param paymentAmount The ETH payment offered for completing the task.
     * @param collateralRequired The amount of worker stake required to be locked for this task.
     * @param submissionDeadline Timestamp by which the result must be submitted.
     * @param inputDataPointer String pointing to the task's input data and code (e.g., IPFS hash).
     * @param requiredCapabilities List of capabilities the worker must have.
     * @return taskId The ID of the newly created task.
     */
    function createTask(
        uint256 paymentAmount,
        uint256 collateralRequired,
        uint256 submissionDeadline,
        string calldata inputDataPointer,
        string[] calldata requiredCapabilities
    ) external payable whenNotPaused returns (uint256 taskId) {
        require(msg.value == paymentAmount, "Incorrect ETH sent for task payment");
        require(paymentAmount > 0, "Task payment must be greater than 0");
        require(collateralRequired >= minWorkerStake, "Collateral required must be at least minWorkerStake");
        require(submissionDeadline > block.timestamp, "Submission deadline must be in the future");
        require(bytes(inputDataPointer).length > 0, "Input data pointer cannot be empty");
        require(requiredCapabilities.length > 0, "Required capabilities cannot be empty");

        taskId = _nextTaskId++;

        // Simple hash of capabilities for lookup - actual hashing needs careful implementation
        // For simplicity here, let's join them into a string and hash. Prone to order issues.
        // A better approach is a canonical representation or a dedicated library.
        string memory capabilitiesString;
        for(uint i = 0; i < requiredCapabilities.length; i++) {
            capabilitiesString = string.concat(capabilitiesString, requiredCapabilities[i]);
        }
        bytes32 capabilitiesHash = keccak256(bytes(capabilitiesString));


        tasks[taskId] = TaskInfo({
            taskId: taskId,
            requester: msg.sender,
            worker: address(0), // Unassigned initially
            state: TaskState.Open,
            paymentAmount: paymentAmount,
            collateralRequired: collateralRequired,
            submissionDeadline: submissionDeadline,
            inputDataPointer: inputDataPointer,
            outputDataPointer: "", // Set later by worker
            requiredCapabilitiesHash: string(abi.encodePacked(capabilitiesHash)), // Store hash as string (workaround)
            creationTime: block.timestamp,
            assignmentTime: 0,
            completionTime: 0,
            rejectionReason: ""
        });

        emit TaskCreated(taskId, msg.sender, paymentAmount, collateralRequired, inputDataPointer);
    }

     /**
      * @dev Retrieves the details for a specific task ID.
      * @param taskId The ID of the task.
      * @return TaskInfo struct containing the task's details.
      */
    function getTaskDetails(uint256 taskId) external view returns (TaskInfo memory) {
        require(tasks[taskId].taskId != 0, "Task does not exist");
        return tasks[taskId];
    }

    /**
     * @dev Allows the requester to cancel an open task.
     * Only possible if the task is in the Open state and before it's assigned.
     * Refunds the task payment to the requester.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 taskId) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.requester == msg.sender, "Not the task requester");
        require(task.state == TaskState.Open, "Task is not in Open state");

        task.state = TaskState.Cancelled;

        // Refund the task payment
        (bool success, ) = payable(task.requester).call{value: task.paymentAmount}("");
        require(success, "Requester refund failed"); // Basic transfer check

        emit TaskCancelled(taskId, msg.sender);
    }

    /**
     * @dev Allows the requester to accept the submitted result for a task.
     * Moves task to Accepted state and triggers payment to the worker.
     * @param taskId The ID of the task.
     * @param outputDataPointer String pointing to the verified output data (e.g., IPFS hash).
     */
    function acceptTaskResult(uint256 taskId, string calldata outputDataPointer) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.requester == msg.sender, "Not the task requester");
        require(task.state == TaskState.AwaitingReview, "Task is not awaiting review");
        require(bytes(outputDataPointer).length > 0, "Output data pointer cannot be empty");

        task.state = TaskState.Accepted;
        task.outputDataPointer = outputDataPointer;
        task.completionTime = block.timestamp;

        _payoutWorker(taskId);

        emit TaskAccepted(taskId, msg.sender, task.worker, task.paymentAmount);
    }

    /**
     * @dev Allows the requester to reject the submitted result for a task.
     * Moves task to Rejected state. Worker does not receive payment, collateral is released.
     * NOTE: This is a simplified rejection. Full systems would require arbitration or challenge periods.
     * @param taskId The ID of the task.
     * @param reason A description of the rejection reason.
     */
    function rejectTaskResult(uint256 taskId, string calldata reason) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.requester == msg.sender, "Not the task requester");
        require(task.state == TaskState.AwaitingReview, "Task is not awaiting review");
        require(bytes(reason).length > 0, "Rejection reason cannot be empty");

        task.state = TaskState.Rejected;
        task.rejectionReason = reason;
        task.completionTime = block.timestamp;

        // Release worker's locked collateral back to their available stake
        workerLockedStake[task.worker] -= task.collateralRequired;
        workers[task.worker].activeTasksCount--;

        // Task payment remains in the contract (e.g., sent to admin fees or held)
        // In this simplified version, it just increases the contract's balance or fee pool.
        // A real system might transfer it to the admin fee pool or a dispute resolution pool.
        // Let's add it to the admin fee pool for simplicity here.
        totalAdminFees += task.paymentAmount;

        emit TaskRejected(taskId, msg.sender, task.worker, reason);
        // Potentially emit a slashing event here, but the _slashWorker logic is simplified
        // to not auto-slash on simple rejection in this example.
    }


    // --- Task Management (Worker Side) Functions ---

    /**
     * @dev Retrieves a list of task IDs that are currently open and match the worker's capabilities.
     * Note: This view function iterates, which can be gas-intensive for many tasks.
     * Off-chain indexing based on TaskCreated events is recommended for production.
     * Returns max 100 task IDs to prevent excessive gas usage.
     * @param myCapabilities The capabilities of the worker searching for tasks.
     * @return An array of task IDs matching the criteria.
     */
    function findAvailableTasks(string[] calldata myCapabilities) external view returns (uint256[] memory) {
         // Simple hash of capabilities for lookup - matching needs careful implementation
        string memory capabilitiesString;
        for(uint i = 0; i < myCapabilities.length; i++) {
            capabilitiesString = string.concat(capabilitiesString, myCapabilities[i]);
        }
        bytes32 myCapabilitiesHash = keccak256(bytes(capabilitiesString));

        uint256[] memory openTaskIds = new uint256[](100); // Max 100 results
        uint256 count = 0;

        // WARNING: Iterating through a mapping like this is inefficient and gas-limited.
        // For demonstration purposes only. Production systems need off-chain indexing.
        // Looping up to _nextTaskId can still be very gas-intensive if many tasks exist,
        // even if limited results are returned. This highlights a limitation of on-chain filtering.
        // A better on-chain pattern might involve linked lists or other structures,
        // but for simplicity and function count, we include this with a limitation.
        for (uint256 i = 1; i < _nextTaskId; i++) {
            TaskInfo storage task = tasks[i];
            // Check if task exists, is open, and capabilities match (using simple hash comparison)
            if (task.taskId != 0 && task.state == TaskState.Open && keccak256(bytes(task.requiredCapabilitiesHash)) == myCapabilitiesHash) {
                 // More robust capability matching would involve comparing the string arrays element by element,
                 // checking if the worker's capabilities contain *all* required capabilities.
                 // This simple hash check assumes an exact match is required, or the off-chain search
                 // provides the correct hash for a partial match based on *its* filtering logic.
                 // Let's use the simple hash comparison for now to avoid complex string array comparison on-chain.
                 // A slightly better on-chain check would iterate through task.requiredCapabilities
                 // and check if msg.sender's capabilities include all of them. This is also gas-intensive.
                 // Let's refine this to iterate through *required* capabilities and check against worker's.

                 // --- Refined Capability Check (still potentially gas intensive) ---
                 bool capabilitiesMatch = true;
                 // Need worker capabilities here
                 // Cannot directly access msg.sender's worker info easily inside this pure/view loop
                 // This function signature needs the worker's address passed in, or be restricted to msg.sender.
                 // Let's restrict to msg.sender and get their capabilities.
                 // This also means the function cannot simply be `view`, it might need `pure` if it didn't access state,
                 // or just `view` if it accesses msg.sender's worker info. Let's make it require the worker address.
                 // No, the requirement is for a *worker* to find tasks *they* can do. msg.sender *is* the worker.
                 // Let's revert to msg.sender check. It can be a `view` function accessing `workers[msg.sender]`.

                 WorkerInfo memory worker = workers[msg.sender];
                 if (!worker.isRegistered) continue; // Skip if not a registered worker

                 // Need to re-calculate the hash from the task's stored string representation
                 // String to bytes to hash:
                 bytes32 taskReqCapsHash = keccak256(bytes(tasks[i].requiredCapabilitiesHash));

                 // Now compare this hash to a hash of the worker's capabilities.
                 // This still feels fragile as it requires hashing the worker's capabilities *inside* the loop.
                 // And simple hash comparison doesn't check if *all* required caps are *present* in the worker's caps.
                 // The ideal check: iterate required caps, check if each is in worker's caps. Very gas heavy.
                 // Let's stick to the simple hash check as an abstraction of "matching" capabilities for this example.
                 // It implies the off-chain system submitting tasks/registering workers ensures this hash represents the capabilities accurately.

                 // Let's try the more explicit check, even if gas-heavy for arrays.
                 // This requires re-fetching the task's required capabilities string array.
                 // Oh, wait, the struct stores a HASH, not the array itself.
                 // This means the matching logic *must* be based on comparing this hash
                 // with a hash derived from the worker's capabilities. This is still limiting
                 // (requires exact capability set match, not superset).

                 // Alternative: store capabilities in the TaskInfo struct as a string array.
                 // This makes `createTask` more expensive, but allows `findAvailableTasks` to iterate
                 // through `task.requiredCapabilities` and check `worker.capabilities` for each.
                 // Let's change `TaskInfo` struct to store `string[] requiredCapabilities;`
                 // This adds complexity to storage but enables the check.

                 // --- Re-implementing with string[] requiredCapabilities in struct ---
                 // (Need to update struct definition and createTask)
                 // Let's assume struct is updated...

                 // Check if worker has all required capabilities
                 bool hasAllRequired = true;
                 // Need task details here, and worker capabilities
                 TaskInfo memory currentTask = tasks[i]; // Get task details
                 WorkerInfo memory currentWorker = workers[msg.sender]; // Get worker details

                 if (currentWorker.isRegistered) { // Only check if worker is registered
                     for (uint j = 0; j < currentTask.requiredCapabilities.length; j++) {
                         bool foundCap = false;
                         for (uint k = 0; k < currentWorker.capabilities.length; k++) {
                             if (keccak256(bytes(currentTask.requiredCapabilities[j])) == keccak256(bytes(currentWorker.capabilities[k]))) {
                                 foundCap = true;
                                 break;
                             }
                         }
                         if (!foundCap) {
                             hasAllRequired = false;
                             break;
                         }
                     }
                 } else {
                    hasAllRequired = false; // Unregistered worker cannot find tasks
                 }


                 if (hasAllRequired && count < 100) { // Add to results if match and limit not reached
                     openTaskIds[count] = i;
                     count++;
                 }
                 // --- End Refined Capability Check ---

            }
        }

        // Copy found IDs to a new array of the correct size
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTaskIds[i];
        }
        return result;
    }


    /**
     * @dev Allows a registered worker to assign an open task to themselves.
     * Requires the worker to have sufficient available stake to meet the task's collateral requirement.
     * Locks the required collateral amount.
     * @param taskId The ID of the task to assign.
     */
    function assignTaskToSelf(uint256 taskId) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        WorkerInfo storage worker = workers[msg.sender];

        require(task.taskId != 0, "Task does not exist");
        require(worker.isRegistered, "Worker not registered");
        require(task.state == TaskState.Open, "Task is not in Open state");
        require(workerTotalStake[msg.sender] - workerLockedStake[msg.sender] >= task.collateralRequired, "Insufficient available stake");
        // Add check if worker capabilities match task requirements (based on findAvailableTasks logic)
         bool hasAllRequired = true;
         for (uint j = 0; j < task.requiredCapabilities.length; j++) {
             bool foundCap = false;
             for (uint k = 0; k < worker.capabilities.length; k++) {
                 if (keccak256(bytes(task.requiredCapabilities[j])) == keccak256(bytes(worker.capabilities[k]))) {
                     foundCap = true;
                     break;
                 }
             }
             if (!foundCap) {
                 hasAllRequired = false;
                 break;
             }
         }
        require(hasAllRequired, "Worker capabilities do not match task requirements");


        task.worker = msg.sender;
        task.state = TaskState.Assigned;
        task.assignmentTime = block.timestamp;

        // Lock required collateral
        workerLockedStake[msg.sender] += task.collateralRequired;
        worker.activeTasksCount++;

        emit TaskAssigned(taskId, msg.sender);
    }

    /**
     * @dev Allows the assigned worker to submit the result for a task.
     * Requires the task to be in the Assigned state and before the submission deadline.
     * Moves task to AwaitingReview state.
     * @param taskId The ID of the task.
     * @param outputDataPointer String pointing to the task's output data (e.g., IPFS hash).
     */
    function submitTaskResult(uint256 taskId, string calldata outputDataPointer) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.worker == msg.sender, "Not the assigned worker for this task");
        require(task.state == TaskState.Assigned || task.state == TaskState.InProgress, "Task is not in Assigned/InProgress state"); // Allow 'InProgress' if we added a state transition
        require(block.timestamp <= task.submissionDeadline, "Submission deadline passed");
        require(bytes(outputDataPointer).length > 0, "Output data pointer cannot be empty");

        task.outputDataPointer = outputDataPointer;
        task.state = TaskState.AwaitingReview;
        task.completionTime = block.timestamp; // Mark completion time upon submission

        emit ResultSubmitted(taskId, msg.sender, outputDataPointer);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Handles the payout to the worker and releases locked collateral upon task acceptance.
     * Calculates and deducts the platform fee.
     * @param taskId The ID of the task to process payout for.
     */
    function _payoutWorker(uint256 taskId) internal {
        TaskInfo storage task = tasks[taskId];
        WorkerInfo storage worker = workers[task.worker];

        uint256 taskPayment = task.paymentAmount;
        uint256 fee = (taskPayment * taskFeePercentage) / 100;
        uint256 payout = taskPayment - fee;

        // Add payout to worker's earned balance (for withdrawal later)
        workerEarnedBalance[task.worker] += payout;

        // Add fee to admin fees
        totalAdminFees += fee;

        // Release locked collateral back to worker's available stake
        workerLockedStake[task.worker] -= task.collateralRequired;

        // Update worker stats
        worker.reputationScore++;
        worker.activeTasksCount--;
    }

    /**
     * @dev Handles slashing of a worker's stake.
     * NOTE: This is a simplified implementation. Real slashing requires complex triggers
     * like failed validation from an oracle or resolution of a dispute.
     * In this example, it's shown as a separate concept not directly tied to `rejectTaskResult`.
     * @param workerAddress The address of the worker to slash.
     * @param amount The amount of stake to slash.
     * @param taskId The relevant task ID (for context).
     * @param reason The reason for slashing.
     */
    function _slashWorker(address workerAddress, uint256 amount, uint256 taskId, string memory reason) internal {
        WorkerInfo storage worker = workers[workerAddress];
        require(worker.isRegistered, "Worker not registered");
        // Cannot slash more than total staked - locked stake (potentially slash from total)
        // Decide if slashing comes from available stake or total stake.
        // Usually, slashing affects the *total* stake.
        require(workerTotalStake[workerAddress] >= amount, "Insufficient total stake to slash");

        workerTotalStake[workerAddress] -= amount;

        // Funds from slashing could be burned, sent to a treasury, or used for bounties.
        // For simplicity, let's send them to the admin fee pool.
        totalAdminFees += amount;

        emit WorkerSlashing(workerAddress, amount, taskId, reason);

        // Note: Releasing locked stake related to the task (if any) might also be needed
        // depending on *when* slashing occurs relative to the task lifecycle.
        // This simplified function doesn't automatically release locked stake.
    }


    // --- Additional Functions to meet 20+ count and provide utilities ---

    /**
     * @dev Gets the total number of created tasks. Note: This is just a counter.
     * Off-chain systems should track TaskCreated events for a list of tasks.
     */
    function getTaskCount() external view returns (uint256) {
        // Returns the count of created tasks.
        return _nextTaskId - 1; // _nextTaskId is the ID for the *next* task, so subtract 1 for total created.
    }

    /**
     * @dev Gets a worker's total staked amount.
     * @param workerAddress The address of the worker.
     * @return The total stake amount in wei.
     */
    function getWorkerTotalStake(address workerAddress) external view returns (uint256) {
        return workerTotalStake[workerAddress];
    }

     /**
     * @dev Gets a worker's locked staked amount.
     * @param workerAddress The address of the worker.
     * @return The locked stake amount in wei.
     */
    function getWorkerLockedStake(address workerAddress) external view returns (uint256) {
        return workerLockedStake[workerAddress];
    }

     /**
     * @dev Gets a worker's available staked amount (Total - Locked).
     * @param workerAddress The address of the worker.
     * @return The available stake amount in wei.
     */
    function getWorkerAvailableStake(address workerAddress) external view returns (uint256) {
        return workerTotalStake[workerAddress] - workerLockedStake[workerAddress];
    }

    /**
     * @dev Gets a worker's accumulated earned balance ready for withdrawal.
     * @param workerAddress The address of the worker.
     * @return The earned balance amount in wei.
     */
    function getWorkerEarnedBalance(address workerAddress) external view returns (uint256) {
        return workerEarnedBalance[workerAddress];
    }

    /**
     * @dev Gets the current state of the contract (paused or not).
     * @return True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Gets the contract owner's address.
     * @return The owner's address.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    // Re-added getWorkerCount properly using the array
    function getRegisteredWorkerCount() external view returns (uint256) {
         return registeredWorkersArray.length;
    }

    // Add Worker address to array on registration
     // Modified registerWorker function:
     // function registerWorker(...) { ... registeredWorkersArray.push(msg.sender); ... }

    // Check function count again:
    // 1. constructor
    // 2. pause
    // 3. unpause
    // 4. setMinWorkerStake
    // 5. setTaskFeePercentage
    // 6. withdrawAdminFees
    // 7. transferOwnership
    // 8. registerWorker (will be modified to add to array)
    // 9. stakeWorker
    // 10. unstakeWorker
    // 11. updateWorkerCapabilities
    // 12. getWorkerInfo
    // 13. getWorkerCount (replaced with getRegisteredWorkerCount)
    // 14. withdrawWorkerFunds
    // 15. createTask
    // 16. getTaskDetails
    // 17. cancelTask
    // 18. acceptTaskResult
    // 19. rejectTaskResult
    // 20. findAvailableTasks
    // 21. assignTaskToSelf
    // 22. submitTaskResult
    // 23. getTaskCount
    // 24. getWorkerTotalStake
    // 25. getWorkerLockedStake
    // 26. getWorkerAvailableStake
    // 27. getWorkerEarnedBalance
    // 28. isPaused
    // 29. owner

    // Okay, that's 29 public/external functions. Plenty!

    // Let's add the modification to registerWorker to include the worker in the array.
    // Let's also modify the struct TaskInfo to store string[] requiredCapabilities as decided for findAvailableTasks.

}
```

---

**Refined `TaskInfo` Struct and `createTask`, `findAvailableTasks`, `assignTaskToSelf`:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIComputeMarketplace
 * @author Your Name/Alias
 * @dev A decentralized marketplace for AI/ML compute tasks.
 * Requesters submit tasks with payment, Workers stake collateral to pick up tasks,
 * execute them off-chain, and submit results. The contract manages escrow and state transitions.
 * Advanced features like robust result verification and complex slashing require off-chain systems.
 */
contract DecentralizedAIComputeMarketplace {

    // --- Outline and Function Summary ---
    // State Variables: Store contract data like workers, tasks, settings.
    // Enums: Define possible states for tasks.
    // Structs: Define data structures for workers and tasks.
    // Events: Announce key actions for off-chain monitoring.
    // Modifiers: Restrict function access (owner, paused state).

    // Admin Functions:
    // 1. constructor: Initializes contract owner and basic settings.
    // 2. pause(): Pauses the contract in case of emergency.
    // 3. unpause(): Unpauses the contract.
    // 4. setMinWorkerStake(): Sets the minimum required stake for workers.
    // 5. setTaskFeePercentage(): Sets the fee percentage taken from task payments.
    // 6. withdrawAdminFees(): Allows owner to withdraw accumulated fees.
    // 7. transferOwnership(): Transfers ownership to a new address.

    // Worker Management Functions:
    // 8. registerWorker(): Registers a new worker with their capabilities. Includes adding to internal array.
    // 9. stakeWorker(): Allows a worker to stake ETH collateral.
    // 10. unstakeWorker(): Allows a worker to unstake available ETH collateral.
    // 11. updateWorkerCapabilities(): Updates the capabilities of a registered worker.
    // 12. getWorkerInfo(): Retrieves information about a specific worker. (View)
    // 13. getRegisteredWorkerCount(): Gets the total number of registered workers. (View)
    // 14. withdrawWorkerFunds(): Allows workers to withdraw earned task payments and unstaked collateral.

    // Task Management (Requester Side) Functions:
    // 15. createTask(): Creates a new AI compute task with parameters and payment. (Payable)
    // 16. getTaskDetails(): Retrieves detailed information about a specific task. (View)
    // 17. cancelTask(): Allows the requester to cancel an open task.
    // 18. acceptTaskResult(): Allows the requester to accept a submitted result. Triggers payment.
    // 19. rejectTaskResult(): Allows the requester to reject a submitted result. (Simplified slashing logic)

    // Task Management (Worker Side) Functions:
    // 20. findAvailableTasks(): Retrieves IDs of tasks currently open and matching worker capabilities. (View)
    // 21. assignTaskToSelf(): Allows a worker to claim an open task. Locks collateral.
    // 22. submitTaskResult(): Allows the assigned worker to submit the task result.

    // Utility/View Functions:
    // 23. getTaskCount(): Gets the total number of created tasks. (View)
    // 24. getWorkerTotalStake(): Gets a worker's total staked amount. (View)
    // 25. getWorkerLockedStake(): Gets a worker's locked staked amount. (View)
    // 26. getWorkerAvailableStake(): Gets a worker's available staked amount. (View)
    // 27. getWorkerEarnedBalance(): Gets a worker's accumulated earned balance. (View)
    // 28. isPaused(): Checks if the contract is paused. (View)
    // 29. owner(): Gets the contract owner's address. (View)

    // Internal Helper Functions (Not callable externally, assist main logic):
    // _payoutWorker(): Handles payment and stake release upon task acceptance.
    // _slashWorker(): Handles slashing of worker stake (simplified).


    // --- State Variables ---
    address private _owner;
    bool private _paused;

    uint256 public minWorkerStake; // Minimum ETH required for a worker to stake
    uint256 public taskFeePercentage; // Percentage of task payment taken as fee (e.g., 5 for 5%)
    uint256 public totalAdminFees; // Accumulated fees

    uint256 private _nextTaskId = 1;
    mapping(uint256 => TaskInfo) public tasks;
    mapping(address => WorkerInfo) public workers;
    address[] private registeredWorkersArray; // To track registered workers for getRegisteredWorkerCount

    // Maps Worker address to their available and locked staked balance
    mapping(address => uint256) private workerTotalStake; // Total ETH staked by worker
    mapping(address => uint256) private workerLockedStake; // ETH locked for assigned tasks

    // Stores balances earned from completed tasks waiting for withdrawal
    mapping(address => uint256) private workerEarnedBalance;

    // --- Enums ---
    enum TaskState { Open, Assigned, InProgress, AwaitingReview, Accepted, Rejected, Cancelled }

    // --- Structs ---
    struct WorkerInfo {
        address workerAddress;
        bool isRegistered;
        string[] capabilities; // e.g., ["GPU", "TensorFlow", "DataSize_Large"]
        uint256 reputationScore; // Basic metric: number of successfully completed tasks
        uint256 activeTasksCount; // Number of tasks currently assigned to this worker
    }

    struct TaskInfo {
        uint256 taskId;
        address requester;
        address worker; // Assigned worker address (0x0 if not assigned)
        TaskState state;
        uint256 paymentAmount; // Amount paid by requester for the task
        uint256 collateralRequired; // Amount of worker stake to lock for this task
        uint256 submissionDeadline; // Timestamp by which the result must be submitted
        string inputDataPointer; // e.g., IPFS hash or URL for input data/code
        string outputDataPointer; // e.g., IPFS hash or URL for output data
        string[] requiredCapabilities; // List of capabilities the worker must have (Added/Modified)
        uint256 creationTime;
        uint256 assignmentTime;
        uint256 completionTime; // Time result was submitted/accepted/rejected
        string rejectionReason; // Reason if task was rejected
    }

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event WorkerRegistered(address indexed workerAddress, string[] capabilities);
    event WorkerStaked(address indexed workerAddress, uint256 amount, uint256 totalStake);
    event WorkerUnstaked(address indexed workerAddress, uint256 amount, uint256 totalStake);
    event WorkerCapabilitiesUpdated(address indexed workerAddress, string[] capabilities);
    event WorkerFundsWithdrawn(address indexed workerAddress, uint256 amount);

    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 paymentAmount, uint256 collateralRequired, string inputDataPointer, string[] requiredCapabilities); // Added requiredCapabilities to event
    event TaskAssigned(uint256 indexed taskId, address indexed worker);
    event ResultSubmitted(uint256 indexed taskId, address indexed worker, string outputDataPointer);
    event TaskAccepted(uint256 indexed taskId, address indexed requester, address indexed worker, uint256 paymentAmount);
    event TaskRejected(uint256 indexed taskId, address indexed requester, address indexed worker, string rejectionReason);
    event TaskCancelled(uint256 indexed taskId, address indexed requester);

    event AdminFeesWithdrawn(address indexed owner, uint256 amount);
    event WorkerSlashing(address indexed workerAddress, uint256 amount, uint256 taskId, string reason);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _minWorkerStake, uint256 _taskFeePercentage) {
        require(_taskFeePercentage <= 100, "Fee percentage cannot exceed 100");
        _owner = msg.sender;
        minWorkerStake = _minWorkerStake;
        taskFeePercentage = _taskFeePercentage;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- Admin Functions ---

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the minimum required stake for a worker. Only owner can call.
     * @param _minStake The new minimum stake amount in wei.
     */
    function setMinWorkerStake(uint256 _minStake) external onlyOwner {
        minWorkerStake = _minStake;
    }

    /**
     * @dev Sets the percentage of task payment taken as a fee. Only owner can call.
     * @param _feePercentage The new fee percentage (e.g., 5 for 5%).
     */
    function setTaskFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        taskFeePercentage = _feePercentage;
    }

    /**
     * @dev Allows the owner to withdraw accumulated fees.
     */
    function withdrawAdminFees() external onlyOwner {
        uint256 feeAmount = totalAdminFees;
        require(feeAmount > 0, "No fees accumulated");
        totalAdminFees = 0;
        // Use call for flexibility, with re-entrancy guard if needed
        (bool success, ) = payable(msg.sender).call{value: feeAmount}("");
        require(success, "Fee withdrawal failed");
        emit AdminFeesWithdrawn(msg.sender, feeAmount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    // --- Worker Management Functions ---

    /**
     * @dev Registers a new address as a worker with specified capabilities.
     * A worker must be registered before staking or taking tasks.
     * Adds the worker's address to an internal array for tracking.
     * @param capabilities The list of AI/compute capabilities the worker possesses.
     */
    function registerWorker(string[] calldata capabilities) external whenNotPaused {
        require(!workers[msg.sender].isRegistered, "Worker already registered");
        require(capabilities.length > 0, "Capabilities cannot be empty");

        workers[msg.sender] = WorkerInfo({
            workerAddress: msg.sender,
            isRegistered: true,
            capabilities: capabilities,
            reputationScore: 0,
            activeTasksCount: 0
        });
        registeredWorkersArray.push(msg.sender); // Add to tracking array

        emit WorkerRegistered(msg.sender, capabilities);
    }

    /**
     * @dev Allows a registered worker to stake ETH collateral.
     * The amount staked contributes to their total stake.
     * Workers must meet the minimum stake requirement to accept tasks.
     */
    function stakeWorker() external payable whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        require(msg.value > 0, "Stake amount must be greater than 0");

        workerTotalStake[msg.sender] += msg.value;

        emit WorkerStaked(msg.sender, msg.value, workerTotalStake[msg.sender]);
    }

    /**
     * @dev Allows a registered worker to unstake available ETH collateral.
     * Cannot unstake funds that are currently locked in active tasks.
     * @param amount The amount of ETH to unstake.
     */
    function unstakeWorker(uint256 amount) external whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        uint256 availableStake = workerTotalStake[msg.sender] - workerLockedStake[msg.sender];
        require(amount > 0 && amount <= availableStake, "Insufficient available stake");

        workerTotalStake[msg.sender] -= amount;
        // Use call for flexibility
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Unstake transfer failed");

        emit WorkerUnstaked(msg.sender, amount, workerTotalStake[msg.sender]);
    }

    /**
     * @dev Updates the capabilities of a registered worker.
     * @param capabilities The new list of AI/compute capabilities.
     */
    function updateWorkerCapabilities(string[] calldata capabilities) external whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        require(capabilities.length > 0, "Capabilities cannot be empty");

        workers[msg.sender].capabilities = capabilities;
        emit WorkerCapabilitiesUpdated(msg.sender, capabilities);
    }

     /**
      * @dev Retrieves the information for a specific worker address.
      * @param workerAddress The address of the worker.
      * @return WorkerInfo struct containing the worker's details.
      */
    function getWorkerInfo(address workerAddress) external view returns (WorkerInfo memory) {
        return workers[workerAddress];
    }

    /**
     * @dev Gets the total number of registered workers.
     * Uses an internal array populated during registration.
     * @return The count of registered workers.
     */
    function getRegisteredWorkerCount() external view returns (uint256) {
         return registeredWorkersArray.length;
    }

    /**
     * @dev Allows a worker to withdraw their accumulated earned balance and released stake.
     */
    function withdrawWorkerFunds() external whenNotPaused {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        uint256 amount = workerEarnedBalance[msg.sender];
        require(amount > 0, "No funds available to withdraw");

        workerEarnedBalance[msg.sender] = 0;
        // Use call for flexibility
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Worker withdrawal failed");

        emit WorkerFundsWithdrawn(msg.sender, amount);
    }


    // --- Task Management (Requester Side) Functions ---

    /**
     * @dev Creates a new AI compute task. The requester pays the task amount upfront.
     * @param paymentAmount The ETH payment offered for completing the task.
     * @param collateralRequired The amount of worker stake required to be locked for this task.
     * @param submissionDeadline Timestamp by which the result must be submitted.
     * @param inputDataPointer String pointing to the task's input data and code (e.g., IPFS hash).
     * @param requiredCapabilities List of capabilities the worker must have.
     * @return taskId The ID of the newly created task.
     */
    function createTask(
        uint256 paymentAmount,
        uint256 collateralRequired,
        uint256 submissionDeadline,
        string calldata inputDataPointer,
        string[] calldata requiredCapabilities
    ) external payable whenNotPaused returns (uint256 taskId) {
        require(msg.value == paymentAmount, "Incorrect ETH sent for task payment");
        require(paymentAmount > 0, "Task payment must be greater than 0");
        require(collateralRequired >= minWorkerStake, "Collateral required must be at least minWorkerStake");
        require(submissionDeadline > block.timestamp, "Submission deadline must be in the future");
        require(bytes(inputDataPointer).length > 0, "Input data pointer cannot be empty");
        require(requiredCapabilities.length > 0, "Required capabilities cannot be empty");

        taskId = _nextTaskId++;

        tasks[taskId] = TaskInfo({
            taskId: taskId,
            requester: msg.sender,
            worker: address(0), // Unassigned initially
            state: TaskState.Open,
            paymentAmount: paymentAmount,
            collateralRequired: collateralRequired,
            submissionDeadline: submissionDeadline,
            inputDataPointer: inputDataPointer,
            outputDataPointer: "", // Set later by worker
            requiredCapabilities: requiredCapabilities, // Stored the array
            creationTime: block.timestamp,
            assignmentTime: 0,
            completionTime: 0,
            rejectionReason: ""
        });

        emit TaskCreated(taskId, msg.sender, paymentAmount, collateralRequired, inputDataPointer, requiredCapabilities);
    }

     /**
      * @dev Retrieves the details for a specific task ID.
      * @param taskId The ID of the task.
      * @return TaskInfo struct containing the task's details.
      */
    function getTaskDetails(uint256 taskId) external view returns (TaskInfo memory) {
        require(tasks[taskId].taskId != 0, "Task does not exist");
        return tasks[taskId];
    }

    /**
     * @dev Allows the requester to cancel an open task.
     * Only possible if the task is in the Open state and before it's assigned.
     * Refunds the task payment to the requester.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 taskId) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.requester == msg.sender, "Not the task requester");
        require(task.state == TaskState.Open, "Task is not in Open state");

        task.state = TaskState.Cancelled;

        // Refund the task payment
        (bool success, ) = payable(task.requester).call{value: task.paymentAmount}("");
        require(success, "Requester refund failed");

        emit TaskCancelled(taskId, msg.sender);
    }

    /**
     * @dev Allows the requester to accept the submitted result for a task.
     * Moves task to Accepted state and triggers payment to the worker.
     * @param taskId The ID of the task.
     * @param outputDataPointer String pointing to the verified output data (e.g., IPFS hash).
     */
    function acceptTaskResult(uint256 taskId, string calldata outputDataPointer) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.requester == msg.sender, "Not the task requester");
        require(task.state == TaskState.AwaitingReview, "Task is not awaiting review");
        require(bytes(outputDataPointer).length > 0, "Output data pointer cannot be empty");

        task.state = TaskState.Accepted;
        task.outputDataPointer = outputDataPointer;
        task.completionTime = block.timestamp;

        _payoutWorker(taskId);

        emit TaskAccepted(taskId, msg.sender, task.worker, task.paymentAmount);
    }

    /**
     * @dev Allows the requester to reject the submitted result for a task.
     * Moves task to Rejected state. Worker does not receive payment, collateral is released.
     * NOTE: This is a simplified rejection. Full systems would require arbitration or challenge periods.
     * @param taskId The ID of the task.
     * @param reason A description of the rejection reason.
     */
    function rejectTaskResult(uint256 taskId, string calldata reason) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.requester == msg.sender, "Not the task requester");
        require(task.state == TaskState.AwaitingReview, "Task is not awaiting review");
        require(bytes(reason).length > 0, "Rejection reason cannot be empty");

        task.state = TaskState.Rejected;
        task.rejectionReason = reason;
        task.completionTime = block.timestamp;

        // Release worker's locked collateral back to their available stake
        workerLockedStake[task.worker] -= task.collateralRequired;
        workers[task.worker].activeTasksCount--;

        // Task payment remains in the contract (added to admin fee pool)
        totalAdminFees += task.paymentAmount;

        emit TaskRejected(taskId, msg.sender, task.worker, reason);
        // No automatic slashing in this simplified version.
    }


    // --- Task Management (Worker Side) Functions ---

    /**
     * @dev Retrieves a list of task IDs that are currently open and match the worker's capabilities.
     * Note: This view function iterates, which can be gas-intensive for many tasks.
     * Off-chain indexing based on TaskCreated events is recommended for production.
     * Returns max 100 task IDs to prevent excessive gas usage.
     * @return An array of task IDs matching the criteria.
     */
    function findAvailableTasks() external view returns (uint256[] memory) {
        WorkerInfo storage worker = workers[msg.sender];
        require(worker.isRegistered, "Caller is not a registered worker");

        uint256[] memory openTaskIds = new uint256[](100); // Max 100 results
        uint256 count = 0;

        // WARNING: Iterating through a mapping like this is inefficient and gas-limited.
        // For demonstration purposes only. Production systems need off-chain indexing.
        // Looping up to _nextTaskId can still be very gas-intensive.
        for (uint256 i = 1; i < _nextTaskId; i++) {
            TaskInfo storage task = tasks[i];

            // Check if task exists, is open, and worker capabilities match task requirements
            if (task.taskId != 0 && task.state == TaskState.Open && task.requester != address(0)) { // Check requester != 0x0 to confirm valid task entry
                 // Check if worker has all required capabilities
                 bool hasAllRequired = true;
                 for (uint j = 0; j < task.requiredCapabilities.length; j++) {
                     bool foundCap = false;
                     for (uint k = 0; k < worker.capabilities.length; k++) {
                         if (keccak256(bytes(task.requiredCapabilities[j])) == keccak256(bytes(worker.capabilities[k]))) {
                             foundCap = true;
                             break;
                         }
                     }
                     if (!foundCap) {
                         hasAllRequired = false;
                         break;
                     }
                 }

                 if (hasAllRequired && count < 100) { // Add to results if match and limit not reached
                     openTaskIds[count] = i;
                     count++;
                 }
            }
        }

        // Copy found IDs to a new array of the correct size
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTaskIds[i];
        }
        return result;
    }


    /**
     * @dev Allows a registered worker to assign an open task to themselves.
     * Requires the worker to have sufficient available stake to meet the task's collateral requirement.
     * Locks the required collateral amount.
     * @param taskId The ID of the task to assign.
     */
    function assignTaskToSelf(uint256 taskId) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        WorkerInfo storage worker = workers[msg.sender];

        require(task.taskId != 0, "Task does not exist");
        require(worker.isRegistered, "Worker not registered");
        require(task.state == TaskState.Open, "Task is not in Open state");
        require(workerTotalStake[msg.sender] - workerLockedStake[msg.sender] >= task.collateralRequired, "Insufficient available stake");
        require(task.requester != address(0), "Invalid task entry"); // Ensure it's a valid task, not default struct

        // Check if worker capabilities match task requirements
         bool hasAllRequired = true;
         for (uint j = 0; j < task.requiredCapabilities.length; j++) {
             bool foundCap = false;
             for (uint k = 0; k < worker.capabilities.length; k++) {
                 if (keccak256(bytes(task.requiredCapabilities[j])) == keccak256(bytes(worker.capabilities[k]))) {
                     foundCap = true;
                     break;
                 }
             }
             if (!foundCap) {
                 hasAllRequired = false;
                 break;
             }
         }
        require(hasAllRequired, "Worker capabilities do not match task requirements");


        task.worker = msg.sender;
        task.state = TaskState.Assigned;
        task.assignmentTime = block.timestamp;

        // Lock required collateral
        workerLockedStake[msg.sender] += task.collateralRequired;
        worker.activeTasksCount++;

        emit TaskAssigned(taskId, msg.sender);
    }

    /**
     * @dev Allows the assigned worker to submit the result for a task.
     * Requires the task to be in the Assigned state and before the submission deadline.
     * Moves task to AwaitingReview state.
     * @param taskId The ID of the task.
     * @param outputDataPointer String pointing to the task's output data (e.g., IPFS hash).
     */
    function submitTaskResult(uint256 taskId, string calldata outputDataPointer) external whenNotPaused {
        TaskInfo storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.worker == msg.sender, "Not the assigned worker for this task");
        require(task.state == TaskState.Assigned, "Task is not in Assigned state"); // Simplified: only from Assigned state
        require(block.timestamp <= task.submissionDeadline, "Submission deadline passed");
        require(bytes(outputDataPointer).length > 0, "Output data pointer cannot be empty");

        task.outputDataPointer = outputDataPointer;
        task.state = TaskState.AwaitingReview;
        task.completionTime = block.timestamp; // Mark completion time upon submission

        emit ResultSubmitted(taskId, msg.sender, outputDataPointer);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Handles the payout to the worker and releases locked collateral upon task acceptance.
     * Calculates and deducts the platform fee.
     * @param taskId The ID of the task to process payout for.
     */
    function _payoutWorker(uint256 taskId) internal {
        TaskInfo storage task = tasks[taskId];
        WorkerInfo storage worker = workers[task.worker];

        uint256 taskPayment = task.paymentAmount;
        uint256 fee = (taskPayment * taskFeePercentage) / 100;
        uint256 payout = taskPayment - fee;

        // Add payout to worker's earned balance (for withdrawal later)
        workerEarnedBalance[task.worker] += payout;

        // Add fee to admin fees
        totalAdminFees += fee;

        // Release locked collateral back to worker's available stake
        workerLockedStake[task.worker] -= task.collateralRequired;

        // Update worker stats
        worker.reputationScore++;
        worker.activeTasksCount--;
    }

    /**
     * @dev Handles slashing of a worker's stake.
     * NOTE: This is a simplified implementation. Real slashing requires complex triggers
     * like failed validation from an oracle or resolution of a dispute.
     * In this example, it's shown as a separate concept not directly tied to `rejectTaskResult`.
     * @param workerAddress The address of the worker to slash.
     * @param amount The amount of stake to slash.
     * @param taskId The relevant task ID (for context).
     * @param reason The reason for slashing.
     */
    function _slashWorker(address workerAddress, uint256 amount, uint256 taskId, string memory reason) internal {
        WorkerInfo storage worker = workers[workerAddress];
        require(worker.isRegistered, "Worker not registered");
        // Cannot slash more than total staked
        require(workerTotalStake[workerAddress] >= amount, "Insufficient total stake to slash");

        workerTotalStake[workerAddress] -= amount;

        // Funds from slashing could be burned, sent to a treasury, or used for bounties.
        // For simplicity, send to admin fee pool.
        totalAdminFees += amount;

        emit WorkerSlashing(workerAddress, amount, taskId, reason);

        // If slashing occurs for a task that still has locked collateral,
        // that locked collateral should also be slashed/handled.
        // This simplified _slashWorker doesn't auto-release/slash locked stake for specific tasks.
        // A real system would need more state or parameters for slashing linked to specific tasks.
    }


    // --- Utility/View Functions ---

    /**
     * @dev Gets the total number of created tasks. Note: This is just a counter.
     * Off-chain systems should track TaskCreated events for a list of tasks.
     */
    function getTaskCount() external view returns (uint256) {
        return _nextTaskId - 1;
    }

    /**
     * @dev Gets a worker's total staked amount.
     * @param workerAddress The address of the worker.
     * @return The total stake amount in wei.
     */
    function getWorkerTotalStake(address workerAddress) external view returns (uint256) {
        return workerTotalStake[workerAddress];
    }

     /**
     * @dev Gets a worker's locked staked amount.
     * @param workerAddress The address of the worker.
     * @return The locked stake amount in wei.
     */
    function getWorkerLockedStake(address workerAddress) external view returns (uint256) {
        return workerLockedStake[workerAddress];
    }

     /**
     * @dev Gets a worker's available staked amount (Total - Locked).
     * @param workerAddress The address of the worker.
     * @return The available stake amount in wei.
     */
    function getWorkerAvailableStake(address workerAddress) external view returns (uint256) {
         uint256 total = workerTotalStake[workerAddress];
         uint256 locked = workerLockedStake[workerAddress];
         // Using checked arithmetic from 0.8+
         if (locked > total) return 0; // Should not happen with correct logic, but safety
         return total - locked;
    }

    /**
     * @dev Gets a worker's accumulated earned balance ready for withdrawal.
     * @param workerAddress The address of the worker.
     * @return The earned balance amount in wei.
     */
    function getWorkerEarnedBalance(address workerAddress) external view returns (uint256) {
        return workerEarnedBalance[workerAddress];
    }

    /**
     * @dev Gets the current state of the contract (paused or not).
     * @return True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Gets the contract owner's address.
     * @return The owner's address.
     */
    function owner() external view returns (address) {
        return _owner;
    }
}
```