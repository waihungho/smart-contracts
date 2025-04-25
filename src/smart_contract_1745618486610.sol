Okay, let's create a smart contract exploring concepts inspired by quantum mechanics and complex systems, focusing on state changes influenced by internal entropy, external interactions, attestations, and simulated observation. We'll call it `QuantumFluctuations`.

It will manage abstract "Particles" that exist in various simulated "states," which can change based on defined rules. The state changes can be probabilistic, influenced by a global "Entropy Pool" and individual particle properties.

**Outline and Function Summary**

**Contract Name:** `QuantumFluctuations`

**Core Concept:** Manages abstract 'Particles' with complex, evolving states influenced by entropy, interactions, time, and external attestations. Simulates probabilistic state transitions and interactions inspired by quantum concepts like superposition (multi-state potential), entanglement (linked states), and observation (state collapse).

**Key State Variables:**
*   `entropyPool`: A global measure influencing system randomness and energy.
*   `particles`: Mapping storing details of each particle.
*   `particleAttestations`: Mapping storing external attestations towards particles, influencing their potential state.
*   `chronitons`: Mapping storing time-based persistence values for particles.
*   `delayedEffects`: Mapping storing state changes scheduled for the future.
*   `nextParticleId`: Counter for new particles.

**Enums:**
*   `ParticleState`: Defines possible states (e.g., Undetermined, Coherent, Decoherent, Entangled, Collapsed).
*   `DelayedEffectType`: Defines types of effects to be applied later.

**Structs:**
*   `Particle`: Represents a particle with properties like owner, state, entropy level, timestamps, flags, linked particles, attestation weight.
*   `DelayedEffect`: Represents a pending state change with target, type, trigger time, and data.

**Functions (Minimum 20):**

1.  `constructor()`: Initializes the contract with a starting entropy level.
2.  `createParticle()`: Mints a new particle for the caller in an initial state (e.g., Undetermined). Costs entropy.
3.  `attestToParticle(uint256 particleId, uint8 weight)`: Allows users to influence a particle's potential state by adding an attestation with a certain weight.
4.  `revokeAttestation(uint256 particleId)`: Removes the caller's attestation from a particle.
5.  `observeParticle(uint256 particleId)`: Attempts to "collapse" a particle's state from a potential/undetermined state to a single determined state based on internal entropy, attestations, and current conditions. Probabilistic outcome. Costs entropy.
6.  `interactParticles(uint256 particleId1, uint256 particleId2)`: Simulates interaction between two particles, potentially changing their states or creating/dissipating entanglement. Costs entropy.
7.  `entangleParticles(uint256 particleId1, uint256 particleId2)`: Attempts to link the states of two particles, making their future states dependent on each other. Requires specific particle states. Costs entropy.
8.  `dissipateEntanglement(uint256 particleId)`: Breaks the entanglement involving a specific particle. Costs entropy.
9.  `injectEntropy(uint256 amount)`: Increases the global entropy pool.
10. `extractEntropy(uint256 amount)`: Decreases the global entropy pool (e.g., used as a cost for high-level operations).
11. `applyChroniton(uint256 particleId, uint256 duration)`: Adds a "Chroniton" value to a particle, increasing its state stability or preventing state changes for a duration. Costs entropy.
12. `decayChroniton(uint256 particleId)`: Explicitly reduces the Chroniton value (can also decay over time implicitly in state transitions).
13. `triggerDelayedEffect(uint256 particleId, DelayedEffectType effectType, uint256 delayInSeconds, bytes calldata data)`: Schedules a specific state change effect to occur on a particle at a future time. Costs entropy.
14. `processDelayedEffect(uint256 particleId)`: Function called (potentially by a relayer or keeper) to execute a scheduled delayed effect if its trigger time has passed.
15. `evolveParticle(uint256 particleId)`: A general function to advance the particle's state based on time elapsed since last interaction, current entropy level, attestation influence, and internal rules. Might be probabilistic. Costs entropy.
16. `transferParticle(address recipient, uint256 particleId)`: Transfers ownership of a particle (acts like a simplified ERC-721 transfer for the particle ID). Requires particle to be in a 'transferable' state.
17. `getParticleState(uint256 particleId)`: Reads the current simulated state of a particle.
18. `getParticleDetails(uint256 particleId)`: Reads all details of a specific particle.
19. `getEntropyPool()`: Reads the current global entropy pool value.
20. `getAttestationWeight(uint256 particleId, address attester)`: Reads the attestation weight provided by a specific address for a particle.
21. `getDelayedEffect(uint256 particleId)`: Reads details of a pending delayed effect for a particle.
22. `simulateObservationOutcome(uint256 particleId)`: Pure function predicting the *potential* state outcome if `observeParticle` were called now, without changing state. Uses current state, entropy, and attestations.
23. `resolveEntangledState(uint256 particleId)`: If a particle is entangled and its state is observed/collapsed, this function (internal or external call) can potentially resolve the state of the *linked* particle based on entanglement rules.
24. `setCausalityLock(uint256 particleId, uint256 lockDuration)`: Applies a temporary lock preventing certain state changes for a duration, simulating a localized 'causality lock'. Costs entropy.
25. `checkCausalityLock(uint256 particleId)`: Checks if a particle is currently under a causality lock and returns remaining time.
26. `scrambleEntropy(uint256 factor)`: Randomly redistributes a portion of the global entropy pool internally or between particles, based on a factor. Costs entropy.
27. `measureParticleCoherence(uint256 particleId)`: Attempts to measure how "coherent" a particle's state is (i.e., how close it is to collapsing or becoming unstable), based on internal state, chroniton, and entropy. Returns a score.
28. `applyExternalFluctuation(uint256 particleId, uint256 fluctuationMagnitude)`: Simulates an external force acting on a particle, potentially increasing its entropy level or triggering a state change based on magnitude. Costs fluctuation magnitude.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuations
 * @dev A smart contract simulating abstract 'Particles' with complex, evolving states
 *      influenced by internal entropy, external interactions, time, and attestations.
 *      Explores concepts of probabilistic state transitions, entanglement,
 *      observation (state collapse), delayed effects, and time-based state persistence.
 *
 * Outline and Function Summary:
 *
 * Core Concept:
 * Manages abstract 'Particles' with complex, evolving states influenced by entropy,
 * interactions, time, and external attestations. Simulates probabilistic state
 * transitions and interactions inspired by quantum concepts like superposition
 * (multi-state potential), entanglement (linked states), and observation (state collapse).
 *
 * Key State Variables:
 * - entropyPool: A global measure influencing system randomness and energy.
 * - particles: Mapping storing details of each particle.
 * - particleAttestations: Mapping storing external attestations towards particles.
 * - chronitons: Mapping storing time-based persistence values.
 * - delayedEffects: Mapping storing state changes scheduled for the future.
 * - nextParticleId: Counter for new particles.
 *
 * Enums:
 * - ParticleState: Defines possible states (Undetermined, Coherent, Decoherent, Entangled, Collapsed).
 * - DelayedEffectType: Defines types of effects for delayed execution.
 *
 * Structs:
 * - Particle: Represents a particle with properties like owner, state, entropy level, timestamps, flags, linked particles, attestation weight.
 * - DelayedEffect: Represents a pending state change with target, type, trigger time, and data.
 *
 * Functions (Minimum 20+):
 * 1. constructor(): Initializes the contract with a starting entropy level.
 * 2. createParticle(): Mints a new particle for the caller in an initial state.
 * 3. attestToParticle(uint256 particleId, uint8 weight): Users influence a particle's potential state.
 * 4. revokeAttestation(uint256 particleId): Removes caller's attestation.
 * 5. observeParticle(uint256 particleId): Attempts to 'collapse' a particle's state probabilistically.
 * 6. interactParticles(uint256 particleId1, uint256 particleId2): Simulates interaction, potentially changing states or entanglement.
 * 7. entangleParticles(uint256 particleId1, uint256 particleId2): Attempts to link states of two particles.
 * 8. dissipateEntanglement(uint256 particleId): Breaks entanglement.
 * 9. injectEntropy(uint256 amount): Increases global entropy pool.
 * 10. extractEntropy(uint256 amount): Decreases global entropy pool.
 * 11. applyChroniton(uint256 particleId, uint256 duration): Adds time-based state stability.
 * 12. decayChroniton(uint256 particleId): Explicitly reduces Chroniton value.
 * 13. triggerDelayedEffect(uint256 particleId, DelayedEffectType effectType, uint256 delayInSeconds, bytes calldata data): Schedules a future state change.
 * 14. processDelayedEffect(uint256 particleId): Executes a scheduled delayed effect if time is up.
 * 15. evolveParticle(uint256 particleId): General function to advance state based on time, entropy, etc.
 * 16. transferParticle(address recipient, uint256 particleId): Transfers particle ownership.
 * 17. getParticleState(uint256 particleId): Reads current particle state.
 * 18. getParticleDetails(uint256 particleId): Reads all particle details.
 * 19. getEntropyPool(): Reads global entropy pool value.
 * 20. getAttestationWeight(uint256 particleId, address attester): Reads attestation weight by an address.
 * 21. getDelayedEffect(uint256 particleId): Reads details of a pending delayed effect.
 * 22. simulateObservationOutcome(uint256 particleId): Pure function predicting potential observation result.
 * 23. resolveEntangledState(uint256 particleId): Resolves linked particle's state if entangled particle is observed/collapsed.
 * 24. setCausalityLock(uint256 particleId, uint256 lockDuration): Applies a temporary lock preventing certain changes.
 * 25. checkCausalityLock(uint256 particleId): Checks if particle is under causality lock.
 * 26. scrambleEntropy(uint256 factor): Redistributes entropy internally.
 * 27. measureParticleCoherence(uint256 particleId): Measures state stability potential.
 * 28. applyExternalFluctuation(uint256 particleId, uint256 fluctuationMagnitude): Simulates external force influence.
 */
contract QuantumFluctuations {

    // --- Enums ---
    enum ParticleState {
        Undetermined, // State is probabilistic / not yet observed
        Coherent,     // Stable, ordered state
        Decoherent,   // Unstable, likely to change state
        Entangled,    // Linked to another particle's state
        Collapsed     // State has been observed and fixed
    }

    enum DelayedEffectType {
        StateTransitionToCoherent,
        StateTransitionToDecoherent,
        IncreaseEntropy,
        DissipateChroniton,
        ScrambleAttestations
    }

    // --- Structs ---
    struct Particle {
        uint256 id;
        address owner;
        ParticleState currentState;
        uint256 entropyLevel; // Internal entropy influencing its volatility
        uint64 lastInteractionTime;
        uint256 linkedParticleId; // For entanglement
        uint256 attestationWeight; // Total external attestation influence
        uint256 flags; // Bitmask for various properties (e.g., 1=IsObserved, 2=IsEntangled, 4=RequiresChroniton)
        uint64 causalityLockUntil; // Timestamp until causality lock expires
    }

    struct DelayedEffect {
        uint256 targetParticleId;
        DelayedEffectType effectType;
        uint64 triggerTime;
        bytes data; // Optional data for the effect
        bool exists; // To differentiate default struct from set struct
    }

    // --- State Variables ---
    uint256 public entropyPool; // Global entropy pool
    mapping(uint256 => Particle) public particles; // Stores all particles by ID
    mapping(uint256 => mapping(address => uint8)) private particleAttestations; // Attestations by user per particle
    mapping(uint256 => uint256) public chronitons; // Time-based persistence value per particle
    mapping(uint256 => DelayedEffect) public delayedEffects; // Stores pending delayed effects by target particle ID
    uint256 public nextParticleId = 1; // Counter for new particles

    // --- Events ---
    event ParticleCreated(uint256 indexed particleId, address indexed owner, ParticleState initialState);
    event ParticleStateChanged(uint256 indexed particleId, ParticleState newState, ParticleState oldState);
    event EntropyInjected(uint256 amount, address indexed by);
    event EntropyExtracted(uint256 amount, address indexed by);
    event AttestationAdded(uint256 indexed particleId, address indexed attester, uint8 weight);
    event AttestationRevoked(uint256 indexed particleId, address indexed attester);
    event ParticleObserved(uint256 indexed particleId, ParticleState finalState, uint256 entropyAtObservation);
    event ParticlesInteracted(uint256 indexed particleId1, uint256 indexed particleId2);
    event ParticlesEntangled(uint256 indexed particleId1, uint256 indexed particleId2);
    event EntanglementDissipated(uint256 indexed particleId);
    event ChronitonApplied(uint256 indexed particleId, uint256 duration);
    event ChronitonDecayed(uint256 indexed particleId, uint256 remainingChroniton);
    event DelayedEffectTriggered(uint256 indexed particleId, DelayedEffectType effectType, uint64 triggerTime);
    event DelayedEffectProcessed(uint256 indexed particleId, DelayedEffectType effectType);
    event ParticleEvolved(uint256 indexed particleId, ParticleState newState);
    event ParticleTransferred(uint256 indexed particleId, address indexed from, address indexed to);
    event CausalityLockApplied(uint256 indexed particleId, uint64 lockUntil);
    event EntropyScrambled(uint256 factor);
    event ParticleCoherenceMeasured(uint256 indexed particleId, uint256 coherenceScore);
    event ExternalFluctuationApplied(uint256 indexed particleId, uint256 magnitude);


    // --- Modifiers ---
    modifier particleExists(uint256 _particleId) {
        require(particles[_particleId].id != 0, "Particle does not exist");
        _;
    }

    modifier notCausalityLocked(uint256 _particleId) {
         require(block.timestamp >= particles[_particleId].causalityLockUntil, "Particle is causality locked");
         _;
    }

    // --- Constructor ---
    constructor(uint256 initialEntropy) {
        entropyPool = initialEntropy;
    }

    // --- Core Functionality ---

    /**
     * @dev Creates a new particle in an initial Undetermined state for the caller.
     * Costs 10 entropy from the pool.
     * @return particleId The ID of the newly created particle.
     */
    function createParticle() external notCausalityLocked(0) returns (uint256 particleId) {
        require(entropyPool >= 10, "Not enough global entropy to create particle");
        entropyPool -= 10;

        particleId = nextParticleId++;
        particles[particleId] = Particle({
            id: particleId,
            owner: msg.sender,
            currentState: ParticleState.Undetermined,
            entropyLevel: 1, // Start with low internal entropy
            lastInteractionTime: uint64(block.timestamp),
            linkedParticleId: 0,
            attestationWeight: 0,
            flags: 0,
            causalityLockUntil: 0
        });

        emit ParticleCreated(particleId, msg.sender, ParticleState.Undetermined);
    }

    /**
     * @dev Allows an address to attest to a particle, influencing its future state collapse.
     * Weight is cumulative per address per particle. Max weight is 100 per attester.
     * @param particleId The ID of the particle to attest to.
     * @param weight The weight of the attestation (1-100).
     */
    function attestToParticle(uint256 particleId, uint8 weight) external particleExists(particleId) notCausalityLocked(particleId) {
        require(weight > 0 && weight <= 100, "Weight must be between 1 and 100");

        uint8 currentAttestation = particleAttestations[particleId][msg.sender];
        uint8 newAttestation = weight; // Can make this cumulative or replace, replace is simpler

        particles[particleId].attestationWeight = particles[particleId].attestationWeight - currentAttestation + newAttestation;
        particleAttestations[particleId][msg.sender] = newAttestation;

        emit AttestationAdded(particleId, msg.sender, newAttestation);
    }

    /**
     * @dev Allows an address to revoke their attestation from a particle.
     * @param particleId The ID of the particle.
     */
    function revokeAttestation(uint256 particleId) external particleExists(particleId) notCausalityLocked(particleId) {
        uint8 currentAttestation = particleAttestations[particleId][msg.sender];
        require(currentAttestation > 0, "No active attestation from this address");

        particles[particleId].attestationWeight -= currentAttestation;
        delete particleAttestations[particleId][msg.sender];

        emit AttestationRevoked(particleId, msg.sender);
    }

    /**
     * @dev Attempts to 'collapse' the state of an Undetermined or Decoherent particle
     * to a fixed state (Coherent or Collapsed) based on a probabilistic outcome
     * influenced by global entropy, particle's internal entropy, and total attestations.
     * Costs variable entropy.
     * @param particleId The ID of the particle to observe.
     */
    function observeParticle(uint256 particleId) external particleExists(particleId) notCausalityLocked(particleId) {
        Particle storage particle = particles[particleId];
        require(particle.currentState == ParticleState.Undetermined || particle.currentState == ParticleState.Decoherent, "Particle state is not suitable for observation");
        require(particle.currentState != ParticleState.Collapsed, "Particle state is already collapsed");
        require(particle.currentState != ParticleState.Entangled, "Cannot observe an entangled particle directly");

        uint256 observationCost = 20 + particle.entropyLevel; // Cost scales with internal entropy
        require(entropyPool >= observationCost, "Not enough global entropy for observation");
        entropyPool -= observationCost;

        // --- Probabilistic State Collapse Logic (Simplified) ---
        // This is a simplified simulation. Real randomness on-chain is tricky.
        // Using blockhash/timestamp/msg.sender is deterministic but provides variety for demonstration.
        // For production randomness, consider VRF or other oracle solutions.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, particleId, entropyPool, particle.entropyLevel)));

        // Factors influencing outcome:
        // - Global Entropy: Higher entropy -> more unpredictable (Decoherent outcome more likely)
        // - Particle Entropy: Higher internal entropy -> more chaotic (Decoherent outcome more likely)
        // - Attestations: Higher attestation -> more 'aligned' (Coherent/Collapsed outcome more likely)
        // - Current State: Decoherent is more likely to collapse to Collapsed/Decoherent again. Undetermined is more open.

        uint256 outcomeFactor = (seed % 1000) + particle.attestationWeight - (entropyPool / 100) - (particle.entropyLevel * 10);

        ParticleState oldState = particle.currentState;
        ParticleState newState;

        if (outcomeFactor >= 500) { // Higher attestation/lower entropy bias
            newState = ParticleState.Coherent;
        } else if (outcomeFactor >= 200) { // Mixed influence
             if (seed % 2 == 0) { newState = ParticleState.Coherent; } else { newState = ParticleState.Decoherent; }
        }
         else { // Lower attestation/higher entropy bias
            newState = ParticleState.Decoherent;
        }

        // Add a chance to go straight to Collapsed if it was already Decoherent or very high attestation
        if ((oldState == ParticleState.Decoherent && (seed % 5 < 2)) || (particle.attestationWeight > 100 && (seed % 10 < 3))) {
             newState = ParticleState.Collapsed;
             particle.flags |= 1; // Set IsObserved flag
        } else if (newState == ParticleState.Coherent) {
             particle.flags &= ~1; // Clear IsObserved flag if it becomes Coherent
        }


        particle.currentState = newState;
        particle.lastInteractionTime = uint64(block.timestamp);

        emit ParticleObserved(particleId, newState, entropyPool);
        emit ParticleStateChanged(particleId, newState, oldState);
    }

    /**
     * @dev Simulates interaction between two particles. Outcome depends on their current states.
     * Can cause state changes or initiate/dissipate entanglement.
     * Costs 15 entropy.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     */
    function interactParticles(uint256 particleId1, uint256 particleId2) external particleExists(particleId1) particleExists(particleId2) notCausalityLocked(particleId1) notCausalityLocked(particleId2) {
        require(particleId1 != particleId2, "Cannot interact a particle with itself");
        require(entropyPool >= 15, "Not enough global entropy for interaction");
        entropyPool -= 15;

        Particle storage p1 = particles[particleId1];
        Particle storage p2 = particles[particleId2];

        // Simplified interaction logic based on states (can be much more complex)
        if (p1.currentState == ParticleState.Undetermined && p2.currentState == ParticleState.Undetermined) {
            // Might increase entropy, slightly push towards Decoherent
            p1.entropyLevel += 1;
            p2.entropyLevel += 1;
            if (p1.entropyLevel > 5) p1.currentState = ParticleState.Decoherent;
            if (p2.entropyLevel > 5) p2.currentState = ParticleState.Decoherent;
        } else if (p1.currentState == ParticleState.Coherent && p2.currentState == ParticleState.Coherent) {
             // Might resist change, maybe slight entropy increase
             p1.entropyLevel += 1;
             p2.entropyLevel += 1;
        } else if (p1.currentState == ParticleState.Decoherent || p2.currentState == ParticleState.Decoherent) {
            // High chance of state change or entanglement
             uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, particleId1, particleId2)));
             if (seed % 3 == 0) {
                 entangleParticles(particleId1, particleId2); // Attempt entanglement
             } else if (seed % 3 == 1) {
                 // Trigger a state evolution immediately
                 _evolveParticleState(p1);
                 _evolveParticleState(p2);
             } else {
                 // Just increase internal entropy
                 p1.entropyLevel += 2;
                 p2.entropyLevel += 2;
             }
        }
        // Interaction logic for Entangled/Collapsed states could be added

        p1.lastInteractionTime = uint64(block.timestamp);
        p2.lastInteractionTime = uint64(block.timestamp);

        emit ParticlesInteracted(particleId1, particleId2);
         // Emit state change events if states changed
        if (p1.currentState != particles[particleId1].currentState) emit ParticleStateChanged(particleId1, p1.currentState, particles[particleId1].currentState);
        if (p2.currentState != particles[particleId2].currentState) emit ParticleStateChanged(particleId2, p2.currentState, particles[particleId2].currentState);
    }


    /**
     * @dev Attempts to link the states of two particles, making them entangled.
     * Requires both particles to be in a non-Collapsed, non-Entangled state.
     * Costs 30 entropy.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     */
    function entangleParticles(uint256 particleId1, uint256 particleId2) public particleExists(particleId1) particleExists(particleId2) notCausalityLocked(particleId1) notCausalityLocked(particleId2) {
        require(particleId1 != particleId2, "Cannot entangle a particle with itself");
        Particle storage p1 = particles[particleId1];
        Particle storage p2 = particles[particleId2];

        require(p1.currentState != ParticleState.Collapsed && p1.currentState != ParticleState.Entangled, "Particle 1 cannot be entangled");
        require(p2.currentState != ParticleState.Collapsed && p2.currentState != ParticleState.Entangled, "Particle 2 cannot be entangled");

        require(entropyPool >= 30, "Not enough global entropy for entanglement");
        entropyPool -= 30;

        p1.currentState = ParticleState.Entangled;
        p2.currentState = ParticleState.Entangled;
        p1.linkedParticleId = particleId2;
        p2.linkedParticleId = particleId1;
        p1.flags |= 2; // Set IsEntangled flag
        p2.flags |= 2; // Set IsEntangled flag

        emit ParticlesEntangled(particleId1, particleId2);
         emit ParticleStateChanged(particleId1, ParticleState.Entangled, p1.currentState); // Old state is whatever it was before
         emit ParticleStateChanged(particleId2, ParticleState.Entangled, p2.currentState);
    }

    /**
     * @dev Breaks the entanglement involving a specific particle.
     * If the linked particle exists and is also entangled with this one, its entanglement is broken too.
     * Costs 5 entropy.
     * @param particleId The ID of the particle whose entanglement to break.
     */
    function dissipateEntanglement(uint256 particleId) public particleExists(particleId) notCausalityLocked(particleId) {
        Particle storage p = particles[particleId];
        require(p.currentState == ParticleState.Entangled, "Particle is not entangled");
        require(entropyPool >= 5, "Not enough global entropy to dissipate entanglement");
        entropyPool -= 5;

        uint256 linkedId = p.linkedParticleId;
        p.currentState = ParticleState.Decoherent; // Return to a volatile state
        p.linkedParticleId = 0;
        p.flags &= ~2; // Clear IsEntangled flag

        emit EntanglementDissipated(particleId);
        emit ParticleStateChanged(particleId, ParticleState.Decoherent, ParticleState.Entangled);

        // Dissipate entanglement on the linked particle if it exists and is correctly linked
        if (linkedId != 0 && particles[linkedId].id != 0 && particles[linkedId].linkedParticleId == particleId) {
             Particle storage linkedP = particles[linkedId];
             linkedP.currentState = ParticleState.Decoherent; // Return to a volatile state
             linkedP.linkedParticleId = 0;
             linkedP.flags &= ~2; // Clear IsEntangled flag
             emit EntanglementDissipated(linkedId);
             emit ParticleStateChanged(linkedId, ParticleState.Decoherent, ParticleState.Entangled);
        }
    }

    /**
     * @dev Increases the global entropy pool. Can be called by anyone (simulate external energy).
     * @param amount The amount of entropy to inject.
     */
    function injectEntropy(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        entropyPool += amount;
        emit EntropyInjected(amount, msg.sender);
    }

    /**
     * @dev Decreases the global entropy pool. Can be used as a sink or cost for specific actions.
     * Costs 1 unit from the caller's ETH balance per 100 entropy extracted (example cost mechanism).
     * @param amount The amount of entropy to extract.
     */
    function extractEntropy(uint256 amount) external payable {
         require(amount > 0, "Amount must be greater than 0");
         uint256 ethCost = amount / 100; // Example: 1 ETH per 100 entropy
         require(msg.value >= ethCost, "Not enough ETH sent to extract entropy");

         // Excess ETH is sent back (or handled differently)
         if (msg.value > ethCost) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - ethCost}("");
             require(success, "Failed to return excess ETH");
         }

         require(entropyPool >= amount, "Not enough global entropy to extract");
         entropyPool -= amount;

         emit EntropyExtracted(amount, msg.sender);
    }


    /**
     * @dev Applies a "Chroniton" value to a particle, simulating time-based persistence
     * or inertia, resisting state changes for a duration. Costs 8 entropy.
     * @param particleId The ID of the particle.
     * @param duration The duration in seconds for the chroniton effect.
     */
    function applyChroniton(uint256 particleId, uint256 duration) external particleExists(particleId) notCausalityLocked(particleId) {
        require(duration > 0, "Duration must be greater than 0");
         require(entropyPool >= 8, "Not enough global entropy to apply chroniton");
        entropyPool -= 8;

        // Simple add - could be max(), or weighted average etc.
        chronitons[particleId] += duration;
        particles[particleId].flags |= 4; // Set RequiresChroniton flag

        emit ChronitonApplied(particleId, duration);
    }

     /**
      * @dev Explicitly decays the Chroniton value of a particle.
      * Can also decay implicitly during state transitions over time.
      * Costs 2 entropy.
      * @param particleId The ID of the particle.
      */
    function decayChroniton(uint256 particleId) external particleExists(particleId) notCausalityLocked(particleId) {
         require(chronitons[particleId] > 0, "No chroniton to decay");
         require(entropyPool >= 2, "Not enough global entropy for chroniton decay");
         entropyPool -= 2;

         // Simple linear decay
         uint256 decayAmount = chronitons[particleId] / 2 > 1 ? chronitons[particleId] / 2 : 1; // Decay at least 1
         chronitons[particleId] -= decayAmount;

         if (chronitons[particleId] == 0) {
             particles[particleId].flags &= ~4; // Clear RequiresChroniton flag
         }

         emit ChronitonDecayed(particleId, chronitons[particleId]);
    }


    /**
     * @dev Schedules a specific state change effect to occur on a particle at a future time.
     * Only one delayed effect can be pending per particle at a time.
     * Costs 12 entropy.
     * @param particleId The ID of the particle.
     * @param effectType The type of delayed effect.
     * @param delayInSeconds The duration until the effect triggers.
     * @param data Optional additional data for the effect.
     */
    function triggerDelayedEffect(uint256 particleId, DelayedEffectType effectType, uint256 delayInSeconds, bytes calldata data) external particleExists(particleId) notCausalityLocked(particleId) {
        require(!delayedEffects[particleId].exists, "Particle already has a pending delayed effect");
        require(delayInSeconds > 0, "Delay must be greater than 0");
        require(entropyPool >= 12, "Not enough global entropy to trigger delayed effect");
        entropyPool -= 12;

        delayedEffects[particleId] = DelayedEffect({
            targetParticleId: particleId,
            effectType: effectType,
            triggerTime: uint64(block.timestamp + delayInSeconds),
            data: data,
            exists: true
        });

        emit DelayedEffectTriggered(particleId, effectType, delayedEffects[particleId].triggerTime);
    }

    /**
     * @dev Function called (potentially by a relayer or keeper) to execute a scheduled
     * delayed effect if its trigger time has passed. Costs 1 entropy.
     * @param particleId The ID of the particle with the pending effect.
     */
    function processDelayedEffect(uint256 particleId) external particleExists(particleId) notCausalityLocked(particleId) {
        DelayedEffect storage effect = delayedEffects[particleId];
        require(effect.exists, "No pending delayed effect for this particle");
        require(block.timestamp >= effect.triggerTime, "Delayed effect trigger time has not passed");
        require(entropyPool >= 1, "Not enough global entropy to process delayed effect");
        entropyPool -= 1;

        // Apply the effect based on its type (simplified logic)
        Particle storage particle = particles[particleId];
        ParticleState oldState = particle.currentState;

        if (effect.effectType == DelayedEffectType.StateTransitionToCoherent) {
             if (particle.currentState != ParticleState.Collapsed && particle.currentState != ParticleState.Entangled) {
                particle.currentState = ParticleState.Coherent;
             }
        } else if (effect.effectType == DelayedEffectType.StateTransitionToDecoherent) {
             if (particle.currentState != ParticleState.Collapsed && particle.currentState != ParticleState.Entangled) {
                particle.currentState = ParticleState.Decoherent;
             }
        } else if (effect.effectType == DelayedEffectType.IncreaseEntropy) {
             particle.entropyLevel += uint256(bytes1(effect.data)); // Example: treat first byte of data as entropy increase
        } else if (effect.effectType == DelayedEffectType.DissipateChroniton) {
             chronitons[particleId] = chronitons[particleId] / 2; // Halve chroniton
             if (chronitons[particleId] == 0) particle.flags &= ~4;
             emit ChronitonDecayed(particleId, chronitons[particleId]); // Emit decay event
        } else if (effect.effectType == DelayedEffectType.ScrambleAttestations) {
            // This would require iterating attestations, which is complex/costly on-chain.
            // Simplified: just reduce total weight.
            particle.attestationWeight = particle.attestationWeight / 4; // Reduce total weight significantly
        }

        delete delayedEffects[particleId]; // Remove the processed effect

        emit DelayedEffectProcessed(particleId, effect.effectType);
        if (particle.currentState != oldState) {
             emit ParticleStateChanged(particleId, particle.currentState, oldState);
        }
    }


    /**
     * @dev A general function to advance the particle's state based on time elapsed,
     * current entropy level, attestation influence, chroniton, and internal rules.
     * Can trigger probabilistic state changes. Costs 3 entropy.
     * @param particleId The ID of the particle.
     */
    function evolveParticle(uint256 particleId) external particleExists(particleId) notCausalityLocked(particleId) {
        require(entropyPool >= 3, "Not enough global entropy for evolution");
        entropyPool -= 3;

        Particle storage particle = particles[particleId];
        ParticleState oldState = particle.currentState;

        _evolveParticleState(particle);

        emit ParticleEvolved(particleId, particle.currentState);
        if (particle.currentState != oldState) {
             emit ParticleStateChanged(particleId, particle.currentState, oldState);
        }
    }

     /**
      * @dev Internal helper function for particle state evolution logic.
      * @param particle The particle struct storage reference.
      */
     function _evolveParticleState(Particle storage particle) internal {
        if (particle.currentState == ParticleState.Collapsed || particle.currentState == ParticleState.Entangled) {
            // Collapsed and Entangled states are generally stable until acted upon directly
            // Unless entanglement is broken externally, or observation triggers collapse resolution
            return;
        }

        uint64 timeElapsed = uint64(block.timestamp) - particle.lastInteractionTime;
        uint256 evolutionFactor = timeElapsed + particle.entropyLevel + (entropyPool / 100); // Influence from time, internal, global entropy

        // Adjust factor based on Chroniton
        if (chronitons[particle.id] > 0) {
            uint256 effectiveChroniton = chronitons[particle.id];
            // Decay chroniton based on time elapsed
            if (effectiveChroniton > timeElapsed) {
                chronitons[particle.id] -= timeElapsed;
            } else {
                chronitons[particle.id] = 0;
                 particle.flags &= ~4; // Clear RequiresChroniton flag
            }
             emit ChronitonDecayed(particle.id, chronitons[particle.id]);
            // Chroniton reduces evolution factor (makes it more stable)
            evolutionFactor = evolutionFactor > effectiveChroniton ? evolutionFactor - effectiveChroniton : 0;
        }


        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, particle.id, evolutionFactor)));

        // Simplified probabilistic state changes based on evolutionFactor and current state
        if (evolutionFactor > 100 && seed % 10 < 7) { // High chance of change if high factor
            if (particle.currentState == ParticleState.Undetermined) {
                 particle.currentState = ParticleState.Decoherent; // Undetermined tends to become Decoherent
            } else if (particle.currentState == ParticleState.Decoherent) {
                 // Decoherent can become Coherent, Undetermined, or even collapse (small chance)
                 uint256 innerSeed = uint256(keccak256(abi.encodePacked(seed, particle.attestationWeight)));
                 if (innerSeed % 3 == 0) particle.currentState = ParticleState.Coherent;
                 else if (innerSeed % 3 == 1) particle.currentState = ParticleState.Undetermined;
                 else { /* state remains Decoherent */ }
            } else if (particle.currentState == ParticleState.Coherent) {
                 // Coherent can become Decoherent under high stress/time
                 particle.currentState = ParticleState.Decoherent;
            }
        } else if (evolutionFactor < 50 && seed % 10 < 3) { // Low factor, bias towards stability (Coherent)
            if (particle.currentState != ParticleState.Coherent && particle.currentState != ParticleState.Collapsed) {
                particle.currentState = ParticleState.Coherent;
            }
        }
        // Other evolution rules can be added

        particle.lastInteractionTime = uint64(block.timestamp);
     }


    /**
     * @dev Transfers ownership of a particle. Requires particle to be in a 'transferable' state (e.g., not Entangled or Collapsed).
     * Similar to ERC-721 transferFrom. Costs 7 entropy.
     * @param recipient The address to transfer the particle to.
     * @param particleId The ID of the particle to transfer.
     */
    function transferParticle(address recipient, uint256 particleId) external particleExists(particleId) {
        require(recipient != address(0), "Cannot transfer to zero address");
        Particle storage particle = particles[particleId];
        require(msg.sender == particle.owner, "Caller is not the particle owner");
        require(particle.currentState != ParticleState.Entangled, "Cannot transfer an entangled particle");
         require(particle.currentState != ParticleState.Collapsed, "Cannot transfer a collapsed particle"); // Maybe allow collapsed? Decide game rules. Let's disallow for complexity.

        require(entropyPool >= 7, "Not enough global entropy for transfer");
        entropyPool -= 7;

        address oldOwner = particle.owner;
        particle.owner = recipient;

        emit ParticleTransferred(particleId, oldOwner, recipient);
    }

    // --- Getter Functions ---

    /**
     * @dev Reads the current simulated state of a particle.
     * @param particleId The ID of the particle.
     * @return The current ParticleState.
     */
    function getParticleState(uint256 particleId) external view particleExists(particleId) returns (ParticleState) {
        return particles[particleId].currentState;
    }

    /**
     * @dev Reads all details of a specific particle.
     * @param particleId The ID of the particle.
     * @return A tuple containing particle properties.
     */
    function getParticleDetails(uint256 particleId) external view particleExists(particleId) returns (
        uint256 id,
        address owner,
        ParticleState currentState,
        uint256 entropyLevel,
        uint64 lastInteractionTime,
        uint256 linkedParticleId,
        uint256 attestationWeight,
        uint256 flags,
        uint64 causalityLockUntil
    ) {
        Particle storage particle = particles[particleId];
        return (
            particle.id,
            particle.owner,
            particle.currentState,
            particle.entropyLevel,
            particle.lastInteractionTime,
            particle.linkedParticleId,
            particle.attestationWeight,
            particle.flags,
            particle.causalityLockUntil
        );
    }

    /**
     * @dev Reads the current global entropy pool value.
     * @return The current entropy pool amount.
     */
    function getEntropyPool() external view returns (uint256) {
        return entropyPool;
    }

    /**
     * @dev Reads the attestation weight provided by a specific address for a particle.
     * @param particleId The ID of the particle.
     * @param attester The address whose attestation weight to check.
     * @return The attestation weight (0 if no attestation).
     */
    function getAttestationWeight(uint256 particleId, address attester) external view particleExists(particleId) returns (uint8) {
        return particleAttestations[particleId][attester];
    }

    /**
     * @dev Reads details of a pending delayed effect for a particle.
     * @param particleId The ID of the particle.
     * @return A tuple containing delayed effect details, and a boolean indicating existence.
     */
    function getDelayedEffect(uint256 particleId) external view particleExists(particleId) returns (DelayedEffectType effectType, uint64 triggerTime, bytes memory data, bool exists) {
        DelayedEffect storage effect = delayedEffects[particleId];
        return (effect.effectType, effect.triggerTime, effect.data, effect.exists);
    }

    // --- Advanced/Conceptual Functionality ---

     /**
      * @dev Pure function predicting the *potential* state outcome if `observeParticle`
      * were called now. Does not change state. Uses a simulated snapshot of current conditions.
      * This is for demonstration/simulation of prediction, not a guarantee.
      * @param particleId The ID of the particle.
      * @return The predicted potential state if observed.
      */
    function simulateObservationOutcome(uint256 particleId) external view particleExists(particleId) returns (ParticleState potentialState) {
        Particle storage particle = particles[particleId];
        require(particle.currentState == ParticleState.Undetermined || particle.currentState == ParticleState.Decoherent, "Particle state is not suitable for simulated observation");
        require(particle.currentState != ParticleState.Collapsed, "Particle state is already collapsed");
        require(particle.currentState != ParticleState.Entangled, "Cannot simulate observation on an entangled particle directly");


        // Simulation uses a deterministic seed based on current view state/block data
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, particleId, entropyPool, particle.entropyLevel)));

        uint256 outcomeFactor = (seed % 1000) + particle.attestationWeight - (entropyPool / 100) - (particle.entropyLevel * 10);

        if (outcomeFactor >= 500) {
            potentialState = ParticleState.Coherent;
        } else if (outcomeFactor >= 200) {
             if (seed % 2 == 0) { potentialState = ParticleState.Coherent; } else { potentialState = ParticleState.Decoherent; }
        }
         else {
            potentialState = ParticleState.Decoherent;
        }

        // Add a chance to predict Collapsed based on current Decoherent state or high attestation
        if ((particle.currentState == ParticleState.Decoherent && (seed % 5 < 2)) || (particle.attestationWeight > 100 && (seed % 10 < 3))) {
             potentialState = ParticleState.Collapsed;
        }

        return potentialState;
    }

    /**
     * @dev If a particle is entangled and its state is observed/collapsed externally,
     * this function can be called to potentially resolve the state of the linked
     * particle based on entanglement rules (e.g., opposite state, same state probabilistically).
     * Costs 10 entropy.
     * @param particleId The ID of the particle whose entangled link needs resolving.
     */
    function resolveEntangledState(uint256 particleId) external particleExists(particleId) notCausalityLocked(particleId) {
        Particle storage p = particles[particleId];
        require(p.currentState == ParticleState.Entangled, "Particle is not entangled");
        require(p.linkedParticleId != 0 && particles[p.linkedParticleId].id != 0 && particles[p.linkedParticleId].currentState == ParticleState.Entangled, "Linked particle invalid or not entangled");
         require(entropyPool >= 10, "Not enough global entropy for entanglement resolution");
        entropyPool -= 10;

        uint256 linkedId = p.linkedParticleId;
        Particle storage linkedP = particles[linkedId];

        // --- Simplified Entanglement Resolution Logic ---
        // If this particle collapsed, influence the linked one
        ParticleState oldStateLinked = linkedP.currentState;
        if ((p.flags & 1) == 1) { // Check if particle was observed/collapsed (IsObserved flag)
             // Example rule: Linked particle collapses to opposite state (if Coherent/Decoherent is 'opposite')
             // Or maybe probabilistic based on attestation/entropy
             uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, particleId, linkedId, entropyPool)));

             if (seed % 2 == 0) {
                 linkedP.currentState = ParticleState.Decoherent; // Bias towards chaos on linked particle
             } else {
                 linkedP.currentState = ParticleState.Coherent; // Bias towards order
             }
             linkedP.flags |= 1; // The act of resolving might observe the linked one too
             linkedP.lastInteractionTime = uint64(block.timestamp);
             dissipateEntanglement(particleId); // Resolving often breaks entanglement
             // Note: dissipateEntanglement will also call for linkedId if valid, preventing need to call it twice
         } else {
             // If the particle wasn't observed/collapsed but this is called, maybe it's just a disturbance?
             // Slightly increase entropy of both, maybe push linked towards Decoherent
             p.entropyLevel += 1;
             linkedP.entropyLevel += 2;
             if (linkedP.entropyLevel > 6 && linkedP.currentState != ParticleState.Collapsed) {
                 linkedP.currentState = ParticleState.Decoherent;
             }
         }

         if (linkedP.currentState != oldStateLinked) {
             emit ParticleStateChanged(linkedId, linkedP.currentState, oldStateLinked);
         }
    }

    /**
     * @dev Applies a temporary lock preventing certain state changes for a duration,
     * simulating a localized 'causality lock' or stability field. Costs 20 entropy.
     * @param particleId The ID of the particle.
     * @param lockDuration The duration in seconds for the lock.
     */
    function setCausalityLock(uint256 particleId, uint256 lockDuration) external particleExists(particleId) notCausalityLocked(particleId) {
        require(lockDuration > 0, "Lock duration must be greater than 0");
        require(entropyPool >= 20, "Not enough global entropy to apply causality lock");
        entropyPool -= 20;

        uint64 lockUntil = uint64(block.timestamp + lockDuration);
        particles[particleId].causalityLockUntil = lockUntil;

        emit CausalityLockApplied(particleId, lockUntil);
    }

    /**
     * @dev Checks if a particle is currently under a causality lock and returns the
     * timestamp until the lock expires (0 if not locked or expired).
     * @param particleId The ID of the particle.
     * @return The timestamp until the causality lock expires.
     */
    function checkCausalityLock(uint256 particleId) external view particleExists(particleId) returns (uint64) {
        uint64 lockUntil = particles[particleId].causalityLockUntil;
        if (lockUntil > block.timestamp) {
            return lockUntil;
        } else {
            return 0;
        }
    }

    /**
     * @dev Simulates scrambling/redistributing a portion of the global entropy
     * internally within the system based on a factor. Can affect individual particle
     * entropy levels or global entropy distribution. Costs `factor` entropy.
     * @param factor The factor influencing the scrambling magnitude.
     */
    function scrambleEntropy(uint256 factor) external {
        require(factor > 0, "Factor must be greater than 0");
        require(entropyPool >= factor, "Not enough global entropy to scramble");
        entropyPool -= factor; // Cost is the factor itself

        // --- Simplified Scrambling Logic ---
        // Distribute some entropy randomly back into a few particles
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, factor)));
        uint256 numParticles = nextParticleId - 1;
        if (numParticles > 0) {
             uint256 distributionAmount = factor / 2; // Only redistribute half the cost
             uint256 particlesToAffect = seed % (numParticles > 5 ? 5 : numParticles + 1); // Affect up to 5 random particles

             for (uint i = 0; i < particlesToAffect; i++) {
                 uint256 targetParticleId = (seed + i) % numParticles + 1; // Simple pseudorandom particle selection
                 if (particles[targetParticleId].id != 0) {
                     particles[targetParticleId].entropyLevel += distributionAmount / (particlesToAffect > 0 ? particlesToAffect : 1);
                 }
             }
        }
         // The other half of the factor is just 'lost' or dissipated in the scramble

        emit EntropyScrambled(factor);
    }

    /**
     * @dev Attempts to measure how "coherent" a particle's state is (i.e., how close
     * it is to collapsing or becoming unstable). Returns a simplified score based on
     * its state, internal entropy, chroniton, and global entropy.
     * @param particleId The ID of the particle.
     * @return A coherence score (higher = more stable/less likely to spontaneously change/collapse).
     */
    function measureParticleCoherence(uint256 particleId) external view particleExists(particleId) returns (uint256 coherenceScore) {
        Particle storage particle = particles[particleId];

        // --- Simplified Coherence Score Calculation ---
        // Collapsed state is 1000 (most coherent/stable in its fixed state)
        // Coherent state starts high, reduced by entropy
        // Undetermined/Decoherent states are low, increased by chroniton and attestation
        // Entangled state has variable coherence depending on linked particle? (Too complex for simple score)

        if (particle.currentState == ParticleState.Collapsed) {
            coherenceScore = 1000;
        } else if (particle.currentState == ParticleState.Entangled) {
             // Coherence of entangled state is complex - let's give it a baseline + linked influence (if exists)
             coherenceScore = 500;
             if (particle.linkedParticleId != 0 && particles[particle.linkedParticleId].id != 0) {
                 // Add/subtract based on linked particle's coherence (recursive or simplified)
                 // Avoid deep recursion by just using linked particle's entropy/state basics
                 Particle storage linkedP = particles[particle.linkedParticleId];
                 if (linkedP.currentState == ParticleState.Collapsed) coherenceScore += 200;
                 else if (linkedP.currentState == ParticleState.Decoherent) coherenceScore -= 100;
                 // Add linked particle's chroniton influence
                 coherenceScore += chronitons[linkedP.id] / 100; // Scale down large chroniton values
             }
             // Entangled coherence is also reduced by high global entropy
             coherenceScore = entropyPool < 1000 ? coherenceScore * (1000 - entropyPool) / 1000 : 0;

        } else if (particle.currentState == ParticleState.Coherent) {
            coherenceScore = 800;
            // Reduced by internal and global entropy
            coherenceScore = coherenceScore > particle.entropyLevel * 10 ? coherenceScore - particle.entropyLevel * 10 : 0;
            coherenceScore = entropyPool < 80000 ? coherenceScore * (80000 - entropyPool) / 80000 : 0;
        } else { // Undetermined, Decoherent
            coherenceScore = 200; // Low baseline
            // Increased by chroniton and attestation
            coherenceScore += chronitons[particleId] / 50;
            coherenceScore += particle.attestationWeight * 2;
            // Reduced by internal and global entropy
             coherenceScore = coherenceScore > particle.entropyLevel * 20 ? coherenceScore - particle.entropyLevel * 20 : 0;
             coherenceScore = entropyPool < 50000 ? coherenceScore * (50000 - entropyPool) / 50000 : 0;
        }

        // Ensure score is within a reasonable range (e.g., 0-1000)
        coherenceScore = coherenceScore > 1000 ? 1000 : coherenceScore;

        emit ParticleCoherenceMeasured(particleId, coherenceScore); // Emit for transparency
        return coherenceScore;
    }


    /**
     * @dev Simulates an external force acting on a particle, potentially increasing
     * its internal entropy level or triggering a state change based on the magnitude.
     * The cost of the operation is equal to the fluctuation magnitude.
     * @param particleId The ID of the particle.
     * @param fluctuationMagnitude The strength of the external fluctuation.
     */
    function applyExternalFluctuation(uint256 particleId, uint256 fluctuationMagnitude) external particleExists(particleId) notCausalityLocked(particleId) {
        require(fluctuationMagnitude > 0, "Fluctuation magnitude must be greater than 0");
        require(entropyPool >= fluctuationMagnitude, "Not enough global entropy to absorb fluctuation cost");
        entropyPool -= fluctuationMagnitude; // Cost is the fluctuation itself

        Particle storage particle = particles[particleId];
        ParticleState oldState = particle.currentState;

        // --- Simplified Fluctuation Effect Logic ---
        // High fluctuation significantly increases internal entropy
        particle.entropyLevel += fluctuationMagnitude / 10; // Scale down magnitude for entropy effect

        // High fluctuation might push towards Decoherent or trigger evolution
        if (fluctuationMagnitude > 50 && particle.currentState != ParticleState.Collapsed && particle.currentState != ParticleState.Entangled) {
             uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, particleId, fluctuationMagnitude)));
             if (seed % 3 < 2) { // High chance
                 particle.currentState = ParticleState.Decoherent;
             }
             // Also trigger general evolution logic
             _evolveParticleState(particle);
        } else if (fluctuationMagnitude > 10 && particle.currentState != ParticleState.Collapsed && particle.currentState != ParticleState.Entangled) {
             // Lower fluctuation just adds entropy and slightly influences evolution
             _evolveParticleState(particle);
        }
        // Fluctuation on Collapsed/Entangled might subtly increase internal entropy or add Chronitons (resistance)

        particle.lastInteractionTime = uint64(block.timestamp);

        emit ExternalFluctuationApplied(particleId, fluctuationMagnitude);
        if (particle.currentState != oldState) {
             emit ParticleStateChanged(particleId, particle.currentState, oldState);
        }
    }

    // Fallback and Receive to accept ETH for extraction cost
    receive() external payable {}
    fallback() external payable {}

}
```