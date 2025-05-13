Okay, let's create a complex, creative, and non-standard smart contract. We'll design a "Dimensional Nexus" - a system managing abstract dimensions, entities that can explore and interact with them, and various resources and mechanics.

This contract will involve concepts like:
*   **Dynamic State:** Dimensions and Entities have evolving properties (energy, stability, knowledge, inventory).
*   **Resource Management:** Multiple resource types (`NexusEnergy`, `KnowledgeFragments`, dimensional resources).
*   **Complex Interactions:** Exploring dimensions, harvesting resources, traveling, merging/splintering dimensions, adjusting dimensional properties.
*   **Access Control:** Ownership of dimensions, entity registration.
*   **Time-Based Mechanics:** Dimension state decay/regen based on time.
*   **Pseudo-Randomness:** Basic on-chain simulation elements for exploration outcomes.

It's important to note that complex logic and simulations on-chain are gas-intensive and constrained by block limits. This design is conceptual and showcases advanced ideas rather than being optimized for low gas costs or production-grade randomness.

---

## Dimensional Nexus Smart Contract

**Outline:**

1.  **License & Version Pragma:** Standard Solidity license and version.
2.  **Imports:** Use OpenZeppelin for `Ownable` and `Pausable` for standard admin patterns.
3.  **Errors:** Define custom errors for clearer failure reasons.
4.  **Events:** Define events to signal key state changes.
5.  **Data Structures:**
    *   `Dimension`: Struct to represent a dimension's properties.
    *   `Entity`: Struct to represent an explorer entity's properties.
6.  **State Variables:**
    *   Mappings for storing Dimensions and Entities.
    *   Counters for total dimensions/entities.
    *   Mapping for system parameters.
    *   Global resource pools (e.g., Nexus Energy pool).
    *   Temporary global event modifiers.
7.  **Modifiers:** Custom modifiers for access control and state checks.
8.  **Constructor:** Initialize the contract, set initial parameters.
9.  **Core Management Functions:** Create, claim, release, destroy dimensions. Register entities.
10. **Entity Action Functions:** Travel, explore, harvest, deposit, withdraw resources.
11. **Dimension Interaction Functions:** Stabilize, adjust frequency, infuse energy, sync state.
12. **Advanced/Complex Functions:** Merge dimensions, splinter dimensions, attune entity, catalyze reaction, transfer resources.
13. **System/Admin Functions:** Set parameters, trigger global events, withdraw fees, pause/unpause.
14. **Getter/View Functions:** Read state variables and struct details.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner, sets initial system parameters.
2.  `createDimension()`: Creates a new, unclaimed dimension with initial properties.
3.  `claimDimension(uint256 _dimensionId)`: Allows an entity to claim ownership of an unclaimed dimension by paying a cost.
4.  `releaseDimension(uint256 _dimensionId)`: Allows a dimension owner to relinquish ownership.
5.  `destroyDimension(uint256 _dimensionId)`: Allows an owner to destroy a dimension under certain conditions (e.g., low energy), potentially recovering some resources.
6.  `registerEntity()`: Registers the calling address as a new entity, initializing their state.
7.  `travelToDimension(uint256 _dimensionId)`: Allows an entity to change their current location to a specified dimension, potentially costing energy.
8.  `exploreDimension()`: Simulates an entity exploring their current dimension. Can discover resources, knowledge fragments, or trigger events based on dimension properties and a pseudo-random outcome. Costs entity energy.
9.  `harvestDimensionResource(bytes32 _resourceType, uint256 _amount)`: Allows an entity in a dimension to move a specific resource type from the dimension's pool to their inventory, costing energy and potentially reducing dimension stability.
10. `depositNexusEnergy(uint256 _amount)`: Allows an entity to deposit Nexus Energy from their balance into the global Nexus energy pool.
11. `depositDimensionEnergy(uint256 _dimensionId, uint256 _amount)`: Allows an entity to deposit Nexus Energy from their balance into a specific dimension's energy pool.
12. `withdrawNexusEnergy(uint256 _amount)`: Allows an entity to withdraw Nexus Energy from their balance (if available).
13. `stabilizeDimension(uint256 _dimensionId)`: Allows a dimension owner to spend energy or resources to increase their dimension's stability.
14. `adjustDimensionFrequency(uint256 _dimensionId, bytes32 _newFrequencySignature)`: Allows a dimension owner to change its frequency signature, potentially affecting exploration outcomes or interactions, costing knowledge fragments.
15. `syncDimensionState(uint256 _dimensionId)`: Public function to trigger a state update for a dimension based on time elapsed (decay, potential minor regen). Can be called by anyone.
16. `mergeDimensions(uint256 _dimensionId1, uint256 _dimensionId2)`: Allows an owner of two dimensions to merge them into one, combining resources and averaging properties, destroying one of the source dimensions. High cost and complexity.
17. `splinterDimension(uint256 _sourceDimensionId)`: Allows a dimension owner to create a new, unclaimed dimension derived from the source dimension, consuming resources from the source.
18. `attuneEntity(uint256 _dimensionId)`: Allows an entity to attune themselves to a dimension's frequency, costing knowledge and potentially granting bonuses when interacting with dimensions of similar frequencies.
19. `catalyzeReaction(bytes32 _recipeId)`: Allows an entity to trigger a defined resource transformation within their inventory or current dimension, consuming input resources and producing output resources based on a recipe. Costs energy.
20. `transferEntityResources(address _to, bytes32 _resourceType, uint256 _amount)`: Allows an entity to transfer resources from their inventory to another entity's inventory.
21. `transferDimensionResourcesToEntity(uint256 _dimensionId, address _to, bytes32 _resourceType, uint256 _amount)`: Allows a dimension owner to transfer resources from their dimension's pool to an entity's inventory.
22. `setSystemParameter(bytes32 _paramName, uint256 _paramValue)`: Owner function to adjust system parameters.
23. `triggerGlobalEvent(bytes32 _eventType, uint256 _intensity, uint40 _duration)`: Owner function to apply temporary global modifiers affecting dimension or entity state.
24. `withdrawProtocolFees(address payable _to, uint256 _amount)`: Owner function to withdraw funds/energy collected by the protocol.
25. `getDimensionDetails(uint256 _dimensionId)`: View function to get details of a specific dimension.
26. `getEntityDetails(address _entityAddress)`: View function to get details of a specific entity.
27. `getSystemParameter(bytes32 _paramName)`: View function to get the value of a system parameter.
28. `listDimensions(uint256 _offset, uint256 _limit)`: View function to list a range of dimension IDs.
29. `dimensionExists(uint256 _dimensionId)`: View function to check if a dimension ID is valid.
30. `entityExists(address _entityAddress)`: View function to check if an address is a registered entity.
31. `pause()`: Owner function to pause contract interactions.
32. `unpause()`: Owner function to unpause contract interactions.
33. `renounceOwnership()`: Standard Ownable function.
34. `transferOwnership(address newOwner)`: Standard Ownable function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For utility functions like min/max if needed, or simple math is fine.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Example if using an external ERC20 for costs/resources

// Note: On-chain pseudo-randomness is insecure for high-value applications.
// This contract uses block hash and timestamp for demonstration purposes only.
// For production, consider Chainlink VRF or similar solutions.

/// @title DimensionalNexus
/// @dev A complex smart contract simulating abstract dimensions, exploring entities, and resource management.
/// Features dynamic state, complex interactions, and various resource types.

contract DimensionalNexus is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Custom Errors ---
    error DimensionNotFound(uint256 dimensionId);
    error DimensionNotUnclaimed(uint256 dimensionId);
    error DimensionAlreadyClaimed(uint256 dimensionId);
    error NotDimensionOwner(uint256 dimensionId);
    error EntityNotFound(address entityAddress);
    error EntityAlreadyRegistered(address entityAddress);
    error InsufficientNexusEnergy(uint256 required, uint256 available);
    error InsufficientEntityResource(bytes32 resourceType, uint256 required, uint256 available);
    error InsufficientDimensionResource(uint256 dimensionId, bytes32 resourceType, uint256 required, uint256 available);
    error InvalidDimensionState(uint256 dimensionId, string reason);
    error InvalidParameter(bytes32 paramName);
    error InvalidRecipe(bytes32 recipeId);
    error InvalidResourceAmount(uint256 amount);
    error TransferFailed();
    error NotInValidDimension();
    error SourceAndTargetSame(uint256 id);

    // --- Events ---
    event DimensionCreated(uint256 indexed dimensionId, address indexed creator, bytes32 initialFrequency);
    event DimensionClaimed(uint256 indexed dimensionId, address indexed newOwner);
    event DimensionReleased(uint256 indexed dimensionId, address indexed oldOwner);
    event DimensionDestroyed(uint256 indexed dimensionId, address indexed owner);
    event EntityRegistered(address indexed entityAddress);
    event EntityTraveled(address indexed entityAddress, uint256 indexed fromDimensionId, uint256 indexed toDimensionId);
    event EntityExplored(address indexed entityAddress, uint256 indexed dimensionId, uint256 knowledgeGained, uint256 energyConsumed);
    event ResourceHarvested(address indexed entityAddress, uint256 indexed dimensionId, bytes32 resourceType, uint256 amount);
    event NexusEnergyDeposited(address indexed entityAddress, uint256 amount);
    event DimensionEnergyDeposited(address indexed entityAddress, uint256 indexed dimensionId, uint256 amount);
    event NexusEnergyWithdrawn(address indexed entityAddress, uint256 amount);
    event DimensionStabilized(uint256 indexed dimensionId, address indexed entityAddress, uint256 stabilityIncrease);
    event DimensionFrequencyAdjusted(uint256 indexed dimensionId, address indexed entityAddress, bytes32 oldFrequency, bytes32 newFrequency);
    event DimensionStateSynced(uint256 indexed dimensionId, uint40 lastSyncTime, uint256 energyChange, int256 stabilityChange);
    event DimensionsMerged(uint256 indexed primaryDimensionId, uint256 indexed mergedDimensionId, address indexed owner);
    event DimensionSplintered(uint256 indexed sourceDimensionId, uint256 indexed newDimensionId, address indexed owner);
    event EntityAttuned(address indexed entityAddress, uint256 indexed dimensionId);
    event ReactionCatalyzed(address indexed entityAddress, bytes32 indexed recipeId, uint256 dimensionId);
    event EntityResourceTransferred(address indexed from, address indexed to, bytes32 resourceType, uint256 amount);
    event DimensionResourceTransferredToEntity(address indexed fromDimensionOwner, uint256 indexed dimensionId, address indexed toEntity, bytes32 resourceType, uint256 amount);
    event SystemParameterSet(bytes32 indexed paramName, uint256 value);
    event GlobalEventTriggered(bytes32 indexed eventType, uint256 intensity, uint40 duration);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- Data Structures ---

    /// @dev Represents an abstract dimension or reality space.
    struct Dimension {
        uint256 id;
        address owner; // Address(0) for unclaimed
        uint256 energyLevel; // Primary resource pool within the dimension
        uint16 stability; // Affects decay/regen and event outcomes (0-1000)
        bytes32 frequencySignature; // Unique identifier/seed for random events
        uint40 genesisTimestamp; // When the dimension was created
        uint40 lastInteraction; // Timestamp of last significant interaction (for state sync)
        mapping(bytes32 => uint256) dimensionalResources; // Specific resources unique to this dimension
    }

    /// @dev Represents an explorer entity interacting with the Nexus.
    struct Entity {
        address entityAddress;
        uint256 nexusEnergy; // Resource held by the entity, usable across the Nexus
        uint256 knowledgeFragments; // Resource gained through exploration, unlocks features
        uint256 currentDimensionId; // ID of the dimension the entity is currently in
        mapping(bytes32 => uint256) inventory; // Resources held by the entity
        mapping(uint256 => bool) attunedDimensions; // Dimensions the entity is attuned to
    }

    /// @dev Represents a recipe for resource transformation.
    struct Recipe {
        mapping(bytes32 => uint256) inputs;
        mapping(bytes32 => uint256) outputs;
        uint256 energyCost;
        uint256 knowledgeCost;
    }

    // --- State Variables ---

    Counters.Counter private _dimensionIds;
    mapping(uint256 => Dimension) private dimensions;
    mapping(address => Entity) private entities;
    mapping(address => bool) private isRegisteredEntity; // Quick check for entity existence

    mapping(bytes32 => uint256) public systemParameters;

    // Global pool for Nexus Energy collected by the protocol
    uint256 public globalNexusEnergyPool;

    // Mapping for catalyzed reaction recipes (recipeId => Recipe)
    mapping(bytes32 => Recipe) private recipes;

    // Temporary global event modifiers (type => value)
    mapping(bytes32 => uint256) private globalEventModifiers;
    mapping(bytes32 => uint40) private globalEventEndTimestamps;

    // --- Constants (using bytes32 for parameter names/resource types) ---
    bytes32 public constant PARAM_DIMENSION_CREATION_COST = "dimensionCreationCost";
    bytes32 public constant PARAM_DIMENSION_CLAIM_COST = "dimensionClaimCost";
    bytes32 public constant PARAM_EXPLORE_ENERGY_COST = "exploreEnergyCost";
    bytes32 public constant PARAM_HARVEST_ENERGY_COST = "harvestEnergyCost";
    bytes32 public constant PARAM_TRAVEL_ENERGY_COST = "travelEnergyCost";
    bytes32 public constant PARAM_STABILIZE_KNOWLEDGE_COST = "stabilizeKnowledgeCost";
    bytes32 public constant PARAM_FREQUENCY_ADJUST_KNOWLEDGE_COST = "freqAdjustKnowledgeCost";
    bytes32 public constant PARAM_DIMENSION_DECAY_RATE_PER_DAY = "dimDecayRatePerDay"; // In energy units per day
    bytes32 public constant PARAM_MIN_STABILITY_FOR_SYNC = "minStabilityForSync"; // Below this, decay is faster
    bytes32 public constant PARAM_MERGE_ENERGY_COST = "mergeEnergyCost";
    bytes32 public constant PARAM_SPLINTER_ENERGY_COST = "splinterEnergyCost";
    bytes32 public constant PARAM_ATTUNE_KNOWLEDGE_COST = "attuneKnowledgeCost";
    bytes32 public constant PARAM_ENTITY_REGISTER_ENERGY = "entityRegisterEnergy"; // Initial energy for new entities
    bytes32 public constant PARAM_ENTITY_REGISTER_KNOWLEDGE = "entityRegisterKnowledge"; // Initial knowledge

    bytes32 public constant RESOURCE_NEXUS_ENERGY = "NexusEnergy";
    bytes32 public constant RESOURCE_KNOWLEDGE_FRAGMENT = "KnowledgeFragment";

    bytes32 public constant EVENT_ENERGY_SURGE = "EnergySurge"; // Increases all energy levels
    bytes32 public constant EVENT_STABILITY_FLUX = "StabilityFlux"; // Makes stability volatile

    uint256 private constant DIMENSION_ID_HUB = 0; // Reserved ID for a potential hub dimension

    // --- Modifiers ---

    modifier onlyExistingDimension(uint256 _dimensionId) {
        if (!dimensionExists(_dimensionId)) revert DimensionNotFound(_dimensionId);
        _;
    }

    modifier onlyExistingEntity(address _entityAddress) {
        if (!entityExists(_entityAddress)) revert EntityNotFound(_entityAddress);
        _;
    }

    modifier onlyDimensionOwner(uint256 _dimensionId) {
        if (!dimensionExists(_dimensionId)) revert DimensionNotFound(_dimensionId);
        if (dimensions[_dimensionId].owner != _msgSender()) revert NotDimensionOwner(_dimensionId);
        _;
    }

    modifier onlyUnclaimedDimension(uint256 _dimensionId) {
         if (!dimensionExists(_dimensionId)) revert DimensionNotFound(_dimensionId);
         if (dimensions[_dimensionId].owner != address(0)) revert DimensionAlreadyClaimed(_dimensionId);
        _;
    }

     modifier onlyClaimedDimension(uint256 _dimensionId) {
         if (!dimensionExists(_dimensionId)) revert DimensionNotFound(_dimensionId);
         if (dimensions[_dimensionId].owner == address(0)) revert DimensionNotUnclaimed(_dimensionId);
        _;
    }

    modifier onlyInValidDimension() {
        if (entities[_msgSender()].currentDimensionId == DIMENSION_ID_HUB) revert NotInValidDimension(); // Example: hub is not explorable/harvestable
        _;
    }


    // --- Constructor ---

    constructor() Ownable(_msgSender()) Pausable() {
        // Set initial system parameters
        systemParameters[PARAM_DIMENSION_CREATION_COST] = 100;
        systemParameters[PARAM_DIMENSION_CLAIM_COST] = 500;
        systemParameters[PARAM_EXPLORE_ENERGY_COST] = 10;
        systemParameters[PARAM_HARVEST_ENERGY_COST] = 5;
        systemParameters[PARAM_TRAVEL_ENERGY_COST] = 20;
        systemParameters[PARAM_STABILIZE_KNOWLEDGE_COST] = 50;
        systemParameters[PARAM_FREQUENCY_ADJUST_KNOWLEDGE_COST] = 100;
        systemParameters[PARAM_DIMENSION_DECAY_RATE_PER_DAY] = 1000; // 1000 energy decay per day
        systemParameters[PARAM_MIN_STABILITY_FOR_SYNC] = 300; // Below 300 stability, decay is faster
        systemParameters[PARAM_MERGE_ENERGY_COST] = 5000;
        systemParameters[PARAM_SPLINTER_ENERGY_COST] = 2000;
        systemParameters[PARAM_ATTUNE_KNOWLEDGE_COST] = 150;
        systemParameters[PARAM_ENTITY_REGISTER_ENERGY] = 50;
        systemParameters[PARAM_ENTITY_REGISTER_KNOWLEDGE] = 5;

        // Create the initial Hub Dimension (ID 0) - non-claimable, safe zone
         dimensions[DIMENSION_ID_HUB] = Dimension({
            id: DIMENSION_ID_HUB,
            owner: address(0), // Cannot be claimed
            energyLevel: 1e18, // Large initial energy
            stability: 1000, // Max stability
            frequencySignature: bytes32(uint256(keccak256("NexusHubFrequency"))),
            genesisTimestamp: uint40(block.timestamp),
            lastInteraction: uint40(block.timestamp)
         });
         _dimensionIds.increment(); // Increment past 0

        // Define some example recipes (using hardcoded bytes32 keys for simplicity)
        bytes32 recipeId1 = keccak256("BasicConversion");
        recipes[recipeId1].inputs[bytes32(uint256(1))] = 10; // Example resource ID 1
        recipes[recipeId1].inputs[RESOURCE_NEXUS_ENERGY] = 5;
        recipes[recipeId1].outputs[bytes32(uint256(2))] = 3; // Example resource ID 2
        recipes[recipeId1].energyCost = 10;
        recipes[recipeId1].knowledgeCost = 1;

         bytes32 recipeId2 = keccak256("AdvancedSynthesis");
        recipes[recipeId2].inputs[bytes32(uint256(2))] = 5; // Example resource ID 2
        recipes[recipeId2].inputs[RESOURCE_KNOWLEDGE_FRAGMENT] = 10;
        recipes[recipeId2].outputs[bytes32(uint256(3))] = 1; // Example resource ID 3 (more rare)
        recipes[recipeId2].energyCost = 50;
        recipes[recipeId2].knowledgeCost = 10;
    }

    // --- Core Management Functions ---

    /// @dev Creates a new, unclaimed dimension.
    /// @return The ID of the newly created dimension.
    function createDimension() public whenNotPaused returns (uint256) {
        uint256 newDimensionId = _dimensionIds.current();
        _dimensionIds.increment();

        // Simple pseudo-random frequency based on block data
        bytes32 initialFrequency = bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newDimensionId))));

        dimensions[newDimensionId] = Dimension({
            id: newDimensionId,
            owner: address(0),
            energyLevel: 1000, // Initial energy
            stability: 500, // Initial stability
            frequencySignature: initialFrequency,
            genesisTimestamp: uint40(block.timestamp),
            lastInteraction: uint40(block.timestamp)
        });

        emit DimensionCreated(newDimensionId, _msgSender(), initialFrequency);
        return newDimensionId;
    }

    /// @dev Allows an entity to claim ownership of an unclaimed dimension.
    /// @param _dimensionId The ID of the dimension to claim.
    function claimDimension(uint256 _dimensionId) public whenNotPaused onlyExistingEntity(_msgSender()) onlyUnclaimedDimension(_dimensionId) {
        uint256 claimCost = systemParameters[PARAM_DIMENSION_CLAIM_COST];
        Entity storage entity = entities[_msgSender()];

        if (entity.nexusEnergy < claimCost) revert InsufficientNexusEnergy(claimCost, entity.nexusEnergy);

        entity.nexusEnergy -= claimCost;
        dimensions[_dimensionId].owner = _msgSender();

        emit DimensionClaimed(_dimensionId, _msgSender());
    }

    /// @dev Allows a dimension owner to release ownership. Dimension becomes unclaimed.
    /// Resources might be partially lost or returned.
    /// @param _dimensionId The ID of the dimension to release.
    function releaseDimension(uint256 _dimensionId) public whenNotPaused onlyDimensionOwner(_dimensionId) {
        dimensions[_dimensionId].owner = address(0);
        // Optional: Implement logic for resource decay/loss upon release
        // Example: dimensions[_dimensionId].energyLevel = dimensions[_dimensionId].energyLevel / 2;

        emit DimensionReleased(_dimensionId, _msgSender());
    }

    /// @dev Allows a dimension owner to destroy their dimension. Requires low energy.
    /// Resources are lost, owner might get a small refund.
    /// @param _dimensionId The ID of the dimension to destroy.
    function destroyDimension(uint256 _dimensionId) public whenNotPaused onlyDimensionOwner(_dimensionId) {
         if (_dimensionId == DIMENSION_ID_HUB) revert InvalidDimensionState(_dimensionId, "Hub dimension cannot be destroyed");
         // Example condition: must have very low energy
         if (dimensions[_dimensionId].energyLevel > 100) revert InvalidDimensionState(_dimensionId, "Dimension energy too high to destroy");

         // Optional: refund a small percentage of potential original cost or remaining energy
         uint256 refundAmount = dimensions[_dimensionId].energyLevel / 10; // Example refund

         // Clear data (Solidity auto-clears mapping entries when struct is deleted/overwritten)
         delete dimensions[_dimensionId];
         // Note: This leaves gaps in the dimension ID sequence, but the mapping handles it.

         entities[_msgSender()].nexusEnergy += refundAmount; // Refund to owner

         emit DimensionDestroyed(_dimensionId, _msgSender());
    }

    /// @dev Registers the calling address as a new entity.
    function registerEntity() public whenNotPaused {
        if (isRegisteredEntity[_msgSender()]) revert EntityAlreadyRegistered(_msgSender());

        entities[_msgSender()] = Entity({
            entityAddress: _msgSender(),
            nexusEnergy: systemParameters[PARAM_ENTITY_REGISTER_ENERGY], // Starting energy
            knowledgeFragments: systemParameters[PARAM_ENTITY_REGISTER_KNOWLEDGE], // Starting knowledge
            currentDimensionId: DIMENSION_ID_HUB, // Start in the Hub
            inventory: new mapping(bytes32 => uint256)(), // Initialize empty inventory
            attunedDimensions: new mapping(uint256 => bool)() // Initialize empty attunement
        });
        isRegisteredEntity[_msgSender()] = true;

        emit EntityRegistered(_msgSender());
    }

    // --- Entity Action Functions ---

    /// @dev Allows an entity to travel to another dimension.
    /// @param _dimensionId The ID of the dimension to travel to.
    function travelToDimension(uint256 _dimensionId) public whenNotPaused onlyExistingEntity(_msgSender()) onlyExistingDimension(_dimensionId) {
        Entity storage entity = entities[_msgSender()];
        uint256 travelCost = systemParameters[PARAM_TRAVEL_ENERGY_COST];

        if (entity.nexusEnergy < travelCost) revert InsufficientNexusEnergy(travelCost, entity.nexusEnergy);
        if (entity.currentDimensionId == _dimensionId) revert InvalidDimensionState(_dimensionId, "Already in this dimension");

        uint256 fromDimensionId = entity.currentDimensionId;
        entity.nexusEnergy -= travelCost;
        entity.currentDimensionId = _dimensionId;

        emit EntityTraveled(_msgSender(), fromDimensionId, _dimensionId);
    }

    /// @dev Simulates exploration in the entity's current dimension.
    /// Potential outcomes include finding resources, knowledge, or triggering mini-events.
    function exploreDimension() public whenNotPaused onlyExistingEntity(_msgSender()) onlyInValidDimension() {
        Entity storage entity = entities[_msgSender()];
        uint256 dimensionId = entity.currentDimensionId;
        Dimension storage dimension = dimensions[dimensionId]; // Assumed existence by onlyInValidDimension/onlyExistingDimension from travel

        uint256 exploreCost = systemParameters[PARAM_EXPLORE_ENERGY_COST];
        if (entity.nexusEnergy < exploreCost) revert InsufficientNexusEnergy(exploreCost, entity.nexusEnergy);
        entity.nexusEnergy -= exploreCost;

        // Sync dimension state before exploration to account for decay/regen
        _syncDimensionState(dimensionId);

        // Simple pseudo-randomness based on block data and dimension frequency
        // NOT SECURE FOR HIGH-VALUE USE CASES
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, dimension.frequencySignature, dimension.lastInteraction)));
        uint256 outcomeRoll = randSeed % 1000; // Roll between 0 and 999

        uint256 knowledgeGained = 0;
        // Example logic: higher stability -> more predictable, less chance of negative events, moderate resource/knowledge gain
        // Lower stability -> more volatile, chance of higher gains, higher chance of decay/negative events

        if (outcomeRoll < dimension.stability) {
            // Relatively stable outcome: moderate knowledge, some basic resources
            knowledgeGained = 5 + (outcomeRoll % 10); // Base + small variance
            // Example: Gain a basic resource type (using a hardcoded ID for simplicity)
            bytes32 basicResource = bytes32(uint256(1));
            uint256 resourceAmount = 1 + (outcomeRoll % 5);
             // Note: Simplified - resources should exist in dimension to harvest.
             // A more complex version would check dimension.dimensionalResources and move from there.
             // For this example, we 'find'/generate it in entity inventory directly for simplicity.
            entity.inventory[basicResource] += resourceAmount;
             // dimension.energyLevel = dimension.energyLevel >= resourceAmount ? dimension.energyLevel - resourceAmount : 0; // Consume resource from dim

        } else {
            // Unstable outcome: chance for higher knowledge/rare resources, or negative effects
            if (outcomeRoll % 2 == 0) {
                // Positive volatile outcome: Higher knowledge or rarer resources
                 knowledgeGained = 10 + (outcomeRoll % 20);
                 bytes32 rareResource = bytes32(uint256(3)); // Example rare resource
                 uint256 rareResourceAmount = 1 + (outcomeRoll % 2);
                 // Again, simplified direct addition to inventory
                 entity.inventory[rareResource] += rareResourceAmount;
                 // dimension.energyLevel = dimension.energyLevel >= rareResourceAmount * 10 ? dimension.energyLevel - rareResourceAmount * 10 : 0; // Higher cost from dim
            } else {
                // Negative volatile outcome: Lose energy, dimension stability decreases
                uint256 energyLoss = 5 + (outcomeRoll % 15);
                entity.nexusEnergy = entity.nexusEnergy >= energyLoss ? entity.nexusEnergy - energyLoss : 0;
                dimension.stability = dimension.stability >= 20 ? dimension.stability - 20 : 0; // Reduce stability significantly
            }
        }

        entity.knowledgeFragments += knowledgeGained;
        dimension.lastInteraction = uint40(block.timestamp); // Update interaction time

        emit EntityExplored(_msgSender(), dimensionId, knowledgeGained, exploreCost);
    }

    /// @dev Allows an entity to harvest resources from their current dimension.
    /// Requires ownership or special permission (not implemented).
    /// @param _resourceType The type of resource to harvest.
    /// @param _amount The amount of resource to harvest.
    function harvestDimensionResource(bytes32 _resourceType, uint256 _amount) public whenNotPaused onlyExistingEntity(_msgSender()) onlyInValidDimension() {
        if (_amount == 0) revert InvalidResourceAmount(_amount);

        Entity storage entity = entities[_msgSender()];
        uint256 dimensionId = entity.currentDimensionId;
        Dimension storage dimension = dimensions[dimensionId];

        // Check ownership or permission - simplified to owner for now
        if (dimension.owner != _msgSender()) revert NotDimensionOwner(dimensionId);

        // Sync state
        _syncDimensionState(dimensionId);

        // Check if resource exists in dimension and enough is available
        if (dimension.dimensionalResources[_resourceType] < _amount) {
            revert InsufficientDimensionResource(dimensionId, _resourceType, _amount, dimension.dimensionalResources[_resourceType]);
        }

        // Check entity energy cost
        uint26 energyCost = systemParameters[PARAM_HARVEST_ENERGY_COST];
        if (entity.nexusEnergy < energyCost) revert InsufficientNexusEnergy(energyCost, entity.nexusEnergy);

        // Perform transfer
        dimension.dimensionalResources[_resourceType] -= _amount;
        entity.inventory[_resourceType] += _amount;
        entity.nexusEnergy -= energyCost;
        dimension.stability = dimension.stability >= 5 ? dimension.stability - 5 : 0; // Small stability cost for harvesting
        dimension.lastInteraction = uint40(block.timestamp);

        emit ResourceHarvested(_msgSender(), dimensionId, _resourceType, _amount);
    }

    /// @dev Allows an entity to deposit Nexus Energy into the global pool.
    /// @param _amount The amount of Nexus Energy to deposit.
    function depositNexusEnergy(uint256 _amount) public whenNotPaused onlyExistingEntity(_msgSender()) {
        if (_amount == 0) revert InvalidResourceAmount(_amount);

        Entity storage entity = entities[_msgSender()];
        if (entity.nexusEnergy < _amount) revert InsufficientEntityResource(RESOURCE_NEXUS_ENERGY, _amount, entity.nexusEnergy);

        entity.nexusEnergy -= _amount;
        globalNexusEnergyPool += _amount;

        emit NexusEnergyDeposited(_msgSender(), _amount);
    }

     /// @dev Allows an entity to deposit Nexus Energy into a dimension's pool.
    /// @param _dimensionId The ID of the dimension.
    /// @param _amount The amount of Nexus Energy to deposit.
    function depositDimensionEnergy(uint256 _dimensionId, uint256 _amount) public whenNotPaused onlyExistingEntity(_msgSender()) onlyExistingDimension(_dimensionId) {
        if (_amount == 0) revert InvalidResourceAmount(_amount);

        Entity storage entity = entities[_msgSender()];
        if (entity.nexusEnergy < _amount) revert InsufficientEntityResource(RESOURCE_NEXUS_ENERGY, _amount, entity.nexusEnergy);

        entity.nexusEnergy -= _amount;
        dimensions[_dimensionId].energyLevel += _amount;
        dimensions[_dimensionId].lastInteraction = uint40(block.timestamp);


        emit DimensionEnergyDeposited(_msgSender(), _dimensionId, _amount);
    }


    /// @dev Allows an entity to withdraw Nexus Energy from their balance.
    /// @param _amount The amount of Nexus Energy to withdraw.
    function withdrawNexusEnergy(uint256 _amount) public whenNotPaused onlyExistingEntity(_msgSender()) {
         if (_amount == 0) revert InvalidResourceAmount(_amount);

        Entity storage entity = entities[_msgSender()];
        if (entity.nexusEnergy < _amount) revert InsufficientEntityResource(RESOURCE_NEXUS_ENERGY, _amount, entity.nexusEnergy);

        entity.nexusEnergy -= _amount;
        // Note: This function withdraws from the *entity's* balance, not the global pool or dimension pool.
        // If you wanted to withdraw from global/dimension pools, specific functions and permissions would be needed.
        // A real implementation might involve transferring an ERC20 token representing Nexus Energy.
        // Here, it just reduces the internal balance.

        emit NexusEnergyWithdrawn(_msgSender(), _amount);
    }


    // --- Dimension Interaction Functions ---

    /// @dev Allows a dimension owner to increase its stability. Costs knowledge.
    /// @param _dimensionId The ID of the dimension.
    function stabilizeDimension(uint256 _dimensionId) public whenNotPaused onlyDimensionOwner(_dimensionId) {
        Entity storage entity = entities[_msgSender()];
        uint256 knowledgeCost = systemParameters[PARAM_STABILIZE_KNOWLEDGE_COST];

        if (entity.knowledgeFragments < knowledgeCost) revert InsufficientEntityResource(RESOURCE_KNOWLEDGE_FRAGMENT, knowledgeCost, entity.knowledgeFragments);

        entity.knowledgeFragments -= knowledgeCost;
        uint16 stabilityIncrease = 50; // Example fixed increase
        dimensions[_dimensionId].stability = Math.min(dimensions[_dimensionId].stability + stabilityIncrease, 1000); // Cap stability at 1000
        dimensions[_dimensionId].lastInteraction = uint40(block.timestamp);


        emit DimensionStabilized(_dimensionId, _msgSender(), stabilityIncrease);
    }

    /// @dev Allows a dimension owner to adjust its frequency signature. Costs knowledge.
    /// Affects outcomes of exploration and potential attunement bonuses.
    /// @param _dimensionId The ID of the dimension.
    /// @param _newFrequencySignature The new desired frequency signature.
    function adjustDimensionFrequency(uint256 _dimensionId, bytes32 _newFrequencySignature) public whenNotPaused onlyDimensionOwner(_dimensionId) {
        Entity storage entity = entities[_msgSender()];
        uint256 knowledgeCost = systemParameters[PARAM_FREQUENCY_ADJUST_KNOWLEDGE_COST];

        if (entity.knowledgeFragments < knowledgeCost) revert InsufficientEntityResource(RESOURCE_KNOWLEDGE_FRAGMENT, knowledgeCost, entity.knowledgeFragments);

        entity.knowledgeFragments -= knowledgeCost;
        bytes32 oldFrequency = dimensions[_dimensionId].frequencySignature;
        dimensions[_dimensionId].frequencySignature = _newFrequencySignature;
        dimensions[_dimensionId].lastInteraction = uint40(block.timestamp);


        emit DimensionFrequencyAdjusted(_dimensionId, _msgSender(), oldFrequency, _newFrequencySignature);
    }

    /// @dev Updates a dimension's state based on time elapsed since last interaction.
    /// Public function allowing anyone to trigger updates (potentially for incentives).
    /// Applies decay logic based on stability and time.
    /// @param _dimensionId The ID of the dimension to sync.
    function syncDimensionState(uint256 _dimensionId) public whenNotPaused onlyExistingDimension(_dimensionId) {
        _syncDimensionState(_dimensionId);
    }

    /// @dev Internal helper to sync a dimension's state.
    /// @param _dimensionId The ID of the dimension to sync.
    function _syncDimensionState(uint256 _dimensionId) internal {
        Dimension storage dimension = dimensions[_dimensionId];
        uint40 currentTime = uint40(block.timestamp);
        uint40 timeElapsed = currentTime - dimension.lastInteraction;

        if (timeElapsed == 0) {
            // No time has passed since last interaction, no sync needed
            return;
        }

        uint256 decayRatePerDay = systemParameters[PARAM_DIMENSION_DECAY_RATE_PER_DAY];
        uint256 minStabilityForFastDecay = systemParameters[PARAM_MIN_STABILITY_FOR_SYNC];

        // Calculate energy decay
        uint256 energyDecayPerSecond = decayRatePerDay / (1 days);
        uint256 totalEnergyDecay = energyDecayPerSecond * timeElapsed;

        // Adjust decay based on stability
        if (dimension.stability < minStabilityForFastDecay) {
            totalEnergyDecay = totalEnergyDecay * 2; // Double decay if stability is low (example)
        }

        uint256 energyChange = totalEnergyDecay;
        int256 stabilityChange = 0; // Stability changes can be added here based on events/parameters

        if (dimension.energyLevel < totalEnergyDecay) {
            dimension.energyLevel = 0;
        } else {
            dimension.energyLevel -= totalEnergyDecay;
        }

        dimension.lastInteraction = currentTime;

        emit DimensionStateSynced(_dimensionId, currentTime, energyChange, stabilityChange);
    }

    // --- Advanced/Complex Functions ---

    /// @dev Allows a dimension owner to merge two of their dimensions.
    /// Combines resources, averages/sums properties, destroys the second dimension.
    /// High energy/resource cost.
    /// @param _primaryDimensionId The ID of the dimension to keep (resources merge into this).
    /// @param _mergedDimensionId The ID of the dimension to merge and destroy.
    function mergeDimensions(uint256 _primaryDimensionId, uint256 _mergedDimensionId) public whenNotPaused onlyDimensionOwner(_primaryDimensionId) onlyDimensionOwner(_mergedDimensionId) {
        if (_primaryDimensionId == _mergedDimensionId) revert SourceAndTargetSame(_primaryDimensionId);

        Entity storage entity = entities[_msgSender()];
        uint26 mergeCost = systemParameters[PARAM_MERGE_ENERGY_COST];
        if (entity.nexusEnergy < mergeCost) revert InsufficientNexusEnergy(mergeCost, entity.nexusEnergy);

        Dimension storage primaryDim = dimensions[_primaryDimensionId];
        Dimension storage mergedDim = dimensions[_mergedDimensionId];

        // Sync states before merging
        _syncDimensionState(_primaryDimensionId);
        _syncDimensionState(_mergedDimensionId);

        // Combine energy
        primaryDim.energyLevel += mergedDim.energyLevel;

        // Combine resources (iterate through mergedDim's resources - requires iteration helper or known keys)
        // For simplicity, let's assume a few resource keys are known or just add all from mergedDim.
        // A production contract would need careful iteration or a fixed list of resource types.
        // Example for known keys:
        bytes32 res1 = bytes32(uint256(1));
        bytes32 res2 = bytes32(uint256(2));
        bytes32 res3 = bytes32(uint256(3));
        primaryDim.dimensionalResources[res1] += mergedDim.dimensionalResources[res1];
        primaryDim.dimensionalResources[res2] += mergedDim.dimensionalResources[res2];
        primaryDim.dimensionalResources[res3] += mergedDim.dimensionalResources[res3];
        // Note: A truly dynamic resource system needs different state representation or off-chain indexing.

        // Average stability (simple example)
        primaryDim.stability = uint16((uint256(primaryDim.stability) + mergedDim.stability) / 2);

        // Frequency signature might become a blend or dominant one - complex. Let's leave primary's for simplicity.

        // Update last interaction time
        primaryDim.lastInteraction = uint40(block.timestamp);

        // Consume energy cost
        entity.nexusEnergy -= mergeCost;

        // Destroy the merged dimension
        delete dimensions[_mergedDimensionId];
        // Note: This leaves a gap in IDs but is handled by the mapping.

        emit DimensionsMerged(_primaryDimensionId, _mergedDimensionId, _msgSender());
    }

    /// @dev Allows a dimension owner to splinter their dimension into a new, smaller, unclaimed one.
    /// Costs resources and energy from the source dimension, creates a new dimension.
    /// @param _sourceDimensionId The ID of the dimension to splinter.
    /// @return The ID of the newly created splinter dimension.
    function splinterDimension(uint256 _sourceDimensionId) public whenNotPaused onlyDimensionOwner(_sourceDimensionId) returns (uint256) {
        if (_sourceDimensionId == DIMENSION_ID_HUB) revert InvalidDimensionState(_sourceDimensionId, "Hub dimension cannot be splintered");

        Entity storage entity = entities[_msgSender()];
        uint26 splinterCost = systemParameters[PARAM_SPLINTER_ENERGY_COST];
        if (entity.nexusEnergy < splinterCost) revert InsufficientNexusEnergy(splinterCost, entity.nexusEnergy);

        Dimension storage sourceDim = dimensions[_sourceDimensionId];

        // Sync state
        _syncDimensionState(_sourceDimensionId);

        // Check if source dimension has enough energy/resources to splinter
        if (sourceDim.energyLevel < 1000) revert InvalidDimensionState(_sourceDimensionId, "Source dimension energy too low to splinter");

        uint256 newDimensionId = _dimensionIds.current();
        _dimensionIds.increment();

        // Derive new dimension properties from the source
        uint256 splinterEnergy = sourceDim.energyLevel / 4; // Splinter takes 25% energy
        uint16 splinterStability = uint16(uint256(sourceDim.stability) / 2); // Splinter is less stable
        bytes32 splinterFrequency = bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, sourceDim.frequencySignature, newDimensionId)))); // New frequency based on source

        // Deduct cost from source dimension and entity
        sourceDim.energyLevel -= splinterEnergy; // Energy transferred
        entity.nexusEnergy -= splinterCost; // Entity energy cost

        // Optionally, transfer some resources from source dimension to new dimension
         bytes32 res1 = bytes32(uint256(1));
         uint256 res1Transfer = sourceDim.dimensionalResources[res1] / 2;
         sourceDim.dimensionalResources[res1] -= res1Transfer;


        // Create the new splinter dimension
        dimensions[newDimensionId] = Dimension({
            id: newDimensionId,
            owner: address(0), // Unclaimed
            energyLevel: splinterEnergy,
            stability: splinterStability,
            frequencySignature: splinterFrequency,
            genesisTimestamp: uint40(block.timestamp),
            lastInteraction: uint40(block.timestamp)
        });

        // Add transferred resources to new dimension (needs dynamic approach or fixed keys)
        dimensions[newDimensionId].dimensionalResources[res1] += res1Transfer;


        sourceDim.lastInteraction = uint40(block.timestamp);


        emit DimensionSplintered(_sourceDimensionId, newDimensionId, _msgSender());
        return newDimensionId;
    }

    /// @dev Allows an entity to attune themselves to a dimension's frequency.
    /// Costs knowledge. Grants potential bonuses when interacting with similar frequencies.
    /// @param _dimensionId The ID of the dimension to attune to.
    function attuneEntity(uint256 _dimensionId) public whenNotPaused onlyExistingEntity(_msgSender()) onlyExistingDimension(_dimensionId) {
         Entity storage entity = entities[_msgSender()];
         uint256 knowledgeCost = systemParameters[PARAM_ATTUNE_KNOWLEDGE_COST];

         if (entity.knowledgeFragments < knowledgeCost) revert InsufficientEntityResource(RESOURCE_KNOWLEDGE_FRAGMENT, knowledgeCost, entity.knowledgeFragments);

         if (entity.attunedDimensions[_dimensionId]) revert InvalidDimensionState(_dimensionId, "Already attuned to this dimension");

         entity.knowledgeFragments -= knowledgeCost;
         entity.attunedDimensions[_dimensionId] = true;
         // Note: The actual application of attunement bonus would be within exploreDimension or catalyzeReaction etc.

         emit EntityAttuned(_msgSender(), _dimensionId);
    }

    /// @dev Allows an entity to perform a resource transformation based on a recipe.
    /// Consumes input resources from entity inventory/current dimension, produces outputs.
    /// Costs energy and knowledge.
    /// @param _recipeId The ID of the recipe to catalyze.
    function catalyzeReaction(bytes32 _recipeId) public whenNotPaused onlyExistingEntity(_msgSender()) onlyInValidDimension() {
         Entity storage entity = entities[_msgSender()];
         uint256 dimensionId = entity.currentDimensionId; // Reactions happen in current dimension
         Dimension storage dimension = dimensions[dimensionId];

         Recipe storage recipe = recipes[_recipeId];
         if (recipe.energyCost == 0 && recipe.knowledgeCost == 0 && getRecipeInputCount(_recipeId) == 0 && getRecipeOutputCount(_recipeId) == 0) {
             revert InvalidRecipe(_recipeId); // Recipe must be defined
         }

         // Check entity energy/knowledge cost
         if (entity.nexusEnergy < recipe.energyCost) revert InsufficientEntityResource(RESOURCE_NEXUS_ENERGY, recipe.energyCost, entity.nexusEnergy);
         if (entity.knowledgeFragments < recipe.knowledgeCost) revert InsufficientEntityResource(RESOURCE_KNOWLEDGE_FRAGMENT, recipe.knowledgeCost, entity.knowledgeFragments);

         // Check if entity/dimension has required inputs (simplified: check entity inventory only)
         // A complex version would check both entity inventory and dimension resources based on recipe type.
         // Requires iterating over recipe.inputs - need a helper or known keys
         // Example for known keys:
         bytes32 input1 = bytes32(uint256(1)); // Assume recipe uses resource 1 and resource 2
         bytes32 input2 = bytes32(uint256(2));

         if (entity.inventory[input1] < recipe.inputs[input1]) revert InsufficientEntityResource(input1, recipe.inputs[input1], entity.inventory[input1]);
         if (entity.inventory[input2] < recipe.inputs[input2]) revert InsufficientEntityResource(input2, recipe.inputs[input2], entity.inventory[input2]);
          // Add checks for other potential inputs in the recipe

         // Consume inputs
         entity.inventory[input1] -= recipe.inputs[input1];
         entity.inventory[input2] -= recipe.inputs[input2];
         // Consume other potential inputs...

         // Produce outputs (simplified: add to entity inventory)
         bytes32 output1 = bytes32(uint256(3)); // Assume recipe produces resource 3
         entity.inventory[output1] += recipe.outputs[output1];
         // Add other potential outputs...

         // Consume costs
         entity.nexusEnergy -= recipe.energyCost;
         entity.knowledgeFragments -= recipe.knowledgeCost;

         dimension.lastInteraction = uint40(block.timestamp); // Reaction is an interaction

         emit ReactionCatalyzed(_msgSender(), _recipeId, dimensionId);
    }

     /// @dev Allows an entity to transfer resources from their inventory to another entity.
    /// @param _to The recipient entity address.
    /// @param _resourceType The type of resource to transfer.
    /// @param _amount The amount to transfer.
    function transferEntityResources(address _to, bytes32 _resourceType, uint256 _amount) public whenNotPaused onlyExistingEntity(_msgSender()) onlyExistingEntity(_to) {
        if (_amount == 0) revert InvalidResourceAmount(_amount);
        if (_msgSender() == _to) revert TransferFailed();

        Entity storage fromEntity = entities[_msgSender()];
        Entity storage toEntity = entities[_to];

        if (fromEntity.inventory[_resourceType] < _amount) revert InsufficientEntityResource(_resourceType, _amount, fromEntity.inventory[_resourceType]);

        fromEntity.inventory[_resourceType] -= _amount;
        toEntity.inventory[_resourceType] += _amount;

        emit EntityResourceTransferred(_msgSender(), _to, _resourceType, _amount);
    }

    /// @dev Allows a dimension owner to transfer resources from their dimension's pool to an entity's inventory.
    /// @param _dimensionId The ID of the dimension.
    /// @param _to The recipient entity address.
    /// @param _resourceType The type of resource to transfer.
    /// @param _amount The amount to transfer.
    function transferDimensionResourcesToEntity(uint256 _dimensionId, address _to, bytes32 _resourceType, uint256 _amount) public whenNotPaused onlyDimensionOwner(_dimensionId) onlyExistingEntity(_to) {
         if (_amount == 0) revert InvalidResourceAmount(_amount);

        Dimension storage dimension = dimensions[_dimensionId];
        Entity storage toEntity = entities[_to];

        if (dimension.dimensionalResources[_resourceType] < _amount) revert InsufficientDimensionResource(_dimensionId, _resourceType, _amount, dimension.dimensionalResources[_resourceType]);

        dimension.dimensionalResources[_resourceType] -= _amount;
        toEntity.inventory[_resourceType] += _amount;
        dimension.lastInteraction = uint40(block.timestamp);


        emit DimensionResourceTransferredToEntity(_msgSender(), _dimensionId, _to, _resourceType, _amount);
    }


    // --- System/Admin Functions ---

    /// @dev Owner function to set a system parameter.
    /// @param _paramName The name of the parameter.
    /// @param _paramValue The new value.
    function setSystemParameter(bytes32 _paramName, uint256 _paramValue) public onlyOwner whenNotPaused {
        // Basic validation, could add more checks for specific parameters
        if (_paramName == bytes32(0)) revert InvalidParameter(_paramName);
        systemParameters[_paramName] = _paramValue;
        emit SystemParameterSet(_paramName, _paramValue);
    }

    /// @dev Owner function to trigger a temporary global event.
    /// These events can modify rules or state temporarily.
    /// @param _eventType The type of event.
    /// @param _intensity The intensity/value associated with the event.
    /// @param _duration The duration of the event in seconds.
    function triggerGlobalEvent(bytes32 _eventType, uint256 _intensity, uint40 _duration) public onlyOwner whenNotPaused {
        if (_eventType == bytes32(0) || _duration == 0) revert InvalidParameter("eventType or duration invalid");

        globalEventModifiers[_eventType] = _intensity;
        globalEventEndTimestamps[_eventType] = uint40(block.timestamp) + _duration;

        // Logic to apply the event effect would be checked within relevant functions (e.g., exploreDimension reads globalEventModifiers)
        // For example, exploreDimension could read globalEventModifiers[EVENT_ENERGY_SURGE] and add energy.

        emit GlobalEventTriggered(_eventType, _intensity, _duration);
    }

    /// @dev Owner function to withdraw protocol fees (e.g., from global Nexus Energy Pool).
    /// This assumes Nexus Energy can be converted or represents a transferable asset.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of energy to withdraw.
    function withdrawProtocolFees(address payable _to, uint256 _amount) public onlyOwner {
        if (_amount == 0) revert InvalidResourceAmount(_amount);
        if (globalNexusEnergyPool < _amount) revert InsufficientNexusEnergy(_amount, globalNexusEnergyPool);

        globalNexusEnergyPool -= _amount;
        // In a real system, this might involve transferring ETH if Nexus Energy represents ETH,
        // or transferring an ERC20 token if Nexus Energy is a token.
        // Simple internal reduction here.

        // If Nexus Energy represented ETH:
        // (bool success, ) = _to.call{value: _amount}("");
        // if (!success) revert TransferFailed();

        emit ProtocolFeesWithdrawn(_to, _amount);
    }

     /// @dev Pauses the contract. Only owner can call.
     function pause() public onlyOwner {
        _pause();
     }

     /// @dev Unpauses the contract. Only owner can call.
     function unpause() public onlyOwner {
        _unpause();
     }


    // --- Getter/View Functions ---

    /// @dev Gets details of a specific dimension.
    /// @param _dimensionId The ID of the dimension.
    /// @return The dimension struct details.
    function getDimensionDetails(uint256 _dimensionId) public view onlyExistingDimension(_dimensionId) returns (Dimension memory) {
        Dimension storage dim = dimensions[_dimensionId];
        // Need to manually copy struct fields if it contains mappings
        // Simpler way is to return tuple or a simplified struct without mappings.
        // Let's return key fields as a tuple for mapping fields.
        return Dimension(
             dim.id,
             dim.owner,
             dim.energyLevel,
             dim.stability,
             dim.frequencySignature,
             dim.genesisTimestamp,
             dim.lastInteraction,
             new mapping(bytes32 => uint256)() // Mappings cannot be returned directly in public view
        );
         // Note: To get dimensionalResources, you'd need a separate getter per resource type.
    }

    /// @dev Gets details of a specific entity.
    /// @param _entityAddress The address of the entity.
    /// @return The entity struct details (excluding mappings).
    function getEntityDetails(address _entityAddress) public view onlyExistingEntity(_entityAddress) returns (Entity memory) {
        Entity storage entity = entities[_entityAddress];
         return Entity(
            entity.entityAddress,
            entity.nexusEnergy,
            entity.knowledgeFragments,
            entity.currentDimensionId,
            new mapping(bytes32 => uint256)(), // Mappings cannot be returned directly
            new mapping(uint256 => bool)() // Mappings cannot be returned directly
         );
         // Note: To get inventory or attuned dimensions, separate getters are needed.
    }

    /// @dev Gets the amount of a specific resource in an entity's inventory.
    /// @param _entityAddress The address of the entity.
    /// @param _resourceType The type of resource.
    /// @return The amount of the resource.
    function getEntityInventoryAmount(address _entityAddress, bytes32 _resourceType) public view onlyExistingEntity(_entityAddress) returns (uint256) {
        return entities[_entityAddress].inventory[_resourceType];
    }

     /// @dev Gets the amount of a specific resource in a dimension's pool.
    /// @param _dimensionId The ID of the dimension.
    /// @param _resourceType The type of resource.
    /// @return The amount of the resource.
    function getDimensionResourceAmount(uint256 _dimensionId, bytes32 _resourceType) public view onlyExistingDimension(_dimensionId) returns (uint256) {
        return dimensions[_dimensionId].dimensionalResources[_resourceType];
    }

     /// @dev Checks if an entity is attuned to a specific dimension.
    /// @param _entityAddress The address of the entity.
    /// @param _dimensionId The ID of the dimension.
    /// @return True if attuned, false otherwise.
    function isEntityAttunedToDimension(address _entityAddress, uint256 _dimensionId) public view onlyExistingEntity(_entityAddress) onlyExistingDimension(_dimensionId) returns (bool) {
        return entities[_entityAddress].attunedDimensions[_dimensionId];
    }

    /// @dev Gets the value of a system parameter.
    /// @param _paramName The name of the parameter.
    /// @return The value of the parameter.
    function getSystemParameter(bytes32 _paramName) public view returns (uint256) {
        return systemParameters[_paramName];
    }

    /// @dev Gets the current total number of dimensions created.
    function getTotalDimensions() public view returns (uint256) {
        return _dimensionIds.current();
    }

     /// @dev Gets a range of dimension IDs.
     /// Note: This is inefficient for large numbers of dimensions and returns IDs that might be destroyed.
     /// A proper index or alternative data structure is needed for scaling.
    /// @param _offset The starting ID offset (e.g., 0).
    /// @param _limit The maximum number of IDs to return.
    /// @return An array of dimension IDs within the range.
    function listDimensions(uint256 _offset, uint256 _limit) public view returns (uint256[] memory) {
        uint256 total = _dimensionIds.current();
        if (_offset >= total) return new uint256[](0);

        uint256 count = Math.min(_limit, total - _offset);
        uint256[] memory dimensionIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            dimensionIds[i] = _offset + i;
        }
        return dimensionIds;
    }

    /// @dev Checks if a dimension exists (has been created and not destroyed).
    /// @param _dimensionId The ID to check.
    /// @return True if the dimension exists, false otherwise.
    function dimensionExists(uint256 _dimensionId) public view returns (bool) {
         // Check if ID is within created range and not a deleted entry (mapping lookup handles deleted)
         // ID 0 (Hub) always exists unless explicitly deleted (which we prevented in destroy).
         return _dimensionId < _dimensionIds.current() && dimensions[_dimensionId].id != 0;
         // The .id != 0 check is a simple way to see if the struct slot is likely initialized,
         // assuming 0 is not a valid value for `id` *after* creation (except for the hub).
         // More robust: check if dimensions[_dimensionId].genesisTimestamp > 0 (assuming 0 is invalid)
         // Or better: use a secondary mapping `mapping(uint256 => bool) public dimensionIsActive;`
    }

     /// @dev Checks if an address is a registered entity.
    /// @param _entityAddress The address to check.
    /// @return True if registered, false otherwise.
    function entityExists(address _entityAddress) public view returns (bool) {
        return isRegisteredEntity[_entityAddress];
    }

    /// @dev Gets the number of inputs for a given recipe.
    /// Note: Requires iterating a mapping, which is not directly possible in Solidity view functions.
    /// This getter is a placeholder. In practice, you'd need to either store input keys in an array
    /// within the Recipe struct, or access this data off-chain or via events.
    function getRecipeInputCount(bytes32 _recipeId) public view returns (uint256) {
        // Placeholder: Cannot reliably count mapping entries on-chain.
        // Return a fixed number or require recipe struct to contain input keys array.
        // For the example recipes, we know there are 2 inputs.
        if (_recipeId == keccak256("BasicConversion") || _recipeId == keccak256("AdvancedSynthesis")) return 2;
        return 0; // Default for unknown recipes
    }

     /// @dev Gets the number of outputs for a given recipe.
    /// Placeholder like getRecipeInputCount.
    function getRecipeOutputCount(bytes32 _recipeId) public view returns (uint256) {
        // For the example recipes, we know there is 1 output.
        if (_recipeId == keccak256("BasicConversion") || _recipeId == keccak256("AdvancedSynthesis")) return 1;
        return 0; // Default for unknown recipes
    }

    // Fallback and Receive functions if interacting with ETH is desired
    // receive() external payable {
    //    // Logic to convert received ETH to Nexus Energy and credit entity could go here
    // }
    // fallback() external payable {
    //    // Handle unexpected ETH sends
    // }
}
```