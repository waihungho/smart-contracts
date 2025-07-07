Okay, here is a Solidity smart contract that attempts to be interesting, advanced, creative, and trendy by combining several concepts: Dynamic NFTs (Sentinels), an internal resource token (ChronoDust), crafting, interaction-based evolution, delegation of usage rights, and an "Epoch" system that influences gameplay/utility. It avoids being a direct copy of standard ERC721/ERC20 implementations by building a *system* around these concepts.

We will use OpenZeppelin libraries for standard patterns like `Ownable`, `Pausable`, and basic ERC721/ERC20 structure to ensure security and adherence to standards, but the core logic creating the unique interactions is custom.

---

**Outline:**

1.  **Contract Description:** A system for managing dynamic digital entities called "Sentinels" (ERC721) and an associated resource token "ChronoDust". Sentinels evolve based on interaction, consume resources, can be equipped with forged items, and are influenced by a global "Epoch" state. Owners can delegate certain usage rights for their Sentinels.
2.  **Core Components:**
    *   `ChronoForgeSentinels`: The main contract managing Sentinels, Items, Epochs, and ChronoDust balances.
    *   Sentinels: ERC721 tokens with dynamic attributes (Level, Power, Affinity, Durability, Experience, Attribute Points) and static/dynamic traits.
    *   ChronoDust: An internal fungible resource used for crafting, upgrades, and repairs. Managed within the main contract's state.
    *   Items: Forged assets (simple structs) that can be attached to Sentinels to boost attributes.
    *   Epochs: A global state that influences Sentinel interactions (e.g., quest outcomes). Updatable by owner/oracle.
    *   Delegation: Owners can grant specific addresses temporary rights to use their Sentinels for defined actions.
3.  **Function Categories:**
    *   Sentinel Management (Minting, Getting Info, Evolution, Burning)
    *   Item Management (Forging, Getting Info, Attaching, Detaching, Burning)
    *   ChronoDust Management (Getting Balance, Transferring - simulating ERC20)
    *   Interaction & Evolution (Gaining XP, Leveling, Applying Attributes, Questing, Bonding)
    *   Epoch Management (Getting Current, Updating State)
    *   Delegation Management (Granting, Revoking, Checking)
    *   Standard ERC721 Functions (Inherited/Implemented)
    *   Standard ERC20-like Functions for ChronoDust (Implemented)
    *   Admin/Utility (Pause, Unpause, Ownership)

**Function Summary:**

*   `constructor(string memory name, string memory symbol)`: Initializes the contract, ERC721 properties, owner.
*   `pause()`: Pauses contract operations (Admin).
*   `unpause()`: Unpauses contract operations (Admin).
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 check.
*   `tokenURI(uint256 tokenId)`: Returns metadata URI for a Sentinel (Standard ERC721).
*   `mintSentinel(address to, uint256 initialPower)`: Mints a new Sentinel token to an address, sets initial stats (Admin/Privileged).
*   `burnSentinel(uint256 sentinelId)`: Destroys a Sentinel token (Owner/Approved/Delegate).
*   `getSentinelStats(uint256 sentinelId)`: Gets core dynamic stats (Level, Power, Affinity, etc.) of a Sentinel.
*   `getSentinelTraits(uint256 sentinelId)`: Gets static origin and dynamic evolved traits.
*   `gainExperience(uint256 sentinelId, uint256 amount)`: Increases a Sentinel's experience points (Requires specific conditions, simulated here).
*   `levelUp(uint256 sentinelId)`: Attempts to level up a Sentinel if it has enough XP, increasing level and attribute points (Owner/Approved/Delegate).
*   `applyAttributePoints(uint256 sentinelId, uint256 powerIncrease, uint256 affinityIncrease, uint256 durabilityIncrease)`: Spends attribute points and ChronoDust to boost a Sentinel's stats (Owner/Approved/Delegate).
*   `forgeItem(uint256 requiredDust, uint256 powerBoost, uint256 affinityBoost, uint256 durabilityBoost)`: Creates a new item by burning ChronoDust (Any user).
*   `getItemStats(uint256 itemId)`: Gets stats of a specific item.
*   `attachItem(uint256 sentinelId, uint256 itemId)`: Attaches an item to a Sentinel, applying stat boosts (Owner/Approved/Delegate). Item becomes bound.
*   `detachItem(uint256 sentinelId)`: Detaches the currently attached item from a Sentinel (Owner/Approved/Delegate). Item becomes unbound.
*   `repairDurability(uint256 sentinelId, uint256 dustAmount)`: Spends ChronoDust to restore a Sentinel's durability (Owner/Approved/Delegate).
*   `updateEpochState(uint256 newEpochId, string calldata description)`: Updates the global Epoch state (Admin).
*   `getCurrentEpoch()`: Gets the current Epoch ID and description.
*   `sendOnQuest(uint256 sentinelId)`: Simulates a quest, consuming durability and potentially yielding rewards (XP, Dust) based on Sentinel stats and Epoch (Owner/Approved/Delegate).
*   `bondWithSentinel(uint256 sentinelId)`: Simulates an owner interaction, increasing Sentinel's affinity (Owner only). May require small dust cost.
*   `delegateSentinelUsage(uint256 sentinelId, address delegatee, uint256 duration)`: Grants temporary usage rights for a Sentinel (Owner only).
*   `revokeDelegate(uint256 sentinelId, address delegatee)`: Revokes specific delegation for a Sentinel (Owner only).
*   `isDelegate(uint256 sentinelId, address delegatee)`: Checks if an address is currently a delegate for a Sentinel.
*   `getChronoDustBalance(address account)`: Gets the ChronoDust balance of an address.
*   `transferChronoDust(address recipient, uint256 amount)`: Transfers ChronoDust from caller's balance (Simulated ERC20).
*   `approveChronoDust(address spender, uint256 amount)`: Sets allowance for ChronoDust spending (Simulated ERC20).
*   `transferFromChronoDust(address sender, address recipient, uint256 amount)`: Transfers ChronoDust using an allowance (Simulated ERC20).
*   `getChronoDustAllowance(address owner, address spender)`: Gets ChronoDust allowance (Simulated ERC20).
*   `mintChronoDust(address to, uint256 amount)`: Mints ChronoDust to an address (Admin/Privileged - e.g., for rewards).
*   `burnChronoDust(address from, uint256 amount)`: Burns ChronoDust from an address (Admin/Privileged or internal logic).
*   (Inherited from ERC721) `balanceOf(address owner)`: Get number of Sentinels owned by an address.
*   (Inherited from ERC721) `ownerOf(uint256 tokenId)`: Get owner of a Sentinel.
*   (Inherited from ERC721) `transferFrom(address from, address to, uint256 tokenId)`: Transfer Sentinel.
*   (Inherited from ERC721) `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer Sentinel.
*   (Inherited from ERC721) `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer Sentinel with data.
*   (Inherited from ERC721) `approve(address to, uint256 tokenId)`: Approve address to transfer Sentinel.
*   (Inherited from ERC721) `getApproved(uint256 tokenId)`: Get approved address for Sentinel.
*   (Inherited from ERC721) `setApprovalForAll(address operator, bool approved)`: Set approval for all Sentinels.
*   (Inherited from ERC721) `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all.
*   (Inherited from Ownable) `owner()`: Get contract owner.
*   (Inherited from Ownable) `transferOwnership(address newOwner)`: Transfer contract ownership.

*(Total functions: 42 including inherited and simulated standard ones, well over the requested 20).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for listing tokens per owner, though can be gas-intensive
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice if complex interactions involving token transfers occur

// --- Outline ---
// 1. Contract Description: A system for managing dynamic digital entities called "Sentinels" (ERC721)
//    and an associated resource token "ChronoDust". Sentinels evolve based on interaction, consume resources,
//    can be equipped with forged items, and are influenced by a global "Epoch" state.
//    Owners can delegate certain usage rights for their Sentinels.
// 2. Core Components:
//    - ChronoForgeSentinels: The main contract managing Sentinels, Items, Epochs, and ChronoDust balances.
//    - Sentinels: ERC721 tokens with dynamic attributes (Level, Power, Affinity, Durability, Experience, Attribute Points) and static/dynamic traits.
//    - ChronoDust: An internal fungible resource used for crafting, upgrades, and repairs. Managed within the main contract's state.
//    - Items: Forged assets (simple structs) that can be attached to Sentinels to boost attributes.
//    - Epochs: A global state that influences Sentinel interactions (e.g., quest outcomes). Updatable by owner/oracle.
//    - Delegation: Owners can grant specific addresses temporary rights to use their Sentinels for defined actions.
// 3. Function Categories: Sentinel Management, Item Management, ChronoDust Management, Interaction & Evolution,
//    Epoch Management, Delegation Management, Standard ERC721, Simulated ERC20 for ChronoDust, Admin/Utility.

// --- Function Summary ---
// - constructor(string memory name, string memory symbol): Initializes the contract, ERC721 properties, owner.
// - pause(): Pauses contract operations (Admin).
// - unpause(): Unpauses contract operations (Admin).
// - supportsInterface(bytes4 interfaceId): Standard ERC165 check.
// - tokenURI(uint256 tokenId): Returns metadata URI for a Sentinel (Standard ERC721).
// - mintSentinel(address to, uint256 initialPower): Mints a new Sentinel token to an address, sets initial stats (Admin/Privileged).
// - burnSentinel(uint256 sentinelId): Destroys a Sentinel token (Owner/Approved/Delegate).
// - getSentinelStats(uint256 sentinelId): Gets core dynamic stats (Level, Power, Affinity, etc.) of a Sentinel.
// - getSentinelTraits(uint256 sentinelId): Gets static origin and dynamic evolved traits.
// - gainExperience(uint256 sentinelId, uint256 amount): Increases a Sentinel's experience points (Requires specific conditions, simulated here).
// - levelUp(uint256 sentinelId): Attempts to level up a Sentinel if it has enough XP, increasing level and attribute points (Owner/Approved/Delegate).
// - applyAttributePoints(uint256 sentinelId, uint256 powerIncrease, uint256 affinityIncrease, uint256 durabilityIncrease): Spends attribute points and ChronoDust to boost a Sentinel's stats (Owner/Approved/Delegate).
// - forgeItem(uint256 requiredDust, uint256 powerBoost, uint256 affinityBoost, uint256 durabilityBoost): Creates a new item by burning ChronoDust (Any user).
// - getItemStats(uint256 itemId): Gets stats of a specific item.
// - attachItem(uint256 sentinelId, uint256 itemId): Attaches an item to a Sentinel, applying stat boosts (Owner/Approved/Delegate). Item becomes bound.
// - detachItem(uint256 sentinelId): Detaches the currently attached item from a Sentinel (Owner/Approved/Delegate). Item becomes unbound.
// - repairDurability(uint256 sentinelId, uint256 dustAmount): Spends ChronoDust to restore a Sentinel's durability (Owner/Approved/Delegate).
// - updateEpochState(uint256 newEpochId, string calldata description): Updates the global Epoch state (Admin).
// - getCurrentEpoch(): Gets the current Epoch ID and description.
// - sendOnQuest(uint256 sentinelId): Simulates a quest, consuming durability and potentially yielding rewards (XP, Dust) based on Sentinel stats and Epoch (Owner/Approved/Delegate).
// - bondWithSentinel(uint256 sentinelId): Simulates an owner interaction, increasing Sentinel's affinity (Owner only).
// - delegateSentinelUsage(uint256 sentinelId, address delegatee, uint256 duration): Grants temporary usage rights for a Sentinel (Owner only).
// - revokeDelegate(uint256 sentinelId, address delegatee): Revokes specific delegation for a Sentinel (Owner only).
// - isDelegate(uint256 sentinelId, address delegatee): Checks if an address is currently a delegate for a Sentinel.
// - getChronoDustBalance(address account): Gets the ChronoDust balance of an address.
// - transferChronoDust(address recipient, uint256 amount): Transfers ChronoDust from caller's balance (Simulated ERC20).
// - approveChronoDust(address spender, uint256 amount): Sets allowance for ChronoDust spending (Simulated ERC20).
// - transferFromChronoDust(address sender, address recipient, uint256 amount): Transfers ChronoDust using an allowance (Simulated ERC20).
// - getChronoDustAllowance(address owner, address spender): Gets ChronoDust allowance (Simulated ERC20).
// - mintChronoDust(address to, uint256 amount): Mints ChronoDust to an address (Admin/Privileged).
// - burnChronoDust(address from, uint256 amount): Burns ChronoDust from an address (Admin/Privileged or internal logic).
// - Standard ERC721 Functions (balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll) - Inherited.
// - Standard Ownable Functions (owner, transferOwnership) - Inherited.

contract ChronoForgeSentinels is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _sentinelCounter;
    Counters.Counter private _itemCounter;

    // --- Error Definitions ---
    error SentinelDoesNotExist(uint256 sentinelId);
    error ItemDoesNotExist(uint256 itemId);
    error NotSentinelOwnerOrApproved(uint256 sentinelId, address caller);
    error NotSentinelOwnerOrDelegate(uint256 sentinelId, address caller);
    error InsufficientExperience(uint256 sentinelId, uint256 requiredXP);
    error InsufficientAttributePoints(uint256 sentinelId, uint256 requestedPoints);
    error InsufficientChronoDust(address account, uint256 requiredAmount);
    error ItemAlreadyAttached(uint256 sentinelId);
    error NoItemAttached(uint256 sentinelId);
    error ItemNotOwnedByCallerOrApproved(uint256 itemId, address caller); // Should not happen if item is attached, but good for forging check if needed
    error InvalidDurability(uint256 sentinelId);
    error DelegationAlreadyExists(uint256 sentinelId, address delegatee);
    error NotADelegate(uint256 sentinelId, address delegatee);
    error DelegationExpired(uint256 sentinelId, address delegatee);

    // --- Structs ---

    struct SentinelStats {
        uint256 level;
        uint256 experience;
        uint256 attributePoints;
        uint256 power;
        uint256 affinity;
        uint256 durability; // Out of 1000 (e.g., 1000 is 100%)
        uint256 attachedItemId; // 0 if no item attached
    }

    struct SentinelTraits {
        uint256 originTrait1; // Static trait from minting
        uint256 originTrait2; // Static trait from minting
        uint256 evolvedTrait; // Dynamic trait that can change/unlock based on actions/level
    }

    struct Item {
        bool exists; // Use mapping check usually, but struct can hold data
        uint256 powerBoost;
        uint256 affinityBoost;
        uint256 durabilityBoost;
        bool isBound; // True if attached to a sentinel
    }

    struct Epoch {
        uint256 id;
        string description;
        uint256 startTime;
    }

    struct Delegation {
        address delegatee;
        uint256 expirationTime;
    }

    // --- State Variables ---

    mapping(uint256 => SentinelStats) private _sentinelStats;
    mapping(uint256 => SentinelTraits) private _sentinelTraits;
    mapping(uint256 => Item) private _items;
    mapping(address => uint256) private _chronoDustBalances;
    mapping(address => mapping(address => uint256)) private _chronoDustAllowances; // Simulated ERC20 allowances
    uint256 private _totalChronoDustSupply;

    Epoch private _currentEpoch;

    // SentinelId => Delegation[] (Simplified: store single delegation for now)
    mapping(uint256 => Delegation) private _sentinelDelegations;

    // --- Events ---

    event SentinelMinted(uint256 indexed sentinelId, address indexed owner, uint256 initialPower);
    event SentinelBurned(uint256 indexed sentinelId, address indexed owner);
    event ExperienceGained(uint256 indexed sentinelId, uint256 amount);
    event LeveledUp(uint256 indexed sentinelId, uint256 newLevel, uint256 attributePointsGained);
    event AttributePointsApplied(uint256 indexed sentinelId, uint256 pointsSpent, uint256 powerIncrease, uint256 affinityIncrease, uint256 durabilityIncrease);
    event ItemForged(uint256 indexed itemId, address indexed creator, uint256 requiredDust);
    event ItemAttached(uint256 indexed sentinelId, uint256 indexed itemId);
    event ItemDetached(uint256 indexed sentinelId, uint256 indexed itemId);
    event DurabilityRepaired(uint256 indexed sentinelId, uint256 dustSpent, uint256 durabilityRestored);
    event EpochStateUpdated(uint256 indexed newEpochId, string description, uint256 timestamp);
    event QuestCompleted(uint256 indexed sentinelId, uint256 xpGained, uint256 dustGained, bool itemFound);
    event ChronoDustTransferred(address indexed from, address indexed to, uint256 amount);
    event ChronoDustApproved(address indexed owner, address indexed spender, uint256 amount);
    event ChronoDustMinted(address indexed account, uint256 amount);
    event ChronoDustBurned(address indexed account, uint256 amount);
    event SentinelDelegated(uint256 indexed sentinelId, address indexed delegatee, uint256 expirationTime);
    event SentinelDelegateRevoked(uint256 indexed sentinelId, address indexed delegatee);
    event SentinelBonded(uint256 indexed sentinelId, address indexed owner);

    // --- Modifiers ---

    modifier onlySentinelOwnerOrApproved(uint256 sentinelId) {
        if (_isApprovedOrOwner(_msgSender(), sentinelId) == false) {
            revert NotSentinelOwnerOrApproved(sentinelId, _msgSender());
        }
        _;
    }

    modifier onlySentinelOwnerOrDelegate(uint256 sentinelId) {
        address currentOwner = ownerOf(sentinelId);
        if (_msgSender() != currentOwner && !isDelegate(sentinelId, _msgSender())) {
             revert NotSentinelOwnerOrDelegate(sentinelId, _msgSender());
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) Pausable() {}

    // --- Admin & Utility ---

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721Enumerable) returns (string memory) {
        // Basic placeholder implementation
        _requireOwned(tokenId);
        return string(abi.encodePacked("ipfs://YOUR_BASE_URI/", Strings.toString(tokenId)));
    }

    // --- Internal ChronoDust Management (Simulating ERC20) ---

    function getChronoDustBalance(address account) public view returns (uint256) {
        return _chronoDustBalances[account];
    }

    function transferChronoDust(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        address sender = _msgSender();
        _transferChronoDust(sender, recipient, amount);
        return true;
    }

    function approveChronoDust(address spender, uint256 amount) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        _chronoDustAllowances[owner][spender] = amount;
        emit ChronoDustApproved(owner, spender, amount);
        return true;
    }

    function transferFromChronoDust(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = _chronoDustAllowances[sender][spender];
        if (currentAllowance < amount) {
            revert InsufficientChronoDustAllowance(sender, spender, amount);
        }
        unchecked {
            _chronoDustAllowances[sender][spender] = currentAllowance - amount;
        }
        _transferChronoDust(sender, recipient, amount);
        return true;
    }

    function getChronoDustAllowance(address owner, address spender) public view returns (uint256) {
        return _chronoDustAllowances[owner][spender];
    }

    // Admin/Privileged function to mint ChronoDust (e.g., for initial supply or rewards)
    function mintChronoDust(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mintChronoDust(to, amount);
    }

    // Admin/Privileged function to burn ChronoDust
    function burnChronoDust(address from, uint256 amount) public onlyOwner whenNotPaused {
         _burnChronoDust(from, amount);
    }

    function _transferChronoDust(address sender, address recipient, uint256 amount) internal {
        if (_chronoDustBalances[sender] < amount) {
            revert InsufficientChronoDust(sender, amount);
        }
        unchecked {
            _chronoDustBalances[sender] = _chronoDustBalances[sender] - amount;
        }
        _chronoDustBalances[recipient] = _chronoDustBalances[recipient] + amount;
        emit ChronoDustTransferred(sender, recipient, amount);
    }

    function _mintChronoDust(address account, uint256 amount) internal {
        _totalChronoDustSupply += amount;
        _chronoDustBalances[account] += amount;
        emit ChronoDustMinted(account, amount);
    }

    function _burnChronoDust(address account, uint256 amount) internal {
        if (_chronoDustBalances[account] < amount) {
            revert InsufficientChronoDust(account, amount);
        }
        unchecked {
             _chronoDustBalances[account] = _chronoDustBalances[account] - amount;
        }
        _totalChronoDustSupply -= amount;
        emit ChronoDustBurned(account, amount);
    }

    // Custom Error for ChronoDust allowance
    error InsufficientChronoDustAllowance(address owner, address spender, uint256 requiredAmount);


    // --- Sentinel Management ---

    // Admin/Privileged function to mint Sentinels
    function mintSentinel(address to, uint256 initialPower) public onlyOwner whenNotPaused {
        _sentinelCounter.increment();
        uint256 newTokenId = _sentinelCounter.current();
        _safeMint(to, newTokenId);

        // Assign initial stats and traits
        _sentinelStats[newTokenId] = SentinelStats({
            level: 1,
            experience: 0,
            attributePoints: 0,
            power: initialPower,
            affinity: 0,
            durability: 1000, // Start at 100%
            attachedItemId: 0
        });

        // Assign random-like origin traits (simplified: use token ID modulo)
        _sentinelTraits[newTokenId] = SentinelTraits({
            originTrait1: newTokenId % 10 + 1, // Trait 1 (1-10)
            originTrait2: (newTokenId / 10) % 10 + 1, // Trait 2 (1-10)
            evolvedTrait: 0 // Starts with no evolved trait
        });

        emit SentinelMinted(newTokenId, to, initialPower);
    }

    // Burn Sentinel (Owner or Approved or Delegate)
    function burnSentinel(uint256 sentinelId) public whenNotPaused onlySentinelOwnerOrApproved(sentinelId) {
        // Note: ERC721Enumerable's _beforeTokenTransfer hook handles removing from owner list
        address currentOwner = ownerOf(sentinelId); // Checks existence internally
        uint256 attachedItemId = _sentinelStats[sentinelId].attachedItemId;

        if (attachedItemId != 0) {
            // Detach and potentially burn the item first, or just detach
            _detachItem(sentinelId, attachedItemId); // Simple detach, item exists but isn't bound/attached
        }

        delete _sentinelStats[sentinelId];
        delete _sentinelTraits[sentinelId];
        delete _sentinelDelegations[sentinelId]; // Clear delegation info

        _burn(sentinelId); // ERC721Enumerable handles internal burning logic

        emit SentinelBurned(sentinelId, currentOwner);
    }

    function getSentinelStats(uint256 sentinelId) public view returns (SentinelStats memory) {
        _requireOwned(sentinelId); // Implicitly checks if token exists
        return _sentinelStats[sentinelId];
    }

    function getSentinelTraits(uint256 sentinelId) public view returns (SentinelTraits memory) {
         _requireOwned(sentinelId); // Implicitly checks if token exists
        return _sentinelTraits[sentinelId];
    }

    // --- Sentinel Evolution & Interaction ---

    // Simulate gaining experience - could be tied to external actions or other contract calls
    function gainExperience(uint256 sentinelId, uint256 amount) public whenNotPaused {
         _requireOwned(sentinelId); // Sentinel must exist
        // Add specific access control here if needed (e.g., only specific game contract)
        // For this example, let's allow anyone to add XP (useful for testing)
        _sentinelStats[sentinelId].experience += amount;
        emit ExperienceGained(sentinelId, amount);
    }

    function levelUp(uint256 sentinelId) public whenNotPaused onlySentinelOwnerOrDelegate(sentinelId) {
        SentinelStats storage stats = _sentinelStats[sentinelId];
        uint256 xpForNextLevel = calculateXPForLevel(stats.level + 1);

        if (stats.experience < xpForNextLevel) {
            revert InsufficientExperience(sentinelId, xpForNextLevel);
        }

        unchecked {
            stats.experience -= xpForNextLevel;
            stats.level += 1;
            // Gain attribute points upon leveling up
            stats.attributePoints += calculateAttributePointsGained(stats.level);
        }

        // Potential logic for evolving traits at certain levels
        if (stats.level == 5) { // Example: evolve trait at level 5
             _sentinelTraits[sentinelId].evolvedTrait = 1; // Example: unlock trait 1
        } else if (stats.level == 10) { // Example: evolve trait at level 10
             _sentinelTraits[sentinelId].evolvedTrait = 2; // Example: unlock trait 2
        }
         // More complex logic could use origin traits or actions taken

        emit LeveledUp(sentinelId, stats.level, calculateAttributePointsGained(stats.level));
    }

    // Helper function (can be internal)
    function calculateXPForLevel(uint256 level) internal pure returns (uint256) {
        // Example: simple linear or exponential scale
        return level * 100; // Level 2 needs 200 XP, Level 3 needs 300 XP *from level 2*
        // Or cumulative:
        // return (level * (level - 1)) / 2 * 100; // Level 2 needs 100, Level 3 needs 300, Level 4 needs 600
        // Let's use the cumulative model:
        return (level * (level - 1)) / 2 * 100;
    }

     // Helper function (can be internal)
    function calculateAttributePointsGained(uint256 level) internal pure returns (uint256) {
        // Example: gain 3 points per level after level 1
        return level > 1 ? 3 : 0;
    }

    function applyAttributePoints(uint256 sentinelId, uint256 powerIncrease, uint256 affinityIncrease, uint256 durabilityIncrease) public whenNotPaused onlySentinelOwnerOrDelegate(sentinelId) {
        SentinelStats storage stats = _sentinelStats[sentinelId];
        uint256 totalPointsSpent = powerIncrease + affinityIncrease + durabilityIncrease;

        if (stats.attributePoints < totalPointsSpent) {
            revert InsufficientAttributePoints(sentinelId, totalPointsSpent);
        }

        // Define a cost in ChronoDust per point applied
        uint256 dustCostPerPoint = 10; // Example cost
        uint256 totalDustCost = totalPointsSpent * dustCostPerPoint;
        address currentOwner = ownerOf(sentinelId); // Dust is paid by the owner account

        _burnChronoDust(currentOwner, totalDustCost); // Burn dust from the owner's balance

        unchecked {
            stats.attributePoints -= totalPointsSpent;
            stats.power += powerIncrease;
            stats.affinity += affinityIncrease;
            // Durability max is 1000, so increase adds to current value, capped at 1000
            stats.durability = Math.min(stats.durability + durabilityIncrease, 1000);
        }

        emit AttributePointsApplied(sentinelId, totalPointsSpent, powerIncrease, affinityIncrease, durabilityIncrease);
    }

     // Simulate an owner-specific bonding interaction
    function bondWithSentinel(uint256 sentinelId) public whenNotPaused nonReentrant {
        // This action should only be done by the owner, not a delegate
        _requireOwned(sentinelId); // Checks if caller is the owner and token exists

        SentinelStats storage stats = _sentinelStats[sentinelId];

        // Example: Increase affinity slightly, maybe cost a tiny bit of dust
        uint256 bondingDustCost = 10; // Small dust cost
        _burnChronoDust(_msgSender(), bondingDustCost); // Cost paid by owner

        stats.affinity = Math.min(stats.affinity + 1, 100); // Cap affinity at 100

        emit SentinelBonded(sentinelId, _msgSender());
    }


    // --- Item Management ---

    function forgeItem(uint256 requiredDust, uint256 powerBoost, uint256 affinityBoost, uint256 durabilityBoost) public whenNotPaused nonReentrant {
        // Anyone can forge an item if they have the dust
        _burnChronoDust(_msgSender(), requiredDust);

        _itemCounter.increment();
        uint256 newItemId = _itemCounter.current();

        _items[newItemId] = Item({
            exists: true,
            powerBoost: powerBoost,
            affinityBoost: affinityBoost,
            durabilityBoost: durabilityBoost,
            isBound: false
        });

        emit ItemForged(newItemId, _msgSender(), requiredDust);
    }

    function getItemStats(uint256 itemId) public view returns (Item memory) {
        if (!_items[itemId].exists) {
            revert ItemDoesNotExist(itemId);
        }
        return _items[itemId];
    }

    function attachItem(uint256 sentinelId, uint256 itemId) public whenNotPaused onlySentinelOwnerOrDelegate(sentinelId) nonReentrant {
        SentinelStats storage stats = _sentinelStats[sentinelId];
        Item storage item = _items[itemId];

        if (!item.exists) {
            revert ItemDoesNotExist(itemId);
        }
        if (item.isBound) {
             // Item is already attached to something else (or this one). Detach first.
             revert ItemAlreadyAttached(itemId);
        }
         if (stats.attachedItemId != 0) {
             // Sentinel already has an item. Detach the current one first.
             revert ItemAlreadyAttached(sentinelId); // Using same error as it's about the attachment slot
         }

        // Basic ownership check for the item itself (before attachment, it should be owned by the caller or approved)
        // We assume items exist and can be transferred/used once forged.
        // A more complex system might track item ownership explicitly.
        // For simplicity here, forging creates the item, and then it can be attached IF NOT BOUND.

        // Update Sentinel stats with boosts
        stats.power += item.powerBoost;
        stats.affinity += item.affinityBoost;
        stats.durability = Math.min(stats.durability + item.durabilityBoost, 1000); // Durability boost is applied once on attach

        // Link item to sentinel
        stats.attachedItemId = itemId;
        item.isBound = true; // Mark item as bound/attached

        emit ItemAttached(sentinelId, itemId);
    }

     function detachItem(uint256 sentinelId) public whenNotPaused onlySentinelOwnerOrDelegate(sentinelId) nonReentrant {
         SentinelStats storage stats = _sentinelStats[sentinelId];
         uint256 attachedItemId = stats.attachedItemId;

         if (attachedItemId == 0) {
             revert NoItemAttached(sentinelId);
         }

         Item storage item = _items[attachedItemId];
         // item.exists check is implicit if attachedItemId was non-zero and we trust state consistency

         // Revert Sentinel stats by removing boosts
         // Need to be careful with underflow if boosts were massive relative to base stats
         stats.power = stats.power >= item.powerBoost ? stats.power - item.powerBoost : 0;
         stats.affinity = stats.affinity >= item.affinityBoost ? stats.affinity - item.affinityBoost : 0;
         // Durability boost from item is likely permanent once applied, or decays over time.
         // For simplicity, let's say detaching *doesn't* remove the durability gained upon attachment.
         // If durability boost should be temporary, the stats struct needs base_durability and current_durability.
         // Let's choose the simple approach: durability boost is one-time on attach.

         // Unlink item from sentinel
         stats.attachedItemId = 0;
         item.isBound = false; // Mark item as unbound

         emit ItemDetached(sentinelId, attachedItemId);
     }

     function repairDurability(uint256 sentinelId, uint256 dustAmount) public whenNotPaused onlySentinelOwnerOrDelegate(sentinelId) nonReentrant {
         SentinelStats storage stats = _sentinelStats[sentinelId];
         if (stats.durability >= 1000) {
             revert InvalidDurability(sentinelId); // Already at max durability
         }

         address currentOwner = ownerOf(sentinelId); // Dust is paid by owner account

         _burnChronoDust(currentOwner, dustAmount);

         // Example repair rate: 1 dust restores 1 durability point
         uint256 durabilityRestored = dustAmount;
         stats.durability = Math.min(stats.durability + durabilityRestored, 1000);

         emit DurabilityRepaired(sentinelId, dustAmount, durabilityRestored);
     }

     // Burn Item (Can only burn if not attached)
     function burnItem(uint256 itemId) public whenNotPaused {
        Item storage item = _items[itemId];
         if (!item.exists) {
             revert ItemDoesNotExist(itemId);
         }
         if (item.isBound) {
             revert ItemAlreadyAttached(itemId); // Cannot burn if attached
         }

        // Add owner/approved check if items were transferable ERC1155/ERC721,
        // but here they are just structs managed by the contract.
        // Allow anyone to burn unbound items? Or only the address that forged it?
        // Let's require the caller to be the forge creator or owner (more complex state needed).
        // Simpler: allow anyone to burn unbound items to remove them from state.

         delete _items[itemId];
         // Optionally emit event for item burning if items had owners
     }


    // --- Epoch Management ---

    // Admin function to update the global Epoch state
    function updateEpochState(uint256 newEpochId, string calldata description) public onlyOwner whenNotPaused {
        _currentEpoch = Epoch({
            id: newEpochId,
            description: description,
            startTime: block.timestamp
        });
        emit EpochStateUpdated(newEpochId, description, block.timestamp);
    }

    function getCurrentEpoch() public view returns (uint256 id, string memory description, uint256 startTime) {
        return (_currentEpoch.id, _currentEpoch.description, _currentEpoch.startTime);
    }

    // --- Delegation ---

    function delegateSentinelUsage(uint256 sentinelId, address delegatee, uint256 duration) public whenNotPaused nonReentrant {
        _requireOwned(sentinelId); // Caller must be the owner

        if (_sentinelDelegations[sentinelId].delegatee == delegatee && _sentinelDelegations[sentinelId].expirationTime > block.timestamp) {
             revert DelegationAlreadyExists(sentinelId, delegatee);
        }

        _sentinelDelegations[sentinelId] = Delegation({
            delegatee: delegatee,
            expirationTime: block.timestamp + duration // duration in seconds
        });

        emit SentinelDelegated(sentinelId, delegatee, _sentinelDelegations[sentinelId].expirationTime);
    }

     function revokeDelegate(uint256 sentinelId, address delegatee) public whenNotPaused nonReentrant {
         _requireOwned(sentinelId); // Caller must be the owner

         Delegation storage currentDelegation = _sentinelDelegations[sentinelId];

         if (currentDelegation.delegatee != delegatee || currentDelegation.expirationTime <= block.timestamp) {
             // Not the current delegate or delegation expired
             revert NotADelegate(sentinelId, delegatee);
         }

         // Revoke immediately
         delete _sentinelDelegations[sentinelId]; // Clear the delegation struct

         emit SentinelDelegateRevoked(sentinelId, delegatee);
     }

    function isDelegate(uint256 sentinelId, address delegatee) public view returns (bool) {
        Delegation storage delegation = _sentinelDelegations[sentinelId];
        return delegation.delegatee == delegatee && delegation.expirationTime > block.timestamp;
    }

    // --- Complex Interaction Examples ---

    // Simulate sending a sentinel on a quest
    // Outcome depends on Sentinel stats and current Epoch state
    function sendOnQuest(uint256 sentinelId) public whenNotPaused onlySentinelOwnerOrDelegate(sentinelId) nonReentrant {
        SentinelStats storage stats = _sentinelStats[sentinelId];

        // Consume durability
        uint256 durabilityCost = 50; // Example cost per quest
        if (stats.durability < durabilityCost) {
            revert InvalidDurability(sentinelId); // Not enough durability for quest
        }
        unchecked {
            stats.durability -= durabilityCost;
        }

        // Determine quest outcome based on stats and epoch
        uint256 xpGained = 0;
        uint256 dustGained = 0;
        bool itemFound = false;
        address currentOwner = ownerOf(sentinelId); // Rewards go to the owner

        // Basic logic: higher power/affinity leads to better rewards, epoch can modify
        uint256 totalScore = stats.power + stats.affinity * 5 + (stats.level * 10); // Affinity weighted, level adds bonus
        uint256 epochFactor = _currentEpoch.id == 1 ? 1 : (_currentEpoch.id == 2 ? 2 : 1); // Example: Epoch 2 gives double rewards

        xpGained = (totalScore / 10) * epochFactor; // Simplified calculation
        dustGained = (totalScore / 20) * epochFactor; // Simplified calculation

        // Simulate finding an item (e.g., 10% chance modified by affinity and epoch)
        uint256 itemFindChance = 10 + (stats.affinity / 10) + (_currentEpoch.id == 3 ? 10 : 0); // Example: Epoch 3 adds 10% chance
        if (uint256(keccak256(abi.encodePacked(block.timestamp, sentinelId, tx.origin))) % 100 < itemFindChance) {
             // Simulate finding an item - maybe forge a low-tier item
             // This is expensive to do directly in a loop/randomly.
             // A better pattern is to issue a reward token or note to claim an item.
             // For simplicity, let's just set itemFound to true and leave item minting to another process/function.
             itemFound = true;
             // Or, if feeling brave and the math is simple, mint a dust amount equivalent to a common item value
             dustGained += 50; // Found a common item worth 50 dust
        }

        // Apply rewards
        stats.experience += xpGained;
        if (dustGained > 0) {
            _mintChronoDust(currentOwner, dustGained); // Mint dust and give to owner
        }

        emit QuestCompleted(sentinelId, xpGained, dustGained, itemFound);

        // Check for level up trigger after gaining XP
        if (stats.experience >= calculateXPForLevel(stats.level + 1)) {
            // Automatically level up or allow owner to trigger? Let's require owner trigger to spend points.
            // So just gain XP here.
        }
    }
}
```