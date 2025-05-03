Okay, let's create a smart contract concept that's a bit abstract and leverages metaphors from quantum mechanics, combined with dynamic properties and interaction effects, aiming for complexity and novelty.

We'll call it "Quantum Fluctuator". This contract will manage digital "Quantum States", each with properties that are not fixed but 'fluctuate' based on time, interactions, and internal logic. Users can 'observe', 'perturb', 'stabilize', or 'entangle' these states, affecting their properties and triggering cascading effects.

It's crucial to state that this contract *simulates* quantum concepts using classical computing principles on the blockchain. It does *not* involve actual quantum computing or true physical randomness. The "randomness" will be derived pseudo-randomly from block data, which is predictable to miners. This is a common limitation in Solidity for on-chain randomness.

---

## Quantum Fluctuator Smart Contract

**Concept:**
Manages digital "Quantum States" with dynamic, fluctuating properties. Users interact with states to influence their potential value, stability, and entanglement, simulating abstract quantum phenomena like observation, perturbation, stabilization, and entanglement. Operations consume 'Quantum Charge'.

**Core Components:**
*   **Quantum State:** A struct representing a state with properties like `potentialValue`, `fluctuationLevel`, `stability`, `charge`, `custody`, `lastObservedTime`, and entanglement status.
*   **Global Quantum Charge:** A contract-wide pool of energy used for operations. Can be replenished.
*   **Dynamic Properties:** State properties change over time based on internal logic and observation/interaction events.
*   **Entanglement:** States can be paired, causing interactions with one to affect the other.
*   **Pseudo-Randomness:** Utilizes block data to introduce unpredictability into state fluctuations and outcomes.

**Outline & Function Summary:**

1.  **State Management & Creation**
    *   `constructor`: Initializes owner, initial charge.
    *   `createQuantumState`: Creates a new state with initial properties.
    *   `getNumberOfStates`: Returns the total count of states.
    *   `getStateDetails`: Returns all details of a specific state.

2.  **Property Interaction**
    *   `perturbState`: Increases a state's fluctuation level.
    *   `stabilizeState`: Increases a state's stability level.
    *   `observeState`: "Collapses" the state's potential value to its current fluctuated value and updates observation time/observer.
    *   `batchPerturbStates`: Applies perturbation to a list of states.
    *   `batchStabilizeStates`: Applies stabilization to a list of states.

3.  **Value & Prediction**
    *   `getCurrentlyFluctuatedValue`: Calculates the *estimated* current value based on potential value, fluctuation, stability, and time since observation.
    *   `predictQuantumOutcome`: Uses state properties and pseudo-randomness to predict a probabilistic outcome (e.g., a boolean or weighted value). Costs charge.
    *   `collapseAndPredict`: Combines `observeState` and `predictQuantumOutcome`.

4.  **Charge Management**
    *   `addGlobalQuantumCharge`: Allows sending ETH to increase the global charge pool.
    *   `withdrawGlobalQuantumCharge`: Owner withdraws ETH from the global charge pool.
    *   `distributeStateCharge`: Moves charge from the global pool to a specific state.
    *   `collectStateCharge`: Moves charge from a state back to the global pool.
    *   `getGlobalCharge`: Returns the current global charge amount.
    *   `getStateCharge`: Returns the charge amount for a specific state.

5.  **Entanglement**
    *   `entangleStates`: Pairs two states, linking their properties. Costs charge. Requires custody of both.
    *   `disentangleState`: Breaks the entanglement of a state. Costs charge. Requires custody.
    *   `interactWithEntangledPair`: Interacting with one entangled state also affects its partner. Costs charge. Requires custody of one.
    *   `getEntangledPartner`: Returns the entangled state ID.
    *   `isStateEntangled`: Checks if a state is entangled.

6.  **Custody & Control**
    *   `transferStateCustody`: Transfers control of a state to another address. Requires current custody.
    *   `getCustody`: Returns the current custodian of a state.

7.  **Advanced Interaction**
    *   `triggerCascadingPerturbation`: Perturbs a state, and this perturbation effect cascades to entangled partners and potentially nearby state IDs. Costs charge. Requires custody.

8.  **View Functions (Helper / Individual Properties)**
    *   `getStatePotentialValue`: Returns just the potential value.
    *   `getStateFluctuationLevel`: Returns just the fluctuation level.
    *   `getStateStability`: Returns just the stability.
    *   `getLastObservedTime`: Returns the last observation timestamp.
    *   `getCurrentObserver`: Returns the address that last observed the state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuator
 * @dev A contract simulating abstract 'Quantum States' with dynamic,
 *      fluctuating properties based on time, interactions, and pseudo-randomness.
 *      Users can interact to perturb, stabilize, observe, or entangle states.
 *      Operations require 'Quantum Charge', which can be added via ETH.
 *      This contract uses blockchain characteristics (like block data) to
 *      simulate unpredictability, *not* actual quantum mechanics or true randomness.
 */
contract QuantumFluctuator {

    address public owner;
    uint256 private nextStateId;
    uint256 public globalQuantumCharge; // Charge pool for operations

    // Global factor influencing time-based fluctuation decay/increase
    // Represents environmental noise or universal expansion metaphorically
    uint256 public globalFluctuationFactor = 1e16; // Default value

    struct State {
        uint256 stateId;
        int256 potentialValue;         // The 'base' value, shifts based on fluctuation
        uint256 fluctuationLevel;     // How much the value is likely to change (volatility)
        uint256 stability;            // Resistance to fluctuation and perturbation
        uint48 lastObservedTime;      // Timestamp of the last interaction/observation
        address currentObserver;      // Address of the last entity to observe
        bool isEntangled;             // Is this state entangled?
        uint256 entanglementPartnerId; // ID of the entangled state
        uint256 stateCharge;          // Charge specific to this state
        address custody;              // Address controlling this state's interactions
    }

    mapping(uint256 => State) public quantumStates;
    mapping(uint256 => uint256) private entangledPairs; // Map ID to its entangled partner ID

    // --- Events ---
    event StateCreated(uint256 indexed stateId, address indexed creator, int256 initialPotentialValue);
    event StatePerturbed(uint256 indexed stateId, address indexed actor, uint256 perturbationAmount);
    event StateStabilized(uint256 indexed stateId, address indexed actor, uint256 stabilizationAmount);
    event StateObserved(uint256 indexed stateId, address indexed observer, int256 collapsedValue);
    event ChargeAdded(address indexed contributor, uint256 amount);
    event ChargeDistributed(uint256 indexed stateId, uint256 amount, address indexed distributor);
    event ChargeCollected(uint256 indexed stateId, uint256 amount, address indexed collector);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2, address indexed actor);
    event StateDisentangled(uint256 indexed stateId, address indexed actor);
    event EntangledInteraction(uint256 indexed stateId, uint256 indexed partnerStateId, address indexed actor);
    event CustodyTransferred(uint256 indexed stateId, address indexed from, address indexed to);
    event QuantumOutcomePredicted(uint256 indexed stateId, int256 predictedValue, bytes32 indexed predictionHash);
    event CascadingPerturbationTriggered(uint256 indexed stateId, uint256 initialPerturbation, uint256 depth, address indexed actor);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "QF: Not the owner");
        _;
    }

    modifier whenStateExists(uint256 _stateId) {
        require(_stateId > 0 && _stateId < nextStateId, "QF: State does not exist");
        _;
    }

    modifier onlyStateCustodian(uint256 _stateId) {
        require(quantumStates[_stateId].custody == msg.sender, "QF: Not state custodian");
        _;
    }

    modifier requiresCharge(uint256 _stateId, uint256 _requiredCharge) {
        uint256 availableCharge = quantumStates[_stateId].stateCharge + globalQuantumCharge;
        require(availableCharge >= _requiredCharge, "QF: Insufficient quantum charge");
        // This modifier only checks availability. The function using it must consume the charge.
        _;
    }

    // --- Constructor ---
    constructor() payable {
        owner = msg.sender;
        nextStateId = 1; // Start IDs from 1
        globalQuantumCharge = msg.value; // Seed initial charge
    }

    // --- Helper Functions (Internal/View Logic) ---

    /**
     * @dev Calculates a pseudo-random factor based on block data and state properties.
     * @param _stateId The ID of the state.
     * @return A uint256 representing a pseudo-random value.
     * @notice This is NOT cryptographically secure randomness. It's predictable.
     */
    function _getPseudoRandomFactor(uint256 _stateId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            _stateId,
            msg.sender,
            tx.origin,
            gasleft()
        )));
    }

    /**
     * @dev Calculates the current estimated fluctuated value of a state.
     *      Formula: potentialValue + (pseudo_random_factor * fluctuationLevel / (stability + 1)) * time_since_observation_factor
     *      Uses fixed point arithmetic by scaling.
     * @param _stateId The ID of the state.
     * @return The calculated fluctuated value.
     */
    function _calculateFluctuatedValue(uint256 _stateId) internal view whenStateExists(_stateId) returns (int256) {
        State storage state = quantumStates[_stateId];
        uint256 timeSinceObservation = block.timestamp - state.lastObservedTime;

        // timeSinceObservationFactor scales with time, maybe exponentially or linearly capped
        // Let's use a simple linear scale for now, capped to avoid overflow
        uint256 timeFactor = timeSinceObservation > 1000 ? 1000 : timeSinceObservation;

        // Pseudo-random component scaled by fluctuation and inversely by stability
        // Scale factors to handle fixed-point style multiplication/division
        uint256 randomFactor = _getPseudoRandomFactor(_stateId) % 1e10; // Cap random factor range

        // Avoid division by zero for stability
        uint256 effectiveStability = state.stability == 0 ? 1 : state.stability;

        // Calculate fluctuation delta: (random * fluctuation * timeFactor * globalFactor) / (stability * scale)
        // Use large multipliers to keep precision before division
        uint256 fluctuationMagnitude = (randomFactor * state.fluctuationLevel * timeFactor * globalFluctuationFactor) / (effectiveStability * 1e10 * 1e18); // Scale down after mults

        // Make it positive or negative based on another random bit
        int256 fluctuationDelta = (randomFactor % 2 == 0) ? int256(fluctuationMagnitude) : -int256(fluctuationMagnitude);

        // Add delta to potential value
        return state.potentialValue + fluctuationDelta;
    }

    /**
     * @dev Consumes charge, prioritizing state charge then global charge.
     * @param _stateId The ID of the state involved in the operation.
     * @param _amount The amount of charge to consume.
     * @return bool True if charge was consumed successfully.
     */
    function _consumeCharge(uint256 _stateId, uint256 _amount) internal returns (bool) {
        State storage state = quantumStates[_stateId];
        if (state.stateCharge >= _amount) {
            state.stateCharge -= _amount;
            return true;
        } else {
            uint256 remaining = _amount - state.stateCharge;
            state.stateCharge = 0;
            if (globalQuantumCharge >= remaining) {
                globalQuantumCharge -= remaining;
                return true;
            } else {
                // Should not happen if requiresCharge modifier is used correctly
                return false;
            }
        }
    }

    /**
     * @dev Applies a perturbation effect to a state, decreasing stability and increasing fluctuation.
     * @param _stateId The ID of the state.
     * @param _amount The amount of perturbation.
     */
    function _applyPerturbation(uint256 _stateId, uint256 _amount) internal {
        State storage state = quantumStates[_stateId];
        state.stability = state.stability >= _amount ? state.stability - _amount : 0;
        state.fluctuationLevel += _amount;
        // Perturbation might slightly shift potential value
        state.potentialValue += int256(_amount * (_getPseudoRandomFactor(_stateId) % 10 - 5)); // Small random shift
        emit StatePerturbed(_stateId, msg.sender, _amount);
    }

    /**
     * @dev Applies a stabilization effect to a state, increasing stability and decreasing fluctuation.
     * @param _stateId The ID of the state.
     * @param _amount The amount of stabilization.
     */
    function _applyStabilization(uint256 _stateId, uint256 _amount) internal {
        State storage state = quantumStates[_stateId];
        state.stability += _amount;
        state.fluctuationLevel = state.fluctuationLevel >= _amount ? state.fluctuationLevel - _amount : 0;
        // Stabilization might slightly shift potential value towards zero or a 'ground state'
        if (state.potentialValue > 0) state.potentialValue -= int256(_amount * (_getPseudoRandomFactor(_stateId) % 2 + 1));
        if (state.potentialValue < 0) state.potentialValue += int256(_amount * (_getPseudoRandomFactor(_stateId) % 2 + 1));
        emit StateStabilized(_stateId, msg.sender, _amount);
    }


    // --- Public / External Functions (20+ total) ---

    /**
     * @dev Creates a new Quantum State.
     * @param _initialPotentialValue The starting value for the state.
     * @param _initialFluctuationLevel The initial volatility.
     * @param _initialStability The initial resistance to change.
     * @return The ID of the newly created state.
     */
    function createQuantumState(
        int256 _initialPotentialValue,
        uint256 _initialFluctuationLevel,
        uint256 _initialStability
    ) external returns (uint256) {
        uint256 newStateId = nextStateId;
        quantumStates[newStateId] = State({
            stateId: newStateId,
            potentialValue: _initialPotentialValue,
            fluctuationLevel: _initialFluctuationLevel,
            stability: _initialStability,
            lastObservedTime: uint48(block.timestamp),
            currentObserver: msg.sender, // Creator is initial observer
            isEntangled: false,
            entanglementPartnerId: 0,
            stateCharge: 0, // Starts with no state-specific charge
            custody: msg.sender // Creator is initial custodian
        });
        nextStateId++;
        emit StateCreated(newStateId, msg.sender, _initialPotentialValue);
        return newStateId;
    }

    /**
     * @dev Gets the total number of states created.
     * @return The count of states.
     */
    function getNumberOfStates() external view returns (uint256) {
        return nextStateId - 1; // Since IDs start at 1
    }

    /**
     * @dev Retrieves all details for a specific state.
     * @param _stateId The ID of the state.
     * @return A tuple containing all State struct members.
     */
    function getStateDetails(uint256 _stateId)
        external
        view
        whenStateExists(_stateId)
        returns (
            uint256 stateId,
            int256 potentialValue,
            uint256 fluctuationLevel,
            uint256 stability,
            uint48 lastObservedTime,
            address currentObserver,
            bool isEntangled,
            uint256 entanglementPartnerId,
            uint256 stateCharge,
            address custody
        )
    {
        State storage state = quantumStates[_stateId];
        return (
            state.stateId,
            state.potentialValue,
            state.fluctuationLevel,
            state.stability,
            state.lastObservedTime,
            state.currentObserver,
            state.isEntangled,
            state.entanglementPartnerId,
            state.stateCharge,
            state.custody
        );
    }

    /**
     * @dev Increases the fluctuation level and slightly decreases stability of a state.
     *      Costs charge (proportional to amount).
     * @param _stateId The ID of the state.
     * @param _perturbationAmount The amount to perturb.
     */
    function perturbState(uint256 _stateId, uint256 _perturbationAmount)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, _perturbationAmount / 1000 + 1) // Example charge cost
    {
        uint256 chargeCost = _perturbationAmount / 1000 + 1;
        require(_consumeCharge(_stateId, chargeCost), "QF: Failed to consume charge for perturb");
        _applyPerturbation(_stateId, _perturbationAmount);

        // If entangled, slightly perturb partner inversely
        State storage state = quantumStates[_stateId];
        if (state.isEntangled) {
            uint256 partnerId = state.entanglementPartnerId;
            if (partnerId != 0 && partnerId < nextStateId) {
                 // Apply a smaller, inverse perturbation effect to the partner
                _applyStabilization(partnerId, _perturbationAmount / 2);
                emit EntangledInteraction(_stateId, partnerId, msg.sender);
            }
        }
    }

    /**
     * @dev Increases the stability level and slightly decreases fluctuation of a state.
     *      Costs charge (proportional to amount).
     * @param _stateId The ID of the state.
     * @param _stabilizationAmount The amount to stabilize.
     */
    function stabilizeState(uint256 _stateId, uint256 _stabilizationAmount)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, _stabilizationAmount / 1000 + 1) // Example charge cost
    {
        uint256 chargeCost = _stabilizationAmount / 1000 + 1;
        require(_consumeCharge(_stateId, chargeCost), "QF: Failed to consume charge for stabilize");
        _applyStabilization(_stateId, _stabilizationAmount);

         // If entangled, slightly stabilize partner
        State storage state = quantumStates[_stateId];
        if (state.isEntangled) {
            uint256 partnerId = state.entanglementPartnerId;
             if (partnerId != 0 && partnerId < nextStateId) {
                // Apply a smaller, proportional stabilization effect to the partner
                _applyStabilization(partnerId, _stabilizationAmount / 2);
                emit EntangledInteraction(_stateId, partnerId, msg.sender);
            }
        }
    }

    /**
     * @dev Simulates 'observing' a state. The state's potential value is set
     *      to its current estimated fluctuated value, and fluctuation is slightly reduced.
     *      Updates the last observed time and observer. Costs charge.
     * @param _stateId The ID of the state.
     */
    function observeState(uint256 _stateId)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 100) // Example charge cost
    {
        require(_consumeCharge(_stateId, 100), "QF: Failed to consume charge for observe");

        State storage state = quantumStates[_stateId];
        int256 collapsedValue = _calculateFluctuatedValue(_stateId);

        state.potentialValue = collapsedValue;
        state.lastObservedTime = uint48(block.timestamp);
        state.currentObserver = msg.sender;

        // Observation reduces fluctuation slightly (collapses the wave function metaphor)
        state.fluctuationLevel = state.fluctuationLevel >= 50 ? state.fluctuationLevel - 50 : 0;

        emit StateObserved(_stateId, msg.sender, collapsedValue);

        // If entangled, observing one might affect the partner (e.g., collapse its fluctuation too)
        if (state.isEntangled) {
            uint256 partnerId = state.entanglementPartnerId;
             if (partnerId != 0 && partnerId < nextStateId) {
                State storage partnerState = quantumStates[partnerId];
                 if(partnerState.isEntangled && partnerState.entanglementPartnerId == _stateId) { // Double check entanglement
                    partnerState.potentialValue = _calculateFluctuatedValue(partnerId);
                    partnerState.lastObservedTime = uint48(block.timestamp);
                    // Partner's fluctuation is also affected
                    partnerState.fluctuationLevel = partnerState.fluctuationLevel >= 25 ? partnerState.fluctuationLevel - 25 : 0;
                    emit StateObserved(partnerId, msg.sender, partnerState.potentialValue); // Emit event for partner too
                    emit EntangledInteraction(_stateId, partnerId, msg.sender);
                 }
            }
        }
    }

    /**
     * @dev Calculates and returns the *estimated* current fluctuated value of a state
     *      without changing the state's properties (a read-only operation).
     * @param _stateId The ID of the state.
     * @return The estimated fluctuated value.
     */
    function getCurrentlyFluctuatedValue(uint256 _stateId)
        external
        view
        whenStateExists(_stateId)
        returns (int256)
    {
        return _calculateFluctuatedValue(_stateId);
    }

    /**
     * @dev Attempts to predict a binary or weighted outcome based on state properties
     *      and pseudo-randomness. Costs charge.
     * @param _stateId The ID of the state.
     * @param _predictionModifier A user-provided modifier to influence the prediction process (abstract).
     * @return A value representing the predicted outcome (e.g., -1, 0, or 1).
     */
    function predictQuantumOutcome(uint256 _stateId, uint256 _predictionModifier)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 200) // Example charge cost
        returns (int256)
    {
        require(_consumeCharge(_stateId, 200), "QF: Failed to consume charge for predict");

        State storage state = quantumStates[_stateId];
        // Use a hash incorporating state properties, modifier, and block data for pseudo-randomness
        bytes32 predictionHash = keccak256(abi.encodePacked(
            _stateId,
            state.potentialValue,
            state.fluctuationLevel,
            state.stability,
            block.timestamp,
            block.number,
            msg.sender,
            _predictionModifier
        ));

        uint256 randomValue = uint256(predictionHash);

        // Predict an outcome based on randomness and state properties
        // Simplified logic: More stable/less fluctuation -> more likely to predict value near 0
        // Higher fluctuation -> more likely to predict extreme values (-1 or 1)
        uint256 stabilityInfluence = state.stability > 0 ? state.stability : 1;
        uint256 fluctuationInfluence = state.fluctuationLevel > 0 ? state.fluctuationLevel : 1;

        uint256 threshold = (stabilityInfluence * 1e18) / (fluctuationInfluence + stabilityInfluence); // Scale threshold based on ratio

        int256 outcome;
        if (randomValue % 1e18 < threshold) {
            // Predict value is near zero (more likely with high stability)
            outcome = 0;
        } else {
            // Predict value is extreme (more likely with high fluctuation)
            outcome = (randomValue % 2 == 0) ? 1 : -1;
        }

        emit QuantumOutcomePredicted(_stateId, outcome, predictionHash);
        return outcome;
    }


    /**
     * @dev Combines observing the state and then predicting an outcome immediately after collapse.
     *      Costs charge (combined cost).
     * @param _stateId The ID of the state.
     * @return The predicted outcome after observation.
     */
    function collapseAndPredict(uint256 _stateId)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 300) // Cost of observe (100) + predict (200)
        returns (int256)
    {
        // Consume charge for both operations at once
        require(_consumeCharge(_stateId, 300), "QF: Failed to consume charge for collapse and predict");

        // Perform observation first
        State storage state = quantumStates[_stateId];
        int256 collapsedValue = _calculateFluctuatedValue(_stateId);
        state.potentialValue = collapsedValue;
        state.lastObservedTime = uint48(block.timestamp);
        state.currentObserver = msg.sender;
        state.fluctuationLevel = state.fluctuationLevel >= 50 ? state.fluctuationLevel - 50 : 0;
        emit StateObserved(_stateId, msg.sender, collapsedValue);

         // If entangled, observing one also affects partner before prediction
        if (state.isEntangled) {
             uint256 partnerId = state.entanglementPartnerId;
             if (partnerId != 0 && partnerId < nextStateId) {
                 State storage partnerState = quantumStates[partnerId];
                 if(partnerState.isEntangled && partnerState.entanglementPartnerId == _stateId) { // Double check entanglement
                     partnerState.potentialValue = _calculateFluctuatedValue(partnerId);
                     partnerState.lastObservedTime = uint48(block.timestamp);
                     partnerState.fluctuationLevel = partnerState.fluctuationLevel >= 25 ? partnerState.fluctuationLevel - 25 : 0;
                     emit StateObserved(partnerId, msg.sender, partnerState.potentialValue);
                     emit EntangledInteraction(_stateId, partnerId, msg.sender);
                 }
             }
         }


        // Then perform prediction on the collapsed state
        bytes32 predictionHash = keccak256(abi.encodePacked(
            _stateId,
            state.potentialValue, // Use the new collapsed value
            state.fluctuationLevel, // Use the new fluctuation level
            state.stability,
            block.timestamp, // Still use current block data
            block.number,
            msg.sender,
            0 // No modifier for this specific prediction step
        ));
         uint256 randomValue = uint256(predictionHash);

        uint256 stabilityInfluence = state.stability > 0 ? state.stability : 1;
        uint256 fluctuationInfluence = state.fluctuationLevel > 0 ? state.fluctuationLevel : 1;

        uint256 threshold = (stabilityInfluence * 1e18) / (fluctuationInfluence + stabilityInfluence);

        int256 outcome;
        if (randomValue % 1e18 < threshold) {
            outcome = 0;
        } else {
            outcome = (randomValue % 2 == 0) ? 1 : -1;
        }

        emit QuantumOutcomePredicted(_stateId, outcome, predictionHash);
        return outcome;
    }


    /**
     * @dev Adds Ether to the global quantum charge pool.
     */
    receive() external payable {
        addGlobalQuantumCharge();
    }

    /**
     * @dev Adds Ether to the global quantum charge pool.
     *      External callable wrapper for `receive()`.
     */
    function addGlobalQuantumCharge() public payable {
        globalQuantumCharge += msg.value;
        emit ChargeAdded(msg.sender, msg.value);
    }

    /**
     * @dev Owner can withdraw accumulated Ether (global charge).
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawGlobalQuantumCharge(uint256 _amount) external onlyOwner {
        require(globalQuantumCharge >= _amount, "QF: Insufficient global charge to withdraw");
        globalQuantumCharge -= _amount;
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "QF: ETH withdrawal failed");
    }

    /**
     * @dev Distributes charge from the global pool to a specific state's charge pool.
     *      Costs charge (small fixed fee).
     * @param _stateId The ID of the state.
     * @param _amount The amount of charge to distribute.
     */
    function distributeStateCharge(uint256 _stateId, uint256 _amount)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 10) // Small fixed cost for the operation itself
    {
        require(_consumeCharge(_stateId, 10), "QF: Failed to consume charge for distribute"); // Consume operation cost first
        require(globalQuantumCharge >= _amount, "QF: Insufficient global charge to distribute");
        globalQuantumCharge -= _amount;
        quantumStates[_stateId].stateCharge += _amount;
        emit ChargeDistributed(_stateId, _amount, msg.sender);
    }

    /**
     * @dev Collects charge from a state's charge pool back to the global pool.
     *      Costs charge (small fixed fee).
     * @param _stateId The ID of the state.
     * @param _amount The amount of charge to collect.
     */
    function collectStateCharge(uint256 _stateId, uint256 _amount)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 10) // Small fixed cost
    {
        require(_consumeCharge(_stateId, 10), "QF: Failed to consume charge for collect"); // Consume operation cost first
        State storage state = quantumStates[_stateId];
        require(state.stateCharge >= _amount, "QF: Insufficient state charge to collect");
        state.stateCharge -= _amount;
        globalQuantumCharge += _amount;
        emit ChargeCollected(_stateId, _amount, msg.sender);
    }

    /**
     * @dev Gets the current total global quantum charge.
     * @return The amount of global charge.
     */
    function getGlobalCharge() external view returns (uint256) {
        return globalQuantumCharge;
    }

    /**
     * @dev Gets the current quantum charge held by a specific state.
     * @param _stateId The ID of the state.
     * @return The amount of state charge.
     */
    function getStateCharge(uint256 _stateId) external view whenStateExists(_stateId) returns (uint256) {
        return quantumStates[_stateId].stateCharge;
    }

    /**
     * @dev Creates an entanglement link between two states.
     *      Requires custody of both states and costs charge.
     * @param _stateId1 The ID of the first state.
     * @param _stateId2 The ID of the second state.
     */
    function entangleStates(uint256 _stateId1, uint256 _stateId2)
        external
        whenStateExists(_stateId1)
        whenStateExists(_stateId2)
        onlyStateCustodian(_stateId1)
        onlyStateCustodian(_stateId2)
        requiresCharge(_stateId1, 500) // Example high cost for entanglement
    {
        require(_stateId1 != _stateId2, "QF: Cannot entangle a state with itself");
        require(!quantumStates[_stateId1].isEntangled, "QF: State 1 is already entangled");
        require(!quantumStates[_stateId2].isEntangled, "QF: State 2 is already entangled");

        // Consume charge, requires enough total charge across both states/global
        // Or simplify and check combined charge from one state and global?
        // Let's make it require enough charge from _stateId1 + global pool for simplicity in the modifier.
        // Actual consumption:
        uint256 chargeCost = 500;
        // Check requiresCharge(_stateId1, chargeCost) covers the total pool check.
        // Now consume from pool based on _stateId1:
        require(_consumeCharge(_stateId1, chargeCost), "QF: Failed to consume charge for entanglement");


        State storage state1 = quantumStates[_stateId1];
        State storage state2 = quantumStates[_stateId2];

        state1.isEntangled = true;
        state1.entanglementPartnerId = _stateId2;
        state2.isEntangled = true;
        state2.entanglementPartnerId = _stateId1;

        entangledPairs[_stateId1] = _stateId2;
        entangledPairs[_stateId2] = _stateId1;

        emit StatesEntangled(_stateId1, _stateId2, msg.sender);
    }

    /**
     * @dev Breaks the entanglement link for a state. Its partner is also disentangled.
     *      Costs charge. Requires custody.
     * @param _stateId The ID of the state to disentangle.
     */
    function disentangleState(uint256 _stateId)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 200) // Example cost
    {
        State storage state = quantumStates[_stateId];
        require(state.isEntangled, "QF: State is not entangled");

        uint256 chargeCost = 200;
        require(_consumeCharge(_stateId, chargeCost), "QF: Failed to consume charge for disentangle");

        uint256 partnerId = state.entanglementPartnerId;
        require(partnerId != 0 && partnerId < nextStateId, "QF: Invalid entanglement partner");

        State storage partnerState = quantumStates[partnerId];
        require(partnerState.isEntangled && partnerState.entanglementPartnerId == _stateId, "QF: Partner state invalidly entangled");

        state.isEntangled = false;
        state.entanglementPartnerId = 0;
        partnerState.isEntangled = false;
        partnerState.entanglementPartnerId = 0;

        delete entangledPairs[_stateId];
        delete entangledPairs[partnerId];

        emit StateDisentangled(_stateId, msg.sender);
        emit StateDisentangled(partnerId, msg.sender); // Also emit for partner
    }

    /**
     * @dev Gets the ID of the entangled partner state. Returns 0 if not entangled.
     * @param _stateId The ID of the state.
     * @return The ID of the partner state, or 0.
     */
    function getEntangledPartner(uint256 _stateId) external view whenStateExists(_stateId) returns (uint256) {
        return quantumStates[_stateId].entanglementPartnerId;
    }

     /**
     * @dev Checks if a state is currently entangled.
     * @param _stateId The ID of the state.
     * @return True if entangled, false otherwise.
     */
    function isStateEntangled(uint256 _stateId) external view whenStateExists(_stateId) returns (bool) {
        return quantumStates[_stateId].isEntangled;
    }


    /**
     * @dev Transfers custody of a state to a new address.
     *      Requires current custody. Costs charge (small fixed fee).
     * @param _stateId The ID of the state.
     * @param _newCustodian The address to transfer custody to.
     */
    function transferStateCustody(uint256 _stateId, address _newCustodian)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 50) // Example cost
    {
        require(_newCustodian != address(0), "QF: New custodian cannot be zero address");
        require(_consumeCharge(_stateId, 50), "QF: Failed to consume charge for custody transfer");

        Address oldCustodian = quantumStates[_stateId].custody;
        quantumStates[_stateId].custody = _newCustodian;
        emit CustodyTransferred(_stateId, oldCustodian, _newCustodian);
    }

    /**
     * @dev Gets the current custodian of a state.
     * @param _stateId The ID of the state.
     * @return The address of the custodian.
     */
    function getCustody(uint256 _stateId) external view whenStateExists(_stateId) returns (address) {
        return quantumStates[_stateId].custody;
    }

    /**
     * @dev Triggers a perturbation effect that cascades to neighboring states (by ID)
     *      and entangled partners up to a certain depth.
     *      Can be gas-intensive depending on depth and number of states.
     *      Costs charge (cost scales with depth). Requires custody.
     * @param _stateId The ID of the state to start the cascade.
     * @param _cascadeDepth The maximum depth of the cascade.
     */
    function triggerCascadingPerturbation(uint256 _stateId, uint256 _cascadeDepth)
        external
        whenStateExists(_stateId)
        onlyStateCustodian(_stateId)
        requiresCharge(_stateId, 100 * (_cascadeDepth + 1)) // Cost scales with depth
    {
        uint256 chargeCost = 100 * (_cascadeDepth + 1);
        require(_consumeCharge(_stateId, chargeCost), "QF: Failed to consume charge for cascade");

        // Simple recursive helper function to manage the cascade
        _cascadePerturb(_stateId, _cascadeDepth, 1000); // Initial perturbation amount

        emit CascadingPerturbationTriggered(_stateId, 1000, _cascadeDepth, msg.sender);
    }

    // Internal helper for cascading perturbation
    function _cascadePerturb(uint256 _stateId, uint256 _remainingDepth, uint256 _perturbAmount) internal {
        if (_remainingDepth == 0 || _perturbAmount == 0 || _stateId == 0 || _stateId >= nextStateId) {
            return;
        }

        // Apply perturbation to the current state (scaled down)
        _applyPerturbation(_stateId, _perturbAmount / 2); // Effect diminishes per step

        // Propagate to neighbors (by ID) - simplified neighbors are just ID +/- 1
        if (_stateId > 1) {
            _cascadePerturb(_stateId - 1, _remainingDepth - 1, _perturbAmount / 4); // Further diminished effect
        }
        if (_stateId < nextStateId - 1) { // nextStateId is the next available ID, so limit is nextStateId - 1
             _cascadePerturb(_stateId + 1, _remainingDepth - 1, _perturbAmount / 4); // Further diminished effect
        }

        // Propagate to entangled partner
        State storage state = quantumStates[_stateId];
        if (state.isEntangled) {
            uint256 partnerId = state.entanglementPartnerId;
             if (partnerId != 0 && partnerId < nextStateId && quantumStates[partnerId].isEntangled && quantumStates[partnerId].entanglementPartnerId == _stateId) {
                // Apply an effect to the partner, potentially different from direct perturbation
                // Let's make it apply stabilization as an inverse reaction in the pair
                 _applyStabilization(partnerId, _perturbAmount / 3); // Different diminished effect
                emit EntangledInteraction(_stateId, partnerId, address(this)); // Emit from contract during cascade
             }
        }
    }

    /**
     * @dev Applies perturbation to a batch of states. Requires custody for *each* state in the batch.
     *      Costs charge (scales with the number of states and perturbation amount).
     *      Can be gas-intensive for large batches.
     * @param _stateIds An array of state IDs to perturb.
     * @param _perturbationAmount The amount of perturbation to apply to each state.
     */
    function batchPerturbStates(uint256[] calldata _stateIds, uint256 _perturbationAmount)
        external
        requiresCharge(0, (_perturbationAmount / 1000 + 1) * _stateIds.length + 100) // Estimate batch cost, check vs global+any state pool (using 0 as stateId placeholder)
    {
        uint256 totalChargeCost = (_perturbationAmount / 1000 + 1) * _stateIds.length + 100; // Fixed batch overhead + per-state cost
         require(_consumeCharge(0, totalChargeCost), "QF: Failed to consume charge for batch perturb"); // Consume from global pool (0)

        for (uint i = 0; i < _stateIds.length; i++) {
            uint256 stateId = _stateIds[i];
            // Check existence and custody for each state in the batch
            if (stateId > 0 && stateId < nextStateId && quantumStates[stateId].custody == msg.sender) {
                // Directly apply perturbation logic without requiring individual state charge for this batch op
                 _applyPerturbation(stateId, _perturbationAmount);
                 // Note: Entanglement side effects will also trigger within the loop
                 State storage state = quantumStates[stateId];
                if (state.isEntangled) {
                    uint256 partnerId = state.entanglementPartnerId;
                    if (partnerId != 0 && partnerId < nextStateId) {
                        _applyStabilization(partnerId, _perturbationAmount / 2);
                        emit EntangledInteraction(stateId, partnerId, msg.sender);
                    }
                }

            }
            // Optionally, could revert on first invalid state, or skip invalid ones.
            // Skipping allows partial success but might hide errors. Let's skip.
        }
    }

    /**
     * @dev Applies stabilization to a batch of states. Requires custody for *each* state in the batch.
     *      Costs charge (scales with the number of states and stabilization amount).
     *      Can be gas-intensive for large batches.
     * @param _stateIds An array of state IDs to stabilize.
     * @param _stabilizationAmount The amount of stabilization to apply to each state.
     */
     function batchStabilizeStates(uint256[] calldata _stateIds, uint256 _stabilizationAmount)
        external
        requiresCharge(0, (_stabilizationAmount / 1000 + 1) * _stateIds.length + 100) // Estimate batch cost
    {
        uint256 totalChargeCost = (_stabilizationAmount / 1000 + 1) * _stateIds.length + 100;
        require(_consumeCharge(0, totalChargeCost), "QF: Failed to consume charge for batch stabilize");

        for (uint i = 0; i < _stateIds.length; i++) {
            uint256 stateId = _stateIds[i];
            if (stateId > 0 && stateId < nextStateId && quantumStates[stateId].custody == msg.sender) {
                 _applyStabilization(stateId, _stabilizationAmount);
                 // Note: Entanglement side effects will also trigger within the loop
                 State storage state = quantumStates[stateId];
                if (state.isEntangled) {
                    uint256 partnerId = state.entanglementPartnerId;
                    if (partnerId != 0 && partnerId < nextStateId) {
                        _applyStabilization(partnerId, _stabilizationAmount / 2);
                        emit EntangledInteraction(stateId, partnerId, msg.sender);
                    }
                }
            }
        }
    }


    // --- Owner Function ---
    /**
     * @dev Owner can set the global factor influencing time-based fluctuation.
     * @param _newFactor The new global fluctuation factor.
     */
    function setGlobalFluctuationFactor(uint256 _newFactor) external onlyOwner {
        globalFluctuationFactor = _newFactor;
    }


    // --- Additional View Functions (Individual Properties) ---

    /**
     * @dev Returns just the potential value of a state.
     * @param _stateId The ID of the state.
     * @return The potential value.
     */
    function getStatePotentialValue(uint256 _stateId) external view whenStateExists(_stateId) returns (int256) {
        return quantumStates[_stateId].potentialValue;
    }

    /**
     * @dev Returns just the fluctuation level of a state.
     * @param _stateId The ID of the state.
     * @return The fluctuation level.
     */
    function getStateFluctuationLevel(uint256 _stateId) external view whenStateExists(_stateId) returns (uint256) {
        return quantumStates[_stateId].fluctuationLevel;
    }

     /**
     * @dev Returns just the stability level of a state.
     * @param _stateId The ID of the state.
     * @return The stability level.
     */
    function getStateStability(uint256 _stateId) external view whenStateExists(_stateId) returns (uint256) {
        return quantumStates[_stateId].stability;
    }

    /**
     * @dev Returns the last observed timestamp of a state.
     * @param _stateId The ID of the state.
     * @return The timestamp.
     */
    function getLastObservedTime(uint256 _stateId) external view whenStateExists(_stateId) returns (uint48) {
        return quantumStates[_stateId].lastObservedTime;
    }

    /**
     * @dev Returns the address of the last observer of a state.
     * @param _stateId The ID of the state.
     * @return The observer address.
     */
    function getCurrentObserver(uint256 _stateId) external view whenStateExists(_stateId) returns (address) {
        return quantumStates[_stateId].currentObserver;
    }

    // --- Fallback (Optional, good practice) ---
    fallback() external payable {
        // Default behavior could be to add global charge
        addGlobalQuantumCharge();
    }
}
```