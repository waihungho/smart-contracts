Okay, let's design an interesting smart contract. Instead of a standard token or simple DeFi example, let's create a system for managing dynamic, evolving on-chain entities ("ChronoEntities") that require resources, interact with each other, and change state based on time and user actions, governed by a simple parameter system.

This incorporates concepts like:
*   **State Machines:** Entities transition between evolution stages.
*   **Time-Based Dynamics:** Entities can decay or become ready to evolve based on elapsed time/interactions.
*   **Resource Management:** Entities consume and potentially produce various defined resources.
*   **Parametric Interaction:** Interactions between entities have effects determined by configurable rules and entity parameters.
*   **Basic Governance:** A simple mechanism to update system parameters and rules.
*   **Dynamic Data:** Entities have parameters that can change.

This is more complex than a standard ERC-anything and involves intricate internal logic. It won't be a fully fledged game, but it lays the groundwork for dynamic on-chain assets.

---

**Contract Name:** ChronoForge

**Description:** A smart contract system for managing dynamic, evolving digital entities called "ChronoEntities". Entities have evolution stages, parameters, resource balances, and can interact with each other or users. Their state changes based on time and interactions, consuming internal resources. System parameters and evolution rules are managed through a simple governor address.

**Advanced/Creative/Trendy Concepts:**
*   **Dynamic Entity State:** Entities are not static tokens; they have health/decay influenced by time, change evolution stages, and hold internal resources.
*   **Parametric Interactions:** Effects of entity-entity interactions are not hardcoded but defined by configurable "Interaction Types" and influenced by entity parameters.
*   **Time-Dependent Logic:** Evolution readiness and decay are calculated based on timestamps.
*   **Internal Resource Economy:** Entities manage their own balances of contract-defined resources.
*   **Decentralized Governance (Simple):** Key system parameters and rules can be adjusted.

**Contract State:**
*   `entities`: Mapping from entity ID (uint256) to Entity struct.
*   `entityOwner`: Mapping from entity ID (uint256) to owner address.
*   `nextEntityId`: Counter for new entities.
*   `evolutionStageConfig`: Mapping from stage ID (uint8) to EvolutionStageConfig struct.
*   `resourceTypes`: Mapping from resource ID (uint8) to ResourceType struct.
*   `interactionTypes`: Mapping from interaction ID (uint8) to InteractionType struct.
*   `entityResourceBalances`: Nested mapping from entity ID (uint256) to resource ID (uint8) to balance (uint256).
*   `globalParameters`: Mapping from bytes32 key to uint256 value (for system configs).
*   `governor`: Address with permission to set system parameters and rules.
*   `paused`: Boolean indicating if core actions are paused.

**Functions Summary (>= 20):**

*   **Entity Management:**
    1.  `createEntity`: Mints a new ChronoEntity with initial parameters.
    2.  `getEntity`: Retrieves details of a specific entity.
    3.  `getEntityOwner`: Gets the owner address for an entity ID.
    4.  `transferEntity`: Transfers ownership of an entity.
    5.  `burnEntity`: Destroys an entity.
    6.  `evolveEntity`: Attempts to advance an entity to the next evolution stage (requires conditions met and resources).
    7.  `checkEvolutionReadiness`: Checks if an entity meets the time/interaction requirements for evolution.
    8.  `calculateDecayProgress`: Calculates the current decay level of an entity based on time since last interaction.
    9.  `applyDecayDamage`: Applies decay damage (reduces health/energy) to an entity based on current decay progress.

*   **Resource Management:**
    10. `grantResourceToEntity`: Issues specific resources directly to an entity's internal balance.
    11. `consumeResourceFromEntity`: Burns specific resources from an entity's internal balance.
    12. `getEntityResourceBalance`: Gets the balance of a specific resource for an entity.
    13. `defineResourceType`: Governor function to register or update details for a resource type.
    14. `transferResourceBetweenEntities`: Moves resources from one entity's balance to another's.

*   **Interaction:**
    15. `interactEntities`: Executes an interaction between two entities based on a specified interaction type.
    16. `interactWithEntity`: Allows a user to interact with an entity (e.g., feed resources, attempt to heal).
    17. `defineInteractionType`: Governor function to register or update the rules/effects of an interaction type.
    18. `getPotentialInteractionEffects`: (View) Calculates the potential outcome of an interaction without executing it.

*   **Governance/Configuration:**
    19. `setGovernor`: Transfers the governor role to a new address.
    20. `addEvolutionStageConfig`: Governor function to add configuration for a new evolution stage.
    21. `updateEvolutionStageConfig`: Governor function to modify configuration for an existing evolution stage.
    22. `setGlobalParameter`: Governor function to set a global system parameter (e.g., base decay rate, evolution time requirement).
    23. `getGlobalParameter`: Retrieves the value of a global parameter.
    24. `pause`: Governor function to pause core contract actions.
    25. `unpause`: Governor function to unpause core contract actions.

*   **Query/Utility:**
    26. `getTotalEntities`: Returns the total number of entities created.
    27. `getEvolutionStageConfig`: Retrieves configuration details for an evolution stage.
    28. `getResourceTypeDetails`: Retrieves details for a resource type.
    29. `getInteractionTypeDetails`: Retrieves details for an interaction type.
    30. `calculateNextEvolutionStage`: (Pure) Determines the ID of the next stage based on the current one.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoForge
 * @dev A smart contract system for managing dynamic, evolving digital entities called "ChronoEntities".
 * Entities have evolution stages, parameters, resource balances, and can interact with each other or users.
 * Their state changes based on time and interactions, consuming internal resources.
 * System parameters and evolution rules are managed through a simple governor address.
 *
 * Concepts: Dynamic State, Time-Based Logic, Resource Management, Parametric Interactions, Basic Governance.
 */

/**
 * @notice Outline:
 * 1. Errors
 * 2. Events
 * 3. Struct Definitions
 * 4. State Variables
 * 5. Modifiers
 * 6. Constructor
 * 7. Entity Management Functions
 * 8. Resource Management Functions
 * 9. Interaction Functions
 * 10. Governance/Configuration Functions
 * 11. Query/Utility Functions
 */

/**
 * @notice Function Summary:
 * - Entity Management:
 *   - createEntity(address owner, uint8 initialStage, uint256 initialHealth, uint256 initialEnergy, bytes initialParams): Mints a new entity.
 *   - getEntity(uint256 entityId): Reads entity details.
 *   - getEntityOwner(uint256 entityId): Reads entity owner.
 *   - transferEntity(address to, uint256 entityId): Transfers entity ownership.
 *   - burnEntity(uint256 entityId): Destroys an entity.
 *   - evolveEntity(uint256 entityId): Advances entity stage, consumes resources, resets state.
 *   - checkEvolutionReadiness(uint256 entityId): Checks if time/interaction requirements for evolution are met.
 *   - calculateDecayProgress(uint256 entityId): Computes time-based decay accumulation.
 *   - applyDecayDamage(uint256 entityId): Reduces entity health/energy based on accumulated decay.
 * - Resource Management:
 *   - grantResourceToEntity(uint256 entityId, uint8 resourceId, uint256 amount): Adds resource balance to entity.
 *   - consumeResourceFromEntity(uint256 entityId, uint8 resourceId, uint256 amount): Removes resource balance from entity.
 *   - getEntityResourceBalance(uint256 entityId, uint8 resourceId): Reads entity's resource balance.
 *   - defineResourceType(uint8 resourceId, string memory name, bool isConsumable, bool canBeProduced): Defines or updates a resource type.
 *   - transferResourceBetweenEntities(uint256 fromEntityId, uint256 toEntityId, uint8 resourceId, uint256 amount): Transfers resources between entities.
 * - Interaction:
 *   - interactEntities(uint256 entity1Id, uint256 entity2Id, uint8 interactionTypeId): Executes interaction between two entities.
 *   - interactWithEntity(uint256 entityId, uint8 interactionTypeId, uint8 resourceId, uint256 resourceAmount): User interacts with an entity (e.g., feeding).
 *   - defineInteractionType(uint8 interactionTypeId, bytes memory effectLogic, uint256 requiredResourcesHash, uint256 outputResourcesHash): Defines interaction rules and effects (simplified logic representation).
 *   - getPotentialInteractionEffects(uint256 entity1Id, uint256 entity2Id, uint8 interactionTypeId): (View) Simulates interaction effects.
 * - Governance/Configuration:
 *   - setGovernor(address newGovernor): Sets new governor address.
 *   - addEvolutionStageConfig(uint8 stageId, uint256 timeToNextStage, uint256 interactionCountToNextStage, uint256 requiredResourcesHash): Adds stage config.
 *   - updateEvolutionStageConfig(uint8 stageId, uint256 timeToNextStage, uint256 interactionCountToNextStage, uint256 requiredResourcesHash): Updates stage config.
 *   - setGlobalParameter(bytes32 key, uint256 value): Sets system-wide parameters.
 *   - getGlobalParameter(bytes32 key): Reads global parameter.
 *   - pause(): Pauses core actions.
 *   - unpause(): Unpauses core actions.
 * - Query/Utility:
 *   - getTotalEntities(): Returns total entity count.
 *   - getEvolutionStageConfig(uint8 stageId): Reads stage config.
 *   - getResourceTypeDetails(uint8 resourceId): Reads resource details.
 *   - getInteractionTypeDetails(uint8 interactionTypeId): Reads interaction details.
 *   - calculateNextEvolutionStage(uint8 currentStageId): (Pure) Calculates next stage ID based on current.
 */

// 1. Errors
error ChronoForge__InvalidEntityId();
error ChronoForge__NotEntityOwner();
error ChronoForge__NotGovernor();
error ChronoForge__Paused();
error ChronoForge__NotPaused();
error ChronoForge__StageConfigNotSet(uint8 stageId);
error ChronoForge__NextStageConfigNotSet(uint8 currentStageId);
error ChronoForge__EvolutionNotReady();
error ChronoForge__InsufficientResources(uint8 resourceId, uint256 required, uint256 has);
error ChronoForge__ResourceTypeNotSet(uint8 resourceId);
error ChronoForge__InteractionTypeNotSet(uint8 interactionTypeId);
error ChronoForge__InsufficientDecayProgress(uint256 required, uint256 has);
error ChronoForge__CannotTransferToZeroAddress();
error ChronoForge__EntityAlreadyExists(uint256 entityId); // Should not happen with auto-increment ID but good safeguard
error ChronoForge__ZeroAmount();

// 2. Events
event EntityCreated(uint256 indexed entityId, address indexed owner, uint8 initialStage, uint256 creationTime);
event EntityTransfered(uint256 indexed entityId, address indexed from, address indexed to);
event EntityBurned(uint256 indexed entityId);
event EntityEvolved(uint256 indexed entityId, uint8 fromStage, uint8 toStage, uint256 evolutionTime);
event EntityParametersUpdated(uint256 indexed entityId, bytes updatedParams); // Simplified
event EntityDecayApplied(uint256 indexed entityId, uint256 decayAmount, uint256 newHealth, uint256 newEnergy); // Simplified
event ResourceGranted(uint256 indexed entityId, uint8 indexed resourceId, uint256 amount);
event ResourceConsumed(uint256 indexed entityId, uint8 indexed resourceId, uint256 amount);
event ResourceTransferred(uint256 indexed fromEntityId, uint256 indexed toEntityId, uint8 indexed resourceId, uint256 amount);
event ResourceTypeDefined(uint8 indexed resourceId, string name, bool isConsumable, bool canBeProduced);
event EntitiesInteracted(uint256 indexed entity1Id, uint256 indexed entity2Id, uint8 indexed interactionTypeId);
event EntityInteractedWith(uint256 indexed entityId, address indexed user, uint8 indexed interactionTypeId);
event InteractionTypeDefined(uint8 indexed interactionTypeId); // Details omitted for event simplicity
event GovernorSet(address indexed oldGovernor, address indexed newGovernor);
event EvolutionStageConfigDefined(uint8 indexed stageId); // Details omitted
event GlobalParameterSet(bytes32 indexed key, uint256 value);
event Paused(address account);
event Unpaused(address account);

// 3. Struct Definitions

/**
 * @dev Represents a ChronoEntity.
 * Simplified health/energy/decay for example.
 * `params` is a generic bytes field for future flexibility (e.g., storing specific attributes).
 */
struct Entity {
    uint256 id;
    uint256 creationTime;
    uint256 lastInteractionTime; // Timestamp of the last significant interaction
    uint8 currentEvolutionStage;
    uint256 currentHealth;
    uint256 currentEnergy;
    uint256 interactionCount; // Count of interactions relevant for evolution
    uint256 accumulatedDecayProgress; // Represents accumulated decay time/points
    bytes params; // Generic parameters data
}

/**
 * @dev Configuration for an evolution stage.
 * `requiredResourcesHash` is a placeholder; ideally, this would be a mapping or array.
 */
struct EvolutionStageConfig {
    uint256 timeToNextStage; // Seconds required since creation or last evolution/interaction
    uint256 interactionCountToNextStage; // Interactions required
    // Placeholder for resources needed to evolve. Use a hash or separate mapping for simplicity in this example.
    // In a real system, this would likely be mapping(uint8 => uint256) requiresResources;
    uint256 requiredResourcesHash; // Dummy value representing resource requirements
    bool exists; // To check if config is set
}

/**
 * @dev Configuration for a resource type.
 */
struct ResourceType {
    string name;
    bool isConsumable;
    bool canBeProduced;
    bool exists; // To check if config is set
}

/**
 * @dev Configuration for an interaction type.
 * `effectLogic` is a placeholder for complex logic, maybe a reference to another system or just data.
 * `requiredResourcesHash` and `outputResourcesHash` are placeholders for resources involved.
 */
struct InteractionType {
    bytes effectLogic; // Placeholder: data defining interaction effects
    // Placeholders for resources required/produced by interaction.
    // mapping(uint8 => uint256) requiredResources;
    // mapping(uint8 => uint256) outputResources;
    uint256 requiredResourcesHash; // Dummy value
    uint256 outputResourcesHash; // Dummy value
    bool exists; // To check if config is set
}

// 4. State Variables
mapping(uint256 => Entity) private s_entities;
mapping(uint256 => address) private s_entityOwner; // Separate owner mapping for easier access
uint256 private s_nextEntityId;

mapping(uint8 => EvolutionStageConfig) private s_evolutionStageConfig;
mapping(uint8 => ResourceType) private s_resourceTypes;
mapping(uint8 => InteractionType) private s_interactionTypes;

mapping(uint256 => mapping(uint8 => uint256)) private s_entityResourceBalances;

mapping(bytes32 => uint256) private s_globalParameters; // Generic system parameters

address private s_governor;
bool private s_paused;

// Define common global parameter keys
bytes32 public constant GLOBAL_PARAM_BASE_DECAY_RATE = keccak256("BASE_DECAY_RATE"); // decay progress per second
bytes32 public constant GLOBAL_PARAM_DECAY_HEALTH_EFFECT = keccak256("DECAY_HEALTH_EFFECT"); // health lost per decay progress unit
bytes32 public constant GLOBAL_PARAM_DECAY_ENERGY_EFFECT = keccak256("DECAY_ENERGY_EFFECT"); // energy lost per decay progress unit
bytes32 public constant GLOBAL_PARAM_BASE_MAX_HEALTH = keccak256("BASE_MAX_HEALTH"); // base health for new entities
bytes32 public constant GLOBAL_PARAM_BASE_MAX_ENERGY = keccak256("BASE_MAX_ENERGY"); // base energy for new entities

// 5. Modifiers
modifier onlyGovernor() {
    if (msg.sender != s_governor) {
        revert ChronoForge__NotGovernor();
    }
    _;
}

modifier whenNotPaused() {
    if (s_paused) {
        revert ChronoForge__Paused();
    }
    _;
}

modifier whenPaused() {
    if (!s_paused) {
        revert ChronoForge__NotPaused();
    }
    _;
}

modifier onlyEntityOwner(uint256 entityId) {
    if (s_entityOwner[entityId] != msg.sender) {
        revert ChronoForge__NotEntityOwner();
    }
    _;
}

modifier entityExists(uint256 entityId) {
    if (s_entityOwner[entityId] == address(0) || s_entities[entityId].creationTime == 0) { // Check existence
         revert ChronoForge__InvalidEntityId();
    }
    _;
}

// 6. Constructor
constructor() {
    s_governor = msg.sender;
    s_nextEntityId = 1; // Start entity IDs from 1
    emit GovernorSet(address(0), msg.sender);

    // Set some initial default global parameters
    s_globalParameters[GLOBAL_PARAM_BASE_DECAY_RATE] = 1; // 1 decay progress per second
    s_globalParameters[GLOBAL_PARAM_DECAY_HEALTH_EFFECT] = 1; // Lose 1 health per 1 decay progress
    s_globalParameters[GLOBAL_PARAM_DECAY_ENERGY_EFFECT] = 1; // Lose 1 energy per 1 decay progress
    s_globalParameters[GLOBAL_PARAM_BASE_MAX_HEALTH] = 1000;
    s_globalParameters[GLOBAL_PARAM_BASE_MAX_ENERGY] = 1000;
}

// Internal helper to calculate decay progress since last interaction
function _calculateDecayProgressSinceLastInteraction(uint256 entityId) internal view returns (uint256) {
    uint256 lastTime = s_entities[entityId].lastInteractionTime;
    uint256 baseRate = s_globalParameters[GLOBAL_PARAM_BASE_DECAY_RATE];
    if (lastTime == 0 || baseRate == 0) {
        return 0; // No interaction recorded or decay disabled
    }
    // Prevent overflow if time difference is huge
    uint256 timeElapsed = block.timestamp - lastTime;
    return timeElapsed * baseRate;
}

// Internal helper to apply accumulated decay to health/energy
function _applyAccumulatedDecay(uint256 entityId) internal {
    uint256 accumulated = s_entities[entityId].accumulatedDecayProgress;
    if (accumulated == 0) return;

    uint256 healthEffect = s_globalParameters[GLOBAL_PARAM_DECAY_HEALTH_EFFECT];
    uint256 energyEffect = s_globalParameters[GLOBAL_PARAM_DECAY_ENERGY_EFFECT];

    uint256 healthLost = accumulated * healthEffect;
    uint256 energyLost = accumulated * energyEffect;

    uint256 currentHealth = s_entities[entityId].currentHealth;
    uint256 currentEnergy = s_entities[entityId].currentEnergy;

    s_entities[entityId].currentHealth = (currentHealth > healthLost) ? currentHealth - healthLost : 0;
    s_entities[entityId].currentEnergy = (currentEnergy > energyLost) ? currentEnergy - energyLost : 0;
    s_entities[entityId].accumulatedDecayProgress = 0; // Reset accumulated decay after applying

    emit EntityDecayApplied(entityId, accumulated, s_entities[entityId].currentHealth, s_entities[entityId].currentEnergy);
}


// 7. Entity Management Functions

/**
 * @dev Creates a new ChronoEntity.
 * @param owner The address that will own the new entity.
 * @param initialStage The starting evolution stage of the entity.
 * @param initialHealth The initial health value.
 * @param initialEnergy The initial energy value.
 * @param initialParams Initial generic parameters for the entity.
 */
function createEntity(address owner, uint8 initialStage, uint256 initialHealth, uint256 initialEnergy, bytes calldata initialParams)
    public
    whenNotPaused
{
    if (owner == address(0)) revert ChronoForge__CannotTransferToZeroAddress();
    if (!s_evolutionStageConfig[initialStage].exists) revert ChronoForge__StageConfigNotSet(initialStage);

    uint256 entityId = s_nextEntityId;
    s_nextEntityId++;

    s_entities[entityId] = Entity({
        id: entityId,
        creationTime: block.timestamp,
        lastInteractionTime: block.timestamp, // Initial interaction time
        currentEvolutionStage: initialStage,
        currentHealth: initialHealth,
        currentEnergy: initialEnergy,
        interactionCount: 0,
        accumulatedDecayProgress: 0,
        params: initialParams
    });

    s_entityOwner[entityId] = owner;

    emit EntityCreated(entityId, owner, initialStage, block.timestamp);
}

/**
 * @dev Retrieves the details of a specific entity.
 * Applies accumulated decay calculation before returning state.
 * @param entityId The ID of the entity.
 * @return The Entity struct.
 */
function getEntity(uint256 entityId)
    public
    view
    entityExists(entityId)
    returns (Entity memory)
{
    Entity storage entity = s_entities[entityId];
    uint256 currentDecayProgress = entity.accumulatedDecayProgress + _calculateDecayProgressSinceLastInteraction(entityId);

    // Create a temporary memory struct with decay applied for reading
    Entity memory displayEntity = entity;
    uint256 healthEffect = s_globalParameters[GLOBAL_PARAM_DECAY_HEALTH_EFFECT];
    uint256 energyEffect = s_globalParameters[GLOBAL_PARAM_DECAY_ENERGY_EFFECT];

    uint256 healthLost = currentDecayProgress * healthEffect;
    uint256 energyLost = currentDecayProgress * energyEffect;

    displayEntity.currentHealth = (displayEntity.currentHealth > healthLost) ? displayEntity.currentHealth - healthLost : 0;
    displayEntity.currentEnergy = (displayEntity.currentEnergy > energyLost) ? displayEntity.currentEnergy - energyLost : 0;
    displayEntity.accumulatedDecayProgress = 0; // Display as if decay was just applied
    displayEntity.lastInteractionTime = block.timestamp; // Display as if updated

    return displayEntity;
}

/**
 * @dev Gets the owner address for a specific entity.
 * @param entityId The ID of the entity.
 * @return The owner's address.
 */
function getEntityOwner(uint256 entityId)
    public
    view
    entityExists(entityId)
    returns (address)
{
    return s_entityOwner[entityId];
}

/**
 * @dev Transfers ownership of an entity to another address.
 * @param to The address to transfer ownership to.
 * @param entityId The ID of the entity to transfer.
 */
function transferEntity(address to, uint256 entityId)
    public
    whenNotPaused
    onlyEntityOwner(entityId)
    entityExists(entityId)
{
    if (to == address(0)) revert ChronoForge__CannotTransferToZeroAddress();

    address from = s_entityOwner[entityId];
    s_entityOwner[entityId] = to;

    emit EntityTransfered(entityId, from, to);
}

/**
 * @dev Destroys an entity. Can only be called by the owner.
 * @param entityId The ID of the entity to burn.
 */
function burnEntity(uint256 entityId)
    public
    whenNotPaused
    onlyEntityOwner(entityId)
    entityExists(entityId)
{
    delete s_entities[entityId];
    delete s_entityOwner[entityId];
    // Note: Resource balances for the entity will remain in storage, but are inaccessible.
    // A more robust system would iterate and clear them, but that's gas-intensive.

    emit EntityBurned(entityId);
}

/**
 * @dev Attempts to evolve an entity to the next stage.
 * Requires the entity to meet time and interaction count criteria,
 * and consume required resources.
 * @param entityId The ID of the entity to evolve.
 */
function evolveEntity(uint256 entityId)
    public
    whenNotPaused
    onlyEntityOwner(entityId)
    entityExists(entityId)
{
    _applyAccumulatedDecay(entityId); // Apply decay before evolving

    Entity storage entity = s_entities[entityId];
    uint8 currentStageId = entity.currentEvolutionStage;
    uint8 nextStageId = calculateNextEvolutionStage(currentStageId);

    if (!s_evolutionStageConfig[nextStageId].exists) revert ChronoForge__NextStageConfigNotSet(currentStageId);

    if (!checkEvolutionReadiness(entityId)) {
        revert ChronoForge__EvolutionNotReady();
    }

    // Placeholder: Resource consumption logic here.
    // For this example, we'll skip actual resource check/consumption based on the dummy hash.
    // In a real implementation, you would consume resources defined for the next stage.
    // e.g., iterate through a requiredResources mapping and call consumeResourceFromEntity.

    entity.currentEvolutionStage = nextStageId;
    entity.creationTime = block.timestamp; // Optionally reset creation time for next stage timer
    entity.lastInteractionTime = block.timestamp; // Reset interaction time
    entity.interactionCount = 0; // Reset interaction count
    // Optionally restore some health/energy, or set base stats from the new stage config
    entity.currentHealth = s_globalParameters[GLOBAL_PARAM_BASE_MAX_HEALTH]; // Simple example
    entity.currentEnergy = s_globalParameters[GLOBAL_PARAM_BASE_MAX_ENERGY]; // Simple example

    emit EntityEvolved(entityId, currentStageId, nextStageId, block.timestamp);
}

/**
 * @dev Checks if an entity meets the criteria (time elapsed, interaction count) for evolution.
 * @param entityId The ID of the entity.
 * @return True if ready, false otherwise.
 */
function checkEvolutionReadiness(uint256 entityId)
    public
    view
    entityExists(entityId)
    returns (bool)
{
    Entity storage entity = s_entities[entityId];
    uint8 currentStageId = entity.currentEvolutionStage;
    uint8 nextStageId = calculateNextEvolutionStage(currentStageId);

    EvolutionStageConfig storage nextStageConfig = s_evolutionStageConfig[nextStageId];

    // If the next stage config doesn't exist, it can't evolve further (or config is missing)
    if (!nextStageConfig.exists) {
        return false;
    }

    bool timeElapsed = (block.timestamp - entity.creationTime) >= nextStageConfig.timeToNextStage;
    bool interactionCountMet = entity.interactionCount >= nextStageConfig.interactionCountToNextStage;

    // Note: In a real scenario, you'd also check resource availability here.
    // Example: bool hasResources = _checkRequiredEvolutionResources(entityId, nextStageId);

    return timeElapsed && interactionCountMet; // Add && hasResources in a real version
}

/**
 * @dev Calculates the current accumulated decay progress for an entity.
 * This is a view function that calculates based on current time.
 * It does *not* update the entity's state. Use `applyDecayDamage` to apply it.
 * @param entityId The ID of the entity.
 * @return The total decay progress (accumulated + since last interaction).
 */
function calculateDecayProgress(uint256 entityId)
    public
    view
    entityExists(entityId)
    returns (uint256)
{
    Entity storage entity = s_entities[entityId];
    return entity.accumulatedDecayProgress + _calculateDecayProgressSinceLastInteraction(entityId);
}

/**
 * @dev Applies accumulated decay damage to an entity's health and energy.
 * Any decay accumulated since the last state update is calculated and applied.
 * Can be called by anyone (potentially incentivized off-chain) or triggered by interactions.
 * @param entityId The ID of the entity.
 */
function applyDecayDamage(uint256 entityId)
    public
    whenNotPaused
    entityExists(entityId)
{
    // First, accumulate any decay since the last interaction time recorded on chain
    uint256 decaySinceLastInteraction = _calculateDecayProgressSinceLastInteraction(entityId);
    s_entities[entityId].accumulatedDecayProgress += decaySinceLastInteraction;
    s_entities[entityId].lastInteractionTime = block.timestamp; // Update last interaction time

    // Then, apply the *total* accumulated decay
    _applyAccumulatedDecay(entityId);
}


// 8. Resource Management Functions

/**
 * @dev Grants a specific amount of a resource to an entity's internal balance.
 * Can be called by the governor or potentially other allowed roles/functions.
 * @param entityId The ID of the entity receiving resources.
 * @param resourceId The ID of the resource type.
 * @param amount The amount of resource to grant.
 */
function grantResourceToEntity(uint256 entityId, uint8 resourceId, uint256 amount)
    public
    whenNotPaused
    onlyGovernor // Or refine access control
    entityExists(entityId)
{
    if (amount == 0) revert ChronoForge__ZeroAmount();
    if (!s_resourceTypes[resourceId].exists) revert ChronoForge__ResourceTypeNotSet(resourceId);

    s_entityResourceBalances[entityId][resourceId] += amount;

    emit ResourceGranted(entityId, resourceId, amount);
}

/**
 * @dev Consumes a specific amount of a resource from an entity's internal balance.
 * Can be called by entity owner, governor, or via interaction logic.
 * @param entityId The ID of the entity consuming resources.
 * @param resourceId The ID of the resource type.
 * @param amount The amount of resource to consume.
 */
function consumeResourceFromEntity(uint256 entityId, uint8 resourceId, uint256 amount)
    public
    whenNotPaused
    entityExists(entityId)
{
    // Access control needs refinement: owner? governor? specific interaction functions?
    // For this example, let's allow owner or governor
    if (msg.sender != s_entityOwner[entityId] && msg.sender != s_governor) {
         revert ChronoForge__NotEntityOwner(); // Or create a specific access error
    }

    if (amount == 0) revert ChronoForge__ZeroAmount();
    if (!s_resourceTypes[resourceId].exists) revert ChronoForge__ResourceTypeNotSet(resourceId);
    if (!s_resourceTypes[resourceId].isConsumable) revert ChronoForge__ResourceTypeNotSet(resourceId); // Should be consumable

    uint256 currentBalance = s_entityResourceBalances[entityId][resourceId];
    if (currentBalance < amount) {
        revert ChronoForge__InsufficientResources(resourceId, amount, currentBalance);
    }

    s_entityResourceBalances[entityId][resourceId] -= amount;

    emit ResourceConsumed(entityId, resourceId, amount);
}

/**
 * @dev Gets the balance of a specific resource for an entity.
 * @param entityId The ID of the entity.
 * @param resourceId The ID of the resource type.
 * @return The balance of the resource.
 */
function getEntityResourceBalance(uint256 entityId, uint8 resourceId)
    public
    view
    entityExists(entityId)
    returns (uint256)
{
    // No check for resourceType.exists, returns 0 if not defined or entity has none.
    return s_entityResourceBalances[entityId][resourceId];
}

/**
 * @dev Defines or updates a resource type configuration. Governor only.
 * @param resourceId The unique ID for the resource type.
 * @param name The human-readable name.
 * @param isConsumable True if entities/users can consume this resource.
 * @param canBeProduced True if this resource can be generated by entities/interactions.
 */
function defineResourceType(uint8 resourceId, string memory name, bool isConsumable, bool canBeProduced)
    public
    whenNotPaused
    onlyGovernor
{
    s_resourceTypes[resourceId] = ResourceType({
        name: name,
        isConsumable: isConsumable,
        canBeProduced: canBeProduced,
        exists: true
    });

    emit ResourceTypeDefined(resourceId, name, isConsumable, canBeProduced);
}

/**
 * @dev Transfers a specific amount of a resource between two entities.
 * Can be called by the governor or potentially interaction logic.
 * @param fromEntityId The ID of the entity sending resources.
 * @param toEntityId The ID of the entity receiving resources.
 * @param resourceId The ID of the resource type.
 * @param amount The amount of resource to transfer.
 */
function transferResourceBetweenEntities(uint256 fromEntityId, uint256 toEntityId, uint8 resourceId, uint256 amount)
    public
    whenNotPaused
    onlyGovernor // Or refine access control (e.g., interaction logic only)
    entityExists(fromEntityId)
    entityExists(toEntityId)
{
    if (amount == 0) revert ChronoForge__ZeroAmount();
    if (fromEntityId == toEntityId) return; // No-op for same entity

    if (!s_resourceTypes[resourceId].exists) revert ChronoForge__ResourceTypeNotSet(resourceId);
    // Can only transfer resources that exist and are intended for entity balances

    uint256 fromBalance = s_entityResourceBalances[fromEntityId][resourceId];
    if (fromBalance < amount) {
        revert ChronoForge__InsufficientResources(resourceId, amount, fromBalance);
    }

    s_entityResourceBalances[fromEntityId][resourceId] -= amount;
    s_entityResourceBalances[toEntityId][resourceId] += amount;

    emit ResourceTransferred(fromEntityId, toEntityId, resourceId, amount);
}


// 9. Interaction Functions

/**
 * @dev Executes an interaction between two entities.
 * The effects are determined by the interaction type config.
 * This function would contain complex logic mapping interaction types and entity params
 * to changes in entity state (health, energy, resources, parameters, interaction count).
 * @param entity1Id The ID of the first entity.
 * @param entity2Id The ID of the second entity.
 * @param interactionTypeId The ID of the interaction type.
 */
function interactEntities(uint256 entity1Id, uint256 entity2Id, uint8 interactionTypeId)
    public
    whenNotPaused
    entityExists(entity1Id)
    entityExists(entity2Id)
{
    if (entity1Id == entity2Id) revert ChronoForge__InvalidEntityId(); // Entities cannot interact with themselves

    // This function would be complex. It would:
    // 1. Apply decay to both entities (_applyAccumulatedDecay).
    // 2. Look up InteractionType config (s_interactionTypes[interactionTypeId]).
    // 3. Check if entities have required resources (using requiredResourcesHash dummy value).
    // 4. Consume resources if needed.
    // 5. Implement the interaction effects based on effectLogic, entity parameters, and random factors if any.
    //    Effects could include: health/energy changes, parameter changes, resource transfers (using transferResourceBetweenEntities),
    //    updating lastInteractionTime, incrementing interactionCount.
    // 6. Emit event.

    if (!s_interactionTypes[interactionTypeId].exists) revert ChronoForge__InteractionTypeNotSet(interactionTypeId);

    // --- Simplified Placeholder Logic ---
    _applyAccumulatedDecay(entity1Id);
    _applyAccumulatedDecay(entity2Id);

    // Dummy logic: just increment interaction counts and update timestamps
    s_entities[entity1Id].interactionCount++;
    s_entities[entity2Id].interactionCount++;
    s_entities[entity1Id].lastInteractionTime = block.timestamp;
    s_entities[entity2Id].lastInteractionTime = block.timestamp;

    // Dummy resource consumption/production logic (based on dummy hashes)
    // In reality, this would read specific resource IDs and amounts from config/structs
    // consumeResourceFromEntity(entity1Id, someResourceId, someAmount);
    // grantResourceToEntity(entity1Id, anotherResourceId, anotherAmount);
    // transferResourceBetweenEntities(entity2Id, entity1Id, someThirdResourceId, someThirdAmount);
    // --- End Placeholder ---

    emit EntitiesInteracted(entity1Id, entity2Id, interactionTypeId);
}

/**
 * @dev Allows a user/external system to interact with a single entity.
 * This could represent feeding, healing, boosting, etc.
 * The interaction logic would depend on the interaction type.
 * @param entityId The ID of the entity being interacted with.
 * @param interactionTypeId The ID of the interaction type.
 * @param resourceId A resource involved in the interaction (e.g., being fed). Use 0 if none.
 * @param resourceAmount The amount of the resource involved. Use 0 if none.
 */
function interactWithEntity(uint256 entityId, uint8 interactionTypeId, uint8 resourceId, uint256 resourceAmount)
    public
    whenNotPaused
    entityExists(entityId)
{
    // This function would be complex. It would:
    // 1. Apply decay to the entity (_applyAccumulatedDecay).
    // 2. Look up InteractionType config (s_interactionTypes[interactionTypeId]).
    // 3. Handle resource transfer from user (msg.sender) or internal entity balance if required by interaction type.
    //    e.g., consumeResourceFromEntity(entityId, ...), or receive ERC20/ERC721 from msg.sender.
    // 4. Implement the interaction effects based on effectLogic, entity parameters, and interaction inputs.
    //    Effects could include: health/energy changes, parameter changes, resource grants (grantResourceToEntity),
    //    updating lastInteractionTime, incrementing interactionCount.
    // 5. Emit event.

     if (!s_interactionTypes[interactionTypeId].exists) revert ChronoForge__InteractionTypeNotSet(interactionTypeId);

     _applyAccumulatedDecay(entityId);

    // --- Simplified Placeholder Logic ---
    // Example: If resourceId and amount are provided, consume it
    if (resourceAmount > 0) {
        // This would ideally involve the user transferring tokens, not just consuming internal entity resources
        // For this example, let's simulate feeding internal resources if the type is consumable and entity has them.
        // A real version might integrate ERC20 transfers from msg.sender.
         if (s_resourceTypes[resourceId].exists && s_resourceTypes[resourceId].isConsumable) {
             uint256 entityBalance = s_entityResourceBalances[entityId][resourceId];
             uint256 toConsume = (entityBalance > resourceAmount) ? resourceAmount : entityBalance;
             s_entityResourceBalances[entityId][resourceId] -= toConsume;
             // Optional: Increase entity health/energy based on resource consumed
             s_entities[entityId].currentHealth += toConsume; // Dummy effect
             s_entities[entityId].currentEnergy += toConsume; // Dummy effect
         }
    }

    // Update interaction time and count
    s_entities[entityId].lastInteractionTime = block.timestamp;
    s_entities[entityId].interactionCount++;

    // Implement other effects based on interactionTypeId and entity parameters here
    // --- End Placeholder ---

    emit EntityInteractedWith(entityId, msg.sender, interactionTypeId);
}

/**
 * @dev Defines or updates an interaction type configuration. Governor only.
 * `effectLogic` is a placeholder for how the interaction impacts entities.
 * `requiredResourcesHash` and `outputResourcesHash` are placeholders for resource flows.
 * @param interactionTypeId The unique ID for the interaction type.
 * @param effectLogic Data describing the interaction effects (simplified bytes).
 * @param requiredResourcesHash Dummy hash representing resources required for interaction.
 * @param outputResourcesHash Dummy hash representing resources produced by interaction.
 */
function defineInteractionType(uint8 interactionTypeId, bytes memory effectLogic, uint256 requiredResourcesHash, uint256 outputResourcesHash)
    public
    whenNotPaused
    onlyGovernor
{
    s_interactionTypes[interactionTypeId] = InteractionType({
        effectLogic: effectLogic,
        requiredResourcesHash: requiredResourcesHash,
        outputResourcesHash: outputResourcesHash,
        exists: true
    });

    emit InteractionTypeDefined(interactionTypeId);
}

/**
 * @dev (View) Calculates the potential outcome of an interaction between two entities without executing it.
 * This would require complex off-chain logic or a dedicated on-chain simulation function.
 * For simplicity, this is a dummy placeholder.
 * @param entity1Id The ID of the first entity.
 * @param entity2Id The ID of the second entity.
 * @param interactionTypeId The ID of the interaction type.
 * @return A bytes array representing the potential outcome (dummy).
 */
function getPotentialInteractionEffects(uint256 entity1Id, uint256 entity2Id, uint8 interactionTypeId)
    public
    view
    entityExists(entity1Id)
    entityExists(entity2Id)
    returns (bytes memory)
{
     if (!s_interactionTypes[interactionTypeId].exists) revert ChronoForge__InteractionTypeNotSet(interactionTypeId);

     // This is a placeholder. Real implementation would require reading entity states,
     // interaction configs, and running the interaction logic (potentially in a pure/view context).
     // It might return simulated changes to health, energy, parameters, resources, etc.
     return s_interactionTypes[interactionTypeId].effectLogic; // Returning dummy effectLogic bytes
}


// 10. Governance/Configuration Functions

/**
 * @dev Transfers the governor role to a new address. Governor only.
 * @param newGovernor The address to transfer the role to.
 */
function setGovernor(address newGovernor) public onlyGovernor {
    if (newGovernor == address(0)) revert ChronoForge__CannotTransferToZeroAddress();
    address oldGovernor = s_governor;
    s_governor = newGovernor;
    emit GovernorSet(oldGovernor, newGovernor);
}

/**
 * @dev Adds or updates configuration for an evolution stage. Governor only.
 * Allows defining the requirements (time, interactions, resources - placeholder)
 * to evolve *to* this stage from the previous one (currentStageId + 1).
 * @param stageId The ID of the stage being configured.
 * @param timeToNextStage Seconds required since creation or last interaction.
 * @param interactionCountToNextStage Interactions required since last interaction.
 * @param requiredResourcesHash Dummy hash representing resource requirements for this stage.
 */
function addEvolutionStageConfig(uint8 stageId, uint256 timeToNextStage, uint256 interactionCountToNextStage, uint256 requiredResourcesHash)
    public
    whenNotPaused
    onlyGovernor
{
    s_evolutionStageConfig[stageId] = EvolutionStageConfig({
        timeToNextStage: timeToNextStage,
        interactionCountToNextStage: interactionCountToNextStage,
        requiredResourcesHash: requiredResourcesHash,
        exists: true
    });
    emit EvolutionStageConfigDefined(stageId);
}

/**
 * @dev Updates configuration for an existing evolution stage. Governor only.
 * Same parameters as addEvolutionStageConfig.
 * @param stageId The ID of the stage being updated.
 * @param timeToNextStage Seconds required since creation or last interaction.
 * @param interactionCountToNextStage Interactions required since last interaction.
 * @param requiredResourcesHash Dummy hash representing resource requirements for this stage.
 */
function updateEvolutionStageConfig(uint8 stageId, uint256 timeToNextStage, uint256 interactionCountToNextStage, uint256 requiredResourcesHash)
    public
    whenNotPaused
    onlyGovernor
{
    if (!s_evolutionStageConfig[stageId].exists) revert ChronoForge__StageConfigNotSet(stageId);

    s_evolutionStageConfig[stageId].timeToNextStage = timeToNextStage;
    s_evolutionStageConfig[stageId].interactionCountToNextStage = interactionCountToNextStage;
    s_evolutionStageConfig[stageId].requiredResourcesHash = requiredResourcesHash; // Update dummy hash
    // s_evolutionStageConfig[stageId].exists remains true

    emit EvolutionStageConfigDefined(stageId); // Use the same event
}


/**
 * @dev Sets a global system parameter. Governor only.
 * Allows flexible configuration of game/system variables.
 * @param key The bytes32 key for the parameter (e.g., keccak256("DECAY_RATE")).
 * @param value The uint256 value to set.
 */
function setGlobalParameter(bytes32 key, uint256 value)
    public
    whenNotPaused
    onlyGovernor
{
    s_globalParameters[key] = value;
    emit GlobalParameterSet(key, value);
}

/**
 * @dev Pauses core contract functionality (create, interact, evolve, consume, transfer entity/resource). Governor only.
 */
function pause() public onlyGovernor whenNotPaused {
    s_paused = true;
    emit Paused(msg.sender);
}

/**
 * @dev Unpauses core contract functionality. Governor only.
 */
function unpause() public onlyGovernor whenPaused {
    s_paused = false;
    emit Unpaused(msg.sender);
}


// 11. Query/Utility Functions

/**
 * @dev Returns the total number of entities created.
 * @return The total count.
 */
function getTotalEntities() public view returns (uint256) {
    return s_nextEntityId - 1; // Since IDs start from 1
}

/**
 * @dev Retrieves configuration details for an evolution stage.
 * @param stageId The ID of the stage.
 * @return The EvolutionStageConfig struct.
 */
function getEvolutionStageConfig(uint8 stageId)
    public
    view
    returns (EvolutionStageConfig memory)
{
     if (!s_evolutionStageConfig[stageId].exists) revert ChronoForge__StageConfigNotSet(stageId);
     return s_evolutionStageConfig[stageId];
}

/**
 * @dev Retrieves details for a resource type.
 * @param resourceId The ID of the resource type.
 * @return The ResourceType struct.
 */
function getResourceTypeDetails(uint8 resourceId)
    public
    view
    returns (ResourceType memory)
{
     if (!s_resourceTypes[resourceId].exists) revert ChronoForge__ResourceTypeNotSet(resourceId);
     return s_resourceTypes[resourceId];
}

/**
 * @dev Retrieves details for an interaction type.
 * @param interactionTypeId The ID of the interaction type.
 * @return The InteractionType struct.
 */
function getInteractionTypeDetails(uint8 interactionTypeId)
    public
    view
    returns (InteractionType memory)
{
     if (!s_interactionTypes[interactionTypeId].exists) revert ChronoForge__InteractionTypeNotSet(interactionTypeId);
     return s_interactionTypes[interactionTypeId];
}

/**
 * @dev Retrieves the value of a global system parameter.
 * Returns 0 if the parameter is not set.
 * @param key The bytes32 key for the parameter.
 * @return The uint256 value.
 */
function getGlobalParameter(bytes32 key) public view returns (uint256) {
    return s_globalParameters[key];
}

/**
 * @dev Pure function to calculate the next evolution stage ID based on the current one.
 * Simple increment in this example. Could be more complex (e.g., based on conditions).
 * @param currentStageId The current stage ID.
 * @return The calculated next stage ID.
 */
function calculateNextEvolutionStage(uint8 currentStageId) public pure returns (uint8) {
    // Simple linear evolution: stage 1 -> 2 -> 3 -> ...
    // Could implement complex branching or loops here if needed
    return currentStageId + 1;
}

// --- Internal View/Pure Helpers (Optional to expose as public views) ---

/*
// Example of an internal helper, potentially exposed as public view if needed
function _checkRequiredEvolutionResources(uint256 entityId, uint8 nextStageId) internal view returns (bool) {
    // This would look up the required resources for nextStageId (e.g., from a mapping)
    // and check s_entityResourceBalances[entityId] for sufficiency.
    // This is complex to implement generically with the current struct placeholders.
    // For now, relying on the dummy hash in the struct.
    // return true; // Assume resources are always sufficient in this simplified example
    return s_evolutionStageConfig[nextStageId].requiredResourcesHash > 0; // Dummy check based on hash existence
}
*/

}
```