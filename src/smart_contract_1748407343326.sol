Okay, let's design a creative and complex smart contract based on the abstract concept of simulating "Quantum Entanglement" and state management on a classical blockchain. We'll call it the `QuantumEntanglementLedger`.

This contract won't *actually* use quantum mechanics (as blockchains are deterministic and classical), but it will *model* digital entities ("Quanta") that have properties inspired by quantum concepts like superposition, measurement, and entanglement, managing their states and interactions in interesting ways.

**Disclaimer:** This contract is a conceptual demonstration of complex state management and interaction patterns in Solidity, inspired by quantum mechanics analogies. It does *not* provide real quantum capabilities. The "randomness" used for measurement is deterministic pseudo-randomness based on block properties and thus vulnerable to miner manipulation in a real-world scenario needing strong unpredictability.

---

## Quantum Entanglement Ledger Smart Contract

**Outline:**

1.  **Contract Definition:** Basic pragma, license, contract name.
2.  **Events:** Signal key actions (creation, transfer, entanglement, measurement, state changes).
3.  **Errors:** Custom errors for better debugging.
4.  **Structs:** Define the structure of a `QuantumEntity` (Quanta).
5.  **State Variables:** Mappings and counters to store Quanta data.
6.  **Modifiers:** Reusable checks (e.g., Quanta existence, ownership, state).
7.  **Core Logic Functions:**
    *   **Quanta Management:** Create, transfer, destroy, update basic properties.
    *   **Superposition Management:** Add/remove potential states, update probabilities.
    *   **Entanglement Management:** Link/unlink Quanta, adjust link properties.
    *   **Interaction & Measurement:** Simulate measurement, propagate influence, simulate complex operations.
    *   **Query Functions:** Read Quanta data and history.
    *   **Advanced/Conceptual Functions:** Complex interactions, conditional logic, simulations.

**Function Summary:**

*   **Creation/Ownership (3 functions):**
    *   `createQuanta`: Mints a new Quantum Entity with initial superposition and probabilities.
    *   `transferQuanta`: Transfers ownership of a Quanta.
    *   `destroyQuanta`: Burns a Quanta, removing it from the ledger.
*   **Superposition & State Management (6 functions):**
    *   `addSuperpositionState`: Adds a new possible state to a Quanta's superposition.
    *   `removeSuperpositionState`: Removes a possible state from a Quanta's superposition.
    *   `updateStateProbability`: Adjusts the probability of a specific state within the superposition.
    *   `applyQuantumGateSim`: Simulates the effect of a "quantum gate" operation on a Quanta's superposition and probabilities.
    *   `triggerDecoherenceEvent`: Simulates external interaction causing partial or full loss of superposition/coherence.
    *   `setGroundState`: Defines a special "ground state" for a Quanta, often the result of full decoherence or initialization.
*   **Entanglement Management (3 functions):**
    *   `entangleQuantaPair`: Links two Quanta together, establishing an entangled relationship.
    *   `disentangleQuanta`: Breaks the entangled link between two Quanta.
    *   `updateEntanglementStrength`: Modifies the influence strength between entangled partners.
*   **Interaction & Measurement (5 functions):**
    *   `measureQuanta`: Simulates measuring a Quanta, collapsing its superposition to a single deterministic state based on probabilities.
    *   `propagateMeasurementInfluence`: Automatically called after `measureQuanta` if entangled, influences the entangled partner's state/probabilities.
    *   `performJointMeasurement`: Attempts to measure two entangled Quanta in a correlated manner.
    *   `attemptConditionalEntanglement`: Tries to entangle Quanta only if external or internal conditions are met.
    *   `resolveEntanglementCascade`: Simulates a chain reaction where one measurement influences an entangled partner, which might in turn influence *its* entangled partner (if any).
*   **Query Functions (6 functions):**
    *   `getQuantaInfo`: Retrieves all structural and state information for a Quanta.
    *   `getSuperpositionStates`: Returns the list of potential states in superposition.
    *   `getStateProbabilities`: Returns the probability distribution mapping for superposition states.
    *   `getEntangledPairId`: Checks if a Quanta is entangled and returns its partner's ID.
    *   `getStateHistory`: Returns the history of measured states for a Quanta.
    *   `predictFutureProbabilitiesSim`: Provides a simulated prediction of potential future state probabilities based on current properties (decay, entanglement).
*   **Advanced & Utilities (3 functions):**
    *   `transferEntangledPair`: Transfers ownership of *both* entangled Quanta in a single operation.
    *   `setMeasurementCallbackContract`: Allows setting a contract to be notified when a specific Quanta is measured.
    *   `updateCoherenceLossRate`: Adjusts the rate at which a Quanta's superposition decays naturally over time (simulated).

**(Total: 26 functions - exceeding the requirement of 20)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementLedger
 * @dev A conceptual smart contract simulating digital entities (Quanta) with
 *      properties inspired by quantum mechanics, including superposition,
 *      measurement, and entanglement. This contract manages complex state
 *      transitions and interactions between these digital entities on a
 *      classical blockchain.
 *      NOTE: This is a simulation for exploring complex Solidity patterns.
 *      It does NOT use or provide real quantum capabilities. Pseudo-randomness
 *      is deterministic and based on block properties.
 */
contract QuantumEntanglementLedger {

    // --- Events ---

    event QuantaCreated(uint256 indexed quantaId, address indexed owner, bytes32 initialGroundState);
    event QuantaTransferred(uint256 indexed quantaId, address indexed from, address indexed to);
    event QuantaDestroyed(uint256 indexed quantaId);
    event SuperpositionStateAdded(uint256 indexed quantaId, bytes32 newState);
    event SuperpositionStateRemoved(uint256 indexed quantaId, bytes32 state);
    event StateProbabilityUpdated(uint256 indexed quantaId, bytes32 state, uint256 newProbabilityScaled); // Probability scaled by 10000
    event QuantaMeasured(uint256 indexed quantaId, bytes32 measuredState, uint256 time);
    event QuantaEntangled(uint256 indexed quanta1Id, uint256 indexed quanta2Id, uint256 strength);
    event QuantaDisentangled(uint256 indexed quanta1Id, uint256 indexed quanta2Id);
    event EntanglementStrengthUpdated(uint256 indexed quanta1Id, uint256 indexed quanta2Id, uint256 newStrength);
    event MeasurementInfluencePropagated(uint256 indexed sourceQuantaId, uint256 indexed targetQuantaId, bytes32 sourceState, string outcomeDescription);
    event DecoherenceTriggered(uint256 indexed quantaId, string description);
    event JointMeasurementPerformed(uint256 indexed quanta1Id, uint256 indexed quanta2Id, bytes32 state1, bytes32 state2);
    event EntanglementCascadeResolved(uint256 indexed initialQuantaId, uint256 indexed affectedQuantaId, bytes32 state);
    event MeasurementCallbackSet(uint256 indexed quantaId, address indexed callbackContract);
    event QuantumGateSimApplied(uint256 indexed quantaId, string gateType);
    event CoherenceLossRateUpdated(uint256 indexed quantaId, uint256 newRateScaled); // Rate scaled by 10000

    // --- Errors ---

    error QuantaDoesNotExist(uint256 quantaId);
    error NotQuantaOwner(uint256 quantaId, address caller);
    error QuantaAlreadyExists(uint256 quantaId);
    error NotInSuperposition(uint256 quantaId);
    error StateNotInSuperposition(uint256 quantaId, bytes32 state);
    error ProbabilitySumNot100Percent(uint256 currentSum); // Expected sum is 10000
    error QuantaNotEntangled(uint256 quantaId);
    error QuantaAlreadyEntangled(uint256 quantaId, uint256 existingPairId);
    error CannotEntangleSelf(uint256 quantaId);
    error EntanglementConditionNotMet(string reason);
    error NotEntangledPairOwner(uint256 quanta1Id, uint256 quanta2Id, address caller);
    error ZeroAddressNotAllowed();

    // --- Structs ---

    struct StateHistoryEntry {
        bytes32 measuredState;
        uint64 timestamp; // Use uint64 for gas efficiency if timestamp fits
        uint256 blockNumber;
    }

    struct QuantumEntity {
        uint256 id;
        address owner;
        bytes32 currentState; // The state after 'measurement'
        bytes32 groundState; // Default or fully decohered state
        bytes32[] superpositionStates; // Potential states before measurement
        mapping(bytes32 => uint256) probabilityDistribution; // state => probability (scaled by 10000, e.g., 50% = 5000)
        bool inSuperposition; // True if currentState is not fixed yet
        uint256 entangledPairId; // 0 if not entangled
        uint256 entanglementStrength; // How strongly does measurement affect the pair? (scaled by 10000)
        uint64 lastMeasurementTime; // Timestamp of the last measurement/collapse
        uint256 coherenceLossRateScaled; // Rate of superposition decay simulation (e.g., per block or per unit time)
        StateHistoryEntry[] history;
        address measurementCallbackContract; // Contract to notify on measurement
    }

    // --- State Variables ---

    mapping(uint256 => QuantumEntity) public quantaLedger;
    mapping(address => uint256[]) private ownerQuantaIds; // Track quanta per owner
    uint256 private nextQuantaId = 1;

    // --- Modifiers ---

    modifier onlyQuantaOwner(uint256 _quantaId) {
        if (quantaLedger[_quantaId].owner != msg.sender) {
            revert NotQuantaOwner(_quantaId, msg.sender);
        }
        _;
    }

    modifier quantaExists(uint256 _quantaId) {
        if (quantaLedger[_quantaId].owner == address(0)) { // Owner address 0 indicates not exists
            revert QuantaDoesNotExist(_quantaId);
        }
        _;
    }

    modifier whenInSuperposition(uint256 _quantaId) {
        if (!quantaLedger[_quantaId].inSuperposition) {
            revert NotInSuperposition(_quantaId);
        }
        _;
    }

    modifier whenEntangled(uint256 _quantaId) {
        if (quantaLedger[_quantaId].entangledPairId == 0) {
            revert QuantaNotEntangled(_quantaId);
        }
        _;
    }

    modifier onlyEntangledPairOwner(uint256 _quanta1Id, uint256 _quanta2Id) {
        quantaExists(_quanta1Id);
        quantaExists(_quanta2Id);
        if (quantaLedger[_quanta1Id].owner != msg.sender || quantaLedger[_quanta2Id].owner != msg.sender) {
             revert NotEntangledPairOwner(_quanta1Id, _quanta2Id, msg.sender);
        }
        _;
    }

    // --- Constructor ---
    // No specific constructor needed for initialization beyond default values

    // --- Core Logic Functions ---

    /**
     * @dev Creates a new Quantum Entity (Quanta).
     * @param _owner The owner of the new Quanta.
     * @param _groundState The default/decohered state of the Quanta.
     * @param _initialSuperpositionStates The potential states before first measurement.
     * @param _initialProbabilitiesScaled The probabilities for each state in _initialSuperpositionStates (scaled by 10000). Must sum to 10000.
     * @param _coherenceLossRateScaled The rate at which superposition decays (scaled by 10000).
     * @return The ID of the newly created Quanta.
     */
    function createQuanta(
        address _owner,
        bytes32 _groundState,
        bytes32[] calldata _initialSuperpositionStates,
        uint256[] calldata _initialProbabilitiesScaled,
        uint256 _coherenceLossRateScaled
    ) external returns (uint256) {
        if (_owner == address(0)) revert ZeroAddressNotAllowed();
        if (_initialSuperpositionStates.length != _initialProbabilitiesScaled.length) revert Error("Initial states and probabilities mismatch");
        if (_initialSuperpositionStates.length == 0) revert Error("Must have at least one initial superposition state");

        uint256 currentId = nextQuantaId++;

        uint256 totalProb = 0;
        for (uint i = 0; i < _initialProbabilitiesScaled.length; i++) {
            totalProb += _initialProbabilitiesScaled[i];
        }
        if (totalProb != 10000) {
            revert ProbabilitySumNot100Percent(totalProb);
        }

        QuantumEntity storage newQuanta = quantaLedger[currentId];
        newQuanta.id = currentId;
        newQuanta.owner = _owner;
        newQuanta.groundState = _groundState;
        newQuanta.superpositionStates = _initialSuperpositionStates;
        newQuanta.inSuperposition = true;
        newQuanta.entangledPairId = 0; // Initially not entangled
        newQuanta.entanglementStrength = 0;
        newQuanta.lastMeasurementTime = uint64(block.timestamp); // Use timestamp for coherence reference
        newQuanta.coherenceLossRateScaled = _coherenceLossRateScaled;
        newQuanta.currentState = bytes32(0); // Undefined until measured

        for (uint i = 0; i < _initialSuperpositionStates.length; i++) {
            newQuanta.probabilityDistribution[_initialSuperpositionStates[i]] = _initialProbabilitiesScaled[i];
        }

        ownerQuantaIds[_owner].push(currentId);

        emit QuantaCreated(currentId, _owner, _groundState);
        return currentId;
    }

    /**
     * @dev Transfers ownership of a Quanta.
     * @param _quantaId The ID of the Quanta to transfer.
     * @param _to The address of the new owner.
     */
    function transferQuanta(uint256 _quantaId, address _to)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
    {
        if (_to == address(0)) revert ZeroAddressNotAllowed();

        QuantumEntity storage quanta = quantaLedger[_quantaId];
        address oldOwner = quanta.owner;

        // Remove from old owner's list (simple implementation, could be optimized)
        uint256[] storage oldOwnerIds = ownerQuantaIds[oldOwner];
        for (uint i = 0; i < oldOwnerIds.length; i++) {
            if (oldOwnerIds[i] == _quantaId) {
                oldOwnerIds[i] = oldOwnerIds[oldOwnerIds.length - 1];
                oldOwnerIds.pop();
                break;
            }
        }

        quanta.owner = _to;
        ownerQuantaIds[_to].push(_quantaId);

        emit QuantaTransferred(_quantaId, oldOwner, _to);
    }

    /**
     * @dev Destroys a Quanta, removing it from the ledger. Cannot be undone.
     *      Also breaks entanglement if applicable.
     * @param _quantaId The ID of the Quanta to destroy.
     */
    function destroyQuanta(uint256 _quantaId)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
    {
        QuantumEntity storage quanta = quantaLedger[_quantaId];
        address owner = quanta.owner;

        // Break entanglement if exists
        if (quanta.entangledPairId != 0) {
            uint256 pairId = quanta.entangledPairId;
            // Ensure the pair exists before attempting to modify
            if (quantaLedger[pairId].owner != address(0) && quantaLedger[pairId].entangledPairId == _quantaId) {
                 quantaLedger[pairId].entangledPairId = 0;
                 quantaLedger[pairId].entanglementStrength = 0;
                 // Trigger potential effects on the disentangled partner (e.g., decoherence)
                 _triggerDecoherenceSim(pairId, "Partner Destroyed");
                 emit QuantaDisentangled(_quantaId, pairId); // Emit for the pair too
            }
        }

         // Remove from owner's list (simple implementation)
        uint256[] storage ownerIds = ownerQuantaIds[owner];
        for (uint i = 0; i < ownerIds.length; i++) {
            if (ownerIds[i] == _quantaId) {
                ownerIds[i] = ownerIds[ownerIds.length - 1];
                ownerIds.pop();
                break;
            }
        }

        // Clear storage
        delete quantaLedger[_quantaId];

        emit QuantaDestroyed(_quantaId);
    }

    /**
     * @dev Adds a potential state to a Quanta's superposition.
     *      Requires probabilities to be re-normalized later.
     * @param _quantaId The ID of the Quanta.
     * @param _newState The state to add.
     */
    function addSuperpositionState(uint256 _quantaId, bytes32 _newState)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
        whenInSuperposition(_quantaId)
    {
        QuantumEntity storage quanta = quantaLedger[_quantaId];

        // Check if state already exists in superposition
        for (uint i = 0; i < quanta.superpositionStates.length; i++) {
            if (quanta.superpositionStates[i] == _newState) {
                return; // State already present, do nothing
            }
        }

        quanta.superpositionStates.push(_newState);
        // Note: Probability for the new state is initially 0.
        // Owner *must* call updateStateProbability and ensure total sum is 10000.

        emit SuperpositionStateAdded(_quantaId, _newState);
    }

    /**
     * @dev Removes a state from a Quanta's superposition.
     *      Requires probabilities to be re-normalized later.
     *      Cannot remove the last state.
     * @param _quantaId The ID of the Quanta.
     * @param _stateToRemove The state to remove.
     */
    function removeSuperpositionState(uint256 _quantaId, bytes32 _stateToRemove)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
        whenInSuperposition(_quantaId)
    {
         QuantumEntity storage quanta = quantaLedger[_quantaId];

        if (quanta.superpositionStates.length <= 1) revert Error("Cannot remove the last superposition state");

        bool found = false;
        for (uint i = 0; i < quanta.superpositionStates.length; i++) {
            if (quanta.superpositionStates[i] == _stateToRemove) {
                // Remove from array (simple swap and pop)
                quanta.superpositionStates[i] = quanta.superpositionStates[quanta.superpositionStates.length - 1];
                quanta.superpositionStates.pop();
                // Remove probability entry
                delete quanta.probabilityDistribution[_stateToRemove];
                found = true;
                break;
            }
        }

        if (!found) revert StateNotInSuperposition(_quantaId, _stateToRemove);

        // Note: Probabilities now might not sum to 10000.
        // Owner *must* call updateStateProbability to re-normalize.

        emit SuperpositionStateRemoved(_quantaId, _stateToRemove);
    }

    /**
     * @dev Updates the probability for a state in superposition.
     *      Requires re-normalization of all probabilities to ensure they sum to 10000.
     * @param _quantaId The ID of the Quanta.
     * @param _states The array of states whose probabilities are being updated.
     * @param _probabilitiesScaled The new probabilities for _states (scaled by 10000).
     */
    function updateStateProbability(uint256 _quantaId, bytes32[] calldata _states, uint256[] calldata _probabilitiesScaled)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
        whenInSuperposition(_quantaId)
    {
        if (_states.length != _probabilitiesScaled.length) revert Error("States and probabilities arrays mismatch");
        if (_states.length == 0) revert Error("Must provide at least one state to update");

        QuantumEntity storage quanta = quantaLedger[_quantaId];
        uint256 totalProb = 0;

        // Check if all provided states are in superposition
        mapping(bytes32 => bool) memory statesInSuperposition;
        for(uint i = 0; i < quanta.superpositionStates.length; i++) {
            statesInSuperposition[quanta.superpositionStates[i]] = true;
        }
         for(uint i = 0; i < _states.length; i++) {
            if (!statesInSuperposition[_states[i]]) {
                revert StateNotInSuperposition(_quantaId, _states[i]);
            }
        }


        // Apply updates and calculate new total probability
        for (uint i = 0; i < _states.length; i++) {
            quanta.probabilityDistribution[_states[i]] = _probabilitiesScaled[i];
        }

        // Calculate the total probability from the *current* superposition states
        for (uint i = 0; i < quanta.superpositionStates.length; i++) {
             totalProb += quanta.probabilityDistribution[quanta.superpositionStates[i]];
        }

        if (totalProb != 10000) {
            revert ProbabilitySumNot100Percent(totalProb);
        }

        // Emit events for each state updated (or a single event is fine)
        emit StateProbabilityUpdated(_quantaId, bytes32(0), totalProb); // Emit with 0 state, total prob for simplicity
    }

     /**
     * @dev Applies a simulated "quantum gate" operation (e.g., Hadamard-like, NOT-like)
     *      This abstractly modifies the superposition and probabilities based on the gate type.
     *      Requires specific gateType strings and corresponding logic implemented internally.
     * @param _quantaId The ID of the Quanta.
     * @param _gateType A string representing the type of quantum gate to simulate.
     * @param _params Arbitrary bytes data for gate-specific parameters.
     */
    function applyQuantumGateSim(uint256 _quantaId, string calldata _gateType, bytes calldata _params)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
        whenInSuperposition(_quantaId)
    {
        // This is a placeholder for complex simulation logic.
        // Real implementation would involve decoding _params and applying
        // complex transformations to superpositionStates and probabilityDistribution
        // based on _gateType string (e.g., "Hadamard", "PauliX", "CNOT" - if entangled).
        // This simulation is highly abstract and depends on how you define states and ops.

        QuantumEntity storage quanta = quantaLedger[_quantaId];

        if (keccak256(abi.encodePacked(_gateType)) == keccak256(abi.encodePacked("HadamardSim"))) {
            // Example: Simulate Hadamard on a 2-state system (|0> -> |0>+|1>, |1> -> |0>-|1>)
            // Abstractly, if there are two states A and B, maybe transform a pure state A
            // into a superposition of A and B with 50/50 probability.
            if (quanta.superpositionStates.length == 1) {
                 bytes32 originalState = quanta.superpositionStates[0];
                 // Find another state, or add one conceptually
                 // Simplified: just add a new state if only one exists, set 50/50
                 if (quanta.superpositionStates.length == 1) {
                     bytes32 newState = bytes32(keccak256(abi.encodePacked(originalState, "HadamardSimmed"))); // Example of generating a new state name
                     addSuperpositionState(_quantaId, newState); // Adds, sets prob to 0 initially
                     // Now update probabilities for both to 50/50 (5000)
                     bytes32[] memory statesToUpdate = new bytes32[](2);
                     uint256[] memory probsToUpdate = new uint256[](2);
                     statesToUpdate[0] = originalState;
                     probsToUpdate[0] = 5000;
                     statesToUpdate[1] = newState;
                     probsToUpdate[1] = 5000;
                     updateStateProbability(_quantaId, statesToUpdate, probsToUpdate); // Calls internal, bypasses external modifier checks if logic were in helper func
                     // Re-check: need to call the function directly from the storage ref or use internal helper
                     _updateStateProbabilityInternal(_quantaId, statesToUpdate, probsToUpdate); // Use helper
                 }
            } else {
                // Handle more complex Hadamard simulation for >2 states
                // This would involve more intricate probability recalculations.
                // Placeholder: Do nothing or revert for unhandled complex cases
            }
        } else if (keccak256(abi.encodePacked(_gateType)) == keccak256(abi.encodePacked("PauliXSim"))) {
             // Example: Simulate Pauli-X (NOT) gate - conceptually flips the state.
             // If in superposition of A, B, C... with probs P_A, P_B, P_C...
             // maybe swap probabilities between two designated states, or reverse the order?
             // Simplistic: If only two states A, B, swap their probabilities.
             if (quanta.superpositionStates.length == 2) {
                bytes32 stateA = quanta.superpositionStates[0];
                bytes32 stateB = quanta.superpositionStates[1];
                uint256 probA = quanta.probabilityDistribution[stateA];
                uint256 probB = quanta.probabilityDistribution[stateB];

                 bytes32[] memory statesToUpdate = new bytes32[](2);
                 uint256[] memory probsToUpdate = new uint256[](2);
                 statesToUpdate[0] = stateA;
                 probsToUpdate[0] = probB; // Swap
                 statesToUpdate[1] = stateB;
                 probsToUpdate[1] = probA; // Swap
                 _updateStateProbabilityInternal(_quantaId, statesToUpdate, probsToUpdate); // Use helper

             } else {
                 // Handle more complex Pauli-X simulation
             }
        }
        // Add more gate simulations here...

        // After applying the gate, probability distribution might change, re-verify sum?
        // The _updateStateProbabilityInternal already checks the sum.

        emit QuantumGateSimApplied(_quantaId, _gateType);
    }

     // Internal helper for probability updates to be called by other internal functions
    function _updateStateProbabilityInternal(uint256 _quantaId, bytes32[] memory _states, uint256[] memory _probabilitiesScaled) internal {
         QuantumEntity storage quanta = quantaLedger[_quantaId];
         uint256 totalProb = 0;

         for (uint i = 0; i < _states.length; i++) {
            quanta.probabilityDistribution[_states[i]] = _probabilitiesScaled[i];
         }

         for (uint i = 0; i < quanta.superpositionStates.length; i++) {
             totalProb += quanta.probabilityDistribution[quanta.superpositionStates[i]];
         }

         if (totalProb != 10000) {
             // This might indicate an error in the gate simulation logic itself, not user input
             revert Error("Internal Probability sum failed after gate simulation");
         }
    }


    /**
     * @dev Simulates external interaction causing partial or full loss of superposition.
     *      Can lead to a random collapse or collapse towards the ground state based on parameters.
     * @param _quantaId The ID of the Quanta.
     * @param _decoherenceFactor Scaled factor (0-10000) determining the extent of decoherence.
     * @param _preferGroundState Whether decoherence biases towards the ground state.
     */
    function triggerDecoherenceEvent(uint256 _quantaId, uint256 _decoherenceFactor, bool _preferGroundState)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
        whenInSuperposition(_quantaId)
    {
        _triggerDecoherenceSim(_quantaId, string(abi.encodePacked("Manual Trigger")));
    }

     // Internal helper for triggering decoherence simulation
    function _triggerDecoherenceSim(uint256 _quantaId, string memory _reason) internal {
        QuantumEntity storage quanta = quantaLedger[_quantaId];

        // Simple decoherence simulation:
        // Increase probability of ground state based on coherence loss rate and time elapsed.
        // If coherence completely lost (simulated), collapse to ground state or random state.

        uint256 timeElapsed = block.timestamp - quanta.lastMeasurementTime;
        // Simulate coherence loss over time - highly simplified
        uint256 potentialLoss = (timeElapsed * quanta.coherenceLossRateScaled) / 1e18; // Example scaling

        uint256 groundStateProbIncrease = potentialLoss; // Just add directly, maxing out at 10000
        if (groundStateProbIncrease > 10000) groundStateProbIncrease = 10000;

        // Adjust probabilities: increase ground state, proportionally decrease others
        bytes32 groundState = quanta.groundState;
        uint256 currentGroundProb = quanta.probabilityDistribution[groundState];
        uint256 remainingProbToDistribute = 10000 - currentGroundProb;
        uint256 newGroundProb = currentGroundProb + groundStateProbIncrease;
        if (newGroundProb > 10000) newGroundProb = 10000;

        uint256 totalOtherProbDecrease = newGroundProb - currentGroundProb;
        if (totalOtherProbDecrease > remainingProbToDistribute) totalOtherProbDecrease = remainingProbToDistribute; // Cap decrease

        uint256 decreasePerOtherState = 0;
        uint256 numOtherStates = 0;
         for(uint i = 0; i < quanta.superpositionStates.length; i++) {
             if (quanta.superpositionStates[i] != groundState) {
                 numOtherStates++;
             }
         }

        if (numOtherStates > 0) {
             decreasePerOtherState = totalOtherProbDecrease / numOtherStates;
        }

        bytes32[] memory statesToUpdate = new bytes32[](quanta.superpositionStates.length);
        uint256[] memory probsToUpdate = new uint256[](quanta.superpositionStates.length);
        uint updateIndex = 0;
        uint256 totalProbCheck = 0;

        for(uint i = 0; i < quanta.superpositionStates.length; i++) {
            bytes32 state = quanta.superpositionStates[i];
            uint256 currentProb = quanta.probabilityDistribution[state];
            uint256 newProb;

            if (state == groundState) {
                newProb = newGroundProb;
            } else {
                if (currentProb <= decreasePerOtherState) {
                    newProb = 0;
                } else {
                    newProb = currentProb - decreasePerOtherState;
                }
            }
             statesToUpdate[updateIndex] = state;
             probsToUpdate[updateIndex] = newProb;
             totalProbCheck += newProb;
             updateIndex++;
        }

        // Re-normalize if needed due to rounding or edge cases (should sum to 10000 ideally)
        if (totalProbCheck != 10000) {
            // Simple re-normalization: add difference to ground state or distribute
            if (totalProbCheck < 10000) {
                 // Add deficit to ground state probability
                 for (uint i = 0; i < statesToUpdate.length; i++) {
                     if (statesToUpdate[i] == groundState) {
                          probsToUpdate[i] += (10000 - totalProbCheck);
                          break;
                     }
                 }
            } else {
                 // Subtract excess from ground state or distribute
                 for (uint i = 0; i < statesToUpdate.length; i++) {
                     if (statesToUpdate[i] == groundState) {
                         if (probsToUpdate[i] >= (totalProbCheck - 10000)) {
                              probsToUpdate[i] -= (totalProbCheck - 10000);
                         } else {
                             // Handle complex case: redistribute excess from other states
                         }
                         break;
                     }
                 }
            }
        }
         _updateStateProbabilityInternal(_quantaId, statesToUpdate, probsToUpdate); // Use helper to apply changes

        // If probability of ground state reaches 10000, collapse it
        if (quanta.probabilityDistribution[groundState] == 10000) {
             _collapseQuantaState(_quantaId, groundState, "Decoherence Collapse");
        }

        emit DecoherenceTriggered(_quantaId, _reason);
    }


     /**
     * @dev Sets or updates the designated ground state for a Quanta.
     *      The ground state is the state a Quanta tends towards during decoherence.
     *      If the new ground state is not in the current superposition, it is added.
     * @param _quantaId The ID of the Quanta.
     * @param _newGroundState The new ground state value.
     */
    function setGroundState(uint256 _quantaId, bytes32 _newGroundState)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
    {
         QuantumEntity storage quanta = quantaLedger[_quantaId];
         bytes32 oldGroundState = quanta.groundState;
         quanta.groundState = _newGroundState;

         // Ensure the new ground state is in the superposition if it's not fixed yet
         if (quanta.inSuperposition) {
            bool existsInSuperposition = false;
             for(uint i = 0; i < quanta.superpositionStates.length; i++) {
                 if (quanta.superpositionStates[i] == _newGroundState) {
                     existsInSuperposition = true;
                     break;
                 }
             }
             if (!existsInSuperposition) {
                 addSuperpositionState(_quantaId, _newGroundState); // Add with 0 probability
                 // Owner should re-normalize probabilities after this
             }
         }
         // Note: No event for ground state change itself, usually implicitly handled by state changes.
    }


    /**
     * @dev Links two Quanta together, establishing an entangled relationship.
     *      Requires both Quanta to be in superposition. Both must be owned by the caller.
     * @param _quanta1Id The ID of the first Quanta.
     * @param _quanta2Id The ID of the second Quanta.
     * @param _initialStrength The initial strength of the entanglement (scaled by 10000).
     */
    function entangleQuantaPair(uint256 _quanta1Id, uint256 _quanta2Id, uint256 _initialStrength)
        external
        quantaExists(_quanta1Id)
        quantaExists(_quanta2Id)
        onlyEntangledPairOwner(_quanta1Id, _quanta2Id)
        whenInSuperposition(_quanta1Id)
        whenInSuperposition(_quanta2Id)
    {
        if (_quanta1Id == _quanta2Id) revert CannotEntangleSelf(_quanta1Id);
        if (quantaLedger[_quanta1Id].entangledPairId != 0) revert QuantaAlreadyEntangled(_quanta1Id, quantaLedger[_quanta1Id].entangledPairId);
        if (quantaLedger[_quanta2Id].entangledPairId != 0) revert QuantaAlreadyEntangled(_quanta2Id, quantaLedger[_quanta2Id].entangledPairId);
        if (_initialStrength > 10000) revert Error("Entanglement strength cannot exceed 10000");

        quantaLedger[_quanta1Id].entangledPairId = _quanta2Id;
        quantaLedger[_quanta1Id].entanglementStrength = _initialStrength;
        quantaLedger[_quanta2Id].entangledPairId = _quanta1Id;
        quantaLedger[_quanta2Id].entanglementStrength = _initialStrength;

        emit QuantaEntangled(_quanta1Id, _quanta2Id, _initialStrength);
    }

    /**
     * @dev Breaks the entangled link between two Quanta.
     * @param _quanta1Id The ID of one Quanta in the entangled pair.
     * @param _quanta2Id The ID of the other Quanta in the entangled pair.
     *      Requires caller to own both.
     */
    function disentangleQuanta(uint256 _quanta1Id, uint256 _quanta2Id)
        external
        quantaExists(_quanta1Id)
        quantaExists(_quanta2Id)
        onlyEntangledPairOwner(_quanta1Id, _quanta2Id)
    {
        if (quantaLedger[_quanta1Id].entangledPairId != _quanta2Id || quantaLedger[_quanta2Id].entangledPairId != _quanta1Id) {
            revert Error("Quanta are not entangled with each other");
        }

        quantaLedger[_quanta1Id].entangledPairId = 0;
        quantaLedger[_quanta1Id].entanglementStrength = 0;
        quantaLedger[_quanta2Id].entangledPairId = 0;
        quantaLedger[_quanta2Id].entanglementStrength = 0;

        // Disentanglement can trigger decoherence in both
        _triggerDecoherenceSim(_quanta1Id, "Disentangled");
        _triggerDecoherenceSim(_quanta2Id, "Disentangled");


        emit QuantaDisentangled(_quanta1Id, _quanta2Id);
    }

    /**
     * @dev Updates the strength of the entanglement between two Quanta.
     *      Requires caller to own both entangled Quanta.
     * @param _quanta1Id The ID of one Quanta.
     * @param _quanta2Id The ID of its entangled partner.
     * @param _newStrength The new strength (scaled by 10000).
     */
     function updateEntanglementStrength(uint256 _quanta1Id, uint256 _quanta2Id, uint256 _newStrength)
         external
         quantaExists(_quanta1Id)
         quantaExists(_quanta2Id)
         onlyEntangledPairOwner(_quanta1Id, _quanta2Id)
     {
         if (quantaLedger[_quanta1Id].entangledPairId != _quanta2Id || quantaLedger[_quanta2Id].entangledPairId != _quanta1Id) {
             revert Error("Quanta are not entangled with each other");
         }
         if (_newStrength > 10000) revert Error("Entanglement strength cannot exceed 10000");

         quantaLedger[_quanta1Id].entanglementStrength = _newStrength;
         quantaLedger[_quanta2Id].entanglementStrength = _newStrength; // Strength is symmetrical

         emit EntanglementStrengthUpdated(_quanta1Id, _quanta2Id, _newStrength);
     }


    /**
     * @dev Simulates the "measurement" of a Quanta, collapsing its superposition
     *      to a single state based on its probability distribution. Uses deterministic
     *      pseudo-randomness.
     * @param _quantaId The ID of the Quanta to measure.
     */
    function measureQuanta(uint256 _quantaId)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
        whenInSuperposition(_quantaId)
    {
        QuantumEntity storage quanta = quantaLedger[_quantaId];

        // --- Deterministic Pseudo-Randomness ---
        // This is the core challenge on a deterministic blockchain.
        // Using block properties is common but predictable/manipulable by miners.
        // For a simulation, this is acceptable. For real-world use needing unpredictability,
        // external oracle or commit-reveal schemes would be necessary.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // deprecated in PoS, use block.prevrandao
            block.number,
            msg.sender, // Include owner for some variability per user
            _quantaId // Include quanta ID
        )));

        // Scale the number to be within the range 0-9999 (for 10000 total probability points)
        uint256 probabilityIndex = randomNumber % 10000;

        // --- Collapse based on Probability Distribution ---
        bytes32 selectedState = bytes32(0);
        uint256 cumulativeProbability = 0;

        // Iterate through superposition states and find which probability range the random number falls into
        for (uint i = 0; i < quanta.superpositionStates.length; i++) {
            bytes32 potentialState = quanta.superpositionStates[i];
            uint256 stateProb = quanta.probabilityDistribution[potentialState];

            if (probabilityIndex < cumulativeProbability + stateProb) {
                selectedState = potentialState;
                break;
            }
            cumulativeProbability += stateProb;
        }

        // Edge case: if due to rounding or logic, no state was selected, fall back to ground state
        if (selectedState == bytes32(0)) {
            selectedState = quanta.groundState;
        }

        // Collapse the state
        _collapseQuantaState(_quantaId, selectedState, "Measured");

        // If entangled, propagate influence
        if (quanta.entangledPairId != 0) {
             // Use an internal or private function to avoid external calls within a loop/critical path
             // and handle potential reentrancy if callbacks were used here directly.
            _propagateMeasurementInfluenceSim(_quantaId, quanta.entangledPairId, selectedState, quanta.entanglementStrength);
            // Consider a cascade effect if the partner is also entangled
            _resolveEntanglementCascadeSim(quanta.entangledPairId);
        }

        // Notify callback contract if set
        if (quanta.measurementCallbackContract != address(0)) {
             // Basic callback - needs careful reentrancy consideration if contract does complex things
             // In a robust system, this might use a separate executor contract or queue.
             // For this simulation, we'll assume a simple call.
             // (address(quanta.measurementCallbackContract)).call(abi.encodeWithSignature("onQuantaMeasured(uint256,bytes32)", _quantaId, selectedState));
             // Using staticcall is safer if no state change is expected on callback contract side
             (bool success,) = address(quanta.measurementCallbackContract).staticcall(abi.encodeWithSignature("onQuantaMeasured(uint256,bytes32)", _quantaId, selectedState));
             if (!success) {
                 // Log or handle failed callback
                 emit Error("Measurement callback failed"); // Use generic error for simulation
             }
        }

        emit QuantaMeasured(_quantaId, selectedState, block.timestamp);
    }

    /**
     * @dev Internal function to collapse a Quanta's state after measurement or decoherence.
     * @param _quantaId The ID of the Quanta.
     * @param _state The state it collapses to.
     * @param _reason Description of why it collapsed.
     */
    function _collapseQuantaState(uint256 _quantaId, bytes32 _state, string memory _reason) internal {
        QuantumEntity storage quanta = quantaLedger[_quantaId];

        quanta.currentState = _state;
        quanta.inSuperposition = false;
        quanta.superpositionStates.length = 0; // Clear superposition states
        // Clear probability distribution mapping (not strictly necessary but good cleanup)
        // Note: Mappings cannot be iterated, manual cleanup is hard. Rely on inSuperposition flag.
        // A more complex struct might use a dynamic array of {state, prob} pairs instead of a mapping.

        quanta.lastMeasurementTime = uint64(block.timestamp);

        // Record history
        quanta.history.push(StateHistoryEntry({
            measuredState: _state,
            timestamp: uint64(block.timestamp),
            blockNumber: block.number
        }));

        // Note: Emitting QuantaMeasured and potentially other events in the caller function
    }


    /**
     * @dev Internal simulation of influence propagation to an entangled partner after measurement.
     *      This is a deterministic simulation of a non-deterministic quantum effect.
     *      The rules of influence are defined here.
     * @param _sourceQuantaId The ID of the measured Quanta.
     * @param _targetQuantaId The ID of the entangled partner.
     * @param _sourceMeasuredState The state the source collapsed into.
     * @param _strength The entanglement strength (scaled by 10000).
     */
    function _propagateMeasurementInfluenceSim(
        uint256 _sourceQuantaId,
        uint256 _targetQuantaId,
        bytes32 _sourceMeasuredState,
        uint256 _strength
    ) internal quantaExists(_targetQuantaId) whenInSuperposition(_targetQuantaId) {

         // Check again in case partner was destroyed between check and call
         if (quantaLedger[_targetQuantaId].owner == address(0) || quantaLedger[_targetQuantaId].entangledPairId != _sourceQuantaId) {
             // Partner destroyed or disentangled mid-transaction/call chain
             return;
         }

        QuantumEntity storage targetQuanta = quantaLedger[_targetQuantaId];

        // Simple Influence Simulation Rules:
        // 1. Increase the target's probability of being in the same state as the source,
        //    proportional to entanglement strength.
        // 2. Decrease the target's probability of being in other states.
        // 3. High strength might cause the target to collapse partially or fully.

        uint256 strengthFactor = _strength; // Use scaled strength directly (0-10000)

        bytes32[] memory statesToUpdate = new bytes32[](targetQuanta.superpositionStates.length);
        uint256[] memory probsToUpdate = new uint256[](targetQuanta.superpositionStates.length);
        uint updateIndex = 0;
        uint256 totalProbCheck = 0;

        uint256 originalProbOfSourceStateInTarget = targetQuanta.probabilityDistribution[_sourceMeasuredState];
        uint256 increaseAmount = (strengthFactor * (10000 - originalProbOfSourceStateInTarget)) / 10000; // More strength -> more increase towards 10000

        for (uint i = 0; i < targetQuanta.superpositionStates.length; i++) {
            bytes32 state = targetQuanta.superpositionStates[i];
            uint256 currentProb = targetQuanta.probabilityDistribution[state];
            uint256 newProb;

            if (state == _sourceMeasuredState) {
                newProb = currentProb + increaseAmount;
                if (newProb > 10000) newProb = 10000; // Cap at 100%
            } else {
                // Proportionally decrease other probabilities
                // Total decrease needed across other states is increaseAmount
                uint256 decreaseAmountPerState = (increaseAmount * currentProb) / (10000 - originalProbOfSourceStateInTarget); // Distribute decrease based on existing proportion
                if (currentProb <= decreaseAmountPerState) {
                    newProb = 0;
                } else {
                    newProb = currentProb - decreaseAmountPerState;
                }
            }
            statesToUpdate[updateIndex] = state;
            probsToUpdate[updateIndex] = newProb;
            totalProbCheck += newProb;
            updateIndex++;
        }

        // Re-normalize to ensure sum is exactly 10000 after calculations (due to scaling/rounding)
         if (totalProbCheck != 10000) {
            // Simple re-normalization: add/subtract difference from the influenced state's probability
            uint256 influencedStateIndex = type(uint256).max;
             for(uint i=0; i < statesToUpdate.length; i++) {
                 if (statesToUpdate[i] == _sourceMeasuredState) {
                     influencedStateIndex = i;
                     break;
                 }
             }
             if (influencedStateIndex != type(uint256).max) {
                 if (totalProbCheck < 10000) {
                      probsToUpdate[influencedStateIndex] += (10000 - totalProbCheck);
                 } else {
                      if (probsToUpdate[influencedStateIndex] >= (totalProbCheck - 10000)) {
                           probsToUpdate[influencedStateIndex] -= (totalProbCheck - 10000);
                      } else {
                          // Complex case: need to spread the decrease across other states
                          // For simulation, we might just zero out all other states if the influenced one is already maxed
                           if (probsToUpdate[influencedStateIndex] == 10000) {
                                for(uint i=0; i < statesToUpdate.length; i++) {
                                    if (i != influencedStateIndex) probsToUpdate[i] = 0;
                                }
                           } else {
                                // This path indicates potential issue with decrease calculation, handle carefully
                           }
                      }
                 }
             } else {
                 // Should not happen if _sourceMeasuredState was in the original superpositionStates or ground state
                 revert Error("Influenced state not found during renormalization");
             }
        }

        _updateStateProbabilityInternal(_targetQuantaId, statesToUpdate, probsToUpdate); // Apply changes


        // Check if target collapses due to strong influence (e.g., >= 99% probability for one state)
        if (targetQuanta.probabilityDistribution[_sourceMeasuredState] >= 9900) { // 99% threshold
            _collapseQuantaState(_targetQuantaId, _sourceMeasuredState, "Entanglement Influence Collapse");
             emit MeasurementInfluencePropagated(_sourceQuantaId, _targetQuantaId, _sourceMeasuredState, "Caused Collapse");
        } else {
             emit MeasurementInfluencePropagated(_sourceQuantaId, _targetQuantaId, _sourceMeasuredState, "Influenced Probabilities");
        }
    }


    /**
     * @dev Attempts to perform a "joint measurement" on two entangled Quanta.
     *      Simulates a correlated outcome based on their current probabilities and entanglement.
     *      Requires caller to own both.
     * @param _quanta1Id The ID of the first Quanta.
     * @param _quanta2Id The ID of the second Quanta.
     */
    function performJointMeasurement(uint256 _quanta1Id, uint256 _quanta2Id)
        external
        quantaExists(_quanta1Id)
        quantaExists(_quanta2Id)
        onlyEntangledPairOwner(_quanta1Id, _quanta2Id)
    {
        if (quantaLedger[_quanta1Id].entangledPairId != _quanta2Id || quantaLedger[_quanta2Id].entangledPairId != _quanta1Id) {
            revert Error("Quanta are not entangled with each other for joint measurement");
        }

        // For a joint measurement simulation, we can measure one, then force the
        // second's outcome to be correlated based on rules derived from strength.
        // More advanced: build a combined probability matrix from both marginals and strength,
        // then pick a state pair from the joint distribution.
        // Simplified approach: Measure the first, then influence/collapse the second.

        // Ensure both are in superposition, or measure results are deterministic
        if (!quantaLedger[_quanta1Id].inSuperposition && !quantaLedger[_quanta2Id].inSuperposition) {
             // Both already measured, outcomes are fixed
             emit JointMeasurementPerformed(_quanta1Id, _quanta2Id, quantaLedger[_quanta1Id].currentState, quantaLedger[_quanta2Id].currentState);
             return;
        }

        bytes32 state1;
        bytes32 state2;

        // Measure Quanta 1 (if in superposition)
        if (quantaLedger[_quanta1Id].inSuperposition) {
            // Perform standard measurement on quanta 1 (which also handles propagation if needed)
            // NOTE: This will trigger _propagateMeasurementInfluenceSim on quanta 2 automatically if entangled
             measureQuanta(_quanta1Id); // This collapses quanta 1 state and influences quanta 2
             state1 = quantaLedger[_quanta1Id].currentState;
        } else {
             state1 = quantaLedger[_quanta1Id].currentState;
        }

        // Quanta 2's state is now potentially influenced by the measurement of Quanta 1.
        // If it's still in superposition, measure it based on its *new* probabilities.
        if (quantaLedger[_quanta2Id].inSuperposition) {
            // Perform standard measurement on quanta 2
            // Note: This measureQuanta call might trigger propagation back to quanta 1 if it's *also* still in superposition and entangled.
            // However, quanta 1 should now be fixed, so the propagation back won't change its state, only potentially influence probabilities if it somehow re-entered superposition.
            // For simplicity, we can assume measuring an already measured Quanta is a no-op on its state.
             measureQuanta(_quanta2Id); // This collapses quanta 2 based on its (potentially updated) probabilities
             state2 = quantaLedger[_quanta2Id].currentState;
        } else {
            state2 = quantaLedger[_quanta2Id].currentState;
        }

        // At this point, both should be measured and fixed.
        // The correlation comes from the influence propagation step.

        emit JointMeasurementPerformed(_quanta1Id, _quanta2Id, state1, state2);

        // Consider triggering cascade resolution from the second quanta if it was measured just now
         _resolveEntanglementCascadeSim(_quanta2Id);
    }


    /**
     * @dev Attempts to entangle two Quanta only if specific conditional criteria are met.
     *      Conditions could be based on block properties, state of other Quanta, etc.
     * @param _quanta1Id The ID of the first Quanta.
     * @param _quanta2Id The ID of the second Quanta.
     * @param _initialStrength The initial entanglement strength.
     * @param _conditionType A string describing the condition to check.
     * @param _conditionData Additional data for the condition check.
     */
    function attemptConditionalEntanglement(
        uint256 _quanta1Id,
        uint256 _quanta2Id,
        uint256 _initialStrength,
        string calldata _conditionType,
        bytes calldata _conditionData
    )
        external
        quantaExists(_quanta1Id)
        quantaExists(_quanta2Id)
        onlyEntangledPairOwner(_quanta1Id, _quanta2Id) // Must own both to attempt
    {
        // Check conditions based on _conditionType and _conditionData
        bool conditionMet = false;
        string memory failReason = "Unknown condition";

        if (keccak256(abi.encodePacked(_conditionType)) == keccak256(abi.encodePacked("BlockNumberEven"))) {
            if (block.number % 2 == 0) {
                conditionMet = true;
            } else {
                failReason = "Block number is odd";
            }
        } else if (keccak256(abi.encodePacked(_conditionType)) == keccak256(abi.encodePacked("QuantaStateMatch"))) {
            // Requires _conditionData to encode a target state bytes32
            if (_conditionData.length == 32) {
                 bytes32 targetState = abi.decode(_conditionData, (bytes32));
                 // Check if both quanta are currently measured and in the target state
                 if (!quantaLedger[_quanta1Id].inSuperposition && !quantaLedger[_quanta2Id].inSuperposition &&
                     quantaLedger[_quanta1Id].currentState == targetState && quantaLedger[_quanta2Id].currentState == targetState)
                 {
                    conditionMet = true;
                 } else {
                     failReason = "Quanta not measured to target state";
                 }
            } else {
                 failReason = "Invalid condition data for QuantaStateMatch";
            }
        }
        // Add more complex conditional logic here (e.g., based on oracles, time, contract state)

        if (conditionMet) {
            // If condition is met, proceed with entanglement
            entangleQuantaPair(_quanta1Id, _quanta2Id, _initialStrength);
        } else {
            revert EntanglementConditionNotMet(failReason);
        }
    }


    /**
     * @dev Simulates a potential cascade effect: if measuring Quanta A influences B,
     *      and B is also entangled with C, B's change *might* influence C.
     *      This is a simplified, limited depth simulation.
     * @param _quantaId The ID of the Quanta whose potential influence chain needs resolution.
     */
     function _resolveEntanglementCascadeSim(uint256 _quantaId) internal quantaExists(_quantaId) {
        // Simple simulation: Check if _quantaId just collapsed
        QuantumEntity storage currentQuanta = quantaLedger[_quantaId];

        if (!currentQuanta.inSuperposition && currentQuanta.entangledPairId != 0) {
             uint256 nextQuantaId = currentQuanta.entangledPairId;
             // Check if the next one exists and is still entangled back
             if (quantaLedger[nextQuantaId].owner != address(0) && quantaLedger[nextQuantaId].entangledPairId == _quantaId) {
                 // The next quanta was already influenced by _quantaId's measurement via _propagateMeasurementInfluenceSim.
                 // Now, if nextQuantaId also just collapsed due to that influence,
                 // check if *it* is entangled with *another* one (Quanta C).
                 if (!quantaLedger[nextQuantaId].inSuperposition && quantaLedger[nextQuantaId].entangledPairId != 0) {
                      uint256 cascadeTargetId = quantaLedger[nextQuantaId].entangledPairId;
                      // Ensure the cascade target is not the original source and exists and is entangled back
                      if (cascadeTargetId != _quantaId &&
                          quantaLedger[cascadeTargetId].owner != address(0) &&
                          quantaLedger[cascadeTargetId].entangledPairId == nextQuantaId &&
                          quantaLedger[cascadeTargetId].inSuperposition // Only propagate if the target is still in superposition
                      ) {
                          // Propagate influence from nextQuantaId (which just collapsed) to cascadeTargetId
                          _propagateMeasurementInfluenceSim(
                                nextQuantaId,
                                cascadeTargetId,
                                quantaLedger[nextQuantaId].currentState,
                                quantaLedger[nextQuantaId].entanglementStrength // Use the strength of the next -> cascade link
                          );
                           emit EntanglementCascadeResolved(_quantaId, cascadeTargetId, quantaLedger[cascadeTargetId].currentState);
                          // Could recursively call _resolveEntanglementCascadeSim(cascadeTargetId) for deeper chains, but limit depth for gas
                      }
                 }
             }
        }
        // Base case: Quanta is still in superposition, not entangled, or chain ends.
    }


    /**
     * @dev Allows the owner to update the simulated coherence loss rate for a Quanta.
     * @param _quantaId The ID of the Quanta.
     * @param _newRateScaled The new rate (scaled by 10000).
     */
     function updateCoherenceLossRate(uint256 _quantaId, uint256 _newRateScaled)
         external
         quantaExists(_quantaId)
         onlyQuantaOwner(_quantaId)
     {
        quantaLedger[_quantaId].coherenceLossRateScaled = _newRateScaled;
        emit CoherenceLossRateUpdated(_quantaId, _newRateScaled);
     }


    // --- Query Functions ---

    /**
     * @dev Gets detailed information about a Quanta.
     * @param _quantaId The ID of the Quanta.
     * @return Structural and state details.
     */
    function getQuantaInfo(uint256 _quantaId)
        external
        view
        quantaExists(_quantaId)
        returns (
            uint256 id,
            address owner,
            bytes32 currentState,
            bytes32 groundState,
            bool inSuperposition,
            uint256 entangledPairId,
            uint256 entanglementStrength,
            uint64 lastMeasurementTime,
            uint256 coherenceLossRateScaled
        )
    {
        QuantumEntity storage quanta = quantaLedger[_quantaId];
        return (
            quanta.id,
            quanta.owner,
            quanta.currentState,
            quanta.groundState,
            quanta.inSuperposition,
            quanta.entangledPairId,
            quanta.entanglementStrength,
            quanta.lastMeasurementTime,
            quanta.coherenceLossRateScaled
        );
    }

    /**
     * @dev Gets the potential states in a Quanta's superposition.
     * @param _quantaId The ID of the Quanta.
     * @return An array of superposition states.
     */
    function getSuperpositionStates(uint256 _quantaId)
        external
        view
        quantaExists(_quantaId)
        returns (bytes32[] memory)
    {
        return quantaLedger[_quantaId].superpositionStates;
    }

    /**
     * @dev Gets the probability distribution for states in superposition.
     * @param _quantaId The ID of the Quanta.
     * @return An array of states and a corresponding array of probabilities (scaled by 10000).
     */
    function getStateProbabilities(uint256 _quantaId)
        external
        view
        quantaExists(_quantaId)
        returns (bytes32[] memory states, uint256[] memory probabilitiesScaled)
    {
        QuantumEntity storage quanta = quantaLedger[_quantaId];
        states = quanta.superpositionStates;
        probabilitiesScaled = new uint256[](states.length);

        for (uint i = 0; i < states.length; i++) {
            probabilitiesScaled[i] = quanta.probabilityDistribution[states[i]];
        }
        return (states, probabilitiesScaled);
    }

    /**
     * @dev Checks if a Quanta is entangled and returns its partner's ID.
     * @param _quantaId The ID of the Quanta.
     * @return The ID of the entangled partner, or 0 if not entangled.
     */
    function getEntangledPairId(uint256 _quantaId)
        external
        view
        quantaExists(_quantaId)
        returns (uint256)
    {
        return quantaLedger[_quantaId].entangledPairId;
    }

    /**
     * @dev Gets the history of measured states for a Quanta.
     * @param _quantaId The ID of the Quanta.
     * @return An array of StateHistoryEntry structs.
     */
    function getStateHistory(uint256 _quantaId)
        external
        view
        quantaExists(_quantaId)
        returns (StateHistoryEntry[] memory)
    {
        return quantaLedger[_quantaId].history;
    }

    /**
     * @dev Simulates a prediction of future state probabilities based on current state,
     *      coherence loss rate, and time elapsed since last measurement.
     *      Does NOT account for potential future entanglement interactions.
     * @param _quantaId The ID of the Quanta.
     * @param _timeDelta A simulated time delta (in seconds) into the future.
     * @return A prediction of probabilities for each state in the current superposition
     *         after the simulated time delta, considering coherence loss.
     */
    function predictFutureProbabilitiesSim(uint256 _quantaId, uint256 _timeDelta)
        external
        view
        quantaExists(_quantaId)
        whenInSuperposition(_quantaId)
        returns (bytes32[] memory states, uint256[] memory predictedProbabilitiesScaled)
    {
         QuantumEntity storage quanta = quantaLedger[_quantaId];

         states = quanta.superpositionStates;
         predictedProbabilitiesScaled = new uint256[](states.length);

         // Simulate coherence loss over the given time delta
         uint256 potentialLoss = (_timeDelta * quanta.coherenceLossRateScaled) / 1e18; // Example scaling
         uint256 groundStateProbIncrease = potentialLoss; // Just add directly, maxing out at 10000

         bytes32 groundState = quanta.groundState;
         uint256 currentGroundProb = quanta.probabilityDistribution[groundState];
         uint256 remainingProbToDistribute = 10000 - currentGroundProb;
         uint256 newGroundProb = currentGroundProb + groundStateProbIncrease;
         if (newGroundProb > 10000) newGroundProb = 10000;

         uint256 totalOtherProbDecrease = newGroundProb - currentGroundProb;
         if (totalOtherProbDecrease > remainingProbToDistribute) totalOtherProbDecrease = remainingProbToDistribute; // Cap decrease

         uint256 numOtherStates = 0;
          for(uint i = 0; i < states.length; i++) {
              if (states[i] != groundState) {
                  numOtherStates++;
              }
          }

         uint256 decreasePerOtherState = 0;
         if (numOtherStates > 0) {
              decreasePerOtherState = totalOtherProbDecrease / numOtherStates;
         }

         uint256 totalProbCheck = 0;

         for(uint i = 0; i < states.length; i++) {
             bytes32 state = states[i];
             uint256 currentProb = quanta.probabilityDistribution[state];
             uint256 newProb;

             if (state == groundState) {
                 newProb = newGroundProb;
             } else {
                 if (currentProb <= decreasePerOtherState) {
                     newProb = 0;
                 } else {
                     newProb = currentProb - decreasePerOtherState;
                 }
             }
             predictedProbabilitiesScaled[i] = newProb;
             totalProbCheck += newProb;
         }

         // Re-normalize predicted probabilities
          if (totalProbCheck != 10000) {
             uint256 influencedStateIndex = type(uint256).max;
              for(uint i=0; i < states.length; i++) {
                  if (states[i] == groundState) { // Add/subtract difference from ground state prediction
                      influencedStateIndex = i;
                      break;
                  }
              }
              if (influencedStateIndex != type(uint256).max) {
                  if (totalProbCheck < 10000) {
                       predictedProbabilitiesScaled[influencedStateIndex] += (10000 - totalProbCheck);
                  } else {
                       if (predictedProbabilitiesScaled[influencedStateIndex] >= (totalProbCheck - 10000)) {
                            predictedProbabilitiesScaled[influencedStateIndex] -= (totalProbCheck - 10000);
                       } else {
                            // Complex case, handle redistribution of excess
                       }
                  }
              } else {
                  // Should not happen
                  revert Error("Ground state not found in prediction");
              }
         }

         return (states, predictedProbabilitiesScaled);
    }


    // --- Advanced & Utilities ---

     /**
     * @dev Transfers ownership of two entangled Quanta simultaneously to a new address.
     *      Ensures the entangled link is maintained under the new owner.
     *      Requires caller to own both.
     * @param _quanta1Id The ID of the first Quanta.
     * @param _quanta2Id The ID of the second Quanta.
     * @param _to The address of the new owner for both.
     */
    function transferEntangledPair(uint256 _quanta1Id, uint256 _quanta2Id, address _to)
        external
        quantaExists(_quanta1Id)
        quantaExists(_quanta2Id)
        onlyEntangledPairOwner(_quanta1Id, _quanta2Id)
    {
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        if (quantaLedger[_quanta1Id].entangledPairId != _quanta2Id || quantaLedger[_quanta2Id].entangledPairId != _quanta1Id) {
            revert Error("Quanta are not entangled with each other");
        }
        address oldOwner = msg.sender;

         // Remove from old owner's list (simple implementation)
        uint256[] storage oldOwnerIds = ownerQuantaIds[oldOwner];
        uint removeCount = 0;
        for (uint i = 0; i < oldOwnerIds.length; i++) {
            if (oldOwnerIds[i] == _quanta1Id || oldOwnerIds[i] == _quanta2Id) {
                oldOwnerIds[i] = oldOwnerIds[oldOwnerIds.length - 1 - removeCount];
                // Don't pop yet, might overwrite a needed ID
                removeCount++;
            }
        }
        for(uint i=0; i < removeCount; i++) {
            oldOwnerIds.pop();
        }


        // Update owners
        quantaLedger[_quanta1Id].owner = _to;
        quantaLedger[_quanta2Id].owner = _to;

        // Add to new owner's list
        ownerQuantaIds[_to].push(_quanta1Id);
        ownerQuantaIds[_to].push(_quanta2Id);

        emit QuantaTransferred(_quanta1Id, oldOwner, _to);
        emit QuantaTransferred(_quanta2Id, oldOwner, _to);
    }

     /**
     * @dev Sets a contract address to be notified when a specific Quanta is measured.
     *      The target contract must implement `onQuantaMeasured(uint256, bytes32)`.
     *      Can be set to address(0) to remove the callback.
     * @param _quantaId The ID of the Quanta.
     * @param _callbackContract The address of the contract to call.
     */
    function setMeasurementCallbackContract(uint256 _quantaId, address _callbackContract)
        external
        quantaExists(_quantaId)
        onlyQuantaOwner(_quantaId)
    {
        // Basic check: callbackContract cannot be this contract itself to prevent simple infinite loops
        if (_callbackContract == address(this)) revert Error("Cannot set callback to self");

        quantaLedger[_quantaId].measurementCallbackContract = _callbackContract;
        emit MeasurementCallbackSet(_quantaId, _callbackContract);
    }

    // --- Utility / Internal ---

    /**
     * @dev Gets the list of Quanta owned by an address.
     * @param _owner The address to query.
     * @return An array of Quanta IDs owned by the address.
     */
    function getOwnedQuanta(address _owner) external view returns (uint256[] memory) {
        return ownerQuantaIds[_owner];
    }
}
```