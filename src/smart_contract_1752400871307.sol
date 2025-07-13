Okay, let's design a smart contract that incorporates several advanced concepts: secure asset management (vault), a complex and dynamic permissioning system (beyond simple roles, using 'Entanglement Keys'), time-based and conditional logic, delegation of capabilities, and a simulated 'proof' mechanism for executing complex actions (like withdrawals). We'll call it `QuantumVault` to imply the intricate, possibly non-obvious, interdependencies of permissions and states.

It won't use actual quantum computing, but the name and mechanics suggest a system where permissions aren't linear and outcomes depend on a confluence of factors ("entangled states").

This contract will manage ERC20 tokens. Withdrawals are gated by requiring a valid "State Entanglement Proof," which is a submitted claim that meets multiple on-chain conditions verified by the contract, requiring specific capabilities and possibly multi-party approvals.

---

**QuantumVault Smart Contract Outline & Function Summary**

This contract acts as a secure, feature-rich ERC20 vault with an advanced, dynamic permissioning and conditional execution system based on "Entanglement Keys" and "State Entanglement Proofs".

1.  **Core Structure & State:**
    *   Manages ERC20 token balances per user.
    *   Defines `CapabilityType` enum for granular permissions.
    *   Defines structs for `EntanglementKey`, `KeyCapability`, `CapabilityDelegation`, and `StateEntanglementProof`.
    *   Mappings to track keys, capabilities, delegations, proofs, and balances.
    *   Variables for owner, paused state, and simulated external conditions.

2.  **Vault Operations:**
    *   `depositERC20`: Allows users to deposit supported ERC20 tokens into the vault.
    *   `withdrawERC20OwnerEmergency`: Emergency function for owner to withdraw *any* token (high privilege).
    *   `executeConditionalWithdrawal`: The primary withdrawal function, requiring a valid, executed `StateEntanglementProof`.

3.  **Entanglement Key Management:**
    *   `createEntanglementKey`: Creates a new unique key, initially owned by the caller (requires specific capability or ownership).
    *   `transferKeyOwnership`: Transfers control of a key to another address.
    *   `revokeEntanglementKey`: Permanently invalidates a key and all associated capabilities/delegations.

4.  **Key Capability Management:**
    *   `assignCapabilityToKey`: Grants a specific capability to a key with conditions (time validity, required external state).
    *   `removeCapabilityFromKey`: Removes a specific capability from a key.
    *   `updateCapabilityConditions`: Modifies the time or state conditions for an existing capability.

5.  **Capability Delegation:**
    *   `delegateCapability`: Allows a key holder to temporarily or conditionally delegate one of their key's capabilities to another address.
    *   `revokeDelegation`: Cancels a specific delegation.

6.  **State Entanglement Proof System:**
    *   `submitStateEntanglementProof`: Initiates a potential action by submitting a structured proof claim, linking it to a key, required capabilities, and target conditions.
    *   `verifyProofConditions`: Internal helper function to check if a proof's claimed conditions (capabilities, time, external state) are met based on the current blockchain state.
    *   `approveProofSubmission`: Allows an authorized address (e.g., owner, specific key holder) to approve a pending proof, potentially fulfilling a multi-approval requirement.
    *   `revokeProofApproval`: Removes an approval from a proof.
    *   `finalizeProofExecution`: Marks a proof as executed *after* `executeConditionalWithdrawal` or another action consumes it. (Internal helper).
    *   `cancelStateEntanglementProof`: Allows the submitter or an authorized key holder to cancel a pending or invalid proof.

7.  **State & Condition Management (Simulated Oracle/Admin):**
    *   `updateExternalCondition`: Allows the owner or a designated key holder with `CAN_UPDATE_STATE` to change a state variable that proof verification might depend on.
    *   `setRequiredApprovalsForProofType`: Configures how many approvals are needed for a specific type of proof submission.

8.  **Access Control & Pausability:**
    *   `pauseContract`: Owner function to pause core operations (deposit, withdrawal, proof submission).
    *   `unpauseContract`: Owner function to unpause the contract.

9.  **View Functions:**
    *   `getUserBalance`: Get the vault balance for a user for a specific token.
    *   `getKeyDetails`: Get information about a specific Entanglement Key.
    *   `getKeyCapabilityDetails`: Get details for a specific capability assigned to a key.
    *   `getDelegationDetails`: Get details for a specific capability delegation.
    *   `getProofDetails`: Get information about a submitted State Entanglement Proof.
    *   `checkKeyCapabilityValidity`: Checks if a key *currently* has a specific capability and if its conditions are met.
    *   `checkDelegatedCapabilityValidity`: Checks if an address *currently* has a delegated capability.
    *   `getRequiredApprovalsForProofType`: Gets the required approval count for a proof type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom error codes for clarity and gas efficiency (Solidity 0.8.4+)
error InvalidKey(uint256 keyId);
error KeyNotOwnedByUser(uint256 keyId, address user);
error CapabilityNotFound(uint256 keyId, CapabilityType capabilityType);
error DelegationNotFound(uint256 keyId, address delegatee, CapabilityType capabilityType);
error ProofNotFound(uint256 proofId);
error ProofNotPending(uint256 proofId);
error ProofAlreadyExecuted(uint256 proofId);
error ProofConditionsNotMet(uint256 proofId);
error ProofRequiresMoreApprovals(uint256 proofId, uint256 needed, uint256 received);
error ProofAlreadyApproved(uint256 proofId, address approver);
error ProofNotSubmittedBy(uint256 proofId, address submitter);
error InsufficientBalance(address token, uint256 requested, uint256 available);
error ActionPaused();
error NoPermission(string reason);
error InvalidState(string reason);


contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _keyIds;
    Counters.Counter private _proofIds;

    // --- Enums ---
    enum CapabilityType {
        // Basic Vault Ops
        CAN_DEPOSIT,          // Can deposit tokens (might be restricted later)
        CAN_INITIATE_WITHDRAWAL, // Can start the withdrawal process (requires proof)
        // Key & Capability Management
        CAN_CREATE_KEY,       // Can create new Entanglement Keys
        CAN_ASSIGN_CAPABILITY, // Can assign capabilities to keys
        CAN_REMOVE_CAPABILITY, // Can remove capabilities from keys
        CAN_TRANSFER_KEY,      // Can transfer key ownership
        CAN_REVOKE_KEY,        // Can revoke Entanglement Keys
        CAN_UPDATE_CAPABILITY_CONDITIONS, // Can change conditions of assigned caps
        // Delegation
        CAN_DELEGATE_CAPABILITY, // Can delegate capabilities they hold via a key
        CAN_REVOKE_DELEGATION,   // Can revoke a specific delegation
        // Proof System Interaction
        CAN_SUBMIT_PROOF,        // Can submit a State Entanglement Proof
        CAN_APPROVE_PROOF,       // Can approve a submitted proof (if required)
        CAN_CANCEL_PROOF,        // Can cancel a submitted proof
        CAN_UPDATE_STATE         // Can update simulated external conditions
    }

    enum ProofStatus {
        Pending,    // Awaiting verification and approvals
        Approved,   // Conditions met, approvals gathered (if any)
        Executed,   // Action (e.g., withdrawal) completed using this proof
        Cancelled,  // Cancelled by submitter or authorized party
        Invalid     // Failed verification or expired
    }

    // --- Structs ---

    struct EntanglementKey {
        uint256 id;
        address owner;
        bool active; // Can be revoked
        uint256 createdAt;
        string metadataURI; // Optional: Link to off-chain data about the key purpose
    }

    struct KeyCapability {
        CapabilityType capabilityType;
        uint256 assignedAt;
        uint256 validFrom; // Unix timestamp
        uint256 validUntil; // Unix timestamp (0 for infinite)
        uint256 requiredExternalState; // A value from `externalConditions` that must match
        bool requiresExternalStateMatch; // Whether `requiredExternalState` check is active
    }

    struct CapabilityDelegation {
        address delegatee;
        uint256 delegatedAt;
        uint256 validUntil; // Unix timestamp (0 for infinite)
        uint256 delegatingKeyId; // The key from which this capability was delegated
    }

    struct StateEntanglementProof {
        uint256 id;
        address submitter;
        uint256 submittedAt;
        uint256 executingKeyId; // The key used to submit the proof
        CapabilityType requiredCapability; // The main capability needed from the key
        address targetAddress; // e.g., address to withdraw to
        IERC20 targetToken;   // e.g., token to withdraw
        uint256 targetAmount; // e.g., amount to withdraw
        bytes proofData;      // Placeholder for off-chain proof data or complex parameters
        ProofStatus status;
        mapping(address => bool) approvals; // Which addresses have approved
        uint256 approvalCount;
    }

    // --- State Variables ---

    // Balances: token address -> user address -> amount
    mapping(IERC20 => mapping(address => uint256)) public balances;

    // Entanglement Keys: key ID -> key data
    mapping(uint256 => EntanglementKey) public entanglementKeys;
    // Which address owns a key ID
    mapping(uint256 => address) public keyOwner;
    // Keys owned by an address (less efficient to list, but useful lookup)
    mapping(address => uint256[]) private _ownedKeys; // Keep track for internal use

    // Capabilities: key ID -> capability type -> capability data
    mapping(uint256 => mapping(CapabilityType => KeyCapability)) private _keyCapabilities;
    // Check if a key has a specific capability assigned
    mapping(uint256 => mapping(CapabilityType => bool)) private _keyHasCapability;

    // Delegations: key ID -> delegatee address -> capability type -> delegation data
    mapping(uint256 => mapping(address => mapping(CapabilityType => CapabilityDelegation))) private _capabilityDelegations;
    // Check if a capability is delegated from a key to an address
    mapping(uint256 => mapping(address => mapping(CapabilityType => bool))) private _isCapabilityDelegated;

    // Proofs: proof ID -> proof data
    mapping(uint256 => StateEntanglementProof) public stateEntanglementProofs;
    // Which addresses have approved a proof
    mapping(uint256 => mapping(address => bool)) public proofApprovals;

    // Proof Configuration: proof type (main capability) -> required approval count
    mapping(CapabilityType => uint256) public requiredProofApprovals;

    // Simulated External Conditions (can be updated by CAN_UPDATE_STATE key holder)
    uint256 public externalConditions;

    bool public paused = false;

    // --- Events ---
    event Deposited(address indexed user, IERC20 indexed token, uint256 amount);
    event Withdrawn(address indexed user, IERC20 indexed token, uint256 amount, uint256 proofId);
    event EntanglementKeyCreated(uint256 indexed keyId, address indexed owner, address creator);
    event KeyOwnershipTransferred(uint256 indexed keyId, address indexed oldOwner, address indexed newOwner);
    event EntanglementKeyRevoked(uint256 indexed keyId, address indexed revoker);
    event CapabilityAssigned(uint256 indexed keyId, CapabilityType indexed capabilityType, address indexed assigner);
    event CapabilityRemoved(uint256 indexed keyId, CapabilityType indexed capabilityType, address indexed remover);
    event CapabilityConditionsUpdated(uint256 indexed keyId, CapabilityType indexed capabilityType, address indexed updater);
    event CapabilityDelegated(uint256 indexed keyId, address indexed delegatee, CapabilityType indexed capabilityType, address delegator);
    event DelegationRevoked(uint256 indexed keyId, address indexed delegatee, CapabilityType indexed capabilityType, address revoker);
    event ProofSubmitted(uint256 indexed proofId, address indexed submitter, uint256 indexed executingKeyId, CapabilityType requiredCapability);
    event ProofStatusChanged(uint256 indexed proofId, ProofStatus oldStatus, ProofStatus newStatus);
    event ProofApproved(uint256 indexed proofId, address indexed approver);
    event ExternalConditionUpdated(uint256 indexed oldValue, uint256 indexed newValue, address updater);
    event ProofApprovalRequirementUpdated(CapabilityType indexed capabilityType, uint256 indexed requiredCount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert ActionPaused();
        _;
    }

    modifier onlyKeyHolder(uint256 _keyId) {
        if (keyOwner[_keyId] != _msgSender()) revert KeyNotOwnedByUser(_keyId, _msgSender());
        if (!entanglementKeys[_keyId].active) revert InvalidKey(_keyId);
        _;
    }

    // Checks if the caller or a key owned/delegated to the caller has a specific capability
    modifier hasCapability(uint256 _keyId, CapabilityType _capabilityType) {
        // Check ownership first (most common case)
        if (keyOwner[_keyId] == _msgSender()) {
            if (!entanglementKeys[_keyId].active) revert InvalidKey(_keyId);
            if (!_keyHasCapability[_keyId][_capabilityType]) revert CapabilityNotFound(_keyId, _capabilityType);
            if (!checkKeyCapabilityValidity(_keyId, _capabilityType)) revert InvalidState("Key capability conditions not met");
            _;
        } else {
             // Check delegation
            if (!entanglementKeys[_keyId].active) revert InvalidKey(_keyId);
            if (!_isCapabilityDelegated[_keyId][_msgSender()][_capabilityType]) revert DelegationNotFound(_keyId, _msgSender(), _capabilityType);
            if (!checkDelegatedCapabilityValidity(_keyId, _msgSender(), _capabilityType)) revert InvalidState("Delegated capability conditions not met");
            _;
        }
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        // Owner gets a default capability to start creating keys/assigning permissions
        // Let's give the owner the ability to create keys and update state initially
        uint256 ownerKeyId = _keyIds.current();
        _keyIds.increment();
        entanglementKeys[ownerKeyId] = EntanglementKey(ownerKeyId, initialOwner, true, block.timestamp, "Initial Owner Key");
        keyOwner[ownerKeyId] = initialOwner;
        _ownedKeys[initialOwner].push(ownerKeyId);

        // Assign initial capabilities to the owner's key
        _assignCapability(ownerKeyId, CapabilityType.CAN_CREATE_KEY, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_UPDATE_STATE, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_ASSIGN_CAPABILITY, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_REMOVE_CAPABILITY, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_REVOKE_KEY, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_TRANSFER_KEY, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_UPDATE_CAPABILITY_CONDITIONS, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_DELEGATE_CAPABILITY, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_REVOKE_DELEGATION, block.timestamp, 0, 0, false, initialOwner);
        _assignCapability(ownerKeyId, CapabilityType.CAN_SUBMIT_PROOF, block.timestamp, 0, 0, false, initialOwner); // Can submit general proofs
        _assignCapability(ownerKeyId, CapabilityType.CAN_APPROVE_PROOF, block.timestamp, 0, 0, false, initialOwner); // Can approve proofs
        _assignCapability(ownerKeyId, CapabilityType.CAN_CANCEL_PROOF, block.timestamp, 0, 0, false, initialOwner); // Can cancel proofs
    }

    // --- Vault Operations ---

    /// @notice Deposits ERC20 tokens into the vault.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(IERC20 token, uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidState("Deposit amount must be > 0");
        token.safeTransferFrom(_msgSender(), address(this), amount);
        balances[token][_msgSender()] += amount;
        emit Deposited(_msgSender(), token, amount);
    }

    /// @notice Emergency function for the owner to withdraw any token from the contract.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20OwnerEmergency(IERC20 token, uint256 amount) public onlyOwner whenNotPaused {
        if (amount == 0) revert InvalidState("Withdrawal amount must be > 0");
        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < amount) revert InsufficientBalance(address(token), amount, contractBalance);
        token.safeTransfer(owner(), amount);
        // Note: This doesn't affect user balances mapping, only contract balance.
        // Use with caution, primarily for retrieving stuck tokens or full migration.
    }

    /// @notice Executes a withdrawal action based on a valid and approved State Entanglement Proof.
    /// This is the *only* way for users to withdraw their deposited funds normally.
    /// @param proofId The ID of the State Entanglement Proof.
    function executeConditionalWithdrawal(uint256 proofId) public nonReentrant whenNotPaused {
        StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.id == 0 && proofId != 0) revert ProofNotFound(proofId); // Check if proof exists (handle ID 0)
        if (proof.status != ProofStatus.Approved) revert ProofNotPending(proofId); // Must be approved
        if (proof.requiredCapability != CapabilityType.CAN_INITIATE_WITHDRAWAL) revert InvalidState("Proof not for withdrawal");

        address user = proof.submitter;
        IERC20 token = proof.targetToken;
        uint256 amount = proof.targetAmount;

        if (balances[token][user] < amount) revert InsufficientBalance(address(token), amount, balances[token][user]);

        balances[token][user] -= amount;
        token.safeTransfer(proof.targetAddress, amount); // Transfer to the target address in the proof

        _finalizeProofExecution(proofId); // Mark proof as executed

        emit Withdrawn(user, token, amount, proofId);
    }

    // --- Entanglement Key Management ---

    /// @notice Creates a new Entanglement Key. Requires caller to have CAN_CREATE_KEY capability via a key they control.
    /// @param submitterKeyId The ID of the key used by the caller to authorize this action.
    /// @param newOwner The address that will own the new key.
    /// @param metadataURI Optional URI for off-chain metadata.
    /// @return The ID of the newly created key.
    function createEntanglementKey(uint256 submitterKeyId, address newOwner, string calldata metadataURI)
        public
        whenNotPaused
        hasCapability(submitterKeyId, CapabilityType.CAN_CREATE_KEY)
        returns (uint256)
    {
        if (newOwner == address(0)) revert InvalidState("New owner cannot be zero address");

        uint256 newKeyId = _keyIds.current();
        _keyIds.increment();

        entanglementKeys[newKeyId] = EntanglementKey(newKeyId, newOwner, true, block.timestamp, metadataURI);
        keyOwner[newKeyId] = newOwner;
        _ownedKeys[newOwner].push(newKeyId);

        emit EntanglementKeyCreated(newKeyId, newOwner, _msgSender());
        return newKeyId;
    }

    /// @notice Transfers ownership of an Entanglement Key. Requires caller to own the key and have CAN_TRANSFER_KEY capability.
    /// @param keyId The ID of the key to transfer.
    /// @param newOwner The address that will become the new owner.
    function transferKeyOwnership(uint256 keyId, address newOwner)
        public
        whenNotPaused
        onlyKeyHolder(keyId)
        hasCapability(keyId, CapabilityType.CAN_TRANSFER_KEY)
    {
        if (newOwner == address(0)) revert InvalidState("New owner cannot be zero address");
        if (keyOwner[keyId] == newOwner) revert InvalidState("New owner is already the current owner");

        address oldOwner = keyOwner[keyId];

        // Remove from old owner's list (less efficient way)
        uint256[] storage oldOwnerKeys = _ownedKeys[oldOwner];
        for (uint i = 0; i < oldOwnerKeys.length; i++) {
            if (oldOwnerKeys[i] == keyId) {
                oldOwnerKeys[i] = oldOwnerKeys[oldOwnerKeys.length - 1];
                oldOwnerKeys.pop();
                break;
            }
        }

        // Update owner and add to new owner's list
        entanglementKeys[keyId].owner = newOwner; // Update owner in the struct
        keyOwner[keyId] = newOwner;
        _ownedKeys[newOwner].push(keyId);

        emit KeyOwnershipTransferred(keyId, oldOwner, newOwner);
    }

    /// @notice Revokes an Entanglement Key, rendering it permanently inactive. Requires caller to own the key and have CAN_REVOKE_KEY capability.
    /// @param keyId The ID of the key to revoke.
    function revokeEntanglementKey(uint256 keyId)
        public
        whenNotPaused
        onlyKeyHolder(keyId)
        hasCapability(keyId, CapabilityType.CAN_REVOKE_KEY)
    {
        EntanglementKey storage key = entanglementKeys[keyId];
        if (!key.active) revert InvalidKey(keyId); // Already inactive

        key.active = false;

        // Note: Capabilities and delegations assigned *from* this key remain in storage
        // but checkKeyCapabilityValidity/checkDelegatedCapabilityValidity will fail
        // because key.active is false. We don't explicitly delete to save gas,
        // relying on the validity checks.

        // Consider clearing approvals associated with proofs submitted by this key?
        // Or simply let proof validity check fail due to inactive key. Let's go with simpler validity check failure.

        emit EntanglementKeyRevoked(keyId, _msgSender());
    }

    // --- Key Capability Management ---

    /// @notice Assigns a capability to an Entanglement Key. Requires caller to have CAN_ASSIGN_CAPABILITY capability via a key they control.
    /// @param submitterKeyId The ID of the key used by the caller to authorize this action.
    /// @param targetKeyId The ID of the key to assign the capability to.
    /// @param capabilityType The capability to assign.
    /// @param validFrom Unix timestamp when the capability becomes active (0 for immediate).
    /// @param validUntil Unix timestamp when the capability expires (0 for infinite).
    /// @param requiredExternalState If requiresExternalStateMatch is true, this is the required value of `externalConditions`.
    /// @param requiresExternalStateMatch Whether the capability is conditional on `externalConditions`.
    function assignCapabilityToKey(
        uint256 submitterKeyId,
        uint256 targetKeyId,
        CapabilityType capabilityType,
        uint256 validFrom,
        uint256 validUntil,
        uint256 requiredExternalState,
        bool requiresExternalStateMatch
    )
        public
        whenNotPaused
        hasCapability(submitterKeyId, CapabilityType.CAN_ASSIGN_CAPABILITY)
    {
        if (entanglementKeys[targetKeyId].id == 0 && targetKeyId != 0) revert InvalidKey(targetKeyId); // Check if target key exists
        if (!entanglementKeys[targetKeyId].active) revert InvalidKey(targetKeyId); // Target key must be active

        _keyCapabilities[targetKeyId][capabilityType] = KeyCapability({
            capabilityType: capabilityType,
            assignedAt: block.timestamp,
            validFrom: validFrom == 0 ? block.timestamp : validFrom, // Default to now if 0
            validUntil: validUntil,
            requiredExternalState: requiredExternalState,
            requiresExternalStateMatch: requiresExternalStateMatch
        });
        _keyHasCapability[targetKeyId][capabilityType] = true;

        emit CapabilityAssigned(targetKeyId, capabilityType, _msgSender());
    }

     // Internal helper for initial assignment in constructor
    function _assignCapability(
        uint256 targetKeyId,
        CapabilityType capabilityType,
        uint256 validFrom,
        uint256 validUntil,
        uint256 requiredExternalState,
        bool requiresExternalStateMatch,
        address assigner
    ) internal {
         _keyCapabilities[targetKeyId][capabilityType] = KeyCapability({
            capabilityType: capabilityType,
            assignedAt: block.timestamp,
            validFrom: validFrom == 0 ? block.timestamp : validFrom,
            validUntil: validUntil,
            requiredExternalState: requiredExternalState,
            requiresExternalStateMatch: requiresExternalStateMatch
        });
        _keyHasCapability[targetKeyId][capabilityType] = true;

        emit CapabilityAssigned(targetKeyId, capabilityType, assigner);
    }


    /// @notice Removes a capability from an Entanglement Key. Requires caller to have CAN_REMOVE_CAPABILITY capability via a key they control.
    /// @param submitterKeyId The ID of the key used by the caller to authorize this action.
    /// @param targetKeyId The ID of the key to remove the capability from.
    /// @param capabilityType The capability to remove.
    function removeCapabilityFromKey(
        uint256 submitterKeyId,
        uint256 targetKeyId,
        CapabilityType capabilityType
    )
        public
        whenNotPaused
        hasCapability(submitterKeyId, CapabilityType.CAN_REMOVE_CAPABILITY)
    {
        if (entanglementKeys[targetKeyId].id == 0 && targetKeyId != 0) revert InvalidKey(targetKeyId);
        if (!_keyHasCapability[targetKeyId][capabilityType]) revert CapabilityNotFound(targetKeyId, capabilityType);

        delete _keyCapabilities[targetKeyId][capabilityType];
        _keyHasCapability[targetKeyId][capabilityType] = false;

        // Also revoke any active delegations for this specific capability from this key
        // This is gas-intensive if many delegations exist.
        // A more gas-efficient design might rely solely on validity checks (which will fail anyway).
        // Let's rely on validity checks for now. Delegations remain but are invalid.

        emit CapabilityRemoved(targetKeyId, capabilityType, _msgSender());
    }

    /// @notice Updates the conditions (time, external state) for an existing capability on a key. Requires caller to have CAN_UPDATE_CAPABILITY_CONDITIONS capability via a key they control.
    /// @param submitterKeyId The ID of the key used by the caller to authorize this action.
    /// @param targetKeyId The ID of the key whose capability conditions to update.
    /// @param capabilityType The capability type to update.
    /// @param validFrom New Unix timestamp when the capability becomes active (0 for immediate).
    /// @param validUntil New Unix timestamp when the capability expires (0 for infinite).
    /// @param requiredExternalState New required value of `externalConditions` if requiresExternalStateMatch is true.
    /// @param requiresExternalStateMatch Whether the capability is now conditional on `externalConditions`.
    function updateCapabilityConditions(
        uint256 submitterKeyId,
        uint256 targetKeyId,
        CapabilityType capabilityType,
        uint256 validFrom,
        uint256 validUntil,
        uint256 requiredExternalState,
        bool requiresExternalStateMatch
    )
        public
        whenNotPaused
        hasCapability(submitterKeyId, CapabilityType.CAN_UPDATE_CAPABILITY_CONDITIONS)
    {
         if (entanglementKeys[targetKeyId].id == 0 && targetKeyId != 0) revert InvalidKey(targetKeyId);
         if (!entanglementKeys[targetKeyId].active) revert InvalidKey(targetKeyId);
         if (!_keyHasCapability[targetKeyId][capabilityType]) revert CapabilityNotFound(targetKeyId, capabilityType);

         _keyCapabilities[targetKeyId][capabilityType].validFrom = validFrom == 0 ? block.timestamp : validFrom;
         _keyCapabilities[targetKeyId][capabilityType].validUntil = validUntil;
         _keyCapabilities[targetKeyId][capabilityType].requiredExternalState = requiredExternalState;
         _keyCapabilities[targetKeyId][capabilityType].requiresExternalStateMatch = requiresExternalStateMatch;

         emit CapabilityConditionsUpdated(targetKeyId, capabilityType, _msgSender());
    }


    // --- Capability Delegation ---

    /// @notice Delegates a specific capability from one of the caller's keys to another address. Requires caller to own `delegatingKeyId` and have CAN_DELEGATE_CAPABILITY capability.
    /// @param delegatingKeyId The ID of the key held by the caller, which possesses the capability to delegate.
    /// @param delegatee The address receiving the delegation.
    /// @param capabilityType The capability being delegated. Must exist on `delegatingKeyId`.
    /// @param validUntil Unix timestamp when the delegation expires (0 for infinite, but infinite delegation is risky).
    function delegateCapability(
        uint256 delegatingKeyId,
        address delegatee,
        CapabilityType capabilityType,
        uint256 validUntil
    )
        public
        whenNotPaused
        onlyKeyHolder(delegatingKeyId) // Caller must own the key
        hasCapability(delegatingKeyId, CapabilityType.CAN_DELEGATE_CAPABILITY) // The key must have delegation power
    {
        if (delegatee == address(0)) revert InvalidState("Delegatee cannot be zero address");
        if (!_keyHasCapability[delegatingKeyId][capabilityType]) revert CapabilityNotFound(delegatingKeyId, capabilityType);

        // Ensure the *key* still has the capability to delegate it
        if (!checkKeyCapabilityValidity(delegatingKeyId, capabilityType)) revert InvalidState("Key capability invalid for delegation");

        _capabilityDelegations[delegatingKeyId][delegatee][capabilityType] = CapabilityDelegation({
            delegatee: delegatee,
            delegatedAt: block.timestamp,
            validUntil: validUntil,
            delegatingKeyId: delegatingKeyId
        });
        _isCapabilityDelegated[delegatingKeyId][delegatee][capabilityType] = true;

        emit CapabilityDelegated(delegatingKeyId, delegatee, capabilityType, _msgSender());
    }

    /// @notice Revokes a previously created capability delegation. Requires caller to own the `delegatingKeyId` or have CAN_REVOKE_DELEGATION capability via another key.
    /// @param delegatingKeyId The ID of the key from which the capability was delegated.
    /// @param delegatee The address the capability was delegated to.
    /// @param capabilityType The capability type that was delegated.
    function revokeDelegation(
        uint256 delegatingKeyId,
        address delegatee,
        CapabilityType capabilityType
    )
        public
        whenNotPaused
    {
        // Caller must either own the key or have CAN_REVOKE_DELEGATION capability
        bool hasRevokeCapability = false;
        // This check is inefficient if user has many keys. A specific "Revoker" key ID could be required.
        // For this example, let's allow ownership or the specific capability via *any* owned/delegated key.
        uint256[] storage ownedKeys = _ownedKeys[_msgSender()];
        for (uint i = 0; i < ownedKeys.length; i++) {
            if (entanglementKeys[ownedKeys[i]].active && _keyHasCapability[ownedKeys[i]][CapabilityType.CAN_REVOKE_DELEGATION] && checkKeyCapabilityValidity(ownedKeys[i], CapabilityType.CAN_REVOKE_DELEGATION)) {
                hasRevokeCapability = true;
                break;
            }
        }
        // Also check delegated capabilities for CAN_REVOKE_DELEGATION? Potentially recursive/complex.
        // Let's simplify: caller must own the key OR hold CAN_REVOKE_DELEGATION directly on an owned key.
         if (keyOwner[delegatingKeyId] != _msgSender() && !hasRevokeCapability) {
             revert NoPermission("Must own key or have CAN_REVOKE_DELEGATION");
         }


        if (!_isCapabilityDelegated[delegatingKeyId][delegatee][capabilityType]) revert DelegationNotFound(delegatingKeyId, delegatee, capabilityType);

        delete _capabilityDelegations[delegatingKeyId][delegatee][capabilityType];
        _isCapabilityDelegated[delegatingKeyId][delegatee][capabilityType] = false;

        emit DelegationRevoked(delegatingKeyId, delegatee, capabilityType, _msgSender());
    }


    // --- State Entanglement Proof System ---

    /// @notice Submits a State Entanglement Proof claim. This requires the submitter to hold `executingKeyId` and possess `requiredCapability` (either directly or via delegation), with conditions met.
    /// The proof then enters a PENDING state, potentially requiring approvals before it can be used (e.g., for withdrawal).
    /// @param executingKeyId The key used to initiate the proof.
    /// @param requiredCapability The capability required from the key for this proof type (e.g., CAN_INITIATE_WITHDRAWAL).
    /// @param targetAddress The address the action is directed towards (e.g., withdrawal recipient).
    /// @param targetToken The token involved in the action (e.g., token to withdraw).
    /// @param targetAmount The amount involved in the action (e.g., amount to withdraw).
    /// @param proofData Placeholder for complex parameters or off-chain proof verification data.
    /// @return The ID of the submitted proof.
    function submitStateEntanglementProof(
        uint256 executingKeyId,
        CapabilityType requiredCapability,
        address targetAddress,
        IERC20 targetToken,
        uint256 targetAmount,
        bytes calldata proofData
    )
        public
        whenNotPaused
        hasCapability(executingKeyId, requiredCapability) // Verifies caller controls key/delegation & conditions met
        // Add specific checks for CAN_SUBMIT_PROOF if needed, but hasCapability can cover it if requiredCapability is CAN_SUBMIT_PROOF
    {
        if (requiredCapability != CapabilityType.CAN_INITIATE_WITHDRAWAL &&
            requiredCapability != CapabilityType.CAN_SUBMIT_PROOF // Example: allow generic proofs
           ) {
               revert InvalidState("Unsupported required capability for proof submission");
           }

        uint256 newProofId = _proofIds.current();
        _proofIds.increment();

        StateEntanglementProof storage newProof = stateEntanglementProofs[newProofId];
        newProof.id = newProofId;
        newProof.submitter = _msgSender();
        newProof.submittedAt = block.timestamp;
        newProof.executingKeyId = executingKeyId;
        newProof.requiredCapability = requiredCapability;
        newProof.targetAddress = targetAddress;
        newProof.targetToken = targetToken;
        newProof.targetAmount = targetAmount;
        newProof.proofData = proofData; // Store the data
        newProof.status = ProofStatus.Pending;
        newProof.approvalCount = 0;
        // Note: 'approvals' mapping is nested within the struct storage

        // Proof state transition logic: Check initial conditions and approvals
        _updateProofStatus(newProofId); // Check if immediately approved

        emit ProofSubmitted(newProofId, _msgSender(), executingKeyId, requiredCapability);
        return newProofId;
    }

    /// @notice Allows an authorized address (configured via `requiredProofApprovals` and potentially `CAN_APPROVE_PROOF` capability) to approve a pending proof.
    /// @param proofId The ID of the proof to approve.
    function approveProofSubmission(uint256 proofId) public whenNotPaused {
        StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.id == 0 && proofId != 0) revert ProofNotFound(proofId);
        if (proof.status != ProofStatus.Pending) revert ProofNotPending(proofId);
        if (proof.approvals[_msgSender()]) revert ProofAlreadyApproved(proofId, _msgSender());

        // Add check: Does _msgSender() have the CAN_APPROVE_PROOF capability (via owned/delegated key)?
        bool canApprove = false;
         uint224[] memory userKeyIds = getUserKeyIds(_msgSender()); // Efficient way to get owned key IDs
         for(uint i=0; i < userKeyIds.length; i++){
             uint256 userKeyId = userKeyIds[i];
             if (entanglementKeys[userKeyId].active && _keyHasCapability[userKeyId][CapabilityType.CAN_APPROVE_PROOF] && checkKeyCapabilityValidity(userKeyId, CapabilityType.CAN_APPROVE_PROOF)){
                 canApprove = true;
                 break;
             }
         }
         // Check delegations for CAN_APPROVE_PROOF capability? (Could add another loop over all active keys and their delegations to _msgSender())
         // For simplicity, let's require the approver to *own* a key with CAN_APPROVE_PROOF.
         if (!canApprove) revert NoPermission("Caller must own a key with CAN_APPROVE_PROOF capability");


        proof.approvals[_msgSender()] = true;
        proof.approvalCount++;

        _updateProofStatus(proofId); // Re-check status after new approval

        emit ProofApproved(proofId, _msgSender());
    }

    /// @notice Allows an address who previously approved a proof to revoke their approval.
    /// @param proofId The ID of the proof to revoke approval from.
    function revokeProofApproval(uint256 proofId) public whenNotPaused {
         StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.id == 0 && proofId != 0) revert ProofNotFound(proofId);
        if (proof.status != ProofStatus.Pending) revert ProofNotPending(proofId); // Only allow revoking pending proofs
        if (!proof.approvals[_msgSender()]) revert InvalidState("Caller has not approved this proof");

        proof.approvals[_msgSender()] = false;
        proof.approvalCount--;

        // Note: Revoking an approval might change status from Approved back to Pending
        if (proof.status == ProofStatus.Approved) {
             _updateProofStatus(proofId); // Re-check status
        }


        emit ProofStatusChanged(proofId, proof.status, proof.status); // Status might or might not change
    }

    /// @notice Allows the proof submitter or a key holder with CAN_CANCEL_PROOF to cancel a pending or invalid proof.
    /// @param proofId The ID of the proof to cancel.
    function cancelStateEntanglementProof(uint256 proofId) public whenNotPaused {
        StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.id == 0 && proofId != 0) revert ProofNotFound(proofId);
        if (proof.status == ProofStatus.Executed || proof.status == ProofStatus.Cancelled) revert InvalidState("Proof cannot be cancelled in its current state");

        // Check permission: Must be the submitter OR have CAN_CANCEL_PROOF capability
        bool canCancel = (_msgSender() == proof.submitter);
        if (!canCancel) {
            // Check if caller has CAN_CANCEL_PROOF capability via an owned key
            uint224[] memory userKeyIds = getUserKeyIds(_msgSender());
            for(uint i=0; i < userKeyIds.length; i++){
                uint256 userKeyId = userKeyIds[i];
                if (entanglementKeys[userKeyId].active && _keyHasCapability[userKeyId][CapabilityType.CAN_CANCEL_PROOF] && checkKeyCapabilityValidity(userKeyId, CapabilityType.CAN_CANCEL_PROOF)){
                    canCancel = true;
                    break;
                }
            }
            // Check delegated CAN_CANCEL_PROOF capability? (Skipped for simplicity in this example)
        }

        if (!canCancel) revert NoPermission("Must be submitter or have CAN_CANCEL_PROOF capability");

        ProofStatus oldStatus = proof.status;
        proof.status = ProofStatus.Cancelled;

        emit ProofStatusChanged(proofId, oldStatus, ProofStatus.Cancelled);
    }

    // Internal: Checks proof conditions and required approvals, updates status
    function _updateProofStatus(uint256 proofId) internal {
        StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.status != ProofStatus.Pending) return; // Only update pending proofs

        // 1. Re-verify Key & Capability conditions (could have expired or been revoked since submission)
        if (!checkKeyCapabilityValidity(proof.executingKeyId, proof.requiredCapability)) {
             proof.status = ProofStatus.Invalid;
             emit ProofStatusChanged(proofId, ProofStatus.Pending, ProofStatus.Invalid);
             return;
        }
        // Note: Delegated capabilities cannot submit proofs directly in this design,
        // the submitter must use an *owned* key that *has* the capability (potentially delegated TO that key).
        // The `hasCapability` modifier on `submitStateEntanglementProof` handles this initial check.
        // This internal check only needs to verify the *key's* validity and its direct capability.

        // 2. Check required approvals
        uint256 requiredCount = requiredProofApprovals[proof.requiredCapability];

        if (proof.approvalCount >= requiredCount) {
            ProofStatus oldStatus = proof.status;
            proof.status = ProofStatus.Approved;
            emit ProofStatusChanged(proofId, oldStatus, ProofStatus.Approved);
        } else {
             // Status remains Pending if not enough approvals
        }
    }

    // Internal: Marks a proof as executed. Called after the action (e.g., withdrawal) is performed.
    function _finalizeProofExecution(uint256 proofId) internal {
        StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.status == ProofStatus.Executed) revert ProofAlreadyExecuted(proofId); // Should not happen if called correctly
        if (proof.status != ProofStatus.Approved) revert InvalidState("Proof must be Approved to be executed");

        ProofStatus oldStatus = proof.status;
        proof.status = ProofStatus.Executed;
        emit ProofStatusChanged(proofId, oldStatus, ProofStatus.Executed);
    }


    // --- State & Condition Management ---

    /// @notice Updates the simulated external condition value. Requires owner or a key holder with CAN_UPDATE_STATE capability.
    /// This variable can be used as a condition for capabilities and proofs.
    /// @param newValue The new value for the external condition.
    function updateExternalCondition(uint256 newValue) public whenNotPaused {
        // Check if owner OR if caller holds a key with CAN_UPDATE_STATE capability
        bool authorized = (_msgSender() == owner());
        if (!authorized) {
            uint224[] memory userKeyIds = getUserKeyIds(_msgSender());
            for(uint i=0; i < userKeyIds.length; i++){
                uint256 userKeyId = userKeyIds[i];
                 if (entanglementKeys[userKeyId].active && _keyHasCapability[userKeyId][CapabilityType.CAN_UPDATE_STATE] && checkKeyCapabilityValidity(userKeyId, CapabilityType.CAN_UPDATE_STATE)){
                    authorized = true;
                    break;
                 }
            }
        }

        if (!authorized) revert NoPermission("Caller must be owner or have CAN_UPDATE_STATE capability");

        uint256 oldValue = externalConditions;
        externalConditions = newValue;
        emit ExternalConditionUpdated(oldValue, newValue, _msgSender());
    }

    /// @notice Sets the number of approvals required for a proof submission type (identified by its required capability). Requires owner or a key holder with CAN_ASSIGN_CAPABILITY (as it configures proof capabilities).
    /// @param capabilityType The capability type associated with the proof type (e.g., CAN_INITIATE_WITHDRAWAL).
    /// @param requiredCount The number of approvals required.
    function setRequiredApprovalsForProofType(CapabilityType capabilityType, uint256 requiredCount) public whenNotPaused {
         // Check if owner OR if caller holds a key with CAN_ASSIGN_CAPABILITY
        bool authorized = (_msgSender() == owner());
         if (!authorized) {
            uint224[] memory userKeyIds = getUserKeyIds(_msgSender());
            for(uint i=0; i < userKeyIds.length; i++){
                uint256 userKeyId = userKeyIds[i];
                 if (entanglementKeys[userKeyId].active && _keyHasCapability[userKeyId][CapabilityType.CAN_ASSIGN_CAPABILITY] && checkKeyCapabilityValidity(userKeyId, CapabilityType.CAN_ASSIGN_CAPABILITY)){
                    authorized = true;
                    break;
                 }
            }
        }

        if (!authorized) revert NoPermission("Caller must be owner or have CAN_ASSIGN_CAPABILITY");

        requiredProofApprovals[capabilityType] = requiredCount;
        emit ProofApprovalRequirementUpdated(capabilityType, requiredCount);
    }

    // --- Access Control & Pausability ---

    /// @notice Pauses the contract, preventing most actions. Only owner can call.
    function pauseContract() public onlyOwner {
        paused = true;
        emit Paused(_msgSender());
    }

    /// @notice Unpauses the contract. Only owner can call.
    function unpauseContract() public onlyOwner {
        paused = false;
        emit Unpaused(_msgSender());
    }

    // --- View Functions ---

    /// @notice Gets the balance of a specific token for a user in the vault.
    /// @param token The address of the ERC20 token.
    /// @param user The address of the user.
    /// @return The balance amount.
    function getUserBalance(IERC20 token, address user) public view returns (uint256) {
        return balances[token][user];
    }

     /// @notice Gets the list of key IDs owned by a user.
     /// @param user The address of the user.
     /// @return An array of key IDs.
     function getUserKeyIds(address user) public view returns (uint224[] memory) {
         // Convert uint256 to uint224 to save gas on return array
         uint256[] storage userKeys256 = _ownedKeys[user];
         uint224[] memory userKeys224 = new uint224[](userKeys256.length);
         for(uint i=0; i < userKeys256.length; i++){
             userKeys224[i] = uint224(userKeys256[i]);
         }
         return userKeys224;
     }

    /// @notice Gets details of an Entanglement Key.
    /// @param keyId The ID of the key.
    /// @return Key data struct.
    function getKeyDetails(uint256 keyId) public view returns (EntanglementKey memory) {
        if (entanglementKeys[keyId].id == 0 && keyId != 0) revert InvalidKey(keyId);
        return entanglementKeys[keyId];
    }

    /// @notice Gets details of a specific capability assigned to a key.
    /// @param keyId The ID of the key.
    /// @param capabilityType The capability type.
    /// @return Capability data struct.
    function getKeyCapabilityDetails(uint256 keyId, CapabilityType capabilityType) public view returns (KeyCapability memory) {
         if (entanglementKeys[keyId].id == 0 && keyId != 0) revert InvalidKey(keyId);
         if (!_keyHasCapability[keyId][capabilityType]) revert CapabilityNotFound(keyId, capabilityType);
         return _keyCapabilities[keyId][capabilityType];
    }

    /// @notice Checks if a key currently possesses a capability and if its conditions are met.
    /// @param keyId The ID of the key.
    /// @param capabilityType The capability type.
    /// @return True if the key has the capability and conditions are valid, false otherwise.
    function checkKeyCapabilityValidity(uint256 keyId, CapabilityType capabilityType) public view returns (bool) {
        EntanglementKey storage key = entanglementKeys[keyId];
        if (key.id == 0 && keyId != 0) return false; // Key doesn't exist
        if (!key.active) return false; // Key is revoked

        if (!_keyHasCapability[keyId][capabilityType]) return false; // Capability not assigned

        KeyCapability storage capability = _keyCapabilities[keyId][capabilityType];

        // Check time validity
        if (capability.validFrom > block.timestamp) return false; // Not yet active
        if (capability.validUntil != 0 && capability.validUntil < block.timestamp) return false; // Expired

        // Check external state condition
        if (capability.requiresExternalStateMatch && externalConditions != capability.requiredExternalState) return false;

        return true; // All checks passed
    }

    /// @notice Gets details of a specific capability delegation.
    /// @param delegatingKeyId The ID of the key the capability was delegated from.
    /// @param delegatee The address the capability was delegated to.
    /// @param capabilityType The capability type delegated.
    /// @return Delegation data struct.
    function getDelegationDetails(uint256 delegatingKeyId, address delegatee, CapabilityType capabilityType) public view returns (CapabilityDelegation memory) {
        if (entanglementKeys[delegatingKeyId].id == 0 && delegatingKeyId != 0) revert InvalidKey(delegatingKeyId);
        if (!_isCapabilityDelegated[delegatingKeyId][delegatee][capabilityType]) revert DelegationNotFound(delegatingKeyId, delegatee, capabilityType);
        return _capabilityDelegations[delegatingKeyId][delegatee][capabilityType];
    }

    /// @notice Checks if an address currently has a specific delegated capability from a key and if conditions are met.
    /// @param delegatingKeyId The ID of the key the capability was delegated from.
    /// @param delegatee The address to check the delegation for.
    /// @param capabilityType The capability type.
    /// @return True if the delegation is valid, false otherwise.
    function checkDelegatedCapabilityValidity(uint256 delegatingKeyId, address delegatee, CapabilityType capabilityType) public view returns (bool) {
        EntanglementKey storage key = entanglementKeys[delegatingKeyId];
        if (key.id == 0 && delegatingKeyId != 0) return false; // Key doesn't exist
        if (!key.active) return false; // Key is revoked

        if (!_isCapabilityDelegated[delegatingKeyId][delegatee][capabilityType]) return false; // Delegation doesn't exist

        CapabilityDelegation storage delegation = _capabilityDelegations[delegatingKeyId][delegatee][capabilityType];

        // Check time validity of delegation
        if (delegation.validUntil != 0 && delegation.validUntil < block.timestamp) return false; // Delegation expired

        // Crucially, check if the *delegating key* itself still has the underlying capability and if *its* conditions are met.
        // A delegated capability is only valid if the source capability on the key is also valid.
        if (!checkKeyCapabilityValidity(delegatingKeyId, capabilityType)) return false;

        return true; // All checks passed
    }


    /// @notice Gets details of a State Entanglement Proof.
    /// @param proofId The ID of the proof.
    /// @return Proof data struct.
    function getProofDetails(uint256 proofId) public view returns (StateEntanglementProof memory) {
        if (stateEntanglementProofs[proofId].id == 0 && proofId != 0) revert ProofNotFound(proofId);
        return stateEntanglementProofs[proofId];
    }

    /// @notice Checks the current validity status of a submitted proof.
    /// This checks conditions *at the time of calling*, not just based on the stored status.
    /// @param proofId The ID of the proof.
    /// @return The current status of the proof.
     function checkProofValidity(uint256 proofId) public view returns (ProofStatus) {
        StateEntanglementProof storage proof = stateEntanglementProofs[proofId];
        if (proof.id == 0 && proofId != 0) return ProofStatus.Invalid; // Proof doesn't exist
        if (proof.status == ProofStatus.Executed || proof.status == ProofStatus.Cancelled || proof.status == ProofStatus.Invalid) {
            return proof.status; // Terminal states
        }

        // Re-evaluate conditions for Pending or Approved proofs
        // This check is similar to _updateProofStatus but doesn't change state.

         // 1. Verify Key & Capability conditions are *still* valid *now*
         // Proof submission uses `hasCapability` which handles delegation.
         // The proof stores the *key ID* used. We need to check if the *submitter* still controls that key
         // OR holds the required capability *via delegation* for that specific key.
         // This check is complex and potentially gas heavy in view function.
         // Let's simplify the view check: only check the key's direct capability validity.
         // A full validity check might be better off-chain or only in the execution step.
         // For simplicity here, let's verify the key's direct capability state.
         // A more rigorous system would require checking the submitter's control path.
         // Simplified check: Does the key exist and is it active? And does it *have* the capability? (Validity conditions are checked by checkKeyCapabilityValidity)
        if (!entanglementKeys[proof.executingKeyId].active || !_keyHasCapability[proof.executingKeyId][proof.requiredCapability] || !checkKeyCapabilityValidity(proof.executingKeyId, proof.requiredCapability)) {
            return ProofStatus.Invalid; // Key or its capability became invalid
        }


        // 2. Check required approvals
        uint256 requiredCount = requiredProofApprovals[proof.requiredCapability];
        if (proof.approvalCount < requiredCount) {
            return ProofStatus.Pending; // Still needs more approvals
        }

        // If we reach here, conditions and approvals are met *currently*.
        return ProofStatus.Approved;
     }


     /// @notice Gets the number of required approvals for a specific proof type.
     /// @param capabilityType The capability type defining the proof type.
     /// @return The required approval count.
    function getRequiredApprovalsForProofType(CapabilityType capabilityType) public view returns (uint256) {
        return requiredProofApprovals[capabilityType];
    }

    /// @notice Gets the number of approvals received for a submitted proof.
    /// @param proofId The ID of the proof.
    /// @return The current approval count.
    function getProofApprovalCount(uint256 proofId) public view returns (uint256) {
        if (stateEntanglementProofs[proofId].id == 0 && proofId != 0) revert ProofNotFound(proofId);
        return stateEntanglementProofs[proofId].approvalCount;
    }

    /// @notice Checks if a specific address has approved a proof.
    /// @param proofId The ID of the proof.
    /// @param approver The address to check.
    /// @return True if approved, false otherwise.
    function hasProofApproved(uint256 proofId, address approver) public view returns (bool) {
         if (stateEntanglementProofs[proofId].id == 0 && proofId != 0) revert ProofNotFound(proofId);
        return stateEntanglementProofs[proofId].approvals[approver];
    }

    /// @notice Gets the current value of the simulated external condition.
    /// @return The current external condition value.
    function getCurrentExternalCondition() public view returns (uint256) {
        return externalConditions;
    }

    // Add more view functions as needed for inspecting state (e.g., list all keys, list all proofs by user, etc.)
    // Listing all items in a mapping is generally not feasible or gas-efficient on-chain.
    // The current view functions allow inspection of specific items by ID.
}
```

**Explanation of Advanced Concepts:**

1.  **Entanglement Keys:** Instead of simple roles (like Admin, User), permissions are granted via unique, transferable NFTs (simulated by `uint256` IDs and ownership tracking) called "Entanglement Keys". These keys are the portable units of authority.
2.  **Granular Capabilities:** Each key doesn't just grant a single role, but a set of specific `CapabilityType` permissions (like `CAN_CREATE_KEY`, `CAN_INITIATE_WITHDRAWAL`, `CAN_UPDATE_STATE`).
3.  **Conditional Capabilities:** Capabilities assigned to keys are not always active. They can be conditional based on:
    *   Time windows (`validFrom`, `validUntil`).
    *   A simulated external state variable (`externalConditions`) matching a required value (`requiredExternalState`). This simulates requiring off-chain data or specific contract states (like a market price being above a threshold) to enable a capability.
4.  **Capability Delegation:** A key holder can delegate *specific capabilities* from their key to another address for a limited time. The validity of the delegation depends on the validity of the original capability on the key *and* the delegation's own time limit. This creates a chain of authority.
5.  **State Entanglement Proofs:** This is the core mechanism for guarded actions, particularly withdrawal. It's a struct (`StateEntanglementProof`) representing a claim ("I want to withdraw X tokens to Y address using Key Z, which has the `CAN_INITIATE_WITHDRAWAL` capability").
    *   Submitting a proof requires the caller to control the specified key and possess the `requiredCapability` *at the time of submission*, fulfilling all its conditions (time, external state).
    *   Once submitted, the proof enters a `Pending` state.
    *   The proof's status is checked against configured requirements (`requiredProofApprovals`).
    *   Other authorized parties (`CAN_APPROVE_PROOF` key holders) might need to `approveProofSubmission`. This builds a multi-sig like layer on top of the permission system.
    *   Only when the proof reaches the `Approved` state can a function like `executeConditionalWithdrawal` consume it to perform the actual action.
    *   The `checkProofValidity` view function allows querying the *current* state of a proof, which might change dynamically if the key's conditions change or more approvals are added.
6.  **Simulated External Conditions:** The `externalConditions` variable acts as a simple oracle or external state dependency. Capabilities and proofs can be made conditional on its value. Updating it requires a specific permission (`CAN_UPDATE_STATE`), showcasing how external factors can be integrated into on-chain logic.
7.  **Dynamic Permission Checks:** The `hasCapability` modifier and helper functions (`checkKeyCapabilityValidity`, `checkDelegatedCapabilityValidity`) encapsulate the complex logic of verifying not just if a capability was *assigned*, but if it's *currently valid* based on the key's active status, time constraints, external conditions, and delegation status.

This contract structure creates a powerful, albeit complex, system for managing assets and permissions that goes significantly beyond standard ownership or simple role-based access control, incorporating temporal logic, state dependencies, and multi-party verification requirements via the proof system.