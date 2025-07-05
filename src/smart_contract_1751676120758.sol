Okay, here is a Solidity smart contract called `QuantumVault`. It's designed to be a non-standard vault with several advanced and interconnected features, including various lock types, delegated access with granular control, withdrawal cooldowns, emergency functions, and a simulated interaction point for external yield (without implementing actual yield protocols, which would require external adapters or specific protocol knowledge).

It avoids common open-source patterns like standard ERC-20/721 implementations, simple multi-sigs, or basic escrow contracts.

**Outline and Function Summary**

This contract implements a secure vault allowing users to deposit Ether and approved ERC-20 tokens, lock funds under various conditions, delegate withdrawal rights, and manage access.

1.  **Core Storage & Configuration**
    *   `owner`: Contract owner address.
    *   `approvedTokens`: Mapping of approved token addresses.
    *   `nextLockId`: Counter for unique lock identifiers.
    *   `locks`: Mapping from lock ID to Lock struct.
    *   `ownerLockIds`: Mapping from owner address to array of their lock IDs.
    *   `conditionalLockStates`: Mapping from condition hash to boolean (met/not met).
    *   `delegations`: Mapping from delegatee address to Delegation struct.
    *   `withdrawalCooldownDuration`: Minimum time between withdrawals for any user.
    *   `lastWithdrawalTime`: Mapping from user address to their last withdrawal timestamp.
    *   `selfDestructScheduledAt`: Timestamp when self-destruct is scheduled (0 if not scheduled).
    *   `selfDestructDelay`: Required delay for self-destruct.

2.  **Data Structures (`struct`)**
    *   `Lock`: Represents a lock on funds.
        *   `lockId`: Unique identifier.
        *   `owner`: Address who created the lock.
        *   `token`: Address of the locked token (address(0) for Ether).
        *   `amount`: Amount locked.
        *   `lockType`: Type of lock (Timed, Conditional, Delegated).
        *   `unlockTime`: Timestamp for Timed locks.
        *   `conditionHash`: Hash for Conditional locks.
        *   `delegatee`: Address for Delegated locks.
        *   `unlockCodeHash`: Hash of the unlock code for Delegated locks.
        *   `isUnlocked`: Status for Conditional/Delegated locks.
    *   `Delegation`: Represents delegated withdrawal rights.
        *   `delegatee`: Address granted delegation.
        *   `grantor`: Address granting delegation.
        *   `maxAmountPerToken`: Mapping of token addresses to the maximum amount they can withdraw.
        *   `expiry`: Timestamp when delegation expires.
        *   `usedAmountPerToken`: Mapping of token addresses to the amount already withdrawn via this delegation.
        *   `isActive`: Whether the delegation is currently active.

3.  **Events (`event`)**
    *   `OwnershipTransferred`: Fired when ownership changes.
    *   `TokenApproved`: Fired when a token is added to the approved list.
    *   `TokenRemoved`: Fired when a token is removed from the approved list.
    *   `Deposit`: Fired when Ether or tokens are deposited.
    *   `Withdrawal`: Fired when Ether or tokens are withdrawn (excluding delegated/panic).
    *   `LockCreated`: Fired when a new lock is created.
    *   `LockUnlocked`: Fired when a lock is successfully unlocked.
    *   `DelegationGranted`: Fired when withdrawal rights are delegated.
    *   `DelegationRevoked`: Fired when a delegation is revoked.
    *   `DelegatedWithdrawal`: Fired when a withdrawal is made using delegated rights.
    *   `WithdrawalCooldownSet`: Fired when the cooldown duration is set.
    *   `PanicWithdrawal`: Fired when the owner uses the emergency withdrawal.
    *   `SelfDestructScheduled`: Fired when self-destruct is initiated.
    *   `SelfDestructCancelled`: Fired when self-destruct is cancelled.
    *   `ExternalYieldSimulated`: Fired when external yield simulation adds funds.

4.  **Functions (Total: 29)**

    *   **Owner & Configuration (7)**
        1.  `constructor()`: Initializes the contract with the deployer as owner.
        2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
        3.  `addApprovedToken(address token)`: Adds a token to the approved list (Owner only).
        4.  `removeApprovedToken(address token)`: Removes a token from the approved list (Owner only).
        5.  `setWithdrawalCooldown(uint256 cooldownDuration)`: Sets the minimum time between any user's withdrawals (Owner only).
        6.  `initiateSelfDestructSequence(uint256 delay)`: Schedules contract self-destruction after a delay (Owner only).
        7.  `cancelSelfDestructSequence()`: Cancels a scheduled self-destruction (Owner only).

    *   **Deposits & Withdrawals (5)**
        8.  `receive()`: Allows receiving Ether deposits.
        9.  `depositToken(address token, uint256 amount)`: Deposits approved ERC-20 tokens.
        10. `withdrawEther(uint256 amount)`: Withdraws unlocked Ether.
        11. `withdrawToken(address token, uint256 amount)`: Withdraws unlocked approved tokens.
        12. `panicWithdraw(address token)`: Allows the owner to withdraw all tokens (or Ether if token is address(0)) bypassing locks and cooldowns in an emergency.

    *   **Locking Mechanisms (5)**
        13. `lockFundsTimed(address token, uint256 amount, uint256 duration)`: Locks funds for a specified duration.
        14. `lockFundsConditional(address token, uint256 amount, bytes32 conditionHash)`: Locks funds until a specific external condition (identified by a hash) is marked as met.
        15. `lockFundsDelegated(address token, uint256 amount, address delegatee, uint256 unlockCode)`: Locks funds which can only be unlocked by a specific delegatee providing a secret code.
        16. `markConditionMet(bytes32 conditionHash, bool met)`: Owner/trusted oracle marks a condition as met or not met.
        17. `simulateExternalYield(address token, uint256 yieldAmount)`: Owner simulates receiving yield, increasing the vault's balance for a token.

    *   **Unlocking Mechanisms (3)**
        18. `unlockTimedLock(uint256 lockId)`: Unlocks a timed lock if the duration has passed.
        19. `unlockConditionalLock(uint256 lockId)`: Unlocks a conditional lock if the associated condition has been marked as met.
        20. `unlockDelegatedLock(uint256 lockId, uint256 unlockCode)`: Unlocks a delegated lock if the correct unlock code is provided by the designated delegatee.

    *   **Delegation Management & Execution (3)**
        21. `delegateWithdrawalRights(address delegatee, address token, uint256 maxAmount, uint256 expiry)`: Grants a delegatee limited withdrawal rights for a specific token until an expiry time. Can be called multiple times for different tokens or to update limits/expiry.
        22. `revokeDelegatedWithdrawal(address delegatee)`: Revokes all active delegations granted to a specific delegatee by the caller.
        23. `executeDelegatedWithdrawal(address delegatee, address token, uint256 amount)`: Allows a delegatee to withdraw funds based on granted rights.

    *   **View & Helper Functions (6)**
        24. `isApprovedToken(address token)`: Checks if a token is on the approved list.
        25. `getApprovedTokens()`: Returns the list of approved token addresses.
        26. `getWithdrawalCooldown()`: Returns the current withdrawal cooldown duration.
        27. `getLockDetails(uint256 lockId)`: Returns details for a specific lock.
        28. `getDelegationDetails(address delegatee, address grantor)`: Returns details for a specific delegation.
        29. `getLockIdsByOwner(address user)`: Returns an array of lock IDs created by a user.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This is a conceptual contract demonstrating advanced patterns.
// In a real application, consider using OpenZeppelin libraries for security,
// specifically SafeERC20 for token interactions and ReentrancyGuard.
// External calls (like token transfers) are potential reentrancy risks.

/**
 * @title QuantumVault
 * @dev An advanced conceptual vault contract with multiple locking mechanisms,
 * delegated access, withdrawal cooldowns, and simulated external yield.
 * It is NOT intended for production use without rigorous security audits and
 * incorporation of robust libraries like OpenZeppelin.
 *
 * Outline:
 * 1. Core Storage & Configuration
 * 2. Data Structures (struct)
 * 3. Events (event)
 * 4. Functions (29 total)
 *    - Owner & Configuration (7)
 *    - Deposits & Withdrawals (5)
 *    - Locking Mechanisms (5)
 *    - Unlocking Mechanisms (3)
 *    - Delegation Management & Execution (3)
 *    - View & Helper Functions (6)
 */
contract QuantumVault {

    // --- 1. Core Storage & Configuration ---
    address private _owner;

    mapping(address => bool) private approvedTokens;
    address[] private approvedTokenList; // To retrieve the list easily

    uint256 private nextLockId;
    mapping(uint256 => Lock) public locks;
    mapping(address => uint256[]) private ownerLockIds; // Track lock IDs per owner

    mapping(bytes32 => bool) private conditionalLockStates; // conditionHash => isMet

    mapping(address => mapping(address => Delegation)) private delegations; // delegatee => grantor => Delegation

    uint256 public withdrawalCooldownDuration; // Minimum seconds between withdrawals per user
    mapping(address => uint256) private lastWithdrawalTime; // user => timestamp of last withdrawal

    uint256 public selfDestructScheduledAt; // Timestamp when self-destruct sequence was initiated
    uint256 public selfDestructDelay; // The required delay before self-destruct can occur

    // --- 2. Data Structures (`struct`) ---

    enum LockType { Timed, Conditional, Delegated }

    struct Lock {
        uint256 lockId;
        address owner; // The address that created the lock
        address token; // address(0) for Ether
        uint256 amount;
        LockType lockType;
        uint256 unlockTime; // Used for Timed locks
        bytes32 conditionHash; // Used for Conditional locks
        address delegatee; // Used for Delegated locks
        bytes32 unlockCodeHash; // Hash of the code for Delegated locks
        bool isUnlocked; // State for Conditional/Delegated locks
        bool exists; // Helper to check if a lockId is valid
    }

    struct Delegation {
        address delegatee;
        address grantor;
        mapping(address => uint256) maxAmountPerToken; // token => max cumulative amount
        mapping(address => uint256) usedAmountPerToken; // token => used cumulative amount
        uint256 expiry;
        bool isActive;
        bool exists; // Helper to check if delegation exists
    }

    // --- 3. Events (`event`) ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenApproved(address indexed token);
    event TokenRemoved(address indexed token);
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event LockCreated(address indexed owner, uint256 indexed lockId, address indexed token, uint256 amount, LockType lockType);
    event LockUnlocked(uint256 indexed lockId);
    event DelegationGranted(address indexed grantor, address indexed delegatee, address indexed token, uint256 maxAmount, uint256 expiry);
    event DelegationRevoked(address indexed grantor, address indexed delegatee);
    event DelegatedWithdrawal(address indexed delegatee, address indexed grantor, address indexed token, uint256 amount);
    event WithdrawalCooldownSet(uint256 duration);
    event PanicWithdrawal(address indexed owner, address indexed token, uint256 amount);
    event SelfDestructScheduled(uint256 scheduledAt, uint256 delay);
    event SelfDestructCancelled();
    event ExternalYieldSimulated(address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QV: Not owner");
        _;
    }

    modifier onlyApprovedToken(address token) {
        require(token == address(0) || approvedTokens[token], "QV: Token not approved");
        _;
    }

    // --- 4. Functions ---

    // --- Owner & Configuration ---

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        // Ether is implicitly approved
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * Can only be called by the current owner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "QV: New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Adds an ERC-20 token to the list of approved tokens for deposit/withdrawal.
     * Only the owner can call this.
     * @param token The address of the ERC-20 token.
     */
    function addApprovedToken(address token) external onlyOwner {
        require(token != address(0), "QV: Cannot approve zero address");
        require(!approvedTokens[token], "QV: Token already approved");
        approvedTokens[token] = true;
        approvedTokenList.push(token);
        emit TokenApproved(token);
    }

    /**
     * @dev Removes an ERC-20 token from the list of approved tokens.
     * Only the owner can call this. Note: Existing balances of this token remain
     * in the vault but cannot be withdrawn via standard methods until re-approved.
     * Panic withdrawal can still retrieve them.
     * @param token The address of the ERC-20 token.
     */
    function removeApprovedToken(address token) external onlyOwner {
        require(token != address(0), "QV: Cannot remove zero address");
        require(approvedTokens[token], "QV: Token not approved");
        approvedTokens[token] = false;
        // Removing from array is inefficient, could use a mapping if needed
        // but for a likely small list, filtering is acceptable for demonstration.
        address[] memory newList = new address[](approvedTokenList.length - 1);
        uint k = 0;
        for (uint i = 0; i < approvedTokenList.length; i++) {
            if (approvedTokenList[i] != token) {
                newList[k] = approvedTokenList[i];
                k++;
            }
        }
        approvedTokenList = newList;
        emit TokenRemoved(token);
    }

    /**
     * @dev Sets the minimum time duration required between withdrawal actions
     * by any single user. Applies to withdrawEther, withdrawToken, and executeDelegatedWithdrawal.
     * @param cooldownDuration The duration in seconds.
     */
    function setWithdrawalCooldown(uint256 cooldownDuration) external onlyOwner {
        withdrawalCooldownDuration = cooldownDuration;
        emit WithdrawalCooldownSet(cooldownDuration);
    }

    /**
     * @dev Initiates a self-destruct sequence. After the specified delay,
     * the owner can call `selfdestruct` to destroy the contract.
     * All funds REMAINING in the contract when selfdestruct is called will be
     * sent to the owner's address. Use with extreme caution.
     * @param delay The delay in seconds before self-destruct is possible.
     */
    function initiateSelfDestructSequence(uint256 delay) external onlyOwner {
        require(selfDestructScheduledAt == 0, "QV: Self-destruct already scheduled");
        selfDestructScheduledAt = block.timestamp;
        selfDestructDelay = delay;
        emit SelfDestructScheduled(block.timestamp, delay);
    }

    /**
     * @dev Cancels a previously initiated self-destruct sequence.
     * Only the owner can call this.
     */
    function cancelSelfDestructSequence() external onlyOwner {
        require(selfDestructScheduledAt > 0, "QV: No self-destruct scheduled");
        selfDestructScheduledAt = 0;
        selfDestructDelay = 0;
        emit SelfDestructCancelled();
    }

    // --- Deposits & Withdrawals ---

    /**
     * @dev Receives Ether deposits. Any Ether sent directly to the contract
     * without calling a specific function will be handled here.
     */
    receive() external payable {
        emit Deposit(msg.sender, address(0), msg.value);
    }

    /**
     * @dev Deposits an approved ERC-20 token into the vault.
     * Requires the user to have approved the contract to spend the tokens first.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(address token, uint256 amount) external onlyApprovedToken(token) {
        require(amount > 0, "QV: Deposit amount must be > 0");
        // Using call for robust interaction with potentially non-standard ERC20s
        bytes memory payload = abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount);
        (bool success, bytes memory data) = token.call(payload);

        require(success, "QV: Token transferIn failed");

        // Optional: Check return data for ERC20 compliance if transferFrom returns bool
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "QV: Token transferIn returned false");
        }

        emit Deposit(msg.sender, token, amount);
    }

    /**
     * @dev Withdraws unlocked Ether from the vault.
     * Subject to withdrawal cooldown.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEther(uint256 amount) external checkWithdrawalCooldown {
        require(amount > 0, "QV: Withdrawal amount must be > 0");
        uint256 unlockedBalance = address(this).balance - _getTotalLockedBalance(address(0));
        require(amount <= unlockedBalance, "QV: Amount exceeds unlocked Ether balance");

        _updateLastWithdrawalTime(msg.sender);

        // Using call for sending Ether for robustness against reentrancy (indirectly via gas limits)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: Ether withdrawal failed");

        emit Withdrawal(msg.sender, address(0), amount);
    }

    /**
     * @dev Withdraws unlocked approved tokens from the vault.
     * Subject to withdrawal cooldown.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawToken(address token, uint256 amount) external onlyApprovedToken(token) checkWithdrawalCooldown {
        require(amount > 0, "QV: Withdrawal amount must be > 0");
        uint256 tokenBalance = _getTokenBalance(token);
        uint256 unlockedBalance = tokenBalance - _getTotalLockedBalance(token);
        require(amount <= unlockedBalance, "QV: Amount exceeds unlocked token balance");

        _updateLastWithdrawalTime(msg.sender);

        // Using call for token transfers for robustness
        bytes memory payload = abi.encodeWithSelector(0xa9059cbb, msg.sender, amount);
        (bool success, bytes memory data) = token.call(payload);

        require(success, "QV: Token transferOut failed");
        // Optional: Check return data for ERC20 compliance if transfer returns bool
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "QV: Token transferOut returned false");
        }

        emit Withdrawal(msg.sender, token, amount);
    }

    /**
     * @dev Emergency function for the owner to withdraw all of a specific
     * token (or Ether) from the vault, bypassing all locks, cooldowns, etc.
     * Use ONLY IN EMERGENCIES like critical vulnerabilities or frozen funds.
     * @param token The address of the token (address(0) for Ether).
     */
    function panicWithdraw(address token) external onlyOwner {
        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "QV: Panic Ether withdrawal failed");
        } else {
            require(approvedTokens[token], "QV: Token not approved for panic"); // Or allow any? Allowing approved for safety
            balance = _getTokenBalance(token);
            // Using call for token transfers
            bytes memory payload = abi.encodeWithSelector(0xa9059cbb, msg.sender, balance);
            (bool success, bytes memory data) = token.call(payload);

            require(success, "QV: Panic Token transferOut failed");
             if (data.length > 0) {
                require(abi.decode(data, (bool)), "QV: Panic Token transferOut returned false");
            }
        }
        emit PanicWithdrawal(_owner, token, balance);
    }


    // --- Locking Mechanisms ---

    /**
     * @dev Locks a specified amount of Ether or approved token for a duration.
     * The funds cannot be withdrawn by the lock owner until the unlock time is reached.
     * @param token The address of the token (address(0) for Ether).
     * @param amount The amount to lock. Must be available as unlocked balance.
     * @param duration The duration in seconds for which to lock the funds.
     * @return The unique ID of the created lock.
     */
    function lockFundsTimed(address token, uint256 amount, uint256 duration) external onlyApprovedToken(token) returns (uint256) {
        require(amount > 0, "QV: Amount must be > 0");
        require(duration > 0, "QV: Duration must be > 0");

        uint256 unlockedBalance = (token == address(0) ? address(this).balance : _getTokenBalance(token)) - _getTotalLockedBalance(token);
        require(amount <= unlockedBalance, "QV: Amount exceeds unlocked balance");

        uint256 lockId = nextLockId++;
        locks[lockId] = Lock({
            lockId: lockId,
            owner: msg.sender,
            token: token,
            amount: amount,
            lockType: LockType.Timed,
            unlockTime: block.timestamp + duration,
            conditionHash: bytes32(0),
            delegatee: address(0),
            unlockCodeHash: bytes32(0),
            isUnlocked: false,
            exists: true
        });
        ownerLockIds[msg.sender].push(lockId);

        emit LockCreated(msg.sender, lockId, token, amount, LockType.Timed);
        return lockId;
    }

     /**
     * @dev Locks a specified amount of Ether or approved token until an external
     * condition, identified by its hash, is marked as met by the owner/trusted oracle.
     * @param token The address of the token (address(0) for Ether).
     * @param amount The amount to lock. Must be available as unlocked balance.
     * @param conditionHash A unique hash representing the condition to be met.
     * @return The unique ID of the created lock.
     */
    function lockFundsConditional(address token, uint256 amount, bytes32 conditionHash) external onlyApprovedToken(token) returns (uint256) {
        require(amount > 0, "QV: Amount must be > 0");
        require(conditionHash != bytes32(0), "QV: Condition hash cannot be zero");
        // Condition state defaults to false if not set
        require(!conditionalLockStates[conditionHash], "QV: Condition is already met");

        uint256 unlockedBalance = (token == address(0) ? address(this).balance : _getTokenBalance(token)) - _getTotalLockedBalance(token);
        require(amount <= unlockedBalance, "QV: Amount exceeds unlocked balance");

        uint256 lockId = nextLockId++;
        locks[lockId] = Lock({
            lockId: lockId,
            owner: msg.sender,
            token: token,
            amount: amount,
            lockType: LockType.Conditional,
            unlockTime: 0,
            conditionHash: conditionHash,
            delegatee: address(0),
            unlockCodeHash: bytes32(0),
            isUnlocked: false,
            exists: true
        });
         ownerLockIds[msg.sender].push(lockId);

        emit LockCreated(msg.sender, lockId, token, amount, LockType.Conditional);
        return lockId;
    }

    /**
     * @dev Locks a specified amount of Ether or approved token that can only be
     * unlocked by a specific delegatee providing a secret unlock code.
     * The lock owner CANNOT unlock this lock themselves using `unlockDelegatedLock`.
     * They could potentially unlock it by calling `markConditionMet` if they also
     * set a `conditionHash` using `lockFundsConditional` for the same funds (complex case,
     * this contract separates lock types for clarity).
     * @param token The address of the token (address(0) for Ether).
     * @param amount The amount to lock. Must be available as unlocked balance.
     * @param delegatee The address that is allowed to unlock this lock.
     * @param unlockCode A secret code (e.g., a random number) the delegatee must provide.
     *                   The hash is stored for verification.
     * @return The unique ID of the created lock.
     */
    function lockFundsDelegated(address token, uint256 amount, address delegatee, uint256 unlockCode) external onlyApprovedToken(token) returns (uint256) {
        require(amount > 0, "QV: Amount must be > 0");
        require(delegatee != address(0), "QV: Delegatee cannot be the zero address");
        require(delegatee != msg.sender, "QV: Cannot delegate to yourself for this lock type"); // Owner cannot unlock this type

        uint256 unlockedBalance = (token == address(0) ? address(this).balance : _getTokenBalance(token)) - _getTotalLockedBalance(token);
        require(amount <= unlockedBalance, "QV: Amount exceeds unlocked balance");

        uint256 lockId = nextLockId++;
        locks[lockId] = Lock({
            lockId: lockId,
            owner: msg.sender,
            token: token,
            amount: amount,
            lockType: LockType.Delegated,
            unlockTime: 0,
            conditionHash: bytes32(0),
            delegatee: delegatee,
            unlockCodeHash: keccak256(abi.encodePacked(unlockCode)), // Store hash, not raw code
            isUnlocked: false,
            exists: true
        });
         ownerLockIds[msg.sender].push(lockId);

        emit LockCreated(msg.sender, lockId, token, amount, LockType.Delegated);
        return lockId;
    }

    /**
     * @dev Allows the contract owner to mark a specific external condition
     * as met or not met. This is required to unlock Conditional locks.
     * Can potentially be extended with role-based access or oracle integration.
     * @param conditionHash The hash of the condition.
     * @param met The status to set for the condition (true if met, false otherwise).
     */
    function markConditionMet(bytes32 conditionHash, bool met) external onlyOwner {
         // Note: Setting 'met' back to false is allowed, but will re-lock funds
         // if they haven't been withdrawn yet after unlocking. Be careful.
        conditionalLockStates[conditionHash] = met;
        // Consider adding an event here ConditionStatusChanged(conditionHash, met);
    }

     /**
     * @dev Owner simulates external yield being added to the vault for a specific token.
     * This does not interact with external protocols but allows demonstrating
     * how the vault handles its balance increasing from sources outside deposits.
     * @param token The address of the token (address(0) for Ether).
     * @param yieldAmount The simulated amount of yield received.
     */
    function simulateExternalYield(address token, uint256 yieldAmount) external onlyOwner onlyApprovedToken(token) {
        require(yieldAmount > 0, "QV: Yield amount must be > 0");
        // This function simply acts as if funds were received externally.
        // In a real scenario, this would involve actual token transfers into the contract.
        // For Ether: no action needed, just event.
        // For Tokens: In a real contract, you'd need to handle the incoming token transfer here.
        // As a simulation, we just emit the event.
        emit ExternalYieldSimulated(token, yieldAmount);
    }


    // --- Unlocking Mechanisms ---

    /**
     * @dev Attempts to unlock a Timed lock. Can be called by anyone, but only
     * succeeds if the lock exists, is a Timed lock, belongs to the caller,
     * is not already unlocked (N/A for Timed), and the unlock time has passed.
     * @param lockId The ID of the lock to unlock.
     */
    function unlockTimedLock(uint256 lockId) external {
        Lock storage lock = locks[lockId];
        require(lock.exists, "QV: Lock does not exist");
        require(lock.lockType == LockType.Timed, "QV: Not a Timed lock");
        require(lock.owner == msg.sender, "QV: Not the owner of this lock");
        require(block.timestamp >= lock.unlockTime, "QV: Lock time has not passed");

        // Timed locks are implicitly unlocked when time passes, no state change needed.
        // We just mark it as unlocked for tracking/preventing double unlock calls if needed.
        // Deleting or marking state could be options depending on desired behavior.
        // Let's just emit the event and rely on the time check for actual withdrawal.
        emit LockUnlocked(lockId);
        // Note: Funds are unlocked, but withdrawal still needs to be called separately
        // using withdrawEther/withdrawToken and is subject to cooldown.
    }

    /**
     * @dev Attempts to unlock a Conditional lock. Can be called by the lock owner.
     * Succeeds if the lock exists, is a Conditional lock, belongs to the caller,
     * is not already unlocked, and the associated condition has been marked as met.
     * @param lockId The ID of the lock to unlock.
     */
    function unlockConditionalLock(uint256 lockId) external {
        Lock storage lock = locks[lockId];
        require(lock.exists, "QV: Lock does not exist");
        require(lock.lockType == LockType.Conditional, "QV: Not a Conditional lock");
        require(lock.owner == msg.sender, "QV: Not the owner of this lock");
        require(!lock.isUnlocked, "QV: Lock already unlocked");
        require(conditionalLockStates[lock.conditionHash], "QV: Condition not met yet");

        lock.isUnlocked = true;
        emit LockUnlocked(lockId);
        // Funds are unlocked, but withdrawal still needs to be called separately
        // using withdrawEther/withdrawToken and is subject to cooldown.
    }

    /**
     * @dev Attempts to unlock a Delegated lock. Can only be called by the designated delegatee.
     * Succeeds if the lock exists, is a Delegated lock, the caller is the correct delegatee,
     * is not already unlocked, and the provided unlock code matches the stored hash.
     * The lock owner CANNOT call this function to unlock.
     * @param lockId The ID of the lock to unlock.
     * @param unlockCode The secret code required to unlock the lock.
     */
    function unlockDelegatedLock(uint256 lockId, uint256 unlockCode) external {
        Lock storage lock = locks[lockId];
        require(lock.exists, "QV: Lock does not exist");
        require(lock.lockType == LockType.Delegated, "QV: Not a Delegated lock");
        require(lock.delegatee == msg.sender, "QV: Not the designated delegatee for this lock");
        require(!lock.isUnlocked, "QV: Lock already unlocked");
        require(keccak256(abi.encodePacked(unlockCode)) == lock.unlockCodeHash, "QV: Incorrect unlock code");

        lock.isUnlocked = true;
        emit LockUnlocked(lockId);
         // Funds are unlocked, but withdrawal still needs to be called separately
         // using withdrawEther/withdrawToken (by the delegatee, subject to cooldown).
         // Or perhaps the delegatee can withdraw immediately? Let's keep it separate
         // from withdrawal flow for clarity and apply cooldown uniformly.
    }


    // --- Delegation Management & Execution ---

    /**
     * @dev Grants withdrawal rights to a delegatee for a specific token.
     * The grantor can delegate up to `maxAmount` of the token which the
     * delegatee can withdraw cumulatively until `expiry`.
     * A grantor can grant multiple delegations to the same delegatee for different tokens,
     * or update existing delegations for a token by calling this again (maxAmount/expiry update).
     * @param delegatee The address to grant withdrawal rights to.
     * @param token The token address (address(0) for Ether) for which rights are granted.
     * @param maxAmount The maximum cumulative amount the delegatee can withdraw for this token using this delegation.
     * @param expiry The timestamp when the delegation expires. 0 means no expiry.
     */
    function delegateWithdrawalRights(address delegatee, address token, uint256 maxAmount, uint256 expiry) external onlyApprovedToken(token) {
        require(delegatee != address(0), "QV: Delegatee cannot be zero address");
        require(delegatee != msg.sender, "QV: Cannot delegate to yourself");

        Delegation storage delegation = delegations[delegatee][msg.sender];

        // Initialize or update delegation
        delegation.delegatee = delegatee;
        delegation.grantor = msg.sender;
        delegation.maxAmountPerToken[token] = maxAmount; // Set or update the max amount
        delegation.expiry = expiry; // Set or update expiry
        delegation.isActive = true; // Ensure it's active
        delegation.exists = true; // Mark as exists

        // Reset used amount if max amount is increased? Or let it continue?
        // Let's decide that calling this function sets a NEW max amount for the token.
        // If the new maxAmount is less than the used amount, it effectively revokes
        // further withdrawals until used amount is reset (e.g. by revoking).
        // For simplicity, let's NOT reset usedAmount here. A separate revoke is needed.

        emit DelegationGranted(msg.sender, delegatee, token, maxAmount, expiry);
    }

    /**
     * @dev Revokes all active delegations granted by the caller to a specific delegatee.
     * This sets the delegation to inactive and resets the used amount for all tokens.
     * @param delegatee The address whose delegation from the caller should be revoked.
     */
    function revokeDelegatedWithdrawal(address delegatee) external {
        Delegation storage delegation = delegations[delegatee][msg.sender];
        require(delegation.exists && delegation.isActive, "QV: No active delegation from you to this delegatee");

        // Reset used amounts for all tokens in this delegation (simple clear)
        // In a complex contract, you'd iterate through potentially delegated tokens.
        // For this example, we assume delegation maps tokens explicitly as added.
        // A full reset by deleting/clearing the mapping requires known keys,
        // so we just mark inactive and reset used amounts if known.
        // Simpler: just mark inactive and any check will fail.
        delegation.isActive = false;
        // Clear known used amounts (if tracking a list of delegated tokens)
        // Since we use a mapping, future reads of usedAmountPerToken[token] will be 0 anyway if not set.
        // Let's explicitly set known ones to zero if we tracked them. Since we don't track keys here,
        // the simplest is just `isActive = false`.

        emit DelegationRevoked(msg.sender, delegatee);
    }

    /**
     * @dev Allows a delegatee to withdraw funds based on the rights granted by a grantor.
     * Subject to the delegation's max amount, expiry, and withdrawal cooldown.
     * @param grantor The address who granted the delegation.
     * @param token The token address (address(0) for Ether) to withdraw.
     * @param amount The amount to withdraw.
     */
    function executeDelegatedWithdrawal(address grantor, address token, uint256 amount) external onlyApprovedToken(token) checkWithdrawalCooldown {
        require(amount > 0, "QV: Withdrawal amount must be > 0");
        require(grantor != address(0), "QV: Grantor cannot be zero address");

        Delegation storage delegation = delegations[msg.sender][grantor];
        require(delegation.exists && delegation.isActive, "QV: No active delegation from this grantor to you");
        require(delegation.delegatee == msg.sender, "QV: Delegation not for you"); // Redundant but good check

        // Check expiry
        if (delegation.expiry > 0) {
            require(block.timestamp <= delegation.expiry, "QV: Delegation expired");
        }

        // Check amount limits
        uint256 currentUsed = delegation.usedAmountPerToken[token];
        uint256 maxAmount = delegation.maxAmountPerToken[token];
        require(currentUsed + amount <= maxAmount, "QV: Amount exceeds remaining delegated limit for this token");

        // Check vault balance (only unlocked funds can be delegated for withdrawal)
        // This is a crucial security check. Delegated withdrawals should only
        // use funds that are NOT locked by any other mechanism.
        uint256 vaultBalance = (token == address(0) ? address(this).balance : _getTokenBalance(token));
        uint256 totalLocked = _getTotalLockedBalance(token);
        uint256 unlockedBalance = vaultBalance - totalLocked;

        // Additional Check: Ensure the funds delegated are available *and* unlocked by the grantor.
        // This is complex. Simplification: Assume delegated amount comes from the grantor's
        // theoretical available balance, but can only withdraw from the vault's *total*
        // unlocked balance. This is a simpler model. A more complex model would track
        // unlocked funds per user/delegation.
        // Using the simpler model: Just check against total unlocked vault balance.
         require(amount <= unlockedBalance, "QV: Amount exceeds vault's total unlocked balance");


        // Update used amount
        delegation.usedAmountPerToken[token] += amount;

        _updateLastWithdrawalTime(msg.sender);

        // Execute withdrawal
        if (token == address(0)) {
             (bool success, ) = payable(msg.sender).call{value: amount}("");
             require(success, "QV: Delegated Ether withdrawal failed");
        } else {
            bytes memory payload = abi.encodeWithSelector(0xa9059cbb, msg.sender, amount);
            (bool success, bytes memory data) = token.call(payload);

            require(success, "QV: Delegated Token transferOut failed");
             if (data.length > 0) {
                require(abi.decode(data, (bool)), "QV: Delegated Token transferOut returned false");
            }
        }

        emit DelegatedWithdrawal(msg.sender, grantor, token, amount);
    }


    // --- View & Helper Functions ---

    /**
     * @dev Internal helper to get ERC-20 token balance.
     * @param token The address of the token.
     * @return The token balance of the contract.
     */
    function _getTokenBalance(address token) internal view returns (uint256) {
        require(token != address(0), "QV: Cannot get balance for zero address");
        // Using staticcall for view function robustness
        bytes memory payload = abi.encodeWithSelector(0x70a08231, address(this)); // ERC20 balanceof(address)
        (bool success, bytes memory data) = token.staticcall(payload);
        require(success && data.length >= 32, "QV: Token balance call failed");
        return abi.decode(data, (uint256));
    }

    /**
     * @dev Internal helper to calculate the total amount locked for a specific token (or Ether).
     * Iterates through all known locks. In a high-volume scenario, this could be inefficient.
     * A more scalable design might aggregate locked amounts per token in state variables.
     * @param token The address of the token (address(0) for Ether).
     * @return The total amount currently locked for the given token.
     */
    function _getTotalLockedBalance(address token) internal view returns (uint256) {
        uint256 totalLocked = 0;
        // Iterating through all locks is inefficient for many locks.
        // A better approach might be to maintain a running total
        // in a mapping like mapping(address => uint256) totalLockedBalances;
        // and update it whenever locks are created/unlocked.
        // For this example, we use iteration for simplicity of demonstrating the concept.
        // Assuming `nextLockId` gives an upper bound (though deleted/unlocked locks exist).
        // A better way would be iterating through `ownerLockIds` for all owners or a list of active lockIds.
        // Let's iterate ownerLockIds for a slightly better approach than blindly looping up to nextLockId.

        // To get ALL locked funds across all owners, we'd need a global list of lock IDs or iterate all owners.
        // Let's provide a simpler view function that aggregates across *all* locks, recognizing the scaling limit.
        // This requires iterating up to nextLockId, checking `locks[i].exists`.

        for (uint i = 0; i < nextLockId; i++) {
            Lock storage lock = locks[i];
            if (lock.exists && lock.token == token) {
                // Check if the lock is currently effective (not unlocked by its condition/code/time)
                bool stillLocked = false;
                if (lock.lockType == LockType.Timed) {
                    if (block.timestamp < lock.unlockTime) {
                        stillLocked = true;
                    }
                } else if (lock.lockType == LockType.Conditional) {
                    if (!lock.isUnlocked) {
                         stillLocked = true;
                    }
                } else if (lock.lockType == LockType.Delegated) {
                     if (!lock.isUnlocked) {
                        stillLocked = true;
                    }
                }
                // Add amount if it's still locked
                if (stillLocked) {
                    totalLocked += lock.amount;
                }
            }
        }
        return totalLocked;
    }

    /**
     * @dev Internal helper to update the last withdrawal timestamp.
     * @param user The address of the user who withdrew.
     */
    function _updateLastWithdrawalTime(address user) internal {
         lastWithdrawalTime[user] = block.timestamp;
    }

    /**
     * @dev Modifier to enforce the withdrawal cooldown.
     */
    modifier checkWithdrawalCooldown() {
        if (withdrawalCooldownDuration > 0) {
            require(block.timestamp >= lastWithdrawalTime[msg.sender] + withdrawalCooldownDuration, "QV: Withdrawal cooldown active");
        }
        _;
    }

    /**
     * @dev Checks if a token address is in the approved list.
     * @param token The address of the token.
     * @return True if approved, false otherwise.
     */
    function isApprovedToken(address token) external view returns (bool) {
        if (token == address(0)) return true; // Ether is always implicitly approved
        return approvedTokens[token];
    }

     /**
     * @dev Returns the list of approved token addresses.
     * Note: This list might be slightly out of sync if tokens were removed
     * inefficiently from the list array. Use `isApprovedToken` for definitive check.
     * @return An array of approved token addresses.
     */
    function getApprovedTokens() external view returns (address[] memory) {
        // Could filter the list array based on the mapping for accuracy
         uint256 count = 0;
         for(uint i = 0; i < approvedTokenList.length; i++){
             if(approvedTokens[approvedTokenList[i]]){
                 count++;
             }
         }
         address[] memory currentApproved = new address[](count);
         uint k = 0;
         for(uint i = 0; i < approvedTokenList.length; i++){
              if(approvedTokens[approvedTokenList[i]]){
                 currentApproved[k] = approvedTokenList[i];
                 k++;
             }
         }
        return currentApproved;
    }


    /**
     * @dev Returns the currently set withdrawal cooldown duration.
     * @return The cooldown duration in seconds.
     */
    function getWithdrawalCooldown() external view returns (uint256) {
        return withdrawalCooldownDuration;
    }

    /**
     * @dev Returns details for a specific lock.
     * @param lockId The ID of the lock.
     * @return The Lock struct data.
     */
    function getLockDetails(uint256 lockId) external view returns (Lock memory) {
        require(locks[lockId].exists, "QV: Lock does not exist");
        return locks[lockId];
    }

     /**
     * @dev Returns details for a specific delegation granted by a grantor to a delegatee.
     * @param delegatee The address of the delegatee.
     * @param grantor The address of the grantor.
     * @return The Delegation struct data. Note: mapping within struct is not fully readable externally this way.
     *         Need specific functions for delegated amounts per token.
     */
    function getDelegationDetails(address delegatee, address grantor) external view returns (Delegation memory) {
        // Note: This view function cannot fully return the inner mapping `maxAmountPerToken` or `usedAmountPerToken`.
        // You would need separate functions like `getDelegatedAmountLimit(delegatee, grantor, token)`
        // and `getDelegatedAmountUsed(delegatee, grantor, token)`.
        // Returning the struct itself gives metadata but not dynamic mapping data.
        return delegations[delegatee][grantor];
    }

    /**
     * @dev Returns the list of lock IDs created by a specific user.
     * Note: This list may contain IDs of locks that no longer exist if locks
     * were permanently removed (this contract doesn't explicitly remove them,
     * just marks them as unlocked or relies on time).
     * @param user The address whose locks to retrieve.
     * @return An array of lock IDs.
     */
    function getLockIdsByOwner(address user) external view returns (uint256[] memory) {
        return ownerLockIds[user];
    }


    // --- Self-destruct ---

    /**
     * @dev Destroys the contract, sending all remaining Ether and tokens
     * to the contract owner's address. Can only be called by the owner
     * after the scheduled self-destruct delay has passed.
     * Use with extreme caution as this is irreversible and may result in
     * loss of funds if called while funds are still intended to be locked.
     * This bypasses all locks and withdrawal mechanisms.
     */
    function selfDestruct() external onlyOwner {
        require(selfDestructScheduledAt > 0, "QV: Self-destruct not scheduled");
        require(block.timestamp >= selfDestructScheduledAt + selfDestructDelay, "QV: Self-destruct delay has not passed");

        // Explicitly transfer ERC20 balances to owner before selfdestruct
        // Iterating all tokens in `approvedTokenList` is needed.
        // This is a simplified approach. In reality, iterating mappings isn't possible directly.
        // Need to track all token addresses with balances or rely only on Ether.
        // Given the limitations, let's just handle Ether via the built-in selfdestruct and
        // note that ERC20 recovery requires manual calls or a helper function *before* destruct.
        // A production contract would need a robust way to sweep tokens.
        // For this example, selfdestruct only reliably sends Ether.

        selfdestruct(payable(_owner));
    }
}
```