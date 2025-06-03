Okay, let's design a creative, advanced-concept smart contract incorporating several interesting features beyond basic token or NFT functionality.

We'll create an **"EtherealEpochs"** smart contract. This contract will manage dynamic non-fungible tokens (NFTs) called "Epoch Shards". These shards will have properties that can change over time, influenced by a contract-wide "epoch" system. Key features will include:

1.  **Dynamic NFT Properties:** Shard properties like "Tier", "Traits", and "State" (Active/Dormant/Staked) are stored on-chain and can change.
2.  **Epoch System:** A global counter (`currentEpoch`) progresses, triggering potential changes or allowing specific actions.
3.  **Time/Epoch-Based Mechanics:** Some actions (like progressing the epoch, activating shards, claiming rewards) are tied to epochs or block timestamps.
4.  **On-chain Randomness (Pseudo):** Using `block.timestamp` or `block.difficulty` (deprecated in PoS, use `blockhash(block.number - 1)` is better, or Chainlink VRF for true randomness, but we'll use a simple on-chain method for illustration) to introduce variability in trait mutation.
5.  **Combining/Splitting:** Users can combine multiple lower-tier shards to create a higher-tier one or split a higher-tier one into lower tiers.
6.  **Staking:** Shards can be staked to earn benefits tied to the epoch system.
7.  **State-Dependent Actions:** Certain functions are only available if a shard is in a specific state (e.g., active, staked).
8.  **Treasury & Fees:** Actions like minting or activation might require payment, accumulating in the contract's treasury, manageable by the owner.

This design combines elements of dynamic NFTs, gaming mechanics, time-based systems, and staking within a single contract, aiming for uniqueness beyond standard implementations.

---

### Smart Contract: `EtherealEpochs`

**Outline:**

1.  **SPDX-License-Identifier:** MIT
2.  **Pragma:** solidity ^0.8.20
3.  **Imports:** ERC721, Ownable, SafeMath (or similar, but 0.8+ handles overflow mostly).
4.  **Errors:** Custom errors for clarity.
5.  **Events:** To signal state changes.
6.  **Data Structures:**
    *   `ShardState` struct: Defines properties for each NFT (tier, traits, state, timestamps, etc.).
    *   Enums: For shard states (`Dormant`, `Active`, `Staked`).
7.  **State Variables:**
    *   Contract owner, counters, mappings for token state, global epoch info, costs, rates.
8.  **Modifiers:** Custom modifiers for access control or state checks.
9.  **Constructor:** Initializes owner and initial parameters.
10. **ERC721 Implementation:** Standard functions (`balanceOf`, `ownerOf`, `approve`, `transferFrom`, etc.).
11. **Core Shard Management Functions:**
    *   Minting, retrieving state, changing state.
    *   Combining, splitting.
    *   Staking, unstaking.
12. **Epoch System Functions:**
    *   Progressing the epoch.
    *   Calculating rewards based on epoch progression.
13. **Dynamic Property Functions:**
    *   Triggering trait mutation (linked to epoch).
14. **Utility/View Functions:**
    *   Get global epoch, costs, rates, shard counts.
    *   Check conditions (e.g., can progress epoch).
15. **Owner Functions:**
    *   Setting costs, rates, epoch interval.
    *   Withdrawing funds.

**Function Summary:**

*   `constructor()`: Initializes the contract, owner, and base parameters.
*   `balanceOf(address owner)`: (ERC721) Returns the number of tokens owned by an address.
*   `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of a specific token.
*   `approve(address to, uint256 tokenId)`: (ERC721) Grants approval for a single token.
*   `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for a single token.
*   `setApprovalForAll(address operator, bool approved)`: (ERC721) Grants/revokes approval for an operator for all tokens.
*   `isApprovedForAll(address owner, address operator)`: (ERC721) Checks if an operator is approved for all tokens of an owner.
*   `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers token ownership.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers token ownership safely (checks if receiver handles ERC721).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: (ERC721) Transfers token ownership safely with data.
*   `mintShard(address to)`: Mints a new Epoch Shard NFT to an address, initializing its dynamic properties. Requires payment of `mintCost`.
*   `getShardState(uint256 tokenId)`: Reads and returns the dynamic state (tier, traits, active status, staked status, timestamps) of a given shard.
*   `progressEpoch()`: Advances the global `currentEpoch` counter if enough time/blocks have passed since the last progression. May trigger side effects or enable actions. Accessible to anyone (but rate-limited).
*   `canProgressEpoch()`: Checks if the required interval has passed to allow calling `progressEpoch()`.
*   `activateShard(uint256 tokenId)`: Changes a shard's state from `Dormant` to `Active`. Requires ownership, dormant state, and payment of `shardActivationCost`. Updates `lastActivatedEpoch`.
*   `deactivateShard(uint256 tokenId)`: Changes a shard's state from `Active` back to `Dormant`. Requires ownership and active state.
*   `combineShards(uint256[] calldata tokenIds)`: Burns multiple (e.g., 3) lower-tier shards owned by the caller and mints one higher-tier shard. Requires specific conditions on the input shards (tier, ownership, non-staked/non-active).
*   `splitShard(uint256 tokenId)`: Burns a higher-tier shard owned by the caller and mints multiple (e.g., 3) lower-tier shards. Requires specific conditions on the input shard (tier, ownership, non-staked/non-active).
*   `stakeShard(uint256 tokenId)`: Changes a shard's state to `Staked`. Requires ownership and non-staked state. Updates `lastStakedEpoch`.
*   `unstakeShard(uint256 tokenId)`: Changes a shard's state from `Staked` back to `Dormant`. Requires ownership and staked state.
*   `claimEpochReward(uint256[] calldata stakedTokenIds)`: Calculates and transfers rewards (e.g., Ether from treasury) for the specified *staked* shards based on how many epochs they have been staked since the last claim. Requires ownership and staked state for each token. Resets `lastStakedEpoch` for claimed tokens.
*   `randomizeShardTrait(uint256 tokenId, uint256 traitIndex)`: Attempts to change a specific trait of a shard to a new random value. Might be restricted (e.g., only once per epoch, only when active). Uses on-chain pseudo-randomness. Requires ownership.
*   `getCurrentEpoch()`: Returns the current global epoch number.
*   `getEpochProgressionInterval()`: Returns the minimum time/block interval required between epoch progressions.
*   `getMintCost()`: Returns the cost in Wei to mint a shard.
*   `getShardActivationCost()`: Returns the cost in Wei to activate a shard.
*   `getEpochRewardRate()`: Returns the reward rate per staked shard per epoch (in Wei).
*   `getTotalSupply()`: Returns the total number of shards minted.
*   `getTotalStakedCount()`: Returns the total number of shards currently staked across all users.
*   `setEpochProgressionInterval(uint256 interval)`: (Owner) Sets the minimum time/block interval for `progressEpoch`.
*   `setMintCost(uint256 cost)`: (Owner) Sets the cost to mint a shard.
*   `setShardActivationCost(uint256 cost)`: (Owner) Sets the cost to activate a shard.
*   `setEpochRewardRate(uint256 rate)`: (Owner) Sets the reward rate for staked shards.
*   `withdrawFunds()`: (Owner) Withdraws the accumulated Ether from the contract's balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ handles overflow, good practice for clarity

// Outline:
// 1. SPDX-License-Identifier & Pragma
// 2. Imports (ERC721, Ownable, Counters, SafeMath)
// 3. Errors (Custom errors for clarity)
// 4. Events (Signal state changes)
// 5. Data Structures (ShardState struct, Enums)
// 6. State Variables (Owner, Counters, Mappings, Global Epoch, Costs, Rates)
// 7. Modifiers (State checks)
// 8. Constructor (Initialize contract)
// 9. ERC721 Implementation (Standard functions)
// 10. Core Shard Management (Mint, Get State, Activate/Deactivate, Combine/Split, Stake/Unstake)
// 11. Epoch System (Progress Epoch, Claim Rewards)
// 12. Dynamic Property Functions (Randomize Trait)
// 13. Utility/View Functions (Getters for global state/costs/rates, counts, canProgressEpoch)
// 14. Owner Functions (Setters for costs/rates/interval, Withdraw Funds)

// Function Summary:
// - constructor(): Initializes the contract, owner, and base parameters.
// - ERC721 standard functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (2 versions).
// - mintShard(address to): Mints a new Epoch Shard NFT. Requires payment.
// - getShardState(uint256 tokenId): Gets the dynamic state of a shard.
// - progressEpoch(): Advances the global epoch counter based on time interval.
// - canProgressEpoch(): Checks if epoch progression is currently allowed.
// - activateShard(uint256 tokenId): Changes shard state to Active. Requires payment.
// - deactivateShard(uint256 tokenId): Changes shard state to Dormant.
// - combineShards(uint256[] calldata tokenIds): Burns multiple shards to mint a higher tier.
// - splitShard(uint256 tokenId): Burns a higher tier shard to mint multiple lower tiers.
// - stakeShard(uint256 tokenId): Changes shard state to Staked.
// - unstakeShard(uint256 tokenId): Changes shard state from Staked back to Dormant.
// - claimEpochReward(uint256[] calldata stakedTokenIds): Claims rewards for staked shards based on elapsed epochs.
// - randomizeShardTrait(uint256 tokenId, uint256 traitIndex): Attempts to randomize a shard's trait.
// - getCurrentEpoch(): Returns the current global epoch.
// - getEpochProgressionInterval(): Returns the minimum time between epoch progressions.
// - getMintCost(): Returns the cost to mint.
// - getShardActivationCost(): Returns the cost to activate.
// - getEpochRewardRate(): Returns the staking reward rate per epoch.
// - getTotalSupply(): Returns total minted shards.
// - getTotalStakedCount(): Returns total currently staked shards.
// - setEpochProgressionInterval(uint256 interval): (Owner) Sets epoch interval.
// - setMintCost(uint256 cost): (Owner) Sets mint cost.
// - setShardActivationCost(uint256 cost): (Owner) Sets activation cost.
// - setEpochRewardRate(uint256 rate): (Owner) Sets reward rate.
// - withdrawFunds(): (Owner) Withdraws contract balance.

contract EtherealEpochs is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // 3. Errors
    error InvalidTokenId();
    error NotOwnerOf(uint256 tokenId);
    error ShardStateError(string message);
    error InvalidShardTier(string message);
    error InvalidShardCount(uint256 required, uint256 provided);
    error InsufficientPayment();
    error EpochProgressionTooSoon();
    error NoRewardsClaimable();
    error TraitIndexOutOfRange(uint256 traitIndex);

    // 4. Events
    event EpochProgressed(uint256 epoch);
    event ShardMinted(address indexed to, uint256 tokenId, uint256 tier);
    event ShardStateChanged(uint256 indexed tokenId, ShardStateEnum newState);
    event ShardCombined(address indexed owner, uint256[] burnedTokenIds, uint256 newTokenId);
    event ShardSplit(address indexed owner, uint256 burnedTokenId, uint256[] newTokenIds);
    event ShardStaked(uint256 indexed tokenId);
    event ShardUnstaked(uint256 indexed tokenId);
    event EpochRewardClaimed(address indexed owner, uint256[] indexed tokenIds, uint256 amount);
    event ShardTraitRandomized(uint256 indexed tokenId, uint256 indexed traitIndex, uint256 newValue);
    event CostsAndRatesUpdated();

    // 5. Data Structures & Enums
    enum ShardStateEnum { Dormant, Active, Staked }

    struct ShardState {
        uint256 tier;
        uint256[3] traits; // Example: 3 fixed traits
        ShardStateEnum state;
        uint256 lastActivatedEpoch;
        uint256 lastStakedEpoch;
        // Could add lastTraitRandomizedEpoch per trait index
    }

    // 6. State Variables
    mapping(uint256 => ShardState) private _shardStates;
    uint256 public currentEpoch;
    uint256 public epochProgressionInterval = 1 hours; // Time in seconds between epoch progressions
    uint256 private lastEpochProgressionTime;

    uint256 public mintCost = 0.01 ether; // Example cost to mint
    uint256 public shardActivationCost = 0.005 ether; // Example cost to activate
    uint256 public epochRewardRate = 0.0001 ether; // Example reward per staked shard per epoch

    uint256 private _totalStakedCount;

    // Configuration for combine/split - Example: 3 tier 1 -> 1 tier 2, 1 tier 2 -> 3 tier 1
    uint256 private constant COMBINE_INPUT_COUNT = 3;
    uint256 private constant SPLIT_OUTPUT_COUNT = 3;
    uint256 private constant BASE_TIER = 1;

    // --- Modifier for Shard State Checks ---
    modifier whenShardStateIs(uint256 tokenId, ShardStateEnum requiredState) {
        if (_shardStates[tokenId].state != requiredState) {
             // More specific error could indicate current state
            revert ShardStateError("Shard is not in the required state");
        }
        _;
    }

    modifier whenShardStateIsNot(uint256 tokenId, ShardStateEnum prohibitedState) {
         if (_shardStates[tokenId].state == prohibitedState) {
            revert ShardStateError("Shard is in a prohibited state");
        }
        _;
    }

    // 8. Constructor
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        lastEpochProgressionTime = block.timestamp; // Initialize epoch timer
        currentEpoch = 1; // Start at epoch 1
    }

    // 9. ERC721 Implementation - Standard functions inherited and used

    // 10. Core Shard Management Functions

    /// @notice Mints a new Epoch Shard NFT to the specified address.
    /// @param to The address to mint the shard to.
    function mintShard(address to) public payable {
        if (msg.value < mintCost) {
            revert InsufficientPayment();
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        // Initialize Shard State - Base tier, random initial traits, Dormant
        _shardStates[newItemId] = ShardState({
            tier: BASE_TIER,
            traits: [_generateRandomTrait(), _generateRandomTrait(), _generateRandomTrait()],
            state: ShardStateEnum.Dormant,
            lastActivatedEpoch: 0, // Not activated yet
            lastStakedEpoch: 0 // Not staked yet
        });

        emit ShardMinted(to, newItemId, BASE_TIER);
    }

    /// @notice Retrieves the dynamic state of a shard.
    /// @param tokenId The ID of the shard.
    /// @return ShardState The dynamic state data of the shard.
    function getShardState(uint256 tokenId) public view returns (ShardState memory) {
         // While ERC721 allows querying owner of non-existent tokens,
         // our custom state only exists for minted tokens.
         // Check if token ID exists (simple check - relies on _tokenIds counter logic)
        if (tokenId == 0 || tokenId > _tokenIdCounter.current()) {
             revert InvalidTokenId();
         }
        return _shardStates[tokenId];
    }

    /// @notice Changes a shard's state from Dormant to Active.
    /// @param tokenId The ID of the shard to activate.
    function activateShard(uint256 tokenId)
        public payable
        whenShardStateIs(tokenId, ShardStateEnum.Dormant)
    {
        if (ownerOf(tokenId) != msg.sender) {
             revert NotOwnerOf(tokenId);
         }
        if (msg.value < shardActivationCost) {
            revert InsufficientPayment();
        }

        _shardStates[tokenId].state = ShardStateEnum.Active;
        _shardStates[tokenId].lastActivatedEpoch = currentEpoch; // Record epoch of activation
        emit ShardStateChanged(tokenId, ShardStateEnum.Active);
    }

     /// @notice Changes a shard's state from Active back to Dormant.
    /// @param tokenId The ID of the shard to deactivate.
    function deactivateShard(uint256 tokenId)
        public
        whenShardStateIs(tokenId, ShardStateEnum.Active)
    {
        if (ownerOf(tokenId) != msg.sender) {
             revert NotOwnerOf(tokenId);
         }
        _shardStates[tokenId].state = ShardStateEnum.Dormant;
        emit ShardStateChanged(tokenId, ShardStateEnum.Dormant);
    }

    /// @notice Combines multiple lower-tier shards into a single higher-tier shard.
    /// @param tokenIds An array of token IDs to burn. Must be owned by the caller.
    /// @dev Requires COMBINE_INPUT_COUNT shards of BASE_TIER to combine into 1 shard of BASE_TIER + 1.
    function combineShards(uint256[] calldata tokenIds) public {
        if (tokenIds.length != COMBINE_INPUT_COUNT) {
            revert InvalidShardCount(COMBINE_INPUT_COUNT, tokenIds.length);
        }

        address caller = msg.sender;
        uint256 expectedTier = BASE_TIER;
        uint256 newTier = BASE_TIER + 1; // Example: Tier 1 -> Tier 2

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != caller) {
                revert NotOwnerOf(tokenId);
            }
             ShardState memory state = _shardStates[tokenId];
            if (state.tier != expectedTier) {
                revert InvalidShardTier("Input shard is not of the required tier for combining");
            }
            if (state.state != ShardStateEnum.Dormant) {
                revert ShardStateError("Input shards must be Dormant to be combined");
            }
            // Avoid duplicate tokenIds in input array (basic check)
            for(uint j = i + 1; j < tokenIds.length; j++) {
                if (tokenIds[i] == tokenIds[j]) {
                     revert InvalidTokenId(); // Duplicate token ID in input
                }
            }
        }

        // Burn the input shards
        for (uint i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
            delete _shardStates[tokenIds[i]]; // Clean up state mapping
        }

        // Mint the new higher-tier shard
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(caller, newItemId);

        // Initialize state for the new shard - New tier, new random traits, Dormant
        _shardStates[newItemId] = ShardState({
            tier: newTier,
            traits: [_generateRandomTrait(), _generateRandomTrait(), _generateRandomTrait()],
            state: ShardStateEnum.Dormant,
            lastActivatedEpoch: 0,
            lastStakedEpoch: 0
        });

        emit ShardCombined(caller, tokenIds, newItemId);
    }

    /// @notice Splits a higher-tier shard into multiple lower-tier shards.
    /// @param tokenId The ID of the shard to burn. Must be owned by the caller.
    /// @dev Requires 1 shard of BASE_TIER + 1 to split into SPLIT_OUTPUT_COUNT shards of BASE_TIER.
    function splitShard(uint256 tokenId) public {
        address caller = msg.sender;
         if (ownerOf(tokenId) != caller) {
             revert NotOwnerOf(tokenId);
         }

        ShardState memory state = _shardStates[tokenId];
        if (state.tier != BASE_TIER + 1) { // Example: Only Tier 2 can be split
             revert InvalidShardTier("Shard is not of the required tier for splitting");
         }
         if (state.state != ShardStateEnum.Dormant) {
             revert ShardStateError("Shard must be Dormant to be split");
         }

        // Burn the input shard
        _burn(tokenId);
        delete _shardStates[tokenId]; // Clean up state mapping

        uint256[] memory newTokens = new uint256[](SPLIT_OUTPUT_COUNT);

        // Mint the new lower-tier shards
        for (uint i = 0; i < SPLIT_OUTPUT_COUNT; i++) {
            _tokenIdCounter.increment();
            uint256 newItemId = _tokenIdCounter.current();
            _safeMint(caller, newItemId);

             // Initialize state for the new shards - Base tier, new random traits, Dormant
            _shardStates[newItemId] = ShardState({
                tier: BASE_TIER,
                traits: [_generateRandomTrait(), _generateRandomTrait(), _generateRandomTrait()],
                state: ShardStateEnum.Dormant,
                lastActivatedEpoch: 0,
                lastStakedEpoch: 0
            });
            newTokens[i] = newItemId;
        }

        emit ShardSplit(caller, tokenId, newTokens);
    }

    /// @notice Changes a shard's state to Staked.
    /// @param tokenId The ID of the shard to stake.
    function stakeShard(uint256 tokenId)
        public
        whenShardStateIsNot(tokenId, ShardStateEnum.Staked) // Must not already be staked
    {
         if (ownerOf(tokenId) != msg.sender) {
             revert NotOwnerOf(tokenId);
         }
         // Can stake from Dormant or Active states
        _shardStates[tokenId].state = ShardStateEnum.Staked;
        _shardStates[tokenId].lastStakedEpoch = currentEpoch; // Record epoch of staking
        _totalStakedCount++;
        emit ShardStateChanged(tokenId, ShardStateEnum.Staked);
        emit ShardStaked(tokenId);
    }

    /// @notice Changes a shard's state from Staked back to Dormant.
    /// @param tokenId The ID of the shard to unstake.
    function unstakeShard(uint256 tokenId)
        public
        whenShardStateIs(tokenId, ShardStateEnum.Staked)
    {
         if (ownerOf(tokenId) != msg.sender) {
             revert NotOwnerOf(tokenId);
         }
        _shardStates[tokenId].state = ShardStateEnum.Dormant; // Unstaking returns to Dormant
        // lastStakedEpoch is kept for potential reward calculation on unstake or next claim
        _totalStakedCount--;
        emit ShardStateChanged(tokenId, ShardStateEnum.Dormant);
        emit ShardUnstaked(tokenId);
    }

    // 11. Epoch System Functions

    /// @notice Advances the global epoch counter if the required interval has passed.
    /// Anyone can call this function, but it's rate-limited.
    function progressEpoch() public {
        if (!canProgressEpoch()) {
            revert EpochProgressionTooSoon();
        }

        lastEpochProgressionTime = block.timestamp;
        currentEpoch++;

        // --- Potential side effects triggered by epoch progression ---
        // Example: Randomize traits for *active* shards with a certain probability
        // Or trigger delayed effects based on lastActivatedEpoch etc.
        // (Implementation of specific side effects omitted for brevity but shown below in randomize function)
        // --- End side effects ---

        emit EpochProgressed(currentEpoch);
    }

    /// @notice Calculates and transfers rewards for specified staked shards.
    /// @param stakedTokenIds An array of token IDs owned by the caller that are currently staked.
    /// @dev Rewards are based on the number of epochs staked since the last claim for each shard.
    function claimEpochReward(uint256[] calldata stakedTokenIds) public {
        address caller = msg.sender;
        uint256 totalReward = 0;
        uint256 claimedCount = 0;

        for (uint i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];
            if (ownerOf(tokenId) != caller) {
                // Skip tokens not owned by caller, or revert? Revert is safer.
                revert NotOwnerOf(tokenId);
            }
            ShardState storage shard = _shardStates[tokenId];
            if (shard.state != ShardStateEnum.Staked) {
                 // Skip non-staked tokens in the input array, or revert? Revert is safer.
                 revert ShardStateError("Token is not staked");
            }

            // Calculate epochs staked since last claim
            uint256 epochsStaked = currentEpoch - shard.lastStakedEpoch;

            if (epochsStaked > 0) {
                totalReward += epochsStaked * epochRewardRate;
                shard.lastStakedEpoch = currentEpoch; // Reset epoch counter for this shard
                claimedCount++;
            }
        }

        if (totalReward == 0) {
            revert NoRewardsClaimable();
        }

        // Transfer accumulated rewards from contract balance
        (bool success,) = payable(caller).call{value: totalReward}("");
        require(success, "Reward transfer failed");

        emit EpochRewardClaimed(caller, stakedTokenIds, totalReward);
    }

    // 12. Dynamic Property Functions

    /// @notice Attempts to randomize a specific trait of a shard.
    /// @param tokenId The ID of the shard.
    /// @param traitIndex The index of the trait to randomize (0, 1, or 2).
    /// @dev Uses on-chain pseudo-randomness (`blockhash(block.number - 1)`). This is NOT cryptographically secure.
    /// @dev Might have conditions, e.g., can only be done once per shard per epoch, or only when Active.
    function randomizeShardTrait(uint256 tokenId, uint256 traitIndex) public {
        if (ownerOf(tokenId) != msg.sender) {
             revert NotOwnerOf(tokenId);
         }
        if (traitIndex >= _shardStates[tokenId].traits.length) {
            revert TraitIndexOutOfRange(traitIndex);
        }

        // Example Condition: Can only randomize if shard is Active
        if (_shardStates[tokenId].state != ShardStateEnum.Active) {
             revert ShardStateError("Shard must be Active to randomize traits");
         }

        // Simple Pseudo-randomness (Vulnerable, use Chainlink VRF for production)
        // Use blockhash of a recent block. Requires a non-zero block number.
        // This value is predictable by miners/validators.
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            blockhash(block.number > 0 ? block.number - 1 : 0),
            msg.sender, // Include sender to make it harder for one user to manipulate
            tokenId,
            traitIndex,
            block.timestamp
        )));

        uint256 newTraitValue = randomness % 100; // Example: trait value between 0-99

        _shardStates[tokenId].traits[traitIndex] = newTraitValue;

        // Optional: Add a cooldown mechanism, e.g., lastTraitRandomizedEpoch per trait index
        // if (_shardStates[tokenId].lastTraitRandomizedEpoch[traitIndex] >= currentEpoch) { ... too soon ... }
        // _shardStates[tokenId].lastTraitRandomizedEpoch[traitIndex] = currentEpoch;

        emit ShardTraitRandomized(tokenId, traitIndex, newTraitValue);
    }

     // Internal helper for trait generation
    function _generateRandomTrait() internal view returns (uint256) {
        // Basic pseudo-randomness for initial minting traits
        // Less critical than the user-callable randomize function, but still not secure
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tx.origin, block.number))) % 100;
    }


    // 13. Utility/View Functions

    /// @notice Returns the current global epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the minimum time interval required between epoch progressions.
    function getEpochProgressionInterval() public view returns (uint256) {
        return epochProgressionInterval;
    }

     /// @notice Checks if the required interval has passed to allow calling `progressEpoch()`.
    function canProgressEpoch() public view returns (bool) {
        return block.timestamp >= lastEpochProgressionTime + epochProgressionInterval;
    }

    /// @notice Returns the cost in Wei to mint a shard.
    function getMintCost() public view returns (uint256) {
        return mintCost;
    }

    /// @notice Returns the cost in Wei to activate a shard.
    function getShardActivationCost() public view returns (uint256) {
        return shardActivationCost;
    }

     /// @notice Returns the reward rate per staked shard per epoch (in Wei).
    function getEpochRewardRate() public view returns (uint256) {
        return epochRewardRate;
    }

    /// @notice Returns the total number of shards minted.
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Returns the total number of shards currently staked across all users.
    function getTotalStakedCount() public view returns (uint256) {
        return _totalStakedCount;
    }

    // 14. Owner Functions

    /// @notice (Owner) Sets the minimum time interval for `progressEpoch`.
    /// @param interval The new interval in seconds.
    function setEpochProgressionInterval(uint256 interval) public onlyOwner {
        epochProgressionInterval = interval;
        emit CostsAndRatesUpdated(); // Generic event for owner config changes
    }

    /// @notice (Owner) Sets the cost to mint a shard.
    /// @param cost The new mint cost in Wei.
    function setMintCost(uint256 cost) public onlyOwner {
        mintCost = cost;
        emit CostsAndRatesUpdated();
    }

    /// @notice (Owner) Sets the cost to activate a shard.
    /// @param cost The new activation cost in Wei.
    function setShardActivationCost(uint256 cost) public onlyOwner {
        shardActivationCost = cost;
        emit CostsAndRatesUpdated();
    }

    /// @notice (Owner) Sets the reward rate for staked shards per epoch.
    /// @param rate The new reward rate in Wei.
    function setEpochRewardRate(uint256 rate) public onlyOwner {
        epochRewardRate = rate;
        emit CostsAndRatesUpdated();
    }

    /// @notice (Owner) Withdraws the accumulated Ether balance from the contract.
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- ERC721 Overrides ---
    // These are required by the ERC721 standard to integrate with the token supply counter.
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
        // Note: State mapping is deleted in combine/split functions where burn is called.
        // If burning is possible through other means (e.g., transfer to zero address),
        // ensure state cleanup happens or add a hook here.
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Receive and fallback functions to accept Ether
    receive() external payable {}
    fallback() external payable {}
}
```