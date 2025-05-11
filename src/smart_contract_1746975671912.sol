Okay, let's design a smart contract around the concept of "Time-Weighted Aura" which grants users different levels of access or benefits based on how much they lock and for how long, incorporating dynamic calculations, tiered access, and interaction with other tokens.

This contract, `TimeLockAura`, will allow users to lock an ERC20 token for a specific duration. The amount and duration of the lock will contribute to a user's "Aura Points". These Aura Points will map to different tiers, granting access to various simulated benefits or functions within the contract (or serving as a reputation score for external applications). It will also include mechanics like early withdrawal penalties (burning tokens and losing Aura), temporary Aura boosts via another token, and tunable parameters.

---

**Smart Contract Outline and Function Summary**

**Contract Name:** `TimeLockAura`

**Core Concept:** Users lock an ERC20 token to earn Time-Weighted Aura Points, unlocking tiered benefits.

**Advanced Concepts/Features:**
1.  **Time-Weighted Dynamic Aura:** Aura points are calculated dynamically based on the amount locked and the duration, with adjustable weights.
2.  **Tiered Access:** Functions are restricted based on a user's current Aura Point tier.
3.  **Early Withdrawal Penalty:** Withdrawing tokens before the unlock time results in a penalty (token burn) and significant Aura decay.
4.  **Temporary Aura Boost:** Users can spend another ERC20 token (`BoostToken`) for a temporary increase in Aura points.
5.  **Founders Aura:** The owner can grant initial Aura points bypassing the lock mechanism.
6.  **Tunable Parameters:** Owner can adjust Aura calculation weights and tier thresholds.
7.  **Non-Reentrant Guards:** Protect against re-entrancy attacks during token transfers.
8.  **Pausable:** Owner can pause key contract interactions.
9.  **ERC20 Integration:** Interacts with two different ERC20 tokens (`LockToken` and `BoostToken`).

**State Variables:**

*   `lockToken`: Address of the ERC20 token to be locked.
*   `boostToken`: Address of the ERC20 token used for temporary boosts.
*   `locks`: Mapping from user address to an array of their active locks (`Lock` struct).
*   `userAuraPoints`: Mapping from user address to their total current Aura points.
*   `auraTiers`: Mapping from tier level (uint8) to the minimum Aura points required for that tier.
*   `auraDurationWeight`: Parameter influencing Aura calculation (seconds per point).
*   `auraAmountWeight`: Parameter influencing Aura calculation (token units per point).
*   `earlyWithdrawalBurnPercentage`: Percentage of tokens burned on early withdrawal (basis points).
*   `tempAuraBoost`: Mapping from user address to their active temporary boost amount.
*   `tempAuraBoostEndTime`: Mapping from user address to the timestamp when their temporary boost ends.
*   `paused`: Boolean indicating if the contract is paused.
*   `TIER_NAMES`: Mapping from tier level (uint8) to a string name for the tier (e.g., "Bronze", "Silver").

**Structs:**

*   `Lock`: Represents a user's token lock.
    *   `amount`: Amount of `lockToken` locked.
    *   `unlockTime`: Timestamp when the lock expires.
    *   `initialLockDurationSeconds`: Original duration of the lock in seconds.
    *   `auraPointsAtCreation`: Aura points calculated at the time of locking.
    *   `active`: Boolean indicating if the lock is still considered active for Aura calculation/unlocking.

**Events:**

*   `LockCreated(address indexed user, uint256 index, uint256 amount, uint256 unlockTime, uint256 auraPoints)`: Logged when a new lock is created.
*   `LockExtended(address indexed user, uint256 index, uint256 newUnlockTime, uint256 additionalAuraPoints)`: Logged when a lock duration is extended.
*   `LockUnlocked(address indexed user, uint256 index)`: Logged when a lock matures.
*   `TokensClaimed(address indexed user, uint256 index, uint256 amount)`: Logged when unlocked tokens are claimed.
*   `EarlyWithdrawal(address indexed user, uint256 index, uint256 amountWithdrawn, uint256 burnedAmount, uint256 auraPointsLost)`: Logged on early withdrawal.
*   `AuraUpdated(address indexed user, uint256 newAuraPoints)`: Logged when a user's total Aura points change.
*   `AuraTierDefined(uint8 indexed tierLevel, uint256 minPoints)`: Logged when an Aura tier threshold is set.
*   `AuraBoosted(address indexed user, uint256 boostAmount, uint256 durationInSeconds, uint256 endsAt)`: Logged when a temporary Aura boost is applied.
*   `FoundersAuraGranted(address indexed user, uint256 pointsGranted)`: Logged when Founder's Aura is granted.
*   `ParametersUpdated(uint256 durationWeight, uint256 amountWeight, uint256 burnPercentage)`: Logged when calculation parameters are changed.
*   `Paused()`: Logged when pausing.
*   `Unpaused()`: Logged when unpausing.
*   `BoostTokenSet(address indexed token)`: Logged when boost token address is set.
*   `LockTokenSet(address indexed token)`: Logged when lock token address is set.
*   `TierNameSet(uint8 indexed tierLevel, string name)`: Logged when a tier name is set.

**Function Summary (20+ functions):**

1.  `constructor(address _lockToken, address _boostToken)`: Initializes the contract with token addresses and default parameters.
2.  `lockTokens(uint256 amount, uint256 durationInDays)`: Allows a user to lock `amount` of `lockToken` for `durationInDays`. Requires prior approval of `lockToken`. Calculates and assigns initial Aura.
3.  `extendLockDuration(uint256 lockIndex, uint256 additionalDays)`: Allows a user to extend an existing lock's duration. Recalculates potential Aura from the extended period.
4.  `unlockTokens(uint256 lockIndex)`: Marks a lock as inactive *if* the unlock time has passed. Does not transfer tokens.
5.  `claimUnlockedTokens(uint256 lockIndex)`: Transfers the locked amount to the user *if* the lock is inactive (either naturally expired or marked via `unlockTokens`). Requires the lock to be marked inactive.
6.  `relockUnlockedAmount(uint256 lockIndex, uint256 additionalDays)`: Allows a user to re-lock the amount from an *inactive* (but unclaimed) lock for a new duration. Creates a new lock entry.
7.  `withdrawEarly(uint256 lockIndex)`: Allows early withdrawal. Burns a percentage of the amount and significantly reduces the user's Aura. Marks the lock inactive.
8.  `calculatePotentialAura(uint256 amount, uint256 durationInDays)`: Pure function to estimate the Aura points for a given amount and duration.
9.  `getCurrentAuraPoints(address user)`: View function to get the user's total current Aura points, including any active temporary boost.
10. `getAuraTier(address user)`: View function to get the user's current Aura tier level (uint8) based on their total points.
11. `getAuraTierName(uint8 tierLevel)`: View function to get the string name for a given tier level.
12. `getUserLockCount(address user)`: View function to get the number of locks a user has.
13. `getUserLockAtIndex(address user, uint256 index)`: View function to get details of a specific lock for a user by index.
14. `accessTierBenefitLevel1()`: Example function requiring minimum Aura tier (e.g., Bronze).
15. `accessTierBenefitLevel2()`: Example function requiring higher Aura tier (e.g., Silver).
16. `accessTierBenefitLevel3()`: Example function requiring even higher Aura tier (e.g., Gold).
17. `accessTierBenefitLevel4()`: Example function requiring highest Aura tier (e.g., Platinum).
18. `boostAuraTemporarily(uint256 boostAmount, uint256 durationInHours)`: Allows a user to spend `boostAmount` of `boostToken` for a temporary Aura increase lasting `durationInHours`. Requires prior approval of `boostToken`.
19. `grantFoundersAura(address user, uint256 points)`: (Owner only) Grants `points` as Founders Aura to a specific user.
20. `setLockToken(address _lockToken)`: (Owner only) Sets the address of the Lock Token.
21. `setBoostToken(address _boostToken)`: (Owner only) Sets the address of the Boost Token.
22. `setAuraCalculationParameters(uint256 _durationWeight, uint256 _amountWeight, uint256 _earlyWithdrawalBurnPercentage)`: (Owner only) Sets parameters for Aura calculation and early withdrawal penalty.
23. `defineAuraTier(uint8 tierLevel, uint256 minPoints, string memory name)`: (Owner only) Defines or updates the minimum points required for a specific Aura tier level and sets its name.
24. `pauseLocking()`: (Owner only) Pauses the `lockTokens` function.
25. `unpauseLocking()`: (Owner only) Unpauses the `lockTokens` function.
26. `withdrawOwnerTokens(address tokenAddress)`: (Owner only) Allows the owner to withdraw any tokens accidentally sent to the contract (except locked tokens).
27. `isPaused()`: View function to check the pause status.
28. `getAuraCalculationParameters()`: View function to see the current calculation parameters.
29. `getTierThreshold(uint8 tierLevel)`: View function to see the minimum points for a tier.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Note: For a real-world application, using a library or upgrading pattern
// for dynamic arrays in mappings would be considered for gas efficiency
// and complexity management (e.g., managing inactive locks).
// This example prioritizes demonstrating the concepts.

/**
 * @title TimeLockAura
 * @dev A smart contract for locking ERC20 tokens to earn time-weighted Aura points,
 * unlocking tiered benefits and featuring early withdrawal penalties and temporary boosts.
 */
contract TimeLockAura is Ownable, ReentrancyGuard, Context {

    // --- State Variables ---

    IERC20 public lockToken;
    IERC20 public boostToken;

    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        uint256 initialLockDurationSeconds; // Store original duration for potential formula use
        uint256 auraPointsAtCreation;
        bool active; // True if lock contributes to Aura and can be unlocked/claimed
    }

    // Mapping from user address to an array of their locks
    mapping(address => Lock[]) public locks;

    // Mapping from user address to their current calculated Aura points (excluding temp boost)
    mapping(address => uint256) private _userBaseAuraPoints;

    // Mapping from user address to their active temporary boost amount and end time
    mapping(address => uint256) public tempAuraBoost;
    mapping(address => uint256) public tempAuraBoostEndTime;

    // Mapping from tier level (e.g., 0 for Bronze, 1 for Silver) to minimum points
    mapping(uint8 => uint256) public auraTiers;
    // Mapping from tier level to a string name
    mapping(uint8 => string) public TIER_NAMES;


    // Parameters for Aura calculation: Aura = (amount * amountWeight + durationInSeconds * durationWeight) / SCALE_FACTOR
    // Using high numbers to avoid floating point issues with integer division
    uint256 public auraDurationWeight; // Points per second locked
    uint256 public auraAmountWeight;   // Points per token unit locked
    uint256 private constant AURA_SCALE_FACTOR = 1e18; // Scaling factor for Aura calculation

    // Percentage of tokens burned on early withdrawal (in basis points, e.g., 5000 for 50%)
    uint256 public earlyWithdrawalBurnPercentage;

    // Pause state
    bool public paused;

    // --- Events ---

    event LockCreated(address indexed user, uint256 index, uint256 amount, uint256 unlockTime, uint256 auraPoints);
    event LockExtended(address indexed user, uint256 index, uint256 newUnlockTime); // Added for clarity
    event LockUnlocked(address indexed user, uint256 index);
    event TokensClaimed(address indexed user, uint256 index, uint256 amount);
    event EarlyWithdrawal(address indexed user, uint256 index, uint256 amountWithdrawn, uint256 burnedAmount, uint256 auraPointsLost);
    event AuraUpdated(address indexed user, uint256 newAuraPoints);
    event AuraTierDefined(uint8 indexed tierLevel, uint256 minPoints);
    event AuraBoosted(address indexed user, uint256 boostAmount, uint256 durationInSeconds, uint256 endsAt);
    event FoundersAuraGranted(address indexed user, uint256 pointsGranted);
    event ParametersUpdated(uint256 durationWeight, uint256 amountWeight, uint256 burnPercentage);
    event Paused();
    event Unpaused();
    event BoostTokenSet(address indexed token);
    event LockTokenSet(address indexed token);
    event TierNameSet(uint8 indexed tierLevel, string name);


    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- Constructor ---

    constructor(address _lockToken, address _boostToken) Ownable(_msgSender()) {
        require(_lockToken != address(0), "Invalid lock token address");
        require(_boostToken != address(0), "Invalid boost token address");
        lockToken = IERC20(_lockToken);
        boostToken = IERC20(_boostToken);

        // Default parameters (can be changed by owner)
        auraDurationWeight = 1; // 1 point per second per 1e18 amount unit
        auraAmountWeight = AURA_SCALE_FACTOR; // 1 point per token unit per 1 second
        earlyWithdrawalBurnPercentage = 5000; // 50% burn

        // Define some default tiers (can be changed by owner)
        auraTiers[0] = 0;       // Base (everyone starts here)
        TIER_NAMES[0] = "Base";
        auraTiers[1] = 1000;    // Bronze
        TIER_NAMES[1] = "Bronze";
        auraTiers[2] = 10000;   // Silver
        TIER_NAMES[2] = "Silver";
        auraTiers[3] = 50000;   // Gold
        TIER_NAMES[3] = "Gold";
        auraTiers[4] = 200000;  // Platinum
        TIER_NAMES[4] = "Platinum";

        emit LockTokenSet(_lockToken);
        emit BoostTokenSet(_boostToken);
        emit ParametersUpdated(auraDurationWeight, auraAmountWeight, earlyWithdrawalBurnPercentage);
        emit AuraTierDefined(0, 0);
        emit AuraTierDefined(1, 1000);
        emit AuraTierDefined(2, 10000);
        emit AuraTierDefined(3, 50000);
        emit AuraTierDefined(4, 200000);
        emit TierNameSet(0, "Base");
        emit TierNameSet(1, "Bronze");
        emit TierNameSet(2, "Silver");
        emit TierNameSet(3, "Gold");
        emit TierNameSet(4, "Platinum");
    }

    // --- Core Lock Management Functions ---

    /**
     * @dev Locks tokens for a specified duration, creating a new lock and updating Aura.
     * @param amount The amount of lockToken to lock.
     * @param durationInDays The duration of the lock in days. Max 4 years (approx).
     */
    function lockTokens(uint256 amount, uint256 durationInDays) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(durationInDays > 0, "Duration must be greater than 0");
        uint256 durationInSeconds = durationInDays * 1 days; // Use 1 days constant (86400)
        require(durationInSeconds > 0 && block.timestamp + durationInSeconds > block.timestamp, "Invalid duration"); // Prevent overflow

        // Transfer tokens from user to contract
        lockToken.transferFrom(_msgSender(), address(this), amount);

        uint256 initialAura = _calculateAuraPoints(amount, durationInSeconds);

        locks[_msgSender()].push(
            Lock({
                amount: amount,
                unlockTime: block.timestamp + durationInSeconds,
                initialLockDurationSeconds: durationInSeconds,
                auraPointsAtCreation: initialAura,
                active: true
            })
        );

        uint256 newLockIndex = locks[_msgSender()].length - 1;
        _updateUserAura(_msgSender());

        emit LockCreated(_msgSender(), newLockIndex, amount, block.timestamp + durationInSeconds, initialAura);
    }

    /**
     * @dev Allows a user to extend the duration of an existing active lock.
     * @param lockIndex The index of the lock to extend.
     * @param additionalDays The number of additional days to extend the lock by.
     */
    function extendLockDuration(uint256 lockIndex, uint256 additionalDays) external nonReentrant whenNotPaused {
        require(locks[_msgSender()].length > lockIndex, "Invalid lock index");
        Lock storage userLock = locks[_msgSender()][lockIndex];
        require(userLock.active, "Lock is not active");
        require(additionalDays > 0, "Additional duration must be greater than 0");

        uint256 additionalSeconds = additionalDays * 1 days;
        uint256 newUnlockTime = userLock.unlockTime + additionalSeconds;
        require(newUnlockTime > userLock.unlockTime, "Invalid additional duration or overflow"); // Prevent overflow

        // The effect on Aura is implicit as the user keeps the lock active for longer.
        // We could calculate and add 'additionalAuraPoints' here if the formula
        // considered *current* duration, but our formula uses *initial* duration.
        // So, extending keeps the lock active, contributing its initial points for longer.
        // This design choice simplifies aura recalculation on extend.

        userLock.unlockTime = newUnlockTime;

        // No need to call _updateUserAura here as the initial points remain associated
        // with the lock until it becomes inactive.

        emit LockExtended(_msgSender(), lockIndex, newUnlockTime);
    }

    /**
     * @dev Marks a lock as inactive if its unlock time has passed.
     * This is a prerequisite for claiming tokens but doesn't transfer them.
     * @param lockIndex The index of the lock to unlock.
     */
    function unlockTokens(uint256 lockIndex) external nonReentrant {
        require(locks[_msgSender()].length > lockIndex, "Invalid lock index");
        Lock storage userLock = locks[_msgSender()][lockIndex];
        require(userLock.active, "Lock is not active");
        require(block.timestamp >= userLock.unlockTime, "Lock has not matured yet");

        userLock.active = false; // Mark as inactive
        _updateUserAura(_msgSender()); // Recalculate Aura as this lock is no longer active

        emit LockUnlocked(_msgSender(), lockIndex);
    }

    /**
     * @dev Claims the tokens from an inactive lock.
     * The lock must have expired naturally OR been withdrawn early.
     * @param lockIndex The index of the lock to claim from.
     */
    function claimUnlockedTokens(uint256 lockIndex) external nonReentrant {
        require(locks[_msgSender()].length > lockIndex, "Invalid lock index");
        Lock storage userLock = locks[_msgSender()][lockIndex];
        require(!userLock.active, "Lock is still active"); // Must be marked inactive
        require(userLock.amount > 0, "Lock already claimed or empty"); // Ensure not claimed previously

        uint256 amountToTransfer = userLock.amount;
        userLock.amount = 0; // Zero out amount to prevent double claiming

        lockToken.transfer(_msgSender(), amountToTransfer);

        emit TokensClaimed(_msgSender(), lockIndex, amountToTransfer);
    }

    /**
     * @dev Allows a user to re-lock the amount from an inactive (but unclaimed) lock.
     * Creates a new lock entry with the same amount but a new duration.
     * @param lockIndex The index of the inactive lock to re-lock from.
     * @param additionalDays The duration for the new lock in days.
     */
    function relockUnlockedAmount(uint256 lockIndex, uint256 additionalDays) external nonReentrant whenNotPaused {
         require(locks[_msgSender()].length > lockIndex, "Invalid lock index");
        Lock storage userLock = locks[_msgSender()][lockIndex];
        require(!userLock.active, "Lock is still active"); // Must be marked inactive
        require(userLock.amount > 0, "Lock already claimed or empty"); // Ensure not claimed previously
        require(additionalDays > 0, "New duration must be greater than 0");

        uint256 amountToRelock = userLock.amount;
        userLock.amount = 0; // Zero out amount from old lock

        uint256 newDurationSeconds = additionalDays * 1 days;
        require(newDurationSeconds > 0 && block.timestamp + newDurationSeconds > block.timestamp, "Invalid new duration"); // Prevent overflow

        uint256 initialAura = _calculateAuraPoints(amountToRelock, newDurationSeconds);

         locks[_msgSender()].push(
            Lock({
                amount: amountToRelock,
                unlockTime: block.timestamp + newDurationSeconds,
                initialLockDurationSeconds: newDurationSeconds,
                auraPointsAtCreation: initialAura,
                active: true
            })
        );

        uint256 newLockIndex = locks[_msgSender()].length - 1;
        _updateUserAura(_msgSender()); // Update aura based on the new active lock

        emit TokensClaimed(_msgSender(), lockIndex, amountToRelock); // Emit claim for the old lock
        emit LockCreated(_msgSender(), newLockIndex, amountToRelock, block.timestamp + newDurationSeconds, initialAura); // Emit creation for the new lock
    }


    /**
     * @dev Allows early withdrawal from an active lock. Applies a burn penalty and Aura decay.
     * @param lockIndex The index of the lock to withdraw early from.
     */
    function withdrawEarly(uint256 lockIndex) external nonReentrant {
        require(locks[_msgSender()].length > lockIndex, "Invalid lock index");
        Lock storage userLock = locks[_msgSender()][lockIndex];
        require(userLock.active, "Lock is not active");
        require(block.timestamp < userLock.unlockTime, "Lock has already matured");

        uint256 totalAmount = userLock.amount;
        uint256 burnedAmount = (totalAmount * earlyWithdrawalBurnPercentage) / 10000;
        uint256 amountToTransfer = totalAmount - burnedAmount;

        userLock.active = false; // Mark as inactive
        userLock.amount = 0; // Zero out amount to prevent claims

        // Significant Aura decay: remove points gained from this lock and potentially more
        // A simple decay mechanism: remove points gained from this lock plus some penalty
        // A more complex mechanism could scale penalty by time remaining.
        // For simplicity, let's remove the points this lock contributed, plus a fixed penalty
        // or just rely on the fact that it's no longer an active lock contributing points.
        // Let's simply remove the points this lock contributed from the base aura.
        // Note: The _updateUserAura call below will recalculate total based on remaining active locks.
        // The true "penalty" on Aura comes from it no longer contributing.

        // A harsh penalty could also be implemented here, e.g.:
        // _userBaseAuraPoints[_msgSender()] = _userBaseAuraPoints[_msgSender()] * 70 / 100; // Lose 30% of total aura

        // Let's just rely on _updateUserAura removing this lock's contribution.
        // Any *additional* penalty could be removing a percentage of the *remaining* aura.
        // Example additional penalty:
        // uint256 currentBaseAura = _userBaseAuraPoints[_msgSender()];
        // uint256 auraPenalty = currentBaseAura * 1000 / 10000; // 10% penalty on remaining aura
        // _userBaseAuraPoints[_msgSender()] = currentBaseAura >= auraPenalty ? currentBaseAura - auraPenalty : 0;
        // emit AuraUpdated(_msgSender(), getCurrentAuraPoints(_msgSender())); // Re-emit after additional penalty

        _updateUserAura(_msgSender()); // Recalculate Aura without the forfeited lock

        // Burn tokens by sending to address(0) or a designated burn address
        if (burnedAmount > 0) {
            lockToken.transfer(address(0), burnedAmount); // Burning tokens
        }

        if (amountToTransfer > 0) {
             lockToken.transfer(_msgSender(), amountToTransfer);
        }


        // We can't easily know how many points were "lost" from the total,
        // only the points *this lock contributed* at creation.
        // Let's just log the creation points as an indicator.
        emit EarlyWithdrawal(_msgSender(), lockIndex, totalAmount, burnedAmount, userLock.auraPointsAtCreation);
    }

    // --- Aura Calculation & Management Functions ---

    /**
     * @dev Calculates the potential Aura points for a given amount and duration.
     * @param amount The amount of lockToken.
     * @param durationInDays The duration in days.
     * @return The calculated potential Aura points.
     */
    function calculatePotentialAura(uint256 amount, uint256 durationInDays) public view returns (uint256) {
        if (amount == 0 || durationInDays == 0) {
            return 0;
        }
        uint256 durationInSeconds = durationInDays * 1 days;
        // Using large weights and scaling factor to maintain precision with integer arithmetic
        // Formula: (amount * amountWeight + durationInSeconds * durationWeight) / AURA_SCALE_FACTOR
        uint256 amountComponent = (amount * auraAmountWeight) / AURA_SCALE_FACTOR;
        uint256 durationComponent = (durationInSeconds * auraDurationWeight) / AURA_SCALE_FACTOR;

        // Avoid overflow if components are huge, though unlikely with reasonable weights/values
        uint256 totalAura = amountComponent + durationComponent;
        require(totalAura >= amountComponent && totalAura >= durationComponent, "Aura calculation overflow");

        return totalAura;
    }

     /**
     * @dev Internal function to recalculate a user's base Aura points based on all their active locks.
     * Should be called after any action that changes the status of a lock (creation, unlock, early withdrawal).
     * @param user The address of the user.
     */
    function _updateUserAura(address user) internal {
        uint256 totalActiveAura = 0;
        uint256 lockCount = locks[user].length;
        for (uint256 i = 0; i < lockCount; i++) {
            if (locks[user][i].active) {
                 // Active locks contribute their points calculated at creation time
                totalActiveAura += locks[user][i].auraPointsAtCreation;
                require(totalActiveAura >= locks[user][i].auraPointsAtCreation, "Aura total overflow"); // Check for overflow
            }
        }
        _userBaseAuraPoints[user] = totalActiveAura;
        emit AuraUpdated(user, getCurrentAuraPoints(user)); // Emit with final total including temp boost
    }

    /**
     * @dev Gets the user's total current Aura points, including any active temporary boost.
     * @param user The address of the user.
     * @return The user's total current Aura points.
     */
    function getCurrentAuraPoints(address user) public view returns (uint256) {
        uint256 baseAura = _userBaseAuraPoints[user];
        uint256 tempBoost = 0;
        if (block.timestamp < tempAuraBoostEndTime[user]) {
            tempBoost = tempAuraBoost[user];
        }
        uint256 totalAura = baseAura + tempBoost;
        // Basic check for overflow if base and boost are huge
        require(totalAura >= baseAura && totalAura >= tempBoost, "Total Aura overflow");
        return totalAura;
    }

    /**
     * @dev Gets the user's current Aura tier level.
     * @param user The address of the user.
     * @return The user's Aura tier level (uint8).
     */
    function getAuraTier(address user) public view returns (uint8) {
        uint256 currentAura = getCurrentAuraPoints(user);
        uint8 highestTier = 0; // Default to Base tier (0)
        // Iterate downwards from highest possible tier to find the highest tier reached
        // Assuming tiers are defined from 0 upwards. Max uint8 is 255, but typically few tiers are used.
        // Iterate through defined tiers using a map or array of levels if many tiers.
        // For simplicity, assuming tiers 0 to 4 are defined.
        for (uint8 i = 4; i > 0; i--) {
            if (auraTiers[i] > 0 && currentAura >= auraTiers[i]) {
                 highestTier = i;
                 break; // Found the highest tier
            }
        }
         // Check tier 0 explicitly in case it wasn't hit by the loop (e.g. currentAura=0)
         if (currentAura >= auraTiers[0]) {
             // highestTier is already 0 if loop didn't find a higher tier
         } else {
             // Should not happen if tier 0 is always 0 points
             highestTier = 0;
         }

        return highestTier;
    }

     /**
     * @dev Gets the string name for a given tier level.
     * @param tierLevel The tier level (uint8).
     * @return The name of the tier.
     */
    function getAuraTierName(uint8 tierLevel) public view returns (string memory) {
        string memory name = TIER_NAMES[tierLevel];
        if (bytes(name).length == 0 && tierLevel != 0) {
            return "Unknown Tier";
        }
        return name;
    }


    // --- Tiered Access / Benefits (Simulated) ---

    /**
     * @dev Example function requiring a minimum Aura tier (e.g., Tier 1: Bronze).
     * @param user The address of the user accessing the benefit.
     */
    function accessTierBenefitLevel1(address user) public view {
        // Example: Requires Bronze tier (assuming Tier 1 is Bronze)
        require(getAuraTier(user) >= 1, "Requires at least Bronze tier");
        // Simulate granting a benefit, e.g., return a special value
        // return "Bronze Benefit Granted";
    }

     /**
     * @dev Example function requiring a higher Aura tier (e.g., Tier 2: Silver).
      * @param user The address of the user accessing the benefit.
     */
    function accessTierBenefitLevel2(address user) public view {
        // Example: Requires Silver tier (assuming Tier 2 is Silver)
        require(getAuraTier(user) >= 2, "Requires at least Silver tier");
         // Simulate granting a benefit
        // return "Silver Benefit Granted";
    }

     /**
     * @dev Example function requiring an even higher Aura tier (e.g., Tier 3: Gold).
      * @param user The address of the user accessing the benefit.
     */
     function accessTierBenefitLevel3(address user) public view {
        // Example: Requires Gold tier (assuming Tier 3 is Gold)
        require(getAuraTier(user) >= 3, "Requires at least Gold tier");
         // Simulate granting a benefit
        // return "Gold Benefit Granted";
    }

     /**
     * @dev Example function requiring the highest Aura tier (e.g., Tier 4: Platinum).
      * @param user The address of the user accessing the benefit.
     */
    function accessTierBenefitLevel4(address user) public view {
        // Example: Requires Platinum tier (assuming Tier 4 is Platinum)
        require(getAuraTier(user) >= 4, "Requires at least Platinum tier");
        // Simulate granting a benefit
        // return "Platinum Benefit Granted";
    }


    // --- Aura Boosting ---

    /**
     * @dev Allows a user to spend BoostTokens for a temporary increase in Aura points.
     * @param boostAmount The amount of Aura points to temporarily add.
     * @param durationInHours The duration of the boost in hours.
     */
    function boostAuraTemporarily(uint256 boostAmount, uint256 durationInHours) external nonReentrant whenNotPaused {
        require(boostAmount > 0, "Boost amount must be > 0");
        require(durationInHours > 0, "Duration must be > 0");
        uint256 durationInSeconds = durationInHours * 1 hours;
        require(durationInSeconds > 0 && block.timestamp + durationInSeconds > block.timestamp, "Invalid duration"); // Prevent overflow

        // Determine BoostToken cost - define a conversion rate or formula here
        // For simplicity, let's assume 1 BoostToken = 1 Aura point boost for 1 hour
        // Cost = boostAmount * durationInHours / CONVERSION_RATE
        // Or simpler: cost is a fixed amount of BoostToken per boost point hour.
        // Let's define cost per BoostPoint-second:
        uint256 BOOST_TOKEN_COST_PER_POINT_SECOND = 1; // 1 BoostToken unit per Aura Point per second
        uint256 cost = (boostAmount * durationInSeconds * BOOST_TOKEN_COST_PER_POINT_SECOND) / AURA_SCALE_FACTOR; // Scale cost similarly to aura

        require(cost > 0, "Calculated boost cost is zero"); // Ensure cost is not zero

        // Transfer BoostToken from user to contract
        boostToken.transferFrom(_msgSender(), address(this), cost);

        // Apply the temporary boost
        tempAuraBoost[_msgSender()] = boostAmount;
        tempAuraBoostEndTime[_msgSender()] = block.timestamp + durationInSeconds;

        emit AuraBoosted(_msgSender(), boostAmount, durationInSeconds, tempAuraBoostEndTime[_msgSender()]);
        emit AuraUpdated(_msgSender(), getCurrentAuraPoints(_msgSender())); // Emit total aura update
    }

    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Allows the owner to grant initial Aura points to a user, bypassing locking.
     * Intended for rewarding founders, early adopters, etc.
     * @param user The address of the user to grant points to.
     * @param points The amount of Aura points to grant.
     */
    function grantFoundersAura(address user, uint256 points) external onlyOwner {
        require(user != address(0), "Invalid address");
        require(points > 0, "Points must be greater than 0");

        // Add directly to base aura - this is permanent unless explicitly removed
        _userBaseAuraPoints[user] += points;
        require(_userBaseAuraPoints[user] >= points, "Founders aura grant overflow"); // Check for overflow

        emit FoundersAuraGranted(user, points);
        emit AuraUpdated(user, getCurrentAuraPoints(user)); // Emit total aura update
    }

     /**
     * @dev Allows the owner to set the address of the Lock Token.
     * Can only be set if the current address is zero (initial setup).
     * @param _lockToken The address of the ERC20 Lock Token.
     */
    function setLockToken(address _lockToken) external onlyOwner {
        require(address(lockToken) == address(0), "Lock token already set");
        require(_lockToken != address(0), "Invalid address");
        lockToken = IERC20(_lockToken);
        emit LockTokenSet(_lockToken);
    }

    /**
     * @dev Allows the owner to set the address of the Boost Token.
     * Can only be set if the current address is zero (initial setup).
     * @param _boostToken The address of the ERC20 Boost Token.
     */
    function setBoostToken(address _boostToken) external onlyOwner {
        require(address(boostToken) == address(0), "Boost token already set");
         require(_boostToken != address(0), "Invalid address");
        boostToken = IERC20(_boostToken);
        emit BoostTokenSet(_boostToken);
    }

    /**
     * @dev Allows the owner to set the parameters for Aura calculation and early withdrawal penalty.
     * @param _durationWeight New duration weight.
     * @param _amountWeight New amount weight.
     * @param _earlyWithdrawalBurnPercentage New burn percentage (basis points).
     */
    function setAuraCalculationParameters(uint256 _durationWeight, uint256 _amountWeight, uint256 _earlyWithdrawalBurnPercentage) external onlyOwner {
        // Add checks to ensure parameters are within reasonable bounds if necessary
        auraDurationWeight = _durationWeight;
        auraAmountWeight = _amountWeight;
        earlyWithdrawalBurnPercentage = _earlyWithdrawalBurnPercentage;
        emit ParametersUpdated(_durationWeight, _amountWeight, _earlyWithdrawalBurnPercentage);
    }

    /**
     * @dev Allows the owner to define or update the minimum points required for an Aura tier.
     * @param tierLevel The tier level (e.g., 0, 1, 2...).
     * @param minPoints The minimum Aura points required for this tier.
     * @param name The string name for this tier (e.g., "Bronze").
     */
    function defineAuraTier(uint8 tierLevel, uint256 minPoints, string memory name) external onlyOwner {
        require(bytes(name).length > 0, "Tier name cannot be empty");
        // Could add checks here to ensure tiers are defined in increasing order of points
        auraTiers[tierLevel] = minPoints;
        TIER_NAMES[tierLevel] = name; // Store the name
        emit AuraTierDefined(tierLevel, minPoints);
        emit TierNameSet(tierLevel, name);
    }

     /**
     * @dev Pauses new token locking.
     */
    function pauseLocking() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses token locking.
     */
    function unpauseLocking() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused();
    }

     /**
     * @dev Allows the owner to withdraw tokens sent to the contract by mistake.
     * Cannot be used to drain locked funds or BoostTokens.
     * @param tokenAddress The address of the token to withdraw.
     */
    function withdrawOwnerTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(lockToken), "Cannot withdraw lock token this way");
        require(tokenAddress != address(boostToken), "Cannot withdraw boost token this way");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }


    // --- View/Helper Functions ---

    /**
     * @dev Gets the number of locks for a specific user.
     * @param user The address of the user.
     * @return The number of locks.
     */
    function getUserLockCount(address user) public view returns (uint256) {
        return locks[user].length;
    }

    /**
     * @dev Gets the details of a specific lock for a user by index.
     * @param user The address of the user.
     * @param index The index of the lock.
     * @return The lock struct details.
     */
    function getUserLockAtIndex(address user, uint256 index) public view returns (Lock memory) {
        require(locks[user].length > index, "Invalid lock index");
        return locks[user][index];
    }

    /**
     * @dev Gets the minimum Aura points required for a given tier level.
     * @param tierLevel The tier level.
     * @return The minimum required points.
     */
    function getTierThreshold(uint8 tierLevel) public view returns (uint256) {
        return auraTiers[tierLevel];
    }

     /**
     * @dev Gets the current Aura calculation parameters.
     * @return durationWeight, amountWeight, earlyWithdrawalBurnPercentage.
     */
    function getAuraCalculationParameters() public view returns (uint256, uint256, uint256) {
        return (auraDurationWeight, auraAmountWeight, earlyWithdrawalBurnPercentage);
    }

    /**
     * @dev Checks if the contract is paused.
     * @return True if paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }

    // --- Private Helper Function for Aura Calculation ---
    // Note: _calculateAuraPoints is internal and called by lockTokens and relockUnlockedAmount
    // calculatePotentialAura is public view for estimation

}
```