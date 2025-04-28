Okay, here is a Solidity smart contract concept called `ChronoCredit`.

**Concept:** `ChronoCredit` is a non-transferable, time-sensitive credit system designed to reward consistent engagement and long-term staking within a specific ecosystem (represented here by locking ERC-20 collateral). Credit Points (`CP`) are earned by staking approved collateral tokens for specified durations. These points *decay* over time if the user is inactive (not actively staking or claiming). This incentivizes continuous participation. The credit score can be used by dApps or other contracts for various purposes (discounts, access, priority, etc.). It's a form of "soulbound" or non-transferable reputation tied to duration and activity.

**Advanced/Creative Aspects:**
1.  **Time-Based Decay:** Credit scores decrease if not actively maintained.
2.  **Variable Earning Rates:** Earning rate can depend on stake duration (longer == higher rate).
3.  **Dynamic Credit Score Calculation:** The current credit score is calculated considering elapsed time and decay since the last update.
4.  **Complex Stake Management:** Includes functions to extend, split, and merge stakes, allowing users more control over their locked collateral and credit earning strategy.
5.  **Non-Transferable Points:** Emphasizes reputation/engagement over tradable value.
6.  **Modular Earning/Decay Logic:** Parameters are adjustable by the owner.

---

**Smart Contract Outline:**

1.  **Pragma and Imports:** Solidity version, standard libraries (ERC20, Ownable, Pausable).
2.  **Custom Errors:** Defined errors for specific failure conditions.
3.  **Structs:** `StakeInfo` to hold details of each individual staking position.
4.  **State Variables:**
    *   Admin/Config: Owner, Paused status, Supported collateral token address, Earning rate parameters, Decay rate parameters, Minimum stake amount.
    *   User Data: Mapping for current credit scores, last update timestamp, total credit earned, individual stake information (using a nested mapping for unique IDs per user).
    *   Counters: Global stake counter, per-user stake counter.
5.  **Events:** To signal important actions (Stake, Unstake, CreditClaimed, ParametersUpdated, etc.).
6.  **Modifiers:** `requireMinCreditScore` (example usage).
7.  **Constructor:** Initializes owner and basic parameters.
8.  **Pausable/Ownable Functions:** Standard pause/unpause, transfer ownership.
9.  **Admin/Configuration Functions:** Set various parameters (`setSupportedCollateralToken`, `setDefaultEarningRatePerSecond`, etc.).
10. **Internal Helper Functions:**
    *   `_updateCreditScore`: Calculates and applies decay based on elapsed time.
    *   `_calculatePendingCredit`: Calculates earned points from active stakes since the last update.
    *   `_calculateCurrentDecay`: Pure function to calculate decay for a given time/score.
    *   `_calculateEffectiveEarningRate`: Pure function to determine earning rate based on stake parameters.
11. **Core User Functions:**
    *   `stake`: Allows users to lock collateral and start earning credit.
    *   `unstake`: Allows users to withdraw collateral after duration or early (with consequences).
    *   `claimCredit`: Updates the user's credit score by applying pending earnings and decay.
12. **Advanced User Functions:**
    *   `extendStakeDuration`: Adds more time to an existing stake.
    *   `splitStake`: Divides one stake entry into two (maintaining total amount and duration).
    *   `mergeStakes`: Combines multiple stake entries into a single new one (liquidating old ones' earnings up to that point).
13. **Query/Read Functions:** View functions to get user's credit score, stake details, contract parameters, etc.
14. **Example Usage Functions:** Placeholder function showing how credit points could be consumed or checked.

---

**Function Summary:**

1.  `constructor(address initialOwner)`: Initializes the contract owner.
2.  `pause()`: Pauses contract execution for sensitive actions (owner only).
3.  `unpause()`: Unpauses the contract (owner only).
4.  `transferOwnership(address newOwner)`: Transfers contract ownership (owner only).
5.  `setSupportedCollateralToken(address token)`: Sets the ERC-20 token address allowed for staking (owner only).
6.  `setDefaultEarningRatePerSecond(uint256 rate)`: Sets the base credit points earned per second per unit of collateral (owner only).
7.  `setEarningRateMultiplierPerYearLocked(uint256 multiplier)`: Sets a multiplier that increases the earning rate based on the stake duration (owner only).
8.  `setDecayRatePerSecond(uint256 rate)`: Sets the base rate at which credit points decay per second (owner only).
9.  `setDecayMultiplierPer10000Points(uint256 multiplier)`: Sets a multiplier that increases the decay rate based on the current credit score (owner only).
10. `setMinStakeAmount(uint256 amount)`: Sets the minimum required amount for a new stake (owner only).
11. `stake(uint256 amount, uint256 durationInSeconds)`: Locks `amount` of the supported collateral token for `durationInSeconds`, starting credit point accumulation. Requires prior ERC-20 approval.
12. `unstake(uint256 stakeId)`: Allows the user to withdraw their collateral for a specific stake. If the duration is not met, pending credit for that stake may be forfeited.
13. `claimCredit()`: Calculates earned credit points from active stakes and applies decay based on time elapsed since the last update, updating the user's credit score.
14. `extendStakeDuration(uint256 stakeId, uint256 additionalDurationInSeconds)`: Adds time to the duration of an existing stake.
15. `splitStake(uint256 stakeId, uint256 splitAmount)`: Divides an existing stake into two, with the original stake having its amount reduced and a new stake created with the `splitAmount`.
16. `mergeStakes(uint256[] stakeIds, uint256 newDurationInSeconds)`: Combines multiple existing stakes into a single new stake. Points earned from the old stakes up to the merge time are added to the user's balance via an implicit update. The new stake earns based on the combined amount and the `newDurationInSeconds`.
17. `getCreditScore(address user)`: Returns the current, decay-adjusted credit score for a user without modifying state.
18. `getPendingCredit(address user)`: Calculates and returns the credit points earned from active stakes that haven't been claimed yet, without applying decay or updating state.
19. `getTotalCreditEarned(address user)`: Returns the total, non-decaying credit points a user has ever earned.
20. `getStakes(address user)`: Returns an array of all stake IDs belonging to a user.
21. `getStakeDetails(address user, uint256 stakeId)`: Returns the detailed information (`StakeInfo`) for a specific stake belonging to a user.
22. `getCalculatedEarningRate(uint256 amount, uint256 durationInSeconds)`: Helper view function to calculate the potential earning rate for a given amount and duration based on current parameters.
23. `getCalculatedDecayRate(uint256 currentScore)`: Helper view function to calculate the instantaneous decay rate for a given credit score based on current parameters.
24. `getSupportedCollateralToken()`: Returns the address of the supported collateral token.
25. `getMinStakeAmount()`: Returns the minimum amount required for a new stake.
26. `redeemPointsForBenefit(uint256 pointsToRedeem)`: (Example) A function showing how a user might spend credit points for some in-contract benefit. Requires the user to have at least `pointsToRedeem`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Smart Contract Outline ---
// 1. Pragma and Imports
// 2. Custom Errors
// 3. Structs: StakeInfo
// 4. State Variables: Admin/Config, User Data, Counters
// 5. Events
// 6. Modifiers: requireMinCreditScore
// 7. Constructor
// 8. Pausable/Ownable Functions
// 9. Admin/Configuration Functions
// 10. Internal Helper Functions
// 11. Core User Functions: stake, unstake, claimCredit
// 12. Advanced User Functions: extendStakeDuration, splitStake, mergeStakes
// 13. Query/Read Functions
// 14. Example Usage Functions

// --- Function Summary ---
// 1. constructor(address initialOwner): Initializes owner.
// 2. pause(): Pauses contract (owner only).
// 3. unpause(): Unpauses contract (owner only).
// 4. transferOwnership(address newOwner): Transfers ownership (owner only).
// 5. setSupportedCollateralToken(address token): Sets allowed staking token (owner only).
// 6. setDefaultEarningRatePerSecond(uint256 rate): Sets base CP earning rate (owner only).
// 7. setEarningRateMultiplierPerYearLocked(uint256 multiplier): Sets multiplier for duration bonus (owner only).
// 8. setDecayRatePerSecond(uint256 rate): Sets base CP decay rate (owner only).
// 9. setDecayMultiplierPer10000Points(uint256 multiplier): Sets multiplier for score-based decay (owner only).
// 10. setMinStakeAmount(uint256 amount): Sets minimum stake amount (owner only).
// 11. stake(uint256 amount, uint256 durationInSeconds): Locks tokens to earn CP.
// 12. unstake(uint256 stakeId): Withdraws collateral, potentially forfeiting pending CP if early.
// 13. claimCredit(): Calculates and applies pending CP and decay to update score.
// 14. extendStakeDuration(uint256 stakeId, uint256 additionalDurationInSeconds): Adds time to a stake.
// 15. splitStake(uint256 stakeId, uint256 splitAmount): Divides a stake into two.
// 16. mergeStakes(uint256[] stakeIds, uint256 newDurationInSeconds): Combines stakes into a new one, adding earned CP from old ones.
// 17. getCreditScore(address user): Gets current decay-adjusted CP.
// 18. getPendingCredit(address user): Gets unclaimed CP from active stakes.
// 19. getTotalCreditEarned(address user): Gets total CP earned (non-decaying).
// 20. getStakes(address user): Gets list of user's stake IDs.
// 21. getStakeDetails(address user, uint256 stakeId): Gets details for a specific stake.
// 22. getCalculatedEarningRate(uint256 amount, uint256 durationInSeconds): Calculates potential earning rate for parameters.
// 23. getCalculatedDecayRate(uint256 currentScore): Calculates instantaneous decay rate for a score.
// 24. getSupportedCollateralToken(): Gets the supported token address.
// 25. getMinStakeAmount(): Gets the minimum stake amount.
// 26. redeemPointsForBenefit(uint256 pointsToRedeem): Example usage: spend CP.

contract ChronoCredit is Ownable, Pausable, ReentrancyGuard {

    // --- Custom Errors ---
    error ChronoCredit__StakeNotFound();
    error ChronoCredit__NotStakeOwner();
    error ChronoCredit__StakeNotYetEnded();
    error ChronoCredit__InsufficientBalance();
    error ChronoCredit__TransferFailed();
    error ChronoCredit__ApprovalFailed();
    error ChronoCredit__InvalidAmount();
    error ChronoCredit__MinimumStakeNotMet();
    error ChronoCredit__ZeroDuration();
    error ChronoCredit__StakeAlreadyEnded();
    error ChronoCredit__NotSupportedToken();
    error ChronoCredit__InsufficientCreditScore(uint256 required);
    error ChronoCredit__InvalidStakeIds();
    error ChronoCredit__SplitAmountTooLarge();
    error ChronoCredit__StakeInactive();

    // --- Structs ---
    struct StakeInfo {
        uint256 id; // Unique ID for the stake
        address owner; // The address of the staker
        uint256 amount; // The amount of collateral staked
        uint256 startTime; // Timestamp when the stake started
        uint256 duration; // Duration of the stake in seconds
        uint256 initialEarningRatePerSecond; // Calculated rate at stake creation
        address collateralToken; // Address of the staked token
        bool active; // Flag if the stake is currently active/earning
    }

    // --- State Variables ---

    // Admin/Config
    address private s_supportedCollateralToken;
    uint256 private s_defaultEarningRatePerSecond = 1; // Default CP per second per unit of token
    uint256 private s_earningRateMultiplierPerYearLocked = 100; // Additional % per full year locked (e.g., 100 means +1% per year)
    uint256 private s_decayRatePerSecond = 1; // Base CP decay per second (multiplied by score factor)
    uint256 private s_decayMultiplierPer10000Points = 5; // Additional decay multiplier per 10000 points (e.g., 5 means +0.05% decay per second per 10000 points)
    uint256 private s_minStakeAmount = 1e18; // Minimum amount to stake (e.g., 1 token assuming 18 decimals)

    // User Data
    mapping(address => uint256) private s_creditScores; // Current non-transferable credit points
    mapping(address => uint256) private s_lastCreditUpdateTime; // Timestamp of last score update/claim
    mapping(address => uint256) private s_totalCreditEarned; // Total credit ever earned (non-decaying history)
    mapping(address => mapping(uint256 => StakeInfo)) private s_stakes; // User stakes: userAddress => stakeId => StakeInfo
    mapping(address => uint256[]) private s_userStakeIds; // List of stake IDs for each user
    mapping(address => uint256) private s_nextStakeId; // Counter for unique stake IDs per user

    // Global counter for unique stake ID generation if needed globally (not used here)
    // uint256 private s_globalStakeCounter = 0;

    // Constants
    uint256 private constant SECONDS_IN_YEAR = 31536000; // Approximation for earning rate calculation

    // --- Events ---
    event StakeCreated(address indexed owner, uint256 stakeId, uint256 amount, uint256 duration, uint256 earningRate, address collateralToken);
    event StakeEnded(address indexed owner, uint256 stakeId, uint256 returnedAmount, bool earlyUnstake);
    event CreditClaimed(address indexed owner, uint256 pointsEarnedThisClaim, uint256 pointsDecayedThisClaim, uint255 currentScore);
    event StakeExtended(address indexed owner, uint256 stakeId, uint256 newDuration);
    event StakeSplit(address indexed owner, uint256 originalStakeId, uint256 newStakeId, uint256 splitAmount);
    event StakesMerged(address indexed owner, uint256[] originalStakeIds, uint256 newStakeId, uint256 mergedAmount, uint256 newDuration);
    event CreditPointsRedeemed(address indexed owner, uint256 pointsRedeemed);
    event ParamsUpdated(string paramName, uint256 newValue);

    // --- Modifiers ---
    modifier requireMinCreditScore(uint256 requiredScore) {
        if (getCreditScore(msg.sender) < requiredScore) {
            revert ChronoCredit__InsufficientCreditScore(requiredScore);
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Pausable/Ownable Functions ---
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Admin/Configuration Functions ---

    function setSupportedCollateralToken(address token) public onlyOwner {
        require(token != address(0), "Zero address not allowed");
        s_supportedCollateralToken = token;
        emit ParamsUpdated("SupportedCollateralToken", uint256(uint160(token)));
    }

    function setDefaultEarningRatePerSecond(uint256 rate) public onlyOwner {
        s_defaultEarningRatePerSecond = rate;
        emit ParamsUpdated("DefaultEarningRatePerSecond", rate);
    }

    function setEarningRateMultiplierPerYearLocked(uint256 multiplier) public onlyOwner {
        s_earningRateMultiplierPerYearLocked = multiplier;
        emit ParamsUpdated("EarningRateMultiplierPerYearLocked", multiplier);
    }

    function setDecayRatePerSecond(uint256 rate) public onlyOwner {
        s_decayRatePerSecond = rate;
        emit ParamsUpdated("DecayRatePerSecond", rate);
    }

    function setDecayMultiplierPer10000Points(uint256 multiplier) public onlyOwner {
        s_decayMultiplierPer10000Points = multiplier;
        emit ParamsUpdated("DecayMultiplierPer10000Points", multiplier);
    }

    function setMinStakeAmount(uint256 amount) public onlyOwner {
        s_minStakeAmount = amount;
        emit ParamsUpdated("MinStakeAmount", amount);
    }

    // --- Internal Helper Functions ---

    /// @dev Calculates and applies decay to the user's credit score.
    /// @param user The address of the user.
    function _updateCreditScore(address user) internal {
        uint256 currentTime = block.timestamp;
        uint256 lastUpdate = s_lastCreditUpdateTime[user];
        uint256 currentScore = s_creditScores[user];

        if (lastUpdate == 0) {
             // First interaction, set last update time without decay
            s_lastCreditUpdateTime[user] = currentTime;
            return;
        }

        uint256 timeElapsed = currentTime - lastUpdate;

        if (timeElapsed == 0) {
            // No time elapsed, no update needed
            return;
        }

        uint256 decayAmount = _calculateCurrentDecay(currentScore, timeElapsed);

        // Ensure decay doesn't make the score negative
        s_creditScores[user] = currentScore > decayAmount ? currentScore - decayAmount : 0;

        s_lastCreditUpdateTime[user] = currentTime;
    }

    /// @dev Calculates the pending credit points earned from all active stakes for a user.
    /// @param user The address of the user.
    /// @return The total pending credit points earned.
    function _calculatePendingCredit(address user) internal view returns (uint256) {
        uint256 totalPending = 0;
        uint256 currentTime = block.timestamp;
        uint256 lastUpdate = s_lastCreditUpdateTime[user]; // Points are calculated since last global update

        for (uint256 i = 0; i < s_userStakeIds[user].length; i++) {
            uint256 stakeId = s_userStakeIds[user][i];
            StakeInfo storage stake = s_stakes[user][stakeId];

            if (stake.active && stake.startTime < currentTime) {
                // Calculate points earned from this stake since the last global update or stake start time
                uint256 effectiveStartTime = lastUpdate > stake.startTime ? lastUpdate : stake.startTime;
                uint256 effectiveEndTime = stake.startTime + stake.duration;
                uint256 calculationEndTime = currentTime < effectiveEndTime ? currentTime : effectiveEndTime;

                if (calculationEndTime > effectiveStartTime) {
                    uint256 timeEarning = calculationEndTime - effectiveStartTime;
                    totalPending += stake.amount * stake.initialEarningRatePerSecond * timeEarning / 1e18; // Adjust for token decimals
                }
            }
        }
        return totalPending;
    }

    /// @dev Pure function to calculate potential decay amount.
    /// @param score The current credit score.
    /// @param timeElapsed The time duration in seconds.
    /// @return The calculated decay amount.
    function _calculateCurrentDecay(uint256 score, uint256 timeElapsed) internal view returns (uint256) {
        if (score == 0 || timeElapsed == 0 || s_decayRatePerSecond == 0) {
            return 0;
        }

        // Base decay: score * rate * time
        uint256 baseDecay = score * s_decayRatePerSecond * timeElapsed;

        // Score-based multiplier: (score / 10000) * multiplier / 10000
        // Total multiplier = 1 + (score * s_decayMultiplierPer10000Points / 10000) / 10000
        // To avoid fixed point math issues, combine:
        // Multiplier effect = score * s_decayMultiplierPer10000Points
        // Total decay = baseDecay + (baseDecay * multiplierEffect / 10000) / 10000
        // Simplified: score * rate * time * (1 + score * decayMultiplier / 100000000)
        // Let's use integer math carefully:
        // Decay factor = (score * s_decayMultiplierPer10000Points) / 10000
        // Total decay = baseDecay + (baseDecay * decayFactor / 10000)
        // Example: score 20k, multiplier 5. decayFactor = (20000 * 5) / 10000 = 10.
        // Total decay = baseDecay + (baseDecay * 10 / 10000) = baseDecay * (1 + 10/10000) = baseDecay * 1.001
        // This implies score 20k decays 0.1% faster per second base rate.

        // Check for potential overflow before multiplication
         if (score > type(uint256).max / timeElapsed / s_decayRatePerSecond) return type(uint256).max;
         if (score > type(uint256).max / s_decayMultiplierPer10000Points) return type(uint256).max;
         uint256 scoreDecayFactor = (score / 10000) * s_decayMultiplierPer10000Points; // Integer division is fine here for multiplier scaling

         // Recalculate base decay potentially after score update, or use initial score for calculation period
         // Using initial score for the whole period is simpler but less precise.
         // Using average score over period is ideal but complex. Let's use start score for simplicity.
         // Current score might be lower due to previous decay application in _updateCreditScore before this call.
         // Let's calculate based on the score passed in.

         uint256 totalDecay = (score * s_decayRatePerSecond * timeElapsed / 1e18); // Base decay scaled by amount unit
         uint256 scoreBoostedDecay = (totalDecay * scoreDecayFactor) / 10000; // Additional decay from score factor

         unchecked {
             return totalDecay + scoreBoostedDecay;
         }
    }


    /// @dev Pure function to calculate the effective earning rate per second for a new stake.
    /// @param amount The amount being staked.
    /// @param durationInSeconds The duration of the stake.
    /// @return The calculated initial earning rate per second (per unit of token).
    function _calculateEffectiveEarningRate(uint256 amount, uint256 durationInSeconds) internal view returns (uint256) {
        if (amount == 0 || durationInSeconds == 0 || s_defaultEarningRatePerSecond == 0) {
            return 0;
        }

        // Base rate: default rate per second
        uint256 baseRate = s_defaultEarningRatePerSecond; // CP per second per unit

        // Duration boost: multiplier * (duration in years)
        // Convert duration to approximate years: durationInSeconds / SECONDS_IN_YEAR
        // Boost percentage = s_earningRateMultiplierPerYearLocked * (durationInSeconds / SECONDS_IN_YEAR)
        // Effective rate = baseRate * (1 + boost percentage / 100)
        // Using integer math:
        // Boost factor = (durationInSeconds * s_earningRateMultiplierPerYearLocked) / SECONDS_IN_YEAR; // E.g., 1 year @ 100% = 100
        // Total rate = baseRate + (baseRate * boostFactor / 100); // E.g., baseRate * (1 + 100/100) = baseRate * 2

        uint256 durationBoostFactor = (durationInSeconds * s_earningRateMultiplierPerYearLocked) / SECONDS_IN_YEAR;

        unchecked {
             uint256 totalRate = baseRate + (baseRate * durationBoostFactor) / 100;
             return totalRate; // CP per second per unit
        }
    }

    // --- Core User Functions ---

    /// @notice Allows a user to stake collateral tokens to earn credit points.
    /// @param amount The amount of tokens to stake.
    /// @param durationInSeconds The duration for which to stake the tokens.
    function stake(uint256 amount, uint256 durationInSeconds) public nonReentrant whenNotPaused {
        if (s_supportedCollateralToken == address(0)) revert ChronoCredit__NotSupportedToken();
        if (amount == 0 || durationInSeconds == 0) revert ChronoCredit__InvalidAmount();
        if (amount < s_minStakeAmount) revert ChronoCredit__MinimumStakeNotMet();

        // Update credit score based on time elapsed before new stake calculation
        _updateCreditScore(msg.sender);

        // Transfer collateral tokens from the user
        // Requires user to have approved this contract first
        IERC20 token = IERC20(s_supportedCollateralToken);
        uint256 contractBalanceBefore = token.balanceOf(address(this));
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert ChronoCredit__TransferFailed();
        if (token.balanceOf(address(this)) != contractBalanceBefore + amount) revert ChronoCredit__TransferFailed(); // Double check

        // Create a new stake entry
        uint256 stakeId = s_nextStakeId[msg.sender]++;
        uint256 effectiveEarningRate = _calculateEffectiveEarningRate(amount, durationInSeconds);

        s_stakes[msg.sender][stakeId] = StakeInfo({
            id: stakeId,
            owner: msg.sender,
            amount: amount,
            startTime: block.timestamp,
            duration: durationInSeconds,
            initialEarningRatePerSecond: effectiveEarningRate,
            collateralToken: s_supportedCollateralToken,
            active: true
        });

        s_userStakeIds[msg.sender].push(stakeId);

        // Update last credit update time
        s_lastCreditUpdateTime[msg.sender] = block.timestamp;

        emit StakeCreated(msg.sender, stakeId, amount, durationInSeconds, effectiveEarningRate, s_supportedCollateralToken);
    }

    /// @notice Allows a user to unstake their collateral tokens.
    /// @param stakeId The ID of the stake to unstake.
    function unstake(uint256 stakeId) public nonReentrant whenNotPaused {
        StakeInfo storage stake = s_stakes[msg.sender][stakeId];

        if (stake.owner == address(0)) revert ChronoCredit__StakeNotFound();
        if (stake.owner != msg.sender) revert ChronoCredit__NotStakeOwner();
        if (!stake.active) revert ChronoCredit__StakeInactive();

        bool earlyUnstake = (block.timestamp < stake.startTime + stake.duration);

        // Update credit score based on time elapsed before unstake calculation
        // This applies decay and *implicitly* includes earned points up to the last update time.
        // The pending points from *this* specific stake since the last update are essentially forfeited if early unstake.
        // If not early, claimCredit should be called *before* or *after* unstake to get pending points.
        // Let's make it simple: unstaking *forfeits* pending points from *this specific stake* not yet claimed via claimCredit.
        // So, claimCredit() should be called first by the user if they want all pending points.
        // Here, we just update the global score based on decay up to now.
        _updateCreditScore(msg.sender);


        // Mark the stake as inactive immediately
        stake.active = false; // This stops future earning calculation for this stake

        // Remove stakeId from the user's list (can be gas intensive for large lists)
        // A simple swap-and-pop is more gas efficient than iterating and deleting.
        uint256[] storage userStakes = s_userStakeIds[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i] == stakeId) {
                // Swap with the last element and pop
                userStakes[i] = userStakes[userStakes.length - 1];
                userStakes.pop();
                break; // Found and removed
            }
        }
        // Note: The stake data in s_stakes[msg.sender][stakeId] remains, but is marked inactive and not in the user's list.

        // Transfer collateral back to the user
        IERC20 token = IERC20(stake.collateralToken);
        bool success = token.transfer(msg.sender, stake.amount);
        if (!success) revert ChronoCredit__TransferFailed();

        // Update last credit update time
        s_lastCreditUpdateTime[msg.sender] = block.timestamp;

        emit StakeEnded(msg.sender, stakeId, stake.amount, earlyUnstake);
    }

    /// @notice Calculates pending credit points from active stakes and applies decay, then updates the user's score.
    function claimCredit() public nonReentrant whenNotPaused {
        address user = msg.sender;
        uint256 currentTime = block.timestamp;
        uint256 lastUpdate = s_lastCreditUpdateTime[user];
        uint256 initialScore = s_creditScores[user];

        // 1. Apply decay based on time since last update
        _updateCreditScore(user); // This updates s_creditScores[user] and s_lastCreditUpdateTime[user]

        // Calculate decay amount that was just applied in _updateCreditScore
        uint256 scoreAfterDecay = s_creditScores[user];
        uint256 decayApplied = initialScore > scoreAfterDecay ? initialScore - scoreAfterDecay : 0;


        // 2. Calculate pending earned points from active stakes since the previous lastUpdate time
        // The _calculatePendingCredit function already calculates based on time elapsed since s_lastCreditUpdateTime[user]
        // which was just updated in _updateCreditScore to the current time.
        // So, we need to calculate pending points *before* _updateCreditScore changes lastUpdate,
        // or _calculatePendingCredit needs to use the *old* lastUpdate time.
        // Let's adjust _calculatePendingCredit to use a provided 'since' time.

        uint256 earnedPoints = 0;
         for (uint256 i = 0; i < s_userStakeIds[user].length; i++) {
            uint256 stakeId = s_userStakeIds[user][i];
            StakeInfo storage stake = s_stakes[user][stakeId];

            if (stake.active && stake.startTime < currentTime) {
                 // Calculate points earned from this stake since the OLD last update time
                 uint256 effectiveStartTime = lastUpdate > stake.startTime ? lastUpdate : stake.startTime;
                 uint256 effectiveEndTime = stake.startTime + stake.duration;
                 uint256 calculationEndTime = currentTime < effectiveEndTime ? currentTime : effectiveEndTime;

                 if (calculationEndTime > effectiveStartTime) {
                     uint256 timeEarning = calculationEndTime - effectiveStartTime;
                     earnedPoints += stake.amount * stake.initialEarningRatePerSecond * timeEarning / 1e18; // Adjust for token decimals
                 }
             }
         }

        // 3. Add earned points to the score
        s_creditScores[user] += earnedPoints;
        s_totalCreditEarned[user] += earnedPoints; // Add to total earned history

        // s_lastCreditUpdateTime was already updated in _updateCreditScore

        emit CreditClaimed(user, earnedPoints, decayApplied, s_creditScores[user]);
    }

    // --- Advanced User Functions ---

    /// @notice Allows a user to extend the duration of an existing stake.
    /// @param stakeId The ID of the stake to extend.
    /// @param additionalDurationInSeconds The number of seconds to add to the duration.
    function extendStakeDuration(uint256 stakeId, uint256 additionalDurationInSeconds) public whenNotPaused {
        StakeInfo storage stake = s_stakes[msg.sender][stakeId];

        if (stake.owner == address(0)) revert ChronoCredit__StakeNotFound();
        if (stake.owner != msg.sender) revert ChronoCredit__NotStakeOwner();
        if (!stake.active) revert ChronoCredit__StakeInactive();
        if (additionalDurationInSeconds == 0) revert ChronoCredit__ZeroDuration();

        // Update credit score before modifying stake
        _updateCreditScore(msg.sender);
        // Claim pending points up to now before extending
        claimCredit();

        stake.duration += additionalDurationInSeconds;
        // Note: Earning rate is based on *initial* duration, does not change.

        // Update last credit update time
        s_lastCreditUpdateTime[msg.sender] = block.timestamp;

        emit StakeExtended(msg.sender, stakeId, stake.duration);
    }

    /// @notice Allows a user to split an existing stake into two.
    /// @dev The original stake's amount is reduced, and a new stake is created.
    /// Both resulting stakes retain the original end time.
    /// @param stakeId The ID of the stake to split.
    /// @param splitAmount The amount to create as a new stake.
    function splitStake(uint256 stakeId, uint256 splitAmount) public whenNotPaused {
        StakeInfo storage originalStake = s_stakes[msg.sender][stakeId];

        if (originalStake.owner == address(0)) revert ChronoCredit__StakeNotFound();
        if (originalStake.owner != msg.sender) revert ChronoCredit__NotStakeOwner();
        if (!originalStake.active) revert ChronoCredit__StakeInactive();
        if (splitAmount == 0) revert ChronoCredit__InvalidAmount();
        if (splitAmount >= originalStake.amount) revert ChronoCredit__SplitAmountTooLarge();
         if (originalStake.amount - splitAmount < s_minStakeAmount && originalStake.amount - splitAmount > 0) {
             revert ChronoCredit__MinimumStakeNotMet(); // Ensure the remaining part is also above min if > 0
         }
         if (splitAmount < s_minStakeAmount) {
             revert ChronoCredit__MinimumStakeNotMet(); // Ensure the new split part is above min
         }


        // Update credit score and claim pending points before splitting
        _updateCreditScore(msg.sender);
        claimCredit();

        // Create the new stake entry
        uint256 newStakeId = s_nextStakeId[msg.sender]++;
        uint256 remainingAmount = originalStake.amount - splitAmount;
        uint256 remainingDuration = (originalStake.startTime + originalStake.duration) > block.timestamp
            ? (originalStake.startTime + originalStake.duration) - block.timestamp
            : 0; // Calculate remaining time

        // Calculate effective earning rate for the NEW stake based on its *new* duration (remaining time)
        // This might be different from the original stake's rate if the multiplier logic was based on initial total duration.
        // To keep it consistent with original stake's *terms*, let's use the original initial rate.
        // Alternative: Recalculate rate based on remainingDuration. Let's stick to using the original rate for simplicity/fairness based on initial commitment.
        uint256 effectiveEarningRateForSplit = originalStake.initialEarningRatePerSecond;


        s_stakes[msg.sender][newStakeId] = StakeInfo({
            id: newStakeId,
            owner: msg.sender,
            amount: splitAmount,
            startTime: block.timestamp, // New stake starts earning from now
            duration: remainingDuration, // New stake ends at the same time as the original
            initialEarningRatePerSecond: effectiveEarningRateForSplit,
            collateralToken: originalStake.collateralToken,
            active: true
        });

        s_userStakeIds[msg.sender].push(newStakeId);

        // Update the original stake
        originalStake.amount = remainingAmount;
        // Note: Original stake's start time and initial rate remain the same. Duration effectively reduced as end time is fixed.

        // Update last credit update time
        s_lastCreditUpdateTime[msg.sender] = block.timestamp;

        emit StakeSplit(msg.sender, stakeId, newStakeId, splitAmount);
    }

     /// @notice Allows a user to merge multiple stakes into a single new stake.
     /// @dev Old stakes are marked inactive, and a new stake is created with the combined amount.
     /// Points earned from the old stakes up to the merge time are added to the user's score.
     /// @param stakeIds The IDs of the stakes to merge.
     /// @param newDurationInSeconds The duration for the new, merged stake.
    function mergeStakes(uint256[] calldata stakeIds, uint256 newDurationInSeconds) public nonReentrant whenNotPaused {
         if (stakeIds.length <= 1) revert ChronoCredit__InvalidStakeIds();
         if (newDurationInSeconds == 0) revert ChronoCredit__ZeroDuration();

         // Update credit score and claim pending points for ALL stakes (including those being merged)
         // This ensures points earned up to now from the merging stakes are added.
         claimCredit(); // This calls _updateCreditScore internally

         uint256 totalMergedAmount = 0;
         address collateralToken = address(0);
         uint256[] memory validStakeIds = new uint256[](stakeIds.length);
         uint256 validCount = 0;

         // Validate stakes and sum amounts
         for (uint256 i = 0; i < stakeIds.length; i++) {
             uint256 currentId = stakeIds[i];
             StakeInfo storage stake = s_stakes[msg.sender][currentId];

             if (stake.owner == address(0) || stake.owner != msg.sender || !stake.active) {
                 // Ignore invalid, inactive, or non-owned stakes
                 continue;
             }
             if (collateralToken == address(0)) {
                 collateralToken = stake.collateralToken;
             } else if (stake.collateralToken != collateralToken) {
                 revert ChronoCredit__NotSupportedToken(); // Must merge stakes of the same token type
             }

             totalMergedAmount += stake.amount;
             validStakeIds[validCount++] = currentId;

             // Mark old stake as inactive
             stake.active = false;

             // Remove from user's list (can be optimized similar to unstake)
             // For simplicity here, we will rebuild the list later or leave inactive ones.
             // A robust implementation would remove them from s_userStakeIds efficiently.
             // Let's implement the swap-and-pop removal now for gas efficiency.
            uint256[] storage userStakes = s_userStakeIds[msg.sender];
            for (uint256 j = 0; j < userStakes.length; j++) {
                if (userStakes[j] == currentId) {
                    userStakes[j] = userStakes[userStakes.length - 1];
                    userStakes.pop();
                    break;
                }
            }
         }

         if (validCount < 2) revert ChronoCredit__InvalidStakeIds(); // Need at least 2 valid stakes to merge
         if (totalMergedAmount < s_minStakeAmount) revert ChronoCredit__MinimumStakeNotMet();

         // Create the new merged stake
         uint256 newStakeId = s_nextStakeId[msg.sender]++;
         uint256 effectiveEarningRateForNewStake = _calculateEffectiveEarningRate(totalMergedAmount, newDurationInSeconds);


         s_stakes[msg.sender][newStakeId] = StakeInfo({
             id: newStakeId,
             owner: msg.sender,
             amount: totalMergedAmount,
             startTime: block.timestamp, // New stake starts earning from now
             duration: newDurationInSeconds,
             initialEarningRatePerSecond: effectiveEarningRateForNewStake,
             collateralToken: collateralToken,
             active: true
         });

         s_userStakeIds[msg.sender].push(newStakeId); // Add the new stake ID

         // Update last credit update time
         s_lastCreditUpdateTime[msg.sender] = block.timestamp;

         // Emit event with only the valid IDs that were actually merged
         uint256[] memory mergedOriginalIds = new uint256[](validCount);
         for(uint256 i=0; i<validCount; i++) {
             mergedOriginalIds[i] = validStakeIds[i];
         }
         emit StakesMerged(msg.sender, mergedOriginalIds, newStakeId, totalMergedAmount, newDurationInSeconds);
    }


    // --- Query/Read Functions ---

    /// @notice Gets the current, decay-adjusted credit score for a user.
    /// @param user The address of the user.
    /// @return The user's current credit score.
    function getCreditScore(address user) public view returns (uint256) {
        uint256 currentScore = s_creditScores[user];
        uint256 lastUpdate = s_lastCreditUpdateTime[user];

        if (lastUpdate == 0 || currentScore == 0) {
            return currentScore; // No decay if score is zero or never updated
        }

        uint256 timeElapsed = block.timestamp - lastUpdate;
        if (timeElapsed == 0) {
             return currentScore; // No decay if no time elapsed
        }

        uint256 decayAmount = _calculateCurrentDecay(currentScore, timeElapsed);

        return currentScore > decayAmount ? currentScore - decayAmount : 0;
    }

     /// @notice Calculates the credit points earned from active stakes that haven't been claimed yet.
     /// Does NOT apply decay or update state.
     /// @param user The address of the user.
     /// @return The user's pending credit points.
    function getPendingCredit(address user) public view returns (uint256) {
         // Calculate points earned from active stakes since the last global update time
         uint256 totalPending = 0;
         uint256 currentTime = block.timestamp;
         uint256 lastUpdate = s_lastCreditUpdateTime[user]; // Points are calculated since last global update

         for (uint256 i = 0; i < s_userStakeIds[user].length; i++) {
             uint256 stakeId = s_userStakeIds[user][i];
             StakeInfo storage stake = s_stakes[user][stakeId];

             // Only consider active stakes that started before now
             if (stake.active && stake.startTime < currentTime) {
                 // Calculate points earned from this stake since the last global update time OR stake start time
                 uint256 effectiveStartTime = lastUpdate > stake.startTime ? lastUpdate : stake.startTime;
                 uint256 effectiveEndTime = stake.startTime + stake.duration;
                 uint256 calculationEndTime = currentTime < effectiveEndTime ? currentTime : effectiveEndTime;

                 if (calculationEndTime > effectiveStartTime) {
                     uint256 timeEarning = calculationEndTime - effectiveStartTime;
                     totalPending += stake.amount * stake.initialEarningRatePerSecond * timeEarning / 1e18; // Adjust for token decimals
                 }
             }
         }
         return totalPending;
    }

    /// @notice Gets the total credit points a user has ever earned (non-decaying).
    /// @param user The address of the user.
    /// @return The total credit earned.
    function getTotalCreditEarned(address user) public view returns (uint256) {
        return s_totalCreditEarned[user];
    }

    /// @notice Gets a list of all stake IDs belonging to a user.
    /// @param user The address of the user.
    /// @return An array of stake IDs.
    function getStakes(address user) public view returns (uint256[] memory) {
         return s_userStakeIds[user];
    }

    /// @notice Gets the detailed information for a specific stake.
    /// @param user The address of the stake owner.
    /// @param stakeId The ID of the stake.
    /// @return The StakeInfo struct details.
    function getStakeDetails(address user, uint256 stakeId) public view returns (StakeInfo memory) {
         // Check if stake exists and belongs to user
         StakeInfo memory stake = s_stakes[user][stakeId];
         if (stake.owner == address(0) || stake.owner != user) {
             revert ChronoCredit__StakeNotFound();
         }
         return stake;
    }

    /// @notice Helper to calculate the potential earning rate for a given stake amount and duration.
    /// @param amount The stake amount.
    /// @param durationInSeconds The stake duration.
    /// @return The calculated effective earning rate per second (per unit of token).
    function getCalculatedEarningRate(uint256 amount, uint256 durationInSeconds) public view returns (uint256) {
        return _calculateEffectiveEarningRate(amount, durationInSeconds);
    }

    /// @notice Helper to calculate the instantaneous decay rate for a given credit score.
    /// @param currentScore The credit score.
    /// @return The calculated instantaneous decay amount per second (scaled by score/amount unit).
    function getCalculatedDecayRate(uint256 currentScore) public view returns (uint256) {
         return _calculateCurrentDecay(currentScore, 1); // Calculate decay for 1 second
    }


    function getSupportedCollateralToken() public view returns (address) {
        return s_supportedCollateralToken;
    }

    function getDefaultEarningRatePerSecond() public view returns (uint256) {
        return s_defaultEarningRatePerSecond;
    }

    function getEarningRateMultiplierPerYearLocked() public view returns (uint256) {
        return s_earningRateMultiplierPerYearLocked;
    }

    function getDecayRatePerSecond() public view returns (uint256) {
        return s_decayRatePerSecond;
    }

    function getDecayMultiplierPer10000Points() public view returns (uint256) {
        return s_decayMultiplierPer10000Points;
    }

    function getMinStakeAmount() public view returns (uint256) {
        return s_minStakeAmount;
    }


    // --- Example Usage Functions ---

    /// @notice Example function showing how credit points can be spent.
    /// @param pointsToRedeem The number of credit points to spend.
    function redeemPointsForBenefit(uint256 pointsToRedeem) public whenNotPaused requireMinCreditScore(pointsToRedeem) nonReentrant {
         address user = msg.sender;

         // Update credit score based on time elapsed before spending
         _updateCreditScore(user);
         // Claim pending points to have the most current score available
         claimCredit();

         uint256 currentScore = s_creditScores[user];

         if (currentScore < pointsToRedeem) {
              // This should not happen if requireMinCreditScore is used, but good defensive check
             revert ChronoCredit__InsufficientCreditScore(pointsToRedeem);
         }

         s_creditScores[user] -= pointsToRedeem;

         emit CreditPointsRedeemed(user, pointsToRedeem);

         // Add logic here for what the benefit is...
         // e.g., unlock feature, get discount, receive a unique token, etc.
    }

    // --- Internal/Utility Functions (if any more needed) ---
    // No more internal functions explicitly listed in summary but needed for implementation

}
```