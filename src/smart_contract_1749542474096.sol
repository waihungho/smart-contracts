Okay, here is a Solidity smart contract concept called "CryptoCraft: Alchemist's Forge". It combines elements of item crafting, dynamic NFTs (items with properties), staking items for yield, upgrading/refining items, and incorporates mechanics like crafting success chance and item durability/blessings. It aims for complexity and uniqueness by integrating these features within a single contract ecosystem.

It leverages ERC-721 for unique Items and includes an ERC-20-like functionality for 'CraftingEssence' (ingredients), though it's defined internally to keep everything within one contract scope for this example.

**Outline:**

1.  **Contract Definition:** Inherits ERC721, Ownable, Pausable. Includes internal ERC20-like logic for `CraftingEssence`.
2.  **State Variables:**
    *   Token information (Names, Symbols for Item and Essence).
    *   Counters (Total items minted, recipe IDs).
    *   Mappings for Item properties (stats, rarity, type, etc.).
    *   Mappings for Crafting Recipes (ingredients needed, output, success chance).
    *   Mappings for Staking (item ID => staking info).
    *   Mappings for Blessings (item ID => expiration time).
    *   Ingredient balance mapping.
    *   Admin settings (Crafting fee, addresses).
3.  **Enums & Structs:**
    *   `ItemType` (Weapon, Armor, Accessory, Consumable).
    *   `Rarity` (Common, Rare, Epic, Legendary).
    *   `ItemProperties` (stats, type, rarity, upgrade level, durability, recipeSourceId).
    *   `IngredientRequirement` (Ingredient type/ID - simplified to 1 type here, quantity).
    *   `CraftingRecipe` (Required ingredients, resulting ItemType/Rarity, Base Stats range, Success Chance).
    *   `StakingInfo` (Staker address, Start time, Claimed amount).
4.  **Events:** For key actions (Crafted, Upgraded, Dismantled, Staked, Unstaked, RewardsClaimed, RecipeAdded, BlessingApplied, Reforged).
5.  **Modifiers:** Pausable, Ownable checks.
6.  **Internal ERC20-like Logic (`CraftingEssence`):** Basic `_mintEssence`, `_burnEssence`, `_transferEssence`, `_balanceOfEssence`, `_approveEssence`, `_allowanceEssence`.
7.  **Admin Functions:** Add/Update/Remove Recipes, Set Fees, Withdraw Fees, Pause/Unpause, Mint initial/event Ingredients.
8.  **Core User Functions:**
    *   Mint/Gather Ingredient (limited/event-based).
    *   Craft Item (uses ingredients, fees, success chance).
    *   Upgrade Item (uses ingredients/other items, modifies stats).
    *   Dismantle Item (burns item, returns some ingredients).
    *   Stake Item (locks item for yield).
    *   Unstake Item (unlocks item, calculates/transfers yield).
    *   Claim Staking Rewards (claims rewards without unstaking).
    *   Reforge Item (reroll certain stats).
    *   Combine Items (merge two items into one, burning source).
    *   Apply Blessing (adds temporary buff).
9.  **View Functions:** Get Item details, Get Recipe details, Get Staking info, Check Blessing expiration.
10. **Inherited ERC721 Functions:** (Standard transfer, approval, balance, owner functions - these add to the function count).

**Function Summary (at least 20 custom functions + inherited):**

*   **`constructor`**: Initializes the contract, names, symbols, owner.
*   **`mintInitialCraftingEssence(address _to, uint256 _amount)`**: (Admin) Mints initial supply of Crafting Essence.
*   **`addCraftingRecipe(IngredientRequirement[] calldata _requiredIngredients, ItemType _itemType, Rarity _rarity, uint16 _baseStrength, uint16 _baseIntelligence, uint16 _baseAgility, uint16 _durability, uint16 _successChanceBps)`**: (Admin) Adds a new recipe. `_successChanceBps` is in Basis Points (e.g., 8000 for 80%).
*   **`updateCraftingRecipe(uint256 _recipeId, IngredientRequirement[] calldata _requiredIngredients, ItemType _itemType, Rarity _rarity, uint16 _baseStrength, uint16 _baseIntelligence, uint16 _baseAgility, uint16 _durability, uint16 _successChanceBps)`**: (Admin) Updates an existing recipe.
*   **`removeCraftingRecipe(uint256 _recipeId)`**: (Admin) Marks a recipe as inactive.
*   **`setCraftingFee(uint256 _fee)`**: (Admin) Sets the fee (in wei) required per craft.
*   **`withdrawFees(address payable _to)`**: (Admin) Allows the owner to withdraw collected Ether fees.
*   **`craftItem(uint256 _recipeId)`**: User attempts to craft an item using a specific recipe. Requires ingredients and fee. Success is based on the recipe's chance. Mints an ERC721 NFT on success.
*   **`upgradeItem(uint256 _itemId, IngredientRequirement[] calldata _extraIngredients)`**: User attempts to upgrade an existing item. Requires ownership and ingredients. Increases stats/level.
*   **`dismantleItem(uint256 _itemId)`**: User burns an item to recover a portion of its crafting cost in ingredients. Recovery amount depends on item properties.
*   **`stakeItem(uint256 _itemId)`**: User locks their item in the contract to earn staking rewards (Crafting Essence). Requires item transfer approval.
*   **`unstakeItem(uint256 _itemId)`**: User unlocks their staked item. Calculates and transfers accumulated rewards before returning the item.
*   **`claimStakingRewards(uint256 _itemId)`**: User claims accumulated staking rewards for a staked item without unstaking it.
*   **`reforgeItem(uint256 _itemId, uint256 _fee)`**: User pays a fee and/or uses ingredients to re-roll certain stats of an item within its rarity range.
*   **`combineItems(uint256 _itemSourceId, uint256 _itemTargetId, IngredientRequirement[] calldata _ingredients)`**: User combines two items. `_itemSourceId` is burned, and its properties contribute to enhancing `_itemTargetId` (e.g., adding sockets, increasing level cap, transferring a specific stat). Requires ingredients.
*   **`applyBlessing(uint256 _itemId, uint256 _durationSeconds, IngredientRequirement[] calldata _specialIngredients)`**: User applies a temporary blessing to an item. Requires ingredients. Adds a timed buff property.
*   **`getItemDetails(uint256 _itemId)`**: (View) Returns all stored properties for a given item ID.
*   **`getRecipeDetails(uint256 _recipeId)`**: (View) Returns details for a given recipe ID.
*   **`getRequiredIngredients(uint256 _recipeId)`**: (View) Returns the ingredient requirements for a specific recipe.
*   **`getStakingInfo(uint256 _itemId)`**: (View) Returns staking details for an item, including calculated pending rewards.
*   **`getBlessingExpiration(uint256 _itemId)`**: (View) Returns the timestamp when an item's current blessing expires (0 if none).
*   **`balanceOfEssence(address _owner)`**: (View) Returns the Crafting Essence balance for an address.
*   **`allowanceEssence(address _owner, address _spender)`**: (View) Returns the Crafting Essence allowance granted from one address to another.
*   **`transferEssence(address _to, uint256 _amount)`**: (User) Transfers Crafting Essence.
*   **`approveEssence(address _spender, uint256 _amount)`**: (User) Approves another address to spend Crafting Essence.
*   **`transferFromEssence(address _from, address _to, uint256 _amount)`**: (User) Transfers Crafting Essence from one address to another using an allowance.
*   **`_safeTransferFrom` / `_transferFrom` (Overridden)**: Standard ERC721 transfers, modified to prevent transferring staked items.
*   **ERC721 Inherited Functions:** `balanceOf(address owner)`, `ownerOf(uint256 tokenId)`, `getApproved(uint256 tokenId)`, `isApprovedForAll(address owner, address operator)`, `approve(address to, uint256 tokenId)`, `setApprovalForAll(address operator, bool approved)`. (These contribute significantly to the total function count).
*   **Pausable Inherited Functions:** `paused()`, `pause()`, `unpause()`.
*   **Ownable Inherited Functions:** `owner()`, `transferOwnership(address newOwner)`, `renounceOwnership()`.

This structure easily exceeds 20 custom functions while incorporating standard ERC calls, resulting in a feature-rich and complex contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Contract Definition: ERC721 for Items, internal ERC20-like for Essence, Ownable, Pausable.
// 2. State Variables: Counters, Mappings for ItemProps, Recipes, Staking, Blessings, Essence balances. Admin settings.
// 3. Enums & Structs: Define item types, rarity, properties, recipe structure, staking info.
// 4. Events: Log key actions (Craft, Upgrade, Stake, etc.).
// 5. Modifiers: Pausable, Ownable checks.
// 6. Internal Essence (ERC20-like) Logic: Basic mint, burn, transfer, approval.
// 7. Admin Functions: Recipe management, Fee settings, Pausing, Initial essence distribution.
// 8. Core User Functions: Crafting, Upgrading, Dismantling, Staking, Reforging, Combining, Blessing items.
// 9. View Functions: Query details of Items, Recipes, Staking, Blessings, Essence balances.
// 10. Overridden ERC721: Prevent transfer of staked items.
// 11. Inherited Standard Functions: ERC721, Ownable, Pausable.

// Function Summary:
// constructor(): Initialize contract, names, symbols, owner.
// Admin Functions (onlyOwner):
// - mintInitialCraftingEssence(address _to, uint256 _amount): Distribute initial Essence.
// - addCraftingRecipe(IngredientRequirement[] calldata _requiredIngredients, ItemType _itemType, Rarity _rarity, uint16 _baseStrength, uint16 _baseIntelligence, uint16 _baseAgility, uint16 _durability, uint16 _successChanceBps): Add a new recipe.
// - updateCraftingRecipe(uint256 _recipeId, IngredientRequirement[] calldata _requiredIngredients, ItemType _itemType, Rarity _rarity, uint16 _baseStrength, uint16 _baseIntelligence, uint16 _baseAgility, uint16 _durability, uint16 _successChanceBps): Modify a recipe.
// - removeCraftingRecipe(uint256 _recipeId): Deactivate a recipe.
// - setCraftingFee(uint256 _fee): Set the ETH fee for crafting.
// - withdrawFees(address payable _to): Withdraw accumulated ETH fees.
// - pause(): Pause crafting and related activities.
// - unpause(): Unpause crafting and related activities.
// User Functions (whenNotPaused, requires fees/ingredients/items):
// - craftItem(uint256 _recipeId): Attempt to craft an item.
// - upgradeItem(uint256 _itemId, IngredientRequirement[] calldata _extraIngredients): Enhance an item.
// - dismantleItem(uint256 _itemId): Burn item to recover some Essence.
// - stakeItem(uint256 _itemId): Lock item for yield.
// - unstakeItem(uint256 _itemId): Unlock staked item and claim rewards.
// - claimStakingRewards(uint256 _itemId): Claim rewards without unstaking.
// - reforgeItem(uint256 _itemId, uint256 _fee): Reroll item stats.
// - combineItems(uint256 _itemSourceId, uint256 _itemTargetId, IngredientRequirement[] calldata _ingredients): Merge items.
// - applyBlessing(uint256 _itemId, uint256 _durationSeconds, IngredientRequirement[] calldata _specialIngredients): Add temporary buff.
// Internal Essence (ERC20-like) Functions:
// - _mintEssence(address _to, uint256 _amount): Mint Essence (used internally by crafting/staking).
// - _burnEssence(address _from, uint256 _amount): Burn Essence (used internally by crafting/upgrading/dismantling).
// - _transferEssence(address _from, address _to, uint256 _amount): Internal Essence transfer.
// - _balanceOfEssence(address _owner): Get Essence balance.
// - _approveEssence(address _owner, address _spender, uint256 _amount): Internal Essence approval.
// - _allowanceEssence(address _owner, address _spender): Get Essence allowance.
// User Essence Functions (Public ERC20-like interface):
// - transferEssence(address _to, uint256 _amount): Transfer Essence.
// - approveEssence(address _spender, uint256 _amount): Approve spender for Essence.
// - transferFromEssence(address _from, address _to, uint256 _amount): Transfer Essence with allowance.
// View Functions:
// - getItemDetails(uint256 _itemId): Get full item properties.
// - getRecipeDetails(uint256 _recipeId): Get recipe details.
// - getRequiredIngredients(uint256 _recipeId): Get ingredients for a recipe.
// - getStakingInfo(uint256 _itemId): Get staking details for an item.
// - getBlessingExpiration(uint256 _itemId): Get blessing expiry time.
// - balanceOfEssence(address _owner): (Public wrapper) Get Essence balance.
// - allowanceEssence(address _owner, address _spender): (Public wrapper) Get Essence allowance.
// Inherited & Overridden ERC721 Functions: balanceOf, ownerOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom, _beforeTokenTransfer (internal hook).
// Inherited Standard Functions: owner, transferOwnership, renounceOwnership, paused, pause, unpause.

contract CryptoCraft is ERC721, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Item Tracking
    Counters.Counter private _itemTokenIds;
    mapping(uint256 => ItemProperties) public itemProperties;
    mapping(uint256 => bool) private _isItemStaked; // Simple flag for transfer checks

    // Crafting Essence (Internal ERC20-like)
    string public constant ESSENCE_NAME = "Crafting Essence";
    string public constant ESSENCE_SYMBOL = "ESS";
    uint256 private _totalEssenceSupply;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    // Crafting Recipes
    Counters.Counter private _recipeIds;
    mapping(uint256 => CraftingRecipe) public craftingRecipes;
    mapping(uint256 => bool) public recipeExists; // To handle deletion/inactivation

    // Staking
    mapping(uint256 => StakingInfo) public stakingInfo;
    // Staking reward rate: Essence per item rarity per second (simplified)
    // Example: Common=1, Rare=2, Epic=5, Legendary=10 Essence per second (scaled down for realism)
    mapping(Rarity => uint256) public stakingRewardRatePerSecond; // Stored as raw essence units per second

    // Blessings
    mapping(uint256 => uint256) public blessingExpiration; // itemId => timestamp

    // Fees
    uint256 public craftingFee = 0; // Fee in wei per successful craft

    // --- Enums & Structs ---

    enum ItemType { Unknown, Weapon, Armor, Accessory, Consumable }
    enum Rarity { Common, Rare, Epic, Legendary }

    struct ItemProperties {
        uint256 id;
        ItemType itemType;
        Rarity rarity;
        uint16 strength;
        uint16 intelligence;
        uint16 agility;
        uint16 durability; // Could decrease with use/crafting
        uint256 recipeSourceId; // Which recipe created this item
        uint256 createdAt; // Timestamp of creation
        uint256 upgradeLevel; // How many times it's been upgraded
    }

    struct IngredientRequirement {
        uint256 quantity; // Simplified: only one ingredient type (CraftingEssence)
    }

    struct CraftingRecipe {
        IngredientRequirement[] requiredIngredients;
        ItemType itemType;
        Rarity rarity;
        uint16 baseStrength;
        uint16 baseIntelligence;
        uint16 baseAgility;
        uint16 durability;
        uint16 successChanceBps; // In Basis Points (1/100 of a percent), 10000 = 100%
        bool active; // Can this recipe be used?
    }

    struct StakingInfo {
        address staker;
        uint256 startTime;
        uint256 claimedAmount; // Total rewards claimed for this stake
    }

    // --- Events ---

    event ItemCrafted(uint256 indexed itemId, address indexed owner, uint256 recipeId, ItemType itemType, Rarity rarity, bool success);
    event ItemUpgraded(uint256 indexed itemId, address indexed owner, uint256 newUpgradeLevel);
    event ItemDismantled(uint256 indexed itemId, address indexed owner, uint256 essenceReturned);
    event ItemStaked(uint256 indexed itemId, address indexed staker, uint256 timestamp);
    event ItemUnstaked(uint256 indexed itemId, address indexed staker, uint256 timestamp, uint256 rewardsClaimed);
    event StakingRewardsClaimed(uint256 indexed itemId, address indexed staker, uint256 rewardsAmount);
    event RecipeAdded(uint256 indexed recipeId, ItemType itemType, Rarity rarity);
    event RecipeUpdated(uint256 indexed recipeId);
    event RecipeRemoved(uint256 indexed recipeId);
    event CraftingFeeSet(uint256 indexed fee);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ItemReforged(uint256 indexed itemId, address indexed owner);
    event ItemsCombined(uint256 indexed newItemId, uint256 indexed burntItemId1, uint256 indexed burntItemId2, address indexed owner); // Assuming combine burns 2 into 1
    event BlessingApplied(uint256 indexed itemId, address indexed owner, uint256 expirationTime);
    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event EssenceTransfer(address indexed from, address indexed to, uint256 amount);
    event EssenceApproval(address indexed owner, address indexed spender, uint256 amount);
    event StakingRewardRateSet(Rarity indexed rarity, uint256 ratePerSecond);


    // --- Constructor ---

    constructor() ERC721("CryptoCraft Item", "CCI") Ownable(msg.sender) Pausable() {
        // Set initial staking rates (example values)
        stakingRewardRatePerSecond[Rarity.Common] = 10; // 10 Essence/sec
        stakingRewardRatePerSecond[Rarity.Rare] = 20;   // 20 Essence/sec
        stakingRewardRatePerSecond[Rarity.Epic] = 50;   // 50 Essence/sec
        stakingRewardRatePerSecond[Rarity.Legendary] = 100; // 100 Essence/sec
    }

    // --- Internal Crafting Essence (ERC20-like) Functions ---
    // These are internal helper functions used by the contract itself.
    // Public wrapper functions are provided below for user interaction.

    function _mintEssence(address _to, uint256 _amount) internal {
        require(_to != address(0), "Mint to zero address");
        _totalEssenceSupply = _totalEssenceSupply.add(_amount);
        _essenceBalances[_to] = _essenceBalances[_to].add(_amount);
        emit EssenceMinted(_to, _amount);
        emit EssenceTransfer(address(0), _to, _amount); // ERC20 standard mint event
    }

    function _burnEssence(address _from, uint256 _amount) internal {
        require(_from != address(0), "Burn from zero address");
        _essenceBalances[_from] = _essenceBalances[_from].sub(_amount, "Insufficient Essence balance");
        _totalEssenceSupply = _totalEssenceSupply.sub(_amount);
        emit EssenceBurned(_from, _amount);
        emit EssenceTransfer(_from, address(0), _amount); // ERC20 standard burn event
    }

    function _transferEssence(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "Transfer from zero address");
        require(_to != address(0), "Transfer to zero address");
        _essenceBalances[_from] = _essenceBalances[_from].sub(_amount, "Insufficient Essence balance for transfer");
        _essenceBalances[_to] = _essenceBalances[_to].add(_amount);
        emit EssenceTransfer(_from, _to, _amount);
    }

    function _approveEssence(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "Approve from zero address");
        require(_spender != address(0), "Approve to zero address");
        _essenceAllowances[_owner][_spender] = _amount;
        emit EssenceApproval(_owner, _spender, _amount);
    }

    function _allowanceEssence(address _owner, address _spender) internal view returns (uint256) {
        return _essenceAllowances[_owner][_spender];
    }

    // --- Public Crafting Essence (ERC20-like) Interface ---

    function balanceOfEssence(address _owner) public view returns (uint256) {
        return _essenceBalances[_owner];
    }

    function allowanceEssence(address _owner, address _spender) public view returns (uint256) {
        return _essenceAllowances[_owner][_spender];
    }

    function transferEssence(address _to, uint256 _amount) public whenNotPaused returns (bool) {
        _transferEssence(msg.sender, _to, _amount);
        return true;
    }

    function approveEssence(address _spender, uint256 _amount) public whenNotPaused returns (bool) {
        _approveEssence(msg.sender, _spender, _amount);
        return true;
    }

    function transferFromEssence(address _from, address _to, uint256 _amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _essenceAllowances[_from][msg.sender];
        require(currentAllowance >= _amount, "Essence allowance exceeded");
        _approveEssence(_from, msg.sender, currentAllowance.sub(_amount, "Allowance calculation error")); // Decrease allowance
        _transferEssence(_from, _to, _amount);
        return true;
    }

    function totalEssenceSupply() public view returns (uint256) {
        return _totalEssenceSupply;
    }


    // --- Admin Functions (onlyOwner) ---

    function mintInitialCraftingEssence(address _to, uint256 _amount) public onlyOwner {
        _mintEssence(_to, _amount);
    }

    function addCraftingRecipe(
        IngredientRequirement[] calldata _requiredIngredients,
        ItemType _itemType,
        Rarity _rarity,
        uint16 _baseStrength,
        uint16 _baseIntelligence,
        uint16 _baseAgility,
        uint16 _durability,
        uint16 _successChanceBps // 0-10000
    ) public onlyOwner {
        require(_itemType != ItemType.Unknown, "Invalid item type");
        require(_rarity != Rarity.Common || _rarity != Rarity.Rare || _rarity != Rarity.Epic || _rarity != Rarity.Legendary, "Invalid rarity");
        require(_successChanceBps <= 10000, "Success chance cannot exceed 100%");

        _recipeIds.increment();
        uint256 newRecipeId = _recipeIds.current();

        craftingRecipes[newRecipeId] = CraftingRecipe({
            requiredIngredients: _requiredIngredients,
            itemType: _itemType,
            rarity: _rarity,
            baseStrength: _baseStrength,
            baseIntelligence: _baseIntelligence,
            baseAgility: _baseAgility,
            durability: _durability,
            successChanceBps: _successChanceBps,
            active: true
        });
        recipeExists[newRecipeId] = true;

        emit RecipeAdded(newRecipeId, _itemType, _rarity);
    }

    function updateCraftingRecipe(
        uint256 _recipeId,
        IngredientRequirement[] calldata _requiredIngredients,
        ItemType _itemType,
        Rarity _rarity,
        uint16 _baseStrength,
        uint16 _baseIntelligence,
        uint16 _baseAgility,
        uint16 _durability,
        uint16 _successChanceBps
    ) public onlyOwner {
        require(recipeExists[_recipeId], "Recipe does not exist");
        require(_itemType != ItemType.Unknown, "Invalid item type");
         require(_rarity != Rarity.Common || _rarity != Rarity.Rare || _rarity != Rarity.Epic || _rarity != Rarity.Legendary, "Invalid rarity");
        require(_successChanceBps <= 10000, "Success chance cannot exceed 100%");

        craftingRecipes[_recipeId].requiredIngredients = _requiredIngredients;
        craftingRecipes[_recipeId].itemType = _itemType;
        craftingRecipes[_recipeId].rarity = _rarity;
        craftingRecipes[_recipeId].baseStrength = _baseStrength;
        craftingRecipes[_recipeId].baseIntelligence = _baseIntelligence;
        craftingRecipes[_recipeId].baseAgility = _baseAgility;
        craftingRecipes[_recipeId].durability = _durability;
        craftingRecipes[_recipeId].successChanceBps = _successChanceBps;

        emit RecipeUpdated(_recipeId);
    }

    function removeCraftingRecipe(uint256 _recipeId) public onlyOwner {
        require(recipeExists[_recipeId], "Recipe does not exist");
        craftingRecipes[_recipeId].active = false;
        emit RecipeRemoved(_recipeId);
    }

    function setCraftingFee(uint256 _fee) public onlyOwner {
        craftingFee = _fee;
        emit CraftingFeeSet(_fee);
    }

    function withdrawFees(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success,) = _to.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(_to, balance);
    }

    function setStakingRewardRate(Rarity _rarity, uint256 _ratePerSecond) public onlyOwner {
        stakingRewardRatePerSecond[_rarity] = _ratePerSecond;
        emit StakingRewardRateSet(_rarity, _ratePerSecond);
    }

    // --- Core User Functions (whenNotPaused) ---

    function craftItem(uint256 _recipeId) public payable whenNotPaused {
        CraftingRecipe storage recipe = craftingRecipes[_recipeId];
        require(recipe.active, "Recipe not active");
        require(msg.value >= craftingFee, "Insufficient crafting fee");

        // Check and consume ingredients (assuming only CraftingEssence)
        for (uint i = 0; i < recipe.requiredIngredients.length; i++) {
            uint256 requiredAmount = recipe.requiredIngredients[i].quantity;
            require(_essenceBalances[msg.sender] >= requiredAmount, "Insufficient Essence for crafting");
            // ERC20 standard requires approve/transferFrom pattern for external contracts.
            // Since Essence is internal, we can directly transfer from the user's balance.
            // If using external ERC20, would require msg.sender to approve *this* contract
            // before calling craftItem, and then use transferFrom.
            _burnEssence(msg.sender, requiredAmount); // Burn ingredients
        }

        // Transfer crafting fee to the contract
        if (craftingFee > 0) {
             (bool success,) = payable(owner()).call{value: craftingFee}("");
             require(success, "Fee transfer failed");
        }
         // Refund any excess ETH sent
        if (msg.value > craftingFee) {
             (bool success,) = payable(msg.sender).call{value: msg.value - craftingFee}("");
             require(success, "Excess fee refund failed");
        }


        // Determine success based on chance
        // WARNING: block.timestamp and block.difficulty/prevrandao are not truly random and can be manipulated by miners.
        // For a real-world application, use a verifiable randomness function (VRF) like Chainlink VRF.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _recipeId, _itemTokenIds.current())));
        uint256 roll = randomNumber % 10000; // Roll between 0 and 9999

        bool success = roll < recipe.successChanceBps;

        if (success) {
            _itemTokenIds.increment();
            uint256 newItemId = _itemTokenIds.current();

            // Mint the item NFT
            _safeMint(msg.sender, newItemId);

            // Generate item properties (can add variability based on rarity/roll)
            itemProperties[newItemId] = ItemProperties({
                id: newItemId,
                itemType: recipe.itemType,
                rarity: recipe.rarity,
                strength: recipe.baseStrength,
                intelligence: recipe.baseIntelligence,
                agility: recipe.baseAgility,
                durability: recipe.durability,
                recipeSourceId: _recipeId,
                createdAt: block.timestamp,
                upgradeLevel: 0
            });

            emit ItemCrafted(newItemId, msg.sender, _recipeId, recipe.itemType, recipe.rarity, true);

        } else {
            // Crafting failed - ingredients/fee are still consumed
            // Optionally, could return a small fraction of ingredients or a different token on failure
            emit ItemCrafted(0, msg.sender, _recipeId, recipe.itemType, recipe.rarity, false);
        }
    }

    function upgradeItem(uint256 _itemId, IngredientRequirement[] calldata _extraIngredients) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _itemId), "Not item owner or approved");
        ItemProperties storage props = itemProperties[_itemId];
        require(props.id != 0, "Item does not exist");
        require(props.durability > 0, "Item durability too low to upgrade"); // Example check
        require(props.itemType != ItemType.Consumable, "Consumables cannot be upgraded"); // Example restriction

        // Check and consume upgrade ingredients (assuming only CraftingEssence)
        uint256 totalRequiredEssence = 0;
        for (uint i = 0; i < _extraIngredients.length; i++) {
            totalRequiredEssence = totalRequiredEssence.add(_extraIngredients[i].quantity);
        }
         require(_essenceBalances[msg.sender] >= totalRequiredEssence, "Insufficient Essence for upgrade");
         _burnEssence(msg.sender, totalRequiredEssence);


        // Apply upgrade logic (example: flat stat increase + percentage increase)
        props.upgradeLevel = props.upgradeLevel.add(1);
        props.strength = props.strength.add(1).add(props.strength.mul(props.upgradeLevel) / 100);
        props.intelligence = props.intelligence.add(1).add(props.intelligence.mul(props.upgradeLevel) / 100);
        props.agility = props.agility.add(1).add(props.agility.mul(props.upgradeLevel) / 100);

        // Optionally decrease durability or add a chance for failure on higher levels

        emit ItemUpgraded(_itemId, msg.sender, props.upgradeLevel);
    }

    function dismantleItem(uint256 _itemId) public whenNotPaused {
         require(_isApprovedOrOwner(msg.sender, _itemId), "Not item owner or approved");
         ItemProperties storage props = itemProperties[_itemId];
         require(props.id != 0, "Item does not exist");
         require(!_isItemStaked[_itemId], "Cannot dismantle staked item");

         // Calculate essence return (example: based on rarity and original recipe cost, potentially less if durability is low)
         CraftingRecipe storage recipe = craftingRecipes[props.recipeSourceId];
         uint256 returnedEssence = 0;
         for(uint i=0; i<recipe.requiredIngredients.length; i++){
             // Example: return 50% of base cost + 10% per upgrade level, capped at 100%
             uint256 baseReturn = recipe.requiredIngredients[i].quantity.mul(50).div(100);
             uint256 upgradeBonus = recipe.requiredIngredients[i].quantity.mul(props.upgradeLevel.mul(10)).div(100);
             returnedEssence = returnedEssence.add(baseReturn).add(upgradeBonus).min(recipe.requiredIngredients[i].quantity);
         }

         _burn(msg.sender, _itemId); // Burn the NFT
         delete itemProperties[_itemId]; // Clear properties
         _mintEssence(msg.sender, returnedEssence); // Return essence

         emit ItemDismantled(_itemId, msg.sender, returnedEssence);
    }

    function stakeItem(uint256 _itemId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _itemId), "Not item owner or approved");
        require(!_isItemStaked[_itemId], "Item is already staked");
        ItemProperties storage props = itemProperties[_itemId];
        require(props.id != 0, "Item does not exist");

        // Transfer item ownership to the contract
        // User must call approve() or setApprovalForAll() on this contract beforehand
        _safeTransferFrom(msg.sender, address(this), _itemId);

        stakingInfo[_itemId] = StakingInfo({
            staker: msg.sender,
            startTime: block.timestamp,
            claimedAmount: 0
        });
        _isItemStaked[_itemId] = true;

        emit ItemStaked(_itemId, msg.sender, block.timestamp);
    }

    function unstakeItem(uint256 _itemId) public whenNotPaused {
        StakingInfo storage sInfo = stakingInfo[_itemId];
        require(_isItemStaked[_itemId], "Item is not staked");
        require(sInfo.staker == msg.sender, "Not the original staker");
        ItemProperties storage props = itemProperties[_itemId];
        require(props.id != 0, "Item does not exist"); // Should exist if staked

        // Calculate rewards
        uint256 pendingRewards = calculateStakingRewards(_itemId);
        uint256 totalRewards = sInfo.claimedAmount.add(pendingRewards);

        // Transfer rewards
        if (totalRewards > 0) {
           _mintEssence(msg.sender, totalRewards);
        }

        // Transfer item back to staker
        _isItemStaked[_itemId] = false; // Set flag BEFORE transfer hook runs
        _safeTransferFrom(address(this), msg.sender, _itemId);

        // Clear staking info
        delete stakingInfo[_itemId];

        emit ItemUnstaked(_itemId, msg.sender, block.timestamp, totalRewards);
    }

    function claimStakingRewards(uint256 _itemId) public whenNotPaused {
        StakingInfo storage sInfo = stakingInfo[_itemId];
        require(_isItemStaked[_itemId], "Item is not staked");
        require(sInfo.staker == msg.sender, "Not the original staker");

        uint256 pendingRewards = calculateStakingRewards(_itemId);
        require(pendingRewards > 0, "No pending rewards");

        // Update claimed amount and reset start time for next cycle
        sInfo.claimedAmount = sInfo.claimedAmount.add(pendingRewards); // Track total claimed history
        sInfo.startTime = block.timestamp; // Restart calculation from now

        // Transfer pending rewards
        _mintEssence(msg.sender, pendingRewards);

        emit StakingRewardsClaimed(_itemId, msg.sender, pendingRewards);
    }

     function reforgeItem(uint256 _itemId, uint256 _fee) public payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _itemId), "Not item owner or approved");
        ItemProperties storage props = itemProperties[_itemId];
        require(props.id != 0, "Item does not exist");
        require(!_isItemStaked[_itemId], "Cannot reforge staked item");
        require(msg.value >= _fee, "Insufficient reforge fee");

        // Transfer fee
         if (_fee > 0) {
             (bool success,) = payable(owner()).call{value: _fee}("");
             require(success, "Reforge fee transfer failed");
         }
         // Refund excess ETH
         if (msg.value > _fee) {
             (bool success,) = payable(msg.sender).call{value: msg.value - _fee}("");
             require(success, "Excess fee refund failed");
         }


        // Reforge logic: Re-roll stats within a certain range based on rarity/upgrade level
        // Using blockhash for pseudo-randomness (again, use VRF for production)
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _itemId, props.upgradeLevel)));

        // Example Rerolling: Adjust stats +/- a percentage based on rarity/upgrade level
        uint16 statVarianceBps = 500; // 5% variance base
        statVarianceBps = statVarianceBps.add(props.upgradeLevel.mul(50)); // +0.5% variance per level
        if (statVarianceBps > 2000) statVarianceBps = 2000; // Cap variance at 20%

        // Generate new stats
        props.strength = _generateNewStat(props.strength, statVarianceBps, randomSeed);
        props.intelligence = _generateNewStat(props.intelligence, statVarianceBps, randomSeed + 1); // Use different seed
        props.agility = _generateNewStat(props.agility, statVarianceBps, randomSeed + 2);

        emit ItemReforged(_itemId, msg.sender);
    }

    function combineItems(uint256 _itemSourceId, uint256 _itemTargetId, IngredientRequirement[] calldata _ingredients) public whenNotPaused {
        require(_itemSourceId != _itemTargetId, "Cannot combine an item with itself");
        require(_isApprovedOrOwner(msg.sender, _itemSourceId), "Not owner/approved of source item");
        require(_isApprovedOrOwner(msg.sender, _itemTargetId), "Not owner/approved of target item");
        require(!_isItemStaked[_itemSourceId], "Cannot combine staked source item");
        require(!_isItemStaked[_itemTargetId], "Cannot combine staked target item");

         ItemProperties storage sourceProps = itemProperties[_itemSourceId];
         ItemProperties storage targetProps = itemProperties[_itemTargetId];

         require(sourceProps.id != 0, "Source item does not exist");
         require(targetProps.id != 0, "Target item does not exist");
         require(sourceProps.itemType != ItemType.Consumable, "Consumables cannot be used as combine source");
         require(targetProps.itemType != ItemType.Consumable, "Consumables cannot be combine target");
         // Add more specific combine rules here (e.g., only combine same item types, or certain rarity combinations)

        // Check and consume ingredients
        uint256 totalRequiredEssence = 0;
        for (uint i = 0; i < _ingredients.length; i++) {
            totalRequiredEssence = totalRequiredEssence.add(_ingredients[i].quantity);
        }
         require(_essenceBalances[msg.sender] >= totalRequiredEssence, "Insufficient Essence for combine");
         _burnEssence(msg.sender, totalRequiredEssence);

        // Combine logic (example: transfer percentage of source stats, add upgrade level)
        targetProps.strength = targetProps.strength.add(sourceProps.strength.mul(20).div(100)); // Add 20% of source strength
        targetProps.intelligence = targetProps.intelligence.add(sourceProps.intelligence.mul(20).div(100));
        targetProps.agility = targetProps.agility.add(sourceProps.agility.mul(20).div(100));
        targetProps.upgradeLevel = targetProps.upgradeLevel.add(sourceProps.upgradeLevel.div(2).add(1)); // Add half source levels + 1

        // More complex logic could be: add a socket, change item appearance (if dynamic metadata), unlock a new ability.

        _burn(msg.sender, _itemSourceId); // Burn the source item
        delete itemProperties[_itemSourceId]; // Clear source properties

        // Note: No new NFT is minted, target item is modified in place.

        emit ItemsCombined(_itemTargetId, _itemSourceId, 0, msg.sender); // BurntItemId2 is 0 as we only burn one source

    }

    function applyBlessing(uint256 _itemId, uint256 _durationSeconds, IngredientRequirement[] calldata _specialIngredients) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _itemId), "Not item owner or approved");
         ItemProperties storage props = itemProperties[_itemId];
         require(props.id != 0, "Item does not exist");
         require(!_isItemStaked[_itemId], "Cannot bless staked item");
         require(props.itemType != ItemType.Consumable, "Cannot bless consumables");


        // Check and consume ingredients
        uint256 totalRequiredEssence = 0;
        for (uint i = 0; i < _specialIngredients.length; i++) {
            totalRequiredEssence = totalRequiredEssence.add(_specialIngredients[i].quantity);
        }
         require(_essenceBalances[msg.sender] >= totalRequiredEssence, "Insufficient Essence for blessing");
         _burnEssence(msg.sender, totalRequiredEssence);

        // Apply blessing: Set expiration time
        uint256 currentExpiration = blessingExpiration[_itemId];
        // If already blessed, add duration to current expiration, otherwise add to now
        uint256 newExpiration = currentExpiration > block.timestamp ? currentExpiration.add(_durationSeconds) : block.timestamp.add(_durationSeconds);
        blessingExpiration[_itemId] = newExpiration;

        // Note: The *effect* of the blessing (e.g., stat boost) would typically be handled off-chain
        // by dApps reading the `blessingExpiration` and item properties.

        emit BlessingApplied(_itemId, msg.sender, newExpiration);
    }

    // --- Internal Helper Functions ---

    function calculateStakingRewards(uint256 _itemId) internal view returns (uint256) {
        StakingInfo storage sInfo = stakingInfo[_itemId];
        ItemProperties storage props = itemProperties[_itemId];
        require(sInfo.staker != address(0) && props.id != 0, "Item not properly staked");

        uint256 secondsStaked = block.timestamp.sub(sInfo.startTime);
        uint256 rate = stakingRewardRatePerSecond[props.rarity]; // Get rate based on rarity
        uint256 potentialRewards = secondsStaked.mul(rate);

        // The actual *claimable* amount is total earned minus already claimed amount in previous claims
        // Note: this logic works if we reset startTime on claim. If not resetting startTime,
        // we would track accumulated earnings and subtract sInfo.claimedAmount from that total.
        // With startTime reset on claim, pending is simply (now - lastClaimTime) * rate.
        // Since startTime *is* reset on claim/unstake, this calculation gives the rewards *since the last claim/stake*.
        return potentialRewards;
    }

     // Helper for reforge stat generation (pseudo-random)
    function _generateNewStat(uint16 _currentStat, uint16 _varianceBps, uint256 _seed) internal pure returns (uint16) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(_seed, block.timestamp, block.difficulty))) % 20001; // 0 to 20000
        int256 variancePercent = int256(randomValue) - 10000; // -10000 to +10000

        // Apply variance (e.g., if variancePercent is 5000 (+50%), variance is _varianceBps / 10000 * 50%)
        int256 statChange = (int256(_currentStat).mul(variancePercent.mul(_varianceBps / 100)) / 10000).div(100); // Simplified scaling

        int256 newStat = int256(_currentStat).add(statChange);

        // Ensure stat doesn't go below zero (or a reasonable minimum)
        if (newStat < 0) newStat = 0;
        // Or enforce minimum based on rarity/level

        return uint16(newStat);
    }


    // --- View Functions ---

    function getItemDetails(uint256 _itemId) public view returns (ItemProperties memory) {
        require(itemProperties[_itemId].id != 0 || _isItemStaked[_itemId], "Item does not exist"); // Check if item exists OR is staked in contract
        return itemProperties[_itemId];
    }

    function getRecipeDetails(uint256 _recipeId) public view returns (CraftingRecipe memory) {
        require(recipeExists[_recipeId], "Recipe does not exist");
        return craftingRecipes[_recipeId];
    }

    function getRequiredIngredients(uint256 _recipeId) public view returns (IngredientRequirement[] memory) {
         require(recipeExists[_recipeId], "Recipe does not exist");
         return craftingRecipes[_recipeId].requiredIngredients;
    }


    function getStakingInfo(uint256 _itemId) public view returns (StakingInfoWithPendingRewards memory) {
         StakingInfo storage sInfo = stakingInfo[_itemId];
         require(_isItemStaked[_itemId], "Item is not staked");

         uint256 pending = calculateStakingRewards(_itemId);

         return StakingInfoWithPendingRewards({
             staker: sInfo.staker,
             startTime: sInfo.startTime,
             claimedAmount: sInfo.claimedAmount,
             pendingRewards: pending
         });
    }

    struct StakingInfoWithPendingRewards {
         address staker;
         uint256 startTime;
         uint256 claimedAmount;
         uint256 pendingRewards; // Calculated on the fly
    }


    function getBlessingExpiration(uint256 _itemId) public view returns (uint256) {
         // Returns 0 if not blessed or expired
         return blessingExpiration[_itemId];
    }


    // --- Overrides and Inherited Functions ---

    // Prevent transfer of staked items
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(!_isItemStaked[tokenId], "Cannot transfer staked item");
        // Note: batchSize is for ERC1155, but the hook signature includes it. We only care about single token transfers here.
    }

    // The ERC721 functions like `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`
    // are inherited from @openzeppelin/contracts/token/ERC721/ERC721.sol and contribute to the total function count.
    // Pausable functions `paused()`, `pause()`, `unpause()` are inherited.
    // Ownable functions `owner()`, `transferOwnership()`, `renounceOwnership()` are inherited.

    // Total functions count includes all public/external and view functions accessible from outside,
    // plus the constructor. Inherited public/external/view functions from OpenZeppelin also count.
    // This contract, with inherited functions, easily clears the 20+ requirement with
    // a good number of unique custom functionalities.
}
```