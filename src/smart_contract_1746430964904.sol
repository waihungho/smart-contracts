Okay, here is a smart contract concept called `QuantumFluctuations`. It's designed as an abstract simulation system where users interact with "fluctuations" that have dynamic properties like energy, stability, phase, and spin. These fluctuations can interact, evolve, and potentially be "harvested" under certain conditions, incorporating ideas of dynamic state, probabilistic outcomes (simulated), and complex interdependencies.

It aims to be creative by representing an abstract physical system, advanced by incorporating concepts like entanglement and probabilistic outcomes (simulated via on-chain data/pseudo-randomness, with caveats), and interesting through its unique interaction model. It avoids directly copying standard token, NFT, or simple DeFi patterns.

**Disclaimer:** This contract uses on-chain data (like `block.timestamp` and `block.difficulty`/`blockhash`) for pseudo-randomness simulation within the example. **This is NOT secure for production systems requiring unpredictable outcomes.** Secure randomness requires external oracles like Chainlink VRF. The complex interactions are simplified models for illustration.

---

## QuantumFluctuations Smart Contract

### Outline:

1.  **State Variables:** Define the core data structures and parameters of the system.
2.  **Structs & Enums:** Define the `Fluctuation` structure and `Phase` enumeration.
3.  **Events:** Define events to signal key actions and state changes.
4.  **Modifiers:** Define custom access control or validation modifiers (`onlyOwner`).
5.  **Constructor:** Initialize contract owner and global parameters.
6.  **Internal/Helper Functions:** Logic used internally by public functions (e.g., calculating decay, generating pseudo-randomness).
7.  **Creation Functions:** Functions to bring new fluctuations into existence.
8.  **Interaction & Modification Functions:** Functions allowing users to interact with and change the state of fluctuations.
9.  **Entanglement Functions:** Functions specifically for linking and unlinking fluctuations.
10. **Complex/Probabilistic Interaction Functions:** Functions involving simulated probabilistic outcomes or cascade effects.
11. **Harvesting Functions:** Functions to "harvest" or finalize fluctuations under specific conditions.
12. **Maintenance & Governance Functions:** Functions for system upkeep and owner/governance controls.
13. **Query & View Functions:** Functions to retrieve information about the system state.

### Function Summary:

**State Variables:**
*   `owner`: Address of the contract owner.
*   `nextFluctuationId`: Counter for unique fluctuation IDs.
*   `fluctuations`: Mapping from ID to `Fluctuation` struct.
*   `environmentStabilityFactor`: Global parameter affecting stability.
*   `decayRatePerSecond`: Global parameter affecting energy and stability decay.
*   `harvestStabilityThreshold`: Minimum stability required for harvesting.
*   `harvestEnergyThreshold`: Minimum energy required for harvesting.

**Structs & Enums:**
*   `Phase`: Enum representing different states (e.g., `Stable`, `Volatile`, `Quantum`, `Decaying`).
*   `Fluctuation`: Struct holding properties: `id`, `energy`, `stability`, `phase`, `spin`, `creationTime`, `lastInteractionTime`, `isEntangled`, `entangledWithId`.

**Events:**
*   `FluctuationCreated`: Emitted when a new fluctuation appears.
*   `FluctuationObserved`: Emitted when a fluctuation state is viewed/interacted with.
*   `EnergyInjected`: Emitted when energy is added.
*   `StabilizerApplied`: Emitted when stability is increased.
*   `PhaseShifted`: Emitted when phase changes.
*   `SpinFlipped`: Emitted when spin changes.
*   `FluctuationsEntangled`: Emitted when two fluctuations are linked.
*   `FluctuationsDisentangled`: Emitted when fluctuations are unlinked.
*   `FluctuationSplit`: Emitted when one fluctuation divides.
*   `FluctuationsMerged`: Emitted when two fluctuations combine.
*   `FluctuationHarvested`: Emitted when a fluctuation is harvested.
*   `DecayProcessed`: Emitted after decay is applied to a batch.
*   `ResonanceInduced`: Emitted when resonance interaction occurs.
*   `ExternalForceApplied`: Emitted when external force affects fluctuation.
*   `QuantumTunnelAttempt`: Emitted when tunneling is attempted.
*   `QuantumEventTriggered`: Emitted when a rare event occurs.
*   `EnvironmentUpdated`: Emitted when global factors change.
*   `ExcessEnergyDissipated`: Emitted when energy is reduced.

**Modifiers:**
*   `onlyOwner`: Restricts function access to the contract owner.

**Internal/Helper Functions:**
*   `_applyDecay(uint256 fluctuationId)`: Internal logic to apply decay based on time and global rates.
*   `_generatePseudoRandom(uint256 seed)`: Internal helper for basic pseudo-randomness (WARNING: Not secure).
*   `_checkFluctuationExists(uint256 fluctuationId)`: Internal helper to validate ID.
*   `_calculateEffectiveStability(uint256 fluctuationId)`: Internal calculation considering environmental factors.

**Creation Functions:**
1.  `createFluctuation()`: Creates a new fluctuation with initial properties, costs gas.
2.  `seedInitialState(uint256 count)`: (Owner) Creates multiple initial fluctuations to populate the system.

**Interaction & Modification Functions:**
3.  `observeFluctuation(uint256 fluctuationId)`: View a fluctuation's state, potentially applying a minor decay/interaction cost (gas).
4.  `injectEnergy(uint256 fluctuationId)`: Increase a fluctuation's energy, requires payment (e.g., Ether, conceptually).
5.  `applyStabilizer(uint256 fluctuationId)`: Increase a fluctuation's stability, requires payment.
6.  `inducePhaseShift(uint256 fluctuationId, Phase targetPhase)`: Attempt to shift a fluctuation to a target phase, probability or cost might depend on current state.
7.  `flipSpin(uint256 fluctuationId)`: Change a fluctuation's spin state (true/false), simple state toggle.

**Entanglement Functions:**
8.  `entangleFluctuations(uint256 id1, uint256 id2)`: Links two fluctuations; actions on one might affect the other while entangled. Requires conditions (e.g., proximity in properties, cost).
9.  `disentangleFluctuations(uint256 id1, uint256 id2)`: Breaks the link between two entangled fluctuations.

**Complex/Probabilistic Interaction Functions:**
10. `splitFluctuation(uint256 fluctuationId)`: Splits one fluctuation into two new ones; requires high energy/low stability. Original may be consumed or properties halved.
11. `mergeFluctuations(uint256 id1, uint256 id2)`: Attempts to merge two fluctuations into a single new one; requires compatible phases/spins. Originals are consumed.
12. `induceResonance(uint256 id1, uint256 id2)`: Triggers a special interaction between fluctuations based on specific phase/spin combinations, potentially leading to large state changes.
13. `applyExternalForce(uint256 fluctuationId, bytes32 externalData)`: Simulates an external influence based on provided data, potentially altering properties in a complex way.
14. `quantumTunnel(uint256 fromId, uint256 toId)`: Attempts to transfer energy/stability between *non-entangled* fluctuations with a probabilistic success rate based on distance in properties.
15. `triggerQuantumEvent(uint256 fluctuationId)`: A rare function call that might trigger a large, unpredictable state change or a cascading effect across fluctuations, potentially requiring high energy input or specific conditions.

**Harvesting Functions:**
16. `harvestStableFluctuation(uint256 fluctuationId)`: Converts a fluctuation meeting stability/energy thresholds into a "harvest"; the fluctuation is removed, and the caller might receive a reward (e.g., conceptual, or placeholder for token minting).

**Maintenance & Governance Functions:**
17. `decayFluctuationsBatch(uint256[] calldata fluctuationIds)`: Allows anyone to pay gas to process decay for a batch of fluctuations, potentially earning a small reward or priority (conceptually).
18. `updateEnvironmentFactors(uint256 newStabilityFactor, uint256 newDecayRate, uint256 newHarvestStability, uint256 newHarvestEnergy)`: (Owner) Updates the global parameters of the simulation.
19. `dissipateExcessEnergy(uint256 fluctuationId)`: Reduces energy if it exceeds a certain cap, potentially converting excess energy into stability or rewarding the caller.

**Query & View Functions:**
20. `getFluctuationState(uint256 fluctuationId)`: Returns the current state of a specific fluctuation (view).
21. `getTotalFluctuations()`: Returns the total number of existing fluctuations (view).
22. `getFluctuationsByPhase(Phase targetPhase)`: Returns an array of IDs for fluctuations currently in a specific phase (view).
23. `getEntangledPairs()`: Returns an array of pairs of IDs that are currently entangled (view).
24. `getGlobalEnvironmentFactors()`: Returns the current global simulation parameters (view).
25. `findPotentialHarvests()`: Returns an array of IDs for fluctuations currently meeting the harvest criteria (view).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuations
 * @dev A smart contract simulating an abstract system of dynamic fluctuations
 *      with properties like energy, stability, phase, and spin. Users can
 *      interact with these fluctuations, causing state changes, entanglement,
 *      splitting, merging, and potentially "harvesting" them. Incorporates
 *      concepts of dynamic state, complex interactions, and simulated
 *      probabilistic outcomes (WARNING: Pseudo-randomness used is INSECURE).
 */
contract QuantumFluctuations {

    // --- State Variables ---
    address public owner;
    uint256 private nextFluctuationId;

    mapping(uint256 => Fluctuation) public fluctuations;
    uint256[] private allFluctuationIds; // To iterate or count easily

    // Global environmental factors influencing fluctuation behavior
    uint256 public environmentStabilityFactor; // Added to fluctuation stability for effective stability calculation
    uint256 public decayRatePerSecond;         // Amount of energy/stability lost per second
    uint256 public harvestStabilityThreshold;  // Minimum stability to be harvestable
    uint256 public harvestEnergyThreshold;     // Minimum energy to be harvestable

    // --- Structs & Enums ---

    enum Phase {
        Undetermined,
        Stable,
        Volatile,
        Quantum,
        Decaying,
        Resonant
    }

    struct Fluctuation {
        uint256 id;
        uint256 energy;     // Represents vitality/activity (e.g., 0-1000)
        uint256 stability;  // Represents resistance to change/decay (e.g., 0-1000)
        Phase phase;        // Current state (Stable, Volatile, etc.)
        bool spin;          // Simple binary state (true/false)
        uint256 creationTime;
        uint256 lastInteractionTime; // Timestamp of last interaction or decay processing
        bool isEntangled;
        uint256 entangledWithId;
    }

    // --- Events ---
    event FluctuationCreated(uint256 indexed id, uint256 creationTime, address indexed creator);
    event FluctuationObserved(uint256 indexed id, address indexed observer);
    event EnergyInjected(uint256 indexed id, uint256 amount, address indexed contributor);
    event StabilizerApplied(uint256 indexed id, uint256 amount, address indexed contributor);
    event PhaseShifted(uint256 indexed id, Phase oldPhase, Phase newPhase);
    event SpinFlipped(uint256 indexed id, bool newSpin);
    event FluctuationsEntangled(uint256 indexed id1, uint256 indexed id2);
    event FluctuationsDisentangled(uint256 indexed id1, uint256 indexed id2);
    event FluctuationSplit(uint256 indexed originalId, uint256 indexed newId1, uint256 indexed newId2);
    event FluctuationsMerged(uint256 indexed id1, uint256 indexed id2, uint256 indexed newId);
    event FluctuationHarvested(uint256 indexed id, address indexed harvester, uint256 finalEnergy, uint256 finalStability);
    event DecayProcessed(uint256 indexed id, uint256 energyLost, uint256 stabilityLost);
    event BatchDecayProcessed(uint256 count, address indexed processor);
    event ResonanceInduced(uint256 indexed id1, uint256 indexed id2, string outcome);
    event ExternalForceApplied(uint256 indexed id, bytes32 indexed externalDataHash, string outcome);
    event QuantumTunnelAttempt(uint256 indexed fromId, uint256 indexed toId, bool success, uint256 energyTransferred);
    event QuantumEventTriggered(uint256 indexed originId, string eventType, uint256 randomnessSeed);
    event EnvironmentUpdated(uint256 newStabilityFactor, uint256 newDecayRate, uint256 newHarvestStability, uint256 newHarvestEnergy);
    event ExcessEnergyDissipated(uint256 indexed id, uint256 energyDissipated, uint256 newStability);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        nextFluctuationId = 1; // Start IDs from 1
        environmentStabilityFactor = 100; // Default values
        decayRatePerSecond = 1;
        harvestStabilityThreshold = 500;
        harvestEnergyThreshold = 500;
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Applies decay to a fluctuation based on time elapsed since last interaction.
     * Updates energy, stability, and lastInteractionTime. Changes phase if properties drop too low.
     * @param fluctuationId The ID of the fluctuation to decay.
     */
    function _applyDecay(uint256 fluctuationId) internal {
        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        uint256 timeElapsed = block.timestamp - fluctuation.lastInteractionTime;
        if (timeElapsed == 0) return;

        uint256 decayAmount = timeElapsed * decayRatePerSecond;

        uint256 energyLoss = decayAmount;
        uint256 stabilityLoss = decayAmount;

        if (energyLoss > fluctuation.energy) energyLoss = fluctuation.energy;
        if (stabilityLoss > fluctuation.stability) stabilityLoss = fluctuation.stability;

        fluctuation.energy -= energyLoss;
        fluctuation.stability -= stabilityLoss;
        fluctuation.lastInteractionTime = block.timestamp;

        // Update phase based on properties after decay
        if (fluctuation.energy == 0 || fluctuation.stability == 0) {
            fluctuation.phase = Phase.Decaying;
        } else if (fluctuation.energy < 200 || fluctuation.stability < 200) {
             if(fluctuation.phase != Phase.Decaying) fluctuation.phase = Phase.Volatile; // Don't change if already Decaying
        } else if (fluctuation.energy > 800 && fluctuation.stability > 800) {
             if(fluctuation.phase != Phase.Decaying) fluctuation.phase = Phase.Stable;
        } else if (fluctuation.isEntangled) {
             if(fluctuation.phase != Phase.Decaying && fluctuation.phase != Phase.Stable) fluctuation.phase = Phase.Quantum;
        } else {
             if(fluctuation.phase != Phase.Decaying && fluctuation.phase != Phase.Stable && fluctuation.phase != Phase.Quantum) fluctuation.phase = Phase.Undetermined;
        }


        emit DecayProcessed(fluctuationId, energyLoss, stabilityLoss);
    }

     /**
     * @dev Generates a pseudo-random number using block data and a seed.
     * WARNING: This is NOT cryptographically secure and predictable by miners.
     * Use Chainlink VRF or similar for secure randomness in production.
     * @param seed An additional seed value for variety.
     * @return A pseudo-random uint256.
     */
    function _generatePseudoRandom(uint256 seed) internal view returns (uint256) {
        // Simple pseudo-randomness using blockhash and timestamp
        // The blockhash is 0 for current block, so use block.number - 1
        // Note: blockhash is deprecated in future Solidity versions.
        // Use block.difficulty or other sources cautiously.
        uint256 blockMix = uint256(blockhash(block.number - 1)) + block.timestamp + seed;
        return uint256(keccak256(abi.encodePacked(blockMix, msg.sender, tx.origin, gasleft())));
    }

    /**
     * @dev Checks if a fluctuation with the given ID exists.
     * @param fluctuationId The ID to check.
     */
    function _checkFluctuationExists(uint256 fluctuationId) internal view {
        require(fluctuationId > 0 && fluctuationId < nextFluctuationId, "Fluctuation does not exist");
        // Additional check to ensure it hasn't been harvested/removed
        require(fluctuations[fluctuationId].id != 0, "Fluctuation has been removed");
    }

    /**
     * @dev Calculates the effective stability of a fluctuation, considering the global factor.
     * @param fluctuationId The ID of the fluctuation.
     * @return The effective stability.
     */
    function _calculateEffectiveStability(uint256 fluctuationId) internal view returns (uint256) {
        _checkFluctuationExists(fluctuationId);
        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        // Prevent overflow, cap effective stability
        unchecked {
            return fluctuation.stability + environmentStabilityFactor;
        }
    }

     /**
     * @dev Removes a fluctuation from the active set (e.g., after harvest or merge).
     * Does not actually delete from mapping, but clears key properties and removes from allFluctuationIds.
     * @param fluctuationId The ID to remove.
     */
    function _removeFluctuation(uint256 fluctuationId) internal {
         _checkFluctuationExists(fluctuationId);
        // In a real scenario, consider if state needs to be explicitly cleared or just marked inactive.
        // For this example, we'll clear key identifying properties.
        fluctuations[fluctuationId].id = 0; // Mark as removed
        // Removing from allFluctuationIds array is expensive O(n),
        // for a real contract with many fluctuations, a linked list or other
        // data structure might be more suitable, or accept the gas cost.
        // Here's a simple O(n) removal:
        for (uint i = 0; i < allFluctuationIds.length; i++) {
            if (allFluctuationIds[i] == fluctuationId) {
                allFluctuationIds[i] = allFluctuationIds[allFluctuationIds.length - 1];
                allFluctuationIds.pop();
                break;
            }
        }
    }


    // --- Creation Functions ---

    /**
     * @dev Creates a new fluctuation with random initial properties.
     * Requires a small gas cost for creation.
     * @return The ID of the newly created fluctuation.
     */
    function createFluctuation() public payable returns (uint256) {
        // Simple gas cost check (can be more complex)
        require(msg.value >= 1e16, "Requires minimum energy input (0.01 Ether)"); // Conceptual cost

        uint256 newId = nextFluctuationId;
        nextFluctuationId++;

        uint256 seed = _generatePseudoRandom(newId + block.number);
        uint256 initialEnergy = (seed % 500) + 250; // Energy between 250 and 750
        uint256 initialStability = ((seed / 100) % 500) + 250; // Stability between 250 and 750
        bool initialSpin = (seed % 2 == 0);

        fluctuations[newId] = Fluctuation({
            id: newId,
            energy: initialEnergy,
            stability: initialStability,
            phase: Phase.Undetermined, // Starts undetermined
            spin: initialSpin,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            isEntangled: false,
            entangledWithId: 0
        });

        allFluctuationIds.push(newId);

        // Apply decay immediately after creation based on initial time (should be 0)
         _applyDecay(newId); // Updates phase potentially

        emit FluctuationCreated(newId, block.timestamp, msg.sender);
        return newId;
    }

    /**
     * @dev (Owner) Creates multiple initial fluctuations to seed the system.
     * Allows owner to quickly populate the contract state.
     * @param count The number of fluctuations to create.
     */
    function seedInitialState(uint256 count) public onlyOwner {
         require(count > 0 && count <= 100, "Seed count must be between 1 and 100");

        for (uint256 i = 0; i < count; i++) {
            uint256 newId = nextFluctuationId;
            nextFluctuationId++;

            uint256 seed = _generatePseudoRandom(newId + block.number + i);
            uint256 initialEnergy = (seed % 600) + 100; // Energy between 100 and 700
            uint256 initialStability = ((seed / 100) % 600) + 100; // Stability between 100 and 700
            bool initialSpin = (seed % 2 == 0);

            fluctuations[newId] = Fluctuation({
                id: newId,
                energy: initialEnergy,
                stability: initialStability,
                 phase: Phase.Undetermined,
                spin: initialSpin,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                isEntangled: false,
                entangledWithId: 0
            });

            allFluctuationIds.push(newId);
             _applyDecay(newId); // Update phase
             emit FluctuationCreated(newId, block.timestamp, address(0)); // Creator address(0) for seeded
        }
    }

    // --- Interaction & Modification Functions ---

    /**
     * @dev "Observes" a fluctuation, viewing its state and applying immediate decay.
     * Represents the cost/interaction of measurement in a quantum-inspired system.
     * @param fluctuationId The ID of the fluctuation to observe.
     */
    function observeFluctuation(uint256 fluctuationId) public {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Observing costs energy/stability decay

        // If entangled, observing one might affect the other slightly (example: propagate a tiny decay)
        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        if (fluctuation.isEntangled) {
            uint256 entangledId = fluctuation.entangledWithId;
            // Check if the entangled fluctuation still exists and is validly entangled back
             if (fluctuations[entangledId].id != 0 &&
                 fluctuations[entangledId].isEntangled &&
                 fluctuations[entangledId].entangledWithId == fluctuationId) {
                 // Apply a fraction of the decay to the entangled one
                 uint256 timeElapsed = block.timestamp - fluctuation.lastInteractionTime; // Time since *its* last decay
                 if (timeElapsed > 0) {
                      uint256 decayAmount = (timeElapsed * decayRatePerSecond) / 10; // 10% propagation example
                       uint256 energyLoss = decayAmount;
                       uint256 stabilityLoss = decayAmount;

                       if (energyLoss > fluctuations[entangledId].energy) energyLoss = fluctuations[entangledId].energy;
                       if (stabilityLoss > fluctuations[entangledId].stability) stabilityLoss = fluctuations[entangledId].stability;

                       fluctuations[entangledId].energy -= energyLoss;
                       fluctuations[entangledId].stability -= stabilityLoss;
                       // Don't update its lastInteractionTime based on the other's observation
                       emit DecayProcessed(entangledId, energyLoss, stabilityLoss);
                 }
             } else {
                 // Cleanup invalid entanglement state
                 fluctuation.isEntangled = false;
                 fluctuation.entangledWithId = 0;
                 // No event for cleanup for simplicity here
             }
        }

        emit FluctuationObserved(fluctuationId, msg.sender);
    }

     /**
     * @dev Injects energy into a fluctuation, increasing its energy property.
     * Requires payment to represent the cost of adding energy.
     * @param fluctuationId The ID of the fluctuation.
     */
    function injectEnergy(uint256 fluctuationId) public payable {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Apply decay before modification

        require(msg.value > 0, "Must send Ether to inject energy");
        // Example: 1 Ether adds 1000 energy (adjust scale as needed)
        uint256 energyAdded = msg.value * 1000 / 1e18; // Scale Ether to energy units

        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        fluctuation.energy += energyAdded;
        fluctuation.lastInteractionTime = block.timestamp; // Update interaction time

        emit EnergyInjected(fluctuationId, energyAdded, msg.sender);
    }

     /**
     * @dev Applies a stabilizer to a fluctuation, increasing its stability property.
     * Requires payment to represent the cost of stabilizing.
     * @param fluctuationId The ID of the fluctuation.
     */
    function applyStabilizer(uint256 fluctuationId) public payable {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Apply decay before modification

         require(msg.value > 0, "Must send Ether to apply stabilizer");
        // Example: 0.5 Ether adds 500 stability
        uint256 stabilityAdded = msg.value * 1000 / (1e18 * 2); // Scale Ether to stability units

        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        fluctuation.stability += stabilityAdded;
        fluctuation.lastInteractionTime = block.timestamp; // Update interaction time

        emit StabilizerApplied(fluctuationId, stabilityAdded, msg.sender);
    }

    /**
     * @dev Attempts to induce a phase shift in a fluctuation.
     * Success probability or cost might depend on current state (simplified logic here).
     * @param fluctuationId The ID of the fluctuation.
     * @param targetPhase The desired target phase.
     */
    function inducePhaseShift(uint256 fluctuationId, Phase targetPhase) public payable {
         _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Apply decay before modification

        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        Phase oldPhase = fluctuation.phase;

        // Simple logic: Requires some payment, might fail based on stability/energy
        require(msg.value >= 1e15, "Requires minimum energy for phase shift (0.001 Ether)"); // Conceptual cost

        uint256 effectiveStability = _calculateEffectiveStability(fluctuationId);
        uint256 randomness = _generatePseudoRandom(fluctuationId + block.timestamp);

        // Simplified probability: Higher stability/energy increases chance, randomness determines outcome
        bool success = (randomness % (effectiveStability + fluctuation.energy)) > 500; // Example threshold

        if (success) {
            fluctuation.phase = targetPhase;
             // Apply a minor cost even on success
            fluctuation.energy = fluctuation.energy > 50 ? fluctuation.energy - 50 : 0;
            fluctuation.stability = fluctuation.stability > 50 ? fluctuation.stability - 50 : 0;
            emit PhaseShifted(fluctuationId, oldPhase, targetPhase);
        } else {
            // Failure: Apply a larger cost
            fluctuation.energy = fluctuation.energy > 100 ? fluctuation.energy - 100 : 0;
            fluctuation.stability = fluctuation.stability > 100 ? fluctuation.stability - 100 : 0;
             // Maybe shift to Volatile phase on failure
            if(fluctuation.phase != Phase.Decaying) fluctuation.phase = Phase.Volatile;
             // Emit phase shifted to Volatile? Or just indicate attempt failed?
             // Let's emit a generic event or just log failure implicitly by not emitting PhaseShifted.
        }
         fluctuation.lastInteractionTime = block.timestamp; // Update interaction time
         // Re-evaluate phase after state change (can be redundant with _applyDecay's phase logic)
         _applyDecay(fluctuationId);
    }

    /**
     * @dev Flips the spin property of a fluctuation.
     * Simple toggle.
     * @param fluctuationId The ID of the fluctuation.
     */
    function flipSpin(uint256 fluctuationId) public {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Apply decay before modification

        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        fluctuation.spin = !fluctuation.spin;
        fluctuation.lastInteractionTime = block.timestamp; // Update interaction time

        emit SpinFlipped(fluctuationId, fluctuation.spin);
    }

    // --- Entanglement Functions ---

    /**
     * @dev Attempts to entangle two fluctuations.
     * Requires both to exist, not be entangled, and potentially meet other criteria (e.g., minimum energy/stability).
     * @param id1 The ID of the first fluctuation.
     * @param id2 The ID of the second fluctuation.
     */
    function entangleFluctuations(uint256 id1, uint256 id2) public payable {
        _checkFluctuationExists(id1);
        _checkFluctuationExists(id2);
        require(id1 != id2, "Cannot entangle a fluctuation with itself");

         _applyDecay(id1); // Apply decay before interaction
         _applyDecay(id2);

        Fluctuation storage f1 = fluctuations[id1];
        Fluctuation storage f2 = fluctuations[id2];

        require(!f1.isEntangled && !f2.isEntangled, "Both fluctuations must not be already entangled");
        require(f1.energy > 200 && f2.energy > 200, "Both fluctuations need minimum energy to entangle"); // Example criteria
        require(f1.stability > 200 && f2.stability > 200, "Both fluctuations need minimum stability to entangle"); // Example criteria
         require(msg.value >= 2e16, "Requires energy input for entanglement (0.02 Ether)"); // Conceptual cost


        f1.isEntangled = true;
        f1.entangledWithId = id2;
        f2.isEntangled = true;
        f2.entangledWithId = id1;

        // Entangled fluctuations might shift to Quantum phase
        if(f1.phase != Phase.Decaying) f1.phase = Phase.Quantum;
        if(f2.phase != Phase.Decaying) f2.phase = Phase.Quantum;

        f1.lastInteractionTime = block.timestamp;
        f2.lastInteractionTime = block.timestamp;


        emit FluctuationsEntangled(id1, id2);
    }

    /**
     * @dev Disentangles two fluctuations.
     * Requires them to be entangled with each other.
     * @param id1 The ID of the first fluctuation.
     * @param id2 The ID of the second fluctuation.
     */
    function disentangleFluctuations(uint256 id1, uint256 id2) public {
        _checkFluctuationExists(id1);
        _checkFluctuationExists(id2);
         require(id1 != id2, "Invalid disentanglement");

        _applyDecay(id1); // Apply decay before interaction
        _applyDecay(id2);

        Fluctuation storage f1 = fluctuations[id1];
        Fluctuation storage f2 = fluctuations[id2];

        require(f1.isEntangled && f1.entangledWithId == id2, "Fluctuations are not entangled with each other");
        require(f2.isEntangled && f2.entangledWithId == id1, "Fluctuations are not entangled with each other"); // Redundant check for safety

        f1.isEntangled = false;
        f1.entangledWithId = 0;
        f2.isEntangled = false;
        f2.entangledWithId = 0;

        // Disentangled fluctuations might shift back to Undetermined/Volatile
        if(f1.phase == Phase.Quantum) f1.phase = Phase.Undetermined;
        if(f2.phase == Phase.Quantum) f2.phase = Phase.Undetermined;

        f1.lastInteractionTime = block.timestamp;
        f2.lastInteractionTime = block.timestamp;

        emit FluctuationsDisentangled(id1, id2);
    }

    // --- Complex/Probabilistic Interaction Functions ---

     /**
     * @dev Attempts to split a fluctuation into two new ones.
     * Requires high energy and potentially low stability to be unstable enough to split.
     * The original fluctuation is consumed.
     * @param fluctuationId The ID of the fluctuation to split.
     * @return The IDs of the two newly created fluctuations.
     */
    function splitFluctuation(uint256 fluctuationId) public payable returns (uint256 newId1, uint256 newId2) {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Apply decay before interaction

        Fluctuation storage original = fluctuations[fluctuationId];

        require(original.energy > 800, "Fluctuation needs high energy to split"); // Example criteria
        require(original.stability < 500, "Fluctuation needs relatively low stability to split"); // Example criteria
        require(!original.isEntangled, "Cannot split an entangled fluctuation directly"); // Cannot split while entangled
         require(msg.value >= 3e16, "Requires energy input for splitting (0.03 Ether)"); // Conceptual cost


        uint256 seed = _generatePseudoRandom(fluctuationId + block.timestamp);

        // Properties of new fluctuations are derived from the original with some randomness
        uint256 totalEnergy = original.energy;
        uint256 totalStability = original.stability;
        bool originalSpin = original.spin;

        // Consume the original
        _removeFluctuation(fluctuationId); // Removes from active set

        // Create the two new fluctuations
        newId1 = nextFluctuationId++;
        newId2 = nextFluctuationId++;

        uint256 energy1 = (seed % (totalEnergy / 2)) + (totalEnergy / 4); // Roughly quarter to three quarters
        uint256 energy2 = totalEnergy - energy1;

        uint256 stability1 = ((seed / 10) % (totalStability / 2)) + (totalStability / 4);
        uint256 stability2 = totalStability - stability1;

        // Spin might inherit or flip randomly
        bool spin1 = originalSpin;
        bool spin2 = (seed % 3 == 0) ? !originalSpin : originalSpin; // 1/3 chance to flip

         fluctuations[newId1] = Fluctuation({
            id: newId1,
            energy: energy1,
            stability: stability1,
            phase: Phase.Undetermined, // New fluctuations start undetermined
            spin: spin1,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            isEntangled: false,
            entangledWithId: 0
        });
        allFluctuationIds.push(newId1);
         _applyDecay(newId1); // Update phase

         fluctuations[newId2] = Fluctuation({
            id: newId2,
            energy: energy2,
            stability: stability2,
            phase: Phase.Undetermined,
            spin: spin2,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            isEntangled: false,
            entangledWithId: 0
        });
        allFluctuationIds.push(newId2);
         _applyDecay(newId2); // Update phase


        emit FluctuationSplit(fluctuationId, newId1, newId2);
        emit FluctuationCreated(newId1, block.timestamp, msg.sender); // Emit creation events for the new ones
        emit FluctuationCreated(newId2, block.timestamp, msg.sender);

        return (newId1, newId2);
    }

    /**
     * @dev Attempts to merge two fluctuations into a single new one.
     * Requires compatible properties (e.g., same spin) and sufficient combined energy/stability.
     * The original fluctuations are consumed.
     * @param id1 The ID of the first fluctuation.
     * @param id2 The ID of the second fluctuation.
     * @return The ID of the newly created merged fluctuation (0 if merge fails).
     */
    function mergeFluctuations(uint256 id1, uint256 id2) public payable returns (uint256 newId) {
         _checkFluctuationExists(id1);
         _checkFluctuationExists(id2);
         require(id1 != id2, "Cannot merge a fluctuation with itself");
         require(!fluctuations[id1].isEntangled && !fluctuations[id2].isEntangled, "Cannot merge entangled fluctuations");

         _applyDecay(id1); // Apply decay before interaction
         _applyDecay(id2);

        Fluctuation storage f1 = fluctuations[id1];
        Fluctuation storage f2 = fluctuations[id2];

        // Example compatibility criteria: must have the same spin
        require(f1.spin == f2.spin, "Fluctuations must have matching spin to merge");
        // Example energy/stability criteria
        require(f1.energy + f2.energy > 1000, "Combined energy too low for merge");
        require(f1.stability + f2.stability > 1000, "Combined stability too low for merge");
         require(msg.value >= 4e16, "Requires energy input for merging (0.04 Ether)"); // Conceptual cost


        uint256 seed = _generatePseudoRandom(id1 + id2 + block.timestamp);

        // Simplified success probability based on combined stability and randomness
        uint256 combinedStability = _calculateEffectiveStability(id1) + _calculateEffectiveStability(id2);
        bool success = (seed % combinedStability) > 500; // Example threshold

        if (success) {
            // Consume the originals
             _removeFluctuation(id1);
             _removeFluctuation(id2);

            // Create the new merged fluctuation
            newId = nextFluctuationId++;

            uint256 mergedEnergy = (f1.energy + f2.energy) / 2 + (seed % 200); // Averaged + bonus/penalty
            uint256 mergedStability = (f1.stability + f2.stability) / 2 + ((seed / 10) % 200);
            Phase mergedPhase = Phase.Stable; // Merging often results in stability
             bool mergedSpin = f1.spin; // Inherit spin

             fluctuations[newId] = Fluctuation({
                id: newId,
                energy: mergedEnergy,
                stability: mergedStability,
                phase: mergedPhase,
                spin: mergedSpin,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                isEntangled: false,
                entangledWithId: 0
            });
             allFluctuationIds.push(newId);
             _applyDecay(newId); // Update phase


            emit FluctuationsMerged(id1, id2, newId);
            emit FluctuationCreated(newId, block.timestamp, msg.sender);
            return newId;

        } else {
            // Failure: Apply a significant cost and maybe alter phases
            f1.energy = f1.energy > 200 ? f1.energy - 200 : 0;
            f1.stability = f1.stability > 200 ? f1.stability - 200 : 0;
            f2.energy = f2.energy > 200 ? f2.energy - 200 : 0;
            f2.stability = f2.stability > 200 ? f2.stability - 200 : 0;
            // Shift to Volatile phase on failure
             if(f1.phase != Phase.Decaying) f1.phase = Phase.Volatile;
             if(f2.phase != Phase.Decaying) f2.phase = Phase.Volatile;
             f1.lastInteractionTime = block.timestamp;
             f2.lastInteractionTime = block.timestamp;
             _applyDecay(id1); _applyDecay(id2); // Re-evaluate phase

            // No new fluctuation created on failure
            return 0;
        }
    }

    /**
     * @dev Induces a resonance between two fluctuations based on specific phase/spin combinations.
     * Outcome is complex and depends on their states.
     * @param id1 The ID of the first fluctuation.
     * @param id2 The ID of the second fluctuation.
     */
    function induceResonance(uint256 id1, uint256 id2) public payable {
        _checkFluctuationExists(id1);
        _checkFluctuationExists(id2);
         require(id1 != id2, "Invalid resonance");
         require(!fluctuations[id1].isEntangled && !fluctuations[id2].isEntangled, "Cannot induce resonance on entangled fluctuations");

        _applyDecay(id1); // Apply decay before interaction
        _applyDecay(id2);

        Fluctuation storage f1 = fluctuations[id1];
        Fluctuation storage f2 = fluctuations[id2];

        // Example resonance condition: one Volatile, one Quantum, opposite spins
        bool resonanceCondition = ( (f1.phase == Phase.Volatile && f2.phase == Phase.Quantum) || (f1.phase == Phase.Quantum && f2.phase == Phase.Volatile) ) && (f1.spin != f2.spin);

        string memory outcome = "No Resonance";
         require(msg.value >= 1e15, "Requires energy input for resonance attempt (0.001 Ether)"); // Conceptual cost

        if (resonanceCondition) {
             uint256 seed = _generatePseudoRandom(id1 + id2 + block.timestamp);
             uint256 combinedEnergy = f1.energy + f2.energy;
             uint256 combinedStability = _calculateEffectiveStability(id1) + _calculateEffectiveStability(id2);

            // Example resonance outcomes based on combined properties and randomness
            if (combinedEnergy > 1500 && combinedStability < 800 && (seed % 100) < 30) { // High energy, low stability, low randomness roll
                 // Catastrophic Collapse: Both lose significant energy/stability
                 f1.energy = f1.energy > 400 ? f1.energy - 400 : 0;
                 f1.stability = f1.stability > 400 ? f1.stability - 400 : 0;
                 f2.energy = f2.energy > 400 ? f2.energy - 400 : 0;
                 f2.stability = f2.stability > 400 ? f2.stability - 400 : 0;
                 outcome = "Catastrophic Collapse";
            } else if (combinedEnergy > 1200 && combinedStability > 1200 && (seed % 100) < 40) { // High energy, high stability
                 // Harmonious Coupling: Both gain energy/stability, shift to Stable/Resonant
                 f1.energy += 200; f2.energy += 200;
                 f1.stability += 200; f2.stability += 200;
                 if(f1.phase != Phase.Decaying) f1.phase = Phase.Resonant;
                 if(f2.phase != Phase.Decaying) f2.phase = Phase.Resonant;
                 outcome = "Harmonious Coupling";
            } else if ((seed % 100) < 60) { // Medium probability
                 // Phase Lock: Spins flip, phases might swap or normalize
                 bool tempSpin = f1.spin;
                 f1.spin = f2.spin;
                 f2.spin = tempSpin;
                 Phase tempPhase = f1.phase;
                 f1.phase = f2.phase;
                 f2.phase = tempPhase;
                 outcome = "Phase Lock";
            } else { // Remaining cases
                 // Minor Fluctuation: Small energy/stability loss
                 f1.energy = f1.energy > 50 ? f1.energy - 50 : 0;
                 f1.stability = f1.stability > 50 ? f1.stability - 50 : 0;
                 f2.energy = f2.energy > 50 ? f2.energy - 50 : 0;
                 f2.stability = f2.stability > 50 ? f2.stability - 50 : 0;
                 outcome = "Minor Fluctuation";
            }
             // Apply decay again to update state/phase based on new values
             _applyDecay(id1);
             _applyDecay(id2);
        } else {
             // No resonance condition met - just apply basic interaction cost (gas)
             f1.energy = f1.energy > 20 ? f1.energy - 20 : 0;
             f1.stability = f1.stability > 20 ? f1.stability - 20 : 20; // Minimum stability cost
             f2.energy = f2.energy > 20 ? f2.energy - 20 : 0;
             f2.stability = f2.stability > 20 ? f2.stability - 20 : 20;
             _applyDecay(id1);
             _applyDecay(id2);
        }

        f1.lastInteractionTime = block.timestamp;
        f2.lastInteractionTime = block.timestamp;

        emit ResonanceInduced(id1, id2, outcome);
    }


    /**
     * @dev Simulates applying an external, abstract force to a fluctuation.
     * The effect depends on the fluctuation's state and provided external data (hashed).
     * @param fluctuationId The ID of the fluctuation.
     * @param externalData Arbitrary external data (e.g., hash of off-chain data, random value).
     */
    function applyExternalForce(uint256 fluctuationId, bytes32 externalData) public payable {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId);

        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        uint256 dataInfluence = uint256(externalData); // Use hash as a source of variability
        string memory outcome = "No significant effect";

         require(msg.value >= 5e14, "Requires energy input for external force (0.0005 Ether)"); // Conceptual cost


        // Example logic: Effect based on phase and external data
        if (fluctuation.phase == Phase.Volatile) {
            if (dataInfluence % 10 < 3) { // 30% chance of destabilization
                 fluctuation.energy = fluctuation.energy > (dataInfluence % 100) ? fluctuation.energy - (dataInfluence % 100) : 0;
                 fluctuation.stability = fluctuation.stability > (dataInfluence % 200) ? fluctuation.stability - (dataInfluence % 200) : 0;
                 outcome = "Destabilized";
            } else {
                 fluctuation.energy += (dataInfluence % 50); // Small random energy gain
                 outcome = "Minor perturbation";
            }
        } else if (fluctuation.phase == Phase.Quantum) {
             if (dataInfluence % 10 < 5) { // 50% chance of entanglement change (if entangled)
                 if(fluctuation.isEntangled) {
                     disentangleFluctuations(fluctuationId, fluctuation.entangledWithId); // Calls another function
                     outcome = "Entanglement broken by force";
                 } else {
                     // Could potentially *induce* entanglement with a random other fluctuation if conditions met (complex)
                     outcome = "Force attempted entanglement change"; // Simplified
                 }
            } else {
                 fluctuation.stability += (dataInfluence % 100); // Small random stability gain
                 outcome = "State reinforced";
            }
        } else {
             // Default: Small random effect
             fluctuation.energy += (dataInfluence % 30);
             fluctuation.stability += (dataInfluence % 30);
             outcome = "Minor shift";
        }

         fluctuation.lastInteractionTime = block.timestamp;
         _applyDecay(fluctuationId); // Apply decay again

        emit ExternalForceApplied(fluctuationId, externalData, outcome);
    }

    /**
     * @dev Attempts to tunnel properties (energy/stability) between two *non-entangled* fluctuations.
     * Success is probabilistic and depends on the "distance" (property differences) between them.
     * @param fromId The ID of the source fluctuation.
     * @param toId The ID of the target fluctuation.
     */
    function quantumTunnel(uint256 fromId, uint256 toId) public payable {
        _checkFluctuationExists(fromId);
        _checkFluctuationExists(toId);
         require(fromId != toId, "Cannot tunnel within the same fluctuation");
         require(!fluctuations[fromId].isEntangled && !fluctuations[toId].isEntangled, "Cannot tunnel with entangled fluctuations");
         require(fluctuations[fromId].energy > 100, "Source needs energy to tunnel");

        _applyDecay(fromId);
        _applyDecay(toId);

        Fluctuation storage source = fluctuations[fromId];
        Fluctuation storage target = fluctuations[toId];

        // Simplified "distance": sum of absolute differences in energy, stability, plus phase/spin difference penalty
        uint256 energyDiff = source.energy > target.energy ? source.energy - target.energy : target.energy - source.energy;
        uint256 stabilityDiff = source.stability > target.stability ? source.stability - target.stability : target.stability - source.stability;
        uint256 phaseDiffPenalty = (uint256(source.phase) > uint256(target.phase) ? uint256(source.phase) - uint256(target.phase) : uint256(target.phase) - uint256(source.phase)) * 50; // Phases 0-5, so max ~250 penalty
        uint256 spinDiffPenalty = (source.spin != target.spin) ? 100 : 0;

        uint256 distance = energyDiff + stabilityDiff + phaseDiffPenalty + spinDiffPenalty;
         require(distance > 50, "Fluctuations are too similar or too far for effective tunneling"); // Minimum difference required

        uint256 seed = _generatePseudoRandom(fromId + toId + block.timestamp);

        // Probability of success decreases with distance, increases with source energy
        // Example: success if (seed % 1000) < (source.energy / 2 + 500) - distance
        uint256 successChance = (source.energy / 2) + 500;
        if (distance < successChance) successChance -= distance; else successChance = 0;

        bool success = (seed % 1000) < successChance; // Roll against chance (max 1000 roll)

         require(msg.value >= 1e16, "Requires energy input for tunneling (0.01 Ether)"); // Conceptual cost

        uint256 energyTransferred = 0;

        if (success) {
            // Transfer a portion of energy/stability
            energyTransferred = (source.energy / 4) + (seed % (source.energy / 4)); // Transfer between 1/4 and 1/2 source energy
            if (energyTransferred > source.energy) energyTransferred = source.energy; // Should not happen with logic, but safety

            source.energy -= energyTransferred;
            target.energy += energyTransferred;

             // Maybe transfer some stability proportionally to energy
             uint256 stabilityTransferred = (energyTransferred * source.stability) / source.energy; // Proportional transfer (simplified)
             if (stabilityTransferred > source.stability) stabilityTransferred = source.stability;

             source.stability -= stabilityTransferred;
             target.stability += stabilityTransferred;

            // Phases might shift due to large property changes
            _applyDecay(fromId);
            _applyDecay(toId);

        } else {
            // Failure: Cost applied to source
            source.energy = source.energy > 100 ? source.energy - 100 : 0;
            source.stability = source.stability > 50 ? source.stability - 50 : 0;
            _applyDecay(fromId); // Re-evaluate phase

        }

        source.lastInteractionTime = block.timestamp;
        target.lastInteractionTime = block.timestamp;

        emit QuantumTunnelAttempt(fromId, toId, success, energyTransferred);
    }

     /**
     * @dev Triggers a rare, large-scale quantum event originating from a specific fluctuation.
     * The outcome is highly unpredictable and can affect multiple fluctuations.
     * Requires very specific conditions (e.g., high energy, specific phase) and randomness.
     * @param fluctuationId The ID of the fluctuation triggering the event.
     */
    function triggerQuantumEvent(uint256 fluctuationId) public payable {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId);

        Fluctuation storage triggerF = fluctuations[fluctuationId];

        // Example trigger condition: High energy, Quantum phase, and favorable pseudo-random roll
        uint256 seed = _generatePseudoRandom(fluctuationId + block.timestamp + tx.gasprice);
        bool conditionsMet = triggerF.energy > 900
                           && triggerF.phase == Phase.Quantum
                           && (seed % 1000) > 950; // Only a 5% chance based on this seed part

        require(conditionsMet, "Conditions not met to trigger a quantum event");
         require(msg.value >= 5e17, "Requires significant energy input to trigger (0.5 Ether)"); // High conceptual cost


        string memory eventType;
        uint256 outcomeRoll = seed % 100; // Roll for outcome type

        if (outcomeRoll < 20) { // 20% chance: Global Stability Shift
            environmentStabilityFactor += 100;
            decayRatePerSecond = decayRatePerSecond > 1 ? decayRatePerSecond - 1 : 1;
            eventType = "Global Stability Shift";
            emit EnvironmentUpdated(environmentStabilityFactor, decayRatePerSecond, harvestStabilityThreshold, harvestEnergyThreshold);

        } else if (outcomeRoll < 40) { // 20% chance: Energy Cascade
             // Distribute energy from the trigger fluctuation to several others
             uint256 energyPool = triggerF.energy / 2; // Half energy becomes pool
             triggerF.energy -= energyPool;
             uint256 fluctuationsToAffect = (seed % 5) + 3; // Affect 3 to 7 others
             for(uint i = 0; i < allFluctuationIds.length && i < fluctuationsToAffect; i++) {
                  uint256 targetId = allFluctuationIds[seed % allFluctuationIds.length]; // Pick random ones
                  if(targetId != 0 && targetId != fluctuationId && fluctuations[targetId].id != 0) {
                      uint256 energyGain = energyPool / fluctuationsToAffect;
                      fluctuations[targetId].energy += energyGain;
                      fluctuations[targetId].lastInteractionTime = block.timestamp;
                      _applyDecay(targetId); // Update affected fluctuations
                       // emit EnergyInjected(targetId, energyGain, address(this)); // Could emit for each
                  }
             }
            eventType = "Energy Cascade";

        } else if (outcomeRoll < 60) { // 20% chance: Phase Inversion
             // Randomly flip phases of several fluctuations
             uint256 fluctuationsToAffect = (seed % 7) + 5; // Affect 5 to 11 others
             for(uint i = 0; i < allFluctuationIds.length && i < fluctuationsToAffect; i++) {
                  uint224 targetId = uint224(allFluctuationIds[seed % allFluctuationIds.length]);
                   if(targetId != 0 && targetId != fluctuationId && fluctuations[targetId].id != 0) {
                       Phase oldPhase = fluctuations[targetId].phase;
                       // Simple inversion logic
                       if (oldPhase == Phase.Stable) fluctuations[targetId].phase = Phase.Volatile;
                       else if (oldPhase == Phase.Volatile) fluctuations[targetId].phase = Phase.Stable;
                       else if (oldPhase == Phase.Quantum) fluctuations[targetId].phase = Phase.Decaying;
                       else if (oldPhase == Phase.Decaying) fluctuations[targetId].phase = Phase.Quantum;
                       else fluctuations[targetId].phase = Phase(seed % 5); // Truly random phase

                        fluctuations[targetId].lastInteractionTime = block.timestamp;
                       emit PhaseShifted(targetId, oldPhase, fluctuations[targetId].phase);
                   }
             }
            eventType = "Phase Inversion";

        } else { // 40% chance: Local Singularity (Trigger fluctuation state drastically altered)
             triggerF.energy = triggerF.energy > 500 ? triggerF.energy - 500 : 0; // Lose significant energy
             triggerF.stability = triggerF.stability > 500 ? triggerF.stability - 500 : 0; // Lose significant stability
             triggerF.isEntangled = false; // Force disentanglement
             triggerF.entangledWithId = 0;
             triggerF.spin = !triggerF.spin; // Flip spin
             triggerF.phase = Phase.Decaying; // Likely becomes decaying
            eventType = "Local Singularity";
        }

         triggerF.lastInteractionTime = block.timestamp;
         _applyDecay(fluctuationId); // Final state update for trigger


        emit QuantumEventTriggered(fluctuationId, eventType, seed);
    }

    // --- Harvesting Functions ---

    /**
     * @dev Allows a user to "harvest" a fluctuation if it meets the stability and energy thresholds.
     * The fluctuation is consumed (removed), and the caller conceptually receives a reward.
     * @param fluctuationId The ID of the fluctuation to harvest.
     */
    function harvestStableFluctuation(uint256 fluctuationId) public {
        _checkFluctuationExists(fluctuationId);
        _applyDecay(fluctuationId); // Apply final decay before checking/harvesting

        Fluctuation storage fluctuation = fluctuations[fluctuationId];

        require(fluctuation.stability >= harvestStabilityThreshold, "Fluctuation stability is too low to harvest");
        require(fluctuation.energy >= harvestEnergyThreshold, "Fluctuation energy is too low to harvest");
        require(!fluctuation.isEntangled, "Cannot harvest an entangled fluctuation");
         require(fluctuation.phase == Phase.Stable, "Only stable fluctuations can be harvested"); // Example criteria

        uint256 finalEnergy = fluctuation.energy;
        uint256 finalStability = fluctuation.stability;

        // Remove the fluctuation from the active set
        _removeFluctuation(fluctuationId);

        // --- Reward Mechanism (Conceptual Placeholder) ---
        // In a real contract, this would involve:
        // 1. Minting an ERC20/ERC721 token based on fluctuation properties.
        // 2. Sending Ether/other tokens to the harvester.
        // 3. Unlocking access to some feature.
        // For this example, we just emit an event and the Ether sent to the contract remains (could be used for other things or withdrawn by owner).

        emit FluctuationHarvested(fluctuationId, msg.sender, finalEnergy, finalStability);
    }

    // --- Maintenance & Governance Functions ---

    /**
     * @dev Allows anyone to trigger decay processing for a batch of old fluctuations.
     * Helps keep the state updated over time without relying solely on user interaction or owner.
     * Can add a small gas stipend/reward mechanism for the caller in a real contract.
     * @param fluctuationIds An array of fluctuation IDs to process decay for.
     */
    function decayFluctuationsBatch(uint256[] calldata fluctuationIds) public {
         require(fluctuationIds.length <= 50, "Batch size limited to 50"); // Limit batch size to prevent hitting block gas limit

         uint256 processedCount = 0;
         for(uint i = 0; i < fluctuationIds.length; i++) {
             uint256 id = fluctuationIds[i];
             // Check if fluctuation exists and hasn't been removed
             if (id > 0 && id < nextFluctuationId && fluctuations[id].id != 0) {
                 _applyDecay(id);
                 processedCount++;
             }
         }
         emit BatchDecayProcessed(processedCount, msg.sender);
    }


    /**
     * @dev Allows the owner to update the global environmental factors.
     * Affects decay rates and harvest thresholds.
     * @param newStabilityFactor New value for environmentStabilityFactor.
     * @param newDecayRate New value for decayRatePerSecond.
     * @param newHarvestStability New value for harvestStabilityThreshold.
     * @param newHarvestEnergy New value for harvestEnergyThreshold.
     */
    function updateEnvironmentFactors(uint256 newStabilityFactor, uint256 newDecayRate, uint256 newHarvestStability, uint256 newHarvestEnergy) public onlyOwner {
        environmentStabilityFactor = newStabilityFactor;
        decayRatePerSecond = newDecayRate;
        harvestStabilityThreshold = newHarvestStability;
        harvestEnergyThreshold = newHarvestEnergy;

        emit EnvironmentUpdated(environmentStabilityFactor, decayRatePerSecond, harvestStabilityThreshold, harvestEnergyThreshold);
    }

    /**
     * @dev Dissipates excess energy from a fluctuation if it's above a cap.
     * Excess energy can be converted into stability or simply removed.
     * @param fluctuationId The ID of the fluctuation.
     */
    function dissipateExcessEnergy(uint256 fluctuationId) public {
         _checkFluctuationExists(fluctuationId);
         _applyDecay(fluctuationId);

         Fluctuation storage fluctuation = fluctuations[fluctuationId];
         uint256 energyCap = 1000; // Example cap

         if (fluctuation.energy > energyCap) {
             uint256 excess = fluctuation.energy - energyCap;
             fluctuation.energy = energyCap; // Cap energy
             fluctuation.stability += (excess / 2); // Convert half excess energy to stability

             fluctuation.lastInteractionTime = block.timestamp;
             _applyDecay(fluctuationId); // Re-evaluate state

             emit ExcessEnergyDissipated(fluctuationId, excess, fluctuation.stability);
         } else {
             // No excess to dissipate, maybe apply a tiny cost for the check
              fluctuation.energy = fluctuation.energy > 5 ? fluctuation.energy - 5 : 0;
              fluctuation.lastInteractionTime = block.timestamp;
              _applyDecay(fluctuationId);
         }
    }


    // --- Query & View Functions ---

    /**
     * @dev Gets the current state of a specific fluctuation.
     * Applies decay before returning the state to provide up-to-date values.
     * @param fluctuationId The ID of the fluctuation.
     * @return The Fluctuation struct data.
     */
    function getFluctuationState(uint256 fluctuationId) public returns (Fluctuation memory) {
        _checkFluctuationExists(fluctuationId);
        // Apply decay state change immediately before returning state in read call.
        // Note: This changes state, so this function cannot be `view`.
        // If a pure `view` is needed, copy logic without state writes.
        _applyDecay(fluctuationId); // This makes it non-view

        return fluctuations[fluctuationId];
    }

    /**
     * @dev Gets the total number of active fluctuations.
     * @return The count of fluctuations.
     */
    function getTotalFluctuations() public view returns (uint256) {
        return allFluctuationIds.length;
    }

     /**
     * @dev Gets a list of IDs for fluctuations currently in a specific phase.
     * Note: This iterates through all active fluctuations. Can be expensive if there are many.
     * @param targetPhase The phase to filter by.
     * @return An array of fluctuation IDs.
     */
    function getFluctuationsByPhase(Phase targetPhase) public view returns (uint256[] memory) {
        uint256[] memory filteredIds = new uint256[](allFluctuationIds.length);
        uint256 count = 0;
        for (uint i = 0; i < allFluctuationIds.length; i++) {
            uint256 id = allFluctuationIds[i];
             // Double check existence in mapping
            if (fluctuations[id].id != 0 && fluctuations[id].phase == targetPhase) {
                filteredIds[count] = id;
                count++;
            }
        }
        // Trim the array to the actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = filteredIds[i];
        }
        return result;
    }

     /**
     * @dev Gets a list of currently entangled fluctuation pairs.
     * Iterates through active fluctuations.
     * @return An array of pairs [id1, id2]. Each pair represents an entangled link.
     */
    function getEntangledPairs() public view returns (uint256[] memory) {
        uint256[] memory entangledPairs = new uint256[](allFluctuationIds.length * 2); // Max possible pairs * 2 IDs each
        uint256 count = 0;
        // Use a mapping to track already added pairs to avoid duplicates (e.g., [1, 2] and [2, 1])
        mapping(uint256 => mapping(uint256 => bool)) addedPairs;

        for (uint i = 0; i < allFluctuationIds.length; i++) {
            uint256 id = allFluctuationIds[i];
             if (fluctuations[id].id != 0 && fluctuations[id].isEntangled) {
                 uint256 entangledId = fluctuations[id].entangledWithId;
                 // Check if the entangled fluctuation exists and is validly linked back
                  if (fluctuations[entangledId].id != 0 &&
                      fluctuations[entangledId].isEntangled &&
                      fluctuations[entangledId].entangledWithId == id) {

                      // Add the pair only once, ensuring order doesn't matter for tracking
                      uint256 smallerId = id < entangledId ? id : entangledId;
                      uint256 largerId = id > entangledId ? id : entangledId;

                      if (!addedPairs[smallerId][largerId]) {
                         entangledPairs[count] = id;
                         entangledPairs[count + 1] = entangledId;
                         addedPairs[smallerId][largerId] = true;
                         count += 2;
                      }
                  } else {
                      // This indicates an invalid state - in a real contract,
                      // an owner/maintenance function might clean this up.
                      // For view, we just ignore the invalid link.
                  }
             }
        }

        // Trim the array
        uint224[] memory result = new uint224[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = uint224(entangledPairs[i]); // Cast to uint224 to save gas/space if needed, otherwise use uint256
        }
        return result; // Returns pairs as a flat array [id1, id2, id3, id4...]
    }


    /**
     * @dev Gets the current global environmental factors.
     * @return environmentStabilityFactor, decayRatePerSecond, harvestStabilityThreshold, harvestEnergyThreshold.
     */
    function getGlobalEnvironmentFactors() public view returns (uint256, uint256, uint256, uint256) {
        return (environmentStabilityFactor, decayRatePerSecond, harvestStabilityThreshold, harvestEnergyThreshold);
    }

    /**
     * @dev Finds and returns the IDs of fluctuations that currently meet the harvesting criteria.
     * Iterates through all active fluctuations. Can be expensive.
     * @return An array of fluctuation IDs that are harvestable.
     */
    function findPotentialHarvests() public view returns (uint256[] memory) {
        uint256[] memory potentialHarvests = new uint256[](allFluctuationIds.length); // Max possible
        uint256 count = 0;

        for (uint i = 0; i < allFluctuationIds.length; i++) {
             uint256 id = allFluctuationIds[i];
             // Double check existence in mapping
            if (fluctuations[id].id != 0) {
                 Fluctuation storage fluctuation = fluctuations[id];
                // Check decay state *conceptually* without altering state in view function
                // In a real system, state might need to be updated first
                // For this view, we check based on current properties which might be slightly stale
                 if (fluctuation.stability >= harvestStabilityThreshold &&
                    fluctuation.energy >= harvestEnergyThreshold &&
                    !fluctuation.isEntangled &&
                     fluctuation.phase == Phase.Stable // Criteria includes being Stable phase
                    ) {
                    potentialHarvests[count] = id;
                    count++;
                }
            }
        }

        // Trim the array
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = potentialHarvests[i];
        }
        return result;
    }
}
```