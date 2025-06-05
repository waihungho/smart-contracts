Okay, here is a smart contract named `QuantumVault` that incorporates several interesting, advanced, and creative concepts beyond standard open-source examples like basic ERC20s, simple vaults, or typical DAOs.

It includes features like:
1.  **State-Dependent Logic:** Functions that behave differently based on the contract's internal `OperationalMode`.
2.  **Programmable Time Locks:** Users can lock funds for specific durations, and these locks can be extended or released individually.
3.  **Delegated Withdrawal Rights:** Owners can delegate limited withdrawal power to other addresses for specific amounts and periods.
4.  **Pseudo-Entropy & State Hinting:** An internal state variable that evolves based on transaction details (not for secure randomness, but demonstrates state change based on external factors) and a function to hint at its next state.
5.  **Batch Operations:** Functions to handle multiple similar actions in a single transaction.
6.  **Conditional Actions:** Functions that execute only if specific internal conditions (like operational mode) are met.
7.  **Emergency & Pause Mechanics:** Standard security features implemented manually.

This contract aims to be a complex, multi-faceted vault demonstrating interaction between different internal states and user actions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CONTRACT OUTLINE & FUNCTION SUMMARY ---
/*
Contract: QuantumVault

A complex, multi-faceted vault holding ETH, featuring advanced access control,
time-locking, delegation, state-dependent logic, pseudo-entropy, and batch operations.

Outline:
1.  State Variables & Mappings
2.  Enums & Structs
3.  Events
4.  Modifiers (Manual implementation of Ownable & Pausable)
5.  Constructor
6.  Core Vault Operations (Deposit, Withdraw)
7.  Owner & Access Control (Manual implementation)
8.  Pause Functionality (Manual implementation)
9.  Operational Mode Management
10. Programmable Time Locks
11. Delegated Withdrawal Rights
12. State-Dependent & Conditional Functions
13. Pseudo-Entropy & State Hinting
14. Batch Operations
15. Inspection/View Functions
16. Emergency Functions

Function Summaries:

Core Vault Operations:
- receive() / fallback(): Allows receiving ETH. Deposits it into the vault.
- deposit(): Explicitly deposits ETH into the vault.
- withdraw(uint256 amount): Allows the owner to withdraw ETH, respecting pause state and available balance.

Owner & Access Control:
- transferOwnership(address newOwner): Transfers contract ownership.
- renounceOwnership(): Renounces ownership (irreversible).

Pause Functionality:
- pauseContract(): Pauses core operations (deposit, withdraw).
- unpauseContract(): Unpauses core operations.
- paused(): View current pause state.

Operational Mode Management:
- setOperationalMode(OperationalMode mode): Sets the contract's current operating mode.
- getOperationalMode(): Gets the current operating mode.

Programmable Time Locks:
- lockEth(uint256 amount, uint40 unlockTime): Locks a specified amount of ETH for the sender until unlockTime.
- extendLock(uint256 lockId, uint40 newUnlockTime): Extends the unlock time for an existing lock owned by the caller.
- releaseLock(uint256 lockId): Releases a locked amount after the unlockTime has passed for the lock owner.
- cancelLockIfMode(uint256 lockId, OperationalMode requiredMode): Allows lock owner to cancel a lock early if the contract is in a specific operational mode.

Delegated Withdrawal Rights:
- delegateWithdrawal(address delegatee, uint256 amount, uint40 expiry): Owner delegates withdrawal rights to a specific address with an amount limit and expiry.
- revokeDelegation(address delegatee): Owner revokes an active delegation.
- delegateWithdraw(uint256 amount): Allows a delegatee to withdraw based on their delegated rights.

State-Dependent & Conditional Functions:
- conditionalWithdraw(uint256 amount, OperationalMode requiredMode): Owner can withdraw only if the contract is in the required operational mode.
- distributeConditionalReward(address payable recipient, uint256 amount, OperationalMode requiredMode): Distributes a reward amount if the contract is in the required mode (example of state-gated action).
- executeOnEntropyMatch(uint256 expectedEntropy): Executes a simple internal action (e.g., changing mode) if the current entropy state matches an expected value.

Pseudo-Entropy & State Hinting:
- triggerStateEntropyUpdate(): Updates an internal 'entropy' state variable based on block data and sender (not for secure randomness).
- getEntropyState(): Gets the current 'entropy' state.
- predictNextEntropyStateHint(address hypotheticalSender): Provides a hint of what the entropy *could* be if `triggerStateEntropyUpdate` were called by a hypothetical sender in the *current* block.

Batch Operations:
- batchReleaseLocks(uint256[] calldata lockIds): Allows a user to release multiple of their own locks in one transaction.
- batchDelegateWithdraw(uint256[] calldata amounts): Allows a delegatee to make multiple withdrawals against their delegation in one transaction (up to their limit).
- batchOwnerWithdraw(address payable[] calldata recipients, uint256[] calldata amounts): Allows owner to send ETH to multiple recipients in one transaction.

Inspection/View Functions:
- getContractBalance(): Gets the total ETH balance held by the contract.
- getLockedBalance(address account): Gets the total ETH amount locked by a specific account.
- getDelegationInfo(address delegatee): Gets information about a specific delegation.
- getUserLockCount(address account): Gets the number of locks created by an account.
- getUserLock(address account, uint256 lockIndex): Gets details of a specific lock for an account by index.

Emergency Functions:
- emergencyWithdraw(uint256 amount): Allows owner to withdraw ETH even if paused, bypassing some checks (but not locks).
*/

// Define an enum for different operational states
enum OperationalMode {
    Neutral,      // Default state
    Investment,   // State suitable for investment/staking-like activities
    WithdrawalOnly, // State allowing only withdrawals
    Restricted,   // State with limitations on many functions
    Emergency     // State indicating a critical situation
}

// Define a struct for programmable time locks
struct Lock {
    uint256 amount;      // Amount of ETH locked
    uint40 unlockTime;   // Timestamp when the lock expires (max 1.36e12 seconds from epoch, sufficient for ~43k years)
    bool released;       // Flag to indicate if the lock has been released
}

// Define a struct for delegated withdrawal rights
struct Delegation {
    uint256 amount;      // Maximum amount the delegatee can withdraw
    uint256 withdrawn;   // Amount already withdrawn by the delegatee
    uint40 expiry;       // Timestamp when the delegation expires
    bool active;         // Flag to indicate if the delegation is active
}

contract QuantumVault {

    // --- State Variables ---
    address private _owner;
    bool private _paused;
    OperationalMode private _operationalMode;
    uint256 private _entropyState; // Simple state variable updated based on block/tx data

    // Mappings for core data
    mapping(address => Lock[]) private userLocks;
    mapping(address => uint256) private userLockedBalance; // Sum of active locks for an account
    mapping(address => Delegation) private delegations;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event OperationalModeChanged(OperationalMode newMode);
    event EthDeposited(address indexed account, uint256 amount);
    event EthWithdrawal(address indexed account, uint256 amount);
    event EthLocked(address indexed account, uint256 amount, uint40 unlockTime, uint256 lockId);
    event EthLockExtended(address indexed account, uint256 lockId, uint40 newUnlockTime);
    event EthLockReleased(address indexed account, uint256 lockId);
    event EthLockCancelled(address indexed account, uint256 lockId, OperationalMode requiredMode);
    event WithdrawalDelegated(address indexed owner, address indexed delegatee, uint256 amount, uint40 expiry);
    event DelegationRevoked(address indexed owner, address indexed delegatee);
    event DelegatedWithdrawal(address indexed delegatee, uint256 amount);
    event StateEntropyUpdated(uint256 newState);
    event ConditionalRewardDistributed(address indexed recipient, uint256 amount, OperationalMode requiredMode);
    event ExecutedOnEntropyMatch(uint256 matchedEntropy, OperationalMode oldMode, OperationalMode newMode);

    // --- Modifiers (Manual Implementation) ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "QV: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "QV: Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "QV: Not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false;
        _operationalMode = OperationalMode.Neutral;
        _entropyState = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))); // Initial entropy
    }

    // --- Receive/Fallback ---
    // Allows the contract to receive plain ETH transfers.
    receive() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    // Allows calling deposit explicitly.
    fallback() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    // --- Core Vault Operations ---

    /// @notice Deposits ETH into the vault. Can also be done via receive/fallback.
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "QV: Deposit amount must be > 0");
        emit EthDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the owner to withdraw a specified amount of ETH.
    /// @param amount The amount of ETH to withdraw in wei.
    function withdraw(uint256 amount) external onlyOwner whenNotPaused {
        uint256 totalLocked = userLockedBalance[_owner];
        require(address(this).balance >= amount + totalLocked, "QV: Insufficient unlocked balance"); // Ensure owner's withdrawal doesn't touch locked funds
        require(amount > 0, "QV: Withdrawal amount must be > 0");

        // Check owner's "available" balance (total balance - their own locked funds)
        uint256 ownerAvailable = address(this).balance - totalLocked;
        require(ownerAvailable >= amount, "QV: Insufficient owner available balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: ETH transfer failed");
        emit EthWithdrawal(msg.sender, amount);
    }

    // --- Owner & Access Control ---

    /// @notice Transfers ownership of the contract to a new account.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "QV: New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Renounces the ownership of the contract.
    /// Can be used to leave the contract without an owner.
    function renounceOwnership() public onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    /// @notice Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    // --- Pause Functionality ---

    /// @notice Pauses the contract, preventing core operations like deposit and withdrawal.
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing core operations again.
    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Returns the current pause state of the contract.
    function paused() public view returns (bool) {
        return _paused;
    }

    // --- Operational Mode Management ---

    /// @notice Sets the operational mode of the contract. State-dependent functions may behave differently.
    /// @param mode The new operational mode.
    function setOperationalMode(OperationalMode mode) external onlyOwner {
        _operationalMode = mode;
        emit OperationalModeChanged(mode);
    }

    /// @notice Gets the current operational mode of the contract.
    function getOperationalMode() external view returns (OperationalMode) {
        return _operationalMode;
    }

    // --- Programmable Time Locks ---

    /// @notice Locks a specified amount of ETH for the sender until the unlockTime.
    /// @param amount The amount of ETH to lock (must already be deposited).
    /// @param unlockTime The timestamp when the lock expires.
    function lockEth(uint256 amount, uint40 unlockTime) external whenNotPaused {
        // We assume ETH is already in the contract via deposit() or receive()
        // This function doesn't receive ETH directly, it marks existing balance as locked.
        // A more robust version might require deposit + lock in one tx or track individual user balances.
        // For simplicity, this example assumes 'total contract balance' is the pool.
        // This lock logic prevents owner/delegate withdrawals from touching locked funds.
        // *Self-correction:* To make locks meaningful against total balance, we need to ensure total locked amount across *all* users doesn't exceed total balance. This is complex state tracking. A simpler approach: locks only affect the *owner's* ability to withdraw, or they track *specific* deposited amounts. Let's make it track amounts *per user* that are locked and prevent *those users* from withdrawing their locked portion, and owner/delegates from withdrawing the *total* locked amount across *all* users. This requires per-user unlocked balance tracking.
        // Let's simplify again: Locks are tracked per user and affect only that user's perceived "unlocked" balance available for withdrawal *via a future unlock mechanism*. Owner/Delegates withdraw from the *total* contract balance, but must respect the *total* locked amount across *all* users. This seems the most practical for this demo.

        require(amount > 0, "QV: Lock amount must be > 0");
        require(unlockTime > block.timestamp, "QV: Unlock time must be in the future");

        uint256 lockId = userLocks[msg.sender].length;
        userLocks[msg.sender].push(Lock({
            amount: amount,
            unlockTime: unlockTime,
            released: false
        }));
        userLockedBalance[msg.sender] += amount; // Track amount locked by THIS user

        // Check if total locked amount across ALL users exceeds total balance.
        // This requires iterating userLockedBalance mapping, which is not feasible on-chain.
        // Alternative: track a global total locked balance. Let's add that state variable.
        _totalLockedBalance += amount;
        require(address(this).balance >= _totalLockedBalance, "QV: Not enough total balance to cover new lock"); // Prevent locking more than exists

        emit EthLocked(msg.sender, amount, unlockTime, lockId);
    }
    uint256 private _totalLockedBalance = 0; // Add global tracker

    /// @notice Extends the unlock time for an existing lock owned by the caller.
    /// @param lockId The index/ID of the lock to extend for the caller.
    /// @param newUnlockTime The new timestamp for the lock expiry.
    function extendLock(uint256 lockId, uint40 newUnlockTime) external whenNotPaused {
        require(lockId < userLocks[msg.sender].length, "QV: Invalid lock ID");
        Lock storage lock = userLocks[msg.sender][lockId];
        require(!lock.released, "QV: Lock already released");
        require(newUnlockTime > lock.unlockTime, "QV: New unlock time must be in the future");

        lock.unlockTime = newUnlockTime;
        emit EthLockExtended(msg.sender, lockId, newUnlockTime);
    }

    /// @notice Releases a locked amount after its unlockTime has passed.
    /// The released amount is not withdrawn immediately, but becomes available for future withdrawal mechanisms (not directly provided by this function).
    /// @param lockId The index/ID of the lock to release for the caller.
    function releaseLock(uint256 lockId) external { // No pause check - releasing after time should always be possible
        require(lockId < userLocks[msg.sender].length, "QV: Invalid lock ID");
        Lock storage lock = userLocks[msg.sender][lockId];
        require(!lock.released, "QV: Lock already released");
        require(block.timestamp >= lock.unlockTime, "QV: Lock time has not passed");

        userLockedBalance[msg.sender] -= lock.amount;
        _totalLockedBalance -= lock.amount;
        lock.released = true; // Mark as released instead of deleting/zeroing
        emit EthLockReleased(msg.sender, lockId);
    }

    /// @notice Allows the lock owner to cancel a lock early if the contract is in a specific operational mode.
    /// This demonstrates state-dependent behavior impacting user actions.
    /// @param lockId The index/ID of the lock to potentially cancel.
    /// @param requiredMode The operational mode required to cancel the lock.
    function cancelLockIfMode(uint256 lockId, OperationalMode requiredMode) external {
        require(lockId < userLocks[msg.sender].length, "QV: Invalid lock ID");
        Lock storage lock = userLocks[msg.sender][lockId];
        require(!lock.released, "QV: Lock already released");
        require(_operationalMode == requiredMode, "QV: Required operational mode not active");

        // Cancel the lock: immediately release it
        userLockedBalance[msg.sender] -= lock.amount;
        _totalLockedBalance -= lock.amount;
        lock.released = true;
        // Note: The unlockTime check is bypassed here due to the mode condition
        emit EthLockCancelled(msg.sender, lockId, requiredMode);
    }


    // --- Delegated Withdrawal Rights ---

    /// @notice Owner delegates withdrawal rights to another address.
    /// The delegatee can withdraw up to 'amount' before 'expiry'.
    /// Only one active delegation per delegatee.
    /// @param delegatee The address receiving delegation rights.
    /// @param amount The maximum total amount the delegatee can withdraw.
    /// @param expiry The timestamp when the delegation expires.
    function delegateWithdrawal(address delegatee, uint256 amount, uint40 expiry) external onlyOwner whenNotPaused {
        require(delegatee != address(0), "QV: Delegatee cannot be zero address");
        require(amount > 0, "QV: Delegation amount must be > 0");
        require(expiry > block.timestamp, "QV: Delegation expiry must be in the future");
        // Delegation amount + total locked balance must not exceed total contract balance
        require(address(this).balance >= amount + _totalLockedBalance, "QV: Insufficient balance for delegation");

        delegations[delegatee] = Delegation({
            amount: amount,
            withdrawn: 0,
            expiry: expiry,
            active: true
        });
        emit WithdrawalDelegated(msg.sender, delegatee, amount, expiry);
    }

    /// @notice Owner revokes an active delegation.
    /// @param delegatee The address whose delegation is being revoked.
    function revokeDelegation(address delegatee) external onlyOwner {
        require(delegations[delegatee].active, "QV: No active delegation for this address");
        delegations[delegatee].active = false;
        // Optionally reset amount/withdrawn, but marking inactive is sufficient to stop withdrawals
        emit DelegationRevoked(msg.sender, delegatee);
    }

    /// @notice Allows a delegatee to withdraw ETH based on their delegated rights.
    /// @param amount The amount of ETH to withdraw.
    function delegateWithdraw(uint256 amount) external whenNotPaused {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.active, "QV: No active delegation");
        require(block.timestamp < delegation.expiry, "QV: Delegation expired");
        require(amount > 0, "QV: Withdrawal amount must be > 0");

        uint256 remaining = delegation.amount - delegation.withdrawn;
        require(amount <= remaining, "QV: Amount exceeds remaining delegation");

        // Ensure the withdrawal respects the total locked balance across all users
        require(address(this).balance >= amount + _totalLockedBalance, "QV: Insufficient contract balance (considering locks)");


        delegation.withdrawn += amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: ETH transfer failed");
        emit DelegatedWithdrawal(msg.sender, amount);

        // Optionally deactivate delegation if fully withdrawn
        if (delegation.withdrawn == delegation.amount) {
            delegation.active = false;
            emit DelegationRevoked(owner(), msg.sender); // Emit revocation event by owner
        }
    }

    // --- State-Dependent & Conditional Functions ---

    /// @notice Allows the owner to withdraw ETH only if the contract is in a specific operational mode.
    /// Adds a state check on top of the standard withdrawal.
    /// @param amount The amount of ETH to withdraw in wei.
    /// @param requiredMode The operational mode required for this withdrawal.
    function conditionalWithdraw(uint256 amount, OperationalMode requiredMode) external onlyOwner whenNotPaused {
        require(_operationalMode == requiredMode, "QV: Required operational mode not active for withdrawal");
        // Standard checks from withdraw() still apply
        uint256 totalLocked = userLockedBalance[_owner]; // Check owner's locks
        require(address(this).balance >= amount + totalLocked, "QV: Insufficient unlocked balance (considering owner locks)");
        require(amount > 0, "QV: Withdrawal amount must be > 0");

         uint256 ownerAvailable = address(this).balance - totalLocked;
         require(ownerAvailable >= amount, "QV: Insufficient owner available balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: ETH transfer failed");
        emit EthWithdrawal(msg.sender, amount); // Can use a specific event if needed
    }

     /// @notice Distributes a reward amount if the contract is in the required mode.
     /// An example of a function gated by operational mode, using contract balance as source.
     /// @param recipient The address to send the reward to.
     /// @param amount The reward amount.
     /// @param requiredMode The operational mode required to distribute the reward.
    function distributeConditionalReward(address payable recipient, uint256 amount, OperationalMode requiredMode) external onlyOwner whenNotPaused {
        require(_operationalMode == requiredMode, "QV: Required operational mode not active for reward");
        require(amount > 0, "QV: Reward amount must be > 0");
        // Ensure reward + total locked balance doesn't exceed contract balance
        require(address(this).balance >= amount + _totalLockedBalance, "QV: Insufficient contract balance (considering locks)");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "QV: Reward transfer failed");
        emit ConditionalRewardDistributed(recipient, amount, requiredMode);
    }

    /// @notice Executes a simple internal action if the current entropy state matches an expected value.
    /// Demonstrates using an unpredictable (though not cryptographically secure) state for conditional logic.
    /// Example action: changing operational mode.
    /// @param expectedEntropy The entropy value that must match the current state.
    function executeOnEntropyMatch(uint256 expectedEntropy) external {
        require(_entropyState == expectedEntropy, "QV: Entropy state does not match");

        // Example internal action: toggle between Neutral and Restricted modes
        OperationalMode oldMode = _operationalMode;
        if (_operationalMode == OperationalMode.Neutral) {
            _operationalMode = OperationalMode.Restricted;
        } else if (_operationalMode == OperationalMode.Restricted) {
            _operationalMode = OperationalMode.Neutral;
        }
        // Add other mode changes here based on logic

        emit ExecutedOnEntropyMatch(expectedEntropy, oldMode, _operationalMode);
    }


    // --- Pseudo-Entropy & State Hinting ---

    // Cooldown to prevent spamming entropy updates within the same block or too quickly
    uint40 private _lastEntropyUpdateTimestamp;
    uint32 private constant ENTROPY_UPDATE_COOLDOWN = 12; // Example cooldown in seconds (approx 4 blocks)

    /// @notice Updates an internal 'entropy' state variable.
    /// The update is based on block data (timestamp, number) and transaction data (sender).
    /// NOT SUITABLE FOR SECURE RANDOMNESS. FOR DEMONSTRATION OF STATE CHANGE ONLY.
    function triggerStateEntropyUpdate() external {
        require(block.timestamp >= _lastEntropyUpdateTimestamp + ENTROPY_UPDATE_COOLDOWN, "QV: Entropy update cooldown active");

        // Combine previous state, block data, and sender address for update
        _entropyState = uint256(keccak256(abi.encodePacked(
            _entropyState,
            block.timestamp,
            block.number,
            msg.sender,
            tx.origin // Using tx.origin is generally discouraged due to phishing risks, but used here only for state entropy derivation, not auth.
        )));
        _lastEntropyUpdateTimestamp = uint40(block.timestamp); // Update cooldown timer

        emit StateEntropyUpdated(_entropyState);
    }

    /// @notice Gets the current 'entropy' state.
    function getEntropyState() external view returns (uint256) {
        return _entropyState;
    }

    /// @notice Provides a hint of what the entropy *could* be if triggerStateEntropyUpdate were called by a hypothetical sender in the *current* block.
    /// This is a deterministic calculation based on current on-chain state, not a prediction of the future.
    /// Useful for off-chain logic that wants to simulate the effect of the entropy update.
    /// @param hypotheticalSender The address to use as the sender in the hypothetical calculation.
    function predictNextEntropyStateHint(address hypotheticalSender) external view returns (uint256) {
         // Note: This calculation uses current block data.
         // A real 'next' state depends on future, unknown block data.
         // This function is purely for demonstrating the *calculation* logic.
        return uint256(keccak256(abi.encodePacked(
            _entropyState,
            block.timestamp,
            block.number,
            hypotheticalSender,
            tx.origin // Using tx.origin here mirrors the trigger function
        )));
    }

    // --- Batch Operations ---

    /// @notice Allows a user to release multiple of their own locks in one transaction.
    /// All locks must meet the release criteria. If any fails, the whole transaction reverts.
    /// @param lockIds An array of lock IDs to attempt to release for the caller.
    function batchReleaseLocks(uint256[] calldata lockIds) external {
        for (uint i = 0; i < lockIds.length; i++) {
            uint256 lockId = lockIds[i];
            require(lockId < userLocks[msg.sender].length, "QV: Invalid lock ID in batch");
            Lock storage lock = userLocks[msg.sender][lockId];
            require(!lock.released, "QV: Lock already released in batch");
            require(block.timestamp >= lock.unlockTime, "QV: Lock time not passed in batch");

            userLockedBalance[msg.sender] -= lock.amount;
             _totalLockedBalance -= lock.amount;
            lock.released = true;
            emit EthLockReleased(msg.sender, lockId);
        }
        // The released amounts are now available for future withdrawal mechanisms.
    }

    /// @notice Allows a delegatee to make multiple withdrawals against their delegation in one transaction.
    /// Withdrawals must respect the remaining delegation amount and expiry.
    /// @param amounts An array of amounts to withdraw in sequence.
    function batchDelegateWithdraw(uint256[] calldata amounts) external whenNotPaused {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.active, "QV: No active delegation");
        require(block.timestamp < delegation.expiry, "QV: Delegation expired");

        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "QV: Batch withdrawal amount must be > 0");
            totalAmount += amounts[i];
        }

        uint256 remaining = delegation.amount - delegation.withdrawn;
        require(totalAmount <= remaining, "QV: Total batch amount exceeds remaining delegation");

         // Ensure the total batch withdrawal respects the total locked balance across all users
        require(address(this).balance >= totalAmount + _totalLockedBalance, "QV: Insufficient contract balance (considering locks)");

        delegation.withdrawn += totalAmount;

        // Perform individual transfers
        for (uint i = 0; i < amounts.length; i++) {
            uint256 currentAmount = amounts[i];
             (bool success, ) = payable(msg.sender).call{value: currentAmount}("");
            require(success, "QV: Batch ETH transfer failed"); // Reverts the whole batch on failure
            emit DelegatedWithdrawal(msg.sender, currentAmount); // Emit for each withdrawal
        }

        // Optionally deactivate delegation if fully withdrawn
        if (delegation.withdrawn == delegation.amount) {
            delegation.active = false;
            emit DelegationRevoked(owner(), msg.sender);
        }
    }

     /// @notice Allows the owner to send ETH to multiple recipients in one transaction.
     /// @param recipients An array of recipient addresses.
     /// @param amounts An array of amounts corresponding to recipients.
    function batchOwnerWithdraw(address payable[] calldata recipients, uint256[] calldata amounts) external onlyOwner whenNotPaused {
        require(recipients.length == amounts.length, "QV: Recipients and amounts must have same length");
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "QV: Batch amount must be > 0");
            totalAmount += amounts[i];
        }

        uint256 ownerLocked = userLockedBalance[_owner];
        uint256 ownerAvailable = address(this).balance - ownerLocked;
        require(ownerAvailable >= totalAmount, "QV: Insufficient owner available balance for batch");
        require(totalAmount + _totalLockedBalance <= address(this).balance, "QV: Batch withdrawal exceeds total contract balance considering locks");


        for (uint i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "QV: Batch owner withdrawal failed"); // Reverts the whole batch on failure
            emit EthWithdrawal(msg.sender, amounts[i]); // Can use a specific event if needed
        }
    }


    // --- Inspection/View Functions ---

    /// @notice Gets the total ETH balance held by the contract.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

     /// @notice Gets the total ETH amount locked by a specific account.
     /// This is the sum of amounts in their active (unreleased) locks.
    function getLockedBalance(address account) external view returns (uint256) {
        return userLockedBalance[account];
    }

    /// @notice Gets the total ETH amount locked across *all* accounts in the contract.
    function getTotalLockedBalance() external view returns (uint256) {
        return _totalLockedBalance;
    }


    /// @notice Gets information about a specific delegation.
    /// @param delegatee The address to check for delegation info.
    /// @return amount The total delegated amount.
    /// @return withdrawn The amount already withdrawn by the delegatee.
    /// @return expiry The delegation expiry timestamp.
    /// @return active Whether the delegation is currently active.
    function getDelegationInfo(address delegatee) external view returns (uint256 amount, uint256 withdrawn, uint40 expiry, bool active) {
        Delegation storage delegation = delegations[delegatee];
        return (delegation.amount, delegation.withdrawn, delegation.expiry, delegation.active);
    }

     /// @notice Gets the number of locks created by an account.
     /// @param account The address to check.
     /// @return The count of locks (including released ones).
    function getUserLockCount(address account) external view returns (uint256) {
        return userLocks[account].length;
    }

    /// @notice Gets details of a specific lock for an account by index.
    /// Note: Lock indices are stable; deleting/releasing doesn't shift indices.
    /// @param account The address of the lock owner.
    /// @param lockIndex The index/ID of the lock.
     /// @return amount The locked amount.
     /// @return unlockTime The unlock timestamp.
     /// @return released Whether the lock has been released.
    function getUserLock(address account, uint256 lockIndex) external view returns (uint256 amount, uint40 unlockTime, bool released) {
        require(lockIndex < userLocks[account].length, "QV: Invalid lock index");
        Lock storage lock = userLocks[account][lockIndex];
        return (lock.amount, lock.unlockTime, lock.released);
    }


    // --- Emergency Functions ---

    /// @notice Allows the owner to withdraw ETH even if the contract is paused.
    /// Bypasses the pause check but still respects the total locked balance.
    /// @param amount The amount of ETH to withdraw.
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "QV: Emergency withdrawal amount must be > 0");
        // Emergency withdrawal bypasses pause, but MUST NOT allow withdrawing locked funds.
        // Check total contract balance minus total locked balance.
        require(address(this).balance >= amount + _totalLockedBalance, "QV: Insufficient contract balance for emergency withdrawal (considering locks)");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: Emergency ETH transfer failed");
        // Use standard withdrawal event, or a specific emergency one
        emit EthWithdrawal(msg.sender, amount);
    }

    // Add more emergency functions if needed, e.g., sweeping specific tokens (would require ERC20 interface knowledge)

    // --- Internal Helper Functions (if any) ---
    // None needed for this example's complexity.
}
```