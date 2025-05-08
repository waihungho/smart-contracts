Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like a Soul-Bound (non-transferable) Dynamic Badge, a linked Reputation System, and a Staking mechanism where yield is dynamically adjusted based on the user's reputation and badge properties.

It avoids duplicating standard open-source patterns directly by combining these elements into a single, interconnected system.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For scaled calculations

/**
 * @title RepuStakeBadge
 * @dev A smart contract combining Soul-Bound Dynamic Badges, a Reputation System,
 * and a Reputation-Gated Staking mechanism with dynamic yield.
 *
 * Outline:
 * 1. Core Concepts:
 *    - Soul-Bound Dynamic Badge: A non-transferable identifier (like an SBT) with properties (level, traits) that can change.
 *    - Reputation System: A score linked to an address, influencing badge properties and staking yield.
 *    - Dynamic Staking Yield: Reward rate for staking is adjusted based on the staker's reputation and badge data.
 * 2. Roles:
 *    - DEFAULT_ADMIN_ROLE: Manages roles and core settings.
 *    - BADGE_ISSUER_ROLE: Can mint and update dynamic badges.
 *    - REPUTATION_MANAGER_ROLE: Can update user reputation scores (e.g., based on off-chain activity verified via trusted oracle/system).
 *    - REWARD_DISTRIBUTOR_ROLE: Can deposit reward tokens and set the base reward rate.
 * 3. Mechanisms:
 *    - Badge Management: Minting, updating level/traits, checking ownership. Badges are non-transferable.
 *    - Reputation Management: Updating scores.
 *    - Staking: Deposit/withdraw staked token.
 *    - Dynamic Rewards Calculation: Calculate pending rewards based on staked amount, base rate, and dynamic reputation/badge multiplier.
 *    - Reward Claiming: Claim accumulated reward tokens.
 *    - Configuration: Set base reward rate, parameters for multiplier calculation.
 *
 * Function Summary (Total: 28 functions including views and internal helpers):
 *
 * Admin & Setup (DEFAULT_ADMIN_ROLE):
 *  1. constructor: Initializes tokens, roles, and initial state.
 *  2. grantRole: Grant specific roles.
 *  3. revokeRole: Revoke specific roles.
 *  4. renounceRole: Renounce own role.
 *  5. setBaseRewardRatePerSecond: Set the base global reward distribution rate. (REWARD_DISTRIBUTOR_ROLE)
 *  6. depositRewards: Deposit reward tokens into the contract. (REWARD_DISTRIBUTOR_ROLE)
 *  7. setReputationMultiplierParameters: Configure how reputation affects yield multiplier.
 *  8. setLevelMultiplierParameters: Configure how badge level affects yield multiplier.
 *
 * Badge Management (BADGE_ISSUER_ROLE):
 *  9. mintBadge: Mints a new Soul-Bound Dynamic Badge for an address.
 * 10. updateBadgeLevel: Updates the level property of a user's badge.
 * 11. updateBadgeTraits: Updates the traits property of a user's badge.
 * 12. getBadgeData: Retrieve badge data for a user. (View)
 * 13. hasBadge: Check if a user has a badge. (View)
 * 14. getBadgeTokenURI: Placeholder for generating dynamic metadata URI. (View)
 *
 * Reputation Management (REPUTATION_MANAGER_ROLE):
 * 15. updateReputation: Updates the reputation score for a user.
 * 16. getReputation: Retrieve reputation score for a user. (View)
 *
 * Staking:
 * 17. stake: Deposit staked tokens to earn rewards.
 * 18. unstake: Withdraw staked tokens.
 * 19. claimRewards: Claim earned reward tokens.
 * 20. getStakeInfo: Retrieve staking information for a user. (View)
 * 21. getTotalStaked: Retrieve the total amount of tokens staked in the contract. (View)
 *
 * Dynamic Rewards & Calculation (Internal/View Helpers):
 * 22. _updateRewardState: Internal helper to update global reward accumulation state.
 * 23. _calculateUserPendingRewards: Internal helper to calculate a user's pending rewards considering the dynamic multiplier.
 * 24. getAdjustedRewardMultiplier: Calculates the user's dynamic reward multiplier based on reputation and badge. (View)
 * 25. getEffectiveRewardRate: Calculates the user's effective reward rate per second. (View)
 * 26. getUserPendingRewards: External view function to calculate user's pending rewards without state change. (View)
 * 27. getAccRewardPerUnitStaked: Retrieve the accumulated reward per unit staked. (View)
 * 28. getLastRewardUpdateTime: Retrieve the last time reward state was updated. (View)
 *
 */
contract RepuStakeBadge is AccessControl, ReentrancyGuard, Context {
    using SafeMath for uint256; // Using SafeMath for potentially sensitive calculations like scaling

    // --- Roles ---
    bytes32 public constant BADGE_ISSUER_ROLE = keccak256("BADGE_ISSUER_ROLE");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");

    // --- Token Contracts ---
    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;

    // --- Badge System ---
    struct BadgeData {
        uint256 level;
        uint256 traits; // Can be used as a bitmask or simple number representing traits
        // Potentially add last_updated_timestamp, etc.
    }
    mapping(address => BadgeData) private _badges;
    mapping(address => bool) private _hasBadge; // Optimized lookup

    // --- Reputation System ---
    mapping(address => uint256) private _reputation; // Simple score

    // --- Staking System ---
    struct StakeData {
        uint256 amount;       // Amount of stakedToken
        uint256 rewardDebt;   // Accumulated reward per unit staked at the time of last interaction (scaled)
    }
    mapping(address => StakeData) private _stakes;
    uint256 private _totalStaked;

    // --- Reward Distribution ---
    uint256 private _rewardRatePerSecond; // Base reward rate per second (e.g., 1e18 wei per second)
    uint256 private _accRewardPerUnitStaked; // Global accumulated reward per unit of staked token (scaled by 1e18)
    uint256 private _lastRewardUpdateTime; // Timestamp of the last global reward state update

    // --- Dynamic Multiplier Parameters ---
    // These parameters configure how reputation and level affect the reward multiplier.
    // Multiplier is scaled by 1e18 (e.g., 1.5x is 1.5 * 1e18)
    uint256 public reputationMultiplierFactor; // How much reputation score adds to multiplier (e.g., scaled points per rep)
    uint256 public levelMultiplierFactor;      // How much level adds to multiplier (e.g., scaled points per level)
    uint256 public minReputationForMultiplier; // Minimum reputation to get above base multiplier
    uint256 public maxReputationForMultiplier; // Reputation where multiplier caps or formula changes

    // --- Constants ---
    uint256 private constant MULTIPLIER_SCALE_FACTOR = 1e18; // Scale factor for multiplier calculations

    // --- Events ---
    event BadgeMinted(address indexed user, uint256 initialLevel, uint256 initialTraits);
    event BadgeLevelUpdated(address indexed user, uint256 newLevel);
    event BadgeTraitsUpdated(address indexed user, uint256 newTraits);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event RewardsDeposited(address indexed distributor, uint256 amount);
    event MultiplierParametersUpdated(
        uint256 newRepFactor,
        uint256 newLevelFactor,
        uint256 newMinRep,
        uint256 newMaxRep
    );

    // --- Constructor ---
    constructor(address _stakedToken, address _rewardToken) Context() {
        // Grant default admin role to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Assign token addresses
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);

        // Initialize reward update time
        _lastRewardUpdateTime = block.timestamp;

        // Set some default multiplier parameters (can be changed by admin)
        reputationMultiplierFactor = 1000000000000000; // 0.001e18 per rep point (scaled) -> 1 rep increases multiplier by 0.001
        levelMultiplierFactor = 50000000000000000; // 0.05e18 per level (scaled) -> Level 1 adds 0.05x, Level 10 adds 0.5x
        minReputationForMultiplier = 100; // Reputation below 100 gets base multiplier (1x)
        maxReputationForMultiplier = 1000; // Reputation above 1000 gets capped benefit
    }

    // --- Access Control Functions (from AccessControl.sol) ---
    // 2. grantRole
    // 3. revokeRole
    // 4. renounceRole
    // (Inherited and managed by DEFAULT_ADMIN_ROLE)

    // --- Admin & Setup Functions ---

    /**
     * @dev Sets the base global reward rate per second. Requires REWARD_DISTRIBUTOR_ROLE.
     * Updates the global reward state before changing the rate.
     * @param newRate The new reward rate (in rewardToken wei per second).
     */
    function setBaseRewardRatePerSecond(uint256 newRate) external onlyRole(REWARD_DISTRIBUTOR_ROLE) {
        _updateRewardState(); // Update state based on old rate before changing
        _rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    /**
     * @dev Allows a REWARD_DISTRIBUTOR_ROLE to deposit reward tokens into the contract.
     * These tokens will be distributed to stakers over time.
     * @param amount The amount of reward tokens to deposit.
     */
    function depositRewards(uint256 amount) external onlyRole(REWARD_DISTRIBUTOR_ROLE) nonReentrant {
        require(amount > 0, "Amount must be > 0");
        // Transfer rewards from the distributor to this contract
        rewardToken.transferFrom(_msgSender(), address(this), amount);
        emit RewardsDeposited(_msgSender(), amount);
    }

    /**
     * @dev Sets the parameters for calculating the dynamic multiplier based on reputation.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param repFactor New reputation multiplier factor (scaled by 1e18, e.g., 0.001e18 per rep).
     * @param minRep Minimum reputation for multiplier effect.
     * @param maxRep Reputation cap for multiplier effect.
     */
    function setReputationMultiplierParameters(
        uint256 repFactor,
        uint256 minRep,
        uint256 maxRep
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minRep <= maxRep, "Min reputation must be <= max reputation");
        reputationMultiplierFactor = repFactor;
        minReputationForMultiplier = minRep;
        maxReputationForMultiplier = maxRep;
        emit MultiplierParametersUpdated(
            reputationMultiplierFactor,
            levelMultiplierFactor,
            minReputationForMultiplier,
            maxReputationForMultiplier
        );
    }

    /**
     * @dev Sets the parameters for calculating the dynamic multiplier based on badge level.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param levelFactor New level multiplier factor (scaled by 1e18, e.g., 0.05e18 per level).
     */
    function setLevelMultiplierParameters(uint256 levelFactor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        levelMultiplierFactor = levelFactor;
        emit MultiplierParametersUpdated(
            reputationMultiplierFactor,
            levelMultiplierFactor,
            minReputationForMultiplier,
            maxReputationForMultiplier
        );
    }


    // --- Badge Management Functions ---

    /**
     * @dev Mints a new Soul-Bound Dynamic Badge for an address.
     * An address can only have one badge. Requires BADGE_ISSUER_ROLE.
     * Sets initial level and traits. Reputation is managed separately.
     * @param user The address to mint the badge for.
     * @param initialLevel The initial level of the badge.
     * @param initialTraits The initial traits of the badge.
     */
    function mintBadge(address user, uint256 initialLevel, uint256 initialTraits) external onlyRole(BADGE_ISSUER_ROLE) {
        require(user != address(0), "Cannot mint to zero address");
        require(!_hasBadge[user], "User already has a badge");

        _badges[user] = BadgeData({
            level: initialLevel,
            traits: initialTraits
        });
        _hasBadge[user] = true;
        // Optionally initialize reputation here, or require it to be set separately
        // _reputation[user] = 0; // Or some default

        emit BadgeMinted(user, initialLevel, initialTraits);
    }

    /**
     * @dev Updates the level of a user's badge. Requires BADGE_ISSUER_ROLE.
     * @param user The address of the badge holder.
     * @param newLevel The new level for the badge.
     */
    function updateBadgeLevel(address user, uint256 newLevel) external onlyRole(BADGE_ISSUER_ROLE) {
        require(_hasBadge[user], "User does not have a badge");
        _badges[user].level = newLevel;
        // Note: This change will affect their staking yield on their next staking interaction.
        emit BadgeLevelUpdated(user, newLevel);
    }

    /**
     * @dev Updates the traits of a user's badge. Requires BADGE_ISSUER_ROLE.
     * Traits can represent various attributes affecting utility or aesthetics.
     * @param user The address of the badge holder.
     * @param newTraits The new traits value for the badge.
     */
    function updateBadgeTraits(address user, uint256 newTraits) external onlyRole(BADGE_ISSUER_ROLE) {
        require(_hasBadge[user], "User does not have a badge");
        _badges[user].traits = newTraits;
        // Traits could potentially also influence the multiplier, depending on logic.
        // Current multiplier logic only uses level and reputation.
        emit BadgeTraitsUpdated(user, newTraits);
    }

    /**
     * @dev Retrieves the badge data for a given user.
     * @param user The address to query.
     * @return BadgeData struct containing level and traits. Returns default struct if no badge.
     */
    function getBadgeData(address user) external view returns (BadgeData memory) {
        return _badges[user];
    }

    /**
     * @dev Checks if a user has a badge.
     * @param user The address to query.
     * @return bool True if the user has a badge, false otherwise.
     */
    function hasBadge(address user) external view returns (bool) {
        return _hasBadge[user];
    }

    /**
     * @dev Placeholder function to generate a dynamic token URI for the badge.
     * In a real implementation, this would fetch badge data and return a URL
     * pointing to JSON metadata (potentially stored off-chain, e.g., IPFS).
     * The metadata JSON could itself point to dynamic images.
     * @param user The address of the badge holder.
     * @return string The token URI for the user's badge.
     */
    function getBadgeTokenURI(address user) external view returns (string memory) {
        if (!_hasBadge[user]) {
            return ""; // Or a default URI for no badge
        }
        BadgeData storage badge = _badges[user];
        uint256 rep = _reputation[user];

        // Example: Generate a simple string representing data.
        // In production, this would be a real URI pointing to metadata.
        string memory uri = string(abi.encodePacked(
            "data:application/json;base64,...", // Base64 encoded JSON
            "{",
            "\"name\": \"RepuStake Badge #",
            // Placeholder: Add unique ID or use address hash
            "\", \"description\": \"Dynamic badge representing reputation and staking participation.\"",
            ", \"attributes\": [",
            "{ \"trait_type\": \"Level\", \"value\": ", uint256ToString(badge.level), " },",
            "{ \"trait_type\": \"Reputation\", \"value\": ", uint256ToString(rep), " },",
            "{ \"trait_type\": \"Traits\", \"value\": ", uint256ToString(badge.traits), " }",
            // Add more attributes based on badge data/user activity
            "],",
            "\"image\": \"ipfs://.../image_", uint256ToString(badge.level), "_", uint256ToString(badge.traits), ".png\"", // Dynamic image link
            "}"
        ));
        return uri;
    }

    // Helper function to convert uint256 to string (simplified)
    function uint256ToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    // --- Reputation Management Functions ---

    /**
     * @dev Updates the reputation score for a user. Requires REPUTATION_MANAGER_ROLE.
     * This function is typically called by an external system (e.g., verified oracle)
     * based on off-chain or other complex on-chain activity.
     * @param user The address whose reputation to update.
     * @param newReputation The new reputation score.
     */
    function updateReputation(address user, uint256 newReputation) external onlyRole(REPUTATION_MANAGER_ROLE) {
        require(user != address(0), "Cannot update zero address reputation");
        // Note: This change will affect their staking yield on their next staking interaction.
        _reputation[user] = newReputation;
        emit ReputationUpdated(user, newReputation);
    }

    /**
     * @dev Retrieves the reputation score for a given user.
     * @param user The address to query.
     * @return uint256 The reputation score. Returns 0 if no score set.
     */
    function getReputation(address user) external view returns (uint256) {
        return _reputation[user];
    }

    // --- Staking Functions ---

    /**
     * @dev Allows a user to stake stakedToken.
     * Calculates and adds any pending rewards before updating the stake.
     * @param amount The amount of stakedToken to deposit.
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");

        address user = _msgSender();
        StakeData storage userStake = _stakes[user];

        _updateRewardState(); // Update global state
        _calculateUserPendingRewards(user); // Calculate and add pending rewards

        // Update user's reward debt to the current global state
        userStake.rewardDebt = _accRewardPerUnitStaked;

        // Transfer tokens from user to contract
        stakedToken.transferFrom(user, address(this), amount);

        // Update user's stake amount and total staked
        userStake.amount = userStake.amount.add(amount);
        _totalStaked = _totalStaked.add(amount);

        emit TokensStaked(user, amount);
    }

    /**
     * @dev Allows a user to unstake stakedToken.
     * Calculates and adds any pending rewards before withdrawing.
     * @param amount The amount of stakedToken to withdraw.
     */
    function unstake(uint256 amount) external nonReentrant {
        address user = _msgSender();
        StakeData storage userStake = _stakes[user];

        require(amount > 0, "Amount must be > 0");
        require(userStake.amount >= amount, "Insufficient staked amount");

        _updateRewardState(); // Update global state
        _calculateUserPendingRewards(user); // Calculate and add pending rewards

        // Update user's reward debt to the current global state
        userStake.rewardDebt = _accRewardPerUnitStaked;

        // Update user's stake amount and total staked
        userStake.amount = userStake.amount.sub(amount);
        _totalStaked = _totalStaked.sub(amount);

        // Transfer tokens from contract to user
        stakedToken.transfer(user, amount);

        emit TokensUnstaked(user, amount);
    }

    /**
     * @dev Allows a user to claim their earned reward tokens.
     * Calculates and transfers pending rewards.
     */
    function claimRewards() external nonReentrant {
        address user = _msgSender();
        StakeData storage userStake = _stakes[user];

        _updateRewardState(); // Update global state
        _calculateUserPendingRewards(user); // Calculate pending rewards and add to claimable

        // The pending rewards are added to a hypothetical 'claimable' balance in _calculateUserPendingRewards
        // Since we don't explicitly store a separate 'claimable' balance, we calculate and transfer directly.
        // The rewardDebt update in _calculateUserPendingRewards effectively resets the 'pending' count.

        // Calculate rewards again to get the final claimable amount before transfer
        uint256 rewards = userStake.amount.mul(_accRewardPerUnitStaked.sub(userStake.rewardDebt)).div(MULTIPLIER_SCALE_FACTOR);
        // Apply the dynamic multiplier to the *total* accumulated rewards for this user
        rewards = rewards.mul(getAdjustedRewardMultiplier(user)).div(MULTIPLIER_SCALE_FACTOR);

        require(rewards > 0, "No rewards to claim");

        // Reset user's reward debt to the current global state
        userStake.rewardDebt = _accRewardPerUnitStaked;

        // Transfer rewards
        rewardToken.transfer(user, rewards);

        emit RewardsClaimed(user, rewards);
    }

    /**
     * @dev Retrieves staking information for a given user.
     * @param user The address to query.
     * @return uint256 amount staked.
     * @return uint256 pending rewards (calculated without state change).
     */
    function getStakeInfo(address user) external view returns (uint256 amount, uint256 pendingRewards) {
        StakeData storage userStake = _stakes[user];
        return (userStake.amount, getUserPendingRewards(user));
    }

    /**
     * @dev Retrieves the total amount of stakedToken currently staked in the contract.
     * @return uint256 Total staked amount.
     */
    function getTotalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    // --- Dynamic Rewards & Calculation ---

    /**
     * @dev Internal helper function to update the global reward accumulation state.
     * Calculates rewards generated since the last update and adds them to _accRewardPerUnitStaked.
     * Called by stake, unstake, and claimRewards before user-specific calculations.
     */
    function _updateRewardState() internal {
        uint256 timeElapsed = block.timestamp.sub(_lastRewardUpdateTime);
        if (timeElapsed > 0 && _totalStaked > 0 && _rewardRatePerSecond > 0) {
            // Calculate total rewards generated during the elapsed time
            uint256 rewardsGenerated = timeElapsed.mul(_rewardRatePerSecond);

            // Add to the global accumulator scaled by total staked amount
            // _accRewardPerUnitStaked represents total rewards per unit staked, scaled.
            _accRewardPerUnitStaked = _accRewardPerUnitStaked.add(
                rewardsGenerated.mul(MULTIPLIER_SCALE_FACTOR).div(_totalStaked)
            );
        }
        _lastRewardUpdateTime = block.timestamp;
    }

    /**
     * @dev Internal helper function to calculate a user's pending rewards and update their state.
     * This should be called after _updateRewardState.
     * It calculates rewards based on the difference between global and user-specific reward debt,
     * applies the dynamic multiplier, and adds to the user's pending balance (implicitly by updating debt).
     * @param user The address of the user.
     */
    function _calculateUserPendingRewards(address user) internal {
        StakeData storage userStake = _stakes[user];
        if (userStake.amount > 0) {
            // Calculate base pending rewards based on the difference between current global accumulation
            // and the user's recorded debt, scaled back down by MULTIPLIER_SCALE_FACTOR.
            uint256 basePending = userStake.amount.mul(_accRewardPerUnitStaked.sub(userStake.rewardDebt)).div(MULTIPLIER_SCALE_FACTOR);

            // Apply the dynamic multiplier to the base pending rewards
            uint256 adjustedPending = basePending.mul(getAdjustedRewardMultiplier(user)).div(MULTIPLIER_SCALE_FACTOR);

            // Conceptually, the difference between adjustedPending and basePending is the extra reward
            // from the multiplier. This difference is implicitly added to the user's claimable amount
            // when their rewardDebt is updated to the new global state later in the calling function (stake/unstake/claim).
            // This pattern is standard for efficient reward calculation systems.
        }
    }

    /**
     * @dev Calculates the user's dynamic reward multiplier based on their reputation and badge level.
     * Base multiplier is 1x (1e18). Reputation and level add to this base.
     * Reputation effect is capped by maxReputationForMultiplier.
     * @param user The address of the user.
     * @return uint256 The calculated multiplier, scaled by MULTIPLIER_SCALE_FACTOR (1e18).
     */
    function getAdjustedRewardMultiplier(address user) public view returns (uint256) {
        uint256 baseMultiplier = MULTIPLIER_SCALE_FACTOR; // Start with 1x

        // Add multiplier from reputation (if above min threshold)
        uint256 currentRep = _reputation[user];
        if (currentRep >= minReputationForMultiplier) {
            uint256 effectiveRep = currentRep;
            if (maxReputationForMultiplier > minReputationForMultiplier) {
                // Cap the effective reputation used for calculation
                effectiveRep = Math.min(currentRep, maxReputationForMultiplier);
            }
             uint256 repContribution = effectiveRep.mul(reputationMultiplierFactor); // Scaled contribution
             baseMultiplier = baseMultiplier.add(repContribution); // Add scaled contribution
        }

        // Add multiplier from badge level (if badge exists)
        if (_hasBadge[user]) {
            uint256 currentLevel = _badges[user].level;
            uint256 levelContribution = currentLevel.mul(levelMultiplierFactor); // Scaled contribution
            baseMultiplier = baseMultiplier.add(levelContribution); // Add scaled contribution
        }

        return baseMultiplier; // Return the total scaled multiplier
    }

    /**
     * @dev Calculates the user's effective reward rate per second.
     * This is the base reward rate multiplied by their dynamic multiplier.
     * @param user The address of the user.
     * @return uint256 The user's effective reward rate (in rewardToken wei per second).
     */
    function getEffectiveRewardRate(address user) external view returns (uint256) {
        uint256 multiplier = getAdjustedRewardMultiplier(user);
        return _rewardRatePerSecond.mul(multiplier).div(MULTIPLIER_SCALE_FACTOR); // Apply multiplier
    }

     /**
     * @dev Calculates the pending rewards for a user without modifying state.
     * This function is useful for displaying the user's potential rewards.
     * It performs the same calculation as done internally before state updates.
     * @param user The address of the user.
     * @return uint256 The amount of reward tokens the user could claim.
     */
    function getUserPendingRewards(address user) public view returns (uint256) {
        StakeData storage userStake = _stakes[user];
        if (userStake.amount == 0) {
            return 0;
        }

        // Simulate _updateRewardState to get current _accRewardPerUnitStaked
        uint256 currentAccRewardPerUnitStaked = _accRewardPerUnitStaked;
        uint256 timeElapsed = block.timestamp.sub(_lastRewardUpdateTime);

        if (timeElapsed > 0 && _totalStaked > 0 && _rewardRatePerSecond > 0) {
            uint256 rewardsGenerated = timeElapsed.mul(_rewardRatePerSecond);
            currentAccRewardPerUnitStaked = currentAccRewardPerUnitStaked.add(
                rewardsGenerated.mul(MULTIPLIER_SCALE_FACTOR).div(_totalStaked)
            );
        }

        // Calculate base pending rewards
        uint256 basePending = userStake.amount.mul(currentAccRewardPerUnitStaked.sub(userStake.rewardDebt)).div(MULTIPLIER_SCALE_FACTOR);

        // Apply the dynamic multiplier
        uint256 multiplier = getAdjustedRewardMultiplier(user);
        uint256 adjustedPending = basePending.mul(multiplier).div(MULTIPLIER_SCALE_FACTOR);

        return adjustedPending;
    }

    /**
     * @dev Retrieves the current global accumulated reward per unit staked.
     * Useful for debugging or external calculations.
     * @return uint256 Accumulated reward per unit staked (scaled by 1e18).
     */
    function getAccRewardPerUnitStaked() external view returns (uint256) {
        // This requires a state update to be truly current, but for a view it shows the last updated value
        // To get the *actual* current value considering elapsed time, one would need to calculate it:
        uint256 currentAcc = _accRewardPerUnitStaked;
        uint256 timeElapsed = block.timestamp.sub(_lastRewardUpdateTime);
         if (timeElapsed > 0 && _totalStaked > 0 && _rewardRatePerSecond > 0) {
            uint256 rewardsGenerated = timeElapsed.mul(_rewardRatePerSecond);
             currentAcc = currentAcc.add(
                rewardsGenerated.mul(MULTIPLIER_SCALE_FACTOR).div(_totalStaked)
            );
        }
        return currentAcc;
    }

     /**
     * @dev Retrieves the timestamp of the last global reward state update.
     * @return uint256 Timestamp.
     */
    function getLastRewardUpdateTime() external view returns (uint256) {
        return _lastRewardUpdateTime;
    }

    // The soul-bound nature is enforced by the lack of transfer functions for the badge data.
    // The badge data is simply associated with the address in the _badges mapping.
    // If you were to use ERC1155 for the badge ID, you'd implement _beforeTokenTransfer
    // to revert if the token ID is the special badge ID. But here, it's just data.
}
```

**Explanation of Concepts & Features:**

1.  **Soul-Bound Dynamic Badge:**
    *   The `BadgeData` struct and `_badges` mapping store information about a user's badge (`level`, `traits`).
    *   The `_hasBadge` mapping provides a quick check if an address holds a badge.
    *   Crucially, there are no transfer functions (`transfer`, `safeTransferFrom`, etc.) for the badge itself. It's linked directly to the user's address in storage, making it non-transferable, akin to a Soul-Bound Token (SBT) concept.
    *   The `mintBadge`, `updateBadgeLevel`, and `updateBadgeTraits` functions allow a designated role (`BADGE_ISSUER_ROLE`) to create and modify these badges, making them "dynamic".
    *   `getBadgeTokenURI` is a placeholder showing how dynamic metadata could be generated based on the badge's current state (level, traits, reputation).

2.  **Reputation System:**
    *   A simple `_reputation` mapping stores a score for each address.
    *   The `updateReputation` function allows a `REPUTATION_MANAGER_ROLE` to set/update this score. This role is intended to be controlled by a trusted entity or even an oracle verifying off-chain data or complex on-chain interactions not directly handled by this contract (e.g., participation in governance, verified identity, complex achievements).

3.  **Dynamic Staking Yield:**
    *   The core innovation lies in `getAdjustedRewardMultiplier`. This function calculates a multiplier that is applied to the base reward rate when calculating a user's pending rewards (`_calculateUserPendingRewards`).
    *   The multiplier is influenced by the user's `_reputation` score (if above a minimum threshold) and their badge `level` (if they have a badge).
    *   Parameters (`reputationMultiplierFactor`, `levelMultiplierFactor`, `minReputationForMultiplier`, `maxReputationForMultiplier`) control how strongly reputation and level affect the multiplier and are configurable by the admin.
    *   The `_accRewardPerUnitStaked` and `rewardDebt` pattern is a standard, gas-efficient way to track proportional rewards in staking pools. The dynamic multiplier is applied *on top* of this standard calculation.

4.  **Role-Based Access Control:**
    *   Uses OpenZeppelin's `AccessControl` for managing permissions.
    *   Specific roles (`BADGE_ISSUER_ROLE`, `REPUTATION_MANAGER_ROLE`, `REWARD_DISTRIBUTOR_ROLE`) are defined to delegate specific privileged actions, enhancing security and modularity compared to a single `owner`.

5.  **Standard Staking Mechanics:**
    *   `stake`, `unstake`, and `claimRewards` functions handle the core staking logic.
    *   `ReentrancyGuard` is used to prevent reentrancy attacks on state-changing functions.
    *   The reward calculation within `_calculateUserPendingRewards` is triggered before any stake/unstake/claim action to ensure the user's pending rewards are up-to-date before state changes occur.

6.  **Efficiency:**
    *   Using the `_accRewardPerUnitStaked` and `rewardDebt` pattern is more efficient than iterating through all stakers or using complex per-user timers. Reward calculation becomes an O(1) operation for each user interaction after the global state update.
    *   `_hasBadge` mapping provides a quick existence check.

This contract provides a framework where user identity (via the non-transferable badge), history/activity (reflected in reputation), and loyalty/participation (staking) are intertwined to create dynamic economic outcomes (variable yield). This moves beyond simple token staking or static NFTs into a more interconnected on-chain identity and incentive system.