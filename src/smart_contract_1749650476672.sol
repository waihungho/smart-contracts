Okay, here is a smart contract in Solidity implementing an advanced concept: a "Quantum Vault".

**Concept:**

The Quantum Vault is a secure vault that holds ERC-20 tokens. Its core advanced functionality lies in the creation and management of *conditional locks*. Users can deposit funds and assign them to a specific beneficiary, but these funds can *only* be unlocked and withdrawn if a complex set of predefined conditions are met. These conditions can combine:

1.  **Time-based:** A specific timestamp must be reached.
2.  **Oracle-based:** A registered oracle must report a specific value.
3.  **Proof-based (Simulated ZK):** The beneficiary must provide a cryptographic hash that matches a predefined value stored in the lock. This simulates proving knowledge of a secret or result without revealing the secret itself (like a simplified ZK proof verification).
4.  **Approval-based:** A designated set of approvers must collectively approve the unlock.

The contract also features state management (`Setup`, `Active`, `Paused`), role-based access control, and registration mechanisms for trusted oracles and simulated proof verifiers.

This concept is advanced because it combines multiple disparate unlock conditions, including a simulated proof verification step and external oracle dependency, within a single atomic unlock operation, allowing for highly customizable and complex financial agreements or state transitions on the blockchain. It avoids duplicating simple time-locks, basic multi-sigs, or standard vaults.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors for better debugging
error QuantumVault__InvalidState();
error QuantumVault__Unauthorized(address account, bytes32 requiredRole);
error QuantumVault__LockNotFound(uint256 lockId);
error QuantumVault__ConditionNotFound(uint256 lockId, uint256 conditionIndex);
error QuantumVault__AllConditionsNotMet(uint256 lockId);
error QuantumVault__LockNotForBeneficiary(uint256 lockId, address account);
error QuantumVault__ConditionAlreadyMet(uint256 lockId, uint256 conditionIndex);
error QuantumVault__ApprovalAlreadyExists(uint256 lockId, address approver);
error QuantumVault__NotEnoughApprovals(uint256 lockId, uint256 required, uint256 provided);
error QuantumVault__InvalidConditionType();
error QuantumVault__OracleNotRegistered(address oracle);
error QuantumVault__ProofVerifierNotRegistered(address verifier);
error QuantumVault__DepositFailed();
error QuantumVault__TransferFailed();
error QuantumVault__AmountMustBePositive();
error QuantumVault__CannotUpdateMetConditions();
error QuantumVault__CannotAddConditionsAfterMet();
error QuantumVault__CannotCancelActiveLock();
error QuantumVault__InvalidProofProvided();
error QuantumVault__OracleCheckFailed();
error QuantumVault__ApprovalCheckFailed();
error QuantumVault__TimeCheckFailed();
error QuantumVault__OnlyLockCreatorOrOwner();
error QuantumVault__ConditionIndexOutOfRange();


/**
 * @title QuantumVault
 * @dev A conditional and time-sensitive ERC-20 vault with advanced unlock mechanics.
 * Funds are locked and require meeting multiple conditions (time, oracle, simulated proof, approval)
 * to be unlocked by the beneficiary. Includes state management and role-based access control.
 */

// --- Outline and Function Summary ---
/*
Outline:
1. State Variables: Contract state, balances, lock counter, lock details, condition types,
   oracle/verifier registration, role management, approval tracking.
2. Events: For state changes, locks, unlocks, deposits, withdrawals, role updates,
   oracle/verifier management, approvals.
3. Modifiers: Custom modifiers for state, roles, lock access.
4. Enums: ContractState, UnlockConditionType, UserRole.
5. Structs: UnlockCondition, ConditionalLock.
6. Errors: Custom error types.
7. Interfaces: For external oracles and simulated verifiers.
8. Functions:
    - Setup & State Management (set state, constructor)
    - Role Management (grant, revoke, check roles)
    - Oracle & Verifier Management (register, deregister, check)
    - Deposits (deposit funds)
    - Lock Management (create, get details, update conditions, cancel, transfer beneficiary)
    - Condition Checking (check individual or all conditions)
    - Unlocking (prove conditions and withdraw)
    - Querying & Utility (get balances, counts, version, emergency withdrawal)
*/

/*
Function Summary:

- constructor(address initialOwner): Initializes the contract with owner and initial state.
- setContractState(ContractState newState): Allows owner/admin to change contract state (Setup, Active, Paused, Expired).
- grantRole(bytes32 role, address account): Grants a specific role to an account.
- revokeRole(bytes32 role, address account): Revokes a specific role from an account.
- getUserRole(address account): Returns the role assigned to an account.
- registerOracle(address oracleAddress): Registers a trusted oracle contract address.
- deregisterOracle(address oracleAddress): Deregisters a trusted oracle contract address.
- isOracleRegistered(address oracleAddress): Checks if an address is a registered oracle.
- registerProofVerifier(address verifierAddress): Registers a trusted simulated proof verifier contract address.
- deregisterProofVerifier(address verifierAddress): Deregisters a trusted verifier contract address.
- isProofVerifierRegistered(address verifierAddress): Checks if an address is a registered verifier.
- deposit(address tokenAddress, uint256 amount): Deposits ERC-20 tokens into the vault.
- createConditionalLock(address tokenAddress, uint256 amount, address beneficiary, UnlockCondition[] conditions): Creates a new conditional lock for a beneficiary requiring conditions to be met for unlock.
- getLockDetails(uint256 lockId): Retrieves all details for a specific lock.
- getUserLocks(address account): Returns an array of lock IDs where the account is the beneficiary.
- checkConditionStatus(uint256 lockId, uint256 conditionIndex): Checks the status of a specific condition within a lock.
- checkAllConditionsStatus(uint256 lockId): Checks if ALL conditions for a lock are currently met.
- proveAndUnlock(uint256 lockId, bytes32 proofData): Attempts to unlock a lock by checking all conditions, potentially using provided proofData for ProofConditions.
- addApprovalToLock(uint256 lockId): Allows a designated approver to add their approval to a lock's approval condition.
- updateLockConditions(uint256 lockId, UnlockCondition[] newConditions): Adds *additional* conditions to an existing lock (only possible before all original conditions are met).
- transferLockBeneficiary(uint256 lockId, address newBeneficiary): Transfers the beneficiary of a lock (restricted access).
- cancelLock(uint256 lockId): Allows the lock creator or owner to cancel a lock under certain conditions.
- getContractBalance(address tokenAddress): Returns the total balance of a token held by the contract.
- getLockedBalanceForUser(address tokenAddress, address account): Returns the total amount locked for a specific beneficiary across all their active locks for a token.
- getUnlockedBalanceForUser(address tokenAddress, address account): Returns the total amount currently eligible for withdrawal for a beneficiary across all their locks for a token (where all conditions are met).
- getTotalLockCount(): Returns the total number of locks ever created.
- getLockConditionDetails(uint256 lockId, uint256 conditionIndex): Retrieves details of a specific condition within a lock.
- withdrawUnassignedFunds(address tokenAddress, uint256 amount): Allows owner to withdraw funds deposited but not currently tied to any active locks.
- getVersion(): Returns the contract version string.
*/

// --- Contract Definition ---

// Interface for a simulated oracle contract
interface IOracle {
    function getValue() external view returns (bytes32);
    // In a real scenario, this might take parameters to query specific data points
    // function getValue(bytes calldata query) external view returns (bytes32);
}

// Interface for a simulated proof verifier contract
interface IProofVerifier {
    // A simple simulation: does a hash match?
    function verifyProof(bytes32 providedHash, bytes32 expectedHash) external view returns (bool);
    // In a real ZK scenario, this would take complex proof parameters
    // function verifyProof(bytes calldata proofBytes, bytes calldata publicInputs) external view returns (bool);
}

contract QuantumVault is Ownable, ReentrancyGuard {

    enum ContractState {
        Setup,    // Initial state, configuration allowed
        Active,   // Operational, locks can be created and unlocked
        Paused,   // Operations paused, only emergency actions allowed
        Expired   // Contract expired, perhaps allows final withdrawals or specific actions
    }

    enum UnlockConditionType {
        Timestamp,       // Condition met when block.timestamp >= requiredTimestamp
        OracleValue,     // Condition met when IOracle.getValue() == requiredValue
        ProofHash,       // Condition met when provided proofHash == requiredHash (simulated ZK)
        Approvals        // Condition met when N out of M required approvals are received
    }

    enum UserRole {
        None,
        Configurator,    // Can set state, manage roles
        LockCreator,     // Can create new locks
        OracleManager,   // Can register/deregister oracles
        VerifierManager  // Can register/deregister verifiers
    }

    struct UnlockCondition {
        UnlockConditionType conditionType;
        uint256 uintValue; // Used for Timestamp (unix timestamp) or Approvals (required count)
        bytes32 bytesValue; // Used for OracleValue (expected bytes32) or ProofHash (expected hash)
        address addressValue; // Used for OracleValue (oracle address) or Approvals (approvers list storage key)
        bool isMet; // Flag to track if this specific condition has been met (for Approvals)
    }

    struct ConditionalLock {
        uint256 id;
        address creator;
        address tokenAddress;
        uint256 amount;
        address beneficiary;
        UnlockCondition[] conditions;
        bool isUnlocked; // Flag to track if the lock has been fully processed/unlocked
        // Additional storage for Approval conditions
        mapping(address => bool) approversStatus; // Tracks which specific approvers have signed off for an Approval condition
        address[] approversList; // List of addresses required for an Approval condition (index corresponds to approversStatus)
        uint256 approvalsCount; // Counter for how many approvals have been gathered for an Approval condition
    }

    // State variables
    ContractState public contractState;
    mapping(address => uint256) private tokenBalances; // Total tokens held by the contract per token address
    mapping(uint256 => ConditionalLock) public conditionalLocks;
    uint256 private nextLockId = 1;
    mapping(address => uint256[]) private beneficiaryLocks; // Map beneficiary address to array of lock IDs

    // Management mappings
    mapping(address => UserRole) private userRoles;
    mapping(address => bool) private registeredOracles;
    mapping(address => bool) private registeredProofVerifiers;

    // Constants
    bytes32 public constant ROLE_CONFIGURATOR = keccak256("CONFIGURATOR");
    bytes32 public constant ROLE_LOCK_CREATOR = keccak256("LOCK_CREATOR");
    bytes32 public constant ROLE_ORACLE_MANAGER = keccak256("ORACLE_MANAGER");
    bytes32 public constant ROLE_VERIFIER_MANAGER = keccak256("VERIFIER_MANAGER");

    // Version information
    string public constant VERSION = "1.0.0";

    // Events
    event ContractStateChanged(ContractState newState, address indexed by);
    event RoleGranted(bytes32 role, address indexed account, address indexed by);
    event RoleRevoked(bytes32 role, address indexed account, address indexed by);
    event OracleRegistered(address indexed oracle, address indexed by);
    event OracleDeregistered(address indexed oracle, address indexed by);
    event VerifierRegistered(address indexed verifier, address indexed by);
    event VerifierDeregistered(address indexed verifier, address indexed by);
    event FundsDeposited(address indexed token, address indexed depositor, uint256 amount);
    event ConditionalLockCreated(uint256 indexed lockId, address indexed token, uint256 amount, address indexed beneficiary, address creator);
    event ConditionalLockUpdated(uint256 indexed lockId, address indexed by, string updateType); // updateType e.g., "conditions_added", "beneficiary_changed"
    event ConditionalLockCancelled(uint256 indexed lockId, address indexed by);
    event LockConditionsMet(uint256 indexed lockId);
    event LockUnlocked(uint256 indexed lockId, address indexed beneficiary, uint256 amount);
    event ApprovalAddedToLock(uint256 indexed lockId, address indexed approver);
    event UnassignedFundsWithdrawn(address indexed token, address indexed receiver, uint256 amount);


    // --- Modifiers ---

    modifier whenState(ContractState expectedState) {
        if (contractState != expectedState) {
            revert QuantumVault__InvalidState();
        }
        _;
    }

    modifier notState(ContractState excludedState) {
         if (contractState == excludedState) {
            revert QuantumVault__InvalidState();
        }
        _;
    }

    modifier isRole(bytes32 role) {
        if (userRoles[msg.sender] != role) {
            revert QuantumVault__Unauthorized(msg.sender, role);
        }
        _;
    }

    modifier onlyLockCreatorOrOwner(uint256 lockId) {
        if (conditionalLocks[lockId].creator != msg.sender && owner() != msg.sender) {
             revert QuantumVault__OnlyLockCreatorOrOwner();
        }
        _;
    }


    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {
        contractState = ContractState.Setup;
        // Grant owner all initial roles or specific admin role
        userRoles[initialOwner] = UserRole.Configurator;
        userRoles[initialOwner] = UserRole.LockCreator;
        userRoles[initialOwner] = UserRole.OracleManager;
        userRoles[initialOwner] = UserRole.VerifierManager;
        emit ContractStateChanged(contractState, msg.sender);
        emit RoleGranted(ROLE_CONFIGURATOR, initialOwner, msg.sender);
        emit RoleGranted(ROLE_LOCK_CREATOR, initialOwner, msg.sender);
        emit RoleGranted(ROLE_ORACLE_MANAGER, initialOwner, msg.sender);
        emit RoleGranted(ROLE_VERIFIER_MANAGER, initialOwner, msg.sender);
    }


    // --- State Management ---

    /**
     * @dev Allows the contract state to be changed. Restricted to Configurator role or owner.
     * @param newState The target contract state.
     */
    function setContractState(ContractState newState) external onlyOwner or isRole(ROLE_CONFIGURATOR) {
        if (contractState == newState) {
            // No change needed
            return;
        }
        contractState = newState;
        emit ContractStateChanged(newState, msg.sender);
    }


    // --- Role Management ---

    /**
     * @dev Grants a specific role to an account. Restricted to Configurator role or owner.
     * @param role The role to grant (bytes32 representation).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) external onlyOwner or isRole(ROLE_CONFIGURATOR) {
        UserRole targetRole;
        if (role == ROLE_CONFIGURATOR) targetRole = UserRole.Configurator;
        else if (role == ROLE_LOCK_CREATOR) targetRole = UserRole.LockCreator;
        else if (role == ROLE_ORACLE_MANAGER) targetRole = UserRole.OracleManager;
        else if (role == ROLE_VERIFIER_MANAGER) targetRole = UserRole.VerifierManager;
        else revert QuantumVault__Unauthorized(account, role); // Invalid role specified

        userRoles[account] = targetRole;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revokes a specific role from an account. Restricted to Configurator role or owner.
     * @param role The role to revoke (bytes32 representation).
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) external onlyOwner or isRole(ROLE_CONFIGURATOR) {
         UserRole targetRole;
        if (role == ROLE_CONFIGURATOR) targetRole = UserRole.Configurator;
        else if (role == ROLE_LOCK_CREATOR) targetRole = UserRole.LockCreator;
        else if (role == ROLE_ORACLE_MANAGER) targetRole = UserRole.OracleManager;
        else if (role == ROLE_VERIFIER_MANAGER) targetRole = UserRole.VerifierManager;
        else revert QuantumVault__Unauthorized(account, role); // Invalid role specified

        if (userRoles[account] == targetRole) {
             userRoles[account] = UserRole.None;
             emit RoleRevoked(role, account, msg.sender);
        }
        // If the account doesn't have the role, do nothing silently or add a check
    }

    /**
     * @dev Gets the role assigned to an account.
     * @param account The address to check.
     * @return The UserRole enum value for the account.
     */
    function getUserRole(address account) external view returns (UserRole) {
        return userRoles[account];
    }


    // --- Oracle & Verifier Management ---

    /**
     * @dev Registers a trusted oracle contract address. Restricted to OracleManager role or owner.
     * @param oracleAddress The address of the oracle contract.
     */
    function registerOracle(address oracleAddress) external onlyOwner or isRole(ROLE_ORACLE_MANAGER) {
        registeredOracles[oracleAddress] = true;
        emit OracleRegistered(oracleAddress, msg.sender);
    }

    /**
     * @dev Deregisters a trusted oracle contract address. Restricted to OracleManager role or owner.
     * @param oracleAddress The address of the oracle contract.
     */
    function deregisterOracle(address oracleAddress) external onlyOwner or isRole(ROLE_ORACLE_MANAGER) {
        registeredOracles[oracleAddress] = false;
        emit OracleDeregistered(oracleAddress, msg.sender);
    }

     /**
     * @dev Checks if an address is a registered oracle.
     * @param oracleAddress The address to check.
     * @return true if registered, false otherwise.
     */
    function isOracleRegistered(address oracleAddress) public view returns (bool) {
        return registeredOracles[oracleAddress];
    }

    /**
     * @dev Registers a trusted simulated proof verifier contract address. Restricted to VerifierManager role or owner.
     * @param verifierAddress The address of the verifier contract.
     */
    function registerProofVerifier(address verifierAddress) external onlyOwner or isRole(ROLE_VERIFIER_MANAGER) {
        registeredProofVerifiers[verifierAddress] = true;
        emit VerifierRegistered(verifierAddress, msg.sender);
    }

    /**
     * @dev Deregisters a trusted simulated proof verifier contract address. Restricted to VerifierManager role or owner.
     * @param verifierAddress The address of the verifier contract.
     */
    function deregisterProofVerifier(address verifierAddress) external onlyOwner or isRole(ROLE_VERIFIER_MANAGER) {
        registeredProofVerifiers[verifierAddress] = false;
        emit VerifierDeregistered(verifierAddress, msg.sender);
    }

    /**
     * @dev Checks if an address is a registered proof verifier.
     * @param verifierAddress The address to check.
     * @return true if registered, false otherwise.
     */
    function isProofVerifierRegistered(address verifierAddress) public view returns (bool) {
        return registeredProofVerifiers[verifierAddress];
    }


    // --- Deposits ---

    /**
     * @dev Deposits ERC-20 tokens into the vault. Requires contract to be Active.
     * @param tokenAddress The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address tokenAddress, uint256 amount) external whenState(ContractState.Active) notState(ContractState.Paused) nonReentrant {
        if (amount == 0) revert QuantumVault__AmountMustBePositive();
        tokenBalances[tokenAddress] += amount;
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) revert QuantumVault__DepositFailed();
        emit FundsDeposited(tokenAddress, msg.sender, amount);
    }


    // --- Lock Management ---

    /**
     * @dev Creates a new conditional lock. Requires contract to be Active. Restricted to LockCreator role or owner.
     * Tokens for the lock must have been previously deposited or approved for transfer.
     * @param tokenAddress The address of the ERC-20 token to lock.
     * @param amount The amount of tokens to lock.
     * @param beneficiary The address that will be able to unlock the funds.
     * @param conditions An array of UnlockCondition structs defining the requirements for unlocking.
     */
    function createConditionalLock(
        address tokenAddress,
        uint256 amount,
        address beneficiary,
        UnlockCondition[] memory conditions // Use memory for input array
    ) external whenState(ContractState.Active) notState(ContractState.Paused) onlyOwner or isRole(ROLE_LOCK_CREATOR) {
        if (amount == 0) revert QuantumVault__AmountMustBePositive();
        if (amount > tokenBalances[tokenAddress]) {
            // This check is simplified. A robust system would track assigned vs unassigned balance.
            // For this example, we just check against the total contract balance.
            // A LockCreator might need to call deposit first, or approve this contract to pull.
            revert QuantumVault__AmountMustBePositive(); // Re-using error, ideally more specific
        }

        uint256 lockId = nextLockId++;

        ConditionalLock storage newLock = conditionalLocks[lockId];
        newLock.id = lockId;
        newLock.creator = msg.sender;
        newLock.tokenAddress = tokenAddress;
        newLock.amount = amount;
        newLock.beneficiary = beneficiary;
        newLock.isUnlocked = false;

        // Copy conditions and initialize Approval-specific data
        for (uint i = 0; i < conditions.length; i++) {
             UnlockCondition storage newCondition = newLock.conditions.push();
             newCondition.conditionType = conditions[i].conditionType;
             newCondition.uintValue = conditions[i].uintValue;
             newCondition.bytesValue = conditions[i].bytesValue;
             newCondition.addressValue = conditions[i].addressValue;
             newCondition.isMet = false; // Initialize as not met

             if (conditions[i].conditionType == UnlockConditionType.OracleValue && !registeredOracles[conditions[i].addressValue]) {
                 revert QuantumVault__OracleNotRegistered(conditions[i].addressValue);
             }
             if (conditions[i].conditionType == UnlockConditionType.ProofHash && !registeredProofVerifiers[conditions[i].addressValue]) {
                 revert QuantumVault__ProofVerifierNotRegistered(conditions[i].addressValue);
             }
             if (conditions[i].conditionType == UnlockConditionType.Approvals) {
                 // Note: The approvers list is not part of the input condition struct
                 // The caller needs to provide the *list* of approvers separately or it's derived.
                 // For simplicity here, the approvers list is implicitly managed via `addApprovalToLock`.
                 // The `uintValue` must be > 0 for Approval condition.
                 if (conditions[i].uintValue == 0) revert QuantumVault__InvalidConditionType(); // uintValue is required count
                 newCondition.uintValue = conditions[i].uintValue; // Store required count
                 // approversList and approvalsCount are handled when addApprovalToLock is called
             }
        }

        beneficiaryLocks[beneficiary].push(lockId);

        // Note: This contract doesn't automatically reserve the balance from tokenBalances.
        // A more complex version would track assigned vs unassigned tokens.
        // For this example, the tokenBalances check in deposit/withdraw covers it loosely.

        emit ConditionalLockCreated(lockId, tokenAddress, amount, beneficiary, msg.sender);
    }

    /**
     * @dev Retrieves details for a specific lock.
     * @param lockId The ID of the lock.
     * @return A tuple containing lock details.
     */
    function getLockDetails(uint256 lockId)
        external
        view
        returns (
            uint256 id,
            address creator,
            address tokenAddress,
            uint256 amount,
            address beneficiary,
            UnlockCondition[] memory conditions,
            bool isUnlocked,
            uint256 approvalsCount,
            address[] memory approversList // Added for clarity on Approval condition data
        )
    {
        ConditionalLock storage lock = conditionalLocks[lockId];
        if (lock.id == 0 && lockId != 0) revert QuantumVault__LockNotFound(lockId); // Check if lock exists

        // Copy conditions to memory for return
        UnlockCondition[] memory _conditions = new UnlockCondition[](lock.conditions.length);
        for(uint i=0; i<lock.conditions.length; i++) {
            _conditions[i] = lock.conditions[i];
        }

         // Copy approversList to memory for return
        address[] memory _approversList = new address[](lock.approversList.length);
        for(uint i=0; i<lock.approversList.length; i++) {
             _approversList[i] = lock.approversList[i];
        }


        return (
            lock.id,
            lock.creator,
            lock.tokenAddress,
            lock.amount,
            lock.beneficiary,
            _conditions,
            lock.isUnlocked,
            lock.approvalsCount,
            _approversList
        );
    }

    /**
     * @dev Returns an array of lock IDs where the account is the beneficiary.
     * Note: This can be gas intensive if a user has many locks.
     * @param account The beneficiary address.
     * @return An array of lock IDs.
     */
    function getUserLocks(address account) external view returns (uint256[] memory) {
        return beneficiaryLocks[account];
    }

    /**
     * @dev Adds *additional* conditions to an existing lock. Restricted to the lock creator or owner.
     * Not possible if the lock is already unlocked or all original conditions are met.
     * @param lockId The ID of the lock.
     * @param newConditions An array of UnlockCondition structs to add.
     */
    function updateLockConditions(uint256 lockId, UnlockCondition[] memory newConditions)
        external
        whenState(ContractState.Active)
        notState(ContractState.Paused)
        nonReentrant
        onlyLockCreatorOrOwner(lockId)
    {
        ConditionalLock storage lock = conditionalLocks[lockId];
         if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
         if (lock.isUnlocked) revert QuantumVault__CannotUpdateMetConditions();
         if (checkAllConditionsStatus(lockId)) revert QuantumVault__CannotAddConditionsAfterMet(); // Cannot add more if already unlockable

        for (uint i = 0; i < newConditions.length; i++) {
             UnlockCondition storage newCondition = lock.conditions.push();
             newCondition.conditionType = newConditions[i].conditionType;
             newCondition.uintValue = newConditions[i].uintValue;
             newCondition.bytesValue = newConditions[i].bytesValue;
             newCondition.addressValue = newConditions[i].addressValue;
             newCondition.isMet = false; // Initialize as not met

             if (newConditions[i].conditionType == UnlockConditionType.OracleValue && !registeredOracles[newConditions[i].addressValue]) {
                 revert QuantumVault__OracleNotRegistered(newConditions[i].addressValue);
             }
              if (newConditions[i].conditionType == UnlockConditionType.ProofHash && !registeredProofVerifiers[newConditions[i].addressValue]) {
                 revert QuantumVault__ProofVerifierNotRegistered(newConditions[i].addressValue);
             }
             if (newConditions[i].conditionType == UnlockConditionType.Approvals) {
                 if (newConditions[i].uintValue == 0) revert QuantumVault__InvalidConditionType(); // required count
                 newCondition.uintValue = newConditions[i].uintValue; // Store required count
                 // Note: Approval data (approversList, approvalsCount) is reset/managed via addApprovalToLock
             }
        }

        emit ConditionalLockUpdated(lockId, msg.sender, "conditions_added");
    }

     /**
     * @dev Transfers the beneficiary of a lock. Restricted to the lock creator or owner.
     * @param lockId The ID of the lock.
     * @param newBeneficiary The new beneficiary address.
     */
    function transferLockBeneficiary(uint256 lockId, address newBeneficiary)
        external
        whenState(ContractState.Active)
        notState(ContractState.Paused)
        onlyLockCreatorOrOwner(lockId)
    {
         ConditionalLock storage lock = conditionalLocks[lockId];
         if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
         if (lock.isUnlocked) revert QuantumVault__CannotUpdateMetConditions(); // Cannot transfer if already unlocked

         address oldBeneficiary = lock.beneficiary;
         lock.beneficiary = newBeneficiary;

         // Update beneficiaryLocks mapping (basic implementation - may be inefficient)
         uint256[] storage oldBeneficiaryLocks = beneficiaryLocks[oldBeneficiary];
         uint256 newLength = 0;
         for(uint i = 0; i < oldBeneficiaryLocks.length; i++) {
             if (oldBeneficiaryLocks[i] != lockId) {
                 oldBeneficiaryLocks[newLength++] = oldBeneficiaryLocks[i];
             }
         }
         oldBeneficiaryLocks.pop(); // Remove the last element (which is now a duplicate or removed lock)

         beneficiaryLocks[newBeneficiary].push(lockId);


        emit ConditionalLockUpdated(lockId, msg.sender, "beneficiary_changed");
    }


    /**
     * @dev Allows the lock creator or owner to cancel a lock.
     * Possible only if the lock is not yet unlocked. Funds are typically returned to the creator,
     * or remain in the vault as unassigned depending on logic. Here, they become unassigned.
     * @param lockId The ID of the lock to cancel.
     */
    function cancelLock(uint256 lockId)
        external
        whenState(ContractState.Active) // Can only cancel active locks
        notState(ContractState.Paused)
        onlyLockCreatorOrOwner(lockId) // Restricted access
    {
        ConditionalLock storage lock = conditionalLocks[lockId];
        if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
        if (lock.isUnlocked) revert QuantumVault__CannotCancelActiveLock(); // Cannot cancel if already unlocked

        // Mark the lock as unlocked/cancelled state
        lock.isUnlocked = true; // Using isUnlocked flag to signify it's no longer active/unlockable via proveAndUnlock

        // Funds remain in the contract, effectively becoming 'unassigned'
        // (unless a more complex balance tracking system is implemented)

        // Optional: Remove from beneficiaryLocks array (gas intensive, basic implementation)
        uint256[] storage beneficiaryLockList = beneficiaryLocks[lock.beneficiary];
        uint256 newLength = 0;
        for(uint i = 0; i < beneficiaryLockList.length; i++) {
             if (beneficiaryLockList[i] != lockId) {
                 beneficiaryLockList[newLength++] = beneficiaryLockList[i];
             }
         }
         beneficiaryLockList.pop();

        emit ConditionalLockCancelled(lockId, msg.sender);
    }


    // --- Condition Checking ---

    /**
     * @dev Checks the status of a specific condition within a lock.
     * @param lockId The ID of the lock.
     * @param conditionIndex The index of the condition within the lock's conditions array.
     * @return true if the condition is met, false otherwise.
     */
    function checkConditionStatus(uint256 lockId, uint256 conditionIndex) public view returns (bool) {
        ConditionalLock storage lock = conditionalLocks[lockId];
        if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
        if (conditionIndex >= lock.conditions.length) revert QuantumVault__ConditionIndexOutOfRange();

        UnlockCondition storage condition = lock.conditions[conditionIndex];

        if (condition.isMet) {
             // For Approval conditions, once met, they stay met.
             // Other types are checked dynamically.
             if (condition.conditionType == UnlockConditionType.Approvals) return true;
        }

        unchecked { // Using unchecked as indices are checked and array length won't wrap
            if (condition.conditionType == UnlockConditionType.Timestamp) {
                return block.timestamp >= condition.uintValue;
            } else if (condition.conditionType == UnlockConditionType.OracleValue) {
                if (!registeredOracles[condition.addressValue]) {
                     // Cannot check if oracle not registered, effectively condition not met
                    return false;
                }
                 // Call the oracle contract
                try IOracle(condition.addressValue).getValue() returns (bytes32 currentValue) {
                     return currentValue == condition.bytesValue;
                 } catch {
                     // Oracle call failed, condition not met
                     return false;
                 }
            } else if (condition.conditionType == UnlockConditionType.ProofHash) {
                 // ProofHash condition status cannot be checked *before* proveAndUnlock is called
                 // as the 'proof' is an input parameter to that function, not contract state.
                 // This view function returns false as it cannot pre-verify the proof.
                 // The actual check happens inside proveAndUnlock.
                return false;
            } else if (condition.conditionType == UnlockConditionType.Approvals) {
                 // Approval condition is met if approvalsCount reaches the required uintValue
                 return lock.approvalsCount >= condition.uintValue;
            } else {
                revert QuantumVault__InvalidConditionType(); // Should not happen with valid condition type
            }
        }
    }


    /**
     * @dev Checks if ALL conditions for a lock are currently met.
     * This function iterates through all conditions and calls checkConditionStatus for each.
     * @param lockId The ID of the lock.
     * @return true if all conditions are met, false otherwise.
     */
    function checkAllConditionsStatus(uint256 lockId) public view returns (bool) {
         ConditionalLock storage lock = conditionalLocks[lockId];
         if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);

         if (lock.isUnlocked) return false; // Already unlocked/cancelled

         for (uint i = 0; i < lock.conditions.length; i++) {
             // Note: checkConditionStatus handles the specific logic for each type
             if (!checkConditionStatus(lockId, i)) {
                 return false; // If any single condition is not met, the entire lock is not unlockable
             }
         }
         return true; // All conditions met
    }


    // --- Unlocking ---

    /**
     * @dev Attempts to unlock and withdraw funds for a lock.
     * Requires the caller to be the lock's beneficiary.
     * Iterates through all conditions and verifies them. For ProofHash conditions,
     * it uses the provided proofData to call the registered verifier.
     * @param lockId The ID of the lock.
     * @param proofData Optional data required for ProofHash conditions (e.g., a hash).
     */
    function proveAndUnlock(uint256 lockId, bytes32 proofData) external nonReentrant whenState(ContractState.Active) notState(ContractState.Paused) {
        ConditionalLock storage lock = conditionalLocks[lockId];

        if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
        if (lock.beneficiary != msg.sender) revert QuantumVault__LockNotForBeneficiary(lockId, msg.sender);
        if (lock.isUnlocked) return; // Already unlocked or cancelled

        bool allConditionsMet = true;
        for (uint i = 0; i < lock.conditions.length; i++) {
            UnlockCondition storage condition = lock.conditions[i];

            if (condition.isMet) {
                // Condition already marked as met (currently only used for Approvals)
                continue;
            }

            bool conditionMet = false;
            unchecked {
                if (condition.conditionType == UnlockConditionType.Timestamp) {
                    conditionMet = block.timestamp >= condition.uintValue;
                    if (!conditionMet) revert QuantumVault__TimeCheckFailed(); // Fail fast if a time condition isn't met
                } else if (condition.conditionType == UnlockConditionType.OracleValue) {
                    if (!registeredOracles[condition.addressValue]) revert QuantumVault__OracleNotRegistered(condition.addressValue);
                    // Call the oracle
                    try IOracle(condition.addressValue).getValue() returns (bytes32 currentValue) {
                         conditionMet = currentValue == condition.bytesValue;
                     } catch {
                         revert QuantumVault__OracleCheckFailed(); // Oracle call failed
                     }
                     if (!conditionMet) revert QuantumVault__OracleCheckFailed(); // Value mismatch
                } else if (condition.conditionType == UnlockConditionType.ProofHash) {
                    if (!registeredProofVerifiers[condition.addressValue]) revert QuantumVault__ProofVerifierNotRegistered(condition.addressValue);
                     // Call the simulated verifier with the provided proofData
                    try IProofVerifier(condition.addressValue).verifyProof(proofData, condition.bytesValue) returns (bool isValid) {
                         conditionMet = isValid;
                     } catch {
                         revert QuantumVault__InvalidProofProvided(); // Verifier call failed
                     }
                     if (!conditionMet) revert QuantumVault__InvalidProofProvided(); // Proof verification failed
                } else if (condition.conditionType == UnlockConditionType.Approvals) {
                     // Approval check is done via addApprovalToLock updating approvalsCount.
                     // Here, we just check if the *count* has reached the requirement.
                     conditionMet = lock.approvalsCount >= condition.uintValue;
                     if (!conditionMet) revert QuantumVault__ApprovalCheckFailed(); // Not enough approvals yet
                } else {
                    revert QuantumVault__InvalidConditionType(); // Should not happen
                }
            } // unchecked

            // Mark Approval condition as met once the count is sufficient
            if (conditionMet && condition.conditionType == UnlockConditionType.Approvals) {
                 condition.isMet = true;
            }

            if (!conditionMet) {
                allConditionsMet = false;
                 // Note: For efficiency, we could revert immediately if any condition fails.
                 // However, iterating allows checking all conditions in one go and identifying
                 // which ones failed if we were to return error details.
                 // Reverting immediately is simpler and saves gas on failure path.
                 // Let's revert immediately for non-Approval conditions if not met.
                 // Approval condition status check happens below after iterating.
                 // The "fail fast" reverts above cover Timestamp, Oracle, ProofHash.
            }
        }

        // After iterating, re-check if all conditions are indeed met (especially relevant for Approvals)
        if (!checkAllConditionsStatus(lockId)) {
            revert QuantumVault__AllConditionsNotMet(lockId);
        }

        // If all conditions passed all checks:
        lock.isUnlocked = true; // Mark lock as processed

        // Transfer tokens to beneficiary
        tokenBalances[lock.tokenAddress] -= lock.amount; // Decrement contract's perceived balance
        bool success = IERC20(lock.tokenAddress).transfer(lock.beneficiary, lock.amount);
        if (!success) revert QuantumVault__TransferFailed(); // This is bad, funds are 'lost' to the contract

        emit LockUnlocked(lockId, lock.beneficiary, lock.amount);
    }

    /**
     * @dev Allows a designated approver to add their approval to an Approval condition within a lock.
     * This function requires knowing which condition is the Approval one.
     * @param lockId The ID of the lock.
     */
     function addApprovalToLock(uint256 lockId) external nonReentrant whenState(ContractState.Active) notState(ContractState.Paused) {
         ConditionalLock storage lock = conditionalLocks[lockId];
         if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
         if (lock.isUnlocked) revert QuantumVault__ConditionAlreadyMet(lockId, type(uint256).max); // Use a dummy index

         // Find the Approval condition(s). Assume there's at least one and we update the first found.
         // A more complex design might allow multiple approval conditions or specific ones to target.
         // For this simplified example, we assume one Approval condition per lock if any.
         int256 approvalConditionIndex = -1;
         for (uint i = 0; i < lock.conditions.length; i++) {
             if (lock.conditions[i].conditionType == UnlockConditionType.Approvals) {
                 approvalConditionIndex = int256(i);
                 break;
             }
         }

         if (approvalConditionIndex == -1) {
             // No approval condition on this lock
             revert QuantumVault__InvalidConditionType();
         }

         UnlockCondition storage approvalCondition = lock.conditions[uint25mal(approvalConditionIndex)];

         if (approvalCondition.isMet) revert QuantumVault__ConditionAlreadyMet(lockId, uint256(approvalConditionIndex));

         // Check if msg.sender is already an approver for this condition (basic check)
         // Note: This simple implementation doesn't pre-define *who* the approvers are.
         // Anyone can approve, and the count matters. A real scenario would check against a list.
         // To make it more realistic, let's add a basic check against the dynamic approversList being built.
         for(uint i=0; i<lock.approversList.length; i++) {
             if (lock.approversList[i] == msg.sender) {
                 revert QuantumVault__ApprovalAlreadyExists(lockId, msg.sender);
             }
         }

         lock.approversList.push(msg.sender);
         lock.approversStatus[msg.sender] = true; // Not strictly necessary but good practice
         lock.approvalsCount++;

         // Check if the required number of approvals is reached
         if (lock.approvalsCount >= approvalCondition.uintValue) {
             approvalCondition.isMet = true; // Mark the condition as met
         }

         emit ApprovalAddedToLock(lockId, msg.sender);
     }


    // --- Querying & Utility ---

    /**
     * @dev Gets the total balance of a specific token held by the contract.
     * @param tokenAddress The address of the ERC-20 token.
     * @return The total balance.
     */
    function getContractBalance(address tokenAddress) external view returns (uint256) {
        return tokenBalances[tokenAddress];
    }

    /**
     * @dev Gets the total amount locked for a specific beneficiary across all their active locks for a token.
     * Note: Can be gas intensive if a user has many locks.
     * @param tokenAddress The address of the ERC-20 token.
     * @param account The beneficiary address.
     * @return The total locked amount.
     */
    function getLockedBalanceForUser(address tokenAddress, address account) external view returns (uint256) {
        uint256 totalLocked = 0;
        uint256[] memory userLocks = beneficiaryLocks[account]; // Get copy of array
        for (uint i = 0; i < userLocks.length; i++) {
            uint256 lockId = userLocks[i];
            ConditionalLock storage lock = conditionalLocks[lockId];
            if (lock.id != 0 && lock.tokenAddress == tokenAddress && !lock.isUnlocked) {
                totalLocked += lock.amount;
            }
        }
        return totalLocked;
    }

    /**
     * @dev Gets the total amount currently eligible for withdrawal for a beneficiary across all their locks for a token.
     * This sums up amounts from locks where checkAllConditionsStatus returns true.
     * Note: Can be gas intensive due to iterating locks and checking all conditions per lock.
     * @param tokenAddress The address of the ERC-20 token.
     * @param account The beneficiary address.
     * @return The total unlockable amount.
     */
    function getUnlockedBalanceForUser(address tokenAddress, address account) external view returns (uint256) {
         uint256 totalUnlocked = 0;
        uint256[] memory userLocks = beneficiaryLocks[account]; // Get copy of array
        for (uint i = 0; i < userLocks.length; i++) {
            uint256 lockId = userLocks[i];
            ConditionalLock storage lock = conditionalLocks[lockId];
            // Check if lock exists, is for the correct token, is for the beneficiary, and is not already unlocked
            if (lock.id != 0 && lock.tokenAddress == tokenAddress && lock.beneficiary == account && !lock.isUnlocked) {
                // Check if all conditions are met for this specific lock
                if (checkAllConditionsStatus(lockId)) {
                    totalUnlocked += lock.amount;
                }
            }
        }
        return totalUnlocked;
    }

     /**
     * @dev Gets the total number of locks ever created.
     * @return The total lock count.
     */
    function getTotalLockCount() external view returns (uint256) {
        return nextLockId - 1; // nextLockId is 1 more than the count
    }


    /**
     * @dev Retrieves details of a specific condition within a lock.
     * Useful for frontends to display condition requirements.
     * @param lockId The ID of the lock.
     * @param conditionIndex The index of the condition.
     * @return A tuple containing condition details.
     */
    function getLockConditionDetails(uint256 lockId, uint256 conditionIndex)
        external
        view
        returns (
            UnlockConditionType conditionType,
            uint256 uintValue,
            bytes32 bytesValue,
            address addressValue,
            bool isMet
        )
    {
         ConditionalLock storage lock = conditionalLocks[lockId];
         if (lock.id == 0) revert QuantumVault__LockNotFound(lockId);
         if (conditionIndex >= lock.conditions.length) revert QuantumVault__ConditionIndexOutOfRange();

         UnlockCondition storage condition = lock.conditions[conditionIndex];

         return (
             condition.conditionType,
             condition.uintValue,
             condition.bytesValue,
             condition.addressValue,
             condition.isMet // Note: isMet might not reflect real-time status for all types
         );
    }


     /**
     * @dev Allows the owner to withdraw funds that are in the contract but NOT currently assigned to any active locks.
     * This requires careful external accounting to know what is "unassigned".
     * This function assumes any balance exceeding the sum of all active locks is unassigned.
     * WARNING: This is a simplified owner backdoor. In a real system, assigned balances would be tracked explicitly.
     * @param tokenAddress The token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawUnassignedFunds(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
         // Simplified check: total balance minus sum of active locks.
         // This is NOT perfectly accurate without explicit assignment tracking.
         // It's a basic 'sweep excess' function.
         uint256 totalLockedAmount = 0;
         // Iterating all locks can be gas-prohibitive if there are many.
         // This is a known limitation of this simplified approach.
         for(uint i=1; i < nextLockId; i++) {
             ConditionalLock storage lock = conditionalLocks[i];
             if(lock.id != 0 && lock.tokenAddress == tokenAddress && !lock.isUnlocked) {
                 totalLockedAmount += lock.amount;
             }
         }

         uint256 availableUnassigned = tokenBalances[tokenAddress] - totalLockedAmount;

         if (amount == 0) revert QuantumVault__AmountMustBePositive();
         if (amount > availableUnassigned) revert QuantumVault__TransferFailed(); // Re-using error

         tokenBalances[tokenAddress] -= amount;
         bool success = IERC20(tokenAddress).transfer(msg.sender, amount);
         if (!success) revert QuantumVault__TransferFailed();

         emit UnassignedFundsWithdrawn(tokenAddress, msg.sender, amount);
    }


    /**
     * @dev Returns the contract version string.
     * @return The version string.
     */
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }

    // Fallback function (optional but good practice)
    // Prevent accidental ether transfer
    receive() external payable {
        revert("Ether not accepted");
    }

    fallback() external payable {
        revert("Calls to non-existent functions or unexpected fallback");
    }
}
```