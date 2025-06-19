Okay, let's create a smart contract concept that's a bit more involved than standard DeFi or NFT operations. How about a decentralized marketplace for *verifiable* off-chain computation tasks, specifically tailored for something trendy like *AI model evaluation or specific data processing jobs*. The 'advanced concept' is managing staked participants, incentivizing honest off-chain work, handling result submission, validation, and a simplified dispute resolution mechanism, all tied together on-chain.

We won't implement the actual AI/computation, as that's off-chain, but the contract will orchestrate the process, manage funds, and enforce rules based on submitted proofs/results/stakes.

**Concept:** Decentralized Verifiable Computation Marketplace (DVCM) - Focused on AI/ML tasks.

**Roles:**
1.  **Task Requester:** Posts a job, specifies computation requirements (via hash/URI), provides input data hash/URI, sets budget, and defines output requirements. Stakes funds.
2.  **Compute Provider:** Stakes tokens (or ETH) to signal availability and trustworthiness. Selects an open task, performs the computation off-chain, and submits the result hash/URI and proof (simplified for this example, could be ZK proofs, optimistic rollups, etc. - here we just assume a hash and metrics). Gets rewarded on success.
3.  **Validator:** Stakes tokens (or ETH) to signal availability and trustworthiness. Selects a *completed* task, verifies the Compute Provider's result (off-chain, based on submitted proof/metrics), and submits a validation outcome (approve/reject) on-chain. Gets rewarded for honest validation.
4.  **Arbitrator (Simplified):** A designated entity (could be a DAO, a committee, or for simplicity here, the contract owner) resolves disputes between Requesters, Compute Providers, and Validators. Can slash stakes.

**Advanced Concepts Used:**
*   **Staking:** Participants stake capital to gain roles and show commitment, subject to slashing.
*   **Escrow:** Task funds are held in escrow until completion or dispute resolution.
*   **Lifecycle Management:** Tasks transition through defined states (Open, Computation, Validation, Completed, Disputed, Failed, Cancelled).
*   **Incentive Alignment:** Rewards are distributed for successful task completion and validation. Slashing punishes dishonest or incorrect submissions/validations.
*   **Off-chain Coordination / On-chain Verification:** Contract orchestrates off-chain work by managing state and verifying simple proofs (hashes, metrics) submitted on-chain. True result verification happens off-chain, but the *outcome* of verification is submitted on-chain, backed by validator stake.
*   **Dispute Resolution:** A mechanism (simplified) exists to resolve disagreements and maintain trust.
*   **Role-Based Access:** Functions are restricted based on participant roles and task status.

**Non-Duplication:** While staking, escrow, and marketplaces exist, combining them specifically for a verifiable computation marketplace with distinct roles for data/compute/validation, managing a complex lifecycle with explicit validation and dispute resolution around off-chain AI/ML-like tasks, and aiming for this many specific functions is less likely to be a direct clone of a single prominent open-source project.

---

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports** (Using OpenZeppelin for Context, Pausable, Ownable is fine as these are standard building blocks, not the core concept)
3.  **Error Definitions**
4.  **Events:** To signal state changes (Task created, started, results submitted, validated, disputed, resolved, stakes updated, slashed, rewards claimed, etc.)
5.  **Enums:** TaskStatus
6.  **Structs:** Task details, Provider registration info (stake, active tasks), potential future reputation.
7.  **State Variables:** Mappings for tasks, providers (Data, Compute, Validator), minimum stakes, fees, task counter.
8.  **Modifiers:** `whenNotPaused`, `onlyOwner`, `requireTaskStatus`, `requireRegistered`, `requireTaskAssignee`.
9.  **Functions (>= 20):**
    *   **Admin/Platform (Owner):** Set fees/stakes, manage pausing, resolve disputes, withdraw fees.
    *   **Provider Registration:** Register/deregister roles (Data, Compute, Validator) by staking.
    *   **Task Management (Requester):** Create task, cancel task, fund task, accept completion, dispute.
    *   **Task Workflow (Compute Provider):** Claim task, submit results.
    *   **Task Workflow (Validator):** Claim validation, submit validation result.
    *   **Dispute Resolution (Owner):** Resolve dispute (determines outcome and triggers potential slashing/rewards).
    *   **Claiming:** Claim rewards (Compute, Data, Validator), claim refund (Requester).
    *   **Viewing:** Get task details, get provider status.

---

**Function Summary:**

*   `constructor(uint256 _minDataStake, uint256 _minComputeStake, uint256 _minValidatorStake, uint256 _platformFeePercent)`: Initializes contract owner, minimum stakes for different roles, and platform fee percentage.
*   `pause()`: Admin function to pause contract (OpenZeppelin Pausable).
*   `unpause()`: Admin function to unpause contract (OpenZeppelin Pausable).
*   `setMinStakes(uint256 _minDataStake, uint256 _minComputeStake, uint256 _minValidatorStake)`: Admin function to update minimum stake requirements.
*   `setPlatformFeePercent(uint256 _platformFeePercent)`: Admin function to update the platform fee percentage.
*   `withdrawPlatformFees()`: Admin function to withdraw accumulated platform fees.
*   `registerDataProvider()`: Stake required amount to become a Data Provider.
*   `deregisterDataProvider()`: Withdraw stake and unregister as Data Provider (only if no active tasks).
*   `registerComputeProvider()`: Stake required amount to become a Compute Provider.
*   `deregisterComputeProvider()`: Withdraw stake and unregister as Compute Provider (only if no active tasks).
*   `registerValidator()`: Stake required amount to become a Validator.
*   `deregisterValidator()`: Withdraw stake and unregister as Validator (only if no active tasks).
*   `createTrainingTask(bytes32 _dataRequirementsHash, bytes32 _computeRequirementsHash, bytes32 _outputRequirementsHash, uint256 _dataReward, uint256 _computeReward, uint256 _validatorReward)`: Requester creates a task, specifying requirements and reward distribution. Requires attaching total budget (`msg.value`).
*   `cancelTrainingTask(uint256 _taskId)`: Requester cancels an open task before computation starts, getting a refund.
*   `submitTrainingData(uint256 _taskId, bytes32 _dataHash)`: Registered Data Provider submits data hash for an open task.
*   `claimTaskForTraining(uint256 _taskId)`: Registered Compute Provider claims an available task to perform computation.
*   `submitTrainingResults(uint256 _taskId, bytes32 _resultsHash, bytes32 _metricsHash)`: Assigned Compute Provider submits computation results and metrics hashes.
*   `claimTaskForValidation(uint256 _taskId)`: Registered Validator claims a completed task to validate the results.
*   `submitValidationResult(uint256 _taskId, bool _isValid)`: Assigned Validator submits their validation outcome (true for valid, false for invalid).
*   `acceptTaskCompletion(uint256 _taskId)`: Requester explicitly accepts a validated result (if they agree with the validation outcome, alternative to dispute). This triggers reward distribution.
*   `disputeTaskCompletion(uint256 _taskId)`: Requester disagrees with the validation outcome, initiating a dispute.
*   `resolveDispute(uint256 _taskId, address _slashedAddress, uint256 _slashAmount, bool _requesterWins)`: Admin resolves a dispute. Determines who was wrong (_slashedAddress gets slashed), amount, and if requester's view prevails (triggers rewards based on that).
*   `claimDataRewards(uint256 _taskId)`: Data Providers claim rewards for a completed/resolved task they contributed data to. (Simplified: Distributes pool among all who submitted data before computation started).
*   `claimComputeReward(uint256 _taskId)`: Compute Provider claims reward for a successfully completed/resolved task they trained.
*   `claimValidationReward(uint256 _taskId)`: Validator claims reward for a successfully completed/resolved task they validated correctly.
*   `claimRequesterRefund(uint256 _taskId)`: Requester claims refund for a cancelled or failed task.
*   `getTaskDetails(uint256 _taskId)`: View function to get details of a specific task.
*   `getDataProviderStatus(address _provider)`: View function to get status of a Data Provider.
*   `getComputeProviderStatus(address _provider)`: View function to get status of a Compute Provider.
*   `getValidatorStatus(address _validator)`: View function to get status of a Validator.

Let's start coding!

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. SPDX License & Pragma
// 2. Imports (OpenZeppelin for standard features)
// 3. Error Definitions
// 4. Events
// 5. Enums (TaskStatus)
// 6. Structs (Task, Provider registration status)
// 7. State Variables (Mappings for tasks, providers, stakes, fees, counters)
// 8. Modifiers (whenNotPaused, onlyOwner, requireTaskStatus, requireRegistered, requireTaskAssignee)
// 9. Functions (Admin, Provider Reg/Dereg, Task Management, Workflow, Dispute, Claims, View)

// Function Summary:
// Admin/Platform (Owner):
// - constructor: Initializes contract owner, min stakes, platform fee.
// - pause/unpause: Pauses/unpauses contract operations.
// - setMinStakes: Updates minimum stake requirements for roles.
// - setPlatformFeePercent: Updates the platform fee percentage.
// - withdrawPlatformFees: Withdraws accumulated platform fees.
// - resolveDispute: Owner decides the outcome of a dispute, potentially slashing stake and determining task finality.

// Provider Registration:
// - registerDataProvider: Stakes ETH to become a Data Provider.
// - deregisterDataProvider: Unstakes ETH and deregisters as Data Provider (if no active tasks).
// - registerComputeProvider: Stakes ETH to become a Compute Provider.
// - deregisterComputeProvider: Unstakes ETH and deregisters as Compute Provider (if no active tasks).
// - registerValidator: Stakes ETH to become a Validator.
// - deregisterValidator: Unstakes ETH and deregisters as Validator (if no active tasks).

// Task Management (Requester):
// - createTrainingTask: Creates a new task, funds it, defines requirements and rewards.
// - cancelTrainingTask: Cancels an open task and gets a refund.
// - acceptTaskCompletion: Requester agrees with validation result, completing the task.
// - disputeTaskCompletion: Requester disagrees with validation result, initiating dispute.

// Task Workflow:
// - submitTrainingData: Data Provider submits data hash for a task.
// - claimTaskForTraining: Compute Provider claims an open task to perform computation.
// - submitTrainingResults: Compute Provider submits computation results and metrics hashes.
// - claimTaskForValidation: Validator claims a task awaiting validation.
// - submitValidationResult: Validator submits outcome of their validation.

// Claiming:
// - claimDataRewards: Data Provider claims rewards for a completed task they contributed data to.
// - claimComputeReward: Compute Provider claims reward for successfully trained tasks.
// - claimValidationReward: Validator claims reward for successfully validated tasks.
// - claimRequesterRefund: Requester claims refund for cancelled/failed tasks.

// Viewing:
// - getTaskDetails: Retrieves details of a specific task.
// - getDataProviderStatus: Retrieves status of a Data Provider.
// - getComputeProviderStatus: Retrieves status of a Compute Provider.
// - getValidatorStatus: Retrieves status of a Validator.

// Note: Off-chain computation and data storage (like IPFS) are external to the contract.
// The contract primarily manages the task lifecycle, fund escrow, and participant stakes
// based on submitted hashes and validation outcomes. Dispute resolution is centralized
// with the owner for simplicity in this example but could be decentralized in a real system.

contract DecentralizedVerifiableComputationMarketplace is Ownable, Pausable, ReentrancyGuard {

    // --- Error Definitions ---
    error TaskNotFound();
    error InvalidTaskStatus();
    error AlreadyRegistered();
    error NotRegistered();
    error InsufficientStake();
    error TaskNotClaimedByYou();
    error TaskAlreadyClaimed();
    error NoActiveTasksToDeregister();
    error StakeLockedInActiveTasks();
    error InvalidPlatformFeePercent();
    error InsufficientBudget();
    error NothingToWithdraw();
    error NotPermitted();
    error DisputeAlreadyResolved();
    error TaskNotDisputed();
    error CannotSubmitDataAfterComputeStarted();
    error TaskNotReadyForValidation();
    error TaskNotReadyForCompute();

    // --- Events ---
    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 budget, uint256 dataReward, uint256 computeReward, uint256 validatorReward, bytes32 dataRequirementsHash, bytes32 computeRequirementsHash, bytes32 outputRequirementsHash);
    event TaskStatusChanged(uint256 indexed taskId, TaskStatus newStatus, TaskStatus oldStatus);
    event DataSubmitted(uint256 indexed taskId, address indexed provider, bytes32 dataHash);
    event TaskClaimedForCompute(uint256 indexed taskId, address indexed computeProvider);
    event ResultsSubmitted(uint256 indexed taskId, address indexed computeProvider, bytes32 resultsHash, bytes32 metricsHash);
    event TaskClaimedForValidation(uint256 indexed taskId, address indexed validator);
    event ValidationSubmitted(uint256 indexed taskId, address indexed validator, bool isValid);
    event TaskCompleted(uint256 indexed taskId, address indexed finalValidator); // Indicates task finished successfully based on validation/acceptance
    event TaskCancelled(uint256 indexed taskId, address indexed requester);
    event DisputeInitiated(uint256 indexed taskId, address indexed disputer);
    event DisputeResolved(uint256 indexed taskId, bool requesterWins, address indexed slashedAddress, uint256 slashAmount);
    event StakeUpdated(address indexed provider, uint256 newTotalStake, string role);
    event StakeSlashed(address indexed provider, uint256 slashAmount, string reason);
    event RewardsClaimed(uint256 indexed taskId, address indexed claimant, uint256 amount);
    event RefundClaimed(uint256 indexed taskId, address indexed claimant, uint256 amount);
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);
    event MinStakesUpdated(uint256 minData, uint256 minCompute, uint256 minValidator);
    event PlatformFeePercentUpdated(uint256 newPercent);
    event ProviderRegistered(address indexed provider, string role, uint256 initialStake);
    event ProviderDeregistered(address indexed provider, string role, uint256 remainingStake);


    // --- Enums ---
    enum TaskStatus {
        Open,               // Task created, awaiting data submissions
        DataSubmission,     // Task accepting data submissions (same as Open, perhaps redundant but clearer lifecycle)
        Compute,            // Data submission phase over, awaiting Compute Provider to claim and submit results
        Validation,         // Results submitted, awaiting Validator to claim and validate
        Completed,          // Task successfully completed and validated/accepted, funds ready for distribution
        Disputed,           // Task is under dispute
        Failed,             // Task failed (e.g., compute/validation failed and not resolved favorably)
        Cancelled           // Task cancelled by requester
    }

    // --- Structs ---
    struct Task {
        uint256 id;
        address payable requester;
        uint256 budget; // Total budget provided by requester
        bytes32 dataRequirementsHash; // Hash of data requirements (e.g., structure, format)
        bytes32 computeRequirementsHash; // Hash of compute requirements (e.g., model architecture, parameters, software stack)
        bytes32 outputRequirementsHash; // Hash of output requirements (e.g., format for results/metrics)

        uint256 dataReward;     // ETH allocated for Data Providers pool
        uint256 computeReward;  // ETH allocated for the winning Compute Provider
        uint256 validatorReward; // ETH allocated for the winning Validator
        uint256 platformFee;    // ETH allocated for platform fee

        TaskStatus status;
        address assignedComputeProvider; // Address of the Compute Provider who claimed the task
        address assignedValidator;       // Address of the Validator who claimed the task

        bytes32 resultsHash; // Hash of submitted computation results
        bytes32 metricsHash; // Hash of submitted evaluation metrics
        bool validationOutcome; // True if validator marked as valid, False if invalid

        uint40 creationTime;
        uint40 completionTime; // Time when task enters Completed, Failed, or Cancelled state
    }

    struct ProviderInfo {
        uint256 totalStake; // Total ETH staked by this provider
        uint256 activeTasksCount; // Number of tasks where this provider is actively involved (staked for data, assigned compute/validator)
        // uint256 reputationScore; // Future enhancement: track reputation
        bool isRegistered;
    }

    // --- State Variables ---
    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;

    mapping(address => ProviderInfo) public dataProviders;
    mapping(address => ProviderInfo) public computeProviders;
    mapping(address => ProviderInfo) public validators;

    // Keep track of data submissions per task
    mapping(uint256 => mapping(address => bytes32)) private taskDataSubmissions;
    // Keep track of which data providers submitted data for a task (for reward distribution)
    mapping(uint256 => address[]) private taskDataContributors;
    // Prevent double claiming rewards
    mapping(uint256 => mapping(address => bool)) private dataRewardClaimed;
    mapping(uint256 => mapping(address => bool)) private computeRewardClaimed;
    mapping(uint256 => mapping(address => bool)) private validatorRewardClaimed;
    mapping(uint256 => mapping(address => bool)) private requesterRefundClaimed;


    uint256 public minDataStake;
    uint256 public minComputeStake;
    uint256 public minValidatorStake;
    uint256 public platformFeePercent; // In basis points (e.g., 100 for 1%)
    uint256 private totalPlatformFees;

    // --- Modifiers ---
    modifier requireTaskStatus(uint256 _taskId, TaskStatus _expectedStatus) {
        if (tasks[_taskId].status != _expectedStatus) {
            revert InvalidTaskStatus();
        }
        _;
    }

    modifier requireAnyTaskStatus(uint256 _taskId, TaskStatus[] memory _expectedStatuses) {
        bool statusMatch = false;
        for (uint i = 0; i < _expectedStatuses.length; i++) {
            if (tasks[_taskId].status == _expectedStatuses[i]) {
                statusMatch = true;
                break;
            }
        }
        if (!statusMatch) {
             revert InvalidTaskStatus();
        }
        _;
    }

    modifier requireRegistered(address _provider, string memory _role) {
        if (compareStrings(_role, "data")) {
            if (!dataProviders[_provider].isRegistered) revert NotRegistered();
        } else if (compareStrings(_role, "compute")) {
            if (!computeProviders[_provider].isRegistered) revert NotRegistered();
        } else if (compareStrings(_role, "validator")) {
            if (!validators[_provider].isRegistered) revert NotRegistered();
        } else {
            revert NotPermitted(); // Should not happen with correct usage
        }
        _;
    }

    modifier requireTaskAssignee(uint256 _taskId, string memory _role) {
        if (compareStrings(_role, "compute")) {
             if (tasks[_taskId].assignedComputeProvider != _msgSender()) revert TaskNotClaimedByYou();
        } else if (compareStrings(_role, "validator")) {
             if (tasks[_taskId].assignedValidator != _msgSender()) revert TaskNotClaimedByYou();
        } else {
             revert NotPermitted(); // Should not happen
        }
        _;
    }

    // --- Constructor ---
    constructor(uint256 _minDataStake, uint256 _minComputeStake, uint256 _minValidatorStake, uint256 _platformFeePercent) Ownable(_msgSender()) Pausable() {
        if (_platformFeePercent > 10000) revert InvalidPlatformFeePercent(); // Max 100%
        minDataStake = _minDataStake;
        minComputeStake = _minComputeStake;
        minValidatorStake = _minValidatorStake;
        platformFeePercent = _platformFeePercent;
        taskCounter = 0; // Tasks start from 1
    }

    // --- Admin Functions ---
    function setMinStakes(uint256 _minDataStake, uint256 _minComputeStake, uint256 _minValidatorStake) public onlyOwner {
        minDataStake = _minDataStake;
        minComputeStake = _minComputeStake;
        minValidatorStake = _minValidatorStake;
        emit MinStakesUpdated(minDataStake, minComputeStake, minValidatorStake);
    }

    function setPlatformFeePercent(uint256 _platformFeePercent) public onlyOwner {
         if (_platformFeePercent > 10000) revert InvalidPlatformFeePercent(); // Max 100%
        platformFeePercent = _platformFeePercent;
        emit PlatformFeePercentUpdated(platformFeePercent);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = totalPlatformFees;
        if (amount == 0) revert NothingToWithdraw();
        totalPlatformFees = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit PlatformFeesWithdrawn(owner(), amount);
    }

    function resolveDispute(uint256 _taskId, address _slashedAddress, uint256 _slashAmount, bool _requesterWins) public onlyOwner nonReentrant requireTaskStatus(_taskId, TaskStatus.Disputed) {
        Task storage task = tasks[_taskId];
        if (task.completionTime != 0) revert DisputeAlreadyResolved(); // Safety check

        // Determine who gets potentially slashed
        ProviderInfo storage slashedProvider;
        string memory slashedRole;
        bool providerFound = false;

        if (dataProviders[_slashedAddress].isRegistered && dataProviders[_slashedAddress].totalStake >= _slashAmount) {
             slashedProvider = dataProviders[_slashedAddress];
             slashedRole = "data";
             providerFound = true;
        } else if (computeProviders[_slashedAddress].isRegistered && computeProviders[_slashedAddress].totalStake >= _slashAmount) {
             slashedProvider = computeProviders[_slashedAddress];
             slashedRole = "compute";
             providerFound = true;
        } else if (validators[_slashedAddress].isRegistered && validators[_slashedAddress].totalStake >= _slashAmount) {
             slashedProvider = validators[_slashedAddress];
             slashedRole = "validator";
             providerFound = true;
        }

        if (providerFound && slashedProvider.totalStake >= _slashAmount) {
            slashedProvider.totalStake -= _slashAmount;
            // The slashed amount could go to the requester, or platform fees, or specific providers, or burned.
            // For simplicity, let's add it to platform fees.
            totalPlatformFees += _slashAmount;
            emit StakeSlashed(_slashedAddress, _slashAmount, "Dispute Resolution");
            emit StakeUpdated(_slashedAddress, slashedProvider.totalStake, slashedRole);
        } else if (_slashAmount > 0) {
             // If slashing was intended but the address wasn't a registered provider with enough stake,
             // this indicates an issue or a deliberate attempt to slash a non-provider.
             // Handle as appropriate - here, we'll just revert to indicate the slash wasn't possible as specified.
             // A real system might handle this differently (e.g., log error, proceed without slashing).
             revert NotPermitted(); // Or a more specific error like InsufficientStake or NotRegistered
        }


        // Based on resolution, set final status and potential outcome for reward claiming
        if (_requesterWins) {
            // Requester won the dispute. This might mean the results were bad, or validation was wrong.
            // Mark task as failed or allow requester to claim refund/re-open?
            // Let's mark as Failed. Rewards are not distributed except potentially refund.
            task.status = TaskStatus.Failed;
            task.completionTime = uint40(block.timestamp);
        } else {
            // Requester lost the dispute. This implies the original validation outcome stands.
            // If validation was true -> task completed. If false -> task failed based on validation.
             if (task.validationOutcome) {
                 task.status = TaskStatus.Completed;
             } else {
                 task.status = TaskStatus.Failed; // Validator said it was invalid, and dispute upheld this
             }
            task.completionTime = uint40(block.timestamp);
        }

        emit DisputeResolved(_taskId, _requesterWins, _slashedAddress, _slashAmount);
        emit TaskStatusChanged(_taskId, task.status, TaskStatus.Disputed);
    }


    // --- Provider Registration ---

    function registerDataProvider() public payable whenNotPaused nonReentrant {
        if (dataProviders[_msgSender()].isRegistered) revert AlreadyRegistered();
        if (msg.value < minDataStake) revert InsufficientStake();

        dataProviders[_msgSender()].totalStake = msg.value;
        dataProviders[_msgSender()].isRegistered = true;
        emit ProviderRegistered(_msgSender(), "data", msg.value);
        emit StakeUpdated(_msgSender(), msg.value, "data");
    }

     function deregisterDataProvider() public whenNotPaused nonReentrant requireRegistered(_msgSender(), "data") {
        if (dataProviders[_msgSender()].activeTasksCount > 0) revert StakeLockedInActiveTasks();

        uint256 amount = dataProviders[_msgSender()].totalStake;
        if (amount == 0) revert NothingToWithdraw(); // Should not happen if registered

        dataProviders[_msgSender()].totalStake = 0;
        dataProviders[_msgSender()].isRegistered = false;

        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit ProviderDeregistered(_msgSender(), "data", 0);
        emit StakeUpdated(_msgSender(), 0, "data");
     }

    function registerComputeProvider() public payable whenNotPaused nonReentrant {
        if (computeProviders[_msgSender()].isRegistered) revert AlreadyRegistered();
        if (msg.value < minComputeStake) revert InsufficientStake();

        computeProviders[_msgSender()].totalStake = msg.value;
        computeProviders[_msgSender()].isRegistered = true;
        emit ProviderRegistered(_msgSender(), "compute", msg.value);
        emit StakeUpdated(_msgSender(), msg.value, "compute");
    }

    function deregisterComputeProvider() public whenNotPaused nonReentrant requireRegistered(_msgSender(), "compute") {
        if (computeProviders[_msgSender()].activeTasksCount > 0) revert StakeLockedInActiveTasks();

        uint256 amount = computeProviders[_msgSender()].totalStake;
        if (amount == 0) revert NothingToWithdraw(); // Should not happen if registered

        computeProviders[_msgSender()].totalStake = 0;
        computeProviders[_msgSender()].isRegistered = false;

        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit ProviderDeregistered(_msgSender(), "compute", 0);
        emit StakeUpdated(_msgSender(), 0, "compute");
    }


    function registerValidator() public payable whenNotPaused nonReentrant {
        if (validators[_msgSender()].isRegistered) revert AlreadyRegistered();
        if (msg.value < minValidatorStake) revert InsufficientStake();

        validators[_msgSender()].totalStake = msg.value;
        validators[_msgSender()].isRegistered = true;
        emit ProviderRegistered(_msgSender(), "validator", msg.value);
        emit StakeUpdated(_msgSender(), msg.value, "validator");
    }

    function deregisterValidator() public whenNotPaused nonReentrant requireRegistered(_msgSender(), "validator") {
        if (validators[_msgSender()].activeTasksCount > 0) revert StakeLockedInActiveTasks();

        uint256 amount = validators[_msgSender()].totalStake;
        if (amount == 0) revert NothingToWithdraw(); // Should not happen if registered

        validators[_msgSender()].totalStake = 0;
        validators[_msgSender()].isRegistered = false;

        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit ProviderDeregistered(_msgSender(), "validator", 0);
        emit StakeUpdated(_msgSender(), 0, "validator");
    }


    // --- Task Management (Requester) ---

    function createTrainingTask(
        bytes32 _dataRequirementsHash,
        bytes32 _computeRequirementsHash,
        bytes32 _outputRequirementsHash,
        uint256 _dataReward,
        uint256 _computeReward,
        uint256 _validatorReward
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        uint256 totalReward = _dataReward + _computeReward + _validatorReward;
        uint256 feeAmount = (totalReward * platformFeePercent) / 10000;
        uint256 requiredBudget = totalReward + feeAmount;

        if (msg.value < requiredBudget) revert InsufficientBudget();

        taskCounter++;
        uint256 _taskId = taskCounter;

        tasks[_taskId] = Task({
            id: _taskId,
            requester: payable(_msgSender()),
            budget: msg.value, // Store actual amount sent
            dataRequirementsHash: _dataRequirementsHash,
            computeRequirementsHash: _computeRequirementsHash,
            outputRequirementsHash: _outputRequirementsHash,
            dataReward: _dataReward,
            computeReward: _computeReward,
            validatorReward: _validatorReward,
            platformFee: feeAmount,
            status: TaskStatus.DataSubmission, // Starts in data submission phase
            assignedComputeProvider: address(0),
            assignedValidator: address(0),
            resultsHash: bytes32(0),
            metricsHash: bytes32(0),
            validationOutcome: false, // Default value
            creationTime: uint40(block.timestamp),
            completionTime: 0
        });

        totalPlatformFees += feeAmount; // Add fee to platform balance immediately

        emit TaskCreated(_taskId, _msgSender(), msg.value, _dataReward, _computeReward, _validatorReward, _dataRequirementsHash, _computeRequirementsHash, _outputRequirementsHash);
        emit TaskStatusChanged(_taskId, TaskStatus.DataSubmission, TaskStatus.Open); // Open state is just conceptual before creation
        return _taskId;
    }

    function cancelTrainingTask(uint256 _taskId) public whenNotPaused nonReentrant requireTaskStatus(_taskId, TaskStatus.DataSubmission) {
        Task storage task = tasks[_taskId];
        if (task.requester != _msgSender()) revert NotPermitted();

        // Refund remaining budget (full budget less platform fee, as fee is collected on creation)
        uint256 refundAmount = task.budget - task.platformFee;
        // Note: platform fee is kept even if cancelled. Could change this logic.

        task.status = TaskStatus.Cancelled;
        task.completionTime = uint40(block.timestamp);

        // No need to track data providers for refund as they didn't stake per task, only contributed data.
        // If they staked *per task* for data, that would need refunding here.
        // Since stake is global, they just lose potential rewards.

        // Transfer refund to requester
        (bool success, ) = payable(task.requester).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit TaskCancelled(_taskId, _msgSender());
        emit TaskStatusChanged(_taskId, TaskStatus.Cancelled, TaskStatus.DataSubmission);
    }

    function acceptTaskCompletion(uint256 _taskId) public whenNotPaused nonReentrant requireAnyTaskStatus(_taskId, new TaskStatus[](2){ TaskStatus.Validation, TaskStatus.Disputed }) {
         Task storage task = tasks[_taskId];
         if (task.requester != _msgSender()) revert NotPermitted();
         if (task.status == TaskStatus.Disputed && task.completionTime != 0) revert DisputeAlreadyResolved(); // Already resolved by owner
         if (task.status == TaskStatus.Validation && task.assignedValidator == address(0)) revert TaskNotReadyForValidation(); // Validation phase but no validator? Should not happen.
         if (task.status == TaskStatus.Validation && task.validationOutcome == false) revert NotPermitted(); // Requester accepting invalid result? Unlikely workflow. Assume requester only accepts *valid* outcomes. If they disagree with valid, they dispute.

         // This function means Requester agrees with a VALID outcome from validation phase, OR manually accepts a Dispute outcome.
         // If status is Validation and outcome is true -> proceed to Completed.
         // If status is Disputed -> This is an alternative way for requester to end dispute *by accepting current state*,
         // but typically dispute resolution is via owner. Let's only allow accepting from Validation status.
         // A better model for Dispute: Requester/Validator/Compute Provider can escalate to dispute. Owner resolves.

         if (task.status == TaskStatus.Validation && task.validationOutcome == true) {
             task.status = TaskStatus.Completed;
             task.completionTime = uint40(block.timestamp);
             // Rewards become claimable
             emit TaskCompleted(_taskId, task.assignedValidator);
             emit TaskStatusChanged(_taskId, TaskStatus.Completed, TaskStatus.Validation);
         } else {
            revert InvalidTaskStatus(); // Only allow accepting from Validation -> True state
         }
    }

    function disputeTaskCompletion(uint256 _taskId) public whenNotPaused nonReentrant requireTaskStatus(_taskId, TaskStatus.Validation) {
         Task storage task = tasks[_taskId];
         if (task.requester != _msgSender()) revert NotPermitted();
         if (task.assignedValidator == address(0)) revert TaskNotReadyForValidation(); // Need a validator result to dispute

         // Requester disagrees with the validation outcome (either true or false).
         // Move task to Disputed state, awaits owner resolution.
         task.status = TaskStatus.Disputed;
         emit DisputeInitiated(_taskId, _msgSender());
         emit TaskStatusChanged(_taskId, TaskStatus.Disputed, TaskStatus.Validation);
    }


    // --- Task Workflow ---

    function submitTrainingData(uint256 _taskId, bytes32 _dataHash) public whenNotPaused requireRegistered(_msgSender(), "data") requireTaskStatus(_taskId, TaskStatus.DataSubmission) {
        Task storage task = tasks[_taskId];

        // Check if provider already submitted data for this task
        if (taskDataSubmissions[_taskId][_msgSender()] != bytes32(0)) {
            // Allow updating data submission? Or only one submission per provider?
            // Let's allow updating for simplicity, but a real system might require unique submissions or versioning.
            // For now, just overwrite.
             taskDataSubmissions[_taskId][_msgSender()] = _dataHash;
             emit DataSubmitted(_taskId, _msgSender(), _dataHash); // Maybe a separate event for update
        } else {
            // First time submission
            taskDataSubmissions[_taskId][_msgSender()] = _dataHash;
            taskDataContributors[_taskId].push(_msgSender()); // Add to list of contributors
            emit DataSubmitted(_taskId, _msgSender(), _dataHash);
        }
    }

    function claimTaskForTraining(uint256 _taskId) public whenNotPaused nonReentrant requireRegistered(_msgSender(), "compute") requireTaskStatus(_taskId, TaskStatus.DataSubmission) {
        Task storage task = tasks[_taskId];
        if (task.assignedComputeProvider != address(0)) revert TaskAlreadyClaimed();
        if (taskDataContributors[_taskId].length == 0) revert TaskNotReadyForCompute(); // Need at least one data submission

        task.assignedComputeProvider = _msgSender();
        computeProviders[_msgSender()].activeTasksCount++;

        task.status = TaskStatus.Compute; // Move to Compute phase
        emit TaskClaimedForCompute(_taskId, _msgSender());
        emit TaskStatusChanged(_taskId, TaskStatus.Compute, TaskStatus.DataSubmission);
    }

    function submitTrainingResults(uint256 _taskId, bytes32 _resultsHash, bytes32 _metricsHash) public whenNotPaused requireTaskStatus(_taskId, TaskStatus.Compute) requireTaskAssignee(_taskId, "compute") {
         Task storage task = tasks[_taskId];

         task.resultsHash = _resultsHash;
         task.metricsHash = _metricsHash;
         task.status = TaskStatus.Validation; // Move to Validation phase
         computeProviders[_msgSender()].activeTasksCount--; // Compute provider finished their part

         emit ResultsSubmitted(_taskId, _msgSender(), _resultsHash, _metricsHash);
         emit TaskStatusChanged(_taskId, TaskStatus.Validation, TaskStatus.Compute);
    }

    function claimTaskForValidation(uint256 _taskId) public whenNotPaused nonReentrant requireRegistered(_msgSender(), "validator") requireTaskStatus(_taskId, TaskStatus.Validation) {
        Task storage task = tasks[_taskId];
        if (task.assignedValidator != address(0)) revert TaskAlreadyClaimed();

        task.assignedValidator = _msgSender();
        validators[_msgSender()].activeTasksCount++;

        // Task remains in Validation status, but is now assigned
        emit TaskClaimedForValidation(_taskId, _msgSender());
    }

    function submitValidationResult(uint256 _taskId, bool _isValid) public whenNotPaused requireTaskStatus(_taskId, TaskStatus.Validation) requireTaskAssignee(_taskId, "validator") {
         Task storage task = tasks[_taskId];

         task.validationOutcome = _isValid;
         validators[_msgSender()].activeTasksCount--; // Validator finished their part

         // The task moves to Completed if Valid, or remains in Validation (or moves to Failed?) if Invalid, awaiting Requester action or dispute.
         // Let's follow the workflow: after validation submitted, it waits for Requester accept or dispute.
         // The task stays in Validation status until Requester accepts or disputes, or owner resolves dispute.
         // The validation outcome is recorded, and the validator is unassigned and activeTasksCount reduced.
         // If Requester accepts the 'true' outcome, it goes to Completed via `acceptTaskCompletion`.
         // If Requester disputes, it goes to Disputed via `disputeTaskCompletion`.

         emit ValidationSubmitted(_taskId, _msgSender(), _isValid);
    }


    // --- Claiming Functions ---

    // Simplified: Data reward split equally among all data providers who submitted data before compute phase started.
    // A more complex system could factor in stake amount at submission, data quality (via validation), etc.
    function claimDataRewards(uint256 _taskId) public nonReentrant requireTaskStatus(_taskId, TaskStatus.Completed) {
        Task storage task = tasks[_taskId];
        address claimant = _msgSender();

        // Check if claimant is a data contributor for this task
        bool isContributor = false;
        for (uint i = 0; i < taskDataContributors[_taskId].length; i++) {
            if (taskDataContributors[_taskId][i] == claimant) {
                isContributor = true;
                break;
            }
        }
        if (!isContributor) revert NotPermitted();
        if (dataRewardClaimed[_taskId][claimant]) revert NothingToWithdraw();

        uint256 totalContributors = taskDataContributors[_taskId].length;
        if (totalContributors == 0) revert NothingToWithdraw(); // Should not happen for Completed task if dataReward > 0

        uint256 rewardPerContributor = task.dataReward / totalContributors;
        if (rewardPerContributor == 0) revert NothingToWithdraw(); // Happens if task.dataReward is 0 or totalContributors is too high

        dataRewardClaimed[_taskId][claimant] = true;

        (bool success, ) = payable(claimant).call{value: rewardPerContributor}("");
        require(success, "Reward claim failed");

        emit RewardsClaimed(_taskId, claimant, rewardPerContributor);
    }

    function claimComputeReward(uint256 _taskId) public nonReentrant requireTaskStatus(_taskId, TaskStatus.Completed) {
        Task storage task = tasks[_taskId];
        address claimant = _msgSender();

        if (task.assignedComputeProvider != claimant) revert NotPermitted(); // Only the assigned CP can claim
        if (computeRewardClaimed[_taskId][claimant]) revert NothingToWithdraw();

        uint256 rewardAmount = task.computeReward;
        if (rewardAmount == 0) revert NothingToWithdraw();

        computeRewardClaimed[_taskId][claimant] = true;

        (bool success, ) = payable(claimant).call{value: rewardAmount}("");
        require(success, "Reward claim failed");

        emit RewardsClaimed(_taskId, claimant, rewardAmount);
    }

    function claimValidationReward(uint256 _taskId) public nonReentrant requireTaskStatus(_taskId, TaskStatus.Completed) {
        Task storage task = tasks[_taskId];
        address claimant = _msgSender();

        // Only the assigned validator who submitted a *correct* outcome can claim.
        // In this simplified model, 'correct' means their validationOutcome matches what led to TaskStatus.Completed.
        // Since the task status is COMPLETED, it implies the validationOutcome recorded led to this state (usually true).
        // If a dispute occurred and was resolved such that the *requester* lost (meaning the validator was right),
        // and the final status is Completed, the original validator also gets reward.
        // Let's simplify: if task.status is Completed, the assigned validator claims if their outcome was true.
        if (task.assignedValidator != claimant || task.validationOutcome != true) revert NotPermitted();
        if (validatorRewardClaimed[_taskId][claimant]) revert NothingToWithdraw();

        uint256 rewardAmount = task.validatorReward;
        if (rewardAmount == 0) revert NothingToWithdraw();

        validatorRewardClaimed[_taskId][claimant] = true;

        (bool success, ) = payable(claimant).call{value: rewardAmount}("");
        require(success, "Reward claim failed");

        emit RewardsClaimed(_taskId, claimant, rewardAmount);
    }

    function claimRequesterRefund(uint256 _taskId) public nonReentrant requireAnyTaskStatus(_taskId, new TaskStatus[](2){ TaskStatus.Cancelled, TaskStatus.Failed }) {
        Task storage task = tasks[_taskId];
        address claimant = _msgSender();

        if (task.requester != claimant) revert NotPermitted();
        if (requesterRefundClaimed[_taskId][claimant]) revert NothingToWithdraw();

        // Calculate remaining balance in the task's "escrow" that wasn't paid out as rewards or fees.
        // For Cancelled, it's initial budget - platform fee.
        // For Failed, it's initial budget - platform fee - (any potential partial payouts? No, in this model rewards are only for Completed).
        // So for Failed, it's also initial budget - platform fee.
        uint256 refundAmount = task.budget - task.platformFee;

        // If any rewards *were* somehow claimed before reaching Failed/Cancelled (shouldn't happen in this logic, but safety)
        // the contract would need to track spent reward amounts per task.
        // With the current logic (rewards only for Completed), the math holds.

        requesterRefundClaimed[_taskId][claimant] = true;

        (bool success, ) = payable(claimant).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit RefundClaimed(_taskId, claimant, refundAmount);
    }


    // --- Viewing Functions ---
    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        if (tasks[_taskId].id == 0) revert TaskNotFound(); // Check if task exists
        return tasks[_taskId];
    }

    function getDataProviderStatus(address _provider) public view returns (ProviderInfo memory) {
        return dataProviders[_provider];
    }

    function getComputeProviderStatus(address _provider) public view returns (ProviderInfo memory) {
        return computeProviders[_provider];
    }

    function getValidatorStatus(address _validator) public view returns (ProviderInfo memory) {
        return validators[_validator];
    }

    // --- Internal Helper Functions ---
    // Helper to compare strings (necessary before 0.8.11 for storage/memory comparison)
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // Function to receive ETH
    receive() external payable {
        // Can potentially add logic here, e.g., for staking or specific deposits
        // For this contract, all ETH should come via specific functions (register, createTask)
        // So this receive function is primarily for safety, allowing ETH sent without data
    }

    // Fallback function (for calls with data but no matching function)
    fallback() external payable {
        revert(); // Reject calls with data that don't match a function
    }
}
```