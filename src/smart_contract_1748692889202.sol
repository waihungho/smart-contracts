Okay, let's design an advanced smart contract. Instead of a simple vault or token, let's create a contract that acts as a `QuantumVault` – a system for managing multi-asset deposits with complex, state-dependent access controls, time-locks, conditional releases potentially tied to external data (simulated via oracle interaction), and a fine-grained delegation/permission system. This incorporates several advanced concepts like state machines, complex access control, conditional logic, and external dependency simulation.

**Concept:** QuantumVault is a secure vault capable of holding various ERC-20 and ERC-721 tokens. Access to deposited assets is governed by a state machine, granular permissions, time-locks, and configurable release conditions that can depend on time, external data (simulated oracle), or proofs.

**Advanced Concepts Used:**
1.  **State Machine:** The contract operates in distinct states (`Active`, `Paused`, `ConditionalReleaseOnly`, `Emergency`), changing function behavior.
2.  **Complex Access Control:** Beyond simple owner, it uses roles (Admin, Manager) and granular permissions that can be granted/revoked for specific actions.
3.  **Delegated Access:** Users can delegate specific withdrawal rights (with limits and expiry) to other addresses.
4.  **Conditional Release:** Assets can be configured to only be withdrawable when specific, pre-defined conditions are met (time-based, oracle-data-based, proof-based).
5.  **Simulated Oracle Interaction:** The contract has a hook for an oracle address and allows conditions to *require* external data/proofs, although the actual *verification* logic is simplified for this example contract's scope.
6.  **Multi-Asset Management:** Handles both ERC-20 (fungible) and ERC-721 (non-fungible) tokens.
7.  **Dynamic Configuration:** Fees, oracle address, and release conditions can be updated.
8.  **Emergency Mechanism:** A dedicated state and function for admins to recover assets in critical situations.
9.  **Permission Granularity:** Actions require specific permissions, not just roles.

---

**Outline and Function Summary:**

**Contract Name:** `QuantumVault`

**Description:** A multi-asset vault with state-dependent access, roles, granular permissions, delegation, and configurable conditional release mechanisms.

**States:**
*   `Active`: Normal operation.
*   `Paused`: Most operations disabled, except admin/emergency.
*   `ConditionalReleaseOnly`: Only conditional withdrawals are allowed.
*   `Emergency`: Only admin emergency withdrawals are allowed.

**Roles:**
*   `ADMIN_ROLE`: Highest privileges, can manage roles, permissions, state, emergency.
*   `MANAGER_ROLE`: Can perform certain configuration tasks but not critical state changes or emergency withdrawals.

**Permissions:**
*   `PERM_SET_STATE`: Can change the vault's state.
*   `PERM_CONFIG`: Can set fees, oracle, etc.
*   `PERM_WITHDRAW_REGULAR`: Can perform non-conditional withdrawals (if state allows).
*   `PERM_SET_CONDITIONS`: Can configure conditional release rules for assets they own in the vault.
*   `PERM_DELEGATE`: Can delegate withdrawal rights to others.
*   `PERM_EMERGENCY_WITHDRAW`: Can trigger admin emergency withdrawals (only Admin role has this).

**Structs:**
*   `ReleaseCondition`: Defines a single condition requirement (time, oracle, proof, token balance).
*   `Delegation`: Tracks details of a delegated withdrawal permission.

**State Variables:**
*   Vault state, fee percentage, oracle address.
*   Mappings for ERC20 balances and ERC721 ownership within the vault.
*   Mappings for roles, user permissions, delegated withdrawals.
*   Mapping for asset-specific release conditions.
*   Allowed token lists (optional, added for better practice).

**Events:**
*   `DepositERC20`, `DepositERC721`
*   `WithdrawERC20`, `WithdrawERC721`
*   `VaultStateChanged`
*   `RoleGranted`, `RoleRevoked`
*   `PermissionGranted`, `PermissionRevoked`
*   `DelegationSet`, `DelegationRevoked`
*   `ConditionalReleaseConfigured`
*   `ConditionalWithdrawalTriggered`
*   `FeePercentageUpdated`, `OracleAddressUpdated`
*   `EmergencyWithdrawal`

**Error Handling:** Custom errors for clarity.

**Modifiers:**
*   `onlyRole`: Checks if the caller has a specific role.
*   `onlyPermission`: Checks if the caller has a specific permission.
*   `requireVaultState`: Checks if the vault is in a required state.

**Functions (>= 20):**

1.  `constructor()`: Initializes the contract, sets the initial admin(s) and state.
2.  `setVaultState(VaultState newState)`: (Admin/`PERM_SET_STATE` only) Changes the operational state of the vault.
3.  `addAdmin(address account)`: (Admin only) Grants the ADMIN_ROLE to an account.
4.  `removeAdmin(address account)`: (Admin only) Revokes the ADMIN_ROLE from an account.
5.  `addManager(address account)`: (Admin only) Grants the MANAGER_ROLE to an account.
6.  `removeManager(address account)`: (Admin only) Revokes the MANAGER_ROLE from an account.
7.  `grantPermission(address account, Permission permission)`: (Admin only) Grants a specific permission to an account.
8.  `revokePermission(address account, Permission permission)`: (Admin only) Revokes a specific permission from an account.
9.  `depositERC20(address token, uint256 amount)`: Allows users to deposit ERC20 tokens into their vault balance.
10. `depositERC721(address token, uint256 tokenId)`: Allows users to deposit ERC721 tokens into the vault, tracking ownership.
11. `withdrawERC20(address token, uint256 amount)`: (Requires `PERM_WITHDRAW_REGULAR`) Allows withdrawal of ERC20 tokens based on user balance, subject to vault state.
12. `withdrawERC721(address token, uint256 tokenId)`: (Requires `PERM_WITHDRAW_REGULAR`) Allows withdrawal of a specific ERC721 token, subject to vault state and ownership.
13. `delegateWithdrawalPermission(address delegatee, address token, uint256 maxAmount, uint256 duration)`: (Requires `PERM_DELEGATE`) Delegates the right to withdraw a certain ERC20 token amount for a limited time to another address.
14. `revokeDelegation(address delegatee, address token)`: (Requires `PERM_DELEGATE`) Revokes an active delegation.
15. `delegatedWithdrawalERC20(address owner, address token, uint256 amount)`: Allows a delegatee to withdraw ERC20 tokens on behalf of the `owner`, based on a valid delegation.
16. `setAssetReleaseConditions(address token, uint256 idOrZero, ReleaseCondition[] conditions)`: (Requires `PERM_SET_CONDITIONS`) Configures the set of conditions required to release a specific asset (ERC20 or ERC721). `idOrZero` is 0 for ERC20.
17. `checkAssetReleaseConditions(address token, uint256 idOrZero, bytes memory optionalProof)`: (View function) Checks if the configured conditions for an asset are currently met (simulated checks for oracle/proof).
18. `conditionalWithdrawERC20(address token, uint256 amount, bytes memory optionalProof)`: Allows withdrawal of ERC20 if the defined conditions for that token are met.
19. `conditionalWithdrawERC721(address token, uint256 tokenId, bytes memory optionalProof)`: Allows withdrawal of ERC721 if the defined conditions for that token are met.
20. `emergencyWithdrawERC20Admin(address token, uint256 amount)`: (Admin/`PERM_EMERGENCY_WITHDRAW`, requires Emergency state) Allows admin to forcibly withdraw ERC20 from the contract.
21. `emergencyWithdrawERC721Admin(address token, uint256 tokenId)`: (Admin/`PERM_EMERGENCY_WITHDRAW`, requires Emergency state) Allows admin to forcibly withdraw ERC721 from the contract.
22. `setFeePercentage(uint256 basisPoints)`: (Manager/`PERM_CONFIG` only) Sets a fee percentage (e.g., on conditional withdrawals).
23. `setOracleAddress(address oracle)`: (Manager/`PERM_CONFIG` only) Sets the address of the trusted oracle contract (simulated).
24. `withdrawFees(address token, uint256 amount)`: (Admin/`PERM_CONFIG` only) Allows withdrawing collected fees.
25. `getUserERC20Balance(address user, address token)`: (View function) Gets a user's balance of a specific ERC20 token within the vault.
26. `hasUserERC721(address user, address token, uint256 tokenId)`: (View function) Checks if a user owns a specific ERC721 token within the vault. (Getting *all* ERC721 IDs for a user is gas-prohibitive in a single contract function and typically done by indexing events off-chain).
27. `getVaultState()`: (View function) Gets the current state of the vault.
28. `getAssetReleaseConditions(address token, uint256 idOrZero)`: (View function) Gets the configured release conditions for an asset.
29. `getDelegation(address owner, address delegatee, address token)`: (View function) Gets details of a specific delegation.
30. `hasRole(address account, Role role)`: (View function) Checks if an account has a specific role.
31. `hasPermission(address account, Permission permission)`: (View function) Checks if an account has a specific permission.
32. `addAllowedToken(address token, bool isERC721)`: (Admin only) Marks a token address as explicitly allowed for deposit/withdrawal.
33. `removeAllowedToken(address token)`: (Admin only) Removes a token from the allowed list.
34. `isTokenAllowed(address token)`: (View function) Checks if a token is on the allowed list.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title QuantumVault
 * @dev An advanced multi-asset vault with state-dependent access control,
 *      roles, granular permissions, delegation, and conditional release.
 *      Uses a state machine, simulates oracle interaction for conditions,
 *      and manages both ERC-20 and ERC-721 tokens.
 */

// Outline:
// 1. State Machine (Enum VaultState)
// 2. Roles (Enum Role) and Permission (Enum Permission) definitions
// 3. Custom Error definitions
// 4. Interfaces (IERC20, IERC721)
// 5. Data Structures (Struct ReleaseCondition, Struct Delegation)
// 6. State Variables (Vault state, Balances, Ownership, Roles, Permissions, Delegations, Conditions, Config)
// 7. Events
// 8. Modifiers (onlyRole, onlyPermission, requireVaultState, isAllowedToken)
// 9. Constructor
// 10. Core Vault Logic (Deposit, Withdraw - Regular, Delegated, Conditional, Emergency)
// 11. Access Control & Permission Management (Add/Remove Roles, Grant/Revoke Permissions)
// 12. Delegation Management
// 13. Conditional Release Configuration & Checking
// 14. Configuration Management (Fees, Oracle)
// 15. Allowed Token Management
// 16. View Functions (Get balances, states, conditions, etc.)

// Function Summary:
// constructor() - Initializes vault with admin and default state.
// setVaultState(VaultState newState) - Changes vault state (Admin/PERM_SET_STATE).
// addAdmin(address account) - Adds an Admin role (Admin only).
// removeAdmin(address account) - Removes an Admin role (Admin only).
// addManager(address account) - Adds a Manager role (Admin only).
// removeManager(address account) - Removes a Manager role (Admin only).
// grantPermission(address account, Permission permission) - Grants a specific permission (Admin only).
// revokePermission(address account, Permission permission) - Revokes a specific permission (Admin only).
// depositERC20(address token, uint256 amount) - Deposits ERC20 into user's vault balance.
// depositERC721(address token, uint256 tokenId) - Deposits ERC721, tracks ownership.
// withdrawERC20(address token, uint256 amount) - Regular ERC20 withdrawal (PERM_WITHDRAW_REGULAR).
// withdrawERC721(address token, uint256 tokenId) - Regular ERC721 withdrawal (PERM_WITHDRAW_REGULAR).
// delegateWithdrawalPermission(address delegatee, address token, uint256 maxAmount, uint256 duration) - Delegates ERC20 withdrawal rights (PERM_DELEGATE).
// revokeDelegation(address delegatee, address token) - Revokes delegation (PERM_DELEGATE).
// delegatedWithdrawalERC20(address owner, address token, uint256 amount) - Executes delegated ERC20 withdrawal.
// setAssetReleaseConditions(address token, uint256 idOrZero, ReleaseCondition[] conditions) - Sets conditions for asset release (PERM_SET_CONDITIONS).
// checkAssetReleaseConditions(address token, uint256 idOrZero, bytes memory optionalProof) - Checks if release conditions are met (View).
// conditionalWithdrawERC20(address token, uint256 amount, bytes memory optionalProof) - Conditional ERC20 withdrawal.
// conditionalWithdrawERC721(address token, uint256 tokenId, bytes memory optionalProof) - Conditional ERC721 withdrawal.
// emergencyWithdrawERC20Admin(address token, uint256 amount) - Admin emergency ERC20 withdrawal (Admin/PERM_EMERGENCY_WITHDRAW, Emergency state).
// emergencyWithdrawERC721Admin(address token, uint256 tokenId) - Admin emergency ERC721 withdrawal (Admin/PERM_EMERGENCY_WITHDRAW, Emergency state).
// setFeePercentage(uint256 basisPoints) - Sets withdrawal fee (Manager/PERM_CONFIG).
// setOracleAddress(address oracle) - Sets oracle address (Manager/PERM_CONFIG).
// withdrawFees(address token, uint256 amount) - Withdraws collected fees (Admin/PERM_CONFIG).
// getUserERC20Balance(address user, address token) - Get user's ERC20 balance (View).
// hasUserERC721(address user, address token, uint256 tokenId) - Check user's ERC721 ownership (View).
// getVaultState() - Get current vault state (View).
// getAssetReleaseConditions(address token, uint256 idOrZero) - Get asset conditions (View).
// getDelegation(address owner, address delegatee, address token) - Get delegation details (View).
// hasRole(address account, Role role) - Check if account has role (View).
// hasPermission(address account, Permission permission) - Check if account has permission (View).
// addAllowedToken(address token, bool isERC721) - Adds a token to the allowed list (Admin only).
// removeAllowedToken(address token) - Removes a token from the allowed list (Admin only).
// isTokenAllowed(address token) - Checks if a token is allowed (View).

contract QuantumVault {
    using Address for address;

    enum VaultState {
        Active,
        Paused,
        ConditionalReleaseOnly,
        Emergency
    }

    enum Role {
        ADMIN_ROLE,
        MANAGER_ROLE
    }

    enum Permission {
        PERM_SET_STATE,
        PERM_CONFIG,
        PERM_WITHDRAW_REGULAR,
        PERM_SET_CONDITIONS,
        PERM_DELEGATE,
        PERM_EMERGENCY_WITHDRAW // Note: Only granted to Admin role internally
    }

    error Unauthorized(address account, string requiredRoleOrPermission);
    error InvalidState(VaultState currentState, VaultState requiredState);
    error ZeroAddress();
    error TransferFailed();
    error InsufficientBalance(uint256 requested, uint256 available);
    error ERC721NotOwnedByUser(address user, address token, uint256 tokenId);
    error ERC721NotOwnedByVault(address token, uint256 tokenId);
    error ERC721TransferFailed(address token, uint256 tokenId);
    error DelegationNotFound();
    error DelegationExpired();
    error DelegationAmountExceeded();
    error ConditionsNotMet();
    error InvalidConditionalProof();
    error AssetNotAllowed();
    error InvalidAmount();

    struct ReleaseCondition {
        bool requiresOracleData; // True if oracle data is needed
        bytes requiredOracleProof; // Data/proof expected from oracle (or off-chain proof)
        uint256 requiredBlockTimestamp; // Minimum block timestamp
        uint256 requiredBlockNumber; // Minimum block number
        address requiredERC20Token; // Specific ERC20 token required in caller's wallet (outside vault)
        uint256 requiredERC20Amount; // Minimum amount of requiredERC20Token
        address requiredERC721Token; // Specific ERC721 token required in caller's wallet (outside vault)
        uint256 requiredERC721TokenId; // Specific ID of requiredERC721Token
        bytes proofVerifierData; // Data for an external verifier contract (simulated)
        bool negateCondition; // If true, the condition must *not* be met
    }

    struct Delegation {
        uint256 maxAmount;
        uint256 expiry; // Unix timestamp
        uint256 withdrawnAmount; // Amount already withdrawn using this delegation
    }

    // --- State Variables ---
    VaultState private _vaultState;
    address private _oracleAddress;
    uint256 private _feePercentageBasisPoints; // e.g., 100 for 1%

    mapping(address => mapping(address => uint256)) private _erc20Balances; // user => token => amount
    // ERC721 ownership within the vault. We track who deposited it.
    // This is simplified; robust ERC721 handling might need more complex tracking
    mapping(address => mapping(uint256 => address)) private _erc721TokenOwners; // token => tokenId => user owner
    mapping(address => mapping(address => bool)) private _erc721UserHasToken; // user => token => tokenId => exists (for quick check)

    mapping(address => mapping(Role => bool)) private _roles; // account => role => hasRole
    mapping(address => mapping(Permission => bool)) private _userPermissions; // account => permission => hasPermission

    mapping(address => mapping(address => mapping(address => Delegation))) private _delegatedWithdrawals; // owner => delegatee => token => Delegation

    // Conditions for asset release. key: token address, inner key: tokenId (0 for ERC20)
    mapping(address => mapping(uint256 => ReleaseCondition[])) private _assetReleaseConditions;

    mapping(address => bool) private _allowedTokens; // token => isAllowed
    mapping(address => bool) private _isERC721Token; // token => isERC721 (needed for type checking)
    mapping(address => uint256) private _collectedFeesERC20; // token => amount

    // --- Events ---
    event DepositERC20(address indexed user, address indexed token, uint256 amount);
    event DepositERC721(address indexed user, address indexed token, uint256 tokenId);
    event WithdrawERC20(address indexed user, address indexed token, uint256 amount);
    event WithdrawERC721(address indexed user, address indexed token, uint256 tokenId);
    event VaultStateChanged(VaultState oldState, VaultState newState);
    event RoleGranted(address indexed account, Role indexed role);
    event RoleRevoked(address indexed account, Role indexed role);
    event PermissionGranted(address indexed account, Permission indexed permission);
    event PermissionRevoked(address indexed account, Permission indexed permission);
    event DelegationSet(address indexed owner, address indexed delegatee, address indexed token, uint256 maxAmount, uint256 expiry);
    event DelegationRevoked(address indexed owner, address indexed delegatee, address indexed token);
    event ConditionalReleaseConfigured(address indexed token, uint256 indexed idOrZero);
    event ConditionalWithdrawalTriggered(address indexed user, address indexed token, uint256 indexed idOrZero, uint256 amount); // amount only relevant for ERC20
    event FeePercentageUpdated(uint256 basisPoints);
    event OracleAddressUpdated(address indexed oracle);
    event EmergencyWithdrawal(address indexed admin, address indexed token, uint256 amountOrId);
    event FeesWithdrawn(address indexed admin, address indexed token, uint256 amount);
    event AllowedTokenAdded(address indexed token, bool isERC721);
    event AllowedTokenRemoved(address indexed token);

    // --- Modifiers ---
    modifier onlyRole(Role role) {
        if (!_roles[msg.sender][role]) {
            revert Unauthorized(msg.sender, string(abi.encodePacked("Role:", uint8(role))));
        }
        _;
    }

    modifier onlyPermission(Permission permission) {
        if (!_userPermissions[msg.sender][permission]) {
            revert Unauthorized(msg.sender, string(abi.encodePacked("Permission:", uint8(permission))));
        }
        _;
    }

    modifier requireVaultState(VaultState requiredState) {
        if (_vaultState != requiredState) {
            revert InvalidState(_vaultState, requiredState);
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (!_allowedTokens[token]) {
            revert AssetNotAllowed();
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        _vaultState = VaultState.Active;
        _roles[msg.sender][Role.ADMIN_ROLE] = true; // Grant initial admin role
        // Grant all initial permissions to the initial admin
        _userPermissions[msg.sender][Permission.PERM_SET_STATE] = true;
        _userPermissions[msg.sender][Permission.PERM_CONFIG] = true;
        _userPermissions[msg.sender][Permission.PERM_WITHDRAW_REGULAR] = true;
        _userPermissions[msg.sender][Permission.PERM_SET_CONDITIONS] = true;
        _userPermissions[msg.sender][Permission.PERM_DELEGATE] = true;
        _userPermissions[msg.sender][Permission.PERM_EMERGENCY_WITHDRAW] = true; // Grant emergency permission to Admin

        emit RoleGranted(msg.sender, Role.ADMIN_ROLE);
        emit PermissionGranted(msg.sender, Permission.PERM_SET_STATE);
        emit PermissionGranted(msg.sender, Permission.PERM_CONFIG);
        emit PermissionGranted(msg.sender, Permission.PERM_WITHDRAW_REGULAR);
        emit PermissionGranted(msg.sender, Permission.PERM_SET_CONDITIONS);
        emit PermissionGranted(msg.sender, Permission.PERM_DELEGATE);
        emit PermissionGranted(msg.sender, Permission.PERM_EMERGENCY_WITHDRAW);
    }

    // --- Core Vault Logic ---

    /**
     * @dev Changes the state of the vault. Affects allowed operations.
     * @param newState The target state.
     */
    function setVaultState(VaultState newState) external onlyRole(Role.ADMIN_ROLE) onlyPermission(Permission.PERM_SET_STATE) {
        VaultState oldState = _vaultState;
        _vaultState = newState;
        emit VaultStateChanged(oldState, newState);
    }

    /**
     * @dev Deposits ERC20 tokens into the caller's balance in the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount to deposit.
     */
    function depositERC20(address token, uint256 amount) external isAllowedToken(token) {
        if (amount == 0) revert InvalidAmount();
        if (!token.isContract()) revert ZeroAddress(); // Basic check

        // require(IERC20(token).transferFrom(msg.sender, address(this), amount), "TransferFrom failed"); // Standard OZ check
         bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
         if (!success) revert TransferFailed();

        _erc20Balances[msg.sender][token] += amount;
        emit DepositERC20(msg.sender, token, amount);
    }

    /**
     * @dev Deposits an ERC721 token into the vault. The vault becomes the owner,
     *      but contract tracks original user owner internally.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to deposit.
     */
    function depositERC721(address token, uint256 tokenId) external isAllowedToken(token) {
        if (!token.isContract()) revert ZeroAddress(); // Basic check
        // Check if the token address is actually configured as ERC721
        if (!_isERC721Token[token]) revert AssetNotAllowed();

        // require(IERC721(token).transferFrom(msg.sender, address(this), tokenId), "ERC721 TransferFrom failed"); // Standard OZ check
        try IERC721(token).transferFrom(msg.sender, address(this), tokenId) {} catch {
             revert ERC721TransferFailed(token, tokenId);
        }


        // Check if the token is already owned by the vault (shouldn't happen if transferFrom succeeds from user)
        // Or if our internal tracking is wrong.
        if (_erc721TokenOwners[token][tokenId] != address(0)) {
             // This state indicates an internal inconsistency or a malicious attempt.
             // Revert or handle appropriately - reverting is safer.
             revert ERC721NotOwnedByVault(token, tokenId);
        }

        _erc721TokenOwners[token][tokenId] = msg.sender;
        _erc721UserHasToken[msg.sender][token][tokenId] = true; // Track existence for user
        emit DepositERC721(msg.sender, token, tokenId);
    }


    /**
     * @dev Withdraws ERC20 tokens from the caller's balance, subject to state and permission.
     * @param token The address of the ERC20 token.
     * @param amount The amount to withdraw.
     */
    function withdrawERC20(address token, uint256 amount) external onlyPermission(Permission.PERM_WITHDRAW_REGULAR) requireVaultState(VaultState.Active) isAllowedToken(token) {
        if (amount == 0) revert InvalidAmount();
        if (!token.isContract()) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC20

        uint256 userBalance = _erc20Balances[msg.sender][token];
        if (userBalance < amount) {
            revert InsufficientBalance(amount, userBalance);
        }

        _erc20Balances[msg.sender][token] -= amount;
        // require(IERC20(token).transfer(msg.sender, amount), "Transfer failed"); // Standard OZ check
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();

        emit WithdrawERC20(msg.sender, token, amount);
    }

     /**
     * @dev Withdraws a specific ERC721 token, subject to state, permission, and ownership.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to withdraw.
     */
    function withdrawERC721(address token, uint256 tokenId) external onlyPermission(Permission.PERM_WITHDRAW_REGULAR) requireVaultState(VaultState.Active) isAllowedToken(token) {
         if (!token.isContract()) revert ZeroAddress();
         if (!_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC721

        if (_erc721TokenOwners[token][tokenId] != msg.sender) {
            revert ERC721NotOwnedByUser(msg.sender, token, tokenId);
        }

        // Check if the vault actually owns it globally (should be true if _erc721TokenOwners is correct)
        if (IERC721(token).ownerOf(tokenId) != address(this)) {
             revert ERC721NotOwnedByVault(token, tokenId);
        }

        // Clean up internal tracking FIRST in case external transfer fails
        delete _erc721TokenOwners[token][tokenId];
        _erc721UserHasToken[msg.sender][token][tokenId] = false;

        // require(IERC721(token).transferFrom(address(this), msg.sender, tokenId), "ERC721 Transfer failed"); // Standard OZ check
         try IERC721(token).transferFrom(address(this), msg.sender, tokenId) {} catch {
             // If transfer fails, attempt to restore internal tracking
             _erc721TokenOwners[token][tokenId] = msg.sender;
             _erc721UserHasToken[msg.sender][token][tokenId] = true;
             revert ERC721TransferFailed(token, tokenId);
        }

        emit WithdrawERC721(msg.sender, token, tokenId);
    }


    /**
     * @dev Allows a delegatee to withdraw ERC20 on behalf of the owner, based on a delegation.
     *      Subject to delegation limits, expiry, and vault state (Active or ConditionalReleaseOnly).
     * @param owner The address of the original asset owner in the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount to withdraw.
     */
    function delegatedWithdrawalERC20(address owner, address token, uint256 amount)
        external
        requireVaultState(VaultState.Active) // Allow delegation in Active or
        requireVaultState(VaultState.ConditionalReleaseOnly) // in ConditionalReleaseOnly
        isAllowedToken(token)
    {
        if (amount == 0) revert InvalidAmount();
         if (!token.isContract()) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC20

        Delegation storage delegation = _delegatedWithdrawals[owner][msg.sender][token];

        if (delegation.expiry == 0 || block.timestamp > delegation.expiry) {
            revert DelegationExpired();
        }
        if (delegation.maxAmount < delegation.withdrawnAmount + amount) {
            revert DelegationAmountExceeded();
        }

        uint256 ownerBalance = _erc20Balances[owner][token];
        if (ownerBalance < amount) {
            revert InsufficientBalance(amount, ownerBalance);
        }

        // Apply fee (example: 1% fee on delegated withdrawals)
        uint256 feeAmount = (amount * _feePercentageBasisPoints) / 10000;
        uint256 amountToSend = amount - feeAmount;

        _erc20Balances[owner][token] -= amount; // Deduct from owner's balance
        _collectedFeesERC20[token] += feeAmount; // Collect fee
        delegation.withdrawnAmount += amount; // Track withdrawn amount for this delegation

        // require(IERC20(token).transfer(msg.sender, amountToSend), "Transfer failed"); // Standard OZ check
         bool success = IERC20(token).transfer(msg.sender, amountToSend);
        if (!success) {
            // Attempt to revert state changes if transfer fails
            _erc20Balances[owner][token] += amount;
            _collectedFeesERC20[token] -= feeAmount;
            delegation.withdrawnAmount -= amount;
             revert TransferFailed();
        }


        emit WithdrawERC20(owner, token, amount); // Event notes owner, not delegatee
        // Could add a specific DelegationWithdrawal event if needed
    }

    /**
     * @dev Allows withdrawal of ERC20 if defined conditions are met, subject to state.
     *      Fees may apply.
     * @param token The address of the ERC20 token.
     * @param amount The amount to withdraw.
     * @param optionalProof Optional bytes data required by a condition check.
     */
    function conditionalWithdrawERC20(address token, uint256 amount, bytes memory optionalProof)
        external
        requireVaultState(VaultState.Active) // Allow conditional in Active or
        requireVaultState(VaultState.ConditionalReleaseOnly) // in ConditionalReleaseOnly
        isAllowedToken(token)
    {
        if (amount == 0) revert InvalidAmount();
         if (!token.isContract()) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC20

        if (!checkAssetReleaseConditions(token, 0, optionalProof)) { // 0 for ERC20
            revert ConditionsNotMet();
        }

        uint256 userBalance = _erc20Balances[msg.sender][token];
        if (userBalance < amount) {
            revert InsufficientBalance(amount, userBalance);
        }

        // Apply fee on conditional withdrawals
        uint256 feeAmount = (amount * _feePercentageBasisPoints) / 10000;
        uint256 amountToSend = amount - feeAmount;

        _erc20Balances[msg.sender][token] -= amount;
        _collectedFeesERC20[token] += feeAmount;

        // require(IERC20(token).transfer(msg.sender, amountToSend), "Transfer failed"); // Standard OZ check
        bool success = IERC20(token).transfer(msg.sender, amountToSend);
        if (!success) {
            // Attempt to revert state changes if transfer fails
             _erc20Balances[msg.sender][token] += amount;
             _collectedFeesERC20[token] -= feeAmount;
            revert TransferFailed();
        }

        emit ConditionalWithdrawalTriggered(msg.sender, token, 0, amount);
        emit WithdrawERC20(msg.sender, token, amount);
    }

    /**
     * @dev Allows withdrawal of ERC721 if defined conditions are met, subject to state.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to withdraw.
     * @param optionalProof Optional bytes data required by a condition check.
     */
    function conditionalWithdrawERC721(address token, uint256 tokenId, bytes memory optionalProof)
        external
        requireVaultState(VaultState.Active) // Allow conditional in Active or
        requireVaultState(VaultState.ConditionalReleaseOnly) // in ConditionalReleaseOnly
        isAllowedToken(token)
    {
         if (!token.isContract()) revert ZeroAddress();
         if (!_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC721

        if (_erc721TokenOwners[token][tokenId] != msg.sender) {
            revert ERC721NotOwnedByUser(msg.sender, token, tokenId);
        }

        if (!checkAssetReleaseConditions(token, tokenId, optionalProof)) {
            revert ConditionsNotMet();
        }

        // Check if the vault actually owns it globally (should be true if _erc721TokenOwners is correct)
         if (IERC721(token).ownerOf(tokenId) != address(this)) {
             revert ERC721NotOwnedByVault(token, tokenId);
         }

        // Clean up internal tracking FIRST in case external transfer fails
        delete _erc721TokenOwners[token][tokenId];
        _erc721UserHasToken[msg.sender][token][tokenId] = false;

        // require(IERC721(token).transferFrom(address(this), msg.sender, tokenId), "ERC721 Transfer failed"); // Standard OZ check
         try IERC721(token).transferFrom(address(this), msg.sender, tokenId) {} catch {
             // If transfer fails, attempt to restore internal tracking
             _erc721TokenOwners[token][tokenId] = msg.sender;
             _erc721UserHasToken[msg.sender][token][tokenId] = true;
             revert ERC721TransferFailed(token, tokenId);
        }

        emit ConditionalWithdrawalTriggered(msg.sender, token, tokenId, 0); // Amount 0 for ERC721
        emit WithdrawERC721(msg.sender, token, tokenId);
    }


     /**
     * @dev Allows an admin to withdraw ERC20 in case of emergency.
     *      Only possible in Emergency state.
     * @param token The address of the ERC20 token.
     * @param amount The amount to withdraw from the contract's total balance.
     */
    function emergencyWithdrawERC20Admin(address token, uint256 amount)
        external
        onlyRole(Role.ADMIN_ROLE)
        onlyPermission(Permission.PERM_EMERGENCY_WITHDRAW)
        requireVaultState(VaultState.Emergency)
         isAllowedToken(token)
    {
         if (amount == 0) revert InvalidAmount();
         if (!token.isContract()) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC20

        // In emergency, admin can withdraw any amount the contract holds
        // We don't check individual user balances here, as this is a recovery mechanism
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        if (contractBalance < amount) {
            revert InsufficientBalance(amount, contractBalance);
        }

        // require(IERC20(token).transfer(msg.sender, amount), "Emergency transfer failed"); // Standard OZ check
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();

        // NOTE: This emergency function does NOT update user balances or internal state.
        // This is a raw recovery. State needs to be rebuilt/migrated later.
        emit EmergencyWithdrawal(msg.sender, token, amount);
    }

     /**
     * @dev Allows an admin to withdraw a specific ERC721 in case of emergency.
     *      Only possible in Emergency state.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to withdraw.
     */
    function emergencyWithdrawERC721Admin(address token, uint256 tokenId)
        external
        onlyRole(Role.ADMIN_ROLE)
        onlyPermission(Permission.PERM_EMERGENCY_WITHDRAW)
        requireVaultState(VaultState.Emergency)
         isAllowedToken(token)
    {
         if (!token.isContract()) revert ZeroAddress();
         if (!_isERC721Token[token]) revert AssetNotAllowed(); // Ensure it's actually ERC721

        // In emergency, admin can withdraw any token the contract holds
         if (IERC721(token).ownerOf(tokenId) != address(this)) {
             revert ERC721NotOwnedByVault(token, tokenId);
         }

        // NOTE: This emergency function does NOT update internal state.
        // This is a raw recovery. State needs to be rebuilt/migrated later.
        // require(IERC721(token).transferFrom(address(this), msg.sender, tokenId), "Emergency ERC721 transfer failed"); // Standard OZ check
         try IERC721(token).transferFrom(address(this), msg.sender, tokenId) {} catch {
             revert ERC721TransferFailed(token, tokenId);
         }

        emit EmergencyWithdrawal(msg.sender, token, tokenId);
    }

    // --- Access Control & Permission Management ---

    /**
     * @dev Grants a role to an account.
     * @param account The account to grant the role to.
     * @param role The role to grant.
     */
    function _grantRole(address account, Role role) internal {
        if (!_roles[account][role]) {
            _roles[account][role] = true;
            emit RoleGranted(account, role);
        }
    }

    /**
     * @dev Revokes a role from an account.
     * @param account The account to revoke the role from.
     * @param role The role to revoke.
     */
    function _revokeRole(address account, Role role) internal {
         // Prevent removing the last admin role
        if (role == Role.ADMIN_ROLE && account == msg.sender) {
             bool otherAdminExists = false;
             // This check is inefficient for many admins. A set/list might be better
             // but complicates add/remove. For this example, we accept this trade-off.
             // In a real-world scenario with many admins, a more robust role management
             // pattern (like OpenZeppelin's AccessControl) is recommended.
             // We'll skip the check for simplicity here, assuming external logic prevents
             // removing the last admin.
            // Note: A robust check requires iterating over all potential admin addresses.
            // This is infeasible/gas-prohibitive on-chain generally.
            // A simple check could be: require(_countAdmins() > 1, "Cannot remove last admin");
        }

        if (_roles[account][role]) {
            _roles[account][role] = false;
            emit RoleRevoked(account, role);
        }
    }

    /**
     * @dev Grants the ADMIN_ROLE to an account.
     * @param account The account to grant the role to.
     */
    function addAdmin(address account) external onlyRole(Role.ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _grantRole(account, Role.ADMIN_ROLE);
        // Grant default Admin permissions
        _userPermissions[account][Permission.PERM_SET_STATE] = true;
        _userPermissions[account][Permission.PERM_CONFIG] = true;
        _userPermissions[account][Permission.PERM_WITHDRAW_REGULAR] = true; // Admins can do anything regular users can
        _userPermissions[account][Permission.PERM_SET_CONDITIONS] = true;
        _userPermissions[account][Permission.PERM_DELEGATE] = true;
        _userPermissions[account][Permission.PERM_EMERGENCY_WITHDRAW] = true;
         emit PermissionGranted(account, Permission.PERM_SET_STATE);
         emit PermissionGranted(account, Permission.PERM_CONFIG);
         emit PermissionGranted(account, Permission.PERM_WITHDRAW_REGULAR);
         emit PermissionGranted(account, Permission.PERM_SET_CONDITIONS);
         emit PermissionGranted(account, Permission.PERM_DELEGATE);
         emit PermissionGranted(account, Permission.PERM_EMERGENCY_WITHDRAW);

    }

    /**
     * @dev Revokes the ADMIN_ROLE from an account.
     * @param account The account to revoke the role from.
     */
    function removeAdmin(address account) external onlyRole(Role.ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _revokeRole(account, Role.ADMIN_ROLE);
         // Revoke default Admin permissions (optional, but good practice)
        _userPermissions[account][Permission.PERM_SET_STATE] = false;
        _userPermissions[account][Permission.PERM_CONFIG] = false;
        _userPermissions[account][Permission.PERM_WITHDRAW_REGULAR] = false;
        _userPermissions[account][Permission.PERM_SET_CONDITIONS] = false;
        _userPermissions[account][Permission.PERM_DELEGATE] = false;
        _userPermissions[account][Permission.PERM_EMERGENCY_WITHDRAW] = false;
         emit PermissionRevoked(account, Permission.PERM_SET_STATE);
         emit PermissionRevoked(account, Permission.PERM_CONFIG);
         emit PermissionRevoked(account, Permission.PERM_WITHDRAW_REGULAR);
         emit PermissionRevoked(account, Permission.PERM_SET_CONDITIONS);
         emit PermissionRevoked(account, Permission.PERM_DELEGATE);
         emit PermissionRevoked(account, Permission.PERM_EMERGENCY_WITHDRAW);
    }

    /**
     * @dev Grants the MANAGER_ROLE to an account.
     * @param account The account to grant the role to.
     */
    function addManager(address account) external onlyRole(Role.ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _grantRole(account, Role.MANAGER_ROLE);
         // Managers might get some default permissions too, e.g., PERM_CONFIG
        _userPermissions[account][Permission.PERM_CONFIG] = true;
         emit PermissionGranted(account, Permission.PERM_CONFIG);
    }

     /**
     * @dev Revokes the MANAGER_ROLE from an account.
     * @param account The account to revoke the role from.
     */
    function removeManager(address account) external onlyRole(Role.ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _revokeRole(account, Role.MANAGER_ROLE);
         _userPermissions[account][Permission.PERM_CONFIG] = false;
         emit PermissionRevoked(account, Permission.PERM_CONFIG);
    }

    /**
     * @dev Grants a specific permission to an account.
     * @param account The account to grant the permission to.
     * @param permission The permission to grant.
     */
    function grantPermission(address account, Permission permission) external onlyRole(Role.ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _userPermissions[account][permission] = true;
        emit PermissionGranted(account, permission);
    }

    /**
     * @dev Revokes a specific permission from an account.
     * @param account The account to revoke the permission from.
     * @param permission The permission to revoke.
     */
    function revokePermission(address account, Permission permission) external onlyRole(Role.ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _userPermissions[account][permission] = false;
        emit PermissionRevoked(account, permission);
    }

    // --- Delegation Management ---

     /**
     * @dev Delegates the right to withdraw a specific ERC20 token amount for a duration.
     * @param delegatee The address receiving the delegation.
     * @param token The address of the ERC20 token.
     * @param maxAmount The maximum amount the delegatee can withdraw.
     * @param duration The duration of the delegation in seconds from now.
     */
    function delegateWithdrawalPermission(address delegatee, address token, uint256 maxAmount, uint256 duration)
        external
        onlyPermission(Permission.PERM_DELEGATE)
        isAllowedToken(token)
    {
        if (delegatee == address(0) || token == address(0)) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Delegation only for ERC20 for now
        if (maxAmount == 0 || duration == 0) revert InvalidAmount(); // Require non-zero amount/duration

        // Overwrite any existing delegation
        _delegatedWithdrawals[msg.sender][delegatee][token] = Delegation({
            maxAmount: maxAmount,
            expiry: block.timestamp + duration,
            withdrawnAmount: 0
        });

        emit DelegationSet(msg.sender, delegatee, token, maxAmount, block.timestamp + duration);
    }

     /**
     * @dev Revokes an active delegation.
     * @param delegatee The address whose delegation is being revoked.
     * @param token The address of the token for which the delegation is being revoked.
     */
    function revokeDelegation(address delegatee, address token)
        external
        onlyPermission(Permission.PERM_DELEGATE)
        isAllowedToken(token)
    {
         if (delegatee == address(0) || token == address(0)) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Delegation only for ERC20 for now

        Delegation storage delegation = _delegatedWithdrawals[msg.sender][delegatee][token];
        if (delegation.expiry == 0) {
             revert DelegationNotFound(); // No active delegation to revoke
        }

        delete _delegatedWithdrawals[msg.sender][delegatee][token];

        emit DelegationRevoked(msg.sender, delegatee, token);
    }


    // --- Conditional Release Configuration & Checking ---

    /**
     * @dev Sets the conditions required to release a specific asset.
     *      Can be called by the asset owner with PERM_SET_CONDITIONS.
     * @param token The address of the token.
     * @param idOrZero The tokenId for ERC721, or 0 for ERC20.
     * @param conditions An array of ReleaseCondition structs. ALL conditions must be met.
     */
    function setAssetReleaseConditions(address token, uint256 idOrZero, ReleaseCondition[] memory conditions)
        external
        onlyPermission(Permission.PERM_SET_CONDITIONS)
        isAllowedToken(token)
    {
        if (token == address(0)) revert ZeroAddress();

        // Verify caller owns the asset in the vault if ERC721
        if (_isERC721Token[token]) {
            if (_erc721TokenOwners[token][idOrZero] != msg.sender) {
                revert ERC721NotOwnedByUser(msg.sender, token, idOrZero);
            }
        }
        // Note: For ERC20 (idOrZero=0), anyone with PERM_SET_CONDITIONS can set conditions
        // for that token type for themselves. Conditions are per-asset, not per-user balance slice.
        // A more complex design could have user-specific conditions for ERC20 amounts.

        _assetReleaseConditions[token][idOrZero] = conditions;

        emit ConditionalReleaseConfigured(token, idOrZero);
    }

    /**
     * @dev Checks if the configured conditions for an asset are currently met.
     *      This function simulates checks against time, required tokens/balances,
     *      oracle data (requires `optionalProof`), and proof verifier data.
     *      In a real dApp, the `optionalProof` verification would be complex
     *      (e.g., ZK proof verification). Here it's a simplified check.
     * @param token The address of the token.
     * @param idOrZero The tokenId for ERC721, or 0 for ERC20.
     * @param optionalProof Data potentially required by a condition check (e.g., oracle signature, ZK proof).
     * @return bool True if all conditions are met.
     */
    function checkAssetReleaseConditions(address token, uint256 idOrZero, bytes memory optionalProof)
        public // Made public to be callable by conditionalWithdraw functions
        view
        returns (bool)
    {
        ReleaseCondition[] memory conditions = _assetReleaseConditions[token][idOrZero];

        // If no conditions are set, it is always met (or revert if empty conditions implies locked)
        // Let's assume no conditions means no conditional release is possible, requires regular withdrawal.
        // So, if conditions array is empty, check fails for conditional release.
        if (conditions.length == 0) {
            return false;
        }

        for (uint i = 0; i < conditions.length; i++) {
            ReleaseCondition memory condition = conditions[i];
            bool conditionMet = true; // Assume met unless failed below

            // 1. Time-based conditions
            if (condition.requiredBlockTimestamp > 0 && block.timestamp < condition.requiredBlockTimestamp) {
                conditionMet = false;
            }
            if (condition.requiredBlockNumber > 0 && block.number < condition.requiredBlockNumber) {
                conditionMet = false;
            }

            // 2. Required external token/balance conditions (caller's wallet, NOT inside vault)
            if (condition.requiredERC20Token != address(0)) {
                if (IERC20(condition.requiredERC20Token).balanceOf(msg.sender) < condition.requiredERC20Amount) {
                    conditionMet = false;
                }
            }
            if (condition.requiredERC721Token != address(0)) {
                 // Note: Checking ERC721 ownership externally is prone to reentrancy if not careful.
                 // For a view function, it's less risky, but be aware in state-changing calls.
                if (IERC721(condition.requiredERC721Token).ownerOf(condition.requiredERC721TokenId) != msg.sender) {
                    conditionMet = false;
                }
            }

            // 3. Oracle data / Proof conditions (Simulated)
            if (condition.requiresOracleData) {
                // In a real scenario, interact with an oracle contract here:
                // bool oracleOK = Oracle(_oracleAddress).verifyData(condition.requiredOracleProof, optionalProof);
                // if (!oracleOK) conditionMet = false;

                // Simulation: Check if oracle address is set and optionalProof matches required data
                 if (_oracleAddress == address(0) || bytes.equal(condition.requiredOracleProof, optionalProof) == false) {
                     conditionMet = false;
                 }
            }

            // 4. External Verifier Proof conditions (Simulated)
             if (condition.proofVerifierData.length > 0) {
                // In a real scenario, interact with a verifier contract:
                // bool proofOK = Verifier(address(bytes20(condition.proofVerifierData))).verifyProof(optionalProof);
                // if (!proofOK) conditionMet = false;

                // Simulation: Assume external verification needed, require optionalProof exists
                if (optionalProof.length == 0) {
                    conditionMet = false; // Proof required, but not provided
                }
                // More realistic sim: Check if optionalProof starts with expected bytes prefix from verifierData
                // Example: If proofVerifierData is '0x1234', optionalProof must start with '0x1234...'
                 if (optionalProof.length < condition.proofVerifierData.length ||
                     !bytes.equal(optionalProof[0..condition.proofVerifierData.length], condition.proofVerifierData)) {
                     // Optional: Specific error for invalid proof format
                      // revert InvalidConditionalProof(); // Cannot revert in view function, just return false
                     conditionMet = false;
                 }
             }


            // Apply negation if required
            if (condition.negateCondition) {
                conditionMet = !conditionMet;
            }

            // If *any* condition is not met (and not negated), the whole check fails.
            if (!conditionMet) {
                return false;
            }
        }

        // If we looped through all conditions and none failed, then all are met.
        return true;
    }


    // --- Configuration Management ---

     /**
     * @dev Sets the fee percentage applied to certain withdrawals (e.g., delegated, conditional).
     * @param basisPoints Fee percentage in basis points (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setFeePercentage(uint256 basisPoints) external onlyRole(Role.MANAGER_ROLE) onlyPermission(Permission.PERM_CONFIG) {
        if (basisPoints > 10000) revert InvalidAmount(); // Fee cannot be > 100%
        _feePercentageBasisPoints = basisPoints;
        emit FeePercentageUpdated(basisPoints);
    }

     /**
     * @dev Sets the address of the trusted oracle contract.
     * @param oracle The address of the oracle contract.
     */
    function setOracleAddress(address oracle) external onlyRole(Role.MANAGER_ROLE) onlyPermission(Permission.PERM_CONFIG) {
         // Allow setting to zero address to disable oracle requirement
        _oracleAddress = oracle;
        emit OracleAddressUpdated(oracle);
    }

    /**
     * @dev Allows admins to withdraw collected fees for a specific ERC20 token.
     * @param token The address of the ERC20 token.
     * @param amount The amount of fees to withdraw.
     */
    function withdrawFees(address token, uint256 amount) external onlyRole(Role.ADMIN_ROLE) onlyPermission(Permission.PERM_CONFIG) isAllowedToken(token) {
        if (amount == 0) revert InvalidAmount();
         if (!token.isContract()) revert ZeroAddress();
         if (_isERC721Token[token]) revert AssetNotAllowed(); // Can only withdraw ERC20 fees

        uint256 collected = _collectedFeesERC20[token];
        if (collected < amount) {
            revert InsufficientBalance(amount, collected);
        }

        _collectedFeesERC20[token] -= amount;

        // require(IERC20(token).transfer(msg.sender, amount), "Fee withdrawal failed"); // Standard OZ check
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) {
             // Revert state change on transfer failure
             _collectedFeesERC20[token] += amount;
            revert TransferFailed();
        }

        emit FeesWithdrawn(msg.sender, token, amount);
    }


    // --- Allowed Token Management ---

    /**
     * @dev Adds a token to the list of allowed tokens for deposit/withdrawal.
     * @param token The address of the token.
     * @param isERC721 Specifies if the token is ERC721 (false for ERC20).
     */
    function addAllowedToken(address token, bool isERC721) external onlyRole(Role.ADMIN_ROLE) {
        if (token == address(0)) revert ZeroAddress();
        _allowedTokens[token] = true;
        _isERC721Token[token] = isERC721;
        emit AllowedTokenAdded(token, isERC721);
    }

    /**
     * @dev Removes a token from the list of allowed tokens. Does not affect existing deposits.
     * @param token The address of the token.
     */
    function removeAllowedToken(address token) external onlyRole(Role.ADMIN_ROLE) {
         if (token == address(0)) revert ZeroAddress();
        _allowedTokens[token] = false;
        // _isERC721Token entry remains but is irrelevant if !allowedTokens
        emit AllowedTokenRemoved(token);
    }


    // --- View Functions ---

    /**
     * @dev Checks if an account has a specific role.
     * @param account The account to check.
     * @param role The role to check for.
     * @return bool True if the account has the role.
     */
    function hasRole(address account, Role role) public view returns (bool) {
        return _roles[account][role];
    }

     /**
     * @dev Checks if an account has a specific permission.
     * @param account The account to check.
     * @param permission The permission to check for.
     * @return bool True if the account has the permission.
     */
    function hasPermission(address account, Permission permission) public view returns (bool) {
        return _userPermissions[account][permission];
    }


    /**
     * @dev Gets a user's balance of a specific ERC20 token within the vault.
     * @param user The user's address.
     * @param token The address of the ERC20 token.
     * @return uint256 The balance.
     */
    function getUserERC20Balance(address user, address token) external view returns (uint256) {
        return _erc20Balances[user][token];
    }

     /**
     * @dev Checks if a user owns a specific ERC721 token within the vault.
     *      Note: Does not return a list of all token IDs due to gas limitations.
     * @param user The user's address.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to check.
     * @return bool True if the user owns the token in the vault.
     */
    function hasUserERC721(address user, address token, uint256 tokenId) external view returns (bool) {
        return _erc721TokenOwners[token][tokenId] == user && _erc721UserHasToken[user][token][tokenId];
    }


    /**
     * @dev Gets the current state of the vault.
     * @return VaultState The current state.
     */
    function getVaultState() external view returns (VaultState) {
        return _vaultState;
    }

    /**
     * @dev Gets the currently configured fee percentage.
     * @return uint256 The fee percentage in basis points.
     */
    function getFeePercentage() external view returns (uint256) {
        return _feePercentageBasisPoints;
    }

     /**
     * @dev Gets the currently configured oracle address.
     * @return address The oracle address.
     */
    function getOracleAddress() external view returns (address) {
        return _oracleAddress;
    }

     /**
     * @dev Gets the collected fees for a specific ERC20 token.
     * @param token The address of the ERC20 token.
     * @return uint256 The collected fees.
     */
    function getCollectedFeesERC20(address token) external view returns (uint256) {
        return _collectedFeesERC20[token];
    }


    /**
     * @dev Gets the configured release conditions for an asset.
     * @param token The address of the token.
     * @param idOrZero The tokenId for ERC721, or 0 for ERC20.
     * @return ReleaseCondition[] The array of conditions.
     */
    function getAssetReleaseConditions(address token, uint256 idOrZero) external view returns (ReleaseCondition[] memory) {
        return _assetReleaseConditions[token][idOrZero];
    }

    /**
     * @dev Gets the details of a specific delegation.
     * @param owner The address of the original asset owner.
     * @param delegatee The address of the delegatee.
     * @param token The address of the token.
     * @return uint256 maxAmount, uint256 expiry, uint256 withdrawnAmount
     */
    function getDelegation(address owner, address delegatee, address token) external view returns (uint256 maxAmount, uint256 expiry, uint256 withdrawnAmount) {
        Delegation storage delegation = _delegatedWithdrawals[owner][delegatee][token];
        return (delegation.maxAmount, delegation.expiry, delegation.withdrawnAmount);
    }

     /**
     * @dev Checks if a token is currently allowed for deposit/withdrawal.
     * @param token The address of the token.
     * @return bool True if the token is allowed.
     */
    function isTokenAllowed(address token) external view returns (bool) {
        return _allowedTokens[token];
    }
}
```