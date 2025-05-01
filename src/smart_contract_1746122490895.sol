Okay, let's design a smart contract that orchestrates a decentralized collective for verifying the output of off-chain computations, specifically focusing on something trendy like AI model results or proofs. This requires staking mechanisms, a validation game, and a system for task management and rewards.

We'll call it `DecentralizedAICollective`. It won't execute AI *on-chain* (too expensive/impossible), but it will manage tasks, submissions, validation, and rewards for *off-chain* AI work.

**Advanced Concepts Used:**

1.  **Decentralized Task Coordination:** Managing lifecycle of computation tasks requested by users.
2.  **Staking for Participation:** Users stake funds to become 'Nodes' (compute providers) or 'Validators' (result verifiers).
3.  **Decentralized Validation Game:** A mechanism where staked validators vote on the correctness of a submitted result, with rewards/penalties based on consensus.
4.  **Reputation System (Basic):** Tracking success/failure rates for Nodes and Validators.
5.  **State Machine:** Tasks transition through different states (Open, Submission, Validation, Completed, Failed).
6.  **Mechanism Design:** Incentivizing honest participation through stake-weighted rewards and penalties.
7.  **Time-Based Logic:** Using block timestamps for deadlines and cooldowns.
8.  **Pausability:** Standard safety feature.
9.  **Ownership/Admin Control:** For setting parameters (though could be upgraded to DAO governance).

This design avoids duplicating standard tokens (ERC-20, 721), simple DAOs, basic marketplaces, or standard staking pools. The core logic revolves around the validation game for off-chain results.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath can add clarity/safety in complex calculations.

// --- OUTLINE ---
// 1. State Variables & Constants
// 2. Enums & Structs
// 3. Events
// 4. Custom Errors
// 5. Modifiers (Ownable, Pausable)
// 6. Constructor
// 7. Node Management Functions (Stake, Register, Deregister, Update)
// 8. Validator Management Functions (Stake, Register, Deregister, Update)
// 9. Task Management Functions (Create, Claim, Submit, Cancel)
// 10. Validation Game Functions (Submit Vote, Finalize)
// 11. Reward & Withdrawal Functions (Claim Rewards, Withdraw Stake/Fees)
// 12. View/Query Functions
// 13. Admin/Parameter Functions
// 14. Receive/Fallback for ETH

// --- FUNCTION SUMMARY ---
// 1. registerAsNode(): Stake minimum ETH and register as a computation node.
// 2. deregisterNode(): Initiate node deregistration; stake is locked until cooldown.
// 3. updateNodeStake(): Add more ETH to node's stake.
// 4. withdrawNodeStake(): Withdraw stake after deregistration cooldown.
// 5. getNodeDetails(): Get details for a registered node.
// 6. registerAsValidator(): Stake minimum ETH and register as a validator node.
// 7. deregisterValidator(): Initiate validator deregistration; stake is locked.
// 8. updateValidatorStake(): Add more ETH to validator's stake.
// 9. withdrawValidatorStake(): Withdraw stake after validator deregistration cooldown.
// 10. getValidatorDetails(): Get details for a registered validator.
// 11. createTaskRequest(): User pays a fee and defines a computation task request.
// 12. claimTask(): A registered node claims an open task to work on.
// 13. submitTaskResult(): A node submits the hash of the result for a claimed task.
// 14. cancelTaskRequest(): Task creator cancels their task before submission.
// 15. submitValidationVote(): A registered validator votes on the correctness of a submitted result and stakes ETH.
// 16. finalizeTask(): Anyone can call after validation deadline; processes votes, distributes rewards/penalties.
// 17. claimNodeRewards(): Node withdraws earned rewards from completed tasks.
// 18. claimValidatorRewards(): Validator withdraws earned rewards from finalized tasks.
// 19. withdrawTaskRequesterFee(): Requester withdraws fee if task failed or was cancelled before submission.
// 20. getTaskDetails(): Get details for a specific task by ID.
// 21. getTaskSubmissionDetails(): Get details for the submission of a specific task.
// 22. getTaskValidationVoteDetails(): Get details for a specific validator's vote on a task.
// 23. getActiveNodeCount(): Get the total number of active nodes.
// 24. getActiveValidatorCount(): Get the total number of active validators.
// 25. getTotalTaskCount(): Get the total number of tasks created.
// 26. getParameters(): Get current contract parameters (stakes, periods, threshold).
// 27. setMinimumNodeStake(): Admin function to set minimum node stake.
// 28. setMinimumValidatorStake(): Admin function to set minimum validator stake.
// 29. setSubmissionPeriod(): Admin function to set task submission period.
// 30. setValidationPeriod(): Admin function to set task validation period.
// 31. setValidationMajorityThreshold(): Admin function to set validator majority threshold.
// 32. setDeregistrationCooldown(): Admin function to set stake deregistration cooldown.
// 33. rescueFunds(): Admin function to rescue accidentally sent non-stake ETH.

contract DecentralizedAICollective is Ownable, Pausable {
    using SafeMath for uint256; // Although less critical in 0.8+, good practice

    // --- State Variables & Constants ---
    uint256 public minimumNodeStake;
    uint256 public minimumValidatorStake;
    uint256 public taskSubmissionPeriod; // Time window for node to submit result after claiming
    uint256 public taskValidationPeriod; // Time window for validators to vote after submission
    uint256 public validationMajorityThreshold; // Percentage (e.g., 70 for 70%) needed for consensus
    uint256 public deregistrationCooldown; // Time before staked ETH can be withdrawn after deregistering

    uint256 private nextTaskID = 1; // Start task IDs from 1

    // --- Enums & Structs ---

    enum TaskState {
        Open, // Task created, waiting for a node to claim
        Submission, // Task claimed by a node, waiting for result submission
        Validation, // Result submitted, waiting for validators to vote
        Completed, // Task successfully completed and validated
        FailedSubmission, // Node failed to submit result in time
        FailedValidation // Validation failed (e.g., no majority, result incorrect)
    }

    struct Node {
        address owner;
        uint256 stake;
        uint256 reputation; // Simple success counter
        bool isActive; // Can claim tasks/earn rewards
        uint256 deregistrationCooldownEnd; // Timestamp when stake can be withdrawn
        uint256 rewards; // Accumulated rewards
    }

    struct Validator {
        address owner;
        uint256 stake;
        uint256 reputation; // Simple success counter
        bool isActive; // Can submit validation votes
        uint256 deregistrationCooldownEnd; // Timestamp when stake can be withdrawn
        uint256 rewards; // Accumulated rewards
    }

    struct TaskRequest {
        uint256 taskID;
        address requester;
        uint256 fee; // Fee paid by requester, distributed as rewards
        bytes32 taskParametersHash; // Hash representing task details (e.g., dataset, model hash)
        TaskState state;
        uint256 createdAt;
        address claimedByNode; // Node that claimed the task
        uint256 submissionDeadline; // Deadline for node submission
        bytes32 resultHash; // Hash of the result submitted by the node
        uint256 submittedAt; // Timestamp of submission
        uint256 validationDeadline; // Deadline for validators to vote
        uint256 totalCorrectStake; // Total stake of validators voting Correct
        uint256 totalIncorrectStake; // Total stake of validators voting Incorrect
        bool validationMajorityAchieved; // Whether a consensus majority was reached
        bool validationResult; // True if validated as Correct, False if Incorrect (only if majority achieved)
    }

    struct ValidationVote {
        address validatorAddress;
        uint256 stake; // Stake specifically for this vote
        bool vote; // True for Correct, False for Incorrect
        bool processed; // True once vote counted in finalization
    }

    // --- Mappings ---
    mapping(address => Node) public nodes;
    mapping(address => Validator) public validators;
    mapping(uint256 => TaskRequest) public tasks;
    // Mapping: taskID => validatorAddress => ValidationVote
    mapping(uint256 => mapping(address => ValidationVote)) private taskValidationVotes;
    // Need a way to iterate over validators who voted on a task for finalization
    mapping(uint256 => address[]) private taskVoters;

    uint256 private activeNodeCount = 0;
    uint256 private activeValidatorCount = 0;

    // --- Events ---
    event NodeRegistered(address indexed nodeAddress, uint256 stake);
    event NodeDeregistered(address indexed nodeAddress);
    event NodeStakeUpdated(address indexed nodeAddress, uint256 newStake);
    event NodeRewardsClaimed(address indexed nodeAddress, uint256 amount);
    event NodeStakeWithdrawn(address indexed nodeAddress, uint256 amount);

    event ValidatorRegistered(address indexed validatorAddress, uint256 stake);
    event ValidatorDeregistered(address indexed validatorAddress);
    event ValidatorStakeUpdated(address indexed validatorAddress, uint256 newStake);
    event ValidatorRewardsClaimed(address indexed validatorAddress, uint256 amount);
    event ValidatorStakeWithdrawn(address indexed validatorAddress, uint256 amount);

    event TaskRequestCreated(uint256 indexed taskID, address indexed requester, uint256 fee, bytes32 taskParametersHash);
    event TaskClaimed(uint256 indexed taskID, address indexed nodeAddress, uint256 submissionDeadline);
    event TaskResultSubmitted(uint256 indexed taskID, address indexed nodeAddress, bytes32 resultHash, uint256 validationDeadline);
    event TaskRequestCancelled(uint256 indexed taskID, address indexed requester);
    event TaskFinalized(uint256 indexed taskID, TaskState finalState, bool success, uint256 rewardsDistributed);

    event ValidationVoteSubmitted(uint256 indexed taskID, address indexed validatorAddress, bool vote, uint256 stake);
    event ValidationResultDetermined(uint256 indexed taskID, bool majorityAchieved, bool result);

    // --- Custom Errors ---
    error NotEnoughStake(uint256 required, uint256 provided);
    error AlreadyRegistered();
    error NotRegistered();
    error StakeLocked(uint256 unlockTime);
    error NothingToWithdraw();
    error TaskNotFound();
    error TaskNotInOpenState();
    error TaskNotInSubmissionState();
    error TaskNotInValidationState();
    error TaskNotClaimedByYou();
    error TaskAlreadyClaimed();
    error SubmissionPeriodPassed();
    error ResultAlreadySubmitted();
    error NotActiveNode();
    error NotActiveValidator();
    error AlreadyVoted();
    error ValidationPeriodNotStarted();
    error ValidationPeriodPassed();
    error TaskNotFinalized();
    error NothingToClaim();
    error TaskNotFailedOrCancelled();
    error InsufficientFunds(uint256 required, uint256 available);
    error DeregistrationPeriodNotPassed();
    error CannotCancelClaimedTask();

    // --- Constructor ---
    constructor(
        uint256 _minimumNodeStake,
        uint256 _minimumValidatorStake,
        uint256 _taskSubmissionPeriod,
        uint256 _taskValidationPeriod,
        uint256 _validationMajorityThreshold, // e.g., 70 for 70%
        uint256 _deregistrationCooldown // in seconds
    ) Ownable(msg.sender) {
        minimumNodeStake = _minimumNodeStake;
        minimumValidatorStake = _minimumValidatorStake;
        taskSubmissionPeriod = _taskSubmissionPeriod;
        taskValidationPeriod = _taskValidationPeriod;
        validationMajorityThreshold = _validationMajorityThreshold;
        deregistrationCooldown = _deregistrationCooldown;
    }

    // --- Node Management Functions ---

    /// @notice Stakes minimum ETH and registers caller as a computation node.
    /// @dev Requires minimumNodeStake to be sent with the transaction.
    function registerAsNode() external payable whenNotPaused {
        if (nodes[msg.sender].isActive) revert AlreadyRegistered();
        if (msg.value < minimumNodeStake) revert NotEnoughStake(minimumNodeStake, msg.value);

        nodes[msg.sender] = Node({
            owner: msg.sender,
            stake: msg.value,
            reputation: 0,
            isActive: true,
            deregistrationCooldownEnd: 0,
            rewards: 0
        });
        activeNodeCount++;
        emit NodeRegistered(msg.sender, msg.value);
    }

    /// @notice Initiates deregistration for a node. Stake is locked until cooldown passes.
    function deregisterNode() external whenNotPaused {
        Node storage node = nodes[msg.sender];
        if (!node.isActive) revert NotRegistered();

        node.isActive = false;
        node.deregistrationCooldownEnd = block.timestamp + deregistrationCooldown;
        activeNodeCount--;
        emit NodeDeregistered(msg.sender);
    }

    /// @notice Adds more ETH to an existing node's stake.
    /// @dev Can be called by active or inactive nodes during cooldown.
    function updateNodeStake() external payable whenNotPaused {
        Node storage node = nodes[msg.sender];
        if (node.owner == address(0)) revert NotRegistered(); // Ensure exists

        node.stake = node.stake.add(msg.value);
        emit NodeStakeUpdated(msg.sender, node.stake);
    }

    /// @notice Withdraws stake after a node has deregistered and cooldown passed.
    function withdrawNodeStake() external whenNotPaused {
        Node storage node = nodes[msg.sender];
        if (node.owner == address(0)) revert NotRegistered();
        if (node.isActive) revert StakeLocked(0); // Cannot withdraw if still active
        if (block.timestamp < node.deregistrationCooldownEnd) revert DeregistrationPeriodNotPassed();
        if (node.stake == 0) revert NothingToWithdraw();

        uint256 amount = node.stake;
        node.stake = 0;
        // Clean up the node entry slightly, though stake = 0 is main indicator
        node.deregistrationCooldownEnd = 0; // Reset cooldown

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit NodeStakeWithdrawn(msg.sender, amount);
    }

    /// @notice Gets details for a registered node.
    /// @param nodeAddress The address of the node.
    /// @return Node struct details.
    function getNodeDetails(address nodeAddress) external view returns (Node memory) {
        return nodes[nodeAddress];
    }

    // --- Validator Management Functions ---

    /// @notice Stakes minimum ETH and registers caller as a validator node.
    /// @dev Requires minimumValidatorStake to be sent with the transaction.
    function registerAsValidator() external payable whenNotPaused {
        if (validators[msg.sender].isActive) revert AlreadyRegistered();
        if (msg.value < minimumValidatorStake) revert NotEnoughStake(minimumValidatorStake, msg.value);

        validators[msg.sender] = Validator({
            owner: msg.sender,
            stake: msg.value,
            reputation: 0,
            isActive: true,
            deregistrationCooldownEnd: 0,
            rewards: 0
        });
        activeValidatorCount++;
        emit ValidatorRegistered(msg.sender, msg.value);
    }

    /// @notice Initiates deregistration for a validator. Stake is locked until cooldown passes.
    function deregisterValidator() external whenNotPaused {
        Validator storage validator = validators[msg.sender];
        if (!validator.isActive) revert NotRegistered();

        validator.isActive = false;
        validator.deregistrationCooldownEnd = block.timestamp + deregistrationCooldown;
        activeValidatorCount--;
        emit ValidatorDeregistered(msg.sender);
    }

    /// @notice Adds more ETH to an existing validator's stake.
    /// @dev Can be called by active or inactive validators during cooldown.
    function updateValidatorStake() external payable whenNotPaused {
        Validator storage validator = validators[msg.sender];
        if (validator.owner == address(0)) revert NotRegistered(); // Ensure exists

        validator.stake = validator.stake.add(msg.value);
        emit ValidatorStakeUpdated(msg.sender, validator.stake);
    }

    /// @notice Withdraws stake after a validator has deregistered and cooldown passed.
    function withdrawValidatorStake() external whenNotPaused {
        Validator storage validator = validators[msg.sender];
        if (validator.owner == address(0)) revert NotRegistered();
        if (validator.isActive) revert StakeLocked(0); // Cannot withdraw if still active
        if (block.timestamp < validator.deregistrationCooldownEnd) revert DeregistrationPeriodNotPassed();
        if (validator.stake == 0) revert NothingToWithdraw();

        uint256 amount = validator.stake;
        validator.stake = 0;
        // Clean up slightly
        validator.deregistrationCooldownEnd = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ValidatorStakeWithdrawn(msg.sender, amount);
    }

     /// @notice Gets details for a registered validator.
    /// @param validatorAddress The address of the validator.
    /// @return Validator struct details.
    function getValidatorDetails(address validatorAddress) external view returns (Validator memory) {
        return validators[validatorAddress];
    }


    // --- Task Management Functions ---

    /// @notice Creates a new computation task request.
    /// @dev Caller pays the task fee.
    /// @param _taskParametersHash A hash representing the task details (e.g., link to dataset, model requirements).
    /// @return taskID The ID of the newly created task.
    function createTaskRequest(bytes32 _taskParametersHash) external payable whenNotPaused returns (uint256 taskID) {
        taskID = nextTaskID++;
        tasks[taskID] = TaskRequest({
            taskID: taskID,
            requester: msg.sender,
            fee: msg.value,
            taskParametersHash: _taskParametersHash,
            state: TaskState.Open,
            createdAt: block.timestamp,
            claimedByNode: address(0),
            submissionDeadline: 0,
            resultHash: 0,
            submittedAt: 0,
            validationDeadline: 0,
            totalCorrectStake: 0,
            totalIncorrectStake: 0,
            validationMajorityAchieved: false,
            validationResult: false
        });

        emit TaskRequestCreated(taskID, msg.sender, msg.value, _taskParametersHash);
    }

    /// @notice A registered node claims an open task to perform the computation.
    /// @param _taskID The ID of the task to claim.
    function claimTask(uint256 _taskID) external whenNotPaused {
        TaskRequest storage task = tasks[_taskID];
        if (task.taskID == 0) revert TaskNotFound();
        if (task.state != TaskState.Open) revert TaskNotInOpenState();

        Node storage node = nodes[msg.sender];
        if (!node.isActive) revert NotActiveNode();

        task.claimedByNode = msg.sender;
        task.submissionDeadline = block.timestamp + taskSubmissionPeriod;
        task.state = TaskState.Submission;

        emit TaskClaimed(_taskID, msg.sender, task.submissionDeadline);
    }

    /// @notice The node that claimed a task submits the hash of the result.
    /// @param _taskID The ID of the task.
    /// @param _resultHash The hash of the computation result.
    function submitTaskResult(uint256 _taskID, bytes32 _resultHash) external whenNotPaused {
        TaskRequest storage task = tasks[_taskID];
        if (task.taskID == 0) revert TaskNotFound();
        if (task.state != TaskState.Submission) revert TaskNotInSubmissionState();
        if (task.claimedByNode != msg.sender) revert TaskNotClaimedByYou();
        if (block.timestamp > task.submissionDeadline) {
            // Node failed to submit, mark task as failed
            task.state = TaskState.FailedSubmission;
            // Optionally penalize the node here, or handle it in finalizeTask if applicable
            emit TaskFinalized(_taskID, TaskState.FailedSubmission, false, 0);
            revert SubmissionPeriodPassed();
        }
        if (task.resultHash != 0) revert ResultAlreadySubmitted(); // Should not happen with state check, but safety

        task.resultHash = _resultHash;
        task.submittedAt = block.timestamp;
        task.validationDeadline = block.timestamp + taskValidationPeriod;
        task.state = TaskState.Validation;

        emit TaskResultSubmitted(_taskID, msg.sender, _resultHash, task.validationDeadline);
    }

    /// @notice The task creator can cancel their task if it hasn't been claimed yet.
    /// @param _taskID The ID of the task to cancel.
    function cancelTaskRequest(uint256 _taskID) external whenNotPaused {
        TaskRequest storage task = tasks[_taskID];
        if (task.taskID == 0) revert TaskNotFound();
        if (task.requester != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Reuse Ownable error for unauthorized access
        if (task.state != TaskState.Open) revert CannotCancelClaimedTask();

        // Set state to failed/cancelled so fee can be withdrawn
        task.state = TaskState.FailedSubmission; // Using FailedSubmission state for cancellation before submission
        emit TaskRequestCancelled(_taskID, msg.sender);
        emit TaskFinalized(_taskID, TaskState.FailedSubmission, false, 0); // Indicate finalization for fee withdrawal
    }

    // --- Validation Game Functions ---

    /// @notice A registered validator submits their vote on the correctness of a submitted task result.
    /// @dev Requires validator stake to be sent with the transaction.
    /// @param _taskID The ID of the task being validated.
    /// @param _vote True for Correct, False for Incorrect.
    function submitValidationVote(uint256 _taskID, bool _vote) external payable whenNotPaused {
        TaskRequest storage task = tasks[_taskID];
        if (task.taskID == 0) revert TaskNotFound();
        if (task.state != TaskState.Validation) revert TaskNotInValidationState();
        if (block.timestamp < task.submittedAt) revert ValidationPeriodNotStarted(); // Should not happen if state is Validation
        if (block.timestamp > task.validationDeadline) revert ValidationPeriodPassed();

        Validator storage validator = validators[msg.sender];
        if (!validator.isActive) revert NotActiveValidator();
        if (msg.value == 0) revert NotEnoughStake(1, 0); // Require at least 1 wei staked on the vote

        // Check if validator already voted on this task
        if (taskValidationVotes[_taskID][msg.sender].validatorAddress != address(0)) revert AlreadyVoted();

        taskValidationVotes[_taskID][msg.sender] = ValidationVote({
            validatorAddress: msg.sender,
            stake: msg.value,
            vote: _vote,
            processed: false
        });
        taskVoters[_taskID].push(msg.sender); // Track voters for finalization

        if (_vote) {
            task.totalCorrectStake = task.totalCorrectStake.add(msg.value);
        } else {
            task.totalIncorrectStake = task.totalIncorrectStake.add(msg.value);
        }

        emit ValidationVoteSubmitted(_taskID, msg.sender, _vote, msg.value);
    }

    /// @notice Finalizes a task after the validation period ends. Calculates consensus and distributes rewards/penalties.
    /// @dev Can be called by anyone after the validation deadline.
    /// @param _taskID The ID of the task to finalize.
    function finalizeTask(uint256 _taskID) external whenNotPaused {
        TaskRequest storage task = tasks[_taskID];
        if (task.taskID == 0) revert TaskNotFound();
        if (task.state != TaskState.Validation) {
            // Allow finalization if submission period passed without submission
            if (task.state == TaskState.Submission && block.timestamp > task.submissionDeadline) {
                 task.state = TaskState.FailedSubmission;
                 emit TaskFinalized(_taskID, TaskState.FailedSubmission, false, 0);
                 return; // Finalized as failed submission
            }
             revert TaskNotInValidationState(); // Otherwise, wrong state
        }

        if (block.timestamp <= task.validationDeadline) revert StakeLocked(task.validationDeadline); // Can't finalize before deadline

        uint256 totalValidationStake = task.totalCorrectStake.add(task.totalIncorrectStake);
        bool majorityAchieved = false;
        bool finalResult = false; // Default to incorrect
        uint256 rewardPool = task.fee; // Start reward pool with task fee

        if (totalValidationStake > 0) {
            uint256 correctPercentage = task.totalCorrectStake.mul(100).div(totalValidationStake);
            uint256 incorrectPercentage = task.totalIncorrectStake.mul(100).div(totalValidationStake);

            if (correctPercentage >= validationMajorityThreshold) {
                majorityAchieved = true;
                finalResult = true; // Correct majority
                // Winning validators (Correct) split reward pool
                rewardPool = rewardPool.add(task.totalIncorrectStake); // Add stake from incorrect voters to pool
            } else if (incorrectPercentage >= validationMajorityThreshold) {
                majorityAchieved = true;
                finalResult = false; // Incorrect majority
                // Winning validators (Incorrect) split stake from correct voters
                rewardPool = rewardPool.add(task.totalCorrectStake); // Add stake from correct voters to pool
                // Task fee is not paid to node/incorrect validators, remains in contract or returned
                // For simplicity, let's add it to the incorrect validators' pool or burn it.
                // Adding it to the incorrect validators' pool incentivizes finding errors.
            }
            // If no majority, task fails validation, no rewards from stake penalties or fee distribution
            // Staked validation ETH is returned to voters in proportion to their vote stake.
        }
        // If totalValidationStake is 0, task fails validation due to lack of votes. Task fee is claimable by requester.

        task.validationMajorityAchieved = majorityAchieved;
        task.validationResult = finalResult;

        // Distribute rewards/penalties
        if (majorityAchieved) {
             address[] memory voters = taskVoters[_taskID];
             uint256 winningStake = finalResult ? task.totalCorrectStake : task.totalIncorrectStake;

             for (uint i = 0; i < voters.length; i++) {
                 address voterAddress = voters[i];
                 ValidationVote storage vote = taskValidationVotes[_taskID][voterAddress];

                 if (vote.processed) continue; // Should not happen, but safety

                 if (vote.vote == finalResult) {
                     // Winning validator gets their stake back + share of reward pool
                     uint256 validatorReward = rewardPool.mul(vote.stake).div(winningStake);
                     validators[voterAddress].rewards = validators[voterAddress].rewards.add(vote.stake).add(validatorReward);
                     validators[voterAddress].reputation = validators[voterAddress].reputation.add(1);
                 } else {
                     // Losing validator stake is added to the reward pool (already done) and they get nothing back.
                     // Their reputation is not increased.
                 }
                 vote.processed = true; // Mark vote as processed
             }

             // Reward the node if task result was validated as Correct
             if (finalResult) {
                 nodes[task.claimedByNode].rewards = nodes[task.claimedByNode].rewards.add(task.fee); // Node gets the initial task fee
                 nodes[task.claimedByNode].reputation = nodes[task.claimedByNode].reputation.add(1);
                 task.state = TaskState.Completed;
                 emit TaskFinalized(_taskID, TaskState.Completed, true, task.fee.add(totalValidationStake)); // Report total distributed including staked penalties
             } else {
                 // Node submitted an incorrect result
                 // Node is penalized (no reward, potential future slashing logic could be added)
                 nodes[task.claimedByNode].reputation = nodes[task.claimedByNode].reputation > 0 ? nodes[task.claimedByNode].reputation.sub(1) : 0; // Simple reputation decrease
                 task.state = TaskState.FailedValidation;
                  emit TaskFinalized(_taskID, TaskState.FailedValidation, false, totalValidationStake); // Report total distributed to incorrect validators
             }

        } else {
             // No majority, task fails validation
             // Return staked ETH to ALL validators
             address[] memory voters = taskVoters[_taskID];
             for (uint i = 0; i < voters.length; i++) {
                 address voterAddress = voters[i];
                 ValidationVote storage vote = taskValidationVotes[_taskID][voterAddress];
                 if (!vote.processed) {
                      validators[voterAddress].rewards = validators[voterAddress].rewards.add(vote.stake); // Return their stake
                      vote.processed = true;
                 }
             }
             // Task fee is claimable by the requester
             task.state = TaskState.FailedValidation; // Consider a specific state like NoConsensus or simply FailedValidation
             emit TaskFinalized(_taskID, TaskState.FailedValidation, false, totalValidationStake); // Report total returned stake
        }

        emit ValidationResultDetermined(_taskID, majorityAchieved, finalResult);

        // Clear temporary voters list (optional, saves gas on future lookups but costs now)
        delete taskVoters[_taskID];
    }


    // --- Reward & Withdrawal Functions ---

    /// @notice Allows a node to claim their accumulated rewards.
    function claimNodeRewards() external whenNotPaused {
        Node storage node = nodes[msg.sender];
        if (node.owner == address(0) || node.rewards == 0) revert NothingToClaim();

        uint256 amount = node.rewards;
        node.rewards = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit NodeRewardsClaimed(msg.sender, amount);
    }

     /// @notice Allows a validator to claim their accumulated rewards (including returned vote stakes).
    function claimValidatorRewards() external whenNotPaused {
        Validator storage validator = validators[msg.sender];
        if (validator.owner == address(0) || validator.rewards == 0) revert NothingToClaim();

        uint256 amount = validator.rewards;
        validator.rewards = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ValidatorRewardsClaimed(msg.sender, amount);
    }

    /// @notice Allows the task requester to withdraw their fee if the task failed (submission or validation) or was cancelled.
    /// @param _taskID The ID of the task.
    function withdrawTaskRequesterFee(uint256 _taskID) external whenNotPaused {
        TaskRequest storage task = tasks[_taskID];
        if (task.taskID == 0) revert TaskNotFound();
        if (task.requester != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        // Allow withdrawal only if task is in a failed state where the fee was not distributed
        if (task.state != TaskState.FailedSubmission && task.state != TaskState.FailedValidation) {
            revert TaskNotFailedOrCancelled();
        }

        // Fee is only reclaimable if validation didn't happen or failed without majority (fee wasn't paid to node)
        // If it failed validation *with* incorrect majority, fee went to validators.
        // We need to check if the fee was ever distributed. A simple flag or checking task state suffices based on finalization logic.
        // In our finalizeTask logic, the fee is only given to the node if validationResult is true.
        // If state is FailedSubmission or FailedValidation (and not Completed), fee was not distributed to node.
         if (task.state == TaskState.FailedValidation && task.validationMajorityAchieved && !task.validationResult) {
             // Fee was added to Incorrect validators pool. Requesters cannot withdraw.
             revert TaskNotFailedOrCancelled(); // Use the same error, indicates fee is not available for withdrawal by requester
         }


        uint256 feeAmount = task.fee;
        if (feeAmount == 0) revert NothingToWithdraw();

        // Mark fee as withdrawn (can set fee to 0 or use a flag)
        task.fee = 0;

        (bool success, ) = payable(msg.sender).call{value: feeAmount}("");
        require(success, "ETH transfer failed");

        // Task state remains FailedSubmission/FailedValidation, fee is zeroed out
    }


    // --- View/Query Functions ---

    /// @notice Gets details for a specific task by ID.
    /// @param _taskID The ID of the task.
    /// @return TaskRequest struct details.
    function getTaskDetails(uint256 _taskID) external view returns (TaskRequest memory) {
        if (tasks[_taskID].taskID == 0 && _taskID != 0) revert TaskNotFound(); // Ensure _taskID 0 returns empty struct
        return tasks[_taskID];
    }

    /// @notice Gets submission details for a specific task.
    /// @param _taskID The ID of the task.
    /// @return nodeAddress Address of the submitting node.
    /// @return resultHash Hash of the result.
    /// @return submittedAt Timestamp of submission.
    function getTaskSubmissionDetails(uint256 _taskID) external view returns (address nodeAddress, bytes32 resultHash, uint256 submittedAt) {
         if (tasks[_taskID].taskID == 0) revert TaskNotFound();
         TaskRequest storage task = tasks[_taskID];
         return (task.claimedByNode, task.resultHash, task.submittedAt);
    }

    /// @notice Gets validation vote details for a specific validator on a task.
    /// @param _taskID The ID of the task.
    /// @param _validatorAddress The address of the validator.
    /// @return stake Stake amount for this vote.
    /// @return vote True for Correct, False for Incorrect.
    /// @return processed Whether the vote has been processed in finalization.
    function getTaskValidationVoteDetails(uint256 _taskID, address _validatorAddress) external view returns (uint256 stake, bool vote, bool processed) {
         if (tasks[_taskID].taskID == 0) revert TaskNotFound(); // Task must exist
         ValidationVote storage vVote = taskValidationVotes[_taskID][_validatorAddress];
         // Return default values if validator hasn't voted on this task (stake will be 0)
         return (vVote.stake, vVote.vote, vVote.processed);
    }


    /// @notice Gets the current count of active nodes.
    function getActiveNodeCount() external view returns (uint256) {
        return activeNodeCount;
    }

    /// @notice Gets the current count of active validators.
    function getActiveValidatorCount() external view returns (uint256) {
        return activeValidatorCount;
    }

    /// @notice Gets the total number of tasks ever created.
    function getTotalTaskCount() external view returns (uint256) {
        return nextTaskID.sub(1); // nextTaskID is always 1 greater than the last created ID
    }

    /// @notice Gets the current contract parameters.
    /// @return _minimumNodeStake Minimum stake for nodes.
    /// @return _minimumValidatorStake Minimum stake for validators.
    /// @return _taskSubmissionPeriod Submission period for tasks.
    /// @return _taskValidationPeriod Validation period for tasks.
    /// @return _validationMajorityThreshold Majority percentage for validation consensus.
    /// @return _deregistrationCooldown Deregistration cooldown period.
    function getParameters() external view returns (uint256 _minimumNodeStake, uint256 _minimumValidatorStake, uint256 _taskSubmissionPeriod, uint256 _taskValidationPeriod, uint256 _validationMajorityThreshold, uint256 _deregistrationCooldown) {
        return (minimumNodeStake, minimumValidatorStake, taskSubmissionPeriod, taskValidationPeriod, validationMajorityThreshold, deregistrationCooldown);
    }

    // --- Admin/Parameter Functions ---

    /// @notice Admin function to set the minimum stake required for nodes.
    /// @param _minimumNodeStake The new minimum stake amount.
    function setMinimumNodeStake(uint256 _minimumNodeStake) external onlyOwner {
        minimumNodeStake = _minimumNodeStake;
    }

    /// @notice Admin function to set the minimum stake required for validators.
    /// @param _minimumValidatorStake The new minimum stake amount.
    function setMinimumValidatorStake(uint256 _minimumValidatorStake) external onlyOwner {
        minimumValidatorStake = _minimumValidatorStake;
    }

    /// @notice Admin function to set the period for task submission after claiming.
    /// @param _taskSubmissionPeriod The new submission period in seconds.
    function setSubmissionPeriod(uint256 _taskSubmissionPeriod) external onlyOwner {
        taskSubmissionPeriod = _taskSubmissionPeriod;
    }

    /// @notice Admin function to set the period for validator voting after submission.
    /// @param _taskValidationPeriod The new validation period in seconds.
    function setValidationPeriod(uint256 _taskValidationPeriod) external onlyOwner {
        taskValidationPeriod = _taskValidationPeriod;
    }

    /// @notice Admin function to set the percentage of stake required for validation consensus.
    /// @param _validationMajorityThreshold The new threshold percentage (e.g., 70 for 70%).
    function setValidationMajorityThreshold(uint256 _validationMajorityThreshold) external onlyOwner {
        require(_validationMajorityThreshold <= 100, "Threshold cannot exceed 100%");
        validationMajorityThreshold = _validationMajorityThreshold;
    }

    /// @notice Admin function to set the cooldown period after deregistration before stake can be withdrawn.
    /// @param _deregistrationCooldown The new cooldown period in seconds.
    function setDeregistrationCooldown(uint256 _deregistrationCooldown) external onlyOwner {
        deregistrationCooldown = _deregistrationCooldown;
    }

     /// @notice Admin function to withdraw accidentally sent ETH (not associated with stakes or task fees).
    /// @param _amount The amount to withdraw.
    /// @param _recipient The address to send the ETH to.
    function rescueFunds(uint256 _amount, address payable _recipient) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        // This rescue function is complex to get right if contract holds stakes and fees.
        // A simple balance check is not sufficient as it could withdraw staked funds.
        // A safer approach requires tracking contract ETH not tied to any active stake or task.
        // A basic version could allow withdrawing *excess* ETH above sum of all known stakes/fees,
        // but that's complex to calculate accurately on-chain.
        // A simpler (less safe) approach is to allow withdrawing up to contract balance,
        // relying on admin not to abuse it or accidentally withdraw locked funds.
        // For this example, we'll use the simpler approach, but flag the risk.
        // A more robust system would track unbound ETH separately or use a dedicated rescue vault.

        // WARNING: This simplistic rescue could potentially withdraw ETH currently staked
        // or held as task fees if called carelessly by the owner.
        // A real production system needs a more sophisticated way to track 'rescueable' funds.
        require(address(this).balance >= _amount, "Insufficient contract balance for rescue");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }


    // --- Receive/Fallback ---

    /// @notice Allows receiving ETH for staking and task fees.
    /// @dev This function is triggered when ETH is sent without data.
    receive() external payable {
        // This allows users to send ETH for staking/task fees, which is handled by specific functions.
        // Sending ETH directly without calling a function is typically for registration or updating stake.
        // The registration/update functions check msg.value, so this receive allows that first step.
        // Alternatively, we could disallow bare sends and force users to call updateStake etc.
        // Allowing bare sends is simpler UX for adding to stake.
    }

    // fallback() external payable {} // Not needed if receive() is present and handles all bare ETH sends.


    // --- Internal Helper Functions ---
    // (None strictly necessary for this structure, logic is inline)

}
```

---

**Explanation of Key Concepts and Design Choices:**

1.  **Staking (`registerAsNode`, `registerAsValidator`, `updateNodeStake`, `updateValidatorStake`):** Participants must stake ETH (could be replaced with an ERC-20 token) to gain eligibility. This stake acts as collateral, which can be penalized.
2.  **Task Lifecycle (`createTaskRequest`, `claimTask`, `submitTaskResult`, `finalizeTask`):** Tasks move through defined states, managed by deadlines. This provides structure to the off-chain work process.
3.  **Decentralized Validation Game (`submitValidationVote`, `finalizeTask`):**
    *   Validators stake ETH *per vote*. This vote stake is separate from their main validator stake and is committed to their chosen outcome.
    *   `finalizeTask` is the core of the game. It determines the consensus (if any) based on the *total stake* behind each vote (Correct vs. Incorrect), not just the number of voters.
    *   Winning validators (those whose vote matches the majority) get their vote stake back *plus* a share of the reward pool.
    *   Losing validators (those whose vote contradicts the majority) lose their vote stake; this stake is added to the reward pool for winners.
    *   If no majority is reached, all validators get their vote stake back, and the task fails validation.
4.  **Reward Distribution (`finalizeTask`, `claimNodeRewards`, `claimValidatorRewards`, `withdrawTaskRequesterFee`):**
    *   The task requester's fee primarily rewards the Node *if* their result is validated as correct.
    *   Validators are rewarded from the task fee (if they are in the winning majority and the task was ultimately correct) and potentially from the vote stakes of losing validators.
    *   Rewards are accumulated in the `rewards` balance and must be explicitly claimed.
    *   The requester can reclaim their fee only if the task failed *before* validation or failed validation *without* an incorrect majority consensus (meaning the fee wasn't distributed).
5.  **Reputation (`reputation` counter):** A basic counter tracking successful contributions (submitting correct results for nodes, voting with the majority for validators). This could be expanded into a more sophisticated weighted system.
6.  **Cooldown (`deregisterCooldown`, `withdrawNodeStake`, `withdrawValidatorStake`):** A period after deregistering before stake can be withdrawn, mitigating some risks like participants immediately withdrawing stake after causing issues.
7.  **Error Handling:** Using custom errors makes debugging clearer and saves gas compared to string reverts in some cases.
8.  **Pausability:** Standard OpenZeppelin `Pausable` is included for emergency pauses.
9.  **Ownable:** Standard OpenZeppelin `Ownable` for administrative control over parameters. This could be replaced with a DAO structure for true decentralization.

This contract provides a framework for coordinating off-chain work that requires verification, using economic incentives and a staking/validation game to ensure integrity without running the computationally expensive part (like AI model inference or training) on the blockchain itself.