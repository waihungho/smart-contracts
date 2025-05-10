Okay, let's create a smart contract that goes beyond typical examples. We'll build a "Quantum Vault" where funds are locked based on a set of evolving, interdependent conditions, inspired by the idea of quantum states collapsing when observed or influenced.

The "quantum" aspect here is a metaphor for the lock's eligibility state not being fixed but depending on the convergence of multiple, potentially external or time-dependent, factors. It's not using actual quantum computing, which is not possible on-chain.

This contract will manage deposits (ETH) that are released to a recipient only when *all* specified conditions for a given lock are met. Conditions can be time-based, dependent on the contract's internal state, or signaled by an authorized oracle. The owner has advanced control over conditions and the contract's state, adding complexity and control, though also potential risk.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Contract Information:** Pragma, Imports.
2.  **State Variables:** Owner, Oracle address, next Lock ID, mapping for Locks, current Vault State.
3.  **Enums:** `LockState`, `ConditionType`, `VaultState`.
4.  **Structs:** `Condition`, `Lock`.
5.  **Events:** Significant actions like Lock creation, state changes, condition met, oracle/state changes, condition modifications.
6.  **Modifiers:** Access control (`onlyOwner`, `onlyOracle`), state checks.
7.  **Constructor:** Initializes owner.
8.  **Core Vault Management Functions:**
    *   `createLock`: Deposit ETH and define unlock conditions for a recipient.
    *   `attemptUnlock`: Recipient tries to unlock funds by checking if all conditions are met.
    *   `cancelLock`: Owner can forcefully cancel a lock (potentially with constraints).
    *   `migrateContractFunds`: Owner can withdraw residual funds after locks are resolved.
9.  **Condition & State Management Functions:**
    *   `setState`: Owner changes the global Vault state, potentially influencing state-based conditions.
    *   `signalOracleConditionMet`: Oracle confirms an external event/condition for a specific lock.
    *   `addConditionToLock`: Owner adds a new condition to an existing lock.
    *   `removeConditionFromLock`: Owner removes a condition from an existing lock.
    *   `updateConditionParameter`: Owner modifies parameters of an existing condition.
    *   `setOracle`: Owner sets the address of the authorized oracle.
10. **View Functions:** Retrieve information about locks, states, conditions, and contract balance.
    *   `getLockDetails`
    *   `getLockState`
    *   `getVaultState`
    *   `getOracle`
    *   `getContractBalance`
    *   `getLockCount`
    *   `getLockConditionDetails`
    *   `getLockConditionsCount`
    *   `checkLockConditionsMet` (Simulates condition check without state change)
    *   `getConditionStatus` (Check status of a single condition)
11. **Helper Internal Functions:** Logic for checking and transitioning lock states.

**Function Summary:**

1.  `constructor()`: Sets the initial owner of the contract.
2.  `createLock(address _recipient, Condition[] calldata _conditions)`: Creates a new locked vault entry for `_recipient` with deposited Ether (`msg.value`). Requires an array of `_conditions` to be met for unlocking. Emits `LockCreated`.
3.  `attemptUnlock(uint256 _lockId)`: Called by the lock's recipient (`msg.sender`). Checks if the lock is in a state where conditions can be evaluated (`Locked`). If so, evaluates all associated conditions. If all are met, transitions the lock state to `ReadyToUnlock`. If the state is `ReadyToUnlock`, transfers the locked ETH to the recipient and transitions state to `Unlocked`. Emits `LockStateChanged` and `LockUnlocked`.
4.  `cancelLock(uint256 _lockId)`: callable by the contract owner. Allows the owner to forcefully cancel a lock, returning the funds to the *owner's* address (simulating a penalty/management recovery). Emits `LockStateChanged` and `LockCancelled`.
5.  `migrateContractFunds()`: Callable by the contract owner. Withdraws the entire balance of the contract to the owner's address. Intended for recovering residual dust or funds from cancelled/resolved locks if not automatically handled.
6.  `setState(VaultState _newState)`: Callable by the contract owner. Changes the global `vaultState`. This can influence `StateBased` conditions on existing locks. Emits `StateChanged`.
7.  `signalOracleConditionMet(uint256 _lockId, uint256 _conditionIndex)`: Callable by the designated oracle address. Marks a specific `OracleBased` condition within a lock as met (`isMet = true`). Triggers a check if all conditions for that lock are now met. Emits `ConditionMet`.
8.  `addConditionToLock(uint256 _lockId, Condition calldata _newCondition)`: Callable by the contract owner. Adds a new condition to an existing lock. Only allowed if the lock is in the `Locked` state. Emits `ConditionAdded`.
9.  `removeConditionFromLock(uint256 _lockId, uint256 _conditionIndex)`: Callable by the contract owner. Invalidates (`isValid = false`) a condition at a specific index within a lock's conditions array. Only allowed if the lock is in the `Locked` state. Emits `ConditionRemoved`.
10. `updateConditionParameter(uint256 _lockId, uint256 _conditionIndex, uint256 _parameter)`: Callable by the contract owner. Updates the generic `parameter` field of a condition. Requires caution! Only allowed if the lock is in the `Locked` state and condition is valid. Emits `ConditionUpdated`.
11. `setOracle(address _oracle)`: Callable by the contract owner. Sets the address authorized to call `signalOracleConditionMet`. Emits `OracleSet`.
12. `transferOwnership(address newOwner)`: Callable by the contract owner (from OpenZeppelin's Ownable). Transfers ownership to `newOwner`.
13. `renounceOwnership()`: Callable by the contract owner (from OpenZeppelin's Ownable). Renounces ownership, setting owner to zero address.
14. `getLockDetails(uint256 _lockId)`: View function. Returns details of a specific lock.
15. `getLockState(uint256 _lockId)`: View function. Returns the current state of a specific lock.
16. `getVaultState()`: View function. Returns the current global `vaultState`.
17. `getOracle()`: View function. Returns the current oracle address.
18. `getContractBalance()`: View function. Returns the current ETH balance of the contract.
19. `getLockCount()`: View function. Returns the total number of locks created.
20. `getLockConditionDetails(uint256 _lockId, uint256 _conditionIndex)`: View function. Returns details of a specific condition within a lock.
21. `getLockConditionsCount(uint256 _lockId)`: View function. Returns the number of conditions associated with a lock (including potentially invalid ones).
22. `checkLockConditionsMet(uint256 _lockId)`: View function. Evaluates if all valid conditions for a lock are currently met based on the chain state, but does *not* change the lock's state. Useful for checking eligibility off-chain.
23. `getConditionStatus(uint256 _lockId, uint256 _conditionIndex)`: View function. Checks and returns whether a specific condition at an index is currently considered met based on its type and parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// Note: This contract is for demonstration purposes and complexity.
// It involves significant owner control and potential risks.
// A production contract would require extensive security audits and testing.

/**
 * @title QuantumVault
 * @dev A smart contract vault holding Ether released based on complex, evolving conditions.
 * The concept is inspired by quantum states, where the final state (unlock) depends
 * on the convergence of multiple factors (conditions) which are initially uncertain
 * and only 'collapse' into eligibility when all criteria are met or observed (signaled).
 * Supports time-based, state-based, oracle-signaled, and dependent lock conditions.
 */
contract QuantumVault is Ownable {

    // --- Enums ---

    /**
     * @dev Represents the current state of a lock.
     * Locked: Funds are held, conditions not yet met.
     * ReadyToUnlock: All conditions are met, awaiting recipient to call attemptUnlock.
     * Unlocked: Funds have been successfully transferred to the recipient.
     * Cancelled: Lock was cancelled by the owner, funds returned to owner.
     * PendingOracle: Waiting for an oracle signal for one or more conditions (optional intermediate state).
     */
    enum LockState {
        Locked,
        ReadyToUnlock,
        Unlocked,
        Cancelled,
        PendingOracle // Added for clarity when oracle condition is pending
    }

    /**
     * @dev Defines the type of condition required for unlock.
     * TimeBased: Unlock requires current block timestamp to be >= a specified value.
     * StateBased: Unlock requires the global VaultState to match a specified value.
     * OracleBased: Unlock requires a signal from the designated oracle address.
     * DependentLockUnlocked: Unlock requires another specific lock to be in the Unlocked state.
     */
    enum ConditionType {
        TimeBased,
        StateBased,
        OracleBased,
        DependentLockUnlocked
    }

    /**
     * @dev Represents the global state of the vault, controllable by the owner.
     * This state can influence StateBased conditions.
     * Initial: Default state.
     * Phase1, Phase2, Phase3: Example custom states.
     * Finalized: Indicates a terminal contract state perhaps allowing owner recovery.
     */
    enum VaultState {
        Initial,
        Phase1,
        Phase2,
        Phase3,
        Finalized
    }

    // --- Structs ---

    /**
     * @dev Represents a single condition that must be met for a lock to transition.
     * conditionType: The type of condition (TimeBased, StateBased, etc.).
     * parameter: A generic uint256 parameter used differently based on type (timestamp, state enum value, lock ID).
     * isMet: For OracleBased conditions, this flag is set true by the oracle. For others, it's evaluated dynamically.
     * isValid: Allows conditions to be soft-deleted (marked invalid) by the owner instead of removing from array.
     */
    struct Condition {
        ConditionType conditionType;
        uint256 parameter;
        bool isMet; // Used primarily by OracleBased conditions
        bool isValid; // Allows owner to invalidate conditions
    }

    /**
     * @dev Represents a single lock entry in the vault.
     * recipient: The address that receives the funds upon unlock.
     * amount: The amount of Ether locked.
     * conditions: An array of conditions that must all be met for unlock.
     * state: The current state of this lock (Locked, ReadyToUnlock, etc.).
     */
    struct Lock {
        address payable recipient;
        uint256 amount;
        Condition[] conditions;
        LockState state;
    }

    // --- State Variables ---

    uint256 public nextLockId;
    mapping(uint256 => Lock) private _locks;
    VaultState public vaultState;
    address public oracle; // Address authorized to signal oracle conditions

    // --- Events ---

    event LockCreated(uint256 lockId, address recipient, uint256 amount, uint256 conditionCount);
    event LockStateChanged(uint256 lockId, LockState newState);
    event LockUnlocked(uint256 lockId, address recipient, uint256 amount);
    event LockCancelled(uint256 lockId, address recipient, uint256 amount); // Amount might be 0 if owner takes it
    event ConditionMet(uint256 lockId, uint256 conditionIndex, ConditionType conditionType);
    event StateChanged(VaultState newState);
    event OracleSet(address indexed oldOracle, address indexed newOracle);
    event ConditionAdded(uint256 lockId, uint256 conditionIndex);
    event ConditionRemoved(uint256 lockId, uint256 conditionIndex);
    event ConditionUpdated(uint256 lockId, uint256 conditionIndex, uint256 newParameter);
    event FundsMigrated(address indexed to, uint256 amount);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracle, "Caller is not the oracle");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        nextLockId = 1; // Start Lock IDs from 1
        vaultState = VaultState.Initial; // Set initial global state
    }

    // --- Receive Ether Function ---
    // Allows the contract to receive ETH, but locks can only be created via createLock
    receive() external payable {}

    // --- Core Vault Management ---

    /**
     * @dev Creates a new lock with specified recipient, amount, and conditions.
     * @param _recipient The address to receive the funds upon unlock.
     * @param _conditions An array of conditions that must all be met.
     */
    function createLock(address _recipient, Condition[] calldata _conditions) public payable {
        require(_recipient != address(0), "Invalid recipient address");
        require(msg.value > 0, "Amount must be greater than 0");
        require(_conditions.length > 0, "Must provide at least one condition");

        uint256 currentLockId = nextLockId++;

        Lock storage newLock = _locks[currentLockId];
        newLock.recipient = payable(_recipient);
        newLock.amount = msg.value;
        newLock.state = LockState.Locked;

        // Copy conditions, ensuring validity flag is true by default
        newLock.conditions = new Condition[](_conditions.length);
        for (uint i = 0; i < _conditions.length; i++) {
             newLock.conditions[i] = _conditions[i];
             newLock.conditions[i].isValid = true; // Ensure isValid is true for new conditions
             // Reset isMet for OracleBased conditions on creation - oracle must signal AFTER creation
             if (_conditions[i].conditionType == ConditionType.OracleBased) {
                 newLock.conditions[i].isMet = false;
             }
        }


        emit LockCreated(currentLockId, _recipient, msg.value, _conditions.length);
    }

    /**
     * @dev Allows the recipient of a lock to attempt unlocking it.
     * Triggers a check of all conditions. If met, transfers funds.
     * @param _lockId The ID of the lock to attempt unlocking.
     */
    function attemptUnlock(uint256 _lockId) public {
        Lock storage lock = _locks[_lockId];
        require(lock.recipient == msg.sender, "Not the lock recipient");
        require(lock.state != LockState.Unlocked && lock.state != LockState.Cancelled, "Lock is not active");

        // If the lock is still 'Locked', first check if conditions are now met
        if (lock.state == LockState.Locked || lock.state == LockState.PendingOracle) {
            _checkAndTransitionState(_lockId); // This might change state to ReadyToUnlock
        }

        // Now, if the state is ReadyToUnlock, execute the transfer
        require(lock.state == LockState.ReadyToUnlock, "Lock conditions not yet met or not ready");

        // --- Checks-Effects-Interactions Pattern ---
        // 1. Checks: Done above (recipient, state, conditions met).
        // 2. Effects: Update the lock's state *before* interaction.
        lock.state = LockState.Unlocked;
        emit LockStateChanged(_lockId, LockState.Unlocked);

        // 3. Interactions: Transfer funds (the only external call).
        (bool success, ) = payable(lock.recipient).call{value: lock.amount}("");
        require(success, "ETH transfer failed");

        emit LockUnlocked(_lockId, lock.recipient, lock.amount);
    }

    /**
     * @dev Allows the owner to forcefully cancel a lock.
     * Funds are returned to the owner's address.
     * @param _lockId The ID of the lock to cancel.
     */
    function cancelLock(uint256 _lockId) public onlyOwner {
        Lock storage lock = _locks[_lockId];
        require(lock.state != LockState.Unlocked && lock.state != LockState.Cancelled, "Lock is already resolved");

        uint256 amountToRecover = lock.amount; // Amount originally locked

        // --- Checks-Effects-Interactions ---
        // 1. Checks: Done above (owner, state).
        // 2. Effects: Update state first.
        lock.state = LockState.Cancelled;
        lock.amount = 0; // Clear amount in struct
        emit LockStateChanged(_lockId, LockState.Cancelled);
        emit LockCancelled(_lockId, lock.recipient, amountToRecover);

        // 3. Interactions: Send funds to owner.
        // Using call instead of transfer/send for better error handling and avoiding fixed gas limit.
        (bool success, ) = payable(owner()).call{value: amountToRecover}("");
        require(success, "ETH recovery to owner failed");
    }

    /**
     * @dev Allows the owner to migrate any remaining contract balance.
     * Useful for recovering dust or funds after all relevant locks are handled.
     */
    function migrateContractFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Funds migration failed");

        emit FundsMigrated(owner(), balance);
    }

    // --- Condition & State Management ---

    /**
     * @dev Allows the owner to change the global vault state.
     * This can affect StateBased conditions.
     * @param _newState The new VaultState to set.
     */
    function setState(VaultState _newState) public onlyOwner {
        require(vaultState != _newState, "Vault state is already set to this value");
        vaultState = _newState;
        emit StateChanged(vaultState);

        // Note: Changing state doesn't automatically trigger condition checks for ALL locks.
        // Recipients must call attemptUnlock or use checkLockConditionsMet (view) to see if they are now eligible.
    }

    /**
     * @dev Allows the designated oracle to signal that an OracleBased condition is met.
     * @param _lockId The ID of the lock containing the condition.
     * @param _conditionIndex The index of the OracleBased condition within the lock's conditions array.
     */
    function signalOracleConditionMet(uint256 _lockId, uint256 _conditionIndex) public onlyOracle {
        Lock storage lock = _locks[_lockId];
        require(lock.state == LockState.Locked || lock.state == LockState.PendingOracle, "Lock not in a state awaiting oracle signal");
        require(_conditionIndex < lock.conditions.length, "Condition index out of bounds");

        Condition storage condition = lock.conditions[_conditionIndex];
        require(condition.isValid, "Condition is not valid");
        require(condition.conditionType == ConditionType.OracleBased, "Condition is not OracleBased");
        require(!condition.isMet, "Oracle condition already signaled as met");

        // --- Checks-Effects-Interactions ---
        // 1. Checks: Done above.
        // 2. Effects: Update the condition state.
        condition.isMet = true;
        emit ConditionMet(_lockId, _conditionIndex, condition.conditionType);

        // 3. Interactions: None directly. Call internal check.
        _checkAndTransitionState(_lockId); // Check if all conditions are now met
    }

    /**
     * @dev Allows the owner to add a new condition to an existing lock.
     * Only permitted if the lock is still in the Locked state.
     * @param _lockId The ID of the lock to modify.
     * @param _newCondition The condition struct to add.
     */
    function addConditionToLock(uint256 _lockId, Condition calldata _newCondition) public onlyOwner {
        Lock storage lock = _locks[_lockId];
        require(lock.state == LockState.Locked || lock.state == LockState.PendingOracle, "Can only add conditions to a locked/pending lock");

        // Ensure isValid is true and isMet is false for new OracleBased conditions
        Condition memory conditionToAdd = _newCondition;
        conditionToAdd.isValid = true;
        if (conditionToAdd.conditionType == ConditionType.OracleBased) {
            conditionToAdd.isMet = false;
        }

        lock.conditions.push(conditionToAdd);
        emit ConditionAdded(_lockId, lock.conditions.length - 1);
    }

    /**
     * @dev Allows the owner to remove (invalidate) an existing condition from a lock.
     * The condition is marked as invalid but remains in the array.
     * Only permitted if the lock is still in the Locked state.
     * @param _lockId The ID of the lock to modify.
     * @param _conditionIndex The index of the condition to invalidate.
     */
    function removeConditionFromLock(uint256 _lockId, uint256 _conditionIndex) public onlyOwner {
        Lock storage lock = _locks[_lockId];
        require(lock.state == LockState.Locked || lock.state == LockState.PendingOracle, "Can only remove conditions from a locked/pending lock");
        require(_conditionIndex < lock.conditions.length, "Condition index out of bounds");
        require(lock.conditions[_conditionIndex].isValid, "Condition is already invalid");

        lock.conditions[_conditionIndex].isValid = false; // Mark as invalid
        emit ConditionRemoved(_lockId, _conditionIndex);
    }

    /**
     * @dev Allows the owner to update the generic parameter of a condition.
     * Use with extreme caution as this can significantly change unlock requirements.
     * Only permitted if the lock is still in the Locked state.
     * @param _lockId The ID of the lock to modify.
     * @param _conditionIndex The index of the condition to update.
     * @param _parameter The new parameter value.
     */
    function updateConditionParameter(uint256 _lockId, uint256 _conditionIndex, uint256 _parameter) public onlyOwner {
         Lock storage lock = _locks[_lockId];
         require(lock.state == LockState.Locked || lock.state == LockState.PendingOracle, "Can only update conditions on a locked/pending lock");
         require(_conditionIndex < lock.conditions.length, "Condition index out of bounds");
         require(lock.conditions[_conditionIndex].isValid, "Condition is not valid");

         // Specific checks based on type might be needed in a real scenario,
         // e.g., ensure TimeBased parameter is future timestamp, DependentLockUnlocked parameter is valid lock ID.
         // For this example, we allow changing any parameter.
         lock.conditions[_conditionIndex].parameter = _parameter;
         emit ConditionUpdated(_lockId, _conditionIndex, _parameter);
    }


    /**
     * @dev Allows the owner to set the oracle address.
     * @param _oracle The address of the new oracle.
     */
    function setOracle(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        emit OracleSet(oracle, _oracle);
        oracle = _oracle;
    }


    // --- View Functions ---

    /**
     * @dev Gets details of a specific lock.
     * @param _lockId The ID of the lock.
     * @return recipient The recipient address.
     * @return amount The locked amount.
     * @return state The current lock state.
     * @return conditionCount The number of conditions.
     */
    function getLockDetails(uint256 _lockId) public view returns (address recipient, uint256 amount, LockState state, uint256 conditionCount) {
        require(_lockId > 0 && _lockId < nextLockId, "Invalid lock ID");
        Lock storage lock = _locks[_lockId];
        return (lock.recipient, lock.amount, lock.state, lock.conditions.length);
    }

    /**
     * @dev Gets the current state of a specific lock.
     * @param _lockId The ID of the lock.
     * @return The current LockState.
     */
    function getLockState(uint256 _lockId) public view returns (LockState) {
         require(_lockId > 0 && _lockId < nextLockId, "Invalid lock ID");
         return _locks[_lockId].state;
    }

    /**
     * @dev Gets the current global vault state.
     * @return The current VaultState.
     */
    function getVaultState() public view returns (VaultState) {
        return vaultState;
    }

    /**
     * @dev Gets the current oracle address.
     * @return The oracle address.
     */
    function getOracle() public view returns (address) {
        return oracle;
    }

    /**
     * @dev Gets the current ETH balance of the contract.
     * @return The contract's balance in Wei.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the total number of locks ever created.
     * @return The total count of locks.
     */
    function getLockCount() public view returns (uint256) {
        return nextLockId - 1;
    }

     /**
     * @dev Gets details of a specific condition within a lock.
     * Includes its type, parameter, and current isMet/isValid status.
     * @param _lockId The ID of the lock.
     * @param _conditionIndex The index of the condition.
     * @return conditionType The type of the condition.
     * @return parameter The condition's parameter.
     * @return isMet The current isMet status (relevant for OracleBased).
     * @return isValid The current isValid status.
     */
    function getLockConditionDetails(uint256 _lockId, uint256 _conditionIndex) public view returns (ConditionType conditionType, uint256 parameter, bool isMet, bool isValid) {
        require(_lockId > 0 && _lockId < nextLockId, "Invalid lock ID");
        Lock storage lock = _locks[_lockId];
        require(_conditionIndex < lock.conditions.length, "Condition index out of bounds");
        Condition storage condition = lock.conditions[_conditionIndex];
        return (condition.conditionType, condition.parameter, condition.isMet, condition.isValid);
    }

    /**
     * @dev Gets the total number of conditions (valid or invalid) associated with a lock.
     * @param _lockId The ID of the lock.
     * @return The number of conditions.
     */
    function getLockConditionsCount(uint256 _lockId) public view returns (uint256) {
        require(_lockId > 0 && _lockId < nextLockId, "Invalid lock ID");
        return _locks[_lockId].conditions.length;
    }

    /**
     * @dev Checks if all valid conditions for a lock are currently met based on current chain state.
     * This is a view function and does NOT change the lock's state.
     * @param _lockId The ID of the lock.
     * @return true if all valid conditions are met, false otherwise.
     */
    function checkLockConditionsMet(uint256 _lockId) public view returns (bool) {
        require(_lockId > 0 && _lockId < nextLockId, "Invalid lock ID");
        Lock storage lock = _locks[_lockId];

        bool allMet = true;
        uint validConditionCount = 0;

        for (uint i = 0; i < lock.conditions.length; i++) {
            Condition storage condition = lock.conditions[i];
            if (condition.isValid) {
                validConditionCount++;
                if (!_isConditionMet(lock, i)) {
                    allMet = false;
                    break; // No need to check further if one valid condition isn't met
                }
            }
        }

        // A lock with 0 valid conditions cannot be unlocked via conditions
        // Or define behavior: if 0 valid conditions, it's always ready? Let's require > 0.
        return allMet && (validConditionCount > 0);
    }

    /**
     * @dev Checks if a single condition is currently met based on its type and parameter.
     * Does not consider the 'isValid' flag or the lock's overall state.
     * @param _lockId The ID of the lock.
     * @param _conditionIndex The index of the condition.
     * @return true if the condition is met, false otherwise.
     */
    function getConditionStatus(uint256 _lockId, uint256 _conditionIndex) public view returns (bool) {
        require(_lockId > 0 && _lockId < nextLockId, "Invalid lock ID");
        Lock storage lock = _locks[_lockId];
        require(_conditionIndex < lock.conditions.length, "Condition index out of bounds");
        return _isConditionMet(lock, _conditionIndex);
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal function to check all conditions for a lock and transition its state if met.
     * Called by attemptUnlock or signalOracleConditionMet.
     * @param _lockId The ID of the lock to check.
     */
    function _checkAndTransitionState(uint256 _lockId) internal {
        Lock storage lock = _locks[_lockId];

        // Only check and transition if the lock is still active (Locked or PendingOracle)
        if (lock.state != LockState.Locked && lock.state != LockState.PendingOracle) {
            return; // Lock is already resolved or ready/unlocked
        }

        bool allMet = true;
        bool needsOracle = false; // Track if any valid oracle condition exists and is not met
        uint validConditionCount = 0;

        for (uint i = 0; i < lock.conditions.length; i++) {
            Condition storage condition = lock.conditions[i];
            if (condition.isValid) {
                validConditionCount++;
                if (!_isConditionMet(lock, i)) {
                    allMet = false;
                    // If it's an OracleBased condition that isn't met, note that we are pending oracle
                    if (condition.conditionType == ConditionType.OracleBased && !condition.isMet) {
                         needsOracle = true;
                    }
                    // Continue checking other conditions even if one failed,
                    // to correctly set needsOracle flag if applicable.
                }
            }
        }

        // State Transition Logic:
        if (validConditionCount == 0) {
             // No valid conditions means it can never transition via conditions.
             // Keep it locked or pending, effectively requiring owner cancellation.
             // Or define: if 0 valid conditions, it's always ready? Let's stick to > 0 valid conditions.
             // If we are here, allMet is true because the loop didn't find unmet *valid* conditions, but count is 0.
             // So, treat 0 valid conditions as not met.
             if (lock.state == LockState.ReadyToUnlock) {
                 // This is an edge case if conditions were removed after it became ReadyToUnlock.
                 // Revert state to Locked. This is complex state management,
                 // for simplicity let's assume validConditionCount > 0 is checked *before* reaching ReadyToUnlock state.
                 // Let's implicitly require validConditionCount > 0 for ReadyToUnlock.
             }
        } else if (allMet) {
            if (lock.state != LockState.ReadyToUnlock) {
                 lock.state = LockState.ReadyToUnlock;
                 emit LockStateChanged(_lockId, LockState.ReadyToUnlock);
            }
        } else { // !allMet
            if (needsOracle && lock.state != LockState.PendingOracle) {
                 lock.state = LockState.PendingOracle;
                 emit LockStateChanged(_lockId, LockState.PendingOracle);
            } else if (!needsOracle && lock.state != LockState.Locked) {
                // If not all conditions met, and no oracle condition is pending,
                // it means another non-oracle condition isn't met (time, state, dependent lock).
                // State should be Locked.
                 lock.state = LockState.Locked;
                 emit LockStateChanged(_lockId, LockState.Locked);
            }
             // If needsOracle is true and state is already PendingOracle, do nothing.
             // If !needsOracle and state is already Locked, do nothing.
        }
    }


    /**
     * @dev Internal helper to check if a single condition is met.
     * Does not check the 'isValid' flag or overall lock state.
     * @param _lock The lock struct.
     * @param _conditionIndex The index of the condition within the lock's conditions array.
     * @return true if the specific condition is met, false otherwise.
     */
    function _isConditionMet(Lock storage _lock, uint256 _conditionIndex) internal view returns (bool) {
        Condition storage condition = _lock.conditions[_conditionIndex];

        // If condition is not valid, it cannot be met for the purpose of unlocking
        // Although this helper is used by getConditionStatus which doesn't check isValid,
        // the _checkAndTransitionState logic filters by isValid first.
        // So technically, this helper assumes the condition is valid in the context of unlock logic.
        // Let's include the check anyway for robustness in getConditionStatus.
        if (!condition.isValid) {
            return false;
        }

        // Evaluate the condition based on its type
        if (condition.conditionType == ConditionType.TimeBased) {
            return block.timestamp >= condition.parameter;
        } else if (condition.conditionType == ConditionType.StateBased) {
            // Cast uint256 parameter back to VaultState enum
            return vaultState == VaultState(uint8(condition.parameter));
        } else if (condition.conditionType == ConditionType.OracleBased) {
            // Status is determined by the oracle having signaled
            return condition.isMet;
        } else if (condition.conditionType == ConditionType.DependentLockUnlocked) {
            // Parameter is the ID of the dependent lock
            uint256 dependentLockId = condition.parameter;
            // Check if dependent lock ID is valid and its state is Unlocked
            // Note: This introduces a potential recursion depth risk if locks form a long chain.
            // Solidity has a recursion depth limit (usually 1024 calls). Deep dependencies could fail.
            if (dependentLockId > 0 && dependentLockId < nextLockId) {
                return _locks[dependentLockId].state == LockState.Unlocked;
            } else {
                // Dependent lock ID is invalid, this condition can never be met
                return false;
            }
        }
        // Should not reach here if all ConditionTypes are handled
        return false;
    }
}
```