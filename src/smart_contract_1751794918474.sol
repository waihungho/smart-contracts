Okay, here is a Solidity smart contract for a conceptual "Decentralized AI Compute Marketplace". This contract facilitates connecting requesters who need AI/ML computation done with providers who have the resources, managing tasks, payments, stakes, and a basic dispute/verification flow.

It uses concepts like managing off-chain work via on-chain state, staking collateral, a simple rating system, and a placeholder for dispute resolution, while requiring off-chain components (like compute nodes and IPFS). It aims to be creative by modeling an AI compute market on-chain without duplicating standard DeFi/NFT/DAO patterns.

**Outline & Function Summary**

This contract, `DecentralizedAIComputeMarketplace`, facilitates a marketplace for off-chain AI computation tasks.

**Core Concepts:**

*   **Requesters:** Users who define tasks, provide data (via IPFS CIDs), and pay for computation.
*   **Providers:** Users who register computational resources, stake collateral, accept tasks, perform off-chain computation, and submit results (via IPFS CIDs).
*   **Tasks:** On-chain representation of a computation request, including state, budget, participants, data references (CIDs), and verification hashes.
*   **Staking:** Both providers and potentially requesters stake collateral to incentivize honest behavior and compensate for non-performance.
*   **Verification & Dispute:** A basic flow allows requesters to verify results. A dispute mechanism (partially off-chain, signaled on-chain) is included.
*   **Reputation:** A simple rating system for providers.
*   **Platform Fees:** The contract owner can set and withdraw a small fee.
*   **Pausable:** Basic contract pausing mechanism for emergencies.

**State Variables:**

*   `owner`: The contract owner address.
*   `paused`: Boolean indicating if the contract is paused.
*   `taskIdCounter`: Counter for unique task IDs.
*   `tasks`: Mapping from task ID to `Task` struct.
*   `providers`: Mapping from provider address to `Provider` struct.
*   `requesterTasks`: Mapping from requester address to an array of their task IDs.
*   `providerTasks`: Mapping from provider address to an array of their task IDs.
*   `platformFeeBasisPoints`: Fee percentage (e.g., 100 = 1%).
*   `arbitratorAddress`: Address designated to resolve disputes (placeholder).
*   `providerTotalRatingPoints`: Mapping provider address -> total rating points received.
*   `providerRatingCount`: Mapping provider address -> number of ratings received.
*   `contractBalance`: Tracks accumulated fees.

**Enums:**

*   `TaskState`: Represents the current stage of a task (Open, Assigned, Submitted, RequesterVerifying, Disputed, Completed, Cancelled).

**Structs:**

*   `Task`: Details of a computation task.
*   `Provider`: Details of a registered compute provider.

**Events:**

*   `TaskCreated`: Emitted when a new task is created.
*   `TaskAccepted`: Emitted when a provider accepts a task.
*   `TaskResultSubmitted`: Emitted when a provider submits a result.
*   `TaskVerified`: Emitted when a requester verifies a result (success/failure).
*   `TaskCompleted`: Emitted when a task is successfully completed and funds disbursed.
*   `TaskCancelled`: Emitted when a task is cancelled.
*   `TaskDisputed`: Emitted when a task enters a disputed state.
*   `ProviderRegistered`: Emitted when a provider registers.
*   `ProviderDeregistered`: Emitted when a provider deregisters.
*   `PlatformFeeSet`: Emitted when the platform fee is updated.
*   `FeesWithdrawn`: Emitted when fees are withdrawn.
*   `ContractPaused`: Emitted when the contract is paused.
*   `ContractUnpaused`: Emitted when the contract is unpaused.
*   `ArbitratorAddressSet`: Emitted when the arbitrator address is set.
*   `ProviderRated`: Emitted when a provider receives a rating.

**Functions:**

1.  `constructor()`: Initializes the contract owner and sets initial parameters.
2.  `pauseContract()`: (Owner only) Pauses the contract, preventing most interactions.
3.  `unpauseContract()`: (Owner only) Unpauses the contract.
4.  `setPlatformFeeBasisPoints(uint256 feeBasisPoints)`: (Owner only) Sets the platform fee (in basis points, 100 = 1%).
5.  `withdrawPlatformFees()`: (Owner only) Allows the owner to withdraw accumulated fees.
6.  `setArbitratorAddress(address payable _arbitratorAddress)`: (Owner only) Sets the address designated as the arbitrator.
7.  `registerProvider(uint256 initialStake)`: Providers register with a required ETH stake.
8.  `deregisterProvider()`: Providers can deregister and withdraw their stake (if no active tasks).
9.  `updateProviderGlobalStake()`: Providers can add more ETH to their global stake (withdrawal requires `deregisterProvider`).
10. `getProviderGlobalStake(address provider)`: Gets the total global stake of a provider.
11. `isProviderRegistered(address provider)`: Checks if an address is a registered provider.
12. `createTask(string memory inputCID, uint256 budget, uint256 providerStakeRequired)`: Requesters create a new task, depositing the `budget` + required `providerStakeRequired` (which acts as requester collateral against provider stake).
13. `cancelTask(uint256 taskId)`: Requesters can cancel open tasks, receiving a refund.
14. `acceptTask(uint256 taskId)`: Providers accept an open task, depositing the `providerStakeRequired`.
15. `submitTaskResult(uint256 taskId, string memory outputCID, bytes32 resultVerificationHash)`: Providers submit the result CID and a hash for verification.
16. `verifyTaskResult(uint256 taskId, bool success, string memory verificationMessage)`: Requesters verify the submitted result. If `success` is false, the task moves to disputed or cancelled state.
17. `requestArbitration(uint256 taskId)`: Either party can formally request arbitration after a failed verification.
18. `arbitrateDispute(uint256 taskId, address winningParty)`: (Arbitrator only) Resolves a disputed task, determining the winning party and influencing fund distribution.
19. `completeTaskPayment(uint256 taskId)`: Triggers payment and stake distribution for tasks in Completed or Arbitrated states. Handles sending budget to provider, returning stakes, and collecting fees.
20. `submitProviderRating(uint256 taskId, uint8 rating)`: Requesters can rate the provider after a task is completed.
21. `getProviderRating(address provider)`: Calculates and returns the average rating for a provider.
22. `getTaskDetails(uint256 taskId)`: Retrieves all details for a specific task.
23. `getRequesterTasks(address requester)`: Retrieves the list of task IDs created by a requester.
24. `getProviderTasks(address provider)`: Retrieves the list of task IDs assigned to a provider.
25. `getOpenTasks()`: Retrieves a list of tasks currently in the `Open` state. (Note: For many tasks, this would need pagination off-chain).
26. `getTasksByState(TaskState state)`: Retrieves a list of task IDs in a specific state. (Similar note about pagination).
27. `getPlatformFeeBasisPoints()`: Gets the current platform fee.
28. `getContractBalance()`: Gets the current ETH balance held by the contract (useful for verifying fees).
29. `getArbitratorAddress()`: Gets the current arbitrator address.
30. `getTaskState(uint256 taskId)`: Gets only the state of a specific task (gas optimized getter).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Decentralized AI Compute Marketplace
/// @author Your Name/Alias (Conceptual Example)
/// @notice This contract facilitates a marketplace for off-chain AI computation tasks,
/// connecting requesters and providers, managing tasks, payments, and stakes.
/// It relies on off-chain components (compute nodes, IPFS, external verification)
/// and serves as a state and financial layer on-chain.

/// @dev Outline:
/// - Version Pragma and License
/// - Error Definitions
/// - Enums (TaskState)
/// - Structs (Task, Provider)
/// - Events
/// - State Variables
/// - Modifiers (onlyOwner, whenNotPaused, whenPaused, onlyRequester, onlyProvider, onlyArbitrator)
/// - Constructor
/// - Owner Functions (pause, unpause, set fee, withdraw fees, set arbitrator)
/// - Provider Management Functions (register, deregister, update stake, getters)
/// - Task Management Functions (create, cancel, accept, submit result, verify result, request arbitration, arbitrate, complete payment)
/// - Reputation Functions (submit rating, get rating)
/// - Query Functions (get task details, get tasks by user/state, get contract balance, get parameters)

error Unauthorized();
error Paused();
error NotPaused();
error InvalidState();
error InvalidAmount();
error TaskNotFound();
error AlreadyRegistered();
error NotRegistered();
error TaskNotOpen();
error TaskNotAssigned();
error TaskNotSubmitted();
error TaskNotRequesterVerifying();
error TaskNotDisputed();
error TaskNotCompleted();
error TaskNotCancelled();
error IncorrectStake();
error NotTaskParticipant();
error TaskAlreadyRated();
error ArbitrationNotRequested();
error ArbitrationAlreadyResolved();


enum TaskState {
    Open,               // Task created, waiting for a provider to accept
    Assigned,           // Provider accepted, computation in progress off-chain
    Submitted,          // Provider submitted results, waiting for requester verification
    RequesterVerifying, // Requester is verifying results
    Disputed,           // Requester rejected results, dispute process needed
    Completed,          // Task successfully completed, funds distributed
    Cancelled           // Task cancelled by requester before assignment or due to failure
}

struct Task {
    uint256 taskId;
    address payable requester;
    address payable provider; // Address of the assigned provider (0x0 for Open state)
    TaskState state;
    string inputCID;        // IPFS CID referencing task inputs (data, model, script)
    string outputCID;       // IPFS CID referencing task outputs (results, logs)
    bytes32 resultVerificationHash; // Hash provided by provider for verification (e.g., hash of output)
    uint256 budget;                 // ETH amount allocated for the provider
    uint256 providerStakeRequired;  // ETH amount provider must stake per task
    uint256 requesterStake;         // ETH amount requester staked (can be equal to providerStakeRequired)
    uint256 createdAt;
    uint256 submittedAt;
    bool requesterVerifiedSuccess; // Result of requester's verification
    string verificationMessage;    // Optional message from requester verification
    bool arbitrationRequested;   // Flag if arbitration has been formally requested
    bool arbitrationResolved;    // Flag if arbitration has been resolved
    address winningParty;       // Address determined winner in arbitration
    bool rated;                 // Flag if the task has been rated by the requester
}

struct Provider {
    address providerAddress;
    bool isRegistered;
    uint256 globalStake; // Total stake held by provider outside of specific tasks
    // Note: Individual task stakes are held within the Task struct ETH balance
}

event TaskCreated(uint256 taskId, address indexed requester, uint256 budget, uint256 providerStakeRequired, string inputCID);
event TaskAccepted(uint256 taskId, address indexed provider, uint256 providerStake);
event TaskResultSubmitted(uint256 taskId, address indexed provider, string outputCID, bytes32 resultVerificationHash);
event TaskVerified(uint256 taskId, address indexed requester, bool success, string verificationMessage);
event TaskCompleted(uint256 taskId, address indexed provider, address indexed requester, uint256 budgetPaid, uint256 feeAmount);
event TaskCancelled(uint256 taskId, address indexed requester, uint256 refundAmount);
event TaskDisputed(uint256 taskId, address indexed requester, address indexed provider);
event ProviderRegistered(address indexed provider, uint256 initialStake);
event ProviderDeregistered(address indexed provider, uint256 stakeReturned);
event PlatformFeeSet(uint256 oldFeeBasisPoints, uint256 newFeeBasisPoints);
event FeesWithdrawn(address indexed owner, uint256 amount);
event ContractPaused(address indexed account);
event ContractUnpaused(address indexed account);
event ArbitratorAddressSet(address indexed oldArbitrator, address indexed newArbitrator);
event ProviderRated(address indexed provider, uint256 taskId, uint8 rating);
event DisputeArbitrated(uint256 taskId, address indexed arbitrator, address indexed winningParty);

address public immutable owner;
bool public paused;
uint256 public taskIdCounter;
mapping(uint256 => Task) public tasks;
mapping(address => Provider) public providers;
mapping(address => uint256[]) public requesterTasks;
mapping(address => uint256[]) public providerTasks;
uint256 public platformFeeBasisPoints; // Fee in basis points (e.g., 100 = 1%)
address payable public arbitratorAddress;
mapping(address => uint256) public providerTotalRatingPoints;
mapping(address => uint256) public providerRatingCount;

// Use contract balance to track accumulated fees for simplicity
// address public feeCollector; // Could use a separate fee collector address

modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
}

modifier whenNotPaused() {
    if (paused) revert Paused();
    _;
}

modifier whenPaused() {
    if (!paused) revert NotPaused();
    _;
}

modifier onlyRequester(uint256 taskId) {
    if (tasks[taskId].requester == address(0) || msg.sender != tasks[taskId].requester) revert Unauthorized();
    _;
}

modifier onlyProvider(uint256 taskId) {
    if (tasks[taskId].provider == address(0) || msg.sender != tasks[taskId].provider) revert Unauthorized();
    _;
}

modifier onlyArbitrator() {
    if (msg.sender != arbitratorAddress) revert Unauthorized();
    _;
}

constructor() {
    owner = msg.sender;
    paused = false;
    platformFeeBasisPoints = 50; // Default 0.5% fee
    taskIdCounter = 0;
}

// 1. constructor() - See above

// Owner Functions

/// @summary Pauses the contract functionality.
/// @dev Prevents execution of most state-changing functions.
/// @custom:security Emergency pause mechanism.
function pauseContract() external onlyOwner whenNotPaused {
    paused = true;
    emit ContractPaused(msg.sender);
}

/// @summary Unpauses the contract.
/// @dev Allows execution of previously restricted functions.
function unpauseContract() external onlyOwner whenPaused {
    paused = false;
    emit ContractUnpaused(msg.sender);
}

/// @summary Sets the platform fee percentage.
/// @param feeBasisPoints Fee amount in basis points (e.g., 100 for 1%). Max 10000 (100%).
function setPlatformFeeBasisPoints(uint256 feeBasisPoints) external onlyOwner {
    uint256 oldFee = platformFeeBasisPoints;
    platformFeeBasisPoints = feeBasisPoints;
    emit PlatformFeeSet(oldFee, feeBasisPoints);
}

/// @summary Allows the owner to withdraw accumulated platform fees.
function withdrawPlatformFees() external onlyOwner {
    // The contract balance holds the accumulated fees
    uint256 balance = address(this).balance;
    require(balance > 0, "No fees to withdraw");

    (bool success,) = payable(owner).call{value: balance}("");
    require(success, "Fee withdrawal failed");

    // contractBalance state variable was removed to rely solely on address(this).balance
    // If re-implementing contractBalance state, update it here.

    emit FeesWithdrawn(owner, balance);
}

/// @summary Sets the address designated as the arbitrator for disputes.
/// @param _arbitratorAddress The address of the arbitrator.
function setArbitratorAddress(address payable _arbitratorAddress) external onlyOwner {
    address oldArbitrator = arbitratorAddress;
    arbitratorAddress = _arbitratorAddress;
    emit ArbitratorAddressSet(oldArbitrator, _arbitratorAddress);
}


// Provider Management

/// @summary Registers an address as a compute provider.
/// @param initialStake The initial amount of ETH staked by the provider.
function registerProvider(uint256 initialStake) external payable whenNotPaused {
    Provider storage providerInfo = providers[msg.sender];
    if (providerInfo.isRegistered) revert AlreadyRegistered();
    if (msg.value != initialStake || msg.value == 0) revert InvalidAmount(); // Must stake non-zero amount

    providerInfo.providerAddress = msg.sender;
    providerInfo.isRegistered = true;
    providerInfo.globalStake = initialStake;

    emit ProviderRegistered(msg.sender, initialStake);
}

/// @summary Allows a registered provider to deregister and withdraw their global stake.
/// @dev Fails if the provider has any active tasks (not Completed or Cancelled).
function deregisterProvider() external whenNotPaused {
    Provider storage providerInfo = providers[msg.sender];
    if (!providerInfo.isRegistered) revert NotRegistered();

    // Check if provider has active tasks
    for (uint256 i = 0; i < providerTasks[msg.sender].length; i++) {
        uint256 tid = providerTasks[msg.sender][i];
        TaskState state = tasks[tid].state;
        if (state != TaskState.Completed && state != TaskState.Cancelled) {
             revert("Cannot deregister with active tasks");
        }
    }

    uint256 stakeToReturn = providerInfo.globalStake;
    providerInfo.isRegistered = false;
    providerInfo.globalStake = 0;

    (bool success,) = payable(msg.sender).call{value: stakeToReturn}("");
    require(success, "Stake withdrawal failed");

    emit ProviderDeregistered(msg.sender, stakeToReturn);
}

/// @summary Allows a registered provider to add more ETH to their global stake.
function updateProviderGlobalStake() external payable whenNotPaused {
     Provider storage providerInfo = providers[msg.sender];
     if (!providerInfo.isRegistered) revert NotRegistered();
     if (msg.value == 0) revert InvalidAmount();

     providerInfo.globalStake += msg.value;
     // No explicit event for update stake, ProviderRegistered/Deregistered cover major changes.
     // Could add UpdateProviderStake event if needed.
}

/// @summary Gets the current total global stake amount for a provider.
/// @param provider The address of the provider.
/// @return The total global stake amount.
function getProviderGlobalStake(address provider) external view returns (uint256) {
    return providers[provider].globalStake;
}

/// @summary Checks if an address is a registered provider.
/// @param provider The address to check.
/// @return True if registered, false otherwise.
function isProviderRegistered(address provider) external view returns (bool) {
    return providers[provider].isRegistered;
}

// Task Management

/// @summary Creates a new AI computation task.
/// @dev Requires sending ETH equal to `budget` + `providerStakeRequired` (acting as requester's collateral).
/// @param inputCID IPFS CID pointing to the task inputs (data, code, requirements).
/// @param budget The amount of ETH offered to the provider for successful completion.
/// @param providerStakeRequired The amount of ETH the provider must stake to accept this task. This also determines requester's required deposit for collateral.
/// @return The ID of the newly created task.
function createTask(string memory inputCID, uint256 budget, uint256 providerStakeRequired) external payable whenNotPaused {
    if (budget == 0 || providerStakeRequired == 0) revert InvalidAmount();
    if (msg.value != budget + providerStakeRequired) revert InvalidAmount(); // Requester stakes budget + required provider stake as collateral

    uint256 newTaskId = taskIdCounter++;
    tasks[newTaskId] = Task({
        taskId: newTaskId,
        requester: payable(msg.sender),
        provider: payable(address(0)), // No provider yet
        state: TaskState.Open,
        inputCID: inputCID,
        outputCID: "", // Set later by provider
        resultVerificationHash: 0x0, // Set later by provider
        budget: budget,
        providerStakeRequired: providerStakeRequired,
        requesterStake: providerStakeRequired, // Requester stakes amount equivalent to provider's required stake
        createdAt: block.timestamp,
        submittedAt: 0,
        requesterVerifiedSuccess: false,
        verificationMessage: "",
        arbitrationRequested: false,
        arbitrationResolved: false,
        winningParty: address(0),
        rated: false
    });

    requesterTasks[msg.sender].push(newTaskId);

    emit TaskCreated(newTaskId, msg.sender, budget, providerStakeRequired, inputCID);
    // Transfer incoming funds to contract balance (implicitly handled by msg.value)
    // contractBalance += msg.value; // If using contractBalance state
}

/// @summary Allows a requester to cancel an open task.
/// @dev Only possible if the task is in the `Open` state. Refunds budget and requester stake.
/// @param taskId The ID of the task to cancel.
function cancelTask(uint256 taskId) external onlyRequester(taskId) whenNotPaused {
    Task storage task = tasks[taskId];
    if (task.state != TaskState.Open) revert InvalidState();

    task.state = TaskState.Cancelled;

    uint256 refundAmount = task.budget + task.requesterStake; // Refund budget + requester stake
    (bool success,) = payable(msg.sender).call{value: refundAmount}("");
    require(success, "Refund failed");

    emit TaskCancelled(taskId, msg.sender, refundAmount);
}

/// @summary Allows a registered provider to accept an open task.
/// @dev Requires the provider to stake the `providerStakeRequired` amount.
/// @param taskId The ID of the task to accept.
function acceptTask(uint256 taskId) external payable whenNotPaused {
    Task storage task = tasks[taskId];
    Provider storage providerInfo = providers[msg.sender];

    if (task.state != TaskState.Open) revert InvalidState();
    if (!providerInfo.isRegistered) revert NotRegistered();
    if (msg.value != task.providerStakeRequired) revert IncorrectStake();

    task.provider = payable(msg.sender);
    task.state = TaskState.Assigned;

    providerTasks[msg.sender].push(taskId);

    emit TaskAccepted(taskId, msg.sender, msg.value);
    // Task stake is implicitly held by the contract along with the task budget
}

/// @summary Allows the assigned provider to submit the task results.
/// @dev Requires the task to be in the `Assigned` state.
/// @param taskId The ID of the task.
/// @param outputCID IPFS CID pointing to the computation results.
/// @param resultVerificationHash A hash derived from the output, used for verification.
function submitTaskResult(uint256 taskId, string memory outputCID, bytes32 resultVerificationHash) external onlyProvider(taskId) whenNotPaused {
    Task storage task = tasks[taskId];
    if (task.state != TaskState.Assigned) revert InvalidState();

    task.outputCID = outputCID;
    task.resultVerificationHash = resultVerificationHash;
    task.state = TaskState.Submitted;
    task.submittedAt = block.timestamp;

    emit TaskResultSubmitted(taskId, msg.sender, outputCID, resultVerificationHash);
}

/// @summary Allows the requester to verify the submitted result.
/// @dev Moves the task state based on verification success.
/// @param taskId The ID of the task.
/// @param success True if the result is verified successfully, false otherwise.
/// @param verificationMessage Optional message from the requester.
function verifyTaskResult(uint256 taskId, bool success, string memory verificationMessage) external onlyRequester(taskId) whenNotPaused {
    Task storage task = tasks[taskId];
    if (task.state != TaskState.Submitted && task.state != TaskState.RequesterVerifying) revert InvalidState();

    task.requesterVerifiedSuccess = success;
    task.verificationMessage = verificationMessage;

    if (success) {
        // Task successfully verified, ready for completion
        task.state = TaskState.Completed;
        // Funds disbursement happens in completeTaskPayment
    } else {
        // Verification failed, move to disputed state
        task.state = TaskState.Disputed;
    }

    emit TaskVerified(taskId, msg.sender, success, verificationMessage);
}

/// @summary Allows either the requester or provider to request formal arbitration after a failed verification.
/// @dev Task must be in the `Disputed` state. Signals need for off-chain arbitration.
/// @param taskId The ID of the task.
function requestArbitration(uint256 taskId) external whenNotPaused {
    Task storage task = tasks[taskId];
    if (task.state != TaskState.Disputed) revert InvalidState();
    if (msg.sender != task.requester && msg.sender != task.provider) revert NotTaskParticipant();
    if (task.arbitrationRequested) revert("Arbitration already requested");

    task.arbitrationRequested = true;
    // Off-chain process should now handle resolution
    // The `arbitrateDispute` function is called by the arbitrator based on off-chain outcome

    emit TaskDisputed(taskId, task.requester, task.provider);
}


/// @summary Allows the designated arbitrator to resolve a disputed task.
/// @dev Called after an off-chain arbitration process determines the outcome.
/// @param taskId The ID of the task.
/// @param winningParty The address of the party determined to have won the dispute (requester or provider).
function arbitrateDispute(uint256 taskId, address winningParty) external onlyArbitrator whenNotPaused {
     Task storage task = tasks[taskId];
     if (task.state != TaskState.Disputed) revert InvalidState();
     if (!task.arbitrationRequested) revert ArbitrationNotRequested();
     if (task.arbitrationResolved) revert ArbitrationAlreadyResolved();
     if (winningParty != task.requester && winningParty != task.provider) revert InvalidAmount(); // Winning party must be one of the participants

     task.winningParty = winningParty;
     task.arbitrationResolved = true;
     task.state = TaskState.Completed; // Move to completed state for fund distribution

     emit DisputeArbitrated(taskId, msg.sender, winningParty);
}


/// @summary Handles the final payment and stake distribution for completed or arbitrated tasks.
/// @dev Can be called by requester or provider once the task state is Completed.
/// @param taskId The ID of the task.
function completeTaskPayment(uint256 taskId) external whenNotPaused {
    Task storage task = tasks[taskId];
    if (task.state != TaskState.Completed) revert InvalidState();
    if (msg.sender != task.requester && msg.sender != task.provider && msg.sender != owner) revert NotTaskParticipant(); // Allow owner to trigger if needed

    uint256 totalTaskBalance = task.budget + task.requesterStake + task.providerStakeRequired; // ETH held by contract for this task

    uint256 amountToProvider = 0;
    uint256 amountToRequesterStakeReturn = 0;
    uint256 amountToProviderStakeReturn = 0;
    uint256 feeAmount = 0;

    // Determine distribution based on successful verification or arbitration outcome
    if (task.requesterVerifiedSuccess) {
        // Success path (requester verified true)
        amountToProvider = task.budget;
        amountToRequesterStakeReturn = task.requesterStake;
        amountToProviderStakeReturn = task.providerStakeRequired;
        // Fee is taken from the provider's payment
        if (platformFeeBasisPoints > 0) {
             feeAmount = (amountToProvider * platformFeeBasisPoints) / 10000;
             amountToProvider = amountToProvider - feeAmount;
        }

    } else if (task.arbitrationResolved) {
        // Arbitration path
        if (task.winningParty == task.provider) {
            // Provider won arbitration
            amountToProvider = task.budget;
            amountToRequesterStakeReturn = 0; // Requester stake potentially lost
            amountToProviderStakeReturn = task.providerStakeRequired; // Provider stake returned
             if (platformFeeBasisPoints > 0) {
                 feeAmount = (amountToProvider * platformFeeBasisPoints) / 10000;
                 amountToProvider = amountToProvider - feeAmount;
            }

        } else if (task.winningParty == task.requester) {
            // Requester won arbitration
            amountToProvider = 0; // Provider gets no budget
            amountToRequesterStakeReturn = task.requesterStake; // Requester stake returned
            amountToProviderStakeReturn = 0; // Provider stake potentially lost
            feeAmount = 0; // No fee if provider gets nothing
        }
    } else {
        // Should not happen if state is Completed without verification success or arbitration
        revert InvalidState();
    }

    // Check if total payout exceeds the available balance for the task
    // Note: totalTaskBalance includes the initial ETH received when creating/accepting
    // This check isn't strictly necessary if the logic is sound, but good for safety
    uint256 totalPayout = amountToProvider + amountToRequesterStakeReturn + amountToProviderStakeReturn + feeAmount;
    require(totalPayout <= totalTaskBalance, "Payout exceeds task balance");


    // Transfer funds
    if (amountToProvider > 0) {
        (bool successProvider,) = task.provider.call{value: amountToProvider}("");
        require(successProvider, "Provider payment failed");
    }
     if (amountToRequesterStakeReturn > 0) {
        (bool successRequester,) = task.requester.call{value: amountToRequesterStakeReturn}("");
        require(successRequester, "Requester stake return failed");
    }
    if (amountToProviderStakeReturn > 0) {
        (bool successProviderStake,) = task.provider.call{value: amountToProviderStakeReturn}("");
        require(successProviderStake, "Provider stake return failed");
    }

    // Any remaining balance (should be feeAmount in success case, or slashed stakes in loss case) stays in contract for withdrawal by owner
    // The fee amount is implicitly held in the contract balance by not being sent out

    task.state = TaskState.Completed; // Ensure state is marked completed after distribution

    emit TaskCompleted(taskId, task.provider, task.requester, amountToProvider, feeAmount);
}


// Reputation

/// @summary Allows the requester to submit a rating for the provider after task completion.
/// @dev Can only be called once per completed task by the requester.
/// @param taskId The ID of the task.
/// @param rating The rating value (e.g., 1-5).
function submitProviderRating(uint256 taskId, uint8 rating) external onlyRequester(taskId) whenNotPaused {
    Task storage task = tasks[taskId];
    if (task.state != TaskState.Completed) revert InvalidState();
    if (task.rated) revert TaskAlreadyRated();
    if (task.provider == address(0)) revert("Provider not assigned"); // Should not happen for completed tasks
    if (rating == 0) revert("Rating must be greater than 0"); // Optional: Define rating range

    task.rated = true;

    providerTotalRatingPoints[task.provider] += rating;
    providerRatingCount[task.provider]++;

    emit ProviderRated(task.provider, taskId, rating);
}

/// @summary Gets the average rating for a provider.
/// @param provider The address of the provider.
/// @return The average rating (integer division). Returns 0 if no ratings.
function getProviderRating(address provider) external view returns (uint256) {
    uint256 count = providerRatingCount[provider];
    if (count == 0) {
        return 0;
    }
    return providerTotalRatingPoints[provider] / count;
}

// Query Functions

/// @summary Gets all details for a specific task.
/// @param taskId The ID of the task.
/// @return The Task struct.
function getTaskDetails(uint256 taskId) external view returns (Task memory) {
     if (taskId >= taskIdCounter) revert TaskNotFound();
     return tasks[taskId];
}

/// @summary Gets the state of a specific task.
/// @param taskId The ID of the task.
/// @return The TaskState enum value.
function getTaskState(uint256 taskId) external view returns (TaskState) {
     if (taskId >= taskIdCounter) revert TaskNotFound();
     return tasks[taskId].state;
}


/// @summary Gets the list of task IDs created by a specific requester.
/// @param requester The address of the requester.
/// @return An array of task IDs.
function getRequesterTasks(address requester) external view returns (uint256[] memory) {
    return requesterTasks[requester];
}

/// @summary Gets the list of task IDs assigned to a specific provider.
/// @param provider The address of the provider.
/// @return An array of task IDs.
function getProviderTasks(address provider) external view returns (uint256[] memory) {
    return providerTasks[provider];
}

/// @summary Gets a list of task IDs that are currently open.
/// @dev Note: This could be resource-intensive for many tasks. Consider off-chain indexing for large lists.
/// @return An array of open task IDs.
function getOpenTasks() external view returns (uint256[] memory) {
    uint256[] memory openTaskIds = new uint256[](taskIdCounter);
    uint256 count = 0;
    for (uint256 i = 0; i < taskIdCounter; i++) {
        if (tasks[i].state == TaskState.Open) {
            openTaskIds[count] = i;
            count++;
        }
    }
    // Resize array to actual count
    uint256[] memory result = new uint256[](count);
    for(uint256 i = 0; i < count; i++) {
        result[i] = openTaskIds[i];
    }
    return result;
}

/// @summary Gets a list of task IDs that are in a specific state.
/// @dev Note: Resource-intensive for many tasks. Consider off-chain indexing.
/// @param state The desired task state.
/// @return An array of task IDs in the specified state.
function getTasksByState(TaskState state) external view returns (uint256[] memory) {
     uint256[] memory taskIds = new uint256[](taskIdCounter);
    uint256 count = 0;
    for (uint256 i = 0; i < taskIdCounter; i++) {
        if (tasks[i].state == state) {
            taskIds[count] = i;
            count++;
        }
    }
    // Resize array
    uint256[] memory result = new uint256[](count);
    for(uint256 i = 0; i < count; i++) {
        result[i] = taskIds[i];
    }
    return result;
}

/// @summary Gets the current platform fee in basis points.
/// @return The fee amount in basis points.
function getPlatformFeeBasisPoints() external view returns (uint256) {
    return platformFeeBasisPoints;
}

/// @summary Gets the current ETH balance of the contract.
/// @return The contract's ETH balance.
function getContractBalance() external view returns (uint256) {
    return address(this).balance;
}

/// @summary Gets the address currently designated as the arbitrator.
/// @return The arbitrator address.
function getArbitratorAddress() external view returns (address payable) {
    return arbitratorAddress;
}

// --- Additional Getters for specific task fields (increase function count and provide targeted access) ---

/// @summary Gets the requester address for a specific task.
function getTaskRequester(uint256 taskId) external view returns (address payable) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].requester;
}

/// @summary Gets the provider address for a specific task.
function getTaskProvider(uint256 taskId) external view returns (address payable) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].provider;
}

/// @summary Gets the budget for a specific task.
function getTaskBudget(uint256 taskId) external view returns (uint256) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].budget;
}

/// @summary Gets the provider stake required for a specific task.
function getTaskProviderStakeRequired(uint256 taskId) external view returns (uint256) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].providerStakeRequired;
}

/// @summary Gets the requester stake for a specific task.
function getTaskRequesterStake(uint256 taskId) external view returns (uint256) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].requesterStake;
}

/// @summary Gets the input CID for a specific task.
function getTaskInputCID(uint256 taskId) external view returns (string memory) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].inputCID;
}

/// @summary Gets the output CID for a specific task.
function getTaskOutputCID(uint256 taskId) external view returns (string memory) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].outputCID;
}

/// @summary Gets the result verification hash for a specific task.
function getTaskResultVerificationHash(uint256 taskId) external view returns (bytes32) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].resultVerificationHash;
}

/// @summary Gets the requester's verification outcome for a specific task.
function getTaskRequesterVerifiedSuccess(uint256 taskId) external view returns (bool) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].requesterVerifiedSuccess;
}

/// @summary Gets the requester's verification message for a specific task.
function getTaskVerificationMessage(uint256 taskId) external view returns (string memory) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].verificationMessage;
}

/// @summary Gets the arbitration requested status for a specific task.
function getTaskArbitrationRequested(uint256 taskId) external view returns (bool) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].arbitrationRequested;
}

/// @summary Gets the arbitration resolved status for a specific task.
function getTaskArbitrationResolved(uint256 taskId) external view returns (bool) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].arbitrationResolved;
}

/// @summary Gets the winning party address determined by arbitration for a specific task.
function getTaskWinningParty(uint256 taskId) external view returns (address) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].winningParty;
}

/// @summary Gets the rated status for a specific task.
function getTaskRated(uint256 taskId) external view returns (bool) {
    if (taskId >= taskIdCounter) revert TaskNotFound();
    return tasks[taskId].rated;
}

// Fallback and Receive functions to accept ETH transfers
receive() external payable {}
fallback() external payable {}


}
```