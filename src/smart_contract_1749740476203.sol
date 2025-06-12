Okay, here is a Solidity smart contract implementing a system around "Chrono-Shards" - dynamic NFTs whose attributes evolve over time or based on interactions, combined with NFT staking for yield and attribute-based challenges.

This contract attempts to incorporate advanced concepts like:

1.  **Dynamic NFTs:** Attributes are not static metadata but change based on time/block height.
2.  **On-chain State Evolution:** Attributes are calculated based on contract state (`lastSyncBlock`) and external factors (block data, seed).
3.  **Time-Based Mechanics:** Attribute decay/evolution, staking duration, freeze periods.
4.  **NFT Staking:** Users stake NFTs to earn a utility token.
5.  **Attribute-Based Challenges:** Gamified interactions requiring specific NFT attributes.
6.  **Simple Internal Tokenomics:** A simulated utility token (`TIME`) managed internally for rewards and fees (avoids duplicating ERC20 fully).
7.  **Partial ERC721 Implementation:** Implements necessary ERC721-like functions internally without inheriting a full standard library (to avoid duplicating common open source).

**Disclaimer:** This is a complex conceptual contract for demonstration. It's not gas-optimized, has potential security considerations (e.g., simple randomness, reentrancy risks in complex interactions), and a real-world implementation would require extensive testing, auditing, and likely use of standard libraries (like OpenZeppelin) for robust implementations of ERC721, ERC20, and Ownable.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoShards
 * @author Your Name/Alias
 * @dev A contract managing dynamic NFTs (Chrono-Shards) with evolving attributes,
 *      NFT staking for yield, and attribute-based challenges.
 *      This contract is a conceptual demonstration and implements core logic
 *      internally rather than inheriting standard libraries directly to meet
 *      the "don't duplicate open source" constraint for the core logic.
 *      It simulates a utility token ($TIME) for internal use.
 */

/*
 * OUTLINE:
 *
 * I. State Variables:
 *    - Ownership (Owner)
 *    - NFT Core Data (tokenId counter, ownership mappings, approvals)
 *    - Shard Attribute Data (struct, mapping)
 *    - Staking Data (mappings for staked shards, staking info)
 *    - Challenge Data (structs, mappings for configs, progress, attempts)
 *    - Simulated Token Data (balance mapping, total supply)
 *    - Parameters (staking reward rate, challenge fee, time parameters)
 *
 * II. Events:
 *    - Core NFT Events (Transfer, Approval, ApprovalForAll)
 *    - Attribute Events (AttributeSynced, AttributeFrozen, AttributeUnfrozen, SeedMutated)
 *    - Staking Events (ShardStaked, ShardUnstaked, StakingRewardsClaimed)
 *    - Challenge Events (ChallengeCreated, ChallengeParticipated, ChallengeCompleted, ChallengeRewardClaimed)
 *    - Simulated Token Events (TokenMinted, TokenBurned, TokenTransfer)
 *
 * III. Modifiers:
 *    - onlyOwner: Restricts access to the contract owner.
 *    - isShardOwner: Checks if the caller is the owner of a shard.
 *    - isShardStakedByCaller: Checks if the caller has staked a shard.
 *
 * IV. Core NFT Functions (Partial ERC721-like):
 *    - constructor: Sets the initial owner.
 *    - mintShard: Creates a new dynamic NFT.
 *    - transferFrom: Transfers ownership of a shard.
 *    - approve: Approves an address to transfer a specific shard.
 *    - setApprovalForAll: Approves an operator for all caller's shards.
 *    - ownerOf: Gets the owner of a shard.
 *    - balanceOf: Gets the number of shards owned by an address.
 *    - getApproved: Gets the approved address for a shard.
 *    - isApprovedForAll: Checks operator approval status.
 *
 * V. Dynamic Attribute Functions:
 *    - getShardAttributes: Gets the current calculated attributes (may sync implicitly).
 *    - syncShardAttributes: Explicitly updates and recalculates dynamic attributes.
 *    - freezeShardAttributes: Prevents attribute changes for a duration (burns $TIME).
 *    - unfreezeShardAttributes: Ends attribute freeze early (optional penalty).
 *    - mutateShardSeed: Changes the seed influencing attribute generation (burns $TIME).
 *    - _calculateDynamicAttributes: Internal helper for attribute logic.
 *
 * VI. Staking Functions (Temporal Anchoring):
 *    - stakeShard: Stakes a shard, locking it to earn $TIME rewards.
 *    - unstakeShard: Unstakes a shard, returning ownership and allowing reward claims.
 *    - claimStakingRewards: Claims accumulated $TIME rewards from all staked/unstaked shards.
 *    - getStakedShards: Lists shards currently staked by an address.
 *    - getPendingStakingRewards: Calculates potential rewards for a staker.
 *    - _calculateStakingRewards: Internal helper for reward calculation per shard.
 *
 * VII. Challenge Functions (Chronosync Challenges):
 *    - createChallenge: Owner creates a new attribute-based challenge.
 *    - participateInChallenge: Attempts a challenge with a specific shard (burns $TIME).
 *    - claimChallengeReward: Claims $TIME reward after successful challenge completion.
 *    - getChallengeConfig: Views details of a challenge.
 *    - getChallengeProgress: Views a user's progress/status on a challenge.
 *    - _checkChallengeCompletion: Internal helper to verify challenge conditions.
 *
 * VIII. Simulated Token Functions ($TIME):
 *    - getTokenBalance: Gets the $TIME balance of an address.
 *    - ownerMintToken: Owner can mint $TIME for initial distribution or rewards pool.
 *    - _mintToken: Internal function to mint $TIME.
 *    - _burnToken: Internal function to burn $TIME.
 *    - _transferToken: Internal function to transfer $TIME.
 *
 * IX. Utility/View Functions:
 *    - getTotalShards: Total number of shards minted.
 *    - getShardStakingInfo: Gets staking details for a specific shard.
 *    - getCurrentBlockNumber: Helper to get current block number.
 *
 * Total Functions: 32 (Exceeds minimum 20)
 */


// --- State Variables ---

address private _owner;

// NFT Core Data (Partial ERC721)
uint256 private _nextTokenId;
mapping(uint256 => address) private _owners; // tokenId => owner
mapping(address => uint256) private _balances; // owner => count
mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

// Shard Attribute Data
struct ShardAttributes {
    uint256 seed; // Initial seed influencing attribute generation
    uint256 generationBlock; // Block when shard was minted
    uint256 lastSyncBlock; // Block when attributes were last synced/frozen
    uint256 dynamicAttr1; // Example dynamic attribute 1 (e.g., "Energy")
    uint256 dynamicAttr2; // Example dynamic attribute 2 (e.g., "Form")
    bool isFrozen; // Are attributes currently frozen?
    uint256 frozenUntilBlock; // Block number until which attributes are frozen
}
mapping(uint256 => ShardAttributes) private _shardAttributes;

// Staking Data (Temporal Anchoring)
struct ShardStakingInfo {
    address staker; // Original staker address
    uint256 stakeTime; // Timestamp when staked
    uint256 rewardClaimedTime; // Timestamp of last reward claim for this stake
    bool isStaked; // Is the shard currently staked? (Owner is address(this))
}
mapping(uint256 => ShardStakingInfo) private _shardStakingInfo;
mapping(address => uint256[] ) private _stakedShardsByStaker; // staker => list of tokenIds

// Challenge Data (Chronosync Challenges)
struct ChallengeConfig {
    uint256 challengeType; // 1: Attr1 > value, 2: Attr2 < value, etc.
    uint256 requiredAttributeValue; // The target value for the required attribute
    uint256 rewardAmount; // $TIME reward for completion
    uint256 requiredAttempts; // Number of successful attempts needed
    uint256 attemptFee; // $TIME fee per attempt
    bool isActive; // Is the challenge currently active?
}
mapping(uint256 => ChallengeConfig) private _challengeConfigs;
uint256 private _nextChallengeId;

struct ChallengeProgress {
    uint256 successfulAttempts; // How many times the user successfully passed the check
    bool completed; // Has the user completed the challenge requirements?
    bool rewardClaimed; // Has the user claimed the reward?
}
mapping(address => mapping(uint256 => ChallengeProgress)) private _challengeProgress; // user => challengeId => progress

// Simulated Token Data ($TIME)
string public constant TIME_TOKEN_SYMBOL = "TIME";
uint256 private _timeTotalSupply;
mapping(address => uint256) private _timeBalances; // address => balance

// Parameters
uint256 public stakingRewardRatePerSecond = 1e16; // 0.01 TIME per second per shard (example)
uint256 public attributeDecayRate = 1; // Amount attributes might decay per block (example)
uint256 public attributeEvolutionRate = 1; // Amount attributes might evolve per block (example)
uint256 public constant ATTRIBUTE_MAX_VALUE = 1000; // Max value for dynamic attributes

// --- Events ---

// Core NFT Events
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

// Attribute Events
event AttributeSynced(uint256 indexed tokenId, uint256 indexed syncBlock, uint256 attr1, uint256 attr2);
event AttributeFrozen(uint256 indexed tokenId, uint256 indexed frozenUntilBlock);
event AttributeUnfrozen(uint256 indexed tokenId);
event SeedMutated(uint256 indexed tokenId, uint256 indexed newSeed);

// Staking Events
event ShardStaked(address indexed staker, uint256 indexed tokenId, uint256 stakeTime);
event ShardUnstaked(address indexed staker, uint256 indexed tokenId, uint256 unstakeTime);
event StakingRewardsClaimed(address indexed staker, uint256 amount);

// Challenge Events
event ChallengeCreated(uint256 indexed challengeId, uint256 challengeType, uint256 rewardAmount);
event ChallengeParticipated(address indexed user, uint256 indexed challengeId, uint256 indexed tokenId, bool passedCheck);
event ChallengeCompleted(address indexed user, uint256 indexed challengeId);
event ChallengeRewardClaimed(address indexed user, uint256 indexed challengeId, uint256 amount);

// Simulated Token Events
event TokenMinted(address indexed recipient, uint256 amount);
event TokenBurned(address indexed burner, uint256 amount);
event TokenTransfer(address indexed from, address indexed to, uint256 amount);

// --- Modifiers ---

modifier onlyOwner() {
    require(_owner == msg.sender, "Only owner can call this function");
    _;
}

modifier isShardOwner(uint256 tokenId) {
    require(_owners[tokenId] == msg.sender, "Not shard owner");
    _;
}

modifier isShardStakedByCaller(uint256 tokenId) {
    require(_shardStakingInfo[tokenId].isStaked && _shardStakingInfo[tokenId].staker == msg.sender, "Shard not staked by caller");
    _;
}

// --- Constructor ---

constructor() {
    _owner = msg.sender;
    _nextTokenId = 0;
    _nextChallengeId = 0;
}

// --- Core NFT Functions (Partial ERC721-like) ---

/**
 * @dev Mints a new Chrono-Shard NFT and assigns it to a recipient.
 * @param recipient The address that will receive the new shard.
 * @param seed A value influencing the initial and dynamic attributes.
 */
function mintShard(address recipient, uint256 seed) external onlyOwner {
    require(recipient != address(0), "Mint to non-zero address");

    uint256 newTokenId = _nextTokenId++;
    _owners[newTokenId] = recipient;
    _balances[recipient]++;

    // Initialize attributes
    ShardAttributes memory newAttributes;
    newAttributes.seed = seed;
    newAttributes.generationBlock = block.number;
    newAttributes.lastSyncBlock = block.number;
    newAttributes.isFrozen = false;
    newAttributes.frozenUntilBlock = 0;

    // Calculate initial dynamic attributes
    (newAttributes.dynamicAttr1, newAttributes.dynamicAttr2) = _calculateDynamicAttributes(
        seed,
        block.number,
        block.number, // Initial sync block is generation block
        block.number // Calculate based on current block for initial value
    );

    _shardAttributes[newTokenId] = newAttributes;

    emit Transfer(address(0), recipient, newTokenId);
}

/**
 * @dev Transfers ownership of a shard from one address to another.
 *      Handles internal state updates for ownership and staking status.
 *      Cannot transfer if staked.
 * @param from The current owner of the shard.
 * @param to The address to transfer the shard to.
 * @param tokenId The ID of the shard to transfer.
 */
function transferFrom(address from, address to, uint256 tokenId) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
    require(_owners[tokenId] == from, "Transfer from incorrect owner");
    require(to != address(0), "Transfer to non-zero address");
    require(!_shardStakingInfo[tokenId].isStaked, "Cannot transfer staked shard"); // Prevent transferring staked shard

    _transfer(from, to, tokenId);
}

/**
 * @dev Approves another address to transfer a specific shard.
 * @param to The address to approve.
 * @param tokenId The ID of the shard.
 */
function approve(address to, uint256 tokenId) public {
    address owner = _owners[tokenId];
    require(owner != address(0), "Shard does not exist");
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not owner or operator");

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
}

/**
 * @dev Approves or disapproves an operator for all of the caller's shards.
 * @param operator The address to approve as operator.
 * @param approved Whether to approve or disapprove.
 */
function setApprovalForAll(address operator, bool approved) public {
    require(operator != msg.sender, "Cannot approve self as operator");
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
}

/**
 * @dev Gets the owner of a specific shard.
 * @param tokenId The ID of the shard.
 * @return The owner's address. Returns address(0) if shard does not exist.
 */
function ownerOf(uint256 tokenId) public view returns (address) {
    return _owners[tokenId];
}

/**
 * @dev Gets the number of shards owned by an address.
 * @param owner The address to check.
 * @return The number of shards owned.
 */
function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "Balance query for non-zero address");
    return _balances[owner];
}

/**
 * @dev Gets the address approved for a specific shard.
 * @param tokenId The ID of the shard.
 * @return The approved address, or address(0) if none.
 */
function getApproved(uint256 tokenId) public view returns (address) {
    require(_owners[tokenId] != address(0), "Shard does not exist");
    return _tokenApprovals[tokenId];
}

/**
 * @dev Checks if an address is an approved operator for another address.
 * @param owner The address owning the shards.
 * @param operator The potential operator address.
 * @return True if approved, false otherwise.
 */
function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
}

/**
 * @dev Internal transfer function, handles ownership and balance updates.
 * @param from The current owner.
 * @param to The recipient.
 * @param tokenId The shard ID.
 */
function _transfer(address from, address to, uint256 tokenId) internal {
    require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner");

    // Clear approvals
    _tokenApprovals[tokenId] = address(0);

    _balances[from]--;
    _balances[to]++;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
}

/**
 * @dev Internal helper to check if an address is approved or the owner of a shard.
 * @param spender The address attempting the action.
 * @param tokenId The shard ID.
 * @return True if approved or owner, false otherwise.
 */
function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address owner = _owners[tokenId];
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
}

// --- Dynamic Attribute Functions ---

/**
 * @dev Gets the current attributes of a shard.
 *      May implicitly sync attributes if they are not frozen and need updating.
 * @param tokenId The ID of the shard.
 * @return The current ShardAttributes struct.
 */
function getShardAttributes(uint256 tokenId) public returns (ShardAttributes memory) {
    require(_owners[tokenId] != address(0), "Shard does not exist");

    ShardAttributes storage attributes = _shardAttributes[tokenId];

    // If not frozen and past sync block, update attributes implicitly
    if (!attributes.isFrozen && attributes.lastSyncBlock < block.number) {
         (attributes.dynamicAttr1, attributes.dynamicAttr2) = _calculateDynamicAttributes(
            attributes.seed,
            attributes.generationBlock,
            attributes.lastSyncBlock,
            block.number // Calculate based on current block
        );
        attributes.lastSyncBlock = block.number;
        emit AttributeSynced(tokenId, block.number, attributes.dynamicAttr1, attributes.dynamicAttr2);
    }

    return attributes;
}


/**
 * @dev Explicitly syncs and updates the dynamic attributes of a shard.
 *      Requires ownership. Does nothing if attributes are frozen.
 * @param tokenId The ID of the shard.
 */
function syncShardAttributes(uint256 tokenId) external isShardOwner(tokenId) {
    ShardAttributes storage attributes = _shardAttributes[tokenId];
    require(!attributes.isFrozen, "Attributes are frozen");
    require(attributes.lastSyncBlock < block.number, "Attributes already synced to current block");

     (attributes.dynamicAttr1, attributes.dynamicAttr2) = _calculateDynamicAttributes(
        attributes.seed,
        attributes.generationBlock,
        attributes.lastSyncBlock,
        block.number // Calculate based on current block
    );
    attributes.lastSyncBlock = block.number;

    emit AttributeSynced(tokenId, block.number, attributes.dynamicAttr1, attributes.dynamicAttr2);
}

/**
 * @dev Freezes the dynamic attributes of a shard for a specified duration.
 *      Requires ownership and burns $TIME tokens as a cost.
 * @param tokenId The ID of the shard.
 * @param durationBlocks The number of blocks the attributes will be frozen.
 */
function freezeShardAttributes(uint256 tokenId, uint256 durationBlocks) external isShardOwner(tokenId) {
    require(durationBlocks > 0, "Freeze duration must be positive");
    ShardAttributes storage attributes = _shardAttributes[tokenId];
    require(!attributes.isFrozen, "Attributes are already frozen");

    // --- Simulate token burn cost ---
    uint256 freezeCost = durationBlocks * 100; // Example cost: 100 $TIME per block duration
    _burnToken(msg.sender, freezeCost);
    // --- End simulate token burn cost ---

    // Sync attributes before freezing
     (attributes.dynamicAttr1, attributes.dynamicAttr2) = _calculateDynamicAttributes(
        attributes.seed,
        attributes.generationBlock,
        attributes.lastSyncBlock,
        block.number
    );
    attributes.lastSyncBlock = block.number; // Freeze captures current state

    attributes.isFrozen = true;
    attributes.frozenUntilBlock = block.number + durationBlocks;

    emit AttributeFrozen(tokenId, attributes.frozenUntilBlock);
}

/**
 * @dev Unfreezes the attributes of a shard before the frozenUntilBlock is reached.
 *      Requires ownership.
 * @param tokenId The ID of the shard.
 */
function unfreezeShardAttributes(uint256 tokenId) external isShardOwner(tokenId) {
     ShardAttributes storage attributes = _shardAttributes[tokenId];
     require(attributes.isFrozen, "Attributes are not frozen");
     require(block.number < attributes.frozenUntilBlock, "Freeze period is already over");

     attributes.isFrozen = false;
     attributes.frozenUntilBlock = 0;
     // Attributes will now become dynamic again and sync on next check

     emit AttributeUnfrozen(tokenId);
}

/**
 * @dev Allows the owner to mutate the seed of a shard, influencing future attribute evolution.
 *      Requires ownership and burns $TIME tokens as a cost.
 * @param tokenId The ID of the shard.
 * @param newSeed The new seed value.
 */
function mutateShardSeed(uint256 tokenId, uint256 newSeed) external isShardOwner(tokenId) {
    ShardAttributes storage attributes = _shardAttributes[tokenId];
    require(newSeed != attributes.seed, "New seed must be different");

    // --- Simulate token burn cost ---
    uint256 mutateCost = 5000; // Example cost: 5000 $TIME
    _burnToken(msg.sender, mutateCost);
    // --- End simulate token burn cost ---

    attributes.seed = newSeed;
    // Sync attributes immediately after mutation based on the new seed
     (attributes.dynamicAttr1, attributes.dynamicAttr2) = _calculateDynamicAttributes(
        newSeed, // Use the new seed
        attributes.generationBlock,
        block.number, // Sync from current block
        block.number // Calculate based on current block
    );
    attributes.lastSyncBlock = block.number;


    emit SeedMutated(tokenId, newSeed);
    emit AttributeSynced(tokenId, block.number, attributes.dynamicAttr1, attributes.dynamicAttr2);
}


/**
 * @dev Internal helper to calculate dynamic attributes based on seed, time, and blocks.
 *      This is a simplified example logic. Real implementations could use complex algorithms,
 *      on-chain data (e.g., contract state), or external oracles (less decentralized).
 *      Attributes tend to drift from initial value based on blocks passed since last sync.
 * @param seed The shard's seed.
 * @param generationBlock Block when shard was created.
 * @param lastSyncBlock Block when attributes were last updated/frozen.
 * @param currentBlock The current block number for calculation.
 * @return The calculated values for dynamicAttr1 and dynamicAttr2.
 */
function _calculateDynamicAttributes(
    uint256 seed,
    uint256 generationBlock,
    uint256 lastSyncBlock,
    uint256 currentBlock
) internal view returns (uint256 attr1, uint256 attr2) {
    uint256 blocksPassed = currentBlock - lastSyncBlock;

    // Simple pseudo-randomness based on block data and seed
    uint256 entropy = uint256(keccak256(abi.encodePacked(blockhash(currentBlock - 1), block.timestamp, seed, generationBlock, lastSyncBlock)));

    // Example attribute logic: drift based on blocksPassed and entropy
    // Attr1 increases/decreases, Attr2 changes character based on entropy/seed
    // Ensure values stay within a range [0, ATTRIBUTE_MAX_VALUE]

    uint256 drift = (blocksPassed * (entropy % 10)) / 100; // Example simple drift logic

    // Initialize based on seed and generation block (simplified)
    uint256 baseAttr1 = (uint256(keccak256(abi.encodePacked(seed, generationBlock))) % ATTRIBUTE_MAX_VALUE);
    uint256 baseAttr2 = (uint256(keccak256(abi.encodePacked(generationBlock, seed))) % ATTRIBUTE_MAX_VALUE);


    // Apply drift/evolution based on time passed since last sync
    uint256 calculatedAttr1 = baseAttr1;
    uint256 calculatedAttr2 = baseAttr2;

    // Example: Attr1 evolves (increases) slightly over time, bounded by max value
    calculatedAttr1 = (baseAttr1 + (blocksPassed * attributeEvolutionRate)) % (ATTRIBUTE_MAX_VALUE + 1);

    // Example: Attr2 decays (decreases) slightly over time, bounded by 0
    if (blocksPassed * attributeDecayRate > baseAttr2) {
         calculatedAttr2 = 0;
    } else {
         calculatedAttr2 = baseAttr2 - (blocksPassed * attributeDecayRate);
    }

    // Mix in current entropy for variation (simplified)
    calculatedAttr1 = (calculatedAttr1 + (entropy % 50)) % (ATTRIBUTE_MAX_VALUE + 1);
    calculatedAttr2 = (calculatedAttr2 + (entropy % 50)) % (ATTRIBUTE_MAX_VALUE + 1);


    // Ensure results are within bounds
    attr1 = calculatedAttr1 % (ATTRIBUTE_MAX_VALUE + 1);
    attr2 = calculatedAttr2 % (ATTRIBUTE_MAX_VALUE + 1);

    return (attr1, attr2);
}

// --- Staking Functions (Temporal Anchoring) ---

/**
 * @dev Stakes a Chrono-Shard NFT. Transfers ownership to the contract
 *      and records staking information. Requires ownership.
 * @param tokenId The ID of the shard to stake.
 */
function stakeShard(uint256 tokenId) external isShardOwner(tokenId) {
    address staker = msg.sender;
    require(!_shardStakingInfo[tokenId].isStaked, "Shard already staked");

    // Before staking, claim any pending rewards from previous stakes of this shard
    // (This prevents reward manipulation by rapid unstake/restake,
    // assuming rewards are only claimable by the _current_ staker).
    // This also handles the edge case if a shard was previously staked, unstaked, and is now being re-staked.
    uint256 pending = _calculateStakingRewards(tokenId, staker); // Calculate based on OLD staking info if any
    if (pending > 0) {
        _mintToken(staker, pending); // Mint rewards to the staker
        emit StakingRewardsClaimed(staker, pending);
         _shardStakingInfo[tokenId].rewardClaimedTime = block.timestamp; // Update claimed time for the OLD stake record
    }


    // Record new staking info
    _shardStakingInfo[tokenId].staker = staker;
    _shardStakingInfo[tokenId].stakeTime = block.timestamp;
    _shardStakingInfo[tokenId].rewardClaimedTime = block.timestamp; // Reset claim time for the new stake
    _shardStakingInfo[tokenId].isStaked = true;

    // Transfer ownership to the contract to "lock" it
    _transfer(staker, address(this), tokenId);

    // Add to staker's list (simple append, requires manual cleanup/tracking for removals)
    _stakedShardsByStaker[staker].push(tokenId);

    emit ShardStaked(staker, tokenId, block.timestamp);
}

/**
 * @dev Unstakes a Chrono-Shard NFT. Transfers ownership back to the original staker
 *      and clears staking information. Requires the caller to be the staker.
 *      Allows claiming pending rewards before unstaking.
 * @param tokenId The ID of the shard to unstake.
 */
function unstakeShard(uint256 tokenId) external isShardStakedByCaller(tokenId) {
    address staker = msg.sender;
    ShardStakingInfo storage stakingInfo = _shardStakingInfo[tokenId];

    // Claim any pending rewards upon unstaking
    uint256 pending = _calculateStakingRewards(tokenId, staker);
    if (pending > 0) {
        _mintToken(staker, pending); // Mint rewards to the staker
        emit StakingRewardsClaimed(staker, pending);
    }

    // Clear staking info
    stakingInfo.isStaked = false;
    stakingInfo.staker = address(0);
    stakingInfo.stakeTime = 0;
    stakingInfo.rewardClaimedTime = 0; // Reset state fully

    // Transfer ownership back to the original staker
    _transfer(address(this), staker, tokenId);

    // Remove from staker's list (basic implementation - inefficient for large lists)
    uint256[] storage staked = _stakedShardsByStaker[staker];
    for (uint i = 0; i < staked.length; i++) {
        if (staked[i] == tokenId) {
            staked[i] = staked[staked.length - 1];
            staked.pop();
            break;
        }
    }

    emit ShardUnstaked(staker, tokenId, block.timestamp);
}

/**
 * @dev Claims accumulated $TIME rewards from all staked and recently unstaked shards
 *      by the caller. Rewards are calculated based on staking duration since last claim.
 */
function claimStakingRewards() external {
    address staker = msg.sender;
    uint256 totalRewards = 0;

    // Need to iterate through all shards the user has ever staked
    // This requires tracking all staked shards per user historically,
    // or having a way to query all shards owned by the contract and check staking info.
    // The current _stakedShardsByStaker mapping only tracks *currently* staked shards.
    // A more robust system might require a different data structure or claiming per shard.
    // For simplicity here, we'll iterate through *currently* staked shards and assume a user
    // claims rewards *before* unstaking. A better pattern would be to store pending rewards per shard/user.

    // Let's refine: Iterate through currently staked shards and claim for those.
    // A separate mechanism would be needed for claiming after unstaking if not done before.
    // Simpler pattern: Calculate rewards per shard and claim all at once.
    // The `_calculateStakingRewards` internal function already does the time calculation per shard.

    uint256[] memory currentlyStaked = _stakedShardsByStaker[staker];
    uint256[] memory claimableTokenIds; // To track which shards had rewards claimed
    uint256[] memory claimableAmounts;

    for(uint i = 0; i < currentlyStaked.length; i++){
        uint256 tokenId = currentlyStaked[i];
        if (_shardStakingInfo[tokenId].staker == staker) { // Double check ownership/staker link
             uint256 pending = _calculateStakingRewards(tokenId, staker);
             if (pending > 0) {
                 claimableTokenIds.push(tokenId);
                 claimableAmounts.push(pending);
                 totalRewards += pending;
             }
        }
    }

    require(totalRewards > 0, "No rewards to claim");

    // Mint total rewards to the staker
    _mintToken(staker, totalRewards);

    // Update claimed time for the shards where rewards were calculated
    for(uint i = 0; i < claimableTokenIds.length; i++){
         _shardStakingInfo[claimableTokenIds[i]].rewardClaimedTime = block.timestamp;
    }

    emit StakingRewardsClaimed(staker, totalRewards);
}

/**
 * @dev Gets the list of shard IDs currently staked by a given address.
 * @param staker The address to check.
 * @return An array of shard IDs.
 */
function getStakedShards(address staker) external view returns (uint256[] memory) {
    return _stakedShardsByStaker[staker];
}

/**
 * @dev Calculates the total pending $TIME rewards for a staker across all their currently staked shards.
 * @param staker The address to check.
 * @return The total pending reward amount.
 */
function getPendingStakingRewards(address staker) external view returns (uint256) {
    uint256 totalPending = 0;
    uint256[] memory currentlyStaked = _stakedShardsByStaker[staker];

    for(uint i = 0; i < currentlyStaked.length; i++){
        uint256 tokenId = currentlyStaked[i];
        if (_shardStakingInfo[tokenId].staker == staker) { // Double check ownership/staker link
            totalPending += _calculateStakingRewards(tokenId, staker);
        }
    }
    return totalPending;
}


/**
 * @dev Internal helper to calculate staking rewards for a specific shard.
 * @param tokenId The ID of the shard.
 * @param staker The address of the staker.
 * @return The calculated reward amount.
 */
function _calculateStakingRewards(uint256 tokenId, address staker) internal view returns (uint256) {
    ShardStakingInfo memory stakingInfo = _shardStakingInfo[tokenId];

    // Ensure the shard is currently staked by this staker before calculating
    if (!(stakingInfo.isStaked && stakingInfo.staker == staker)) {
        // If not currently staked by this staker, check if it was recently unstaked
        // This logic is tricky. A robust system needs better tracking.
        // For this example, let's assume rewards are primarily calculated while staked.
        // A more advanced system could store unclaimed rewards per user per shard.
        // Simple approach: only calculate for currently staked shards.
        return 0;
    }

    uint256 timeStaked = block.timestamp - stakingInfo.rewardClaimedTime;
    return timeStaked * stakingRewardRatePerSecond;
}


// --- Challenge Functions (Chronosync Challenges) ---

/**
 * @dev Creates a new attribute-based challenge. Callable only by the owner.
 * @param challengeType The type of attribute check (e.g., 1 for Attr1 > value).
 * @param requiredAttributeValue The value needed for the check.
 * @param rewardAmount The $TIME reward for successful completion.
 * @param requiredAttempts The number of successful checks needed to complete.
 * @param attemptFee The $TIME fee burned per attempt.
 */
function createChallenge(
    uint256 challengeType,
    uint256 requiredAttributeValue,
    uint256 rewardAmount,
    uint256 requiredAttempts,
    uint256 attemptFee
) external onlyOwner {
    require(challengeType > 0 && challengeType <= 2, "Invalid challenge type"); // Example: Type 1 or 2
    require(requiredAttributeValue <= ATTRIBUTE_MAX_VALUE, "Required attribute value too high");
    require(requiredAttempts > 0, "Required attempts must be positive");

    uint256 challengeId = _nextChallengeId++;
    _challengeConfigs[challengeId] = ChallengeConfig({
        challengeType: challengeType,
        requiredAttributeValue: requiredAttributeValue,
        rewardAmount: rewardAmount,
        requiredAttempts: requiredAttempts,
        attemptFee: attemptFee,
        isActive: true
    });

    emit ChallengeCreated(challengeId, challengeType, rewardAmount);
}

/**
 * @dev Participates in a challenge using a specific shard.
 *      Requires ownership of the shard and burns the attempt fee ($TIME).
 *      Checks shard attributes against challenge requirements.
 * @param challengeId The ID of the challenge.
 * @param tokenId The ID of the shard to use.
 */
function participateInChallenge(uint256 challengeId, uint256 tokenId) external isShardOwner(tokenId) {
    ChallengeConfig storage config = _challengeConfigs[challengeId];
    require(config.isActive, "Challenge is not active");
    ChallengeProgress storage progress = _challengeProgress[msg.sender][challengeId];
    require(!progress.completed, "Challenge already completed");

    // --- Simulate token burn cost ---
    require(_timeBalances[msg.sender] >= config.attemptFee, "Insufficient TIME for attempt fee");
    _burnToken(msg.sender, config.attemptFee);
    // --- End simulate token burn cost ---

    // Get and sync shard attributes (getShardAttributes handles sync if needed)
    ShardAttributes memory currentAttributes = getShardAttributes(tokenId);

    // Check if the shard's attributes meet the challenge requirement
    bool passedCheck = _checkChallengeCompletion(challengeId, currentAttributes);

    if (passedCheck) {
        progress.successfulAttempts++;
    }

    // Increment total attempts for tracking purposes (optional, could be added to progress struct)
    // _challengeAttempts[msg.sender][challengeId]++; // Requires additional mapping

    emit ChallengeParticipated(msg.sender, challengeId, tokenId, passedCheck);

    // Check if challenge is completed after this attempt
    if (passedCheck && progress.successfulAttempts >= config.requiredAttempts) {
        progress.completed = true;
        emit ChallengeCompleted(msg.sender, challengeId);
    }
}

/**
 * @dev Claims the $TIME reward for a successfully completed challenge.
 *      Requires the challenge to be completed and the reward not yet claimed.
 * @param challengeId The ID of the challenge.
 */
function claimChallengeReward(uint256 challengeId) external {
    ChallengeConfig storage config = _challengeConfigs[challengeId];
    ChallengeProgress storage progress = _challengeProgress[msg.sender][challengeId];

    require(config.isActive, "Challenge is not active");
    require(progress.completed, "Challenge not yet completed");
    require(!progress.rewardClaimed, "Reward already claimed");

    // --- Simulate token mint reward ---
    _mintToken(msg.sender, config.rewardAmount);
    // --- End simulate token mint reward ---

    progress.rewardClaimed = true;

    emit ChallengeRewardClaimed(msg.sender, challengeId, config.rewardAmount);
}

/**
 * @dev Gets the configuration details for a specific challenge.
 * @param challengeId The ID of the challenge.
 * @return The ChallengeConfig struct.
 */
function getChallengeConfig(uint256 challengeId) external view returns (ChallengeConfig memory) {
    require(_challengeConfigs[challengeId].isActive, "Challenge does not exist or is inactive");
    return _challengeConfigs[challengeId];
}

/**
 * @dev Gets the progress details for a user on a specific challenge.
 * @param user The address of the user.
 * @param challengeId The ID of the challenge.
 * @return The ChallengeProgress struct.
 */
function getChallengeProgress(address user, uint256 challengeId) external view returns (ChallengeProgress memory) {
     require(_challengeConfigs[challengeId].isActive, "Challenge does not exist or is inactive"); // Can view progress even if not active
    return _challengeProgress[user][challengeId];
}

/**
 * @dev Internal helper to check if a shard's attributes meet a challenge's criteria.
 * @param challengeId The ID of the challenge.
 * @param attributes The attributes of the shard.
 * @return True if the criteria are met, false otherwise.
 */
function _checkChallengeCompletion(uint256 challengeId, ShardAttributes memory attributes) internal view returns (bool) {
    ChallengeConfig memory config = _challengeConfigs[challengeId];
    require(config.isActive, "Challenge not active for check"); // Should ideally be checked by caller

    if (config.challengeType == 1) {
        return attributes.dynamicAttr1 >= config.requiredAttributeValue;
    } else if (config.challengeType == 2) {
        return attributes.dynamicAttr2 <= config.requiredAttributeValue;
    }
    // Add more challenge types here

    return false; // Default case for unknown challenge types
}

// --- Simulated Token Functions ($TIME) ---

/**
 * @dev Gets the simulated $TIME token balance for an address.
 * @param user The address to check.
 * @return The balance.
 */
function getTokenBalance(address user) external view returns (uint256) {
    return _timeBalances[user];
}

/**
 * @dev Owner can mint new $TIME tokens. Used for initial supply or rewards pool.
 * @param recipient The address to receive the minted tokens.
 * @param amount The amount to mint.
 */
function ownerMintToken(address recipient, uint256 amount) external onlyOwner {
    _mintToken(recipient, amount);
}

/**
 * @dev Internal function to mint $TIME tokens.
 * @param recipient The address to receive tokens.
 * @param amount The amount to mint.
 */
function _mintToken(address recipient, uint256 amount) internal {
    _timeTotalSupply += amount;
    _timeBalances[recipient] += amount;
    emit TokenMinted(recipient, amount);
    emit TokenTransfer(address(0), recipient, amount);
}

/**
 * @dev Internal function to burn $TIME tokens.
 * @param burner The address from which tokens are burned.
 * @param amount The amount to burn.
 */
function _burnToken(address burner, uint256 amount) internal {
    require(_timeBalances[burner] >= amount, "Insufficient TIME balance for burn");
    _timeBalances[burner] -= amount;
    _timeTotalSupply -= amount;
    emit TokenBurned(burner, amount);
    emit TokenTransfer(burner, address(0), amount);
}

/**
 * @dev Internal function to transfer $TIME tokens.
 *      Not exposed externally to prevent this contract acting as a full ERC20.
 * @param from The sender address.
 * @param to The recipient address.
 * @param amount The amount to transfer.
 */
function _transferToken(address from, address to, uint256 amount) internal {
     require(_timeBalances[from] >= amount, "Insufficient TIME balance for transfer");
     _timeBalances[from] -= amount;
     _timeBalances[to] += amount;
     emit TokenTransfer(from, to, amount);
}


// --- Utility/View Functions ---

/**
 * @dev Gets the total number of Chrono-Shards minted.
 * @return The total count.
 */
function getTotalShards() external view returns (uint256) {
    return _nextTokenId;
}

/**
 * @dev Gets the staking information for a specific shard.
 * @param tokenId The ID of the shard.
 * @return The ShardStakingInfo struct.
 */
function getShardStakingInfo(uint256 tokenId) external view returns (ShardStakingInfo memory) {
     // Shard must exist, but doesn't have to be staked to check info struct
    require(_owners[tokenId] != address(0), "Shard does not exist");
    return _shardStakingInfo[tokenId];
}

/**
 * @dev Helper function to get the current block number.
 * @return The current block number.
 */
function getCurrentBlockNumber() external view returns (uint256) {
    return block.number;
}

// Add other utility functions if needed (e.g., get owner address, get TIME total supply)
function owner() external view returns (address) {
    return _owner;
}

function getTimeTotalSupply() external view returns (uint256) {
    return _timeTotalSupply;
}

// Functions to set parameters (e.g., staking rate, decay rate) - owner only
function setStakingRewardRate(uint256 ratePerSecond) external onlyOwner {
    stakingRewardRatePerSecond = ratePerSecond;
}

function setAttributeDecayRate(uint256 rate) external onlyOwner {
    attributeDecayRate = rate;
}

function setAttributeEvolutionRate(uint256 rate) external onlyOwner {
    attributeEvolutionRate = rate;
}

function deactivateChallenge(uint256 challengeId) external onlyOwner {
    require(_challengeConfigs[challengeId].isActive, "Challenge is already inactive");
    _challengeConfigs[challengeId].isActive = false;
}


// Counting functions (can be expensive for large data, use with caution)
// This is just to meet the function count/demonstrate features
function getUserStakedShardCount(address user) external view returns (uint256) {
    return _stakedShardsByStaker[user].length;
}

function getUserChallengeSuccessfulAttempts(address user, uint256 challengeId) external view returns (uint256) {
     require(_challengeConfigs[challengeId].isActive, "Challenge does not exist or is inactive");
    return _challengeProgress[user][challengeId].successfulAttempts;
}


}
```