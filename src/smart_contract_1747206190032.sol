Okay, here is a Solidity smart contract based on a conceptual "Quantum Entanglement Ledger". It models abstract "particles" with states like superposition and entanglement, which collapse upon "observation" in a quantum-inspired manner. This concept is creative and goes beyond typical token or simple data contracts.

It aims for novelty by focusing on state relationships and observation-triggered events inspired by quantum mechanics, rather than standard blockchain use cases like DeFi, NFTs, or simple data storage.

---

**Outline & Function Summary**

**Contract:** `QuantumEntanglementLedger`

**Concept:** A ledger for tracking abstract "Quantum Particles" that can exist in different states, including superposition and entanglement. Interactions like "observation" cause state collapse according to predefined quantum-inspired rules. It's a conceptual model exploring complex on-chain state management and interaction based on physical analogies.

**Key Structures & States:**

*   `ParticleState`: Enum representing possible states (Created, Superposed, SpinUp, SpinDown, Collapsed, Entangled).
*   `EntanglementType`: Enum defining how entangled particles resolve (SpinOpposite, SpinSame, RandomPair).
*   `QuantumParticle`: Struct holding particle ID, state, creation time, owner, and a flag if it's part of a collapsed entanglement.
*   `EntanglementPair`: Struct linking two particle IDs, defining the type of entanglement, tracking if collapsed, and storing resolved states.

**Function Summary:**

1.  **Creation & Management (Basic):**
    *   `constructor()`: Initializes the contract owner.
    *   `createParticle(address initialOwner, bool startInSuperposition)`: Creates a new particle with an initial state.
    *   `batchCreateParticles(uint256 count, address initialOwner, bool startInSuperposition)`: Creates multiple particles in a single transaction.
    *   `getTotalParticles()`: Returns the total number of particles created.
    *   `transferParticleOwnership(uint256 particleId, address newOwner)`: Transfers ownership of a particle.
    *   `renounceOwnership()`: Standard Ownable function.

2.  **Particle State Interaction:**
    *   `enterSuperposition(uint256 particleId)`: Transitions a particle to the Superposed state (if valid).
    *   `simulateQuantumFluctuation(uint256 particleId)`: Randomly changes the state of a non-collapsed particle based on on-chain factors (simulated instability).
    *   `predictPotentialStates(uint256 particleId)`: View function suggesting possible states after observation/collapse for Superposed or Entangled particles.
    *   `getParticleDetails(uint256 particleId)`: View function returning struct details of a particle.
    *   `getParticleState(uint256 particleId)`: View function returning the current state enum.
    *   `getParticleOwner(uint256 particleId)`: View function returning the owner address.
    *   `getParticleCreationTime(uint256 particleId)`: View function returning the creation timestamp.
    *   `isParticleCollapsed(uint256 particleId)`: View function checking if the particle has collapsed.

3.  **Entanglement Management:**
    *   `createEntangledPair(uint256 particleId1, uint256 particleId2, EntanglementType entType)`: Creates a quantum entanglement between two particles. Requires both to be in Superposition.
    *   `dissolveEntanglement(uint256 particleId1, uint256 particleId2)`: Breaks an entanglement (only if not collapsed).
    *   `getParticleEntanglements(uint256 particleId)`: View function returning a list of IDs of particles entangled with the given one.
    *   `getEntanglementDetails(uint256 particleId1, uint256 particleId2)`: View function returning details of a specific entanglement pair.
    *   `checkEntanglementStatus(uint256 particleId1, uint256 particleId2)`: View function returning boolean indicating if they are entangled and the pair's status.

4.  **Observation & Collapse:**
    *   `observeParticle(uint256 particleId)`: The core function. Forces a particle out of superposition/entanglement, determining its final state. If entangled, also collapses the paired particle according to the entanglement type. Uses on-chain data for simulated non-determinism.
    *   `getResolvedState(uint256 particleId)`: View function returning the final state if the particle is collapsed.
    *   `getPairResolvedStates(uint256 particleId1, uint256 particleId2)`: View function returning the final states for both particles in a collapsed pair.
    *   `setEntanglementResolutionSeed(uint256 particleId1, uint256 particleId2, bytes32 seed)`: Allows setting a custom seed *before* collapse for deterministic testing or privileged control (admin/owner).

5.  **Advanced/Creative:**
    *   `calculateEntanglementEntropy(uint256 particleId)`: Conceptual view function returning a value proportional to the number of *uncollapsed* entanglements the particle is in (simulating higher "entropy" before measurement).
    *   `createParticleFromObservation(uint256 observedParticleId, address newOwner)`: Creates a *new* particle whose *initial* state (SpinUp/SpinDown) is determined by the *resolved* state of an already observed particle.
    *   `adminForceCollapse(uint256 particleId, ParticleState targetState)`: Admin function to bypass observation logic and force a particle into a specific collapsed state.
    *   `adminDissolveAllForParticle(uint256 particleId)`: Admin function to dissolve all entanglements involving a particle, regardless of state.
    *   `getVersion()`: Returns the contract version string.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline & Function Summary
// Contract: QuantumEntanglementLedger
// Concept: A ledger for tracking abstract "Quantum Particles" that can exist in different states,
//          including superposition and entanglement. Interactions like "observation" cause state collapse
//          according to predefined quantum-inspired rules. It's a conceptual model exploring complex
//          on-chain state management and interaction based on physical analogies.
//
// Key Structures & States:
// - ParticleState: Enum representing possible states (Created, Superposed, SpinUp, SpinDown, Collapsed, Entangled).
// - EntanglementType: Enum defining how entangled particles resolve (SpinOpposite, SpinSame, RandomPair).
// - QuantumParticle: Struct holding particle ID, state, creation time, owner, and a flag if part of a collapsed entanglement.
// - EntanglementPair: Struct linking two particle IDs, defining the type of entanglement, tracking if collapsed, and storing resolved states.
//
// Function Summary:
// 1. Creation & Management (Basic):
//    - constructor(): Initializes the contract owner.
//    - createParticle(address initialOwner, bool startInSuperposition): Creates a new particle with an initial state.
//    - batchCreateParticles(uint256 count, address initialOwner, bool startInSuperposition): Creates multiple particles.
//    - getTotalParticles(): Total particles created.
//    - transferParticleOwnership(uint256 particleId, address newOwner): Transfers ownership.
//    - renounceOwnership(): Standard Ownable.
// 2. Particle State Interaction:
//    - enterSuperposition(uint256 particleId): Transitions a particle to Superposed.
//    - simulateQuantumFluctuation(uint256 particleId): Randomly changes non-collapsed state (simulated).
//    - predictPotentialStates(uint256 particleId): View suggesting possible states after collapse.
//    - getParticleDetails(uint256 particleId): View struct details.
//    - getParticleState(uint256 particleId): View state enum.
//    - getParticleOwner(uint256 particleId): View owner address.
//    - getParticleCreationTime(uint256 particleId): View creation timestamp.
//    - isParticleCollapsed(uint256 particleId): View check if collapsed.
// 3. Entanglement Management:
//    - createEntangledPair(uint256 particleId1, uint256 particleId2, EntanglementType entType): Creates entanglement.
//    - dissolveEntanglement(uint256 particleId1, uint256 particleId2): Breaks entanglement (if not collapsed).
//    - getParticleEntanglements(uint256 particleId): View list of paired IDs.
//    - getEntanglementDetails(uint256 particleId1, uint256 particleId2): View pair details.
//    - checkEntanglementStatus(uint256 particleId1, uint256 particleId2): View entanglement status.
// 4. Observation & Collapse:
//    - observeParticle(uint256 particleId): Triggers collapse of particle and its entangled pair(s).
//    - getResolvedState(uint256 particleId): View final state if collapsed.
//    - getPairResolvedStates(uint256 particleId1, uint256 particleId2): View final states for a collapsed pair.
//    - setEntanglementResolutionSeed(uint256 particleId1, uint256 particleId2, bytes32 seed): Set custom seed for resolution (admin/owner).
// 5. Advanced/Creative:
//    - calculateEntanglementEntropy(uint256 particleId): Conceptual view of entropy (uncollapsed entanglements).
//    - createParticleFromObservation(uint256 observedParticleId, address newOwner): Creates new particle based on observed state.
//    - adminForceCollapse(uint256 particleId, ParticleState targetState): Admin override to force state.
//    - adminDissolveAllForParticle(uint256 particleId): Admin utility to dissolve all entanglements for a particle.
//    - getVersion(): Contract version.

contract QuantumEntanglementLedger is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums ---

    // Possible states of a Quantum Particle
    enum ParticleState {
        Uninitialized, // Should not be a persistent state
        Created,       // Just created, no specific state yet
        Superposed,    // In a state of superposition (undetermined Spin)
        SpinUp,        // Collapsed/Observed state
        SpinDown,      // Collapsed/Observed state
        Collapsed,     // A general collapsed state (e.g., if not Spin specific or error)
        Entangled      // Part of an entangled pair, state is linked to another
    }

    // Types of entanglement relationships
    enum EntanglementType {
        Uninitialized, // Should not be a persistent state
        SpinOpposite,  // When collapsed, spins are opposite (Up/Down or Down/Up)
        SpinSame,      // When collapsed, spins are the same (Up/Up or Down/Down)
        RandomPair     // Each particle's resolved state is random upon collapse, independent of the other
    }

    // --- Structs ---

    struct QuantumParticle {
        uint256 id;
        ParticleState state;
        uint64 creationTimestamp; // Use uint64 for timestamp
        address owner;
        bool isEntanglementMemberCollapsed; // Flag to track if its entangled pair(s) have collapsed
        ParticleState resolvedState; // Stores the final state after collapse/observation
    }

    struct EntanglementPair {
        uint256 particleId1;
        uint256 particleId2;
        EntanglementType entType;
        bool isCollapsed;
        ParticleState resolvedState1; // Resolved state for particleId1
        ParticleState resolvedState2; // Resolved state for particleId2
        bytes32 resolutionSeed; // Optional seed for deterministic resolution
    }

    // --- State Variables ---

    Counters.Counter private _particleIds;
    mapping(uint256 => QuantumParticle) public particles;

    // Mapping from particle ID to a list of hashes representing the entanglement pairs it's involved in
    mapping(uint256 => bytes32[]) private _particleEntanglements;

    // Mapping from unique pair hash to the EntanglementPair details
    // Hash is calculated as keccak256(abi.encodePacked(min(id1, id2), max(id1, id2)))
    mapping(bytes32 => EntanglementPair) private _entanglementPairs;

    string public constant version = "1.0.0";

    // --- Events ---

    event ParticleCreated(uint256 indexed particleId, address indexed owner, ParticleState initialState, uint64 timestamp);
    event ParticleStateChanged(uint256 indexed particleId, ParticleState oldState, ParticleState newState);
    event ParticleOwnerChanged(uint256 indexed particleId, address indexed oldOwner, address indexed newOwner);
    event EntanglementCreated(uint256 indexed particleId1, uint256 indexed particleId2, EntanglementType entType, bytes32 indexed pairHash);
    event EntanglementDissolved(uint256 indexed particleId1, uint256 indexed particleId2, bytes32 indexed pairHash);
    event ParticleObserved(uint256 indexed particleId, ParticleState resolvedState);
    event EntanglementCollapsed(uint256 indexed particleId1, uint256 indexed particleId2, ParticleState resolvedState1, ParticleState resolvedState2, bytes32 indexed pairHash);
    event FluctuationOccurred(uint256 indexed particleId, ParticleState newState);
    event ParticleCreatedFromObservation(uint256 indexed newParticleId, uint256 indexed observedParticleId, ParticleState initialState);
    event ResolutionSeedSet(uint256 indexed particleId1, uint256 indexed particleId2, bytes32 seed, bytes32 indexed pairHash);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Helper Functions ---

    function _particleExists(uint256 particleId) internal view returns (bool) {
        return particles[particleId].id != 0; // ID 0 means not created
    }

    function _getEntanglementPairKey(uint256 particleId1, uint256 particleId2) internal pure returns (bytes32) {
        // Ensure consistent key regardless of order
        if (particleId1 < particleId2) {
            return keccak256(abi.encodePacked(particleId1, particleId2));
        } else {
            return keccak256(abi.encodePacked(particleId2, particleId1));
        }
    }

    // Simulates a quantum collapse outcome (either SpinUp or SpinDown)
    // Note: On-chain randomness is not truly random and should not be used
    // for high-security or adversarial scenarios. This is for conceptual simulation.
    function _generateResolutionOutcome(uint256 particleId, bytes32 customSeed) internal view returns (ParticleState) {
        bytes32 seed = customSeed != bytes32(0) ? customSeed : keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty, // block.difficulty is 0 after The Merge, use block.prevrandao instead in post-merge Ethereum
                block.chainid,
                msg.sender, // Incorporate sender for variability
                particleId,
                particles[particleId].creationTimestamp // Use a particle-specific factor
            )
        );
        // Deterministically pick based on the seed
        if (uint256(seed) % 2 == 0) {
            return ParticleState.SpinUp;
        } else {
            return ParticleState.SpinDown;
        }
    }

    // Internal function to get a pair struct securely
    function _getEntanglementPair(uint256 particleId1, uint256 particleId2) internal view returns (EntanglementPair storage pair) {
        bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
        pair = _entanglementPairs[pairKey];
        require(pair.entType != EntanglementType.Uninitialized, "Pair does not exist");
    }

    // Internal function to resolve an entangled pair's states
    function _resolveEntanglement(uint256 particleId1, uint256 particleId2) internal {
        bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
        EntanglementPair storage pair = _entanglementPairs[pairKey];

        require(pair.entType != EntanglementType.Uninitialized, "Pair does not exist");
        require(!pair.isCollapsed, "Entanglement already collapsed");

        QuantumParticle storage p1 = particles[particleId1];
        QuantumParticle storage p2 = particles[particleId2];

        require(p1.state == ParticleState.Entangled, "Particle 1 not in Entangled state");
        require(p2.state == ParticleState.Entangled, "Particle 2 not in Entangled state");

        // Use the seed stored in the pair, or generate one if not set
        bytes32 pairSeed = pair.resolutionSeed != bytes32(0) ? pair.resolutionSeed : keccak256(
             abi.encodePacked(
                block.timestamp,
                block.difficulty, // block.difficulty is 0 after The Merge, use block.prevrandao instead
                block.chainid,
                pairKey // Use pair key for uniqueness
             )
        );


        ParticleState resolved1;
        ParticleState resolved2;

        if (pair.entType == EntanglementType.SpinOpposite) {
             // Resolve one particle based on the seed
            resolved1 = uint256(pairSeed) % 2 == 0 ? ParticleState.SpinUp : ParticleState.SpinDown;
            // The other is opposite
            resolved2 = (resolved1 == ParticleState.SpinUp) ? ParticleState.SpinDown : ParticleState.SpinUp;
        } else if (pair.entType == EntanglementType.SpinSame) {
            // Resolve one particle based on the seed
            resolved1 = uint256(pairSeed) % 2 == 0 ? ParticleState.SpinUp : ParticleState.SpinDown;
            // The other is the same
            resolved2 = resolved1;
        } else if (pair.entType == EntanglementType.RandomPair) {
            // Resolve each particle independently based on variations of the seed
             resolved1 = uint256(keccak256(abi.encodePacked(pairSeed, 1))) % 2 == 0 ? ParticleState.SpinUp : ParticleState.SpinDown;
             resolved2 = uint256(keccak256(abi.encodePacked(pairSeed, 2))) % 2 == 0 ? ParticleState.SpinUp : ParticleState.SpinDown;
        } else {
            revert("Invalid entanglement type"); // Should not happen if logic is correct
        }

        // Update pair state
        pair.isCollapsed = true;
        pair.resolvedState1 = resolved1;
        pair.resolvedState2 = resolved2;

        // Update particle states
        p1.state = resolved1;
        p1.resolvedState = resolved1;
        p1.isEntanglementMemberCollapsed = true;

        p2.state = resolved2;
        p2.resolvedState = resolved2;
        p2.isEntanglementMemberCollapsed = true;

        emit ParticleStateChanged(particleId1, ParticleState.Entangled, resolved1);
        emit ParticleObserved(particleId1, resolved1);
        emit ParticleStateChanged(particleId2, ParticleState.Entangled, resolved2);
        emit ParticleObserved(particleId2, resolved2);
        emit EntanglementCollapsed(particleId1, particleId2, resolved1, resolved2, pairKey);
    }

    // Internal function to resolve a single Superposed particle
    function _resolveSuperposition(uint256 particleId) internal {
        QuantumParticle storage p = particles[particleId];
        require(p.state == ParticleState.Superposed, "Particle not in Superposed state");
        require(!p.isEntanglementMemberCollapsed, "Particle is part of a collapsed pair, cannot resolve singly");

        ParticleState resolved = _generateResolutionOutcome(particleId, bytes32(0)); // No custom seed for single particles

        p.state = resolved;
        p.resolvedState = resolved;
        p.isEntanglementMemberCollapsed = true; // Mark as collapsed

        emit ParticleStateChanged(particleId, ParticleState.Superposed, resolved);
        emit ParticleObserved(particleId, resolved);
    }

    // Internal helper to add pair hash to particle's entanglement list
    function _addPairHashToParticle(uint256 particleId, bytes32 pairHash) internal {
         bool found = false;
         for(uint i = 0; i < _particleEntanglements[particleId].length; i++) {
             if (_particleEntanglements[particleId][i] == pairHash) {
                 found = true;
                 break;
             }
         }
         if (!found) {
            _particleEntanglements[particleId].push(pairHash);
         }
    }

    // Internal helper to remove pair hash from particle's entanglement list
    function _removePairHashFromParticle(uint256 particleId, bytes32 pairHash) internal {
        bytes32[] storage entanglements = _particleEntanglements[particleId];
        for (uint i = 0; i < entanglements.length; i++) {
            if (entanglements[i] == pairHash) {
                // Swap with last element and pop
                entanglements[i] = entanglements[entanglements.length - 1];
                entanglements.pop();
                break;
            }
        }
    }


    // --- Core Functions ---

    /**
     * @dev Creates a new Quantum Particle.
     * @param initialOwner The address to assign ownership to.
     * @param startInSuperposition Whether the particle starts in Superposed state or Created state.
     * @return The ID of the newly created particle.
     */
    function createParticle(address initialOwner, bool startInSuperposition) public onlyOwner returns (uint256) {
        _particleIds.increment();
        uint256 newParticleId = _particleIds.current();
        ParticleState initialState = startInSuperposition ? ParticleState.Superposed : ParticleState.Created;

        particles[newParticleId] = QuantumParticle({
            id: newParticleId,
            state: initialState,
            creationTimestamp: uint64(block.timestamp),
            owner: initialOwner,
            isEntanglementMemberCollapsed: false,
            resolvedState: ParticleState.Uninitialized // No resolved state yet
        });

        emit ParticleCreated(newParticleId, initialOwner, initialState, uint64(block.timestamp));
        return newParticleId;
    }

    /**
     * @dev Creates multiple Quantum Particles in a batch.
     * @param count The number of particles to create.
     * @param initialOwner The address to assign ownership to.
     * @param startInSuperposition Whether the particles start in Superposed state or Created state.
     * @return An array of IDs of the newly created particles.
     */
    function batchCreateParticles(uint256 count, address initialOwner, bool startInSuperposition) public onlyOwner returns (uint256[] memory) {
        require(count > 0, "Count must be positive");
        uint256[] memory newParticleIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            newParticleIds[i] = createParticle(initialOwner, startInSuperposition);
        }
        return newParticleIds;
    }

    /**
     * @dev Returns the total number of particles ever created.
     */
    function getTotalParticles() public view returns (uint256) {
        return _particleIds.current();
    }

     /**
     * @dev Transfers ownership of a specific particle.
     * @param particleId The ID of the particle to transfer.
     * @param newOwner The address to transfer ownership to.
     */
    function transferParticleOwnership(uint256 particleId, address newOwner) public {
        require(_particleExists(particleId), "Particle does not exist");
        require(particles[particleId].owner == msg.sender, "Not particle owner");
        require(newOwner != address(0), "New owner is the zero address");

        address oldOwner = particles[particleId].owner;
        particles[particleId].owner = newOwner;
        emit ParticleOwnerChanged(particleId, oldOwner, newOwner);
    }

    /**
     * @dev Transitions a particle to the Superposed state.
     * Requires the particle to be in Created state.
     * @param particleId The ID of the particle.
     */
    function enterSuperposition(uint256 particleId) public {
        require(_particleExists(particleId), "Particle does not exist");
        QuantumParticle storage p = particles[particleId];
        require(p.owner == msg.sender, "Not particle owner");
        require(p.state == ParticleState.Created, "Particle must be in Created state to enter Superposition");
        require(!p.isEntanglementMemberCollapsed, "Particle already collapsed"); // Cannot enter superposition if already collapsed

        ParticleState oldState = p.state;
        p.state = ParticleState.Superposed;
        emit ParticleStateChanged(particleId, oldState, p.state);
    }

    /**
     * @dev Simulates a random quantum fluctuation that might change a non-collapsed particle's state.
     * The state change is simulated based on on-chain data. Only works for Created or Superposed states.
     * @param particleId The ID of the particle.
     */
    function simulateQuantumFluctuation(uint256 particleId) public {
         require(_particleExists(particleId), "Particle does not exist");
         QuantumParticle storage p = particles[particleId];
         require(p.owner == msg.sender, "Not particle owner");
         require(p.state == ParticleState.Created || p.state == ParticleState.Superposed, "Particle not in fluctuatable state");
         require(!p.isEntanglementMemberCollapsed, "Particle already collapsed"); // Cannot fluctuate if already collapsed

         // Simple simulation: use block data to decide if fluctuation happens and to what state
         bytes32 fluctuationSeed = keccak256(
             abi.encodePacked(
                 block.timestamp,
                 block.difficulty, // Use block.prevrandao post-merge
                 block.chainid,
                 particleId,
                 msg.sender
             )
         );

         ParticleState oldState = p.state;

         // A 50% chance to fluctuate for this simulation
         if (uint256(fluctuationSeed) % 2 == 0) {
             // If fluctuating, pick a new state (Created or Superposed)
             ParticleState newState = (uint256(keccak256(abi.encodePacked(fluctuationSeed, "state")))) % 2 == 0 ? ParticleState.Created : ParticleState.Superposed;
             if (p.state != newState) {
                  p.state = newState;
                  emit ParticleStateChanged(particleId, oldState, newState);
                  emit FluctuationOccurred(particleId, newState);
             }
         }
         // Else, no change happens this time.
    }

    /**
     * @dev Creates a quantum entanglement between two particles.
     * Requires both particles to be in Superposed state.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     * @param entType The type of entanglement (SpinOpposite, SpinSame, or RandomPair).
     */
    function createEntangledPair(uint256 particleId1, uint256 particleId2, EntanglementType entType) public {
        require(particleId1 != particleId2, "Cannot entangle a particle with itself");
        require(_particleExists(particleId1), "Particle 1 does not exist");
        require(_particleExists(particleId2), "Particle 2 does not exist");

        QuantumParticle storage p1 = particles[particleId1];
        QuantumParticle storage p2 = particles[particleId2];

        require(p1.owner == msg.sender || p2.owner == msg.sender || owner() == msg.sender, "Neither particle owner nor contract owner"); // Owner or admin can create entanglement
        require(p1.state == ParticleState.Superposed, "Particle 1 must be in Superposed state");
        require(p2.state == ParticleState.Superposed, "Particle 2 must be in Superposed state");
        require(!p1.isEntanglementMemberCollapsed && !p2.isEntanglementMemberCollapsed, "One or both particles already collapsed");

        bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
        require(_entanglementPairs[pairKey].entType == EntanglementType.Uninitialized, "Particles are already entangled");
        require(entType != EntanglementType.Uninitialized, "Invalid entanglement type");

        _entanglementPairs[pairKey] = EntanglementPair({
            particleId1: particleId1,
            particleId2: particleId2,
            entType: entType,
            isCollapsed: false,
            resolvedState1: ParticleState.Uninitialized,
            resolvedState2: ParticleState.Uninitialized,
            resolutionSeed: bytes32(0) // Initially no custom seed
        });

        // Transition particles to Entangled state
        ParticleState oldState1 = p1.state;
        ParticleState oldState2 = p2.state;
        p1.state = ParticleState.Entangled;
        p2.state = ParticleState.Entangled;

        // Track this pair on both particles
        _addPairHashToParticle(particleId1, pairKey);
        _addPairHashToParticle(particleId2, pairKey);

        emit ParticleStateChanged(particleId1, oldState1, p1.state);
        emit ParticleStateChanged(particleId2, oldState2, p2.state);
        emit EntanglementCreated(particleId1, particleId2, entType, pairKey);
    }


    /**
     * @dev Dissolves an entanglement between two particles.
     * Requires the entanglement to exist and not be collapsed.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     */
    function dissolveEntanglement(uint256 particleId1, uint256 particleId2) public {
        require(particleId1 != particleId2, "Invalid pair");
        bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
        EntanglementPair storage pair = _entanglementPairs[pairKey];

        require(pair.entType != EntanglementType.Uninitialized, "Pair does not exist");
        require(!pair.isCollapsed, "Entanglement already collapsed");

        QuantumParticle storage p1 = particles[particleId1];
        QuantumParticle storage p2 = particles[particleId2];

        require(p1.owner == msg.sender || p2.owner == msg.sender || owner() == msg.sender, "Neither particle owner nor contract owner");

        // Reset pair state
        delete _entanglementPairs[pairKey];

        // Transition particles back to Superposed (or another default state like Created)
        ParticleState oldState1 = p1.state;
        ParticleState oldState2 = p2.state;
        p1.state = ParticleState.Superposed; // Revert to Superposed state
        p2.state = ParticleState.Superposed; // Revert to Superposed state

        // Remove pair hash from particle tracking
        _removePairHashFromParticle(particleId1, pairKey);
        _removePairHashFromParticle(particleId2, pairKey);

        emit ParticleStateChanged(particleId1, oldState1, p1.state);
        emit ParticleStateChanged(particleId2, oldState2, p2.state);
        emit EntanglementDissolved(particleId1, particleId2, pairKey);
    }

     /**
     * @dev Gets the IDs of particles entangled with a given particle.
     * Note: This iterates through a particle's stored pair hashes.
     * @param particleId The ID of the particle.
     * @return An array of IDs of entangled particles.
     */
    function getParticleEntanglements(uint256 particleId) public view returns (uint256[] memory) {
        require(_particleExists(particleId), "Particle does not exist");
        bytes32[] storage pairHashes = _particleEntanglements[particleId];
        uint256[] memory entangledIds = new uint256[](pairHashes.length);

        for (uint i = 0; i < pairHashes.length; i++) {
            EntanglementPair storage pair = _entanglementPairs[pairHashes[i]];
            // Determine which particle in the pair is *not* the requested one
            if (pair.particleId1 == particleId) {
                entangledIds[i] = pair.particleId2;
            } else if (pair.particleId2 == particleId) {
                entangledIds[i] = pair.particleId1;
            }
            // If neither matches, something is wrong with the mapping, but we'll return 0.
        }
        return entangledIds;
    }

     /**
     * @dev Gets the details of a specific entanglement pair.
     * @param particleId1 The ID of the first particle in the pair.
     * @param particleId2 The ID of the second particle in the pair.
     * @return The EntanglementPair struct details.
     */
    function getEntanglementDetails(uint256 particleId1, uint256 particleId2) public view returns (EntanglementPair memory) {
        require(particleId1 != particleId2, "Invalid pair");
        bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
        EntanglementPair storage pair = _entanglementPairs[pairKey];
        require(pair.entType != EntanglementType.Uninitialized, "Pair does not exist");
        return pair;
    }

    /**
     * @dev Checks the entanglement status between two particles.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     * @return bool True if entangled, false otherwise.
     * @return EntanglementType The type of entanglement (Uninitialized if not entangled).
     * @return bool True if the entanglement is collapsed, false otherwise.
     */
    function checkEntanglementStatus(uint256 particleId1, uint256 particleId2) public view returns (bool, EntanglementType, bool) {
         if (particleId1 == particleId2) {
             return (false, EntanglementType.Uninitialized, false);
         }
         bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
         EntanglementPair storage pair = _entanglementPairs[pairKey];
         bool exists = pair.entType != EntanglementType.Uninitialized;
         return (exists, pair.entType, pair.isCollapsed);
    }


    /**
     * @dev Observes a particle, causing it (and potentially its entangled pair) to collapse into a definite state.
     * This is the core quantum-inspired interaction function.
     * Uses on-chain data for simulated non-determinism.
     * @param particleId The ID of the particle to observe.
     */
    function observeParticle(uint256 particleId) public {
        require(_particleExists(particleId), "Particle does not exist");
        QuantumParticle storage p = particles[particleId];
        require(p.owner == msg.sender, "Not particle owner");
        require(p.state != ParticleState.SpinUp && p.state != ParticleState.SpinDown && p.state != ParticleState.Collapsed, "Particle already in a collapsed state");
        require(!p.isEntanglementMemberCollapsed, "Particle is already part of a collapsed entanglement");


        if (p.state == ParticleState.Superposed) {
            // Resolve a single superposition
             _resolveSuperposition(particleId);

        } else if (p.state == ParticleState.Entangled) {
            // Find all entangled pairs involving this particle and collapse them
            bytes32[] memory pairHashes = _particleEntanglements[particleId];
            // Note: A particle could potentially be entangled in *multiple* pairs simultaneously
            // in some theoretical models. This implementation collapses ALL uncollapsed pairs
            // it's currently part of upon its observation.

            for (uint i = 0; i < pairHashes.length; i++) {
                 bytes32 pairKey = pairHashes[i];
                 EntanglementPair storage pair = _entanglementPairs[pairKey];

                 if (!pair.isCollapsed) {
                     // Determine the other particle ID in the pair
                     uint256 otherParticleId = (pair.particleId1 == particleId) ? pair.particleId2 : pair.particleId1;
                     _resolveEntanglement(particleId, otherParticleId);
                 }
            }
             require(p.isEntanglementMemberCollapsed, "Entangled particle did not collapse - something is wrong");

        } else {
            // Particle is in Created state or other non-collapsible state
            revert("Particle is not in a state that can be observed (Superposed or Entangled)");
        }
    }

     /**
     * @dev Checks if a particle has collapsed (either singly or as part of an entanglement).
     * @param particleId The ID of the particle.
     * @return bool True if collapsed, false otherwise.
     */
    function isParticleCollapsed(uint256 particleId) public view returns (bool) {
         require(_particleExists(particleId), "Particle does not exist");
         QuantumParticle storage p = particles[particleId];
         return p.isEntanglementMemberCollapsed || (p.state == ParticleState.SpinUp || p.state == ParticleState.SpinDown || p.state == ParticleState.Collapsed);
    }

    /**
     * @dev Gets the final resolved state of a particle after it has collapsed.
     * @param particleId The ID of the particle.
     * @return The resolved ParticleState (SpinUp, SpinDown, or Collapsed), or Uninitialized if not yet collapsed.
     */
    function getResolvedState(uint256 particleId) public view returns (ParticleState) {
        require(_particleExists(particleId), "Particle does not exist");
        QuantumParticle storage p = particles[particleId];
        require(isParticleCollapsed(particleId), "Particle has not yet collapsed");
        // Return the stored resolved state which is set during collapse
        return p.resolvedState;
    }

    /**
     * @dev Gets the final resolved states for both particles in a specific entanglement pair, if collapsed.
     * @param particleId1 The ID of the first particle in the pair.
     * @param particleId2 The ID of the second particle in the pair.
     * @return The resolved state for particleId1 and particleId2. Returns Uninitialized if the pair is not collapsed.
     */
    function getPairResolvedStates(uint256 particleId1, uint256 particleId2) public view returns (ParticleState, ParticleState) {
         require(particleId1 != particleId2, "Invalid pair");
         bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
         EntanglementPair storage pair = _entanglementPairs[pairKey];

         require(pair.entType != EntanglementType.Uninitialized, "Pair does not exist");
         require(pair.isCollapsed, "Entanglement pair has not yet collapsed");

         // Ensure the IDs match the pair structure (could be in either order)
         if (pair.particleId1 == particleId1) {
             return (pair.resolvedState1, pair.resolvedState2);
         } else {
             return (pair.resolvedState2, pair.resolvedState1);
         }
    }

     /**
     * @dev Allows the owner/admin to set a custom seed for the resolution of a specific entanglement pair.
     * This seed will be used instead of the automatically generated block-based seed during collapse.
     * Can only be set if the pair exists and has not yet collapsed.
     * Useful for deterministic testing or privileged control over outcomes.
     * @param particleId1 The ID of the first particle in the pair.
     * @param particleId2 The ID of the second particle in the pair.
     * @param seed The 32-byte seed to use for resolution. Set to bytes32(0) to revert to automatic seeding.
     */
    function setEntanglementResolutionSeed(uint256 particleId1, uint256 particleId2, bytes32 seed) public onlyOwner {
         require(particleId1 != particleId2, "Invalid pair");
         bytes32 pairKey = _getEntanglementPairKey(particleId1, particleId2);
         EntanglementPair storage pair = _entanglementPairs[pairKey];

         require(pair.entType != EntanglementType.Uninitialized, "Pair does not exist");
         require(!pair.isCollapsed, "Entanglement already collapsed");

         pair.resolutionSeed = seed;
         emit ResolutionSeedSet(particleId1, particleId2, seed, pairKey);
    }


    /**
     * @dev Conceptual function to predict the potential states a particle could collapse into upon observation.
     * For Superposed particles, it's SpinUp or SpinDown.
     * For Entangled particles, it shows the potential pair outcomes based on the entanglement type.
     * This is a simulation and doesn't guarantee the actual outcome due to the simulated randomness during `observeParticle`.
     * @param particleId The ID of the particle.
     * @return An array of possible states.
     */
    function predictPotentialStates(uint256 particleId) public view returns (ParticleState[] memory) {
        require(_particleExists(particleId), "Particle does not exist");
        QuantumParticle storage p = particles[particleId];

        if (p.state == ParticleState.Superposed) {
            // Could collapse to SpinUp or SpinDown
            ParticleState[] memory potential = new ParticleState[](2);
            potential[0] = ParticleState.SpinUp;
            potential[1] = ParticleState.SpinDown;
            return potential;
        } else if (p.state == ParticleState.Entangled) {
            bytes32[] storage pairHashes = _particleEntanglements[particleId];
            // For simplicity, predicting for ALL uncollapsed pairs the particle is in
            // In reality, observing one might collapse others simultaneously.
            // This just shows the *possibilities* if that specific entanglement collapses.
            ParticleState[] memory potential = new ParticleState[](0); // Dynamic array

            for (uint i = 0; i < pairHashes.length; i++) {
                 bytes32 pairKey = pairHashes[i];
                 EntanglementPair storage pair = _entanglementPairs[pairKey];

                 if (!pair.isCollapsed) {
                     // Predict based on entanglement type
                     if (pair.entType == EntanglementType.SpinOpposite) {
                         // Could be SpinUp (if partner is Down) or SpinDown (if partner is Up)
                         // So, potential outcomes for *this* particle are SpinUp and SpinDown
                          ParticleState[] memory pairPotential = new ParticleState[](2);
                          pairPotential[0] = ParticleState.SpinUp;
                          pairPotential[1] = ParticleState.SpinDown;
                          potential = _concatArrays(potential, pairPotential); // Helper to concatenate
                     } else if (pair.entType == EntanglementType.SpinSame) {
                          // Could be SpinUp (if partner is Up) or SpinDown (if partner is Down)
                          // So, potential outcomes for *this* particle are SpinUp and SpinDown
                          ParticleState[] memory pairPotential = new ParticleState[](2);
                          pairPotential[0] = ParticleState.SpinUp;
                          pairPotential[1] = ParticleState.SpinDown;
                          potential = _concatArrays(potential, pairPotential);
                     } else if (pair.entType == EntanglementType.RandomPair) {
                         // Could collapse to SpinUp or SpinDown independently
                          ParticleState[] memory pairPotential = new ParticleState[](2);
                          pairPotential[0] = ParticleState.SpinUp;
                          pairPotential[1] = ParticleState.SpinDown;
                          potential = _concatArrays(potential, pairPotential);
                     }
                 }
            }
            // Remove duplicates if any, though in this simplified model, it's always {SpinUp, SpinDown} for Superposed/Entangled.
            // A more complex model might have more states or restrictions.
             if (potential.length > 0) {
                 // Simple deduplication: if any element is SpinUp/Down, the potential is {SpinUp, SpinDown}
                 return new ParticleState[](2) {ParticleState.SpinUp, ParticleState.SpinDown};
             } else {
                 // No uncollapsed entanglements or just Superposed -> Standard {SpinUp, SpinDown}
                 return new ParticleState[](2) {ParticleState.SpinUp, ParticleState.SpinDown};
             }


        } else if (isParticleCollapsed(particleId)) {
             // Already collapsed, potential is just the resolved state
             ParticleState[] memory potential = new ParticleState[](1);
             potential[0] = p.resolvedState;
             return potential;
        } else {
             // Created state or other non-collapsible state
             return new ParticleState[](0); // No collapse potential
        }
    }

    // Internal helper for predictPotentialStates array concatenation (basic implementation)
    function _concatArrays(ParticleState[] memory a, ParticleState[] memory b) internal pure returns (ParticleState[] memory) {
        ParticleState[] memory result = new ParticleState[](a.length + b.length);
        uint k = 0;
        for (uint i = 0; i < a.length; i++) {
            result[k++] = a[i];
        }
        for (uint i = 0; i < b.length; i++) {
            result[k++] = b[i];
        }
        return result;
    }


     /**
     * @dev Conceptual function to calculate a measure of "Entanglement Entropy" for a particle.
     * Here defined as the number of *uncollapsed* entanglements the particle is currently involved in.
     * More uncollapsed entanglements means higher "entropy" or uncertainty before observation.
     * @param particleId The ID of the particle.
     * @return uint256 The number of uncollapsed entanglements.
     */
    function calculateEntanglementEntropy(uint256 particleId) public view returns (uint256) {
        require(_particleExists(particleId), "Particle does not exist");
        bytes32[] storage pairHashes = _particleEntanglements[particleId];
        uint256 uncollapsedCount = 0;
        for (uint i = 0; i < pairHashes.length; i++) {
            bytes32 pairKey = pairHashes[i];
            EntanglementPair storage pair = _entanglementPairs[pairKey];
            if (pair.entType != EntanglementType.Uninitialized && !pair.isCollapsed) {
                uncollapsedCount++;
            }
        }
        return uncollapsedCount;
    }

    /**
     * @dev Creates a new particle whose initial state (SpinUp or SpinDown) is determined by the resolved state of an *already observed* particle.
     * This conceptually links the creation of new particles to the outcomes of past quantum measurements.
     * Requires the observed particle to be in a collapsed state (SpinUp or SpinDown).
     * @param observedParticleId The ID of the particle whose resolved state determines the new particle's state.
     * @param newOwner The address to assign ownership of the new particle to.
     * @return The ID of the newly created particle.
     */
    function createParticleFromObservation(uint256 observedParticleId, address newOwner) public onlyOwner returns (uint256) {
        require(_particleExists(observedParticleId), "Observed particle does not exist");
        QuantumParticle storage observedParticle = particles[observedParticleId];
        require(observedParticle.state == ParticleState.SpinUp || observedParticle.state == ParticleState.SpinDown, "Observed particle must be in a SpinUp/SpinDown state");

        _particleIds.increment();
        uint256 newParticleId = _particleIds.current();
        ParticleState initialState = observedParticle.resolvedState; // Use the resolved state as initial state

        particles[newParticleId] = QuantumParticle({
            id: newParticleId,
            state: initialState, // Set state directly to the observed state
            creationTimestamp: uint64(block.timestamp),
            owner: newOwner,
            isEntanglementMemberCollapsed: true, // A particle starting in Spin state is considered 'collapsed' from creation
            resolvedState: initialState // Its resolved state is its initial state
        });

        emit ParticleCreated(newParticleId, newOwner, initialState, uint64(block.timestamp));
        emit ParticleCreatedFromObservation(newParticleId, observedParticleId, initialState);
        return newParticleId;
    }

    /**
     * @dev Admin function to forcefully set a particle to a collapsed state, bypassing the normal observation process.
     * Useful for testing or emergency state overrides.
     * @param particleId The ID of the particle to force collapse.
     * @param targetState The target collapsed state (SpinUp, SpinDown, or Collapsed).
     */
    function adminForceCollapse(uint256 particleId, ParticleState targetState) public onlyOwner {
        require(_particleExists(particleId), "Particle does not exist");
        require(targetState == ParticleState.SpinUp || targetState == ParticleState.SpinDown || targetState == ParticleState.Collapsed, "Target state must be a collapsed state");

        QuantumParticle storage p = particles[particleId];
        ParticleState oldState = p.state;

        // If entangled and not yet collapsed, also handle the pair
        bytes32[] memory pairHashes = _particleEntanglements[particleId];
        for (uint i = 0; i < pairHashes.length; i++) {
             bytes32 pairKey = pairHashes[i];
             EntanglementPair storage pair = _entanglementPairs[pairKey];

             if (!pair.isCollapsed) {
                 // Force collapse the pair as well
                  pair.isCollapsed = true;
                  // Admin might just want to force *this* particle's state,
                  // so set the other's state randomly or to a default collapsed state.
                  // For simplicity, let's set both to the target state if EntanglementType allows,
                  // otherwise set the other based on the target state and EntanglementType.
                  uint256 otherParticleId = (pair.particleId1 == particleId) ? pair.particleId2 : pair.particleId1;
                  QuantumParticle storage pOther = particles[otherParticleId];

                  ParticleState resolvedOther;
                   if (pair.entType == EntanglementType.SpinOpposite && (targetState == ParticleState.SpinUp || targetState == ParticleState.SpinDown)) {
                       resolvedOther = (targetState == ParticleState.SpinUp) ? ParticleState.SpinDown : ParticleState.SpinUp;
                   } else if (pair.entType == EntanglementType.SpinSame && (targetState == ParticleState.SpinUp || targetState == ParticleState.SpinDown)) {
                       resolvedOther = targetState;
                   } else {
                       // For RandomPair or Collapsed target, just set the other to Collapsed state
                       resolvedOther = ParticleState.Collapsed;
                   }

                  if (pair.particleId1 == particleId) {
                      pair.resolvedState1 = targetState;
                      pair.resolvedState2 = resolvedOther;
                  } else {
                      pair.resolvedState2 = targetState;
                      pair.resolvedState1 = resolvedOther;
                  }

                  pOther.state = resolvedOther;
                  pOther.resolvedState = resolvedOther;
                  pOther.isEntanglementMemberCollapsed = true;
                   emit ParticleStateChanged(otherParticleId, pOther.state, resolvedOther);
                   emit ParticleObserved(otherParticleId, resolvedOther); // Admin collapse is still an 'observation' event for tracking
                   emit EntanglementCollapsed(particleId, otherParticleId, targetState, resolvedOther, pairKey);
             }
        }

        // Force the particle state
        p.state = targetState;
        p.resolvedState = targetState;
        p.isEntanglementMemberCollapsed = true; // Mark as collapsed

        emit ParticleStateChanged(particleId, oldState, targetState);
        emit ParticleObserved(particleId, targetState); // Admin collapse is still an 'observation' event for tracking
    }

    /**
     * @dev Admin function to forcefully dissolve all entanglements involving a specific particle, regardless of their collapsed state.
     * This effectively isolates the particle from all its pairs.
     * @param particleId The ID of the particle.
     */
    function adminDissolveAllForParticle(uint256 particleId) public onlyOwner {
        require(_particleExists(particleId), "Particle does not exist");

        bytes32[] memory pairHashes = _particleEntanglements[particleId];
        // Clear the list before iterating, as dissolving modifies the array
        delete _particleEntanglements[particleId];


        for (uint i = 0; i < pairHashes.length; i++) {
             bytes32 pairKey = pairHashes[i];
             EntanglementPair storage pair = _entanglementPairs[pairKey];

             if (pair.entType != EntanglementType.Uninitialized) {
                uint256 otherParticleId = (pair.particleId1 == particleId) ? pair.particleId2 : pair.particleId1;

                // Clean up the pair entry
                delete _entanglementPairs[pairKey];

                 // Remove this pair hash from the *other* particle's list as well
                 _removePairHashFromParticle(otherParticleId, pairKey);

                 // Reset particle states if they were Entangled and not already collapsed
                 QuantumParticle storage p1 = particles[particleId];
                 QuantumParticle storage p2 = particles[otherParticleId];

                 // If they were Entangled and not collapsed, revert them.
                 // If collapsed, their state remains, but entanglement linkage is broken.
                 if(p1.state == ParticleState.Entangled && !pair.isCollapsed) {
                     ParticleState oldState1 = p1.state;
                     p1.state = ParticleState.Superposed;
                      emit ParticleStateChanged(particleId, oldState1, p1.state);
                 }
                 if(p2.state == ParticleState.Entangled && !pair.isCollapsed) {
                      ParticleState oldState2 = p2.state;
                     p2.state = ParticleState.Superposed;
                      emit ParticleStateChanged(otherParticleId, oldState2, p2.state);
                 }

                emit EntanglementDissolved(particleId, otherParticleId, pairKey);
             }
        }
    }


    // --- View Functions (>= 20 total functions) ---

    /**
     * @dev Returns the details of a particle struct.
     * @param particleId The ID of the particle.
     * @return The QuantumParticle struct.
     */
    function getParticleDetails(uint256 particleId) public view returns (QuantumParticle memory) {
        require(_particleExists(particleId), "Particle does not exist");
        return particles[particleId];
    }

    /**
     * @dev Returns the current state of a particle.
     * @param particleId The ID of the particle.
     * @return The ParticleState enum.
     */
    function getParticleState(uint256 particleId) public view returns (ParticleState) {
         require(_particleExists(particleId), "Particle does not exist");
         return particles[particleId].state;
    }

    /**
     * @dev Returns the owner of a particle.
     * @param particleId The ID of the particle.
     * @return The owner address.
     */
    function getParticleOwner(uint256 particleId) public view returns (address) {
         require(_particleExists(particleId), "Particle does not exist");
         return particles[particleId].owner;
    }

     /**
     * @dev Returns the creation timestamp of a particle.
     * @param particleId The ID of the particle.
     * @return The creation timestamp (uint64).
     */
    function getParticleCreationTime(uint256 particleId) public view returns (uint64) {
         require(_particleExists(particleId), "Particle does not exist");
         return particles[particleId].creationTimestamp;
    }

    /**
     * @dev Returns the contract version string.
     */
    function getVersion() public pure returns (string memory) {
        return version;
    }

    // Counting functions required for >= 20, already listed in summary:
    // 7. getTotalParticles() - Implemented
    // 13. getParticleEntanglements(uint256 particleId) - Implemented
    // 14. getEntanglementDetails(uint256 particleId1, uint256 particleId2) - Implemented
    // 15. checkEntanglementStatus(uint256 particleId1, uint256 particleId2) - Implemented
    // 17. isParticleCollapsed(uint256 particleId) - Implemented
    // 18. getResolvedState(uint256 particleId) - Implemented
    // 19. getPairResolvedStates(uint256 particleId1, uint256 particleId2) - Implemented
    // 21. predictPotentialStates(uint256 particleId) - Implemented
    // 22. calculateEntanglementEntropy(uint256 particleId) - Implemented
    // Plus the other 20+ functions previously outlined.


    // Ensure we have at least 20 functions:
    // 1. constructor
    // 2. createParticle
    // 3. batchCreateParticles
    // 4. getTotalParticles
    // 5. transferParticleOwnership
    // 6. renounceOwnership (from Ownable)
    // 7. enterSuperposition
    // 8. simulateQuantumFluctuation
    // 9. predictPotentialStates
    // 10. getParticleDetails
    // 11. getParticleState
    // 12. getParticleOwner
    // 13. getParticleCreationTime
    // 14. isParticleCollapsed
    // 15. createEntangledPair
    // 16. dissolveEntanglement
    // 17. getParticleEntanglements
    // 18. getEntanglementDetails
    // 19. checkEntanglementStatus
    // 20. observeParticle
    // 21. getResolvedState
    // 22. getPairResolvedStates
    // 23. setEntanglementResolutionSeed
    // 24. calculateEntanglementEntropy
    // 25. createParticleFromObservation
    // 26. adminForceCollapse
    // 27. adminDissolveAllForParticle
    // 28. getVersion
    // Yes, we have 28 public/external functions plus the constructor and internal helpers. This exceeds the 20 function requirement.

}
```