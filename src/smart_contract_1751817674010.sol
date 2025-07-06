Okay, let's design a smart contract based on an advanced crafting/alchemy system with evolving NFTs and resource management.

**Concept:** **CryptoAlchemy Forge**

This contract acts as a decentralized alchemy laboratory. Users collect elemental resources (fungible tokens represented internally), combine them using recipes (known or potentially discovered through experimentation) to create more complex components (internal fungible tokens) or unique artifacts (NFTs). Artifacts can have properties influenced by ingredients, randomness, and can potentially evolve through further interaction and resource expenditure. Users gain experience (XP) and level up, potentially unlocking new recipes or increasing success chances.

**Advanced Concepts:**

1.  **Internal Fungible Tokens:** Instead of deploying separate ERC20 contracts for elements and components, their balances are managed within the main contract's state. This simplifies interaction within the contract's logic but requires custom transfer/balance logic.
2.  **Complex Crafting Recipes:** Recipes involve specific multiple ingredients (elements/components) and potentially catalysts, with defined output types (components or artifacts), success chances, and required user levels.
3.  **Procedural NFT Property Generation:** Artifact properties are generated based on the recipe used, ingredient ratios, user's level, and a degree of pseudo-randomness (using block data - note: not truly random, use VRF for production).
4.  **NFT Evolution/State Changes:** Artifacts are not static. They have properties like Level, Durability, and Evolution Stage that can change through specific contract functions (`evolveArtifact`, `useArtifact`, `repairArtifact`).
5.  **Resource Sink / Burn Mechanism:** Functions like `burnArtifact` or `decomposeComponent` provide ways to remove assets from the ecosystem, managing potential inflation of elements/components.
6.  **Discovery Mechanism:** A simplified `discoverRecipeAttempt` function allows users to experiment with inputs, potentially identifying known recipes (if the combination matches) at a small cost, encouraging interaction.
7.  **XP and Leveling System:** Users gain XP by successfully crafting or evolving, leading to level ups which can grant benefits.
8.  **Minimal Integrated ERC721:** A basic ERC721 implementation is included within the contract to handle the Artifact NFTs, demonstrating direct integration rather than relying solely on imported libraries (while acknowledging OpenZeppelin for production).

---

**Outline:**

1.  **State Variables:** Define mappings and variables for elements, components, recipes, artifacts, user levels, XP, minimal ERC721 state.
2.  **Events:** Define events for tracking creation, crafting, evolution, transfers, etc.
3.  **Modifiers:** `onlyOwner`, `onlyExistingArtifact`.
4.  **Enums:** `OutputType` for recipes (Component, Artifact).
5.  **Structs:** `Recipe`, `Artifact`, `IngredientInput`, `CatalystInput`.
6.  **Admin/Setup Functions:** Create element/component types, add recipes, set XP requirements, grant initial elements, ownership transfer.
7.  **Core Alchemy Functions:** Crafting (`craft`), experimental discovery attempt (`discoverRecipeAttempt`), artifact evolution (`evolveArtifact`), artifact burning (`burnArtifact`), component decomposition (`decomposeComponent`).
8.  **User Inventory/State Functions:** Check balances, get artifact details, get user level/XP, get recipe details, list types/recipes.
9.  **Minimal ERC721 Functions:** `balanceOf`, `ownerOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`.
10. **Internal Helper Functions:** Handle element/component balance updates, XP granting, artifact minting/burning, pseudo-randomness generation.

---

**Function Summary:**

1.  `constructor()`: Initializes contract owner and sets initial state.
2.  `createElementType(string memory _name)`: (Admin) Creates a new type of elemental resource.
3.  `addComponentType(string memory _name)`: (Admin) Creates a new type of crafted component resource.
4.  `addRecipe(IngredientInput[] memory _ingredients, IngredientInput[] memory _catalysts, uint256 _requiredLevel, uint16 _successChance, OutputType _outputType, uint256 _outputId, uint256 _outputAmount, string[] memory _propertyNames, string[] memory _propertyValues)`: (Admin) Adds a new crafting recipe.
5.  `setLevelXPRequirement(uint256 _level, uint256 _xpRequired)`: (Admin) Sets the XP needed to reach a specific user level.
6.  `grantElement(address _user, uint256 _elementId, uint256 _amount)`: (Admin) Mints a specified amount of an element to a user.
7.  `craft(uint256 _recipeId)`: User attempts to craft using a known recipe ID, consuming ingredients/catalysts and potentially creating output.
8.  `discoverRecipeAttempt(IngredientInput[] memory _ingredients, IngredientInput[] memory _catalysts)`: User attempts to find a recipe matching given inputs, consuming a small discovery cost.
9.  `evolveArtifact(uint256 _artifactId, IngredientInput[] memory _ingredients, IngredientInput[] memory _catalysts)`: User attempts to evolve an existing artifact using resources.
10. `burnArtifact(uint256 _artifactId)`: User destroys an artifact, potentially gaining some resources back or XP.
11. `decomposeComponent(uint256 _componentId, uint256 _amount)`: User breaks down a component into elements, likely with some loss.
12. `getUserElementBalance(address _user, uint256 _elementId)`: View balance of a specific element for a user.
13. `getUserComponentBalance(address _user, uint256 _componentId)`: View balance of a specific component for a user.
14. `getUserLevel(address _user)`: View the alchemy level of a user.
15. `getUserXP(address _user)`: View the current XP of a user.
16. `getArtifactDetails(uint256 _artifactId)`: View detailed properties and state of an artifact.
17. `getRecipeDetails(uint256 _recipeId)`: View the ingredients and output of a specific recipe.
18. `listAllElementTypes()`: View all created element types and their IDs/names.
19. `listAllComponentTypes()`: View all created component types and their IDs/names.
20. `listAllRecipeIds()`: View all currently known recipe IDs.
21. `balanceOf(address _owner)`: (ERC721) Get the number of artifacts owned by an address.
22. `ownerOf(uint256 _tokenId)`: (ERC721) Get the owner of a specific artifact token.
23. `transferFrom(address _from, address _to, uint256 _tokenId)`: (ERC721) Transfer artifact ownership.
24. `approve(address _to, uint256 _tokenId)`: (ERC721) Approve an address to transfer a specific artifact.
25. `getApproved(uint256 _tokenId)`: (ERC721) Get the approved address for a specific artifact.
26. `setApprovalForAll(address _operator, bool _approved)`: (ERC721) Approve or revoke approval for an operator for all owner's artifacts.
27. `isApprovedForAll(address _owner, address _operator)`: (ERC721) Check if an operator is approved for all of an owner's artifacts.
28. `transferOwnership(address newOwner)`: (Admin) Transfer contract ownership.
29. `renounceOwnership()`: (Admin) Renounce contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoAlchemy Forge
 * @author Your Name/Alias
 * @notice A smart contract for an advanced crafting/alchemy system with internal resources and evolving NFTs.
 *
 * Outline:
 * 1. State Variables for elements, components, recipes, artifacts, user data, and minimal ERC721.
 * 2. Events to track actions and state changes.
 * 3. Modifiers for access control and validation.
 * 4. Enums and Structs to define data types.
 * 5. Admin/Setup functions (createElementType, addComponentType, addRecipe, setLevelXPRequirement, grantElement, transferOwnership, renounceOwnership).
 * 6. Core Alchemy functions (craft, discoverRecipeAttempt, evolveArtifact, burnArtifact, decomposeComponent).
 * 7. User Inventory/State functions (getUserElementBalance, getUserComponentBalance, getUserLevel, getUserXP, getArtifactDetails, getRecipeDetails, listAllElementTypes, listAllComponentTypes, listAllRecipeIds).
 * 8. Minimal ERC721 functions for Artifact NFTs (balanceOf, ownerOf, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll).
 * 9. Internal helper functions (_grantXP, _mintArtifact, _burnArtifact, _transferArtifact, _checkLevelUp, _rollSuccess).
 *
 * Function Summary:
 * - constructor(): Initializes contract owner.
 * - createElementType(string): Admin adds a new element type.
 * - addComponentType(string): Admin adds a new component type.
 * - addRecipe(...): Admin adds a new crafting recipe with ingredients, catalysts, requirements, and output.
 * - setLevelXPRequirement(uint, uint): Admin sets XP needed for a level.
 * - grantElement(address, uint, uint): Admin gives elements to a user (e.g., faucet).
 * - craft(uint): User attempts to craft based on a recipe ID.
 * - discoverRecipeAttempt(IngredientInput[], CatalystInput[]): User experiments with inputs to identify a recipe.
 * - evolveArtifact(uint, IngredientInput[], Catalyst[]): User attempts to evolve an artifact.
 * - burnArtifact(uint): User destroys an artifact.
 * - decomposeComponent(uint, uint): User breaks down a component into elements.
 * - getUserElementBalance(address, uint): View user's element balance.
 * - getUserComponentBalance(address, uint): View user's component balance.
 * - getUserLevel(address): View user's alchemy level.
 * - getUserXP(address): View user's current XP.
 * - getArtifactDetails(uint): View artifact properties and state.
 * - getRecipeDetails(uint): View a recipe's details.
 * - listAllElementTypes(): View all element types.
 * - listAllComponentTypes(): View all component types.
 * - listAllRecipeIds(): View all known recipe IDs.
 * - balanceOf(address): ERC721: Get artifact count for owner.
 * - ownerOf(uint): ERC721: Get owner of artifact ID.
 * - transferFrom(address, address, uint): ERC721: Transfer artifact.
 * - approve(address, uint): ERC721: Approve artifact transfer.
 * - getApproved(uint): ERC721: Get approved address for artifact.
 * - setApprovalForAll(address, bool): ERC721: Set operator approval.
 * - isApprovedForAll(address, address): ERC721: Check operator approval.
 * - transferOwnership(address): Admin transfers ownership.
 * - renounceOwnership(): Admin renounces ownership.
 */
contract CryptoAlchemyForge {

    // --- State Variables ---

    // Owner
    address private _owner;

    // Element Definitions (internal fungible resource type)
    mapping(uint256 => string) public elementNames;
    uint256 private _nextElementId = 0;

    // Component Definitions (internal fungible resource type)
    mapping(uint256 => string) public componentNames;
    uint256 private _nextComponentId = 0;

    // User Balances for Elements and Components
    mapping(address => mapping(uint256 => uint256)) private _userElements; // user => elementId => amount
    mapping(address => mapping(uint256 => uint256)) private _userComponents; // user => componentId => amount

    // Recipe Definitions
    enum OutputType { Component, Artifact }
    struct IngredientInput { uint256 id; uint256 amount; bool isElement; } // id is elementId or componentId
    struct Recipe {
        IngredientInput[] ingredients; // Required inputs
        IngredientInput[] catalysts; // Optional inputs influencing chance/output
        uint256 requiredLevel;
        uint16 successChance; // Percentage (0-10000 for 0.00% to 100.00%)
        OutputType outputType;
        uint256 outputId; // elementId, componentId, or ignored for new artifact type
        uint256 outputAmount; // Amount for component output, 1 for artifact
        string[] artifactPropertyNames; // Only for Artifact outputType
        string[] artifactPropertyValues; // Only for Artifact outputType (base values)
    }
    mapping(uint256 => Recipe) public recipes;
    uint256[] public allRecipeIds; // To list all recipe IDs
    uint256 private _nextRecipeId = 0;

    // Artifact Definitions (Minimal ERC721 + Alchemy State)
    struct Artifact {
        uint256 tokenId;
        address owner; // Stored explicitly for easier access
        mapping(string => string) properties; // Dynamic properties
        uint48 creationTimestamp;
        uint256 provenanceRecipeId;
        uint16 level;
        uint16 durability;
        uint8 evolutionStage;
        bool isBurned; // Flag to mark as burned
    }
    mapping(uint256 => Artifact) private _artifacts;
    uint256 private _nextTokenId = 0;

    // Minimal ERC721 State
    mapping(address => uint256) private _balances; // owner => count
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // User Level and XP System
    mapping(address => uint256) private _userLevel;
    mapping(address => uint256) private _userXP;
    mapping(uint256 => uint256) public levelXPRequirements; // level => XP needed to reach this level

    // --- Events ---

    event ElementCreated(uint256 indexed id, string name);
    event ComponentCreated(uint256 indexed id, string name);
    event RecipeAdded(uint256 indexed recipeId, OutputType outputType, uint256 outputId);
    event GrantElement(address indexed user, uint256 indexed elementId, uint256 amount);

    event CraftSuccess(address indexed user, uint256 indexed recipeId, OutputType outputType, uint256 outputTokenIdOrAmount);
    event CraftFailed(address indexed user, uint256 indexed recipeId);
    event RecipeDiscoveredAttempt(address indexed user, bool foundMatch, uint256 indexed matchedRecipeId); // foundMatch indicates if inputs matched *any* known recipe

    event ArtifactMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed recipeId);
    event ArtifactEvolved(uint256 indexed tokenId, uint16 newLevel, uint8 newStage);
    event ArtifactBurned(uint256 indexed tokenId, address indexed owner);

    event XPGranted(address indexed user, uint256 amount, uint256 newTotalXP);
    event LevelUp(address indexed user, uint256 newLevel, uint256 oldLevel);

    // Minimal ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyExistingArtifact(uint256 _tokenId) {
        require(_artifacts[_tokenId].owner != address(0) && !_artifacts[_tokenId].isBurned, "Artifact does not exist or is burned");
        _;
    }

    // --- Enums and Structs already defined above ---

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
    }

    // --- Admin/Setup Functions ---

    function createElementType(string memory _name) public onlyOwner {
        uint256 newId = _nextElementId++;
        elementNames[newId] = _name;
        emit ElementCreated(newId, _name);
    }

    function addComponentType(string memory _name) public onlyOwner {
        uint256 newId = _nextComponentId++;
        componentNames[newId] = _name;
        emit ComponentCreated(newId, _name);
    }

    function addRecipe(
        IngredientInput[] memory _ingredients,
        IngredientInput[] memory _catalysts,
        uint256 _requiredLevel,
        uint16 _successChance,
        OutputType _outputType,
        uint256 _outputId, // For Component outputType, the componentId. Ignored for Artifact.
        uint256 _outputAmount, // Amount for Component outputType. Must be 1 for Artifact.
        string[] memory _artifactPropertyNames, // Only for Artifact outputType
        string[] memory _artifactPropertyValues // Only for Artifact outputType (base values)
    ) public onlyOwner {
        require(_successChance <= 10000, "Success chance must be <= 10000 (100%)");

        // Basic validation for ingredients/catalysts existence (can be expanded)
        for(uint i = 0; i < _ingredients.length; i++) {
            if (_ingredients[i].isElement) {
                require(_ingredients[i].id < _nextElementId, "Invalid ingredient elementId");
            } else {
                require(_ingredients[i].id < _nextComponentId, "Invalid ingredient componentId");
            }
        }
         for(uint i = 0; i < _catalysts.length; i++) {
            if (_catalysts[i].isElement) {
                require(_catalysts[i].id < _nextElementId, "Invalid catalyst elementId");
            } else {
                require(_catalysts[i].id < _nextComponentId, "Invalid catalyst componentId");
            }
        }

        if (_outputType == OutputType.Component) {
             require(_outputId < _nextComponentId, "Invalid output componentId for Component type");
             require(_outputAmount > 0, "Output amount must be greater than 0 for Component type");
             require(_artifactPropertyNames.length == 0 && _artifactPropertyValues.length == 0, "Artifact properties only for Artifact type");
        } else if (_outputType == OutputType.Artifact) {
             // _outputId is not strictly needed for Artifact, but could represent an artifact *type* in a more complex system.
             // For this version, we'll just mint a new unique token.
             require(_outputAmount == 1, "Output amount must be 1 for Artifact type");
             require(_artifactPropertyNames.length == _artifactPropertyValues.length, "Artifact property name/value arrays must match length");
             // More validation could check for valid property names/formats
        }

        uint256 newId = _nextRecipeId++;
        recipes[newId] = Recipe({
            ingredients: _ingredients,
            catalysts: _catalysts,
            requiredLevel: _requiredLevel,
            successChance: _successChance,
            outputType: _outputType,
            outputId: _outputId,
            outputAmount: _outputAmount,
            artifactPropertyNames: _artifactPropertyNames,
            artifactPropertyValues: _artifactPropertyValues
        });
        allRecipeIds.push(newId);
        emit RecipeAdded(newId, _outputType, _outputId);
    }

    function setLevelXPRequirement(uint256 _level, uint256 _xpRequired) public onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        levelXPRequirements[_level] = _xpRequired;
    }

    function grantElement(address _user, uint256 _elementId, uint256 _amount) public onlyOwner {
        require(_elementId < _nextElementId, "Invalid elementId");
        require(_amount > 0, "Amount must be greater than 0");
        _userElements[_user][_elementId] += _amount;
        emit GrantElement(_user, _elementId, _amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
        emit Transfer(msg.sender, newOwner, 0); // Use Transfer event with tokenId 0 for ownership transfer, convention
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
        emit Transfer(msg.sender, address(0), 0); // Use Transfer event with tokenId 0 for ownership transfer, convention
    }


    // --- Core Alchemy Functions ---

    function craft(uint256 _recipeId) public {
        Recipe storage recipe = recipes[_recipeId];
        require(recipe.successChance > 0 || recipe.outputType == OutputType.Component, "Recipe does not exist or is non-craftable"); // Basic check if recipeId is valid
        require(_userLevel[msg.sender] >= recipe.requiredLevel, "User level too low for this recipe");

        // Consume ingredients and catalysts
        for (uint i = 0; i < recipe.ingredients.length; i++) {
            IngredientInput storage input = recipe.ingredients[i];
            uint256 requiredAmount = input.amount;
            if (input.isElement) {
                require(_userElements[msg.sender][input.id] >= requiredAmount, "Insufficient element ingredient");
                _userElements[msg.sender][input.id] -= requiredAmount;
            } else {
                require(_userComponents[msg.sender][input.id] >= requiredAmount, "Insufficient component ingredient");
                _userComponents[msg.sender][input.id] -= requiredAmount;
            }
        }
        for (uint i = 0; i < recipe.catalysts.length; i++) {
            IngredientInput storage input = recipe.catalysts[i];
            uint256 requiredAmount = input.amount;
            if (input.isElement) {
                 require(_userElements[msg.sender][input.id] >= requiredAmount, "Insufficient element catalyst");
                _userElements[msg.sender][input.id] -= requiredAmount;
            } else {
                require(_userComponents[msg.sender][input.id] >= requiredAmount, "Insufficient component catalyst");
                _userComponents[msg.sender][input.id] -= requiredAmount;
            }
        }

        bool success = _rollSuccess(recipe.successChance);

        if (success) {
            if (recipe.outputType == OutputType.Component) {
                _userComponents[msg.sender][recipe.outputId] += recipe.outputAmount;
                _grantXP(msg.sender, recipe.requiredLevel * 10); // XP based on recipe difficulty
                emit CraftSuccess(msg.sender, _recipeId, recipe.outputType, recipe.outputAmount);
            } else if (recipe.outputType == OutputType.Artifact) {
                uint256 newTokenId = _mintArtifact(msg.sender, _recipeId, recipe.artifactPropertyNames, recipe.artifactPropertyValues);
                 _grantXP(msg.sender, recipe.requiredLevel * 50); // More XP for crafting artifacts
                emit CraftSuccess(msg.sender, _recipeId, recipe.outputType, newTokenId);
                emit ArtifactMinted(msg.sender, newTokenId, _recipeId);
            }
        } else {
            // On failure, resources are consumed, no output, potentially some XP loss or gain?
            // For simplicity here, just consume resources and no output/XP gain.
            emit CraftFailed(msg.sender, _recipeId);
        }
    }

     // Note: This "discovery" function is simplified. It checks if provided inputs match a *known* recipe.
     // A more advanced version would potentially unveil *new* recipes not yet in the 'recipes' mapping.
    function discoverRecipeAttempt(IngredientInput[] memory _ingredients, IngredientInput[] memory _catalysts) public {
        // Define a small cost for the attempt
        uint256 discoveryCostElementId = 0; // Example: require 1 unit of Element 0 (e.g., "Curiosity Dust")
        uint256 discoveryCostAmount = 1;
        require(discoveryCostElementId < _nextElementId, "Discovery cost element not configured");
        require(_userElements[msg.sender][discoveryCostElementId] >= discoveryCostAmount, "Insufficient resources for discovery attempt");
        _userElements[msg.sender][discoveryCostElementId] -= discoveryCostAmount;

        bool foundMatch = false;
        uint256 matchedRecipeId = 0;

        // Iterate through all known recipes to find a match
        for (uint r = 0; r < allRecipeIds.length; r++) {
            uint256 currentRecipeId = allRecipeIds[r];
            Recipe storage recipe = recipes[currentRecipeId];

            bool ingredientsMatch = _checkInputsMatchRecipe(recipe.ingredients, _ingredients);
            bool catalystsMatch = _checkInputsMatchRecipe(recipe.catalysts, _catalysts);

            if (ingredientsMatch && catalystsMatch) {
                foundMatch = true;
                matchedRecipeId = currentRecipeId;
                // In a real system, you might return the recipe ID here,
                // or grant a temporary boost, or reveal it visually off-chain.
                // For this demo, we just emit the event.
                break; // Found a match, stop checking
            }
        }

        emit RecipeDiscoveredAttempt(msg.sender, foundMatch, matchedRecipeId);
         // Grant minimal XP for experimentation regardless of success
        _grantXP(msg.sender, 5);
    }

    // Helper to check if provided inputs exactly match recipe requirements
    function _checkInputsMatchRecipe(IngredientInput[] memory recipeInputs, IngredientInput[] memory providedInputs) internal pure returns (bool) {
        if (recipeInputs.length != providedInputs.length) {
            return false;
        }

        // Create maps for easier lookup
        mapping(uint256 => mapping(bool => uint256)) private recipeMap; // id => isElement => amount
        mapping(uint256 => mapping(bool => uint256)) private providedMap; // id => isElement => amount

        for(uint i = 0; i < recipeInputs.length; i++) {
            recipeMap[recipeInputs[i].id][recipeInputs[i].isElement] = recipeInputs[i].amount;
        }
         for(uint i = 0; i < providedInputs.length; i++) {
            providedMap[providedInputs[i].id][providedInputs[i].isElement] = providedInputs[i].amount;
        }

        // Check if amounts match for all recipe inputs
        for(uint i = 0; i < recipeInputs.length; i++) {
            IngredientInput memory recipeInput = recipeInputs[i];
            if (providedMap[recipeInput.id][recipeInput.isElement] != recipeInput.amount) {
                return false;
            }
        }

        // Check if there are any extra provided inputs not in the recipe (optional, depends on game design)
        // For exact match, iterate provided and check against recipeMap
         for(uint i = 0; i < providedInputs.length; i++) {
            IngredientInput memory providedInput = providedInputs[i];
            if (recipeMap[providedInput.id][providedInput.isElement] != providedInput.amount) {
                 return false; // Provided an ingredient not in the recipe or wrong amount
            }
        }


        return true;
    }


    function evolveArtifact(uint256 _artifactId, IngredientInput[] memory _ingredients, IngredientInput[] memory _catalysts) public onlyExistingArtifact(_artifactId) {
        require(_artifacts[_artifactId].owner == msg.sender, "Not the artifact owner");
        // Require a specific level or state for evolution? Add checks here.
        // require(_artifacts[_artifactId].level < MAX_ARTIFACT_LEVEL, "Artifact cannot evolve further");

        // Define evolution requirements (example: recipe-like check)
        // This could be hardcoded or stored in a separate 'evolutionRecipes' mapping.
        // For this demo, let's just require a fixed amount of specific resources + XP cost
        uint256 requiredXP = 1000 * (_artifacts[_artifactId].evolutionStage + 1); // XP cost increases with stage
        require(_userXP[msg.sender] >= requiredXP, "Insufficient XP to attempt evolution");
        _userXP[msg.sender] -= requiredXP;

         // Consume ingredients/catalysts based on the provided inputs (validation omitted for brevity, would be similar to craft)
         // ... resource consumption logic ...

        bool success = _rollSuccess(7000); // 70% base chance for evolution

        if (success) {
            Artifact storage artifact = _artifacts[_artifactId];
            artifact.level++;
            artifact.evolutionStage++;
            // Modify properties based on evolution or inputs (example: add a property, increase a value)
            // artifact.properties["Power"] = string(abi.encodePacked(uint256(parseInt(bytes(artifact.properties["Power"]), 10)) + 10)); // Example: requires parseInt helper
            // artifact.properties["Color"] = "Radiant"; // Example: change a property

            _grantXP(msg.sender, requiredXP / 2); // Grant back some XP on success
            emit ArtifactEvolved(_artifactId, artifact.level, artifact.evolutionStage);
        } else {
            // On failure, XP and resources are lost. Maybe artifact durability decreases?
            // For simplicity: loss of XP and resources, no artifact change.
            // artifact.durability = artifact.durability > 10 ? artifact.durability - 10 : 0;
            // Add event for failed evolution if needed.
        }
    }

    function burnArtifact(uint256 _artifactId) public onlyExistingArtifact(_artifactId) {
         require(_artifacts[_artifactId].owner == msg.sender, "Not the artifact owner");

        Artifact storage artifact = _artifacts[_artifactId];
        artifact.isBurned = true;
        // No need to zero out owner here for our minimal ERC721, _burnArtifact handles state
        _burnArtifact(_artifactId); // Update ERC721 state

        // Reward user for burning (example: some resources back, or XP)
        _grantXP(msg.sender, artifact.level * 20); // XP based on artifact level
        // Example: Return 50% of initial crafting ingredient cost (difficult to track precisely, simple fixed return is easier)
        // _userElements[msg.sender][elementId] += amount;

        emit ArtifactBurned(_artifactId, msg.sender);
    }

     // Example: Decomposing Component 1 yields Elements 0 and 2
     // This could be driven by 'decompositionRecipes' or hardcoded rules
    function decomposeComponent(uint256 _componentId, uint256 _amount) public {
        require(_componentId < _nextComponentId, "Invalid componentId");
        require(_amount > 0, "Amount must be greater than 0");
        require(_userComponents[msg.sender][_componentId] >= _amount, "Insufficient components");

        _userComponents[msg.sender][_componentId] -= _amount;

        // Define decomposition rules (hardcoded example)
        if (_componentId == 0) { // Assuming component 0 decomposes
            uint256 element1Id = 0; // Output element 1
            uint256 element2Id = 1; // Output element 2
            uint256 element1Amount = _amount * 2; // Example yield
            uint256 element2Amount = _amount * 1; // Example yield
            uint256 lossFactor = 10; // 10% loss example

            _userElements[msg.sender][element1Id] += element1Amount * (100 - lossFactor) / 100;
            _userElements[msg.sender][element2Id] += element2Amount * (100 - lossFactor) / 100;

             _grantXP(msg.sender, _amount * 5); // Grant XP for decomposition
        } else {
            // No decomposition rule for this component, components are just lost
             // Add an event or revert if decomposition is only for specific types
             revert("Component cannot be decomposed");
        }
    }

    // --- User Inventory/State Functions (View) ---

    function getUserElementBalance(address _user, uint256 _elementId) public view returns (uint256) {
        require(_elementId < _nextElementId, "Invalid elementId");
        return _userElements[_user][_elementId];
    }

    function getUserComponentBalance(address _user, uint256 _componentId) public view returns (uint256) {
        require(_componentId < _nextComponentId, "Invalid componentId");
        return _userComponents[_user][_componentId];
    }

    function getUserLevel(address _user) public view returns (uint256) {
        return _userLevel[_user];
    }

     function getUserXP(address _user) public view returns (uint256) {
        return _userXP[_user];
    }

    function getArtifactDetails(uint256 _artifactId) public view onlyExistingArtifact(_artifactId) returns (
        uint256 tokenId,
        address owner,
        uint48 creationTimestamp,
        uint256 provenanceRecipeId,
        uint16 level,
        uint16 durability,
        uint8 evolutionStage,
        string[] memory propertyNames,
        string[] memory propertyValues
    ) {
         Artifact storage artifact = _artifacts[_artifactId];
         tokenId = artifact.tokenId;
         owner = artifact.owner;
         creationTimestamp = artifact.creationTimestamp;
         provenanceRecipeId = artifact.provenanceRecipeId;
         level = artifact.level;
         durability = artifact.durability;
         evolutionStage = artifact.evolutionStage;

         // Fetch dynamic properties
         // This part is tricky due to mappings inside structs in view functions.
         // A common pattern is to store properties in separate top-level mappings
         // or limit the number/keys of properties to iterate.
         // For this demo, let's assume a maximum number of properties or fetch known keys.
         // A more robust solution needs off-chain indexing or a different state structure.
         // Let's return the base properties from the recipe for simplicity in a view function.
         // To return *current* dynamic properties would require iterating the artifact.properties mapping, which is complex in Solidity view.
         // Let's return the *base* properties from the recipe it was created from.

         Recipe storage recipe = recipes[artifact.provenanceRecipeId];
         propertyNames = recipe.artifactPropertyNames;
         propertyValues = recipe.artifactPropertyValues;

         // Note: This doesn't show properties added/changed by evolution.
         // A real dapp would need to query the artifact.properties mapping directly if possible or rely on events/off-chain data.
    }

    function getRecipeDetails(uint256 _recipeId) public view returns (
        IngredientInput[] memory ingredients,
        IngredientInput[] memory catalysts,
        uint256 requiredLevel,
        uint16 successChance,
        OutputType outputType,
        uint256 outputId,
        uint256 outputAmount,
        string[] memory artifactPropertyNames,
        string[] memory artifactPropertyValues
    ) {
        require(_recipeId < _nextRecipeId, "Invalid recipeId");
        Recipe storage recipe = recipes[_recipeId];
        ingredients = recipe.ingredients;
        catalysts = recipe.catalysts;
        requiredLevel = recipe.requiredLevel;
        successChance = recipe.successChance;
        outputType = recipe.outputType;
        outputId = recipe.outputId;
        outputAmount = recipe.outputAmount;
        artifactPropertyNames = recipe.artifactPropertyNames;
        artifactPropertyValues = recipe.artifactPropertyValues;
    }

    function listAllElementTypes() public view returns (uint256[] memory ids, string[] memory names) {
        ids = new uint256[](_nextElementId);
        names = new string[](_nextElementId);
        for (uint i = 0; i < _nextElementId; i++) {
            ids[i] = i;
            names[i] = elementNames[i];
        }
        return (ids, names);
    }

    function listAllComponentTypes() public view returns (uint256[] memory ids, string[] memory names) {
        ids = new uint256[](_nextComponentId);
        names = new string[](_nextComponentId);
        for (uint i = 0; i < _nextComponentId; i++) {
            ids[i] = i;
            names[i] = componentNames[i];
        }
        return (ids, names);
    }

    function listAllRecipeIds() public view returns (uint256[] memory) {
        return allRecipeIds;
    }

    function getXPRequirementForLevel(uint256 _level) public view returns(uint256) {
        return levelXPRequirements[_level];
    }


    // --- Minimal ERC721 Functions ---

    // This is a simplified implementation. A full ERC721 includes many more details
    // like tokenURIs, metadata, enumerable extensions, etc.

    // ERC721 standard requires these public view functions
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = _artifacts[_tokenId].owner;
        require(owner != address(0) && !_artifacts[_tokenId].isBurned, "ERC721: owner query for nonexistent or burned token");
        return owner;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        // Simplified transfer: only owner or approved can transfer
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_from != address(0), "ERC721: transfer from the zero address");
        require(_to != address(0), "ERC721: transfer to the zero address");
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own"); // Ensure _from is current owner

        _transferArtifact(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_artifacts[_tokenId].owner != address(0) && !_artifacts[_tokenId].isBurned, "ERC721: approved query for nonexistent or burned token");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }


     // --- Internal Helper Functions ---

    function _grantXP(address _user, uint256 _amount) internal {
        require(_amount > 0, "XP amount must be positive");
        uint256 currentXP = _userXP[_user];
        uint256 newXP = currentXP + _amount;
        _userXP[_user] = newXP;
        emit XPGranted(_user, _amount, newXP);
        _checkLevelUp(_user);
    }

    function _checkLevelUp(address _user) internal {
        uint256 currentLevel = _userLevel[_user];
        uint265 requiredXPForNextLevel = levelXPRequirements[currentLevel + 1]; // Level 1 requires levelXPRequirements[1]

        while (requiredXPForNextLevel > 0 && _userXP[_user] >= requiredXPForNextLevel) {
            currentLevel++;
            _userLevel[_user] = currentLevel;
            emit LevelUp(_user, currentLevel, currentLevel - 1);
            requiredXPForNextLevel = levelXPRequirements[currentLevel + 1];
        }
    }

    function _rollSuccess(uint16 _chance) internal view returns (bool) {
        // Simple pseudo-randomness using block data
        // NOTE: This is predictable to miners. For production, use Chainlink VRF or similar.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender))) % 10000;
        return randomNumber < _chance;
    }


    function _mintArtifact(address _to, uint256 _recipeId, string[] memory _propertyNames, string[] memory _propertyValues) internal returns (uint256) {
        require(_to != address(0), "ERC721: mint to the zero address");

        uint256 newTokenId = _nextTokenId++;
        _artifacts[newTokenId].tokenId = newTokenId;
        _artifacts[newTokenId].owner = _to;
        _artifacts[newTokenId].creationTimestamp = uint48(block.timestamp);
        _artifacts[newTokenId].provenanceRecipeId = _recipeId;
        _artifacts[newTokenId].level = 1; // Start at level 1
        _artifacts[newTokenId].durability = 100; // Initial durability
        _artifacts[newTokenId].evolutionStage = 0;

        // Set base properties from recipe (dynamic properties can be added/modified later)
        for(uint i = 0; i < _propertyNames.length; i++) {
            _artifacts[newTokenId].properties[_propertyNames[i]] = _propertyValues[i];
        }
        // Add some properties based on creation time, user level, etc. (example)
         _artifacts[newTokenId].properties["CrafterLevel"] = string(abi.encodePacked(_userLevel[msg.sender]));
         _artifacts[newTokenId].properties["CreationBlock"] = string(abi.encodePacked(block.number));
        // Add a random element to properties (using pseudo-randomness)
         uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, _to, newTokenId))) % 100 + 1;
         _artifacts[newTokenId].properties["RandomValue"] = string(abi.encodePacked(randomValue));


        _balances[_to]++;
        // No ERC721 Approval event needed on minting
        emit Transfer(address(0), _to, newTokenId);

        return newTokenId;
    }

    function _burnArtifact(uint256 _tokenId) internal onlyExistingArtifact(_tokenId) {
        address owner = _artifacts[_tokenId].owner;
        require(owner != address(0), "ERC721: burn of zero address token");

        // Clear approvals
        _tokenApprovals[_tokenId] = address(0);

        // Update state
        _balances[owner]--;
        // Keep artifact data but mark as burned.
        // _artifacts[_tokenId].owner = address(0); // Don't clear owner if we use isBurned flag

        emit Transfer(owner, address(0), _tokenId);
    }

    function _transferArtifact(address _from, address _to, uint256 _tokenId) internal onlyExistingArtifact(_tokenId) {
        require(_from != address(0), "ERC721: transfer from the zero address");
        require(_to != address(0), "ERC721: transfer to the zero address");
        require(_artifacts[_tokenId].owner == _from, "ERC721: transfer of token not owned by from");

        // Clear approvals
        _tokenApprovals[_tokenId] = address(0);

        // Update balances
        _balances[_from]--;
        _balances[_to]++;

        // Update artifact owner
        _artifacts[_tokenId].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    // Helper to check if sender is owner or approved
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId); // ownerOf includes existence check
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    // Example helper function to parse string to uint (requires more robust implementation for general use)
    // function parseInt(bytes memory s, uint _base) internal pure returns (uint) {
    //     bytes memory b = s;
    //     uint n = 0;
    //     for (uint i = 0; i < b.length; i++) {
    //         uint d;
    //         if (b[i] >= '0' && b[i] <= '9') {
    //             d = uint(uint8(b[i]) - uint8('0'));
    //         } else {
    //             revert("String contains non-digit character");
    //         }
    //         n = n * _base + d;
    //     }
    //     return n;
    // }

    // You would need more complex logic for artifact property updates based on evolution, catalysts, etc.
    // e.g., `function useArtifact(uint256 _artifactId) public onlyExistingArtifact(...)` that reduces durability or consumes 'charge'.

}
```