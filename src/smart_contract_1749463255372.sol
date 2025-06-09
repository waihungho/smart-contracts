Okay, let's design a smart contract based on the concept of "Quantum Entanglement" applied metaphorically to digital entities. This allows for complex state dependencies and probabilistic interactions between linked assets/identities, avoiding direct copies of standard patterns.

**Concept:** `QuantumEntanglementRegistry` is a registry for unique digital entities. These entities can be "entangled" in pairs. The "quantum state" of an entity (represented abstractly) can be in "superposition" or a definite state. Observing an entity collapses its superposition (probabilistically) and *may* instantly affect the state of its entangled partner, simulating "spooky action at a distance." Entities also have dynamic attributes and can be transferred or retired.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although using SafeMath for simple uints might be excessive in 0.8+, good practice for general safety.

// --- Contract Outline ---
// 1. State Variables: Storage for entities, counter, parameters.
// 2. Structs: Definition of the Entity structure.
// 3. Events: Signals for key contract actions.
// 4. Modifiers: Access control and state checks.
// 5. Constructor: Initializes the contract owner and parameters.
// 6. Core Registry Functions: Create, retrieve, manage entity basics.
// 7. Dynamic Attribute Functions: Manage custom key-value data on entities.
// 8. Entanglement Functions: Link and unlink entities.
// 9. Quantum State Functions: Manage superposition, observation, and definite states.
// 10. Utility & Governance Functions: Total count, retirement, parameter setting (Owner-only).
// 11. Ownable Functions: Inherited for contract ownership.

// --- Function Summary ---
// --- Core Registry ---
// 1. createEntity(string name, uint8 initialDefiniteState): Creates a new entity with a name and initial potential definite state.
// 2. getEntity(uint256 entityId) view: Retrieves details of an entity (owner, name, state, superposition, entangledWith, active).
// 3. getEntityOwner(uint256 entityId) view: Gets the owner address of an entity.
// 4. getEntityState(uint256 entityId) view: Gets the current quantum state and superposition status of an entity.
// 5. setEntityName(uint256 entityId, string newName): Allows entity owner to change its name.
// 6. transferEntityOwnership(uint256 entityId, address newOwner): Transfers ownership of an entity to another address.
// 7. retireEntity(uint256 entityId): Marks an entity as inactive, preventing most state changes and entanglement. Callable by owner.
// 8. isEntityActive(uint256 entityId) view: Checks if an entity is currently active.

// --- Dynamic Attributes ---
// 9. setDynamicAttribute(uint256 entityId, string key, string value): Adds or updates a custom string attribute for an entity. Callable by owner.
// 10. getDynamicAttribute(uint256 entityId, string key) view: Retrieves a dynamic attribute's value.
// 11. removeDynamicAttribute(uint256 entityId, string key): Removes a dynamic attribute from an entity. Callable by owner.

// --- Entanglement ---
// 12. entangleEntities(uint256 entity1Id, uint256 entity2Id): Entangles two active, non-entangled entities. Callable by owner of *both* or contract owner.
// 13. disentangleEntity(uint256 entityId): Disentangles an entity from its partner. Callable by owner of *either* entangled entity or contract owner.
// 14. isEntangled(uint256 entityId) view: Checks if an entity is currently entangled.
// 15. getEntangledWith(uint256 entityId) view: Gets the ID of the entity's entangled partner (0 if not entangled).

// --- Quantum State Mechanics ---
// 16. setStateSuperposition(uint256 entityId, bool isInSuperposition): Manually sets the superposition status of an entity. Callable by owner.
// 17. setDefiniteState(uint256 entityId, uint8 newState): Sets the definite state of an entity, but only if it's NOT in superposition. Callable by owner.
// 18. forceSetDefiniteState(uint256 entityId, uint8 newState): Forces an entity into a definite state, collapsing any superposition. Callable by owner.
// 19. observeState(uint256 entityId): Simulates observation. Collapses superposition (probabilistically) if in one. May affect entangled partner. Subject to cooldown. Callable by anyone.
// 20. getLastObservationTime(uint256 entityId) view: Gets the timestamp of the last observation for an entity.

// --- Utility & Governance (Owner-only) ---
// 21. setObservationCooldown(uint256 seconds): Sets the minimum time between observations for any entity.
// 22. getObservationCooldown() view: Gets the current observation cooldown duration.
// 23. setPropagationChance(uint256 basisPoints): Sets the probability (in basis points, 0-10000) of state propagation to an entangled partner upon observation.
// 24. getPropagationChance() view: Gets the current state propagation chance.
// 25. getTotalEntities() view: Gets the total number of entities ever created.

// --- Ownable (Inherited from OpenZeppelin) ---
// 26. owner() view: Get the contract owner.
// 27. transferOwnership(address newOwner): Transfer contract ownership.
// 28. renounceOwnership(): Renounce contract ownership.

contract QuantumEntanglementRegistry is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Though mostly implicit in 0.8+ arithmetic

    // --- State Variables ---
    struct Entity {
        address owner;
        string name;
        uint8 quantumState; // The definite state (meaningful when isSuperpositioned is false)
        bool isSuperpositioned; // True if the state is uncertain
        uint256 entangledWith; // ID of the partner entity (0 if not entangled)
        uint256 lastObservationTime; // Timestamp of the last observeState call
        bool isActive; // Can be marked inactive (e.g., retired)
        mapping(string => string) dynamicAttributes; // Custom key-value attributes
    }

    mapping(uint256 => Entity) private entities;
    Counters.Counter private _entityIdCounter;

    uint256 public observationCooldown; // Minimum seconds between observations per entity
    uint256 public propagationChance; // Probability in basis points (0-10000) for entangled state propagation

    // --- Events ---
    event EntityCreated(uint256 entityId, address owner, string name, uint8 initialState);
    event EntityNameUpdated(uint256 entityId, string newName);
    event EntityOwnershipTransferred(uint256 entityId, address oldOwner, address newOwner);
    event EntityRetired(uint256 entityId);
    event DynamicAttributeSet(uint256 entityId, string key, string value);
    event DynamicAttributeRemoved(uint256 entityId, string key);

    event EntitiesEntangled(uint256 entity1Id, uint256 entity2Id);
    event EntityDisentangled(uint256 entityId, uint256 partnerId);

    event StateSuperpositionSet(uint256 entityId, bool isInSuperposition);
    event StateDefiniteSet(uint256 entityId, uint8 newState, bool forced);
    event Observed(uint256 entityId, uint8 finalState, bool wasSuperpositioned, bool propagatedToPartner);
    event EntangledStatePropagated(uint256 fromEntityId, uint256 toEntityId, uint8 newState);

    // --- Modifiers ---
    modifier onlyEntityOwner(uint256 entityId) {
        require(entities[entityId].owner == msg.sender, "Not entity owner");
        _;
    }

    modifier mustExistAndBeActive(uint256 entityId) {
        require(entities[entityId].owner != address(0), "Entity does not exist");
        require(entities[entityId].isActive, "Entity is not active");
        _;
    }

    modifier mustBeInactive(uint256 entityId) {
        require(entities[entityId].owner != address(0), "Entity does not exist"); // Still needs to exist to check inactive state
        require(!entities[entityId].isActive, "Entity is active");
        _;
    }

    modifier mustNotBeEntangled(uint256 entityId) {
        require(entities[entityId].entangledWith == 0, "Entity is already entangled");
        _;
    }

    modifier mustBeEntangled(uint256 entityId) {
        require(entities[entityId].entangledWith != 0, "Entity is not entangled");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _observationCooldown, uint256 _propagationChance) Ownable(msg.sender) {
        // Sanity check chance (basis points 0-10000)
        require(_propagationChance <= 10000, "Propagation chance must be <= 10000 basis points");
        observationCooldown = _observationCooldown;
        propagationChance = _propagationChance;
        // Entity ID 0 is reserved as "not entangled" or "non-existent" indicator.
        _entityIdCounter.increment(); // Start counter at 1
    }

    // --- Core Registry Functions ---

    /**
     * @notice Creates a new unique digital entity.
     * @param name The name of the entity.
     * @param initialDefiniteState The initial underlying definite state the entity might collapse to.
     * @return The ID of the newly created entity.
     */
    function createEntity(string memory name, uint8 initialDefiniteState) public returns (uint256) {
        _entityIdCounter.increment();
        uint256 newId = _entityIdCounter.current();

        entities[newId] = Entity({
            owner: msg.sender,
            name: name,
            quantumState: initialDefiniteState, // Store the potential initial state
            isSuperpositioned: true, // New entities start in superposition
            entangledWith: 0, // Not entangled initially
            lastObservationTime: 0, // Never observed yet
            isActive: true // Active by default
        });

        emit EntityCreated(newId, msg.sender, name, initialDefiniteState);
        return newId;
    }

    /**
     * @notice Retrieves detailed information about an entity.
     * @param entityId The ID of the entity.
     * @return owner The entity's owner address.
     * @return name The entity's name.
     * @return quantumState The definite quantum state (if not in superposition).
     * @return isSuperpositioned Whether the entity is in superposition.
     * @return entangledWith The ID of the entangled partner (0 if none).
     * @return isActive Whether the entity is active.
     */
    function getEntity(uint256 entityId) public view mustExistAndBeActive(entityId) returns (address owner, string memory name, uint8 quantumState, bool isSuperpositioned, uint256 entangledWith, bool isActive) {
         Entity storage entity = entities[entityId];
         return (entity.owner, entity.name, entity.quantumState, entity.isSuperpositioned, entity.entangledWith, entity.isActive);
    }

    /**
     * @notice Gets the owner address of an entity.
     * @param entityId The ID of the entity.
     * @return The owner address.
     */
    function getEntityOwner(uint256 entityId) public view mustExistAndBeActive(entityId) returns (address) {
        return entities[entityId].owner;
    }

    /**
     * @notice Gets the current quantum state and superposition status of an entity.
     * @param entityId The ID of the entity.
     * @return quantumState The definite state if not in superposition (else potentially initial state).
     * @return isSuperpositioned Whether the entity is in superposition.
     */
    function getEntityState(uint256 entityId) public view mustExistAndBeActive(entityId) returns (uint8 quantumState, bool isSuperpositioned) {
        Entity storage entity = entities[entityId];
        return (entity.quantumState, entity.isSuperpositioned);
    }

    /**
     * @notice Allows the entity owner to change its name.
     * @param entityId The ID of the entity.
     * @param newName The new name for the entity.
     */
    function setEntityName(uint256 entityId, string memory newName) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        entities[entityId].name = newName;
        emit EntityNameUpdated(entityId, newName);
    }

     /**
     * @notice Transfers ownership of an entity to a new address.
     * @param entityId The ID of the entity.
     * @param newOwner The address of the new owner.
     */
    function transferEntityOwnership(uint256 entityId, address newOwner) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = entities[entityId].owner;
        entities[entityId].owner = newOwner;
        emit EntityOwnershipTransferred(entityId, oldOwner, newOwner);
    }

    /**
     * @notice Marks an entity as inactive (retired). Prevents most state changes and entanglement.
     * @param entityId The ID of the entity.
     */
    function retireEntity(uint256 entityId) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        // Cannot retire if entangled (must disentangle first)
        require(entities[entityId].entangledWith == 0, "Cannot retire an entangled entity");

        entities[entityId].isActive = false;
        emit EntityRetired(entityId);
    }

    /**
     * @notice Checks if an entity is currently active (not retired).
     * @param entityId The ID of the entity.
     * @return True if active, false otherwise.
     */
    function isEntityActive(uint256 entityId) public view returns (bool) {
        return entities[entityId].owner != address(0) && entities[entityId].isActive;
    }


    // --- Dynamic Attribute Functions ---

    /**
     * @notice Adds or updates a custom string attribute for an entity.
     * @param entityId The ID of the entity.
     * @param key The attribute key.
     * @param value The attribute value.
     */
    function setDynamicAttribute(uint256 entityId, string memory key, string memory value) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        entities[entityId].dynamicAttributes[key] = value;
        emit DynamicAttributeSet(entityId, key, value);
    }

    /**
     * @notice Retrieves a dynamic attribute's value. Returns empty string if not found.
     * @param entityId The ID of the entity.
     * @param key The attribute key.
     * @return The attribute value.
     */
    function getDynamicAttribute(uint256 entityId, string memory key) public view mustExistAndBeActive(entityId) returns (string memory) {
        return entities[entityId].dynamicAttributes[key];
    }

    /**
     * @notice Removes a dynamic attribute from an entity.
     * @param entityId The ID of the entity.
     * @param key The attribute key.
     */
    function removeDynamicAttribute(uint256 entityId, string memory key) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        delete entities[entityId].dynamicAttributes[key];
        emit DynamicAttributeRemoved(entityId, key);
    }

    // --- Entanglement Functions ---

    /**
     * @notice Entangles two active, non-entangled entities. Requires ownership of both or contract owner permission.
     * @param entity1Id The ID of the first entity.
     * @param entity2Id The ID of the second entity.
     */
    function entangleEntities(uint256 entity1Id, uint256 entity2Id) public {
        require(entity1Id != entity2Id, "Cannot entangle an entity with itself");
        mustExistAndBeActive(entity1Id);
        mustExistAndBeActive(entity2Id);
        mustNotBeEntangled(entity1Id);
        mustNotBeEntangled(entity2Id);

        // Either caller owns both, or contract owner calls
        bool callerOwnsBoth = entities[entity1Id].owner == msg.sender && entities[entity2Id].owner == msg.sender;
        require(callerOwnsBoth || owner() == msg.sender, "Caller must own both entities or be the contract owner");

        entities[entity1Id].entangledWith = entity2Id;
        entities[entity2Id].entangledWith = entity1Id;

        emit EntitiesEntangled(entity1Id, entity2Id);
    }

    /**
     * @notice Disentangles an entity from its partner. Callable by owner of either entity or contract owner.
     * @param entityId The ID of the entity to disentangle.
     */
    function disentangleEntity(uint256 entityId) public mustExistAndBeActive(entityId) mustBeEntangled(entityId) {
        uint256 partnerId = entities[entityId].entangledWith;
        require(partnerId != 0, "Entity is not entangled"); // Should be caught by modifier, but good practice

        // Either caller owns one, or contract owner calls
        bool callerOwnsOne = entities[entityId].owner == msg.sender || entities[partnerId].owner == msg.sender;
        require(callerOwnsOne || owner() == msg.sender, "Caller must own one of the entities or be the contract owner");

        entities[entityId].entangledWith = 0;
        entities[partnerId].entangledWith = 0; // Disentangle the partner too

        emit EntityDisentangled(entityId, partnerId);
        emit EntityDisentangled(partnerId, entityId); // Emit for both sides for clarity
    }

    /**
     * @notice Checks if an entity is currently entangled with another.
     * @param entityId The ID of the entity.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 entityId) public view mustExistAndBeActive(entityId) returns (bool) {
        return entities[entityId].entangledWith != 0;
    }

    /**
     * @notice Gets the ID of the entity's entangled partner.
     * @param entityId The ID of the entity.
     * @return The partner entity ID (0 if not entangled).
     */
    function getEntangledWith(uint256 entityId) public view mustExistAndBeActive(entityId) returns (uint256) {
        return entities[entityId].entangledWith;
    }

    // --- Quantum State Functions ---

    /**
     * @notice Manually sets the superposition status of an entity.
     * @param entityId The ID of the entity.
     * @param isInSuperposition The new superposition status.
     */
    function setStateSuperposition(uint256 entityId, bool isInSuperposition) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        entities[entityId].isSuperpositioned = isInSuperposition;
        emit StateSuperpositionSet(entityId, isInSuperposition);
    }

    /**
     * @notice Sets the definite state of an entity, but only if it's NOT in superposition.
     * @param entityId The ID of the entity.
     * @param newState The new definite state.
     */
    function setDefiniteState(uint256 entityId, uint8 newState) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        require(!entities[entityId].isSuperpositioned, "Entity must not be in superposition to set definite state directly");
        entities[entityId].quantumState = newState;
        emit StateDefiniteSet(entityId, newState, false);
        // Note: Setting definite state directly does NOT trigger entangled propagation automatically
    }

    /**
     * @notice Forces an entity into a definite state, collapsing any superposition.
     * @param entityId The ID of the entity.
     * @param newState The new definite state.
     */
    function forceSetDefiniteState(uint256 entityId, uint8 newState) public mustExistAndBeActive(entityId) onlyEntityOwner(entityId) {
        entities[entityId].isSuperpositioned = false;
        entities[entityId].quantumState = newState;
        emit StateDefiniteSet(entityId, newState, true);
        // Note: Forcing definite state directly does NOT trigger entangled propagation automatically
    }


    /**
     * @notice Simulates observation. Collapses superposition (probabilistically) if in one.
     *         May affect entangled partner based on propagation chance. Subject to cooldown.
     *         Callable by anyone.
     * @param entityId The ID of the entity to observe.
     */
    function observeState(uint256 entityId) public mustExistAndBeActive(entityId) {
        require(block.timestamp >= entities[entityId].lastObservationTime + observationCooldown, "Observation cooldown in effect");

        Entity storage entity = entities[entityId];
        uint8 finalState = entity.quantumState; // Default if not in superposition
        bool wasSuperpositioned = entity.isSuperpositioned;
        bool propagated = false;

        if (wasSuperpositioned) {
            // Simulate probabilistic collapse
            // Use block data for pseudo-randomness (deterministic on EVM, but sufficient for simulation)
            uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, entityId))) % 10000;

            // Collapse logic: Bias towards the initial 'quantumState' value stored when created/set
            // Example: If initial state was 0, (10000 - propagationChance)% chance to collapse to 0, else collapse to 1.
            // If initial state was 1, (10000 - propagationChance)% chance to collapse to 1, else collapse to 0.
            // If initial state was something else, 50/50 chance (simplistic, can be refined)
            if (entity.quantumState == 0) {
                 if (randomFactor < (10000 - propagationChance)) {
                    finalState = 0;
                } else {
                    finalState = 1;
                }
            } else if (entity.quantumState == 1) {
                 if (randomFactor < (10000 - propagationChance)) {
                    finalState = 1;
                } else {
                    finalState = 0;
                }
            } else { // For other states, perhaps 50/50 between 0 and 1, or just stick to the initial state?
                     // Let's make it 50/50 between 0 and 1 for simplicity if initial state wasn't 0 or 1
                if (randomFactor < 5000) {
                    finalState = 0;
                } else {
                    finalState = 1;
                }
            }

            entity.isSuperpositioned = false;
            entity.quantumState = finalState;
            emit StateDefiniteSet(entityId, finalState, true); // Collapse is effectively a forced set
            emit StateChanged(entityId, finalState, false); // Indicate the state changed

            // --- Entangled Propagation (Spooky Action) ---
            if (entity.entangledWith != 0) {
                uint256 partnerId = entity.entangledWith;
                // Check if partner exists and is active (in case it was retired concurrently)
                if (entities[partnerId].owner != address(0) && entities[partnerId].isActive) {
                     // Separate random check for propagation
                     uint256 propagationRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, partnerId))) % 10000;

                    if (propagationRandom < propagationChance) {
                         // Propagate a change: Flip the partner's definite state
                        Entity storage partnerEntity = entities[partnerId];
                        uint8 partnerNewState = (partnerEntity.quantumState == 0) ? 1 : 0; // Simple flip 0->1, 1->0

                         // Propagation forces partner collapse too if it was in superposition
                        partnerEntity.isSuperpositioned = false;
                        partnerEntity.quantumState = partnerNewState;
                        propagated = true; // Mark that propagation occurred
                        emit EntangledStatePropagated(entityId, partnerId, partnerNewState);
                        emit StateDefiniteSet(partnerId, partnerNewState, true); // Propagation is also a forced set
                        emit StateChanged(partnerId, partnerNewState, false); // Indicate partner state changed
                    }
                }
            }
        } else {
             // If not in superposition, observation just updates the timestamp.
             // StateChanged event only emitted if state actually changed (which it didn't here).
        }

        entity.lastObservationTime = block.timestamp;
        emit Observed(entityId, entity.quantumState, wasSuperpositioned, propagated);
    }

     // Event for general state changes (helpful to track any definite state change)
     event StateChanged(uint256 entityId, uint8 newState, bool isInSuperposition);


    /**
     * @notice Gets the timestamp of the last observation for an entity.
     * @param entityId The ID of the entity.
     * @return The timestamp (0 if never observed).
     */
    function getLastObservationTime(uint256 entityId) public view mustExistAndBeActive(entityId) returns (uint256) {
        return entities[entityId].lastObservationTime;
    }


    // --- Utility & Governance Functions (Owner-only) ---

    /**
     * @notice Sets the minimum time between observations for any entity.
     * @param seconds The new cooldown duration in seconds.
     */
    function setObservationCooldown(uint256 seconds) public onlyOwner {
        observationCooldown = seconds;
    }

    /**
     * @notice Gets the current observation cooldown duration.
     * @return The cooldown in seconds.
     */
    function getObservationCooldown() public view returns (uint256) {
        return observationCooldown;
    }

    /**
     * @notice Sets the probability (in basis points, 0-10000) of state propagation
     *         to an entangled partner upon observation. Also influences collapse probability.
     * @param basisPoints The probability in basis points (e.g., 1000 = 10%).
     */
    function setPropagationChance(uint256 basisPoints) public onlyOwner {
        require(basisPoints <= 10000, "Propagation chance must be <= 10000 basis points");
        propagationChance = basisPoints;
    }

     /**
     * @notice Gets the current state propagation chance.
     * @return The probability in basis points (0-10000).
     */
    function getPropagationChance() public view returns (uint256) {
        return propagationChance;
    }


    /**
     * @notice Gets the total number of entities ever created.
     * @return The total count.
     */
    function getTotalEntities() public view returns (uint256) {
        return _entityIdCounter.current();
    }

    // Ownable functions (owner, transferOwnership, renounceOwnership) are inherited.
    // They manage the contract owner, not entity owners.
}
```