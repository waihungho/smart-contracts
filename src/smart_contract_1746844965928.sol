Okay, here is a smart contract concept called `ChronoGenesisShards`. It's a dynamic NFT-like system combined with gamified elements, resource management, and owner-controlled parameters. It avoids inheriting from standard OpenZeppelin contracts like ERC721 or Ownable directly, implementing similar patterns manually to fit the "don't duplicate open source" constraint in terms of *inheritance*, while still using common Solidity concepts.

**Concept:** Shards are unique digital entities that can level up, gain experience points (XP), have affinities, bond with other shards, and require 'Catalysts' (an internal contract resource) to perform actions. The game progresses through 'Epochs', potentially causing decay or triggering events.

---

## Smart Contract Outline and Function Summary

**Contract Name:** `ChronoGenesisShards`

**Concept:** A dynamic NFT-like system (`Shard`) with gamified interactions, leveling, bonding, resource management (`Catalyst`), and a time-based global state (`Epoch`). It features owner-controlled parameters to tune the game mechanics.

**Core Components:**
1.  **Shards:** Unique, non-fungible entities with dynamic state (Level, XP, Affinity, etc.).
2.  **Catalysts:** A fungible resource managed within the contract, required for Shard interactions.
3.  **Epochs:** A global counter representing discrete time periods, affecting Shard states and interactions.
4.  **Owner Controls:** Functions for the contract owner to adjust game parameters, mint catalysts, bless shards, and manage the global state.

**State Variables:**
*   `_owner`: The contract owner's address.
*   `_paused`: Boolean to pause certain actions.
*   `_totalSupply`: Total number of shards minted.
*   `_tokenCounter`: Internal counter for assigning unique token IDs.
*   `_shards`: Mapping from `tokenId` to `ShardState` struct.
*   `_tokenOwners`: Mapping from `tokenId` to owner address (custom NFT ownership).
*   `_ownerTokenCount`: Mapping from owner address to number of shards owned (custom NFT balance).
*   `_ownerTokens`: Mapping from owner address to an array of `tokenId`s owned. (Note: This is potentially gas-expensive for many tokens, included for `getUserShards` functionality).
*   `_catalystBalances`: Mapping from address to catalyst balance.
*   `_currentEpoch`: The current global epoch number.
*   `_epochDuration`: Duration in seconds for each epoch (owner-set).
*   `_xpRequiredForLevel`: Mapping from level to XP needed to reach that level.
*   `_baseXPGain`: Base XP awarded for `performAction`.
*   `_actionCost`: Catalyst cost for `performAction`.
*   `_bondingCost`: Catalyst cost for `bondShards`.
*   `_decayRate`: Percentage decay per epoch of inactivity (owner-set).
*   `_blessingEndTime`: Mapping from `tokenId` to timestamp when blessing expires.
*   `_affinityTypes`: Array of valid affinity type integers.
*   `_bondingCompatibility`: Mapping `(affinity1, affinity2) => bool` indicating if they can bond.

**Structs:**
*   `ShardState`: Represents the dynamic state of a shard (`level`, `xp`, `affinity`, `creationEpoch`, `lastActiveEpoch`, `bondedToId`).

**Events:**
*   `ShardMinted`: Emitted when a new shard is created.
*   `ShardTransferred`: Emitted when shard ownership changes.
*   `ShardLevelUp`: Emitted when a shard gains a level.
*   `XPGained`: Emitted when a shard gains XP.
*   `EpochAdvanced`: Emitted when the global epoch updates.
*   `ParametersUpdated`: Emitted when owner changes game parameters.
*   `ShardBonded`: Emitted when two shards are bonded.
*   `ShardUnbonded`: Emitted when bonded shards are separated.
*   `CatalystMinted`: Emitted when catalysts are issued.
*   `CatalystConsumed`: Emitted when catalysts are spent.
*   `ShardBlessed`: Emitted when a shard receives a blessing.
*   `Paused`: Emitted when the contract is paused.
*   `Unpaused`: Emitted when the contract is unpaused.

**Functions (Minimum 20):**

1.  `constructor()`: Initializes the contract, sets owner, initial epoch, and default parameters.
2.  `onlyOwner()`: Modifier for owner-restricted functions. (Manual implementation of Ownable pattern).
3.  `paused()`: Modifier to check if the contract is paused.
4.  `_mint(address to, uint256 tokenId, uint256 affinity)`: Internal function to create a new shard.
5.  `_burn(uint256 tokenId)`: Internal function to destroy a shard.
6.  `_transfer(address from, address to, uint256 tokenId)`: Internal function to transfer shard ownership. Handles custom ownership mappings.
7.  `balanceOf(address owner)`: Returns the number of shards owned by an address (custom ERC721-like).
8.  `ownerOf(uint256 tokenId)`: Returns the owner of a shard (custom ERC721-like).
9.  `transferShard(address to, uint256 tokenId)`: External function to transfer shard ownership. Includes custom checks (e.g., not bonded).
10. `mintShard(uint256 affinity)`: Mints a new shard to the caller. Requires catalysts. Assigns initial state.
11. `getShardState(uint256 tokenId)`: Returns the full state struct of a shard.
12. `getShardLevel(uint256 tokenId)`: Returns just the level of a shard.
13. `getShardXP(uint256 tokenId)`: Returns just the XP of a shard.
14. `getAffinityType(uint256 tokenId)`: Returns just the affinity of a shard.
15. `getShardBondedTo(uint256 tokenId)`: Returns the ID of the shard a given shard is bonded to (0 if not bonded).
16. `getBlessingEndTime(uint256 tokenId)`: Returns the timestamp when a blessing expires.
17. `getLastActiveEpoch(uint256 tokenId)`: Returns the last epoch the shard was active.
18. `performAction(uint256 tokenId)`: Allows a user to interact with their shard. Consumes catalysts, awards XP, potentially triggers level-up and decay check.
19. `_awardXP(uint256 tokenId, uint256 amount)`: Internal helper to add XP and check/handle level up.
20. `_checkLevelUp(uint256 tokenId)`: Internal helper to manage level transitions.
21. `applyDecay(uint256 tokenId)`: Internal function to apply state decay based on inactivity and epoch difference.
22. `bondShards(uint256 tokenId1, uint256 tokenId2)`: Bonds two shards together if compatible and owned by caller. Consumes catalysts.
23. `unbondShards(uint256 tokenId)`: Unbonds a previously bonded shard.
24. `advanceEpoch()`: Owner-only function to manually increment the global epoch. Could trigger effects or be called by a time-based keeper.
25. `getEpoch()`: Returns the current global epoch.
26. `getCatalystBalance(address user)`: Returns a user's catalyst balance.
27. `mintCatalysts(address to, uint256 amount)`: Owner-only function to issue catalysts.
28. `blessShard(uint256 tokenId, uint256 durationSeconds)`: Owner-only function to apply a temporary blessing boost to a shard.
29. `pauseActions()`: Owner-only function to pause core user actions.
30. `unpauseActions()`: Owner-only function to unpause core user actions.
31. `setXPRequiredForLevel(uint256 level, uint256 requiredXP)`: Owner-only to set level progression requirements.
32. `setBaseXPGain(uint256 amount)`: Owner-only to set base XP gained per action.
33. `setBondingCost(uint256 cost)`: Owner-only to set catalyst cost for bonding.
34. `setDecayParameters(uint256 rate)`: Owner-only to set decay rate (percentage).
35. `setActionCost(uint256 cost)`: Owner-only to set catalyst cost for actions.
36. `getUserShards(address user)`: Returns an array of all shard IDs owned by a user. (Gas warning: expensive for large collections).
37. `getTotalSupply()`: Returns the total number of shards.
38. `canPerformAction(uint256 tokenId)`: View function to check if `performAction` prerequisites are met.
39. `canBondShards(uint256 tokenId1, uint256 tokenId2)`: View function to check if `bondShards` prerequisites are met.
40. `canUnbondShards(uint256 tokenId)`: View function to check if `unbondShards` prerequisites are met.
41. `setBondingCompatibility(uint256 affinity1, uint256 affinity2, bool compatible)`: Owner-only to define affinity bonding rules.
42. `isValidAffinity(uint256 affinity)`: View function to check if an affinity value is valid.
43. `setValidAffinities(uint256[] calldata validAffinities)`: Owner-only to set the list of valid affinities.
44. `getValidAffinities()`: View function to get the list of valid affinities.

*(Note: The list already exceeds 20 functions with meaningful unique logic/queries)*

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Based on the outline above. Implementing custom ownership and state
// management instead of inheriting standard libraries directly to fulfill
// the "don't duplicate any open source" constraint in spirit, focusing
// on the unique game logic.

// --- Smart Contract Outline and Function Summary (See above) ---

/**
 * @title ChronoGenesisShards
 * @dev A dynamic NFT-like contract with gamified state, resources, and epoch-based progression.
 */
contract ChronoGenesisShards {
    // --- State Variables ---
    address private _owner;
    bool private _paused;

    uint256 private _totalSupply;
    uint256 private _tokenCounter; // Starts from 1 for token IDs

    // Custom NFT-like mappings
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _ownerTokenCount;
    mapping(address => uint256[]) private _ownerTokens; // To list tokens by owner (potentially gas-heavy)

    // Shard State
    struct ShardState {
        uint256 level;
        uint256 xp;
        uint256 affinity; // Represents a type/element, e.g., 1=Fire, 2=Water
        uint256 creationEpoch;
        uint256 lastActiveEpoch;
        uint256 bondedToId; // 0 if not bonded
    }
    mapping(uint256 => ShardState) private _shards;

    // Catalysts (Fungible resource)
    mapping(address => uint256) private _catalystBalances;

    // Global State / Epoch
    uint256 private _currentEpoch;
    uint256 private _epochDuration; // Duration in seconds for each epoch

    // Game Parameters (Owner Adjustable)
    mapping(uint256 => uint256) private _xpRequiredForLevel; // level => required XP
    uint256 private _baseXPGain;
    uint256 private _actionCost; // Catalyst cost for performAction
    uint256 private _bondingCost; // Catalyst cost for bondShards
    uint256 private _decayRate; // Percentage points of level/XP decay per inactive epoch

    // Blessing State
    mapping(uint256 => uint256) private _blessingEndTime; // tokenId => timestamp

    // Affinity Parameters
    uint256[] private _affinityTypes; // List of valid affinity IDs
    mapping(uint256 => mapping(uint256 => bool)) private _bondingCompatibility; // affinity1 => affinity2 => compatible

    // --- Events ---
    event ShardMinted(address indexed owner, uint256 indexed tokenId, uint256 affinity, uint256 epoch);
    event ShardTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event ShardLevelUp(uint256 indexed tokenId, uint256 newLevel);
    event XPGained(uint256 indexed tokenId, uint256 amount, uint256 currentXP);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event ParametersUpdated(string parameterName);
    event ShardBonded(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ShardUnbonded(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event CatalystMinted(address indexed to, uint256 amount);
    event CatalystConsumed(address indexed from, uint256 amount);
    event ShardBlessed(uint256 indexed tokenId, uint256 endTime);
    event Paused(address account);
    event Unpaused(address account);
    event AffinityCompatibilitySet(uint256 indexed affinity1, uint256 indexed affinity2, bool compatible);
    event ValidAffinitiesSet(uint256[] validAffinities);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false;
        _currentEpoch = 1;
        _tokenCounter = 0; // Token IDs start from 1

        // Set some default parameters (can be adjusted by owner)
        _epochDuration = 7 days; // Example: 1 week per epoch
        _baseXPGain = 100;
        _actionCost = 1; // 1 Catalyst per action
        _bondingCost = 5; // 5 Catalysts to bond
        _decayRate = 5; // 5% decay per inactive epoch

        // Default XP requirements (Example)
        _xpRequiredForLevel[1] = 0; // Level 1 requires 0 XP (starting)
        _xpRequiredForLevel[2] = 500;
        _xpRequiredForLevel[3] = 1500;
        _xpRequiredForLevel[4] = 3000;
        _xpRequiredForLevel[5] = 5000;
        // ... owner can add more levels
    }

    // --- Internal Helpers (Custom NFT-like and Game Logic) ---

    /**
     * @dev Internal function to assign ownership of a new shard.
     * @param to The address to assign ownership to.
     * @param tokenId The ID of the shard.
     * @param affinity The affinity assigned to the new shard.
     */
    function _mint(address to, uint256 tokenId, uint256 affinity) internal {
        require(to != address(0), "Mint to the zero address");
        require(_tokenOwners[tokenId] == address(0), "Token already minted");

        _tokenOwners[tokenId] = to;
        _ownerTokenCount[to]++;
        _ownerTokens[to].push(tokenId); // Add to owner's token list
        _totalSupply++;

        // Initialize shard state
        _shards[tokenId] = ShardState({
            level: 1,
            xp: 0,
            affinity: affinity,
            creationEpoch: _currentEpoch,
            lastActiveEpoch: _currentEpoch,
            bondedToId: 0
        });

        emit ShardMinted(to, tokenId, affinity, _currentEpoch);
    }

    /**
     * @dev Internal function to remove ownership of a shard.
     * @param tokenId The ID of the shard.
     */
    function _burn(uint256 tokenId) internal {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "Token does not exist");

        // Handle unbonding if bonded
        if (_shards[tokenId].bondedToId != 0) {
             _unbondShards(tokenId, _shards[tokenId].bondedToId); // Unbond before burning
        }
        if (_shards[_shards[tokenId].bondedToId].bondedToId == tokenId) {
             _unbondShards(_shards[tokenId].bondedToId, tokenId); // Unbond the other side too
        }


        // Remove from owner's token list (simple approach: find and replace last, then pop)
        uint256[] storage ownerTokens = _ownerTokens[owner];
        uint256 lastIndex = ownerTokens.length - 1;
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == tokenId) {
                ownerTokens[i] = ownerTokens[lastIndex];
                break;
            }
        }
        ownerTokens.pop();

        delete _tokenOwners[tokenId];
        delete _shards[tokenId]; // Remove shard state
        _ownerTokenCount[owner]--;
        _totalSupply--;
        // No specific Burn event, can be inferred from transfer to address(0) if needed
        // For this custom implementation, we just delete.
    }


    /**
     * @dev Internal function to transfer shard ownership.
     * @param from The current owner.
     * @param to The new owner.
     * @param tokenId The ID of the shard.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");

        // Handle unbonding if bonded before transfer
         if (_shards[tokenId].bondedToId != 0) {
             _unbondShards(tokenId, _shards[tokenId].bondedToId); // Unbond before transfer
        }

        // Remove from old owner's token list
        uint256[] storage fromOwnerTokens = _ownerTokens[from];
        uint256 lastIndexFrom = fromOwnerTokens.length - 1;
        for (uint256 i = 0; i < fromOwnerTokens.length; i++) {
            if (fromOwnerTokens[i] == tokenId) {
                fromOwnerTokens[i] = fromOwnerTokens[lastIndexFrom];
                break;
            }
        }
        fromOwnerTokens.pop();

        _ownerTokenCount[from]--;
        _tokenOwners[tokenId] = to;
        _ownerTokenCount[to]++;
        _ownerTokens[to].push(tokenId); // Add to new owner's token list

        emit ShardTransferred(from, to, tokenId);
    }

    /**
     * @dev Internal helper to award XP to a shard and check for level up.
     * @param tokenId The ID of the shard.
     * @param amount The amount of XP to award.
     */
    function _awardXP(uint256 tokenId, uint256 amount) internal {
        ShardState storage shard = _shards[tokenId];
        uint256 initialLevel = shard.level;
        shard.xp += amount;

        emit XPGained(tokenId, amount, shard.xp);

        // Check for potential multiple level ups
        while (_checkLevelUp(tokenId)) {
            // Loop as long as the shard can level up
        }

        if (shard.level > initialLevel) {
            emit ShardLevelUp(tokenId, shard.level);
        }
    }

     /**
     * @dev Internal helper to check if a shard can level up and perform the level up.
     * @param tokenId The ID of the shard.
     * @return bool True if a level up occurred, false otherwise.
     */
    function _checkLevelUp(uint256 tokenId) internal returns (bool) {
        ShardState storage shard = _shards[tokenId];
        uint256 nextLevel = shard.level + 1;
        uint256 requiredXP = _xpRequiredForLevel[nextLevel];

        // Level 0 means this level is not defined yet, or max level reached
        if (requiredXP == 0 || shard.xp < requiredXP) {
            return false; // Cannot level up or max level
        }

        // Level up!
        shard.level = nextLevel;
        // Optionally reset XP or carry over excess XP
        shard.xp -= requiredXP; // Carry over excess XP

        return true;
    }

    /**
     * @dev Internal function to apply decay to a shard based on inactivity.
     * Decay is applied *before* any action updates lastActiveEpoch.
     * @param tokenId The ID of the shard.
     */
    function applyDecay(uint256 tokenId) internal {
        ShardState storage shard = _shards[tokenId];
        if (shard.level == 1) return; // No decay for level 1 shards

        // Check for active blessing - no decay if blessed
        if (_blessingEndTime[tokenId] > block.timestamp) return;

        uint256 epochsInactive = _currentEpoch > shard.lastActiveEpoch ? _currentEpoch - shard.lastActiveEpoch : 0;

        if (epochsInactive > 0 && _decayRate > 0) {
            uint256 decayAmount = (shard.level * _decayRate) / 100; // Decay based on level percentage
            if (decayAmount == 0 && _decayRate > 0) decayAmount = 1; // Minimum 1 level decay if rate > 0

            if (shard.level > decayAmount) {
                shard.level -= decayAmount;
            } else {
                shard.level = 1; // Cannot decay below level 1
            }

            // Optionally decay XP proportionally or reset
            // shard.xp = (shard.xp * (100 - _decayRate)) / 100; // Example: decay XP by same percentage

             // Re-check level up state if decay caused level drop (e.g., if XP should be reset)
             // If XP carried over, decaying levels might require re-checking.
             // Simpler approach here: decay level, XP stays (harder to level up again).
        }
    }

    /**
     * @dev Internal helper to bond two shards. Assumes checks are done by caller.
     * @param tokenId1 The ID of the first shard.
     * @param tokenId2 The ID of the second shard.
     */
    function _bondShards(uint256 tokenId1, uint256 tokenId2) internal {
        _shards[tokenId1].bondedToId = tokenId2;
        _shards[tokenId2].bondedToId = tokenId1;
        emit ShardBonded(tokenId1, tokenId2);
    }

    /**
     * @dev Internal helper to unbond two shards. Assumes checks are done by caller.
     * @param tokenId1 The ID of the first shard.
     * @param tokenId2 The ID of the second shard.
     */
    function _unbondShards(uint256 tokenId1, uint256 tokenId2) internal {
        _shards[tokenId1].bondedToId = 0;
        _shards[tokenId2].bondedToId = 0;
        emit ShardUnbonded(tokenId1, tokenId2);
    }

    // --- Public/External Functions ---

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     * @param owner Address for whom to query the balance.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for zero address");
        return _ownerTokenCount[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     * @param tokenId The token ID to query the owner for.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    /**
     * @dev Transfers ownership of a shard from one address to another.
     * Includes custom checks for bonding status.
     * @param to The address to transfer ownership to.
     * @param tokenId The token ID to transfer.
     */
    function transferShard(address to, uint256 tokenId) external notPaused {
        require(ownerOf(tokenId) == msg.sender, "Sender is not the owner");
        require(_shards[tokenId].bondedToId == 0, "Cannot transfer bonded shard"); // Custom check
        _transfer(msg.sender, to, tokenId);
    }

    /**
     * @dev Mints a new shard to the caller. Requires catalysts.
     * A random or pre-defined affinity could be assigned here.
     * For simplicity, affinity is passed as a parameter for now.
     * @param affinity The affinity type for the new shard.
     */
    function mintShard(uint256 affinity) external notPaused {
        require(isValidAffinity(affinity), "Invalid affinity type");
        require(_catalystBalances[msg.sender] >= _actionCost, "Not enough catalysts to mint"); // Using action cost as mint cost for example
        _catalystBalances[msg.sender] -= _actionCost;
        emit CatalystConsumed(msg.sender, _actionCost);

        _tokenCounter++;
        uint256 newTokenId = _tokenCounter;
        _mint(msg.sender, newTokenId, affinity);
    }

    /**
     * @dev Returns the full state struct of a shard.
     * @param tokenId The ID of the shard.
     */
    function getShardState(uint256 tokenId) public view returns (ShardState memory) {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        return _shards[tokenId];
    }

    /**
     * @dev Returns the level of a shard.
     * @param tokenId The ID of the shard.
     */
    function getShardLevel(uint256 tokenId) public view returns (uint256) {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        return _shards[tokenId].level;
    }

     /**
     * @dev Returns the XP of a shard.
     * @param tokenId The ID of the shard.
     */
    function getShardXP(uint256 tokenId) public view returns (uint256) {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        return _shards[tokenId].xp;
    }

    /**
     * @dev Returns the affinity of a shard.
     * @param tokenId The ID of the shard.
     */
    function getAffinityType(uint256 tokenId) public view returns (uint256) {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        return _shards[tokenId].affinity;
    }

    /**
     * @dev Returns the ID of the shard this shard is bonded to (0 if not bonded).
     * @param tokenId The ID of the shard.
     */
    function getShardBondedTo(uint256 tokenId) public view returns (uint256) {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        return _shards[tokenId].bondedToId;
    }

    /**
     * @dev Returns the timestamp when a shard's blessing expires. 0 if not blessed.
     * @param tokenId The ID of the shard.
     */
    function getBlessingEndTime(uint256 tokenId) public view returns (uint256) {
        return _blessingEndTime[tokenId];
    }

     /**
     * @dev Returns the last epoch the shard was active in an interaction.
     * @param tokenId The ID of the shard.
     */
    function getLastActiveEpoch(uint256 tokenId) public view returns (uint256) {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        return _shards[tokenId].lastActiveEpoch;
    }


    /**
     * @dev Allows a user to perform an action with their shard.
     * Consumes catalysts, awards XP, updates activity epoch, applies decay first.
     * @param tokenId The ID of the shard to perform the action with.
     */
    function performAction(uint256 tokenId) external notPaused {
        require(ownerOf(tokenId) == msg.sender, "Sender is not the owner");
        require(_catalystBalances[msg.sender] >= _actionCost, "Not enough catalysts");

        // Apply decay based on inactivity *before* updating lastActiveEpoch
        applyDecay(tokenId);

        _catalystBalances[msg.sender] -= _actionCost;
        emit CatalystConsumed(msg.sender, _actionCost);

        // Award XP (potentially influenced by affinity, blessing, etc. - simplified here)
        uint256 xpGain = _baseXPGain;
        if (_blessingEndTime[tokenId] > block.timestamp) {
            xpGain = xpGain * 2; // Example: blessing doubles XP gain
        }
        _awardXP(tokenId, xpGain);

        // Update last active epoch
        _shards[tokenId].lastActiveEpoch = _currentEpoch;
    }

    /**
     * @dev Bonds two shards together. Both must be owned by the caller, unbonded,
     * and have compatible affinities. Consumes catalysts.
     * @param tokenId1 The ID of the first shard.
     * @param tokenId2 The ID of the second shard.
     */
    function bondShards(uint256 tokenId1, uint256 tokenId2) external notPaused {
        require(tokenId1 != tokenId2, "Cannot bond a shard to itself");
        require(ownerOf(tokenId1) == msg.sender, "Sender is not owner of first shard");
        require(ownerOf(tokenId2) == msg.sender, "Sender is not owner of second shard");
        require(_shards[tokenId1].bondedToId == 0, "First shard is already bonded");
        require(_shards[tokenId2].bondedToId == 0, "Second shard is already bonded");
        require(_catalystBalances[msg.sender] >= _bondingCost, "Not enough catalysts to bond");

        uint256 affinity1 = _shards[tokenId1].affinity;
        uint256 affinity2 = _shards[tokenId2].affinity;
        require(_bondingCompatibility[affinity1][affinity2] || _bondingCompatibility[affinity2][affinity1], "Affinities are not compatible for bonding");

        _catalystBalances[msg.sender] -= _bondingCost;
        emit CatalystConsumed(msg.sender, _bondingCost);

        _bondShards(tokenId1, tokenId2);
    }

    /**
     * @dev Unbonds a shard if it is currently bonded.
     * @param tokenId The ID of the shard to unbond.
     */
    function unbondShards(uint256 tokenId) external notPaused {
        require(ownerOf(tokenId) == msg.sender, "Sender is not the owner");
        uint256 bondedToId = _shards[tokenId].bondedToId;
        require(bondedToId != 0, "Shard is not bonded");

        _unbondShards(tokenId, bondedToId);
    }

     /**
     * @dev Owner-only function to manually advance the global epoch.
     * This would typically be called by a keeper bot or on a schedule.
     */
    function advanceEpoch() external onlyOwner {
        // Could add a check here based on _epochDuration and block.timestamp
        // for a time-based advance, but manual offers more control for demo.
        _currentEpoch++;
        emit EpochAdvanced(_currentEpoch, block.timestamp);
    }

    /**
     * @dev Returns the current global epoch number.
     */
    function getEpoch() public view returns (uint256) {
        return _currentEpoch;
    }

    /**
     * @dev Returns the catalyst balance for a user.
     * @param user The address to query the balance for.
     */
    function getCatalystBalance(address user) public view returns (uint256) {
        return _catalystBalances[user];
    }

    /**
     * @dev Owner-only function to mint catalysts and distribute them.
     * @param to The address to send catalysts to.
     * @param amount The amount of catalysts to mint.
     */
    function mintCatalysts(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Mint to the zero address");
        _catalystBalances[to] += amount;
        emit CatalystMinted(to, amount);
    }

    /**
     * @dev Owner-only function to apply a temporary blessing to a shard.
     * Blessings can modify game mechanics (e.g., XP gain, decay immunity).
     * @param tokenId The ID of the shard to bless.
     * @param durationSeconds The duration of the blessing in seconds.
     */
    function blessShard(uint256 tokenId, uint256 durationSeconds) external onlyOwner {
         require(_tokenOwners[tokenId] != address(0), "Token does not exist");
        _blessingEndTime[tokenId] = block.timestamp + durationSeconds;
        emit ShardBlessed(tokenId, _blessingEndTime[tokenId]);
    }

     /**
     * @dev Owner-only function to pause core user actions.
     */
    function pauseActions() external onlyOwner {
        require(!_paused, "Contract is already paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Owner-only function to unpause core user actions.
     */
    function unpauseActions() external onlyOwner {
        require(_paused, "Contract is not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Owner-only Parameter Setting Functions ---

    /**
     * @dev Owner-only function to set XP required for a specific level.
     * @param level The level number.
     * @param requiredXP The XP needed to reach this level. Set 0 for max level or undefined.
     */
    function setXPRequiredForLevel(uint256 level, uint256 requiredXP) external onlyOwner {
        require(level > 0, "Level must be greater than 0");
        _xpRequiredForLevel[level] = requiredXP;
        emit ParametersUpdated("XPRequiredForLevel");
    }

    /**
     * @dev Owner-only function to set the base amount of XP gained per action.
     * @param amount The base XP amount.
     */
    function setBaseXPGain(uint256 amount) external onlyOwner {
        _baseXPGain = amount;
        emit ParametersUpdated("BaseXPGain");
    }

    /**
     * @dev Owner-only function to set the catalyst cost for bonding shards.
     * @param cost The catalyst cost.
     */
    function setBondingCost(uint256 cost) external onlyOwner {
        _bondingCost = cost;
        emit ParametersUpdated("BondingCost");
    }

     /**
     * @dev Owner-only function to set the decay rate per inactive epoch.
     * Rate is in percentage points (e.g., 5 for 5%).
     * @param rate The decay rate percentage.
     */
    function setDecayParameters(uint256 rate) external onlyOwner {
        require(rate <= 100, "Decay rate cannot exceed 100%");
        _decayRate = rate;
        emit ParametersUpdated("DecayRate");
    }

    /**
     * @dev Owner-only function to set the catalyst cost for performing actions.
     * @param cost The catalyst cost.
     */
    function setActionCost(uint256 cost) external onlyOwner {
        _actionCost = cost;
        emit ParametersUpdated("ActionCost");
    }

     /**
     * @dev Owner-only function to set the duration of an epoch in seconds.
     * @param durationSeconds The epoch duration.
     */
    function setEpochDuration(uint256 durationSeconds) external onlyOwner {
        _epochDuration = durationSeconds;
        emit ParametersUpdated("EpochDuration");
    }

    /**
     * @dev Owner-only function to define which affinities are valid.
     * Clears previous valid affinities.
     * @param validAffinities An array of valid affinity IDs.
     */
    function setValidAffinities(uint256[] calldata validAffinities) external onlyOwner {
        // Reset current valid affinities
        delete _affinityTypes;
        for(uint i = 0; i < validAffinities.length; i++) {
            _affinityTypes.push(validAffinities[i]);
        }
        emit ValidAffinitiesSet(validAffinities);
    }

    /**
     * @dev Owner-only function to set bonding compatibility between two affinity types.
     * @param affinity1 The ID of the first affinity.
     * @param affinity2 The ID of the second affinity.
     * @param compatible True if they can bond, false otherwise.
     */
    function setBondingCompatibility(uint256 affinity1, uint256 affinity2, bool compatible) external onlyOwner {
         require(isValidAffinity(affinity1), "Invalid affinity1 type");
         require(isValidAffinity(affinity2), "Invalid affinity2 type");
        _bondingCompatibility[affinity1][affinity2] = compatible;
        emit AffinityCompatibilitySet(affinity1, affinity2, compatible);
    }

    // --- View/Query Functions ---

    /**
     * @dev Returns an array of all shard IDs owned by a user.
     * WARNING: Can be very gas-expensive for users with many tokens.
     * Consider pagination or off-chain indexing for production.
     * @param user The address to query tokens for.
     */
    function getUserShards(address user) public view returns (uint256[] memory) {
        return _ownerTokens[user];
    }

    /**
     * @dev Returns the total number of shards that have been minted.
     */
    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Checks if a user can perform an action with a shard based on costs and state.
     * @param tokenId The ID of the shard.
     */
    function canPerformAction(uint256 tokenId) public view returns (bool) {
         if (_tokenOwners[tokenId] == address(0)) return false; // Token must exist
         if (_paused) return false; // Contract must not be paused
         if (ownerOf(tokenId) != msg.sender) return false; // Must own the token
         if (_catalystBalances[msg.sender] < _actionCost) return false; // Must have enough catalysts
        // Add other potential checks here (e.g., shard status, global event)
        return true;
    }

    /**
     * @dev Checks if two shards can be bonded by the caller based on ownership, bonding status, and compatibility.
     * @param tokenId1 The ID of the first shard.
     * @param tokenId2 The ID of the second shard.
     */
    function canBondShards(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
        if (tokenId1 == tokenId2) return false;
        if (_tokenOwners[tokenId1] == address(0) || _tokenOwners[tokenId2] == address(0)) return false; // Tokens must exist
        if (_paused) return false; // Contract must not be paused
        if (ownerOf(tokenId1) != msg.sender || ownerOf(tokenId2) != msg.sender) return false; // Must own both tokens
        if (_shards[tokenId1].bondedToId != 0 || _shards[tokenId2].bondedToId != 0) return false; // Neither can be already bonded
        if (_catalystBalances[msg.sender] < _bondingCost) return false; // Must have enough catalysts

        uint256 affinity1 = _shards[tokenId1].affinity;
        uint256 affinity2 = _shards[tokenId2].affinity;
        if (!_bondingCompatibility[affinity1][affinity2] && !_bondingCompatibility[affinity2][affinity1]) return false; // Affinities must be compatible

        return true;
    }

    /**
     * @dev Checks if a shard can be unbonded by the caller.
     * @param tokenId The ID of the shard.
     */
    function canUnbondShards(uint256 tokenId) public view returns (bool) {
        if (_tokenOwners[tokenId] == address(0)) return false; // Token must exist
        if (_paused) return false; // Contract must not be paused
        if (ownerOf(tokenId) != msg.sender) return false; // Must own the token
        if (_shards[tokenId].bondedToId == 0) return false; // Must be bonded

        // Add other potential checks (e.g., cooldown period)
        return true;
    }

     /**
     * @dev Checks if an affinity value is a valid type.
     * @param affinity The affinity ID to check.
     */
    function isValidAffinity(uint256 affinity) public view returns (bool) {
        if (affinity == 0) return false; // Assuming 0 is reserved for 'no affinity' or invalid
        for (uint i = 0; i < _affinityTypes.length; i++) {
            if (_affinityTypes[i] == affinity) return true;
        }
        return false;
    }

    /**
     * @dev Returns the list of currently defined valid affinity types.
     */
     function getValidAffinities() public view returns (uint256[] memory) {
         return _affinityTypes;
     }

     /**
      * @dev Returns the XP required for a specific level.
      * @param level The level to query.
      */
     function getXPRequiredForLevel(uint256 level) public view returns (uint256) {
         return _xpRequiredForLevel[level];
     }

     /**
      * @dev Returns the current base XP gain per action.
      */
     function getBaseXPGain() public view returns (uint256) {
         return _baseXPGain;
     }

      /**
      * @dev Returns the current catalyst cost for bonding.
      */
     function getBondingCost() public view returns (uint256) {
         return _bondingCost;
     }

      /**
      * @dev Returns the current decay rate percentage.
      */
     function getDecayRate() public view returns (uint256) {
         return _decayRate;
     }

      /**
      * @dev Returns the current catalyst cost for actions.
      */
     function getActionCost() public view returns (uint256) {
         return _actionCost;
     }

     /**
      * @dev Returns the current epoch duration in seconds.
      */
     function getEpochDuration() public view returns (uint256) {
         return _epochDuration;
     }

     /**
      * @dev Returns true if contract is paused.
      */
     function isPaused() public view returns (bool) {
         return _paused;
     }

     /**
      * @dev Returns the contract owner address.
      */
     function owner() public view returns (address) {
         return _owner;
     }

     /**
      * @dev Get bonding compatibility status between two affinities.
      * @param affinity1 The ID of the first affinity.
      * @param affinity2 The ID of the second affinity.
      */
     function getBondingCompatibility(uint256 affinity1, uint256 affinity2) public view returns (bool) {
        // Check both directions for symmetric compatibility if needed, or rely on owner setting both
         return _bondingCompatibility[affinity1][affinity2];
     }
}
```

**Explanation of Concepts and Code Choices:**

1.  **Custom NFT Implementation:** Instead of `import "@openzeppelin/contracts/token/ERC721/ERC721.sol";`, the contract uses internal mappings (`_tokenOwners`, `_ownerTokenCount`, `_ownerTokens`) and functions (`_mint`, `_burn`, `_transfer`) to manage ownership and balances. This aligns with the "don't duplicate open source" constraint by building the core logic manually rather than inheriting a standard implementation. The public `balanceOf`, `ownerOf`, and `transferShard` provide an interface *similar* to ERC721 but with custom internal handling.
2.  **Dynamic State (`ShardState` struct):** Each shard isn't just an ID; it has evolving properties stored directly on-chain. This is a core aspect of dynamic NFTs.
3.  **Gamified Mechanics (XP, Leveling, Actions):** The `performAction` function simulates interaction, awards XP, and triggers leveling (`_awardXP`, `_checkLevelUp`). This creates a state-changing game loop on-chain.
4.  **Resource Management (`Catalyst`):** `Catalysts` are an internal fungible token-like resource (`_catalystBalances`) required for actions (`performAction`) and bonding (`bondShards`). This adds a strategic layer to interactions and provides an owner-controlled faucet (`mintCatalysts`).
5.  **Epoch System:** `_currentEpoch` provides a discrete time step. `advanceEpoch` (owner-controlled) moves to the next epoch. This is used for features like inactivity decay (`applyDecay`). A real-world implementation might use an external keeper or Chainlink Automation to call `advanceEpoch` based on time or other triggers.
6.  **Bonding (`bondShards`, `unbondShards`, `bondedToId`):** Shards can be linked together, affecting their state or enabling new interactions (though the contract only implements the bonding/unbonding state change). This adds combinatorial complexity.
7.  **Inactivity Decay (`applyDecay`):** Shards can lose levels/XP if they aren't interacted with over several epochs. This encourages participation.
8.  **Blessings (`blessShard`, `_blessingEndTime`):** A temporary owner-granted buff to a shard, modifying game mechanics (e.g., increased XP gain, decay immunity).
9.  **Owner-Controlled Parameters:** Many aspects of the game (`_xpRequiredForLevel`, `_baseXPGain`, `_actionCost`, `_bondingCost`, `_decayRate`, `_epochDuration`) are controlled by the owner, allowing for tuning and evolution of the game/system.
10. **Affinities and Compatibility:** Shards have affinities, and bonding is restricted based on these affinities (`_affinityTypes`, `_bondingCompatibility`). The owner defines valid affinities and their compatibility.
11. **Query Functions (`getShardState`, `getShardLevel`, etc. + `can...` functions):** A rich set of view functions allows external applications (like a frontend) to query the state of shards, users, and game parameters, and even check if actions are possible before attempting a transaction.
12. **`getUserShards`:** This function demonstrates retrieving all tokens for a user. *Important Note:* For contracts where a single user might own *many* tokens, iterating and returning a large array can hit gas limits. In production, a more advanced pattern (like linked lists on-chain or relying on off-chain indexing of events) might be necessary. It's included here to meet the function count and demonstrate the query.
13. **Access Control:** The `onlyOwner` modifier (implemented manually) is used for sensitive administrative functions. `notPaused` modifier controls core user interactions.

This contract provides a foundation for a complex on-chain game or dynamic digital collectible system with multiple intertwined mechanics and administrative controls, going beyond simple token transfers or static NFTs.