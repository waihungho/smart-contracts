Okay, here is a smart contract that aims for creativity, advanced concepts, and a significant number of functions (>20) without directly duplicating common open-source patterns. It simulates a system of "Quantum Entangled Storage Units" (Quanta) where data hashes are linked and their accessibility/state depends on a simulated "entanglement state" that can be manipulated and 'measured'.

**Concept:**

The contract manages abstract data units called "Quanta". Each Quanta holds a cryptographic hash representing some external data. These Quanta can be linked ("entangled") via shared identifiers. The state of each Quanta progresses through defined phases (e.g., `Entangled`, `Decohered`, `Collapsed`). Access to information or derived results ("measurement") is conditional on the Quanta's state and potentially external factors or proofs. The contract includes roles for managing these states and entanglement links.

---

**Outline:**

1.  **SPDX License Identifier**
2.  **Pragma Version**
3.  **Imports (Implicit: No external imports needed for the core logic)**
4.  **Contract Definition**
5.  **Roles Definition (Constants)**
6.  **Entanglement State Enum**
7.  **Structs**
    *   `QuantaDetails`: Holds data hash, entanglement ID, creation timestamp, last state change timestamp, current state, and potentially a measurement condition/result.
8.  **State Variables**
    *   Owner address
    *   Mapping for roles (`address => bytes32 => bool`)
    *   Mapping for Quanta details (`uint256 => QuantaDetails`)
    *   Mapping for tracking next Quanta ID (`uint256`)
    *   Mapping for measurement conditions (`uint256 => bytes32`)
    *   Mapping for measurement results (`uint256 => bytes32`)
9.  **Events**
    *   `QuantaAdded`
    *   `QuantaUpdated`
    *   `QuantaRemoved`
    *   `StateChanged`
    *   `Entangled`
    *   `Decoupled`
    *   `MeasurementPerformed`
    *   `RoleGranted`
    *   `RoleRevoked`
    *   `OwnershipTransferred`
10. **Modifiers**
    *   `onlyOwner`
    *   `hasRole`
    *   `isQuantaValid`
11. **Constructor**
12. **Owner & Role Management Functions** (6 functions)
    *   `transferOwnership`
    *   `addRole`
    *   `removeRole`
    *   `isOwner` (view)
    *   `hasRole` (view)
    *   `renounceOwnership`
13. **Quanta Management Functions** (5 functions)
    *   `addQuanta`
    *   `updateQuantaHash`
    *   `removeQuanta`
    *   `getQuantaCount` (view)
    *   `getQuantaDetails` (view)
14. **Entanglement & State Manipulation Functions** (9 functions)
    *   `entangleQuantaPair`
    *   `decoupleQuantaPair`
    *   `setQuantaState` (restricted)
    *   `attemptDecoherence` (condition-based state change)
    *   `performMeasurement` (condition-based state change, potentially calculates/reveals result)
    *   `setMeasurementCondition`
    *   `clearMeasurementCondition`
    *   `verifyEntanglementLink` (view)
    *   `batchSetStates` (utility)
15. **State Information & Access Functions** (5 functions)
    *   `getQuantaState` (view)
    *   `canPerformMeasurement` (view)
    *   `isQuantaEntangledWith` (view)
    *   `getMeasurementResult` (view)
    *   `getQuantaTimestamp` (view)
16. **Batch Operations (Optional, but adds to function count)** (2 functions)
    *   `batchAddQuanta`
    *   `batchSetMeasurementConditions`

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets the owner.
2.  `transferOwnership(address newOwner)`: Transfers ownership of the contract.
3.  `addRole(address account, bytes32 role)`: Grants a specific role (e.g., KEY_MANAGER) to an address.
4.  `removeRole(address account, bytes32 role)`: Revokes a specific role from an address.
5.  `isOwner(address account) view`: Checks if an address is the contract owner.
6.  `hasRole(address account, bytes32 role) view`: Checks if an address has a specific role.
7.  `renounceOwnership()`: Relinquishes ownership (cannot be undone).
8.  `addQuanta(bytes32 dataHash, bytes32 initialEntanglementID) returns (uint256)`: Creates a new Quanta unit, assigns an ID, stores the hash, and sets initial state/entanglement.
9.  `updateQuantaHash(uint256 quantaId, bytes32 newDataHash)`: Updates the data hash for an existing Quanta (restricted access).
10. `removeQuanta(uint256 quantaId)`: Removes a Quanta unit (restricted, perhaps state-dependent).
11. `getQuantaCount() view returns (uint256)`: Returns the total number of Quanta added.
12. `getQuantaDetails(uint256 quantaId) view returns (bytes32, bytes32, uint256, uint256, EntanglementState)`: Retrieves comprehensive details about a Quanta.
13. `entangleQuantaPair(uint256 quantaId1, uint256 quantaId2, bytes32 entanglementID)`: Links two Quanta units using a shared entanglement ID (restricted, state transition).
14. `decoupleQuantaPair(uint256 quantaId1, uint256 quantaId2)`: Breaks the entanglement link between two Quanta (restricted, state transition).
15. `setQuantaState(uint256 quantaId, EntanglementState newState)`: Directly sets the state of a Quanta (highly restricted, for admin/manager use).
16. `attemptDecoherence(uint256 quantaId)`: Attempts to move a Quanta from `Entangled` to `Decohered` state based on internal rules (e.g., time elapsed, maybe an external condition check).
17. `performMeasurement(uint256 quantaId, bytes32 measurementProof)`: Attempts to move a Quanta from `Decohered` to `Collapsed` state. Requires meeting a predefined measurement condition and potentially a cryptographic proof. A successful measurement stores a result.
18. `setMeasurementCondition(uint256 quantaId, bytes32 conditionHash)`: Sets a hash representing a condition that must be met to perform measurement on a Quanta (restricted access).
19. `clearMeasurementCondition(uint256 quantaId)`: Removes the measurement condition for a Quanta (restricted access).
20. `verifyEntanglementLink(uint256 quantaId1, uint256 quantaId2, bytes32 potentialEntanglementID) view returns (bool)`: Checks if two Quanta share a specific entanglement ID.
21. `batchSetStates(uint256[] calldata quantaIds, EntanglementState[] calldata newStates)`: Sets the state for multiple Quanta in one transaction (restricted, batch utility).
22. `getQuantaState(uint256 quantaId) view returns (EntanglementState)`: Returns the current state of a Quanta.
23. `canPerformMeasurement(uint256 quantaId) view returns (bool)`: Checks if a Quanta is in the `Decohered` state and has a measurement condition set.
24. `isQuantaEntangledWith(uint256 quantaId1, uint256 quantaId2) view returns (bool)`: Checks if two specific Quanta units are currently linked by *any* shared entanglement ID.
25. `getMeasurementResult(uint256 quantaId) view returns (bytes32)`: Retrieves the stored measurement result for a `Collapsed` Quanta (returns zero bytes if not collapsed or no result).
26. `getQuantaTimestamp(uint256 quantaId) view returns (uint256 creationTime, uint256 lastStateChangeTime)`: Returns the creation and last state change timestamps for a Quanta.
27. `batchAddQuanta(bytes32[] calldata dataHashes, bytes32[] calldata initialEntanglementIDs)`: Adds multiple Quanta in a single transaction.
28. `batchSetMeasurementConditions(uint256[] calldata quantaIds, bytes32[] calldata conditionHashes)`: Sets measurement conditions for multiple Quanta.
29. `getCurrentEntanglementID(uint256 quantaId) view returns (bytes32)`: Gets the entanglement ID of a Quanta (returns zero bytes if not entangled).
30. `clearMeasurementResult(uint256 quantaId)`: Clears the stored measurement result for a Quanta (restricted).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledStorage
 * @dev A conceptual smart contract simulating quantum-like state management
 *      and entanglement for abstract data units (Quanta), represented by hashes.
 *      Access and interaction depend on the Quanta's state and predefined conditions.
 *      This contract explores complex state transitions, role-based access,
 *      and conditional execution triggered by simulated "quantum" events.
 */
contract QuantumEntangledStorage {

    // --- Outline ---
    // 1. SPDX License Identifier
    // 2. Pragma Version
    // 3. Imports (None needed for core logic)
    // 4. Contract Definition
    // 5. Roles Definition (Constants)
    // 6. Entanglement State Enum
    // 7. Structs: QuantaDetails
    // 8. State Variables
    // 9. Events
    // 10. Modifiers
    // 11. Constructor
    // 12. Owner & Role Management Functions (6)
    // 13. Quanta Management Functions (5)
    // 14. Entanglement & State Manipulation Functions (9)
    // 15. State Information & Access Functions (5)
    // 16. Batch Operations (2)
    // Total: 6 + 5 + 9 + 5 + 2 = 27 functions (excluding modifiers, views can be helpers)

    // --- Function Summary ---
    // 1. constructor(): Initializes the contract, sets owner.
    // 2. transferOwnership(address newOwner): Transfers contract ownership.
    // 3. addRole(address account, bytes32 role): Grants a role.
    // 4. removeRole(address account, bytes32 role): Revokes a role.
    // 5. isOwner(address account) view: Checks if account is owner.
    // 6. hasRole(address account, bytes32 role) view: Checks if account has role.
    // 7. renounceOwnership(): Renounces contract ownership.
    // 8. addQuanta(bytes32 dataHash, bytes32 initialEntanglementID) returns (uint256): Adds a new Quanta.
    // 9. updateQuantaHash(uint256 quantaId, bytes32 newDataHash): Updates a Quanta's data hash (restricted).
    // 10. removeQuanta(uint256 quantaId): Removes a Quanta (restricted, state-dependent).
    // 11. getQuantaCount() view returns (uint256): Returns total Quanta count.
    // 12. getQuantaDetails(uint256 quantaId) view returns (...): Gets all details for a Quanta.
    // 13. entangleQuantaPair(uint256 quantaId1, uint256 quantaId2, bytes32 entanglementID): Links two Quanta (restricted, state transition).
    // 14. decoupleQuantaPair(uint256 quantaId1, uint256 quantaId2): Breaks entanglement (restricted, state transition).
    // 15. setQuantaState(uint256 quantaId, EntanglementState newState): Directly sets state (highly restricted).
    // 16. attemptDecoherence(uint256 quantaId): Tries to move from Entangled to Decohered based on internal logic.
    // 17. performMeasurement(uint256 quantaId, bytes32 measurementProof): Tries to move from Decohered to Collapsed, verifies proof, stores result.
    // 18. setMeasurementCondition(uint256 quantaId, bytes32 conditionHash): Sets condition for measurement (restricted).
    // 19. clearMeasurementCondition(uint256 quantaId): Removes measurement condition (restricted).
    // 20. verifyEntanglementLink(uint256 quantaId1, uint256 quantaId2, bytes32 potentialEntanglementID) view returns (bool): Checks if two Quanta share a specific ID.
    // 21. batchSetStates(uint256[] calldata quantaIds, EntanglementState[] calldata newStates): Sets states for multiple Quanta (restricted).
    // 22. getQuantaState(uint256 quantaId) view returns (EntanglementState): Gets a Quanta's current state.
    // 23. canPerformMeasurement(uint256 quantaId) view returns (bool): Checks if a Quanta is ready for measurement.
    // 24. isQuantaEntangledWith(uint256 quantaId1, uint256 quantaId2) view returns (bool): Checks if two Quanta are entangled (any ID).
    // 25. getMeasurementResult(uint256 quantaId) view returns (bytes32): Gets stored measurement result.
    // 26. getQuantaTimestamp(uint256 quantaId) view returns (uint256 creationTime, uint256 lastStateChangeTime): Gets timestamps.
    // 27. batchAddQuanta(bytes32[] calldata dataHashes, bytes32[] calldata initialEntanglementIDs): Adds multiple Quanta.
    // 28. batchSetMeasurementConditions(uint256[] calldata quantaIds, bytes32[] calldata conditionHashes): Sets conditions for multiple Quanta.
    // 29. getCurrentEntanglementID(uint256 quantaId) view returns (bytes32): Gets the current entanglement ID.
    // 30. clearMeasurementResult(uint256 quantaId): Clears measurement result (restricted).


    // --- Roles ---
    bytes32 public constant KEY_MANAGER_ROLE = keccak256("KEY_MANAGER");
    bytes32 public constant STATE_ENGINE_ROLE = keccak256("STATE_ENGINE"); // Entity responsible for state transitions

    // --- Entanglement States ---
    enum EntanglementState {
        Initial,    // Newly created, not yet entangled
        Entangled,  // Linked with other Quanta
        Decohered,  // Partially separated, ready for potential measurement
        Collapsed,  // Measured, state determined, result stored
        Superposed // Reserved for future complex states (not used in current logic)
    }

    // --- Structs ---
    struct QuantaDetails {
        bytes32 dataHash;            // Hash representing the external data
        bytes32 entanglementID;      // Identifier linking entangled Quanta
        uint256 creationTimestamp;
        uint256 lastStateChangeTimestamp;
        EntanglementState state;
    }

    // --- State Variables ---
    address private _owner;
    mapping(address => mapping(bytes32 => bool)) private _roles;
    mapping(uint256 => QuantaDetails) private _quanta;
    uint256 private _nextQuantaId;
    mapping(uint256 => bytes32) private _quantaMeasurementConditions; // Hash of condition required for measurement
    mapping(uint256 => bytes32) private _quantaMeasurementResults;   // Result stored after successful measurement

    // --- Events ---
    event QuantaAdded(uint256 indexed quantaId, bytes32 dataHash, bytes32 indexed entanglementID, address indexed creator);
    event QuantaUpdated(uint256 indexed quantaId, bytes32 newDataHash, address indexed updater);
    event QuantaRemoved(uint256 indexed quantaId, address indexed remover);
    event StateChanged(uint256 indexed quantaId, EntanglementState oldState, EntanglementState newState, address indexed changer);
    event Entangled(uint256 indexed quantaId1, uint256 indexed quantaId2, bytes32 indexed entanglementID, address indexed entangler);
    event Decoupled(uint256 indexed quantaId1, uint256 indexed quantaId2, address indexed decoupler);
    event MeasurementPerformed(uint256 indexed quantaId, bytes32 measurementResult, address indexed performer);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not owner");
        _;
    }

    modifier hasRole(bytes32 role) {
        require(_roles[msg.sender][role] || isOwner(msg.sender), string(abi.encodePacked("Missing role: ", role)));
        _;
    }

    modifier isQuantaValid(uint256 quantaId) {
        require(_quanta[quantaId].creationTimestamp != 0, "Invalid Quanta ID");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // --- Owner & Role Management (6 Functions) ---

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addRole(address account, bytes32 role) public virtual onlyOwner {
        require(account != address(0), "Account is zero address");
        require(!_roles[account][role], "Account already has role");
        _roles[account][role] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    function removeRole(address account, bytes32 role) public virtual onlyOwner {
        require(account != address(0), "Account is zero address");
        require(_roles[account][role], "Account does not have role");
        _roles[account][role] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function isOwner(address account) public view virtual returns (bool) {
        return account == _owner;
    }

    function hasRole(address account, bytes32 role) public view virtual returns (bool) {
        return _roles[account][role];
    }

    function renounceOwnership() public virtual onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    // --- Quanta Management (5 Functions) ---

    /**
     * @dev Adds a new Quanta unit with a data hash and initial entanglement ID.
     * The initial state is set based on whether an entanglement ID is provided.
     */
    function addQuanta(bytes32 dataHash, bytes32 initialEntanglementID) public returns (uint256) {
        uint256 quantaId = _nextQuantaId++;
        EntanglementState initialState = initialEntanglementID == bytes32(0) ? EntanglementState.Initial : EntanglementState.Entangled;

        _quanta[quantaId] = QuantaDetails({
            dataHash: dataHash,
            entanglementID: initialEntanglementID,
            creationTimestamp: block.timestamp,
            lastStateChangeTimestamp: block.timestamp,
            state: initialState
        });

        emit QuantaAdded(quantaId, dataHash, initialEntanglementID, msg.sender);
        return quantaId;
    }

    /**
     * @dev Updates the data hash of an existing Quanta. Restricted to roles or owner.
     */
    function updateQuantaHash(uint256 quantaId, bytes32 newDataHash) public hasRole(KEY_MANAGER_ROLE) isQuantaValid(quantaId) {
        _quanta[quantaId].dataHash = newDataHash;
        emit QuantaUpdated(quantaId, newDataHash, msg.sender);
    }

    /**
     * @dev Removes a Quanta unit. Can only be removed if in Initial or Collapsed state. Restricted access.
     */
    function removeQuanta(uint256 quantaId) public hasRole(STATE_ENGINE_ROLE) isQuantaValid(quantaId) {
        require(_quanta[quantaId].state == EntanglementState.Initial || _quanta[quantaId].state == EntanglementState.Collapsed, "Quanta must be Initial or Collapsed to be removed");

        delete _quanta[quantaId];
        delete _quantaMeasurementConditions[quantaId];
        delete _quantaMeasurementResults[quantaId];

        emit QuantaRemoved(quantaId, msg.sender);
    }

    /**
     * @dev Returns the total number of Quanta ever added.
     */
    function getQuantaCount() public view returns (uint256) {
        return _nextQuantaId;
    }

    /**
     * @dev Gets the details for a specific Quanta.
     */
    function getQuantaDetails(uint256 quantaId) public view isQuantaValid(quantaId) returns (bytes32 dataHash, bytes32 entanglementID, uint256 creationTimestamp, uint256 lastStateChangeTimestamp, EntanglementState state) {
        QuantaDetails storage details = _quanta[quantaId];
        return (details.dataHash, details.entanglementID, details.creationTimestamp, details.lastStateChangeTimestamp, details.state);
    }

    // --- Entanglement & State Manipulation (9 Functions) ---

    /**
     * @dev Links two Quanta units with a shared entanglement ID.
     * Both must be in Initial or Decohered state and not already Entangled with a *different* ID.
     * Sets their state to Entangled. Requires KEY_MANAGER role.
     */
    function entangleQuantaPair(uint256 quantaId1, uint256 quantaId2, bytes32 entanglementID) public hasRole(KEY_MANAGER_ROLE) isQuantaValid(quantaId1) isQuantaValid(quantaId2) {
        require(quantaId1 != quantaId2, "Cannot entangle a Quanta with itself");
        require(entanglementID != bytes32(0), "Entanglement ID cannot be zero");

        QuantaDetails storage q1 = _quanta[quantaId1];
        QuantaDetails storage q2 = _quanta[quantaId2];

        require(q1.state == EntanglementState.Initial || q1.state == EntanglementState.Decohered, "Quanta 1 not in suitable state for entanglement");
        require(q2.state == EntanglementState.Initial || q2.state == EntanglementState.Decohered, "Quanta 2 not in suitable state for entanglement");
        require(q1.entanglementID == bytes32(0) || q1.entanglementID == entanglementID, "Quanta 1 already entangled with different ID");
        require(q2.entanglementID == bytes32(0) || q2.entanglementID == entanglementID, "Quanta 2 already entangled with different ID");

        _updateQuantaState(quantaId1, EntanglementState.Entangled);
        _updateQuantaState(quantaId2, EntanglementState.Entangled);

        q1.entanglementID = entanglementID;
        q2.entanglementID = entanglementID;

        emit Entangled(quantaId1, quantaId2, entanglementID, msg.sender);
    }

    /**
     * @dev Breaks the entanglement link between two Quanta if they share the same ID.
     * Sets their state to Decohered. Requires KEY_MANAGER role.
     */
    function decoupleQuantaPair(uint256 quantaId1, uint256 quantaId2) public hasRole(KEY_MANAGER_ROLE) isQuantaValid(quantaId1) isQuantaValid(quantaId2) {
        require(quantaId1 != quantaId2, "Cannot decouple a Quanta from itself");

        QuantaDetails storage q1 = _quanta[quantaId1];
        QuantaDetails storage q2 = _quanta[quantaId2];

        require(q1.state == EntanglementState.Entangled && q2.state == EntanglementState.Entangled, "Both Quanta must be in Entangled state");
        require(q1.entanglementID != bytes32(0) && q1.entanglementID == q2.entanglementID, "Quanta pair are not entangled with the same ID");

        q1.entanglementID = bytes32(0); // Clear entanglement ID
        q2.entanglementID = bytes32(0); // Clear entanglement ID

        _updateQuantaState(quantaId1, EntanglementState.Decohered);
        _updateQuantaState(quantaId2, EntanglementState.Decohered);

        emit Decoupled(quantaId1, quantaId2, msg.sender);
    }

    /**
     * @dev Allows restricted entities (STATE_ENGINE_ROLE or Owner) to directly set the state of a Quanta.
     * This bypasses the normal state transition logic and should be used cautiously.
     */
    function setQuantaState(uint256 quantaId, EntanglementState newState) public hasRole(STATE_ENGINE_ROLE) isQuantaValid(quantaId) {
        _updateQuantaState(quantaId, newState);
    }

    /**
     * @dev Attempts to move a Quanta from Entangled to Decohered state.
     * This function simulates a decoherence event. For this example, it simply requires STATE_ENGINE_ROLE.
     * In a more complex system, this could require time elapsed, external trigger, etc.
     */
    function attemptDecoherence(uint256 quantaId) public hasRole(STATE_ENGINE_ROLE) isQuantaValid(quantaId) {
        require(_quanta[quantaId].state == EntanglementState.Entangled, "Quanta is not in Entangled state");

        // Simulate potential condition for decoherence (e.g., time elapsed since last entangled/state change)
        // For simplicity here, just check role and state.
        // uint256 timeSinceLastChange = block.timestamp - _quanta[quantaId].lastStateChangeTimestamp;
        // require(timeSinceLastChange > MIN_DECOHERENCE_TIME, "Not enough time has passed for decoherence");

        _updateQuantaState(quantaId, EntanglementState.Decohered);
    }

    /**
     * @dev Attempts to perform a "measurement" on a Decohered Quanta, collapsing its state.
     * Requires STATE_ENGINE_ROLE, the Quanta to be in Decohered state, a measurement condition to be set,
     * and a provided proof that matches the condition.
     * Stores the 'measurementProof' as the result upon success.
     */
    function performMeasurement(uint256 quantaId, bytes32 measurementProof) public hasRole(STATE_ENGINE_ROLE) isQuantaValid(quantaId) {
        require(_quanta[quantaId].state == EntanglementState.Decohered, "Quanta is not in Decohered state");
        bytes32 requiredCondition = _quantaMeasurementConditions[quantaId];
        require(requiredCondition != bytes32(0), "Measurement condition is not set for this Quanta");

        // In a real system, this would involve verifying a cryptographic proof.
        // For this example, we just check if the provided proof hash matches the required condition hash.
        require(keccak256(abi.encodePacked(measurementProof)) == requiredCondition, "Measurement proof does not match condition");

        _updateQuantaState(quantaId, EntanglementState.Collapsed);
        _quantaMeasurementResults[quantaId] = measurementProof; // Store the "result" (the proof itself)
        emit MeasurementPerformed(quantaId, measurementProof, msg.sender);
    }

    /**
     * @dev Sets the hash representing the condition required to perform measurement on a Quanta.
     * Requires KEY_MANAGER role.
     */
    function setMeasurementCondition(uint256 quantaId, bytes32 conditionHash) public hasRole(KEY_MANAGER_ROLE) isQuantaValid(quantaId) {
         require(_quanta[quantaId].state != EntanglementState.Collapsed, "Cannot set condition on Collapsed Quanta");
        _quantaMeasurementConditions[quantaId] = conditionHash;
        // Event could be added here
    }

     /**
     * @dev Clears the measurement condition set for a Quanta.
     * Requires KEY_MANAGER role.
     */
    function clearMeasurementCondition(uint256 quantaId) public hasRole(KEY_MANAGER_ROLE) isQuantaValid(quantaId) {
         require(_quanta[quantaId].state != EntanglementState.Collapsed, "Cannot clear condition on Collapsed Quanta");
        delete _quantaMeasurementConditions[quantaId];
        // Event could be added here
    }


    /**
     * @dev Internal helper function to update Quanta state and timestamp.
     * Emits StateChanged event.
     */
    function _updateQuantaState(uint256 quantaId, EntanglementState newState) internal isQuantaValid(quantaId) {
        QuantaDetails storage details = _quanta[quantaId];
        EntanglementState oldState = details.state;
        if (oldState != newState) {
            details.state = newState;
            details.lastStateChangeTimestamp = block.timestamp;
            emit StateChanged(quantaId, oldState, newState, msg.sender);
        }
    }

     /**
      * @dev Checks if two Quanta units share a specific entanglement ID.
      */
     function verifyEntanglementLink(uint256 quantaId1, uint256 quantaId2, bytes32 potentialEntanglementID) public view isQuantaValid(quantaId1) isQuantaValid(quantaId2) returns (bool) {
         if (potentialEntanglementID == bytes32(0)) return false;
         QuantaDetails storage q1 = _quanta[quantaId1];
         QuantaDetails storage q2 = _quanta[quantaId2];
         return q1.entanglementID == potentialEntanglementID && q2.entanglementID == potentialEntanglementID && q1.entanglementID == q2.entanglementID;
     }

     /**
      * @dev Sets the state for a batch of Quanta IDs. Restricted access.
      */
     function batchSetStates(uint256[] calldata quantaIds, EntanglementState[] calldata newStates) public hasRole(STATE_ENGINE_ROLE) {
         require(quantaIds.length == newStates.length, "Array length mismatch");
         for(uint i = 0; i < quantaIds.length; i++) {
             uint256 quantaId = quantaIds[i];
             // Internal check: must be valid to prevent issues
             if (_quanta[quantaId].creationTimestamp != 0) {
                _updateQuantaState(quantaId, newStates[i]);
             }
         }
     }


    // --- State Information & Access (5 Functions) ---

    /**
     * @dev Returns the current state of a specific Quanta.
     */
    function getQuantaState(uint256 quantaId) public view isQuantaValid(quantaId) returns (EntanglementState) {
        return _quanta[quantaId].state;
    }

     /**
      * @dev Checks if a Quanta is in the Decohered state and has a measurement condition set.
      * These are the prerequisites for calling performMeasurement.
      */
    function canPerformMeasurement(uint256 quantaId) public view isQuantaValid(quantaId) returns (bool) {
        return _quanta[quantaId].state == EntanglementState.Decohered && _quantaMeasurementConditions[quantaId] != bytes32(0);
    }

    /**
     * @dev Checks if two Quanta units are currently linked by ANY shared entanglement ID.
     */
    function isQuantaEntangledWith(uint256 quantaId1, uint256 quantaId2) public view isQuantaValid(quantaId1) isQuantaValid(quantaId2) returns (bool) {
        QuantaDetails storage q1 = _quanta[quantaId1];
        QuantaDetails storage q2 = _quanta[quantaId2];
        return q1.state == EntanglementState.Entangled && q2.state == EntanglementState.Entangled && q1.entanglementID != bytes32(0) && q1.entanglementID == q2.entanglementID;
    }

    /**
     * @dev Retrieves the stored measurement result for a Collapsed Quanta.
     * Returns zero bytes if the Quanta is not Collapsed or no result was stored.
     */
    function getMeasurementResult(uint256 quantaId) public view isQuantaValid(quantaId) returns (bytes32) {
        require(_quanta[quantaId].state == EntanglementState.Collapsed, "Quanta is not in Collapsed state");
        return _quantaMeasurementResults[quantaId];
    }

    /**
     * @dev Gets the creation and last state change timestamps for a Quanta.
     */
    function getQuantaTimestamp(uint256 quantaId) public view isQuantaValid(quantaId) returns (uint256 creationTime, uint256 lastStateChangeTime) {
        QuantaDetails storage details = _quanta[quantaId];
        return (details.creationTimestamp, details.lastStateChangeTimestamp);
    }

    // --- Batch Operations (2 Functions) ---

    /**
     * @dev Adds multiple Quanta in a single transaction.
     * Data hashes and entanglement IDs arrays must have the same length.
     */
    function batchAddQuanta(bytes32[] calldata dataHashes, bytes32[] calldata initialEntanglementIDs) public {
        require(dataHashes.length == initialEntanglementIDs.length, "Array length mismatch");
        for(uint i = 0; i < dataHashes.length; i++) {
            addQuanta(dataHashes[i], initialEntanglementIDs[i]);
        }
    }

    /**
     * @dev Sets measurement conditions for a batch of Quanta IDs. Restricted access.
     */
    function batchSetMeasurementConditions(uint256[] calldata quantaIds, bytes32[] calldata conditionHashes) public hasRole(KEY_MANAGER_ROLE) {
         require(quantaIds.length == conditionHashes.length, "Array length mismatch");
         for(uint i = 0; i < quantaIds.length; i++) {
             uint256 quantaId = quantaIds[i];
             // Internal check: must be valid and not collapsed
             if (_quanta[quantaId].creationTimestamp != 0 && _quanta[quantaId].state != EntanglementState.Collapsed) {
                _quantaMeasurementConditions[quantaId] = conditionHashes[i];
             }
         }
    }

    // --- Additional Utility/View Functions (Added to reach >20 and provide more detail) ---

    /**
     * @dev Returns the data hash of a specific Quanta.
     */
    function getQuantaHash(uint256 quantaId) public view isQuantaValid(quantaId) returns (bytes32) {
        return _quanta[quantaId].dataHash;
    }

    /**
     * @dev Returns the current entanglement ID of a specific Quanta.
     */
    function getCurrentEntanglementID(uint256 quantaId) public view isQuantaValid(quantaId) returns (bytes32) {
        return _quanta[quantaId].entanglementID;
    }

    /**
     * @dev Clears the stored measurement result for a Collapsed Quanta.
     * Allows resetting a collapsed unit (e.g., for re-use or privacy). Restricted access.
     */
    function clearMeasurementResult(uint256 quantaId) public hasRole(KEY_MANAGER_ROLE) isQuantaValid(quantaId) {
        require(_quanta[quantaId].state == EntanglementState.Collapsed, "Quanta is not in Collapsed state");
        delete _quantaMeasurementResults[quantaId];
        // Event could be added here
    }
}
```