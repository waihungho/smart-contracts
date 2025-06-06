Okay, let's design a smart contract centered around Digital Alchemy. The concept will involve managing unique digital "Essences" (NFTs) with dynamic states like purity and decay, combining them via "Transmutation" using "Catalysts" (also NFTs) based on known "Recipes," and a mechanic for "Discovery" of new recipes. It will also include time-based mechanics (decay) and role-based access control.

This is a complex system, and implementing it fully would require careful consideration of gas costs, security (especially with complex state changes and token transfers), and potential oracle integration for true randomness or external state influence (which I'll conceptualize but keep simplified for this example).

Here is the proposed structure and functions:

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice for complex state changes potentially involving value transfer or external calls (though minimized here)

/**
 * @title DigitalAlchemy
 * @dev A smart contract for managing digital essences, catalysts, and artifacts
 *      through transmutation, discovery, and time-based decay mechanics.
 *
 * Outline:
 * 1. Contract Details & Dependencies
 * 2. State Variables & Constants
 * 3. Struct Definitions (EssenceState, Recipe)
 * 4. Enum Definitions (AssetType, EssenceType, ArtifactType)
 * 5. Event Declarations
 * 6. Error Declarations
 * 7. Role Definitions (AccessControl)
 * 8. Constructor
 * 9. Modifiers (Pausable, AccessControl)
 * 10. Core Logic Functions (Transmutation, Discovery, Decay, Stabilization)
 * 11. NFT Management Functions (Minting, Burning, BaseURI)
 * 12. Recipe Management Functions (Add, Remove, Get, Preview)
 * 13. State Query Functions (Get Essence State, Decay Status)
 * 14. Admin & Utility Functions (Pause, Unpause, Role Management, Parameter Setting)
 * 15. ERC721 Overrides (to handle internal state)
 *
 * Function Summary (Total: 31 functions + inherited ERC721/AccessControl/Pausable functions):
 *
 * Core Logic:
 * - transmute(uint256[] memory ingredientEssenceIds, uint256 catalystId): Attempts to transmute essences using a catalyst based on recipes. Consumes ingredients/catalyst, mints new asset.
 * - attemptDiscovery(uint256[] memory ingredientEssenceIds, uint256 catalystId): Attempts transmutation with unknown combinations. Might discover a new recipe or yield a random outcome based on probability.
 * - processDecay(uint256 essenceId): Applies decay effects to an essence based on time elapsed since last stabilization/minting.
 * - stabilizeEssence(uint256 essenceId, uint256 stabilizerItemId): Prevents an essence from decaying for a set period by consuming a stabilizer item or fee.
 *
 * NFT Management:
 * - mintInitialEssences(address to, uint256 essenceType, uint256 count, string memory uri): Admin/Minter function to mint starting essences.
 * - mintCatalyst(address to, uint256 catalystType, string memory uri): Admin/Minter function to mint catalysts.
 * - mintArtifact(address to, uint256 artifactType, string memory uri): Internal/Core logic function to mint artifacts as transmutation/discovery outputs.
 * - burnEssence(uint256 essenceId): Internal function to burn essences (e.g., after transmutation/decay).
 * - burnCatalyst(uint256 catalystId): Internal function to burn catalysts.
 * - burnArtifact(uint256 artifactId): Internal function to burn artifacts.
 * - setBaseURI(string memory baseURI_): Admin function to set the base URI for metadata.
 * - setCatalystURI(uint256 catalystType, string memory uri): Admin function to set URI for specific catalyst types. (Could be merged with baseURI, but shows granularity)
 * - setArtifactURI(uint256 artifactType, string memory uri): Admin function to set URI for specific artifact types.
 *
 * Recipe Management:
 * - addRecipe(Recipe memory newRecipe): Admin/Recipe Admin function to add a new transmutation recipe.
 * - removeRecipe(uint256 recipeId): Admin/Recipe Admin function to remove a recipe.
 * - getRecipe(uint256 recipeId): View function to retrieve details of a specific recipe.
 * - previewTransmutation(uint256[] memory ingredientEssenceTypes, uint256 catalystType): View function to check if a combination of types matches any known recipe without requiring token ownership.
 * - listRecipeIds(): View function to list all available recipe IDs.
 *
 * State Query Functions:
 * - getEssenceState(uint256 essenceId): View function to get the detailed state of an essence (purity, stability, timestamps).
 * - checkDecayStatus(uint256 essenceId): View function to check if an essence is currently decayed.
 * - getTimeUntilDecay(uint256 essenceId): View function to calculate time remaining until decay.
 * - isEssenceStable(uint256 essenceId): View function to check if an essence is currently stable.
 * - getAssetType(uint256 tokenId): View function to determine if a token ID is an Essence, Catalyst, or Artifact.
 * - getEssenceType(uint256 essenceId): View function to get the specific type of an essence.
 *
 * Admin & Utility:
 * - pause(): Pauser role function to pause core contract operations.
 * - unpause(): Pauser role function to unpause.
 * - grantRole(bytes32 role, address account): Admin function to grant roles.
 * - revokeRole(bytes32 role, address account): Admin function to revoke roles.
 * - renounceRole(bytes32 role): Users can renounce their own roles. (Inherited from AccessControl but good to list).
 * - setDecayDuration(uint256 duration): Admin function to set the decay duration for essences.
 * - setStabilizationDuration(uint256 duration): Admin function to set how long stabilization lasts.
 * - setDiscoverySuccessRate(uint16 rateBps): Admin function to set the probability of success for discovery attempts (in Basis Points, 0-10000).
 * - withdrawETH(): Admin function to withdraw any accumulated ETH (e.g., from stabilization fees, if implemented).
 *
 * ERC721 Overrides:
 * - _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Internal hook to manage state before transfers (e.g., clearing state on burn).
 */

contract DigitalAlchemy is ERC721URIStorage, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIds; // Global token counter for all asset types

    mapping(uint256 => AssetType) private _assetTypes; // Maps tokenId to its type (Essence, Catalyst, Artifact)
    mapping(uint256 => uint256) private _assetSubtypes; // Maps tokenId to its specific type (EssenceType, CatalystType, ArtifactType)

    // Essence State
    struct EssenceState {
        uint256 purity; // e.g., 100 = 100%
        uint66 lastStabilizedTimestamp; // When it was last stabilized
        uint66 stableUntilTimestamp;    // Until when it is stable
    }
    mapping(uint256 => EssenceState) private _essenceStates; // State specific to Essences

    // Recipes for Transmutation
    struct Recipe {
        uint256 id;
        uint256[] ingredientEssenceTypes; // Required types of essences
        uint256[] ingredientCounts;       // Required counts for each type (must match ingredientEssenceTypes length)
        uint256 requiredCatalystType;     // Required catalyst type
        AssetType outputAssetType;        // Type of output (Essence or Artifact)
        uint256 outputAssetSubtype;       // Specific type/subtype of output
        uint256 outputPurity;             // Purity of output essence (if applicable)
        bool isEnabled;                   // Can this recipe be used?
    }
    mapping(uint256 => Recipe) private _recipes;
    uint256[] private _recipeIds; // Array to keep track of existing recipe IDs

    // Timers and Parameters
    uint256 public essenceDecayDuration = 7 days; // Time after stabilization expires for decay to happen
    uint256 public essenceStabilizationDuration = 30 days; // How long stabilization lasts
    uint16 public discoverySuccessRateBps = 1000; // Success rate for discovery attempts in Basis Points (1000 = 10%)

    // Metadata Management (can be granular per asset type or use base)
    string private _baseTokenURI;
    mapping(uint256 => string) private _catalystURIs; // URI overrides for specific catalyst types
    mapping(uint256 => string) private _artifactURIs; // URI overrides for specific artifact types

    // --- Enums ---

    enum AssetType { Unknown, Essence, Catalyst, Artifact }
    enum EssenceType { UnknownEssence, Fire, Water, Earth, Air, Spirit, Mana, Void } // Example types
    enum CatalystType { UnknownCatalyst, AlchemicalSalt, PhilosophicalStone, PrismaticDust } // Example types
    enum ArtifactType { UnknownArtifact, AmuletOfStability, OrbOfPurity, ShardOfChaos } // Example types

    // --- Events ---

    event AssetMinted(uint256 indexed tokenId, AssetType assetType, uint256 assetSubtype, address indexed owner);
    event AssetBurned(uint256 indexed tokenId, AssetType assetType, uint256 assetSubtype, address indexed owner);
    event TransmutationSuccess(address indexed owner, uint256[] ingredientIds, uint256 catalystId, uint256 outputTokenId, uint256 recipeId);
    event TransmutationFailed(address indexed owner, uint256[] ingredientIds, uint256 catalystId, string reason);
    event RecipeAdded(uint256 indexed recipeId, uint256 indexed outputSubtype);
    event RecipeRemoved(uint256 indexed recipeId);
    event EssenceDecayed(uint256 indexed essenceId, uint256 oldPurity, uint256 newPurity);
    event EssenceStabilized(uint256 indexed essenceId, uint256 stableUntil);
    event DiscoveryAttempt(address indexed owner, uint256[] ingredientIds, uint256 catalystId, bool success, uint256 outputTokenId);
    event ParametersUpdated(string paramName, uint256 newValue);

    // --- Errors ---

    error Unauthorized();
    error ContractPaused();
    error InsufficientIngredients();
    error InvalidCatalyst();
    error IngredientsNotOwnedByCaller();
    error CatalystNotOwnedByCaller();
    error IngredientsDifferentOwners(); // Ingredients must belong to the same owner
    error RecipeNotFound();
    error RecipeDisabled();
    error InvalidAssetTypeForOperation();
    error EssenceAlreadyDecayed();
    error EssenceNotDecayed();
    error EssenceAlreadyStable();
    error StabilizerItemNotFound();
    error StabilizationRequiresItemOrETH(); // If stabilization requires an item or payment
    error InvalidRecipeDefinition();
    error InvalidDiscoveryRate();
    error InvalidEssencePurity(); // For settings/checks related to purity
    error InvalidSubtype();

    // --- Roles ---

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RECIPE_ADMIN_ROLE = keccak256("RECIPE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // Grant the deployer all initial roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(RECIPE_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, _msgSender())) {
            revert Unauthorized();
        }
        _;
    }

    // Use Pausable's whenNotPaused modifier

    // --- Core Logic ---

    /**
     * @dev Attempts to transmute a set of ingredients using a catalyst based on defined recipes.
     * @param ingredientEssenceIds Array of token IDs for essences used as ingredients.
     * @param catalystId Token ID of the catalyst used.
     */
    function transmute(uint256[] memory ingredientEssenceIds, uint256 catalystId)
        external
        payable // Can accept ETH if recipes require it (e.g., for complex transmutations) - though not implemented below
        whenNotPaused
        nonReentrant
    {
        address owner = _msgSender();

        // 1. Basic Checks
        if (ingredientEssenceIds.length == 0) revert InsufficientIngredients();
        if (_assetTypes[catalystId] != AssetType.Catalyst) revert InvalidCatalyst();

        // 2. Ownership Checks
        if (ownerOf(catalystId) != owner) revert CatalystNotOwnedByCaller();
        for (uint i = 0; i < ingredientEssenceIds.length; i++) {
            uint256 essenceId = ingredientEssenceIds[i];
            if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
            if (ownerOf(essenceId) != owner) revert IngredientsNotOwnedByCaller();
        }

        // 3. Gather Ingredient Types and Counts
        mapping(uint256 => uint256) private _tempIngredientCounts; // Temporary mapping for counting ingredient types
        uint256[] memory ingredientTypes = new uint256[](ingredientEssenceIds.length); // To store types for recipe matching
        for (uint i = 0; i < ingredientEssenceIds.length; i++) {
            uint256 essenceId = ingredientEssenceIds[i];
            uint256 essenceType = _assetSubtypes[essenceId];
            ingredientTypes[i] = essenceType;
            _tempIngredientCounts[essenceType]++;
        }
        uint256 catalystType = _assetSubtypes[catalystId];

        // 4. Find Matching Recipe
        uint256 matchedRecipeId = 0;
        for (uint i = 0; i < _recipeIds.length; i++) {
            uint256 recipeId = _recipeIds[i];
            Recipe storage recipe = _recipes[recipeId];

            if (!recipe.isEnabled) continue;
            if (recipe.requiredCatalystType != catalystType) continue;

            bool ingredientsMatch = true;
            if (recipe.ingredientEssenceTypes.length != ingredientTypes.length) {
                 ingredientsMatch = false; // Quick check: need same number of unique types
            } else {
                 // Check if required ingredient types and counts match
                 mapping(uint256 => uint256) private _tempRecipeCounts; // Temporary mapping for recipe ingredient counts
                 for(uint j=0; j < recipe.ingredientEssenceTypes.length; j++) {
                     _tempRecipeCounts[recipe.ingredientEssenceTypes[j]] = recipe.ingredientCounts[j];
                 }

                 // Check if caller's ingredients match recipe requirements
                 for(uint j=0; j < ingredientTypes.length; j++) {
                    uint256 type_ = ingredientTypes[j];
                    if (_tempIngredientCounts[type_] == 0 || _tempIngredientCounts[type_] != _tempRecipeCounts[type_]) {
                        ingredientsMatch = false;
                        break;
                    }
                     // Mark as checked
                     _tempRecipeCounts[type_] = 0;
                 }
                 // Ensure all required recipe ingredients were present in the caller's ingredients
                 if (ingredientsMatch) {
                     for(uint j=0; j < recipe.ingredientEssenceTypes.length; j++) {
                         if(_tempRecipeCounts[recipe.ingredientEssenceTypes[j]] != 0) {
                             ingredientsMatch = false;
                             break;
                         }
                     }
                 }
            }


            if (ingredientsMatch) {
                matchedRecipeId = recipeId;
                break; // Found a match, exit loop
            }
        }

        if (matchedRecipeId == 0) {
            emit TransmutationFailed(owner, ingredientEssenceIds, catalystId, "No matching recipe found");
            revert RecipeNotFound(); // Or potentially proceed to attemptDiscovery automatically? For now, fail.
        }

        // 5. Execute Transmutation (Consume & Mint)
        Recipe storage matchedRecipe = _recipes[matchedRecipeId];

        // Burn Ingredients
        for (uint i = 0; i < ingredientEssenceIds.length; i++) {
            _burnEssence(ingredientEssenceIds[i]); // Internal burn handling state cleanup
        }

        // Burn Catalyst
        _burnCatalyst(catalystId); // Internal burn

        // Mint Output
        uint256 outputTokenId = 0;
        if (matchedRecipe.outputAssetType == AssetType.Essence) {
            outputTokenId = _mintEssence(owner, matchedRecipe.outputAssetSubtype, matchedRecipe.outputPurity);
        } else if (matchedRecipe.outputAssetType == AssetType.Artifact) {
            outputTokenId = _mintArtifact(owner, matchedRecipe.outputAssetSubtype);
        } else {
             // This shouldn't happen with current enums, but safety check
            emit TransmutationFailed(owner, ingredientEssenceIds, catalystId, "Invalid output asset type in recipe");
            revert InvalidRecipeDefinition();
        }

        emit TransmutationSuccess(owner, ingredientEssenceIds, catalystId, outputTokenId, matchedRecipeId);
    }


    /**
     * @dev Allows users to attempt discovering new recipes by trying ingredient/catalyst combinations.
     *      Outcome is probabilistic based on discoverySuccessRateBps.
     *      Note: This simplified version doesn't actually reveal/add a recipe to _recipes,
     *      but could potentially mint a special "Discovery" artifact or a random output.
     *      A more advanced version could interact with off-chain systems or multi-sig for recipe addition.
     * @param ingredientEssenceIds Array of token IDs for essences used.
     * @param catalystId Token ID of the catalyst used.
     */
    function attemptDiscovery(uint256[] memory ingredientEssenceIds, uint256 catalystId)
        external
        whenNotPaused
        nonReentrant
    {
        address owner = _msgSender();

         // Basic and Ownership Checks (similar to transmute, simplified)
        if (ingredientEssenceIds.length == 0) revert InsufficientIngredients();
        if (_assetTypes[catalystId] != AssetType.Catalyst) revert InvalidCatalyst();
        if (ownerOf(catalystId) != owner) revert CatalystNotOwnedByCaller();
        for (uint i = 0; i < ingredientEssenceIds.length; i++) {
            uint256 essenceId = ingredientEssenceIds[i];
            if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
            if (ownerOf(essenceId) != owner) revert IngredientsNotOwnedByCaller();
        }

        // Burn ingredients and catalyst regardless of success - this is a risky attempt!
        for (uint i = 0; i < ingredientEssenceIds.length; i++) {
             _burnEssence(ingredientEssenceIds[i]);
        }
        _burnCatalyst(catalystId);


        // Determine Success (simplified randomness using blockhash or Chainlink VRF for production)
        // WARNING: block.timestamp and block.difficulty (or block.number) are susceptible to miner manipulation.
        // For production, integrate Chainlink VRF or a similar secure randomness solution.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, ingredientEssenceIds, catalystId))) % 10000;

        uint256 outputTokenId = 0;
        bool success = randomNumber < discoverySuccessRateBps;

        if (success) {
            // Example Success: Mint a random high-purity Essence or a specific Artifact
            // In a real system, this might depend on the *input* types/counts
            // For simplicity, mint a high-purity Spirit Essence or an OrbOfPurity
            if (randomNumber % 2 == 0) { // 50% chance of Essence vs Artifact on success
                 outputTokenId = _mintEssence(owner, uint256(EssenceType.Spirit), 95); // Example random high-purity output
            } else {
                 outputTokenId = _mintArtifact(owner, uint256(ArtifactType.OrbOfPurity)); // Example discovery artifact
            }
        } else {
            // Example Failure: Nothing is minted, resources are just consumed.
             // Could potentially mint a "Waste" token or give a small amount of a common resource instead.
        }

        emit DiscoveryAttempt(owner, ingredientEssenceIds, catalystId, success, outputTokenId);
    }

    /**
     * @dev Checks and applies decay to an essence if overdue for decay and not stable.
     *      Can be called by anyone to process the decay for a specific essence,
     *      incentivizing users/bots to keep the state updated.
     * @param essenceId The ID of the essence to process decay for.
     */
    function processDecay(uint256 essenceId) external whenNotPaused nonReentrant {
        if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();

        EssenceState storage state = _essenceStates[essenceId];
        uint256 currentPurity = state.purity;

        // Check if it's stable or already fully decayed (purity 0)
        if (state.stableUntilTimestamp > block.timestamp || currentPurity == 0) {
            revert EssenceAlreadyStable(); // Or NotDecayed if already stable
        }

        // Check if it's actually overdue for decay processing
        // Decay is processed if current timestamp is past stableUntil + decayDuration
        if (block.timestamp < state.stableUntilTimestamp + essenceDecayDuration) {
             revert EssenceNotDecayed();
        }

        // Apply Decay Effect (Example: Reduce purity)
        // In a more complex system, decay could be staged, leading to burning,
        // changing type, or becoming unusable as ingredient.
        uint256 oldPurity = state.purity;
        uint256 newPurity = 0; // Example: Single stage decay reduces purity to 0

        state.purity = newPurity;
        // Reset stabilization timestamps after decay? Depends on desired mechanic.
        // state.lastStabilizedTimestamp = uint64(block.timestamp);
        // state.stableUntilTimestamp = uint64(block.timestamp); // Or leave them as they were.

        emit EssenceDecayed(essenceId, oldPurity, newPurity);

        // Optional: If purity reaches 0, burn the essence automatically
        if (newPurity == 0) {
             address owner = ownerOf(essenceId); // Get owner before burning
             _burnEssence(essenceId);
             emit AssetBurned(essenceId, AssetType.Essence, _assetSubtypes[essenceId], owner); // Re-emit burn event specifically
        }
    }

    /**
     * @dev Stabilizes an essence, preventing decay for a set period.
     *      Requires consuming a specific stabilizer item or payment (payment not implemented).
     * @param essenceId The ID of the essence to stabilize.
     * @param stabilizerItemId The ID of the item used for stabilization (e.g., a specific Catalyst or other NFT).
     */
    function stabilizeEssence(uint256 essenceId, uint256 stabilizerItemId) external whenNotPaused nonReentrant {
        address owner = _msgSender();

        if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
        if (ownerOf(essenceId) != owner) revert IngredientsNotOwnedByCaller();

        EssenceState storage state = _essenceStates[essenceId];
        // Check if already stable and the current stabilization hasn't expired yet
        if (state.stableUntilTimestamp > block.timestamp) {
            revert EssenceAlreadyStable();
        }

        // Check and consume stabilizer item (Example: Requires a specific Catalyst type)
        if (_assetTypes[stabilizerItemId] != AssetType.Catalyst) revert InvalidCatalyst();
        if (ownerOf(stabilizerItemId) != owner) revert CatalystNotOwnedByCaller();

        // Example: Require a Catalyst of type PhilosophicalStone (ID 2) for stabilization
        if (_assetSubtypes[stabilizerItemId] != uint256(CatalystType.PhilosophicalStone)) {
             revert StabilizerItemNotFound(); // Or more specific error like InvalidStabilizerItem
        }

        // Burn the stabilizer item
        _burnCatalyst(stabilizerItemId);

        // Update stabilization state
        state.lastStabilizedTimestamp = uint64(block.timestamp);
        state.stableUntilTimestamp = uint64(block.timestamp + essenceStabilizationDuration); // Extend stability

        emit EssenceStabilized(essenceId, state.stableUntilTimestamp);
    }

    // --- NFT Management ---

    /**
     * @dev Mints initial essences. Restricted to MINTER_ROLE.
     * @param to The recipient address.
     * @param essenceType The subtype of the essence.
     * @param count The number of essences to mint.
     * @param uri Specific URI for these initial essences (optional).
     */
    function mintInitialEssences(address to, uint256 essenceType, uint256 count, string memory uri) external onlyRole(MINTER_ROLE) whenNotPaused {
         if (essenceType == uint256(EssenceType.UnknownEssence)) revert InvalidSubtype();
         for (uint i = 0; i < count; i++) {
             uint256 newTokenId = _mintEssence(to, essenceType, 100); // Initial purity 100
             if (bytes(uri).length > 0) {
                 _setTokenURI(newTokenId, uri); // Set specific URI if provided
             }
         }
    }

    /**
     * @dev Mints catalysts. Restricted to MINTER_ROLE.
     * @param to The recipient address.
     * @param catalystType The subtype of the catalyst.
     * @param uri Specific URI for this catalyst (optional, can be overridden by _catalystURIs).
     */
    function mintCatalyst(address to, uint256 catalystType, string memory uri) external onlyRole(MINTER_ROLE) whenNotPaused {
         if (catalystType == uint256(CatalystType.UnknownCatalyst)) revert InvalidSubtype();
         uint256 newTokenId = _tokenIds.current();
         _tokenIds.increment();
         _safeMint(to, newTokenId);

         _assetTypes[newTokenId] = AssetType.Catalyst;
         _assetSubtypes[newTokenId] = catalystType;

         if (bytes(uri).length > 0) {
             _setTokenURI(newTokenId, uri);
         }

         emit AssetMinted(newTokenId, AssetType.Catalyst, catalystType, to);
    }

    /**
     * @dev Mints artifacts. Intended for internal use during transmutation/discovery.
     * @param to The recipient address.
     * @param artifactType The subtype of the artifact.
     * @return The token ID of the minted artifact.
     */
    function _mintArtifact(address to, uint256 artifactType) internal returns (uint256) {
         if (artifactType == uint256(ArtifactType.UnknownArtifact)) revert InvalidSubtype();
         uint256 newTokenId = _tokenIds.current();
         _tokenIds.increment();
         _safeMint(to, newTokenId);

         _assetTypes[newTokenId] = AssetType.Artifact;
         _assetSubtypes[newTokenId] = artifactType;

         // Artifact URI is typically set via setArtifactURI or base URI + type
         // _setTokenURI is handled by tokenURI logic

         emit AssetMinted(newTokenId, AssetType.Artifact, artifactType, to);
         return newTokenId;
    }

     /**
     * @dev Mints essences. Intended for internal use during initial minting or transmutation.
     * @param to The recipient address.
     * @param essenceType The subtype of the essence.
     * @param purity The initial purity of the essence.
     * @return The token ID of the minted essence.
     */
    function _mintEssence(address to, uint256 essenceType, uint256 purity) internal returns (uint256) {
         if (essenceType == uint256(EssenceType.UnknownEssence)) revert InvalidSubtype();
         if (purity > 100) revert InvalidEssencePurity();

         uint256 newTokenId = _tokenIds.current();
         _tokenIds.increment();
         _safeMint(to, newTokenId);

         _assetTypes[newTokenId] = AssetType.Essence;
         _assetSubtypes[newTokenId] = essenceType;
         _essenceStates[newTokenId] = EssenceState({
             purity: purity,
             lastStabilizedTimestamp: uint64(block.timestamp), // Stable initially upon mint
             stableUntilTimestamp: uint64(block.timestamp + essenceStabilizationDuration) // Stable for duration
         });

         // Essence URI is typically handled by tokenURI logic

         emit AssetMinted(newTokenId, AssetType.Essence, essenceType, to);
         return newTokenId;
    }

    /**
     * @dev Internal function to burn an essence and clean up its state.
     * @param essenceId The ID of the essence to burn.
     */
    function _burnEssence(uint256 essenceId) internal {
        address owner = ownerOf(essenceId); // Get owner before burning
        _burn(essenceId); // Standard ERC721 burn
        // State cleanup is handled in _beforeTokenTransfer hook
        emit AssetBurned(essenceId, AssetType.Essence, _assetSubtypes[essenceId], owner);
    }

     /**
     * @dev Internal function to burn a catalyst and clean up its state.
     * @param catalystId The ID of the catalyst to burn.
     */
    function _burnCatalyst(uint256 catalystId) internal {
        address owner = ownerOf(catalystId); // Get owner before burning
        _burn(catalystId); // Standard ERC721 burn
        // State cleanup is handled in _beforeTokenTransfer hook
         emit AssetBurned(catalystId, AssetType.Catalyst, _assetSubtypes[catalystId], owner);
    }

      /**
     * @dev Internal function to burn an artifact and clean up its state.
     * @param artifactId The ID of the artifact to burn.
     */
    function _burnArtifact(uint256 artifactId) internal {
        address owner = ownerOf(artifactId); // Get owner before burning
        _burn(artifactId); // Standard ERC721 burn
        // State cleanup is handled in _beforeTokenTransfer hook
         emit AssetBurned(artifactId, AssetType.Artifact, _assetSubtypes[artifactId], owner);
    }

    /**
     * @dev Sets the base URI for all token IDs. Can be overridden by type-specific URIs.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI_;
    }

     /**
     * @dev Sets a specific URI for a catalyst type, overriding the base URI.
     * @param catalystType The subtype of the catalyst.
     * @param uri The specific URI for this type.
     */
    function setCatalystURI(uint256 catalystType, string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _catalystURIs[catalystType] = uri;
    }

      /**
     * @dev Sets a specific URI for an artifact type, overriding the base URI.
     * @param artifactType The subtype of the artifact.
     * @param uri The specific URI for this type.
     */
    function setArtifactURI(uint256 artifactType, string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _artifactURIs[artifactType] = uri;
    }

    // --- Recipe Management ---

    /**
     * @dev Adds a new transmutation recipe. Restricted to RECIPE_ADMIN_ROLE.
     * @param newRecipe The Recipe struct containing details.
     */
    function addRecipe(Recipe memory newRecipe) external onlyRole(RECIPE_ADMIN_ROLE) whenNotPaused {
        // Basic validation
        if (newRecipe.ingredientEssenceTypes.length != newRecipe.ingredientCounts.length) {
            revert InvalidRecipeDefinition();
        }
        if (newRecipe.outputAssetType == AssetType.Unknown) {
             revert InvalidRecipeDefinition();
        }
        if (newRecipe.outputAssetType == AssetType.Essence && newRecipe.outputAssetSubtype == uint256(EssenceType.UnknownEssence)) {
             revert InvalidSubtype();
        }
         if (newRecipe.outputAssetType == AssetType.Artifact && newRecipe.outputAssetSubtype == uint256(ArtifactType.UnknownArtifact)) {
             revert InvalidSubtype();
        }


        uint256 newRecipeId = _recipeIds.length + 1; // Simple sequential ID
        newRecipe.id = newRecipeId;
        newRecipe.isEnabled = true; // Recipes are enabled by default upon creation

        _recipes[newRecipeId] = newRecipe;
        _recipeIds.push(newRecipeId);

        emit RecipeAdded(newRecipeId, newRecipe.outputAssetSubtype);
    }

    /**
     * @dev Removes or disables a recipe. Restricted to RECIPE_ADMIN_ROLE.
     *      Note: This implementation disables the recipe, not truly removes it from storage
     *      to avoid state corruption with existing IDs. A more robust system might require
     *      careful mapping updates or recipe versioning.
     * @param recipeId The ID of the recipe to remove/disable.
     */
    function removeRecipe(uint256 recipeId) external onlyRole(RECIPE_ADMIN_ROLE) whenNotPaused {
        if (_recipes[recipeId].id == 0) revert RecipeNotFound(); // Check if recipe exists

        // Mark as disabled rather than deleting from mapping
        _recipes[recipeId].isEnabled = false;

        emit RecipeRemoved(recipeId);
    }

    /**
     * @dev Gets the details of a specific recipe.
     * @param recipeId The ID of the recipe.
     * @return The Recipe struct.
     */
    function getRecipe(uint256 recipeId) external view returns (Recipe memory) {
        if (_recipes[recipeId].id == 0) revert RecipeNotFound();
        return _recipes[recipeId];
    }

     /**
     * @dev Returns the list of all available recipe IDs.
     */
    function listRecipeIds() external view returns (uint256[] memory) {
        // Filter out disabled recipes if needed, but returning all IDs is simpler
        return _recipeIds;
    }

     /**
     * @dev Allows previewing if a set of ingredient/catalyst *types* matches an enabled recipe.
     *      Does not check ownership or consume items. Useful for UI.
     * @param ingredientEssenceTypes Array of essence subtypes.
     * @param catalystType Catalyst subtype.
     * @return recipeId The ID of the matching recipe, or 0 if none found.
     * @return outputAssetType The type of the output asset.
     * @return outputAssetSubtype The subtype of the output asset.
     */
    function previewTransmutation(uint256[] memory ingredientEssenceTypes, uint256 catalystType)
        external
        view
        returns (uint256 recipeId, AssetType outputAssetType, uint256 outputAssetSubtype)
    {
         if (ingredientEssenceTypes.length == 0) return (0, AssetType.Unknown, 0);

        // Count ingredient types for comparison
        mapping(uint256 => uint256) private _tempIngredientCounts;
        for (uint i = 0; i < ingredientEssenceTypes.length; i++) {
            _tempIngredientCounts[ingredientEssenceTypes[i]]++;
        }

        // Find Matching Recipe (Logic similar to transmute but using input types directly)
        for (uint i = 0; i < _recipeIds.length; i++) {
            uint256 currentRecipeId = _recipeIds[i];
            Recipe storage recipe = _recipes[currentRecipeId];

            if (!recipe.isEnabled) continue;
            if (recipe.requiredCatalystType != catalystType) continue;

             bool ingredientsMatch = true;
            if (recipe.ingredientEssenceTypes.length != ingredientEssenceTypes.length) {
                 ingredientsMatch = false;
            } else {
                 mapping(uint256 => uint256) private _tempRecipeCounts;
                 for(uint j=0; j < recipe.ingredientEssenceTypes.length; j++) {
                     _tempRecipeCounts[recipe.ingredientEssenceTypes[j]] = recipe.ingredientCounts[j];
                 }

                 for(uint j=0; j < ingredientEssenceTypes.length; j++) {
                    uint256 type_ = ingredientEssenceTypes[j];
                    if (_tempIngredientCounts[type_] == 0 || _tempIngredientCounts[type_] != _tempRecipeCounts[type_]) {
                        ingredientsMatch = false;
                        break;
                    }
                     _tempRecipeCounts[type_] = 0;
                 }
                 if (ingredientsMatch) {
                     for(uint j=0; j < recipe.ingredientEssenceTypes.length; j++) {
                         if(_tempRecipeCounts[recipe.ingredientEssenceTypes[j]] != 0) {
                             ingredientsMatch = false;
                             break;
                         }
                     }
                 }
            }


            if (ingredientsMatch) {
                // Found a match
                return (currentRecipeId, recipe.outputAssetType, recipe.outputAssetSubtype);
            }
        }

        // No recipe found
        return (0, AssetType.Unknown, 0);
    }


    // --- State Query Functions ---

    /**
     * @dev Gets the detailed state of an essence.
     * @param essenceId The ID of the essence.
     * @return The EssenceState struct.
     */
    function getEssenceState(uint256 essenceId) external view returns (EssenceState memory) {
        if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
        return _essenceStates[essenceId];
    }

    /**
     * @dev Checks if an essence is currently decayed (purity 0 in this example).
     * @param essenceId The ID of the essence.
     * @return True if decayed, false otherwise.
     */
    function checkDecayStatus(uint256 essenceId) external view returns (bool) {
        if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
        // Note: This doesn't automatically *process* decay, just reports current state based on purity.
        // A more complex state could track decay level.
        return _essenceStates[essenceId].purity == 0;
    }

     /**
     * @dev Calculates the time remaining until an essence decays, considering its stability period.
     *      Returns 0 if already decayed or stable indefinitely (not applicable here).
     * @param essenceId The ID of the essence.
     * @return Time in seconds until decay. Returns 0 if already decayed or stable.
     */
    function getTimeUntilDecay(uint256 essenceId) external view returns (uint256) {
         if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
         EssenceState storage state = _essenceStates[essenceId];

         if (state.purity == 0) return 0; // Already decayed

         uint256 decayBeginsTimestamp = state.stableUntilTimestamp;

         if (block.timestamp < decayBeginsTimestamp) {
             // Still stable
             return (decayBeginsTimestamp + essenceDecayDuration) - block.timestamp;
         } else {
             // Stability expired, check if decay has completed
             uint256 decayCompletionTimestamp = decayBeginsTimestamp + essenceDecayDuration;
             if (block.timestamp < decayCompletionTimestamp) {
                 // Decay in progress (conceptually, if decay were multi-stage)
                 // For this single-stage decay, it means it *can* be processed now
                 // Returning 1 indicates it's ready for processDecay
                 return 1; // Or a different indicator
             } else {
                 // Decay period fully elapsed
                 return 0; // Or indicate it's past due for processing
             }
         }
    }


    /**
     * @dev Checks if an essence is currently stable (within its stableUntilTimestamp).
     * @param essenceId The ID of the essence.
     * @return True if stable, false otherwise.
     */
    function isEssenceStable(uint256 essenceId) external view returns (bool) {
        if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
        return _essenceStates[essenceId].stableUntilTimestamp > block.timestamp;
    }


     /**
     * @dev Gets the specific subtype of an essence.
     * @param essenceId The ID of the essence.
     * @return The essence subtype (as uint256).
     */
    function getEssenceType(uint256 essenceId) external view returns (uint256) {
         if (_assetTypes[essenceId] != AssetType.Essence) revert InvalidAssetTypeForOperation();
         return _assetSubtypes[essenceId];
    }

      /**
     * @dev Gets the asset type (Essence, Catalyst, Artifact) for a given token ID.
     * @param tokenId The ID of the token.
     * @return The AssetType enum value.
     */
    function getAssetType(uint256 tokenId) external view returns (AssetType) {
        return _assetTypes[tokenId];
    }


    // --- Admin & Utility ---

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // AccessControl's grantRole, revokeRole, renounceRole functions are public/external
    // and inherit DEFAULT_ADMIN_ROLE control by default.
    // Listing them here as they are part of the >= 20 functions requirement.
    // function grantRole(bytes32 role, address account) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) { super.grantRole(role, account); }
    // function revokeRole(bytes32 role, address account) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) { super.revokeRole(role, account); }
    // function renounceRole(bytes32 role) external virtual override { super.renounceRole(role); }

    /**
     * @dev Sets the duration after stability expires when decay can be processed.
     * @param duration Duration in seconds.
     */
    function setDecayDuration(uint256 duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        essenceDecayDuration = duration;
        emit ParametersUpdated("essenceDecayDuration", duration);
    }

     /**
     * @dev Sets how long an essence remains stable after stabilization.
     * @param duration Duration in seconds.
     */
    function setStabilizationDuration(uint256 duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        essenceStabilizationDuration = duration;
        emit ParametersUpdated("essenceStabilizationDuration", duration);
    }

     /**
     * @dev Sets the success rate for discovery attempts.
     * @param rateBps Rate in Basis Points (0-10000).
     */
    function setDiscoverySuccessRate(uint16 rateBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (rateBps > 10000) revert InvalidDiscoveryRate();
        discoverySuccessRateBps = rateBps;
        emit ParametersUpdated("discoverySuccessRateBps", rateBps);
    }

    /**
     * @dev Allows the contract admin to withdraw any ETH held by the contract.
     *      Useful if stabilization or other functions collected ETH fees.
     *      NOTE: Stabilization currently does not collect ETH in this example.
     */
    function withdrawETH() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }


    // --- ERC721 Overrides ---

    /**
     * @dev See {ERC721URIStorage-tokenURI}.
     *      Custom logic to handle different URIs based on AssetType and Subtype.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // ERC721URIStorage requires baseURI/tokenURI to be set for *all* tokens.
        // We handle this internally based on asset type.

        _requireOwned(tokenId); // Ensure token exists and is not burned

        AssetType assetType = _assetTypes[tokenId];
        uint256 assetSubtype = _assetSubtypes[tokenId];

        string memory specificURI = "";

        if (assetType == AssetType.Essence) {
            // Essence URI could be based on base URI + type + purity?
            // For simplicity, just use base URI + tokenId or a type-specific path
            // Let's use base URI + type for now.
            // A more complex system might use a dedicated metadata service/gateway.
            string memory typeString = "";
             if (assetSubtype == uint256(EssenceType.Fire)) typeString = "fire/";
             else if (assetSubtype == uint256(EssenceType.Water)) typeString = "water/";
             // Add more types...
             else typeString = "essence/";

             // Concatenate base URI, type path, and token ID (or metadata file name)
             // This is a simplified example. Proper metadata requires a JSON file link.
             // Usually it's base_uri + token_id.json
             // For this example, let's just return a placeholder or baseURI.
             specificURI = string(abi.encodePacked(_baseTokenURI, "essence/", Strings.toString(tokenId)));


        } else if (assetType == AssetType.Catalyst) {
            specificURI = _catalystURIs[assetSubtype];
             if (bytes(specificURI).length == 0) {
                 // Fallback to base URI + catalyst path + tokenId
                 specificURI = string(abi.encodePacked(_baseTokenURI, "catalyst/", Strings.toString(tokenId)));
             }

        } else if (assetType == AssetType.Artifact) {
            specificURI = _artifactURIs[assetSubtype];
             if (bytes(specificURI).length == 0) {
                  // Fallback to base URI + artifact path + tokenId
                 specificURI = string(abi.encodePacked(_baseTokenURI, "artifact/", Strings.toString(tokenId)));
             }
        }

        if (bytes(specificURI).length > 0) {
            return specificURI;
        } else {
            // Fallback if no specific or base URI is set
            return super.tokenURI(tokenId); // This will likely revert if no _tokenURIs are set
        }
    }


    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *      Used here primarily to clean up custom state (`_assetTypes`, `_assetSubtypes`, `_essenceStates`)
     *      when tokens are burned.
     *      Note: This hook is called for minting, transferring, and burning.
     *      'from' is address(0) on mint, 'to' is address(0) on burn.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721URIStorage) // List all direct parent contracts with this function
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If burning (transfer to address(0))
        if (to == address(0)) {
            AssetType assetType = _assetTypes[tokenId];

            // Clean up state based on asset type
            if (assetType == AssetType.Essence) {
                 delete _essenceStates[tokenId];
            }
            // No specific state to clean for Catalyst or Artifact beyond the basic mappings

            // Clean up general asset type mappings
            delete _assetTypes[tokenId];
            delete _assetSubtypes[tokenId];

             // ERC721URIStorage cleans up _tokenURIs mapping automatically if used

        }
         // No special handling needed for minting or standard transfers in this example
    }

    // The following functions are inherited from ERC721, AccessControl, Pausable
    // and contribute to the function count:
    // ERC721: supportsInterface, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, safeTransferFrom (2 overloads), transferFrom
    // AccessControl: hasRole, getRoleAdmin, grantRole, revokeRole, renounceRole, supportsInterface (again, but handles different ids)
    // Pausable: paused
    // Total inherited external/public functions are numerous, easily exceeding 20 combined with custom ones.
    // Let's list the key distinct functions implemented or significantly overridden:
    // 1. transmute
    // 2. attemptDiscovery
    // 3. processDecay
    // 4. stabilizeEssence
    // 5. mintInitialEssences
    // 6. mintCatalyst
    // 7. addRecipe
    // 8. removeRecipe
    // 9. getRecipe
    // 10. previewTransmutation
    // 11. listRecipeIds
    // 12. getEssenceState
    // 13. checkDecayStatus
    // 14. getTimeUntilDecay
    // 15. isEssenceStable
    // 16. getEssenceType
    // 17. getAssetType
    // 18. pause
    // 19. unpause
    // 20. setBaseURI
    // 21. setCatalystURI
    // 22. setArtifactURI
    // 23. setDecayDuration
    // 24. setStabilizationDuration
    // 25. setDiscoverySuccessRate
    // 26. withdrawETH
    // 27. tokenURI (override)
    // (+ internal mint/burn helpers, and inherited roles functions like grant/revoke/renounce and basic ERC721 ops)
    // Yes, we have more than 20 distinct, non-trivial functions implemented or specifically listed/overridden.

    // Fallback/Receive functions can be added if ETH is accepted without specific payable functions,
    // but withdrawETH already handles the current balance.
    // receive() external payable {}
    // fallback() external payable {}

}
```