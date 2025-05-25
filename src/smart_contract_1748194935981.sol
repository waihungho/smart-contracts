Okay, let's design a smart contract that combines several advanced concepts: a Decentralized, Programmable Task Protocol with Reputation, Escrow, Milestones, Delegation, and a basic Dispute Resolution system.

This is *not* a standard token, NFT, or simple DAO. It focuses on coordinating work, managing payments based on verifiable milestones, and building on-chain reputation.

**Core Concepts:**

1.  **Programmable Tasks:** Tasks defined with multiple milestones, each with its own reward and deadline.
2.  **Escrow:** Funds (ETH) are held in escrow within the contract and released milestone by milestone.
3.  **Reputation System:** Users (creators and workers) earn or lose reputation based on task outcomes (completion, abandonment, disputes).
4.  **Delegation:** Users can delegate task management actions (reviewing, accepting, raising disputes) to another address.
5.  **Dispute Resolution:** A basic on-chain mechanism (controlled by owner or a designated entity in a more advanced version) to resolve disagreements.
6.  **State Machine:** Tasks transition through various states (Open, Assigned, InProgress, AwaitingReview, Completed, Disputed, Cancelled, Abandoned).

Let's aim for 20+ functions by providing granular actions for task lifecycle management, delegation, querying, etc.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- CONTRACT OUTLINE ---
// 1. State Variables: Stores task data, user reputation, counters, delegation map.
// 2. Enums: Define possible states for tasks, milestones, and disputes.
// 3. Structs: Define data structures for Milestones, Tasks, and Disputes.
// 4. Events: Announce key actions and state changes.
// 5. Errors: Custom errors for clearer failure reasons.
// 6. Modifiers: Simplify access control and state checks.
// 7. Core Logic: Functions for creating, managing, and completing tasks.
// 8. Escrow Logic: Handling fund deposits and releases.
// 9. Reputation Logic: Updating user reputation scores.
// 10. Delegation Logic: Setting and managing delegates.
// 11. Dispute Resolution Logic: Handling disputes (simplified).
// 12. View Functions: For querying contract state.

// --- FUNCTION SUMMARY ---
// Admin/Setup:
// 1. constructor(): Initializes the contract owner and reputation parameters.
// 2. setReputationParameters(): Allows owner to set parameters for reputation calculation.
// 3. updateOwner(): Standard Ownable function to transfer ownership.

// Task Creation & Management:
// 4. createTask(): Allows anyone to propose a task with milestones and deposit bounty.
// 5. cancelTaskCreator(): Creator cancels an unassigned task.
// 6. updateTaskDetails(): Creator updates details before assignment.
// 7. assignTask(): Creator assigns an open task to a worker.

// Worker Interaction:
// 8. applyForTask(): Worker applies for an open task.
// 9. abandonTaskWorker(): Worker abandons an assigned task.
// 10. submitMilestoneCompletion(): Worker submits proof/request for milestone review.

// Milestone Review & Payment:
// 11. reviewMilestoneCompletion(): Creator reviews a submitted milestone. (View function - maybe remove as a separate public call and integrate review within accept/reject). Let's make it a view helper.
// 12. acceptMilestoneCompletion(): Creator accepts a milestone, triggering payment.
// 13. rejectMilestoneCompletion(): Creator rejects a milestone submission, requires reason.

// Dispute Resolution:
// 14. raiseDispute(): Participant raises a dispute over a task milestone/state.
// 15. submitDisputeEvidence(): Participants submit evidence for a dispute.
// 16. resolveDispute(): Owner/Resolver resolves a dispute (simplified).

// Reputation:
// 17. getReputation(): Retrieves a user's current reputation score.

// Delegation:
// 18. setDelegate(): Allows a user to set another address as their delegate.
// 19. clearDelegate(): Removes a user's delegate.
// 20. getDelegate(): Retrieves the delegate for a user.

// Querying/View Functions:
// 21. getTask(): Retrieve details of a specific task.
// 22. getUserTasks(): Retrieve list of task IDs associated with a user (as creator or worker).
// 23. getTasksByState(): Retrieve list of task IDs in a specific state (inefficient for large lists, but meets function count).
// 24. getDispute(): Retrieve details of a specific dispute.
// 25. getReputationParameters(): Retrieve current reputation parameters.

// Note: This contract requires ETH payments. For ERC20, an interface and slight modifications for token transfers would be needed.
// Security Note: The dispute resolution is simplified (owner-controlled). A real system would need a decentralized oracle or committee.
// Gas Note: Iterating through task IDs in `getTasksByState` is inefficient for many tasks.

contract EthosWork is Ownable, ReentrancyGuard {

    // --- ENUMS ---
    enum TaskState {
        Open,             // Task is available for workers to apply
        Assigned,         // Task has a worker assigned
        InProgress,       // Worker is actively working on a milestone
        AwaitingReview,   // Worker submitted milestone, waiting for creator review
        Completed,        // All milestones accepted, task finished successfully
        Disputed,         // Task is under dispute
        Cancelled,        // Creator cancelled the task (before assigned)
        Abandoned         // Worker abandoned the task (after assigned)
    }

    enum MilestoneState {
        Pending,        // Waiting for worker to submit
        Submitted,      // Worker submitted, waiting for review
        Accepted,       // Creator accepted submission
        Rejected,       // Creator rejected submission
        Disputed        // Milestone part of a disputed task
    }

     enum DisputeState {
        Open,           // Dispute initiated
        EvidencePeriod, // Waiting for evidence submission
        Reviewing,      // Resolver is reviewing evidence
        Resolved        // Dispute concluded
    }

    // --- STRUCTS ---
    struct Milestone {
        bytes32 descriptionHash; // Hash of the milestone description (e.g., IPFS)
        uint256 rewardAmount;    // Amount paid upon completion of this milestone (in wei or token units)
        uint64 deadline;         // Unix timestamp deadline for this milestone
        MilestoneState state;    // Current state of the milestone
        bytes32 submissionHash;  // Hash of the worker's submission for this milestone
    }

    struct Task {
        uint256 id;
        address payable creator; // Task creator, payable to receive refunds
        address payable worker;  // Assigned worker, payable to receive rewards
        bytes32 titleHash;       // Hash of the task title
        bytes32 descriptionHash; // Hash of the full task description
        uint256 totalBounty;     // Total bounty amount for the task (sum of all milestone rewards)
        Milestone[] milestones;  // Array of milestones
        uint256 currentMilestoneIndex; // Index of the current milestone the worker is on
        TaskState state;         // Current state of the task
        uint64 deadline;         // Overall task deadline
        address[] applicants;    // List of addresses who applied for the task (only in Open state)
        uint256 creatorStake;    // Stake required from creator
        uint256 workerStake;     // Stake required from worker
    }

    struct Dispute {
        uint256 id;
        uint256 taskId;
        address disputer;       // Address that initiated the dispute
        bytes32 reasonHash;     // Hash of the reason for dispute
        bytes32 creatorEvidenceHash; // Hash of creator's evidence
        bytes32 workerEvidenceHash;  // Hash of worker's evidence
        uint64 evidenceDeadline; // Deadline for submitting evidence
        DisputeState state;     // State of the dispute resolution process
        int256 resolutionOutcome; // -1: Worker wins, 0: Split/Other, 1: Creator wins
    }

    // --- STATE VARIABLES ---
    uint256 private _taskCounter;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userCreatedTasks;
    mapping(address => uint256[]) public userAssignedTasks; // Includes Abandoned/Completed/Disputed assigned tasks

    uint256 private _disputeCounter;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => uint256) public taskDispute; // Mapping from taskId to disputeId (0 if no dispute)

    mapping(address => uint256) public reputation; // Simple reputation score (can be positive or negative)

    mapping(address => address) public delegates; // User -> Delegate address

    // Reputation Parameters
    int256 public reputationParams_completion;     // Points awarded for task completion
    int256 public reputationParams_abandonment;    // Points deducted for abandonment
    int256 public reputationParams_rejectionPenalty; // Points deducted for milestone rejection
    int256 public reputationParams_disputeWin;     // Points awarded for winning a dispute
    int256 public reputationParams_disputeLoss;    // Points deducted for losing a dispute

    // Stake Requirements (can be 0 if no stake needed)
    uint256 public requiredCreatorStake = 0; // Default stake required from creator
    uint256 public requiredWorkerStake = 0;  // Default stake required from worker

    // --- EVENTS ---
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 totalBounty, uint64 deadline);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event TaskUpdated(uint256 indexed taskId);
    event TaskAssigned(uint256 indexed taskId, address indexed worker);
    event TaskAbandoned(uint256 indexed taskId, address indexed worker);
    event MilestoneSubmitted(uint256 indexed taskId, uint256 indexed milestoneIndex, bytes32 submissionHash);
    event MilestoneAccepted(uint256 indexed taskId, uint256 indexed milestoneIndex, uint256 payoutAmount);
    event MilestoneRejected(uint256 indexed taskId, uint256 indexed milestoneIndex, bytes32 reasonHash);
    event TaskCompleted(uint256 indexed taskId);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed taskId, address indexed disputer);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed participant, bytes32 evidenceHash);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed taskId, int256 resolutionOutcome);
    event ReputationUpdated(address indexed user, int256 newReputation, int256 change);
    event DelegateSet(address indexed user, address indexed delegate);
    event DelegateCleared(address indexed user, address indexed oldDelegate);
    event FundsReturned(address indexed recipient, uint256 amount);
    event StakeReleased(address indexed recipient, uint256 amount);
    event StakeSlashed(address indexed slashee, uint256 amount);

    // --- ERRORS ---
    error TaskNotFound(uint256 taskId);
    error Unauthorized(address caller);
    error InvalidTaskState(uint256 taskId, TaskState currentState, TaskState[] expectedStates);
    error InvalidMilestoneIndex(uint256 taskId, uint256 milestoneIndex, uint256 expectedIndex);
    error InvalidMilestoneState(uint256 taskId, uint256 milestoneIndex, MilestoneState currentState, MilestoneState[] expectedStates);
    error NotEnoughFunds(uint256 required, uint256 received);
    error TaskDeadlinePassed(uint256 taskId);
    error MilestoneDeadlinePassed(uint256 taskId, uint256 milestoneIndex);
    error NotTaskCreator(uint256 taskId, address caller);
    error NotTaskWorker(uint256 taskId, address caller);
    error NotTaskParticipant(uint256 taskId, address caller);
    error TaskAlreadyAssigned(uint256 taskId);
    error StakeRequirementNotMet(uint256 required, uint256 sent);
    error DisputeNotFound(uint256 disputeId);
    error InvalidDisputeState(uint256 disputeId, DisputeState currentState, DisputeState[] expectedStates);
    error DisputeAlreadyExists(uint256 taskId);
    error NoDelegateSet(address user);
    error InvalidResolutionOutcome(int256 outcome);
    error CannotUpdateAssignedTask(uint256 taskId);
    error InvalidApplicantsList(uint256 taskId); // e.g., assigning someone not in applicants (if enforcing)

    // --- MODIFIERS ---
    modifier onlyTaskCreator(uint256 _taskId) {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) revert TaskNotFound(_taskId);
        if (task.creator != msg.sender && delegates[msg.sender] != task.creator) revert NotTaskCreator(_taskId, msg.sender);
        _;
    }

    modifier onlyTaskWorker(uint256 _taskId) {
        Task storage task = tasks[_taskId];
         if (task.creator == address(0)) revert TaskNotFound(_taskId);
        if (task.worker == address(0) || (task.worker != msg.sender && delegates[msg.sender] != task.worker)) revert NotTaskWorker(_taskId, msg.sender);
        _;
    }

    modifier onlyTaskParticipant(uint256 _taskId) {
        Task storage task = tasks[_taskId];
         if (task.creator == address(0)) revert TaskNotFound(_taskId);
        if (task.creator != msg.sender && task.worker != msg.sender && delegates[msg.sender] != task.creator && delegates[msg.sender] != task.worker) revert NotTaskParticipant(_taskId, msg.sender);
        _;
    }

    modifier whenTaskState(uint256 _taskId, TaskState _expectedState) {
         Task storage task = tasks[_taskId];
        if (task.creator == address(0)) revert TaskNotFound(_taskId);
        if (task.state != _expectedState) revert InvalidTaskState(_taskId, task.state, new TaskState[]{_expectedState});
        _;
    }

     modifier whenDisputeState(uint256 _disputeId, DisputeState _expectedState) {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.taskId == 0) revert DisputeNotFound(_disputeId); // Using taskId as a check if struct exists
        if (dispute.state != _expectedState) revert InvalidDisputeState(_disputeId, dispute.state, new DisputeState[]{_expectedState});
        _;
    }

    // --- CONSTRUCTOR ---
    constructor() Ownable(msg.sender) {
        // Default reputation parameters (can be updated by owner)
        reputationParams_completion = 10;
        reputationParams_abandonment = -15;
        reputationParams_rejectionPenalty = -5;
        reputationParams_disputeWin = 20;
        reputationParams_disputeLoss = -20;
    }

    // --- ADMIN/SETUP FUNCTIONS ---

    /**
     * @notice Allows the owner to set parameters affecting reputation calculation.
     * @param _completion Points for task completion.
     * @param _abandonment Points deducted for task abandonment.
     * @param _rejectionPenalty Points deducted for milestone rejection.
     * @param _disputeWin Points for winning a dispute.
     * @param _disputeLoss Points for losing a dispute.
     */
    function setReputationParameters(
        int256 _completion,
        int256 _abandonment,
        int256 _rejectionPenalty,
        int256 _disputeWin,
        int256 _disputeLoss
    ) external onlyOwner {
        reputationParams_completion = _completion;
        reputationParams_abandonment = _abandonment;
        rejectionPenalty = _rejectionPenalty;
        reputationParams_disputeWin = _disputeWin;
        reputationParams_disputeLoss = _disputeLoss;
    }

    /**
     * @notice Allows the owner to set the required stake for creators and workers.
     * @param _creatorStake Required ETH stake from the creator.
     * @param _workerStake Required ETH stake from the worker.
     */
    function setStakeRequirement(uint256 _creatorStake, uint256 _workerStake) external onlyOwner {
        requiredCreatorStake = _creatorStake;
        requiredWorkerStake = _workerStake;
    }

     // --- TASK CREATION & MANAGEMENT ---

    /**
     * @notice Creates a new task with milestones and deposits the total bounty + creator stake.
     * @param _titleHash Hash of the task title.
     * @param _descriptionHash Hash of the full task description.
     * @param _milestones Array of milestone structs defining the work breakdown and rewards.
     * @param _overallDeadline Overall deadline for the entire task.
     */
    function createTask(
        bytes32 _titleHash,
        bytes32 _descriptionHash,
        Milestone[] calldata _milestones,
        uint64 _overallDeadline
    ) external payable nonReentrant {
        if (_milestones.length == 0) revert InvalidApplicantsList(0); // Using the error for "empty list"
        if (_overallDeadline <= block.timestamp) revert TaskDeadlinePassed(0); // Use 0 as taskId since it's not created yet

        uint256 totalBounty = 0;
        for (uint i = 0; i < _milestones.length; i++) {
            if (_milestones[i].rewardAmount == 0) revert InvalidMilestoneIndex(0, i, 0); // Bounty must be non-zero
            totalBounty += _milestones[i].rewardAmount;
             if (_milestones[i].deadline <= block.timestamp) revert MilestoneDeadlinePassed(0, i); // Milestone deadline must be in future
             // Initialize milestone state
             _milestones[i].state = MilestoneState.Pending;
             _milestones[i].submissionHash = bytes32(0); // Clear submission hash
        }

        uint256 requiredTotal = totalBounty + requiredCreatorStake;
        if (msg.value < requiredTotal) revert NotEnoughFunds(requiredTotal, msg.value);

        _taskCounter++;
        uint256 taskId = _taskCounter;

        tasks[taskId] = Task({
            id: taskId,
            creator: payable(msg.sender),
            worker: payable(address(0)), // Not assigned yet
            titleHash: _titleHash,
            descriptionHash: _descriptionHash,
            totalBounty: totalBounty,
            milestones: _milestones, // Calldata array copied to storage
            currentMilestoneIndex: 0, // Start at the first milestone
            state: TaskState.Open,
            deadline: _overallDeadline,
            applicants: new address[](0), // Empty applicants list initially
            creatorStake: requiredCreatorStake,
            workerStake: 0 // Worker stake is added upon assignment
        });

        userCreatedTasks[msg.sender].push(taskId);

        // Any excess funds are refunded
        if (msg.value > requiredTotal) {
            uint256 refundAmount = msg.value - requiredTotal;
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
            // Note: A failure here might lock funds. In a production system,
            // safer refund patterns (e.g., pull payments) should be considered.
            require(success, "Refund failed");
             emit FundsReturned(msg.sender, refundAmount);
        }

        emit TaskCreated(taskId, msg.sender, totalBounty, _overallDeadline);
    }

    /**
     * @notice Allows the task creator to cancel an open task.
     * Refunds the full bounty and creator stake.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTaskCreator(uint256 _taskId) external onlyTaskCreator(_taskId) nonReentrant whenTaskState(_taskId, TaskState.Open) {
        Task storage task = tasks[_taskId];

        // Refund total bounty and creator stake
        uint256 refundAmount = task.totalBounty + task.creatorStake;
        task.state = TaskState.Cancelled;

        (bool success, ) = task.creator.call{value: refundAmount}("");
        require(success, "Refund failed");

        emit TaskCancelled(_taskId, task.creator);
        emit FundsReturned(task.creator, refundAmount);
    }

     /**
     * @notice Allows the task creator to update details of an open task.
     * @param _taskId The ID of the task to update.
     * @param _titleHash New hash of the task title.
     * @param _descriptionHash New hash of the full task description.
     * @param _overallDeadline New overall deadline for the task.
     */
    function updateTaskDetails(
        uint256 _taskId,
        bytes32 _titleHash,
        bytes32 _descriptionHash,
        uint64 _overallDeadline
    ) external onlyTaskCreator(_taskId) whenTaskState(_taskId, TaskState.Open) {
        Task storage task = tasks[_taskId];

        if (_overallDeadline <= block.timestamp) revert TaskDeadlinePassed(_taskId);

        task.titleHash = _titleHash;
        task.descriptionHash = _descriptionHash;
        task.deadline = _overallDeadline;

        emit TaskUpdated(_taskId);
    }

    /**
     * @notice Allows a potential worker to apply for an open task.
     * @param _taskId The ID of the task to apply for.
     */
    function applyForTask(uint256 _taskId) external whenTaskState(_taskId, TaskState.Open) {
        Task storage task = tasks[_taskId];

        // Prevent applying multiple times
        for (uint i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == msg.sender) return; // Already applied
        }

        task.applicants.push(msg.sender);
        // No event needed for application, creator can query applicants list
    }


    /**
     * @notice Allows the task creator to assign an open task to a chosen worker.
     * Requires the worker's stake to be sent with the transaction.
     * @param _taskId The ID of the task to assign.
     * @param _worker The address of the worker to assign the task to.
     */
    function assignTask(uint256 _taskId, address payable _worker) external payable nonReentrant onlyTaskCreator(_taskId) whenTaskState(_taskId, TaskState.Open) {
        Task storage task = tasks[_taskId];

        if (_worker == address(0)) revert InvalidApplicantsList(_taskId); // Worker address must be valid
        if (_worker == task.creator) revert InvalidApplicantsList(_taskId); // Cannot assign to creator

        // Check if the worker applied (optional, but good practice)
        // bool workerApplied = false;
        // for(uint i=0; i < task.applicants.length; i++) {
        //     if (task.applicants[i] == _worker) {
        //         workerApplied = true;
        //         break;
        //     }
        // }
        // if (!workerApplied) revert InvalidApplicantsList(_taskId); // Worker must have applied

        if (msg.value < requiredWorkerStake) revert StakeRequirementNotMet(requiredWorkerStake, msg.value);
        if (msg.value > requiredWorkerStake) {
             uint256 refundAmount = msg.value - requiredWorkerStake;
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
             require(success, "Creator stake refund failed during assignment"); // Creator gets excess back
             emit FundsReturned(msg.sender, refundAmount);
        }


        task.worker = _worker;
        task.workerStake = requiredWorkerStake;
        task.state = TaskState.InProgress; // Task starts in progress for the first milestone
        task.applicants = new address[](0); // Clear applicants list after assignment

        userAssignedTasks[_worker].push(_taskId);

        emit TaskAssigned(_taskId, _worker);
    }

     /**
     * @notice Allows the assigned worker to abandon a task.
     * Penalizes the worker by slashing their stake. Creator's stake is refunded. Bounty is returned.
     * @param _taskId The ID of the task to abandon.
     */
    function abandonTaskWorker(uint256 _taskId) external onlyTaskWorker(_taskId) nonReentrant {
        Task storage task = tasks[_taskId];

        // Only allowed in states where worker is active
        TaskState[] memory allowedStates = new TaskState[](3);
        allowedStates[0] = TaskState.Assigned; // Should transition to InProgress right away, but handle defensive
        allowedStates[1] = TaskState.InProgress;
        allowedStates[2] = TaskState.AwaitingReview;

        bool allowed = false;
        for(uint i=0; i < allowedStates.length; i++) {
            if (task.state == allowedStates[i]) {
                allowed = true;
                break;
            }
        }
        if (!allowed) revert InvalidTaskState(_taskId, task.state, allowedStates);

        task.state = TaskState.Abandoned;

        // Slash worker stake (send to creator or burn?) Let's send to creator.
        if (task.workerStake > 0) {
             (bool success, ) = task.creator.call{value: task.workerStake}("");
             // If this fails, worker stake is stuck. Consider pull payments or a separate recovery mechanism.
             require(success, "Slashed worker stake transfer failed");
             emit StakeSlashed(task.worker, task.workerStake);
        }

        // Refund remaining bounty and creator stake to creator
        // The amount of bounty is the total bounty minus any milestones already paid
        uint256 paidBounty = 0;
        for(uint i=0; i < task.currentMilestoneIndex; i++) {
            // Assuming only accepted milestones are paid, and current index means milestones BEFORE it are done
             if (task.milestones[i].state == MilestoneState.Accepted) {
                 paidBounty += task.milestones[i].rewardAmount;
             }
        }
        uint256 remainingBounty = task.totalBounty - paidBounty;
        uint256 refundAmount = remainingBounty + task.creatorStake;

        (bool success, ) = task.creator.call{value: refundAmount}("");
        require(success, "Remaining bounty and creator stake refund failed");
        emit FundsReturned(task.creator, refundAmount);

        _updateReputation(task.worker, reputationParams_abandonment);

        emit TaskAbandoned(_taskId, task.worker);
    }

    // --- MILESTONE REVIEW & PAYMENT ---

    /**
     * @notice Allows the assigned worker to submit completion for the current milestone.
     * @param _taskId The ID of the task.
     * @param _submissionHash Hash of the submission proof (e.g., IPFS hash of completed work).
     */
    function submitMilestoneCompletion(uint256 _taskId, bytes32 _submissionHash) external onlyTaskWorker(_taskId) whenTaskState(_taskId, TaskState.InProgress) {
        Task storage task = tasks[_taskId];
        uint256 currentIdx = task.currentMilestoneIndex;

        if (currentIdx >= task.milestones.length) revert InvalidMilestoneIndex(_taskId, currentIdx, 0); // Should not happen if state logic is correct

        Milestone storage currentMilestone = task.milestones[currentIdx];
        if (currentMilestone.deadline <= block.timestamp) revert MilestoneDeadlinePassed(_taskId, currentIdx);

        currentMilestone.submissionHash = _submissionHash;
        currentMilestone.state = MilestoneState.Submitted;
        task.state = TaskState.AwaitingReview;

        emit MilestoneSubmitted(_taskId, currentIdx, _submissionHash);
    }

    /**
     * @notice Allows the task creator to accept the worker's submission for the current milestone.
     * Triggers payment for the milestone and advances the task state.
     * @param _taskId The ID of the task.
     */
    function acceptMilestoneCompletion(uint256 _taskId) external onlyTaskCreator(_taskId) nonReentrant whenTaskState(_taskId, TaskState.AwaitingReview) {
        Task storage task = tasks[_taskId];
        uint256 currentIdx = task.currentMilestoneIndex;

        if (currentIdx >= task.milestones.length) revert InvalidMilestoneIndex(_taskId, currentIdx, 0);

        Milestone storage currentMilestone = task.milestones[currentIdx];
        currentMilestone.state = MilestoneState.Accepted;

        // Pay the worker for this milestone
        uint256 payoutAmount = currentMilestone.rewardAmount;
        (bool success, ) = task.worker.call{value: payoutAmount}("");
        require(success, "Milestone payment failed");
        emit MilestoneAccepted(_taskId, currentIdx, payoutAmount);

        // Advance to the next milestone or complete the task
        if (currentIdx == task.milestones.length - 1) {
            // Last milestone completed
            task.state = TaskState.Completed;
            _updateReputation(task.worker, reputationParams_completion);
            _updateReputation(task.creator, reputationParams_completion); // Creator also gets points for successful task

            // Release creator and worker stakes
            if (task.creatorStake > 0) {
                (success, ) = task.creator.call{value: task.creatorStake}("");
                 require(success, "Creator stake release failed");
                 emit StakeReleased(task.creator, task.creatorStake);
            }
            if (task.workerStake > 0) {
                (success, ) = task.worker.call{value: task.workerStake}("");
                 require(success, "Worker stake release failed");
                 emit StakeReleased(task.worker, task.workerStake);
            }

            emit TaskCompleted(_taskId);

        } else {
            // More milestones remaining
            task.currentMilestoneIndex++;
            task.state = TaskState.InProgress; // Move to next milestone
        }
    }

    /**
     * @notice Allows the task creator to reject the worker's submission for the current milestone.
     * Task state returns to InProgress, worker needs to resubmit. Affects reputation.
     * @param _taskId The ID of the task.
     * @param _reasonHash Hash of the reason for rejection.
     */
    function rejectMilestoneCompletion(uint256 _taskId, bytes32 _reasonHash) external onlyTaskCreator(_taskId) nonReentrant whenTaskState(_taskId, TaskState.AwaitingReview) {
        Task storage task = tasks[_taskId];
        uint256 currentIdx = task.currentMilestoneIndex;

        if (currentIdx >= task.milestones.length) revert InvalidMilestoneIndex(_taskId, currentIdx, 0);

        Milestone storage currentMilestone = task.milestones[currentIdx];
        currentMilestone.state = MilestoneState.Rejected; // Mark as rejected

        task.state = TaskState.InProgress; // Worker needs to re-submit

        _updateReputation(task.worker, reputationParams_rejectionPenalty); // Penalize worker for rejection

        emit MilestoneRejected(_taskId, currentIdx, _reasonHash);
    }

    // --- DISPUTE RESOLUTION ---

    /**
     * @notice Allows a task participant (creator or worker) to raise a dispute.
     * Only possible in specific states where disagreement might occur.
     * @param _taskId The ID of the task to dispute.
     * @param _reasonHash Hash of the reason for raising the dispute.
     */
    function raiseDispute(uint256 _taskId, bytes32 _reasonHash) external onlyTaskParticipant(_taskId) nonReentrant {
        Task storage task = tasks[_taskId];

        // Allowed states for raising a dispute
        TaskState[] memory allowedStates = new TaskState[](2);
        allowedStates[0] = TaskState.InProgress;   // e.g., worker missed deadline, creator wants to cancel
        allowedStates[1] = TaskState.AwaitingReview; // e.g., creator rejected unfairly, worker disagrees

         bool allowed = false;
        for(uint i=0; i < allowedStates.length; i++) {
            if (task.state == allowedStates[i]) {
                allowed = true;
                break;
            }
        }
        if (!allowed) revert InvalidTaskState(_taskId, task.state, allowedStates);
        if (taskDispute[_taskId] != 0) revert DisputeAlreadyExists(_taskId); // Cannot dispute an already disputed task

        task.state = TaskState.Disputed;
        if (task.currentMilestoneIndex < task.milestones.length) {
             task.milestones[task.currentMilestoneIndex].state = MilestoneState.Disputed;
        }


        _disputeCounter++;
        uint256 disputeId = _disputeCounter;
        taskDispute[_taskId] = disputeId;

        // Set a short deadline for submitting evidence
        uint64 evidencePeriod = 3 days; // Example: 3 days to submit evidence
        uint64 evidenceDeadline = uint64(block.timestamp) + evidencePeriod;

        disputes[disputeId] = Dispute({
            id: disputeId,
            taskId: _taskId,
            disputer: msg.sender,
            reasonHash: _reasonHash,
            creatorEvidenceHash: bytes32(0),
            workerEvidenceHash: bytes32(0),
            evidenceDeadline: evidenceDeadline,
            state: DisputeState.EvidencePeriod, // Immediately moves to evidence period
            resolutionOutcome: 0 // Default no outcome
        });

        emit DisputeRaised(disputeId, _taskId, msg.sender);
    }

     /**
     * @notice Allows a participant in a dispute to submit evidence.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceHash Hash of the evidence.
     */
    function submitDisputeEvidence(uint256 _disputeId, bytes32 _evidenceHash) external nonReentrant whenDisputeState(_disputeId, DisputeState.EvidencePeriod) {
        Dispute storage dispute = disputes[_disputeId];
        Task storage task = tasks[dispute.taskId]; // Assuming task always exists for a valid dispute

        if (msg.sender != task.creator && msg.sender != task.worker && delegates[msg.sender] != task.creator && delegates[msg.sender] != task.worker) {
             revert NotTaskParticipant(dispute.taskId, msg.sender);
        }
        if (block.timestamp > dispute.evidenceDeadline) {
             // Evidence period passed, maybe auto-resolve based on submitted evidence or lack thereof
             // For this contract, just prevent submission after deadline
             revert MilestoneDeadlinePassed(dispute.taskId, 0); // Re-using error
        }

        if (msg.sender == task.creator || delegates[msg.sender] == task.creator) {
            dispute.creatorEvidenceHash = _evidenceHash;
        } else if (msg.sender == task.worker || delegates[msg.sender] == task.worker) {
            dispute.workerEvidenceHash = _evidenceHash;
        }
        // Note: Both parties can submit multiple times, only the last submission before deadline is kept.
        // A more advanced system might timestamp submissions or allow multiple.

        // If both have submitted, move to reviewing (optional, owner can manually move)
        // if (dispute.creatorEvidenceHash != bytes32(0) && dispute.workerEvidenceHash != bytes32(0)) {
        //     dispute.state = DisputeState.Reviewing;
        // }

        emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceHash);
    }

     /**
     * @notice Allows the contract owner (acting as resolver) to resolve a dispute.
     * Distributes funds and updates reputation based on the outcome.
     * @param _disputeId The ID of the dispute.
     * @param _resolutionOutcome -1 for worker wins, 0 for split/other, 1 for creator wins.
     * @param _creatorShare Percentage of remaining bounty/stakes creator receives (0-100). Worker gets 100 - _creatorShare. Only applicable for outcome 0.
     */
    function resolveDispute(uint256 _disputeId, int256 _resolutionOutcome, uint256 _creatorShare) external onlyOwner nonReentrant {
         Dispute storage dispute = disputes[_disputeId];
        if (dispute.taskId == 0) revert DisputeNotFound(_disputeId);
        if (dispute.state == DisputeState.Resolved) revert InvalidDisputeState(_disputeId, dispute.state, new DisputeState[]{DisputeState.Open, DisputeState.EvidencePeriod, DisputeState.Reviewing}); // Cannot resolve if already resolved

        Task storage task = tasks[dispute.taskId];

        // Ensure evidence submission period is over
        if (block.timestamp <= dispute.evidenceDeadline) {
             // Or transition to Reviewing state? For this simplified version, evidence must be in before resolving.
             // A real system would handle this state flow. Let's allow resolving *after* deadline or manually transition to Reviewing.
             // For simplicity here, let's just check deadline IF state is EvidencePeriod.
             if (dispute.state == DisputeState.EvidencePeriod && block.timestamp <= dispute.evidenceDeadline) {
                  revert InvalidDisputeState(_disputeId, dispute.state, new DisputeState[]{DisputeState.Open, DisputeState.Reviewing}); // Or custom error
             }
        }

        dispute.state = DisputeState.Resolved;
        dispute.resolutionOutcome = _resolutionOutcome;
        task.state = TaskState.Completed; // Task is considered concluded after dispute resolution

        // Calculate total funds locked in the task
        // This is the initial total bounty + creator stake + worker stake - paid milestones
         uint256 paidBounty = 0;
        for(uint i=0; i < task.currentMilestoneIndex; i++) {
             if (task.milestones[i].state == MilestoneState.Accepted) {
                 paidBounty += task.milestones[i].rewardAmount;
             }
        }
        // Total funds deposited: initial total bounty + creator stake + worker stake
        // Note: this assumes creator sends total bounty + creator stake initially, and worker sends worker stake on assign
        // Check `createTask` and `assignTask` logic for deposited amounts
        // Assuming initial deposit was task.totalBounty + task.creatorStake + task.workerStake on assignment
        // Let's assume total funds in contract for this task is remaining bounty + creatorStake + workerStake
        uint256 remainingBounty = task.totalBounty - paidBounty;
        uint256 totalFundsInEscrow = remainingBounty + task.creatorStake + task.workerStake;

        uint256 creatorShare = 0;
        uint256 workerShare = 0;

        if (_resolutionOutcome == 1) { // Creator wins
            creatorShare = totalFundsInEscrow;
            workerShare = 0;
            _updateReputation(task.creator, reputationParams_disputeWin);
            _updateReputation(task.worker, reputationParams_disputeLoss);
        } else if (_resolutionOutcome == -1) { // Worker wins
            creatorShare = 0;
            workerShare = totalFundsInEscrow;
            _updateReputation(task.creator, reputationParams_disputeLoss);
            _updateReputation(task.worker, reputationParams_disputeWin);
        } else if (_resolutionOutcome == 0) { // Split or Other (e.g., cancel with partial refund)
            if (_creatorShare > 100) revert InvalidResolutionOutcome(_creatorShare);
            creatorShare = (totalFundsInEscrow * _creatorShare) / 100;
            workerShare = totalFundsInEscrow - creatorShare;
            // Reputation could be neutral or minor penalty/gain
        } else {
            revert InvalidResolutionOutcome(_resolutionOutcome);
        }

        // Distribute funds
        if (creatorShare > 0) {
            (bool success, ) = task.creator.call{value: creatorShare}("");
            require(success, "Dispute resolution payout to creator failed");
            emit FundsReturned(task.creator, creatorShare);
        }
         if (workerShare > 0) {
            (bool success, ) = task.worker.call{value: workerShare}("");
            require(success, "Dispute resolution payout to worker failed");
             emit FundsReturned(task.worker, workerShare);
        }


        emit DisputeResolved(_disputeId, dispute.taskId, _resolutionOutcome);
    }

    // --- REPUTATION ---

    /**
     * @notice Internal function to update a user's reputation score.
     * Can result in positive or negative changes.
     * @param _user The address whose reputation to update.
     * @param _change The amount to add to the reputation score (can be negative).
     */
    function _updateReputation(address _user, int256 _change) internal {
        // Simple addition. Can add checks for min/max reputation if needed.
        // Convert to int256 for calculation, convert back to uint256 for storage.
        // Assuming reputation can go below zero and uint256 stores it as is (two's complement representation).
        // A safer approach might be to use a signed integer type if available or track delta and base.
        // For simplicity with uint256 mapping:
        uint256 currentRep = reputation[_user];
        if (_change > 0) {
            reputation[_user] = currentRep + uint256(_change);
        } else {
             uint256 absChange = uint256(-_change);
             if (currentRep < absChange) {
                 reputation[_user] = 0; // Cannot go below zero (in this simple model)
             } else {
                 reputation[_user] = currentRep - absChange;
             }
        }

        emit ReputationUpdated(_user, int256(reputation[_user]), _change);
    }

    /**
     * @notice Retrieves a user's current reputation score.
     * @param _user The address to query.
     * @return The reputation score. Note: Stored as uint256, interpret as needed externally if scores can be negative.
     * In this simple model using uint256, scores cannot strictly be negative, they just approach 0.
     */
    function getReputation(address _user) external view returns (uint256) {
        return reputation[_user];
    }

    // --- DELEGATION ---

    /**
     * @notice Allows a user to set another address as their delegate.
     * The delegate can perform task actions on behalf of the delegator.
     * Setting address(0) clears the delegate.
     * @param _delegate The address to set as delegate, or address(0) to clear.
     */
    function setDelegate(address _delegate) external {
        address oldDelegate = delegates[msg.sender];
        delegates[msg.sender] = _delegate;
        if (_delegate == address(0)) {
            emit DelegateCleared(msg.sender, oldDelegate);
        } else {
            emit DelegateSet(msg.sender, _delegate);
        }
    }

    /**
     * @notice Clears the delegate for the caller.
     */
    function clearDelegate() external {
        setDelegate(address(0));
    }

    /**
     * @notice Retrieves the delegate address for a given user.
     * @param _user The address to query.
     * @return The delegate address, or address(0) if none is set.
     */
    function getDelegate(address _user) external view returns (address) {
        return delegates[_user];
    }


    // --- QUERYING/VIEW FUNCTIONS ---

    /**
     * @notice Retrieves the details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing all task details.
     */
    function getTask(uint256 _taskId) external view returns (Task memory) {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) revert TaskNotFound(_taskId); // Check if task exists
        return task;
    }

    /**
     * @notice Retrieves the milestone details for a specific task and index.
     * @param _taskId The ID of the task.
     * @param _milestoneIndex The index of the milestone.
     * @return Milestone struct containing milestone details.
     */
    function getMilestone(uint256 _taskId, uint256 _milestoneIndex) external view returns (Milestone memory) {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) revert TaskNotFound(_taskId);
        if (_milestoneIndex >= task.milestones.length) revert InvalidMilestoneIndex(_taskId, _milestoneIndex, 0);
        return task.milestones[_milestoneIndex];
    }

    /**
     * @notice Retrieves a list of task IDs created or assigned to a user.
     * @param _user The address to query.
     * @return createdTaskIds List of task IDs created by the user.
     * @return assignedTaskIds List of task IDs assigned to the user.
     */
    function getUserTasks(address _user) external view returns (uint256[] memory createdTaskIds, uint256[] memory assignedTaskIds) {
        return (userCreatedTasks[_user], userAssignedTasks[_user]);
    }

    /**
     * @notice Retrieves a list of task IDs in a specific state.
     * NOTE: This function can be gas-intensive for a large number of tasks.
     * @param _state The state to filter by.
     * @return An array of task IDs.
     */
    function getTasksByState(TaskState _state) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](_taskCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _taskCounter; i++) {
            if (tasks[i].creator != address(0) && tasks[i].state == _state) { // Check if task exists and matches state
                taskIds[count] = i;
                count++;
            }
        }
        // Copy to a new array of exact size
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }

     /**
     * @notice Retrieves the details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct containing all dispute details.
     */
    function getDispute(uint256 _disputeId) external view returns (Dispute memory) {
         Dispute storage dispute = disputes[_disputeId];
        if (dispute.taskId == 0) revert DisputeNotFound(_disputeId); // Check if dispute exists
        return dispute;
    }

    /**
     * @notice Retrieves the current reputation parameters.
     * @return completion Points for task completion.
     * @return abandonment Points deducted for task abandonment.
     * @return rejectionPenalty Points deducted for milestone rejection.
     * @return disputeWin Points for winning a dispute.
     * @return disputeLoss Points for losing a dispute.
     */
    function getReputationParameters() external view returns (int256 completion, int256 abandonment, int256 rejectionPenalty, int256 disputeWin, int256 disputeLoss) {
        return (
            reputationParams_completion,
            reputationParams_abandonment,
            reputationParams_rejectionPenalty,
            reputationParams_disputeWin,
            reputationParams_disputeLoss
        );
    }

     /**
     * @notice Checks if a user (or their delegate) is the creator of a task.
     * @param _taskId The task ID.
     * @param _user The address to check.
     * @return True if the user or their delegate is the creator, false otherwise.
     */
    function isTaskCreator(uint256 _taskId, address _user) external view returns (bool) {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) return false; // Task doesn't exist
        return task.creator == _user || delegates[_user] == task.creator;
    }

    /**
     * @notice Checks if a user (or their delegate) is the worker assigned to a task.
     * @param _taskId The task ID.
     * @param _user The address to check.
     * @return True if the user or their delegate is the worker, false otherwise.
     */
    function isTaskWorker(uint256 _taskId, address _user) external view returns (bool) {
         Task storage task = tasks[_taskId];
        if (task.creator == address(0)) return false; // Task doesn't exist
        return task.worker != address(0) && (task.worker == _user || delegates[_user] == task.worker);
    }

    // Additional functions to reach 20+, focusing on views/helpers

    /**
     * @notice Gets the total number of tasks created.
     * @return The task counter value.
     */
    function getTotalTasks() external view returns (uint256) {
        return _taskCounter;
    }

    /**
     * @notice Gets the ID of the dispute associated with a task, if any.
     * @param _taskId The ID of the task.
     * @return The dispute ID, or 0 if no dispute is associated.
     */
    function getTaskDisputeId(uint256 _taskId) external view returns (uint256) {
        return taskDispute[_taskId];
    }

    /**
     * @notice Gets the required stake amounts for creating and assigning tasks.
     * @return creatorStake The required stake for a creator.
     * @return workerStake The required stake for a worker.
     */
    function getRequiredStakes() external view returns (uint256 creatorStake, uint256 workerStake) {
        return (requiredCreatorStake, requiredWorkerStake);
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Programmable Escrow with Milestones:** Going beyond simple "pay or not pay", this contract locks funds and releases them incrementally upon verifiable (via creator acceptance) completion of predefined milestones. This is more flexible than single-payment or time-based releases.
2.  **On-Chain Reputation System:** The contract directly tracks and updates a reputation score for users based on protocol-defined events (completion, failure, dispute outcomes). While simple here, this is a building block for complex decentralized trust systems, potentially influencing future task assignments, required stakes, or governance weight.
3.  **Delegation:** Users can explicitly delegate control of their actions within the protocol to another address. This is useful for account abstraction, hot/cold wallet setups, or specific roles within a DAO, allowing a secure cold wallet to delegate daily operational control to a hot wallet.
4.  **State Machine:** The task lifecycle is managed rigorously through distinct states and transitions, enforced by modifiers and logic within functions. This is crucial for complex processes to prevent incorrect or malicious actions at wrong times.
5.  **Dispute Resolution Hook:** While simplified (owner-controlled), the contract includes the *structure* for disputes, allowing participants to formally register disagreements and submit evidence hashes. This can be upgraded to a decentralized court (like Kleros), DAO voting, or oracle system without changing the fundamental task lifecycle too much.
6.  **Staking for Commitment:** Requiring creators and workers to lock funds (stakes) incentivizes honest behavior and commitment, with stakes subject to slashing in case of abandonment or losing a dispute.
7.  **Data Hashing (IPFS/Arweave Integration Pattern):** Using `bytes32` hashes for task descriptions, milestone submissions, dispute reasons, and evidence encourages storing larger data payloads off-chain (e.g., on IPFS or Arweave) while maintaining an immutable, verifiable link on-chain.

**Why it's not a direct duplicate of common open source:**

*   It's not an ERC-20, ERC-721, ERC-1155, or a standard token contract.
*   It's not a generic DAO governance contract.
*   It's not a standard DeFi lending/borrowing protocol.
*   While components exist elsewhere (escrow, reputation), combining *programmable milestones*, *on-chain reputation*, *delegation*, and a *structured dispute flow* within a *task coordination protocol* context creates a unique contract purpose.

This contract provides a solid foundation for a decentralized platform facilitating work coordination, combining financial incentives with reputation building and a mechanism for resolving disagreements.