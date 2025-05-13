Okay, let's create a smart contract for a complex, interactive *Metaverse Nexus*. This contract will manage virtual entities like Avatars and Parcels, incorporate dynamic state (like Avatar skills, energy, Parcel resources), resource harvesting, crafting, and a delegation mechanism. It will *simulate* NFT behavior for Avatars and Parcels without directly inheriting a standard ERC721 to ensure it's not a direct open-source copy, while still providing core ownership and state management.

Here's the structure and the code:

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MetaverseNexus
 * @dev A complex smart contract for managing virtual entities, interactions,
 *      resources, skills, and dynamic state within a simulated metaverse environment.
 *      This contract incorporates concepts like dynamic NFTs (simulated), on-chain
 *      resource management, crafting, character progression (skills, energy),
 *      and action delegation.
 *
 *      Outline:
 *      1.  Admin & Setup: Core contract configuration and adding metaverse element types.
 *      2.  Data Structures: Defines structs for key entities (Avatar, Parcel, Item, Skill, Recipe).
 *      3.  Counters & Mappings: Track unique IDs and entity data.
 *      4.  Events: Signal key state changes.
 *      5.  Modifiers: Restrict function access based on roles or state.
 *      6.  Internal Helpers: Logic functions used internally.
 *      7.  Core Entity Management (Simulated NFTs): Minting, transfer, getting details for Avatars and Parcels.
 *      8.  Dynamic State & Interaction:
 *          - Location management (Avatar movement).
 *          - Resource Harvesting (interaction between Avatar, Skill, Parcel, and Resources).
 *          - Item Management & Usage (Inventory, equipping, consuming).
 *          - Skill Progression (Gaining exp, leveling up).
 *          - Crafting (Combining resources/items using skills).
 *          - Parcel Development (Improving parcels using resources/skills).
 *          - Nexus Energy (Non-transferable energy/reputation tied to Avatars).
 *      9.  Inventory Management (Parcel & Avatar): Moving items between entities.
 *      10. Delegation: Allowing a third party to perform actions on behalf of an Avatar owner.
 *      11. Getters: Public functions to query contract state.
 *
 *      Function Summary (20+ Functions):
 *      - Setup:
 *          - constructor(): Initializes the contract with an admin.
 *          - addResourceToken(): Registers a valid ERC20 token as a resource.
 *          - addParcelType(): Defines characteristics for a new type of parcel.
 *          - addItemType(): Defines characteristics for a new type of item.
 *          - addSkillType(): Defines characteristics for a new type of skill.
 *          - addCraftingRecipe(): Defines a recipe for crafting items.
 *      - Admin:
 *          - setAdmin(): Transfers admin ownership.
 *          - updateParcelResourceYield(): Modifies resource yield rate for a parcel type.
 *          - updateCraftingRecipe(): Modifies an existing crafting recipe.
 *      - Entity Management (Simulated NFTs):
 *          - mintAvatar(): Creates a new Avatar entity and assigns ownership.
 *          - transferAvatar(): Transfers ownership of an Avatar.
 *          - getAvatarDetails(): Retrieves detailed state of an Avatar.
 *          - mintParcel(): Creates a new Parcel entity and assigns ownership.
 *          - transferParcel(): Transfers ownership of a Parcel.
 *          - getParcelDetails(): Retrieves detailed state of a Parcel.
 *          - setAvatarMetadataURI(): Updates the metadata URI for an Avatar (dynamic aspect).
 *          - setParcelDescription(): Sets a custom description for a Parcel (dynamic aspect).
 *      - Core Interaction & Dynamic State:
 *          - moveAvatar(): Changes an Avatar's current location to a specified Parcel.
 *          - harvestResource(): Attempts to harvest resources from the Avatar's current Parcel.
 *          - useItem(): Consumes or applies an item from an Avatar's inventory.
 *          - levelUpSkill(): Allows an Avatar owner to spend experience to level up a skill.
 *          - craftItem(): Attempts to craft an item using resources and items in the Avatar's inventory.
 *          - developParcel(): Improves the Avatar's current Parcel using resources and skills.
 *          - spendNexusEnergy(): Allows spending accumulated Nexus Energy for benefits.
 *      - Inventory/Resource Management:
 *          - depositResourceToContract(): Allows users to deposit registered ERC20 resources into the contract.
 *          - withdrawResourceFromContract(): Allows users to withdraw deposited ERC20 resources.
 *          - depositItemToParcel(): Moves an item from Avatar inventory to Parcel inventory.
 *          - withdrawItemFromParcel(): Moves an item from Parcel inventory to Avatar inventory.
 *      - Delegation:
 *          - delegateAvatarAction(): Grants a specific address permission to act on behalf of an Avatar.
 *          - revokeAvatarDelegate(): Removes delegation permission.
 *      - Getters (Additional for 20+ count):
 *          - getAvatarInventory(): Lists items held by an Avatar.
 *          - getParcelInventory(): Lists items held by a Parcel.
 *          - getAvatarSkills(): Lists skills and levels for an Avatar.
 *          - getParcelOccupants(): Lists Avatars currently located on a Parcel.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for Ownable as it's standard and good practice.

contract MetaverseNexus is Ownable {
    using SafeERC20 for IERC20;

    // --- Data Structures ---

    struct Avatar {
        uint256 id;
        address owner;
        string name;
        uint256 currentParcelId; // 0 means not on any parcel
        uint256 nexusEnergy; // Non-transferable energy/reputation
        mapping(uint256 => Skill) skills; // skillTypeId => Skill
        mapping(uint256 => uint256) inventory; // itemId => quantity (for stackable) OR count (for unique)
        string metadataURI; // Dynamic metadata link
    }

    struct Skill {
        uint256 skillTypeId;
        uint256 level;
        uint256 experience;
    }

    struct Parcel {
        uint256 id;
        address owner;
        uint256 parcelTypeId;
        int256 x; // Coordinate X
        int256 y; // Coordinate Y
        uint256 developmentLevel;
        mapping(uint256 => uint256) resourcesAvailable; // resourceTypeId => quantity
        mapping(uint256 => uint256) inventory; // itemId => quantity (for stackable) OR count (for unique)
        string description; // Dynamic description
    }

    struct Item {
        uint256 id;
        uint256 itemTypeId;
        uint256 durability; // Example dynamic state
        // Could add more state like enchantment, etc.
    }

    struct ParcelType {
        string name;
        mapping(uint256 => uint256) baseResourceYield; // resourceTypeId => base quantity per harvest
        uint256 developmentCost; // Cost in resources/energy to develop
    }

    struct ItemType {
        string name;
        bool stackable;
        uint256 maxDurability; // 0 if not applicable (e.g., consumable)
        uint256 harvestBoost; // % boost to harvest yield when used (if applicable)
        uint256 craftingBoost; // % boost to crafting success/speed (if applicable)
        uint256 skillBoost; // flat boost to a specific skill when equipped/used
        uint256 boostedSkillTypeId; // Which skill is boosted
    }

    struct SkillType {
        string name;
        uint256 xpToLevelUp; // Base XP needed for level 1->2
    }

    struct CraftingRecipe {
        uint256 outputItemTypeId;
        uint256 outputQuantity; // For stackable items
        mapping(uint256 => uint256) requiredResources; // resourceTypeId => quantity
        mapping(uint256 => uint256) requiredItems; // itemTypeId => quantity
        mapping(uint256 => uint256) requiredSkills; // skillTypeId => minimum level
        uint256 requiredNexusEnergy;
    }

    // --- State Variables ---

    address public admin; // Using Ownable for admin access
    uint256 public nextAvatarId = 1;
    uint256 public nextParcelId = 1;
    uint256 public nextItemId = 1;
    uint256 public nextItemTypeId = 1; // Start types from 1
    uint256 public nextSkillTypeId = 1;
    uint256 public nextParcelTypeId = 1;
    uint256 public nextRecipeId = 1;

    // Entity Storage
    mapping(uint256 => Avatar) public avatars; // avatarId => Avatar
    mapping(uint256 => Parcel) public parcels; // parcelId => Parcel
    mapping(uint256 => Item) public items; // itemId => Item (for unique items)

    // Type Definitions
    mapping(uint256 => ParcelType) public parcelTypes; // parcelTypeId => ParcelType
    mapping(uint256 => ItemType) public itemTypes; // itemTypeId => ItemType
    mapping(uint256 => SkillType) public skillTypes; // skillTypeId => SkillType
    mapping(uint256 => CraftingRecipe) public craftingRecipes; // recipeId => CraftingRecipe

    // Registered ERC20 Resource Tokens
    mapping(address => bool) public isResourceToken; // resourceTokenAddress => bool
    mapping(uint256 => address) public resourceTokenAddresses; // resourceTypeId => address
    mapping(address => uint256) public resourceTokenTypes; // address => resourceTypeId (Helper)
    uint256 public nextResourceTypeId = 1;

    // Contract's resource balances (ERC20 held here for crafting costs etc.)
    mapping(address => uint256) public contractResourceBalances; // resourceTokenAddress => balance

    // Entity Ownership & Location Mappings (Simulating NFT ownership/location)
    mapping(uint256 => address) private avatarOwner; // avatarId => owner address
    mapping(address => uint256[]) private ownerAvatars; // owner address => array of avatarIds
    mapping(uint256 => uint256) private avatarLocation; // avatarId => parcelId (0 if unlocated)

    mapping(uint256 => address) private parcelOwner; // parcelId => owner address
    mapping(address => uint256[]) private ownerParcels; // owner address => array of parcelIds
    mapping(uint256 => uint256[]) private parcelOccupants; // parcelId => array of avatarIds

    // Item Location (Either Avatar ID or Parcel ID, using 0 for neither/burned)
    mapping(uint256 => uint256) private itemLocationAvatar; // itemId => avatarId (if in avatar inventory)
    mapping(uint256 => uint256) private itemLocationParcel; // itemId => parcelId (if in parcel inventory)


    // Delegation Mapping: avatarId => delegateAddress
    mapping(uint256 => address) public avatarDelegates;

    // --- Events ---

    event AvatarMinted(uint256 indexed avatarId, address indexed owner, string name);
    event AvatarTransferred(uint256 indexed avatarId, address indexed from, address indexed to);
    event AvatarMoved(uint256 indexed avatarId, uint256 indexed fromParcelId, uint256 indexed toParcelId);
    event AvatarMetadataUpdated(uint256 indexed avatarId, string newURI);
    event ParcelMinted(uint256 indexed parcelId, address indexed owner, uint256 parcelTypeId, int256 x, int256 y);
    event ParcelTransferred(uint256 indexed parcelId, address indexed from, address indexed to);
    event ParcelDeveloped(uint256 indexed parcelId, uint256 newDevelopmentLevel);
    event ParcelDescriptionUpdated(uint256 indexed parcelId, string newDescription);
    event ResourceHarvested(uint256 indexed avatarId, uint256 indexed parcelId, uint256 indexed resourceTypeId, uint256 amount);
    event ItemMinted(uint256 indexed itemId, uint256 itemTypeId, uint256 initialLocationAvatarId, uint256 initialLocationParcelId); // Indicate where it was minted into
    event ItemTransferred(uint256 indexed itemId, uint256 indexed fromAvatarId, uint256 indexed toAvatarId, uint256 fromParcelId, uint256 toParcelId);
    event ItemUsed(uint256 indexed avatarId, uint256 indexed itemId, uint256 itemTypeId, uint256 remainingDurability);
    event SkillGainedXP(uint256 indexed avatarId, uint256 indexed skillTypeId, uint256 newExperience);
    event SkillLeveledUp(uint256 indexed avatarId, uint256 indexed skillTypeId, uint256 newLevel);
    event ItemCrafted(uint256 indexed avatarId, uint256 indexed recipeId, uint256 outputItemTypeId, uint256 outputQuantity, uint256 firstOutputItemId); // firstOutputItemId useful for unique items
    event NexusEnergyGained(uint256 indexed avatarId, uint256 amount);
    event NexusEnergySpent(uint256 indexed avatarId, uint256 amount);
    event ResourceDeposited(address indexed user, uint256 indexed resourceTypeId, uint256 amount);
    event ResourceWithdrawal(address indexed user, uint256 indexed resourceTypeId, uint256 amount);
    event ItemDepositedToParcel(uint256 indexed avatarId, uint256 indexed parcelId, uint256 indexed itemId, uint256 itemTypeId, uint256 quantity); // Quantity for stackable
    event ItemWithdrawalFromParcel(uint256 indexed avatarId, uint256 indexed parcelId, uint256 indexed itemId, uint256 itemTypeId, uint256 quantity); // Quantity for stackable
    event AvatarDelegationSet(uint256 indexed avatarId, address indexed delegate);
    event AvatarDelegationRevoked(uint256 indexed avatarId, address indexed oldDelegate);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin"); // Using Ownable's owner
        _;
    }

    modifier onlyAvatarOwner(uint256 _avatarId) {
        require(avatarOwner[_avatarId] == msg.sender || avatarDelegates[_avatarId] == msg.sender, "Not avatar owner or delegate");
        _;
    }

     modifier onlyParcelOwner(uint256 _parcelId) {
        require(parcelOwner[_parcelId] == msg.sender, "Not parcel owner");
        _;
    }

    modifier avatarExists(uint256 _avatarId) {
        require(avatarOwner[_avatarId] != address(0), "Avatar does not exist");
        _;
    }

     modifier parcelExists(uint256 _parcelId) {
        require(parcelOwner[_parcelId] != address(0), "Parcel does not exist");
        _;
    }

    modifier itemExists(uint256 _itemId) {
        require(items[_itemId].id != 0, "Item does not exist");
        _;
    }

    modifier isRegisteredResourceToken(address _tokenAddress) {
        require(isResourceToken[_tokenAddress], "Token is not a registered resource");
        _;
    }

    modifier isRegisteredParcelType(uint256 _parcelTypeId) {
        require(parcelTypes[_parcelTypeId].baseResourceYield[0] != 0 || bytes(parcelTypes[_parcelTypeId].name).length > 0, "Parcel type does not exist"); // Check a non-zero field or non-empty string
        _;
    }

    modifier isRegisteredItemType(uint256 _itemTypeId) {
        require(itemTypes[_itemTypeId].maxDurability != 0 || bytes(itemTypes[_itemTypeId].name).length > 0, "Item type does not exist");
        _;
    }

    modifier isRegisteredSkillType(uint256 _skillTypeId) {
         require(skillTypes[_skillTypeId].xpToLevelUp != 0 || bytes(skillTypes[_skillTypeId].name).length > 0, "Skill type does not exist");
        _;
    }

     modifier isRegisteredRecipe(uint256 _recipeId) {
         require(craftingRecipes[_recipeId].outputItemTypeId != 0 || craftingRecipes[_recipeId].requiredNexusEnergy != 0, "Recipe does not exist");
        _;
    }


    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // admin is set by Ownable
        admin = msg.sender;
    }

    // --- Setup & Admin Functions ---

    function setAdmin(address _newAdmin) public virtual onlyOwner {
        admin = _newAdmin; // This state variable is redundant if using Ownable's owner(), but kept for clarity as per outline. The Ownable transferOwnership is the secure way.
        transferOwnership(_newAdmin); // Transfer Ownable ownership
    }

    function addResourceToken(address _tokenAddress) public onlyAdmin {
        require(_tokenAddress != address(0), "Invalid address");
        require(!isResourceToken[_tokenAddress], "Resource token already registered");
        uint256 typeId = nextResourceTypeId++;
        isResourceToken[_tokenAddress] = true;
        resourceTokenAddresses[typeId] = _tokenAddress;
        resourceTokenTypes[_tokenAddress] = typeId;
        // Initialize contract balance entry
        contractResourceBalances[_tokenAddress] = 0;
    }

    function addParcelType(string memory _name, mapping(uint256 => uint256) memory _baseResourceYield, uint256 _developmentCost) public onlyAdmin {
        uint256 typeId = nextParcelTypeId++;
        parcelTypes[typeId].name = _name;
        parcelTypes[typeId].developmentCost = _developmentCost;
        // Deep copy the mapping
        uint256[] memory resourceTypeIds = new uint256[](nextResourceTypeId);
        for (uint256 i = 1; i < nextResourceTypeId; i++) {
             resourceTypeIds[i] = i; // Assume resourceTypeIds are sequential from 1
        }
        for(uint i=0; i < resourceTypeIds.length; i++){
            if(resourceTypeIds[i] != 0){
                 parcelTypes[typeId].baseResourceYield[resourceTypeIds[i]] = _baseResourceYield[resourceTypeIds[i]];
            }
        }
    }

     function updateParcelResourceYield(uint256 _parcelTypeId, uint256 _resourceTypeId, uint256 _newYield) public onlyAdmin isRegisteredParcelType(_parcelTypeId) isRegisteredResourceToken(resourceTokenAddresses[_resourceTypeId]) {
         parcelTypes[_parcelTypeId].baseResourceYield[_resourceTypeId] = _newYield;
     }


    function addItemType(string memory _name, bool _stackable, uint256 _maxDurability, uint256 _harvestBoost, uint256 _craftingBoost, uint256 _skillBoost, uint256 _boostedSkillTypeId) public onlyAdmin {
        uint256 typeId = nextItemTypeId++;
        itemTypes[typeId] = ItemType(_name, _stackable, _maxDurability, _harvestBoost, _craftingBoost, _skillBoost, _boostedSkillTypeId);
    }

    function addSkillType(string memory _name, uint256 _xpToLevelUp) public onlyAdmin {
        uint256 typeId = nextSkillTypeId++;
        skillTypes[typeId] = SkillType(_name, _xpToLevelUp);
    }

    function addCraftingRecipe(uint256 _outputItemTypeId, uint256 _outputQuantity, mapping(uint256 => uint256) memory _requiredResources, mapping(uint256 => uint256) memory _requiredItems, mapping(uint256 => uint256) memory _requiredSkills, uint256 _requiredNexusEnergy) public onlyAdmin isRegisteredItemType(_outputItemTypeId) {
        uint256 recipeId = nextRecipeId++;
        craftingRecipes[recipeId].outputItemTypeId = _outputItemTypeId;
        craftingRecipes[recipeId].outputQuantity = _outputQuantity;
         craftingRecipes[recipeId].requiredNexusEnergy = _requiredNexusEnergy;

        // Deep copy required resources (assuming resource type ids are sequential from 1)
         uint256[] memory resourceTypeIds = new uint256[](nextResourceTypeId);
        for (uint256 i = 1; i < nextResourceTypeId; i++) {
             resourceTypeIds[i] = i;
        }
        for(uint i=0; i < resourceTypeIds.length; i++){
             if(resourceTypeIds[i] != 0){
                 craftingRecipes[recipeId].requiredResources[resourceTypeIds[i]] = _requiredResources[resourceTypeIds[i]];
            }
        }

        // Deep copy required items (assuming item type ids are sequential from 1)
         uint256[] memory itemTypeIds = new uint256[](nextItemTypeId);
        for (uint256 i = 1; i < nextItemTypeId; i++) {
             itemTypeIds[i] = i;
        }
         for(uint i=0; i < itemTypeIds.length; i++){
             if(itemTypeIds[i] != 0){
                craftingRecipes[recipeId].requiredItems[itemTypeIds[i]] = _requiredItems[itemTypeIds[i]];
             }
        }

        // Deep copy required skills (assuming skill type ids are sequential from 1)
        uint256[] memory skillTypeIds = new uint256[](nextSkillTypeId);
        for (uint256 i = 1; i < nextSkillTypeId; i++) {
             skillTypeIds[i] = i;
        }
         for(uint i=0; i < skillTypeIds.length; i++){
             if(skillTypeIds[i] != 0){
                craftingRecipes[recipeId].requiredSkills[skillTypeIds[i]] = _requiredSkills[skillTypeIds[i]];
             }
        }
    }

    function updateCraftingRecipe(uint256 _recipeId, uint256 _outputItemTypeId, uint256 _outputQuantity, mapping(uint256 => uint256) memory _requiredResources, mapping(uint256 => uint256) memory _requiredItems, mapping(uint256 => uint256) memory _requiredSkills, uint256 _requiredNexusEnergy) public onlyAdmin isRegisteredRecipe(_recipeId) isRegisteredItemType(_outputItemTypeId) {
         craftingRecipes[_recipeId].outputItemTypeId = _outputItemTypeId;
         craftingRecipes[_recipeId].outputQuantity = _outputQuantity;
         craftingRecipes[_recipeId].requiredNexusEnergy = _requiredNexusEnergy;

         // Update required resources (assuming resource type ids are sequential from 1)
         uint256[] memory resourceTypeIds = new uint256[](nextResourceTypeId);
        for (uint256 i = 1; i < nextResourceTypeId; i++) {
             resourceTypeIds[i] = i;
        }
        for(uint i=0; i < resourceTypeIds.length; i++){
             if(resourceTypeIds[i] != 0){
                 craftingRecipes[_recipeId].requiredResources[resourceTypeIds[i]] = _requiredResources[resourceTypeIds[i]];
            }
        }

         // Update required items (assuming item type ids are sequential from 1)
         uint256[] memory itemTypeIds = new uint256[](nextItemTypeId);
        for (uint256 i = 1; i < nextItemTypeId; i++) {
             itemTypeIds[i] = i;
        }
         for(uint i=0; i < itemTypeIds.length; i++){
             if(itemTypeIds[i] != 0){
                craftingRecipes[_recipeId].requiredItems[itemTypeIds[i]] = _requiredItems[itemTypeIds[i]];
             }
        }

         // Update required skills (assuming skill type ids are sequential from 1)
        uint256[] memory skillTypeIds = new uint256[](nextSkillTypeId);
        for (uint256 i = 1; i < nextSkillTypeId; i++) {
             skillTypeIds[i] = i;
        }
         for(uint i=0; i < skillTypeIds.length; i++){
             if(skillTypeIds[i] != 0){
                craftingRecipes[_recipeId].requiredSkills[skillTypeIds[i]] = _requiredSkills[skillTypeIds[i]];
             }
        }
    }


    // --- Internal Helpers ---

    // Adds an item (stackable or unique) to an avatar's inventory
    function _addItemToAvatarInventory(uint256 _avatarId, uint256 _itemTypeId, uint256 _quantity, uint256 _specificItemId) internal avatarExists(_avatarId) isRegisteredItemType(_itemTypeId) {
        require(_quantity > 0, "Quantity must be positive");
        bool stackable = itemTypes[_itemTypeId].stackable;

        if (stackable) {
            avatars[_avatarId].inventory[_itemTypeId] += _quantity;
             // Specific item ID is not relevant for stackable items
            emit ItemTransferred(_specificItemId, 0, _avatarId, 0, 0); // Signal generic item received by avatar
        } else {
             // For unique items, _specificItemId must be provided
            require(_specificItemId > 0 && items[_specificItemId].id == _specificItemId, "Invalid unique item ID");
            require(itemLocationAvatar[_specificItemId] == 0 && itemLocationParcel[_specificItemId] == 0, "Unique item already has a location");
            require(items[_specificItemId].itemTypeId == _itemTypeId, "Unique item type mismatch");

            itemLocationAvatar[_specificItemId] = _avatarId;
            avatars[_avatarId].inventory[_itemTypeId]++; // Increment count of this item type

            emit ItemTransferred(_specificItemId, 0, _avatarId, 0, 0); // Signal unique item received by avatar
        }
    }

     // Removes an item (stackable or unique) from an avatar's inventory
    function _removeItemFromAvatarInventory(uint256 _avatarId, uint256 _itemTypeId, uint256 _quantity, uint256 _specificItemId) internal avatarExists(_avatarId) isRegisteredItemType(_itemTypeId) {
         require(_quantity > 0, "Quantity must be positive");
         bool stackable = itemTypes[_itemTypeId].stackable;

         if (stackable) {
             require(avatars[_avatarId].inventory[_itemTypeId] >= _quantity, "Not enough stackable items");
             avatars[_avatarId].inventory[_itemTypeId] -= _quantity;
             emit ItemTransferred(_specificItemId, _avatarId, 0, 0, 0); // Signal generic item removed from avatar
         } else {
             // For unique items, _specificItemId must be provided
             require(_specificItemId > 0 && items[_specificItemId].id == _specificItemId, "Invalid unique item ID");
             require(itemLocationAvatar[_specificItemId] == _avatarId, "Unique item not in avatar inventory");
             require(items[_specificItemId].itemTypeId == _itemTypeId, "Unique item type mismatch");

             itemLocationAvatar[_specificItemId] = 0; // Remove location
             avatars[_avatarId].inventory[_itemTypeId]--; // Decrement count of this item type
              emit ItemTransferred(_specificItemId, _avatarId, 0, 0, 0); // Signal unique item removed from avatar
         }
    }

     // Adds an item (stackable or unique) to a parcel's inventory
    function _addItemToParcelInventory(uint256 _parcelId, uint256 _itemTypeId, uint256 _quantity, uint256 _specificItemId) internal parcelExists(_parcelId) isRegisteredItemType(_itemTypeId) {
        require(_quantity > 0, "Quantity must be positive");
        bool stackable = itemTypes[_itemTypeId].stackable;

        if (stackable) {
            parcels[_parcelId].inventory[_itemTypeId] += _quantity;
             emit ItemTransferred(_specificItemId, 0, 0, 0, _parcelId); // Signal generic item received by parcel
        } else {
             // For unique items, _specificItemId must be provided
            require(_specificItemId > 0 && items[_specificItemId].id == _specificItemId, "Invalid unique item ID");
             require(itemLocationAvatar[_specificItemId] == 0 && itemLocationParcel[_specificItemId] == 0, "Unique item already has a location");
             require(items[_specificItemId].itemTypeId == _itemTypeId, "Unique item type mismatch");

            itemLocationParcel[_specificItemId] = _parcelId;
            parcels[_parcelId].inventory[_itemTypeId]++; // Increment count of this item type
             emit ItemTransferred(_specificItemId, 0, 0, 0, _parcelId); // Signal unique item received by parcel
        }
    }

    // Removes an item (stackable or unique) from a parcel's inventory
    function _removeItemFromParcelInventory(uint256 _parcelId, uint256 _itemTypeId, uint256 _quantity, uint256 _specificItemId) internal parcelExists(_parcelId) isRegisteredItemType(_itemTypeId) {
        require(_quantity > 0, "Quantity must be positive");
        bool stackable = itemTypes[_itemTypeId].stackable;

        if (stackable) {
            require(parcels[_parcelId].inventory[_itemTypeId] >= _quantity, "Not enough stackable items in parcel");
            parcels[_parcelId].inventory[_itemTypeId] -= _quantity;
             emit ItemTransferred(_specificItemId, 0, 0, _parcelId, 0); // Signal generic item removed from parcel
        } else {
            // For unique items, _specificItemId must be provided
            require(_specificItemId > 0 && items[_specificItemId].id == _specificItemId, "Invalid unique item ID");
            require(itemLocationParcel[_specificItemId] == _parcelId, "Unique item not in parcel inventory");
             require(items[_specificItemId].itemTypeId == _itemTypeId, "Unique item type mismatch");

            itemLocationParcel[_specificItemId] = 0; // Remove location
            parcels[_parcelId].inventory[_itemTypeId]--; // Decrement count of this item type
            emit ItemTransferred(_specificItemId, 0, 0, _parcelId, 0); // Signal unique item removed from parcel
        }
    }


    // Helper to remove an item from a dynamic array (used for owner/occupant tracking)
    function _removeIdFromArray(uint256[] storage arr, uint256 idToRemove) internal returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == idToRemove) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                return true;
            }
        }
        return false; // ID not found
    }

    // Internal function to gain Nexus Energy
    function _gainNexusEnergy(uint256 _avatarId, uint256 _amount) internal avatarExists(_avatarId) {
        require(_amount > 0, "Amount must be positive");
        avatars[_avatarId].nexusEnergy += _amount;
        emit NexusEnergyGained(_avatarId, _amount);
    }

    // Internal function to spend Nexus Energy
     function _spendNexusEnergy(uint256 _avatarId, uint256 _amount) internal avatarExists(_avatarId) {
        require(_amount > 0, "Amount must be positive");
        require(avatars[_avatarId].nexusEnergy >= _amount, "Not enough Nexus Energy");
        avatars[_avatarId].nexusEnergy -= _amount;
        emit NexusEnergySpent(_avatarId, _amount);
    }


    // --- Core Entity Management (Simulated NFTs) ---

    function mintAvatar(address _owner, string memory _name) public onlyAdmin returns (uint256) {
        require(_owner != address(0), "Invalid owner address");
        uint256 newAvatarId = nextAvatarId++;
        avatars[newAvatarId] = Avatar(newAvatarId, _owner, _name, 0, 0, avatars[newAvatarId].skills, avatars[newAvatarId].inventory, "");
        avatarOwner[newAvatarId] = _owner;
        ownerAvatars[_owner].push(newAvatarId);
        avatarLocation[newAvatarId] = 0; // Start unlocated

         // Give avatar level 1 in all default skills (example)
        for(uint256 skillTypeId = 1; skillTypeId < nextSkillTypeId; skillTypeId++){
             avatars[newAvatarId].skills[skillTypeId] = Skill(skillTypeId, 1, 0);
        }


        emit AvatarMinted(newAvatarId, _owner, _name);
        return newAvatarId;
    }

    function transferAvatar(uint256 _avatarId, address _to) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) {
        require(_to != address(0), "Invalid recipient address");
        address currentOwner = avatarOwner[_avatarId];
        require(currentOwner != _to, "Transfer to self");

        // Clear delegation upon transfer
        if(avatarDelegates[_avatarId] != address(0)) {
            address oldDelegate = avatarDelegates[_avatarId];
            avatarDelegates[_avatarId] = address(0);
            emit AvatarDelegationRevoked(_avatarId, oldDelegate);
        }


        // Update ownership mappings
        _removeIdFromArray(ownerAvatars[currentOwner], _avatarId);
        ownerAvatars[_to].push(_avatarId);
        avatarOwner[_avatarId] = _to;
        avatars[_avatarId].owner = _to; // Update owner in the struct


        emit AvatarTransferred(_avatarId, currentOwner, _to);
    }


    function mintParcel(address _owner, uint256 _parcelTypeId, int256 _x, int256 _y) public onlyAdmin isRegisteredParcelType(_parcelTypeId) returns (uint256) {
        require(_owner != address(0), "Invalid owner address");
        uint256 newParcelId = nextParcelId++;
        parcels[newParcelId] = Parcel(newParcelId, _owner, _parcelTypeId, _x, _y, 0, parcels[newParcelId].resourcesAvailable, parcels[newParcelId].inventory, "");
        parcelOwner[newParcelId] = _owner;
        ownerParcels[_owner].push(newParcelId);

        // Initialize starting resources based on parcel type (example)
        for(uint256 resTypeId = 1; resTypeId < nextResourceTypeId; resTypeId++){
             parcels[newParcelId].resourcesAvailable[resTypeId] = parcelTypes[_parcelTypeId].baseResourceYield[resTypeId] * 100; // Example: start with 100x base yield
        }


        emit ParcelMinted(newParcelId, _owner, _parcelTypeId, _x, _y);
        return newParcelId;
    }

    function transferParcel(uint256 _parcelId, address _to) public onlyParcelOwner(_parcelId) parcelExists(_parcelId) {
        require(_to != address(0), "Invalid recipient address");
        address currentOwner = parcelOwner[_parcelId];
        require(currentOwner != _to, "Transfer to self");

        // Important: Handle occupants? Maybe Avatars must leave before transfer?
        // For now, assume occupants can stay, but maybe limit actions.
        // Or, require parcel to be empty: require(parcelOccupants[_parcelId].length == 0, "Parcel must be empty to transfer");

        // Update ownership mappings
        _removeIdFromArray(ownerParcels[currentOwner], _parcelId);
        ownerParcels[_to].push(_parcelId);
        parcelOwner[_parcelId] = _to;
        parcels[_parcelId].owner = _to; // Update owner in the struct

        emit ParcelTransferred(_parcelId, currentOwner, _to);
    }

    function setAvatarMetadataURI(uint256 _avatarId, string memory _uri) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) {
        avatars[_avatarId].metadataURI = _uri;
        emit AvatarMetadataUpdated(_avatarId, _uri);
    }

     function setParcelDescription(uint256 _parcelId, string memory _description) public onlyParcelOwner(_parcelId) parcelExists(_parcelId) {
        parcels[_parcelId].description = _description;
        emit ParcelDescriptionUpdated(_parcelId, _description);
    }


    // --- Core Interaction & Dynamic State ---

    function moveAvatar(uint256 _avatarId, uint256 _toParcelId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) parcelExists(_toParcelId) {
        uint256 fromParcelId = avatarLocation[_avatarId];

        // Remove from old parcel's occupants list if applicable
        if (fromParcelId != 0) {
            _removeIdFromArray(parcelOccupants[fromParcelId], _avatarId);
        }

        // Add to new parcel's occupants list
        parcelOccupants[_toParcelId].push(_avatarId);
        avatarLocation[_avatarId] = _toParcelId;
        avatars[_avatarId].currentParcelId = _toParcelId; // Update struct as well

        emit AvatarMoved(_avatarId, fromParcelId, _toParcelId);
    }

    function harvestResource(uint256 _avatarId, uint256 _resourceTypeId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) isRegisteredResourceToken(resourceTokenAddresses[_resourceTypeId]) {
        uint256 currentParcelId = avatars[_avatarId].currentParcelId;
        require(currentParcelId != 0, "Avatar must be on a parcel to harvest");
        parcelExists(currentParcelId); // Ensure the parcel exists

        uint256 parcelTypeId = parcels[currentParcelId].parcelTypeId;
        isRegisteredParcelType(parcelTypeId); // Ensure parcel type exists

        uint256 baseYield = parcelTypes[parcelTypeId].baseResourceYield[_resourceTypeId];
        require(baseYield > 0, "Resource not available on this parcel type");
        require(parcels[currentParcelId].resourcesAvailable[_resourceTypeId] > 0, "Parcel resource depleted");

        // Calculate harvest amount based on skill, development level, items, etc. (Example)
        uint256 harvestingSkillLevel = avatars[_avatarId].skills[1].level; // Assuming skill type 1 is Harvesting
        if (harvestingSkillLevel == 0) harvestingSkillLevel = 1; // Default level 1 if skill not initialized
        uint256 yield = baseYield * harvestingSkillLevel / 2; // Example scaling

        // Apply item boosts (Example: iterate equipped items - need inventory structure rework for equipped items)
        // For simplicity, let's add a flat boost chance/amount based on Nexus Energy
        uint256 nexusBonus = avatars[_avatarId].nexusEnergy / 100; // 1 extra yield per 100 energy
        yield += nexusBonus;

        yield = min(yield, parcels[currentParcelId].resourcesAvailable[_resourceTypeId]); // Don't harvest more than available

        require(yield > 0, "Calculated yield is zero");

        // Transfer resource to the contract's balance first
        IERC20 resourceToken = IERC20(resourceTokenAddresses[_resourceTypeId]);
        // In a real scenario, the parcel would need to 'own' the resource tokens,
        // or the contract would mint them based on harvest. Since ERC20s are external,
        // this simulates harvesting by adding to the contract's pool which the user can then withdraw.
        // A more realistic model might involve the parcel owner funding the resource pool.
        // For THIS example, we'll just decrement the *simulated* resource count on the parcel.
        parcels[currentParcelId].resourcesAvailable[_resourceTypeId] -= yield;

        // Transfer the harvested resource to the Avatar's *owner's* wallet (assuming external ERC20)
        // This requires the contract to hold the tokens or mint them.
        // Let's adjust: The contract manages the *simulated* resource count on the parcel,
        // and the *harvested* resources are added to the user's *contract* balance,
        // which they can then withdraw. This keeps ERC20 interaction simple (deposit/withdraw from contract).

        contractResourceBalances[resourceTokenAddresses[_resourceTypeId]] += yield; // Add to contract balance for later withdrawal

        // Gain XP for harvesting skill (Example)
        _gainSkillExperience(_avatarId, 1, yield); // Gain 1 XP per resource harvested (example)

        // Gain Nexus Energy (Example)
        _gainNexusEnergy(_avatarId, yield / 10); // Gain 1 Nexus Energy per 10 resource harvested

        emit ResourceHarvested(_avatarId, currentParcelId, _resourceTypeId, yield);
    }

    function useItem(uint256 _avatarId, uint256 _itemId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) itemExists(_itemId) {
        Item storage item = items[_itemId];
        isRegisteredItemType(item.itemTypeId); // Ensure item type exists
        ItemType storage itemType = itemTypes[item.itemTypeId];

        // Check item location - must be in avatar's inventory
        require(itemLocationAvatar[_itemId] == _avatarId, "Item not in avatar inventory");

        require(itemType.maxDurability > 0, "Item is not usable or is a unique collectible type"); // Can only use items with durability or that are consumable (durability 0 for consumable logic)

        if (itemType.maxDurability > 0) { // Usable item with durability
            require(item.durability > 0, "Item has 0 durability");
            item.durability--;

            // Apply effects based on itemType (This is where complex effects would go)
            // Example: if it's a harvest boost item, maybe apply boost for N harvests or M minutes (requires time tracking/state)
            // For this example, just decrease durability. Effect logic is outside scope or simplified.

            emit ItemUsed(_avatarId, _itemId, item.itemTypeId, item.durability);

            if (item.durability == 0) {
                // Handle item breaking/burning
                _removeItemFromAvatarInventory(_avatarId, item.itemTypeId, 1, _itemId); // Remove unique item instance
                 // Optionally delete item struct or mark as burned
            }

        } else { // Consumable item (maxDurability == 0)
             // Apply effects (Example: heal Avatar energy, boost skill XP gain)
             // For this example, just remove the item
             _removeItemFromAvatarInventory(_avatarId, item.itemTypeId, 1, _itemId); // Remove unique item instance

             emit ItemUsed(_avatarId, _itemId, item.itemTypeId, 0); // Durability 0 for consumables

             // Optionally delete item struct or mark as consumed
        }
    }

    // Internal helper to gain skill experience
     function _gainSkillExperience(uint256 _avatarId, uint256 _skillTypeId, uint256 _amount) internal avatarExists(_avatarId) isRegisteredSkillType(_skillTypeId) {
         require(_amount > 0, "XP amount must be positive");
         avatars[_avatarId].skills[_skillTypeId].experience += _amount;
         emit SkillGainedXP(_avatarId, _skillTypeId, avatars[_avatarId].skills[_skillTypeId].experience);
     }


    function levelUpSkill(uint256 _avatarId, uint256 _skillTypeId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) isRegisteredSkillType(_skillTypeId) {
        Skill storage skill = avatars[_avatarId].skills[_skillTypeId];
        SkillType storage skillType = skillTypes[_skillTypeId];

        // Simple leveling system: xp needed increases linearly
        uint256 xpNeeded = skillType.xpToLevelUp * (skill.level); // Level 1->2 needs base*1, 2->3 needs base*2, etc.

        require(skill.experience >= xpNeeded, "Not enough experience to level up");

        skill.experience -= xpNeeded;
        skill.level++;

        emit SkillLeveledUp(_avatarId, _skillTypeId, skill.level);
    }


     function craftItem(uint256 _avatarId, uint256 _recipeId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) isRegisteredRecipe(_recipeId) {
        Avatar storage avatar = avatars[_avatarId];
        CraftingRecipe storage recipe = craftingRecipes[_recipeId];
        isRegisteredItemType(recipe.outputItemTypeId); // Ensure output item type exists

        // 1. Check required skills
        for (uint256 skillTypeId = 1; skillTypeId < nextSkillTypeId; skillTypeId++) { // Iterate through all potential required skills
            uint256 requiredLevel = recipe.requiredSkills[skillTypeId];
            if (requiredLevel > 0) {
                require(avatar.skills[skillTypeId].level >= requiredLevel, "Insufficient skill level");
            }
        }

        // 2. Check required Nexus Energy
        require(avatar.nexusEnergy >= recipe.requiredNexusEnergy, "Not enough Nexus Energy for crafting");

        // 3. Check required Resources (need to read from contract balance)
         for (uint256 resTypeId = 1; resTypeId < nextResourceTypeId; resTypeId++) { // Iterate through all potential required resources
            uint256 requiredAmount = recipe.requiredResources[resTypeId];
             if (requiredAmount > 0) {
                address resourceTokenAddress = resourceTokenAddresses[resTypeId];
                require(contractResourceBalances[resourceTokenAddress] >= requiredAmount, "Not enough resources in contract");
             }
         }

        // 4. Check required Items (need to read from avatar inventory)
        for (uint256 itemTypeId = 1; itemTypeId < nextItemTypeId; itemTypeId++) { // Iterate through all potential required items
            uint256 requiredQuantity = recipe.requiredItems[itemTypeId];
            if (requiredQuantity > 0) {
                 require(avatar.inventory[itemTypeId] >= requiredQuantity, "Not enough items in inventory");
            }
        }

        // --- If all checks pass, perform the craft ---

        // 5. Consume Nexus Energy
        _spendNexusEnergy(_avatarId, recipe.requiredNexusEnergy);

        // 6. Consume Resources (from contract balance)
         for (uint256 resTypeId = 1; resTypeId < nextResourceTypeId; resTypeId++) {
            uint256 requiredAmount = recipe.requiredResources[resTypeId];
             if (requiredAmount > 0) {
                address resourceTokenAddress = resourceTokenAddresses[resTypeId];
                contractResourceBalances[resourceTokenAddress] -= requiredAmount;
             }
         }

        // 7. Consume Items (from avatar inventory)
        for (uint256 itemTypeId = 1; itemTypeId < nextItemTypeId; itemTypeId++) {
            uint256 requiredQuantity = recipe.requiredItems[itemTypeId];
             if (requiredQuantity > 0) {
                 // For simplicity, assume consumed items are unique and removed.
                 // A more complex system would handle stackable consumption differently.
                 // This requires finding specific item IDs if they are unique items.
                 // For now, let's assume requiredItems only lists *stackable* items for simplicity in this example.
                 // Or, if unique, the recipe specifies ITEM IDs, not ITEM TYPE IDs (more complex data structure).
                 // Let's stick to requiredItems[itemTypeId] means CONSUME N stackable items of that type.
                 // Or, if the item type is NOT stackable, this means CONSUME N *unique instances* of that type. This needs finding specific IDs.
                 // Let's simplify: Assume requiredItems mapping is for stackable items ONLY.
                 require(itemTypes[itemTypeId].stackable, "Cannot consume unique items this way in recipe"); // Added constraint for simplicity
                 _removeItemFromAvatarInventory(_avatarId, itemTypeId, requiredQuantity, 0); // 0 indicates stackable, no specific ID needed
            }
        }


        // 8. Mint Output Item(s)
        uint256 outputItemTypeId = recipe.outputItemTypeId;
        uint256 outputQuantity = recipe.outputQuantity;
        bool outputIsStackable = itemTypes[outputItemTypeId].stackable;
        uint256 firstMintedItemId = 0; // To return the first ID for unique items

        if (outputIsStackable) {
             _addItemToAvatarInventory(_avatarId, outputItemTypeId, outputQuantity, 0);
        } else {
            require(outputQuantity == 1, "Unique items must be minted one at a time");
            uint256 newItemId = nextItemId++;
            items[newItemId] = Item(newItemId, outputItemTypeId, itemTypes[outputItemTypeId].maxDurability); // Initialize with max durability
            _addItemToAvatarInventory(_avatarId, outputItemTypeId, 1, newItemId); // Add the unique item ID
            firstMintedItemId = newItemId;
        }


        // 9. Gain Crafting Skill XP (Example: gain XP based on recipe difficulty/cost)
        uint256 xpGain = recipe.requiredNexusEnergy / 10; // Example XP gain
        _gainSkillExperience(_avatarId, 2, xpGain); // Assuming skill type 2 is Crafting

        emit ItemCrafted(_avatarId, _recipeId, outputItemTypeId, outputQuantity, firstMintedItemId);
     }


    function developParcel(uint256 _avatarId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) {
        uint256 currentParcelId = avatars[_avatarId].currentParcelId;
        require(currentParcelId != 0, "Avatar must be on a parcel to develop it");
        parcelExists(currentParcelId); // Ensure parcel exists

        Parcel storage parcel = parcels[currentParcelId];
        require(parcel.owner == avatarOwner[_avatarId], "Avatar owner must own the parcel to develop it");

        uint256 parcelTypeId = parcel.parcelTypeId;
        isRegisteredParcelType(parcelTypeId); // Ensure parcel type exists
        ParcelType storage pType = parcelTypes[parcelTypeId];

        uint256 developmentCost = pType.developmentCost * (parcel.developmentLevel + 1); // Cost increases with level

        require(avatars[_avatarId].nexusEnergy >= developmentCost, "Not enough Nexus Energy to develop parcel");

        // Consume Nexus Energy
        _spendNexusEnergy(_avatarId, developmentCost);

        // Apply Development effects (Example: increase resource yield, unlock building slots)
        parcel.developmentLevel++;
         // For simplicity, let's permanently increase base resource yield by 10% of original base per level
         for (uint256 resTypeId = 1; resTypeId < nextResourceTypeId; resTypeId++) {
             if (pType.baseResourceYield[resTypeId] > 0) {
                uint256 yieldIncrease = pType.baseResourceYield[resTypeId] / 10;
                 parcels[currentParcelId].resourcesAvailable[resTypeId] += yieldIncrease; // Add more resources to the parcel pool
             }
         }


        // Gain Development Skill XP (Example: gain XP based on cost)
         uint256 xpGain = developmentCost / 10; // Example XP gain
         _gainSkillExperience(_avatarId, 3, xpGain); // Assuming skill type 3 is Development

        emit ParcelDeveloped(currentParcelId, parcel.developmentLevel);
    }

    function spendNexusEnergy(uint256 _avatarId, uint256 _amount) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) {
        _spendNexusEnergy(_avatarId, _amount);
        // Add logic here for what spending Nexus Energy *does*.
        // E.g., boost harvest rate for a limited time, get a temporary buff, etc.
        // This function itself just spends, the *effect* happens in functions that require spending energy.
    }


    // --- Inventory/Resource Management ---

     function depositResourceToContract(uint256 _resourceTypeId, uint256 _amount) public isRegisteredResourceToken(resourceTokenAddresses[_resourceTypeId]) {
        require(_amount > 0, "Amount must be positive");
        address resourceTokenAddress = resourceTokenAddresses[_resourceTypeId];
        IERC20 resourceToken = IERC20(resourceTokenAddress);

        // User must approve this contract to spend their tokens first
        resourceToken.safeTransferFrom(msg.sender, address(this), _amount);

        contractResourceBalances[resourceTokenAddress] += _amount;

        emit ResourceDeposited(msg.sender, _resourceTypeId, _amount);
    }

    function withdrawResourceFromContract(uint256 _resourceTypeId, uint256 _amount) public isRegisteredResourceToken(resourceTokenAddresses[_resourceTypeId]) {
        require(_amount > 0, "Amount must be positive");
        address resourceTokenAddress = resourceTokenAddresses[_resourceTypeId];
        require(contractResourceBalances[resourceTokenAddress] >= _amount, "Contract does not have enough resources");

        IERC20 resourceToken = IERC20(resourceTokenAddress);

        contractResourceBalances[resourceTokenAddress] -= _amount;
        resourceToken.safeTransfer(msg.sender, _amount);

        emit ResourceWithdrawal(msg.sender, _resourceTypeId, _amount);
    }

     function depositItemToParcel(uint256 _avatarId, uint256 _parcelId, uint256 _itemId, uint256 _quantity) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) parcelExists(_parcelId) itemExists(_itemId) {
        require(_avatarId != 0, "Invalid avatar ID"); // Ensure source is an avatar
        require(_parcelId != 0, "Invalid parcel ID"); // Ensure destination is a parcel
        require(avatars[_avatarId].currentParcelId == _parcelId, "Avatar must be on the parcel to deposit"); // Must be physically present
        // Consider requiring parcel ownership? Maybe anyone can deposit to a public chest on a parcel?
        // For this example, let's assume the Avatar owner must also own the Parcel OR the Parcel is public storage.
        // Let's require Avatar owner also owns the Parcel for simplicity.
        require(parcelOwner[_parcelId] == avatarOwner[_avatarId], "Avatar owner must own the parcel to deposit items");


        Item storage item = items[_itemId];
        isRegisteredItemType(item.itemTypeId); // Ensure item type exists
        ItemType storage itemType = itemTypes[item.itemTypeId];

        require(itemLocationAvatar[_itemId] == _avatarId, "Item not in avatar inventory");

        if (itemType.stackable) {
             // For stackable items, _itemId doesn't represent a unique instance, it's the item TYPE ID.
             // Need to adjust: this function should take itemTypeId and quantity.
             // Redefining function signature for stackable items.
             // This function will now ONLY work for UNIQUE items. Need separate for stackable.
             // OR, make _itemId the itemTypeId if stackable, and _quantity is the amount.
             // Let's make _itemId the item ID for UNIQUE items, and require quantity=1.
             // And create a separate function for stackable items.

             require(!itemType.stackable, "Use depositStackableItemToParcel for stackable items");
             require(_quantity == 1, "Quantity must be 1 for unique items");

             _removeItemFromAvatarInventory(_avatarId, item.itemTypeId, 1, _itemId); // Remove from avatar
             _addItemToParcelInventory(_parcelId, item.itemTypeId, 1, _itemId); // Add to parcel

             emit ItemDepositedToParcel(_avatarId, _parcelId, _itemId, item.itemTypeId, 1);

        } else {
            // Should be caught by require(!itemType.stackable) above, but good defensive check
             revert("Use depositStackableItemToParcel for stackable items");
        }
     }

      // Separate function for stackable items deposit
     function depositStackableItemToParcel(uint256 _avatarId, uint256 _parcelId, uint256 _itemTypeId, uint256 _quantity) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) parcelExists(_parcelId) isRegisteredItemType(_itemTypeId) {
         require(_avatarId != 0, "Invalid avatar ID");
         require(_parcelId != 0, "Invalid parcel ID");
         require(_quantity > 0, "Quantity must be positive");
         require(avatars[_avatarId].currentParcelId == _parcelId, "Avatar must be on the parcel to deposit");
         require(parcelOwner[_parcelId] == avatarOwner[_avatarId], "Avatar owner must own the parcel to deposit items");

         ItemType storage itemType = itemTypes[_itemTypeId];
         require(itemType.stackable, "Use depositItemToParcel for unique items");

         require(avatars[_avatarId].inventory[_itemTypeId] >= _quantity, "Not enough stackable items in avatar inventory");

         avatars[_avatarId].inventory[_itemTypeId] -= _quantity; // Remove from avatar
         parcels[_parcelId].inventory[_itemTypeId] += _quantity; // Add to parcel

         emit ItemDepositedToParcel(_avatarId, _parcelId, 0, _itemTypeId, _quantity); // ItemId 0 for stackable
     }


     function withdrawItemFromParcel(uint256 _avatarId, uint256 _parcelId, uint256 _itemId, uint256 _quantity) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) parcelExists(_parcelId) itemExists(_itemId) {
        require(_avatarId != 0, "Invalid avatar ID");
        require(_parcelId != 0, "Invalid parcel ID");
        require(_quantity > 0, "Quantity must be positive");
        require(avatars[_avatarId].currentParcelId == _parcelId, "Avatar must be on the parcel to withdraw"); // Must be physically present
        require(parcelOwner[_parcelId] == avatarOwner[_avatarId], "Avatar owner must own the parcel to withdraw items");

        Item storage item = items[_itemId];
        isRegisteredItemType(item.itemTypeId); // Ensure item type exists
        ItemType storage itemType = itemTypes[item.itemTypeId];

        require(itemLocationParcel[_itemId] == _parcelId, "Item not in parcel inventory");

        if (itemType.stackable) {
            // Redefining function signature for stackable items.
            // This function will now ONLY work for UNIQUE items. Need separate for stackable.
             require(!itemType.stackable, "Use withdrawStackableItemFromParcel for stackable items");
             require(_quantity == 1, "Quantity must be 1 for unique items");

             _removeItemFromParcelInventory(_parcelId, item.itemTypeId, 1, _itemId); // Remove from parcel
             _addItemToAvatarInventory(_avatarId, item.itemTypeId, 1, _itemId); // Add to avatar

             emit ItemWithdrawalFromParcel(_avatarId, _parcelId, _itemId, item.itemTypeId, 1);
        } else {
             revert("Use withdrawStackableItemFromParcel for stackable items");
        }
     }

      // Separate function for stackable items withdrawal
      function withdrawStackableItemFromParcel(uint256 _avatarId, uint256 _parcelId, uint256 _itemTypeId, uint256 _quantity) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) parcelExists(_parcelId) isRegisteredItemType(_itemTypeId) {
        require(_avatarId != 0, "Invalid avatar ID");
        require(_parcelId != 0, "Invalid parcel ID");
        require(_quantity > 0, "Quantity must be positive");
        require(avatars[_avatarId].currentParcelId == _parcelId, "Avatar must be on the parcel to withdraw");
        require(parcelOwner[_parcelId] == avatarOwner[_avatarId], "Avatar owner must own the parcel to withdraw items");

        ItemType storage itemType = itemTypes[_itemTypeId];
        require(itemType.stackable, "Use withdrawItemFromParcel for unique items");

        require(parcels[_parcelId].inventory[_itemTypeId] >= _quantity, "Not enough stackable items in parcel inventory");

        parcels[_parcelId].inventory[_itemTypeId] -= _quantity; // Remove from parcel
        avatars[_avatarId].inventory[_itemTypeId] += _quantity; // Add to avatar

        emit ItemWithdrawalFromParcel(_avatarId, _parcelId, 0, _itemTypeId, _quantity); // ItemId 0 for stackable
     }


    // --- Delegation ---

    function delegateAvatarAction(uint256 _avatarId, address _delegate) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) {
        require(_delegate != msg.sender, "Cannot delegate to yourself");
        avatarDelegates[_avatarId] = _delegate;
        emit AvatarDelegationSet(_avatarId, _delegate);
    }

     function revokeAvatarDelegate(uint256 _avatarId) public onlyAvatarOwner(_avatarId) avatarExists(_avatarId) {
        address oldDelegate = avatarDelegates[_avatarId];
        require(oldDelegate != address(0), "No delegate currently set");
        avatarDelegates[_avatarId] = address(0);
        emit AvatarDelegationRevoked(_avatarId, oldDelegate);
     }

    // --- Getters (Exceeding 20 function count) ---

    function getAvatarDetails(uint256 _avatarId) public view avatarExists(_avatarId) returns (uint256 id, address owner, string memory name, uint256 currentParcelId, uint256 nexusEnergy, string memory metadataURI) {
        Avatar storage avatar = avatars[_avatarId];
        return (avatar.id, avatar.owner, avatar.name, avatar.currentParcelId, avatar.nexusEnergy, avatar.metadataURI);
    }

    function getParcelDetails(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256 id, address owner, uint256 parcelTypeId, int256 x, int256 y, uint256 developmentLevel, string memory description) {
        Parcel storage parcel = parcels[_parcelId];
        return (parcel.id, parcel.owner, parcel.parcelTypeId, parcel.x, parcel.y, parcel.developmentLevel, parcel.description);
    }

    function getAvatarInventory(uint256 _avatarId) public view avatarExists(_avatarId) returns (uint256[] memory itemTypeIds, uint256[] memory quantities) {
        // Note: This will return type IDs and counts. For unique items, the count is the number of unique instances of that type.
        // To get *specific* unique item IDs, a different query pattern is needed (e.g., iterating through all items and checking location).
        // For simplicity here, we return the summary view from the Avatar struct's inventory mapping.
        uint256[] memory keys = new uint256[](nextItemTypeId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextItemTypeId; i++) {
            if (avatars[_avatarId].inventory[i] > 0) {
                keys[count] = i;
                count++;
            }
        }

        uint256[] memory resultItemTypeIds = new uint256[](count);
        uint256[] memory resultQuantities = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultItemTypeIds[i] = keys[i];
            resultQuantities[i] = avatars[_avatarId].inventory[keys[i]];
        }
        return (resultItemTypeIds, resultQuantities);
    }

    function getParcelInventory(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256[] memory itemTypeIds, uint256[] memory quantities) {
         // Similar to getAvatarInventory, returns type IDs and counts.
        uint256[] memory keys = new uint256[](nextItemTypeId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextItemTypeId; i++) {
            if (parcels[_parcelId].inventory[i] > 0) {
                keys[count] = i;
                count++;
            }
        }

        uint256[] memory resultItemTypeIds = new uint256[](count);
        uint256[] memory resultQuantities = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultItemTypeIds[i] = keys[i];
            resultQuantities[i] = parcels[_parcelId].inventory[keys[i]];
        }
        return (resultItemTypeIds, resultQuantities);
    }


    function getAvatarSkills(uint256 _avatarId) public view avatarExists(_avatarId) returns (uint256[] memory skillTypeIds, uint256[] memory levels, uint256[] memory experiences) {
        uint256[] memory sTypeIds = new uint256[](nextSkillTypeId - 1);
        uint256 count = 0;
         for (uint256 i = 1; i < nextSkillTypeId; i++) {
             // Include all registered skill types, even if level/xp is 0
             // if (avatars[_avatarId].skills[i].skillTypeId != 0 || avatars[_avatarId].skills[i].level > 0) { // Check if skill struct was initialized (optional)
                 sTypeIds[count] = i;
                 count++;
             // }
         }

        uint256[] memory resultSkillTypeIds = new uint256[](count);
        uint256[] memory resultLevels = new uint256[](count);
        uint256[] memory resultExperiences = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 currentSkillTypeId = sTypeIds[i];
            resultSkillTypeIds[i] = currentSkillTypeId;
            resultLevels[i] = avatars[_avatarId].skills[currentSkillTypeId].level;
            resultExperiences[i] = avatars[_avatarId].skills[currentSkillTypeId].experience;
        }

        return (resultSkillTypeIds, resultLevels, resultExperiences);
    }

     function getParcelOccupants(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256[] memory) {
         return parcelOccupants[_parcelId];
     }

     function getResourceTokenAddress(uint256 _resourceTypeId) public view isRegisteredResourceToken(resourceTokenAddresses[_resourceTypeId]) returns (address) {
         return resourceTokenAddresses[_resourceTypeId];
     }

     function getContractResourceBalance(uint256 _resourceTypeId) public view isRegisteredResourceToken(resourceTokenAddresses[_resourceTypeId]) returns (uint256) {
         return contractResourceBalances[resourceTokenAddresses[_resourceTypeId]];
     }

     function getAvatarOwner(uint256 _avatarId) public view avatarExists(_avatarId) returns (address) {
         return avatarOwner[_avatarId];
     }

     function getParcelOwner(uint256 _parcelId) public view parcelExists(_parcelId) returns (address) {
         return parcelOwner[_parcelId];
     }

    function getItemDetails(uint256 _itemId) public view itemExists(_itemId) returns (uint256 id, uint256 itemTypeId, uint256 durability, uint256 ownerAvatarId, uint256 ownerParcelId) {
        Item storage item = items[_itemId];
        return (item.id, item.itemTypeId, item.durability, itemLocationAvatar[_itemId], itemLocationParcel[_itemId]);
    }

    function getOwnerAvatars(address _owner) public view returns (uint256[] memory) {
        return ownerAvatars[_owner];
    }

     function getOwnerParcels(address _owner) public view returns (uint256[] memory) {
        return ownerParcels[_owner];
    }


    // Helper for min (Solidity 0.8.0+)
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Fallback function to prevent accidental ether sends
    receive() external payable {
        revert("Ether transfers not supported");
    }

    fallback() external payable {
        revert("Invalid function call");
    }
}
```