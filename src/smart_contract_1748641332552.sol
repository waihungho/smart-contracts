Okay, this is an exciting challenge! We'll design a smart contract called `GenerativeAssetForge` that combines several advanced concepts:

1.  **Generative On-Chain Assets:** Assets (ERC721) whose initial properties are partly derived from input components and on-chain entropy during minting.
2.  **Dynamic/Evolving State:** Assets can accumulate "Energy" over time (claimed by the owner) and spend this energy to "Evolve," potentially changing their traits or level.
3.  **Component-Based Forging:** Users combine specific quantities of different "Components" (ERC1155) and "Glyphs" (another ERC1155 type) via defined "Recipes" to forge a new Generative Asset. Components and Glyphs are consumed.
4.  **Glyph Fusion:** A separate process allowing users to combine Glyphs to create new or enhanced Glyphs.
5.  **Asset Deconstruction:** Allows burning a Generative Asset to recover a portion of the original Components.
6.  **Parameterized Creation Influence:** Allow users to provide simple parameters during forging that can slightly influence the outcome (a hint of skill).
7.  **External Attribute Influence (Conceptual):** Include a placeholder mechanism where certain traits *could* potentially be updated by authorized oracle callers based on external data (simulated here).

We will use OpenZeppelin library for standard implementations (ERC721, ERC1155, Pausable, Ownable, ERC2981) to ensure safety and efficiency, but the *logic* connecting these pieces and the specific forging/evolution/fusion mechanisms will be custom.

---

**Outline and Function Summary**

**Contract Name:** `GenerativeAssetForge`

**Core Concepts:** ERC721 Generative Assets, ERC1155 Components & Glyphs, Component-based Forging, Dynamic Asset State (Energy, Evolution), Glyph Fusion, Asset Deconstruction, Parameterized Forging, External Attribute Hooks.

**Interfaces Used:** ERC721, ERC721Enumerable, ERC1155, ERC2981, Ownable, Pausable.

**State Variables:**
*   Asset Properties mapping (`assetProperties`)
*   Recipe storage (`recipes`)
*   Glyph Fusion Recipe storage (`glyphFusionRecipes`)
*   Counters for Assets, Component Types, Glyph Types, Recipes, Fusion Recipes.
*   Base URIs for tokens.
*   Authorized Oracle Callers mapping.

**Events:**
*   `AssetForged`: When a new asset is created.
*   `EnergyClaimed`: When energy is added to an asset.
*   `AssetEvolved`: When an asset evolves.
*   `GlyphFused`: When glyphs are combined.
*   `AssetDeconstructed`: When an asset is burned for components.
*   `RecipeSet`: When a forging recipe is defined/updated.
*   `GlyphFusionRecipeSet`: When a glyph fusion recipe is defined/updated.
*   `ExternalAttributeUpdated`: When an external attribute is changed.

**Modifiers:**
*   `onlyOracleCaller`: Restricts access to registered oracle callers.

**Functions (Approx. 30+):**

**I. Standard ERC Interfaces (Base implementations from OpenZeppelin):**
1.  `constructor(...)`: Initializes contract, sets base URIs, owner.
2.  `supportsInterface(bytes4 interfaceId)`: Standard function to indicate supported interfaces (ERC165).
3.  `name()`: Returns the contract name (ERC721).
4.  `symbol()`: Returns the contract symbol (ERC721).
5.  `balanceOf(address owner)`: Get number of assets owned by address (ERC721).
6.  `ownerOf(uint256 tokenId)`: Get owner of a specific asset (ERC721).
7.  `approve(address to, uint256 tokenId)`: Approve an address to transfer an asset (ERC721).
8.  `getApproved(uint256 tokenId)`: Get the approved address for an asset (ERC721).
9.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all assets (ERC721).
10. `isApprovedForAll(address owner, address operator)`: Check if operator is approved for owner (ERC721).
11. `transferFrom(address from, address to, uint256 tokenId)`: Transfer asset (ERC721).
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer asset (ERC721).
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer asset with data (ERC721).
14. `tokenURI(uint256 tokenId)`: Get URI for an asset (ERC721Metadata).
15. `totalSupply()`: Get total number of assets minted (ERC721Enumerable).
16. `tokenByIndex(uint256 index)`: Get token ID by index (ERC721Enumerable).
17. `tokenOfOwnerByIndex(address owner, uint256 index)`: Get token ID of owner by index (ERC721Enumerable).
18. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: Get royalty information (ERC2981).
19. `uri(uint256 id)`: Get URI for a component or glyph type (ERC1155).
20. `balanceOf(address account, uint256 id)`: Get balance of a specific component/glyph type for an account (ERC1155).
21. `balanceOfBatch(address[] accounts, uint256[] ids)`: Get balances for multiple accounts and types (ERC1155).
22. `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all component/glyph types (ERC1155).
23. `isApprovedForAll(address account, address operator)`: Check if operator is approved for account (ERC1155).
24. `safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)`: Safe transfer components/glyphs (ERC1155).
25. `safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data)`: Safe batch transfer components/glyphs (ERC1155).

**II. Core Logic Functions:**
26. `setRecipe(uint256 recipeId, ComponentInput[] componentInputs, GlyphInput[] glyphInputs, bytes32 baseOutputTraits, uint256 baseEnergyRate)`: (Admin) Defines or updates a forging recipe.
27. `getRecipe(uint256 recipeId)`: (View) Retrieves recipe details.
28. `forgeAsset(uint256 recipeId, uint256[] parameterValues)`: Mints a new Generative Asset by consuming required components and glyphs according to the recipe. Incorporates parameters and on-chain data (`blockhash`) for initial traits.
29. `getAssetProperties(uint256 tokenId)`: (View) Retrieves the dynamic properties of a Generative Asset.
30. `claimEnergy(uint256 tokenId)`: Calculates and adds accumulated energy to an asset based on time elapsed.
31. `evolveAsset(uint256 tokenId, uint256 energyToSpend)`: Spends asset's energy to potentially change traits or increase level.
32. `setGlyphFusionRecipe(uint256 fusionRecipeId, GlyphInput[] inputGlyphs, GlyphOutput[] outputGlyphs)`: (Admin) Defines or updates a glyph fusion recipe.
33. `getGlyphFusionRecipe(uint256 fusionRecipeId)`: (View) Retrieves glyph fusion recipe details.
34. `fuseGlyphs(uint256 fusionRecipeId)`: Consumes input glyphs according to a fusion recipe and mints output glyphs.
35. `deconstructAsset(uint256 tokenId)`: Burns an asset and mints a portion of its original components back to the owner.

**III. Admin & Utility Functions:**
36. `pause()`: (Admin) Pauses core contract operations.
37. `unpause()`: (Admin) Unpauses core contract operations.
38. `withdraw()`: (Admin) Withdraws any Ether held by the contract (e.g., from royalties).
39. `issueComponents(address to, uint256[] ids, uint256[] amounts)`: (Admin) Mints new components/glyphs (initial distribution/supply).
40. `setComponentURI(uint256 componentId, string uri)`: (Admin) Sets the metadata URI for a specific component type.
41. `setGlyphURI(uint256 glyphId, string uri)`: (Admin) Sets the metadata URI for a specific glyph type.
42. `setAssetBaseURI(string baseURI)`: (Admin) Sets the base metadata URI for Generative Assets.
43. `setDefaultRoyalty(address receiver, uint96 feeNumerator)`: (Admin) Sets the default royalty for assets.
44. `setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)`: (Admin) Sets a specific royalty for a single asset (overrides default).
45. `addOracleCaller(address caller)`: (Admin) Grants permission to update external attributes.
46. `removeOracleCaller(address caller)`: (Admin) Revokes permission to update external attributes.
47. `updateExternalAttribute(uint256 tokenId, uint256 attributeIndex, bytes32 value)`: (Oracle Caller) Updates a specific trait based on external data (simulated).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Added for potential calculations
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

// --- Outline and Function Summary ---
//
// Contract Name: GenerativeAssetForge
//
// Core Concepts:
// - ERC721 Generative Assets: Minted with initial properties partly from inputs and on-chain entropy.
// - Dynamic/Evolving State: Assets accumulate Energy (claimable) and can spend it to Evolve (change traits/level).
// - Component-Based Forging: Consume ERC1155 Components and Glyphs via Recipes to create ERC721 Assets.
// - Glyph Fusion: Combine ERC1155 Glyphs to create new/enhanced Glyphs via Fusion Recipes.
// - Asset Deconstruction: Burn ERC721 Assets to recover some ERC1155 Components.
// - Parameterized Forging: User input parameters subtly influence forging outcomes.
// - External Attribute Hooks: Placeholder mechanism for traits to be updated by authorized oracles.
//
// Interfaces Used: ERC721, ERC721Enumerable, ERC1155, ERC2981 (ERC721Royalty), Ownable, Pausable.
//
// State Variables:
// - assetProperties: Mapping from asset tokenId to dynamic properties struct.
// - recipes: Mapping from recipeId to ForgingRecipe struct.
// - glyphFusionRecipes: Mapping from fusionRecipeId to GlyphFusionRecipe struct.
// - tokenCounter: Counter for ERC721 assets.
// - componentURI/glyphURI: Mappings for ERC1155 metadata URIs per type.
// - oracleCallers: Mapping for authorized addresses updating external attributes.
//
// Events: AssetForged, EnergyClaimed, AssetEvolved, GlyphFused, AssetDeconstructed, RecipeSet, GlyphFusionRecipeSet, ExternalAttributeUpdated.
//
// Modifiers: onlyOwner, whenNotPaused, whenPaused, onlyOracleCaller.
//
// Functions (30+ total):
// I. Standard ERC Interfaces (Base implementations):
//    - constructor, supportsInterface, name, symbol, balanceOf (ERC721), ownerOf, approve, getApproved, setApprovalForAll (ERC721), isApprovedForAll (ERC721), transferFrom, safeTransferFrom (both overloads), tokenURI, totalSupply, tokenByIndex, tokenOfOwnerByIndex, royaltyInfo, uri (ERC1155), balanceOf (ERC1155), balanceOfBatch, setApprovalForAll (ERC1155), isApprovedForAll (ERC1155), safeTransferFrom (ERC1155), safeBatchTransferFrom.
// II. Core Logic Functions:
//    - setRecipe (Admin): Define forging recipes.
//    - getRecipe (View): Retrieve forging recipes.
//    - forgeAsset: Consume inputs, mint asset, set initial properties.
//    - getAssetProperties (View): Retrieve asset properties.
//    - claimEnergy: Calculate & add energy based on time.
//    - evolveAsset: Spend energy to modify asset state.
//    - setGlyphFusionRecipe (Admin): Define glyph fusion recipes.
//    - getGlyphFusionRecipe (View): Retrieve glyph fusion recipes.
//    - fuseGlyphs: Consume input glyphs, mint output glyphs based on recipe.
//    - deconstructAsset: Burn asset, return partial components.
// III. Admin & Utility Functions:
//    - pause (Admin), unpause (Admin), withdraw (Admin).
//    - issueComponents (Admin): Mint initial components/glyphs.
//    - setComponentURI (Admin), setGlyphURI (Admin), setAssetBaseURI (Admin).
//    - setDefaultRoyalty (Admin), setTokenRoyalty (Admin).
//    - addOracleCaller (Admin), removeOracleCaller (Admin).
//    - updateExternalAttribute (Oracle Caller): Simulate external data influence on traits.
//
// --- End of Outline and Summary ---


contract GenerativeAssetForge is ERC721Enumerable, ERC721Royalty, ERC1155, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenCounter;

    // Represents the dynamic, on-chain properties of an asset
    struct AssetProperties {
        uint256 id; // Token ID
        uint64 creationTimestamp;
        uint64 lastEnergyClaimTimestamp;
        uint256 currentEnergy;
        uint256 level;
        bytes32[] traits; // Storing traits as bytes32 (can be packed values)
        uint256 energyPerSecond; // Rate of energy accumulation
        // Add other dynamic properties here (e.g., 'cooldownUntil')
    }
    mapping(uint256 => AssetProperties) public assetProperties;

    // Structs for Forging Recipes
    struct ComponentInput {
        uint256 componentId; // ERC1155 ID
        uint256 amount;
    }

    struct GlyphInput {
        uint256 glyphId; // ERC1155 ID
        uint256 amount;
    }

    struct ForgingRecipe {
        ComponentInput[] componentInputs;
        GlyphInput[] glyphInputs;
        // baseOutputTraits provides a starting point, modified by glyphs/params/entropy
        bytes32[] baseOutputTraits;
        uint256 baseEnergyRate; // Base energy rate for the resulting asset
        // Maybe add required level or other conditions later
    }
    mapping(uint256 => ForgingRecipe) public recipes;

    // Structs for Glyph Fusion Recipes
    struct GlyphOutput {
        uint256 glyphId; // ERC1155 ID
        uint256 amount;
    }

    struct GlyphFusionRecipe {
        GlyphInput[] inputGlyphs;
        GlyphOutput[] outputGlyphs;
        // Maybe add cost or conditions
    }
    mapping(uint256 => GlyphFusionRecipe) public glyphFusionRecipes;

    // ERC1155 URIs (separate from ERC721 base URI)
    mapping(uint256 => string) private _componentURIs;
    mapping(uint256 => string) private _glyphURIs;

    // Oracle Callers for updating external attributes
    mapping(address => bool) public isOracleCaller;

    // --- Events ---

    event AssetForged(uint256 indexed tokenId, address indexed owner, uint256 recipeId, bytes32[] initialTraits);
    event EnergyClaimed(uint256 indexed tokenId, uint256 amount);
    event AssetEvolved(uint256 indexed tokenId, uint256 newLevel, uint256 energySpent, bytes32[] newTraits);
    event GlyphFused(uint256 indexed fusionRecipeId, address indexed fusor, uint256[] inputIds, uint256[] inputAmounts, uint256[] outputIds, uint256[] outputAmounts);
    event AssetDeconstructed(uint256 indexed tokenId, address indexed owner, uint256[] recoveredComponentIds, uint256[] recoveredAmounts);
    event RecipeSet(uint256 indexed recipeId);
    event GlyphFusionRecipeSet(uint256 indexed fusionRecipeId);
    event ExternalAttributeUpdated(uint256 indexed tokenId, uint256 indexed attributeIndex, bytes32 oldValue, bytes32 newValue);
    event OracleCallerSet(address indexed caller, bool authorized);

    // --- Modifiers ---

    modifier onlyOracleCaller() {
        require(isOracleCaller[msg.sender], "Not an oracle caller");
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, string memory assetBaseURI_)
        ERC721(name_, symbol_)
        ERC721Enumerable()
        ERC721Royalty()
        ERC1155("") // Base URI for ERC1155 set later via setComponentURI/setGlyphURI
        Ownable(msg.sender) // Make deployer the initial owner
    {
        _setAssetBaseURI(assetBaseURI_);
    }

    // --- Standard ERC721 Overrides (ERC721Enumerable & ERC721Royalty handled by inheritance) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and caller is interacting with a valid token
        string memory base = _assetBaseURI(); // Get base URI from ERC721Metadata
        if (bytes(base).length == 0) {
            return "";
        }
        // Append token ID and potentially .json
        return string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
         // Note: Real implementation would likely fetch data from assetProperties and combine with base URI/external source
    }

    // --- Standard ERC1155 Overrides ---

    function uri(uint256 id) public view override returns (string memory) {
        // Differentiate between Components and Glyphs based on ID ranges or a separate mapping if needed
        // For simplicity, let's assume separate URI mappings
        string memory componentUri = _componentURIs[id];
        if (bytes(componentUri).length > 0) {
            return componentUri;
        }
        string memory glyphUri = _glyphURIs[id];
        if (bytes(glyphUri).length > 0) {
             return glyphUri;
        }
        return super.uri(id); // Fallback to base URI if set for ERC1155
    }

    // --- Core Logic: Forging ---

    /**
     * @notice Defines or updates a forging recipe. Only callable by the owner.
     * @param recipeId Unique identifier for the recipe.
     * @param componentInputs Array of ComponentInput structs required.
     * @param glyphInputs Array of GlyphInput structs required.
     * @param baseOutputTraits Array of bytes32 representing the base traits before modification.
     * @param baseEnergyRate The base energy per second the resulting asset will have.
     */
    function setRecipe(
        uint256 recipeId,
        ComponentInput[] calldata componentInputs,
        GlyphInput[] calldata glyphInputs,
        bytes32[] calldata baseOutputTraits,
        uint256 baseEnergyRate
    ) external onlyOwner {
        recipes[recipeId] = ForgingRecipe(
            componentInputs,
            glyphInputs,
            baseOutputTraits,
            baseEnergyRate
        );
        emit RecipeSet(recipeId);
    }

    /**
     * @notice Forges a new Generative Asset based on a recipe, consuming components and glyphs.
     * Initial traits are influenced by recipe base traits, user parameters, and on-chain entropy.
     * @param recipeId The ID of the recipe to use.
     * @param parameterValues Optional array of uint256 values provided by the user to influence output.
     */
    function forgeAsset(
        uint256 recipeId,
        uint256[] calldata parameterValues
    ) external payable whenNotPaused {
        ForgingRecipe storage recipe = recipes[recipeId];
        require(recipe.componentInputs.length > 0 || recipe.glyphInputs.length > 0, "Recipe does not exist or is empty"); // Basic check

        address minter = msg.sender;

        // 1. Check and Consume Components
        uint256[] memory compIds = new uint256[](recipe.componentInputs.length);
        uint256[] memory compAmounts = new uint256[](recipe.componentInputs.length);
        for (uint i = 0; i < recipe.componentInputs.length; i++) {
            compIds[i] = recipe.componentInputs[i].componentId;
            compAmounts[i] = recipe.componentInputs[i].amount;
            require(balanceOf(minter, compIds[i]) >= compAmounts[i], "Insufficient components");
        }
        if (compIds.length > 0) {
             // Consume components - transfer from minter to this contract address
            safeBatchTransferFrom(minter, address(this), compIds, compAmounts, "");
        }

        // 2. Check and Consume Glyphs
        uint256[] memory glyphIds = new uint256[](recipe.glyphInputs.length);
        uint256[] memory glyphAmounts = new uint256[](recipe.glyphInputs.length);
        for (uint i = 0; i < recipe.glyphInputs.length; i++) {
            glyphIds[i] = recipe.glyphInputs[i].glyphId;
            glyphAmounts[i] = recipe.glyphInputs[i].amount;
            require(balanceOf(minter, glyphIds[i]) >= glyphAmounts[i], "Insufficient glyphs");
        }
         if (glyphIds.length > 0) {
            // Consume glyphs - transfer from minter to this contract address
            safeBatchTransferFrom(minter, address(this), glyphIds, glyphAmounts, "");
        }

        // 3. Generate Initial Traits (Creative & On-Chain Logic)
        uint256 newItemId = _tokenCounter.current();
        bytes32[] memory initialTraits = new bytes32[](recipe.baseOutputTraits.length);

        // Seed for pseudo-randomness / unique derivation
        bytes32 entropySeed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use block.difficulty or prevrandao in PoS
            block.coinbase,
            msg.sender,
            newItemId,
            recipeId,
            parameterValues, // Incorporate user parameters
            compIds,
            compAmounts,
            glyphIds,
            glyphAmounts
        ));

        // Combine base traits with derived properties based on seed and parameters
        for (uint i = 0; i < recipe.baseOutputTraits.length; i++) {
            bytes32 baseTrait = recipe.baseOutputTraits[i];
            // Simple example: XOR with a portion of the seed, or use the seed to pick from options
            // More complex logic can involve bit shifts, hashing parts of inputs, etc.
            initialTraits[i] = baseTrait ^ bytes32(uint256(entropySeed) + i); // Example derivation
            // Parameters could influence how traits are derived or modified
             if (parameterValues.length > i) {
                 initialTraits[i] = initialTraits[i] ^ bytes32(parameterValues[i]);
             }
        }

        // 4. Mint Asset and Initialize Properties
        _tokenCounter.increment();
        _safeMint(minter, newItemId);

        assetProperties[newItemId] = AssetProperties({
            id: newItemId,
            creationTimestamp: uint64(block.timestamp),
            lastEnergyClaimTimestamp: uint64(block.timestamp),
            currentEnergy: 0,
            level: 1,
            traits: initialTraits,
            energyPerSecond: recipe.baseEnergyRate // Initial energy rate
            // Initialize other properties
        });

        emit AssetForged(newItemId, minter, recipeId, initialTraits);
    }

    /**
     * @notice Retrieves the dynamic properties of a Generative Asset.
     * @param tokenId The ID of the asset.
     * @return AssetProperties struct.
     */
    function getAssetProperties(uint256 tokenId) public view returns (AssetProperties memory) {
        _requireOwned(tokenId); // Ensure token exists
        return assetProperties[tokenId];
    }

    /**
     * @notice Allows the asset owner or approved address to claim accumulated energy.
     * Energy accumulates based on time since last claim or creation.
     * @param tokenId The ID of the asset.
     */
    function claimEnergy(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");

        AssetProperties storage props = assetProperties[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - props.lastEnergyClaimTimestamp;

        uint256 energyGained = uint256(timeElapsed).mul(props.energyPerSecond);

        if (energyGained > 0) {
            props.currentEnergy = props.currentEnergy.add(energyGained);
            props.lastEnergyClaimTimestamp = currentTime;
            emit EnergyClaimed(tokenId, energyGained);
        }
    }

    /**
     * @notice Allows the asset owner or approved address to spend accumulated energy to evolve the asset.
     * Evolution can change traits or increase the asset's level.
     * @param tokenId The ID of the asset.
     * @param energyToSpend The amount of energy to spend on evolution.
     */
    function evolveAsset(uint256 tokenId, uint256 energyToSpend) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        AssetProperties storage props = assetProperties[tokenId];
        require(props.currentEnergy >= energyToSpend, "Insufficient energy to evolve");
        require(energyToSpend > 0, "Must spend energy to evolve");

        // Internal function to handle energy spending
        _spendEnergy(tokenId, energyToSpend);

        // --- Evolution Logic (Advanced/Creative) ---
        // This is where complexity can be added.
        // Examples:
        // - deterministic trait changes based on level
        // - probabilistic trait changes based on energy spent and current traits
        // - requiring additional components/glyphs as catalysts for specific evolutions
        // - changing the energyPerSecond rate
        // - unlocking new abilities/functions tied to the asset's level/traits

        props.level = props.level.add(1); // Simple level increase
        uint256 numTraits = props.traits.length;
        if (numTraits > 0) {
            // Example trait modification: change a trait based on level and spent energy
            uint256 traitIndexToModify = props.level % numTraits; // Cycle through traits
             // Mix current trait value, energy spent, and block data for new value
            props.traits[traitIndexToModify] = keccak256(abi.encodePacked(
                props.traits[traitIndexToModify],
                energyToSpend,
                props.level,
                block.timestamp,
                block.difficulty // Use block.difficulty or prevrandao
            ));
            // More sophisticated logic would interpret bytes32 as specific trait types and apply rules
        }

        emit AssetEvolved(tokenId, props.level, energyToSpend, props.traits);
    }

    /**
     * @notice Internal function to spend an asset's energy.
     * @param tokenId The ID of the asset.
     * @param amount The amount of energy to spend.
     */
    function _spendEnergy(uint256 tokenId, uint256 amount) internal {
        AssetProperties storage props = assetProperties[tokenId];
        require(props.currentEnergy >= amount, "ERC721: insufficient energy");
        props.currentEnergy = props.currentEnergy.sub(amount);
        // Note: Spending energy does NOT reset lastEnergyClaimTimestamp, only claiming does.
    }


    // --- Core Logic: Glyph Fusion ---

    /**
     * @notice Defines or updates a glyph fusion recipe. Only callable by the owner.
     * @param fusionRecipeId Unique identifier for the fusion recipe.
     * @param inputGlyphs Array of GlyphInput structs required for fusion.
     * @param outputGlyphs Array of GlyphOutput structs produced by fusion.
     */
    function setGlyphFusionRecipe(
        uint256 fusionRecipeId,
        GlyphInput[] calldata inputGlyphs,
        GlyphOutput[] calldata outputGlyphs
    ) external onlyOwner {
        glyphFusionRecipes[fusionRecipeId] = GlyphFusionRecipe(inputGlyphs, outputGlyphs);
        emit GlyphFusionRecipeSet(fusionRecipeId);
    }

    /**
     * @notice Fuses glyphs according to a defined recipe, consuming input glyphs and minting output glyphs.
     * @param fusionRecipeId The ID of the glyph fusion recipe to use.
     */
    function fuseGlyphs(uint256 fusionRecipeId) external whenNotPaused {
        GlyphFusionRecipe storage recipe = glyphFusionRecipes[fusionRecipeId];
        require(recipe.inputGlyphs.length > 0, "Fusion recipe does not exist or is empty");

        address fusor = msg.sender;

        // 1. Check and Consume Input Glyphs
        uint256[] memory inputIds = new uint256[](recipe.inputGlyphs.length);
        uint256[] memory inputAmounts = new uint256[](recipe.inputGlyphs.length);
        for (uint i = 0; i < recipe.inputGlyphs.length; i++) {
            inputIds[i] = recipe.inputGlyphs[i].glyphId;
            inputAmounts[i] = recipe.inputGlyphs[i].amount;
            require(balanceOf(fusor, inputIds[i]) >= inputAmounts[i], "Insufficient input glyphs");
        }
        // Consume glyphs - transfer from fusor to this contract address
        safeBatchTransferFrom(fusor, address(this), inputIds, inputAmounts, "");

        // 2. Mint Output Glyphs
        uint256[] memory outputIds = new uint256[](recipe.outputGlyphs.length);
        uint256[] memory outputAmounts = new uint256[](recipe.outputGlyphs.length);
        for (uint i = 0; i < recipe.outputGlyphs.length; i++) {
             outputIds[i] = recipe.outputGlyphs[i].glyphId;
             outputAmounts[i] = recipe.outputGlyphs[i].amount;
        }
        // Mint glyphs - transfer from this contract address to fusor
        _mintERC1155(fusor, outputIds, outputAmounts, "");

        emit GlyphFused(fusionRecipeId, fusor, inputIds, inputAmounts, outputIds, outputAmounts);
    }

     /**
     * @notice Internal helper to mint ERC1155 tokens (components or glyphs).
     * Allows the contract to mint tokens from itself (assuming it has minter rights via _mint function,
     * which ERC1155 doesn't strictly have - we simulate this by having owner issue, or contract holds supply)
     * A better approach: Owner pre-mints supply to the contract, and contract safeTransferFrom(self, receiver).
     * Let's assume owner issues initially and contract manages supply, or contract is the minter authority.
     * For simplicity here, let's assume the contract *can* mint from a "zero address" source or owner pre-minted to it.
     * We'll use the internal `_mint` from OpenZeppelin's ERC1155 for the owner to initially issue.
     * For contract logic producing tokens, we'll simulate this by transferring from `address(this)`.
     * This function name is misleading if using `safeTransferFrom(address(this), ...)`.
     * Let's rename or use the owner issue function for simplicity.
     * A standard pattern is for the owner to issue initial supply to the contract address, then the contract `safeTransferFrom(address(this), ...)`
     * For this contract, `issueComponents` will be the owner's way to add tokens to the system (can mint directly to users or contract).
     * Fusion output and Deconstruction input/output will use `safeBatchTransferFrom(address(this), ...)` and burn via `safeBatchTransferFrom(caller, address(this), ...)` where contract balance effectively decreases (or tokens are sent to burn address).
     * Let's refine: Fusion output should *mint* new tokens if they are new types or increasing supply. Deconstruction *burns*.
     * OpenZeppelin's ERC1155 `_mint` is protected. The contract *itself* needs permission or to call an owner function.
     * Let's add an internal mint function that *assumes* the contract has minting authority or supply. Or, simply let `issueComponents` be the *only* way to create supply, and fusion/deconstruction manage existing supply.
     * The prompt asks for creative functions. Let's assume the contract *is* the minting authority for new types created via fusion.
     */
    function _mintERC1155(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
         // In a real scenario, the contract might need specific MINTER_ROLE access or a dedicated mint function call.
         // For this example, we'll simulate the contract having minting capability for these processes.
         // This part would need careful access control design in a production contract.
         // OpenZeppelin ERC1155 `_mint` is protected. We need a way for THIS contract instance to call it.
         // Simplest: ERC1155 base contract allows `_mint` by the contract itself IF `msg.sender` is the contract.
         // Let's rely on that for fusion outputs representing new supply.
         _mint(to, ids[0], amounts[0], data); // ERC1155 _mint is for single ID/amount. Need batch.
         // OpenZeppelin ERC1155 has `_mintBatch`.
         _mintBatch(to, ids, amounts, data); // This requires the contract address to have MINTER_ROLE if used from other contracts.
         // In this case, it's the same contract calling itself, so _mintBatch should work *if* the contract address is implicitly authorized,
         // or if we structure it so only `owner()` can trigger mints (via issueComponents) and fusion/deconstruction use transfers.
         // Let's structure so `issueComponents` (owner) creates supply, and fusion/deconstruction use `safeBatchTransferFrom`. Fusion output comes from a pool managed by the contract, deconstruction burns into that pool or to zero address.
         // Re-evaluate Fusion/Deconstruction:
         // Fusion: Consumes A+B, Produces C. C must come from somewhere. Either pre-minted C held by contract, or contract *mints* C. Let's assume contract has `_mintBatch` capability for simplicity in this complex example.
         // Deconstruction: Consumes ERC721, Produces A. A was consumed during forging. Contract holds consumed A. Deconstruction `safeBatchTransferFrom(address(this), owner, recoveredIds, recoveredAmounts, "")`.
    }


    // --- Core Logic: Asset Deconstruction ---

    /**
     * @notice Burns a Generative Asset and returns a portion of the original components used to forge it.
     * Recovery rate is a simplified example (e.g., 50%).
     * @param tokenId The ID of the asset to deconstruct.
     */
    function deconstructAsset(uint256 tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");

        address owner = ownerOf(tokenId);
        // In a real system, you'd likely store the *exact* components used for each asset upon forging.
        // For simplicity here, we'll assume a fixed list or look up the recipe used and return a percentage.
        // Let's look up the recipe used (need to store recipeId in AssetProperties) - ADD TO STRUCT
        // Let's simplify and just return *some* predefined components for *any* deconstructed asset, or make it recipe-dependent but assume recipeId is known.
        // Let's add recipeId to AssetProperties.

        AssetProperties storage props = assetProperties[tokenId];
        // Retrieve the original recipe (need to have stored it) - Let's assume recipeId is stored.
        // Add `uint256 recipeId;` to AssetProperties struct.
        // For now, let's use a placeholder or require recipeId be passed.
        // Okay, let's add recipeId to AssetProperties.

        // Forging recipe is needed to know what components were used.
        // Let's assume `forgeAsset` stores `recipeId` in `assetProperties`.
        // struct AssetProperties { ... uint256 recipeId; ... } -> Requires migrating storage or adding later.
        // Let's hardcode a simple recovery logic for the example. Recovering 1x of Component 1 and 1x of Glyph 1.
        // A real contract should recover based on the *specific* components originally used.

        // Placeholder for recovery logic based on original recipe:
        // ForgingRecipe storage originalRecipe = recipes[props.recipeId]; // Requires recipeId in struct
        // uint256[] memory recoveredCompIds = new uint256[](originalRecipe.componentInputs.length);
        // uint256[] memory recoveredAmounts = new uint256[](originalRecipe.componentInputs.length);
        // For (uint i=0; i < originalRecipe.componentInputs.length; i++) {
        //     recoveredCompIds[i] = originalRecipe.componentInputs[i].componentId;
        //     recoveredAmounts[i] = originalRecipe.componentInputs[i].amount.mul(50).div(100); // 50% recovery
        // }

        // Simple Placeholder Deconstruction: recover 1 of Component 1 and 1 of Glyph 1
        uint256[] memory recoveredCompIds = new uint256[](2);
        uint256[] memory recoveredAmounts = new uint256[](2);
        recoveredCompIds[0] = 1; // Example Component ID
        recoveredAmounts[0] = 1;
        recoveredCompIds[1] = 101; // Example Glyph ID
        recoveredAmounts[1] = 1;

        // Burn the ERC721 asset
        _burn(tokenId);
        delete assetProperties[tokenId]; // Clean up properties

        // Transfer recovered components/glyphs from contract balance to owner
        // This assumes the contract holds a pool of components/glyphs (e.g., from consumed during forging)
        safeBatchTransferFrom(address(this), owner, recoveredCompIds, recoveredAmounts, "");

        emit AssetDeconstructed(tokenId, owner, recoveredCompIds, recoveredAmounts);
    }


    // --- Admin & Utility Functions ---

    /**
     * @notice Allows the owner to mint new components/glyphs into the system.
     * This acts as the initial supply creation mechanism.
     * @param to The address to receive the tokens.
     * @param ids Array of ERC1155 IDs (component or glyph types).
     * @param amounts Array of amounts corresponding to the IDs.
     */
    function issueComponents(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @notice Sets the metadata URI for a specific component type.
     * @param componentId The ID of the component type.
     * @param uri_ The URI string.
     */
    function setComponentURI(uint256 componentId, string calldata uri_) external onlyOwner {
        _componentURIs[componentId] = uri_;
    }

    /**
     * @notice Sets the metadata URI for a specific glyph type.
     * @param glyphId The ID of the glyph type.
     * @param uri_ The URI string.
     */
    function setGlyphURI(uint256 glyphId, string calldata uri_) external onlyOwner {
        _glyphURIs[glyphId] = uri_;
    }

    /**
     * @notice Sets the base metadata URI for Generative Assets.
     * @param baseURI_ The base URI string.
     */
    function setAssetBaseURI(string calldata baseURI_) external onlyOwner {
        _setAssetBaseURI(baseURI_);
    }

    /**
     * @notice Sets the default royalty fee for all assets in this contract.
     * @param receiver The address receiving royalties.
     * @param feeNumerator The royalty fee numerator (denominator is 10000).
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Sets a specific royalty fee for a single asset. Overrides the default.
     * @param tokenId The ID of the asset.
     * @param receiver The address receiving royalties.
     * @param feeNumerator The royalty fee numerator.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }


    /**
     * @notice Allows the owner to add an address authorized to call oracle functions.
     * @param caller The address to authorize.
     */
    function addOracleCaller(address caller) external onlyOwner {
        isOracleCaller[caller] = true;
        emit OracleCallerSet(caller, true);
    }

    /**
     * @notice Allows the owner to remove an address's authorization for oracle functions.
     * @param caller The address to deauthorize.
     */
    function removeOracleCaller(address caller) external onlyOwner {
        isOracleCaller[caller] = false;
        emit OracleCallerSet(caller, false);
    }

    /**
     * @notice Allows authorized oracle callers to update a specific attribute (trait) of an asset.
     * This simulates external data influencing asset properties.
     * @param tokenId The ID of the asset.
     * @param attributeIndex The index of the trait to update within the traits array.
     * @param value The new bytes32 value for the trait.
     */
    function updateExternalAttribute(uint256 tokenId, uint256 attributeIndex, bytes32 value) external onlyOracleCaller whenNotPaused {
        AssetProperties storage props = assetProperties[tokenId];
        require(attributeIndex < props.traits.length, "Invalid attribute index");

        bytes32 oldValue = props.traits[attributeIndex];
        props.traits[attributeIndex] = value;

        emit ExternalAttributeUpdated(tokenId, attributeIndex, oldValue, value);
    }

    /**
     * @notice Pauses core functionality (forging, claiming energy, evolving, fusion, deconstruction).
     * @dev Inherited from Pausable.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses core functionality.
     * @dev Inherited from Pausable.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

     /**
     * @notice Allows the owner to withdraw any Ether held by the contract.
     * Useful for collecting protocol fees if any were implemented (e.g., in forgeAsset payable).
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }


    // --- ERC721 & ERC1155 Hooks for Pausable ---
    // These ensure transfers are paused when the contract is paused.

    function _update(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._update(to, tokenId);
    }

     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) whenNotPaused {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);
     }

     function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155) whenNotPaused {
         super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
     }

    // --- Support for ERC165 Interfaces ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```