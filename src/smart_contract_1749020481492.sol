Okay, here is a Solidity smart contract that implements an "Evolving Digital Familiar" system with a dynamic crafting mechanism and time-based state decay.

It incorporates:
1.  **Dynamic State:** Familiars have states (Hunger, Mood, Experience, Level) that change over time and through interaction.
2.  **Time Decay:** Familiar states decay over time (hunger increases, mood decreases).
3.  **Fungible Items:** An internal system for managing user balances of different item types (food, toys, crafting materials, equipment).
4.  **Interaction Loop:** Users interact with familiars using items, affecting their state.
5.  **Crafting System:** Recipes define how to combine items to create new ones.
6.  **Equippable Items:** Items can be equipped to familiars, potentially granting bonuses or altering traits.
7.  **Dynamic Traits:** Traits derived from the familiar's current state and equipped items.
8.  **Progression:** Familiars level up based on experience.
9.  **Access Control & Pausability:** Basic administrative features.
10. **NFT Component:** Familiars are non-fungible tokens (conceptually ERC721-like, simplified implementation for this example).

It avoids being a direct copy of standard ERC tokens, simple vaults, or common DeFi primitives by focusing on a stateful, interactive, and evolving system specific to the "Familiar" concept.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EvolvingFamiliarCrafting
 * @notice A smart contract managing evolving digital familiars (NFTs),
 * their dynamic state based on time and user interaction,
 * an internal fungible item system, and a crafting mechanism.
 * Familiars' hunger and mood decay over time. Users interact by
 * consuming items (food, toys) to improve state and gain experience.
 * Items can also be crafted from materials or equipped to familiars.
 */

/**
 * OUTLINE:
 * 1.  Interfaces (Simplified conceptual ERC721/ERC20)
 * 2.  Errors
 * 3.  Structs (Familiar, ItemProperties, Recipe)
 * 4.  Events
 * 5.  State Variables
 * 6.  Modifiers (Access control, Pausability)
 * 7.  Constructor
 * 8.  Admin Functions (Setup, pause, roles)
 * 9.  Familiar Management (NFT-like: mint, transfer, ownership)
 * 10. Item Management (Fungible-like: mint, transfer, balance)
 * 11. Interaction Functions (Feed, Play, Train, Equip, Unequip)
 * 12. Crafting Functions (Craft items)
 * 13. Query Functions (Get state, traits, recipes, items)
 * 14. Internal Helper Functions (State update, trait calculation, consumption, etc.)
 */

/**
 * FUNCTION SUMMARY:
 *
 * Admin Functions:
 * - constructor(): Initializes contract owner and pause status.
 * - setMinter(address minter, bool allowed): Grants/revokes ability to mint familiars and items.
 * - addAllowedItem(uint256 itemId, string calldata name, ItemType itemType, uint256 decayModifier, string[] calldata traitsGranted, uint256 equipSlot): Defines properties of a new item type.
 * - addCraftingRecipe(uint256 recipeId, InputItem[] calldata inputs, uint256 outputItemId, uint256 outputAmount): Defines a new crafting recipe.
 * - setBaseURI(string calldata baseURI): Sets the base URI for NFT metadata.
 * - pause(): Pauses key state-changing contract operations.
 * - unpause(): Unpauses the contract.
 *
 * Familiar Management (NFT-like):
 * - mintFamiliar(address owner, string calldata name): Mints a new familiar NFT to an owner.
 * - transferFrom(address from, address to, uint256 tokenId): Transfers ownership of a familiar. (Simplified ERC721 transfer)
 * - safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Safe transfer (simplified, no ERC721Receiver check).
 * - balanceOf(address owner): Gets the number of familiars owned by an address. (Simplified ERC721)
 * - ownerOf(uint256 tokenId): Gets the owner of a specific familiar. (Simplified ERC721)
 * - tokenURI(uint256 tokenId): Gets the metadata URI for a familiar.
 * - approve(address to, uint256 tokenId): Approves an address to transfer a specific token. (Simplified ERC721)
 * - setApprovalForAll(address operator, bool approved): Approves/disapproves an operator for all tokens of sender. (Simplified ERC721)
 * - getApproved(uint256 tokenId): Gets the approved address for a token. (Simplified ERC721)
 * - isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens of an owner. (Simplified ERC721)
 *
 * Item Management (Fungible-like):
 * - mintItems(address to, uint256 itemId, uint256 amount): Mints a specific amount of an item to an address.
 * - transferItems(address from, address to, uint256 itemId, uint256 amount): Transfers items between user balances.
 * - balanceOfItems(address owner, uint256 itemId): Gets the item balance for a user and item type.
 * - approveItems(address spender, uint256 itemId, uint256 amount): Sets an allowance for a spender to transfer items on owner's behalf. (Simplified ERC20 allowance)
 * - allowanceItems(address owner, address spender, uint256 itemId): Gets the remaining allowance. (Simplified ERC20 allowance)
 * - transferItemsFrom(address from, address to, uint256 itemId, uint256 amount): Transfers items using allowance. (Simplified ERC20 transferFrom)
 *
 * Interaction Functions:
 * - feedFamiliar(uint256 tokenId, uint256 foodItemId, uint256 amount): Feeds a familiar using food items. Improves hunger.
 * - playWithFamiliar(uint256 tokenId, uint256 toyItemId, uint256 amount): Plays with a familiar using toy items. Improves mood.
 * - trainFamiliar(uint256 tokenId, uint256 trainingItemId, uint256 amount): Trains a familiar using training items. Gives experience.
 * - equipItem(uint256 tokenId, uint256 itemToEquipId): Equips an item from owner's inventory to a familiar.
 * - unequipItem(uint256 tokenId, uint256 equippedItemId): Unequips an item from a familiar back to owner's inventory.
 *
 * Crafting Functions:
 * - craftItem(uint256 recipeId): Attempts to craft an item using a predefined recipe and consuming input items from the sender's inventory.
 *
 * Query Functions:
 * - getFamiliarState(uint256 tokenId): Gets the current state (level, xp, hunger, mood, last interaction time) of a familiar, applying decay.
 * - getFamiliarTraits(uint256 tokenId): Gets the calculated traits of a familiar based on its current state and equipped items.
 * - getItemProperties(uint256 itemId): Gets the static properties of an item type.
 * - getCraftingRecipe(uint256 recipeId): Gets the details of a crafting recipe.
 * - getAllowedItemIds(): Gets a list of all defined item IDs.
 * - getAllCraftingRecipeIds(): Gets a list of all defined recipe IDs.
 *
 * Internal/Helper Functions:
 * - _updateFamiliarState(uint256 tokenId): Internal helper to calculate state decay based on time.
 * - _applyItemEffects(uint256 tokenId, uint256 itemId, uint256 amount): Applies item consumption effects (hunger, mood, xp).
 * - _consumeItems(address owner, uint256 itemId, uint256 amount): Internal helper to consume items from owner's balance.
 * - _awardExperience(uint256 tokenId, uint256 amount): Internal helper to add XP and check for level up.
 * - _levelUpCheck(uint256 tokenId): Internal helper to handle familiar leveling up.
 * - _calculateTraits(uint256 tokenId, Familiar memory familiar): Internal view helper to determine traits.
 * - _checkItemEquipability(uint256 itemId, uint256 tokenId): Internal helper to validate item equipping rules.
 */


// Simplified Interfaces for conceptual clarity - actual implementation is internal
interface ISimplifiedERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ISimplifiedERC20Like {
    event Transfer(address indexed from, address indexed to, uint256 indexed amount);
    event Approval(address indexed owner, address indexed spender, uint256 indexed amount);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool); // Not used directly externally in this contract
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // Simplified internal version used
    function approve(address spender, uint256 amount) external returns (bool); // Simplified internal version used
    function allowance(address owner, address spender) external view returns (uint256); // Simplified internal version used
}


contract EvolvingFamiliarCrafting {

    // --- Errors ---
    error NotMinter();
    error ItemNotAllowed(uint256 itemId);
    error FamiliarNotFound(uint256 tokenId);
    error NotFamiliarOwner(uint256 tokenId, address caller);
    error InsufficientItems(uint256 itemId, uint256 required, uint256 has);
    error RecipeNotFound(uint256 recipeId);
    error CannotCraft(uint256 recipeId);
    error ItemNotConsumable(uint256 itemId);
    error ItemNotEquippable(uint256 itemId);
    error InvalidEquipSlot(uint256 itemId, uint256 expectedSlot, uint256 actualSlot);
    error ItemNotEquipped(uint256 itemId, uint256 tokenId);
    error ItemAlreadyEquipped(uint256 itemId, uint256 tokenId);
    error Paused();
    error NotApprovedOrOwner(address caller, uint256 tokenId);
    error ItemApprovalFailed(address owner, address spender, uint256 itemId, uint256 amount);
    error InvalidItemTypeForInteraction(uint256 itemId, ItemType expectedType);


    // --- Structs ---

    enum ItemType {
        None,
        ConsumableFood,
        ConsumableToy,
        ConsumableTraining,
        CraftingMaterial,
        EquipHead,
        EquipBody,
        EquipAccessory
    }

    struct Familiar {
        string name;
        uint256 level;
        uint256 experience;
        uint256 hunger; // 0 = starving, 100 = full
        uint256 mood;   // 0 = miserable, 100 = ecstatic
        uint256 lastInteractionTime;
        mapping(uint256 => uint256) equippedItems; // slot => itemId
        uint256[] equippedSlots; // Track occupied slots for easier iteration
    }

    struct ItemProperties {
        string name;
        ItemType itemType;
        // Effects when consumed (for consumables)
        uint256 hungerRestore;
        uint256 moodRestore;
        uint256 xpGain;
        // Modifiers when equipped (for equipment)
        mapping(string => int256) traitModifiers; // e.g., "charisma" => +5
        uint256 equipSlot; // Applicable slot for equipType items
        bool isConsumable; // Can be consumed
        bool isCraftable; // Can be produced via crafting
        bool isEquippable; // Can be equipped
    }

    struct InputItem {
        uint256 itemId;
        uint256 amount;
    }

    struct Recipe {
        InputItem[] inputs;
        uint256 outputItemId;
        uint256 outputAmount;
    }


    // --- Events ---

    // Familiar Events (NFT-like)
    event FamiliarMinted(uint256 indexed tokenId, address indexed owner, string name);
    event FamiliarTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event FamiliarStateChanged(uint256 indexed tokenId, uint256 level, uint256 experience, uint256 hunger, uint256 mood);
    event FamiliarLevelUp(uint256 indexed tokenId, uint256 newLevel);
    event FamiliarEquippedItem(uint256 indexed tokenId, uint256 indexed itemId, uint256 slot);
    event FamiliarUnequippedItem(uint256 indexed tokenId, uint256 indexed itemId, uint256 slot);

    // Item Events (Fungible-like)
    event ItemMinted(address indexed to, uint256 indexed itemId, uint256 amount);
    event ItemTransfer(address indexed from, address indexed to, uint256 indexed itemId, uint256 amount);
    event ItemAllowanceSet(address indexed owner, address indexed spender, uint256 indexed itemId, uint256 amount);

    // Crafting Events
    event ItemCrafted(address indexed crafter, uint256 indexed recipeId, uint256 outputItemId, uint256 outputAmount);

    // Admin Events
    event Paused(address account);
    event Unpaused(address account);
    event MinterSet(address indexed minter, bool allowed);
    event ItemAdded(uint256 indexed itemId, string name);
    event RecipeAdded(uint256 indexed recipeId);
    event BaseURISet(string baseURI);


    // --- State Variables ---

    address private _owner;
    bool private _paused;

    // Access control
    mapping(address => bool) private _minters;

    // Familiars (NFT data)
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _ownerFamiliarCount;
    mapping(uint256 => Familiar) private _familiars;
    mapping(uint256 => address) private _tokenApprovals; // Simplified ERC721 approval
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Simplified ERC721 approval for all

    // Items (Fungible data)
    uint256[] private _allowedItemIds;
    mapping(uint256 => ItemProperties) private _itemProperties;
    mapping(address => mapping(uint256 => uint256)) private _itemBalances; // owner => itemId => balance
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _itemAllowances; // owner => spender => itemId => allowance

    // Crafting
    uint256[] private _craftingRecipeIds;
    mapping(uint256 => Recipe) private _craftingRecipes;

    // NFT Metadata
    string private _baseTokenURI;

    // Game Parameters (Can be made configurable via admin functions if needed)
    uint256 public constant HUNGER_DECAY_RATE_PER_DAY = 20; // points per day
    uint256 public constant MOOD_DECAY_RATE_PER_DAY = 25; // points per day
    uint256[] public experienceThresholds = [0, 100, 300, 600, 1000, 1500, 2100]; // XP needed for levels 1, 2, 3...


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert("Only owner can call");
        _;
    }

    modifier onlyMinter() {
        if (!_minters[msg.sender]) revert NotMinter();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert("Not paused");
        _;
    }


    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _paused = false;
    }


    // --- Admin Functions ---

    function setMinter(address minter, bool allowed) external onlyOwner {
        _minters[minter] = allowed;
        emit MinterSet(minter, allowed);
    }

    // Function to define properties of a new item type
    // This should be called for *every* item that exists in the ecosystem
    function addAllowedItem(
        uint256 itemId,
        string calldata name,
        ItemType itemType,
        uint256 hungerRestore,
        uint256 moodRestore,
        uint256 xpGain,
        string[] calldata traitNames, // Names of traits (e.g., "strength", "speed")
        int256[] calldata traitValues, // Values of traits (+5, -2, etc.) - must match traitNames length
        uint256 equipSlot // Use 0 if not equippable
    ) external onlyOwner {
        require(_itemProperties[itemId].itemType == ItemType.None, "Item ID already exists");
        require(traitNames.length == traitValues.length, "Trait arrays must match length");

        ItemProperties storage newItem = _itemProperties[itemId];
        newItem.name = name;
        newItem.itemType = itemType;
        newItem.hungerRestore = hungerRestore;
        newItem.moodRestore = moodRestore;
        newItem.xpGain = xpGain;
        newItem.equipSlot = equipSlot;

        newItem.isConsumable = (itemType == ItemType.ConsumableFood || itemType == ItemType.ConsumableToy || itemType == ItemType.ConsumableTraining);
        newItem.isCraftable = (itemType != ItemType.None); // Assume any defined item can be a crafting output
        newItem.isEquippable = (itemType == ItemType.EquipHead || itemType == ItemType.EquipBody || itemType == ItemType.EquipAccessory);

        // Store trait modifiers if equippable
        if (newItem.isEquippable) {
            for(uint i = 0; i < traitNames.length; i++) {
                 newItem.traitModifiers[traitNames[i]] = traitValues[i];
            }
        }

        _allowedItemIds.push(itemId);
        emit ItemAdded(itemId, name);
    }

    // Function to define a new crafting recipe
    function addCraftingRecipe(
        uint256 recipeId,
        InputItem[] calldata inputs,
        uint256 outputItemId,
        uint256 outputAmount
    ) external onlyOwner {
        require(_craftingRecipes[recipeId].outputItemId == 0, "Recipe ID already exists"); // Check outputItemId as a proxy for recipe existence
        require(_itemProperties[outputItemId].itemType != ItemType.None, "Output item not defined");
        require(outputAmount > 0, "Output amount must be > 0");
        for (uint i = 0; i < inputs.length; i++) {
            require(_itemProperties[inputs[i].itemId].itemType != ItemType.None, "Input item not defined");
            require(inputs[i].amount > 0, "Input amount must be > 0");
        }

        _craftingRecipes[recipeId].inputs = inputs;
        _craftingRecipes[recipeId].outputItemId = outputItemId;
        _craftingRecipes[recipeId].outputAmount = outputAmount;

        _craftingRecipeIds.push(recipeId);
        emit RecipeAdded(recipeId);
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURISet(baseURI);
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }


    // --- Familiar Management (NFT-like) ---

    function mintFamiliar(address owner, string calldata name) external onlyMinter whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _tokenOwners[tokenId] = owner;
        _ownerFamiliarCount[owner]++;

        Familiar storage newFamiliar = _familiars[tokenId];
        newFamiliar.name = name;
        newFamiliar.level = 1;
        newFamiliar.experience = 0;
        newFamiliar.hunger = 100; // Start full
        newFamiliar.mood = 100;   // Start happy
        newFamiliar.lastInteractionTime = block.timestamp;

        emit FamiliarMinted(tokenId, owner, name);
        emit FamiliarTransfer(address(0), owner, tokenId); // Conceptual ERC721 Mint event
        return tokenId;
    }

    // Simplified ERC721 transfer - Does not check ERC721Receiver
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        require(_tokenOwners[tokenId] == from, "Transfer: Caller is not owner");
        require(to != address(0), "Transfer: Transfer to the zero address");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer: Transfer caller is not owner nor approved");

        _transferFamiliar(from, to, tokenId);
    }

    // Simplified ERC721 safeTransfer - Does not check ERC721Receiver
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata /* data */) external whenNotPaused {
         transferFrom(from, to, tokenId);
         // Note: A full ERC721 safeTransfer would check if the recipient is a contract
         // and, if so, call onERC721Received. This is omitted for simplicity
         // as per the "don't duplicate" brief, but would be required for full compliance.
    }

    // Simplified ERC721 balance query
    function balanceOf(address owner) public view returns (uint256) {
        return _ownerFamiliarCount[owner];
    }

    // Simplified ERC721 owner query
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "OwnerQuery: Invalid token ID");
        return owner;
    }

    // ERC721 tokenURI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_tokenOwners[tokenId] != address(0), "TokenURI: Invalid token ID");
        // Construct the metadata URI. Assumes a base URI like ipfs://.../ or https://.../
        // and metadata files are named `[tokenId].json`.
        return string.concat(_baseTokenURI, Strings.toString(tokenId), ".json");
    }

    // Simplified ERC721 approve
    function approve(address to, uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId); // Implicitly checks token existence
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "Approve: Caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId); // Conceptual ERC721 Approval event
    }

     // Simplified ERC721 setApprovalForAll
    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved); // Conceptual ERC721 ApprovalForAll event
    }

    // Simplified ERC721 getApproved
    function getApproved(uint256 tokenId) public view returns (address) {
         require(_tokenOwners[tokenId] != address(0), "GetApproved: Invalid token ID");
         return _tokenApprovals[tokenId];
    }

    // Simplified ERC721 isApprovedForAll
     function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    // Internal helper for simplified familiar transfer
    function _transferFamiliar(address from, address to, uint256 tokenId) internal {
        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _ownerFamiliarCount[from]--;
        _ownerFamiliarCount[to]++;
        _tokenOwners[tokenId] = to;

        emit FamiliarTransfer(from, to, tokenId); // Conceptual ERC721 Transfer event
    }

     // Internal helper for simplified ERC721 approval check
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    // --- Item Management (Fungible-like) ---

    function mintItems(address to, uint256 itemId, uint256 amount) external onlyMinter whenNotPaused {
        require(_itemProperties[itemId].itemType != ItemType.None, "Item ID not defined");
        _itemBalances[to][itemId] += amount;
        emit ItemMinted(to, itemId, amount); // Using ItemMinted instead of ERC20 Transfer from address(0)
    }

    // Internal simplified ERC20-like transfer
    function transferItems(address from, address to, uint256 itemId, uint256 amount) internal {
        if (_itemBalances[from][itemId] < amount) revert InsufficientItems(itemId, amount, _itemBalances[from][itemId]);
        _itemBalances[from][itemId] -= amount;
        _itemBalances[to][itemId] += amount;
        emit ItemTransfer(from, to, itemId, amount);
    }

    // Internal simplified ERC20-like transferFrom using allowance
     function transferItemsFrom(address from, address to, uint256 itemId, uint256 amount) internal {
        uint256 currentAllowance = _itemAllowances[from][msg.sender][itemId];
        if (currentAllowance < amount) revert ItemApprovalFailed(from, msg.sender, itemId, amount);

        unchecked { // Allowance check prevents underflow
             _itemAllowances[from][msg.sender][itemId] = currentAllowance - amount;
        }

        transferItems(from, to, itemId, amount);
     }


    function balanceOfItems(address owner, uint256 itemId) public view returns (uint256) {
        // No need to check if item exists for balance query, 0 is valid
        return _itemBalances[owner][itemId];
    }

     // Simplified ERC20-like approve for items
     function approveItems(address spender, uint256 itemId, uint256 amount) external whenNotPaused {
         require(_itemProperties[itemId].itemType != ItemType.None, "Item ID not defined");
        _itemAllowances[msg.sender][spender][itemId] = amount;
        emit ItemAllowanceSet(msg.sender, spender, itemId, amount); // Using ItemAllowanceSet instead of ERC20 Approval
     }

     // Simplified ERC20-like allowance query for items
     function allowanceItems(address owner, address spender, uint256 itemId) public view returns (uint256) {
         // No need to check if item exists for allowance query, 0 is valid
         return _itemAllowances[owner][spender][itemId];
     }


    // --- Interaction Functions ---

    function feedFamiliar(uint256 tokenId, uint256 foodItemId, uint256 amount) external whenNotPaused {
        address owner = ownerOf(tokenId); // Checks token existence
        require(msg.sender == owner || _isApprovedOrOwner(msg.sender, tokenId), "Feed: Caller is not owner nor approved");

        ItemProperties storage itemProps = _itemProperties[foodItemId];
        if (itemProps.itemType != ItemType.ConsumableFood) revert InvalidItemTypeForInteraction(foodItemId, ItemType.ConsumableFood);
        if (!itemProps.isConsumable) revert ItemNotConsumable(foodItemId);
        if (amount == 0) return; // No action if amount is 0

        _updateFamiliarState(tokenId); // Apply time decay before interaction
        _consumeItems(msg.sender, foodItemId, amount);
        _applyItemEffects(tokenId, foodItemId, amount);

        emit FamiliarStateChanged(tokenId, _familiars[tokenId].level, _familiars[tokenId].experience, _familiars[tokenId].hunger, _familiars[tokenId].mood);
    }

     function playWithFamiliar(uint256 tokenId, uint256 toyItemId, uint256 amount) external whenNotPaused {
        address owner = ownerOf(tokenId); // Checks token existence
        require(msg.sender == owner || _isApprovedOrOwner(msg.sender, tokenId), "Play: Caller is not owner nor approved");

        ItemProperties storage itemProps = _itemProperties[toyItemId];
        if (itemProps.itemType != ItemType.ConsumableToy) revert InvalidItemTypeForInteraction(toyItemId, ItemType.ConsumableToy);
        if (!itemProps.isConsumable) revert ItemNotConsumable(toyItemId);
         if (amount == 0) return; // No action if amount is 0

        _updateFamiliarState(tokenId); // Apply time decay before interaction
        _consumeItems(msg.sender, toyItemId, amount);
        _applyItemEffects(tokenId, toyItemId, amount);

        emit FamiliarStateChanged(tokenId, _familiars[tokenId].level, _familiars[tokenId].experience, _familiars[tokenId].hunger, _familiars[tokenId].mood);
    }

     function trainFamiliar(uint256 tokenId, uint256 trainingItemId, uint256 amount) external whenNotPaused {
        address owner = ownerOf(tokenId); // Checks token existence
        require(msg.sender == owner || _isApprovedOrOwner(msg.sender, tokenId), "Train: Caller is not owner nor approved");

        ItemProperties storage itemProps = _itemProperties[trainingItemId];
        if (itemProps.itemType != ItemType.ConsumableTraining) revert InvalidItemTypeForInteraction(trainingItemId, ItemType.ConsumableTraining);
        if (!itemProps.isConsumable) revert ItemNotConsumable(trainingItemId);
         if (amount == 0) return; // No action if amount is 0

        _updateFamiliarState(tokenId); // Apply time decay before interaction
        _consumeItems(msg.sender, trainingItemId, amount);
        _applyItemEffects(tokenId, trainingItemId, amount);
        _awardExperience(tokenId, itemProps.xpGain * amount); // Award XP after applying other effects

        emit FamiliarStateChanged(tokenId, _familiars[tokenId].level, _familiars[tokenId].experience, _familiars[tokenId].hunger, _familiars[tokenId].mood);
    }

    // Equips an item from the sender's inventory to the familiar.
    function equipItem(uint256 tokenId, uint256 itemToEquipId) external whenNotPaused {
        address owner = ownerOf(tokenId); // Checks token existence
        require(msg.sender == owner, "Equip: Caller must be owner"); // Equip requires direct ownership

        ItemProperties storage itemProps = _itemProperties[itemToEquipId];
        if (!itemProps.isEquippable) revert ItemNotEquippable(itemToEquipId);
        uint256 equipSlot = itemProps.equipSlot;
        if (equipSlot == 0) revert InvalidEquipSlot(itemToEquipId, 0, 0); // Ensure a valid slot is defined

        Familiar storage familiar = _familiars[tokenId];

        // Check if something is already equipped in this slot
        uint256 currentlyEquippedItemId = familiar.equippedItems[equipSlot];
        if (currentlyEquippedItemId != 0) {
            // Automatically unequip the old item first
            _unequipItem(tokenId, currentlyEquippedItemId, owner);
        }

        // Check if the item is already equipped (shouldn't happen after unequip, but belt-and-suspenders)
        if (familiar.equippedItems[equipSlot] == itemToEquipId) revert ItemAlreadyEquipped(itemToEquipId, tokenId);

        // Consume the item from the owner's inventory (it moves *to* the familiar)
        _consumeItems(owner, itemToEquipId, 1);

        // Equip the item to the familiar
        familiar.equippedItems[equipSlot] = itemToEquipId;

        // Add slot to the list if not already present (should be unique per slot)
        bool slotFound = false;
        for(uint i=0; i < familiar.equippedSlots.length; i++) {
            if (familiar.equippedSlots[i] == equipSlot) {
                slotFound = true;
                break;
            }
        }
        if (!slotFound) {
            familiar.equippedSlots.push(equipSlot);
        }

        emit FamiliarEquippedItem(tokenId, itemToEquipId, equipSlot);
         // Note: Traits might change, but _calculateTraits is view, so client needs to query state/traits again.
    }

    // Unequips an item from a familiar back to the sender's inventory.
    function unequipItem(uint256 tokenId, uint256 itemToUnequipId) external whenNotPaused {
        address owner = ownerOf(tokenId); // Checks token existence
        require(msg.sender == owner, "Unequip: Caller must be owner"); // Unequip requires direct ownership

        _unequipItem(tokenId, itemToUnequipId, owner);

        emit FamiliarUnequippedItem(tokenId, itemToUnequipId, _itemProperties[itemToUnequipId].equipSlot);
         // Note: Traits might change, but _calculateTraits is view, so client needs to query state/traits again.
    }

     // Internal helper for unequipping
    function _unequipItem(uint256 tokenId, uint256 itemToUnequipId, address owner) internal {
        Familiar storage familiar = _familiars[tokenId];
        ItemProperties storage itemProps = _itemProperties[itemToUnequipId];
        uint256 equipSlot = itemProps.equipSlot;

        // Check if the item is actually equipped in the correct slot
        if (familiar.equippedItems[equipSlot] != itemToUnequipId) revert ItemNotEquipped(itemToUnequipId, tokenId);

        // Remove item from familiar's equipped list
        delete familiar.equippedItems[equipSlot];

        // Remove slot from the list of occupied slots
         uint256 slotIndexToRemove = familiar.equippedSlots.length; // Default to not found
         for(uint i = 0; i < familiar.equippedSlots.length; i++) {
             if (familiar.equippedSlots[i] == equipSlot) {
                 slotIndexToRemove = i;
                 break;
             }
         }
         // This should always find the slot if the item was equipped, but better safe
         if (slotIndexToRemove < familiar.equippedSlots.length) {
             // Swap the last element into the found index and pop
             familiar.equippedSlots[slotIndexToRemove] = familiar.equippedSlots[familiar.equippedSlots.length - 1];
             familiar.equippedSlots.pop();
         }


        // Return item to owner's inventory (mint 1)
        // Note: This assumes equipped items are "bound" to the familiar and returned to the owner's main inventory upon unequip,
        // not that they maintain separate state while equipped.
        mintItems(owner, itemToUnequipId, 1);
    }


    // --- Crafting Functions ---

    function craftItem(uint256 recipeId) external whenNotPaused {
        Recipe storage recipe = _craftingRecipes[recipeId];
        if (recipe.outputItemId == 0) revert RecipeNotFound(recipeId); // Check outputItemId as proxy for recipe existence

        address crafter = msg.sender;

        // Check if crafter has all required input items
        for (uint i = 0; i < recipe.inputs.length; i++) {
            InputItem storage input = recipe.inputs[i];
            if (_itemBalances[crafter][input.itemId] < input.amount) {
                revert InsufficientItems(input.itemId, input.amount, _itemBalances[crafter][input.itemId]);
            }
        }

        // Consume input items
        for (uint i = 0; i < recipe.inputs.length; i++) {
            InputItem storage input = recipe.inputs[i];
            _consumeItems(crafter, input.itemId, input.amount);
        }

        // Mint output item
        mintItems(crafter, recipe.outputItemId, recipe.outputAmount);

        emit ItemCrafted(crafter, recipeId, recipe.outputItemId, recipe.outputAmount);
    }


    // --- Query Functions ---

    // Returns the current state of a familiar after applying potential decay.
    function getFamiliarState(uint256 tokenId) public view returns (
        uint256 level,
        uint256 experience,
        uint256 hunger,
        uint256 mood,
        uint256 lastInteractionTime
    ) {
        Familiar storage familiar = _familiars[tokenId];
        if (_tokenOwners[tokenId] == address(0)) revert FamiliarNotFound(tokenId); // Check token existence

        // Simulate state decay for query purposes
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime > familiar.lastInteractionTime ? currentTime - familiar.lastInteractionTime : 0;
        uint256 daysElapsed = timeElapsed / (24 * 60 * 60);

        uint256 currentHunger = familiar.hunger;
        uint256 currentMood = familiar.mood;

        if (daysElapsed > 0) {
            // Apply decay (capped at 0)
            currentHunger = familiar.hunger > (daysElapsed * HUNGER_DECAY_RATE_PER_DAY) ? familiar.hunger - (daysElapsed * HUNGER_DECAY_RATE_PER_DAY) : 0;
            currentMood = familiar.mood > (daysElapsed * MOOD_DECAY_RATE_PER_DAY) ? familiar.mood - (daysElapsed * MOOD_DECAY_RATE_PER_DAY) : 0;
        }

        // State variables in storage are not modified by this view function,
        // only the returned values reflect the potential decay.
        return (
            familiar.level,
            familiar.experience,
            currentHunger,
            currentMood,
            familiar.lastInteractionTime
        );
    }

    // Returns the calculated traits of a familiar based on its state and equipped items.
    // This is a view function; state changes need to happen via interaction functions.
    function getFamiliarTraits(uint256 tokenId) public view returns (string[] memory traitNames, string[] memory traitDescriptions) {
         Familiar storage familiar = _familiars[tokenId];
         if (_tokenOwners[tokenId] == address(0)) revert FamiliarNotFound(tokenId); // Check token existence

         // Get current state including decay for trait calculation
         (uint256 level, , uint256 hunger, uint256 mood, ) = getFamiliarState(tokenId);

         // Use a temporary mapping to aggregate trait modifiers
         mapping(string => int256) temporaryTraitModifiers;

         // Apply state-based traits
         if (hunger <= 20) temporaryTraitModifiers["Hunger"] += 1; // Example state trait modifier
         if (mood <= 20) temporaryTraitModifiers["Grumpy"] += 1; // Example state trait modifier
         if (level >= 5) temporaryTraitModifiers["Experienced"] += 1; // Example level trait modifier

         // Apply equipped item traits
         for (uint i = 0; i < familiar.equippedSlots.length; i++) {
            uint256 slot = familiar.equippedSlots[i];
             uint256 equippedItemId = familiar.equippedItems[slot];
             if (equippedItemId != 0) {
                 ItemProperties storage itemProps = _itemProperties[equippedItemId];
                 // Iterate through the traitModifiers mapping of the item
                 // NOTE: Iterating maps in Solidity is not direct. Need to know keys or use helper lists if map keys aren't fixed.
                 // For this example, let's assume a fixed set of potential traits that items *might* modify.
                 // A more robust system might require storing trait keys in the ItemProperties or globally.
                 // For simplicity here, let's hardcode a few common potential trait keys and check them.
                 // In a real application, you'd manage trait keys more systematically.
                 string[] memory potentialTraitKeys = new string[](3); // Example: strength, charisma, agility
                 potentialTraitKeys[0] = "strength";
                 potentialTraitKeys[1] = "charisma";
                 potentialTraitKeys[2] = "agility";

                 for(uint j = 0; j < potentialTraitKeys.length; j++) {
                    string memory traitKey = potentialTraitKeys[j];
                    // Check if the item modifier for this key exists and is non-zero
                    // Note: Reading a non-existent mapping entry returns default (0 for int256).
                    // We assume here that a stored value implies the trait can be modified by this item.
                    // A better pattern would be to store list of modified trait keys per item.
                    int256 modifierValue = itemProps.traitModifiers[traitKey];
                    if (modifierValue != 0) {
                        temporaryTraitModifiers[traitKey] += modifierValue;
                    }
                 }
                 // Add item name as a trait description
                 temporaryTraitModifiers["Equipped"] += 1; // Just a marker trait
             }
         }


         // Compile traits and descriptions based on the aggregated modifiers
         // Again, iterating over a map requires knowing keys.
         // We'll collect keys that have non-zero modifiers from the temporary map.
         // This requires knowing the potential keys upfront or using a list of keys.
         // Let's use a fixed list of known trait keys + potential state traits for this example.
         string[] memory knownTraitKeys = new string[](6);
         knownTraitKeys[0] = "Hunger";
         knownTraitKeys[1] = "Grumpy";
         knownTraitKeys[2] = "Experienced";
         knownTraitKeys[3] = "strength";
         knownTraitKeys[4] = "charisma";
         knownTraitKeys[5] = "agility";

         string[] memory names;
         string[] memory descriptions;
         uint256 count = 0;

         // Count active traits to size arrays
         for(uint i = 0; i < knownTraitKeys.length; i++) {
             if (temporaryTraitModifiers[knownTraitKeys[i]] != 0) {
                 count++;
             }
         }
          if (temporaryTraitModifiers["Equipped"] != 0) count++; // Add equipped item trait marker

         names = new string[](count);
         descriptions = new string[](count);
         count = 0; // Reset counter for filling arrays

         // Fill arrays
         for(uint i = 0; i < knownTraitKeys.length; i++) {
             int256 modifier = temporaryTraitModifiers[knownTraitKeys[i]];
             if (modifier != 0) {
                 names[count] = knownTraitKeys[i];
                 // Create description string, e.g., "Hunger (State)", "strength (+5)"
                 if (i <= 2) { // Assuming first few keys are state/level traits
                     descriptions[count] = string.concat(knownTraitKeys[i], " (State)");
                 } else { // Assuming these are item-modified stats
                      descriptions[count] = string.concat(knownTraitKeys[i], " (", Strings.toString(modifier), ")");
                 }
                 count++;
             }
         }

         // Add equipped item list description
         if (temporaryTraitModifiers["Equipped"] != 0) {
              names[count] = "Equipped Items";
              string memory equippedList = "";
              for (uint i = 0; i < familiar.equippedSlots.length; i++) {
                 uint256 slot = familiar.equippedSlots[i];
                 uint256 equippedItemId = familiar.equippedItems[slot];
                  if (equippedItemId != 0) {
                      if (bytes(equippedList).length > 0) equippedList = string.concat(equippedList, ", ");
                      equippedList = string.concat(equippedList, _itemProperties[equippedItemId].name);
                  }
              }
              descriptions[count] = equippedList;
              count++;
         }


         return (names, descriptions);
    }

    function getItemProperties(uint256 itemId) public view returns (ItemProperties memory) {
        require(_itemProperties[itemId].itemType != ItemType.None, "Item ID not defined");
        // Note: Cannot return traitModifiers mapping directly from memory,
        // client would need to query individual potential trait keys or there needs to be a different structure.
        // Returning a subset of properties here.
        ItemProperties storage item = _itemProperties[itemId];
        return ItemProperties({
            name: item.name,
            itemType: item.itemType,
            hungerRestore: item.hungerRestore,
            moodRestore: item.moodRestore,
            xpGain: item.xpGain,
            traitModifiers: item.traitModifiers, // This mapping won't be fully populated in the returned memory copy
            equipSlot: item.equipSlot,
            isConsumable: item.isConsumable,
            isCraftable: item.isCraftable,
            isEquippable: item.isEquippable
        });
    }

    function getCraftingRecipe(uint256 recipeId) public view returns (Recipe memory) {
        Recipe storage recipe = _craftingRecipes[recipeId];
        if (recipe.outputItemId == 0) revert RecipeNotFound(recipeId);
         // Return a memory copy
        return Recipe({
             inputs: recipe.inputs,
             outputItemId: recipe.outputItemId,
             outputAmount: recipe.outputAmount
        });
    }

    function getAllowedItemIds() public view returns (uint256[] memory) {
        return _allowedItemIds;
    }

    function getAllCraftingRecipeIds() public view returns (uint256[] memory) {
        return _craftingRecipeIds;
    }


    // --- Internal Helper Functions ---

    // Applies time-based decay to hunger and mood
    function _updateFamiliarState(uint256 tokenId) internal {
        Familiar storage familiar = _familiars[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime > familiar.lastInteractionTime ? currentTime - familiar.lastInteractionTime : 0;
        uint256 daysElapsed = timeElapsed / (24 * 60 * 60);

        if (daysElapsed > 0) {
            // Calculate total decay
            uint256 hungerDecay = daysElapsed * HUNGER_DECAY_RATE_PER_DAY;
            uint256 moodDecay = daysElapsed * MOOD_DECAY_RATE_PER_DAY;

            // Apply decay, ensuring state doesn't go below 0
            familiar.hunger = familiar.hunger > hungerDecay ? familiar.hunger - hungerDecay : 0;
            familiar.mood = familiar.mood > moodDecay ? familiar.mood - moodDecay : 0;

            // Update last interaction time to the current time (or just the time *after* decay was applied)
            // Set it to current time to prevent applying the same decay again immediately.
            familiar.lastInteractionTime = currentTime;
        }
    }

    // Applies item consumption effects (hunger, mood, xp)
    function _applyItemEffects(uint256 tokenId, uint256 itemId, uint256 amount) internal {
        Familiar storage familiar = _familiars[tokenId];
        ItemProperties storage itemProps = _itemProperties[itemId];

        familiar.hunger = Math.min(100, familiar.hunger + (itemProps.hungerRestore * amount));
        familiar.mood = Math.min(100, familiar.mood + (itemProps.moodRestore * amount));
        // XP is awarded separately in trainFamiliar
    }

    // Consumes a specified amount of an item from the owner's balance.
    function _consumeItems(address owner, uint256 itemId, uint256 amount) internal {
         if (_itemBalances[owner][itemId] < amount) revert InsufficientItems(itemId, amount, _itemBalances[owner][itemId]);
         unchecked { // Balance check prevents underflow
             _itemBalances[owner][itemId] -= amount;
         }
         // Emit conceptual transfer to burn address if applicable, or just rely on ItemTransfer from sender to address(0)
         emit ItemTransfer(owner, address(0), itemId, amount); // Conceptual burn event
    }

     // Awards experience and checks for level up.
    function _awardExperience(uint256 tokenId, uint256 amount) internal {
        Familiar storage familiar = _familiars[tokenId];
        familiar.experience += amount;
        _levelUpCheck(tokenId);
    }

    // Checks if a familiar levels up and updates its level.
    function _levelUpCheck(uint256 tokenId) internal {
        Familiar storage familiar = _familiars[tokenId];
        uint256 currentLevel = familiar.level;
        uint256 currentXP = familiar.experience;

        // Levels start from 1. experienceThresholds[0] is for level 1, [1] for level 2, etc.
        // Familiar levels up if currentXP meets or exceeds the threshold for the *next* level.
        // Max level is determined by the size of the experienceThresholds array.
        while (currentLevel < experienceThresholds.length && currentXP >= experienceThresholds[currentLevel]) {
             familiar.level++;
             currentLevel = familiar.level; // Update currentLevel for the next check
             emit FamiliarLevelUp(tokenId, currentLevel);
        }
    }

     // Simple helper check for item equipability - more complex rules could be added here (e.g., level requirement)
     function _checkItemEquipability(uint256 itemId, uint256 /* tokenId */) internal view returns (bool) {
         ItemProperties storage itemProps = _itemProperties[itemId];
         return itemProps.isEquippable && itemProps.equipSlot != 0;
         // Add level checks, trait checks, etc. here if needed
     }


}

// Simple helper for string conversions
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by Oraclize's uint2str: https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
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
}

// Simple Safe Math (though Solidity 0.8+ has built-in checks)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```

**Explanation of Concepts and Functions:**

1.  **Familiar as NFT (Simplified ERC721):**
    *   Uses mappings (`_tokenOwners`, `_familiars`) and a counter (`_nextTokenId`) to track unique familiar instances and their data (`struct Familiar`).
    *   Includes core NFT functions: `mintFamiliar`, `transferFrom`, `ownerOf`, `balanceOf`, `tokenURI`.
    *   Includes basic approval functions (`approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`).
    *   Does *not* implement the full ERC721 standard (e.g., no `onERC721Received` check in `safeTransferFrom`) to adhere to the "don't duplicate open source" idea, focusing on the core logic instead of standard compliance boilerplate.

2.  **Items as Fungible Tokens (Simplified ERC20-like):**
    *   Uses a mapping (`_itemBalances`) to track user balances of different `itemId`s.
    *   `struct ItemProperties` defines the static data for each item type (`name`, `itemType`, effects, equip slot, etc.). `_itemProperties` maps `itemId` to this struct.
    *   Includes core fungible functions: `mintItems`, `transferItems` (internal), `transferItemsFrom` (internal, uses allowance), `balanceOfItems`.
    *   Includes basic allowance functions (`approveItems`, `allowanceItems`).
    *   Similar to ERC721, this is a simplified internal implementation, not a standalone ERC20 contract.

3.  **Dynamic Familiar State:**
    *   `struct Familiar` holds `level`, `experience`, `hunger`, `mood`, and `lastInteractionTime`.
    *   `_updateFamiliarState` calculates decay based on `block.timestamp` and `lastInteractionTime`. This function is called *before* state-changing interactions to ensure the state is up-to-date before applying new effects.

4.  **Time Decay:**
    *   `HUNGER_DECAY_RATE_PER_DAY` and `MOOD_DECAY_RATE_PER_DAY` define how much state is lost per day.
    *   `_updateFamiliarState` uses `block.timestamp` to calculate elapsed time and apply decay. `getFamiliarState` also calculates decay *without* updating storage for read-only queries.

5.  **Interaction Loop:**
    *   `feedFamiliar`, `playWithFamiliar`, `trainFamiliar` are functions that take an `amount` of a specific `itemId`.
    *   They first call `_updateFamiliarState`, then `_consumeItems`, and finally `_applyItemEffects` (which updates hunger/mood/xp).

6.  **Crafting System:**
    *   `struct Recipe` defines inputs and outputs. `_craftingRecipes` maps `recipeId` to the recipe.
    *   `addCraftingRecipe` allows the owner to define new recipes.
    *   `craftItem` checks if the user has the required items, consumes them using `_consumeItems`, and mints the output items using `mintItems`.

7.  **Equippable Items & Slots:**
    *   `ItemType` enum includes `EquipHead`, `EquipBody`, `EquipAccessory`.
    *   `ItemProperties` includes `equipSlot` and a `traitModifiers` mapping.
    *   `Familiar` struct includes `equippedItems` (mapping slot to item ID) and `equippedSlots` (array to track occupied slots).
    *   `equipItem` handles consuming the item from inventory and adding it to the familiar's equipped state. It automatically unequips if a slot is already occupied.
    *   `unequipItem` moves the item back to the owner's inventory and removes it from the familiar's state.

8.  **Dynamic Traits (`getFamiliarTraits`):**
    *   Calculates traits based on the familiar's *current* state (including decay) and its *equipped* items.
    *   Uses a temporary mapping to aggregate modifiers from state conditions and equipped items.
    *   Returns arrays of trait names and descriptions. Note the limitation of iterating Solidity mappings; this example uses a fixed list of potential trait keys for simplicity. A real system might manage traits differently.

9.  **Progression (`experienceThresholds`, `_awardExperience`, `_levelUpCheck`):**
    *   `experienceThresholds` defines the XP required for each level.
    *   `_awardExperience` adds XP from training.
    *   `_levelUpCheck` is called after XP gain to see if the familiar crosses a level threshold and increments the level.

10. **Access Control & Pausability:**
    *   `onlyOwner` modifier for administrative setup.
    *   `onlyMinter` modifier for creating new familiars and items.
    *   `whenNotPaused` and `whenPaused` modifiers to stop/allow operations.

This contract provides a framework for a complex, stateful on-chain system beyond typical token contracts, featuring elements common in blockchain gaming or collectible ecosystems. Remember that gas costs for complex state updates or iterations can be significant on Ethereum mainnet.