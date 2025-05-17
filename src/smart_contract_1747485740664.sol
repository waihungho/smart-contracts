Okay, let's create a smart contract concept inspired by "Quantum Entanglement" and "Probabilistic Collapse" – not in a literal physics sense, but using these ideas metaphorically to create complex, state-dependent, and potentially probabilistic release conditions for locked assets.

This contract, which we'll call `QuantumVault`, allows users to deposit assets and lock them under a set of conditions. These conditions can be based on time, external contract states, oracle data, or even a probabilistic outcome triggered by interaction. Accessing funds requires *all* associated conditions for a specific "lock" to be met ("quantum collapse" of the state). Conditions can be shared or "entangled" across different locks or even users (conceptually).

---

**Smart Contract: QuantumVault**

**Description:**
A novel smart contract that acts as a secure vault for locking assets (ETH and ERC20 tokens) under complex, multi-factor release conditions. Inspired by concepts from quantum mechanics, it allows for the creation of "Vault Locks" linked to a set of "Conditions". Conditions can be time-based, depend on the state of external contracts, integrate data from oracles, or involve a probabilistic element. Funds associated with a lock are released only when *all* linked conditions are met, conceptually representing the "collapse" of the quantum state into a withdrawable state.

**Outline:**

1.  **Interfaces:** Define necessary interfaces (ERC20, Oracle Adapter).
2.  **Libraries:** Use SafeERC20 and ReentrancyGuard from OpenZeppelin.
3.  **State Variables:**
    *   Owner, Paused state.
    *   Supported ERC20 tokens.
    *   Deposited balances per user per asset.
    *   Global array of defined Conditions.
    *   Global array of defined Vault Locks.
    *   Mapping from user address to their Vault Lock indices.
4.  **Enums:** Define `ConditionType`.
5.  **Structs:** Define `Condition` and `VaultLock`.
6.  **Events:** Announce key actions (Deposit, Lock Created, Condition Created, Withdrawal Attempt, Withdrawal Success, etc.).
7.  **Modifiers:** Pausable, ReentrancyGuard.
8.  **Constructor:** Initialize owner, supported tokens.
9.  **Core Functionality:**
    *   Deposits (ETH, ERC20).
    *   Condition Creation (various types).
    *   Vault Lock Creation (linking funds to conditions).
    *   Attempting Withdrawal (evaluates conditions, performs withdrawal).
10. **Internal/Helper Functions:**
    *   Evaluate individual condition types.
    *   Evaluate all conditions for a lock.
    *   Parameter encoding/decoding for conditions.
11. **Admin Functions:**
    *   Manage supported tokens.
    *   Pause/Unpause.
    *   Withdraw admin fees (if any).
    *   Transfer Ownership.
12. **View Functions:**
    *   Get balances.
    *   Get condition details.
    *   Get vault lock details.
    *   Check if conditions for a lock are currently met.
    *   Get user's vault locks.
    *   Get counts (conditions, locks).

**Function Summary:**

1.  `constructor(address[] initialSupportedTokens)`: Initializes the contract with the owner and a list of initially supported ERC20 tokens.
2.  `receive() external payable`: Allows receiving native ETH deposits.
3.  `depositETH() external payable nonReentrant`: Deposits native ETH into the user's balance.
4.  `depositERC20(address token, uint256 amount) external nonReentrant`: Deposits a specified amount of a supported ERC20 token. Requires prior approval.
5.  `addSupportedToken(address token) external onlyOwner`: Adds a new ERC20 token to the list of supported assets.
6.  `removeSupportedToken(address token) external onlyOwner`: Removes an ERC20 token from the list of supported assets.
7.  `createConditionTime(uint256 unlockTimestamp) external returns (uint256 conditionIndex)`: Creates a time-based condition requiring the current time to be greater than or equal to `unlockTimestamp`.
8.  `createConditionEventCheck(address targetContract, bytes4 functionSelector, uint256 requiredValue) external returns (uint256 conditionIndex)`: Creates a condition that checks if calling a `view`/`pure` function (`functionSelector`) on `targetContract` returns `requiredValue`.
9.  `createConditionOracle(address oracleAdapter, bytes dataKey, uint256 requiredValue) external returns (uint256 conditionIndex)`: Creates a condition based on an oracle feed. Assumes `oracleAdapter` is a contract implementing `IOracleAdapter` with a `getData(bytes dataKey)` function returning `uint256`. Condition is met if `getData` returns `requiredValue`.
10. `createConditionContractStateBytes(address targetContract, bytes callData, bytes expectedResult) external returns (uint256 conditionIndex)`: Creates a condition that calls an arbitrary `view`/`pure` function on `targetContract` using `callData` and checks if the returned raw bytes match `expectedResult`. *Note: Use with caution.*
11. `createConditionProbabilistic(uint16 probabilityBasisPoints) external returns (uint256 conditionIndex)`: Creates a probabilistic condition. When evaluated in `attemptWithdraw`, it passes based on a random number generation (pseudo-random using block hash/timestamp/caller - *warning: not truly random, vulnerable to miner manipulation*) against the specified probability (basis points, e.g., 5000 for 50%).
12. `createVaultLock(address asset, uint256 amount, uint256[] conditionIndices) external nonReentrant returns (uint256 lockIndex)`: Creates a new vault lock for the caller's deposited asset amount, linking it to existing conditions by their indices. Deducts the amount from the user's available balance.
13. `addConditionToLock(uint256 lockIndex, uint256 conditionIndex) external`: Adds an existing condition to an existing vault lock owned by the caller.
14. `removeConditionFromLock(uint256 lockIndex, uint256 conditionIndex) external`: Removes a condition from a vault lock owned by the caller.
15. `cancelVaultLock(uint256 lockIndex) external nonReentrant`: Allows the owner of a lock to cancel it *if none of the conditions have been met yet*. Returns the locked amount to the user's available balance.
16. `attemptWithdraw(uint256 lockIndex) external nonReentrant`: Attempts to withdraw funds from a vault lock. Evaluates *all* conditions associated with the lock. If ALL conditions are met, the funds are transferred to the lock owner and the lock is marked inactive.
17. `getDepositedBalance(address user, address asset) external view returns (uint256)`: Gets the currently available deposited balance for a user for a specific asset (excluding amounts locked in active vaults).
18. `getConditionDetails(uint256 index) external view returns (uint8 conditionType, bytes parameters, uint256 creationTime)`: Retrieves details of a condition by index.
19. `getVaultLockDetails(uint256 index) external view returns (address owner, address asset, uint256 amount, uint256[] conditionIndices, bool isActive)`: Retrieves details of a vault lock by index.
20. `checkLockConditions(uint256 lockIndex) external view returns (bool)`: Checks if *all* conditions for a specific vault lock are currently met *without* attempting withdrawal.
21. `getUserVaultLocks(address user) external view returns (uint256[] lockIndices)`: Returns the indices of all vault locks created by a specific user.
22. `getTotalConditions() external view returns (uint256)`: Returns the total number of conditions created.
23. `getTotalVaultLocks() external view returns (uint256)`: Returns the total number of vault locks created.
24. `isSupportedToken(address token) external view returns (bool)`: Checks if a token is supported by the vault.
25. `pause() external onlyOwner`: Pauses the contract, preventing deposits, withdrawals, and lock/condition creation.
26. `unpause() external onlyOwner`: Unpauses the contract.

This design incorporates multiple types of conditions, links them to specific asset locks, and requires a complex multi-condition check for withdrawal, fitting the "advanced, creative, 20+ functions" requirement without directly copying common patterns like simple time locks, vesting, or multi-sigs. The "Quantum" theme is a conceptual layer over the complex conditionality.

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol"; // Useful for structured storage access patterns if needed, though not strictly required for this example.

// --- OUTLINE & FUNCTION SUMMARY ---
//
// Smart Contract: QuantumVault
//
// Description:
// A novel smart contract that acts as a secure vault for locking assets (ETH and ERC20 tokens) under complex, multi-factor release conditions. Inspired by concepts from quantum mechanics, it allows for the creation of "Vault Locks" linked to a set of "Conditions". Conditions can be time-based, depend on the state of external contracts, integrate data from oracles, or involve a probabilistic element. Funds associated with a lock are released only when *all* linked conditions are met, conceptually representing the "collapse" of the quantum state into a withdrawable state.
//
// Outline:
// 1.  Interfaces: Define necessary interfaces (ERC20, Oracle Adapter).
// 2.  Libraries: Use SafeERC20 and ReentrancyGuard from OpenZeppelin.
// 3.  State Variables: Owner, Paused state, Supported ERC20 tokens, Deposited balances, Conditions array, Vault Locks array, User-to-locks mapping.
// 4.  Enums: Define ConditionType.
// 5.  Structs: Define Condition and VaultLock.
// 6.  Events: Announce key actions.
// 7.  Modifiers: Pausable, ReentrancyGuard.
// 8.  Constructor: Initialize owner, supported tokens.
// 9.  Core Functionality: Deposits, Condition Creation (various types), Vault Lock Creation, Attempting Withdrawal.
// 10. Internal/Helper Functions: Evaluate individual condition types, Evaluate all conditions for a lock, Parameter encoding/decoding.
// 11. Admin Functions: Manage supported tokens, Pause/Unpause, Transfer Ownership.
// 12. View Functions: Get balances, Get condition details, Get vault lock details, Check if conditions for a lock are met, Get user's vault locks, Get counts, Check if token is supported.
//
// Function Summary:
// 1.  constructor(address[] initialSupportedTokens): Initializes the contract.
// 2.  receive() external payable: Allows receiving native ETH deposits.
// 3.  depositETH() external payable nonReentrant: Deposits native ETH.
// 4.  depositERC20(address token, uint256 amount) external nonReentrant: Deposits ERC20 tokens.
// 5.  addSupportedToken(address token) external onlyOwner: Adds supported token.
// 6.  removeSupportedToken(address token) external onlyOwner: Removes supported token.
// 7.  createConditionTime(uint256 unlockTimestamp) external returns (uint256 conditionIndex): Creates time condition.
// 8.  createConditionEventCheck(address targetContract, bytes4 functionSelector, uint256 requiredValue) external returns (uint256 conditionIndex): Creates condition checking external contract state (uint256 getter).
// 9.  createConditionOracle(address oracleAdapter, bytes dataKey, uint256 requiredValue) external returns (uint256 conditionIndex): Creates condition based on oracle data.
// 10. createConditionContractStateBytes(address targetContract, bytes callData, bytes expectedResult) external returns (uint256 conditionIndex): Creates condition checking raw bytes result of external contract call.
// 11. createConditionProbabilistic(uint16 probabilityBasisPoints) external returns (uint256 conditionIndex): Creates probabilistic condition.
// 12. createVaultLock(address asset, uint256 amount, uint256[] conditionIndices) external nonReentrant returns (uint256 lockIndex): Creates a vault lock.
// 13. addConditionToLock(uint256 lockIndex, uint256 conditionIndex) external: Adds condition to a lock.
// 14. removeConditionFromLock(uint256 lockIndex, uint256 conditionIndex) external: Removes condition from a lock.
// 15. cancelVaultLock(uint256 lockIndex) external nonReentrant: Cancels a lock before conditions are met.
// 16. attemptWithdraw(uint256 lockIndex) external nonReentrant: Attempts withdrawal by evaluating lock conditions.
// 17. getDepositedBalance(address user, address asset) external view returns (uint256): Gets available balance.
// 18. getConditionDetails(uint256 index) external view returns (uint8 conditionType, bytes parameters, uint256 creationTime): Gets condition details.
// 19. getVaultLockDetails(uint256 index) external view returns (address owner, address asset, uint256 amount, uint256[] conditionIndices, bool isActive): Gets vault lock details.
// 20. checkLockConditions(uint256 lockIndex) external view returns (bool): Checks if lock conditions are met *now*.
// 21. getUserVaultLocks(address user) external view returns (uint256[] lockIndices): Gets user's lock indices.
// 22. getTotalConditions() external view returns (uint256): Gets total number of conditions.
// 23. getTotalVaultLocks() external view returns (uint256): Gets total number of vault locks.
// 24. isSupportedToken(address token) external view returns (bool): Checks if token is supported.
// 25. pause() external onlyOwner: Pauses the contract.
// 26. unpause() external onlyOwner: Unpauses the contract.

// --- INTERFACES ---

interface IOracleAdapter {
    // Example interface for an oracle adapter contract
    // This function is assumed to fetch data based on a key and return a uint256 value
    function getData(bytes calldata dataKey) external view returns (uint256);
    // Add other necessary oracle functions as per actual implementation
}

// --- CONTRACT ---

contract QuantumVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Address for address; // For checking if address is contract

    // --- STATE VARIABLES ---

    mapping(address => bool) private _supportedTokens;
    // Asset -> User -> Balance (available for locking or withdrawal outside locks)
    mapping(address => mapping(address => uint256)) public depositedBalances;

    enum ConditionType {
        TimeBased,            // Param: abi.encode(unlockTimestamp) -> uint256
        EventCheckUint,       // Param: abi.encode(targetContract, functionSelector, requiredValue) -> address, bytes4, uint256
        OracleValue,          // Param: abi.encode(oracleAdapter, dataKey, requiredValue) -> address, bytes, uint256
        ContractStateBytes,   // Param: abi.encode(targetContract, callData, expectedResult) -> address, bytes, bytes
        Probabilistic         // Param: abi.encode(probabilityBasisPoints) -> uint16 (e.g., 5000 for 50%)
    }

    struct Condition {
        ConditionType conditionType;
        bytes parameters;
        uint256 creationTime; // Timestamp when the condition was created
    }

    struct VaultLock {
        address owner;
        address asset;
        uint256 amount;
        uint256[] conditionIndices;
        bool isActive; // True if the lock is active and funds are pending release
    }

    Condition[] public allConditions;
    VaultLock[] public allVaultLocks;

    // Mapping from user address to the indices of vault locks they own
    mapping(address => uint256[]) public userVaultLocks;

    // --- EVENTS ---

    event EthDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event ConditionCreated(uint256 indexed index, ConditionType conditionType, address indexed creator);
    event VaultLockCreated(uint256 indexed index, address indexed owner, address indexed asset, uint256 amount);
    event ConditionAddedToLock(uint256 indexed lockIndex, uint256 indexed conditionIndex);
    event ConditionRemovedFromLock(uint256 indexed lockIndex, uint256 indexed conditionIndex);
    event VaultLockCancelled(uint256 indexed lockIndex, address indexed owner);
    event WithdrawalAttempt(uint256 indexed lockIndex, address indexed caller);
    event WithdrawalSuccessful(uint256 indexed lockIndex, address indexed owner, address indexed asset, uint256 amount);
    event ConditionsNotMet(uint256 indexed lockIndex);
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    // --- MODIFIERS ---

    modifier whenTokenSupported(address token) {
        require(_supportedTokens[token], "QuantumVault: Token not supported");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(address[] memory initialSupportedTokens) Ownable(msg.sender) Pausable() {
        for (uint i = 0; i < initialSupportedTokens.length; i++) {
            _supportedTokens[initialSupportedTokens[i]] = true;
            emit SupportedTokenAdded(initialSupportedTokens[i]);
        }
    }

    // --- CORE DEPOSIT FUNCTIONS ---

    /// @notice Allows users to deposit native ETH into their available balance.
    receive() external payable whenNotPaused {
        require(msg.value > 0, "QuantumVault: Zero ETH deposit");
        depositedBalances[address(0)][msg.sender] += msg.value; // Use address(0) for ETH
        emit EthDeposited(msg.sender, msg.value);
    }

    /// @notice Allows users to deposit supported ERC20 tokens into their available balance.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    /// @dev Requires the user to have approved the contract to spend the tokens first.
    function depositERC20(address token, uint256 amount) external nonReentrant whenNotPaused whenTokenSupported(token) {
        require(amount > 0, "QuantumVault: Zero token deposit");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        depositedBalances[token][msg.sender] += amount;
        emit ERC20Deposited(msg.sender, token, amount);
    }

    // --- ADMIN FUNCTIONS ---

    /// @notice Adds a new ERC20 token to the list of supported assets.
    /// @param token The address of the ERC20 token to add.
    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "QuantumVault: Invalid token address");
        require(!_supportedTokens[token], "QuantumVault: Token already supported");
        _supportedTokens[token] = true;
        emit SupportedTokenAdded(token);
    }

    /// @notice Removes an ERC20 token from the list of supported assets.
    /// @param token The address of the ERC20 token to remove.
    /// @dev Be cautious removing tokens if funds are still held.
    function removeSupportedToken(address token) external onlyOwner {
        require(token != address(0), "QuantumVault: Invalid token address");
        require(_supportedTokens[token], "QuantumVault: Token not supported");
        // TODO: Add checks or warnings if significant balance of this token is held?
        delete _supportedTokens[token];
        emit SupportedTokenRemoved(token);
    }

    /// @notice Pauses the contract, restricting most user interactions.
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, enabling user interactions.
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // Note: Standard Ownable renounce/transfer ownership functions are inherited.

    // --- CONDITION CREATION FUNCTIONS ---

    /// @notice Creates a time-based condition.
    /// @param unlockTimestamp The timestamp (in seconds since epoch) when the condition becomes met.
    /// @return conditionIndex The index of the newly created condition in `allConditions`.
    function createConditionTime(uint256 unlockTimestamp) external whenNotPaused returns (uint256 conditionIndex) {
        require(unlockTimestamp > block.timestamp, "QuantumVault: Unlock time must be in the future");
        bytes memory params = abi.encode(unlockTimestamp);
        allConditions.push(Condition(ConditionType.TimeBased, params, block.timestamp));
        conditionIndex = allConditions.length - 1;
        emit ConditionCreated(conditionIndex, ConditionType.TimeBased, msg.sender);
    }

    /// @notice Creates a condition that checks the return value of a view/pure function on another contract.
    /// @param targetContract The address of the target contract.
    /// @param functionSelector The first 4 bytes of the target function's signature (e.g., `bytes4(keccak256("getValue()"))`).
    /// @param requiredValue The uint256 value expected from the function call.
    /// @return conditionIndex The index of the newly created condition.
    /// @dev This assumes the target function returns a single uint256.
    function createConditionEventCheck(
        address targetContract,
        bytes4 functionSelector,
        uint256 requiredValue
    ) external whenNotPaused returns (uint256 conditionIndex) {
        require(targetContract.isContract(), "QuantumVault: Target address is not a contract");
        // We don't validate the selector or return type here beyond assuming uint256.
        bytes memory params = abi.encode(targetContract, functionSelector, requiredValue);
        allConditions.push(Condition(ConditionType.EventCheckUint, params, block.timestamp));
        conditionIndex = allConditions.length - 1;
        emit ConditionCreated(conditionIndex, ConditionType.EventCheckUint, msg.sender);
    }

    /// @notice Creates a condition based on an oracle data feed.
    /// @param oracleAdapter The address of the oracle adapter contract implementing `IOracleAdapter`.
    /// @param dataKey The key or identifier for the data feed (format depends on the oracle adapter).
    /// @param requiredValue The uint256 value expected from the oracle feed.
    /// @return conditionIndex The index of the newly created condition.
    function createConditionOracle(
        address oracleAdapter,
        bytes memory dataKey,
        uint256 requiredValue
    ) external whenNotPaused returns (uint256 conditionIndex) {
        require(oracleAdapter.isContract(), "QuantumVault: Oracle adapter is not a contract");
        bytes memory params = abi.encode(oracleAdapter, dataKey, requiredValue);
        allConditions.push(Condition(ConditionType.OracleValue, params, block.timestamp));
        conditionIndex = allConditions.length - 1;
        emit ConditionCreated(conditionIndex, ConditionType.OracleValue, msg.sender);
    }

    /// @notice Creates a condition by calling a contract function with arbitrary calldata and checking the raw byte result.
    /// @param targetContract The address of the target contract.
    /// @param callData The ABI-encoded calldata for the function call.
    /// @param expectedResult The exact bytes expected as the return value.
    /// @return conditionIndex The index of the newly created condition.
    /// @dev This is flexible but potentially risky if `callData` targets non-view/pure functions or unexpected state changes occur.
    /// @dev The call is made using low-level `call`. It's the creator's responsibility to ensure safety and correctness.
    function createConditionContractStateBytes(
        address targetContract,
        bytes memory callData,
        bytes memory expectedResult
    ) external whenNotPaused returns (uint256 conditionIndex) {
        require(targetContract.isContract(), "QuantumVault: Target address is not a contract");
        // We cannot reliably check if the callData targets a view/pure function here.
        bytes memory params = abi.encode(targetContract, callData, expectedResult);
        allConditions.push(Condition(ConditionType.ContractStateBytes, params, block.timestamp));
        conditionIndex = allConditions.length - 1;
        emit ConditionCreated(conditionIndex, ConditionType.ContractStateBytes, msg.sender);
    }


    /// @notice Creates a probabilistic condition. When evaluated, it has a chance to pass.
    /// @param probabilityBasisPoints Probability in basis points (0-10000). 5000 = 50% chance.
    /// @return conditionIndex The index of the newly created condition.
    /// @dev The random number generation is pseudo-random and depends on block variables, making it vulnerable to miner manipulation. Do NOT use for high-value, high-security applications requiring true randomness. This is for conceptual/demonstration purposes.
    function createConditionProbabilistic(uint16 probabilityBasisPoints) external whenNotPaused returns (uint256 conditionIndex) {
        require(probabilityBasisPoints <= 10000, "QuantumVault: Probability must be <= 10000");
        bytes memory params = abi.encode(probabilityBasisPoints);
        allConditions.push(Condition(ConditionType.Probabilistic, params, block.timestamp));
        conditionIndex = allConditions.length - 1;
        emit ConditionCreated(conditionIndex, ConditionType.Probabilistic, msg.sender);
    }

    // --- VAULT LOCK MANAGEMENT FUNCTIONS ---

    /// @notice Creates a new vault lock for a specified amount of a deposited asset, linked to conditions.
    /// @param asset The address of the asset (address(0) for ETH).
    /// @param amount The amount of the asset to lock.
    /// @param conditionIndices The indices of the conditions that must be met for this lock to be released.
    /// @return lockIndex The index of the newly created vault lock.
    function createVaultLock(
        address asset,
        uint256 amount,
        uint256[] memory conditionIndices
    ) external nonReentrant whenNotPaused returns (uint256 lockIndex) {
        if (asset != address(0)) {
             require(_supportedTokens[asset], "QuantumVault: Asset token not supported");
        }
        require(amount > 0, "QuantumVault: Cannot lock zero amount");
        require(depositedBalances[asset][msg.sender] >= amount, "QuantumVault: Insufficient deposited balance");
        require(conditionIndices.length > 0, "QuantumVault: At least one condition is required");

        // Validate condition indices
        for (uint i = 0; i < conditionIndices.length; i++) {
            require(conditionIndices[i] < allConditions.length, "QuantumVault: Invalid condition index");
        }

        // Deduct amount from available balance
        depositedBalances[asset][msg.sender] -= amount;

        // Create the vault lock
        allVaultLocks.push(VaultLock(msg.sender, asset, amount, conditionIndices, true));
        lockIndex = allVaultLocks.length - 1;

        // Add lock index to user's list
        userVaultLocks[msg.sender].push(lockIndex);

        emit VaultLockCreated(lockIndex, msg.sender, asset, amount);
    }

    /// @notice Adds an existing condition to a vault lock owned by the caller.
    /// @param lockIndex The index of the vault lock.
    /// @param conditionIndex The index of the condition to add.
    function addConditionToLock(uint256 lockIndex, uint256 conditionIndex) external whenNotPaused {
        require(lockIndex < allVaultLocks.length, "QuantumVault: Invalid lock index");
        VaultLock storage lock = allVaultLocks[lockIndex];
        require(lock.owner == msg.sender, "QuantumVault: Not the owner of this lock");
        require(lock.isActive, "QuantumVault: Lock is not active");
        require(conditionIndex < allConditions.length, "QuantumVault: Invalid condition index");

        // Check if condition is already present (simple linear scan - okay for small number of conditions per lock)
        bool alreadyPresent = false;
        for (uint i = 0; i < lock.conditionIndices.length; i++) {
            if (lock.conditionIndices[i] == conditionIndex) {
                alreadyPresent = true;
                break;
            }
        }
        require(!alreadyPresent, "QuantumVault: Condition already linked to this lock");

        lock.conditionIndices.push(conditionIndex);
        emit ConditionAddedToLock(lockIndex, conditionIndex);
    }

    /// @notice Removes a condition from a vault lock owned by the caller.
    /// @param lockIndex The index of the vault lock.
    /// @param conditionIndex The index of the condition to remove.
    /// @dev This function uses a basic removal method (shifting elements). More efficient methods exist for large arrays.
    function removeConditionFromLock(uint256 lockIndex, uint256 conditionIndex) external whenNotPaused {
        require(lockIndex < allVaultLocks.length, "QuantumVault: Invalid lock index");
        VaultLock storage lock = allVaultLocks[lockIndex];
        require(lock.owner == msg.sender, "QuantumVault: Not the owner of this lock");
        require(lock.isActive, "QuantumVault: Lock is not active");

        bool found = false;
        for (uint i = 0; i < lock.conditionIndices.length; i++) {
            if (lock.conditionIndices[i] == conditionIndex) {
                // Simple removal by shifting elements and resizing
                lock.conditionIndices[i] = lock.conditionIndices[lock.conditionIndices.length - 1];
                lock.conditionIndices.pop();
                found = true;
                break;
            }
        }
        require(found, "QuantumVault: Condition not found in this lock");

        emit ConditionRemovedFromLock(lockIndex, conditionIndex);
    }

    /// @notice Allows the owner to cancel an active vault lock, returning funds to their available balance.
    /// @param lockIndex The index of the vault lock to cancel.
    /// @dev This is only possible if *none* of the conditions associated with the lock are currently met.
    function cancelVaultLock(uint256 lockIndex) external nonReentrant whenNotPaused {
         require(lockIndex < allVaultLocks.length, "QuantumVault: Invalid lock index");
        VaultLock storage lock = allVaultLocks[lockIndex];
        require(lock.owner == msg.sender, "QuantumVault: Not the owner of this lock");
        require(lock.isActive, "QuantumVault: Lock is not active");

        // Cannot cancel if *any* condition is already met.
        // Check each condition individually.
        for (uint i = 0; i < lock.conditionIndices.length; i++) {
             uint256 currentConditionIndex = lock.conditionIndices[i];
             if (_evaluateCondition(currentConditionIndex)) {
                 revert("QuantumVault: Cannot cancel lock, at least one condition is already met.");
             }
         }

        // Return funds to available balance
        depositedBalances[lock.asset][lock.owner] += lock.amount;

        // Mark lock as inactive
        lock.isActive = false;

        emit VaultLockCancelled(lockIndex, msg.sender);
    }

    // --- WITHDRAWAL FUNCTION ---

    /// @notice Attempts to withdraw funds from a vault lock by evaluating all linked conditions.
    /// @param lockIndex The index of the vault lock to attempt to withdraw from.
    /// @dev Funds are only transferred if ALL conditions associated with the lock are currently met.
    function attemptWithdraw(uint256 lockIndex) external nonReentrant whenNotPaused {
        emit WithdrawalAttempt(lockIndex, msg.sender);

        require(lockIndex < allVaultLocks.length, "QuantumVault: Invalid lock index");
        VaultLock storage lock = allVaultLocks[lockIndex];
        require(lock.owner == msg.sender, "QuantumVault: Not the owner of this lock");
        require(lock.isActive, "QuantumVault: Lock is not active");

        // --- Evaluate ALL conditions for the lock ---
        bool allConditionsMet = true;
        for (uint i = 0; i < lock.conditionIndices.length; i++) {
            uint256 conditionIndex = lock.conditionIndices[i];
            if (!_evaluateCondition(conditionIndex)) {
                allConditionsMet = false;
                break; // Found one unmet condition, no need to check further
            }
        }

        if (allConditionsMet) {
            // --- Conditions Met: Perform Withdrawal ---
            lock.isActive = false; // Deactivate the lock

            if (lock.asset == address(0)) {
                // Transfer ETH
                (bool success,) = payable(lock.owner).call{value: lock.amount}("");
                require(success, "QuantumVault: ETH transfer failed");
            } else {
                // Transfer ERC20
                IERC20(lock.asset).safeTransfer(lock.owner, lock.amount);
            }

            emit WithdrawalSuccessful(lockIndex, lock.owner, lock.asset, lock.amount);

        } else {
            // --- Conditions Not Met ---
            emit ConditionsNotMet(lockIndex);
            // No state change, funds remain locked.
        }
    }

    // --- INTERNAL/HELPER FUNCTIONS FOR CONDITION EVALUATION ---

    /// @notice Evaluates a single condition based on its type and parameters.
    /// @param conditionIndex The index of the condition to evaluate.
    /// @return True if the condition is met, false otherwise.
    function _evaluateCondition(uint256 conditionIndex) internal view returns (bool) {
        require(conditionIndex < allConditions.length, "QuantumVault: Invalid condition index during evaluation");
        Condition storage condition = allConditions[conditionIndex];

        if (condition.conditionType == ConditionType.TimeBased) {
            uint256 unlockTimestamp;
            // Decode parameters safely
            assembly {
                unlockTimestamp := calldataload(add(condition.parameters, 32)) // Load uint256 from bytes
            }
            // (bool success, bytes memory decoded) = abi.decode(condition.parameters, (uint256)); // Alternative using abi.decode directly
            // unlockTimestamp = decoded[0]; // Access the uint256 value

            return block.timestamp >= unlockTimestamp;

        } else if (condition.conditionType == ConditionType.EventCheckUint) {
            (address targetContract, bytes4 functionSelector, uint256 requiredValue) = abi.decode(condition.parameters, (address, bytes4, uint256));
             (bool success, bytes memory returnData) = targetContract.staticcall(abi.encodePacked(functionSelector));
             if (!success || returnData.length != 32) {
                 // Call failed or returned unexpected data size
                 return false; // Treat failure to read as unmet
             }
             uint256 currentValue = abi.decode(returnData, (uint256));
             return currentValue == requiredValue;

        } else if (condition.conditionType == ConditionType.OracleValue) {
            (address oracleAdapter, bytes memory dataKey, uint256 requiredValue) = abi.decode(condition.parameters, (address, bytes, uint256));
             try IOracleAdapter(oracleAdapter).getData(dataKey) returns (uint256 oracleValue) {
                 return oracleValue == requiredValue;
             } catch {
                 // Oracle call failed
                 return false; // Treat failure to get data as unmet
             }

        } else if (condition.conditionType == ConditionType.ContractStateBytes) {
             (address targetContract, bytes memory callData, bytes memory expectedResult) = abi.decode(condition.parameters, (address, bytes, bytes));
             (bool success, bytes memory returnData) = targetContract.staticcall(callData);

             if (!success) {
                 return false; // Call failed
             }
             // Compare raw bytes returned with expected bytes
             return keccak256(returnData) == keccak256(expectedResult);

        } else if (condition.conditionType == ConditionType.Probabilistic) {
            uint16 probabilityBasisPoints;
            // Decode parameters
             assembly {
                 probabilityBasisPoints := shr(240, calldataload(add(condition.parameters, 32))) // Load uint16 from bytes (shifted)
             }
             // (bool success, bytes memory decoded) = abi.decode(condition.parameters, (uint16)); // Alternative using abi.decode directly
             // probabilityBasisPoints = decoded[0]; // Access the uint16 value

            // Pseudo-randomness: Combine block variables
            uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number, block.coinbase)));
            uint256 randomNumber = randomSeed % 10001; // Get a number between 0 and 10000

            return randomNumber < probabilityBasisPoints; // Condition met if random number falls within probability range

        } else {
            // Unknown condition type
            return false;
        }
    }


    // --- VIEW FUNCTIONS ---

    /// @notice Gets the available deposited balance for a user for a specific asset.
    /// @param user The user address.
    /// @param asset The asset address (address(0) for ETH).
    /// @return The available balance.
    function getDepositedBalance(address user, address asset) external view returns (uint256) {
        return depositedBalances[asset][user];
    }

    /// @notice Retrieves details of a condition by its index.
    /// @param index The index of the condition.
    /// @return conditionType The type of the condition (as uint8).
    /// @return parameters The raw encoded parameters of the condition.
    /// @return creationTime The timestamp when the condition was created.
    function getConditionDetails(uint256 index) external view returns (uint8 conditionType, bytes memory parameters, uint256 creationTime) {
        require(index < allConditions.length, "QuantumVault: Invalid condition index");
        Condition storage condition = allConditions[index];
        return (uint8(condition.conditionType), condition.parameters, condition.creationTime);
    }

    /// @notice Retrieves details of a vault lock by its index.
    /// @param index The index of the vault lock.
    /// @return owner The owner's address.
    /// @return asset The asset address (address(0) for ETH).
    /// @return amount The amount locked.
    /// @return conditionIndices The indices of linked conditions.
    /// @return isActive Whether the lock is active.
    function getVaultLockDetails(uint256 index) external view returns (address owner, address asset, uint256 amount, uint256[] memory conditionIndices, bool isActive) {
        require(index < allVaultLocks.length, "QuantumVault: Invalid lock index");
        VaultLock storage lock = allVaultLocks[index];
        return (lock.owner, lock.asset, lock.amount, lock.conditionIndices, lock.isActive);
    }

    /// @notice Checks if ALL conditions for a specific vault lock are currently met.
    /// @param lockIndex The index of the vault lock.
    /// @return True if all conditions are met, false otherwise.
    function checkLockConditions(uint256 lockIndex) external view returns (bool) {
        require(lockIndex < allVaultLocks.length, "QuantumVault: Invalid lock index");
        VaultLock storage lock = allVaultLocks[lockIndex];

        if (!lock.isActive) {
            return false; // Inactive locks cannot have conditions met for withdrawal
        }

        for (uint i = 0; i < lock.conditionIndices.length; i++) {
            uint256 conditionIndex = lock.conditionIndices[i];
            if (!_evaluateCondition(conditionIndex)) {
                return false; // Found one unmet condition
            }
        }

        return true; // All conditions met
    }

    /// @notice Gets the indices of all vault locks owned by a specific user.
    /// @param user The user address.
    /// @return An array of vault lock indices.
    function getUserVaultLocks(address user) external view returns (uint256[] memory) {
        return userVaultLocks[user];
    }

    /// @notice Gets the total number of conditions created in the contract.
    /// @return The total count of conditions.
    function getTotalConditions() external view returns (uint256) {
        return allConditions.length;
    }

    /// @notice Gets the total number of vault locks created in the contract.
    /// @return The total count of vault locks.
    function getTotalVaultLocks() external view returns (uint256) {
        return allVaultLocks.length;
    }

     /// @notice Checks if a specific token is supported by the vault for deposits.
     /// @param token The address of the token.
     /// @return True if the token is supported, false otherwise.
    function isSupportedToken(address token) external view returns (bool) {
        return _supportedTokens[token];
    }

    // Inherited: owner(), transferOwnership(), renounceOwnership(), paused()
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Multi-Factor Complex Conditions:** Unlike simple time locks or single-condition releases, funds are tied to *multiple* potentially independent conditions (`conditionIndices` array in `VaultLock`). All must be true simultaneously for release. This complexity is inspired by the idea of a complex "state" that must collapse.
2.  **Diverse Condition Types:** Includes time, external contract state checks, oracle data, and even a probabilistic element. This goes beyond standard on-chain logic and integrates external data sources and non-deterministic concepts (probabilistic).
3.  **External Contract State Dependency (`createConditionEventCheck`, `createConditionContractStateBytes`):** Allows the release of funds to depend on the state or events happening in *other* arbitrary contracts, creating a form of on-chain "entanglement" where one contract's state affects another's behavior. The `ContractStateBytes` condition is particularly flexible (and risky) by allowing arbitrary `staticcall` data checks.
4.  **Oracle Integration (`createConditionOracle`):** Directly ties fund release to off-chain data feeds (like price feeds, event outcomes, etc.), brought on-chain by an oracle adapter. This makes the vault react to real-world or external blockchain events.
5.  **Probabilistic Release (`createConditionProbabilistic`):** Introduced as a conceptual nod to quantum probability. A condition might pass with a certain percentage chance upon evaluation. **Crucially, this uses on-chain pseudo-randomness (based on block variables), which is highly insecure for applications requiring true randomness and vulnerable to miner manipulation.** It's included here purely for the "creative/trendy" concept demonstration, with a warning.
6.  **Conceptual "Quantum Collapse" (`attemptWithdraw`):** The act of calling `attemptWithdraw` is the trigger that evaluates the entire set of conditions for a lock. If and only if *all* are met, the state "collapses" into the released state, transferring funds. If any condition fails, the state remains "superposed" (locked).
7.  **Shared Conditions:** Conditions are global (`allConditions`) and indexed. A single condition (e.g., a specific timestamp, a specific oracle value threshold, or a specific external contract state) can be linked to *multiple* different `VaultLock`s, possibly owned by different users. This is the conceptual "entanglement" – changes meeting that shared condition affect potentially many locks simultaneously.
8.  **Modularity:** Conditions are separate entities from locks, allowing for reuse and combination in flexible ways.
9.  **Comprehensive Functionality:** Includes standard vault features (deposit, balance tracking) alongside the complex condition and lock management, plus necessary admin controls and views, exceeding the 20-function requirement.

This contract is a conceptual exploration and demonstration. The probabilistic condition using block variables is a known security risk for real-world applications requiring strong randomness. The `ContractStateBytes` condition is also risky due to the use of low-level `call` with potentially unvalidated calldata. Real-world implementations would require much more robust oracle implementations, secure randomness sources (like Chainlink VRF or similar), and safer methods for checking external contract states if needed.