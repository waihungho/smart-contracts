Okay, let's design a smart contract with a focus on advanced access control mechanisms inspired by potentially future or complex concepts, going beyond standard time-locks and simple multi-sigs. We'll create a "Quantum Vault" that allows locking assets under various sophisticated conditions.

Here's the outline and function summary, followed by the Solidity code.

---

**Contract Name:** `QuantumVault`

**Description:**
A smart contract designed to hold and manage Ether and various ERC20 tokens. It implements multiple sophisticated, potentially simultaneous locking mechanisms for deposited assets, allowing users or predefined recipients to withdraw funds only when specific, advanced conditions are met. The conditions are inspired by concepts like future state simulation, external action dependencies ("entanglement"), and complex conditional logic, alongside more traditional multi-party approvals and time-based releases.

**Outline:**

1.  **State Variables:** Store ownership, allowed tokens, balances (unlocked, locked), lock configurations for each user/asset, global conditions, multi-sig states, etc.
2.  **Events:** Log significant actions like deposits, withdrawals, lock setups, condition changes, lock releases.
3.  **Modifiers:** Access control (`onlyOwner`, `whenShieldInactive`).
4.  **Enums:** Define types of locks.
5.  **Structs:** Define the structure for different lock configurations and states.
6.  **Core Vault Functionality:** Deposit Ether and ERC20 tokens.
7.  **Admin/Configuration:** Add/remove allowed tokens, transfer ownership.
8.  **Global Conditional Flags:** Set and check boolean flags used by conditional locks.
9.  **Lock Setup Functions:** Allow users (or owner, depending on desired architecture - let's allow users to lock *their own* deposited funds) to define specific locking conditions on amounts they deposit or already hold in their unlocked balance.
10. **Lock Action/Release Functions:** Functions called to check if a specific lock condition is met and, if so, move the locked amount to the user's unlocked balance. This separates checking/releasing from withdrawing.
11. **Withdrawal Functions:** Allow users to withdraw from their *unlocked* balance.
12. **Query/View Functions:** Get state information about balances, locks, conditions, etc.

**Function Summary:**

*   **`constructor()`**: Initializes the contract owner.
*   **`depositEther()` (payable)**: Allows anyone to deposit Ether into their unlocked balance.
*   **`depositERC20(address token, uint256 amount)`**: Allows anyone to deposit ERC20 tokens into their unlocked balance.
*   **`addAllowedToken(address token)` (onlyOwner)**: Adds an ERC20 token to the list of allowed tokens.
*   **`removeAllowedToken(address token)` (onlyOwner)**: Removes an ERC20 token from the list of allowed tokens.
*   **`transferOwnership(address newOwner)` (onlyOwner)**: Transfers contract ownership.
*   **`setConditionalFlag(bytes32 conditionId, bool status)` (onlyOwner)**: Sets the status of a global boolean condition flag.
*   **`setupTimedLock(address token, uint256 amount, uint256 unlockTime)`**: Locks a specified amount until a future timestamp. Deducts from user's unlocked balance.
*   **`setupConditionalLock(address token, uint256 amount, bytes32 conditionId)`**: Locks an amount until a specific global conditional flag is true. Deducts from user's unlocked balance.
*   **`setupMultiSigLock(address token, uint256 amount, address[] approvers, uint256 requiredApprovals)`**: Locks an amount requiring N out of M specified approvers. Deducts from user's unlocked balance.
*   **`setupDecayingLock(address token, uint256 totalAmount, uint256 startTime, uint256 endTime)`**: Locks an amount that becomes progressively available over a time period. Deducts from user's unlocked balance.
*   **`setupQuantumSingularityLock(address token, uint256 amount, uint256 targetBlock, int256 requiredValue, address dataFeedAddress)`**: Locks amount until a specific block number is reached and a value from an oracle data feed meets a threshold. Deducts from user's unlocked balance. (Requires Chainlink or similar oracle interface).
*   **`setupEntanglementLock(address token, uint256 amount, address entanglerAddress, uint256 validAfterTime)`**: Locks an amount requiring a specific external address (`entanglerAddress`) to call `signalEntanglement` after a certain time. Deducts from user's unlocked balance.
*   **`setupExternalDepositLock(address token, uint256 amount, address targetContract, address depositToken, uint256 requiredAmount)`**: Locks an amount requiring a minimum deposit of a specific token into another contract. Deducts from user's unlocked balance. (Requires interface to target contract).
*   **`setupPostQuantumRecipientLock(address token, uint256 amount, address recipient, uint256 unlockTime)`**: Locks an amount payable to a specific recipient after a potentially very long time (conceptually, hedging against future tech changes). Deducts from user's unlocked balance.
*   **`checkAndReleaseTimedLock(address token, uint256 lockIndex)`**: Checks if a specific timed lock is met and moves funds to unlocked balance.
*   **`checkAndReleaseConditionalLock(address token, uint256 lockIndex)`**: Checks if a specific conditional lock is met and moves funds.
*   **`initiateMultiSigUnlock(uint256 lockId)`**: Initiates the multi-sig approval process for a lock.
*   **`approveMultiSigUnlock(uint256 lockId)`**: Approves a multi-sig unlock request.
*   **`checkAndReleaseMultiSigLock(uint256 lockId)`**: Checks if required multi-sig approvals are met and moves funds.
*   **`claimDecayingAmount(address token, uint256 lockIndex)`**: Calculates and moves the currently available amount from a decaying lock to unlocked balance.
*   **`checkAndReleaseQuantumSingularityLock(address token, uint256 lockIndex)`**: Checks the oracle/block condition and releases funds if met.
*   **`signalEntanglement(address user, address token, uint256 lockIndex)`**: Called by the designated entangler to signal condition met for a specific lock.
*   **`checkAndReleaseEntanglementLock(address token, uint256 lockIndex)`**: Checks if the entanglement signal is received and releases funds.
*   **`checkAndReleaseExternalDepositLock(address token, uint256 lockIndex)`**: Checks the external contract deposit state and releases funds if met. (Requires interface call).
*   **`releasePostQuantumAsset(address token, uint256 lockIndex)`**: Releases PQ asset to the recipient if unlock time is met.
*   **`withdrawUnlockedEther(uint256 amount)`**: Withdraws Ether from the user's unlocked balance.
*   **`withdrawUnlockedERC20(address token, uint256 amount)`**: Withdraws ERC20 tokens from the user's unlocked balance.
*   **`getUnlockedBalance(address user, address token)` (view)**: Gets the user's currently unlocked balance for a token (0x0 for Ether).
*   **`getLockedBalance(address user, address token)` (view)**: Gets the user's total currently locked balance across all *active* locks for a token.
*   **`getLockDetails(address user, address token, uint256 lockIndex)` (view)**: Gets details of a specific lock entry. (Might return a simplified view struct due to stack limits).
*   **`getMultiSigLockState(uint256 lockId)` (view)**: Gets the current state (approvals, required) of a multi-sig lock.
*   **`getDecayingLockState(address user, address token, uint256 lockIndex)` (view)**: Gets details and calculates currently available amount for a decaying lock.
*   **`checkQuantumSingularityCondition(address user, address token, uint256 lockIndex)` (view)**: Checks *only* the QS condition without releasing.
*   **`checkEntanglementCondition(address user, address token, uint256 lockIndex)` (view)**: Checks *only* the entanglement condition without releasing.
*   **`checkExternalDepositCondition(address user, address token, uint256 lockIndex)` (view)**: Checks *only* the external deposit condition without releasing.
*   **`getPostQuantumLockState(address user, address token, uint256 lockIndex)` (view)**: Gets details of a PQ lock.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Mock Chainlink AggregatorV3Interface for Quantum Singularity Lock
// In a real scenario, you would import the actual Chainlink contract interface
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// Mock Interface for External Deposit Check
// Assumes the target contract has a function like getUserBalance(address user, address token)
interface ExternalDepositCheckInterface {
    function getUserBalance(address user, address token) external view returns (uint256);
}


/**
 * @title QuantumVault
 * @dev A smart contract implementing advanced, multi-conditional locking mechanisms for Ether and ERC20 tokens.
 * Assets can be locked under various rules including time-based, conditional flags, multi-signature,
 * decaying schedules, oracle-dependent future states, external action dependencies, and external contract state checks.
 */
contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // Mapping from user address => token address (0x0 for Ether) => unlocked balance
    mapping(address => mapping(address => uint256)) public unlockedBalances;

    // Mapping from user address => token address (0x0 for Ether) => array of lock states
    mapping(address => mapping(address => LockState[])) public userLocks;

    // List of allowed ERC20 tokens
    mapping(address => bool) public allowedTokens;

    // Global conditional flags (bytes32 id => status)
    mapping(bytes32 => bool) public conditionalFlags;

    // Multi-Sig lock states (lockId => required approvals, approved count)
    mapping(uint256 => MultiSigState) public multiSigLocks;

    // Multi-Sig approval tracking (lockId => approver address => approved)
    mapping(uint256 => mapping(address => bool)) public multiSigApprovals;

    // Entanglement signal tracking (user => token => lock index => signaled)
    mapping(address => mapping(address => mapping(uint256 => bool))) public entanglementSignaled;

    // Counter for unique Multi-Sig lock IDs
    uint256 private nextMultiSigLockId = 1;

    // --- Structs and Enums ---

    enum LockType {
        None,
        Timed,
        Conditional,
        MultiSig,
        Decaying,
        QuantumSingularity,
        Entanglement,
        ExternalDeposit,
        PostQuantumRecipient
    }

    struct LockState {
        LockType lockType;
        uint256 amount; // The amount locked by this specific state
        bool isActive; // true if the lock condition is currently active

        // Parameters for different lock types
        uint256 unlockTime; // Used by Timed, PostQuantumRecipient
        bytes32 conditionId; // Used by Conditional
        uint256 multiSigLockId; // Used by MultiSig (links to multiSigLocks mapping)
        uint256 startTime; // Used by Decaying
        uint256 endTime; // Used by Decaying
        uint256 targetBlock; // Used by QuantumSingularity
        int256 requiredValue; // Used by QuantumSingularity
        address dataFeedAddress; // Used by QuantumSingularity (AggregatorV3Interface)
        address entanglerAddress; // Used by Entanglement
        uint256 validAfterTime; // Used by Entanglement
        address targetContract; // Used by ExternalDeposit (ExternalDepositCheckInterface)
        address depositToken; // Used by ExternalDeposit
        uint256 requiredAmount; // Used by ExternalDeposit
        address recipient; // Used by PostQuantumRecipient
    }

    struct MultiSigState {
        uint256 requiredApprovals;
        uint256 approvedCount;
        address[] approvers;
        bool exists; // To check if a lockId is valid
        // Note: Does NOT store amount or token here to avoid redundancy; that's in LockState
    }


    // --- Events ---

    event EtherDeposited(address indexed user, uint256 amount);
    event TokenDeposited(address indexed user, address indexed token, uint256 amount);
    event EtherWithdrawn(address indexed user, uint256 amount);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event ConditionalFlagSet(bytes32 indexed conditionId, bool status);
    event LockSetup(address indexed user, address indexed token, uint256 amount, uint256 lockIndex, LockType lockType);
    event LockReleased(address indexed user, address indexed token, uint256 amount, uint256 lockIndex, LockType lockType);
    event MultiSigInitiated(uint256 indexed lockId, address indexed initiator);
    event MultiSigApproved(uint256 indexed lockId, address indexed approver);
    event EntanglementSignaled(address indexed user, address indexed token, uint256 indexed lockIndex, address indexed entangler);
    event PostQuantumAssetReleased(address indexed user, address indexed token, uint256 amount, address indexed recipient, uint256 lockIndex);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Modifiers ---
    // No custom modifiers needed yet beyond Ownable and ReentrancyGuard


    // --- Core Vault Functionality ---

    /**
     * @dev Deposits Ether into the sender's unlocked balance.
     */
    receive() external payable nonReentrant {
        unlockedBalances[msg.sender][address(0)] += msg.value;
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Deposits ERC20 tokens into the sender's unlocked balance.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external nonReentrant {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Amount must be > 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        unlockedBalances[msg.sender][token] += amount;
        emit TokenDeposited(msg.sender, token, amount);
    }

    // --- Admin/Configuration ---

    /**
     * @dev Adds an ERC20 token to the list of allowed tokens. Only owner can call.
     * @param token The address of the ERC20 token.
     */
    function addAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        allowedTokens[token] = true;
        emit AllowedTokenAdded(token);
    }

    /**
     * @dev Removes an ERC20 token from the list of allowed tokens. Only owner can call.
     * Assets of this token remain in the vault but new deposits are blocked.
     * @param token The address of the ERC20 token.
     */
    function removeAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        allowedTokens[token] = false;
        emit AllowedTokenRemoved(token);
    }

    // transferOwnership is inherited from Ownable

    // --- Global Conditional Flags ---

    /**
     * @dev Sets the status of a global boolean condition flag.
     * These flags can be used by Conditional Locks. Only owner can call.
     * @param conditionId A unique identifier for the condition flag (e.g., keccak256("MarketConditionMet")).
     * @param status The boolean status to set for the flag.
     */
    function setConditionalFlag(bytes32 conditionId, bool status) external onlyOwner {
        conditionalFlags[conditionId] = status;
        emit ConditionalFlagSet(conditionId, status);
    }

    /**
     * @dev Checks the current status of a global conditional flag.
     * @param conditionId The unique identifier for the condition flag.
     * @return The boolean status of the flag.
     */
    function isConditionalFlagSet(bytes32 conditionId) external view returns (bool) {
        return conditionalFlags[conditionId];
    }

    // --- Lock Setup Functions (User Calls) ---

    /**
     * @dev Sets up a timed lock on a specified amount of a user's unlocked balance.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to lock.
     * @param unlockTime The Unix timestamp when the amount becomes available.
     */
    function setupTimedLock(address token, uint256 amount, uint256 unlockTime) external nonReentrant {
        _decreaseUnlockedBalance(msg.sender, token, amount);
        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.Timed,
            amount: amount,
            isActive: true,
            unlockTime: unlockTime,
            conditionId: bytes32(0), // Not used
            multiSigLockId: 0, // Not used
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.Timed);
    }

    /**
     * @dev Sets up a conditional lock based on a global flag.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to lock.
     * @param conditionId The ID of the global boolean flag required to be true.
     */
    function setupConditionalLock(address token, uint256 amount, bytes32 conditionId) external nonReentrant {
        _decreaseUnlockedBalance(msg.sender, token, amount);
        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.Conditional,
            amount: amount,
            isActive: true,
            unlockTime: 0, // Not used
            conditionId: conditionId,
            multiSigLockId: 0, // Not used
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.Conditional);
    }

    /**
     * @dev Sets up a multi-signature lock.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to lock.
     * @param approvers Addresses allowed to approve the release.
     * @param requiredApprovals The number of approvals required.
     * @return The unique ID generated for this multi-sig lock.
     */
    function setupMultiSigLock(address token, uint256 amount, address[] memory approvers, uint256 requiredApprovals) external nonReentrant returns (uint256) {
        require(approvers.length > 0, "Must provide approvers");
        require(requiredApprovals > 0 && requiredApprovals <= approvers.length, "Invalid required approvals");
        require(amount > 0, "Amount must be > 0");

        _decreaseUnlockedBalance(msg.sender, token, amount);

        uint256 lockId = nextMultiSigLockId++;
        multiSigLocks[lockId] = MultiSigState({
            requiredApprovals: requiredApprovals,
            approvedCount: 0,
            approvers: approvers,
            exists: true
        });

        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.MultiSig,
            amount: amount,
            isActive: true,
            unlockTime: 0, // Not used
            conditionId: bytes32(0), // Not used
            multiSigLockId: lockId,
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.MultiSig);
        return lockId;
    }

    /**
     * @dev Sets up a decaying lock where the amount becomes available gradually over time.
     * @param token The address of the token (0x0 for Ether).
     * @param totalAmount The total amount that will eventually be released.
     * @param startTime The Unix timestamp when decay starts.
     * @param endTime The Unix timestamp when decay is complete and full amount is available.
     */
    function setupDecayingLock(address token, uint256 totalAmount, uint256 startTime, uint256 endTime) external nonReentrant {
        require(endTime > startTime, "End time must be after start time");
        require(totalAmount > 0, "Amount must be > 0");

        _decreaseUnlockedBalance(msg.sender, token, totalAmount); // Lock the total amount upfront

        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.Decaying,
            amount: totalAmount, // Total amount initially locked
            isActive: true,
            unlockTime: 0, // Not used
            conditionId: bytes32(0), // Not used
            multiSigLockId: 0, // Not used
            startTime: startTime,
            endTime: endTime,
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, totalAmount, userLocks[msg.sender][token].length - 1, LockType.Decaying);
    }

    /**
     * @dev Sets up a Quantum Singularity Lock, dependent on a future block and an oracle value.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to lock.
     * @param targetBlock The block number at which the condition can be checked.
     * @param requiredValue The minimum (or maximum, depending on context) oracle value required.
     * @param dataFeedAddress The address of the oracle data feed (AggregatorV3Interface).
     */
    function setupQuantumSingularityLock(address token, uint256 amount, uint256 targetBlock, int256 requiredValue, address dataFeedAddress) external nonReentrant {
         require(targetBlock > block.number, "Target block must be in the future");
         // Further validation on dataFeedAddress could be added (e.g., check interface)

        _decreaseUnlockedBalance(msg.sender, token, amount);

        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.QuantumSingularity,
            amount: amount,
            isActive: true,
            unlockTime: 0, // Not used
            conditionId: bytes32(0), // Not used
            multiSigLockId: 0, // Not used
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: targetBlock,
            requiredValue: requiredValue,
            dataFeedAddress: dataFeedAddress,
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.QuantumSingularity);
    }

    /**
     * @dev Sets up an Entanglement Lock, requiring an external address to signal after a time.
     * The `entanglerAddress` must call `signalEntanglement`.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to lock.
     * @param entanglerAddress The address whose signal is required.
     * @param validAfterTime The Unix timestamp after which the signal is valid.
     */
    function setupEntanglementLock(address token, uint256 amount, address entanglerAddress, uint256 validAfterTime) external nonReentrant {
        require(entanglerAddress != address(0), "Entangler address cannot be zero");

        _decreaseUnlockedBalance(msg.sender, token, amount);

        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.Entanglement,
            amount: amount,
            isActive: true,
            unlockTime: 0, // Not used
            conditionId: bytes32(0), // Not used
            multiSigLockId: 0, // Not used
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: entanglerAddress,
            validAfterTime: validAfterTime,
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.Entanglement);
    }

    /**
     * @dev Sets up an External Deposit Lock, requiring a minimum deposit in another contract.
     * @param token The address of the token in THIS vault (0x0 for Ether).
     * @param amount The amount in THIS vault to lock.
     * @param targetContract The address of the external contract to check.
     * @param depositToken The address of the token expected in the target contract check.
     * @param requiredAmount The minimum balance required for the user in the target contract.
     */
    function setupExternalDepositLock(address token, uint256 amount, address targetContract, address depositToken, uint256 requiredAmount) external nonReentrant {
        require(targetContract != address(0), "Target contract cannot be zero");
        require(depositToken != address(0), "Deposit token cannot be zero");
        require(requiredAmount > 0, "Required amount must be > 0");

        _decreaseUnlockedBalance(msg.sender, token, amount);

        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.ExternalDeposit,
            amount: amount,
            isActive: true,
            unlockTime: 0, // Not used
            conditionId: bytes32(0), // Not used
            multiSigLockId: 0, // Not used
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: targetContract,
            depositToken: depositToken,
            requiredAmount: requiredAmount,
            recipient: address(0) // Not used
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.ExternalDeposit);
    }

    /**
     * @dev Sets up a Post-Quantum Recipient Lock, payable to a different address after a long time.
     * This is more conceptual, anticipating scenarios far in the future.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to lock.
     * @param recipient The address that can claim the funds after unlockTime.
     * @param unlockTime The future timestamp when the recipient can claim.
     */
    function setupPostQuantumRecipientLock(address token, uint256 amount, address recipient, uint256 unlockTime) external nonReentrant {
        require(recipient != address(0), "Recipient address cannot be zero");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");
        // Maybe add a check for a very long time horizon: require(unlockTime > block.timestamp + 365 days * 100, "Must be a long-term lock");

        _decreaseUnlockedBalance(msg.sender, token, amount);

        userLocks[msg.sender][token].push(LockState({
            lockType: LockType.PostQuantumRecipient,
            amount: amount,
            isActive: true,
            unlockTime: unlockTime,
            conditionId: bytes32(0), // Not used
            multiSigLockId: 0, // Not used
            startTime: 0, // Not used
            endTime: 0, // Not used
            targetBlock: 0, // Not used
            requiredValue: 0, // Not used
            dataFeedAddress: address(0), // Not used
            entanglerAddress: address(0), // Not used
            validAfterTime: 0, // Not used
            targetContract: address(0), // Not used
            depositToken: address(0), // Not used
            requiredAmount: 0, // Not used
            recipient: recipient
        }));
        emit LockSetup(msg.sender, token, amount, userLocks[msg.sender][token].length - 1, LockType.PostQuantumRecipient);
    }


    // --- Lock Action/Release Functions ---
    // These functions check a specific lock condition and move funds to unlocked balance if met.

    /**
     * @dev Checks if a specific Timed Lock is met and releases the funds to the user's unlocked balance.
     * Anyone can call this to potentially trigger the release for a user.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock in the user's lock array for this token.
     */
    function checkAndReleaseTimedLock(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.Timed);
        require(lock.isActive, "Lock is not active");
        require(block.timestamp >= lock.unlockTime, "Unlock time has not been reached");

        lock.isActive = false;
        unlockedBalances[msg.sender][token] += lock.amount;
        emit LockReleased(msg.sender, token, lock.amount, lockIndex, LockType.Timed);
    }

     /**
     * @dev Checks if a specific Conditional Lock is met and releases the funds.
     * Anyone can call this.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function checkAndReleaseConditionalLock(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.Conditional);
        require(lock.isActive, "Lock is not active");
        require(conditionalFlags[lock.conditionId], "Condition is not met");

        lock.isActive = false;
        unlockedBalances[msg.sender][token] += lock.amount;
        emit LockReleased(msg.sender, token, lock.amount, lockIndex, LockType.Conditional);
    }

    /**
     * @dev Initiates the multi-signature approval process for a specific lock ID.
     * The lock creator or an approver might call this (design choice - let's say creator or any approver).
     * @param lockId The ID of the multi-sig lock.
     */
    function initiateMultiSigUnlock(uint256 lockId) external {
        MultiSigState storage msState = multiSigLocks[lockId];
        require(msState.exists, "Invalid multi-sig lock ID");
        // Optional: Add requirement that caller is owner or an approver
        bool isApprover = false;
        for(uint i = 0; i < msState.approvers.length; i++) {
            if (msState.approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
         require(isApprover, "Only approvers can initiate multi-sig unlock"); // Or require owner/creator

        // State change is just the event for initiation
        emit MultiSigInitiated(lockId, msg.sender);
    }


    /**
     * @dev Approves a multi-signature unlock request for a specific lock ID.
     * Only designated approvers can call this.
     * @param lockId The ID of the multi-sig lock.
     */
    function approveMultiSigUnlock(uint256 lockId) external nonReentrant {
        MultiSigState storage msState = multiSigLocks[lockId];
        require(msState.exists, "Invalid multi-sig lock ID");
        require(!multiSigApprovals[lockId][msg.sender], "Already approved");

        bool isApprover = false;
        for(uint i = 0; i < msState.approvers.length; i++) {
            if (msState.approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
        require(isApprover, "Not an approver");

        multiSigApprovals[lockId][msg.sender] = true;
        msState.approvedCount++;

        emit MultiSigApproved(lockId, msg.sender);

        // Optional: Automatically check and release if threshold is met
        // checkAndReleaseMultiSigLock(lockId); // Could call here, but better to let user call explicitly for gas control
    }

    /**
     * @dev Checks if the required number of multi-signature approvals are met and releases the funds.
     * Anyone can call this to trigger the release if approvals are sufficient.
     * @param lockId The ID of the multi-sig lock.
     */
    function checkAndReleaseMultiSigLock(uint256 lockId) external nonReentrant {
        MultiSigState storage msState = multiSigLocks[lockId];
        require(msState.exists, "Invalid multi-sig lock ID");
        require(msState.approvedCount >= msState.requiredApprovals, "Required approvals not met");

        // Find the lock state entry linked to this multiSigLockId
        address user;
        address token;
        uint256 lockIndex = type(uint256).max; // Placeholder for not found

        // Need to iterate through all user locks to find the one linked to this multiSigLockId
        // This can be gas intensive if a user has many locks.
        // A better design might map lockId directly to (user, token, lockIndex).
        // For simplicity here, we iterate.
        bool found = false;
        // This is highly inefficient. In a real contract, map lockId => {user, token, lockIndex}
        // For demonstration purposes, leaving it simple but noting inefficiency.
        // Alternative: Require user/token/lockIndex as params?
        // Let's require user/token/lockIndex for efficiency.
        revert("checkAndReleaseMultiSigLock requires user, token, lockIndex parameters for efficiency.");
        // Let's add a version that requires these parameters:
    }

    /**
     * @dev Checks if the required number of multi-signature approvals are met and releases the funds
     * for a specific lock identified by user, token, and index.
     * Anyone can call this to trigger the release if approvals are sufficient.
     * @param user The user who owns the lock.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the multi-sig lock in the user's lock array for this token.
     */
     function checkAndReleaseMultiSigLock(address user, address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(user, token, lockIndex, LockType.MultiSig);
        require(lock.isActive, "Lock is not active");

        MultiSigState storage msState = multiSigLocks[lock.multiSigLockId];
        require(msState.exists, "Invalid linked multi-sig state"); // Should not happen if LockState is valid
        require(msState.approvedCount >= msState.requiredApprovals, "Required multi-sig approvals not met");

        lock.isActive = false;
        unlockedBalances[user][token] += lock.amount;
        emit LockReleased(user, token, lock.amount, lockIndex, LockType.MultiSig);
        // Optional: Clean up MultiSigState? Mark as completed?
     }


    /**
     * @dev Calculates and claims the available amount from a Decaying Lock.
     * Anyone can call this to claim for a user.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function claimDecayingAmount(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.Decaying);
        require(lock.isActive, "Lock is not active or fully claimed");

        uint256 availableAmount = getDecayingAmountAvailable(lock);
        require(availableAmount > 0, "No amount available to claim yet");

        // Calculate the amount already claimed from this lock
        // Need a way to track claimed amount per decaying lock
        // This requires modifying LockState or adding another mapping.
        // Let's add a claimedAmount field to the LockState struct for Decaying locks.
        // (Note: Modifying struct requires migration in production)
        // Assuming LockState has `claimedAmount` field for Decaying locks.
        // This demo doesn't have `claimedAmount` due to aiming for simplicity.
        // A simpler way *without* `claimedAmount`: calculate total available,
        // and move the *entire* currently available amount to unlocked,
        // then update the lock's `amount` to the *remaining* locked amount.
        // This treats `amount` as the *remaining* locked amount, not the total.
        // Let's recalculate `getDecayingAmountAvailable` to return the *total* available *so far*.
        // The user's unlocked balance implicitly tracks what they *have* claimed.
        // A better approach: The `amount` in LockState *is* the total.
        // We need a separate way to track how much of that `amount` has moved to unlocked.
        // Add `releasedAmount` to LockState? Or a separate mapping `mapping(address => mapping(address => mapping(uint256 => uint256))) public decayingLockReleasedAmount;`
        // Let's use a separate mapping for simplicity in this draft, but note the complexity.

        // Assume a mapping: `mapping(address => mapping(address => mapping(uint256 => uint256))) public decayingLockClaimedAmount;`
        // Add this mapping declaration above.

        uint256 totalAvailableNow = getDecayingAmountAvailable(lock); // Total amount that *should* be unlocked by now
        uint256 alreadyClaimed = decayingLockClaimedAmount[msg.sender][token][lockIndex];
        uint256 amountToRelease = totalAvailableNow - alreadyClaimed;

        require(amountToRelease > 0, "No new amount available to claim");

        // Move funds from conceptually 'locked' within this entry to 'unlockedBalances'
        // Note: The *actual* funds are already in the contract. This is a state update.
        // The initial `setupDecayingLock` moved the funds *from* unlocked.
        // This function moves them back *to* unlocked.
        unlockedBalances[msg.sender][token] += amountToRelease;
        decayingLockClaimedAmount[msg.sender][token][lockIndex] += amountToRelease;

        // Mark as inactive if fully claimed
        if (decayingLockClaimedAmount[msg.sender][token][lockIndex] >= lock.amount) {
             lock.isActive = false;
             emit LockReleased(msg.sender, token, lock.amount, lockIndex, LockType.Decaying); // Emit total amount when fully released
        } else {
            // Emit only the claimed portion if not fully released
            emit LockReleased(msg.sender, token, amountToRelease, lockIndex, LockType.Decaying);
        }
    }

    /**
     * @dev Checks if the Quantum Singularity Lock condition is met and releases funds.
     * Uses a mock oracle interface. Anyone can call this.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function checkAndReleaseQuantumSingularityLock(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.QuantumSingularity);
        require(lock.isActive, "Lock is not active");
        require(block.number >= lock.targetBlock, "Target block not reached");

        // Check oracle value
        AggregatorV3Interface priceFeed = AggregatorV3Interface(lock.dataFeedAddress);
        (, int256 latestValue, , , ) = priceFeed.latestRoundData();

        // Example condition: latestValue must be >= requiredValue
        require(latestValue >= lock.requiredValue, "Oracle value condition not met");
        // More complex oracle conditions could be implemented here

        lock.isActive = false;
        unlockedBalances[msg.sender][token] += lock.amount;
        emit LockReleased(msg.sender, token, lock.amount, lockIndex, LockType.QuantumSingularity);
    }

     /**
     * @dev Called by the designated `entanglerAddress` to signal the condition is met.
     * This function itself doesn't release funds, only updates state.
     * @param user The user who owns the lock.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function signalEntanglement(address user, address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(user, token, lockIndex, LockType.Entanglement);
        require(lock.isActive, "Lock is not active");
        require(msg.sender == lock.entanglerAddress, "Not the designated entangler");
        require(block.timestamp >= lock.validAfterTime, "Signal time not yet valid");

        entanglementSignaled[user][token][lockIndex] = true;
        emit EntanglementSignaled(user, token, lockIndex, msg.sender);

        // Optional: Automatically check and release after signaling
        // checkAndReleaseEntanglementLock(token, lockIndex); // Could call here
    }

    /**
     * @dev Checks if the Entanglement Lock condition is met (signal received after time) and releases funds.
     * Anyone can call this.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function checkAndReleaseEntanglementLock(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.Entanglement);
        require(lock.isActive, "Lock is not active");
        require(entanglementSignaled[msg.sender][token][lockIndex], "Entanglement signal not received");
         // Valid After Time check is done during signalEntanglement, but could add redundancy here:
         // require(block.timestamp >= lock.validAfterTime, "Signal time was not yet valid");

        lock.isActive = false;
        unlockedBalances[msg.sender][token] += lock.amount;
        emit LockReleased(msg.sender, token, lock.amount, lockIndex, LockType.Entanglement);
    }

     /**
     * @dev Checks if the External Deposit Lock condition is met using an external contract view function.
     * Anyone can call this. Requires the target contract implements `getUserBalance(address user, address token)`.
     * @param token The address of the token in THIS vault (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function checkAndReleaseExternalDepositLock(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.ExternalDeposit);
        require(lock.isActive, "Lock is not active");

        ExternalDepositCheckInterface targetContract = ExternalDepositCheckInterface(lock.targetContract);
        uint256 userExternalBalance = targetContract.getUserBalance(msg.sender, lock.depositToken);

        require(userExternalBalance >= lock.requiredAmount, "External deposit condition not met");

        lock.isActive = false;
        unlockedBalances[msg.sender][token] += lock.amount;
        emit LockReleased(msg.sender, token, lock.amount, lockIndex, LockType.ExternalDeposit);
    }

    /**
     * @dev Releases funds from a Post-Quantum Recipient Lock to the designated recipient if the time is met.
     * Only the designated recipient can call this.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     */
    function releasePostQuantumAsset(address token, uint256 lockIndex) external nonReentrant {
        LockState storage lock = _getLockState(msg.sender, token, lockIndex, LockType.PostQuantumRecipient);
        require(lock.isActive, "Lock is not active");
        require(msg.sender == lock.recipient, "Only the designated recipient can release this lock");
        require(block.timestamp >= lock.unlockTime, "Unlock time has not been reached");

        lock.isActive = false;
        // Transfer directly to the recipient, not to unlockedBalances
        _transferAsset(lock.recipient, token, lock.amount);

        emit PostQuantumAssetReleased(msg.sender, token, lock.amount, lock.recipient, lockIndex);
        // Note: Funds are directly transferred, not added to the user's unlocked balance in *this* contract.
    }


    // --- Withdrawal Functions (From unlocked balance) ---

    /**
     * @dev Withdraws Ether from the user's unlocked balance.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawUnlockedEther(uint256 amount) external nonReentrant {
        _decreaseUnlockedBalance(msg.sender, address(0), amount);
        // The actual transfer is handled by _decreaseUnlockedBalance for Ether
        emit EtherWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Withdraws ERC20 tokens from the user's unlocked balance.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawUnlockedERC20(address token, uint256 amount) external nonReentrant {
         _decreaseUnlockedBalance(msg.sender, token, amount);
        // The actual transfer is handled by _decreaseUnlockedBalance for ERC20
        emit TokenWithdrawn(msg.sender, token, amount);
    }


    // --- Query/View Functions ---

    /**
     * @dev Gets the user's currently unlocked balance for a token.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @return The unlocked balance.
     */
    function getUnlockedBalance(address user, address token) external view returns (uint256) {
        return unlockedBalances[user][token];
    }

    /**
     * @dev Gets the user's total currently locked balance across all *active* locks for a token.
     * Note: This iterates through all locks, gas cost depends on number of locks.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @return The total locked balance in active locks.
     */
    function getLockedBalance(address user, address token) external view returns (uint256) {
        uint256 totalLocked = 0;
        for (uint256 i = 0; i < userLocks[user][token].length; i++) {
            if (userLocks[user][token][i].isActive) {
                // Special case for Decaying lock: only count the *remaining* locked amount
                if (userLocks[user][token][i].lockType == LockType.Decaying) {
                    uint256 totalAmount = userLocks[user][token][i].amount;
                    uint256 claimedAmount = decayingLockClaimedAmount[user][token][i];
                    if (totalAmount > claimedAmount) {
                         totalLocked += (totalAmount - claimedAmount);
                    }
                } else {
                     totalLocked += userLocks[user][token][i].amount;
                }
            }
        }
        return totalLocked;
    }

     /**
     * @dev Gets details of a specific lock entry.
     * Note: Returns a simplified representation to avoid stack limits/complex types.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock in the user's lock array.
     * @return lockType The type of lock (enum as uint).
     * @return amount The initial amount placed in the lock.
     * @return isActive Whether the lock is still active.
     * @return params A bytes array containing type-specific parameters (encoding varies by type).
     */
    function getLockDetails(address user, address token, uint256 lockIndex) external view returns (uint8 lockType, uint256 amount, bool isActive, bytes memory params) {
        require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];

        lockType = uint8(lock.lockType);
        amount = lock.amount;
        isActive = lock.isActive;

        // Encode type-specific parameters
        if (lock.lockType == LockType.Timed) {
            params = abi.encode(lock.unlockTime);
        } else if (lock.lockType == LockType.Conditional) {
            params = abi.encode(lock.conditionId);
        } else if (lock.lockType == LockType.MultiSig) {
             params = abi.encode(lock.multiSigLockId);
        } else if (lock.lockType == LockType.Decaying) {
             params = abi.encode(lock.startTime, lock.endTime, decayingLockClaimedAmount[user][token][lockIndex]);
        } else if (lock.lockType == LockType.QuantumSingularity) {
             params = abi.encode(lock.targetBlock, lock.requiredValue, lock.dataFeedAddress);
        } else if (lock.lockType == LockType.Entanglement) {
             params = abi.encode(lock.entanglerAddress, lock.validAfterTime, entanglementSignaled[user][token][lockIndex]);
        } else if (lock.lockType == LockType.ExternalDeposit) {
             params = abi.encode(lock.targetContract, lock.depositToken, lock.requiredAmount);
        } else if (lock.lockType == LockType.PostQuantumRecipient) {
             params = abi.encode(lock.recipient, lock.unlockTime);
        } else {
            params = ""; // No specific params or unknown type
        }

        return (lockType, amount, isActive, params);
    }


     /**
     * @dev Gets the current state of a multi-sig lock.
     * @param lockId The ID of the multi-sig lock.
     * @return requiredApprovals The number of required approvals.
     * @return approvedCount The number of approvals received so far.
     * @return approvers The list of approver addresses.
     * @return exists True if the lockId is valid.
     */
    function getMultiSigLockState(uint256 lockId) external view returns (uint256 requiredApprovals, uint256 approvedCount, address[] memory approvers, bool exists) {
        MultiSigState storage msState = multiSigLocks[lockId];
        return (msState.requiredApprovals, msState.approvedCount, msState.approvers, msState.exists);
    }

    /**
     * @dev Gets details and calculates currently available amount for a decaying lock.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     * @return totalAmount The total amount originally locked.
     * @return startTime The decay start time.
     * @return endTime The decay end time.
     * @return availableNow The amount currently available to claim.
     * @return claimedAmount The amount already claimed from this lock.
     */
    function getDecayingLockState(address user, address token, uint256 lockIndex) external view returns (uint256 totalAmount, uint256 startTime, uint256 endTime, uint256 availableNow, uint256 claimedAmount) {
        require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];
        require(lock.lockType == LockType.Decaying, "Lock is not a Decaying lock");

        totalAmount = lock.amount;
        startTime = lock.startTime;
        endTime = lock.endTime;
        claimedAmount = decayingLockClaimedAmount[user][token][lockIndex];

        availableNow = getDecayingAmountAvailable(lock);

        return (totalAmount, startTime, endTime, availableNow, claimedAmount);
    }

    /**
     * @dev Helper function to calculate the amount available from a decaying lock at the current time.
     * @param lock The Decaying LockState struct.
     * @return The total amount available from this lock up to now.
     */
    function getDecayingAmountAvailable(LockState storage lock) internal view returns (uint256) {
        if (block.timestamp < lock.startTime) {
            return 0;
        }
        if (block.timestamp >= lock.endTime) {
            return lock.amount; // Full amount available
        }

        // Linear decay calculation
        uint256 totalDuration = lock.endTime - lock.startTime;
        uint256 elapsedDuration = block.timestamp - lock.startTime;

        // Use 18 decimals for precision, similar to ERC20.
        // (elapsedDuration * lock.amount) / totalDuration
        // Need to handle potential overflow if amount is very large. Use multiplication before division carefully.
        // Consider using a fixed-point math library for production.
        // For simplicity, standard Solidity uint256 multiplication is used here, which *could* overflow.
        // A safer calculation: (lock.amount / totalDuration) * elapsedDuration + remainder_handling
        // Or better: (lock.amount * elapsedDuration) / totalDuration if intermediate product doesn't overflow.
        // If `lock.amount` is uint256 max, this will overflow. Let's assume typical amounts fit.
        // For safety, could cap total amount or use a library.

        // Example safer division structure if Intermediate is UQ128x128 or similar:
        // return uint256((uint256(lock.amount) * elapsedDuration) / totalDuration);

        // Simple version (potential overflow if lock.amount * elapsedDuration is > uint256 max):
        return (lock.amount * elapsedDuration) / totalDuration;
    }


    /**
     * @dev Checks only the Quantum Singularity Lock condition without attempting release.
     * Useful for UI or pre-checking. Requires mock oracle interface.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     * @return true if the condition is met, false otherwise.
     */
    function checkQuantumSingularityCondition(address user, address token, uint256 lockIndex) external view returns (bool) {
        require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];
        require(lock.lockType == LockType.QuantumSingularity, "Lock is not a Quantum Singularity lock");

        if (!lock.isActive) return false;
        if (block.number < lock.targetBlock) return false;

        // Check oracle value
        AggregatorV3Interface priceFeed = AggregatorV3Interface(lock.dataFeedAddress);
        (, int256 latestValue, , , ) = priceFeed.latestRoundData();

        // Example condition: latestValue must be >= requiredValue
        return latestValue >= lock.requiredValue;
    }

     /**
     * @dev Checks only the Entanglement Lock condition without attempting release.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     * @return true if the condition is met, false otherwise.
     */
    function checkEntanglementCondition(address user, address token, uint256 lockIndex) external view returns (bool) {
        require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];
        require(lock.lockType == LockType.Entanglement, "Lock is not an Entanglement lock");

        if (!lock.isActive) return false;
        // Condition is signaled AND after valid time
        return entanglementSignaled[user][token][lockIndex] && block.timestamp >= lock.validAfterTime;
    }


    /**
     * @dev Checks only the External Deposit Lock condition without attempting release.
     * Requires mock interface for the target contract.
     * @param user The user address.
     * @param token The address of the token in THIS vault (0x0 for Ether).
     * @param lockIndex The index of the lock.
     * @return true if the condition is met, false otherwise.
     */
    function checkExternalDepositCondition(address user, address token, uint256 lockIndex) external view returns (bool) {
        require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];
        require(lock.lockType == LockType.ExternalDeposit, "Lock is not an External Deposit lock");

        if (!lock.isActive) return false;

        ExternalDepositCheckInterface targetContract = ExternalDepositCheckInterface(lock.targetContract);
        // This view function might fail if the external contract call reverts! Handle in production.
        uint256 userExternalBalance = targetContract.getUserBalance(user, lock.depositToken);

        return userExternalBalance >= lock.requiredAmount;
    }

     /**
     * @dev Gets details of a Post-Quantum Recipient lock.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     * @return recipient The recipient address.
     * @return unlockTime The unlock timestamp.
     * @return amount The amount locked.
     * @return isActive Whether the lock is active.
     */
    function getPostQuantumLockState(address user, address token, uint256 lockIndex) external view returns (address recipient, uint256 unlockTime, uint256 amount, bool isActive) {
         require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];
        require(lock.lockType == LockType.PostQuantumRecipient, "Lock is not a Post-Quantum Recipient lock");
        return (lock.recipient, lock.unlockTime, lock.amount, lock.isActive);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Decreases a user's unlocked balance and handles Ether withdrawal.
     * @param user The user address.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to decrease/withdraw.
     */
    function _decreaseUnlockedBalance(address user, address token, uint256 amount) internal {
        require(unlockedBalances[user][token] >= amount, "Insufficient unlocked balance");
        unlockedBalances[user][token] -= amount;

        if (token == address(0) && amount > 0) {
            // Handle Ether withdrawal
             (bool success, ) = payable(user).call{value: amount}("");
             require(success, "Ether withdrawal failed");
        } else if (token != address(0) && amount > 0) {
            // Handle ERC20 withdrawal (transfer from contract to user)
             IERC20(token).safeTransfer(user, amount);
        }
        // If amount is 0, no transfer needed, just balance update
    }

     /**
     * @dev Transfers asset (Ether or ERC20) directly to a recipient.
     * Used by PostQuantumRecipient lock.
     * @param recipient The address to transfer to.
     * @param token The address of the token (0x0 for Ether).
     * @param amount The amount to transfer.
     */
     function _transferAsset(address recipient, address token, uint256 amount) internal {
         require(amount > 0, "Transfer amount must be > 0");
         if (token == address(0)) {
             (bool success, ) = payable(recipient).call{value: amount}("");
             require(success, "Ether transfer failed");
         } else {
             IERC20(token).safeTransfer(recipient, amount);
         }
     }


    /**
     * @dev Helper to get a specific lock state and validate its type and ownership.
     * @param user The user address expected to own the lock.
     * @param token The address of the token (0x0 for Ether).
     * @param lockIndex The index of the lock.
     * @param expectedType The expected LockType.
     * @return The storage reference to the LockState struct.
     */
    function _getLockState(address user, address token, uint256 lockIndex, LockType expectedType) internal view returns (LockState storage) {
        require(lockIndex < userLocks[user][token].length, "Invalid lock index");
        LockState storage lock = userLocks[user][token][lockIndex];
        require(lock.lockType == expectedType, "Incorrect lock type for index");
        // Ownership check is implicit by using userLocks[user] mapping
        return lock;
    }

    // Add mapping for decaying lock claimed amount (needs to be outside functions)
    mapping(address => mapping(address => mapping(uint256 => uint256))) public decayingLockClaimedAmount;

    // Add a receive function to accept Ether deposits

}
```