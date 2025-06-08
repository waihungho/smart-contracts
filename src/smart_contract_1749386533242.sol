Okay, let's create a smart contract that plays with concepts inspired by quantum mechanics, specifically superposition, observation, entanglement, and decoherence, applied to data storage. It won't be actual quantum computing, but a conceptual simulation on the blockchain state.

We'll create pairs of 'entangled' storage states. Each state can exist in 'superposition' (holding multiple potential values) until it's 'observed' via a specific function call, which collapses it into one 'observed' value based on defined criteria (like oracle data, block properties, etc.). Modifying one state in superposition can 'influence' the potential outcomes or criteria of its entangled partner. Finally, states can be 'decohered' (finalized) or data can be 'tunneled' (transferred) between them.

This contract will be called `QuantumEntangledStorage`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledStorage
 * @dev A creative and advanced smart contract simulating quantum concepts (superposition, observation, entanglement, decoherence)
 *      applied to on-chain data storage.
 *      It manages pairs of 'entangled' states, each holding potential values until 'collapsed' by observation.
 *      One state's modification in superposition can 'influence' its entangled partner.
 *      States can be finalized ('decohered') or their observed data 'tunneled' elsewhere.
 *      Utilizes oracle simulation for observation criteria.
 */

/**
 * @dev Outline:
 * 1.  Enums: Define possible states (Superposition, Observed, Decohered, Errored).
 * 2.  Structs:
 *     - QuantumState: Represents one half of an entangled pair. Holds potential values, observed value, state, timestamps, observer address, influence factor.
 *     - ObservationCriteria: Defines how a Superposition state collapses (e.g., using oracle data, block properties).
 *     - EntangledPair: Holds two QuantumState structs (stateA, stateB), observation criteria for each, and pause status.
 * 3.  State Variables:
 *     - Owner: Contract deployer (basic access control).
 *     - EntangledPairs: Mapping from uint256 ID to EntangledPair struct.
 *     - pairCount: Counter for generating unique pair IDs.
 *     - oracles: Mapping from oracle ID (bytes32) to oracle contract address (address).
 *     - observedValueClaimants: Mapping from pair ID and state index (0 for A, 1 for B) to address allowed to claim the observed value.
 * 4.  Events: Signal key lifecycle events (creation, state change, observation, influence, tunneling, removal, etc.).
 * 5.  Modifiers: Custom modifiers for access control and state checks.
 * 6.  Functions:
 *     - Management/Setup:
 *         - constructor: Sets owner.
 *         - registerOracle: Register an address as an oracle.
 *         - setSpecificObserverPermission: Grant/revoke observer role for a state.
 *     - Pair/State Creation & Configuration:
 *         - createEntangledPair: Creates a new pair, initializes states.
 *         - setPotentialValues: Set/replace all potential values for a state.
 *         - addPotentialValue: Add a single potential value.
 *         - removePotentialValue: Remove a single potential value by index.
 *         - updatePotentialValueWeight: Adjust weight of a potential value (for weighted probability collapse).
 *         - setObservationCriteria: Define criteria for collapsing a state.
 *         - setInfluenceFactor: Define how much one state's actions influence its partner.
 *     - Interaction (Superposition):
 *         - influenceEntangledState: Modify partner state's potential values/criteria based on influence factor.
 *     - Observation (Superposition -> Observed):
 *         - collapseState: Performs the core observation and state collapse based on criteria. (Simulates measurement).
 *         - batchCollapseStates: Collapse multiple states in one call.
 *     - Finalization (Observed -> Decohered):
 *         - decohereState: Finalizes an observed state, preventing further changes or influence. (Simulates decoherence).
 *     - Data Transfer/Claim:
 *         - tunnelStateData: Transfer the observed value of a state to a target address (e.g., another contract/mapping). Conceptual tunneling.
 *         - assignObservedValueClaimant: Assign an address the right to claim the observed value.
 *         - claimObservedValue: Allow the assigned claimant to get the observed value. (View function, actual transfer depends on 'tunnel').
 *     - Lifecycle Management:
 *         - pausePairInteraction: Pause interaction for a specific pair.
 *         - unpausePairInteraction: Unpause interaction for a specific pair.
 *         - removeEntangledPair: Remove a pair (requires states to be decohered).
 *     - Query/View Functions:
 *         - getEntangledPair: Get full pair data.
 *         - getQuantumState: Get single state data.
 *         - getObservedValue: Get the observed value of a state.
 *         - getPotentialValues: Get potential values of a state.
 *         - getStateStatus: Get current state enum.
 *         - getObservationCriteria: Get criteria for a state.
 *         - getInfluenceFactor: Get influence factor for a state.
 *         - isObserver: Check if address is observer for a state.
 *         - getOracleAddress: Get registered oracle address.
 *         - getObservedValueClaimant: Get the address assigned to claim the value.
 */

// --- ENUMS ---

enum State {
    Superposition, // Can hold multiple potential values, subject to influence and observation
    Observed,      // Collapsed into a single value via observation
    Decohered,     // Finalized state, no further changes or influence
    Errored        // State transition failed or invalid
}

// --- STRUCTS ---

struct QuantumState {
    bytes[] potentialValues;    // Multiple possible outcomes (e.g., hashes, data snippets)
    uint256[] potentialWeights; // Weights for probabilistic collapse (optional, if criteria uses weighted random)
    bytes observedValue;        // The single value determined upon Observation
    State currentState;         // Current state (Superposition, Observed, Decohered)
    uint64 lastUpdated;         // Timestamp of last state-changing interaction
    address observerAddress;    // Specific address authorized to trigger Observation (optional)
    uint256 influenceFactor;    // How much influence this state exerts on its partner (conceptual)
}

struct ObservationCriteria {
    uint8 criteriaType; // 0: Block Hash, 1: Timestamp (current), 2: Oracle Data, 3: Weighted Random, etc.
    bytes32 oracleId;   // Identifier for oracle if criteriaType is Oracle Data
    bytes dataReference; // Specific data point reference for Oracle (e.g., feed ID, key) or other criteria data
}

struct EntangledPair {
    QuantumState stateA;
    QuantumState stateB;
    ObservationCriteria criteriaA; // How stateA collapses
    ObservationCriteria criteriaB; // How stateB collapses
    bool isPaused;              // Can interactions modify this pair?
}

// --- CONTRACT ---

contract QuantumEntangledStorage {
    address private immutable i_owner;
    uint256 private s_pairCount;

    mapping(uint256 => EntangledPair) private s_entangledPairs;
    mapping(bytes32 => address) private s_oracles; // Registered oracle contract addresses
    // Mapping to store who has the right to claim the observed value for a specific state
    mapping(uint256 => mapping(uint8 => address)) private s_observedValueClaimants; // pairId => stateIndex (0=A, 1=B) => claimant address


    // --- EVENTS ---

    event PairCreated(uint256 indexed pairId, address indexed creator);
    event PotentialValuesUpdated(uint256 indexed pairId, uint8 indexed stateIndex, uint256 numValues);
    event PotentialValueAdded(uint256 indexed pairId, uint8 indexed stateIndex, bytes value, uint256 weight);
    event PotentialValueRemoved(uint256 indexed pairId, uint8 indexed stateIndex, uint256 index);
    event PotentialValueWeightUpdated(uint256 indexed pairId, uint8 indexed stateIndex, uint256 index, uint256 newWeight);
    event ObservationCriteriaUpdated(uint256 indexed pairId, uint8 indexed stateIndex, uint8 criteriaType);
    event SpecificObserverSet(uint256 indexed pairId, uint8 indexed stateIndex, address indexed observer);
    event SpecificObserverRemoved(uint256 indexed pairId, uint8 indexed stateIndex, address indexed removedObserver);
    event InfluenceFactorUpdated(uint256 indexed pairId, uint8 indexed stateIndex, uint256 factor);
    event StateInfluenced(uint256 indexed pairId, uint8 indexed influencingStateIndex, uint8 indexed influencedStateIndex, uint256 influenceApplied);
    event StateCollapsed(uint256 indexed pairId, uint8 indexed stateIndex, bytes observedValue, uint8 criteriaTypeUsed);
    event BatchStatesCollapsed(uint256[] pairIds, uint8[] stateIndices);
    event StateDecohered(uint256 indexed pairId, uint8 indexed stateIndex);
    event StateTunneled(uint256 indexed pairId, uint8 indexed stateIndex, bytes observedValue, address indexed destination);
    event ObservedValueClaimantAssigned(uint256 indexed pairId, uint8 indexed stateIndex, address indexed claimant);
    event PairPaused(uint256 indexed pairId);
    event PairUnpaused(uint256 indexed pairId);
    event PairRemoved(uint256 indexed pairId);
    event OracleRegistered(bytes32 indexed oracleId, address indexed oracleAddress);

    // --- MODIFIERS ---

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not authorized: Owner only");
        _;
    }

    modifier onlyObserver(uint256 _pairId, uint8 _stateIndex) {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
        require(state.observerAddress == address(0) || msg.sender == state.observerAddress, "Not authorized: Specific observer required");
        _;
    }

    modifier whenNotPaused(uint256 _pairId) {
        require(!s_entangledPairs[_pairId].isPaused, "Pair is paused");
        _;
    }

    modifier pairExists(uint256 _pairId) {
        require(_pairId > 0 && _pairId <= s_pairCount && s_entangledPairs[_pairId].stateA.currentState != State.Errored, "Pair does not exist or was removed"); // Using Errored as a 'removed' flag conceptually for simplicity
        _;
    }

    modifier validStateIndex(uint8 _stateIndex) {
        require(_stateIndex == 0 || _stateIndex == 1, "Invalid state index (must be 0 for A or 1 for B)");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor() {
        i_owner = msg.sender;
        s_pairCount = 0; // Start ID counter from 1
    }

    // --- MANAGEMENT / SETUP ---

    /**
     * @dev Registers an oracle contract address under a given ID.
     * @param _oracleId A unique identifier for the oracle (e.g., "CHAINLINK_PRICE_FEED").
     * @param _oracleAddress The address of the oracle contract.
     */
    function registerOracle(bytes32 _oracleId, address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        s_oracles[_oracleId] = _oracleAddress;
        emit OracleRegistered(_oracleId, _oracleAddress);
    }

    /**
     * @dev Sets a specific observer address for a state within a pair. Only this address (or owner if address(0)) can collapse it.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _observer The address to set as the observer. Set to address(0) to allow anyone (or owner based on other modifiers).
     */
    function setSpecificObserverPermission(uint256 _pairId, uint8 _stateIndex, address _observer)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        state.observerAddress = _observer;

        if (_observer == address(0)) {
            emit SpecificObserverRemoved(_pairId, _stateIndex, state.observerAddress);
        } else {
             emit SpecificObserverSet(_pairId, _stateIndex, _observer);
        }
    }

    // --- PAIR / STATE CREATION & CONFIGURATION ---

    /**
     * @dev Creates a new entangled pair with initial potential values and criteria.
     * @param _initialPotentialA Initial potential values for stateA.
     * @param _initialWeightsA Initial weights for stateA (must match length of _initialPotentialA, or empty).
     * @param _criteriaA Observation criteria for stateA.
     * @param _initialPotentialB Initial potential values for stateB.
     * @param _initialWeightsB Initial weights for stateB (must match length of _initialPotentialB, or empty).
     * @param _criteriaB Observation criteria for stateB.
     * @return The ID of the newly created pair.
     */
    function createEntangledPair(
        bytes[] calldata _initialPotentialA,
        uint256[] calldata _initialWeightsA,
        ObservationCriteria calldata _criteriaA,
        bytes[] calldata _initialPotentialB,
        uint256[] calldata _initialWeightsB,
        ObservationCriteria calldata _criteriaB
    ) external onlyOwner returns (uint256) {
        require(_initialPotentialA.length > 0, "State A must have at least one potential value");
        require(_initialPotentialB.length > 0, "State B must have at least one potential value");
        if (_initialWeightsA.length > 0) require(_initialWeightsA.length == _initialPotentialA.length, "Weights A length must match potential values A length");
        if (_initialWeightsB.length > 0) require(_initialWeightsB.length == _initialPotentialB.length, "Weights B length must match potential values B length");

        s_pairCount++;
        uint256 newPairId = s_pairCount;

        s_entangledPairs[newPairId].stateA = QuantumState({
            potentialValues: _initialPotentialA,
            potentialWeights: _initialWeightsA,
            observedValue: "", // Empty initially
            currentState: State.Superposition,
            lastUpdated: uint64(block.timestamp),
            observerAddress: address(0), // Anyone can observe by default
            influenceFactor: 0 // Default no influence
        });

        s_entangledPairs[newPairId].stateB = QuantumState({
            potentialValues: _initialPotentialB,
            potentialWeights: _initialWeightsB,
            observedValue: "", // Empty initially
            currentState: State.Superposition,
            lastUpdated: uint64(block.timestamp),
            observerAddress: address(0), // Anyone can observe by default
            influenceFactor: 0 // Default no influence
        });

        s_entangledPairs[newPairId].criteriaA = _criteriaA;
        s_entangledPairs[newPairId].criteriaB = _criteriaB;
        s_entangledPairs[newPairId].isPaused = false;

        emit PairCreated(newPairId, msg.sender);
        emit PotentialValuesUpdated(newPairId, 0, _initialPotentialA.length);
        emit PotentialValuesUpdated(newPairId, 1, _initialPotentialB.length);
        emit ObservationCriteriaUpdated(newPairId, 0, _criteriaA.criteriaType);
        emit ObservationCriteriaUpdated(newPairId, 1, _criteriaB.criteriaType);


        return newPairId;
    }

    /**
     * @dev Sets/replaces the entire list of potential values and weights for a state in Superposition.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _newPotentialValues The new list of potential values.
     * @param _newWeights The new list of weights (must match length, or empty).
     */
    function setPotentialValues(uint256 _pairId, uint8 _stateIndex, bytes[] calldata _newPotentialValues, uint256[] calldata _newWeights)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Superposition, "State is not in Superposition");
        require(_newPotentialValues.length > 0, "Must provide at least one potential value");
        if (_newWeights.length > 0) require(_newWeights.length == _newPotentialValues.length, "Weights length must match potential values length");

        state.potentialValues = _newPotentialValues;
        state.potentialWeights = _newWeights; // Replaces existing weights
        state.lastUpdated = uint64(block.timestamp);

        emit PotentialValuesUpdated(_pairId, _stateIndex, _newPotentialValues.length);
    }

     /**
     * @dev Adds a single potential value with an optional weight to a state in Superposition.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _valueToAdd The value to add.
     * @param _weightToAdd The weight for the value (0 or 1 if no weights used).
     */
    function addPotentialValue(uint256 _pairId, uint8 _stateIndex, bytes calldata _valueToAdd, uint256 _weightToAdd)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Superposition, "State is not in Superposition");
        // Check if state already has weights defined consistently
        if (state.potentialWeights.length > 0) {
             require(state.potentialValues.length == state.potentialWeights.length, "Inconsistent weights state"); // Should not happen if modifiers/checks are correct elsewhere
             state.potentialWeights.push(_weightToAdd);
        } else if (_weightToAdd > 0) {
            // If adding weight for the first time, need to initialize weights for all existing values
            revert("Cannot add weight to state without existing weights. Use updatePotentialValueWeight or setPotentialValues to initialize.");
        }

        state.potentialValues.push(_valueToAdd);
        state.lastUpdated = uint64(block.timestamp);

        emit PotentialValueAdded(_pairId, _stateIndex, _valueToAdd, _weightToAdd);
    }

     /**
     * @dev Removes a potential value by index from a state in Superposition.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _indexToRemove The index of the value to remove.
     */
    function removePotentialValue(uint256 _pairId, uint8 _stateIndex, uint256 _indexToRemove)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Superposition, "State is not in Superposition");
        require(_indexToRemove < state.potentialValues.length, "Index out of bounds");
        require(state.potentialValues.length > 1, "Cannot remove the last potential value"); // Must have at least one

        // Shift elements to remove the value at the specified index
        state.potentialValues[_indexToRemove] = state.potentialValues[state.potentialValues.length - 1];
        state.potentialValues.pop();

         // Handle weights similarly if they exist
        if (state.potentialWeights.length > 0) {
            state.potentialWeights[_indexToRemove] = state.potentialWeights[state.potentialWeights.length - 1];
            state.potentialWeights.pop();
        }

        state.lastUpdated = uint64(block.timestamp);

        emit PotentialValueRemoved(_pairId, _stateIndex, _indexToRemove);
    }

    /**
     * @dev Updates the weight of a specific potential value in a state in Superposition.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _indexToUpdate The index of the potential value whose weight to update.
     * @param _newWeight The new weight.
     */
    function updatePotentialValueWeight(uint256 _pairId, uint8 _stateIndex, uint256 _indexToUpdate, uint256 _newWeight)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Superposition, "State is not in Superposition");
        require(_indexToUpdate < state.potentialValues.length, "Index out of bounds");

        // Initialize weights array if it's empty
        if (state.potentialWeights.length == 0) {
            state.potentialWeights = new uint256[](state.potentialValues.length);
            // Default existing values to weight 1
            for(uint i = 0; i < state.potentialValues.length; i++) {
                 state.potentialWeights[i] = 1;
            }
        }
        require(state.potentialWeights.length == state.potentialValues.length, "Inconsistent weights state during update"); // Should not happen

        state.potentialWeights[_indexToUpdate] = _newWeight;
        state.lastUpdated = uint64(block.timestamp);

        emit PotentialValueWeightUpdated(_pairId, _stateIndex, _indexToUpdate, _newWeight);
    }


    /**
     * @dev Sets the observation criteria for a state.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _criteria The new observation criteria.
     */
    function setObservationCriteria(uint256 _pairId, uint8 _stateIndex, ObservationCriteria calldata _criteria)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        // Ensure criteria type is valid (0-3 defined, maybe more later)
        require(_criteria.criteriaType <= 3, "Invalid criteria type");

        if (_criteria.criteriaType == 2) { // Oracle Data
            require(s_oracles[_criteria.oracleId] != address(0), "Oracle not registered");
            require(_criteria.dataReference.length > 0, "Oracle data reference is required");
        }

        if (_stateIndex == 0) {
            pair.criteriaA = _criteria;
        } else {
            pair.criteriaB = _criteria;
        }

        // No state change for QuantumState, only criteria updated for future collapse
        // state.lastUpdated = uint64(block.timestamp); // Criteria update doesn't change the *state* itself

        emit ObservationCriteriaUpdated(_pairId, _stateIndex, _criteria.criteriaType);
    }

    /**
     * @dev Sets the influence factor for a state in Superposition.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _factor The new influence factor (conceptual value).
     */
    function setInfluenceFactor(uint256 _pairId, uint8 _stateIndex, uint256 _factor)
        external
        onlyOwner
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Superposition, "State is not in Superposition");

        state.influenceFactor = _factor;
        state.lastUpdated = uint64(block.timestamp);

        emit InfluenceFactorUpdated(_pairId, _stateIndex, _factor);
    }


    // --- INTERACTION (SUPERPOSITION) ---

    /**
     * @dev Simulates one state influencing its entangled partner while both are in Superposition.
     *      This can modify the partner's potential values, weights, or criteria based on the influencing state's factor.
     *      Conceptual: e.g., higher influence factor might double a weight or add a specific potential value.
     *      NOTE: This implementation provides a simple example; real-world influence logic would be complex.
     * @param _pairId The ID of the entangled pair.
     * @param _influencingStateIndex The index of the state applying influence (0 or 1).
     */
    function influenceEntangledState(uint256 _pairId, uint8 _influencingStateIndex)
        external
        pairExists(_pairId)
        validStateIndex(_influencingStateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage influencingState = (_influencingStateIndex == 0) ? pair.stateA : pair.stateB;
        QuantumState storage influencedState = (_influencingStateIndex == 0) ? pair.stateB : pair.stateA;
        uint8 influencedStateIndex = (_influencingStateIndex == 0) ? 1 : 0;

        require(influencingState.currentState == State.Superposition, "Influencing state must be in Superposition");
        require(influencedState.currentState == State.Superposition, "Influenced state must be in Superposition");
        require(influencingState.influenceFactor > 0, "Influencing state has no influence factor set");

        // --- Conceptual Influence Logic ---
        // This is a simplified example. Influence could:
        // - Add a new potential value to the influenced state
        // - Multiply weights in the influenced state's potentialWeights array
        // - Modify the influenced state's ObservationCriteria based on a mapping/rule
        // - etc.

        uint256 influenceMagnitude = influencingState.influenceFactor; // Use the factor

        // Example: Increase the weight of a random potential value in the influenced state
        // Using block.timestamp for pseudo-randomness - do NOT use for security-critical applications.
        // A real implementation might use Chainlink VRF or similar for better randomness.
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, influenceMagnitude)));

        if (influencedState.potentialValues.length > 0) {
             // Initialize weights if necessary
             if (influencedState.potentialWeights.length == 0 || influencedState.potentialWeights.length != influencedState.potentialValues.length) {
                influencedState.potentialWeights = new uint256[](influencedState.potentialValues.length);
                for(uint i = 0; i < influencedState.potentialValues.length; i++) {
                    influencedState.potentialWeights[i] = 1; // Default weight
                }
            }

            uint256 targetIndex = randomValue % influencedState.potentialValues.length;
            uint256 oldWeight = influencedState.potentialWeights[targetIndex];
            uint256 newWeight = oldWeight + (influenceMagnitude % 10 + 1); // Add 1-10 based on influence factor

            influencedState.potentialWeights[targetIndex] = newWeight;

            emit PotentialValueWeightUpdated(_pairId, influencedStateIndex, targetIndex, newWeight);
            emit StateInfluenced(_pairId, _influencingStateIndex, influencedStateIndex, influenceMagnitude);

             influencedState.lastUpdated = uint64(block.timestamp); // Partner is affected

        } else {
             // If no potential values, influence can't modify weights. Could potentially add a default value.
             // Skipping for this example, but could add logic here.
        }

         influencingState.lastUpdated = uint64(block.timestamp); // Influencing state also updated by action
    }


    // --- OBSERVATION (SUPERPOSITION -> OBSERVED) ---

    /**
     * @dev Performs the 'observation' on a state, collapsing its Superposition into a single Observed value
     *      based on its defined ObservationCriteria.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state to observe (0 for stateA, 1 for stateB).
     */
    function collapseState(uint256 _pairId, uint8 _stateIndex)
        external
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
        onlyObserver(_pairId, _stateIndex) // Only the designated observer (or owner if address(0)) can collapse
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
        ObservationCriteria storage criteria = (_stateIndex == 0) ? pair.criteriaA : pair.criteriaB;

        require(state.currentState == State.Superposition, "State is not in Superposition");
        require(state.potentialValues.length > 0, "State has no potential values to collapse");
        // Criteria must be set, although default (e.g. Block Hash) could be used implicitly if not set.
        // Adding an explicit check here forces configuration before collapse.
        require(criteria.criteriaType != 99, "Observation criteria not set"); // Using 99 as a 'not set' placeholder initially, though struct has defaults. Let's assume 0 is a valid type.

        bytes memory selectedValue;
        uint8 criteriaTypeUsed = criteria.criteriaType;

        // --- Collapse Logic based on Criteria ---
        if (criteria.criteriaType == 0) { // Block Hash
            // Use block.blockhash(block.number - 1) for deterministic choice based on previous block
            // Cannot use current block hash as it's not available during execution
            require(block.number > 0, "Cannot use blockhash on block 0");
            bytes32 blockHash = blockhash(block.number - 1);
            uint256 choiceIndex = uint256(blockHash) % state.potentialValues.length;
            selectedValue = state.potentialValues[choiceIndex];

        } else if (criteria.criteriaType == 1) { // Timestamp
            // Use current block timestamp for deterministic choice
            uint256 choiceIndex = block.timestamp % state.potentialValues.length;
            selectedValue = state.potentialValues[choiceIndex];

        } else if (criteria.criteriaType == 2) { // Oracle Data
            // This is a simulation. In a real contract, you'd interact with an oracle interface.
            // Example: Call a view function on the registered oracle contract.
            address oracleAddress = s_oracles[criteria.oracleId];
            require(oracleAddress != address(0), "Oracle not registered for this criteria");
            // Simulate getting data from oracle - replace with actual oracle call
            // e.g., IOracle(oracleAddress).getData(criteria.dataReference)
            // For simulation, let's use a pseudo-deterministic value derived from criteria reference and block data
            bytes32 oracleSimValue = keccak256(abi.encodePacked(oracleAddress, criteria.dataReference, block.number, block.timestamp));
            uint256 choiceIndex = uint256(oracleSimValue) % state.potentialValues.length;
             selectedValue = state.potentialValues[choiceIndex];

        } else if (criteria.criteriaType == 3) { // Weighted Random
             require(state.potentialWeights.length == state.potentialValues.length, "Weights must be set for weighted random collapse");
             uint256 totalWeight = 0;
             for(uint i = 0; i < state.potentialWeights.length; i++) {
                 totalWeight += state.potentialWeights[i];
             }
             require(totalWeight > 0, "Total weight must be greater than 0 for weighted random collapse");

             // Use block data for pseudo-random seed (again, not for security-critical random)
             uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalWeight)));
             uint256 cumulativeWeight = 0;
             uint256 choiceIndex = 0;

             // Find the index based on cumulative weights
             for(uint i = 0; i < state.potentialValues.length; i++) {
                 cumulativeWeight += state.potentialWeights[i];
                 if (randomNumber % totalWeight < cumulativeWeight) {
                     choiceIndex = i;
                     break;
                 }
             }
             selectedValue = state.potentialValues[choiceIndex];

        } else {
            // Default or other criteria types can be added
             revert("Unsupported observation criteria type");
        }

        // Collapse the state
        state.observedValue = selectedValue;
        state.currentState = State.Observed;
        state.lastUpdated = uint64(block.timestamp);

        // Clear potential values and weights to signify collapse
        delete state.potentialValues;
        delete state.potentialWeights;

        emit StateCollapsed(_pairId, _stateIndex, selectedValue, criteriaTypeUsed);
    }

    /**
     * @dev Collapses multiple states in a batch call.
     * @param _pairIds Array of pair IDs.
     * @param _stateIndices Array of state indices (0 or 1). Must match length of _pairIds.
     */
    function batchCollapseStates(uint256[] calldata _pairIds, uint8[] calldata _stateIndices) external {
        require(_pairIds.length == _stateIndices.length, "Input arrays must have same length");
        require(_pairIds.length > 0, "Input arrays cannot be empty");

        for (uint i = 0; i < _pairIds.length; i++) {
            // Call collapseState for each item. Use try/catch if you want partial success.
            // Simple loop will revert entire tx if any collapse fails.
            collapseState(_pairIds[i], _stateIndices[i]); // Uses its own modifiers (pairExists, validStateIndex, whenNotPaused, onlyObserver)
        }

        emit BatchStatesCollapsed(_pairIds, _stateIndices);
    }


    // --- FINALIZATION (OBSERVED -> DECOHERED) ---

    /**
     * @dev Finalizes an Observed state, moving it to Decohered. No further changes or influence possible.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state to decohere (0 for stateA, 1 for stateB).
     */
    function decohereState(uint256 _pairId, uint8 _stateIndex)
        external
        onlyOwner // Only owner can finalize
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Observed, "State is not in Observed state");

        state.currentState = State.Decohered;
        state.lastUpdated = uint64(block.timestamp);

        // Optionally clear observer/influence after decoherence
        state.observerAddress = address(0);
        state.influenceFactor = 0;

        emit StateDecohered(_pairId, _stateIndex);
    }

    // --- DATA TRANSFER / CLAIM ---

    /**
     * @dev Simulates 'tunneling' the Observed value of a state to a target address.
     *      This could conceptually represent transferring the data itself, or triggering an action
     *      elsewhere based on the observed value.
     *      NOTE: This implementation just emits an event. Real tunneling would interact with `_destination`.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state whose value to tunnel (0 or 1).
     * @param _destination The address or contract to 'tunnel' the value to.
     */
    function tunnelStateData(uint256 _pairId, uint8 _stateIndex, address _destination)
        external
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Observed || state.currentState == State.Decohered, "State is not Observed or Decohered");
        require(_destination != address(0), "Invalid destination address");
        require(state.observedValue.length > 0, "State has no observed value");

        // --- Conceptual Tunneling ---
        // In a real application, this might involve:
        // - Calling a function on `_destination` with `state.observedValue` as an argument.
        // - Updating a mapping in `_destination` contract.
        // - Transferring an ERC-721 or ERC-1155 token ID stored in `state.observedValue`.
        // - Sending Ether/tokens based on the value.

        // For this simulation, we just emit an event.
        // Add checks for claimant if you want to restrict who can tunnel
        address claimant = s_observedValueClaimants[_pairId][_stateIndex];
        require(claimant == address(0) || msg.sender == claimant || msg.sender == i_owner, "Not authorized to tunnel this value");


        emit StateTunneled(_pairId, _stateIndex, state.observedValue, _destination);

        // Optional: Clear observed value after tunneling if it's a one-time transfer
        // delete state.observedValue;
        // s_observedValueClaimants[_pairId][_stateIndex] = address(0); // Clear claimant after tunneling

        state.lastUpdated = uint64(block.timestamp);
    }


    /**
     * @dev Assigns an address the right to 'claim' or access the observed value of a state.
     *      This is separate from `tunnelStateData` and only grants permission.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 or 1).
     * @param _claimant The address to assign the claim right to. Set to address(0) to revoke.
     */
    function assignObservedValueClaimant(uint256 _pairId, uint8 _stateIndex, address _claimant)
        external
        onlyOwner // Only owner can assign claimants
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Observed || state.currentState == State.Decohered, "State is not Observed or Decohered");

        s_observedValueClaimants[_pairId][_stateIndex] = _claimant;

        emit ObservedValueClaimantAssigned(_pairId, _stateIndex, _claimant);
    }

    /**
     * @dev Allows a claimant to retrieve the observed value (view function).
     *      Does not perform any transfer, just provides the data.
     * @param _pairId The ID of the entangled pair.
     * @param _stateIndex The index of the state (0 or 1).
     * @return The observed value.
     */
    function claimObservedValue(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (bytes memory)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;

        require(state.currentState == State.Observed || state.currentState == State.Decohered, "State is not Observed or Decohered");

        address claimant = s_observedValueClaimants[_pairId][_stateIndex];
        require(claimant == address(0) || msg.sender == claimant || msg.sender == i_owner, "Not authorized to claim this value");

        return state.observedValue;
    }

    // --- LIFECYCLE MANAGEMENT ---

    /**
     * @dev Pauses interactions (excluding view functions and unpausing) for a specific pair.
     * @param _pairId The ID of the entangled pair to pause.
     */
    function pausePairInteraction(uint256 _pairId)
        external
        onlyOwner
        pairExists(_pairId)
    {
        require(!s_entangledPairs[_pairId].isPaused, "Pair is already paused");
        s_entangledPairs[_pairId].isPaused = true;
        emit PairPaused(_pairId);
    }

    /**
     * @dev Unpauses interactions for a specific pair.
     * @param _pairId The ID of the entangled pair to unpause.
     */
    function unpausePairInteraction(uint256 _pairId)
        external
        onlyOwner
        pairExists(_pairId)
    {
        require(s_entangledPairs[_pairId].isPaused, "Pair is not paused");
        s_entangledPairs[_pairId].isPaused = false;
        emit PairUnpaused(_pairId);
    }


    /**
     * @dev Removes a pair from storage. Requires both states to be Decohered.
     * @param _pairId The ID of the entangled pair to remove.
     */
    function removeEntangledPair(uint256 _pairId)
        external
        onlyOwner
        pairExists(_pairId)
        whenNotPaused(_pairId)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        require(pair.stateA.currentState == State.Decohered, "State A must be Decohered to remove pair");
        require(pair.stateB.currentState == State.Decohered, "State B must be Decohered to remove pair");

        // Conceptually remove by marking as Errored state and clearing mappings
        pair.stateA.currentState = State.Errored;
        pair.stateB.currentState = State.Errored;

        // Clear mappings for the pair
        delete s_entangledPairs[_pairId];
        delete s_observedValueClaimants[_pairId]; // Clear claimants for this pair

        // Note: This doesn't truly reduce gas usage for the slot, just marks it unusable/cleared conceptually.
        // To free up storage gas, you'd need to carefully set fields back to their default (zero) values before deleting.
        // For this example, marking as Errored in the struct and deleting the mapping entry is sufficient conceptually.

        emit PairRemoved(_pairId);
    }

    // --- QUERY / VIEW FUNCTIONS ---

    /**
     * @dev Returns the total number of pairs created.
     */
    function getPairCount() external view returns (uint256) {
        return s_pairCount;
    }

    /**
     * @dev Retrieves the full data structure for an entangled pair.
     * @param _pairId The ID of the pair.
     * @return The EntangledPair struct data.
     */
    function getEntangledPair(uint256 _pairId)
        external
        view
        pairExists(_pairId)
        returns (EntangledPair memory)
    {
        return s_entangledPairs[_pairId];
    }

    /**
     * @dev Retrieves the data structure for a single quantum state within a pair.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @return The QuantumState struct data.
     */
    function getQuantumState(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (QuantumState memory)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        return (_stateIndex == 0) ? pair.stateA : pair.stateB;
    }

    /**
     * @dev Gets the currently observed value for a state. Returns empty bytes if not yet Observed.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @return The observed value.
     */
    function getObservedValue(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (bytes memory)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
        require(state.currentState == State.Observed || state.currentState == State.Decohered, "State is not Observed or Decohered");
        return state.observedValue;
    }

    /**
     * @dev Gets the current list of potential values for a state. Returns empty array if already Observed/Decohered.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @return An array of potential values.
     */
    function getPotentialValues(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (bytes[] memory, uint256[] memory)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
        require(state.currentState == State.Superposition, "State is not in Superposition");
        return (state.potentialValues, state.potentialWeights);
    }

    /**
     * @dev Gets the current state status (Superposition, Observed, Decohered, Errored) for a state.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @return The State enum value.
     */
    function getStateStatus(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId) // Use a lighter check here if needed, but pairExists handles the 'removed' case
        validStateIndex(_stateIndex)
        returns (State)
    {
         // Manual check instead of pairExists modifier to handle the Errored state implicitly
        if (_pairId == 0 || _pairId > s_pairCount) {
            return State.Errored; // Invalid ID
        }
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
        return state.currentState;
    }

    /**
     * @dev Gets the observation criteria for a state.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @return The ObservationCriteria struct data.
     */
     function getObservationCriteria(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (ObservationCriteria memory)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        return (_stateIndex == 0) ? pair.criteriaA : pair.criteriaB;
    }

     /**
     * @dev Gets the influence factor for a state.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @return The influence factor.
     */
    function getInfluenceFactor(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (uint256)
    {
        EntangledPair storage pair = s_entangledPairs[_pairId];
        QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
        return state.influenceFactor;
    }

    /**
     * @dev Checks if an address is the specific observer for a state.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 for stateA, 1 for stateB).
     * @param _addr The address to check.
     * @return True if the address is the specific observer, false otherwise.
     */
    function isObserver(uint256 _pairId, uint8 _stateIndex, address _addr)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (bool)
    {
         EntangledPair storage pair = s_entangledPairs[_pairId];
         QuantumState storage state = (_stateIndex == 0) ? pair.stateA : pair.stateB;
         return state.observerAddress == _addr && _addr != address(0);
    }

    /**
     * @dev Gets the registered address for an oracle ID.
     * @param _oracleId The ID of the oracle.
     * @return The oracle contract address. Returns address(0) if not registered.
     */
    function getOracleAddress(bytes32 _oracleId) external view returns (address) {
        return s_oracles[_oracleId];
    }

     /**
     * @dev Gets the address assigned to claim the observed value for a state.
     * @param _pairId The ID of the pair.
     * @param _stateIndex The index of the state (0 or 1).
     * @return The claimant address. Returns address(0) if no claimant is assigned.
     */
    function getObservedValueClaimant(uint256 _pairId, uint8 _stateIndex)
        external
        view
        pairExists(_pairId)
        validStateIndex(_stateIndex)
        returns (address)
    {
        return s_observedValueClaimants[_pairId][_stateIndex];
    }

    // Add more view functions as needed for struct fields (lastUpdated, isPaused etc.)
    // For simplicity, some basic ones are included. Accessing others can be done via getEntangledPair.
    function getPairPausedStatus(uint256 _pairId) external view pairExists(_pairId) returns (bool) {
        return s_entangledPairs[_pairId].isPaused;
    }

     function getOwner() external view returns (address) {
         return i_owner;
     }
}
```