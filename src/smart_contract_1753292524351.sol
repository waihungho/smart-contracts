Here's a Solidity smart contract for an advanced, creative, and trending NFT concept, named "ChronoGlyph Sentinels." It focuses on dynamic NFTs with on-chain component management, synthesis, epoch-based progression, and simplified governance hooks.

This contract aims to be unique by:
*   **On-chain Trait Logic:** Traits (components) are not just metadata; they are active, interchangeable elements stored directly on-chain within each NFT.
*   **Component Synthesis:** Users can burn existing components to create new, potentially rarer ones, creating an internal economy and dynamic rarity.
*   **Epoch-based Evolution:** The contract progresses through defined "epochs," which can unlock new features, modify rules, or enable different types of interactions, simulating a living protocol.
*   **Intrinsic Glyph Aura/Stance:** Glyphs have evolving `auraLevel` and `defensiveStance` that can be influenced by components and user actions, demonstrating a "living" NFT concept.

---

## ChronoGlyph Sentinels Contract Outline & Function Summary

**Contract Name:** `ChronoGlyphSentinels`

**Description:**
`ChronoGlyphSentinels` is an ERC721 compliant smart contract that manages a collection of dynamic, evolving NFTs called "ChronoGlyphs." Unlike static NFTs, each ChronoGlyph is comprised of multiple "Components" which are themselves on-chain entities. Holders can acquire, attach, swap, and synthesize these Components to customize and evolve their Glyphs. The contract features an "Epoch" system, where global rules and functionalities can change over time, and includes mechanisms for community interaction and governance.

**Key Concepts:**
*   **Dynamic NFTs:** Glyph traits (Components) are mutable and stored on-chain.
*   **On-Chain Component Management:** Direct manipulation of NFT attributes via contract functions.
*   **Component Synthesis:** A crafting system where users combine (burn) multiple components to create a new, distinct one.
*   **Epoch-based Progression:** The entire collection progresses through discrete "Epochs," each potentially introducing new rules, available components, or interactions.
*   **Intrinsic Glyph Evolution:** Glyphs can have evolving internal states like `auraLevel` and `defensiveStance` influenced by actions and components.
*   **Simplified Governance Hooks:** Basic functions for an owner/future DAO to manage critical contract parameters and introduce new component types/recipes.

---

### Function Summary:

**I. Core ERC721 & Base Management:**
1.  `constructor()`: Initializes the contract, sets the deployer as the initial owner, and defines the genesis epoch.
2.  `mintGenesisGlyph(address _to)`: Mints a limited number of initial ChronoGlyphs to a specified address. Callable only by the contract owner and limited to genesis supply.
3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer.
4.  `approve(address to, uint256 tokenId)`: Standard ERC721 approval.
5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 operator approval.
6.  `tokenURI(uint256 tokenId)`: Generates a dynamic metadata URI for a Glyph based on its current on-chain components.
7.  `getGlyphDetails(uint256 _glyphId)`: Retrieves all component IDs, aura level, and defensive stance for a given Glyph.

**II. Dynamic Trait & Component Evolution:**
8.  `defineComponentType(uint256 _componentTypeId, string memory _name, uint256 _maxSupply)`: Defines a new general category of component (e.g., "Weapon", "Helm"). Callable by owner.
9.  `mintComponent(uint256 _componentTypeId, string memory _componentMetadataURI, address _to)`: Mints a specific instance of a component type to an address. Callable by owner and limited by max supply per type.
10. `updateGlyphComponent(uint256 _glyphId, uint256 _slotIndex, uint256 _newComponentId)`: Replaces an existing component on a Glyph at a specific slot with a new one. Requires ownership of both Glyph and the new component. Burns the old component.
11. `synthesizeComponents(uint256[] calldata _sourceComponentIds, uint256 _outputComponentTypeId, uint256 _outputComponentId)`: Allows a user to burn multiple specified components they own to receive a single new, synthesized component, based on predefined recipes.
12. `deconstructComponent(uint256 _glyphId, uint256 _slotIndex)`: Removes a component from a Glyph, burning it permanently.
13. `evolveGlyphAura(uint256 _glyphId, uint256 _boosterComponentId)`: Enhances a Glyph's intrinsic `auraLevel` by burning a specific "booster" component.
14. `toggleGlyphDefensiveStance(uint256 _glyphId)`: Toggles a Glyph's `defensiveStance` between true/false, potentially altering its functional attributes in external systems.
15. `getComponentDetails(uint256 _componentId)`: Returns the type ID, owner, and metadata URI for a specific component.

**III. Epochs & Global State Management:**
16. `initiateEpochTransition()`: Callable by the owner to advance the contract to the next epoch. Each epoch can potentially unlock new features or modify global parameters.
17. `setEpochRule(uint256 _epoch, bytes32 _ruleKey, uint256 _value)`: Allows the owner to define or update a numerical rule for a specific epoch (e.g., `synthesisFee` for epoch X).
18. `getEpochRule(uint256 _epoch, bytes32 _ruleKey)`: Retrieves a specific rule value for a given epoch.
19. `activateGlyphProtocolFeature(bytes32 _featureKey)`: Owner-callable function to globally activate a specific protocol feature, potentially epoch-gated.

**IV. Community & Treasury (Simplified Governance Hooks):**
20. `depositToTreasury()`: Allows any user to send ETH to the contract's internal treasury.
21. `withdrawFromTreasury(address _to, uint256 _amount)`: Allows the owner to withdraw funds from the treasury for community initiatives or protocol upgrades.
22. `setComponentRecipe(uint256[] calldata _inputComponentIds, uint256 _outputComponentTypeId, uint256 _outputComponentId, uint256 _recipeCost)`: Owner can define new component synthesis recipes, specifying input components, output, and any associated cost.
23. `removeComponentRecipe(uint256[] calldata _inputComponentIds)`: Owner can remove an existing synthesis recipe.
24. `proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, uint256 _duration)`: Allows a user with sufficient Glyphs (or owner) to propose a change to a global parameter (e.g., `mintGenesisGlyphPrice`).
25. `voteOnParameterChange(bytes32 _parameterKey, bool _support)`: Allows Glyphs holders to vote on an active proposal. (Simplified: just tracks votes, requires off-chain counting or a more complex governance module).
26. `executeParameterChange(bytes32 _parameterKey)`: If a proposal passes (checked off-chain or by a future governance module), the owner can execute the change.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ChronoGlyphSentinels
 * @dev An advanced, dynamic NFT collection where each "ChronoGlyph" is composed of on-chain "Components"
 *      that can be swapped, synthesized, and evolved. The contract incorporates an epoch system
 *      for progressive feature unlocks and simplified governance hooks.
 *
 * Outline & Function Summary:
 *
 * Contract Name: ChronoGlyphSentinels
 *
 * Description:
 * `ChronoGlyphSentinels` is an ERC721 compliant smart contract that manages a collection of dynamic, evolving NFTs
 * called "ChronoGlyphs." Unlike static NFTs, each ChronoGlyph is comprised of multiple "Components" which are
 * themselves on-chain entities. Holders can acquire, attach, swap, and synthesize these Components to customize
 * and evolve their Glyphs. The contract features an "Epoch" system, where global rules and functionalities can
 * change over time, and includes mechanisms for community interaction and governance.
 *
 * Key Concepts:
 * - Dynamic NFTs: Glyph traits (Components) are mutable and stored on-chain.
 * - On-Chain Component Management: Direct manipulation of NFT attributes via contract functions.
 * - Component Synthesis: A crafting system where users combine (burn) multiple components to create a new, distinct one.
 * - Epoch-based Progression: The entire collection progresses through discrete "Epochs," each potentially
 *   introducing new rules, available components, or interactions.
 * - Intrinsic Glyph Evolution: Glyphs can have evolving internal states like `auraLevel` and `defensiveStance`
 *   influenced by actions and components.
 * - Simplified Governance Hooks: Basic functions for an owner/future DAO to manage critical contract parameters
 *   and introduce new component types/recipes.
 *
 * Function Summary:
 *
 * I. Core ERC721 & Base Management:
 * 1. constructor(): Initializes the contract, sets the deployer as the initial owner, and defines the genesis epoch.
 * 2. mintGenesisGlyph(address _to): Mints a limited number of initial ChronoGlyphs to a specified address. Callable only by the contract owner and limited to genesis supply.
 * 3. safeTransferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer.
 * 4. approve(address to, uint256 tokenId): Standard ERC721 approval.
 * 5. setApprovalForAll(address operator, bool approved): Standard ERC721 operator approval.
 * 6. tokenURI(uint256 tokenId): Generates a dynamic metadata URI for a Glyph based on its current on-chain components.
 * 7. getGlyphDetails(uint256 _glyphId): Retrieves all component IDs, aura level, and defensive stance for a given Glyph.
 *
 * II. Dynamic Trait & Component Evolution:
 * 8. defineComponentType(uint256 _componentTypeId, string memory _name, uint256 _maxSupply): Defines a new general category of component (e.g., "Weapon", "Helm"). Callable by owner.
 * 9. mintComponent(uint256 _componentTypeId, string memory _componentMetadataURI, address _to): Mints a specific instance of a component type to an address. Callable by owner and limited by max supply per type.
 * 10. updateGlyphComponent(uint256 _glyphId, uint256 _slotIndex, uint256 _newComponentId): Replaces an existing component on a Glyph at a specific slot with a new one. Requires ownership of both Glyph and the new component. Burns the old component.
 * 11. synthesizeComponents(uint256[] calldata _sourceComponentIds, uint256 _outputComponentTypeId, uint256 _outputComponentId): Allows a user to burn multiple specified components they own to receive a single new, synthesized component, based on predefined recipes.
 * 12. deconstructComponent(uint256 _glyphId, uint256 _slotIndex): Removes a component from a Glyph, burning it permanently.
 * 13. evolveGlyphAura(uint256 _glyphId, uint256 _boosterComponentId): Enhances a Glyph's intrinsic `auraLevel` by burning a specific "booster" component.
 * 14. toggleGlyphDefensiveStance(uint256 _glyphId): Toggles a Glyph's `defensiveStance` between true/false, potentially altering its functional attributes in external systems.
 * 15. getComponentDetails(uint256 _componentId): Returns the type ID, owner, and metadata URI for a specific component.
 *
 * III. Epochs & Global State Management:
 * 16. initiateEpochTransition(): Callable by the owner to advance the contract to the next epoch. Each epoch can potentially unlock new features or modify global parameters.
 * 17. setEpochRule(uint256 _epoch, bytes32 _ruleKey, uint256 _value): Allows the owner to define or update a numerical rule for a specific epoch (e.g., `synthesisFee` for epoch X).
 * 18. getEpochRule(uint256 _epoch, bytes32 _ruleKey): Retrieves a specific rule value for a given epoch.
 * 19. activateGlyphProtocolFeature(bytes32 _featureKey): Owner-callable function to globally activate a specific protocol feature, potentially epoch-gated.
 *
 * IV. Community & Treasury (Simplified Governance Hooks):
 * 20. depositToTreasury(): Allows any user to send ETH to the contract's internal treasury.
 * 21. withdrawFromTreasury(address _to, uint256 _amount): Allows the owner to withdraw funds from the treasury for community initiatives or protocol upgrades.
 * 22. setComponentRecipe(uint256[] calldata _inputComponentIds, uint256 _outputComponentTypeId, uint256 _outputComponentId, uint256 _recipeCost): Owner can define new component synthesis recipes, specifying input components, output, and any associated cost.
 * 23. removeComponentRecipe(uint256[] calldata _inputComponentIds): Owner can remove an existing synthesis recipe.
 * 24. proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, uint256 _duration): Allows a user with sufficient Glyphs (or owner) to propose a change to a global parameter (e.g., `mintGenesisGlyphPrice`).
 * 25. voteOnParameterChange(bytes32 _parameterKey, bool _support): Allows Glyphs holders to vote on an active proposal. (Simplified: just tracks votes, requires off-chain counting or a more complex governance module).
 * 26. executeParameterChange(bytes32 _parameterKey): If a proposal passes (checked off-chain or by a future governance module), the owner can execute the change.
 */
contract ChronoGlyphSentinels is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ChronoGlyph NFT counters
    Counters.Counter private _glyphTokenIds;
    // Component counters (global unique ID for each minted component instance)
    Counters.Counter private _componentTokenIds;

    // Maximum number of initial ChronoGlyphs to mint
    uint256 public constant MAX_GENESIS_GLYPHS = 1000;
    // Number of slots for components on each Glyph
    uint256 public constant GLYPH_COMPONENT_SLOTS = 4;

    // --- Structs ---

    // Represents a ChronoGlyph NFT
    struct Glyph {
        uint256[] componentIds; // Array of component instance IDs attached to this Glyph
        uint256 auraLevel;      // An intrinsic evolving stat for the Glyph
        bool defensiveStance;   // A boolean state for the Glyph (e.g., affects its behavior in external games)
        uint256 lastEvolutionEpoch; // The epoch when this Glyph last had a major evolution
    }

    // Represents a unique instance of a component
    struct Component {
        uint256 componentTypeId; // The ID of the general type of component (e.g., 1 for "Head", 2 for "Weapon")
        address owner;           // The current owner of this specific component instance (can be zero address if attached to a Glyph or burned)
        string metadataURI;      // URI for this component instance's metadata/image
    }

    // Represents a type of component (e.g., "Head", "Weapon", "Legs")
    struct ComponentType {
        string name;          // Name of the component type
        uint256 maxSupply;    // Max number of components of this type that can ever be minted
        uint256 mintedSupply; // Current number of components of this type minted
    }

    // Represents a synthesis recipe
    struct ComponentRecipe {
        uint256[] inputComponentIds; // Specific component instance IDs needed as input (simplified for now, could be component types later)
        uint256 outputComponentTypeId; // The type ID of the component produced
        uint256 outputComponentId;     // The specific instance ID of the component produced (must be pre-minted by owner for recipe)
        uint256 cost;                  // ETH cost for performing this synthesis
        bool isActive;                 // Whether this recipe is currently active
    }

    // For governance proposals (simplified)
    struct Proposal {
        bytes32 parameterKey;
        uint256 newValue;
        uint256 duration; // End time for voting
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
    }

    // --- Mappings ---

    // Glyph ID to Glyph struct
    mapping(uint256 => Glyph) public glyphs;
    // Component ID to Component struct
    mapping(uint256 => Component) public components;
    // Component Type ID to ComponentType struct
    mapping(uint256 => ComponentType) public componentTypes;

    // Store component ownership if not attached to a Glyph (i.e., in user's inventory)
    mapping(address => mapping(uint256 => bool)) public componentInventory;

    // Global contract parameters, potentially controlled by governance
    mapping(bytes32 => uint256) public globalParameters; // e.g., "MINT_GENESIS_PRICE", "SYNTHESIS_BASE_FEE"

    // Epoch-specific rules (epoch => ruleKey => value)
    mapping(uint256 => mapping(bytes32 => uint256)) public epochRules;
    // Globally activated features
    mapping(bytes32 => bool) public activatedFeatures;

    // Synthesis recipes (mapping array of input component IDs to a recipe)
    mapping(bytes32 => ComponentRecipe) public synthesisRecipes; // Hashed input component IDs -> recipe

    // Governance proposals
    mapping(bytes32 => Proposal) public proposals; // Hashed parameterKey -> Proposal

    // --- Events ---

    event GlyphMinted(uint256 indexed glyphId, address indexed owner);
    event ComponentMinted(uint256 indexed componentId, uint256 indexed componentTypeId, address indexed owner);
    event GlyphComponentUpdated(uint256 indexed glyphId, uint256 indexed slotIndex, uint256 indexed oldComponentId, uint256 newComponentId);
    event ComponentsSynthesized(address indexed synthesiser, uint256[] indexed inputComponentIds, uint256 indexed outputComponentId);
    event ComponentDeconstructed(uint256 indexed glyphId, uint256 indexed componentId);
    event GlyphAuraEvolved(uint256 indexed glyphId, uint256 newAuraLevel);
    event GlyphStanceToggled(uint256 indexed glyphId, bool newStance);
    event EpochTransitioned(uint256 indexed newEpoch);
    event EpochRuleSet(uint256 indexed epoch, bytes32 indexed ruleKey, uint256 value);
    event ProtocolFeatureActivated(bytes32 indexed featureKey);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ComponentRecipeSet(bytes32 indexed recipeHash);
    event ComponentRecipeRemoved(bytes32 indexed recipeHash);
    event ParameterChangeProposed(bytes32 indexed parameterKey, uint256 newValue, uint256 proposalId, uint256 duration);
    event VotedOnProposal(address indexed voter, bytes32 indexed parameterKey, bool support);
    event ProposalExecuted(bytes32 indexed parameterKey, uint256 newValue);

    // --- Constructor ---

    constructor() ERC721("ChronoGlyph Sentinels", "CGS") Ownable(msg.sender) {
        // Initialize global parameters
        globalParameters["MINT_GENESIS_PRICE"] = 0.01 ether; // Example price
        globalParameters["SYNTHESIS_BASE_FEE"] = 0.001 ether; // Example fee
        globalParameters["CURRENT_EPOCH"] = 0; // Starting epoch
    }

    // --- Modifiers ---

    modifier onlyGlyphOwner(uint256 _glyphId) {
        require(_exists(_glyphId), "Glyph does not exist");
        require(ownerOf(_glyphId) == msg.sender, "Caller is not Glyph owner");
        _;
    }

    modifier onlyComponentOwner(uint256 _componentId) {
        require(components[_componentId].owner == msg.sender, "Caller does not own component");
        _;
    }

    // --- I. Core ERC721 & Base Management ---

    /**
     * @dev Mints an initial ChronoGlyph NFT. Only callable by the contract owner.
     * @param _to The address to mint the Glyph to.
     */
    function mintGenesisGlyph(address _to) public onlyOwner {
        _glyphTokenIds.increment();
        uint256 newGlyphId = _glyphTokenIds.current();
        require(newGlyphId <= MAX_GENESIS_GLYPHS, "Max genesis glyphs minted");

        _safeMint(_to, newGlyphId);

        // Initialize Glyph with empty components and base stats
        glyphs[newGlyphId] = Glyph({
            componentIds: new uint256[](GLYPH_COMPONENT_SLOTS),
            auraLevel: 1, // Starting aura
            defensiveStance: false,
            lastEvolutionEpoch: globalParameters["CURRENT_EPOCH"]
        });

        // Initialize component slots with 0 (representing no component)
        for (uint256 i = 0; i < GLYPH_COMPONENT_SLOTS; i++) {
            glyphs[newGlyphId].componentIds[i] = 0;
        }

        emit GlyphMinted(newGlyphId, _to);
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * Generates a dynamic metadata URI based on the Glyph's components.
     * In a real scenario, this would point to an API that queries the on-chain data
     * and constructs the JSON/image on the fly.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Base URI to an external service that renders metadata based on Glyph's components
        string memory baseURI = "https://your-dynamic-metadata-api.com/glyph/";
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Retrieves all details of a ChronoGlyph.
     * @param _glyphId The ID of the Glyph.
     * @return componentIds The IDs of components attached to the Glyph.
     * @return auraLevel The current aura level of the Glyph.
     * @return defensiveStance The current defensive stance of the Glyph.
     * @return lastEvolutionEpoch The epoch of the last major evolution.
     */
    function getGlyphDetails(uint256 _glyphId)
        public
        view
        returns (
            uint256[] memory componentIds,
            uint256 auraLevel,
            bool defensiveStance,
            uint256 lastEvolutionEpoch
        )
    {
        require(_exists(_glyphId), "Glyph does not exist");
        Glyph storage glyph = glyphs[_glyphId];
        return (
            glyph.componentIds,
            glyph.auraLevel,
            glyph.defensiveStance,
            glyph.lastEvolutionEpoch
        );
    }

    // ERC721 standard functions (safeTransferFrom, approve, setApprovalForAll) are inherited.

    // --- II. Dynamic Trait & Component Evolution ---

    /**
     * @dev Defines a new general type of component (e.g., "Head", "Weapon").
     * @param _componentTypeId A unique identifier for the component type.
     * @param _name The name of the component type.
     * @param _maxSupply The maximum total supply for this component type.
     */
    function defineComponentType(uint256 _componentTypeId, string memory _name, uint256 _maxSupply) public onlyOwner {
        require(componentTypes[_componentTypeId].mintedSupply == 0, "Component type already defined");
        componentTypes[_componentTypeId] = ComponentType({
            name: _name,
            maxSupply: _maxSupply,
            mintedSupply: 0
        });
        emit ComponentRecipeSet(keccak256(abi.encodePacked("COMPONENT_TYPE_DEFINED", _componentTypeId))); // Reusing event for similar concept
    }

    /**
     * @dev Mints a specific component instance of a defined type. Only callable by the owner.
     * @param _componentTypeId The type ID of the component to mint.
     * @param _componentMetadataURI The metadata URI for this specific component instance.
     * @param _to The address to mint the component to (or address(0) if to be directly attached/burned).
     * @return The ID of the newly minted component instance.
     */
    function mintComponent(uint256 _componentTypeId, string memory _componentMetadataURI, address _to) public onlyOwner returns (uint256) {
        ComponentType storage cType = componentTypes[_componentTypeId];
        require(cType.mintedSupply < cType.maxSupply, "Max supply for this component type reached");

        _componentTokenIds.increment();
        uint256 newComponentId = _componentTokenIds.current();

        components[newComponentId] = Component({
            componentTypeId: _componentTypeId,
            owner: _to, // Initially owned by _to, or address(0) if meant for direct internal use
            metadataURI: _componentMetadataURI
        });

        if (_to != address(0)) {
            componentInventory[_to][newComponentId] = true;
        }
        cType.mintedSupply++;

        emit ComponentMinted(newComponentId, _componentTypeId, _to);
        return newComponentId;
    }

    /**
     * @dev Replaces an existing component on a Glyph with a new one.
     * The old component is burned. The new component must be owned by the caller.
     * @param _glyphId The ID of the Glyph to modify.
     * @param _slotIndex The index of the component slot to update (0 to GLYPH_COMPONENT_SLOTS-1).
     * @param _newComponentId The ID of the new component to attach.
     */
    function updateGlyphComponent(uint256 _glyphId, uint256 _slotIndex, uint256 _newComponentId) public onlyGlyphOwner(_glyphId) {
        require(_slotIndex < GLYPH_COMPONENT_SLOTS, "Invalid component slot index");
        require(components[_newComponentId].componentTypeId != 0, "New component does not exist");
        require(components[_newComponentId].owner == msg.sender, "New component not owned by caller");
        require(componentInventory[msg.sender][_newComponentId], "New component not in inventory");

        Glyph storage glyph = glyphs[_glyphId];
        uint256 oldComponentId = glyph.componentIds[_slotIndex];

        // Transfer new component to Glyph (owner becomes address(0) for attached components)
        components[_newComponentId].owner = address(0);
        componentInventory[msg.sender][_newComponentId] = false; // Remove from sender's inventory

        glyph.componentIds[_slotIndex] = _newComponentId;

        // Burn the old component if it existed
        if (oldComponentId != 0) {
            delete components[oldComponentId]; // Permanently remove old component data
            emit ComponentDeconstructed(_glyphId, oldComponentId); // Re-use event for burning
        }

        emit GlyphComponentUpdated(_glyphId, _slotIndex, oldComponentId, _newComponentId);
    }

    /**
     * @dev Allows a user to burn multiple source components to mint a new, synthesized component.
     * Requires the corresponding recipe to be set by the owner.
     * @param _sourceComponentIds An array of component IDs to be consumed (burned).
     * @param _outputComponentTypeId The type ID of the component to be produced.
     * @param _outputComponentId The specific component ID to be produced (must be pre-minted by owner for the recipe).
     */
    function synthesizeComponents(uint256[] calldata _sourceComponentIds, uint256 _outputComponentTypeId, uint256 _outputComponentId) public payable {
        bytes32 recipeHash = keccak256(abi.encodePacked(_sourceComponentIds));
        ComponentRecipe storage recipe = synthesisRecipes[recipeHash];

        require(recipe.isActive, "Recipe not active");
        require(recipe.outputComponentTypeId == _outputComponentTypeId, "Output component type mismatch");
        require(recipe.outputComponentId == _outputComponentId, "Output component ID mismatch");
        require(msg.value >= recipe.cost, "Insufficient ETH for synthesis");

        // Verify ownership and burn source components
        for (uint256 i = 0; i < _sourceComponentIds.length; i++) {
            uint256 compId = _sourceComponentIds[i];
            require(components[compId].owner == msg.sender, "Caller does not own a source component");
            require(componentInventory[msg.sender][compId], "Source component not in inventory");

            // Burn component
            componentInventory[msg.sender][compId] = false;
            delete components[compId];
            emit ComponentDeconstructed(0, compId); // 0 for glyphId indicates burning from inventory
        }

        // Transfer synthesized component to sender
        require(components[_outputComponentId].componentTypeId != 0, "Output component does not exist or was burned");
        require(components[_outputComponentId].owner == address(0) || components[_outputComponentId].owner == address(this), "Output component already owned");

        components[_outputComponentId].owner = msg.sender;
        componentInventory[msg.sender][_outputComponentId] = true;

        emit ComponentsSynthesized(msg.sender, _sourceComponentIds, _outputComponentId);
    }

    /**
     * @dev Removes a component from a Glyph, burning it permanently.
     * @param _glyphId The ID of the Glyph.
     * @param _slotIndex The index of the component slot to deconstruct.
     */
    function deconstructComponent(uint256 _glyphId, uint256 _slotIndex) public onlyGlyphOwner(_glyphId) {
        require(_slotIndex < GLYPH_COMPONENT_SLOTS, "Invalid component slot index");

        Glyph storage glyph = glyphs[_glyphId];
        uint256 componentToBurnId = glyph.componentIds[_slotIndex];
        require(componentToBurnId != 0, "No component in this slot to deconstruct");

        glyph.componentIds[_slotIndex] = 0; // Set slot to empty
        delete components[componentToBurnId]; // Permanently remove component data

        emit ComponentDeconstructed(_glyphId, componentToBurnId);
    }

    /**
     * @dev Evolves a Glyph's intrinsic `auraLevel` by burning a specific "booster" component.
     * @param _glyphId The ID of the Glyph to evolve.
     * @param _boosterComponentId The ID of the booster component to be consumed.
     */
    function evolveGlyphAura(uint256 _glyphId, uint256 _boosterComponentId) public onlyGlyphOwner(_glyphId) {
        require(components[_boosterComponentId].owner == msg.sender, "Booster component not owned by caller");
        require(componentInventory[msg.sender][_boosterComponentId], "Booster component not in inventory");

        // Example: Only allow certain component types as boosters
        // For a real contract, this would involve specific booster component type IDs
        // For simplicity, let's assume any existing component can be a booster for now.
        // Or, specifically: require(components[_boosterComponentId].componentTypeId == BOOSTER_TYPE_ID, "Invalid booster component type");

        Glyph storage glyph = glyphs[_glyphId];
        glyph.auraLevel = glyph.auraLevel + 1; // Simple increment, could be more complex logic
        glyph.lastEvolutionEpoch = globalParameters["CURRENT_EPOCH"];

        // Burn the booster component
        componentInventory[msg.sender][_boosterComponentId] = false;
        delete components[_boosterComponentId];

        emit GlyphAuraEvolved(_glyphId, glyph.auraLevel);
        emit ComponentDeconstructed(0, _boosterComponentId); // Indicate booster burned from inventory
    }

    /**
     * @dev Toggles a Glyph's `defensiveStance` between true/false.
     * This could change its functional attributes in an external game or system.
     * @param _glyphId The ID of the Glyph to toggle.
     */
    function toggleGlyphDefensiveStance(uint256 _glyphId) public onlyGlyphOwner(_glyphId) {
        Glyph storage glyph = glyphs[_glyphId];
        glyph.defensiveStance = !glyph.defensiveStance;
        emit GlyphStanceToggled(_glyphId, glyph.defensiveStance);
    }

    /**
     * @dev Retrieves details about a specific component instance.
     * @param _componentId The ID of the component instance.
     * @return componentTypeId The type ID of the component.
     * @return owner The current owner address of the component (address(0) if attached to a Glyph).
     * @return metadataURI The metadata URI for this component instance.
     */
    function getComponentDetails(uint256 _componentId) public view returns (uint256 componentTypeId, address owner, string memory metadataURI) {
        require(components[_componentId].componentTypeId != 0, "Component does not exist");
        Component storage comp = components[_componentId];
        return (comp.componentTypeId, comp.owner, comp.metadataURI);
    }

    // --- III. Epochs & Global State Management ---

    /**
     * @dev Initiates a transition to the next epoch. Only callable by the owner.
     * This can unlock new features, modify rules, or enable different interactions.
     */
    function initiateEpochTransition() public onlyOwner {
        uint256 currentEpoch = globalParameters["CURRENT_EPOCH"];
        globalParameters["CURRENT_EPOCH"] = currentEpoch + 1;
        emit EpochTransitioned(currentEpoch + 1);
    }

    /**
     * @dev Sets or updates a numerical rule for a specific epoch. Callable by the owner.
     * This allows for dynamic adjustments to contract mechanics over time.
     * @param _epoch The epoch for which the rule applies.
     * @param _ruleKey A unique identifier for the rule (e.g., "SYNTHESIS_FEE").
     * @param _value The value of the rule.
     */
    function setEpochRule(uint256 _epoch, bytes32 _ruleKey, uint256 _value) public onlyOwner {
        epochRules[_epoch][_ruleKey] = _value;
        emit EpochRuleSet(_epoch, _ruleKey, _value);
    }

    /**
     * @dev Retrieves a specific rule value for a given epoch.
     * @param _epoch The epoch to query.
     * @param _ruleKey The key of the rule.
     * @return The value of the rule. Returns 0 if not set.
     */
    function getEpochRule(uint256 _epoch, bytes32 _ruleKey) public view returns (uint256) {
        return epochRules[_epoch][_ruleKey];
    }

    /**
     * @dev Activates a global protocol feature. Callable by the owner.
     * This could be used to enable or disable major functionalities for all Glyphs.
     * @param _featureKey A unique identifier for the feature (e.g., "GLYPH_QUESTS_ENABLED").
     */
    function activateGlyphProtocolFeature(bytes32 _featureKey) public onlyOwner {
        activatedFeatures[_featureKey] = true;
        emit ProtocolFeatureActivated(_featureKey);
    }

    // --- IV. Community & Treasury (Simplified Governance Hooks) ---

    /**
     * @dev Allows anyone to deposit ETH into the contract's treasury.
     */
    function depositToTreasury() public payable {
        require(msg.value > 0, "Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows the contract owner to withdraw funds from the treasury.
     * In a full DAO, this would be subject to a successful governance proposal.
     * @param _to The address to send funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFromTreasury(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance in treasury");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw funds");
        emit FundsWithdrawn(_to, _amount);
    }

    /**
     * @dev Sets or updates a component synthesis recipe. Callable by the owner.
     * Input components must be specified by their individual IDs (for simple recipes) or type IDs (for more complex ones).
     * @param _inputComponentIds An array of component IDs required as input.
     * @param _outputComponentTypeId The type ID of the component produced.
     * @param _outputComponentId The specific ID of the component instance that will be given as output. This component instance must be pre-minted by the owner and "owned" by the contract (address(0) or address(this)).
     * @param _recipeCost The ETH cost to perform this synthesis.
     */
    function setComponentRecipe(uint256[] calldata _inputComponentIds, uint256 _outputComponentTypeId, uint256 _outputComponentId, uint256 _recipeCost) public onlyOwner {
        // Ensure input and output components are valid and output is not already owned by a user
        require(_inputComponentIds.length > 0, "Input components cannot be empty");
        require(componentTypes[_outputComponentTypeId].mintedSupply != 0, "Output component type not defined");
        require(components[_outputComponentId].componentTypeId != 0 && (components[_outputComponentId].owner == address(0) || components[_outputComponentId].owner == address(this)), "Output component must exist and not be user-owned");
        require(components[_outputComponentId].componentTypeId == _outputComponentTypeId, "Output component ID does not match output type ID");


        bytes32 recipeHash = keccak256(abi.encodePacked(_inputComponentIds));
        synthesisRecipes[recipeHash] = ComponentRecipe({
            inputComponentIds: _inputComponentIds,
            outputComponentTypeId: _outputComponentTypeId,
            outputComponentId: _outputComponentId,
            cost: _recipeCost,
            isActive: true
        });
        emit ComponentRecipeSet(recipeHash);
    }

    /**
     * @dev Removes a component synthesis recipe. Callable by the owner.
     * @param _inputComponentIds The array of input component IDs that define the recipe to remove.
     */
    function removeComponentRecipe(uint256[] calldata _inputComponentIds) public onlyOwner {
        bytes32 recipeHash = keccak256(abi.encodePacked(_inputComponentIds));
        require(synthesisRecipes[recipeHash].isActive, "Recipe is not active or does not exist");
        synthesisRecipes[recipeHash].isActive = false; // Deactivate rather than delete for historical tracking
        emit ComponentRecipeRemoved(recipeHash);
    }

    /**
     * @dev Allows a user (or future DAO) to propose a change to a global parameter.
     * Simplified: currently, anyone can propose, but execution is owner-gated.
     * A real DAO would require a voting power check.
     * @param _parameterKey The key of the parameter to change.
     * @param _newValue The new value for the parameter.
     * @param _duration The duration of the voting period in seconds.
     */
    function proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, uint256 _duration) public {
        require(proposals[_parameterKey].duration == 0 || block.timestamp > proposals[_parameterKey].duration, "A proposal for this parameter is already active");
        proposals[_parameterKey] = Proposal({
            parameterKey: _parameterKey,
            newValue: _newValue,
            duration: block.timestamp + _duration,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false
        });
        emit ParameterChangeProposed(_parameterKey, _newValue, block.timestamp + _duration, _duration);
    }

    /**
     * @dev Allows users to vote on an active proposal.
     * Voting power should be based on owned Glyphs in a real DAO.
     * Simplified: 1 address = 1 vote.
     * @param _parameterKey The key of the parameter the proposal is about.
     * @param _support True for "yes", false for "no".
     */
    function voteOnParameterChange(bytes32 _parameterKey, bool _support) public {
        Proposal storage proposal = proposals[_parameterKey];
        require(proposal.duration != 0 && block.timestamp <= proposal.duration, "Proposal is not active or does not exist");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VotedOnProposal(msg.sender, _parameterKey, _support);
    }

    /**
     * @dev Executes a passed proposal. Owner-callable (or by DAO if implemented).
     * Simplified: requires votes to be counted off-chain or by a separate voting module.
     * For demonstration, this function assumes the owner manually checks vote outcomes.
     * In a real system, this would have `require` conditions checking vote thresholds.
     * @param _parameterKey The key of the parameter to execute the change for.
     */
    function executeParameterChange(bytes32 _parameterKey) public onlyOwner {
        Proposal storage proposal = proposals[_parameterKey];
        require(proposal.duration != 0 && block.timestamp > proposal.duration, "Voting period not ended or proposal non-existent");
        require(!proposal.executed, "Proposal already executed");

        // Simple majority check (replace with more robust logic for actual DAO)
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass (no majority for yes)");

        globalParameters[_parameterKey] = proposal.newValue;
        proposal.executed = true;
        emit ProposalExecuted(_parameterKey, proposal.newValue);
    }
}
```