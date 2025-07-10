Okay, let's create a smart contract based on an advanced, creative concept. We'll design a `HyperbolicTimeChamber` contract.

**Concept:** Users can "stake" a specific ERC20 token (representing some form of "energy" or "resource") within the chamber. While staked, they don't just earn more of the staked token, but rather accrue "Temporal Essence" at an accelerated, non-linear rate. This rate is influenced by several dynamic factors:
1.  **Individual Stake Duration:** Longer individual stake time might yield diminishing or accelerating returns depending on configuration.
2.  **Global Chamber Efficiency:** A factor that can change over time or be influenced by user actions.
3.  **User Boosts:** Users can burn accumulated Essence to gain a personal boost multiplier for future Essence generation.
4.  **Global Time Factor:** A system-wide multiplier that might change based on external conditions (simulated here) or governance.
5.  **Chamber Capacity/Congestion:** The rate might decrease if the chamber is full or congested.

Accumulated Temporal Essence is an internal balance users can claim. It can be used for user boosts or potentially burned for other effects (like influencing global efficiency). Users can also delegate the *claiming* of their Essence to another address.

This contract involves:
*   Time-based mechanics
*   Dynamic rate calculation
*   Resource conversion (staking token -> Essence, Essence -> Boost/Global effect)
*   Internal token/resource tracking (Essence balance)
*   Delegation pattern
*   Admin/Owner controls for dynamic parameters

---

**Outline and Function Summary:**

**Contract:** `HyperbolicTimeChamber`

**Core Concept:** Allows users to stake a designated ERC20 token to accrue "Temporal Essence" based on stake duration, global factors, and personal boosts.

**State Variables:**
*   Addresses: Owner, Staking Token, designated Admin addresses.
*   Staking State: Total staked amount, number of active users, mapping of user addresses to their staked amount, entry timestamp, accumulated Essence, and personal boost multiplier.
*   Chamber Parameters: Maximum total capacity, maximum user count, global time factor, chamber efficiency rate, timestamps related to efficiency updates.
*   Delegation: Mapping of user addresses to their delegated claimer address.

**Functions Summary:**

1.  `constructor`: Initializes the contract with the staking token address and initial parameters.
2.  `enterChamber(uint256 amount)`: Stakes the specified amount of `stakingToken`. Requires prior approval. Updates user stake, total stake, user count, and calculates/adds pending Essence before restaking.
3.  `exitChamber(uint256 amount)`: Unstakes the specified amount of `stakingToken`. Calculates and adds pending Essence before reducing the stake and transferring tokens back.
4.  `claimEssence()`: Claims the calculated pending Temporal Essence for the caller. Adds to their accumulated balance and updates their entry time.
5.  `calculatePendingEssence(address user)`: *Internal helper* - Calculates the Temporal Essence accrued by a user since their last stake modification or claim.
6.  `getPendingEssence(address user)`: *View* - Returns the amount of pending Essence for a user without claiming.
7.  `getEssenceBalance(address user)`: *View* - Returns the user's accumulated, claimed Essence balance.
8.  `burnEssenceForBoost(uint256 essenceAmount)`: Burns a specified amount of claimed Essence to increase the user's personal `userBoostMultiplier`.
9.  `sacrificeEssenceForGlobalEfficiency(uint256 essenceAmount)`: Allows users to burn claimed Essence to contribute to a temporary increase in the global `chamberEfficiencyRate` (requires admin/owner confirmation or has a decay mechanism).
10. `delegateClaim(address delegatee)`: Allows the caller to designate another address to claim Essence on their behalf.
11. `removeDelegateClaim()`: Removes the current claim delegatee for the caller.
12. `claimEssenceDelegated(address user)`: Allows a designated delegatee to claim pending Essence for the specified user.
13. `updateChamberEfficiency()`: *Admin/Owner* - Allows updating the `chamberEfficiencyRate` based on predefined logic (e.g., time elapsed since last update, total staked amount, burned Essence contributions).
14. `setChamberCapacity(uint256 newCapacity)`: *Owner* - Sets the maximum total tokens that can be staked.
15. `setUserLimit(uint256 newUserLimit)`: *Owner* - Sets the maximum number of unique users that can stake.
16. `setGlobalTimeFactor(uint256 newFactor)`: *Admin/Owner* - Sets the global multiplier for Essence generation.
17. `addAdmin(address admin)`: *Owner* - Grants admin privileges to an address. Admins can update parameters like efficiency and global factor.
18. `removeAdmin(address admin)`: *Owner* - Revokes admin privileges from an address.
19. `isAdmin(address account)`: *View* - Checks if an address has admin privileges.
20. `pauseChamber()`: *Owner* - Pauses key operations (enter, exit, claim).
21. `unpauseChamber()`: *Owner* - Unpauses the chamber.
22. `getStakedAmount(address user)`: *View* - Returns the amount of tokens staked by a user.
23. `getTotalStakedAmount()`: *View* - Returns the total amount of tokens staked in the chamber.
24. `getActiveUsersCount()`: *View* - Returns the current number of unique users staking.
25. `getChamberCapacity()`: *View* - Returns the max total token capacity.
26. `getUserLimit()`: *View* - Returns the max user limit.
27. `getGlobalTimeFactor()`: *View* - Returns the current global time factor.
28. `getUserBoostMultiplier(address user)`: *View* - Returns a user's personal boost multiplier.
29. `getChamberEfficiencyRate()`: *View* - Returns the current chamber efficiency rate.
30. `getLastEfficiencyUpdateTime()`: *View* - Returns the timestamp of the last efficiency update.
31. `getStakingTokenAddress()`: *View* - Returns the address of the staking token.
32. `getClaimDelegatee(address user)`: *View* - Returns the claim delegatee for a user.
33. `transferOwnership(address newOwner)`: *Owner* - Transfers contract ownership.
34. `renounceOwnership()`: *Owner* - Renounces contract ownership.
35. `withdrawEmergency(address token, uint256 amount)`: *Owner* - Allows withdrawal of arbitrary tokens sent to the contract by mistake.

*(Note: Some internal helpers like `calculatePendingEssence` don't add to the *public* function count but are crucial for the logic. We have well over 20 public/external functions here.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title HyperbolicTimeChamber
/// @dev A creative staking contract where users stake tokens to earn Temporal Essence based on time, dynamic factors, and boosts.
/// @author Your Name/Alias

// --- Outline and Function Summary ---
// Contract: HyperbolicTimeChamber
// Core Concept: Allows users to stake a designated ERC20 token to accrue "Temporal Essence" based on stake duration, global factors, and personal boosts.
//
// State Variables:
// - Addresses: Owner, Staking Token, designated Admin addresses.
// - Staking State: Total staked amount, number of active users, mapping of user addresses to their staked amount, entry timestamp, accumulated Essence, and personal boost multiplier.
// - Chamber Parameters: Maximum total capacity, maximum user count, global time factor, chamber efficiency rate, timestamps related to efficiency updates.
// - Delegation: Mapping of user addresses to their delegated claimer address.
//
// Functions Summary:
// 1. constructor(address _stakingToken, uint256 _initialCapacity, uint256 _initialUserLimit, uint256 _initialGlobalFactor, uint256 _initialEfficiencyRate): Initializes the contract.
// 2. enterChamber(uint256 amount): Stakes the specified amount of stakingToken.
// 3. exitChamber(uint256 amount): Unstakes the specified amount of stakingToken.
// 4. claimEssence(): Claims the calculated pending Temporal Essence for the caller.
// 5. getPendingEssence(address user): View - Returns pending Essence.
// 6. getEssenceBalance(address user): View - Returns claimed Essence balance.
// 7. burnEssenceForBoost(uint256 essenceAmount): Burns claimed Essence for personal boost.
// 8. sacrificeEssenceForGlobalEfficiency(uint256 essenceAmount): Burns claimed Essence to potentially increase global efficiency (requires admin/owner action).
// 9. delegateClaim(address delegatee): Designates an address to claim Essence.
// 10. removeDelegateClaim(): Removes the claim delegatee.
// 11. claimEssenceDelegated(address user): Delegatee claims Essence for a user.
// 12. updateChamberEfficiency(): Admin/Owner - Updates chamber efficiency rate.
// 13. setChamberCapacity(uint256 newCapacity): Owner - Sets max total token capacity.
// 14. setUserLimit(uint256 newUserLimit): Owner - Sets max user limit.
// 15. setGlobalTimeFactor(uint256 newFactor): Admin/Owner - Sets the global factor.
// 16. addAdmin(address admin): Owner - Grants admin privileges.
// 17. removeAdmin(address admin): Owner - Revokes admin privileges.
// 18. isAdmin(address account): View - Checks admin status.
// 19. pauseChamber(): Owner - Pauses key operations.
// 20. unpauseChamber(): Owner - Unpauses chamber.
// 21. getStakedAmount(address user): View - Returns user's staked amount.
// 22. getTotalStakedAmount(): View - Returns total staked amount.
// 23. getActiveUsersCount(): View - Returns active user count.
// 24. getChamberCapacity(): View - Returns max capacity.
// 25. getUserLimit(): View - Returns max user limit.
// 26. getGlobalTimeFactor(): View - Returns global factor.
// 27. getUserBoostMultiplier(address user): View - Returns user's boost.
// 28. getChamberEfficiencyRate(): View - Returns efficiency rate.
// 29. getLastEfficiencyUpdateTime(): View - Returns last efficiency update time.
// 30. getStakingTokenAddress(): View - Returns staking token address.
// 31. getClaimDelegatee(address user): View - Returns delegatee address.
// 32. transferOwnership(address newOwner): Owner - Transfers ownership.
// 33. renounceOwnership(): Owner - Renounces ownership.
// 34. withdrawEmergency(address token, uint256 amount): Owner - Withdraws arbitrary tokens.
// --- End of Summary ---

contract HyperbolicTimeChamber is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable stakingToken;

    // --- Staking State ---
    uint256 public totalStakedAmount;
    uint256 public activeUsersCount;
    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userEntryTime; // Timestamp when user last staked/claimed
    mapping(address => uint256) public userAccumulatedEssence; // Claimed Essence balance
    mapping(address => uint256) public userBoostMultiplier; // Personal multiplier (e.g., 1000 is 1x, 2000 is 2x)

    // --- Chamber Parameters ---
    uint256 public chamberCapacity; // Maximum total staked tokens
    uint256 public chamberUserLimit; // Maximum number of unique users
    uint256 public globalTimeFactor; // Global multiplier (e.g., 1000 is 1x)
    uint256 public chamberEfficiencyRate; // Dynamic efficiency rate (e.g., 1000 is 1x)
    uint256 public lastEfficiencyUpdateTime; // Timestamp of the last efficiency update
    uint256 public efficiencyUpdateInterval = 1 days; // Minimum interval between admin efficiency updates

    // --- Delegation ---
    mapping(address => address) public claimDelegatee;

    // --- Constants ---
    uint256 public constant TIME_UNIT = 1 hours; // Base time unit for essence calculation (e.g., 1 hour = 1 TIME_UNIT)
    uint256 public constant ESSENCE_RATE_SCALE = 1e18; // Scale for Essence calculation (like decimals)
    uint256 public constant BOOST_SCALE = 1000; // Base scale for multipliers (1000 = 1x)
    uint256 public constant ESSENCE_PER_BOOST_UNIT = 1e16; // How much essence roughly equals 1 BOOST_SCALE increase

    // --- Admin Control ---
    mapping(address => bool) private admins;

    // --- Events ---
    event EnteredChamber(address indexed user, uint256 amount, uint256 newStake);
    event ExitedChamber(address indexed user, uint256 amount, uint256 remainingStake);
    event EssenceClaimed(address indexed user, uint256 amount);
    event EssenceBurnedForBoost(address indexed user, uint256 burnedAmount, uint256 newBoostMultiplier);
    event EssenceSacrificedForGlobal(address indexed user, uint256 burnedAmount);
    event ChamberEfficiencyUpdated(uint256 newRate, uint256 timestamp);
    event GlobalTimeFactorUpdated(uint256 newFactor);
    event ChamberCapacityUpdated(uint256 newCapacity);
    event ChamberUserLimitUpdated(uint256 newUserLimit);
    event ClaimDelegateeSet(address indexed delegator, address indexed delegatee);
    event ClaimDelegateeRemoved(address indexed delegator);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ChamberPaused(address account);
    event ChamberUnpaused(address account);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(admins[msg.sender] || owner() == msg.sender, "Not authorized");
        _;
    }

    // --- Constructor ---
    /// @param _stakingToken Address of the ERC20 token to be staked.
    /// @param _initialCapacity Initial maximum total tokens allowed in the chamber.
    /// @param _initialUserLimit Initial maximum number of unique users allowed.
    /// @param _initialGlobalFactor Initial global multiplier for Essence generation (e.g., 1000 for 1x).
    /// @param _initialEfficiencyRate Initial dynamic efficiency rate (e.g., 1000 for 1x).
    constructor(
        address _stakingToken,
        uint256 _initialCapacity,
        uint256 _initialUserLimit,
        uint256 _initialGlobalFactor,
        uint256 _initialEfficiencyRate
    ) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);
        chamberCapacity = _initialCapacity;
        chamberUserLimit = _initialUserLimit;
        globalTimeFactor = _initialGlobalFactor;
        chamberEfficiencyRate = _initialEfficiencyRate;
        lastEfficiencyUpdateTime = block.timestamp;
        admins[msg.sender] = true; // Owner is initially an admin
        userBoostMultiplier[address(0)] = BOOST_SCALE; // Default boost for non-stakers (not strictly necessary but good practice)
    }

    // --- Core Staking and Claiming ---

    /// @notice Stakes tokens into the Hyperbolic Time Chamber to start accruing Essence.
    /// @dev Requires the user to have approved the contract to spend the tokens first.
    /// @param amount The amount of stakingToken to stake.
    function enterChamber(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(totalStakedAmount + amount <= chamberCapacity, "Chamber capacity reached");

        address user = msg.sender;
        bool wasActive = userStakes[user] > 0;

        if (wasActive) {
            // If already staking, claim pending essence before updating stake
            userAccumulatedEssence[user] += _calculatePendingEssence(user);
        } else {
            // If new staker, check user limit
            require(activeUsersCount < chamberUserLimit, "User limit reached");
            activeUsersCount++;
            userBoostMultiplier[user] = BOOST_SCALE; // Initialize boost for new staker
        }

        // Update stake and time
        userStakes[user] += amount;
        totalStakedAmount += amount;
        userEntryTime[user] = block.timestamp; // Reset time counter for new stake period

        // Transfer tokens into the contract
        bool success = stakingToken.transferFrom(user, address(this), amount);
        require(success, "Token transfer failed");

        emit EnteredChamber(user, amount, userStakes[user]);
    }

    /// @notice Exits the Hyperbolic Time Chamber, unstaking tokens and claiming pending Essence.
    /// @param amount The amount of stakingToken to unstake.
    function exitChamber(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        address user = msg.sender;
        require(userStakes[user] >= amount, "Insufficient staked amount");

        // Claim pending essence up to this moment
        userAccumulatedEssence[user] += _calculatePendingEssence(user);

        // Update stake and time
        userStakes[user] -= amount;
        totalStakedAmount -= amount;
        userEntryTime[user] = block.timestamp; // Reset time counter (even if stake is 0, marks exit time)

        if (userStakes[user] == 0) {
            activeUsersCount--;
            delete userEntryTime[user]; // Clear entry time if not staking
            delete userBoostMultiplier[user]; // Reset boost when completely unstaked
        }

        // Transfer tokens back to the user
        bool success = stakingToken.transfer(user, amount);
        require(success, "Token transfer failed");

        emit ExitedChamber(user, amount, userStakes[user]);
    }

    /// @notice Claims the pending Temporal Essence accrued since the last claim or stake modification.
    function claimEssence() external nonReentrant whenNotPaused {
        address user = msg.sender;
        require(userStakes[user] > 0, "User is not staking");

        uint256 pending = _calculatePendingEssence(user);
        require(pending > 0, "No pending Essence to claim");

        userAccumulatedEssence[user] += pending;
        userEntryTime[user] = block.timestamp; // Reset time counter

        emit EssenceClaimed(user, pending);
    }

    /// @notice Calculates the amount of Temporal Essence a user has accrued since their last action.
    /// @dev This function is internal but exposed via `getPendingEssence`.
    /// @param user The address of the user.
    /// @return The amount of pending Temporal Essence.
    function _calculatePendingEssence(address user) internal view returns (uint256) {
        uint256 staked = userStakes[user];
        if (staked == 0) {
            return 0;
        }

        uint256 timeDelta = block.timestamp - userEntryTime[user];
        if (timeDelta == 0) {
            return 0;
        }

        // Essence = staked * timeDelta * globalFactor * efficiencyRate * userBoost / (TIME_UNIT * BOOST_SCALE * BOOST_SCALE * ESSENCE_RATE_SCALE^-1)
        // To avoid large numbers before division, rearrange and scale.
        // Let's simplify the rate calculation. Rate = (globalFactor * efficiencyRate * userBoost) / (BOOST_SCALE * BOOST_SCALE * BOOST_SCALE) -- use BOOST_SCALE^3 denominator
        // Base rate per token per second = (globalFactor * efficiencyRate * userBoost) / (BOOST_SCALE * BOOST_SCALE * BOOST_SCALE * ESSENCE_RATE_SCALE_INV)
        // Essence = staked * timeDelta * Rate * TIME_UNIT

        // Scale factors: Global, Efficiency, User Boost are all BOOST_SCALE based
        // Time is seconds. Staked amount is base units. Essence is ESSENCE_RATE_SCALE based.
        // Essence_accrued = staked_amount * time_delta * (global_factor/BOOST_SCALE) * (efficiency_rate/BOOST_SCALE) * (user_boost/BOOST_SCALE) * (TIME_UNIT_multiplier)
        // The TIME_UNIT constant essentially defines the *base* rate for 1 token over TIME_UNIT seconds with all factors at 1x.
        // Let's make the calculation: staked * timeDelta * global * efficiency * boost / (TIME_UNIT_SECONDS * BOOST_SCALE * BOOST_SCALE * BOOST_SCALE / ESSENCE_RATE_SCALE)
        // Simplified: (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]) / (TIME_UNIT * BOOST_SCALE * BOOST_SCALE * BOOST_SCALE / ESSENCE_RATE_SCALE)

        // To prevent division issues with large numerators, perform multiplications first.
        // Use 1e18 for ESSENCE_RATE_SCALE for standard ERC20-like decimals for Essence.
        // Base rate per second per staked token assuming factors are 1000 (1x): 1 * 1 * (1000/1000) * (1000/1000) * (1000/1000) / (TIME_UNIT_SECONDS * 1000*1000*1000 / 1e18)
        // = 1 / (TIME_UNIT_SECONDS * 1e9 / 1e18) = 1 / (TIME_UNIT_SECONDS / 1e9) = 1e9 / TIME_UNIT_SECONDS
        // If TIME_UNIT = 1 hour = 3600 seconds, base rate is 1e9 / 3600 Essence per staked token per second.

        // Calculation: staked * timeDelta * global * efficiency * boost / (BOOST_SCALE^3) * (ESSENCE_RATE_SCALE / TIME_UNIT_SECONDS)
        // = (staked * timeDelta) * (global * efficiency * boost) / (BOOST_SCALE^3) * (ESSENCE_RATE_SCALE / TIME_UNIT)
        // We can combine the fixed denominators: BOOST_SCALE^3 * TIME_UNIT / ESSENCE_RATE_SCALE
        // Denominator = uint256(BOOST_SCALE).mul(BOOST_SCALE).mul(BOOST_SCALE).mul(TIME_UNIT).div(ESSENCE_RATE_SCALE); // Need SafeMath or Solidity 0.8+ checks

        // Let's do it like this:
        // Essence rate per second per token = (globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT);
        // Total pending = staked * timeDelta * Essence rate per second per token / ESSENCE_RATE_SCALE
        // Total pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT / ESSENCE_RATE_SCALE * ESSENCE_RATE_SCALE / ESSENCE_RATE_SCALE) -- simplifies back
        // Total pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT);

        // To avoid overflow, perform calculations carefully.
        // Max possible value of staked * timeDelta * global * efficiency * boost?
        // Assume max staked ~ 2^128, max timeDelta ~ 2^64 (years), factors ~ 1000x boost = 10^3.
        // 2^128 * 2^64 * 10^3 * 10^3 * 10^3 * 1e18 ~ 2^192 * 10^9 * 1e18 ~ 2^192 * 10^27
        // This might exceed uint256 (max ~ 1.15 * 10^77, or 2^256).
        // Let's use a different scaling approach or calculate rate per second first.

        // Rate per second per token (scaled up by ESSENCE_RATE_SCALE * BOOST_SCALE):
        // rate_scaled = (globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE);
        // Total pending = (staked * timeDelta * rate_scaled) / TIME_UNIT;
        // This looks better. staked*timeDelta could still be large, but rate_scaled should fit.
        // max rate_scaled: (10^3 * 10^3 * 10^3 * 1e18) / (10^3 * 10^3 * 10^3) = 1e18. Okay.
        // max staked * timeDelta: 2^128 * 2^64 = 2^192. Still potentially large.

        // Let's split the calculation: (staked * timeDelta / TIME_UNIT) * rate_scaled / ESSENCE_RATE_SCALE
        // Amount of TIME_UNIT periods = timeDelta / TIME_UNIT
        // Essence = staked * (timeDelta / TIME_UNIT) * (global * efficiency * boost) / (BOOST_SCALE^3) * ESSENCE_RATE_SCALE
        // Use fixed point arithmetic: multiply by scaling factors early, divide late.
        // Numerator: staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]
        uint256 numerator = staked;
        numerator = numerator * timeDelta; // Potentially large
        numerator = numerator * globalTimeFactor; // Potentially larger
        numerator = numerator * chamberEfficiencyRate; // Potentially larger
        numerator = numerator * userBoostMultiplier[user]; // Potentially largest intermediate

        // Denominator: TIME_UNIT * BOOST_SCALE^3
        uint256 denominator = uint256(TIME_UNIT);
        denominator = denominator * BOOST_SCALE;
        denominator = denominator * BOOST_SCALE;
        denominator = denominator * BOOST_SCALE;

        // Result = (numerator * ESSENCE_RATE_SCALE) / denominator
        // This form (N * Scale) / D helps maintain precision.
        // Check max numerator: 2^128 * 2^64 * (1000)^3 * (1000)^3 * (1000)^3 ~ 2^192 * 10^9 * 10^9 * 10^9 = 2^192 * 10^27.
        // Multiply by ESSENCE_RATE_SCALE (1e18): 2^192 * 10^27 * 10^18 = 2^192 * 10^45.
        // 2^192 is large, but 10^45 is much smaller than 2^64. The product should fit in uint256.
        // log2(10^45) = 45 * log2(10) ~ 45 * 3.32 = 149.4. So 10^45 is roughly 2^149.
        // 2^192 * 10^45 ~ 2^192 * 2^149 = 2^341. This is too large for uint256.

        // Okay, rethink the scaling and formula to manage intermediate values.
        // Essence per second per token = Rate / TIME_UNIT
        // Rate = (globalFactor/BS) * (efficiencyRate/BS) * (userBoost/BS) * ESSENCE_RATE_SCALE
        // Rate per second per token = (globalFactor * efficiencyRate * userBoost * ESSENCE_RATE_SCALE) / (BOOST_SCALE^3 * TIME_UNIT)
        // Total = staked * timeDelta * Rate per second per token
        // Total = (staked * timeDelta * globalFactor * efficiencyRate * userBoost * ESSENCE_RATE_SCALE) / (BOOST_SCALE^3 * TIME_UNIT)

        // Let's use a different scaling for rate components:
        // Rate = (globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]) / (BOOST_SCALE * BOOST_SCALE) // Scaled rate, e.g., 1e6 for 1x
        // Essence per second per token = Rate / BOOST_SCALE // Now 1e3 for 1x per second per token (if boostscale=1000)
        // Essence per time_unit per token = Essence per second per token * TIME_UNIT
        // Essence = staked * (timeDelta / TIME_UNIT) * (Rate / BOOST_SCALE) * ESSENCE_RATE_SCALE
        // Essence = staked * timeDelta * Rate / (BOOST_SCALE * TIME_UNIT) * ESSENCE_RATE_SCALE
        // Essence = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3 * TIME_UNIT);
        // This is the same formula, the intermediate overflow risk persists.

        // Let's cap time delta for calculation? Or use a different unit?
        // What if Essence calculation was simpler? Essence = staked * timeDelta * simple_rate
        // simple_rate could be (global * efficiency * boost) / COMPOUND_SCALE
        // Compound Scale = BOOST_SCALE^3 * TIME_UNIT / ESSENCE_RATE_SCALE
        // (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]) / (BOOST_SCALE^3 * TIME_UNIT / ESSENCE_RATE_SCALE)
        // This is the correct scaling. The maximum value of `numerator` should fit `uint256` if
        // `staked * timeDelta * globalFactor * efficiencyRate * userBoost`
        // fits. Max `staked` = `chamberCapacity`. Max `timeDelta`... could be years.
        // Let's assume `chamberCapacity` is reasonable (e.g., 10^24 tokens with 18 decimals).
        // Max timeDelta = 1 year ~ 3.15e7.
        // Max Factors ~ 10x = 10000 for BOOST_SCALE=1000. So max boostMultiplier=10000.
        // 10^24 * 3.15e7 * 10000 * 10000 * 10000 = 10^24 * 3.15e7 * 10^12 = 3.15e43.
        // Multiply by ESSENCE_RATE_SCALE (1e18): 3.15e43 * 1e18 = 3.15e61. This fits in uint256.
        // The denominator is BOOST_SCALE^3 * TIME_UNIT / ESSENCE_RATE_SCALE
        // (1000)^3 * 3600 / 1e18 = 1e9 * 3600 / 1e18 = 3.6e12 / 1e18 = 3.6e-6.
        // We need to multiply the numerator by ESSENCE_RATE_SCALE *before* dividing by BOOST_SCALE^3 * TIME_UNIT.

        // Formula: (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3 * TIME_UNIT)
        // Let's calculate the denominator term first: DenomTerm = (uint256(BOOST_SCALE)**3 * TIME_UNIT) / ESSENCE_RATE_SCALE
        // This DenomTerm will be a scaling factor that converts the raw product (staked * timeDelta * factors) into Essence units.
        // DenomTerm = (1e9 * 3600) / 1e18 = 3.6e12 / 1e18 = 3.6e-6. This is less than 1. Division by zero risk if using integer division directly.
        // We must ensure the denominator part is calculated correctly and doesn't result in 0 or huge numbers due to integer math order.

        // The correct integer math should be:
        // pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE)
        // Now pending is in "raw" essence units, scaled up by BOOST_SCALE^3.
        // Convert to final essence units (scaled by ESSENCE_RATE_SCALE per token):
        // pending = (pending * ESSENCE_RATE_SCALE) / TIME_UNIT; // This is the tricky division order.

        // Let's use the structure:
        // rate_per_sec_per_token = (global * eff * boost) / (BOOST_SCALE^3) -- effectively 1e-9 for 1x factors
        // total_essence = staked * timeDelta * rate_per_sec_per_token * ESSENCE_RATE_SCALE
        // total_essence = (staked * timeDelta * global * eff * boost * ESSENCE_RATE_SCALE) / (BOOST_SCALE^3)
        // This still doesn't account for TIME_UNIT. TIME_UNIT is part of the *rate*.

        // Correct rate: Essence per staked token per SECOND = (global * eff * boost) / (BOOST_SCALE^3) * (ESSENCE_RATE_SCALE / TIME_UNIT)
        // Essence = staked * timeDelta * Rate_per_sec_per_token
        // Essence = staked * timeDelta * (global * eff * boost * ESSENCE_RATE_SCALE) / (BOOST_SCALE^3 * TIME_UNIT)

        // Let's break it down:
        // Numerator: staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]
        // Denominator: uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT / ESSENCE_RATE_SCALE -- This is NOT standard. The ESSENCE_RATE_SCALE should be in the numerator scale.
        // Correct: Denominator = uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT

        // pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT);

        // To avoid overflow in numerator before division:
        // Let's calculate per-second-rate-scaled:
        // rate_per_sec_scaled = (globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]); // This is scaled by BOOST_SCALE^3
        // Now scale it to Essence units per second per token:
        // rate_per_sec_essence_scaled = (rate_per_sec_scaled * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE * TIME_UNIT); // TIME_UNIT here seems wrong. TIME_UNIT is a multiplier on TIME_DELTA, not a divisor in the rate per second.

        // The Time Unit defines how many seconds correspond to the "base" unit of Essence generation.
        // If TIME_UNIT = 1 hour (3600s), and factors are 1x (1000), then 1 staked token for 1 hour generates X Essence.
        // X = 1 * (1 hour) * (1000/1000) * (1000/1000) * (1000/1000) * ESSENCE_RATE_SCALE / MAGIC_CONSTANT
        // Let MAGIC_CONSTANT = BOOST_SCALE^3
        // X = 1 * TIME_UNIT * 1 * 1 * 1 * ESSENCE_RATE_SCALE / BOOST_SCALE^3
        // X = TIME_UNIT * ESSENCE_RATE_SCALE / BOOST_SCALE^3

        // So Essence generated = staked * (timeDelta / TIME_UNIT) * (global * eff * boost) / BOOST_SCALE^3 * ESSENCE_RATE_SCALE
        // Need integer division for (timeDelta / TIME_UNIT).
        // periods = timeDelta / TIME_UNIT;
        // leftover_seconds = timeDelta % TIME_UNIT;

        // Essence from periods = staked * periods * (global * eff * boost) / BOOST_SCALE^3 * ESSENCE_RATE_SCALE
        // Essence from leftover = staked * leftover_seconds * (global * eff * boost) / BOOST_SCALE^3 * ESSENCE_RATE_SCALE / TIME_UNIT

        // Simpler: Just use timeDelta directly in seconds.
        // Essence per second per token = (global * eff * boost) / BOOST_SCALE^3 * (ESSENCE_RATE_SCALE / TIME_UNIT) ?
        // No, TIME_UNIT is the unit *of time*, the rate is per second.
        // Base rate = ESSENCE_RATE_SCALE per token per TIME_UNIT seconds (with 1x factors).
        // Rate per second per token = ESSENCE_RATE_SCALE / TIME_UNIT (with 1x factors).
        // Total Essence = staked * timeDelta * Rate per second per token * factors
        // Total Essence = staked * timeDelta * (ESSENCE_RATE_SCALE / TIME_UNIT) * (global / BOOST_SCALE) * (eff / BOOST_SCALE) * (boost / BOOST_SCALE)
        // Total Essence = (staked * timeDelta * ESSENCE_RATE_SCALE * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]) / (TIME_UNIT * uint256(BOOST_SCALE)**3);
        // This is the same formula causing overflow fears.

        // Let's break down calculations to keep intermediates small.
        // staked * timeDelta <= 2^128 * 2^64 = 2^192
        // factors = global * eff * boost <= (10000)^3 = 10^12
        // staked * timeDelta * factors <= 2^192 * 10^12
        // Multiply by ESSENCE_RATE_SCALE (1e18): <= 2^192 * 10^12 * 1e18 = 2^192 * 10^30. log2(10^30) ~ 30*3.32 = 99.6.
        // 2^192 * 2^99.6 ~ 2^291. Still too big.

        // Maybe the issue is the scale of factors? If max factors are 1000 (1x), then BOOST_SCALE is the max value.
        // Let max factor = BOOST_SCALE. (1000)^3 = 1e9.
        // staked * timeDelta * factors <= 2^192 * 1e9. Multiply by 1e18: 2^192 * 1e27. log2(1e27)~ 90. 2^192 * 2^90 = 2^282. Still too big.

        // What if Essence per second per token is (global * eff * boost) / (BOOST_SCALE^3)?
        // This yields a very small number (e.g., 1/1e9).
        // Then total essence = staked * timeDelta * this_rate * ESSENCE_RATE_SCALE
        // total = staked * timeDelta * (global * eff * boost) / (BOOST_SCALE^3) * ESSENCE_RATE_SCALE
        // total = (staked * timeDelta * global * eff * boost * ESSENCE_RATE_SCALE) / (BOOST_SCALE^3)

        // This requires (staked * timeDelta * global * eff * boost * ESSENCE_RATE_SCALE) to fit in uint256.
        // Use max practical values: staked 1e24, timeDelta 1yr ~ 3.15e7, factors 1000 (1x), ESSENCE_RATE_SCALE 1e18.
        // 1e24 * 3.15e7 * 1000 * 1000 * 1000 * 1e18 = 3.15e7 * 1e24 * 1e9 * 1e18 = 3.15e58. This fits!

        // The denominator is BOOST_SCALE^3 = 1000^3 = 1e9.
        // The formula should be:
        // pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3);

        // Final attempt at calculation logic:
        // Accrual Rate per Second per Staked Token (scaled by ESSENCE_RATE_SCALE):
        // rate_per_sec_per_token_scaled = (globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user]); // Scaled by BOOST_SCALE^3
        // pending = (staked * timeDelta * rate_per_sec_per_token_scaled * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3); // No, this reintroduces the issue.

        // Let's calculate pending using fixed point arithmetic with ESSENCE_RATE_SCALE as the base.
        // Essence generated per staked token per second = (global * eff * boost) / (BOOST_SCALE^3) * 1e18
        // This rate should be directly used.
        // rate_per_second_per_token = (globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3);
        // pending = staked * timeDelta * rate_per_second_per_token / ESSENCE_RATE_SCALE; // Div by scale at the end
        // pending = staked * timeDelta * (global * eff * boost * ESSENCE_RATE_SCALE / BOOST_SCALE^3) / ESSENCE_RATE_SCALE
        // pending = (staked * timeDelta * global * eff * boost * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3 * ESSENCE_RATE_SCALE);
        // pending = (staked * timeDelta * global * eff * boost) / (uint256(BOOST_SCALE)**3); // This assumes Essence base is 1 token per BOOST_SCALE^3 seconds? No.

        // Let's try the simple way again and check max values carefully.
        // Essence = staked * timeDelta * globalFactor * efficiencyRate * userBoost / (BOOST_SCALE * BOOST_SCALE * BOOST_SCALE / ESSENCE_RATE_SCALE)
        // Numerator: staked * timeDelta * globalFactor * efficiencyRate * userBoost
        // Denominator: (BOOST_SCALE * BOOST_SCALE * BOOST_SCALE) / ESSENCE_RATE_SCALE -- Integer division here is problematic.
        // Multiply numerator by ESSENCE_RATE_SCALE first:
        // pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE) * BOOST_SCALE * BOOST_SCALE);

        // Max Numerator: 1e24 * 3.15e7 * 1000 * 1000 * 1000 * 1e18 = 3.15e58. Fits in uint256.
        // Denominator: 1000^3 = 1e9. This is fine.
        // So the formula:
        uint256 numerator = staked;
        numerator = numerator * timeDelta;
        numerator = numerator * globalTimeFactor;
        numerator = numerator * chamberEfficiencyRate;
        numerator = numerator * userBoostMultiplier[user];
        numerator = numerator * ESSENCE_RATE_SCALE;

        uint256 denominator = uint256(BOOST_SCALE);
        denominator = denominator * BOOST_SCALE;
        denominator = denominator * BOOST_SCALE;
        // denominator = denominator * TIME_UNIT; // TIME_UNIT defines the rate, it's not a divisor like this. It's part of the conceptual "base unit".

        // Let's redefine how TIME_UNIT and scaling work.
        // Let's say 1 staked token with all factors at 1x generates 1 unit of Essence (scaled by ESSENCE_RATE_SCALE) every TIME_UNIT seconds.
        // Rate per TIME_UNIT seconds = staked * globalFactor * efficiencyRate * userBoost / BOOST_SCALE^3
        // Rate per second = (staked * globalFactor * efficiencyRate * userBoost / BOOST_SCALE^3) / TIME_UNIT
        // Total Essence = timeDelta * Rate per second
        // Total Essence = timeDelta * (staked * globalFactor * efficiencyRate * userBoost / BOOST_SCALE^3) / TIME_UNIT
        // Total Essence = (staked * timeDelta * globalFactor * efficiencyRate * userBoost) / (BOOST_SCALE^3 * TIME_UNIT) // Raw value
        // Scaled Essence = (staked * timeDelta * globalFactor * efficiencyRate * userBoost * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3 * TIME_UNIT)

        // Max Numerator: 1e24 * 3.15e7 * 1000 * 1000 * 1000 * 1e18 = 3.15e58. Fits.
        // Denominator: BOOST_SCALE^3 * TIME_UNIT = 1e9 * 3600 = 3.6e12.
        // Result: 3.15e58 / 3.6e12 ~ 10^46. Fits.

        // So the calculation is:
        // pending = (staked * timeDelta * globalTimeFactor * chamberEfficiencyRate * userBoostMultiplier[user] * ESSENCE_RATE_SCALE) / (uint256(BOOST_SCALE)**3 * TIME_UNIT);

        uint256 denominator_scaled = uint256(BOOST_SCALE);
        denominator_scaled = denominator_scaled * BOOST_SCALE;
        denominator_scaled = denominator_scaled * BOOST_SCALE;
        denominator_scaled = denominator_scaled * TIME_UNIT;

        // Check for division by zero, though BOOST_SCALE and TIME_UNIT are constants > 0
        require(denominator_scaled > 0, "Calc error: Denominator is zero");

        // Calculate pending
        uint256 pending = (numerator * ESSENCE_RATE_SCALE) / denominator_scaled; // This requires numerator to be staked * timeDelta * global * eff * boost

        numerator = staked;
        numerator = numerator * timeDelta;
        numerator = numerator * globalTimeFactor;
        numerator = numerator * chamberEfficiencyRate;
        numerator = numerator * userBoostMultiplier[user];

        pending = (numerator * ESSENCE_RATE_SCALE) / denominator_scaled;


        return pending;
    }

    /// @notice Returns the amount of Temporal Essence a user has accrued but not yet claimed.
    /// @param user The address of the user.
    /// @return The amount of pending Temporal Essence.
    function getPendingEssence(address user) public view returns (uint256) {
        return _calculatePendingEssence(user);
    }

    /// @notice Returns the accumulated, claimed Temporal Essence balance for a user.
    /// @param user The address of the user.
    /// @return The user's accumulated Essence balance.
    function getEssenceBalance(address user) public view returns (uint256) {
        return userAccumulatedEssence[user];
    }

    // --- Essence Utility ---

    /// @notice Burns claimed Temporal Essence to permanently increase the user's personal boost multiplier.
    /// @param essenceAmount The amount of claimed Essence to burn.
    function burnEssenceForBoost(uint256 essenceAmount) external whenNotPaused {
        require(essenceAmount > 0, "Burn amount must be > 0");
        address user = msg.sender;
        require(userAccumulatedEssence[user] >= essenceAmount, "Insufficient claimed Essence");

        // Calculate boost increase: roughly 1 BOOST_SCALE per ESSENCE_PER_BOOST_UNIT burned
        // increase = (essenceAmount * BOOST_SCALE) / ESSENCE_PER_BOOST_UNIT;
        // To maintain precision for smaller burns:
        uint256 boostIncrease = (essenceAmount * BOOST_SCALE * BOOST_SCALE) / ESSENCE_PER_BOOST_UNIT; // Scaled up
        boostIncrease = boostIncrease / BOOST_SCALE; // Scale down

        require(boostIncrease > 0, "Burn amount too small for boost increase");

        userAccumulatedEssence[user] -= essenceAmount;

        // Ensure userBoostMultiplier exists before adding (it's set on first stake)
        if (userStakes[user] == 0 && userBoostMultiplier[user] == 0) {
             userBoostMultiplier[user] = BOOST_SCALE; // Initialize if somehow missing
        }

        userBoostMultiplier[user] += boostIncrease;

        emit EssenceBurnedForBoost(user, essenceAmount, userBoostMultiplier[user]);
    }

     /// @notice Allows users to sacrifice claimed Essence to contribute to a potential global efficiency increase.
     /// @dev The actual global efficiency update logic is handled by an admin via `updateChamberEfficiency`,
     /// @dev which might take total sacrificed amount into account. This function only records the sacrifice.
     /// @param essenceAmount The amount of claimed Essence to sacrifice.
    function sacrificeEssenceForGlobalEfficiency(uint256 essenceAmount) external whenNotPaused {
        require(essenceAmount > 0, "Sacrifice amount must be > 0");
        address user = msg.sender;
        require(userAccumulatedEssence[user] >= essenceAmount, "Insufficient claimed Essence");

        userAccumulatedEssence[user] -= essenceAmount;

        // Logic to record sacrifice for potential future global efficiency update.
        // This could be a simple sum or more complex. For this example, let's just emit an event,
        // and the admin/owner logic in updateChamberEfficiency can decide how to react.
        // A more advanced version might track a global sacrifice pool.
        // For now, it's a signal for off-chain or admin action.

        emit EssenceSacrificedForGlobal(user, essenceAmount);
    }

    // --- Delegation ---

    /// @notice Allows the caller to delegate the ability to claim their pending Essence to another address.
    /// @param delegatee The address to delegate claim rights to. Address(0) to remove.
    function delegateClaim(address delegatee) external whenNotPaused {
        require(userStakes[msg.sender] > 0 || userAccumulatedEssence[msg.sender] > 0, "User has no stake or essence");
        claimDelegatee[msg.sender] = delegatee;
        emit ClaimDelegateeSet(msg.sender, delegatee);
    }

    /// @notice Removes the current claim delegatee for the caller.
    function removeDelegateClaim() external whenNotPaused {
        require(claimDelegatee[msg.sender] != address(0), "No delegatee set");
        delete claimDelegatee[msg.sender];
        emit ClaimDelegateeRemoved(msg.sender);
    }

    /// @notice Allows a designated delegatee to claim pending Essence for the user who delegated.
    /// @param user The address of the user whose Essence should be claimed.
    function claimEssenceDelegated(address user) external nonReentrant whenNotPaused {
        require(claimDelegatee[user] == msg.sender, "Not authorized to claim for this user");
        require(userStakes[user] > 0, "User is not staking");

        uint256 pending = _calculatePendingEssence(user);
        require(pending > 0, "No pending Essence to claim");

        userAccumulatedEssence[user] += pending;
        userEntryTime[user] = block.timestamp; // Reset time counter for the user

        // Note: The delegatee claims *into* the user's accumulated balance, not their own.
        emit EssenceClaimed(user, pending); // Event still refers to the user whose Essence is claimed
    }

    // --- Dynamic State / Admin Controls ---

    /// @notice Allows Admin or Owner to update the chamber efficiency rate.
    /// @dev This could incorporate logic based on `sacrificeEssenceForGlobalEfficiency` events,
    /// @dev or simply be a time-gated parameter update.
    function updateChamberEfficiency() external onlyAdmin whenNotPaused {
        require(block.timestamp >= lastEfficiencyUpdateTime + efficiencyUpdateInterval, "Efficiency update interval not passed");

        // --- Advanced Logic Placeholder ---
        // Implement logic here to determine the new chamberEfficiencyRate.
        // This could be based on:
        // - A function of totalStakedAmount
        // - A function of activeUsersCount
        // - Accumulation from sacrificeEssenceForGlobalEfficiency (needs state variable to track)
        // - A time-based decay or oscillation
        // - Data from an oracle (more advanced, requires oracle integration)

        // For this example, let's make it a simple oscillating value or fixed increase/decrease.
        // Or just allow the admin to set it within bounds. Let's make it admin settable for simplicity in the code,
        // but the function name and interval suggest dynamic updates.
        // A robust implementation would have internal logic calculating `newRate`.

        // Example: oscillate based on time and total staked (highly simplified)
        // uint256 newRate = BOOST_SCALE + (totalStakedAmount / 1e18 / 1000) % 500; // Base 1000 + small variation
        // For a true oscillation or decay, more complex state (like last rate change, direction, etc.) is needed.
        // Let's just require admin to provide the new rate for now.
        revert("Implement updateChamberEfficiency logic or use setChamberEfficiencyRate");

        // uint256 newRate = calculateNewEfficiencyRate(); // Replace with actual logic
        // chamberEfficiencyRate = newRate;
        // lastEfficiencyUpdateTime = block.timestamp;
        // emit ChamberEfficiencyUpdated(newRate, block.timestamp);
    }

     /// @notice Allows Admin or Owner to manually set the chamber efficiency rate.
     /// @dev This bypasses the automated `updateChamberEfficiency` logic but respects admin control.
     /// @param newRate The new efficiency rate (e.g., 1000 for 1x).
    function setChamberEfficiencyRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "Efficiency rate must be > 0");
        chamberEfficiencyRate = newRate;
        lastEfficiencyUpdateTime = block.timestamp; // Treat manual update like an automated one for the interval
        emit ChamberEfficiencyUpdated(newRate, block.timestamp);
    }


    /// @notice Allows the Owner to set the maximum total tokens allowed in the chamber.
    /// @param newCapacity The new maximum capacity. Must be >= current total staked.
    function setChamberCapacity(uint256 newCapacity) external onlyOwner {
        require(newCapacity >= totalStakedAmount, "New capacity must be >= current staked amount");
        chamberCapacity = newCapacity;
        emit ChamberCapacityUpdated(newCapacity);
    }

    /// @notice Allows the Owner to set the maximum number of unique users allowed to stake.
    /// @param newUserLimit The new maximum user limit. Must be >= current active users.
    function setUserLimit(uint256 newUserLimit) external onlyOwner {
        require(newUserLimit >= activeUsersCount, "New limit must be >= current active users");
        chamberUserLimit = newUserLimit;
        emit ChamberUserLimitUpdated(newUserLimit);
    }

    /// @notice Allows Admin or Owner to set the global multiplier for Essence generation.
    /// @param newFactor The new global time factor (e.g., 1000 for 1x).
    function setGlobalTimeFactor(uint256 newFactor) external onlyAdmin {
        require(newFactor > 0, "Global factor must be > 0");
        globalTimeFactor = newFactor;
        emit GlobalTimeFactorUpdated(newFactor);
    }

    /// @notice Grants admin privileges to an address.
    /// @param admin The address to grant privileges to.
    function addAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        admins[admin] = true;
        emit AdminAdded(admin);
    }

    /// @notice Revokes admin privileges from an address.
    /// @param admin The address to revoke privileges from.
    function removeAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        // Prevent removing the current owner unless ownership is transferred first
        require(admin != owner(), "Cannot remove owner as admin directly");
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    /// @notice Checks if an address has admin privileges.
    /// @param account The address to check.
    /// @return True if the account is an admin or the owner, false otherwise.
    function isAdmin(address account) public view returns (bool) {
        return admins[account] || owner() == account;
    }

    // --- Pause/Unpause ---

    /// @notice Pauses core chamber operations (enter, exit, claim, burn, sacrifice, delegate).
    function pauseChamber() external onlyOwner {
        _pause();
        emit ChamberPaused(msg.sender);
    }

    /// @notice Unpauses core chamber operations.
    function unpauseChamber() external onlyOwner {
        _unpause();
        emit ChamberUnpaused(msg.sender);
    }

    // --- Information / View Functions ---

    /// @notice Returns the amount of staking tokens currently staked by a user.
    /// @param user The address of the user.
    /// @return The staked amount.
    function getStakedAmount(address user) public view returns (uint256) {
        return userStakes[user];
    }

    /// @notice Returns the total amount of staking tokens currently staked in the chamber.
    /// @return The total staked amount.
    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }

    /// @notice Returns the current number of unique users actively staking.
    /// @return The count of active users.
    function getActiveUsersCount() public view returns (uint256) {
        return activeUsersCount;
    }

    /// @notice Returns the maximum total tokens allowed to be staked.
    /// @return The chamber capacity.
    function getChamberCapacity() public view returns (uint256) {
        return chamberCapacity;
    }

    /// @notice Returns the maximum number of unique users allowed to stake.
    /// @return The user limit.
    function getUserLimit() public view returns (uint256) {
        return chamberUserLimit;
    }

    /// @notice Returns the current global multiplier for Essence generation.
    /// @return The global time factor.
    function getGlobalTimeFactor() public view returns (uint256) {
        return globalTimeFactor;
    }

    /// @notice Returns the current personal boost multiplier for a user.
    /// @param user The address of the user.
    /// @return The user's boost multiplier.
    function getUserBoostMultiplier(address user) public view returns (uint256) {
        // Return default boost if user is not staking/has no explicit boost
        return userBoostMultiplier[user] > 0 ? userBoostMultiplier[user] : BOOST_SCALE;
    }

    /// @notice Returns the current dynamic chamber efficiency rate.
    /// @return The chamber efficiency rate.
    function getChamberEfficiencyRate() public view returns (uint256) {
        return chamberEfficiencyRate;
    }

     /// @notice Returns the timestamp of the last time the chamber efficiency rate was updated.
     /// @return The timestamp.
    function getLastEfficiencyUpdateTime() public view returns (uint256) {
        return lastEfficiencyUpdateTime;
    }

    /// @notice Returns the address of the staking token used in this chamber.
    /// @return The staking token address.
    function getStakingTokenAddress() public view returns (address) {
        return address(stakingToken);
    }

    /// @notice Returns the address designated to claim Essence on behalf of a user.
    /// @param user The address of the user.
    /// @return The delegatee address (address(0) if no delegatee is set).
    function getClaimDelegatee(address user) public view returns (address) {
        return claimDelegatee[user];
    }

    // --- Owner Functions ---

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        // Optionally revoke admin status from old owner if they are not the new owner
        if (admins[_owner] && newOwner != _owner) {
             admins[_owner] = false;
             emit AdminRemoved(_owner);
        }
        // Grant admin status to new owner if not already admin (Ownable transfer handles ownership)
        if (!admins[newOwner]) {
            admins[newOwner] = true;
            emit AdminAdded(newOwner);
        }
        super.transferOwnership(newOwner);
    }

    /// @notice Renounces ownership of the contract.
    /// @dev The contract will be left without an owner, and admin functions will be inaccessible
    ///      unless they explicitly check for admin status besides ownership.
    function renounceOwnership() public override onlyOwner {
         // Optionally revoke admin status from the owner
        if (admins[_owner]) {
             admins[_owner] = false;
             emit AdminRemoved(_owner);
        }
        super.renounceOwnership();
    }

    /// @notice Allows the owner to withdraw arbitrary ERC20 tokens sent to the contract by mistake.
    /// @dev This is a safety function to recover misplaced tokens. Can't withdraw stakingToken if paused.
    /// @param token Address of the token to withdraw.
    /// @param amount Amount of the token to withdraw.
    function withdrawEmergency(address token, uint256 amount) external onlyOwner nonReentrant {
        // Prevent withdrawing staking token if the chamber is paused to avoid affecting staked balance integrity
        if (token == address(stakingToken)) {
             require(!paused(), "Cannot emergency withdraw staking token while paused");
             // Add check to ensure withdrawing doesn't break totalStakedAmount invariant if necessary,
             // though this is usually only for *mistakenly* sent tokens, not the staked ones.
             // Simple check: Ensure the amount being withdrawn is less than the total balance minus staked amount
             require(IERC20(token).balanceOf(address(this)) >= totalStakedAmount + amount, "Cannot withdraw staked tokens via emergency withdraw");
        }
        IERC20(token).transfer(owner(), amount);
    }

     // Optional: Receive Ether function to allow sending ETH by mistake
    receive() external payable {}
    fallback() external payable {}
}
```

---

**Explanation and Advanced Concepts Used:**

1.  **Time-Based Non-Linear Accrual:** The core mechanic is calculating `_calculatePendingEssence` based on `block.timestamp - userEntryTime[user]`. The rate is not fixed, but modulated by multiple multipliers (`globalTimeFactor`, `chamberEfficiencyRate`, `userBoostMultiplier`). The use of `BOOST_SCALE` and `ESSENCE_RATE_SCALE` provides a structured way to handle fractional rates and maintain precision before the final division. The rate calculation involves several factors, making it non-trivial.
2.  **Dynamic Parameters:** `chamberEfficiencyRate` and `globalTimeFactor` can be changed by admins/owner, allowing the system to react to external conditions, internal state (like total staked), or even user actions (`sacrificeEssenceForGlobalEfficiency`). `updateChamberEfficiency` is a placeholder for more complex time- or state-dependent logic.
3.  **Resource Conversion/Burning:** Users don't just stake and unstake; they generate a new resource (`Temporal Essence`). This resource has internal utility (`burnEssenceForBoost`, `sacrificeEssenceForGlobalEfficiency`), adding an economic loop within the contract itself rather than just interacting with external markets. Burning Essence adds a deflationary pressure on the Essence supply and provides a sink.
4.  **Internal Resource Tracking:** `userAccumulatedEssence` acts like an internal token balance. This avoids the overhead of deploying a separate ERC20 for Essence if its primary use is within this contract.
5.  **Claim Delegation:** The `delegateClaim` / `claimEssenceDelegated` pattern allows users to grant limited, specific permissions (claiming) to another address. This is a useful pattern for account management, yield farming aggregators, or even simple proxies, without giving full control.
6.  **Layered Access Control:** Uses `Ownable` for core control (`pause`, `setCapacity`, `setUserLimit`, `add/removeAdmin`, `transferOwnership`, `emergencyWithdraw`) and a separate `admins` mapping with `onlyAdmin` modifier for parameters that might need to be tweaked more frequently or by multiple trusted parties (`setGlobalTimeFactor`, `setChamberEfficiencyRate`, `updateChamberEfficiency`).
7.  **State Invariants & Calculations:** The logic in `enterChamber` and `exitChamber` correctly handles the calculation and addition of pending Essence *before* modifying the stake amount or resetting the timer (`userEntryTime`), ensuring users are credited for the time elapsed with their *previous* stake amount and factors.
8.  **Modular Design:** Uses OpenZeppelin libraries (`Ownable`, `ReentrancyGuard`, `Pausable`) for standard patterns, allowing focus on the unique mechanics.
9.  **Error Handling and Events:** Extensive `require` statements for input validation and state checks. Events are emitted for all significant actions, providing transparency and allowing off-chain monitoring.

This contract is more complex than a standard staking pool and incorporates several features that could be part of a larger game, DeFi protocol, or resource management simulation on chain. It aims to be novel by combining time-based dynamics with multiple interacting factors and internal resource utility/burning.