Here's a smart contract for the "GenesisShard Protocol," designed with advanced, creative, and trendy concepts like dynamic NFTs, on-chain evolutionary mechanics, and a self-governing ecosystem. It integrates a native token ($AURA) with evolving NFTs (Genesis Shards) to create a unique, interactive experience.

---

## GenesisShard Protocol: An Evolving Digital Ecosystem

This contract introduces a novel ecosystem where digital entities, called "Genesis Shards" (dynamic NFTs), evolve and interact based on user actions and a "Catalyst Engine." The protocol features a native ERC-20 token ($AURA) that fuels interactions, staking, and rewards. Shards possess mutable traits (`level`, `purity`, `resonance`, `affinity`) that influence their utility, voting power, and evolutionary path. A decentralized governance mechanism allows the community, via Shard power, to propose and enact "Protocol Mutations" (parameter changes).

### Outline:

*   **I. Core Assets & Identity:** Management of the native $AURA ERC-20 token and dynamic Genesis Shard ERC-721 NFTs.
*   **II. Shard Evolution & Interaction:** Functions for users to influence their Shards' growth, stake $AURA for boosts, activate temporary effects, merge Shards, and attune their fundamental `affinity`.
*   **III. Catalyst Engine & Ecosystem Dynamics:** The heart of the protocol, where periodic "Evolutionary Pressure" is applied, driving Shard trait changes, distributing latent rewards, and maintaining ecosystem balance.
*   **IV. Protocol Governance (Mutations):** A decentralized autonomous organization (DAO) mechanism enabling Shard holders to propose, vote on, and execute changes to core protocol parameters.
*   **V. Administrative & Utility Functions:** Essential functions for contract management, access control, pausing, and emergency fund recovery.

### Function Summary:

**I. Core Assets & Identity**

1.  `constructor(string memory name, string memory symbol, string memory shardName, string memory shardSymbol)`: Initializes the ERC-20 ($AURA) and ERC-721 (Genesis Shard) tokens, roles, and initial protocol parameters.
2.  `mintGenesisShard(address to, uint256 initialAffinity)`: Mints a new Genesis Shard NFT to an address, assigning an initial `affinity`. Requires a minting fee in $AURA.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC-721 function to transfer a Genesis Shard.
4.  `approve(address to, uint256 tokenId)`: Standard ERC-721 function to approve an address to transfer a specific Shard.
5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC-721 function to approve/disapprove an operator for all Shards.
6.  `tokenURI(uint256 tokenId)`: Retrieves the metadata URI for a given Genesis Shard, reflecting its current dynamic traits. (This will be dynamically generated off-chain in a real scenario, but the function exists).
7.  `getShard(uint256 shardId)`: Retrieves all mutable properties (`level`, `purity`, `resonance`, `affinity`, `stakedAuraAmount`, `lastEvolutionTimestamp`) of a specific Genesis Shard.
8.  `getTotalSupplyShards()`: Returns the total count of Genesis Shards ever minted.
9.  `balanceOf(address owner)`: Standard ERC-20 function: returns the $AURA token balance of an account.
10. `transfer(address to, uint256 amount)`: Standard ERC-20 function: transfers $AURA tokens.
11. `approveAura(address spender, uint256 amount)`: Standard ERC-20 function: approves a spender for $AURA.
12. `transferFromAura(address from, address to, uint256 amount)`: Standard ERC-20 function: transfers $AURA tokens on behalf of an approved owner.
13. `burnAura(uint256 amount)`: Burns a specified amount of $AURA tokens from the caller's balance.

**II. Shard Evolution & Interaction**

14. `stakeAuraForShardBoost(uint256 shardId, uint256 amount)`: Stakes $AURA tokens against a specific Genesis Shard, directly increasing its `purity` trait and contributing to its `level` growth.
15. `unstakeAuraFromShard(uint256 shardId, uint256 amount)`: Allows the owner to unstake $AURA tokens previously staked against their Shard.
16. `activateShardResonance(uint256 shardId)`: Consumes $AURA to temporarily boost a Shard's `resonance` trait, enhancing its chances for beneficial evolution in the Catalyst Engine for a limited duration.
17. `catalyzeShardMerge(uint256 shardId_A, uint256 shardId_B)`: Merges two Genesis Shards owned by the caller. `shardId_B` is burned, and `shardId_A` is enhanced, gaining combined traits and a `level` boost. Requires a $AURA fee.
18. `attuneShardAffinity(uint256 shardId, uint256 newAffinity)`: Pays $AURA to change a Shard's `affinity` trait, allowing strategic adaptation to different ecosystem dynamics or future features.

**III. Catalyst Engine & Ecosystem Dynamics**

19. `applyEvolutionaryPressure(uint256 batchSize)`: The core Catalyst Engine function. Triggered by anyone (incentivized by a small $AURA reward), it processes a batch of active Shards, applying time-based decay, calculating potential trait evolutions (e.g., `level` up, `purity` decay), and accumulating latent $AURA rewards based on their current state and activity.
20. `claimAuraRewards(uint256[] calldata shardIds)`: Allows owners to claim their accumulated $AURA rewards generated by their specified Shards.
21. `getPendingAuraRewards(uint256 shardId)`: Calculates and returns the currently accumulated, claimable $AURA rewards for a single Shard.
22. `setCatalystEngineParameters(uint256 _evolutionInterval, uint256 _shardMergeCost, uint256 _resonanceBoostCost, uint256 _affinityChangeCost, uint256 _auraStakingMultiplier, uint256 _baseAuraRewardRate, uint256 _evolutionProcessingReward)`: Admin function to adjust mutable parameters governing the Catalyst Engine's behavior.

**IV. Protocol Governance (Mutations)**

23. `proposeProtocolMutation(bytes32 parameterHash, uint256 newValue, string memory description)`: Allows Shard holders with sufficient cumulative voting power to propose a change to a mutable protocol parameter (e.g., `MINT_FEE`, `STAKING_MULTIPLIER`).
24. `voteOnMutation(uint256 mutationId, bool support)`: Casts a vote (for or against) on an active protocol mutation, using the voting power derived from the caller's owned Shards (`level` + `purity` contribute).
25. `executeMutation(uint256 mutationId)`: Executes a successfully passed and finalized protocol mutation, applying the proposed parameter change.
26. `getMutationStatus(uint256 mutationId)`: Retrieves the current status, votes (for/against), and details of a specific mutation proposal.

**V. Administrative & Utility Functions**

27. `pause()`: Pauses certain critical functions of the contract, such as minting and transfers (requires `PAUSER_ROLE`).
28. `unpause()`: Unpauses the contract functions (requires `PAUSER_ROLE`).
29. `grantRole(bytes32 role, address account)`: Grants a specified role (e.g., `ADMIN_ROLE`, `PAUSER_ROLE`) to an account. Only callable by the `ADMIN_ROLE` or a role's specific admin.
30. `revokeRole(bytes32 role, address account)`: Revokes a specified role from an account.
31. `renounceRole(bytes32 role)`: Allows an account to voluntarily renounce a role it possesses.
32. `withdrawExcessFunds(address tokenAddress, address recipient)`: Allows the `ADMIN_ROLE` to withdraw accidentally sent tokens (ERC-20) or ETH from the contract, ensuring funds are not permanently locked.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

/**
 * @title GenesisShardProtocol
 * @dev An advanced, dynamic, and self-governing ecosystem featuring evolving NFTs (Genesis Shards)
 *      and a native ERC-20 token ($AURA).
 *      - Dynamic NFTs: Shards evolve their traits (level, purity, resonance, affinity).
 *      - Catalyst Engine: A pseudo-random/time-based mechanism for on-chain evolution.
 *      - Decentralized Governance: Shard holders propose and vote on protocol mutations.
 *      - Staking & Rewards: $AURA staking influences Shard evolution and yields rewards.
 *      - Unique Mechanics: Shard merging, resonance activation, affinity attunement.
 */
contract GenesisShardProtocol is ERC20, ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- I. Core Assets & Identity ---

    // Roles for AccessControl
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Can pause critical functions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Can mint AURA tokens

    // ERC-721 Genesis Shard properties
    Counters.Counter private _shardIds; // Counter for unique Shard IDs

    struct Shard {
        uint256 level;       // Represents overall growth, increases with merges/activity
        uint256 purity;      // Influenced by staked AURA, boosts rewards and voting power
        uint256 resonance;   // Time-bound boost from activation, enhances evolution chances
        uint256 affinity;    // Categorical trait (e.g., 0=Fire, 1=Water), influences specific rewards/interactions
        uint256 lastEvolutionTimestamp; // When it last evolved or was acted upon
        uint256 stakedAuraAmount; // AURA staked against this specific shard
        address stakedAuraOwner; // Original owner of the staked AURA, for unstaking
        uint256 pendingRewards; // Accumulating AURA rewards
        uint256 resonanceExpiration; // Timestamp when resonance boost expires
    }

    mapping(uint256 => Shard) public genesisShards;

    // --- II. Shard Evolution & Interaction Parameters ---
    uint256 public MINT_FEE = 1000 * 10**18; // AURA tokens required to mint a new Shard
    uint256 public SHARD_MERGE_COST = 500 * 10**18; // AURA tokens required to merge Shards
    uint256 public RESONANCE_BOOST_COST = 200 * 10**18; // AURA tokens to activate resonance
    uint256 public RESONANCE_DURATION = 7 days; // How long resonance lasts
    uint256 public AFFINITY_CHANGE_COST = 300 * 10**18; // AURA tokens to change shard affinity
    uint256 public AURA_STAKING_MULTIPLIER = 10; // Multiplier for staked AURA affecting purity/level
    uint256 public PURITY_DECAY_RATE = 1; // Purity decay per day (as a percentage point)
    uint256 public MIN_PURITY_FOR_EVOLUTION = 50; // Minimum purity for positive evolution chance

    // --- III. Catalyst Engine & Ecosystem Dynamics Parameters ---
    uint256 public EVOLUTION_INTERVAL = 1 days; // Minimum time between major evolutionary pressure applications
    uint256 public BASE_AURA_REWARD_RATE = 1 * 10**18; // Base AURA per Shard per day for rewards
    uint256 public EVOLUTION_PROCESSING_REWARD = 10 * 10**18; // AURA reward for calling applyEvolutionaryPressure
    uint256 public lastEvolutionPressureTimestamp; // Last time applyEvolutionaryPressure was called

    // --- IV. Protocol Governance (Mutations) Parameters ---
    uint256 public MIN_VOTING_POWER_TO_PROPOSE = 1000; // Minimum total (level + purity) to propose
    uint256 public MUTATION_VOTING_PERIOD = 3 days;
    uint256 public MUTATION_QUORUM_PERCENTAGE = 51; // 51% of total active voting power
    uint256 public MUTATION_THRESHOLD_PERCENTAGE = 60; // 60% of cast votes must be 'for'

    struct MutationProposal {
        bytes32 parameterHash; // keccak256 hash of the parameter name (e.g., "MINT_FEE")
        uint256 newValue;      // The proposed new value
        string description;     // Description of the change
        uint256 startTime;      // When the proposal started
        uint256 forVotes;       // Total voting power for the proposal
        uint256 againstVotes;   // Total voting power against the proposal
        bool executed;          // Whether the mutation has been executed
        mapping(address => bool) hasVoted; // Tracks if an address has voted (prevents double voting)
    }

    Counters.Counter private _mutationIds;
    mapping(uint256 => MutationProposal) public mutationProposals;
    mapping(bytes32 => bool) public mutableParameters; // Maps hash of parameter name to true if mutable

    // --- Events ---
    event ShardMinted(address indexed owner, uint256 indexed shardId, uint256 initialAffinity);
    event ShardStaked(uint256 indexed shardId, address indexed staker, uint256 amount, uint256 newPurity);
    event ShardUnstaked(uint256 indexed shardId, address indexed staker, uint256 amount, uint256 newPurity);
    event ShardResonanceActivated(uint256 indexed shardId, uint256 cost, uint256 expiration);
    event ShardMerged(uint256 indexed primaryShardId, uint256 indexed consumedShardId, address indexed owner, uint256 newLevel, uint256 newPurity);
    event ShardAffinityAttuned(uint256 indexed shardId, uint256 oldAffinity, uint256 newAffinity);
    event ShardEvolved(uint256 indexed shardId, uint256 oldLevel, uint256 newLevel, uint256 oldPurity, uint256 newPurity, uint256 oldResonance, uint256 newResonance);
    event AuraRewardsClaimed(address indexed claimant, uint256[] indexed shardIds, uint256 amount);
    event MutationProposed(uint256 indexed mutationId, address indexed proposer, bytes32 parameterHash, uint256 newValue, string description);
    event MutationVoted(uint256 indexed mutationId, address indexed voter, bool support, uint256 votingPower);
    event MutationExecuted(uint256 indexed mutationId, bytes32 parameterHash, uint256 newValue);
    event CatalystParametersSet(uint256 evolutionInterval, uint256 shardMergeCost, uint256 resonanceBoostCost, uint256 affinityChangeCost, uint256 auraStakingMultiplier, uint256 baseAuraRewardRate, uint256 evolutionProcessingReward);

    constructor(string memory name, string memory symbol, string memory shardName, string memory shardSymbol)
        ERC20(name, symbol)
        ERC721(shardName, shardSymbol)
        ReentrancyGuard()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Initialize mutable parameters for governance
        mutableParameters[keccak256("MINT_FEE")] = true;
        mutableParameters[keccak256("SHARD_MERGE_COST")] = true;
        mutableParameters[keccak256("RESONANCE_BOOST_COST")] = true;
        mutableParameters[keccak256("AFFINITY_CHANGE_COST")] = true;
        mutableParameters[keccak256("AURA_STAKING_MULTIPLIER")] = true;
        mutableParameters[keccak256("PURITY_DECAY_RATE")] = true;
        mutableParameters[keccak256("MIN_PURITY_FOR_EVOLUTION")] = true;
        mutableParameters[keccak256("EVOLUTION_INTERVAL")] = true;
        mutableParameters[keccak256("BASE_AURA_REWARD_RATE")] = true;
        mutableParameters[keccak256("EVOLUTION_PROCESSING_REWARD")] = true;
        mutableParameters[keccak256("MIN_VOTING_POWER_TO_PROPOSE")] = true;
        mutableParameters[keccak256("MUTATION_VOTING_PERIOD")] = true;
        mutableParameters[keccak256("MUTATION_QUORUM_PERCENTAGE")] = true;
        mutableParameters[keccak256("MUTATION_THRESHOLD_PERCENTAGE")] = true;
    }

    // Fallback function to receive ETH (e.g., for accidental transfers)
    receive() external payable {}

    // --- I. Core Assets & Identity ---

    /**
     * @dev Mints a new Genesis Shard NFT.
     * @param to The address to mint the Shard to.
     * @param initialAffinity The initial affinity trait for the new Shard.
     */
    function mintGenesisShard(address to, uint256 initialAffinity) external nonReentrant whenNotPaused {
        require(initialAffinity < 100, "GenesisShard: Affinity must be < 100 (for categorization)"); // Example constraint
        require(ERC20.transferFrom(msg.sender, address(this), MINT_FEE), "GenesisShard: AURA transfer failed for mint fee");

        _shardIds.increment();
        uint256 newShardId = _shardIds.current();

        genesisShards[newShardId] = Shard({
            level: 1,
            purity: 100, // Starts with high purity
            resonance: 0,
            affinity: initialAffinity,
            lastEvolutionTimestamp: block.timestamp,
            stakedAuraAmount: 0,
            stakedAuraOwner: address(0),
            pendingRewards: 0,
            resonanceExpiration: 0
        });

        _mint(to, newShardId);
        emit ShardMinted(to, newShardId, initialAffinity);
    }

    /**
     * @dev Standard ERC-721 transferFrom function.
     * Overridden to handle Shard specific logic if needed (e.g., unstake before transfer).
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(genesisShards[tokenId].stakedAuraAmount == 0, "GenesisShard: Cannot transfer Shard with staked AURA. Unstake first.");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Standard ERC-721 approve function.
     */
    function approve(address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.approve(to, tokenId);
    }

    /**
     * @dev Standard ERC-721 setApprovalForAll function.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Retrieves the metadata URI for a given Genesis Shard.
     * In a real scenario, this would point to an off-chain API that dynamically generates
     * the URI based on the Shard's current traits from `getShard`.
     * For this contract, it returns a placeholder.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Shard storage shard = genesisShards[tokenId];
        // In a real application, this would construct a URL like:
        // return string(abi.encodePacked("https://api.genesisshard.xyz/metadata/", tokenId.toString()));
        // The API would then query the contract for shard.level, shard.purity etc.
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
            bytes(abi.encodePacked(
                '{"name": "Genesis Shard #', tokenId.toString(),
                '", "description": "An evolving digital entity.",',
                '"attributes": [',
                    '{"trait_type": "Level", "value": ', shard.level.toString(), '},',
                    '{"trait_type": "Purity", "value": ', shard.purity.toString(), '},',
                    '{"trait_type": "Resonance", "value": ', shard.resonance.toString(), '},',
                    '{"trait_type": "Affinity", "value": ', shard.affinity.toString(), '}',
                ']}'
            ))
        )));
    }

    /**
     * @dev Returns all mutable properties of a Genesis Shard.
     * @param shardId The ID of the Shard.
     * @return Shard struct containing all properties.
     */
    function getShard(uint256 shardId) public view returns (Shard memory) {
        require(_exists(shardId), "GenesisShard: Shard does not exist");
        return genesisShards[shardId];
    }

    /**
     * @dev Returns the total number of Genesis Shards minted.
     */
    function getTotalSupplyShards() public view returns (uint256) {
        return _shardIds.current();
    }

    /**
     * @dev Standard ERC-20: Returns the AURA token balance of an account.
     * @param account The address to query.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    /**
     * @dev Standard ERC-20: Transfers AURA tokens from msg.sender to another address.
     * @param to The recipient.
     * @param amount The amount of AURA to transfer.
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    /**
     * @dev Standard ERC-20: Allows a `spender` to spend `amount` AURA on behalf of msg.sender.
     * @param spender The address allowed to spend.
     * @param amount The amount to allow.
     */
    function approveAura(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Standard ERC-20: Transfers AURA tokens from `from` to `to` using the allowance mechanism.
     * @param from The owner of the tokens.
     * @param to The recipient.
     * @param amount The amount of AURA to transfer.
     */
    function transferFromAura(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(from, to, amount); // Handles allowance internally
        return true;
    }

    /**
     * @dev Burns a specified amount of AURA tokens from the caller's balance.
     * @param amount The amount of AURA to burn.
     */
    function burnAura(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Mints AURA tokens to a specified address. Restricted to MINTER_ROLE.
     * @param to The recipient of the minted tokens.
     * @param amount The amount of AURA to mint.
     */
    function _mintAura(address to, uint256 amount) internal virtual onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // --- II. Shard Evolution & Interaction ---

    /**
     * @dev Stakes AURA tokens to a specific Shard, increasing its purity and potential level growth.
     * @param shardId The ID of the Shard to stake against.
     * @param amount The amount of AURA to stake.
     */
    function stakeAuraForShardBoost(uint256 shardId, uint256 amount) external nonReentrant whenNotPaused {
        require(_exists(shardId), "GenesisShard: Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "GenesisShard: Caller is not Shard owner");
        require(amount > 0, "GenesisShard: Amount must be greater than zero");
        require(ERC20.transferFrom(msg.sender, address(this), amount), "GenesisShard: AURA transfer failed for staking");

        Shard storage shard = genesisShards[shardId];
        // If a new staker, record their address. Only one staker per shard for simplicity
        if (shard.stakedAuraAmount == 0) {
            shard.stakedAuraOwner = msg.sender;
        } else {
            require(shard.stakedAuraOwner == msg.sender, "GenesisShard: Only original staker can add more AURA");
        }

        shard.stakedAuraAmount = shard.stakedAuraAmount.add(amount);
        shard.purity = shard.purity.add(amount.div(10**18).mul(AURA_STAKING_MULTIPLIER)).min(1000); // Purity cap
        emit ShardStaked(shardId, msg.sender, amount, shard.purity);
    }

    /**
     * @dev Unstakes previously staked AURA from a Shard.
     * @param shardId The ID of the Shard to unstake from.
     * @param amount The amount of AURA to unstake.
     */
    function unstakeAuraFromShard(uint256 shardId, uint256 amount) external nonReentrant whenNotPaused {
        require(_exists(shardId), "GenesisShard: Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "GenesisShard: Caller is not Shard owner");
        require(genesisShards[shardId].stakedAuraOwner == msg.sender, "GenesisShard: Not the original staker");
        require(amount > 0, "GenesisShard: Amount must be greater than zero");

        Shard storage shard = genesisShards[shardId];
        require(shard.stakedAuraAmount >= amount, "GenesisShard: Not enough AURA staked to unstake this amount");

        shard.stakedAuraAmount = shard.stakedAuraAmount.sub(amount);
        // Reduce purity based on unstaked amount
        uint256 purityReduction = amount.div(10**18).mul(AURA_STAKING_MULTIPLIER);
        shard.purity = shard.purity.sub(purityReduction);
        if (shard.stakedAuraAmount == 0) {
            shard.stakedAuraOwner = address(0);
        }

        require(ERC20.transfer(msg.sender, amount), "GenesisShard: AURA transfer failed for unstaking");
        emit ShardUnstaked(shardId, msg.sender, amount, shard.purity);
    }

    /**
     * @dev Consumes AURA to temporarily boost a Shard's resonance, enhancing its chances in the evolutionary process.
     * @param shardId The ID of the Shard to activate resonance for.
     */
    function activateShardResonance(uint256 shardId) external nonReentrant whenNotPaused {
        require(_exists(shardId), "GenesisShard: Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "GenesisShard: Caller is not Shard owner");
        require(ERC20.transferFrom(msg.sender, address(this), RESONANCE_BOOST_COST), "GenesisShard: AURA transfer failed for resonance boost");

        Shard storage shard = genesisShards[shardId];
        // Reset or extend resonance duration
        shard.resonanceExpiration = block.timestamp.add(RESONANCE_DURATION);
        shard.resonance = shard.resonance.add(100).min(500); // Max resonance cap
        emit ShardResonanceActivated(shardId, RESONANCE_BOOST_COST, shard.resonanceExpiration);
    }

    /**
     * @dev Merges two Genesis Shards owned by the caller. shardId_B is burned, and shardId_A is enhanced.
     * The new level and purity of shardId_A are a weighted average/sum of both.
     * @param shardId_A The ID of the primary Shard (will be enhanced).
     * @param shardId_B The ID of the secondary Shard (will be burned).
     */
    function catalyzeShardMerge(uint256 shardId_A, uint256 shardId_B) external nonReentrant whenNotPaused {
        require(shardId_A != shardId_B, "GenesisShard: Cannot merge a Shard with itself");
        require(_exists(shardId_A) && _exists(shardId_B), "GenesisShard: One or both Shards do not exist");
        require(ownerOf(shardId_A) == msg.sender && ownerOf(shardId_B) == msg.sender, "GenesisShard: Caller must own both Shards");
        require(genesisShards[shardId_A].stakedAuraAmount == 0 && genesisShards[shardId_B].stakedAuraAmount == 0, "GenesisShard: Cannot merge Shards with staked AURA. Unstake first.");
        require(ERC20.transferFrom(msg.sender, address(this), SHARD_MERGE_COST), "GenesisShard: AURA transfer failed for merge cost");

        Shard storage shardA = genesisShards[shardId_A];
        Shard storage shardB = genesisShards[shardId_B];

        uint256 oldLevelA = shardA.level;
        uint256 oldPurityA = shardA.purity;

        // Simple merge logic: increase level, average purity, sum resonance, keep primary affinity
        shardA.level = shardA.level.add(shardB.level).div(2).add(1); // Avg level + bonus
        shardA.purity = shardA.purity.add(shardB.purity).div(2);     // Avg purity
        shardA.resonance = shardA.resonance.add(shardB.resonance).div(2); // Avg resonance
        // affinity of ShardA is retained

        _burn(shardId_B); // Burn the secondary Shard
        emit ShardMerged(shardId_A, shardId_B, msg.sender, shardA.level, shardA.purity);
        emit ShardEvolved(shardId_A, oldLevelA, shardA.level, oldPurityA, shardA.purity, shardA.resonance, shardA.resonance);
    }

    /**
     * @dev Pays AURA to change a Shard's affinity trait, altering its interaction with certain ecosystem dynamics.
     * @param shardId The ID of the Shard.
     * @param newAffinity The new affinity value.
     */
    function attuneShardAffinity(uint256 shardId, uint256 newAffinity) external nonReentrant whenNotPaused {
        require(_exists(shardId), "GenesisShard: Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "GenesisShard: Caller is not Shard owner");
        require(newAffinity < 100, "GenesisShard: Affinity must be < 100");
        require(ERC20.transferFrom(msg.sender, address(this), AFFINITY_CHANGE_COST), "GenesisShard: AURA transfer failed for affinity change");

        Shard storage shard = genesisShards[shardId];
        uint256 oldAffinity = shard.affinity;
        shard.affinity = newAffinity;
        emit ShardAffinityAttuned(shardId, oldAffinity, newAffinity);
    }

    // --- III. Catalyst Engine & Ecosystem Dynamics ---

    /**
     * @dev The core Catalyst Engine function. Processes a batch of Shards, applying evolutionary rules,
     *      updating traits, and distributing latent AURA rewards based on their current state and activity.
     *      This function can be called by anyone, incentivized by a reward.
     * @param batchSize The number of Shards to process in this batch.
     */
    function applyEvolutionaryPressure(uint256 batchSize) external nonReentrant whenNotPaused {
        require(block.timestamp.sub(lastEvolutionPressureTimestamp) >= EVOLUTION_INTERVAL, "GenesisShard: Evolutionary pressure can only be applied after interval");

        // Reward the caller for triggering the engine
        _mintAura(msg.sender, EVOLUTION_PROCESSING_REWARD);

        uint256 startShardId = lastEvolutionPressureTimestamp % _shardIds.current() + 1; // Simple pseudo-random start
        uint256 processedCount = 0;
        uint256 totalShards = _shardIds.current();

        for (uint256 i = 0; i < batchSize && processedCount < totalShards; i++) {
            uint256 currentShardId = (startShardId + i - 1) % totalShards + 1; // Loop through Shards

            if (_exists(currentShardId)) { // Ensure Shard hasn't been burned
                Shard storage shard = genesisShards[currentShardId];
                uint256 timePassed = block.timestamp.sub(shard.lastEvolutionTimestamp);
                if (timePassed > 0) { // Only evolve if time has passed
                    uint256 oldLevel = shard.level;
                    uint256 oldPurity = shard.purity;
                    uint256 oldResonance = shard.resonance;

                    // 1. Purity Decay: Over time, purity decays if not maintained by staking.
                    uint256 purityDecayAmount = timePassed.div(1 days).mul(PURITY_DECAY_RATE);
                    if (shard.purity > purityDecayAmount) {
                        shard.purity = shard.purity.sub(purityDecayAmount);
                    } else {
                        shard.purity = 0;
                    }

                    // 2. Resonance Decay: Resonance expires after its duration.
                    if (block.timestamp >= shard.resonanceExpiration) {
                        shard.resonance = 0;
                        shard.resonanceExpiration = 0;
                    }

                    // 3. Level Evolution: Based on purity and resonance
                    // A simple pseudo-random chance based on blockhash and shard properties.
                    // This is for demonstration. Real advanced contracts might use Chainlink VRF.
                    bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, currentShardId));
                    uint256 randomness = uint256(randomSeed) % 100; // 0-99

                    if (shard.purity >= MIN_PURITY_FOR_EVOLUTION && randomness < (shard.purity.div(10) + shard.resonance.div(50))) { // Example threshold
                        shard.level = shard.level.add(1); // Shard levels up!
                    }

                    // 4. Accumulate Rewards: Based on level, purity, and affinity
                    uint256 dailyRewardRate = BASE_AURA_REWARD_RATE.mul(shard.level).mul(shard.purity.add(100)).div(1000); // Example formula
                    shard.pendingRewards = shard.pendingRewards.add(dailyRewardRate.mul(timePassed.div(1 days)));

                    shard.lastEvolutionTimestamp = block.timestamp;

                    emit ShardEvolved(currentShardId, oldLevel, shard.level, oldPurity, shard.purity, oldResonance, shard.resonance);
                }
            }
            processedCount++;
        }
        lastEvolutionPressureTimestamp = block.timestamp;
    }

    /**
     * @dev Allows owners to claim accumulated AURA rewards generated by their specified Shards.
     * @param shardIds An array of Shard IDs to claim rewards for.
     */
    function claimAuraRewards(uint256[] calldata shardIds) external nonReentrant whenNotPaused {
        uint256 totalClaimAmount = 0;
        for (uint256 i = 0; i < shardIds.length; i++) {
            uint256 shardId = shardIds[i];
            require(_exists(shardId), "GenesisShard: Shard does not exist");
            require(ownerOf(shardId) == msg.sender, "GenesisShard: Not Shard owner");

            Shard storage shard = genesisShards[shardId];
            totalClaimAmount = totalClaimAmount.add(shard.pendingRewards);
            shard.pendingRewards = 0; // Reset pending rewards after claiming
        }
        require(totalClaimAmount > 0, "GenesisShard: No rewards to claim");
        _mintAura(msg.sender, totalClaimAmount);
        emit AuraRewardsClaimed(msg.sender, shardIds, totalClaimAmount);
    }

    /**
     * @dev Calculates and returns the currently accumulated, claimable AURA rewards for a single Shard.
     * @param shardId The ID of the Shard.
     * @return The amount of pending AURA rewards.
     */
    function getPendingAuraRewards(uint256 shardId) public view returns (uint256) {
        require(_exists(shardId), "GenesisShard: Shard does not exist");
        return genesisShards[shardId].pendingRewards;
    }

    /**
     * @dev Admin function to adjust core parameters for the Catalyst Engine.
     * @param _evolutionInterval The new evolution interval.
     * @param _shardMergeCost The new shard merge cost.
     * @param _resonanceBoostCost The new resonance boost cost.
     * @param _affinityChangeCost The new affinity change cost.
     * @param _auraStakingMultiplier The new AURA staking multiplier.
     * @param _baseAuraRewardRate The new base AURA reward rate.
     * @param _evolutionProcessingReward The reward for calling applyEvolutionaryPressure.
     */
    function setCatalystEngineParameters(
        uint256 _evolutionInterval,
        uint256 _shardMergeCost,
        uint256 _resonanceBoostCost,
        uint256 _affinityChangeCost,
        uint256 _auraStakingMultiplier,
        uint256 _baseAuraRewardRate,
        uint256 _evolutionProcessingReward
    ) external onlyRole(ADMIN_ROLE) {
        EVOLUTION_INTERVAL = _evolutionInterval;
        SHARD_MERGE_COST = _shardMergeCost;
        RESONANCE_BOOST_COST = _resonanceBoostCost;
        AFFINITY_CHANGE_COST = _affinityChangeCost;
        AURA_STAKING_MULTIPLIER = _auraStakingMultiplier;
        BASE_AURA_REWARD_RATE = _baseAuraRewardRate;
        EVOLUTION_PROCESSING_REWARD = _evolutionProcessingReward;
        emit CatalystParametersSet(
            _evolutionInterval,
            _shardMergeCost,
            _resonanceBoostCost,
            _affinityChangeCost,
            _auraStakingMultiplier,
            _baseAuraRewardRate,
            _evolutionProcessingReward
        );
    }

    // --- IV. Protocol Governance (Mutations) ---

    /**
     * @dev Internal helper to calculate a user's total voting power from their Shards.
     * @param voter The address of the voter.
     * @return The total voting power.
     */
    function _getVotingPower(address voter) internal view returns (uint256) {
        uint256 power = 0;
        uint256 shardCount = balanceOf(voter); // ERC721.balanceOf
        for (uint256 i = 0; i < shardCount; i++) {
            uint256 shardId = tokenOfOwnerByIndex(voter, i); // ERC721Enumerable not used, but basic lookup here.
            power = power.add(genesisShards[shardId].level);
            power = power.add(genesisShards[shardId].purity.div(10)); // Purity gives fractional power
        }
        return power;
    }

    /**
     * @dev Retrieves a token ID owned by `owner` at a given `index` of its token list.
     * This is an expensive operation and typically uses ERC721Enumerable, but implemented here
     * as a placeholder for brevity. In production, consider using ERC721Enumerable or an off-chain index.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        uint256 currentCount = 0;
        for (uint256 i = 1; i <= _shardIds.current(); i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                if (currentCount == index) {
                    return i;
                }
                currentCount++;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev Allows Shard holders with sufficient cumulative voting power to propose a change to a mutable protocol parameter.
     * @param parameterHash keccak256 hash of the parameter name (e.g., "MINT_FEE").
     * @param newValue The proposed new value for the parameter.
     * @param description A descriptive string for the proposal.
     */
    function proposeProtocolMutation(bytes32 parameterHash, uint256 newValue, string memory description) external nonReentrant whenNotPaused {
        require(mutableParameters[parameterHash], "GenesisShard: Parameter is not mutable through governance");
        require(_getVotingPower(msg.sender) >= MIN_VOTING_POWER_TO_PROPOSE, "GenesisShard: Not enough voting power to propose");

        _mutationIds.increment();
        uint256 newMutationId = _mutationIds.current();

        mutationProposals[newMutationId] = MutationProposal({
            parameterHash: parameterHash,
            newValue: newValue,
            description: description,
            startTime: block.timestamp,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new MutationProposal.hasVoted() // Initialize nested mapping
        });

        emit MutationProposed(newMutationId, msg.sender, parameterHash, newValue, description);
    }

    /**
     * @dev Casts a vote (for or against) on an active protocol mutation, using the voting power derived from owned Shards.
     * @param mutationId The ID of the mutation proposal.
     * @param support True for a 'for' vote, false for 'against'.
     */
    function voteOnMutation(uint256 mutationId, bool support) external nonReentrant whenNotPaused {
        MutationProposal storage proposal = mutationProposals[mutationId];
        require(proposal.startTime != 0, "GenesisShard: Proposal does not exist");
        require(block.timestamp < proposal.startTime.add(MUTATION_VOTING_PERIOD), "GenesisShard: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "GenesisShard: Already voted on this proposal");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "GenesisShard: No voting power");

        if (support) {
            proposal.forVotes = proposal.forVotes.add(voterPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterPower);
        }
        proposal.hasVoted[msg.sender] = true;
        emit MutationVoted(mutationId, msg.sender, support, voterPower);
    }

    /**
     * @dev Executes a successfully passed and finalized protocol mutation.
     * This function can be called by anyone once the voting period is over and conditions are met.
     * @param mutationId The ID of the mutation proposal.
     */
    function executeMutation(uint256 mutationId) external nonReentrant whenNotPaused {
        MutationProposal storage proposal = mutationProposals[mutationId];
        require(proposal.startTime != 0, "GenesisShard: Proposal does not exist");
        require(block.timestamp >= proposal.startTime.add(MUTATION_VOTING_PERIOD), "GenesisShard: Voting period not ended");
        require(!proposal.executed, "GenesisShard: Proposal already executed");

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        require(totalVotes > 0, "GenesisShard: No votes cast");

        // Quorum check: Minimum total voting power must participate
        uint256 totalActiveVotingPower = 0; // This would require iterating all shards, impractical on-chain.
                                          // For simplicity, we'll use `_shardIds.current() * average_shard_power` or a fixed proxy.
                                          // For this demo, let's use totalVotes >= a proxy of total voting power for quorum.
                                          // In a real DAO, snapshotting voting power at proposal creation is common.
        // Simplified quorum: require a minimum number of participating voters based on their power.
        // To properly implement quorum against total voting power, a snapshotting mechanism (e.g., ERC-20 Votes) is needed.
        // For this demo, we'll assume a basic quorum against *cast* votes for simplicity or a hardcoded target.
        // Let's use `_shardIds.current()` as a very rough proxy for potential voting power.
        // We'll require a certain percentage of the *total possible voting power* (rough estimate) to have voted.
        // This is a simplification; a full DAO would snapshot total voting power.
        // Assuming ~100 purity and level 1 for _shardIds.current() shards, roughly 110 power per shard.
        uint256 estimatedMaxVotingPower = _shardIds.current().mul(110);
        require(totalVotes.mul(100) >= estimatedMaxVotingPower.mul(MUTATION_QUORUM_PERCENTAGE).div(100), "GenesisShard: Quorum not met");


        // Threshold check: Percentage of 'for' votes
        require(proposal.forVotes.mul(100) >= totalVotes.mul(MUTATION_THRESHOLD_PERCENTAGE).div(100), "GenesisShard: Proposal did not meet vote threshold");

        // Execute the mutation
        _applyParameterMutation(proposal.parameterHash, proposal.newValue);
        proposal.executed = true;
        emit MutationExecuted(mutationId, proposal.parameterHash, proposal.newValue);
    }

    /**
     * @dev Internal function to apply the parameter change from a successful mutation.
     * @param parameterHash The hash of the parameter name.
     * @param newValue The new value to set.
     */
    function _applyParameterMutation(bytes32 parameterHash, uint256 newValue) internal {
        if (parameterHash == keccak256("MINT_FEE")) {
            MINT_FEE = newValue;
        } else if (parameterHash == keccak256("SHARD_MERGE_COST")) {
            SHARD_MERGE_COST = newValue;
        } else if (parameterHash == keccak256("RESONANCE_BOOST_COST")) {
            RESONANCE_BOOST_COST = newValue;
        } else if (parameterHash == keccak256("AFFINITY_CHANGE_COST")) {
            AFFINITY_CHANGE_COST = newValue;
        } else if (parameterHash == keccak256("AURA_STAKING_MULTIPLIER")) {
            AURA_STAKING_MULTIPLIER = newValue;
        } else if (parameterHash == keccak256("PURITY_DECAY_RATE")) {
            PURITY_DECAY_RATE = newValue;
        } else if (parameterHash == keccak256("MIN_PURITY_FOR_EVOLUTION")) {
            MIN_PURITY_FOR_EVOLUTION = newValue;
        } else if (parameterHash == keccak256("EVOLUTION_INTERVAL")) {
            EVOLUTION_INTERVAL = newValue;
        } else if (parameterHash == keccak256("BASE_AURA_REWARD_RATE")) {
            BASE_AURA_REWARD_RATE = newValue;
        } else if (parameterHash == keccak256("EVOLUTION_PROCESSING_REWARD")) {
            EVOLUTION_PROCESSING_REWARD = newValue;
        } else if (parameterHash == keccak256("MIN_VOTING_POWER_TO_PROPOSE")) {
            MIN_VOTING_POWER_TO_PROPOSE = newValue;
        } else if (parameterHash == keccak256("MUTATION_VOTING_PERIOD")) {
            MUTATION_VOTING_PERIOD = newValue;
        } else if (parameterHash == keccak256("MUTATION_QUORUM_PERCENTAGE")) {
            MUTATION_QUORUM_PERCENTAGE = newValue;
        } else if (parameterHash == keccak256("MUTATION_THRESHOLD_PERCENTAGE")) {
            MUTATION_THRESHOLD_PERCENTAGE = newValue;
        } else {
            revert("GenesisShard: Unknown parameter for mutation");
        }
    }

    /**
     * @dev Retrieves the current status, votes, and details of a specific mutation proposal.
     * @param mutationId The ID of the mutation proposal.
     * @return tuple (parameterHash, newValue, description, startTime, forVotes, againstVotes, executed, votingPeriodEnded, quorumMet, thresholdMet)
     */
    function getMutationStatus(uint256 mutationId) public view returns (
        bytes32 parameterHash,
        uint256 newValue,
        string memory description,
        uint256 startTime,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed,
        bool votingPeriodEnded,
        bool quorumMet,
        bool thresholdMet
    ) {
        MutationProposal storage proposal = mutationProposals[mutationId];
        require(proposal.startTime != 0, "GenesisShard: Proposal does not exist");

        parameterHash = proposal.parameterHash;
        newValue = proposal.newValue;
        description = proposal.description;
        startTime = proposal.startTime;
        forVotes = proposal.forVotes;
        againstVotes = proposal.againstVotes;
        executed = proposal.executed;
        votingPeriodEnded = block.timestamp >= proposal.startTime.add(MUTATION_VOTING_PERIOD);

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        uint256 estimatedMaxVotingPower = _shardIds.current().mul(110); // Rough proxy
        quorumMet = totalVotes.mul(100) >= estimatedMaxVotingPower.mul(MUTATION_QUORUM_PERCENTAGE).div(100);
        thresholdMet = (totalVotes > 0 && proposal.forVotes.mul(100) >= totalVotes.mul(MUTATION_THRESHOLD_PERCENTAGE).div(100));
    }

    // --- V. Administrative & Utility Functions ---

    /**
     * @dev Pauses certain critical functions of the contract. Restricted to PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract functions. Restricted to PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Grants a specified role to an account.
     * @param role The role to grant (e.g., ADMIN_ROLE, PAUSER_ROLE).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override {
        // Ensure only DEFAULT_ADMIN_ROLE can grant ADMIN_ROLE
        if (role == ADMIN_ROLE) {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AccessControl: sender must be an admin to grant ADMIN_ROLE");
        } else {
            // For other roles, use the default AccessControl behavior
            require(hasRole(getRoleAdmin(role), msg.sender), "AccessControl: sender must be an admin to grant this role");
        }
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a specified role from an account.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override {
        // Similar check for revoking roles.
        if (role == ADMIN_ROLE) {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AccessControl: sender must be an admin to revoke ADMIN_ROLE");
        } else {
            require(hasRole(getRoleAdmin(role), msg.sender), "AccessControl: sender must be an admin to revoke this role");
        }
        _revokeRole(role, account);
    }

    /**
     * @dev Allows an account to voluntarily renounce a role it possesses.
     * @param role The role to renounce.
     */
    function renounceRole(bytes32 role) public override {
        super.renounceRole(role);
    }

    /**
     * @dev Allows the ADMIN_ROLE to withdraw accidentally sent tokens (ERC-20) or ETH from the contract.
     * @param tokenAddress The address of the token to withdraw (use address(0) for ETH).
     * @param recipient The address to send the funds to.
     */
    function withdrawExcessFunds(address tokenAddress, address recipient) external onlyRole(ADMIN_ROLE) {
        require(recipient != address(0), "GenesisShard: Recipient cannot be zero address");

        if (tokenAddress == address(0)) {
            // Withdraw ETH
            uint256 ethBalance = address(this).balance;
            require(ethBalance > 0, "GenesisShard: No ETH to withdraw");
            payable(recipient).transfer(ethBalance);
        } else {
            // Withdraw ERC-20 tokens
            IERC20 excessToken = IERC20(tokenAddress);
            uint256 tokenBalance = excessToken.balanceOf(address(this));
            require(tokenBalance > 0, "GenesisShard: No tokens to withdraw");
            require(excessToken.transfer(recipient, tokenBalance), "GenesisShard: Token transfer failed");
        }
    }
}

// Minimal Base64 library for on-chain metadata (not for production, complex URIs should be off-chain)
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length required
        uint256 len = data.length;
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // allocate output buffer large enough for the encoded data
        bytes memory buffer = new bytes(encodedLen);

        uint256 i;
        uint256 j = 0;
        for (i = 0; i < len; i += 3) {
            uint256 b1 = data[i];
            uint256 b2 = i + 1 < len ? data[i + 1] : 0;
            uint256 b3 = i + 2 < len ? data[i + 2] : 0;

            uint256 enc1 = b1 >> 2;
            uint256 enc2 = ((b1 & 0x03) << 4) | (b2 >> 4);
            uint256 enc3 = ((b2 & 0x0F) << 2) | (b3 >> 6);
            uint256 enc4 = b3 & 0x3F;

            buffer[j] = bytes1(table[enc1]);
            buffer[j + 1] = bytes1(table[enc2]);
            buffer[j + 2] = bytes1(i + 1 < len ? table[enc3] : "=");
            buffer[j + 3] = bytes1(i + 2 < len ? table[enc4] : "=");

            j += 4;
        }

        return string(buffer);
    }
}
```