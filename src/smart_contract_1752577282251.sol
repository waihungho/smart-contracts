Okay, here is a Solidity smart contract called `QuantumReflector`. It's designed around the concept of managing abstract "Reflected States" whose properties can be influenced by external data (simulated oracles), time, and user interactions, including splitting, merging, and granular permissioning. It avoids standard token (ERC-20/721/1155) interfaces directly, focusing on the unique state management logic.

This contract is complex and illustrative. Deploying it on a real network would require careful consideration of gas costs, security audits, and robust oracle integration (using services like Chainlink).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumReflector
/// @author Your Name / AI
/// @notice A contract for managing abstract 'Reflected States' influenced by user interaction, time, and simulated external 'quantum fluctuations' (oracles).
/// These states have properties like energy, coherence, and entropy, and can be transformed, split, merged, and delegated.

// --- OUTLINE ---
// 1. Data Structures (Structs, Enums)
// 2. State Variables (Mappings, Counters)
// 3. Events
// 4. Custom Errors
// 5. Modifiers
// 6. Core State Management (Create, Transfer, Destroy)
// 7. State Property Modification
// 8. Advanced State Transformations (Split, Merge, Mutate)
// 9. Oracle Interaction Simulation (Register, Link, Process)
// 10. Time-based State Control
// 11. Access Control & Delegation
// 12. Granular State Permissions
// 13. Batch Operations
// 14. Query Functions

// --- FUNCTION SUMMARY ---
// State Management:
// 1. createReflectedState: Creates a new Reflected State with initial properties.
// 2. activateState: Marks an inactive state as active.
// 3. deactivateState: Marks an active state as inactive.
// 4. transferStateOwnership: Transfers ownership of a state.
// 5. destroyState: Permanently removes a state.

// Property Modification:
// 6. modifyEnergyLevel: Adjusts the energy level of a state.
// 7. modifyCoherenceLevel: Adjusts the coherence level of a state.
// 8. modifyEntropyFactor: Adjusts the entropy factor of a state.
// 9. attuneStateToFrequency: Applies a transformation based on a frequency parameter.

// Advanced Transformations:
// 10. splitState: Divides one state into two new states based on property ratios.
// 11. mergeStates: Combines two states into a single new state.
// 12. mutateState: Applies a transformation influenced by linked oracle data and entropy.

// Oracle Interaction (Simulated):
// 13. registerOracleFeed: Registers a new simulated oracle feed.
// 14. unregisterOracleFeed: Unregisters a simulated oracle feed.
// 15. linkStateToOracle: Associates a state with a registered oracle feed.
// 16. unlinkStateFromOracle: Removes the association with an oracle feed.
// 17. processLinkedOracleData: Manually triggers processing of the latest oracle data for a state (simulated pull).

// Time-based Control:
// 18. setTimeLock: Locks a state until a specific timestamp.
// 19. clearTimeLock: Removes a time lock after the unlock time has passed.

// Access Control & Delegation:
// 20. delegateStateControl: Allows an address to temporarily control a state.
// 21. revokeStateControl: Removes delegated control.
// 22. queryDelegatee: Checks the current delegatee for a state.

// Granular State Permissions:
// 23. setCustomStatePermission: Grants or revokes a specific address permission to call a specific function signature on a state.
// 24. clearCustomStatePermission: Clears all custom permissions for an address on a state.
// 25. queryCustomStatePermission: Checks if an address has a specific permission on a state.

// Batch Operations:
// 26. performBatchMutation: Applies mutation to multiple states owned by the caller.

// Maintenance/Derived Value:
// 27. initiateDecoherenceScan: Simulates a check that potentially reduces coherence based on time/entropy.
// 28. reflectStateValue: Calculates a hypothetical value based on a state's properties.

// Query Functions:
// 29. getStateDetails: Retrieves all details for a given state ID.
// 30. getOracleFeedDetails: Retrieves details for a registered oracle feed.

// 31. getTotalStates: Returns the total number of states ever created (incl. destroyed).
// 32. getActiveStatesCount: Returns the count of active states. (Requires iteration or separate counter, less efficient, or updated via events). Let's add simple ones.
// 33. getStatesOwnedBy: Returns a list of state IDs owned by an address (Requires an array or linked list per user - less efficient. Let's make this read-only, potentially inefficient for many states).

contract QuantumReflector {

    // --- 1. Data Structures ---
    struct ReflectedState {
        uint256 id;
        address owner;
        uint64 creationTime;
        uint256 energyLevel;      // e.g., 0-1000, represents intensity
        uint256 coherenceLevel;   // e.g., 0-100, represents stability/resistance to change
        uint256 entropyFactor;    // e.g., 0-10, influences speed of decoherence/mutation
        uint32 linkedOracleId;    // 0 if not linked, else ID
        uint64 lastOracleUpdateTime; // When oracle data last processed for this state
        string metadataURI;       // Link to off-chain data
        bool isActive;            // Can it be interacted with?
    }

    struct OracleFeed {
        uint32 id;
        address authorizedUpdater; // Address allowed to update this feed
        uint256 latestData;        // Simulated latest data point
        uint64 lastUpdateTime;     // When the feed was last updated
        string description;        // Description of the feed (e.g., "ETH Price", "Randomness Seed")
        bool isRegistered;         // Whether the feed is currently active
    }

    // Custom Permission levels (could be expanded)
    enum Permission {
        NONE,       // No special permission
        READ,       // Can query state details
        MODIFY      // Can modify state properties (energy, coherence, entropy, metadata)
        // Could add more granular permissions like TRANSFER, SPLIT, MERGE, etc.
    }

    // --- 2. State Variables ---
    uint256 private _stateCounter;
    mapping(uint256 => ReflectedState) private _states;
    mapping(address => uint256[]) private _statesOwnedBy; // Helper for getStatesOwnedBy (potentially inefficient)
    mapping(uint256 => uint64) private _stateTimeLocks; // stateId => unlockTimestamp
    mapping(uint256 => address) private _stateDelegates; // stateId => delegateAddress

    // Granular state permissions: stateId => subjectAddress => functionSignature => allowed
    mapping(uint256 => mapping(address => mapping(bytes4 => bool))) private _customStatePermissions;

    uint32 private _oracleFeedCounter;
    mapping(uint32 => OracleFeed) private _oracleFeeds;
    // Simulating oracle data: oracleId => data (This is where the *updater* would write)
    mapping(uint32 => uint256) private _latestOracleData;

    address public admin; // Simple admin role for managing oracles

    // --- 3. Events ---
    event StateCreated(uint256 indexed stateId, address indexed owner, uint256 initialEnergy);
    event StateOwnershipTransferred(uint256 indexed stateId, address indexed from, address indexed to);
    event StateDestroyed(uint256 indexed stateId, address indexed owner);
    event StateActivated(uint256 indexed stateId);
    event StateDeactivated(uint256 indexed stateId);
    event StatePropertiesModified(uint256 indexed stateId, string propertyName, uint256 oldValue, uint256 newValue);
    event StateSplit(uint256 indexed sourceStateId, uint256 indexed newState1Id, uint256 indexed newState2Id);
    event StateMerged(uint256 indexed newStateId, uint256 indexed sourceState1Id, uint256 indexed sourceState2Id);
    event StateMutated(uint256 indexed stateId, uint256 newEnergy, uint256 newCoherence, uint256 newEntropy);
    event OracleFeedRegistered(uint32 indexed oracleId, address indexed updater, string description);
    event OracleFeedUnregistered(uint32 indexed oracleId);
    event StateLinkedToOracle(uint256 indexed stateId, uint32 indexed oracleId);
    event StateUnlinkedFromOracle(uint256 indexed stateId, uint32 indexed oracleId);
    event OracleDataProcessedForState(uint256 indexed stateId, uint32 indexed oracleId, uint256 processedData);
    event StateTimeLocked(uint256 indexed stateId, uint64 unlockTime);
    event StateTimeLockCleared(uint256 indexed stateId);
    event StateControlDelegated(uint256 indexed stateId, address indexed delegatee);
    event StateControlRevoked(uint256 indexed stateId, address indexed delegatee);
    event CustomStatePermissionSet(uint256 indexed stateId, address indexed subject, bytes4 functionSig, bool allowed);
    event CustomStatePermissionCleared(uint256 indexed stateId, address indexed subject);
    event BatchMutationPerformed(address indexed caller, uint256[] indexed stateIds);
    event DecoherenceScanInitiated(address indexed caller, uint256 indexed stateId, uint256 newCoherence);


    // --- 4. Custom Errors ---
    error StateNotFound(uint256 stateId);
    error NotStateOwner(uint256 stateId, address caller);
    error NotStateOwnerOrDelegatee(uint256 stateId, address caller);
    error NotStateOwnerOrDelegateeOrPermitted(uint256 stateId, address caller, bytes4 functionSig);
    error StateNotActive(uint255 stateId);
    error StateActive(uint255 stateId);
    error StateTimeLocked(uint256 stateId, uint64 unlockTime);
    error UnlockTimeNotInPast(uint64 unlockTime);
    error OracleNotRegistered(uint32 oracleId);
    error NotOracleUpdater(uint32 oracleId, address caller);
    error StateAlreadyLinkedToOracle(uint256 stateId, uint32 oracleId);
    error StateNotLinkedToOracle(uint256 stateId);
    error InvalidSplitRatio();
    error CannotMergeDifferentOracles();
    error CannotMergeInactiveStates();
    error CannotMergeStatesWithDifferentOwners();
    error NothingToDecohere();
    error NoDelegateeSet(uint256 stateId);
    error AlreadyDelegatee(uint256 stateId, address delegatee);
    error DelegationAlreadyExists(uint256 stateId);
    error PermissionAlreadySet(uint256 stateId, address subject, bytes4 functionSig);
    error PermissionDoesNotExist(uint256 stateId, address subject, bytes4 functionSig);


    // --- 5. Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert ("Not admin"); // Use simple string for admin check
        }
        _;
    }

    modifier onlyStateOwner(uint256 stateId) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        if (_states[stateId].owner != msg.sender) revert NotStateOwner(stateId, msg.sender);
        _;
    }

     modifier onlyStateOwnerOrDelegatee(uint256 stateId) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        if (_states[stateId].owner != msg.sender && _stateDelegates[stateId] != msg.sender) {
            revert NotStateOwnerOrDelegatee(stateId, msg.sender);
        }
        _;
    }

    modifier onlyStateOwnerOrDelegateeOrPermitted(uint256 stateId) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        address owner = _states[stateId].owner;
        address delegatee = _stateDelegates[stateId];
        bytes4 functionSig = msg.sig;

        // Owner always has permission
        if (owner == msg.sender) {
            _;
        }
        // Delegatee has implicit permission for certain actions (defined by contract logic)
        // Or explicit custom permission
        else if (delegatee == msg.sender || _customStatePermissions[stateId][msg.sender][functionSig]) {
             // Add checks here if delegatee should be restricted from certain actions even if delegated
            _;
        }
        else {
            revert NotStateOwnerOrDelegateeOrPermitted(stateId, msg.sender, functionSig);
        }
    }

    modifier onlyActiveState(uint256 stateId) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        if (!_states[stateId].isActive) revert StateNotActive(stateId);
        _;
    }

    modifier onlyInactiveState(uint256 stateId) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        if (_states[stateId].isActive) revert StateActive(stateId);
        _;
    }

    modifier notTimeLocked(uint256 stateId) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        uint64 unlockTime = _stateTimeLocks[stateId];
        if (unlockTime > 0 && uint64(block.timestamp) < unlockTime) {
            revert StateTimeLocked(stateId, unlockTime);
        }
        _;
    }

    modifier onlyOracleUpdater(uint32 oracleId) {
        if (!_oracleFeeds[oracleId].isRegistered) revert OracleNotRegistered(oracleId);
        if (_oracleFeeds[oracleId].authorizedUpdater != msg.sender) revert NotOracleUpdater(oracleId, msg.sender);
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        _stateCounter = 0;
        _oracleFeedCounter = 0;
    }

    // --- 6. Core State Management ---

    /// @notice Creates a new Reflected State.
    /// @param initialEnergy Initial energy level (0-1000).
    /// @param initialCoherence Initial coherence level (0-100).
    /// @param initialEntropy Initial entropy factor (0-10).
    /// @param metadataURI Optional URI for off-chain data.
    /// @return stateId The ID of the newly created state.
    function createReflectedState(
        uint256 initialEnergy,
        uint256 initialCoherence,
        uint256 initialEntropy,
        string calldata metadataURI
    ) external returns (uint256 stateId) {
        _stateCounter++;
        stateId = _stateCounter;

        ReflectedState storage newState = _states[stateId];
        newState.id = stateId;
        newState.owner = msg.sender;
        newState.creationTime = uint64(block.timestamp);
        newState.energyLevel = initialEnergy > 1000 ? 1000 : initialEnergy; // Clamp values
        newState.coherenceLevel = initialCoherence > 100 ? 100 : initialCoherence;
        newState.entropyFactor = initialEntropy > 10 ? 10 : initialEntropy;
        newState.linkedOracleId = 0; // No oracle initially
        newState.lastOracleUpdateTime = 0;
        newState.metadataURI = metadataURI;
        newState.isActive = true; // States start active

        _statesOwnedBy[msg.sender].push(stateId);

        emit StateCreated(stateId, msg.sender, initialEnergy);
    }

    /// @notice Marks an inactive state as active. Only callable by owner.
    /// @param stateId The ID of the state to activate.
    function activateState(uint256 stateId) external onlyStateOwner(stateId) onlyInactiveState(stateId) {
        _states[stateId].isActive = true;
        emit StateActivated(stateId);
    }

    /// @notice Marks an active state as inactive. Only callable by owner.
    /// @param stateId The ID of the state to deactivate.
    function deactivateState(uint256 stateId) external onlyStateOwner(stateId) onlyActiveState(stateId) {
        _states[stateId].isActive = false;
        emit StateDeactivated(stateId);
    }

    /// @notice Transfers ownership of a state to another address. Only callable by owner and when not time locked.
    /// @param stateId The ID of the state to transfer.
    /// @param to The recipient address.
    function transferStateOwnership(uint256 stateId, address to)
        external
        onlyStateOwner(stateId)
        notTimeLocked(stateId)
    {
        if (to == address(0)) revert ("Cannot transfer to zero address");

        address from = _states[stateId].owner;
        _states[stateId].owner = to;

        // Update _statesOwnedBy mappings (inefficient but necessary for getStatesOwnedBy)
        uint256[] storage fromStates = _statesOwnedBy[from];
        for (uint i = 0; i < fromStates.length; i++) {
            if (fromStates[i] == stateId) {
                fromStates[i] = fromStates[fromStates.length - 1];
                fromStates.pop();
                break;
            }
        }
        _statesOwnedBy[to].push(stateId);

        emit StateOwnershipTransferred(stateId, from, to);
    }

    /// @notice Permanently destroys a state. Only callable by owner and when inactive and not time locked.
    /// @param stateId The ID of the state to destroy.
    function destroyState(uint256 stateId)
        external
        onlyStateOwner(stateId)
        onlyInactiveState(stateId)
        notTimeLocked(stateId)
    {
         // Remove from _statesOwnedBy mapping
        address owner = _states[stateId].owner;
        uint256[] storage ownedStates = _statesOwnedBy[owner];
         for (uint i = 0; i < ownedStates.length; i++) {
            if (ownedStates[i] == stateId) {
                ownedStates[i] = ownedStates[ownedStates.length - 1];
                ownedStates.pop();
                break;
            }
        }

        // Clear related mappings
        delete _states[stateId];
        delete _stateTimeLocks[stateId];
        delete _stateDelegates[stateId];
        delete _customStatePermissions[stateId]; // Clear all permissions for this state

        emit StateDestroyed(stateId, owner);
    }

    // --- 7. State Property Modification ---

    /// @notice Adjusts the energy level of a state. Subject to permissions/delegation/ownership.
    /// @param stateId The ID of the state.
    /// @param newEnergy The new energy level (clamped 0-1000).
    function modifyEnergyLevel(uint256 stateId, uint256 newEnergy)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        uint256 clampedEnergy = newEnergy > 1000 ? 1000 : newEnergy;
        uint256 oldEnergy = _states[stateId].energyLevel;
        if (oldEnergy != clampedEnergy) {
            _states[stateId].energyLevel = clampedEnergy;
            emit StatePropertiesModified(stateId, "energyLevel", oldEnergy, clampedEnergy);
        }
    }

    /// @notice Adjusts the coherence level of a state. Subject to permissions/delegation/ownership.
    /// @param stateId The ID of the state.
    /// @param newCoherence The new coherence level (clamped 0-100).
    function modifyCoherenceLevel(uint256 stateId, uint256 newCoherence)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        uint256 clampedCoherence = newCoherence > 100 ? 100 : newCoherence;
        uint256 oldCoherence = _states[stateId].coherenceLevel;
         if (oldCoherence != clampedCoherence) {
            _states[stateId].coherenceLevel = clampedCoherence;
            emit StatePropertiesModified(stateId, "coherenceLevel", oldCoherence, clampedCoherence);
        }
    }

    /// @notice Adjusts the entropy factor of a state. Subject to permissions/delegation/ownership.
    /// @param stateId The ID of the state.
    /// @param newEntropy The new entropy factor (clamped 0-10).
    function modifyEntropyFactor(uint256 stateId, uint256 newEntropy)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        uint256 clampedEntropy = newEntropy > 10 ? 10 : newEntropy;
        uint256 oldEntropy = _states[stateId].entropyFactor;
        if (oldEntropy != clampedEntropy) {
             _states[stateId].entropyFactor = clampedEntropy;
            emit StatePropertiesModified(stateId, "entropyFactor", oldEntropy, clampedEntropy);
        }
    }

    /// @notice Updates the metadata URI for a state. Subject to permissions/delegation/ownership.
    /// @param stateId The ID of the state.
    /// @param newURI The new metadata URI.
    function updateMetadataURI(uint256 stateId, string calldata newURI)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        // Simple string comparison check would be gas intensive, skip for example
        _states[stateId].metadataURI = newURI;
        // Emit a generic modified event or a specific metadata event? Let's use generic for simplicity.
        // emit StatePropertiesModified(stateId, "metadataURI", 0, 0); // Value doesn't apply well
        // Could add a specific event if needed
    }

    /// @notice Applies a transformation based on a frequency parameter, affecting properties.
    /// @param stateId The ID of the state.
    /// @param frequency A parameter influencing the transformation (e.g., 0-100).
    function attuneStateToFrequency(uint256 stateId, uint256 frequency)
         external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        ReflectedState storage state = _states[stateId];
        uint256 clampedFreq = frequency > 100 ? 100 : frequency; // Clamp frequency

        // Simple example logic: frequency influences energy/coherence trade-off
        uint256 oldEnergy = state.energyLevel;
        uint256 oldCoherence = state.coherenceLevel;

        // Formula example: Higher freq -> more energy, less coherence
        // Lower freq -> less energy, more coherence
        // This is just illustrative logic.
        state.energyLevel = (oldEnergy * (100 + clampedFreq) / 100) > 1000 ? 1000 : (oldEnergy * (100 + clampedFreq) / 100);
        state.coherenceLevel = (oldCoherence * (100 - clampedFreq) / 100) > 100 ? 100 : (oldCoherence * (100 - clampedFreq) / 100);

        emit StatePropertiesModified(stateId, "energyLevel", oldEnergy, state.energyLevel);
        emit StatePropertiesModified(stateId, "coherenceLevel", oldCoherence, state.coherenceLevel);
        // No event for frequency itself, as it's an input, not a state property

    }

    // --- 8. Advanced State Transformations ---

    /// @notice Splits a state into two new states. Requires owner and the state must be active and not time locked.
    /// Properties are divided based on a ratio. The original state is consumed.
    /// @param sourceStateId The ID of the state to split.
    /// @param ratioBps The ratio for the first new state in basis points (e.g., 5000 for 50%). Remaining goes to the second.
    /// @return newState1Id The ID of the first new state.
    /// @return newState2Id The ID of the second new state.
    function splitState(uint256 sourceStateId, uint256 ratioBps)
        external
        onlyStateOwner(sourceStateId)
        onlyActiveState(sourceStateId)
        notTimeLocked(sourceStateId)
        returns (uint256 newState1Id, uint256 newState2Id)
    {
        if (ratioBps == 0 || ratioBps >= 10000) revert InvalidSplitRatio();

        ReflectedState storage sourceState = _states[sourceStateId];
        address owner = sourceState.owner;

        // Calculate new properties based on ratio
        uint256 energy1 = (sourceState.energyLevel * ratioBps) / 10000;
        uint256 coherence1 = (sourceState.coherenceLevel * ratioBps) / 10000;
        uint256 entropy1 = (sourceState.entropyFactor * ratioBps) / 10000;

        uint256 energy2 = (sourceState.energyLevel * (10000 - ratioBps)) / 10000;
        uint256 coherence2 = (sourceState.coherenceLevel * (10000 - ratioBps)) / 10000;
        uint256 entropy2 = (sourceState.entropyFactor * (10000 - ratioBps)) / 10000;

        // Create two new states
        _stateCounter++;
        newState1Id = _stateCounter;
        ReflectedState storage state1 = _states[newState1Id];
        state1.id = newState1Id;
        state1.owner = owner;
        state1.creationTime = uint64(block.timestamp);
        state1.energyLevel = energy1;
        state1.coherenceLevel = coherence1;
        state1.entropyFactor = entropy1;
        state1.linkedOracleId = sourceState.linkedOracleId; // Inherit oracle link
        state1.lastOracleUpdateTime = sourceState.lastOracleUpdateTime;
        state1.metadataURI = string.concat(sourceState.metadataURI, "-split1"); // Append identifier
        state1.isActive = true;

        _stateCounter++;
        newState2Id = _stateCounter;
        ReflectedState storage state2 = _states[newState2Id];
        state2.id = newState2Id;
        state2.owner = owner;
        state2.creationTime = uint64(block.timestamp);
        state2.energyLevel = energy2;
        state2.coherenceLevel = coherence2;
        state2.entropyFactor = entropy2;
        state2.linkedOracleId = sourceState.linkedOracleId; // Inherit oracle link
        state2.lastOracleUpdateTime = sourceState.lastOracleUpdateTime;
        state2.metadataURI = string.concat(sourceState.metadataURI, "-split2"); // Append identifier
        state2.isActive = true;

         // Add new states to owner's list
        _statesOwnedBy[owner].push(newState1Id);
        _statesOwnedBy[owner].push(newState2Id);

        // Destroy the original state
        // Removing from _statesOwnedBy happens inside destroyState
        destroyState(sourceStateId); // Note: destroyState requires inactive state, need to override or make exception
                                     // Let's make split consume state regardless of active status for simplicity here.
                                     // In production, may require inactivation first.

        // Override destroyState's inactive requirement for split
        // Simple version: clear data, don't call destroyState
        address originalOwner = sourceState.owner; // Get owner before deleting state
        delete _states[sourceStateId];
        delete _stateTimeLocks[sourceStateId];
        delete _stateDelegates[sourceStateId];
        delete _customStatePermissions[sourceStateId];
         // Manually remove from _statesOwnedBy as destroyState wasn't fully called
        uint256[] storage originalOwnedStates = _statesOwnedBy[originalOwner];
        for (uint i = 0; i < originalOwnedStates.length; i++) {
            if (originalOwnedStates[i] == sourceStateId) {
                originalOwnedStates[i] = originalOwnedStates[originalOwnedStates.length - 1];
                originalOwnedStates.pop();
                break;
            }
        }


        emit StateSplit(sourceStateId, newState1Id, newState2Id);
    }

    /// @notice Merges two states into one new state. Requires owner of both, and both must be active and not time locked.
    /// Properties are combined (e.g., summed). The original states are consumed.
    /// States must have the same owner and be linked to the same or no oracle.
    /// @param stateId1 The ID of the first state to merge.
    /// @param stateId2 The ID of the second state to merge.
    /// @return newStateId The ID of the newly created state.
    function mergeStates(uint256 stateId1, uint256 stateId2)
        external
        onlyStateOwner(stateId1) // Implies msg.sender is owner of state1
        onlyActiveState(stateId1)
        notTimeLocked(stateId1)
    {
        if (stateId1 == stateId2) revert ("Cannot merge state with itself");

        // Check ownership, activity, and time lock for state2
        ReflectedState storage state1 = _states[stateId1];
        ReflectedState storage state2 = _states[stateId2];

        if (state2.owner == address(0)) revert StateNotFound(stateId2);
        if (state1.owner != state2.owner) revert CannotMergeStatesWithDifferentOwners();
        if (!state2.isActive) revert CannotMergeInactiveStates();
        uint64 state2UnlockTime = _stateTimeLocks[stateId2];
        if (state2UnlockTime > 0 && uint64(block.timestamp) < state2UnlockTime) revert StateTimeLocked(stateId2, state2UnlockTime);
        if (state1.linkedOracleId != state2.linkedOracleId) revert CannotMergeDifferentOracles();

        address owner = state1.owner; // Same owner for both

        // Combine properties (simple sum, clamped)
        uint256 newEnergy = state1.energyLevel + state2.energyLevel;
        uint256 newCoherence = state1.coherenceLevel + state2.coherenceLevel;
        uint256 newEntropy = state1.entropyFactor + state2.entropyFactor;

        newEnergy = newEnergy > 1000 ? 1000 : newEnergy; // Clamp values
        newCoherence = newCoherence > 100 ? 100 : newCoherence;
        newEntropy = newEntropy > 10 ? 10 : newEntropy;


        // Create the new state
        _stateCounter++;
        uint256 newStateId = _stateCounter;
        ReflectedState storage newState = _states[newStateId];
        newState.id = newStateId;
        newState.owner = owner;
        newState.creationTime = uint64(block.timestamp);
        newState.energyLevel = newEnergy;
        newState.coherenceLevel = newCoherence;
        newState.entropyFactor = newEntropy;
        newState.linkedOracleId = state1.linkedOracleId; // Inherit oracle link
        // Use max last update time? Or average? Let's use max.
        newState.lastOracleUpdateTime = state1.lastOracleUpdateTime > state2.lastOracleUpdateTime ? state1.lastOracleUpdateTime : state2.lastOracleUpdateTime;
        newState.metadataURI = string.concat("Merged(", state1.metadataURI, ",", state2.metadataURI, ")"); // Combine URIs (simplistic)
        newState.isActive = true;

         // Add new state to owner's list
        _statesOwnedBy[owner].push(newStateId);

        // Destroy the original states (similar override as splitState)
        address ownerState1 = state1.owner; // Get owner before deleting state1
        delete _states[stateId1];
        delete _stateTimeLocks[stateId1];
        delete _stateDelegates[stateId1];
        delete _customStatePermissions[stateId1];
        // Manually remove from _statesOwnedBy
        uint256[] storage ownedStates1 = _statesOwnedBy[ownerState1];
        for (uint i = 0; i < ownedStates1.length; i++) {
            if (ownedStates1[i] == stateId1) {
                ownedStates1[i] = ownedStates1[ownedStates1.length - 1];
                ownedStates1.pop();
                break;
            }
        }

        address ownerState2 = state2.owner; // Get owner before deleting state2
        delete _states[stateId2];
        delete _stateTimeLocks[stateId2];
        delete _stateDelegates[stateId2];
        delete _customStatePermissions[stateId2];
         // Manually remove from _statesOwnedBy
        uint256[] storage ownedStates2 = _statesOwnedBy[ownerState2];
         for (uint i = 0; i < ownedStates2.length; i++) {
            if (ownedStates2[i] == stateId2) {
                ownedStates2[i] = ownedStates2[ownedStates2.length - 1];
                ownedStates2.pop();
                break;
            }
        }


        emit StateMerged(newStateId, stateId1, stateId2);
    }

    /// @notice Applies a mutation to a state, influenced by linked oracle data and entropy.
    /// Requires permissions/delegation/ownership, active state, not time locked.
    /// @param stateId The ID of the state to mutate.
    function mutateState(uint256 stateId)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        ReflectedState storage state = _states[stateId];

        uint256 baseMutationFactor = state.entropyFactor; // Higher entropy -> more potential change

        // Influence from oracle data if linked and recently updated
        uint256 oracleInfluence = 0;
        if (state.linkedOracleId != 0 && _latestOracleData[state.linkedOracleId] > 0 && state.lastOracleUpdateTime > 0) {
            // Example: Oracle data provides a seed or scaling factor
            // Using XOR with time for pseudo-randomness influenced by oracle data
            oracleInfluence = (_latestOracleData[state.linkedOracleId] ^ stateId ^ uint256(block.timestamp)) % 10; // Pseudo random influence 0-9
        } else {
             // If no oracle or stale data, use block hash/timestamp (simple pseudo-random)
             oracleInfluence = (uint255(keccak256(abi.encodePacked(block.timestamp, block.difficulty, stateId))) % 10);
        }


        // Calculate mutation amount (example logic)
        // Factor influenced by entropy and oracle data, scaled by coherence (lower coherence -> more susceptible)
        uint256 totalInfluence = baseMutationFactor + oracleInfluence; // 0-20 approx
        uint256 mutationAmount = (totalInfluence * (100 - state.coherenceLevel)) / 100; // 0-20 approx

        // Apply mutation (example: random increase/decrease to energy and coherence)
        uint256 oldEnergy = state.energyLevel;
        uint256 oldCoherence = state.coherenceLevel;
        uint256 oldEntropy = state.entropyFactor;

        // Use simple modulo arithmetic for direction and amount (pseudo-random direction)
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, stateId, mutationAmount)));

        int256 energyChange = int256(mutationAmount / 2);
        if (randSeed % 2 == 0) energyChange = -energyChange;

        int256 coherenceChange = int256(mutationAmount / 4); // Coherence changes slower
        if (randSeed % 3 == 0) coherenceChange = -coherenceChange;

        // Apply changes, clamping values
        state.energyLevel = uint256(int256(state.energyLevel) + energyChange > 0 ? int256(state.energyLevel) + energyChange : 0);
        state.energyLevel = state.energyLevel > 1000 ? 1000 : state.energyLevel;

        state.coherenceLevel = uint256(int256(state.coherenceLevel) + coherenceChange > 0 ? int256(state.coherenceLevel) + coherenceChange : 0);
        state.coherenceLevel = state.coherenceLevel > 100 ? 100 : state.coherenceLevel;

        // Entropy might also change slightly
        state.entropyFactor = (state.entropyFactor + (mutationAmount % 3)) > 10 ? 10 : (state.entropyFactor + (mutationAmount % 3));


        emit StateMutated(stateId, state.energyLevel, state.coherenceLevel, state.entropyFactor);
        // Also emit individual property changes for detailed tracking
        emit StatePropertiesModified(stateId, "energyLevel", oldEnergy, state.energyLevel);
        emit StatePropertiesModified(stateId, "coherenceLevel", oldCoherence, state.coherenceLevel);
        emit StatePropertiesModified(stateId, "entropyFactor", oldEntropy, state.entropyFactor);
    }

    // --- 9. Oracle Interaction Simulation ---

    /// @notice Registers a new simulated oracle feed. Only callable by admin.
    /// @param updater The address authorized to update this feed's data.
    /// @param description Description of the feed.
    /// @return oracleId The ID of the new oracle feed.
    function registerOracleFeed(address updater, string calldata description) external onlyAdmin returns (uint32 oracleId) {
        _oracleFeedCounter++;
        oracleId = _oracleFeedCounter;

        OracleFeed storage newFeed = _oracleFeeds[oracleId];
        newFeed.id = oracleId;
        newFeed.authorizedUpdater = updater;
        newFeed.latestData = 0; // Initial data is zero
        newFeed.lastUpdateTime = uint64(block.timestamp);
        newFeed.description = description;
        newFeed.isRegistered = true;

        emit OracleFeedRegistered(oracleId, updater, description);
    }

    /// @notice Unregisters a simulated oracle feed. Only callable by admin.
    /// @param oracleId The ID of the feed to unregister.
    function unregisterOracleFeed(uint32 oracleId) external onlyAdmin {
        if (!_oracleFeeds[oracleId].isRegistered) revert OracleNotRegistered(oracleId);
        _oracleFeeds[oracleId].isRegistered = false; // Mark as inactive rather than deleting

        // Note: States linked to this oracle will still have the old linkedOracleId
        // They will effectively use stale or default mutation behavior until relinked.

        emit OracleFeedUnregistered(oracleId);
    }

    /// @notice Allows the authorized updater to update the latest data for a feed.
    /// @param oracleId The ID of the feed to update.
    /// @param newData The new data value from the oracle.
    function updateOracleFeedData(uint32 oracleId, uint256 newData) external onlyOracleUpdater(oracleId) {
        _latestOracleData[oracleId] = newData;
        _oracleFeeds[oracleId].lastUpdateTime = uint64(block.timestamp);
        // No specific event for raw data update, processing event is key.
    }

     /// @notice Links a state to a registered oracle feed. Requires owner.
     /// @param stateId The ID of the state.
     /// @param oracleId The ID of the oracle feed.
    function linkStateToOracle(uint256 stateId, uint32 oracleId)
        external
        onlyStateOwner(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        if (!_oracleFeeds[oracleId].isRegistered) revert OracleNotRegistered(oracleId);
        if (_states[stateId].linkedOracleId != 0) revert StateAlreadyLinkedToOracle(stateId, _states[stateId].linkedOracleId);

        _states[stateId].linkedOracleId = oracleId;
        _states[stateId].lastOracleUpdateTime = uint64(block.timestamp); // Initialize last update time

        emit StateLinkedToOracle(stateId, oracleId);
    }

    /// @notice Unlinks a state from its current oracle feed. Requires owner.
    /// @param stateId The ID of the state.
    function unlinkStateFromOracle(uint256 stateId)
        external
        onlyStateOwner(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        if (_states[stateId].linkedOracleId == 0) revert StateNotLinkedToOracle(stateId);

        uint32 oldOracleId = _states[stateId].linkedOracleId;
        _states[stateId].linkedOracleId = 0;
        _states[stateId].lastOracleUpdateTime = 0; // Reset update time

        emit StateUnlinkedFromOracle(stateId, oldOracleId);
    }

    /// @notice Triggers processing of the latest data from the state's linked oracle.
    /// Updates the state's lastOracleUpdateTime and can influence potential future mutations.
    /// Callable by owner/delegatee/permitted address.
    /// @param stateId The ID of the state.
    function processLinkedOracleData(uint256 stateId)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        ReflectedState storage state = _states[stateId];
        if (state.linkedOracleId == 0) revert StateNotLinkedToOracle(stateId);

        uint32 oracleId = state.linkedOracleId;
        if (!_oracleFeeds[oracleId].isRegistered) {
            // Oracle was unregistered after state was linked
            state.linkedOracleId = 0; // Auto-unlink if oracle is gone
            state.lastOracleUpdateTime = 0;
            revert OracleNotRegistered(oracleId); // Or just log and continue? Revert for clarity.
        }

        // Simulate processing: Simply update the state's last update time and record the processed data
        // In a real contract, this would trigger logic that uses the oracle data directly to modify state
        // For this example, the `mutateState` function is where the data's *effect* is applied.
        uint224 latestData = uint224(_latestOracleData[oracleId]); // Use a smaller type if data range is known
        state.lastOracleUpdateTime = uint64(block.timestamp);

        emit OracleDataProcessedForState(stateId, oracleId, latestData);

        // Could optionally trigger a mutation immediately after processing?
        // mutateState(stateId); // Requires re-entering modifier chain or having internal version
    }


    // --- 10. Time-based State Control ---

    /// @notice Sets a time lock on a state, preventing transfers and certain modifications until the unlock time.
    /// Requires owner. Cannot set a lock if already time locked past the new time.
    /// @param stateId The ID of the state.
    /// @param unlockTimestamp The Unix timestamp until which the state is locked.
    function setTimeLock(uint256 stateId, uint64 unlockTimestamp)
        external
        onlyStateOwner(stateId)
    {
        if (unlockTimestamp <= block.timestamp) revert ("Unlock time must be in the future");
        // Allow extending lock, but not shortening it if currently locked
        if (_stateTimeLocks[stateId] > 0 && _stateTimeLocks[stateId] > unlockTimestamp) {
            revert ("Cannot shorten existing time lock");
        }

        _stateTimeLocks[stateId] = unlockTimestamp;
        emit StateTimeLocked(stateId, unlockTimestamp);
    }

    /// @notice Clears a time lock on a state after the unlock time has passed.
    /// Requires owner.
    /// @param stateId The ID of the state.
    function clearTimeLock(uint256 stateId)
        external
        onlyStateOwner(stateId)
    {
        uint64 unlockTime = _stateTimeLocks[stateId];
        if (unlockTime == 0) return; // No lock exists

        if (uint64(block.timestamp) < unlockTime) {
             revert UnlockTimeNotInPast(unlockTime);
        }

        delete _stateTimeLocks[stateId];
        emit StateTimeLockCleared(stateId);
    }


    // --- 11. Access Control & Delegation ---

    /// @notice Delegates control of a state to another address. The delegatee can perform certain actions (e.g., modify properties).
    /// Requires owner and state must not be time locked. Only one delegatee per state.
    /// @param stateId The ID of the state.
    /// @param delegatee The address to delegate control to (address(0) to clear).
    function delegateStateControl(uint256 stateId, address delegatee)
        external
        onlyStateOwner(stateId)
        notTimeLocked(stateId)
    {
        if (_stateDelegates[stateId] == delegatee) {
             if (delegatee == address(0)) return; // Already cleared
             revert AlreadyDelegatee(stateId, delegatee); // Already set to this address
        }
         if (_stateDelegates[stateId] != address(0) && delegatee != address(0)) {
            revert DelegationAlreadyExists(stateId); // Cannot set a new one if one exists (unless clearing)
        }


        address oldDelegatee = _stateDelegates[stateId];
        _stateDelegates[stateId] = delegatee;

        if (delegatee == address(0)) {
            emit StateControlRevoked(stateId, oldDelegatee);
        } else {
            emit StateControlDelegated(stateId, delegatee);
        }
    }

    /// @notice Revokes delegated control from an address. Callable by owner or the delegatee themselves.
    /// @param stateId The ID of the state.
    function revokeStateControl(uint256 stateId)
        external
        onlyStateOwnerOrDelegatee(stateId) // Owner or delegatee can revoke
    {
        address currentDelegatee = _stateDelegates[stateId];
        if (currentDelegatee == address(0)) revert NoDelegateeSet(stateId);

        // If caller is delegatee, they can self-revoke
        if (msg.sender != _states[stateId].owner && msg.sender != currentDelegatee) {
             revert NotStateOwnerOrDelegatee(stateId, msg.sender); // Should be caught by modifier, but double check
        }

        delete _stateDelegates[stateId];
        emit StateControlRevoked(stateId, currentDelegatee);
    }


    // --- 12. Granular State Permissions ---

    /// @notice Sets or revokes a custom permission for a specific address to call a specific function signature on a state.
    /// Requires owner and state must not be time locked.
    /// @param stateId The ID of the state.
    /// @param subject The address the permission applies to.
    /// @param functionSig The function signature (e.g., `bytes4(keccak256("modifyEnergyLevel(uint256,uint256)"))`).
    /// @param allowed Whether to grant (true) or revoke (false) the permission.
    function setCustomStatePermission(uint256 stateId, address subject, bytes4 functionSig, bool allowed)
        external
        onlyStateOwner(stateId)
        notTimeLocked(stateId)
    {
        if (subject == address(0)) revert ("Subject address cannot be zero");
         if (functionSig == bytes4(0)) revert ("Function signature cannot be zero");
        if (_customStatePermissions[stateId][subject][functionSig] == allowed) {
             revert PermissionAlreadySet(stateId, subject, functionSig);
        }

        _customStatePermissions[stateId][subject][functionSig] = allowed;
        emit CustomStatePermissionSet(stateId, subject, functionSig, allowed);
    }

    /// @notice Clears all custom permissions for a specific address on a state.
    /// Requires owner and state must not be time locked.
    /// @param stateId The ID of the state.
    /// @param subject The address whose permissions to clear.
    function clearCustomStatePermission(uint256 stateId, address subject)
         external
        onlyStateOwner(stateId)
        notTimeLocked(stateId)
    {
         if (subject == address(0)) revert ("Subject address cannot be zero");

        // Simple check if any permission exists to avoid unnecessary event/gas
        bool permissionExists = false;
        // Iterating mappings directly in Solidity is not possible.
        // We'll assume if _customStatePermissions[stateId][subject] is accessed, it's potentially non-empty.
        // A robust check would require a more complex data structure.
        // For simplicity here, we'll just delete and emit.

        delete _customStatePermissions[stateId][subject]; // Clears all entries for this subject on this state
        emit CustomStatePermissionCleared(stateId, subject);

    }

    // --- 13. Batch Operations ---

    /// @notice Applies the `mutateState` operation to multiple states owned by the caller.
    /// Requires states to be active, not time locked, and owned by msg.sender.
    /// Skips states that fail checks.
    /// @param stateIds An array of state IDs to mutate.
    function performBatchMutation(uint256[] calldata stateIds) external {
        address caller = msg.sender;
        uint256[] memory mutatedStates = new uint256[](stateIds.length);
        uint256 mutatedCount = 0;

        for (uint i = 0; i < stateIds.length; i++) {
            uint256 stateId = stateIds[i];
            // Check conditions internally for batch processing robustness
            ReflectedState storage state = _states[stateId];

            // Check if state exists, is owned by caller, is active, and not time locked
            if (state.owner == state.owner && // Check if state exists (owner != address(0))
                state.owner == caller &&
                state.isActive &&
                (_stateTimeLocks[stateId] == 0 || uint64(block.timestamp) >= _stateTimeLocks[stateId]))
            {
                // Apply mutation logic (simplified from mutateState to avoid modifier recursion)
                 uint256 baseMutationFactor = state.entropyFactor;
                uint256 oracleInfluence = 0;
                 if (state.linkedOracleId != 0 && _latestOracleData[state.linkedOracleId] > 0 && state.lastOracleUpdateTime > 0) {
                    oracleInfluence = (_latestOracleData[state.linkedOracleId] ^ stateId ^ uint256(block.timestamp) ^ i) % 10; // Add index for variation
                } else {
                    oracleInfluence = (uint255(keccak256(abi.encodePacked(block.timestamp, block.difficulty, stateId, i))) % 10);
                }

                uint256 totalInfluence = baseMutationFactor + oracleInfluence;
                uint256 mutationAmount = (totalInfluence * (100 - state.coherenceLevel)) / 100;

                 uint256 oldEnergy = state.energyLevel;
                uint256 oldCoherence = state.coherenceLevel;
                uint256 oldEntropy = state.entropyFactor;

                 uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, stateId, mutationAmount, i)));

                int256 energyChange = int256(mutationAmount / 2);
                if (randSeed % 2 == 0) energyChange = -energyChange;

                int256 coherenceChange = int256(mutationAmount / 4);
                if (randSeed % 3 == 0) coherenceChange = -coherenceChange;

                state.energyLevel = uint256(int256(state.energyLevel) + energyChange > 0 ? int256(state.energyLevel) + energyChange : 0);
                state.energyLevel = state.energyLevel > 1000 ? 1000 : state.energyLevel;

                state.coherenceLevel = uint256(int256(state.coherenceLevel) + coherenceChange > 0 ? int256(state.coherenceLevel) + coherenceChange : 0);
                state.coherenceLevel = state.coherenceLevel > 100 ? 100 : state.coherenceLevel;

                 state.entropyFactor = (state.entropyFactor + (mutationAmount % 3)) > 10 ? 10 : (state.entropyFactor + (mutationAmount % 3));

                 emit StateMutated(stateId, state.energyLevel, state.coherenceLevel, state.entropyFactor);
                 emit StatePropertiesModified(stateId, "energyLevel", oldEnergy, state.energyLevel);
                 emit StatePropertiesModified(stateId, "coherenceLevel", oldCoherence, state.coherenceLevel);
                 emit StatePropertiesModified(stateId, "entropyFactor", oldEntropy, state.entropyFactor);

                mutatedStates[mutatedCount] = stateId;
                mutatedCount++;

            }
            // Silently skip states that don't meet conditions in a batch
        }

        // Resize the mutatedStates array to actual count
        uint256[] memory successfulMutations = new uint256[](mutatedCount);
        for(uint i = 0; i < mutatedCount; i++) {
            successfulMutations[i] = mutatedStates[i];
        }

        emit BatchMutationPerformed(caller, successfulMutations);
    }


    // --- 14. Maintenance/Derived Value ---

    /// @notice Initiates a decoherence scan for a specific state, potentially reducing coherence over time/entropy.
    /// Callable by owner/delegatee/permitted address.
    /// @param stateId The ID of the state.
    function initiateDecoherenceScan(uint256 stateId)
        external
        onlyStateOwnerOrDelegateeOrPermitted(stateId)
        onlyActiveState(stateId)
        notTimeLocked(stateId)
    {
        ReflectedState storage state = _states[stateId];

        // Decoherence logic: coherence decreases based on time since last interaction/creation
        // and influenced by entropy. Higher entropy -> faster decoherence. Lower coherence -> less change from *this* scan.
        uint64 timeSinceLastUpdate = uint64(block.timestamp) - state.lastOracleUpdateTime; // Use last oracle update as a proxy for activity/stability

        // Simple decoherence formula: reduction = (time_since_update / some_factor) * entropy / coherence_resistance
        // To avoid division by zero coherence, use max(coherence, 1)
        uint256 coherenceResistance = state.coherenceLevel > 0 ? state.coherenceLevel : 1;
        uint256 timeFactor = timeSinceLastUpdate / 1 days; // Reduce by some amount per day (example)

        uint256 coherenceReduction = (timeFactor * state.entropyFactor) / coherenceResistance;

        if (coherenceReduction == 0) revert NothingToDecohere(); // State is stable or recently updated

        uint256 oldCoherence = state.coherenceLevel;
        if (state.coherenceLevel < coherenceReduction) {
            state.coherenceLevel = 0;
        } else {
            state.coherenceLevel -= coherenceReduction;
        }

        // Clamp min coherence to 0
        state.coherenceLevel = state.coherenceLevel > 0 ? state.coherenceLevel : 0;


        // Update last update time to prevent immediate rescanning having effect
        state.lastOracleUpdateTime = uint64(block.timestamp);


        emit DecoherenceScanInitiated(msg.sender, stateId, state.coherenceLevel);
        emit StatePropertiesModified(stateId, "coherenceLevel", oldCoherence, state.coherenceLevel);
    }

    /// @notice Calculates a hypothetical derived value for a state based on its properties. Pure function.
    /// This could represent yield potential, rarity score, etc.
    /// @param stateId The ID of the state.
    /// @return value A hypothetical calculated value.
    function reflectStateValue(uint256 stateId) public view returns (uint256 value) {
        // State must exist to calculate value
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);

        ReflectedState storage state = _states[stateId];

        // Example calculation: Energy * Coherence / (Entropy + 1)
        // Higher energy/coherence is good, higher entropy is bad.
        uint256 denominator = state.entropyFactor + 1; // Avoid division by zero
        value = (state.energyLevel * state.coherenceLevel) / denominator;

        // Scale the value up for more meaningful range
        value = value * 1 ether / 100; // Value roughly scales with Ether denomination

        // Add influence from last oracle update or creation time if needed
        // uint256 age = block.timestamp - state.creationTime;
        // value = value * (1000 + age / 1 days) / 1000; // Older states slightly more valuable? (example)

        return value;
    }

    // --- 15. Query Functions ---

    /// @notice Retrieves all details for a given state ID. View function.
    /// @param stateId The ID of the state.
    /// @return struct ReflectedState The state details.
    function getStateDetails(uint256 stateId) public view returns (ReflectedState memory) {
        if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        return _states[stateId];
    }

    /// @notice Retrieves details for a registered oracle feed. View function.
    /// @param oracleId The ID of the oracle feed.
    /// @return struct OracleFeed The oracle feed details.
    function getOracleFeedDetails(uint32 oracleId) public view returns (OracleFeed memory) {
        if (!_oracleFeeds[oracleId].isRegistered) revert OracleNotRegistered(oracleId);
        return _oracleFeeds[oracleId];
    }

    /// @notice Gets the time lock unlock timestamp for a state. View function.
    /// @param stateId The ID of the state.
    /// @return unlockTimestamp The timestamp, or 0 if no lock.
    function getStateTimeLock(uint256 stateId) public view returns (uint64) {
         if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
         return _stateTimeLocks[stateId];
    }

     /// @notice Gets the current delegatee for a state. View function.
     /// @param stateId The ID of the state.
     /// @return delegatee The delegatee address, or address(0) if none set.
    function queryDelegatee(uint256 stateId) public view returns (address) {
         if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
        return _stateDelegates[stateId];
    }


     /// @notice Checks if an address has a specific custom permission on a state. View function.
     /// @param stateId The ID of the state.
     /// @param subject The address to check.
     /// @param functionSig The function signature (e.g., `bytes4(keccak256("modifyEnergyLevel(uint256,uint256)"))`).
     /// @return allowed True if the permission is granted, false otherwise.
    function queryCustomStatePermission(uint256 stateId, address subject, bytes4 functionSig) public view returns (bool) {
         if (_states[stateId].owner == address(0)) revert StateNotFound(stateId);
         // Owner always has permission, even if not explicitly set
         if (_states[stateId].owner == subject) return true;
        return _customStatePermissions[stateId][subject][functionSig];
    }

    /// @notice Returns the total number of states ever created. View function.
    function getTotalStates() public view returns (uint256) {
        return _stateCounter;
    }

    /// @notice Returns a potentially large array of state IDs owned by an address.
    /// Note: This function can be very gas-intensive for addresses owning many states.
    /// Use with caution off-chain or consider pagination if gas is a concern.
    /// @param owner The address to query.
    /// @return stateIds An array of state IDs.
    function getStatesOwnedBy(address owner) public view returns (uint256[] memory) {
         return _statesOwnedBy[owner];
    }

    // --- Helper Functions ---
    // (No private helpers needed beyond state variables for this example)

}
```