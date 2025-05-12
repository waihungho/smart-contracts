Okay, let's create a smart contract concept around simulating "Quantum Entanglement" and "Superposition" for managing abstract digital "keys" or "access states" on-chain. This is highly metaphorical and uses Solidity's state management to represent these concepts in a creative way, distinctly different from typical access control or token contracts.

We'll call the contract `QuantumEntangledKeyManager`. It will manage key fragments, each capable of being in a superposition of potential states (represented by bitmasks). These fragments can be entangled, meaning collapsing the state of one fragment might influence the potential states of its entangled partners. Observers (allowed addresses) can "measure" a key, collapsing its superposition into a single, definite state based on provided "entropy" (input). Decoherence (automatic return to superposition) and observation locks will add further complexity.

This concept is advanced due to its complex state transitions, mapping relationships between state entities, and the unique logic simulating entanglement effects and superposition collapse. It avoids duplicating common open-source patterns like standard token interfaces, simple ownership, or basic ACLs.

---

**Outline and Function Summary: QuantumEntangledKeyManager**

**Outline:**

1.  **Contract Description:** Manages abstract "Key Fragments" with states representing potential access configurations. Implements concepts of Superposition, Entanglement, and Collapse (measurement) using on-chain state and logic.
2.  **State Representation:**
    *   `KeyFragment` struct: Stores owner, initial state, potential states (array of uint256), current collapsed state index, entanglement status, timestamps, lock status.
    *   Mappings for key storage, entanglement pairs, allowed observers, timestamps, etc.
3.  **Core Concepts & Functions:**
    *   **Creation:** `createKeyFragment`
    *   **Superposition:** `enterSuperposition`, `isSuperposition`
    *   **Collapse (Measurement):** `collapseState` (deterministic based on entropy), `getCurrentState`, `getLastCollapseInfo`
    *   **Entanglement:** `entangleFragments`, `disentangleFragments`, `getEntangledFragments`, `isFragmentEntangled`, `_applyEntanglementEffect` (internal)
    *   **Potential States:** `addPotentialState`, `removePotentialState`, `getPotentialStates`, `updateInitialState`
    *   **Observation Control:** `addAllowedObserver`, `removeAllowedObserver`, `isObserverAllowed`, `getAllowedObservers`, `lockStateForObservation`, `unlockState`, `isStateLocked`
    *   **Decoherence:** `setDecoherenceDuration`, `triggerDecoherenceCheck`
    *   **Temporal/Cooldowns:** `setCollapseCooldown`, `checkCollapseCooldown`
    *   **Ownership:** `transferKeyOwnership`, `getKeyOwner`
    *   **Utilities:** `getKeyFragmentDetails`, `getTotalFragments`
4.  **Events:** Signal state changes, entanglement, collapse, etc.
5.  **Modifiers:** Enforce access control and state preconditions.

**Function Summary:**

1.  `createKeyFragment(uint256 _initialState, uint256[] calldata _potentialStates)`: Creates a new key fragment, initially in superposition with the provided potential states.
2.  `addPotentialState(uint256 _keyId, uint256 _newState)`: Adds a new potential state configuration to a key fragment. Only callable if the key is in superposition.
3.  `removePotentialState(uint256 _keyId, uint256 _stateIndex)`: Removes a potential state configuration by index. Only callable if the key is in superposition.
4.  `updateInitialState(uint256 _keyId, uint256 _newInitialState)`: Updates the base initial state value.
5.  `entangleFragments(uint256 _keyId1, uint256 _keyId2)`: Establishes a bidirectional entanglement link between two key fragments. Requires ownership or permission.
6.  `disentangleFragments(uint256 _keyId1, uint256 _keyId2)`: Removes the entanglement link between two key fragments. Requires ownership or permission.
7.  `addAllowedObserver(uint256 _keyId, address _observer)`: Grants permission to an address to `collapseState` for a specific key.
8.  `removeAllowedObserver(uint256 _keyId, address _observer)`: Revokes observer permission for a specific key.
9.  `setCollapseCooldown(uint256 _keyId, uint256 _duration)`: Sets a minimum time duration that must pass after a collapse before the key can be collapsed again.
10. `setDecoherenceDuration(uint256 _keyId, uint256 _duration)`: Sets the duration after which a collapsed state automatically returns to superposition (simulated decoherence), if `triggerDecoherenceCheck` is called.
11. `enterSuperposition(uint256 _keyId)`: Manually forces a key fragment back into a superposition state (resets collapsed state). Requires ownership.
12. `collapseState(uint256 _keyId, bytes32 _entropy)`: "Measures" the key fragment, collapsing it into one definite state from its potential states, using the provided entropy for deterministic selection. Triggers entanglement effects on linked fragments. Requires observer permission, cooldown check, and not being locked.
13. `lockStateForObservation(uint256 _keyId, uint256 _duration)`: Temporarily prevents `collapseState` or `enterSuperposition` for a specified duration. Requires ownership.
14. `unlockState(uint256 _keyId)`: Removes the lock on a key's state. Requires ownership.
15. `transferKeyOwnership(uint256 _keyId, address _newOwner)`: Transfers ownership of a key fragment.
16. `triggerDecoherenceCheck(uint256 _keyId)`: Allows anyone to trigger a check for decoherence based on the set duration and last collapse time. If criteria met, forces superposition. Useful for external keepers.
17. `getCurrentState(uint256 _keyId)`: Returns the current collapsed state value if the key is collapsed, or 0 if in superposition (or a specific indicator like type(uint256).max).
18. `getPotentialStates(uint256 _keyId)`: Returns the array of potential state configurations for a key fragment.
19. `getEntangledFragments(uint256 _keyId)`: Returns the list of key IDs this fragment is entangled with.
20. `isObserverAllowed(uint256 _keyId, address _observer)`: Checks if an address is an allowed observer for a key.
21. `checkCollapseCooldown(uint256 _keyId)`: Checks if the collapse cooldown period for a key has passed.
22. `isFragmentEntangled(uint256 _keyId)`: Checks if a key fragment is entangled with any other fragment.
23. `getKeyFragmentDetails(uint256 _keyId)`: Returns a tuple containing comprehensive details about a key fragment.
24. `getLastCollapseInfo(uint256 _keyId)`: Returns the timestamp and entropy used for the last state collapse.
25. `getKeyOwner(uint256 _keyId)`: Returns the owner address of a key fragment.
26. `getTotalFragments()`: Returns the total number of key fragments created.
27. `isStateLocked(uint256 _keyId)`: Checks if the key fragment's state is currently locked.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledKeyManager
 * @dev A creative smart contract simulating abstract "Quantum" concepts
 * for managing digital state or access configurations ("Key Fragments") on-chain.
 * - Key Fragments can exist in a "Superposition" of potential states (represented by bitmasks).
 * - They can be "Entangled", where collapsing one affects the potential states of others.
 * - Allowed "Observers" can "Collapse" (measure) a key using deterministic "entropy",
 *   forcing it into one definite state.
 * - Concepts like "Decoherence" (returning to superposition) and "Observation Locks" are included.
 *
 * This contract uses complex state management, mappings, and custom logic
 * to provide a unique and non-standard mechanism for access control or data state representation.
 * It is a metaphorical implementation of quantum ideas for on-chain mechanics.
 */

// Outline:
// 1. Contract Description
// 2. State Representation (Structs, Mappings)
// 3. Core Concepts & Functions (Creation, Superposition, Collapse, Entanglement, etc.)
// 4. Events
// 5. Modifiers

// Function Summary:
// 1. createKeyFragment(uint256 _initialState, uint256[] calldata _potentialStates): Creates a new key fragment.
// 2. addPotentialState(uint256 _keyId, uint256 _newState): Adds a possible state configuration.
// 3. removePotentialState(uint256 _keyId, uint256 _stateIndex): Removes a potential state by index.
// 4. updateInitialState(uint256 _keyId, uint256 _newInitialState): Updates the base initial state.
// 5. entangleFragments(uint256 _keyId1, uint256 _keyId2): Links two fragments with entanglement.
// 6. disentangleFragments(uint256 _keyId1, uint256 _keyId2): Removes entanglement link.
// 7. addAllowedObserver(uint256 _keyId, address _observer): Grants collapse permission.
// 8. removeAllowedObserver(uint256 _keyId, address _observer): Revokes collapse permission.
// 9. setCollapseCooldown(uint256 _keyId, uint256 _duration): Sets minimum time between collapses.
// 10. setDecoherenceDuration(uint256 _keyId, uint256 _duration): Sets duration for automatic decoherence check.
// 11. enterSuperposition(uint256 _keyId): Manually returns a key to superposition.
// 12. collapseState(uint256 _keyId, bytes32 _entropy): "Measures" and collapses the key state.
// 13. lockStateForObservation(uint256 _keyId, uint256 _duration): Prevents state changes temporarily.
// 14. unlockState(uint256 _keyId): Removes observation lock.
// 15. transferKeyOwnership(uint256 _keyId, address _newOwner): Transfers key ownership.
// 16. triggerDecoherenceCheck(uint256 _keyId): Allows external check for decoherence.
// 17. getCurrentState(uint256 _keyId): Gets the currently collapsed state value.
// 18. getPotentialStates(uint256 _keyId): Gets the list of potential states.
// 19. getEntangledFragments(uint256 _keyId): Gets list of entangled partners.
// 20. isObserverAllowed(uint256 _keyId, address _observer): Checks if an address can observe/collapse.
// 21. checkCollapseCooldown(uint256 _keyId): Checks if collapse cooldown has passed.
// 22. isFragmentEntangled(uint256 _keyId): Checks if key is entangled.
// 23. getKeyFragmentDetails(uint256 _keyId): Gets full details of a key fragment.
// 24. getLastCollapseInfo(uint256 _keyId): Gets info about the last collapse.
// 25. getKeyOwner(uint256 _keyId): Gets the owner of a key.
// 26. getTotalFragments(): Gets the total number of keys created.
// 27. isStateLocked(uint256 _keyId): Checks if the key's state is locked.

contract QuantumEntangledKeyManager {

    // --- State Representation ---

    struct KeyFragment {
        address owner;
        uint256 initialState; // Base state value, maybe default if no collapse happens or after full decoherence
        uint256[] potentialStates; // Possible states the fragment can collapse into
        int256 currentStateIndex; // Index in potentialStates after collapse (-1 if in superposition)
        bool isSuperposition; // True if not collapsed
        bool isEntangled; // True if entangled with >= 1 other fragment
        uint256 creationTimestamp;
        uint256 lastCollapseTimestamp;
        bytes32 lastCollapseEntropy; // Entropy used for the last collapse

        uint256 collapseCooldownDuration; // Minimum time between collapses for this key
        uint256 decoherenceDuration; // Time after which a collapsed state *can* revert to superposition

        uint256 stateLockUntil; // Timestamp until which state changes (collapse/superposition) are locked
    }

    // Mapping from Key ID to KeyFragment struct
    mapping(uint256 => KeyFragment) private keyFragments;

    // Mapping representing entanglement: Key ID => List of Entangled Key IDs
    mapping(uint256 => uint256[]) private entangledPairs;

    // Mapping from Key ID to Allowed Observers
    mapping(uint256 => mapping(address => bool)) private allowedObservers;

    // Counter for unique key IDs
    uint256 private nextKeyId;

    // --- Events ---

    event KeyFragmentCreated(uint256 indexed keyId, address indexed owner, uint256 initialState, uint256 numPotentialStates);
    event PotentialStateAdded(uint256 indexed keyId, uint256 newState, uint256 indexed index);
    event PotentialStateRemoved(uint256 indexed keyId, uint256 indexed index);
    event InitialStateUpdated(uint256 indexed keyId, uint256 newInitialState);
    event FragmentsEntangled(uint256 indexed keyId1, uint256 indexed keyId2);
    event FragmentsDisentangled(uint256 indexed keyId1, uint256 indexed keyId2);
    event ObserverAdded(uint256 indexed keyId, address indexed observer);
    event ObserverRemoved(uint256 indexed keyId, address indexed observer);
    event CollapseCooldownSet(uint256 indexed keyId, uint256 duration);
    event DecoherenceDurationSet(uint256 indexed keyId, uint256 duration);
    event StateEnteredSuperposition(uint256 indexed keyId);
    event StateCollapsed(uint256 indexed keyId, uint256 indexed collapsedState, bytes32 entropy);
    event EntanglementEffectApplied(uint256 indexed sourceKeyId, uint256 indexed targetKeyId, uint256 oldPotentialStateCount, uint256 newPotentialStateCount);
    event StateLocked(uint256 indexed keyId, uint256 untilTimestamp);
    event StateUnlocked(uint256 indexed keyId);
    event KeyOwnershipTransferred(uint256 indexed keyId, address indexed oldOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyKeyOwner(uint256 _keyId) {
        require(keyFragments[_keyId].owner == msg.sender, "Not key owner");
        _;
    }

    modifier onlyAllowedObserver(uint256 _keyId) {
        require(keyFragments[_keyId].owner == msg.sender || allowedObservers[_keyId][msg.sender], "Not allowed observer or owner");
        _;
    }

    modifier whenSuperposition(uint256 _keyId) {
        require(keyFragments[_keyId].isSuperposition, "Key not in superposition");
        _;
    }

    modifier whenCollapsed(uint256 _keyId) {
        require(!keyFragments[_keyId].isSuperposition, "Key not collapsed");
        _;
    }

    modifier notLocked(uint256 _keyId) {
        require(block.timestamp >= keyFragments[_keyId].stateLockUntil, "Key state is locked");
        _;
    }

    modifier keyExists(uint256 _keyId) {
        require(keyFragments[_keyId].creationTimestamp > 0, "Key does not exist"); // Use creationTimestamp as existence check
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Deterministically resolves the state index based on entropy and potential states.
     * Uses a hash function to map entropy to an index within the bounds of the array.
     * @param _keyId The ID of the key.
     * @param _entropy Input entropy for state selection.
     * @return The index of the selected state in the potentialStates array.
     */
    function _resolveStateFromEntropy(uint256 _keyId, bytes32 _entropy) internal view returns (uint256) {
        uint256 numPotentialStates = keyFragments[_keyId].potentialStates.length;
        require(numPotentialStates > 0, "No potential states to collapse into");

        // Combine entropy with key-specific deterministic factors for uniqueness
        bytes32 combinedEntropy = keccak256(abi.encodePacked(_entropy, _keyId, block.timestamp, block.number));

        // Convert hash to a uint256 and use modulo to get an index
        return uint256(combinedEntropy) % numPotentialStates;
    }

    /**
     * @dev Applies the "entanglement effect" to entangled partners when a key collapses.
     * This simulation filters the potential states of entangled partners based on
     * the collapsed state of the source key (using bitwise AND as a simple filter).
     * Only affects partners currently in superposition.
     * @param _sourceKeyId The key that just collapsed.
     * @param _collapsedState The state value the source key collapsed into.
     */
    function _applyEntanglementEffect(uint256 _sourceKeyId, uint256 _collapsedState) internal {
        uint256[] storage partners = entangledPairs[_sourceKeyId];
        for (uint i = 0; i < partners.length; i++) {
            uint256 partnerKeyId = partners[i];
            KeyFragment storage partnerFragment = keyFragments[partnerKeyId];

            // Only affect partners currently in superposition
            if (partnerFragment.isSuperposition) {
                 uint256[] memory oldPotentialStates = partnerFragment.potentialStates;
                 uint256[] memory newPotentialStates = new uint256[](oldPotentialStates.length); // Start with same size

                 uint256 validCount = 0;
                 for(uint j = 0; j < oldPotentialStates.length; j++) {
                     // Apply bitwise AND filter: only keep bits set in *both* the old potential state AND the collapsed state of the source
                     uint256 filteredState = oldPotentialStates[j] & _collapsedState;

                     // Keep the state if the filter resulted in a non-zero value (or implement other filtering logic)
                     // Example: filterState == oldPotentialStates[j] implies the old state was a "subset" of the collapsed state's properties
                     // Example: filteredState > 0 implies there's some overlap in properties
                     // Example: always add, just the value changes
                      if (filteredState > 0) { // Simple filtering: state must have at least one bit shared with the collapsed state
                         newPotentialStates[validCount] = filteredState;
                         validCount++;
                      }
                 }

                 // Update potential states, removing filtered-out ones
                 uint256[] memory finalPotentialStates = new uint256[](validCount);
                 for(uint k = 0; k < validCount; k++) {
                     finalPotentialStates[k] = newPotentialStates[k];
                 }
                 partnerFragment.potentialStates = finalPotentialStates;


                // Note: If validCount becomes 0, the partner key might enter a "stuck" state with no potential states.
                // A more complex implementation might force it back to its initialState or handle this.
                // For this version, 0 potential states mean it cannot be collapsed until new states are added.

                emit EntanglementEffectApplied(_sourceKeyId, partnerKeyId, oldPotentialStates.length, partnerFragment.potentialStates.length);
            }
        }
    }

    /**
     * @dev Helper to add a key ID to the entangled list of another key.
     * Prevents duplicates.
     * @param _sourceKeyId The key to add to.
     * @param _targetKeyId The key ID to add to the list.
     */
     function _addEntangledPartner(uint256 _sourceKeyId, uint256 _targetKeyId) internal {
         uint256[] storage partners = entangledPairs[_sourceKeyId];
         for(uint i = 0; i < partners.length; i++) {
             if (partners[i] == _targetKeyId) return; // Already exists
         }
         partners.push(_targetKeyId);
     }

    /**
     * @dev Helper to remove a key ID from the entangled list of another key.
     * @param _sourceKeyId The key to remove from.
     * @param _targetKeyId The key ID to remove from the list.
     */
     function _removeEntangledPartner(uint256 _sourceKeyId, uint256 _targetKeyId) internal {
         uint256[] storage partners = entangledPairs[_sourceKeyId];
         for(uint i = 0; i < partners.length; i++) {
             if (partners[i] == _targetKeyId) {
                 // Shift elements to remove the target ID
                 for(uint j = i; j < partners.length - 1; j++) {
                     partners[j] = partners[j+1];
                 }
                 partners.pop(); // Remove the last element (which is now a duplicate or the shifted element)

                 // Update isEntangled flag if the list becomes empty
                 if (partners.length == 0) {
                     keyFragments[_sourceKeyId].isEntangled = false;
                 }
                 return;
             }
         }
     }


    // --- Public Functions ---

    /**
     * @dev Creates a new key fragment.
     * @param _initialState The base state value.
     * @param _potentialStates An array of possible state configurations this key can collapse into.
     * Requires at least one potential state.
     */
    function createKeyFragment(uint256 _initialState, uint256[] calldata _potentialStates) external returns (uint256 keyId) {
        require(_potentialStates.length > 0, "Must provide at least one potential state");

        keyId = nextKeyId++;
        keyFragments[keyId] = KeyFragment({
            owner: msg.sender,
            initialState: _initialState,
            potentialStates: _potentialStates, // Copy the array
            currentStateIndex: -1, // -1 signifies superposition
            isSuperposition: true,
            isEntangled: false,
            creationTimestamp: block.timestamp,
            lastCollapseTimestamp: 0,
            lastCollapseEntropy: bytes32(0),
            collapseCooldownDuration: 0,
            decoherenceDuration: 0,
            stateLockUntil: 0
        });

        emit KeyFragmentCreated(keyId, msg.sender, _initialState, _potentialStates.length);
        return keyId;
    }

    /**
     * @dev Adds a new potential state configuration to a key fragment.
     * Only possible if the key is currently in superposition.
     * @param _keyId The ID of the key.
     * @param _newState The state value to add to the potential states.
     */
    function addPotentialState(uint256 _keyId, uint256 _newState)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
        whenSuperposition(_keyId)
    {
        keyFragments[_keyId].potentialStates.push(_newState);
        emit PotentialStateAdded(_keyId, _newState, keyFragments[_keyId].potentialStates.length - 1);
    }

    /**
     * @dev Removes a potential state configuration from a key fragment by its index.
     * Only possible if the key is currently in superposition.
     * Uses the swap-and-pop method for efficiency.
     * @param _keyId The ID of the key.
     * @param _stateIndex The index of the potential state to remove.
     */
    function removePotentialState(uint256 _keyId, uint256 _stateIndex)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
        whenSuperposition(_keyId)
    {
        KeyFragment storage key = keyFragments[_keyId];
        require(_stateIndex < key.potentialStates.length, "Invalid state index");
        require(key.potentialStates.length > 1, "Cannot remove the last potential state");

        uint256 removedStateValue = key.potentialStates[_stateIndex];

        // Swap the element to remove with the last element
        key.potentialStates[_stateIndex] = key.potentialStates[key.potentialStates.length - 1];
        // Remove the last element
        key.potentialStates.pop();

        emit PotentialStateRemoved(_keyId, _stateIndex);
    }

     /**
      * @dev Updates the initial base state value for a key fragment.
      * This state is not the collapsed state, but could be used as a default.
      * @param _keyId The ID of the key.
      * @param _newInitialState The new initial state value.
      */
     function updateInitialState(uint256 _keyId, uint256 _newInitialState)
         external
         keyExists(_keyId)
         onlyKeyOwner(_keyId)
     {
         keyFragments[_keyId].initialState = _newInitialState;
         emit InitialStateUpdated(_keyId, _newInitialState);
     }


    /**
     * @dev Establishes a bidirectional entanglement link between two key fragments.
     * Requires ownership of both keys by the sender.
     * Cannot entangle a key with itself.
     * @param _keyId1 The ID of the first key.
     * @param _keyId2 The ID of the second key.
     */
    function entangleFragments(uint256 _keyId1, uint256 _keyId2)
        external
        keyExists(_keyId1)
        keyExists(_keyId2)
        onlyKeyOwner(_keyId1)
        onlyKeyOwner(_keyId2)
    {
        require(_keyId1 != _keyId2, "Cannot entangle a key with itself");

        _addEntangledPartner(_keyId1, _keyId2);
        _addEntangledPartner(_keyId2, _keyId1);

        keyFragments[_keyId1].isEntangled = true;
        keyFragments[_keyId2].isEntangled = true;

        emit FragmentsEntangled(_keyId1, _keyId2);
    }

    /**
     * @dev Removes the bidirectional entanglement link between two key fragments.
     * Requires ownership of both keys by the sender.
     * @param _keyId1 The ID of the first key.
     * @param _keyId2 The ID of the second key.
     */
    function disentangleFragments(uint256 _keyId1, uint256 _keyId2)
        external
        keyExists(_keyId1)
        keyExists(_keyId2)
        onlyKeyOwner(_keyId1)
        onlyKeyOwner(_keyId2)
    {
        require(_keyId1 != _keyId2, "Invalid disentanglement pair");

        _removeEntangledPartner(_keyId1, _keyId2);
        _removeEntangledPartner(_keyId2, _keyId1);

        // isEntangled flag is updated inside _removeEntangledPartner

        emit FragmentsDisentangled(_keyId1, _keyId2);
    }

    /**
     * @dev Grants permission to an address to act as an "observer" and call `collapseState`
     * for a specific key fragment, in addition to the owner.
     * @param _keyId The ID of the key.
     * @param _observer The address to grant permission to.
     */
    function addAllowedObserver(uint256 _keyId, address _observer)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
    {
        allowedObservers[_keyId][_observer] = true;
        emit ObserverAdded(_keyId, _observer);
    }

    /**
     * @dev Revokes observer permission from an address for a specific key fragment.
     * @param _keyId The ID of the key.
     * @param _observer The address to revoke permission from.
     */
    function removeAllowedObserver(uint256 _keyId, address _observer)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
    {
        allowedObservers[_keyId][_observer] = false;
        emit ObserverRemoved(_keyId, _observer);
    }

     /**
      * @dev Sets the minimum time duration that must pass after a collapse
      * before this key fragment can be collapsed again by any observer.
      * @param _keyId The ID of the key.
      * @param _duration The cooldown duration in seconds.
      */
     function setCollapseCooldown(uint256 _keyId, uint256 _duration)
         external
         keyExists(_keyId)
         onlyKeyOwner(_keyId)
     {
         keyFragments[_keyId].collapseCooldownDuration = _duration;
         emit CollapseCooldownSet(_keyId, _duration);
     }

     /**
      * @dev Sets the duration after which a collapsed state *can* revert to superposition
      * if `triggerDecoherenceCheck` is called and the key is not locked.
      * @param _keyId The ID of the key.
      * @param _duration The decoherence duration in seconds. Set to 0 to disable.
      */
     function setDecoherenceDuration(uint256 _keyId, uint256 _duration)
         external
         keyExists(_keyId)
         onlyKeyOwner(_keyId)
     {
         keyFragments[_keyId].decoherenceDuration = _duration;
         emit DecoherenceDurationSet(_keyId, _duration);
     }

    /**
     * @dev Manually forces a key fragment back into a superposition state.
     * Resets the collapsed state index and updates status.
     * @param _keyId The ID of the key.
     */
    function enterSuperposition(uint256 _keyId)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
        notLocked(_keyId)
        whenCollapsed(_keyId) // Can only enter superposition if it was collapsed
    {
        KeyFragment storage key = keyFragments[_keyId];
        key.currentStateIndex = -1;
        key.isSuperposition = true;
        // lastCollapseTimestamp/Entropy are NOT reset here, they represent the *last* collapse event.
        // decoherence timer might start from the moment it enters superposition, or from last collapse.
        // Let's keep last collapse time as is, decoherence check uses that.

        emit StateEnteredSuperposition(_keyId);
    }

    /**
     * @dev "Measures" the key fragment using provided entropy, causing its superposition
     * to collapse into one definite state selected deterministically from its potential states.
     * Checks observer permissions, cooldowns, and locks.
     * Applies entanglement effects to linked fragments currently in superposition.
     * @param _keyId The ID of the key.
     * @param _entropy Input entropy (e.g., hash of some off-chain data, VRF randomness result)
     *                 used to determine the collapsed state.
     */
    function collapseState(uint256 _keyId, bytes32 _entropy)
        external
        keyExists(_keyId)
        onlyAllowedObserver(_keyId)
        whenSuperposition(_keyId)
        notLocked(_keyId)
    {
        KeyFragment storage key = keyFragments[_keyId];
        require(block.timestamp >= key.lastCollapseTimestamp + key.collapseCooldownDuration, "Collapse cooldown active");
        require(key.potentialStates.length > 0, "Cannot collapse state with no potential states");

        // Resolve the specific state index using the provided entropy
        uint256 selectedIndex = _resolveStateFromEntropy(_keyId, _entropy);

        // Collapse the state
        key.currentStateIndex = int256(selectedIndex);
        key.isSuperposition = false;
        key.lastCollapseTimestamp = block.timestamp;
        key.lastCollapseEntropy = _entropy;

        uint256 collapsedStateValue = key.potentialStates[selectedIndex];

        emit StateCollapsed(_keyId, collapsedStateValue, _entropy);

        // Apply entanglement effect to entangled partners
        if (key.isEntangled) {
             _applyEntanglementEffect(_keyId, collapsedStateValue);
        }
    }

    /**
     * @dev Temporarily locks the state of a key fragment, preventing `collapseState`
     * or `enterSuperposition` calls until the lock duration expires.
     * Useful to "freeze" a state for a period of observation or interaction.
     * Setting duration to 0 removes the lock immediately.
     * @param _keyId The ID of the key.
     * @param _duration The duration in seconds for which the state should be locked.
     */
    function lockStateForObservation(uint256 _keyId, uint256 _duration)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
    {
        keyFragments[_keyId].stateLockUntil = block.timestamp + _duration;
        if (_duration > 0) {
             emit StateLocked(_keyId, keyFragments[_keyId].stateLockUntil);
        } else {
             emit StateUnlocked(_keyId); // 0 duration effectively unlocks
        }
    }

    /**
     * @dev Removes any active observation lock on a key fragment immediately.
     * @param _keyId The ID of the key.
     */
    function unlockState(uint256 _keyId)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
    {
         // Only unlock if it is currently locked
         if (keyFragments[_keyId].stateLockUntil > block.timestamp) {
            keyFragments[_keyId].stateLockUntil = block.timestamp; // Set to now to unlock
            emit StateUnlocked(_keyId);
         }
    }

    /**
     * @dev Transfers ownership of a key fragment to a new address.
     * @param _keyId The ID of the key.
     * @param _newOwner The address to transfer ownership to.
     * Requires the new owner address not to be zero.
     */
    function transferKeyOwnership(uint256 _keyId, address _newOwner)
        external
        keyExists(_keyId)
        onlyKeyOwner(_keyId)
    {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = keyFragments[_keyId].owner;
        keyFragments[_keyId].owner = _newOwner;
        emit KeyOwnershipTransferred(_keyId, oldOwner, _newOwner);
    }

    /**
     * @dev Allows anyone to trigger a check for decoherence for a specific key.
     * If the key is collapsed, not locked, has a decoherence duration set,
     * and the duration has passed since the last collapse, it forces the key
     * back into superposition. This function is public to allow external keepers
     * or automated systems to manage decoherence.
     * @param _keyId The ID of the key.
     */
    function triggerDecoherenceCheck(uint256 _keyId)
        external
        keyExists(_keyId)
    {
        KeyFragment storage key = keyFragments[_keyId];

        // Check if eligible for decoherence
        if (!key.isSuperposition && // Must be collapsed
            block.timestamp >= key.stateLockUntil && // Must not be locked
            key.decoherenceDuration > 0 && // Must have a decoherence duration set
            block.timestamp >= key.lastCollapseTimestamp + key.decoherenceDuration // Duration must have passed
        ) {
            // Force decoherence: return to superposition
            key.currentStateIndex = -1;
            key.isSuperposition = true;
            // lastCollapseTimestamp remains as is, it marks the event that decayed

            emit StateEnteredSuperposition(_keyId);
        }
        // If conditions aren't met, function does nothing (no error).
    }


    // --- View Functions (Read Operations) ---

    /**
     * @dev Gets the current collapsed state value of a key fragment.
     * Returns the specific potential state value if collapsed, or 0 (or a specific indicator)
     * if in superposition. Using 0 for superposition might be ambiguous if 0 is a valid state.
     * Let's return type(uint256).max if in superposition to avoid ambiguity.
     * @param _keyId The ID of the key.
     * @return The collapsed state value, or type(uint256).max if in superposition.
     */
    function getCurrentState(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (uint256)
    {
        KeyFragment storage key = keyFragments[_keyId];
        if (key.isSuperposition) {
            return type(uint256).max; // Indicator for superposition
        } else {
            // Defensive check, though currentStateIndex should be valid if not superposition
            require(key.currentStateIndex >= 0 && uint256(key.currentStateIndex) < key.potentialStates.length, "Invalid collapsed state index");
            return key.potentialStates[uint256(key.currentStateIndex)];
        }
    }

    /**
     * @dev Gets the array of potential state configurations for a key fragment.
     * @param _keyId The ID of the key.
     * @return An array of uint256 representing the potential states.
     */
    function getPotentialStates(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (uint256[] memory)
    {
        return keyFragments[_keyId].potentialStates;
    }

    /**
     * @dev Gets the list of key IDs that this fragment is entangled with.
     * @param _keyId The ID of the key.
     * @return An array of uint256 representing entangled key IDs.
     */
    function getEntangledFragments(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (uint256[] memory)
    {
        return entangledPairs[_keyId];
    }

    /**
     * @dev Checks if an address is an allowed observer for a specific key fragment.
     * @param _keyId The ID of the key.
     * @param _observer The address to check.
     * @return True if the address is allowed to observe/collapse the key, false otherwise.
     */
    function isObserverAllowed(uint256 _keyId, address _observer)
        external
        view
        keyExists(_keyId)
        returns (bool)
    {
        return keyFragments[_keyId].owner == _observer || allowedObservers[_keyId][_observer];
    }

    /**
     * @dev Checks if the collapse cooldown period for a key fragment has passed.
     * @param _keyId The ID of the key.
     * @return True if the cooldown is over or not set, false otherwise.
     */
    function checkCollapseCooldown(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (bool)
    {
        KeyFragment storage key = keyFragments[_keyId];
        return block.timestamp >= key.lastCollapseTimestamp + key.collapseCooldownDuration;
    }

    /**
     * @dev Checks if a key fragment is currently entangled with any other fragment.
     * @param _keyId The ID of the key.
     * @return True if the key is entangled, false otherwise.
     */
    function isFragmentEntangled(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (bool)
    {
        return keyFragments[_keyId].isEntangled; // Directly use the flag for efficiency
    }

    /**
     * @dev Returns comprehensive details about a key fragment.
     * @param _keyId The ID of the key.
     * @return A tuple containing owner, initialState, potentialStates, currentStateIndex,
     *         isSuperposition, isEntangled, creationTimestamp, lastCollapseTimestamp,
     *         collapseCooldownDuration, decoherenceDuration, stateLockUntil.
     */
    function getKeyFragmentDetails(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (
            address owner,
            uint256 initialState,
            uint256[] memory potentialStates,
            int256 currentStateIndex,
            bool isSuperposition,
            bool isEntangled,
            uint256 creationTimestamp,
            uint256 lastCollapseTimestamp,
            uint256 collapseCooldownDuration,
            uint256 decoherenceDuration,
            uint256 stateLockUntil
        )
    {
        KeyFragment storage key = keyFragments[_keyId];
        return (
            key.owner,
            key.initialState,
            key.potentialStates,
            key.currentStateIndex,
            key.isSuperposition,
            key.isEntangled,
            key.creationTimestamp,
            key.lastCollapseTimestamp,
            key.collapseCooldownDuration,
            key.decoherenceDuration,
            key.stateLockUntil
        );
    }

    /**
     * @dev Gets information about the last state collapse for a key fragment.
     * @param _keyId The ID of the key.
     * @return A tuple containing the timestamp of the last collapse and the entropy used.
     */
    function getLastCollapseInfo(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (uint256 lastCollapseTimestamp, bytes32 lastCollapseEntropy)
    {
        KeyFragment storage key = keyFragments[_keyId];
        return (key.lastCollapseTimestamp, key.lastCollapseEntropy);
    }

    /**
     * @dev Gets the owner address of a key fragment.
     * @param _keyId The ID of the key.
     * @return The owner address.
     */
    function getKeyOwner(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (address)
    {
        return keyFragments[_keyId].owner;
    }

    /**
     * @dev Gets the total number of key fragments that have been created.
     * @return The total count of key fragments.
     */
    function getTotalFragments() external view returns (uint256) {
        return nextKeyId;
    }

    /**
     * @dev Checks if the key fragment's state is currently locked against changes.
     * @param _keyId The ID of the key.
     * @return True if the stateLockUntil timestamp is in the future, false otherwise.
     */
    function isStateLocked(uint256 _keyId)
        external
        view
        keyExists(_keyId)
        returns (bool)
    {
        return block.timestamp < keyFragments[_keyId].stateLockUntil;
    }
}
```