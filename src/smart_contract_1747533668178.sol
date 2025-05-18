Okay, here is a Solidity smart contract named `ChronoVault`. It incorporates several advanced, creative, and trending concepts centered around time-based and conditional asset management, along with scheduled arbitrary actions. It aims to be distinct from common open-source examples by combining multiple complex features like multi-type locks, guardian-asserted conditions, and scheduled arbitrary calls within a single vault.

**Outline and Function Summary**

**Contract Name:** ChronoVault

**Purpose:** A secure vault for storing ETH and ERC20 tokens with various time-based and conditional release mechanisms, including scheduled arbitrary contract calls, managed potentially by owners and designated guardians.

**Core Concepts Implemented:**
1.  **Multi-Type Asset Locking:** Supports Time Locks, Vesting Schedules, and Conditional Locks (assertion-based).
2.  **Scheduled Arbitrary Calls:** Allows scheduling function calls on *other* contracts to be executed at a later time.
3.  **Guardian System:** Designated addresses can assert pre-defined conditions, potentially enabling access to certain funds or actions under specific circumstances (e.g., owner inactivity, external trigger).
4.  **Detailed State Management:** Tracks individual lock entries, vesting steps, scheduled calls, and guardian statuses.
5.  **Fine-Grained Access Control:** Uses modifiers and internal checks for different roles (Owner, Guardian, Locker).
6.  **ERC20 Handling:** Interacts with generic ERC20 tokens.
7.  **Event Emission:** Provides transparency for key actions.
8.  **Custom Errors:** Uses efficient custom errors.

**Function Summary:**

**Owner/Admin Functions:**
1.  `constructor(address[] memory initialGuardians)`: Initializes the contract with the deployer as owner and sets initial guardians.
2.  `transferOwnership(address newOwner)`: Transfers ownership of the contract.
3.  `renounceOwnership()`: Renounces ownership (sets owner to zero address).
4.  `addGuardian(address guardian)`: Adds an address to the list of guardians.
5.  `removeGuardian(address guardian)`: Removes an address from the list of guardians.
6.  `cancelSpecificLock(uint256 lockId)`: Allows the owner to cancel a specific lock *if* it hasn't started yet, returning funds to the locker.
7.  `cancelScheduledCall(uint256 callId)`: Allows the owner to cancel a scheduled call if it hasn't been executed or failed permanently.

**Deposit Functions:**
8.  `depositETH() payable`: Deposits Ether into the vault.
9.  `depositERC20(address token, uint256 amount)`: Deposits ERC20 tokens into the vault (requires prior approval).

**Locking Functions (Locker can be msg.sender or another address):**
10. `createTimeLock(address token, address locker, uint256 amount, uint64 releaseTime)`: Creates a simple time lock for a specific token amount, released entirely at `releaseTime`.
11. `createVestingLock(address token, address locker, uint256 totalAmount, VestingStep[] memory steps)`: Creates a vesting lock with multiple release steps defined by time and percentage/amount.
12. `createConditionalLock(address token, address locker, uint256 amount, uint256 conditionIdentifier)`: Creates a lock released only when a specific condition is asserted by a guardian.

**Withdrawal/Release Functions (Locker or authorized address):**
13. `releaseTimeLock(uint256 lockId)`: Releases funds from a completed time lock.
14. `releaseVestingLock(uint256 lockId)`: Releases available funds from a vesting lock based on elapsed time.
15. `releaseConditionalLock(uint256 lockId)`: Releases funds from a conditional lock *if* the required condition has been asserted by a guardian.
16. `withdrawUnlockedETH()`: Allows the owner to withdraw any ETH that is not currently locked.
17. `withdrawUnlockedERC20(address token)`: Allows the owner to withdraw any ERC20 tokens of a specific type that are not currently locked.

**Scheduled Call Functions:**
18. `scheduleCall(uint64 executeTime, address target, bytes memory data, uint256 value)`: Schedules an arbitrary function call on `target` with `data` and `value` to be executed at `executeTime`.
19. `executeScheduledCall(uint256 callId)`: Attempts to execute a scheduled call if the execution time has passed and it hasn't been executed or permanently failed.

**Guardian Functions:**
20. `assertCondition(uint256 conditionIdentifier)`: Allows a guardian to assert that a specific condition (referenced by `conditionIdentifier`) has been met.
21. `guardianCancelScheduledCall(uint256 callId)`: Allows a guardian to cancel a scheduled call *if* a specific owner inactivity condition has been met (example condition).

**View Functions:**
22. `getLockDetails(uint256 lockId)`: Returns details for a specific lock.
23. `getScheduledCallDetails(uint256 callId)`: Returns details for a specific scheduled call.
24. `getGuardians()`: Returns the list of current guardian addresses.
25. `getGuardianConditionStatus(address guardian, uint256 conditionIdentifier)`: Checks if a specific guardian has asserted a specific condition.
26. `getTotalLockedBalance(address token)`: Returns the total amount of a specific token currently held in all active locks.
27. `getUnlockedBalance(address token)`: Returns the amount of a specific token not held in any active locks (calculates total vault balance minus total locked).
28. `isGuardian(address account)`: Checks if an address is a guardian.

**Note:** This contract uses counters for IDs. While simpler for this example, in production, using hash-based IDs or more robust ID generation might be considered depending on scale and potential for collision/guessing. The conditional lock and guardian condition assertion is a simplified example; real-world conditions might involve oracle data, proofs, or multi-guardian consensus. The scheduled call mechanism is powerful but requires careful handling of potential failures and gas costs during execution.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors for gas efficiency
error ChronoVault__NotLockerOrOwner();
error ChronoVault__LockNotFound();
error ChronoVault__LockNotReadyYet();
error ChronoVault__LockAlreadyReleased();
error ChronoVault__NoFundsToRelease();
error ChronoVault__InvalidVestingSchedule();
error ChronoVault__LockNotConditional();
error ChronoVault__ConditionNotAsserted();
error ChronoVault__ScheduledCallNotFound();
error ChronoVault__ScheduledCallNotReadyYet();
error ChronoVault__ScheduledCallAlreadyExecutedOrFailed();
error ChronoVault__CallExecutionFailed();
error ChronoVault__NotEnoughUnlockedBalance();
error ChronoVault__ZeroAddressNotAllowed();
error ChronoVault__GuardianAlreadyAdded();
error ChronoVault__NotAGuardian();
error ChronoVault__LockNotCancelledYet(); // For owner cancellation timing
error ChronoVault__ConditionAlreadyAsserted();
error ChronoVault__OwnerActivityConditionNotMet();

contract ChronoVault is Ownable, ReentrancyGuard {

    /* --- State Variables --- */

    // ERC20 token address for ETH is represented by address(0)
    address constant ETH_TOKEN_ADDRESS = address(0);

    // Lock Management
    enum LockType { TimeLock, VestingLock, ConditionalLock }
    enum LockStatus { Active, Released, Cancelled }

    struct VestingStep {
        uint64 releaseTime; // Timestamp for this step
        uint256 amount;      // Specific amount for this step (or percentage, depending on interpretation - here amount)
        bool released;       // Whether this step has been released
    }

    struct LockEntry {
        LockType lockType;
        address token;       // Token address (address(0) for ETH)
        address locker;      // The original locker/beneficiary
        uint256 totalAmount; // Total amount locked
        uint64 creationTime; // Timestamp of lock creation
        LockStatus status;

        // Type-specific data
        uint64 releaseTime;            // Used by TimeLock
        VestingStep[] vestingSteps;    // Used by VestingLock
        uint256 conditionIdentifier;   // Used by ConditionalLock (e.g., a hash or arbitrary ID)
    }

    mapping(uint256 => LockEntry) public locks;
    uint256 private nextLockId = 1; // Start from 1

    // Scheduled Call Management
    enum ScheduledCallStatus { Pending, ExecutedSuccess, ExecutedFailedPermanent, Cancelled }

    struct ScheduledCall {
        uint64 executeTime;
        address target;
        bytes data;
        uint256 value; // ETH value to send with the call
        ScheduledCallStatus status;
        address scheduler; // Address that scheduled the call
    }

    mapping(uint256 => ScheduledCall) public scheduledCalls;
    uint256 private nextCallId = 1; // Start from 1

    // Guardian System
    // Represents a specific condition that can be asserted by guardians
    // Example condition: owner inactivity for X time (handled externally, but state tracked here)
    // Oracles could assert conditions too, but simplified here.
    // Mapping guardian address => condition identifier => asserted (bool)
    mapping(address => mapping(uint256 => bool)) public guardianConditionAssertions;
    // Mapping guardian address => is a guardian (bool) - Easier lookup
    mapping(address => bool) private _isGuardian;
    // List of guardians (for easy iteration in view function)
    address[] private _guardians;

    // Example Condition Identifier: Owner inactivity for 90 days
    // In a real scenario, this would be asserted based on external monitoring
    uint256 constant CONDITION_OWNER_INACTIVITY_90_DAYS = 1;

    // Internal state to track total locked balance per token
    mapping(address => uint256) private totalLockedBalances;

    /* --- Events --- */

    event ETHDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed token, address indexed sender, uint256 amount);

    event LockCreated(uint256 indexed lockId, LockType lockType, address indexed token, address indexed locker, uint256 amount);
    event LockReleased(uint256 indexed lockId, address indexed token, address indexed beneficiary, uint256 amount);
    event LockCancelled(uint256 indexed lockId, address indexed token, address indexed locker, uint256 amount);

    event VestingStepReleased(uint256 indexed lockId, uint256 stepIndex, uint256 amount);

    event ScheduledCallCreated(uint256 indexed callId, address indexed target, uint64 executeTime, address indexed scheduler);
    event ScheduledCallExecuted(uint256 indexed callId, bool success);
    event ScheduledCallCancelled(uint256 indexed callId, address indexed canceller);

    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event ConditionAsserted(address indexed guardian, uint256 indexed conditionIdentifier);

    event UnlockedETHWithdrawal(address indexed recipient, uint256 amount);
    event UnlockedERC20Withdrawal(address indexed token, address indexed recipient, uint256 amount);

    /* --- Modifiers --- */

    modifier onlyGuardian() {
        if (!_isGuardian[msg.sender]) {
            revert ChronoVault__NotAGuardian();
        }
        _;
    }

    modifier onlyLockerOrOwner(uint256 lockId) {
        if (locks[lockId].locker != msg.sender && owner() != msg.sender) {
            revert ChronoVault__NotLockerOrOwner();
        }
        _;
    }

    modifier lockExists(uint256 lockId) {
        if (locks[lockId].locker == address(0)) { // Assuming address(0) locker means lock does not exist
            revert ChronoVault__LockNotFound();
        }
        _;
    }

     modifier scheduledCallExists(uint256 callId) {
        if (scheduledCalls[callId].target == address(0)) { // Assuming address(0) target means call does not exist
            revert ChronoVault__ScheduledCallNotFound();
        }
        _;
    }

    /* --- Constructor --- */

    constructor(address[] memory initialGuardians) Ownable(msg.sender) {
        for (uint i = 0; i < initialGuardians.length; i++) {
             if (initialGuardians[i] == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
             if (_isGuardian[initialGuardians[i]]) revert ChronoVault__GuardianAlreadyAdded();
            _isGuardian[initialGuardians[i]] = true;
            _guardians.push(initialGuardians[i]);
            emit GuardianAdded(initialGuardians[i]);
        }
    }

    /* --- Deposit Functions --- */

    /// @notice Deposits Ether into the vault.
    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @notice Deposits Ether into the vault. Explicit function.
    function depositETH() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @notice Deposits ERC20 tokens into the vault. Requires prior approval.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external nonReentrant {
        if (token == ETH_TOKEN_ADDRESS) revert ChronoVault__ZeroAddressNotAllowed();
        IERC20 tokenContract = IERC20(token);
        // TransferFrom requires allowance to be set by the sender
        bool success = tokenContract.transferFrom(msg.sender, address(this), amount);
        if (!success) revert ChronoVault__NoFundsToRelease(); // Can use a more specific error if needed

        emit ERC20Deposited(token, msg.sender, amount);
    }

    /* --- Locking Functions --- */

    /// @notice Creates a simple time lock for assets.
    /// @param token The address of the token (address(0) for ETH).
    /// @param locker The beneficiary address who can release the funds.
    /// @param amount The amount to lock.
    /// @param releaseTime The timestamp when the funds become available.
    function createTimeLock(
        address token,
        address locker,
        uint256 amount,
        uint64 releaseTime
    ) external nonReentrant {
        if (locker == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
        if (amount == 0) revert ChronoVault__NoFundsToRelease();
        if (releaseTime <= block.timestamp) revert ChronoVault__LockNotReadyYet(); // Must be in the future

        _transferFundsForLock(token, msg.sender, amount, locker);

        uint256 lockId = nextLockId++;
        locks[lockId] = LockEntry({
            lockType: LockType.TimeLock,
            token: token,
            locker: locker,
            totalAmount: amount,
            creationTime: uint64(block.timestamp),
            status: LockStatus.Active,
            releaseTime: releaseTime,
            vestingSteps: new VestingStep[](0), // Not used for time lock
            conditionIdentifier: 0 // Not used for time lock
        });

        totalLockedBalances[token] += amount;
        emit LockCreated(lockId, LockType.TimeLock, token, locker, amount);
    }

    /// @notice Creates a vesting lock with multiple release steps.
    /// @param token The address of the token (address(0) for ETH).
    /// @param locker The beneficiary address.
    /// @param totalAmount The total amount to vest.
    /// @param steps Array of VestingStep structs defining release times and amounts. Steps must be ordered by time.
    function createVestingLock(
        address token,
        address locker,
        uint256 totalAmount,
        VestingStep[] memory steps
    ) external nonReentrant {
        if (locker == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
        if (totalAmount == 0) revert ChronoVault__NoFundsToRelease();
        if (steps.length == 0) revert ChronoVault__InvalidVestingSchedule();

        uint256 sumAmounts = 0;
        uint64 lastReleaseTime = 0;
        for (uint i = 0; i < steps.length; i++) {
            if (steps[i].releaseTime <= lastReleaseTime) revert ChronoVault__InvalidVestingSchedule(); // Steps must be in time order
            if (steps[i].amount == 0) revert ChronoVault__InvalidVestingSchedule(); // Step amount must be > 0
            sumAmounts += steps[i].amount;
            lastReleaseTime = steps[i].releaseTime;
        }
        if (sumAmounts > totalAmount) revert ChronoVault__InvalidVestingSchedule(); // Sum of steps cannot exceed total

        _transferFundsForLock(token, msg.sender, totalAmount, locker);

        uint256 lockId = nextLockId++;
        locks[lockId] = LockEntry({
            lockType: LockType.VestingLock,
            token: token,
            locker: locker,
            totalAmount: totalAmount,
            creationTime: uint64(block.timestamp),
            status: LockStatus.Active,
            releaseTime: 0, // Not used for vesting
            vestingSteps: steps,
            conditionIdentifier: 0 // Not used for vesting
        });

        totalLockedBalances[token] += totalAmount;
        emit LockCreated(lockId, LockType.VestingLock, token, locker, totalAmount);
    }

    /// @notice Creates a lock that requires a guardian to assert a specific condition before release.
    /// @param token The address of the token (address(0) for ETH).
    /// @param locker The beneficiary address.
    /// @param amount The amount to lock.
    /// @param conditionIdentifier An identifier representing the condition that must be asserted by a guardian.
    function createConditionalLock(
        address token,
        address locker,
        uint256 amount,
        uint256 conditionIdentifier
    ) external nonReentrant {
        if (locker == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
        if (amount == 0) revert ChronoVault__NoFundsToRelease();
        if (conditionIdentifier == 0) revert ChronoVault__InvalidVestingSchedule(); // Identifier 0 reserved

        _transferFundsForLock(token, msg.sender, amount, locker);

        uint256 lockId = nextLockId++;
        locks[lockId] = LockEntry({
            lockType: LockType.ConditionalLock,
            token: token,
            locker: locker,
            totalAmount: amount,
            creationTime: uint64(block.timestamp),
            status: LockStatus.Active,
            releaseTime: 0, // Not used
            vestingSteps: new VestingStep[](0), // Not used
            conditionIdentifier: conditionIdentifier
        });

        totalLockedBalances[token] += amount;
        emit LockCreated(lockId, LockType.ConditionalLock, token, locker, amount);
    }

    /* --- Withdrawal/Release Functions --- */

    /// @notice Releases funds from a time lock if the release time has passed.
    /// @param lockId The ID of the time lock.
    function releaseTimeLock(uint256 lockId) external nonReentrant lockExists(lockId) {
        LockEntry storage lock = locks[lockId];

        if (lock.lockType != LockType.TimeLock) revert ChronoVault__LockNotReadyYet(); // Specific error for type mismatch
        if (lock.status != LockStatus.Active) revert ChronoVault__LockAlreadyReleased();
        if (block.timestamp < lock.releaseTime) revert ChronoVault__LockNotReadyYet();

        uint256 amountToRelease = lock.totalAmount;
        lock.status = LockStatus.Released;
        totalLockedBalances[lock.token] -= amountToRelease;

        _safeTransfer(lock.token, lock.locker, amountToRelease);
        emit LockReleased(lockId, lock.token, lock.locker, amountToRelease);
    }

    /// @notice Releases available funds from a vesting lock based on elapsed time.
    /// @param lockId The ID of the vesting lock.
    function releaseVestingLock(uint256 lockId) external nonReentrant lockExists(lockId) {
        LockEntry storage lock = locks[lockId];

        if (lock.lockType != LockType.VestingLock) revert ChronoVault__LockNotReadyYet(); // Specific error for type mismatch
        if (lock.status != LockStatus.Active) revert ChronoVault__LockAlreadyReleased();

        uint256 totalReleasedForThisCall = 0;

        for (uint i = 0; i < lock.vestingSteps.length; i++) {
            VestingStep storage step = lock.vestingSteps[i];
            if (!step.released && block.timestamp >= step.releaseTime) {
                step.released = true;
                totalReleasedForThisCall += step.amount;
            }
        }

        if (totalReleasedForThisCall == 0) revert ChronoVault__NoFundsToRelease();

        // Check if all steps are released
        bool allReleased = true;
        for (uint i = 0; i < lock.vestingSteps.length; i++) {
             if (!lock.vestingSteps[i].released) {
                 allReleased = false;
                 break;
             }
        }
        if (allReleased) {
            lock.status = LockStatus.Released;
        }

        totalLockedBalances[lock.token] -= totalReleasedForThisCall;
        _safeTransfer(lock.token, lock.locker, totalReleasedForThisCall);
        emit LockReleased(lockId, lock.token, lock.locker, totalReleasedForThisCall);
    }

    /// @notice Releases funds from a conditional lock if the required condition has been asserted.
    /// @param lockId The ID of the conditional lock.
    function releaseConditionalLock(uint256 lockId) external nonReentrant lockExists(lockId) {
        LockEntry storage lock = locks[lockId];

        if (lock.lockType != LockType.ConditionalLock) revert ChronoVault__LockNotConditional();
        if (lock.status != LockStatus.Active) revert ChronoVault__LockAlreadyReleased();

        // Check if ANY guardian has asserted the required condition
        bool conditionMet = false;
        for (uint i = 0; i < _guardians.length; i++) {
            if (guardianConditionAssertions[_guardians[i]][lock.conditionIdentifier]) {
                conditionMet = true;
                break;
            }
        }

        if (!conditionMet) revert ChronoVault__ConditionNotAsserted();

        uint256 amountToRelease = lock.totalAmount;
        lock.status = LockStatus.Released;
        totalLockedBalances[lock.token] -= amountToRelease;

        _safeTransfer(lock.token, lock.locker, amountToRelease);
        emit LockReleased(lockId, lock.token, lock.locker, amountToRelease);
    }

    /// @notice Allows the owner to withdraw ETH not currently held in any active lock.
    /// @param amount The amount of ETH to withdraw.
    function withdrawUnlockedETH(uint256 amount) external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 locked = totalLockedBalances[ETH_TOKEN_ADDRESS];
        uint256 unlocked = contractBalance > locked ? contractBalance - locked : 0;

        if (amount == 0 || amount > unlocked) revert ChronoVault__NotEnoughUnlockedBalance();

        // Using call for ETH transfer recommended in modern Solidity
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) revert ChronoVault__NoFundsToRelease(); // Generic error, refine if needed

        emit UnlockedETHWithdrawal(owner(), amount);
    }

    /// @notice Allows the owner to withdraw ERC20 tokens not currently held in any active lock.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawUnlockedERC20(address token, uint256 amount) external onlyOwner nonReentrant {
         if (token == ETH_TOKEN_ADDRESS) revert ChronoVault__ZeroAddressNotAllowed();
        IERC20 tokenContract = IERC20(token);

        uint256 contractBalance = tokenContract.balanceOf(address(this));
        uint256 locked = totalLockedBalances[token];
        uint256 unlocked = contractBalance > locked ? contractBalance - locked : 0;

        if (amount == 0 || amount > unlocked) revert ChronoVault__NotEnoughUnlockedBalance();

        bool success = tokenContract.transfer(owner(), amount);
        if (!success) revert ChronoVault__NoFundsToRelease(); // Generic error, refine if needed

        emit UnlockedERC20Withdrawal(token, owner(), amount);
    }


    /* --- Scheduled Call Functions --- */

    /// @notice Schedules an arbitrary function call on another contract.
    /// Can be used for scheduled interactions with other protocols, maintenance, etc.
    /// @param executeTime The timestamp when the call should be attempted.
    /// @param target The address of the contract to call.
    /// @param data The calldata for the function call.
    /// @param value The amount of ETH to send with the call.
    function scheduleCall(
        uint64 executeTime,
        address target,
        bytes memory data,
        uint256 value
    ) external onlyOwner nonReentrant { // Only owner can schedule sensitive calls
        if (target == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
        if (executeTime <= block.timestamp) revert ChronoVault__ScheduledCallNotReadyYet();
        // value check: ensure contract has enough ETH for the call's value + gas
        if (value > address(this).balance - totalLockedBalances[ETH_TOKEN_ADDRESS]) {
             // This is a simplified check. Real check needs to consider gas too.
             revert ChronoVault__NotEnoughUnlockedBalance();
        }


        uint256 callId = nextCallId++;
        scheduledCalls[callId] = ScheduledCall({
            executeTime: executeTime,
            target: target,
            data: data,
            value: value,
            status: ScheduledCallStatus.Pending,
            scheduler: msg.sender
        });

        emit ScheduledCallCreated(callId, target, executeTime, msg.sender);
    }

    /// @notice Executes a scheduled call if the time has passed and it's pending.
    /// Can potentially be called by anyone (keeper network pattern) to enable execution.
    /// The cost of execution is paid by the caller's gas.
    /// @param callId The ID of the scheduled call.
    function executeScheduledCall(uint256 callId) external nonReentrant scheduledCallExists(callId) {
        ScheduledCall storage callEntry = scheduledCalls[callId];

        if (callEntry.status != ScheduledCallStatus.Pending) revert ChronoVault__ScheduledCallAlreadyExecutedOrFailed();
        if (block.timestamp < callEntry.executeTime) revert ChronoVault__ScheduledCallNotReadyYet();

        // Important: Use call opcode with reentrancy protection (nonReentrant modifier helps, but call itself is risky)
        // The ReentrancyGuard on the *external* call ensures that the target cannot call back into ChronoVault
        // and re-trigger `executeScheduledCall` on the same instance before its state is updated.
        (bool success, ) = callEntry.target.call{value: callEntry.value}(callEntry.data);

        if (success) {
            callEntry.status = ScheduledCallStatus.ExecutedSuccess;
            emit ScheduledCallExecuted(callId, true);
        } else {
            // Note: A failed call could be temporary (e.g., target ran out of gas, or temporary condition)
            // Or it could be permanent (e.g., invalid data, target doesn't exist).
            // A more advanced implementation might allow retries or have an explicit permanent failure status.
            // For this example, we'll mark it as permanently failed on first failure.
             callEntry.status = ScheduledCallStatus.ExecutedFailedPermanent;
            emit ScheduledCallExecuted(callId, false);
            revert ChronoVault__CallExecutionFailed(); // Revert the transaction if the scheduled call failed
        }
    }

    /// @notice Allows the owner to cancel a scheduled call.
    /// @param callId The ID of the scheduled call.
    function cancelScheduledCall(uint256 callId) external onlyOwner scheduledCallExists(callId) {
         ScheduledCall storage callEntry = scheduledCalls[callId];

        if (callEntry.status != ScheduledCallStatus.Pending) revert ChronoVault__ScheduledCallAlreadyExecutedOrFailed();

        callEntry.status = ScheduledCallStatus.Cancelled;
        emit ScheduledCallCancelled(callId, msg.sender);
    }

    /* --- Guardian Functions --- */

    /// @notice Adds a guardian address. Only owner.
    /// @param guardian The address to add as a guardian.
    function addGuardian(address guardian) external onlyOwner {
        if (guardian == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
        if (_isGuardian[guardian]) revert ChronoVault__GuardianAlreadyAdded();
        _isGuardian[guardian] = true;
        _guardians.push(guardian);
        emit GuardianAdded(guardian);
    }

    /// @notice Removes a guardian address. Only owner.
    /// @param guardian The address to remove.
    function removeGuardian(address guardian) external onlyOwner {
        if (!_isGuardian[guardian]) revert ChronoVault__NotAGuardian();

        _isGuardian[guardian] = false;

        // Remove from dynamic array - costly, consider alternatives for large lists
        for (uint i = 0; i < _guardians.length; i++) {
            if (_guardians[i] == guardian) {
                _guardians[i] = _guardians[_guardians.length - 1];
                _guardians.pop();
                break;
            }
        }
        // Any existing assertions by this guardian remain in storage but are irrelevant once they are not a guardian.
        emit GuardianRemoved(guardian);
    }

    /// @notice Allows a guardian to assert that a specific condition has been met.
    /// This assertion can then potentially trigger conditional locks or guardian-specific actions.
    /// @param conditionIdentifier The identifier of the condition being asserted.
    function assertCondition(uint256 conditionIdentifier) external onlyGuardian {
        if (conditionIdentifier == 0) revert ChronoVault__InvalidVestingSchedule(); // Identifier 0 reserved
         if (guardianConditionAssertions[msg.sender][conditionIdentifier]) revert ChronoVault__ConditionAlreadyAsserted(); // Avoid re-asserting

        guardianConditionAssertions[msg.sender][conditionIdentifier] = true;
        emit ConditionAsserted(msg.sender, conditionIdentifier);
    }

    /// @notice Allows a guardian to cancel a scheduled call IF a specific condition (e.g., owner inactivity) has been met.
    /// This is an example guardian-specific action based on a condition.
    /// @param callId The ID of the scheduled call to cancel.
    function guardianCancelScheduledCall(uint256 callId) external onlyGuardian scheduledCallExists(callId) {
        ScheduledCall storage callEntry = scheduledCalls[callId];

        if (callEntry.status != ScheduledCallStatus.Pending) revert ChronoVault__ScheduledCallAlreadyExecutedOrFailed();

        // Example Condition Check: Has this guardian asserted the OWNER_INACTIVITY_90_DAYS condition?
        if (!guardianConditionAssertions[msg.sender][CONDITION_OWNER_INACTIVITY_90_DAYS]) {
             revert ChronoVault__OwnerActivityConditionNotMet();
        }

        callEntry.status = ScheduledCallStatus.Cancelled;
        emit ScheduledCallCancelled(callId, msg.sender);
    }

    /* --- Owner/Admin Functions --- */
    // Ownable functions transferOwnership and renounceOwnership are inherited.

    /// @notice Allows the owner to cancel a specific lock. Only permitted before the lock's start time (for time/vesting) or if no conditions met (for conditional).
    /// Funds are returned to the original locker.
    /// @param lockId The ID of the lock to cancel.
    function cancelSpecificLock(uint256 lockId) external onlyOwner nonReentrant lockExists(lockId) {
        LockEntry storage lock = locks[lockId];

        if (lock.status != LockStatus.Active) revert ChronoVault__LockAlreadyReleased(); // Or already cancelled

        // Define cancellation conditions
        bool canCancel = false;
        if (lock.lockType == LockType.TimeLock) {
            // Can cancel if release time is in the future (lock hasn't started)
            if (block.timestamp < lock.releaseTime) canCancel = true;
        } else if (lock.lockType == LockType.VestingLock) {
            // Can cancel if the first vesting step hasn't passed
            if (lock.vestingSteps.length > 0 && block.timestamp < lock.vestingSteps[0].releaseTime) canCancel = true;
             // More complex rules could be implemented here (e.g., partial cancellation)
        } else if (lock.lockType == LockType.ConditionalLock) {
             // Can cancel if no guardian has asserted the condition yet
            bool conditionAsserted = false;
            for (uint i = 0; i < _guardians.length; i++) {
                if (guardianConditionAssertions[_guardians[i]][lock.conditionIdentifier]) {
                    conditionAsserted = true;
                    break;
                }
            }
            if (!conditionAsserted) canCancel = true;
        }

        if (!canCancel) revert ChronoVault__LockNotCancelledYet(); // Specific error for cancellation timing/condition

        lock.status = LockStatus.Cancelled;
        totalLockedBalances[lock.token] -= lock.totalAmount;

        _safeTransfer(lock.token, lock.locker, lock.totalAmount);
        emit LockCancelled(lockId, lock.token, lock.locker, lock.totalAmount);
    }


    /* --- View Functions --- */

    /// @notice Gets the details of a specific lock.
    /// @param lockId The ID of the lock.
    /// @return LockEntry struct containing all details.
    function getLockDetails(uint256 lockId) external view lockExists(lockId) returns (LockEntry memory) {
        return locks[lockId];
    }

    /// @notice Gets the details of a specific scheduled call.
    /// @param callId The ID of the scheduled call.
    /// @return ScheduledCall struct containing all details.
    function getScheduledCallDetails(uint256 callId) external view scheduledCallExists(callId) returns (ScheduledCall memory) {
        return scheduledCalls[callId];
    }

    /// @notice Gets the list of current guardian addresses.
    /// @return Array of guardian addresses.
    function getGuardians() external view returns (address[] memory) {
        return _guardians;
    }

    /// @notice Checks if a specific guardian has asserted a specific condition.
    /// @param guardian The guardian's address.
    /// @param conditionIdentifier The identifier of the condition.
    /// @return True if the guardian has asserted the condition, false otherwise.
    function getGuardianConditionStatus(address guardian, uint256 conditionIdentifier) external view returns (bool) {
        return guardianConditionAssertions[guardian][conditionIdentifier];
    }

     /// @notice Checks if an address is currently a guardian.
     /// @param account The address to check.
     /// @return True if the address is a guardian, false otherwise.
    function isGuardian(address account) external view returns (bool) {
        return _isGuardian[account];
    }

    /// @notice Gets the total amount of a specific token currently held in all active locks.
    /// @param token The address of the token (address(0) for ETH).
    /// @return The total locked amount.
    function getTotalLockedBalance(address token) external view returns (uint256) {
        return totalLockedBalances[token];
    }

    /// @notice Gets the total balance of a specific token held by the contract.
    /// @param token The address of the token (address(0) for ETH).
    /// @return The total balance.
    function getAssetTotalBalance(address token) external view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }


    /// @notice Calculates the amount of a specific token currently not held in any active lock.
    /// This is the total balance minus the total locked balance.
    /// @param token The address of the token (address(0) for ETH).
    /// @return The unlocked amount.
    function getUnlockedBalance(address token) external view returns (uint256) {
        uint256 total = getAssetTotalBalance(token);
        uint256 locked = totalLockedBalances[token];
        return total > locked ? total - locked : 0;
    }

    /* --- Internal Helpers --- */

    /// @dev Internal function to handle fund transfer from locker to vault and validation for locking.
    /// @param token The address of the token (address(0) for ETH).
    /// @param from The address transferring funds (usually msg.sender).
    /// @param amount The amount to transfer.
    /// @param locker The beneficiary (used here mainly for context, actual transfer is to address(this)).
    function _transferFundsForLock(address token, address from, uint256 amount, address locker) internal {
         // Check if contract has enough balance *before* locking
        uint256 currentBalance = getAssetTotalBalance(token);
        if (amount > currentBalance) {
             // This might happen if someone tries to lock more than is available in the vault.
             // For deposits, this check is implicitly done by the transfer.
             // However, if funds were deposited *before* locking, this check is necessary.
             // Alternatively, force deposits to happen *in the same tx* as locking.
             // Current design allows separate deposit/lock.
             revert ChronoVault__NotEnoughUnlockedBalance(); // Or a more specific error like InsufficientVaultBalance
        }

        // If locking from caller's own balance, need transferFrom (ERC20) or payable (ETH)
        // This design assumes funds are already in the vault or sent with the ETH lock transaction.
        // A more common pattern might be `createLock(..., amount)` which pulls `amount` from `msg.sender`.
        // Let's stick to the current design where funds must be *in the vault* already.
        // So, the check above `amount > currentBalance` is relevant.
        // If the intent was to pull from sender:
        // if (token == ETH_TOKEN_ADDRESS) {
        //     require(msg.value >= amount, "ETH not sent");
        //     // ETH is already in the contract via `receive()` or `depositETH()`
        // } else {
        //     IERC20 tokenContract = IERC20(token);
        //     bool success = tokenContract.transferFrom(from, address(this), amount);
        //     if (!success) revert ChronoVault__NoFundsToRelease(); // Use specific error
        // }

         // With the current design (funds must be in vault):
         // No transfer logic needed in _transferFundsForLock, just the balance check
         // The deposit functions handle getting funds into the vault.
    }


    /// @dev Internal function to handle safe transfers of ETH or ERC20 tokens.
    /// @param token The address of the token (address(0) for ETH).
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    function _safeTransfer(address token, address to, uint256 amount) internal nonReentrant {
        if (to == address(0)) revert ChronoVault__ZeroAddressNotAllowed();
        if (amount == 0) return; // No-op for zero amount

        if (token == ETH_TOKEN_ADDRESS) {
            (bool success, ) = payable(to).call{value: amount}("");
            if (!success) revert ChronoVault__NoFundsToRelease(); // Using a general error
        } else {
            IERC20 tokenContract = IERC20(token);
             // Check recipient balance before and after transfer for basic validation
            uint256 recipientBalanceBefore = tokenContract.balanceOf(to);
            bool success = tokenContract.transfer(to, amount);
            if (!success) revert ChronoVault__NoFundsToRelease(); // Using a general error
            // Optional: More robust check against ERC20 return values and balance changes
             require(tokenContract.balanceOf(to) == recipientBalanceBefore + amount, "ERC20 transfer failed or incorrect amount");
        }
    }
}
```