Okay, let's design a smart contract that simulates a "CryptoCrafting Forge". This contract will manage recipes, allow users to combine different ERC-1155 "Ingredient" tokens and ERC-20 "Fuel" tokens to attempt to craft ERC-721 "Artifact" NFTs. It will include features like probabilistic crafting success, dynamic artifact properties based on crafting inputs, refining existing artifacts, and salvaging artifacts for resources.

This combines concepts from GameFi, NFTs, multi-token interaction, state management (recipes, properties), and controlled randomness (with necessary disclaimers).

**Disclaimer:** The randomness implemented using `block.timestamp` or similar `block` variables is *not* secure for production use cases where significant value is at stake, as miners can influence it. A production system would require a secure oracle like Chainlink VRF or similar verifiable random function. This example uses a simple method for demonstration purposes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- OUTLINE ---
// 1. Libraries/Interfaces: ERC20, ERC721, ERC1155, Ownable, Pausable.
// 2. State Variables:
//    - Token addresses (FUEL ERC20, INGREDIENTS ERC1155, ARTIFACTS ERC721).
//    - Owner & Pausable state.
//    - Recipe management: Mapping from recipe ID to Recipe struct.
//    - Ingredient types: Mapping from ingredient type ID to bool (validity).
//    - Artifact properties: Mapping from Artifact token ID to ArtifactProperties struct.
//    - Crafting counter for unique artifact IDs.
//    - Ingredient discovery parameters (cost, probabilities).
//    - Salvage parameters (min return rates).
// 3. Structs:
//    - IngredientAmount: ERC1155 ID and required amount.
//    - Recipe: ID, name, required ingredients, required fuel, output artifact type/base properties, success chance.
//    - ArtifactProperties: Dynamic properties of a crafted artifact (e.g., power, durability).
//    - IngredientDiscoveryProb: Ingredient type ID and weighted probability for discovery.
// 4. Events: To log important actions (CraftingSuccess, CraftingFailed, Salvaged, RecipeAdded, IngredientDiscovered, FeeWithdrawn, etc.).
// 5. Modifiers: onlyOwner, whenNotPaused, whenPaused.
// 6. Constructor: Initialize owner and token addresses.
// 7. Admin Functions (onlyOwner):
//    - Set token addresses.
//    - Add/Update/Remove recipes.
//    - Add/Remove valid ingredient types.
//    - Set ingredient discovery cost and probabilities.
//    - Set salvage return rates.
//    - Pause/Unpause crafting.
//    - Withdraw accumulated fuel fees.
// 8. User Functions (whenNotPaused):
//    - Discover ingredients (spends FUEL, gains random INGREDIENTS).
//    - Craft artifact (spends INGREDIENTS and FUEL based on recipe, attempts to mint ARTIFACT).
//    - Refine artifact (spends INGREDIENTS/FUEL, modifies existing ARTIFACT properties).
//    - Salvage artifact (burns ARTIFACT, recovers some INGREDIENTS/FUEL).
// 9. View Functions:
//    - Get recipe details.
//    - Get artifact properties.
//    - Check crafting requirements for a recipe.
//    - Get ingredient discovery probability data.
//    - Get salvage return rates.
//    - Get total recipe count, valid ingredient type count.
//    - Get contract's fuel balance.
// 10. Internal Functions:
//     - Pseudo-random number generation (with disclaimer).
//     - Artifact property generation logic.
//     - Salvage return calculation.
//     - Helper to check user balances/approvals.

// --- FUNCTION SUMMARY ---
// Admin Functions:
// - setFuelToken(IERC20 fuelToken_): Set the address of the FUEL token.
// - setIngredientToken(IERC1155 ingredientToken_): Set the address of the INGREDIENTS token.
// - setArtifactToken(IERC721 artifactToken_): Set the address of the ARTIFACTS token.
// - addIngredientType(uint256 ingredientTypeId_): Mark an ingredient type ID as valid.
// - removeIngredientType(uint256 ingredientTypeId_): Mark an ingredient type ID as invalid.
// - addRecipe(string memory name_, IngredientAmount[] memory requiredIngredients_, uint256 requiredFuel_, uint256 successChance_, uint256 basePower_, uint256 baseDurability_): Add a new crafting recipe.
// - updateRecipe(uint256 recipeId_, string memory name_, IngredientAmount[] memory requiredIngredients_, uint256 requiredFuel_, uint256 successChance_, uint256 basePower_, uint256 baseDurability_): Update an existing crafting recipe.
// - removeRecipe(uint256 recipeId_): Remove a crafting recipe.
// - setIngredientDiscoveryCost(uint256 cost_): Set the FUEL cost for discovering ingredients.
// - addIngredientDiscoveryProb(uint256 ingredientTypeId_, uint256 weight_): Add or update a weighted probability for an ingredient type in discovery.
// - removeIngredientDiscoveryProb(uint256 ingredientTypeId_): Remove an ingredient type from discovery probabilities.
// - setSalvageReturnRates(uint256 minIngredientReturnBps_, uint256 minFuelReturnBps_): Set minimum return rates for salvaging (in basis points).
// - pauseCrafting(): Pause all crafting operations.
// - unpauseCrafting(): Unpause crafting operations.
// - withdrawFees(uint256 amount_): Withdraw accumulated FUEL fees to the owner.

// User Functions:
// - discoverIngredient(): Pay FUEL to attempt to discover random ingredients. Requires FUEL approval.
// - craftArtifact(uint256 recipeId_): Attempt to craft an artifact using a recipe. Requires INGREDIENT and FUEL approvals.
// - refineArtifact(uint256 artifactTokenId_, uint256 recipeId_): Attempt to refine an existing artifact. Requires INGREDIENT and FUEL approvals.
// - salvageArtifact(uint256 artifactTokenId_): Salvage an artifact to recover resources. Requires ARTIFACT approval (burn).

// View Functions:
// - getRecipe(uint256 recipeId_): Get details of a specific recipe.
// - getArtifactProperties(uint256 artifactTokenId_): Get dynamic properties of an artifact.
// - checkCraftingRequirements(address user_, uint256 recipeId_): Check if a user meets requirements for a recipe without executing.
// - getIngredientDiscoveryProbabilities(): Get the current ingredient discovery probabilities.
// - getSalvageReturnRates(): Get the current salvage return rates.
// - getTotalRecipeCount(): Get the total number of defined recipes.
// - getValidIngredientTypeCount(): Get the total number of valid ingredient types.
// - getForgeFuelBalance(): Get the contract's current FUEL balance.
// - isValidIngredientType(uint256 ingredientTypeId_): Check if an ingredient type is valid.

// --- INTERFACES & LIBRARIES ---

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Burnable.sol"; // Assuming burnable ERC721
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For tokenURI etc. (though not fully implemented here)
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // If the contract needs to hold ERC721
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Useful for calculations, although Solidity 0.8+ has overflow checks by default

// We will mock ERC721/ERC1155 interfaces and assume they have necessary functions like safeTransferFrom, balanceOf, mint, burn.
// For a real implementation, you'd deploy these token contracts and link their addresses.

interface IERC721MintableBurnable is IERC721, IERC721Burnable, IERC721Metadata {
    function safeMint(address to, uint256 tokenId) external;
}

interface IERC1155MintableBurnable is IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 amount) external;
}


contract CryptoCraftingForge is Ownable, Pausable, ERC721Holder { // Inherit ERC721Holder if the forge might temporarily hold artifacts
    using SafeMath for uint256;

    // --- STATE VARIABLES ---

    IERC20 private _fuelToken;
    IERC1155MintableBurnable private _ingredientToken;
    IERC721MintableBurnable private _artifactToken;

    // Recipe Management
    struct IngredientAmount {
        uint256 id;     // ERC1155 token ID
        uint256 amount; // Required amount
    }

    struct Recipe {
        uint256 id;
        string name;
        IngredientAmount[] requiredIngredients;
        uint256 requiredFuel;
        uint256 successChance; // 0-100, percentage
        uint256 basePower;     // Base property for generated artifact
        uint256 baseDurability; // Base property for generated artifact
        bool isRefinement;    // Is this a refinement recipe (modifies existing artifact)?
    }

    mapping(uint256 => Recipe) private _recipes;
    uint256 private _recipeCount; // To track recipe IDs

    mapping(uint256 => bool) private _validIngredientTypes; // ERC1155 IDs that are recognized
    uint256 private _validIngredientTypeCount;

    // Artifact Properties
    struct ArtifactProperties {
        uint256 power;
        uint256 durability;
        // Add more properties as needed (e.g., type, element, enchantments)
    }

    mapping(uint256 => ArtifactProperties) private _artifactProperties;
    uint256 private _nextArtifactId; // Counter for ERC721 minting

    // Ingredient Discovery
    uint256 private _ingredientDiscoveryCost; // In FUEL tokens
    struct IngredientDiscoveryProb {
        uint256 ingredientTypeId;
        uint256 weight; // Higher weight = higher chance
    }
    IngredientDiscoveryProb[] private _ingredientDiscoveryProbabilities;
    uint256 private _totalDiscoveryWeight;

    // Salvage Parameters (in Basis Points, e.g., 5000 = 50%)
    uint256 private _minIngredientReturnBps = 5000; // Default 50%
    uint256 private _minFuelReturnBps = 2500;       // Default 25%
    uint256 private constant BPS_DENOMINATOR = 10000;

    // --- EVENTS ---

    event TokensSet(address fuelToken, address ingredientToken, address artifactToken);
    event IngredientTypeAdded(uint256 indexed ingredientTypeId);
    event IngredientTypeRemoved(uint256 indexed ingredientTypeId);
    event RecipeAdded(uint256 indexed recipeId, string name);
    event RecipeUpdated(uint256 indexed recipeId, string name);
    event RecipeRemoved(uint256 indexed recipeId);
    event IngredientDiscoveryCostSet(uint256 cost);
    event IngredientDiscoveryProbAdded(uint256 indexed ingredientTypeId, uint256 weight);
    event IngredientDiscoveryProbRemoved(uint256 indexed ingredientTypeId);
    event SalvageReturnRatesSet(uint256 minIngredientReturnBps, uint256 minFuelReturnBps);
    event IngredientDiscovered(address indexed user, uint256 indexed ingredientTypeId, uint256 amount, uint256 fuelSpent);
    event CraftingAttempt(address indexed user, uint256 indexed recipeId);
    event CraftingSuccess(address indexed user, uint256 indexed recipeId, uint256 indexed artifactTokenId);
    event CraftingFailed(address indexed user, uint256 indexed recipeId, string reason);
    event ArtifactRefined(address indexed user, uint256 indexed artifactTokenId, uint256 indexed recipeId);
    event ArtifactSalvaged(address indexed user, uint256 indexed artifactTokenId, uint256 returnedFuel, IngredientAmount[] returnedIngredients);
    event FeeWithdrawn(address indexed owner, uint256 amount);

    // --- MODIFIERS ---

    // No custom modifiers needed beyond Ownable and Pausable

    // --- CONSTRUCTOR ---

    constructor(address fuelToken_, address ingredientToken_, address artifactToken_) Ownable(msg.sender) {
        setFuelToken(IERC20(fuelToken_));
        setIngredientToken(IERC1155MintableBurnable(ingredientToken_));
        setArtifactToken(IERC721MintableBurnable(artifactToken_));
        _nextArtifactId = 1; // Start artifact IDs from 1
        _recipeCount = 0;
        _validIngredientTypeCount = 0;
        _ingredientDiscoveryCost = 100 * (10**18); // Example default cost: 100 FUEL (assuming 18 decimals)
    }

    // --- ADMIN FUNCTIONS ---

    /// @notice Sets the address of the FUEL ERC20 token.
    /// @param fuelToken_ The address of the FUEL token contract.
    function setFuelToken(IERC20 fuelToken_) public onlyOwner {
        require(address(fuelToken_) != address(0), "Invalid address");
        _fuelToken = fuelToken_;
        emit TokensSet(address(_fuelToken), address(_ingredientToken), address(_artifactToken));
    }

    /// @notice Sets the address of the INGREDIENTS ERC1155 token.
    /// @param ingredientToken_ The address of the INGREDIENTS token contract.
    function setIngredientToken(IERC1155MintableBurnable ingredientToken_) public onlyOwner {
        require(address(ingredientToken_) != address(0), "Invalid address");
        _ingredientToken = ingredientToken_;
        emit TokensSet(address(_fuelToken), address(_ingredientToken), address(_artifactToken));
    }

    /// @notice Sets the address of the ARTIFACTS ERC721 token.
    /// @param artifactToken_ The address of the ARTIFACTS token contract.
    function setArtifactToken(IERC721MintableBurnable artifactToken_) public onlyOwner {
        require(address(artifactToken_) != address(0), "Invalid address");
        _artifactToken = artifactToken_;
        emit TokensSet(address(_fuelToken), address(_ingredientToken), address(_artifactToken));
    }

    /// @notice Marks an ingredient type ID as valid for use in recipes and discovery.
    /// @param ingredientTypeId_ The ID of the ERC1155 ingredient type.
    function addIngredientType(uint256 ingredientTypeId_) public onlyOwner {
        if (!_validIngredientTypes[ingredientTypeId_]) {
            _validIngredientTypes[ingredientTypeId_] = true;
            _validIngredientTypeCount++;
            emit IngredientTypeAdded(ingredientTypeId_);
        }
    }

    /// @notice Marks an ingredient type ID as invalid. Existing uses in recipes/discovery are not automatically removed.
    /// @param ingredientTypeId_ The ID of the ERC1155 ingredient type.
    function removeIngredientType(uint256 ingredientTypeId_) public onlyOwner {
        if (_validIngredientTypes[ingredientTypeId_]) {
            _validIngredientTypes[ingredientTypeId_] = false;
            _validIngredientTypeCount--;
            emit IngredientTypeRemoved(ingredientTypeId_);
        }
    }

    /// @notice Adds a new crafting or refinement recipe.
    /// @param name_ The name of the recipe.
    /// @param requiredIngredients_ An array of IngredientAmount required.
    /// @param requiredFuel_ The amount of FUEL required.
    /// @param successChance_ The probability of success (0-100).
    /// @param basePower_ Base power property for output artifact.
    /// @param baseDurability_ Base durability property for output artifact.
    function addRecipe(
        string memory name_,
        IngredientAmount[] memory requiredIngredients_,
        uint256 requiredFuel_,
        uint256 successChance_,
        uint256 basePower_,
        uint256 baseDurability_,
        bool isRefinement_
    ) public onlyOwner {
        require(bytes(name_).length > 0, "Recipe name required");
        require(successChance_ <= 100, "Success chance > 100");
        for (uint i = 0; i < requiredIngredients_.length; i++) {
             require(_validIngredientTypes[requiredIngredients_[i].id], "Invalid ingredient type in recipe");
        }

        _recipeCount++;
        uint256 newRecipeId = _recipeCount;
        _recipes[newRecipeId] = Recipe(
            newRecipeId,
            name_,
            requiredIngredients_,
            requiredFuel_,
            successChance_,
            basePower_,
            baseDurability_,
            isRefinement_
        );

        emit RecipeAdded(newRecipeId, name_);
    }

    /// @notice Updates an existing crafting or refinement recipe.
    /// @param recipeId_ The ID of the recipe to update.
    /// @param name_ The new name of the recipe.
    /// @param requiredIngredients_ The new required ingredients.
    /// @param requiredFuel_ The new required FUEL.
    /// @param successChance_ The new probability of success (0-100).
    /// @param basePower_ The new base power property.
    /// @param baseDurability_ The new base durability property.
    function updateRecipe(
        uint256 recipeId_,
        string memory name_,
        IngredientAmount[] memory requiredIngredients_,
        uint256 requiredFuel_,
        uint256 successChance_,
        uint256 basePower_,
        uint256 baseDurability_,
        bool isRefinement_
    ) public onlyOwner {
        require(_recipes[recipeId_].id != 0, "Recipe does not exist");
        require(bytes(name_).length > 0, "Recipe name required");
        require(successChance_ <= 100, "Success chance > 100");
        for (uint i = 0; i < requiredIngredients_.length; i++) {
             require(_validIngredientTypes[requiredIngredients_[i].id], "Invalid ingredient type in recipe");
        }

        _recipes[recipeId_] = Recipe(
            recipeId_,
            name_,
            requiredIngredients_,
            requiredFuel_,
            successChance_,
            basePower_,
            baseDurability_,
            isRefinement_
        );

        emit RecipeUpdated(recipeId_, name_);
    }

    /// @notice Removes a crafting recipe.
    /// @param recipeId_ The ID of the recipe to remove.
    function removeRecipe(uint256 recipeId_) public onlyOwner {
        require(_recipes[recipeId_].id != 0, "Recipe does not exist");
        string memory name = _recipes[recipeId_].name;
        delete _recipes[recipeId_]; // Removes from storage
        emit RecipeRemoved(recipeId_, name);
    }

    /// @notice Sets the FUEL cost for the `discoverIngredient` function.
    /// @param cost_ The new FUEL cost (in token decimals).
    function setIngredientDiscoveryCost(uint256 cost_) public onlyOwner {
        _ingredientDiscoveryCost = cost_;
        emit IngredientDiscoveryCostSet(cost_);
    }

    /// @notice Adds or updates the weighted probability for an ingredient type in discovery.
    /// Weights determine the relative chance of discovering an ingredient type.
    /// @param ingredientTypeId_ The ID of the ERC1155 ingredient type.
    /// @param weight_ The new weight for this ingredient type. Set weight to 0 to effectively remove.
    function addIngredientDiscoveryProb(uint256 ingredientTypeId_, uint256 weight_) public onlyOwner {
        require(_validIngredientTypes[ingredientTypeId_], "Invalid ingredient type");

        bool found = false;
        uint256 oldWeight = 0;
        for (uint i = 0; i < _ingredientDiscoveryProbabilities.length; i++) {
            if (_ingredientDiscoveryProbabilities[i].ingredientTypeId == ingredientTypeId_) {
                oldWeight = _ingredientDiscoveryProbabilities[i].weight;
                _ingredientDiscoveryProbabilities[i].weight = weight_;
                found = true;
                break;
            }
        }

        if (!found && weight_ > 0) {
            _ingredientDiscoveryProbabilities.push(IngredientDiscoveryProb({
                ingredientTypeId: ingredientTypeId_,
                weight: weight_
            }));
            _totalDiscoveryWeight += weight_;
        } else if (found) {
             _totalDiscoveryWeight = _totalDiscoveryWeight.sub(oldWeight).add(weight_);
             // If weight became 0, consider removing it from the array to save gas on iteration,
             // but for simplicity here, we'll leave it with weight 0.
        }


        emit IngredientDiscoveryProbAdded(ingredientTypeId_, weight_);
    }

     /// @notice Removes an ingredient type from the discovery probability list.
     /// @param ingredientTypeId_ The ID of the ERC1155 ingredient type.
     function removeIngredientDiscoveryProb(uint256 ingredientTypeId_) public onlyOwner {
        uint256 indexToRemove = type(uint256).max;
        for (uint i = 0; i < _ingredientDiscoveryProbabilities.length; i++) {
            if (_ingredientDiscoveryProbabilities[i].ingredientTypeId == ingredientTypeId_) {
                _totalDiscoveryWeight = _totalDiscoveryWeight.sub(_ingredientDiscoveryProbabilities[i].weight);
                indexToRemove = i;
                break;
            }
        }

        require(indexToRemove != type(uint256).max, "Ingredient type not in discovery probabilities");

        // Remove by swapping with last element and shrinking array
        if (indexToRemove != _ingredientDiscoveryProbabilities.length - 1) {
            _ingredientDiscoveryProbabilities[indexToRemove] = _ingredientDiscoveryProbabilities[_ingredientDiscoveryProbabilities.length - 1];
        }
        _ingredientDiscoveryProbabilities.pop();

        emit IngredientDiscoveryProbRemoved(ingredientTypeId_);
    }


    /// @notice Sets the minimum return rates for salvaging artifacts (in Basis Points).
    /// @param minIngredientReturnBps_ Minimum percentage (0-10000) of ingredients return.
    /// @param minFuelReturnBps_ Minimum percentage (0-10000) of fuel return.
    function setSalvageReturnRates(uint256 minIngredientReturnBps_, uint256 minFuelReturnBps_) public onlyOwner {
        require(minIngredientReturnBps_ <= BPS_DENOMINATOR, "Invalid ingredient return rate");
        require(minFuelReturnBps_ <= BPS_DENOMINATOR, "Invalid fuel return rate");
        _minIngredientReturnBps = minIngredientReturnBps_;
        _minFuelReturnBps = minFuelReturnBps_;
        emit SalvageReturnRatesSet(_minIngredientReturnBps, _minFuelReturnBps);
    }


    /// @notice Pauses the crafting, discovery, and salvage functions.
    function pauseCrafting() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the crafting, discovery, and salvage functions.
    function unpauseCrafting() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accumulated FUEL fees.
    /// @param amount_ The amount of FUEL to withdraw.
    function withdrawFees(uint256 amount_) public onlyOwner {
        require(amount_ > 0, "Amount must be > 0");
        require(address(_fuelToken).balance >= amount_, "Insufficient contract balance"); // Check actual ETH balance if FUEL is ETH, otherwise token balance
         _fuelToken.transfer(owner(), amount_); // Transfer FUEL tokens
        emit FeeWithdrawn(owner(), amount_);
    }

    // --- USER FUNCTIONS ---

    /// @notice Allows a user to spend FUEL to discover random ingredients.
    /// Requires the user to approve the Forge contract to spend FUEL tokens.
    function discoverIngredient() public whenNotPaused {
        require(_ingredientDiscoveryCost > 0, "Discovery is not enabled");
        require(_totalDiscoveryWeight > 0, "No ingredient discovery probabilities set");
        require(address(_fuelToken) != address(0), "FUEL token not set");
        require(address(_ingredientToken) != address(0), "INGREDIENT token not set");

        // Pay discovery cost (requires user approval beforehand)
        _fuelToken.transferFrom(msg.sender, address(this), _ingredientDiscoveryCost);

        // --- PSEUDO-RANDOM INGREDIENT DISCOVERY ---
        // WARNING: This is INSECURE for high-value applications. Use Chainlink VRF or similar in production.
        uint256 randomWeight = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, block.difficulty, _ingredientDiscoveryCost))) % _totalDiscoveryWeight;
        uint256 cumulativeWeight = 0;
        uint256 discoveredIngredientTypeId = 0; // Default or error value
        uint256 discoveredAmount = 0; // Amount to discover

        for (uint i = 0; i < _ingredientDiscoveryProbabilities.length; i++) {
            cumulativeWeight += _ingredientDiscoveryProbabilities[i].weight;
            if (randomWeight < cumulativeWeight) {
                discoveredIngredientTypeId = _ingredientDiscoveryProbabilities[i].ingredientTypeId;
                // Example: Discovered amount could be based on another random roll or a fixed value per ingredient type
                discoveredAmount = (uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, discoveredIngredientTypeId))) % 5) + 1; // Random amount 1-5
                break;
            }
        }

        require(discoveredIngredientTypeId != 0 && discoveredAmount > 0, "Discovery failed to select ingredient"); // Should not happen if probabilities are set correctly

        // Mint discovered ingredients to the user
        _ingredientToken.mint(msg.sender, discoveredIngredientTypeId, discoveredAmount, "");

        emit IngredientDiscovered(msg.sender, discoveredIngredientTypeId, discoveredAmount, _ingredientDiscoveryCost);
    }

    /// @notice Attempts to craft an artifact using a specified recipe.
    /// Requires the user to approve the Forge contract to spend INGREDIENTS and FUEL tokens.
    /// @param recipeId_ The ID of the recipe to use.
    function craftArtifact(uint256 recipeId_) public whenNotPaused {
        Recipe storage recipe = _recipes[recipeId_];
        require(recipe.id != 0, "Recipe does not exist");
        require(!recipe.isRefinement, "This recipe is for refining, not crafting");
        require(address(_ingredientToken) != address(0), "INGREDIENT token not set");
        require(address(_fuelToken) != address(0), "FUEL token not set");
        require(address(_artifactToken) != address(0), "ARTIFACT token not set");

        // Check user balances for ingredients and fuel
        for (uint i = 0; i < recipe.requiredIngredients.length; i++) {
            require(
                _ingredientToken.balanceOf(msg.sender, recipe.requiredIngredients[i].id) >= recipe.requiredIngredients[i].amount,
                "Insufficient ingredient balance"
            );
        }
        require(_fuelToken.balanceOf(msg.sender) >= recipe.requiredFuel, "Insufficient fuel balance");

        emit CraftingAttempt(msg.sender, recipeId_);

        // Consume ingredients (requires user approval beforehand)
        for (uint i = 0; i < recipe.requiredIngredients.length; i++) {
            _ingredientToken.safeTransferFrom(
                msg.sender,
                address(this),
                recipe.requiredIngredients[i].id,
                recipe.requiredIngredients[i].amount,
                "" // Data field for ERC1155
            );
        }

        // Consume fuel (requires user approval beforehand)
        _fuelToken.transferFrom(msg.sender, address(this), recipe.requiredFuel);

        // --- PSEUDO-RANDOM SUCCESS CHECK ---
        // WARNING: This is INSECURE for high-value applications. Use Chainlink VRF or similar in production.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, block.difficulty, recipeId_))) % 100;

        if (randomNumber < recipe.successChance) {
            // Success! Mint the artifact
            uint256 newArtifactId = _nextArtifactId++;
            _artifactToken.safeMint(msg.sender, newArtifactId);

            // Generate and store artifact properties
            _artifactProperties[newArtifactId] = _generateArtifactProperties(recipe);

            emit CraftingSuccess(msg.sender, recipeId_, newArtifactId);
        } else {
            // Failure! Ingredients and fuel are still consumed.
            emit CraftingFailed(msg.sender, recipeId_, "Crafting failed");
        }
    }

     /// @notice Attempts to refine an existing artifact using a specified refinement recipe.
     /// Requires the user to approve the Forge contract to spend INGREDIENTS and FUEL tokens,
     /// and potentially approve burning the existing artifact if the recipe replaces it.
     /// @param artifactTokenId_ The ID of the artifact to refine.
     /// @param recipeId_ The ID of the refinement recipe to use.
    function refineArtifact(uint256 artifactTokenId_, uint256 recipeId_) public whenNotPaused {
        Recipe storage recipe = _recipes[recipeId_];
        require(recipe.id != 0, "Recipe does not exist");
        require(recipe.isRefinement, "This recipe is for crafting, not refining");
        require(address(_ingredientToken) != address(0), "INGREDIENT token not set");
        require(address(_fuelToken) != address(0), "FUEL token not set");
        require(address(_artifactToken) != address(0), "ARTIFACT token not set");
        require(_artifactToken.ownerOf(artifactTokenId_) == msg.sender, "User does not own this artifact");
        require(_artifactProperties[artifactTokenId_].power > 0 || _artifactProperties[artifactTokenId_].durability > 0, "Artifact has no properties (not crafted by this forge?)"); // Basic check

        // Check user balances for ingredients and fuel
        for (uint i = 0; i < recipe.requiredIngredients.length; i++) {
            require(
                _ingredientToken.balanceOf(msg.sender, recipe.requiredIngredients[i].id) >= recipe.requiredIngredients[i].amount,
                "Insufficient ingredient balance"
            );
        }
        require(_fuelToken.balanceOf(msg.sender) >= recipe.requiredFuel, "Insufficient fuel balance");

        emit CraftingAttempt(msg.sender, recipeId_); // Re-using event for refinement attempts

        // Consume ingredients (requires user approval beforehand)
        for (uint i = 0; i < recipe.requiredIngredients.length; i++) {
            _ingredientToken.safeTransferFrom(
                msg.sender,
                address(this),
                recipe.requiredIngredients[i].id,
                recipe.requiredIngredients[i].amount,
                "" // Data field for ERC1155
            );
        }

        // Consume fuel (requires user approval beforehand)
        _fuelToken.transferFrom(msg.sender, address(this), recipe.requiredFuel);

        // --- PSEUDO-RANDOM SUCCESS CHECK ---
        // WARNING: INSECURE randomness.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, block.difficulty, recipeId_, artifactTokenId_))) % 100;

        if (randomNumber < recipe.successChance) {
            // Success! Modify the artifact properties
            ArtifactProperties storage currentProps = _artifactProperties[artifactTokenId_];

            // Example refinement logic: add base properties with some randomness
            uint256 powerIncrease = recipe.basePower.mul((randomNumber % 25) + 75).div(100); // Add 75-100% of base power
            uint256 durabilityIncrease = recipe.baseDurability.mul((randomNumber % 25) + 75).div(100); // Add 75-100% of base durability

            currentProps.power = currentProps.power.add(powerIncrease);
            currentProps.durability = currentProps.durability.add(durabilityIncrease);

            // Optionally, cap max properties or add new types of properties

            emit ArtifactRefined(msg.sender, artifactTokenId_, recipeId_);

        } else {
            // Failure! Ingredients and fuel are still consumed. Artifact is unchanged.
            emit CraftingFailed(msg.sender, recipeId_, "Refinement failed"); // Re-using event for refinement failures
        }
    }


    /// @notice Allows a user to salvage an artifact to recover some resources.
    /// Requires the user to approve the Forge contract to burn the ARTIFACT token.
    /// @param artifactTokenId_ The ID of the artifact to salvage.
    function salvageArtifact(uint256 artifactTokenId_) public whenNotPaused {
        require(address(_artifactToken) != address(0), "ARTIFACT token not set");
        require(_artifactToken.ownerOf(artifactTokenId_) == msg.sender, "User does not own this artifact");
        require(_artifactProperties[artifactTokenId_].power > 0 || _artifactProperties[artifactTokenId_].durability > 0, "Artifact has no properties (cannot salvage?)"); // Ensure it's a craftable artifact

        // Get properties before potentially deleting them
        ArtifactProperties memory props = _artifactProperties[artifactTokenId_];
        delete _artifactProperties[artifactTokenId_]; // Remove properties first

        // Burn the artifact (requires user approval beforehand, e.g., `approve` or `setApprovalForAll`)
        // Note: Standard IERC721 doesn't have `burn`. We assume `_artifactToken` is IERC721Burnable.
        _artifactToken.burn(artifactTokenId_);

        // Calculate return amounts (example logic: based on original recipe costs and artifact properties)
        IngredientAmount[] memory returnedIngredients = new IngredientAmount[](0); // Simplified: Not tracking ingredient types used in original craft in this example
        uint256 returnedFuel = 0;

        // More sophisticated logic would trace back to the recipe that created it,
        // or calculate return based on artifact properties.
        // Simple example: Fixed percentage return based on minimum rates.
        uint256 dummyOriginalFuelCost = _ingredientDiscoveryCost * 2; // Example placeholder
        uint256 dummyOriginalIngredientAmount = 5; // Example placeholder

        returnedFuel = dummyOriginalFuelCost.mul(_minFuelReturnBps).div(BPS_DENOMINATOR);

        // In a real system, you'd return specific ingredient types used.
        // Here, returning a single 'generic' ingredient type (e.g., ID 1).
        if (_validIngredientTypes[1]) { // Check if ingredient type 1 is valid
             uint256 returnedIngredientAmount = dummyOriginalIngredientAmount.mul(_minIngredientReturnBps).div(BPS_DENOMINATOR);
             if (returnedIngredientAmount > 0) {
                 returnedIngredients = new IngredientAmount[](1);
                 returnedIngredients[0] = IngredientAmount({ id: 1, amount: returnedIngredientAmount });
                 _ingredientToken.mint(msg.sender, 1, returnedIngredientAmount, "");
             }
        }


        if (returnedFuel > 0) {
            // Transfer fuel back to user
             _fuelToken.transfer(msg.sender, returnedFuel); // Transfer fuel back
        }


        emit ArtifactSalvaged(msg.sender, artifactTokenId_, returnedFuel, returnedIngredients);
    }

    // --- VIEW FUNCTIONS ---

    /// @notice Gets the details of a specific recipe.
    /// @param recipeId_ The ID of the recipe.
    /// @return The Recipe struct.
    function getRecipe(uint256 recipeId_) public view returns (Recipe memory) {
        require(_recipes[recipeId_].id != 0, "Recipe does not exist");
        return _recipes[recipeId_];
    }

    /// @notice Gets the dynamic properties of a crafted artifact.
    /// @param artifactTokenId_ The token ID of the artifact.
    /// @return The ArtifactProperties struct.
    function getArtifactProperties(uint256 artifactTokenId_) public view returns (ArtifactProperties memory) {
        // Note: Returns default struct if ID has no properties stored (e.g., not forged here, or salvaged)
        return _artifactProperties[artifactTokenId_];
    }

    /// @notice Checks if a user meets the requirements for a specific recipe (balance check).
    /// Does not check for token approvals.
    /// @param user_ The address of the user.
    /// @param recipeId_ The ID of the recipe.
    /// @return bool True if requirements are met, false otherwise.
    /// @return string A message indicating why requirements are not met (empty string if met).
    function checkCraftingRequirements(address user_, uint256 recipeId_) public view returns (bool, string memory) {
        Recipe storage recipe = _recipes[recipeId_];
        if (recipe.id == 0) {
            return (false, "Recipe does not exist");
        }
         if (address(_ingredientToken) == address(0) || address(_fuelToken) == address(0)) {
             return (false, "Token addresses not set");
         }


        for (uint i = 0; i < recipe.requiredIngredients.length; i++) {
            if (_ingredientToken.balanceOf(user_, recipe.requiredIngredients[i].id) < recipe.requiredIngredients[i].amount) {
                return (false, "Insufficient ingredients");
            }
        }
        if (_fuelToken.balanceOf(user_) < recipe.requiredFuel) {
            return (false, "Insufficient fuel");
        }

        return (true, "");
    }

    /// @notice Gets the current ingredient discovery cost.
    /// @return The cost in FUEL tokens.
    function getIngredientDiscoveryCost() public view returns (uint256) {
        return _ingredientDiscoveryCost;
    }

    /// @notice Gets the current ingredient discovery probabilities.
    /// @return An array of IngredientDiscoveryProb structs.
    function getIngredientDiscoveryProbabilities() public view returns (IngredientDiscoveryProb[] memory) {
        return _ingredientDiscoveryProbabilities;
    }

    /// @notice Gets the current minimum salvage return rates.
    /// @return minIngredientReturnBps_ Minimum percentage (0-10000) of ingredients return.
    /// @return minFuelReturnBps_ Minimum percentage (0-10000) of fuel return.
    function getSalvageReturnRates() public view returns (uint256 minIngredientReturnBps_, uint256 minFuelReturnBps_) {
        return (_minIngredientReturnBps, _minFuelReturnBps);
    }

    /// @notice Gets the total number of recipes defined.
    /// @return The total recipe count.
    function getTotalRecipeCount() public view returns (uint256) {
        return _recipeCount;
    }

    /// @notice Gets the total number of valid ingredient types defined.
    /// @return The total valid ingredient type count.
    function getValidIngredientTypeCount() public view returns (uint256) {
        return _validIngredientTypeCount;
    }

     /// @notice Checks if an ingredient type ID is currently marked as valid.
     /// @param ingredientTypeId_ The ID to check.
     /// @return True if valid, false otherwise.
     function isValidIngredientType(uint256 ingredientTypeId_) public view returns (bool) {
        return _validIngredientTypes[ingredientTypeId_];
     }

    /// @notice Gets the current FUEL token balance held by the Forge contract.
    /// This represents accumulated fees/unspent fuel.
    /// @return The contract's FUEL balance.
    function getForgeFuelBalance() public view returns (uint256) {
         if (address(_fuelToken) == address(0)) {
             return 0;
         }
        return _fuelToken.balanceOf(address(this));
    }

    // --- INTERNAL FUNCTIONS ---

    /// @notice Generates dynamic artifact properties based on the recipe.
    /// This is a placeholder; actual logic could be more complex (randomness, input ingredient types).
    /// @param recipe_ The recipe used for crafting.
    /// @return ArtifactProperties struct.
    function _generateArtifactProperties(Recipe storage recipe_) internal view returns (ArtifactProperties memory) {
        // Example simple property generation: base + small random bonus
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, recipe_.id)));
         uint256 bonusPower = recipe_.basePower.mul(randomSeed % 10).div(100); // 0-10% bonus
         uint256 bonusDurability = recipe_.baseDurability.mul(randomSeed % 15).div(100); // 0-15% bonus

        return ArtifactProperties({
            power: recipe_.basePower.add(bonusPower),
            durability: recipe_.baseDurability.add(bonusDurability)
            // Add other properties here
        });
    }

    // --- RECEIVE / FALLBACK ---
    // Optional: Allow receiving native currency if needed, but the contract uses ERC20 FUEL.
    // If FUEL is native currency (ETH), you'd adjust accordingly (payable functions, address(this).balance, msg.value)
    // receive() external payable {
    //     // Handle received ETH if needed
    // }
    // fallback() external payable {
    //     // Handle unexpected calls
    // }


    // The following functions are from ERC721Holder and needed if the contract needs to receive ERC721 tokens
    // (e.g., temporarily holding an artifact before burning/transferring during refine/salvage).
    // Our current salvage/refine logic burns/transfers from the user directly or modifies in place,
    // so ERC721Holder might not be strictly necessary unless the logic changes.
    // If not holding artifacts, remove 'ERC721Holder' inheritance and the `onERC721Received` function.
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
         external override returns (bytes4)
     {
         // Return the ERC721 received magic value
         return this.onERC721Received.selector;
     }

}
```