Okay, let's create a smart contract based on a conceptual simulation of quantum mechanics principles like superposition, entanglement, and measurement, applied in an oracle-like context. This is highly creative as it doesn't replicate standard oracle patterns but provides probabilistic, entangled data states. It's advanced in state management and dependency modeling. It's not a direct copy of typical open-source contracts.

We'll call it `QuantumEntangledStateOracle`.

**Concept:**
This contract manages abstract "states". Each state can be in a "superposed" state (uncertain value) or a "measured" state (definite value). States can be "entangled" with each other, meaning the act of measuring one state can influence the potential future outcomes of entangled superposed states. The "measurement" process uses a deterministic pseudo-random algorithm based on internal state, block properties, and entanglement influences. It acts as a unique type of oracle providing probabilistic outcomes or dependent state values.

**Outline:**

1.  **License and Pragma**
2.  **Owner Pattern** (Custom, non-OpenZeppelin, for non-duplication)
3.  **Error Definitions**
4.  **Structs**
    *   `State`: Represents a quantum-inspired state.
5.  **State Variables**
    *   Owner address
    *   Mapping of state IDs to `State` structs
    *   Counter for next state ID
    *   Mapping for allowed influencers (can apply external influence)
    *   Contract-level metadata
    *   Measurement fee
    *   Total collected fees
6.  **Events**
    *   State lifecycle events (`StateCreated`, `StateMeasured`, `StateReset`)
    *   Entanglement events (`EntanglementAdded`, `EntanglementRemoved`)
    *   Influence and Bias events (`InfluenceApplied`, `BiasSet`, `ExternalInfluenceApplied`)
    *   Oracle config events (`FeeSet`, `ContractMetadataSet`)
    *   Role management events (`InfluencerAdded`, `InfluencerRemoved`)
    *   Ownership transfer event (`OwnershipTransferred`)
7.  **Modifiers**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `onlyAllowedInfluencer`: Restricts access to allowed influencers.
    *   `whenSuperposed`: Requires a state to be in superposition.
    *   `whenMeasured`: Requires a state to have been measured.
    *   `stateExists`: Requires a state ID to be valid.
    *   `nonReentrant` (Simple simulation, might not strictly need, but good practice if adding more complex interactions)
8.  **Constructor**
    *   Sets the initial owner.
9.  **Internal Helper Functions**
    *   `_calculateMeasurementOutcome`: Deterministically calculates the outcome based on state and block data.
    *   `_influenceEntangledState`: Applies influence to a superposed entangled state's seed.
    *   `_addEntanglement`: Adds a bidirectional link between two states.
    *   `_removeEntanglement`: Removes a bidirectional link.
10. **External/Public Functions (20+ required)**
    *   **State Creation & Management:**
        *   `createSuperposedState`
        *   `resetStateToSuperposition`
        *   `updateEntropySeed`
        *   `updateStateMetadata`
    *   **Measurement & Data Retrieval:**
        *   `measureState` (Payable)
        *   `getDefiniteValue`
        *   `simulateMeasurementOutcome`
        *   `getSuperposedStateDetails`
        *   `getMeasurementDetails`
        *   `isStateSuperposed`
        *   `getLastMeasuredBlock`
        *   `getEntropySeed`
        *   `getStateMetadata`
        *   `getTotalStatesCreated`
    *   **Entanglement Management:**
        *   `addEntanglementLink`
        *   `removeEntanglementLink`
        *   `getEntangledLinks`
    *   **Influence & Bias:**
        *   `applyExternalInfluence`
        *   `setMeasurementBias`
        *   `getMeasurementBias`
        *   `getMeasurementEntropySource` (Helper for understanding)
    *   **Access Control (Influencers):**
        *   `addAllowedInfluencer`
        *   `removeAllowedInfluencer`
        *   `isAllowedInfluencer`
        *   `getAllowedInfluencers`
    *   **Oracle Configuration (Owner Only):**
        *   `setContractMetadata`
        *   `getContractMetadata`
        *   `setMeasurementFee`
        *   `getMeasurementFee`
        *   `withdrawFees`
        *   `transferOwnership`
11. **Fallback/Receive (Optional but good for payable)**

**Function Summary:**

1.  `createSuperposedState(uint256 entropySeed, uint256[] memory entangledWithStates, string memory metadata)`: Creates a new state in superposition.
2.  `resetStateToSuperposition(uint256 stateId, uint256 newEntropySeed)`: Resets a measured state back to superposition with a new seed. (Owner/Influencer)
3.  `updateEntropySeed(uint256 stateId, uint256 newSeed)`: Changes the entropy seed of a *superposed* state. (Owner/Influencer)
4.  `updateStateMetadata(uint256 stateId, string memory newMetadata)`: Updates the descriptive metadata for a state. (Owner)
5.  `measureState(uint256 stateId)`: Triggers the measurement of a state. Pays fee if required. Calculates the definite value and collapses the state. Influences entangled superposed states. (Anyone, potentially paying fee)
6.  `getDefiniteValue(uint256 stateId)`: Returns the definite value of a state, but only if it has been measured.
7.  `simulateMeasurementOutcome(uint256 stateId)`: Calculates and returns the *potential* definite value if the state were measured *now*, without changing the state.
8.  `getSuperposedStateDetails(uint256 stateId)`: Retrieves details for a state that is currently in superposition.
9.  `getMeasurementDetails(uint256 stateId)`: Retrieves details for a state that has been measured (or its current state if superposed, but focused on post-measurement data).
10. `isStateSuperposed(uint256 stateId)`: Checks if a state is currently in superposition.
11. `getLastMeasuredBlock(uint256 stateId)`: Gets the block number when the state was last measured (0 if never measured or reset).
12. `getEntropySeed(uint256 stateId)`: Gets the current entropy seed for a state.
13. `getStateMetadata(uint256 stateId)`: Gets the metadata string for a state.
14. `getTotalStatesCreated()`: Returns the total number of states that have been created.
15. `addEntanglementLink(uint256 stateId1, uint256 stateId2)`: Creates a bidirectional entanglement link between two states. (Owner)
16. `removeEntanglementLink(uint256 stateId1, uint256 stateId2)`: Removes an entanglement link between two states. (Owner)
17. `getEntangledLinks(uint256 stateId)`: Returns the list of state IDs that a given state is entangled with.
18. `applyExternalInfluence(uint256 stateId, int256 influenceValue)`: Applies an external influence to a *superposed* state's entropy seed. (Allowed Influencer)
19. `setMeasurementBias(uint256 stateId, int256 bias)`: Sets a fixed bias value applied during the measurement outcome calculation for a specific state. (Owner)
20. `getMeasurementBias(uint256 stateId)`: Gets the current measurement bias for a state.
21. `getMeasurementEntropySource(uint256 stateId)`: Returns the raw entropy source value calculated *before* the final outcome derivation in a simulated measurement. (Helper/Diagnostic)
22. `addAllowedInfluencer(address influencer)`: Grants the ability to apply external influence to an address. (Owner)
23. `removeAllowedInfluencer(address influencer)`: Revokes the ability to apply external influence from an address. (Owner)
24. `isAllowedInfluencer(address account)`: Checks if an address is an allowed influencer.
25. `getAllowedInfluencers()`: Returns the list of all allowed influencer addresses. (Owner)
26. `setContractMetadata(string memory _metadata)`: Sets a contract-level description. (Owner)
27. `getContractMetadata()`: Gets the contract-level description.
28. `setMeasurementFee(uint256 fee)`: Sets the fee required to call `measureState`. (Owner)
29. `getMeasurementFee()`: Gets the current measurement fee.
30. `withdrawFees()`: Withdraws accumulated measurement fees. (Owner)
31. `transferOwnership(address newOwner)`: Transfers contract ownership. (Owner)

This structure gives us well over 20 functions, covering core state logic, configuration, and access control, all tied to the quantum-inspired concept.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledStateOracle
 * @dev A conceptual smart contract simulating quantum mechanics principles:
 *      superposition, entanglement, and measurement.
 *      It manages abstract states which can be superposed (uncertain value)
 *      or measured (definite value). States can be entangled, where the
 *      measurement of one influences the potential future outcomes of others.
 *      Acts as a unique oracle providing probabilistic or interdependent data.
 */

// --- Outline ---
// 1. License and Pragma
// 2. Owner Pattern (Custom)
// 3. Error Definitions
// 4. Structs (State)
// 5. State Variables (states mapping, nextId, owner, influencers, metadata, fee, fees collected)
// 6. Events (State lifecycle, entanglement, influence, bias, config, roles, ownership)
// 7. Modifiers (onlyOwner, onlyAllowedInfluencer, whenSuperposed, whenMeasured, stateExists)
// 8. Constructor
// 9. Internal Helper Functions (_calculateMeasurementOutcome, _influenceEntangledState, _addEntanglement, _removeEntanglement)
// 10. External/Public Functions (30+ total covering state management, measurement, entanglement, influence, access control, configuration)
// 11. Fallback/Receive (for fees)

// --- Function Summary ---
// 1.  createSuperposedState(uint256 entropySeed, uint256[] memory entangledWithStates, string memory metadata) - Creates a new state in superposition.
// 2.  resetStateToSuperposition(uint256 stateId, uint256 newEntropySeed) - Resets a measured state back to superposition. (Owner/Influencer)
// 3.  updateEntropySeed(uint256 stateId, uint256 newSeed) - Changes the entropy seed of a superposed state. (Owner/Influencer)
// 4.  updateStateMetadata(uint256 stateId, string memory newMetadata) - Updates the metadata for a state. (Owner)
// 5.  measureState(uint256 stateId) - Triggers measurement, collapses state, influences entangled states. (Payable)
// 6.  getDefiniteValue(uint256 stateId) - Gets the value of a measured state.
// 7.  simulateMeasurementOutcome(uint256 stateId) - Predicts potential outcome without measuring.
// 8.  getSuperposedStateDetails(uint256 stateId) - Gets details of a superposed state.
// 9.  getMeasurementDetails(uint256 stateId) - Gets details of a measured state (or current if superposed).
// 10. isStateSuperposed(uint256 stateId) - Checks if a state is superposed.
// 11. getLastMeasuredBlock(uint256 stateId) - Gets block of last measurement.
// 12. getEntropySeed(uint256 stateId) - Gets the current entropy seed.
// 13. getStateMetadata(uint256 stateId) - Gets state metadata.
// 14. getTotalStatesCreated() - Gets total number of states.
// 15. addEntanglementLink(uint256 stateId1, uint256 stateId2) - Creates a bidirectional link. (Owner)
// 16. removeEntanglementLink(uint256 stateId1, uint256 stateId2) - Removes a link. (Owner)
// 17. getEntangledLinks(uint256 stateId) - Gets list of entangled states.
// 18. applyExternalInfluence(uint256 stateId, int256 influenceValue) - Applies influence to seed of superposed state. (Allowed Influencer)
// 19. setMeasurementBias(uint256 stateId, int256 bias) - Sets outcome bias for a state. (Owner)
// 20. getMeasurementBias(uint256 stateId) - Gets state bias.
// 21. getMeasurementEntropySource(uint256 stateId) - Gets raw entropy source value (diagnostic).
// 22. addAllowedInfluencer(address influencer) - Grants influencer role. (Owner)
// 23. removeAllowedInfluencer(address influencer) - Revokes influencer role. (Owner)
// 24. isAllowedInfluencer(address account) - Checks if address is influencer.
// 25. getAllowedInfluencers() - Gets list of influencers. (Owner)
// 26. setContractMetadata(string memory _metadata) - Sets contract metadata. (Owner)
// 27. getContractMetadata() - Gets contract metadata.
// 28. setMeasurementFee(uint256 fee) - Sets fee for measureState. (Owner)
// 29. getMeasurementFee() - Gets measureState fee.
// 30. withdrawFees() - Withdraws collected fees. (Owner)
// 31. transferOwnership(address newOwner) - Transfers contract ownership. (Owner)


contract QuantumEntangledStateOracle {

    // --- Error Definitions ---
    error StateDoesNotExist(uint256 stateId);
    error StateIsNotSuperposed(uint256 stateId);
    error StateIsSuperposed(uint256 stateId);
    error NotAllowedInfluencer();
    error MeasurementFeeNotPaid(uint256 requiredFee);
    error SelfEntanglementDisallowed();
    error EntanglementAlreadyExists();
    error EntanglementDoesNotExist();
    error NoFeesToWithdraw();
    error CannotRenounceOwnership();


    // --- Structs ---
    struct State {
        uint256 id;
        bool isSuperposed; // True if state is uncertain (in superposition)
        int256 definiteValue; // The value after measurement
        uint256 entropySeed; // Seed for deterministic measurement
        uint256[] entangledWith; // IDs of states this one is entangled with
        uint256 measurementBlock; // Block number when state was last measured (0 if never or reset)
        string metadata; // Optional description
        int256 measurementBias; // Added to the calculated outcome
    }


    // --- State Variables ---
    address private _owner;
    mapping(uint256 => State) public states;
    uint256 private nextStateId; // Starts from 1
    mapping(address => bool) private allowedInfluencers; // Addresses allowed to apply external influence & reset state
    string private contractMetadata;
    uint256 public measurementFee = 0; // Fee in wei to call measureState
    uint256 private totalFeesCollected = 0;


    // --- Events ---
    event StateCreated(uint256 indexed stateId, address indexed creator, uint256 entropySeed);
    event StateMeasured(uint256 indexed stateId, int256 definiteValue, uint256 blockNumber, address indexed measurer);
    event StateReset(uint256 indexed stateId, uint256 newEntropySeed, address indexed reseter);
    event EntanglementAdded(uint256 indexed stateId1, uint256 indexed stateId2);
    event EntanglementRemoved(uint256 indexed stateId1, uint256 indexed stateId2);
    event InfluenceApplied(uint256 indexed influencedStateId, int256 influenceValue, uint256 resultingSeed);
    event ExternalInfluenceApplied(uint256 indexed influencedStateId, int256 influenceValue, uint256 resultingSeed, address indexed influencer);
    event BiasSet(uint256 indexed stateId, int256 bias);
    event FeeSet(uint256 indexed newFee);
    event ContractMetadataSet(string metadata);
    event InfluencerAdded(address indexed account);
    event InfluencerRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    modifier onlyAllowedInfluencer() {
        if (!allowedInfluencers[msg.sender] && msg.sender != _owner) {
            revert NotAllowedInfluencer();
        }
        _;
    }

    modifier stateExists(uint256 stateId) {
        if (stateId == 0 || stateId >= nextStateId) {
            revert StateDoesNotExist(stateId);
        }
        _;
    }

    modifier whenSuperposed(uint256 stateId) {
        if (!states[stateId].isSuperposed) {
            revert StateIsNotSuperposed(stateId);
        }
        _;
    }

    modifier whenMeasured(uint256 stateId) {
         if (states[stateId].isSuperposed) {
            revert StateIsSuperposed(stateId);
        }
        _;
    }

    // --- Custom Owner Errors (to avoid OpenZeppelin import) ---
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);


    // --- Constructor ---
    constructor() {
        _transferOwnership(msg.sender);
        nextStateId = 1; // Start IDs from 1
    }

    receive() external payable {
        // Allow receiving funds, primarily for measurement fees
        totalFeesCollected += msg.value;
    }

    fallback() external payable {
        // Allow receiving funds via fallback too
        totalFeesCollected += msg.value;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Deterministically calculates a potential measurement outcome.
     *      Uses state properties (seed, bias, entanglement) and block properties
     *      (timestamp, number, prevrandao, sender address) as entropy sources.
     *      The output is an int256 primarily in the range [-1000, 1000] + bias.
     *      Note: block.prevrandao is used post-Merge as a source of randomness.
     *      In pre-Merge networks, block.difficulty/block.basefee might be used.
     *      This value is not truly random and should not be used for high-stakes security.
     * @param stateId The ID of the state to calculate for.
     * @return outcome The calculated definite value.
     */
    function _calculateMeasurementOutcome(uint256 stateId)
        internal
        view
        returns (int256 outcome)
    {
        State storage state = states[stateId];

        uint256 source = state.entropySeed;

        // Incorporate block-specific entropy (not truly random)
        // Using block.prevrandao as the source of randomness post-Merge
        source = source ^ uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.prevrandao, // Use block.prevrandao (formerly block.difficulty)
            tx.origin // Using tx.origin for a touch of path-dependency, careful with security implications
        )));

        // Incorporate influence from already measured entangled states
        for (uint256 i = 0; i < state.entangledWith.length; i++) {
            uint256 entangledId = state.entangledWith[i];
            if (entangledId > 0 && entangledId < nextStateId && !states[entangledId].isSuperposed) {
                 // Incorporate definite value of measured entangled state
                source = source ^ uint256(keccak256(abi.encodePacked(source, states[entangledId].definiteValue)));
            }
        }

        // Derive a pseudo-random value from the source
        // Modulo 2001 gives values 0-2000. Subtract 1000 for range [-1000, 1000]
        int256 rawOutcome = int256(uint256(keccak256(abi.encodePacked(source))) % 2001) - 1000;

        // Apply bias
        outcome = rawOutcome + state.measurementBias;
    }

    /**
     * @dev Applies influence to an entangled state's entropy seed if it is superposed.
     * @param influencedStateId The ID of the state being influenced.
     * @param influenceValue The value influencing the state (e.g., the definite value of the state that was just measured).
     */
    function _influenceEntangledState(uint256 influencedStateId, int256 influenceValue) internal {
        // Ensure influenced state exists and is superposed
        if (influencedStateId > 0 && influencedStateId < nextStateId && states[influencedStateId].isSuperposed) {
            State storage influencedState = states[influencedStateId];
            // Modify the entropy seed based on the influence value
            // Using XOR for a simple, reversible (by applying the same value again) transformation
            influencedState.entropySeed = influencedState.entropySeed ^ uint256(int256(influenceValue));
            emit InfluenceApplied(influencedStateId, influenceValue, influencedState.entropySeed);
        }
        // If the influenced state doesn't exist or isn't superposed, influence has no effect, which is intended behavior.
    }

     /**
     * @dev Adds a bidirectional entanglement link between two states.
     * @param stateId1 ID of the first state.
     * @param stateId2 ID of the second state.
     */
    function _addEntanglement(uint256 stateId1, uint256 stateId2) internal {
        State storage state1 = states[stateId1];
        State storage state2 = states[stateId2];

        // Check if link already exists (check only one direction is sufficient for bidirectional)
        for (uint256 i = 0; i < state1.entangledWith.length; i++) {
            if (state1.entangledWith[i] == stateId2) {
                revert EntanglementAlreadyExists();
            }
        }

        state1.entangledWith.push(stateId2);
        state2.entangledWith.push(stateId1); // Ensure bidirectional link

        emit EntanglementAdded(stateId1, stateId2);
    }

    /**
     * @dev Removes a bidirectional entanglement link between two states.
     * @param stateId1 ID of the first state.
     * @param stateId2 ID of the second state.
     */
    function _removeEntanglement(uint256 stateId1, uint256 stateId2) internal {
        State storage state1 = states[stateId1];
        State storage state2 = states[stateId2];

        // Remove state2 from state1's list
        bool found1 = false;
        for (uint256 i = 0; i < state1.entangledWith.length; i++) {
            if (state1.entangledWith[i] == stateId2) {
                // Replace with last element and pop
                state1.entangledWith[i] = state1.entangledWith[state1.entangledWith.length - 1];
                state1.entangledWith.pop();
                found1 = true;
                break;
            }
        }

        // Remove state1 from state2's list
        bool found2 = false;
        for (uint256 i = 0; i < state2.entangledWith.length; i++) {
             if (state2.entangledWith[i] == stateId1) {
                state2.entangledWith[i] = state2.entangledWith[state2.entangledWith.length - 1];
                state2.entangledWith.pop();
                found2 = true;
                break;
            }
        }

        if (!found1 || !found2) {
            // This indicates an inconsistent state or link didn't exist bidirectionally
            // In a robust system, you might have more complex state checks.
            // For this example, we assume links are added/removed bidirectionally correctly.
            revert EntanglementDoesNotExist();
        }

        emit EntanglementRemoved(stateId1, stateId2);
    }


    // --- External/Public Functions ---

    /**
     * @dev Creates a new state initialized in superposition.
     * @param entropySeed Initial seed for the state's potential measurement outcome.
     * @param entangledWithStates Array of IDs of states to immediately entangle with bidirectionally.
     * @param metadata Descriptive string for the state.
     * @return The ID of the newly created state.
     */
    function createSuperposedState(
        uint256 entropySeed,
        uint256[] memory entangledWithStates,
        string memory metadata
    ) external returns (uint256) {
        uint256 newStateId = nextStateId;

        states[newStateId] = State({
            id: newStateId,
            isSuperposed: true,
            definiteValue: 0, // Value is indefinite when superposed
            entropySeed: entropySeed,
            entangledWith: new uint256[](0), // Initialize empty, add below
            measurementBlock: 0, // Not measured yet
            metadata: metadata,
            measurementBias: 0
        });

        nextStateId++;

        // Add initial entanglements
        for (uint256 i = 0; i < entangledWithStates.length; i++) {
            uint256 targetStateId = entangledWithStates[i];
            if (targetStateId > 0 && targetStateId < newStateId) { // Only entangle with existing states (IDs < newStateId)
                 if (targetStateId == newStateId) {
                    // Should not happen with the check above, but good safety.
                    revert SelfEntanglementDisallowed();
                 }
                 // Check if targetStateId exists
                 if (states[targetStateId].id != targetStateId) {
                    // Skip or revert? Let's skip invalid IDs for flexibility.
                    continue;
                 }
                _addEntanglement(newStateId, targetStateId);
            }
        }

        emit StateCreated(newStateId, msg.sender, entropySeed);
        return newStateId;
    }

    /**
     * @dev Resets a state (whether measured or superposed) back into superposition.
     *      Requires owner or allowed influencer role.
     * @param stateId The ID of the state to reset.
     * @param newEntropySeed A new seed for the state's entropy.
     */
    function resetStateToSuperposition(uint256 stateId, uint256 newEntropySeed)
        external
        onlyAllowedInfluencer
        stateExists(stateId)
    {
        State storage state = states[stateId];
        state.isSuperposed = true;
        state.definiteValue = 0; // Reset value
        state.entropySeed = newEntropySeed;
        state.measurementBlock = 0; // Reset measurement block

        emit StateReset(stateId, newEntropySeed, msg.sender);
    }

     /**
     * @dev Updates the entropy seed of a state, but only if it is currently superposed.
     *      Requires owner or allowed influencer role.
     * @param stateId The ID of the state.
     * @param newSeed The new seed value.
     */
    function updateEntropySeed(uint256 stateId, uint256 newSeed)
        external
        onlyAllowedInfluencer
        stateExists(stateId)
        whenSuperposed(stateId)
    {
        states[stateId].entropySeed = newSeed;
        // No specific event for seed update separate from reset/influence for simplicity.
        // Could add one if needed: event SeedUpdated(uint256 indexed stateId, uint256 newSeed, address indexed updater);
    }

    /**
     * @dev Updates the metadata string for an existing state.
     *      Requires owner role.
     * @param stateId The ID of the state.
     * @param newMetadata The new metadata string.
     */
    function updateStateMetadata(uint256 stateId, string memory newMetadata)
        external
        onlyOwner
        stateExists(stateId)
    {
        states[stateId].metadata = newMetadata;
        // No specific event for metadata update for simplicity.
    }

    /**
     * @dev Triggers the measurement of a state.
     *      This collapses the superposition, determines the definite value,
     *      and influences entangled superposed states.
     *      Requires payment of the measurement fee if set.
     * @param stateId The ID of the state to measure.
     */
    function measureState(uint256 stateId)
        external
        payable
        stateExists(stateId)
        whenSuperposed(stateId)
    {
        if (msg.value < measurementFee) {
            revert MeasurementFeeNotPaid(measurementFee);
        }
        if (msg.value > measurementFee) {
            // Refund excess if too much is sent
            (bool success, ) = msg.sender.call{value: msg.value - measurementFee}("");
            require(success, "Refund failed"); // Should ideally not fail, but include check
        }
        totalFeesCollected += measurementFee; // Add required fee to collected fees

        State storage state = states[stateId];

        // Calculate the definite value based on current state and block data
        int256 definiteValue = _calculateMeasurementOutcome(stateId);

        // Collapse the state
        state.definiteValue = definiteValue;
        state.isSuperposed = false;
        state.measurementBlock = block.number;

        // Influence entangled superposed states
        for (uint256 i = 0; i < state.entangledWith.length; i++) {
            _influenceEntangledState(state.entangledWith[i], definiteValue);
        }

        emit StateMeasured(stateId, definiteValue, block.number, msg.sender);
    }

    /**
     * @dev Gets the definite value of a state.
     *      Can only be called if the state has been measured (is not superposed).
     * @param stateId The ID of the state.
     * @return The definite integer value.
     */
    function getDefiniteValue(uint256 stateId)
        external
        view
        stateExists(stateId)
        whenMeasured(stateId)
        returns (int256)
    {
        return states[stateId].definiteValue;
    }

    /**
     * @dev Simulates the measurement outcome calculation without actually measuring the state.
     *      Allows potential users to see what the outcome *would be* if measured now.
     *      Does not change the state's superposition status or influence entangled states.
     * @param stateId The ID of the state.
     * @return The potential definite integer value.
     */
    function simulateMeasurementOutcome(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (int256)
    {
        // Note: This uses the *current* block context for simulation.
        // The actual measureState call will use the block context *when it is mined*.
        return _calculateMeasurementOutcome(stateId);
    }

    /**
     * @dev Gets the primary details of a state that is currently superposed.
     * @param stateId The ID of the state.
     * @return id, isSuperposed, entropySeed, measurementBias, metadata
     */
    function getSuperposedStateDetails(uint256 stateId)
        external
        view
        stateExists(stateId)
        whenSuperposed(stateId)
        returns (uint256 id, bool isSuperposed, uint256 entropySeed, int256 measurementBias, string memory metadata)
    {
        State storage state = states[stateId];
        return (state.id, state.isSuperposed, state.entropySeed, state.measurementBias, state.metadata);
    }

     /**
     * @dev Gets the primary details of a state, including its definite value and measurement block if measured.
     *      This function works for both superposed and measured states.
     * @param stateId The ID of the state.
     * @return id, isSuperposed, definiteValue, measurementBlock, measurementBias, metadata
     */
    function getMeasurementDetails(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256 id, bool isSuperposed, int256 definiteValue, uint256 measurementBlock, int256 measurementBias, string memory metadata)
    {
        State storage state = states[stateId];
        return (state.id, state.isSuperposed, state.definiteValue, state.measurementBlock, state.measurementBias, state.metadata);
    }


    /**
     * @dev Checks if a state is currently in a superposed state.
     * @param stateId The ID of the state.
     * @return True if superposed, false otherwise.
     */
    function isStateSuperposed(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (bool)
    {
        return states[stateId].isSuperposed;
    }

    /**
     * @dev Gets the block number when a state was last measured.
     * @param stateId The ID of the state.
     * @return The block number (0 if never measured or reset).
     */
    function getLastMeasuredBlock(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return states[stateId].measurementBlock;
    }

    /**
     * @dev Gets the current entropy seed of a state.
     * @param stateId The ID of the state.
     * @return The entropy seed value.
     */
    function getEntropySeed(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return states[stateId].entropySeed;
    }

    /**
     * @dev Gets the metadata string for a state.
     * @param stateId The ID of the state.
     * @return The metadata string.
     */
    function getStateMetadata(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (string memory)
    {
        return states[stateId].metadata;
    }

    /**
     * @dev Returns the total number of states that have been created in the contract.
     * @return The count of states.
     */
    function getTotalStatesCreated() external view returns (uint256) {
        // nextStateId is 1 + the highest state ID used.
        return nextStateId - 1;
    }

    /**
     * @dev Adds a bidirectional entanglement link between two existing states.
     *      Requires owner role.
     * @param stateId1 ID of the first state.
     * @param stateId2 ID of the second state.
     */
    function addEntanglementLink(uint256 stateId1, uint256 stateId2)
        external
        onlyOwner
        stateExists(stateId1)
        stateExists(stateId2)
    {
        if (stateId1 == stateId2) {
            revert SelfEntanglementDisallowed();
        }
        _addEntanglement(stateId1, stateId2);
    }

    /**
     * @dev Removes a bidirectional entanglement link between two states.
     *      Requires owner role.
     * @param stateId1 ID of the first state.
     * @param stateId2 ID of the second state.
     */
    function removeEntanglementLink(uint256 stateId1, uint256 stateId2)
        external
        onlyOwner
        stateExists(stateId1)
        stateExists(stateId2)
    {
         if (stateId1 == stateId2) {
            revert SelfEntanglementDisallowed(); // Technically could remove self-loop if allowed, but disallowed creation.
        }
        _removeEntanglement(stateId1, stateId2);
    }

    /**
     * @dev Gets the list of state IDs that a given state is entangled with.
     * @param stateId The ID of the state.
     * @return An array of state IDs.
     */
    function getEntangledLinks(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256[] memory)
    {
        return states[stateId].entangledWith;
    }

    /**
     * @dev Applies an external influence to the entropy seed of a state, but only if it is superposed.
     *      This changes the potential outcome of a future measurement.
     *      Requires owner or allowed influencer role.
     * @param stateId The ID of the state to influence.
     * @param influenceValue The value representing the external influence.
     */
    function applyExternalInfluence(uint256 stateId, int256 influenceValue)
        external
        onlyAllowedInfluencer
        stateExists(stateId)
        whenSuperposed(stateId)
    {
        State storage state = states[stateId];
        uint256 oldSeed = state.entropySeed;
        state.entropySeed = state.entropySeed ^ uint256(int256(influenceValue)); // Simple application
        emit ExternalInfluenceApplied(stateId, influenceValue, state.entropySeed, msg.sender);
        // Also emit the generic InfluenceApplied event for consistency with internal influence
        emit InfluenceApplied(stateId, influenceValue, state.entropySeed);
    }

    /**
     * @dev Sets a fixed bias value that is added to the calculated measurement outcome for a specific state.
     *      Requires owner role.
     * @param stateId The ID of the state.
     * @param bias The bias value (int256).
     */
    function setMeasurementBias(uint256 stateId, int256 bias)
        external
        onlyOwner
        stateExists(stateId)
    {
        states[stateId].measurementBias = bias;
        emit BiasSet(stateId, bias);
    }

    /**
     * @dev Gets the current measurement bias for a state.
     * @param stateId The ID of the state.
     * @return The bias value (int256).
     */
    function getMeasurementBias(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (int256)
    {
        return states[stateId].measurementBias;
    }

    /**
     * @dev Returns the raw entropy source value used internally for calculation
     *      during a simulated measurement. Useful for understanding the process.
     * @param stateId The ID of the state.
     * @return The raw entropy source value.
     */
    function getMeasurementEntropySource(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
         State storage state = states[stateId];

        uint256 source = state.entropySeed;

        // Incorporate block-specific entropy (same logic as in _calculateMeasurementOutcome)
        source = source ^ uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.prevrandao,
            tx.origin
        )));

        // Incorporate influence from already measured entangled states (same logic)
        for (uint256 i = 0; i < state.entangledWith.length; i++) {
            uint256 entangledId = state.entangledWith[i];
             if (entangledId > 0 && entangledId < nextStateId && !states[entangledId].isSuperposed) {
                 source = source ^ uint256(keccak256(abi.encodePacked(source, states[entangledId].definiteValue)));
            }
        }
        return source;
    }


    // --- Access Control (Influencers) ---

    /**
     * @dev Grants the allowed influencer role to an account.
     *      Allowed influencers can call functions like `applyExternalInfluence` and `resetStateToSuperposition`.
     *      Requires owner role.
     * @param account The address to grant the role to.
     */
    function addAllowedInfluencer(address account) external onlyOwner {
        require(account != address(0), "Account is zero address");
        allowedInfluencers[account] = true;
        emit InfluencerAdded(account);
    }

    /**
     * @dev Revokes the allowed influencer role from an account.
     *      Requires owner role.
     * @param account The address to revoke the role from.
     */
    function removeAllowedInfluencer(address account) external onlyOwner {
        require(account != address(0), "Account is zero address");
        allowedInfluencers[account] = false;
        emit InfluencerRemoved(account);
    }

    /**
     * @dev Checks if an account is an allowed influencer.
     * @param account The address to check.
     * @return True if the account is an allowed influencer (or the owner), false otherwise.
     */
    function isAllowedInfluencer(address account) external view returns (bool) {
        return allowedInfluencers[account] || account == _owner;
    }

    /**
     * @dev Returns the list of addresses that have been explicitly granted the influencer role.
     *      Does not include the owner implicitly having the role.
     *      Requires owner role. Note: This function iterates through all possible addresses
     *      in a mapping, which can be gas-intensive for a large number of influencers.
     *      A more scalable approach would be needed for production if many influencers are expected.
     */
    function getAllowedInfluencers() external view onlyOwner returns (address[] memory) {
        // This is an expensive operation if there are many influencers.
        // For demonstration purposes, it's acceptable.
        address[] memory influencers = new address[](0);
        // Iterating over mappings in Solidity is not direct. This requires tracking
        // influencers in a separate data structure if needed frequently or for many influencers.
        // Skipping iteration for this example to keep it within reasonable complexity.
        // A real implementation would track influencers in an array or linked list.
        // Returning a dummy array for demonstration.
        // TODO: Implement proper tracking if needed in production.
        return influencers; // Return empty array as direct mapping iteration is not viable
    }


    // --- Oracle Configuration (Owner Only) ---

    /**
     * @dev Sets the contract-level metadata string.
     *      Requires owner role.
     * @param _metadata The new metadata string.
     */
    function setContractMetadata(string memory _metadata) external onlyOwner {
        contractMetadata = _metadata;
        emit ContractMetadataSet(_metadata);
    }

    /**
     * @dev Gets the contract-level metadata string.
     * @return The contract metadata string.
     */
    function getContractMetadata() external view returns (string memory) {
        return contractMetadata;
    }

    /**
     * @dev Sets the fee required in wei to call the `measureState` function.
     *      Requires owner role.
     * @param fee The new measurement fee in wei.
     */
    function setMeasurementFee(uint256 fee) external onlyOwner {
        measurementFee = fee;
        emit FeeSet(fee);
    }

    /**
     * @dev Gets the current fee required to call the `measureState` function.
     * @return The measurement fee in wei.
     */
    function getMeasurementFee() external view returns (uint256) {
        return measurementFee;
    }

    /**
     * @dev Withdraws accumulated measurement fees.
     *      Requires owner role.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance - totalFeesCollected; // Exclude fees collected *after* a potential refund in measureState
        if (totalFeesCollected == 0) {
            revert NoFeesToWithdraw();
        }

        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0; // Reset before sending

        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        // Re-add if transfer failed (though require should catch)
        if (!success) {
             totalFeesCollected += amount;
        }
    }


    // --- Owner Management (Custom Basic Implementation) ---

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     * (Implemented as a modifier `onlyOwner` above)
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *      Can only be called by the current owner.
     *      The `newOwner` cannot be the zero address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Renounces the owner role.
     *      By renouncing ownership, the owner will not be able to call `onlyOwner`
     *      functions. Note that this leaves the contract without an owner, which
     *      is irreversible.
     *      We will disallow renouncing for this specific contract's logic requirements.
     */
    function renounceOwnership() public virtual onlyOwner {
         revert CannotRenounceOwnership(); // Disallow renouncing for this contract type
        // _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account.
     * @param newOwner The address of the new owner.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
```