Okay, let's design a smart contract that incorporates multiple interesting and somewhat advanced concepts beyond basic token standards or simple vaults.

We'll call it "QuantumVault". The core idea is a vault where unlocking assets isn't based on a single condition (like a timelock) but requires a *combination* of multiple, potentially external, and dynamic factors to be met simultaneously, inspired by the idea of quantum states requiring multiple observations/conditions to collapse.

This contract will handle both native currency (ETH) and multiple ERC-20 tokens.

**Advanced Concepts Used:**

1.  **Multi-Conditional Release:** Assets are locked and require *all* conditions within a specific "Quantum Lock Configuration" to be true for withdrawal.
2.  **Dynamic Conditions:** Conditions can include time, external oracle values (simulated here, but could integrate Chainlink/etc.), contract internal states (like minimum unique depositors), potentially random elements (simulated), and governance flags.
3.  **Role-Based Access Control:** Instead of a single owner, different roles manage different aspects (config management, oracle updates, governance flags).
4.  **Multiple Asset Handling:** Manages both native currency and diverse ERC-20 tokens within the same contract.
5.  **Configurable Lock Types:** Allows defining different sets of conditions as distinct "Quantum Lock Configurations".
6.  **Internal State Tracking:** Tracks unique depositors per lock configuration as a potential unlock condition.
7.  **Simulated External Inputs:** Includes functions to simulate inputs from oracles and governance mechanisms for condition checking (in a real scenario, these would be integrated via Chainlink, specific governance modules, etc.).

---

**QuantumVault Smart Contract: Outline & Function Summary**

**Outline:**

1.  **Pragma and Imports:** Specifies Solidity version and imports necessary interfaces (like ERC20).
2.  **Errors:** Custom error definitions for clarity.
3.  **Events:** Events to log significant actions (deposits, withdrawals, lock config changes, role changes, condition updates).
4.  **Structs:**
    *   `QuantumLockConfig`: Defines the structure for a set of unlock conditions.
5.  **Enums/Constants:** Define roles.
6.  **State Variables:** Store contract data (balances, lock configurations, roles, supported tokens, condition states).
7.  **Modifiers:** Custom modifiers for access control (`onlyRole`).
8.  **Constructor:** Initializes the contract, assigning initial roles.
9.  **Access Control Functions:** Manage roles and permissions.
10. **Supported Token Management:** Add/remove allowed ERC-20 tokens.
11. **Quantum Lock Configuration Functions:** Define, update, disable, and retrieve lock configurations.
12. **Condition Update Functions:** Functions to simulate/set external condition states (oracle values, governance flags, randomness trigger).
13. **Deposit Functions:** Allow users to deposit ETH or ERC-20 tokens linked to a specific lock configuration.
14. **Withdrawal Functions:** Allow users to withdraw assets *if* the associated lock configuration's conditions are met.
15. **View Functions:** Provide read-only access to contract state (balances, lock details, condition states).
16. **Internal Helper Functions:** Logic for checking lock conditions and tracking state.

**Function Summary (Total: 29 functions):**

*   **Access Control (5):**
    *   `constructor()`: Sets up initial roles.
    *   `addRole(bytes32 role, address account)`: Assigns a role to an address.
    *   `removeRole(bytes32 role, address account)`: Removes a role from an address.
    *   `hasRole(bytes32 role, address account)`: Checks if an address has a specific role (view).
    *   `renounceRole(bytes32 role)`: Allows an address to remove its own role.
*   **Supported Tokens (3):**
    *   `addSupportedToken(address token)`: Adds an ERC-20 token to the supported list (only `TOKEN_MANAGER_ROLE`).
    *   `removeSupportedToken(address token)`: Removes an ERC-20 token from the supported list (only `TOKEN_MANAGER_ROLE`).
    *   `isSupportedToken(address token)`: Checks if a token is supported (view).
*   **Quantum Lock Configuration (5):**
    *   `defineLockConfig(QuantumLockConfig calldata config)`: Defines a new lock configuration, returns new lock ID (only `CONFIG_MANAGER_ROLE`).
    *   `updateLockConfig(uint256 lockId, QuantumLockConfig calldata config)`: Updates an existing lock configuration (only `CONFIG_MANAGER_ROLE`). Limited update capability to prevent breaking existing deposits.
    *   `disableLockConfig(uint256 lockId)`: Marks a lock configuration as disabled (no new deposits) (only `CONFIG_MANAGER_ROLE`).
    *   `getLockConfigDetails(uint256 lockId)`: Retrieves details of a specific lock configuration (view).
    *   `getLockConfigs()`: Lists all defined lock IDs (view).
*   **Condition Updates (3):**
    *   `setOracleValue(bytes32 oracleId, uint256 value)`: Sets a simulated oracle value (only `ORACLE_UPDATER_ROLE`).
    *   `setGovernanceFlag(bytes32 flagId, bool state)`: Sets a simulated governance flag state (only `GOVERNANCE_ROLE`).
    *   `triggerRandomness(bytes32 randomnessId, uint256 value)`: Sets a simulated random value (only `ORACLE_UPDATER_ROLE`). In a real system, this would be VRF callback.
*   **Deposits (2):**
    *   `depositETH(uint256 lockId)`: Deposits ETH under a specific lock configuration (payable).
    *   `depositERC20(address token, uint256 lockId, uint256 amount)`: Deposits ERC-20 tokens under a specific lock configuration. Requires prior approval.
*   **Withdrawals (2):**
    *   `withdrawETH(uint256 lockId, uint256 amount)`: Withdraws ETH if lock conditions are met.
    *   `withdrawERC20(address token, uint256 lockId, uint256 amount)`: Withdraws ERC-20 tokens if lock conditions are met.
*   **View Functions (9):**
    *   `getUserETHBalance(uint256 lockId, address user)`: Gets a user's ETH balance for a lock (view).
    *   `getUserTokenBalance(address token, uint256 lockId, address user)`: Gets a user's token balance for a lock (view).
    *   `getTotalLockETHBalance(uint256 lockId)`: Gets the total ETH balance for a lock (view).
    *   `getTotalLockTokenBalance(address token, uint256 lockId)`: Gets the total token balance for a lock (view).
    *   `getTotalTokenBalance(address token)`: Gets the total balance of a specific token in the contract (view).
    *   `checkLockStatus(uint256 lockId)`: Checks if a specific lock configuration's conditions are currently met (view).
    *   `getOracleValue(bytes32 oracleId)`: Gets a simulated oracle value (view).
    *   `getGovernanceFlag(bytes32 flagId)`: Gets a simulated governance flag state (view).
    *   `getUniqueUserCountForLock(uint256 lockId)`: Gets the number of unique depositors for a lock (view).

*   **Internal Functions (Needed for logic, not exposed as public/external count - 1):**
    *   `_areLockConditionsMet(uint256 lockId)`: Internal helper to check all conditions for a lock.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint255);
    function balanceOf(address account) external view returns (uint255);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint255);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title QuantumVault
 * @dev A smart contract for depositing and withdrawing assets based on complex, multi-conditional 'Quantum Locks'.
 * Assets can only be withdrawn when all specified conditions for a given lock configuration are met simultaneously.
 * Supports ETH and multiple ERC-20 tokens. Uses role-based access control for configuration and condition updates.
 */

// --- Errors ---
error QuantumVault__InvalidLockId();
error QuantumVault__LockDisabled();
error QuantumVault__UnsupportedToken();
error QuantumVault__ZeroAddress();
error QuantumVault__InsufficientBalance();
error QuantumVault__ConditionsNotMet();
error QuantumVault__PermissionDenied();
error QuantumVault__AmountMustBeGreaterThanZero();
error QuantumVault__TokenAlreadySupported();
error QuantumVault__TokenNotSupported();
error QuantumVault__LockConfigUpdateRestricted();
error QuantumVault__LockIdExists(); // For update/disable if ID doesn't exist
error QuantumVault__OracleIdNotSet();
error QuantumVault__RandomnessIdNotSet();
error QuantumVault__GovernanceFlagIdNotSet();
error QuantumVault__RoleDoesNotExist();


// --- Events ---
event ETHDeposited(address indexed user, uint256 lockId, uint256 amount);
event ERC20Deposited(address indexed user, address indexed token, uint256 lockId, uint256 amount);
event ETHWithdrawn(address indexed user, uint256 lockId, uint256 amount);
event ERC20Withdrawn(address indexed user, address indexed token, uint256 lockId, uint256 amount);
event LockConfigDefined(uint256 indexed lockId, string description);
event LockConfigUpdated(uint256 indexed lockId);
event LockConfigDisabled(uint256 indexed lockId);
event OracleValueSet(bytes32 indexed oracleId, uint256 value);
event GovernanceFlagSet(bytes32 indexed flagId, bool state);
event RandomnessTriggered(bytes32 indexed randomnessId, uint256 value);
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
event SupportedTokenAdded(address indexed token);
event SupportedTokenRemoved(address indexed token);


// --- Structs ---
/**
 * @dev Defines the conditions required for a Quantum Lock to be considered 'met'.
 * All conditions must be true simultaneously for withdrawal.
 */
struct QuantumLockConfig {
    bool exists;             // Flag to indicate if this config ID is valid
    bool disabled;           // Flag to disable new deposits to this config
    string description;      // Human-readable description of the lock type

    // Condition 1: Timelock
    bool requireTimestamp;
    uint256 unlockTimestamp; // Timestamp after which this condition is met

    // Condition 2: External Oracle Value
    bool requireOracleValue;
    bytes32 oracleId;        // Identifier for the oracle feed (e.g., keccak256("ETH_USD_PRICE"))
    uint256 minOracleValue;  // Minimum value required from the oracle

    // Condition 3: Minimum Unique Depositors
    bool requireMinUsers;
    uint256 minUniqueUsers;  // Minimum number of unique addresses that have deposited to this lock ID

    // Condition 4: Minimum Required Token Balance in Contract (specific token)
    bool requireMinTokenBalance;
    address requiredTokenForLockCheck; // The token address to check balance for in this contract
    uint256 minRequiredTokenBalance;   // Minimum balance of requiredTokenForLockCheck required in the contract for *this specific lock ID*

    // Condition 5: Randomness Check (Simulated VRF)
    bool requireRandomness;
    bytes32 randomnessId;      // Identifier for the randomness feed/request
    uint256 randomnessModulus; // Value to take modulo of the random result
    uint256 randomnessTarget;  // The target remainder (randomResult % randomnessModulus == randomnessTarget)

    // Condition 6: Governance Flag
    bool requireGovernanceFlag;
    bytes32 governanceFlagId;    // Identifier for a governance decision/flag
    bool requiredGovernanceFlagState; // The required state (true/false) of the flag

    // Future conditions could be added here...
}


// --- Constants (Roles) ---
bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
bytes32 public constant CONFIG_MANAGER_ROLE = keccak256("CONFIG_MANAGER_ROLE");
bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");
bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");


contract QuantumVault {

    // --- State Variables ---

    // Balances: user address => lock ID => token address => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) private userTokenBalances;
    // Balances: user address => lock ID => ETH amount
    mapping(address => mapping(uint256 => uint256)) private userETHBalances;

    // Total Balances per lock: lock ID => token address => amount
    mapping(uint256 => mapping(address => uint256)) private totalLockTokenBalances;
    // Total Balances per lock: lock ID => ETH amount
    mapping(uint256 => uint256) private totalLockETHBalances;

    // Total Balances per token in the whole contract: token address => amount
    mapping(address => uint256) private totalTokenBalances;

    // Lock Configurations: lock ID => config
    mapping(uint256 => QuantumLockConfig) private quantumLockConfigs;
    uint256 private nextLockId = 1; // Start lock IDs from 1

    // Role Management: role => account => bool
    mapping(bytes32 => mapping(address => bool)) private roles;

    // Supported Tokens: token address => bool
    mapping(address => bool) private isSupportedToken;

    // Unique User Tracking for Condition 3: lock ID => user address => bool
    mapping(uint256 => mapping(address => bool)) private uniqueUsersPerLock;
    // Unique User Count for Condition 3: lock ID => count
    mapping(uint256 => uint256) private uniqueUserCount;

    // Simulated External Condition States:
    mapping(bytes32 => uint256) private oracleValues; // For Condition 2
    mapping(bytes32 => bool) private governanceFlags; // For Condition 6
    mapping(bytes32 => uint256) private randomnessValues; // For Condition 5


    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        if (!roles[role][msg.sender]) {
            revert QuantumVault__PermissionDenied();
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        // Grant initial roles to the deployer
        roles[DEFAULT_ADMIN_ROLE][msg.sender] = true;
        roles[CONFIG_MANAGER_ROLE][msg.sender] = true;
        roles[ORACLE_UPDATER_ROLE][msg.sender] = true;
        roles[GOVERNANCE_ROLE][msg.sender] = true;
        roles[TOKEN_MANAGER_ROLE][msg.sender] = true;

        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
        emit RoleGranted(CONFIG_MANAGER_ROLE, msg.sender, msg.sender);
        emit RoleGranted(ORACLE_UPDATER_ROLE, msg.sender, msg.sender);
        emit RoleGranted(GOVERNANCE_ROLE, msg.sender, msg.sender);
        emit RoleGranted(TOKEN_MANAGER_ROLE, msg.sender, msg.sender);
    }


    // --- Access Control Functions ---

    /**
     * @dev Grants a role to an account.
     * Only DEFAULT_ADMIN_ROLE can grant roles.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function addRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert QuantumVault__ZeroAddress();
        if (roles[role][account]) return; // Role already exists

        roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revokes a role from an account.
     * Only DEFAULT_ADMIN_ROLE can revoke roles.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function removeRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert QuantumVault__ZeroAddress();
        if (!roles[role][account]) revert QuantumVault__RoleDoesNotExist();

        roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @dev Returns true if `account` has `role`.
     * @param role The role to check.
     * @param account The account to check.
     */
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return roles[role][account];
    }

     /**
     * @dev Revokes a role from the calling account.
     * @param role The role to revoke.
     */
    function renounceRole(bytes32 role) external {
        if (!roles[role][msg.sender]) revert QuantumVault__RoleDoesNotExist();

        roles[role][msg.sender] = false;
        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    // --- Supported Token Management ---

    /**
     * @dev Adds an ERC-20 token to the list of supported tokens for deposits.
     * Only accounts with TOKEN_MANAGER_ROLE can call this.
     * @param token The address of the ERC-20 token contract.
     */
    function addSupportedToken(address token) external onlyRole(TOKEN_MANAGER_ROLE) {
        if (token == address(0)) revert QuantumVault__ZeroAddress();
        if (isSupportedToken[token]) revert QuantumVault__TokenAlreadySupported();

        isSupportedToken[token] = true;
        emit SupportedTokenAdded(token);
    }

    /**
     * @dev Removes an ERC-20 token from the list of supported tokens.
     * Note: Existing deposits of this token remain in the contract but cannot be withdrawn.
     * Consider migration or specific withdrawal functions for deprecated tokens if needed in a real system.
     * Only accounts with TOKEN_MANAGER_ROLE can call this.
     * @param token The address of the ERC-20 token contract.
     */
    function removeSupportedToken(address token) external onlyRole(TOKEN_MANAGER_ROLE) {
        if (token == address(0)) revert QuantumVault__ZeroAddress();
        if (!isSupportedToken[token]) revert QuantumVault__TokenNotSupported();

        isSupportedToken[token] = false;
        emit SupportedTokenRemoved(token);
    }

     /**
     * @dev Checks if a token is currently supported for deposit.
     * @param token The address of the ERC-20 token contract.
     */
    function isSupportedToken(address token) public view returns (bool) {
        return isSupportedToken[token];
    }

    // --- Quantum Lock Configuration Functions ---

    /**
     * @dev Defines a new Quantum Lock configuration.
     * Generates a new unique lock ID.
     * Only accounts with CONFIG_MANAGER_ROLE can call this.
     * @param config The QuantumLockConfig struct defining the conditions.
     * @return The newly created unique lock ID.
     */
    function defineLockConfig(QuantumLockConfig calldata config) external onlyRole(CONFIG_MANAGER_ROLE) returns (uint256) {
        uint256 newLockId = nextLockId++;
        quantumLockConfigs[newLockId] = config;
        quantumLockConfigs[newLockId].exists = true; // Mark as existing
        emit LockConfigDefined(newLockId, config.description);
        return newLockId;
    }

    /**
     * @dev Updates an existing Quantum Lock configuration.
     * Note: Careful updates are crucial. Avoid changing core conditions that might lock existing funds permanently.
     * This implementation restricts updates to prevent unexpected behavior.
     * Only accounts with CONFIG_MANAGER_ROLE can call this.
     * @param lockId The ID of the lock configuration to update.
     * @param config The new QuantumLockConfig struct.
     */
    function updateLockConfig(uint256 lockId, QuantumLockConfig calldata config) external onlyRole(CONFIG_MANAGER_ROLE) {
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();

        // Implement strict update logic: Only allow description or disabled status change.
        // Other fields are immutable once set to protect existing depositors.
        // A more complex contract might allow specific, non-breaking parameter tweaks.
        quantumLockConfigs[lockId].description = config.description;
        quantumLockConfigs[lockId].disabled = config.disabled; // Allow disabling
        // No other fields are allowed to be updated here.

        // If you needed to allow specific field updates, add checks here, e.g.:
        // if (config.requireTimestamp && quantumLockConfigs[lockId].unlockTimestamp != config.unlockTimestamp) revert QuantumVault__LockConfigUpdateRestricted();

        emit LockConfigUpdated(lockId);
    }

    /**
     * @dev Disables a Quantum Lock configuration, preventing new deposits to it.
     * Does not affect existing deposits under this lock ID (they can still withdraw if conditions are met).
     * Only accounts with CONFIG_MANAGER_ROLE can call this.
     * @param lockId The ID of the lock configuration to disable.
     */
    function disableLockConfig(uint256 lockId) external onlyRole(CONFIG_MANAGER_ROLE) {
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();
        if (quantumLockConfigs[lockId].disabled) return; // Already disabled

        quantumLockConfigs[lockId].disabled = true;
        emit LockConfigDisabled(lockId);
    }

    /**
     * @dev Retrieves the details of a specific Quantum Lock configuration.
     * @param lockId The ID of the lock configuration.
     * @return The QuantumLockConfig struct.
     */
    function getLockConfigDetails(uint256 lockId) external view returns (QuantumLockConfig memory) {
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();
        return quantumLockConfigs[lockId];
    }

    /**
     * @dev Lists the IDs of all defined Quantum Lock configurations.
     * Note: This returns IDs 1 up to the current nextLockId - 1. Clients need to check `exists` flag.
     * For very large numbers of locks, this could hit gas limits. An alternative pattern (like linked list) might be needed.
     * @return An array of all valid lock IDs.
     */
    function getLockConfigs() external view returns (uint256[] memory) {
        uint256 count = nextLockId - 1;
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = i + 1;
        }
        return ids;
    }


    // --- Condition Update Functions (Simulated External Inputs) ---

    /**
     * @dev Sets a simulated value for an oracle feed.
     * In a real system, this would be updated by a trusted oracle contract (e.g., Chainlink).
     * Only accounts with ORACLE_UPDATER_ROLE can call this.
     * @param oracleId Identifier for the oracle feed.
     * @param value The new value from the oracle.
     */
    function setOracleValue(bytes32 oracleId, uint256 value) external onlyRole(ORACLE_UPDATER_ROLE) {
        if (oracleId == bytes32(0)) revert QuantumVault__InvalidLockId(); // Using error for ID type
        oracleValues[oracleId] = value;
        emit OracleValueSet(oracleId, value);
    }

    /**
     * @dev Sets the state of a simulated governance flag.
     * In a real system, this might be tied to a DAO voting outcome.
     * Only accounts with GOVERNANCE_ROLE can call this.
     * @param flagId Identifier for the governance flag.
     * @param state The state (true/false) of the flag.
     */
    function setGovernanceFlag(bytes32 flagId, bool state) external onlyRole(GOVERNANCE_ROLE) {
         if (flagId == bytes32(0)) revert QuantumVault__InvalidLockId(); // Using error for ID type
        governanceFlags[flagId] = state;
        emit GovernanceFlagSet(flagId, state);
    }

    /**
     * @dev Sets a simulated random value associated with an ID.
     * In a real system, this would be a callback from a VRF service (e.g., Chainlink VRF).
     * Only accounts with ORACLE_UPDATER_ROLE can call this.
     * @param randomnessId Identifier for the randomness request/feed.
     * @param value The generated random value.
     */
    function triggerRandomness(bytes32 randomnessId, uint256 value) external onlyRole(ORACLE_UPDATER_ROLE) {
         if (randomnessId == bytes32(0)) revert QuantumVault__InvalidLockId(); // Using error for ID type
        randomnessValues[randomnessId] = value;
        emit RandomnessTriggered(randomnessId, value);
    }


    // --- Deposits ---

    /**
     * @dev Deposits ETH into the vault under a specific lock configuration.
     * Records the depositor for the unique user count condition.
     * @param lockId The ID of the Quantum Lock configuration to use.
     */
    function depositETH(uint256 lockId) external payable {
        if (msg.value == 0) revert QuantumVault__AmountMustBeGreaterThanZero();
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();
        if (quantumLockConfigs[lockId].disabled) revert QuantumVault__LockDisabled();

        userETHBalances[msg.sender][lockId] += msg.value;
        totalLockETHBalances[lockId] += msg.value;

        // Track unique users for this lock ID
        if (!uniqueUsersPerLock[lockId][msg.sender]) {
            uniqueUsersPerLock[lockId][msg.sender] = true;
            uniqueUserCount[lockId]++;
        }

        emit ETHDeposited(msg.sender, lockId, msg.value);
    }

    /**
     * @dev Deposits ERC-20 tokens into the vault under a specific lock configuration.
     * Requires the user to have approved this contract to spend the tokens beforehand.
     * Records the depositor for the unique user count condition.
     * @param token The address of the ERC-20 token.
     * @param lockId The ID of the Quantum Lock configuration to use.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 lockId, uint256 amount) external {
        if (amount == 0) revert QuantumVault__AmountMustBeGreaterThanZero();
        if (token == address(0)) revert QuantumVault__ZeroAddress();
        if (!isSupportedToken[token]) revert QuantumVault__UnsupportedToken();
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();
        if (quantumLockConfigs[lockId].disabled) revert QuantumVault__LockDisabled();

        // Transfer tokens from the user to the contract
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) revert QuantumVault__InsufficientBalance(); // Common ERC-20 transfer failure reason

        userTokenBalances[msg.sender][lockId][token] += amount;
        totalLockTokenBalances[lockId][token] += amount;
        totalTokenBalances[token] += amount; // Track total in contract

        // Track unique users for this lock ID
         if (!uniqueUsersPerLock[lockId][msg.sender]) {
            uniqueUsersPerLock[lockId][msg.sender] = true;
            uniqueUserCount[lockId]++;
        }

        emit ERC20Deposited(msg.sender, token, lockId, amount);
    }


    // --- Withdrawals ---

    /**
     * @dev Allows a user to withdraw ETH if the associated lock conditions are met.
     * @param lockId The ID of the Quantum Lock configuration used for deposit.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 lockId, uint256 amount) external {
        if (amount == 0) revert QuantumVault__AmountMustBeGreaterThanZero();
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();
        if (userETHBalances[msg.sender][lockId] < amount) revert QuantumVault__InsufficientBalance();

        // --- Core Logic: Check if ALL conditions for this lock ID are met ---
        if (!_areLockConditionsMet(lockId)) {
            revert QuantumVault__ConditionsNotMet();
        }
        // --------------------------------------------------------------------

        userETHBalances[msg.sender][lockId] -= amount;
        totalLockETHBalances[lockId] -= amount;

        // Transfer ETH to the user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert QuantumVault__InsufficientBalance(); // Should not happen if balance check passed, but good practice

        emit ETHWithdrawn(msg.sender, lockId, amount);
    }

     /**
     * @dev Allows a user to withdraw ERC-20 tokens if the associated lock conditions are met.
     * @param token The address of the ERC-20 token.
     * @param lockId The ID of the Quantum Lock configuration used for deposit.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address token, uint256 lockId, uint256 amount) external {
        if (amount == 0) revert QuantumVault__AmountMustBeGreaterThanZero();
        if (token == address(0)) revert QuantumVault__ZeroAddress();
        // Withdrawal is possible even if token is no longer supported, assuming it's still in the contract
        // if (!isSupportedToken[token]) revert QuantumVault__UnsupportedToken(); // Optional: could restrict withdrawal to supported tokens only
        if (!quantumLockConfigs[lockId].exists) revert QuantumVault__InvalidLockId();
        if (userTokenBalances[msg.sender][lockId][token] < amount) revert QuantumVault__InsufficientBalance();

        // --- Core Logic: Check if ALL conditions for this lock ID are met ---
         if (!_areLockConditionsMet(lockId)) {
            revert QuantumVault__ConditionsNotMet();
        }
        // --------------------------------------------------------------------

        userTokenBalances[msg.sender][lockId][token] -= amount;
        totalLockTokenBalances[lockId][token] -= amount;
        totalTokenBalances[token] -= amount; // Update total in contract

        // Transfer tokens to the user
        bool success = IERC20(token).transfer(msg.sender, amount);
         if (!success) revert QuantumVault__InsufficientBalance(); // Should not happen if balance check passed

        emit ERC20Withdrawn(msg.sender, token, lockId, amount);
    }


    // --- View Functions ---

    /**
     * @dev Gets the ETH balance of a user for a specific lock configuration.
     * @param lockId The lock ID.
     * @param user The user's address.
     * @return The ETH balance.
     */
    function getUserETHBalance(uint256 lockId, address user) external view returns (uint256) {
        // No need to check lockId existence for balance lookup, will just return 0
        return userETHBalances[user][lockId];
    }

    /**
     * @dev Gets the ERC-20 token balance of a user for a specific lock configuration.
     * @param token The token address.
     * @param lockId The lock ID.
     * @param user The user's address.
     * @return The token balance.
     */
    function getUserTokenBalance(address token, uint256 lockId, address user) external view returns (uint256) {
         // No need to check lockId existence for balance lookup, will just return 0
        return userTokenBalances[user][lockId][token];
    }

    /**
     * @dev Gets the total ETH balance held under a specific lock configuration by all users.
     * @param lockId The lock ID.
     * @return The total ETH balance for the lock.
     */
    function getTotalLockETHBalance(uint256 lockId) external view returns (uint256) {
        // No need to check lockId existence, will just return 0
        return totalLockETHBalances[lockId];
    }

    /**
     * @dev Gets the total ERC-20 token balance held under a specific lock configuration by all users.
     * @param token The token address.
     * @param lockId The lock ID.
     * @return The total token balance for the lock.
     */
    function getTotalLockTokenBalance(address token, uint256 lockId) external view returns (uint256) {
         // No need to check lockId existence, will just return 0
        return totalLockTokenBalances[lockId][token];
    }

    /**
     * @dev Gets the total balance of a specific ERC-20 token held in the contract across all locks.
     * This should match the actual contract balance of the token if transfers were successful.
     * @param token The token address.
     * @return The total token balance in the contract.
     */
    function getTotalTokenBalance(address token) external view returns (uint256) {
        return totalTokenBalances[token];
    }

    /**
     * @dev Checks if the conditions for a specific Quantum Lock configuration are currently met.
     * @param lockId The ID of the lock configuration to check.
     * @return True if all required conditions are met, false otherwise.
     */
    function checkLockStatus(uint256 lockId) external view returns (bool) {
        if (!quantumLockConfigs[lockId].exists) {
            // Revert or return false? Let's return false for a view function checking status
            return false;
        }
        return _areLockConditionsMet(lockId);
    }

     /**
     * @dev Gets the current simulated value for a given oracle ID.
     * @param oracleId Identifier for the oracle feed.
     * @return The current oracle value.
     */
    function getOracleValue(bytes32 oracleId) external view returns (uint256) {
        return oracleValues[oracleId];
    }

     /**
     * @dev Gets the current state for a given governance flag ID.
     * @param flagId Identifier for the governance flag.
     * @return The current flag state.
     */
    function getGovernanceFlag(bytes32 flagId) external view returns (bool) {
        return governanceFlags[flagId];
    }

    /**
     * @dev Gets the count of unique addresses that have deposited to a specific lock ID.
     * Used for the minimum unique users condition.
     * @param lockId The lock ID.
     * @return The number of unique depositors.
     */
    function getUniqueUserCountForLock(uint256 lockId) external view returns (uint256) {
        // No need to check lockId existence, will just return 0
        return uniqueUserCount[lockId];
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to check if ALL conditions for a given lock ID are met.
     * Assumes lockId exists (checked by external callers like withdraw functions).
     * @param lockId The ID of the lock configuration to check.
     * @return True if all required conditions are met, false otherwise.
     */
    function _areLockConditionsMet(uint256 lockId) internal view returns (bool) {
        QuantumLockConfig storage config = quantumLockConfigs[lockId];

        // Condition 1: Timelock
        if (config.requireTimestamp) {
            if (block.timestamp < config.unlockTimestamp) {
                return false; // Time condition not met
            }
        }

        // Condition 2: External Oracle Value
        if (config.requireOracleValue) {
             if (config.oracleId == bytes32(0)) revert QuantumVault__OracleIdNotSet();
            // Check if oracle value is set AND meets minimum
            if (oracleValues[config.oracleId] < config.minOracleValue) {
                return false; // Oracle condition not met
            }
        }

        // Condition 3: Minimum Unique Depositors
        if (config.requireMinUsers) {
            if (uniqueUserCount[lockId] < config.minUniqueUsers) {
                return false; // Unique user count condition not met
            }
        }

        // Condition 4: Minimum Required Token Balance in Contract (for this lock)
        if (config.requireMinTokenBalance) {
            if (config.requiredTokenForLockCheck == address(0)) revert QuantumVault__UnsupportedToken(); // Should be set if requireMinTokenBalance is true
            // Check if the total balance of the required token *for this specific lock ID* meets the minimum
            if (totalLockTokenBalances[lockId][config.requiredTokenForLockCheck] < config.minRequiredTokenBalance) {
                 return false; // Minimum token balance condition not met
            }
        }

        // Condition 5: Randomness Check
        if (config.requireRandomness) {
             if (config.randomnessId == bytes32(0)) revert QuantumVault__RandomnessIdNotSet();
            // Check if a random value is set AND meets the modulo target
            uint256 randomValue = randomnessValues[config.randomnessId];
            // If the randomness value hasn't been set yet (e.g., VRF hasn't called back), assume condition not met
            if (randomValue == 0 && config.randomnessModulus != 0 && config.randomnessTarget != 0) {
                 // This check might need refinement depending on VRF implementation.
                 // For this simulation, if randomnessId is set and value is 0, assume not met UNLESS target is 0
                 return false;
            }
            if (config.randomnessModulus > 0 && (randomValue % config.randomnessModulus != config.randomnessTarget)) {
                return false; // Randomness condition not met
            }
            // If modulus is 0, the condition is effectively true if randomnessId is set and value is non-zero?
            // Or if modulus is 0, it means no check? Let's assume modulus > 0 is required if requireRandomness is true.
             if (config.randomnessModulus == 0 && config.requireRandomness) {
                 // Invalid config: requires randomness but modulus is 0. Treat as not met.
                 return false;
             }
        }

        // Condition 6: Governance Flag
        if (config.requireGovernanceFlag) {
             if (config.governanceFlagId == bytes32(0)) revert QuantumVault__GovernanceFlagIdNotSet();
            if (governanceFlags[config.governanceFlagId] != config.requiredGovernanceFlagState) {
                return false; // Governance flag condition not met
            }
        }

        // If we reached here, ALL required conditions are met
        return true;
    }
}
```