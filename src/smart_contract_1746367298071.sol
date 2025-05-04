Okay, here is a Solidity smart contract concept I've designed, focusing on a dynamic, player-centric system involving crafting, progression, and resource management. It's called "CryptoCraft Nexus."

It combines elements of:
1.  **ERC-1155** for multi-token management (Resources, Crafted Items, Mystery Boxes).
2.  **Player Progression:** Leveling, XP, and Skill Points.
3.  **Dynamic Crafting:** Recipes with skill requirements, success chance, cooldowns, and partial failure returns.
4.  **Resource Generation:** Time-based "mining" simulation with global caps and player cooldowns.
5.  **Staking:** Locking resources for XP rewards and potential random bonuses.
6.  **Mystery Boxes:** Random item/resource distribution based on probabilities.
7.  **Owner Control:** Managing recipes, token types, skill effects, caps, etc.

This is *not* a simple standard token or basic dApp structure. It builds an interactive system state on-chain.

**Disclaimer:** This is a complex example for demonstration. Production systems would require extensive audits, gas optimization, potentially layer 2 considerations, and more robust randomness (like Chainlink VRF). The block-hash based randomness used here is *not* secure for high-value applications.

---

## CryptoCraft Nexus Smart Contract

**Outline:**

1.  **License & Pragma**
2.  **Imports:** ERC1155, Ownable, ReentrancyGuard, Math (SafeMath is included in recent Solidity, but good to be explicit for older versions or complex math, though basic ops are fine here), Address (for `isContract`).
3.  **Enums:** `TokenType`, `SkillType`.
4.  **Structs:** `TokenDetails`, `Recipe`, `PlayerData`, `StakingData`, `MysteryBoxDrop`.
5.  **Events:** `TokenRegistered`, `RecipeAdded`, `RecipeUpdated`, `RecipeRemoved`, `ItemCrafted`, `CraftingFailed`, `ResourceMined`, `ResourcesStaked`, `StakingRewardsClaimed`, `ResourcesUnstaked`, `PlayerLeveledUp`, `SkillPointsAllocated`, `MysteryBoxOpened`, `SkillEffectivenessSet`, `CraftingCooldownSet`, `MiningCooldownSet`, `ResourceCapSet`, `MysteryBoxDropAdded`, `MysteryBoxDropRemoved`, `MysteryBoxDropUpdated`.
6.  **State Variables:**
    *   Owner
    *   ERC1155 balances (`_balances`)
    *   Token Metadata/Details (`_tokenDetails`)
    *   Recipes (`_recipes`)
    *   Player Data (`_playerData`)
    *   Staking Data (`_stakingData`)
    *   Skill Effect Multipliers (`_skillEffectiveness`)
    *   Crafting Cooldowns per Recipe (`_craftingCooldowns`)
    *   Mining Cooldowns per Resource (`_miningCooldowns`)
    *   Player Last Craft Time (`_lastCraftTime`)
    *   Player Last Mine Time (`_lastMineTime`)
    *   Global Resource Caps (`_resourceGlobalCaps`)
    *   Total Resources Minted (`_totalResourceMinted`)
    *   XP needed per level (`_xpNeededForLevel`)
    *   Mystery Box Drop Tables (`_mysteryBoxDrops`)
7.  **Constructor:** Sets owner, initializes base XP requirements.
8.  **Modifiers:** `nonReentrant`.
9.  **ERC-1155 Standard Functions:** (Inherited and potentially overridden if custom hooks are needed, but generally used as provided by OpenZeppelin).
10. **Owner Functions:**
    *   `registerToken`: Define a new resource, item, or box type.
    *   `addRecipe`: Add a new crafting recipe.
    *   `updateRecipe`: Modify an existing recipe.
    *   `removeRecipe`: Disable a recipe.
    *   `setSkillEffectiveness`: Configure skill multiplier values.
    *   `setCraftingCooldown`: Set cooldown for a specific recipe.
    *   `setMiningCooldown`: Set cooldown for a specific resource.
    *   `setGlobalResourceCap`: Set max total mintable amount for a resource.
    *   `mintInitialResources`: Owner can mint initial resource supply.
    *   `addMysteryBoxDrop`: Add an item/resource drop to a mystery box type.
    *   `removeMysteryBoxDrop`: Remove a specific drop from a box type.
    *   `updateMysteryBoxDrop`: Modify an existing drop configuration.
11. **Player Interaction Functions:**
    *   `craftItem`: Attempt to craft an item based on a recipe. Handles inputs, outputs, skill checks, success chance, failure returns, cooldowns, XP distribution.
    *   `mineResource`: Attempt to mine resources. Handles cooldowns, caps, minting, XP distribution.
    *   `stakeResources`: Lock resources in the contract.
    *   `unstakeResources`: Withdraw staked resources.
    *   `claimStakingRewards`: Claim accumulated staking rewards (XP and potential random drops).
    *   `allocateSkillPoints`: Spend earned skill points to improve a skill.
    *   `openMysteryBox`: Consume a mystery box item and receive random items/resources based on the drop table.
12. **Internal Helper Functions:**
    *   `_tryCraft`: Internal logic for crafting success/failure and outcomes.
    *   `_distributeXP`: Add XP to a player and handle level ups/skill points.
    *   `_checkCooldown`: Internal check for time-based cooldowns.
    *   `_updateMiningSupply`: Increment total minted resource count.
    *   `_getRandomNumber`: *Insecure* randomness helper (for demonstration).
    *   `_selectMysteryBoxDrop`: Internal logic to pick a random drop based on weights.
13. **View Functions:**
    *   `getPlayerLevel`: Get player's current level.
    *   `getPlayerXP`: Get player's current XP.
    *   `getPlayerSkillPoints`: Get player's available skill points.
    *   `getPlayerSkillLevel`: Get player's level for a specific skill type.
    *   `getRecipeDetails`: Get details of a specific recipe.
    *   `getStakingData`: Get player's staking data for a resource.
    *   `getCraftingCooldown`: Get the cooldown duration for a recipe.
    *   `getPlayerLastCraftTime`: Get player's last craft time for a recipe.
    *   `getMiningCooldown`: Get the cooldown duration for a resource.
    *   `getPlayerLastMineTime`: Get player's last mine time for a resource.
    *   `getTokenDetails`: Get details of a specific token.
    *   `getResourceGlobalCap`: Get the global minting cap for a resource.
    *   `getTotalResourceMinted`: Get the total amount minted for a resource.
    *   `getXPNeededForLevel`: Get the XP required for a specific level.
    *   `getMysteryBoxDropTable`: Get the drop configuration for a mystery box.
    *   `supportsInterface`: Standard ERC-165.

**Function Summary:**

*   `constructor()`: Initializes the contract, sets owner, defines base XP requirements.
*   `registerToken(uint256 _tokenId, TokenType _tokenType, string memory _uri)`: Owner registers a new ERC-1155 token type (Resource, Crafted Item, Mystery Box) with metadata URI.
*   `addRecipe(uint256 _recipeId, Recipe memory _recipe)`: Owner adds a new crafting recipe definition.
*   `updateRecipe(uint256 _recipeId, Recipe memory _recipe)`: Owner modifies an existing crafting recipe.
*   `removeRecipe(uint256 _recipeId)`: Owner disables a crafting recipe.
*   `setSkillEffectiveness(SkillType _skillType, uint256 _multiplier)`: Owner sets the multiplier for how much a skill type affects related mechanics (e.g., crafting success chance boost per skill point).
*   `setCraftingCooldown(uint256 _recipeId, uint256 _cooldownSeconds)`: Owner sets the time cooldown required between crafting attempts for a specific recipe for a player.
*   `setMiningCooldown(uint256 _resourceId, uint256 _cooldownSeconds)`: Owner sets the time cooldown required between mining attempts for a specific resource for a player.
*   `setGlobalResourceCap(uint256 _resourceId, uint256 _cap)`: Owner sets the maximum total amount of a resource that can ever be minted via the `mineResource` function.
*   `mintInitialResources(uint256 _resourceId, uint256 _amount, address _to)`: Owner can mint initial resources to a specific address (e.g., for initial distribution or treasury).
*   `addMysteryBoxDrop(uint256 _boxItemId, uint256 _dropItemId, uint256 _minAmount, uint256 _maxAmount, uint256 _weight)`: Owner adds a possible item/resource drop with min/max amounts and relative weight to a mystery box type.
*   `removeMysteryBoxDrop(uint256 _boxItemId, uint256 _dropItemId, uint256 _weightIndex)`: Owner removes a specific drop configuration from a mystery box type by index.
*   `updateMysteryBoxDrop(uint256 _boxItemId, uint256 _weightIndex, uint256 _dropItemId, uint256 _minAmount, uint256 _maxAmount, uint256 _weight)`: Owner updates an existing drop configuration for a mystery box type.
*   `craftItem(uint256 _recipeId, uint256 _amount)`: Attempts to craft one or more items using a specified recipe. Checks inputs, skills, cooldowns, calculates success chance, burns inputs, mints outputs on success or returns partial inputs on failure, distributes XP.
*   `mineResource(uint256 _resourceId, uint256 _amount)`: Attempts to "mine" or generate a specific amount of a resource. Checks cooldowns and global caps, mints the resource if successful, distributes XP.
*   `stakeResources(uint256 _resourceId, uint256 _amount)`: Transfers a specified amount of a resource from the player to the contract for staking. Records staking start time.
*   `unstakeResources(uint256 _resourceId, uint256 _amount)`: Transfers a specified amount of a staked resource back to the player. Clears staking data for that portion.
*   `claimStakingRewards()`: Calculates and distributes rewards (currently XP and potential random drops) based on staked resources and time elapsed since last claim/stake. Resets staking timer for reward calculation.
*   `allocateSkillPoints(SkillType _skillType, uint256 _points)`: Allows a player to spend earned skill points to increase a specific skill level.
*   `openMysteryBox(uint256 _boxItemId, uint256 _amount)`: Burns a specified amount of mystery box items from the player and mints random items/resources based on the box's drop table configurations and random chance.
*   `getPlayerLevel(address _player)`: View function to get a player's current progression level.
*   `getPlayerXP(address _player)`: View function to get a player's current experience points.
*   `getPlayerSkillPoints(address _player)`: View function to get a player's currently available skill points.
*   `getPlayerSkillLevel(address _player, SkillType _skillType)`: View function to get a player's level in a specific skill type.
*   `getRecipeDetails(uint256 _recipeId)`: View function to get the full details of a registered crafting recipe.
*   `getStakingData(address _player, uint256 _resourceId)`: View function to get a player's current staked amount and staking start time for a specific resource.
*   `getCraftingCooldown(uint256 _recipeId)`: View function to get the base cooldown duration for a crafting recipe.
*   `getPlayerLastCraftTime(address _player, uint256 _recipeId)`: View function to get the timestamp of a player's last successful craft for a specific recipe.
*   `getMiningCooldown(uint256 _resourceId)`: View function to get the base cooldown duration for mining a resource.
*   `getPlayerLastMineTime(address _player, uint256 _resourceId)`: View function to get the timestamp of a player's last successful mine for a specific resource.
*   `getTokenDetails(uint256 _tokenId)`: View function to get the type and URI prefix of a registered token.
*   `getResourceGlobalCap(uint256 _resourceId)`: View function to get the maximum total mintable amount for a resource.
*   `getTotalResourceMinted(uint256 _resourceId)`: View function to get the current total amount minted for a resource via mining.
*   `getXPNeededForLevel(uint256 _level)`: View function to get the total XP required to reach a specific level.
*   `getMysteryBoxDropTable(uint256 _boxItemId)`: View function to get the full list of possible drops configured for a mystery box type.
*   `uri(uint256 _tokenId)`: ERC-1155 standard function to get the metadata URI for a token ID. (Inherited/Overridden)
*   `balanceOf(address _account, uint256 _id)`: ERC-1155 standard function.
*   `balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids)`: ERC-1155 standard function.
*   `setApprovalForAll(address _operator, bool _approved)`: ERC-1155 standard function.
*   `isApprovedForAll(address _account, address _operator)`: ERC-1155 standard function.
*   `safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data)`: ERC-1155 standard function.
*   `safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)`: ERC-1155 standard function.
*   `supportsInterface(bytes4 interfaceId)`: ERC-165 standard function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- CryptoCraft Nexus Smart Contract ---
// A complex, player-centric system combining ERC1155 assets with crafting,
// progression (XP, Levels, Skills), resource mining, staking, and random drops.

// Outline:
// 1. License & Pragma
// 2. Imports (ERC1155, Ownable, ReentrancyGuard, Math, Address)
// 3. Enums (TokenType, SkillType)
// 4. Structs (TokenDetails, RecipeInputOutput, Recipe, PlayerData, StakingData, MysteryBoxDrop)
// 5. Events
// 6. State Variables
// 7. Constructor
// 8. Modifiers (nonReentrant)
// 9. ERC-1155 Functions (Inherited)
// 10. Owner Functions
// 11. Player Interaction Functions
// 12. Internal Helper Functions
// 13. View Functions

// Function Summary:
// - constructor(): Initializes contract, sets owner, defines base XP requirements.
// - registerToken(uint256 _tokenId, TokenType _tokenType, string memory _uri): Owner registers a new ERC-1155 token type.
// - addRecipe(uint256 _recipeId, Recipe memory _recipe): Owner adds a new crafting recipe.
// - updateRecipe(uint256 _recipeId, Recipe memory _recipe): Owner modifies an existing recipe.
// - removeRecipe(uint256 _recipeId): Owner disables a recipe.
// - setSkillEffectiveness(SkillType _skillType, uint256 _multiplier): Owner sets skill multiplier values.
// - setCraftingCooldown(uint256 _recipeId, uint256 _cooldownSeconds): Owner sets crafting cooldown for a recipe.
// - setMiningCooldown(uint256 _resourceId, uint256 _cooldownSeconds): Owner sets mining cooldown for a resource.
// - setGlobalResourceCap(uint256 _resourceId, uint256 _cap): Owner sets max total mintable cap for a resource.
// - mintInitialResources(uint256 _resourceId, uint256 _amount, address _to): Owner mints initial resource supply.
// - addMysteryBoxDrop(uint256 _boxItemId, uint256 _dropItemId, uint256 _minAmount, uint256 _maxAmount, uint256 _weight): Owner adds a possible drop to a mystery box.
// - removeMysteryBoxDrop(uint256 _boxItemId, uint256 _dropItemId, uint256 _weightIndex): Owner removes a drop from a mystery box.
// - updateMysteryBoxDrop(uint256 _boxItemId, uint256 _weightIndex, uint256 _dropItemId, uint256 _minAmount, uint256 _maxAmount, uint256 _weight): Owner updates a drop configuration.
// - craftItem(uint256 _recipeId, uint256 _amount): Attempts to craft items. Handles inputs, skills, chance, cooldowns, failure, XP.
// - mineResource(uint256 _resourceId, uint256 _amount): Attempts to mine resources. Handles cooldowns, caps, minting, XP.
// - stakeResources(uint256 _resourceId, uint256 _amount): Stakes resources.
// - unstakeResources(uint256 _resourceId, uint256 _amount): Unstakes resources.
// - claimStakingRewards(): Claims staking rewards (XP, potential random drops).
// - allocateSkillPoints(SkillType _skillType, uint256 _points): Spends skill points to increase a skill level.
// - openMysteryBox(uint256 _boxItemId, uint256 _amount): Burns box item, mints random drops.
// - getPlayerLevel(address _player): View player level.
// - getPlayerXP(address _player): View player XP.
// - getPlayerSkillPoints(address _player): View player skill points.
// - getPlayerSkillLevel(address _player, SkillType _skillType): View player skill level for a skill.
// - getRecipeDetails(uint256 _recipeId): View recipe details.
// - getStakingData(address _player, uint256 _resourceId): View player staking data.
// - getCraftingCooldown(uint256 _recipeId): View recipe cooldown.
// - getPlayerLastCraftTime(address _player, uint256 _recipeId): View player's last craft time.
// - getMiningCooldown(uint256 _resourceId): View resource mining cooldown.
// - getPlayerLastMineTime(address _player, uint256 _resourceId): View player's last mine time.
// - getTokenDetails(uint256 _tokenId): View token type and URI prefix.
// - getResourceGlobalCap(uint256 _resourceId): View resource global cap.
// - getTotalResourceMinted(uint256 _resourceId): View total minted for a resource.
// - getXPNeededForLevel(uint256 _level): View XP needed for a level.
// - getMysteryBoxDropTable(uint256 _boxItemId): View mystery box drop table.
// - uri(uint256 _tokenId): ERC-1155 standard view.
// - balanceOf(address _account, uint256 _id): ERC-1155 standard view.
// - balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids): ERC-1155 standard view.
// - setApprovalForAll(address _operator, bool _approved): ERC-1155 standard function.
// - isApprovedForAll(address _account, address _operator): ERC-1155 standard view.
// - safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data): ERC-1155 standard function.
// - safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data): ERC-1155 standard function.
// - supportsInterface(bytes4 interfaceId): ERC-165 standard view.

contract CryptoCraftNexus is ERC1155, Ownable, ReentrancyGuard {

    // --- Enums ---
    enum TokenType { Resource, CraftedItem, MysteryBox }
    enum SkillType { CraftingEfficiency, MiningSpeed, Luck }

    // --- Structs ---
    struct TokenDetails {
        TokenType tokenType;
        string uriPrefix; // Used by uri()
        bool registered;
    }

    struct RecipeInputOutput {
        uint256 tokenId;
        uint256 amount;
    }

    struct Recipe {
        bool active; // Can be deactivated by owner
        RecipeInputOutput[] inputs;
        RecipeInputOutput[] outputs;
        SkillType requiredSkillType;
        uint256 requiredSkillLevel;
        uint256 baseSuccessChancePercent; // e.g., 70 for 70%
        // XP gained per craft attempt (regardless of success/failure)
        uint256 xpPerAttempt;
        // Percentage of input resources returned on failure
        uint256 failureReturnPercent; // e.g., 50 for 50%
    }

    struct PlayerData {
        uint256 level;
        uint256 xp;
        uint256 skillPoints;
        mapping(SkillType => uint256) skills; // SkillType -> Level
        mapping(uint256 => uint256) lastCraftTime; // RecipeId -> Timestamp
        mapping(uint256 => uint256) lastMineTime; // ResourceId -> Timestamp
    }

    struct StakingData {
        uint256 amount;
        uint256 lastClaimTime; // Timestamp of last reward claim or staking action
    }

    struct MysteryBoxDrop {
        uint256 dropItemId;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 weight; // Relative probability weight
    }

    // --- State Variables ---
    mapping(uint256 => TokenDetails) private _tokenDetails;
    mapping(uint256 => Recipe) private _recipes;
    mapping(address => PlayerData) private _playerData;
    mapping(address => mapping(uint256 => StakingData)) private _stakingData; // player => resourceId => StakingData

    // Skill effects: SkillType -> Multiplier (e.g., how many success chance points per skill level)
    mapping(SkillType => uint256) private _skillEffectiveness; // Multiplied by 100 to use uint256

    // Cooldowns in seconds
    mapping(uint256 => uint256) private _craftingCooldowns; // RecipeId -> seconds
    mapping(uint256 => uint256) private _miningCooldowns; // ResourceId -> seconds

    // Global limits for mineable resources
    mapping(uint256 => uint256) private _resourceGlobalCaps; // ResourceId -> total supply cap
    mapping(uint256 => uint256) private _totalResourceMinted; // ResourceId -> total currently minted via mineResource

    // XP progression curve (total XP required to REACH a level)
    // Index 0 is level 0, Index 1 is level 1, etc.
    // XP to reach level N = _xpNeededForLevel[N]
    // XP needed for level 1 is _xpNeededForLevel[1] - _xpNeededForLevel[0] (which is 0)
    uint256[] private _xpNeededForLevel;

    // Mystery box drops: boxItemId -> array of possible drops
    mapping(uint256 => MysteryBoxDrop[]) private _mysteryBoxDrops;

    // --- Events ---
    event TokenRegistered(uint256 indexed tokenId, TokenType tokenType, string uriPrefix);
    event RecipeAdded(uint256 indexed recipeId, Recipe recipe);
    event RecipeUpdated(uint256 indexed recipeId, Recipe recipe);
    event RecipeRemoved(uint256 indexed recipeId);
    event ItemCrafted(address indexed player, uint256 indexed recipeId, uint256 amount, bool success, uint256 xpGained);
    event CraftingFailed(address indexed player, uint256 indexed recipeId, uint256 amount, RecipeInputOutput[] inputsReturned);
    event ResourceMined(address indexed player, uint256 indexed resourceId, uint256 amount, uint256 xpGained);
    event ResourcesStaked(address indexed player, uint256 indexed resourceId, uint256 amount);
    event StakingRewardsClaimed(address indexed player, uint256 totalXPGained, RecipeInputOutput[] randomRewards);
    event ResourcesUnstaked(address indexed player, uint256 indexed resourceId, uint256 amount);
    event PlayerLeveledUp(address indexed player, uint256 newLevel, uint256 skillPointsEarned);
    event SkillPointsAllocated(address indexed player, SkillType skillType, uint256 pointsSpent, uint256 newSkillLevel);
    event MysteryBoxOpened(address indexed player, uint256 indexed boxItemId, uint256 amountBurned, RecipeInputOutput[] itemsMinted);
    event SkillEffectivenessSet(SkillType skillType, uint256 multiplier);
    event CraftingCooldownSet(uint256 indexed recipeId, uint256 cooldownSeconds);
    event MiningCooldownSet(uint256 indexed resourceId, uint256 cooldownSeconds);
    event ResourceCapSet(uint256 indexed resourceId, uint256 cap);
    event MysteryBoxDropAdded(uint256 indexed boxItemId, uint256 indexed dropItemId, uint256 minAmount, uint256 maxAmount, uint256 weight);
    event MysteryBoxDropRemoved(uint256 indexed boxItemId, uint256 indexed dropItemId, uint256 weightIndex);
    event MysteryBoxDropUpdated(uint256 indexed boxItemId, uint256 indexed dropItemId, uint256 weightIndex, uint256 minAmount, uint256 maxAmount, uint256 weight);


    // --- Constructor ---
    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {
        // Set base XP required for initial levels
        // xpNeededForLevel[0] = 0 (start at level 0)
        // xpNeededForLevel[1] = 100
        // xpNeededForLevel[2] = 300
        // xpNeededForLevel[3] = 600
        // ... define progression curve ...
        _xpNeededForLevel = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5500, 7000]; // Example curve
    }

    // --- Owner Functions ---

    function registerToken(uint256 _tokenId, TokenType _tokenType, string memory _uriPrefix) external onlyOwner {
        require(!_tokenDetails[_tokenId].registered, "Token already registered");
        _tokenDetails[_tokenId] = TokenDetails({
            tokenType: _tokenType,
            uriPrefix: _uriPrefix,
            registered: true
        });
        emit TokenRegistered(_tokenId, _tokenType, _uriPrefix);
    }

    function addRecipe(uint256 _recipeId, Recipe memory _recipe) external onlyOwner {
        require(!_recipes[_recipeId].active, "Recipe ID already exists");
        // Basic validation
        require(_recipe.inputs.length > 0 || _recipe.outputs.length > 0, "Recipe must have inputs or outputs");
        for (uint256 i = 0; i < _recipe.inputs.length; i++) {
             require(_tokenDetails[_recipe.inputs[i].tokenId].registered, "Input token not registered");
             // Could add checks here like: inputs cannot be CraftedItems or MysteryBoxes unless for upgrading
        }
         for (uint256 i = 0; i < _recipe.outputs.length; i++) {
             require(_tokenDetails[_recipe.outputs[i].tokenId].registered, "Output token not registered");
             // Could add checks here like: outputs cannot be Resources
         }
        _recipe.active = true;
        _recipes[_recipeId] = _recipe;
        emit RecipeAdded(_recipeId, _recipe);
    }

     function updateRecipe(uint256 _recipeId, Recipe memory _recipe) external onlyOwner {
        require(_recipes[_recipeId].active, "Recipe ID does not exist or is inactive");
         // Basic validation
        require(_recipe.inputs.length > 0 || _recipe.outputs.length > 0, "Recipe must have inputs or outputs");
         for (uint256 i = 0; i < _recipe.inputs.length; i++) {
             require(_tokenDetails[_recipe.inputs[i].tokenId].registered, "Input token not registered");
         }
         for (uint256 i = 0; i < _recipe.outputs.length; i++) {
             require(_tokenDetails[_recipe.outputs[i].tokenId].registered, "Output token not registered");
         }
        _recipe.active = true; // Ensure it stays active unless explicitly removed
        _recipes[_recipeId] = _recipe;
        emit RecipeUpdated(_recipeId, _recipe);
    }

    function removeRecipe(uint256 _recipeId) external onlyOwner {
        require(_recipes[_recipeId].active, "Recipe ID does not exist or is already inactive");
        _recipes[_recipeId].active = false; // Deactivate instead of deleting
        emit RecipeRemoved(_recipeId);
    }

    function setSkillEffectiveness(SkillType _skillType, uint256 _multiplier) external onlyOwner {
        // Multiplier is stored * 100 to allow for 2 decimal places implicitly (e.g., 150 -> 1.5x)
        _skillEffectiveness[_skillType] = _multiplier;
        emit SkillEffectivenessSet(_skillType, _multiplier);
    }

    function setCraftingCooldown(uint256 _recipeId, uint256 _cooldownSeconds) external onlyOwner {
         require(_recipes[_recipeId].active, "Recipe ID does not exist or is inactive");
        _craftingCooldowns[_recipeId] = _cooldownSeconds;
        emit CraftingCooldownSet(_recipeId, _cooldownSeconds);
    }

    function setMiningCooldown(uint256 _resourceId, uint256 _cooldownSeconds) external onlyOwner {
        require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
        _miningCooldowns[_resourceId] = _cooldownSeconds;
        emit MiningCooldownSet(_resourceId, _cooldownSeconds);
    }

     function setGlobalResourceCap(uint256 _resourceId, uint256 _cap) external onlyOwner {
        require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
        _resourceGlobalCaps[_resourceId] = _cap;
        emit ResourceCapSet(_resourceId, _cap);
    }

    function mintInitialResources(uint256 _resourceId, uint256 _amount, address _to) external onlyOwner {
         require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
         require(_to != address(0), "Cannot mint to zero address");
         // This bypasses the mining cap, intended for initial distribution
         _mint(_to, _resourceId, _amount, "");
    }

    function addMysteryBoxDrop(uint256 _boxItemId, uint256 _dropItemId, uint256 _minAmount, uint256 _maxAmount, uint256 _weight) external onlyOwner {
        require(_tokenDetails[_boxItemId].registered && _tokenDetails[_boxItemId].tokenType == TokenType.MysteryBox, "Box item is not a registered mystery box token");
        require(_tokenDetails[_dropItemId].registered, "Drop item not registered");
        require(_minAmount > 0 && _maxAmount >= _minAmount && _weight > 0, "Invalid drop configuration");

        _mysteryBoxDrops[_boxItemId].push(MysteryBoxDrop({
            dropItemId: _dropItemId,
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            weight: _weight
        }));
        emit MysteryBoxDropAdded(_boxItemId, _dropItemId, _minAmount, _maxAmount, _weight);
    }

    function removeMysteryBoxDrop(uint256 _boxItemId, uint256 _weightIndex) external onlyOwner {
        require(_tokenDetails[_boxItemId].registered && _tokenDetails[_boxItemId].tokenType == TokenType.MysteryBox, "Box item is not a registered mystery box token");
        require(_weightIndex < _mysteryBoxDrops[_boxItemId].length, "Invalid drop index");

        // Simple removal by swapping with last and popping
        uint256 lastIndex = _mysteryBoxDrops[_boxItemId].length - 1;
        MysteryBoxDrop memory removedDrop = _mysteryBoxDrops[_boxItemId][_weightIndex];
        if (_weightIndex != lastIndex) {
             _mysteryBoxDrops[_boxItemId][_weightIndex] = _mysteryBoxDrops[_boxItemId][lastIndex];
        }
        _mysteryBoxDrops[_boxItemId].pop();

        emit MysteryBoxDropRemoved(_boxItemId, removedDrop.dropItemId, _weightIndex);
    }

     function updateMysteryBoxDrop(uint256 _boxItemId, uint256 _weightIndex, uint256 _dropItemId, uint256 _minAmount, uint256 _maxAmount, uint256 _weight) external onlyOwner {
        require(_tokenDetails[_boxItemId].registered && _tokenDetails[_boxItemId].tokenType == TokenType.MysteryBox, "Box item is not a registered mystery box token");
        require(_weightIndex < _mysteryBoxDrops[_boxItemId].length, "Invalid drop index");
        require(_tokenDetails[_dropItemId].registered, "Drop item not registered");
        require(_minAmount > 0 && _maxAmount >= _minAmount && _weight > 0, "Invalid drop configuration");

        _mysteryBoxDrops[_boxItemId][_weightIndex] = MysteryBoxDrop({
            dropItemId: _dropItemId,
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            weight: _weight
        });

        emit MysteryBoxDropUpdated(_boxItemId, _dropItemId, _weightIndex, _minAmount, _maxAmount, _weight);
     }


    // --- Player Interaction Functions ---

    function craftItem(uint256 _recipeId, uint256 _amount) external nonReentrant {
        require(_recipes[_recipeId].active, "Recipe does not exist or is inactive");
        require(_amount > 0, "Amount must be greater than 0");

        Recipe storage recipe = _recipes[_recipeId];
        PlayerData storage player = _playerData[msg.sender];

        // Check Cooldown
        require(block.timestamp >= player.lastCraftTime[_recipeId] + _craftingCooldowns[_recipeId], "Crafting is on cooldown");

        // Check Skill Requirement
        require(player.skills[recipe.requiredSkillType] >= recipe.requiredSkillLevel, "Player skill level too low");

        // Check Inputs
        uint256[] memory inputIds = new uint256[](recipe.inputs.length);
        uint256[] memory inputAmounts = new uint256[](recipe.inputs.length);
        for (uint256 i = 0; i < recipe.inputs.length; i++) {
            inputIds[i] = recipe.inputs[i].tokenId;
            inputAmounts[i] = recipe.inputs[i].amount * _amount; // Total amount needed
            require(balanceOf(msg.sender, inputIds[i]) >= inputAmounts[i], "Insufficient input resources");
        }

        // Burn Inputs
        _burn(msg.sender, inputIds, inputAmounts);

        // Process Crafts
        RecipeInputOutput[] memory failedReturnItems; // To store items returned on failure
        RecipeInputOutput[] memory mintedOutputItems; // To store items minted on success (aggregated)
        mapping(uint256 => uint256) tempMintedAmounts; // Aggregate amounts for batch minting

        uint256 totalXPGained = 0;

        for (uint256 i = 0; i < _amount; i++) {
            bool success = _tryCraft(_recipeId, msg.sender);
            totalXPGained += recipe.xpPerAttempt;

            if (success) {
                // Aggregate successful outputs
                for (uint256 j = 0; j < recipe.outputs.length; j++) {
                     tempMintedAmounts[recipe.outputs[j].tokenId] += recipe.outputs[j].amount;
                }
            } else {
                // Calculate and aggregate failure return
                if (recipe.failureReturnPercent > 0) {
                     for (uint256 j = 0; j < recipe.inputs.length; j++) {
                          uint256 returnAmount = (recipe.inputs[j].amount * recipe.failureReturnPercent) / 100;
                           if (returnAmount > 0) {
                              // Add to a temporary list for batch minting later
                              bool found = false;
                              for(uint k=0; k < failedReturnItems.length; k++) {
                                   if(failedReturnItems[k].tokenId == recipe.inputs[j].tokenId) {
                                       failedReturnItems[k].amount += returnAmount;
                                       found = true;
                                       break;
                                   }
                              }
                              if (!found) {
                                   RecipeInputOutput[] memory temp = new RecipeInputOutput[](failedReturnItems.length + 1);
                                   for(uint k=0; k < failedReturnItems.length; k++) temp[k] = failedReturnItems[k];
                                   temp[failedReturnItems.length] = RecipeInputOutput(recipe.inputs[j].tokenId, returnAmount);
                                   failedReturnItems = temp;
                              }
                          }
                     }
                }
            }
             emit ItemCrafted(msg.sender, _recipeId, 1, success, recipe.xpPerAttempt); // Emit for each individual attempt
        }

        // Mint successful outputs in batch
        uint256[] memory outputIds = new uint256[](tempMintedAmounts.length);
        uint256[] memory outputAmounts = new uint256[](tempMintedAmounts.length);
        uint256 outputIndex = 0;
        for (uint256 tokenId in tempMintedAmounts) {
            if (tempMintedAmounts[tokenId] > 0) {
                outputIds[outputIndex] = tokenId;
                outputAmounts[outputIndex] = tempMintedAmounts[tokenId];
                outputIndex++;
            }
        }
        if (outputIndex > 0) {
             // Resize arrays if necessary (depends on Solidity version, can be done manually or with helper)
             uint256[] memory finalOutputIds = new uint256[](outputIndex);
             uint256[] memory finalOutputAmounts = new uint256[](outputIndex);
             for(uint i = 0; i < outputIndex; i++) {
                  finalOutputIds[i] = outputIds[i];
                  finalOutputAmounts[i] = outputAmounts[i];
             }
            _mintBatch(msg.sender, finalOutputIds, finalOutputAmounts, "");
        }


        // Return failed inputs in batch
         if (failedReturnItems.length > 0) {
             uint256[] memory returnIds = new uint256[](failedReturnItems.length);
             uint256[] memory returnAmounts = new uint256[](failedReturnItems.length);
             for(uint i=0; i < failedReturnItems.length; i++) {
                 returnIds[i] = failedReturnItems[i].tokenId;
                 returnAmounts[i] = failedReturnItems[i].amount;
             }
             _mintBatch(msg.sender, returnIds, returnAmounts, ""); // Mint back to player
             emit CraftingFailed(msg.sender, _recipeId, _amount, failedReturnItems); // Emit aggregated return
         }


        // Update last craft time (cooldown starts after the batch)
        player.lastCraftTime[_recipeId] = block.timestamp;

        // Distribute Total XP gained from all attempts
        _distributeXP(msg.sender, totalXPGained);
    }

    function mineResource(uint256 _resourceId, uint256 _amount) external nonReentrant {
        require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
        require(_amount > 0, "Amount must be greater than 0");

        PlayerData storage player = _playerData[msg.sender];

        // Check Cooldown
        require(block.timestamp >= player.lastMineTime[_resourceId] + _miningCooldowns[_resourceId], "Mining is on cooldown");

        // Check Global Cap
        uint256 cap = _resourceGlobalCaps[_resourceId];
        if (cap > 0) { // Cap of 0 means unlimited
             require(_totalResourceMinted[_resourceId] + _amount <= cap, "Mining would exceed global cap");
        }

        // Simulate mining success (could add skill check here too)
        // For simplicity, assume success unless cap hit or cooldown active (already checked)
        _mint(msg.sender, _resourceId, _amount, "");
        _updateMiningSupply(_resourceId, _amount);

        // Update last mine time
        player.lastMineTime[_resourceId] = block.timestamp;

        // Distribute XP (could be based on resource type or amount)
        uint256 xpGained = _amount * 1; // Example: 1 XP per resource unit mined
        _distributeXP(msg.sender, xpGained);

        emit ResourceMined(msg.sender, _resourceId, _amount, xpGained);
    }

    function stakeResources(uint256 _resourceId, uint256 _amount) external nonReentrant {
         require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
         require(_amount > 0, "Amount must be greater than 0");
         require(balanceOf(msg.sender, _resourceId) >= _amount, "Insufficient resource balance");

         _stakingData[msg.sender][_resourceId].amount += _amount;
         // Update last claim time if staking for the first time or adding to stake
         if (_stakingData[msg.sender][_resourceId].lastClaimTime == 0) {
             _stakingData[msg.sender][_resourceId].lastClaimTime = block.timestamp;
         } else {
             // Claim rewards before adding more stake if player has existing stake
             // This prevents exploits where players add small amounts to reset timer and claim full rewards early
              _claimStakingRewards(msg.sender);
              _stakingData[msg.sender][_resourceId].lastClaimTime = block.timestamp; // Reset after claim
         }


         _burn(msg.sender, _resourceId, _amount);

         emit ResourcesStaked(msg.sender, _resourceId, _amount);
    }

     function unstakeResources(uint256 _resourceId, uint256 _amount) external nonReentrant {
         require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
         require(_amount > 0, "Amount must be greater than 0");
         require(_stakingData[msg.sender][_resourceId].amount >= _amount, "Not enough resources staked");

         // Claim rewards before unstaking
         _claimStakingRewards(msg.sender);

         _stakingData[msg.sender][_resourceId].amount -= _amount;
         _mint(msg.sender, _resourceId, _amount, "");

         // If unstaking all, clear the last claim time
         if (_stakingData[msg.sender][_resourceId].amount == 0) {
             _stakingData[msg.sender][_resourceId].lastClaimTime = 0;
         } else {
             // If not unstaking all, update last claim time after claim
              _stakingData[msg.sender][_resourceId].lastClaimTime = block.timestamp;
         }


         emit ResourcesUnstaked(msg.sender, _resourceId, _amount);
     }

    function claimStakingRewards() external nonReentrant {
        _claimStakingRewards(msg.sender);
    }

    // Internal function to handle reward claiming logic
    function _claimStakingRewards(address _player) internal {
        uint256 totalXPGained = 0;
        RecipeInputOutput[] memory randomRewards; // Placeholder for potential random drops

        // Iterate over all registered resources (need to add a way to track these better, e.g., a list or iterating through mapping keys - iterating is gas intensive)
        // For this example, we'll iterate a limited set or assume we know resource IDs.
        // A more scalable approach would be to track active staking resources per player or use a list of registered resource IDs.
        // Let's assume we iterate through a known range or list for the example structure.
        // Example: Iterate through resource IDs 1 to 10 (assuming they are registered resources)
        // In a real contract, you'd need a mapping or array of ALL resource IDs.
        // This is a placeholder and needs refinement based on how resource IDs are tracked.
        // A simple approach for demonstration: iterate over player's currently staked resources.
        // This requires iterating over player's staking data, which is also not trivial.
        // Let's simplify: claim rewards on *all* currently staked resources for the player.

        // To iterate staked resources for a player:
        // 1. Need a way to get all resource IDs a player has staked. Not directly possible with just the nested mapping.
        // Alternative: Make players claim per resource type OR iterate a global list of resource IDs (if size is bounded).
        // Let's go with claiming XP based on *total* staked amount across *all* resources, simplified.
        // And add a *chance* for a single random drop based on staking.

        uint256 totalStakedAmount = 0;
        uint256 lastClaimTime = block.timestamp; // Will track the earliest last claim time to advance

        // --- Simplified Staking Reward Logic (Example) ---
        // This simplified version calculates XP based on the total amount currently staked
        // across all resources and the time since the *last* claim.
        // It also offers a small chance for a random reward per claim.

        // Need to iterate over staked resources to sum amount and find earliest lastClaimTime
        // This highlights a limitation of pure mapping-based storage for iteration.
        // A more robust system might use linked lists for staked resource IDs per player,
        // or require players to claim rewards per specific resource ID.

        // Let's refine: Require players to claim per resource ID for easier implementation iteration.
        // This means claimStakingRewards needs a resourceId argument.

        // Adjusting the function signature:
        // function claimStakingRewards(uint256 _resourceId) external nonReentrant { ... }

        // Re-writing the claim logic based on claiming for a single resource type:
    }

    // Redefining claimStakingRewards to claim for a specific resource ID
     function claimStakingRewards(uint256 _resourceId) external nonReentrant {
         require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
         StakingData storage staking = _stakingData[msg.sender][_resourceId];
         require(staking.amount > 0, "No resources staked for this ID");
         require(staking.lastClaimTime < block.timestamp, "No rewards accumulated yet");

         uint256 timeElapsed = block.timestamp - staking.lastClaimTime;
         uint256 stakedAmount = staking.amount;

         // Example XP calculation: XP per day per staked unit
         uint256 xpPerUnitPerSecond = 100 / (1 days); // 100 XP per unit per day
         // Adjust XP based on player's MiningSpeed skill?
         uint256 skillMultiplier = 100 + (_playerData[msg.sender].skills[SkillType.MiningSpeed] * _skillEffectiveness[SkillType.MiningSpeed]) / 100;
         xpPerUnitPerSecond = (xpPerUnitPerSecond * skillMultiplier) / 100;

         uint256 xpGained = (stakedAmount * timeElapsed * xpPerUnitPerSecond) / (1e18); // Example: Scale by 1e18 if xpPerUnitPerSecond uses decimals

         // Simplify scaling for example: assume xpPerUnitPerSecond is integer, timeElapsed is seconds
         xpGained = (stakedAmount * timeElapsed * (100 / (1 days))) / 100; // Base 100 XP/unit/day
         xpGained = (xpGained * skillMultiplier) / 100; // Apply skill multiplier

         totalXPGained += xpGained;


        // --- Random Reward Chance (Example) ---
        // Simple chance check per staked resource type claim
        uint256 randomSeed = _getRandomNumber(block.timestamp + block.difficulty + uint256(keccak256(abi.encodePacked(msg.sender, _resourceId, timeElapsed))));
        // 1% chance per claim (highly simplified)
        if (randomSeed % 100 < 1) {
            // Select a random item from a predefined list or another mechanism
            // This needs a mechanism to define what items can drop from staking rewards
            // For this example, let's hardcode a potential reward ID and amount
            uint256 potentialRewardId = 999; // Example special item ID
            uint256 potentialRewardAmount = 1;
             // Need to check if potentialRewardId is registered as CraftedItem or MysteryBox
             if (_tokenDetails[potentialRewardId].registered &&
                 (_tokenDetails[potentialRewardId].tokenType == TokenType.CraftedItem || _tokenDetails[potentialRewardId].tokenType == TokenType.MysteryBox)) {
                 RecipeInputOutput[] memory temp = new RecipeInputOutput[](1);
                 temp[0] = RecipeInputOutput(potentialRewardId, potentialRewardAmount);
                 randomRewards = temp;
                 _mint(msg.sender, potentialRewardId, potentialRewardAmount, "");
             }
        }

        // Update last claim time
        staking.lastClaimTime = block.timestamp;

        // Distribute XP
        _distributeXP(msg.sender, totalXPGained);

        emit StakingRewardsClaimed(msg.sender, totalXPGained, randomRewards); // randomRewards might be empty
    }


     function allocateSkillPoints(SkillType _skillType, uint256 _points) external nonReentrant {
         PlayerData storage player = _playerData[msg.sender];
         require(_points > 0, "Points must be greater than 0");
         require(player.skillPoints >= _points, "Not enough skill points");

         player.skillPoints -= _points;
         player.skills[_skillType] += _points; // Each point increases skill level by 1

         emit SkillPointsAllocated(msg.sender, _skillType, _points, player.skills[_skillType]);
     }

    function openMysteryBox(uint256 _boxItemId, uint256 _amount) external nonReentrant {
        require(_tokenDetails[_boxItemId].registered && _tokenDetails[_boxItemId].tokenType == TokenType.MysteryBox, "Item is not a registered mystery box token");
        require(_amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender, _boxItemId) >= _amount, "Insufficient mystery box balance");

        MysteryBoxDrop[] storage drops = _mysteryBoxDrops[_boxItemId];
        require(drops.length > 0, "Mystery box has no drops configured");

        // Burn the boxes
        _burn(msg.sender, _boxItemId, _amount);

        mapping(uint256 => uint256) tempMintedAmounts; // Aggregate amounts for batch minting
        RecipeInputOutput[] memory mintedOutputItems; // Store final minted items for event

        for (uint256 i = 0; i < _amount; i++) {
            // Select drops for each box
            uint256 totalWeight = 0;
            for (uint256 j = 0; j < drops.length; j++) {
                totalWeight += drops[j].weight;
            }
            require(totalWeight > 0, "Total drop weight must be greater than 0");

            // Generate random number for selection (insecure)
            uint256 randomSeed = _getRandomNumber(block.timestamp + block.difficulty + uint256(keccak256(abi.encodePacked(msg.sender, _boxItemId, i, totalWeight))));
            uint256 randomNumber = randomSeed % totalWeight;

            // Select drop based on weight
            uint256 cumulativeWeight = 0;
            MysteryBoxDrop memory selectedDrop;
            bool dropFound = false;
            for (uint256 j = 0; j < drops.length; j++) {
                cumulativeWeight += drops[j].weight;
                if (randomNumber < cumulativeWeight) {
                    selectedDrop = drops[j];
                    dropFound = true;
                    break;
                }
            }
            require(dropFound, "Error selecting mystery box drop"); // Should not happen if totalWeight > 0

            // Generate random amount within min/max (insecure)
             randomSeed = _getRandomNumber(block.timestamp + block.difficulty + uint256(keccak256(abi.encodePacked(msg.sender, _boxItemId, i, selectedDrop.dropItemId, block.number))));
            uint256 amountToMint = selectedDrop.minAmount + (randomSeed % (selectedDrop.maxAmount - selectedDrop.minAmount + 1));

            if (amountToMint > 0) {
                tempMintedAmounts[selectedDrop.dropItemId] += amountToMint;
            }
        }

        // Mint awarded items/resources in batch
        uint256 outputIndex = 0;
        uint256[] memory outputIds = new uint256[](tempMintedAmounts.length); // Potentially oversized
        uint256[] memory outputAmounts = new uint256[](tempMintedAmounts.length); // Potentially oversized

        for (uint256 tokenId in tempMintedAmounts) {
            if (tempMintedAmounts[tokenId] > 0) {
                outputIds[outputIndex] = tokenId;
                outputAmounts[outputIndex] = tempMintedAmounts[tokenId];
                outputIndex++;
            }
        }

        if (outputIndex > 0) {
            // Resize arrays
             uint256[] memory finalOutputIds = new uint256[](outputIndex);
             uint256[] memory finalOutputAmounts = new uint256[](outputIndex);
             for(uint i = 0; i < outputIndex; i++) {
                  finalOutputIds[i] = outputIds[i];
                  finalOutputAmounts[i] = outputAmounts[i];
             }

            _mintBatch(msg.sender, finalOutputIds, finalOutputAmounts, "");
             // Copy to mintedOutputItems for the event (resize needed)
             mintedOutputItems = new RecipeInputOutput[](outputIndex);
             for(uint i = 0; i < outputIndex; i++) {
                 mintedOutputItems[i] = RecipeInputOutput(finalOutputIds[i], finalOutputAmounts[i]);
             }
        } else {
             mintedOutputItems = new RecipeInputOutput[](0); // Empty array if nothing was minted
        }


        emit MysteryBoxOpened(msg.sender, _boxItemId, _amount, mintedOutputItems);
    }

    // --- Internal Helper Functions ---

    // Internal function to determine crafting success and handle outcomes
    function _tryCraft(uint256 _recipeId, address _player) internal view returns (bool success) {
        Recipe storage recipe = _recipes[_recipeId];
        PlayerData storage player = _playerData[_player];

        // Calculate success chance based on skill
        uint256 skillLevel = player.skills[recipe.requiredSkillType];
        uint256 skillMultiplier = _skillEffectiveness[recipe.requiredSkillType]; // Multiplied by 100
        uint256 skillBonus = (skillLevel * skillMultiplier) / 100; // Actual bonus percentage
        uint256 effectiveSuccessChance = Math.min(100, recipe.baseSuccessChancePercent + skillBonus); // Cap at 100%

        // Generate random number for success check (INSECURE)
        // WARNING: block.timestamp and block.difficulty (or blockhash) are NOT cryptographically secure
        // and can be manipulated by miners/validators. Use Chainlink VRF or similar for secure randomness.
        uint256 randomNumber = _getRandomNumber(block.timestamp + block.difficulty + uint256(keccak256(abi.encodePacked(_player, _recipeId, block.number))));

        // Check if random number is within success range
        return randomNumber % 100 < effectiveSuccessChance;
    }

    // Internal function to add XP, check for level ups, and grant skill points
    function _distributeXP(address _player, uint256 _xp) internal {
        if (_xp == 0) return;

        PlayerData storage player = _playerData[_player];
        uint256 currentLevel = player.level;
        player.xp += _xp;

        uint256 newLevel = currentLevel;
        uint256 skillPointsGained = 0;

        // Check for level ups
        // Need to iterate through xpNeededForLevel array
        // Note: Iterating state variables like arrays can be gas-expensive if the array is large.
        // Consider a different XP curve or a helper function if levels are numerous.
        for (uint256 i = currentLevel + 1; i < _xpNeededForLevel.length; i++) {
            if (player.xp >= _xpNeededForLevel[i]) {
                newLevel = i;
                skillPointsGained += 1; // Example: Grant 1 skill point per level
                emit PlayerLeveledUp(_player, newLevel, skillPointsGained);
            } else {
                break; // Stop checking if next level requirement is not met
            }
        }

        player.level = newLevel;
        player.skillPoints += skillPointsGained;
    }

    // Internal helper for mining supply cap
    function _updateMiningSupply(uint256 _resourceId, uint256 _amount) internal {
        _totalResourceMinted[_resourceId] += _amount;
    }

    // --- INSECURE RANDOMNESS FUNCTION (DO NOT USE FOR HIGH-VALUE APPLICATIONS) ---
    // This function provides a simple way to get a pseudo-random number on-chain.
    // It is vulnerable to miner/validator manipulation.
    function _getRandomNumber(uint256 _seed) internal view returns (uint256) {
        // Combine block hash, timestamp, difficulty, and a unique seed for more "randomness"
        // Note: blockhash(block.number - 1) is a better practice if available, but block.difficulty/timestamp are simpler for basic examples
        // Using block.number and potentially tx.origin/msg.sender can also add entropy but have other risks.
        // Using block.timestamp and block.difficulty is common in simple examples despite flaws.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _seed)));
    }


    // --- View Functions ---

    function getPlayerLevel(address _player) external view returns (uint256) {
        return _playerData[_player].level;
    }

    function getPlayerXP(address _player) external view returns (uint256) {
        return _playerData[_player].xp;
    }

    function getPlayerSkillPoints(address _player) external view returns (uint256) {
        return _playerData[_player].skillPoints;
    }

    function getPlayerSkillLevel(address _player, SkillType _skillType) external view returns (uint256) {
        return _playerData[_player].skills[_skillType];
    }

    function getRecipeDetails(uint256 _recipeId) external view returns (Recipe memory) {
        require(_recipes[_recipeId].active, "Recipe does not exist or is inactive");
        return _recipes[_recipeId];
    }

     function getStakingData(address _player, uint256 _resourceId) external view returns (StakingData memory) {
         require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
         return _stakingData[_player][_resourceId];
     }

    function getCraftingCooldown(uint256 _recipeId) external view returns (uint256) {
        require(_recipes[_recipeId].active, "Recipe does not exist or is inactive");
        return _craftingCooldowns[_recipeId];
    }

    function getPlayerLastCraftTime(address _player, uint256 _recipeId) external view returns (uint256) {
        return _playerData[_player].lastCraftTime[_recipeId];
    }

    function getMiningCooldown(uint256 _resourceId) external view returns (uint256) {
        require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
        return _miningCooldowns[_resourceId];
    }

    function getPlayerLastMineTime(address _player, uint256 _resourceId) external view returns (uint256) {
        return _playerData[_player].lastMineTime[_resourceId];
    }

    function getTokenDetails(uint256 _tokenId) external view returns (TokenDetails memory) {
        require(_tokenDetails[_tokenId].registered, "Token not registered");
        return _tokenDetails[_tokenId];
    }

    function getResourceGlobalCap(uint256 _resourceId) external view returns (uint256) {
        require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
        return _resourceGlobalCaps[_resourceId];
    }

    function getTotalResourceMinted(uint256 _resourceId) external view returns (uint256) {
         require(_tokenDetails[_resourceId].registered && _tokenDetails[_resourceId].tokenType == TokenType.Resource, "Token is not a registered resource");
        return _totalResourceMinted[_resourceId];
    }

     function getXPNeededForLevel(uint256 _level) external view returns (uint256) {
         require(_level < _xpNeededForLevel.length, "Invalid level");
         return _xpNeededForLevel[_level];
     }

    function getMysteryBoxDropTable(uint256 _boxItemId) external view returns (MysteryBoxDrop[] memory) {
        require(_tokenDetails[_boxItemId].registered && _tokenDetails[_boxItemId].tokenType == TokenType.MysteryBox, "Item is not a registered mystery box token");
        return _mysteryBoxDrops[_boxItemId];
    }


    // --- ERC-1155 Standard Overrides (if needed) ---
    // The base ERC1155 contract handles these primarily.
    // We override uri to use our stored uriPrefix.
    function uri(uint256 _tokenId) override public view returns (string memory) {
        // Append token ID to the URI prefix
         require(_tokenDetails[_tokenId].registered, "Token not registered for URI");
        return string(abi.encodePacked(_tokenDetails[_tokenId].uriPrefix, Strings.toString(_tokenId), ".json"));
    }

    // balanceOf, balanceOfBatch, setApprovalForAll, isApprovedForAll, safeTransferFrom, safeBatchTransferFrom
    // are handled by the inherited OpenZeppelin ERC1155 contract unless custom hooks are required.
    // supportsInterface is handled by the inherited OpenZeppelin ERC1155 and Ownable contracts.
}
```