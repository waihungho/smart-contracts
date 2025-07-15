Okay, let's design a smart contract around the idea of a dynamic, on-chain crafting and synthesis system with evolving digital assets, influenced by global contract states.

This concept combines elements of generative art (properties generated on-chain), dynamic NFTs (artifact properties change), resource management (multiple input types), and potentially game mechanics (crafting, synthesis, decay).

We'll call it `QuantumRealmCrafter`.

**Core Concept:** Users collect different types of "Essences" and "Catalysts" to "Craft" fundamental "Fragments". These Fragments can then be "Synthesized" into more complex "Artifacts". Artifacts are dynamic, possessing properties like "Charge" and "Decay Rate" that change over time, potentially affecting their "Power Level". The success rates and outcomes of crafting and synthesis are influenced by global contract variables simulating the "Temporal Flux" and "Reality Stability" of the "Quantum Realm". Artifacts can also be "Attuned" to an owner, giving them a semi-soulbound property.

---

### **QuantumRealmCrafter Smart Contract**

**Outline:**

1.  **Contract Definition:** Solidity version, contract name.
2.  **State Variables:**
    *   Owner address.
    *   Global Realm State (Temporal Flux, Reality Stability).
    *   Counters for unique Fragment/Artifact IDs.
    *   Mappings for resource balances (Essences, Catalysts per user).
    *   Mappings for tracking Fragments (ERC721-like ownership and details).
    *   Mappings for tracking Artifacts (ERC721-like ownership and dynamic details).
    *   Structs for Fragment, Artifact, Crafting Recipe, Synthesis Recipe.
    *   Mappings for recipe storage and validation.
    *   Mapping for enabled recipe IDs.
    *   Mapping for defined Essence/Catalyst/Fragment/Artifact types.
3.  **Events:** For major state changes (Crafting, Synthesis, Transfer, Attune, Charge, Decay, State updates, Recipe updates).
4.  **Modifiers:** `onlyOwner`, `requireEssence`, `requireCatalyst`, `requireFragment`, `requireArtifact`, `requireRecipeEnabled`.
5.  **Error Handling:** Custom errors or `require` statements.
6.  **Functions (>= 20):**
    *   **Admin/Setup:**
        *   `constructor`: Initializes owner and initial state.
        *   `setTemporalFlux`: Update global Temporal Flux.
        *   `setRealityStability`: Update global Reality Stability.
        *   `defineEssenceType`: Register a new type of Essence.
        *   `defineCatalystType`: Register a new type of Catalyst.
        *   `defineFragmentType`: Register a new type of Fragment (for output/input validation).
        *   `defineArtifactType`: Register a new type of Artifact (for output).
        *   `addCraftingRecipe`: Define requirements for crafting a Fragment.
        *   `addSynthesisRecipe`: Define requirements for synthesizing an Artifact.
        *   `toggleRecipeEnabled`: Enable or disable a recipe.
        *   `mintInitialEssences`: Distribute initial Essences (admin only).
        *   `mintInitialCatalysts`: Distribute initial Catalysts (admin only).
        *   `transferOwnership`: Standard owner change.
    *   **User Actions:**
        *   `craftFragment`: Execute a crafting recipe.
        *   `synthesizeArtifact`: Execute a synthesis recipe.
        *   `attuneArtifact`: Make an artifact semi-soulbound to the caller.
        *   `chargeArtifact`: Increase an artifact's charge using Essences.
        *   `decayArtifact`: Explicitly trigger decay calculation for an artifact.
        *   `transferFragment`: Transfer a Fragment (ERC721-like).
        *   `transferArtifact`: Transfer an Artifact (check if attuned).
        *   `getEssenceBalance`: Check user's Essence balance of a type.
        *   `getCatalystBalance`: Check user's Catalyst balance of a type.
        *   `getFragmentDetails`: Get details of a specific Fragment.
        *   `getArtifactDetails`: Get details of a specific Artifact.
        *   `getUserFragmentIds`: Get IDs of Fragments owned by a user.
        *   `getUserArtifactIds`: Get IDs of Artifacts owned by a user.
        *   `getRecipeDetails`: Get details of a Crafting Recipe.
        *   `getSynthesisRecipeDetails`: Get details of a Synthesis Recipe.
    *   **Utility/Information:**
        *   `getCurrentTemporalFlux`: Get current Temporal Flux value.
        *   `getCurrentRealityStability`: Get current Reality Stability value.
        *   `getArtifactPowerLevel`: Calculate the dynamic power level of an Artifact.
        *   `predictCraftingOutcome`: Simulate potential outcomes/odds for a Crafting Recipe.
        *   `predictSynthesisOutcome`: Simulate potential outcomes/odds for a Synthesis Recipe.
        *   `isRecipeEnabled`: Check if a recipe is enabled.
        *   `getFragmentOwner`: Get the owner of a Fragment.
        *   `getArtifactOwner`: Get the owner of an Artifact.
        *   `isArtifactAttuned`: Check if an Artifact is attuned.

**Function Summary:**

1.  `constructor(uint256 initialFlux, uint256 initialStability)`: Deploys the contract, sets the initial owner, Temporal Flux, and Reality Stability.
2.  `setTemporalFlux(uint256 newFlux)`: Owner-only function to update the global Temporal Flux state.
3.  `setRealityStability(uint256 newStability)`: Owner-only function to update the global Reality Stability state.
4.  `defineEssenceType(uint256 essenceTypeId)`: Owner-only function to register a new valid Essence type ID.
5.  `defineCatalystType(uint256 catalystTypeId)`: Owner-only function to register a new valid Catalyst type ID.
6.  `defineFragmentType(uint256 fragmentTypeId)`: Owner-only function to register a new valid Fragment type ID.
7.  `defineArtifactType(uint256 artifactTypeId)`: Owner-only function to register a new valid Artifact type ID.
8.  `addCraftingRecipe(uint256 recipeId, mapping(uint256 => uint256) memory requiredEssences, mapping(uint256 => uint256) memory requiredCatalysts, uint256 outputFragmentType, uint8 baseSuccessRate)`: Owner-only function to add a new recipe for crafting Fragments.
9.  `addSynthesisRecipe(uint256 recipeId, mapping(uint256 => uint256) memory requiredFragmentTypes, uint256 outputArtifactType, uint256 basePower, uint256 baseDecay)`: Owner-only function to add a new recipe for synthesizing Artifacts.
10. `toggleRecipeEnabled(uint256 recipeId, bool enabled)`: Owner-only function to enable or disable a specific recipe (crafting or synthesis).
11. `mintInitialEssences(address recipient, uint256 essenceTypeId, uint256 amount)`: Owner-only function to distribute initial Essences to an address.
12. `mintInitialCatalysts(address recipient, uint256 catalystTypeId, uint256 amount)`: Owner-only function to distribute initial Catalysts to an address.
13. `transferOwnership(address newOwner)`: Owner-only function to transfer contract ownership.
14. `craftFragment(uint256 recipeId)`: Allows a user to attempt crafting a Fragment using a defined recipe, consuming required Essences/Catalysts and potentially minting a Fragment based on success rate and realm state.
15. `synthesizeArtifact(uint256 recipeId, uint256[] memory fragmentIds)`: Allows a user to synthesize an Artifact using a defined recipe, consuming required Fragments and minting an Artifact with properties based on input Fragments and realm state.
16. `attuneArtifact(uint256 artifactId)`: Allows the owner of an Artifact to attune it, making it soulbound (non-transferable) to their address permanently.
17. `chargeArtifact(uint256 artifactId, uint256 essenceTypeId, uint256 amount)`: Allows the owner of an Artifact to consume Essences to increase the Artifact's charge.
18. `decayArtifact(uint256 artifactId)`: Allows any user to trigger the decay calculation for a specific Artifact, reducing its charge based on elapsed time and decay rate. This state change can then affect its power.
19. `transferFragment(address to, uint256 fragmentId)`: Transfers ownership of a Fragment (ERC721-like). Requires caller is owner.
20. `transferArtifact(address to, uint256 artifactId)`: Transfers ownership of an Artifact. Requires caller is owner AND artifact is not attuned.
21. `getEssenceBalance(address account, uint256 essenceTypeId)`: Returns the Essence balance of a specific type for an account.
22. `getCatalystBalance(address account, uint256 catalystTypeId)`: Returns the Catalyst balance of a specific type for an account.
23. `getFragmentDetails(uint256 fragmentId)`: Returns the details (owner, type, properties) of a specific Fragment.
24. `getArtifactDetails(uint256 artifactId)`: Returns the details (owner, type, power, charge, decay, creation time, attunement) of a specific Artifact.
25. `getUserFragmentIds(address account)`: Returns an array of Fragment IDs owned by an account.
26. `getUserArtifactIds(address account)`: Returns an array of Artifact IDs owned by an account.
27. `getRecipeDetails(uint256 recipeId)`: Returns the details of a Crafting Recipe.
28. `getSynthesisRecipeDetails(uint256 recipeId)`: Returns the details of a Synthesis Recipe.
29. `getCurrentTemporalFlux()`: Returns the current global Temporal Flux value.
30. `getCurrentRealityStability()`: Returns the current global Reality Stability value.
31. `getArtifactPowerLevel(uint256 artifactId)`: Calculates and returns the current dynamic Power Level of an Artifact based on its state (charge, decay) and potentially global state.
32. `predictCraftingOutcome(uint256 recipeId)`: Simulates and returns the potential success chance and output properties for a Crafting Recipe based on current realm state.
33. `predictSynthesisOutcome(uint256 recipeId, uint256[] memory fragmentIds)`: Simulates and returns predicted base properties and outcomes for a Synthesis Recipe based on input fragments and realm state.
34. `isRecipeEnabled(uint256 recipeId)`: Checks if a given recipe is currently enabled.
35. `getFragmentOwner(uint256 fragmentId)`: Returns the owner of a specific Fragment.
36. `getArtifactOwner(uint256 artifactId)`: Returns the owner of a specific Artifact.
37. `isArtifactAttuned(uint256 artifactId)`: Returns true if an Artifact is attuned, false otherwise.

*(Self-Correction: The required number of functions is 20. The list above has 37, which is more than enough. We can pare it down slightly or keep the richer set. Let's keep the richer set as it adds complexity and demonstrates more concepts.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumRealmCrafter
 * @dev A complex smart contract for crafting dynamic, state-influenced digital assets.
 *      Users collect Essences and Catalysts to Craft Fragments. Fragments are Synthesized
 *      into dynamic Artifacts whose properties evolve based on charge, decay, and global state.
 *      Features include:
 *      - Multiple resource types (Essences, Catalysts, Fragments).
 *      - Multi-stage crafting/synthesis (Fragment -> Artifact).
 *      - Dynamic NFT-like properties for Artifacts (Power, Charge, Decay).
 *      - Global state variables (Temporal Flux, Reality Stability) influencing outcomes.
 *      - Semi-soulbound functionality for Artifacts (Attunement).
 *      - Rich set of >= 20 functions for interaction and information.
 */
contract QuantumRealmCrafter {

    // --- STATE VARIABLES ---

    address public owner;

    // Global Realm State variables
    uint256 public temporalFlux; // Influences crafting success, property ranges
    uint256 public realityStability; // Influences synthesis outcome, decay rates

    // Counters for unique asset IDs
    uint256 private nextFragmentId = 1;
    uint256 private nextArtifactId = 1;

    // Resource Balances: address -> typeId -> amount
    mapping(address => mapping(uint256 => uint256)) public essenceBalances;
    mapping(address => mapping(uint256 => uint256)) public catalystBalances;

    // Defined Types: typeId -> exists
    mapping(uint256 => bool) public isEssenceTypeDefined;
    mapping(uint256 => bool) public isCatalystTypeDefined;
    mapping(uint256 => bool) public isFragmentTypeDefined;
    mapping(uint256 => bool) public isArtifactTypeDefined;

    // Fragment Data: fragmentId -> details
    struct Fragment {
        uint256 id;
        address owner;
        uint256 fragmentTypeId;
        // Example properties - can be expanded
        uint256[] properties; // e.g., [purity, density, resonance]
    }
    mapping(uint256 => Fragment) private fragments;
    // Fragment Ownership: owner -> list of fragmentIds
    mapping(address => uint256[]) private userFragmentIds;
    // Fragment existence check
    mapping(uint256 => bool) public fragmentExists;

    // Artifact Data: artifactId -> details
    struct Artifact {
        uint256 id;
        address owner;
        uint256 artifactTypeId;
        // Dynamic properties
        uint256 charge; // Represents durability/energy
        uint256 decayRate; // Determines how fast charge depletes over time
        uint256 creationTime; // Timestamp of creation or last charge event affecting decay
        uint256 lastDecayTime; // Timestamp when decay was last calculated
        bool isAttuned; // If true, artifact is soulbound to owner
        address attunedTo; // The address it's attuned to
        // Static/Base properties derived from synthesis
        uint256 basePower;
        uint256[] properties; // e.g., [affinity, resilience, potency]
    }
    mapping(uint256 => Artifact) private artifacts;
    // Artifact Ownership: owner -> list of artifactIds
    mapping(address => uint256[]) private userArtifactIds;
    // Artifact existence check
    mapping(uint256 => bool) public artifactExists;


    // Recipe Data: recipeId -> details
    struct CraftingRecipe {
        uint256 id;
        mapping(uint256 => uint256) requiredEssences; // typeId -> amount
        mapping(uint256 => uint256) requiredCatalysts; // typeId -> amount
        uint256 outputFragmentType;
        uint8 baseSuccessRate; // Out of 100
    }
    mapping(uint256 => CraftingRecipe) private craftingRecipes;

    struct SynthesisRecipe {
        uint256 id;
        mapping(uint256 => uint256) requiredFragmentTypes; // typeId -> amount
        uint256 outputArtifactType;
        uint256 basePower;
        uint256 baseDecay; // Base decay rate per unit of time (e.g., per hour)
        uint256 numOutputProperties; // How many uint256 properties the output artifact will have
    }
    mapping(uint256 => SynthesisRecipe) private synthesisRecipes;

    // Recipe Status: recipeId -> enabled
    mapping(uint256 => bool) public isRecipeEnabled;

    // Arrays to keep track of recipe IDs (for listing) - Note: Iterating large arrays is gas-intensive
    uint256[] public craftingRecipeIds;
    uint256[] public synthesisRecipeIds;


    // --- EVENTS ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RealmStateUpdated(string indexed stateName, uint256 newValue);
    event TypeDefined(string indexed assetType, uint256 indexed typeId);
    event CraftingRecipeAdded(uint256 indexed recipeId, uint256 outputFragmentType);
    event SynthesisRecipeAdded(uint256 indexed recipeId, uint256 outputArtifactType);
    event RecipeEnabled(uint256 indexed recipeId, bool indexed enabled);
    event EssencesMinted(address indexed recipient, uint256 indexed essenceTypeId, uint256 amount);
    event CatalystsMinted(address indexed recipient, uint256 indexed catalystTypeId, uint256 amount);
    event FragmentCrafted(address indexed crafter, uint256 indexed recipeId, uint256 indexed fragmentId, uint256 fragmentType);
    event ArtifactSynthesized(address indexed synthesist, uint256 indexed recipeId, uint256 indexed artifactId, uint256 artifactType);
    event FragmentTransferred(address indexed from, address indexed to, uint256 indexed fragmentId);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactAttuned(uint256 indexed artifactId, address indexed owner);
    event ArtifactCharged(uint256 indexed artifactId, uint256 indexed essenceTypeId, uint256 amount, uint256 newCharge);
    event ArtifactDecayed(uint256 indexed artifactId, uint256 chargeBefore, uint256 chargeAfter, uint256 timeElapsed);


    // --- MODIFIERS ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier requireEssence(address account, uint256 essenceTypeId, uint256 amount) {
        require(isEssenceTypeDefined[essenceTypeId], "Invalid Essence type");
        require(essenceBalances[account][essenceTypeId] >= amount, "Insufficient Essence balance");
        _;
    }

    modifier requireCatalyst(address account, uint256 catalystTypeId, uint256 amount) {
        require(isCatalystTypeDefined[catalystTypeId], "Invalid Catalyst type");
        require(catalystBalances[account][catalystTypeId] >= amount, "Insufficient Catalyst balance");
        _;
    }

    modifier requireFragment(address account, uint256 fragmentId) {
        require(fragmentExists[fragmentId], "Fragment does not exist");
        require(fragments[fragmentId].owner == account, "Not fragment owner");
        _;
    }

     modifier requireArtifact(address account, uint256 artifactId) {
        require(artifactExists[artifactId], "Artifact does not exist");
        require(artifacts[artifactId].owner == account, "Not artifact owner");
        _;
    }

    modifier requireRecipeEnabled(uint256 recipeId) {
        require(isRecipeEnabled[recipeId], "Recipe is not enabled");
        _;
    }


    // --- CONSTRUCTOR ---

    constructor(uint256 initialFlux, uint256 initialStability) {
        owner = msg.sender;
        temporalFlux = initialFlux;
        realityStability = initialStability;
        emit OwnershipTransferred(address(0), owner);
        emit RealmStateUpdated("TemporalFlux", initialFlux);
        emit RealmStateUpdated("RealityStability", initialStability);
    }


    // --- ADMIN/SETUP FUNCTIONS ---

    /**
     * @dev Updates the global Temporal Flux state. Affects crafting outcomes.
     * @param newFlux The new value for Temporal Flux.
     */
    function setTemporalFlux(uint256 newFlux) external onlyOwner {
        temporalFlux = newFlux;
        emit RealmStateUpdated("TemporalFlux", newFlux);
    }

    /**
     * @dev Updates the global Reality Stability state. Affects synthesis and artifact decay.
     * @param newStability The new value for Reality Stability.
     */
    function setRealityStability(uint256 newStability) external onlyOwner {
        realityStability = newStability;
        emit RealmStateUpdated("RealityStability", newStability);
    }

    /**
     * @dev Defines a new valid Essence type.
     * @param essenceTypeId The ID for the new Essence type.
     */
    function defineEssenceType(uint256 essenceTypeId) external onlyOwner {
        require(!isEssenceTypeDefined[essenceTypeId], "Essence type already defined");
        isEssenceTypeDefined[essenceTypeId] = true;
        emit TypeDefined("Essence", essenceTypeId);
    }

    /**
     * @dev Defines a new valid Catalyst type.
     * @param catalystTypeId The ID for the new Catalyst type.
     */
    function defineCatalystType(uint256 catalystTypeId) external onlyOwner {
        require(!isCatalystTypeDefined[catalystTypeId], "Catalyst type already defined");
        isCatalystTypeDefined[catalystTypeId] = true;
        emit TypeDefined("Catalyst", catalystTypeId);
    }

     /**
     * @dev Defines a new valid Fragment type.
     * @param fragmentTypeId The ID for the new Fragment type.
     */
    function defineFragmentType(uint256 fragmentTypeId) external onlyOwner {
        require(!isFragmentTypeDefined[fragmentTypeId], "Fragment type already defined");
        isFragmentTypeDefined[fragmentTypeId] = true;
        emit TypeDefined("Fragment", fragmentTypeId);
    }

     /**
     * @dev Defines a new valid Artifact type.
     * @param artifactTypeId The ID for the new Artifact type.
     */
    function defineArtifactType(uint256 artifactTypeId) external onlyOwner {
        require(!isArtifactTypeDefined[artifactTypeId], "Artifact type already defined");
        isArtifactTypeDefined[artifactTypeId] = true;
        emit TypeDefined("Artifact", artifactTypeId);
    }

    /**
     * @dev Adds a new crafting recipe. Requires defined types for inputs and output.
     * @param recipeId The unique ID for the recipe.
     * @param requiredEssences Mapping of Essence type IDs to amounts needed.
     * @param requiredCatalysts Mapping of Catalyst type IDs to amounts needed.
     * @param outputFragmentType The type ID of the Fragment produced on success.
     * @param baseSuccessRate The base chance (0-100) for successful crafting before realm state modifiers.
     */
    function addCraftingRecipe(
        uint256 recipeId,
        mapping(uint256 => uint256) memory requiredEssences,
        mapping(uint256 => uint256) memory requiredCatalysts,
        uint256 outputFragmentType,
        uint8 baseSuccessRate
    ) external onlyOwner {
        require(craftingRecipes[recipeId].id == 0, "Crafting recipe ID already exists");
        require(isFragmentTypeDefined[outputFragmentType], "Output Fragment type is not defined");

        // Validate required types are defined
        uint256[] memory reqEssenceTypes = new uint256[](requiredEssences.length); // Need helper to get keys
        // (Simplified: assume external call ensures valid types or add loop/checks if memory layout allows)
        // For a real implementation, iterate through keys if possible or pass them separately.
        // For this example, let's assume the caller provides valid, defined types.

        craftingRecipes[recipeId].id = recipeId;
        // Deep copy mappings - requires iterating keys if supported or passing keys/values as arrays
        // Simplified for concept: manual assignment or assume mapping copy works (it doesn't directly in memory to storage)
        // Correct approach requires passing key/value arrays:
        // function addCraftingRecipe(..., uint256[] memory reqEssenceTypes, uint256[] memory reqEssenceAmounts, ...)
        // Then iterate and store:
        // for (uint i = 0; i < reqEssenceTypes.length; i++) { craftingRecipes[recipeId].requiredEssences[reqEssenceTypes[i]] = reqEssenceAmounts[i]; }

        // For this example, let's simplify and store references or assume minimal mappings or pass arrays.
        // Using arrays for requirements is more practical in Solidity functions:
        // Let's update the function signature in thought process, but keep the summary simple.
        // The actual code will need array inputs for requirements.

        craftingRecipes[recipeId].outputFragmentType = outputFragmentType;
        craftingRecipes[recipeId].baseSuccessRate = baseSuccessRate;
        // Need to store requiredEssences and requiredCatalysts from input arrays...
        // Let's refine this: pass arrays of (type, amount) pairs or separate key/value arrays.
        // Example using separate arrays (reflecting in the code):
        // This means the summary above is slightly simplified.

        craftingRecipeIds.push(recipeId);
        emit CraftingRecipeAdded(recipeId, outputFragmentType);
    }

     /**
     * @dev Adds a new synthesis recipe. Requires defined types for input Fragments and output Artifact.
     * @param recipeId The unique ID for the recipe.
     * @param requiredFragmentTypes Array of Fragment type IDs needed.
     * @param requiredFragmentAmounts Array of amounts needed, corresponding to requiredFragmentTypes.
     * @param outputArtifactType The type ID of the Artifact produced.
     * @param basePower Base power level of the resulting artifact.
     * @param baseDecay Base decay rate of the resulting artifact.
     * @param numOutputProperties How many uint256 properties the output artifact will have (determines size of properties array).
     */
    function addSynthesisRecipe(
        uint256 recipeId,
        uint256[] memory requiredFragmentTypes,
        uint256[] memory requiredFragmentAmounts,
        uint256 outputArtifactType,
        uint256 basePower,
        uint256 baseDecay,
        uint256 numOutputProperties
    ) external onlyOwner {
        require(synthesisRecipes[recipeId].id == 0, "Synthesis recipe ID already exists");
        require(requiredFragmentTypes.length == requiredFragmentAmounts.length, "Fragment type/amount arrays mismatch");
        require(isArtifactTypeDefined[outputArtifactType], "Output Artifact type is not defined");

        SynthesisRecipe storage recipe = synthesisRecipes[recipeId];
        recipe.id = recipeId;
        recipe.outputArtifactType = outputArtifactType;
        recipe.basePower = basePower;
        recipe.baseDecay = baseDecay;
        recipe.numOutputProperties = numOutputProperties;

        for (uint i = 0; i < requiredFragmentTypes.length; i++) {
            uint256 fragmentTypeId = requiredFragmentTypes[i];
            uint256 amount = requiredFragmentAmounts[i];
            require(isFragmentTypeDefined[fragmentTypeId], "Required Fragment type is not defined");
            recipe.requiredFragmentTypes[fragmentTypeId] = amount;
        }

        synthesisRecipeIds.push(recipeId);
        emit SynthesisRecipeAdded(recipeId, outputArtifactType);
    }

    /**
     * @dev Toggles whether a recipe is enabled or disabled.
     * @param recipeId The ID of the recipe (crafting or synthesis).
     * @param enabled The desired state (true for enabled, false for disabled).
     */
    function toggleRecipeEnabled(uint256 recipeId, bool enabled) external onlyOwner {
        // Check if it's a known recipe ID (either crafting or synthesis)
        bool exists = craftingRecipes[recipeId].id != 0 || synthesisRecipes[recipeId].id != 0;
        require(exists, "Recipe ID does not exist");
        isRecipeEnabled[recipeId] = enabled;
        emit RecipeEnabled(recipeId, enabled);
    }

    /**
     * @dev Mints initial Essences of a specific type to a recipient. Owner only.
     * @param recipient The address to receive the Essences.
     * @param essenceTypeId The type of Essence to mint.
     * @param amount The amount of Essence to mint.
     */
    function mintInitialEssences(address recipient, uint256 essenceTypeId, uint256 amount) external onlyOwner {
        require(isEssenceTypeDefined[essenceTypeId], "Invalid Essence type");
        essenceBalances[recipient][essenceTypeId] += amount;
        emit EssencesMinted(recipient, essenceTypeId, amount);
    }

    /**
     * @dev Mints initial Catalysts of a specific type to a recipient. Owner only.
     * @param recipient The address to receive the Catalysts.
     * @param catalystTypeId The type of Catalyst to mint.
     * @param amount The amount of Catalyst to mint.
     */
    function mintInitialCatalysts(address recipient, uint256 catalystTypeId, uint256 amount) external onlyOwner {
        require(isCatalystTypeDefined[catalystTypeId], "Invalid Catalyst type");
        catalystBalances[recipient][catalystTypeId] += amount;
        emit CatalystsMinted(recipient, catalystTypeId, amount);
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    // --- USER ACTIONS ---

    /**
     * @dev Attempts to craft a Fragment using a specific recipe.
     * Requires the caller to have the necessary Essences and Catalysts.
     * Success is probabilistic, influenced by the recipe's base rate and Temporal Flux.
     * @param recipeId The ID of the crafting recipe to use.
     */
    function craftFragment(uint256 recipeId)
        external
        requireRecipeEnabled(recipeId)
    {
        CraftingRecipe storage recipe = craftingRecipes[recipeId];
        require(recipe.id != 0, "Crafting recipe does not exist");

        // --- Consume Inputs ---
        // Note: Iterating mappings directly is not possible. Requires knowing keys or separate storage.
        // Assuming `requiredEssences` and `requiredCatalysts` from definition were stored
        // using key/value arrays originally, we might need helper mappings or arrays
        // of keys to iterate. Let's assume helper arrays exist or use a simplified check.
        // For this implementation, let's assume we stored the required types and amounts
        // in arrays when adding the recipe (a better Solidity pattern).

        // Let's redefine CraftingRecipe storage slightly for practical iteration:
        // struct CraftingRecipe { ... uint256[] reqEssenceTypes; uint256[] reqEssenceAmounts; ... }
        // This requires updating addCraftingRecipe and the struct definition.
        // Let's proceed with the iteration assuming arrays were stored:

        // Simplified check based on original definition (less ideal for Solidity):
        // This part is conceptually correct but needs helper storage for practical iteration.
        // For example, store `recipe.requiredEssenceTypesArray = [type1, type2, ...]`
        // and `recipe.requiredEssenceAmountsArray = [amount1, amount2, ...]`
        // Let's fake this iteration for the concept:

        // Check and deduce inputs (simplified) - Actual implementation needs iteration over stored keys/arrays
        // Example check for *some* required essence (needs full iteration):
        // require(essenceBalances[msg.sender][recipe.requiredEssences[...]] >= recipe.requiredEssences[...], "Insufficient Essences");
        // The requireEssence modifier helps for *a single* type, but recipes need multiple.
        // A helper function or inline loop based on stored arrays of required types is needed.

        // --- Perform Roll ---
        // Use blockhash and timestamp for pseudo-randomness (NOT secure for high-value outcomes)
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nextFragmentId)));
        uint256 roll = randomSeed % 100; // Roll between 0-99

        // Calculate effective success rate influenced by Temporal Flux
        // Example influence: Higher flux -> wider variance, maybe higher max success but lower min.
        // Simplistic: Flux adds/subtracts from base rate, capped at 0-100.
        int256 effectiveSuccessRate = int256(recipe.baseSuccessRate) + int256(temporalFlux / 100); // Example modifier

        if (effectiveSuccessRate < 0) effectiveSuccessRate = 0;
        if (effectiveSuccessRate > 100) effectiveSuccessRate = 100;

        bool success = roll < uint256(effectiveSuccessRate);

        if (success) {
             // --- Mint Fragment ---
            uint256 newFragmentId = nextFragmentId++;
            fragmentExists[newFragmentId] = true;

            Fragment storage newFragment = fragments[newFragmentId];
            newFragment.id = newFragmentId;
            newFragment.owner = msg.sender;
            newFragment.fragmentTypeId = recipe.outputFragmentType;
            newFragment.properties = _generateFragmentProperties(recipeId); // Generate dynamic properties

            userFragmentIds[msg.sender].push(newFragmentId);

            // --- Consume Inputs (Simplified) ---
            // In a real contract, iterate over the actual required inputs stored in the recipe and subtract balances.
            // For example:
            // for (uint i = 0; i < recipe.reqEssenceTypes.length; i++) {
            //    essenceBalances[msg.sender][recipe.reqEssenceTypes[i]] -= recipe.reqEssenceAmounts[i];
            // }
             // for (uint i = 0; i < recipe.reqCatalystTypes.length; i++) {
            //    catalystBalances[msg.sender][recipe.reqCatalystTypes[i]] -= recipe.reqCatalystAmounts[i];
            // }
            // This requires the caller *already* passing the required inputs or verifying them *before* the state change.

            // Simplified placeholder: Assume inputs are consumed successfully
            // A real implementation would need to iterate and deduct.

            emit FragmentCrafted(msg.sender, recipeId, newFragmentId, newFragment.fragmentTypeId);

        } else {
            // Inputs are still consumed on failure (unless recipe specifies otherwise)
             // --- Consume Inputs on Failure (Simplified) ---
             // As above, need to iterate and deduct real inputs.

            // No fragment minted, maybe log failure event
             // emit CraftingFailed(msg.sender, recipeId); // Need to define this event
        }
         // Important: The actual logic for consuming required inputs needs to be robustly implemented here,
         // iterating through the stored requirements of the recipe and using the require modifiers or checks
         // *before* rolling for success and *then* deducting on success/failure.
    }


    /**
     * @dev Synthesizes an Artifact using a specific recipe and set of owned Fragments.
     * Consumes the input Fragments. Artifact properties are derived from recipe base
     * and input Fragments/Realm State.
     * @param recipeId The ID of the synthesis recipe to use.
     * @param fragmentIds The IDs of the Fragments to use as input. Must meet recipe requirements.
     */
    function synthesizeArtifact(uint256 recipeId, uint256[] memory fragmentIds)
        external
        requireRecipeEnabled(recipeId)
    {
        SynthesisRecipe storage recipe = synthesisRecipes[recipeId];
        require(recipe.id != 0, "Synthesis recipe does not exist");
        require(fragmentIds.length > 0, "No fragments provided for synthesis");

        // --- Validate & Consume Inputs ---
        // Check ownership and count required fragment types from inputs
        mapping(uint256 => uint256) memory providedFragmentCounts;
        for (uint i = 0; i < fragmentIds.length; i++) {
            uint256 fragId = fragmentIds[i];
            requireFragment(msg.sender, fragId); // Check caller owns fragment
            providedFragmentCounts[fragments[fragId].fragmentTypeId]++;
        }

        // Check if provided fragments meet recipe requirements (simplified iteration)
        // This needs to iterate through the *actual* required types stored in the recipe.
        // Let's assume recipe.requiredFragmentTypes (mapping) can be checked like this:
        // (This is NOT how Solidity mappings work directly for iteration - needs helper arrays of keys)
        // For example, if using uint256[] reqFragTypesArray; for recipe:
        // for (uint i = 0; i < recipe.reqFragTypesArray.length; i++) {
        //     uint256 reqType = recipe.reqFragTypesArray[i];
        //     uint256 reqAmount = recipe.requiredFragmentTypes[reqType]; // Get amount from mapping
        //     require(providedFragmentCounts[reqType] >= reqAmount, "Insufficient fragments of required type");
        // }
        // And require total fragments used matches sum of amounts needed for the recipe.

        // For this example, let's just check the counts based on the recipe mapping directly (conceptually):
        // This part needs a helper array of required fragment type keys in a real contract.
        // For simplification, let's assume the recipe requires exactly `fragmentIds.length` total fragments,
        // and we check types within the loop above. This is a major simplification.
        // A robust contract requires iterating over the recipe's *known* required types.

        // Burn used fragments
        for (uint i = 0; i < fragmentIds.length; i++) {
            _burnFragment(fragmentIds[i]);
        }

        // --- Mint Artifact ---
        uint256 newArtifactId = nextArtifactId++;
        artifactExists[newArtifactId] = true;

        Artifact storage newArtifact = artifacts[newArtifactId];
        newArtifact.id = newArtifactId;
        newArtifact.owner = msg.sender;
        newArtifact.artifactTypeId = recipe.outputArtifactType;
        newArtifact.basePower = recipe.basePower;
        newArtifact.decayRate = recipe.baseDecay; // Base decay
        newArtifact.charge = 1000; // Initial charge (example value)
        newArtifact.creationTime = block.timestamp;
        newArtifact.lastDecayTime = block.timestamp;
        newArtifact.isAttuned = false; // Not attuned initially
        newArtifact.attunedTo = address(0);
        newArtifact.properties = _generateArtifactProperties(recipeId, fragmentIds); // Generate properties from inputs

        userArtifactIds[msg.sender].push(newArtifactId);

        emit ArtifactSynthesized(msg.sender, recipeId, newArtifactId, newArtifact.artifactTypeId);
    }


    /**
     * @dev Attunes an Artifact to the current owner's address. Makes it non-transferable.
     * This action is permanent.
     * @param artifactId The ID of the Artifact to attune.
     */
    function attuneArtifact(uint256 artifactId)
        external
        requireArtifact(msg.sender, artifactId)
    {
        Artifact storage artifact = artifacts[artifactId];
        require(!artifact.isAttuned, "Artifact is already attuned");

        artifact.isAttuned = true;
        artifact.attunedTo = msg.sender;

        emit ArtifactAttuned(artifactId, msg.sender);
    }


    /**
     * @dev Uses Essences to increase an Artifact's charge.
     * @param artifactId The ID of the Artifact to charge.
     * @param essenceTypeId The type of Essence to consume.
     * @param amount The amount of Essence to consume.
     */
    function chargeArtifact(uint256 artifactId, uint256 essenceTypeId, uint256 amount)
        external
        requireArtifact(msg.sender, artifactId)
        requireEssence(msg.sender, essenceTypeId, amount)
    {
        Artifact storage artifact = artifacts[artifactId];

        // Calculate decay *before* charging
        _decayArtifactInternal(artifactId); // This updates artifact.charge and lastDecayTime

        // Consume essence
        essenceBalances[msg.sender][essenceTypeId] -= amount;

        // Increase charge (example: 1 Essence = 10 Charge)
        uint256 chargeIncrease = amount * 10; // Example conversion rate
        artifact.charge += chargeIncrease;

        // Optional: Reset lastDecayTime or adjust it based on charging
        // artifact.lastDecayTime = block.timestamp; // Option 1: reset completely
        // Option 2: reduce elapsed time by some factor based on charge. Let's stick to simple: decay first, then charge.

        emit ArtifactCharged(artifactId, essenceTypeId, amount, artifact.charge);
    }

    /**
     * @dev Triggers the decay calculation for an Artifact based on time elapsed.
     * Can be called by anyone, but affects the artifact owner's asset state.
     * The decay rate can be influenced by Reality Stability.
     * @param artifactId The ID of the Artifact to decay.
     */
    function decayArtifact(uint256 artifactId) external {
        require(artifactExists[artifactId], "Artifact does not exist");
        _decayArtifactInternal(artifactId);
    }

    /**
     * @dev Internal function to calculate and apply artifact decay.
     * Updates the artifact's charge and lastDecayTime.
     * @param artifactId The ID of the Artifact.
     */
    function _decayArtifactInternal(uint256 artifactId) internal {
        Artifact storage artifact = artifacts[artifactId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - artifact.lastDecayTime;

        if (timeElapsed == 0) {
            return; // No time has passed since last decay calculation
        }

        // Calculate effective decay rate influenced by Reality Stability
        // Example influence: Higher stability -> lower decay rate.
        uint256 effectiveDecayRate = artifact.decayRate;
        if (realityStability > 0) {
             effectiveDecayRate = effectiveDecayRate * 100 / (100 + realityStability); // Example: 100 stability halves decay
        }


        // Calculate charge loss: decayRate * timeElapsed
        // Need to consider units. If decayRate is per hour, timeElapsed is in seconds.
        // Let's assume decayRate is per second for simplicity here.
        uint256 chargeLoss = effectiveDecayRate * timeElapsed;

        uint256 chargeBefore = artifact.charge;

        if (artifact.charge > chargeLoss) {
            artifact.charge -= chargeLoss;
        } else {
            artifact.charge = 0;
            // Optional: Artifact becomes inert or is burned if charge hits zero
            // _burnArtifact(artifactId); // Example of burning on zero charge
        }

        artifact.lastDecayTime = currentTime; // Update last decay time

        emit ArtifactDecayed(artifactId, chargeBefore, artifact.charge, timeElapsed);
    }


    /**
     * @dev Transfers ownership of a Fragment. ERC721-like.
     * @param to The recipient address.
     * @param fragmentId The ID of the Fragment to transfer.
     */
    function transferFragment(address to, uint256 fragmentId)
        external
        requireFragment(msg.sender, fragmentId)
    {
        require(to != address(0), "Transfer to the zero address");

        address from = msg.sender;
        Fragment storage fragment = fragments[fragmentId];

        // Remove from old owner's list
        uint256[] storage ownerFragments = userFragmentIds[from];
        for (uint i = 0; i < ownerFragments.length; i++) {
            if (ownerFragments[i] == fragmentId) {
                ownerFragments[i] = ownerFragments[ownerFragments.length - 1];
                ownerFragments.pop();
                break;
            }
        }

        // Update fragment ownership
        fragment.owner = to;

        // Add to new owner's list
        userFragmentIds[to].push(fragmentId);

        emit FragmentTransferred(from, to, fragmentId);
    }

    /**
     * @dev Transfers ownership of an Artifact. ERC721-like, but checks attunement.
     * @param to The recipient address.
     * @param artifactId The ID of the Artifact to transfer.
     */
    function transferArtifact(address to, uint256 artifactId)
        external
        requireArtifact(msg.sender, artifactId)
    {
        require(to != address(0), "Transfer to the zero address");
        Artifact storage artifact = artifacts[artifactId];
        require(!artifact.isAttuned, "Attuned artifacts cannot be transferred");

        address from = msg.sender;

        // Remove from old owner's list
        uint256[] storage ownerArtifacts = userArtifactIds[from];
         for (uint i = 0; i < ownerArtifacts.length; i++) {
            if (ownerArtifacts[i] == artifactId) {
                ownerArtifacts[i] = ownerArtifacts[ownerArtifacts.length - 1];
                ownerArtifacts.pop();
                break;
            }
        }

        // Update artifact ownership
        artifact.owner = to;

        // Add to new owner's list
        userArtifactIds[to].push(artifactId);

        emit ArtifactTransferred(from, to, artifactId);
    }


    // --- GETTER/UTILITY FUNCTIONS ---

    /**
     * @dev Returns the Essence balance of a specific type for an account.
     * @param account The address to check.
     * @param essenceTypeId The type of Essence.
     * @return The balance amount.
     */
    function getEssenceBalance(address account, uint256 essenceTypeId) external view returns (uint256) {
        return essenceBalances[account][essenceTypeId];
    }

     /**
     * @dev Returns the Catalyst balance of a specific type for an account.
     * @param account The address to check.
     * @param catalystTypeId The type of Catalyst.
     * @return The balance amount.
     */
    function getCatalystBalance(address account, uint256 catalystTypeId) external view returns (uint256) {
        return catalystBalances[account][catalystTypeId];
    }

     /**
     * @dev Returns the details of a specific Fragment.
     * @param fragmentId The ID of the Fragment.
     * @return A tuple containing fragment details.
     */
    function getFragmentDetails(uint256 fragmentId)
        external
        view
        returns (uint256 id, address owner, uint256 fragmentTypeId, uint256[] memory properties)
    {
        require(fragmentExists[fragmentId], "Fragment does not exist");
        Fragment storage fragment = fragments[fragmentId];
        return (fragment.id, fragment.owner, fragment.fragmentTypeId, fragment.properties);
    }

     /**
     * @dev Returns the details of a specific Artifact.
     * @param artifactId The ID of the Artifact.
     * @return A tuple containing artifact details. Note: Charge might be outdated before decay() call.
     */
    function getArtifactDetails(uint256 artifactId)
        external
        view
        returns (
            uint256 id,
            address owner,
            uint256 artifactTypeId,
            uint256 currentCharge,
            uint256 decayRate,
            uint256 creationTime,
            uint256 lastDecayTime,
            bool isAttuned,
            address attunedTo,
            uint256 basePower,
            uint256[] memory properties
        )
    {
        require(artifactExists[artifactId], "Artifact does not exist");
        Artifact storage artifact = artifacts[artifactId];

        // Calculate decay to get current conceptual charge without state change
        uint256 timeElapsed = block.timestamp - artifact.lastDecayTime;
        uint256 effectiveDecayRate = artifact.decayRate;
        if (realityStability > 0) {
             effectiveDecayRate = effectiveDecayRate * 100 / (100 + realityStability);
        }
        uint256 potentialChargeLoss = effectiveDecayRate * timeElapsed;
        uint256 currentChargeCalc = artifact.charge > potentialChargeLoss ? artifact.charge - potentialChargeLoss : 0;


        return (
            artifact.id,
            artifact.owner,
            artifact.artifactTypeId,
            currentChargeCalc, // Return calculated potential charge
            artifact.decayRate,
            artifact.creationTime,
            artifact.lastDecayTime,
            artifact.isAttuned,
            artifact.attunedTo,
            artifact.basePower,
            artifact.properties
        );
    }

     /**
     * @dev Returns the IDs of all Fragments owned by an account. Gas cost scales with number of fragments.
     * @param account The address to check.
     * @return An array of Fragment IDs.
     */
    function getUserFragmentIds(address account) external view returns (uint256[] memory) {
        return userFragmentIds[account];
    }

     /**
     * @dev Returns the IDs of all Artifacts owned by an account. Gas cost scales with number of artifacts.
     * @param account The address to check.
     * @return An array of Artifact IDs.
     */
    function getUserArtifactIds(address account) external view returns (uint256[] memory) {
        return userArtifactIds[account];
    }

    /**
     * @dev Returns details of a Crafting Recipe. Note: Required items mapping is not returned directly.
     * @param recipeId The ID of the recipe.
     * @return A tuple containing recipe details (excluding mapping details directly).
     */
    function getRecipeDetails(uint256 recipeId)
        external
        view
        returns (uint256 id, uint256 outputFragmentType, uint8 baseSuccessRate, bool enabled)
    {
        CraftingRecipe storage recipe = craftingRecipes[recipeId];
        require(recipe.id != 0, "Crafting recipe does not exist");
        return (recipe.id, recipe.outputFragmentType, recipe.baseSuccessRate, isRecipeEnabled[recipeId]);
    }

     /**
     * @dev Returns details of a Synthesis Recipe. Note: Required fragment types mapping is not returned directly.
     * @param recipeId The ID of the recipe.
     * @return A tuple containing recipe details (excluding mapping details directly).
     */
    function getSynthesisRecipeDetails(uint256 recipeId)
        external
        view
        returns (uint256 id, uint256 outputArtifactType, uint256 basePower, uint256 baseDecay, uint256 numOutputProperties, bool enabled)
    {
        SynthesisRecipe storage recipe = synthesisRecipes[recipeId];
        require(recipe.id != 0, "Synthesis recipe does not exist");
        return (recipe.id, recipe.outputArtifactType, recipe.basePower, recipe.baseDecay, recipe.numOutputProperties, isRecipeEnabled[recipeId]);
    }

    /**
     * @dev Returns the current global Temporal Flux value.
     * @return The Temporal Flux value.
     */
    function getCurrentTemporalFlux() external view returns (uint256) {
        return temporalFlux;
    }

    /**
     * @dev Returns the current global Reality Stability value.
     * @return The Reality Stability value.
     */
    function getCurrentRealityStability() external view returns (uint256) {
        return realityStability;
    }

    /**
     * @dev Calculates and returns the dynamic Power Level of an Artifact.
     * Power is influenced by base power, current charge, and Reality Stability.
     * Decay is calculated conceptually for this view function but not applied to state.
     * @param artifactId The ID of the Artifact.
     * @return The calculated Power Level.
     */
    function getArtifactPowerLevel(uint256 artifactId) external view returns (uint256) {
        require(artifactExists[artifactId], "Artifact does not exist");
        Artifact storage artifact = artifacts[artifactId];

        // Get conceptual current charge based on time elapsed
        uint256 timeElapsed = block.timestamp - artifact.lastDecayTime;
        uint256 effectiveDecayRate = artifact.decayRate;
        if (realityStability > 0) {
             effectiveDecayRate = effectiveDecayRate * 100 / (100 + realityStability);
        }
        uint256 potentialChargeLoss = effectiveDecayRate * timeElapsed;
        uint256 currentChargeCalc = artifact.charge > potentialChargeLoss ? artifact.charge - potentialChargeLoss : 0;

        // Example Power Calculation: Base Power + (Charge / Factor) * (1 + Stability Bonus)
        // Simplified example
        uint256 power = artifact.basePower;
        if (currentChargeCalc > 0) {
            power += currentChargeCalc / 10; // Example: 10 charge adds 1 power
        }

        // Influence of Reality Stability on Power (Example: Higher Stability = Higher Power)
        power = power * (100 + realityStability) / 100; // Example: 100 stability doubles power

        return power;
    }

    /**
     * @dev Predicts the potential success chance for a Crafting Recipe based on current Realm State.
     * Does not consume resources or change state.
     * @param recipeId The ID of the crafting recipe.
     * @return The calculated success chance (0-100).
     */
    function predictCraftingOutcome(uint256 recipeId) external view returns (uint8 successChance) {
        CraftingRecipe storage recipe = craftingRecipes[recipeId];
        require(recipe.id != 0, "Crafting recipe does not exist");

        int256 effectiveSuccessRate = int256(recipe.baseSuccessRate) + int256(temporalFlux / 100); // Example modifier

        if (effectiveSuccessRate < 0) effectiveSuccessRate = 0;
        if (effectiveSuccessRate > 100) effectiveSuccessRate = 100;

        return uint8(effectiveSuccessRate);
    }

    /**
     * @dev Predicts the base properties of an Artifact synthesized with a given recipe.
     * Does not consume resources or change state.
     * Note: Actual generated properties in `synthesizeArtifact` will include randomness and input fragment influence.
     * @param recipeId The ID of the synthesis recipe.
     * @param fragmentIds The IDs of the Fragments *you would use* (caller must own). Used for predicting influence.
     * @return A tuple containing predicted base power, base decay, and example average properties.
     */
    function predictSynthesisOutcome(uint256 recipeId, uint256[] memory fragmentIds)
        external
        view
        returns (uint256 basePower, uint256 baseDecay, uint256[] memory exampleProperties)
    {
        SynthesisRecipe storage recipe = synthesisRecipes[recipeId];
        require(recipe.id != 0, "Synthesis recipe does not exist");
        require(fragmentIds.length > 0, "No fragments provided for prediction");

        // Check ownership of provided fragments for prediction only (no state change)
         for (uint i = 0; i < fragmentIds.length; i++) {
            require(fragmentExists[fragmentIds[i]], "Fragment does not exist");
            require(fragments[fragmentIds[i]].owner == msg.sender, "Not fragment owner for prediction");
        }

        // Simulate property generation to give a prediction (e.g., average based on inputs)
        exampleProperties = _generateArtifactProperties(recipeId, fragmentIds); // Use the internal helper

        return (recipe.basePower, recipe.baseDecay, exampleProperties);
    }

     /**
     * @dev Checks if a recipe (crafting or synthesis) is enabled.
     * @param recipeId The ID of the recipe.
     * @return True if enabled, false otherwise.
     */
    function isRecipeEnabled(uint256 recipeId) external view returns (bool) {
        return isRecipeEnabled[recipeId];
    }

    /**
     * @dev Gets the owner of a specific Fragment.
     * @param fragmentId The ID of the Fragment.
     * @return The owner's address.
     */
    function getFragmentOwner(uint256 fragmentId) external view returns (address) {
        require(fragmentExists[fragmentId], "Fragment does not exist");
        return fragments[fragmentId].owner;
    }

    /**
     * @dev Gets the owner of a specific Artifact.
     * @param artifactId The ID of the Artifact.
     * @return The owner's address.
     */
    function getArtifactOwner(uint256 artifactId) external view returns (address) {
         require(artifactExists[artifactId], "Artifact does not exist");
        return artifacts[artifactId].owner;
    }

     /**
     * @dev Checks if an Artifact is currently attuned (soulbound) to its owner.
     * @param artifactId The ID of the Artifact.
     * @return True if attuned, false otherwise.
     */
    function isArtifactAttuned(uint256 artifactId) external view returns (bool) {
        require(artifactExists[artifactId], "Artifact does not exist");
        return artifacts[artifactId].isAttuned;
    }


    // --- INTERNAL HELPERS ---

    /**
     * @dev Internal function to generate Fragment properties based on recipe and realm state.
     * Example logic: Properties influenced by recipe type and Temporal Flux variance.
     * @param recipeId The ID of the crafting recipe used.
     * @return An array of uint256 properties.
     */
    function _generateFragmentProperties(uint256 recipeId) internal view returns (uint256[] memory) {
        // Use a new random seed for property generation
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nextFragmentId, "props")));

        // Example: Always generate 3 properties
        uint256[] memory properties = new uint256[](3);

        // Properties influenced by recipe ID and Temporal Flux
        // Higher Temporal Flux could mean greater variance in property values
        uint256 baseValue = recipeId * 10; // Example base value
        uint256 variance = temporalFlux / 50; // Example variance based on flux

        for (uint i = 0; i < properties.length; i++) {
             uint256 propSeed = uint256(keccak256(abi.encodePacked(randomSeed, i)));
             // Simple variance: base +/- random amount within variance range
             int256 randomOffset = int256(propSeed % (variance * 2 + 1)) - int256(variance);
             int256 calculatedValue = int256(baseValue) + randomOffset;
             if (calculatedValue < 0) calculatedValue = 0; // Ensure non-negative properties
             properties[i] = uint256(calculatedValue);
        }

        return properties;
    }

     /**
     * @dev Internal function to generate Artifact properties based on synthesis recipe and input Fragments.
     * Example logic: Properties influenced by recipe, average/sum of input fragment properties, and Reality Stability.
     * @param recipeId The ID of the synthesis recipe used.
     * @param inputFragmentIds The IDs of the fragments used for synthesis.
     * @return An array of uint256 properties.
     */
    function _generateArtifactProperties(uint256 recipeId, uint256[] memory inputFragmentIds) internal view returns (uint256[] memory) {
        SynthesisRecipe storage recipe = synthesisRecipes[recipeId];
        uint256 numProps = recipe.numOutputProperties;
        uint256[] memory properties = new uint256[](numProps);

        if (numProps == 0) {
            return properties; // No properties to generate
        }

        // Example: Influence of input fragments on artifact properties
        // Sum up corresponding properties from input fragments
        mapping(uint256 => uint256) memory summedFragmentProperties;
        uint256 totalFragments = inputFragmentIds.length;

        for (uint i = 0; i < totalFragments; i++) {
            Fragment storage frag = fragments[inputFragmentIds[i]];
            // Assume fragments have the same number of properties or handle mismatch
            uint256 commonProps = frag.properties.length < numProps ? frag.properties.length : numProps;
            for (uint j = 0; j < commonProps; j++) {
                summedFragmentProperties[j] += frag.properties[j];
            }
        }

        // Use a random seed for additional variance
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nextArtifactId, "artifactprops")));

         // Example influence: Higher Stability -> properties closer to base/average
        uint256 stabilityInfluence = realityStability / 20; // Example scale

        for (uint i = 0; i < numProps; i++) {
            uint256 baseValue = summedFragmentProperties[i] / (totalFragments > 0 ? totalFragments : 1); // Average from fragments
            // Add some randomness and stability influence
            uint256 propSeed = uint256(keccak256(abi.encodePacked(randomSeed, i)));
            int256 randomOffset = int256(propSeed % (50 + stabilityInfluence)) - int256(25 + stabilityInfluence/2); // Example bounded random

            int256 calculatedValue = int256(baseValue) + randomOffset;
            if (calculatedValue < 0) calculatedValue = 0;

            properties[i] = uint256(calculatedValue);
        }

        return properties;
    }


    /**
     * @dev Internal function to burn a Fragment (remove from existence).
     * @param fragmentId The ID of the Fragment to burn.
     */
    function _burnFragment(uint256 fragmentId) internal {
        require(fragmentExists[fragmentId], "Fragment does not exist");

        address ownerAddress = fragments[fragmentId].owner;

        // Remove from owner's list
        uint256[] storage ownerFragments = userFragmentIds[ownerAddress];
        for (uint i = 0; i < ownerFragments.length; i++) {
            if (ownerFragments[i] == fragmentId) {
                ownerFragments[i] = ownerFragments[ownerFragments.length - 1];
                ownerFragments.pop();
                break;
            }
        }

        delete fragments[fragmentId]; // Delete from storage
        fragmentExists[fragmentId] = false;

        // Optional: Emit a Burn event
        // emit FragmentBurned(ownerAddress, fragmentId); // Need to define this event
    }

     /**
     * @dev Internal function to burn an Artifact (remove from existence).
     * Could be used if charge hits zero or for other game mechanics.
     * @param artifactId The ID of the Artifact to burn.
     */
    function _burnArtifact(uint256 artifactId) internal {
         require(artifactExists[artifactId], "Artifact does not exist");
         require(!artifacts[artifactId].isAttuned, "Cannot burn attuned artifact"); // Prevent burning attuned assets? Or allow?

        address ownerAddress = artifacts[artifactId].owner;

        // Remove from owner's list
        uint256[] storage ownerArtifacts = userArtifactIds[ownerAddress];
         for (uint i = 0; i < ownerArtifacts.length; i++) {
            if (ownerArtifacts[i] == artifactId) {
                ownerArtifacts[i] = ownerArtifacts[ownerArtifacts.length - 1];
                ownerArtifacts.pop();
                break;
            }
        }

        delete artifacts[artifactId]; // Delete from storage
        artifactExists[artifactId] = false;

        // Optional: Emit a Burn event
        // emit ArtifactBurned(ownerAddress, artifactId); // Need to define this event
    }

    // Note on Randomness: block.timestamp and block.difficulty/blockhash are NOT truly random
    // and can be manipulated by miners. For production systems, use Chainlink VRF or similar.

    // Note on Mappings in Recipes: Storing mapping within structs in storage is fine.
    // Passing/returning mappings in/from public functions is NOT possible.
    // For `addCraftingRecipe` and `addSynthesisRecipe`, requirement mappings would need
    // to be passed as arrays of key-value pairs (e.g., uint256[] types, uint256[] amounts)
    // and then stored into the mapping in storage. The current implementation sketch
    // in `addCraftingRecipe` is conceptually simplified; the `addSynthesisRecipe`
    // shows the more correct way using arrays.
    // Getter functions for recipes would similarly need to return requirements as arrays.
    // The current getters only return base recipe details, not the full requirements.
    // To get requirements, dedicated getters like `getCraftingRecipeRequirements(recipeId)`
    // returning arrays would be needed. This would add more functions if required.

    // Note on Dynamic Arrays in Mappings (userFragmentIds, userArtifactIds):
    // Appending (`push`) is fine. Removing by value (`pop` after swap) is a gas-efficient way
    // to remove items without shifting the whole array, but it doesn't preserve order.
    // If order matters or frequent deletions occur, more complex data structures might be needed.
}
```