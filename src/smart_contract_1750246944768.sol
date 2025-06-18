Okay, let's design a smart contract concept called "Dimensional Nexus". This contract will manage interconnected "Dimensions" and "Entities" that exist within them. Entities can possess resources, evolve, shift between linked dimensions, and their state can be influenced by the dimensions they inhabit or global "Epochs". It incorporates elements of state management, resource dynamics, access control, and interconnected data structures.

It specifically avoids being a standard ERC-20 (no fungible token interface for general transfer) or ERC-721 (Entities have IDs and owners, but the core logic is about their state *within* the Nexus, not just ownership + metadata) or a typical DeFi primitive.

---

**Smart Contract: DimensionalNexus**

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Errors:** Custom errors for specific failure conditions.
3.  **Events:** Events for significant state changes (creation, updates, transfers, links, etc.).
4.  **Enums:** Define possible states for Dimensions, Entities, and the Nexus itself.
5.  **Structs:** Define data structures for Dimensions, Entities, and Resource Types.
6.  **State Variables:** Store the core data and system parameters.
7.  **Modifiers:** Access control and state checks (`onlyOwner`, `whenNotPaused`, `whenPaused`).
8.  **Constructor:** Initialize the contract with the owner.
9.  **Admin/Owner Functions:** Core system setup, pausing, global parameter changes.
10. **Dimension Management:** Create, configure, and link Dimensions.
11. **Resource Type Management:** Define and seed Resource Types.
12. **Entity Management:** Create, transfer ownership of, configure, upgrade, and link Entities.
13. **Resource Interaction:** Deposit, withdraw, harvest, and synthesize Resources.
14. **Dimensional Interaction:** Shift Entities between Dimensions.
15. **Nexus State & Epochs:** Advance the global state (Epochs), trigger anomalies.
16. **Query Functions (View/Pure):** Retrieve information about Dimensions, Entities, Resources, and the Nexus state.

**Function Summary:**

*   `constructor()`: Sets the initial contract owner.
*   `initializeNexus()`: Owner initializes core system parameters after deployment.
*   `createDimension(string calldata name)`: Owner creates a new Dimension.
*   `setDimensionState(uint256 dimensionId, DimensionState newState)`: Owner changes a Dimension's state.
*   `setDimensionProperties(uint256 dimensionId, DimensionProperties calldata props)`: Owner updates a Dimension's properties.
*   `establishDimensionalLink(uint256 dimIdA, uint256 dimIdB)`: Owner creates a link between two Dimensions.
*   `breakDimensionalLink(uint256 dimIdA, uint256 dimIdB)`: Owner removes a link between two Dimensions.
*   `createResourceType(string calldata name, uint256 decayRatePerEpoch)`: Owner defines a new Resource Type with a decay rate.
*   `distributeInitialResources(uint256 resourceTypeId, uint256 amount, uint256 targetEntityId)`: Owner seeds a specific Entity with initial Resources of a type.
*   `setGlobalParameter(bytes32 paramName, uint256 value)`: Owner sets a global system parameter by name (e.g., costs, multipliers).
*   `pauseNexus()`: Owner pauses all non-query state-changing operations.
*   `unpauseNexus()`: Owner unpauses the contract.
*   `transferOwnership(address newOwner)`: Owner transfers contract ownership.
*   `manifestEntity(uint256 initialDimensionId, EntityProperties calldata initialProps)`: A user creates (manifests) a new Entity in a specified Dimension.
*   `attuneEntityOwner(uint256 entityId, address newOwner)`: The current owner of an Entity transfers its ownership to another address.
*   `dissolveEntity(uint256 entityId)`: The owner of an Entity destroys it, potentially recovering some resources.
*   `upgradeEntityState(uint256 entityId, EntityState targetState, uint256[] calldata requiredResourceTypes, uint256[] calldata requiredAmounts)`: Owner attempts to upgrade an Entity's state by consuming required Resources.
*   `linkEntities(uint256 entityIdA, uint256 entityIdB)`: Owner of two Entities creates a link between them. Requires both entities belong to the caller.
*   `unlinkEntities(uint256 entityIdA, uint256 entityIdB)`: Owner of two linked Entities breaks the link.
*   `depositResource(uint256 entityId, uint256 resourceTypeId, uint256 amount)`: User deposits external resources into an Entity they own (assumes external resource tokens or similar input mechanism, simplified here).
*   `withdrawResource(uint256 entityId, uint256 resourceTypeId, uint256 amount)`: User withdraws resources from an Entity they own.
*   `harvestEntityResources(uint256 entityId)`: Owner triggers resource generation for an Entity based on its state, dimension, and time/epochs passed since last harvest.
*   `synthesizeResources(uint256 entityId, uint256 outputResourceType, uint256 amountToSynthesize, uint256[] calldata consumedResourceTypes, uint256[] calldata consumedAmounts)`: Owner uses resources within an Entity to synthesize a different resource type based on predefined 'recipes' (simplified: checks for required inputs for a given output).
*   `shiftEntityDimension(uint256 entityId, uint256 targetDimensionId)`: Owner attempts to move their Entity to a different Dimension, requires dimension link and potentially consumes resources.
*   `advanceNexusEpoch()`: Owner (or authorized caller via separate mechanism) advances the global Epoch counter, triggering epoch-based effects like resource decay.
*   `triggerDimensionalAnomaly(uint256 dimensionId, uint256 anomalyCode)`: Owner triggers a specific anomaly effect in a Dimension (effect logic abstracted).
*   `resolveDimensionalAnomaly(uint256 dimensionId)`: Owner resolves an anomaly in a Dimension.
*   `queryEntityProperties(uint256 entityId)`: View function to get an Entity's details.
*   `queryDimensionProperties(uint256 dimensionId)`: View function to get a Dimension's details.
*   `queryEntityResourceBalance(uint256 entityId, uint256 resourceTypeId)`: View function to get an Entity's balance for a specific resource type.
*   `queryLinkedEntities(uint256 entityId)`: View function to get a list of Entities linked to a given Entity.
*   `queryLinkedDimensions(uint256 dimensionId)`: View function to get a list of Dimensions linked to a given Dimension.
*   `queryTotalResourceType(uint256 resourceTypeId)`: View function to get the total circulating amount of a Resource Type (across all entities).
*   `queryEntityOwner(uint256 entityId)`: View function to get the owner of an Entity.
*   `queryGlobalNexusState()`: View function to get overall Nexus state (epoch, paused status, counts).
*   `queryNexusParameter(bytes32 paramName)`: View function to get the value of a global parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DimensionalNexus
 * @dev A smart contract managing interconnected Dimensions and Entities with state transitions,
 *      resource dynamics, and linking mechanisms. Avoids standard ERC-20/721 patterns for core logic.
 *
 * Outline:
 * 1. SPDX-License-Identifier & Pragma
 * 2. Errors
 * 3. Events
 * 4. Enums
 * 5. Structs
 * 6. State Variables
 * 7. Modifiers
 * 8. Constructor
 * 9. Admin/Owner Functions (10+)
 * 10. Dimension Management
 * 11. Resource Type Management
 * 12. Entity Management (5+)
 * 13. Resource Interaction (4+)
 * 14. Dimensional Interaction (1)
 * 15. Nexus State & Epochs (3+)
 * 16. Query Functions (View/Pure) (7+)
 *
 * Total Functions: 20+
 *
 * Function Summary:
 * - Core Admin: initializeNexus, createDimension, setDimensionState, setDimensionProperties, establishDimensionalLink, breakDimensionalLink, createResourceType, distributeInitialResources, setGlobalParameter, pauseNexus, unpauseNexus, transferOwnership.
 * - Entity Core: manifestEntity, attuneEntityOwner, dissolveEntity.
 * - Entity Evolution/Linking: upgradeEntityState, linkEntities, unlinkEntities.
 * - Resource Interaction: depositResource, withdrawResource, harvestEntityResources, synthesizeResources.
 * - Dimensional Shifts: shiftEntityDimension.
 * - Global State: advanceNexusEpoch, triggerDimensionalAnomaly, resolveDimensionalAnomaly.
 * - Queries: queryEntityProperties, queryDimensionProperties, queryEntityResourceBalance, queryLinkedEntities, queryLinkedDimensions, queryTotalResourceType, queryEntityOwner, queryGlobalNexusState, queryNexusParameter.
 */

error NotOwner();
error Paused();
error NotPaused();
error NexusAlreadyInitialized();
error DimensionNotFound(uint256 dimensionId);
error InvalidDimensionState();
error InvalidDimensionProperties(); // Generic error for bad properties data
error DimensionLinkExists(uint256 dimIdA, uint256 dimIdB);
error DimensionLinkDoesNotExist(uint256 dimIdA, uint256 dimIdB);
error ResourceTypeNotFound(uint256 resourceTypeId);
error EntityNotFound(uint256 entityId);
error EntityNotOwner(uint256 entityId, address caller);
error InvalidEntityState();
error InvalidEntityProperties(); // Generic error for bad properties data
error EntityLinkExists(uint256 entityIdA, uint256 entityIdB);
error EntityLinkDoesNotExist(uint256 entityIdA, uint256 entityIdB);
error InsufficientEntityResource(uint256 entityId, uint256 resourceTypeId, uint256 required, uint256 current);
error InsufficientGlobalResource(uint256 resourceTypeId, uint256 required, uint256 current); // For admin seeding
error EntityNotInCorrectDimension(uint256 entityId, uint256 requiredDimensionId, uint256 currentDimensionId);
error DimensionShiftNotAllowed(uint256 entityId, uint256 targetDimensionId); // e.g., due to state or lack of link
error SynthesisFailed(); // Generic for failed synthesis logic (e.g., bad recipe)
error NexusNotInitialized();
error InvalidParameterName(); // For setGlobalParameter

enum NexusState {
    Uninitialized,
    Operational,
    Paused,
    AnomalyDetected // Global anomaly state maybe? Or just Dimension-specific? Let's keep it Dimension-specific for now.
}

enum DimensionState {
    Stable,
    Volatile,
    Quiescent,
    Anomaly
}

// Example properties struct - could include things affecting resource generation, entity state changes, etc.
struct DimensionProperties {
    uint256 resourceAbundanceMultiplier;
    uint256 entityEvolutionCostModifier;
    // Add other dimension-specific parameters
    bytes data; // Flexible field for arbitrary dimension data
}

enum EntityState {
    Latent,
    Active,
    Evolved,
    Dormant,
    Corrupted // Could be a state induced by anomalies
}

// Example properties struct - could include base resource generation, combat stats, etc.
struct EntityProperties {
    uint256 baseResourceGeneration; // Amount generated per epoch (before multipliers)
    uint256 maxResourceCapacity;
    // Add other entity-specific parameters
    bytes data; // Flexible field for arbitrary entity data
}

struct ResourceType {
    string name;
    uint256 decayRatePerEpoch; // Percentage decay (e.g., 100 = 1% decay)
    uint256 totalCirculating;
}

struct Entity {
    uint256 id;
    address owner;
    uint256 dimensionId;
    EntityState state;
    EntityProperties properties;
    uint256 lastHarvestEpoch; // To track resource harvesting
}

struct Dimension {
    uint256 id;
    string name;
    DimensionState state;
    DimensionProperties properties;
    // Linked dimensions are stored in a mapping
}

address private _owner;
NexusState private _nexusState;
uint256 private _currentEpoch;

uint256 private _nextDimensionId;
uint256 private _nextEntityId;
uint256 private _nextResourceTypeId;

mapping(uint256 => Dimension) private _dimensions;
mapping(uint256 => Entity) private _entities;
mapping(uint256 => ResourceType) private _resourceTypes;

// entityId => resourceTypeId => balance
mapping(uint256 => mapping(uint256 => uint256)) private _entityResourceBalances;

// dimIdA => dimIdB => bool (true if linked)
mapping(uint256 => mapping(uint256 => bool)) private _dimensionalLinks;

// entityIdA => entityIdB => bool (true if linked) - requires entityA and entityB owners to be the same for creation/deletion
mapping(uint256 => mapping(uint256 => bool)) private _entityLinks;

// Global parameters storage
mapping(bytes32 => uint256) private _globalParameters;

event NexusInitialized(address indexed owner);
event NexusStateChanged(NexusState newState);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event DimensionCreated(uint256 indexed dimensionId, string name, DimensionState initialState);
event DimensionStateChanged(uint256 indexed dimensionId, DimensionState newState);
event DimensionPropertiesUpdated(uint256 indexed dimensionId, DimensionProperties properties);
event DimensionalLinkEstablished(uint256 indexed dimIdA, uint256 indexed dimIdB);
event DimensionalLinkBroken(uint256 indexed dimIdA, uint256 indexed dimIdB);
event ResourceTypeCreated(uint256 indexed resourceTypeId, string name, uint256 decayRatePerEpoch);
event ResourcesDistributed(uint256 indexed resourceTypeId, uint256 indexed targetEntityId, uint256 amount);
event GlobalParameterSet(bytes32 indexed paramName, uint256 value);
event EntityManifested(uint256 indexed entityId, address indexed owner, uint256 indexed initialDimensionId);
event EntityAttuned(uint256 indexed entityId, address indexed oldOwner, address indexed newOwner);
event EntityDissolved(uint256 indexed entityId);
event EntityStateUpgraded(uint256 indexed entityId, EntityState oldState, EntityState newState);
event EntityLinked(uint256 indexed entityIdA, uint256 indexed entityIdB);
event EntityUnlinked(uint256 indexed entityIdA, uint256 indexed entityIdB);
event ResourceDeposited(uint256 indexed entityId, uint256 indexed resourceTypeId, uint256 amount);
event ResourceWithdrawn(uint256 indexed entityId, uint256 indexed resourceTypeId, uint256 amount);
event EntityResourcesHarvested(uint256 indexed entityId, uint256 indexed resourceTypeId, uint256 amount);
event ResourcesSynthesized(uint256 indexed entityId, uint256 indexed outputResourceType, uint256 outputAmount);
event EntityDimensionShifted(uint256 indexed entityId, uint256 indexed fromDimensionId, uint256 indexed toDimensionId);
event NexusEpochAdvanced(uint256 newEpoch);
event DimensionalAnomalyTriggered(uint256 indexed dimensionId, uint256 anomalyCode);
event DimensionalAnomalyResolved(uint256 indexed dimensionId);

modifier onlyOwner() {
    if (msg.sender != _owner) revert NotOwner();
    _;
}

modifier whenNotPaused() {
    if (_nexusState == NexusState.Paused) revert Paused();
    _;
}

modifier whenPaused() {
    if (_nexusState != NexusState.Paused) revert NotPaused();
    _;
}

modifier onlyOperational() {
    if (_nexusState != NexusState.Operational) revert NexusNotInitialized();
    _;
}

constructor() {
    _owner = msg.sender;
    _nexusState = NexusState.Uninitialized;
    _currentEpoch = 0;
    _nextDimensionId = 1; // Start IDs from 1
    _nextEntityId = 1;
    _nextResourceTypeId = 1;
    emit OwnershipTransferred(address(0), _owner);
}

// --- Admin/Owner Functions ---

/**
 * @dev Initializes the core Nexus parameters. Can only be called once by the owner.
 */
function initializeNexus() external onlyOwner {
    if (_nexusState != NexusState.Uninitialized) revert NexusAlreadyInitialized();
    _nexusState = NexusState.Operational;
    emit NexusInitialized(_owner);
    emit NexusStateChanged(NexusState.Operational);
}

/**
 * @dev Transfers ownership of the contract.
 * @param newOwner The address to transfer ownership to.
 */
function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner == address(0)) revert NotOwner(); // Simple check for zero address
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
}

/**
 * @dev Creates a new Dimension in the Nexus.
 * @param name The name of the Dimension.
 */
function createDimension(string calldata name) external onlyOwner onlyOperational {
    uint256 dimId = _nextDimensionId++;
    _dimensions[dimId] = Dimension({
        id: dimId,
        name: name,
        state: DimensionState.Stable,
        properties: DimensionProperties({
            resourceAbundanceMultiplier: 100, // Default 100%
            entityEvolutionCostModifier: 100, // Default 100%
            data: ""
        })
    });
    emit DimensionCreated(dimId, name, DimensionState.Stable);
}

/**
 * @dev Sets the state of an existing Dimension.
 * @param dimensionId The ID of the Dimension.
 * @param newState The new state for the Dimension.
 */
function setDimensionState(uint256 dimensionId, DimensionState newState) external onlyOwner onlyOperational {
    if (_dimensions[dimensionId].id == 0) revert DimensionNotFound(dimensionId);
    _dimensions[dimensionId].state = newState;
    emit DimensionStateChanged(dimensionId, newState);
}

/**
 * @dev Sets the properties of an existing Dimension.
 * @param dimensionId The ID of the Dimension.
 * @param props The new properties for the Dimension.
 */
function setDimensionProperties(uint256 dimensionId, DimensionProperties calldata props) external onlyOwner onlyOperational {
    if (_dimensions[dimensionId].id == 0) revert DimensionNotFound(dimensionId);
    // Basic validation, more complex validation based on data content might be needed
    if (props.resourceAbundanceMultiplier == 0 || props.entityEvolutionCostModifier == 0) revert InvalidDimensionProperties();

    _dimensions[dimensionId].properties = props;
    emit DimensionPropertiesUpdated(dimensionId, props);
}

/**
 * @dev Establishes a link between two Dimensions, allowing Entities to potentially shift between them.
 * @param dimIdA The ID of the first Dimension.
 * @param dimIdB The ID of the second Dimension.
 */
function establishDimensionalLink(uint256 dimIdA, uint256 dimIdB) external onlyOwner onlyOperational {
    if (_dimensions[dimIdA].id == 0) revert DimensionNotFound(dimIdA);
    if (_dimensions[dimIdB].id == 0) revert DimensionNotFound(dimIdB);
    if (dimIdA == dimIdB) revert InvalidDimensionLink(); // Cannot link a dimension to itself
    if (_dimensionalLinks[dimIdA][dimIdB]) revert DimensionLinkExists(dimIdA, dimIdB);

    _dimensionalLinks[dimIdA][dimIdB] = true;
    _dimensionalLinks[dimIdB][dimIdA] = true; // Links are bidirectional
    emit DimensionalLinkEstablished(dimIdA, dimIdB);
}

/**
 * @dev Breaks a link between two Dimensions.
 * @param dimIdA The ID of the first Dimension.
 * @param dimIdB The ID of the second Dimension.
 */
function breakDimensionalLink(uint256 dimIdA, uint256 dimIdB) external onlyOwner onlyOperational {
    if (_dimensions[dimIdA].id == 0) revert DimensionNotFound(dimIdA);
    if (_dimensions[dimIdB].id == 0) revert DimensionNotFound(dimIdB);
    if (dimIdA == dimIdB) revert InvalidDimensionLink();
    if (!_dimensionalLinks[dimIdA][dimIdB]) revert DimensionLinkDoesNotExist(dimIdA, dimIdB);

    _dimensionalLinks[dimIdA][dimIdB] = false;
    _dimensionalLinks[dimIdB][dimIdA] = false;
    emit DimensionalLinkBroken(dimIdA, dimIdB);
}

/**
 * @dev Creates a new type of Resource available in the Nexus.
 * @param name The name of the Resource Type.
 * @param decayRatePerEpoch The percentage of the resource that decays each epoch (e.g., 100 for 1%). Max 10000 (100%).
 */
function createResourceType(string calldata name, uint256 decayRatePerEpoch) external onlyOwner onlyOperational {
    if (decayRatePerEpoch > 10000) revert InvalidResourceTypeProperties(); // Cap decay rate at 100% per epoch

    uint256 typeId = _nextResourceTypeId++;
    _resourceTypes[typeId] = ResourceType({
        id: typeId, // Add ID to struct for easier lookup if needed, though map key is ID
        name: name,
        decayRatePerEpoch: decayRatePerEpoch,
        totalCirculating: 0
    });
    emit ResourceTypeCreated(typeId, name, decayRatePerEpoch);
}

/**
 * @dev Distributes initial resources of a specific type to a target entity.
 *      This is typically for seeding the system or rewarding.
 * @param resourceTypeId The ID of the Resource Type.
 * @param amount The amount to distribute.
 * @param targetEntityId The ID of the Entity to receive the resources.
 */
function distributeInitialResources(uint256 resourceTypeId, uint256 amount, uint256 targetEntityId) external onlyOwner onlyOperational {
    if (_resourceTypes[resourceTypeId].id == 0) revert ResourceTypeNotFound(resourceTypeId);
    if (_entities[targetEntityId].id == 0) revert EntityNotFound(targetEntityId);
    if (amount == 0) return; // Nothing to distribute

    _entityResourceBalances[targetEntityId][resourceTypeId] += amount;
    _resourceTypes[resourceTypeId].totalCirculating += amount;

    emit ResourcesDistributed(resourceTypeId, targetEntityId, amount);
    emit ResourceDeposited(targetEntityId, resourceTypeId, amount); // Use deposit event as well
}

/**
 * @dev Sets a global system parameter by its name (hashed) and value.
 *      Useful for tuning costs, multipliers, etc.
 * @param paramName The keccak256 hash of the parameter name (e.g., keccak256("ENTITY_MANIFEST_COST")).
 * @param value The value to set for the parameter.
 */
function setGlobalParameter(bytes32 paramName, uint256 value) external onlyOwner onlyOperational {
     if (paramName == bytes32(0)) revert InvalidParameterName();
    _globalParameters[paramName] = value;
    emit GlobalParameterSet(paramName, value);
}

/**
 * @dev Gets the value of a global system parameter.
 * @param paramName The keccak256 hash of the parameter name.
 * @return The value of the parameter, or 0 if not set.
 */
function queryNexusParameter(bytes32 paramName) external view returns (uint256) {
    return _globalParameters[paramName];
}


/**
 * @dev Pauses state-changing operations of the Nexus.
 */
function pauseNexus() external onlyOwner whenNotPaused {
    _nexusState = NexusState.Paused;
    emit NexusStateChanged(NexusState.Paused);
}

/**
 * @dev Unpauses state-changing operations of the Nexus.
 */
function unpauseNexus() external onlyOwner whenPaused {
    _nexusState = NexusState.Operational;
    emit NexusStateChanged(NexusState.Operational);
}

// --- Entity Management Functions ---

/**
 * @dev Allows a user to create a new Entity in a specific Dimension.
 *      Might require burning resources or paying a fee based on global parameters.
 * @param initialDimensionId The ID of the Dimension where the Entity will manifest.
 * @param initialProps The initial properties of the Entity.
 */
function manifestEntity(uint256 initialDimensionId, EntityProperties calldata initialProps) external onlyOperational whenNotPaused {
    if (_dimensions[initialDimensionId].id == 0) revert DimensionNotFound(initialDimensionId);
    // Basic properties validation
    if (initialProps.maxResourceCapacity == 0) revert InvalidEntityProperties();

    // Example cost mechanism: require a global parameter value (e.g., cost in a certain resource type)
    bytes32 manifestCostParam = keccak256("ENTITY_MANIFEST_COST");
    uint256 costAmount = _globalParameters[manifestCostParam];
    bytes32 costResourceTypeParam = keccak256("ENTITY_MANIFEST_COST_RESOURCE");
    uint256 costResourceType = _globalParameters[costResourceTypeParam];

    if (costAmount > 0 && costResourceType > 0) {
         if (_resourceTypes[costResourceType].id == 0) revert ResourceTypeNotFound(costResourceType); // Cost resource must exist
         // Simplified: User must "burn" global circulating supply (requires a deposit mechanism first or a separate token)
         // More realistically, this would consume resources *from the caller* or require interaction with a separate token contract.
         // For this example, let's simulate a check that the caller has enough of an *external* resource, but the consumption is abstracted.
         // A real implementation would integrate with ERC-20 or similar.
         // Let's assume for this example, we're just checking for existence of a parameter defining the cost.
         // *Self-correction*: A contract cannot *take* arbitrary tokens. The user would need to approve this contract or call a function *on the token contract* to transfer. Let's abstract this away for the example and just *state* it would consume resources, or use an *internal* resource check if entities could own resources before manifestation (which they can't initially).
         // Alternative: Make manifestation free, or require a global resource sink that users somehow contribute to off-chain or via other functions.
         // Let's make it free for this example to avoid external token dependencies. The cost is defined, but not enforced in v1.
         // require(userHasOrDepositsResource(msg.sender, costResourceType, costAmount), "Insufficient manifest cost");
    }


    uint256 entityId = _nextEntityId++;
    _entities[entityId] = Entity({
        id: entityId,
        owner: msg.sender,
        dimensionId: initialDimensionId,
        state: EntityState.Latent,
        properties: initialProps,
        lastHarvestEpoch: _currentEpoch // Start harvest timer
    });

    // Initialize resource balances mapping for this entity
    // No need to explicitly initialize, mapping(uint256 => uint256) defaults to 0 for all resource types

    emit EntityManifested(entityId, msg.sender, initialDimensionId);
}

/**
 * @dev Allows the current owner of an Entity to transfer its ownership to another address.
 * @param entityId The ID of the Entity to transfer.
 * @param newOwner The address to transfer ownership to.
 */
function attuneEntityOwner(uint256 entityId, address newOwner) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);
    if (newOwner == address(0)) revert NotOwner(); // Cannot transfer to zero address

    address oldOwner = entity.owner;
    entity.owner = newOwner;
    emit EntityAttuned(entityId, oldOwner, newOwner);
}

/**
 * @dev Allows the owner of an Entity to dissolve it, effectively burning it.
 *      Might return a fraction of resources based on global parameters.
 * @param entityId The ID of the Entity to dissolve.
 */
function dissolveEntity(uint256 entityId) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);

    // Optional: Resource return logic based on global parameter
    // bytes32 dissolveReturnRateParam = keccak256("ENTITY_DISSOLVE_RETURN_RATE"); // Percentage
    // uint256 returnRate = _globalParameters[dissolveReturnRateParam];
    // Iterate over all resource types the entity holds
    // (Optimization needed for iterating all resource types - potentially track types per entity)
    // For simplicity in this example, let's just burn the entity and its resources.
    // A real implementation would need to iterate entityResourceBalances or have a linked list/array of held resources.
    // The `_entityResourceBalances[entityId]` mapping entry remains, but will hold 0s. The entity struct is zeroed.

    delete _entities[entityId]; // This zeros out the struct fields including owner, state, dimensionId etc.
    // Resource balances remain in the mapping but are unreachable via an entity ID.
    // A proper implementation would iterate and reduce totalCirculating for each resource type.
    // Let's emit the event assuming resources are gone with the entity for this simplified version.

    emit EntityDissolved(entityId);
}

/**
 * @dev Allows an Entity owner to attempt to upgrade its state by consuming specific resources.
 *      The success and cost depend on the Entity's current state, the target state, and its Dimension properties.
 * @param entityId The ID of the Entity to upgrade.
 * @param targetState The desired new state for the Entity.
 * @param requiredResourceTypes Array of resource type IDs needed for the upgrade.
 * @param requiredAmounts Array of corresponding amounts needed. Must match requiredResourceTypes length.
 */
function upgradeEntityState(uint256 entityId, EntityState targetState, uint256[] calldata requiredResourceTypes, uint256[] calldata requiredAmounts) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);

    // Basic state transition logic (example: can't go back, can only go from Latent->Active, Active->Evolved)
    // More complex logic could depend on entity.state and targetState
    if (targetState <= entity.state) revert InvalidEntityState(); // Cannot downgrade or stay in same state via upgrade

    if (requiredResourceTypes.length != requiredAmounts.length) revert SynthesisFailed(); // Input mismatch

    // Check required resources
    for (uint i = 0; i < requiredResourceTypes.length; i++) {
        uint256 typeId = requiredResourceTypes[i];
        uint256 required = requiredAmounts[i];
        if (_resourceTypes[typeId].id == 0) revert ResourceTypeNotFound(typeId);
        if (_entityResourceBalances[entityId][typeId] < required) {
            revert InsufficientEntityResource(entityId, typeId, required, _entityResourceBalances[entityId][typeId]);
        }
    }

    // Consume resources
    for (uint i = 0; i < requiredResourceTypes.length; i++) {
        uint256 typeId = requiredResourceTypes[i];
        uint256 amount = requiredAmounts[i];
         _entityResourceBalances[entityId][typeId] -= amount;
         _resourceTypes[typeId].totalCirculating -= amount;
         emit ResourceWithdrawn(entityId, typeId, amount); // Use withdraw event for consumption
    }

    EntityState oldState = entity.state;
    entity.state = targetState;
    // Optionally update entity properties based on the new state
    // e.g., entity.properties.baseResourceGeneration = calculateNewGeneration(targetState, entity.properties);

    emit EntityStateUpgraded(entityId, oldState, targetState);
}

/**
 * @dev Allows an Entity owner to create a link between two of their own Entities.
 *      Linked Entities might share resources, combine properties, or have special interactions.
 * @param entityIdA The ID of the first Entity.
 * @param entityIdB The ID of the second Entity.
 */
function linkEntities(uint256 entityIdA, uint256 entityIdB) external onlyOperational whenNotPaused {
    Entity storage entityA = _entities[entityIdA];
    Entity storage entityB = _entities[entityIdB];

    if (entityA.id == 0) revert EntityNotFound(entityIdA);
    if (entityB.id == 0) revert EntityNotFound(entityIdB);
    if (entityA.owner != msg.sender) revert EntityNotOwner(entityIdA, msg.sender);
    if (entityB.owner != msg.sender) revert EntityNotOwner(entityIdB, msg.sender);
    if (entityIdA == entityIdB) revert InvalidEntityLink(); // Cannot link entity to itself
    if (_entityLinks[entityIdA][entityIdB]) revert EntityLinkExists(entityIdA, entityIdB);

    _entityLinks[entityIdA][entityIdB] = true;
    _entityLinks[entityIdB][entityIdA] = true; // Links are bidirectional

    emit EntityLinked(entityIdA, entityIdB);
}

/**
 * @dev Allows an Entity owner to break a link between two of their own Entities.
 * @param entityIdA The ID of the first Entity.
 * @param entityIdB The ID of the second Entity.
 */
function unlinkEntities(uint256 entityIdA, uint256 entityIdB) external onlyOperational whenNotPaused {
    Entity storage entityA = _entities[entityIdA];
    Entity storage entityB = _entities[entityIdB];

    if (entityA.id == 0) revert EntityNotFound(entityIdA);
    if (entityB.id == 0) revert EntityNotFound(entityIdB);
     // Check owner of one is sufficient if link requires same owner, but checking both is safer if link logic changes
    if (entityA.owner != msg.sender || entityB.owner != msg.sender) revert EntityNotOwner(entityIdA, msg.sender); // Or create a specific error

    if (entityIdA == entityIdB) revert InvalidEntityLink();
    if (!_entityLinks[entityIdA][entityIdB]) revert EntityLinkDoesNotExist(entityIdA, entityIdB);

    _entityLinks[entityIdA][entityIdB] = false;
    _entityLinks[entityIdB][entityIdA] = false;

    emit EntityUnlinked(entityIdA, entityIdB);
}

// --- Resource Interaction Functions ---

/**
 * @dev Allows a user to deposit resources into an Entity they own.
 *      This function assumes the resources are somehow available to the contract (e.g.,
 *      transferred via a separate ERC-20 call before calling this, or managed internally).
 *      Simplified: directly increases entity balance and total circulating supply.
 * @param entityId The ID of the Entity to deposit into.
 * @param resourceTypeId The ID of the Resource Type.
 * @param amount The amount to deposit.
 */
function depositResource(uint256 entityId, uint256 resourceTypeId, uint256 amount) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);
    if (_resourceTypes[resourceTypeId].id == 0) revert ResourceTypeNotFound(resourceTypeId);
    if (amount == 0) return;

    // Optional: check max resource capacity
    // if (_entityResourceBalances[entityId][resourceTypeId] + amount > entity.properties.maxResourceCapacity) revert InsufficientEntityCapacity();

    _entityResourceBalances[entityId][resourceTypeId] += amount;
     _resourceTypes[resourceTypeId].totalCirculating += amount;

    emit ResourceDeposited(entityId, resourceTypeId, amount);
}

/**
 * @dev Allows a user to withdraw resources from an Entity they own.
 *      Simplified: directly decreases entity balance and total circulating supply.
 *      A real implementation might transfer external tokens.
 * @param entityId The ID of the Entity to withdraw from.
 * @param resourceTypeId The ID of the Resource Type.
 * @param amount The amount to withdraw.
 */
function withdrawResource(uint256 entityId, uint256 resourceTypeId, uint256 amount) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);
    if (_resourceTypes[resourceTypeId].id == 0) revert ResourceTypeNotFound(resourceTypeId);
    if (amount == 0) return;
    if (_entityResourceBalances[entityId][resourceTypeId] < amount) {
        revert InsufficientEntityResource(entityId, resourceTypeId, amount, _entityResourceBalances[entityId][resourceTypeId]);
    }

    _entityResourceBalances[entityId][resourceTypeId] -= amount;
    _resourceTypes[resourceTypeId].totalCirculating -= amount;

    // In a real scenario, this would trigger an external token transfer to msg.sender
    // For this example, the resources are just removed from the Nexus system/entity balance.

    emit ResourceWithdrawn(entityId, resourceTypeId, amount);
}


/**
 * @dev Allows an Entity owner to harvest resources generated by the Entity.
 *      Generation depends on entity properties, dimension properties, state, and epochs passed.
 * @param entityId The ID of the Entity to harvest from.
 */
function harvestEntityResources(uint256 entityId) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);

    Dimension storage dimension = _dimensions[entity.dimensionId];
    if (dimension.id == 0) revert DimensionNotFound(entity.dimensionId); // Should not happen if entity exists in valid dimension

    uint256 epochsPassed = _currentEpoch - entity.lastHarvestEpoch;
    if (epochsPassed == 0) return; // No new resources generated this epoch

    uint256 baseGeneration = entity.properties.baseResourceGeneration;
    if (baseGeneration == 0) {
        entity.lastHarvestEpoch = _currentEpoch; // Update epoch even if generation is 0
        return; // Entity doesn't generate resources
    }

    // Calculate generation (simplified: base * dimension multiplier * epochs passed)
    // More complex: state multipliers, random factors (using VRF), etc.
    uint256 generatedAmount = (baseGeneration * dimension.properties.resourceAbundanceMultiplier * epochsPassed) / 100;

    if (generatedAmount > 0) {
        // Simplified: Assume a default primary resource type is generated (e.g., ResourceType 1)
        uint256 primaryResourceType = 1; // This should be a configurable parameter
         if (_resourceTypes[primaryResourceType].id == 0) {
              // Handle case where default resource type doesn't exist, or make it a parameter
              entity.lastHarvestEpoch = _currentEpoch; // Update epoch
              return; // Cannot harvest if resource type invalid
         }

        // Add generated resources to entity balance (respecting capacity)
        uint256 currentBalance = _entityResourceBalances[entityId][primaryResourceType];
        uint256 amountToAdd = generatedAmount;
        if (currentBalance + amountToAdd > entity.properties.maxResourceCapacity) {
            amountToAdd = entity.properties.maxResourceCapacity - currentBalance;
             if (amountToAdd == 0) {
                  entity.lastHarvestEpoch = _currentEpoch; // Update epoch
                  return; // At max capacity
             }
        }

        _entityResourceBalances[entityId][primaryResourceType] += amountToAdd;
        _resourceTypes[primaryResourceType].totalCirculating += amountToAdd; // Update total circulating

        emit EntityResourcesHarvested(entityId, primaryResourceType, amountToAdd);
        emit ResourceDeposited(entityId, primaryResourceType, amountToAdd); // Also emit as deposit

    }

    entity.lastHarvestEpoch = _currentEpoch; // Update last harvest epoch regardless of amount generated/added
}


/**
 * @dev Allows an Entity owner to consume resources to synthesize a different resource type.
 *      Requires matching input resources based on a 'recipe' for the output type.
 *      Recipes are implicitly defined by the required/consumed arrays.
 * @param entityId The ID of the Entity performing synthesis.
 * @param outputResourceType The ID of the Resource Type to synthesize.
 * @param amountToSynthesize The number of units of the output resource to create.
 * @param consumedResourceTypes Array of resource type IDs consumed per output unit.
 * @param consumedAmounts Array of corresponding amounts consumed per output unit. Must match consumedResourceTypes length.
 */
function synthesizeResources(uint256 entityId, uint256 outputResourceType, uint256 amountToSynthesize, uint256[] calldata consumedResourceTypes, uint256[] calldata consumedAmounts) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);
     if (_resourceTypes[outputResourceType].id == 0) revert ResourceTypeNotFound(outputResourceType);

    if (amountToSynthesize == 0) return;
    if (consumedResourceTypes.length != consumedAmounts.length) revert SynthesisFailed(); // Input mismatch

    // Calculate total resources needed
    uint256[] memory totalConsumedAmounts = new uint256[](consumedResourceTypes.length);
    for (uint i = 0; i < consumedResourceTypes.length; i++) {
        uint256 requiredPerUnit = consumedAmounts[i];
         // Check for overflow before calculating total
        if (requiredPerUnit > 0 && amountToSynthesize > type(uint256).max / requiredPerUnit) revert SynthesisFailed(); // Overflow check
        totalConsumedAmounts[i] = requiredPerUnit * amountToSynthesize;

        // Check entity has enough resources
        uint256 typeId = consumedResourceTypes[i];
         if (_resourceTypes[typeId].id == 0) revert ResourceTypeNotFound(typeId);
        if (_entityResourceBalances[entityId][typeId] < totalConsumedAmounts[i]) {
            revert InsufficientEntityResource(entityId, typeId, totalConsumedAmounts[i], _entityResourceBalances[entityId][typeId]);
        }
    }

    // Check if entity has capacity for output resource
    uint256 currentOutputBalance = _entityResourceBalances[entityId][outputResourceType];
     // Check for overflow before calculating new balance
     if (currentOutputBalance > type(uint256).max - amountToSynthesize) revert SynthesisFailed(); // Overflow check for output

    if (currentOutputBalance + amountToSynthesize > entity.properties.maxResourceCapacity) revert InsufficientEntityCapacity(); // Assume this error exists or add it


    // Consume input resources
    for (uint i = 0; i < consumedResourceTypes.length; i++) {
        uint256 typeId = consumedResourceTypes[i];
        uint256 amount = totalConsumedAmounts[i];
        _entityResourceBalances[entityId][typeId] -= amount;
        _resourceTypes[typeId].totalCirculating -= amount;
         emit ResourceWithdrawn(entityId, typeId, amount); // Use withdraw event for consumption
    }

    // Add output resources
    _entityResourceBalances[entityId][outputResourceType] += amountToSynthesize;
    _resourceTypes[outputResourceType].totalCirculating += amountToSynthesize;

    emit ResourcesSynthesized(entityId, outputResourceType, amountToSynthesize);
    emit ResourceDeposited(entityId, outputResourceType, amountToSynthesize); // Also emit as deposit
}

// --- Dimensional Interaction Functions ---

/**
 * @dev Allows an Entity owner to shift their Entity to a linked Dimension.
 *      Might require resources or be restricted by Entity/Dimension state.
 * @param entityId The ID of the Entity to shift.
 * @param targetDimensionId The ID of the target Dimension.
 */
function shiftEntityDimension(uint256 entityId, uint256 targetDimensionId) external onlyOperational whenNotPaused {
    Entity storage entity = _entities[entityId];
    if (entity.id == 0) revert EntityNotFound(entityId);
    if (entity.owner != msg.sender) revert EntityNotOwner(entityId, msg.sender);

    uint256 currentDimensionId = entity.dimensionId;
    if (currentDimensionId == targetDimensionId) return; // Already in target dimension
    if (_dimensions[targetDimensionId].id == 0) revert DimensionNotFound(targetDimensionId);
    if (!_dimensionalLinks[currentDimensionId][targetDimensionId]) revert DimensionShiftNotAllowed(entityId, targetDimensionId); // Not linked

    DimensionState targetDimState = _dimensions[targetDimensionId].state;
    // Example restriction: cannot shift into an Anomaly dimension unless Entity is Corrupted
    if (targetDimState == DimensionState.Anomaly && entity.state != EntityState.Corrupted) {
        revert DimensionShiftNotAllowed(entityId, targetDimensionId);
    }
    // Example restriction: Corrupted entities can only shift into Anomaly dimensions
     if (entity.state == EntityState.Corrupted && targetDimState != DimensionState.Anomaly) {
         revert DimensionShiftNotAllowed(entityId, targetDimensionId);
     }

    // Optional: Resource cost for shifting
    // bytes32 shiftCostParam = keccak256("DIMENSION_SHIFT_COST");
    // uint256 cost = _globalParameters[shiftCostParam];
    // if (cost > 0) {
    //    // Check and consume resources from entity (e.g., a specific 'ShiftFuel' resource)
    //    uint256 fuelTypeId = _globalParameters[keccak256("SHIFT_FUEL_RESOURCE_TYPE")];
    //    if (_entityResourceBalances[entityId][fuelTypeId] < cost) {
    //        revert InsufficientEntityResource(entityId, fuelTypeId, cost, _entityResourceBalances[entityId][fuelTypeId]);
    //    }
    //    _entityResourceBalances[entityId][fuelTypeId] -= cost;
    //    _resourceTypes[fuelTypeId].totalCirculating -= cost;
    //    emit ResourceWithdrawn(entityId, fuelTypeId, cost);
    // }


    entity.dimensionId = targetDimensionId;
    emit EntityDimensionShifted(entityId, currentDimensionId, targetDimensionId);
}


// --- Nexus State & Epoch Functions ---

/**
 * @dev Advances the global Nexus Epoch counter.
 *      This function should be called periodically (e.g., via a relayer or Chainlink Keeper)
 *      to trigger time-based effects like resource decay.
 */
function advanceNexusEpoch() external onlyOwner onlyOperational whenNotPaused { // Made onlyOwner for simplicity, but could be a specific role or relayer.
    _currentEpoch++;

    // --- Apply Epoch Effects ---
    // Resource Decay: Decay is applied lazily during harvest/access or could be here.
    // Iterating over *all* entities/resource types here is gas-prohibitive for large numbers.
    // A more advanced pattern is needed for widespread decay (e.g., checkpointing and decay on read/write,
    // or requiring users to call a function to apply decay and maybe get a small reward).
    // For this example, resource decay is *defined* per type but not automatically applied here.
    // It could be applied *during* `harvestEntityResources`, `withdrawResource`, etc. based on epochs passed since last interaction.
    // Let's add a placeholder for lazy decay logic hint.

    // Trigger Global Events/Anomalies (if any are epoch-based)
    // ... complex logic here ...

    emit NexusEpochAdvanced(_currentEpoch);
}

/**
 * @dev Allows the owner to manually trigger an anomaly in a specific Dimension.
 *      The nature of the anomaly (represented by anomalyCode) is defined off-chain or in related logic.
 * @param dimensionId The ID of the Dimension.
 * @param anomalyCode A code representing the type of anomaly.
 */
function triggerDimensionalAnomaly(uint256 dimensionId, uint256 anomalyCode) external onlyOwner onlyOperational whenNotPaused {
     Dimension storage dimension = _dimensions[dimensionId];
     if (dimension.id == 0) revert DimensionNotFound(dimensionId);

     if (dimension.state != DimensionState.Anomaly) {
         DimensionState oldState = dimension.state;
         dimension.state = DimensionState.Anomaly;
         emit DimensionStateChanged(dimensionId, DimensionState.Anomaly);
         emit DimensionalAnomalyTriggered(dimensionId, anomalyCode);
     }
     // Could also update properties or trigger effects based on the anomalyCode
}

/**
 * @dev Allows the owner to resolve an anomaly in a Dimension, returning it to a stable state.
 * @param dimensionId The ID of the Dimension.
 */
function resolveDimensionalAnomaly(uint256 dimensionId) external onlyOwner onlyOperational whenNotPaused {
     Dimension storage dimension = _dimensions[dimensionId];
     if (dimension.id == 0) revert DimensionNotFound(dimensionId);

     if (dimension.state == DimensionState.Anomaly) {
         DimensionState oldState = dimension.state;
         dimension.state = DimensionState.Stable; // Or another non-anomaly state
         emit DimensionStateChanged(dimensionId, DimensionState.Stable); // Or the resolved state
         emit DimensionalAnomalyResolved(dimensionId);
     }
     // Could also revert properties changes caused by the anomaly
}


// --- Query Functions (View/Pure) ---

/**
 * @dev Gets the properties of an Entity.
 * @param entityId The ID of the Entity.
 * @return The Entity struct.
 */
function queryEntityProperties(uint256 entityId) external view returns (Entity memory) {
    if (_entities[entityId].id == 0) revert EntityNotFound(entityId);
    return _entities[entityId];
}

/**
 * @dev Gets the properties of a Dimension.
 * @param dimensionId The ID of the Dimension.
 * @return The Dimension struct.
 */
function queryDimensionProperties(uint256 dimensionId) external view returns (Dimension memory) {
     if (_dimensions[dimensionId].id == 0) revert DimensionNotFound(dimensionId);
    return _dimensions[dimensionId];
}

/**
 * @dev Gets the resource balance for a specific Entity and Resource Type.
 * @param entityId The ID of the Entity.
 * @param resourceTypeId The ID of the Resource Type.
 * @return The amount of the resource the Entity holds.
 */
function queryEntityResourceBalance(uint256 entityId, uint256 resourceTypeId) external view returns (uint256) {
    if (_entities[entityId].id == 0) revert EntityNotFound(entityId);
    if (_resourceTypes[resourceTypeId].id == 0) revert ResourceTypeNotFound(resourceTypeId);
    return _entityResourceBalances[entityId][resourceTypeId];
}

/**
 * @dev Gets the IDs of Entities linked to a given Entity.
 *      Note: Retrieving all linked entities efficiently from a mapping requires
 *      either iterating (gas cost for view depends on complexity) or storing links
 *      in a different structure (like an array within the Entity struct, but arrays in storage are complex).
 *      This function would require iteration in a real implementation if not using a different storage pattern.
 *      Simplified here to just return the mapping state directly (which isn't practical off-chain).
 *      A realistic implementation would need to return an array of IDs, requiring iteration or a different data structure.
 *      Let's return a boolean for a specific link instead, or make it clear this needs refinement for practical use.
 * @param entityIdA The ID of the Entity to check links for.
 * @param entityIdB The ID of the potential linked Entity.
 * @return True if entityIdA and entityIdB are linked, false otherwise.
 */
function queryLinkedEntities(uint256 entityIdA, uint256 entityIdB) external view returns (bool) {
     if (_entities[entityIdA].id == 0) revert EntityNotFound(entityIdA);
     if (_entities[entityIdB].id == 0) revert EntityNotFound(entityIdB);
    return _entityLinks[entityIdA][entityIdB]; // Returns false if keys don't exist or value is false
}

/**
 * @dev Gets the IDs of Dimensions linked to a given Dimension.
 *      Similar considerations as queryLinkedEntities regarding efficient retrieval of all links.
 * @param dimIdA The ID of the Dimension to check links for.
 * @param dimIdB The ID of the potential linked Dimension.
 * @return True if dimIdA and dimIdB are linked, false otherwise.
 */
function queryLinkedDimensions(uint256 dimIdA, uint256 dimIdB) external view returns (bool) {
     if (_dimensions[dimIdA].id == 0) revert DimensionNotFound(dimIdA);
     if (_dimensions[dimIdB].id == 0) revert DimensionNotFound(dimIdB);
    return _dimensionalLinks[dimIdA][dimIdB]; // Returns false if keys don't exist or value is false
}

/**
 * @dev Gets the total circulating amount of a Resource Type across all entities.
 * @param resourceTypeId The ID of the Resource Type.
 * @return The total amount of the resource in circulation.
 */
function queryTotalResourceType(uint256 resourceTypeId) external view returns (uint256) {
     if (_resourceTypes[resourceTypeId].id == 0) revert ResourceTypeNotFound(resourceTypeId);
    return _resourceTypes[resourceTypeId].totalCirculating;
}

/**
 * @dev Gets the owner of an Entity.
 * @param entityId The ID of the Entity.
 * @return The address of the Entity's owner.
 */
function queryEntityOwner(uint256 entityId) external view returns (address) {
    if (_entities[entityId].id == 0) revert EntityNotFound(entityId);
    return _entities[entityId].owner;
}

/**
 * @dev Gets the current global Nexus state.
 * @return The current epoch, nexus state enum, total dimensions, total entities, total resource types.
 */
function queryGlobalNexusState() external view returns (uint256 currentEpoch, NexusState state, uint256 totalDimensions, uint256 totalEntities, uint256 totalResourceTypes) {
    return (_currentEpoch, _nexusState, _nextDimensionId - 1, _nextEntityId - 1, _nextResourceTypeId - 1);
}

// Placeholder for potential resource decay logic upon interaction (lazy decay)
// function _applyResourceDecay(uint256 entityId, uint256 resourceTypeId, uint256 lastInteractionEpoch) private {
//     uint256 epochsPassed = _currentEpoch - lastInteractionEpoch;
//     if (epochsPassed == 0 || _resourceTypes[resourceTypeId].decayRatePerEpoch == 0) return;

//     uint256 currentBalance = _entityResourceBalances[entityId][resourceTypeId];
//     if (currentBalance == 0) return;

//     // Calculate decay amount (simple percentage per epoch)
//     // Example: 10% decay per epoch
//     // Epoch 1: 100 -> 90
//     // Epoch 2: 90 -> 81
//     // Needs careful calculation for multiple epochs - not just epochsPassed * rate
//     // Amount after N epochs = Initial * (1 - rate/10000)^N
//     // Can use a loop or more complex math, loop is safer on chain if N is small/capped.
//     uint256 decayRate = _resourceTypes[resourceTypeId].decayRatePerEpoch; // Assuming rate is * 100 (e.g. 100 = 1%)
//     uint256 remainingPercentage = 10000 - decayRate; // Assuming max rate is 10000 (100%)

//     uint256 remainingBalance = currentBalance;
//     // This loop could be a DoS vector if epochsPassed is large.
//     // Real implementation would use a math approach or checkpointing.
//     // For example: remaining = currentBalance * (remainingPercentage / 10000)^epochsPassed
//     // Power function is complex/gas heavy. Alternative: cap epochsPassed or use a simplified linear decay for N epochs.
//     // Let's use a simplified linear decay for the example:
//     uint256 totalDecayPercent = decayRate * epochsPassed;
//      if (totalDecayPercent >= 10000) { // Decay is 100% or more
//          uint256 decayedAmount = currentBalance;
//           _entityResourceBalances[entityId][resourceTypeId] = 0;
//           _resourceTypes[resourceTypeId].totalCirculating -= decayedAmount; // Reduce total circulating
//           emit ResourceWithdrawn(entityId, resourceTypeId, decayedAmount); // Emit decay as a kind of withdrawal
//      } else {
//           uint256 decayedAmount = (currentBalance * totalDecayPercent) / 10000;
//            _entityResourceBalances[entityId][resourceTypeId] -= decayedAmount;
//            _resourceTypes[resourceTypeId].totalCirculating -= decayedAmount;
//            emit ResourceWithdrawn(entityId, resourceTypeId, decayedAmount); // Emit decay
//      }

//     // Note: The `lastInteractionEpoch` would need to be tracked per resource type per entity.
//     // This adds state complexity (`mapping(uint256 => mapping(uint256 => uint256))` for last interaction epoch).
//     // This lazy decay logic is commented out as it significantly increases complexity and gas considerations.
//     // A simpler model might have decay applied only when `advanceNexusEpoch` iterates over *some* entities,
//     // or just track current balance and implicitly calculate "effective" balance off-chain based on epoch & decay rate.
// }

// Placeholder for potential entity capacity check
// error InsufficientEntityCapacity();

// Placeholder for invalid link error
 error InvalidEntityLink();
 error InvalidDimensionLink();

 // Placeholder for potential resource properties validation
 error InvalidResourceTypeProperties();
 // Placeholder for insufficient entity capacity
 error InsufficientEntityCapacity();

}
```