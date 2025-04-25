Okay, let's create a smart contract concept that's a bit more involved than standard tokens or simple interactions. We'll build a "Quantum Alchemy Lab" where users can combine unique digital "Essences" (NFTs) based on recipes, influenced by a dynamic "Quantum Flux" state, with possibilities of probabilistic outcomes and changing Essence properties.

This concept uses:
*   ERC-721 for unique Essences.
*   On-chain "recipes" for combination.
*   A simulated "Quantum Flux" influencing outcomes (using block data, acknowledging its limitations for true randomness/unpredictability).
*   Probabilistic outcomes for alchemy.
*   Dynamic properties for Essences that can be "Observed" or "Collapsed".
*   Owner/Admin controls for recipe management and flux simulation (for testing/initial state).

**Disclaimer:** The on-chain randomness/flux generation using block data is *not* cryptographically secure and is predictable to miners. For production, a Chainlink VRF or similar oracle would be required for unpredictable outcomes. This example uses block data for illustrative purposes of an on-chain influencing factor. This contract is also complex and resource-intensive for on-chain execution.

---

### Smart Contract Outline: Quantum Alchemy Lab

1.  **Contract Name:** `QuantumAlchemy`
2.  **Inheritance:** ERC721, Ownable, Pausable
3.  **Core Concept:** Users combine unique "Essence" NFTs based on defined "Recipes", influenced by a fluctuating "Quantum Flux". Outcomes can be probabilistic, and Essences have dynamic properties.
4.  **State Variables:**
    *   Essence data (mapping NFT ID to properties)
    *   Recipe data (mapping recipe ID to inputs, output, probabilities, flux range)
    *   Quantum Flux value
    *   Counters for NFT IDs and Recipe IDs
    *   Base URI for NFT metadata
5.  **Structs:**
    *   `EssenceProperties`: Defines the type and state (observed, collapsed) of an Essence.
    *   `Recipe`: Defines required inputs, potential output, success chance, and required flux range for an alchemy operation.
6.  **Events:**
    *   `EssenceMinted`: When a new Essence NFT is created.
    *   `AlchemyPerformed`: When an alchemy attempt is made.
    *   `AlchemySuccess`: When alchemy successfully yields an output.
    *   `AlchemyFailure`: When alchemy fails.
    *   `RecipeAdded`: When a new recipe is added.
    *   `RecipeUpdated`: When a recipe is modified.
    *   `RecipeRemoved`: When a recipe is removed.
    *   `EssenceObserved`: When an Essence's properties are observed.
    *   `EssenceCollapsed`: When an Essence's properties are collapsed.
    *   `FluxUpdated`: When the Quantum Flux value changes (via simulation/block).
7.  **Functions:**
    *   Standard ERC721 functions (8+)
    *   Minting functions (Initial, Random)
    *   Alchemy execution function
    *   Recipe management functions (Add, Update, Remove, Get, List)
    *   Essence state functions (Observe, Collapse, Get Properties, Check State)
    *   Flux related functions (Get Current, Simulate - if owner-controlled for testing)
    *   Querying functions (Recipe details, Essence details, Flux value, etc.)
    *   Admin functions (Pause, Unpause, Set Base URI)
    *   Internal helper functions (Generate random, Check recipe, Burn inputs, Mint output).

---

### Function Summary:

1.  `constructor(string memory name, string memory symbol, string memory initialBaseURI)`: Initializes the ERC721 contract, Ownable, and Pausable. Sets the initial metadata URI.
2.  `mintInitialEssence(address recipient, uint256 essenceType)`: (Owner only) Mints a new Essence NFT of a specific type to a recipient.
3.  `mintRandomEssence(address recipient)`: (Owner only) Mints a new Essence NFT of a randomly determined type to a recipient. Uses internal randomness.
4.  `addRecipe(uint256[] calldata inputEssenceTypes, uint256 outputEssenceType, uint256 successChanceBasisPoints, uint256 minFlux, uint256 maxFlux)`: (Owner only) Adds a new alchemy recipe. `successChanceBasisPoints` is chance out of 10000. `minFlux`/`maxFlux` define the required flux range.
5.  `updateRecipe(uint256 recipeId, uint256[] calldata inputEssenceTypes, uint256 outputEssenceType, uint256 successChanceBasisPoints, uint256 minFlux, uint256 maxFlux)`: (Owner only) Modifies an existing recipe's parameters.
6.  `removeRecipe(uint256 recipeId)`: (Owner only) Deactivates or removes a recipe.
7.  `performAlchemy(uint256 recipeId, uint256[] calldata inputEssenceTokenIds)`: Executes the alchemy process. Burns the input Essences, checks the recipe against the current flux and inputs, rolls for success chance, and potentially mints an output Essence.
8.  `observeEssence(uint256 tokenId)`: Allows the owner of an Essence to "observe" it, potentially revealing dynamic properties (not fully implemented in this base code, but hooks are here). Marks the Essence as observed.
9.  `collapseEssence(uint255 tokenId)`: Allows the owner of an Essence to "collapse" it, fixing its properties permanently. Marks the Essence as collapsed. May be required for certain recipes or interactions.
10. `getEssenceProperties(uint256 tokenId)`: (View) Returns the type and state (observed, collapsed) of a given Essence NFT.
11. `getRecipeDetails(uint256 recipeId)`: (View) Returns the details of a specific alchemy recipe.
12. `listAvailableRecipeIds()`: (View) Returns an array of all currently active recipe IDs.
13. `getCurrentFlux()`: (View) Returns the current simulated Quantum Flux value based on recent block data.
14. `predictAlchemyOutcome(uint256 recipeId)`: (View) Predicts the *potential* outcome based on a recipe and the *current* flux, showing success chance. Does not account for specific input Essence types beyond checking existence of the recipe.
15. `getEssenceType(uint256 tokenId)`: (View) Returns the type of a specific Essence NFT.
16. `isEssenceObserved(uint256 tokenId)`: (View) Checks if an Essence NFT has been observed.
17. `isEssenceCollapsed(uint256 tokenId)`: (View) Checks if an Essence NFT has been collapsed.
18. `setBaseURI(string memory baseURI_)`: (Owner only) Updates the base URI for NFT metadata, allowing dynamic metadata systems.
19. `pause()`: (Owner only) Pauses contract functionality (minting, alchemy).
20. `unpause()`: (Owner only) Unpauses contract functionality.
21. `tokenURI(uint256 tokenId)`: (Overrides ERC721) Returns the metadata URI for a specific token.
22. `transferFrom`: (ERC721 Standard)
23. `safeTransferFrom` (bytes): (ERC721 Standard)
24. `safeTransferFrom` (address): (ERC721 Standard)
25. `approve`: (ERC721 Standard)
26. `setApprovalForAll`: (ERC721 Standard)
27. `getApproved`: (ERC721 Standard)
28. `isApprovedForAll`: (ERC721 Standard)
29. `balanceOf`: (ERC721 Standard)
30. `ownerOf`: (ERC721 Standard)
31. `totalSupply`: (ERC721 Standard)

*(Note: We already have more than 20 functions listed here, including the standard ERC721 functions)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Useful for probability calculations

// --- Smart Contract Outline: Quantum Alchemy Lab ---
// 1. Contract Name: QuantumAlchemy
// 2. Inheritance: ERC721, Ownable, Pausable, ReentrancyGuard
// 3. Core Concept: Users combine unique "Essence" NFTs based on defined "Recipes", influenced by a fluctuating "Quantum Flux". Outcomes can be probabilistic, and Essences have dynamic properties.
// 4. State Variables:
//    - Essence data (mapping NFT ID to properties)
//    - Recipe data (mapping recipe ID to inputs, output, probabilities, flux range)
//    - Quantum Flux value (simulated)
//    - Counters for NFT IDs and Recipe IDs
//    - Base URI for NFT metadata
// 5. Structs: EssenceProperties, Recipe
// 6. Events: EssenceMinted, AlchemyPerformed, AlchemySuccess, AlchemyFailure, RecipeAdded, RecipeUpdated, RecipeRemoved, EssenceObserved, EssenceCollapsed, FluxUpdated
// 7. Functions: (See Function Summary below)

// --- Function Summary: ---
// 1. constructor(string memory name, string memory symbol, string memory initialBaseURI)
// 2. mintInitialEssence(address recipient, uint256 essenceType) (Owner only)
// 3. mintRandomEssence(address recipient) (Owner only)
// 4. addRecipe(uint256[] calldata inputEssenceTypes, uint256 outputEssenceType, uint256 successChanceBasisPoints, uint256 minFlux, uint256 maxFlux) (Owner only)
// 5. updateRecipe(uint256 recipeId, uint256[] calldata inputEssenceTypes, uint256 outputEssenceType, uint256 successChanceBasisPoints, uint256 minFlux, uint256 maxFlux) (Owner only)
// 6. removeRecipe(uint256 recipeId) (Owner only)
// 7. performAlchemy(uint256 recipeId, uint256[] calldata inputEssenceTokenIds)
// 8. observeEssence(uint256 tokenId)
// 9. collapseEssence(uint256 tokenId)
// 10. getEssenceProperties(uint256 tokenId) (View)
// 11. getRecipeDetails(uint256 recipeId) (View)
// 12. listAvailableRecipeIds() (View)
// 13. getCurrentFlux() (View)
// 14. predictAlchemyOutcome(uint256 recipeId) (View)
// 15. getEssenceType(uint256 tokenId) (View)
// 16. isEssenceObserved(uint256 tokenId) (View)
// 17. isEssenceCollapsed(uint256 tokenId) (View)
// 18. setBaseURI(string memory baseURI_) (Owner only)
// 19. pause() (Owner only)
// 20. unpause() (Owner only)
// 21. tokenURI(uint256 tokenId) (Overrides ERC721)
// 22. transferFrom (ERC721 Standard)
// 23. safeTransferFrom (bytes) (ERC721 Standard)
// 24. safeTransferFrom (address) (ERC721 Standard)
// 25. approve (ERC721 Standard)
// 26. setApprovalForAll (ERC721 Standard)
// 27. getApproved (ERC721 Standard)
// 28. isApprovedForAll (ERC721 Standard)
// 29. balanceOf (ERC721 Standard)
// 30. ownerOf (ERC721 Standard)
// 31. totalSupply (ERC721 Standard)
// (More functions added to meet the 20+ requirement and flesh out logic)
// 32. getEssenceDetailsBatch(uint256[] calldata tokenIds) (View)
// 33. getRecipeInputTypes(uint256 recipeId) (View)
// 34. getRecipeOutputDetails(uint256 recipeId) (View)
// 35. checkRecipeMatch(uint256 recipeId, uint256[] calldata inputEssenceTokenIds) (View)
// 36. checkFluxRequirement(uint256 recipeId, uint256 currentFlux) (View)

contract QuantumAlchemy is ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Structs ---
    struct EssenceProperties {
        uint256 essenceType;
        bool observed;
        bool collapsed;
        // Add fields here for dynamic properties if needed
        // Example: uint256 inherentTrait; // Could be set at mint
        // Example: uint256 dynamicTrait; // Could change until collapsed
    }

    struct Recipe {
        uint256[] inputEssenceTypes;
        uint256 outputEssenceType;
        uint256 successChanceBasisPoints; // Chance out of 10000 (e.g., 5000 for 50%)
        uint256 minFlux;
        uint256 maxFlux;
        bool active; // Whether the recipe is currently usable
    }

    // --- State Variables ---
    mapping(uint256 => EssenceProperties) private _essenceProperties;
    mapping(uint256 => Recipe) private _recipes;
    uint256 private _nextTokenId;
    uint256 private _nextRecipeId;
    string private _baseTokenURI;

    // --- Events ---
    event EssenceMinted(address indexed recipient, uint256 indexed tokenId, uint256 essenceType);
    event AlchemyPerformed(address indexed performer, uint256 indexed recipeId, uint256[] inputTokenIds);
    event AlchemySuccess(address indexed performer, uint256 indexed recipeId, uint256 outputTokenId, uint256 outputEssenceType);
    event AlchemyFailure(address indexed performer, uint256 indexed recipeId, string reason);
    event RecipeAdded(uint256 indexed recipeId, uint256[] inputEssenceTypes, uint256 outputEssenceType);
    event RecipeUpdated(uint256 indexed recipeId);
    event RecipeRemoved(uint256 indexed recipeId);
    event EssenceObserved(uint256 indexed tokenId);
    event EssenceCollapsed(uint256 indexed tokenId);
    event FluxUpdated(uint256 indexed blockNumber, uint256 fluxValue); // Emitted when flux is calculated for an operation

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory initialBaseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = initialBaseURI;
        _nextTokenId = 0; // Token IDs start from 0
        _nextRecipeId = 0; // Recipe IDs start from 0
    }

    // --- Core Logic: Minting ---

    /// @notice Mints a new Essence NFT of a specific type.
    /// @param recipient The address to receive the NFT.
    /// @param essenceType The predefined type ID of the Essence.
    function mintInitialEssence(address recipient, uint256 essenceType) external onlyOwner pausable nonReentrant {
        _safeMint(recipient, _nextTokenId);
        _essenceProperties[_nextTokenId] = EssenceProperties({
            essenceType: essenceType,
            observed: false,
            collapsed: false
            // Initialize dynamic properties if they exist
        });
        emit EssenceMinted(recipient, _nextTokenId, essenceType);
        _nextTokenId++;
    }

    /// @notice Mints a new Essence NFT of a randomly determined type.
    /// @param recipient The address to receive the NFT.
    function mintRandomEssence(address recipient) external onlyOwner pausable nonReentrant {
        // In a real scenario, this would use a secure VRF or oracle for randomness.
        // Using block hash/timestamp is predictable and not secure for fair distribution.
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextTokenId)));
        // Example: Determine type based on modulo or range (replace with actual type logic)
        uint256 essenceType = randomValue % 10; // Example: 10 possible types (0-9)

        _safeMint(recipient, _nextTokenId);
        _essenceProperties[_nextTokenId] = EssenceProperties({
            essenceType: essenceType,
            observed: false,
            collapsed: false
            // Initialize dynamic properties
        });
        emit EssenceMinted(recipient, _nextTokenId, essenceType);
        _nextTokenId++;
    }

    // --- Core Logic: Alchemy ---

    /// @notice Performs the alchemy process using specified input Essences and a recipe.
    /// @param recipeId The ID of the recipe to use.
    /// @param inputEssenceTokenIds An array of token IDs for the Essences to be used as input.
    function performAlchemy(uint256 recipeId, uint256[] calldata inputEssenceTokenIds) external pausable nonReentrant {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        Recipe storage recipe = _recipes[recipeId];

        // 1. Validate inputs
        require(inputEssenceTokenIds.length == recipe.inputEssenceTypes.length, "Incorrect number of input Essences");

        // Check ownership and type of inputs, and track used token IDs
        mapping(uint256 => bool) usedTokenIds;
        uint256[] memory inputTypesProvided = new uint256[](inputEssenceTokenIds.length);

        for (uint i = 0; i < inputEssenceTokenIds.length; i++) {
            uint256 tokenId = inputEssenceTokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Not owner of input Essence");
            require(!usedTokenIds[tokenId], "Duplicate input Essence token ID");
            usedTokenIds[tokenId] = true;
            inputTypesProvided[i] = _essenceProperties[tokenId].essenceType;

            // Require inputs to be collapsed for stable alchemy (example rule)
            require(_essenceProperties[tokenId].collapsed, "Input Essences must be collapsed");
        }

        // Check if provided input types match recipe required types (order-independent check)
        require(_checkRecipeMatch(recipeId, inputEssenceTokenIds), "Input Essence types do not match recipe");

        // 2. Determine current Quantum Flux
        // Simulated flux based on block data. In production, use Oracle.
        uint256 currentFlux = uint256(keccak256(abi.encodePacked(block.number, block.timestamp)));
        // Simple range mapping for illustrative purposes (adjust range as needed)
        // Maps keccak256 output (large range) to a 0-9999 range.
        currentFlux = currentFlux % 10000; // Flux is between 0 and 9999

        emit FluxUpdated(block.number, currentFlux);

        // 3. Check Flux Requirement
        require(currentFlux >= recipe.minFlux && currentFlux <= recipe.maxFlux, "Current flux outside recipe range");

        // 4. Burn input Essences
        for (uint i = 0; i < inputEssenceTokenIds.length; i++) {
            _burn(inputEssenceTokenIds[i]);
        }

        emit AlchemyPerformed(msg.sender, recipeId, inputEssenceTokenIds);

        // 5. Roll for success chance
        // Use randomness derived from block data + performer address (still predictable)
        uint256 randomRoll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, inputEssenceTokenIds.length, currentFlux))) % 10000; // Roll between 0 and 9999

        if (randomRoll < recipe.successChanceBasisPoints) {
            // Success: Mint output Essence
            uint256 newEssenceTokenId = _nextTokenId;
            _safeMint(msg.sender, newEssenceTokenId);
            _essenceProperties[newEssenceTokenId] = EssenceProperties({
                essenceType: recipe.outputEssenceType,
                observed: false,
                collapsed: false
                // Initialize dynamic properties for the output
            });
            emit EssenceMinted(msg.sender, newEssenceTokenId, recipe.outputEssenceType);
            emit AlchemySuccess(msg.sender, recipeId, newEssenceTokenId, recipe.outputEssenceType);
             _nextTokenId++;
        } else {
            // Failure: Inputs are burned, no output
            emit AlchemyFailure(msg.sender, recipeId, "Alchemy failed the probabilistic roll.");
        }
    }

    // --- Essence State Management ---

    /// @notice Allows the owner to observe an Essence. This might reveal hidden properties.
    /// @param tokenId The ID of the Essence NFT to observe.
    function observeEssence(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not owner of Essence");
        require(!_essenceProperties[tokenId].observed, "Essence already observed");

        _essenceProperties[tokenId].observed = true;
        // Add logic here to potentially reveal/calculate dynamic properties upon observation
        // For example: _essenceProperties[tokenId].dynamicTrait = calculateDynamicTrait(tokenId);

        emit EssenceObserved(tokenId);
    }

    /// @notice Allows the owner to collapse an Essence. This fixes any dynamic properties permanently.
    /// @param tokenId The ID of the Essence NFT to collapse.
    function collapseEssence(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not owner of Essence");
        require(!_essenceProperties[tokenId].collapsed, "Essence already collapsed");
        require(_essenceProperties[tokenId].observed, "Essence must be observed before collapsing");

        _essenceProperties[tokenId].collapsed = true;
        // Add logic here to lock dynamic properties if they weren't already fixed on observation

        emit EssenceCollapsed(tokenId);
    }

    // --- Recipe Management (Owner Only) ---

    /// @notice Adds a new alchemy recipe.
    /// @param inputEssenceTypes Array of required input Essence type IDs.
    /// @param outputEssenceType The type ID of the Essence produced on success.
    /// @param successChanceBasisPoints Chance of success (0-10000).
    /// @param minFlux Minimum required flux value (0-9999).
    /// @param maxFlux Maximum required flux value (0-9999).
    function addRecipe(
        uint256[] calldata inputEssenceTypes,
        uint256 outputEssenceType,
        uint256 successChanceBasisPoints,
        uint256 minFlux,
        uint256 maxFlux
    ) external onlyOwner nonReentrant {
        require(inputEssenceTypes.length > 0, "Recipe requires at least one input type");
        require(successChanceBasisPoints <= 10000, "Success chance out of 10000");
        require(minFlux <= maxFlux, "minFlux cannot be greater than maxFlux");
        require(maxFlux <= 9999, "maxFlux cannot exceed 9999");

        _recipes[_nextRecipeId] = Recipe({
            inputEssenceTypes: inputEssenceTypes,
            outputEssenceType: outputEssenceType,
            successChanceBasisPoints: successChanceBasisPoints,
            minFlux: minFlux,
            maxFlux: maxFlux,
            active: true
        });
        emit RecipeAdded(_nextRecipeId, inputEssenceTypes, outputEssenceType);
        _nextRecipeId++;
    }

    /// @notice Updates an existing alchemy recipe.
    /// @param recipeId The ID of the recipe to update.
    /// @param inputEssenceTypes New array of required input Essence type IDs.
    /// @param outputEssenceType New type ID of the Essence produced on success.
    /// @param successChanceBasisPoints New chance of success (0-10000).
    /// @param minFlux New minimum required flux value (0-9999).
    /// @param maxFlux New maximum required flux value (0-9999).
    function updateRecipe(
        uint256 recipeId,
        uint256[] calldata inputEssenceTypes,
        uint256 outputEssenceType,
        uint256 successChanceBasisPoints,
        uint256 minFlux,
        uint256 maxFlux
    ) external onlyOwner nonReentrant {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        require(inputEssenceTypes.length > 0, "Recipe requires at least one input type");
        require(successChanceBasisPoints <= 10000, "Success chance out of 10000");
        require(minFlux <= maxFlux, "minFlux cannot be greater than maxFlux");
        require(maxFlux <= 9999, "maxFlux cannot exceed 9999");

        _recipes[recipeId].inputEssenceTypes = inputEssenceTypes;
        _recipes[recipeId].outputEssenceType = outputEssenceType;
        _recipes[recipeId].successChanceBasisPoints = successChanceBasisPoints;
        _recipes[recipeId].minFlux = minFlux;
        _recipes[recipeId].maxFlux = maxFlux;
        // Keep active status as is

        emit RecipeUpdated(recipeId);
    }

    /// @notice Removes (deactivates) a recipe so it can no longer be used.
    /// @param recipeId The ID of the recipe to remove.
    function removeRecipe(uint256 recipeId) external onlyOwner nonReentrant {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        _recipes[recipeId].active = false;
        emit RecipeRemoved(recipeId);
    }

    // --- Querying Functions (View) ---

    /// @notice Gets the properties of a specific Essence NFT.
    /// @param tokenId The ID of the Essence NFT.
    /// @return essenceType The type ID.
    /// @return observed Whether it has been observed.
    /// @return collapsed Whether it has been collapsed.
    function getEssenceProperties(uint256 tokenId) public view returns (uint256 essenceType, bool observed, bool collapsed) {
        require(_exists(tokenId), "Essence does not exist");
        EssenceProperties storage props = _essenceProperties[tokenId];
        return (props.essenceType, props.observed, props.collapsed);
    }

     /// @notice Gets the properties of multiple Essence NFTs.
    /// @param tokenIds Array of Essence NFT IDs.
    /// @return essenceTypes Array of type IDs.
    /// @return observedStates Array of observed states.
    /// @return collapsedStates Array of collapsed states.
    function getEssenceDetailsBatch(uint256[] calldata tokenIds) public view returns (uint256[] memory essenceTypes, bool[] memory observedStates, bool[] memory collapsedStates) {
        essenceTypes = new uint256[](tokenIds.length);
        observedStates = new bool[](tokenIds.length);
        collapsedStates = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
             require(_exists(tokenIds[i]), string.concat("Essence does not exist: ", Strings.toString(tokenIds[i])));
            EssenceProperties storage props = _essenceProperties[tokenIds[i]];
            essenceTypes[i] = props.essenceType;
            observedStates[i] = props.observed;
            collapsedStates[i] = props.collapsed;
        }
        return (essenceTypes, observedStates, collapsedStates);
    }


    /// @notice Gets the type of a specific Essence NFT.
    /// @param tokenId The ID of the Essence NFT.
    /// @return The type ID.
    function getEssenceType(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Essence does not exist");
        return _essenceProperties[tokenId].essenceType;
    }

    /// @notice Checks if a specific Essence NFT has been observed.
    /// @param tokenId The ID of the Essence NFT.
    /// @return True if observed, false otherwise.
    function isEssenceObserved(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Essence does not exist");
        return _essenceProperties[tokenId].observed;
    }

    /// @notice Checks if a specific Essence NFT has been collapsed.
    /// @param tokenId The ID of the Essence NFT.
    /// @return True if collapsed, false otherwise.
    function isEssenceCollapsed(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Essence does not exist");
        return _essenceProperties[tokenId].collapsed;
    }

    /// @notice Gets the details of a specific alchemy recipe.
    /// @param recipeId The ID of the recipe.
    /// @return inputEssenceTypes Array of required input Essence type IDs.
    /// @return outputEssenceType The type ID of the Essence produced on success.
    /// @return successChanceBasisPoints Chance of success (0-10000).
    /// @return minFlux Minimum required flux value (0-9999).
    /// @return maxFlux Maximum required flux value (0-9999).
    /// @return active Whether the recipe is currently active.
    function getRecipeDetails(uint256 recipeId) public view returns (uint256[] memory inputEssenceTypes, uint256 outputEssenceType, uint256 successChanceBasisPoints, uint256 minFlux, uint256 maxFlux, bool active) {
        require(_recipes[recipeId].active, "Recipe not found or inactive"); // Only show active recipes? Or allow querying inactive? Let's allow querying.
        Recipe storage recipe = _recipes[recipeId];
         return (recipe.inputEssenceTypes, recipe.outputEssenceType, recipe.successChanceBasisPoints, recipe.minFlux, recipe.maxFlux, recipe.active);
    }

    /// @notice Gets the required input types for a recipe.
    /// @param recipeId The ID of the recipe.
    /// @return Array of required input Essence type IDs.
    function getRecipeInputTypes(uint256 recipeId) public view returns (uint256[] memory) {
         require(_recipes[recipeId].active, "Recipe not found or inactive");
        return _recipes[recipeId].inputEssenceTypes;
    }

    /// @notice Gets the output details for a recipe.
    /// @param recipeId The ID of the recipe.
    /// @return outputEssenceType The type ID of the Essence produced.
    /// @return successChanceBasisPoints Chance of success (0-10000).
     function getRecipeOutputDetails(uint256 recipeId) public view returns (uint256, uint256) {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        return (_recipes[recipeId].outputEssenceType, _recipes[recipeId].successChanceBasisPoints);
    }


    /// @notice Lists all currently active recipe IDs.
    /// @return An array of active recipe IDs.
    function listAvailableRecipeIds() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint i = 0; i < _nextRecipeId; i++) {
            if (_recipes[i].active) {
                count++;
            }
        }
        uint256[] memory activeRecipeIds = new uint256[](count);
        uint256 index = 0;
        for (uint i = 0; i < _nextRecipeId; i++) {
            if (_recipes[i].active) {
                activeRecipeIds[index] = i;
                index++;
            }
        }
        return activeRecipeIds;
    }

    /// @notice Calculates the current simulated Quantum Flux value.
    /// @dev Uses block data which is predictable. Do not rely on this for security.
    /// @return The current flux value (0-9999).
    function getCurrentFlux() public view returns (uint256) {
         // Simulated flux based on block data. In production, use Oracle.
        uint256 currentFlux = uint256(keccak256(abi.encodePacked(block.number, block.timestamp)));
        return currentFlux % 10000; // Flux is between 0 and 9999
    }

    /// @notice Predicts the potential alchemy outcome based on a recipe and the current flux.
    /// @dev This is a deterministic calculation based on current on-chain state.
    /// @param recipeId The ID of the recipe.
    /// @return successChance The calculated success chance based on recipe and current flux.
    function predictAlchemyOutcome(uint256 recipeId) public view returns (uint256 successChance) {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        Recipe storage recipe = _recipes[recipeId];
        uint256 currentFlux = getCurrentFlux();

        if (currentFlux >= recipe.minFlux && currentFlux <= recipe.maxFlux) {
            return recipe.successChanceBasisPoints;
        } else {
            return 0; // 0% chance if flux is outside the range
        }
    }

    /// @notice Checks if the provided input token IDs match the required types for a recipe.
    /// @dev This performs an order-independent check of types.
    /// @param recipeId The ID of the recipe.
    /// @param inputEssenceTokenIds An array of token IDs for the Essences to check.
    /// @return True if the input types match the recipe requirements.
    function checkRecipeMatch(uint256 recipeId, uint256[] calldata inputEssenceTokenIds) public view returns (bool) {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        Recipe storage recipe = _recipes[recipeId];

        if (inputEssenceTokenIds.length != recipe.inputEssenceTypes.length) {
            return false;
        }

        // Count occurrences of each input type in the provided tokens
        mapping(uint256 => uint256) providedTypeCounts;
        for (uint i = 0; i < inputEssenceTokenIds.length; i++) {
            require(_exists(inputEssenceTokenIds[i]), string.concat("Essence does not exist: ", Strings.toString(inputEssenceTokenIds[i])));
            providedTypeCounts[_essenceProperties[inputEssenceTokenIds[i]].essenceType]++;
        }

        // Count occurrences of each required type in the recipe
        mapping(uint256 => uint256) requiredTypeCounts;
        for (uint i = 0; i < recipe.inputEssenceTypes.length; i++) {
            requiredTypeCounts[recipe.inputEssenceTypes[i]]++;
        }

        // Compare counts
        for (uint i = 0; i < recipe.inputEssenceTypes.length; i++) {
            uint256 requiredType = recipe.inputEssenceTypes[i];
            if (providedTypeCounts[requiredType] != requiredTypeCounts[requiredType]) {
                return false;
            }
        }

        return true;
    }

     /// @notice Checks if a given flux value meets the requirement for a recipe.
    /// @param recipeId The ID of the recipe.
    /// @param currentFlux A flux value to check against.
    /// @return True if the flux is within the recipe's required range.
    function checkFluxRequirement(uint256 recipeId, uint256 currentFlux) public view returns (bool) {
        require(_recipes[recipeId].active, "Recipe not found or inactive");
        Recipe storage recipe = _recipes[recipeId];
        return currentFlux >= recipe.minFlux && currentFlux <= recipe.maxFlux;
    }


    // --- Admin Functions ---

    /// @notice Updates the base URI for token metadata.
    /// @param baseURI_ The new base URI string.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /// @notice Pauses core contract functionality.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract functionality.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Overrides ---

    /// @dev See {ERC721-_beforeTokenTransfer}.
    // Prevent transfers if observed or collapsed state is relevant (example rule)
    // Disabled this for simplicity in this example, but could add:
    // require(!_essenceProperties[tokenId].observed, "Cannot transfer observed Essence");
    // require(!_essenceProperties[tokenId].collapsed, "Cannot transfer collapsed Essence");
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Optional: Add specific checks here based on Essence state (observed/collapsed)
        // if (from != address(0) && to != address(0)) { // Not minting or burning
        //     require(!_essenceProperties[tokenId].observed, "Essence cannot be transferred while observed");
        //     require(!_essenceProperties[tokenId].collapsed, "Essence cannot be transferred while collapsed"); // Or require collapse to transfer? Depends on game design.
        // }
    }


    /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // Append token ID and potentially query params for dynamic metadata
        // Example: "base_uri/token/123" or "base_uri/metadata?id=123&flux=4567&observed=true"
        // This simple example just appends the ID.
        // A real implementation would pass state to a metadata server.
         string memory tokenIdStr = Strings.toString(tokenId);
         string memory essenceTypeStr = Strings.toString(_essenceProperties[tokenId].essenceType);
         string memory observedStr = _essenceProperties[tokenId].observed ? "true" : "false";
         string memory collapsedStr = _essenceProperties[tokenId].collapsed ? "true" : "false";

        // Basic concat: baseURI/tokenId
        // return string(abi.encodePacked(base, tokenIdStr));

        // More complex metadata URI example including state (requires off-chain server to interpret):
        // return string(abi.encodePacked(base, "?id=", tokenIdStr, "&type=", essenceTypeStr, "&observed=", observedStr, "&collapsed=", collapsedStr));

        // Simplest implementation: just append token ID
        return string(abi.encodePacked(base, tokenIdStr));
    }


    // --- Internal Helpers ---

     /// @dev Internal check for recipe input type matching.
     /// @param recipeId The ID of the recipe.
     /// @param inputEssenceTokenIds The array of token IDs provided.
     /// @return True if types match, false otherwise.
     function _checkRecipeMatch(uint256 recipeId, uint256[] calldata inputEssenceTokenIds) internal view returns (bool) {
         Recipe storage recipe = _recipes[recipeId];
        if (inputEssenceTokenIds.length != recipe.inputEssenceTypes.length) {
            return false;
        }

        mapping(uint256 => uint256) providedTypeCounts;
        for (uint i = 0; i < inputEssenceTokenIds.length; i++) {
            // Assuming _exists(inputEssenceTokenIds[i]) is already checked by ownerOf or similar
            providedTypeCounts[_essenceProperties[inputEssenceTokenIds[i]].essenceType]++;
        }

        mapping(uint256 => uint256) requiredTypeCounts;
        for (uint i = 0; i < recipe.inputEssenceTypes.length; i++) {
            requiredTypeCounts[recipe.inputEssenceTypes[i]]++;
        }

        for (uint i = 0; i < recipe.inputEssenceTypes.length; i++) {
            uint256 requiredType = recipe.inputEssenceTypes[i];
            if (providedTypeCounts[requiredType] != requiredTypeCounts[requiredType]) {
                return false;
            }
        }

        return true;
    }

     // Standard ERC721 functions are inherited and publicly available:
     // transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, balanceOf, ownerOf, totalSupply

}
```