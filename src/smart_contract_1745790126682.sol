Okay, let's design a smart contract that implements a "Decentralized Task/Compute Marketplace with Verifiable Outputs and Dispute Resolution".

This concept involves users submitting tasks with bounties, other users claiming and executing these tasks off-chain, submitting results, and a verification/dispute system to ensure correctness before payment. It incorporates elements of computation, data verification, incentives, and conflict resolution on-chain. It's complex and not a standard ERC type or a direct copy of popular protocols like MakerDAO, Compound, Uniswap, or basic bounty boards like Gitcoin (which often rely heavily on off-chain components and centralized moderation).

We will aim for over 20 functions covering task lifecycle, user interactions, admin controls, and dispute resolution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedTaskHub
 * @dev A decentralized platform for submitting and executing computational tasks.
 * Users (Requesters) post tasks with bounties. Users (Executors) claim tasks,
 * perform the work off-chain, and submit a result hash. The Requester verifies
 * the result, or a dispute process is initiated. Payment occurs upon successful
 * verification or dispute resolution. Includes admin controls, fees, and timeouts.
 */

/**
 * @notice Outline:
 * 1. State Variables: Owner, protocol fee, counters, mappings for tasks, submissions, disputes.
 * 2. Enums: TaskStatus, SubmissionStatus, DisputeStatus.
 * 3. Structs: Task, TaskSubmission, Dispute.
 * 4. Events: Signalling task creation, claims, submissions, verifications, disputes, etc.
 * 5. Modifiers: Basic access control (onlyOwner, onlyRequester, onlyExecutor).
 * 6. Admin Functions: Setting parameters, withdrawing fees, pausing.
 * 7. Task Lifecycle Functions: Creating, claiming, submitting results, cancelling, extending timeout.
 * 8. Verification & Completion Functions: Requester verification, rejection, triggering auto-completion.
 * 9. Dispute Resolution Functions: Starting dispute, submitting evidence, resolving dispute.
 * 10. View Functions: Retrieving task, submission, dispute details, counts, user-specific lists.
 */

/**
 * @notice Function Summary:
 *
 * Admin Functions:
 * - constructor(): Initializes the contract owner.
 * - setProtocolFeeBps(uint16 _feeBps): Sets the protocol fee percentage in basis points.
 * - setMinBountyAmount(uint256 _minBounty): Sets the minimum bounty amount required per task.
 * - setDefaultTaskTimeout(uint40 _timeout): Sets the default execution timeout for tasks.
 * - setVerificationPeriod(uint40 _period): Sets the time period for requesters to verify a submission.
 * - setDisputePeriod(uint40 _period): Sets the time period for disputes to be initiated/resolved.
 * - withdrawProtocolFees(): Allows the owner to withdraw accumulated protocol fees.
 * - pause(): Pauses core contract functionality (creation, claiming, submission).
 * - unpause(): Unpauses the contract.
 *
 * Task Lifecycle Functions:
 * - createTask(bytes32 _taskDataHash, uint40 _customTimeout): Creates a new task with a bounty (sent via msg.value).
 * - cancelTask(uint256 _taskId): Allows the requester to cancel an open task.
 * - claimTask(uint256 _taskId): Allows an executor to claim an open task.
 * - submitTaskResult(uint256 _taskId, bytes32 _resultHash): Allows the claiming executor to submit a result hash.
 * - extendTaskTimeout(uint256 _taskId, uint40 _extension): Allows the requester to extend the execution timeout.
 * - triggerAutoCompletion(uint256 _taskId): Allows anyone to trigger auto-completion of a submission if the verification period expired.
 *
 * Verification & Dispute Functions:
 * - verifyTaskResult(uint256 _submissionId): Allows the requester to accept a submission and pay the executor.
 * - rejectTaskResult(uint256 _submissionId, bytes32 _rejectionReasonHash): Allows the requester to reject a submission.
 * - startDispute(uint256 _submissionId): Allows the executor (after rejection) or requester (after timeout) to start a dispute. Requires a stake.
 * - submitDisputeEvidenceHash(uint256 _disputeId, bytes32 _evidenceHash): Allows parties in a dispute to submit evidence references.
 * - resolveDispute(uint256 _disputeId, bool _requesterWins): Allows the owner (as arbitrator) to resolve a dispute.
 *
 * View Functions:
 * - getTask(uint256 _taskId): Returns details of a specific task.
 * - getTaskSubmission(uint256 _submissionId): Returns details of a specific submission.
 * - getDispute(uint256 _disputeId): Returns details of a specific dispute.
 * - getTaskCount(): Returns the total number of tasks created.
 * - getSubmissionCount(): Returns the total number of submissions.
 * - getDisputeCount(): Returns the total number of disputes.
 * - getTasksByRequester(address _requester): Returns a list of task IDs created by a specific requester.
 * - getClaimedTaskIdByExecutor(address _executor): Returns the task ID claimed by a specific executor (if any).
 * - getSubmissionsForTask(uint256 _taskId): Returns a list of submission IDs for a specific task.
 * - getSubmissionStatus(uint256 _submissionId): Returns the status of a specific submission.
 * - getTaskStatus(uint256 _taskId): Returns the status of a specific task.
 * - getDisputeStatus(uint256 _disputeId): Returns the status of a specific dispute.
 */

contract DecentralizedTaskHub {
    address payable public owner; // Owner for admin functions and fee withdrawal

    // Protocol Parameters
    uint16 public protocolFeeBps; // Fee in Basis Points (e.g., 500 for 5%)
    uint256 public minBountyAmount; // Minimum ETH required per task
    uint40 public defaultTaskTimeout; // Default time in seconds for task execution
    uint40 public verificationPeriod; // Time in seconds for requester to verify/reject
    uint40 public disputePeriod; // Time in seconds for dispute resolution

    // Counters for unique IDs
    uint256 private taskIdCounter;
    uint256 private submissionIdCounter;
    uint256 private disputeIdCounter;

    // Mappings for data storage
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => TaskSubmission) public submissions;
    mapping(uint256 => Dispute) public disputes;

    // Helper mappings for lookups
    mapping(address => uint256[]) private requesterTasks; // Requester address -> list of task IDs
    mapping(address => uint256) private executorClaimedTask; // Executor address -> claimed task ID (only one active claim allowed)
    mapping(uint256 => uint256[]) private taskSubmissions; // Task ID -> list of submission IDs
    mapping(uint256 => uint256) private submissionToDispute; // Submission ID -> Dispute ID (if any)

    // State for pausing
    bool public paused = false;

    // Accumulated fees
    uint256 public accumulatedFees;

    // --- Enums ---
    enum TaskStatus {
        Open,             // Task is available for claiming
        Claimed,          // Task is claimed by an executor
        SubmissionDue,    // Claimed, but executor time is up, submission expected soon or overdue
        VerificationDue,  // Submission received, requester needs to verify/reject
        Completed,        // Task successfully finished and paid
        Cancelled,        // Task cancelled by requester before claim
        Disputed          // Submission result is under dispute
    }

    enum SubmissionStatus {
        PendingVerification, // Submission received, awaiting requester action
        Accepted,            // Requester accepted the result
        Rejected,            // Requester rejected the result
        Disputed             // Submission is currently under dispute
    }

    enum DisputeStatus {
        Open,     // Dispute is active
        Resolved  // Dispute has been resolved
    }

    // --- Structs ---
    struct Task {
        uint256 id;
        address payable requester; // Address of the task creator
        uint256 bounty;          // ETH bounty for the task (includes potential fee deduction)
        bytes32 taskDataHash;    // Hash reference to off-chain task description/input data (e.g., IPFS hash)
        TaskStatus status;
        address executor;        // Address of the claiming executor
        uint40 claimedAt;         // Timestamp when the task was claimed
        uint40 executionTimeout;  // Timestamp when the executor must submit by
        uint256 submissionId;    // ID of the active submission for this task
        uint40 verificationDeadline; // Timestamp by which requester must verify
    }

    struct TaskSubmission {
        uint256 id;
        uint256 taskId;           // The ID of the task this submission belongs to
        address executor;         // The executor who submitted the result
        bytes32 resultHash;       // Hash reference to off-chain task result (e.g., IPFS hash)
        SubmissionStatus status;
        uint40 submittedAt;       // Timestamp when the result was submitted
        bytes32 rejectionReasonHash; // Optional hash reference for rejection reason
    }

    struct Dispute {
        uint256 id;
        uint256 taskId;
        uint256 submissionId;
        address initiator;         // Address that started the dispute
        DisputeStatus status;
        address partyA;            // Requester
        address partyB;            // Executor
        bytes32 evidenceHashA;     // Optional hash reference to evidence from Party A
        bytes32 evidenceHashB;     // Optional hash reference to evidence from Party B
        uint40 initiatedAt;        // Timestamp when dispute started
        uint40 resolutionDeadline; // Timestamp by which dispute must be resolved
        bool requesterWins;        // Resolution outcome: true if requester wins, false if executor wins
    }

    // --- Events ---
    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 bounty, bytes32 taskDataHash);
    event TaskCancelled(uint256 indexed taskId, address indexed requester);
    event TaskClaimed(uint256 indexed taskId, address indexed executor, uint40 executionTimeout);
    event TaskExecutionTimeoutExtended(uint256 indexed taskId, uint40 newTimeout);
    event TaskSubmissionReceived(uint256 indexed submissionId, uint256 indexed taskId, address indexed executor, bytes32 resultHash);
    event TaskSubmissionAccepted(uint256 indexed submissionId, uint256 indexed taskId, address indexed requester, address indexed executor);
    event TaskSubmissionRejected(uint256 indexed submissionId, uint256 indexed taskId, address indexed requester, bytes32 rejectionReasonHash);
    event TaskCompleted(uint256 indexed taskId, address indexed requester, address indexed executor, uint256 paidAmount);
    event TaskAutoCompleted(uint256 indexed submissionId, uint256 indexed taskId, address indexed executor);
    event DisputeStarted(uint256 indexed disputeId, uint256 indexed submissionId, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed party, bytes32 evidenceHash);
    event DisputeResolved(uint256 indexed disputeId, bool requesterWins, address indexed resolvedBy);
    event ProtocolFeeSet(uint16 feeBps);
    event MinBountySet(uint256 minBounty);
    event DefaultTaskTimeoutSet(uint40 timeout);
    event VerificationPeriodSet(uint40 period);
    event DisputePeriodSet(uint40 period);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyTaskRequester(uint256 _taskId) {
        require(tasks[_taskId].requester == msg.sender, "Only task requester can call this function");
        _;
    }

    modifier onlyTaskExecutor(uint256 _taskId) {
        require(tasks[_taskId].executor == msg.sender, "Only task executor can call this function");
        _;
    }

     modifier onlySubmissionExecutor(uint256 _submissionId) {
        require(submissions[_submissionId].executor == msg.sender, "Only submission executor can call this function");
        _;
    }

     modifier onlySubmissionRequester(uint256 _submissionId) {
        uint256 taskId = submissions[_submissionId].taskId;
        require(tasks[taskId].requester == msg.sender, "Only task requester can call this function");
        _;
    }

    modifier onlyDisputeParticipant(uint256 _disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(msg.sender == dispute.partyA || msg.sender == dispute.partyB, "Only dispute participants can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    // --- Constructor ---
    constructor() payable {
        owner = payable(msg.sender);
        protocolFeeBps = 500; // 5% default fee
        minBountyAmount = 0.01 ether; // Example minimum bounty
        defaultTaskTimeout = 1 days; // Default 1 day for execution
        verificationPeriod = 3 days; // Default 3 days for verification
        disputePeriod = 7 days; // Default 7 days for dispute resolution
    }

    // --- Admin Functions ---
    function setProtocolFeeBps(uint16 _feeBps) external onlyOwner {
        require(_feeBps <= 10000, "Fee cannot exceed 10000 basis points (100%)");
        protocolFeeBps = _feeBps;
        emit ProtocolFeeSet(_feeBps);
    }

    function setMinBountyAmount(uint256 _minBounty) external onlyOwner {
        minBountyAmount = _minBounty;
        emit MinBountySet(_minBounty);
    }

    function setDefaultTaskTimeout(uint40 _timeout) external onlyOwner {
        require(_timeout > 0, "Timeout must be positive");
        defaultTaskTimeout = _timeout;
        emit DefaultTaskTimeoutSet(_timeout);
    }

    function setVerificationPeriod(uint40 _period) external onlyOwner {
        require(_period > 0, "Period must be positive");
        verificationPeriod = _period;
        emit VerificationPeriodSet(_period);
    }

    function setDisputePeriod(uint40 _period) external onlyOwner {
        require(_period > 0, "Period must be positive");
        disputePeriod = _period;
        emit DisputePeriodSet(_period);
    }

    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to withdraw");
        accumulatedFees = 0;

        // Use call for safer withdrawal
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(owner, amount);
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Task Lifecycle Functions ---

    /**
     * @dev Creates a new task. Requires sending ETH equal to the bounty amount.
     * The protocol fee is calculated and deducted from the bounty received.
     * The actual bounty stored is the amount sent minus the fee.
     * @param _taskDataHash Hash reference to the off-chain task description/input data.
     * @param _customTimeout Optional custom timeout for execution (0 uses default).
     */
    function createTask(bytes32 _taskDataHash, uint40 _customTimeout) external payable whenNotPaused returns (uint256) {
        require(msg.value >= minBountyAmount, "Bounty amount is below minimum");
        require(msg.value > 0, "Bounty must be greater than zero");
        require(_taskDataHash != bytes32(0), "Task data hash cannot be empty");

        uint256 bountyAmount = msg.value;
        uint256 feeAmount = (bountyAmount * protocolFeeBps) / 10000;
        uint256 netBounty = bountyAmount - feeAmount;

        accumulatedFees += feeAmount;

        uint256 newTaskId = ++taskIdCounter;
        uint40 executionTimeout = (_customTimeout > 0 ? _customTimeout : defaultTaskTimeout);

        tasks[newTaskId] = Task({
            id: newTaskId,
            requester: payable(msg.sender),
            bounty: netBounty, // Storing net bounty after fee
            taskDataHash: _taskDataHash,
            status: TaskStatus.Open,
            executor: address(0),
            claimedAt: 0,
            executionTimeout: uint40(block.timestamp) + executionTimeout,
            submissionId: 0,
            verificationDeadline: 0
        });

        requesterTasks[msg.sender].push(newTaskId);

        emit TaskCreated(newTaskId, msg.sender, netBounty, _taskDataHash); // Emit net bounty
        return newTaskId;
    }

    /**
     * @dev Allows the requester to cancel an open task.
     * The task must be in Open status. The full bounty is refunded.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external onlyTaskRequester(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "Task must be open to cancel");

        task.status = TaskStatus.Cancelled;

        // Refund the full amount including the fee portion (as no work was done)
        uint256 feePaid = (task.bounty * protocolFeeBps) / (10000 - protocolFeeBps); // Calculate original fee based on net bounty
        uint256 refundAmount = task.bounty + feePaid;

        // Deduct refunded fee from accumulated fees
        accumulatedFees -= feePaid;

        (bool success, ) = payable(task.requester).call{value: refundAmount}("");
        require(success, "Bounty refund failed");

        emit TaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Allows an executor to claim an open task.
     * The task must be in Open status and the executor must not have another task claimed.
     * @param _taskId The ID of the task to claim.
     */
    function claimTask(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "Task is not open for claiming");
        require(executorClaimedTask[msg.sender] == 0, "Executor already has a claimed task");
        require(task.requester != msg.sender, "Requester cannot claim their own task");

        task.status = TaskStatus.Claimed;
        task.executor = msg.sender;
        task.claimedAt = uint40(block.timestamp);
        task.executionTimeout = uint40(block.timestamp) + (task.executionTimeout - uint40(task.claimedAt)); // Update deadline based on current time

        executorClaimedTask[msg.sender] = _taskId;

        emit TaskClaimed(_taskId, msg.sender, task.executionTimeout);
    }

    /**
     * @dev Allows the claiming executor to submit a result hash for their claimed task.
     * The task must be in Claimed or SubmissionDue status and within the timeout.
     * @param _taskId The ID of the task.
     * @param _resultHash Hash reference to the off-chain task result.
     */
    function submitTaskResult(uint256 _taskId, bytes32 _resultHash) external onlyTaskExecutor(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Claimed || task.status == TaskStatus.SubmissionDue, "Task is not in a state for submission");
        require(block.timestamp <= task.executionTimeout, "Execution timeout expired");
        require(_resultHash != bytes32(0), "Result hash cannot be empty");

        uint256 newSubmissionId = ++submissionIdCounter;

        submissions[newSubmissionId] = TaskSubmission({
            id: newSubmissionId,
            taskId: _taskId,
            executor: msg.sender,
            resultHash: _resultHash,
            status: SubmissionStatus.PendingVerification,
            submittedAt: uint40(block.timestamp),
            rejectionReasonHash: bytes32(0)
        });

        task.status = TaskStatus.VerificationDue;
        task.submissionId = newSubmissionId;
        task.verificationDeadline = uint40(block.timestamp) + verificationPeriod;
        taskSubmissions[_taskId].push(newSubmissionId);

        // Clear the executor's active claim slot
        executorClaimedTask[msg.sender] = 0;

        emit TaskSubmissionReceived(newSubmissionId, _taskId, msg.sender, _resultHash);
    }

    /**
     * @dev Allows the requester to extend the execution timeout for their claimed task.
     * Can only be called when the task is in Claimed status.
     * @param _taskId The ID of the task.
     * @param _extension Amount of time in seconds to add to the current deadline.
     */
    function extendTaskTimeout(uint256 _taskId, uint40 _extension) external onlyTaskRequester(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Claimed, "Task must be claimed to extend timeout");
        require(_extension > 0, "Extension must be positive");

        task.executionTimeout += _extension;
        emit TaskExecutionTimeoutExtended(_taskId, task.executionTimeout);
    }

    /**
     * @dev Allows anyone to trigger the auto-completion of a submission
     * if the verification period has passed without requester action.
     * @param _submissionId The ID of the submission to check.
     */
    function triggerAutoCompletion(uint256 _submissionId) external {
        TaskSubmission storage submission = submissions[_submissionId];
        require(submission.status == SubmissionStatus.PendingVerification, "Submission is not pending verification");

        Task storage task = tasks[submission.taskId];
        require(task.status == TaskStatus.VerificationDue, "Task is not in verification state");
        require(block.timestamp > task.verificationDeadline, "Verification period has not expired");

        // Automatically accept the submission
        submission.status = SubmissionStatus.Accepted;
        task.status = TaskStatus.Completed;

        // Pay the executor
        uint256 amountToPay = task.bounty;
        (bool success, ) = payable(submission.executor).call{value: amountToPay}("");
        require(success, "Payment to executor failed");

        emit TaskAutoCompleted(_submissionId, submission.taskId, submission.executor);
        emit TaskCompleted(submission.taskId, task.requester, submission.executor, amountToPay);
    }


    // --- Verification & Dispute Functions ---

    /**
     * @dev Allows the task requester to accept a submission.
     * The submission must be in PendingVerification status and within the verification period.
     * This transfers the bounty to the executor.
     * @param _submissionId The ID of the submission to accept.
     */
    function verifyTaskResult(uint256 _submissionId) external onlySubmissionRequester(_submissionId) whenNotPaused {
        TaskSubmission storage submission = submissions[_submissionId];
        require(submission.status == SubmissionStatus.PendingVerification, "Submission is not pending verification");

        Task storage task = tasks[submission.taskId];
        require(task.status == TaskStatus.VerificationDue, "Task is not in verification state");
        require(block.timestamp <= task.verificationDeadline, "Verification period expired (use triggerAutoCompletion)");

        submission.status = SubmissionStatus.Accepted;
        task.status = TaskStatus.Completed;

        // Pay the executor the net bounty
        uint256 amountToPay = task.bounty;
        (bool success, ) = payable(submission.executor).call{value: amountToPay}("");
        require(success, "Payment to executor failed");

        emit TaskSubmissionAccepted(_submissionId, submission.taskId, msg.sender, submission.executor);
        emit TaskCompleted(submission.taskId, task.requester, submission.executor, amountToPay);
    }

    /**
     * @dev Allows the task requester to reject a submission.
     * The submission must be in PendingVerification status and within the verification period.
     * The executor can then start a dispute.
     * @param _submissionId The ID of the submission to reject.
     * @param _rejectionReasonHash Optional hash reference for the reason.
     */
    function rejectTaskResult(uint256 _submissionId, bytes32 _rejectionReasonHash) external onlySubmissionRequester(_submissionId) whenNotPaused {
         TaskSubmission storage submission = submissions[_submissionId];
        require(submission.status == SubmissionStatus.PendingVerification, "Submission is not pending verification");

        Task storage task = tasks[submission.taskId];
        require(task.status == TaskStatus.VerificationDue, "Task is not in verification state");
        require(block.timestamp <= task.verificationDeadline, "Verification period expired (use triggerAutoCompletion)");

        submission.status = SubmissionStatus.Rejected;
        submission.rejectionReasonHash = _rejectionReasonHash;
        task.status = TaskStatus.Disputed; // Task moves to disputed state implicitly, dispute needs to be initiated

        emit TaskSubmissionRejected(_submissionId, submission.taskId, msg.sender, _rejectionReasonHash);
    }

    /**
     * @dev Allows the executor (after rejection) or requester (if auto-completion window missed)
     * to start a dispute for a rejected or overdue submission.
     * Requires a small stake to prevent spamming disputes.
     * NOTE: For simplicity in this example, the stake is symbolic (0 ether) and the owner is the arbitrator.
     * A real system would require a significant stake and a more complex arbitration mechanism (e.g., Kleros, Aragon Court, DAO vote).
     * @param _submissionId The ID of the submission to dispute.
     */
    function startDispute(uint256 _submissionId) external payable whenNotPaused returns (uint256) {
        TaskSubmission storage submission = submissions[_submissionId];
        require(submission.status == SubmissionStatus.Rejected ||
                (submission.status == SubmissionStatus.PendingVerification && block.timestamp > tasks[submission.taskId].verificationDeadline),
               "Submission must be rejected or verification period expired to dispute");
        require(submissionToDispute[_submissionId] == 0, "Dispute already exists for this submission");

        Task storage task = tasks[submission.taskId];
        require(task.status != TaskStatus.Disputed, "Task is already disputed"); // Check on task status too

        // Determine initiator and validity
        address initiator = msg.sender;
        bool isValidInitiator = false;

        if (submission.status == SubmissionStatus.Rejected && initiator == submission.executor) {
            isValidInitiator = true; // Executor disputes rejection
        } else if (submission.status == SubmissionStatus.PendingVerification && block.timestamp > task.verificationDeadline && initiator == task.requester) {
            // Requester disputes auto-completion (if they missed verification window) - less common flow, maybe simplify?
            // Let's simplify: Only executor can start dispute after rejection. Requesters rely on the auto-completion failure implicitly.
            // If the verification window passes, the executor can call triggerAutoCompletion. If that fails, or is disputed by the requester, it's complex.
            // Let's refine: Executor disputes Rejection. Requester disputes Timeout (if triggerAutoCompletion fails or executor doesn't trigger it).
            // Re-evaluating: The prompt is for >20 functions, not a perfect dispute system. Let's keep it simpler: Only executor disputes rejection. Requester *cannot* dispute if they missed the window, they implicitly accept auto-completion or loss of bounty if auto-completion fails. Executor disputing rejection is the primary flow.
             require(initiator == submission.executor, "Only the executor can dispute a rejected submission");
             isValidInitiator = true; // Executor disputes rejection

        } else {
             revert("Invalid initiator for dispute");
        }
        require(isValidInitiator, "Invalid initiator for dispute"); // Should be covered by above checks, but good final guard.

        // NOTE: Implement a staking requirement here for real applications
        // require(msg.value >= DISPUTE_STAKE_AMOUNT, "Insufficient dispute stake");

        uint256 newDisputeId = ++disputeIdCounter;

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            taskId: submission.taskId,
            submissionId: _submissionId,
            initiator: initiator,
            status: DisputeStatus.Open,
            partyA: task.requester, // Requester is Party A
            partyB: submission.executor, // Executor is Party B
            evidenceHashA: bytes32(0),
            evidenceHashB: bytes32(0),
            initiatedAt: uint40(block.timestamp),
            resolutionDeadline: uint40(block.timestamp) + disputePeriod,
            requesterWins: false // Default, set on resolution
        });

        submissionToDispute[_submissionId] = newDisputeId;
        task.status = TaskStatus.Disputed;
        submission.status = SubmissionStatus.Disputed;

        emit DisputeStarted(newDisputeId, _submissionId, initiator);
        return newDisputeId;
    }

    /**
     * @dev Allows parties in an open dispute to submit a hash reference to their evidence.
     * Can be called multiple times, but only the last submission per party is stored.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceHash Hash reference to the evidence.
     */
    function submitDisputeEvidenceHash(uint256 _disputeId, bytes32 _evidenceHash) external onlyDisputeParticipant(_disputeId) whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");
         require(block.timestamp <= dispute.resolutionDeadline, "Dispute resolution period expired");

        if (msg.sender == dispute.partyA) {
            dispute.evidenceHashA = _evidenceHash;
        } else if (msg.sender == dispute.partyB) {
            dispute.evidenceHashB = _evidenceHash;
        } // else, should be caught by onlyDisputeParticipant

        emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceHash);
    }

    /**
     * @dev Allows the owner (acting as a simple arbitrator) to resolve an open dispute.
     * In a real system, this would be a more complex mechanism (DAO vote, Schelling point game, etc.).
     * Distributes the bounty based on the outcome.
     * NOTE: Dispute stake handling would be done here in a real system.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _requesterWins True if the requester's position is upheld, false if the executor's is.
     */
    function resolveDispute(uint256 _disputeId, bool _requesterWins) external onlyOwner whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");
        // Allow owner to resolve even after deadline? Or require resolution before deadline?
        // Let's require resolution before the deadline in this simple model.
         require(block.timestamp <= dispute.resolutionDeadline, "Dispute resolution period expired");


        dispute.status = DisputeStatus.Resolved;
        dispute.requesterWins = _requesterWins;
        dispute.resolvedBy = msg.sender;

        Task storage task = tasks[dispute.taskId];
        TaskSubmission storage submission = submissions[dispute.submissionId];

        // Update task and submission status based on resolution
        if (_requesterWins) {
            // Requester wins: Submission rejected, task bounty stays with requester (or is lost if stake involved)
            task.status = TaskStatus.Completed; // Task is completed (unsuccessfully for executor)
            submission.status = SubmissionStatus.Rejected; // Final status is Rejected
             // In a real system, handle dispute stakes here. Bounty stays in contract or is returned to requester.
             // For simplicity, let's assume bounty is 'burned' or stays with the protocol if requester wins a dispute
             // after funds left the requester's wallet in createTask. Or refund if possible.
             // Given funds were sent in createTask, they are in the contract.
             // Option A: If requester wins, refund bounty to requester (less fee). Executor stake lost.
             // Option B: If requester wins, bounty goes to protocol/burn. Executor stake lost.
             // Let's go with Option A: Refund net bounty to requester. Fee is still kept.
             (bool success, ) = payable(task.requester).call{value: task.bounty}("");
             require(success, "Bounty refund to requester failed after dispute");
             emit TaskCompleted(task.id, task.requester, address(0), 0); // Indicate task finished, no executor payment
        } else {
            // Executor wins: Submission accepted, executor gets bounty
            task.status = TaskStatus.Completed; // Task is completed successfully
            submission.status = SubmissionStatus.Accepted; // Final status is Accepted

            uint256 amountToPay = task.bounty;
            (bool success, ) = payable(dispute.partyB).call{value: amountToPay}("");
            require(success, "Payment to executor failed after dispute");
             emit TaskCompleted(task.id, task.requester, task.executor, amountToPay); // Indicate task finished, executor paid
        }

        emit DisputeResolved(_disputeId, _requesterWins, msg.sender);
    }


    // --- View Functions ---

    function getTask(uint256 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }

    function getTaskSubmission(uint256 _submissionId) external view returns (TaskSubmission memory) {
        return submissions[_submissionId];
    }

    function getDispute(uint256 _disputeId) external view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    function getTaskCount() external view returns (uint256) {
        return taskIdCounter;
    }

    function getSubmissionCount() external view returns (uint256) {
        return submissionIdCounter;
    }

    function getDisputeCount() external view returns (uint256) {
        return disputeIdCounter;
    }

    function getTasksByRequester(address _requester) external view returns (uint256[] memory) {
        return requesterTasks[_requester];
    }

    function getClaimedTaskIdByExecutor(address _executor) external view returns (uint256) {
         // Note: This assumes an executor can only claim one task at a time.
         // If multiple claims were allowed, this would need to return an array.
        return executorClaimedTask[_executor];
    }

    function getSubmissionsForTask(uint256 _taskId) external view returns (uint256[] memory) {
        return taskSubmissions[_taskId];
    }

    function getSubmissionStatus(uint256 _submissionId) external view returns (SubmissionStatus) {
        return submissions[_submissionId].status;
    }

    function getTaskStatus(uint256 _taskId) external view returns (TaskStatus) {
        return tasks[_taskId].status;
    }

    function getDisputeStatus(uint256 _disputeId) external view returns (DisputeStatus) {
        return disputes[_disputeId].status;
    }

    // Fallback function to prevent accidental ETH sends without calling a function
    receive() external payable {
        revert("Direct ETH deposits not allowed, use createTask");
    }

     fallback() external payable {
        revert("Call to non-existent function or direct ETH deposit");
    }
}
```

---

**Explanation of Advanced/Interesting Concepts:**

1.  **Decentralized Task Execution Lifecycle:** Implements a full flow for tasks from creation, claiming, execution (off-chain, represented by hash), submission, verification, and completion/dispute.
2.  **Off-chain Compute, On-chain Verification:** The contract doesn't *do* the computation, but manages the *agreement* and *verification* based on hash references (e.g., IPFS CIDs) for task inputs and results. This is a common pattern for offloading heavy work while maintaining trust/verifiability on-chain.
3.  **Role-Based Access Control:** Uses simple modifiers (`onlyOwner`, `onlyTaskRequester`, `onlyTaskExecutor`, etc.) to restrict function calls based on the user's role in a specific task or the protocol.
4.  **State Machine:** The `TaskStatus`, `SubmissionStatus`, and `DisputeStatus` enums and the `require` checks in functions enforce a clear state machine for tasks, submissions, and disputes, preventing invalid transitions (e.g., claiming a claimed task, verifying a rejected submission).
5.  **Timed Processes:** Utilizes `block.timestamp` to implement execution timeouts, verification periods, and dispute resolution deadlines. Includes a `triggerAutoCompletion` function allowing anyone to push the state forward if a deadline is missed by the requester.
6.  **Protocol Fees:** Includes a simple mechanism for calculating and collecting a protocol fee from the task bounty, which can be withdrawn by the owner.
7.  **Dispute Resolution System:** Provides a basic framework for disputing results. While simplified (owner as arbitrator, symbolic stake), it outlines the necessary state transitions, evidence submission (via hash), and outcome-based fund distribution. A real-world system would replace the `onlyOwner` for `resolveDispute` with a more decentralized mechanism.
8.  **Non-Standard ERC:** This contract defines a custom protocol logic rather than being a standard token (ERC-20, ERC-721) or a direct wrapper around one.
9.  **Use of Hashes for Off-chain Data:** Relies on `bytes32` hashes (`taskDataHash`, `resultHash`, `rejectionReasonHash`, `evidenceHash`) to reference potentially large off-chain data (like task descriptions, input files, results, evidence logs) stored on decentralized storage like IPFS or Arweave. This keeps transaction costs low compared to storing raw data on-chain.
10. **Payable and Fund Management:** Handles ETH payments (`payable`), fee calculation, fund transfers (`call` for safety), and managing balances for bounties and fees.
11. **Pausable:** Includes basic pause functionality for emergency situations, restricting core actions (`createTask`, `claimTask`, `submitTaskResult`, dispute functions).

This contract serves as a foundation for a complex decentralized compute marketplace, incorporating various advanced concepts beyond typical token contracts or simple dApps.