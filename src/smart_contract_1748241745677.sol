Okay, here is a smart contract concept called "Digital Dimension Shards". It combines elements of NFTs, dynamic traits, staking/farming with varied outcomes, resource burning for upgrades, merging mechanics, and integrated governance, all within a single contract context. The idea is that the NFTs (Shards) are pieces of a larger, evolving digital dimension, and holders interact with the dimension through these Shards.

This contract is designed to be complex and illustrative of various concepts. *Note: This is a conceptual contract for educational purposes. Production code would require extensive audits, gas optimizations, robust error handling, and secure randomness sources (like Chainlink VRF).*

---

**Outline and Function Summary**

**Contract Name:** `DigitalDimensionShards`

**Core Concepts:**
1.  **ERC721 Shards:** Non-fungible tokens representing unique "Dimension Shards".
2.  **Dynamic Traits:** Shards possess on-chain traits that can change or evolve.
3.  **ERC20 Essence:** A fungible utility/governance token ("Dimension Essence") earned by interacting with Shards.
4.  **Refining:** Burning Essence to upgrade Shard traits.
5.  **Merging:** Burning multiple Shards to create a new, potentially more powerful Shard.
6.  **Exploration Staking:** Staking Shards for variable durations and outcomes (Essence, new Shards, trait changes, events).
7.  **Governance:** Holders of Essence can propose and vote on parameters affecting the Digital Dimension.
8.  **On-Chain Generative Elements:** Traits are partially generated on-chain during minting/merging.
9.  **Time-Based Mechanics:** Staking durations, cool-downs, time-sensitive events.

**Function Categories & Summaries:**

*   **ERC721 Standard (Implicit/Interface):** Core NFT operations (transfer, ownership, approval).
    *   `transferFrom(address from, address to, uint251 tokenId)`: Transfer a Shard.
    *   `ownerOf(uint251 tokenId)`: Get owner of a Shard.
    *   `balanceOf(address owner)`: Get number of Shards owned by address.
    *   `approve(address to, uint251 tokenId)`: Approve an address to transfer a Shard.
    *   `getApproved(uint251 tokenId)`: Get approved address for a Shard.
    *   `setApprovalForAll(address operator, bool approved)`: Set approval for all Shards.
    *   `isApprovedForAll(address owner, address operator)`: Check approval for all Shards.
    *   `totalSupply()`: Get total number of Shards minted.
*   **ERC20 Standard (Implicit/Interface):** Core Essence token operations.
    *   `transfer(address to, uint256 amount)`: Transfer Essence.
    *   `transferFrom(address from, address to, uint256 amount)`: Transfer Essence via allowance.
    *   `balanceOf(address account)`: Get Essence balance.
    *   `approve(address spender, uint256 amount)`: Approve spender for Essence.
    *   `allowance(address owner, address spender)`: Get allowance for spender.
    *   `totalSupply()`: Get total Essence supply.
*   **Shard Management & Dynamics:**
    *   `mintShard(address recipient)`: Mints a new Shard with initial generated traits.
    *   `getShardTraits(uint251 shardId)`: View function to retrieve a Shard's current traits.
    *   `refineShard(uint251 shardId, TraitType traitType, uint256 essenceAmount)`: Burns Essence to upgrade a specific trait of a Shard.
    *   `mergeShards(uint251[] memory shardIds)`: Burns input Shards to create a new Shard with traits derived from inputs.
    *   `updateDynamicModifier(uint251 shardId)`: Internal/triggered function to recalculate a Shard's dynamic modifier based on current state (e.g., global parameters, time since last action).
*   **Staking & Exploration:**
    *   `stakeShard(uint251 shardId, ExplorationType explorationType)`: Locks a Shard for a specific exploration type.
    *   `unstakeShard(uint251 shardId)`: Unlocks a staked Shard and resolves basic staking rewards.
    *   `claimEssence(uint251 shardId)`: Claims accrued Essence rewards from basic staking without unstaking.
    *   `getPendingEssence(uint251 shardId)`: View function to calculate pending basic staking rewards.
    *   `completeExploration(uint251 shardId)`: Finalizes an exploration staking period, potentially triggering random events and distributing rewards/new Shards based on exploration type.
    *   `getExplorationStatus(uint251 shardId)`: View function for current staking/exploration details.
*   **Governance (Essence-Based):**
    *   `proposeParameterChange(string memory description, address target, bytes memory calldata)`: Create a new governance proposal (requires staking/burning Essence).
    *   `voteOnProposal(uint256 proposalId, VoteType vote)`: Cast a vote on an active proposal (Essence balance at snapshot block determines weight).
    *   `executeProposal(uint256 proposalId)`: Execute a proposal if it has passed and is within its execution window.
    *   `getProposalState(uint256 proposalId)`: View function for a proposal's current state (Pending, Active, Succeeded, etc.).
*   **Dimension State & Events:**
    *   `updateGlobalDimensionState(bytes data)`: Potentially triggered by governance or time, updates global parameters affecting Shards. (Example concept, implementation simplified).
    *   `triggerDimensionEvent(bytes eventData)`: Potentially triggered by governance or exploration, introduces a temporary or permanent event affecting the dimension/shards. (Example concept, implementation simplified).
*   **Admin & Configuration:**
    *   `setRandomnessSource(address _randomnessSource)`: Set the address of a secure randomness oracle (e.g., Chainlink VRF Coordinator).
    *   `withdrawAdminFees(address recipient)`: Withdraw collected platform fees (if any).
    *   `pause()`: Pause core interactions (minting, staking, refining, merging).
    *   `unpause()`: Unpause core interactions.
    *   `setGeometryRules(bytes data)`: Set parameters influencing trait generation during minting/merging (governance/admin function). (Example concept, implementation simplified).

**Total Functions (Including standard ERCs handled implicitly):** 8 (ERC721) + 8 (ERC20) + 5 (Shard Mgmt) + 6 (Staking) + 4 (Governance) + 2 (Dimension State) + 5 (Admin) = **38 Functions** (Well over 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Using interfaces for ERC721 and ERC20 to demonstrate compliance
// and allow custom implementation logic instead of direct inheritance
// of standard OpenZeppelin implementations.

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint251 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint251 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint251 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint251 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint251 tokenId) external;
    function transferFrom(address from, address to, uint251 tokenId) external;
    function approve(address to, uint251 tokenId) external;
    function getApproved(uint251 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint251);
    function tokenByIndex(uint256 index) external view returns (uint251);
}

interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint251 tokenId) external view returns (string memory);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// Placeholder for a secure randomness source interface (e.g., Chainlink VRF)
interface IRandomnessSource {
    function requestRandomness(bytes32 key) external returns (bytes32 requestId);
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

contract DigitalDimensionShards is IERC721, IERC721Enumerable, IERC721Metadata, IERC20 {
    // --- State Variables: ERC721 ---
    string public name;
    string public symbol;
    uint251 private _currentTokenId;
    mapping(uint251 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint251 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint251[] _ownedTokens; // Simple enumerable implementation
    mapping(uint251 => uint256) private _ownedTokensIndex; // For fast removal

    // --- State Variables: ERC20 (Dimension Essence) ---
    string public constant essenceName = "Dimension Essence";
    string public constant essenceSymbol = "DIM";
    uint256 private _essenceTotalSupply;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    // --- State Variables: Shard Dynamics & Staking ---
    enum TraitType { NONE, Resonance, Texture, Geometry, Color, Rarity, Stability }
    enum ExplorationType { Passive, DeepScan, EventHorizon }
    enum ExplorationState { None, Exploring, Completed }

    struct ShardTraits {
        mapping(TraitType => uint256) values; // Base value for each trait
        mapping(TraitType => uint256) levels; // Upgrade level for each trait
        mapping(TraitType => uint64) lastRefinedTimestamp; // Timestamp of last trait refinement
        uint256 dynamicModifier; // Modifier calculated based on various factors
        uint64 lastStateUpdateTime; // Timestamp of last dynamic modifier update
    }

    struct StakingInfo {
        uint251 shardId;
        address staker;
        uint64 startTime;
        ExplorationType explorationType;
        ExplorationState state;
        uint64 lastEssenceClaimTime; // For passive essence gain
        uint256 boostMultiplier; // Potential boost from traits/events
        uint256 explorationDuration; // Duration set for exploration types
        bytes32 randomnessRequestId; // Request ID for exploration outcomes
    }

    mapping(uint251 => ShardTraits) public shardData;
    mapping(uint251 => StakingInfo) private _stakedShards; // 0-initialized means not staked

    uint256 public essencePerSecondPerStake = 1 ether / (365 days) / 24 / 60 / 60 * 100; // Example: 100 DIM per year per shard basic stake
    uint256 public constant MERGE_ESSENCE_COST = 500 ether; // Example cost to merge
    uint256 public constant REFINE_ESSENCE_COST_PER_LEVEL = 10 ether; // Example cost per trait level

    // --- State Variables: Governance ---
    enum ProposalState { Pending, Active, Succeeded, Defeated, Expired, Executed }
    enum VoteType { Against, For, Abstain }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target;
        bytes calldata;
        uint64 voteStartTime;
        uint64 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        uint256 snapshotBlock; // Essence balance snapshot for voting weight
        ProposalState state;
    }

    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voter => voted
    uint256 public constant MIN_ESSENCE_FOR_PROPOSAL = 1000 ether; // Example
    uint256 public constant QUORUM_PERCENTAGE = 4; // Example: 4% of snapshot total essence must vote 'For' to pass
    uint256 public constant VOTING_PERIOD_SECONDS = 3 days; // Example

    // --- State Variables: Dimension State & Events ---
    mapping(string => uint256) public globalDimensionParameters; // Example: "ResonanceBoost", "MergeSuccessRate"
    uint64 public lastDimensionEventTime;

    // --- State Variables: Admin ---
    address private _owner;
    bool public paused = false;
    address public randomnessSource;

    // --- Events ---
    event ShardMinted(address indexed owner, uint251 indexed tokenId, ShardTraits initialTraits);
    event ShardTransferred(address indexed from, address indexed to, uint224 indexed tokenId); // Use uint224 for tokenId in events to save gas if needed
    event ShardBurned(uint251 indexed tokenId);
    event TraitRefined(uint251 indexed shardId, TraitType indexed traitType, uint256 newLevel);
    event ShardsMerged(uint251[] indexed burnedShardIds, uint251 indexed newShardId);
    event ShardStaked(uint251 indexed shardId, address indexed staker, ExplorationType explorationType);
    event ShardUnstaked(uint251 indexed shardId, address indexed staker);
    event EssenceClaimed(uint251 indexed shardId, address indexed staker, uint256 amount);
    event ExplorationCompleted(uint251 indexed shardId, address indexed staker, ExplorationType explorationType, bytes outcomeData); // outcomeData could encode results
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, VoteType vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event GlobalDimensionStateUpdated(bytes indexed updateData); // Simplified
    event DimensionEventTriggered(bytes indexed eventData); // Simplified
    event RandomnessRequested(bytes32 indexed requestId, bytes32 indexed key);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 randomness);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier shardExists(uint251 shardId) {
        require(_owners[shardId] != address(0), "Shard does not exist");
        _;
    }

    modifier isOwnerOf(uint251 shardId) {
        require(_owners[shardId] == msg.sender, "Not owner of shard");
        _;
    }

    modifier notStaked(uint251 shardId) {
        require(_stakedShards[shardId].state == ExplorationState.None, "Shard is staked");
        _;
    }

    modifier isStaked(uint251 shardId) {
        require(_stakedShards[shardId].state != ExplorationState.None, "Shard not staked");
        _;
    }

    modifier enoughEssence(uint256 amount) {
        require(_essenceBalances[msg.sender] >= amount, "Not enough essence");
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, address _initialOwner) {
        name = _name;
        symbol = _symbol;
        _owner = _initialOwner;
        _currentTokenId = 0;
        _nextProposalId = 0;
        // Set some initial parameters
        globalDimensionParameters["BaseEssenceRate"] = essencePerSecondPerStake;
        globalDimensionParameters["MergeEssenceCost"] = MERGE_ESSENCE_COST;
    }

    // --- ERC721 Implementations ---
    // (Simplified implementations - a full ERC721 would be more complex with enumeration)
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint251 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint251 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint251 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve for all to operator query");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint251 tokenId) public override whenNotPaused shardExists(tokenId) {
         // Check if sender is owner or approved
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint251 tokenId) public override {
         safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint251 tokenId, bytes calldata data) public override whenNotPaused shardExists(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);

        // Check if recipient is a smart contract and supports the IERC721Receiver interface
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // Internal transfer logic
    function _transfer(address from, address to, uint251 tokenId) internal {
        // Clear approvals
        delete _tokenApprovals[tokenId];

        // Update balances and ownership
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // Update enumerable mappings
        _removeTokenFromOwnedList(from, tokenId);
        _addTokenToOwnedList(to, tokenId);

        emit ShardTransferred(from, to, uint224(tokenId));
    }

    // ERC721 Enumeration (Simplified)
     function totalSupply() public view override returns (uint256) {
        return _currentTokenId; // Assuming tokenIds are sequential from 1
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint251) {
         require(index < _ownedTokens[owner].length, "ERC721Enumerable: owner index out of bounds");
         return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view override returns (uint251) {
         require(index < _currentTokenId, "ERC721Enumerable: global index out of bounds");
         // This simple implementation assumes sequential minting from 1.
         // A more robust implementation would iterate or use a more complex mapping.
         // For this example, we'll assume tokenIds are 1 to _currentTokenId.
         // This function as implemented is *not* correct for non-sequential IDs or burns.
         // A proper implementation would require an array of all tokenIds.
         // Skipping a complex implementation for brevity. Returning a placeholder.
         revert("ERC721Enumerable: tokenByIndex not fully implemented for arbitrary IDs");
         // A correct implementation would likely track ALL token IDs in an array.
         // return _allTokens[index];
    }


    // Internal helper for ERC721 transfers
    function _isApprovedOrOwner(address spender, uint251 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     // Internal helper to check ERC721Receiver
    function _checkOnERC721Received(address from, address to, uint251 tokenId, bytes calldata data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                 if (reason.length > 0) {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                } else {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
            }
        } else {
            return true; // EOA recipient
        }
    }

    // Minimal Enumerable helpers (basic, assumes no burns for easy index updates)
    function _addTokenToOwnedList(address to, uint251 tokenId) internal {
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;
    }

     function _removeTokenFromOwnedList(address from, uint251 tokenId) internal {
        uint256 lastIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // Move the last token to the position of the token to delete
        uint251 lastTokenId = _ownedTokens[from][lastIndex];
        _ownedTokens[from][tokenIndex] = lastTokenId;
        _ownedTokensIndex[lastTokenId] = tokenIndex;

        // Remove the last token
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId]; // Important: clear the index for the removed token
    }


    // Interface for ERC721Receiver - required for safeTransferFrom to contracts
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint251 tokenId, bytes calldata data) external returns (bytes4);
    }

    // --- ERC20 (Dimension Essence) Implementations ---
    function totalSupply() public view override returns (uint256) {
        return _essenceTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _essenceBalances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transferEssence(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _essenceAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approveEssence(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _essenceAllowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approveEssence(from, msg.sender, currentAllowance - amount);
        }
        _transferEssence(from, to, amount);
        return true;
    }

    function _transferEssence(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_essenceBalances[from] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _essenceBalances[from] -= amount;
            _essenceBalances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _essenceTotalSupply += amount;
        _essenceBalances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

     function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_essenceBalances[account] >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _essenceBalances[account] -= amount;
        }
        _essenceTotalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }


    function _approveEssence(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _essenceAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Shard Management & Dynamics ---

    /**
     * @dev Mints a new Shard with initial generated traits.
     * @param recipient The address to receive the new Shard.
     */
    function mintShard(address recipient) public whenNotPaused returns (uint251 tokenId) {
        require(recipient != address(0), "Mint to zero address");

        tokenId = ++_currentTokenId; // Assuming sequential ID generation

        // Generate initial traits (simplified - needs robust randomness)
        ShardTraits storage newShardTraits = shardData[tokenId];
        bytes32 randomnessSeed = blockhash(block.number - 1); // Insecure randomness for example
        if (address(randomnessSource) != address(0)) {
            // Ideally request from a secure source
            bytes32 requestId = IRandomnessSource(randomnessSource).requestRandomness(bytes32(tokenId)); // Use tokenId as key
             emit RandomnessRequested(requestId, bytes32(tokenId));
             // Note: Cannot use randomness immediately. This would be part of a fulfillment callback.
             // For this example, we'll use blockhash but acknowledge the insecurity.
             randomnessSeed = keccak256(abi.encodePacked(randomnessSeed, block.timestamp));
        } else {
             randomnessSeed = keccak256(abi.encodePacked(randomnessSeed, block.timestamp));
        }


        // Example trait generation logic (simplified)
        newShardTraits.values[TraitType.Resonance] = uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Resonance))) % 100 + 1; // 1-100
        newShardTraits.values[TraitType.Texture] = uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Texture))) % 10 + 1; // 1-10
        newShardTraits.values[TraitType.Geometry] = uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Geometry))) % 5 + 1; // 1-5
        newShardTraits.values[TraitType.Color] = uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Color))); // Hex color or ID
        newShardTraits.values[TraitType.Rarity] = uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Rarity))) % 1000; // 0-999, higher is rarer?
        newShardTraits.values[TraitType.Stability] = uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Stability))) % 50 + 1; // 1-50

        // Initialize levels and timestamps
        newShardTraits.levels[TraitType.Resonance] = 1;
        newShardTraits.levels[TraitType.Texture] = 1;
        newShardTraits.levels[TraitType.Geometry] = 1;
        newShardTraits.levels[TraitType.Color] = 1;
        newShardTraits.levels[TraitType.Rarity] = 1;
        newShardTraits.levels[TraitType.Stability] = 1;

        uint64 currentTime = uint64(block.timestamp);
        newShardTraits.lastStateUpdateTime = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Resonance] = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Texture] = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Geometry] = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Color] = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Rarity] = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Stability] = currentTime;


        _owners[tokenId] = recipient;
        _balances[recipient]++;
        _addTokenToOwnedList(recipient, tokenId); // For enumerable
        emit Transfer(address(0), recipient, tokenId); // ERC721 Mint event
        emit ShardMinted(recipient, tokenId, newShardTraits);

        // Consider implementing _safeMint for contract recipients
    }

    /**
     * @dev View function to retrieve a Shard's current traits.
     * @param shardId The ID of the Shard.
     * @return A struct containing the Shard's traits.
     */
    function getShardTraits(uint251 shardId) public view shardExists(shardId) returns (ShardTraits memory) {
         ShardTraits storage traits = shardData[shardId];
         // We need to return a memory copy of the mapping values
         ShardTraits memory result;
         result.values[TraitType.Resonance] = traits.values[TraitType.Resonance];
         result.values[TraitType.Texture] = traits.values[TraitType.Texture];
         result.values[TraitType.Geometry] = traits.values[TraitType.Geometry];
         result.values[TraitType.Color] = traits.values[TraitType.Color];
         result.values[TraitType.Rarity] = traits.values[TraitType.Rarity];
         result.values[TraitType.Stability] = traits.values[TraitType.Stability];

         result.levels[TraitType.Resonance] = traits.levels[TraitType.Resonance];
         result.levels[TraitType.Texture] = traits.levels[TraitType.Texture];
         result.levels[TraitType.Geometry] = traits.levels[TraitType.Geometry];
         result.levels[TraitType.Color] = traits.levels[TraitType.Color];
         result.levels[TraitType.Rarity] = traits.levels[TraitType.Rarity];
         result.levels[TraitType.Stability] = traits.levels[TraitType.Stability];

         result.lastRefinedTimestamp[TraitType.Resonance] = traits.lastRefinedTimestamp[TraitType.Resonance];
         result.lastRefinedTimestamp[TraitType.Texture] = traits.lastRefinedTimestamp[TraitType.Texture];
         result.lastRefinedTimestamp[TraitType.Geometry] = traits.lastRefinedTimestamp[TraitType.Geometry];
         result.lastRefinedTimestamp[TraitType.Color] = traits.lastRefinedTimestamp[TraitType.Color];
         result.lastRefinedTimestamp[TraitType.Rarity] = traits.lastRefinedTimestamp[TraitType.Rarity];
         result.lastRefinedTimestamp[TraitType.Stability] = traits.lastRefinedTimestamp[TraitType.Stability];

         result.dynamicModifier = traits.dynamicModifier;
         result.lastStateUpdateTime = traits.lastStateUpdateTime;

         return result;
    }

    /**
     * @dev Burns Essence to upgrade a specific trait of a Shard.
     * @param shardId The ID of the Shard.
     * @param traitType The type of trait to refine.
     * @param essenceAmount The amount of Essence to burn.
     */
    function refineShard(uint251 shardId, TraitType traitType, uint256 essenceAmount)
        public
        whenNotPaused
        isOwnerOf(shardId)
        notStaked(shardId)
        enoughEssence(essenceAmount)
        shardExists(shardId)
    {
        require(traitType != TraitType.NONE, "Cannot refine NONE trait type");
        // Calculate potential level increase based on essenceAmount and cost
        uint256 levelsToIncrease = essenceAmount / REFINE_ESSENCE_COST_PER_LEVEL;
        require(levelsToIncrease > 0, "Insufficient essence to gain a level");

        ShardTraits storage traits = shardData[shardId];
        uint256 oldLevel = traits.levels[traitType];
        traits.levels[traitType] += levelsToIncrease;
        traits.lastRefinedTimestamp[traitType] = uint64(block.timestamp);

        _burnEssence(msg.sender, levelsToIncrease * REFINE_ESSENCE_COST_PER_LEVEL); // Burn the exact amount for levels gained

        // Trait value might increase based on level, or dynamic modifier updates later
        // traits.values[traitType] = calculateNewTraitValue(traits.values[traitType], traits.levels[traitType]);

        // Recalculate dynamic modifier if trait level affects it immediately
        updateDynamicModifier(shardId); // Internal call

        emit TraitRefined(shardId, traitType, traits.levels[traitType]);
    }

    /**
     * @dev Burns multiple input Shards to create a new Shard with derived traits.
     * @param shardIds An array of Shard IDs to merge.
     */
    function mergeShards(uint251[] memory shardIds)
        public
        whenNotPaused
        enoughEssence(MERGE_ESSENCE_COST)
    {
        require(shardIds.length >= 2, "Need at least two shards to merge");
        require(shardIds.length <= 5, "Max 5 shards per merge"); // Example limit

        address owner = msg.sender;
        // Check ownership and staking status for all shards
        for (uint256 i = 0; i < shardIds.length; i++) {
            require(ownerOf(shardIds[i]) == owner, "Not owner of all shards");
            require(_stakedShards[shardIds[i]].state == ExplorationState.None, "One or more shards are staked");
        }

        _burnEssence(owner, MERGE_ESSENCE_COST);

        // Store burned IDs for event
        uint251[] memory burnedIds = new uint251[](shardIds.length);
        for (uint256 i = 0; i < shardIds.length; i++) {
            uint251 currentShardId = shardIds[i];
            burnedIds[i] = currentShardId;

            // --- Burn logic ---
            _transfer(owner, address(0), currentShardId); // Transfer to zero address
            delete shardData[currentShardId]; // Remove shard data
            // _currentTokenId is not decremented, ID is lost forever (common NFT burn)
            emit ShardBurned(currentShardId);
            // --- End Burn logic ---
        }

        // --- Mint new merged shard ---
        uint251 newShardId = ++_currentTokenId;
        ShardTraits storage newShardTraits = shardData[newShardId];

         // Example trait derivation (simplified - could be weighted average, max, or new generation)
         bytes32 randomnessSeed = blockhash(block.number - 1); // Insecure
          if (address(randomnessSource) != address(0)) {
            // Ideally request from a secure source
            bytes32 requestId = IRandomnessSource(randomnessSource).requestRandomness(bytes32(newShardId));
            emit RandomnessRequested(requestId, bytes32(newShardId));
             // Note: Cannot use randomness immediately.
             randomnessSeed = keccak256(abi.encodePacked(randomnessSeed, block.timestamp));
        } else {
             randomnessSeed = keccak256(abi.encodePacked(randomnessSeed, block.timestamp));
        }


        for (uint256 i = 0; i < shardIds.length; i++) {
            // Accessing old shard data *after* deleting it is impossible.
            // Need to load traits *before* burning.
            // Simplified: let's re-generate based on input count and randomness
             uint252 inputCount = uint252(shardIds.length); // Use uint252 to avoid overflow
             newShardTraits.values[TraitType.Resonance] = (uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Resonance))) % (100 * inputCount) + 1) + 1; // Higher potential max
             newShardTraits.levels[TraitType.Resonance] = (uint256(keccak256(abi.encodePacked(randomnessSeed, TraitType.Resonance, "level"))) % inputCount) + 1; // Level starts based on merge count
             // ... repeat for other traits
             // This derivation logic is a placeholder. A real implementation would need careful design.
        }

         uint64 currentTime = uint64(block.timestamp);
        newShardTraits.lastStateUpdateTime = currentTime;
         newShardTraits.lastRefinedTimestamp[TraitType.Resonance] = currentTime; // Initialize timestamps for new shard
         // ... initialize others

        _owners[newShardId] = owner;
        _balances[owner]++;
         _addTokenToOwnedList(owner, newShardId); // For enumerable

        emit Transfer(address(0), owner, newShardId); // ERC721 Mint event for new shard
        emit ShardMinted(owner, newShardId, newShardTraits); // Custom Mint event for new shard

        emit ShardsMerged(burnedIds, newShardId);
    }

    /**
     * @dev Internal/triggered function to recalculate a Shard's dynamic modifier.
     * @param shardId The ID of the Shard.
     */
    function updateDynamicModifier(uint251 shardId) internal shardExists(shardId) {
         // Example logic: Dynamic modifier changes based on time since last action, trait levels,
         // and global dimension parameters.
         ShardTraits storage traits = shardData[shardId];
         uint64 timeSinceLastUpdate = uint64(block.timestamp) - traits.lastStateUpdateTime;

         // Example calculation:
         uint256 baseModifier = traits.levels[TraitType.Resonance] * 100 + traits.levels[TraitType.Texture] * 50;
         uint256 timeDecay = timeSinceLastUpdate / 1 days; // Loses value over time
         uint256 globalBoost = globalDimensionParameters["ResonanceBoost"]; // Influence from global state

         traits.dynamicModifier = baseModifier + globalBoost - timeDecay;
         if (traits.dynamicModifier < 0) traits.dynamicModifier = 0; // Modifier doesn't go below zero

         traits.lastStateUpdateTime = uint64(block.timestamp);
         // No event needed for internal update, can be viewed via getShardTraits
    }

    // --- Staking & Exploration ---

    /**
     * @dev Locks a Shard for a specific exploration type.
     * @param shardId The ID of the Shard.
     * @param explorationType The type of exploration (Passive, DeepScan, EventHorizon).
     */
    function stakeShard(uint251 shardId, ExplorationType explorationType)
        public
        whenNotPaused
        isOwnerOf(shardId)
        notStaked(shardId)
        shardExists(shardId)
    {
        // Transfer shard to contract address
        _transfer(msg.sender, address(this), shardId);

        StakingInfo storage staking = _stakedShards[shardId];
        staking.shardId = shardId;
        staking.staker = msg.sender;
        staking.startTime = uint64(block.timestamp);
        staking.explorationType = explorationType;
        staking.state = ExplorationState.Exploring;
        staking.lastEssenceClaimTime = uint64(block.timestamp); // Start tracking essence from now
        staking.boostMultiplier = shardData[shardId].dynamicModifier; // Capture modifier at stake time? Or dynamic? Let's make it dynamic for complexity.
        // Set exploration duration based on type (example values)
        if (explorationType == ExplorationType.Passive) {
            staking.explorationDuration = type(uint256).max; // Effectively infinite for passive
        } else if (explorationType == ExplorationType.DeepScan) {
            staking.explorationDuration = 7 days;
        } else if (explorationType == ExplorationType.EventHorizon) {
            staking.explorationDuration = 30 days;
        } else {
             revert("Invalid exploration type");
        }


        emit ShardStaked(shardId, msg.sender, explorationType);
    }

    /**
     * @dev Unlocks a staked Shard and resolves basic staking rewards.
     * Completing Exploration types with finite duration uses completeExploration.
     * @param shardId The ID of the Shard.
     */
    function unstakeShard(uint251 shardId)
        public
        whenNotPaused
        isStaked(shardId)
    {
         StakingInfo storage staking = _stakedShards[shardId];
         require(staking.staker == msg.sender, "Not the staker of this shard");
         require(staking.explorationType == ExplorationType.Passive, "Cannot unstake finite exploration type, use completeExploration");

         // Claim pending essence before unstaking
         claimEssence(shardId);

         // Transfer shard back
         _transfer(address(this), msg.sender, shardId);

         // Clear staking info
         delete _stakedShards[shardId];

         emit ShardUnstaked(shardId, msg.sender);
    }

    /**
     * @dev Claims accrued Essence rewards from basic staking (Passive type).
     * Does not unstake the Shard.
     * @param shardId The ID of the Shard.
     */
    function claimEssence(uint251 shardId)
        public
        whenNotPaused
        isStaked(shardId)
    {
        StakingInfo storage staking = _stakedShards[shardId];
        require(staking.staker == msg.sender, "Not the staker of this shard");
        // Only allow claiming from Passive stake or Exploration that is finished
        require(staking.explorationType == ExplorationType.Passive || staking.state == ExplorationState.Completed, "Cannot claim Essence during active finite exploration");

        uint64 currentTime = uint64(block.timestamp);
        uint64 lastClaimTime = staking.lastEssenceClaimTime;
        uint256 timeElapsed = currentTime - lastClaimTime;

        if (timeElapsed == 0) return; // Nothing to claim

        // Calculate essence reward (simplified linear reward)
        // Reward is (time elapsed) * (base rate) * (dynamic modifier / 1000?) * (global boost?)
        uint256 baseRate = globalDimensionParameters["BaseEssenceRate"]; // Essence per second
        uint256 shardModifier = shardData[shardId].dynamicModifier; // Dynamic modifier influences rate

        // Example reward calculation: seconds * rate * (modifier / 1000)
        // Need to handle potential precision issues if modifier is < 1000 or very large
        // Use fixed point math or adjust units carefully
        uint256 potentialReward = (baseRate * timeElapsed * shardModifier) / 1000; // Assuming modifier 1000 is neutral

        // Ensure there's a minimum modifier effect if needed
        if (shardModifier < 100) potentialReward = (baseRate * timeElapsed * 100) / 1000; // Example minimum

        uint256 rewardAmount = potentialReward; // Basic calculation

        if (rewardAmount > 0) {
             _mintEssence(msg.sender, rewardAmount);
             staking.lastEssenceClaimTime = currentTime;
             emit EssenceClaimed(shardId, msg.sender, rewardAmount);
        }
    }

     /**
      * @dev View function to calculate pending basic staking rewards for a Shard.
      * @param shardId The ID of the Shard.
      * @return The amount of pending Essence.
      */
     function getPendingEssence(uint251 shardId) public view isStaked(shardId) returns (uint256) {
        StakingInfo storage staking = _stakedShards[shardId];
        if (staking.explorationType != ExplorationType.Passive && staking.state != ExplorationState.Completed) {
            return 0; // Cannot claim during active finite exploration
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 lastClaimTime = staking.lastEssenceClaimTime;
        uint256 timeElapsed = currentTime - lastClaimTime;

        if (timeElapsed == 0) return 0;

        uint256 baseRate = globalDimensionParameters["BaseEssenceRate"];
        uint256 shardModifier = shardData[shardId].dynamicModifier; // Use current dynamic modifier

        // Example reward calculation (must match claimEssence logic)
        uint256 potentialReward = (baseRate * timeElapsed * shardModifier) / 1000;
         if (shardModifier < 100) potentialReward = (baseRate * timeElapsed * 100) / 1000;

        return potentialReward;
     }


    /**
     * @dev Finalizes an exploration staking period (DeepScan, EventHorizon).
     * Triggers outcome determination based on randomness.
     * @param shardId The ID of the Shard.
     */
    function completeExploration(uint251 shardId)
        public
        whenNotPaused
        isStaked(shardId)
    {
        StakingInfo storage staking = _stakedShards[shardId];
        require(staking.staker == msg.sender, "Not the staker of this shard");
        require(staking.explorationType != ExplorationType.Passive, "Cannot complete Passive exploration");
        require(staking.state == ExplorationState.Exploring, "Exploration not in progress");

        uint64 currentTime = uint64(block.timestamp);
        require(currentTime >= staking.startTime + staking.explorationDuration, "Exploration duration not met");

        // --- Exploration Outcome Logic ---
        // This is where randomness is crucial.
        // Ideally, this function would *request* randomness and a separate callback function
        // (e.g., `fulfillRandomness` from Chainlink VRF) would handle the outcome.
        // For this example, we'll use insecure blockhash + timestamp for *illustration only*.

        bytes32 outcomeSeed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, shardId)); // INSECURE
         if (address(randomnessSource) != address(0)) {
            // In a real system, request randomness here and mark state as 'RandomnessPending'
            // The outcome logic below would be in a callback function like fulfillRandomness.
             bytes32 requestId = IRandomnessSource(randomnessSource).requestRandomness(outcomeSeed);
             emit RandomnessRequested(requestId, outcomeSeed);
             staking.randomnessRequestId = requestId;
             staking.state = ExplorationState.Completed; // Mark as completed, outcome pending randomness
             emit ExplorationCompleted(shardId, msg.sender, staking.explorationType, bytes("Randomness Pending"));
             return; // Exit here, outcome handled by callback
        } else {
             // Insecure fallback for illustration
             outcomeSeed = keccak256(abi.encodePacked(outcomeSeed, msg.sender)); // Add sender for slight variation
        }

        // --- Process Outcome (Illustrative - depends on randomness) ---
        bytes memory outcomeData; // Data to encode the outcome

        uint256 outcomeRoll = uint256(outcomeSeed) % 100; // Roll 0-99
        uint256 shardModifier = shardData[shardId].dynamicModifier; // Influence outcome probability

        if (staking.explorationType == ExplorationType.DeepScan) {
            // DeepScan outcomes: Essence, trait boost, small chance of new shard
            uint256 essenceReward = (staking.explorationDuration / 1 days) * 50 ether; // Time-based base reward
             essenceReward = (essenceReward * shardModifier) / 1000; // Modifier influence

            _mintEssence(msg.sender, essenceReward);
            outcomeData = abi.encodePacked("Essence", essenceReward);

            if (outcomeRoll < 20 + shardModifier / 100) { // 20% base chance + modifier
                // Trait boost
                TraitType boostedTrait = TraitType((uint256(keccak256(abi.encodePacked(outcomeSeed, "trait"))) % 6) + 1); // Random trait type (1-6)
                shardData[shardId].levels[boostedTrait]++;
                shardData[shardId].lastRefinedTimestamp[boostedTrait] = currentTime;
                 updateDynamicModifier(shardId);
                 outcomeData = abi.encodePacked(outcomeData, "TraitBoost", boostedTrait);
            }

            if (outcomeRoll > 95 - shardModifier / 200) { // Small chance of new shard
                 uint251 newShardId = mintShard(msg.sender); // Mint a new shard directly to user
                 outcomeData = abi.encodePacked(outcomeData, "NewShard", newShardId);
            }

        } else if (staking.explorationType == ExplorationType.EventHorizon) {
             // EventHorizon outcomes: Higher Essence, significant trait changes, chance of global event
            uint256 essenceReward = (staking.explorationDuration / 1 days) * 200 ether;
             essenceReward = (essenceReward * shardModifier) / 800;
            _mintEssence(msg.sender, essenceReward);
             outcomeData = abi.encodePacked("Essence", essenceReward);

            if (outcomeRoll < 50 + shardModifier / 50) { // Higher chance of trait changes
                 // Significant trait changes (e.g., re-roll some trait values/levels)
                 // ... complex logic based on outcomeSeed ...
                 outcomeData = abi.encodePacked(outcomeData, "TraitReshuffle");
                 // Re-generate some traits based on outcomeSeed and current levels?
                 // shardData[shardId].values[TraitType.Resonance] = ...;
                 // shardData[shardId].levels[TraitType.Geometry] = ...;
                 updateDynamicModifier(shardId);
            }

            if (outcomeRoll > 80 - shardModifier / 100) { // Chance of triggering a global event
                 bytes memory eventData = abi.encodePacked("EventHorizonFlux", uint256(keccak256(outcomeSeed)));
                 triggerDimensionEvent(eventData); // Admin/Governance function, called by protocol logic here
                 outcomeData = abi.encodePacked(outcomeData, "GlobalEvent");
            }

        }
        // --- End Outcome Logic ---

        // Claim any remaining basic essence from the passive part of staking duration
        claimEssence(shardId); // Claims up to completion time

        // Transfer shard back
        _transfer(address(this), msg.sender, shardId);

        // Clear staking info
        delete _stakedShards[shardId];

        staking.state = ExplorationState.Completed; // Set state explicitly if not using randomness callback

        emit ExplorationCompleted(shardId, msg.sender, staking.explorationType, outcomeData);
    }

    /**
     * @dev View function for current staking/exploration details of a Shard.
     * @param shardId The ID of the Shard.
     * @return A struct containing the staking info.
     */
     function getExplorationStatus(uint251 shardId) public view returns (StakingInfo memory) {
         return _stakedShards[shardId]; // Returns zeroed struct if not staked
     }

    // --- Governance (Essence-Based) ---

    /**
     * @dev Create a new governance proposal. Requires minimum Essence stake/burn.
     * @param description Short description of the proposal.
     * @param target The address of the contract to call (usually this contract).
     * @param calldata The encoded function call data (function signature + arguments).
     */
    function proposeParameterChange(string memory description, address target, bytes memory calldata)
        public
        whenNotPaused
        enoughEssence(MIN_ESSENCE_FOR_PROPOSAL)
    {
        // Burn/Lock essence for proposal cost
        _burnEssence(msg.sender, MIN_ESSENCE_FOR_PROPOSAL); // Example: burn the cost

        uint256 proposalId = _nextProposalId++;
        uint64 currentTime = uint64(block.timestamp);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            target: target,
            calldata: calldata,
            voteStartTime: currentTime,
            voteEndTime: currentTime + VOTING_PERIOD_SECONDS,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            snapshotBlock: block.number - 1, // Snapshot essence balance at the block before proposal
            state: ProposalState.Active
        });

        // Snapshot total essence supply at the snapshot block (for quorum calculation later)
        // Requires reading historical state, which is not directly possible like this.
        // A proper governance contract tracks historical token balances or uses a delegate pattern
        // like OpenZeppelin Governor + ERC20Votes.
        // For this example, we'll *assume* we can get historical balances or rely on a simpler quorum check.
        // A true implementation needs a mechanism for vote weight based on historical balances.

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Cast a vote on an active proposal.
     * Vote weight based on Essence balance at the proposal's snapshot block.
     * @param proposalId The ID of the proposal.
     * @param vote The vote choice (For, Against, Abstain).
     */
    function voteOnProposal(uint256 proposalId, VoteType vote)
        public
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp >= proposal.voteStartTime, "Voting period has not started");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!_hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        // Get voter's essence balance at the snapshot block
        // *** IMPORTANT *** This is a placeholder. Reading historical balances is complex.
        // A real implementation needs a mechanism like ERC20Votes or a custom snapshotting system.
        uint256 voteWeight = _essenceBalances[msg.sender]; // INSECURE for real governance, allows flashloan voting

        require(voteWeight > 0, "Voter must hold Essence at snapshot block"); // Simplified check

        if (vote == VoteType.For) {
            proposal.forVotes += voteWeight;
        } else if (vote == VoteType.Against) {
            proposal.againstVotes += voteWeight;
        } else if (vote == VoteType.Abstain) {
            proposal.abstainVotes += voteWeight;
        } else {
             revert("Invalid vote type");
        }

        _hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender, vote);
    }

     /**
      * @dev Internal helper (or could be public callable by anyone) to determine proposal state.
      * @param proposalId The ID of the proposal.
      * @return The current state of the proposal.
      */
     function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Succeeded || proposal.state == ProposalState.Defeated || proposal.state == ProposalState.Expired) {
             return proposal.state;
        }

        if (block.timestamp < proposal.voteStartTime) {
            return ProposalState.Pending;
        }
        if (block.timestamp <= proposal.voteEndTime) {
            return ProposalState.Active;
        }

        // Voting period has ended
        // Need total supply at snapshot block for quorum calculation
        // *** PLACEHOLDER: Assuming _essenceTotalSupply at snapshot block is needed ***
        // Requires historical lookup or external oracle/snapshot system.
        // For this example, we'll use current total supply (INACCURATE for real governance)
        uint224 totalEssenceAtSnapshot = uint224(_essenceTotalSupply); // INACCURATE

        // Calculate quorum (simplified)
        bool quorumMet = proposal.forVotes > (uint256(totalEssenceAtSnapshot) * QUORUM_PERCENTAGE) / 100;

        if (proposal.forVotes > proposal.againstVotes && quorumMet) {
            return ProposalState.Succeeded;
        } else if (block.timestamp > proposal.voteEndTime) {
             // If voting period ended but not successful, check defeat conditions
             if (proposal.againstVotes >= proposal.forVotes || !quorumMet) {
                 return ProposalState.Defeated;
             }
        }


         return ProposalState.Expired; // Default if none of the above and vote period is over
     }


    /**
     * @dev Execute a proposal if it has passed and is within its execution window.
     * Anyone can call this after the voting period ends and if the proposal passed.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId)
        public
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Succeeded || getProposalState(proposalId) == ProposalState.Succeeded, "Proposal not in succeeded state");
        require(!proposal.executed, "Proposal already executed");

        // Check execution window (e.g., can only execute for N days after vote ends)
        // require(block.timestamp <= proposal.voteEndTime + EXECUTION_WINDOW_SECONDS, "Execution window closed"); // Add EXECUTION_WINDOW_SECONDS state variable

        // Execute the proposed function call
        (bool success, ) = proposal.target.call(proposal.calldata);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
    }

    // --- Dimension State & Events ---

    /**
     * @dev Updates a global parameter for the dimension. Can be called by governance execution.
     * Simplified implementation. Actual parameter updates would be handled inside.
     * @param data Encoded data specifying the update.
     */
    function updateGlobalDimensionState(bytes data) public onlyOwner { // Or require governance execution
        // Decode `data` and update `globalDimensionParameters` or other state
        // Example: Decode `abi.encodePacked("ResonanceBoost", newValue)`
        // string memory paramName = ... decode ...
        // uint256 newValue = ... decode ...
        // globalDimensionParameters[paramName] = newValue;

        emit GlobalDimensionStateUpdated(data);
    }

    /**
     * @dev Triggers a dimension-wide event. Can be called by governance execution or Exploration.
     * Simplified implementation. Actual event effects would be handled elsewhere.
     * @param eventData Encoded data specifying the event.
     */
    function triggerDimensionEvent(bytes eventData) public onlyOwner { // Or require governance execution/exploration outcome
        // Based on `eventData`, potentially:
        // - Temporarily boost/decay certain traits for all shards
        // - Modify staking rates globally
        // - Enable/disable certain actions for a period
        // - Mint special event-related items (not in this contract's scope)

        lastDimensionEventTime = uint64(block.timestamp);
        emit DimensionEventTriggered(eventData);
    }

    // --- Admin & Configuration ---

    /**
     * @dev Sets the address of the secure randomness oracle contract (e.g., Chainlink VRF).
     * Only callable by the contract owner (or governance).
     * @param _randomnessSource The address of the randomness source contract.
     */
    function setRandomnessSource(address _randomnessSource) public onlyOwner {
        randomnessSource = _randomnessSource;
    }

    /**
     * @dev Withdraws any Ether or tokens sent directly to the contract (excluding staked shards).
     * This is a basic emergency function. A robust system might use specific fee collection mechanics.
     * @param recipient The address to send funds to.
     */
    function withdrawAdminFees(address recipient) public onlyOwner {
        // Example: withdraw any ETH sent to the contract address
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");

        // Example: withdraw any other tokens held by the contract (requires token address)
        // IERC20 someToken = IERC20(tokenAddress);
        // someToken.transfer(recipient, someToken.balanceOf(address(this)));
    }

    /**
     * @dev Pauses core contract interactions.
     * Only callable by the contract owner (or governance).
     */
    function pause() public onlyOwner {
        paused = true;
    }

    /**
     * @dev Unpauses core contract interactions.
     * Only callable by the contract owner (or governance).
     */
    function unpause() public onlyOwner {
        paused = false;
    }

    /**
     * @dev Sets parameters influencing trait generation during minting/merging.
     * Can be called by governance execution.
     * @param data Encoded data specifying geometry rules.
     */
     function setGeometryRules(bytes data) public onlyOwner { // Or require governance execution
         // Decode and update internal variables or mappings used in trait generation logic
         // Example: uint256 maxResonance = ...; uint256 minStability = ...;
         // This function is a placeholder for complex on-chain generation rules.
         emit GlobalDimensionStateUpdated(data); // Re-using event for simplicity
     }


    // --- Internal/Helper Functions ---

     // Placeholder for a more complex trait value calculation based on level, global state, etc.
    // function calculateNewTraitValue(uint256 baseValue, uint256 level) internal pure returns (uint256) {
    //     return baseValue + level * 10; // Simple example
    // }


    // Fallback/Receive functions to accept ETH
    receive() external payable {}
    fallback() external payable {}
}
```