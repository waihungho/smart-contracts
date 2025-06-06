Okay, here is a Solidity smart contract that incorporates several advanced and creative concepts beyond typical open-source patterns. It's designed around a system of "Flux Entities" that can be registered, evolve dynamically based on internal state, reputation, links to other entities, simulated external factors, and even decay if neglected.

It uses concepts like:
*   Dynamic state changes triggered by specific functions and conditions.
*   A custom reputation system influencing outcomes.
*   A probabilistic (pseudo-random) evolution mechanism based on internal factors.
*   Simulated interaction with external data via a function parameter.
*   Linking between entities influencing their dynamics.
*   Batch operations.
*   Basic fee mechanics.
*   Integration of standard patterns like Ownable and Pausable for robust administration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Contract Outline ---
// 1. State Definitions (Enum for Entity State)
// 2. Struct Definition (FluxEntity)
// 3. State Variables (Mappings for entities, counters, fees, parameters)
// 4. Events
// 5. Constructor
// 6. Modifiers (Inherited Pausable/Ownable)
// 7. Core Registry Functions (Register, Get Details, Ownership)
// 8. State & Reputation Management
// 9. Entity Interaction & Linking
// 10. Dynamic Evolution & Decay Mechanisms (Core Advanced Logic)
// 11. State Transition Functions
// 12. Query Functions (Getting lists of entities - potentially gas-heavy)
// 13. Batch Operations
// 14. Configuration & Admin Functions
// 15. Fee Management

// --- Function Summary ---
// Core Registry:
// 1. registerEntity: Creates a new Flux Entity, assigns initial parameters and reputation. Requires registration fee.
// 2. getEntityDetails: Retrieves all details for a given entity ID.
// 3. getEntityOwner: Retrieves the owner's address for a given entity ID (ERC-721 like).
// 4. transferEntityOwnership: Transfers ownership of an entity (ERC-721 like).

// State & Reputation:
// 5. getEntityState: Gets the current state of an entity.
// 6. getReputation: Gets the current reputation score of an entity.
// 7. addReputation: Increases an entity's reputation (restricted).
// 8. subtractReputation: Decreases an entity's reputation (restricted).

// Interaction & Linking:
// 9. linkEntities: Establishes a bidirectional link between two entities. Can influence evolution.
// 10. getLinkedEntities: Retrieves the list of entity IDs linked to a given entity.

// Dynamic Evolution & Decay:
// 11. triggerEvolution: Core dynamic function. Attempts to evolve an entity based on internal state, reputation, and linked entities. Outcome can be probabilistic and influenced by `evolutionEnergy`. Decreases `evolutionEnergy`.
// 12. triggerDecay: Triggers decay of an entity based on inactivity or low reputation. Decreases parameters and reputation, can change state to Dormant.
// 13. triggerRejuvenation: Restores `evolutionEnergy` and potentially improves parameters slightly. Requires rejuvenation fee. Can transition entity from Dormant to Active.
// 14. simulateExternalInfluenceEvolution: Same as triggerEvolution but incorporates an external `factor` parameter (simulating oracle data) into the evolution outcome calculation.

// State Transitions:
// 15. transitionToDormant: Explicitly sets an entity's state to Dormant (conditional, e.g., requires low energy or owner).
// 16. transitionToActive: Explicitly sets an entity's state to Active (conditional, e.g., requires sufficient reputation/energy or owner).

// Query Functions (Potential Gas Considerations for large number of entities):
// 17. getTotalEntities: Gets the total number of registered entities.
// 18. queryEntitiesByOwner: Returns an array of entity IDs owned by a specific address.
// 19. queryEntitiesByState: Returns an array of entity IDs currently in a specific state.
// 20. queryEntitiesByReputationRange: Returns an array of entity IDs within a specified reputation range.

// Batch Operations:
// 21. batchUpdateParameters: Allows updating parameters for multiple entities in a single transaction (owner/admin only, potentially gas-heavy).

// Configuration & Admin:
// 22. setEvolutionParameters: Owner sets parameters governing evolution probabilities and effects.
// 23. setReputationParameters: Owner sets parameters governing reputation changes.
// 24. setFees: Owner sets the registration and rejuvenation fees.
// 25. pauseContract: Owner pauses core functionality (inherited from Pausable).
// 26. unpauseContract: Owner unpauses contract (inherited from Pausable).

// Fee Management:
// 27. withdrawFees: Owner withdraws accumulated Ether fees.

contract QuantumFluxRegistry is Ownable, Pausable {

    // --- State Definitions ---
    enum EntityState {
        NonExistent, // Should not be stored, indicates ID is unused
        Active,
        Dormant,
        Evolving, // Temporary state during evolution process (optional, simplified version skips this)
        Decayed // Represents a state of significant degradation
    }

    // --- Struct Definition ---
    struct FluxEntity {
        uint256 entityId;
        address owner;
        EntityState state;
        int256 reputation; // Can be positive or negative
        uint256[] parameters; // Dynamic array of parameters representing entity attributes
        uint256 creationTime;
        uint256 lastUpdateTime;
        uint256 evolutionEnergy; // Resource required for evolution
    }

    // --- State Variables ---
    mapping(uint256 => FluxEntity) private _entities;
    uint256 private _entityCounter;

    // Keep track of entities per owner for querying (can be gas-heavy for many entities)
    mapping(address => uint256[]) private _ownerEntities;
    // Keep track of entities per state for querying (can be gas-heavy for many entities)
    mapping(EntityState => uint256[]) private _stateEntities;

    // Linked entities (bidirectional)
    mapping(uint256 => uint256[]) private _linkedEntities;

    // Fees
    uint256 public registrationFee = 0.01 ether; // Example fee
    uint256 public rejuvenationFee = 0.005 ether; // Example fee
    uint256 public totalFees;

    // Evolution Parameters (Admin Configurable)
    uint256 public minReputationForEvolution = 0;
    uint256 public evolutionCooldown = 1 days; // Time required between evolutions
    uint256 public evolutionEnergyCost = 10;
    uint256 public maxEvolutionEnergy = 100;
    int256 public evolutionReputationImpactRange = 10; // +/- range for reputation change on evolution
    uint256 public evolutionParameterChangeRange = 5; // +/- range for parameter change on evolution
    uint256 public maxParameterValue = 100; // Cap for parameter values

    // Reputation Parameters (Admin Configurable)
    int256 public decayReputationThreshold = -50; // Reputation below this triggers decay checks
    uint256 public decayInactivityThreshold = 30 days; // Inactivity period triggering decay checks
    int256 public decayReputationPenalty = 20; // Amount of reputation lost on decay
    uint256 public decayParameterPenalty = 10; // Amount parameters decrease on decay

    // --- Events ---
    event EntityRegistered(uint256 indexed entityId, address indexed owner, uint256 creationTime);
    event EntityUpdated(uint256 indexed entityId, uint256[] newParameters, int256 newReputation, EntityState newState);
    event EntityOwnershipTransferred(uint256 indexed entityId, address indexed previousOwner, address indexed newOwner);
    event ReputationChanged(uint256 indexed entityId, int256 oldReputation, int256 newReputation);
    event StateChanged(uint256 indexed entityId, EntityState oldState, EntityState newState);
    event EntitiesLinked(uint256 indexed entity1Id, uint256 indexed entity2Id);
    event EntityEvolved(uint256 indexed entityId, uint256 externalFactorUsed, int256 reputationChange, uint256 parameterChangeMagnitude);
    event EntityDecayed(uint256 indexed entityId, string reason);
    event EntityRejuvenated(uint256 indexed entityId, uint256 energyRestored);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(uint256 initialRegistrationFee, uint256 initialRejuvenationFee) Ownable(msg.sender) {
        registrationFee = initialRegistrationFee;
        rejuvenationFee = initialRejuvenationFee;
        _entityCounter = 0; // Start counter at 0 or 1 as appropriate
    }

    // --- Modifiers ---
    // Uses inherited whenNotPaused and onlyOwner from OpenZeppelin

    modifier onlyEntityOwner(uint256 entityId) {
        require(_entities[entityId].owner == msg.sender, "Not entity owner");
        _;
    }

    modifier entityExists(uint256 entityId) {
        require(_entities[entityId].entityId != 0, "Entity does not exist");
        _;
    }

    // --- Core Registry Functions ---

    /**
     * @notice Registers a new Flux Entity.
     * @param initialParameters Initial values for the entity's parameters.
     * @dev Requires payment of the registration fee. Assigns initial reputation (e.g., 0).
     */
    function registerEntity(uint256[] calldata initialParameters) external payable whenNotPaused {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(initialParameters.length > 0, "Must provide initial parameters");

        uint256 newEntityId = ++_entityCounter; // Pre-increment for ID 1, 2, 3...

        FluxEntity storage newEntity = _entities[newEntityId];
        newEntity.entityId = newEntityId;
        newEntity.owner = msg.sender;
        newEntity.state = EntityState.Active; // Starts active
        newEntity.reputation = 0; // Initial reputation
        newEntity.parameters = initialParameters; // Copy parameters
        newEntity.creationTime = block.timestamp;
        newEntity.lastUpdateTime = block.timestamp;
        newEntity.evolutionEnergy = maxEvolutionEnergy; // Starts with full energy

        // Update owner & state indices (gas consideration)
        _ownerEntities[msg.sender].push(newEntityId);
        _stateEntities[EntityState.Active].push(newEntityId); // Add to Active state list

        totalFees += msg.value;

        emit EntityRegistered(newEntityId, msg.sender, block.timestamp);
        emit StateChanged(newEntityId, EntityState.NonExistent, EntityState.Active);
    }

    /**
     * @notice Retrieves all details for a given entity ID.
     * @param entityId The ID of the entity.
     * @return FluxEntity struct containing all details.
     */
    function getEntityDetails(uint256 entityId) external view entityExists(entityId) returns (FluxEntity memory) {
        return _entities[entityId];
    }

    /**
     * @notice Retrieves the owner's address for a given entity ID.
     * @param entityId The ID of the entity.
     * @return The owner's address.
     */
    function getEntityOwner(uint256 entityId) public view entityExists(entityId) returns (address) {
        return _entities[entityId].owner;
    }

    /**
     * @notice Transfers ownership of an entity to a new address.
     * @param to The address to transfer ownership to.
     * @param entityId The ID of the entity to transfer.
     */
    function transferEntityOwnership(address to, uint256 entityId) external onlyEntityOwner(entityId) whenNotPaused {
        require(to != address(0), "Cannot transfer to zero address");

        address previousOwner = _entities[entityId].owner;
        _entities[entityId].owner = to;

        // Update owner index (gas consideration)
        // Removing from old owner's list is complex and gas-heavy for large lists.
        // For simplicity, we just add to the new owner's list. Querying _ownerEntities
        // would require iterating and checking if the entity still belongs to the old owner.
        // A more gas-efficient approach for removal might involve linked lists or requiring off-chain indexing.
        _ownerEntities[to].push(entityId);
        // Note: Removal from _ownerEntities[previousOwner] is omitted for gas efficiency in this example,
        // making _ownerEntities potentially contain "stale" entries for previous owners.
        // A proper implementation might require iterating and removing or using a different data structure.

        emit EntityOwnershipTransferred(entityId, previousOwner, to);
    }

    // --- State & Reputation Management ---

    /**
     * @notice Gets the current state of an entity.
     * @param entityId The ID of the entity.
     * @return The entity's current state enum value.
     */
    function getEntityState(uint256 entityId) external view entityExists(entityId) returns (EntityState) {
        return _entities[entityId].state;
    }

    /**
     * @notice Gets the current reputation score of an entity.
     * @param entityId The ID of the entity.
     * @return The entity's current reputation score.
     */
    function getReputation(uint256 entityId) external view entityExists(entityId) returns (int256) {
        return _entities[entityId].reputation;
    }

    /**
     * @notice Increases an entity's reputation.
     * @dev Restricted function, could be called by owner, linked entities (complex), or specific contract logic. Owner-only for simplicity here.
     * @param entityId The ID of the entity.
     * @param amount The amount to add to reputation.
     */
    function addReputation(uint256 entityId, uint256 amount) external onlyEntityOwner(entityId) whenNotPaused entityExists(entityId) {
        int256 oldReputation = _entities[entityId].reputation;
        _entities[entityId].reputation += int256(amount);
        emit ReputationChanged(entityId, oldReputation, _entities[entityId].reputation);
    }

    /**
     * @notice Decreases an entity's reputation.
     * @dev Restricted function, could be called by owner, linked entities (complex), or specific contract logic. Owner-only for simplicity here.
     * @param entityId The ID of the entity.
     * @param amount The amount to subtract from reputation.
     */
    function subtractReputation(uint256 entityId, uint256 amount) external onlyEntityOwner(entityId) whenNotPaused entityExists(entityId) {
         int256 oldReputation = _entities[entityId].reputation;
        _entities[entityId].reputation -= int256(amount);
        emit ReputationChanged(entityId, oldReputation, _entities[entityId].reputation);
    }

    // --- Entity Interaction & Linking ---

    /**
     * @notice Establishes a bidirectional link between two entities.
     * @dev Requires ownership of both entities to link them.
     * @param entity1Id The ID of the first entity.
     * @param entity2Id The ID of the second entity.
     */
    function linkEntities(uint256 entity1Id, uint256 entity2Id) external entityExists(entity1Id) entityExists(entity2Id) whenNotPaused {
        require(entity1Id != entity2Id, "Cannot link an entity to itself");
        require(_entities[entity1Id].owner == msg.sender || _entities[entity2Id].owner == msg.sender, "Must own at least one entity to link");
        // To prevent abuse, requiring ownership of *both* is safer, depending on game/system rules.
        // Let's require ownership of BOTH for simplicity and security in this example.
        require(_entities[entity1Id].owner == msg.sender && _entities[entity2Id].owner == msg.sender, "Must own both entities to link");

        // Add link from 1 to 2 if not exists
        bool alreadyLinked = false;
        for (uint i = 0; i < _linkedEntities[entity1Id].length; i++) {
            if (_linkedEntities[entity1Id][i] == entity2Id) {
                alreadyLinked = true;
                break;
            }
        }
        if (!alreadyLinked) {
             _linkedEntities[entity1Id].push(entity2Id);
        }

        // Add link from 2 to 1 if not exists
        alreadyLinked = false; // Reset flag
        for (uint i = 0; i < _linkedEntities[entity2Id].length; i++) {
            if (_linkedEntities[entity2Id][i] == entity1Id) {
                alreadyLinked = true;
                break;
            }
        }
         if (!alreadyLinked) {
             _linkedEntities[entity2Id].push(entity1Id);
        }

        emit EntitiesLinked(entity1Id, entity2Id);
    }

    /**
     * @notice Retrieves the list of entity IDs linked to a given entity.
     * @param entityId The ID of the entity.
     * @return An array of entity IDs linked to the specified entity.
     */
    function getLinkedEntities(uint256 entityId) external view entityExists(entityId) returns (uint256[] memory) {
        return _linkedEntities[entityId];
    }

    // --- Dynamic Evolution & Decay Mechanisms ---

    /**
     * @notice Triggers an attempt for an entity to evolve.
     * @dev Evolution outcome is influenced by reputation, parameters, evolutionEnergy, and potentially linked entities.
     *      Uses block data for pseudo-randomness (note: exploitable by miners in production).
     * @param entityId The ID of the entity to evolve.
     */
    function triggerEvolution(uint256 entityId) external whenNotPaused entityExists(entityId) {
        FluxEntity storage entity = _entities[entityId];
        require(entity.owner == msg.sender, "Only owner can trigger evolution");
        require(entity.state == EntityState.Active, "Entity must be Active to evolve");
        require(entity.evolutionEnergy >= evolutionEnergyCost, "Insufficient evolution energy");
        require(block.timestamp >= entity.lastUpdateTime + evolutionCooldown, "Evolution cooldown in effect");
        require(entity.reputation >= minReputationForEvolution, "Reputation too low to evolve");

        _handleEvolution(entityId, 0); // Call internal logic, 0 indicates no external factor
    }

    /**
     * @notice Triggers an attempt for an entity to evolve, incorporating a simulated external factor.
     * @dev The external factor parameter allows simulating influence from off-chain data (e.g., weather, market data via oracle).
     *      Uses block data and the external factor for pseudo-randomness.
     * @param entityId The ID of the entity to evolve.
     * @param externalFactor A uint256 value representing influence from external data.
     */
    function simulateExternalInfluenceEvolution(uint256 entityId, uint256 externalFactor) external whenNotPaused entityExists(entityId) {
         FluxEntity storage entity = _entities[entityId];
        require(entity.owner == msg.sender, "Only owner can trigger evolution");
        require(entity.state == EntityState.Active, "Entity must be Active to evolve");
        require(entity.evolutionEnergy >= evolutionEnergyCost, "Insufficient evolution energy");
        require(block.timestamp >= entity.lastUpdateTime + evolutionCooldown, "Evolution cooldown in effect");
        require(entity.reputation >= minReputationForEvolution, "Reputation too low to evolve");

        _handleEvolution(entityId, externalFactor); // Call internal logic with external factor
    }


    /**
     * @dev Internal function containing the core evolution logic.
     * @param entityId The ID of the entity.
     * @param externalFactor An optional external factor to influence the outcome.
     */
    function _handleEvolution(uint256 entityId, uint256 externalFactor) internal {
        FluxEntity storage entity = _entities[entityId];
        int256 oldReputation = entity.reputation;

        // --- Pseudo-randomness and Outcome Calculation ---
        // WARNING: Using block data for randomness is insecure and predictable by miners!
        // For a production system, use Chainlink VRF or similar secure randomness source.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.difficulty,
            block.timestamp,
            entityId,
            entity.reputation,
            externalFactor, // Incorporate external factor
            msg.sender
        )));

        // Calculate a score based on entity state, reputation, and pseudo-randomness
        // Higher reputation = higher base score, more likely for positive outcomes
        int256 outcomeScore = entity.reputation / 10 + int256(randomSeed % 100) - 50; // Basic score influenced by reputation and randomness

        // Factor in linked entities' reputation (simplified: average reputation of linked entities)
        // This part can be complex and gas-heavy depending on the number of linked entities.
        // Simple approach: Sum reputation of linked entities and add a portion to outcomeScore.
        uint26 linkInfluence = 0;
        uint256[] memory linked = _linkedEntities[entityId];
        if (linked.length > 0) {
            int256 totalLinkedReputation = 0;
            uint256 validLinks = 0;
             for (uint i = 0; i < linked.length; i++) {
                uint256 linkedId = linked[i];
                // Ensure linked entity exists and is not in a terminal state like Decayed
                if (_entities[linkedId].entityId != 0 && _entities[linkedId].state != EntityState.Decayed) {
                    totalLinkedReputation += _entities[linkedId].reputation;
                    validLinks++;
                }
            }
            if (validLinks > 0) {
                 // Add a small portion of average linked reputation to influence
                 linkInfluence = uint26(totalLinkedReputation / int256(validLinks) / 50); // Divide to scale down influence
            }
        }
        outcomeScore += int256(linkInfluence); // Add influence from linked entities


        // --- Apply Evolution Effects ---
        int256 reputationChange = 0;
        int256 parameterChangeMagnitude = 0;

        if (outcomeScore >= 20) { // Highly positive outcome
            reputationChange = int256(randomSeed % uint256(evolutionReputationImpactRange)) + (evolutionReputationImpactRange / 2); // Positive change
            parameterChangeMagnitude = randomSeed % evolutionParameterChangeRange + (evolutionParameterChangeRange / 2); // Increase parameters
            // Optional: state transition to a higher level, unlock abilities etc.
        } else if (outcomeScore >= 0) { // Moderately positive outcome
            reputationChange = int256(randomSeed % uint256(evolutionReputationImpactRange / 2)) + 1; // Small positive change
            parameterChangeMagnitude = randomSeed % (evolutionParameterChangeRange / 2) + 1; // Small increase parameters
        } else if (outcomeScore >= -20) { // Neutral or slightly negative
             reputationChange = -(int256(randomSeed % uint256(evolutionReputationImpactRange / 2)) + 1); // Small negative change
             parameterChangeMagnitude = randomSeed % (evolutionParameterChangeRange / 2); // Small random parameter change (can be positive or negative)
             if (randomSeed % 2 == 0) parameterChangeMagnitude = -parameterChangeMagnitude;
        } else { // Negative outcome
            reputationChange = -(int256(randomSeed % uint256(evolutionReputationImpactRange)) + (evolutionReputationImpactRange / 2)); // Significant negative change
            parameterChangeMagnitude = -(randomSeed % evolutionParameterChangeRange + (evolutionParameterChangeRange / 2)); // Decrease parameters
            // Optional: state transition to Dormant or Decayed based on severe negative outcome
        }

        // Update reputation
        entity.reputation += reputationChange;
         emit ReputationChanged(entityId, oldReputation, entity.reputation);

        // Update parameters (apply change magnitude to all parameters)
        uint256[] storage params = entity.parameters;
        for (uint i = 0; i < params.length; i++) {
             if (parameterChangeMagnitude >= 0) {
                 params[i] += uint256(parameterChangeMagnitude);
                 // Cap parameters at maxParameterValue
                 if (params[i] > maxParameterValue) {
                     params[i] = maxParameterValue;
                 }
             } else {
                 uint256 change = uint256(-parameterChangeMagnitude); // Make it positive for subtraction
                 if (params[i] >= change) {
                     params[i] -= change;
                 } else {
                     params[i] = 0; // Cannot go below zero
                 }
             }
        }

        // Consume evolution energy
        entity.evolutionEnergy -= evolutionEnergyCost;

        // Update timestamps
        entity.lastUpdateTime = block.timestamp;

        emit EntityEvolved(entityId, externalFactor, reputationChange, uint256(parameterChangeMagnitude >= 0 ? parameterChangeMagnitude : -parameterChangeMagnitude));
        emit EntityUpdated(entityId, entity.parameters, entity.reputation, entity.state);

        // Check for decay possibility after evolution based on new state
        _checkAndTriggerDecay(entityId);
    }

    /**
     * @notice Checks if an entity should decay and triggers it if necessary.
     * @dev Can be called internally after evolution or rejuvenation, or externally by anyone.
     *      Decay happens if reputation is below threshold AND entity is inactive.
     * @param entityId The ID of the entity to check/decay.
     */
    function triggerDecay(uint256 entityId) external whenNotPaused entityExists(entityId) {
         _checkAndTriggerDecay(entityId);
    }

     /**
     * @dev Internal function to check decay conditions and apply decay effects.
     * @param entityId The ID of the entity.
     */
    function _checkAndTriggerDecay(uint256 entityId) internal {
         FluxEntity storage entity = _entities[entityId];

        // Only decay if not already Decayed and not actively evolving (optional Evolving state check)
        if (entity.state == EntityState.Decayed /* || entity.state == EntityState.Evolving */) {
            return;
        }

        bool reputationTooLow = entity.reputation < decayReputationThreshold;
        bool inactive = block.timestamp >= entity.lastUpdateTime + decayInactivityThreshold;

        if (reputationTooLow && inactive) {
            // Apply decay effects
            int256 oldReputation = entity.reputation;
            EntityState oldState = entity.state;

            entity.reputation -= decayReputationPenalty; // Decrease reputation
            if (entity.reputation < -100) { // Arbitrary lower bound
                 entity.reputation = -100;
            }

            // Decrease parameters
            uint256[] storage params = entity.parameters;
            for (uint i = 0; i < params.length; i++) {
                 if (params[i] >= decayParameterPenalty) {
                     params[i] -= decayParameterPenalty;
                 } else {
                     params[i] = 0;
                 }
            }

            // Change state to Dormant or Decayed
            if (entity.state != EntityState.Dormant) { // Avoid redundant state change event if already Dormant
                 _changeState(entityId, EntityState.Dormant); // Transition to Dormant
            }

            emit EntityDecayed(entityId, "Low reputation and inactivity");
            emit ReputationChanged(entityId, oldReputation, entity.reputation);
            emit EntityUpdated(entityId, entity.parameters, entity.reputation, entity.state);
        }
    }


    /**
     * @notice Restores evolution energy and potentially improves parameters slightly. Requires fee.
     * @dev Can transition entity from Dormant back to Active if conditions met.
     * @param entityId The ID of the entity to rejuvenate.
     */
    function triggerRejuvenation(uint256 entityId) external payable whenNotPaused entityExists(entityId) onlyEntityOwner(entityId) {
        require(msg.value >= rejuvenationFee, "Insufficient rejuvenation fee");

        FluxEntity storage entity = _entities[entityId];
        EntityState oldState = entity.state;

        // Restore evolution energy
        uint256 energyRestored = maxEvolutionEnergy - entity.evolutionEnergy;
        entity.evolutionEnergy = maxEvolutionEnergy;

        // Slight parameter boost (optional)
        uint256[] storage params = entity.parameters;
        for (uint i = 0; i < params.length; i++) {
             if (params[i] < maxParameterValue) {
                  params[i] += (maxParameterValue - params[i]) / 10 + 1; // Boost towards max, smaller boost for high values
                  if (params[i] > maxParameterValue) {
                     params[i] = maxParameterValue; // Ensure cap
                 }
             }
        }

        // Transition back to Active if Dormant and reputation is not critically low
        if (entity.state == EntityState.Dormant && entity.reputation > decayReputationThreshold) {
             _changeState(entityId, EntityState.Active);
        }

        entity.lastUpdateTime = block.timestamp; // Consider rejuvenation an update

        totalFees += msg.value;

        emit EntityRejuvenated(entityId, energyRestored);
        if (entity.state != oldState) {
             emit StateChanged(entityId, oldState, entity.state);
        }
        emit EntityUpdated(entityId, entity.parameters, entity.reputation, entity.state);
    }

     // --- State Transition Functions ---

    /**
     * @notice Explicitly attempts to transition an entity to the Dormant state.
     * @dev Owner can force dormant, or contract logic might allow if energy is low etc.
     * @param entityId The ID of the entity.
     */
    function transitionToDormant(uint256 entityId) external whenNotPaused entityExists(entityId) {
         FluxEntity storage entity = _entities[entityId];
         require(entity.owner == msg.sender, "Only owner can request state change");
         require(entity.state != EntityState.Dormant, "Entity is already Dormant");
         // Add more conditions if needed, e.g., require low energy
         // require(entity.evolutionEnergy < evolutionEnergyCost, "Entity energy too high to go Dormant");

         _changeState(entityId, EntityState.Dormant);
    }

    /**
     * @notice Explicitly attempts to transition an entity to the Active state.
     * @dev Owner can force active, or contract logic might allow if reputation/energy is high etc.
     * @param entityId The ID of the entity.
     */
     function transitionToActive(uint256 entityId) external whenNotPaused entityExists(entityId) {
         FluxEntity storage entity = _entities[entityId];
         require(entity.owner == msg.sender, "Only owner can request state change");
         require(entity.state == EntityState.Dormant || entity.state == EntityState.Decayed, "Entity must be Dormant or Decayed to become Active");
         // Add more conditions if needed, e.g., require sufficient reputation or energy
         require(entity.reputation > decayReputationThreshold, "Reputation too low to become Active");
         // Note: rejuvenation also handles Active transition with fee

         _changeState(entityId, EntityState.Active);
    }

     /**
     * @dev Internal function to handle state transitions and update index.
     * @param entityId The ID of the entity.
     * @param newState The state to transition to.
     */
    function _changeState(uint256 entityId, EntityState newState) internal {
         FluxEntity storage entity = _entities[entityId];
         EntityState oldState = entity.state;
         if (oldState == newState) return; // No change

         // Update state index (removing from old state list, adding to new - gas consideration)
         // Removing from mapping lists is omitted for gas efficiency, similar to _ownerEntities.
         // Querying _stateEntities would require iterating and checking current state.
         _stateEntities[newState].push(entityId);
         // Omission of removal from _stateEntities[oldState] here.

         entity.state = newState;
         emit StateChanged(entityId, oldState, newState);
         entity.lastUpdateTime = block.timestamp; // State change is a form of update
    }


    // --- Query Functions (Potential Gas Considerations) ---

    /**
     * @notice Gets the total number of registered entities.
     * @return The total count of entities.
     */
    function getTotalEntities() external view returns (uint256) {
        return _entityCounter;
    }

    /**
     * @notice Returns an array of entity IDs owned by a specific address.
     * @dev WARNING: This function can be very gas-expensive if an address owns many entities.
     *      Consider alternative querying methods for production (e.g., off-chain indexer).
     *      Note: Includes potentially stale entries from past ownership transfers due to gas optimization in transferEntityOwnership.
     * @param owner The address to query entities for.
     * @return An array of entity IDs.
     */
    function queryEntitiesByOwner(address owner) external view returns (uint256[] memory) {
        // This returns the raw list. Caller/indexer needs to filter out stale entries.
        return _ownerEntities[owner];
    }

    /**
     * @notice Returns an array of entity IDs currently in a specific state.
     * @dev WARNING: This function can be very gas-expensive if many entities are in the queried state.
     *      Consider alternative querying methods for production (e.g., off-chain indexer).
     *      Note: Includes potentially stale entries if _changeState omission impacts index.
     * @param state The state to query entities for.
     * @return An array of entity IDs.
     */
     function queryEntitiesByState(EntityState state) external view returns (uint256[] memory) {
        // For states other than NonExistent (which isn't stored in the index)
         if (state == EntityState.NonExistent) return new uint256[](0);
         // This returns the raw list. Caller/indexer needs to filter out stale entries if state changes were not fully removed.
         return _stateEntities[state];
    }

    /**
     * @notice Returns an array of entity IDs within a specified reputation range (inclusive).
     * @dev WARNING: This function iterates through ALL entities to find matches, which is extremely gas-expensive
     *      for a large number of entities. Primarily for demonstration.
     *      Use an off-chain indexer for any practical application.
     * @param minReputation The minimum reputation (inclusive).
     * @param maxReputation The maximum reputation (inclusive).
     * @return An array of entity IDs.
     */
    function queryEntitiesByReputationRange(int256 minReputation, int256 maxReputation) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_entityCounter); // Allocate max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _entityCounter; i++) {
            if (_entities[i].entityId != 0) { // Check if entity exists (handle potential future deletion)
                if (_entities[i].reputation >= minReputation && _entities[i].reputation <= maxReputation) {
                    result[count] = i;
                    count++;
                }
            }
        }
        // Copy to a new array of the correct size
        uint256[] memory filteredResult = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            filteredResult[i] = result[i];
        }
        return filteredResult;
    }

    // --- Batch Operations ---

    /**
     * @notice Allows the owner to update parameters for multiple entities in a single transaction.
     * @dev WARNING: Can be gas-heavy depending on the number of entities and parameters being updated.
     * @param entityIds The array of entity IDs to update.
     * @param newParametersArray An array of parameter arrays, where newParametersArray[i] corresponds to entityIds[i].
     */
    function batchUpdateParameters(uint256[] calldata entityIds, uint256[][] calldata newParametersArray) external onlyOwner whenNotPaused {
        require(entityIds.length == newParametersArray.length, "Array lengths must match");

        for (uint i = 0; i < entityIds.length; i++) {
            uint256 entityId = entityIds[i];
            uint256[] calldata newParams = newParametersArray[i];

            require(_entities[entityId].entityId != 0, string.concat("Entity ", Strings.toString(entityId), " does not exist"));
            // Optional: Add more specific validation for parameters if needed
            // require(_entities[entityId].parameters.length == newParams.length, "Parameter length mismatch"); // Example check

            FluxEntity storage entity = _entities[entityId];
             // Deep copy the parameters array
            delete entity.parameters; // Clear old dynamic array
            entity.parameters = new uint256[](newParams.length);
            for (uint j = 0; j < newParams.length; j++) {
                entity.parameters[j] = newParams[j];
                // Optional: Apply parameter caps here too
                if (entity.parameters[j] > maxParameterValue) {
                     entity.parameters[j] = maxParameterValue;
                 }
            }
             entity.lastUpdateTime = block.timestamp; // Parameter update is a form of update

            // Note: This does *not* trigger the full evolution/decay logic, just a raw parameter update.
            // Consider emitting a specific event for batch updates if necessary.
            emit EntityUpdated(entityId, entity.parameters, entity.reputation, entity.state);
        }
    }


    // --- Configuration & Admin Functions ---

    /**
     * @notice Owner sets parameters governing evolution probabilities and effects.
     */
    function setEvolutionParameters(uint256 _minReputationForEvolution, uint256 _evolutionCooldown, uint256 _evolutionEnergyCost, uint256 _maxEvolutionEnergy, int256 _evolutionReputationImpactRange, uint256 _evolutionParameterChangeRange, uint256 _maxParameterValue) external onlyOwner {
        minReputationForEvolution = _minReputationForEvolution;
        evolutionCooldown = _evolutionCooldown;
        evolutionEnergyCost = _evolutionEnergyCost;
        maxEvolutionEnergy = _maxEvolutionEnergy;
        evolutionReputationImpactRange = _evolutionReputationImpactRange;
        evolutionParameterChangeRange = _evolutionParameterChangeRange;
        maxParameterValue = _maxParameterValue;
    }

     /**
     * @notice Owner sets parameters governing reputation changes and decay thresholds.
     */
    function setReputationParameters(int256 _decayReputationThreshold, uint256 _decayInactivityThreshold, int256 _decayReputationPenalty, uint256 _decayParameterPenalty) external onlyOwner {
        decayReputationThreshold = _decayReputationThreshold;
        decayInactivityThreshold = _decayInactivityThreshold;
        decayReputationPenalty = _decayReputationPenalty;
        decayParameterPenalty = _decayParameterPenalty;
    }

    /**
     * @notice Owner sets the registration and rejuvenation fees.
     */
    function setFees(uint26 _registrationFee, uint26 _rejuvenationFee) external onlyOwner {
        registrationFee = _registrationFee;
        rejuvenationFee = _rejuvenationFee;
    }

    // Inherits pause/unpause from Pausable

    // --- Fee Management ---

    /**
     * @notice Allows the owner to withdraw accumulated Ether fees.
     * @param to The address to send the fees to.
     */
    function withdrawFees(address to) external onlyOwner {
        uint256 amount = totalFees;
        totalFees = 0;
        // Use a low-level call to prevent reentrancy issues
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(to, amount);
    }

    // --- Internal Helper Functions ---

    // Function to safely convert uint256 to string (from OpenZeppelin, included here for self-containment)
    library Strings {
        bytes16 private constant _HEX_TABLE = "0123456789abcdef";

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
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Entity State:** The `FluxEntity` struct has a `state` enum (`Active`, `Dormant`, `Decayed`). These aren't just passive labels; they can affect which actions are allowed (`triggerEvolution` requires `Active`), and transitions between states can be triggered by specific functions (`transitionToDormant`, `transitionToActive`) or internal logic (`triggerDecay`, `triggerRejuvenation`).
2.  **Custom Reputation System (`int256 reputation`):** Entities have a mutable reputation score that can go up or down. This score directly influences the outcome of the core `triggerEvolution` function, where higher reputation leads to a higher chance of positive parameter changes and vice versa. It also plays a role in the `triggerDecay` conditions.
3.  **Probabilistic Evolution Mechanism (`_handleEvolution`):** This is the core dynamic part.
    *   It uses a pseudo-random seed derived from block data (`block.difficulty`, `block.timestamp`), entity state, reputation, and the caller. **Note:** EVM pseudo-randomness is predictable and exploitable by miners in production. For a secure dApp, a solution like Chainlink VRF is necessary. This implementation is for conceptual demonstration.
    *   An `outcomeScore` is calculated, heavily influenced by the entity's current `reputation` and the pseudo-random value.
    *   Based on this `outcomeScore`, the entity's `reputation` and `parameters` are modified probabilistically within defined ranges. This simulates growth, stagnation, or decline.
    *   It consumes `evolutionEnergy`, adding another resource management layer.
4.  **Simulated External Influence (`simulateExternalInfluenceEvolution`):** This function takes an `externalFactor` parameter. While in this contract it's just a number passed by the caller, it's designed to *represent* data that might come from an oracle (like Chainlink) feeding off-chain information (market price, weather data, AI prediction score, etc.) into the on-chain logic. This allows simulating how external events could affect the internal state of entities.
5.  **Entity Linking Influence:** The `linkEntities` function allows creating bidirectional links. The `_handleEvolution` function then incorporates the average reputation of *linked* entities into the `outcomeScore` calculation. This adds a layer of networked dynamics, where an entity's neighbours can influence its personal development.
6.  **Evolution Energy (`evolutionEnergy`):** A resource tracked per entity. `triggerEvolution` consumes it, and `triggerRejuvenation` replenishes it for a fee. This prevents spamming the evolution function and creates a strategic element.
7.  **Decay Mechanism (`triggerDecay`, `_checkAndTriggerDecay`):** Entities can decay if they are inactive *and* their reputation drops below a threshold. Decay causes a penalty to reputation and parameters and can change the state to `Dormant`. This adds a cost to neglect and encourages interaction/rejuvenation.
8.  **Parameter Dynamics (`parameters` array):** The `parameters` field is a dynamic array, allowing entities to have a variable number of attributes (unlike fixed struct fields). The evolution and decay mechanisms modify these parameters, giving entities a mutable 'DNA' that changes over time and interaction. `maxParameterValue` provides a cap.
9.  **Batch Operations (`batchUpdateParameters`):** Includes a function to update multiple entities in a single transaction, which can be convenient for owner/admin tasks, although it highlights potential gas costs for large batches.
10. **Gas Optimization Caveats:** The contract explicitly mentions and often *omits* gas-heavy operations like removing elements from dynamic arrays within mappings (`_ownerEntities`, `_stateEntities`) during state changes or transfers. This makes the *querying* functions (`queryEntitiesByOwner`, `queryEntitiesByState`) less precise or more gas-heavy for filtering, acknowledging that a production system would likely require off-chain indexing or different data structures. The `queryEntitiesByReputationRange` is noted as extremely gas-intensive for large entity counts.

This contract provides a framework for a system where digital entities have complex, interacting, and evolving states, driven by internal logic and simulated external factors, moving beyond simple token ownership or fixed data points.