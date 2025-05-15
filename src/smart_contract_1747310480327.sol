Okay, let's design a smart contract that simulates a system inspired by quantum mechanics concepts: superposition, entanglement, and observation-induced state collapse. This provides a framework for interesting, non-trivial state management.

We'll call the contract `QuantumEntangledState`.

**Concept:**
The contract manages a collection of "Quanta" (analogs of quantum particles). Each Quanta can be in one of three states:
1.  **Superposition:** Represents a state where the outcome is uncertain. It holds a list of *potential* definite states, each with a "weight" (simulating probability).
2.  **Definite State (State0, State1, etc.):** Represents a collapsed state after observation. The Quanta is no longer in superposition.

Quanta can be **Entangled**. An entanglement link means that when one entangled Quanta is **Observed** and collapses into a specific Definite State, its entangled partner(s) are forced to collapse into specific corresponding Definite State(s).

**Key Advanced Concepts Used (Simulated/Analogous):**
*   **Superposition:** State represented by multiple potential outcomes with weights.
*   **Observation (Collapse):** An action that forces a Superposition state into a single Definite State based on simulated probabilities.
*   **Entanglement:** A relationship where the observation of one Quanta instantly influences the state of another.
*   **Probabilistic Simulation:** Using EVM's (limited and cautioned) sources to simulate probabilistic outcomes during observation. *Note: True randomness is not possible on-chain without VRF or oracles. This implementation uses block properties which are manipulable for high-value applications.*
*   **State History:** Tracking observation events.
*   **Delegated Permissions:** Allowing others to perform actions (like observation) on your behalf.
*   **Dynamic State:** The state of Quanta evolves significantly based on external interactions (`observeQuanta`).
*   **Batch/Global Operations:** A function (`applyGlobalNoise`) that affects the state of multiple entities simultaneously.

**Outline:**

1.  **Structs & Enums:** Define the structure of a Quanta, its potential states, observation records, and the state enum.
2.  **State Variables:** Mappings and arrays to store Quanta data, ownership, entanglement rules, observation history, etc.
3.  **Events:** Announce significant state changes.
4.  **Errors:** Custom errors for clarity.
5.  **Modifiers:** Restrict access based on ownership or permission.
6.  **Core Logic Functions:**
    *   Quanta Creation & Management (create, add potential, remove potential, set weight, remove)
    *   Entanglement Management (create, remove, set rules)
    *   Observation (the core collapse and propagation logic)
    *   State Reset (back to superposition)
    *   Simulated Global Effects (`applyGlobalNoise`)
7.  **Access Control & Permissions:** Ownership, Delegation for Observation.
8.  **View/Pure Functions:** Get state, potentials, history, counts, etc.

**Function Summary:**

1.  `constructor()`: Deploys the contract, sets owner.
2.  `createQuanta()`: Mints a new Quanta in Superposition.
3.  `addPotentialState(uint256 quantaId, QuantaState state, uint256 weight)`: Adds a possible outcome and its weight to a Quanta in Superposition.
4.  `setPotentialWeight(uint256 quantaId, QuantaState state, uint256 weight)`: Updates the weight of an existing potential state.
5.  `removePotentialState(uint256 quantaId, QuantaState state)`: Removes a potential outcome from a Quanta in Superposition.
6.  `removeQuanta(uint256 quantaId)`: Permanently removes/burns a Quanta and associated data.
7.  `createEntanglementPair(uint256 quantaId1, uint256 quantaId2, QuantaState outcomeState1, QuantaState forcedState2, QuantaState outcomeState2, QuantaState forcedState1)`: Creates a mutual entanglement link and defines the forced outcome states upon observation of either partner.
8.  `removeEntanglementPair(uint256 quantaId1, uint256 quantaId2)`: Breaks the entanglement link between two Quanta.
9.  `setEntanglementRuleOutcome(uint256 quantaId, QuantaState outcomeState, uint256 targetQuantaId, QuantaState forcedState)`: Updates the specific forced outcome for a partner when a Quanta collapses to a given state.
10. `observeQuanta(uint256 quantaId)`: Triggers the collapse of a Quanta in Superposition based on simulated probability, records the observation, and propagates collapse to entangled partners if they are in Superposition.
11. `resetQuantaToSuperposition(uint256 quantaId, SuperpositionPotential[] memory potentials)`: Resets a collapsed Quanta back to Superposition with new potential states.
12. `applyGlobalNoise()`: Applies a simulated random change to the potential weights of all Quanta currently in Superposition.
13. `delegateObservationPermission(uint256 quantaId, address delegate)`: Allows another address to call `observeQuanta` for a specific Quanta.
14. `revokeObservationPermission(uint256 quantaId, address delegate)`: Revokes observation permission.
15. `transferQuantaOwnership(uint256 quantaId, address newOwner)`: Transfers ownership of a Quanta (includes clearing delegations).
16. `getTotalQuanta()`: Returns the total number of minted Quanta. (view)
17. `getQuantaOwner(uint256 quantaId)`: Returns the owner of a Quanta. (view)
18. `getQuantaState(uint256 quantaId)`: Returns the current state (Superposition or Definite). (view)
19. `getQuantaPotentials(uint256 quantaId)`: Returns the potential states and weights if in Superposition. (view)
20. `getPotentialWeight(uint256 quantaId, QuantaState state)`: Returns the weight for a specific potential state. (view)
21. `getPotentialWeightSum(uint256 quantaId)`: Returns the sum of all potential weights. (view)
22. `quantaIsSuperposition(uint256 quantaId)`: Checks if a Quanta is in Superposition. (view)
23. `getEntangledPartners(uint256 quantaId)`: Returns a list of Quanta IDs entangled with the given one. (view)
24. `getEntanglementRuleOutcome(uint256 quantaId, QuantaState outcomeState)`: Returns the target Quanta and its forced state when the given Quanta collapses to the specified outcomeState. (view)
25. `isObserverOrDelegate(uint256 quantaId, address account)`: Checks if an account is the owner or a delegate for observing a Quanta. (view)
26. `getObservationHistory(uint256 quantaId)`: Returns the list of past observation records for a Quanta. (view)
27. `simulateObservationOutcome(uint256 quantaId)`: (Pure function simulation) Given current potentials, calculates the *possible* definite states and their percentage chance (based on weights). *Does not use randomness or change state.* (pure)
28. `quantaExists(uint256 quantaId)`: Checks if a Quanta with the given ID exists. (view)

This structure gives us 28 distinct functions implementing the described concepts.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledState
 * @dev A smart contract simulating quantum superposition, entanglement, and observation-induced collapse.
 *      It manages "Quanta" that can be in Superposition or a Definite State.
 *      Observation collapses Superposition states based on simulated probability
 *      and propagates collapse through Entanglement links.
 *      NOTE: True randomness is not possible on-chain. This contract uses block properties
 *      for simulated randomness, which is *not* suitable for high-security applications
 *      requiring unpredictable outcomes. Use a VRF or oracle for production randomness.
 */

// --- Outline ---
// 1. Structs & Enums
// 2. State Variables
// 3. Events
// 4. Errors
// 5. Modifiers
// 6. Core Logic Functions (Creation, Management, Entanglement, Observation, Global Effects, Reset)
// 7. Access Control & Permissions
// 8. View/Pure Functions

// --- Function Summary ---
// 1. constructor()
// 2. createQuanta()
// 3. addPotentialState(uint256 quantaId, QuantaState state, uint256 weight)
// 4. setPotentialWeight(uint256 quantaId, QuantaState state, uint256 weight)
// 5. removePotentialState(uint256 quantaId, QuantaState state)
// 6. removeQuanta(uint256 quantaId)
// 7. createEntanglementPair(uint256 quantaId1, uint256 quantaId2, QuantaState outcomeState1, QuantaState forcedState2, QuantaState outcomeState2, QuantaState forcedState1)
// 8. removeEntanglementPair(uint256 quantaId1, uint256 quantaId2)
// 9. setEntanglementRuleOutcome(uint256 quantaId, QuantaState outcomeState, uint256 targetQuantaId, QuantaState forcedState)
// 10. observeQuanta(uint256 quantaId)
// 11. resetQuantaToSuperposition(uint256 quantaId, SuperpositionPotential[] memory potentials)
// 12. applyGlobalNoise()
// 13. delegateObservationPermission(uint256 quantaId, address delegate)
// 14. revokeObservationPermission(uint256 quantaId, address delegate)
// 15. transferQuantaOwnership(uint256 quantaId, address newOwner)
// 16. getTotalQuanta() - view
// 17. getQuantaOwner(uint256 quantaId) - view
// 18. getQuantaState(uint256 quantaId) - view
// 19. getQuantaPotentials(uint256 quantaId) - view
// 20. getPotentialWeight(uint256 quantaId, QuantaState state) - view
// 21. getPotentialWeightSum(uint256 quantaId) - view
// 22. quantaIsSuperposition(uint256 quantaId) - view
// 23. getEntangledPartners(uint256 quantaId) - view
// 24. getEntanglementRuleOutcome(uint256 quantaId, QuantaState outcomeState) - view
// 25. isObserverOrDelegate(uint256 quantaId, address account) - view
// 26. getObservationHistory(uint256 quantaId) - view
// 27. simulateObservationOutcome(uint256 quantaId) - pure
// 28. quantaExists(uint256 quantaId) - view

contract QuantumEntangledState {

    // --- 1. Structs & Enums ---

    enum QuantaState {
        Superposition, // State before observation
        State0,        // A definite state outcome
        State1,        // Another definite state outcome
        // Add more definite states as needed
        StateReserved  // Value used internally, should not be a potential or observed state
    }

    struct SuperpositionPotential {
        QuantaState state; // The potential definite state
        uint256 weight;    // The relative weight (simulated probability)
    }

    struct Quanta {
        uint256 id;
        address owner;
        QuantaState currentState;
        SuperpositionPotential[] potentials; // Only if currentState == Superposition
    }

    struct ObservationRecord {
        uint256 timestamp;
        address observer;
        QuantaState observedState;
        uint256 blockNumber;
    }

    struct EntanglementRule {
        uint256 targetQuantaId; // The quanta forced to collapse
        QuantaState forcedState; // The state the target quanta is forced into
    }

    // --- 2. State Variables ---

    uint256 private _nextQuantaId = 1; // Start IDs from 1

    // Mapping from quanta ID to Quanta data
    mapping(uint256 => Quanta) private _quanta;
    // Keep track of all active quanta IDs for iteration (gas intensive if many)
    uint256[] private _allQuantaIds;

    // Mapping from quanta ID to owner address
    mapping(uint256 => address) private _quantaOwner;

    // Mapping from quanta ID to a list of observation records
    mapping(uint256 => ObservationRecord[]) private _observationHistory;

    // Entanglement mapping: Quanta A ID -> When A collapses to State X -> Which Quanta B ID is affected and forced into Which State Y
    // _entanglementRules[quantaId1][outcomeState1] = EntanglementRule { targetQuantaId: quantaId2, forcedState: forcedState2 }
    mapping(uint256 => mapping(QuantaState => EntanglementRule)) private _entanglementRules;

    // For easy lookup of entangled partners
    mapping(uint256 => uint256[]) private _entangledPartners;

    // Mapping for observation delegation: quantaId -> delegate address -> is permitted
    mapping(uint256 => mapping(address => bool)) private _observationDelegates;

    address private _owner; // Contract owner

    // --- 3. Events ---

    event QuantaCreated(uint256 indexed quantaId, address indexed owner);
    event StateObserved(uint256 indexed quantaId, QuantaState indexed observedState, address indexed observer);
    event PotentialStateAdded(uint256 indexed quantaId, QuantaState state, uint256 weight);
    event PotentialStateWeightUpdated(uint256 indexed quantaId, QuantaState state, uint256 newWeight);
    event PotentialStateRemoved(uint256 indexed quantaId, QuantaState state);
    event QuantaRemoved(uint256 indexed quantaId);
    event EntanglementCreated(uint256 indexed quantaId1, uint256 indexed quantaId2, QuantaState outcomeState1, QuantaState forcedState2, QuantaState outcomeState2, QuantaState forcedState1);
    event EntanglementRemoved(uint256 indexed quantaId1, uint256 indexed quantaId2);
    event StateResetToSuperposition(uint256 indexed quantaId);
    event ObservationDelegated(uint256 indexed quantaId, address indexed delegate, address indexed owner);
    event ObservationRevoked(uint256 indexed quantaId, address indexed delegate, address indexed owner);
    event QuantaOwnershipTransferred(uint256 indexed quantaId, address indexed oldOwner, address indexed newOwner);
    event GlobalNoiseApplied(address indexed caller, uint256 affectedQuantaCount);


    // --- 4. Errors ---

    error QuantaDoesNotExist(uint256 quantaId);
    error NotInSuperposition(uint256 quantaId);
    error AlreadyInSuperposition(uint256 quantaId);
    error InvalidQuantaState();
    error PotentialStateAlreadyExists(QuantaState state);
    error PotentialStateDoesNotExist(QuantaState state);
    error PotentialWeightSumZero();
    error PotentialWeightZero(QuantaState state);
    error CannotEntangleWithSelf();
    error EntanglementDoesNotExist();
    error PermissionDenied();
    error NotContractOwner();
    error ZeroAddressNotAllowed();


    // --- 5. Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotContractOwner();
        _;
    }

    modifier onlyQuantaOwner(uint256 quantaId) {
        if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        if (msg.sender != _quantaOwner[quantaId]) revert PermissionDenied();
        _;
    }

     modifier onlyObserverOrDelegate(uint256 quantaId) {
        if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        if (msg.sender != _quantaOwner[quantaId] && !_observationDelegates[quantaId][msg.sender]) revert PermissionDenied();
        _;
    }

    // --- 6. Core Logic Functions ---

    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Creates a new Quanta, initially in Superposition with an empty list of potentials.
     * @return The ID of the newly created Quanta.
     */
    function createQuanta() external returns (uint256) {
        uint256 newId = _nextQuantaId++;
        _quanta[newId].id = newId;
        _quanta[newId].owner = msg.sender;
        _quanta[newId].currentState = QuantaState.Superposition;
        // Potentials array is empty initially
        _quantaOwner[newId] = msg.sender;
        _allQuantaIds.push(newId); // Store ID for iteration

        emit QuantaCreated(newId, msg.sender);
        return newId;
    }

    /**
     * @dev Adds a potential definite state and its weight to a Quanta in Superposition.
     *      Only callable by the Quanta owner.
     * @param quantaId The ID of the Quanta.
     * @param state The potential definite state (must not be Superposition or StateReserved).
     * @param weight The weight for this potential state (must be > 0).
     */
    function addPotentialState(uint256 quantaId, QuantaState state, uint256 weight) external onlyQuantaOwner(quantaId) {
        if (_quanta[quantaId].currentState != QuantaState.Superposition) revert NotInSuperposition(quantaId);
        if (state == QuantaState.Superposition || state == QuantaState.StateReserved) revert InvalidQuantaState();
        if (weight == 0) revert PotentialWeightZero(state);

        // Check if state already exists
        for (uint i = 0; i < _quanta[quantaId].potentials.length; i++) {
            if (_quanta[quantaId].potentials[i].state == state) {
                revert PotentialStateAlreadyExists(state);
            }
        }

        _quanta[quantaId].potentials.push(SuperpositionPotential({state: state, weight: weight}));
        emit PotentialStateAdded(quantaId, state, weight);
    }

    /**
     * @dev Updates the weight of an existing potential definite state for a Quanta in Superposition.
     *      Only callable by the Quanta owner.
     * @param quantaId The ID of the Quanta.
     * @param state The potential definite state whose weight to update.
     * @param weight The new weight (must be > 0).
     */
    function setPotentialWeight(uint256 quantaId, QuantaState state, uint256 weight) external onlyQuantaOwner(quantaId) {
         if (_quanta[quantaId].currentState != QuantaState.Superposition) revert NotInSuperposition(quantaId);
         if (state == QuantaState.Superposition || state == QuantaState.StateReserved) revert InvalidQuantaState();
         if (weight == 0) revert PotentialWeightZero(state);

        bool found = false;
        for (uint i = 0; i < _quanta[quantaId].potentials.length; i++) {
            if (_quanta[quantaId].potentials[i].state == state) {
                _quanta[quantaId].potentials[i].weight = weight;
                found = true;
                emit PotentialStateWeightUpdated(quantaId, state, weight);
                break;
            }
        }
        if (!found) revert PotentialStateDoesNotExist(state);
    }

    /**
     * @dev Removes a potential definite state from a Quanta in Superposition.
     *      Only callable by the Quanta owner.
     * @param quantaId The ID of the Quanta.
     * @param state The potential definite state to remove.
     */
    function removePotentialState(uint256 quantaId, QuantaState state) external onlyQuantaOwner(quantaId) {
        if (_quanta[quantaId].currentState != QuantaState.Superposition) revert NotInSuperposition(quantaId);
        if (state == QuantaState.Superposition || state == QuantaState.StateReserved) revert InvalidQuantaState();

        uint index = type(uint).max;
        for (uint i = 0; i < _quanta[quantaId].potentials.length; i++) {
            if (_quanta[quantaId].potentials[i].state == state) {
                index = i;
                break;
            }
        }

        if (index == type(uint).max) revert PotentialStateDoesNotExist(state);

        // Efficient removal from array by swapping with last element
        uint lastIndex = _quanta[quantaId].potentials.length - 1;
        _quanta[quantaId].potentials[index] = _quanta[quantaId].potentials[lastIndex];
        _quanta[quantaId].potentials.pop();

        emit PotentialStateRemoved(quantaId, state);
    }

    /**
     * @dev Removes a Quanta and all its associated data (ownership, history, delegations, entanglement).
     *      Only callable by the Quanta owner.
     * @param quantaId The ID of the Quanta to remove.
     */
    function removeQuanta(uint256 quantaId) external onlyQuantaOwner(quantaId) {
        if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);

        // Clean up entanglement links involving this quanta
        uint256[] memory partners = _entangledPartners[quantaId];
        for (uint i = 0; i < partners.length; i++) {
             // Note: This might call removeEntanglementPair multiple times for the same link
             // if partners list contains duplicates or both ends are listed.
             // A more robust cleanup would track links differently. For this example,
             // calling removeEntanglementPair handles null checks internally.
            removeEntanglementPair(quantaId, partners[i]);
        }
         delete _entangledPartners[quantaId]; // Ensure the list itself is cleared

        // Clean up this quanta's entanglement rules (rules where *it* collapsing affects others)
        // We cannot iterate through a mapping's keys (QuantaState), so we'd need to know
        // which states were used in rules. For simplicity in this example, we delete the whole entry.
        delete _entanglementRules[quantaId];


        // Clean up observation history and delegates
        delete _observationHistory[quantaId];
        // Cannot delete specific nested map entries without knowing keys.
        // A full cleanup would require iterating over delegates.
        // For simplicity, we just delete the top-level entry.
         delete _observationDelegates[quantaId];


        // Remove from the _allQuantaIds list (gas intensive for large arrays)
         uint index = type(uint).max;
         for(uint i = 0; i < _allQuantaIds.length; i++) {
             if (_allQuantaIds[i] == quantaId) {
                 index = i;
                 break;
             }
         }
         if (index != type(uint).max) {
              uint lastIndex = _allQuantaIds.length - 1;
             _allQuantaIds[index] = _allQuantaIds[lastIndex];
             _allQuantaIds.pop();
         }


        // Delete the Quanta struct and owner mapping
        delete _quanta[quantaId];
        delete _quantaOwner[quantaId];

        emit QuantaRemoved(quantaId);
    }


    /**
     * @dev Creates a mutual entanglement link between two Quanta.
     *      Defines the forced outcome states when either Quanta collapses to a specific state.
     *      Only callable by the contract owner.
     * @param quantaId1 The ID of the first Quanta.
     * @param quantaId2 The ID of the second Quanta.
     * @param outcomeState1 The specific definite state of quantaId1 that triggers entanglement.
     * @param forcedState2 The state quantaId2 is forced into when quantaId1 collapses to outcomeState1.
     * @param outcomeState2 The specific definite state of quantaId2 that triggers entanglement.
     * @param forcedState1 The state quantaId1 is forced into when quantaId2 collapses to outcomeState2.
     */
    function createEntanglementPair(
        uint256 quantaId1,
        uint256 quantaId2,
        QuantaState outcomeState1,
        QuantaState forcedState2,
        QuantaState outcomeState2,
        QuantaState forcedState1
    ) external onlyOwner {
        if (quantaId1 == quantaId2) revert CannotEntangleWithSelf();
        if (_quantaOwner[quantaId1] == address(0)) revert QuantaDoesNotExist(quantaId1);
        if (_quantaOwner[quantaId2] == address(0)) revert QuantaDoesNotExist(quantaId2);
        if (outcomeState1 == QuantaState.Superposition || outcomeState1 == QuantaState.StateReserved ||
            outcomeState2 == QuantaState.Superposition || outcomeState2 == QuantaState.StateReserved ||
            forcedState1 == QuantaState.Superposition || forcedState1 == QuantaState.StateReserved ||
            forcedState2 == QuantaState.Superposition || forcedState2 == QuantaState.StateReserved) revert InvalidQuantaState();


        // Set the rule for quantaId1 affecting quantaId2
        _entanglementRules[quantaId1][outcomeState1] = EntanglementRule({
            targetQuantaId: quantaId2,
            forcedState: forcedState2
        });

        // Set the rule for quantaId2 affecting quantaId1
        _entanglementRules[quantaId2][outcomeState2] = EntanglementRule({
            targetQuantaId: quantaId1,
            forcedState: forcedState1
        });

        // Add to entangled partners list (simple adjacency list, might have duplicates if multiple rules)
        _entangledPartners[quantaId1].push(quantaId2);
        _entangledPartners[quantaId2].push(quantaId1);

        emit EntanglementCreated(quantaId1, quantaId2, outcomeState1, forcedState2, outcomeState2, forcedState1);
    }

    /**
     * @dev Removes the mutual entanglement link between two Quanta.
     *      Only callable by the contract owner.
     * @param quantaId1 The ID of the first Quanta.
     * @param quantaId2 The ID of the second Quanta.
     */
    function removeEntanglementPair(uint256 quantaId1, uint256 quantaId2) public onlyOwner {
         if (_quantaOwner[quantaId1] == address(0) && _quantaOwner[quantaId2] == address(0)) revert QuantaDoesNotExist(quantaId1); // Check at least one exists, or maybe check both? Let's check both as a pair.
         if (_quantaOwner[quantaId1] == address(0) || _quantaOwner[quantaId2] == address(0)) {
             // One or both quanta might be removed already. Clean up any remaining links.
             // We need to iterate through all possible outcome states to find and delete rules.
             // This is inefficient. A better design would track active rules.
             // For this example, we'll attempt deletion for common states.
             // A real system might require knowing the specific outcomeStates used in the pair creation.
             // Or, have a separate mapping for active entanglement pairs.
             // For simplicity, let's just delete the top-level entries which is often done, losing specific rule info on removal.
             // This assumes only one rule per pair per outcome state exists.
             delete _entanglementRules[quantaId1];
             delete _entanglementRules[quantaId2];

         } else {
             // To properly remove a *specific* pair rule, we'd need the specific outcomeStates used.
             // Assuming for this example that removing a pair removes *all* rules defined between them.
             // This requires finding all rules where target is the other quanta.
             // Again, iterating map is hard. A different state structure is needed for robust removal.
             // Let's just remove common rules defined in createEntanglementPair for demo purposes.
             // This is not a perfect cleanup if arbitrary rules were set with setEntanglementRuleOutcome.

             // Example cleanup for rules created by createEntanglementPair, assuming State0/State1 outcomes.
             // This needs to match how rules were *actually* set.
             delete _entanglementRules[quantaId1][QuantaState.State0];
             delete _entanglementRules[quantaId1][QuantaState.State1];
             delete _entanglementRules[quantaId2][QuantaState.State0];
             delete _entanglementRules[quantaId2][QuantaState.State1];

         }

        // Remove from entangled partners list (needs array manipulation)
         _removeEntangledPartnerFromList(quantaId1, quantaId2);
         _removeEntangledPartnerFromList(quantaId2, quantaId1);


        emit EntanglementRemoved(quantaId1, quantaId2);
    }

     // Helper function for removing from the _entangledPartners array
    function _removeEntangledPartnerFromList(uint256 quantaId, uint256 partnerId) internal {
        uint[] storage partners = _entangledPartners[quantaId];
        uint index = type(uint).max;
        for (uint i = 0; i < partners.length; i++) {
            if (partners[i] == partnerId) {
                index = i;
                break;
            }
        }
        if (index != type(uint).max) {
            uint lastIndex = partners.length - 1;
            partners[index] = partners[lastIndex];
            partners.pop();
        }
    }


    /**
     * @dev Updates the specific forced outcome for a target Quanta when the primary Quanta
     *      collapses to a given state. Can be used to set or change rules after pair creation.
     *      Only callable by the contract owner.
     * @param quantaId The ID of the Quanta whose collapse triggers the rule.
     * @param outcomeState The specific definite state of quantaId that triggers the rule.
     * @param targetQuantaId The ID of the Quanta that is forced to collapse.
     * @param forcedState The state the targetQuantaId is forced into.
     */
    function setEntanglementRuleOutcome(
        uint256 quantaId,
        QuantaState outcomeState,
        uint256 targetQuantaId,
        QuantaState forcedState
    ) external onlyOwner {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
         if (_quantaOwner[targetQuantaId] == address(0)) revert QuantaDoesNotExist(targetQuantaId);
          if (quantaId == targetQuantaId) revert CannotEntangleWithSelf();
         if (outcomeState == QuantaState.Superposition || outcomeState == QuantaState.StateReserved ||
            forcedState == QuantaState.Superposition || forcedState == QuantaState.StateReserved) revert InvalidQuantaState();

        _entanglementRules[quantaId][outcomeState] = EntanglementRule({
            targetQuantaId: targetQuantaId,
            forcedState: forcedState
        });

        // Add to entangled partners list if not already there (basic check, inefficient for large lists)
        bool found = false;
        uint[] storage partners = _entangledPartners[quantaId];
        for(uint i=0; i < partners.length; i++) {
            if(partners[i] == targetQuantaId) {
                found = true;
                break;
            }
        }
        if(!found) {
            partners.push(targetQuantaId);
        }

         // Also add the reciprocal link for lookup (even if there's no specific rule the other way)
        found = false;
        partners = _entangledPartners[targetQuantaId];
         for(uint i=0; i < partners.length; i++) {
            if(partners[i] == quantaId) {
                found = true;
                break;
            }
        }
        if(!found) {
            partners.push(quantaId);
        }

        // No specific event for rule *update*, uses EntanglementCreated event analogy
         emit EntanglementCreated(quantaId, targetQuantaId, outcomeState, forcedState, QuantaState.StateReserved, QuantaState.StateReserved); // Use reserved states for the other direction to signify unilateral rule set
    }


    /**
     * @dev Observes a Quanta in Superposition, causing it to collapse into a definite state
     *      based on simulated probability weights. Propagates collapse to entangled partners.
     *      Callable by the Quanta owner or a delegated observer.
     *      WARNING: Uses block properties for simulated randomness. Do not use for critical
     *      applications requiring strong, unpredictable randomness.
     * @param quantaId The ID of the Quanta to observe.
     */
    function observeQuanta(uint256 quantaId) external onlyObserverOrDelegate(quantaId) {
        Quanta storage quanta = _quanta[quantaId];
        if (quanta.currentState != QuantaState.Superposition) revert NotInSuperposition(quantaId);
        if (quanta.potentials.length == 0) revert PotentialWeightSumZero(); // Cannot observe if no potentials

        uint256 totalWeight = getPotentialWeightSum(quantaId);
        if (totalWeight == 0) revert PotentialWeightSumZero(); // Double check

        // --- Simulate Randomness (CAUTION!) ---
        // Using block.timestamp, block.difficulty, msg.sender, and quantaId for entropy.
        // This is predictable by miners.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, quantaId, block.number)));
        uint256 randomWeight = randomNumber % totalWeight;

        // --- Determine Outcome ---
        QuantaState observedState = QuantaState.StateReserved;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < quanta.potentials.length; i++) {
            cumulativeWeight += quanta.potentials[i].weight;
            if (randomWeight < cumulativeWeight) {
                observedState = quanta.potentials[i].state;
                break;
            }
        }

        // Should always find a state if totalWeight > 0, but safety check
        if (observedState == QuantaState.StateReserved) {
             // Fallback to the last state if floating point rounding issues occurred (highly unlikely with integer math) or if logic is flawed.
             // A better approach is to ensure randomWeight is always less than totalWeight.
             // Given randomWeight = randomNumber % totalWeight, this condition should ideally not be met
             // unless totalWeight was somehow computed incorrectly or potentials were empty.
             // Reverting might be safer than guessing an outcome.
             revert("Observation outcome determination failed");
        }


        // --- Collapse State ---
        quanta.currentState = observedState;
        delete quanta.potentials; // Clear potentials array

        // --- Record Observation ---
        _observationHistory[quantaId].push(ObservationRecord({
            timestamp: block.timestamp,
            observer: msg.sender,
            observedState: observedState,
            blockNumber: block.number
        }));

        emit StateObserved(quantaId, observedState, msg.sender);

        // --- Propagate Entanglement ---
        EntanglementRule memory rule = _entanglementRules[quantaId][observedState];
        if (rule.targetQuantaId != 0) { // Check if a rule exists for this outcome
            uint256 targetId = rule.targetQuantaId;
            QuantaState forcedState = rule.forcedState;

            Quanta storage targetQuanta = _quanta[targetId];

            // Only propagate if the target exists and is currently in Superposition
            // This is a design choice. Could allow forcing a collapsed state to change,
            // but collapsing superposition based on entanglement is more aligned with the concept.
            if (_quantaOwner[targetId] != address(0) && targetQuanta.currentState == QuantaState.Superposition) {
                targetQuanta.currentState = forcedState;
                delete targetQuanta.potentials; // Target also collapses

                 // Record observation for the *target* Quanta due to entanglement
                 _observationHistory[targetId].push(ObservationRecord({
                    timestamp: block.timestamp,
                    observer: msg.sender, // The original observer
                    observedState: forcedState, // The state it was forced into
                    blockNumber: block.number
                }));

                emit StateObserved(targetId, forcedState, address(this)); // Emit event indicating contract-forced collapse
            }
             // Note: Entanglement could trigger cascading observations if the forced state
             // in the target Quanta itself triggers an entanglement rule. This requires
             // recursive calls or a queue system, which adds complexity and potential
             // gas issues (infinite loops). We won't implement cascading for this example.
        }
    }

     /**
      * @dev Resets a Quanta from a Definite State back to Superposition.
      *      Requires providing the new list of potentials.
      *      Only callable by the Quanta owner.
      * @param quantaId The ID of the Quanta to reset.
      * @param potentials An array of new potential states and weights for the reset Quanta.
      */
    function resetQuantaToSuperposition(uint256 quantaId, SuperpositionPotential[] memory potentials) external onlyQuantaOwner(quantaId) {
        Quanta storage quanta = _quanta[quantaId];
        if (quanta.currentState == QuantaState.Superposition) revert AlreadyInSuperposition(quantaId);
        if (potentials.length == 0) revert PotentialWeightSumZero(); // Must provide potentials to enter superposition

        // Validate provided potentials
        uint256 totalWeight = 0;
        for(uint i=0; i < potentials.length; i++) {
            if (potentials[i].state == QuantaState.Superposition || potentials[i].state == QuantaState.StateReserved) revert InvalidQuantaState();
             if (potentials[i].weight == 0) revert PotentialWeightZero(potentials[i].state);
             totalWeight += potentials[i].weight;
        }
         if (totalWeight == 0) revert PotentialWeightSumZero(); // Safety check


        quanta.currentState = QuantaState.Superposition;
        quanta.potentials = potentials; // Assign the new potentials

        emit StateResetToSuperposition(quantaId);
    }

     /**
      * @dev Applies a simulated global noise effect by slightly adjusting
      *      potential weights of all Quanta currently in Superposition.
      *      Only callable by the contract owner.
      *      WARNING: Uses block properties for simulated randomness. Gas intensive
      *      for a large number of Quanta.
      */
     function applyGlobalNoise() external onlyOwner {
         uint256 affectedCount = 0;
         // Use block properties for randomness, apply sparingly due to gas costs
         uint256 baseRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number)));

         // Iterate through all quanta IDs. This is gas-expensive for many NFTs.
         // In a real system, you'd need a more efficient way to track superposition quanta
         // or process in batches.
         for (uint i = 0; i < _allQuantaIds.length; i++) {
             uint256 quantaId = _allQuantaIds[i];
             // Check if the quanta exists and is in superposition
             if (_quantaOwner[quantaId] != address(0) && _quanta[quantaId].currentState == QuantaState.Superposition) {
                  Quanta storage quanta = _quanta[quantaId];
                  if (quanta.potentials.length > 0) {
                      affectedCount++;
                       uint256 localRandom = uint256(keccak256(abi.encodePacked(baseRandom, quantaId, i)));

                       for (uint j = 0; j < quanta.potentials.length; j++) {
                           uint256 noiseAmount = (localRandom >> (j * 8)) % 10 + 1; // Small random amount 1-10
                           bool addNoise = ((localRandom >> (j * 4)) % 2) == 0; // Randomly add or subtract

                           if (addNoise) {
                               quanta.potentials[j].weight += noiseAmount;
                           } else {
                                if (quanta.potentials[j].weight > noiseAmount) {
                                   quanta.potentials[j].weight -= noiseAmount;
                               } else {
                                   quanta.potentials[j].weight = 1; // Don't let weight drop to 0
                               }
                           }
                           // Could emit event for each affected potential, but too gas intensive
                           // emit PotentialStateWeightUpdated(quantaId, quanta.potentials[j].state, quanta.potentials[j].weight);
                       }
                  }
             }
         }
         emit GlobalNoiseApplied(msg.sender, affectedCount);
     }


    // --- 7. Access Control & Permissions ---

    /**
     * @dev Delegates permission to observe a specific Quanta to another address.
     *      Only callable by the Quanta owner.
     * @param quantaId The ID of the Quanta.
     * @param delegate The address to grant observation permission to.
     */
    function delegateObservationPermission(uint256 quantaId, address delegate) external onlyQuantaOwner(quantaId) {
        if (delegate == address(0)) revert ZeroAddressNotAllowed();
        _observationDelegates[quantaId][delegate] = true;
        emit ObservationDelegated(quantaId, delegate, msg.sender);
    }

    /**
     * @dev Revokes observation permission for a specific Quanta from a delegate address.
     *      Only callable by the Quanta owner.
     * @param quantaId The ID of the Quanta.
     * @param delegate The address to revoke permission from.
     */
    function revokeObservationPermission(uint256 quantaId, address delegate) external onlyQuantaOwner(quantaId) {
         if (delegate == address(0)) revert ZeroAddressNotAllowed();
        _observationDelegates[quantaId][delegate] = false;
        emit ObservationRevoked(quantaId, delegate, msg.sender);
    }

     /**
      * @dev Transfers ownership of a Quanta. Clears any existing observation delegations.
      *      Only callable by the current Quanta owner.
      * @param quantaId The ID of the Quanta.
      * @param newOwner The address to transfer ownership to.
      */
     function transferQuantaOwnership(uint256 quantaId, address newOwner) external onlyQuantaOwner(quantaId) {
         if (newOwner == address(0)) revert ZeroAddressNotAllowed();
         address oldOwner = _quantaOwner[quantaId];

         // Clear all delegations for this quanta upon ownership transfer
         // This is simplified; a full implementation might track delegates in a list to clear them efficiently.
         // With current mapping, cannot iterate delegates easily. User would need to revoke manually or accept this limitation.
         // For demo, we note the limitation. A better way would be to delete the entire delegate mapping for this quanta ID.
          delete _observationDelegates[quantaId]; // This deletes the inner mapping for this quantaId

         _quanta[quantaId].owner = newOwner;
         _quantaOwner[quantaId] = newOwner;

         emit QuantaOwnershipTransferred(quantaId, oldOwner, newOwner);
     }

    // Note: Standard ERC721 approve/getApproved pattern for the *Quanta itself* is not implemented here
    // as observation delegation serves a similar purpose specific to the core logic.
    // If needed, mappings like `_quantaApprovals` could be added following ERC721.


    // --- 8. View/Pure Functions ---

    /**
     * @dev Returns the total number of Quanta that have been created (and not removed).
     */
    function getTotalQuanta() external view returns (uint256) {
        return _allQuantaIds.length; // More accurate count using the list
    }

     /**
      * @dev Returns the owner of a specific Quanta.
      * @param quantaId The ID of the Quanta.
      * @return The owner address.
      */
     function getQuantaOwner(uint256 quantaId) external view returns (address) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
         return _quantaOwner[quantaId];
     }

    /**
     * @dev Returns the current state of a Quanta (Superposition or a Definite State).
     * @param quantaId The ID of the Quanta.
     * @return The current QuantaState.
     */
    function getQuantaState(uint256 quantaId) external view returns (QuantaState) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        return _quanta[quantaId].currentState;
    }

    /**
     * @dev Returns the list of potential states and their weights for a Quanta in Superposition.
     *      Returns an empty array if the Quanta is not in Superposition.
     * @param quantaId The ID of the Quanta.
     * @return An array of SuperpositionPotential structs.
     */
    function getQuantaPotentials(uint256 quantaId) external view returns (SuperpositionPotential[] memory) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        if (_quanta[quantaId].currentState != QuantaState.Superposition) {
            return new SuperpositionPotential[](0); // Return empty array if not in superposition
        }
        return _quanta[quantaId].potentials;
    }

     /**
      * @dev Returns the weight for a specific potential state of a Quanta in Superposition.
      *      Returns 0 if the state is not a potential or the Quanta is not in Superposition.
      * @param quantaId The ID of the Quanta.
      * @param state The potential definite state to query.
      * @return The weight of the potential state.
      */
     function getPotentialWeight(uint256 quantaId, QuantaState state) external view returns (uint256) {
          if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
         if (_quanta[quantaId].currentState != QuantaState.Superposition) return 0;
         if (state == QuantaState.Superposition || state == QuantaState.StateReserved) return 0;

         for (uint i = 0; i < _quanta[quantaId].potentials.length; i++) {
             if (_quanta[quantaId].potentials[i].state == state) {
                 return _quanta[quantaId].potentials[i].weight;
             }
         }
         return 0; // State not found in potentials
     }


    /**
     * @dev Calculates the sum of weights of all potential states for a Quanta in Superposition.
     *      Returns 0 if the Quanta is not in Superposition or has no potentials.
     * @param quantaId The ID of the Quanta.
     * @return The total weight.
     */
    function getPotentialWeightSum(uint256 quantaId) public view returns (uint256) {
        if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        if (_quanta[quantaId].currentState != QuantaState.Superposition) return 0;

        uint256 totalWeight = 0;
        for (uint i = 0; i < _quanta[quantaId].potentials.length; i++) {
            totalWeight += _quanta[quantaId].potentials[i].weight;
        }
        return totalWeight;
    }

    /**
     * @dev Checks if a Quanta is currently in Superposition.
     * @param quantaId The ID of the Quanta.
     * @return True if in Superposition, false otherwise.
     */
    function quantaIsSuperposition(uint256 quantaId) external view returns (bool) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        return _quanta[quantaId].currentState == QuantaState.Superposition;
    }

    /**
     * @dev Returns a list of Quanta IDs that are entangled with the given Quanta.
     *      Note: This list represents potential entanglement partners, not necessarily
     *      that a specific rule is active for every outcome state with that partner.
     * @param quantaId The ID of the Quanta.
     * @return An array of entangled Quanta IDs.
     */
    function getEntangledPartners(uint256 quantaId) external view returns (uint256[] memory) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
         return _entangledPartners[quantaId];
    }

    /**
     * @dev Returns the entanglement rule consequence when a Quanta collapses to a specific outcome state.
     * @param quantaId The ID of the Quanta whose collapse triggers the rule.
     * @param outcomeState The definite state the quanta collapses into.
     * @return targetQuantaId The ID of the Quanta that will be forced to collapse. Returns 0 if no rule exists for this outcome.
     * @return forcedState The state the targetQuantaId is forced into. Returns StateReserved if no rule exists.
     */
    function getEntanglementRuleOutcome(uint256 quantaId, QuantaState outcomeState) external view returns (uint256 targetQuantaId, QuantaState forcedState) {
        if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
         if (outcomeState == QuantaState.Superposition || outcomeState == QuantaState.StateReserved) revert InvalidQuantaState();

        EntanglementRule memory rule = _entanglementRules[quantaId][outcomeState];
        return (rule.targetQuantaId, rule.forcedState);
    }

     /**
      * @dev Checks if an address is the owner of a Quanta or has observation permission delegated.
      * @param quantaId The ID of the Quanta.
      * @param account The address to check.
      * @return True if the account can observe, false otherwise.
      */
     function isObserverOrDelegate(uint256 quantaId, address account) public view returns (bool) {
          if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
         return account == _quantaOwner[quantaId] || _observationDelegates[quantaId][account];
     }

    /**
     * @dev Returns the history of observation events for a specific Quanta.
     * @param quantaId The ID of the Quanta.
     * @return An array of ObservationRecord structs.
     */
    function getObservationHistory(uint256 quantaId) external view returns (ObservationRecord[] memory) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
        return _observationHistory[quantaId];
    }

     /**
      * @dev Pure function to simulate potential observation outcomes and their chances based on current weights.
      *      Does not use randomness or access state. Provides a view of the *possibility space*.
      * @param quantaId The ID of the Quanta.
      * @return An array of potential definite states and their simulated percentage chance (weight / totalWeight * 100).
      */
     function simulateObservationOutcome(uint256 quantaId) external view returns (SuperpositionPotential[] memory) {
         if (_quantaOwner[quantaId] == address(0)) revert QuantaDoesNotExist(quantaId);
          Quanta storage quanta = _quanta[quantaId];
         if (quanta.currentState != QuantaState.Superposition) {
             // If not in superposition, the only outcome is its current state with 100% chance
             SuperpositionPotential[] memory result = new SuperpositionPotential[](1);
             result[0] = SuperpositionPotential({state: quanta.currentState, weight: 100}); // Use weight field for percentage
             return result;
         }

         uint256 totalWeight = getPotentialWeightSum(quantaId);
         if (totalWeight == 0) {
             return new SuperpositionPotential[](0); // No potentials, no outcome
         }

         SuperpositionPotential[] memory potentialResults = new SuperpositionPotential[](quanta.potentials.length);
         for (uint i = 0; i < quanta.potentials.length; i++) {
             potentialResults[i].state = quanta.potentials[i].state;
             // Calculate percentage: weight * 100 / totalWeight
             potentialResults[i].weight = (quanta.potentials[i].weight * 10000) / totalWeight; // Use 10000 for better precision (0.01%)
         }
         return potentialResults; // Weight field now represents percentage * 100
     }

     /**
      * @dev Checks if a Quanta with the given ID exists in the contract.
      * @param quantaId The ID of the Quanta.
      * @return True if the Quanta exists, false otherwise.
      */
     function quantaExists(uint256 quantaId) external view returns (bool) {
         return _quantaOwner[quantaId] != address(0);
     }

     // Example: Add a function to get all Quanta IDs (could be gas intensive)
     /**
      * @dev Returns a list of all active Quanta IDs.
      *      WARNING: Can be gas intensive if there are many Quanta.
      */
     function getAllQuantaIds() external view returns (uint256[] memory) {
         return _allQuantaIds;
     }
}
```