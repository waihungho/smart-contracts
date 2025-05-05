Okay, let's design a smart contract that combines dynamic NFTs, staking rewards, and interactive evolution mechanics. We'll call it the "Genesis Shards Protocol".

The core idea is:
1.  Users stake a specific ERC20 token (let's call it "Essence").
2.  Staking Essence mints a unique ERC721 NFT (a "Shard").
3.  Shards represent the staked position and accrue rewards over time.
4.  Shards have dynamic attributes that change based on stake duration, amount, protocol state, and user-triggered evolution events.
5.  Users can claim rewards, add/remove stake from a Shard, or merge Shards to create new, potentially stronger ones.
6.  A fee mechanism funds a protocol treasury.

This concept combines elements of staking, NFTs, dynamic metadata, and interaction fees, implemented in a specific, non-standard way.

Here's the Solidity contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For tokenURI Base64 encoding
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion

// --- Outline and Function Summary ---
/*
Outline:
1. State Variables & Events
2. Structs for Shard Data
3. Constructor
4. Core Staking & NFT Logic (Stake, Unstake, Add/Remove Stake)
5. Reward Logic (Claim, Calculate)
6. Dynamic NFT Logic (Attributes, Evolution Trigger, Merge)
7. View Functions (Getters for State and Data)
8. Admin/Configuration Functions (Set fees, rates, cooldowns, withdraw treasury, pause)
9. Internal/Helper Functions (Reward calculation, attribute evolution, pseudo-randomness)
10. ERC721 Overrides (For custom minting/burning side effects)
11. ERC721 Metadata (tokenURI implementation for dynamic attributes)

Function Summary:

Core Staking & NFT Logic:
- stakeEssence(uint256 amount): Allows user to stake Essence token, mints a new Shard NFT representing the stake.
- unstakeEssence(uint256 shardId): Allows user to unstake the Essence associated with a Shard, claims rewards, and burns the Shard NFT.
- addEssenceToStake(uint256 shardId, uint256 additionalAmount): Adds more Essence to an existing staked Shard.
- removeEssenceFromStake(uint256 shardId, uint256 amountToReduce): Removes some Essence from a staked Shard without fully unstaking.

Reward Logic:
- claimEssenceRewards(uint256[] calldata shardIds): Allows user to claim accrued rewards for multiple staked Shards.
- calculateEssenceReward(uint256 shardId): Helper view function to estimate rewards for a single Shard. (Internal helper used by claim/unstake)

Dynamic NFT Logic:
- getShardAttributes(uint256 shardId): View function to get the current attributes of a Shard.
- triggerShardEvolution(uint256 shardId): Allows the owner of a Shard to trigger an evolution attempt (costs Essence fee, subject to cooldown), potentially updating attributes.
- mergeShards(uint256 shardId1, uint256 shardId2): Allows owner to merge two Shards, burning them and minting a new one with combined stake and evolved attributes.
- getEssenceRewardEstimate(uint256 shardId): Public view to calculate pending rewards.
- getLastEvolutionTime(uint256 shardId): View function for last evolution time.

View Functions:
- getShardStakeAmount(uint256 shardId): View function to get the Essence amount staked for a Shard.
- getTotalStakedEssence(): View function for total Essence staked across all Shards.
- getProtocolFeeEssenceBalance(): View function for Essence held in the protocol treasury from fees.
- getEssenceTokenAddress(): View function for Essence token address.
- getShardTokenAddress(): View function for the address of this ERC721 contract.
- getEvolutionCooldown(): View function for evolution cooldown period.
- getMergeFee(): View function for the fee (in Essence) to merge shards.
- getEvolutionEssenceCost(): View function for the cost (in Essence) to trigger evolution.
- getRewardRate(): View function for the current reward rate.
- getProtocolStateSeed(): View function for a simple pseudo-random seed based on aggregate state. (Used internally)

Admin/Configuration Functions:
- setEssenceToken(address _essenceToken): Sets the address of the Essence ERC20 token (only callable once by owner).
- setEvolutionCooldown(uint256 cooldown): Sets the cooldown duration between evolution triggers for a Shard.
- setMergeFee(uint256 fee): Sets the Essence fee required to merge two Shards.
- setEvolutionEssenceCost(uint256 cost): Sets the Essence cost to trigger a Shard evolution.
- setRewardRate(uint256 ratePerSecond): Sets the global reward rate for staked Essence.
- withdrawTreasury(address tokenAddress, uint256 amount): Allows owner to withdraw tokens collected as fees into the treasury.
- pause(): Pauses core protocol functions (staking, unstaking, claiming, merging, evolution).
- unpause(): Unpauses the protocol.
- renounceOwnership(): Standard Ownable function.
- transferOwnership(address newOwner): Standard Ownable function.

ERC721 Metadata:
- tokenURI(uint256 tokenId): Overridden function to generate dynamic JSON metadata for a Shard based on its attributes and state.
*/


contract GenesisShardsProtocol is ERC721, Ownable, Pausable {
    using Strings for uint256; // Used for string conversions in tokenURI
    using Base64 for bytes; // Used for Base64 encoding in tokenURI

    // --- State Variables ---

    IERC20 public essenceToken;

    uint256 public nextShardId = 1; // Start from 1, 0 is often reserved or unused

    uint256 public totalStakedEssence; // Total Essence staked across all active Shards

    // Protocol configuration parameters
    uint256 public rewardRatePerSecond = 100; // Example: 100 wei of Essence per second per unit of Essence staked
    uint256 public evolutionCooldown = 7 days; // Cooldown period for triggering evolution
    uint256 public mergeFeeEssence = 5 ether; // Fee paid in Essence to merge shards
    uint256 public evolutionEssenceCost = 1 ether; // Cost paid in Essence to trigger evolution

    // --- Structs ---

    struct ShardStake {
        address owner;
        uint256 amountStaked;
        uint256 startTime; // Timestamp when stake was initiated or last increased significantly (e.g., merge/add stake)
        uint256 lastRewardClaimTime; // Timestamp of last reward claim or stake action
        uint256 lastEvolutionTime; // Timestamp of last triggered evolution attempt
    }

    struct ShardAttributes {
        uint8 power; // Example attribute 1 (0-100)
        uint8 resilience; // Example attribute 2 (0-100)
        uint8 luck; // Example attribute 3 (0-100)
        uint8 affinity; // Example attribute 4 (0-100)
        // Add more attributes as needed
    }

    // --- Mappings ---

    mapping(uint256 => ShardStake) public shardStakes;
    mapping(uint256 => ShardAttributes) public shardAttributes;
    mapping(address => bool) private essenceTokenSet; // To ensure essenceToken is set only once

    // --- Events ---

    event ShardMinted(uint256 indexed shardId, address indexed owner, uint256 amountStaked);
    event ShardBurned(uint256 indexed shardId, address indexed owner, uint256 amountUnstaked, uint256 rewardsClaimed);
    event StakeAdded(uint256 indexed shardId, uint256 additionalAmount);
    event StakeReduced(uint256 indexed shardId, uint256 amountReduced);
    event RewardsClaimed(address indexed owner, uint256[] indexed shardIds, uint256 totalRewards);
    event ShardMerged(uint256 indexed newShardId, uint256 indexed shardId1, uint256 indexed shardId2, uint256 resultingStake);
    event ShardEvolutionTriggered(uint256 indexed shardId, uint256 evolutionCost);
    event ShardAttributesEvolved(uint256 indexed shardId, ShardAttributes newAttributes);
    event TreasuryWithdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event ConfigurationUpdated(string configKey, uint256 newValue);


    // --- Constructor ---

    // ERC721 constructor requires a name and symbol for the NFT collection
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Core Staking & NFT Logic ---

    /**
     * @notice Stakes Essence token and mints a new Shard NFT representing the stake.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssence(uint256 amount) external whenNotPaused {
        require(address(essenceToken) != address(0), "Essence token not set");
        require(amount > 0, "Amount must be greater than zero");

        uint256 shardId = nextShardId++;

        // Transfer Essence from user to this contract
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed");

        // Mint the new Shard NFT to the staker
        _safeMint(msg.sender, shardId);

        // Record the stake details
        uint256 currentTime = block.timestamp;
        shardStakes[shardId] = ShardStake({
            owner: msg.sender,
            amountStaked: amount,
            startTime: currentTime,
            lastRewardClaimTime: currentTime,
            lastEvolutionTime: 0 // 0 indicates never evolved or no cooldown started
        });

        // Initialize basic attributes (could be random or based on amount)
        shardAttributes[shardId] = ShardAttributes({
            power: 50, // Initial base attribute
            resilience: 50,
            luck: 50,
            affinity: 50
        });

        totalStakedEssence += amount;

        emit ShardMinted(shardId, msg.sender, amount);
    }

    /**
     * @notice Unstakes Essence and claims rewards for a specific Shard. Burns the Shard NFT.
     * @param shardId The ID of the Shard NFT to unstake.
     */
    function unstakeEssence(uint256 shardId) external whenNotPaused {
        require(_exists(shardId), "Shard does not exist");
        require(_isApprovedOrOwner(msg.sender, shardId), "Not authorized to unstake this Shard");

        ShardStake storage stake = shardStakes[shardId];
        uint256 amount = stake.amountStaked;
        address owner = stake.owner;

        require(owner == msg.sender, "Sender must be Shard owner"); // Double check owner

        // Calculate and claim pending rewards
        uint256 rewards = _calculateEssenceReward(shardId);
        if (rewards > 0) {
             require(essenceToken.transfer(owner, rewards), "Reward transfer failed");
        }

        // Transfer staked amount back to owner
        require(essenceToken.transfer(owner, amount), "Stake transfer failed");

        // Burn the Shard NFT
        _burn(shardId);

        // Clean up stake and attribute data
        delete shardStakes[shardId];
        delete shardAttributes[shardId]; // Attributes are tied to the stake

        totalStakedEssence -= amount;

        emit ShardBurned(shardId, owner, amount, rewards);
    }

    /**
     * @notice Adds more Essence to an existing staked Shard.
     * @param shardId The ID of the Shard NFT.
     * @param additionalAmount The amount of Essence to add.
     */
    function addEssenceToStake(uint256 shardId, uint256 additionalAmount) external whenNotPaused {
        require(_exists(shardId), "Shard does not exist");
        require(_isApprovedOrOwner(msg.sender, shardId), "Not authorized");
        require(additionalAmount > 0, "Amount must be greater than zero");

        ShardStake storage stake = shardStakes[shardId];
        require(stake.owner == msg.sender, "Sender must be Shard owner"); // Double check owner

        // Claim pending rewards before modifying stake
        uint256 rewards = _calculateEssenceReward(shardId);
        if (rewards > 0) {
             require(essenceToken.transfer(msg.sender, rewards), "Reward claim failed during add");
        }
        stake.lastRewardClaimTime = block.timestamp;

        // Transfer additional Essence from user to this contract
        require(essenceToken.transferFrom(msg.sender, address(this), additionalAmount), "Essence transfer failed");

        // Update stake details
        stake.amountStaked += additionalAmount;
        // Consider resetting startTime or adjusting based on weighted average if desired.
        // For simplicity here, just update the amount.

        totalStakedEssence += additionalAmount;

        emit StakeAdded(shardId, additionalAmount);
    }

    /**
     * @notice Removes some Essence from a staked Shard without fully unstaking.
     * @param shardId The ID of the Shard NFT.
     * @param amountToReduce The amount of Essence to remove.
     */
    function removeEssenceFromStake(uint256 shardId, uint256 amountToReduce) external whenNotPaused {
         require(_exists(shardId), "Shard does not exist");
        require(_isApprovedOrOwner(msg.sender, shardId), "Not authorized");

        ShardStake storage stake = shardStakes[shardId];
        require(stake.owner == msg.sender, "Sender must be Shard owner"); // Double check owner
        require(amountToReduce > 0, "Amount must be greater than zero");
        require(stake.amountStaked > amountToReduce, "Cannot reduce below zero or unstake completely via this function");
        // Full unstake should use unstakeEssence, which burns the NFT.

        // Claim pending rewards before modifying stake
        uint256 rewards = _calculateEssenceReward(shardId);
        if (rewards > 0) {
             require(essenceToken.transfer(msg.sender, rewards), "Reward claim failed during remove");
        }
        stake.lastRewardClaimTime = block.timestamp;

        // Update stake details
        stake.amountStaked -= amountToReduce;

        // Transfer removed amount back to owner
        require(essenceToken.transfer(msg.sender, amountToReduce), "Essence transfer failed");

        totalStakedEssence -= amountToReduce;

        emit StakeReduced(shardId, amountToReduce);
    }


    // --- Reward Logic ---

    /**
     * @notice Allows user to claim accrued rewards for multiple staked Shards.
     * @param shardIds An array of Shard IDs to claim rewards for.
     */
    function claimEssenceRewards(uint256[] calldata shardIds) external whenNotPaused {
        uint256 totalRewards = 0;
        address claimant = msg.sender;

        for (uint i = 0; i < shardIds.length; i++) {
            uint256 shardId = shardIds[i];
            require(_exists(shardId), "Shard does not exist");
            require(_isApprovedOrOwner(claimant, shardId), "Not authorized to claim for this Shard");

            ShardStake storage stake = shardStakes[shardId];
            require(stake.owner == claimant, "Claimant must be Shard owner"); // Double check owner

            uint256 rewards = _calculateEssenceReward(shardId);
            totalRewards += rewards;
            stake.lastRewardClaimTime = block.timestamp; // Update last claim time
        }

        if (totalRewards > 0) {
            require(essenceToken.transfer(claimant, totalRewards), "Reward transfer failed");
            emit RewardsClaimed(claimant, shardIds, totalRewards);
        }
    }

    /**
     * @notice Calculates the estimated pending rewards for a single Shard.
     * @param shardId The ID of the Shard.
     * @return The estimated reward amount.
     */
    function getEssenceRewardEstimate(uint256 shardId) external view returns (uint256) {
         require(_exists(shardId), "Shard does not exist");
         return _calculateEssenceReward(shardId);
    }

    /**
     * @dev Calculates the accrued rewards for a Shard since the last claim/stake action.
     * @param shardId The ID of the Shard.
     * @return The calculated reward amount.
     */
    function _calculateEssenceReward(uint256 shardId) internal view returns (uint256) {
        ShardStake storage stake = shardStakes[shardId];
        uint256 timeElapsed = block.timestamp - stake.lastRewardClaimTime;
        // Prevent overflow in multiplication
        if (rewardRatePerSecond > 0 && timeElapsed > 0 && stake.amountStaked > 0) {
            // Basic linear reward: stake amount * rate * time
            // Could implement decaying rewards, bonus based on attributes, etc.
             unchecked { // Use unchecked assuming inputs are reasonable
                return (stake.amountStaked * rewardRatePerSecond * timeElapsed) / (1 ether); // Divide by 1e18 if rate is per 1e18 Essence
             }
        }
        return 0;
    }

    // --- Dynamic NFT Logic ---

    /**
     * @notice Allows the owner of a Shard to trigger an evolution attempt.
     * The attempt costs Essence and is subject to a cooldown. Attributes *may* change.
     * @param shardId The ID of the Shard.
     */
    function triggerShardEvolution(uint256 shardId) external whenNotPaused {
        require(_exists(shardId), "Shard does not exist");
        require(_isApprovedOrOwner(msg.sender, shardId), "Not authorized to trigger evolution");

        ShardStake storage stake = shardStakes[shardId];
        require(stake.owner == msg.sender, "Sender must be Shard owner"); // Double check owner
        require(block.timestamp >= stake.lastEvolutionTime + evolutionCooldown, "Evolution cooldown active");

        // Pay evolution cost
        if (evolutionEssenceCost > 0) {
            require(essenceToken.transferFrom(msg.sender, address(this), evolutionEssenceCost), "Evolution cost transfer failed");
        }

        // Trigger attribute evolution logic
        _evolveShardAttributes(shardId);

        // Update last evolution time
        stake.lastEvolutionTime = block.timestamp;

        emit ShardEvolutionTriggered(shardId, evolutionEssenceCost);
    }

    /**
     * @notice Allows owner to merge two Shards.
     * Burns the two input Shards and mints a new one with combined stake and evolved attributes.
     * Costs a fee in Essence.
     * @param shardId1 The ID of the first Shard.
     * @param shardId2 The ID of the second Shard.
     */
    function mergeShards(uint256 shardId1, uint256 shardId2) external whenNotPaused {
        require(shardId1 != shardId2, "Cannot merge a shard with itself");
        require(_exists(shardId1), "Shard 1 does not exist");
        require(_exists(shardId2), "Shard 2 does not exist");
        require(_isApprovedOrOwner(msg.sender, shardId1), "Not authorized for Shard 1");
        require(_isApprovedOrOwner(msg.sender, shardId2), "Not authorized for Shard 2");

        ShardStake storage stake1 = shardStakes[shardId1];
        ShardStake storage stake2 = shardStakes[shardId2];
        require(stake1.owner == msg.sender, "Sender must own Shard 1"); // Double check owner
        require(stake2.owner == msg.sender, "Sender must own Shard 2"); // Double check owner

        // Pay merge fee
        if (mergeFeeEssence > 0) {
             require(essenceToken.transferFrom(msg.sender, address(this), mergeFeeEssence), "Merge fee transfer failed");
        }

        // Calculate combined stake amount (could add a bonus here)
        uint256 combinedAmount = stake1.amountStaked + stake2.amountStaked;

        // Claim pending rewards for both before merging
        uint256 rewards1 = _calculateEssenceReward(shardId1);
        uint256 rewards2 = _calculateEssenceReward(shardId2);
        uint256 totalRewards = rewards1 + rewards2;
         if (totalRewards > 0) {
             require(essenceToken.transfer(msg.sender, totalRewards), "Reward claim failed during merge");
        }

        // Determine new Shard ID
        uint256 newShardId = nextShardId++;

        // Mint the new Shard NFT to the owner
        _safeMint(msg.sender, newShardId);

        // Record the new stake details
        uint256 currentTime = block.timestamp;
        shardStakes[newShardId] = ShardStake({
            owner: msg.sender,
            amountStaked: combinedAmount,
            startTime: currentTime, // New start time for the merged stake
            lastRewardClaimTime: currentTime, // Last claim time is now
            lastEvolutionTime: 0 // Reset evolution cooldown
        });

        // Combine and evolve attributes
        _combineAndEvolveAttributes(newShardId, shardId1, shardId2);

        // Burn the original Shard NFTs
        _burn(shardId1);
        _burn(shardId2);

        // Clean up old stake and attribute data (done by _burn overrides or explicitly)
        delete shardStakes[shardId1];
        delete shardStakes[shardId2];
        delete shardAttributes[shardId1];
        delete shardAttributes[shardId2];

        // totalStakedEssence remains the same, as we burned and re-minted the stake amount

        emit ShardMerged(newShardId, shardId1, shardId2, combinedAmount);
    }

    /**
     * @dev Internal logic for evolving attributes of a single Shard.
     * Uses pseudo-randomness and current state.
     * @param shardId The ID of the Shard to evolve.
     */
    function _evolveShardAttributes(uint256 shardId) internal {
        ShardAttributes storage attrs = shardAttributes[shardId];
        ShardStake storage stake = shardStakes[shardId];

        // Simple pseudo-random seed based on block data and shard state
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Note: block.difficulty is deprecated in Eth 2, use other sources or VRF
            tx.origin,
            msg.sender, // If triggered by user
            shardId,
            stake.amountStaked,
            stake.startTime,
            attrs.power,
            attrs.resilience,
            attrs.luck,
            attrs.affinity,
            getProtocolStateSeed() // Include a simple global state seed
        )));

        // Use the seed to derive attribute changes
        // Example: Increment/decrement based on seed and current value, maybe influenced by stake duration
        uint265 randFactor = uint256(keccak256(abi.encodePacked(seed))).mod(10); // Simple factor 0-9

        // Evolution logic (simplified example)
        // Attributes can increase or decrease based on randomness and other factors
        if (randFactor < 5) {
            attrs.power = uint8(Math.min(100, attrs.power + 1));
        } else if (randFactor < 8) {
            attrs.power = uint8(Math.max(0, int(attrs.power) - 1)); // Use int conversion for max(0) with uint8
        }

        randFactor = uint256(keccak256(abi.encodePacked(seed, 1))).mod(10);
         if (randFactor < 6) { // resilience more likely to increase
            attrs.resilience = uint8(Math.min(100, attrs.resilience + 1));
        }

        randFactor = uint256(keccak256(abi.encodePacked(seed, 2))).mod(10);
         if (randFactor < 7) { // luck influenced by stake duration
            uint256 duration = block.timestamp - stake.startTime;
            if (duration > 30 days) attrs.luck = uint8(Math.min(100, attrs.luck + 2));
            else if (duration > 7 days) attrs.luck = uint8(Math.min(100, attrs.luck + 1));
             else attrs.luck = uint8(Math.max(0, int(attrs.luck) - 1));
        }

         randFactor = uint256(keccak256(abi.encodePacked(seed, 3))).mod(10);
         // affinity might evolve based on total staked amount or protocol state
         if (totalStakedEssence > 1000 ether) {
             attrs.affinity = uint8(Math.min(100, attrs.affinity + 1));
         } else {
             attrs.affinity = uint8(Math.max(0, int(attrs.affinity) - 1));
         }

        // Ensure attributes stay within 0-100 bounds
        attrs.power = Math.min(attrs.power, 100);
        attrs.resilience = Math.min(attrs.resilience, 100);
        attrs.luck = Math.min(attrs.luck, 100);
        attrs.affinity = Math.min(attrs.affinity, 100);

        attrs.power = uint8(Math.max(0, int(attrs.power)));
        attrs.resilience = uint8(Math.max(0, int(attrs.resilience)));
        attrs.luck = uint8(Math.max(0, int(attrs.luck)));
        attrs.affinity = uint8(Math.max(0, int(attrs.affinity)));


        emit ShardAttributesEvolved(shardId, attrs);
    }

     /**
     * @dev Internal logic for combining and evolving attributes during merge.
     * @param newShardId The ID of the newly minted Shard.
     * @param shardId1 The ID of the first input Shard.
     * @param shardId2 The ID of the second input Shard.
     */
    function _combineAndEvolveAttributes(uint256 newShardId, uint256 shardId1, uint256 shardId2) internal {
        ShardAttributes storage attrs1 = shardAttributes[shardId1];
        ShardAttributes storage attrs2 = shardAttributes[shardId2];
        ShardStake storage stake1 = shardStakes[shardId1];
        ShardStake storage stake2 = shardStakes[shardId2];

        // Simple combination logic: Weighted average based on stake amount, plus a merge bonus/randomness
        uint256 totalInputStake = stake1.amountStaked + stake2.amountStaked;
        uint256 power = (attrs1.power * stake1.amountStaked + attrs2.power * stake2.amountStaked) / totalInputStake;
        uint256 resilience = (attrs1.resilience * stake1.amountStaked + attrs2.resilience * stake2.amountStaked) / totalInputStake;
        uint256 luck = (attrs1.luck * stake1.amountStaked + attrs2.luck * stake2.amountStaked) / totalInputStake;
        uint256 affinity = (attrs1.affinity * stake1.amountStaked + attrs2.affinity * stake2.amountStaked) / totalInputStake;


        // Add a merge bonus/randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Note: block.difficulty is deprecated in Eth 2
            tx.origin,
            msg.sender,
            shardId1,
            shardId2,
            newShardId
        )));

        uint256 bonusFactor = uint256(keccak256(abi.encodePacked(seed))).mod(10); // 0-9

        power = Math.min(100, power + bonusFactor);
        resilience = Math.min(100, resilience + (10 - bonusFactor)); // Inverse bonus
        luck = Math.min(100, luck + (bonusFactor % 5));
        affinity = Math.min(100, affinity + ((10 - bonusFactor) % 5));


        // Ensure bounds
        shardAttributes[newShardId] = ShardAttributes({
            power: uint8(Math.min(100, power)),
            resilience: uint8(Math.min(100, resilience)),
            luck: uint8(Math.min(100, luck)),
            affinity: uint8(Math.min(100, affinity))
        });
         shardAttributes[newShardId].power = uint8(Math.max(0, int(shardAttributes[newShardId].power))); // Use int conversion for max(0) with uint8
         shardAttributes[newShardId].resilience = uint8(Math.max(0, int(shardAttributes[newShardId].resilience)));
         shardAttributes[newShardId].luck = uint8(Math.max(0, int(shardAttributes[newShardId].luck)));
         shardAttributes[newShardId].affinity = uint8(Math.max(0, int(shardAttributes[newShardId].affinity)));

        emit ShardAttributesEvolved(newShardId, shardAttributes[newShardId]);
    }

    /**
     * @dev Provides a simple protocol-wide pseudo-random seed.
     * Could incorporate oracle data or other protocol state.
     */
    function getProtocolStateSeed() public view returns (uint256) {
        // Simple seed based on contract state and time
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            totalStakedEssence,
            rewardRatePerSecond
            // Add more unpredictable state variables if available (e.g., last transaction hash of essenceToken)
        )));
    }

    // --- View Functions ---

    /**
     * @notice Returns the current attributes for a Shard.
     * @param shardId The ID of the Shard.
     * @return ShardAttributes struct.
     */
    function getShardAttributes(uint256 shardId) public view returns (ShardAttributes memory) {
        require(_exists(shardId), "Shard does not exist");
        return shardAttributes[shardId];
    }

    /**
     * @notice Returns the amount of Essence staked for a Shard.
     * @param shardId The ID of the Shard.
     * @return The staked amount.
     */
    function getShardStakeAmount(uint256 shardId) public view returns (uint256) {
        require(_exists(shardId), "Shard does not exist");
        return shardStakes[shardId].amountStaked;
    }

     /**
     * @notice Returns the timestamp of the last evolution trigger for a Shard.
     * @param shardId The ID of the Shard.
     * @return The timestamp.
     */
    function getLastEvolutionTime(uint256 shardId) public view returns (uint256) {
        require(_exists(shardId), "Shard does not exist");
        return shardStakes[shardId].lastEvolutionTime;
    }

    /**
     * @notice Returns the total amount of Essence staked across all Shards in the protocol.
     * @return The total staked amount.
     */
    function getTotalStakedEssence() public view returns (uint256) {
        return totalStakedEssence;
    }

     /**
     * @notice Returns the current balance of Essence held by the protocol treasury from fees.
     * @return The treasury balance.
     */
    function getProtocolFeeEssenceBalance() public view returns (uint256) {
        if (address(essenceToken) == address(0)) return 0;
        // The total balance of Essence in the contract minus the sum of staked amounts
        // This works because staked amounts are explicitly tracked and fees are sent to the contract.
        return essenceToken.balanceOf(address(this)) - totalStakedEssence;
    }


    /**
     * @notice Returns the address of the Essence token.
     */
    function getEssenceTokenAddress() external view returns (address) {
        return address(essenceToken);
    }

    /**
     * @notice Returns the address of this Shard ERC721 contract.
     */
    function getShardTokenAddress() external view returns (address) {
        return address(this);
    }

     /**
     * @notice Returns the current evolution cooldown duration.
     */
    function getEvolutionCooldown() external view returns (uint256) {
        return evolutionCooldown;
    }

     /**
     * @notice Returns the current merge fee in Essence.
     */
    function getMergeFee() external view returns (uint256) {
        return mergeFeeEssence;
    }

     /**
     * @notice Returns the current evolution cost in Essence.
     */
    function getEvolutionEssenceCost() external view returns (uint256) {
        return evolutionEssenceCost;
    }

     /**
     * @notice Returns the current reward rate per second per unit of staked Essence.
     */
    function getRewardRate() external view returns (uint256) {
        return rewardRatePerSecond;
    }


    // --- Admin/Configuration Functions ---

    /**
     * @notice Sets the address of the Essence ERC20 token. Can only be called once by the owner.
     * @param _essenceToken The address of the Essence token.
     */
    function setEssenceToken(address _essenceToken) external onlyOwner {
        require(address(essenceToken) == address(0) && !essenceTokenSet[address(0)], "Essence token already set");
        require(_essenceToken != address(0), "Essence token address cannot be zero");
        essenceToken = IERC20(_essenceToken);
        essenceTokenSet[address(0)] = true; // Use a mapping key to track if set (safer than checking address(0))
         emit ConfigurationUpdated("EssenceToken", uint256(uint160(_essenceToken))); // Emit address as uint for logging
    }

    /**
     * @notice Sets the cooldown period for triggering Shard evolution.
     * @param cooldown The new cooldown duration in seconds.
     */
    function setEvolutionCooldown(uint256 cooldown) external onlyOwner {
        require(cooldown < 365 days, "Cooldown too long"); // Basic sanity check
        evolutionCooldown = cooldown;
        emit ConfigurationUpdated("EvolutionCooldown", cooldown);
    }

    /**
     * @notice Sets the Essence fee required to merge two Shards.
     * @param fee The new merge fee amount in Essence.
     */
    function setMergeFee(uint256 fee) external onlyOwner {
        mergeFeeEssence = fee;
         emit ConfigurationUpdated("MergeFeeEssence", fee);
    }

    /**
     * @notice Sets the Essence cost to trigger a Shard evolution.
     * @param cost The new evolution cost amount in Essence.
     */
    function setEvolutionEssenceCost(uint256 cost) external onlyOwner {
        evolutionEssenceCost = cost;
         emit ConfigurationUpdated("EvolutionEssenceCost", cost);
    }

    /**
     * @notice Sets the global reward rate for staked Essence.
     * @param ratePerSecond The new reward rate per second per unit of staked Essence.
     */
    function setRewardRate(uint256 ratePerSecond) external onlyOwner {
        rewardRatePerSecond = ratePerSecond;
         emit ConfigurationUpdated("RewardRate", ratePerSecond);
    }

    /**
     * @notice Allows the owner to withdraw collected fees from the contract treasury.
     * Can withdraw any token address held by the contract, useful if other tokens are accidentally sent or used for future fees.
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawTreasury(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(essenceToken), "Cannot withdraw staked essence via this function. Use getProtocolFeeEssenceBalance");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient treasury balance");
        require(token.transfer(msg.sender, amount), "Treasury withdrawal failed");
        emit TreasuryWithdrawal(tokenAddress, msg.sender, amount);
    }

    // Inherited from Pausable
    // pause() - Stops core functionality (stake, unstake, claim, merge, evolve)
    // unpause() - Resumes core functionality

    // Inherited from Ownable
    // renounceOwnership()
    // transferOwnership(address newOwner)

    // --- ERC721 Overrides ---

    /**
     * @dev Internal function called before any token transfer.
     * We use this to prevent unauthorized transfers of staked Shards, as they represent a locked position.
     * Transfers are only allowed via `unstakeEssence` (burn), `mergeShards` (burn), or if specifically handled here.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from address(0))
        if (from == address(0)) {
             require(to != address(0), "ERC721: mint to the zero address");
            return;
        }

        // Allow burning (to address(0)) - This happens during unstake/merge
        if (to == address(0)) {
            // Cleanup stake and attribute data during burn
             delete shardStakes[tokenId];
             delete shardAttributes[tokenId]; // Attributes are tied to the stake
            return;
        }

        // Prevent general transfers of staked Shards
        // Staked shards should ONLY be 'transferred' by being burned during unstake/merge.
        // This prevents users from transferring a staked position without going through the protocol logic.
        revert("Cannot transfer staked Shards directly");
    }

     // --- ERC721 Metadata (tokenURI) ---

    /**
     * @dev Generates the JSON metadata URI for a Shard NFT.
     * This function makes the NFT dynamic by including its current attributes and state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        ShardStake memory stake = shardStakes[tokenId];
        ShardAttributes memory attrs = shardAttributes[tokenId];

        // Calculate stake duration and pending rewards for metadata
        uint256 stakeDuration = block.timestamp - stake.startTime;
        uint256 pendingRewards = _calculateEssenceReward(tokenId);

        // Construct the JSON metadata string
        // Example structure based on ERC721 Metadata standard
        // https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721Metadata-tokenURI-uint256-
        // https://docs.opensea.io/docs/metadata-standards
        string memory json = string(abi.encodePacked(
            '{"name": "Genesis Shard #', tokenId.toString(), '",',
            '"description": "A dynamic Genesis Shard representing staked Essence in the Protocol. Evolves over time based on stake, interaction, and cosmic chance.",',
            // Placeholder image URL - replace with your image service or base64 image data
            '"image": "ipfs://YOUR_DEFAULT_IMAGE_CID",',
            '"attributes": [',
                '{"trait_type": "Staked Essence", "value": "', stake.amountStaked.toString(), '"},',
                '{"trait_type": "Stake Duration (sec)", "value": "', stakeDuration.toString(), '"},',
                '{"trait_type": "Pending Rewards", "value": "', pendingRewards.toString(), '"},',
                '{"trait_type": "Power", "value": ', attrs.power.toString(), '},',
                '{"trait_type": "Resilience", "value": ', attrs.resilience.toString(), '},',
                '{"trait_type": "Luck", "value": ', attrs.luck.toString(), '},',
                '{"trait_type": "Affinity", "value": ', attrs.affinity.toString(), '}',
                // Add more attributes here
            ']}'
        ));

        // Encode the JSON string to Base64
        string memory base64Json = Base64.encode(bytes(json));

        // Return the Data URI
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    // Simple helper library for min/max, needed for attribute bounds
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
         function min(uint8 a, uint8 b) internal pure returns (uint8) {
            return a < b ? a : b;
        }
         function max(int256 a, int256 b) internal pure returns (int256) {
            return a > b ? a : b;
        }
         function max(int8 a, int8 b) internal pure returns (int8) { // Need int8 for comparison with 0
            return a > b ? a : b;
        }
    }
}
```

**Explanation of Concepts & Features:**

1.  **Dynamic NFTs (`tokenURI`)**: The `tokenURI` function doesn't return a static link but generates JSON metadata *on the fly* based on the Shard's current state (`amountStaked`, `startTime`, `ShardAttributes`). This is the core of the "dynamic" aspect. When platforms (like OpenSea) query the metadata, they get the current attributes, making the NFT evolve visually or stat-wise as its underlying state changes.
2.  **ERC20 Staking Integration**: The contract interacts with an external ERC20 token (`essenceToken`) for staking and rewards. It uses `transferFrom` for users staking and `transfer` for giving rewards and returning staked funds.
3.  **NFT Represents Staked Position**: The ERC721 Shard is not just a collectible; it *is* the user's staked position in the protocol. Holding the NFT means you own the underlying staked Essence and the right to rewards/evolution.
4.  **Accruing Rewards**: Shards passively accrue rewards based on the staked amount and duration since the last claim/stake action, calculated on-demand by `_calculateEssenceReward`.
5.  **User-Triggered Evolution (`triggerShardEvolution`)**: This adds an interactive element. Users can pay a fee to attempt to evolve their Shard's attributes. This is subject to a cooldown to prevent spamming and introduces a cost to influencing the NFT's state.
6.  **Attribute Evolution Logic**: The `_evolveShardAttributes` and `_combineAndEvolveAttributes` functions contain the logic for how attributes change. They use pseudo-randomness derived from various chain and state variables (though for true security/unpredictability in production, a Chainlink VRF or similar would be needed). Attributes also evolve based on factors like stake duration and total protocol stake.
7.  **Shard Merging (`mergeShards`)**: A creative function allowing users to combine two Shards into one new, potentially stronger Shard. This burns the originals, combines the staked amounts, and applies a new evolution/combination logic to the attributes. This adds a strategic decision point for users.
8.  **Partial Unstaking (`removeEssenceFromStake`)**: Allows users to reduce their stake amount without fully unstaking the NFT, offering flexibility. Full unstaking requires burning the Shard.
9.  **Protocol Treasury**: Fees (`mergeFeeEssence`, `evolutionEssenceCost`) are collected in the contract's balance, creating a treasury that the owner can manage (e.g., for protocol development, buybacks, etc.).
10. **Access Control & Pausability**: Standard `Ownable` for administrative functions and `Pausable` to halt critical user interactions in case of issues.
11. **Comprehensive Views**: A large number of view functions provide transparency into the state of individual Shards and the protocol as a whole, crucial for front-end dApp development.
12. **Internal ERC721 Mint/Burn Handling**: The `_beforeTokenTransfer` override is crucial. By default, ERC721 tokens are freely transferable. Here, we *prevent* direct transfers because the NFT represents a staked position that should only be managed through the protocol's `stake`/`unstake`/`merge` functions. The `_burn` calls inside `unstakeEssence` and `mergeShards` are the intended ways to remove Shards.

This contract provides a rich set of interactions around a dynamic NFT concept tied to economic activity (staking) and user-driven evolution. It exceeds the 20-function requirement with a mix of core logic, configuration, views, and inherited functions.