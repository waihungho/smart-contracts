Okay, let's create a smart contract that explores concepts like state superposition, observation-triggered collapse, entanglement simulation, and historical record-keeping within the context of unique digital "Chronicle Fragments." This isn't a standard token or DeFi pattern.

**Concept:** The `QuantumChronicle` contract manages unique digital artifacts called "Chronicle Fragments." Each fragment can exist in a state of "superposition," meaning it has multiple potential outcomes or characteristics encoded within it. An "observation" action, potentially triggered by an owner or specific conditions, forces the fragment to collapse into a single, definite state based on weighted probabilities. Fragments can also be "entangled," such that observing one can affect the state or observation of its entangled partners, potentially requiring compatibility between collapsed states. The contract maintains a history log for each fragment.

**Advanced Concepts Used:**

1.  **Simulated Superposition & Collapse:** Representing multiple potential states and using a probabilistic mechanism (simulated randomness) to select one upon an "observation" event.
2.  **Simulated Entanglement:** Linking fragments such that an action on one (observation) can trigger related actions or state constraints on others.
3.  **State Compatibility Logic:** Introducing rules (like matching compatibility hashes) that entangled fragments' collapsed states must satisfy.
4.  **Dynamic State:** Fragment properties (the current state) change immutably after an event (observation). Metadata could also be dynamic within limits.
5.  **On-Chain History/Provenance:** Maintaining a detailed, immutable log of significant events for each fragment.
6.  **Weighted Probabilistic Outcomes:** Using weights to influence the likelihood of different states being selected during collapse.
7.  **Structured Data (Structs & Mappings):** Using complex data structures to represent fragments, states, and history entries.
8.  **Controlled Mutability:** Certain data points (like current state) become immutable after a specific event, while others (like metadata before collapse) might be mutable.
9.  **Fee Mechanism:** Implementing a simple fee for a specific action (observation).
10. **Pausability & Ownership:** Standard but necessary access control patterns.
11. **Event Sourcing (Implicit):** Events record all key state transitions, allowing reconstruction of history off-chain.
12. **Simulated Randomness:** Using block data (with caveats) to introduce non-determinism for state collapse. (Requires a proper VRF for production).
13. **Interface Introspection (ERC-165):** While not fully ERC-721, includes `supportsInterface` for potential integration or signaling capabilities.

---

**Outline and Function Summary**

**Contract Name:** `QuantumChronicle`

**Description:** A contract for managing unique digital artifacts ("Chronicle Fragments") that can exist in a state of superposition with multiple potential outcomes. Fragments collapse into a single state upon "observation" based on weighted probabilities and simulated randomness. Fragments can be entangled, where observation of one can influence or require compatibility with entangled partners. A history log tracks all significant events for each fragment.

**Core Components:**

1.  **State Management:** Structs and mappings to store fragment data, potential states, current state, and history.
2.  **Fragment Lifecycle:** Functions for creation, managing superposition, observation (collapse), and state interaction.
3.  **Entanglement:** Functions to create, link, break links, and handle observation effects on entangled fragments.
4.  **History Logging:** Internal mechanism to record events.
5.  **Ownership & Access Control:** Standard owner pattern and pausability.
6.  **Fee Mechanism:** Collects fees for the observation action.

**Function Summary:**

*   **Creation & Minting:**
    *   `createFragment`: Mints a new fragment in superposition with initial potential states.
    *   `createEntangledFragments`: Mints two fragments and immediately entangles them.
*   **Superposition Management (Before Observation):**
    *   `addPotentialState`: Adds a new potential state to a fragment in superposition.
    *   `removePotentialState`: Removes a potential state from a fragment in superposition.
    *   `modifyStateWeight`: Adjusts the weight (probability) of a potential state.
    *   `updatePotentialStateMetadata`: Updates metadata for a potential state.
*   **Observation & Collapse:**
    *   `observeFragment`: Triggers the collapse of a single fragment from superposition into a definite state.
    *   `observeEntangledPair`: Triggers observation on a fragment and attempts to observe its entangled partners, enforcing state compatibility.
*   **Entanglement Management:**
    *   `entangleFragments`: Links two existing fragments.
    *   `disentangleFragments`: Breaks the link between two entangled fragments.
*   **Fragment & State Interaction (After Observation):**
    *   `updateCurrentStateMetadata`: Updates metadata for the *collapsed* state (if allowed by the state).
*   **Information & View Functions:**
    *   `getFragmentDetails`: Retrieves comprehensive details of a fragment.
    *   `getOwner`: Gets the owner of a fragment.
    *   `getPotentialStates`: Gets the list of potential states for a fragment.
    *   `getCurrentState`: Gets the ID and metadata of the collapsed state (or indicates superposition).
    *   `isSuperposition`: Checks if a fragment is still in superposition.
    *   `getEntangledFragments`: Gets the list of fragments entangled with a given fragment.
    *   `getHistoryLog`: Retrieves the history of events for a fragment.
    *   `getStateMetadata`: Gets metadata for a specific potential or current state ID.
    *   `getTotalFragments`: Gets the total number of fragments minted.
    *   `getObservationFee`: Gets the current fee for observation.
    *   `isPaused`: Checks if the contract is paused.
*   **Ownership & Administration:**
    *   `transferFragment`: Transfers ownership of a fragment (basic, non-ERC721).
    *   `setObservationFee`: Sets the fee required to observe a fragment.
    *   `withdrawFunds`: Allows the owner to withdraw collected fees.
    *   `pauseContract`: Pauses core interactions (observation, entanglement).
    *   `unpauseContract`: Unpauses the contract.
*   **Interface Support:**
    *   `supportsInterface`: Standard ERC-165 function for introspection.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath adds clarity or can be used for specific operations if needed.

// Outline and Function Summary on Top

/**
 * @title QuantumChronicle
 * @dev A smart contract managing unique digital artifacts called "Chronicle Fragments".
 * Each fragment can exist in a state of superposition with multiple potential outcomes.
 * Observation triggers collapse into a single state based on weighted probabilities.
 * Fragments can be entangled, where observation of one influences entangled partners.
 * A history log is maintained for each fragment.
 */

/**
 * @dev Function Summary:
 *
 * Creation & Minting:
 * - createFragment(bytes32 baseData, StateInfo[] initialStates): Mints a new fragment in superposition.
 * - createEntangledFragments(bytes32 baseDataA, StateInfo[] initialStatesA, bytes32 baseDataB, StateInfo[] initialStatesB): Mints two fragments and entangles them.
 *
 * Superposition Management (Before Observation):
 * - addPotentialState(uint256 fragmentId, StateInfo state): Adds a new potential state.
 * - removePotentialState(uint256 fragmentId, uint256 stateId): Removes a potential state.
 * - modifyStateWeight(uint256 fragmentId, uint256 stateId, uint16 newWeight): Adjusts a potential state's weight.
 * - updatePotentialStateMetadata(uint256 fragmentId, uint256 stateId, string newMetadataHash): Updates metadata for a potential state.
 *
 * Observation & Collapse:
 * - observeFragment(uint256 fragmentId): Triggers the collapse of a single fragment.
 * - observeEntangledPair(uint256 fragmentIdA): Triggers observation on a fragment and its entangled partners (if applicable).
 *
 * Entanglement Management:
 * - entangleFragments(uint256 fragmentIdA, uint256 fragmentIdB): Links two fragments.
 * - disentangleFragments(uint256 fragmentIdA, uint256 fragmentIdB): Breaks the link between two fragments.
 *
 * Fragment & State Interaction (After Observation):
 * - updateCurrentStateMetadata(uint256 fragmentId, string newMetadataHash): Updates metadata for the collapsed state.
 *
 * Information & View Functions:
 * - getFragmentDetails(uint256 fragmentId): Gets detailed fragment info.
 * - getOwner(uint256 fragmentId): Gets fragment owner.
 * - getPotentialStates(uint256 fragmentId): Gets potential states.
 * - getCurrentState(uint256 fragmentId): Gets collapsed state info.
 * - isSuperposition(uint256 fragmentId): Checks if fragment is in superposition.
 * - getEntangledFragments(uint256 fragmentId): Gets entangled fragments.
 * - getHistoryLog(uint256 fragmentId): Gets history log.
 * - getStateMetadata(uint256 fragmentId, uint256 stateId): Gets state metadata.
 * - getTotalFragments(): Gets total fragments minted.
 * - getObservationFee(): Gets current observation fee.
 * - isPaused(): Checks if contract is paused.
 *
 * Ownership & Administration:
 * - transferFragment(uint256 fragmentId, address newOwner): Transfers fragment ownership.
 * - setObservationFee(uint256 newFee): Sets observation fee.
 * - withdrawFunds(): Withdraws fees.
 * - pauseContract(): Pauses contract.
 * - unpauseContract(): Unpauses contract.
 *
 * Interface Support:
 * - supportsInterface(bytes4 interfaceId): ERC-165 introspection.
 */

contract QuantumChronicle is Ownable, Pausable, ERC165 {
    using SafeMath for uint256; // Example use, 0.8+ has overflow checks by default

    struct StateInfo {
        uint256 stateId;
        string metadataHash; // IPFS hash or similar
        uint16 weight;       // Relative probability weight for observation (0-65535)
        bool isObservable;   // Can this state be the outcome of observation?
        bool allowsMetadataUpdate; // Can metadata be changed AFTER collapse?
        bytes32 stateCompatibilityHash; // Hash used for entangled state compatibility
    }

    enum HistoryEntryType {
        Created,
        SuperpositionAdded,
        SuperpositionRemoved,
        WeightModified,
        MetadataUpdated,
        Observed,
        Entangled,
        Disentangled,
        Transferred
    }

    struct HistoryEntry {
        uint64 timestamp;
        HistoryEntryType entryType;
        bytes details; // Arbitrary data related to the event (e.g., old/new values)
    }

    struct ChronicleFragment {
        address owner;
        uint64 creationTimestamp;
        bytes32 baseData; // Immutable core data identifier
        mapping(uint256 => StateInfo) potentialStates; // StateId => StateInfo
        uint256[] potentialStateIds; // Array of stateIds for iteration
        uint256 totalStateWeight; // Sum of weights for active potential states

        uint256 currentStateId;     // The state it collapsed into (0 if in superposition)
        uint64 observationTimestamp; // When it was observed (0 if not)

        uint256[] entangledFragments; // Other fragmentIds this one is entangled with

        HistoryEntry[] historyLog; // Log of significant events
    }

    mapping(uint256 => ChronicleFragment) private _fragments;
    uint256 private _nextTokenId; // Counter for fragment IDs

    mapping(uint256 => address) private _owners; // Explicit ownership mapping (simplified)

    uint256 public observationFee = 0 ether; // Fee required to observe a fragment

    // --- Events ---
    event FragmentCreated(uint256 indexed fragmentId, address indexed owner, bytes32 baseData, uint64 timestamp);
    event StateAddedToSuperposition(uint256 indexed fragmentId, uint256 indexed stateId, uint16 weight);
    event StateRemovedFromSuperposition(uint256 indexed fragmentId, uint256 indexed stateId);
    event StateWeightModified(uint256 indexed fragmentId, uint256 indexed stateId, uint16 oldWeight, uint16 newWeight);
    event PotentialStateMetadataUpdated(uint256 indexed fragmentId, uint256 indexed stateId, string newMetadataHash);
    event FragmentObserved(uint256 indexed fragmentId, uint256 indexed collapsedStateId, uint64 timestamp, bytes32 usedRandomness);
    event CurrentStateMetadataUpdated(uint256 indexed fragmentId, uint256 indexed stateId, string newMetadataHash);
    event FragmentsEntangled(uint256 indexed fragmentIdA, uint256 indexed fragmentIdB);
    event FragmentsDisentangled(uint256 indexed fragmentIdA, uint256 indexed fragmentIdB);
    event FragmentTransferred(uint256 indexed fragmentId, address indexed from, address indexed to);
    event HistoryEntryAdded(uint256 indexed fragmentId, HistoryEntryType entryType, uint64 timestamp);
    event ObservationFeeSet(uint256 oldFee, uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // --- Errors ---
    error FragmentNotFound(uint256 fragmentId);
    error StateNotFound(uint256 fragmentId, uint256 stateId);
    error NotInSuperposition(uint256 fragmentId);
    error AlreadyObserved(uint256 fragmentId);
    error StateAlreadyExists(uint256 fragmentId, uint256 stateId);
    error StateNotPotential(uint256 fragmentId, uint256 stateId);
    error InvalidStateWeight(uint16 weight);
    error ObservationFeeNotMet(uint256 requiredFee, uint256 sentAmount);
    error NoObservableStates(uint256 fragmentId);
    error EntangledFragmentsMustExist(uint256 fragmentIdA, uint256 fragmentIdB);
    error FragmentsAlreadyEntangled(uint256 fragmentIdA, uint256 fragmentIdB);
    error FragmentsNotEntangled(uint256 fragmentIdA, uint256 fragmentIdB);
    error CannotUpdateMetadataForState(uint256 fragmentId, uint256 stateId);
    error EntangledObservationFailed(uint256 fragmentIdA, uint256 fragmentIdB);
    error EntangledStateIncompatibility(uint256 fragmentIdA, uint256 stateIdA, uint256 fragmentIdB, uint256 stateIdB);

    constructor() Ownable(msg.sender) Pausable() {
        // The _nextTokenId starts at 1 as 0 is used to indicate 'not observed' state ID
        _nextTokenId = 1;
    }

    // --- Interface Introspection ---
    // ERC-165 identifier for this specific contract, if needed for discovery
    // Not implementing full ERC721, just the introspection part.
    // We can define a custom interface ID for QuantumChronicle or just support 165 itself.
    // The interface ID for ERC165 is 0x01ffc9a7.
    // If we were to define our own interface, we'd hash function signatures:
    // bytes4(keccak256("createFragment(bytes32,StateInfo[])")) ^ ... etc.
    // For simplicity, let's just support the ERC165 standard interface ID itself.
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        // Check if the contract supports the ERC165 standard interface ID (0x01ffc9a7)
        // or potentially other interfaces in the future.
        return interfaceId == type(ERC165).interfaceId || super.supportsInterface(interfaceId);
    }


    // --- Core Fragment Management ---

    /**
     * @dev Mints a new Chronicle Fragment in a state of superposition.
     * @param baseData Immutable core data for the fragment.
     * @param initialStates Array of initial potential states.
     * Requires at least one initial state with weight > 0.
     */
    function createFragment(bytes32 baseData, StateInfo[] calldata initialStates) external whenNotPaused returns (uint256) {
        require(initialStates.length > 0, "QC: Must provide initial states");

        uint256 fragmentId = _nextTokenId++;
        _fragments[fragmentId].owner = msg.sender;
        _owners[fragmentId] = msg.sender; // Simplified ownership tracking
        _fragments[fragmentId].creationTimestamp = uint64(block.timestamp);
        _fragments[fragmentId].baseData = baseData;
        _fragments[fragmentId].currentStateId = 0; // 0 means not observed

        uint256 currentTotalWeight = 0;
        for (uint i = 0; i < initialStates.length; i++) {
             require(initialStates[i].weight > 0, "QC: Initial state weight must be > 0");
             require(_fragments[fragmentId].potentialStates[initialStates[i].stateId].stateId == 0, "QC: Duplicate initial stateId"); // Basic check

            _fragments[fragmentId].potentialStates[initialStates[i].stateId] = initialStates[i];
            _fragments[fragmentId].potentialStateIds.push(initialStates[i].stateId);
            currentTotalWeight = currentTotalWeight.add(initialStates[i].weight);
        }
         require(currentTotalWeight > 0, "QC: Total initial weight must be > 0");

        _fragments[fragmentId].totalStateWeight = currentTotalWeight;

        _addHistoryEntry(fragmentId, HistoryEntryType.Created, abi.encode(msg.sender, baseData));

        emit FragmentCreated(fragmentId, msg.sender, baseData, block.timestamp);
        return fragmentId;
    }

    /**
     * @dev Mints two new Chronicle Fragments and immediately entangles them.
     * @param baseDataA Immutable core data for fragment A.
     * @param initialStatesA Initial potential states for fragment A.
     * @param baseDataB Immutable core data for fragment B.
     * @param initialStatesB Initial potential states for fragment B.
     */
     function createEntangledFragments(
         bytes32 baseDataA, StateInfo[] calldata initialStatesA,
         bytes32 baseDataB, StateInfo[] calldata initialStatesB
     ) external whenNotPaused returns (uint256 fragmentIdA, uint256 fragmentIdB) {
         fragmentIdA = createFragment(baseDataA, initialStatesA); // Calls internal create logic
         fragmentIdB = createFragment(baseDataB, initialStatesB); // Calls internal create logic

         _entangle(fragmentIdA, fragmentIdB); // Directly entangle internally

         emit FragmentsEntangled(fragmentIdA, fragmentIdB); // Emit entanglement event
     }


    // --- Superposition Management ---

    /**
     * @dev Adds a new potential state to a fragment that is still in superposition.
     * @param fragmentId The ID of the fragment.
     * @param state The StateInfo struct for the new state.
     */
    function addPotentialState(uint256 fragmentId, StateInfo calldata state) external whenNotPaused {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        require(_fragments[fragmentId].currentStateId == 0, NotInSuperposition(fragmentId)); // Must be in superposition
        require(_fragments[fragmentId].potentialStates[state.stateId].stateId == 0, StateAlreadyExists(fragmentId, state.stateId)); // StateId must be unique for this fragment

        _fragments[fragmentId].potentialStates[state.stateId] = state;
        _fragments[fragmentId].potentialStateIds.push(state.stateId);
        _fragments[fragmentId].totalStateWeight = _fragments[fragmentId].totalStateWeight.add(state.weight);

        _addHistoryEntry(fragmentId, HistoryEntryType.SuperpositionAdded, abi.encode(state.stateId, state.weight, state.metadataHash));

        emit StateAddedToSuperposition(fragmentId, state.stateId, state.weight);
    }

    /**
     * @dev Removes a potential state from a fragment that is still in superposition.
     * @param fragmentId The ID of the fragment.
     * @param stateId The ID of the state to remove.
     */
    function removePotentialState(uint256 fragmentId, uint256 stateId) external whenNotPaused {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        require(_fragments[fragmentId].currentStateId == 0, NotInSuperposition(fragmentId)); // Must be in superposition
        StateInfo storage state = _fragments[fragmentId].potentialStates[stateId];
        require(state.stateId == stateId && stateId != 0, StateNotFound(fragmentId, stateId)); // State must exist and not be the 'unobserved' state 0

        // Remove from stateIds array
        uint256[] storage potentialIds = _fragments[fragmentId].potentialStateIds;
        for (uint i = 0; i < potentialIds.length; i++) {
            if (potentialIds[i] == stateId) {
                // Swap last element with current and pop (unordered removal)
                potentialIds[i] = potentialIds[potentialIds.length - 1];
                potentialIds.pop();
                break; // Found and removed
            }
        }

        _fragments[fragmentId].totalStateWeight = _fragments[fragmentId].totalStateWeight.sub(state.weight);
        delete _fragments[fragmentId].potentialStates[stateId]; // Delete from mapping

        _addHistoryEntry(fragmentId, HistoryEntryType.SuperpositionRemoved, abi.encode(stateId));

        emit StateRemovedFromSuperposition(fragmentId, stateId);
    }

    /**
     * @dev Modifies the weight of an existing potential state for a fragment in superposition.
     * @param fragmentId The ID of the fragment.
     * @param stateId The ID of the state to modify.
     * @param newWeight The new weight for the state. Must be > 0.
     */
    function modifyStateWeight(uint256 fragmentId, uint256 stateId, uint16 newWeight) external whenNotPaused {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        require(_fragments[fragmentId].currentStateId == 0, NotInSuperposition(fragmentId)); // Must be in superposition
        StateInfo storage state = _fragments[fragmentId].potentialStates[stateId];
        require(state.stateId == stateId && stateId != 0, StateNotFound(fragmentId, stateId)); // State must exist

        uint16 oldWeight = state.weight;
        require(newWeight > 0, InvalidStateWeight(newWeight));

        _fragments[fragmentId].totalStateWeight = _fragments[fragmentId].totalStateWeight.sub(oldWeight).add(newWeight);
        state.weight = newWeight;

        _addHistoryEntry(fragmentId, HistoryEntryType.WeightModified, abi.encode(stateId, oldWeight, newWeight));

        emit StateWeightModified(fragmentId, stateId, oldWeight, newWeight);
    }

     /**
      * @dev Updates the metadata hash for a potential state in superposition.
      * @param fragmentId The ID of the fragment.
      * @param stateId The ID of the state to modify.
      * @param newMetadataHash The new metadata hash string.
      */
     function updatePotentialStateMetadata(uint256 fragmentId, uint256 stateId, string calldata newMetadataHash) external whenNotPaused {
         require(_exists(fragmentId), FragmentNotFound(fragmentId));
         require(_fragments[fragmentId].currentStateId == 0, NotInSuperposition(fragmentId)); // Must be in superposition
         StateInfo storage state = _fragments[fragmentId].potentialStates[stateId];
         require(state.stateId == stateId && stateId != 0, StateNotFound(fragmentId, stateId)); // State must exist

         state.metadataHash = newMetadataHash;

         _addHistoryEntry(fragmentId, HistoryEntryType.MetadataUpdated, abi.encode(stateId, newMetadataHash));

         emit PotentialStateMetadataUpdated(fragmentId, stateId, newMetadataHash);
     }

    // --- Observation & Collapse ---

    /**
     * @dev Triggers the collapse of a fragment from superposition into a definite state.
     * Pays the observation fee. The state is selected based on weighted probabilities and simulated randomness.
     * @param fragmentId The ID of the fragment to observe.
     */
    function observeFragment(uint256 fragmentId) external payable whenNotPaused {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        require(_fragments[fragmentId].currentStateId == 0, AlreadyObserved(fragmentId)); // Must be in superposition
        require(msg.value >= observationFee, ObservationFeeNotMet(observationFee, msg.value));

        // Find observable states and sum their weights
        uint256[] memory observableStateIds;
        uint256 observableTotalWeight = 0;
        uint256[] storage potentialIds = _fragments[fragmentId].potentialStateIds;

        // First pass to filter observable states and calculate their total weight
        uint256 observableCount = 0;
        for(uint i=0; i < potentialIds.length; i++) {
            StateInfo storage state = _fragments[fragmentId].potentialStates[potentialIds[i]];
            if(state.isObservable) {
                 observableCount++; // Just count first, resize array later
            }
        }

        require(observableCount > 0, NoObservableStates(fragmentId));

        observableStateIds = new uint256[](observableCount);
        uint256 currentObservableIndex = 0;
        for(uint i=0; i < potentialIds.length; i++) {
            StateInfo storage state = _fragments[fragmentId].potentialStates[potentialIds[i]];
            if(state.isObservable) {
                observableStateIds[currentObservableIndex] = potentialIds[i];
                observableTotalWeight = observableTotalWeight.add(state.weight);
                currentObservableIndex++;
            }
        }

        // Ensure total weight is still positive after filtering
        require(observableTotalWeight > 0, NoObservableStates(fragmentId));


        // Simulate randomness (WARNING: NOT CRYPTOGRAPHICALLY SECURE FOR HIGH-VALUE USE CASES)
        // Use block.timestamp, block.prevrandao (renamed from block.difficulty in newer versions)
        // and msg.sender for a basic, non-production friendly random seed.
        // For production, integrate Chainlink VRF or similar.
        bytes32 randomness = keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use block.difficulty for older compilers (<0.8.0)
            msg.sender,
            fragmentId
        ));

        // Select state based on weighted probability
        uint256 selectedStateId = _selectState(fragmentId, observableStateIds, observableTotalWeight, uint256(randomness));

        _performObservation(fragmentId, selectedStateId, randomness);
    }

    /**
     * @dev Triggers observation on a fragment and attempts to observe its entangled partners.
     * Entangled observation may require state compatibility between the collapsed states.
     * @param fragmentIdA The ID of the primary fragment to observe.
     */
    function observeEntangledPair(uint256 fragmentIdA) external payable whenNotPaused {
        require(_exists(fragmentIdA), FragmentNotFound(fragmentIdA));
        require(_fragments[fragmentIdA].currentStateId == 0, AlreadyObserved(fragmentIdA)); // Must be in superposition
        // Note: Fee is paid *once* per observation call, even if multiple fragments collapse.
        // Adjust fee logic if needed for complex entangled scenarios.
        require(msg.value >= observationFee, ObservationFeeNotMet(observationFee, msg.value));


         // Simulate randomness for the pair (same seed for linked outcomes)
         bytes32 randomness = keccak256(abi.encodePacked(
             block.timestamp,
             block.prevrandao,
             msg.sender,
             fragmentIdA,
             "entangled" // Add a unique factor for entangled observation
         ));

        // --- 1. Observe Fragment A ---
        // Find observable states for A and sum their weights
        uint256[] memory observableStateIdsA;
        uint256 observableTotalWeightA = 0;
        uint256[] storage potentialIdsA = _fragments[fragmentIdA].potentialStateIds;

        uint256 observableCountA = 0;
         for(uint i=0; i < potentialIdsA.length; i++) {
             if(_fragments[fragmentIdA].potentialStates[potentialIdsA[i]].isObservable) {
                  observableCountA++;
             }
         }
         require(observableCountA > 0, NoObservableStates(fragmentIdA));

         observableStateIdsA = new uint256[](observableCountA);
         uint256 currentObservableIndexA = 0;
         for(uint i=0; i < potentialIdsA.length; i++) {
             StateInfo storage state = _fragments[fragmentIdA].potentialStates[potentialIdsA[i]];
             if(state.isObservable) {
                 observableStateIdsA[currentObservableIndexA] = potentialIdsA[i];
                 observableTotalWeightA = observableTotalWeightA.add(state.weight);
                 currentObservableIndexA++;
             }
         }
         require(observableTotalWeightA > 0, NoObservableStates(fragmentIdA));

        // Select state for A
        uint256 selectedStateIdA = _selectState(fragmentIdA, observableStateIdsA, observableTotalWeightA, uint256(randomness));
        StateInfo storage selectedStateA = _fragments[fragmentIdA].potentialStates[selectedStateIdA];

        // --- 2. Attempt to Observe Entangled Fragments ---
        uint256[] storage entangledIds = _fragments[fragmentIdA].entangledFragments;
        for (uint i = 0; i < entangledIds.length; i++) {
            uint256 fragmentIdB = entangledIds[i];

            // Check if fragment B exists, is not observed, and is entangled back with A
            if (_exists(fragmentIdB) &&
                _fragments[fragmentIdB].currentStateId == 0 &&
                _isEntangledWith(fragmentIdB, fragmentIdA)) // Check reciprocal entanglement
             {
                // Find observable states for B that are COMPATIBLE with A's selected state
                uint256[] memory compatibleObservableStateIdsB;
                uint256 compatibleObservableTotalWeightB = 0;
                uint256[] storage potentialIdsB = _fragments[fragmentIdB].potentialStateIds;

                uint256 compatibleCountB = 0;
                for(uint j=0; j < potentialIdsB.length; j++) {
                     StateInfo storage stateB = _fragments[fragmentIdB].potentialStates[potentialIdsB[j]];
                     // State B must be observable AND its compatibility hash must match A's collapsed state's compatibility hash
                     if(stateB.isObservable && stateB.stateCompatibilityHash == selectedStateA.stateCompatibilityHash) {
                          compatibleCountB++;
                     }
                }

                // If no compatible observable states exist for B, this entangled observation FAILS for B
                if(compatibleCountB == 0) {
                    // Optionally log this failure or emit a specific event
                     emit EntangledObservationFailed(fragmentIdA, fragmentIdB);
                    continue; // Skip observation for this entangled partner
                }

                compatibleObservableStateIdsB = new uint256[](compatibleCountB);
                uint256 currentCompatibleIndexB = 0;
                for(uint j=0; j < potentialIdsB.length; j++) {
                    StateInfo storage stateB = _fragments[fragmentIdB].potentialStates[potentialIdsB[j]];
                     if(stateB.isObservable && stateB.stateCompatibilityHash == selectedStateA.stateCompatibilityHash) {
                        compatibleObservableStateIdsB[currentCompatibleIndexB] = potentialIdsB[j];
                        compatibleObservableTotalWeightB = compatibleObservableTotalWeightB.add(stateB.weight);
                        currentCompatibleIndexB++;
                    }
                }
                 // Ensure total weight is still positive after filtering
                 if (compatibleObservableTotalWeightB == 0) {
                      emit EntangledObservationFailed(fragmentIdA, fragmentIdB);
                      continue; // Skip observation for this entangled partner
                 }


                // Select state for B from the *compatible* and *observable* states
                // Use related randomness, maybe derived from the original randomness
                 bytes32 randomnessB = keccak256(abi.encodePacked(randomness, fragmentIdB)); // Derive randomness for B

                uint256 selectedStateIdB = _selectState(fragmentIdB, compatibleObservableStateIdsB, compatibleObservableTotalWeightB, uint256(randomnessB));

                // Perform observation for B
                _performObservation(fragmentIdB, selectedStateIdB, randomnessB);

             }
        }

        // Finally, perform observation for A
         _performObservation(fragmentIdA, selectedStateIdA, randomness); // Use the original randomness for A

        // Note: The fee was checked and paid at the beginning for the entire entangled observation process.
    }

    // --- Entanglement Management ---

    /**
     * @dev Entangles two existing Chronicle Fragments.
     * Fragments must exist and not be entangled with each other already.
     * Entanglement is reciprocal.
     * @param fragmentIdA The ID of the first fragment.
     * @param fragmentIdB The ID of the second fragment.
     */
    function entangleFragments(uint256 fragmentIdA, uint256 fragmentIdB) external whenNotPaused {
        require(fragmentIdA != fragmentIdB, "QC: Cannot entangle fragment with itself");
        require(_exists(fragmentIdA) && _exists(fragmentIdB), EntangledFragmentsMustExist(fragmentIdA, fragmentIdB));
        require(!_isEntangledWith(fragmentIdA, fragmentIdB), FragmentsAlreadyEntangled(fragmentIdA, fragmentIdB));

        _entangle(fragmentIdA, fragmentIdB); // Internal reciprocal linking

        _addHistoryEntry(fragmentIdA, HistoryEntryType.Entangled, abi.encode(fragmentIdB));
        _addHistoryEntry(fragmentIdB, HistoryEntryType.Entangled, abi.encode(fragmentIdA));

        emit FragmentsEntangled(fragmentIdA, fragmentIdB);
    }

    /**
     * @dev Breaks the entanglement between two fragments.
     * Fragments must be entangled.
     * Disentanglement is reciprocal.
     * @param fragmentIdA The ID of the first fragment.
     * @param fragmentIdB The ID of the second fragment.
     */
    function disentangleFragments(uint256 fragmentIdA, uint256 fragmentIdB) external whenNotPaused {
        require(fragmentIdA != fragmentIdB, "QC: Cannot disentangle fragment with itself");
        require(_exists(fragmentIdA) && _exists(fragmentIdB), EntangledFragmentsMustExist(fragmentIdA, fragmentIdB)); // Check existence
        require(_isEntangledWith(fragmentIdA, fragmentIdB), FragmentsNotEntangled(fragmentIdA, fragmentIdB));

        _disentangle(fragmentIdA, fragmentIdB); // Internal reciprocal unlinking

        _addHistoryEntry(fragmentIdA, HistoryEntryType.Disentangled, abi.encode(fragmentIdB));
        _addHistoryEntry(fragmentIdB, HistoryEntryType.Disentangled, abi.encode(fragmentIdA));

        emit FragmentsDisentangled(fragmentIdA, fragmentIdB);
    }

    // --- State Interaction (Post-Collapse) ---

     /**
      * @dev Updates the metadata hash for the fragment's *current* collapsed state.
      * Allowed only if the current state's `allowsMetadataUpdate` is true.
      * @param fragmentId The ID of the fragment.
      * @param newMetadataHash The new metadata hash string.
      */
     function updateCurrentStateMetadata(uint256 fragmentId, string calldata newMetadataHash) external whenNotPaused {
         require(_exists(fragmentId), FragmentNotFound(fragmentId));
         require(_fragments[fragmentId].currentStateId != 0, "QC: Fragment is still in superposition"); // Must be observed

         StateInfo storage currentState = _fragments[fragmentId].potentialStates[_fragments[fragmentId].currentStateId];
         require(currentState.allowsMetadataUpdate, CannotUpdateMetadataForState(fragmentId, currentState.stateId));

         currentState.metadataHash = newMetadataHash;

         _addHistoryEntry(fragmentId, HistoryEntryType.MetadataUpdated, abi.encode(currentState.stateId, newMetadataHash));

         emit CurrentStateMetadataUpdated(fragmentId, currentState.stateId, newMetadataHash);
     }


    // --- Information & View Functions ---

    /**
     * @dev Gets comprehensive details for a Chronicle Fragment.
     * @param fragmentId The ID of the fragment.
     * @return owner Address of the fragment owner.
     * @return creationTimestamp Fragment creation time.
     * @return baseData Immutable base data.
     * @return currentStateId ID of the collapsed state (0 if superposition).
     * @return observationTimestamp Time of observation (0 if superposition).
     * @return entangledFragments List of entangled fragment IDs.
     * Note: Does NOT return potential state details or history log directly to keep view gas low.
     */
    function getFragmentDetails(uint256 fragmentId) public view returns (
        address owner,
        uint64 creationTimestamp,
        bytes32 baseData,
        uint256 currentStateId,
        uint64 observationTimestamp,
        uint256[] memory entangledFragments
    ) {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        ChronicleFragment storage fragment = _fragments[fragmentId];
        return (
            fragment.owner,
            fragment.creationTimestamp,
            fragment.baseData,
            fragment.currentStateId,
            fragment.observationTimestamp,
            fragment.entangledFragments // Returns a copy of the array
        );
    }

    /**
     * @dev Gets the owner of a specific fragment.
     * @param fragmentId The ID of the fragment.
     * @return The owner's address.
     */
    function getOwner(uint256 fragmentId) public view returns (address) {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        return _owners[fragmentId]; // Use simplified owner mapping for efficiency
    }

    /**
     * @dev Gets the potential states for a fragment.
     * Only available if the fragment is in superposition.
     * @param fragmentId The ID of the fragment.
     * @return An array of StateInfo structs.
     */
    function getPotentialStates(uint256 fragmentId) public view returns (StateInfo[] memory) {
         require(_exists(fragmentId), FragmentNotFound(fragmentId));
         require(_fragments[fragmentId].currentStateId == 0, AlreadyObserved(fragmentId)); // Only available in superposition

         uint256[] storage potentialIds = _fragments[fragmentId].potentialStateIds;
         StateInfo[] memory states = new StateInfo[](potentialIds.length);
         for(uint i = 0; i < potentialIds.length; i++) {
             states[i] = _fragments[fragmentId].potentialStates[potentialIds[i]];
         }
         return states;
    }

    /**
     * @dev Gets the current collapsed state of a fragment.
     * @param fragmentId The ID of the fragment.
     * @return stateId The ID of the collapsed state (0 if still in superposition).
     * @return metadataHash The metadata hash of the collapsed state (empty string if superposition).
     */
    function getCurrentState(uint256 fragmentId) public view returns (uint256 stateId, string memory metadataHash) {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        uint256 currentId = _fragments[fragmentId].currentStateId;
        if (currentId == 0) {
            return (0, ""); // Still in superposition
        } else {
            StateInfo storage currentState = _fragments[fragmentId].potentialStates[currentId];
            return (currentId, currentState.metadataHash);
        }
    }

    /**
     * @dev Checks if a fragment is currently in a state of superposition.
     * @param fragmentId The ID of the fragment.
     * @return True if in superposition, false otherwise.
     */
    function isSuperposition(uint256 fragmentId) public view returns (bool) {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        return _fragments[fragmentId].currentStateId == 0;
    }

    /**
     * @dev Gets the list of fragment IDs that a given fragment is entangled with.
     * @param fragmentId The ID of the fragment.
     * @return An array of entangled fragment IDs.
     */
    function getEntangledFragments(uint256 fragmentId) public view returns (uint256[] memory) {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        return _fragments[fragmentId].entangledFragments; // Returns a copy
    }

    /**
     * @dev Gets the history log for a fragment.
     * Note: Can be gas-intensive for long histories. Consider off-chain indexing of events instead for performance.
     * @param fragmentId The ID of the fragment.
     * @return An array of HistoryEntry structs.
     */
    function getHistoryLog(uint256 fragmentId) public view returns (HistoryEntry[] memory) {
        require(_exists(fragmentId), FragmentNotFound(fragmentId));
        return _fragments[fragmentId].historyLog; // Returns a copy
    }

    /**
     * @dev Gets the details of a specific potential or current state for a fragment.
     * @param fragmentId The ID of the fragment.
     * @param stateId The ID of the state.
     * @return The StateInfo struct.
     */
    function getStateMetadata(uint256 fragmentId, uint256 stateId) public view returns (StateInfo memory) {
         require(_exists(fragmentId), FragmentNotFound(fragmentId));
         // Allow fetching details for the current state (even if not in potentialIds anymore)
         if (_fragments[fragmentId].currentStateId == stateId || _fragments[fragmentId].potentialStates[stateId].stateId == stateId) {
              return _fragments[fragmentId].potentialStates[stateId];
         }
         revert StateNotFound(fragmentId, stateId);
    }


    /**
     * @dev Gets the total number of fragments minted.
     * @return The total count.
     */
    function getTotalFragments() public view returns (uint256) {
        return _nextTokenId - 1; // _nextTokenId is the next available ID, count is one less
    }

    /**
     * @dev Gets the current fee required to observe a fragment.
     * @return The observation fee in Wei.
     */
    function getObservationFee() public view returns (uint256) {
        return observationFee;
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused();
    }


    // --- Ownership & Administration ---

    /**
     * @dev Transfers ownership of a fragment to a new address.
     * Basic transfer, not full ERC721 spec.
     * @param fragmentId The ID of the fragment to transfer.
     * @param newOwner The address to transfer to.
     */
    function transferFragment(uint256 fragmentId, address newOwner) external whenNotPaused {
         require(_exists(fragmentId), FragmentNotFound(fragmentId));
         address currentOwner = _owners[fragmentId];
         require(msg.sender == currentOwner, "QC: Not fragment owner");
         require(newOwner != address(0), "QC: Transfer to zero address");

         _fragments[fragmentId].owner = newOwner; // Update owner in the struct
         _owners[fragmentId] = newOwner; // Update simplified owner mapping

         _addHistoryEntry(fragmentId, HistoryEntryType.Transferred, abi.encode(currentOwner, newOwner));

         emit FragmentTransferred(fragmentId, currentOwner, newOwner);
    }


    /**
     * @dev Sets the fee required to observe a fragment. Only callable by the owner.
     * @param newFee The new fee in Wei.
     */
    function setObservationFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = observationFee;
        observationFee = newFee;
        emit ObservationFeeSet(oldFee, newFee);
    }

    /**
     * @dev Allows the contract owner to withdraw collected observation fees.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "QC: No funds to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "QC: Withdrawal failed");
        emit FundsWithdrawn(msg.sender, balance);
    }

    /**
     * @dev Pauses the contract, preventing key interactions like creation, observation, entanglement, transfer.
     * Only callable by the owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Checks if a fragment with the given ID exists.
     */
    function _exists(uint256 fragmentId) internal view returns (bool) {
        // Fragment 0 is invalid; check creation timestamp is non-zero
        return fragmentId > 0 && _fragments[fragmentId].creationTimestamp > 0;
    }

    /**
     * @dev Adds an entry to a fragment's history log.
     */
    function _addHistoryEntry(uint256 fragmentId, HistoryEntryType entryType, bytes memory details) internal {
        _fragments[fragmentId].historyLog.push(HistoryEntry({
            timestamp: uint64(block.timestamp),
            entryType: entryType,
            details: details
        }));
        emit HistoryEntryAdded(fragmentId, entryType, uint64(block.timestamp));
    }

     /**
      * @dev Selects a state based on weighted probabilities and randomness.
      * @param fragmentId The ID of the fragment.
      * @param stateIds The IDs of the states to select from.
      * @param totalWeight The sum of weights of the states in stateIds.
      * @param seed The random seed (uint256).
      * @return The ID of the selected state.
      */
     function _selectState(uint256 fragmentId, uint256[] memory stateIds, uint256 totalWeight, uint256 seed) internal view returns (uint256) {
         require(totalWeight > 0, "QC: Cannot select state with zero total weight");
         uint256 randomNumber = seed % totalWeight;
         uint256 cumulativeWeight = 0;

         for (uint i = 0; i < stateIds.length; i++) {
             uint256 stateId = stateIds[i];
             StateInfo storage state = _fragments[fragmentId].potentialStates[stateId]; // Read from storage
             cumulativeWeight = cumulativeWeight.add(state.weight);
             if (randomNumber < cumulativeWeight) {
                 return stateId;
             }
         }

         // This should theoretically not be reached if totalWeight is calculated correctly
         // and stateIds contains all states contributing to that weight.
         // As a fallback or safety, return the last state or revert. Reverting is safer.
         revert("QC: State selection failed (internal error)");
     }


     /**
      * @dev Performs the final steps of fragment observation and state collapse.
      * Internal function to avoid code duplication between observeFragment and observeEntangledPair.
      * @param fragmentId The ID of the fragment being observed.
      * @param selectedStateId The ID of the state selected for collapse.
      * @param randomnessUsed The randomness value used for selection.
      */
     function _performObservation(uint256 fragmentId, uint256 selectedStateId, bytes32 randomnessUsed) internal {
         require(_fragments[fragmentId].currentStateId == 0, AlreadyObserved(fragmentId)); // Double-check

         _fragments[fragmentId].currentStateId = selectedStateId;
         _fragments[fragmentId].observationTimestamp = uint64(block.timestamp);

         // Clear potential states and reset weight sum after collapse
         // We don't delete the StateInfo structs themselves immediately in the mapping
         // because the selected state's info is still needed for getCurrentState etc.
         // We clear the *array* of potential state IDs as they are no longer 'potential'.
         delete _fragments[fragmentId].potentialStateIds;
         _fragments[fragmentId].totalStateWeight = 0;

         _addHistoryEntry(fragmentId, HistoryEntryType.Observed, abi.encode(selectedStateId, randomnessUsed));

         emit FragmentObserved(fragmentId, selectedStateId, block.timestamp, randomnessUsed);
     }


    /**
     * @dev Internal function to check if two fragments are entangled.
     * Checks if fragmentIdB is in fragmentIdA's entangled list.
     */
    function _isEntangledWith(uint256 fragmentIdA, uint256 fragmentIdB) internal view returns (bool) {
        uint256[] storage entangledIds = _fragments[fragmentIdA].entangledFragments;
        for (uint i = 0; i < entangledIds.length; i++) {
            if (entangledIds[i] == fragmentIdB) {
                return true;
            }
        }
        return false;
    }

     /**
      * @dev Internal function to perform reciprocal entanglement.
      */
    function _entangle(uint256 fragmentIdA, uint256 fragmentIdB) internal {
         // Add B to A's list
         bool foundA = false;
         uint256[] storage entangledIdsA = _fragments[fragmentIdA].entangledFragments;
         for(uint i=0; i < entangledIdsA.length; i++) {
             if(entangledIdsA[i] == fragmentIdB) {
                 foundA = true;
                 break;
             }
         }
         if (!foundA) {
             entangledIdsA.push(fragmentIdB);
         }

         // Add A to B's list
         bool foundB = false;
         uint256[] storage entangledIdsB = _fragments[fragmentIdB].entangledFragments;
         for(uint i=0; i < entangledIdsB.length; i++) {
             if(entangledIdsB[i] == fragmentIdA) {
                 foundB = true;
                 break;
             }
         }
          if (!foundB) {
             entangledIdsB.push(fragmentIdA);
         }
    }

     /**
      * @dev Internal function to perform reciprocal disentanglement.
      */
    function _disentangle(uint256 fragmentIdA, uint256 fragmentIdB) internal {
         // Remove B from A's list
        uint256[] storage entangledIdsA = _fragments[fragmentIdA].entangledFragments;
        for (uint i = 0; i < entangledIdsA.length; i++) {
            if (entangledIdsA[i] == fragmentIdB) {
                entangledIdsA[i] = entangledIdsA[entangledIdsA.length - 1];
                entangledIdsA.pop();
                break; // Assuming unique entries
            }
        }

         // Remove A from B's list
        uint256[] storage entangledIdsB = _fragments[fragmentIdB].entangledFragments;
        for (uint i = 0; i < entangledIdsB.length; i++) {
            if (entangledIdsB[i] == fragmentIdA) {
                entangledIdsB[i] = entangledIdsB[entangledIdsB.length - 1];
                entangledIdsB.pop();
                break; // Assuming unique entries
            }
        }
    }

     // Fallback function to accept ETH for fees
     receive() external payable {}

     // Optional: Add a withdraw function for accidental ETH sent not for observationFee
     function withdrawAccidentalETH(address payable _to) external onlyOwner {
        uint256 balance = address(this).balance.sub(observationFee * getTotalFragments()); // Be careful with this logic - a simple total balance withdrawal might be safer
        if (balance > 0) {
             (bool success, ) = _to.call{value: balance}("");
             require(success, "QC: Accidental withdrawal failed");
        }
     }

}
```