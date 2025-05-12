Okay, here is a smart contract concept leveraging "quantum-inspired" state management and complex, conditional access control, focusing on managing references (hashes) to sensitive data or keys. It uses concepts like 'states' with dynamic 'values', 'entanglement' (dependencies between states), 'superposition' (conditions evaluated at access time), and 'collapse' (state changes upon access or external trigger).

This is *not* actual quantum computing, but uses the terminology and ideas to build a more advanced state machine than typical access control contracts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumKeyManager
 * @author YourNameHere (Inspired by Quantum Concepts)
 * @notice A smart contract for managing access to hashed secrets/keys based on complex, dynamic, quantum-inspired states, conditions, and entanglements.
 * Access requires meeting specific conditions that can depend on the state of other "entangled" keys, time, internal values, or provided proofs.
 */

// --- OUTLINE ---
// 1. Structures: Define the data types for Quantum States, Access Conditions, etc.
// 2. State Variables: Store the contract's data (owner, states, mappings).
// 3. Events: Log important actions (state creation, access, permission changes, etc.).
// 4. Modifiers: Restrict function access (owner, state owner/permitted).
// 5. Internal/Helper Functions: Logic reused within the contract (e.g., checking conditions).
// 6. Core Functionality (State Management & Configuration): Functions to create, configure, and manage Quantum States and their rules.
// 7. Access Control & Interaction: Functions for users to attempt access, delegate access, check status, etc.
// 8. Admin/Owner Functions: High-level control functions.
// 9. View Functions: Read contract state without modifying it.

// --- FUNCTION SUMMARY ---
// Constructor: Initializes the contract owner.
// transferOwnership: Transfers contract ownership.
// renounceOwnership: Renounces contract ownership.
// createQuantumState: Registers a new quantum state with initial config and key hash.
// addAccessCondition: Adds a condition to an existing quantum state required for access.
// removeAccessCondition: Removes a specific access condition from a state.
// setEntanglement: Defines entanglement dependencies for a state (requires other states to be active).
// removeEntanglement: Removes entanglement dependencies.
// addStatePermission: Grants an address permission to configure a specific state.
// removeStatePermission: Revokes state configuration permission.
// deactivateState: Deactivates a state, preventing access.
// activateState: Activates a state, allowing access attempts.
// updateStateKeyHash: Updates the hashed key associated with a state (owner/state owner only).
// updateStateValue: Updates the dynamic currentStateValue of a state.
// setCollapseThreshold: Sets the access count threshold at which a state automatically collapses (deactivates).
// attemptAccess: The main function for users to attempt accessing a key hash by meeting state conditions.
// checkStateConditionsMet: View function to check if a state's conditions are met for a given address and proof (simulates attempt).
// checkEntanglementsMet: View function to check if a state's entangled dependencies are active.
// grantUserAccessOverride: Owner/state owner grants direct access permission, bypassing conditions.
// revokeUserAccessOverride: Owner/state owner revokes direct access override.
// grantDelegateForState: Owner/state owner grants an address permission to attempt access *for others* on a specific state.
// revokeDelegateForState: Owner/state owner revokes delegation permission.
// attemptAccessFor: Allows a permitted delegate to attempt access for another specified address.
// splitStateConditions: Creates a new state containing a subset of conditions from an existing state.
// mergeStateValues: Updates the value of a target state based on the values of two source states.
// setTimelock: Sets a timestamp before which a state cannot be accessed.
// getStateDetails: View function to retrieve details about a quantum state.
// getEntangledStates: View function to get a state's entanglement dependencies.
// getUserStatePermissions: View function to check an address's configuration permissions for a state.
// getUserGrantedAccess: View function to check if an address has a direct access override for a state.
// getStateAccessCount: View function to get the access count for a state.
// getStateLastAccess: View function to get the last access timestamp for a state.
// getConditionDetails: View function to retrieve details of a specific condition within a state.
// getCollapseThreshold: View function to get the collapse threshold for a state.
// isDelegateForState: View function to check if an address has delegation permission for a state.

contract QuantumKeyManager {

    // --- 1. Structures ---

    struct AccessCondition {
        // Represents a condition required for access.
        // Conditions are checked at the time of an access attempt.
        uint8 conditionType; // Type of check (e.g., 1=UserHasPermission, 2=StateValueAbove, 3=DependentStateActive, 4=TimestampAfter, 5=ProofMatchesHash, 6=AccessCountBelow, 7=ExternalOracleValue - note: Oracle check is symbolic here, requires external integration)
        uint256 param1;      // Generic parameter 1 (e.g., required value, state ID, timestamp, access count)
        uint256 param2;      // Generic parameter 2
        address paramAddress; // Address parameter (e.g., specific user for permission check)
        bytes32 paramBytes32; // Bytes32 parameter (e.g., hash to match for proof)
        bool negateCondition; // If true, the condition is met if the check *fails*.
    }

    struct QuantumState {
        // Represents a key/secret managed by the contract with its access rules.
        uint256 id;                     // Unique ID for the state
        bytes32 keyHash;                // Hash of the secret/key (the actual secret is stored OFF-CHAIN)
        address owner;                  // Creator/primary manager of this specific state
        bool isActive;                  // If false, access is currently disabled (manual or collapse)
        uint256[] entangledStates;      // IDs of other states this state depends on (must be active)
        AccessCondition[] accessConditions; // List of conditions required for access
        uint256 currentStateValue;      // A dynamic value representing the state's internal metric
        uint40 lastAccessTimestamp;     // Timestamp of the last successful access (uint40 fits block.timestamp)
        uint40 timelockUntil;          // Timestamp before which access is locked
        uint256 accessCount;            // Total number of successful accesses
        uint256 collapseThreshold;      // Access count threshold to automatically deactivate state (0 = no collapse)
    }

    // --- 2. State Variables ---

    address private _owner; // Contract owner with highest privileges

    uint256 private _stateCounter; // Counter for generating unique state IDs

    // Mapping from State ID to QuantumState struct
    mapping(uint256 => QuantumState) private _quantumStates;

    // Mapping from State ID => Address => bool (permissions for configuring a state)
    mapping(uint256 => mapping(address => bool)) private _statePermissions;

    // Mapping from Address => State ID => bool (direct access override, bypasses conditions)
    mapping(address => mapping(uint224 => bool)) private _userAccessOverride; // uint224 saves space

    // Mapping from Delegate Address => State ID => bool (permission to call attemptAccessFor)
    mapping(address => mapping(uint224 => bool)) private _delegateForStatePermission; // uint224 saves space


    // Mapping from State ID => Address => uint40 (record of last successful access for a user)
    mapping(uint256 => mapping(address => uint40)) private _accessLogs;

    // --- 3. Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event QuantumStateCreated(uint256 indexed stateId, address indexed owner, bytes32 keyHash);
    event AccessAttempted(uint256 indexed stateId, address indexed user, bool success);
    event AccessGranted(uint256 indexed stateId, address indexed user, bytes32 keyHash);
    event AccessOverrideGranted(uint256 indexed stateId, address indexed user, address indexed grantor);
    event AccessOverrideRevoked(uint256 indexed stateId, address indexed user, address indexed revoker);
    event StateDeactivated(uint256 indexed stateId, address indexed caller);
    event StateActivated(uint256 indexed stateId, address indexed caller);
    event StateValueUpdated(uint256 indexed stateId, address indexed caller, uint256 newValue);
    event StateEntanglementSet(uint256 indexed stateId, uint256[] entangledStates);
    event ConditionAdded(uint256 indexed stateId, uint8 conditionType);
    event ConditionRemoved(uint256 indexed stateId, uint256 indexed conditionIndex);
    event CollapseThresholdSet(uint256 indexed stateId, uint256 threshold);
    event StateConditionsSplit(uint256 indexed sourceStateId, uint256 indexed newStateId);
    event StateValuesMerged(uint256 indexed targetStateId, uint256 indexed sourceStateId1, uint256 indexed sourceStateId2);
    event DelegationGranted(uint256 indexed stateId, address indexed delegatee, address indexed grantor);
    event DelegationRevoked(uint256 indexed stateId, address indexed delegatee, address indexed revoker);

    // --- 4. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QKM: Not contract owner");
        _;
    }

    modifier onlyStateOwnerOrPermitted(uint256 _stateId) {
        require(_quantumStates[_stateId].owner == msg.sender || _statePermissions[_stateId][msg.sender] || msg.sender == _owner, "QKM: Not state owner or permitted");
        _;
    }

    modifier onlyStateOwner(uint256 _stateId) {
        require(_quantumStates[_stateId].owner == msg.sender, "QKM: Not state owner");
        _;
    }

    // --- 5. Internal/Helper Functions ---

    /// @dev Checks if all conditions for a given state are met by a specific user with optional proof.
    /// @param _stateId The ID of the state to check.
    /// @param _user The address attempting to meet conditions.
    /// @param _proofValueHash A hash provided by the user as proof for certain condition types.
    /// @return True if all conditions are met, false otherwise.
    function _checkStateConditions(uint256 _stateId, address _user, bytes32 _proofValueHash) internal view returns (bool) {
        QuantumState storage state = _quantumStates[_stateId];

        // Check direct override first (applies only to _user, not delegate)
        if (_userAccessOverride[_user][uint224(_stateId)]) {
            return true;
        }

        // Check if state is active and not timelocked
        if (!state.isActive || block.timestamp < state.timelockUntil) {
            return false;
        }

        // Check entanglements (dependent states must be active)
        if (!checkEntanglementsMet(_stateId)) {
             return false;
        }

        // Check all access conditions
        for (uint i = 0; i < state.accessConditions.length; i++) {
            AccessCondition storage condition = state.accessConditions[i];
            bool conditionMet = false;

            // Evaluate the condition based on its type
            if (condition.conditionType == 1) { // UserHasPermission (requires _user to have state permission)
                conditionMet = _statePermissions[_stateId][_user];
            } else if (condition.conditionType == 2) { // StateValueAbove (requires state.currentStateValue to be >= param1)
                conditionMet = state.currentStateValue >= condition.param1;
            } else if (condition.conditionType == 3) { // DependentStateActive (requires a specific state ID in param1 to be active)
                 uint256 dependentStateId = condition.param1;
                 if (_quantumStates[dependentStateId].id != dependentStateId) { // Check if state exists
                     conditionMet = false; // Non-existent state means condition fails
                 } else {
                     conditionMet = _quantumStates[dependentStateId].isActive;
                 }
            } else if (condition.conditionType == 4) { // TimestampAfter (requires current time to be >= param1)
                conditionMet = block.timestamp >= condition.param1;
            } else if (condition.conditionType == 5) { // ProofMatchesHash (requires _proofValueHash to match condition.paramBytes32)
                conditionMet = _proofValueHash != bytes32(0) && _proofValueHash == condition.paramBytes32;
            } else if (condition.conditionType == 6) { // AccessCountBelow (requires state.accessCount to be < param1)
                conditionMet = state.accessCount < condition.param1;
            }
            // Case 7: ExternalOracleValue (Symbolic - requires integration with an oracle contract
            // to fetch a value based on params and check it. Not implemented here.)
            // else if (condition.conditionType == 7) { ... }

            // Apply negation if necessary
            if (condition.negateCondition) {
                conditionMet = !conditionMet;
            }

            // If any condition is NOT met, the overall check fails
            if (!conditionMet) {
                return false;
            }
        }

        // If all conditions passed
        return true;
    }

    /// @dev Triggers state collapse (deactivation) if the collapse threshold is met.
    /// @param _stateId The ID of the state to check and potentially collapse.
    function _triggerCollapse(uint256 _stateId) internal {
        QuantumState storage state = _quantumStates[_stateId];
        if (state.collapseThreshold > 0 && state.accessCount >= state.collapseThreshold) {
            state.isActive = false;
            emit StateDeactivated(_stateId, address(this)); // Indicate automated collapse
        }
    }

    /// @dev Checks if a state's entangled dependencies are met (all dependent states are active).
    /// @param _stateId The ID of the state to check dependencies for.
    /// @return True if all entangled states are active or if there are no entangled states, false otherwise.
    function _checkEntanglements(uint256 _stateId) internal view returns (bool) {
        QuantumState storage state = _quantumStates[_stateId];
         for (uint i = 0; i < state.entangledStates.length; i++) {
             uint256 dependentStateId = state.entangledStates[i];
             // Check if the dependent state exists and is active
             if (_quantumStates[dependentStateId].id != dependentStateId || !_quantumStates[dependentStateId].isActive) {
                 return false; // Dependency not met
             }
         }
         return true; // All dependencies met
    }


    // --- 6. Core Functionality (State Management & Configuration) ---

    /// @notice Creates a new quantum state.
    /// @param _keyHash The hash of the off-chain secret/key this state controls access to.
    /// @param _initialConditions The initial set of conditions required for access.
    /// @param _entangledStates IDs of other states this state depends on.
    /// @param _collapseThreshold Access count threshold for automatic deactivation (0 for none).
    /// @param _timelockUntil Timestamp before which access is locked (0 for no timelock).
    /// @return The ID of the newly created state.
    function createQuantumState(
        bytes32 _keyHash,
        AccessCondition[] memory _initialConditions,
        uint256[] memory _entangledStates,
        uint256 _collapseThreshold,
        uint40 _timelockUntil
    ) public returns (uint256) {
        _stateCounter++;
        uint256 newStateId = _stateCounter;

        _quantumStates[newStateId] = QuantumState({
            id: newStateId,
            keyHash: _keyHash,
            owner: msg.sender,
            isActive: true, // States start active
            entangledStates: _entangledStates,
            accessConditions: _initialConditions,
            currentStateValue: 0, // Start with a default value
            lastAccessTimestamp: 0,
            timelockUntil: _timelockUntil,
            accessCount: 0,
            collapseThreshold: _collapseThreshold
        });

        emit QuantumStateCreated(newStateId, msg.sender, _keyHash);
        if (_entangledStates.length > 0) {
             emit StateEntanglementSet(newStateId, _entangledStates);
        }

        return newStateId;
    }

    /// @notice Adds a new access condition to an existing state.
    /// @param _stateId The ID of the state to modify.
    /// @param _condition The condition to add.
    function addAccessCondition(uint256 _stateId, AccessCondition memory _condition)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        _quantumStates[_stateId].accessConditions.push(_condition);
        emit ConditionAdded(_stateId, _condition.conditionType);
    }

    /// @notice Removes an access condition from a state by index.
    /// @dev Removing conditions can make a state easier to access.
    /// @param _stateId The ID of the state to modify.
    /// @param _conditionIndex The index of the condition to remove.
    function removeAccessCondition(uint256 _stateId, uint256 _conditionIndex)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        QuantumState storage state = _quantumStates[_stateId];
        require(state.id == _stateId, "QKM: State not found");
        require(_conditionIndex < state.accessConditions.length, "QKM: Invalid condition index");

        // Shift conditions to fill the gap
        for (uint i = _conditionIndex; i < state.accessConditions.length - 1; i++) {
            state.accessConditions[i] = state.accessConditions[i+1];
        }
        // Remove the last element (which is now a duplicate of the second to last, or was the single element)
        state.accessConditions.pop();

        emit ConditionRemoved(_stateId, _conditionIndex);
    }

    /// @notice Sets the entanglement dependencies for a state.
    /// @dev All states in `_entangledStates` must be active for this state to be accessible.
    /// @param _stateId The ID of the state to modify.
    /// @param _entangledStates The new list of entangled state IDs.
    function setEntanglement(uint256 _stateId, uint256[] memory _entangledStates)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");

        // Optional: Add checks for circular dependencies or max depth if needed (adds complexity/gas)
        // For simplicity here, we assume valid input or accept simple cycles.

        _quantumStates[_stateId].entangledStates = _entangledStates;
        emit StateEntanglementSet(_stateId, _entangledStates);
    }

     /// @notice Removes all entanglement dependencies for a state.
     /// @param _stateId The ID of the state to modify.
     function removeEntanglement(uint256 _stateId)
         public onlyStateOwnerOrPermitted(_stateId)
     {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         delete _quantumStates[_stateId].entangledStates; // Clears the dynamic array
         emit StateEntanglementSet(_stateId, new uint256[](0)); // Emit with empty array
     }


    /// @notice Grants an address permission to manage the configuration of a specific state (add/remove conditions, etc.).
    /// @param _stateId The ID of the state.
    /// @param _user The address to grant permission to.
    function addStatePermission(uint256 _stateId, address _user)
        public onlyStateOwnerOrPermitted(_stateId) // Owner can grant permissions, state owner can too
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        require(_user != address(0), "QKM: Zero address");
        _statePermissions[_stateId][_user] = true;
        // No specific event for add/remove permission to save gas, rely on state query
    }

    /// @notice Revokes configuration permission for an address on a state.
    /// @param _stateId The ID of the state.
    /// @param _user The address to revoke permission from.
    function removeStatePermission(uint256 _stateId, address _user)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        require(_user != address(0), "QKM: Zero address");
         // Prevent state owner removing their own permission if they are not contract owner
        if (msg.sender == _quantumStates[_stateId].owner && msg.sender != _owner && _user == msg.sender) {
             revert("QKM: State owner cannot remove their own permission");
        }
        _statePermissions[_stateId][_user] = false;
    }

    /// @notice Deactivates a state, preventing any further access attempts until activated again.
    /// @dev This simulates a "hard collapse".
    /// @param _stateId The ID of the state to deactivate.
    function deactivateState(uint256 _stateId) public onlyStateOwnerOrPermitted(_stateId) {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        _quantumStates[_stateId].isActive = false;
        emit StateDeactivated(_stateId, msg.sender);
    }

    /// @notice Activates a deactivated state.
    /// @param _stateId The ID of the state to activate.
    function activateState(uint256 _stateId) public onlyStateOwnerOrPermitted(_stateId) {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        _quantumStates[_stateId].isActive = true;
        emit StateActivated(_stateId, msg.sender);
    }

    /// @notice Updates the key hash associated with a state.
    /// @dev Use with extreme caution, as the old key hash effectively becomes inaccessible through this state.
    /// @param _stateId The ID of the state to modify.
    /// @param _newKeyHash The new hash of the secret/key.
    function updateStateKeyHash(uint256 _stateId, bytes32 _newKeyHash)
        public onlyStateOwnerOrPermitted(_stateId) // Allow permitted addresses too, if trusted
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         bytes32 oldHash = _quantumStates[_stateId].keyHash;
        _quantumStates[_stateId].keyHash = _newKeyHash;
        // Emit an event indicating the hash was updated? Or just rely on querying?
        // Let's rely on querying state details to see the change.
    }

    /// @notice Updates the dynamic value (`currentStateValue`) of a state.
    /// @dev This value can be used as a parameter in access conditions.
    /// @param _stateId The ID of the state to modify.
    /// @param _newValue The new value for `currentStateValue`.
    function updateStateValue(uint256 _stateId, uint256 _newValue)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        _quantumStates[_stateId].currentStateValue = _newValue;
        emit StateValueUpdated(_stateId, msg.sender, _newValue);
    }

    /// @notice Sets or updates the automatic collapse threshold for a state.
    /// @dev When the access count reaches this threshold (if > 0), the state deactivates.
    /// @param _stateId The ID of the state to modify.
    /// @param _threshold The new threshold (0 for no collapse).
    function setCollapseThreshold(uint256 _stateId, uint256 _threshold)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        _quantumStates[_stateId].collapseThreshold = _threshold;
        emit CollapseThresholdSet(_stateId, _threshold);
    }

    /// @notice Sets a timelock on a state, preventing access until a specific timestamp.
    /// @param _stateId The ID of the state to modify.
    /// @param _timelockUntil The timestamp until which access is locked. Set to 0 to remove timelock.
    function setTimelock(uint256 _stateId, uint40 _timelockUntil)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        _quantumStates[_stateId].timelockUntil = _timelockUntil;
        // No specific event for timelock, rely on querying state details
    }


    // --- 7. Access Control & Interaction ---

    /// @notice Attempts to access the key hash associated with a quantum state by meeting its conditions.
    /// @param _stateId The ID of the state to attempt access to.
    /// @param _proofValueHash A hash provided by the caller as proof for any 'ProofMatchesHash' conditions.
    /// @return The key hash if access is successful.
    function attemptAccess(uint256 _stateId, bytes32 _proofValueHash) public returns (bytes32) {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");

        bool success = _checkStateConditions(_stateId, msg.sender, _proofValueHash);

        emit AccessAttempted(_stateId, msg.sender, success);

        require(success, "QKM: Access conditions not met");

        QuantumState storage state = _quantumStates[_stateId];

        // Grant access, update state, and potentially trigger collapse
        state.lastAccessTimestamp = uint40(block.timestamp);
        state.accessCount++;
        _accessLogs[_stateId][msg.sender] = uint40(block.timestamp);

        _triggerCollapse(_stateId); // Check if collapse occurs after successful access

        emit AccessGranted(_stateId, msg.sender, state.keyHash);

        return state.keyHash;
    }

    /// @notice Allows a permitted delegate to attempt access for another address.
    /// @dev The delegate must have permission granted by `grantDelegateForState`.
    /// @param _stateId The ID of the state.
    /// @param _forAddress The address for whom the delegate is attempting access.
    /// @param _proofValueHash A hash provided by the delegate as proof for any 'ProofMatchesHash' conditions (evaluated against _forAddress).
    /// @return The key hash if access is successful for `_forAddress`.
    function attemptAccessFor(uint256 _stateId, address _forAddress, bytes32 _proofValueHash) public returns (bytes32) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         require(_forAddress != address(0), "QKM: Cannot attempt for zero address");

         // Check if msg.sender is a permitted delegate for this state
         require(_delegateForStatePermission[msg.sender][uint224(_stateId)], "QKM: Not permitted delegate for state");

         // Check conditions *for* the _forAddress
         bool success = _checkStateConditions(_stateId, _forAddress, _proofValueHash);

         emit AccessAttempted(_stateId, _forAddress, success); // Log attempt for the target user

         require(success, "QKM: Access conditions not met for target user");

         QuantumState storage state = _quantumStates[_stateId];

         // Grant access, update state, and potentially trigger collapse (state state is updated regardless of who accesses)
         state.lastAccessTimestamp = uint40(block.timestamp);
         state.accessCount++;
         _accessLogs[_stateId][_forAddress] = uint40(block.timestamp); // Log access for the target user

         _triggerCollapse(_stateId); // Check if collapse occurs

         emit AccessGranted(_stateId, _forAddress, state.keyHash); // Emit granted event for target user

         return state.keyHash;
    }


    // --- 8. Admin/Owner Functions ---

    /// @notice Transfers ownership of the contract.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "QKM: Zero address");
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /// @notice Renounces ownership of the contract.
    /// @dev This will leave the contract without an owner, potentially making some functions inaccessible.
    function renounceOwnership() public onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    /// @notice Grants a user direct access override for a state, bypassing all conditions.
    /// @dev This is a powerful permission, use with caution. Can be granted by contract owner or state owner/permitted address.
    /// @param _stateId The ID of the state.
    /// @param _user The address to grant override access to.
    function grantUserAccessOverride(uint256 _stateId, address _user)
        public onlyStateOwnerOrPermitted(_stateId) // Allow state owner/permitted to grant overrides for their state
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        require(_user != address(0), "QKM: Zero address");
        _userAccessOverride[_user][uint224(_stateId)] = true;
        emit AccessOverrideGranted(_stateId, _user, msg.sender);
    }

    /// @notice Revokes a user's direct access override for a state.
    /// @param _stateId The ID of the state.
    /// @param _user The address to revoke override access from.
    function revokeUserAccessOverride(uint256 _stateId, address _user)
        public onlyStateOwnerOrPermitted(_stateId)
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        require(_user != address(0), "QKM: Zero address");
        _userAccessOverride[_user][uint224(_stateId)] = false;
        emit AccessOverrideRevoked(_stateId, _user, msg.sender);
    }

    /// @notice Grants an address permission to be a delegate and call `attemptAccessFor` for a state.
    /// @dev The delegate can then attempt access for *any* address on this state.
    /// @param _stateId The ID of the state.
    /// @param _delegatee The address to grant delegation permission to.
    function grantDelegateForState(uint256 _stateId, address _delegatee)
         public onlyStateOwnerOrPermitted(_stateId) // Allow state owner/permitted to grant delegation
    {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         require(_delegatee != address(0), "QKM: Zero address");
         _delegateForStatePermission[_delegatee][uint224(_stateId)] = true;
         emit DelegationGranted(_stateId, _delegatee, msg.sender);
    }

    /// @notice Revokes an address's permission to be a delegate for a state.
    /// @param _stateId The ID of the state.
    /// @param _delegatee The address to revoke delegation permission from.
     function revokeDelegateForState(uint256 _stateId, address _delegatee)
         public onlyStateOwnerOrPermitted(_stateId)
     {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         require(_delegatee != address(0), "QKM: Zero address");
         _delegateForStatePermission[_delegatee][uint224(_stateId)] = false;
         emit DelegationRevoked(_stateId, _delegatee, msg.sender);
     }

    /// @notice Creates a new state containing a subset of conditions copied from an existing state.
    /// @dev This represents "splitting" a state's conditions into a new entity.
    /// The original state remains unchanged, but a new state is born with specific conditions.
    /// @param _sourceStateId The ID of the state to copy conditions from.
    /// @param _conditionIndicesToSplit The indices of the conditions from the source state to include in the new state.
    /// @param _newKeyHash The key hash for the new state (can be same or different).
    /// @return The ID of the newly created state.
    function splitStateConditions(uint256 _sourceStateId, uint256[] memory _conditionIndicesToSplit, bytes32 _newKeyHash)
         public onlyStateOwnerOrPermitted(_sourceStateId)
    {
         QuantumState storage sourceState = _quantumStates[_sourceStateId];
         require(sourceState.id == _sourceStateId, "QKM: Source state not found");
         require(_conditionIndicesToSplit.length > 0, "QKM: No conditions specified to split");

         // Prepare conditions for the new state
         AccessCondition[] memory newConditions = new AccessCondition[](_conditionIndicesToSplit.length);
         for (uint i = 0; i < _conditionIndicesToSplit.length; i++) {
             uint256 index = _conditionIndicesToSplit[i];
             require(index < sourceState.accessConditions.length, "QKM: Invalid condition index in split list");
             newConditions[i] = sourceState.accessConditions[index];
         }

         // Create the new state
         _stateCounter++;
         uint256 newStateId = _stateCounter;

          _quantumStates[newStateId] = QuantumState({
             id: newStateId,
             keyHash: _newKeyHash,
             owner: msg.sender, // New state owned by the caller
             isActive: true,
             entangledStates: new uint256[](0), // New state starts with no entanglements
             accessConditions: newConditions,
             currentStateValue: sourceState.currentStateValue, // Inherit value? Or start at 0? Let's inherit.
             lastAccessTimestamp: 0,
             timelockUntil: 0,
             accessCount: 0,
             collapseThreshold: 0 // Start with no collapse threshold
         });

         emit QuantumStateCreated(newStateId, msg.sender, _newKeyHash);
         emit StateConditionsSplit(_sourceStateId, newStateId);

         return newStateId;
    }

    /// @notice Merges the `currentStateValue` of two source states into a target state.
    /// @dev A simple merging logic (e.g., sum or average) is applied. Here, we sum the values.
    /// Accessing the target state might now depend on this new combined value.
    /// @param _targetStateId The state whose value will be updated.
    /// @param _sourceStateId1 The first source state.
    /// @param _sourceStateId2 The second source state.
    function mergeStateValues(uint256 _targetStateId, uint256 _sourceStateId1, uint256 _sourceStateId2)
        public onlyStateOwnerOrPermitted(_targetStateId)
    {
        require(_quantumStates[_targetStateId].id == _targetStateId, "QKM: Target state not found");
        require(_quantumStates[_sourceStateId1].id == _sourceStateId1, "QKM: Source state 1 not found");
        require(_quantumStates[_sourceStateId2].id == _sourceStateId2, "QKM: Source state 2 not found");
        require(_targetStateId != _sourceStateId1 && _targetStateId != _sourceStateId2, "QKM: Target cannot be source");

        uint256 mergedValue = _quantumStates[_sourceStateId1].currentStateValue + _quantumStates[_sourceStateId2].currentStateValue; // Simple sum
        _quantumStates[_targetStateId].currentStateValue = mergedValue;

        emit StateValuesMerged(_targetStateId, _sourceStateId1, _sourceStateId2);
         emit StateValueUpdated(_targetStateId, msg.sender, mergedValue); // Also emit the value update event
    }


    // --- 9. View Functions ---

    /// @notice Returns the address of the current contract owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice Retrieves details about a specific quantum state.
    /// @param _stateId The ID of the state to query.
    /// @return A tuple containing state properties.
    function getStateDetails(uint256 _stateId)
        public view
        returns (
            uint256 id,
            bytes32 keyHash,
            address stateOwner,
            bool isActive,
            uint256 currentStateValue,
            uint40 timelockUntil,
            uint256 accessCount,
            uint256 collapseThreshold
        )
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        QuantumState storage state = _quantumStates[_stateId];
        return (
            state.id,
            state.keyHash,
            state.owner,
            state.isActive,
            state.currentStateValue,
            state.timelockUntil,
            state.accessCount,
            state.collapseThreshold
        );
    }

    /// @notice Retrieves the entanglement dependencies for a state.
    /// @param _stateId The ID of the state to query.
    /// @return An array of state IDs that this state is entangled with.
    function getEntangledStates(uint256 _stateId) public view returns (uint256[] memory) {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        return _quantumStates[_stateId].entangledStates;
    }

    /// @notice Checks if an address has configuration permission for a specific state.
    /// @param _stateId The ID of the state.
    /// @param _user The address to check.
    /// @return True if the user has permission, false otherwise.
    function getUserStatePermissions(uint256 _stateId, address _user) public view returns (bool) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         return _statePermissions[_stateId][_user];
    }

    /// @notice Checks if a user has a direct access override for a state.
    /// @param _stateId The ID of the state.
    /// @param _user The address to check.
    /// @return True if the user has an override, false otherwise.
    function getUserGrantedAccess(uint256 _stateId, address _user) public view returns (bool) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         return _userAccessOverride[_user][uint224(_stateId)];
    }

     /// @notice Gets the current access count for a state.
     /// @param _stateId The ID of the state.
     /// @return The number of times the state has been successfully accessed.
     function getStateAccessCount(uint256 _stateId) public view returns (uint256) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         return _quantumStates[_stateId].accessCount;
     }

     /// @notice Gets the timestamp of the last successful access for a state.
     /// @param _stateId The ID of the state.
     /// @return The timestamp of the last access, or 0 if never accessed.
     function getStateLastAccess(uint256 _stateId) public view returns (uint40) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         return _quantumStates[_stateId].lastAccessTimestamp;
     }

    /// @notice Retrieves the details of a specific access condition within a state.
    /// @param _stateId The ID of the state.
    /// @param _conditionIndex The index of the condition to retrieve.
    /// @return A tuple containing the condition properties.
    function getConditionDetails(uint256 _stateId, uint256 _conditionIndex)
        public view
        returns (
            uint8 conditionType,
            uint256 param1,
            uint256 param2,
            address paramAddress,
            bytes32 paramBytes32,
            bool negateCondition
        )
    {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        require(_conditionIndex < _quantumStates[_stateId].accessConditions.length, "QKM: Invalid condition index");
        AccessCondition storage condition = _quantumStates[_stateId].accessConditions[_conditionIndex];
        return (
            condition.conditionType,
            condition.param1,
            condition.param2,
            condition.paramAddress,
            condition.paramBytes32,
            condition.negateCondition
        );
    }

    /// @notice Gets the collapse threshold for a state.
    /// @param _stateId The ID of the state.
    /// @return The access count threshold for automatic collapse (0 if none).
    function getCollapseThreshold(uint256 _stateId) public view returns (uint256) {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        return _quantumStates[_stateId].collapseThreshold;
    }

    /// @notice Checks if an address has delegation permission for a state.
    /// @dev If true, this address can call `attemptAccessFor` for this state.
    /// @param _stateId The ID of the state.
    /// @param _delegatee The address to check.
    /// @return True if the address is a permitted delegate for this state, false otherwise.
     function isDelegateForState(uint256 _stateId, address _delegatee) public view returns (bool) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         return _delegateForStatePermission[_delegatee][uint224(_stateId)];
     }

     /// @notice View helper to check if a state's entangled dependencies are met.
     /// @param _stateId The ID of the state to check dependencies for.
     /// @return True if all entangled states are active or if there are no entangled states, false otherwise.
     function checkEntanglementsMet(uint256 _stateId) public view returns (bool) {
        require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
        return _checkEntanglements(_stateId);
     }

     /// @notice View function to check if a state's conditions are met for a given user and proof, without modifying state.
     /// @dev Useful for a frontend to check if access is possible. Note: Timelock and isActive checks are included.
     /// @param _stateId The ID of the state to check.
     /// @param _user The address whose permissions/conditions are being checked.
     /// @param _proofValueHash A hash provided by the user as proof.
     /// @return True if conditions are met, false otherwise.
     function checkStateConditionsMet(uint256 _stateId, address _user, bytes32 _proofValueHash) public view returns (bool) {
         require(_quantumStates[_stateId].id == _stateId, "QKM: State not found");
         return _checkStateConditions(_stateId, _user, _proofValueHash);
     }
}
```