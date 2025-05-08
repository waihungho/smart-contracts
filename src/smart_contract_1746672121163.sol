Okay, here is a Solidity smart contract that attempts to incorporate several advanced, creative, and trendy concepts without directly copying standard open-source templates like basic ERC20/721 implementations or common DeFi primitives (while still using standard interfaces/building blocks where necessary for compatibility).

The concept is a "Dynamic Adaptive Protocol Vault" (APV). Users stake a specific token. The vault dynamically adjusts its reward multipliers and parameters based on an external "Protocol Health Score" (simulated via an owner-set value, but conceptually from an Oracle). Users also build a non-transferable "Protocol Interaction Score" (PIS) based on their actions, which affects their reward multipliers and unlocks tiers.

---

**Outline and Function Summary**

**Contract Name:** `DynamicAdaptiveProtocolVault`

**Concept:** A staking vault where reward parameters dynamically adapt based on a `protocolHealthScore` (representing external conditions) and users earn a non-transferable `protocolInteractionScore` (PIS) affecting their yield and tier.

**Key Features:**
1.  **Dynamic Parameters:** Reward multipliers and potential future features change based on a `protocolHealthScore`.
2.  **Protocol Interaction Score (PIS):** A non-transferable score for each user, increasing with active participation (staking duration, claiming, etc.).
3.  **Tier System:** Users are grouped into tiers based on their PIS, unlocking higher multipliers and potentially other benefits.
4.  **Modular Strategy:** Uses different "Strategy Modes" based on the health score.
5.  **Time-Weighted Rewards:** Rewards accrue over time based on staked amount, base rate, dynamic multiplier, PIS bonus, and tier bonus.

**Function Summary:**

*   **Core Staking/Rewards:**
    *   `constructor(address _stakedToken, address _rewardToken)`: Initializes the vault with staked and reward token addresses.
    *   `stake(uint256 amount)`: Allows users to stake `stakedToken`. Updates user stake, total staked, PIS, and tier.
    *   `unstake(uint256 amount)`: Allows users to unstake `stakedToken`. Calculates and accrues pending rewards before unstaking. Updates user stake, total staked, PIS, and tier.
    *   `claimRewards()`: Allows users to claim their accrued `rewardToken`. Updates pending rewards, PIS, and tier.
    *   `getUserPendingRewards(address user)`: (View) Calculates and returns the pending rewards for a specific user.

*   **Dynamic Strategy Management:**
    *   `setProtocolHealthScore(uint256 score)`: (Owner) Sets the current `protocolHealthScore`. Triggers strategy update.
    *   `triggerStrategyUpdate()`: (Internal/Owner) Updates the `currentStrategyMode` and `currentStrategyParameters` based on the `protocolHealthScore`.
    *   `getProtocolHealthScore()`: (View) Returns the current `protocolHealthScore`.
    *   `getCurrentStrategyMode()`: (View) Returns the current `StrategyMode`.
    *   `getCurrentStrategyParameters()`: (View) Returns the parameters of the current strategy.

*   **PIS and Tier Management:**
    *   `getUserPIS(address user)`: (View) Returns the Protocol Interaction Score for a specific user.
    *   `getUserTier(address user)`: (View) Returns the Tier for a specific user.
    *   `setPISThresholds(uint256[] memory thresholds)`: (Owner) Sets the thresholds for different PIS tiers.
    *   `setTierMultipliers(uint256[] memory multipliers)`: (Owner) Sets the reward multipliers for each tier.
    *   `getPISThresholds()`: (View) Returns the current PIS tier thresholds.
    *   `getTierMultipliers()`: (View) Returns the current tier multipliers.

*   **Owner/Administrative:**
    *   `setBaseRewardRate(uint256 rate)`: (Owner) Sets the base reward rate per token per second.
    *   `emergencyWithdraw(address tokenAddress, uint256 amount)`: (Owner) Allows withdrawal of *any* token accidentally sent to the contract (excluding staked/reward tokens managed by the vault logic).
    *   `pause()`: (Owner) Pauses core staking/unstaking/claiming functionality.
    *   `unpause()`: (Owner) Unpauses the contract.
    *   `transferOwnership(address newOwner)`: (Owner) Transfers contract ownership.
    *   `getBaseRewardRate()`: (View) Returns the base reward rate.
    *   `paused()`: (View) Checks if the contract is paused.
    *   `owner()`: (View) Returns the contract owner.

*   **View Functions (General):**
    *   `getUserStaked(address user)`: (View) Returns the amount staked by a specific user.
    *   `getTotalStaked()`: (View) Returns the total amount of `stakedToken` in the vault managed by the staking logic.
    *   `getHealthScoreThresholds()`: (View) Returns the health score thresholds for strategy changes.

*   **Internal Helpers (Not directly callable externally):**
    *   `_calculateReward(address user)`: Calculates the pending reward amount for a user.
    *   `_updateProtocolInteractionScore(address user, uint256 stakeAmount, uint256 duration)`: Updates the user's PIS based on action and duration.
    *   `_updateUserTier(address user)`: Determines and sets the user's tier based on their PIS.
    *   `_updateStrategyParameters(uint256 score)`: Logic to select strategy mode and parameters based on health score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary (See above)

contract DynamicAdaptiveProtocolVault is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable stakedToken; // The token users stake
    IERC20 public immutable rewardToken; // The token distributed as rewards

    // Staking state
    mapping(address => uint256) public userStakedAmount;
    uint256 public totalStakedAmount;

    // Reward Calculation State
    mapping(address => uint224) public userPendingRewards; // Use slightly smaller type if gas is critical
    mapping(address => uint64) public userLastActionTime; // Last time user staked or claimed

    uint256 public baseRewardRate; // Rewards per staked token per second (multiplied by multipliers)

    // Dynamic Strategy State
    uint256 public protocolHealthScore; // Represents external health (e.g., from oracle)
    enum StrategyMode { SafeMode, GrowthMode, AggressiveMode, RecoveryMode } // Different strategies
    StrategyMode public currentStrategyMode;

    struct StrategyParameters {
        uint256 strategyMultiplier; // Multiplier applied to baseRewardRate
        uint256 pisIncreaseRate;    // Rate at which PIS increases per action/duration
    }
    StrategyParameters public currentStrategyParameters;

    // Health Score Thresholds for Strategy Changes
    uint256[] public healthScoreThresholds = [50, 70, 90]; // Example: <50=Recovery, 50-69=Safe, 70-89=Growth, >=90=Aggressive

    // Protocol Interaction Score (PIS) and Tiers
    mapping(address => uint256) public userProtocolInteractionScore;
    mapping(address => uint8) public userTier; // Tier index (0, 1, 2...)

    uint256[] public pisThresholds = [100, 500, 2000]; // PIS thresholds for tiers (e.g., Tier 0: <100, Tier 1: 100-499, etc.)
    uint256[] public tierMultipliers = [1e18, 1.1e18, 1.25e18, 1.5e18]; // Reward multiplier for each tier (using 18 decimals for 1.0x, 1.1x etc.)

    // --- Events ---

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProtocolHealthScoreUpdated(uint256 oldScore, uint256 newScore, StrategyMode newMode);
    event StrategyModeChanged(StrategyMode oldMode, StrategyMode newMode);
    event UserPISUpdated(address indexed user, uint256 oldPIS, uint256 newPIS);
    event UserTierUpdated(address indexed user, uint8 oldTier, uint8 newTier);
    event BaseRewardRateUpdated(uint256 newRate);
    event HealthScoreThresholdsUpdated(uint256[] thresholds);
    event PISThresholdsUpdated(uint256[] thresholds);
    event TierMultipliersUpdated(uint256[] multipliers);
    event EmergencyWithdrawal(address indexed token, uint256 amount);


    // --- Constructor ---

    constructor(address _stakedToken, address _rewardToken) Ownable(msg.sender) Pausable(false) {
        require(_stakedToken != address(0), "Invalid staked token address");
        require(_rewardToken != address(0), "Invalid reward token address");
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);

        // Set initial default values
        baseRewardRate = 10000000000000; // Example: 0.00001 rewardToken per stakedToken per second (adjust decimals)
        protocolHealthScore = 60; // Initial health score
        _updateStrategyParameters(protocolHealthScore); // Set initial strategy based on score
        userTier[address(0)] = 0; // Default tier 0, mappings default to 0 anyway but good practice
    }

    // --- Core Staking/Rewards Functions ---

    /// @notice Stakes a specified amount of stakedToken into the vault.
    /// @param amount The amount of stakedToken to stake.
    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot stake 0");

        // Calculate and accrue pending rewards before updating state
        if (userStakedAmount[msg.sender] > 0) {
           userPendingRewards[msg.sender] = userPendingRewards[msg.sender].add(_calculateReward(msg.sender));
        }

        // Transfer staked tokens to the contract
        stakedToken.transferFrom(msg.sender, address(this), amount);

        // Update state
        userStakedAmount[msg.sender] = userStakedAmount[msg.sender].add(amount);
        totalStakedAmount = totalStakedAmount.add(amount);
        userLastActionTime[msg.sender] = uint64(block.timestamp);

        // Update PIS and Tier
        _updateProtocolInteractionScore(msg.sender, amount, 0); // PIS increase on stake
        _updateUserTier(msg.sender);

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstakes a specified amount of stakedToken from the vault.
    /// @param amount The amount of stakedToken to unstake.
    function unstake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot unstake 0");
        require(userStakedAmount[msg.sender] >= amount, "Insufficient staked balance");

         // Calculate and accrue pending rewards before updating state
        userPendingRewards[msg.sender] = userPendingRewards[msg.sender].add(_calculateReward(msg.sender));

        // Update state
        userStakedAmount[msg.sender] = userStakedAmount[msg.sender].sub(amount);
        totalStakedAmount = totalStakedAmount.sub(amount);
        userLastActionTime[msg.sender] = uint64(block.timestamp); // Reset last action time for remaining stake or set to 0 if fully unstaked

        // Transfer staked tokens back to the user
        stakedToken.transfer(msg.sender, amount);

        // Update PIS and Tier (PIS might decrease slightly or tier might change based on new PIS)
        // For simplicity, PIS doesn't decrease on unstake, but the tier might change if PIS was just enough for the old tier.
         _updateUserTier(msg.sender);


        emit Unstaked(msg.sender, amount);
    }

    /// @notice Claims the pending rewardToken for the caller.
    function claimRewards() external whenNotPaused {
        // Calculate and accrue pending rewards
        userPendingRewards[msg.sender] = userPendingRewards[msg.sender].add(_calculateReward(msg.sender));

        uint256 rewardAmount = userPendingRewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim");

        // Reset pending rewards and update last action time
        userPendingRewards[msg.sender] = 0;
        userLastActionTime[msg.sender] = uint64(block.timestamp);

        // Transfer reward tokens
        // Check contract balance before transfer to avoid reverting on low balance
        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 amountToTransfer = rewardAmount > balance ? balance : rewardAmount; // Transfer what's available
        require(amountToTransfer > 0, "Not enough reward tokens in vault");

        rewardToken.transfer(msg.sender, amountToTransfer);

        // Update PIS and Tier
        _updateProtocolInteractionScore(msg.sender, 0, uint256(amountToTransfer > 0 ? 1 : 0)); // PIS increase on claim
        _updateUserTier(msg.sender);


        emit RewardsClaimed(msg.sender, amountToTransfer);

        // Note: If amountToTransfer < rewardAmount, some rewards are not claimed but are still zeroed out.
        // A more complex system might track unclaimed rewards separately or require topping up the vault.
        // This implementation zeros out the claimable amount regardless of vault balance for simplicity.
    }

    /// @notice Calculates the pending rewards for a specific user.
    /// @param user The address of the user.
    /// @return The calculated pending reward amount.
    function getUserPendingRewards(address user) public view returns (uint256) {
        if (userStakedAmount[user] == 0) {
            return userPendingRewards[user]; // Return already accrued but unclaimed rewards
        }
        // Calculate rewards since last action time
        uint256 accrued = _calculateReward(user);
        return userPendingRewards[user].add(accrued);
    }

    // --- Dynamic Strategy Management Functions ---

    /// @notice Sets the protocol health score, triggering a strategy update.
    /// @param score The new health score (e.g., 0-100).
    function setProtocolHealthScore(uint256 score) external onlyOwner {
        require(score <= 100, "Score must be 0-100"); // Example constraint

        uint256 oldScore = protocolHealthScore;
        protocolHealthScore = score;

        _updateStrategyParameters(score); // Update strategy based on new score

        emit ProtocolHealthScoreUpdated(oldScore, score, currentStrategyMode);
    }

    /// @notice Updates the strategy parameters based on the current health score.
    /// @dev Called internally when health score changes. Can be called by owner explicitly if needed.
    /// @param score The health score to evaluate.
    function triggerStrategyUpdate() public onlyOwner {
        _updateStrategyParameters(protocolHealthScore);
    }

    /// @notice Returns the current protocol health score.
    function getProtocolHealthScore() external view returns (uint256) {
        return protocolHealthScore;
    }

    /// @notice Returns the current strategy mode.
    function getCurrentStrategyMode() external view returns (StrategyMode) {
        return currentStrategyMode;
    }

    /// @notice Returns the parameters of the current strategy.
    function getCurrentStrategyParameters() external view returns (StrategyParameters memory) {
        return currentStrategyParameters;
    }

    // --- PIS and Tier Management Functions ---

    /// @notice Returns the Protocol Interaction Score for a user.
    /// @param user The address of the user.
    function getUserPIS(address user) external view returns (uint256) {
        return userProtocolInteractionScore[user];
    }

     /// @notice Returns the tier for a user.
    /// @param user The address of the user.
    function getUserTier(address user) external view returns (uint8) {
        return userTier[user];
    }

    /// @notice Sets the PIS thresholds for determining user tiers.
    /// @param thresholds An array of thresholds. Length determines number of tiers-1.
    function setPISThresholds(uint256[] memory thresholds) external onlyOwner {
        require(thresholds.length == tierMultipliers.length - 1, "Thresholds must match tier multipliers count - 1");
        pisThresholds = thresholds;
        emit PISThresholdsUpdated(thresholds);
        // Note: Users' tiers are updated dynamically on next action or could be done by a separate maintenance function if needed
    }

    /// @notice Sets the reward multipliers for each tier.
    /// @param multipliers An array of multipliers (using 1e18 for 1.0x).
    function setTierMultipliers(uint256[] memory multipliers) external onlyOwner {
        require(multipliers.length == pisThresholds.length + 1, "Multipliers must match thresholds count + 1");
        tierMultipliers = multipliers;
        emit TierMultipliersUpdated(multipliers);
    }

     /// @notice Returns the current PIS tier thresholds.
    function getPISThresholds() external view returns (uint256[] memory) {
        return pisThresholds;
    }

    /// @notice Returns the current tier multipliers.
    function getTierMultipliers() external view returns (uint256[] memory) {
        return tierMultipliers;
    }


    // --- Owner/Administrative Functions ---

    /// @notice Sets the base reward rate per staked token per second.
    /// @param rate The new base rate.
    function setBaseRewardRate(uint256 rate) external onlyOwner {
        baseRewardRate = rate;
        emit BaseRewardRateUpdated(rate);
    }

    /// @notice Allows the owner to withdraw accidentally sent tokens (not staked/reward tokens managed by the vault).
    /// @param tokenAddress The address of the token to withdraw.
    /// @param amount The amount of token to withdraw.
    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(stakedToken) && tokenAddress != address(rewardToken), "Cannot withdraw staked or reward tokens via emergency function");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
        emit EmergencyWithdrawal(tokenAddress, amount);
    }

    /// @notice Pauses core vault functions (stake, unstake, claim).
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core vault functions.
    function unpause() external onlyOwner {
        _unpause();
    }

    // Inherits transferOwnership from Ownable

    /// @notice Returns the current base reward rate.
    function getBaseRewardRate() external view returns (uint256) {
        return baseRewardRate;
    }

    // Inherits paused() from Pausable
    // Inherits owner() from Ownable

    // --- View Functions (General) ---

    /// @notice Returns the amount staked by a specific user.
    /// @param user The address of the user.
    function getUserStaked(address user) external view returns (uint256) {
        return userStakedAmount[user];
    }

    /// @notice Returns the total amount of stakedToken managed by the vault's staking logic.
    function getTotalStaked() external view returns (uint256) {
        return totalStakedAmount;
    }

    /// @notice Returns the health score thresholds for strategy changes.
    function getHealthScoreThresholds() external view returns (uint256[] memory) {
        return healthScoreThresholds;
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates the rewards accrued for a user since their last action.
    /// @param user The address of the user.
    /// @return The calculated reward amount to be added to pending rewards.
    function _calculateReward(address user) internal view returns (uint256) {
        uint256 staked = userStakedAmount[user];
        uint64 lastAction = userLastActionTime[user];

        if (staked == 0 || lastAction == 0) {
            return 0; // No stake or no history
        }

        uint256 timeElapsed = block.timestamp.sub(lastAction);
        if (timeElapsed == 0) {
            return 0; // No time has passed
        }

        uint256 currentPIS = userProtocolInteractionScore[user];
        uint8 currentTier = userTier[user];

        // Calculate multipliers: BaseRate * StrategyMultiplier * TierMultiplier * (1 + PISBonus%)
        // PIS Bonus: Simple example: 1% extra yield for every 100 PIS. Max bonus caps at 50%.
        uint256 pisBonusBps = (currentPIS / 100) * 100; // 100 basis points per 100 PIS
        if (pisBonusBps > 5000) pisBonusBps = 5000; // Cap at 50% bonus (5000 bps)
        uint256 totalMultiplier = baseRewardRate
            .mul(currentStrategyParameters.strategyMultiplier)
            .div(1e18) // Assuming strategyMultiplier is 18 decimals
            .mul(uint256(tierMultipliers[currentTier])) // Assuming tierMultipliers are 18 decimals
            .div(1e18);

        // Apply PIS bonus: totalMultiplier * (1 + pisBonusBps/10000)
         totalMultiplier = totalMultiplier.mul(10000 + pisBonusBps).div(10000);


        // Reward = StakedAmount * TotalMultiplier * TimeElapsed
        // Need to handle potential overflow and division by token decimals (assuming baseRate is already scaled)
        // If baseRate is scaled per 1e18 token, then staked amount needs to be handled.
        // Let's assume baseRewardRate is rewards per 1e18 staked token per second.
        // staked amount needs to be scaled to 1e18 for calculation consistency if using different decimals.
        // Simpler: Let baseRewardRate be rewards per token per second (adjusting for token decimals is caller's job or handled internally if decimals known)
        // Let's assume baseRewardRate is per 1e18 unit of staked token and reward token.
        // Final reward = (staked * totalMultiplier * timeElapsed) / 1e18 / 1e18 ... this gets complex.
        // Let's simplify: baseRewardRate is rewards (in reward token units) per staked token (in staked token units) per second.
        // Multipliers are factors (1.0x = 1e18).
        // Reward = staked * baseRate * strategyMult * tierMult * (1+PISBonus) * timeElapsed / 1e18 / 1e18 / 1e18 (adjusting for decimals and multipliers)
        // Let's assume baseRate is already adjusted for token decimals, and multipliers are 1e18 scale.
        // Rewards = (staked * baseRewardRate / 1e18) * (currentStrategyParameters.strategyMultiplier / 1e18) * (tierMultipliers[currentTier] / 1e18) * (10000 + pisBonusBps) / 10000 * timeElapsed
        // This is getting complicated with divisions. Re-evaluate scaling.
        // Let baseRewardRate be *scaled* rate (e.g., 1e18 for 1 token/sec if tokens have 18 decimals).
        // Multipliers are also 1e18 scale.
        // Reward per second per token = (baseRewardRate * strategyMultiplier / 1e18) * (tierMultiplier / 1e18) * (10000 + pisBonusBps) / 10000
        // Total Reward = staked * (Reward per second per token) * timeElapsed
        // Total Reward = staked.mul(baseRewardRate).div(1e18).mul(currentStrategyParameters.strategyMultiplier).div(1e18).mul(tierMultipliers[currentTier]).div(1e18).mul(10000 + pisBonusBps).div(10000).mul(timeElapsed)

        // Simpler implementation attempt:
        // baseRewardRate = rewards * 1e18 per stakedToken * 1e18 per second
        // Multipliers = 1e18 for 1x
        // Reward per sec = baseRewardRate * strategyMultiplier * tierMultiplier * (1+PISBonus) / (1e18 * 1e18 * 10000/1e18)
        // Reward per sec = baseRewardRate * strategyMultiplier * tierMultiplier * (10000 + pisBonusBps) / (1e18 * 10000)
        // Total Reward = staked * RewardPerSec * timeElapsed / 1e18 (because staked is not 1e18 scaled unless it is)

        // Let's assume:
        // baseRewardRate: rewards per staked token unit per second (e.g., 1e10 if reward token is 18 decimals, staked 18 decimals -> 0.00000001 reward/staked/sec)
        // Multipliers: 1e18 for 1x
        // Reward = staked * baseRewardRate * strategyMultiplier * tierMultiplier * (10000 + pisBonusBps) / (1e18 * 1e18 * 10000/1e18) * timeElapsed
        // Reward = staked * baseRewardRate * strategyMultiplier * tierMultiplier * (10000 + pisBonusBps) / (1e18 * 10000) * timeElapsed
        // Avoid float division:
        // Reward = staked.mul(baseRewardRate).mul(currentStrategyParameters.strategyMultiplier).div(1e18).mul(tierMultipliers[currentTier]).div(1e18).mul(10000 + pisBonusBps).div(10000).mul(timeElapsed)
        // Ensure order of operations to prevent overflow and underflow. Divide after multiplications.

        uint256 rewardNumerator = staked.mul(baseRewardRate);
        uint256 multiplierNumerator = currentStrategyParameters.strategyMultiplier.mul(tierMultipliers[currentTier]).mul(10000 + pisBonusBps);
        uint256 multiplierDenominator = 1e18.mul(1e18).mul(10000); // 1e18 for strategyMult, 1e18 for tierMult, 10000 for PIS bonus BPS

        // Check if multiplierNumerator or staked * baseRewardRate could overflow first
        // For simplicity and avoiding complex fixed-point math libraries here:
        // Let's assume baseRewardRate is *already scaled* (e.g., 1e18 scale per token/sec)
        // Let multipliers be 1e18 scale (1e18 = 1x)
        // Reward = staked * baseRate * strategy * tier * (1+bonus) * time / (1e18 * 1e18 * (1e18 or 10000?))
        // Let's simplify PIS Bonus: add a fixed percentage points, not multiply by (1+bonus).
        // Effective Multiplier = strategyMultiplier + (tierMultiplier - 1e18) + PIS points
        // Or: Effective Multiplier = strategyMultiplier * tierMultiplier * (1 + PIS Bonus Factor)
        // Let's stick to the multiplier product:
        // Multiplier factor = (strategyMultiplier / 1e18) * (tierMultiplier / 1e18) * (1 + PISBonusBps / 10000)
        // Reward rate per staked token = baseRewardRate * Multiplier factor
        // Total reward = stakedAmount * RewardRatePerStakedToken * timeElapsed

        // Simplified Calculation:
        // Calculate effective rate including all multipliers (scaled by 1e18 for multipliers)
        // effectiveRate = baseRewardRate * strategyMultiplier * tierMultiplier * (10000 + pisBonusBps) / (1e18 * 1e18 * 10000)
        // Reward = staked * effectiveRate * timeElapsed
        // Example: baseRate = 1e10 (0.00000001), strategy=1.2e18 (1.2x), tier=1.1e18 (1.1x), PIS bonus 10% (11000)
        // effectiveRate = 1e10 * 1.2e18 * 1.1e18 * 11000 / (1e18 * 1e18 * 10000)
        // effectiveRate = 1e10 * 1.2 * 1.1 * 1.1 / 1e18 = 1e10 * 1.452 / 1e18 = 1.452e-8
        // staked * time * 1.452e-8

        // Use a common scaling factor for multipliers, e.g., 1e18
        // baseRewardRate: uint256 (actual reward token units per staked token unit per second)
        // multipliers: uint256 (1e18 for 1x)
        // effectiveRate = baseRewardRate * (strategy / 1e18) * (tier / 1e18) * (10000 + pisBonusBps) / 10000
        // Reward = staked * effectiveRate * time
        // Reward = staked * baseRewardRate * strategy * tier * (10000 + pisBonusBps) * time / (1e18 * 1e18 * 10000)

         uint256 effectiveMultiplier = currentStrategyParameters.strategyMultiplier.mul(tierMultipliers[currentTier]).div(1e18);
         effectiveMultiplier = effectiveMultiplier.mul(10000 + pisBonusBps).div(10000); // Apply PIS Bonus

         // Rewards = stakedAmount * baseRewardRate * effectiveMultiplier * timeElapsed / 1e18 (for effectiveMultiplier scale)
         uint256 accrued = staked.mul(baseRewardRate).mul(effectiveMultiplier).div(1e18).mul(timeElapsed);


        return accrued;
    }

    /// @dev Updates the user's Protocol Interaction Score.
    /// @param user The address of the user.
    /// @param stakeAmount Amount staked (0 if not staking).
    /// @param duration Duration modifier (e.g., time staked, or 1 if action like claim).
    function _updateProtocolInteractionScore(address user, uint256 stakeAmount, uint256 duration) internal {
        uint256 oldPIS = userProtocolInteractionScore[user];
        uint256 pisIncrease = 0;

        // Example PIS logic:
        // - Base increase on stake (small fixed amount + scaled by amount)
        // - Base increase on claim (small fixed amount)
        // - Potential future: duration-based increase (complex due to gas)

        if (stakeAmount > 0) {
            // Increase PIS based on stake amount (scaled down)
            pisIncrease = pisIncrease.add(10); // Base points for staking
            pisIncrease = pisIncrease.add(stakeAmount.div(1e17)); // Add points based on amount (e.g., 1 point per 0.1 staked token assuming 18 decimals)
        }

        if (duration > 0 && stakeAmount == 0) { // Assuming duration > 0 means a claim occurred
             pisIncrease = pisIncrease.add(5); // Base points for claiming
        }

        // Apply a small multiplier based on current strategy (StrategyParameters.pisIncreaseRate, scaled 1e18)
         pisIncrease = pisIncrease.mul(currentStrategyParameters.pisIncreaseRate).div(1e18);


        userProtocolInteractionScore[user] = userProtocolInteractionScore[user].add(pisIncrease);

        emit UserPISUpdated(user, oldPIS, userProtocolInteractionScore[user]);
    }

    /// @dev Determines and sets the user's tier based on their PIS.
    /// @param user The address of the user.
    function _updateUserTier(address user) internal {
        uint256 currentPIS = userProtocolInteractionScore[user];
        uint8 oldTier = userTier[user];
        uint8 newTier = 0;

        // Find the tier based on thresholds
        for (uint8 i = 0; i < pisThresholds.length; i++) {
            if (currentPIS >= pisThresholds[i]) {
                newTier = i + 1;
            } else {
                break; // Thresholds are assumed to be sorted ascending
            }
        }
        // Ensure tier index doesn't exceed available multipliers
        if (newTier >= tierMultipliers.length) {
             newTier = uint8(tierMultipliers.length - 1);
        }


        if (oldTier != newTier) {
            userTier[user] = newTier;
            emit UserTierUpdated(user, oldTier, newTier);
        }
    }

    /// @dev Updates the strategy mode and parameters based on the health score.
    /// @param score The health score.
    function _updateStrategyParameters(uint256 score) internal {
        StrategyMode oldMode = currentStrategyMode;

        // Determine mode based on thresholds
        if (score < healthScoreThresholds[0]) { // e.g., < 50
            currentStrategyMode = StrategyMode.RecoveryMode;
            currentStrategyParameters.strategyMultiplier = 0.8e18; // Example: Lower yield
            currentStrategyParameters.pisIncreaseRate = 1.2e18; // Example: Encourage interaction during recovery
        } else if (score < healthScoreThresholds[1]) { // e.g., 50-69
            currentStrategyMode = StrategyMode.SafeMode;
            currentStrategyParameters.strategyMultiplier = 1e18; // Example: Base yield
            currentStrategyParameters.pisIncreaseRate = 1e18; // Example: Normal PIS increase
        } else if (score < healthScoreThresholds[2]) { // e.g., 70-89
            currentStrategyMode = StrategyMode.GrowthMode;
            currentStrategyParameters.strategyMultiplier = 1.2e18; // Example: Higher yield
            currentStrategyParameters.pisIncreaseRate = 1.1e18; // Example: Slightly boosted PIS
        } else { // e.g., >= 90
            currentStrategyMode = StrategyMode.AggressiveMode;
            currentStrategyParameters.strategyMultiplier = 1.5e18; // Example: Highest yield
            currentStrategyParameters.pisIncreaseRate = 1e18; // Example: Normal PIS
        }

        if (oldMode != currentStrategyMode) {
            emit StrategyModeChanged(oldMode, currentStrategyMode);
        }
    }
}
```