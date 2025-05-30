Okay, here is a Solidity smart contract incorporating several advanced, creative, and interconnected concepts beyond typical open-source examples like basic ERC-20, ERC-721, or standard staking/vault patterns.

The core idea revolves around a "Vault of Ethereal Essence". Users deposit tokens, and based on duration, specific actions they take (like "Refining"), and global epoch parameters, they accumulate a unique, non-transferable "Essence State". This state can be "Crystallized" (checkpointed), influencing potential future rewards or unlock conditions. The contract includes features like epochs with dynamic parameters, delegated actions, conditional execution of scheduled actions, and a unique internal "Flash" action.

---

**Contract Outline and Function Summary**

**Contract Name:** `EtherealEssenceVault`

**Core Concepts:**
1.  **Epochs:** Time-based periods influencing vault parameters (e.g., essence accumulation rate, fee multipliers).
2.  **Essence State:** A dynamic, user-specific value derived from deposit duration, actions, and epoch parameters. It's not a token but a state variable.
3.  **Refining:** An action users can take on their deposit to influence their Essence State, potentially with costs or time locks.
4.  **Crystallization:** Checkpointing/locking the current Essence State value. This might be required for reward eligibility or future actions.
5.  **Delegated Actions:** Users can delegate specific actions (like Refining) to another address.
6.  **Conditional Execution:** Users can schedule actions to be executed later, but only if predefined on-chain conditions are met. Requires an external trigger (e.g., a relayer/keeper).
7.  **Flash Crystallize:** A special action allowing immediate Crystallization (potentially skipping time locks) in exchange for a higher, immediate fee within the same transaction.
8.  **Dynamic Fees:** Fees for certain actions (Withdrawal, Refine, Flash Crystallize) can vary based on current vault state, user state, or epoch parameters.

**Structs:**
*   `EpochData`: Stores parameters for a specific epoch (start time, essence multiplier, base fees).
*   `UserData`: Stores user-specific information (deposit amount, last deposit time, last refine time, current raw essence parameters, crystallized essence, delegated refiner address).
*   `ConditionalAction`: Stores parameters for a scheduled conditional action (target function selector, execution timestamp, min essence requirement, etc.).

**State Variables:**
*   `owner`: Contract owner (for administrative functions).
*   `governanceTreasury`: Address receiving fees.
*   `essenceToken`: The ERC-20 token accepted for deposit.
*   `isPaused`: Pausing mechanism state.
*   `currentEpochIndex`: Index of the active epoch.
*   `epochs`: Mapping from epoch index to `EpochData`.
*   `users`: Mapping from user address to `UserData`.
*   `totalDeposited`: Total tokens held in the vault.
*   `totalCrystallizedEssence`: Sum of crystallized essence across all users.
*   `userConditionalActions`: Mapping from user address to a mapping of unique action IDs to `ConditionalAction`.
*   `conditionalActionCounter`: Counter for generating unique action IDs per user.

**Enums:**
*   `ConditionalActionType`: Defines types of scheduled actions (e.g., `Withdraw`, `Refine`, `Crystallize`).

**Events:**
*   `Deposited`: Log deposit.
*   `Withdrawn`: Log withdrawal.
*   `EssenceRefined`: Log refine action.
*   `EssenceCrystallized`: Log essence crystallization.
*   `DelegationUpdated`: Log delegation change.
*   `NewEpochStarted`: Log start of a new epoch.
*   `EpochParametersUpdated`: Log epoch parameter changes.
*   `ConditionalActionScheduled`: Log scheduling of an action.
*   `ConditionalActionCancelled`: Log cancellation of an action.
*   `ConditionalActionExecuted`: Log execution of a scheduled action.
*   `Paused`, `Unpaused`: Log pausing state.
*   `OwnershipTransferred`: Log ownership change.
*   `FeesCollected`: Log fee collection.
*   `FlashCrystallized`: Log flash crystallization action.

**Functions (20+):**

1.  `constructor(address _essenceToken, address _governanceTreasury)`: Initializes the contract, sets token and treasury addresses, starts epoch 0.
2.  `deposit(uint256 amount)`: Allows users to deposit `essenceToken`. Requires approval. Updates user and total states.
3.  `withdraw(uint256 amount)`: Allows users to withdraw. Calculates and deducts dynamic withdrawal fee. Updates user and total states.
4.  `emergencyWithdraw(uint256 amount)`: Owner/Admin function for emergency situations. Skips dynamic fee calculation.
5.  `getCurrentUserEssence(address user)`: View function. Calculates the *simulated current* essence for a user based on deposit time, refine state, and current epoch parameters. *Does not change state.*
6.  `refineEssence()`: User action. Triggers a 'refinement' process on their deposit. Pays a dynamic refine fee. Updates user's last refine time and internal essence parameters.
7.  `crystallizeEssence()`: User action. Locks the current calculated essence state, adding it to the user's crystallized balance and the total. Resets parameters used for raw essence accumulation. Pays a dynamic crystallization fee.
8.  `flashCrystallize()`: User action. Immediately crystallizes essence, potentially bypassing time locks associated with normal crystallization, but paying a significantly higher dynamic fee within the same transaction.
9.  `delegateRefiner(address delegatee)`: Allows a user to delegate the `refineEssence` function call permission to another address.
10. `revokeDelegation()`: Allows a user to revoke the delegated refiner permission.
11. `executeDelegatedRefine(address delegator)`: Callable by a delegated address to perform `refineEssence` on behalf of the `delegator`.
12. `scheduleConditionalAction(ConditionalActionType actionType, uint256 executionTimestamp, uint256 minEssenceRequirement, uint256 actionParam)`: Allows a user to schedule an action (e.g., withdraw, refine, crystallize) to happen *after* `executionTimestamp`, *if* their current essence is at least `minEssenceRequirement`. Returns a unique `actionId`.
13. `cancelConditionalAction(uint256 actionId)`: Allows a user to cancel a previously scheduled conditional action.
14. `executeScheduledAction(address user, uint256 actionId)`: Callable by *anyone* (a keeper) to attempt execution of a user's scheduled action. It checks `block.timestamp >= executionTimestamp` and `getCurrentUserEssence(user) >= minEssenceRequirement` before executing the target action (`withdraw`, `refineEssence`, or `crystallizeEssence`) on behalf of the user. Pays a small gas bounty to the caller? (Let's add this).
15. `checkConditionalActionEligibility(address user, uint256 actionId)`: View function. Returns true if the specified conditional action's conditions are met *now*.
16. `startNewEpoch(uint256 essenceMultiplier, uint256 baseWithdrawalFeeBps, uint256 baseRefineFeeBps, uint256 baseCrystallizeFeeBps, uint256 baseFlashCrystallizeFeeBps)`: Owner function. Starts a new epoch with specified parameters.
17. `setEpochParameters(uint256 epochIndex, uint256 essenceMultiplier, uint256 baseWithdrawalFeeBps, uint256 baseRefineFeeBps, uint256 baseCrystallizeFeeBps, uint256 baseFlashCrystallizeFeeBps)`: Owner function. Allows updating parameters for a *future* or the *current* epoch (with caution).
18. `pause()`: Owner function. Pauses the contract for emergencies.
19. `unpause()`: Owner function. Unpauses the contract.
20. `transferOwnership(address newOwner)`: Owner function. Transfers ownership.
21. `setGovernanceTreasury(address _newTreasury)`: Owner function. Updates the address where fees are sent.
22. `getWithdrawalFee(address user, uint256 amount)`: View function. Calculates the dynamic withdrawal fee for a specific user and amount based on current state and epoch parameters.
23. `getRefineFee(address user)`: View function. Calculates the dynamic refine fee.
24. `getCrystallizeFee(address user)`: View function. Calculates the dynamic crystallization fee.
25. `getFlashCrystallizeFee(address user)`: View function. Calculates the dynamic flash crystallization fee.
26. `getUserData(address user)`: View function. Returns the `UserData` struct for a user.
27. `getEpochData(uint256 epochIndex)`: View function. Returns the `EpochData` struct for an epoch.
28. `getConditionalAction(address user, uint256 actionId)`: View function. Returns the `ConditionalAction` struct for a user's scheduled action.

**(Note:** The "raw essence parameters" in `UserData` would store factors like `deposit_duration_factor`, `refine_count_factor`, etc., which are then combined with `epochData.essenceMultiplier` in `getCurrentUserEssence` to get the current value. The specific calculation logic for essence and dynamic fees is simplified for demonstration but can be made arbitrarily complex.)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Contract Outline and Function Summary ---
// Contract Name: EtherealEssenceVault
//
// Core Concepts:
// 1. Epochs: Time-based periods influencing vault parameters.
// 2. Essence State: Dynamic, user-specific value derived from deposit duration, actions, epoch params.
// 3. Refining: User action to influence Essence State.
// 4. Crystallization: Checkpointing/locking current Essence State.
// 5. Delegated Actions: Users can delegate specific actions (Refining).
// 6. Conditional Execution: Schedule actions to execute later if on-chain conditions are met (requires external trigger).
// 7. Flash Crystallize: Special action for immediate Crystallization at higher cost.
// 8. Dynamic Fees: Fees vary based on state, user, epoch.
//
// Structs:
// - EpochData: Parameters for an epoch.
// - UserData: User-specific vault state.
// - ConditionalAction: Parameters for a scheduled action.
//
// State Variables: Owner, Treasury, Essence Token, Paused State, Epoch Data, User Data, Totals, Conditional Actions, Counter.
//
// Enums:
// - ConditionalActionType: Defines types of scheduled actions.
//
// Events: Log key actions like deposit, withdrawal, refine, crystallize, delegation, epoch changes, conditional actions, pausing, ownership.
//
// Functions (>20, detailed summary above the code block):
// 1. constructor
// 2. deposit
// 3. withdraw
// 4. emergencyWithdraw
// 5. getCurrentUserEssence (view)
// 6. refineEssence
// 7. crystallizeEssence
// 8. flashCrystallize
// 9. delegateRefiner
// 10. revokeDelegation
// 11. executeDelegatedRefine
// 12. scheduleConditionalAction
// 13. cancelConditionalAction
// 14. executeScheduledAction
// 15. checkConditionalActionEligibility (view)
// 16. startNewEpoch
// 17. setEpochParameters
// 18. pause
// 19. unpause
// 20. transferOwnership
// 21. setGovernanceTreasury
// 22. getWithdrawalFee (view)
// 23. getRefineFee (view)
// 24. getCrystallizeFee (view)
// 25. getFlashCrystallizeFee (view)
// 26. getUserData (view)
// 27. getEpochData (view)
// 28. getConditionalAction (view)
// --- End Outline ---

contract EtherealEssenceVault is Ownable, ReentrancyGuard, Pausable {

    // --- Structs ---

    struct EpochData {
        uint256 startTime;
        uint256 essenceMultiplier; // Base multiplier for essence calculation (e.g., 1000 for 1x)
        uint256 baseWithdrawalFeeBps; // Base withdrawal fee in basis points (100 = 1%)
        uint256 baseRefineFeeBps;
        uint256 baseCrystallizeFeeBps;
        uint256 baseFlashCrystallizeFeeBps;
    }

    struct UserData {
        uint256 depositAmount;
        uint256 lastDepositTime; // Timestamp of the most recent deposit or partial withdrawal
        uint256 lastRefineTime;  // Timestamp of the last refine action
        uint256 refineCount;     // Number of times refine has been called

        // Raw essence parameters before applying multipliers - simplified example
        // In a real contract, this might track duration factor, action factor, etc.
        // Here, we'll use 'rawAccumulatedEssence' as a base rate accumulator.
        uint256 rawAccumulatedEssence;

        uint256 crystallizedEssence; // Essence checkpointed by the user

        address delegatedRefiner; // Address allowed to call refineEssence on behalf of the user
    }

    enum ConditionalActionType {
        Withdraw,
        Refine,
        Crystallize
        // Can add more action types here
    }

    struct ConditionalAction {
        ConditionalActionType actionType;
        uint256 executionTimestamp;     // Minimum timestamp for execution
        uint256 minEssenceRequirement;  // Minimum current essence required to execute
        uint256 actionParam;            // Parameter for the action (e.g., amount for withdraw)
        bool active;                    // Is this action still active?
    }

    // --- State Variables ---

    IERC20 public immutable essenceToken;
    address public governanceTreasury;

    uint256 public currentEpochIndex;
    mapping(uint256 => EpochData) public epochs;

    mapping(address => UserData) public users;

    uint256 public totalDeposited;
    uint256 public totalCrystallizedEssence;

    mapping(address => mapping(uint256 => ConditionalAction)) private userConditionalActions;
    mapping(address => uint256) private conditionalActionCounter; // Counter for unique action IDs per user

    uint256 private constant BASIS_POINTS_DIVISOR = 10000; // For BPS calculations

    // --- Events ---

    event Deposited(address indexed user, uint256 amount, uint256 newTotalDeposit);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee, uint256 newTotalDeposit);
    event EssenceRefined(address indexed user, uint256 refineCount, uint256 fee);
    event EssenceCrystallized(address indexed user, uint256 crystallizedAmount, uint256 fee, uint256 totalCrystallized);
    event FlashCrystallized(address indexed user, uint256 crystallizedAmount, uint256 fee, uint256 totalCrystallized);
    event DelegationUpdated(address indexed delegator, address indexed delegatee);
    event NewEpochStarted(uint256 indexed epochIndex, uint256 startTime, uint256 essenceMultiplier);
    event EpochParametersUpdated(uint256 indexed epochIndex, uint256 essenceMultiplier, uint256 baseWithdrawalFeeBps, uint256 baseRefineFeeBps, uint256 baseCrystallizeFeeBps, uint256 baseFlashCrystallizeFeeBps);
    event ConditionalActionScheduled(address indexed user, uint256 actionId, ConditionalActionType actionType, uint256 executionTimestamp, uint256 minEssenceRequirement, uint256 actionParam);
    event ConditionalActionCancelled(address indexed user, uint256 actionId);
    event ConditionalActionExecuted(address indexed user, uint256 actionId, ConditionalActionType actionType, uint256 feePaidByKeeper);
    event FeesCollected(address indexed treasury, uint256 amount);
    event GasBountyClaimed(address indexed keeper, uint256 bountyAmount);

    // --- Constructor ---

    constructor(address _essenceToken, address _governanceTreasury) Ownable(msg.sender) {
        essenceToken = IERC20(_essenceToken);
        governanceTreasury = _governanceTreasury;

        // Start epoch 0 immediately with initial parameters
        epochs[0] = EpochData({
            startTime: block.timestamp,
            essenceMultiplier: 1000, // Example: 1x multiplier
            baseWithdrawalFeeBps: 100, // Example: 1%
            baseRefineFeeBps: 50,      // Example: 0.5%
            baseCrystallizeFeeBps: 200, // Example: 2%
            baseFlashCrystallizeFeeBps: 500 // Example: 5%
        });
        currentEpochIndex = 0;
        emit NewEpochStarted(0, block.timestamp, epochs[0].essenceMultiplier);
    }

    // --- Access Control & Pausing ---

    function pause() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function setGovernanceTreasury(address _newTreasury) public onlyOwner {
        governanceTreasury = _newTreasury;
    }

    // --- Core Vault Operations ---

    /// @notice Deposits essence tokens into the vault.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Deposit amount must be > 0");

        UserData storage user = users[msg.sender];

        // Transfer tokens from user to contract
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Update user data. Note: lastDepositTime is key for essence calculation.
        // If user already has a deposit, their lastDepositTime remains the original
        // deposit time, reflecting continuous duration. If it's the first deposit,
        // or if a withdrawal cleared the deposit, set it now.
        if (user.depositAmount == 0) {
             user.lastDepositTime = block.timestamp;
        }
        user.depositAmount += amount;

        totalDeposited += amount;

        emit Deposited(msg.sender, amount, user.depositAmount);
    }

    /// @notice Calculates the dynamic withdrawal fee for a user and amount.
    /// @param user The address of the user.
    /// @param amount The amount being considered for withdrawal.
    /// @return The calculated fee amount in tokens.
    function getWithdrawalFee(address user, uint256 amount) public view returns (uint256) {
        UserData storage userData = users[user];
        require(userData.depositAmount >= amount, "Amount exceeds deposit");

        EpochData storage currentEpoch = epochs[currentEpochIndex];

        // Example Dynamic Fee Logic: Base fee reduced by higher crystallized essence
        // (Simplified: 1% base fee, reduced by up to 0.5% based on crystallized essence ratio)
        uint264 baseFeeBps = uint256(currentEpoch.baseWithdrawalFeeBps);
        uint256 maxReductionBps = baseFeeBps / 2; // Max 50% reduction based on base fee

        uint256 essenceRatioBps = 0;
        if (totalCrystallizedEssence > 0) {
            // This ratio is a placeholder. Real logic might be more complex.
            // Example: user's crystallized essence vs total crystallized essence,
            // or user's crystallized essence vs their deposit size.
            // Let's use a simple example: user's crystallized essence mapped to a 0-10000 range.
            essenceRatioBps = userData.crystallizedEssence > 10000 ? 10000 : userData.crystallizedEssence; // Cap at 100% 'full' essence state for reduction

        }

        uint256 feeReductionBps = (maxReductionBps * essenceRatioBps) / 10000; // Apply reduction based on ratio
        uint256 finalFeeBps = baseFeeBps > feeReductionBps ? baseFeeBps - feeReductionBps : 0;

        return (amount * finalFeeBps) / BASIS_POINTS_DIVISOR;
    }


    /// @notice Allows a user to withdraw tokens from the vault. Subject to dynamic fees.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(uint256 amount) public nonReentrant whenNotPaused {
        UserData storage user = users[msg.sender];
        require(user.depositAmount >= amount, "Insufficient deposit");
        require(amount > 0, "Withdrawal amount must be > 0");

        uint256 fee = getWithdrawalFee(msg.sender, amount);
        uint265 amountToWithdraw = amount - fee;

        // Update user data
        user.depositAmount -= amount;
        totalDeposited -= amount;

        // If the deposit is now zero, reset lastDepositTime (or keep it for history, depending on design)
        // Let's reset it here to signify the "deposit state" is gone.
        if (user.depositAmount == 0) {
            user.lastDepositTime = 0; // Or block.timestamp if you want "last interaction time"
        }

        // Transfer tokens
        if (fee > 0) {
             require(essenceToken.transfer(governanceTreasury, fee), "Fee transfer failed");
             emit FeesCollected(governanceTreasury, fee);
        }
        require(essenceToken.transfer(msg.sender, amountToWithdraw), "Withdrawal transfer failed");

        emit Withdrawn(msg.sender, amount, fee, user.depositAmount);
    }

    /// @notice Allows the owner to withdraw tokens in case of emergency. Skips dynamic fees.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(uint256 amount) public onlyOwner nonReentrant {
        require(totalDeposited >= amount, "Insufficient total deposited in vault");
        require(amount > 0, "Emergency withdrawal amount must be > 0");

        // Note: This function doesn't track user specific emergency withdrawals easily.
        // A more complex emergency system might track user balances separately or drain proportionally.
        // For this example, it's a simple pool drain by owner.

        totalDeposited -= amount;

        // Transfer tokens
        require(essenceToken.transfer(msg.sender, amount), "Emergency withdrawal transfer failed");

        // No event defined for this, keep it minimal
    }


    // --- Essence & Refining ---

    /// @notice Calculates the current *simulated* essence for a user. Does not change state.
    /// Essence accrual is simplified: based on deposit duration, refine count, and epoch multiplier.
    /// @param user The address of the user.
    /// @return The calculated current essence value.
    function getCurrentUserEssence(address user) public view returns (uint256) {
        UserData storage userData = users[user];
        EpochData storage currentEpoch = epochs[currentEpochIndex];

        if (userData.depositAmount == 0 || userData.lastDepositTime == 0) {
            return 0;
        }

        // Simplified Essence Logic:
        // Base essence = (Deposit Duration) + (Refine Count * Refine Bonus)
        // Current Essence = Base Essence * Epoch Multiplier
        // Duration is measured from lastDepositTime.
        // Refine bonus could be time-decayed or fixed per refine. Let's make it simple: fixed bonus per refine.
        // rawAccumulatedEssence accumulates base rate over time + refine bonuses

        uint256 duration = block.timestamp - userData.lastDepositTime;
        uint256 baseEssenceFromDuration = duration; // 1 unit of essence per second of deposit duration

        // Add any accumulated raw essence from previous states/actions not yet crystallized
        uint256 currentRawEssence = userData.rawAccumulatedEssence + baseEssenceFromDuration;

        // Apply Epoch Multiplier (essenceMultiplier / 1000)
        // Using fixed point or integer math: result = (value * multiplier) / divisor
        uint256 finalEssence = (currentRawEssence * currentEpoch.essenceMultiplier) / 1000;

        return finalEssence;
    }

    /// @notice Calculates the dynamic fee for refining essence.
    /// @param user The address of the user.
    /// @return The calculated fee amount in tokens.
    function getRefineFee(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         EpochData storage currentEpoch = epochs[currentEpochIndex];

        // Example Dynamic Fee Logic: Base fee increased by higher refine count (diminishing returns)
        // (Simplified: 0.5% base fee, increases slightly with each refine)
         uint256 baseFeeBps = currentEpoch.baseRefineFeeBps;
         uint256 refinePenaltyBps = userData.refineCount > 0 ? 10 * (userData.refineCount > 10 ? 10 : userData.refineCount) : 0; // 10bps penalty per refine, max 100bps

         uint256 finalFeeBps = baseFeeBps + refinePenaltyBps;

         // Fee is calculated on the user's deposit amount for simplicity
         return (userData.depositAmount * finalFeeBps) / BASIS_POINTS_DIVISOR;
    }

    /// @notice User action to refine their essence state. Costs a dynamic fee and updates state.
    function refineEssence() public nonReentrant whenNotPaused {
        UserData storage user = users[msg.sender];
        require(user.depositAmount > 0, "No active deposit to refine");
        require(block.timestamp >= user.lastRefineTime + 1 days, "Refine cooldown active"); // Example cooldown

        uint264 fee = getRefineFee(msg.sender);
        require(essenceToken.transferFrom(msg.sender, governanceTreasury, fee), "Refine fee transfer failed");
        emit FeesCollected(governanceTreasury, fee);

        // Update user state: Increment refine count, update last refine time,
        // add a bonus to rawAccumulatedEssence (as part of the refine action benefit)
        user.refineCount++;
        user.lastRefineTime = block.timestamp;
        // Example bonus: Add 1000 raw essence per refine
        user.rawAccumulatedEssence += 1000; // This raw essence persists until crystallized

        emit EssenceRefined(msg.sender, user.refineCount, fee);
    }


    /// @notice Calculates the dynamic fee for crystallizing essence.
    /// @param user The address of the user.
    /// @return The calculated fee amount in tokens.
    function getCrystallizeFee(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         EpochData storage currentEpoch = epochs[currentEpochIndex];

         // Example Dynamic Fee Logic: Base fee slightly reduced by higher current essence
         uint256 baseFeeBps = currentEpoch.baseCrystallizeFeeBps;
         uint256 currentEssence = getCurrentUserEssence(user);

         // Reduction based on current essence level (simplified: up to 50% reduction if essence is high)
         uint256 maxReductionBps = baseFeeBps / 2;
         uint256 essenceValueForReduction = currentEssence > 20000 ? 20000 : currentEssence; // Map essence value to 0-20000 range
         uint256 feeReductionBps = (maxReductionBps * essenceValueForReduction) / 20000;

         uint256 finalFeeBps = baseFeeBps > feeReductionBps ? baseFeeBps - feeReductionBps : 0;

         // Fee is calculated on the user's deposit amount for simplicity
         return (userData.depositAmount * finalFeeBps) / BASIS_POINTS_DIVISOR;
    }

    /// @notice Allows a user to crystallize their current accrued essence state.
    /// This locks the current essence and resets the raw accumulation factors.
    function crystallizeEssence() public nonReentrant whenNotPaused {
         UserData storage user = users[msg.sender];
         require(user.depositAmount > 0, "No active deposit to crystallize");
         // Optional: Add a cooldown requirement or minimum duration since last deposit/refine

         uint264 fee = getCrystallizeFee(msg.sender);
         require(essenceToken.transferFrom(msg.sender, governanceTreasury, fee), "Crystallize fee transfer failed");
         emit FeesCollected(governanceTreasury, fee);

         // Calculate the essence being crystallized (based on raw accumulated + duration since last checkpoint)
         uint256 essenceToCrystallizeRaw = user.rawAccumulatedEssence + (block.timestamp - user.lastDepositTime); // Add duration since last check/deposit

         // Apply epoch multiplier to get final essence value
         uint256 essenceValue = (essenceToCrystallizeRaw * epochs[currentEpochIndex].essenceMultiplier) / 1000;

         // Update user and total state
         user.crystallizedEssence += essenceValue;
         totalCrystallizedEssence += essenceValue;

         // Reset raw accumulation factors after crystallization
         user.rawAccumulatedEssence = 0;
         user.lastDepositTime = block.timestamp; // Treat crystallization like a checkpoint for duration

         emit EssenceCrystallized(msg.sender, essenceValue, fee, user.crystallizedEssence);
    }

    /// @notice Calculates the dynamic fee for flash crystallizing essence.
    /// @param user The address of the user.
    /// @return The calculated fee amount in tokens.
     function getFlashCrystallizeFee(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         EpochData storage currentEpoch = epochs[currentEpochIndex];

         // Example Dynamic Fee Logic: Significantly higher base fee, maybe less affected by state
         uint256 baseFeeBps = currentEpoch.baseFlashCrystallizeFeeBps;

         // Maybe a small reduction based on essence, but less than regular crystallize
         uint256 currentEssence = getCurrentUserEssence(user);
         uint256 maxReductionBps = baseFeeBps / 10; // Max 10% reduction
         uint224 essenceValueForReduction = currentEssence > 10000 ? 10000 : currentEssence;
         uint256 feeReductionBps = (maxReductionBps * essenceValueForReduction) / 10000;

         uint256 finalFeeBps = baseFeeBps > feeReductionBps ? baseFeeBps - feeReductionBps : 0;

         // Fee calculated on the user's deposit amount
         return (userData.depositAmount * finalFeeBps) / BASIS_POINTS_DIVISOR;
    }

    /// @notice Allows a user to immediately crystallize their essence state,
    /// potentially skipping time-based cooldowns, at a higher fee.
    function flashCrystallize() public nonReentrant whenNotPaused {
         UserData storage user = users[msg.sender];
         require(user.depositAmount > 0, "No active deposit to flash crystallize");

         // Calculate fee *before* requiring transfer to ensure balance check
         uint264 fee = getFlashCrystallizeFee(msg.sender);

         // User must approve/have enough balance for the fee immediately
         require(essenceToken.transferFrom(msg.sender, governanceTreasury, fee), "Flash Crystallize fee transfer failed");
         emit FeesCollected(governanceTreasury, fee);

         // Calculate and apply essence crystallization logic (same as crystallizeEssence)
         uint256 essenceToCrystallizeRaw = user.rawAccumulatedEssence + (block.timestamp - user.lastDepositTime);
         uint256 essenceValue = (essenceToCrystallizeRaw * epochs[currentEpochIndex].essenceMultiplier) / 1000;

         user.crystallizedEssence += essenceValue;
         totalCrystallizedEssence += essenceValue;
         user.rawAccumulatedEssence = 0;
         user.lastDepositTime = block.timestamp; // Reset duration measurement

         // Note: Flash Crystallize inherently bypasses the 'Refine cooldown active' check
         // if called after a recent refine, adding to its "flash" nature.

         emit FlashCrystallized(msg.sender, essenceValue, fee, user.crystallizedEssence);
    }


    // --- Delegation ---

    /// @notice Allows a user to delegate the permission to call `refineEssence` on their behalf.
    /// @param delegatee The address to delegate to. Address(0) revokes delegation.
    function delegateRefiner(address delegatee) public whenNotPaused {
        users[msg.sender].delegatedRefiner = delegatee;
        emit DelegationUpdated(msg.sender, delegatee);
    }

    /// @notice Revokes any existing refiner delegation for the caller.
    function revokeDelegation() public whenNotPaused {
        delegateRefiner(address(0)); // Delegate to zero address effectively revokes
    }

    /// @notice Allows a delegated address to call `refineEssence` on behalf of the delegator.
    /// @param delegator The address of the user who delegated permission.
    function executeDelegatedRefine(address delegator) public nonReentrant whenNotPaused {
        UserData storage user = users[delegator];
        require(user.delegatedRefiner == msg.sender, "Not the delegated refiner");

        // Check conditions for the *delegator*
        require(user.depositAmount > 0, "No active deposit for delegator");
        require(block.timestamp >= user.lastRefineTime + 1 days, "Delegator's refine cooldown active");

        // Calculate and require fee payment from the *delegator*
        // This requires the delegator to have approved this contract to spend *their* tokens
        uint264 fee = getRefineFee(delegator);
        require(essenceToken.transferFrom(delegator, governanceTreasury, fee), "Delegator's refine fee transfer failed");
        emit FeesCollected(governanceTreasury, fee);

        // Update delegator's state
        user.refineCount++;
        user.lastRefineTime = block.timestamp;
        user.rawAccumulatedEssence += 1000; // Add bonus to delegator's raw essence

        emit EssenceRefined(delegator, user.refineCount, fee);
    }


    // --- Conditional Execution ---

    /// @notice Schedules an action to be executed later based on conditions.
    /// @param actionType The type of action to schedule (e.g., Withdraw, Refine).
    /// @param executionTimestamp The minimum timestamp for execution.
    /// @param minEssenceRequirement The minimum essence required to execute.
    /// @param actionParam Parameter for the action (e.g., withdraw amount).
    /// @return actionId A unique ID for the scheduled action.
    function scheduleConditionalAction(
        ConditionalActionType actionType,
        uint256 executionTimestamp,
        uint256 minEssenceRequirement,
        uint256 actionParam
    ) public whenNotPaused returns (uint256) {
        require(executionTimestamp > block.timestamp, "Execution timestamp must be in the future");
        // Add more validation based on actionType and actionParam if needed

        uint256 actionId = conditionalActionCounter[msg.sender]++;
        userConditionalActions[msg.sender][actionId] = ConditionalAction({
            actionType: actionType,
            executionTimestamp: executionTimestamp,
            minEssenceRequirement: minEssenceRequirement,
            actionParam: actionParam,
            active: true
        });

        emit ConditionalActionScheduled(msg.sender, actionId, actionType, executionTimestamp, minEssenceRequirement, actionParam);
        return actionId;
    }

    /// @notice Cancels a previously scheduled conditional action.
    /// @param actionId The ID of the action to cancel.
    function cancelConditionalAction(uint256 actionId) public whenNotPaused {
        require(userConditionalActions[msg.sender][actionId].active, "Action not found or not active");
        userConditionalActions[msg.sender][actionId].active = false;
        emit ConditionalActionCancelled(msg.sender, actionId);
    }

    /// @notice Checks if a scheduled conditional action's conditions are met.
    /// @param user The address of the user who scheduled the action.
    /// @param actionId The ID of the scheduled action.
    /// @return bool True if conditions are met, false otherwise.
    function checkConditionalActionEligibility(address user, uint256 actionId) public view returns (bool) {
        ConditionalAction storage action = userConditionalActions[user][actionId];
        if (!action.active) {
            return false;
        }
        if (block.timestamp < action.executionTimestamp) {
            return false;
        }
        if (getCurrentUserEssence(user) < action.minEssenceRequirement) {
            return false;
        }
        // Add other potential checks here (e.g., sufficient deposit amount for withdraw)
        if (action.actionType == ConditionalActionType.Withdraw) {
             if (users[user].depositAmount < action.actionParam) {
                 return false;
             }
        }
        // Add checks for Refine/Crystallize if they have specific requirements beyond essence/time
        // For now, the basic essence/time/active checks are sufficient examples.

        return true;
    }

    /// @notice Allows anyone (a keeper) to execute a scheduled action if its conditions are met.
    /// Provides a small gas bounty to the caller if successful.
    /// @param user The address of the user who scheduled the action.
    /// @param actionId The ID of the scheduled action.
    function executeScheduledAction(address user, uint256 actionId) public nonReentrant whenNotPaused {
        require(checkConditionalActionEligibility(user, actionId), "Conditions not met for execution");

        ConditionalAction storage action = userConditionalActions[user][actionId];
        action.active = false; // Deactivate immediately to prevent double execution

        uint264 feePaid; // Fee paid by the user for the underlying action

        // Execute the appropriate action based on type
        if (action.actionType == ConditionalActionType.Withdraw) {
             // Need to simulate the fee calculation for withdrawal
             require(users[user].depositAmount >= action.actionParam, "Insufficient deposit for scheduled withdraw");
             uint265 withdrawalAmount = action.actionParam;
             feePaid = getWithdrawalFee(user, withdrawalAmount);
             uint256 amountToTransfer = withdrawalAmount - feePaid;

             // Perform the withdrawal state updates and transfers from the contract
             users[user].depositAmount -= withdrawalAmount;
             totalDeposited -= withdrawalAmount;
             if (users[user].depositAmount == 0) { users[user].lastDepositTime = 0; } // Reset duration

             if (feePaid > 0) { require(essenceToken.transfer(governanceTreasury, feePaid), "Scheduled withdraw fee transfer failed"); }
             require(essenceToken.transfer(user, amountToTransfer), "Scheduled withdraw transfer failed");

             emit Withdrawn(user, withdrawalAmount, feePaid, users[user].depositAmount);


        } else if (action.actionType == ConditionalActionType.Refine) {
             // Perform refine action state updates and fee transfer
             // This needs to come from the user's approved balance, similar to delegated refine
             // OR the user must have transferred enough tokens to the contract beforehand for fees?
             // Let's assume user approves the contract to pull fees for scheduled actions.
             feePaid = getRefineFee(user);
             require(essenceToken.transferFrom(user, governanceTreasury, feePaid), "Scheduled refine fee transfer failed");
             emit FeesCollected(governanceTreasury, feePaid);

             users[user].refineCount++;
             users[user].lastRefineTime = block.timestamp;
             users[user].rawAccumulatedEssence += 1000; // Add bonus

             emit EssenceRefined(user, users[user].refineCount, feePaid);

        } else if (action.actionType == ConditionalActionType.Crystallize) {
            // Perform crystallize action state updates and fee transfer
            // Requires user approval for fee transfer
            feePaid = getCrystallizeFee(user);
            require(essenceToken.transferFrom(user, governanceTreasury, feePaid), "Scheduled crystallize fee transfer failed");
            emit FeesCollected(governanceTreasury, feePaid);

            uint256 essenceToCrystallizeRaw = users[user].rawAccumulatedEssence + (block.timestamp - users[user].lastDepositTime);
            uint256 essenceValue = (essenceToCrystallizeRaw * epochs[currentEpochIndex].essenceMultiplier) / 1000;

            users[user].crystallizedEssence += essenceValue;
            totalCrystallizedEssence += essenceValue;
            users[user].rawAccumulatedEssence = 0;
            users[user].lastDepositTime = block.timestamp;

            emit EssenceCrystallized(user, essenceValue, feePaid, users[user].crystallizedEssence);
        }
        // else if ... handle other action types

        emit ConditionalActionExecuted(user, actionId, action.actionType, feePaid); // feePaid is the fee for the *user's* action

        // Optional: Send a small gas bounty to the keeper (msg.sender)
        // This requires the contract to hold some ETH or other token, or be able to mint/transfer a specific reward.
        // For simplicity, let's assume a fixed tiny amount paid from a separate bounty pool if needed, or simply rely on transaction fee reimbursement via network mechanics.
        // Adding a simple ETH transfer as a placeholder bounty.
        // payable(msg.sender).transfer(0.0001 ether); // Example bounty - requires contract to be payable

        // If the contract can't hold ETH or you want a token bounty, you'd need separate logic/token.
        // Let's emit an event indicating a bounty opportunity rather than transferring ETH directly
        // without making the contract payable or tracking a bounty balance.
        // A keeper network would calculate their payment off-chain based on gas costs and potentially this event.
    }


    // --- Epoch Management (Owner Only) ---

    /// @notice Starts a new epoch with specified parameters. Can only be called once per epoch index.
    /// @param essenceMultiplier_ New essence multiplier (e.g., 1500 for 1.5x).
    /// @param baseWithdrawalFeeBps_ Base withdrawal fee in BPS for the new epoch.
    /// @param baseRefineFeeBps_ Base refine fee in BPS for the new epoch.
    /// @param baseCrystallizeFeeBps_ Base crystallize fee in BPS for the new epoch.
    /// @param baseFlashCrystallizeFeeBps_ Base flash crystallize fee in BPS for the new epoch.
    function startNewEpoch(
        uint256 essenceMultiplier_,
        uint256 baseWithdrawalFeeBps_,
        uint256 baseRefineFeeBps_,
        uint256 baseCrystallizeFeeBps_,
        uint256 baseFlashCrystallizeFeeBps_
    ) public onlyOwner {
        uint256 nextEpochIndex = currentEpochIndex + 1;
        require(epochs[nextEpochIndex].startTime == 0, "Epoch already exists"); // Prevent overwriting

        epochs[nextEpochIndex] = EpochData({
            startTime: block.timestamp,
            essenceMultiplier: essenceMultiplier_,
            baseWithdrawalFeeBps: baseWithdrawalFeeBps_,
            baseRefineFeeBps: baseRefineFeeBps_,
            baseCrystallizeFeeBps: baseCrystallizeFeeBps_,
            baseFlashCrystallizeFeeBps: baseFlashCrystallizeFeeBps_
        });

        currentEpochIndex = nextEpochIndex;
        emit NewEpochStarted(currentEpochIndex, block.timestamp, essenceMultiplier_);
    }

    /// @notice Updates parameters for a specific epoch. Can update current or future epochs.
    /// Use with caution for the current epoch as it affects live calculations.
    /// @param epochIndex The index of the epoch to update.
    /// @param essenceMultiplier_ New essence multiplier.
    /// @param baseWithdrawalFeeBps_ New base withdrawal fee in BPS.
    /// @param baseRefineFeeBps_ New base refine fee in BPS.
    /// @param baseCrystallizeFeeBps_ New base crystallize fee in BPS.
    /// @param baseFlashCrystallizeFeeBps_ New base flash crystallize fee in BPS.
    function setEpochParameters(
        uint256 epochIndex,
        uint256 essenceMultiplier_,
        uint256 baseWithdrawalFeeBps_,
        uint256 baseRefineFeeBps_,
        uint256 baseCrystallizeFeeBps_,
        uint256 baseFlashCrystallizeFeeBps_
    ) public onlyOwner {
        require(epochs[epochIndex].startTime > 0, "Epoch does not exist"); // Ensure epoch was started

        EpochData storage epoch = epochs[epochIndex];
        epoch.essenceMultiplier = essenceMultiplier_;
        epoch.baseWithdrawalFeeBps = baseWithdrawalFeeBps_;
        epoch.baseRefineFeeBps = baseRefineFeeBps_;
        epoch.baseCrystallizeFeeBps = baseCrystallizeFeeBps_;
        epoch.baseFlashCrystallizeFeeBps = baseFlashCrystallizeFeeBps_;

        emit EpochParametersUpdated(
            epochIndex,
            essenceMultiplier_,
            baseWithdrawalFeeBps_,
            baseRefineFeeBps_,
            baseCrystallizeFeeBps_,
            baseFlashCrystallizeFeeBps_
        );
    }


    // --- View Functions ---

    /// @notice Gets all user data for a specific user.
    /// @param user The address of the user.
    /// @return UserData struct.
    function getUserData(address user) public view returns (UserData storage) {
        return users[user];
    }

    /// @notice Gets epoch data for a specific index.
    /// @param epochIndex The index of the epoch.
    /// @return EpochData struct.
    function getEpochData(uint256 epochIndex) public view returns (EpochData storage) {
        return epochs[epochIndex];
    }

    /// @notice Gets a specific scheduled conditional action for a user.
    /// @param user The address of the user.
    /// @param actionId The ID of the action.
    /// @return ConditionalAction struct.
    function getConditionalAction(address user, uint256 actionId) public view returns (ConditionalAction storage) {
        return userConditionalActions[user][actionId];
    }

    /// @notice Returns the total deposited tokens in the vault.
    function getTotalDeposited() public view returns (uint256) {
        return totalDeposited;
    }

    /// @notice Returns the total crystallized essence across all users.
    function getTotalCrystallizedEssence() public view returns (uint256) {
        return totalCrystallizedEssence;
    }

     /// @notice Returns the current block timestamp.
     function getCurrentTime() public view returns (uint256) {
         return block.timestamp;
     }
}
```