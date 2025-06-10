Okay, here is a Solidity smart contract implementing a "Decentralized Predictive Task & Verification Network" concept. This involves multiple roles (Proposer, Worker, Verifier, Challenger), multi-stage processes, time-based state transitions, staking, slashing, rewards, a simple reputation system, and parameters that can be adjusted.

It's designed to be more complex than standard examples and incorporates concepts like:
*   **Multi-party interaction:** Proposers, Workers, Verifiers, Challengers, and the protocol owner/governance interact.
*   **State Machine:** Tasks go through a series of distinct states based on actions and time.
*   **Time-Based Logic:** Deadlines trigger state changes and potential failures.
*   **Staking and Slashing:** Participants stake collateral that can be forfeited based on performance or honesty.
*   **Reputation System:** Participants earn or lose reputation based on successful/unsuccessful participation, potentially influencing future interactions (though the influence is simple in this version).
*   **Conditional Outcomes:** Reward/penalty distribution depends on the truthfulness of predictions/verifications and the outcome of challenges.
*   **Parameterization:** Core protocol parameters are adjustable (by owner/governance).

**Disclaimer:** This is a complex example for educational purposes. Deploying such a system would require extensive security audits, gas optimization, and potentially external oracle or decentralized governance integration for true decentralization and robust challenge resolution. The challenge resolution here is simplified for demonstration.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
/*
Contract Name: ChronoTaskNetwork

Core Concept: A decentralized network for proposing, taking, verifying, and challenging tasks with a predictive or verifiable outcome. Users stake tokens as collateral and earn rewards or lose stakes based on performance and honesty. Includes a simple reputation system.

State Variables:
- taskCounter: Increments for unique task IDs.
- tasks: Mapping from task ID to Task struct. Stores all task data.
- userReputation: Mapping from user address to their reputation score.
- protocolParameters: Struct holding adjustable parameters (stake amounts, periods, slashing percentages, fees).
- feePool: Amount of protocol fees collected.
- ChronoToken: Address of the ERC20 token used for stakes and rewards.
- indexedTasksByState: Mapping from TaskState to an array of task IDs in that state (simplified indexing).
- indexedTasksByUser: Mapping from user address to an array of task IDs they are involved in (simplified indexing).

Enums:
- TaskState: Defines the lifecycle of a task (Proposed, StakedByWorker, InProgress, VerificationProposed, VerificationStaked, Challenged, Completed, Failed, Expired).
- ChallengeOutcome: Defines the result of a challenge (Unresolved, ChallengerWins, VerifierWins).

Structs:
- ProtocolParameters: Holds configuration values.
- Task: Holds all data for a single task instance.

Modifiers:
- whenNotPaused: Ensures contract is not paused.
- whenPaused: Ensures contract is paused.
- onlyOwner: Restricts function to the owner (used for parameter updates, pause, shutdown, fee withdrawal).
- onlyTaskParticipant: Ensures caller is involved in the specified task (Proposer, Worker, Verifier, Challenger).

Events:
- TaskCreated: When a new task is proposed.
- TaskStakedByWorker: When a worker stakes collateral for a task.
- TaskOutcomeSubmitted: When a worker submits their task outcome.
- TaskStakedByVerifier: When a verifier stakes collateral.
- VerificationSubmitted: When a verifier submits their verification.
- ChallengeRaised: When a challenge against verification is raised.
- ChallengeResolved: When a challenge is resolved (either by process or explicit call).
- TaskResolved: When a task reaches a final state (Completed or Failed).
- ReputationUpdated: When a user's reputation score changes.
- ProtocolParametersUpdated: When owner updates parameters.
- FundsWithdrawn: When user withdraws unstaked funds or owner withdraws fees.
- EmergencyShutdownActivated: When the contract is put into emergency shutdown.

Functions (Public/External - > 20):

Core Task Lifecycle:
1.  constructor: Initializes the contract with the ERC20 token address and initial parameters.
2.  createTask: Allows anyone to propose a new task, paying the reward upfront.
3.  stakeForTask: Allows a user to stake collateral and become the Worker for a Proposed task.
4.  submitTaskOutcome: Allows the Worker to submit their task outcome and move to InProgress (awaiting verification).
5.  stakeForVerification: Allows a user to stake collateral and become the Verifier for a task awaiting verification.
6.  submitVerification: Allows the Verifier to submit their verification (truth claim) for a task.
7.  challengeVerification: Allows any user to challenge the Verifier's claim by staking collateral.
8.  processChallengeResolution: Can be called by anyone after the challenge period to automatically resolve the challenge based on submissions (simplified logic).
9.  processTaskCompletion: Can be called by anyone after verification/challenge periods to finalize a Completed or Failed task, distributing funds and updating reputation.

Time-Based Failures (Callable by anyone):
10. failTaskByWorkerTimeout: Marks a task as Failed if the Worker misses the completion deadline.
11. failTaskByVerificationTimeout: Marks a task as Failed if the Verifier misses the verification deadline.
12. failTaskByChallengeTimeout: Marks a task as Failed if the challenge period expires without resolution (verifier wins by default in this logic).
13. reclaimExpiredTaskStake: Allows the Proposer to reclaim their reward stake if the task expires before being taken by a worker.

User Interaction:
14. withdrawUnstakedFunds: Allows a user to withdraw any token balance they sent to the contract that is not currently staked in a task.

View Functions (> 10, contributing to the >20 total):
15. getTaskDetails: Returns the full details of a specific task.
16. getTaskState: Returns the current state of a specific task.
17. getUserReputation: Returns the reputation score of a specific user.
18. getProtocolParameters: Returns the current protocol parameters.
19. getFeePool: Returns the total collected protocol fees.
20. getTasksByState: Returns the IDs of tasks in a specific state (simplified indexing).
21. getTasksByUser: Returns the IDs of tasks a user is involved in (simplified indexing).
22. viewEligibleTasksForWorker: Returns IDs of tasks in Proposed state.
23. viewEligibleTasksForVerification: Returns IDs of tasks in InProgress state.
24. viewEligibleTasksForChallenge: Returns IDs of tasks in VerificationStaked state.
25. viewTaskParticipants: Returns the addresses of the key participants for a task.

Owner/Admin Functions:
26. updateProtocolParameter: Allows the owner to update a specific parameter.
27. pauseContract: Allows the owner to pause the contract.
28. unpauseContract: Allows the owner to unpause the contract.
29. emergencyShutdown: Allows the owner to shut down the contract, stopping new activity and potentially enabling withdrawals (simplified - stops new activity).
30. withdrawOwnerFees: Allows the owner to withdraw collected protocol fees.

Internal Helper Functions:
- _updateReputation: Internal function to modify a user's reputation.
- _transitionTaskState: Internal function to change a task's state and update indexing.
- _transferTokens: Internal helper for safe token transfers.
- _handleTaskFailure: Internal logic for task failures, handles slashing and state changes.
- _handleTaskSuccess: Internal logic for task success, handles rewards and state changes.
- _resolveChallengeLogic: Internal logic to determine challenge outcome.
*/
// --- End Outline and Function Summary ---


contract ChronoTaskNetwork is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable ChronoToken;

    // --- State Variables ---

    uint256 private taskCounter;

    enum TaskState {
        Proposed,           // Task created, awaiting a worker to stake
        StakedByWorker,     // Worker staked, awaiting task outcome submission
        InProgress,         // Worker submitted outcome, awaiting verifier to stake
        VerificationStaked, // Verifier staked, awaiting verification submission
        Challenged,         // Verification submitted, but challenged
        Completed,          // Task successfully completed and verified
        Failed,             // Task failed (timeout, incorrect outcome, failed challenge)
        Expired             // Task expired before being taken by a worker
    }

    enum ChallengeOutcome {
        Unresolved,
        ChallengerWins,
        VerifierWins
    }

    struct Task {
        uint256 id;
        address proposer;
        uint256 rewardAmount; // Amount paid by proposer or from pool
        uint256 workerStakeAmount; // Required worker stake
        uint256 verifierStakeAmount; // Required verifier stake
        uint256 challengerStakeAmount; // Required challenger stake

        address worker;
        address verifier;
        address challenger; // Only set if a challenge is active

        bytes predictedOutcomeHash; // Hash of the predicted outcome (for verification)
        bytes submittedOutcomeHash; // Hash of the worker's submitted outcome
        bool verifierClaimMatches; // Verifier's claim: true if worker outcome matches predicted

        TaskState state;
        ChallengeOutcome challengeOutcome;

        uint256 proposalTimestamp;
        uint256 workerStakeDeadline; // Deadline for worker to stake
        uint256 completionDeadline;    // Deadline for worker to submit outcome
        uint256 verificationStakeDeadline; // Deadline for verifier to stake
        uint256 verificationDeadline;  // Deadline for verifier to submit verification
        uint256 challengeDeadline;     // Deadline for raising a challenge
        uint256 resolutionDeadline;    // Deadline for resolving a challenge

        // Keep track of funds locked in the task
        uint256 stakedByWorker;
        uint256 stakedByVerifier;
        uint256 stakedByChallenger;
        uint256 rewardLocked;
    }

    mapping(uint256 => Task) public tasks;

    mapping(address => int256) public userReputation; // Using int256 for potential negative reputation

    struct ProtocolParameters {
        uint256 minWorkerStake;
        uint256 minVerifierStake;
        uint256 minChallengerStake;
        uint256 workerStakePeriod; // Time allowed for worker to stake
        uint256 completionPeriod;  // Time allowed for worker to complete
        uint256 verificationStakePeriod; // Time allowed for verifier to stake
        uint256 verificationPeriod; // Time allowed for verifier to verify
        uint256 challengePeriod;    // Time allowed to raise challenge
        uint256 resolutionPeriod;   // Time allowed to resolve challenge

        uint256 workerSlashPercentage;    // % of worker stake slashed on failure
        uint256 verifierSlashPercentage;  // % of verifier stake slashed on failed verification/challenge
        uint256 challengerSlashPercentage; // % of challenger stake slashed on failed challenge

        uint256 protocolFeePercentage; // % of slashed funds/rewards going to protocol fee pool
        int256 reputationGainPerSuccess;
        int256 reputationLossPerFailure;
    }

    ProtocolParameters public protocolParameters;

    uint256 public feePool;

    // Simplified indexing for view functions (can become gas-intensive for large arrays)
    mapping(TaskState => uint256[]) public indexedTasksByState;
    mapping(address => uint256[]) public indexedTasksByUser;

    // --- Events ---

    event TaskCreated(uint256 taskId, address indexed proposer, uint256 rewardAmount);
    event TaskStakedByWorker(uint256 taskId, address indexed worker, uint256 stakedAmount);
    event TaskOutcomeSubmitted(uint256 taskId, address indexed worker, bytes submittedOutcomeHash);
    event TaskStakedByVerifier(uint256 taskId, address indexed verifier, uint256 stakedAmount);
    event VerificationSubmitted(uint256 taskId, address indexed verifier, bool claimMatches);
    event ChallengeRaised(uint256 taskId, address indexed challenger, uint256 stakedAmount);
    event ChallengeResolved(uint256 taskId, ChallengeOutcome outcome);
    event TaskResolved(uint256 taskId, TaskState finalState); // Final state: Completed or Failed
    event ReputationUpdated(address indexed user, int256 newReputation);
    event ProtocolParametersUpdated(string parameterName, uint256 newValue); // Log parameter name and value
    event FundsWithdrawn(address indexed user, uint256 amount);
    event EmergencyShutdownActivated(address indexed owner);

    // --- Modifiers ---

    // Inherits whenNotPaused and whenPaused from Pausable

    modifier onlyTaskParticipant(uint256 _taskId) {
        Task storage task = tasks[_taskId];
        require(msg.sender == task.proposer ||
                msg.sender == task.worker ||
                msg.sender == task.verifier ||
                msg.sender == task.challenger, "Not a task participant");
        _;
    }

    // --- Constructor ---

    constructor(address _chronoTokenAddress) Ownable(msg.sender) Pausable() {
        ChronoToken = IERC20(_chronoTokenAddress);

        // Set initial default parameters
        protocolParameters = ProtocolParameters({
            minWorkerStake: 100, // Example amounts (in token units)
            minVerifierStake: 50,
            minChallengerStake: 75,
            workerStakePeriod: 1 days,
            completionPeriod: 3 days,
            verificationStakePeriod: 1 days,
            verificationPeriod: 2 days,
            challengePeriod: 2 days,
            resolutionPeriod: 3 days, // Period *after* challenge period ends to call processChallengeResolution

            workerSlashPercentage: 50, // 50% slash
            verifierSlashPercentage: 75, // 75% slash
            challengerSlashPercentage: 100, // 100% slash if challenge fails

            protocolFeePercentage: 10, // 10% fee
            reputationGainPerSuccess: 10,
            reputationLossPerFailure: -5
        });
    }

    // --- Core Task Lifecycle Functions ---

    /**
     * @notice Proposes a new task and pays the reward amount upfront.
     * @param _rewardAmount The reward for completing the task.
     * @param _workerStake The minimum stake required from a worker.
     * @param _verifierStake The minimum stake required from a verifier.
     * @param _challengerStake The minimum stake required from a challenger.
     * @param _predictedOutcomeHash A hash representing the expected task outcome.
     */
    function createTask(
        uint256 _rewardAmount,
        uint256 _workerStake,
        uint256 _verifierStake,
        uint256 _challengerStake,
        bytes memory _predictedOutcomeHash
    ) external payable whenNotPaused nonReentrant {
        require(_rewardAmount > 0, "Reward must be positive");
        require(_workerStake >= protocolParameters.minWorkerStake, "Worker stake too low");
        require(_verifierStake >= protocolParameters.minVerifierStake, "Verifier stake too low");
        require(_challengerStake >= protocolParameters.minChallengerStake, "Challenger stake too low");
        require(_predictedOutcomeHash.length > 0, "Predicted outcome hash required");

        uint256 taskId = taskCounter++;
        uint256 currentTimestamp = block.timestamp;

        tasks[taskId] = Task({
            id: taskId,
            proposer: msg.sender,
            rewardAmount: _rewardAmount,
            workerStakeAmount: _workerStake,
            verifierStakeAmount: _verifierStake,
            challengerStakeAmount: _challengerStake,
            worker: address(0),
            verifier: address(0),
            challenger: address(0),
            predictedOutcomeHash: _predictedOutcomeHash,
            submittedOutcomeHash: "", // Initially empty
            verifierClaimMatches: false, // Initially false
            state: TaskState.Proposed,
            challengeOutcome: ChallengeOutcome.Unresolved,
            proposalTimestamp: currentTimestamp,
            workerStakeDeadline: currentTimestamp + protocolParameters.workerStakePeriod,
            completionDeadline: 0, // Set when worker stakes
            verificationStakeDeadline: 0, // Set when worker submits outcome
            verificationDeadline: 0, // Set when verifier stakes
            challengeDeadline: 0, // Set after verification
            resolutionDeadline: 0, // Set after challenge deadline

            stakedByWorker: 0,
            stakedByVerifier: 0,
            stakedByChallenger: 0,
            rewardLocked: _rewardAmount
        });

        _transferTokens(msg.sender, address(this), _rewardAmount);

        _transitionTaskState(taskId, TaskState.Proposed); // Add to Proposed index
        indexedTasksByUser[msg.sender].push(taskId); // Add to proposer's index

        emit TaskCreated(taskId, msg.sender, _rewardAmount);
    }

    /**
     * @notice Stakes the required collateral to become the worker for a task.
     * @param _taskId The ID of the task.
     */
    function stakeForTask(uint256 _taskId) external payable whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Proposed, "Task not in Proposed state");
        require(task.worker == address(0), "Task already has a worker");
        require(block.timestamp <= task.workerStakeDeadline, "Worker stake deadline passed");

        uint256 stakeAmount = task.workerStakeAmount;
        require(msg.value >= stakeAmount, "Insufficient collateral staked"); // Use msg.value for simplicity assuming ETH stake, or ERC20 transferFrom

        // Assuming ERC20 stake:
        _transferTokens(msg.sender, address(this), stakeAmount);
        task.stakedByWorker = stakeAmount; // Record the actual amount staked

        task.worker = msg.sender;
        task.completionDeadline = block.timestamp + protocolParameters.completionPeriod;

        _transitionTaskState(_taskId, TaskState.StakedByWorker); // Update state and indexing
        indexedTasksByUser[msg.sender].push(taskId); // Add to worker's index

        emit TaskStakedByWorker(_taskId, msg.sender, stakeAmount);
    }

    /**
     * @notice Allows the worker to submit the task outcome hash.
     * @param _taskId The ID of the task.
     * @param _submittedOutcomeHash The hash of the actual outcome.
     */
    function submitTaskOutcome(uint256 _taskId, bytes memory _submittedOutcomeHash) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.StakedByWorker, "Task not awaiting outcome submission");
        require(msg.sender == task.worker, "Only the worker can submit the outcome");
        require(block.timestamp <= task.completionDeadline, "Completion deadline passed");
        require(_submittedOutcomeHash.length > 0, "Submitted outcome hash required");

        task.submittedOutcomeHash = _submittedOutcomeHash;
        task.verificationStakeDeadline = block.timestamp + protocolParameters.verificationStakePeriod;

        _transitionTaskState(_taskId, TaskState.InProgress); // Update state and indexing

        emit TaskOutcomeSubmitted(_taskId, msg.sender, _submittedOutcomeHash);
    }

    /**
     * @notice Stakes the required collateral to become the verifier for a task.
     * @param _taskId The ID of the task.
     */
    function stakeForVerification(uint256 _taskId) external payable whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.InProgress, "Task not awaiting verification stake");
        require(task.verifier == address(0), "Task already has a verifier");
        require(msg.sender != task.worker && msg.sender != task.proposer, "Worker or Proposer cannot be Verifier"); // Avoid conflicts
        require(block.timestamp <= task.verificationStakeDeadline, "Verification stake deadline passed");

        uint256 stakeAmount = task.verifierStakeAmount;
        require(msg.value >= stakeAmount, "Insufficient collateral staked"); // Assuming ERC20 stake

        // Assuming ERC20 stake:
        _transferTokens(msg.sender, address(this), stakeAmount);
        task.stakedByVerifier = stakeAmount;

        task.verifier = msg.sender;
        task.verificationDeadline = block.timestamp + protocolParameters.verificationPeriod;

        _transitionTaskState(_taskId, TaskState.VerificationStaked); // Update state and indexing
        indexedTasksByUser[msg.sender].push(taskId); // Add to verifier's index

        emit TaskStakedByVerifier(_taskId, msg.sender, stakeAmount);
    }

    /**
     * @notice Allows the verifier to submit their verification claim.
     * @param _taskId The ID of the task.
     * @param _claimMatches Whether the worker's submitted outcome matches the predicted outcome.
     */
    function submitVerification(uint256 _taskId, bool _claimMatches) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.VerificationStaked, "Task not awaiting verification submission");
        require(msg.sender == task.verifier, "Only the verifier can submit verification");
        require(block.timestamp <= task.verificationDeadline, "Verification deadline passed");

        task.verifierClaimMatches = _claimMatches;
        task.challengeDeadline = block.timestamp + protocolParameters.challengePeriod;

        // State does not transition yet, stays in VerificationStaked during challenge period
        emit VerificationSubmitted(_taskId, msg.sender, _claimMatches);
    }

    /**
     * @notice Allows any user (not proposer, worker, verifier) to challenge the verifier's claim.
     * @param _taskId The ID of the task.
     */
    function challengeVerification(uint256 _taskId) external payable whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.VerificationStaked, "Task not in challengeable state");
        require(task.challenger == address(0), "Task already has a challenger");
        require(msg.sender != task.worker && msg.sender != task.proposer && msg.sender != task.verifier, "Worker, Proposer, or Verifier cannot challenge"); // Avoid conflicts
        require(block.timestamp <= task.challengeDeadline, "Challenge deadline passed");
        require(task.verifierClaimMatches != (task.submittedOutcomeHash == task.predictedOutcomeHash), "Cannot challenge an honest verification"); // Only challenge if verifier's claim is potentially false

        uint256 stakeAmount = task.challengerStakeAmount;
        require(msg.value >= stakeAmount, "Insufficient collateral staked"); // Assuming ERC20 stake

        // Assuming ERC20 stake:
        _transferTokens(msg.sender, address(this), stakeAmount);
        task.stakedByChallenger = stakeAmount;

        task.challenger = msg.sender;
        task.resolutionDeadline = block.timestamp + protocolParameters.resolutionPeriod; // Set resolution deadline after challenge raised

        _transitionTaskState(_taskId, TaskState.Challenged); // Update state and indexing
        indexedTasksByUser[msg.sender].push(taskId); // Add to challenger's index

        emit ChallengeRaised(_taskId, msg.sender, stakeAmount);
    }

    /**
     * @notice Processes the resolution of a challenged task. Can be called by anyone after the challenge period ends.
     * The outcome is determined automatically based on submissions and the truth (simplified: comparing hashes).
     * This function assumes the 'truth' is verifiable on-chain by comparing predicted and submitted hashes.
     * A real-world implementation might need an oracle or decentralized court.
     * @param _taskId The ID of the task.
     */
    function processChallengeResolution(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Challenged, "Task not in Challenged state");
        require(block.timestamp > task.challengeDeadline, "Challenge period not over"); // Can only be resolved after challenge period
        // Optional: require block.timestamp > task.resolutionDeadline for a hard timeout resolution

        bool actualOutcomeMatchesPrediction = (task.submittedOutcomeHash == task.predictedOutcomeHash);
        bool verifierWasHonest = (task.verifierClaimMatches == actualOutcomeMatchesPrediction);

        if (verifierWasHonest) {
            // Verifier was right, Challenger was wrong
            task.challengeOutcome = ChallengeOutcome.VerifierWins;
            _updateReputation(task.verifier, protocolParameters.reputationGainPerSuccess); // Verifier rewarded
            _updateReputation(task.challenger, protocolParameters.reputationLossPerFailure); // Challenger penalized

            // Slashing: Challenger stake is slashed
            uint256 slashedAmount = (task.stakedByChallenger * protocolParameters.challengerSlashPercentage) / 100;
            uint256 protocolFee = (slashedAmount * protocolParameters.protocolFeePercentage) / 100;
            feePool += protocolFee;
            uint256 remainingSlash = slashedAmount - protocolFee;

            // Reward: Slashed challenger funds are distributed
            // To Verifier? To Protocol? For this example, remaining slash goes to Verifier.
             _transferTokens(address(this), task.verifier, remainingSlash);

            // Return remaining stakes: Challenger gets nothing back (100% slash in params example), Verifier gets their stake back
            _transferTokens(address(this), task.verifier, task.stakedByVerifier);


        } else {
             // Verifier was wrong, Challenger was right (or Verifier didn't verify honestly)
            task.challengeOutcome = ChallengeOutcome.ChallengerWins;
            _updateReputation(task.challenger, protocolParameters.reputationGainPerSuccess); // Challenger rewarded
            _updateReputation(task.verifier, protocolParameters.reputationLossPerFailure); // Verifier penalized

            // Slashing: Verifier stake is slashed
            uint256 slashedAmount = (task.stakedByVerifier * protocolParameters.verifierSlashPercentage) / 100;
            uint256 protocolFee = (slashedAmount * protocolParameters.protocolFeePercentage) / 100;
            feePool += protocolFee;
             uint256 remainingSlash = slashedAmount - protocolFee;

            // Reward: Slashed verifier funds are distributed
            // To Challenger? To Protocol? For this example, remaining slash goes to Challenger.
             _transferTokens(address(this), task.challenger, remainingSlash);

            // Return remaining stakes: Verifier gets nothing back (75% slash leaves some, but simplified), Challenger gets their stake back
            _transferTokens(address(this), task.challenger, task.stakedByChallenger);
        }

        // After challenge resolution, the task needs to proceed to completion or failure based on the *actual* outcome
        if (actualOutcomeMatchesPrediction) {
             // Even if verification was challenged, if the *actual* outcome is correct, the worker succeeds.
            _handleTaskSuccess(_taskId);
        } else {
            // If the *actual* outcome is incorrect, the worker failed.
            _handleTaskFailure(_taskId, "Task outcome incorrect after challenge");
        }

        emit ChallengeResolved(_taskId, task.challengeOutcome);
    }


    /**
     * @notice Finalizes a task after verification/challenge periods. Callable by anyone.
     * This function handles the distribution of rewards/penalties based on the final state.
     * @param _taskId The ID of the task.
     */
    function processTaskCompletion(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];

        // Ensure task is in a state ready for finalization and deadlines have passed
        require(
            task.state == TaskState.VerificationStaked && block.timestamp > task.challengeDeadline ||
            task.state == TaskState.Challenged && block.timestamp > task.resolutionDeadline,
            "Task not ready for completion processing"
        );
        require(task.challengeOutcome != ChallengeOutcome.Unresolved, "Challenge must be resolved first");

        // Determine final outcome based on verification and challenge resolution
        bool actualOutcomeMatchesPrediction = (task.submittedOutcomeHash == task.predictedOutcomeHash);

        if (actualOutcomeMatchesPrediction) {
             // If the outcome matches, worker succeeds regardless of challenge path resolution
            _handleTaskSuccess(_taskId);
        } else {
            // If outcome does not match, worker fails
            _handleTaskFailure(_taskId, "Task outcome incorrect");
        }

         emit TaskResolved(_taskId, task.state); // Log final state
    }

    // --- Time-Based Failure Functions (Callable by anyone) ---

    /**
     * @notice Marks a task as Failed if the worker failed to stake in time.
     * @param _taskId The ID of the task.
     */
    function failTaskByWorkerTimeout(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Proposed, "Task not in Proposed state");
        require(block.timestamp > task.workerStakeDeadline, "Worker stake deadline not passed");

        _handleTaskFailure(_taskId, "Worker stake timeout");
        // Proposer can reclaim reward using reclaimExpiredTaskStake
         emit TaskResolved(_taskId, task.state);
    }

    /**
     * @notice Marks a task as Failed if the worker failed to submit outcome in time.
     * @param _taskId The ID of the task.
     */
    function failTaskByCompletionTimeout(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.StakedByWorker, "Task not in StakedByWorker state");
        require(block.timestamp > task.completionDeadline, "Completion deadline not passed");

        _handleTaskFailure(_taskId, "Completion timeout");
         emit TaskResolved(_taskId, task.state);
    }


    /**
     * @notice Marks a task as Failed if the verifier failed to stake in time.
     * @param _taskId The ID of the task.
     */
    function failTaskByVerificationStakeTimeout(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.InProgress, "Task not in InProgress state");
        require(block.timestamp > task.verificationStakeDeadline, "Verification stake deadline not passed");

         _handleTaskFailure(_taskId, "Verification stake timeout");
         emit TaskResolved(_taskId, task.state);
    }

     /**
     * @notice Marks a task as Failed if the verifier failed to submit verification in time.
     * @param _taskId The ID of the task.
     */
    function failTaskByVerificationTimeout(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.VerificationStaked, "Task not in VerificationStaked state");
        require(block.timestamp > task.verificationDeadline, "Verification deadline not passed");

        // Verifier fails, worker state depends on whether outcome was actually correct
        bool actualOutcomeMatchesPrediction = (task.submittedOutcomeHash == task.predictedOutcomeHash);

        _updateReputation(task.verifier, protocolParameters.reputationLossPerFailure); // Verifier is penalized for timeout

        // Slashing: Verifier stake is slashed
        uint256 slashedAmount = (task.stakedByVerifier * protocolParameters.verifierSlashPercentage) / 100;
        uint256 protocolFee = (slashedAmount * protocolParameters.protocolFeePercentage) / 100;
        feePool += protocolFee;
        // Remaining slash amount is effectively lost if no challenge occurs, or could go to worker/proposer.
        // Simplified: it stays in the contract or goes to feePool depending on specific logic.
        // Let's add it to the feePool for simplicity here.
        feePool += (slashedAmount - protocolFee);


        // Return remaining stakes: Verifier gets nothing back (slashed)
        // Worker gets their stake back? Depends on worker's outcome.
        if (actualOutcomeMatchesPrediction) {
             // Worker was correct, gets stake back + reward (even if verifier timed out)
             _handleTaskSuccess(_taskId);
        } else {
             // Worker was incorrect, worker stake is slashed
            _handleTaskFailure(_taskId, "Worker outcome incorrect, verification timed out");
        }
         emit TaskResolved(_taskId, task.state);
    }


    /**
     * @notice Can be called by the proposer to reclaim their reward if the task expires before being taken by a worker.
     * @param _taskId The ID of the task.
     */
    function reclaimExpiredTaskStake(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.state == TaskState.Proposed, "Task not in Proposed state");
        require(msg.sender == task.proposer, "Only proposer can reclaim");
        require(block.timestamp > task.workerStakeDeadline, "Worker stake deadline not passed");
        require(task.rewardLocked > 0, "No reward to reclaim"); // Ensure reward hasn't been moved

        uint256 reward = task.rewardLocked;
        task.rewardLocked = 0; // Prevent double withdrawal

        _transitionTaskState(_taskId, TaskState.Expired); // Mark as expired
         _transferTokens(address(this), task.proposer, reward);

         emit FundsWithdrawn(task.proposer, reward);
         emit TaskResolved(_taskId, task.state);
    }

    // --- User Interaction Functions ---

    /**
     * @notice Allows a user to withdraw any ChronoToken balance they have in the contract
     * that is NOT currently staked in an active task.
     */
    function withdrawUnstakedFunds() external nonReentrant {
         // Calculate available balance: total balance minus sum of all staked amounts for this user
        uint256 totalBalance = ChronoToken.balanceOf(address(this));
        uint256 stakedBalance = 0;

        // This requires iterating over all tasks a user is involved in, which can be gas-intensive.
        // A more gas-efficient design would track unstaked balances explicitly.
        // For this example, we iterate over their indexed tasks.
        for (uint256 i = 0; i < indexedTasksByUser[msg.sender].length; i++) {
            uint256 taskId = indexedTasksByUser[msg.sender][i];
            Task storage task = tasks[taskId];

            // Only count stakes if the task is in a state where funds are potentially locked
            if (task.state != TaskState.Completed && task.state != TaskState.Failed && task.state != TaskState.Expired) {
                 if (task.worker == msg.sender) stakedBalance += task.stakedByWorker;
                 if (task.verifier == msg.sender) stakedBalance += task.stakedByVerifier;
                 if (task.challenger == msg.sender) stakedBalance += task.stakedByChallenger;
                 // Proposer reward is locked but not counted here as it's different from collateral
            }
             // Note: This simple sum might be inaccurate if the user had multiple roles in one task (unlikely)
             // or if funds were partially slashed but not yet transferred out.
             // A robust system would need more precise balance tracking.
        }

        uint256 contractUserBalance = ChronoToken.balanceOf(address(this));
        uint256 withdrawableAmount = contractUserBalance - stakedBalance - feePool - taskCounter; // Subtract total staked funds and fee pool, plus a small buffer for simplicity

        // A safer approach would be to track 'deposits' vs 'stakes' explicitly per user.
        // This current implementation is a simplification and might have edge cases.

        require(withdrawableAmount > 0, "No withdrawable funds");

        _transferTokens(address(this), msg.sender, withdrawableAmount);

        emit FundsWithdrawn(msg.sender, withdrawableAmount);
    }

    // --- View Functions ---

    /**
     * @notice Gets the details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct details.
     */
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(_taskId < taskCounter, "Task ID out of bounds");
        return tasks[_taskId];
    }

    /**
     * @notice Gets the current state of a specific task.
     * @param _taskId The ID of the task.
     * @return The current TaskState.
     */
    function getTaskState(uint255 _taskId) external view returns (TaskState) {
         require(_taskId < taskCounter, "Task ID out of bounds");
         return tasks[_taskId].state;
    }

    /**
     * @notice Gets the reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (int256) {
        return userReputation[_user];
    }

     /**
     * @notice Gets the current protocol parameters.
     * @return The ProtocolParameters struct.
     */
    function getProtocolParameters() external view returns (ProtocolParameters memory) {
        return protocolParameters;
    }

    /**
     * @notice Gets the total collected protocol fees.
     * @return The amount of fees in the fee pool.
     */
    function getFeePool() external view returns (uint256) {
        return feePool;
    }

    /**
     * @notice Gets the IDs of tasks in a specific state.
     * @param _state The state to filter by.
     * @return An array of task IDs.
     */
    function getTasksByState(TaskState _state) external view returns (uint256[] memory) {
        return indexedTasksByState[_state];
    }

     /**
     * @notice Gets the IDs of tasks a user is involved in.
     * @param _user The address of the user.
     * @return An array of task IDs.
     */
    function getTasksByUser(address _user) external view returns (uint256[] memory) {
        return indexedTasksByUser[_user];
    }

    /**
     * @notice Gets the IDs of tasks currently in the Proposed state, available for workers.
     * @return An array of task IDs.
     */
    function viewEligibleTasksForWorker() external view returns (uint256[] memory) {
        return indexedTasksByState[TaskState.Proposed];
    }

    /**
     * @notice Gets the IDs of tasks currently in the InProgress state, available for verifiers to stake.
     * @return An array of task IDs.
     */
    function viewEligibleTasksForVerification() external view returns (uint256[] memory) {
        return indexedTasksByState[TaskState.InProgress];
    }

    /**
     * @notice Gets the IDs of tasks currently in the VerificationStaked state, available for challenge.
     * @return An array of task IDs.
     */
    function viewEligibleTasksForChallenge() external view returns (uint256[] memory) {
        return indexedTasksByState[TaskState.VerificationStaked];
    }

     /**
     * @notice Gets the addresses of the main participants for a task.
     * @param _taskId The ID of the task.
     * @return proposer, worker, verifier, challenger addresses.
     */
    function viewTaskParticipants(uint256 _taskId) external view returns (address proposer, address worker, address verifier, address challenger) {
        require(_taskId < taskCounter, "Task ID out of bounds");
        Task storage task = tasks[_taskId];
        return (task.proposer, task.worker, task.verifier, task.challenger);
    }


    // --- Owner/Admin Functions ---

     /**
     * @notice Updates a specific protocol parameter.
     * @param _parameterName The name of the parameter (e.g., "minWorkerStake").
     * @param _newValue The new value for the parameter.
     * @dev Requires exact string match for parameter name. Use with caution.
     */
    function updateProtocolParameter(string calldata _parameterName, uint256 _newValue) external onlyOwner whenNotPaused {
        bytes memory paramNameBytes = bytes(_parameterName);

        if (keccak256(paramNameBytes) == keccak256("minWorkerStake")) {
            protocolParameters.minWorkerStake = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("minVerifierStake")) {
            protocolParameters.minVerifierStake = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("minChallengerStake")) {
            protocolParameters.minChallengerStake = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("workerStakePeriod")) {
            protocolParameters.workerStakePeriod = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("completionPeriod")) {
            protocolParameters.completionPeriod = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("verificationStakePeriod")) {
            protocolParameters.verificationStakePeriod = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("verificationPeriod")) {
            protocolParameters.verificationPeriod = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("challengePeriod")) {
            protocolParameters.challengePeriod = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("resolutionPeriod")) {
            protocolParameters.resolutionPeriod = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("workerSlashPercentage")) {
             require(_newValue <= 100, "Percentage cannot exceed 100");
            protocolParameters.workerSlashPercentage = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("verifierSlashPercentage")) {
             require(_newValue <= 100, "Percentage cannot exceed 100");
            protocolParameters.verifierSlashPercentage = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("challengerSlashPercentage")) {
             require(_newValue <= 100, "Percentage cannot exceed 100");
            protocolParameters.challengerSlashPercentage = _newValue;
        } else if (keccak256(paramNameBytes) == keccak256("protocolFeePercentage")) {
             require(_newValue <= 100, "Percentage cannot exceed 100");
            protocolParameters.protocolFeePercentage = _newValue;
        }
        // Reputation parameters are int256, need different handling or cast
        // else if (keccak256(paramNameBytes) == keccak256("reputationGainPerSuccess")) {
        //     protocolParameters.reputationGainPerSuccess = int256(_newValue);
        // } else if (keccak256(paramNameBytes) == keccak256("reputationLossPerFailure")) {
        //     protocolParameters.reputationLossPerFailure = int256(_newValue); // Be careful with casting negative numbers
        // }
        else {
            revert("Invalid parameter name");
        }

        emit ProtocolParametersUpdated(_parameterName, _newValue);
    }

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit Paused(msg.sender); // Pausable emits this event
    }

    /**
     * @notice Unpauses the contract, allowing operations again.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender); // Pausable emits this event
    }

     /**
     * @notice Initiates an emergency shutdown. Stops new tasks and staking.
     * @dev Does NOT automatically return staked funds. Staked funds remain locked
     * until the tasks they are in are resolved or can be force-completed/failed.
     * Unstaked funds can still be withdrawn.
     */
    function emergencyShutdown() external onlyOwner {
        // Stop creating new tasks and staking
        _pause();
        // Potentially add a flag to disable *all* state changes except withdrawals?
        // For this example, pause() is sufficient to prevent new activity.
        emit EmergencyShutdownActivated(msg.sender);
    }

    /**
     * @notice Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawOwnerFees() external onlyOwner nonReentrant {
        uint256 amount = feePool;
        require(amount > 0, "No fees to withdraw");
        feePool = 0;
        _transferTokens(address(this), owner(), amount);
        emit FundsWithdrawn(owner(), amount);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address of the user.
     * @param _change The amount to add to their reputation (can be negative).
     */
    function _updateReputation(address _user, int256 _change) internal {
        if (_user == address(0)) return; // Don't update reputation for zero address
        userReputation[_user] = userReputation[_user] + _change;
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    /**
     * @dev Internal function to transition a task's state and update indexing.
     * @param _taskId The ID of the task.
     * @param _newState The state to transition to.
     */
    function _transitionTaskState(uint256 _taskId, TaskState _newState) internal {
        Task storage task = tasks[_taskId];
        TaskState oldState = task.state;
        task.state = _newState;

        // Update indexing (simplified - requires manual removal from old state array which is gas intensive)
        // A more realistic index would use linked lists or auxiliary mapping for removals.
        // For this example, we just push to the new state's array. Querying needs to filter by current state.
        indexedTasksByState[_newState].push(_taskId);

        // Note: Removing from oldState array is complex and gas-heavy.
        // A simple iteration to find and remove is bad for gas.
        // A better indexing requires mapping element value to its index in the array for O(1) removal,
        // or using a state that indicates "removed from index".
        // For this complex example, we'll omit the *removal* from the old state's array to save gas,
        // meaning `indexedTasksByState` arrays might contain IDs of tasks not currently in that state.
        // View functions using these indices would need to check the task's *current* state.
        // indexedTasksByState[oldState] would need removal logic here.
    }

     /**
     * @dev Internal function to handle token transfers, using SafeERC20.
     * @param _from The address sending tokens.
     * @param _to The address receiving tokens.
     * @param _amount The amount to transfer.
     */
    function _transferTokens(address _from, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            if (_from == address(this)) {
                ChronoToken.safeTransfer(_to, _amount);
            } else {
                ChronoToken.safeTransferFrom(_from, _to, _amount);
            }
        }
    }

     /**
     * @dev Internal logic for handling task failure. Handles slashing and transitions state to Failed.
     * Assumes failure reason is already determined (e.g., timeout, incorrect outcome).
     * @param _taskId The ID of the task.
     * @param _reason A string describing the reason for failure.
     */
    function _handleTaskFailure(uint256 _taskId, string memory _reason) internal {
        Task storage task = tasks[_taskId];
        require(task.state != TaskState.Completed && task.state != TaskState.Failed && task.state != TaskState.Expired, "Task already finalized");

        _updateReputation(task.worker, protocolParameters.reputationLossPerFailure);

        // Slashing logic for worker
        if (task.stakedByWorker > 0) {
            uint256 slashedAmount = (task.stakedByWorker * protocolParameters.workerSlashPercentage) / 100;
            uint256 protocolFee = (slashedAmount * protocolParameters.protocolFeePercentage) / 100;
            feePool += protocolFee;
            uint256 remainingStake = task.stakedByWorker - slashedAmount;

            // Worker gets remaining stake back
             _transferTokens(address(this), task.worker, remainingStake);
            task.stakedByWorker = 0; // Clear stake amount in task struct
        }

        // Proposer reward goes back to the proposer (if it was locked)
        if (task.rewardLocked > 0) {
             _transferTokens(address(this), task.proposer, task.rewardLocked);
            task.rewardLocked = 0; // Clear reward amount in task struct
        }

        // Any remaining stakes (verifier, challenger) are also returned here if not handled by challenge resolution
        // Or could be directed to fee pool depending on protocol design
        if (task.stakedByVerifier > 0 && task.state != TaskState.Challenged) { // Don't return if handled by challenge
             _transferTokens(address(this), task.verifier, task.stakedByVerifier);
            task.stakedByVerifier = 0;
        }
        if (task.stakedByChallenger > 0 && task.state != TaskState.Challenged) { // Don't return if handled by challenge
            // Challenger stake is usually only relevant if they challenged
             _transferTokens(address(this), task.challenger, task.stakedByChallenger);
            task.stakedByChallenger = 0;
        }


        _transitionTaskState(_taskId, TaskState.Failed); // Update state and indexing
    }

    /**
     * @dev Internal logic for handling task success. Handles reward distribution and transitions state to Completed.
     * Assumes success reason is already determined (e.g., outcome correct).
     * @param _taskId The ID of the task.
     */
     function _handleTaskSuccess(uint256 _taskId) internal {
        Task storage task = tasks[_taskId];
        require(task.state != TaskState.Completed && task.state != TaskState.Failed && task.state != TaskState.Expired, "Task already finalized");

        _updateReputation(task.worker, protocolParameters.reputationGainPerSuccess);

        // Worker gets stake back + reward
        uint256 workerPayout = task.stakedByWorker + task.rewardLocked;
         _transferTokens(address(this), task.worker, workerPayout);
        task.stakedByWorker = 0;
        task.rewardLocked = 0;

        // Any remaining stakes (verifier, challenger) are returned here if not handled by challenge resolution
        // Or could be directed to fee pool depending on protocol design
         if (task.stakedByVerifier > 0 && task.state != TaskState.Challenged) { // Don't return if handled by challenge
             _transferTokens(address(this), task.verifier, task.stakedByVerifier);
            task.stakedByVerifier = 0;
        }
        if (task.stakedByChallenger > 0 && task.state != TaskState.Challenged) { // Don't return if handled by challenge
             _transferTokens(address(this), task.challenger, task.stakedByChallenger);
            task.stakedByChallenger = 0;
        }


        _transitionTaskState(_taskId, TaskState.Completed); // Update state and indexing
    }

    // --- ERC20 Receiver Fallback (Optional but good practice if receiving ETH) ---
    // This contract uses ERC20, so a receive or fallback for ETH isn't strictly needed
    // unless you intended to allow ETH deposits not tied to tasks, which isn't the current design.
    // receive() external payable {}
    // fallback() external payable {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Decentralized Task Network:** Moves beyond simple token transfers or single-action contracts. It's a mini-protocol for coordinating multiple users around a specific outcome (the "task").
2.  **State Machine:** The `TaskState` enum and the transition logic in functions (`_transitionTaskState`, `require` statements checking `task.state`) implement a robust state machine, a common pattern in complex smart contracts representing workflows or processes.
3.  **Time-Based Logic & Automated Failures:** Deadlines (`workerStakeDeadline`, `completionDeadline`, etc.) are enforced on-chain. Functions like `failTaskByWorkerTimeout` can be called by anyone after the deadline, pushing the task to a `Failed` state. This introduces a degree of autonomous progression based on time.
4.  **Multi-Party Staking & Slashing:** Different roles (Worker, Verifier, Challenger) require different stakes. The contract implements logic for *slashing* (partially or fully forfeiting) these stakes based on timeouts or verification/challenge outcomes. Slashed funds are distributed (partially to a fee pool, partially to winning parties).
5.  **Simple Reputation System:** The `userReputation` mapping tracks a score for users. Successes increase reputation, failures/slashes decrease it. While not heavily used *within* this contract (e.g., doesn't affect staking requirements here), it lays the groundwork for potential future features where reputation could influence eligibility, required stake amounts, or reward multipliers. It's a building block for decentralized trust.
6.  **On-Chain Challenge Mechanism:** The `challengeVerification` and `processChallengeResolution` functions create a mini-dispute resolution system on-chain. While simplified (resolution relies on comparing internal hashes), it demonstrates the pattern of allowing third parties to challenge claims made by other participants, adding an adversarial component to enforce honesty.
7.  **Parameterization:** The `ProtocolParameters` struct allows the owner (or potentially a decentralized governance module in a real system) to adjust core economic and timing parameters (`minStake`, `periods`, `slashPercentages`, `fees`) without deploying a new contract. This adds flexibility and upgradeability (though upgrading logic itself is harder).
8.  **Fee Collection:** A `feePool` accumulates a percentage of slashed funds, providing a potential revenue stream for protocol maintenance or distribution (handled by `withdrawOwnerFees`).
9.  **Simplified On-Chain Verification:** The concept relies on comparing `predictedOutcomeHash` and `submittedOutcomeHash`. While simplistic (real-world tasks often need off-chain data or complex verification), it represents an attempt to keep the core truth-checking logic within the contract boundaries.
10. **Indexing for Querying:** The `indexedTasksByState` and `indexedTasksByUser` mappings (despite the caveats about removal) are included to demonstrate how a contract might provide view functions to query tasks based on status or participant, which is crucial for dApps built on top of the contract.

This contract, with its multiple states, roles, time-sensitive transitions, staking economics, and built-in dispute/verification layers, goes considerably beyond standard token or simple logic contracts, fulfilling the request for an interesting, advanced, and creative example with over 20 functions.