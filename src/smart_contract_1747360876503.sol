Okay, let's create a smart contract that implements a Decentralized AI Oracle, focusing on bringing off-chain AI model inference results onto the blockchain in a decentralized and verifiable manner.

This contract will allow users to request specific AI tasks (e.g., sentiment analysis of a text, image classification result hash, prediction probability), AI providers to stake collateral and submit their results, and the contract to use a consensus mechanism (e.g., median for numerical, majority for others) to validate results, rewarding accurate providers and slashing inaccurate ones.

This concept is advanced as it deals with off-chain computation verification, incentivization, and a rudimentary consensus mechanism within the contract. It's trendy due to the focus on AI integration and decentralized oracles. It won't be a direct copy of standard Chainlink oracle patterns or basic token/DeFi contracts.

---

**Smart Contract Outline & Function Summary: `DecentralizedAIOracle`**

**Concept:** A decentralized oracle network specializing in bringing off-chain AI model inference results onto the blockchain. Users request AI tasks, staked providers perform computation off-chain and submit results on-chain. The contract validates results via consensus, distributing rewards and slashing stakes based on accuracy.

**Modules:**
1.  **Core Infrastructure:** Ownable, Pausable.
2.  **Provider Management:** Registration, staking, deactivation, reputation.
3.  **Task Management:** Requesting tasks, specifying requirements, viewing status.
4.  **Submission & Consensus:** Providers submitting results, contract aggregating and validating results, finalization.
5.  **Reward & Slashing:** Distributing user rewards, slashing inaccurate providers, managing protocol fees.
6.  **Configuration:** Setting parameters (stakes, fees, periods, thresholds).
7.  **Viewing & Utility:** Getting contract state, provider info, task details, results.

**Function Summary (20+ Functions):**

**Provider Management:**
1.  `registerProvider()`: Registers a new address as an AI provider, requires initial stake.
2.  `deregisterProvider()`: Deregisters a provider, initiating stake withdrawal (subject to safety period).
3.  `topUpProviderStake(address provider)`: Allows a provider (or anyone on their behalf) to increase their stake.
4.  `initiateStakeWithdraw(uint256 amount)`: Provider requests to withdraw a portion of their stake, starts a withdrawal timer.
5.  `completeStakeWithdraw()`: Provider completes the withdrawal after the safety period expires.
6.  `deactivateProvider()`: Temporarily prevents a provider from being assigned or submitting to *new* tasks.
7.  `activateProvider()`: Re-activates a deactivated provider.
8.  `getProviderInfo(address provider)`: View details of a provider (stake, reputation, status).
9.  `getProviderStake(address provider)`: View current staked amount for a provider.
10. `getProviderReputation(address provider)`: View current reputation score for a provider.

**Task Management:**
11. `requestTask(string memory taskType, bytes memory taskInput, uint256 minProviders, uint256 requiredStakePerProvider, uint256 rewardPerProvider, uint256 submissionPeriod, uint256 revealPeriod)`: User requests an AI task, specifying parameters and providing reward/stake funds.
12. `cancelTaskRequest(uint256 taskId)`: User cancels a task request before submissions are finalized (funds returned with penalty).
13. `getTaskDetails(uint256 taskId)`: View all parameters and current status of a specific task.
14. `getUserTasks(address user)`: List tasks requested by a specific user.
15. `getTaskResult(uint256 taskId)`: Retrieve the final, validated result for a completed task.

**Submission & Consensus:**
16. `submitTaskResult(uint256 taskId, bytes memory resultData)`: Provider submits their computed result for a specific task. Requires provider stake and matching task requirements.
17. `getTaskSubmissions(uint256 taskId)`: View all submitted results for a task (might return hashes or limited info for privacy before reveal).
18. `triggerTaskFinalization(uint256 taskId)`: Anyone can call this after the submission period to initiate result consensus, reward distribution, and slashing.

**Configuration (Owner Only):**
19. `setMinimumProviderStake(uint256 amount)`: Sets the minimum required stake for new providers.
20. `setProtocolFeeRate(uint256 rate)`: Sets the percentage fee taken by the protocol from task rewards.
21. `setWithdrawalSafetyPeriod(uint256 seconds)`: Sets the delay before withdrawn stake can be claimed.
22. `setConsensusThresholdNumerical(uint256 percentage)`: Sets the allowed percentage deviation for numerical results to be considered in consensus.
23. `setConsensusThresholdCategorical(uint256 minMajorityPercentage)`: Sets the minimum percentage of providers required for a majority consensus on non-numerical results.
24. `withdrawProtocolFees(address recipient)`: Owner withdraws accumulated protocol fees.
25. `pauseContract()`: Pauses core functionality (task requests, submissions, finalization).
26. `unpauseContract()`: Unpauses the contract.

**Viewing & Utility:**
27. `isProvider(address provider)`: Checks if an address is a registered provider.
28. `getTaskCount()`: Returns the total number of tasks requested.
29. `getProviderCount()`: Returns the total number of registered providers.
30. `getProtocolFees()`: Returns the total accumulated protocol fees available for withdrawal.
31. `getMinimumProviderStake()`: Gets the current minimum provider stake requirement.
32. `getProtocolFeeRate()`: Gets the current protocol fee percentage.
33. `getWithdrawalSafetyPeriod()`: Gets the current stake withdrawal delay.

*(Note: Some internal helper functions like `_evaluateSubmissions` and `_distributeRewardsAndSlash` are implied but not listed as external API functions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Could potentially use ERC20 for staking/rewards

/**
 * @title DecentralizedAIOracle
 * @dev A smart contract for a decentralized AI oracle network.
 * Users request AI tasks, providers submit results, consensus validates,
 * and rewards/slashes are distributed.
 */
contract DecentralizedAIOracle is Ownable, Pausable, ReentrancyGuard {

    // --- Structs and Enums ---

    enum ProviderStatus {
        Inactive,       // Not registered
        Active,         // Registered and accepting/submitting tasks
        Deactivated,    // Temporarily inactive (e.g., maintenance)
        PendingWithdraw // Deregistering, waiting for safety period
    }

    struct Provider {
        address wallet;
        uint256 stake;
        uint256 reputation; // Simple score: increases on success, decreases on failure
        ProviderStatus status;
        uint256 pendingWithdrawAmount;
        uint256 withdrawReadyTimestamp;
    }

    enum TaskStatus {
        Requested,      // Task created, waiting for providers
        SubmissionPeriod, // Providers can submit results
        RevealPeriod,   // (Optional, for commit/reveal) - Not implemented in this version for simplicity
        Finalizing,     // Consensus being evaluated
        Completed,      // Result finalized, rewards distributed
        Cancelled,      // Task cancelled by requester
        Failed          // Task failed (e.g., not enough submissions)
    }

    enum SubmissionStatus {
        Pending,        // Submitted, waiting for finalization
        Accepted,       // Accepted by consensus
        Rejected        // Rejected by consensus
    }

    struct TaskSubmission {
        address provider;
        bytes resultData; // Can be encoded numerical, categorical, or hash/CID
        SubmissionStatus status;
    }

    struct Task {
        uint256 taskId;
        address requester;
        string taskType;      // e.g., "sentiment", "image_classification_hash", "numerical_prediction"
        bytes taskInput;      // Off-chain input parameters/identifiers (e.g., text hash, image CID, data ID)
        uint256 requestTimestamp;
        uint256 minProviders;
        uint256 requiredStakePerProvider; // Required stake from provider to *submit*
        uint256 rewardPerProvider;        // Reward for provider on success
        uint256 submissionPeriodEnd;      // Timestamp when submission ends
        uint256 revealPeriodEnd;          // (Optional) Timestamp when reveal ends (not used in simple version)
        uint256 finalizationTimestamp;    // Timestamp when finalization occurred
        TaskStatus status;
        bytes finalResult;              // The validated consensus result
        uint256 totalTaskCost;          // Total ETH provided by requester (minProviders * rewardPerProvider + fees)
        address[] providersSubmitted;   // List of providers who submitted
        TaskSubmission[] submissions;    // All submitted results

        // Parameters used for consensus evaluation for THIS specific task
        uint256 consensusThresholdNumerical;
        uint256 consensusThresholdCategorical;
    }

    // --- State Variables ---

    uint256 private _taskCounter;
    uint256 private _providerCount; // Keep track of total registered providers over time (not active count)

    // Mappings
    mapping(address => Provider) public providers;
    mapping(address => uint256) private _providerWalletToIndex; // For internal tracking if needed, simpler without index array for now
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks; // Keep track of tasks requested by each user

    // Configuration Parameters (Owner can set)
    uint256 public minimumProviderStake = 1 ether; // Min stake to register as provider
    uint256 public protocolFeeRate = 5; // 5% (represented as 5 out of 100)
    uint256 public withdrawalSafetyPeriod = 7 days; // Delay for stake withdrawal
    uint256 public consensusThresholdNumerical = 5; // 5% deviation allowed for numerical consensus
    uint256 public consensusThresholdCategorical = 51; // 51% majority required for categorical/hash

    uint256 public totalProtocolFees; // Accumulated fees

    // --- Events ---

    event ProviderRegistered(address indexed provider, uint256 initialStake);
    event ProviderDeregistered(address indexed provider);
    event ProviderStakeToppedUp(address indexed provider, uint256 amount, uint256 newStake);
    event ProviderStakeWithdrawInitiated(address indexed provider, uint256 amount, uint256 withdrawReadyTimestamp);
    event ProviderStakeWithdrawCompleted(address indexed provider, uint256 amount);
    event ProviderDeactivated(address indexed provider);
    event ProviderActivated(address indexed provider);

    event TaskRequested(uint256 indexed taskId, address indexed requester, string taskType, uint256 totalCost);
    event TaskCancelled(uint256 indexed taskId, address indexed requester, uint256 refundAmount);
    event TaskCompleted(uint256 indexed taskId, bytes finalResult);
    event TaskFailed(uint256 indexed taskId, string reason);

    event ResultSubmitted(uint256 indexed taskId, address indexed provider);
    event TaskFinalizationTriggered(uint256 indexed taskId);

    event ProviderRewarded(uint256 indexed taskId, address indexed provider, uint256 reward);
    event ProviderSlashed(uint256 indexed taskId, address indexed provider, uint256 slashAmount, string reason);

    event ParametersUpdated(string paramName, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Modifier ---

    modifier onlyProvider(address providerAddress) {
        require(providers[providerAddress].status != ProviderStatus.Inactive, "Not a registered provider");
        _;
    }

    modifier whenTaskStatusIs(uint256 taskId, TaskStatus expectedStatus) {
        require(tasks[taskId].status == expectedStatus, "Task not in expected status");
        _;
    }

    // --- Provider Management Functions (1-10) ---

    /**
     * @dev Registers a new address as an AI provider. Requires a minimum stake.
     */
    function registerProvider() external payable nonReentrant whenNotPaused {
        require(providers[msg.sender].status == ProviderStatus.Inactive, "Provider already registered");
        require(msg.value >= minimumProviderStake, "Insufficient initial stake");

        providers[msg.sender] = Provider({
            wallet: msg.sender,
            stake: msg.value,
            reputation: 1000, // Start with a base reputation
            status: ProviderStatus.Active,
            pendingWithdrawAmount: 0,
            withdrawReadyTimestamp: 0
        });
        _providerCount++;
        emit ProviderRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Deregisters a provider. Initiates the stake withdrawal process.
     * Stake cannot be withdrawn immediately to cover potential pending task obligations.
     */
    function deregisterProvider() external onlyProvider(msg.sender) whenNotPaused {
        require(providers[msg.sender].status != ProviderStatus.PendingWithdraw, "Withdrawal already pending");
        // Note: A more complex version would check for active tasks this provider is involved in
        // and potentially delay deregistration until those tasks are finalized.
        // For simplicity, we just move stake to pending and start the timer.

        uint256 currentStake = providers[msg.sender].stake;
        providers[msg.sender].pendingWithdrawAmount = currentStake;
        providers[msg.sender].stake = 0;
        providers[msg.sender].withdrawReadyTimestamp = block.timestamp + withdrawalSafetyPeriod;
        providers[msg.sender].status = ProviderStatus.PendingWithdraw;

        emit ProviderDeregistered(msg.sender);
        emit ProviderStakeWithdrawInitiated(msg.sender, currentStake, providers[msg.sender].withdrawReadyTimestamp);
    }

    /**
     * @dev Allows a provider to top up their stake.
     * @param provider The address of the provider to top up. Can be msg.sender or another address.
     */
    function topUpProviderStake(address provider) external payable nonReentrant whenNotPaused {
        require(providers[provider].status != ProviderStatus.Inactive, "Provider not registered");
        require(msg.value > 0, "Must send non-zero value to top up");

        Provider storage p = providers[provider];
        p.stake += msg.value;

        emit ProviderStakeToppedUp(provider, msg.value, p.stake);
    }

     /**
     * @dev Allows a provider to initiate a withdrawal of a portion of their stake.
     * The amount becomes pending and is subject to the withdrawal safety period.
     * @param amount The amount to withdraw.
     */
    function initiateStakeWithdraw(uint256 amount) external onlyProvider(msg.sender) whenNotPaused nonReentrant {
        Provider storage p = providers[msg.sender];
        require(p.status != ProviderStatus.PendingWithdraw, "Already have a pending withdrawal");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(p.stake >= amount, "Insufficient stake");
        // Ensure provider maintains minimum stake if not fully withdrawing
        if (p.stake - amount > 0) {
             require(p.stake - amount >= minimumProviderStake, "Must maintain minimum stake");
        }


        p.stake -= amount;
        p.pendingWithdrawAmount += amount;
        p.withdrawReadyTimestamp = block.timestamp + withdrawalSafetyPeriod; // Timer restarts for combined pending amount

        emit ProviderStakeWithdrawInitiated(msg.sender, amount, p.withdrawReadyTimestamp);
    }

    /**
     * @dev Allows a provider to complete a pending stake withdrawal after the safety period has passed.
     */
    function completeStakeWithdraw() external onlyProvider(msg.sender) nonReentrant {
        Provider storage p = providers[msg.sender];
        require(p.pendingWithdrawAmount > 0, "No pending withdrawal");
        require(block.timestamp >= p.withdrawReadyTimestamp, "Withdrawal safety period not over");

        uint256 amountToWithdraw = p.pendingWithdrawAmount;
        p.pendingWithdrawAmount = 0;
        p.withdrawReadyTimestamp = 0;

        // If this was a full deregistration, set status back to Inactive
        if (p.stake == 0 && p.pendingWithdrawAmount == 0) {
             p.status = ProviderStatus.Inactive;
        }

        // Transfer funds
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Stake withdrawal failed");

        emit ProviderStakeWithdrawCompleted(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Allows a provider to temporarily deactivate themselves.
     * Deactivated providers cannot be selected for *new* tasks and cannot submit results.
     */
    function deactivateProvider() external onlyProvider(msg.sender) whenNotPaused {
        Provider storage p = providers[msg.sender];
        require(p.status == ProviderStatus.Active, "Provider not in Active status");
        p.status = ProviderStatus.Deactivated;
        emit ProviderDeactivated(msg.sender);
    }

    /**
     * @dev Allows a deactivated provider to reactivate themselves.
     */
    function activateProvider() external onlyProvider(msg.sender) whenNotPaused {
        Provider storage p = providers[msg.sender];
        require(p.status == ProviderStatus.Deactivated, "Provider not in Deactivated status");
        p.status = ProviderStatus.Active;
        emit ProviderActivated(msg.sender);
    }

    /**
     * @dev Gets information about a registered provider.
     * @param provider The address of the provider.
     * @return Provider struct details.
     */
    function getProviderInfo(address provider) external view onlyProvider(provider) returns (Provider memory) {
        return providers[provider];
    }

     /**
     * @dev Gets the current stake of a provider.
     * @param provider The address of the provider.
     * @return The staked amount.
     */
    function getProviderStake(address provider) external view onlyProvider(provider) returns (uint256) {
        return providers[provider].stake;
    }

    /**
     * @dev Gets the current reputation score of a provider.
     * @param provider The address of the provider.
     * @return The reputation score.
     */
    function getProviderReputation(address provider) external view onlyProvider(provider) returns (uint256) {
        return providers[provider].reputation;
    }


    // --- Task Management Functions (11-15) ---

    /**
     * @dev Requests a new AI task. Requires payment covering provider rewards and protocol fee.
     * @param taskType Identifier for the type of AI task (e.g., "sentiment", "image_classification").
     * @param taskInput Encoded input data or reference (e.g., hash, CID). Off-chain execution uses this.
     * @param minProviders Minimum number of provider submissions required for consensus.
     * @param requiredStakePerProvider Minimum stake a provider must have to *submit* to this task.
     * @param rewardPerProvider Reward paid to each *successful* provider.
     * @param submissionPeriod Duration in seconds for providers to submit results.
     * @param revealPeriod Duration in seconds for revealing (optional, set to 0 if not using reveal).
     * @return The ID of the newly created task.
     */
    function requestTask(
        string memory taskType,
        bytes memory taskInput,
        uint256 minProviders,
        uint256 requiredStakePerProvider,
        uint256 rewardPerProvider,
        uint256 submissionPeriod,
        uint256 revealPeriod // Future use: commit/reveal scheme
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        require(minProviders > 0, "Must require at least one provider");
        require(submissionPeriod > 0, "Submission period must be positive");
        require(rewardPerProvider > 0, "Reward must be positive");
        require(requiredStakePerProvider >= minimumProviderStake, "Required provider stake less than minimum"); // Providers need this much total stake, not staked per task

        uint256 totalRewardCost = minProviders * rewardPerProvider;
        uint256 protocolFee = (totalRewardCost * protocolFeeRate) / 100;
        uint256 totalCost = totalRewardCost + protocolFee;
        require(msg.value >= totalCost, "Insufficient payment for task");

        uint256 taskId = _taskCounter++;

        tasks[taskId] = Task({
            taskId: taskId,
            requester: msg.sender,
            taskType: taskType,
            taskInput: taskInput,
            requestTimestamp: block.timestamp,
            minProviders: minProviders,
            requiredStakePerProvider: requiredStakePerProvider, // Note: This is the required *total* stake for a provider to submit
            rewardPerProvider: rewardPerProvider,
            submissionPeriodEnd: block.timestamp + submissionPeriod,
            revealPeriodEnd: (revealPeriod > 0 ? block.timestamp + submissionPeriod + revealPeriod : 0), // Simple version sets this to 0
            finalizationTimestamp: 0,
            status: TaskStatus.SubmissionPeriod, // Start directly in submission period
            finalResult: bytes(""),
            totalTaskCost: totalCost,
            providersSubmitted: new address[](0),
            submissions: new TaskSubmission[](0),
            consensusThresholdNumerical: consensusThresholdNumerical, // Capture current consensus params at task creation
            consensusThresholdCategorical: consensusThresholdCategorical
        });

        userTasks[msg.sender].push(taskId);
        totalProtocolFees += protocolFee;

        // Refund any excess ETH sent by the user
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(success, "Refund failed"); // Or handle failure gracefully
        }


        emit TaskRequested(taskId, msg.sender, taskType, totalCost);

        return taskId;
    }

     /**
     * @dev Allows the requester to cancel a task before submissions are finalized.
     * A penalty might apply or partial funds are returned.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTaskRequest(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.requester == msg.sender, "Not your task");
        require(task.status == TaskStatus.Requested || task.status == TaskStatus.SubmissionPeriod, "Task cannot be cancelled in its current status");
        require(task.submissions.length == 0, "Cannot cancel after submissions have started"); // Simple version: no submissions means full refund minus fee

        // Simple cancellation: Refund total cost minus the protocol fee
        uint256 refundAmount = task.totalTaskCost - (task.totalTaskCost * protocolFeeRate) / 100;
        totalProtocolFees -= (task.totalTaskCost * protocolFeeRate) / 100; // Adjust fees if fee was already accounted for

        task.status = TaskStatus.Cancelled;
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Cancellation refund failed");

        emit TaskCancelled(taskId, msg.sender, refundAmount);
    }


    /**
     * @dev Gets details about a specific task.
     * @param taskId The ID of the task.
     * @return Task struct details.
     */
    function getTaskDetails(uint256 taskId) external view returns (Task memory) {
        require(tasks[taskId].requester != address(0), "Task does not exist"); // Check if task struct is initialized
        return tasks[taskId];
    }

     /**
     * @dev Gets a list of task IDs requested by a specific user.
     * @param user The address of the user.
     * @return An array of task IDs.
     */
    function getUserTasks(address user) external view returns (uint256[] memory) {
        return userTasks[user];
    }

    /**
     * @dev Gets the final validated result for a completed task.
     * @param taskId The ID of the task.
     * @return The final result data.
     */
    function getTaskResult(uint256 taskId) external view returns (bytes memory) {
        Task storage task = tasks[taskId];
        require(task.requester != address(0), "Task does not exist");
        require(task.status == TaskStatus.Completed, "Task result not finalized yet");
        return task.finalResult;
    }

    // --- Submission & Consensus Functions (16-18) ---

    /**
     * @dev Allows an AI provider to submit their computed result for a task.
     * @param taskId The ID of the task.
     * @param resultData The encoded result data from the AI computation.
     */
    function submitTaskResult(uint256 taskId, bytes memory resultData) external onlyProvider(msg.sender) nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        Provider storage provider = providers[msg.sender];

        require(task.requester != address(0), "Task does not exist");
        require(task.status == TaskStatus.SubmissionPeriod, "Task not in submission period");
        require(block.timestamp <= task.submissionPeriodEnd, "Submission period has ended");
        require(provider.status == ProviderStatus.Active, "Provider is not active");
        require(provider.stake >= task.requiredStakePerProvider, "Provider stake too low for this task");

        // Check if provider already submitted
        for (uint i = 0; i < task.providersSubmitted.length; i++) {
            require(task.providersSubmitted[i] != msg.sender, "Provider already submitted for this task");
        }

        task.providersSubmitted.push(msg.sender);
        task.submissions.push(TaskSubmission({
            provider: msg.sender,
            resultData: resultData,
            status: SubmissionStatus.Pending
        }));

        emit ResultSubmitted(taskId, msg.sender);
    }

     /**
     * @dev Allows viewing the submitted results for a task.
     * Note: In a real system, result data might be hashed on submission and revealed later
     * to prevent front-running or copying. This simplified version exposes submitted data.
     * @param taskId The ID of the task.
     * @return An array of TaskSubmission structs.
     */
    function getTaskSubmissions(uint256 taskId) external view returns (TaskSubmission[] memory) {
         require(tasks[taskId].requester != address(0), "Task does not exist");
         // Potentially restrict this view to requester or owner depending on privacy needs
         return tasks[taskId].submissions;
    }


    /**
     * @dev Triggers the finalization process for a task after the submission period.
     * Evaluates submissions, determines consensus, distributes rewards, and applies slashing.
     * Can be called by anyone to finalize a task once its submission period is over.
     * @param taskId The ID of the task to finalize.
     */
    function triggerTaskFinalization(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.requester != address(0), "Task does not exist");
        require(task.status == TaskStatus.SubmissionPeriod, "Task not in submission period");
        require(block.timestamp > task.submissionPeriodEnd, "Submission period is not over yet");

        task.status = TaskStatus.Finalizing; // Prevent re-entrancy on finalization
        task.finalizationTimestamp = block.timestamp;

        if (task.submissions.length < task.minProviders) {
            // Task failed due to insufficient submissions
            task.status = TaskStatus.Failed;
            // Refund user minus protocol fee (protocol fee is kept even if task fails)
             uint256 refundAmount = task.totalTaskCost - (task.totalTaskCost * protocolFeeRate) / 100;
            (bool success, ) = payable(task.requester).call{value: refundAmount}("");
            // Note: If refund fails, funds are stuck unless a recovery mechanism is added.
            // For this example, we assume refund success or accept the risk.
            if (success) {
                 emit TaskFailed(taskId, "Insufficient submissions");
            } else {
                 emit TaskFailed(taskId, "Insufficient submissions, refund failed");
            }

        } else {
            // Proceed with consensus evaluation
            _evaluateSubmissions(taskId);
            // Distribute rewards and slashes based on evaluation
            _distributeRewardsAndSlash(taskId);

            task.status = TaskStatus.Completed;
            emit TaskCompleted(taskId, task.finalResult);
        }
    }

    /**
     * @dev Internal function to evaluate submitted results and determine consensus.
     * Sets the status of each submission and the final task result.
     * Simplistic Consensus: Median for numerical, simple majority for others.
     * @param taskId The ID of the task.
     */
    function _evaluateSubmissions(uint256 taskId) internal {
        Task storage task = tasks[taskId];
        require(task.submissions.length >= task.minProviders, "Not enough submissions for evaluation"); // Should be checked in triggerFinalization

        // Basic Consensus Logic
        bytes[] memory acceptedResults = new bytes[](0);
        uint256 acceptedCount = 0;

        if (keccak256(abi.encodePacked(task.taskType)) == keccak256(abi.encodePacked("numerical_prediction"))) {
            // Numerical consensus: Calculate median and accept results within threshold
            uint256[] memory numericalResults = new uint256[](task.submissions.length);
            for(uint i = 0; i < task.submissions.length; i++) {
                 // Assume resultData for numerical is abi.encode(uint256)
                 numericalResults[i] = abi.decode(task.submissions[i].resultData, (uint256));
            }
            // Sort results (requires a sorting function or library)
            // For simplicity, let's assume a basic bubble sort or use a helper.
            // In production, offload or use a tested library.
             _sort(numericalResults);

            uint256 median;
            if (numericalResults.length % 2 == 0) {
                 median = (numericalResults[numericalResults.length / 2 - 1] + numericalResults[numericalResults.length / 2]) / 2;
            } else {
                 median = numericalResults[numericalResults.length / 2];
            }

            // Determine acceptable range based on median and threshold
            uint256 lowerBound = (median * (100 - task.consensusThresholdNumerical)) / 100;
            uint256 upperBound = (median * (100 + task.consensusThresholdNumerical)) / 100;

            for(uint i = 0; i < task.submissions.length; i++) {
                uint256 submittedValue = abi.decode(task.submissions[i].resultData, (uint256));
                if (submittedValue >= lowerBound && submittedValue <= upperBound) {
                    task.submissions[i].status = SubmissionStatus.Accepted;
                    acceptedCount++;
                    // Add to accepted results (might just need count for numerical)
                } else {
                    task.submissions[i].status = SubmissionStatus.Rejected;
                }
            }
             // Final result is the median or average of accepted results
            // For simplicity, use median here
            task.finalResult = abi.encode(median);

        } else {
            // Categorical or Hash consensus: Simple majority
            mapping(bytes32 => uint256) resultCounts;
            mapping(bytes32 => bytes) resultDataMap; // Store actual data keyed by hash
            uint256 maxCount = 0;
            bytes32 majorityHash = bytes32(0);

            for(uint i = 0; i < task.submissions.length; i++) {
                bytes32 resultHash = keccak256(task.submissions[i].resultData);
                resultCounts[resultHash]++;
                 resultDataMap[resultHash] = task.submissions[i].resultData; // Store data

                if (resultCounts[resultHash] > maxCount) {
                    maxCount = resultCounts[resultHash];
                    majorityHash = resultHash;
                }
            }

            uint256 totalSubmissions = task.submissions.length;
            uint256 majorityPercentage = (maxCount * 100) / totalSubmissions;

            if (majorityPercentage >= task.consensusThresholdCategorical) {
                // Consensus reached
                 task.finalResult = resultDataMap[majorityHash];
                 acceptedCount = maxCount; // Number of providers who got the majority result
                for(uint i = 0; i < task.submissions.length; i++) {
                    if (keccak256(task.submissions[i].resultData) == majorityHash) {
                        task.submissions[i].status = SubmissionStatus.Accepted;
                    } else {
                        task.submissions[i].status = SubmissionStatus.Rejected;
                    }
                }
            } else {
                // No strong consensus reached
                // Mark all as rejected? Mark task as failed?
                // For simplicity, mark all as rejected and set task to failed.
                for(uint i = 0; i < task.submissions.length; i++) {
                     task.submissions[i].status = SubmissionStatus.Rejected;
                }
                task.status = TaskStatus.Failed; // Change status directly or let _distribute handle it
                task.finalResult = bytes(""); // No valid consensus result
                 emit TaskFailed(taskId, "No strong consensus");
            }
        }

        // If no submissions were accepted (e.g., no numerical results within threshold), mark task failed
        if (acceptedCount == 0 && task.status != TaskStatus.Failed) {
            task.status = TaskStatus.Failed;
            task.finalResult = bytes("");
             emit TaskFailed(taskId, "No submissions met consensus criteria");
        }
    }

     /**
     * @dev Internal function to distribute rewards to accepted providers and slash rejected ones.
     * @param taskId The ID of the task.
     */
    function _distributeRewardsAndSlash(uint256 taskId) internal {
        Task storage task = tasks[taskId];
        // Only distribute if task is completed (i.e., consensus was reached)
        if (task.status != TaskStatus.Completed) {
             // If task failed, refund user minus fees (handled in triggerFinalization)
             // Providers who submitted get nothing, no slash for failed consensus (only for wrong result)
             return;
        }

        uint256 rewardPerProvider = task.rewardPerProvider;
        uint256 totalRewardDistributed = 0;
        uint256 totalSlashCollected = 0; // Future: Slashing could recover some ETH/stake

        // Calculate total reward pool available for successful providers *after* fees
        uint256 rewardPoolAfterFees = task.totalTaskCost - (task.totalTaskCost * protocolFeeRate) / 100;

        uint256 acceptedProviderCount = 0;
        for(uint i = 0; i < task.submissions.length; i++) {
            if (task.submissions[i].status == SubmissionStatus.Accepted) {
                 acceptedProviderCount++;
            }
        }

        // If there were accepted providers, distribute rewards from the pool
        if (acceptedProviderCount > 0) {
             // Reward is distributed proportionally if pool is less than sum of individual rewards
             uint256 rewardPerAcceptedProvider = rewardPoolAfterFees / acceptedProviderCount;

            for(uint i = 0; i < task.submissions.length; i++) {
                TaskSubmission storage submission = task.submissions[i];
                Provider storage provider = providers[submission.provider];

                if (submission.status == SubmissionStatus.Accepted) {
                    // Reward the provider
                    // Option 1: Increase provider's stake (simpler internal accounting)
                     provider.stake += rewardPerAcceptedProvider;
                     totalRewardDistributed += rewardPerAcceptedProvider;
                    // Option 2: Transfer ETH directly (more complex with re-entrancy)
                    // (bool success, ) = payable(provider.wallet).call{value: rewardPerAcceptedProvider}("");
                    // require(success, "Reward transfer failed"); // Or handle failure
                    emit ProviderRewarded(taskId, submission.provider, rewardPerAcceptedProvider);

                    // Increase reputation for correct submissions
                     provider.reputation += 1; // Simple reputation boost
                } else {
                    // Slash the provider (simplified: a fixed small amount or percentage of stake)
                    // A more complex system would base slash amount on severity/stake/reputation
                    uint256 slashAmount = provider.stake / 100; // Example: 1% slash
                    if (provider.stake > slashAmount) {
                         provider.stake -= slashAmount;
                         totalSlashCollected += slashAmount;
                         emit ProviderSlashed(taskId, submission.provider, slashAmount, "Incorrect result");
                         // Decrease reputation for incorrect submissions
                          if (provider.reputation > 0) provider.reputation -= 1; // Simple reputation penalty
                    } else if (provider.stake > 0) {
                        // Slash remainder if stake is less than 1%
                        totalSlashCollected += provider.stake;
                        provider.stake = 0;
                         emit ProviderSlashed(taskId, submission.provider, provider.stake, "Incorrect result (full stake slashed)");
                         if (provider.reputation > 0) provider.reputation -= 1;
                    }
                    // If stake is already 0, nothing to slash (already severely penalized)
                }
            }
             // Any remainder in reward pool (due to rounding or less than min accepted) stays as protocol fees
             totalProtocolFees += rewardPoolAfterFees - totalRewardDistributed;

        } else {
             // No providers were accepted by consensus, task should have been marked Failed already
             // All initial task cost minus protocol fee remains as protocol fee
             totalProtocolFees += task.totalTaskCost - (task.totalTaskCost * protocolFeeRate) / 100;
        }

        // Note: Slashed funds (totalSlashCollected) could also be added to the protocol fees
         totalProtocolFees += totalSlashCollected;

        // User (requester) has already paid, their interaction ends when they get the result.
    }

     // Simple sorting function for numerical consensus (Bubble Sort)
    function _sort(uint256[] memory arr) internal pure {
        uint256 n = arr.length;
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    // Swap elements
                    uint256 temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }


    // --- Configuration Functions (19-26) ---

    /**
     * @dev Owner sets the minimum required stake for providers.
     * @param amount The new minimum stake amount.
     */
    function setMinimumProviderStake(uint256 amount) external onlyOwner {
        require(amount > 0, "Minimum stake must be positive");
        minimumProviderStake = amount;
        emit ParametersUpdated("minimumProviderStake", amount);
    }

    /**
     * @dev Owner sets the protocol fee rate percentage.
     * @param rate The new fee rate (e.g., 5 for 5%). Max 100.
     */
    function setProtocolFeeRate(uint256 rate) external onlyOwner {
        require(rate <= 100, "Fee rate cannot exceed 100%");
        protocolFeeRate = rate;
        emit ParametersUpdated("protocolFeeRate", rate);
    }

    /**
     * @dev Owner sets the withdrawal safety period for provider stake.
     * @param seconds The new period in seconds.
     */
    function setWithdrawalSafetyPeriod(uint256 seconds) external onlyOwner {
        withdrawalSafetyPeriod = seconds;
        emit ParametersUpdated("withdrawalSafetyPeriod", seconds);
    }

     /**
     * @dev Owner sets the allowed percentage deviation for numerical consensus.
     * @param percentage The new percentage (e.g., 5 for 5%). Max 100.
     */
    function setConsensusThresholdNumerical(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Threshold cannot exceed 100%");
        consensusThresholdNumerical = percentage;
        emit ParametersUpdated("consensusThresholdNumerical", percentage);
    }

     /**
     * @dev Owner sets the minimum majority percentage required for categorical/hash consensus.
     * @param minMajorityPercentage The new percentage (e.g., 51 for 51%). Max 100.
     */
    function setConsensusThresholdCategorical(uint256 minMajorityPercentage) external onlyOwner {
        require(minMajorityPercentage <= 100, "Threshold cannot exceed 100%");
        consensusThresholdCategorical = minMajorityPercentage;
        emit ParametersUpdated("consensusThresholdCategorical", minMajorityPercentage);
    }


    /**
     * @dev Owner withdraws accumulated protocol fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address payable recipient) external onlyOwner nonReentrant {
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(recipient, amount);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }


    // --- Viewing & Utility Functions (27-32) ---

    /**
     * @dev Checks if an address is a registered provider.
     * @param provider The address to check.
     * @return True if registered (status is not Inactive), false otherwise.
     */
    function isProvider(address provider) external view returns (bool) {
        return providers[provider].status != ProviderStatus.Inactive;
    }

    /**
     * @dev Gets the total number of tasks requested historically.
     * @return The total count.
     */
    function getTaskCount() external view returns (uint256) {
        return _taskCounter;
    }

    /**
     * @dev Gets the total number of providers who have registered historically.
     * @return The total count.
     */
    function getProviderCount() external view returns (uint256) {
        return _providerCount;
    }

     /**
     * @dev Gets the total accumulated protocol fees.
     * @return The total fees in wei.
     */
    function getProtocolFees() external view returns (uint256) {
        return totalProtocolFees;
    }

     /**
     * @dev Gets the current minimum provider stake requirement.
     * @return The minimum stake in wei.
     */
    function getMinimumProviderStake() external view returns (uint256) {
        return minimumProviderStake;
    }

    /**
     * @dev Gets the current protocol fee rate.
     * @return The fee rate percentage.
     */
    function getProtocolFeeRate() external view returns (uint256) {
        return protocolFeeRate;
    }

    /**
     * @dev Gets the current withdrawal safety period in seconds.
     * @return The period in seconds.
     */
    function getWithdrawalSafetyPeriod() external view returns (uint256) {
        return withdrawalSafetyPeriod;
    }

    // --- Fallback/Receive ---
    // Allow receiving Ether for stake top-ups or potential direct payments (if implemented)
    receive() external payable {
        // Can add logic here if needed, e.g., require minimum transfer amount
        // or log the deposit. For simplicity, just allow receipt.
    }

    fallback() external payable {
        // Default fallback, potentially revert or add specific logic
        revert("Fallback called, check transaction data");
    }
}
```

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Decentralized AI Oracle:** The core idea itself is specific and combines AI (off-chain computation) with decentralized oracles, which is less common than general-purpose oracles.
2.  **Staking and Slashing:** Providers stake collateral (`registerProvider`, `topUpProviderStake`). This stake is used to incentivize honest behavior. If they submit incorrect results based on consensus, they are penalized (`_distributeRewardsAndSlash` triggered by `triggerTaskFinalization`). This is a standard DeFi/oracle mechanism, but applied to AI results here.
3.  **Reputation System:** A simple reputation score (`reputation` in `Provider` struct) is included, increasing for correct submissions and decreasing for incorrect ones (`_distributeRewardsAndSlash`). A more advanced system could use this reputation to influence task assignment, reward amounts, or slashing severity.
4.  **Consensus Mechanism:** The contract includes a rudimentary `_evaluateSubmissions` function implementing basic consensus logic (median for numerical, majority for others). This is a key part of oracle decentralization – agreeing on a single result from multiple sources. Real-world consensus algorithms are much more complex (e.g., using weighted averages, outlier detection, ZK proofs for verification), but this provides the core concept on-chain.
5.  **Task-Specific Requirements:** Task requests can specify `minProviders`, `requiredStakePerProvider`, and `rewardPerProvider`. This allows flexibility for different AI task complexities and values.
6.  **Configurable Parameters:** Owner functions (`setMinimumProviderStake`, `setProtocolFeeRate`, `setConsensusThresholdNumerical`, `setConsensusThresholdCategorical`, etc.) allow the protocol parameters to be adjusted over time, introducing a layer of governance or adaptability.
7.  **Provider Lifecycle:** Functions cover the full lifecycle: `register`, `deactivate`, `activate`, `deregister`, `initiateStakeWithdraw`, `completeStakeWithdraw`. The withdrawal safety period adds a security delay.
8.  **Task Lifecycle:** Functions manage tasks from `requestTask`, through `submitTaskResult`, `triggerTaskFinalization`, to getting the `getTaskResult` or handling `cancelTaskRequest`/`TaskFailed`.
9.  **Data Handling (`bytes memory resultData`, `bytes memory taskInput`):** Uses generic `bytes` types to allow flexibility in the type of AI result or input identifier being handled (e.g., could be `abi.encode` for structured data, a simple string, a hash `bytes32`, or an IPFS CID encoded as bytes). The *interpretation* of `resultData` for consensus depends on the `taskType` and requires off-chain coordination among providers.
10. **Separation of Concerns:** Functions are grouped logically (Provider, Task, Submission, Config, View).
11. **Events:** Comprehensive events are included for transparency and off-chain monitoring of key actions and state changes.
12. **Pausable:** Standard security feature (`pauseContract`, `unpauseContract`).
13. **ReentrancyGuard:** Protects against re-entrancy attacks, especially important when handling Ether transfers (`nonReentrant`).
14. **Internal Helper Functions:** Uses internal functions like `_evaluateSubmissions` and `_distributeRewardsAndSlash` to encapsulate core logic, keeping external functions cleaner.
15. **Protocol Fees:** Includes a mechanism to collect a percentage fee from task payments (`protocolFeeRate`, `totalProtocolFees`, `withdrawProtocolFees`), allowing the protocol operator (or a DAO in a more advanced version) to sustain itself.
16. **User Task Tracking:** `userTasks` mapping provides a convenient way for users to query their own requested tasks.
17. **Dynamic Consensus Thresholds:** The consensus thresholds (`consensusThresholdNumerical`, `consensusThresholdCategorical`) are stored per *task* at creation time, allowing parameters to change via governance without affecting already requested tasks.
18. **Basic Numerical Sorting:** Inclusion of a simple `_sort` function demonstrates the need for potentially gas-intensive computation or reliance on external libraries for on-chain data processing required for consensus like median calculation.
19. **Flexible Task Types:** The `taskType` string and generic `bytes` for `taskInput` and `resultData` allow the contract to support a variety of AI inference tasks without needing a rigid structure for each type (the interpretation is off-chain).
20. **Status Tracking:** Detailed `ProviderStatus` and `TaskStatus` enums provide clear states for entities within the system.
21. **Submission Status:** `SubmissionStatus` tracks the outcome of each individual provider's submission within the consensus process.
22. **Historical Counts:** `_taskCounter` and `_providerCount` track the total number of tasks and providers over the contract's lifetime, not just currently active ones.

This contract provides a solid foundation for a decentralized AI oracle, showcasing several advanced concepts beyond basic token or simple interaction contracts, and fulfilling the requirement of having more than 20 distinct functions covering different aspects of the system.