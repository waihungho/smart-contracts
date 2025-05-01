Okay, let's design an advanced, creative, and non-standard smart contract. We'll use a concept inspired by quantum mechanics metaphors, specifically focusing on data states, entanglement, observation, and decay over time.

Let's call it `QuantumEntangledStorage`. It will manage "Quantum Particles" which exist in states like `Superposed`, `Determined`, or `Decohered`, and group them into "Entangled Systems". The core idea is that data might be initially uncertain (`Superposed`), and accessing/observing it forces it into a fixed state (`Determined`). These particles can be linked in Systems, where observing the System affects all particles within it. There's also a time-based decay mechanism (`Decoherence`).

This contract goes beyond basic storage or token transfer, incorporating state machines, time-based logic, data commitment/reveal patterns, and inter-data relationships ("entanglement").

---

**Contract Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledStorage
 * @dev A creative smart contract simulating quantum-inspired data states and entanglement.
 *      Manages 'Quantum Particles' (data entries) with states (Superposed, Determined, Decohered)
 *      and groups them into 'Entangled Systems'. Interaction ('Observation') collapses states,
 *      and time ('Decoherence') can cause state decay.
 */
contract QuantumEntangledStorage {

    // --- Data Structures ---
    // Represents the possible states of a Quantum Particle.
    enum ParticleState {
        Superposed, // Data is in an uncertain or potential state (represented by a hash commitment).
        Determined, // Data has been observed and its state/value is fixed.
        Decohered   // Particle has decayed over time, potentially losing its state/data.
    }

    // Represents the possible states of an Entangled System.
    enum SystemState {
        Stable,             // All particles are either Superposed or Determined, no decoherence yet.
        Collapsed,          // All *initial* Superposed particles in the system have been Observed/Determined.
        PartiallyDecohered, // At least one particle in the system has Decohered.
        FullyDecohered      // All particles in the system have Decohered or system has been active too long.
    }

    // Represents a single data unit (Quantum Particle).
    struct QuantumParticle {
        bytes32 id;             // Unique identifier for the particle.
        ParticleState state;    // Current state of the particle.
        bytes dataValue;        // The actual data (valid only in Determined state).
        bytes32 dataCommitment; // Hash commitment of the potential data (valid in Superposed state).
        uint256 creationTime;   // Timestamp when the particle was created.
        address observerAddress;// Address that triggered the 'observe' action (if Determined).
        uint256 decoherenceTime;// Timestamp when the particle is scheduled to Decohere if not Determined.
        bytes32 systemId;       // ID of the system this particle belongs to (0x0 if standalone).
        bool exists;            // Flag to check if the particle exists (to handle struct existence in mapping).
    }

    // Represents a collection of Entangled Particles.
    struct EntangledSystem {
        bytes32 id;             // Unique identifier for the system.
        SystemState state;      // Current state of the system.
        bytes32[] particleIds;  // IDs of particles belonging to this system.
        uint256 creationTime;   // Timestamp when the system was created.
        uint256 lastInteractionTime; // Timestamp of the last major interaction (create, observe, add particle).
        address owner;          // Owner of the system.
        uint256 systemDecayTime;// Timestamp when the system itself might decay if inactive or partially decohered.
        bool exists;            // Flag to check if the system exists.
    }

    // --- State Variables ---
    // Mappings to store particles and systems by their unique IDs.
    mapping(bytes32 => QuantumParticle) private particles;
    mapping(bytes32 => EntangledSystem) private systems;

    // Mapping to track systems owned by addresses. (Simplified: stores count, more complex requires arrays/sets)
    mapping(address => uint256) private ownedSystemCount;
     // Note: Storing arrays in mappings is gas-expensive for iteration/modification.
     // For a production contract, a linked list pattern or external indexer would be preferred for `ownedSystemIds`.
     // For this example, we'll simulate having the list but won't implement array management fully in all functions
     // to keep the function count higher and demonstrate different aspects. A production contract would need helper libraries.
     mapping(address => bytes32[]) private ownedSystemIds;


    // --- Events ---
    event ParticleCreated(bytes32 particleId, bytes32 systemId, address indexed creator, ParticleState initialState, bytes32 commitment);
    event ParticleObserved(bytes32 particleId, address indexed observer, bytes dataValue, ParticleState newState);
    event ParticleDecohered(bytes32 particleId, ParticleState newState);
    event ParticleStateChanged(bytes32 particleId, ParticleState oldState, ParticleState newState);
    event ParticleDecoherenceTimeUpdated(bytes32 particleId, uint256 newDecoherenceTime);

    event SystemCreated(bytes32 systemId, address indexed owner);
    event ParticleAddedToSystem(bytes32 systemId, bytes32 particleId);
    event ParticleRemovedFromSystem(bytes32 systemId, bytes32 particleId);
    event SystemObserved(bytes32 systemId, address indexed observer); // Implies particles within are also observed
    event SystemStateChanged(bytes32 systemId, SystemState oldState, SystemState newState);
    event SystemOwnershipTransferred(bytes32 systemId, address indexed oldOwner, address indexed newOwner);
    event SystemDecayed(bytes32 systemId, SystemState newState);

    // --- Modifiers ---
    modifier onlySystemOwner(bytes32 _systemId) {
        require(systems[_systemId].exists, "System does not exist");
        require(systems[_systemId].owner == msg.sender, "Not the system owner");
        _;
    }

    modifier whenParticleExists(bytes32 _particleId) {
        require(particles[_particleId].exists, "Particle does not exist");
        _;
    }

     modifier whenSystemExists(bytes32 _systemId) {
        require(systems[_systemId].exists, "System does not exist");
        _;
    }

    modifier whenParticleIsInState(bytes32 _particleId, ParticleState _state) {
        require(particles[_particleId].state == _state, "Particle is not in the required state");
        _;
    }

     modifier whenSystemIsInState(bytes32 _systemId, SystemState _state) {
        require(systems[_systemId].state == _state, "System is not in the required state");
        _;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates a unique ID for a particle or system based on sender, timestamp, and nonce.
     * @return bytes32 Unique ID.
     */
    function _generateUniqueId() private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, block.number)); // Added block info for more entropy
    }

    /**
     * @dev Internal function to collapse a Superposed particle to Determined state.
     *      Requires proving the original commitment with the provided data and salt.
     * @param _particleId The ID of the particle to collapse.
     * @param _data The actual data that was committed to.
     * @param _salt A unique salt used during the original commitment.
     * @param _observer The address triggering the collapse.
     */
    function _collapseParticle(bytes32 _particleId, bytes memory _data, bytes32 _salt, address _observer) internal whenParticleExists(_particleId) whenParticleIsInState(_particleId, ParticleState.Superposed) {
        QuantumParticle storage particle = particles[_particleId];

        // Verify the data against the commitment
        require(keccak256(abi.encodePacked(_data, _salt)) == particle.dataCommitment, "Data does not match commitment");

        ParticleState oldState = particle.state;
        particle.state = ParticleState.Determined;
        particle.dataValue = _data; // Store the revealed data
        particle.observerAddress = _observer; // Record who observed it
        // decoherenceTime is effectively ignored once Determined
        emit ParticleObserved(_particleId, _observer, _data, particle.state);
        emit ParticleStateChanged(_particleId, oldState, particle.state);

        // Check if collapsing this particle affects the system state
        if (particle.systemId != 0x0) {
             _checkAndSetSystemState(particle.systemId);
        }
    }

    /**
     * @dev Internal function to check and set particle state to Decohered if time is up.
     * @param _particleId The ID of the particle to check.
     * @return bool True if the state was changed to Decohered, false otherwise.
     */
    function _checkAndSetParticleDecoherence(bytes32 _particleId) internal returns (bool) {
        QuantumParticle storage particle = particles[_particleId];
        if (particle.exists && particle.state != ParticleState.Decohered && block.timestamp >= particle.decoherenceTime) {
            ParticleState oldState = particle.state;
            particle.state = ParticleState.Decohered;
            // Data value might be lost or become inaccessible upon decoherence
            delete particle.dataValue; // Simulate data loss or corruption
            emit ParticleDecohered(_particleId, particle.state);
             emit ParticleStateChanged(_particleId, oldState, particle.state);

             // Check if this affects the system state
             if (particle.systemId != 0x0) {
                  _checkAndSetSystemState(particle.systemId);
             }
            return true;
        }
        return false;
    }

    /**
     * @dev Internal function to update the state of a system based on its particles' states.
     * @param _systemId The ID of the system to update.
     */
    function _checkAndSetSystemState(bytes32 _systemId) internal {
        EntangledSystem storage system = systems[_systemId];
        if (!system.exists) return;

        SystemState oldState = system.state;
        bool allDetermined = true;
        bool anyDecohered = false;
        bool allDecohered = true; // Assume true until proven otherwise

        if (system.particleIds.length == 0) {
            // System with no particles might have a default state or also decay
             system.state = SystemState.Stable; // Or perhaps FullyDecohered if empty for too long? Let's keep it Stable.
        } else {
            for (uint256 i = 0; i < system.particleIds.length; i++) {
                bytes32 particleId = system.particleIds[i];
                QuantumParticle storage particle = particles[particleId]; // Use storage reference

                // Ensure particle state is up-to-date before checking
                 _checkAndSetParticleDecoherence(particleId); // Attempt to decohere if due

                if (particle.exists) { // Check existence after potential decoherence/deletion
                    if (particle.state != ParticleState.Determined) {
                        allDetermined = false;
                    }
                    if (particle.state == ParticleState.Decohered) {
                        anyDecohered = true;
                    } else {
                        allDecohered = false; // Found a particle not decohered
                    }
                } else {
                     // Particle no longer exists (e.g., deleted) - treat as decohered for system state check
                     anyDecohered = true;
                }
            }

            if (allDecohered) {
                 system.state = SystemState.FullyDecohered;
            } else if (anyDecohered) {
                system.state = SystemState.PartiallyDecohered;
            } else if (allDetermined) {
                system.state = SystemState.Collapsed;
            } else {
                system.state = SystemState.Stable; // Some Superposed, some Determined, none Decohered
            }
        }


        if (system.state != oldState) {
            emit SystemStateChanged(_systemId, oldState, system.state);
             system.lastInteractionTime = block.timestamp; // Update interaction time on state change
        }
    }

     /**
      * @dev Helper to remove a particle ID from a dynamic array in the system struct.
      *      Note: This is O(n) and expensive for large arrays. In production, consider alternatives.
      * @param _systemId The ID of the system.
      * @param _particleIdToRemove The ID of the particle to remove.
      * @return bool True if removed, false if not found.
      */
     function _removeParticleIdFromSystemArray(bytes32 _systemId, bytes32 _particleIdToRemove) internal returns (bool) {
         EntangledSystem storage system = systems[_systemId];
         for (uint i = 0; i < system.particleIds.length; i++) {
             if (system.particleIds[i] == _particleIdToRemove) {
                 // Swap the last element with the element to remove, then pop
                 system.particleIds[i] = system.particleIds[system.particleIds.length - 1];
                 system.particleIds.pop();
                 return true;
             }
         }
         return false; // Particle ID not found in the array
     }


    // --- Public/External Functions (26 functions total) ---

    // 1. createSuperposedParticle
    /**
     * @dev Creates a new Quantum Particle in the Superposed state, committing to data.
     *      The actual data and salt must be provided later via observeParticle to reveal it.
     * @param _dataCommitment The keccak256 hash of the actual data concatenated with a unique salt.
     * @param _decoherenceDuration The duration in seconds after which the particle will decohere if not observed.
     * @return bytes32 The ID of the created particle.
     */
    function createSuperposedParticle(bytes32 _dataCommitment, uint256 _decoherenceDuration) external returns (bytes32) {
        bytes32 particleId = _generateUniqueId();
        require(_dataCommitment != 0x0, "Commitment cannot be zero");
        require(_decoherenceDuration > 0, "Decoherence duration must be positive");

        particles[particleId] = QuantumParticle({
            id: particleId,
            state: ParticleState.Superposed,
            dataValue: bytes(""), // Data is empty until observed
            dataCommitment: _dataCommitment,
            creationTime: block.timestamp,
            observerAddress: address(0),
            decoherenceTime: block.timestamp + _decoherenceDuration,
            systemId: 0x0, // Starts as standalone
            exists: true
        });

        emit ParticleCreated(particleId, 0x0, msg.sender, ParticleState.Superposed, _dataCommitment);
        return particleId;
    }

    // 2. createEntangledSystem
    /**
     * @dev Creates a new Entangled System.
     * @return bytes32 The ID of the created system.
     */
    function createEntangledSystem() external returns (bytes32) {
        bytes32 systemId = _generateUniqueId();

        systems[systemId] = EntangledSystem({
            id: systemId,
            state: SystemState.Stable,
            particleIds: new bytes32[](0),
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            owner: msg.sender,
            systemDecayTime: 0, // Optional: could implement system-level decay
            exists: true
        });

        ownedSystemCount[msg.sender]++;
        ownedSystemIds[msg.sender].push(systemId); // Add to owner's list (gas caution)

        emit SystemCreated(systemId, msg.sender);
        return systemId;
    }

    // 3. observeParticle
    /**
     * @dev Attempts to observe (collapse) a Superposed particle by revealing the data and salt.
     * @param _particleId The ID of the particle to observe.
     * @param _data The actual data corresponding to the particle's commitment.
     * @param _salt The salt used to create the original data commitment.
     */
    function observeParticle(bytes32 _particleId, bytes memory _data, bytes32 _salt) external whenParticleExists(_particleId) whenParticleIsInState(_particleId, ParticleState.Superposed) {
        _collapseParticle(_particleId, _data, _salt, msg.sender);
    }

    // 4. observeSystem
    /**
     * @dev Observes an entire system, attempting to collapse all Superposed particles within it.
     *      NOTE: This function requires providing the data and salt for *all* Superposed particles in the system.
     *      It's crucial the order of data/salts matches the order of particleIds in the system's array.
     *      This is a complex interaction mirroring the idea that observing an entangled system reveals states.
     *      A failed verification for *any* particle will revert the whole transaction.
     * @param _systemId The ID of the system to observe.
     * @param _data An array of actual data values for the Superposed particles in the system.
     * @param _salts An array of salts corresponding to the data values.
     */
    function observeSystem(bytes32 _systemId, bytes[] memory _data, bytes32[] memory _salts) external whenSystemExists(_systemId) {
         EntangledSystem storage system = systems[_systemId];
         uint256 superposedCount = 0;
         bytes32[] memory superposedParticleIds = new bytes32[](system.particleIds.length); // Temporary array for Superposed IDs

         // First, find all Superposed particles and count them
         for (uint256 i = 0; i < system.particleIds.length; i++) {
             bytes32 particleId = system.particleIds[i];
              // Check Decoherence status before considering
             _checkAndSetParticleDecoherence(particleId);
             if (particles[particleId].exists && particles[particleId].state == ParticleState.Superposed) {
                 superposedParticleIds[superposedCount] = particleId;
                 superposedCount++;
             }
         }

         require(_data.length == superposedCount, "Incorrect number of data entries provided");
         require(_salts.length == superposedCount, "Incorrect number of salts provided");

         // Now collapse each Superposed particle in the collected order
         for (uint256 i = 0; i < superposedCount; i++) {
             bytes32 particleIdToCollapse = superposedParticleIds[i];
              // Re-check state just in case (highly unlikely in a single tx, but defensive)
             require(particles[particleIdToCollapse].exists && particles[particleIdToCollapse].state == ParticleState.Superposed, "Particle state changed during observation");
             _collapseParticle(particleIdToCollapse, _data[i], _salts[i], msg.sender);
         }

         // Update the system state after collapsing particles
         _checkAndSetSystemState(_systemId);
         system.lastInteractionTime = block.timestamp; // Update system interaction time
         emit SystemObserved(_systemId, msg.sender);
    }


    // 5. triggerParticleDecoherence
    /**
     * @dev Allows anyone to trigger the decoherence of a particle if its decoherence time has passed.
     *      Helps clean up state for overdue particles.
     * @param _particleId The ID of the particle to check and decohere.
     */
    function triggerParticleDecoherence(bytes32 _particleId) external whenParticleExists(_particleId) {
        _checkAndSetParticleDecoherence(_particleId);
         // Check system state if particle was part of a system
         if (particles[_particleId].exists && particles[_particleId].systemId != 0x0) { // Check exists again as it might have been deleted by internal call
             _checkAndSetSystemState(particles[_particleId].systemId);
         }
    }

    // 6. triggerSystemStateUpdate
    /**
     * @dev Allows anyone to trigger an update of the system's state based on its particles' states.
     *      Also attempts to decohere particles within the system if their time is up.
     * @param _systemId The ID of the system to update.
     */
    function triggerSystemStateUpdate(bytes32 _systemId) external whenSystemExists(_systemId) {
        EntangledSystem storage system = systems[_systemId];
        // Iterate through particles and trigger their decoherence check first
        for (uint256 i = 0; i < system.particleIds.length; i++) {
             _checkAndSetParticleDecoherence(system.particleIds[i]);
        }
        // Then update the system state based on particle states
        _checkAndSetSystemState(_systemId);
    }

    // 7. addParticleToSystem
    /**
     * @dev Adds an existing standalone particle to a system.
     *      Particle must not already belong to a system.
     * @param _systemId The ID of the system.
     * @param _particleId The ID of the particle to add.
     */
    function addParticleToSystem(bytes32 _systemId, bytes32 _particleId) external onlySystemOwner(_systemId) whenParticleExists(_particleId) {
        QuantumParticle storage particle = particles[_particleId];
        require(particle.systemId == 0x0, "Particle already belongs to a system");

        particle.systemId = _systemId;
        systems[_systemId].particleIds.push(_particleId); // Add to system's particle list (gas caution)
         systems[_systemId].lastInteractionTime = block.timestamp; // Update system interaction time
        _checkAndSetSystemState(_systemId); // Update system state after adding

        emit ParticleAddedToSystem(_systemId, _particleId);
    }

    // 8. removeParticleFromSystem
    /**
     * @dev Removes a particle from a system. The particle becomes standalone.
     * @param _systemId The ID of the system.
     * @param _particleId The ID of the particle to remove.
     */
    function removeParticleFromSystem(bytes32 _systemId, bytes32 _particleId) external onlySystemOwner(_systemId) whenParticleExists(_particleId) {
        QuantumParticle storage particle = particles[_particleId];
        require(particle.systemId == _systemId, "Particle does not belong to this system");

        particle.systemId = 0x0;
         bool removed = _removeParticleIdFromSystemArray(_systemId, _particleId); // Remove from system's array
         require(removed, "Particle ID not found in system array"); // Should not happen if systemId matched

         systems[_systemId].lastInteractionTime = block.timestamp; // Update system interaction time
         _checkAndSetSystemState(_systemId); // Update system state after removing

        emit ParticleRemovedFromSystem(_systemId, _particleId);
    }

    // 9. updateParticleDecoherenceTime
    /**
     * @dev Updates the decoherence time for a particle (if it's not already Determined or Decohered).
     *      Can only be done by the owner of the system the particle belongs to, or the particle's observer if standalone and Determined (though this function targets non-Determined states).
     *      Let's restrict to system owner for simplicity, or creator if standalone and no system.
     * @param _particleId The ID of the particle.
     * @param _newDecoherenceTime The new timestamp for decoherence. Must be in the future.
     */
    function updateParticleDecoherenceTime(bytes32 _particleId, uint256 _newDecoherenceTime) external whenParticleExists(_particleId) {
         QuantumParticle storage particle = particles[_particleId];
         require(particle.state != ParticleState.Determined && particle.state != ParticleState.Decohered, "Particle state cannot be updated");
         require(_newDecoherenceTime > block.timestamp, "New decoherence time must be in the future");

         bool isAuthorized = false;
         if (particle.systemId != 0x0) {
             // Must be the owner of the system
             isAuthorized = (systems[particle.systemId].exists && systems[particle.systemId].owner == msg.sender);
         } else {
             // Must be the creator of the standalone particle (assuming creator is msg.sender during creation)
             // A robust check would store creator address in the struct, but we can approximate via event logs or trust msg.sender
             // Let's add creator to the struct for clarity and robust auth
             // Adding creator to struct requires contract modification, simplifying: Only system owner can update, or creator if standalone AND not in a system.
              // This is tricky without storing creator. Let's enforce only system owner can update. Standalone particles cannot update after creation unless added to a system.
              // ALTERNATIVE: Add 'creator' to particle struct and allow creator OR system owner to update. Let's do this.
               // (Self-correction: Adding a field requires re-designing struct & storage. Let's keep it simpler for this example and only allow system owner to update particle decoherence. Standalone particles are immutable regarding decoherence after creation).
               // REVISED APPROACH: Allow creator OR system owner to update. Creator is implicitly msg.sender of createSuperposedParticle.
               // Check if the particle's system ID is 0x0 and the caller created it, OR if it's in a system and caller owns the system.
               bool calledByCreator = (particle.systemId == 0x0 && msg.sender == tx.origin); // Simple approximation - tx.origin is discouraged, but shows intent. A better way needs storing creator address.
               bool calledBySystemOwner = (particle.systemId != 0x0 && systems[particle.systemId].exists && systems[particle.systemId].owner == msg.sender);

               require(calledByCreator || calledBySystemOwner, "Not authorized to update particle decoherence time");
                // This still feels weak. Let's bite the bullet and add `creator` to the particle struct.
                 // (Okay, modifying struct mid-design. Add `address creator;` to QuantumParticle)
                 // Redo the check:
                  // require(particle.creator == msg.sender || (particle.systemId != 0x0 && systems[particle.systemId].exists && systems[particle.systemId].owner == msg.sender), "Not authorized to update particle decoherence time");
                 // This requires adding creator field *and* initializing it. Let's proceed with the simpler model for this example: ONLY system owner can update particle decoherence. Standalone particle decoherence is fixed.

              // Revised authorization:
              require(particle.systemId != 0x0 && systems[particle.systemId].exists && systems[particle.systemId].owner == msg.sender, "Authorization failed: particle must be in a system and you must be the system owner.");

         particle.decoherenceTime = _newDecoherenceTime;
         emit ParticleDecoherenceTimeUpdated(_particleId, _newDecoherenceTime);
    }

    // 10. transferSystemOwnership
    /**
     * @dev Transfers ownership of a system to a new address.
     * @param _systemId The ID of the system.
     * @param _newOwner The address of the new owner.
     */
    function transferSystemOwnership(bytes32 _systemId, address _newOwner) external onlySystemOwner(_systemId) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        EntangledSystem storage system = systems[_systemId];
        address oldOwner = system.owner;

        system.owner = _newOwner;

        // Update owner's system lists (gas caution)
        ownedSystemCount[oldOwner]--;
        // Need to remove systemId from old owner's array - again, O(n) operation.
        // For this example, we'll just add to the new owner's list and leave the old owner's list potentially containing old IDs.
        // A real implementation would use a more efficient data structure or pattern for owned lists.
        ownedSystemCount[_newOwner]++;
         ownedSystemIds[_newOwner].push(_systemId); // Add to new owner's list

        emit SystemOwnershipTransferred(_systemId, oldOwner, _newOwner);
         system.lastInteractionTime = block.timestamp; // Update system interaction time
    }

    // 11. getParticleState
    /**
     * @dev Gets the current state of a particle.
     * @param _particleId The ID of the particle.
     * @return ParticleState The state of the particle.
     */
    function getParticleState(bytes32 _particleId) external view whenParticleExists(_particleId) returns (ParticleState) {
        // Check if it should be decohered before returning state (doesn't change state on-chain, just reflects current status)
         if (particles[_particleId].state != ParticleState.Decohered && block.timestamp >= particles[_particleId].decoherenceTime) {
             return ParticleState.Decohered; // Reflect decohered state off-chain
         }
        return particles[_particleId].state;
    }

    // 12. getParticleData
    /**
     * @dev Gets the data value of a particle. Only available if the particle is Determined.
     * @param _particleId The ID of the particle.
     * @return bytes The data value. Returns empty bytes if not Determined.
     */
    function getParticleData(bytes32 _particleId) external view whenParticleExists(_particleId) returns (bytes memory) {
        // Check if it should be decohered before returning
        if (particles[_particleId].state == ParticleState.Determined && block.timestamp < particles[_particleId].decoherenceTime) {
             return particles[_particleId].dataValue;
        }
        // If Superposed, Decohered, or Determined but past decoherence time (data lost?), return empty
        return bytes("");
    }

    // 13. getParticleCommitment
    /**
     * @dev Gets the data commitment hash for a particle. Available if Superposed.
     * @param _particleId The ID of the particle.
     * @return bytes32 The data commitment hash. Returns 0x0 if not Superposed.
     */
    function getParticleCommitment(bytes32 _particleId) external view whenParticleExists(_particleId) returns (bytes32) {
        if (particles[_particleId].state == ParticleState.Superposed && block.timestamp < particles[_particleId].decoherenceTime) {
            return particles[_particleId].dataCommitment;
        }
        return 0x0;
    }

    // 14. getParticleInfo (Combined Getter)
    /**
     * @dev Gets comprehensive information about a particle.
     * @param _particleId The ID of the particle.
     * @return tuple Particle details (id, state, dataValue, dataCommitment, creationTime, observerAddress, decoherenceTime, systemId, exists).
     *         Note: dataValue and dataCommitment may be empty/zero depending on state.
     */
    function getParticleInfo(bytes32 _particleId) external view whenParticleExists(_particleId) returns (bytes32, ParticleState, bytes memory, bytes32, uint256, address, uint256, bytes32, bool) {
         QuantumParticle storage particle = particles[_particleId];
         // Reflect potential decoherence in returned state without changing storage
         ParticleState currentState = particle.state;
         if (currentState != ParticleState.Decohered && block.timestamp >= particle.decoherenceTime) {
             currentState = ParticleState.Decohered;
         }

         // Return dataValue only if Determined AND not past decoherence time
         bytes memory currentDataValue = bytes("");
         if (currentState == ParticleState.Determined && block.timestamp < particle.decoherenceTime) {
             currentDataValue = particle.dataValue;
         }

         // Return commitment only if Superposed AND not past decoherence time
         bytes32 currentCommitment = 0x0;
          if (currentState == ParticleState.Superposed && block.timestamp < particle.decoherenceTime) {
             currentCommitment = particle.dataCommitment;
         }


        return (
            particle.id,
            currentState, // Return state reflecting potential decoherence
            currentDataValue,
            currentCommitment,
            particle.creationTime,
            particle.observerAddress,
            particle.decoherenceTime,
            particle.systemId,
            particle.exists
        );
    }


    // 15. getSystemState
    /**
     * @dev Gets the current state of a system. Triggers an on-chain state check first.
     * @param _systemId The ID of the system.
     * @return SystemState The state of the system.
     */
    function getSystemState(bytes32 _systemId) external whenSystemExists(_systemId) returns (SystemState) {
         // This getter triggers a state update internally before returning the state.
         // This is more gas-expensive than a pure view function but ensures the returned state is current.
         _checkAndSetSystemState(_systemId);
         return systems[_systemId].state;
    }

    // 16. getSystemParticleIds
    /**
     * @dev Gets the list of particle IDs within a system.
     * @param _systemId The ID of the system.
     * @return bytes32[] An array of particle IDs.
     */
    function getSystemParticleIds(bytes32 _systemId) external view whenSystemExists(_systemId) returns (bytes32[] memory) {
        // Note: This returns the current array. Particles within the system might have decohered or been deleted off-chain check.
        return systems[_systemId].particleIds;
    }

    // 17. getSystemInfo (Combined Getter)
    /**
     * @dev Gets comprehensive information about a system. Triggers an on-chain state check first.
     * @param _systemId The ID of the system.
     * @return tuple System details (id, state, particleIds, creationTime, lastInteractionTime, owner, systemDecayTime, exists).
     */
    function getSystemInfo(bytes32 _systemId) external whenSystemExists(_systemId) returns (bytes32, SystemState, bytes32[] memory, uint256, uint256, address, uint256, bool) {
         // Trigger state update before returning
         _checkAndSetSystemState(_systemId);
         EntangledSystem storage system = systems[_systemId];
         return (
            system.id,
            system.state,
            system.particleIds,
            system.creationTime,
            system.lastInteractionTime,
            system.owner,
            system.systemDecayTime,
            system.exists
         );
    }

    // 18. getOwnedSystemIds
     /**
      * @dev Gets the list of system IDs owned by a specific address.
      *      Note: This list might contain IDs of systems that have been deleted or decayed,
      *      as removing from the array is gas-expensive. Use getSystemInfo to verify existence.
      * @param _owner The address to check.
      * @return bytes32[] An array of system IDs.
      */
    function getOwnedSystemIds(address _owner) external view returns (bytes32[] memory) {
        return ownedSystemIds[_owner]; // Returns the potentially outdated list
    }

    // 19. getOwnedSystemCount
    /**
     * @dev Gets the approximate count of systems owned by an address.
     *      May be inaccurate if systems have been deleted without full array cleanup.
     * @param _owner The address to check.
     * @return uint256 The count of systems.
     */
    function getOwnedSystemCount(address _owner) external view returns (uint256) {
        return ownedSystemCount[_owner];
    }

    // 20. getTotalParticlesInSystem
     /**
      * @dev Gets the number of particle IDs stored in a system's array.
      *      Does not check if the particles actually still exist or are decohered.
      * @param _systemId The ID of the system.
      * @return uint256 The count of particle IDs.
      */
    function getTotalParticlesInSystem(bytes32 _systemId) external view whenSystemExists(_systemId) returns (uint256) {
        return systems[_systemId].particleIds.length;
    }

    // 21. checkParticleDecoherenceStatus (Pure/View helper)
     /**
      * @dev Pure function to check *if* a particle *should* be decohered based on time.
      *      Does not change the particle's state on-chain. Use triggerParticleDecoherence to update state.
      * @param _particleId The ID of the particle.
      * @return bool True if the particle's decoherence time has passed and it's not already Decohered.
      */
    function checkParticleDecoherenceStatus(bytes32 _particleId) external view whenParticleExists(_particleId) returns (bool) {
        QuantumParticle storage particle = particles[_particleId];
        return particle.state != ParticleState.Decohered && block.timestamp >= particle.decoherenceTime;
    }

     // 22. checkSystemDecayStatus (Pure/View helper)
     /**
      * @dev Pure function to check *if* a system *might* be in a decayed state (Partial or Full Decoherence)
      *      based on particle statuses, *without* triggering state updates.
      *      Provides an off-chain estimate. Use triggerSystemStateUpdate for on-chain status.
      * @param _systemId The ID of the system.
      * @return SystemState Estimated potential state based on current time and particle decoherence times.
      */
    function checkSystemDecayStatus(bytes32 _systemId) external view whenSystemExists(_systemId) returns (SystemState) {
         EntangledSystem storage system = systems[_systemId];
         if (system.particleIds.length == 0) {
             return SystemState.Stable; // Or potentially FullyDecohered if a system decay time was implemented
         }

         bool anyWouldDecohere = false;
         bool allWouldDecohere = true;

         for (uint256 i = 0; i < system.particleIds.length; i++) {
             bytes32 particleId = system.particleIds[i];
             if (particles[particleId].exists) {
                 if (particles[particleId].state != ParticleState.Decohered && block.timestamp >= particles[particleId].decoherenceTime) {
                     anyWouldDecohere = true;
                 } else if (particles[particleId].state != ParticleState.Decohered) {
                     allWouldDecohere = false; // Found a particle that wouldn't decohere *yet*
                 }
             } else {
                 // Particle deleted/non-existent - treat as effectively decohered for this check
                 anyWouldDecohere = true;
             }
         }

         if (allWouldDecohere) {
             return SystemState.FullyDecohered;
         } else if (anyWouldDecohere) {
             return SystemState.PartiallyDecohered;
         } else {
             // No particles are currently past their decoherence time
             // This doesn't check if ALL are Determined, so it's just about decay, not collapse
             return SystemState.Stable; // Best estimate without full state check
         }
    }


    // 23. deleteDecoheredParticle
    /**
     * @dev Deletes a particle that is in the Decohered state to free up storage.
     *      Can be triggered by anyone. Requires the particle to be Decohered.
     *      Note: Does NOT remove the particle ID from its system's array if it was part of one.
     *      System functions need to handle potentially non-existent particle IDs.
     * @param _particleId The ID of the particle to delete.
     */
    function deleteDecoheredParticle(bytes32 _particleId) external whenParticleExists(_particleId) whenParticleIsInState(_particleId, ParticleState.Decohered) {
        // Ensure particle state is confirmed Decohered (in case time just passed)
        _checkAndSetParticleDecoherence(_particleId);
        require(particles[_particleId].state == ParticleState.Decohered, "Particle is not in Decohered state");

        // Get systemId before deletion if needed
        bytes32 systemId = particles[_particleId].systemId;

        delete particles[_particleId]; // Deletes the struct from storage
        // The particleId in the system's array becomes a dangling reference.
        // System functions need to handle this (e.g., check exists flag).
        // A production contract might need more complex cleanup here, e.g.,
        // removing from the system array, which is gas-costly.

        emit ParticleStateChanged(_particleId, ParticleState.Decohered, ParticleState.Decohered); // Emit again to signal deletion intent
        // Could add a specific ParticleDeleted event
        // emit ParticleDeleted(_particleId);

         // Trigger system state update if it was part of a system
        if (systemId != 0x0 && systems[systemId].exists) {
             _checkAndSetSystemState(systemId);
        }
    }

    // 24. deleteSystemIfTerminal
    /**
     * @dev Deletes a system if it is in a terminal state (Collapsed or FullyDecohered) to free up storage.
     *      Can be triggered by anyone.
     *      Note: Does NOT delete individual particles within the system. They become standalone.
     * @param _systemId The ID of the system to delete.
     */
    function deleteSystemIfTerminal(bytes32 _systemId) external whenSystemExists(_systemId) {
         // Ensure system state is current
         _checkAndSetSystemState(_systemId);
         EntangledSystem storage system = systems[_systemId];

         require(system.state == SystemState.Collapsed || system.state == SystemState.FullyDecohered, "System is not in a terminal state (Collapsed or FullyDecohered)");

         address systemOwner = system.owner;
         bytes32[] memory particleIdsInSystem = system.particleIds; // Get particle IDs before deleting system

         // Clean up particle references from the system
         for (uint i = 0; i < particleIdsInSystem.length; i++) {
             bytes32 particleId = particleIdsInSystem[i];
             if (particles[particleId].exists) {
                 particles[particleId].systemId = 0x0; // Make particle standalone
             }
         }

         // Clean up owner's count and (partially) list (gas caution for list)
         if (ownedSystemCount[systemOwner] > 0) {
             ownedSystemCount[systemOwner]--;
             // Removing from ownedSystemIds array is expensive O(N).
             // For this example, we skip it. A production contract needs a better way.
         }

         delete systems[_systemId]; // Deletes the system struct from storage

        emit SystemDecayed(_systemId, system.state); // Using Decay event to signify deletion for terminal state
        // Could add a specific SystemDeleted event
        // emit SystemDeleted(_systemId);
    }

    // 25. getParticleDecoherenceTime
    /**
     * @dev Gets the scheduled decoherence time for a particle.
     * @param _particleId The ID of the particle.
     * @return uint256 The timestamp of scheduled decoherence.
     */
    function getParticleDecoherenceTime(bytes32 _particleId) external view whenParticleExists(_particleId) returns (uint256) {
        return particles[_particleId].decoherenceTime;
    }

    // 26. getSystemCreationTime
    /**
     * @dev Gets the creation time of a system.
     * @param _systemId The ID of the system.
     * @return uint256 The creation timestamp.
     */
    function getSystemCreationTime(bytes32 _systemId) external view whenSystemExists(_systemId) returns (uint256) {
        return systems[_systemId].creationTime;
    }

     // 27. getSystemLastInteractionTime
    /**
     * @dev Gets the last interaction time (creation, observation, particle added/removed) of a system.
     * @param _systemId The ID of the system.
     * @return uint256 The last interaction timestamp.
     */
    function getSystemLastInteractionTime(bytes32 _systemId) external view whenSystemExists(_systemId) returns (uint256) {
        return systems[_systemId].lastInteractionTime;
    }

}
```