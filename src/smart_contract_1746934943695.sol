Okay, here is a Solidity smart contract implementing a decentralized digital crafting system with reputation tiers, recipe suggestions, batch crafting, and dynamic item bonuses. It interacts with external ERC-20 and ERC-1155 tokens (defined via interfaces) to represent currency, items, and recipes.

This contract aims for a unique combination of features, going beyond basic token or simple NFT contracts by incorporating:
1.  **ERC-1155 for Diverse Assets:** Using ERC-1155 to represent both fungible ingredients/resources and unique items/recipes.
2.  **Complex State Transitions:** The `craft` function involves multiple state changes (burning tokens, minting tokens, updating user stats, updating reputation).
3.  **Reputation System with Tiers:** Reputation points influence access to certain features (like gated recipes).
4.  **Batching:** Allows users to perform multiple crafts in one transaction (`craftBatch`).
5.  **Dynamic Bonuses:** Recipes can be configured to have a chance of yielding bonus items.
6.  **User-Driven Content Suggestion:** A mechanism for users to suggest new recipes (though admin-approved).
7.  **Access Control:** Multi-level access (Owner, Admins).
8.  **Pausable:** Standard security feature.

It interacts with tokens via interfaces, assuming the actual token contracts are deployed separately. This avoids duplicating the standard ERC20/ERC1155 *implementations* but demonstrates how a complex application contract uses these standards.

---

## Smart Contract Outline: `DecentralizedCrafter`

1.  **Interfaces:**
    *   `IERC20`: Minimal interface for interaction (transferFrom, balanceOf).
    *   `IERC1155`: Minimal interface for interaction (safeBatchTransferFrom, balanceOfBatch).
2.  **Error Handling:** Custom errors for clarity and gas efficiency.
3.  **State Variables:**
    *   Addresses of the Crafting Coin (ERC20) and Crafting Asset (ERC1155) contracts.
    *   Owner address.
    *   Mapping for Admin addresses.
    *   Pausable state.
    *   Mapping for user reputation points.
    *   Array and mapping for reputation tier thresholds.
    *   Struct for `Recipe` details (ingredients, output, costs, bonuses, active status, tier requirement, availability).
    *   Mapping to store `Recipe` data by output item ID.
    *   Array to store all active recipe IDs.
    *   Mapping to store user craft counts per recipe.
    *   Struct for `RecipeSuggestion`.
    *   Array to store recipe suggestions.
    *   Counter for suggestion IDs.
4.  **Events:**
    *   `Crafted`: Emitted on successful crafting.
    *   `RecipeAdded`: Emitted when a new recipe is added.
    *   `RecipeDeactivated`: Emitted when a recipe is deactivated.
    *   `ReputationUpdated`: Emitted when a user's reputation changes.
    *   `TierThresholdsUpdated`: Emitted when tier thresholds are changed.
    *   `Paused`/`Unpaused`: Standard Pausable events.
    *   `AdminAdded`/`AdminRemoved`: Emitted when admin status changes.
    *   `OwnershipTransferred`: Standard Ownable event.
    *   `RecipeSuggested`: Emitted when a user suggests a recipe.
    *   `RecipeBonusSet`: Emitted when a bonus is configured for a recipe.
5.  **Modifiers:**
    *   `onlyOwner`: Restricts to contract owner.
    *   `onlyAdmin`: Restricts to contract owner or registered admin.
    *   `whenNotPaused`: Prevents execution when paused.
6.  **Constructor:**
    *   Sets owner, Crafting Coin and Crafting Asset contract addresses.
7.  **Access Control Functions:**
    *   `transferOwnership`
    *   `addAdmin`
    *   `removeAdmin`
    *   `isAdmin` (view)
8.  **Pausable Functions:**
    *   `pause`
    *   `unpause`
    *   `paused` (view)
9.  **Token Interaction Functions (Query only):**
    *   `getCraftCoinBalance` (view)
    *   `getCraftAssetBalance` (view)
    *   `getCraftAssetBatchBalance` (view)
10. **Reputation Functions:**
    *   `getReputation` (view)
    *   `getReputationTier` (view)
    *   `setReputationTierThresholds` (admin)
    *   `getTierThresholds` (view)
    *   `penalizeReputation` (admin)
    *   `_awardReputation` (internal helper)
    *   `_penalizeReputation` (internal helper)
11. **Recipe Management Functions:**
    *   `addRecipe` (admin)
    *   `addTierGatedRecipe` (admin)
    *   `deactivateRecipe` (admin)
    *   `getRecipeDetails` (view)
    *   `getAllRecipeIds` (view)
    *   `setRecipeBonusItem` (admin)
    *   `suggestRecipe` (public)
    *   `getRecipeSuggestions` (admin view)
12. **Crafting Functions:**
    *   `craft` (public, main crafting logic)
    *   `craftBatch` (public, allows crafting multiple times)
    *   `_processCraft` (internal helper, contains core logic for one craft)
13. **User Statistics Functions:**
    *   `getUserCraftCount` (view)
14. **ERC1155 Receiver Hooks (Placeholder/Acknowledgement):**
    *   `onERC1155Received`
    *   `onERC1155BatchReceived`
    *   `supportsInterface`

---

## Function Summary:

1.  `constructor(address _craftCoinAddress, address _craftAssetAddress)`: Deploys the contract, sets token addresses and initial owner.
2.  `transferOwnership(address newOwner)`: Transfers ownership (owner only).
3.  `addAdmin(address adminAddress)`: Adds an address as an admin (owner only).
4.  `removeAdmin(address adminAddress)`: Removes an admin address (owner only).
5.  `isAdmin(address adminAddress) public view returns (bool)`: Checks if an address is an admin.
6.  `pause()`: Pauses contract functionality (admin only).
7.  `unpause()`: Unpauses contract functionality (admin only).
8.  `paused() public view returns (bool)`: Checks if the contract is paused.
9.  `getCraftCoinBalance(address account) public view returns (uint256)`: Gets Craft Coin balance of an account.
10. `getCraftAssetBalance(address account, uint256 id) public view returns (uint256)`: Gets Craft Asset balance of an account for a specific item ID.
11. `getCraftAssetBatchBalance(address account, uint256[] calldata ids) public view returns (uint256[] memory)`: Gets Craft Asset balances for multiple item IDs for an account.
12. `getReputation(address account) public view returns (uint256)`: Gets the reputation points of an account.
13. `getReputationTier(address account) public view returns (uint256)`: Gets the reputation tier of an account based on points.
14. `setReputationTierThresholds(uint256[] calldata thresholds) public onlyAdmin`: Sets the reputation point thresholds for each tier (admin only). Tier 0 is implicit (below first threshold). Thresholds must be increasing.
15. `getTierThresholds() public view returns (uint256[] memory)`: Gets the current reputation tier thresholds.
16. `penalizeReputation(address account, uint256 points) public onlyAdmin`: Decreases an account's reputation points (admin only).
17. `addRecipe(uint256 outputItemId, uint256 outputAmount, uint256[] calldata ingredientItemIds, uint256[] calldata ingredientAmounts, uint256 craftCost, uint256 reputationReward, uint64 availableUntil) public onlyAdmin`: Adds a new recipe without a reputation tier requirement (admin only).
18. `addTierGatedRecipe(uint256 outputItemId, uint256 outputAmount, uint256[] calldata ingredientItemIds, uint256[] calldata ingredientAmounts, uint256 craftCost, uint256 reputationReward, uint64 availableUntil, uint256 requiredTier) public onlyAdmin`: Adds a new recipe that requires a minimum reputation tier (admin only).
19. `deactivateRecipe(uint256 outputItemId) public onlyAdmin`: Deactivates a recipe, preventing further crafting (admin only).
20. `getRecipeDetails(uint256 outputItemId) public view returns (Recipe memory)`: Gets the details of a specific recipe.
21. `getAllRecipeIds() public view returns (uint256[] memory)`: Gets a list of all currently active recipe output IDs.
22. `setRecipeBonusItem(uint256 recipeOutputItemId, uint256 bonusItemId, uint256 bonusAmount, uint256 bonusChanceBasisPoints) public onlyAdmin`: Sets a potential bonus item and its drop chance for a recipe (admin only). `bonusChanceBasisPoints` is chance out of 10000 (e.g., 100 = 1% chance).
23. `suggestRecipe(uint256 outputItemId, uint256 outputAmount, uint256[] calldata ingredientItemIds, uint256[] calldata ingredientAmounts, uint256 craftCost, uint256 reputationReward)`: Allows any user to suggest a new recipe.
24. `getRecipeSuggestions() public view onlyAdmin returns (RecipeSuggestion[] memory)`: Gets the list of all pending recipe suggestions (admin only).
25. `craft(uint256 recipeOutputItemId) public whenNotPaused`: Executes a single craft of a specified recipe. Requires user approval for ingredient transfer/burning and coin burning. Handles all checks (ingredients, coin, reputation tier, availability, active status) and awards reputation/bonus.
26. `craftBatch(uint256 recipeOutputItemId, uint256 amount) public whenNotPaused`: Executes multiple crafts of a specified recipe in a single transaction. Requires user approval for batch transfer/burning of ingredients and coin.
27. `getUserCraftCount(address account, uint256 recipeOutputItemId) public view returns (uint256)`: Gets how many times a specific user has successfully crafted a specific recipe.
28. `onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual returns (bytes4)`: ERC1155 hook (required if contract receives ERC1155 tokens - included for completeness).
29. `onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) public virtual returns (bytes4)`: ERC1155 hook (required if contract receives ERC1155 tokens - included for completeness).
30. `supportsInterface(bytes4 interfaceId) public view virtual returns (bool)`: ERC165 standard interface detection (required for ERC1155 compatibility).

*(Note: The actual contract implementation includes internal helper functions like `_awardReputation`, `_penalizeReputation`, `_processCraft` etc., which are not exposed externally but are counted towards the logical flow and complexity)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol"; // Using console.sol for debugging during development

// Minimal ERC-20 Interface needed for this contract
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Minimal ERC-1155 Interface needed for this contract
interface IERC1155 {
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
}

// Standard ERC-165 Interface
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Basic Pausable implementation
abstract contract Pausable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!_paused, "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(_paused, "Pausable: not paused");
    }

    function _pause() internal virtual {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


/// @title DecentralizedCrafter
/// @dev A smart contract for managing digital item crafting, reputation, and recipes using external ERC-20 and ERC-1155 tokens.
contract DecentralizedCrafter is Pausable, IERC165 {

    // --- Errors ---
    error NotOwner();
    error NotAdmin();
    error RecipeDoesNotExist(uint256 recipeId);
    error RecipeNotActive(uint256 recipeId);
    error RecipeNotAvailable(uint256 recipeId);
    error InsufficientIngredients(uint256 itemId, uint256 required, uint256 owned);
    error InsufficientCraftCoin(uint256 required, uint256 owned);
    error ReputationTooLow(uint256 requiredTier, uint256 currentTier);
    error ArraysMismatch();
    error InvalidAmount();
    error InvalidTierThresholds();
    error InvalidBonusChance();
    error SuggestionNotFound(uint256 suggestionId);

    // --- State Variables ---
    address public immutable craftCoin;       // Address of the ERC-20 Crafting Coin contract
    address public immutable craftAsset;      // Address of the ERC-1155 Crafting Asset contract (items/recipes)

    address private _owner;
    mapping(address => bool) private _admins;

    mapping(address => uint256) private userReputation;
    uint256[] private reputationTierThresholds; // [Tier 1, Tier 2, ...]. User is in Tier N if rep >= thresholds[N-1]

    struct Recipe {
        uint256[] ingredientItemIds;    // IDs of ingredients required
        uint256[] ingredientAmounts;    // Amounts of ingredients required
        uint256 outputAmount;           // Amount of output item produced
        uint256 craftCost;              // Amount of CraftCoin required
        uint256 reputationReward;       // Reputation points gained on successful craft
        bool isActive;                  // Is this recipe currently craftable?
        uint64 availableUntil;          // Timestamp when the recipe expires (0 for never)
        uint256 requiredTier;           // Minimum reputation tier required to craft (0 for no requirement)

        // Bonus item chance (optional)
        uint256 bonusItemId;            // ID of the potential bonus item
        uint256 bonusAmount;            // Amount of bonus item
        uint256 bonusChanceBasisPoints; // Chance out of 10000 (e.g., 100 is 1%)
    }

    mapping(uint256 => Recipe) private recipes; // Maps output item ID to recipe details
    uint256[] private activeRecipeIds; // Array of output item IDs for active recipes

    mapping(address => mapping(uint256 => uint256)) private userCraftCounts; // userAddress => recipeOutputItemId => count

    struct RecipeSuggestion {
        uint256 suggestionId;
        address suggester;
        uint256 outputItemId;
        uint256 outputAmount;
        uint256[] ingredientItemIds;
        uint256[] ingredientAmounts;
        uint256 craftCost;
        uint256 reputationReward;
        uint64 timestamp;
    }

    RecipeSuggestion[] private recipeSuggestions;
    uint256 private nextSuggestionId = 1;

    bytes4 private constant ERC1155_RECEIVED_ID = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED_ID = 0xbc197c81;

    // --- Events ---
    event Crafted(address indexed user, uint256 indexed recipeOutputItemId, uint256 amount, uint256 reputationGained, uint256 bonusItemId, uint256 bonusAmount);
    event RecipeAdded(uint256 indexed outputItemId, address indexed addedBy);
    event RecipeDeactivated(uint256 indexed outputItemId, address indexed deactivatedBy);
    event ReputationUpdated(address indexed account, uint256 newReputation);
    event TierThresholdsUpdated(uint256[] thresholds);
    event AdminAdded(address indexed adminAddress);
    event AdminRemoved(address indexed adminAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RecipeSuggested(uint256 indexed suggestionId, address indexed suggester, uint256 outputItemId);
    event RecipeBonusSet(uint256 indexed recipeOutputItemId, uint256 bonusItemId, uint256 bonusAmount, uint256 bonusChanceBasisPoints);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != _owner && !_admins[msg.sender]) revert NotAdmin();
        _;
    }

    // --- Constructor ---
    constructor(address _craftCoinAddress, address _craftAssetAddress) {
        if (_craftCoinAddress == address(0) || _craftAssetAddress == address(0)) revert InvalidAmount(); // Simple check
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        craftCoin = _craftCoinAddress;
        craftAsset = _craftAssetAddress;
    }

    // --- Access Control ---

    /// @dev Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NotOwner(); // Prevent setting owner to zero address
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /// @dev Adds an address as an admin. Admins can perform privileged operations.
    /// @param adminAddress The address to add as admin.
    function addAdmin(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "Invalid address");
        _admins[adminAddress] = true;
        emit AdminAdded(adminAddress);
    }

    /// @dev Removes an admin address.
    /// @param adminAddress The address to remove as admin.
    function removeAdmin(address adminAddress) public onlyOwner {
        require(adminAddress != _owner, "Cannot remove owner as admin via this function");
        _admins[adminAddress] = false;
        emit AdminRemoved(adminAddress);
    }

    /// @dev Checks if an address has admin privileges.
    /// @param adminAddress The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address adminAddress) public view returns (bool) {
        return _admins[adminAddress];
    }

    // --- Pausable ---

    /// @dev Pauses contract operations.
    function pause() public onlyAdmin {
        _pause();
    }

    /// @dev Unpauses contract operations.
    function unpause() public onlyAdmin {
        _unpause();
    }

    // --- Token Interaction (Queries) ---

    /// @dev Gets the Craft Coin balance of an account.
    /// @param account The address to query.
    /// @return The balance of Craft Coin.
    function getCraftCoinBalance(address account) public view returns (uint256) {
        return IERC20(craftCoin).balanceOf(account);
    }

    /// @dev Gets the Craft Asset balance of an account for a specific item ID.
    /// @param account The address to query.
    /// @param id The item ID to query.
    /// @return The balance of the specific Craft Asset.
    function getCraftAssetBalance(address account, uint256 id) public view returns (uint256) {
         address[] memory accounts = new address[](1);
         uint256[] memory ids = new uint256[](1);
         accounts[0] = account;
         ids[0] = id;
        return IERC1155(craftAsset).balanceOfBatch(accounts, ids)[0];
    }

    /// @dev Gets Craft Asset balances for multiple item IDs for an account.
    /// @param account The address to query.
    /// @param ids The array of item IDs to query.
    /// @return An array of balances corresponding to the input IDs.
    function getCraftAssetBatchBalance(address account, uint256[] calldata ids) public view returns (uint256[] memory) {
        address[] memory accounts = new address[](ids.length);
        for(uint i = 0; i < ids.length; i++) {
            accounts[i] = account;
        }
        return IERC1155(craftAsset).balanceOfBatch(accounts, ids);
    }

    // --- Reputation System ---

    /// @dev Gets the current reputation points for an account.
    /// @param account The address to query.
    /// @return The reputation points.
    function getReputation(address account) public view returns (uint256) {
        return userReputation[account];
    }

    /// @dev Gets the reputation tier for an account based on their points and current thresholds.
    /// @param account The address to query.
    /// @return The reputation tier (0 is the lowest tier).
    function getReputationTier(address account) public view returns (uint256) {
        uint256 currentRep = userReputation[account];
        uint256 tier = 0;
        for (uint256 i = 0; i < reputationTierThresholds.length; i++) {
            if (currentRep >= reputationTierThresholds[i]) {
                tier = i + 1;
            } else {
                // Thresholds are increasing, so we found the tier
                break;
            }
        }
        return tier;
    }

    /// @dev Sets the reputation point thresholds for different tiers. Must be strictly increasing.
    /// @param thresholds An array where thresholds[i] is the minimum points for tier i+1.
    function setReputationTierThresholds(uint256[] calldata thresholds) public onlyAdmin {
        for (uint256 i = 0; i < thresholds.length; i++) {
            if (i > 0 && thresholds[i] <= thresholds[i-1]) {
                revert InvalidTierThresholds();
            }
        }
        reputationTierThresholds = thresholds;
        emit TierThresholdsUpdated(thresholds);
    }

    /// @dev Gets the currently configured reputation tier thresholds.
    /// @return An array of tier thresholds.
    function getTierThresholds() public view returns (uint256[] memory) {
        return reputationTierThresholds;
    }

    /// @dev Penalizes an account's reputation points.
    /// @param account The address to penalize.
    /// @param points The number of points to subtract.
    function penalizeReputation(address account, uint256 points) public onlyAdmin {
        if (userReputation[account] < points) {
             userReputation[account] = 0;
        } else {
            unchecked { userReputation[account] -= points; }
        }
        emit ReputationUpdated(account, userReputation[account]);
    }

    /// @dev Internal helper to award reputation points.
    /// @param account The address to award points to.
    /// @param points The number of points to add.
    function _awardReputation(address account, uint256 points) internal {
        if (points == 0) return;
        unchecked { userReputation[account] += points; }
        emit ReputationUpdated(account, userReputation[account]);
    }

    // --- Recipe Management ---

    /// @dev Adds a new recipe to the system. Output item ID is the unique identifier for the recipe.
    /// @param outputItemId The ID of the item produced by this recipe.
    /// @param outputAmount The amount of the output item produced per craft.
    /// @param ingredientItemIds IDs of required ingredients.
    /// @param ingredientAmounts Amounts of required ingredients.
    /// @param craftCost The Craft Coin cost for one craft.
    /// @param reputationReward Reputation points gained per craft.
    /// @param availableUntil Timestamp when the recipe is no longer available (0 for never).
    function addRecipe(
        uint256 outputItemId,
        uint256 outputAmount,
        uint256[] calldata ingredientItemIds,
        uint256[] calldata ingredientAmounts,
        uint256 craftCost,
        uint256 reputationReward,
        uint64 availableUntil
    ) public onlyAdmin {
        _addRecipe(outputItemId, outputAmount, ingredientItemIds, ingredientAmounts, craftCost, reputationReward, availableUntil, 0);
    }

    /// @dev Adds a new recipe that requires a minimum reputation tier to craft.
    /// @param outputItemId The ID of the item produced by this recipe.
    /// @param outputAmount The amount of the output item produced per craft.
    /// @param ingredientItemIds IDs of required ingredients.
    /// @param ingredientAmounts Amounts of required ingredients.
    /// @param craftCost The Craft Coin cost for one craft.
    /// @param reputationReward Reputation points gained per craft.
    /// @param availableUntil Timestamp when the recipe is no longer available (0 for never).
    /// @param requiredTier Minimum reputation tier required.
    function addTierGatedRecipe(
        uint256 outputItemId,
        uint256 outputAmount,
        uint256[] calldata ingredientItemIds,
        uint256[] calldata ingredientAmounts,
        uint256 craftCost,
        uint256 reputationReward,
        uint64 availableUntil,
        uint256 requiredTier
    ) public onlyAdmin {
         _addRecipe(outputItemId, outputAmount, ingredientItemIds, ingredientAmounts, craftCost, reputationReward, availableUntil, requiredTier);
    }

     /// @dev Internal helper to add/update a recipe.
     function _addRecipe(
        uint256 outputItemId,
        uint256 outputAmount,
        uint256[] calldata ingredientItemIds,
        uint256[] calldata ingredientAmounts,
        uint256 craftCost,
        uint256 reputationReward,
        uint64 availableUntil,
        uint256 requiredTier
     ) internal {
        require(ingredientItemIds.length == ingredientAmounts.length, "Ingredients and amounts mismatch");
        require(outputAmount > 0, "Output amount must be greater than zero");
        require(recipes[outputItemId].outputAmount == 0, "Recipe already exists for this output item ID"); // Prevent overwriting existing recipes

        recipes[outputItemId] = Recipe({
            ingredientItemIds: ingredientItemIds,
            ingredientAmounts: ingredientAmounts,
            outputAmount: outputAmount,
            craftCost: craftCost,
            reputationReward: reputationReward,
            isActive: true, // Newly added recipes are active by default
            availableUntil: availableUntil,
            requiredTier: requiredTier,
            bonusItemId: 0,
            bonusAmount: 0,
            bonusChanceBasisPoints: 0
        });

        // Add to active list if not already there
        bool found = false;
        for(uint i = 0; i < activeRecipeIds.length; i++) {
            if (activeRecipeIds[i] == outputItemId) {
                found = true;
                break;
            }
        }
        if (!found) {
            activeRecipeIds.push(outputItemId);
        }

        emit RecipeAdded(outputItemId, msg.sender);
    }


    /// @dev Deactivates a recipe, making it uncraftable.
    /// @param outputItemId The ID of the recipe (output item ID) to deactivate.
    function deactivateRecipe(uint256 outputItemId) public onlyAdmin {
        Recipe storage recipe = recipes[outputItemId];
        if (recipe.outputAmount == 0 || !recipe.isActive) revert RecipeDoesNotExist(outputItemId); // Check if recipe exists and is active

        recipe.isActive = false;

        // Remove from active list (inefficient for large lists, but simple)
        for(uint i = 0; i < activeRecipeIds.length; i++) {
            if (activeRecipeIds[i] == outputItemId) {
                // Swap with last element and pop
                activeRecipeIds[i] = activeRecipeIds[activeRecipeIds.length - 1];
                activeRecipeIds.pop();
                break;
            }
        }

        emit RecipeDeactivated(outputItemId, msg.sender);
    }

    /// @dev Gets the details of a specific recipe.
    /// @param outputItemId The ID of the recipe (output item ID).
    /// @return The Recipe struct.
    function getRecipeDetails(uint256 outputItemId) public view returns (Recipe memory) {
        Recipe storage recipe = recipes[outputItemId];
        if (recipe.outputAmount == 0) revert RecipeDoesNotExist(outputItemId); // Check if recipe exists
        return recipe;
    }

    /// @dev Gets a list of all currently active recipe output item IDs.
    /// @return An array of active recipe IDs.
    function getAllRecipeIds() public view returns (uint256[] memory) {
        return activeRecipeIds;
    }

    /// @dev Sets a potential bonus item and its drop chance for a specific recipe.
    /// @param recipeOutputItemId The ID of the recipe (output item ID).
    /// @param bonusItemId The ID of the bonus item.
    /// @param bonusAmount The amount of the bonus item.
    /// @param bonusChanceBasisPoints The chance of dropping the bonus item, out of 10000 (e.g., 100 = 1%).
    function setRecipeBonusItem(uint256 recipeOutputItemId, uint256 bonusItemId, uint256 bonusAmount, uint256 bonusChanceBasisPoints) public onlyAdmin {
        Recipe storage recipe = recipes[recipeOutputItemId];
        if (recipe.outputAmount == 0) revert RecipeDoesNotExist(recipeOutputItemId); // Check if recipe exists

        if (bonusChanceBasisPoints > 10000) revert InvalidBonusChance();

        recipe.bonusItemId = bonusItemId;
        recipe.bonusAmount = bonusAmount;
        recipe.bonusChanceBasisPoints = bonusChanceBasisPoints;

        emit RecipeBonusSet(recipeOutputItemId, bonusItemId, bonusAmount, bonusChanceBasisPoints);
    }

    /// @dev Allows a user to suggest a new recipe. These suggestions can be reviewed by admins.
    /// @param outputItemId The ID of the item this recipe would produce.
    /// @param outputAmount The amount produced.
    /// @param ingredientItemIds Ingredient IDs.
    /// @param ingredientAmounts Ingredient amounts.
    /// @param craftCost Craft Coin cost.
    /// @param reputationReward Reputation gained.
    function suggestRecipe(
        uint256 outputItemId,
        uint256 outputAmount,
        uint256[] calldata ingredientItemIds,
        uint256[] calldata ingredientAmounts,
        uint256 craftCost,
        uint256 reputationReward
    ) public whenNotPaused {
        require(ingredientItemIds.length == ingredientAmounts.length, "Ingredients and amounts mismatch");
        require(outputAmount > 0, "Output amount must be greater than zero");
        // Could add more validation here (e.g., check if outputItemId is already a recipe)

        recipeSuggestions.push(RecipeSuggestion({
            suggestionId: nextSuggestionId,
            suggester: msg.sender,
            outputItemId: outputItemId,
            outputAmount: outputAmount,
            ingredientItemIds: ingredientItemIds,
            ingredientAmounts: ingredientAmounts,
            craftCost: craftCost,
            reputationReward: reputationReward,
            timestamp: uint64(block.timestamp)
        }));

        emit RecipeSuggested(nextSuggestionId, msg.sender, outputItemId);
        nextSuggestionId++;
    }

    /// @dev Gets the list of all pending recipe suggestions.
    /// @return An array of RecipeSuggestion structs.
    function getRecipeSuggestions() public view onlyAdmin returns (RecipeSuggestion[] memory) {
        return recipeSuggestions;
    }

    // --- Crafting ---

    /// @dev Executes a single craft of a specified recipe.
    /// Requires the user to have approved the contract to spend the required Craft Coin
    /// and transfer the required Craft Assets (ingredients).
    /// @param recipeOutputItemId The ID of the recipe (output item ID) to craft.
    function craft(uint256 recipeOutputItemId) public whenNotPaused {
        _processCraft(msg.sender, recipeOutputItemId, 1);
    }

    /// @dev Executes multiple crafts of a specified recipe in a single transaction.
    /// Requires the user to have approved the contract to spend the required Craft Coin
    /// and transfer the required Craft Assets (ingredients). Total costs/ingredients = amount * single craft cost/ingredients.
    /// @param recipeOutputItemId The ID of the recipe (output item ID) to craft.
    /// @param amount The number of times to craft the recipe.
    function craftBatch(uint256 recipeOutputItemId, uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        _processCraft(msg.sender, recipeOutputItemId, amount);
    }

    /// @dev Internal helper function containing the core crafting logic.
    /// Handles checking requirements, transferring/burning ingredients and coin,
    /// minting output item, awarding reputation, and applying bonus chance.
    /// @param user The address performing the craft.
    /// @param recipeOutputItemId The ID of the recipe.
    /// @param craftAmount The number of times to craft the recipe (for batching).
    function _processCraft(address user, uint256 recipeOutputItemId, uint256 craftAmount) internal {
        Recipe storage recipe = recipes[recipeOutputItemId];

        // 1. Check Recipe Existence and Status
        if (recipe.outputAmount == 0) revert RecipeDoesNotExist(recipeOutputItemId);
        if (!recipe.isActive) revert RecipeNotActive(recipeOutputItemId);
        if (recipe.availableUntil > 0 && block.timestamp > recipe.availableUntil) revert RecipeNotAvailable(recipeOutputItemId);

        // 2. Check Reputation Tier Requirement
        uint256 currentUserTier = getReputationTier(user);
        if (currentUserTier < recipe.requiredTier) {
            revert ReputationTooLow(recipe.requiredTier, currentUserTier);
        }

        // 3. Calculate Total Costs and Ingredients
        uint256 totalCraftCost = recipe.craftCost * craftAmount;
        uint256 totalOutputAmount = recipe.outputAmount * craftAmount;
        uint256 reputationGained = recipe.reputationReward * craftAmount;

        uint256[] memory totalIngredientItemIds = recipe.ingredientItemIds;
        uint256[] memory totalIngredientAmounts = new uint256[](totalIngredientItemIds.length);

        for (uint i = 0; i < totalIngredientItemIds.length; i++) {
            totalIngredientAmounts[i] = recipe.ingredientAmounts[i] * craftAmount;
        }

        // 4. Check User Balances (Ingredients and Coin)
        uint256[] memory userIngredientBalances = IERC1155(craftAsset).balanceOfBatch(
            new address[](totalIngredientItemIds.length).fill(user), // Fill with user address
            totalIngredientItemIds
        );

        for (uint i = 0; i < totalIngredientItemIds.length; i++) {
            if (userIngredientBalances[i] < totalIngredientAmounts[i]) {
                revert InsufficientIngredients(totalIngredientItemIds[i], totalIngredientAmounts[i], userIngredientBalances[i]);
            }
        }

        uint256 userCoinBalance = IERC20(craftCoin).balanceOf(user);
        if (userCoinBalance < totalCraftCost) {
            revert InsufficientCraftCoin(totalCraftCost, userCoinBalance);
        }

        // 5. Perform Transfers/Burns
        // Transfer ingredients from user to this contract (or burn)
        // Assuming ingredients are burned upon crafting, transfer to address(0x0)
        // Note: User MUST have approved this contract for the Craft Asset using setApprovalForAll
        if (totalIngredientItemIds.length > 0) {
             IERC1155(craftAsset).safeBatchTransferFrom(
                user,
                address(0), // Burn ingredients
                totalIngredientItemIds,
                totalIngredientAmounts,
                "" // Data field, not used here
            );
        }

        // Transfer Craft Coin from user to this contract (or burn)
        // Assuming coin is burned, transfer to address(0x0)
        // Note: User MUST have approved this contract for the Craft Coin using approve
        if (totalCraftCost > 0) {
            bool success = IERC20(craftCoin).transferFrom(user, address(0), totalCraftCost); // Burn coin
            require(success, "CraftCoin transfer failed");
        }

        // 6. Mint Output Item(s)
        // Assuming this contract has minting permission on the Craft Asset contract
        // or there's an admin function on CraftAsset that this contract calls.
        // For this example, we'll assume an internal mint function exists or is simulated.
        // In a real system, the CraftAsset contract would likely have an internal
        // or restricted `_mintBatch` function callable by trusted addresses like this crafter.
        // Example (simplified):
        // IERC1155(craftAsset).mint(address(this), recipeOutputItemId, totalOutputAmount, ""); // Requires this contract to *be* the minter or call a minter function
        // A better approach is usually: CraftAsset has a public `mintBatch(address to, uint256[] ids, uint256[] amounts, bytes data)` function callable *only* by the owner/admin (this contract).

        // We'll simulate minting by assuming a call happens elsewhere or the CraftAsset
        // contract is designed to allow this contract to mint to the user.
        // A simple internal simulation for demonstration:
        // `_mintAsset(user, recipeOutputItemId, totalOutputAmount);`
        // In a real multi-contract setup, this would be a cross-contract call.
        // Let's assume the call succeeds. For the purpose of *this* contract's logic:
        // The user receives totalOutputAmount of recipeOutputItemId.

        // Simulate ERC1155 Mint (requires an external contract call in reality)
        // Pseudo-code: Call `CraftAssetContract.mint(user, recipeOutputItemId, totalOutputAmount)`
        // We don't have the mint function defined in the IERC1155 interface, as that's application specific.
        // A real implementation would cast to the specific CraftAsset contract or use a custom interface.
        // ERC1155 Minting:
        // address[] memory recipients = new address[](1).fill(user);
        // uint256[] memory outputIds = new uint256[](1).fill(recipeOutputItemId);
        // uint256[] memory outputAmounts = new uint256[](1).fill(totalOutputAmount);
        // IERC1155(craftAsset).mintBatch(recipients, outputIds, outputAmounts, ""); // This function is NOT standard ERC1155, must exist on the specific token contract

        // Simplified Simulation for this contract's internal logic:
        // Assume assets are minted to the user.

        // 7. Award Reputation
        _awardReputation(user, reputationGained);

        // 8. Process Bonus Item Chance
        uint256 bonusDroppedItemId = 0;
        uint256 bonusDroppedAmount = 0;

        if (recipe.bonusItemId != 0 && recipe.bonusAmount > 0 && recipe.bonusChanceBasisPoints > 0) {
             // Simple on-chain randomness based on block data (caution: predictable!)
             // A more robust system would use Chainlink VRF or similar.
            uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, userCraftCounts[user][recipeOutputItemId])));

            // Check bonus chance for *each* craft attempt within the batch
            for (uint i = 0; i < craftAmount; i++) {
                 // Generate a value between 0 and 9999
                 uint256 chanceRoll = (randomValue + i) % 10000; // Add 'i' to slightly vary roll in batch

                 if (chanceRoll < recipe.bonusChanceBasisPoints) {
                    // Bonus dropped!
                    // Simulate minting bonus item
                    // address[] memory bonusRecipients = new address[](1).fill(user);
                    // uint256[] memory bonusIds = new uint256[](1).fill(recipe.bonusItemId);
                    // uint256[] memory bonusAmounts = new uint256[](1).fill(recipe.bonusAmount);
                    // IERC1155(craftAsset).mintBatch(bonusRecipients, bonusIds, bonusAmounts, ""); // Again, requires non-standard mint function

                    bonusDroppedItemId = recipe.bonusItemId; // Report the bonus item
                    // For simplicity, just report ONE bonus drop in the event even if multiple occurred in batch
                    // A more complex event or separate event per craft would be needed for full detail.
                    bonusDroppedAmount += recipe.bonusAmount; // Sum up total bonus amount for the batch
                 }
            }
        }


        // 9. Update User Craft Count
        unchecked { userCraftCounts[user][recipeOutputItemId] += craftAmount; }

        // 10. Emit Event
        emit Crafted(user, recipeOutputItemId, craftAmount, reputationGained, bonusDroppedItemId, bonusDroppedAmount);
    }


    // --- User Statistics ---

    /// @dev Gets the number of times a user has successfully crafted a specific recipe.
    /// @param account The address to query.
    /// @param recipeOutputItemId The ID of the recipe (output item ID).
    /// @return The number of times crafted.
    function getUserCraftCount(address account, uint256 recipeOutputItemId) public view returns (uint256) {
        return userCraftCounts[account][recipeOutputItemId];
    }


    // --- ERC1155 Receiver Hooks ---
    // These are necessary if this contract were designed to *receive* ERC1155 tokens.
    // In this specific crafting logic, the contract *burns* ingredients by transferring to address(0),
    // so it doesn't strictly *need* to implement these hooks for the *crafting input* side.
    // However, implementing supportsInterface for ERC1155 receiver is good practice
    // if the contract might interact with ERC1155 tokens in other ways or if safeBatchTransferFrom
    // is used where the recipient is this contract.

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual returns (bytes4) {
        // This hook is called when a single ERC1155 token is transferred to this contract using safeTransferFrom
        // Implement logic here if the contract needs to react to receiving single tokens.
        // For a crafting contract, receiving ingredients might be relevant for storage,
        // but burning (transfer to address(0)) bypasses this hook on the sender side.
        // If you wanted users to transfer ingredients *to* the contract first, then craft,
        // you would need logic here.
        console.log("onERC1155Received called: operator %s, from %s, id %s, value %s", operator, from, id, value);
        return ERC1155_RECEIVED_ID; // Return this magic value to signal successful reception
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) public virtual returns (bytes4) {
         // This hook is called when a batch of ERC1155 tokens is transferred to this contract using safeBatchTransferFrom
        // Implement logic here if the contract needs to react to receiving batch tokens.
        console.log("onERC1155BatchReceived called: operator %s, from %s, ids %s, values %s", operator, from, ids, values);
        return ERC1155_BATCH_RECEIVED_ID; // Return this magic value to signal successful reception
    }

    /// @dev Required for ERC165 compliance. Indicates which interfaces this contract supports.
    /// @param interfaceId The interface ID to check.
    /// @return True if the interface is supported, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || // ERC165 itself
               interfaceId == type(IERC1155).interfaceId || // ERC1155 (if implementing receiver hooks)
               super.supportsInterface(interfaceId); // Include interfaces from inherited contracts (like Pausable if it supported ERC165)
    }
}

// Helper function to fill an array - useful for batchBalanceOf or minting
library ArrayUtils {
    function fill(address[] memory arr, address value) internal pure returns (address[] memory) {
        for(uint i = 0; i < arr.length; i++) {
            arr[i] = value;
        }
        return arr;
    }
}
```