Okay, let's design a creative, advanced smart contract called `CelestialTreasury`. This contract will manage a fictional resource called "Cosmic Essence" (fungible) and unique "Star Shards" (non-fungible internal items). It will involve dynamic yield generation, a resource sink mechanism, roles, epochs, and simulated cosmic events.

We will avoid directly copying common patterns like standard ERC20/ERC721 implementations or standard staking contracts, instead building the core mechanics internally based on account balances and item ownership tracked within the contract itself.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CelestialTreasury
 * @notice A unique smart contract managing Cosmic Essence (fungible) and Star Shards (non-fungible)
 *         with dynamic yield generation, resource sinks, roles, epochs, and simulated events.
 *
 * @dev This contract uses an internal representation of assets (Cosmic Essence and Star Shards)
 *      rather than relying on external ERC20/ERC721 tokens for core mechanics, enhancing complexity
 *      and ensuring non-duplication of standard patterns.
 *
 * Outline:
 * 1. Contract Overview and State Variables
 *    - Basic ownership and roles (Owner, Guardians).
 *    - Core asset tracking (Cosmic Essence balances, staked amounts, Star Shards).
 *    - Yield mechanics state (yield factor, cosmic intensity, epoch data, user last updates).
 *    - Sink mechanism state (black hole burn rate, cooldowns).
 *    - Star Shard metadata and state.
 *    - Global parameters and counters.
 * 2. Events
 *    - Signaling key actions like deposits, stakes, claims, shard mints, sink activation, role changes, etc.
 * 3. Errors
 *    - Custom error types for clearer failure reasons.
 * 4. Modifiers
 *    - Access control (onlyOwner, onlyGuardianOrOwner).
 * 5. Core Logic (Internal & External Functions)
 *    - Essence Management: Deposit, withdraw, stake, unstake, balance queries.
 *    - Yield Calculation & Claiming: Time-based, dynamic yield calculation; claiming accrued yield.
 *    - Star Shard Management: Internal minting (tied to yield/events), staking shards for boosts, query functions.
 *    - Black Hole Sink: Mechanism to burn Essence for effects with cooldowns.
 *    - Parameter Management: Setting dynamic factors (yield, burn rate, intensity).
 *    - Epoch & Event Handling: Advancing epochs, triggering simulated cosmic events affecting intensity.
 *    - Role Management: Adding/removing Guardians.
 *    - Query Functions: Retrieving various state data (user specific, global).
 *    - Protocol/Treasury Functions: Admin withdrawal of leftover/protocol-accumulated essence.
 */
contract CelestialTreasury {

    // --- State Variables ---

    address public owner;
    mapping(address => bool) public guardians;
    uint256 public constant GUARDIAN_ROLE = 1; // Role identifier (simple)

    // Cosmic Essence (Internal Fungible Token)
    mapping(address => uint256) private userEssenceBalances; // Available (non-staked)
    mapping(address => uint256) private userStakedEssence; // Staked
    uint256 public totalEssenceSupply;
    uint256 public totalStakedEssence;

    // Star Shards (Internal Non-Fungible Items)
    struct StarShard {
        address owner; // Owner address (staked implies contract)
        uint256 mintTime;
        uint256 boostFactor; // e.g., in basis points, 100 = 1% boost
        bool isStaked; // True if staked in the contract
    }
    mapping(uint256 => StarShard) private starShards; // shardId => Shard data
    uint256 private nextShardId = 1; // Counter for unique shard IDs
    mapping(address => uint256[]) private userShardIds; // User => list of shard IDs they 'own' (available or staked)
    mapping(address => uint256[]) private userStakedShardIds; // User => list of shard IDs they have staked

    // Yield & Epoch Mechanics
    uint256 public currentEpoch = 1;
    uint256 public epochDuration = 7 days; // Example: Epoch lasts 7 days
    uint256 public epochStartTime;

    uint256 public baseYieldFactor = 10; // Example: 10 basis points per unit staked per day (scaled)
    uint256 public cosmicIntensity = 100; // Example: Base 100, affects yield (scaled)
    // Yield calculation: stakedAmount * baseYieldFactor/10000 * cosmicIntensity/100 * timeDelta / 1 day

    mapping(address => uint256) private userLastYieldUpdateTime; // Timestamp of last claim/stake/unstake
    mapping(address => uint256) private userPendingYield; // Unclaimed yield for user

    // Black Hole Sink Mechanics
    uint256 public blackHoleBurnRate = 500; // Example: 500 basis points (5%) of burned essence is returned immediately
    uint256 public blackHoleCooldown = 1 days; // Cooldown period after activating sink
    mapping(address => uint256) private userBlackHoleCooldown; // Timestamp when user can activate sink again

    // Cosmic Event Simulation (Simple)
    uint256 public lastCosmicEventTime;
    uint256 public cosmicEventCooldown = 3 days; // Cooldown for triggering events

    // Scaling factor for calculations (e.g., 1e18 for 18 decimals)
    uint256 private constant SCALING_FACTOR = 1e18;
    uint256 private constant BASIS_POINTS_DIVISOR = 10000; // For basis points calculations
    uint256 private constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);

    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawal(address indexed user, uint256 amount);
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event EssenceYieldClaimed(address indexed user, uint256 amount);
    event EssenceBurned(address indexed user, uint256 amountBurned, uint256 amountReturned);

    event ShardMinted(address indexed owner, uint256 indexed shardId, uint256 boostFactor);
    event ShardStaked(address indexed user, uint256 indexed shardId);
    event ShardUnstaked(address indexed user, uint256 indexed shardId);

    event BlackHoleActivated(address indexed user, uint256 essenceBurned, uint256 essenceReturned);
    event CosmicEventTriggered(uint256 newCosmicIntensity);
    event EpochAdvanced(uint256 newEpoch, uint256 startTime);
    event ParameterUpdated(string name, uint256 oldValue, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Errors ---

    error NotOwner();
    error NotGuardianOrOwner();
    error ZeroAddress();
    error InsufficientBalance(uint256 requested, uint256 available);
    error InsufficientStakedEssence(uint256 requested, uint256 available);
    error InsufficientStakedShards(uint256 requested, uint256 available); // maybe not needed if unstaking by ID
    error InvalidShardId();
    error ShardAlreadyStaked(uint256 shardId);
    error ShardNotStaked(uint256 shardId);
    error NotShardOwner(uint256 shardId, address caller);
    error BlackHoleOnCooldown(uint256 availableInSeconds);
    error CosmicEventOnCooldown(uint256 availableInSeconds);
    error InsufficientProtocolBalance(uint256 requested, uint256 available);
    error CannotWithdrawStakedEssence();


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyGuardianOrOwner() {
        if (msg.sender != owner && !guardians[msg.sender]) revert NotGuardianOrOwner();
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        epochStartTime = block.timestamp; // Start epoch 1 now
        emit OwnershipTransferred(address(0), owner);
    }

    // --- Access Control Functions ---

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @notice Grants the Guardian role to an address.
     * @param guardian The address to grant the role to.
     */
    function grantGuardianRole(address guardian) external onlyOwner {
        if (guardian == address(0)) revert ZeroAddress();
        guardians[guardian] = true;
        emit GuardianAdded(guardian);
    }

    /**
     * @notice Revokes the Guardian role from an address.
     * @param guardian The address to revoke the role from.
     */
    function revokeGuardianRole(address guardian) external onlyOwner {
        if (guardian == address(0)) revert ZeroAddress();
        guardians[guardian] = false;
        emit GuardianRemoved(guardian);
    }

    // --- Cosmic Essence Management ---

    /**
     * @notice Mints initial Cosmic Essence supply (owner only, typically used once at setup).
     * @param recipient The address to receive the minted essence.
     * @param amount The amount of essence to mint.
     */
    function mintInitialEssence(address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        userEssenceBalances[recipient] += amount;
        totalEssenceSupply += amount;
        // No specific event for initial mint, consider adding one if needed.
        // EssenceDeposited could potentially be repurposed or a new one added.
    }

    /**
     * @notice Allows a user to deposit external essence (simulated as adding to their balance).
     *         In a real scenario, this would involve receiving an ERC20 token.
     * @param amount The amount of essence to deposit.
     */
    function depositEssence(uint256 amount) external {
        // Simulate deposit: assumes user "has" amount and transfers it to the contract.
        // In a real ERC20 integration, this would be a transferFrom or pull pattern.
        // For this example, we just increase user balance directly.
        // require(ERC20(essenceTokenAddress).transferFrom(msg.sender, address(this), amount));
        userEssenceBalances[msg.sender] += amount;
        // totalEssenceSupply might not increase here if essence is burned elsewhere,
        // but for this simulation, we'll track internal supply including user balances.
        // totalEssenceSupply += amount; // Only if essence is minted here, not deposited
        emit EssenceDeposited(msg.sender, amount);
    }

     /**
     * @notice Allows a user to withdraw available (non-staked) essence.
     * @param amount The amount of essence to withdraw.
     */
    function withdrawEssence(uint256 amount) external {
        if (userEssenceBalances[msg.sender] < amount) {
            revert InsufficientBalance(amount, userEssenceBalances[msg.sender]);
        }
        userEssenceBalances[msg.sender] -= amount;
        // totalEssenceSupply -= amount; // Only decrease if supply tracking excludes contract balance
        // Simulate withdrawal: transfer amount to user.
        // In a real ERC20 integration, this would be a transfer.
        // require(ERC20(essenceTokenAddress).transfer(msg.sender, amount));
        emit EssenceWithdrawal(msg.sender, amount);
    }


    /**
     * @notice Stakes available Cosmic Essence to earn yield.
     * @param amount The amount of essence to stake.
     */
    function stakeEssence(uint256 amount) external {
        if (userEssenceBalances[msg.sender] < amount) {
            revert InsufficientBalance(amount, userEssenceBalances[msg.sender]);
        }

        // Update yield before staking
        _updateUserYield(msg.sender);

        userEssenceBalances[msg.sender] -= amount;
        userStakedEssence[msg.sender] += amount;
        totalStakedEssence += amount;

        userLastYieldUpdateTime[msg.sender] = block.timestamp; // Reset timer

        emit EssenceStaked(msg.sender, amount);
    }

    /**
     * @notice Unstakes previously staked Cosmic Essence.
     * @param amount The amount of essence to unstake.
     */
    function unstakeEssence(uint256 amount) external {
        if (userStakedEssence[msg.sender] < amount) {
            revert InsufficientStakedEssence(amount, userStakedEssence[msg.sender]);
        }

        // Update yield before unstaking
        _updateUserYield(msg.sender);

        userStakedEssence[msg.sender] -= amount;
        userEssenceBalances[msg.sender] += amount;
        totalStakedEssence -= amount;

        userLastYieldUpdateTime[msg.sender] = block.timestamp; // Reset timer

        emit EssenceUnstaked(msg.sender, amount);
    }

    // --- Yield Calculation & Claiming ---

    /**
     * @notice Calculates the pending yield for a user based on time staked and current parameters.
     * @param user The address of the user.
     * @return The amount of pending Cosmic Essence yield.
     */
    function getPendingEssenceYield(address user) public view returns (uint256) {
        uint256 staked = userStakedEssence[user];
        if (staked == 0) {
            return userPendingYield[user];
        }

        uint256 lastUpdateTime = userLastYieldUpdateTime[user];
        uint256 timeDelta = block.timestamp - lastUpdateTime;

        // Avoid division by zero if ONE_DAY_IN_SECONDS is 0 or timeDelta is small
        if (timeDelta == 0 || ONE_DAY_IN_SECONDS == 0) {
             return userPendingYield[user];
        }

        // Calculate yield: staked * baseYieldFactor/10000 * cosmicIntensity/100 * timeDelta / ONE_DAY_IN_SECONDS
        // Use scaling factors to maintain precision
        uint256 yield = (staked * baseYieldFactor * cosmicIntensity * timeDelta) / (BASIS_POINTS_DIVISOR * 100 * ONE_DAY_IN_SECONDS);
        // Scale yield to SCALING_FACTOR (assuming baseYieldFactor/cosmicIntensity are integer percentages or factors)
        // If baseYieldFactor is bps/day and cosmicIntensity is a factor (100 = 1x), yield per second is:
        // staked * (baseYieldFactor / 10000) * (cosmicIntensity / 100) / ONE_DAY_IN_SECONDS
        // = staked * baseYieldFactor * cosmicIntensity / (10000 * 100 * ONE_DAY_IN_SECONDS)
        // = staked * baseYieldFactor * cosmicIntensity / (1e6 * ONE_DAY_IN_SECONDS)
        // Let's assume baseYieldFactor is bps/day and cosmicIntensity is a factor (100 = 100%).
        // Yield/second = staked * (baseYieldFactor / 10000) * (cosmicIntensity / 100) / ONE_DAY_IN_SECONDS
        // This is yield *per unit staked*. Total yield = above * staked.
        // Let's assume baseYieldFactor is bps *per unit staked* per day. cosmicIntensity is a multiplier (100 = 1x)
        // Yield/second = staked * (baseYieldFactor / 10000) * (cosmicIntensity / 100) / ONE_DAY_IN_SECONDS
        // Re-evaluate units:
        // baseYieldFactor: basis points per unit staked per DAY (e.g., 10 -> 0.1% / unit / day)
        // cosmicIntensity: Percentage multiplier (e.g., 100 -> 100%, 150 -> 150%)
        // Yield/second = staked * (baseYieldFactor / 10000) * (cosensity / 100) / ONE_DAY_IN_SECONDS
        // Example: 100 staked, baseYield 10 bps, intensity 150%, time 1 day
        // Yield = 100 * (10/10000) * (150/100) * (1 day / 1 day)
        // Yield = 100 * 0.001 * 1.5 * 1 = 0.15 Essence.
        // With SCALING_FACTOR (1e18):
        // Yield = (staked * baseYieldFactor * cosmicIntensity * timeDelta * SCALING_FACTOR) / (BASIS_POINTS_DIVISOR * 100 * ONE_DAY_IN_SECONDS)
        // Example: 100e18 staked, baseYield 10, intensity 150, time 1 day (scaled)
        // Yield = (100e18 * 10 * 150 * ONE_DAY_IN_SECONDS * SCALING_FACTOR) / (10000 * 100 * ONE_DAY_IN_SECONDS * SCALING_FACTOR)
        // Wait, timeDelta is already in seconds.
        // Yield = (staked * baseYieldFactor * cosmicIntensity * timeDelta) / (BASIS_POINTS_DIVISOR * 100 * ONE_DAY_IN_SECONDS)
        // Staked is already scaled (e.g., 1e18 for 1 unit).
        // Yield = (staked_scaled * baseYieldFactor * cosmicIntensity * timeDelta) / (BASIS_POINTS_DIVISOR * 100 * ONE_DAY_IN_SECONDS)
        // Example: 1e18 staked, baseYield 10, intensity 150, time 1 day in seconds.
        // Yield = (1e18 * 10 * 150 * ONE_DAY_IN_SECONDS) / (10000 * 100 * ONE_DAY_IN_SECONDS)
        // Yield = (1e18 * 10 * 150) / (10000 * 100)
        // Yield = (1e18 * 1500) / 1e6 = 1e18 * 0.0015 = 0.0015e18 = 1.5e15 (scaled)
        // This looks correct. Let's use this formula.
        // To avoid potential overflow if intermediate values are huge, carefully order ops or use mulDiv.
        // (staked * timeDelta * baseYieldFactor) / ONE_DAY_IN_SECONDS * cosmicIntensity / (BASIS_POINTS_DIVISOR * 100)
        // = (staked * timeDelta * baseYieldFactor * cosmicIntensity) / (ONE_DAY_IN_SECONDS * BASIS_POINTS_DIVISOR * 100)

        // Let's calculate per second yield first, then multiply by timeDelta
        // yieldPerSecond = (staked * baseYieldFactor * cosmicIntensity) / (BASIS_POINTS_DIVISOR * 100 * ONE_DAY_IN_SECONDS)
        // This still involves large numbers. Let's combine the denominator.
        // Denominator = 10000 * 100 * ONE_DAY_IN_SECONDS = 1e6 * ONE_DAY_IN_SECONDS

        // Simplified:
        // yield = (staked * baseYieldFactor * cosmicIntensity * timeDelta) / (10000 * 100 * ONE_DAY_IN_SECONDS)
        // Ensure staked is uint256. All params are uint256.
        // The maximum value of staked * baseYieldFactor * cosmicIntensity * timeDelta could exceed uint256.
        // Staked can be total supply. baseYieldFactor/intensity relatively small. timeDelta max is ~4e9.
        // Max staked ~ 1e27 (1e9 tokens at 1e18 scale).
        // Max term ~ 1e27 * 10000 * 1000 * 4e9 (upper bounds) ~ 4e43. Exceeds uint256 max (~1.15e77). Wait, no.
        // uint256 max is 2^256 - 1 which is ~ 1.15 * 10^77.
        // Max staked_scaled * baseYieldFactor * cosmicIntensity * timeDelta
        // Max Staked: 1e27 (if total supply is 1e9 tokens scaled)
        // Max baseYieldFactor: Let's assume reasonable max, say 1000 (10% / day)
        // Max cosmicIntensity: Let's assume 1000 (10x boost)
        // Max timeDelta: If epoch is 7 days, delta could be max 7 days before update. 7*ONE_DAY_IN_SECONDS.
        // Max product: 1e27 * 1000 * 1000 * (7 * 86400) ~ 1e27 * 1e6 * 6e5 ~ 6e38. This fits comfortably in uint256.

        uint256 denominator = BASIS_POINTS_DIVISOR * 100 * ONE_DAY_IN_SECONDS;
        uint256 yieldAmount = (staked * baseYieldFactor * cosmicIntensity * timeDelta) / denominator;

        // Add shard boosts
        uint256 totalShardBoost = 0;
        uint256[] memory stakedShardIds = userStakedShardIds[user];
        for (uint i = 0; i < stakedShardIds.length; i++) {
            uint256 shardId = stakedShardIds[i];
            // Ensure shard exists and is correctly tracked
            if (starShards[shardId].owner == address(this) && starShards[shardId].isStaked) {
                totalShardBoost += starShards[shardId].boostFactor;
            }
        }

        if (totalShardBoost > 0) {
             // Apply boost: yieldAmount * (1 + totalShardBoost/10000)
             // = yieldAmount + (yieldAmount * totalShardBoost / 10000)
             yieldAmount += (yieldAmount * totalShardBoost) / BASIS_POINTS_DIVISOR;
        }


        return userPendingYield[user] + yieldAmount;
    }

    /**
     * @notice Internal helper function to calculate and add pending yield to user's balance.
     * @param user The address of the user.
     */
    function _updateUserYield(address user) internal {
        uint256 pending = getPendingEssenceYield(user);
        if (pending > 0) {
            userPendingYield[user] = pending; // Update pending before resetting
            userLastYieldUpdateTime[user] = block.timestamp; // Reset timer *before* adding to balance/claiming
        }
        // Note: This helper just *updates* the pending amount, it doesn't claim it.
    }

    /**
     * @notice Claims the accrued Cosmic Essence yield for the calling user.
     *         May also trigger Star Shard minting based on a chance mechanism (simulated).
     */
    function claimEssenceYield() external {
        _updateUserYield(msg.sender); // Calculate any yield accumulated since last update

        uint256 amountToClaim = userPendingYield[msg.sender];
        if (amountToClaim == 0) {
            // No yield to claim, but check for shard drop chance anyway? Or only on claim?
            // Let's make shard drop happen on claim attempt *if* user has staked essence.
             if (userStakedEssence[msg.sender] > 0) {
                _attemptShardMint(msg.sender);
             }
             return; // No essence yield to claim
        }

        userPendingYield[msg.sender] = 0;
        userEssenceBalances[msg.sender] += amountToClaim;
        totalEssenceSupply += amountToClaim; // Yield increases total supply

        emit EssenceYieldClaimed(msg.sender, amountToClaim);

        // After claiming yield, attempt to mint a shard
        _attemptShardMint(msg.sender);
    }

    // --- Star Shard Management ---

    /**
     * @notice Internal function to attempt minting a Star Shard for a user.
     *         Chance mechanism based on cosmic intensity and staked essence (simulated randomness).
     * @param user The address of the user potentially receiving a shard.
     */
    function _attemptShardMint(address user) internal {
         // Simulate a chance mechanism. This is NOT secure randomness for high-value dApps.
         // Use Chainlink VRF or similar for real applications.
         // Simple simulation: blockhash and timestamp/user address interaction.
         uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, user, totalStakedEssence, cosmicIntensity)));
         uint256 roll = entropy % 10000; // Roll a number between 0 and 9999

         // Higher intensity, higher staked essence could increase chance?
         // Let's define a base chance (e.g., 10/10000 = 0.1%) modified by intensity (cosmicIntensity/100)
         // Chance threshold = (baseChance * cosmicIntensity / 100). Let baseChance = 10 (out of 10000)
         // A threshold roll lower than this means success.
         // threshold = (10 * cosmicIntensity) / 100 = cosmicIntensity / 10
         // Example: intensity 100 -> threshold 10. roll < 10 = 0.1% chance.
         // Example: intensity 500 -> threshold 50. roll < 50 = 0.5% chance.
         uint256 chanceThreshold = cosmicIntensity / 10; // Simple scaling

         // Also, more staked essence could increase individual chance, or maybe just total pool chance.
         // Let's keep it simple and based primarily on intensity for this example.
         // If user has less than a minimum staked amount, no chance.
         if (userStakedEssence[user] < SCALING_FACTOR) { // Need at least 1 essence staked (scaled)
             return;
         }

         if (roll < chanceThreshold) {
             // Mint a shard!
             uint256 shardId = nextShardId++;
             // Assign a random boost factor (e.g., 10 to 100 bps = 0.1% to 1% boost)
             // Use part of the entropy for boost factor
             uint256 boost = (entropy % 91) + 10; // Boost between 10 and 100

             starShards[shardId] = StarShard({
                 owner: user,
                 mintTime: block.timestamp,
                 boostFactor: boost,
                 isStaked: false // Initially not staked
             });
             userShardIds[user].push(shardId);
             emit ShardMinted(user, shardId, boost);
         }
    }

    /**
     * @notice Stakes a Star Shard owned by the user to gain its boost effect on essence yield.
     * @param shardId The ID of the shard to stake.
     */
    function stakeShard(uint256 shardId) external {
        StarShard storage shard = starShards[shardId];

        if (shard.owner != msg.sender) revert NotShardOwner(shardId, msg.sender);
        if (shard.isStaked) revert ShardAlreadyStaked(shardId);
        if (shard.mintTime == 0) revert InvalidShardId(); // Check if shard exists

        // Before staking, update user's essence yield calculation
        _updateUserYield(msg.sender);

        shard.isStaked = true;
        // Transfer ownership concept to the contract while staked
        shard.owner = address(this);

        // Add to user's staked shard list
        userStakedShardIds[msg.sender].push(shardId);
        // Remove from user's available shard list
        _removeShardIdFromList(userShardIds[msg.sender], shardId);

        // The boost factor will be applied in getPendingEssenceYield

        emit ShardStaked(msg.sender, shardId);
    }

    /**
     * @notice Unstakes a previously staked Star Shard.
     * @param shardId The ID of the shard to unstake.
     */
    function unstakeShard(uint256 shardId) external {
        StarShard storage shard = starShards[shardId];

        // Check if the shard is staked by this user
        // This check is slightly different from standard ERC721 as ownership is internal
        bool isStakedByCaller = false;
        uint256 index = 0;
        uint256[] storage stakedIds = userStakedShardIds[msg.sender];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == shardId) {
                isStakedByCaller = true;
                index = i;
                break;
            }
        }

        if (!isStakedByCaller) revert ShardNotStaked(shardId);
        if (shard.owner != address(this) || !shard.isStaked) revert ShardNotStaked(shardId); // Double check internal state

        // Before unstaking, update user's essence yield calculation
        _updateUserYield(msg.sender);

        shard.isStaked = false;
        // Return ownership concept to the user address
        shard.owner = msg.sender;

        // Remove from user's staked shard list efficiently
        if (index < stakedIds.length - 1) {
            stakedIds[index] = stakedIds[stakedIds.length - 1];
        }
        stakedIds.pop();

        // Add back to user's available shard list
        userShardIds[msg.sender].push(shardId);

        emit ShardUnstaked(msg.sender, shardId);
    }

    /**
     * @notice Internal helper to remove a shard ID from a dynamic array (inefficient for large arrays).
     * @param list The dynamic array of shard IDs.
     * @param shardId The ID to remove.
     */
    function _removeShardIdFromList(uint256[] storage list, uint256 shardId) internal {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == shardId) {
                // Shift elements to the left
                if (i < list.length - 1) {
                    list[i] = list[list.length - 1];
                }
                list.pop(); // Remove last element (either the moved one or the original)
                return;
            }
        }
        // Should not happen if logic is correct, but could add a specific error if needed
    }


    // --- Black Hole Sink ---

    /**
     * @notice Activates the Black Hole Sink, burning user's available essence for a partial return
     *         and a temporary effect (e.g., simulated yield boost for a short period, not implemented in calc yet).
     * @param essenceToBurn The amount of available essence to burn.
     */
    function activateBlackHoleSink(uint256 essenceToBurn) external {
        if (essenceToBurn == 0) return; // No need to burn 0

        if (userEssenceBalances[msg.sender] < essenceToBurn) {
            revert InsufficientBalance(essenceToBurn, userEssenceBalances[msg.sender]);
        }

        if (block.timestamp < userBlackHoleCooldown[msg.sender]) {
            revert BlackHoleOnCooldown(userBlackHoleCooldown[msg.sender] - block.timestamp);
        }

        userEssenceBalances[msg.sender] -= essenceToBurn;
        totalEssenceSupply -= essenceToBurn; // Burning reduces total supply

        uint256 amountReturned = (essenceToBurn * blackHoleBurnRate) / BASIS_POINTS_DIVISOR;
        userEssenceBalances[msg.sender] += amountReturned;
        totalEssenceSupply += amountReturned; // Returned amount is added back to supply

        userBlackHoleCooldown[msg.sender] = block.timestamp + blackHoleCooldown;

        // Add a temporary effect? E.g., a mapping user => boostEndTime.
        // This would require modifying the yield calculation to check this mapping.
        // Skipping complex temporary boost for function count, focus on burn/return/cooldown.

        emit BlackHoleActivated(msg.sender, essenceToBurn, amountReturned);
        emit EssenceBurned(msg.sender, essenceToBurn, amountReturned); // Specific event for burn
    }

    // --- Epoch & Event Handling ---

    /**
     * @notice Advances the current epoch. Can be called by Guardian or Owner.
     *         Yield calculations are time-based within epochs in this version, but epochs
     *         could be used for rule changes or scheduled events.
     */
    function advanceEpoch() external onlyGuardianOrOwner {
        // Only advance if epoch duration has passed
        if (block.timestamp < epochStartTime + epochDuration) {
             // Optionally add an error or just return/log
             return;
        }
        currentEpoch++;
        epochStartTime = block.timestamp; // Start the new epoch from now
        // Could potentially trigger events or update parameters here based on epoch number
        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    /**
     * @notice Triggers a simulated cosmic event, randomly (pseudo-randomly) changing Cosmic Intensity.
     *         Uses simple blockhash/timestamp based entropy (NOT secure).
     *         Callable by Guardian or Owner with a cooldown.
     */
    function triggerCosmicEvent() external onlyGuardianOrOwner {
        if (block.timestamp < lastCosmicEventTime + cosmicEventCooldown) {
            revert CosmicEventOnCooldown(lastCosmicEventTime + cosmicEventCooldown - block.timestamp);
        }

        // Simulate a random change to cosmic intensity
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, totalStakedEssence, totalEssenceSupply, cosmicIntensity)));
        // Change intensity by +/- 10% to 50% of current value, with min/max bounds.
        // Range of change: -5000 to +5000 (bps)
        uint256 changeAmountBps = (entropy % 10001) - 5000; // Between -5000 and 5000

        uint256 oldIntensity = cosmicIntensity;
        int256 signedIntensity = int256(cosmicIntensity); // Use signed int for calculation

        // Calculate change: current * changeAmountBps / 10000
        int256 intensityChange = (signedIntensity * int256(changeAmountBps)) / 10000;

        signedIntensity += intensityChange;

        // Apply min/max bounds (e.g., min 50, max 500)
        int256 minIntensity = 50;
        int256 maxIntensity = 500;
        if (signedIntensity < minIntensity) signedIntensity = minIntensity;
        if (signedIntensity > maxIntensity) signedIntensity = maxIntensity;

        cosmicIntensity = uint256(signedIntensity);
        lastCosmicEventTime = block.timestamp;

        emit CosmicEventTriggered(cosmicIntensity);
        emit ParameterUpdated("CosmicIntensity", oldIntensity, cosmicIntensity);
    }

    // --- Parameter Management ---

    /**
     * @notice Sets the base yield factor. Callable by Guardian or Owner.
     * @param newFactor New base yield factor (basis points per unit staked per day).
     */
    function setBaseYieldFactor(uint256 newFactor) external onlyGuardianOrOwner {
         uint256 oldValue = baseYieldFactor;
         baseYieldFactor = newFactor;
         emit ParameterUpdated("baseYieldFactor", oldValue, newFactor);
    }

    /**
     * @notice Sets the black hole burn rate. Callable by Guardian or Owner.
     * @param newRate New black hole burn rate (basis points of burned amount returned).
     */
    function setBlackHoleBurnRate(uint256 newRate) external onlyGuardianOrOwner {
         // Add validation? e.g., newRate <= 10000 (cannot return more than burned)
         uint256 oldValue = blackHoleBurnRate;
         blackHoleBurnRate = newRate;
         emit ParameterUpdated("blackHoleBurnRate", oldValue, newRate);
    }

    /**
     * @notice Sets the black hole cooldown period. Callable by Guardian or Owner.
     * @param newCooldown New cooldown duration in seconds.
     */
    function setBlackHoleCooldown(uint256 newCooldown) external onlyGuardianOrOwner {
         uint256 oldValue = blackHoleCooldown;
         blackHoleCooldown = newCooldown;
         emit ParameterUpdated("blackHoleCooldown", oldValue, newCooldown);
    }

    /**
     * @notice Sets the epoch duration. Callable by Guardian or Owner.
     * @param newDuration New epoch duration in seconds.
     */
    function setEpochDuration(uint256 newDuration) external onlyGuardianOrOwner {
        // Ensure duration is non-zero to avoid division issues if used in calc
         if (newDuration == 0) return; // Or revert
         uint256 oldValue = epochDuration;
         epochDuration = newDuration;
         emit ParameterUpdated("epochDuration", oldValue, newDuration);
    }


    // --- Query Functions ---

    /**
     * @notice Gets the available (non-staked) Cosmic Essence balance for a user.
     * @param user The address of the user.
     * @return The available essence balance.
     */
    function getAvailableEssence(address user) external view returns (uint256) {
        return userEssenceBalances[user];
    }

    /**
     * @notice Gets the staked Cosmic Essence balance for a user.
     * @param user The address of the user.
     * @return The staked essence balance.
     */
    function getStakedEssence(address user) external view returns (uint256) {
        return userStakedEssence[user];
    }

     /**
     * @notice Gets the total available essence in the contract (sum of all userEssenceBalances).
     * @dev This requires iterating or maintaining a sum, which can be gas-intensive.
     *      A more efficient way is to only query total supply and total staked, inferring available.
     *      Let's provide the inferred value based on total supply and total staked + protocol fees.
     *      However, userEssenceBalances is the *user's* available essence. Let's rename this query
     *      or provide a different one.
     *      Let's stick to getting *user's* available balance via `getAvailableEssence` and
     *      total system supply via `getTotalEssenceSupply`.
     *      This query is likely not needed or intended as "total available in contract".
     *      Removing this function to avoid confusion.
      * function getTotalAvailableEssence() external view returns (uint256);
     */

    /**
     * @notice Gets the total Cosmic Essence staked across all users.
     * @return The total staked essence.
     */
    function getTotalStakedEssence() external view returns (uint256) {
        return totalStakedEssence;
    }

     /**
     * @notice Gets the total Cosmic Essence supply (staked + available + protocol balance).
     * @return The total essence supply.
     */
    function getTotalEssenceSupply() external view returns (uint256) {
        return totalEssenceSupply;
    }

    /**
     * @notice Gets the list of shard IDs owned by a user (available or staked).
     * @param user The address of the user.
     * @return An array of shard IDs.
     */
    function getUserShardIds(address user) external view returns (uint256[] memory) {
        return userShardIds[user];
    }

     /**
     * @notice Gets the list of shard IDs currently staked by a user.
     * @param user The address of the user.
     * @return An array of staked shard IDs.
     */
    function getUserStakedShardIds(address user) external view returns (uint256[] memory) {
        return userStakedShardIds[user];
    }


    /**
     * @notice Gets the boost factor of a specific Star Shard.
     * @param shardId The ID of the shard.
     * @return The boost factor in basis points. Returns 0 if shard doesn't exist.
     */
    function getShardBoostFactor(uint256 shardId) external view returns (uint256) {
        if (starShards[shardId].mintTime == 0) return 0; // Check if shard exists
        return starShards[shardId].boostFactor;
    }

     /**
     * @notice Gets the owner address of a specific Star Shard (user address or contract address if staked).
     * @param shardId The ID of the shard.
     * @return The owner address. Returns address(0) if shard doesn't exist.
     */
    function getShardOwner(uint256 shardId) external view returns (address) {
         if (starShards[shardId].mintTime == 0) return address(0); // Check if shard exists
         return starShards[shardId].owner;
    }

    /**
     * @notice Gets the number of Star Shards owned by a user (available or staked).
     * @param user The address of the user.
     * @return The total count of shards for the user.
     */
    function countUserShards(address user) external view returns (uint256) {
        return userShardIds[user].length + userStakedShardIds[user].length;
    }

    /**
     * @notice Gets the timestamp when a user can next activate the Black Hole Sink.
     * @param user The address of the user.
     * @return The timestamp of the next available activation.
     */
    function getBlackHoleCooldownEnd(address user) external view returns (uint256) {
        return userBlackHoleCooldown[user];
    }

     /**
     * @notice Gets the current Cosmic Intensity value.
     * @return The cosmic intensity.
     */
    function getCosmicIntensity() external view returns (uint256) {
        return cosmicIntensity;
    }

     /**
     * @notice Gets the current epoch number.
     * @return The epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Gets the timestamp of the last cosmic event trigger.
     * @return The timestamp.
     */
    function getLastCosmicEventTime() external view returns (uint256) {
        return lastCosmicEventTime;
    }

    // --- Protocol/Treasury Functions ---

    /**
     * @notice Allows the owner to withdraw any residual or protocol-accumulated essence.
     *         In this contract, essence doesn't explicitly accumulate for the protocol,
     *         but this function serves as a general withdrawal for funds somehow stuck or designated.
     *         Needs to calculate contract's "free" balance (total supply - sum of user balances/staked).
     *         This is complex if supply changes. Let's simplify: assumes a separate protocol balance
     *         or allows withdrawing from userEssenceBalances mapping if address(this) balance is used.
     *         Let's make it withdrawable from the *contract's* conceptual essence balance, which
     *         is the total supply minus all user balances and staked amounts.
     *         This requires tracking a separate contract balance or calculating it.
     *         A simpler approach for this example: assume some function *could* send essence to contract,
     *         and this withdraws that explicit balance. But essence is only in user mappings.
     *         Okay, let's assume owner can withdraw from a specific conceptual 'protocol balance'
     *         which might accumulate from future features (e.g., transaction fees if added).
     *         For now, let's make it withdraw from the *total supply* minus total staked,
     *         minus total *user* available balances. This means withdrawing "leftovers".
     *         Total Essence Supply = Sum(userAvailable) + Sum(userStaked) + Protocol Balance.
     *         Protocol Balance = Total Supply - Total Staked - Sum(userAvailable).
     *         Sum(userAvailable) is hard to calculate without iterating.
     *         Alternative: Protocol Balance = Total Supply - Staked - Pending - Sum(userAvailable).
     *         Let's assume a simple model where the protocol balance is just the total supply minus total staked.
     *         This implies user available balances are part of 'total supply', which is true.
     *         So, protocol balance = total supply - total staked - Sum(userEssenceBalances)
     *         Let's restrict this to *only* withdraw if total supply > total staked + sum of userEssenceBalances
     *         This sum is hard. Okay, simplest is assuming *some* essence could be sent *to the contract address*
     *         in a real ERC20 scenario, and we withdraw that. Since this is internal, let's rethink.
     *         Perhaps fees are added to a `protocolBalance` variable instead of mappings?
     *         Let's add a simple `protocolBalance` variable to accumulate future fees/leftovers.
     */
    uint256 public protocolEssenceBalance;

    /**
     * @notice Transfers essence from the protocol's balance to a recipient.
     *         Callable by the Owner.
     * @param recipient The address to send essence to.
     * @param amount The amount of essence to withdraw.
     */
    function withdrawProtocolFees(address recipient, uint256 amount) external onlyOwner {
         if (recipient == address(0)) revert ZeroAddress();
         if (protocolEssenceBalance < amount) revert InsufficientProtocolBalance(amount, protocolEssenceBalance);

         protocolEssenceBalance -= amount;
         userEssenceBalances[recipient] += amount; // Transferring to a user's available balance
         // Total supply remains unchanged as it's a transfer within the system

         emit ProtocolFeesWithdrawn(recipient, amount);
    }

    // --- Utility Functions (Already covered in Queries) ---
    // getAvailableEssence, getStakedEssence, getTotalStakedEssence, getPendingEssenceYield
    // getShardBoostFactor, getShardOwner, countUserShards, getBlackHoleCooldownEnd
    // getCosmicIntensity, getCurrentEpoch, getLastCosmicEventTime, getTotalEssenceSupply

    // Count function review: We need >= 20.
    // 1. constructor
    // 2. transferOwnership
    // 3. grantGuardianRole
    // 4. revokeGuardianRole
    // 5. mintInitialEssence (Owner)
    // 6. depositEssence
    // 7. withdrawEssence
    // 8. stakeEssence
    // 9. unstakeEssence
    // 10. claimEssenceYield
    // 11. getPendingEssenceYield (view)
    // 12. activateBlackHoleSink
    // 13. advanceEpoch (Guardian/Owner)
    // 14. triggerCosmicEvent (Guardian/Owner)
    // 15. setBaseYieldFactor (Guardian/Owner)
    // 16. setBlackHoleBurnRate (Guardian/Owner)
    // 17. setBlackHoleCooldown (Guardian/Owner)
    // 18. setEpochDuration (Guardian/Owner)
    // 19. getAvailableEssence (view)
    // 20. getStakedEssence (view)
    // 21. getTotalStakedEssence (view)
    // 22. getTotalEssenceSupply (view)
    // 23. getUserShardIds (view)
    // 24. getUserStakedShardIds (view)
    // 25. getShardBoostFactor (view)
    // 26. getShardOwner (view)
    // 27. countUserShards (view)
    // 28. getBlackHoleCooldownEnd (view)
    // 29. getCosmicIntensity (view)
    // 30. getCurrentEpoch (view)
    // 31. getLastCosmicEventTime (view)
    // 32. withdrawProtocolFees (Owner)
    // 33. stakeShard
    // 34. unstakeShard

    // Okay, we have significantly more than 20 functions, covering various aspects of the system.
    // The internal helper functions (_updateUserYield, _attemptShardMint, _removeShardIdFromList)
    // are not counted in the public/external function count.

}
```

---

**Explanation of Concepts and Functions:**

1.  **Cosmic Essence (Internal Fungible):**
    *   `userEssenceBalances`: Tracks essence available for withdrawal or staking.
    *   `userStakedEssence`: Tracks essence currently staked for yield.
    *   `totalEssenceSupply`: Total essence in existence (staked + available + protocol).
    *   `totalStakedEssence`: Sum of all `userStakedEssence`.
    *   Functions: `mintInitialEssence`, `depositEssence` (simulated), `withdrawEssence` (simulated), `stakeEssence`, `unstakeEssence`. Query functions: `getAvailableEssence`, `getStakedEssence`, `getTotalStakedEssence`, `getTotalEssenceSupply`.

2.  **Star Shards (Internal Non-Fungible):**
    *   `StarShard` struct: Holds data like owner, mint time, boost factor, and staking status.
    *   `starShards`: Mapping from ID to `StarShard` data.
    *   `nextShardId`: Counter for unique IDs.
    *   `userShardIds`: List of IDs owned by a user (staked or unstaked).
    *   `userStakedShardIds`: List of IDs currently staked by a user.
    *   Functions: `_attemptShardMint` (internal helper, triggered by `claimEssenceYield`), `stakeShard`, `unstakeShard`. Query functions: `getUserShardIds`, `getUserStakedShardIds`, `getShardBoostFactor`, `getShardOwner`, `countUserShards`.

3.  **Dynamic Yield Generation:**
    *   `baseYieldFactor`, `cosmicIntensity`: Parameters affecting yield rate.
    *   `userLastYieldUpdateTime`, `userPendingYield`: State to track time-based accumulation.
    *   Yield calculation in `getPendingEssenceYield`: `stakedAmount * baseYieldFactor * cosmicIntensity * timeDelta / (time unit * scaling factors)` + `shardBoost`.
    *   `_updateUserYield`: Helper to snapshot accrued yield before state changes.
    *   Function: `claimEssenceYield` (claims pending yield, triggers shard mint attempt). Query: `getPendingEssenceYield`.

4.  **Black Hole Sink:**
    *   `blackHoleBurnRate`: Percentage of burned essence returned.
    *   `blackHoleCooldown`: Time required between activations.
    *   `userBlackHoleCooldown`: Tracks user's next available timestamp.
    *   Function: `activateBlackHoleSink`. Query: `getBlackHoleCooldownEnd`.

5.  **Epochs & Simulated Cosmic Events:**
    *   `currentEpoch`, `epochDuration`, `epochStartTime`: Track the current time period.
    *   `cosmicEventCooldown`, `lastCosmicEventTime`: Track cosmic event timing.
    *   Functions: `advanceEpoch`, `triggerCosmicEvent` (updates `cosmicIntensity`). Queries: `getCurrentEpoch`, `getCosmicIntensity`, `getLastCosmicEventTime`.

6.  **Parameter Management:**
    *   Functions for Guardian/Owner to adjust key rates/durations: `setBaseYieldFactor`, `setBlackHoleBurnRate`, `setBlackHoleCooldown`, `setEpochDuration`.

7.  **Roles:**
    *   `owner`: Standard ownership.
    *   `guardians`: Mapping for a second tier of control.
    *   Modifiers: `onlyOwner`, `onlyGuardianOrOwner`.
    *   Functions: `transferOwnership`, `grantGuardianRole`, `revokeGuardianRole`.

8.  **Protocol Treasury:**
    *   `protocolEssenceBalance`: A conceptual balance for funds not held by users (e.g., future fees).
    *   Function: `withdrawProtocolFees` (Owner only).

This contract provides a complex system with intertwined mechanics (staking affects yield, shards boost yield, cosmic events affect yield, black hole burns essence) and multiple distinct functions (well over 20). The internal tracking of assets distinguishes it from standard ERC20/ERC721 based protocols. The simulated randomness and epoch system add creative elements.