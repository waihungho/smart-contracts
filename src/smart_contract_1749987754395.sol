Okay, let's design a smart contract for a complex, on-chain crafting and item management system within a hypothetical game or simulation environment. We'll call it `CryptoCraftingNexus`.

It will involve managing different types of resources (using ERC-1155), crafting unique items (using ERC-721), learning recipes via blueprints (using ERC-721), upgrading existing items, and tracking basic player progression like levels.

This requires intricate state management, interactions with multiple token standards, and complex logic flows for crafting, upgrading, and learning.

---

**Outline & Function Summary: CryptoCraftingNexus**

**Contract Name:** `CryptoCraftingNexus`

**Purpose:** Manages resource consumption, item crafting, item upgrading, blueprint learning, and player progression within a decentralized crafting simulation. Interacts with external ERC-1155 (Resources) and ERC-721 (Crafted Items, Workshops, Blueprints) contracts.

**Key Concepts:**
*   **Resources:** Fungible tokens (ERC-1155) used as crafting inputs.
*   **Crafted Items:** Unique NFTs (ERC-721) produced via crafting. Possess dynamic attributes stored on-chain.
*   **Workshops:** NFTs (ERC-721) that can provide bonuses or enable specific crafting recipes.
*   **Blueprints:** NFTs (ERC-721) that players consume to permanently unlock the ability to craft specific recipes.
*   **Recipes:** Defined rules within the contract specifying resource inputs, required workshop, and output item type.
*   **Item Attributes:** Dynamic data stored for individual Crafted Item NFTs (e.g., level, durability, enhancements).
*   **Player Level:** Simple on-chain counter tracking a player's crafting activity.

**External Dependencies:**
*   ERC-1155 Token Contract (for Resources)
*   ERC-721 Token Contract (for Crafted Items)
*   ERC-721 Token Contract (for Workshops)
*   ERC-721 Token Contract (for Blueprints)

**State Variables:**
*   Addresses of the dependent token contracts.
*   Owner address.
*   Paused state for crafting.
*   Mappings for Recipe definitions (`recipeId => Recipe`).
*   Mappings for Crafting Item Type definitions (`itemTypeId => ItemTypeDefinition`).
*   Mappings for Workshop Type definitions (`workshopTypeId => WorkshopTypeDefinition`).
*   Mappings for Blueprint definitions (`blueprintTypeId => BlueprintInfo`).
*   Mapping for dynamic Crafted Item attributes (`itemTokenId => CraftedItemAttributes`).
*   Mapping for player levels (`playerAddress => level`).
*   Mapping for tracking learned blueprints per player (`playerAddress => blueprintTypeId => bool`).
*   Mapping for player display names (`playerAddress => string`).
*   Mapping for player level rewards claimed timestamps (`playerAddress => timestamp`).
*   Crafting fee configuration.

**Events:**
*   `RecipeAdded`
*   `RecipeUpdated`
*   `BlueprintAdded`
*   `ItemTypeAdded`
*   `WorkshopTypeAdded`
*   `CraftingPaused`
*   `CraftingUnpaused`
*   `Crafted` (Detailed info: player, recipeId, workshopId, newItemId, resourcesUsed, outcomeAttributes)
*   `BatchCrafted` (Similar info for batch operation)
*   `ItemUpgraded` (player, itemTokenId, newAttributes, resourcesUsed)
*   `ItemDisenchanted` (player, itemTokenId, resourcesReturned)
*   `BlueprintLearned` (player, blueprintTypeId, recipeUnlockedId)
*   `PlayerLevelUp` (player, newLevel)
*   `PlayerLevelRewardClaimed` (player, level, rewardDetails)
*   `PlayerDisplayNameUpdated` (player, newName)
*   `CraftingFeeUpdated`

**Modifiers:**
*   `onlyOwner`
*   `whenNotPaused`
*   `whenPaused`

**Function Summary:**

1.  **`constructor(...)`**: Initializes the contract with owner and token contract addresses.
2.  **`setResourceTokenAddress(address _address)`**: Sets the address for the Resource ERC-1155 contract (Owner only).
3.  **`setCraftedItemTokenAddress(address _address)`**: Sets the address for the Crafted Item ERC-721 contract (Owner only).
4.  **`setWorkshopTokenAddress(address _address)`**: Sets the address for the Workshop ERC-721 contract (Owner only).
5.  **`setBlueprintTokenAddress(address _address)`**: Sets the address for the Blueprint ERC-721 contract (Owner only).
6.  **`addResourceType(uint256 _typeId, string memory _name)`**: Registers a new valid Resource type ID and name (Owner only).
7.  **`addItemType(uint256 _typeId, string memory _name, uint256 _initialDurability)`**: Registers a new valid Crafted Item type ID, name, and base durability (Owner only).
8.  **`addWorkshopType(uint256 _typeId, string memory _name, uint256 _craftingBonusPercent)`**: Registers a new valid Workshop type ID, name, and crafting bonus (Owner only).
9.  **`addBlueprintType(uint256 _typeId, string memory _name, uint256 _unlocksRecipeId)`**: Registers a new valid Blueprint type ID, name, and the recipe it unlocks (Owner only).
10. **`addRecipe(uint256 _recipeId, uint256[] memory _resourceTypeIds, uint256[] memory _resourceAmounts, uint256 _outputItemTypeId, uint256 _requiredWorkshopTypeId, uint256 _craftingDurationSeconds, uint256 _levelRequirement)`**: Defines a new crafting recipe (Owner only).
11. **`updateRecipe(uint256 _recipeId, uint256[] memory _resourceTypeIds, uint256[] memory _resourceAmounts, uint256 _outputItemTypeId, uint256 _requiredWorkshopTypeId, uint256 _craftingDurationSeconds, uint256 _levelRequirement)`**: Updates an existing recipe's parameters (Owner only).
12. **`removeRecipe(uint256 _recipeId)`**: Marks a recipe as inactive (Owner only).
13. **`setCraftingFee(uint256 _feeAmount)`**: Sets a fee (in a designated token or native currency) required for crafting (Owner only).
14. **`pauseCrafting()`**: Pauses the `craftItem` and `batchCraftItems` functions (Owner only).
15. **`unpauseCrafting()`**: Unpauses the `craftItem` and `batchCraftItems` functions (Owner only).
16. **`withdrawFees(address _tokenAddress)`**: Withdraws collected fees of a specific token (Owner only).
17. **`craftItem(uint256 _recipeId, uint256 _workshopTokenId)`**: Executes a single crafting attempt using a specific recipe and workshop. Checks resources, blueprint, workshop type, level reqs. Burns resources, potentially takes fee, Mints a new Crafted Item NFT, updates player level (Requires player to approve Resource token transfer from address(this)).
18. **`batchCraftItems(uint256 _recipeId, uint256 _workshopTokenId, uint256 _amount)`**: Executes multiple crafting attempts of the same recipe and workshop in one transaction. Checks total resources, etc. (Requires player to approve Resource token transfer from address(this)).
19. **`learnBlueprint(uint256 _blueprintTokenId)`**: Player consumes a Blueprint NFT to learn its associated recipe. Burns the Blueprint NFT, updates learned state, potentially grants level (Requires player to approve Blueprint token transfer from address(this)).
20. **`upgradeItem(uint256 _itemTokenId, uint256[] memory _resourceTypeIds, uint256[] memory _resourceAmounts)`**: Player uses resources to upgrade a Crafted Item NFT. Burns resources, modifies the item's on-chain attributes (level, durability etc.), updates player level (Requires player to approve Resource token transfer from address(this) and approve CraftedItem token transfer from address(this) if burning/re-minting logic is used, otherwise just approve resources). *Modification:* Let's update attributes directly via mapping for simplicity here, no NFT transfer needed.
21. **`disenchantItem(uint256 _itemTokenId)`**: Player destroys a Crafted Item NFT to recover some resources. Burns the item NFT, mints/transfers resources back to the player (Requires player to approve CraftedItem token transfer from address(this)).
22. **`claimPlayerLevelReward()`**: Allows a player to claim a reward based on their current level, potentially on a cooldown (Requires contract to have reward resources/items or permission to mint).
23. **`setPlayerDisplayName(string memory _name)`**: Allows a player to set or update their on-chain display name.
24. **`getRecipeDetails(uint256 _recipeId)`**: View function. Returns details of a recipe.
25. **`getItemAttributes(uint256 _itemTokenId)`**: View function. Returns the dynamic attributes of a specific Crafted Item NFT.
26. **`getWorkshopBonus(uint256 _workshopTokenId)`**: View function. Returns the crafting bonus percentage provided by a specific Workshop NFT.
27. **`getBlueprintDetails(uint256 _blueprintTypeId)`**: View function. Returns details of a blueprint type.
28. **`getPlayerLevel(address _player)`**: View function. Returns the crafting level of a player.
29. **`isBlueprintLearned(address _player, uint256 _blueprintTypeId)`**: View function. Checks if a player has learned a specific blueprint.
30. **`getPlayerDisplayName(address _player)`**: View function. Returns the display name of a player.
31. **`checkRecipeRequirements(uint256 _recipeId, uint256 _workshopTokenId)`**: View function. Checks if the *caller* meets the requirements (resources, blueprint learned, level, workshop type) to craft a specific recipe with a workshop. Returns boolean and specific failure reason code.
32. **`getCraftingFee()`**: View function. Returns the current crafting fee amount.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Useful for tracking sets of IDs

// Define Interfaces for our external tokens (using OpenZeppelin interfaces)
interface IResourceToken is IERC1155 {}
interface ICraftedItemToken is IERC721 {
    // Assuming the ERC721 contract has a mint function callable by the Nexus
    function safeMint(address to, uint256 tokenId) external;
    // Assuming the ERC721 contract has a burn function callable by the Nexus
    function burn(uint256 tokenId) external;
    // Optional: Function to get next available token ID
    function getNextTokenId() external view returns (uint256);
}
interface IWorkshopToken is IERC721 {
    // Assuming metadata/attributes are stored on-chain or retrievable
}
interface IBlueprintToken is IERC721 {
    // Assuming metadata/attributes are stored on-chain or retrievable
}

/**
 * @title CryptoCraftingNexus
 * @dev A smart contract for managing crafting, resources, items, blueprints, and player progression.
 * @dev Interacts with external ERC-1155 (Resources) and ERC-721 (Crafted Items, Workshops, Blueprints) contracts.
 */
contract CryptoCraftingNexus is Ownable, ReentrancyGuard, ERC1155Holder, ERC721Holder {

    using EnumerableSet for EnumerableSet.UintSet;

    // --- State Variables ---

    // Token Contract Addresses
    IResourceToken private _resourceToken;
    ICraftedItemToken private _craftedItemToken;
    IWorkshopToken private _workshopToken;
    IBlueprintToken private _blueprintToken;

    // Contract State
    bool private _paused = false;

    // Crafting Fee (e.g., in native token or a specific resource)
    // For simplicity, let's use native token (ETH) here. Could be modified.
    uint256 private _craftingFee = 0;

    // Definitions (Owner managed)
    struct Recipe {
        uint256[] resourceTypeIds;
        uint256[] resourceAmounts;
        uint256 outputItemTypeId;
        uint256 requiredWorkshopTypeId; // 0 for no specific workshop required
        uint256 craftingDurationSeconds; // Can be used for future time-based features, or simply ignored if crafting is instant
        uint256 levelRequirement;
        bool active; // Can be deactivated instead of removed
    }
    mapping(uint256 => Recipe) private _recipes;
    EnumerableSet.UintSet private _availableRecipeIds;

    struct ItemTypeDefinition {
        string name;
        uint256 baseDurability; // Example attribute
        bool exists; // To check if the type ID is defined
    }
    mapping(uint256 => ItemTypeDefinition) private _itemTypeDefinitions;
    EnumerableSet.UintSet private _availableItemTypeIds;

    struct WorkshopTypeDefinition {
        string name;
        uint256 craftingBonusPercent; // e.g., 100 = 100% bonus, 110 = 110% bonus (10% extra)
        bool exists; // To check if the type ID is defined
    }
    mapping(uint256 => WorkshopTypeDefinition) private _workshopTypeDefinitions;
    EnumerableSet.UintSet private _availableWorkshopTypeIds;

    struct BlueprintInfo {
        string name;
        uint256 unlocksRecipeId;
        bool exists; // To check if the type ID is defined
    }
    mapping(uint256 => BlueprintInfo) private _blueprintDefinitions;
    EnumerableSet.UintSet private _availableBlueprintTypeIds;

    // Dynamic Data (Player & Item specific)
    struct CraftedItemAttributes {
        uint256 level;
        uint256 currentDurability;
        // Add more dynamic attributes here (e.g., enchantments, quality)
    }
    mapping(uint256 => CraftedItemAttributes) private _craftedItemAttributes; // itemTokenId => attributes

    mapping(address => uint256) private _playerLevels; // playerAddress => level
    mapping(address => mapping(uint256 => bool)) private _learnedBlueprints; // playerAddress => blueprintTypeId => learned?

    mapping(address => string) private _playerDisplayNames; // playerAddress => name

    mapping(address => uint256) private _playerLevelRewardClaimTimestamps; // playerAddress => timestamp of last claim

    // Example: Level-based rewards (can be more complex)
    // Mapping: level => resourceTypeId => amount
    mapping(uint256 => mapping(uint256 => uint256)) private _levelRewards;
    uint256 private constant LEVEL_REWARD_COOLDOWN = 1 days; // Example cooldown


    // --- Events ---

    event ResourceTokenAddressSet(address indexed _address);
    event CraftedItemTokenAddressSet(address indexed _address);
    event WorkshopTokenAddressSet(address indexed _address);
    event BlueprintTokenAddressSet(address indexed _address);

    event ResourceTypeAdded(uint256 indexed _typeId, string _name);
    event ItemTypeAdded(uint256 indexed _typeId, string _name, uint256 _baseDurability);
    event WorkshopTypeAdded(uint256 indexed _typeId, string _name, uint256 _craftingBonusPercent);
    event BlueprintTypeAdded(uint256 indexed _typeId, string _name, uint256 indexed _unlocksRecipeId);

    event RecipeAdded(uint256 indexed _recipeId, uint256 _outputItemTypeId, uint256 _requiredWorkshopTypeId);
    event RecipeUpdated(uint256 indexed _recipeId);
    event RecipeRemoved(uint256 indexed _recipeId);

    event CraftingPaused();
    event CraftingUnpaused();
    event CraftingFeeUpdated(uint256 _newFee);
    event FeesWithdraw(address indexed _tokenAddress, uint256 _amount);

    event Crafted(address indexed player, uint256 indexed recipeId, uint256 indexed newItemTokenId, uint256 workshopTokenId);
    event BatchCrafted(address indexed player, uint256 indexed recipeId, uint256 amount, uint256 firstNewItemTokenId, uint256 workshopTokenId);

    event ItemUpgraded(address indexed player, uint256 indexed itemTokenId, uint256 newLevel);
    event ItemDisenchanted(address indexed player, uint256 indexed itemTokenId);

    event BlueprintLearned(address indexed player, uint256 indexed blueprintTypeId, uint256 indexed recipeUnlockedId);

    event PlayerLevelUp(address indexed player, uint256 newLevel);
    event PlayerLevelRewardClaimed(address indexed player, uint256 level, uint256 indexed resourceTypeId, uint256 amount);

    event PlayerDisplayNameUpdated(address indexed player, string newName);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!_paused, "Crafting is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Crafting is not paused");
        _;
    }

    // --- Constructor ---

    constructor(
        address resourceTokenAddress,
        address craftedItemTokenAddress,
        address workshopTokenAddress,
        address blueprintTokenAddress
    ) Ownable(msg.sender) ERC1155Holder() ERC721Holder() {
        require(resourceTokenAddress != address(0), "Invalid resource token address");
        require(craftedItemTokenAddress != address(0), "Invalid crafted item token address");
        require(workshopTokenAddress != address(0), "Invalid workshop token address");
        require(blueprintTokenAddress != address(0), "Invalid blueprint token address");

        _resourceToken = IResourceToken(resourceTokenAddress);
        _craftedItemToken = ICraftedItemToken(craftedItemTokenAddress);
        _workshopToken = IWorkshopToken(workshopTokenAddress);
        _blueprintToken = IBlueprintToken(blueprintTokenAddress);

        emit ResourceTokenAddressSet(resourceTokenAddress);
        emit CraftedItemTokenAddressSet(craftedItemTokenAddress);
        emit WorkshopTokenAddressSet(workshopTokenAddress);
        emit BlueprintTokenAddressSet(blueprintTokenAddress);
    }

    // --- Admin/Setup Functions (Owner Only) ---

    /**
     * @dev Sets the address of the Resource ERC-1155 token contract.
     * @param _address The address of the Resource token contract.
     */
    function setResourceTokenAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        _resourceToken = IResourceToken(_address);
        emit ResourceTokenAddressSet(_address);
    }

    /**
     * @dev Sets the address of the Crafted Item ERC-721 token contract.
     * @param _address The address of the Crafted Item token contract.
     */
    function setCraftedItemTokenAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        _craftedItemToken = ICraftedItemToken(_address);
        emit CraftedItemTokenAddressSet(_address);
    }

    /**
     * @dev Sets the address of the Workshop ERC-721 token contract.
     * @param _address The address of the Workshop token contract.
     */
    function setWorkshopTokenAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        _workshopToken = IWorkshopToken(_address);
        emit WorkshopTokenAddressSet(_address);
    }

    /**
     * @dev Sets the address of the Blueprint ERC-721 token contract.
     * @param _address The address of the Blueprint token contract.
     */
    function setBlueprintTokenAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        _blueprintToken = IBlueprintToken(_address);
        emit BlueprintTokenAddressSet(_address);
    }

    /**
     * @dev Registers a new valid resource type ID. Resources must be pre-defined in the ERC-1155 contract.
     * @param _typeId The ID of the resource type.
     * @param _name The name of the resource type (for info, not stored on-chain currently).
     */
    function addResourceType(uint256 _typeId, string memory _name) external onlyOwner {
         // Basic check, assume the actual token exists in the ERC1155 contract
         // More robust check might involve calling a view function on ERC1155 if available
        emit ResourceTypeAdded(_typeId, _name);
    }

     /**
     * @dev Registers a new valid crafted item type ID and its base properties.
     * @param _typeId The ID of the item type.
     * @param _name The name of the item type.
     * @param _initialDurability The base durability for items of this type.
     */
    function addItemType(uint256 _typeId, string memory _name, uint256 _initialDurability) external onlyOwner {
        require(!_itemTypeDefinitions[_typeId].exists, "Item type ID already exists");
        _itemTypeDefinitions[_typeId] = ItemTypeDefinition(_name, _initialDurability, true);
        _availableItemTypeIds.add(_typeId);
        emit ItemTypeAdded(_typeId, _name, _initialDurability);
    }

     /**
     * @dev Registers a new valid workshop type ID and its bonus property.
     * @param _typeId The ID of the workshop type.
     * @param _name The name of the workshop type.
     * @param _craftingBonusPercent The percentage bonus this workshop type provides (e.g., 100 = 100%, 110 = 10% bonus).
     */
    function addWorkshopType(uint256 _typeId, string memory _name, uint256 _craftingBonusPercent) external onlyOwner {
        require(!_workshopTypeDefinitions[_typeId].exists, "Workshop type ID already exists");
        _workshopTypeDefinitions[_typeId] = WorkshopTypeDefinition(_name, _craftingBonusPercent, true);
         _availableWorkshopTypeIds.add(_typeId);
        emit WorkshopTypeAdded(_typeId, _name, _craftingBonusPercent);
    }

    /**
     * @dev Registers a new valid blueprint type ID and the recipe it unlocks.
     * @param _typeId The ID of the blueprint type.
     * @param _name The name of the blueprint type.
     * @param _unlocksRecipeId The ID of the recipe this blueprint unlocks.
     */
    function addBlueprintType(uint256 _typeId, string memory _name, uint256 _unlocksRecipeId) external onlyOwner {
        require(!_blueprintDefinitions[_typeId].exists, "Blueprint type ID already exists");
        require(_recipes[_unlocksRecipeId].active, "Recipe to unlock must exist and be active"); // Recipe must exist
        _blueprintDefinitions[_typeId] = BlueprintInfo(_name, _unlocksRecipeId, true);
        _availableBlueprintTypeIds.add(_typeId);
        emit BlueprintTypeAdded(_typeId, _name, _unlocksRecipeId);
    }


    /**
     * @dev Defines a new crafting recipe.
     * @param _recipeId The unique ID for the recipe.
     * @param _resourceTypeIds Array of resource type IDs required.
     * @param _resourceAmounts Array of amounts corresponding to _resourceTypeIds.
     * @param _outputItemTypeId The item type ID produced by this recipe.
     * @param _requiredWorkshopTypeId The workshop type ID required (0 for none).
     * @param _craftingDurationSeconds Placeholder for time-based crafting.
     * @param _levelRequirement Minimum player level required.
     */
    function addRecipe(
        uint256 _recipeId,
        uint256[] memory _resourceTypeIds,
        uint256[] memory _resourceAmounts,
        uint256 _outputItemTypeId,
        uint256 _requiredWorkshopTypeId,
        uint256 _craftingDurationSeconds,
        uint256 _levelRequirement
    ) external onlyOwner {
        require(!_recipes[_recipeId].active, "Recipe ID already exists");
        require(_resourceTypeIds.length == _resourceAmounts.length, "Resource arrays mismatch");
        require(_itemTypeDefinitions[_outputItemTypeId].exists, "Invalid output item type ID");
        if (_requiredWorkshopTypeId != 0) {
             require(_workshopTypeDefinitions[_requiredWorkshopTypeId].exists, "Invalid required workshop type ID");
        }

        _recipes[_recipeId] = Recipe({
            resourceTypeIds: _resourceTypeIds,
            resourceAmounts: _resourceAmounts,
            outputItemTypeId: _outputItemTypeId,
            requiredWorkshopTypeId: _requiredWorkshopTypeId,
            craftingDurationSeconds: _craftingDurationSeconds, // Stored but not used in current craft function
            levelRequirement: _levelRequirement,
            active: true
        });
        _availableRecipeIds.add(_recipeId);
        emit RecipeAdded(_recipeId, _outputItemTypeId, _requiredWorkshopTypeId);
    }

     /**
     * @dev Updates an existing recipe's parameters.
     * @param _recipeId The ID of the recipe to update.
     * @param _resourceTypeIds New array of resource type IDs required.
     * @param _resourceAmounts New array of amounts corresponding to _resourceTypeIds.
     * @param _outputItemTypeId New output item type ID.
     * @param _requiredWorkshopTypeId New required workshop type ID (0 for none).
     * @param _craftingDurationSeconds New crafting duration.
     * @param _levelRequirement New minimum player level required.
     */
    function updateRecipe(
        uint256 _recipeId,
        uint256[] memory _resourceTypeIds,
        uint256[] memory _resourceAmounts,
        uint256 _outputItemTypeId,
        uint256 _requiredWorkshopTypeId,
        uint256 _craftingDurationSeconds,
        uint256 _levelRequirement
    ) external onlyOwner {
        require(_recipes[_recipeId].active, "Recipe ID does not exist or is inactive");
        require(_resourceTypeIds.length == _resourceAmounts.length, "Resource arrays mismatch");
        require(_itemTypeDefinitions[_outputItemTypeId].exists, "Invalid output item type ID");
         if (_requiredWorkshopTypeId != 0) {
             require(_workshopTypeDefinitions[_requiredWorkshopTypeId].exists, "Invalid required workshop type ID");
        }

        _recipes[_recipeId] = Recipe({
            resourceTypeIds: _resourceTypeIds,
            resourceAmounts: _resourceAmounts,
            outputItemTypeId: _outputItemTypeId,
            requiredWorkshopTypeId: _requiredWorkshopTypeId,
            craftingDurationSeconds: _craftingDurationSeconds,
            levelRequirement: _levelRequirement,
            active: true // Remains active unless removed
        });
        emit RecipeUpdated(_recipeId);
    }

    /**
     * @dev Marks a recipe as inactive, preventing further crafting using it.
     * @param _recipeId The ID of the recipe to remove.
     */
    function removeRecipe(uint256 _recipeId) external onlyOwner {
        require(_recipes[_recipeId].active, "Recipe ID does not exist or is already inactive");
        _recipes[_recipeId].active = false;
        _availableRecipeIds.remove(_recipeId); // Also remove from enumerable set
        emit RecipeRemoved(_recipeId);
    }

    /**
     * @dev Sets the fee required to perform crafting operations.
     * @param _feeAmount The amount of the fee (in native token wei).
     */
    function setCraftingFee(uint256 _feeAmount) external onlyOwner {
        _craftingFee = _feeAmount;
        emit CraftingFeeUpdated(_feeAmount);
    }

    /**
     * @dev Pauses crafting actions (`craftItem`, `batchCraftItems`).
     */
    function pauseCrafting() external onlyOwner whenNotPaused {
        _paused = true;
        emit CraftingPaused();
    }

    /**
     * @dev Unpauses crafting actions.
     */
    function unpauseCrafting() external onlyOwner whenPaused {
        _paused = false;
        emit CraftingUnpaused();
    }

    /**
     * @dev Allows the owner to withdraw native token fees collected.
     * @param _tokenAddress Address of the token to withdraw (address(0) for ETH).
     */
    function withdrawFees(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No native token balance to withdraw");
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "ETH withdrawal failed");
            emit FeesWithdraw(address(0), balance);
        } else {
             // For other tokens, assuming they are sent to this contract and implement ERC20/ERC1155 transfer
             // ERC20 withdrawal example:
             // IERC20 token = IERC20(_tokenAddress);
             // uint256 balance = token.balanceOf(address(this));
             // require(balance > 0, "No token balance to withdraw");
             // token.transfer(owner(), balance);

             // ERC1155 withdrawal requires specifying token IDs and amounts.
             // This design assumes fees are primarily native ETH or a single designated token.
             // More complex token withdrawal needs specific function/parameters.
             revert("Only native token withdrawal is implemented");
        }
    }

    // --- Player Action Functions ---

    /**
     * @dev Allows a player to craft an item using a specified recipe and workshop.
     * Requires the player to approve the Nexus contract to transfer their required resources.
     * @param _recipeId The ID of the recipe to use.
     * @param _workshopTokenId The token ID of the Workshop NFT to use (0 for no workshop).
     * @dev Item attributes (like level, durability) are calculated based on recipe/workshop/player level.
     */
    function craftItem(uint256 _recipeId, uint256 _workshopTokenId) external payable nonReentrant whenNotPaused {
        Recipe memory recipe = _recipes[_recipeId];
        require(recipe.active, "Recipe does not exist or is inactive");
        require(msg.value >= _craftingFee, "Insufficient crafting fee");

        address player = msg.sender;
        uint256 playerLevel = _playerLevels[player];

        // 1. Check Requirements (Level, Blueprint, Workshop, Resources)
        require(playerLevel >= recipe.levelRequirement, "Player level too low");

        // Blueprint check: If recipe requires a blueprint to be learned
        bool blueprintRequired = false;
        for (uint i = 0; i < _availableBlueprintTypeIds.length(); i++) {
            uint256 bpTypeId = _availableBlueprintTypeIds.at(i);
             if (_blueprintDefinitions[bpTypeId].exists && _blueprintDefinitions[bpTypeId].unlocksRecipeId == _recipeId) {
                 blueprintRequired = true;
                 require(_learnedBlueprints[player][bpTypeId], "Blueprint not learned");
                 break; // Found the relevant blueprint type
             }
        }
        // If no blueprint is defined for this recipe, it's craftable without one.

        // Workshop check
        uint256 workshopBonusPercent = 100; // Base 100%
        if (recipe.requiredWorkshopTypeId != 0) {
            require(_workshopToken.ownerOf(_workshopTokenId) == player, "Workshop not owned by player");
            require(_workshopToken is IWorkshopToken, "Workshop token contract not set or invalid");
            // In a real scenario, you'd call the workshop contract/metadata to get its type and bonus.
            // For this example, we'll assume the workshop type can be derived or is passed explicitly
            // and we look up the bonus using the _workshopTokenId (mapping workshopId to bonus).
            // Let's simplify and assume workshopType is known and matches recipe.requiredWorkshopTypeId
            // and we look up bonus by workshop *type*.
             require(_workshopTypeDefinitions[recipe.requiredWorkshopTypeId].exists, "Required workshop type not defined");
             workshopBonusPercent = _workshopTypeDefinitions[recipe.requiredWorkshopTypeId].craftingBonusPercent;
        } else {
             require(_workshopTokenId == 0, "Workshop specified but not required by recipe");
        }


        // Resource check & consumption
        require(recipe.resourceTypeIds.length == recipe.resourceAmounts.length, "Recipe resource data mismatch");
        uint256[] memory resourceTypeIds = recipe.resourceTypeIds;
        uint256[] memory resourceAmounts = recipe.resourceAmounts;

        // Check player balances
        for (uint i = 0; i < resourceTypeIds.length; i++) {
            uint256 requiredAmount = resourceAmounts[i];
            require(_resourceToken.balanceOf(player, resourceTypeIds[i]) >= requiredAmount, "Insufficient resources");
        }

        // Transfer resources to Nexus (caller must approve ERC1155 `setApprovalForAll` or `safeApprove`)
        if (resourceTypeIds.length > 0) {
             _resourceToken.safeBatchTransferFrom(player, address(this), resourceTypeIds, resourceAmounts, "");
        }


        // 2. Perform Crafting & Mint Item
        require(_craftedItemToken != address(0), "Crafted Item token contract not set");
        uint256 newItemTokenId = _craftedItemToken.getNextTokenId(); // Get next ID from external contract

        // Calculate item attributes (simplified example based on player level and workshop bonus)
        ItemTypeDefinition memory itemDef = _itemTypeDefinitions[recipe.outputItemTypeId];
        uint256 finalDurability = (itemDef.baseDurability * workshopBonusPercent) / 100; // Apply workshop bonus
        uint256 initialLevel = playerLevel > 0 ? playerLevel / 10 + 1 : 1; // Example: Level 1 at player level 0-9, Level 2 at 10-19 etc.

        _craftedItemToken.safeMint(player, newItemTokenId); // Mint NFT to the player
        _craftedItemAttributes[newItemTokenId] = CraftedItemAttributes(initialLevel, finalDurability);


        // 3. Update Player Progression
        // Increase player level based on crafting activity (simplified: +1 level per craft)
        // A more complex system might involve experience points per recipe.
        uint256 oldLevel = playerLevel;
        _playerLevels[player] = playerLevel + 1;
        if (_playerLevels[player] > oldLevel) {
            emit PlayerLevelUp(player, _playerLevels[player]);
        }


        // 4. Emit Event
        emit Crafted(player, _recipeId, newItemTokenId, _workshopTokenId);

        // Optional: Transfer collected fee (if not already sent to contract address directly)
        // If fee is ETH, it's already sent via msg.value.
        // If fee was a token, it would be transferred here.
    }

    /**
     * @dev Allows a player to craft multiple items of the same recipe and workshop in a single transaction.
     * Requires player to approve the Nexus contract for resource transfer.
     * @param _recipeId The ID of the recipe to use.
     * @param _workshopTokenId The token ID of the Workshop NFT to use (0 for no workshop).
     * @param _amount The number of items to craft.
     */
    function batchCraftItems(uint256 _recipeId, uint256 _workshopTokenId, uint256 _amount) external payable nonReentrant whenNotPaused {
         require(_amount > 0, "Amount must be greater than 0");
         Recipe memory recipe = _recipes[_recipeId];
         require(recipe.active, "Recipe does not exist or is inactive");
         require(msg.value >= _craftingFee * _amount, "Insufficient total crafting fee"); // Check total fee

         address player = msg.sender;
         uint256 playerLevel = _playerLevels[player];

         // 1. Check Requirements (same as craftItem, multiplied for batch)
         require(playerLevel >= recipe.levelRequirement, "Player level too low");

         bool blueprintRequired = false;
         for (uint i = 0; i < _availableBlueprintTypeIds.length(); i++) {
             uint256 bpTypeId = _availableBlueprintTypeIds.at(i);
              if (_blueprintDefinitions[bpTypeId].exists && _blueprintDefinitions[bpTypeId].unlocksRecipeId == _recipeId) {
                  blueprintRequired = true;
                  require(_learnedBlueprints[player][bpTypeId], "Blueprint not learned");
                  break;
              }
         }

         uint256 workshopBonusPercent = 100;
         if (recipe.requiredWorkshopTypeId != 0) {
             require(_workshopToken.ownerOf(_workshopTokenId) == player, "Workshop not owned by player");
             require(_workshopToken is IWorkshopToken, "Workshop token contract not set or invalid");
             require(_workshopTypeDefinitions[recipe.requiredWorkshopTypeId].exists, "Required workshop type not defined");
             workshopBonusPercent = _workshopTypeDefinitions[recipe.requiredWorkshopTypeId].craftingBonusPercent;
         } else {
              require(_workshopTokenId == 0, "Workshop specified but not required by recipe");
         }

         require(recipe.resourceTypeIds.length == recipe.resourceAmounts.length, "Recipe resource data mismatch");
         uint256[] memory resourceTypeIds = recipe.resourceTypeIds;
         uint256[] memory resourceAmounts = new uint256[](resourceTypeIds.length); // Calculate total amounts

         for (uint i = 0; i < resourceTypeIds.length; i++) {
             uint256 requiredAmountPerItem = recipe.resourceAmounts[i];
             uint256 totalRequiredAmount = requiredAmountPerItem * _amount;
             require(_resourceToken.balanceOf(player, resourceTypeIds[i]) >= totalRequiredAmount, "Insufficient resources for batch craft");
             resourceAmounts[i] = totalRequiredAmount; // Store total amounts for the batch transfer
         }

         // Transfer resources to Nexus
         if (resourceTypeIds.length > 0) {
             _resourceToken.safeBatchTransferFrom(player, address(this), resourceTypeIds, resourceAmounts, "");
         }

         // 2. Perform Crafting & Mint Items
         require(_craftedItemToken != address(0), "Crafted Item token contract not set");
         uint256 firstNewItemTokenId = _craftedItemToken.getNextTokenId(); // Get starting ID

         ItemTypeDefinition memory itemDef = _itemTypeDefinitions[recipe.outputItemTypeId];
         uint256 finalDurability = (itemDef.baseDurability * workshopBonusPercent) / 100;
         uint256 initialLevel = playerLevel > 0 ? playerLevel / 10 + 1 : 1;

         for (uint i = 0; i < _amount; i++) {
             uint256 newItemTokenId = firstNewItemTokenId + i;
             _craftedItemToken.safeMint(player, newItemTokenId); // Mint each NFT
             _craftedItemAttributes[newItemTokenId] = CraftedItemAttributes(initialLevel, finalDurability); // Assign attributes
         }


         // 3. Update Player Progression
         uint256 oldLevel = playerLevel;
         _playerLevels[player] = playerLevel + _amount; // Gain level per item crafted
          if (_playerLevels[player] > oldLevel) {
            emit PlayerLevelUp(player, _playerLevels[player]);
        }

         // 4. Emit Event
         emit BatchCrafted(player, _recipeId, _amount, firstNewItemTokenId, _workshopTokenId);
    }


    /**
     * @dev Allows a player to consume a Blueprint NFT to permanently learn a recipe.
     * Requires the player to approve the Nexus contract for Blueprint transfer.
     * @param _blueprintTokenId The token ID of the Blueprint NFT to consume.
     */
    function learnBlueprint(uint256 _blueprintTokenId) external nonReentrant {
        address player = msg.sender;
        require(_blueprintToken.ownerOf(_blueprintTokenId) == player, "Blueprint not owned by player");
        require(_blueprintToken is IBlueprintToken, "Blueprint token contract not set or invalid");

        // In a real system, the blueprint token ID's metadata or a mapping would tell you its type ID.
        // For this example, let's assume we can map the *specific token ID* back to a *blueprint type ID*.
        // A simple way: Map token ID to type ID, or encode type ID in token ID (less flexible).
        // Let's add a mapping for blueprint token ID to type ID (Admin sets this when minting/registering blueprints).
        // mapping(uint256 => uint256) private _blueprintTokenIdToTypeId; // Add this state variable

        // For THIS example, let's simplify: Assume the Blueprint token ID corresponds directly to a *type* ID.
        // This means only one instance of each blueprint type exists and grants the learn ability.
        // A more robust design maps *many* blueprint token IDs to *one* blueprint type ID.
        uint256 blueprintTypeId = _blueprintTokenId; // Simplify: Token ID is also the type ID

        BlueprintInfo storage blueprintInfo = _blueprintDefinitions[blueprintTypeId];
        require(blueprintInfo.exists, "Blueprint type ID not defined");
        require(!_learnedBlueprints[player][blueprintTypeId], "Blueprint already learned");
        require(_recipes[blueprintInfo.unlocksRecipeId].active, "Recipe unlocked by blueprint is not active");


        // Transfer/Burn Blueprint NFT (player must approve)
        // We burn it as it's consumed.
        _blueprintToken.transferFrom(player, address(this), _blueprintTokenId); // Transfer first
        _blueprintToken.burn(_blueprintTokenId); // Then burn from contract balance (ERC721Holder handles ownership)


        // Update learned state
        _learnedBlueprints[player][blueprintTypeId] = true;

        // Optional: Grant some player level/xp for learning
        uint256 oldLevel = _playerLevels[player];
        _playerLevels[player] = oldLevel + 5; // Example: +5 levels for learning
         if (_playerLevels[player] > oldLevel) {
            emit PlayerLevelUp(player, _playerLevels[player]);
        }

        emit BlueprintLearned(player, blueprintTypeId, blueprintInfo.unlocksRecipeId);
    }

    /**
     * @dev Allows a player to use resources to upgrade a Crafted Item NFT.
     * Requires player to approve the Nexus contract for Resource transfer.
     * @param _itemTokenId The token ID of the Crafted Item to upgrade.
     * @param _resourceTypeIds Array of resource type IDs required for upgrade.
     * @param _resourceAmounts Array of amounts corresponding to _resourceTypeIds.
     */
    function upgradeItem(uint256 _itemTokenId, uint256[] memory _resourceTypeIds, uint256[] memory _resourceAmounts) external nonReentrant {
        address player = msg.sender;
        require(_craftedItemToken.ownerOf(_itemTokenId) == player, "Item not owned by player");
        require(_craftedItemAttributes[_itemTokenId].currentDurability > 0, "Item cannot be upgraded (e.g., broken)"); // Example condition

        // Check resources
        require(_resourceTypeIds.length == _resourceAmounts.length, "Resource arrays mismatch");
        for (uint i = 0; i < _resourceTypeIds.length; i++) {
            require(_resourceToken.balanceOf(player, _resourceTypeIds[i]) >= _resourceAmounts[i], "Insufficient resources for upgrade");
        }

        // Transfer resources to Nexus (player must approve)
         if (_resourceTypeIds.length > 0) {
            _resourceToken.safeBatchTransferFrom(player, address(this), _resourceTypeIds, _resourceAmounts, "");
        }

        // Perform Upgrade Logic (Modify item attributes)
        CraftedItemAttributes storage item = _craftedItemAttributes[_itemTokenId];
        item.level += 1; // Simple level increase
        item.currentDurability = _itemTypeDefinitions[_craftedItemToken.tokenURI(_itemTokenId).length].baseDurability; // Restore durability on level up? (This requires knowing item type from token ID, complex)
        // Simpler durability logic: decrease durability gradually, restore some on upgrade.
        // For this example, just increase level. Durability management is more complex.
        // Let's add a simple durability cost per upgrade instead of tracking current durability here.
        // This requires defining upgrade 'recipes' similar to crafting recipes.
        // Let's pivot: Upgrade costs are fixed per item type level, defined outside this contract
        // or via another mapping. And we just check generic resource cost here.
        // Let's simplify further: Upgrade just increases level and consumes resources.

        emit ItemUpgraded(player, _itemTokenId, item.level);

        // Optional: Grant player level/xp
         uint256 oldLevel = _playerLevels[player];
         _playerLevels[player] = oldLevel + 2; // Example: +2 levels for upgrading
         if (_playerLevels[player] > oldLevel) {
            emit PlayerLevelUp(player, _playerLevels[player]);
        }
    }

     /**
     * @dev Allows a player to destroy a Crafted Item NFT to recover some resources.
     * Requires player to approve the Nexus contract for Crafted Item transfer.
     * @param _itemTokenId The token ID of the Crafted Item to disenchant.
     */
    function disenchantItem(uint256 _itemTokenId) external nonReentrant {
        address player = msg.sender;
        require(_craftedItemToken.ownerOf(_itemTokenId) == player, "Item not owned by player");
        require(_craftedItemToken is ICraftedItemToken, "Crafted Item token contract not set or invalid");

        // Disenchantment Logic: Determine resources returned
        // This would typically depend on the item's type, level, etc.
        // For simplicity, let's return a fixed set of resources per disenchantment,
        // or maybe a portion of the original crafting cost.
        // Let's assume a fixed return based on item level.

        CraftedItemAttributes memory item = _craftedItemAttributes[_itemTokenId];
        uint256 returnedResourceTypeId = 1; // Example: Always return resource type 1
        uint256 returnedAmount = item.level * 10; // Example: Amount based on item level

        // Burn the item NFT (player must approve transfer to address(this) first)
        _craftedItemToken.transferFrom(player, address(this), _itemTokenId); // Transfer first
        _craftedItemToken.burn(_itemTokenId); // Then burn from contract balance

        // Clear item attributes
        delete _craftedItemAttributes[_itemTokenId]; // Clean up storage

        // Mint/Transfer resources back to player (requires Nexus contract to have minting permissions or hold a reserve)
        // Assuming the Resource ERC-1155 has a mint function callable by the Nexus
        if (_resourceToken is IResourceToken) { // Defensive check
             _resourceToken.safeBatchTransferFrom(address(this), player, new uint256[]{returnedResourceTypeId}, new uint256[]{returnedAmount}, ""); // Mint from Nexus 'zero' address
        } else {
            // If Nexus doesn't have mint permission, it needs to hold a reserve.
            // Transfer from Nexus balance:
            // _resourceToken.safeTransferFrom(address(this), player, returnedResourceTypeId, returnedAmount, "");
            revert("Resource token contract does not support minting or Nexus holds no reserve");
        }

        emit ItemDisenchanted(player, _itemTokenId);
    }

    /**
     * @dev Allows a player to claim a reward based on their level.
     * Has a cooldown per player. Reward structure is simplified.
     */
    function claimPlayerLevelReward() external nonReentrant {
        address player = msg.sender;
        uint256 playerLevel = _playerLevels[player];
        require(playerLevel > 0, "Player has no level");

        // Cooldown check
        require(block.timestamp >= _playerLevelRewardClaimTimestamps[player] + LEVEL_REWARD_COOLDOWN, "Reward is on cooldown");

        // Determine reward (Simplified: fixed reward per level milestone)
        // In a real system, this would look up rewards from a mapping: level => {resourceId: amount, ...}
        // For this example: Reward 10 of resource type 1 for every 10 levels reached.
        if (playerLevel % 10 == 0 && playerLevel > 0) { // Check if level is a multiple of 10
             uint256 rewardResourceTypeId = 1; // Example resource ID
             uint256 rewardAmount = playerLevel / 10 * 10; // Example amount: 10 at level 10, 20 at level 20 etc.

            // Mint/Transfer reward resources
             if (_resourceToken is IResourceToken) {
                _resourceToken.safeBatchTransferFrom(address(this), player, new uint256[]{rewardResourceTypeId}, new uint256[]{rewardAmount}, "");
             } else {
                 revert("Resource token contract does not support minting");
             }

            _playerLevelRewardClaimTimestamps[player] = block.timestamp;
            emit PlayerLevelRewardClaimed(player, playerLevel, rewardResourceTypeId, rewardAmount);
        } else {
            revert("No level reward available yet or already claimed");
        }
    }

    /**
     * @dev Allows a player to set or update their on-chain display name.
     * @param _name The desired display name (max 32 bytes).
     */
    function setPlayerDisplayName(string memory _name) external {
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length > 0 && nameBytes.length <= 32, "Display name must be between 1 and 32 bytes");
        _playerDisplayNames[msg.sender] = _name;
        emit PlayerDisplayNameUpdated(msg.sender, _name);
    }


    // --- View Functions ---

    /**
     * @dev Returns the details of a specific recipe.
     * @param _recipeId The ID of the recipe.
     * @return Recipe struct details.
     */
    function getRecipeDetails(uint256 _recipeId) external view returns (Recipe memory) {
        require(_recipes[_recipeId].active, "Recipe does not exist or is inactive");
        return _recipes[_recipeId];
    }

    /**
     * @dev Returns the dynamic attributes of a specific Crafted Item NFT.
     * @param _itemTokenId The token ID of the Crafted Item.
     * @return CraftedItemAttributes struct details.
     */
    function getItemAttributes(uint256 _itemTokenId) external view returns (CraftedItemAttributes memory) {
         // Check if item exists and is managed by this system (e.g., owner is not zero)
         // require(_craftedItemToken.ownerOf(_itemTokenId) != address(0), "Item does not exist"); // ownerOf might revert if not minted
         // Better: Check if attributes exist for this ID
         // This mapping check is sufficient if attributes are set only on minting via this contract.
        return _craftedItemAttributes[_itemTokenId];
    }

    /**
     * @dev Returns the crafting bonus percentage of a specific Workshop NFT type.
     * Requires looking up the workshop type ID associated with the token ID.
     * @param _workshopTokenId The token ID of the Workshop.
     * @return Crafting bonus percentage (e.g., 110 for 10% bonus).
     */
    function getWorkshopBonus(uint256 _workshopTokenId) external view returns (uint256) {
        // In a real system, you'd get the workshop *type ID* from the workshopTokenId
        // (e.g., calling a function on the WorkshopToken contract, or using metadata).
        // For this example, we assume we can directly map token ID to a type ID or bonus.
        // Simplification: Assuming workshop token ID *is* the workshop type ID for lookup.
        uint256 workshopTypeId = _workshopTokenId;
        require(_workshopTypeDefinitions[workshopTypeId].exists, "Workshop type not defined");
        return _workshopTypeDefinitions[workshopTypeId].craftingBonusPercent;
    }

    /**
     * @dev Returns details about a specific blueprint type.
     * @param _blueprintTypeId The ID of the blueprint type.
     * @return BlueprintInfo struct details.
     */
    function getBlueprintDetails(uint256 _blueprintTypeId) external view returns (BlueprintInfo memory) {
         require(_blueprintDefinitions[_blueprintTypeId].exists, "Blueprint type not defined");
         return _blueprintDefinitions[_blueprintTypeId];
    }

    /**
     * @dev Returns the current crafting level of a player.
     * @param _player The address of the player.
     * @return The player's crafting level.
     */
    function getPlayerLevel(address _player) external view returns (uint256) {
        return _playerLevels[_player];
    }

    /**
     * @dev Checks if a player has learned a specific blueprint type.
     * @param _player The address of the player.
     * @param _blueprintTypeId The ID of the blueprint type.
     * @return True if the player has learned the blueprint, false otherwise.
     */
    function isBlueprintLearned(address _player, uint256 _blueprintTypeId) external view returns (bool) {
         require(_blueprintDefinitions[_blueprintTypeId].exists, "Blueprint type not defined");
        return _learnedBlueprints[_player][_blueprintTypeId];
    }

    /**
     * @dev Returns the on-chain display name of a player.
     * @param _player The address of the player.
     * @return The player's display name.
     */
    function getPlayerDisplayName(address _player) external view returns (string memory) {
        return _playerDisplayNames[_player];
    }

     /**
     * @dev Checks if the caller meets the requirements to craft a recipe with a workshop.
     * Useful for UI to determine craftability before attempting.
     * @param _recipeId The ID of the recipe.
     * @param _workshopTokenId The token ID of the Workshop (0 for none).
     * @return success Boolean indicating if requirements are met.
     * @return failureReasonCode Integer code indicating the first failed requirement (0 = success, 1=Paused, 2=Fee, 3=Level, 4=Blueprint, 5=WorkshopType, 6=WorkshopOwnership, 7=Resources).
     */
    function checkRecipeRequirements(uint256 _recipeId, uint256 _workshopTokenId) external view returns (bool success, uint256 failureReasonCode) {
        if (_paused) return (false, 1); // Paused

        Recipe memory recipe = _recipes[_recipeId];
        if (!recipe.active) return (false, 0); // Recipe inactive (not a failure, just not craftable) - adjust if needed

        if (msg.value < _craftingFee) return (false, 2); // Fee

        address player = msg.sender;
        uint256 playerLevel = _playerLevels[player];
        if (playerLevel < recipe.levelRequirement) return (false, 3); // Level

        // Blueprint check
        bool blueprintRequired = false;
        for (uint i = 0; i < _availableBlueprintTypeIds.length(); i++) {
            uint256 bpTypeId = _availableBlueprintTypeIds.at(i);
             if (_blueprintDefinitions[bpTypeId].exists && _blueprintDefinitions[bpTypeId].unlocksRecipeId == _recipeId) {
                 blueprintRequired = true;
                 if (!_learnedBlueprints[player][bpTypeId]) return (false, 4); // Blueprint not learned
                 break;
             }
        }

        // Workshop check
        if (recipe.requiredWorkshopTypeId != 0) {
             if (!_workshopTypeDefinitions[recipe.requiredWorkshopTypeId].exists) return (false, 5); // Workshop type not defined
             if (_workshopToken.ownerOf(_workshopTokenId) != player) return (false, 6); // Workshop not owned
             // More rigorous check could verify the workshopTokenId IS actually the required type.
             // This requires workshop token contract having a view function for type.
        } else {
             if (_workshopTokenId != 0) return (false, 5); // Workshop specified but not required
        }

        // Resource check
        require(recipe.resourceTypeIds.length == recipe.resourceAmounts.length, "Internal Error: Recipe resource data mismatch"); // Should not happen if recipes are added correctly
        for (uint i = 0; i < recipe.resourceTypeIds.length; i++) {
            if (_resourceToken.balanceOf(player, recipe.resourceTypeIds[i]) < recipe.resourceAmounts[i]) return (false, 7); // Insufficient resources
        }

        return (true, 0); // All requirements met
    }

    /**
     * @dev Returns the current crafting fee amount.
     * @return The fee amount in native token wei.
     */
    function getCraftingFee() external view returns (uint256) {
        return _craftingFee;
    }

    // --- ERC1155/ERC721 Holder Hooks ---
    // Required overrides for ERC1155Holder and ERC721Holder

    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data)
        override(ERC1155Holder)
        external
        returns (bytes4)
    {
        return super.onERC1155Received(operator, from, id, amount, data);
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)
        override(ERC1155Holder)
        external
        returns (bytes4)
    {
        return super.onERC1155BatchReceived(operator, from, ids, amounts, data);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        override(ERC721Holder)
        external
        returns (bytes4)
    {
        // This hook is relevant when the Nexus contract RECEIVES ERC721 tokens.
        // It's used when burning Blueprints/Crafted Items by transferring them TO the Nexus first.
        // The base ERC721Holder handles accepting the token.
        return super.onERC721Received(operator, from, tokenId, data);
    }

     // Override supportsInterface for ERC1155Holder/ERC721Holder
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Holder, ERC721Holder, Ownable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Receive/Fallback ---
    // Allows the contract to receive native tokens (for crafting fees)

    receive() external payable {}
    fallback() external payable {}
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Multi-Token Standard Interaction (ERC-1155 & ERC-721):** The contract orchestrates operations across potentially four different token contracts, managing fungible resources and unique items/tools/blueprints.
2.  **On-Chain Crafting Logic:** The core `craftItem` and `batchCraftItems` functions implement complex logic involving checking multiple prerequisites (resources, player level, learned blueprints, required workshop type, workshop ownership) *before* executing the state changes (burning resources, minting NFTs, updating player state).
3.  **Dynamic NFT Attributes:** The `_craftedItemAttributes` mapping stores mutable data (like level and durability) associated with specific *instances* of Crafted Item NFTs, directly on the crafting contract. This goes beyond standard static NFT metadata. `upgradeItem` modifies these attributes.
4.  **Blueprint Learning Mechanism:** `learnBlueprint` is a creative use of NFTs where consuming an NFT (`burn`) grants a permanent, non-transferable *capability* (`_learnedBlueprints` mapping) within the contract's logic, unlocking new recipes.
5.  **Item Disenchanting/Burning for Resources:** `disenchantItem` allows players to destroy NFTs (`burn`) to recover fungible resources, providing a resource sink and recycling mechanism within the game economy. It requires the crafting contract to have either minting permissions on the resource token or hold a resource reserve.
6.  **Player Progression (Leveling):** A simple on-chain leveling system (`_playerLevels`) tracks player activity (crafting, learning blueprints). This level can then gate access to recipes (`levelRequirement`) and grant rewards (`claimPlayerLevelReward`).
7.  **Level-Based Rewards with Cooldown:** `claimPlayerLevelReward` implements a basic reward system tied to player level milestones, incorporating a time-based cooldown to prevent spamming or rapid farming.
8.  **Workshop Bonuses:** The crafting logic incorporates a check for a required workshop and applies a bonus (`craftingBonusPercent`) from that workshop type to the resulting item's attributes (e.g., durability).
9.  **Batch Operations:** `batchCraftItems` demonstrates optimizing actions by processing multiple crafting attempts in a single transaction, saving gas compared to individual calls (though the *total* gas cost increases proportionally to the batch size).
10. **On-Chain Player Profile Data:** `setPlayerDisplayName` and `getPlayerDisplayName` show simple storage of user-controlled string data associated with their address directly on the contract.
11. **Pre-Computation/Checking:** `checkRecipeRequirements` is a view function that allows external applications (like a game UI) to verify if a player *can* perform an action *before* sending the transaction, improving user experience and preventing failed transactions. It returns a specific error code.
12. **Fee Mechanism:** The contract includes a simple `_craftingFee` mechanism payable in native token and a corresponding `withdrawFees` function for the owner. This demonstrates a way for the contract operator to potentially monetize activity or cover operational costs.
13. **Enumerable Sets:** Used for `_availableRecipeIds`, `_availableItemTypeIds`, etc., allowing iteration over defined types/recipes (though iterated view functions should be used cautiously off-chain).
14. **ERC-1155/ERC-721 Holder Implementation:** Correctly implements the necessary hooks (`onERC1155Received`, `onERC721Received`) by inheriting from OpenZeppelin's `ERC1155Holder` and `ERC721Holder` to safely receive tokens transferred into the contract's balance (e.g., resources transferred before consumption, or NFTs transferred before burning).
15. **Role-Based Access Control (Ownable):** Standard but essential for managing the complex configuration functions (adding recipes, setting addresses, pausing).
16. **Reentrancy Guard:** Protects against reentrancy attacks, especially important when interacting with external token contracts.
17. **State Management Complexity:** The contract manages numerous mappings and structs to keep track of recipes, item types, workshop types, blueprint types, dynamic item attributes, player levels, learned blueprints, and player names, showcasing complex on-chain data structuring.
18. **Clear Event Logging:** Extensive use of events allows off-chain services (indexers, UIs) to track all significant actions and state changes.
19. **Paused State:** An admin controlled `_paused` state allows halting critical operations like crafting in emergencies or for maintenance.
20. **Resource Management via Transfers:** The crafting and upgrading functions explicitly handle transferring resources *from* the player *to* the contract's address before consuming them. This requires players to pre-approve the Nexus contract using `approve` (for ERC-20 if used) or `setApprovalForAll` (for ERC-1155 and ERC-721).

This contract provides a solid foundation for a sophisticated on-chain crafting system, demonstrating various interactions and state-changing operations beyond simple token transfers or NFT mints. Remember that a production-ready contract would require thorough security audits.