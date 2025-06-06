Okay, let's design a smart contract implementing a "Multi-Dimensional Yield Farm" with advanced concepts.

This concept combines traditional yield farming with additional dimensions that influence yield calculation:
1.  **Staked Amount & Time:** Standard yield farming base.
2.  **NFT Boost:** Users holding specific NFTs can apply a multiplier to their yield.
3.  **Activity Score:** Users earn points for performing certain actions (staking, compounding, claiming), and this score acts as another yield multiplier.
4.  **Dynamic Parameters:** Owner/Governance (conceptually, though implemented as owner for simplicity) can adjust base rates, boost levels, and score weights.

This requires tracking user-specific state beyond just the staked amount, incorporating external contract calls (ERC721 for NFT check), and implementing complex, time-based reward calculation based on multiple factors.

**Advanced Concepts Used:**
*   **Multi-Dimensional Yield Calculation:** Yield isn't just linear `amount * time`.
*   **NFT Integration:** Using ERC721 ownership to influence DeFi mechanics.
*   **On-Chain Activity Scoring:** Gamifying yield farming by rewarding interaction.
*   **Dynamic Parameters:** Allowing adjustment of key contract variables.
*   **Time-Based Calculations:** Handling reward accumulation over time.
*   **Internal State Management:** Tracking complex user data (amount, time, score, NFT boost).

---

**Outline:**

1.  **License and Version Pragma**
2.  **Imports:** IERC20, IERC721, Ownable, ReentrancyGuard, Pausable
3.  **Error Definitions**
4.  **Interfaces:** IERC20, IERC721 (minimal needed)
5.  **Contract Definition:** MultiDimensionalYieldFarm
6.  **State Variables:**
    *   Token Addresses (Staked, Reward, Boost NFT)
    *   User Stake Info Mapping (Struct containing amount, start/last updated time, activity score, active NFT TokenId, pending rewards)
    *   Global Parameters (Base reward rate, NFT boost percentage, Activity score weight, minimum stake time for boost, points awarded for actions)
    *   Ownership, Pausability, ReentrancyGuard states
7.  **Events:** Staked, Withdrawn, Claimed, Compounded, NFTBoostApplied, NFTBoostRemoved, ActivityScoreUpdated, ParametersUpdated, TokensRescued
8.  **Structs:** StakeInfo
9.  **Constructor:** Initialize owner and token addresses.
10. **Modifiers:** whenNotPaused, onlyOwner
11. **Internal Calculation Helpers:**
    *   `_calculatePendingRewards(address user)`: Calculates rewards accumulated since `lastUpdateTime`.
    *   `_updateStakeRewardCalculation(address user)`: Calls calculation helper and updates user's state.
    *   `_getEffectiveBoostMultiplier(address user)`: Calculates the combined boost based on NFT ownership, activity score, and minimum stake time.
    *   `_updateActivityScore(address user, uint256 pointsToAdd)`: Adds points to user's activity score.
12. **User Functions (External/Public):**
    *   `stake(uint256 amount)`
    *   `withdraw(uint256 amount)`
    *   `claim()`
    *   `compound()`
    *   `applyNFTBoost(uint256 tokenId)`
    *   `removeNFTBoost()`
13. **View Functions (External/Public):**
    *   `getPendingRewards(address user)`
    *   `getUserStakeInfo(address user)`
    *   `getNFTBoostMultiplier(address user)`
    *   `getActivityScore(address user)`
    *   `getBaseRewardRate()`
    *   `getNFTBoostPercentage()`
    *   `getActivityScoreWeight()`
    *   `getMinimumStakeTimeForBoost()`
    *   `getActivityPoints()`
    *   `getStakedToken()`
    *   `getRewardToken()`
    *   `getBoostNFTContract()`
14. **Owner/Admin Functions (External/Public, onlyOwner):**
    *   `setBaseRewardRate(uint256 ratePerSecond)`
    *   `setActivityPoints(uint256 stakePoints, uint256 compoundPoints, uint256 claimPoints, uint256 withdrawPoints)`
    *   `setNFTBoostPercentage(uint256 boostPercentage)`
    *   `setActivityScoreWeight(uint256 weight)`
    *   `setBoostNFTContract(address _nftContract)`
    *   `setMinimumStakeTimeForBoost(uint256 timeInSeconds)`
    *   `pause()`
    *   `unpause()`
    *   `inCaseTokensStuck(address tokenAddress, uint256 amount)`

---

**Function Summary:**

1.  **`stake(uint256 amount)`:** Allows a user to deposit staked tokens into the farm. Updates user's stake amount, starts/updates staking timer, calculates rewards up to this point, and updates activity score.
2.  **`withdraw(uint256 amount)`:** Allows a user to withdraw staked tokens. Calculates rewards up to this point, reduces stake amount, transfers tokens, and updates activity score.
3.  **`claim()`:** Allows a user to claim accrued rewards. Calculates rewards up to this point, transfers pending rewards, and updates activity score.
4.  **`compound()`:** Allows a user to claim accrued rewards and automatically restake them. Calculates rewards, adds them to the stake amount, and updates activity score.
5.  **`applyNFTBoost(uint256 tokenId)`:** Allows a user who owns a boost NFT to associate it with their stake to receive a yield multiplier. Verifies ownership and updates user's stake info.
6.  **`removeNFTBoost()`:** Allows a user to remove an applied NFT boost.
7.  **`getPendingRewards(address user)`:** *View function* to calculate and return the total pending rewards for a user without claiming.
8.  **`getUserStakeInfo(address user)`:** *View function* to retrieve the full staking information for a user.
9.  **`getNFTBoostMultiplier(address user)`:** *View function* to calculate and return the current effective NFT boost multiplier for a user, considering NFT ownership and minimum stake time.
10. **`getActivityScore(address user)`:** *View function* to return the current activity score for a user.
11. **`getBaseRewardRate()`:** *View function* to get the current base reward rate per second.
12. **`getNFTBoostPercentage()`:** *View function* to get the percentage used for the NFT boost.
13. **`getActivityScoreWeight()`:** *View function* to get the weight applied to the activity score for calculation.
14. **`getMinimumStakeTimeForBoost()`:** *View function* to get the minimum required stake time for boosts to apply.
15. **`getActivityPoints()`:** *View function* to get the points awarded for different user actions.
16. **`getStakedToken()`:** *View function* to get the address of the staked token.
17. **`getRewardToken()`:** *View function* to get the address of the reward token.
18. **`getBoostNFTContract()`:** *View function* to get the address of the registered boost NFT contract.
19. **`setBaseRewardRate(uint256 ratePerSecond)`:** *Owner function* to set the base reward rate per second.
20. **`setActivityPoints(uint256 stakePoints, uint256 compoundPoints, uint256 claimPoints, uint256 withdrawPoints)`:** *Owner function* to set the points awarded for each activity type.
21. **`setNFTBoostPercentage(uint256 boostPercentage)`:** *Owner function* to set the yield boost percentage applied by an active NFT.
22. **`setActivityScoreWeight(uint256 weight)`:** *Owner function* to set the weight applied to the activity score in the yield calculation.
23. **`setBoostNFTContract(address _nftContract)`:** *Owner function* to set the address of the approved boost NFT contract.
24. **`setMinimumStakeTimeForBoost(uint256 timeInSeconds)`:** *Owner function* to set the minimum stake duration required for boosts to take effect.
25. **`pause()`:** *Owner function* to pause core user interactions.
26. **`unpause()`:** *Owner function* to unpause the contract.
27. **`inCaseTokensStuck(address tokenAddress, uint256 amount)`:** *Owner function* to rescue tokens accidentally sent to the contract, excluding staked/reward tokens.

*(Note: This list already exceeds 20 functions, fulfilling the requirement.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though 0.8+ has overflow checks, SafeMath can add clarity for certain calculations if preferred, but not strictly necessary here. Let's stick to native checks for simplicity.

// Custom Errors
error MultiDimensionalYieldFarm__StakeAmountZero();
error MultiDimensionalYieldFarm__WithdrawAmountZero();
error MultiDimensionalYieldFarm__InsufficientStake(uint256 requested, uint256 available);
error MultiDimensionalYieldFarm__InsufficientRewardToken(uint256 requested, uint256 available);
error MultiDimensionalYieldFarm__RewardTokenTransferFailed();
error MultiDimensionalYieldFarm__StakedTokenTransferFailed();
error MultiDimensionalYieldFarm__InvalidNFTContract();
error MultiDimensionalYieldFarm__NFTNotOwned();
error MultiDimensionalYieldFarm__BoostNFTContractNotSet();
error MultiDimensionalYieldFarm__CannotRescueStakedOrRewardToken();

/**
 * @title MultiDimensionalYieldFarm
 * @dev A yield farming contract where yield is influenced by staked amount, time,
 *      holding a specific NFT, and user activity score. Parameters can be adjusted by the owner.
 *
 * Outline:
 * 1. License and Version Pragma
 * 2. Imports (ERC20, ERC721, Ownable, ReentrancyGuard, Pausable)
 * 3. Error Definitions (Custom errors for clarity)
 * 4. Interfaces (Minimal IERC20, IERC721)
 * 5. Contract Definition
 * 6. State Variables (Token addresses, User stake mapping, Global parameters, etc.)
 * 7. Events (Staked, Withdrawn, Claimed, Compounded, NFTBoost, ActivityScore, ParametersUpdated, Rescue)
 * 8. Structs (StakeInfo)
 * 9. Constructor (Initializes owner and tokens)
 * 10. Modifiers (whenNotPaused, onlyOwner)
 * 11. Internal Calculation & State Update Helpers
 * 12. User Functions (stake, withdraw, claim, compound, applyNFTBoost, removeNFTBoost)
 * 13. View Functions (getPendingRewards, getUserStakeInfo, getNFTBoostMultiplier, getActivityScore, parameter getters)
 * 14. Owner/Admin Functions (set parameters, pause/unpause, rescue tokens)
 */
contract MultiDimensionalYieldFarm is Ownable, ReentrancyGuard, Pausable {

    // --- State Variables ---

    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    IERC721 public boostNFTContract;

    struct StakeInfo {
        uint256 amount; // Amount of staked tokens
        uint256 startTime; // Timestamp when stake was first created (or last compounded)
        uint256 lastUpdateTime; // Last timestamp rewards were calculated/updated
        uint256 activityScore; // Accumulated activity score
        uint256 activeNFTBoostTokenId; // Token ID of the NFT providing boost (0 if none)
        uint256 pendingRewards; // Rewards calculated but not yet claimed
    }

    mapping(address => StakeInfo) public userStakeInfo;

    // Global Parameters (adjustable by owner)
    uint256 public baseRewardRatePerSecond; // Base reward per staked token per second (scaled, e.g., 1e18)
    uint256 public nftBoostPercentage; // Percentage boost from holding NFT (e.g., 10000 for 100%, 5000 for 50%)
    uint256 public activityScoreWeight; // Weight applied to activity score (e.g., 10000 for 1x influence, 5000 for 0.5x)
    uint256 public minimumStakeTimeForBoost; // Minimum time a stake must exist for boosts to apply (in seconds)

    // Points awarded for specific actions
    struct ActivityPoints {
        uint256 stake;
        uint256 compound;
        uint256 claim;
        uint256 withdraw;
    }
    ActivityPoints public activityPoints;

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newTotalStake);
    event Withdrawn(address indexed user, uint256 amount, uint256 newTotalStake);
    event Claimed(address indexed user, uint256 rewardAmount);
    event Compounded(address indexed user, uint256 rewardAmountCompounded, uint256 newTotalStake);
    event NFTBoostApplied(address indexed user, uint256 tokenId);
    event NFTBoostRemoved(address indexed user, uint256 oldTokenId);
    event ActivityScoreUpdated(address indexed user, uint256 pointsAdded, uint256 newScore);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event TokensRescued(address indexed token, address indexed receiver, uint256 amount);

    // --- Constructor ---

    constructor(
        address _stakedToken,
        address _rewardToken,
        address initialOwner
    )
        Ownable(initialOwner)
    {
        require(_stakedToken != address(0) && _rewardToken != address(0), "Invalid token addresses");
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);

        // Initialize default parameters (can be changed by owner)
        baseRewardRatePerSecond = 0;
        nftBoostPercentage = 0; // Default: no boost
        activityScoreWeight = 0; // Default: activity score has no weight
        minimumStakeTimeForBoost = 0; // Default: boosts apply immediately
        activityPoints = ActivityPoints(10, 20, 5, 5); // Default points
    }

    // --- Internal Calculation & State Update Helpers ---

    /**
     * @dev Calculates rewards accumulated for a user since their last update time.
     * @param user The address of the user.
     * @return The amount of rewards accumulated in this interval.
     */
    function _calculatePendingRewards(address user) internal view returns (uint256) {
        StakeInfo storage stake = userStakeInfo[user];
        if (stake.amount == 0 || baseRewardRatePerSecond == 0) {
            return 0;
        }

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - stake.lastUpdateTime;

        if (timeElapsed == 0) {
            return 0; // No time has passed since last calculation
        }

        // Base reward: amount * rate * time
        uint256 baseReward = (stake.amount * baseRewardRatePerSecond * timeElapsed) / 1e18; // Assuming rate is scaled

        // Calculate effective boost multiplier
        uint256 effectiveBoostMultiplier = _getEffectiveBoostMultiplier(user);

        // Apply boost: baseReward * (1 + boostMultiplier/10000)
        // This is equivalent to baseReward + (baseReward * boostMultiplier / 10000)
        uint256 boostedReward = baseReward + (baseReward * effectiveBoostMultiplier) / 10000;

        return boostedReward;
    }

    /**
     * @dev Calculates rewards accumulated up to the current time and updates the user's state.
     * Should be called before any action that modifies the stake state (stake, withdraw, claim, compound, etc.).
     * Adds calculated rewards to `pendingRewards` and updates `lastUpdateTime`.
     * @param user The address of the user.
     */
    function _updateStakeRewardCalculation(address user) internal {
        StakeInfo storage stake = userStakeInfo[user];
        uint256 accumulated = _calculatePendingRewards(user);
        if (accumulated > 0) {
            stake.pendingRewards += accumulated;
        }
        stake.lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Calculates the effective yield boost multiplier for a user.
     * Considers NFT boost (if applicable and owned, and minimum stake time met)
     * and Activity Score boost (if minimum stake time met).
     * The total multiplier is `(nftBoostPercentage + (activityScore * activityScoreWeight / 1e4))`.
     * @param user The address of the user.
     * @return The total boost multiplier in percentage points (e.g., 15000 for 150%).
     */
    function _getEffectiveBoostMultiplier(address user) internal view returns (uint256) {
        StakeInfo storage stake = userStakeInfo[user];
        uint256 currentTimestamp = block.timestamp;

        // Check if minimum stake time is met for boosts to apply
        bool minTimeMet = (minimumStakeTimeForBoost == 0 || (stake.startTime > 0 && currentTimestamp - stake.startTime >= minimumStakeTimeForBoost));

        uint256 totalBoost = 0;

        // 1. NFT Boost
        if (stake.activeNFTBoostTokenId > 0 && address(boostNFTContract) != address(0) && minTimeMet) {
            // Verify user still owns the registered NFT token
            try boostNFTContract.ownerOf(stake.activeNFTBoostTokenId) returns (address nftOwner) {
                 if (nftOwner == user) {
                    totalBoost += nftBoostPercentage;
                 }
            } catch {
                 // NFT contract call failed (e.g., token doesn't exist or contract is broken)
                 // Treat as no NFT boost applied for this calculation
            }
        }

        // 2. Activity Score Boost
        // Activity score contributes based on weight, applied if min time is met
        if (activityScoreWeight > 0 && stake.activityScore > 0 && minTimeMet) {
            // contribution = activityScore * activityScoreWeight / 1e4
            totalBoost += (stake.activityScore * activityScoreWeight) / 1e4;
        }

        return totalBoost;
    }

    /**
     * @dev Updates the activity score for a user. Called internally after core actions.
     * @param user The address of the user.
     * @param pointsToAdd The points to add to the user's score.
     */
    function _updateActivityScore(address user, uint256 pointsToAdd) internal {
        if (pointsToAdd > 0) {
            userStakeInfo[user].activityScore += pointsToAdd;
            emit ActivityScoreUpdated(user, pointsToAdd, userStakeInfo[user].activityScore);
        }
    }

    // --- User Functions ---

    /**
     * @dev Stakes tokens in the farm.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert MultiDimensionalYieldFarm__StakeAmountZero();

        address user = msg.sender;
        StakeInfo storage stake = userStakeInfo[user];

        // Calculate and update pending rewards before changing stake
        _updateStakeRewardCalculation(user);

        uint256 currentStake = stake.amount;

        // Transfer tokens from user to contract
        bool success = stakedToken.transferFrom(user, address(this), amount);
        if (!success) revert MultiDimensionalYieldFarm__StakedTokenTransferFailed();

        // Update stake amount
        stake.amount += amount;

        // If this is the first stake, set the start time
        if (currentStake == 0) {
            stake.startTime = block.timestamp;
        }
        // Ensure lastUpdateTime is current timestamp after calculation
        stake.lastUpdateTime = block.timestamp;

        // Update activity score
        _updateActivityScore(user, activityPoints.stake);

        emit Staked(user, amount, stake.amount);
    }

    /**
     * @dev Withdraws tokens from the farm.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert MultiDimensionalYieldFarm__WithdrawAmountZero();

        address user = msg.sender;
        StakeInfo storage stake = userStakeInfo[user];

        if (amount > stake.amount) revert MultiDimensionalYieldFarm__InsufficientStake(amount, stake.amount);

        // Calculate and update pending rewards before changing stake
        _updateStakeRewardCalculation(user);

        // Update stake amount
        stake.amount -= amount;

        // Transfer tokens back to user
        bool success = stakedToken.transfer(user, amount);
        if (!success) revert MultiDimensionalYieldFarm__StakedTokenTransferFailed();

        // Reset start time if stake becomes zero
        if (stake.amount == 0) {
            stake.startTime = 0;
            stake.activeNFTBoostTokenId = 0; // Remove NFT boost if stake is zero
        }
        // Ensure lastUpdateTime is current timestamp after calculation
         stake.lastUpdateTime = block.timestamp;

        // Update activity score
        _updateActivityScore(user, activityPoints.withdraw);

        emit Withdrawn(user, amount, stake.amount);
    }

    /**
     * @dev Claims pending rewards.
     */
    function claim() external nonReentrant whenNotPaused {
        address user = msg.sender;
        StakeInfo storage stake = userStakeInfo[user];

        // Calculate and update pending rewards
        _updateStakeRewardCalculation(user);

        uint256 rewardsToClaim = stake.pendingRewards;
        if (rewardsToClaim == 0) {
            // No rewards to claim, just update timestamp if stake > 0
            if (stake.amount > 0) {
                 stake.lastUpdateTime = block.timestamp;
            }
            return; // Exit early if no rewards
        }

        // Reset pending rewards
        stake.pendingRewards = 0;

        // Transfer rewards to user
        // Check contract balance before transfer
        uint256 contractRewardBalance = rewardToken.balanceOf(address(this));
        if (rewardsToClaim > contractRewardBalance) revert MultiDimensionalYieldFarm__InsufficientRewardToken(rewardsToClaim, contractRewardBalance);

        bool success = rewardToken.transfer(user, rewardsToClaim);
        if (!success) revert MultiDimensionalYieldFarm__RewardTokenTransferFailed();

        // Ensure lastUpdateTime is current timestamp after calculation
        stake.lastUpdateTime = block.timestamp;

        // Update activity score
        _updateActivityScore(user, activityPoints.claim);

        emit Claimed(user, rewardsToClaim);
    }

    /**
     * @dev Claims pending rewards and restakes them as staked tokens.
     * Requires reward token to be the same as staked token.
     * This is a simplified compound assuming stakedToken == rewardToken.
     * For different tokens, a swap mechanism would be needed, which adds significant complexity.
     * Let's add a check that they must be the same.
     */
    function compound() external nonReentrant whenNotPaused {
        require(address(stakedToken) == address(rewardToken), "Compounding only allowed if staked and reward tokens are the same");

        address user = msg.sender;
        StakeInfo storage stake = userStakeInfo[user];

        // Calculate and update pending rewards
        _updateStakeRewardCalculation(user);

        uint256 rewardsToCompound = stake.pendingRewards;
        if (rewardsToCompound == 0) {
            // No rewards to compound, just update timestamp if stake > 0
            if (stake.amount > 0) {
                 stake.lastUpdateTime = block.timestamp;
            }
            return; // Exit early if no rewards
        }

        // Reset pending rewards
        stake.pendingRewards = 0;

        // Add rewards to stake amount
        // This is safe because rewardsToCompound is added to stake.amount, which is uint256
        stake.amount += rewardsToCompound;

        // Reset start time as if it's a new stake from now (common compounding mechanic)
        stake.startTime = block.timestamp;
        // Ensure lastUpdateTime is current timestamp after calculation
        stake.lastUpdateTime = block.timestamp;

        // Update activity score
        _updateActivityScore(user, activityPoints.compound);

        emit Compounded(user, rewardsToCompound, stake.amount);
    }

    /**
     * @dev Applies the NFT boost using a specific token ID.
     * User must own the token ID from the registered boost NFT contract.
     * Calling this multiple times will overwrite the previously applied token ID.
     * @param tokenId The ID of the NFT token to use for the boost.
     */
    function applyNFTBoost(uint256 tokenId) external nonReentrant whenNotPaused {
        address user = msg.sender;
        StakeInfo storage stake = userStakeInfo[user];

        if (address(boostNFTContract) == address(0)) revert MultiDimensionalYieldFarm__BoostNFTContractNotSet();

        // Check if the user owns the NFT
        try boostNFTContract.ownerOf(tokenId) returns (address nftOwner) {
            if (nftOwner != user) revert MultiDimensionalYieldFarm__NFTNotOwned();
        } catch {
            revert MultiDimensionalYieldFarm__NFTNotOwned(); // Revert if NFT contract call fails or token doesn't exist
        }

        // Calculate and update pending rewards before applying new boost
        _updateStakeRewardCalculation(user);

        // Set the active NFT boost token ID
        uint256 oldTokenId = stake.activeNFTBoostTokenId;
        stake.activeNFTBoostTokenId = tokenId;

        // Ensure lastUpdateTime is current timestamp after calculation
        stake.lastUpdateTime = block.timestamp;

        emit NFTBoostApplied(user, tokenId);
        // Optionally emit Removed event if an old one was replaced
        if (oldTokenId != 0 && oldTokenId != tokenId) {
             emit NFTBoostRemoved(user, oldTokenId);
        }
    }

     /**
     * @dev Removes the currently applied NFT boost.
     * This simply sets the active NFT token ID to 0.
     */
    function removeNFTBoost() external nonReentrant whenNotPaused {
        address user = msg.sender;
        StakeInfo storage stake = userStakeInfo[user];

         if (stake.activeNFTBoostTokenId == 0) {
             // No boost to remove
             return;
         }

        // Calculate and update pending rewards before removing boost
        _updateStakeRewardCalculation(user);

        uint256 oldTokenId = stake.activeNFTBoostTokenId;
        stake.activeNFTBoostTokenId = 0;

        // Ensure lastUpdateTime is current timestamp after calculation
        stake.lastUpdateTime = block.timestamp;

        emit NFTBoostRemoved(user, oldTokenId);
    }

    // --- View Functions ---

    /**
     * @dev Gets the total pending rewards for a user (calculated up to the current block.timestamp).
     * This function does NOT update the user's state.
     * @param user The address of the user.
     * @return The total pending rewards for the user.
     */
    function getPendingRewards(address user) external view returns (uint256) {
        StakeInfo storage stake = userStakeInfo[user];
        // Calculate rewards since last update, add to stored pending rewards
        return stake.pendingRewards + _calculatePendingRewards(user);
    }

     /**
     * @dev Gets the effective boost multiplier for a user, recalculated live.
     * @param user The address of the user.
     * @return The effective boost multiplier in percentage points.
     */
    function getNFTBoostMultiplier(address user) external view returns (uint256) {
        return _getEffectiveBoostMultiplier(user);
    }

    /**
     * @dev Gets the current activity score for a user.
     * @param user The address of the user.
     * @return The user's activity score.
     */
    function getActivityScore(address user) external view returns (uint256) {
        return userStakeInfo[user].activityScore;
    }

    /**
     * @dev Gets the current base reward rate per second.
     */
    function getBaseRewardRate() external view returns (uint256) {
        return baseRewardRatePerSecond;
    }

    /**
     * @dev Gets the current NFT boost percentage.
     */
    function getNFTBoostPercentage() external view returns (uint256) {
        return nftBoostPercentage;
    }

    /**
     * @dev Gets the current activity score weight.
     */
    function getActivityScoreWeight() external view returns (uint256) {
        return activityScoreWeight;
    }

    /**
     * @dev Gets the current minimum stake time required for boosts.
     */
    function getMinimumStakeTimeForBoost() external view returns (uint256) {
        return minimumStakeTimeForBoost;
    }

     /**
     * @dev Gets the current activity points awarded for actions.
     */
    function getActivityPoints() external view returns (ActivityPoints memory) {
        return activityPoints;
    }

    /**
     * @dev Gets the staked token address.
     */
    function getStakedToken() external view returns (address) {
        return address(stakedToken);
    }

    /**
     * @dev Gets the reward token address.
     */
    function getRewardToken() external view returns (address) {
        return address(rewardToken);
    }

     /**
     * @dev Gets the boost NFT contract address.
     */
    function getBoostNFTContract() external view returns (address) {
        return address(boostNFTContract);
    }


    // --- Owner/Admin Functions ---

    /**
     * @dev Sets the base reward rate per second.
     * @param ratePerSecond The new base reward rate (scaled, e.g., 1e18).
     */
    function setBaseRewardRate(uint256 ratePerSecond) external onlyOwner {
        emit ParametersUpdated("baseRewardRatePerSecond", baseRewardRatePerSecond, ratePerSecond);
        baseRewardRatePerSecond = ratePerSecond;
    }

    /**
     * @dev Sets the points awarded for different user actions.
     * @param stakePoints Points for staking.
     * @param compoundPoints Points for compounding.
     * @param claimPoints Points for claiming.
     * @param withdrawPoints Points for withdrawing.
     */
    function setActivityPoints(uint256 stakePoints, uint256 compoundPoints, uint256 claimPoints, uint256 withdrawPoints) external onlyOwner {
        activityPoints.stake = stakePoints;
        activityPoints.compound = compoundPoints;
        activityPoints.claim = claimPoints;
        activityPoints.withdraw = withdrawPoints;
        // Emit a generic event for parameters update, specific values can be logged
        emit ParametersUpdated("activityPoints.stake", 0, stakePoints); // Using 0 for old value as it's a struct update
        emit ParametersUpdated("activityPoints.compound", 0, compoundPoints);
        emit ParametersUpdated("activityPoints.claim", 0, claimPoints);
        emit ParametersUpdated("activityPoints.withdraw", 0, withdrawPoints);
    }


    /**
     * @dev Sets the percentage boost applied by an active NFT.
     * @param boostPercentage The new boost percentage (e.g., 10000 for 100%).
     */
    function setNFTBoostPercentage(uint256 boostPercentage) external onlyOwner {
         // Basic sanity check, prevent excessively high boost
         require(boostPercentage <= 1_000_000, "Boost percentage too high"); // Max 100x boost (1,000,000 / 10,000)
        emit ParametersUpdated("nftBoostPercentage", nftBoostPercentage, boostPercentage);
        nftBoostPercentage = boostPercentage;
    }

    /**
     * @dev Sets the weight applied to the activity score in the yield calculation.
     * @param weight The new weight (e.g., 10000 for 1x).
     */
    function setActivityScoreWeight(uint256 weight) external onlyOwner {
         // Basic sanity check, prevent excessively high weight
         require(weight <= 1_000_000, "Activity weight too high"); // Max 100x weight per point
        emit ParametersUpdated("activityScoreWeight", activityScoreWeight, weight);
        activityScoreWeight = weight;
    }

    /**
     * @dev Sets the address of the approved boost NFT contract.
     * @param _nftContract The address of the ERC721 contract.
     */
    function setBoostNFTContract(address _nftContract) external onlyOwner {
         if (_nftContract == address(0)) revert MultiDimensionalYieldFarm__InvalidNFTContract();
        // Optional: Add a check here that the address is actually a contract
        emit ParametersUpdated("boostNFTContract", uint256(uint160(address(boostNFTContract))), uint256(uint160(_nftContract))); // Log addresses as uint256
        boostNFTContract = IERC721(_nftContract);
    }

    /**
     * @dev Sets the minimum stake time required for boosts (NFT and Activity Score) to apply.
     * @param timeInSeconds Minimum time in seconds.
     */
    function setMinimumStakeTimeForBoost(uint256 timeInSeconds) external onlyOwner {
         emit ParametersUpdated("minimumStakeTimeForBoost", minimumStakeTimeForBoost, timeInSeconds);
         minimumStakeTimeForBoost = timeInSeconds;
    }

    /**
     * @dev Pauses the contract, preventing core user actions.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, enabling core user actions.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to rescue any tokens sent to the contract by mistake,
     *      except for the staked token and reward token.
     * @param tokenAddress The address of the token to rescue.
     * @param amount The amount of tokens to rescue.
     */
    function inCaseTokensStuck(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(stakedToken) || tokenAddress == address(rewardToken)) {
            revert MultiDimensionalYieldFarm__CannotRescueStakedOrRewardToken();
        }
        IERC20 stuckToken = IERC20(tokenAddress);
        uint256 contractBalance = stuckToken.balanceOf(address(this));
        require(amount <= contractBalance, "Insufficient stuck token balance");

        bool success = stuckToken.transfer(owner(), amount);
        require(success, "Stuck token transfer failed");

        emit TokensRescued(tokenAddress, owner(), amount);
    }
}
```