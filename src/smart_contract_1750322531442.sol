Okay, let's design a smart contract for a Decentralized AI Compute Network. This contract will coordinate users who need AI computations done and providers who offer compute power. It incorporates concepts like staking, reputation, decentralized task coordination, and potential hooks for advanced verification methods like zk-proofs (though full ZK verification is off-chain or requires complex separate contracts, we can represent the *process*).

We will aim for more than 20 distinct functions covering task management, provider management, token handling, administration, and views.

This design avoids duplicating simple patterns like basic ERC20/NFT contracts or standard DeFi vaults directly. The core logic revolves around orchestrating a multi-party off-chain process (computation) using on-chain state transitions and incentives.

---

### Smart Contract Outline & Summary:

**Contract Name:** `DecentralizedAIComputeNetwork`

**Purpose:** To provide a decentralized marketplace and coordination layer for AI/Machine Learning compute tasks. Users (Requesters) post tasks with associated rewards and stakes. Providers stake tokens to offer compute power, claim tasks, perform computation off-chain, submit results, and get rewarded upon successful verification. The contract manages task states, provider reputation, token transfers, and dispute resolution workflows.

**Core Concepts:**
*   **Task Orchestration:** Managing the lifecycle of compute tasks from creation to finalization.
*   **Provider Staking & Reputation:** Providers lock tokens as collateral and build a reputation score based on task performance.
*   **Decentralized Verification Workflow:** Allowing for result verification and dispute resolution, potentially integrating with off-chain processes or proofs.
*   **Token Economics:** Handling payment and stake tokens, including platform commission.
*   **Role-Based Access:** Requester, Provider, Verifier, Admin roles managed through addresses/status.

**Key State Variables:**
*   `tasks`: Mapping from task ID to `Task` struct.
*   `providers`: Mapping from provider address to `Provider` struct.
*   `requesterBalances`: Mapping from requester address to payment token balance deposited in the contract.
*   `providerStakes`: Mapping from provider address to network token stake deposited in the contract.
*   `nextTaskId`: Counter for new tasks.
*   `registeredVerifiers`: Set of addresses authorized to dispute results.
*   Configuration parameters (stake amounts, challenge periods, commission rates).

**Function Summary (Minimum 20 functions):**

**Task Management:**
1.  `createTask`: Post a new compute task. Requires deposited payment and task stake.
2.  `cancelTask`: Cancel an open task by the requester. Refunds stakes/payment.
3.  `claimTask`: Provider claims an available task. Requires minimum provider stake and capacity.
4.  `submitResult`: Provider submits the result pointer (e.g., IPFS hash) and optional proof. Moves task to verification state.
5.  `signalTaskFailure`: Requester or Verifier signals a provider failed to submit results within time.
6.  `disputeResult`: Registered Verifier challenges a submitted result. Moves task to dispute state.
7.  `resolveDispute`: Admin/DAO/Oracle resolves a dispute (decides if result was valid).
8.  `finalizeTask`: Finalizes a completed task (either after verification or dispute resolution), distributes rewards, updates reputation, etc.
9.  `bulkCreateTasks`: Create multiple tasks in a single transaction.

**Provider Management:**
10. `registerProvider`: Register an address as a compute provider. Requires staking network tokens.
11. `updateProviderStake`: Increase or decrease a provider's network token stake (if no tasks pending).
12. `unregisterProvider`: Provider unstakes and leaves the network (after completing all tasks).
13. `slashProvider`: Internal function to penalize a provider (called during dispute resolution or failure).
14. `updateReputationScore`: Internal function to adjust provider reputation based on performance.

**Token & Balance Management:**
15. `depositPaymentToken`: User deposits payment tokens into their contract balance.
16. `withdrawPaymentToken`: User withdraws unused payment tokens from their contract balance.
17. `depositNetworkToken`: User (Provider) deposits network tokens for staking.
18. `withdrawNetworkToken`: User (Provider) withdraws unstaked network tokens.
19. `withdrawCommission`: Admin/Owner withdraws accumulated platform commission.

**Verification Management:**
20. `registerVerifier`: Admin registers an address as an authorized verifier.
21. `unregisterVerifier`: Admin removes a registered verifier.

**Admin & Configuration:**
22. `setRequiredProviderStake`: Set minimum network token stake for providers.
23. `setTaskStakeRate`: Set the percentage of task reward required as requester stake.
24. `setCommissionRate`: Set the platform fee percentage on task rewards.
25. `setChallengePeriod`: Set the duration for result verification/dispute period.
26. `setTaskTimeout`: Set the maximum time allowed for a provider to complete a task.
27. `pauseContract`: Pauses core contract functions in case of emergency.
28. `unpauseContract`: Unpauses the contract.

**View Functions:**
29. `getTaskDetails`: Get details of a specific task.
30. `getProviderDetails`: Get details of a specific provider.
31. `getRequesterBalance`: Get a requester's deposit balance.
32. `getAvailableTasks`: Get a list of tasks currently in the `Open` state.
33. `getTasksByRequester`: Get tasks initiated by a specific requester.
34. `getTasksByProvider`: Get tasks claimed by a specific provider.
35. `getRegisteredVerifiers`: Get the list of addresses registered as verifiers.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Smart Contract Outline & Summary ---
// Contract Name: DecentralizedAIComputeNetwork
// Purpose: To provide a decentralized marketplace and coordination layer for AI/Machine Learning compute tasks.
// Users (Requesters) post tasks with associated rewards and stakes. Providers stake tokens
// to offer compute power, claim tasks, perform computation off-chain, submit results,
// and get rewarded upon successful verification. The contract manages task states,
// provider reputation, token transfers, and dispute resolution workflows.
// Core Concepts: Task Orchestration, Provider Staking & Reputation, Decentralized
// Verification Workflow, Token Economics, Role-Based Access.
// Key State Variables: tasks mapping, providers mapping, requesterBalances,
// providerStakes, nextTaskId, registeredVerifiers, configuration parameters.
// Function Summary: (See detailed list below - 35+ functions)

// --- Custom Errors ---
error NotEnoughPaymentToken(address user, uint256 required, uint256 available);
error NotEnoughNetworkToken(address user, uint256 required, uint256 available);
error TaskNotFound(uint256 taskId);
error ProviderNotFound(address provider);
error TaskNotOpen(uint256 taskId);
error TaskNotClaimed(uint256 taskId);
error TaskAlreadyClaimed(uint256 taskId);
error NotTaskRequester(uint256 taskId);
error NotTaskProvider(uint256 taskId);
error TaskStatusInvalid(uint256 taskId, TaskStatus currentStatus, TaskStatus requiredStatus);
error ProviderNotRegistered(address provider);
error ProviderHasActiveTasks(address provider);
error InsufficientProviderStake(address provider, uint256 required, uint256 has);
error ResultAlreadySubmitted(uint256 taskId);
error VerificationPeriodNotElapsed(uint256 taskId);
error DisputePeriodNotElapsed(uint256 taskId); // Might be used if there's a time limit to dispute
error NoActiveDispute(uint256 taskId);
error NotRegisteredVerifier(address user);
error TaskTimeoutNotReached(uint256 taskId);
error TaskTimeoutAlreadyReached(uint256 taskId);
error TaskRequiresResultSubmission(uint256 taskId);
error TaskAlreadyFinalized(uint256 taskId);

// --- Events ---
event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 reward, uint256 requesterStake, string dataPointer);
event TaskCancelled(uint256 indexed taskId, address indexed requester);
event TaskClaimed(uint256 indexed taskId, address indexed provider);
event ResultSubmitted(uint256 indexed taskId, address indexed provider, string resultPointer);
event SignalTaskFailure(uint256 indexed taskId, address indexed signaler);
event DisputeRaised(uint256 indexed taskId, address indexed disputer, string reason); // Reason pointer/hash
event DisputeResolved(uint256 indexed taskId, bool resultValid, address indexed resolver);
event TaskFinalized(uint256 indexed taskId, TaskStatus finalStatus, uint256 rewardPaid, uint256 commissionCollected, int256 providerReputationChange);
event ProviderRegistered(address indexed provider, uint256 initialStake);
event ProviderStakeUpdated(address indexed provider, uint256 newStake);
event ProviderUnregistered(address indexed provider, uint256 returnedStake);
event ProviderSlashed(address indexed provider, uint256 slashedAmount, string reason);
event CommissionWithdrawn(address indexed receiver, uint256 amount);
event VerifierRegistered(address indexed verifier);
event VerifierUnregistered(address indexed verifier);
event ParametersUpdated(string parameterName, uint256 newValue); // Generic event for config changes
event Deposited(address indexed user, address indexed token, uint256 amount);
event Withdraw(address indexed user, address indexed token, uint256 amount);

// --- Enums ---
enum TaskStatus {
    Open,               // Task is available for providers to claim
    Claimed,            // Task is claimed by a provider, computation is ongoing
    ResultSubmitted,    // Provider submitted results, waiting for verification
    InVerification,     // Explicit state if verification involves multiple steps/actors
    Dispute,            // Result is under dispute
    Completed,          // Task successfully completed, provider paid
    Cancelled,          // Task cancelled by requester before claiming
    Failed              // Task failed (e.g., provider failure, invalid result after dispute)
}

enum VerificationStatus {
    None,       // No result submitted yet
    Pending,    // Result submitted, verification period active
    Approved,   // Result verified as valid
    Rejected    // Result verified as invalid
}

// --- Structs ---
struct Task {
    uint256 taskId;
    address requester;
    address provider; // Address(0) if not claimed
    uint256 reward; // Payment token amount for successful completion
    uint256 requesterStake; // Payment token amount staked by requester, returned on success
    string dataPointer; // E.g., IPFS hash pointing to input data and task specs
    string resultPointer; // E.g., IPFS hash pointing to output data
    TaskStatus status;
    VerificationStatus verificationStatus;
    uint64 submissionTime; // Timestamp when result was submitted (for challenge period)
    uint64 claimedTime;    // Timestamp when task was claimed (for timeout)
    uint256 disputeCount; // Counter for disputes on this task
}

struct Provider {
    address providerAddress;
    uint256 stake; // Network token amount staked
    int256 reputationScore; // Provider's reputation (can be positive or negative)
    uint256 tasksInProgress; // Number of tasks currently claimed/submitted
    bool isRegistered; // Flag to indicate if the provider is currently registered
}

// --- Contract ---
contract DecentralizedAIComputeNetwork is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public immutable paymentToken; // Token used for task rewards and requester stakes
    IERC20 public immutable networkToken; // Token used for provider stakes and governance (if applicable)

    mapping(uint256 => Task) public tasks;
    uint256 private _nextTaskId;

    mapping(address => Provider) public providers;
    mapping(address => uint256) private _requesterBalances; // Payment token balance deposited by requesters
    mapping(address => uint256) private _providerStakes; // Network token stake deposited by providers (redundant with Provider struct, but good for clear separation of deposited vs staked)

    EnumerableSet.AddressSet private _registeredVerifiers;
    address public commissionVault; // Address to send platform commission

    // Configuration Parameters (set by owner/DAO)
    uint256 public requiredProviderStake = 1000; // Minimum network token stake to register/claim
    uint256 public taskStakeRate = 10; // Percentage of reward required as requester stake (e.g., 10 for 10%)
    uint256 public commissionRate = 5; // Percentage of reward taken as commission (e.g., 5 for 5%)
    uint64 public challengePeriodDuration = 2 days; // Time allowed for disputes after result submission
    uint64 public taskTimeoutDuration = 7 days; // Max time for provider to submit result after claiming

    constructor(address _paymentToken, address _networkToken, address _commissionVault)
        Ownable(msg.sender) // Sets initial owner
        Pausable()
    {
        require(_paymentToken != address(0), "Payment token address cannot be zero");
        require(_networkToken != address(0), "Network token address cannot be zero");
        require(_commissionVault != address(0), "Commission vault address cannot be zero");
        require(_paymentToken != _networkToken, "Payment and network tokens cannot be the same");

        paymentToken = IERC20(_paymentToken);
        networkToken = IERC20(_networkToken);
        commissionVault = _commissionVault;
        _nextTaskId = 1; // Task IDs start from 1
    }

    // --- Modifiers ---
    modifier onlyTaskRequester(uint256 _taskId) {
        if (tasks[_taskId].requester == address(0)) revert TaskNotFound(_taskId);
        if (tasks[_taskId].requester != msg.sender) revert NotTaskRequester(_taskId);
        _;
    }

    modifier onlyTaskProvider(uint256 _taskId) {
        if (tasks[_taskId].taskId == 0) revert TaskNotFound(_taskId); // Check if task exists
        if (tasks[_taskId].provider == address(0)) revert TaskNotClaimed(_taskId);
        if (tasks[_taskId].provider != msg.sender) revert NotTaskProvider(_taskId);
        _;
    }

     modifier onlyRegisteredVerifier() {
        if (!_registeredVerifiers.contains(msg.sender)) revert NotRegisteredVerifier(msg.sender);
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        if (tasks[_taskId].taskId == 0) revert TaskNotFound(_taskId); // Check if task exists
        if (tasks[_taskId].status != _status) revert TaskStatusInvalid(_taskId, tasks[_taskId].status, _status);
        _;
    }

    modifier providerIsRegistered(address _provider) {
        if (!providers[_provider].isRegistered) revert ProviderNotRegistered(_provider);
        _;
    }

    // --- Token & Balance Management ---

    /// @notice Deposits payment tokens into the user's balance within the contract.
    /// @param amount The amount of payment tokens to deposit. Requires prior ERC20 approve.
    function depositPaymentToken(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        uint256 transferAmount = paymentToken.transferFrom(msg.sender, address(this), amount);
        _requesterBalances[msg.sender] += transferAmount;
        emit Deposited(msg.sender, address(paymentToken), transferAmount);
    }

    /// @notice Withdraws unused payment tokens from the user's balance within the contract.
    /// @param amount The amount of payment tokens to withdraw.
    function withdrawPaymentToken(uint256 amount) external whenNotPaused {
        if (_requesterBalances[msg.sender] < amount) revert NotEnoughPaymentToken(msg.sender, amount, _requesterBalances[msg.sender]);
        _requesterBalances[msg.sender] -= amount;
        paymentToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, address(paymentToken), amount);
    }

    /// @notice Deposits network tokens for staking as a provider.
    /// @param amount The amount of network tokens to deposit. Requires prior ERC20 approve.
    function depositNetworkToken(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        uint256 transferAmount = networkToken.transferFrom(msg.sender, address(this), amount);
        _providerStakes[msg.sender] += transferAmount;
        emit Deposited(msg.sender, address(networkToken), transferAmount);
    }

    /// @notice Withdraws unstaked network tokens from the user's balance within the contract.
    /// @param amount The amount of network tokens to withdraw.
    function withdrawNetworkToken(uint256 amount) external whenNotPaused {
        if (_providerStakes[msg.sender] < amount) revert NotEnoughNetworkToken(msg.sender, amount, _providerStakes[msg.sender]);
        _providerStakes[msg.sender] -= amount;
        networkToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, address(networkToken), amount);
    }

    /// @notice Allows the owner to withdraw accumulated commission fees.
    function withdrawCommission(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        // Commission is collected within the contract's payment token balance.
        // Check contract balance, not a specific mapping, as it comes from task rewards.
        uint256 contractPaymentBalance = paymentToken.balanceOf(address(this));
        require(contractPaymentBalance >= amount, "Insufficient commission balance");
        paymentToken.transfer(commissionVault, amount);
        emit CommissionWithdrawn(commissionVault, amount);
    }

    // --- Task Management ---

    /// @notice Creates a new AI compute task.
    /// @param _reward The payment token amount offered for successful task completion.
    /// @param _dataPointer Pointer (e.g., IPFS hash) to the task data and specifications.
    function createTask(uint256 _reward, string calldata _dataPointer) external whenNotPaused {
        require(_reward > 0, "Reward must be greater than 0");
        uint256 requiredStake = (_reward * taskStakeRate) / 100;
        uint256 totalCost = _reward + requiredStake;

        if (_requesterBalances[msg.sender] < totalCost) {
            revert NotEnoughPaymentToken(msg.sender, totalCost, _requesterBalances[msg.sender]);
        }

        // Deduct total cost from requester's internal balance
        _requesterBalances[msg.sender] -= totalCost;

        uint256 currentTaskId = _nextTaskId;
        tasks[currentTaskId] = Task({
            taskId: currentTaskId,
            requester: msg.sender,
            provider: address(0),
            reward: _reward,
            requesterStake: requiredStake,
            dataPointer: _dataPointer,
            resultPointer: "",
            status: TaskStatus.Open,
            verificationStatus: VerificationStatus.None,
            submissionTime: 0,
            claimedTime: 0,
            disputeCount: 0
        });

        _nextTaskId++;

        emit TaskCreated(currentTaskId, msg.sender, _reward, requiredStake, _dataPointer);
    }

    /// @notice Allows the requester to cancel an open task.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) external whenNotPaused onlyTaskRequester(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        Task storage task = tasks[_taskId];

        // Refund the requester's deposited amount (reward + stake)
        uint256 refundAmount = task.reward + task.requesterStake;
        _requesterBalances[msg.sender] += refundAmount;

        // Remove the task (or mark as cancelled)
        // Marking as Cancelled is better for history
        task.status = TaskStatus.Cancelled;

        emit TaskCancelled(_taskId, msg.sender);
    }

    /// @notice Allows a registered provider to claim an open task.
    /// @param _taskId The ID of the task to claim.
    function claimTask(uint256 _taskId) external whenNotPaused providerIsRegistered(msg.sender) taskInStatus(_taskId, TaskStatus.Open) {
        Task storage task = tasks[_taskId];
        Provider storage provider = providers[msg.sender];

        // Check if provider meets the minimum stake requirement
        if (_providerStakes[msg.sender] < requiredProviderStake) {
             revert InsufficientProviderStake(msg.sender, requiredProviderStake, _providerStakes[msg.sender]);
        }

        // Assign task to provider
        task.provider = msg.sender;
        task.status = TaskStatus.Claimed;
        task.claimedTime = uint64(block.timestamp);

        // Update provider's active task count
        provider.tasksInProgress++;

        emit TaskClaimed(_taskId, msg.sender);
    }

    /// @notice Allows the assigned provider to submit the result of a claimed task.
    /// @param _taskId The ID of the task.
    /// @param _resultPointer Pointer (e.g., IPFS hash) to the result data.
    /// @param _proof Optional pointer/data for a verification proof (e.g., ZK-SNARK proof hash). Not used directly in this contract's verification logic for simplicity, but can be stored.
    function submitResult(uint256 _taskId, string calldata _resultPointer, string calldata _proof) external whenNotPaused onlyTaskProvider(_taskId) taskInStatus(_taskId, TaskStatus.Claimed) {
        Task storage task = tasks[_taskId];
        require(bytes(_resultPointer).length > 0, "Result pointer cannot be empty"); // Basic validation

        // Check if task timed out (provider failed to submit in time)
        if (block.timestamp > task.claimedTime + taskTimeoutDuration) {
             _handleTaskFailure(_taskId, task.provider, "Task timeout");
             return; // Task status is updated in _handleTaskFailure
        }

        task.resultPointer = _resultPointer;
        // Proof is ignored for state, just stored potentially or handled off-chain
        task.status = TaskStatus.ResultSubmitted;
        task.verificationStatus = VerificationStatus.Pending;
        task.submissionTime = uint64(block.timestamp);

        emit ResultSubmitted(_taskId, msg.sender, _resultPointer);
    }

    /// @notice Allows requester or verifier to signal that a claimed task failed (e.g., provider unresponsive).
    /// Can only be called after taskTimeoutDuration has passed since claiming.
    /// @param _taskId The ID of the task.
    function signalTaskFailure(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert TaskNotFound(_taskId);

        bool isRequester = task.requester == msg.sender;
        bool isVerifier = _registeredVerifiers.contains(msg.sender);

        require(isRequester || isVerifier, "Only requester or registered verifier can signal failure");
        require(task.status == TaskStatus.Claimed, TaskStatusInvalid(_taskId, task.status, TaskStatus.Claimed));

        // Check if task timeout has been reached
        if (block.timestamp <= task.claimedTime + taskTimeoutDuration) {
             revert TaskTimeoutNotReached(_taskId);
        }

        // Handle the failure (slash provider, mark task failed)
        _handleTaskFailure(_taskId, task.provider, "Signaled timeout failure");

        emit SignalTaskFailure(_taskId, msg.sender);
    }


    /// @notice Allows a registered verifier to dispute a submitted result.
    /// Can only be called during the challenge period after result submission.
    /// @param _taskId The ID of the task.
    /// @param _reasonHash Hash or pointer to the reason for dispute (stored off-chain).
    function disputeResult(uint256 _taskId, string calldata _reasonHash) external whenNotPaused onlyRegisteredVerifier {
        Task storage task = tasks[_taskId];
        require(task.taskId > 0, TaskNotFound(_taskId)); // Ensure task exists

        require(task.status == TaskStatus.ResultSubmitted || task.status == TaskStatus.InVerification,
                TaskStatusInvalid(_taskId, task.status, TaskStatus.ResultSubmitted)); // Allow dispute if explicitly in verification too

        // Check if challenge period is still active
        require(block.timestamp <= task.submissionTime + challengePeriodDuration, "Challenge period has ended");

        task.status = TaskStatus.Dispute;
        task.disputeCount++;

        emit DisputeRaised(_taskId, msg.sender, _reasonHash);
    }

    /// @notice Called by owner/admin (representing oracle/DAO) to resolve a dispute.
    /// @param _taskId The ID of the task.
    /// @param _resultValid Whether the disputed result is deemed valid or invalid.
    function resolveDispute(uint256 _taskId, bool _resultValid) external onlyOwner whenNotPaused taskInStatus(_taskId, TaskStatus.Dispute) {
        Task storage task = tasks[_taskId];
        Provider storage provider = providers[task.provider];

        task.verificationStatus = _resultValid ? VerificationStatus.Approved : VerificationStatus.Rejected;

        if (_resultValid) {
            // Result is valid, pay the provider
            _finalizeSuccessfulTask(_taskId, task, provider);
        } else {
            // Result is invalid, slash the provider
            _handleTaskFailure(_taskId, task.provider, "Result invalid after dispute");
             // Potentially reward disputer? Out of scope for this example.
        }

        emit DisputeResolved(_taskId, _resultValid, msg.sender);
    }

    /// @notice Finalizes a task that has completed its verification period without dispute, or after a dispute is resolved.
    /// Can be called by anyone to trigger finalization once the time lock is past.
    /// @param _taskId The ID of the task.
    function finalizeTask(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.taskId > 0, TaskNotFound(_taskId)); // Ensure task exists

        require(task.status == TaskStatus.ResultSubmitted || task.status == TaskStatus.Dispute,
                TaskStatusInvalid(_taskId, task.status, task.status)); // Can only finalize if in ResultSubmitted or Dispute

        require(task.status != TaskStatus.Completed && task.status != TaskStatus.Failed && task.status != TaskStatus.Cancelled,
                TaskAlreadyFinalized(_taskId)); // Cannot finalize if already in a final state


        if (task.status == TaskStatus.ResultSubmitted) {
             // Finalizing after result submission, check challenge period
            require(block.timestamp > task.submissionTime + challengePeriodDuration, VerificationPeriodNotElapsed(_taskId));
            require(task.disputeCount == 0, "Task has pending disputes"); // Should be in Dispute state if disputed

            // No disputes and period elapsed, result is approved implicitly
            task.verificationStatus = VerificationStatus.Approved;
            _finalizeSuccessfulTask(_taskId, task, providers[task.provider]);

        } else if (task.status == TaskStatus.Dispute) {
            // Finalizing after dispute resolution
            // Dispute resolution should have already set verificationStatus and handled payment/slashing.
            // This step just sets the final task status if not already set by resolveDispute.
            if (task.verificationStatus == VerificationStatus.Approved) {
                 task.status = TaskStatus.Completed;
                 // Provider should have already been paid by resolveDispute
            } else if (task.verificationStatus == VerificationStatus.Rejected) {
                 task.status = TaskStatus.Failed;
                 // Provider should have already been slashed by resolveDispute
            } else {
                 // Dispute needs resolution before finalizing
                 revert NoActiveDispute(_taskId); // Should not happen if in Dispute status
            }
        } else {
             // Should be caught by initial status check
             revert("Invalid task state for finalization");
        }

        // Update provider's active task count if not failed/cancelled
        if (task.provider != address(0)) {
             Provider storage provider = providers[task.provider];
             if (provider.tasksInProgress > 0) {
                 provider.tasksInProgress--;
             }
        }

        emit TaskFinalized(_taskId, task.status, (task.status == TaskStatus.Completed ? task.reward : 0), (task.status == TaskStatus.Completed ? (task.reward * commissionRate) / 100 : 0), (task.provider != address(0) ? providers[task.provider].reputationScore - (task.status == TaskStatus.Completed ? providers[task.provider].reputationScore : 0) : 0)); // Reputation change is tricky to capture precisely here, maybe better in _updateReputationScore
    }

    /// @notice Allows a user to create multiple tasks in a single transaction.
    /// @param _rewards Array of reward amounts for each task.
    /// @param _dataPointers Array of data pointers for each task.
    function bulkCreateTasks(uint256[] calldata _rewards, string[] calldata _dataPointers) external whenNotPaused {
        require(_rewards.length == _dataPointers.length, "Input arrays must have same length");
        require(_rewards.length > 0, "Must create at least one task");

        uint256 totalCost = 0;
        for (uint i = 0; i < _rewards.length; i++) {
            require(_rewards[i] > 0, "Reward must be greater than 0");
            totalCost += _rewards[i] + (_rewards[i] * taskStakeRate) / 100;
        }

         if (_requesterBalances[msg.sender] < totalCost) {
            revert NotEnoughPaymentToken(msg.sender, totalCost, _requesterBalances[msg.sender]);
        }

        _requesterBalances[msg.sender] -= totalCost;

        for (uint i = 0; i < _rewards.length; i++) {
            uint256 currentTaskId = _nextTaskId;
            tasks[currentTaskId] = Task({
                taskId: currentTaskId,
                requester: msg.sender,
                provider: address(0),
                reward: _rewards[i],
                requesterStake: (_rewards[i] * taskStakeRate) / 100,
                dataPointer: _dataPointers[i],
                resultPointer: "",
                status: TaskStatus.Open,
                verificationStatus: VerificationStatus.None,
                submissionTime: 0,
                claimedTime: 0,
                disputeCount: 0
            });
            _nextTaskId++;
            emit TaskCreated(currentTaskId, msg.sender, _rewards[i], (_rewards[i] * taskStakeRate) / 100, _dataPointers[i]);
        }
    }

    // --- Provider Management ---

    /// @notice Registers an address as a compute provider.
    /// @param _initialStake The amount of network tokens to stake.
    function registerProvider(uint256 _initialStake) external whenNotPaused {
        require(!providers[msg.sender].isRegistered, "Provider is already registered");
        require(_initialStake >= requiredProviderStake, InsufficientProviderStake(msg.sender, requiredProviderStake, _initialStake));

        if (_providerStakes[msg.sender] < _initialStake) {
            revert NotEnoughNetworkToken(msg.sender, _initialStake, _providerStakes[msg.sender]);
        }

        _providerStakes[msg.sender] -= _initialStake; // Move from deposit balance to staked balance
        providers[msg.sender] = Provider({
            providerAddress: msg.sender,
            stake: _initialStake,
            reputationScore: 0, // Start with neutral reputation
            tasksInProgress: 0,
            isRegistered: true
        });

        emit ProviderRegistered(msg.sender, _initialStake);
    }

    /// @notice Updates a provider's stake amount.
    /// @param _newStake The new total stake amount for the provider. Must be >= requiredProviderStake.
    function updateProviderStake(uint256 _newStake) external whenNotPaused providerIsRegistered(msg.sender) {
        Provider storage provider = providers[msg.sender];
        require(provider.tasksInProgress == 0, "Cannot update stake while tasks are in progress");
        require(_newStake >= requiredProviderStake, InsufficientProviderStake(msg.sender, requiredProviderStake, _newStake));

        uint256 currentStake = provider.stake;

        if (_newStake > currentStake) {
            uint256 increaseAmount = _newStake - currentStake;
             if (_providerStakes[msg.sender] < increaseAmount) {
                revert NotEnoughNetworkToken(msg.sender, increaseAmount, _providerStakes[msg.sender]);
            }
            _providerStakes[msg.sender] -= increaseAmount; // Move from deposit balance to staked balance
        } else if (_newStake < currentStake) {
             uint256 decreaseAmount = currentStake - _newStake;
            // Move from staked balance back to deposit balance
             _providerStakes[msg.sender] += decreaseAmount;
        } else {
            // Stake is the same, nothing to do
            return;
        }

        provider.stake = _newStake;
        emit ProviderStakeUpdated(msg.sender, _newStake);
    }


    /// @notice Allows a provider to unregister if they have no active tasks.
    function unregisterProvider() external whenNotPaused providerIsRegistered(msg.sender) {
        Provider storage provider = providers[msg.sender];
        if (provider.tasksInProgress > 0) revert ProviderHasActiveTasks(msg.sender);

        uint256 stakeToReturn = provider.stake;

        // Move staked tokens back to the provider's deposit balance
        _providerStakes[msg.sender] += stakeToReturn;

        // Reset provider state
        delete providers[msg.sender]; // Removes from the mapping
        // Note: If using EnumerableSet for providers, would need to remove here too.

        emit ProviderUnregistered(msg.sender, stakeToReturn);
    }

    /// @notice Internal function to handle provider slashing (penalty).
    /// @param _providerAddress The address of the provider to slash.
    /// @param _reason Reason for slashing (pointer or string).
    function _slashProvider(address _providerAddress, string memory _reason) internal {
        Provider storage provider = providers[_providerAddress];
        if (!provider.isRegistered) revert ProviderNotFound(_providerAddress);

        // Simple slashing logic: reduce stake by a fixed percentage or amount,
        // and significantly decrease reputation.
        // Let's slash a percentage of the stake.
        uint256 slashPercentage = 10; // Example: 10% stake slash
        uint256 slashAmount = (provider.stake * slashPercentage) / 100;

        if (slashAmount > provider.stake) {
            slashAmount = provider.stake; // Don't slash more than they have
        }

        provider.stake -= slashAmount;
        // Slashed amount goes to the commission vault
        paymentToken.transfer(commissionVault, slashAmount); // Assuming slashing uses payment token, or network token sent to vault

        // Update reputation - Significant penalty
        _updateReputationScore(_providerAddress, -50); // Example: -50 points

        emit ProviderSlashed(_providerAddress, slashAmount, _reason);
    }

    /// @notice Internal function to update a provider's reputation score.
    /// @param _providerAddress The address of the provider.
    /// @param _reputationChange The amount to add to the reputation score (can be negative).
    function _updateReputationScore(address _providerAddress, int256 _reputationChange) internal {
        Provider storage provider = providers[_providerAddress];
         if (!provider.isRegistered) revert ProviderNotFound(_providerAddress); // Should not happen if called internally correctly
        provider.reputationScore += _reputationChange;
        // Emit event for reputation change if needed
        // emit ReputationUpdated(_providerAddress, provider.reputationScore); // Add ReputationUpdated event if desired
    }

    /// @notice Internal function to handle task failure (provider fault).
    /// @param _taskId The ID of the task that failed.
    /// @param _providerAddress The provider assigned to the task.
    /// @param _reason Reason for failure.
    function _handleTaskFailure(uint256 _taskId, address _providerAddress, string memory _reason) internal {
        Task storage task = tasks[_taskId];
        Provider storage provider = providers[_providerAddress];

        // Slash the provider
        _slashProvider(_providerAddress, _reason);

        // Refund requester stake and reward
        uint256 refundAmount = task.reward + task.requesterStake;
        _requesterBalances[task.requester] += refundAmount;

        // Mark task as failed
        task.status = TaskStatus.Failed;
        task.verificationStatus = VerificationStatus.Rejected; // Explicitly mark verification rejected

        // Update provider's active task count
         if (provider.tasksInProgress > 0) {
             provider.tasksInProgress--;
         }

         // Finalize event will be emitted by finalizeTask if called afterwards,
         // or manually here if we don't require separate finalization after failure
         // Let's emit a failure event here for clarity
         // emit TaskFailed(_taskId, _providerAddress, _reason); // Add TaskFailed event if desired
         // And then the main Finalize event will cover the final state transition
    }

     /// @notice Internal function to handle successful task completion.
     /// @param _taskId The ID of the task.
     /// @param task The task struct reference.
     /// @param provider The provider struct reference.
    function _finalizeSuccessfulTask(uint256 _taskId, Task storage task, Provider storage provider) internal {
        uint256 totalReward = task.reward;
        uint256 commissionAmount = (totalReward * commissionRate) / 100;
        uint256 providerPayment = totalReward - commissionAmount;

        // Transfer payment to provider's deposit balance
        // Note: Provider needs to withdraw explicitly using withdrawPaymentToken
        _requesterBalances[task.requester] += task.requesterStake; // Return requester stake
        _requesterBalances[task.requester] -= task.reward; // Deduct total reward (stake already deducted upon creation)

        // Add provider payment to their balance
        _requesterBalances[task.provider] += providerPayment;

        // Commission goes to the vault (or stays in contract for admin withdraw)
        // Staying in contract for admin withdraw is simpler with internal balances
        // The commission amount is implicitly left in the contract's balance from the requester's deposit
        // No explicit transfer to commissionVault is needed here if using internal balances for requesters.

        // Update provider reputation - positive
        _updateReputationScore(task.provider, 10); // Example: +10 points

        task.status = TaskStatus.Completed;
        task.verificationStatus = VerificationStatus.Approved; // Explicitly mark verification approved

         // Update provider's active task count
         if (provider.tasksInProgress > 0) {
             provider.tasksInProgress--;
         }
    }

    // --- Verification Management ---

    /// @notice Owner registers an address as an authorized verifier.
    /// @param _verifier The address to register.
    function registerVerifier(address _verifier) external onlyOwner whenNotPaused {
        require(_verifier != address(0), "Verifier address cannot be zero");
        require(!_registeredVerifiers.contains(_verifier), "Address is already a registered verifier");
        _registeredVerifiers.add(_verifier);
        emit VerifierRegistered(_verifier);
    }

    /// @notice Owner unregisters an address as an authorized verifier.
    /// @param _verifier The address to unregister.
    function unregisterVerifier(address _verifier) external onlyOwner whenNotPaused {
        require(_registeredVerifiers.contains(_verifier), "Address is not a registered verifier");
        _registeredVerifiers.remove(_verifier);
        emit VerifierUnregistered(_verifier);
    }

    // --- Admin & Configuration ---

    /// @notice Owner sets the minimum required network token stake for providers.
    /// @param _amount The new minimum stake amount.
    function setRequiredProviderStake(uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than 0");
        requiredProviderStake = _amount;
        emit ParametersUpdated("requiredProviderStake", _amount);
    }

    /// @notice Owner sets the percentage of reward required as requester stake.
    /// @param _rate The new stake rate (e.g., 10 for 10%).
    function setTaskStakeRate(uint256 _rate) external onlyOwner whenNotPaused {
        require(_rate <= 100, "Stake rate cannot exceed 100%");
        taskStakeRate = _rate;
        emit ParametersUpdated("taskStakeRate", _rate);
    }

    /// @notice Owner sets the platform commission percentage on task rewards.
    /// @param _rate The new commission rate (e.g., 5 for 5%).
    function setCommissionRate(uint256 _rate) external onlyOwner whenNotPaused {
        require(_rate <= 100, "Commission rate cannot exceed 100%");
        commissionRate = _rate;
        emit ParametersUpdated("commissionRate", _rate);
    }

     /// @notice Owner sets the duration of the challenge period after result submission.
    /// @param _duration The new duration in seconds.
    function setChallengePeriod(uint64 _duration) external onlyOwner whenNotPaused {
        require(_duration > 0, "Challenge period must be greater than 0");
        challengePeriodDuration = _duration;
        emit ParametersUpdated("challengePeriodDuration", _duration);
    }

    /// @notice Owner sets the maximum time allowed for a provider to complete a task.
    /// @param _duration The new duration in seconds.
    function setTaskTimeout(uint64 _duration) external onlyOwner whenNotPaused {
        require(_duration > 0, "Task timeout must be greater than 0");
        taskTimeoutDuration = _duration;
        emit ParametersUpdated("taskTimeoutDuration", _duration);
    }

    /// @notice Pauses core contract functionality.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract functionality.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- View Functions ---

    /// @notice Gets details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return task struct details.
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        if (tasks[_taskId].taskId == 0) revert TaskNotFound(_taskId); // Check if task exists
        return tasks[_taskId];
    }

     /// @notice Gets details of a specific provider.
    /// @param _provider The address of the provider.
    /// @return provider struct details.
    function getProviderDetails(address _provider) external view returns (Provider memory) {
         if (!providers[_provider].isRegistered) revert ProviderNotFound(_provider);
        return providers[_provider];
    }

    /// @notice Gets the payment token balance deposited by a requester.
    /// @param _requester The address of the requester.
    /// @return The balance amount.
    function getRequesterBalance(address _requester) external view returns (uint256) {
        return _requesterBalances[_requester];
    }

     /// @notice Gets the network token stake deposited by a provider.
    /// @param _provider The address of the provider.
    /// @return The staked amount.
    function getProviderStake(address _provider) external view returns (uint256) {
        // This returns the amount in the *deposit* balance, not the currently staked amount in the Provider struct.
        // To get staked amount, use getProviderDetails.
        // Let's clarify this function name or return the staked amount from the Provider struct.
        // Renaming to getProviderDepositBalance for clarity.
         return _providerStakes[_provider];
    }
     // Adding a clear function for staked amount
     function getProviderStakedAmount(address _provider) external view returns (uint256) {
          if (!providers[_provider].isRegistered) return 0; // Or revert ProviderNotFound(_provider);
          return providers[_provider].stake;
     }


    /// @notice Gets a list of task IDs that are currently open for claiming.
    /// @dev This is inefficient for large numbers of tasks. Off-chain indexing is recommended.
    /// @return An array of task IDs in the Open state.
    function getAvailableTasks() external view returns (uint256[] memory) {
        // Note: Iterating over mappings is not directly possible or efficient on-chain.
        // This function requires iterating through task IDs from 1 up to _nextTaskId.
        // For practical dApps, filtering/fetching task lists should be done off-chain
        // by querying blockchain events or a separate indexer.
        // This implementation provides a basic, potentially inefficient, on-chain way.
        uint256[] memory openTasks = new uint256[](_nextTaskId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < _nextTaskId; i++) {
            if (tasks[i].taskId != 0 && tasks[i].status == TaskStatus.Open) { // Check tasks[i].taskId != 0 to avoid default struct issues for non-existent tasks below _nextTaskId but deleted/skipped.
                openTasks[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of open tasks
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTasks[i];
        }
        return result;
    }

    /// @notice Gets a list of task IDs created by a specific requester.
    /// @dev Similar efficiency concerns as `getAvailableTasks`. Use off-chain indexing for production.
    /// @param _requester The address of the requester.
    /// @return An array of task IDs.
    function getTasksByRequester(address _requester) external view returns (uint256[] memory) {
        uint256[] memory requesterTasks = new uint256[](_nextTaskId - 1);
        uint256 count = 0;
         for (uint256 i = 1; i < _nextTaskId; i++) {
            if (tasks[i].taskId != 0 && tasks[i].requester == _requester) {
                requesterTasks[count] = i;
                count++;
            }
        }
         uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = requesterTasks[i];
        }
        return result;
    }

    /// @notice Gets a list of task IDs claimed by a specific provider.
    /// @dev Similar efficiency concerns as `getAvailableTasks`. Use off-chain indexing for production.
    /// @param _provider The address of the provider.
    /// @return An array of task IDs.
     function getTasksByProvider(address _provider) external view returns (uint256[] memory) {
        uint256[] memory providerTasks = new uint256[](_nextTaskId - 1);
        uint256 count = 0;
         for (uint256 i = 1; i < _nextTaskId; i++) {
            if (tasks[i].taskId != 0 && tasks[i].provider == _provider) {
                providerTasks[count] = i;
                count++;
            }
        }
         uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = providerTasks[i];
        }
        return result;
    }


    /// @notice Gets the list of addresses registered as authorized verifiers.
    /// @dev Uses EnumerableSet, which is suitable for smaller sets of addresses.
    /// @return An array of verifier addresses.
    function getRegisteredVerifiers() external view returns (address[] memory) {
        return _registeredVerifiers.values();
    }
}
```