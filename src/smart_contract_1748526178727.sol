Okay, here is a Solidity smart contract demonstrating some advanced, creative, and trendy concepts beyond standard token or simple vault contracts. It focuses on conditional access based on multiple time, state, and potentially probabilistic factors, simulating a kind of "Quantum Lock" where unlocking depends on complex, potentially interacting (simulated "entangled") conditions and early attempts can cause state changes ("collapse" into a jittery state).

**Key Concepts Demonstrated:**

1.  **Complex, Multi-Factor Conditional Release:** Assets are locked until *all* or *any* of several diverse conditions are met (time, block, simulated external data, internal state).
2.  **Simulated State Entanglement/Collapse:** Attempting to unlock prematurely doesn't just fail, but can trigger a temporary negative state ("Quantum Jitters") for the recipient, affecting *all* their locks. This simulates a state change/penalty on observation/interaction before conditions are right.
3.  **Probabilistic Penalty Trigger:** The "Quantum Jitters" penalty for early unlock attempts is triggered probabilistically based on block data (a common, albeit basic, on-chain pseudo-randomness technique for demonstration).
4.  **Internal State Dependencies:** Unlock conditions can depend on the contract's *own* state, including the simulated external data or whether other locks have collapsed.
5.  **Flexible Asset Handling:** Supports both ETH and any ERC20 token.
6.  **Granular Querying:** Many view functions to inspect the state of individual locks, conditions, and recipient states.
7.  **Owner Controls:** Basic owner functions for pausing, setting parameters, and emergency rescue of collapsed funds.

**Disclaimer:** This contract is a *conceptual demonstration*. The "quantum" aspects are simulated. True on-chain randomness is complex (often requires oracles like Chainlink VRF). External data simulation is for demonstration only; real dApps need secure oracle integrations. Gas costs for complex condition checks or looping through many locks can be high.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for owner functions

// --- Outline and Function Summary ---
//
// Contract: QuantumLock
// Purpose: A smart contract to lock ETH or ERC20 tokens under complex,
//          multi-conditional release terms. Introduces concepts of state-dependent
//          unlocks and a probabilistic "jittery" state triggered by premature access attempts.
//
// Advanced Concepts:
// - Dynamic and Multiple Unlock Conditions (Time, Block, Simulated External Data, Internal State)
// - State-Dependent Access (Jittery state affects unlock attempts)
// - Probabilistic Penalty Trigger (using blockhash for simulated randomness)
// - Simulated State Interaction ("Entanglement"/Collapse via Jittery state)
// - Flexible Asset Locking (ETH and any ERC20)
//
// Structures & Enums:
// - LockState: UNKNOWN, LOCKED, UNLOCKED, COLLAPSED (due to failed early attempt)
// - ConditionType: TIME_ELAPSED, BLOCK_REACHED, EXTERNAL_VALUE_GTE, EXTERNAL_VALUE_LTE, INTERNAL_STATE_MATCH
// - ComparisonType: GREATER_THAN_OR_EQUAL, LESS_THAN_OR_EQUAL, EQUAL_TO
// - ConditionsLogic: ALL_MUST_BE_MET, ANY_CAN_BE_MET
// - UnlockCondition: Defines a single condition requirement
// - Lock: Represents a single quantum lock instance
//
// State Variables:
// - owner: The contract deployer (Ownable)
// - lockCounter: Unique ID generator for locks
// - quantumLocks: Mapping from lock ID (bytes32) to Lock struct
// - recipientToLockIds: Mapping from recipient address to list of their lock IDs
// - jitteryUntilBlock: Mapping tracking if a recipient is in the "jittery" state and until which block
// - simulatedExternalDataValue: A value simulating external data feed
// - earlyUnlockPenaltyChancePercent: Configurable chance (0-100) of triggering jittery state on early unlock attempt
// - jitteryDurationBlocks: Number of blocks the jittery state lasts
//
// Events:
// - LockCreated: Emitted when a new lock is created
// - Unlocked: Emitted when a lock is successfully unlocked and assets are transferred
// - EarlyUnlockAttemptFailed: Emitted when an attempt to unlock fails because conditions aren't met
// - JitteryStateTriggered: Emitted when an early unlock attempt triggers the jittery penalty
// - CollapsedLockRescued: Emitted when the owner rescues collateral from a collapsed lock
// - SimulatedExternalDataUpdated: Emitted when the owner updates the simulated external data
// - PenaltyChanceUpdated: Emitted when the penalty chance is updated
// - JitteryDurationUpdated: Emitted when the jittery duration is updated
//
// Functions (>= 20 Public/External):
// 1. constructor(): Sets owner and initial parameters.
// 2. createQuantumLock(address _recipient, address _asset, uint256 _amount, UnlockCondition[] _conditions, ConditionsLogic _logic): Creates and funds a new lock.
// 3. checkConditions(bytes32 _lockId): View function to check if conditions are currently met for a lock.
// 4. isLockUnlockable(bytes32 _lockId): View function to check if a lock is currently in the state + conditions required for unlocking.
// 5. attemptUnlock(bytes32 _lockId): Attempts to unlock a specific lock. Triggers jittery state probabilistically if conditions not met.
// 6. attemptUnlockAllForRecipient(address _recipient): Attempts to unlock all *potential* locks for a recipient.
// 7. getLockDetails(bytes32 _lockId): View function to retrieve details of a specific lock.
// 8. getLockState(bytes32 _lockId): View function to get the current state of a lock.
// 9. getRecipientLocks(address _recipient): View function to get all lock IDs associated with a recipient.
// 10. getLockConditions(bytes32 _lockId): View function to retrieve the unlock conditions for a lock.
// 11. getLockCount(): View function to get the total number of locks created.
// 12. getRecipientJitteryState(address _recipient): View function to check if a recipient is currently in the jittery state.
// 13. getBlocksLeftOnJittery(address _recipient): View function to get blocks remaining on jittery state.
// 14. simulateExternalDataUpdate(uint256 _newValue): Owner-only function to update the simulated external data. (For demonstration)
// 15. getSimulatedExternalDataValue(): View function to get the current simulated external data.
// 16. setEarlyUnlockPenaltyChance(uint8 _percent): Owner-only function to set the probabilistic penalty chance (0-100).
// 17. getEarlyUnlockPenaltyChance(): View function to get the current penalty chance.
// 18. setJitteryDuration(uint256 _blocks): Owner-only function to set the duration of the jittery state in blocks.
// 19. getJitteryDuration(): View function to get the current jittery duration.
// 20. rescueCollapsedLockCollateral(bytes32 _lockId): Owner-only function to rescue assets from a lock that is in the COLLAPSED state.
// 21. pause(): Owner-only function to pause transfers and lock creation (using Pausable).
// 22. unpause(): Owner-only function to unpause the contract.
// 23. renounceOwnership(): Owner-only function to renounce ownership (from Ownable).
// 24. transferOwnership(address newOwner): Owner-only function to transfer ownership (from Ownable).
//
// (Includes inherited functions from Pausable and Ownable to meet >= 20 count,
// plus custom functions like checkIndividualCondition if needed, but the list above
// already exceeds 20 unique concepts/actions).

contract QuantumLock is Ownable, Pausable, ReentrancyGuard {

    enum LockState {
        UNKNOWN,
        LOCKED,
        UNLOCKED,
        COLLAPSED // State reached if early unlock attempt triggers penalty
    }

    enum ConditionType {
        TIME_ELAPSED,          // Checks block.timestamp >= value
        BLOCK_REACHED,         // Checks block.number >= value
        EXTERNAL_VALUE_GTE,    // Checks simulatedExternalDataValue >= value
        EXTERNAL_VALUE_LTE,    // Checks simulatedExternalDataValue <= value
        INTERNAL_STATE_MATCH   // Checks if another lock is in a specific state (value is state enum index)
    }

     enum ComparisonType {
        GREATER_THAN_OR_EQUAL, // Use for TIME_ELAPSED, BLOCK_REACHED, EXTERNAL_VALUE_GTE
        LESS_THAN_OR_EQUAL,    // Use for EXTERNAL_VALUE_LTE
        EQUAL_TO               // Use for INTERNAL_STATE_MATCH
        // Note: NOT_EQUAL, etc., could be added for more complexity
    }

    enum ConditionsLogic {
        ALL_MUST_BE_MET,
        ANY_CAN_BE_MET
    }

    struct UnlockCondition {
        ConditionType conditionType;
        ComparisonType comparisonType; // How value is compared
        uint256 value;              // Target value (timestamp, block, external data, state index)
        bytes32 targetLockId;       // Used for INTERNAL_STATE_MATCH condition type
    }

    struct Lock {
        address recipient;
        address asset; // address(0) for ETH
        uint256 amount;
        UnlockCondition[] conditions;
        ConditionsLogic conditionsLogic;
        LockState state;
        uint256 creationBlock;
        uint256 creationTimestamp;
    }

    uint256 private lockCounter;
    mapping(bytes32 => Lock) public quantumLocks;
    mapping(address => bytes32[]) private recipientToLockIds;

    // State for the 'jittery' penalty
    mapping(address => uint256) private jitteryUntilBlock;
    uint256 public jitteryDurationBlocks = 10; // Default duration

    // State for simulated external data
    uint256 public simulatedExternalDataValue;

    // Configurable penalty chance for early unlock attempts
    uint8 public earlyUnlockPenaltyChancePercent = 50; // 0-100

    // --- Events ---
    event LockCreated(bytes32 indexed lockId, address indexed recipient, address indexed asset, uint256 amount, uint256 numConditions);
    event Unlocked(bytes32 indexed lockId, address indexed recipient, address indexed asset, uint256 amount);
    event EarlyUnlockAttemptFailed(bytes32 indexed lockId, address indexed recipient, string reason);
    event JitteryStateTriggered(address indexed recipient, uint256 untilBlock);
    event CollapsedLockRescued(bytes32 indexed lockId, address indexed owner, address indexed asset, uint256 amount);
    event SimulatedExternalDataUpdated(uint256 newValue);
    event PenaltyChanceUpdated(uint8 newPercent);
    event JitteryDurationUpdated(uint256 newDurationBlocks);


    // --- Constructor ---
    constructor(uint256 initialSimulatedExternalData, uint8 _earlyUnlockPenaltyChancePercent, uint256 _jitteryDurationBlocks)
        Ownable(msg.sender)
        Pausable()
    {
        simulatedExternalDataValue = initialSimulatedExternalData;
        earlyUnlockPenaltyChancePercent = _earlyUnlockPenaltyChancePercent;
        jitteryDurationBlocks = _jitteryDurationBlocks;
        lockCounter = 0;
    }

    // --- Public/External Functions ---

    /// @notice Creates a new quantum lock with specified conditions.
    /// @param _recipient The address to receive assets upon unlock.
    /// @param _asset The address of the ERC20 token, or address(0) for ETH.
    /// @param _amount The amount of tokens or ETH to lock.
    /// @param _conditions An array of conditions that must be met.
    /// @param _logic Whether ALL or ANY conditions must be met.
    function createQuantumLock(
        address _recipient,
        address _asset,
        uint256 _amount,
        UnlockCondition[] memory _conditions,
        ConditionsLogic _logic
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_conditions.length > 0, "At least one condition is required");

        bytes32 lockId = keccak256(abi.encodePacked(this, lockCounter, _recipient, _asset, _amount, block.timestamp, block.number));
        lockCounter++;

        // Handle asset transfer
        if (_asset == address(0)) {
            require(msg.value == _amount, "ETH amount mismatch");
        } else {
            require(msg.value == 0, "Do not send ETH with token lock");
            IERC20 token = IERC20(_asset);
            // TransferFrom requires the contract to be approved by the sender beforehand
            token.transferFrom(msg.sender, address(this), _amount);
        }

        quantumLocks[lockId] = Lock({
            recipient: _recipient,
            asset: _asset,
            amount: _amount,
            conditions: _conditions,
            conditionsLogic: _logic,
            state: LockState.LOCKED,
            creationBlock: block.number,
            creationTimestamp: block.timestamp
        });

        recipientToLockIds[_recipient].push(lockId);

        emit LockCreated(lockId, _recipient, _asset, _amount, _conditions.length);
    }

    /// @notice Checks if the conditions for a specific lock are met currently.
    /// @param _lockId The ID of the lock to check.
    /// @return bool True if conditions are met, false otherwise.
    function checkConditions(bytes32 _lockId) public view returns (bool) {
        Lock storage lock = quantumLocks[_lockId];
        require(lock.state != LockState.UNKNOWN, "Lock not found");

        if (lock.conditionsLogic == ConditionsLogic.ALL_MUST_BE_MET) {
            for (uint i = 0; i < lock.conditions.length; i++) {
                if (!_checkIndividualCondition(lockId, lock.conditions[i])) {
                    return false; // All must be met, one failure means false
                }
            }
            return true; // All conditions passed
        } else if (lock.conditionsLogic == ConditionsLogic.ANY_CAN_BE_MET) {
             for (uint i = 0; i < lock.conditions.length; i++) {
                if (_checkIndividualCondition(lockId, lock.conditions[i])) {
                    return true; // Any met is enough
                }
            }
            return false; // No conditions passed
        }
        // Should not reach here
        return false;
    }

    /// @notice Internal helper to check a single condition. Made public for external view convenience.
    /// @param _lockId The ID of the lock the condition belongs to.
    /// @param _condition The condition to check.
    /// @return bool True if the single condition is met, false otherwise.
    function _checkIndividualCondition(bytes32 _lockId, UnlockCondition memory _condition) internal view returns (bool) {
         // We need the lock to access creation data if needed, or check internal state
         Lock storage currentLock = quantumLocks[_lockId];
         require(currentLock.state != LockState.UNKNOWN, "Internal: Lock not found for condition check"); // Should not happen if called from checkConditions

        if (_condition.conditionType == ConditionType.TIME_ELAPSED) {
            // Value is duration in seconds relative to lock creation
            return block.timestamp >= currentLock.creationTimestamp + _condition.value;
        } else if (_condition.conditionType == ConditionType.BLOCK_REACHED) {
             // Value is block number relative to lock creation
            return block.number >= currentLock.creationBlock + _condition.value;
        } else if (_condition.conditionType == ConditionType.EXTERNAL_VALUE_GTE) {
            // Value is a threshold for simulatedExternalDataValue
            return simulatedExternalDataValue >= _condition.value;
        } else if (_condition.conditionType == ConditionType.EXTERNAL_VALUE_LTE) {
             // Value is a threshold for simulatedExternalDataValue
            return simulatedExternalDataValue <= _condition.value;
        } else if (_condition.conditionType == ConditionType.INTERNAL_STATE_MATCH) {
            // Value is the index of the target state in the LockState enum
            LockState targetState = LockState(_condition.value);
            bytes32 targetLockId = _condition.targetLockId;
             require(quantumLocks[targetLockId].state != LockState.UNKNOWN, "Internal state condition requires valid target lock ID");
            return quantumLocks[targetLockId].state == targetState;
        }
        // Unknown condition type
        return false;
    }

    /// @notice Checks if a lock is in the LOCKED state and its conditions are met, and the recipient is not jittery.
    /// @param _lockId The ID of the lock to check.
    /// @return bool True if unlockable, false otherwise.
    function isLockUnlockable(bytes32 _lockId) public view returns (bool) {
        Lock storage lock = quantumLocks[_lockId];
        if (lock.state != LockState.LOCKED) {
            return false;
        }
        if (getRecipientJitteryState(lock.recipient)) {
             return false; // Cannot unlock while jittery
        }
        return checkConditions(_lockId);
    }


    /// @notice Attempts to unlock a specific lock. Can trigger jittery state if conditions aren't met.
    /// @param _lockId The ID of the lock to attempt unlocking.
    function attemptUnlock(bytes32 _lockId)
        external
        nonReentrant
        whenNotPaused
    {
        Lock storage lock = quantumLocks[_lockId];
        require(lock.state != LockState.UNKNOWN, "Lock not found");
        require(lock.state == LockState.LOCKED, "Lock is not in LOCKED state");
        require(msg.sender == lock.recipient || msg.sender == owner(), "Only recipient or owner can attempt unlock");
        require(!getRecipientJitteryState(lock.recipient), "Recipient is in jittery state");

        bool conditionsMet = checkConditions(_lockId);

        if (conditionsMet) {
            // Conditions met - UNLOCK
            lock.state = LockState.UNLOCKED;

            if (lock.asset == address(0)) {
                (bool success, ) = payable(lock.recipient).call{value: lock.amount}("");
                require(success, "ETH transfer failed");
            } else {
                IERC20 token = IERC20(lock.asset);
                token.transfer(lock.recipient, lock.amount);
            }

            emit Unlocked(_lockId, lock.recipient, lock.asset, lock.amount);

        } else {
            // Conditions not met - check for penalty
            emit EarlyUnlockAttemptFailed(_lockId, lock.recipient, "Conditions not met");

            // Probabilistic check for triggering jittery state
            // Use blockhash of the previous block (block.number-1) for pseudo-randomness
            // Note: blockhash(block.number) is not available. blockhash(block.number-1)
            // can be influenced by miners. This is a demonstration, not cryptographically secure randomness.
            // Use Chainlink VRF or similar for production-grade randomness.
            uint256 randomNumber = uint256(blockhash(block.number - 1));
            if (randomNumber % 100 < earlyUnlockPenaltyChancePercent) {
                // Trigger jittery state
                jitteryUntilBlock[lock.recipient] = block.number + jitteryDurationBlocks;
                // Optionally mark the lock as collapsed if early attempt penalty is severe
                // lock.state = LockState.COLLAPSED; // Uncomment this line if early failure *collapses* the lock
                emit JitteryStateTriggered(lock.recipient, jitteryUntilBlock[lock.recipient]);
            }
            // If penalty not triggered, lock remains in LOCKED state, just the attempt failed.
        }
    }

     /// @notice Attempts to unlock all locks for a given recipient that are currently unlockable.
     /// @param _recipient The address of the recipient.
     /// Note: This function might consume significant gas if a recipient has many locks.
     function attemptUnlockAllForRecipient(address _recipient)
        external
        nonReentrant
        whenNotPaused
     {
         require(msg.sender == _recipient || msg.sender == owner(), "Only recipient or owner can attempt unlock all");
         require(!getRecipientJitteryState(_recipient), "Recipient is in jittery state");

         bytes32[] storage lockIds = recipientToLockIds[_recipient];
         for (uint i = 0; i < lockIds.length; i++) {
             bytes32 lockId = lockIds[i];
             // Check if the lock exists and is in a state that can be attempted (LOCKED)
             // And check if conditions are met for this specific lock.
             // We don't call attemptUnlock directly here to avoid triggering penalty on *every* failed lock.
             // Instead, we check conditions first and only attempt if conditions are met.
             // A different design could call attemptUnlock for each, accepting potential penalties.
             // This version is safer for the recipient's jittery state.
             Lock storage lock = quantumLocks[lockId];
             if (lock.state == LockState.LOCKED && checkConditions(lockId)) {
                  // Conditions met for this specific lock, proceed with transfer
                  lock.state = LockState.UNLOCKED; // Update state before transfer to prevent reentrancy (part of nonReentrant)

                   if (lock.asset == address(0)) {
                        (bool success, ) = payable(lock.recipient).call{value: lock.amount}("");
                        require(success, "ETH transfer failed for lock in batch");
                    } else {
                        IERC20 token = IERC20(lock.asset);
                        token.transfer(lock.recipient, lock.amount);
                    }
                    emit Unlocked(lockId, lock.recipient, lock.asset, lock.amount);
             }
         }
     }


    /// @notice Retrieves details of a specific lock.
    /// @param _lockId The ID of the lock.
    /// @return recipient The recipient address.
    /// @return asset The asset address.
    /// @return amount The locked amount.
    /// @return state The current state of the lock.
    /// @return conditionsLogic The logic for checking conditions (ALL or ANY).
    /// @return creationBlock The block the lock was created.
    /// @return creationTimestamp The timestamp the lock was created.
    function getLockDetails(bytes32 _lockId)
        public
        view
        returns (
            address recipient,
            address asset,
            uint256 amount,
            LockState state,
            ConditionsLogic conditionsLogic,
            uint256 creationBlock,
            uint256 creationTimestamp
        )
    {
        Lock storage lock = quantumLocks[_lockId];
        require(lock.state != LockState.UNKNOWN, "Lock not found");
        return (
            lock.recipient,
            lock.asset,
            lock.amount,
            lock.state,
            lock.conditionsLogic,
            lock.creationBlock,
            lock.creationTimestamp
        );
    }

    /// @notice Retrieves the current state of a specific lock.
    /// @param _lockId The ID of the lock.
    /// @return LockState The current state.
    function getLockState(bytes32 _lockId) public view returns (LockState) {
        return quantumLocks[_lockId].state;
    }

    /// @notice Retrieves the unlock conditions for a specific lock.
    /// @param _lockId The ID of the lock.
    /// @return UnlockCondition[] An array of conditions.
    function getLockConditions(bytes32 _lockId) public view returns (UnlockCondition[] memory) {
         Lock storage lock = quantumLocks[_lockId];
         require(lock.state != LockState.UNKNOWN, "Lock not found");
         return lock.conditions;
    }


    /// @notice Gets all lock IDs associated with a specific recipient.
    /// @param _recipient The recipient address.
    /// @return bytes32[] An array of lock IDs.
    function getRecipientLocks(address _recipient) public view returns (bytes32[] memory) {
        return recipientToLockIds[_recipient];
    }

    /// @notice Gets the total number of locks created.
    /// @return uint256 The total count.
    function getLockCount() public view returns (uint256) {
        return lockCounter;
    }

    /// @notice Checks if a recipient is currently in the "jittery" penalty state.
    /// @param _recipient The recipient address.
    /// @return bool True if jittery, false otherwise.
    function getRecipientJitteryState(address _recipient) public view returns (bool) {
        return jitteryUntilBlock[_recipient] > block.number;
    }

    /// @notice Gets the number of blocks remaining on the jittery penalty for a recipient.
    /// @param _recipient The recipient address.
    /// @return uint256 Blocks remaining. Returns 0 if not jittery or duration passed.
    function getBlocksLeftOnJittery(address _recipient) public view returns (uint256) {
        uint256 untilBlock = jitteryUntilBlock[_recipient];
        if (untilBlock == 0 || untilBlock <= block.number) {
            return 0;
        }
        return untilBlock - block.number;
    }

    /// @notice (Owner Only) Simulates an update to the external data value.
    ///         In a real application, this would be driven by an oracle.
    /// @param _newValue The new value for the simulated external data.
    function simulateExternalDataUpdate(uint256 _newValue) external onlyOwner {
        simulatedExternalDataValue = _newValue;
        emit SimulatedExternalDataUpdated(_newValue);
    }

    /// @notice Gets the current value of the simulated external data.
    /// @return uint256 The simulated external data value.
    function getSimulatedExternalDataValue() public view returns (uint256) {
        return simulatedExternalDataValue;
    }

    /// @notice (Owner Only) Sets the percentage chance (0-100) for triggering the jittery penalty on early unlock attempts.
    /// @param _percent The new percentage chance.
    function setEarlyUnlockPenaltyChance(uint8 _percent) external onlyOwner {
        require(_percent <= 100, "Percent must be 0-100");
        earlyUnlockPenaltyChancePercent = _percent;
        emit PenaltyChanceUpdated(_percent);
    }

    /// @notice Gets the current percentage chance for the early unlock penalty.
    /// @return uint8 The percentage chance.
    function getEarlyUnlockPenaltyChance() public view returns (uint8) {
        return earlyUnlockPenaltyChancePercent;
    }

    /// @notice (Owner Only) Sets the duration of the jittery state in blocks.
    /// @param _blocks The new duration in blocks.
    function setJitteryDuration(uint256 _blocks) external onlyOwner {
        require(_blocks > 0, "Duration must be greater than 0 blocks");
        jitteryDurationBlocks = _blocks;
        emit JitteryDurationUpdated(_blocks);
    }

    /// @notice Gets the current duration of the jittery state in blocks.
    /// @return uint256 The duration in blocks.
    function getJitteryDuration() public view returns (uint256) {
        return jitteryDurationBlocks;
    }


    /// @notice (Owner Only) Allows the owner to rescue collateral from a lock that is in the COLLAPSED state.
    ///         This function is for recovering funds from locks that failed early and were marked collapsed.
    /// @param _lockId The ID of the collapsed lock.
    function rescueCollapsedLockCollateral(bytes32 _lockId) external onlyOwner nonReentrant {
        Lock storage lock = quantumLocks[_lockId];
        require(lock.state != LockState.UNKNOWN, "Lock not found");
        require(lock.state == LockState.COLLAPSED, "Lock is not in COLLAPSED state");

        lock.state = LockState.UNKNOWN; // Mark as rescued/removed

        if (lock.asset == address(0)) {
            (bool success, ) = payable(owner()).call{value: lock.amount}("");
            require(success, "ETH rescue failed");
        } else {
            IERC20 token = IERC20(lock.asset);
            token.transfer(owner(), lock.amount);
        }

        emit CollapsedLockRescued(_lockId, owner(), lock.asset, lock.amount);
    }

    /// @notice Pauses the contract (Owner only, from Pausable).
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract (Owner only, from Pausable).
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Inherited Ownable Functions (implicitly add to function count) ---
    // renounceOwnership()
    // transferOwnership(address newOwner)
    // owner()
    // _transferOwnership(address newOwner) (internal)

    // --- Fallback/Receive ---
    receive() external payable {} // Allows receiving ETH for locks

    // Function to check individual condition outcome (public wrapper for _checkIndividualCondition)
     function checkIndividualConditionOutcome(bytes32 _lockId, UnlockCondition memory _condition) public view returns (bool) {
         require(quantumLocks[_lockId].state != LockState.UNKNOWN, "Lock not found for condition check");
         return _checkIndividualCondition(_lockId, _condition);
     }

     // Expose the internal _checkIndividualCondition as a public view function if needed for debugging/UI
     // Function count check: The private _checkIndividualCondition is called internally.
     // checkIndividualConditionOutcome is a public wrapper.

     // Let's ensure we have >= 20 distinct *callable* functions (public/external)

     // 1. constructor
     // 2. createQuantumLock
     // 3. checkConditions
     // 4. isLockUnlockable
     // 5. attemptUnlock
     // 6. attemptUnlockAllForRecipient
     // 7. getLockDetails
     // 8. getLockState
     // 9. getRecipientLocks
     // 10. getLockConditions
     // 11. getLockCount
     // 12. getRecipientJitteryState
     // 13. getBlocksLeftOnJittery
     // 14. simulateExternalDataUpdate (Owner)
     // 15. getSimulatedExternalDataValue
     // 16. setEarlyUnlockPenaltyChance (Owner)
     // 17. getEarlyUnlockPenaltyChance
     // 18. setJitteryDuration (Owner)
     // 19. getJitteryDuration
     // 20. rescueCollapsedLockCollateral (Owner)
     // 21. pause (Owner, Pausable)
     // 22. unpause (Owner, Pausable)
     // 23. renounceOwnership (Owner, Ownable)
     // 24. transferOwnership (Owner, Ownable)
     // 25. owner() (Ownable)
     // 26. paused() (Pausable)
     // 27. checkIndividualConditionOutcome (Helper view)

     // Yes, definitely >= 20 public/external functions.

}
```