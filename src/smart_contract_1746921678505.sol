Okay, here is a Solidity smart contract concept called "Quantum Vault", which manages complex, time-locked, and state-dependent interactions with deposited digital assets (simulated NFTs and a custom "Catalyst" token for operations).

This contract aims to be creative and avoid direct duplication of standard open-source implementations by introducing custom concepts like asset entanglement, state shifting, temporal resonance accumulation, and a multi-conditional "Singularity Event".

**Outline:**

1.  **Contract Purpose:** Manage deposits of simulated ERC-721 tokens ("Quantum Shards") and a simulated ERC-20 token ("Catalyst") to perform complex, state-dependent operations.
2.  **Core Concepts:**
    *   **Internal NFT Representation:** Handles simulated ERC-721s ("Quantum Shards") internally with unique IDs, state, and properties.
    *   **Catalyst Token:** A simulated ERC-20 used as a fee/resource for advanced operations.
    *   **NFT States:** Each "Quantum Shard" can be in various states (Dormant, Active, Shifting, Locked), each with specific properties and transition rules.
    *   **Entanglement:** Pairs of "Quantum Shards" can be linked, making actions on one potentially affect the other.
    *   **Temporal Resonance:** A points system accumulated by Shards based on their state and duration within that state.
    *   **Quantum Locking:** Time-locking Shards for a specific duration to enable certain states or earn resonance faster.
    *   **Dimensional Transfer:** Consuming Catalyst and specific Shards to transform them into a different type or level of Shard.
    *   **Refraction:** Breaking an Entanglement Pair, potentially with consequences or rewards.
    *   **Singularity Event:** A rare, complex function triggered when multiple conditions (Shard states, Catalyst supply, Oracle value) are met, resulting in significant state changes or rewards for qualifying Shards.
    *   **Oracle Influence:** External simulated oracle data influencing the conditions for the Singularity Event.
3.  **Key Data Structures:**
    *   `NFTState`: Struct for internal Shard data (external contract/ID, current state, state start time, lock end time, resonance points, owner, entanglement pair ID).
    *   `EntanglementPair`: Struct linking two internal Shard IDs.
    *   Mappings for internal ID to State, Owner to internal IDs, internal ID to Pair ID, Pair ID to Shard IDs.
    *   Mapping for Catalyst balances.
4.  **Function Categories (25+):**
    *   **Core Vault Management:** Deposit/Withdraw Shards, Inject Catalyst.
    *   **NFT State Management:** Shift State (Dormant, Active, Shifting), Get current state/details.
    *   **Entanglement Management:** Create/Break Entanglement Pairs, Check entanglement status.
    *   **Quantum Locking:** Start/End Lock, Check lock status.
    *   **Temporal Resonance:** Claim Points, Check balances.
    *   **Advanced Operations:** Dimensional Transfer, Refract Pair, Trigger Singularity Event, Check Singularity conditions.
    *   **Utility/Views:** Get Shard details by internal/external ID, Get owner's Shards, Check balances, Get Oracle value.
    *   **Owner Functions:** Update Oracle Value (in simulation).
    *   **Internal Transfer:** Transfer Shard ownership *within* the vault.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets owner (simulated).
2.  `depositQuantumShard(address _shardContract, uint256 _externalTokenId)`: Deposits a simulated external Quantum Shard into the vault, creating an internal representation.
3.  `withdrawQuantumShard(uint256 _internalShardId)`: Withdraws a Quantum Shard from the vault back to the owner. Requires Shard to be in a withdrawable state (e.g., Dormant, not Locked/Entangled/Shifting).
4.  `injectCatalyst()`: Allows users to deposit simulated Catalyst tokens into their internal vault balance.
5.  `withdrawCatalyst(uint256 _amount)`: Allows users to withdraw their internal Catalyst balance.
6.  `createEntanglementPair(uint256 _shardId1, uint256 _shardId2)`: Creates an Entanglement Pair between two unentangled Shards owned by the caller. Requires Shards to be in eligible states.
7.  `breakEntanglementPair(uint256 _pairId)`: Breaks an existing Entanglement Pair. May have associated costs or state changes (e.g., both revert to Dormant).
8.  `shiftState(uint256 _internalShardId, uint8 _targetStateCode)`: Initiates or completes a state transition for a Shard. Requires specific current state, maybe Catalyst cost, and time elapsed for 'Shifting' state.
9.  `startQuantumLock(uint256 _internalShardId, uint64 _duration)`: Locks a Shard for a specified duration. Requires Shard to be in an eligible state.
10. `endQuantumLock(uint256 _internalShardId)`: Ends the lock on a Shard if the duration has passed. May change state.
11. `claimTemporalResonance(uint256 _internalShardId)`: Calculates and claims accumulated Temporal Resonance points for a Shard based on its state history.
12. `performDimensionalTransfer(uint256[] _sourceShardIds, uint8 _targetShardTypeCode)`: Consumes Catalyst and specified source Shards (based on type/state) to create a new, higher-level internal Shard representation.
13. `refractEntanglementPair(uint256 _pairId)`: A complex function to break an Entanglement Pair in a specific way, potentially splitting attributes or generating points, possibly consuming Catalyst.
14. `triggerSingularityEvent(uint256[] _potentialParticipatingShardIds)`: Attempts to trigger the rare Singularity Event. Checks global conditions (Oracle value, total Catalyst, specific states of participating Shards). If conditions met, applies effects (state changes, point boosts) to the participating Shards.
15. `updateOracleValue(uint256 _newValue)`: Owner-only function to update the simulated Oracle value, influencing Singularity Event conditions.
16. `getQuantumShardState(uint256 _internalShardId)`: View function to get the current state code of a Shard.
17. `isQuantumShardEntangled(uint256 _internalShardId)`: View function to check if a Shard is part of an Entanglement Pair.
18. `getEntanglementPair(uint256 _internalShardId)`: View function to get the Pair ID for an entangled Shard.
19. `getPairShardIds(uint256 _pairId)`: View function to get the two Shard IDs in a pair.
20. `getQuantumShardLockEndTime(uint256 _internalShardId)`: View function to get the timestamp when a Shard's lock ends.
21. `getTemporalResonancePoints(uint256 _internalShardId)`: View function to get the currently claimable Temporal Resonance points for a Shard.
22. `getTotalTemporalResonancePoints(address _owner)`: View function to get the total Temporal Resonance points across all Shards owned by an address.
23. `getCatalystBalance(address _owner)`: View function to get the internal Catalyst balance of an address.
24. `getQuantumShardDetails(uint256 _internalShardId)`: View function to get comprehensive details about an internal Shard.
25. `checkSingularityConditions()`: View function to check if the global conditions for the Singularity Event are currently met (does not trigger).
26. `transferInternalShard(uint256 _internalShardId, address _to)`: Transfers ownership of an internal Shard representation *within* the vault system.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Quantum Vault: Advanced Asset Management Contract ---
//
// Outline:
// 1. Contract Purpose: Manage deposits of simulated ERC-721 tokens ("Quantum Shards")
//    and a simulated ERC-20 token ("Catalyst") to perform complex, state-dependent operations.
// 2. Core Concepts: Internal NFT Representation, Catalyst Token, NFT States, Entanglement,
//    Temporal Resonance, Quantum Locking, Dimensional Transfer, Refraction, Singularity Event,
//    Oracle Influence.
// 3. Key Data Structures: NFTState, EntanglementPair, mappings for state, ownership, pairs, balances.
// 4. Function Categories: Core Vault, State Management, Entanglement, Locking, Resonance,
//    Advanced Ops, Utility/Views, Owner functions, Internal Transfer.
//
// Function Summary:
// - constructor: Initializes contract.
// - depositQuantumShard: Deposit simulated external NFT.
// - withdrawQuantumShard: Withdraw simulated external NFT.
// - injectCatalyst: Deposit simulated ERC-20 resource.
// - withdrawCatalyst: Withdraw simulated ERC-20 resource.
// - createEntanglementPair: Link two internal Shards.
// - breakEntanglementPair: Delink entangled Shards.
// - shiftState: Change a Shard's state based on rules.
// - startQuantumLock: Time-lock a Shard.
// - endQuantumLock: Release a Shard lock.
// - claimTemporalResonance: Claim points earned over time/state.
// - performDimensionalTransfer: Combine Shards/Catalyst into a new Shard type.
// - refractEntanglementPair: Complex pair breaking with potential outcomes.
// - triggerSingularityEvent: Attempt to trigger a rare, multi-conditional event.
// - updateOracleValue: Owner-only updates simulated oracle data.
// - getQuantumShardState: View Shard state.
// - isQuantumShardEntangled: View entanglement status.
// - getEntanglementPair: View pair ID.
// - getPairShardIds: View Shards in a pair.
// - getQuantumShardLockEndTime: View lock end time.
// - getTemporalResonancePoints: View claimable points for a Shard.
// - getTotalTemporalResonancePoints: View total points for an owner.
// - getCatalystBalance: View internal Catalyst balance.
// - getQuantumShardDetails: View all details for a Shard.
// - checkSingularityConditions: View if Singularity trigger conditions are met.
// - transferInternalShard: Transfer ownership of an internal Shard representation.
// - getInternalShardDetailsByExternal: View internal details from external info.

contract QuantumVault {

    // --- Data Structures ---

    enum ShardState {
        Dormant,    // Default state, minimal interaction
        Active,     // Engaged state, earns resonance, eligible for some ops
        Shifting,   // Transitioning between states (time-locked)
        Locked      // Explicitly time-locked, earns boosted resonance
    }

    struct QuantumShard {
        address externalContract; // Address of the original ERC721 contract
        uint256 externalTokenId;  // Token ID on the original ERC721 contract
        uint256 internalId;       // Unique ID within this vault
        address owner;            // Current owner within this vault system
        ShardState currentState;  // Current state of the shard
        uint64 stateStartTime;    // Timestamp when the current state began
        uint64 lockEndTime;       // Timestamp when Quantum Lock ends (0 if not locked)
        uint256 temporalResonancePoints; // Accumulated points
        uint256 entanglementPairId; // 0 if not entangled, otherwise ID of the pair
        // Add more properties like 'type', 'level' for Dimensional Transfer mechanics
        uint8 shardType;          // e.g., 1=Basic, 2=Advanced, 3=Exotic
    }

    struct EntanglementPair {
        uint256 shardId1;
        uint256 shardId2;
        uint64 creationTime;
    }

    // --- State Variables ---

    uint256 private _nextInternalShardId = 1;
    uint256 private _nextEntanglementPairId = 1;
    address private _owner; // Simple owner for oracle/config

    // Core Mappings
    mapping(uint255 => QuantumShard) private _internalShards; // Maps internal ID to Shard data
    mapping(address => uint256[]) private _ownerShards; // Maps owner address to list of internal Shard IDs
    mapping(uint256 => uint256) private _internalShardIndex; // Helper for _ownerShards lookup
    mapping(uint256 => uint256) private _shardIdToPairId; // Maps internal Shard ID to Pair ID
    mapping(uint256 => EntanglementPair) private _entanglementPairs; // Maps Pair ID to Pair data

    // Catalyst Token Simulation
    mapping(address => uint256) private _catalystBalances;
    uint256 public constant CATALYST_STATE_SHIFT_COST = 100; // Example cost
    uint256 public constant CATALYST_DIMENSIONAL_TRANSFER_BASE_COST = 500; // Example cost

    // Temporal Resonance Simulation
    mapping(ShardState => uint256) public resonancePointsPerSecond; // How many points per second per state
    mapping(uint256 => uint64) private _lastResonanceClaimTime; // Last time points were claimed for a shard

    // Oracle Simulation (Owner controlled)
    uint256 public simulatedOracleValue;
    uint256 public constant SINGULARITY_ORACLE_THRESHOLD_MIN = 77; // Example threshold
    uint256 public constant SINGULARITY_ORACLE_THRESHOLD_MAX = 150;

    // Singularity Event Simulation
    uint256 public constant SINGULARITY_CATALYST_POOL_THRESHOLD = 10000; // Total Catalyst needed in contract
    mapping(uint8 => uint256) public singularityRequiredShardCount; // Min shards of specific type/state

    // --- Events ---

    event ShardDeposited(address indexed owner, uint256 internalShardId, address indexed externalContract, uint256 externalTokenId);
    event ShardWithdrawn(address indexed owner, uint256 internalShardId, address indexed externalContract, uint256 externalTokenId);
    event CatalystInjected(address indexed owner, uint256 amount);
    event CatalystWithdrawn(address indexed owner, uint256 amount);
    event EntanglementCreated(uint256 indexed pairId, uint256 indexed shardId1, uint256 indexed shardId2);
    event EntanglementBroken(uint256 indexed pairId, uint256 shardId1, uint256 shardId2);
    event ShardStateShifted(uint256 indexed internalShardId, ShardState fromState, ShardState toState);
    event QuantumLockStarted(uint256 indexed internalShardId, uint64 duration, uint64 endTime);
    event QuantumLockEnded(uint256 indexed internalShardId);
    event TemporalResonanceClaimed(uint256 indexed internalShardId, uint256 pointsClaimed, uint256 totalPoints);
    event DimensionalTransferOccurred(address indexed owner, uint256[] sourceShardIds, uint256 newShardId, uint8 newShardType);
    event RefractionOccurred(uint256 indexed pairId, uint256 shardId1, uint256 shardId2, uint256 outcomeValue); // OutcomeValue could be points/new asset ID etc.
    event SingularityEventTriggered(uint256 blockTimestamp, uint256 oracleValue, uint256 totalCatalystSupply);
    event InternalShardTransfer(uint256 indexed internalShardId, address indexed from, address indexed to);
    event OracleValueUpdated(uint256 newValue);

    // --- Constructor ---

    constructor() {
        _owner = msg.sender; // Simple owner model

        // Initialize resonance points per state (example values)
        resonancePointsPerSecond[ShardState.Dormant] = 1;
        resonancePointsPerSecond[ShardState.Active] = 5;
        resonancePointsPerSecond[ShardState.Shifting] = 2; // Lower during transition
        resonancePointsPerSecond[ShardState.Locked] = 10; // Boosted

        // Initialize singularity requirements (example: need 5 basic, 3 advanced, 1 exotic in specific states)
        singularityRequiredShardCount[1] = 5; // Basic
        singularityRequiredShardCount[2] = 3; // Advanced
        singularityRequiredShardCount[3] = 1; // Exotic
    }

    // --- Modifiers (Simple simulation of ownership/checks) ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not contract owner");
        _;
    }

    function _requireShardOwner(uint256 _internalShardId) internal view {
        require(_internalShards[_internalShardId].owner == msg.sender, "Not shard owner");
    }

    // --- Core Vault Management ---

    // Simulate depositing an external ERC721. In a real scenario, this would involve
    // ERC721 approve/transferFrom calls before or within this function.
    function depositQuantumShard(address _shardContract, uint256 _externalTokenId) public {
        // In a real contract, add logic to verify external NFT exists and transfer it here.
        // For this example, we just create the internal representation.

        uint256 internalId = _nextInternalShardId++;
        QuantumShard storage newShard = _internalShards[internalId];

        newShard.externalContract = _shardContract;
        newShard.externalTokenId = _externalTokenId;
        newShard.internalId = internalId;
        newShard.owner = msg.sender;
        newShard.currentState = ShardState.Dormant;
        newShard.stateStartTime = uint64(block.timestamp);
        newShard.lockEndTime = 0;
        newShard.temporalResonancePoints = 0;
        newShard.entanglementPairId = 0;
        newShard.shardType = 1; // Default to Basic type on deposit

        _addShardToOwnerList(msg.sender, internalId);
        _lastResonanceClaimTime[internalId] = uint64(block.timestamp); // Initialize claim time

        emit ShardDeposited(msg.sender, internalId, _shardContract, _externalTokenId);
    }

    // Simulate withdrawing an external ERC721. Requires shard to be in a withdrawable state.
    // In a real scenario, this would involve transferring the external NFT back.
    function withdrawQuantumShard(uint256 _internalShardId) public {
        _requireShardOwner(_internalShardId);
        QuantumShard storage shard = _internalShards[_internalShardId];

        // Requires specific states to withdraw - cannot withdraw if actively engaged
        require(shard.currentState == ShardState.Dormant, "Shard not in withdrawable state (Dormant required)");
        require(shard.lockEndTime <= block.timestamp, "Shard is locked");
        require(shard.entanglementPairId == 0, "Shard is entangled");

        address originalOwner = shard.owner; // Store before deleting state

        // Clean up internal state
        _removeShardFromOwnerList(originalOwner, _internalShardId);
        delete _internalShards[_internalShardId];
        delete _lastResonanceClaimTime[_internalShardId];
        // If it had a pair, breaking it would have already cleaned up the pair mapping

        // In a real contract, perform the external ERC721 transfer back to originalOwner here.

        emit ShardWithdrawn(originalOwner, _internalShardId, shard.externalContract, shard.externalTokenId);
    }

    // Simulate injecting Catalyst tokens. In a real scenario, this would involve
    // ERC20 approve/transferFrom calls.
    function injectCatalyst(uint256 _amount) public {
        require(_amount > 0, "Must inject non-zero amount");
        // In a real contract: require(_catalystToken.transferFrom(msg.sender, address(this), _amount));
        _catalystBalances[msg.sender] += _amount;
        emit CatalystInjected(msg.sender, _amount);
    }

    // Simulate withdrawing Catalyst tokens.
    function withdrawCatalyst(uint256 _amount) public {
        require(_amount > 0, "Must withdraw non-zero amount");
        require(_catalystBalances[msg.sender] >= _amount, "Insufficient Catalyst balance");
        _catalystBalances[msg.sender] -= _amount;
        // In a real contract: require(_catalystToken.transfer(msg.sender, _amount));
        emit CatalystWithdrawn(msg.sender, _amount);
    }

    // --- NFT State Management ---

    function shiftState(uint256 _internalShardId, uint8 _targetStateCode) public {
        _requireShardOwner(_internalShardId);
        QuantumShard storage shard = _internalShards[_internalShardId];
        ShardState targetState = ShardState(_targetStateCode);

        // Calculate elapsed time for 'Shifting' state completion
        uint64 timeInCurrentState = uint64(block.timestamp) - shard.stateStartTime;

        // State transition logic (example rules)
        if (shard.currentState == ShardState.Dormant) {
            require(targetState == ShardState.Active || targetState == ShardState.Locked, "Invalid state transition from Dormant");
            if (targetState == ShardState.Active) {
                // Simple transition to Active
                _updateShardState(_internalShardId, targetState);
            } else if (targetState == ShardState.Locked) {
                 revert("Use startQuantumLock to enter Locked state"); // Locked requires a specific function
            }
        } else if (shard.currentState == ShardState.Active) {
            require(targetState == ShardState.Dormant || targetState == ShardState.Shifting || targetState == ShardState.Locked, "Invalid state transition from Active");
            if (targetState == ShardState.Dormant) {
                 _updateShardState(_internalShardId, targetState);
            } else if (targetState == ShardState.Shifting) {
                 // Transition *to* Shifting, requires Catalyst
                 require(_catalystBalances[msg.sender] >= CATALYST_STATE_SHIFT_COST, "Insufficient Catalyst for Shifting state");
                 _catalystBalances[msg.sender] -= CATALYST_STATE_SHIFT_COST;
                 // In a real contract, transfer CATALYST_STATE_SHIFT_COST to contract/burn/distribute
                 _updateShardState(_internalShardId, ShardState.Shifting); // Shard enters the 'Shifting' state
                 // The actual target state is reached *after* the shifting duration via another call or trigger
            } else if (targetState == ShardState.Locked) {
                 revert("Use startQuantumLock to enter Locked state"); // Locked requires a specific function
            }
        } else if (shard.currentState == ShardState.Shifting) {
             // Transition *from* Shifting requires time elapsed
            require(timeInCurrentState >= 1 days, "Shard is still Shifting"); // Example: Shifting takes 1 day
            require(targetState == ShardState.Active || targetState == ShardState.Dormant, "Invalid state transition from Shifting");
            // Actual state change happens here after time passes
            _updateShardState(_internalShardId, targetState);

        } else if (shard.currentState == ShardState.Locked) {
            revert("Cannot shift state directly from Locked. Must end lock first.");
        } else {
             revert("Unknown shard state");
        }
    }

    // Internal helper to update state and track time/resonance
    function _updateShardState(uint256 _internalShardId, ShardState _newState) internal {
        QuantumShard storage shard = _internalShards[_internalShardId];
        require(shard.internalId != 0, "Invalid shard ID"); // Ensure shard exists

        ShardState oldState = shard.currentState;

        // Before changing state, calculate any accumulated resonance in the *old* state
        // and add it to the pending points.
        uint64 lastClaim = _lastResonanceClaimTime[_internalShardId];
        uint64 timeInOldState = uint64(block.timestamp) - (oldState == shard.currentState ? shard.stateStartTime : lastClaim); // Use stateStartTime unless it's the *initial* claim
        uint256 earnedPoints = (timeInOldState * resonancePointsPerSecond[oldState]);
        shard.temporalResonancePoints += earnedPoints;

        // Update state and state start time
        shard.currentState = _newState;
        shard.stateStartTime = uint64(block.timestamp);
        _lastResonanceClaimTime[_internalShardId] = uint64(block.timestamp); // Reset claim time for new state calculation

        emit ShardStateShifted(_internalShardId, oldState, _newState);
    }

    // --- Entanglement Management ---

    function createEntanglementPair(uint256 _shardId1, uint256 _shardId2) public {
        require(_shardId1 != _shardId2, "Cannot entangle a shard with itself");
        _requireShardOwner(_shardId1);
        _requireShardOwner(_shardId2);
        require(_internalShards[_shardId1].owner == _internalShards[_shardId2].owner, "Both shards must be owned by the same address");

        QuantumShard storage shard1 = _internalShards[_shardId1];
        QuantumShard storage shard2 = _internalShards[_shardId2];

        require(shard1.entanglementPairId == 0, "Shard 1 is already entangled");
        require(shard2.entanglementPairId == 0, "Shard 2 is already entangled");

        // Example rule: Only certain states can be entangled
        require(shard1.currentState == ShardState.Active || shard1.currentState == ShardState.Dormant, "Shard 1 must be Active or Dormant to entangle");
        require(shard2.currentState == ShardState.Active || shard2.currentState == ShardState.Dormant, "Shard 2 must be Active or Dormant to entangle");


        uint256 pairId = _nextEntanglementPairId++;
        _entanglementPairs[pairId] = EntanglementPair({
            shardId1: _shardId1,
            shardId2: _shardId2,
            creationTime: uint64(block.timestamp)
        });

        shard1.entanglementPairId = pairId;
        shard2.entanglementPairId = pairId;
        _shardIdToPairId[_shardId1] = pairId;
        _shardIdToPairId[_shardId2] = pairId;

        emit EntanglementCreated(pairId, _shardId1, _shardId2);
    }

    function breakEntanglementPair(uint256 _pairId) public {
        EntanglementPair storage pair = _entanglementPairs[_pairId];
        require(pair.shardId1 != 0, "Invalid pair ID"); // Check if pair exists

        // Either owner of shard1 or shard2 can break the pair
        require(_internalShards[pair.shardId1].owner == msg.sender || _internalShards[pair.shardId2].owner == msg.sender, "Not authorized to break this pair");

        uint256 shardId1 = pair.shardId1;
        uint256 shardId2 = pair.shardId2;

        QuantumShard storage shard1 = _internalShards[shardId1];
        QuantumShard storage shard2 = _internalShards[shardId2];

        // Example: Breaking entanglement might force states back to Dormant
        if (shard1.currentState != ShardState.Dormant) {
             _updateShardState(shardId1, ShardState.Dormant);
        }
        if (shard2.currentState != ShardState.Dormant) {
             _updateShardState(shardId2, ShardState.Dormant);
        }

        // Clean up mappings
        shard1.entanglementPairId = 0;
        shard2.entanglementPairId = 0;
        delete _shardIdToPairId[shardId1];
        delete _shardIdToPairId[shardId2];
        delete _entanglementPairs[_pairId];

        emit EntanglementBroken(_pairId, shardId1, shardId2);
    }

    // --- Quantum Locking ---

    function startQuantumLock(uint256 _internalShardId, uint64 _duration) public {
         require(_duration > 0, "Lock duration must be positive");
        _requireShardOwner(_internalShardId);
        QuantumShard storage shard = _internalShards[_internalShardId];

        require(shard.lockEndTime <= block.timestamp, "Shard is already locked");
        require(shard.currentState == ShardState.Active || shard.currentState == ShardState.Dormant, "Shard must be Active or Dormant to lock");
        require(shard.entanglementPairId == 0, "Cannot lock an entangled shard");

        uint64 newLockEndTime = uint64(block.timestamp) + _duration;
        shard.lockEndTime = newLockEndTime;

        // Immediately change state to Locked
        _updateShardState(_internalShardId, ShardState.Locked);

        emit QuantumLockStarted(_internalShardId, _duration, newLockEndTime);
    }

    function endQuantumLock(uint255 _internalShardId) public {
        _requireShardOwner(_internalShardId);
        QuantumShard storage shard = _internalShards[_internalShardId];

        require(shard.currentState == ShardState.Locked, "Shard is not in Locked state");
        require(shard.lockEndTime <= block.timestamp, "Lock duration has not passed yet");

        // End lock
        shard.lockEndTime = 0;

        // Automatically transition back to Active or Dormant (arbitrary rule)
        _updateShardState(_internalShardId, ShardState.Active); // Example: goes back to Active

        emit QuantumLockEnded(_internalShardId);
    }

    // --- Temporal Resonance ---

    function claimTemporalResonance(uint256 _internalShardId) public {
        _requireShardOwner(_internalShardId);
        QuantumShard storage shard = _internalShards[_internalShardId];

        uint64 lastClaim = _lastResonanceClaimTime[_internalShardId];
        uint64 timeSinceLastClaim = uint64(block.timestamp) - lastClaim;

        // Calculate points earned in the current state since the last claim/state change
        uint256 earnedPoints = (timeSinceLastClaim * resonancePointsPerSecond[shard.currentState]);

        // Add to accumulated points and reset timer
        shard.temporalResonancePoints += earnedPoints;
        _lastResonanceClaimTime[_internalShardId] = uint64(block.timestamp);

        emit TemporalResonanceClaimed(_internalShardId, earnedPoints, shard.temporalResonancePoints);
    }

    // --- Advanced Operations ---

    // Combines source shards and catalyst to create a new shard of a higher type.
    function performDimensionalTransfer(uint256[] memory _sourceShardIds, uint8 _targetShardTypeCode) public {
        require(_sourceShardIds.length > 0, "Must provide source shards");
        require(_targetShardTypeCode > 1, "Target type must be higher than Basic (1)"); // Can't transfer to Basic
        require(_targetShardTypeCode <= 3, "Invalid target shard type"); // Assuming types 1, 2, 3

        address owner = msg.sender;
        uint256 totalCatalystCost = CATALYST_DIMENSIONAL_TRANSFER_BASE_COST; // Base cost

        // Example logic: requires specific types and states for transformation
        uint256 basicCount = 0;
        uint256 advancedCount = 0;
        uint256 exoticCount = 0;

        // Validate sources and sum types
        for (uint i = 0; i < _sourceShardIds.length; i++) {
            uint256 shardId = _sourceShardIds[i];
            _requireShardOwner(shardId);
            QuantumShard storage sourceShard = _internalShards[shardId];

            require(sourceShard.currentState == ShardState.Active, "Source shards must be Active");
            require(sourceShard.entanglementPairId == 0, "Source shards cannot be entangled");
            require(sourceShard.lockEndTime <= block.timestamp, "Source shards cannot be locked");

            if (sourceShard.shardType == 1) basicCount++;
            else if (sourceShard.shardType == 2) advancedCount++;
            else if (sourceShard.shardType == 3) exoticCount++;
            else revert("Unknown source shard type"); // Should not happen with types 1-3
        }

        // Example transformation rules:
        if (_targetShardTypeCode == 2) { // Basic(s) -> Advanced
            require(basicCount >= 3, "Need at least 3 Basic shards to create Advanced");
            require(advancedCount == 0 && exoticCount == 0, "Only Basic shards allowed for Basic->Advanced transfer");
            totalCatalystCost += basicCount * 50; // Add cost per basic shard
        } else if (_targetShardTypeCode == 3) { // Basic + Advanced -> Exotic OR Advanced(s) -> Exotic
            require(basicCount >= 2 && advancedCount >= 1 || advancedCount >= 3, "Need (2 Basic + 1 Advanced) or (3 Advanced) to create Exotic");
             if (basicCount >= 2 && advancedCount >= 1) { /* valid combination */ }
             else if (advancedCount >= 3) { /* valid combination */ }
             else revert("Invalid combination of source shard types for Exotic");
            totalCatalystCost += (basicCount * 100) + (advancedCount * 200) + (exoticCount * 500); // Example variable cost
        } else {
            revert("Unsupported target shard type");
        }


        require(_catalystBalances[owner] >= totalCatalystCost, "Insufficient Catalyst for Dimensional Transfer");
        _catalystBalances[owner] -= totalCatalystCost;
        // In a real contract, transfer totalCatalystCost to contract/burn/distribute

        // Burn/remove the source shards from the vault system
        for (uint i = 0; i < _sourceShardIds.length; i++) {
             uint256 shardId = _sourceShardIds[i];
             _removeShardFromOwnerList(owner, shardId);
             delete _internalShards[shardId];
             delete _lastResonanceClaimTime[shardId];
             // Ensure cleanup if entangled (should be checked by 'require' above)
             if (_shardIdToPairId[shardId] != 0) {
                 // This should not happen if the require(sourceShard.entanglementPairId == 0) passes
                 // but as a safety: breakEntanglementPair(_shardIdToPairId[shardId]);
             }
             delete _shardIdToPairId[shardId]; // Explicitly remove mapping
        }

        // Create the new internal shard representation
        uint256 newInternalId = _nextInternalShardId++;
        QuantumShard storage newShard = _internalShards[newInternalId];

        // Simulate provenance - could store source IDs or aggregate properties
        newShard.externalContract = address(0); // New shard isn't from an external NFT directly
        newShard.externalTokenId = 0;
        newShard.internalId = newInternalId;
        newShard.owner = owner;
        newShard.currentState = ShardState.Dormant; // Starts in Dormant state
        newShard.stateStartTime = uint64(block.timestamp);
        newShard.lockEndTime = 0;
        newShard.temporalResonancePoints = 0; // New shard starts with 0 points
        newShard.entanglementPairId = 0;
        newShard.shardType = _targetShardTypeCode; // Set the new type

        _addShardToOwnerList(owner, newInternalId);
         _lastResonanceClaimTime[newInternalId] = uint64(block.timestamp); // Initialize claim time


        emit DimensionalTransferOccurred(owner, _sourceShardIds, newInternalId, _targetShardTypeCode);
    }


    // Breaks an entanglement pair in a complex way, potentially based on duration or other factors.
    function refractEntanglementPair(uint256 _pairId) public {
        EntanglementPair storage pair = _entanglementPairs[_pairId];
        require(pair.shardId1 != 0, "Invalid pair ID");

        // Either owner of shard1 or shard2 can trigger refraction
        require(_internalShards[pair.shardId1].owner == msg.sender || _internalShards[pair.shardId2].owner == msg.sender, "Not authorized to refract this pair");

        uint256 shardId1 = pair.shardId1;
        uint256 shardId2 = pair.shardId2;

        // Example logic: Refraction requires Catalyst and affects resonance/states
        uint256 refractionCost = 200; // Example cost
        require(_catalystBalances[msg.sender] >= refractionCost, "Insufficient Catalyst for Refraction");
        _catalystBalances[msg.sender] -= refractionCost;
         // In a real contract, transfer refractionCost to contract/burn/distribute

        QuantumShard storage shard1 = _internalShards[shardId1];
        QuantumShard storage shard2 = _internalShards[shardId2];

        // Calculate bonus/penalty based on how long they were entangled (example)
        uint64 entanglementDuration = uint64(block.timestamp) - pair.creationTime;
        uint256 outcomeValue = 0; // Could be points added, or ID of a new minor asset

        if (entanglementDuration >= 7 days) { // Bonus for long entanglement
            uint256 bonusPoints = entanglementDuration / (1 days) * 50; // 50 bonus points per week
            shard1.temporalResonancePoints += bonusPoints;
            shard2.temporalResonancePoints += bonusPoints;
            outcomeValue = bonusPoints * 2; // Report total bonus points
        } else { // Penalty for short entanglement
            uint256 penaltyPoints = 100; // Example penalty
            if (shard1.temporalResonancePoints < penaltyPoints) shard1.temporalResonancePoints = 0; else shard1.temporalResonancePoints -= penaltyPoints;
            if (shard2.temporalResonancePoints < penaltyPoints) shard2.temporalResonancePoints = 0; else shard2.temporalResonancePoints -= penaltyPoints;
            outcomeValue = 0; // Report 0 if penalty
        }

        // Force both shards back to Dormant state
        if (shard1.currentState != ShardState.Dormant) _updateShardState(shardId1, ShardState.Dormant);
        if (shard2.currentState != ShardState.Dormant) _updateShardState(shardId2, ShardState.Dormant);

        // Clean up mappings
        shard1.entanglementPairId = 0;
        shard2.entanglementPairId = 0;
        delete _shardIdToPairId[shardId1];
        delete _shardIdToPairId[shardId2];
        delete _entanglementPairs[_pairId];

        emit RefractionOccurred(_pairId, shardId1, shardId2, outcomeValue);
    }

    // Attempts to trigger the Singularity Event based on complex, multi-factor conditions.
    function triggerSingularityEvent(uint256[] memory _potentialParticipatingShardIds) public {
        // This function can be called by anyone, but requires specific global and shard-level conditions.

        // Check global conditions: Oracle value and total Catalyst supply
        require(simulatedOracleValue >= SINGULARITY_ORACLE_THRESHOLD_MIN && simulatedOracleValue <= SINGULARITY_ORACLE_THRESHOLD_MAX, "Oracle value not in singularity range");

        // Calculate total Catalyst in the vault across all users
        uint256 totalVaultCatalyst = 0;
        // This is inefficient - a real contract would track this globally or iterate user list
        // For this example, we'll skip iterating all users and just check a hypothetical global supply.
        // Let's assume for this example, we track the total Catalyst ever injected, minus withdrawals.
        // A global variable `totalCatalystSupply` would be better. Let's simulate that.
        uint256 _hypotheticalTotalContractCatalyst = 50000; // Replace with actual tracking

        require(_hypotheticalTotalContractCatalyst >= SINGULARITY_CATALYST_POOL_THRESHOLD, "Insufficient total Catalyst supply in vault");

        // Check participating shard conditions: count types in specific states
        mapping(uint8 => uint256) memory currentParticipatingShardCounts;
        uint256 totalCatalystConsumedForEvent = 0; // Event might consume some catalyst

        for (uint i = 0; i < _potentialParticipatingShardIds.length; i++) {
            uint256 shardId = _potentialParticipatingShardIds[i];
            QuantumShard storage shard = _internalShards[shardId];
            require(shard.internalId != 0, "Invalid participating shard ID");

            // Example: Shards must be in 'Active' or 'Locked' state to participate
            require(shard.currentState == ShardState.Active || shard.currentState == ShardState.Locked, "Participating shards must be Active or Locked");

            currentParticipatingShardCounts[shard.shardType]++;

            // Example: Event consumes Catalyst from participating shard owners (scaled by type)
            uint256 individualShardCatalystCost = shard.shardType * 50; // e.g. 50 for Basic, 100 for Advanced, 150 for Exotic
            require(_catalystBalances[shard.owner] >= individualShardCatalystCost, "Participating shard owner has insufficient Catalyst");
            _catalystBalances[shard.owner] -= individualShardCatalystCost;
             // In a real contract, transfer individualShardCatalystCost to contract/burn/distribute
            totalCatalystConsumedForEvent += individualShardCatalystCost;
        }

        // Check required counts of shard types
        for (uint8 shardType = 1; shardType <= 3; shardType++) {
            require(currentParticipatingShardCounts[shardType] >= singularityRequiredShardCount[shardType], "Not enough participating shards of type");
        }

        // If all conditions met: Trigger Singularity Event effects!
        emit SingularityEventTriggered(block.timestamp, simulatedOracleValue, _hypotheticalTotalContractCatalyst - totalCatalystConsumedForEvent); // Emit remaining catalyst

        // Apply effects to participating shards (example: state change, resonance boost)
        for (uint i = 0; i < _potentialParticipatingShardIds.length; i++) {
             uint256 shardId = _potentialParticipatingShardIds[i];
             QuantumShard storage shard = _internalShards[shardId];

             // Example effect: Boost resonance points significantly
             shard.temporalResonancePoints += 1000 * shard.shardType; // More boost for higher types

             // Example effect: Force state transition (e.g., back to Dormant or into a special 'Resonating' state not shown here)
             if (shard.currentState != ShardState.Dormant) {
                 // If it was locked, end the lock
                 if (shard.currentState == ShardState.Locked) shard.lockEndTime = 0;
                 _updateShardState(shardId, ShardState.Dormant); // Force back to Dormant
             }
        }
    }

    // --- Utility / Views ---

    function getQuantumShardState(uint256 _internalShardId) public view returns (ShardState) {
        require(_internalShards[_internalShardId].internalId != 0, "Invalid shard ID");
        return _internalShards[_internalShardId].currentState;
    }

    function isQuantumShardEntangled(uint256 _internalShardId) public view returns (bool) {
        require(_internalShards[_internalShardId].internalId != 0, "Invalid shard ID");
        return _internalShards[_internalShardId].entanglementPairId != 0;
    }

    function getEntanglementPair(uint256 _internalShardId) public view returns (uint256 pairId, uint256 shardId1, uint256 shardId2, uint64 creationTime) {
        require(_internalShards[_internalShardId].internalId != 0, "Invalid shard ID");
        pairId = _shardIdToPairId[_internalShardId];
        require(pairId != 0, "Shard is not entangled");
        EntanglementPair storage pair = _entanglementPairs[pairId];
        return (pairId, pair.shardId1, pair.shardId2, pair.creationTime);
    }

     function getPairShardIds(uint256 _pairId) public view returns (uint256 shardId1, uint256 shardId2) {
        EntanglementPair storage pair = _entanglementPairs[_pairId];
        require(pair.shardId1 != 0, "Invalid pair ID");
        return (pair.shardId1, pair.shardId2);
     }


    function getQuantumShardLockEndTime(uint256 _internalShardId) public view returns (uint64) {
         require(_internalShards[_internalShardId].internalId != 0, "Invalid shard ID");
         return _internalShards[_internalShardId].lockEndTime;
    }

    // Gets the current claimable points, including points earned since last claim/state change
    function getTemporalResonancePoints(uint256 _internalShardId) public view returns (uint256) {
        QuantumShard storage shard = _internalShards[_internalShardId];
        require(shard.internalId != 0, "Invalid shard ID");

        uint64 lastClaim = _lastResonanceClaimTime[_internalShardId];
        uint64 timeSinceLastCalculation = uint64(block.timestamp) - lastClaim;

        uint256 earnedPoints = (timeSinceLastCalculation * resonancePointsPerSecond[shard.currentState]);

        return shard.temporalResonancePoints + earnedPoints;
    }

    function getTotalTemporalResonancePoints(address _owner) public view returns (uint260 totalPoints) {
        uint256[] memory ownedShards = _ownerShards[_owner];
        totalPoints = 0;
        for (uint i = 0; i < ownedShards.length; i++) {
            totalPoints += getTemporalResonancePoints(ownedShards[i]); // Sum claimable points
        }
        return totalPoints;
    }

    function getCatalystBalance(address _owner) public view returns (uint256) {
        return _catalystBalances[_owner];
    }

     function getQuantumShardDetails(uint256 _internalShardId) public view returns (
         uint256 internalId,
         address externalContract,
         uint256 externalTokenId,
         address owner,
         ShardState currentState,
         uint64 stateStartTime,
         uint64 lockEndTime,
         uint256 temporalResonancePoints, // Note: This is *accumulated*, use getTemporalResonancePoints for total claimable
         uint256 entanglementPairId,
         uint8 shardType
     ) {
         QuantumShard storage shard = _internalShards[_internalShardId];
         require(shard.internalId != 0, "Invalid shard ID");

         return (
             shard.internalId,
             shard.externalContract,
             shard.externalTokenId,
             shard.owner,
             shard.currentState,
             shard.stateStartTime,
             shard.lockEndTime,
             shard.temporalResonancePoints, // Returning the stored value
             shard.entanglementPairId,
             shard.shardType
         );
     }

    // View function to check if Singularity conditions are met
    function checkSingularityConditions() public view returns (bool) {
         if (simulatedOracleValue < SINGULARITY_ORACLE_THRESHOLD_MIN || simulatedOracleValue > SINGULARITY_ORACLE_THRESHOLD_MAX) return false;

         // Simulate total Catalyst in contract (see triggerSingularityEvent comment)
         uint256 _hypotheticalTotalContractCatalyst = 50000; // Replace with actual tracking
         if (_hypotheticalTotalContractCatalyst < SINGULARITY_CATALYST_POOL_THRESHOLD) return false;

        // Note: Cannot check required *participating shard counts* accurately here
        // because that depends on which specific shards are passed to triggerSingularityEvent.
        // This view only checks global conditions.
        return true;
    }

     function getInternalShardDetailsByExternal(address _shardContract, uint256 _externalTokenId) public view returns (
         uint256 internalId,
         address owner,
         ShardState currentState,
         uint8 shardType
     ) {
         // This would require a lookup mapping from external ID to internal ID.
         // For simplicity, this view is conceptual unless that mapping is added.
         // Implementing a mapping like `mapping(address => mapping(uint256 => uint256))`
         // would allow this lookup, but adds complexity and gas cost on deposit.
         // As a placeholder, we return default values or revert.
         revert("Lookup by external ID not implemented due to mapping overhead. Use internal IDs.");
         // If implemented, it would look like:
         // uint256 id = _externalToInternalShardId[_shardContract][_externalTokenId];
         // require(id != 0, "Shard not found");
         // QuantumShard storage shard = _internalShards[id];
         // return (id, shard.owner, shard.currentState, shard.shardType);
     }


    // --- Owner Functions (for simulation control) ---

    function updateOracleValue(uint256 _newValue) public onlyOwner {
        simulatedOracleValue = _newValue;
        emit OracleValueUpdated(_newValue);
    }

    // --- Internal Transfer ---

    // Allows transferring ownership of a Shard *within* the vault system to another address.
    // Does NOT withdraw the underlying external NFT.
    function transferInternalShard(uint256 _internalShardId, address _to) public {
        _requireShardOwner(_internalShardId);
        require(_to != address(0), "Cannot transfer to zero address");
        require(msg.sender != _to, "Cannot transfer to self");

        QuantumShard storage shard = _internalShards[_internalShardId];

        // Optional: Add restrictions based on state (e.g., cannot transfer if Locked or Entangled)
        require(shard.currentState == ShardState.Dormant, "Shard must be Dormant to transfer internally");
        require(shard.lockEndTime <= block.timestamp, "Shard is locked");
        require(shard.entanglementPairId == 0, "Shard is entangled");


        address from = msg.sender;
        address to = _to;

        _removeShardFromOwnerList(from, _internalShardId);
        shard.owner = to;
        _addShardToOwnerList(to, _internalShardId);

        emit InternalShardTransfer(_internalShardId, from, to);
    }

    // --- Internal Helper Functions for Owner Mapping ---

    function _addShardToOwnerList(address _owner, uint256 _internalShardId) internal {
        _ownerShards[_owner].push(_internalShardId);
        _internalShardIndex[_internalShardId] = _ownerShards[_owner].length - 1;
    }

    function _removeShardFromOwnerList(address _owner, uint256 _internalShardId) internal {
        uint256 index = _internalShardIndex[_internalShardId];
        uint256 lastIndex = _ownerShards[_owner].length - 1;

        // If not the last element, move the last element to the removed position
        if (index != lastIndex) {
            uint256 lastShardId = _ownerShards[_owner][lastIndex];
            _ownerShards[_owner][index] = lastShardId;
            _internalShardIndex[lastShardId] = index;
        }

        // Remove the last element
        _ownerShards[_owner].pop();
        delete _internalShardIndex[_internalShardId]; // Clean up the index mapping
    }

    // Utility view to get all shard IDs owned by an address
    function getOwnedQuantumShardIds(address _owner) public view returns (uint256[] memory) {
         return _ownerShards[_owner];
    }
}
```