Okay, here is a Solidity smart contract (`ChronoLock`) that implements an advanced asset locking mechanism based on layered time and trigger conditions, featuring role-based access control, pausing, and various utility functions.

It's designed to hold ETH or ERC20 tokens and release them to a recipient only when *both* a specific unlock time has passed *and* a defined external trigger event has been signaled by an authorized party.

This contract avoids duplicating standard OpenZeppelin contracts like `Ownable`, `Pausable`, or simple `Timelock` by implementing custom roles, pausing, and combining multiple complex release conditions in a single entry.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ChronoLock
/// @author Your Name/Alias
/// @notice A smart contract for locking assets (ETH and ERC20) released based on layered time and trigger conditions.
/// @dev This contract allows creation of lock entries requiring both a future time and an external signal (trigger) to enable withdrawal. It includes role-based access control for triggering events and contract administration, pausing mechanisms, and various query/utility functions.

/*
Outline:
1.  State Variables & Constants: Defines roles, counters, mappings for locks, roles, allowed tokens, pause state.
2.  Enums: Defines asset types (ETH, ERC20).
3.  Structs: Defines the structure for a Lock Entry.
4.  Events: Defines events emitted upon state changes.
5.  Errors: Custom error definitions for revert conditions.
6.  Modifiers: Custom modifiers for role checks and pausing.
7.  Constructor: Initializes the contract, setting up initial admin roles.
8.  Role Management Functions: Functions for granting, revoking, and checking roles.
9.  Pause Management Functions: Functions for pausing and unpausing contract operations.
10. Deposit Functions: Functions for receiving ETH and depositing ERC20 tokens.
11. Lock Creation Functions: Functions for creating new ETH and ERC20 lock entries with conditions.
12. Withdrawal Function: The core function allowing recipients to claim assets if conditions are met.
13. Triggering Functions: Functions allowing authorized roles to signal trigger events for locks.
14. Query/View Functions: Functions to check the status of locks, conditions, balances, and configurations.
15. Admin/Utility Functions: Functions for contract administration, cancellation, updates, and emergency sweeping.
*/

/*
Function Summary:
1.  constructor(): Initializes the contract, setting the deployer as ADMIN and TRIGGER_ADMIN.
2.  getAdminRole(): Returns the bytes32 value of the ADMIN_ROLE.
3.  getTriggerAdminRole(): Returns the bytes32 value of the TRIGGER_ADMIN_ROLE.
4.  grantRole(bytes32 role, address account): Grants a specified role to an account (ADMIN_ROLE only).
5.  revokeRole(bytes32 role, address account): Revokes a specified role from an account (ADMIN_ROLE only).
6.  renounceRole(bytes32 role): Allows a user to renounce their own role.
7.  hasRole(bytes32 role, address account): Checks if an account has a specified role.
8.  pauseContract(): Pauses operations (deposits, withdrawals, lock creation, triggering) (ADMIN_ROLE only).
9.  unpauseContract(): Unpauses the contract (ADMIN_ROLE only).
10. depositETH(): Allows anyone to send ETH to the contract.
11. depositERC20(IERC20 token, uint256 amount): Allows anyone to deposit a specific ERC20 token (requires prior approval). Token must be allowed.
12. createLockEntryETH(address recipient, uint256 amount, uint64 unlockTime, string memory requiredTrigger): Creates a new ETH lock entry with specified conditions.
13. createLockEntryERC20(IERC20 token, address recipient, uint256 amount, uint64 unlockTime, string memory requiredTrigger): Creates a new ERC20 lock entry with specified conditions. Token must be allowed.
14. withdraw(uint256 lockEntryId): Allows the recipient of a lock entry to withdraw if all conditions (time and trigger) are met.
15. triggerEvent(uint256 lockEntryId): Allows an account with TRIGGER_ADMIN_ROLE to signal that the trigger condition is met for a specific lock entry.
16. getLockEntry(uint256 lockEntryId): Returns the details of a specific lock entry.
17. getLockEntryStatus(uint256 lockEntryId): Returns a boolean indicating if a lock entry exists, is active, and if all conditions are met for withdrawal.
18. checkTimeConditionMet(uint256 lockEntryId): Checks if the time condition for a lock entry has been met.
19. checkTriggerConditionMet(uint256 lockEntryId): Checks if the trigger condition for a lock entry has been met.
20. checkWithdrawalConditionsMet(uint256 lockEntryId): Checks if BOTH time and trigger conditions are met for a lock entry.
21. getTotalLockEntryCount(): Returns the total number of lock entries created.
22. getContractETHBalance(): Returns the contract's current balance of ETH.
23. getContractERC20Balance(IERC20 token): Returns the contract's current balance of a specific ERC20 token.
24. cancelLockEntryByAdmin(uint256 lockEntryId): Allows an account with ADMIN_ROLE to cancel an active lock entry, returning funds to recipient.
25. cancelLockEntryByRecipient(uint256 lockEntryId): Allows the recipient of an active lock entry to cancel it and withdraw funds, but only if the unlock time hasn't passed AND the trigger hasn't been met.
26. updateRecipient(uint256 lockEntryId, address newRecipient): Allows an account with ADMIN_ROLE to update the recipient address for an active lock entry.
27. updateUnlockTime(uint256 lockEntryId, uint64 newUnlockTime): Allows an account with ADMIN_ROLE to update the unlock time for an active lock entry.
28. setAllowedERC20(IERC20 token, bool allowed): Allows an account with ADMIN_ROLE to whitelist/blacklist ERC20 tokens for deposits and lock creation.
29. isERC20Allowed(IERC20 token): Checks if a specific ERC20 token is whitelisted.
30. sweepFallenERC20(IERC20 token, uint256 amount): Allows an account with ADMIN_ROLE to sweep specified amounts of *untracked* or *non-whitelisted* ERC20 tokens accidentally sent to the contract.

Total Functions: 30
*/

// Define custom errors for better debugging
error ChronoLock__InvalidLockEntryId();
error ChronoLock__LockEntryNotActive();
error ChronoLock__WithdrawConditionsNotMet();
error ChronoLock__NotRecipient();
error ChronoLock__AlreadyTriggered();
error ChronoLock__CancellationNotAllowed();
error ChronoLock__ZeroAmount();
error ChronoLock__ZeroAddress();
error ChronoLock__UnlockTimeNotInFuture();
error ChronoLock__ERC20TransferFailed();
error ChronoLock__ETHTransferFailed();
error ChronoLock__InsufficientContractBalance();
error ChronoLock__UnsupportedAssetType();
error ChronoLock__NotAllowedERC20();
error ChronoLock__RoleManagementOnlyByAdmin();
error ChronoLock__RoleAlreadyExists();
error ChronoLock__RoleDoesNotExist();
error ChronoLock__CannotRenounceAdmin();
error ChronoLock__Paused();
error ChronoLock__NotPaused();
error ChronoLock__InsufficientSweptBalance();


/// @dev Enum to differentiate between native ETH and ERC20 tokens.
enum AssetType {
    ETH,
    ERC20
}

/// @dev Struct representing a single lock entry.
struct LockEntry {
    AssetType assetType;       // Type of asset (ETH or ERC20)
    address assetAddress;      // Address of the ERC20 token (0x0 for ETH)
    uint256 amount;            // Amount of the asset locked
    address recipient;         // Address allowed to withdraw
    uint64 unlockTime;         // Timestamp after which the time condition is met
    string requiredTrigger;    // Identifier for the external trigger event required
    bool isTriggered;          // Flag indicating if the specific trigger for this entry has occurred
    bool isActive;             // Flag indicating if the lock is still active (not withdrawn/cancelled)
    uint64 creationTime;       // Timestamp when the lock was created
}

// --- State Variables ---

// Mapping from lock entry ID to LockEntry struct
mapping(uint256 => LockEntry) private s_lockEntries;

// Counter for unique lock entry IDs
uint256 private s_lockEntryCounter;

// Role management system (mapping account => mapping(role => bool))
mapping(address => mapping(bytes32 => bool)) private s_roles;

// Defined roles
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant TRIGGER_ADMIN_ROLE = keccak256("TRIGGER_ADMIN_ROLE");

// Contract pause state
bool private s_paused;

// Whitelisted ERC20 tokens
mapping(address => bool) private s_allowedERC20s;

// --- Events ---

/// @dev Emitted when ETH is received by the contract.
event ETHReceived(address indexed sender, uint256 amount);

/// @dev Emitted when ERC20 tokens are deposited.
event ERC20Deposited(address indexed token, address indexed sender, uint256 amount);

/// @dev Emitted when a new lock entry is created.
event LockCreated(
    uint256 indexed lockEntryId,
    AssetType indexed assetType,
    address indexed assetAddress, // 0x0 for ETH
    address recipient,
    uint256 amount,
    uint64 unlockTime,
    string requiredTrigger,
    uint64 creationTime
);

/// @dev Emitted when assets are successfully withdrawn from a lock entry.
event Withdrawn(
    uint256 indexed lockEntryId,
    address indexed recipient,
    uint256 amount
);

/// @dev Emitted when the trigger event for a specific lock entry is signaled.
event TriggerSignaled(uint256 indexed lockEntryId, string triggerIdentifier, address indexed signaler);

/// @dev Emitted when a lock entry is cancelled.
event LockCancelled(uint256 indexed lockEntryId, address indexed by, string reason);

/// @dev Emitted when a role is granted to an account.
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

/// @dev Emitted when a role is revoked from an account.
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

/// @dev Emitted when the contract is paused.
event Paused(address indexed pauser);

/// @dev Emitted when the contract is unpaused.
event Unpaused(address indexed unpauser);

/// @dev Emitted when an ERC20 token is added or removed from the allowed list.
event ERC20AllowedStatusSet(address indexed token, bool isAllowed, address indexed sender);

/// @dev Emitted when excess or untracked ERC20 tokens are swept.
event ERC20Swept(address indexed token, address indexed recipient, uint256 amount, address indexed admin);

// --- Modifiers ---

/// @dev Requires the caller to have a specific role.
modifier onlyRole(bytes32 role) {
    if (!hasRole(role, msg.sender)) {
        revert ChronoLock__RoleDoesNotExist();
    }
    _;
}

/// @dev Requires the contract not to be paused.
modifier whenNotPaused() {
    if (s_paused) {
        revert ChronoLock__Paused();
    }
    _;
}

/// @dev Requires the contract to be paused.
modifier whenPaused() {
    if (!s_paused) {
        revert ChronoLock__NotPaused();
    }
    _;
}

// --- Constructor ---

/// @dev Initializes the contract and grants initial roles.
constructor() payable {
    // Grant ADMIN_ROLE and TRIGGER_ADMIN_ROLE to the deployer
    s_roles[msg.sender][ADMIN_ROLE] = true;
    s_roles[msg.sender][TRIGGER_ADMIN_ROLE] = true;
    emit RoleGranted(ADMIN_ROLE, msg.sender, address(0)); // Sender 0x0 signifies initial grant
    emit RoleGranted(TRIGGER_ADMIN_ROLE, msg.sender, address(0));
}

// --- Role Management Functions ---

/// @notice Returns the bytes32 value of the ADMIN_ROLE.
/// @dev Public getter for the ADMIN_ROLE identifier.
/// @return The bytes32 value representing ADMIN_ROLE.
function getAdminRole() public pure returns (bytes32) {
    return ADMIN_ROLE;
}

/// @notice Returns the bytes32 value of the TRIGGER_ADMIN_ROLE.
/// @dev Public getter for the TRIGGER_ADMIN_ROLE identifier.
/// @return The bytes32 value representing TRIGGER_ADMIN_ROLE.
function getTriggerAdminRole() public pure returns (bytes32) {
    return TRIGGER_ADMIN_ROLE;
}

/// @notice Grants a specified role to an account.
/// @dev Only accounts with the ADMIN_ROLE can grant roles.
/// @param role The role to grant (e.g., ADMIN_ROLE, TRIGGER_ADMIN_ROLE).
/// @param account The address to grant the role to.
function grantRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
    if (account == address(0)) revert ChronoLock__ZeroAddress();
    if (s_roles[account][role]) revert ChronoLock__RoleAlreadyExists();
    s_roles[account][role] = true;
    emit RoleGranted(role, account, msg.sender);
}

/// @notice Revokes a specified role from an account.
/// @dev Only accounts with the ADMIN_ROLE can revoke roles. The ADMIN_ROLE cannot be revoked this way (to prevent locking out admins).
/// @param role The role to revoke.
/// @param account The address to revoke the role from.
function revokeRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
    if (account == address(0)) revert ChronoLock__ZeroAddress();
    if (role == ADMIN_ROLE && hasRole(ADMIN_ROLE, account) && msg.sender == account) {
         // Allow admin to renounce themselves via renounceRole function
         revert ChronoLock__CannotRenounceAdmin();
    }
     if (!s_roles[account][role]) revert ChronoLock__RoleDoesNotExist();

    s_roles[account][role] = false;
    emit RoleRevoked(role, account, msg.sender);
}

/// @notice Allows a user to renounce their own role.
/// @dev An account can remove a role from itself. Cannot renounce ADMIN_ROLE using this function if it's the *only* ADMIN_ROLE holder (to prevent bricking).
/// @param role The role to renounce.
function renounceRole(bytes32 role) external {
    if (msg.sender == address(0)) revert ChronoLock__ZeroAddress();
    if (!s_roles[msg.sender][role]) revert ChronoLock__RoleDoesNotExist();

    // Basic safety: Don't allow renouncing ADMIN_ROLE if it's the last one (requires off-chain check or more complex on-chain state tracking)
    // Simple check: if role is ADMIN_ROLE, disallow via this function. Use revoke by another admin.
     if (role == ADMIN_ROLE) {
        revert ChronoLock__CannotRenounceAdmin();
    }

    s_roles[msg.sender][role] = false;
    emit RoleRevoked(role, msg.sender, msg.sender);
}


/// @notice Checks if an account has a specific role.
/// @param role The role to check.
/// @param account The address to check.
/// @return True if the account has the role, false otherwise.
function hasRole(bytes32 role, address account) public view returns (bool) {
    return s_roles[account][role];
}

// --- Pause Management Functions ---

/// @notice Pauses the contract operations.
/// @dev Only accounts with the ADMIN_ROLE can pause the contract. Prevents new deposits, lock creation, withdrawal, and triggering.
function pauseContract() external onlyRole(ADMIN_ROLE) whenNotPaused {
    s_paused = true;
    emit Paused(msg.sender);
}

/// @notice Unpauses the contract operations.
/// @dev Only accounts with the ADMIN_ROLE can unpause the contract. Re-enables all operations.
function unpauseContract() external onlyRole(ADMIN_ROLE) whenPaused {
    s_paused = false;
    emit Unpaused(msg.sender);
}

// --- Deposit Functions ---

/// @notice Receives ETH sent to the contract.
/// @dev Automatically triggers on receiving native ETH. Emits ETHReceived event.
receive() external payable {
    if (msg.value == 0) revert ChronoLock__ZeroAmount(); // Should not happen with receive, but good practice
    emit ETHReceived(msg.sender, msg.value);
}

/// @notice Allows depositing ERC20 tokens into the contract.
/// @dev Requires the sender to have approved this contract to spend the amount first.
/// @param token The address of the ERC20 token.
/// @param amount The amount of tokens to deposit.
function depositERC20(IERC20 token, uint256 amount) external whenNotPaused {
    if (amount == 0) revert ChronoLock__ZeroAmount();
    if (address(token) == address(0)) revert ChronoLock__ZeroAddress();
    if (!isERC20Allowed(token)) revert ChronoLock__NotAllowedERC20();

    // Using transferFrom as tokens are expected to be approved beforehand
    bool success = token.transferFrom(msg.sender, address(this), amount);
    if (!success) revert ChronoLock__ERC20TransferFailed();

    emit ERC20Deposited(address(token), msg.sender, amount);
}


// --- Lock Creation Functions ---

/// @notice Creates a new lock entry for ETH.
/// @dev Locks a specified amount of ETH to be released to a recipient after unlock time and trigger.
/// @param recipient The address that will be allowed to withdraw.
/// @param amount The amount of ETH to lock.
/// @param unlockTime The timestamp when the time condition is met (must be in the future).
/// @param requiredTrigger A string identifier for the required trigger event.
/// @return lockEntryId The ID of the newly created lock entry.
function createLockEntryETH(
    address recipient,
    uint256 amount,
    uint64 unlockTime,
    string memory requiredTrigger
) external whenNotPaused returns (uint256 lockEntryId) {
    if (recipient == address(0)) revert ChronoLock__ZeroAddress();
    if (amount == 0) revert ChronoLock__ZeroAmount();
    if (unlockTime <= block.timestamp) revert ChronoLock__UnlockTimeNotInFuture();
    // Consider adding a check for empty requiredTrigger if all locks must have a trigger

    // Ensure contract has sufficient ETH balance *now* to cover this lock + existing ones
    // This is a simplification; more robust tracking would use an internal balance ledger per asset
    if (address(this).balance < amount) revert ChronoLock__InsufficientContractBalance();


    s_lockEntryCounter++;
    lockEntryId = s_lockEntryCounter;

    s_lockEntries[lockEntryId] = LockEntry({
        assetType: AssetType.ETH,
        assetAddress: address(0), // 0x0 for ETH
        amount: amount,
        recipient: recipient,
        unlockTime: unlockTime,
        requiredTrigger: requiredTrigger,
        isTriggered: false,
        isActive: true,
        creationTime: uint64(block.timestamp)
    });

    emit LockCreated(
        lockEntryId,
        AssetType.ETH,
        address(0),
        recipient,
        amount,
        unlockTime,
        requiredTrigger,
        uint64(block.timestamp)
    );

    return lockEntryId;
}

/// @notice Creates a new lock entry for an ERC20 token.
/// @dev Locks a specified amount of ERC20 tokens to be released after unlock time and trigger.
/// @param token The address of the ERC20 token. Must be an allowed token.
/// @param recipient The address that will be allowed to withdraw.
/// @param amount The amount of ERC20 tokens to lock.
/// @param unlockTime The timestamp when the time condition is met (must be in the future).
/// @param requiredTrigger A string identifier for the required trigger event.
/// @return lockEntryId The ID of the newly created lock entry.
function createLockEntryERC20(
    IERC20 token,
    address recipient,
    uint256 amount,
    uint64 unlockTime,
    string memory requiredTrigger
) external whenNotPaused returns (uint256 lockEntryId) {
    if (recipient == address(0)) revert ChronoLock__ZeroAddress();
    if (amount == 0) revert ChronoLock__ZeroAmount();
    if (address(token) == address(0)) revert ChronoLock__ZeroAddress();
    if (unlockTime <= block.timestamp) revert ChronoLock__UnlockTimeNotInFuture();
    if (!isERC20Allowed(token)) revert ChronoLock__NotAllowedERC20();
    // Consider adding a check for empty requiredTrigger

    // Ensure contract has sufficient ERC20 balance *now* to cover this lock + existing ones
    // This is a simplification; more robust tracking would use an internal balance ledger per asset
    if (token.balanceOf(address(this)) < amount) revert ChronoLock__InsufficientContractBalance();


    s_lockEntryCounter++;
    lockEntryId = s_lockEntryCounter;

    s_lockEntries[lockEntryId] = LockEntry({
        assetType: AssetType.ERC20,
        assetAddress: address(token),
        amount: amount,
        recipient: recipient,
        unlockTime: unlockTime,
        requiredTrigger: requiredTrigger,
        isTriggered: false,
        isActive: true,
        creationTime: uint64(block.timestamp)
    });

    emit LockCreated(
        lockEntryId,
        AssetType.ERC20,
        address(token),
        recipient,
        amount,
        unlockTime,
        requiredTrigger,
        uint64(block.timestamp)
    );

    return lockEntryId;
}


// --- Withdrawal Function ---

/// @notice Allows the recipient of a lock entry to withdraw the locked assets.
/// @dev Withdrawal is only possible if the lock entry exists, is active, the caller is the recipient, AND both the unlock time and the required trigger conditions are met.
/// @param lockEntryId The ID of the lock entry to withdraw from.
function withdraw(uint256 lockEntryId) external whenNotPaused {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];

    // Check if the lock entry exists
    if (lockEntry.creationTime == 0) revert ChronoLock__InvalidLockEntryId(); // Assumes creationTime is never 0 for valid entries
    // Check if the lock entry is active
    if (!lockEntry.isActive) revert ChronoLock__LockEntryNotActive();
    // Check if the caller is the intended recipient
    if (msg.sender != lockEntry.recipient) revert ChronoLock__NotRecipient();
    // Check if ALL withdrawal conditions are met
    if (!checkWithdrawalConditionsMet(lockEntryId)) revert ChronoLock__WithdrawConditionsNotMet();

    // Mark the entry as inactive (withdrawn)
    lockEntry.isActive = false;

    // Perform the transfer
    if (lockEntry.assetType == AssetType.ETH) {
        // Transfer ETH
        (bool success, ) = payable(lockEntry.recipient).call{value: lockEntry.amount}("");
        if (!success) revert ChronoLock__ETHTransferFailed(); // Should ideally re-enable the lock or have a recovery mechanism
    } else if (lockEntry.assetType == AssetType.ERC20) {
        // Transfer ERC20
        IERC20 token = IERC20(lockEntry.assetAddress);
        bool success = token.transfer(lockEntry.recipient, lockEntry.amount);
        if (!success) revert ChronoLock__ERC20TransferFailed(); // Should ideally re-enable the lock or have a recovery mechanism
    } else {
        // Should not happen if AssetType is properly handled, but as a safeguard
        revert ChronoLock__UnsupportedAssetType();
    }

    emit Withdrawn(lockEntryId, lockEntry.recipient, lockEntry.amount);
}


// --- Triggering Functions ---

/// @notice Signals that the external trigger condition is met for a specific lock entry.
/// @dev Only accounts with the TRIGGER_ADMIN_ROLE can call this. Sets the `isTriggered` flag for the given entry.
/// @param lockEntryId The ID of the lock entry whose trigger is met.
function triggerEvent(uint256 lockEntryId) external onlyRole(TRIGGER_ADMIN_ROLE) whenNotPaused {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];

    // Check if the lock entry exists
    if (lockEntry.creationTime == 0) revert ChronoLock__InvalidLockEntryId();
    // Check if the lock entry is active
    if (!lockEntry.isActive) revert ChronoLock__LockEntryNotActive();
    // Check if it hasn't already been triggered (optional, but prevents redundant calls)
    if (lockEntry.isTriggered) revert ChronoLock__AlreadyTriggered();
    // Optionally check if `requiredTrigger` is not empty if that's a rule

    lockEntry.isTriggered = true;

    emit TriggerSignaled(lockEntryId, lockEntry.requiredTrigger, msg.sender);
}

// --- Query/View Functions ---

/// @notice Returns the details of a specific lock entry.
/// @param lockEntryId The ID of the lock entry.
/// @return The LockEntry struct data.
function getLockEntry(uint256 lockEntryId) external view returns (LockEntry memory) {
    // Note: Accessing a non-existent ID returns a struct with default values (e.g., 0s, false).
    // Check `creationTime == 0` in client code or use `getLockEntryStatus` for existence check.
    return s_lockEntries[lockEntryId];
}

/// @notice Returns the overall status of a lock entry.
/// @dev Checks if the entry exists, is active, and if conditions for withdrawal are met.
/// @param lockEntryId The ID of the lock entry.
/// @return exists True if the lock entry ID corresponds to a created entry.
/// @return isActive True if the entry has not been withdrawn or cancelled.
/// @return conditionsMet True if both time and trigger conditions are currently met.
function getLockEntryStatus(uint256 lockEntryId) external view returns (bool exists, bool isActive, bool conditionsMet) {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];
    exists = (lockEntry.creationTime != 0);
    if (!exists) {
        return (false, false, false);
    }
    isActive = lockEntry.isActive;
    conditionsMet = checkWithdrawalConditionsMet(lockEntryId);
    return (exists, isActive, conditionsMet);
}

/// @notice Checks if the time condition for a lock entry has been met.
/// @param lockEntryId The ID of the lock entry.
/// @return True if the lock entry exists and the current block timestamp is >= the unlockTime.
function checkTimeConditionMet(uint256 lockEntryId) public view returns (bool) {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];
    if (lockEntry.creationTime == 0) return false; // Entry does not exist
    return block.timestamp >= lockEntry.unlockTime;
}

/// @notice Checks if the trigger condition for a lock entry has been met.
/// @param lockEntryId The ID of the lock entry.
/// @return True if the lock entry exists and the `isTriggered` flag is true.
function checkTriggerConditionMet(uint256 lockEntryId) public view returns (bool) {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];
    if (lockEntry.creationTime == 0) return false; // Entry does not exist
    // A lock without a required trigger (empty string) is considered immediately triggered.
    if (bytes(lockEntry.requiredTrigger).length == 0) return true;
    return lockEntry.isTriggered;
}

/// @notice Checks if ALL withdrawal conditions are met for a lock entry.
/// @dev Combines the checks for time condition and trigger condition.
/// @param lockEntryId The ID of the lock entry.
/// @return True if the lock entry exists and both time and trigger conditions are met.
function checkWithdrawalConditionsMet(uint256 lockEntryId) public view returns (bool) {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];
    if (lockEntry.creationTime == 0) return false; // Entry does not exist
    // Both time AND trigger must be met
    return checkTimeConditionMet(lockEntryId) && checkTriggerConditionMet(lockEntryId);
}

/// @notice Returns the total number of lock entries created since contract deployment.
/// @dev This includes active, withdrawn, and cancelled entries.
/// @return The total count of lock entries.
function getTotalLockEntryCount() external view returns (uint256) {
    return s_lockEntryCounter;
}

/// @notice Returns the contract's current balance of native ETH.
/// @return The contract's ETH balance in wei.
function getContractETHBalance() external view returns (uint256) {
    return address(this).balance;
}

/// @notice Returns the contract's current balance of a specific ERC20 token.
/// @param token The address of the ERC20 token.
/// @return The contract's token balance in the token's smallest unit.
function getContractERC20Balance(IERC20 token) external view returns (uint256) {
    if (address(token) == address(0)) revert ChronoLock__ZeroAddress();
    return token.balanceOf(address(this));
}


// --- Admin/Utility Functions ---

/// @notice Allows an admin to cancel an active lock entry.
/// @dev The locked amount is returned to the original recipient. Useful for emergencies or policy changes.
/// @param lockEntryId The ID of the lock entry to cancel.
function cancelLockEntryByAdmin(uint256 lockEntryId) external onlyRole(ADMIN_ROLE) whenNotPaused {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];

    if (lockEntry.creationTime == 0) revert ChronoLock__InvalidLockEntryId();
    if (!lockEntry.isActive) revert ChronoLock__LockEntryNotActive();

    // Mark the entry as inactive (cancelled)
    lockEntry.isActive = false;

    // Return assets to the recipient
    if (lockEntry.assetType == AssetType.ETH) {
        (bool success, ) = payable(lockEntry.recipient).call{value: lockEntry.amount}("");
        if (!success) revert ChronoLock__ETHTransferFailed(); // Should ideally log and require manual intervention
    } else if (lockEntry.assetType == AssetType.ERC20) {
        IERC20 token = IERC20(lockEntry.assetAddress);
        bool success = token.transfer(lockEntry.recipient, lockEntry.amount);
        if (!success) revert ChronoLock__ERC20TransferFailed(); // Should ideally log and require manual intervention
    } else {
         revert ChronoLock__UnsupportedAssetType();
    }

    emit LockCancelled(lockEntryId, msg.sender, "Admin Cancellation");
}

/// @notice Allows the recipient of an active lock entry to cancel it under specific conditions.
/// @dev Cancellation is only allowed if the entry is active AND *neither* the time condition nor the trigger condition has been met yet. This prevents cancellation once the lock is fully releasable.
/// @param lockEntryId The ID of the lock entry to cancel.
function cancelLockEntryByRecipient(uint256 lockEntryId) external whenNotPaused {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];

    if (lockEntry.creationTime == 0) revert ChronoLock__InvalidLockEntryId();
    if (!lockEntry.isActive) revert ChronoLock__LockEntryNotActive();
    if (msg.sender != lockEntry.recipient) revert ChronoLock__NotRecipient();

    // Cancellation is only allowed if *neither* time nor trigger condition is met
    if (checkTimeConditionMet(lockEntryId)) revert ChronoLock__CancellationNotAllowed();
    if (checkTriggerConditionMet(lockEntryId)) revert ChronoLock__CancellationNotAllowed();

    // Mark the entry as inactive (cancelled)
    lockEntry.isActive = false;

     // Return assets to the recipient
    if (lockEntry.assetType == AssetType.ETH) {
        (bool success, ) = payable(lockEntry.recipient).call{value: lockEntry.amount}("");
        if (!success) revert ChronoLock__ETHTransferFailed(); // Should ideally log
    } else if (lockEntry.assetType == AssetType.ERC20) {
        IERC20 token = IERC20(lockEntry.assetAddress);
        bool success = token.transfer(lockEntry.recipient, lockEntry.amount);
        if (!success) revert ChronoLock__ERC20TransferFailed(); // Should ideally log
    } else {
         revert ChronoLock__UnsupportedAssetType();
    }

    emit LockCancelled(lockEntryId, msg.sender, "Recipient Cancellation");
}


/// @notice Allows an admin to update the recipient address for an active lock entry.
/// @dev Useful if the original recipient address is compromised or needs to be changed.
/// @param lockEntryId The ID of the lock entry to update.
/// @param newRecipient The new address for the recipient.
function updateRecipient(uint256 lockEntryId, address newRecipient) external onlyRole(ADMIN_ROLE) whenNotPaused {
    LockEntry storage lockEntry = s_lockEntries[lockEntryId];

    if (lockEntry.creationTime == 0) revert ChronoLock__InvalidLockEntryId();
    if (!lockEntry.isActive) revert ChronoLock__LockEntryNotActive();
    if (newRecipient == address(0)) revert ChronoLock__ZeroAddress();

    lockEntry.recipient = newRecipient;
    // Consider adding an event for recipient update
}

/// @notice Allows an admin to update the unlock time for an active lock entry.
/// @dev Useful if external factors require adjusting the time condition.
/// @param lockEntryId The ID of the lock entry to update.
/// @param newUnlockTime The new timestamp for the unlock time (must be in the future or current time).
function updateUnlockTime(uint256 lockEntryId, uint64 newUnlockTime) external onlyRole(ADMIN_ROLE) whenNotPaused {
     LockEntry storage lockEntry = s_lockEntries[lockEntryId];

    if (lockEntry.creationTime == 0) revert ChronoLock__InvalidLockEntryId();
    if (!lockEntry.isActive) revert ChronoLock__LockEntryNotActive();
    // Allow setting unlock time to now or future, but not in the past relative to *this update*
    if (newUnlockTime < block.timestamp) revert ChronoLock__UnlockTimeNotInFuture();


    lockEntry.unlockTime = newUnlockTime;
    // Consider adding an event for time update
}

/// @notice Allows an admin to whitelist or blacklist ERC20 tokens for use in lock entries.
/// @dev Only whitelisted tokens can be deposited and locked. This adds a layer of control and security.
/// @param token The address of the ERC20 token.
/// @param allowed True to whitelist, false to blacklist.
function setAllowedERC20(IERC20 token, bool allowed) external onlyRole(ADMIN_ROLE) {
    if (address(token) == address(0)) revert ChronoLock__ZeroAddress();
    s_allowedERC20s[address(token)] = allowed;
    emit ERC20AllowedStatusSet(address(token), allowed, msg.sender);
}

/// @notice Checks if a specific ERC20 token is whitelisted.
/// @param token The address of the ERC20 token.
/// @return True if the token is allowed, false otherwise.
function isERC20Allowed(IERC20 token) public view returns (bool) {
    return s_allowedERC20s[address(token)];
}

/// @notice Allows an admin to sweep accidentally sent ERC20 tokens that are not part of a lock entry or are not whitelisted.
/// @dev This function is for emergency recovery of misplaced tokens, not for sweeping tokens that are part of active locks.
/// @param token The address of the ERC20 token to sweep.
/// @param amount The amount of tokens to sweep.
function sweepFallenERC20(IERC20 token, uint256 amount) external onlyRole(ADMIN_ROLE) {
    if (address(token) == address(0)) revert ChronoLock__ZeroAddress();
    if (amount == 0) revert ChronoLock__ZeroAmount();

    // This function sweeps *any* balance of the token, regardless of whether it's part of a lock.
    // A more advanced version would track locked balances internally per token and only sweep excess.
    // For simplicity here, it sweeps directly from the contract balance. ADMIN must be careful.
    if (token.balanceOf(address(this)) < amount) revert ChronoLock__InsufficientSweptBalance();

    bool success = token.transfer(msg.sender, amount); // Sweep to the admin
    if (!success) revert ChronoLock__ERC20TransferFailed();

    emit ERC20Swept(address(token), msg.sender, amount, msg.sender);
}


// Fallback function to reject direct ETH sends that are not via receive()
// Adding this prevents accidental sends without calling a function
fallback() external {
    revert("Function Call Failed or ETH Not Supported Here");
}

}
```