Okay, here is a Solidity smart contract called `QuantumLock`. It explores concepts inspired by quantum mechanics (superposition, measurement, entanglement, decoherence, delayed choice) applied to locking/unlocking access to data or actions. This is a *simulation* of these concepts using classical computing and blockchain state, not real quantum computing.

It avoids standard patterns like ERC-20/721, marketplaces, or simple timelocks. It focuses on complex state transitions and access logic based on "quantum-inspired" events.

---

**QuantumLock Smart Contract**

**Outline:**

1.  **Purpose:** Manage access to sensitive data (`lockedDataHash`) or trigger specific actions (`lockedActionId`) based on the "measured" state of a "quantum-inspired" entanglement pair.
2.  **Core Concepts:**
    *   **Entanglement Pair:** A conceptual link between a unique `key` and a dynamic `quantumState`.
    *   **Quantum State:** Exists in a simulated "superposition" (`Unmeasured`) until a "measurement" occurs.
    *   **Measurement:** An action (`performMeasurement`) that collapses the state into one of two classical outcomes (`MeasuredStateA` or `MeasuredStateB`) based on internal entropy sources at the time of measurement and parameters set during pair creation/modification.
    *   **Decoherence:** Over time (`decoherenceTimestamp`), the unmeasured state collapses passively to a fixed outcome (`Decohered`), making measurement impossible or irrelevant.
    *   **Delayed Choice:** The outcome of the measurement can be influenced by the time the measurement occurs relative to creation or other defined delays (`minMeasurementTimestamp`).
    *   **Key:** A unique `bytes32` identifier that is "entangled" with a specific quantum state pair. Ownership of the key grants the right to perform measurement and potentially unlock resources.
3.  **Locked Resources:** Each entanglement pair is associated with a `lockedDataHash` (e.g., a hash of a secret document) and/or a `lockedActionId` (representing a specific privileged operation).
4.  **Unlock Condition:** A parameter (`unlockConditionParameter`) determines which measured state (`StateA` or `StateB`) is considered the "unlocked" state for a specific pair.
5.  **Functionality:**
    *   Register new entanglement pairs.
    *   Manage key ownership.
    *   Perform the measurement to collapse the state.
    *   Retrieve the outcome of a measurement.
    *   Check the current state (Unmeasured, Measured, Decohered).
    *   Check if the pair is in the unlocked state.
    *   Trigger the associated locked action.
    *   Retrieve the associated locked data hash.
    *   Manage decoherence and measurement delays.
    *   Modify parameters that influence the measurement outcome distribution *before* measurement.
    *   Query pair information.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `registerEntanglementPair()`: Creates a new entanglement pair with associated data/action, key owner, decoherence delay, and minimum measurement delay.
3.  `performMeasurement()`: Triggers the state collapse for a given key. Calculates outcome based on various entropy sources and timing. Requires key ownership and valid state.
4.  `getMeasurementOutcome()`: Returns the measured state (`MeasuredStateA` or `MeasuredStateB`) after measurement.
5.  `getLockState()`: Returns the current state of the pair (Unmeasured, MeasuredStateA, MeasuredStateB, Decohered).
6.  `isUnlocked()`: Checks if the pair has been measured and its outcome matches the required unlock condition parameter.
7.  `triggerLockedAction()`: Executes the action associated with a key if the pair is in the unlocked state. Marks action as executed.
8.  `retrieveLockedDataHash()`: Returns the `lockedDataHash` if the pair is in the unlocked state.
9.  `simulateDecoherence()`: Allows marking a pair as Decohered if its decoherence time has passed.
10. `checkDecoherenceStatus()`: Returns true if the decoherence timestamp has passed for a key.
11. `getPairInfo()`: Returns the full details of an `EntanglementPair` struct.
12. `getKeyOwner()`: Returns the address that owns a specific key.
13. `transferKeyOwnership()`: Transfers ownership of a key to another address. Requires current ownership.
14. `revokeKey()`: Allows the key owner to revoke the key (sets owner to address(0)).
15. `setUnlockConditionParameter()`: Sets the parameter that determines which measured state is unlocked for a pair. Callable only before measurement.
16. `getUnlockConditionParameter()`: Returns the current unlock condition parameter for a pair.
17. `modifyEntanglementParameter()`: Allows influencing the potential outcome distribution *before* measurement by modifying an internal parameter used in the measurement calculation. Callable only before measurement.
18. `getEntanglementParameter()`: Returns the current entanglement parameter.
19. `setLockedDataHash()`: Updates the `lockedDataHash` for a pair (only possible before measurement).
20. `setLockedActionId()`: Updates the `lockedActionId` for a pair (only possible before measurement).
21. `setMinMeasurementDelay()`: Sets the minimum timestamp before measurement is allowed for a pair (only possible before measurement).
22. `getMinMeasurementDelay()`: Returns the minimum measurement timestamp for a pair.
23. `getTotalRegisteredPairs()`: Returns the total count of registered entanglement pairs.
24. `getKeyByIndex()`: Returns the key (bytes32) at a specific index in the list of registered keys. Allows iteration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title QuantumLock
/// @notice A smart contract simulating quantum-inspired concepts (superposition, measurement, entanglement, decoherence, delayed choice)
/// for managing access to data or actions via unique keys.

// --- Outline ---
// 1. Purpose: Manage access to data/actions based on quantum-inspired state.
// 2. Core Concepts: Entanglement Pair, Quantum State (Unmeasured, MeasuredA/B, Decohered), Measurement, Decoherence, Delayed Choice, Key.
// 3. Locked Resources: lockedDataHash, lockedActionId.
// 4. Unlock Condition: unlockConditionParameter determines which measured state is unlocked.
// 5. Functionality: Register pairs, manage keys, perform measurement, check state/unlock status, trigger actions, retrieve data hash, manage delays/parameters, query info.

// --- Function Summary ---
// 1. constructor() - Initialize owner.
// 2. registerEntanglementPair() - Create new pair.
// 3. performMeasurement() - Trigger state collapse.
// 4. getMeasurementOutcome() - Get measured state (A or B).
// 5. getLockState() - Get current state (Unmeasured, MeasuredA/B, Decohered).
// 6. isUnlocked() - Check if measured and matching unlock condition.
// 7. triggerLockedAction() - Execute action if unlocked.
// 8. retrieveLockedDataHash() - Get data hash if unlocked.
// 9. simulateDecoherence() - Manually mark as decohered if time passed.
// 10. checkDecoherenceStatus() - Check if decoherence time passed.
// 11. getPairInfo() - Get all pair details.
// 12. getKeyOwner() - Get key owner.
// 13. transferKeyOwnership() - Transfer key ownership.
// 14. revokeKey() - Revoke key ownership.
// 15. setUnlockConditionParameter() - Set which state is unlocked (before measurement).
// 16. getUnlockConditionParameter() - Get unlock parameter.
// 17. modifyEntanglementParameter() - Modify parameter influencing measurement (before measurement).
// 18. getEntanglementParameter() - Get entanglement parameter.
// 19. setLockedDataHash() - Update data hash (before measurement).
// 20. setLockedActionId() - Update action ID (before measurement).
// 21. setMinMeasurementDelay() - Set min measurement timestamp (before measurement).
// 22. getMinMeasurementDelay() - Get min measurement timestamp.
// 23. getTotalRegisteredPairs() - Get total pairs count.
// 24. getKeyByIndex() - Get key by index.

contract QuantumLock {

    // --- State Definitions ---

    enum LockState {
        Unmeasured,
        MeasuredStateA,
        MeasuredStateB,
        Decohered // State collapses passively over time
    }

    // Represents an entanglement pair tied to a unique key
    struct EntanglementPair {
        bytes32 key; // Unique identifier for this pair
        bytes32 lockedDataHash; // Hash of sensitive data locked by this pair
        uint256 lockedActionId; // Identifier for a potential action to trigger
        uint256 initialEntropy; // Entropy captured at creation
        uint64 creationTimestamp; // Timestamp of creation
        uint64 decoherenceTimestamp; // Timestamp after which state is Decohered if not measured
        uint64 minMeasurementTimestamp; // Earliest timestamp measurement is allowed

        LockState currentState; // Current state of the pair (Unmeasured, MeasuredA/B, Decohered)
        uint64 measurementTimestamp; // Timestamp when measurement occurred (if measured)

        // Parameters influencing the measurement outcome and unlock condition
        uint256 entanglementParameter; // Influences measurement outcome calculation (can be modified pre-measurement)
        uint256 unlockConditionParameter; // Determines which measured state is considered 'unlocked'
    }

    // --- State Variables ---

    address public owner; // Contract owner (for administrative functions, though minimized)

    // Mapping from key to its EntanglementPair details
    mapping(bytes32 => EntanglementPair) private entanglementPairs;

    // Mapping from key to its current owner address
    mapping(bytes32 => address) private keyOwners;

    // To keep track of registered keys and allow iteration
    bytes32[] public registeredKeys;
    mapping(bytes32 => bool) private isKeyRegistered; // Helper for existence check

    // To track if a locked action has been executed for a given ID
    mapping(uint256 => bool) private executedActions;

    // --- Events ---

    event PairRegistered(bytes32 indexed key, address indexed owner, uint64 creationTimestamp);
    event MeasurementPerformed(bytes32 indexed key, LockState indexed outcome, uint64 measurementTimestamp);
    event ActionTriggered(bytes32 indexed key, uint256 indexed actionId);
    event KeyTransferred(bytes32 indexed key, address indexed from, address indexed to);
    event KeyRevoked(bytes32 indexed key, address indexed owner);
    event ParametersUpdated(bytes32 indexed key, uint256 indexed entanglementParam, uint256 indexed unlockConditionParam);
    event StateDecohered(bytes32 indexed key, uint64 decoherenceTimestamp);

    // --- Modifiers ---

    modifier onlyKeyOwner(bytes32 _key) {
        require(keyOwners[_key] == msg.sender, "Not authorized: Caller is not the key owner");
        _;
    }

    modifier onlyBeforeMeasurement(bytes32 _key) {
        require(entanglementPairs[_key].currentState == LockState.Unmeasured, "Operation not allowed after measurement or decoherence");
        _;
    }

    modifier onlyAfterMeasurement(bytes32 _key) {
        require(entanglementPairs[_key].currentState == LockState.MeasuredStateA || entanglementPairs[_key].currentState == LockState.MeasuredStateB, "Operation requires measurement");
        _;
    }

    modifier onlyWhenUnlocked(bytes32 _key) {
        require(isUnlocked(_key), "Operation requires the lock to be in the unlocked state");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Core Functionality ---

    /// @notice Registers a new entanglement pair with a unique key, locking specified data and/or action.
    /// @param _key The unique identifier for this entanglement pair.
    /// @param _lockedDataHash The hash of the data associated with this lock.
    /// @param _lockedActionId An identifier for the action associated with this lock (0 if none).
    /// @param _keyOwner The address that will initially own this key.
    /// @param _decoherenceDelaySeconds The time in seconds after creation when the state decoheres if not measured.
    /// @param _minMeasurementDelaySeconds The minimum time in seconds after creation before measurement is allowed.
    /// @dev The initial quantum state entropy is derived from unpredictable blockchain data.
    function registerEntanglementPair(
        bytes32 _key,
        bytes32 _lockedDataHash,
        uint256 _lockedActionId,
        address _keyOwner,
        uint64 _decoherenceDelaySeconds,
        uint64 _minMeasurementDelaySeconds
    ) external {
        require(!isKeyRegistered[_key], "Key already registered");
        require(_keyOwner != address(0), "Key owner cannot be zero address");
        require(_decoherenceDelaySeconds > 0, "Decoherence delay must be positive");
        require(_minMeasurementDelaySeconds <= _decoherenceDelaySeconds, "Min measurement delay must be less than or equal to decoherence delay");

        uint64 currentTimestamp = uint64(block.timestamp);

        // Simulate initial quantum entropy from blockchain data
        // Using blockhash of the *previous* block is more resistant to miner manipulation within the same block
        uint256 initialEntropy = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), // Or current if block.number > 0, previous is safer
            currentTimestamp,
            msg.sender,
            tx.origin // Use tx.origin cautiously, but okay for novelty
        )));

        entanglementPairs[_key] = EntanglementPair({
            key: _key,
            lockedDataHash: _lockedDataHash,
            lockedActionId: _lockedActionId,
            initialEntropy: initialEntropy,
            creationTimestamp: currentTimestamp,
            decoherenceTimestamp: currentTimestamp + _decoherenceDelaySeconds,
            minMeasurementTimestamp: currentTimestamp + _minMeasurementDelaySeconds,
            currentState: LockState.Unmeasured,
            measurementTimestamp: 0, // Not measured yet
            entanglementParameter: 0, // Default, can be modified later
            unlockConditionParameter: 1 // Default: StateB is unlocked (can be modified)
        });

        keyOwners[_key] = _keyOwner;
        registeredKeys.push(_key);
        isKeyRegistered[_key] = true;

        emit PairRegistered(_key, _keyOwner, currentTimestamp);
    }

    /// @notice Performs the "measurement" on an entanglement pair, collapsing its state.
    /// @param _key The key of the pair to measure.
    /// @dev The outcome is determined by a combination of initial entropy, current entropy sources,
    /// timing relative to decoherence/min delay, and the entanglement parameter.
    /// Requires key ownership and the state to be Unmeasured and past the minimum measurement delay.
    function performMeasurement(bytes32 _key) external onlyKeyOwner(_key) onlyBeforeMeasurement(_key) {
        EntanglementPair storage pair = entanglementPairs[_key];
        uint64 currentTimestamp = uint64(block.timestamp);

        require(currentTimestamp >= pair.minMeasurementTimestamp, "Measurement is not allowed yet (delayed choice simulation)");
        require(currentTimestamp < pair.decoherenceTimestamp, "Cannot measure, state has decohered");

        // Simulate measurement entropy from current blockchain data
        uint256 measurementEntropy = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), // Or current if block.number > 0
            currentTimestamp,
            msg.sender,
            pair.key, // Include the key itself in the entropy calculation
            pair.initialEntropy, // Initial entropy also influences outcome
            pair.entanglementParameter // Entanglement parameter also influences outcome
        )));

        // --- Quantum-inspired outcome simulation logic ---
        // This is a simplification. The entanglementParameter and timing influence the outcome distribution.
        // Example: If entanglementParameter is high, maybe it biases towards StateA.
        // The modulo operator combined with a dynamic threshold based on parameters provides a probabilistic element.
        uint256 combinedEntropy = pair.initialEntropy ^ measurementEntropy ^ pair.entanglementParameter;
        uint256 outcomeValue = uint256(keccak256(abi.encodePacked(combinedEntropy, currentTimestamp)));

        // Simple bias simulation: Higher entanglementParameter shifts the threshold
        uint256 biasThreshold = (type(uint256).max / 2) + (pair.entanglementParameter * 1e6); // Example bias

        if (outcomeValue < biasThreshold) {
             pair.currentState = LockState.MeasuredStateA;
        } else {
             pair.currentState = LockState.MeasuredStateB;
        }
        // --- End outcome simulation logic ---

        pair.measurementTimestamp = currentTimestamp;

        emit MeasurementPerformed(_key, pair.currentState, currentTimestamp);
    }

    /// @notice Gets the outcome state after measurement.
    /// @param _key The key of the pair.
    /// @return The measured state (StateA or StateB). Reverts if not measured or decohered.
    function getMeasurementOutcome(bytes32 _key) external view onlyAfterMeasurement(_key) returns (LockState) {
        // This modifier ensures it's only callable if state is MeasuredStateA or MeasuredStateB
        return entanglementPairs[_key].currentState;
    }

    /// @notice Gets the current state of the entanglement pair.
    /// @param _key The key of the pair.
    /// @return The LockState (Unmeasured, MeasuredStateA, MeasuredStateB, Decohered).
    function getLockState(bytes32 _key) public view returns (LockState) {
         // Check decoherence status first if still unmeasured
        EntanglementPair storage pair = entanglementPairs[_key];
        if (pair.currentState == LockState.Unmeasured && uint64(block.timestamp) >= pair.decoherenceTimestamp) {
             return LockState.Decohered; // State is logically decohered, even if storage isn't updated yet
        }
        return pair.currentState;
    }


    /// @notice Checks if the entanglement pair is in the unlocked state.
    /// @param _key The key of the pair.
    /// @return True if the state is measured AND matches the unlock condition parameter. False otherwise.
    function isUnlocked(bytes32 _key) public view returns (bool) {
        LockState currentState = getLockState(_key); // Use getter to account for potential decoherence
        uint256 unlockParam = entanglementPairs[_key].unlockConditionParameter;

        if (currentState == LockState.MeasuredStateA && unlockParam == 0) {
            return true; // Example: unlockParam 0 means StateA is unlocked
        } else if (currentState == LockState.MeasuredStateB && unlockParam == 1) {
            return true; // Example: unlockParam 1 means StateB is unlocked
        }
        // Add more conditions based on unlockParam if needed
        return false;
    }

    /// @notice Attempts to trigger the locked action associated with the key.
    /// @param _key The key of the pair.
    /// @dev Requires the pair to be in the unlocked state and the action not already executed.
    /// This is a placeholder for complex action execution (e.g., delegatecall, state changes).
    function triggerLockedAction(bytes32 _key) external onlyWhenUnlocked(_key) onlyKeyOwner(_key) {
        EntanglementPair storage pair = entanglementPairs[_key];
        uint256 actionId = pair.lockedActionId;

        require(actionId != 0, "No action is associated with this key");
        require(!executedActions[actionId], "Action has already been executed for this ID");

        // --- Placeholder for actual action execution logic ---
        // In a real contract, this would involve calling another contract,
        // changing significant state, minting tokens, etc.
        // For this example, we just mark it as executed.
        executedActions[actionId] = true;
        // --- End Placeholder ---

        emit ActionTriggered(_key, actionId);
    }

    /// @notice Retrieves the locked data hash associated with the key.
    /// @param _key The key of the pair.
    /// @return The locked data hash.
    /// @dev Requires the pair to be in the unlocked state.
    function retrieveLockedDataHash(bytes32 _key) external view onlyWhenUnlocked(_key) returns (bytes32) {
        return entanglementPairs[_key].lockedDataHash;
    }

    /// @notice Allows anyone to explicitly mark a pair as Decohered if its time has passed.
    /// @param _key The key of the pair.
    /// @dev State must be Unmeasured and decoherence timestamp must have passed.
    function simulateDecoherence(bytes32 _key) external {
        EntanglementPair storage pair = entanglementPairs[_key];
        require(pair.currentState == LockState.Unmeasured, "State is not Unmeasured");
        require(uint64(block.timestamp) >= pair.decoherenceTimestamp, "Decoherence time has not passed yet");

        pair.currentState = LockState.Decohered;
        emit StateDecohered(_key, pair.decoherenceTimestamp);
    }

    /// @notice Checks if the decoherence timestamp has passed for a given key.
    /// @param _key The key of the pair.
    /// @return True if current block.timestamp is >= decoherenceTimestamp, false otherwise.
    function checkDecoherenceStatus(bytes32 _key) external view returns (bool) {
        return uint64(block.timestamp) >= entanglementPairs[_key].decoherenceTimestamp;
    }

    // --- Key Management ---

    /// @notice Gets the owner of a specific key.
    /// @param _key The key to check.
    /// @return The address of the key owner. Returns address(0) if key not registered or revoked.
    function getKeyOwner(bytes32 _key) public view returns (address) {
        return keyOwners[_key];
    }

    /// @notice Transfers ownership of a key to another address.
    /// @param _key The key to transfer.
    /// @param _newOwner The address to transfer ownership to.
    /// @dev Requires caller to be the current owner of the key.
    function transferKeyOwnership(bytes32 _key, address _newOwner) external onlyKeyOwner(_key) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = keyOwners[_key];
        keyOwners[_key] = _newOwner;
        emit KeyTransferred(_key, oldOwner, _newOwner);
    }

    /// @notice Revokes ownership of a key.
    /// @param _key The key to revoke.
    /// @dev Requires caller to be the current owner of the key. Sets owner to address(0).
    function revokeKey(bytes32 _key) external onlyKeyOwner(_key) {
        address oldOwner = keyOwners[_key];
        keyOwners[_key] = address(0); // Revoke by setting to zero address
        emit KeyRevoked(_key, oldOwner);
    }

    // --- Parameter Management (Before Measurement) ---

    /// @notice Sets the parameter that defines which measured state corresponds to 'unlocked'.
    /// @param _key The key of the pair.
    /// @param _conditionParam The parameter (e.g., 0 for StateA, 1 for StateB).
    /// @dev Can only be called before the pair's state has been measured or decohered. Requires key ownership.
    function setUnlockConditionParameter(bytes32 _key, uint256 _conditionParam) external onlyKeyOwner(_key) onlyBeforeMeasurement(_key) {
        entanglementPairs[_key].unlockConditionParameter = _conditionParam;
        // Emit a general parameter update event
        emit ParametersUpdated(_key, entanglementPairs[_key].entanglementParameter, _conditionParam);
    }

     /// @notice Gets the current unlock condition parameter for a pair.
     /// @param _key The key of the pair.
     /// @return The unlock condition parameter.
     function getUnlockConditionParameter(bytes32 _key) public view returns (uint256) {
         return entanglementPairs[_key].unlockConditionParameter;
     }


    /// @notice Modifies the entanglement parameter which influences the measurement outcome distribution.
    /// @param _key The key of the pair.
    /// @param _newParameter The new value for the entanglement parameter.
    /// @dev Can only be called before the pair's state has been measured or decohered. Requires key ownership.
    function modifyEntanglementParameter(bytes32 _key, uint256 _newParameter) external onlyKeyOwner(_key) onlyBeforeMeasurement(_key) {
        entanglementPairs[_key].entanglementParameter = _newParameter;
         // Emit a general parameter update event
        emit ParametersUpdated(_key, _newParameter, entanglementPairs[_key].unlockConditionParameter);
    }

    /// @notice Gets the current entanglement parameter for a pair.
    /// @param _key The key of the pair.
    /// @return The entanglement parameter.
    function getEntanglementParameter(bytes32 _key) public view returns (uint256) {
        return entanglementPairs[_key].entanglementParameter;
    }


    /// @notice Updates the locked data hash for a pair.
    /// @param _key The key of the pair.
    /// @param _newDataHash The new data hash.
    /// @dev Can only be called before measurement. Requires key ownership.
    function setLockedDataHash(bytes32 _key, bytes32 _newDataHash) external onlyKeyOwner(_key) onlyBeforeMeasurement(_key) {
        entanglementPairs[_key].lockedDataHash = _newDataHash;
    }

    /// @notice Updates the locked action ID for a pair.
    /// @param _key The key of the pair.
    /// @param _newActionId The new action ID.
     /// @dev Can only be called before measurement. Requires key ownership.
    function setLockedActionId(bytes32 _key, uint256 _newActionId) external onlyKeyOwner(_key) onlyBeforeMeasurement(_key) {
        entanglementPairs[_key].lockedActionId = _newActionId;
    }

    /// @notice Sets the minimum timestamp before measurement is allowed for a pair.
    /// @param _key The key of the pair.
    /// @param _delay The minimum delay in seconds from creation timestamp.
    /// @dev Can only be called before measurement. Requires key ownership. Cannot set delay past decoherence.
    function setMinMeasurementDelay(bytes32 _key, uint64 _delay) external onlyKeyOwner(_key) onlyBeforeMeasurement(_key) {
        EntanglementPair storage pair = entanglementPairs[_key];
        uint64 newMinTimestamp = pair.creationTimestamp + _delay;
        require(newMinTimestamp <= pair.decoherenceTimestamp, "Minimum measurement timestamp cannot be past decoherence time");
        pair.minMeasurementTimestamp = newMinTimestamp;
    }

     /// @notice Gets the minimum measurement timestamp for a pair.
     /// @param _key The key of the pair.
     /// @return The minimum measurement timestamp.
     function getMinMeasurementDelay(bytes32 _key) public view returns (uint64) {
         return entanglementPairs[_key].minMeasurementTimestamp;
     }

    // --- Query Functions ---

    /// @notice Gets all information about an entanglement pair.
    /// @param _key The key of the pair.
    /// @return The EntanglementPair struct details.
    function getPairInfo(bytes32 _key) external view returns (EntanglementPair memory) {
        // Need to return memory copy as storage reference can't cross external boundary
        // Also, need to check if key exists first in a production contract
        EntanglementPair storage pair = entanglementPairs[_key];
         // Note: currentState returned here might not reflect passive decoherence yet.
         // Use getLockState for active check.
        return pair;
    }

    /// @notice Returns the total number of registered entanglement pairs.
    function getTotalRegisteredPairs() external view returns (uint256) {
        return registeredKeys.length;
    }

    /// @notice Returns a registered key by its index in the registration order.
    /// @param _index The index of the key.
    /// @return The key (bytes32).
    /// @dev This allows iterating through all registered keys.
    function getKeyByIndex(uint256 _index) external view returns (bytes32) {
        require(_index < registeredKeys.length, "Index out of bounds");
        return registeredKeys[_index];
    }
}
```