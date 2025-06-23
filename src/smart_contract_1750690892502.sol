Okay, here is a Solidity smart contract incorporating advanced, creative, and trendy concepts centered around a dynamic, craftable/evolvable digital asset system for a hypothetical metaverse or game. It avoids direct duplication of standard ERC implementations for the core logic, managing assets internally with functions to interact with their state and history.

It focuses on:

1.  **Forging/Crafting:** Assets ("Artifacts") are created from consumable inputs ("Components").
2.  **Dynamic Traits:** Artifacts have traits that can change over time or through actions.
3.  **Evolution/Reforging:** Artifacts can be upgraded or modified using specific processes.
4.  **Internal Marketplace:** Basic functions for peer-to-peer trading within the contract logic (transfer of ownership and ETH).
5.  **Delegated Usage:** Owners can allow others to use their artifacts for certain functions without transferring ownership.
6.  **Probabilistic Discovery:** A function simulating finding random components or potentially rare artifacts.
7.  **History Tracking:** Simple on-chain logging of major artifact events.

**Outline & Function Summary**

**Contract Name:** `MetaverseAssetForge`

**Purpose:** Manages a system of crafting Components into dynamic Artifacts with evolvable traits, including features like internal trading and usage delegation.

**Key Concepts:**
*   **Components:** Consumable tokens used as ingredients. Fungible within their type.
*   **Artifacts:** Non-fungible, dynamic assets created via forging. Have traits and history.
*   **Traits:** Dynamic attributes of Artifacts that can change.
*   **Forging:** Process of consuming Components to create a new Artifact.
*   **Evolution:** Process of upgrading an existing Artifact, potentially changing its traits.
*   **Reforging:** Process of modifying traits of an existing Artifact.
*   **Delegation:** Granting temporary permission to another address to use an Artifact.
*   **Internal Listing:** Basic p2p sale mechanism within the contract.
*   **Discovery:** Probabilistic function to acquire new items.

**Contract Structure:**
1.  **State Variables & Data Structures:** Define the core data types (Components, Artifacts, Traits, Listings, Rules) and storage mappings.
2.  **Events:** Log important actions.
3.  **Modifiers:** Access control and state checks.
4.  **Administrative Functions:** Setup and control of the contract and rules.
5.  **Component Management:** Minting, burning, transferring Components.
6.  **Artifact Management & Core Logic:** Forging, evolving, reforging, transferring, burning Artifacts.
7.  **Trait Management:** Functions to get and potentially update traits (mostly done via Evolve/Reforge).
8.  **Discovery Mechanics:** Simulating finding items probabilistically.
9.  **Delegation System:** Managing artifact usage permissions.
10. **Internal Marketplace:** Listing, buying, cancelling item sales.
11. **Query Functions:** Retrieving state information.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and sets initial parameters.
2.  `setMinter(address _minter)`: Grants the minter role (for creating initial components/artifact types). (Admin)
3.  `registerComponentType(string calldata name, string calldata baseMetadataURI, uint256 maxSupply)`: Defines a new type of Component. (Admin/Minter)
4.  `registerArtifactType(string calldata name, string calldata baseMetadataURI)`: Defines a new type of Artifact. (Admin/Minter)
5.  `registerTraitType(string calldata name, uint8 dataType, uint8 evolutionRuleType)`: Defines a new type of Trait and its behavior rules. (Admin/Minter)
6.  `updateForgeRule(uint256 artifactTypeId, uint256[] calldata requiredComponentTypeIds, uint256[] calldata requiredComponentAmounts)`: Sets the component requirements for forging a specific artifact type. (Admin)
7.  `updateTraitEvolutionRule(uint256 traitTypeId, uint256 evolutionLevel, uint8 ruleType, uint256 ruleValue)`: Defines how a trait changes at a specific evolution level. (Admin)
8.  `updateDiscoveryRates(uint256 componentTypeId, uint256 artifactTypeId, uint16 componentChance, uint16 artifactChance)`: Sets probabilities for finding items in `attemptDiscovery`. (Admin)
9.  `mintComponent(address to, uint256 componentTypeId, uint256 amount)`: Creates new components and assigns them. (Minter)
10. `burnComponent(uint256 componentTypeId, uint256 amount)`: Destroys components from the caller's balance. (Component Owner)
11. `transferComponent(address to, uint256 componentTypeId, uint256 amount)`: Transfers components to another address. (Component Owner)
12. `forgeArtifact(uint256 artifactTypeId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts)`: Consumes components to forge a new artifact. (Anyone)
13. `evolveArtifact(uint256 artifactId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts)`: Upgrades an existing artifact, potentially changing traits based on rules. (Artifact Owner/Delegated User)
14. `reforgeArtifact(uint256 artifactId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts, uint256[] calldata traitTypeIdsToReforge)`: Uses components to reroll or modify specific traits of an artifact. (Artifact Owner/Delegated User)
15. `transferArtifact(address to, uint256 artifactId)`: Transfers ownership of an artifact. (Artifact Owner)
16. `burnArtifact(uint256 artifactId)`: Destroys an artifact. (Artifact Owner)
17. `attemptDiscovery()`: Simulates a random discovery event based on defined rates. (Anyone)
18. `delegateArtifactUsage(address delegatee, uint256 artifactId, uint256 duration)`: Allows another address to use the artifact for a limited time. (Artifact Owner)
19. `revokeArtifactUsageDelegation(address delegatee, uint256 artifactId)`: Revokes usage delegation immediately. (Artifact Owner)
20. `listItemForSale(bool isComponent, uint256 itemId, uint256 amountOrArtifactId, uint256 price)`: Lists a component amount or an artifact for sale internally. (Item Owner)
21. `buyItem(uint256 listingId) payable`: Purchases an item listed for sale. (Buyer)
22. `cancelListing(uint256 listingId)`: Cancels an active listing. (Seller)
23. `withdrawFunds()`: Seller withdraws accumulated sale proceeds. (Seller)
24. `getComponentBalance(address owner, uint256 componentTypeId)`: Returns the component balance for an address. (View)
25. `getArtifactDetails(uint256 artifactId)`: Returns detailed information about an artifact. (View)
26. `getArtifactTraits(uint256 artifactId)`: Returns the dynamic traits of an artifact. (View)
27. `getArtifactHistory(uint256 artifactId)`: Returns the history log of an artifact. (View)
28. `getItemListing(uint256 listingId)`: Returns details of a sale listing. (View)
29. `isComponentOwner(address owner, uint256 componentTypeId, uint256 amount)`: Checks if an address owns at least a certain amount of a component type. (View)
30. `isArtifactOwner(address owner, uint256 artifactId)`: Checks if an address owns a specific artifact. (View)
31. `isArtifactOperator(address potentialOperator, uint256 artifactId)`: Checks if an address is delegated to use an artifact. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline & Function Summary provided above the contract code block.

/**
 * @title MetaverseAssetForge
 * @dev A smart contract for crafting, evolving, and managing dynamic digital assets (Artifacts)
 *      from consumable inputs (Components) for a hypothetical metaverse or game.
 *      Includes features like dynamic traits, history tracking, usage delegation,
 *      probabilistic discovery, and a basic internal marketplace.
 */
contract MetaverseAssetForge {
    // =========================================================================================
    //                                     Errors
    // =========================================================================================
    error NotOwner();
    error NotMinter();
    error NotItemOwnerOrOperator();
    error InsufficientComponents();
    error InvalidComponentAmounts();
    error ArtifactNotFound();
    error ComponentTypeNotFound();
    error ArtifactTypeNotFound();
    error TraitTypeNotFound();
    error InvalidForgeRule();
    error ArtifactNotEvolvable();
    error InvalidTraitReforge();
    error DelegationNotFound();
    error DelegationExpired();
    error ItemNotFound();
    error ListingNotFound();
    error NotListingSeller();
    error InsufficientPayment();
    error ListingAlreadyExists();
    error ItemAlreadyListed();
    error CannotBuyOwnItem();
    error ZeroAmount();
    error MaxSupplyReached();
    error Paused();
    error NotPaused();

    // =========================================================================================
    //                                     Events
    // =========================================================================================
    event ComponentTypeRegistered(uint256 indexed componentTypeId, string name, uint256 maxSupply);
    event ArtifactTypeRegistered(uint256 indexed artifactTypeId, string name);
    event TraitTypeRegistered(uint256 indexed traitTypeId, string name);
    event ForgeRuleUpdated(uint256 indexed artifactTypeId, uint256[] requiredComponentTypeIds, uint256[] requiredComponentAmounts);
    event TraitEvolutionRuleUpdated(uint256 indexed traitTypeId, uint256 indexed evolutionLevel);
    event DiscoveryRatesUpdated(uint256 indexed componentTypeId, uint256 indexed artifactTypeId, uint16 componentChance, uint16 artifactChance);

    event ComponentsMinted(address indexed to, uint256 indexed componentTypeId, uint256 amount);
    event ComponentsBurned(address indexed from, uint256 indexed componentTypeId, uint256 amount);
    event ComponentsTransferred(address indexed from, address indexed to, uint256 indexed componentTypeId, uint256 amount);

    event ArtifactForged(uint256 indexed artifactId, address indexed owner, uint256 indexed artifactTypeId);
    event ArtifactEvolved(uint256 indexed artifactId, uint256 newEvolutionLevel);
    event ArtifactReforged(uint256 indexed artifactId);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactBurned(address indexed from, uint256 indexed artifactId);

    event ItemDiscovered(address indexed receiver, bool isComponent, uint256 itemId, uint256 amount); // amount only for components

    event UsageDelegated(uint256 indexed artifactId, address indexed delegatee, uint256 expiryTimestamp);
    event UsageDelegationRevoked(uint256 indexed artifactId, address indexed delegatee);

    event ItemListedForSale(uint256 indexed listingId, bool isComponent, uint256 itemId, uint256 amountOrArtifactId, uint256 price, address indexed seller);
    event ItemSold(uint256 indexed listingId, uint256 itemId, address indexed seller, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event FundsWithdrawn(address indexed seller, uint256 amount);

    event PausedStateChanged(bool isPaused);

    // =========================================================================================
    //                                     Enums
    // =========================================================================================
    enum TraitDataType { Uint256, String, Bool } // Defines the type of data a trait holds
    enum TraitEvolutionRuleType { Static, AddValue, SetValue, RandomRange, BasedOnInputComponents } // How a trait changes upon evolution/reforging
    enum ItemTypeForListing { Component, Artifact } // Used in the listing system

    // =========================================================================================
    //                                     Structs
    // =========================================================================================
    struct ComponentType {
        string name;
        string baseMetadataURI;
        uint256 maxSupply;
        uint256 mintedSupply;
    }

    struct Trait {
        uint256 traitTypeId;
        uint256 uintValue; // Stores uint256 data
        string stringValue; // Stores string data
        bool boolValue;     // Stores bool data
        uint256 lastUpdatedTimestamp;
    }

    struct HistoryEntry {
        string action;
        uint256 timestamp;
        address byAddress;
        string details; // e.g., "Forged using x, y", "Evolved to level 2", "Reforged trait Z"
    }

    struct Artifact {
        uint256 artifactId;
        uint256 artifactTypeId;
        address owner;
        Trait[] traits;
        uint256 forgedTimestamp;
        uint256 evolutionLevel;
        HistoryEntry[] history;
    }

     struct ForgeRule {
        uint256[] requiredComponentTypeIds;
        uint256[] requiredComponentAmounts;
    }

    struct TraitEvolutionRule {
        uint8 ruleType; // Corresponds to TraitEvolutionRuleType enum
        uint256 ruleValue; // Generic value used by the rule (e.g., amount to add, specific value)
        // Could add specific component requirements here if ruleType == BasedOnInputComponents
    }

    struct DiscoveryRate {
        uint16 componentChance; // Chance out of 10000 (e.g., 100 = 1%)
        uint16 artifactChance;  // Chance out of 10000
    }

     struct Listing {
        uint256 listingId;
        ItemTypeForListing itemType;
        uint256 itemId; // ComponentTypeId or ArtifactId
        uint256 amountOrArtifactId; // Amount for component, ArtifactId for artifact (redundant but clear)
        uint256 price; // Price in Wei
        address seller;
        bool active;
    }

    // =========================================================================================
    //                                     State Variables
    // =========================================================================================
    address public owner;
    address public minter;
    bool public paused = false;

    // Counters for unique IDs
    uint256 private _nextComponentTypeId = 1;
    uint256 private _nextArtifactTypeId = 1;
    uint256 private _nextTraitTypeId = 1;
    uint256 private _nextArtifactId = 1; // Artifact IDs are global and unique across types
    uint256 private _nextListingId = 1;

    // Asset data
    mapping(uint256 => ComponentType) public componentTypes;
    mapping(address => mapping(uint256 => uint256)) public componentBalances; // owner => componentTypeId => amount

    mapping(uint256 => Artifact) public artifacts; // artifactId => Artifact

    // Rules and configurations
    mapping(uint256 => ForgeRule) public forgeRules; // artifactTypeId => rule
    mapping(uint256 => mapping(uint256 => TraitEvolutionRule)) public traitEvolutionRules; // traitTypeId => evolutionLevel => rule
    mapping(uint256 => DiscoveryRate) public discoveryRates; // componentTypeId (for specific discovery) or 0 (for general/artifact) => rate

    // Delegation data (artifactId => delegatee => expiryTimestamp)
    mapping(uint256 => mapping(address => uint256)) public artifactUsageDelegation;

    // Marketplace data
    mapping(uint256 => Listing) public listings; // listingId => Listing
    // Map item to active listing ID (isComponent => itemId => listingId). Allows checking if item is listed.
    mapping(bool => mapping(uint256 => uint256)) private _itemToListingId;
    mapping(address => uint256) public fundsAvailableForWithdrawal; // seller => amount

    // =========================================================================================
    //                                     Modifiers
    // =========================================================================================
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) revert NotMinter();
        _;
    }

    modifier onlyArtifactOwnerOrOperator(uint256 _artifactId) {
        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.owner == address(0)) revert ArtifactNotFound(); // Check if artifact exists

        bool isOwner = artifact.owner == msg.sender;
        bool isOperator = artifactUsageDelegation[_artifactId][msg.sender] > block.timestamp;

        if (!isOwner && !isOperator) revert NotItemOwnerOrOperator();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    // =========================================================================================
    //                                   Constructor
    // =========================================================================================
    constructor() {
        owner = msg.sender;
    }

    // =========================================================================================
    //                                Administrative Functions
    // =========================================================================================

    /**
     * @dev Sets the address with the minter role. Only callable by the contract owner.
     * @param _minter The address to grant the minter role to.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /**
     * @dev Registers a new type of component. Only callable by Admin or Minter.
     * @param name The name of the component type.
     * @param baseMetadataURI The base URI for metadata (can be appended with ID or details).
     * @param maxSupply The maximum total supply for this component type (0 for unlimited).
     */
    function registerComponentType(string calldata name, string calldata baseMetadataURI, uint256 maxSupply) external onlyOwner {
        uint256 newTypeId = _nextComponentTypeId++;
        componentTypes[newTypeId] = ComponentType(name, baseMetadataURI, maxSupply, 0);
        emit ComponentTypeRegistered(newTypeId, name, maxSupply);
    }

    /**
     * @dev Registers a new type of artifact. Only callable by Admin or Minter.
     * @param name The name of the artifact type.
     * @param baseMetadataURI The base URI for metadata.
     */
    function registerArtifactType(string calldata name, string calldata baseMetadataURI) external onlyOwner {
        uint256 newTypeId = _nextArtifactTypeId++;
        // Placeholder for artifact type data storage if needed (e.g., mapping from artifactTypeId to metadataURI)
        // artifactTypes[newTypeId] = ArtifactType(name, baseMetadataURI); // Example if ArtifactType struct existed
        emit ArtifactTypeRegistered(newTypeId, name);
    }

    /**
     * @dev Registers a new type of trait. Only callable by Admin or Minter.
     * @param name The name of the trait type.
     * @param dataType The data type of the trait (Uint256, String, Bool).
     * @param evolutionRuleType The default evolution rule type for this trait.
     */
    function registerTraitType(string calldata name, uint8 dataType, uint8 evolutionRuleType) external onlyOwner {
        uint256 newTypeId = _nextTraitTypeId++;
        // Placeholder for trait type data storage if needed
        // traitTypes[newTypeId] = TraitType(name, dataType, evolutionRuleType); // Example if TraitType struct existed
        emit TraitTypeRegistered(newTypeId, name);
    }

    /**
     * @dev Sets or updates the required components for forging a specific artifact type.
     *      Only callable by the contract owner.
     * @param artifactTypeId The ID of the artifact type.
     * @param requiredComponentTypeIds Array of component type IDs required.
     * @param requiredComponentAmounts Array of amounts corresponding to the component type IDs.
     */
    function updateForgeRule(uint256 artifactTypeId, uint256[] calldata requiredComponentTypeIds, uint256[] calldata requiredComponentAmounts) external onlyOwner {
        if (componentTypes[requiredComponentTypeIds[0]].name == "") revert ComponentTypeNotFound(); // Basic existence check
        // Add more robust checks for all IDs

        if (requiredComponentTypeIds.length != requiredComponentAmounts.length) revert InvalidForgeRule();

        forgeRules[artifactTypeId] = ForgeRule(requiredComponentTypeIds, requiredComponentAmounts);
        emit ForgeRuleUpdated(artifactTypeId, requiredComponentTypeIds, requiredComponentAmounts);
    }

     /**
     * @dev Sets or updates the rule for how a specific trait type evolves at a given evolution level.
     *      Only callable by the contract owner.
     * @param traitTypeId The ID of the trait type.
     * @param evolutionLevel The evolution level this rule applies to.
     * @param ruleType The type of rule (e.g., AddValue, SetValue).
     * @param ruleValue A value used by the rule (e.g., amount to add).
     */
    function updateTraitEvolutionRule(uint256 traitTypeId, uint256 evolutionLevel, uint8 ruleType, uint256 ruleValue) external onlyOwner {
         // Basic check if traitType exists (could be enhanced)
        if (traitTypeId >= _nextTraitTypeId) revert TraitTypeNotFound();

        traitEvolutionRules[traitTypeId][evolutionLevel] = TraitEvolutionRule(ruleType, ruleValue);
        emit TraitEvolutionRuleUpdated(traitTypeId, evolutionLevel);
    }

    /**
     * @dev Sets or updates the discovery rates for specific component types or general artifacts.
     *      Only callable by the contract owner. Rates are out of 10000.
     * @param componentTypeId The ID of the component type (0 for general artifact discovery).
     * @param artifactTypeId If componentTypeId is 0, this is the potential artifact type ID to discover (optional).
     * @param componentChance The chance (0-10000) of finding this component type.
     * @param artifactChance The chance (0-10000) of finding the specified artifact type (if componentTypeId is 0).
     */
    function updateDiscoveryRates(uint256 componentTypeId, uint256 artifactTypeId, uint16 componentChance, uint16 artifactChance) external onlyOwner {
         // Basic checks for existence if IDs are non-zero
         if (componentTypeId != 0 && componentTypes[componentTypeId].name == "") revert ComponentTypeNotFound();
         if (artifactTypeId != 0 && artifactTypeId >= _nextArtifactTypeId) revert ArtifactTypeNotFound(); // Placeholder check

         discoveryRates[componentTypeId] = DiscoveryRate(componentChance, artifactChance);
         emit DiscoveryRatesUpdated(componentTypeId, artifactTypeId, componentChance, artifactChance);
    }

    /**
     * @dev Pauses the contract, preventing core actions like forging, evolving, trading, etc.
     *      Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit PausedStateChanged(true);
    }

    /**
     * @dev Unpauses the contract, allowing actions to resume.
     *      Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit PausedStateChanged(false);
    }

    // =========================================================================================
    //                                 Component Management
    // =========================================================================================

    /**
     * @dev Mints new components of a specific type and assigns them to an address.
     *      Only callable by the minter.
     * @param to The address to mint components to.
     * @param componentTypeId The type of component to mint.
     * @param amount The amount of components to mint.
     */
    function mintComponent(address to, uint256 componentTypeId, uint256 amount) external onlyMinter whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        ComponentType storage cType = componentTypes[componentTypeId];
        if (cType.name == "") revert ComponentTypeNotFound();

        unchecked {
            uint256 newTotalSupply = cType.mintedSupply + amount;
             if (cType.maxSupply > 0 && newTotalSupply > cType.maxSupply) revert MaxSupplyReached();
            cType.mintedSupply = newTotalSupply;
        }

        componentBalances[to][componentTypeId] += amount;
        emit ComponentsMinted(to, componentTypeId, amount);
    }

    /**
     * @dev Burns components of a specific type from the caller's balance.
     * @param componentTypeId The type of component to burn.
     * @param amount The amount of components to burn.
     */
    function burnComponent(uint256 componentTypeId, uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (componentBalances[msg.sender][componentTypeId] < amount) revert InsufficientComponents();

        componentBalances[msg.sender][componentTypeId] -= amount;
        emit ComponentsBurned(msg.sender, componentTypeId, amount);
    }

    /**
     * @dev Transfers components of a specific type from the caller's balance to another address.
     * @param to The address to transfer components to.
     * @param componentTypeId The type of component to transfer.
     * @param amount The amount of components to transfer.
     */
    function transferComponent(address to, uint256 componentTypeId, uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (to == address(0)) revert ItemNotFound(); // Invalid recipient
        if (componentBalances[msg.sender][componentTypeId] < amount) revert InsufficientComponents();

        componentBalances[msg.sender][componentTypeId] -= amount;
        componentBalances[to][componentTypeId] += amount;
        emit ComponentsTransferred(msg.sender, to, componentTypeId, amount);
    }

    // =========================================================================================
    //                             Artifact Management & Core Logic
    // =========================================================================================

    /**
     * @dev Forges a new artifact of a specific type by consuming required components.
     *      Callable by anyone.
     * @param artifactTypeId The type of artifact to forge.
     * @param componentTypeIds Array of component type IDs being used.
     * @param componentAmounts Array of amounts corresponding to the component type IDs.
     * @return The ID of the newly forged artifact.
     */
    function forgeArtifact(uint256 artifactTypeId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts) external whenNotPaused returns (uint256) {
        ForgeRule storage rule = forgeRules[artifactTypeId];
        if (rule.requiredComponentTypeIds.length == 0) revert InvalidForgeRule(); // No rule defined for this type

        if (componentTypeIds.length != componentAmounts.length) revert InvalidComponentAmounts();
        if (componentTypeIds.length != rule.requiredComponentTypeIds.length) revert InvalidForgeRule(); // Must provide exactly the components required by the rule

        // Check and consume components
        for (uint i = 0; i < rule.requiredComponentTypeIds.length; i++) {
            uint256 requiredTypeId = rule.requiredComponentTypeIds[i];
            uint256 requiredAmount = rule.requiredComponentAmounts[i];

            // Find the provided component in the input arrays
            bool found = false;
            for (uint j = 0; j < componentTypeIds.length; j++) {
                 if (componentTypeIds[j] == requiredTypeId) {
                    if (componentAmounts[j] < requiredAmount) revert InsufficientComponents();
                    if (componentBalances[msg.sender][requiredTypeId] < requiredAmount) revert InsufficientComponents(); // Double-check balance

                    // Consume component
                    componentBalances[msg.sender][requiredTypeId] -= requiredAmount;
                    emit ComponentsBurned(msg.sender, requiredTypeId, requiredAmount);
                    found = true;
                    break; // Assume each required type appears once in input
                 }
            }
            if (!found) revert InvalidForgeRule(); // Missing a required component in the input
        }

        uint256 newArtifactId = _nextArtifactId++;
        Artifact storage newArtifact = artifacts[newArtifactId];
        newArtifact.artifactId = newArtifactId;
        newArtifact.artifactTypeId = artifactTypeId;
        newArtifact.owner = msg.sender;
        newArtifact.forgedTimestamp = block.timestamp;
        newArtifact.evolutionLevel = 1;

        // Initialize traits (could be based on artifactType, input components, or randomness)
        // For simplicity, let's initialize a couple of generic traits here.
        // In a real contract, this would be more complex based on game logic.
        uint256 initialTrait1TypeId = 1; // Example: Power
        uint256 initialTrait2TypeId = 2; // Example: Speed

        if (initialTrait1TypeId < _nextTraitTypeId) { // Basic check if trait type exists
             newArtifact.traits.push(Trait(initialTrait1TypeId, 10, "", false, block.timestamp));
        }
         if (initialTrait2TypeId < _nextTraitTypeId) {
             newArtifact.traits.push(Trait(initialTrait2TypeId, 5, "", false, block.timestamp));
        }


        // Add history entry
        newArtifact.history.push(HistoryEntry("Forged", block.timestamp, msg.sender, "Initial creation"));

        emit ArtifactForged(newArtifactId, msg.sender, artifactTypeId);

        return newArtifactId;
    }

    /**
     * @dev Evolves an existing artifact to the next level, potentially modifying its traits.
     *      Requires specific components and updates the artifact's evolution level and traits.
     *      Callable by the artifact owner or a delegated user.
     * @param artifactId The ID of the artifact to evolve.
     * @param componentTypeIds Array of component type IDs being used for evolution (if required).
     * @param componentAmounts Array of amounts corresponding to the component type IDs.
     */
    function evolveArtifact(uint256 artifactId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts) external onlyArtifactOwnerOrOperator(artifactId) whenNotPaused {
        Artifact storage artifact = artifacts[artifactId];
        // Add checks for specific component requirements for evolution if needed
        // For simplicity here, assuming evolution just costs some components (or none)
        // and triggers trait updates based on rules.

        // Example: Requires 10 of component type 1 for any evolution
        uint256 requiredEvolveComponentTypeId = 1;
        uint256 requiredEvolveAmount = 10;

         if (componentTypeIds.length != componentAmounts.length) revert InvalidComponentAmounts();
         bool requirementsMet = false;
         for(uint i = 0; i < componentTypeIds.length; i++) {
             if (componentTypeIds[i] == requiredEvolveComponentTypeId && componentAmounts[i] >= requiredEvolveAmount) {
                  if (componentBalances[msg.sender][requiredEvolveComponentTypeId] < requiredEvolveAmount) revert InsufficientComponents();
                  componentBalances[msg.sender][requiredEvolveComponentTypeId] -= requiredEvolveAmount;
                  emit ComponentsBurned(msg.sender, requiredEvolveComponentTypeId, requiredEvolveAmount);
                  requirementsMet = true;
                  break;
             }
         }
         if (!requirementsMet) revert InvalidComponentAmounts(); // Or a specific evolution component error

        // Update evolution level
        artifact.evolutionLevel++;

        // Apply trait evolution rules based on the new level
        for (uint i = 0; i < artifact.traits.length; i++) {
            Trait storage trait = artifact.traits[i];
            TraitEvolutionRule storage rule = traitEvolutionRules[trait.traitTypeId][artifact.evolutionLevel];

            // Apply rule based on type
            if (rule.ruleType == uint8(TraitEvolutionRuleType.AddValue)) {
                trait.uintValue += rule.ruleValue;
            } else if (rule.ruleType == uint8(TraitEvolutionRuleType.SetValue)) {
                 trait.uintValue = rule.ruleValue;
            }
             // Add more complex rules here (e.g., RandomRange, BasedOnInputComponents)

             trait.lastUpdatedTimestamp = block.timestamp;
             // Emit TraitChanged event if needed
        }

        // Add history entry
        artifact.history.push(HistoryEntry("Evolved", block.timestamp, msg.sender, string(abi.encodePacked("To level ", Strings.toString(artifact.evolutionLevel)))));

        emit ArtifactEvolved(artifactId, artifact.evolutionLevel);
    }

    /**
     * @dev Modifies specific traits of an artifact using components.
     *      Callable by the artifact owner or a delegated user.
     * @param artifactId The ID of the artifact to reforge.
     * @param componentTypeIds Array of component type IDs being used for reforging.
     * @param componentAmounts Array of amounts corresponding to the component type IDs.
     * @param traitTypeIdsToReforge Array of trait type IDs to attempt to reforge.
     */
    function reforgeArtifact(uint256 artifactId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts, uint256[] calldata traitTypeIdsToReforge) external onlyArtifactOwnerOrOperator(artifactId) whenNotPaused {
         Artifact storage artifact = artifacts[artifactId];

         // --- Component Consumption Logic (Example: 5 of Component Type 2 per trait) ---
         uint256 reforgeComponentTypeId = 2;
         uint256 reforgeAmountPerTrait = 5;
         uint256 totalRequiredAmount = reforgeAmountPerTrait * traitTypeIdsToReforge.length;

         if (componentTypeIds.length != 1 || componentAmounts.length != 1 ||
             componentTypeIds[0] != reforgeComponentTypeId || componentAmounts[0] < totalRequiredAmount) {
              revert InvalidComponentAmounts();
         }

         if (componentBalances[msg.sender][reforgeComponentTypeId] < totalRequiredAmount) revert InsufficientComponents();

         componentBalances[msg.sender][reforgeComponentTypeId] -= totalRequiredAmount;
         emit ComponentsBurned(msg.sender, reforgeComponentTypeId, totalRequiredAmount);
         // --- End Component Consumption ---

         // Apply reforging to specified traits
         for (uint i = 0; i < traitTypeIdsToReforge.length; i++) {
             uint256 targetTraitTypeId = traitTypeIdsToReforge[i];
             bool traitFound = false;
             for (uint j = 0; j < artifact.traits.length; j++) {
                 Trait storage trait = artifact.traits[j];
                 if (trait.traitTypeId == targetTraitTypeId) {
                     traitFound = true;

                     // --- Reforging Logic (Example: Simple random range reroll) ---
                     // Note: On-chain randomness is tricky. Using block.timestamp/difficulty is predictable.
                     // A production system would need Chainlink VRF or similar.
                     uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, artifactId, targetTraitTypeId, j)));
                     uint256 minReforgeValue = 1; // Example min
                     uint256 maxReforgeValue = 20; // Example max

                     // Assuming the trait is Uint256 for this example reforge
                     if (trait.traitTypeId < _nextTraitTypeId /*&& traitType is Uint256*/) { // Need to check TraitType data type
                          uint256 newTokenId = randomness % (maxReforgeValue - minReforgeValue + 1) + minReforgeValue;
                          trait.uintValue = newTokenId; // Assign new random value
                     }
                     // Add logic for other trait data types if needed

                     trait.lastUpdatedTimestamp = block.timestamp;
                     // Emit TraitChanged event if needed
                     // --- End Reforging Logic ---
                     break; // Move to the next traitTypeIdToReforge
                 }
             }
             if (!traitFound) revert InvalidTraitReforge(); // Trait type requested for reforge doesn't exist on artifact
         }

        // Add history entry
        artifact.history.push(HistoryEntry("Reforged", block.timestamp, msg.sender, string(abi.encodePacked("Traits updated: ", Strings.toString(traitTypeIdsToReforge.length)))));

         emit ArtifactReforged(artifactId);
    }


    /**
     * @dev Transfers ownership of an artifact. Only callable by the current owner.
     * @param to The address to transfer the artifact to.
     * @param artifactId The ID of the artifact to transfer.
     */
    function transferArtifact(address to, uint256 artifactId) external whenNotPaused {
        Artifact storage artifact = artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactNotFound();
        if (artifact.owner != msg.sender) revert NotItemOwnerOrOperator(); // Only owner can transfer

        if (to == address(0)) revert ItemNotFound(); // Invalid recipient

         // Check if the artifact is listed for sale and cancel the listing
        uint256 listingId = _itemToListingId[true][artifactId];
        if (listingId != 0 && listings[listingId].active) {
            _cancelListing(listingId); // Internal cancel
        }

        address from = artifact.owner;
        artifact.owner = to;

        // Clear any delegations upon transfer
        // Note: This might be undesirable depending on game design.
        // Could iterate through active delegations and revoke. For simplicity, clear map entry.
        delete artifactUsageDelegation[artifactId]; // Clears all delegations for this artifact

        // Add history entry
        artifact.history.push(HistoryEntry("Transferred", block.timestamp, msg.sender, string(abi.encodePacked("To: ", Strings.toHexString(to)))));


        emit ArtifactTransferred(from, to, artifactId);
    }

    /**
     * @dev Burns (destroys) an artifact. Callable by the artifact owner.
     * @param artifactId The ID of the artifact to burn.
     */
    function burnArtifact(uint256 artifactId) external onlyArtifactOwnerOrOperator(artifactId) whenNotPaused {
        Artifact storage artifact = artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactNotFound(); // Should be caught by modifier, but defensive

        address from = artifact.owner;

         // Check if the artifact is listed for sale and cancel the listing
        uint256 listingId = _itemToListingId[true][artifactId];
        if (listingId != 0 && listings[listingId].active) {
            _cancelListing(listingId); // Internal cancel
        }

        // Clear any delegations
        delete artifactUsageDelegation[artifactId];

        // Cannot delete from storage mapping directly in this way, but can mark as invalid/zero out fields.
        // For simplicity in this example, we'll just zero out the owner and potentially clear sensitive data.
        // In a real contract, you might use a boolean flag or a separate mapping for existence check.
        artifact.owner = address(0); // Marks as burned/non-existent

        // Clear trait data to save gas on future queries (optional)
        // artifact.traits.length = 0; // Clear dynamic array
        // artifact.history.length = 0; // Clear dynamic array


        emit ArtifactBurned(from, artifactId);
    }

    // =========================================================================================
    //                                  Discovery Mechanics
    // =========================================================================================

    /**
     * @dev Simulates attempting to discover items based on configured rates.
     *      Uses simple block hash/timestamp based "randomness". NOT for security-critical rolls.
     *      Callable by anyone (perhaps with a cost or cooldown in a real application).
     */
    function attemptDiscovery() external whenNotPaused {
        // Simple PRNG based on block data and sender address.
        // **WARNING:** This is NOT secure or unpredictable. Miners can influence it.
        // Use Chainlink VRF or similar for production randomness.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tx.origin, block.number)));
        uint256 roll = randomness % 10000; // Roll between 0 and 9999

        // Attempt general artifact discovery first (uses discoveryRates[0])
        DiscoveryRate storage generalRate = discoveryRates[0];
        if (generalRate.artifactChance > 0 && roll < generalRate.artifactChance) {
             // Found an artifact! Determine type based on rule/config (simplification: use artifactTypeId from rate)
             uint256 discoveredArtifactTypeId = generalRate.artifactTypeId; // Needs artifactTypeId added to DiscoveryRate struct/mapping
             // OR select from a pool of discoverable artifact types based on randomness
             // For simplicity, let's assume artifactTypeId is hardcoded or derived simply here.
             if (discoveredArtifactTypeId == 0 || discoveredArtifactTypeId >= _nextArtifactTypeId) {
                 // Fallback or no specific artifact configured for discovery[0], try a default
                 discoveredArtifactTypeId = 1; // Example: Default rare artifact type
             }
              if (discoveredArtifactTypeId < _nextArtifactTypeId) { // Ensure it's a valid type
                 // Mint/create the discovered artifact internally (no component cost)
                 uint256 newArtifactId = _nextArtifactId++;
                 Artifact storage newArtifact = artifacts[newArtifactId];
                 newArtifact.artifactId = newArtifactId;
                 newArtifact.artifactTypeId = discoveredArtifactTypeId; // Use discovered type
                 newArtifact.owner = msg.sender;
                 newArtifact.forgedTimestamp = block.timestamp; // Use forged timestamp for simplicity
                 newArtifact.evolutionLevel = 1;

                 // Initialize traits (could be special 'discovered' traits)
                  uint256 initialTrait1TypeId = 1; // Example: Power
                 if (initialTrait1TypeId < _nextTraitTypeId) {
                      newArtifact.traits.push(Trait(initialTrait1TypeId, 20, "", false, block.timestamp)); // Higher power for discovered?
                 }

                 // Add history entry
                 newArtifact.history.push(HistoryEntry("Discovered", block.timestamp, msg.sender, "Found through discovery mechanic"));

                 emit ItemDiscovered(msg.sender, false, newArtifactId, 0); // ItemId is ArtifactId for artifacts
                 emit ArtifactForged(newArtifactId, msg.sender, discoveredArtifactTypeId); // Also emit forge event for consistency
                 return; // Discovery successful
              }
        }

        // If no artifact found, attempt component discovery
        uint256 componentRoll = randomness / 10000; // Use a different part of the randomness
        uint256 cumulativeChance = 0;
        uint256 discoveredComponentTypeId = 0;
        uint256 discoveredComponentAmount = 0; // Amount found per discovery event

        // Iterate through registered component types to check discovery rates
        // (Inefficient for many types - better structure needed for large numbers)
        for (uint256 i = 1; i < _nextComponentTypeId; i++) {
             DiscoveryRate storage compRate = discoveryRates[i];
             if (compRate.componentChance > 0) {
                 cumulativeChance += compRate.componentChance;
                 if (componentRoll < cumulativeChance) {
                     // Found this component type!
                     discoveredComponentTypeId = i;
                     discoveredComponentAmount = 1; // Example: Always find 1 per event

                     // Mint the discovered component
                     if (componentTypes[discoveredComponentTypeId].maxSupply == 0 ||
                         componentTypes[discoveredComponentTypeId].mintedSupply + discoveredComponentAmount <= componentTypes[discoveredComponentTypeId].maxSupply) {
                         componentBalances[msg.sender][discoveredComponentTypeId] += discoveredComponentAmount;
                         componentTypes[discoveredComponentTypeId].mintedSupply += discoveredComponentAmount; // Update supply
                         emit ItemDiscovered(msg.sender, true, discoveredComponentTypeId, discoveredComponentAmount);
                         emit ComponentsMinted(msg.sender, discoveredComponentTypeId, discoveredComponentAmount); // Also emit mint event
                         return; // Discovery successful
                     }
                     // Else: Max supply reached, did not find it despite the roll
                 }
             }
        }

        // If no item found after all checks (roll was higher than cumulative chances or supply maxed), do nothing.
        // Can add an event for 'NoDiscovery' if needed.
    }

    // =========================================================================================
    //                                  Delegation System
    // =========================================================================================

    /**
     * @dev Delegates usage rights of an artifact to another address for a specific duration.
     *      Allows the delegatee to call functions restricted to owner/operator.
     *      Callable by the artifact owner.
     * @param delegatee The address to grant usage rights to.
     * @param artifactId The ID of the artifact.
     * @param duration The duration in seconds for which the delegation is valid.
     */
    function delegateArtifactUsage(address delegatee, uint256 artifactId, uint256 duration) external whenNotPaused {
         Artifact storage artifact = artifacts[artifactId];
         if (artifact.owner == address(0)) revert ArtifactNotFound();
         if (artifact.owner != msg.sender) revert NotItemOwnerOrOperator(); // Only owner can delegate

         uint256 expiryTimestamp = block.timestamp + duration;
         artifactUsageDelegation[artifactId][delegatee] = expiryTimestamp;
         emit UsageDelegated(artifactId, delegatee, expiryTimestamp);
    }

    /**
     * @dev Revokes an existing usage delegation for an artifact immediately.
     *      Callable by the artifact owner or the delegatee themselves.
     * @param delegatee The address whose delegation is being revoked.
     * @param artifactId The ID of the artifact.
     */
    function revokeArtifactUsageDelegation(address delegatee, uint256 artifactId) external whenNotPaused {
        Artifact storage artifact = artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactNotFound();

        // Either the owner or the delegatee can revoke
        bool isOwner = artifact.owner == msg.sender;
        bool isDelegatee = delegatee == msg.sender;

        if (!isOwner && !isDelegatee) revert NotItemOwnerOrOperator(); // Not owner or the delegatee

        if (artifactUsageDelegation[artifactId][delegatee] == 0 || artifactUsageDelegation[artifactId][delegatee] < block.timestamp) {
            revert DelegationNotFound(); // Or already expired
        }

        delete artifactUsageDelegation[artifactId][delegatee];
        emit UsageDelegationRevoked(artifactId, delegatee);
    }

    // =========================================================================================
    //                                Internal Marketplace
    // =========================================================================================

    /**
     * @dev Lists a component or artifact for sale within the contract.
     *      Transfers item ownership/amount to the contract's custody temporarily.
     *      Callable by the item owner.
     * @param isComponent True if listing a component, false if listing an artifact.
     * @param itemId The componentTypeId (if isComponent) or artifactId (if !isComponent).
     * @param amountOrArtifactId The amount (if isComponent) or the artifactId (if !isComponent).
     * @param price The price in Wei.
     */
    function listItemForSale(bool isComponent, uint256 itemId, uint256 amountOrArtifactId, uint256 price) external whenNotPaused {
        if (price == 0) revert ZeroAmount(); // Price must be > 0

        uint256 itemEffectiveId = isComponent ? itemId : amountOrArtifactId; // Use amountOrArtifactId for artifact ID consistency

        if (_itemToListingId[isComponent][itemEffectiveId] != 0) revert ItemAlreadyListed();

        if (isComponent) {
            uint256 amountToList = amountOrArtifactId;
            if (amountToList == 0) revert ZeroAmount();
            if (componentBalances[msg.sender][itemId] < amountToList) revert InsufficientComponents();

            // Transfer component to contract custody
            componentBalances[msg.sender][itemId] -= amountToList;
            componentBalances[address(this)][itemId] += amountToList;

        } else { // Listing an Artifact
            uint256 artifactIdToList = amountOrArtifactId; // It's the artifact ID
            Artifact storage artifact = artifacts[artifactIdToList];
            if (artifact.owner == address(0)) revert ArtifactNotFound();
            if (artifact.owner != msg.sender) revert NotItemOwnerOrOperator(); // Only owner can list

            // Transfer artifact ownership to contract custody
            // Temporarily change owner to address(this)
            // In a real system, might use a dedicated escrow struct/mapping
            // For simplicity, let's just update owner and rely on the listing being active
            artifact.owner = address(this);

             // Clear any delegations while listed
            delete artifactUsageDelegation[artifactIdToList];
        }

        uint256 newListingId = _nextListingId++;
        listings[newListingId] = Listing(
            newListingId,
            isComponent ? ItemTypeForListing.Component : ItemTypeForListing.Artifact,
            itemId, // ComponentType ID or Artifact Type ID (less useful here, keeping for context)
            amountOrArtifactId, // The actual item ID (Component Amount/Type ID or Artifact ID)
            price,
            msg.sender,
            true // Active
        );

        _itemToListingId[isComponent][itemEffectiveId] = newListingId; // Map item ID to listing ID

        emit ItemListedForSale(newListingId, isComponent, itemId, amountOrArtifactId, price, msg.sender);
    }

    /**
     * @dev Buys an item listed for sale by paying the price in ETH.
     *      Transfers item ownership/amount from contract custody to the buyer.
     * @param listingId The ID of the listing to buy.
     */
    function buyItem(uint256 listingId) external payable whenNotPaused {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotFound();
        if (msg.sender == listing.seller) revert CannotBuyOwnItem();
        if (msg.value < listing.price) revert InsufficientPayment();

        // Mark listing as inactive first to prevent re-entrancy issues if transfers trigger callbacks
        listing.active = false;

        uint256 itemEffectiveId = listing.itemType == ItemTypeForListing.Component ? listing.itemId : listing.amountOrArtifactId;
        delete _itemToListingId[listing.itemType == ItemTypeForListing.Component][itemEffectiveId]; // Remove mapping

        if (listing.itemType == ItemTypeForListing.Component) {
            // Transfer components from contract custody to buyer
            uint256 amountToBuy = listing.amountOrArtifactId; // Amount for component
            uint256 componentTypeId = listing.itemId; // ItemId is the type ID for components

            // Check contract balance (should be sufficient if listing was correct)
             if (componentBalances[address(this)][componentTypeId] < amountToBuy) revert ItemNotFound(); // Should not happen if listed correctly

            componentBalances[address(this)][componentTypeId] -= amountToBuy;
            componentBalances[msg.sender][componentTypeId] += amountToBuy;
            emit ComponentsTransferred(address(this), msg.sender, componentTypeId, amountToBuy);

        } else { // Buying an Artifact
            uint256 artifactIdToBuy = listing.amountOrArtifactId; // ArtifactId for artifact
            Artifact storage artifact = artifacts[artifactIdToBuy];
            // Check contract ownership (should be owned by this contract if listed correctly)
            if (artifact.owner != address(this)) revert ItemNotFound(); // Should not happen if listed correctly

            // Transfer artifact ownership from contract custody to buyer
            artifact.owner = msg.sender;
             // Add history entry for the sale
             artifact.history.push(HistoryEntry("Sold", block.timestamp, address(this), string(abi.encodePacked("Sold to ", Strings.toHexString(msg.sender), " for ", Strings.toString(listing.price)))));
            emit ArtifactTransferred(address(this), msg.sender, artifactIdToBuy);
        }

        // Transfer payment to seller (or add to withdrawable balance)
        // Adding to withdrawable balance is safer than direct transfer in buy function
        fundsAvailableForWithdrawal[listing.seller] += listing.price;

        // Refund excess payment if any
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }

        emit ItemSold(listingId, itemEffectiveId, listing.seller, msg.sender, listing.price);
    }

    /**
     * @dev Cancels an active sale listing. Refunds item to the seller.
     *      Callable by the seller.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) external whenNotPaused {
        _cancelListing(listingId);
    }

    /**
     * @dev Internal function to cancel a listing.
     */
    function _cancelListing(uint256 listingId) internal {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotFound();
        if (msg.sender != listing.seller) revert NotListingSeller();

        // Mark listing as inactive first
        listing.active = false;

         uint256 itemEffectiveId = listing.itemType == ItemTypeForListing.Component ? listing.itemId : listing.amountOrArtifactId;
         delete _itemToListingId[listing.itemType == ItemTypeForListing.Component][itemEffectiveId]; // Remove mapping

        if (listing.itemType == ItemTypeForListing.Component) {
            // Transfer components from contract custody back to seller
             uint256 amountToReturn = listing.amountOrArtifactId; // Amount for component
             uint256 componentTypeId = listing.itemId; // ItemId is the type ID for components

             // Check contract balance (should be sufficient)
             if (componentBalances[address(this)][componentTypeId] < amountToReturn) revert ItemNotFound(); // Should not happen

            componentBalances[address(this)][componentTypeId] -= amountToReturn;
            componentBalances[listing.seller][componentTypeId] += amountToReturn;
             emit ComponentsTransferred(address(this), listing.seller, componentTypeId, amountToReturn);

        } else { // Cancelling Artifact listing
            uint256 artifactIdToReturn = listing.amountOrArtifactId; // ArtifactId for artifact
             Artifact storage artifact = artifacts[artifactIdToReturn];
             // Check contract ownership
             if (artifact.owner != address(this)) revert ItemNotFound(); // Should not happen

            // Transfer artifact ownership from contract custody back to seller
            artifact.owner = listing.seller;
             // Add history entry for the cancellation
             artifact.history.push(HistoryEntry("Listing Cancelled", block.timestamp, address(this), string(abi.encodePacked("Listing ", Strings.toString(listingId), " cancelled"))));
             emit ArtifactTransferred(address(this), listing.seller, artifactIdToReturn);
        }

        emit ListingCancelled(listingId);
    }

    /**
     * @dev Allows a seller to withdraw the funds accumulated from sales.
     *      Callable by the seller.
     */
    function withdrawFunds() external whenNotPaused {
        uint256 amount = fundsAvailableForWithdrawal[msg.sender];
        if (amount == 0) revert ZeroAmount();

        fundsAvailableForWithdrawal[msg.sender] = 0; // Zero out balance BEFORE transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // If transfer fails, potentially revert or log and leave balance for later withdrawal
            // Reverting is safer to prevent loss of funds in the contract
            revert InsufficientPayment(); // Or a specific withdrawal error
        }

        emit FundsWithdrawn(msg.sender, amount);
    }

    // =========================================================================================
    //                                  Query Functions (View)
    // =========================================================================================

     /**
     * @dev Returns the balance of a specific component type for an owner.
     * @param owner The address to check.
     * @param componentTypeId The type of component.
     * @return The amount of the component type owned by the address.
     */
    function getComponentBalance(address owner, uint256 componentTypeId) external view returns (uint256) {
        return componentBalances[owner][componentTypeId];
    }

     /**
     * @dev Returns details of a component type.
     * @param componentTypeId The type of component.
     * @return name, baseMetadataURI, maxSupply, mintedSupply
     */
    function getComponentDetails(uint256 componentTypeId) external view returns (string memory name, string memory baseMetadataURI, uint256 maxSupply, uint256 mintedSupply) {
         ComponentType storage cType = componentTypes[componentTypeId];
         if (cType.name == "") revert ComponentTypeNotFound();
         return (cType.name, cType.baseMetadataURI, cType.maxSupply, cType.mintedSupply);
     }

    /**
     * @dev Returns detailed information about an artifact.
     * @param artifactId The ID of the artifact.
     * @return artifactId, artifactTypeId, owner, forgedTimestamp, evolutionLevel
     */
    function getArtifactDetails(uint256 artifactId) external view returns (
        uint256 id,
        uint256 artifactTypeId,
        address owner,
        uint256 forgedTimestamp,
        uint256 evolutionLevel
    ) {
        Artifact storage artifact = artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactNotFound(); // Check if exists/not burned
        return (
            artifact.artifactId,
            artifact.artifactTypeId,
            artifact.owner,
            artifact.forgedTimestamp,
            artifact.evolutionLevel
        );
    }

    /**
     * @dev Returns the dynamic traits of an artifact.
     * @param artifactId The ID of the artifact.
     * @return An array of Trait structs.
     */
    function getArtifactTraits(uint256 artifactId) external view returns (Trait[] memory) {
         Artifact storage artifact = artifacts[artifactId];
         if (artifact.owner == address(0)) revert ArtifactNotFound();
         return artifact.traits; // Return a copy of the dynamic array
    }

    /**
     * @dev Returns the history log of an artifact.
     * @param artifactId The ID of the artifact.
     * @return An array of HistoryEntry structs.
     */
    function getArtifactHistory(uint256 artifactId) external view returns (HistoryEntry[] memory) {
         Artifact storage artifact = artifacts[artifactId];
         if (artifact.owner == address(0)) revert ArtifactNotFound();
         return artifact.history; // Return a copy of the dynamic array
    }

     /**
     * @dev Returns details of an active listing.
     * @param listingId The ID of the listing.
     * @return listingId, itemType, itemId, amountOrArtifactId, price, seller, active
     */
    function getItemListing(uint256 listingId) external view returns (
        uint256 id,
        ItemTypeForListing itemType,
        uint256 itemId, // ComponentTypeId or Artifact Type ID (conceptually)
        uint256 amountOrArtifactId, // Actual item ID / amount
        uint256 price,
        address seller,
        bool active
    ) {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotFound(); // Only return active listings
        return (
            listing.listingId,
            listing.itemType,
            listing.itemId,
            listing.amountOrArtifactId,
            listing.price,
            listing.seller,
            listing.active
        );
    }

     /**
     * @dev Checks if an address is currently delegated to use an artifact and the delegation is active.
     * @param potentialOperator The address to check.
     * @param artifactId The ID of the artifact.
     * @return True if the address is a valid operator for the artifact, false otherwise.
     */
    function isArtifactOperator(address potentialOperator, uint256 artifactId) external view returns (bool) {
         Artifact storage artifact = artifacts[artifactId];
         if (artifact.owner == address(0)) return false; // Artifact must exist

         return artifactUsageDelegation[artifactId][potentialOperator] > block.timestamp;
     }

     /**
      * @dev Checks if an address owns a specific artifact.
      * @param owner The address to check.
      * @param artifactId The ID of the artifact.
      * @return True if the address is the current owner, false otherwise.
      */
     function isArtifactOwner(address owner, uint256 artifactId) external view returns (bool) {
         Artifact storage artifact = artifacts[artifactId];
         if (artifact.owner == address(0)) return false; // Artifact must exist

         return artifact.owner == owner;
     }

      /**
       * @dev Checks if an address owns at least a certain amount of a specific component type.
       * @param owner The address to check.
       * @param componentTypeId The type of component.
       * @param amount The minimum amount required.
       * @return True if the address owns at least the specified amount, false otherwise.
       */
     function isComponentOwner(address owner, uint256 componentTypeId, uint256 amount) external view returns (bool) {
         return componentBalances[owner][componentTypeId] >= amount;
     }

     /**
      * @dev Gets the timestamp when delegation for a specific artifact and delegatee expires.
      *      Returns 0 if no active delegation exists.
      * @param artifactId The ID of the artifact.
      * @param delegatee The address to check.
      * @return The expiry timestamp, or 0 if no active delegation.
      */
     function getArtifactDelegationExpiry(uint256 artifactId, address delegatee) external view returns (uint256) {
        uint256 expiry = artifactUsageDelegation[artifactId][delegatee];
        if (expiry > block.timestamp) {
            return expiry;
        }
        return 0; // Return 0 for expired or non-existent delegations
     }
}

// Helper library for converting uint to string (commonly used)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

     function toHexString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; ++i) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
```