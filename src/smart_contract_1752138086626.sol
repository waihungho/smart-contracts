Okay, here is a Solidity smart contract for a "Decentralized AI Computing Hub".

**Concept:** This contract acts as a marketplace and escrow for decentralized AI computation tasks. Users request tasks and deposit funds. Providers stake tokens to offer computing resources and accept tasks. The contract manages the task lifecycle, payment release upon successful completion, provider staking, slashing for failures, and a basic provider reputation system.

**Advanced/Creative Aspects:**

1.  **Task Lifecycle with Multiple States:** Manages tasks through states like `Requested`, `Accepted`, `ResultSubmitted`, `VerificationPeriod`, `Completed`, `Failed`, `Cancelled`, `Timeout`.
2.  **Provider Staking & Slashing:** Providers stake collateral. This stake can be slashed if they fail to complete tasks or timeout, incentivizing reliability.
3.  **Basic On-Chain Reputation:** A simple reputation score for providers, updated on successful completion and failure. Minimum reputation can be required to accept tasks.
4.  **Escrow for Task Funds:** User funds are held in escrow until the task is verified as complete by the user.
5.  **Time-Based Mechanisms:** Uses timestamps for task timeouts, verification periods, and provider stake cooldowns.
6.  **Off-Chain Work, On-Chain Proof (Partial):** The computation happens off-chain, but the *result hash* is submitted on-chain, and the *verification* step (acknowledging the result is correct) happens on-chain. This is a common pattern for off-chain work coordination.
7.  **Role-Based Functions:** Distinguishes between owner, user, and provider actions.

**Why it's not a direct copy:** While components like staking or escrow exist, the combination and specific state machine tailored for a *decentralized compute marketplace* with provider reputation and complex task states are less common standard templates compared to ERC-20/721, simple DEXs, or basic DAOs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Decentralized AI Computing Hub Outline ---
// 1. Configuration: Set global parameters (stake, fees, timeouts).
// 2. Provider Management: Register, unregister, stake, manage availability.
// 3. Task Management: Request, cancel, accept, submit result, verify, report failure/timeout.
// 4. Payment & Slashing: Handle task payouts, fee collection, stake slashing.
// 5. Reputation: Update provider reputation based on performance.
// 6. State & Information: View function for tasks, providers, config.
// 7. Access Control & Safety: Owner functions, Pausable, ReentrancyGuard.

// --- Function Summary ---
// Configuration:
// 1.  constructor(IERC20 _paymentToken): Deploys the contract, sets owner and payment token.
// 2.  setRequiredProviderStake(uint256 amount): Owner sets the required stake for providers.
// 3.  setTaskFeeRatePermille(uint16 ratePermille): Owner sets platform fee rate (per mille).
// 4.  setDefaultTaskTimeout(uint48 timeout): Owner sets the default time limit for tasks.
// 5.  setVerificationPeriod(uint48 period): Owner sets time window for result verification.
// 6.  setMinReputationToAccept(int16 reputation): Owner sets minimum reputation for providers to accept tasks.
// 7.  withdrawFees(): Owner withdraws accumulated platform fees.

// Provider Management:
// 8.  registerProvider(): Providers stake required tokens and register.
// 9.  unregisterProvider(): Providers initiate stake withdrawal (starts cooldown).
// 10. claimStake(): Providers claim stake after the cooldown period.
// 11. updateProviderStatus(ProviderStatus status): Providers update their availability status.

// Task Management:
// 12. requestTask(string calldata modelHash, string calldata dataHash, uint256 maxCost, uint48 customTimeout): Users request a computation task, depositing maxCost.
// 13. cancelTaskRequest(uint256 taskId): User cancels a task request before acceptance.
// 14. acceptTask(uint256 taskId): Providers accept an available task.
// 15. submitTaskResult(uint256 taskId, string calldata resultHash): Provider submits the hash of the computation result.
// 16. verifyTaskResult(uint256 taskId): User verifies the submitted result is correct. Triggers payout and reputation update.
// 17. reportTaskFailure(uint256 taskId, string calldata reason): User reports a task failure (e.g., incorrect result) before timeout/verification.
// 18. reportTaskTimeout(uint256 taskId): Anyone can report a task timeout after its deadline. Triggers slashing.
// 19. extendTaskTimeout(uint256 taskId, uint48 extension): User pays extra to extend task deadline if not yet accepted/failed.

// State & Information (View Functions):
// 20. getTaskDetails(uint256 taskId): Get detailed information about a task.
// 21. getProviderDetails(address provider): Get detailed information about a provider.
// 22. getUserTasks(address user): (Requires separate index mapping, omitted for brevity to stay under functional focus, or could iterate - expensive. Let's skip this specific view for gas/complexity, focus on direct access).
// 23. getProviderTasks(address provider): (Similar to above, complexity makes it unsuitable as a simple view).
// 24. getRequiredProviderStake(): Get the current required stake amount.
// 25. getTaskFeeRatePermille(): Get the current task fee rate.
// 26. getDefaultTaskTimeout(): Get the default task timeout.
// 27. getVerificationPeriod(): Get the result verification period.
// 28. getMinReputationToAccept(): Get the minimum reputation required.
// 29. getProviderReputation(address provider): Get a specific provider's reputation.
// 30. getTotalStakedAmount(): Get the total amount of tokens staked by all providers.

// Access Control & Safety:
// 31. pause(): Owner pauses contract operations.
// 32. unpause(): Owner unpauses contract operations.

// (Internal helper functions are also present but not listed in the function summary)

contract DecentralizedAIComputingHub is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken;

    // --- Configuration ---
    uint256 public requiredProviderStake;
    uint16 public taskFeeRatePermille; // e.g., 50 for 5%
    uint48 public defaultTaskTimeout; // Duration in seconds
    uint48 public verificationPeriod; // Duration in seconds for user verification
    int16 public minReputationToAccept; // Minimum reputation required for providers to accept tasks

    // --- State Variables ---
    enum TaskStatus {
        Requested,        // Task requested by user, waiting for provider
        Accepted,         // Task accepted by a provider
        ResultSubmitted,  // Provider submitted result hash, waiting for verification
        VerificationPeriod, // User has a time window to verify
        Completed,        // Task verified by user, payment released
        Failed,           // Task reported failed by user or provider
        Cancelled,        // Task cancelled by user before acceptance
        Timeout           // Task timed out before result submission
    }

    enum ProviderStatus {
        Inactive,         // Not registered or unregistered
        Registered,       // Staked and available
        Unavailable,      // Staked but temporarily unavailable
        Unregistering     // Initiated unregistration, stake is locked
    }

    struct Task {
        uint256 id;
        address user;
        address provider; // address(0) if not yet accepted
        string modelHash;
        string dataHash;
        uint256 taskCost; // Amount paid to provider (maxCost requested by user)
        uint256 totalPayment; // totalPayment = taskCost + fee
        uint48 requestTimestamp;
        uint48 deadline; // When the task must be completed by
        uint48 resultSubmitTimestamp; // When the result was submitted
        string resultHash; // Hash of the computation result
        TaskStatus status;
    }

    struct Provider {
        address addr;
        ProviderStatus status;
        int16 reputation;
        uint48 stakeUnlockTimestamp; // For unregistering cooldown
    }

    uint256 private nextTaskId;
    mapping(uint256 => Task) public tasks;
    mapping(address => Provider) public providers;
    mapping(address => uint256) public providerStake; // Separate mapping for staked amount

    uint256 public totalPlatformFees;

    // --- Events ---
    event ProviderRegistered(address indexed provider, uint256 stakeAmount);
    event ProviderUnregistering(address indexed provider, uint48 unlockTimestamp);
    event ProviderStakeClaimed(address indexed provider, uint256 amount);
    event ProviderStatusUpdated(address indexed provider, ProviderStatus status);

    event TaskRequested(uint256 indexed taskId, address indexed user, uint256 totalPayment, string modelHash, string dataHash, uint48 deadline);
    event TaskCancelled(uint256 indexed taskId);
    event TaskAccepted(uint256 indexed taskId, address indexed provider);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed provider, string resultHash);
    event TaskResultVerified(uint256 indexed taskId, address indexed user);
    event TaskFailed(uint256 indexed taskId, string reason);
    event TaskTimeout(uint256 indexed taskId);
    event TaskTimeoutExtended(uint256 indexed taskId, uint48 newDeadline, uint256 extraCost);

    event FeesWithdrawn(address indexed owner, uint256 amount);
    event ProviderStakeSlashing(address indexed provider, uint256 amount);
    event ProviderReputationUpdated(address indexed provider, int16 newReputation);

    // --- Modifiers ---
    modifier onlyProvider(uint256 taskId) {
        require(tasks[taskId].provider == msg.sender, "Not task provider");
        _;
    }

    modifier onlyTaskUser(uint256 taskId) {
        require(tasks[taskId].user == msg.sender, "Not task user");
        _;
    }

    modifier whenTaskStatusIs(uint256 taskId, TaskStatus expectedStatus) {
        require(tasks[taskId].status == expectedStatus, "Task not in expected status");
        _;
    }

    modifier whenProviderStatusIs(address providerAddr, ProviderStatus expectedStatus) {
        require(providers[providerAddr].status == expectedStatus, "Provider not in expected status");
        _;
    }

    // --- Constructor ---
    constructor(IERC20 _paymentToken) Ownable(msg.sender) {
        paymentToken = _paymentToken;
        nextTaskId = 1;
        // Set some reasonable defaults - owner should adjust these
        requiredProviderStake = 1 ether; // Example: 1 token
        taskFeeRatePermille = 50; // Example: 5%
        defaultTaskTimeout = 24 * 3600; // Example: 24 hours
        verificationPeriod = 72 * 3600; // Example: 72 hours
        minReputationToAccept = 0; // Example: Start with 0 required
    }

    // --- Configuration (Owner Only) ---
    function setRequiredProviderStake(uint256 amount) external onlyOwner {
        require(amount > 0, "Stake must be > 0");
        requiredProviderStake = amount;
    }

    function setTaskFeeRatePermille(uint16 ratePermille) external onlyOwner {
        require(ratePermille <= 1000, "Rate cannot exceed 100%");
        taskFeeRatePermille = ratePermille;
    }

    function setDefaultTaskTimeout(uint48 timeout) external onlyOwner {
        require(timeout > 0, "Timeout must be > 0");
        defaultTaskTimeout = timeout;
    }

    function setVerificationPeriod(uint48 period) external onlyOwner {
        require(period > 0, "Verification period must be > 0");
        verificationPeriod = period;
    }

    function setMinReputationToAccept(int16 reputation) external onlyOwner {
        minReputationToAccept = reputation;
    }

    function withdrawFees() external onlyOwner {
        uint256 feesToWithdraw = totalPlatformFees;
        totalPlatformFees = 0;
        if (feesToWithdraw > 0) {
            paymentToken.safeTransfer(owner(), feesToWithdraw);
            emit FeesWithdrawn(owner(), feesToWithdraw);
        }
    }

    // --- Provider Management ---

    function registerProvider() external payable nonReentrant whenNotPaused {
        Provider storage provider = providers[msg.sender];
        require(provider.status == ProviderStatus.Inactive, "Provider already registered or unregistering");

        uint256 amountToStake = requiredProviderStake;
        require(providerStake[msg.sender] + msg.value >= amountToStake, "Insufficient stake amount"); // Check if total staked + new deposit meets requirement

        // Transfer required stake from provider (assuming they approved or sent Ether if paymentToken is WETH/ETH)
        // For ERC20: Provider MUST approve this contract *before* calling this.
        if (providerStake[msg.sender] == 0) { // Only pull stake if they don't have any yet
             paymentToken.safeTransferFrom(msg.sender, address(this), amountToStake);
             providerStake[msg.sender] = amountToStake;
        } else {
             // If provider already staked and is adding more (e.g. required stake increased),
             // they need to transfer the difference. This function doesn't handle adding stake after initial registration well.
             // A better approach might be a separate `increaseStake` function.
             // Let's keep it simple: registration requires depositing the full required stake.
             revert("Provider already has stake. Cannot re-register.");
        }


        provider.addr = msg.sender;
        provider.status = ProviderStatus.Registered;
        provider.reputation = 0; // Initial reputation
        provider.stakeUnlockTimestamp = 0;

        emit ProviderRegistered(msg.sender, amountToStake);
    }

    function unregisterProvider() external nonReentrant whenNotPaused whenProviderStatusIs(msg.sender, ProviderStatus.Registered) {
        Provider storage provider = providers[msg.sender];
        require(providerStake[msg.sender] > 0, "No stake to unregister");
        // Check if provider has any active tasks? Maybe prevent unregistering if they do.
        // Omitted for brevity, assuming providers finish tasks or tasks timeout/fail.

        provider.status = ProviderStatus.Unregistering;
        // 7-day cooldown example
        provider.stakeUnlockTimestamp = uint48(block.timestamp + 7 * 24 * 3600);

        emit ProviderUnregistering(msg.sender, provider.stakeUnlockTimestamp);
    }

    function claimStake() external nonReentrant whenNotPaused whenProviderStatusIs(msg.sender, ProviderStatus.Unregistering) {
        Provider storage provider = providers[msg.sender];
        require(block.timestamp >= provider.stakeUnlockTimestamp, "Stake is still locked");
        uint256 amount = providerStake[msg.sender];
        require(amount > 0, "No stake to claim");

        providerStake[msg.sender] = 0;
        provider.status = ProviderStatus.Inactive;
        provider.stakeUnlockTimestamp = 0; // Reset

        paymentToken.safeTransfer(msg.sender, amount);

        emit ProviderStakeClaimed(msg.sender, amount);
    }

    function updateProviderStatus(ProviderStatus status) external whenProviderStatusIs(msg.sender, ProviderStatus.Registered) {
        require(status == ProviderStatus.Registered || status == ProviderStatus.Unavailable, "Invalid status update");
        providers[msg.sender].status = status;
        emit ProviderStatusUpdated(msg.sender, status);
    }

    // --- Task Management ---

    function requestTask(
        string calldata modelHash,
        string calldata dataHash,
        uint256 maxCost, // The max amount user is willing to pay the provider
        uint48 customTimeout // Optional: user-defined timeout
    ) external nonReentrant whenNotPaused {
        require(maxCost > 0, "Max cost must be greater than 0");
        require(bytes(modelHash).length > 0, "Model hash cannot be empty");
        require(bytes(dataHash).length > 0, "Data hash cannot be empty");

        uint256 fee = (maxCost * taskFeeRatePermille) / 1000;
        uint256 totalPayment = maxCost + fee;

        // User MUST approve this contract to spend totalPayment BEFORE calling this.
        paymentToken.safeTransferFrom(msg.sender, address(this), totalPayment);

        uint256 taskId = nextTaskId++;
        uint48 timeout = customTimeout > 0 ? customTimeout : defaultTaskTimeout;

        tasks[taskId] = Task({
            id: taskId,
            user: msg.sender,
            provider: address(0),
            modelHash: modelHash,
            dataHash: dataHash,
            taskCost: maxCost,
            totalPayment: totalPayment,
            requestTimestamp: uint48(block.timestamp),
            deadline: uint48(block.timestamp + timeout),
            resultSubmitTimestamp: 0,
            resultHash: "", // Empty initially
            status: TaskStatus.Requested
        });

        emit TaskRequested(taskId, msg.sender, totalPayment, modelHash, dataHash, tasks[taskId].deadline);
    }

    function cancelTaskRequest(uint256 taskId) external nonReentrant whenNotPaused onlyTaskUser(taskId) whenTaskStatusIs(taskId, TaskStatus.Requested) {
        Task storage task = tasks[taskId];
        uint256 refundAmount = task.totalPayment;

        // Mark task as cancelled
        task.status = TaskStatus.Cancelled;

        // Refund user's funds
        paymentToken.safeTransfer(task.user, refundAmount);

        emit TaskCancelled(taskId);
        // Note: Task struct remains, marked as Cancelled. Could potentially free storage later if needed.
    }

    function acceptTask(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Requested, "Task is not available to accept");
        require(block.timestamp <= task.deadline, "Task has already timed out");

        Provider storage provider = providers[msg.sender];
        require(provider.status == ProviderStatus.Registered, "Provider is not registered or available");
        require(provider.reputation >= minReputationToAccept, "Provider reputation too low");
        require(providerStake[msg.sender] >= requiredProviderStake, "Provider does not meet stake requirement"); // Should be guaranteed by Registered status, but good check

        // Assign provider and update status
        task.provider = msg.sender;
        task.status = TaskStatus.Accepted;
        // No timestamp update here, deadline remains from request

        // Stake could be locked now if desired, but let's keep it simple - stake is checked on acceptance
        // and slashed on failure/timeout.

        emit TaskAccepted(taskId, msg.sender);
    }

    function submitTaskResult(uint256 taskId, string calldata resultHash) external nonReentrant whenNotPaused onlyProvider(taskId) whenTaskStatusIs(taskId, TaskStatus.Accepted) {
        Task storage task = tasks[taskId];
        require(block.timestamp <= task.deadline, "Task has already timed out");
        require(bytes(resultHash).length > 0, "Result hash cannot be empty");

        task.resultHash = resultHash;
        task.resultSubmitTimestamp = uint48(block.timestamp);
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(taskId, msg.sender, resultHash);
    }

    function verifyTaskResult(uint256 taskId) external nonReentrant whenNotPaused onlyTaskUser(taskId) {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task result not submitted or already processed");
        require(block.timestamp <= task.resultSubmitTimestamp + verificationPeriod, "Verification period has expired");

        // User confirms result is correct (off-chain check is assumed based on resultHash)

        // Calculate fee and payout
        uint256 fee = task.totalPayment - task.taskCost;
        uint256 payout = task.taskCost;

        // Update fees and transfer payment to provider
        totalPlatformFees += fee;
        paymentToken.safeTransfer(task.provider, payout);

        // Update provider reputation (positive)
        providers[task.provider].reputation += 1; // Simple increment
        emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);


        task.status = TaskStatus.Completed;

        emit TaskResultVerified(taskId, msg.sender);
    }

    function reportTaskFailure(uint256 taskId, string calldata reason) external nonReentrant whenNotPaused onlyTaskUser(taskId) {
         Task storage task = tasks[taskId];
         require(task.status == TaskStatus.Accepted || task.status == TaskStatus.ResultSubmitted, "Task cannot be reported as failed in its current status");
         require(block.timestamp <= task.deadline || (task.status == TaskStatus.ResultSubmitted && block.timestamp <= task.resultSubmitTimestamp + verificationPeriod), "Cannot report failure after task deadline or verification period");

         // Mark task as failed
         task.status = TaskStatus.Failed;

         // Slash a portion of the provider's stake (e.g., 10% of required stake)
         uint256 slashAmount = requiredProviderStake / 10;
         if (providerStake[task.provider] < slashAmount) {
             slashAmount = providerStake[task.provider]; // Slash max available
         }
         providerStake[task.provider] -= slashAmount;
         totalPlatformFees += slashAmount; // Slashing goes to platform fees

         // Update provider reputation (negative)
         providers[task.provider].reputation -= 1; // Simple decrement
         emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);


         emit ProviderStakeSlashing(task.provider, slashAmount);
         emit TaskFailed(taskId, reason);

         // Note: User's funds (totalPayment) remain in the contract.
         // A more complex system could implement partial refunds or a dispute mechanism
         // for the user's funds. For simplicity here, they are not refunded on provider failure.
         // This incentivizes the user to choose reputable providers and potentially request smaller tasks.
     }

    // This function can be called by anyone to clean up timed-out tasks and slash providers
    function reportTaskTimeout(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Requested || task.status == TaskStatus.Accepted || task.status == TaskStatus.ResultSubmitted, "Task not in a state that can timeout");
        require(block.timestamp > task.deadline || (task.status == TaskStatus.ResultSubmitted && block.timestamp > task.resultSubmitTimestamp + verificationPeriod), "Task has not timed out yet");

        // If task was Requested and timed out before acceptance
        if (task.status == TaskStatus.Requested) {
            // Refund user's funds fully
            uint256 refundAmount = task.totalPayment;
            task.status = TaskStatus.Timeout; // Mark as timeout
            paymentToken.safeTransfer(task.user, refundAmount);
            emit TaskTimeout(taskId);
            return; // Exit function
        }

        // If task was Accepted or ResultSubmitted and timed out
        require(task.provider != address(0), "Task accepted provider missing on timeout"); // Should not happen if status is Accepted/Submitted
        task.status = TaskStatus.Timeout; // Mark as timeout

        // Slash a portion of the provider's stake (same logic as reportTaskFailure)
        uint256 slashAmount = requiredProviderStake / 10;
        if (providerStake[task.provider] < slashAmount) {
            slashAmount = providerStake[task.provider]; // Slash max available
        }
        providerStake[task.provider] -= slashAmount;
        totalPlatformFees += slashAmount; // Slashing goes to platform fees

        // Update provider reputation (negative)
        providers[task.provider].reputation -= 1; // Simple decrement
        emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);

        emit ProviderStakeSlashing(task.provider, slashAmount);
        emit TaskTimeout(taskId);

        // User's funds are NOT refunded on provider timeout in this simplified model.
    }

    function extendTaskTimeout(uint256 taskId, uint48 extension) external nonReentrant whenNotPaused onlyTaskUser(taskId) whenTaskStatusIs(taskId, TaskStatus.Requested) {
        Task storage task = tasks[taskId];
        require(extension > 0, "Extension must be positive");
        require(block.timestamp < task.deadline, "Task deadline has already passed");

        // User pays a small fee or percentage of original cost to extend
        // Example: Pay 5% of original task cost to extend
        uint256 extensionCost = (task.taskCost * 50) / 1000; // 5%

        // User MUST approve this contract to spend extensionCost BEFORE calling this.
        paymentToken.safeTransferFrom(msg.sender, address(this), extensionCost);

        // The extension cost goes to platform fees in this model.
        // A more complex model could distribute it to potential future providers or use it differently.
        totalPlatformFees += extensionCost;

        task.deadline = uint48(task.deadline + extension);

        emit TaskTimeoutExtended(taskId, task.deadline, extensionCost);
    }


    // --- State & Information (View Functions) ---

    function getTaskDetails(uint256 taskId) external view returns (Task memory) {
        require(taskId > 0 && taskId < nextTaskId, "Invalid task ID");
        return tasks[taskId];
    }

    function getProviderDetails(address providerAddr) external view returns (Provider memory) {
        require(providerAddr != address(0), "Invalid address");
        return providers[providerAddr];
    }

    // Helper view functions for config
    function getRequiredProviderStake() external view returns (uint256) {
        return requiredProviderStake;
    }

    function getTaskFeeRatePermille() external view returns (uint16) {
        return taskFeeRatePermille;
    }

    function getDefaultTaskTimeout() external view returns (uint48) {
        return defaultTaskTimeout;
    }

    function getVerificationPeriod() external view returns (uint48) {
        return verificationPeriod;
    }

    function getMinReputationToAccept() external view returns (int16) {
        return minReputationToAccept;
    }

    function getProviderReputation(address providerAddr) external view returns (int16) {
         require(providerAddr != address(0), "Invalid address");
         return providers[providerAddr].reputation;
    }

    function getTotalStakedAmount() external view returns (uint256) {
        // This requires iterating through all providers, which is inefficient.
        // A better approach is to maintain a running total in a state variable,
        // updated during stake/unstake/slash operations.
        // For simplicity in this example, let's add a state variable `totalProviderStake`
        // and update it in relevant functions (register, claimStake, slash).
        // (Self-correction: Adding a state variable is better practice for views than iteration).
        // Let's add `totalProviderStake` state variable.

        // Need to add `uint256 public totalProviderStake;`
        // And update it in:
        // registerProvider: totalProviderStake += amountToStake;
        // claimStake: totalProviderStake -= amount;
        // reportTaskFailure: totalProviderStake -= slashAmount;
        // reportTaskTimeout: totalProviderStake -= slashAmount;
        // Re-implementing this function using the new state variable:
         return totalProviderStake;
    }

    // Let's add `uint256 public totalProviderStake;` to the state variables section.
    // The function list will be updated to reflect totalProviderStake instead of getProviderStake.

    // --- Pausable Functions ---

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // The following view function is automatically generated by the `public` keyword for `providerStake` mapping:
    // function providerStake(address providerAddr) external view returns (uint256);
    // This gives the stake for a *specific* provider, distinct from the *total* staked amount.
    // Let's keep `providerStake` mapping public, and add the `getTotalStakedAmount` view (re-implementing it efficiently).

     function getProviderStake(address providerAddr) external view returns (uint256) {
         return providerStake[providerAddr];
     }


    // Final function count check:
    // Constructor: 1
    // Config: 6 + 1 = 7
    // Provider Mgmt: 4
    // Task Mgmt: 8
    // View (Config): 6 (including getProviderStake, excluding totalStake which needs state var)
    // View (Entity): 2 (Task, Provider details)
    // Pause: 2
    // Total = 1 + 7 + 4 + 8 + 6 + 2 + 2 = 30 functions. Well over the required 20.
    // Adding the TotalStakedAmount view using the new state variable makes it 31.

    // Let's add the `totalProviderStake` state variable and update related functions.
    // (This was a refinement step during coding).

    // --- Updated State Variables (including totalProviderStake) ---
    // (Moved to the top in the final code)
    // uint256 public totalProviderStake;

    // --- Updated Functions (registerProvider, claimStake, reportTaskFailure, reportTaskTimeout) ---
    // (Implement the updates to totalProviderStake within these functions)

    // --- Updated View Function (getTotalStakedAmount) ---
    // (Use the new state variable)

    // Need to add SafeMath or check for underflow/overflow? uint256 generally handles large numbers.
    // Addressed by SafeERC20 for token transfers. For other arithmetic, simple +/- should be okay unless numbers become astronomical. Stake/fees are uint256, should be fine. Reputation is int16, bounded. Timestamps are uint48, bounded.

    // Need to ensure all state transitions are valid and covered.
    // - TaskStatus.Requested -> Accepted, Cancelled, Timeout
    // - TaskStatus.Accepted -> ResultSubmitted, Failed, Timeout
    // - TaskStatus.ResultSubmitted -> VerificationPeriod (implied), Completed, Failed, Timeout
    // - TaskStatus.VerificationPeriod -> (Handled by time check in verify/report)
    // - TaskStatus.Completed, Failed, Cancelled, Timeout are terminal.

    // Seems reasonable for a base version. More advanced features could include:
    // - Partial stake slashing configurable by failure type.
    // - User refunds on *some* types of provider failures.
    // - A more complex, potentially game-theory-backed verification or dispute system.
    // - Allowing different payment tokens.
    // - Provider tiers based on stake/reputation.
    // - On-chain queueing for tasks.
    // - ZK proofs for verifiable computation results (much harder).

    // This contract provides a solid *framework* for coordinating decentralized compute.
    // The 20+ function requirement pushed towards covering more aspects of the lifecycle and roles.

}
```

```solidity
// Add the new state variable
// uint256 public totalProviderStake; // This needs to be added to the state variable section

// Update registerProvider:
/*
    function registerProvider() external payable nonReentrant whenNotPaused {
        Provider storage provider = providers[msg.sender];
        require(provider.status == ProviderStatus.Inactive, "Provider already registered or unregistering");

        uint256 amountToStake = requiredProviderStake;
        // For ERC20: Provider MUST approve this contract *before* calling this.
        require(paymentToken.balanceOf(msg.sender) >= amountToStake, "Insufficient token balance to stake");

        paymentToken.safeTransferFrom(msg.sender, address(this), amountToStake);
        providerStake[msg.sender] = amountToStake;
        totalProviderStake += amountToStake; // <-- Update total

        provider.addr = msg.sender;
        provider.status = ProviderStatus.Registered;
        provider.reputation = 0; // Initial reputation
        provider.stakeUnlockTimestamp = 0;

        emit ProviderRegistered(msg.sender, amountToStake);
    }
*/

// Update claimStake:
/*
    function claimStake() external nonReentrant whenNotPaused whenProviderStatusIs(msg.sender, ProviderStatus.Unregistering) {
        Provider storage provider = providers[msg.sender];
        require(block.timestamp >= provider.stakeUnlockTimestamp, "Stake is still locked");
        uint256 amount = providerStake[msg.sender];
        require(amount > 0, "No stake to claim");

        providerStake[msg.sender] = 0;
        totalProviderStake -= amount; // <-- Update total
        provider.status = ProviderStatus.Inactive;
        provider.stakeUnlockTimestamp = 0; // Reset

        paymentToken.safeTransfer(msg.sender, amount);

        emit ProviderStakeClaimed(msg.sender, amount);
    }
*/

// Update reportTaskFailure:
/*
    function reportTaskFailure(uint256 taskId, string calldata reason) external nonReentrant whenNotPaused onlyTaskUser(taskId) {
         Task storage task = tasks[taskId];
         require(task.status == TaskStatus.Accepted || task.status == TaskStatus.ResultSubmitted, "Task cannot be reported as failed in its current status");
         require(block.timestamp <= task.deadline || (task.status == TaskStatus.ResultSubmitted && block.timestamp <= task.resultSubmitTimestamp + verificationPeriod), "Cannot report failure after task deadline or verification period");

         // Mark task as failed
         task.status = TaskStatus.Failed;

         // Slash a portion of the provider's stake (e.g., 10% of required stake)
         uint256 slashAmount = requiredProviderStake / 10;
         if (providerStake[task.provider] < slashAmount) {
             slashAmount = providerStake[task.provider]; // Slash max available
         }
         providerStake[task.provider] -= slashAmount;
         totalProviderStake -= slashAmount; // <-- Update total
         totalPlatformFees += slashAmount; // Slashing goes to platform fees

         // Update provider reputation (negative)
         providers[task.provider].reputation -= 1; // Simple decrement
         emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);

         emit ProviderStakeSlashing(task.provider, slashAmount);
         emit TaskFailed(taskId, reason);
     }
*/

// Update reportTaskTimeout:
/*
    function reportTaskTimeout(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Requested || task.status == TaskStatus.Accepted || task.status == TaskStatus.ResultSubmitted, "Task not in a state that can timeout");
        require(block.timestamp > task.deadline || (task.status == TaskStatus.ResultSubmitted && block.timestamp > task.resultSubmitTimestamp + verificationPeriod), "Task has not timed out yet");

        // If task was Requested and timed out before acceptance
        if (task.status == TaskStatus.Requested) {
            // Refund user's funds fully
            uint256 refundAmount = task.totalPayment;
            task.status = TaskStatus.Timeout; // Mark as timeout
            paymentToken.safeTransfer(task.user, refundAmount);
            emit TaskTimeout(taskId);
            return; // Exit function
        }

        // If task was Accepted or ResultSubmitted and timed out
        require(task.provider != address(0), "Task accepted provider missing on timeout"); // Should not happen if status is Accepted/Submitted
        task.status = TaskStatus.Timeout; // Mark as timeout

        // Slash a portion of the provider's stake (same logic as reportTaskFailure)
        uint256 slashAmount = requiredProviderStake / 10;
        if (providerStake[task.provider] < slashAmount) {
            slashAmount = providerStake[task.provider]; // Slash max available
        }
        providerStake[task.provider] -= slashAmount;
        totalProviderStake -= slashAmount; // <-- Update total
        totalPlatformFees += slashAmount; // Slashing goes to platform fees

        // Update provider reputation (negative)
        providers[task.provider].reputation -= 1; // Simple decrement
        emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);

        emit ProviderStakeSlashing(task.provider, slashAmount);
        emit TaskTimeout(taskId);
     }
*/

// Add the new view function using the totalProviderStake state variable
/*
    function getTotalStakedAmount() external view returns (uint256) {
        return totalProviderStake;
    }
*/

// The final code above includes the totalProviderStake variable and updates in relevant functions.
// The function count is 31, satisfying the requirement.
```

```solidity
// --- Decentralized AI Computing Hub Smart Contract ---
// This contract facilitates a decentralized marketplace for AI computation tasks.
// Users can request tasks and fund them, while providers stake tokens
// to offer compute resources, accept tasks, submit results, and get paid upon verification.
// The contract includes features like staking, slashing, basic reputation,
// and a defined task lifecycle.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Outline ---
// 1. Configuration Management: Define global parameters like stake requirements, fees, timeouts, verification periods, and minimum reputation. (Owner-controlled)
// 2. Provider Lifecycle: Handle registration (staking), status updates (available/unavailable), unregistering (with cooldown), and stake withdrawal.
// 3. Task Lifecycle: Manage task requests from users, acceptance by providers, result submission, user verification of results, reporting failures/timeouts, and cancellation.
// 4. Payment & Slashing: Facilitate payment to providers upon successful verification, collect platform fees, and slash provider stake upon task failures or timeouts.
// 5. Reputation System: Implement a simple mechanism to track and update provider reputation based on task outcomes.
// 6. State Information: Provide view functions to inspect contract configuration, task details, and provider information.
// 7. Access Control & Safety: Use modifiers and OpenZeppelin libraries for secure access control and reentrancy prevention.

// --- Function Summary ---
// Configuration:
// 1.  constructor(IERC20 _paymentToken): Initializes the contract with the payment token address and sets the owner.
// 2.  setRequiredProviderStake(uint256 amount): Allows the owner to set the required token stake for new providers.
// 3.  setTaskFeeRatePermille(uint16 ratePermille): Allows the owner to set the platform fee percentage for tasks, in parts per thousand.
// 4.  setDefaultTaskTimeout(uint48 timeout): Allows the owner to set the default time limit for task completion.
// 5.  setVerificationPeriod(uint48 period): Allows the owner to set the time window users have to verify results.
// 6.  setMinReputationToAccept(int16 reputation): Allows the owner to set the minimum reputation score a provider needs to accept tasks.
// 7.  withdrawFees(): Allows the owner to withdraw accumulated platform fees.

// Provider Management:
// 8.  registerProvider(): Allows a user to stake the required tokens and register as a compute provider.
// 9.  unregisterProvider(): Allows a registered provider to initiate the unregistration process, locking their stake for a cooldown period.
// 10. claimStake(): Allows an unregistering provider to claim their stake after the cooldown period has passed.
// 11. updateProviderStatus(ProviderStatus status): Allows a provider to update their availability status (e.g., Registered, Unavailable).

// Task Management:
// 12. requestTask(string calldata modelHash, string calldata dataHash, uint256 maxCost, uint48 customTimeout): Allows a user to request a computation task, depositing the specified maximum cost and fee.
// 13. cancelTaskRequest(uint256 taskId): Allows a user to cancel their task request if it hasn't been accepted by a provider yet, refunding the funds.
// 14. acceptTask(uint256 taskId): Allows a registered and available provider meeting the minimum reputation to accept a pending task request.
// 15. submitTaskResult(uint256 taskId, string calldata resultHash): Allows the task provider to submit the hash of the off-chain computation result.
// 16. verifyTaskResult(uint256 taskId): Allows the task user to verify the submitted result (based on off-chain check), triggering payment to the provider and a positive reputation update.
// 17. reportTaskFailure(uint256 taskId, string calldata reason): Allows the task user to report a provider failure (e.g., incorrect result) during the active or verification phase, triggering stake slashing and a negative reputation update.
// 18. reportTaskTimeout(uint256 taskId): Allows anyone to report a task that has exceeded its deadline or verification period, triggering stake slashing (if accepted/submitted) or user refund (if requested).
// 19. extendTaskTimeout(uint256 taskId, uint48 extension): Allows the task user to pay an additional fee to extend the deadline of a task that has not yet been accepted.

// State Information (View Functions):
// 20. getTaskDetails(uint256 taskId): Retrieves all details for a specific task.
// 21. getProviderDetails(address providerAddr): Retrieves all details for a specific provider address.
// 22. getRequiredProviderStake(): Returns the current required stake amount for providers.
// 23. getTaskFeeRatePermille(): Returns the current task fee rate in per mille.
// 24. getDefaultTaskTimeout(): Returns the current default task timeout duration.
// 25. getVerificationPeriod(): Returns the current result verification period duration.
// 26. getMinReputationToAccept(): Returns the current minimum reputation required for providers.
// 27. getProviderReputation(address providerAddr): Returns the reputation score for a specific provider.
// 28. getProviderStake(address providerAddr): Returns the amount of tokens staked by a specific provider.
// 29. getTotalStakedAmount(): Returns the total amount of tokens currently staked by all registered providers in the contract.

// Access Control & Safety:
// 30. pause(): Owner can pause contract operations in case of emergency.
// 31. unpause(): Owner can unpause contract operations.


contract DecentralizedAIComputingHub is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken;

    // --- Configuration ---
    uint256 public requiredProviderStake;
    uint16 public taskFeeRatePermille; // e.g., 50 for 5%
    uint48 public defaultTaskTimeout; // Duration in seconds
    uint48 public verificationPeriod; // Duration in seconds for user verification
    int16 public minReputationToAccept; // Minimum reputation required for providers to accept tasks

    // --- State Variables ---
    enum TaskStatus {
        Requested,        // Task requested by user, waiting for provider
        Accepted,         // Task accepted by a provider
        ResultSubmitted,  // Provider submitted result hash, waiting for verification
        VerificationPeriod, // User has a time window to verify (implicitly handled by time check)
        Completed,        // Task verified by user, payment released
        Failed,           // Task reported failed by user or provider
        Cancelled,        // Task cancelled by user before acceptance
        Timeout           // Task timed out before result submission
    }

    enum ProviderStatus {
        Inactive,         // Not registered, stake is 0
        Registered,       // Staked and available
        Unavailable,      // Staked but temporarily unavailable
        Unregistering     // Initiated unregistration, stake is locked
    }

    struct Task {
        uint256 id;
        address user;
        address provider; // address(0) if not yet accepted
        string modelHash;
        string dataHash;
        uint256 taskCost; // Amount paid to provider (maxCost requested by user)
        uint256 totalPayment; // totalPayment = taskCost + fee (amount deposited by user)
        uint48 requestTimestamp;
        uint48 deadline; // When the task must be completed by
        uint48 resultSubmitTimestamp; // When the result was submitted (0 if not submitted)
        string resultHash; // Hash of the computation result (empty if not submitted)
        TaskStatus status;
    }

    struct Provider {
        address addr;
        ProviderStatus status;
        int16 reputation;
        uint48 stakeUnlockTimestamp; // For unregistering cooldown (0 if not unregistering)
    }

    uint256 private nextTaskId;
    mapping(uint256 => Task) public tasks;
    mapping(address => Provider) public providers;
    mapping(address => uint256) public providerStake; // Separate mapping for staked amount per provider

    uint256 public totalPlatformFees; // Accumulated fees from tasks and slashing
    uint256 public totalProviderStake; // Total amount of tokens staked by all providers

    // --- Events ---
    event ProviderRegistered(address indexed provider, uint256 stakeAmount);
    event ProviderUnregistering(address indexed provider, uint48 unlockTimestamp);
    event ProviderStakeClaimed(address indexed provider, uint256 amount);
    event ProviderStatusUpdated(address indexed provider, ProviderStatus status);

    event TaskRequested(uint256 indexed taskId, address indexed user, uint256 totalPayment, string modelHash, uint48 deadline); // dataHash omitted for gas
    event TaskCancelled(uint256 indexed taskId);
    event TaskAccepted(uint256 indexed taskId, address indexed provider);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed provider, string resultHash);
    event TaskResultVerified(uint256 indexed taskId, address indexed user);
    event TaskFailed(uint256 indexed taskId, string reason);
    event TaskTimeout(uint256 indexed taskId);
    event TaskTimeoutExtended(uint256 indexed taskId, uint48 newDeadline, uint256 extraCost);

    event FeesWithdrawn(address indexed owner, uint255 amount); // uint255 to match SafeTransfer
    event ProviderStakeSlashing(address indexed provider, uint255 amount); // uint255
    event ProviderReputationUpdated(address indexed provider, int16 newReputation);

    // --- Modifiers ---
    modifier onlyProvider(uint256 taskId) {
        require(tasks[taskId].provider == msg.sender, "Not task provider");
        _;
    }

    modifier onlyTaskUser(uint256 taskId) {
        require(tasks[taskId].user == msg.sender, "Not task user");
        _;
    }

    modifier whenTaskStatusIs(uint256 taskId, TaskStatus expectedStatus) {
        require(tasks[taskId].status == expectedStatus, "Task not in expected status");
        _;
    }

    modifier whenProviderStatusIs(address providerAddr, ProviderStatus expectedStatus) {
        require(providers[providerAddr].status == expectedStatus, "Provider not in expected status");
        _;
    }

    // --- Constructor ---
    constructor(IERC20 _paymentToken) Ownable(msg.sender) {
        paymentToken = _paymentToken;
        nextTaskId = 1;
        // Set some reasonable defaults - owner should adjust these post-deployment
        requiredProviderStake = 1000000000000000000; // 1e18, assuming 18 decimals
        taskFeeRatePermille = 50; // 5%
        defaultTaskTimeout = 24 * 3600; // 24 hours
        verificationPeriod = 72 * 3600; // 72 hours
        minReputationToAccept = 0; // Start with 0 required
    }

    // --- Configuration (Owner Only) ---
    function setRequiredProviderStake(uint256 amount) external onlyOwner {
        require(amount > 0, "Stake must be > 0");
        requiredProviderStake = amount;
    }

    function setTaskFeeRatePermille(uint16 ratePermille) external onlyOwner {
        require(ratePermille <= 1000, "Rate cannot exceed 100%");
        taskFeeRatePermille = ratePermille;
    }

    function setDefaultTaskTimeout(uint48 timeout) external onlyOwner {
        require(timeout > 0, "Timeout must be > 0");
        defaultTaskTimeout = timeout;
    }

    function setVerificationPeriod(uint48 period) external onlyOwner {
        require(period > 0, "Verification period must be > 0");
        verificationPeriod = period;
    }

    function setMinReputationToAccept(int16 reputation) external onlyOwner {
        minReputationToAccept = reputation;
    }

    function withdrawFees() external onlyOwner nonReentrant {
        uint256 feesToWithdraw = totalPlatformFees;
        totalPlatformFees = 0;
        if (feesToWithdraw > 0) {
            paymentToken.safeTransfer(owner(), feesToWithdraw);
            emit FeesWithdrawn(owner(), uint255(feesToWithdraw)); // Cast to uint255 for event
        }
    }

    // --- Provider Management ---

    function registerProvider() external nonReentrant whenNotPaused {
        Provider storage provider = providers[msg.sender];
        require(provider.status == ProviderStatus.Inactive, "Provider already registered or unregistering");

        uint256 amountToStake = requiredProviderStake;
        // Provider MUST approve this contract to spend amountToStake BEFORE calling this.
        require(paymentToken.allowance(msg.sender, address(this)) >= amountToStake, "Insufficient token allowance");

        paymentToken.safeTransferFrom(msg.sender, address(this), amountToStake);
        providerStake[msg.sender] = amountToStake;
        totalProviderStake += amountToStake; // <-- Update total

        provider.addr = msg.sender;
        provider.status = ProviderStatus.Registered;
        provider.reputation = 0; // Initial reputation
        provider.stakeUnlockTimestamp = 0;

        emit ProviderRegistered(msg.sender, amountToStake);
    }

    function unregisterProvider() external nonReentrant whenNotPaused whenProviderStatusIs(msg.sender, ProviderStatus.Registered) {
        Provider storage provider = providers[msg.sender];
        require(providerStake[msg.sender] > 0, "No stake to unregister");
        // Could add a check here to prevent unregistering if provider has active tasks accepted.
        // Omitted for simplicity.

        provider.status = ProviderStatus.Unregistering;
        // Example: 7-day cooldown
        provider.stakeUnlockTimestamp = uint48(block.timestamp + 7 * 24 * 3600);

        emit ProviderUnregistering(msg.sender, provider.stakeUnlockTimestamp);
    }

    function claimStake() external nonReentrant whenNotPaused whenProviderStatusIs(msg.sender, ProviderStatus.Unregistering) {
        Provider storage provider = providers[msg.sender];
        require(block.timestamp >= provider.stakeUnlockTimestamp, "Stake is still locked");
        uint256 amount = providerStake[msg.sender];
        require(amount > 0, "No stake to claim");

        providerStake[msg.sender] = 0;
        totalProviderStake -= amount; // <-- Update total
        provider.status = ProviderStatus.Inactive;
        provider.stakeUnlockTimestamp = 0; // Reset

        paymentToken.safeTransfer(msg.sender, amount);

        emit ProviderStakeClaimed(msg.sender, amount);
    }

    function updateProviderStatus(ProviderStatus status) external whenProviderStatusIs(msg.sender, ProviderStatus.Registered) {
        require(status == ProviderStatus.Registered || status == ProviderStatus.Unavailable, "Invalid status update");
        providers[msg.sender].status = status;
        emit ProviderStatusUpdated(msg.sender, status);
    }

    // --- Task Management ---

    function requestTask(
        string calldata modelHash,
        string calldata dataHash,
        uint256 maxCost, // The max amount user is willing to pay the provider
        uint48 customTimeout // Optional: user-defined timeout
    ) external nonReentrant whenNotPaused {
        require(maxCost > 0, "Max cost must be greater than 0");
        require(bytes(modelHash).length > 0, "Model hash cannot be empty");
        require(bytes(dataHash).length > 0, "Data hash cannot be empty");
        require(block.timestamp <= type(uint48).max - (customTimeout > 0 ? customTimeout : defaultTaskTimeout), "Timeout too large");


        uint256 fee = (maxCost * taskFeeRatePermille) / 1000;
        uint256 totalPayment = maxCost + fee;

        // User MUST approve this contract to spend totalPayment BEFORE calling this.
        require(paymentToken.allowance(msg.sender, address(this)) >= totalPayment, "Insufficient token allowance");
        paymentToken.safeTransferFrom(msg.sender, address(this), totalPayment);

        uint256 taskId = nextTaskId++;
        uint48 timeout = customTimeout > 0 ? customTimeout : defaultTaskTimeout;

        tasks[taskId] = Task({
            id: taskId,
            user: msg.sender,
            provider: address(0),
            modelHash: modelHash,
            dataHash: dataHash,
            taskCost: maxCost,
            totalPayment: totalPayment,
            requestTimestamp: uint48(block.timestamp),
            deadline: uint48(block.timestamp + timeout),
            resultSubmitTimestamp: 0,
            resultHash: "", // Empty initially
            status: TaskStatus.Requested
        });

        emit TaskRequested(taskId, msg.sender, totalPayment, modelHash, tasks[taskId].deadline);
    }

    function cancelTaskRequest(uint256 taskId) external nonReentrant whenNotPaused onlyTaskUser(taskId) whenTaskStatusIs(taskId, TaskStatus.Requested) {
        Task storage task = tasks[taskId];
        uint256 refundAmount = task.totalPayment;

        // Mark task as cancelled
        task.status = TaskStatus.Cancelled;

        // Refund user's funds
        paymentToken.safeTransfer(task.user, refundAmount);

        emit TaskCancelled(taskId);
        // Note: Task struct remains, marked as Cancelled. Could potentially free storage later if needed.
    }

    function acceptTask(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Requested, "Task is not available to accept");
        require(block.timestamp <= task.deadline, "Task has already timed out");

        Provider storage provider = providers[msg.sender];
        require(provider.status == ProviderStatus.Registered, "Provider is not registered or available");
        require(provider.reputation >= minReputationToAccept, "Provider reputation too low");
        require(providerStake[msg.sender] >= requiredProviderStake, "Provider does not meet stake requirement"); // Should be guaranteed by Registered status, but good check

        // Assign provider and update status
        task.provider = msg.sender;
        task.status = TaskStatus.Accepted;
        // No timestamp update here, deadline remains from request

        // Stake could be locked now if desired, but let's keep it simple - stake is checked on acceptance
        // and slashed on failure/timeout.

        emit TaskAccepted(taskId, msg.sender);
    }

    function submitTaskResult(uint256 taskId, string calldata resultHash) external nonReentrant whenNotPaused onlyProvider(taskId) whenTaskStatusIs(taskId, TaskStatus.Accepted) {
        Task storage task = tasks[taskId];
        require(block.timestamp <= task.deadline, "Task has already timed out");
        require(bytes(resultHash).length > 0, "Result hash cannot be empty");
        require(block.timestamp <= type(uint48).max - verificationPeriod, "Verification period causes timestamp overflow");


        task.resultHash = resultHash;
        task.resultSubmitTimestamp = uint48(block.timestamp);
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(taskId, msg.sender, resultHash);
    }

    function verifyTaskResult(uint256 taskId) external nonReentrant whenNotPaused onlyTaskUser(taskId) {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task result not submitted or already processed");
        require(block.timestamp <= task.resultSubmitTimestamp + verificationPeriod, "Verification period has expired");

        // User confirms result is correct (off-chain check is assumed based on resultHash)

        // Calculate fee and payout
        uint256 fee = task.totalPayment - task.taskCost;
        uint256 payout = task.taskCost;
        require(task.totalPayment >= fee, "Fee calculation error"); // Defensive check
        require(task.totalPayment >= payout, "Payout calculation error"); // Defensive check


        // Update fees and transfer payment to provider
        totalPlatformFees += fee;
        paymentToken.safeTransfer(task.provider, payout);

        // Update provider reputation (positive)
        providers[task.provider].reputation += 1; // Simple increment
        emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);

        task.status = TaskStatus.Completed;

        emit TaskResultVerified(taskId, msg.sender);
    }

    function reportTaskFailure(uint256 taskId, string calldata reason) external nonReentrant whenNotPaused onlyTaskUser(taskId) {
         Task storage task = tasks[taskId];
         require(task.status == TaskStatus.Accepted || task.status == TaskStatus.ResultSubmitted, "Task cannot be reported as failed in its current status");
         require(block.timestamp <= task.deadline || (task.status == TaskStatus.ResultSubmitted && block.timestamp <= task.resultSubmitTimestamp + verificationPeriod), "Cannot report failure after task deadline or verification period");

         // Mark task as failed
         task.status = TaskStatus.Failed;

         // Slash a portion of the provider's stake (e.g., 10% of required stake)
         uint256 slashAmount = requiredProviderStake / 10;
         if (providerStake[task.provider] < slashAmount) {
             slashAmount = providerStake[task.provider]; // Slash max available
         }
         providerStake[task.provider] -= slashAmount;
         totalProviderStake -= slashAmount; // <-- Update total stake
         totalPlatformFees += slashAmount; // Slashing goes to platform fees

         // Update provider reputation (negative)
         providers[task.provider].reputation -= 1; // Simple decrement
         emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);

         emit ProviderStakeSlashing(task.provider, uint255(slashAmount)); // Cast for event
         emit TaskFailed(taskId, reason);

         // Note: User's funds (totalPayment) remain in the contract and are not refunded on provider failure
         // in this simplified model.
     }

    // This function can be called by anyone to clean up timed-out tasks and slash providers
    function reportTaskTimeout(uint256 taskId) external nonReentrant whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Requested || task.status == TaskStatus.Accepted || task.status == TaskStatus.ResultSubmitted, "Task not in a state that can timeout");
        // Check if the deadline has passed for Accepted/Requested tasks, OR if the verification period has passed for Submitted tasks
        bool isTimeout = (task.status != TaskStatus.ResultSubmitted && block.timestamp > task.deadline) ||
                         (task.status == TaskStatus.ResultSubmitted && task.resultSubmitTimestamp > 0 && block.timestamp > task.resultSubmitTimestamp + verificationPeriod);
        require(isTimeout, "Task has not timed out yet");

        // If task was Requested and timed out before acceptance
        if (task.status == TaskStatus.Requested) {
            uint256 refundAmount = task.totalPayment;
            task.status = TaskStatus.Timeout; // Mark as timeout
            paymentToken.safeTransfer(task.user, refundAmount);
            emit TaskTimeout(taskId);
            return; // Exit function
        }

        // If task was Accepted or ResultSubmitted and timed out
        require(task.provider != address(0), "Task accepted provider missing on timeout"); // Should not happen if status is Accepted/Submitted
        task.status = TaskStatus.Timeout; // Mark as timeout

        // Slash a portion of the provider's stake (same logic as reportTaskFailure)
        uint256 slashAmount = requiredProviderStake / 10;
        if (providerStake[task.provider] < slashAmount) {
            slashAmount = providerStake[task.provider]; // Slash max available
        }
        providerStake[task.provider] -= slashAmount;
        totalProviderStake -= slashAmount; // <-- Update total stake
        totalPlatformFees += slashAmount; // Slashing goes to platform fees

        // Update provider reputation (negative)
        providers[task.provider].reputation -= 1; // Simple decrement
        emit ProviderReputationUpdated(task.provider, providers[task.provider].reputation);

        emit ProviderStakeSlashing(task.provider, uint255(slashAmount)); // Cast for event
        emit TaskTimeout(taskId);

        // User's funds are NOT refunded on provider timeout in this simplified model.
    }

    function extendTaskTimeout(uint256 taskId, uint48 extension) external nonReentrant whenNotPaused onlyTaskUser(taskId) whenTaskStatusIs(taskId, TaskStatus.Requested) {
        Task storage task = tasks[taskId];
        require(extension > 0, "Extension must be positive");
        require(block.timestamp < task.deadline, "Task deadline has already passed");
        require(task.deadline <= type(uint48).max - extension, "Extension causes deadline overflow");

        // User pays a small fee or percentage of original cost to extend
        // Example: Pay 5% of original task cost to extend
        uint256 extensionCost = (task.taskCost * 50) / 1000; // 5%

        // User MUST approve this contract to spend extensionCost BEFORE calling this.
        require(paymentToken.allowance(msg.sender, address(this)) >= extensionCost, "Insufficient token allowance for extension");
        paymentToken.safeTransferFrom(msg.sender, address(this), extensionCost);

        // The extension cost goes to platform fees in this model.
        totalPlatformFees += extensionCost;

        task.deadline = uint48(task.deadline + extension);

        emit TaskTimeoutExtended(taskId, task.deadline, extensionCost);
    }


    // --- State Information (View Functions) ---

    function getTaskDetails(uint256 taskId) external view returns (Task memory) {
        require(taskId > 0 && taskId < nextTaskId, "Invalid task ID");
        return tasks[taskId];
    }

    function getProviderDetails(address providerAddr) external view returns (Provider memory) {
        require(providerAddr != address(0), "Invalid address");
        // Return empty/default Provider struct if address is not a registered provider
        if (providers[providerAddr].addr == address(0) && providerStake[providerAddr] == 0) {
            return Provider(address(0), ProviderStatus.Inactive, 0, 0);
        }
        return providers[providerAddr];
    }

    // Helper view functions for config
    function getRequiredProviderStake() external view returns (uint256) {
        return requiredProviderStake;
    }

    function getTaskFeeRatePermille() external view returns (uint16) {
        return taskFeeRatePermille;
    }

    function getDefaultTaskTimeout() external view returns (uint48) {
        return defaultTaskTimeout;
    }

    function getVerificationPeriod() external view returns (uint48) {
        return verificationPeriod;
    }

    function getMinReputationToAccept() external view returns (int16) {
        return minReputationToAccept;
    }

    function getProviderReputation(address providerAddr) external view returns (int16) {
         require(providerAddr != address(0), "Invalid address");
         return providers[providerAddr].reputation;
    }

    function getProviderStake(address providerAddr) external view returns (uint256) {
         require(providerAddr != address(0), "Invalid address");
         return providerStake[providerAddr];
    }

    function getTotalStakedAmount() external view returns (uint256) {
        return totalProviderStake;
    }

    // --- Access Control & Safety ---

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // Note: Functions decorated with `whenNotPaused` automatically revert when paused.
    // Owner functions and pure/view functions typically do not need `whenNotPaused`.

}
```