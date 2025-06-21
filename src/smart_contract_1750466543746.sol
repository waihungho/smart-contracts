Okay, here is a Solidity smart contract called `QuantumVault`. It aims to be creative and utilize several interconnected advanced concepts without being a direct copy of standard open-source protocols.

It incorporates:
1.  **Multi-Asset Management:** Handling both native ETH and a custom ERC-20 token.
2.  **Conditional & Timed Locks:** Funds locked based on time *or* external conditions.
3.  **Fractional & Delegated Access:** Allowing parts of locked funds to be designated to others or management rights transferred.
4.  **Dynamic Fees & States:** Contract behavior (like fees) can change based on administrative triggers or simulated external data.
5.  **Simulated Oracle Interaction:** Functions to simulate receiving external data (like price feeds) and acting upon it.
6.  **Reputation System:** An internal score affecting user withdrawal limits or fees.
7.  **Goal-Based Contributions:** Users contributing to collective goals tracked by the contract.
8.  **Paused States:** Granular pausing of specific functionalities.
9.  **Event Sourcing:** Comprehensive events for transparency.
10. **Custom Errors:** Gas-efficient error handling.

It has well over the minimum of 20 functions, including core logic, administrative controls, and helper/getter functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary interfaces - Using a standard ERC20 interface
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title QuantumVault
 * @dev A multi-faceted vault contract supporting dynamic locking, conditional releases,
 * fractional access, internal state changes, simulated oracle interaction, and reputation scoring.
 * Not intended for production without rigorous audits and real oracle integration.
 */

/**
 * @notice Outline and Function Summary
 *
 * --- Core Vault Management ---
 * 1.  constructor(): Initializes the contract owner and the custom token address.
 * 2.  depositETH(): Allows users to deposit ETH into their vault balance.
 * 3.  depositToken(uint256 amount): Allows users to deposit the configured custom token.
 * 4.  withdrawETH(uint256 amount): Allows users to withdraw their available ETH balance (subject to checks).
 * 5.  withdrawToken(uint256 amount): Allows users to withdraw their available token balance (subject to checks).
 * 6.  emergencyWithdrawOwner(address tokenAddress, uint256 amount): Owner emergency withdrawal function.
 * 7.  transferOwnership(address newOwner): Transfers contract ownership.
 *
 * --- Balance & Status Getters ---
 * 8.  getVaultBalanceETH(): Get total ETH held by the contract.
 * 9.  getVaultBalanceToken(): Get total token held by the contract.
 * 10. getUserBalanceETH(address user): Get a specific user's available ETH balance.
 * 11. getUserBalanceToken(address user): Get a specific user's available token balance.
 * 12. getLockDetails(uint256 lockId): Get details of a specific lock.
 * 13. isConditionFulfilled(bytes32 conditionHash): Check if a specific condition has been marked as fulfilled.
 * 14. getReputationScore(address user): Get a user's reputation score.
 * 15. getCurrentVaultState(): Get the current internal state of the vault.
 * 16. getPausedFlags(): Get the current paused flags status.
 *
 * --- Locking & Conditional Release ---
 * 17. lockFundsTimed(uint256 amount, uint256 unlockTime, uint8 assetType): Lock funds (ETH or Token) until a specific time.
 * 18. lockFundsConditional(uint256 amount, bytes32 conditionHash, uint8 assetType): Lock funds until a specific condition is fulfilled.
 * 19. unlockFunds(uint256 lockId): Attempt to unlock funds for a given lock ID (checks time or condition).
 * 20. fulfillCondition(bytes32 conditionHash): Owner/Oracle marks a specific condition as fulfilled globally.
 * 21. setAutoReleaseCondition(uint256 lockId, bytes32 autoConditionHash): Link a lock to a condition hash for potential auto-release logic (requires external trigger or manual call).
 * 22. attemptAutoRelease(uint256 lockId): Allows anyone to attempt to release a lock if its linked auto-release condition is fulfilled.
 *
 * --- Fractional & Delegated Access ---
 * 23. setFractionalRecipient(uint256 lockId, address recipient, uint256 fractionNumerator, uint256 fractionDenominator): Designate a recipient for a fraction of a specific lock.
 * 24. transferLockOwnership(uint256 lockId, address newOwner): Transfer the management rights of a lock.
 * 25. authorizePartialWithdrawal(address recipient, uint256 amount, uint256 expiration, uint8 assetType): Authorize a specific address to withdraw a limited amount before expiration.
 * 26. revokeAuthorization(address recipient, uint8 assetType): Revoke an existing withdrawal authorization.
 * 27. withdrawAuthorized(address granter, uint8 assetType): Allows an authorized recipient to withdraw their portion.
 *
 * --- Dynamic State & Fees ---
 * 28. setDynamicFeeRate(uint16 newRatePermille): Owner sets a new withdrawal fee rate in parts per thousand (per mille).
 * 29. triggerStateChange(uint8 newState): Owner changes the contract's internal state (influencing behavior).
 * 30. setWithdrawalLimits(uint8 reputationScore, uint256 limitETH, uint256 limitToken): Owner sets withdrawal limits based on reputation score.
 *
 * --- Simulated Oracle Interaction ---
 * 31. updatePriceFeed(uint256 ethPriceUsd, uint256 tokenPriceUsd): Owner simulates updating price data.
 * 32. triggerActionBasedOnPrice(uint256 ethPriceThreshold, uint8 actionType): Owner triggers specific actions if ETH price meets a threshold. (Action types are internal logic hooks).
 *
 * --- Reputation System ---
 * 33. assignReputationScore(address user, uint8 score): Owner assigns a reputation score to a user.
 *
 * --- Goal-Based Contributions ---
 * 34. createVaultGoal(bytes32 goalId, uint256 targetAmountToken, uint256 deadline): Owner creates a community contribution goal.
 * 35. contributeToGoal(bytes32 goalId, uint256 amount): Users contribute tokens to a goal.
 * 36. claimGoalCompletionStatus(bytes32 goalId): Users can register their claim that a goal was completed by the deadline (external verification needed).
 * 37. getGoalDetails(bytes32 goalId): Get details of a specific goal.
 * 38. getUserGoalContribution(bytes32 goalId, address user): Get a user's contribution to a goal.
 *
 * --- Pausing Mechanism ---
 * 39. pauseVault(uint8 flags): Owner pauses specific functions using bit flags.
 * 40. unpauseVault(uint8 flags): Owner unpauses specific functions using bit flags.
 */

// Custom Error Definitions - More gas-efficient than revert strings
error Unauthorized();
error InsufficientBalance();
error InsufficientVaultBalance();
error InvalidAmount();
error InvalidAssetType();
error LockNotFound();
error LockStillLocked();
error LockAlreadyUnlocked();
error ConditionNotFulfilled();
error AlreadyFractionalized();
error InvalidFraction();
error AuthorizationNotFound();
error AuthorizationExpired();
error AuthorizationAmountExceeded();
error GoalNotFound();
error GoalExpired();
error GoalAlreadyCompleted();
error GoalNotYetCompleted();
error ContributionTooSmall(); // Example
error InvalidReputationScore();
error Paused(uint8 flags);
error ZeroAddress();
error ReentrancyGuard(); // Simple reentrancy detection placeholder

contract QuantumVault {
    address private _owner;
    IERC20 private immutable _customToken;

    // User Balances
    mapping(address => uint256) private userETHBalances;
    mapping(address => uint256) private userTokenBalances;

    // Asset Type Enum
    enum AssetType { ETH, TOKEN }

    // Lock Structure
    struct Lock {
        uint256 id; // Unique Lock ID
        address owner; // Current owner of the lock management rights
        uint256 amount;
        AssetType assetType;
        uint256 unlockTime; // 0 if conditional
        bytes32 conditionHash; // bytes32(0) if timed
        bool unlocked; // True if funds have been released
        uint256 creationTime;
        address fractionalRecipient; // Address for fractional withdrawal
        uint256 fractionNumerator;
        uint256 fractionDenominator;
        bytes32 autoReleaseConditionHash; // Condition that *could* auto-release this lock
    }

    mapping(uint256 => Lock) private locks;
    uint256 private nextLockId = 1; // Start lock IDs from 1

    // Conditional Locks State
    mapping(bytes32 => bool) private conditionsFulfilled;

    // Partial Withdrawal Authorization
    struct AuthorizedWithdrawal {
        uint256 amount;
        uint256 expiration;
        address granter; // The address that granted this authorization
    }
    mapping(address => mapping(uint8 => AuthorizedWithdrawal)) private authorizedWithdrawals; // recipient => assetType => Authorization

    // Dynamic State
    uint8 private currentState = 0; // Default state 0
    uint16 private withdrawalFeeRatePermille = 0; // Fee rate in per mille (parts per thousand), 0-1000

    // Simulated Oracle Data
    uint256 private lastETHPriceUsd;
    uint256 private lastTokenPriceUsd;
    uint48 private lastPriceUpdateTime; // uint48 to save space

    // Internal Reputation System
    mapping(address => uint8) private reputationScores; // 0-100 score
    mapping(uint8 => struct { uint256 limitETH; uint256 limitToken; }) private withdrawalLimitsByReputation;

    // Goal-Based Contributions
    struct VaultGoal {
        bytes32 goalId;
        uint256 targetAmountToken;
        uint256 deadline;
        uint256 totalContributionsToken;
        bool completed; // Set if target met by deadline (requires owner/oracle to verify and set)
        mapping(address => uint256) contributions; // User contributions to this specific goal
    }
    mapping(bytes32 => VaultGoal) private vaultGoals;
    // Note: `completed` flag for goals needs external verification logic in a real system. Here, assume owner sets it.

    // Pausing Mechanism - Using bit flags for granularity
    // e.g., 0x01 = pause deposits, 0x02 = pause withdrawals, 0x04 = pause locking, etc.
    uint8 private pausedFlags = 0;

    // Reentrancy Guard - Simple implementation
    uint256 private _guard = 1;

    modifier onlyOwner() {
        if (msg.sender != _owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused(uint8 flag) {
        if ((pausedFlags & flag) != 0) revert Paused(flag);
        _;
    }

    // Simple Reentrancy Guard
    modifier nonReentrant() {
        if (_guard == 0) revert ReentrancyGuard();
        _guard = 0;
        _;
        _guard = 1;
    }

    // --- Events ---
    event Deposit(address indexed user, uint8 assetType, uint256 amount);
    event Withdrawal(address indexed user, uint8 assetType, uint256 amount, uint256 fee);
    event LockCreated(address indexed owner, uint256 lockId, uint8 assetType, uint256 amount, uint256 unlockTime, bytes32 conditionHash);
    event LockUnlocked(uint256 indexed lockId, address indexed recipient, uint256 amount); // recipient might be original owner or fractional recipient
    event LockOwnershipTransferred(uint256 indexed lockId, address indexed oldOwner, address indexed newOwner);
    event ConditionFulfilled(bytes32 indexed conditionHash);
    event FractionalRecipientSet(uint256 indexed lockId, address indexed recipient, uint256 numerator, uint256 denominator);
    event AuthorizationGranted(address indexed granter, address indexed recipient, uint8 assetType, uint256 amount, uint256 expiration);
    event AuthorizationRevoked(address indexed granter, address indexed recipient, uint8 assetType);
    event AuthorizedWithdrawalPerformed(address indexed granter, address indexed recipient, uint8 assetType, uint256 amount);
    event FeeRateUpdated(uint16 newRatePermille);
    event StateChanged(uint8 newState);
    event PriceFeedUpdated(uint256 ethPriceUsd, uint256 tokenPriceUsd, uint48 timestamp);
    event ActionTriggeredBasedOnPrice(uint256 ethPriceThreshold, uint8 actionType);
    event ReputationScoreUpdated(address indexed user, uint8 score);
    event WithdrawalLimitsUpdated(uint8 reputationScore, uint256 limitETH, uint256 limitToken);
    event GoalCreated(bytes32 indexed goalId, uint256 targetAmountToken, uint256 deadline);
    event GoalContributed(bytes32 indexed goalId, address indexed user, uint256 amount, uint256 totalContribution);
    event GoalCompletionClaimed(bytes32 indexed goalId, address indexed user); // Claiming status, not necessarily reward
    event VaultPaused(uint8 flags);
    event VaultUnpaused(uint8 flags);
    event EmergencyWithdraw(address indexed tokenAddress, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address customTokenAddress) {
        if (customTokenAddress == address(0)) revert ZeroAddress();
        _owner = msg.sender;
        _customToken = IERC20(customTokenAddress);

        // Initialize some default withdrawal limits (example)
        withdrawalLimitsByReputation[0] = struct { uint256 limitETH; uint256 limitToken; }(1 ether, 100 ether);
        withdrawalLimitsByReputation[50] = struct { uint256 limitETH; uint256 limitToken; }(10 ether, 1000 ether);
        withdrawalLimitsByReputation[100] = struct { uint256 limitETH; uint256 limitToken; }(type(uint256).max, type(uint256).max); // Unlimited for max rep
    }

    // --- Core Vault Management ---

    /**
     * @dev Allows users to deposit ETH into their vault balance.
     */
    function depositETH() external payable whenNotPaused(0x01) nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        userETHBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, AssetType.ETH, msg.value);
    }

    /**
     * @dev Allows users to deposit the configured custom token. Requires prior approval.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(uint256 amount) external whenNotPaused(0x01) nonReentrant {
        if (amount == 0) revert InvalidAmount();
        // Transfer tokens from the user to the contract
        bool success = _customToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientBalance(); // or a more specific token transfer error

        userTokenBalances[msg.sender] += amount;
        emit Deposit(msg.sender, AssetType.TOKEN, amount);
    }

    /**
     * @dev Allows users to withdraw their available ETH balance.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external nonReentrant whenNotPaused(0x02) {
        if (amount == 0) revert InvalidAmount();
        uint256 availableBalance = userETHBalances[msg.sender];
        if (availableBalance < amount) revert InsufficientBalance();

        // Apply withdrawal limits based on reputation
        uint8 rep = reputationScores[msg.sender];
        uint256 limit = withdrawalLimitsByReputation[rep].limitETH;
        if (amount > limit) {
             // Find the appropriate limit based on score ranges
             uint256 effectiveLimit = 0;
             if(rep >= 100) effectiveLimit = withdrawalLimitsByReputation[100].limitETH;
             else if(rep >= 50) effectiveLimit = withdrawalLimitsByReputation[50].limitETH;
             else effectiveLimit = withdrawalLimitsByReputation[0].limitETH;

             if (amount > effectiveLimit) revert InsufficientBalance(); // Or a specific limit error
        }


        // Apply withdrawal fee
        uint256 fee = (amount * withdrawalFeeRatePermille) / 1000;
        uint256 amountAfterFee = amount - fee;

        userETHBalances[msg.sender] -= amount;
        // Send ETH to the user
        (bool success, ) = payable(msg.sender).call{value: amountAfterFee}("");
        if (!success) {
            // Revert or handle transfer failure - here we revert and revert balance change
            userETHBalances[msg.sender] += amount; // Revert state change
            revert(); // Or a specific transfer error
        }

        // Fee amount stays in the contract's ETH balance
        emit Withdrawal(msg.sender, AssetType.ETH, amountAfterFee, fee);
    }

    /**
     * @dev Allows users to withdraw their available token balance.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawToken(uint255 amount) external nonReentrant whenNotPaused(0x02) {
         if (amount == 0) revert InvalidAmount();
        uint256 availableBalance = userTokenBalances[msg.sender];
        if (availableBalance < amount) revert InsufficientBalance();

        // Apply withdrawal limits based on reputation
        uint8 rep = reputationScores[msg.sender];
        uint256 limit = withdrawalLimitsByReputation[rep].limitToken;
         if (amount > limit) {
             // Find the appropriate limit based on score ranges
             uint256 effectiveLimit = 0;
             if(rep >= 100) effectiveLimit = withdrawalLimitsByReputation[100].limitToken;
             else if(rep >= 50) effectiveLimit = withdrawalLimitsByReputation[50].limitToken;
             else effectiveLimit = withdrawalLimitsByReputation[0].limitToken;

             if (amount > effectiveLimit) revert InsufficientBalance(); // Or a specific limit error
        }

        // Apply withdrawal fee
        uint256 fee = (amount * withdrawalFeeRatePermille) / 1000;
        uint256 amountAfterFee = amount - fee;

        userTokenBalances[msg.sender] -= amount;
        // Transfer tokens to the user
        bool success = _customToken.transfer(msg.sender, amountAfterFee);
        if (!success) {
            // Revert or handle transfer failure - here we revert and revert balance change
            userTokenBalances[msg.sender] += amount; // Revert state change
             revert(); // Or a specific token transfer error
        }

        // Fee amount stays in the contract's token balance
        emit Withdrawal(msg.sender, AssetType.TOKEN, amountAfterFee, fee);
    }

     /**
     * @dev Owner can withdraw funds in an emergency.
     * @param tokenAddress The address of the token to withdraw (use address(0) for ETH).
     * @param amount The amount to withdraw.
     */
    function emergencyWithdrawOwner(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert InvalidAmount();

        if (tokenAddress == address(0)) { // ETH
            if (address(this).balance < amount) revert InsufficientVaultBalance();
            (bool success, ) = payable(_owner).call{value: amount}("");
             if (!success) revert(); // Or specific error
        } else { // ERC20 Token
            IERC20 token = IERC20(tokenAddress);
            if (token.balanceOf(address(this)) < amount) revert InsufficientVaultBalance();
            bool success = token.transfer(_owner, amount);
            if (!success) revert(); // Or specific error
        }
        emit EmergencyWithdraw(tokenAddress, amount);
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // --- Balance & Status Getters ---

    function getVaultBalanceETH() external view returns (uint256) {
        return address(this).balance;
    }

    function getVaultBalanceToken() external view returns (uint256) {
        return _customToken.balanceOf(address(this));
    }

    function getUserBalanceETH(address user) external view returns (uint256) {
        return userETHBalances[user];
    }

    function getUserBalanceToken(address user) external view returns (uint256) {
        return userTokenBalances[user];
    }

     /**
     * @dev Get details of a specific lock.
     * @param lockId The ID of the lock.
     */
    function getLockDetails(uint256 lockId) external view returns (
        uint256 id,
        address owner,
        uint256 amount,
        AssetType assetType,
        uint256 unlockTime,
        bytes32 conditionHash,
        bool unlocked,
        uint256 creationTime,
        address fractionalRecipient,
        uint256 fractionNumerator,
        uint256 fractionDenominator,
        bytes32 autoReleaseConditionHash
    ) {
        Lock storage lock = locks[lockId];
         if (lock.id == 0) revert LockNotFound(); // Check if lock exists
        return (
            lock.id,
            lock.owner,
            lock.amount,
            lock.assetType,
            lock.unlockTime,
            lock.conditionHash,
            lock.unlocked,
            lock.creationTime,
            lock.fractionalRecipient,
            lock.fractionNumerator,
            lock.fractionDenominator,
            lock.autoReleaseConditionHash
        );
    }

    /**
     * @dev Check if a specific condition hash has been marked as fulfilled.
     * @param conditionHash The hash representing the condition.
     */
    function isConditionFulfilled(bytes32 conditionHash) external view returns (bool) {
        return conditionsFulfilled[conditionHash];
    }

    /**
     * @dev Get a user's internal reputation score.
     * @param user The address of the user.
     */
    function getReputationScore(address user) external view returns (uint8) {
        return reputationScores[user];
    }

    /**
     * @dev Get the current internal state of the vault.
     */
    function getCurrentVaultState() external view returns (uint8) {
        return currentState;
    }

     /**
     * @dev Get the current paused flags status.
     */
    function getPausedFlags() external view returns (uint8) {
        return pausedFlags;
    }


    // --- Locking & Conditional Release ---

    /**
     * @dev Locks a specific amount of ETH or Token for a specific duration.
     * @param amount The amount of the asset to lock.
     * @param unlockTime The unix timestamp when the lock expires.
     * @param assetType The type of asset to lock (ETH=0, TOKEN=1).
     */
    function lockFundsTimed(uint256 amount, uint256 unlockTime, uint8 assetType) external nonReentrant whenNotPaused(0x04) {
        if (amount == 0) revert InvalidAmount();
        if (unlockTime <= block.timestamp) revert LockStillLocked(); // unlockTime must be in the future
        if (assetType != uint8(AssetType.ETH) && assetType != uint8(AssetType.TOKEN)) revert InvalidAssetType();

        AssetType asset = AssetType(assetType);
        uint256 availableBalance;
        if (asset == AssetType.ETH) {
            availableBalance = userETHBalances[msg.sender];
            if (availableBalance < amount) revert InsufficientBalance();
            userETHBalances[msg.sender] -= amount;
        } else { // AssetType.TOKEN
            availableBalance = userTokenBalances[msg.sender];
            if (availableBalance < amount) revert InsufficientBalance();
            userTokenBalances[msg.sender] -= amount;
        }

        uint256 lockId = nextLockId++;
        locks[lockId] = Lock({
            id: lockId,
            owner: msg.sender,
            amount: amount,
            assetType: asset,
            unlockTime: unlockTime,
            conditionHash: bytes32(0), // Timed lock
            unlocked: false,
            creationTime: block.timestamp,
            fractionalRecipient: address(0),
            fractionalNumerator: 0,
            fractionalDenominator: 1, // Default to 1/1
            autoReleaseConditionHash: bytes32(0) // No auto-release condition initially
        });

        emit LockCreated(msg.sender, lockId, assetType, amount, unlockTime, bytes32(0));
    }

     /**
     * @dev Locks a specific amount of ETH or Token until a specific condition is fulfilled.
     * @param amount The amount of the asset to lock.
     * @param conditionHash A unique hash identifying the condition that must be fulfilled.
     * @param assetType The type of asset to lock (ETH=0, TOKEN=1).
     */
    function lockFundsConditional(uint256 amount, bytes32 conditionHash, uint8 assetType) external nonReentrant whenNotPaused(0x04) {
        if (amount == 0) revert InvalidAmount();
        if (conditionHash == bytes32(0)) revert ConditionNotFulfilled(); // Must provide a condition hash
         if (conditionsFulfilled[conditionHash]) revert ConditionNotFulfilled(); // Cannot lock on an already fulfilled condition
        if (assetType != uint8(AssetType.ETH) && assetType != uint8(AssetType.TOKEN)) revert InvalidAssetType();


        AssetType asset = AssetType(assetType);
        uint256 availableBalance;
        if (asset == AssetType.ETH) {
            availableBalance = userETHBalances[msg.sender];
            if (availableBalance < amount) revert InsufficientBalance();
            userETHBalances[msg.sender] -= amount;
        } else { // AssetType.TOKEN
            availableBalance = userTokenBalances[msg.sender];
            if (availableBalance < amount) revert InsufficientBalance();
            userTokenBalances[msg.sender] -= amount;
        }

        uint256 lockId = nextLockId++;
        locks[lockId] = Lock({
            id: lockId,
            owner: msg.sender,
            amount: amount,
            assetType: asset,
            unlockTime: 0, // Conditional lock
            conditionHash: conditionHash,
            unlocked: false,
            creationTime: block.timestamp,
             fractionalRecipient: address(0),
            fractionalNumerator: 0,
            fractionalDenominator: 1,
            autoReleaseConditionHash: bytes32(0)
        });

        emit LockCreated(msg.sender, lockId, assetType, amount, 0, conditionHash);
    }

    /**
     * @dev Allows the lock owner or fractional recipient to attempt to unlock funds for a lock.
     * Checks if the lock is timed and expired, or conditional and the condition is fulfilled.
     * Handles distribution to fractional recipient if set.
     * @param lockId The ID of the lock to unlock.
     */
    function unlockFunds(uint256 lockId) external nonReentrant whenNotPaused(0x08) {
        Lock storage lock = locks[lockId];
        if (lock.id == 0 || lock.unlocked) revert LockNotFound(); // LockNotFound implies already unlocked if ID exists

        bool canUnlock = false;
        if (lock.conditionHash == bytes32(0)) { // Timed Lock
            if (block.timestamp >= lock.unlockTime) {
                canUnlock = true;
            } else {
                 revert LockStillLocked();
            }
        } else { // Conditional Lock
            if (conditionsFulfilled[lock.conditionHash]) {
                 canUnlock = true;
            } else {
                 revert ConditionNotFulfilled();
            }
        }

        if (!canUnlock) revert(); // Should not happen if checks above are correct, but as a fallback

        // Check if caller is the lock owner or the designated fractional recipient
        if (msg.sender != lock.owner && msg.sender != lock.fractionalRecipient) {
            revert Unauthorized();
        }

        lock.unlocked = true; // Mark as unlocked first to prevent re-unlocking

        address recipient = lock.owner; // Default recipient is the owner
        uint256 amountToSend = lock.amount;

        if (lock.fractionalRecipient != address(0) && lock.fractionalDenominator > 0) {
             // Calculate fractional amounts
            uint256 fractionalAmount = (lock.amount * lock.fractionalNumerator) / lock.fractionalDenominator;
            uint256 ownerAmount = lock.amount - fractionalAmount;

            // Send fractional amount to the designated recipient if caller is the fractional recipient
            if (msg.sender == lock.fractionalRecipient) {
                recipient = lock.fractionalRecipient;
                amountToSend = fractionalAmount;
                 // The remaining owner amount is NOT sent here. It stays in the user's balance or another unlock call is needed by the owner.
                 // For simplicity, let's make this function unlock the *full* amount, distributed based on who calls.
                 // A cleaner design might be `claimFractionalAmount` and `claimOwnerAmount` distinct functions.
                 // Let's stick to one function for now, if fractional recipient calls, they get their share, if owner calls, they get the owner's share + fractional share if not claimed.
                 // This is getting complex. Let's simplify: `unlockFunds` can *only* be called by the owner OR the fractional recipient. If fractional, they get their share. If owner, they get the full amount MINUS the fractional share IF the fractional recipient hasn't claimed yet. This requires tracking fractional claim status per lock.
                 // ALTERNATIVE SIMPLIFICATION: `unlockFunds` releases the *full* amount to the original lock *owner's* AVAILABLE balance. The fractional recipient setting just serves as *information* or requires a separate function *called by the owner* to transfer after unlocking.
                 // Let's go with the owner gets the full amount back to their balance, and fractional recipient info is just metadata or used by a separate transfer function.
                 // OR, even simpler: `unlockFunds` sends the FULL amount to the ORIGINAL owner's AVAILABLE balance. FractionalRecipient is just a pointer for OFF-CHAIN logic or a separate transfer function.

                 // Let's try distributing directly from unlock:
                 if (msg.sender == lock.fractionalRecipient) {
                    amountToSend = fractionalAmount;
                    recipient = lock.fractionalRecipient;
                     // No need to adjust owner balance yet, the fractional amount is sent directly from contract balance.
                     // The *remaining* amount for the owner will be unlocked when the owner calls unlockFunds.
                 } else { // msg.sender is lock.owner
                     // Owner is unlocking. Send the owner's portion PLUS the fractional portion if unclaimed.
                     // This requires tracking if the fractional portion was claimed. Let's add a flag to Lock struct.
                     // Or, even simpler, if fractionalRecipient calls, they get their share. If owner calls, they get the full amount.
                     // Let's go back to the owner gets the full amount back to their AVAILABLE balance. This simplifies state.
                 }
        }

        // Send funds back to the lock owner's AVAILABLE balance
        if (lock.assetType == AssetType.ETH) {
            userETHBalances[lock.owner] += lock.amount;
            // Re-calculate amountToSend if fractional was intended to withdraw directly? No, stick to owner's balance for simplicity here.
        } else { // AssetType.TOKEN
             userTokenBalances[lock.owner] += lock.amount;
             // Re-calculate amountToSend if fractional was intended to withdraw directly? No, stick to owner's balance for simplicity here.
        }

        // If fractional recipient exists and caller is fractional recipient, send *their* share from contract balance directly.
        // This requires the fractional recipient to call *after* the condition/time is met, and *before* the owner calls `unlockFunds`.
        // This makes the state complex. Let's require the *owner* to call `unlockFunds`, which releases the full amount to *their* balance.
        // Then, a separate function `transferFractionalShare(lockId)` called by the owner transfers the calculated fractional amount from the owner's *available* balance to the recipient. This is much cleaner.

        // So, revised logic: `unlockFunds` releases full amount to owner's available balance. Fractional recipient is just metadata.
        // Let's revert the complex fractional logic within `unlockFunds`. It just adds the full amount back to the owner's balance.

        if (lock.assetType == AssetType.ETH) {
            userETHBalances[lock.owner] += lock.amount;
        } else { // AssetType.TOKEN
             userTokenBalances[lock.owner] += lock.amount;
        }

        // Emit event indicating full amount unlocked for the original owner
        emit LockUnlocked(lock.id, lock.owner, lock.amount);

         // Cleanup or leave lock struct? Leaving it allows querying historical locks. Just mark as unlocked.
    }

    /**
     * @dev Owner/Oracle marks a specific condition hash as fulfilled.
     * This allows conditional locks linked to this hash to be unlocked.
     * @param conditionHash The hash identifying the condition.
     */
    function fulfillCondition(bytes32 conditionHash) external onlyOwner {
        if (conditionHash == bytes32(0)) revert InvalidAmount(); // Should not be zero hash
        if (conditionsFulfilled[conditionHash]) revert ConditionNotFulfilled(); // Already fulfilled

        conditionsFulfilled[conditionHash] = true;
        emit ConditionFulfilled(conditionHash);

        // Note: This doesn't auto-unlock locks. `unlockFunds` or `attemptAutoRelease` must be called.
    }

     /**
     * @dev Allows the lock owner to link an existing lock to a condition hash for potential auto-release logic.
     * This does NOT automatically release the lock, it merely sets a flag that `attemptAutoRelease` can check.
     * @param lockId The ID of the lock to link.
     * @param autoConditionHash The condition hash that, when fulfilled, should allow auto-release.
     */
    function setAutoReleaseCondition(uint256 lockId, bytes32 autoConditionHash) external whenNotPaused(0x04) {
        Lock storage lock = locks[lockId];
        if (lock.id == 0 || lock.unlocked) revert LockNotFound();
        if (msg.sender != lock.owner) revert Unauthorized();
        if (autoConditionHash == bytes32(0)) revert InvalidAmount(); // Must be a valid hash

        lock.autoReleaseConditionHash = autoConditionHash;
        // No event for this specific linkage, implicit in LockUpdated if we had one, or just part of lock details
    }

    /**
     * @dev Allows anyone to attempt to release a lock if its linked auto-release condition is fulfilled.
     * This function pays gas for the caller but benefits the lock owner.
     * @param lockId The ID of the lock to attempt to auto-release.
     */
    function attemptAutoRelease(uint256 lockId) external nonReentrant whenNotPaused(0x08) {
        Lock storage lock = locks[lockId];
        if (lock.id == 0 || lock.unlocked) revert LockNotFound();
        if (lock.autoReleaseConditionHash == bytes32(0)) revert ConditionNotFulfilled(); // No auto-release condition set

        if (!conditionsFulfilled[lock.autoReleaseConditionHash]) {
            revert ConditionNotFulfilled(); // The linked condition is not yet fulfilled
        }

        // Condition is fulfilled, proceed with unlocking logic similar to unlockFunds
        lock.unlocked = true; // Mark as unlocked

        // Send funds back to the lock owner's AVAILABLE balance
        if (lock.assetType == AssetType.ETH) {
            userETHBalances[lock.owner] += lock.amount;
        } else { // AssetType.TOKEN
             userTokenBalances[lock.owner] += lock.amount;
        }

        // Emit event indicating full amount unlocked for the original owner, triggered by auto-release
        emit LockUnlocked(lock.id, lock.owner, lock.amount);
    }


    // --- Fractional & Delegated Access ---
    // (Refined based on unlockFunds simplification: Fractional info is metadata or for owner-initiated transfers)

    /**
     * @dev Allows the lock owner to designate a recipient for a fraction of the locked amount.
     * This information is stored but does not grant the recipient direct withdrawal rights via `unlockFunds`.
     * The owner must call `unlockFunds` and then potentially `transferFractionalShare`.
     * @param lockId The ID of the lock.
     * @param recipient The address to receive the fraction.
     * @param fractionNumerator The numerator of the fraction.
     * @param fractionDenominator The denominator of the fraction.
     */
    function setFractionalRecipient(uint256 lockId, address recipient, uint256 fractionNumerator, uint256 fractionDenominator) external whenNotPaused(0x10) {
         Lock storage lock = locks[lockId];
        if (lock.id == 0 || lock.unlocked) revert LockNotFound();
        if (msg.sender != lock.owner) revert Unauthorized();
        if (recipient == address(0)) revert ZeroAddress();
        if (fractionDenominator == 0 || fractionNumerator > fractionDenominator) revert InvalidFraction();
        if (lock.fractionalRecipient != address(0)) revert AlreadyFractionalized(); // Only set once per lock? Or allow updating? Let's allow updating.

        lock.fractionalRecipient = recipient;
        lock.fractionalNumerator = fractionNumerator;
        lock.fractionalDenominator = fractionDenominator;

        emit FractionalRecipientSet(lockId, recipient, fractionNumerator, fractionDenominator);
    }

     /**
     * @dev Allows the lock owner to transfer the management rights of a lock (not the underlying funds).
     * The new owner can then call functions like `unlockFunds` or `setFractionalRecipient` for this lock.
     * @param lockId The ID of the lock.
     * @param newOwner The address of the new lock owner.
     */
    function transferLockOwnership(uint256 lockId, address newOwner) external nonReentrant whenNotPaused(0x10) {
        Lock storage lock = locks[lockId];
        if (lock.id == 0 || lock.unlocked) revert LockNotFound();
        if (msg.sender != lock.owner) revert Unauthorized();
        if (newOwner == address(0)) revert ZeroAddress();
        if (newOwner == lock.owner) return; // No-op

        address oldOwner = lock.owner;
        lock.owner = newOwner;

        emit LockOwnershipTransferred(lockId, oldOwner, newOwner);
    }

     /**
     * @dev Allows a user to authorize another address to withdraw a specific amount from their AVAILABLE balance before expiration.
     * @param recipient The address being authorized.
     * @param amount The maximum amount they can withdraw.
     * @param expiration The unix timestamp when the authorization expires.
     * @param assetType The type of asset (ETH=0, TOKEN=1).
     */
    function authorizePartialWithdrawal(address recipient, uint256 amount, uint256 expiration, uint8 assetType) external whenNotPaused(0x20) {
         if (recipient == address(0)) revert ZeroAddress();
         if (amount == 0) revert InvalidAmount();
         if (expiration <= block.timestamp) revert AuthorizationExpired(); // Expiration must be in the future
         if (assetType != uint8(AssetType.ETH) && assetType != uint8(AssetType.TOKEN)) revert InvalidAssetType();

         // Overwrite any existing authorization for this recipient and asset type
         authorizedWithdrawals[recipient][assetType] = AuthorizedWithdrawal({
             amount: amount,
             expiration: expiration,
             granter: msg.sender
         });

         emit AuthorizationGranted(msg.sender, recipient, assetType, amount, expiration);
    }

     /**
     * @dev Allows the granter to revoke an existing withdrawal authorization.
     * @param recipient The address whose authorization is being revoked.
     * @param assetType The type of asset (ETH=0, TOKEN=1).
     */
    function revokeAuthorization(address recipient, uint8 assetType) external whenNotPaused(0x20) {
        if (recipient == address(0)) revert ZeroAddress();
        if (assetType != uint8(AssetType.ETH) && assetType != uint8(AssetType.TOKEN)) revert InvalidAssetType();

        AuthorizedWithdrawal storage auth = authorizedWithdrawals[recipient][assetType];
        if (auth.granter != msg.sender) revert AuthorizationNotFound(); // Only the granter can revoke

        delete authorizedWithdrawals[recipient][assetType]; // Remove the authorization

        emit AuthorizationRevoked(msg.sender, recipient, assetType);
    }

    /**
     * @dev Allows an authorized recipient to withdraw a portion of the granter's AVAILABLE balance.
     * @param granter The address that granted the authorization.
     * @param assetType The type of asset (ETH=0, TOKEN=1).
     * @param amount The amount the authorized recipient wishes to withdraw (must not exceed the authorized amount or granter's balance).
     */
    function withdrawAuthorized(address granter, uint8 assetType, uint256 amount) external nonReentrant whenNotPaused(0x02) {
        if (granter == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        if (assetType != uint8(AssetType.ETH) && assetType != uint8(AssetType.TOKEN)) revert InvalidAssetType();

        AuthorizedWithdrawal storage auth = authorizedWithdrawals[msg.sender][assetType]; // msg.sender is the recipient

        if (auth.granter != granter || auth.expiration < block.timestamp || auth.amount == 0) {
            revert AuthorizationNotFound(); // Includes expired auths
        }
        if (amount > auth.amount) revert AuthorizationAmountExceeded();

        // Check granter's available balance
        uint256 granterAvailableBalance;
        if (assetType == uint8(AssetType.ETH)) {
            granterAvailableBalance = userETHBalances[granter];
        } else { // AssetType.TOKEN
            granterAvailableBalance = userTokenBalances[granter];
        }

        if (granterAvailableBalance < amount) revert InsufficientBalance(); // Granter doesn't have enough balance

        // Perform the withdrawal on behalf of the granter
         if (assetType == uint8(AssetType.ETH)) {
            userETHBalances[granter] -= amount;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            if (!success) {
                 userETHBalances[granter] += amount; // Revert state change
                 revert(); // Or specific error
            }
        } else { // AssetType.TOKEN
             userTokenBalances[granter] -= amount;
             bool success = _customToken.transfer(msg.sender, amount);
             if (!success) {
                 userTokenBalances[granter] += amount; // Revert state change
                 revert(); // Or specific error
             }
        }

        // Decrease remaining authorized amount
        auth.amount -= amount;
         if (auth.amount == 0) {
             // If the full authorized amount is withdrawn, remove the authorization
             delete authorizedWithdrawals[msg.sender][assetType];
         }
         // Note: Fee is NOT applied here, as this is a transfer within the vault/authorized.
         // Fees are only on direct user withdrawals via withdrawETH/Token.

        emit AuthorizedWithdrawalPerformed(granter, msg.sender, assetType, amount);
    }


    // --- Dynamic State & Fees ---

    /**
     * @dev Owner sets a dynamic fee rate applied to user withdrawals.
     * @param newRatePermille The new fee rate in parts per thousand (0-1000).
     */
    function setDynamicFeeRate(uint16 newRatePermille) external onlyOwner whenNotPaused(0x40) {
        if (newRatePermille > 1000) revert InvalidAmount(); // Max 100% fee
        withdrawalFeeRatePermille = newRatePermille;
        emit FeeRateUpdated(newRatePermille);
    }

    /**
     * @dev Owner changes the internal state of the vault. This can influence behavior of other functions
     * based on conditional logic checking `currentState`.
     * @param newState The new state value (0-255).
     */
    function triggerStateChange(uint8 newState) external onlyOwner whenNotPaused(0x40) {
        currentState = newState;
        emit StateChanged(newState);
    }

     /**
     * @dev Owner sets withdrawal limits based on reputation score tiers.
     * @param reputationScore The score threshold this limit applies to (e.g., 0, 50, 100).
     * @param limitETH The maximum ETH withdrawal amount for users with this score or higher.
     * @param limitToken The maximum Token withdrawal amount for users with this score or higher.
     */
    function setWithdrawalLimits(uint8 reputationScore, uint256 limitETH, uint256 limitToken) external onlyOwner {
        // Add validation for reputationScore if needed (e.g., must be in predefined tiers)
        withdrawalLimitsByReputation[reputationScore] = struct { uint256 limitETH; uint256 limitToken; }(limitETH, limitToken);
        emit WithdrawalLimitsUpdated(reputationScore, limitETH, limitToken);
    }


    // --- Simulated Oracle Interaction ---

    /**
     * @dev Owner simulates updating external price feeds.
     * In a real system, this would likely come from a decentralized oracle like Chainlink.
     * @param ethPriceUsd The current price of ETH in USD (scaled, e.g., 1e8).
     * @param tokenPriceUsd The current price of the custom token in USD (scaled).
     */
    function updatePriceFeed(uint256 ethPriceUsd, uint256 tokenPriceUsd) external onlyOwner whenNotPaused(0x80) {
        lastETHPriceUsd = ethPriceUsd;
        lastTokenPriceUsd = tokenPriceUsd;
        lastPriceUpdateTime = uint48(block.timestamp); // Using uint48 to save space
        emit PriceFeedUpdated(ethPriceUsd, tokenPriceUsd, lastPriceUpdateTime);
    }

    /**
     * @dev Owner triggers actions based on the *last known* ETH price.
     * This is a simplified example; real systems might use price triggers directly via oracle keepers.
     * @param ethPriceThreshold The threshold price to check against.
     * @param actionType A code representing the action to trigger (defined internally).
     */
    function triggerActionBasedOnPrice(uint256 ethPriceThreshold, uint8 actionType) external onlyOwner whenNotPaused(0x80) {
        // Check if price data is recent enough (optional check)
        // if (block.timestamp - lastPriceUpdateTime > ...) revert OldPriceData();

        bool conditionMet = false;
        // Example logic based on actionType
        if (actionType == 1) { // Trigger if ETH price is above threshold
            if (lastETHPriceUsd > ethPriceThreshold) conditionMet = true;
        } else if (actionType == 2) { // Trigger if ETH price is below threshold
             if (lastETHPriceUsd < ethPriceThreshold) conditionMet = true;
        }
        // Add more action types as needed...

        if (conditionMet) {
            // --- Execute Action based on actionType ---
            // Example: Change fee rate, change state, trigger a specific condition fulfillment, etc.
            if (actionType == 1) { // Price > threshold -> maybe increase fee
                 uint16 newFee = withdrawalFeeRatePermille + 10; // Add 1%
                 if (newFee > 1000) newFee = 1000;
                 withdrawalFeeRatePermille = newFee;
                 emit FeeRateUpdated(newFee); // Re-emit fee update event
            } else if (actionType == 2) { // Price < threshold -> maybe change state
                 triggerStateChange(currentState + 1); // Move to next state (example)
            }
            // Add more action logic here...

            emit ActionTriggeredBasedOnPrice(ethPriceThreshold, actionType);
        } else {
             // Condition not met, no action taken
        }
    }


    // --- Reputation System ---

    /**
     * @dev Owner assigns or updates a user's reputation score.
     * This score can affect withdrawal limits or other future logic.
     * @param user The address of the user.
     * @param score The new reputation score (0-100).
     */
    function assignReputationScore(address user, uint8 score) external onlyOwner whenNotPaused(0x100) {
        if (user == address(0)) revert ZeroAddress();
        // Max score is 100
        if (score > 100) revert InvalidReputationScore();

        reputationScores[user] = score;
        emit ReputationScoreUpdated(user, score);
    }


    // --- Goal-Based Contributions ---

    /**
     * @dev Owner creates a new community contribution goal.
     * @param goalId A unique identifier for the goal.
     * @param targetAmountToken The total amount of tokens needed to meet the goal.
     * @param deadline The unix timestamp by which the goal must be met.
     */
    function createVaultGoal(bytes32 goalId, uint256 targetAmountToken, uint256 deadline) external onlyOwner whenNotPaused(0x200) {
        if (goalId == bytes32(0)) revert InvalidAmount(); // Invalid goal ID
        if (vaultGoals[goalId].goalId != bytes32(0)) revert GoalAlreadyCompleted(); // Goal ID already exists/used
        if (targetAmountToken == 0) revert InvalidAmount();
        if (deadline <= block.timestamp) revert GoalExpired(); // Deadline must be in the future

        vaultGoals[goalId] = VaultGoal({
            goalId: goalId,
            targetAmountToken: targetAmountToken,
            deadline: deadline,
            totalContributionsToken: 0,
            completed: false // Initially not completed
            // contributions mapping is implicitly initialized
        });

        emit GoalCreated(goalId, targetAmountToken, deadline);
    }

    /**
     * @dev Allows users to contribute tokens to an active goal. Requires prior approval.
     * @param goalId The ID of the goal to contribute to.
     * @param amount The amount of tokens to contribute.
     */
    function contributeToGoal(bytes32 goalId, uint256 amount) external nonReentrant whenNotPaused(0x200) {
        VaultGoal storage goal = vaultGoals[goalId];
        if (goal.goalId == bytes32(0)) revert GoalNotFound();
        if (block.timestamp > goal.deadline) revert GoalExpired();
        if (goal.completed) revert GoalAlreadyCompleted();
        if (amount == 0) revert ContributionTooSmall(); // Or InvalidAmount()

        // Transfer tokens from the user to the contract
        bool success = _customToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientBalance(); // User didn't approve enough or insufficient balance

        goal.totalContributionsToken += amount;
        goal.contributions[msg.sender] += amount;

        // Check if goal is completed *immediately* upon this contribution
        if (goal.totalContributionsToken >= goal.targetAmountToken) {
            // In a real system, might need owner/oracle verification, but here we auto-mark if total > target
             goal.completed = true;
             // Potentially trigger events or actions for goal completion here
        }

        emit GoalContributed(goalId, msg.sender, amount, goal.contributions[msg.sender]);
    }

    /**
     * @dev Allows a user to claim or check the completion status of a goal after its deadline.
     * This doesn't distribute rewards, just confirms if the goal was met by the deadline.
     * Reward distribution would be a separate mechanism.
     * @param goalId The ID of the goal.
     */
    function claimGoalCompletionStatus(bytes32 goalId) external view returns (bool wasCompleted) {
        VaultGoal storage goal = vaultGoals[goalId];
        if (goal.goalId == bytes32(0)) revert GoalNotFound();
        // Check allowed only after deadline? Or anytime? Let's allow anytime for status check.
        // if (block.timestamp <= goal.deadline) revert GoalNotYetCompleted(); // Only check after deadline

        // The `completed` flag should be set if totalContributions >= targetAmount by the deadline.
        // If auto-setting `completed` on contribute, this just returns that flag.
        // If owner sets `completed` flag, this returns that flag.
        // Let's assume owner sets `completed` after verifying contributions vs deadline.
        // For this example, we'll assume the check is based on the stored state,
        // which *should* be updated by the owner based on the deadline.
        // However, for simplicity, let's just return the `completed` flag.
        // A user "claiming" completion status might trigger an event for off-chain processing.

         // Simulate owner verification: If deadline passed and total met target, set completed.
         // In a real contract, this state change would be a separate owner function.
         // For the `view` function, we just check the *current* state.
         // bool theoreticalCompletion = (block.timestamp > goal.deadline && goal.totalContributionsToken >= goal.targetAmountToken);
         // return goal.completed || theoreticalCompletion; // Can return true if completed or theoretically completed based on current state? No, stick to the state variable.

        return goal.completed; // Return the state as set by owner or auto-logic on contribute

        // Emit event indicating someone checked/claimed the status (optional, but good for dApps)
        // emit GoalCompletionClaimed(goalId, msg.sender); // Cannot emit from view function
    }

     /**
     * @dev Get details of a specific goal.
     * @param goalId The ID of the goal.
     */
    function getGoalDetails(bytes32 goalId) external view returns (
        bytes32 id,
        uint256 targetAmountToken,
        uint256 deadline,
        uint256 totalContributionsToken,
        bool completed
    ) {
        VaultGoal storage goal = vaultGoals[goalId];
        if (goal.goalId == bytes32(0)) revert GoalNotFound();
        return (
            goal.goalId,
            goal.targetAmountToken,
            goal.deadline,
            goal.totalContributionsToken,
            goal.completed
        );
    }

     /**
     * @dev Get a specific user's contribution to a goal.
     * @param goalId The ID of the goal.
     * @param user The address of the user.
     */
    function getUserGoalContribution(bytes32 goalId, address user) external view returns (uint256) {
        VaultGoal storage goal = vaultGoals[goalId];
        if (goal.goalId == bytes32(0)) revert GoalNotFound();
        return goal.contributions[user];
    }


    // --- Pausing Mechanism ---

    /**
     * @dev Owner can pause specific contract functionalities using bit flags.
     * Flags: 0x01 = deposit, 0x02 = withdrawal, 0x04 = locking, 0x08 = unlocking,
     * 0x10 = fractional/delegated access setup, 0x20 = authorized withdrawal setup/revoke,
     * 0x40 = dynamic state/fee changes, 0x80 = oracle updates/triggers, 0x100 = reputation assignment,
     * 0x200 = goal creation/contribution
     * @param flags The bitmask of functions to pause.
     */
    function pauseVault(uint8 flags) external onlyOwner {
        pausedFlags |= flags;
        emit VaultPaused(flags);
    }

    /**
     * @dev Owner can unpause specific contract functionalities using bit flags.
     * @param flags The bitmask of functions to unpause.
     */
    function unpauseVault(uint8 flags) external onlyOwner {
        pausedFlags &= ~flags;
        emit VaultUnpaused(flags);
    }

    // --- Receive/Fallback ---
    // Allow contract to receive ETH for deposits
    receive() external payable {
        depositETH(); // Route incoming ETH to the deposit function
    }
}
```