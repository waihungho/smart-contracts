Okay, let's design a smart contract inspired by concepts from quantum mechanics, specifically focusing on key or data access management. We'll use ideas like superposition, observation (measurement), entanglement, and even a form of "quantum erasure" as metaphors for complex, state-dependent access control.

This contract, `QuantumKeyManager`, won't perform actual quantum computations on the blockchain (which is impossible with current tech) but will model access rights based on states that behave *analogously* to quantum phenomena.

**Outline & Function Summary**

**Contract Name:** `QuantumKeyManager`

**Core Concept:** Manage access to virtual "Quantum Keys" or associated data pointers. Access depends on the key's "state", which can be in "superposition" (multiple potential states simultaneously) until "observed" (a transaction or query triggers state collapse based on defined policies and external conditions). Keys can be "entangled" meaning their states influence each other's observation outcomes. A complex "quantum erasure" protocol allows for irreversible removal under specific, multi-step conditions.

**Key Components:**

1.  **States:** Keys exist in different states (Superposition, StateA, StateB, etc.). Superposition is the initial unobserved state.
2.  **Policies:** Rules defined on-chain that dictate:
    *   How Superposition collapses upon Observation (based on internal/external conditions).
    *   How states can transition *after* observation.
    *   When "Quantum Erasure" is possible and how it progresses.
3.  **Conditions:** Abstract checks (e.g., reading oracle data, checking block number, verifying entangled key states, specific addresses) referenced by policies.
4.  **Entanglement:** Links between keys where the state of one can be a condition for the state transition/collapse of another.
5.  **Observation:** The process that collapses a key from Superposition to a definite state based on active policies and conditions.
6.  **Quantum Erasure:** A multi-step, potentially irreversible process to transition a key to a terminal state (like 'Corrupted' or 'Erased') making it inaccessible.

**Function Summary:**

1.  `constructor()`: Initializes the contract (sets admin, etc.).
2.  `registerCondition()`: Admin function to define a reusable condition type and parameters, mapping it to a unique hash.
3.  `unregisterCondition()`: Admin function to remove a condition definition.
4.  `setObservationCollapsePolicy()`: Admin function to define how a key in Superposition collapses based on a condition hash resolving true.
5.  `removeObservationCollapsePolicy()`: Admin function to remove an observation policy rule.
6.  `setControlledTransitionPolicy()`: Admin function to define how a key in a definite state can transition to another state, linked to a condition hash.
7.  `removeControlledTransitionPolicy()`: Admin function to remove a controlled transition policy rule.
8.  `setErasureEligibilityCondition()`: Admin function to define the condition required to *initiate* the erasure protocol for a key.
9.  `setErasureStepCondition()`: Admin function to define the condition required to advance to a specific step in the erasure protocol.
10. `createQuantumKey()`: Creates a new key, initially in Superposition, with associated data hash and manager.
11. `updateKeyDataHash()`: Manager function to update the off-chain data hash linked to a key.
12. `addEntanglementLink()`: Manager function to link two keys, establishing entanglement. Requires reciprocal linking.
13. `removeEntanglementLink()`: Manager function to break entanglement links.
14. `delegateKeyManagement()`: Allows a key's manager to delegate management rights to another address.
15. `revokeKeyManagement()`: Allows a key's manager (or contract admin) to revoke delegation.
16. `observeKey()`: The core function triggered by manager or authorized delegate. Attempts to collapse a key's Superposition state based on defined observation policies and the current state of conditions. Emits state change events.
17. `requestAccess()`: Combines observation (if needed) and checks if the *final* state grants access based on a predefined state mapping. Returns access status and the final state.
18. `checkCurrentAccess()`: Pure view function. Checks if a key has been observed and if its *current* definite state grants access. Does *not* trigger observation.
19. `simulateObservationResult()`: Pure view function. Predicts the outcome (collapsed state) if `observeKey` were called now, based on current conditions and policies, *without* changing state.
20. `triggerControlledStateTransition()`: Allows a manager (or via policy condition) to attempt a state transition *after* observation, based on `controlledTransitionPolicy` and evaluating the linked condition.
21. `initiateQuantumErasure()`: Attempts to start the multi-step erasure protocol for a key, checking the `erasureEligibilityCondition`.
22. `confirmErasureStep()`: Allows a manager (or via policy condition) to advance a key through a specific step in the erasure protocol, checking the `erasureStepCondition` for that step.
23. `cancelErasure()`: Allows a manager to halt the erasure protocol before completion.
24. `captureStateSnapshot()`: Manager function to explicitly save the current state and data hash of a key, creating a historical snapshot.
25. `revertToSnapshot()`: Manager function (potentially admin override/condition protected) to revert a key's state and data hash to a previously captured snapshot, subject to policy conditions (e.g., within a time window, or requiring specific authorization/condition check).
26. `getKeyDetails()`: View function to retrieve all details of a specific key.
27. `getEntangledKeys()`: View function to list keys entangled with a given key.
28. `getTotalKeyCount()`: View function for the total number of created keys.
29. `getConditionDefinition()`: View function to retrieve the parameters of a registered condition hash.
30. `getStateGrantsAccess()`: View function to check if a specific state number is configured to grant access.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumKeyManager
 * @dev A smart contract managing access to virtual "Quantum Keys" or associated data pointers.
 * Access control is based on a metaphorical quantum state model including superposition,
 * observation (measurement), entanglement, and policy-driven state transitions and erasure.
 * This contract simulates complex, state-dependent access logic on-chain, inspired by
 * quantum mechanics concepts, without performing actual quantum computations.
 *
 * Outline & Function Summary (See above summary for details)
 *
 * Key Concepts:
 * - States: Keys can be in Superposition (unobserved, initial) or definite states (StateA, StateB, etc.).
 * - Policies: Define how states change based on Conditions (Observation Collapse, Controlled Transition, Erasure).
 * - Conditions: Abstract checks (oracle data, block data, entangled state, etc.) evaluated on-chain.
 * - Entanglement: Linked keys influencing each other's state transitions/collapses.
 * - Observation: The process collapsing Superposition based on Policies and Conditions.
 * - Quantum Erasure: A multi-step, policy-controlled, potentially irreversible key removal process.
 */
contract QuantumKeyManager {

    // --- Errors ---
    error Unauthorized(address caller);
    error KeyDoesNotExist(uint256 keyId);
    error KeyNotManagedByCaller(uint256 keyId);
    error KeyAlreadyObserved(uint256 keyId);
    error KeyNotInSuperposition(uint256 keyId);
    error KeyAlreadyInSuperposition(uint256 keyId); // Should not happen after creation/revert
    error KeyAlreadyEntangled(uint256 keyId1, uint256 keyId2);
    error KeysNotEntangled(uint256 keyId1, uint256 keyId2);
    error ConditionAlreadyRegistered(bytes32 conditionHash);
    error ConditionNotRegistered(bytes32 conditionHash);
    error PolicyRuleDoesNotExist(bytes32 ruleHash); // Used for removing policies
    error InvalidState(uint8 state);
    error InvalidTargetState(uint8 fromState, uint8 toState);
    error ErasureNotInInitiatedState(uint256 keyId);
    error ErasureNotInitiated(uint256 keyId);
    error InvalidErasureStep(uint256 keyId, uint8 attemptedStep);
    error ConditionEvaluationFailed(bytes32 conditionHash); // Generic failure
    error RevertSnapshotNotFound(uint256 keyId, uint256 snapshotIndex);
    error RevertConditionNotMet(uint256 keyId);
    error CannotRevertObservedKey(uint256 keyId); // Maybe reversible under strict conditions? Let's disallow for simplicity here.


    // --- Enums ---
    // Key states (0 is Superposition, >0 are definite states, 255 is Corrupted/Erased)
    enum KeyState { Superposition, StateA, StateB, StateC, StateD, ErasedOrCorrupted } // Using enum for clarity, map to uint8 internally

    // Erasure protocol status
    enum ErasureStatus { Inactive, Initiated, Step1Confirmed, Step2Confirmed, Step3Confirmed, Completed }

    // Types of conditions that can be evaluated
    enum ConditionType {
        AlwaysTrue,             // Condition always evaluates to true
        CheckEntangledKeyState, // Checks if an entangled key is in a specific state
        CheckOracleValue,       // Placeholder: Check a value from a registered oracle (requires oracle integration)
        CheckBlockNumber,       // Checks if current block number meets a condition (e.g., >= target)
        CheckMsgSender,         // Checks if msg.sender is a specific address
        CheckErasureEligibility // Specific check for the erasure eligibility condition
    }

    // --- Structs ---
    struct QuantumKey {
        uint256 id;
        bytes32 dataHash; // Hash of off-chain data or actual key material
        uint8 currentState; // Using uint8 to allow more states than enum KeyState, 0 = Superposition
        bool isObserved; // True if state has collapsed from Superposition
        uint64 observationBlock; // Block number when observation occurred
        address manager; // Address authorized to manage this specific key
        mapping(uint256 => bool) entangledKeys; // IDs of keys this key is entangled with
        mapping(address => bool) observationDelegates; // Addresses allowed to call observeKey for this key

        // Erasure Protocol state for this key
        ErasureProtocol erasure;
    }

    struct ErasureProtocol {
        ErasureStatus status;
        uint8 currentStep; // Which step is currently being confirmed
        uint64 initiatedBlock;
        bytes32 eligibilityConditionHash; // Condition required to initiate
    }

    struct ConditionDefinition {
        ConditionType cType;
        bytes data; // Encodes parameters based on cType (e.g., target key ID, target state, block number, address, oracle ID + data hash)
    }

    struct StateSnapshot {
        uint64 blockNumber;
        uint8 state;
        bytes32 dataHash;
    }

    // --- State Variables ---
    address public admin; // Contract deployer or assigned admin
    uint256 private _nextKeyId;
    uint8 public constant STATE_SUPERPOSITION = 0;
    uint8 public constant STATE_ERASED_OR_CORRUPTED = 255;

    // Key Storage: id => QuantumKey
    mapping(uint256 => QuantumKey) private _keys;

    // Total number of keys
    uint256 private _keyCount;

    // Policy Definitions:
    // observationCollapseRules: Superposition state (0) => conditionHash => targetState (must be > 0)
    mapping(uint8 => mapping(bytes32 => uint8)) private _observationCollapseRules;

    // controlledTransitionPolicies: fromState (>0) => toState (>0) => conditionHash
    mapping(uint8 => mapping(uint8 => bytes32)) private _controlledTransitionPolicies;

    // conditionDefinitions: conditionHash => ConditionDefinition
    mapping(bytes32 => ConditionDefinition) private _conditionDefinitions;

    // erasureStepConditions: stepNumber => conditionHash (Step 0 is initiation, uses eligibility condition)
    mapping(uint8 => bytes32) private _erasureStepConditions;

    // Access Mapping: state => grantsAccess?
    mapping(uint8 => bool) private _stateGrantsAccess;

    // Snapshots: keyId => snapshotIndex => StateSnapshot
    mapping(uint256 => mapping(uint256 => StateSnapshot)) private _keySnapshots;
    mapping(uint256 => uint256) private _nextSnapshotIndex; // To track snapshot indices per key

    // --- Events ---
    event KeyCreated(uint256 indexed keyId, address indexed manager, bytes32 initialDataHash);
    event DataHashUpdated(uint256 indexed keyId, bytes32 newDataHash);
    event EntanglementAdded(uint256 indexed keyId1, uint256 indexed keyId2);
    event EntanglementRemoved(uint256 indexed keyId1, uint256 indexed keyId2);
    event KeyManagementDelegated(uint256 indexed keyId, address indexed oldManager, address indexed newManager);
    event ObservationDelegateAdded(uint256 indexed keyId, address indexed delegate);
    event ObservationDelegateRemoved(uint256 indexed keyId, address indexed delegate);
    event KeyObserved(uint256 indexed keyId, uint8 collapsedState, uint64 observationBlock);
    event StateTransitioned(uint256 indexed keyId, uint8 oldState, uint8 newState);
    event AccessRequested(uint256 indexed keyId, address indexed requester, bool granted, uint8 finalState);
    event ErasureInitiated(uint256 indexed keyId, uint64 initiatedBlock);
    event ErasureStepConfirmed(uint256 indexed keyId, uint8 step);
    event ErasureCanceled(uint256 indexed keyId);
    event ErasureCompleted(uint256 indexed keyId); // Key effectively erased/corrupted
    event ConditionRegistered(bytes32 indexed conditionHash, ConditionType cType);
    event ConditionUnregistered(bytes32 indexed conditionHash);
    event ObservationPolicySet(uint8 indexed fromState, bytes32 indexed conditionHash, uint8 indexed targetState);
    event ObservationPolicyRemoved(uint8 indexed fromState, bytes32 indexed conditionHash);
    event TransitionPolicySet(uint8 indexed fromState, uint8 indexed toState, bytes32 indexed conditionHash);
    event TransitionPolicyRemoved(uint8 indexed fromState, uint8 indexed toState);
    event ErasureEligibilitySet(bytes32 indexed conditionHash);
    event ErasureStepConditionSet(uint8 indexed step, bytes32 indexed conditionHash);
    event StateAccessGrantedConfigured(uint8 indexed state, bool grantsAccess);
    event StateSnapshotCaptured(uint256 indexed keyId, uint256 indexed snapshotIndex, uint64 blockNumber);
    event StateRevertedFromSnapshot(uint256 indexed keyId, uint256 indexed snapshotIndex, uint8 newState);


    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized(msg.sender);
        _;
    }

    modifier onlyManager(uint256 _keyId) {
        _checkKeyExists(_keyId);
        if (msg.sender != _keys[_keyId].manager && msg.sender != admin) revert KeyNotManagedByCaller(_keyId);
        _;
    }

     // Helper to check if key exists
    modifier keyExists(uint256 _keyId) {
        _checkKeyExists(_keyId);
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        _nextKeyId = 1; // Start key IDs from 1
        _keyCount = 0;

        // Configure default access: only certain observed states grant access
        _stateGrantsAccess[uint8(KeyState.StateA)] = true;
        _stateGrantsAccess[uint8(KeyState.StateB)] = true; // Example: StateA and StateB grant access
        // StateC, StateD, ErasedOrCorrupted (255) and Superposition (0) do not grant access by default.
    }

    // --- Admin Functions (Policy & Condition Management) ---

    /**
     * @dev Registers a reusable condition definition.
     * @param _conditionHash The unique hash identifier for this condition.
     * @param _cType The type of condition.
     * @param _data Encoded parameters specific to the condition type.
     */
    function registerCondition(bytes32 _conditionHash, ConditionType _cType, bytes calldata _data) external onlyAdmin {
        if (_conditionDefinitions[_conditionHash].cType != ConditionType.AlwaysTrue) { // Assuming AlwaysTrue is default(0) and indicates not set
            revert ConditionAlreadyRegistered(_conditionHash);
        }
        _conditionDefinitions[_conditionHash] = ConditionDefinition({
            cType: _cType,
            data: _data
        });
        emit ConditionRegistered(_conditionHash, _cType);
    }

    /**
     * @dev Unregisters a condition definition.
     * @param _conditionHash The hash identifier of the condition to unregister.
     */
    function unregisterCondition(bytes32 _conditionHash) external onlyAdmin {
         if (_conditionDefinitions[_conditionHash].cType == ConditionType.AlwaysTrue) {
            revert ConditionNotRegistered(_conditionHash);
        }
        // Consider implications if this condition is used in active policies.
        // For this example, we allow unregistering, making policies using it unevaluable.
        delete _conditionDefinitions[_conditionHash];
        emit ConditionUnregistered(_conditionHash);
    }

    /**
     * @dev Sets a policy rule for how Superposition collapses upon observation.
     * @param _conditionHash The condition hash that triggers this collapse rule.
     * @param _targetState The state (must be > 0 and < 255) the key collapses to if the condition is true.
     */
    function setObservationCollapsePolicy(bytes32 _conditionHash, uint8 _targetState) external onlyAdmin {
        if (_targetState == STATE_SUPERPOSITION || _targetState == STATE_ERASED_OR_CORRUPTED) {
             revert InvalidTargetState(STATE_SUPERPOSITION, _targetState);
        }
         if (_conditionDefinitions[_conditionHash].cType == ConditionType.AlwaysTrue) {
            revert ConditionNotRegistered(_conditionHash);
        }
        _observationCollapseRules[STATE_SUPERPOSITION][_conditionHash] = _targetState;
        // Note: Multiple conditions can map from Superposition. The first one to evaluate true in observeKey will trigger the collapse.
        emit ObservationPolicySet(STATE_SUPERPOSITION, _conditionHash, _targetState);
    }

    /**
     * @dev Removes an observation collapse policy rule.
     * @param _conditionHash The condition hash associated with the rule to remove.
     */
    function removeObservationCollapsePolicy(bytes32 _conditionHash) external onlyAdmin {
        // Check if a rule exists for this condition hash from Superposition state
        if (_observationCollapseRules[STATE_SUPERPOSITION][_conditionHash] == STATE_SUPERPOSITION) { // Assuming 0 is never a valid target state here
             // We can't easily check if the condition exists here without iterating.
             // A safer approach would be to pass the rule ID or require a separate mapping.
             // For simplicity, let's check if the target state is non-zero after lookup.
             uint8 target = _observationCollapseRules[STATE_SUPERPOSITION][_conditionHash];
             if (target == 0) revert PolicyRuleDoesNotExist(_conditionHash); // Rough check
        }
        delete _observationCollapseRules[STATE_SUPERPOSITION][_conditionHash];
        emit ObservationPolicyRemoved(STATE_SUPERPOSITION, _conditionHash);
    }

    /**
     * @dev Sets a policy rule for controlled state transitions *after* observation.
     * @param _fromState The starting state (> 0 and < 255).
     * @param _toState The target state (> 0 and < 255).
     * @param _conditionHash The condition hash that must be true to allow this transition.
     */
    function setControlledTransitionPolicy(uint8 _fromState, uint8 _toState, bytes32 _conditionHash) external onlyAdmin {
         if (_fromState == STATE_SUPERPOSITION || _fromState == STATE_ERASED_OR_CORRUPTED ||
             _toState == STATE_SUPERPOSITION || _toState == STATE_ERASED_OR_CORRUPTED) {
             revert InvalidTargetState(_fromState, _toState);
         }
          if (_conditionDefinitions[_conditionHash].cType == ConditionType.AlwaysTrue) {
            revert ConditionNotRegistered(_conditionHash);
        }
        _controlledTransitionPolicies[_fromState][_toState] = _conditionHash;
        emit TransitionPolicySet(_fromState, _toState, _conditionHash);
    }

    /**
     * @dev Removes a controlled state transition policy rule.
     * @param _fromState The starting state.
     * @param _toState The target state.
     */
    function removeControlledTransitionPolicy(uint8 _fromState, uint8 _toState) external onlyAdmin {
         if (_fromState == STATE_SUPERPOSITION || _fromState == STATE_ERASED_OR_CORRUPTED ||
             _toState == STATE_SUPERPOSITION || _toState == STATE_ERASED_OR_CORRUPTED) {
             revert InvalidTargetState(_fromState, _toState); // Use same error as setting
         }
        if (_controlledTransitionPolicies[_fromState][_toState] == bytes32(0)) {
             revert PolicyRuleDoesNotExist(bytes32(0)); // Indicate rule doesn't exist by hash 0
        }
        delete _controlledTransitionPolicies[_fromState][_toState];
        emit TransitionPolicyRemoved(_fromState, _toState);
    }

    /**
     * @dev Sets the condition required to initiate the Quantum Erasure protocol.
     * @param _conditionHash The condition hash.
     */
    function setErasureEligibilityCondition(bytes32 _conditionHash) external onlyAdmin {
         if (_conditionDefinitions[_conditionHash].cType == ConditionType.AlwaysTrue) {
            revert ConditionNotRegistered(_conditionHash);
        }
        // We'll store this per key when initiated, but this sets the *default* requirement to start
        _erasureStepConditions[0] = _conditionHash; // Step 0 represents initiation
        emit ErasureEligibilitySet(_conditionHash);
    }

    /**
     * @dev Sets the condition required to advance a specific step in the Erasure protocol.
     * @param _stepNumber The step number (1 to N).
     * @param _conditionHash The condition hash.
     */
    function setErasureStepCondition(uint8 _stepNumber, bytes32 _conditionHash) external onlyAdmin {
         if (_stepNumber == 0 || _stepNumber >= uint8(ErasureStatus.Completed)) {
             revert InvalidErasureStep(0, _stepNumber); // Use keyId 0 as placeholder
         }
         if (_conditionDefinitions[_conditionHash].cType == ConditionType.AlwaysTrue) {
            revert ConditionNotRegistered(_conditionHash);
        }
        _erasureStepConditions[_stepNumber] = _conditionHash;
        emit ErasureStepConditionSet(_stepNumber, _conditionHash);
    }

     /**
      * @dev Configures whether a specific state grants access upon check.
      * @param _state The state number.
      * @param _grantsAccess True if this state grants access, false otherwise.
      */
    function setStateGrantsAccess(uint8 _state, bool _grantsAccess) external onlyAdmin {
        // Allow setting access for Superposition (0) and Erased (255) just in case, though they likely won't grant access in typical configs.
        _stateGrantsAccess[_state] = _grantsAccess;
        emit StateAccessGrantedConfigured(_state, _grantsAccess);
    }

    // --- Key Management Functions ---

    /**
     * @dev Creates a new Quantum Key. Initially in Superposition.
     * @param _initialDataHash Hash referencing off-chain data or key material.
     * @return The ID of the newly created key.
     */
    function createQuantumKey(bytes32 _initialDataHash) external returns (uint256) {
        uint256 newKeyId = _nextKeyId++;
        _keys[newKeyId] = QuantumKey({
            id: newKeyId,
            dataHash: _initialDataHash,
            currentState: STATE_SUPERPOSITION,
            isObserved: false,
            observationBlock: 0,
            manager: msg.sender,
            entangledKeys: mapping(uint256 => bool),
            observationDelegates: mapping(address => bool),
            erasure: ErasureProtocol({
                status: ErasureStatus.Inactive,
                currentStep: 0,
                initiatedBlock: 0,
                eligibilityConditionHash: bytes32(0) // Will use the global default set by admin initially
            })
        });
        _keyCount++;
        emit KeyCreated(newKeyId, msg.sender, _initialDataHash);
        return newKeyId;
    }

    /**
     * @dev Updates the data hash associated with a key.
     * @param _keyId The ID of the key.
     * @param _newDataHash The new data hash.
     */
    function updateKeyDataHash(uint256 _keyId, bytes32 _newDataHash) external onlyManager(_keyId) keyExists(_keyId) {
        // Optionally add condition: only allowed if key is in a specific state, or not observed, etc.
        _keys[_keyId].dataHash = _newDataHash;
        emit DataHashUpdated(_keyId, _newDataHash);
    }

    /**
     * @dev Establishes entanglement between two keys. Requires manager permission for both keys.
     * Entanglement must be reciprocal.
     * @param _keyId1 The ID of the first key.
     * @param _keyId2 The ID of the second key.
     */
    function addEntanglementLink(uint256 _keyId1, uint256 _keyId2) external keyExists(_keyId1) keyExists(_keyId2) {
        if (_keyId1 == _keyId2) revert KeysNotEntangled(_keyId1, _keyId2); // Cannot entangle with self
        if (_keys[_keyId1].entangledKeys[_keyId2]) revert KeyAlreadyEntangled(_keyId1, _keyId2);

        // Check manager permission for both keys (caller must be manager of *both*)
        if (_keys[_keyId1].manager != msg.sender || _keys[_keyId2].manager != msg.sender) {
            revert Unauthorized(msg.sender); // Simplified: requires caller to manage both
        }

        _keys[_keyId1].entangledKeys[_keyId2] = true;
        _keys[_key2Id].entangledKeys[_keyId1] = true;
        emit EntanglementAdded(_keyId1, _keyId2);
    }

    /**
     * @dev Removes entanglement between two keys. Requires manager permission for both keys.
     * @param _keyId1 The ID of the first key.
     * @param _keyId2 The ID of the second key.
     */
    function removeEntanglementLink(uint256 _keyId1, uint256 _keyId2) external keyExists(_keyId1) keyExists(_keyId2) {
         if (_keyId1 == _keyId2) revert KeysNotEntangled(_keyId1, _keyId2);
         if (!_keys[_keyId1].entangledKeys[_keyId2]) revert KeysNotEntangled(_keyId1, _keyId2);

         // Check manager permission for both keys (caller must be manager of *both*)
        if (_keys[_keyId1].manager != msg.sender || _keys[_keyId2].manager != msg.sender) {
            revert Unauthorized(msg.sender); // Simplified: requires caller to manage both
        }

        delete _keys[_keyId1].entangledKeys[_keyId2];
        delete _keys[_key2Id].entangledKeys[_keyId1];
        emit EntanglementRemoved(_keyId1, _keyId2);
    }

    /**
     * @dev Delegates management rights for a specific key to another address.
     * @param _keyId The ID of the key.
     * @param _newManager The address to delegate management to.
     */
    function delegateKeyManagement(uint256 _keyId, address _newManager) external onlyManager(_keyId) keyExists(_keyId) {
         address oldManager = _keys[_keyId].manager;
         // Admin can also delegate management if they are not the key manager initially.
         // Check added in onlyManager.
        _keys[_keyId].manager = _newManager;
        emit KeyManagementDelegated(_keyId, oldManager, _newManager);
    }

    /**
     * @dev Revokes management delegation, returning management to the original creator or admin (if they delegated).
     * Simple version: Reverts manager to the contract admin. More complex: store original creator or previous manager.
     * Let's revert it to the contract admin for simplicity in this example.
     * @param _keyId The ID of the key.
     */
    function revokeKeyManagement(uint256 _keyId) external onlyManager(_keyId) keyExists(_keyId) {
         address oldManager = _keys[_keyId].manager;
         if (oldManager == admin) return; // Admin is already manager
         _keys[_keyId].manager = admin; // Revoke delegation, admin takes over
         emit KeyManagementDelegated(_keyId, oldManager, admin);
    }

    /**
     * @dev Allows a manager to delegate observation permission for a key to another address.
     * @param _keyId The ID of the key.
     * @param _delegate Address to grant observation permission.
     */
    function delegateObservationPermission(uint256 _keyId, address _delegate) external onlyManager(_keyId) keyExists(_keyId) {
        _keys[_keyId].observationDelegates[_delegate] = true;
        emit ObservationDelegateAdded(_keyId, _delegate);
    }

    /**
     * @dev Allows a manager to revoke observation permission for a key.
     * @param _keyId The ID of the key.
     * @param _delegate Address to revoke observation permission from.
     */
    function revokeObservationPermission(uint256 _keyId, address _delegate) external onlyManager(_keyId) keyExists(_keyId) {
        delete _keys[_keyId].observationDelegates[_delegate];
        emit ObservationDelegateRemoved(_keyId, _delegate);
    }


    // --- Quantum Interaction Functions ---

    /**
     * @dev Attempts to "observe" a key. If in Superposition, triggers state collapse based on policies.
     * Can only be called by the key's manager or an authorized observation delegate.
     * @param _keyId The ID of the key to observe.
     * @return The resulting state after observation (or current state if already observed).
     */
    function observeKey(uint256 _keyId) external keyExists(_keyId) returns (uint8) {
        QuantumKey storage key = _keys[_keyId];

        // Check authorization: manager, admin, or observation delegate
        if (msg.sender != key.manager && msg.sender != admin && !key.observationDelegates[msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        if (key.isObserved) {
            // Key already observed, nothing changes
            return key.currentState;
        }

        if (key.currentState != STATE_SUPERPOSITION) {
             // Should be redundant with isObserved check, but good practice
            revert KeyNotInSuperposition(_keyId);
        }

        uint8 collapsedState = STATE_ERASED_OR_CORRUPTED; // Default to corrupted if no rule matches

        // Evaluate observation collapse policies. Policies are checked in order of registration? No, mapping iteration order is not guaranteed.
        // We need to iterate through registered conditions that are part of observation policies.
        // This requires iterating through _observationCollapseRules[STATE_SUPERPOSITION] keys (condition hashes).
        // Iterating mappings is possible but gas-intensive for large numbers of policies.
        // For simplicity, let's assume a reasonable number of policies or a predefined order/priority could be added via policy data.
        // In this simplified example, we'll simulate finding a matching rule.
        // A robust implementation might require policies to be stored in an array or linked list for guaranteed order.

        bool conditionMet = false;
        bytes32 winningConditionHash = bytes32(0);

        // --- Simplified Policy Evaluation (Illustrative) ---
        // In a real scenario, you'd iterate through _observationCollapseRules[STATE_SUPERPOSITION].keys()
        // and call evaluateCondition for each. The first one that returns true wins.

        // Example: Hardcoded check for a hypothetical condition hash (replace with actual iteration)
        bytes32 exampleConditionHash1 = keccak256("ExampleCondition1"); // Example hash
        if (_observationCollapseRules[STATE_SUPERPOSITION][exampleConditionHash1] != STATE_SUPERPOSITION) { // Rule exists
             if (_evaluateCondition(exampleConditionHash1, _keyId)) {
                 collapsedState = _observationCollapseRules[STATE_SUPERPOSITION][exampleConditionHash1];
                 winningConditionHash = exampleConditionHash1;
                 conditionMet = true;
             }
        }

        // Add more example checks or implement mapping iteration here...
        // For loop over mapping keys is non-trivial/expensive. Consider alternative policy storage (e.g., array of structs).

        // --- End Simplified Policy Evaluation ---

        if (!conditionMet) {
            // If no condition met for a specific target state, the key collapses to the default corrupted state.
            // Alternatively, it could stay in superposition, but the 'isObserved' flag is crucial.
            // Let's enforce collapse upon observation call.
             collapsedState = STATE_ERASED_OR_CORRUPTED; // Explicitly collapse to corrupted if no rule matched
        }


        key.currentState = collapsedState;
        key.isObserved = true;
        key.observationBlock = uint64(block.number);

        emit KeyObserved(_keyId, collapsedState, key.observationBlock);
        // Optional: Emit event detailing which condition caused collapse (if applicable)
        // event KeyCollapsedByCondition(uint256 indexed keyId, bytes32 indexed conditionHash, uint8 resultingState);
        // if (conditionMet) emit KeyCollapsedByCondition(_keyId, winningConditionHash, collapsedState);

        return key.currentState;
    }

    /**
     * @dev Attempts to request access to the key.
     * If the key is in Superposition, it is first Observed. Then, access is checked based on the final state.
     * @param _keyId The ID of the key.
     * @return tuple (accessGranted, finalState)
     */
    function requestAccess(uint256 _keyId) external keyExists(_keyId) returns (bool, uint8) {
        QuantumKey storage key = _keys[_keyId];
        uint8 finalState = key.currentState;

        // Observe if necessary
        if (!key.isObserved) {
            // Call observeKey internally. Note: This will revert if msg.sender is not authorized to observe.
            finalState = observeKey(_keyId); // This modifies state and emits KeyObserved
        }

        // Check if the final state grants access
        bool granted = _stateGrantsAccess[finalState];

        emit AccessRequested(_keyId, msg.sender, granted, finalState);

        return (granted, finalState);
    }

    /**
     * @dev Pure view function to check if access is granted based on the key's *current* state.
     * Does NOT trigger observation.
     * @param _keyId The ID of the key.
     * @return tuple (accessGranted, currentState)
     */
    function checkCurrentAccess(uint256 _keyId) external view keyExists(_keyId) returns (bool, uint8) {
        QuantumKey storage key = _keys[_keyId];
        // Access is only possibly granted if observed and the state allows it.
        bool granted = key.isObserved && _stateGrantsAccess[key.currentState];
        return (granted, key.currentState);
    }

     /**
      * @dev Pure view function to simulate the outcome of an observation *without* changing state.
      * Useful for predicting collapse.
      * @param _keyId The ID of the key.
      * @return The state the key *would* collapse to if observeKey were called now. Returns current state if already observed.
      */
     function simulateObservationResult(uint256 _keyId) external view keyExists(_keyId) returns (uint8) {
         QuantumKey storage key = _keys[_keyId];

         if (key.isObserved) {
             return key.currentState; // Already observed, outcome is its current state
         }

         if (key.currentState != STATE_SUPERPOSITION) {
             // Should not happen for an unobserved key, but as a check
             return STATE_ERASED_OR_CORRUPTED; // Cannot simulate collapse from non-superposition if not observed
         }

        // --- Simplified Policy Evaluation Simulation (Illustrative) ---
        // Same logic as observeKey, but using a pure function to evaluate conditions where possible.
        // Some conditions (like CheckMsgSender) cannot be evaluated accurately in a pure view function.
        // This simulation is an *approximation* assuming external conditions are static or predictable.

         uint8 simulatedCollapsedState = STATE_ERASED_OR_CORRUPTED; // Default outcome

         bytes32 exampleConditionHash1 = keccak256("ExampleCondition1"); // Example hash
         if (_observationCollapseRules[STATE_SUPERPOSITION][exampleConditionHash1] != STATE_SUPERPOSITION) { // Rule exists
              // Note: _evaluateCondition is internal and not pure. We need a pure version or simulate its outcome.
              // For simulation, we rely on ConditionType and data that *can* be checked in pure mode.
              // Pure conditions: AlwaysTrue, CheckBlockNumber, CheckEntangledKeyState (if those key states are already observed).
              // Non-pure: CheckOracleValue, CheckMsgSender.
              // This simulation is thus limited or requires oracle mocks/known states.
              // Let's call a pure helper for evaluable conditions:
              if (_simulateConditionEvaluation(exampleConditionHash1, _keyId)) {
                  simulatedCollapsedState = _observationCollapseRules[STATE_SUPERPOSITION][exampleConditionHash1];
                  return simulatedCollapsedState; // Return the first matching rule's outcome
              }
         }
         // Implement simulation for other policies...

         // --- End Simplified Policy Evaluation Simulation ---

         return simulatedCollapsedState; // Return default if no rule condition was met (or could be simulated)
     }

     /**
      * @dev Allows a controlled state transition *after* a key has been observed.
      * Requires the linked policy condition to be true.
      * @param _keyId The ID of the key.
      * @param _targetState The state (> 0 and < 255) to transition to.
      */
     function triggerControlledStateTransition(uint256 _keyId, uint8 _targetState) external onlyManager(_keyId) keyExists(_keyId) {
         QuantumKey storage key = _keys[_keyId];

         if (!key.isObserved) {
             revert KeyNotInSuperposition(_keyId); // Can only transition after observation
         }
         if (key.currentState == STATE_ERASED_OR_CORRUPTED) {
             revert InvalidState(key.currentState); // Cannot transition from terminal state
         }
         if (_targetState == STATE_SUPERPOSITION || _targetState == STATE_ERASED_OR_CORRUPTED) {
             revert InvalidTargetState(key.currentState, _targetState);
         }
         if (key.currentState == _targetState) {
              // Already in target state, no-op
             return;
         }

         bytes32 conditionHash = _controlledTransitionPolicies[key.currentState][_targetState];

         if (conditionHash == bytes32(0)) {
              // No defined policy rule for this transition from this state
             revert PolicyRuleDoesNotExist(bytes32(0));
         }

         // Evaluate the condition required for this specific transition
         if (!_evaluateCondition(conditionHash, _keyId)) {
             revert ConditionEvaluationFailed(conditionHash);
         }

         uint8 oldState = key.currentState;
         key.currentState = _targetState;
         emit StateTransitioned(_keyId, oldState, key.currentState);
     }


    // --- Quantum Erasure Functions ---

    /**
     * @dev Attempts to initiate the Quantum Erasure protocol for a key.
     * Requires the global erasure eligibility condition to be set and evaluate true.
     * @param _keyId The ID of the key.
     */
    function initiateQuantumErasure(uint256 _keyId) external onlyManager(_keyId) keyExists(_keyId) {
        QuantumKey storage key = _keys[_keyId];

        if (key.erasure.status != ErasureStatus.Inactive) {
            revert ErasureNotInInitiatedState(_keyId); // Already active or completed
        }

        bytes32 eligibilityConditionHash = _erasureStepConditions[0]; // Step 0 is initiation condition

        if (eligibilityConditionHash == bytes32(0)) {
             // Admin has not set the eligibility condition
             revert ConditionNotRegistered(bytes32(0)); // Using 0 hash to indicate unset eligibility
        }

        // Evaluate the eligibility condition specifically for this key
        if (!_evaluateCondition(eligibilityConditionHash, _keyId)) {
             revert ConditionEvaluationFailed(eligibilityConditionHash);
        }

        // Set the specific eligibility condition hash used for this initiation on the key itself
        // (Allows admin to change global rule without affecting already initiated protocols)
        key.erasure.eligibilityConditionHash = eligibilityConditionHash;
        key.erasure.status = ErasureStatus.Initiated;
        key.erasure.currentStep = 1; // Protocol starts at step 1
        key.erasure.initiatedBlock = uint64(block.number);

        emit ErasureInitiated(_keyId, key.erasure.initiatedBlock);
    }

    /**
     * @dev Attempts to confirm the next step in the Quantum Erasure protocol for a key.
     * Requires the condition for the *current* step to evaluate true.
     * @param _keyId The ID of the key.
     */
    function confirmErasureStep(uint256 _keyId) external onlyManager(_keyId) keyExists(_keyId) {
        QuantumKey storage key = _keys[_keyId];

        if (key.erasure.status == ErasureStatus.Inactive || key.erasure.status == ErasureStatus.Completed) {
            revert ErasureNotInitiated(_keyId);
        }

        uint8 nextStep = key.erasure.currentStep;
        bytes32 stepConditionHash = _erasureStepConditions[nextStep]; // Get condition for the *next* step

        if (stepConditionHash == bytes32(0)) {
            // No condition set for this step, protocol cannot advance
             revert ConditionNotRegistered(bytes32(0)); // Indicate missing step condition
        }

        // Evaluate the condition required for this specific step
         if (!_evaluateCondition(stepConditionHash, _keyId)) {
             revert ConditionEvaluationFailed(stepConditionHash);
         }

        // Advance step and status
        key.erasure.currentStep++;
        // Update status enum based on currentStep. This assumes a fixed mapping or sequential steps.
        // Using a helper function or direct mapping for clarity.
        if (key.erasure.currentStep == 1) key.erasure.status = ErasureStatus.Initiated; // Already Initiated, stays Initiated
        else if (key.erasure.currentStep == 2) key.erasure.status = ErasureStatus.Step1Confirmed;
        else if (key.erasure.currentStep == 3) key.erasure.status = ErasureStatus.Step2Confirmed;
        else if (key.erasure.currentStep == 4) key.erasure.status = ErasureStatus.Step3Confirmed;
        // Add more steps here...

        emit ErasureStepConfirmed(_keyId, key.erasure.currentStep - 1); // Emit step that was just confirmed

        // Check if this step completes the protocol
        // Assuming step 4 completes the protocol for this example
        if (key.erasure.currentStep >= uint8(ErasureStatus.Completed) -1 ) { // Assuming Completed is the final status
             key.erasure.status = ErasureStatus.Completed;
             key.currentState = STATE_ERASED_OR_CORRUPTED;
             key.dataHash = bytes32(0); // Clear data hash upon erasure completion (irreversible)
             // Optionally clear entanglement links, delegates, etc.
             emit ErasureCompleted(_keyId);
        }
    }

    /**
     * @dev Allows the key manager to cancel the ongoing Erasure protocol.
     * @param _keyId The ID of the key.
     */
    function cancelErasure(uint256 _keyId) external onlyManager(_keyId) keyExists(_keyId) {
        QuantumKey storage key = _keys[_keyId];

        if (key.erasure.status == ErasureStatus.Inactive || key.erasure.status == ErasureStatus.Completed) {
            revert ErasureNotInitiated(_keyId);
        }

        key.erasure.status = ErasureStatus.Inactive;
        key.erasure.currentStep = 0;
        key.erasure.initiatedBlock = 0;
        key.erasure.eligibilityConditionHash = bytes32(0); // Reset initiated condition

        emit ErasureCanceled(_keyId);
    }

    // --- Snapshot Functions ---

     /**
      * @dev Captures a snapshot of the key's current state and data hash.
      * Can be used for potential future reversion (if policy allows).
      * @param _keyId The ID of the key.
      * @return The index of the captured snapshot.
      */
    function captureStateSnapshot(uint256 _keyId) external onlyManager(_keyId) keyExists(_keyId) returns (uint256) {
        QuantumKey storage key = _keys[_keyId];
        uint256 snapshotIndex = _nextSnapshotIndex[_keyId]++;
        _keySnapshots[_keyId][snapshotIndex] = StateSnapshot({
            blockNumber: uint64(block.number),
            state: key.currentState,
            dataHash: key.dataHash
        });
        emit StateSnapshotCaptured(_keyId, snapshotIndex, block.number);
        return snapshotIndex;
    }

     /**
      * @dev Reverts the key's state and data hash to a previously captured snapshot.
      * Requires a specific condition (set by admin) to be met.
      * @param _keyId The ID of the key.
      * @param _snapshotIndex The index of the snapshot to revert to.
      */
    function revertToSnapshot(uint256 _keyId, uint256 _snapshotIndex) external onlyManager(_keyId) keyExists(_keyId) {
        QuantumKey storage key = _keys[_keyId];

        if (_snapshotIndex >= _nextSnapshotIndex[_keyId]) {
            revert RevertSnapshotNotFound(_keyId, _snapshotIndex);
        }

        StateSnapshot storage snapshot = _keySnapshots[_keyId][_snapshotIndex];

        // Check policy/condition for allowing reversion
        // Let's define a *per-key* revert condition or a global one.
        // Option 1: Global admin-set condition `_revertConditionHash`
        bytes32 revertConditionHash = _erasureStepConditions[254]; // Arbitrary index for revert condition

        if (revertConditionHash == bytes32(0)) {
             revert ConditionNotRegistered(bytes32(0)); // Revert condition not set by admin
        }

        if (!_evaluateCondition(revertConditionHash, _keyId)) {
             revert RevertConditionNotMet(_keyId);
        }

        // Optional: Add checks like `require(block.number < snapshot.blockNumber + revertWindowBlocks)`

        // Revert state and data hash
        uint8 oldState = key.currentState;
        key.currentState = snapshot.state;
        key.dataHash = snapshot.dataHash;

        // Decide if reverting from observed state makes it unobserved.
        // Quantum analogy: Can you un-observe? Complex. Let's keep it observed for simplicity.
        // If state reverts to Superposition, should it be unobserved? This adds complexity.
        // Let's disallow reverting *to* Superposition if currently observed, or require a stricter policy.
        if (key.isObserved && snapshot.state == STATE_SUPERPOSITION) {
            revert CannotRevertObservedKey(_keyId);
        }
        // If reverting to an observed state, keep it observed. If reverting from observed to observed, keep observed.
        // If key wasn't observed, and snapshot is not superposition, it becomes observed.
        if (!key.isObserved && snapshot.state != STATE_SUPERPOSITION) {
             key.isObserved = true; // Reverting to a definite state implies observation
             key.observationBlock = uint64(block.number); // New observation block
        }
         // If key wasn't observed and snapshot is superposition, it remains unobserved.

        emit StateRevertedFromSnapshot(_keyId, _snapshotIndex, key.currentState);
    }


    // --- Batch Functions ---

    /**
     * @dev Requests access for multiple keys in one transaction.
     * Each key will be observed if in Superposition.
     * @param _keyIds An array of key IDs.
     * @return An array of tuples (accessGranted, finalState) for each key.
     */
    function batchRequestAccess(uint256[] calldata _keyIds) external returns (tuple(bool granted, uint8 finalState)[] memory) {
        uint256 numKeys = _keyIds.length;
        tuple(bool granted, uint8 finalState)[] memory results = new tuple(bool granted, uint8 finalState)[numKeys];

        for (uint i = 0; i < numKeys; i++) {
             // We need to check existence individually within the loop
             _checkKeyExists(_keyIds[i]);
            (results[i].granted, results[i].finalState) = requestAccess(_keyIds[i]); // Calls requestAccess for each key
        }

        return results;
    }

    // --- View Functions ---

    /**
     * @dev Gets the full details of a Quantum Key.
     * @param _keyId The ID of the key.
     * @return A tuple containing all key properties.
     */
    function getKeyDetails(uint256 _keyId) external view keyExists(_keyId) returns (
        uint256 id,
        bytes32 dataHash,
        uint8 currentState,
        bool isObserved,
        uint64 observationBlock,
        address manager,
        ErasureStatus erasureStatus,
        uint8 erasureCurrentStep
    ) {
        QuantumKey storage key = _keys[_keyId];
        return (
            key.id,
            key.dataHash,
            key.currentState,
            key.isObserved,
            key.observationBlock,
            key.manager,
            key.erasure.status,
            key.erasure.currentStep
        );
    }

    /**
     * @dev Gets the list of keys entangled with a given key.
     * @param _keyId The ID of the key.
     * @return An array of key IDs that _keyId is entangled with.
     */
    function getEntangledKeys(uint256 _keyId) external view keyExists(_keyId) returns (uint256[] memory) {
        QuantumKey storage key = _keys[_keyId];
        uint256[] memory entangled; // Placeholder, iterating mapping is needed

        // Iterating mapping in view function is possible but requires knowing all possible entangled keys.
        // A practical approach might store entangled keys in a dynamic array in the struct, but adds gas cost on writes.
        // For demonstration, we can return an empty array or limited view. A full graph requires off-chain traversal or different data structure.
        // Let's return a limited view by checking up to a certain range or requiring an external list of potential entangled keys.
        // Simpler: Just return an empty array or require off-chain lookup using `_keys[_keyId].entangledKeys[otherKeyId]` calls.
        // Let's return a dynamically sized array by iterating if the number of entangled keys is expected to be small per key.
        // This requires storing entangled key IDs in a separate array, adding complexity.

        // Simplified view: Cannot easily return dynamic array from mapping view.
        // Returning a placeholder or requiring individual checks is more feasible.
        // A common pattern is to provide a function `isEntangledWith(keyId1, keyId2)`
         return new uint256[](0); // Placeholder: Cannot efficiently list from mapping view
    }

    /**
     * @dev Gets the total number of keys created.
     * @return The total key count.
     */
    function getTotalKeyCount() external view returns (uint256) {
        return _keyCount;
    }

     /**
      * @dev Gets the definition of a registered condition.
      * @param _conditionHash The hash of the condition.
      * @return tuple (conditionType, data)
      */
     function getConditionDefinition(bytes32 _conditionHash) external view returns (ConditionType, bytes memory) {
         ConditionDefinition storage cond = _conditionDefinitions[_conditionHash];
          if (cond.cType == ConditionType.AlwaysTrue && _conditionHash != keccak256("AlwaysTrueConditionPlaceholder")) { // Check for unset conditions
            revert ConditionNotRegistered(_conditionHash);
         }
         return (cond.cType, cond.data);
     }

     /**
      * @dev Checks if a specific state number is configured to grant access.
      * @param _state The state number.
      * @return True if the state grants access, false otherwise.
      */
     function getStateGrantsAccess(uint8 _state) external view returns (bool) {
         return _stateGrantsAccess[_state];
     }

     /**
      * @dev Gets a specific historical snapshot for a key.
      * @param _keyId The ID of the key.
      * @param _snapshotIndex The index of the snapshot.
      * @return tuple (blockNumber, state, dataHash)
      */
     function getSnapshot(uint256 _keyId, uint256 _snapshotIndex) external view keyExists(_keyId) returns (uint64, uint8, bytes32) {
         if (_snapshotIndex >= _nextSnapshotIndex[_keyId]) {
             revert RevertSnapshotNotFound(_keyId, _snapshotIndex);
         }
         StateSnapshot storage snapshot = _keySnapshots[_keyId][_snapshotIndex];
         return (snapshot.blockNumber, snapshot.state, snapshot.dataHash);
     }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to check if a key exists.
     */
    function _checkKeyExists(uint256 _keyId) internal view {
        // Key ID 0 is unused
        if (_keyId == 0 || _keyId >= _nextKeyId) {
            revert KeyDoesNotExist(_keyId);
        }
    }

    /**
     * @dev Internal function to evaluate a registered condition.
     * This function contains the core "logic simulation" of quantum-inspired conditions.
     * @param _conditionHash The hash of the condition to evaluate.
     * @param _keyId The ID of the key context for the evaluation (e.g., for entangled checks).
     * @return True if the condition is met, false otherwise.
     */
    function _evaluateCondition(bytes32 _conditionHash, uint256 _keyId) internal view returns (bool) {
        ConditionDefinition storage cond = _conditionDefinitions[_conditionHash];

         if (cond.cType == ConditionType.AlwaysTrue && _conditionHash != keccak256("AlwaysTrueConditionPlaceholder")) {
            // If type is AlwaysTrue but hash doesn't match a known AlwaysTrue hash (or just check if data is empty?)
            // Assume hash(0) or empty data indicates not set for simplicity.
            // If a hash is registered but type is AlwaysTrue, it means it was explicitly set as always true.
         }


        // Evaluate based on condition type
        if (cond.cType == ConditionType.AlwaysTrue) {
            return true; // Simple case
        } else if (cond.cType == ConditionType.CheckEntangledKeyState) {
            // Data should contain the entangled key ID and the target state.
            // Example encoding: abi.encodePacked(entangledKeyId, targetState)
            if (cond.data.length < 32 + 1) revert ConditionEvaluationFailed(_conditionHash); // Not enough data
            (uint256 entangledKeyId, uint8 targetState) = abi.decode(cond.data, (uint256, uint8));

            // Check if entangled (optional: policy might check state of *any* key)
            if (!_keys[_keyId].entangledKeys[entangledKeyId]) {
                 // Or should this condition evaluate false if not entangled? Policy decision.
                 // Let's evaluate false if not entangled or target key doesn't exist/is not observed.
                return false;
            }
             _checkKeyExists(entangledKeyId); // Ensure the entangled key exists
            QuantumKey storage entangledKey = _keys[entangledKeyId];

            // The entangled key must be observed for its state to be definite and checked.
            return entangledKey.isObserved && entangledKey.currentState == targetState;

        } else if (cond.cType == ConditionType.CheckOracleValue) {
            // Placeholder: Requires integration with an oracle contract.
            // Data could encode oracle address and specific query parameters/expected value hash.
            // Example: bytes data = abi.encodePacked(oracleAddress, queryId, expectedValueHash);
            // Call `(bool success, bytes memory returnData) = oracleAddress.staticcall(abi.encodeWithSignature("getValue(bytes32)", queryId));`
            // Then compare keccak256(returnData) with expectedValueHash.
            // This is complex and needs trusted oracles. For this example, always return false.
            return false; // Oracle integration not implemented
        } else if (cond.cType == ConditionType.CheckBlockNumber) {
             // Data should contain comparison type (e.g., >=) and target block number.
             // Example encoding: abi.encodePacked(ComparisonType.GreaterThanOrEqual, targetBlock)
             if (cond.data.length < 1 + 8) revert ConditionEvaluationFailed(_conditionHash);
             // Placeholder: Decode comparison type and target block, then compare with block.number
             // uint8 comparisonType = uint8(cond.data[0]);
             // uint64 targetBlock; abi.decode(cond.data[1:], (uint64));
             // if (comparisonType == GreaterThanOrEqual) return block.number >= targetBlock; ...
             // For simplicity, let's just check if current block is >= a target block encoded as uint64.
             if (cond.data.length < 8) revert ConditionEvaluationFailed(_conditionHash);
             uint64 targetBlock = abi.decode(cond.data, (uint64));
             return block.number >= targetBlock;

        } else if (cond.cType == ConditionType.CheckMsgSender) {
            // Data should contain the required address.
            // Example encoding: abi.encodePacked(requiredAddress)
            if (cond.data.length < 20) revert ConditionEvaluationFailed(_conditionHash);
            address requiredAddress = abi.decode(cond.data, (address));
            return msg.sender == requiredAddress;

        } else if (cond.cType == ConditionType.CheckErasureEligibility) {
             // This condition type is specifically for the *initial* check to start erasure.
             // It might evaluate other internal factors like key age, observation state, etc.
             // Data could encode minimum age, required state, etc.
             // Example: abi.encodePacked(minKeyAgeBlocks, requiredKeyState)
             // For simplicity, let's check if the key has been observed AND is in StateC (arbitrary example)
             if (cond.data.length < 1) revert ConditionEvaluationFailed(_conditionHash); // Example data check
             uint8 requiredState = abi.decode(cond.data, (uint8)); // Example: require key is in this state
             return _keys[_keyId].isObserved && _keys[_keyId].currentState == requiredState;

        }
        // Add more condition types here...

        // If condition type is unknown or not handled, evaluate false.
        return false;
    }

     /**
      * @dev Internal pure function to simulate evaluating a condition where possible.
      * Limited by pure constraints (no `block.number`, `msg.sender`, cross-contract calls).
      * @param _conditionHash The hash of the condition.
      * @param _keyId The ID of the key context (only used for reading state of *this* key or entangled keys if already known/passed in).
      * @return True if the condition *can be simulated* and evaluates true, false otherwise or if simulation is not possible.
      */
     function _simulateConditionEvaluation(bytes32 _conditionHash, uint256 _keyId) internal view returns (bool) {
         ConditionDefinition storage cond = _conditionDefinitions[_conditionHash];

         if (cond.cType == ConditionType.AlwaysTrue) {
             return true;
         } else if (cond.cType == ConditionType.CheckEntangledKeyState) {
             // Simulation requires knowing the state of the entangled key without calling observeKey.
             // This is only possible if the entangled key is *already observed*.
             if (cond.data.length < 33) return false; // Not enough data for simulation check
             (uint256 entangledKeyId, uint8 targetState) = abi.decode(cond.data, (uint256, uint8));

              // Check if entangled key exists and is observed
             if (_keyId == 0 || _keyId >= _nextKeyId) return false; // Cannot check existence of key context
             if (entangledKeyId == 0 || entangledKeyId >= _nextKeyId) return false; // Cannot check existence of target key

             // Access state directly - requires entangledKey to be *already in state*
             // This simulation works only if the entangled key is not in superposition.
             // In a real scenario, this simulation is an estimate.
             // If the entangled key is in superposition, the simulation cannot definitively say if *this* condition will be true upon observation.
             // Let's only simulate if the entangled key is *already observed*.
             QuantumKey storage entangledKey = _keys[entangledKeyId]; // Accessing storage in view is okay
             return entangledKey.isObserved && entangledKey.currentState == targetState;


         } else if (cond.cType == ConditionType.CheckBlockNumber) {
             // Can compare block.number in a view function
             if (cond.data.length < 8) return false;
             uint64 targetBlock = abi.decode(cond.data, (uint64));
             return block.number >= targetBlock; // Simple greater than check simulation

         } else {
             // ConditionType.CheckOracleValue, ConditionType.CheckMsgSender, ConditionType.CheckErasureEligibility, etc.
             // cannot be reliably simulated in a pure view function without external data or msg.sender context.
             return false; // Cannot simulate
         }
     }
}
```