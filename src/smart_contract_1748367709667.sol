Okay, let's create a smart contract with a creative and advanced concept, avoiding common patterns. We'll design a contract that simulates a "Quantum State Management Nexus," allowing users to create, manipulate, entangle, measure, and observe "quantum-inspired" data states on-chain.

The core concepts are:
1.  **Quantum State:** Data points that exist in different conceptual states (Superposition, Entangled, Measured, Decohered).
2.  **Superposition:** A state where the data can be manipulated by "gates."
3.  **Entanglement:** Linking two or more states such that manipulating one might affect others (conceptually, implemented via state requirements and shared status).
4.  **Measurement:** Collapsing a state from Superposition/Entangled into a final, immutable state (Measured).
5.  **Decoherence:** A time-based process where states left in Superposition/Entangled states for too long decay into a stable but unmeasurable state (Decohered).
6.  **Quantum Gates:** Functions that apply transformations to states in Superposition or Entangled states.
7.  **Nexus:** The central contract managing these states.

This requires complex state transitions, timestamp logic, mapping management, and unique function definitions beyond standard patterns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// --- Contract Outline: QuantumNexus ---
// A smart contract simulating a quantum-inspired state management system.
// It allows users to create, manipulate (via 'gates'), entangle, measure,
// and observe data states that transition through different conceptual phases:
// Superposition, Entangled, Measured, and Decohered.
// Features include:
// - Creation and identification of unique states.
// - Applying various "quantum gates" to states in Superposition or Entangled states.
// - Linking states through "entanglement".
// - "Measuring" states to finalize their data and status.
// - Automatic (trigger-based) "decoherence" of transient states based on time.
// - Comprehensive view functions to inspect state properties and status.
// - Basic ownership and administrative controls.

// --- Function Summary ---
// 1.  constructor() - Initializes the contract owner and sets a default decoherence duration.
// 2.  setDecoherenceDuration(uint256 duration) - Admin function to set the time limit for superposition/entanglement before decoherence.
// 3.  transferOwnership(address newOwner) - Admin function to transfer contract ownership.
// 4.  renounceOwnership() - Admin function to renounce contract ownership.
// 5.  createQuantumState(uint256 initialData) - Creates a new state initialized in Superposition with given data.
// 6.  batchCreateQuantumStates(uint256[] calldata initialDataArray) - Creates multiple states from an array of initial data.
// 7.  entangleStates(uint256 stateId1, uint256 stateId2) - Links two states, transitioning them to Entangled status if they were in Superposition.
// 8.  disentangleStates(uint256 stateId1, uint256 stateId2) - Removes the entanglement link between two states.
// 9.  measureState(uint256 stateId) - Measures a state, finalizing its data and transitioning it to Measured status. Collapses entanglement.
// 10. triggerDecoherence(uint256[] calldata stateIds) - Processes provided state IDs, transitioning those in Superposition or Entangled past their time limit to Decohered.
// 11. applyHadamardGate(uint256 stateId) - Applies a conceptual Hadamard-like transformation to a state's data.
// 12. applyPauliXGate(uint256 stateId) - Applies a conceptual Pauli-X (NOT) transformation.
// 13. applyPauliYGate(uint256 stateId) - Applies a conceptual Pauli-Y transformation.
// 14. applyPauliZGate(uint256 stateId) - Applies a conceptual Pauli-Z transformation.
// 15. applyPhaseShiftGate(uint256 stateId, uint256 phase) - Applies a conceptual phase shift based on the phase parameter.
// 16. applyControlledGate(uint256 controlStateId, uint256 targetStateId) - Applies a gate to targetStateId based on a condition of controlStateId's data.
// 17. applySwapGate(uint256 stateId1, uint256 stateId2) - Swaps the data between two states.
// 18. applyCustomGate(uint256 stateId, uint256 transformationType, uint256 parameter) - A generic gate function allowing custom transformations based on parameters.
// 19. getQuantumState(uint256 stateId) - View function to get all details of a specific state.
// 20. getData(uint256 stateId) - View function to get the data of a specific state.
// 21. getStatus(uint256 stateId) - View function to get the status of a specific state.
// 22. getCreationTimestamp(uint256 stateId) - View function to get the creation timestamp.
// 23. getMeasurementTimestamp(uint256 stateId) - View function to get the measurement timestamp (0 if not measured).
// 24. isEntangled(uint256 stateId1, uint256 stateId2) - View function to check if two states are entangled.
// 25. getDecoherenceDuration() - View function to get the current decoherence duration.
// 26. getTotalStates() - View function to get the total number of states created.
// 27. getStatesByStatus(StateStatus status) - View function (limited iteration) to find states with a specific status. (Note: Iterating over mappings is gas-intensive; this is a simplified version or for limited numbers).
// 28. getSuperpositionStates() - Alias for getStatesByStatus(Superposition).
// 29. getEntangledStatesList() - Alias for getStatesByStatus(Entangled).
// 30. getMeasuredStates() - Alias for getStatesByStatus(Measured).
// 31. getDecoheredStates() - Alias for getStatesByStatus(Decohered).
// 32. withdrawEther() - Allows the owner to withdraw any accumulated Ether (e.g., from accidental sends).

contract QuantumNexus {

    address private owner;

    enum StateStatus { Superposition, Entangled, Measured, Decohered }

    struct QuantumState {
        StateStatus status;
        uint256 data;
        uint256 creationTimestamp;
        uint256 measurementTimestamp; // 0 if not measured
    }

    mapping(uint256 => QuantumState) private states;
    uint256 private nextStateId; // Counter for unique state IDs

    // Mapping to track entanglement links. Adjacency list style.
    // Note: Managing dynamic arrays in mappings for large numbers is complex/costly.
    // This implementation assumes a moderate number of entangled pairs, and entanglement
    // status is primarily derived from the main QuantumState struct's 'Entangled' status.
    // The mapping primarily supports the `isEntangled` view function and helps manage links conceptually.
    // A more robust system might use separate data structures or enforce limits.
    mapping(uint256 => uint256[]) private entangledLinks;

    uint256 public decoherenceDuration; // Time in seconds before superposition/entanglement decays

    event StateCreated(uint256 stateId, uint256 initialData, uint256 timestamp);
    event StateStatusChanged(uint256 stateId, StateStatus oldStatus, StateStatus newStatus, uint256 timestamp);
    event DataTransformed(uint256 stateId, uint256 oldData, uint256 newData, string gateApplied);
    event StatesEntangled(uint256 stateId1, uint256 stateId2, uint256 timestamp);
    event StatesDisentangled(uint256 stateId1, uint256 stateId2, uint256 timestamp);
    event StateMeasured(uint256 stateId, uint256 finalData, uint256 timestamp);
    event StateDecohered(uint256 stateId, uint256 timestamp);
    event DecoherenceDurationUpdated(uint256 newDuration, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyTransientState(uint256 stateId) {
        require(states[stateId].status == StateStatus.Superposition || states[stateId].status == StateStatus.Entangled, "State must be in Superposition or Entangled");
        _;
    }

    modifier stateExists(uint256 stateId) {
        require(stateId > 0 && stateId < nextStateId, "State does not exist");
        _;
    }

    modifier onlySuperpositionState(uint256 stateId) {
         require(states[stateId].status == StateStatus.Superposition, "State must be in Superposition");
         _;
    }

    constructor() {
        owner = msg.sender;
        decoherenceDuration = 1 days; // Default: 1 day
        nextStateId = 1; // Start IDs from 1
        emit OwnershipTransferred(address(0), owner);
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the duration after which a state in Superposition or Entangled will decohere.
     * @param duration The new decoherence duration in seconds.
     */
    function setDecoherenceDuration(uint256 duration) external onlyOwner {
        decoherenceDuration = duration;
        emit DecoherenceDurationUpdated(duration, block.timestamp);
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Renounces ownership of the contract.
     * The owner address will be set to zero, and no future owner can be set.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

     /**
     * @dev Withdraws any Ether held by the contract (e.g., accidental sends).
     * Only the owner can withdraw.
     */
    function withdrawEther() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Ether withdrawal failed");
    }


    // --- State Creation ---

    /**
     * @dev Creates a new quantum state in the Superposition status.
     * @param initialData The initial data value for the state.
     * @return The ID of the newly created state.
     */
    function createQuantumState(uint256 initialData) external returns (uint256) {
        uint256 newStateId = nextStateId++;
        states[newStateId] = QuantumState({
            status: StateStatus.Superposition,
            data: initialData,
            creationTimestamp: block.timestamp,
            measurementTimestamp: 0
        });
        emit StateCreated(newStateId, initialData, block.timestamp);
        return newStateId;
    }

    /**
     * @dev Creates multiple quantum states in a batch.
     * @param initialDataArray An array of initial data values for the states.
     * @return An array of the IDs of the newly created states.
     */
    function batchCreateQuantumStates(uint256[] calldata initialDataArray) external returns (uint256[] memory) {
        uint256[] memory newIds = new uint256[](initialDataArray.length);
        for (uint i = 0; i < initialDataArray.length; i++) {
            newIds[i] = createQuantumState(initialDataArray[i]);
        }
        return newIds;
    }


    // --- Entanglement Management ---

    /**
     * @dev Conceptually entangles two quantum states.
     * Both states must exist and be in Superposition.
     * Transitions both states to Entangled status.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     */
    function entangleStates(uint256 stateId1, uint256 stateId2) external stateExists(stateId1) stateExists(stateId2) {
        require(stateId1 != stateId2, "Cannot entangle a state with itself");
        require(states[stateId1].status == StateStatus.Superposition, "State 1 must be in Superposition to entangle");
        require(states[stateId2].status == StateStatus.Superposition, "State 2 must be in Superposition to entangle");

        // Update status
        states[stateId1].status = StateStatus.Entangled;
        states[stateId2].status = StateStatus.Entangled;
        emit StateStatusChanged(stateId1, StateStatus.Superposition, StateStatus.Entangled, block.timestamp);
        emit StateStatusChanged(stateId2, StateStatus.Superposition, StateStatus.Entangled, block.timestamp);

        // Record entanglement links (for conceptual tracking and `isEntangled`)
        // Check if already linked to avoid duplicates (simple search in array - potentially costly)
        bool alreadyLinked1 = false;
        for(uint i = 0; i < entangledLinks[stateId1].length; i++) {
            if (entangledLinks[stateId1][i] == stateId2) {
                alreadyLinked1 = true;
                break;
            }
        }
         if (!alreadyLinked1) {
            entangledLinks[stateId1].push(stateId2);
            entangledLinks[stateId2].push(stateId1); // Symmetric link
            emit StatesEntangled(stateId1, stateId2, block.timestamp);
        }
    }

    /**
     * @dev Conceptually disentangles two quantum states.
     * Both states must exist and be in Entangled status and actually linked.
     * If a state is no longer entangled with *anything* after this, its status
     * could conceptually revert to Superposition, but for simplicity,
     * we'll keep them as Entangled until measured or decohered, reflecting the history.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     */
    function disentangleStates(uint256 stateId1, uint256 stateId2) external stateExists(stateId1) stateExists(stateId2) {
        require(stateId1 != stateId2, "Cannot disentangle a state from itself");
        require(states[stateId1].status == StateStatus.Entangled, "State 1 must be in Entangled status");
        require(states[stateId2].status == StateStatus.Entangled, "State 2 must be in Entangled status");
        require(isEntangled(stateId1, stateId2), "States are not currently entangled");

        // Remove links (simple but potentially inefficient array manipulation)
        uint256[] storage links1 = entangledLinks[stateId1];
        for (uint i = 0; i < links1.length; i++) {
            if (links1[i] == stateId2) {
                links1[i] = links1[links1.length - 1];
                links1.pop();
                break;
            }
        }

        uint256[] storage links2 = entangledLinks[stateId2];
        for (uint i = 0; i < links2.length; i++) {
            if (links2[i] == stateId1) {
                links2[i] = links2[links2.length - 1];
                links2.pop();
                break;
            }
        }

        // Note: Status remains Entangled until Measure/Decohere for simplicity.
        // A more complex model might revert to Superposition if no links remain.
        emit StatesDisentangled(stateId1, stateId2, block.timestamp);
    }


    // --- Measurement and Decoherence ---

    /**
     * @dev Measures a quantum state, collapsing its superposition/entanglement.
     * The state must exist and be in Superposition or Entangled.
     * Transitions the state to Measured, finalizes its data, and records the measurement time.
     * Conceptually breaks entanglement links involving this state.
     * @param stateId The ID of the state to measure.
     */
    function measureState(uint256 stateId) external stateExists(stateId) onlyTransientState(stateId) {
        QuantumState storage state = states[stateId];
        StateStatus oldStatus = state.status;

        // Simulate collapse - data is finalized as is
        state.status = StateStatus.Measured;
        state.measurementTimestamp = block.timestamp;

        // Conceptually disentangle from all states
        uint256[] memory linkedStates = entangledLinks[stateId]; // Copy array before modifying mapping
        delete entangledLinks[stateId]; // Remove all links from this state

        for (uint i = 0; i < linkedStates.length; i++) {
             uint256 linkedId = linkedStates[i];
             if (states[linkedId].status == StateStatus.Entangled) { // Only process if the other end is still entangled
                 uint256[] storage otherLinks = entangledLinks[linkedId];
                  for (uint j = 0; j < otherLinks.length; j++) {
                     if (otherLinks[j] == stateId) {
                         otherLinks[j] = otherLinks[otherLinks.length - 1];
                         otherLinks.pop();
                         break;
                     }
                 }
                 // Optional: If linkedId is no longer entangled with *anything*, revert its status?
                 // For this contract, we keep it Entangled until measured/decohered itself.
             }
        }


        emit StateStatusChanged(stateId, oldStatus, StateStatus.Measured, block.timestamp);
        emit StateMeasured(stateId, state.data, block.timestamp);
    }

    /**
     * @dev Triggers the decoherence process for a list of states.
     * Checks if states in Superposition or Entangled have exceeded the decoherenceDuration.
     * Transitions expired states to Decohered status.
     * This function is designed to be called externally (e.g., by a bot) to process state decay.
     * @param stateIds An array of state IDs to check for decoherence.
     */
    function triggerDecoherence(uint256[] calldata stateIds) external {
        uint256 currentTime = block.timestamp;
        for (uint i = 0; i < stateIds.length; i++) {
            uint256 stateId = stateIds[i];
             // Check if state exists and is in a transient state
            if (stateId > 0 && stateId < nextStateId) {
                QuantumState storage state = states[stateId];
                if ((state.status == StateStatus.Superposition || state.status == StateStatus.Entangled) &&
                    (currentTime >= state.creationTimestamp + decoherenceDuration))
                {
                    StateStatus oldStatus = state.status;
                    state.status = StateStatus.Decohered;
                    // Decohered states also conceptually break entanglement links
                     delete entangledLinks[stateId]; // Remove all links from this state

                    // Also remove links from the other ends (similar to measurement)
                     // Note: need to get linked states BEFORE deleting entangledLinks[stateId]
                    // Re-implementing link removal logic for clarity here
                     uint256[] memory linkedStates = new uint256[](entangledLinks[stateId].length);
                     for(uint k = 0; k < entangledLinks[stateId].length; k++) linkedStates[k] = entangledLinks[stateId][k]; // Copy
                     delete entangledLinks[stateId]; // Now delete

                    for (uint j = 0; j < linkedStates.length; j++) {
                         uint256 linkedId = linkedStates[j];
                         if (states[linkedId].status == StateStatus.Entangled) {
                             uint256[] storage otherLinks = entangledLinks[linkedId];
                              for (uint l = 0; l < otherLinks.length; l++) {
                                 if (otherLinks[l] == stateId) {
                                     otherLinks[l] = otherLinks[otherLinks.length - 1];
                                     otherLinks.pop();
                                     break;
                                 }
                             }
                         }
                    }

                    emit StateStatusChanged(stateId, oldStatus, StateStatus.Decohered, currentTime);
                    emit StateDecohered(stateId, currentTime);
                }
            }
        }
    }


    // --- Quantum Gate Transformations (Conceptual) ---
    // These functions apply transformations only to states in Superposition or Entangled states.
    // The transformations are simplified mathematical operations on a uint256.

    /**
     * @dev Applies a conceptual Hadamard-like transformation to a state's data.
     * Affects states in Superposition or Entangled status.
     * (Simplified: e.g., bitwise NOT)
     * @param stateId The ID of the state to transform.
     */
    function applyHadamardGate(uint256 stateId) external stateExists(stateId) onlyTransientState(stateId) {
         QuantumState storage state = states[stateId];
         uint256 oldData = state.data;
         state.data = ~state.data; // Simple bitwise NOT as conceptual example
         emit DataTransformed(stateId, oldData, state.data, "Hadamard");
    }

    /**
     * @dev Applies a conceptual Pauli-X (NOT) transformation.
     * Affects states in Superposition or Entangled status.
     * (Simplified: e.g., addition/subtraction or XOR)
     * @param stateId The ID of the state to transform.
     */
    function applyPauliXGate(uint256 stateId) external stateExists(stateId) onlyTransientState(stateId) {
        QuantumState storage state = states[stateId];
        uint256 oldData = state.data;
        state.data = state.data ^ type(uint256).max; // Simple XOR with max value as conceptual example
         emit DataTransformed(stateId, oldData, state.data, "PauliX");
    }

     /**
     * @dev Applies a conceptual Pauli-Y transformation.
     * Affects states in Superposition or Entangled status.
     * (Simplified: e.g., multiplication/division or shift)
     * @param stateId The ID of the state to transform.
     */
    function applyPauliYGate(uint256 stateId) external stateExists(stateId) onlyTransientState(stateId) {
        QuantumState storage state = states[stateId];
        uint256 oldData = state.data;
        // Conceptual: shift bits and maybe XOR
        state.data = (state.data << 1) ^ (state.data >> 1);
         emit DataTransformed(stateId, oldData, state.data, "PauliY");
    }

     /**
     * @dev Applies a conceptual Pauli-Z transformation.
     * Affects states in Superposition or Entangled status.
     * (Simplified: e.g., conditional negation/transformation)
     * @param stateId The ID of the state to transform.
     */
    function applyPauliZGate(uint256 stateId) external stateExists(stateId) onlyTransientState(stateId) {
        QuantumState storage state = states[stateId];
        uint256 oldData = state.data;
        // Conceptual: If data is 'odd', apply transformation.
        if (state.data % 2 != 0) {
            state.data = state.data * 3 + 1; // Collatz-like transformation as a simple example
        }
         emit DataTransformed(stateId, oldData, state.data, "PauliZ");
    }

     /**
     * @dev Applies a conceptual phase shift to a state's data.
     * Affects states in Superposition or Entangled status.
     * (Simplified: e.g., modular arithmetic or addition)
     * @param stateId The ID of the state to transform.
     * @param phase A parameter influencing the shift.
     */
    function applyPhaseShiftGate(uint256 stateId, uint256 phase) external stateExists(stateId) onlyTransientState(stateId) {
        QuantumState storage state = states[stateId];
        uint256 oldData = state.data;
        // Conceptual: Add phase, wrap around a large number
        state.data = (state.data + phase) % type(uint256).max;
         emit DataTransformed(stateId, oldData, state.data, "PhaseShift");
    }

    /**
     * @dev Applies a controlled gate. Transforms targetStateId based on a condition of controlStateId.
     * Both states must exist and be in Superposition or Entangled status.
     * (Simplified: e.g., If control data is > 100, apply PauliX to target data)
     * @param controlStateId The ID of the control state.
     * @param targetStateId The ID of the state to be transformed.
     */
    function applyControlledGate(uint256 controlStateId, uint256 targetStateId) external stateExists(controlStateId) stateExists(targetStateId) {
        require(controlStateId != targetStateId, "Control and target states must be different");
        onlyTransientState(controlStateId); // Apply modifier checks
        onlyTransientState(targetStateId); // Apply modifier checks

        QuantumState storage controlState = states[controlStateId];
        QuantumState storage targetState = states[targetStateId];
        uint256 oldTargetData = targetState.data;

        // Conceptual control condition: If control data is above a threshold
        if (controlState.data > 100) {
            // Apply a transformation to the target (e.g., conceptual PauliX)
            targetState.data = targetState.data ^ type(uint256).max;
            emit DataTransformed(targetStateId, oldTargetData, targetState.data, "ControlledGate (Applied)");
        } else {
             // No transformation applied
            emit DataTransformed(targetStateId, oldTargetData, targetState.data, "ControlledGate (Skipped)");
        }
    }

    /**
     * @dev Applies a conceptual SWAP gate, exchanging data between two states.
     * Both states must exist and be in Superposition or Entangled status.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     */
    function applySwapGate(uint256 stateId1, uint256 stateId2) external stateExists(stateId1) stateExists(stateId2) {
        require(stateId1 != stateId2, "Cannot swap a state with itself");
        onlyTransientState(stateId1); // Apply modifier checks
        onlyTransientState(stateId2); // Apply modifier checks

        QuantumState storage state1 = states[stateId1];
        QuantumState storage state2 = states[stateId2];

        uint256 oldData1 = state1.data;
        uint256 oldData2 = state2.data;

        // Swap data
        uint256 tempData = state1.data;
        state1.data = state2.data;
        state2.data = tempData;

        emit DataTransformed(stateId1, oldData1, state1.data, "SwapGate");
        emit DataTransformed(stateId2, oldData2, state2.data, "SwapGate");
    }

     /**
     * @dev Applies a custom transformation based on type and parameter.
     * Affects states in Superposition or Entangled status.
     * Provides flexibility for defining arbitrary transformations.
     * @param stateId The ID of the state to transform.
     * @param transformationType An identifier for the type of transformation (e.g., 1=add, 2=multiply, etc.).
     * @param parameter A parameter used in the transformation.
     */
    function applyCustomGate(uint256 stateId, uint256 transformationType, uint256 parameter) external stateExists(stateId) onlyTransientState(stateId) {
        QuantumState storage state = states[stateId];
        uint256 oldData = state.data;
        uint256 newData = oldData;

        // Apply transformation based on type
        if (transformationType == 1) { // Addition
            newData = oldData + parameter;
        } else if (transformationType == 2) { // Multiplication
             if (parameter != 0) newData = oldData * parameter;
        } else if (transformationType == 3) { // Subtraction (handle underflow conceptually, e.g., wrap around)
             newData = oldData >= parameter ? oldData - parameter : type(uint256).max - (parameter - oldData) + 1;
        } else if (transformationType == 4) { // Division (handle division by zero)
             if (parameter != 0) newData = oldData / parameter;
        } else {
            // Default or specific other transformation
            newData = oldData ^ parameter; // Example: XOR with parameter
        }
        state.data = newData;
        emit DataTransformed(stateId, oldData, state.data, string(abi.encodePacked("CustomGate-Type", transformationType)));
    }


    // --- View Functions ---

    /**
     * @dev Gets all details of a specific quantum state.
     * @param stateId The ID of the state.
     * @return The status, data, creation timestamp, and measurement timestamp of the state.
     */
    function getQuantumState(uint256 stateId) external view stateExists(stateId) returns (StateStatus status, uint256 data, uint256 creationTimestamp, uint256 measurementTimestamp) {
        QuantumState storage state = states[stateId];
        return (state.status, state.data, state.creationTimestamp, state.measurementTimestamp);
    }

    /**
     * @dev Gets the data value of a specific quantum state.
     * @param stateId The ID of the state.
     * @return The data value.
     */
    function getData(uint256 stateId) external view stateExists(stateId) returns (uint256) {
        return states[stateId].data;
    }

     /**
     * @dev Gets the status of a specific quantum state.
     * @param stateId The ID of the state.
     * @return The state's status enum.
     */
    function getStatus(uint256 stateId) external view stateExists(stateId) returns (StateStatus) {
        return states[stateId].status;
    }

    /**
     * @dev Gets the creation timestamp of a specific quantum state.
     * @param stateId The ID of the state.
     * @return The creation timestamp.
     */
    function getCreationTimestamp(uint256 stateId) external view stateExists(stateId) returns (uint256) {
        return states[stateId].creationTimestamp;
    }

     /**
     * @dev Gets the measurement timestamp of a specific quantum state.
     * Returns 0 if the state has not been measured.
     * @param stateId The ID of the state.
     * @return The measurement timestamp.
     */
    function getMeasurementTimestamp(uint256 stateId) external view stateExists(stateId) returns (uint256) {
        return states[stateId].measurementTimestamp;
    }

    /**
     * @dev Checks if two states are conceptually entangled.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     * @return True if they are entangled, false otherwise.
     */
    function isEntangled(uint256 stateId1, uint256 stateId2) public view returns (bool) {
         if (stateId1 == stateId2 || stateId1 == 0 || stateId2 == 0 || stateId1 >= nextStateId || stateId2 >= nextStateId) return false;

        // Check if both states are currently marked as Entangled status
        if (states[stateId1].status != StateStatus.Entangled || states[stateId2].status != StateStatus.Entangled) {
            return false;
        }

        // Check entanglement link list (less efficient for large lists)
        uint256[] storage links = entangledLinks[stateId1];
        for(uint i = 0; i < links.length; i++) {
            if (links[i] == stateId2) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Gets the current decoherence duration.
     * @return The duration in seconds.
     */
    function getDecoherenceDuration() external view returns (uint256) {
        return decoherenceDuration;
    }

    /**
     * @dev Gets the total number of states created so far.
     * @return The total count (nextStateId - 1).
     */
    function getTotalStates() external view returns (uint256) {
        return nextStateId - 1;
    }

    /**
     * @dev Helper view function to find states with a specific status.
     * WARNING: Iterating over all possible IDs (`nextStateId`) can be extremely
     * gas-intensive and may fail for a large number of states. This is included
     * primarily for demonstration/limited use cases. A production contract
     * would need a different pattern (e.g., linked lists, external indexers,
     * or requiring callers to provide batches of IDs).
     * @param status The status to filter by.
     * @return An array of state IDs matching the status.
     */
    function getStatesByStatus(StateStatus status) internal view returns (uint256[] memory) {
         uint256[] memory filteredIds = new uint256[](nextStateId - 1); // Max possible size
         uint256 count = 0;
         // Iterate through all created IDs (from 1 to nextStateId - 1)
         for (uint256 i = 1; i < nextStateId; i++) {
             if (states[i].status == status) {
                 filteredIds[count] = i;
                 count++;
             }
         }
         // Resize array to actual count
         uint256[] memory result = new uint256[](count);
         for (uint i = 0; i < count; i++) {
             result[i] = filteredIds[i];
         }
         return result;
    }

     /**
     * @dev Gets the IDs of all states currently in Superposition.
     * WARNING: Gas-intensive if total states are large.
     * @return An array of state IDs.
     */
    function getSuperpositionStates() external view returns (uint256[] memory) {
        return getStatesByStatus(StateStatus.Superposition);
    }

    /**
     * @dev Gets the IDs of all states currently in Entangled status.
     * WARNING: Gas-intensive if total states are large.
     * @return An array of state IDs.
     */
     function getEntangledStatesList() external view returns (uint256[] memory) {
        return getStatesByStatus(StateStatus.Entangled);
    }

    /**
     * @dev Gets the IDs of all states currently in Measured status.
     * WARNING: Gas-intensive if total states are large.
     * @return An array of state IDs.
     */
     function getMeasuredStates() external view returns (uint256[] memory) {
        return getStatesByStatus(StateStatus.Measured);
    }

    /**
     * @dev Gets the IDs of all states currently in Decohered status.
     * WARNING: Gas-intensive if total states are large.
     * @return An array of state IDs.
     */
     function getDecoheredStates() external view returns (uint256[] memory) {
        return getStatesByStatus(StateStatus.Decohered);
    }

}
```