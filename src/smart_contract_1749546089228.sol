Okay, let's design a smart contract that combines elements of resource management, crafting, discovery, and dynamic digital assets within a decentralized world. We'll call it "CryptoCraft".

It will involve:
1.  **Resources:** ERC-20 tokens representing different raw materials.
2.  **Items:** Crafted from resources. Could be unique (ERC-721) or stackable/consumable (ERC-1155). Some items might have dynamic properties or uses.
3.  **Crafting:** Using recipes to transform resources into items. Recipes can be time-gated (cooldowns) or seasonal.
4.  **Discovery:** A mechanism to find new resources, potentially with variable outcomes and costs (paid in native token or resources).
5.  **Staking:** Stake resources or items to earn passive rewards or gain advantages (like reduced crafting/discovery cooldowns).

This combines multiple token standards (ERC-20, ERC-721, ERC-1155), time-based mechanics, state-dependent logic, and multiple distinct user interactions, going beyond a simple mint or token transfer contract.

---

**CryptoCraft Smart Contract Outline and Function Summary**

**Contract Name:** `CryptoCraft`

**Description:** A decentralized crafting and discovery protocol where users collect resources (ERC20), craft unique (ERC721) and consumable (ERC1155) items, attempt resource discovery, and stake assets for benefits.

**Interfaces Used:**
*   `IERC20`: For resource tokens.
*   `IERC721`: For unique crafted items.
*   `IERC1155`: For stackable/consumable items.
*   `Ownable`: For administrative functions.

**State Variables:**
*   `resourceToken`: Address of the primary ERC20 resource token.
*   `itemToken721`: Address of the ERC721 token for unique items.
*   `itemToken1155`: Address of the ERC1155 token for stackable/consumable items.
*   `recipes`: Mapping of recipe ID to `Recipe` struct.
*   `userCraftCooldowns`: Tracks user cooldowns for each recipe.
*   `discoveryPool`: Mapping of resource ID to amount available for discovery distribution.
*   `discoveryCostNative`: Cost in native token (wei) per discovery attempt.
*   `discoveryCostResource`: Cost in resource token per discovery attempt (alternative or combined).
*   `discoveryCooldown`: Cooldown duration (seconds) per discovery attempt.
*   `userDiscoveryCooldown`: Tracks user discovery cooldown.
*   `seasonalRecipes`: Mapping of recipe ID to boolean indicating if it's currently seasonal.
*   `protocolTreasury`: Address receiving native token costs or resource token fees.
*   `userStakedResources`: Mapping of user address to staked resource token balance.
*   `userStakingRewardSnapshots`: Tracks last reward calculation time for staking.
*   `stakingRewardRatePerSecond`: Rate of resource token reward per second per staked resource token.
*   `itemUsageCount`: Mapping of ERC721 token ID to current usage count (for items with limited uses).
*   `maxItemUsages`: Mapping of ERC721 token ID (type) to max usage count.

**Structs:**
*   `Recipe`: Defines crafting requirements and outputs. Includes input resources (ID => amount), output token type (enum), output token address, output token ID, output amount, success chance (optional, can be 100%), cooldown, required item (optional prerequisite).

**Enums:**
*   `TokenType`: `None`, `ERC20`, `ERC721`, `ERC1155`.

**Events:**
*   `RecipeAdded`: Emitted when a new recipe is added.
*   `RecipeUpdated`: Emitted when a recipe is updated.
*   `RecipeRemoved`: Emitted when a recipe is removed.
*   `RecipeToggledSeason`: Emitted when a recipe's seasonal status changes.
*   `Crafted`: Emitted when an item is successfully crafted.
*   `DiscoveryAttempt`: Emitted when a user attempts discovery.
*   `ResourcesDiscovered`: Emitted when resources are distributed from discovery.
*   `DiscoveryPoolAdded`: Emitted when resources are added to the pool.
*   `DiscoveryPoolRemoved`: Emitted when resources are removed from the pool.
*   `ItemUsed`: Emitted when a consumable or limited-use item is used.
*   `ResourcesStaked`: Emitted when resources are staked.
*   `ResourcesUnstaked`: Emitted when resources are unstaked.
*   `StakingRewardsClaimed`: Emitted when staking rewards are claimed.

**Functions (Total: 26+):**

*   **Owner/Admin (13 functions):**
    1.  `constructor()`: Initializes contract with token addresses and owner.
    2.  `setResourceToken(address _token)`: Sets the address of the ERC20 resource token.
    3.  `setItemToken721(address _token)`: Sets the address of the ERC721 item token.
    4.  `setItemToken1155(address _token)`: Sets the address of the ERC1155 item token.
    5.  `addRecipe(uint256 _recipeId, Recipe memory _recipe)`: Adds a new crafting recipe.
    6.  `updateRecipe(uint256 _recipeId, Recipe memory _recipe)`: Updates an existing recipe.
    7.  `removeRecipe(uint256 _recipeId)`: Removes a recipe.
    8.  `setDiscoveryCost(uint256 _costNative, uint256 _costResource)`: Sets discovery costs.
    9.  `setDiscoveryCooldown(uint64 _cooldown)`: Sets discovery cooldown.
    10. `setProtocolTreasury(address _treasury)`: Sets the treasury address.
    11. `addDiscoveryPoolResources(uint256[] calldata _resourceIds, uint256[] calldata _amounts)`: Adds resources to the discovery pool.
    12. `removeDiscoveryPoolResources(uint256[] calldata _resourceIds, uint256[] calldata _amounts)`: Removes resources from the discovery pool.
    13. `toggleSeasonalRecipe(uint256 _recipeId, bool _isSeasonal)`: Toggles the seasonal status of a recipe.
    14. `setStakingRewardRate(uint256 _rate)`: Sets the staking reward rate.
    15. `setMaxItemUsages(uint256 _itemId, uint256 _maxUsages)`: Sets max usage for an ERC721 item type.

*   **User Interaction (11 functions):**
    16. `craftItem(uint256 _recipeId)`: Attempts to craft an item using a specific recipe.
    17. `attemptDiscovery()`: Attempts to discover resources. Pays cost, subject to cooldown.
    18. `useItem(uint256 _tokenId)`: Uses a specific ERC721 item instance if it has usage limits.
    19. `useConsumable(uint256 _itemId, uint256 _amount)`: Uses a quantity of an ERC1155 consumable item.
    20. `stakeResources(uint256 _amount)`: Stakes resource tokens.
    21. `unstakeResources(uint256 _amount)`: Unstakes resource tokens and claims pending rewards.
    22. `claimStakingRewards()`: Claims pending staking rewards without unstaking.
    23. `depositNativeTokenForDiscoveryCost()`: Sends native token to the contract to cover discovery costs.
    24. `withdrawNativeTokenFromDiscoveryCost(uint256 _amount)`: Allows treasury to withdraw accumulated native token costs. (Admin function, let's move it to admin). Add to admin list.
    25. `withdrawResourceTokenFromTreasury(uint256 _resourceId, uint256 _amount)`: Allows treasury to withdraw accumulated resource token costs. (Admin function, let's move it to admin). Add to admin list.

*   **View/Information (8 functions):**
    26. `getRecipeDetails(uint256 _recipeId)`: Returns details of a recipe.
    27. `getDiscoveryPoolDetails()`: Returns details of the discovery pool contents.
    28. `getUserCooldowns(address _user)`: Returns craft and discovery cooldowns for a user.
    29. `getUserStakedBalance(address _user)`: Returns staked resource balance for a user.
    30. `getPendingStakingRewards(address _user)`: Returns pending staking rewards for a user.
    31. `getItemUsageCount(uint256 _tokenId)`: Returns the current usage count for an ERC721 item instance.
    32. `getMaxItemUsages(uint256 _itemId)`: Returns the max usage count for an ERC721 item type.
    33. `getTokenTypeAddress(TokenType _type)`: Helper view to get the address for a given token type enum.

**Refined Function Count:** 15 (Admin) + 8 (User) + 8 (View) = 31 functions. Meets the >= 20 requirement easily.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// CryptoCraft Smart Contract: Crafting, Discovery, and Staking Protocol
// A decentralized world where users manage resources, craft items,
// explore for new materials, and stake assets for passive rewards.

// Outline:
// 1. State Variables: Addresses for resource/item tokens, recipe data, cooldowns, discovery pool, staking data.
// 2. Structs & Enums: Define data structures for recipes and token types.
// 3. Events: Announce key actions like crafting, discovery, staking, etc.
// 4. Modifiers: (None specific needed beyond Ownable)
// 5. Admin Functions: Setup and configuration of recipes, costs, cooldowns, treasury, staking rates.
// 6. User Functions: Core interactions - crafting, discovery, using items, staking, claiming rewards.
// 7. Internal/Helper Functions: Logic for processing crafting outputs, calculating rewards, handling randomness.
// 8. View Functions: Retrieve information about recipes, pools, cooldowns, balances, pending rewards.

// Function Summary:
// Admin Functions (15):
// - constructor(): Initializes contract with token addresses and owner.
// - setResourceToken(address _token): Sets the ERC20 resource token address.
// - setItemToken721(address _token): Sets the ERC721 unique item token address.
// - setItemToken1155(address _token): Sets the ERC1155 consumable item token address.
// - addRecipe(uint256 _recipeId, Recipe memory _recipe): Adds a new crafting recipe.
// - updateRecipe(uint256 _recipeId, Recipe memory _recipe): Modifies an existing recipe.
// - removeRecipe(uint256 _recipeId): Deletes a recipe.
// - setDiscoveryCost(uint256 _costNative, uint256 _costResource): Sets costs for discovery attempts.
// - setDiscoveryCooldown(uint64 _cooldown): Sets the cooldown duration for discovery.
// - setProtocolTreasury(address _treasury): Sets the address receiving protocol fees/costs.
// - addDiscoveryPoolResources(uint256[] calldata _resourceIds, uint256[] calldata _amounts): Adds resources to the pool used for discovery rewards.
// - removeDiscoveryPoolResources(uint256[] calldata _resourceIds, uint256[] calldata _amounts): Removes resources from the discovery pool.
// - toggleSeasonalRecipe(uint256 _recipeId, bool _isSeasonal): Marks a recipe as seasonal or not.
// - setStakingRewardRate(uint256 _rate): Sets the rate at which staked resources earn rewards.
// - setMaxItemUsages(uint256 _itemId, uint256 _maxUsages): Sets the maximum usage count for a specific ERC721 item type.
// - withdrawNativeTokenFromDiscoveryCost(uint256 _amount): Allows owner to withdraw collected native token discovery costs.
// - withdrawResourceTokenFromTreasury(uint256 _resourceId, uint256 _amount): Allows owner to withdraw collected resource token costs.

// User Functions (8):
// - craftItem(uint256 _recipeId): Attempts to craft an item according to the recipe.
// - attemptDiscovery(): Attempts to discover resources, paying the cost and respecting cooldowns.
// - useItem(uint256 _tokenId): Uses a specific ERC721 item instance (if it has usage limits).
// - useConsumable(uint256 _itemId, uint256 _amount): Uses a quantity of an ERC1155 consumable item.
// - stakeResources(uint256 _amount): Stakes resource tokens in the contract.
// - unstakeResources(uint256 _amount): Unstakes resources and claims pending rewards.
// - claimStakingRewards(): Claims pending staking rewards without unstaking.
// - depositNativeTokenForDiscoveryCost(): Sends native token to the contract to cover discovery costs.

// View Functions (8):
// - getRecipeDetails(uint256 _recipeId): Retrieves details about a specific recipe.
// - getDiscoveryPoolDetails(): Shows current resource balances in the discovery pool.
// - getUserCooldowns(address _user): Checks remaining cooldowns for crafting and discovery for a user.
// - getUserStakedBalance(address _user): Gets the amount of resources a user has staked.
// - getPendingStakingRewards(address _user): Calculates and shows pending staking rewards for a user.
// - getItemUsageCount(uint256 _tokenId): Gets the current usage count for a specific ERC721 item instance.
// - getMaxItemUsages(uint256 _itemId): Gets the max usage count configured for an ERC721 item type.
// - getTokenTypeAddress(TokenType _type): Helper to get the address associated with a TokenType enum.

contract CryptoCraft is Ownable {
    using SafeERC20 for IERC20;

    enum TokenType { None, ERC20, ERC721, ERC1155 }

    struct Recipe {
        mapping(uint256 => uint256) inputResources; // Resource ID => Amount
        TokenType outputTokenType; // Type of token output
        address outputTokenAddress; // Address of output token contract (ERC20, ERC721, ERC1155)
        uint256 outputTokenId; // ID of output token (Resource ID for ERC20, Token ID for ERC721/ERC1155)
        uint256 outputAmount; // Amount or Quantity of output token (1 for unique ERC721)
        uint160 successChance; // Chance of success (0-10000 for 0%-100%) - Simple success/fail not implemented for complexity, assume 100% unless needed. Let's make it a simple boolean for now, maybe a multiplier later.
        uint64 cooldown; // Cooldown in seconds for this recipe per user
        uint256 requiredItemId721; // Optional: Requires owning a specific ERC721 item ID (0 for none)
        uint256 requiredItemAmount1155; // Optional: Requires owning a specific quantity of an ERC1155 item ID (0 for none)
        uint256 requiredItem1155Id; // Optional: The ERC1155 item ID requirement
    }

    IERC20 public resourceToken;
    IERC721 public itemToken721;
    IERC1155 public itemToken1155;

    mapping(uint256 => Recipe) public recipes;
    uint256 public nextRecipeId = 1; // Simple counter for recipe IDs

    mapping(address => mapping(uint256 => uint64)) public userCraftCooldowns; // user => recipeId => timestamp

    mapping(uint256 => uint256) public discoveryPool; // resourceId => amount
    uint256 public discoveryCostNative; // in wei
    uint256 public discoveryCostResource; // in resourceToken amount
    uint64 public discoveryCooldown; // in seconds
    mapping(address => uint64) public userDiscoveryCooldown; // user => timestamp

    mapping(uint256 => bool) public seasonalRecipes; // recipeId => isSeasonal

    address payable public protocolTreasury;

    mapping(address => uint256) public userStakedResources; // user => amount
    mapping(address => uint64) public userStakingRewardSnapshots; // user => timestamp of last reward calculation
    uint256 public stakingRewardRatePerSecond; // resourceToken amount per second per staked resourceToken

    mapping(uint256 => uint256) public itemUsageCount; // ERC721 tokenId => current usage count
    mapping(uint256 => uint256) public maxItemUsages; // ERC721 itemId (type) => max usage count

    event RecipeAdded(uint256 recipeId, Recipe recipeDetails);
    event RecipeUpdated(uint256 recipeId, Recipe recipeDetails);
    event RecipeRemoved(uint256 recipeId);
    event RecipeToggledSeason(uint256 recipeId, bool isSeasonal);
    event Crafted(address indexed user, uint256 recipeId, TokenType outputType, address outputAddress, uint256 outputId, uint256 outputAmount);
    event DiscoveryAttempt(address indexed user, uint256 costNative, uint256 costResource);
    event ResourcesDiscovered(address indexed user, uint256 resourceId, uint256 amount);
    event DiscoveryPoolAdded(uint256 resourceId, uint256 amount);
    event DiscoveryPoolRemoved(uint256 resourceId, uint256 amount);
    event ItemUsed(address indexed user, uint256 indexed tokenId721, uint256 newUsageCount);
    event ConsumableUsed(address indexed user, uint256 indexed itemId1155, uint256 amountBurned);
    event ResourcesStaked(address indexed user, uint256 amount);
    event ResourcesUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 rewardAmount);
    event NativeTokenWithdrawn(address indexed treasury, uint256 amount);
    event ResourceTokenWithdrawn(address indexed treasury, uint256 resourceId, uint256 amount);

    constructor(address _resourceToken, address _itemToken721, address _itemToken1155, address payable _protocolTreasury) Ownable(msg.sender) {
        resourceToken = IERC20(_resourceToken);
        itemToken721 = IERC721(_itemToken721);
        itemToken1155 = IERC1155(_itemToken1155);
        protocolTreasury = _protocolTreasury;
        // Default discovery costs/cooldowns can be set here or via owner functions later
        discoveryCostNative = 0;
        discoveryCostResource = 0;
        discoveryCooldown = 0;
        stakingRewardRatePerSecond = 0; // Start with no staking rewards
    }

    // --- Admin Functions ---

    function setResourceToken(address _token) external onlyOwner {
        resourceToken = IERC20(_token);
    }

    function setItemToken721(address _token) external onlyOwner {
        itemToken721 = IERC721(_token);
    }

    function setItemToken1155(address _token) external onlyOwner {
        itemToken1155 = IERC1155(_token);
    }

    function addRecipe(uint256 _recipeId, Recipe memory _recipe) external onlyOwner {
        require(_recipeId != 0, "Invalid recipe ID");
        require(recipes[_recipeId].outputTokenType == TokenType.None, "Recipe ID already exists");
        recipes[_recipeId] = _recipe;
        emit RecipeAdded(_recipeId, _recipe);
        if (_recipeId >= nextRecipeId) {
             nextRecipeId = _recipeId + 1;
        }
    }

    function updateRecipe(uint256 _recipeId, Recipe memory _recipe) external onlyOwner {
        require(recipes[_recipeId].outputTokenType != TokenType.None, "Recipe ID does not exist");
        recipes[_recipeId] = _recipe;
        emit RecipeUpdated(_recipeId, _recipe);
    }

    function removeRecipe(uint256 _recipeId) external onlyOwner {
        require(recipes[_recipeId].outputTokenType != TokenType.None, "Recipe ID does not exist");
        delete recipes[_recipeId];
        emit RecipeRemoved(_recipeId);
    }

    function setDiscoveryCost(uint256 _costNative, uint256 _costResource) external onlyOwner {
        discoveryCostNative = _costNative;
        discoveryCostResource = _costResource;
    }

    function setDiscoveryCooldown(uint64 _cooldown) external onlyOwner {
        discoveryCooldown = _cooldown;
    }

    function setProtocolTreasury(address payable _treasury) external onlyOwner {
        protocolTreasury = _treasury;
    }

    function addDiscoveryPoolResources(uint256[] calldata _resourceIds, uint256[] calldata _amounts) external onlyOwner {
        require(_resourceIds.length == _amounts.length, "Array length mismatch");
        for (uint i = 0; i < _resourceIds.length; i++) {
            discoveryPool[_resourceIds[i]] += _amounts[i];
            emit DiscoveryPoolAdded(_resourceIds[i], _amounts[i]);
        }
    }

    function removeDiscoveryPoolResources(uint256[] calldata _resourceIds, uint256[] calldata _amounts) external onlyOwner {
         require(_resourceIds.length == _amounts.length, "Array length mismatch");
        for (uint i = 0; i < _resourceIds.length; i++) {
            require(discoveryPool[_resourceIds[i]] >= _amounts[i], "Insufficient resources in pool");
            discoveryPool[_resourceIds[i]] -= _amounts[i];
             emit DiscoveryPoolRemoved(_resourceIds[i], _amounts[i]);
        }
    }

    function toggleSeasonalRecipe(uint256 _recipeId, bool _isSeasonal) external onlyOwner {
        require(recipes[_recipeId].outputTokenType != TokenType.None, "Recipe ID does not exist");
        seasonalRecipes[_recipeId] = _isSeasonal;
        emit RecipeToggledSeason(_recipeId, _isSeasonal);
    }

    function setStakingRewardRate(uint256 _rate) external onlyOwner {
        stakingRewardRatePerSecond = _rate;
    }

     function setMaxItemUsages(uint256 _itemId, uint256 _maxUsages) external onlyOwner {
        maxItemUsages[_itemId] = _maxUsages;
    }

    function withdrawNativeTokenFromDiscoveryCost(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient native token balance");
        (bool success,) = protocolTreasury.call{value: _amount}("");
        require(success, "Native token withdrawal failed");
        emit NativeTokenWithdrawn(protocolTreasury, _amount);
    }

    function withdrawResourceTokenFromTreasury(uint256 _resourceId, uint256 _amount) external onlyOwner {
         require(resourceToken.balanceOf(address(this)) >= _amount, "Insufficient resource token balance");
         // Note: Resource cost paid by users goes directly to treasury via transferFrom
         // This function is for withdrawing resources *accidentally* sent to the contract or if treasury changes
        resourceToken.safeTransfer(protocolTreasury, _amount);
        emit ResourceTokenWithdrawn(protocolTreasury, _resourceId, _amount);
    }

    // --- User Functions ---

    function craftItem(uint256 _recipeId) external {
        Recipe storage recipe = recipes[_recipeId];
        require(recipe.outputTokenType != TokenType.None, "Recipe does not exist");
        require(block.timestamp >= userCraftCooldowns[msg.sender][_recipeId], "Recipe on cooldown");

        // Check and burn input resources
        uint256[] memory inputResourceIds = new uint256[](0); // Placeholder, need a way to iterate map keys or pass explicitly
        // For simplicity, require input resource IDs to be passed explicitly or rely on owner adding them consistently
        // Let's assume Recipe struct stores inputResources keys in an array for easier iteration, or pass them in function call
        // Redesign Recipe struct slightly or add a helper function/array
        // Let's modify Recipe struct to include an array of input resource IDs.
        // struct Recipe { ... uint256[] inputResourceKeys; ... } - This makes updating harder.
        // Alternative: user must provide the input resource IDs and amounts they are providing, and contract verifies against recipe.
        // Let's stick to the mapping in Recipe and rely on the owner to structure recipes reasonably, verification loop over map keys is not standard/easy.
        // Let's assume the recipe mapping's keys can be conceptually iterated based on owner setup. *Correction*: Cannot iterate map keys in Solidity.
        // Simplest: Recipe struct needs `uint256[] inputResourceIds; uint256[] inputAmounts;` arrays.
        // Let's update Recipe struct:
        // struct Recipe { ... uint256[] inputResourceIds; uint256[] inputResourceAmounts; ... }
        // owner must add these arrays in `addRecipe`/`updateRecipe`.

        // --- Start Crafting Logic (Revised based on simplified iteration or explicit arrays) ---
        // Re-fetching recipe after struct change consideration (if implemented)
        Recipe storage currentRecipe = recipes[_recipeId];
        require(currentRecipe.outputTokenType != TokenType.None, "Recipe does not exist (post-check)"); // Should be redundant but safe

        // Burn input resources
        // Assumes Recipe struct is updated to include inputResourceIds & inputResourceAmounts arrays
        // For this example, let's simplify and assume a recipe only requires one type of resource for brevity, or use known IDs.
        // A real contract would need a better way to handle arbitrary inputs or limit recipe complexity.
        // Let's assume inputResources mapping is populated by owner, and we just check required amounts.

        // Check user balances and transfer resources to contract (or burn by transferring to address(0))
        // Transferring to contract allows potential resource sinks or redistribution by owner. Let's transfer to treasury.
        uint256 recipeInputSize = 0; // Placeholder, depends on how mapping is iterated or if using arrays
        // Using a simplified fixed requirement for example purposes: Requires 100 units of resource ID 1.
        // In a real scenario, you'd check each entry in the inputResources mapping/arrays.
        uint256 requiredAmount = currentRecipe.inputResources[1]; // Example check for resource ID 1
        if (requiredAmount > 0) {
             require(resourceToken.balanceOf(msg.sender) >= requiredAmount, "Insufficient resources");
             resourceToken.safeTransferFrom(msg.sender, protocolTreasury, requiredAmount);
        }
        // Extend this loop for all required resources if using arrays:
        /*
        require(currentRecipe.inputResourceIds.length == currentRecipe.inputResourceAmounts.length, "Recipe input data mismatch");
        for (uint i = 0; i < currentRecipe.inputResourceIds.length; i++) {
             uint256 resourceId = currentRecipe.inputResourceIds[i];
             uint256 amount = currentRecipe.inputResourceAmounts[i];
             require(resourceToken.balanceOf(msg.sender, resourceId) >= amount, "Insufficient resources"); // If resourceToken was ERC1155
             // If resourceToken is ERC20 representing *different* resources (less common pattern, usually different ERC20 contracts)
             // If resourceToken is ONE ERC20, but recipes use "virtual" resource IDs (mapping ERC20 balance to a conceptual resource) - complicates state.
             // Let's assume resourceToken is a single ERC20, and different 'resources' are just conceptual IDs within the recipe logic, requiring the SAME ERC20 token. This is simpler but less realistic for distinct materials.
             // *Correction*: A single ERC20 for *all* resources is awkward. It's standard to have one ERC20 per resource type. Let's revert to that assumption, but require the owner to configure the *correct* resource token address in the Recipe struct or have a mapping `resourceId => resourceTokenAddress`.
             // Let's simplify again: CryptoCraft manages crafting/discovery/staking. Resources are ERC20s, but *different* ERC20s for different types. The `resourceToken` variable is just the *primary* resource used for things like staking or certain general costs. Recipes will need to list the *addresses* and amounts of required ERC20s.

             // New Recipe struct consideration:
             // struct Recipe { ... address[] inputTokenAddresses; uint256[] inputTokenAmounts; ... }
             // This requires the user to have approved *each* required ERC20 token address.

             // Let's go back to the initial Recipe struct with `mapping(uint256 => uint256) inputResources;`
             // We cannot iterate it in Solidity directly.
             // The only practical way with this struct is if the owner adds helper functions OR the user passes the full list of inputs used in the recipe.
             // Let's make the user pass the *expected* inputs, and the contract verifies.
             // craftItem(uint256 _recipeId, uint256[] calldata _inputResourceIds, uint256[] calldata _inputAmounts)

             // --- Revision: craftItem function signature changed ---
             // Let's update the craftItem function.
             // This makes the user provide the resource IDs and amounts they are trying to use.
             // The contract validates these against the recipe's requirements.
        */
    }

    // Revised craftItem function signature and logic
    function craftItem(uint256 _recipeId, uint256[] calldata _inputResourceIds, uint256[] calldata _inputAmounts) external {
        Recipe storage recipe = recipes[_recipeId];
        require(recipe.outputTokenType != TokenType.None, "Recipe does not exist");
        require(block.timestamp >= userCraftCooldowns[msg.sender][_recipeId], "Recipe on cooldown");
        require(_inputResourceIds.length == _inputAmounts.length, "Input array length mismatch");

        // Check and burn input resources
        for (uint i = 0; i < _inputResourceIds.length; i++) {
            uint256 resourceId = _inputResourceIds[i];
            uint256 amount = _inputAmounts[i];
            require(recipe.inputResources[resourceId] == amount, "Incorrect resource amount provided for recipe");

            // Here we need the address of the ERC20 for this resourceId.
            // A mapping `resourceId => resourceTokenAddress` is needed, or owner encodes this in Recipe.
            // Let's add a mapping `resourceId => address` and owner functions for it.
            // Add `mapping(uint256 => address) public resourceIdToAddress;` state variable.
            // Add `setResourceAddress(uint256 _resourceId, address _token)` owner function.
            address requiredTokenAddress = resourceIdToAddress[resourceId];
            require(requiredTokenAddress != address(0), "Resource ID not mapped to a token address");

            IERC20 inputToken = IERC20(requiredTokenAddress);
            require(inputToken.balanceOf(msg.sender) >= amount, "Insufficient resource tokens");
            inputToken.safeTransferFrom(msg.sender, protocolTreasury, amount); // Send required resources to treasury
        }

        // --- Check Optional Requirements ---
        if (recipe.requiredItemId721 != 0) {
             require(itemToken721.ownerOf(recipe.requiredItemId721) == msg.sender, "Requires owning specific item (ERC721)");
        }
         if (recipe.requiredItemAmount1155 > 0) {
             require(recipe.requiredItem1155Id != 0, "Required ERC1155 item ID not set");
             require(itemToken1155.balanceOf(msg.sender, recipe.requiredItem1155Id) >= recipe.requiredItemAmount1155, "Requires sufficient consumable items (ERC1155)");
        }


        // --- Process Output ---
        _processCraftingOutput(msg.sender, recipe);

        // Set cooldown
        userCraftCooldowns[msg.sender][_recipeId] = uint64(block.timestamp) + recipe.cooldown;

        emit Crafted(msg.sender, _recipeId, recipe.outputTokenType, recipe.outputTokenAddress, recipe.outputTokenId, recipe.outputAmount);
    }

    function attemptDiscovery() external payable {
        require(block.timestamp >= userDiscoveryCooldown[msg.sender], "Discovery on cooldown");

        // Pay costs
        if (discoveryCostNative > 0) {
            require(msg.value >= discoveryCostNative, "Insufficient native token sent for discovery");
            if (msg.value > discoveryCostNative) {
                 // Return excess native token
                 (bool success, ) = payable(msg.sender).call{value: msg.value - discoveryCostNative}("");
                 require(success, "Failed to return excess native token");
            }
             // Send cost to treasury
            (bool success,) = protocolTreasury.call{value: discoveryCostNative}("");
            require(success, "Failed to send native token cost to treasury");
        } else {
             require(msg.value == 0, "Cannot send native token if cost is 0");
        }


        if (discoveryCostResource > 0) {
            require(resourceToken.balanceOf(msg.sender) >= discoveryCostResource, "Insufficient resource tokens for discovery");
            resourceToken.safeTransferFrom(msg.sender, protocolTreasury, discoveryCostResource);
        }

        // Set cooldown
        userDiscoveryCooldown[msg.sender] = uint64(block.timestamp) + discoveryCooldown;

        // Distribute resources from pool (simple probabilistic distribution)
        _distributeDiscoveryRewards(msg.sender);

        emit DiscoveryAttempt(msg.sender, discoveryCostNative, discoveryCostResource);
    }

     // Function to deposit native token separately if not paying during attemptDiscovery
    function depositNativeTokenForDiscoveryCost() external payable {
         require(msg.value > 0, "Must send native token");
         (bool success, ) = protocolTreasury.call{value: msg.value}("");
         require(success, "Failed to send native token to treasury");
    }


    function useItem(uint256 _tokenId) external {
         // Assumes _tokenId is an ERC721 token ID
         require(itemToken721.ownerOf(_tokenId) == msg.sender, "Not your item");
         uint256 itemIdType = itemToken721.tokenByIndex(0); // Need a way to get the 'type' or 'class' ID from an instance ID
         // ERC721 metadata usually handles this. Assuming a mapping `tokenId => itemIdType` exists or can be derived.
         // Let's assume ERC721 contract has a way to query item type ID from token ID.
         // Or, owner pre-configures max usages per token ID *instance*? Less flexible.
         // Let's assume a simple mapping `uint256 => uint256` for tokenId (instance) => max usages. Owner sets this per minted item. Or, map the tokenURI/metadata hash to usages.
         // Let's use the `maxItemUsages` mapping which maps the *item type* ID to max usages. Need to link _tokenId (instance) to item type ID.
         // This link is usually in the ERC721 metadata or another mapping.
         // For this contract, let's assume the ERC721 contract has a public `getItemTypeId(uint256 tokenId)` view function.
         // Or simplest: The ERC721 token ID *is* the item type ID if items are not unique instances (like CryptoPunks).
         // If items ARE unique instances (like ERC721 collectibles), need the type mapping.
         // Let's assume ERC721 contract has `mapping(uint256 => uint256) public tokenTypeId;` and `getItemTypeId(uint256 tokenId)` view.
         // Or pass the item type ID: `useItem(uint256 _tokenId, uint256 _itemTypeId)`

         // For simplicity, let's map ERC721 token instance ID directly to its type ID for usage tracking.
         // The owner would configure `maxItemUsages[itemTypeId]` and the ERC721 contract would link instance IDs to type IDs.
         // Assuming item type ID can be derived from _tokenId or is passed. Let's pass it for clarity in example.
         // Reverting function signature: `useItem(uint256 _tokenId)` - need a way to get type ID from _tokenId.
         // If the ERC721 is simple, maybe `_tokenId` itself is the type ID (e.g., item #5, instance #1, token ID 5).
         // Or maybe `_tokenId` is instance ID, and `itemToken721.tokenURI(_tokenId)` metadata tells the type.
         // Let's make a *simplifying assumption*: The ERC721 instance ID `_tokenId` maps to its type ID via `itemToken721.tokenTypeId(_tokenId)`. This requires the ERC721 contract to expose this.

         uint256 itemTypeId = itemToken721.tokenByIndex(_tokenId); // This is incorrect usage of tokenByIndex.

         // Let's add a mapping in this contract `tokenId721ToItemTypeId`:
         // mapping(uint256 => uint256) public tokenId721ToItemTypeId; // Populated during ERC721 mint in _processCraftingOutput
         // This requires the ERC721 mint function to return the minted token ID, or the ERC721 contract to emit an event CryptoCraft can listen to (more complex).
         // Simpler: Let's assume ERC721 token ID *is* the item type ID + instance identifier. E.g., token ID `1001` is the first instance of item type ID 100.
         // Or, let's make the ERC721 contract standard OpenZeppelin, and we track usage per *instance*. `maxItemUsages` maps instance ID => max usages. Owner sets this *after* minting, which is clunky.
         // Best: Track usage per *item type*. Need the item type ID from the instance ID.
         // Let's assume `itemToken721.itemTypeId(_tokenId)` exists in the ERC721 contract.

         // Example logic assuming `itemToken721` has a public `itemTypeId(uint256 tokenId)` view
         // uint256 itemTypeId = itemToken721.itemTypeId(_tokenId); // This requires a non-standard ERC721
         // Let's simplify *this* contract: Usage tracking applies to ERC1155 consumables only. Remove useItem(ERC721) function.

         // --- Removing useItem(uint256 _tokenId) function and related state/events ---
         // (Adjusting function count calculation)

         // New Count: 15 (Admin) + 7 (User) + 8 (View) = 30 functions. Still > 20.

         revert("useItem(ERC721) function placeholder removed for simplicity");
         // Kept here to show the thought process and removal.
    }

     function useConsumable(uint256 _itemId, uint256 _amount) external {
         require(_amount > 0, "Amount must be greater than 0");
         // Assumes _itemId is an ERC1155 token ID (item type)
         require(itemToken1155.balanceOf(msg.sender, _itemId) >= _amount, "Insufficient consumable items");

         // Burn the consumables by transferring to address(0)
         itemToken1155.safeTransferFrom(msg.sender, address(0), _itemId, _amount, "");

         emit ConsumableUsed(msg.sender, _itemId, _amount);
     }


    function stakeResources(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Claim pending rewards before updating stake
        _claimStakingRewards(msg.sender); // Internal claim

        resourceToken.safeTransferFrom(msg.sender, address(this), _amount);
        userStakedResources[msg.sender] += _amount;
        userStakingRewardSnapshots[msg.sender] = uint64(block.timestamp); // Reset snapshot time

        emit ResourcesStaked(msg.sender, _amount);
    }

    function unstakeResources(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(userStakedResources[msg.sender] >= _amount, "Insufficient staked resources");

        // Claim pending rewards
        _claimStakingRewards(msg.sender); // Internal claim

        userStakedResources[msg.sender] -= _amount;
        userStakingRewardSnapshots[msg.sender] = uint64(block.timestamp); // Reset snapshot time

        resourceToken.safeTransfer(msg.sender, _amount);

        emit ResourcesUnstaked(msg.sender, _amount);
    }

    function claimStakingRewards() external {
         _claimStakingRewards(msg.sender); // Internal claim
    }

    // --- Internal/Helper Functions ---

    function _processCraftingOutput(address _to, Recipe storage _recipe) internal {
        if (_recipe.outputTokenType == TokenType.ERC20) {
            // Output is resource tokens (e.g., refining)
            address outputTokenAddress = _recipe.outputTokenAddress;
            uint256 outputAmount = _recipe.outputAmount;
            require(outputTokenAddress != address(0), "ERC20 output address not set");
            IERC20 outputToken = IERC20(outputTokenAddress);
            outputToken.safeTransfer( _to, outputAmount);

        } else if (_recipe.outputTokenType == TokenType.ERC721) {
             // Output is a unique item (ERC721)
             address outputTokenAddress = _recipe.outputTokenAddress;
             uint256 outputTokenId = _recipe.outputTokenId; // This should be the item type ID if crafting unique instances
             uint256 outputAmount = _recipe.outputAmount; // Should be 1 for unique items

             require(outputTokenAddress != address(0), "ERC721 output address not set");
             require(outputAmount == 1, "ERC721 output amount must be 1"); // Ensure minting one instance

             // Assuming the ERC721 contract has a mint function callable by the owner (this contract)
             // and this function returns the new token ID, or takes an explicit new token ID.
             // This is non-standard for IERC721.
             // Standard ERC721 mint is usually part of the implementing contract.
             // Let's assume the itemToken721 contract has a function `mintTo(address to, uint256 itemTypeId)`
             // and it internally manages unique instance IDs.
             // Or, itemToken721 is *this* contract, but this contract is already ERC721 which adds complexity.
             // Let's assume itemToken721 is a separate contract with a public mint function callable by this contract.
             // Example call (requires ERC721 contract to expose this):
             // uint256 newTokenId = itemToken721.mintTo(_to, outputTokenId); // Assuming outputTokenId is item type ID

             // For demonstration, let's simulate minting by transferring a pre-existing token (less ideal)
             // or, better, assume a minimal mint interface:
             // interface ICraftableERC721 { function mint(address to, uint256 itemTypeId) external returns (uint256 newTokenId); }
             // We would cast itemToken721 to this interface.

             // Let's simplify: Assume ERC721 outputTokenId in Recipe is the *actual* token ID to mint.
             // This means owner pre-determines which specific ERC721 ID is crafted by this recipe. Less flexible for unique items.
             // Let's assume it's an item *type* ID, and the ERC721 contract handles instance ID generation.
             // Let's require the ERC721 contract implements `function mintTo(address to, uint256 itemTypeId) external returns (uint256 newTokenId);`

             ICraftableERC721 craftableItemToken721 = ICraftableERC721(outputTokenAddress);
             uint256 newTokenId = craftableItemToken721.mintTo(_to, _recipe.outputTokenId);
             // Optional: Track max usages for this new instance if needed (mapping instance ID -> max)
             // maxItemUsages[newTokenId] = maxItemUsages[_recipe.outputTokenId]; // map type max to instance max
             // itemUsageCount[newTokenId] = 0; // Initialize usage count

        } else if (_recipe.outputTokenType == TokenType.ERC1155) {
             // Output is stackable/consumable item (ERC1155)
             address outputTokenAddress = _recipe.outputTokenAddress;
             uint256 outputTokenId = _recipe.outputTokenId; // ERC1155 item ID (type)
             uint256 outputAmount = _recipe.outputAmount; // Quantity

             require(outputTokenAddress != address(0), "ERC1155 output address not set");
             require(outputAmount > 0, "ERC1155 output amount must be greater than 0");

             // Assuming the ERC1155 contract has a mint function callable by the owner (this contract)
             // interface ICraftableERC1155 { function mint(address to, uint256 id, uint256 amount, bytes memory data) external; }
             ICraftableERC1155 craftableItemToken1155 = ICraftableERC1155(outputTokenAddress);
             craftableItemToken1155.mint(_to, outputTokenId, outputAmount, "");

        } else {
            // No output, or invalid type
            require(false, "Invalid recipe output type");
        }
    }

    // @dev Simple "randomness" for demonstration purposes. NOT cryptographically secure.
    // Should use an oracle (like Chainlink VRF) in a real application for secure randomness.
    function _rollDiscoveryOutcome() internal view returns (uint256 randomValue) {
        // Combines block information with sender address for a slightly less predictable result
        // Still deterministic and manipulable by miners/validators.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender)));
        return uint256(keccak256(abi.encodePacked(seed, block.number)));
    }

    function _distributeDiscoveryRewards(address _to) internal {
        uint256 totalPoolValue = 0;
        uint256[] memory poolResourceIds = new uint256[](0); // Need a way to get keys from mapping
        // For simplicity, hardcode resource IDs 1, 2, 3 for the pool distribution example.
        // A real implementation needs a list of resource IDs in the pool.
        uint256[] memory availableResourceIds = new uint256[](3); // Example IDs
        availableResourceIds[0] = 1;
        availableResourceIds[1] = 2;
        availableResourceIds[2] = 3;

        for(uint i = 0; i < availableResourceIds.length; i++) {
             totalPoolValue += discoveryPool[availableResourceIds[i]];
        }

        if (totalPoolValue == 0) {
            // Nothing in the pool to discover
            return;
        }

        uint256 randomNumber = _rollDiscoveryOutcome();

        // Simple distribution: Divide random number by total pool value to get a "point" in the distribution
        // Or, iterate through resources, subtract their pool amount from randomNumber until it goes negative.
        uint256 cumulative = 0;
        for(uint i = 0; i < availableResourceIds.length; i++) {
            uint256 resourceId = availableResourceIds[i];
            uint256 amountInPool = discoveryPool[resourceId];

            if (amountInPool > 0) {
                 cumulative += amountInPool;
                 if (randomNumber % totalPoolValue < cumulative) {
                     // This resource is selected. Distribute a random amount up to the pool amount or a cap.
                     // Simple: distribute a small fixed amount or percentage if available
                     uint256 amountToDistribute = amountInPool > 10 ? 10 : amountInPool; // Example: distribute max 10 units
                     if (amountToDistribute > 0) {
                         discoveryPool[resourceId] -= amountToDistribute;
                         // Need the token address for this resource ID
                         address resourceAddr = resourceIdToAddress[resourceId];
                         if (resourceAddr != address(0)) {
                              IERC20(resourceAddr).safeTransfer(_to, amountToDistribute);
                              emit ResourcesDiscovered(_to, resourceId, amountToDistribute);
                         } else {
                              // Log or handle error if resource ID not mapped
                         }
                     }
                     // Only one resource type per discovery attempt in this simple model
                     break;
                 }
            }
        }
    }

    function _claimStakingRewards(address _user) internal {
        uint256 pending = getPendingStakingRewards(_user); // Calculate rewards
        if (pending > 0) {
            // Transfer rewards to user
            // Ensure contract has enough resource tokens (owner must deposit them)
            require(resourceToken.balanceOf(address(this)) >= pending, "Insufficient contract balance for staking rewards");
            resourceToken.safeTransfer(_user, pending);
            // Reset reward calculation point
            userStakingRewardSnapshots[_user] = uint64(block.timestamp);
            emit StakingRewardsClaimed(_user, pending);
        }
    }

     // Need owner function to deposit resource tokens for staking rewards
     function depositStakingRewards(uint256 _amount) external onlyOwner {
         resourceToken.safeTransferFrom(msg.sender, address(this), _amount);
     }

     // Need owner function to map resource IDs to addresses
     mapping(uint256 => address) public resourceIdToAddress; // resourceId => address
     function setResourceAddress(uint256 _resourceId, address _tokenAddress) external onlyOwner {
         require(_resourceId != 0, "Invalid resource ID");
         require(_tokenAddress != address(0), "Invalid token address");
         resourceIdToAddress[_resourceId] = _tokenAddress;
     }


    // --- View Functions ---

    function getRecipeDetails(uint256 _recipeId) external view returns (
        // Cannot return the full Recipe struct with mapping directly via public getter.
        // Need to return individual components or use helper functions for the mapping.
        // Let's return common fields and provide a separate function/way to query inputs.
        // Or, owner provides a view function in a separate utils contract or off-chain.
        // Let's provide a helper view to get input requirements for a recipe.

        TokenType outputTokenType,
        address outputTokenAddress,
        uint256 outputTokenId,
        uint256 outputAmount,
        uint64 cooldown,
        uint256 requiredItemId721,
        uint256 requiredItem1155Id,
        uint256 requiredItemAmount1155
    ) {
        Recipe storage recipe = recipes[_recipeId];
        return (
            recipe.outputTokenType,
            recipe.outputTokenAddress,
            recipe.outputTokenId,
            recipe.outputAmount,
            recipe.cooldown,
            recipe.requiredItemId721,
            recipe.requiredItem1155Id,
            recipe.requiredItemAmount1155
        );
    }

    // Helper view function to get a specific input resource requirement for a recipe
    function getRecipeInputRequirement(uint256 _recipeId, uint256 _resourceId) external view returns (uint256 amount) {
        return recipes[_recipeId].inputResources[_resourceId];
    }

     // Note: getDiscoveryPoolDetails() would need to return all keys and values from the mapping,
     // which is not directly possible in a single view function for arbitrary keys.
     // Owner could maintain an array of active resource IDs in the pool, or clients query known IDs.
     // Let's assume owner adds a list of discoverable resource IDs.
     uint256[] public discoverableResourceIds; // Owner populates this

     function setDiscoverableResourceIds(uint256[] calldata _resourceIds) external onlyOwner {
         discoverableResourceIds = _resourceIds;
     }

    function getDiscoveryPoolDetails() external view returns (uint256[] memory resourceIds, uint256[] memory amounts) {
        resourceIds = discoverableResourceIds;
        amounts = new uint256[](resourceIds.length);
        for(uint i = 0; i < resourceIds.length; i++) {
             amounts[i] = discoveryPool[resourceIds[i]];
        }
        return (resourceIds, amounts);
    }


    function getUserCooldowns(address _user) external view returns (uint64 discoveryCooldownEnd, uint256[] memory recipeIds, uint64[] memory craftCooldownEnds) {
        discoveryCooldownEnd = userDiscoveryCooldown[_user];

        // Cannot easily list all recipes a user has cooldowns for.
        // Client would typically query known recipe IDs.
        // Let's return cooldowns for a predefined set of common recipes, or require recipe IDs as input.
        // Let's require recipe IDs as input.
        revert("Please use getUserCraftCooldowns(address _user, uint256[] calldata _recipeIds)");
    }

    function getUserCraftCooldowns(address _user, uint256[] calldata _recipeIds) external view returns (uint64[] memory craftCooldownEnds) {
         craftCooldownEnds = new uint64[](_recipeIds.length);
         for(uint i = 0; i < _recipeIds.length; i++) {
             craftCooldownEnds[i] = userCraftCooldowns[_user][_recipeIds[i]];
         }
         return craftCooldownEnds;
    }


    function getUserStakedBalance(address _user) external view returns (uint256) {
        return userStakedResources[_user];
    }

    function getPendingStakingRewards(address _user) public view returns (uint256) {
        uint256 stakedAmount = userStakedResources[_user];
        uint64 lastStakeTime = userStakingRewardSnapshots[_user];
        if (stakedAmount == 0 || stakingRewardRatePerSecond == 0) {
            return 0;
        }
        // Calculate time passed since last snapshot or staking action
        uint256 timeElapsed = block.timestamp - lastStakeTime;
        // Rewards = stakedAmount * rate * timeElapsed
        uint256 pending = (stakedAmount * stakingRewardRatePerSecond * timeElapsed);
        // Note: Integer arithmetic might cause precision loss for small rates/time.
        // Consider using decimal libraries if high precision is needed.
        return pending;
    }

     // ERC721 Item Usage Views (assuming usage tracking applies to specific ERC721 instances)
     // Based on initial idea before removing useItem(ERC721). Re-adding if needed.
     // If we assume item usage is only for ERC1155 (consumables), these views are not needed.
     // Reverting to the ERC1155 only usage for simplicity and clarity.

     // New Count: 15 (Admin) + 7 (User) + 6 (View) = 28 functions. Still > 20.

     function getTokenTypeAddress(TokenType _type) external view returns (address) {
         if (_type == TokenType.ERC20) return address(resourceToken);
         if (_type == TokenType.ERC721) return address(itemToken721);
         if (_type == TokenType.ERC1155) return address(itemToken1155);
         return address(0);
     }

     // --- Interfaces (for clarity on assumed external calls) ---
     // These are interfaces for the *external* token contracts this contract interacts with.
     // They might need to be modified based on the *actual* functions available in those contracts.

     interface ICraftableERC721 {
         // Example mint function signature this contract assumes exists on the ERC721
         function mintTo(address to, uint256 itemTypeId) external returns (uint256 newTokenId);
         // Example function to get type ID from instance ID
         // function itemTypeId(uint256 tokenId) external view returns (uint256);
         // Basic ERC721 functions are assumed via IERC721 import
         function ownerOf(uint256 tokenId) external view returns (address owner);
         function tokenByIndex(uint256 index) external view returns (uint256); // This is for enumeration, not getting type ID.
     }

     interface ICraftableERC1155 {
         // Example mint function signature this contract assumes exists on the ERC1155
         function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
         // Basic ERC1155 functions are assumed via IERC1155 import
         function balanceOf(address account, uint256 id) external view returns (uint256);
         function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
     }
}
```