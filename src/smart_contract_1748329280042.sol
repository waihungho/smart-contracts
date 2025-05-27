Okay, let's create a smart contract concept that's a bit abstract and goes beyond typical token/DeFi mechanics, inspired by concepts like state synchronization, probabilistic outcomes, and interconnected data points, framed with a "Quantum Entangled State Bridge" narrative for creativity. It's a simulation, of course, as blockchains are classical systems.

This contract will manage abstract "states" that can be in a "superposition" of potential values. These states can be "entangled" in pairs across two conceptual "Realities" (simulated within the contract). "Measuring" a superposed state collapses it to a single deterministic value (using Chainlink VRF for simulated non-determinism), and this measurement *probabilistically* influences the potential values of its entangled partner state in the other "Reality". It also includes concepts like simulated "decoherence".

**Outline & Function Summary**

**Contract Name:** QuantumEntangledStateBridge

**Concept:** Simulates the management and probabilistic synchronization of abstract "states" across two conceptual "Realities" using simulated quantum entanglement, superposition, measurement (via VRF), influence propagation, and decoherence. It's a creative exploration of complex state management and interaction patterns on-chain.

**Key Features:**
1.  **Simulated States:** Manage distinct abstract data points (`RealityState`).
2.  **Realities:** States exist in one of two simulated realities (`RealityA`, `RealityB`).
3.  **Superposition:** States can exist in a `Superposed` state, holding multiple `potentialValues`.
4.  **Measurement:** Triggering a measurement collapses a `Superposed` state to a single `measuredValue` using Chainlink VRF for a source of simulated randomness.
5.  **Entanglement:** Pairs of states (one in each Reality) can be `Entangled`.
6.  **Influence:** Measuring one state in an `EntangledPair` influences the `potentialValues` of its partner state in the other Reality before the partner is measured.
7.  **Decoherence:** Superposed states can eventually "decohere" over time if not measured.
8.  **Quantum Gate Simulations:** Simple functions (`applyHadamardSim`, `applyPauliXSim`) to manipulate states in superposition.

**Function Summary:**

*   **VRF Management (Chainlink VRF v2):**
    1.  `constructor`: Initializes VRF subscription ID, owner.
    2.  `setVRFCoordinator`: Sets the VRF coordinator address.
    3.  `setVRFKeyHash`: Sets the key hash for VRF requests.
    4.  `setVRFFee`: Sets the VRF fee.
    5.  `fundVRFSubscription`: Allows funding the VRF subscription with LINK.
    6.  `addVRFConsumer`: Adds this contract as a consumer to the VRF subscription.
    7.  `withdrawVRFLink`: Allows the owner to withdraw LINK from the subscription.
*   **State & Entanglement Creation:**
    8.  `createRealityState`: Creates a new, non-superposed state in a specified reality.
    9.  `createEntangledPair`: Creates two new states (one in A, one in B) and entangles them.
    10. `entangleExistingStates`: Entangles two existing states (one in A, one in B).
    11. `disentanglePair`: Breaks the entanglement of a pair.
*   **Entanglement Configuration:**
    12. `updateEntanglementStrength`: Sets the influence strength for a pair.
    13. `setInfluenceEffectAtoB`: Defines how measuring state A influences state B.
    14. `setInfluenceEffectBtoA`: Defines how measuring state B influences state A.
*   **State Manipulation (Simulated Quantum Gates):**
    15. `applyHadamardSim`: Puts a non-superposed state into `Superposed` status with initial potential values.
    16. `applyPauliXSim`: Applies a simulated Pauli-X gate effect, potentially altering potential values of a `Superposed` state.
    17. `addPotentialValueToState`: Adds a potential value to a `Superposed` state's list.
    18. `removePotentialValueFromState`: Removes a potential value from a `Superposed` state's list.
*   **Measurement & Collapse:**
    19. `requestStateMeasurement`: Initiates the VRF request to measure/collapse a `Superposed` state.
    20. `fulfillRandomWords`: VRF callback function - performs the actual state collapse using the random word, sets `measuredValue`, triggers influence propagation.
    21. `simulateDecoherenceCheck`: Allows checking if a state has decohered based on time and changes its status if it has.
    22. `resetDecoheredState`: Resets a `Decohered` state back to a default, non-superposed state.
*   **Influence Propagation:**
    23. `applyInfluenceEffectOnPartner`: Internal/triggered function called after measurement to influence the entangled partner's potential values based on configuration.
*   **Configuration:**
    24. `setDecoherenceTime`: Sets the time limit before a `Superposed` state decoheres.
*   **View Functions (Read-only):**
    25. `getMeasuredStateValue`: Returns the measured value of a state.
    26. `getPotentialStateValues`: Returns the list of potential values for a state.
    27. `getStateStatus`: Returns the current status of a state (Superposed, Measured, Decohered, etc.).
    28. `getEntangledPartnerId`: Returns the ID of the entangled partner state.
    29. `getEntanglementStrength`: Returns the entanglement strength of a state's pair.
    30. `getInfluenceEffects`: Returns the A->B and B->A influence effects for a pair.
    31. `getStateDetails`: Returns comprehensive details about a state.
    32. `getEntangledPairDetails`: Returns comprehensive details about an entangled pair.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Outline & Function Summary above this contract definition

contract QuantumEntangledStateBridge is VRFConsumerBaseV2 {

    // --- Enums ---
    enum StateStatus {
        Inactive,       // Initial state or after reset
        Superposed,     // Exists in multiple potential values
        MeasuringRequested, // VRF randomness requested
        Measured,       // State has collapsed to a single value
        Decohered       // State lost superposition over time/interaction
    }

    enum Reality {
        RealityA,
        RealityB
    }

    enum GateTypeSim {
        HadamardSim,     // Puts state into superposition
        PauliXSim        // Simulates Pauli-X, potentially flipping potential values
        // More simulation gates could be added
    }

    enum InfluenceEffect {
        None,                 // No influence on partner
        MirrorMeasuredValue,  // Add initiator's measured value to partner's potentials
        FlipPotentialValues   // Apply simulated Pauli-X to partner's potentials
        // More complex effects could be added
    }

    // --- Structs ---
    struct RealityState {
        uint256 id;
        Reality reality;
        StateStatus status;
        uint256 measuredValue; // Valid only if status is Measured
        uint256[] potentialValues; // Valid only if status is Superposed or MeasuringRequested
        uint256 lastStatusChangeTime;
        uint256 entangledPairId; // 0 if not entangled
        uint256 measurementRequestId; // VRF request ID if status is MeasuringRequested
    }

    struct EntangledPair {
        uint256 id;
        uint256 stateAId; // State in RealityA
        uint256 stateBId; // State in RealityB
        uint256 entanglementStrength; // e.g., 0-100, affects probability/impact of influence (simple int for simulation)
        InfluenceEffect influenceEffectAtoB; // How A's measurement influences B
        InfluenceEffect influenceEffectBtoA; // How B's measurement influences A
    }

    // --- State Variables ---
    address public owner;

    uint256 private _stateCounter;
    uint256 private _pairCounter;

    mapping(uint256 => RealityState) public states;
    mapping(uint256 => EntangledPair) public entangledPairs;

    // VRF variables
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 public s_keyHash;
    uint64 public s_subscriptionId;
    uint32 public s_callbackGasLimit = 100000; // Default gas limit for fulfillRandomWords
    uint32 public s_numWords = 1;
    uint256 public s_requestFee;

    // Mapping to track VRF request IDs to State IDs
    mapping(uint256 => uint256) public s_requestIdToStateId;

    // Configuration parameters
    uint256 public decoherenceTime = 7 days; // Time after which a Superposed state might decohere

    // --- Events ---
    event StateCreated(uint256 stateId, Reality reality, address indexed creator);
    event EntangledPairCreated(uint256 pairId, uint256 stateAId, uint256 stateBId);
    event PairDisentangled(uint256 pairId, uint256 stateAId, uint256 stateBId);
    event StateStatusChanged(uint256 stateId, StateStatus oldStatus, StateStatus newStatus);
    event StateMeasurementRequested(uint256 stateId, uint256 requestId);
    event StateMeasured(uint256 stateId, uint256 measuredValue, uint256 requestId);
    event StateDecohered(uint256 stateId);
    event EntanglementInfluenceApplied(uint256 initiatorStateId, uint256 influencedStateId, InfluenceEffect effectApplied);
    event VRFSubscriptionFunded(uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenStateIs(uint256 _stateId, StateStatus _status) {
        require(states[_stateId].status == _status, "State is not in required status");
        _;
    }

     modifier whenStateIsNot(uint256 _stateId, StateStatus _status) {
        require(states[_stateId].status != _status, "State is in restricted status");
        _;
    }

    modifier onlySuperposed(uint256 _stateId) {
        require(states[_stateId].status == StateStatus.Superposed, "State must be Superposed");
        _;
    }

    modifier onlyEntangled(uint256 _stateId) {
        require(states[_stateId].entangledPairId != 0, "State is not entangled");
        _;
    }

    // --- Constructor ---
    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(_subscriptionId) {
        owner = msg.sender;
        s_subscriptionId = _subscriptionId;
    }

    // --- VRF Management ---
    /**
     * @notice Sets the VRF Coordinator address.
     * @param _vrfCoordinator Address of the VRF Coordinator contract.
     */
    function setVRFCoordinator(address _vrfCoordinator) external onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

     /**
     * @notice Sets the VRF Key Hash.
     * @param _keyHash The key hash to use for VRF requests.
     */
    function setVRFKeyHash(bytes32 _keyHash) external onlyOwner {
        s_keyHash = _keyHash;
    }

     /**
     * @notice Sets the fee for VRF requests.
     * @param _fee The fee amount in LINK.
     */
    function setVRFFee(uint256 _fee) external onlyOwner {
        s_requestFee = _fee;
    }

    /**
     * @notice Allows anyone to fund the VRF subscription used by this contract.
     * @param _amount The amount of LINK to send.
     */
    function fundVRFSubscription(uint256 _amount) external {
        // Assuming LINK token is used and approved this contract to spend
        // For simplicity in this example, we don't include LINK token transfer logic.
        // In a real scenario, you'd use a transferFrom call here or a payable function.
        // This is a placeholder for the funding action.
         emit VRFSubscriptionFunded(_amount);
        // Example: IERC20(LINK_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        // Funding is actually done on the VRF Coordinator contract by the subscription owner
        // calling fundSubscription. This function would typically just signal funding intent
        // or trigger an owner action. Let's make it signal for owner to fund.
    }

     /**
     * @notice Adds this contract as a consumer to the VRF subscription.
     * @dev Requires the subscription owner to have added this contract's address.
     */
    function addVRFConsumer(uint64 _subscriptionId, address _consumerAddress) external onlyOwner {
        // This function is symbolic. The actual addition of a consumer
        // is done by the subscription owner calling the VRF Coordinator.
        // This function in THIS contract doesn't perform the action.
        // It's a placeholder indicating the owner should perform the off-chain step.
        s_subscriptionId = _subscriptionId; // Update ID if needed
        // COORDINATOR.addConsumer(s_subscriptionId, _consumerAddress); // This call would fail if owner != msg.sender
    }

    /**
     * @notice Allows the owner to withdraw excess LINK from the VRF subscription.
     * @dev Requires owner privileges on the subscription itself. This is symbolic.
     */
    function withdrawVRFLink(uint256 _amount) external onlyOwner {
         // COORDINATOR.withdraw(s_subscriptionId, owner, _amount); // This call would fail if owner != msg.sender
    }


    // --- State & Entanglement Creation ---
    /**
     * @notice Creates a new state in a specified reality.
     * @param _reality The reality (A or B) for the new state.
     */
    function createRealityState(Reality _reality) external returns (uint256 newStateId) {
        _stateCounter++;
        newStateId = _stateCounter;

        states[newStateId] = RealityState({
            id: newStateId,
            reality: _reality,
            status: StateStatus.Inactive,
            measuredValue: 0,
            potentialValues: new uint256[](0),
            lastStatusChangeTime: block.timestamp,
            entangledPairId: 0,
            measurementRequestId: 0
        });

        emit StateCreated(newStateId, _reality, msg.sender);
        emit StateStatusChanged(newStateId, StateStatus.Inactive, StateStatus.Inactive); // Initial status change event
    }

    /**
     * @notice Creates two new states, one in each reality, and entangles them.
     * @param _initialPotentialValuesA Initial potential values for state A.
     * @param _initialPotentialValuesB Initial potential values for state B.
     * @param _entanglementStrength Initial entanglement strength (e.g., 0-100).
     * @param _influenceAtoB How A's measurement influences B.
     * @param _influenceBtoA How B's measurement influences A.
     */
    function createEntangledPair(
        uint256[] memory _initialPotentialValuesA,
        uint256[] memory _initialPotentialValuesB,
        uint256 _entanglementStrength,
        InfluenceEffect _influenceAtoB,
        InfluenceEffect _influenceBtoA
    ) external returns (uint256 pairId, uint256 stateAId, uint256 stateBId)
    {
        require(_initialPotentialValuesA.length > 0 && _initialPotentialValuesB.length > 0, "Initial potentials cannot be empty");
        require(_entanglementStrength <= 100, "Entanglement strength max 100");

        stateAId = createRealityState(Reality.RealityA);
        stateBId = createRealityState(Reality.RealityB);

        // Put states into initial superposition
        _applyHadamardSimInternal(stateAId, _initialPotentialValuesA);
        _applyHadamardSimInternal(stateBId, _initialPotentialValuesB);

        _pairCounter++;
        pairId = _pairCounter;

        entangledPairs[pairId] = EntangledPair({
            id: pairId,
            stateAId: stateAId,
            stateBId: stateBId,
            entanglementStrength: _entanglementStrength,
            influenceEffectAtoB: _influenceAtoB,
            influenceEffectBtoA: _influenceBtoA
        });

        states[stateAId].entangledPairId = pairId;
        states[stateBId].entangledPairId = pairId;

        emit EntangledPairCreated(pairId, stateAId, stateBId);
    }

    /**
     * @notice Entangles two existing states, one in RealityA and one in RealityB.
     *         Both states must be Inactive or Decohered to be entangled.
     * @param _stateAId ID of the state in RealityA.
     * @param _stateBId ID of the state in RealityB.
     * @param _initialPotentialValuesA Initial potential values for state A (puts it in superposition).
     * @param _initialPotentialValuesB Initial potential values for state B (puts it in superposition).
     * @param _entanglementStrength Initial entanglement strength (e.g., 0-100).
     * @param _influenceAtoB How A's measurement influences B.
     * @param _influenceBtoA How B's measurement influences A.
     */
    function entangleExistingStates(
        uint256 _stateAId,
        uint256 _stateBId,
        uint256[] memory _initialPotentialValuesA,
        uint256[] memory _initialPotentialValuesB,
        uint256 _entanglementStrength,
        InfluenceEffect _influenceAtoB,
        InfluenceEffect _influenceBtoA
    ) external
    {
        require(states[_stateAId].id != 0, "State A does not exist");
        require(states[_stateBId].id != 0, "State B does not exist");
        require(states[_stateAId].reality == Reality.RealityA, "State A must be in RealityA");
        require(states[_stateBBId].reality == Reality.RealityB, "State B must be in RealityB");
        require(states[_stateAId].entangledPairId == 0, "State A is already entangled");
        require(states[_stateBId].entangledPairId == 0, "State B is already entangled");
        require(states[_stateAId].status == StateStatus.Inactive || states[_stateAId].status == StateStatus.Decohered, "State A status prevents entanglement");
        require(states[_stateBId].status == StateStatus.Inactive || states[_stateBId].status == StateStatus.Decohered, "State B status prevents entanglement");
        require(_initialPotentialValuesA.length > 0 && _initialPotentialValuesB.length > 0, "Initial potentials cannot be empty");
        require(_entanglementStrength <= 100, "Entanglement strength max 100");


        _pairCounter++;
        uint256 pairId = _pairCounter;

        entangledPairs[pairId] = EntangledPair({
            id: pairId,
            stateAId: _stateAId,
            stateBId: _stateBId,
            entanglementStrength: _entanglementStrength,
            influenceEffectAtoB: _influenceAtoB,
            influenceEffectBtoA: _influenceBtoA
        });

        states[_stateAId].entangledPairId = pairId;
        states[_stateBId].entangledPairId = pairId;

         // Put states into initial superposition upon entanglement
        _applyHadamardSimInternal(_stateAId, _initialPotentialValuesA);
        _applyHadamardSimInternal(_stateBId, _initialPotentialValuesB);


        emit EntangledPairCreated(pairId, _stateAId, _stateBId);
    }

    /**
     * @notice Breaks the entanglement of a pair. States remain, but are no longer linked.
     * @param _pairId The ID of the entangled pair.
     */
    function disentanglePair(uint256 _pairId) external onlyEntangled(entangledPairs[_pairId].stateAId) {
        EntangledPair storage pair = entangledPairs[_pairId];
        require(pair.id != 0, "Pair does not exist");

        uint256 stateAId = pair.stateAId;
        uint256 stateBId = pair.stateBId;

        // Clear entanglement linkage from states
        states[stateAId].entangledPairId = 0;
        states[stateBId].entangledPairId = 0;

        // Clear pair data (optional, could mark as inactive instead)
        delete entangledPairs[_pairId];

        emit PairDisentangled(_pairId, stateAId, stateBId);
    }

    // --- Entanglement Configuration ---
    /**
     * @notice Updates the entanglement strength of a pair.
     * @param _pairId The ID of the entangled pair.
     * @param _newStrength The new entanglement strength (0-100).
     */
    function updateEntanglementStrength(uint256 _pairId, uint256 _newStrength) external {
         require(entangledPairs[_pairId].id != 0, "Pair does not exist");
         require(_newStrength <= 100, "Entanglement strength max 100");
         entangledPairs[_pairId].entanglementStrength = _newStrength;
    }

    /**
     * @notice Sets the influence effect from RealityA state to RealityB state for a pair.
     * @param _pairId The ID of the entangled pair.
     * @param _effect The new influence effect.
     */
    function setInfluenceEffectAtoB(uint256 _pairId, InfluenceEffect _effect) external {
         require(entangledPairs[_pairId].id != 0, "Pair does not exist");
         entangledPairs[_pairId].influenceEffectAtoB = _effect;
    }

    /**
     * @notice Sets the influence effect from RealityB state to RealityA state for a pair.
     * @param _pairId The ID of the entangled pair.
     * @param _effect The new influence effect.
     */
    function setInfluenceEffectBtoA(uint256 _pairId, InfluenceEffect _effect) external {
         require(entangledPairs[_pairId].id != 0, "Pair does not exist");
         entangledPairs[_pairId].influenceEffectBtoA = _effect;
    }


    // --- State Manipulation (Simulated Quantum Gates) ---
    /**
     * @notice Simulates applying a Hadamard gate: Puts an Inactive or Decohered state into Superposed status.
     * @param _stateId The ID of the state.
     * @param _potentialValues The list of potential values the state can collapse into.
     */
    function applyHadamardSim(uint256 _stateId, uint256[] memory _potentialValues) external {
        require(states[_stateId].id != 0, "State does not exist");
        require(states[_stateId].status == StateStatus.Inactive || states[_stateId].status == StateStatus.Decohered, "State must be Inactive or Decohered to apply Hadamard");
        require(_potentialValues.length > 0, "Potential values cannot be empty");

        _applyHadamardSimInternal(_stateId, _potentialValues);
    }

    /**
     * @dev Internal function to apply Hadamard simulation.
     */
    function _applyHadamardSimInternal(uint256 _stateId, uint256[] memory _potentialValues) internal {
         StateStatus oldStatus = states[_stateId].status;
        states[_stateId].status = StateStatus.Superposed;
        states[_stateId].potentialValues = _potentialValues;
        states[_stateId].measuredValue = 0; // Reset measured value
        states[_stateId].lastStatusChangeTime = block.timestamp;
        states[_stateId].measurementRequestId = 0; // Reset request ID

        emit StateStatusChanged(_stateId, oldStatus, StateStatus.Superposed);
    }


    /**
     * @notice Simulates applying a Pauli-X gate: Flips the values within the potential values list of a Superposed state.
     * @param _stateId The ID of the state.
     * @dev This is a simplified simulation. Actual effect depends on the potential values.
     *      Example: If potential values are [0, 1], they might become [1, 0]. If [10, 20], maybe [~10, ~20] or reordered.
     *      We'll implement a simple XOR-like flip if possible, or just reverse the array for simplicity. Let's reverse.
     */
    function applyPauliXSim(uint256 _stateId) external onlySuperposed(_stateId) {
        require(states[_stateId].id != 0, "State does not exist");

        uint256[] storage potentials = states[_stateId].potentialValues;
        uint256 len = potentials.length;
        for (uint256 i = 0; i < len / 2; i++) {
            uint256 temp = potentials[i];
            potentials[i] = potentials[len - 1 - i];
            potentials[len - 1 - i] = temp;
        }
         // Note: Status remains Superposed, but the state vector (potential values) changed conceptually.
         // No event needed for just this internal state vector change in this simulation.
    }

    /**
     * @notice Adds a new potential value to a Superposed state.
     * @param _stateId The ID of the state.
     * @param _newValue The value to add to potential outcomes.
     */
    function addPotentialValueToState(uint256 _stateId, uint256 _newValue) external onlySuperposed(_stateId) {
         require(states[_stateId].id != 0, "State does not exist");
         // Check if value already exists? Optional, let's allow duplicates for simplicity.
         states[_stateId].potentialValues.push(_newValue);
    }

    /**
     * @notice Removes a potential value from a Superposed state. Removes the first occurrence.
     * @param _stateId The ID of the state.
     * @param _valueToRemove The value to remove from potential outcomes.
     */
    function removePotentialValueFromState(uint256 _stateId, uint256 _valueToRemove) external onlySuperposed(_stateId) {
         require(states[_stateId].id != 0, "State does not exist");

         uint256[] storage potentials = states[_stateId].potentialValues;
         uint256 foundIndex = potentials.length; // Sentinel value
         for(uint256 i = 0; i < potentials.length; i++) {
             if (potentials[i] == _valueToRemove) {
                 foundIndex = i;
                 break;
             }
         }

         require(foundIndex < potentials.length, "Value not found in potential values");

         // Shift elements left to remove the value
         for (uint256 i = foundIndex; i < potentials.length - 1; i++) {
             potentials[i] = potentials[i+1];
         }
         potentials.pop(); // Remove the last (now duplicate) element

         require(potentials.length > 0, "Cannot remove the last potential value"); // Must have at least one potential value
    }


    // --- Measurement & Collapse ---
    /**
     * @notice Requests VRF randomness to measure (collapse) a Superposed state.
     * @param _stateId The ID of the state to measure.
     * @return requestId The VRF request ID.
     */
    function requestStateMeasurement(uint256 _stateId) external onlySuperposed(_stateId) returns (uint256 requestId) {
        require(states[_stateId].id != 0, "State does not exist");
        require(s_keyHash != bytes32(0), "VRF Key Hash not set");
        require(s_requestFee > 0, "VRF Fee not set");
        require(address(COORDINATOR) != address(0), "VRF Coordinator not set");

        StateStatus oldStatus = states[_stateId].status;
        states[_stateId].status = StateStatus.MeasuringRequested;
        states[_stateId].lastStatusChangeTime = block.timestamp;

        // Request randomness
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestFee,
            s_callbackGasLimit,
            s_numWords
        );

        s_requestIdToStateId[requestId] = _stateId;
        states[_stateId].measurementRequestId = requestId;

        emit StateStatusChanged(_stateId, oldStatus, StateStatus.MeasuringRequested);
        emit StateMeasurementRequested(_stateId, requestId);
        return requestId;
    }

    /**
     * @notice VRF callback function. Called by the VRF Coordinator to fulfill a randomness request.
     * @param requestId The ID of the randomness request.
     * @param randomWords The random word(s) returned by VRF.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 stateId = s_requestIdToStateId[requestId];
        require(stateId != 0, "Request ID not linked to a state"); // Should not happen if VRF setup is correct

        RealityState storage state = states[stateId];

        // Ensure state is in the correct status for fulfillment
        require(state.status == StateStatus.MeasuringRequested && state.measurementRequestId == requestId, "State not awaiting this measurement fulfillment");

        StateStatus oldStatus = state.status;

        // Use the random word to select a potential value
        uint256 randomIndex = randomWords[0] % state.potentialValues.length;
        state.measuredValue = state.potentialValues[randomIndex];

        // Collapse state
        state.status = StateStatus.Measured;
        delete state.potentialValues; // Clear potential values after collapse
        state.lastStatusChangeTime = block.timestamp;
        // Keep measurementRequestId for history/debugging if needed

        emit StateStatusChanged(stateId, oldStatus, StateStatus.Measured);
        emit StateMeasured(stateId, state.measuredValue, requestId);

        // --- Trigger Entanglement Influence ---
        // After collapsing, this state influences its entangled partner if one exists.
        if (state.entangledPairId != 0) {
            _initiateCrossRealityInfluence(stateId);
        }
    }

    /**
     * @notice Checks if a Superposed state has exceeded the decoherence time and changes its status if it has.
     *         Anyone can call this to trigger decoherence checks.
     * @param _stateId The ID of the state to check.
     */
    function simulateDecoherenceCheck(uint256 _stateId) external {
        require(states[_stateId].id != 0, "State does not exist");
        RealityState storage state = states[_stateId];

        if (state.status == StateStatus.Superposed && block.timestamp >= state.lastStatusChangeTime + decoherenceTime) {
            StateStatus oldStatus = state.status;
            state.status = StateStatus.Decohered;
            // When decohering, it collapses to a default value (e.g., 0) or the first potential value. Let's use 0.
            state.measuredValue = 0; // Arbitrary default collapse value
            delete state.potentialValues;
            state.lastStatusChangeTime = block.timestamp;

            emit StateStatusChanged(_stateId, oldStatus, StateStatus.Decohered);
            emit StateDecohered(_stateId);
        }
         // No state change if not Superposed or time hasn't passed
    }

    /**
     * @notice Resets a Decohered state back to an Inactive state, allowing it to be re-superposed or entangled.
     * @param _stateId The ID of the state.
     */
    function resetDecoheredState(uint256 _stateId) external whenStateIs(_stateId, StateStatus.Decohered) {
        require(states[_stateId].id != 0, "State does not exist");

        RealityState storage state = states[_stateId];
        StateStatus oldStatus = state.status;

        state.status = StateStatus.Inactive;
        state.measuredValue = 0;
        delete state.potentialValues;
        state.lastStatusChangeTime = block.timestamp;
        state.entangledPairId = 0; // Decohered states lose entanglement linkage in this simulation
        state.measurementRequestId = 0;

        emit StateStatusChanged(_stateId, oldStatus, StateStatus.Inactive);
    }

    // --- Influence Propagation ---
    /**
     * @dev Internal function called after a state is measured to initiate influence on its entangled partner.
     * @param _initiatorStateId The ID of the state that was just measured.
     */
    function _initiateCrossRealityInfluence(uint256 _initiatorStateId) internal onlyEntangled(_initiatorStateId) {
        RealityState storage initiatorState = states[_initiatorStateId];
        require(initiatorState.status == StateStatus.Measured, "Initiator state must be Measured");

        EntangledPair storage pair = entangledPairs[initiatorState.entangledPairId];
        uint256 partnerStateId = (initiatorState.reality == Reality.RealityA) ? pair.stateBId : pair.stateAId;
        RealityState storage partnerState = states[partnerStateId];

        // Influence only applies if the partner is still Superposed
        if (partnerState.status == StateStatus.Superposed) {
            InfluenceEffect effect = (initiatorState.reality == Reality.RealityA) ? pair.influenceEffectAtoB : pair.influenceEffectBtoA;

            // Apply influence based on configured effect and entanglement strength (strength isn't used in these simple effects but could be)
            _applyInfluenceEffectOnPartner(partnerStateId, initiatorState.measuredValue, effect, pair.entanglementStrength);

            emit EntanglementInfluenceApplied(_initiatorStateId, partnerStateId, effect);
        }
         // If partner is Measured, MeasuringRequested, Inactive, or Decohered, no influence occurs in this simulation model.
    }

    /**
     * @dev Internal function to apply the specific influence effect on a Superposed partner state.
     * @param _partnerStateId The ID of the state being influenced.
     * @param _initiatorMeasuredValue The measured value of the state that caused the influence.
     * @param _effect The type of influence effect to apply.
     * @param _strength The entanglement strength (currently unused in these simple effects).
     */
    function _applyInfluenceEffectOnPartner(
        uint256 _partnerStateId,
        uint256 _initiatorMeasuredValue,
        InfluenceEffect _effect,
        uint256 _strength // Added for potential future use
    ) internal onlySuperposed(_partnerStateId) {

        uint256[] storage partnerPotentials = states[_partnerStateId].potentialValues;

        if (_effect == InfluenceEffect.MirrorMeasuredValue) {
            // Check if the measured value is already in the potentials
            bool found = false;
            for (uint256 i = 0; i < partnerPotentials.length; i++) {
                if (partnerPotentials[i] == _initiatorMeasuredValue) {
                    found = true;
                    break;
                }
            }
            // If not found, add the initiator's measured value to the partner's potential values
            if (!found) {
                partnerPotentials.push(_initiatorMeasuredValue);
            }
             // In a more complex model, strength could affect the *probability* of this happening
             // or increase the weight/likelihood of the mirrored value being chosen upon measurement.

        } else if (_effect == InfluenceEffect.FlipPotentialValues) {
             // Apply a simulated Pauli-X effect (reverse the list of potential values)
             // Strength could influence the *chance* this flip happens. Let's apply always for simplicity.
             uint256 len = partnerPotentials.length;
            for (uint256 i = 0; i < len / 2; i++) {
                uint256 temp = partnerPotentials[i];
                partnerPotentials[i] = partnerPotentials[len - 1 - i];
                partnerPotentials[len - 1 - i] = temp;
            }
        }
         // Note: Status remains Superposed. The potential state changed.
         // No event needed for just this internal state vector change in this simulation.
    }


    // --- Configuration ---
    /**
     * @notice Sets the time duration after which a Superposed state might decohere.
     * @param _newDecoherenceTime The new decoherence time in seconds.
     */
    function setDecoherenceTime(uint256 _newDecoherenceTime) external onlyOwner {
        decoherenceTime = _newDecoherenceTime;
    }


    // --- View Functions ---
    /**
     * @notice Gets the measured value of a state.
     * @param _stateId The ID of the state.
     * @return The measured value (0 if not Measured).
     */
    function getMeasuredStateValue(uint256 _stateId) external view returns (uint256) {
        require(states[_stateId].id != 0, "State does not exist");
        return states[_stateId].measuredValue;
    }

    /**
     * @notice Gets the potential values of a state.
     * @param _stateId The ID of the state.
     * @return An array of potential values (empty if not Superposed or MeasuringRequested).
     */
    function getPotentialStateValues(uint256 _stateId) external view returns (uint256[] memory) {
         require(states[_stateId].id != 0, "State does not exist");
         if (states[_stateId].status == StateStatus.Superposed || states[_stateId].status == StateStatus.MeasuringRequested) {
            return states[_stateId].potentialValues;
         } else {
             return new uint256[](0);
         }
    }

    /**
     * @notice Gets the current status of a state.
     * @param _stateId The ID of the state.
     * @return The state's status enum value.
     */
    function getStateStatus(uint256 _stateId) external view returns (StateStatus) {
         require(states[_stateId].id != 0, "State does not exist");
         return states[_stateId].status;
    }

     /**
     * @notice Gets the ID of the entangled partner state.
     * @param _stateId The ID of the state.
     * @return The partner state ID (0 if not entangled or partner does not exist).
     */
    function getEntangledPartnerId(uint256 _stateId) external view returns (uint256) {
        require(states[_stateId].id != 0, "State does not exist");
        uint256 pairId = states[_stateId].entangledPairId;
        if (pairId == 0) {
            return 0;
        }
        EntangledPair storage pair = entangledPairs[pairId];
        if (pair.stateAId == _stateId) return pair.stateBId;
        if (pair.stateBId == _stateId) return pair.stateAId;
        return 0; // Should not happen if entangledPairId is correct
    }

    /**
     * @notice Gets the entanglement strength of the state's pair.
     * @param _stateId The ID of the state.
     * @return The entanglement strength (0 if not entangled).
     */
    function getEntanglementStrength(uint256 _stateId) external view returns (uint256) {
        require(states[_stateId].id != 0, "State does not exist");
         uint256 pairId = states[_stateId].entangledPairId;
        if (pairId == 0) {
            return 0;
        }
        return entangledPairs[pairId].entanglementStrength;
    }

     /**
     * @notice Gets the influence effects configured for the state's entangled pair.
     * @param _stateId The ID of the state.
     * @return effectAtoB How A influences B.
     * @return effectBtoA How B influences A.
     */
    function getInfluenceEffects(uint256 _stateId) external view returns (InfluenceEffect effectAtoB, InfluenceEffect effectBtoA) {
        require(states[_stateId].id != 0, "State does not exist");
        uint256 pairId = states[_stateId].entangledPairId;
        if (pairId == 0) {
            return (InfluenceEffect.None, InfluenceEffect.None);
        }
        EntangledPair storage pair = entangledPairs[pairId];
        return (pair.influenceEffectAtoB, pair.influenceEffectBtoA);
    }

    /**
     * @notice Gets all details for a specific state.
     * @param _stateId The ID of the state.
     * @return All fields of the RealityState struct.
     */
    function getStateDetails(uint256 _stateId) external view returns (RealityState memory) {
        require(states[_stateId].id != 0, "State does not exist");
        return states[_stateId];
    }

     /**
     * @notice Gets all details for a specific entangled pair.
     * @param _pairId The ID of the entangled pair.
     * @return All fields of the EntangledPair struct.
     */
    function getEntangledPairDetails(uint256 _pairId) external view returns (EntangledPair memory) {
        require(entangledPairs[_pairId].id != 0, "Pair does not exist");
        return entangledPairs[_pairId];
    }

    // Fallback and Receive functions (optional, but good practice if sending native currency)
    // This contract doesn't handle native currency directly for the core logic,
    // but might receive LINK for VRF funding (handled via specific VRF functions).
    // If it were to accept native currency for other purposes, these would be needed.
    // receive() external payable {}
    // fallback() external payable {}

}
```