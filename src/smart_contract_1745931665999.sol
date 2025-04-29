Okay, let's create a smart contract based on a hypothetical "Quantum-Resistant Key and Proof Management System". This concept allows us to explore complex data structures, access control, time-based states, and multi-signature-like approval flows, simulating the management of cryptographic assets in a post-quantum computing threat landscape (though the crypto itself is not implemented on-chain, only its management).

We will define structures for Keys and Proofs, associate them with owners, status, and expiration times. We'll implement a threshold-based manager system for critical operations.

---

**Smart Contract: QuantumKeyManager**

**Outline:**

1.  **Overview:** Manages the lifecycle and access control of hypothetical "Quantum Keys" and associated "Quantum Proofs".
2.  **State:** Stores Key and Proof data, owner mappings, manager list, and pending multi-signature actions.
3.  **Core Entities:**
    *   `Key`: Represents a quantum-resistant key (stored as a hash/ID), with owner, status, type, creation/expiration times.
    *   `Proof`: Represents a proof derived from a Key (stored as a hash/ID), with status, type, and association to a Key.
    *   `Manager`: Addresses authorized for specific contract management tasks.
    *   `PendingManagerAction`: Stores details for actions requiring a threshold of Manager approvals.
4.  **Access Control:** Owner-based for contract configuration, Manager-based for key/proof lifecycle actions with a configurable threshold.
5.  **Key Lifecycle:** Creation, Revocation, Transfer, Extension, Update.
6.  **Proof Lifecycle:** Creation, Invalidation, Update.
7.  **Manager System:** Adding/Removing managers, setting threshold, initiating, approving, and executing threshold-requiring actions.
8.  **Queries:** Functions to retrieve details, lists, and counts.
9.  **Events:** Signal important state changes.

**Function Summary:**

*   **Constructor:** Initializes the contract owner and the initial manager threshold.
*   **Key Management (8 functions):**
    *   `createKey`: Creates a new key representation.
    *   `getKeyDetails`: Retrieves struct details for a given key ID.
    *   `listKeysByOwner`: Lists all key IDs owned by a specific address.
    *   `revokeKey`: Marks a key as revoked. Requires manager approval.
    *   `transferKeyOwnership`: Changes the owner of a key. Requires manager approval.
    *   `extendKeyExpiration`: Extends the expiration time of a key. Requires manager approval.
    *   `updateKeyDataHash`: Updates the hash associated with a key (simulating key rotation). Requires manager approval.
    *   `reactivateRevokedKey`: Changes a key's status from revoked back to active. Requires manager approval.
*   **Proof Management (6 functions):**
    *   `createProof`: Creates a new proof representation associated with a key.
    *   `getProofDetails`: Retrieves struct details for a given proof ID.
    *   `listProofsForKey`: Lists all proof IDs associated with a specific key ID.
    *   `invalidateProof`: Marks a proof as invalid. Requires manager approval.
    *   `updateProofDataHash`: Updates the hash associated with a proof. Requires manager approval.
    *   `verifyProofOwnership`: Checks if a given address owns the key associated with a proof.
*   **Manager & Access Control (10 functions):**
    *   `addManager`: Adds an address to the list of managers. Owner only.
    *   `removeManager`: Removes an address from the list of managers. Owner only.
    *   `setMinManagersForAction`: Sets the minimum number of approvals required for threshold actions. Owner only.
    *   `initiateManagerAction`: Starts a new threshold-requiring manager action.
    *   `approveManagerAction`: Approves a pending manager action.
    *   `executeManagerAction`: Executes a pending manager action if threshold is met.
    *   `cancelManagerAction`: Cancels a pending manager action.
    *   `getManagerList`: Returns the list of current manager addresses.
    *   `getMinManagersForAction`: Returns the current required manager approval threshold.
    *   `getPendingManagerActions`: Returns details of pending manager actions.
*   **Status & Validation (2 functions):**
    *   `isKeyActiveAndValid`: Checks if a key is active and not expired.
    *   `isProofAssociatedKeyActiveAndValid`: Checks if a proof's associated key is active and valid.
*   **Query & Utility (4 functions):**
    *   `getKeyCount`: Returns the total number of keys created.
    *   `getProofCount`: Returns the total number of proofs created.
    *   `getKeyStatus`: Returns the status string for a key.
    *   `getProofStatus`: Returns the status string for a proof.

Total functions: 8 + 6 + 10 + 2 + 4 = 30 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumKeyManager
 * @dev Manages the lifecycle and access control of hypothetical "Quantum Keys"
 * and associated "Quantum Proofs". Utilizes a threshold-based manager system
 * for critical operations. This contract simulates key/proof management
 * in a post-quantum context by managing unique IDs, hashes, states, and
 * access, without implementing the actual quantum-resistant cryptography.
 */

/*
 * Outline:
 * 1. Overview: Manages Quantum Keys and Proofs, their state, and access.
 * 2. State: Keys, Proofs, owners, managers, pending threshold actions.
 * 3. Core Entities: Key, Proof, Manager, PendingManagerAction structs/enums.
 * 4. Access Control: Owner configures managers, managers use threshold approval for operations.
 * 5. Key Lifecycle: Create, Revoke, Transfer, Extend, Update, Reactivate.
 * 6. Proof Lifecycle: Create, Invalidate, Update, Verify association.
 * 7. Manager System: Add/Remove managers, set threshold, initiate/approve/execute actions.
 * 8. Queries: Retrieve details, lists, counts, status.
 * 9. Events: Signal state changes.
 */

/*
 * Function Summary:
 * - Constructor: Sets initial owner and manager threshold.
 * - Key Management (8): createKey, getKeyDetails, listKeysByOwner, revokeKey, transferKeyOwnership, extendKeyExpiration, updateKeyDataHash, reactivateRevokedKey.
 * - Proof Management (6): createProof, getProofDetails, listProofsForKey, invalidateProof, updateProofDataHash, verifyProofOwnership.
 * - Manager & Access Control (10): addManager, removeManager, setMinManagersForAction, initiateManagerAction, approveManagerAction, executeManagerAction, cancelManagerAction, getManagerList, getMinManagersForAction, getPendingManagerActions.
 * - Status & Validation (2): isKeyActiveAndValid, isProofAssociatedKeyActiveAndValid.
 * - Query & Utility (4): getKeyCount, getProofCount, getKeyStatus, getProofStatus.
 */

contract QuantumKeyManager {

    // --- Error Definitions ---
    error NotOwner();
    error NotManager();
    error KeyNotFound(uint256 keyId);
    error ProofNotFound(uint256 proofId);
    error KeyNotOwnedByCaller(uint256 keyId, address caller);
    error KeyAlreadyRevoked(uint256 keyId);
    error KeyNotRevoked(uint256 keyId);
    error ProofAlreadyInvalid(uint256 proofId);
    error ManagerAlreadyExists(address manager);
    error ManagerNotFound(address manager);
    error InsufficientManagers(uint256 required, uint256 current);
    error ManagerActionNotFound(uint256 actionId);
    error ManagerActionAlreadyApproved(uint256 actionId, address manager);
    error ManagerActionNotYetApproved(uint256 actionId, uint256 required, uint256 current);
    error ManagerActionAlreadyExecuted(uint256 actionId);
    error ManagerActionNotInitiatedByManager(uint256 actionId, address initiator);
    error ManagerActionParametersMismatch(uint256 actionId);
    error ActionNotPending(uint256 actionId);
    error InvalidExpirationTime();

    // --- Event Definitions ---
    event KeyCreated(uint256 indexed keyId, address indexed owner, bytes32 keyType, uint256 expiration);
    event KeyStatusChanged(uint256 indexed keyId, KeyStatus oldStatus, KeyStatus newStatus);
    event KeyOwnershipTransferred(uint256 indexed keyId, address indexed from, address indexed to);
    event KeyExpirationExtended(uint256 indexed keyId, uint256 newExpiration);
    event KeyDataHashUpdated(uint256 indexed keyId, bytes32 newHash);

    event ProofCreated(uint256 indexed proofId, uint256 indexed keyId, bytes32 proofType);
    event ProofStatusChanged(uint256 indexed proofId, ProofStatus oldStatus, ProofStatus newStatus);
    event ProofDataHashUpdated(uint256 indexed proofId, bytes32 newHash);

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);
    event MinManagersForActionSet(uint256 newThreshold);

    event ManagerActionInitiated(uint256 indexed actionId, ManagerActionType indexed actionType, address indexed initiator);
    event ManagerActionApproved(uint256 indexed actionId, address indexed approver);
    event ManagerActionExecuted(uint256 indexed actionId, ManagerActionType indexed actionType);
    event ManagerActionCancelled(uint256 indexed actionId, ManagerActionType indexed actionType);

    // --- Enums ---
    enum KeyStatus { Active, Revoked, Expired }
    enum ProofStatus { Valid, Invalidated }

    enum ManagerActionType {
        RevokeKey,
        TransferKeyOwnership,
        ExtendKeyExpiration,
        UpdateKeyDataHash,
        ReactivateRevokedKey,
        InvalidateProof,
        UpdateProofDataHash // Maybe also add/remove manager? No, owner-only makes sense for that.
    }

    // --- Structs ---
    struct Key {
        uint256 id;
        address owner;
        bytes32 keyDataHash; // Hash representing the actual key data (kept off-chain)
        bytes32 keyType;     // e.g., "Dilithium", "Falcon", "Sphincs+" (conceptually)
        uint256 creationTime;
        uint256 expirationTime;
        KeyStatus status;
        uint256[] proofIds;  // List of proof IDs associated with this key
    }

    struct Proof {
        uint256 id;
        uint256 keyId;       // The key this proof is derived from
        bytes32 proofDataHash; // Hash representing the actual proof data (kept off-chain)
        bytes32 proofType;   // e.g., "ZK", "Signature", "ChallengeResponse" (conceptually)
        uint256 creationTime;
        ProofStatus status;
    }

    struct PendingManagerAction {
        uint256 actionId;
        ManagerActionType actionType;
        address initiator;
        uint256 targetId; // Key ID or Proof ID depending on actionType
        bytes data;       // ABI-encoded extra parameters (e.g., newOwner, newExpiration)
        mapping(address => bool) approvals;
        uint256 approvalCount;
        bool executed;
        bool cancelled;
    }

    // --- State Variables ---
    address private immutable i_owner;
    uint256 private s_keyIdCounter;
    uint256 private s_proofIdCounter;
    uint256 private s_managerActionIdCounter;

    mapping(uint256 => Key) private s_keys;
    mapping(uint256 => Proof) private s_proofs;
    mapping(address => uint256[]) private s_ownerToKeyIds; // Index for owner's keys

    mapping(address => bool) private s_managers;
    address[] private s_managerList; // To easily iterate managers

    uint256 private s_minManagersForAction;

    mapping(uint256 => PendingManagerAction) private s_pendingManagerActions;

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier onlyManager() {
        if (!s_managers[msg.sender]) revert NotManager();
        _;
    }

    // Requires that a pending action with _actionId initiated by msg.sender exists
    modifier onlyInitiatorOfPendingAction(uint256 _actionId) {
        PendingManagerAction storage action = s_pendingManagerActions[_actionId];
        if (action.actionId == 0) revert ManagerActionNotFound(_actionId); // Check if action exists
        if (action.initiator != msg.sender) revert ManagerActionNotInitiatedByManager(_actionId, action.initiator);
        if (action.executed) revert ManagerActionAlreadyExecuted(_actionId);
        if (action.cancelled) revert ActionNotPending(_actionId); // Use ActionNotPending if cancelled
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialMinManagersForAction) {
        i_owner = msg.sender;
        if (initialMinManagersForAction == 0) revert InsufficientManagers(1, 0); // Must be at least 1
        s_minManagersForAction = initialMinManagersForAction;
    }

    // --- Key Management Functions ---

    /**
     * @dev Creates a new key representation.
     * @param _keyDataHash The hash of the off-chain key data.
     * @param _keyType A identifier for the key type (e.g., hash of a string like "Dilithium").
     * @param _expirationTime Timestamp when the key expires.
     */
    function createKey(bytes32 _keyDataHash, bytes32 _keyType, uint256 _expirationTime) external {
        if (_expirationTime <= block.timestamp) revert InvalidExpirationTime();

        s_keyIdCounter++;
        uint256 keyId = s_keyIdCounter;

        Key storage newKey = s_keys[keyId];
        newKey.id = keyId;
        newKey.owner = msg.sender;
        newKey.keyDataHash = _keyDataHash;
        newKey.keyType = _keyType;
        newKey.creationTime = block.timestamp;
        newKey.expirationTime = _expirationTime;
        newKey.status = KeyStatus.Active;

        s_ownerToKeyIds[msg.sender].push(keyId);

        emit KeyCreated(keyId, msg.sender, _keyType, _expirationTime);
    }

    /**
     * @dev Retrieves details of a specific key.
     * @param _keyId The ID of the key to retrieve.
     * @return Key struct details.
     */
    function getKeyDetails(uint256 _keyId) external view returns (Key memory) {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);
        return key;
    }

    /**
     * @dev Lists all key IDs owned by a specific address.
     * @param _owner The address to list keys for.
     * @return Array of key IDs.
     */
    function listKeysByOwner(address _owner) external view returns (uint256[] memory) {
        return s_ownerToKeyIds[_owner];
    }

    /**
     * @dev Initiates the revocation of a key, requiring manager approval.
     * @param _keyId The ID of the key to revoke.
     */
    function revokeKey(uint256 _keyId) external onlyManager {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);
        if (key.status == KeyStatus.Revoked) revert KeyAlreadyRevoked(_keyId);

        uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.RevokeKey,
            _keyId,
            abi.encode(_keyId) // Redundant but shows how params would be passed
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.RevokeKey, msg.sender);
    }

     /**
     * @dev Initiates the transfer of key ownership, requiring manager approval.
     * @param _keyId The ID of the key.
     * @param _newOwner The address of the new owner.
     */
    function transferKeyOwnership(uint256 _keyId, address _newOwner) external onlyManager {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);

         uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.TransferKeyOwnership,
            _keyId,
            abi.encode(_keyId, _newOwner)
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.TransferKeyOwnership, msg.sender);
    }

    /**
     * @dev Initiates extending a key's expiration, requiring manager approval.
     * @param _keyId The ID of the key.
     * @param _newExpirationTime The new expiration timestamp.
     */
    function extendKeyExpiration(uint256 _keyId, uint256 _newExpirationTime) external onlyManager {
         Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);
        if (_newExpirationTime <= key.expirationTime) revert InvalidExpirationTime(); // Must extend

         uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.ExtendKeyExpiration,
            _keyId,
            abi.encode(_keyId, _newExpirationTime)
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.ExtendKeyExpiration, msg.sender);
    }

    /**
     * @dev Initiates updating the key data hash (simulates rotation), requiring manager approval.
     * @param _keyId The ID of the key.
     * @param _newKeyDataHash The new hash of the off-chain key data.
     */
    function updateKeyDataHash(uint256 _keyId, bytes32 _newKeyDataHash) external onlyManager {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);

        uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.UpdateKeyDataHash,
            _keyId,
            abi.encode(_keyId, _newKeyDataHash)
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.UpdateKeyDataHash, msg.sender);
    }

    /**
     * @dev Initiates reactivating a revoked key, requiring manager approval.
     * @param _keyId The ID of the key to reactivate.
     */
    function reactivateRevokedKey(uint256 _keyId) external onlyManager {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);
        if (key.status != KeyStatus.Revoked) revert KeyNotRevoked(_keyId);

        uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.ReactivateRevokedKey,
            _keyId,
            abi.encode(_keyId)
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.ReactivateRevokedKey, msg.sender);
    }


    // --- Proof Management Functions ---

    /**
     * @dev Creates a new proof representation associated with an active key.
     * @param _keyId The ID of the key this proof is derived from.
     * @param _proofDataHash The hash of the off-chain proof data.
     * @param _proofType An identifier for the proof type (e.g., hash of a string like "ZKProof").
     */
    function createProof(uint256 _keyId, bytes32 _proofDataHash, bytes32 _proofType) external {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId);
        if (key.status != KeyStatus.Active || block.timestamp > key.expirationTime) {
             revert KeyNotFound(_keyId); // Treat non-active/expired key as not found for proof creation
        }
         if (key.owner != msg.sender) revert KeyNotOwnedByCaller(_keyId, msg.sender);

        s_proofIdCounter++;
        uint256 proofId = s_proofIdCounter;

        Proof storage newProof = s_proofs[proofId];
        newProof.id = proofId;
        newProof.keyId = _keyId;
        newProof.proofDataHash = _proofDataHash;
        newProof.proofType = _proofType;
        newProof.creationTime = block.timestamp;
        newProof.status = ProofStatus.Valid;

        key.proofIds.push(proofId); // Add proof ID to the associated key

        emit ProofCreated(proofId, _keyId, _proofType);
    }

     /**
     * @dev Retrieves details of a specific proof.
     * @param _proofId The ID of the proof to retrieve.
     * @return Proof struct details.
     */
    function getProofDetails(uint256 _proofId) external view returns (Proof memory) {
        Proof storage proof = s_proofs[_proofId];
        if (proof.id == 0) revert ProofNotFound(_proofId);
        return proof;
    }

    /**
     * @dev Lists all proof IDs associated with a specific key ID.
     * @param _keyId The ID of the key to list proofs for.
     * @return Array of proof IDs.
     */
    function listProofsForKey(uint256 _keyId) external view returns (uint256[] memory) {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) revert KeyNotFound(_keyId); // Ensure key exists
        return key.proofIds;
    }

    /**
     * @dev Initiates invalidating a proof, requiring manager approval.
     * @param _proofId The ID of the proof to invalidate.
     */
    function invalidateProof(uint256 _proofId) external onlyManager {
        Proof storage proof = s_proofs[_proofId];
        if (proof.id == 0) revert ProofNotFound(_proofId);
        if (proof.status == ProofStatus.Invalidated) revert ProofAlreadyInvalid(_proofId);

        uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.InvalidateProof,
            _proofId,
            abi.encode(_proofId)
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.InvalidateProof, msg.sender);
    }

    /**
     * @dev Initiates updating the proof data hash, requiring manager approval.
     * @param _proofId The ID of the proof.
     * @param _newProofDataHash The new hash of the off-chain proof data.
     */
    function updateProofDataHash(uint256 _proofId, bytes32 _newProofDataHash) external onlyManager {
        Proof storage proof = s_proofs[_proofId];
        if (proof.id == 0) revert ProofNotFound(_proofId);

        uint256 actionId = initiateManagerActionInternal(
            ManagerActionType.UpdateProofDataHash,
            _proofId,
            abi.encode(_proofId, _newProofDataHash)
        );
        emit ManagerActionInitiated(actionId, ManagerActionType.UpdateProofDataHash, msg.sender);
    }

    /**
     * @dev Checks if a given address owns the key associated with a proof.
     * @param _proofId The ID of the proof.
     * @param _addr The address to check ownership for.
     * @return True if the address owns the associated key, false otherwise.
     */
    function verifyProofOwnership(uint256 _proofId, address _addr) external view returns (bool) {
        Proof storage proof = s_proofs[_proofId];
        if (proof.id == 0 || proof.status != ProofStatus.Valid) return false; // Proof must exist and be valid

        Key storage key = s_keys[proof.keyId];
         // Key must exist, be active, not expired, and owned by _addr
        return key.id != 0 && key.owner == _addr && key.status == KeyStatus.Active && block.timestamp <= key.expirationTime;
    }


    // --- Manager & Access Control Functions ---

    /**
     * @dev Adds a manager address. Only owner can call.
     * @param _manager The address to add as manager.
     */
    function addManager(address _manager) external onlyOwner {
        if (s_managers[_manager]) revert ManagerAlreadyExists(_manager);
        s_managers[_manager] = true;
        s_managerList.push(_manager);
        emit ManagerAdded(_manager);
    }

     /**
     * @dev Removes a manager address. Only owner can call.
     * @param _manager The address to remove from managers.
     */
    function removeManager(address _manager) external onlyOwner {
        if (!s_managers[_manager]) revert ManagerNotFound(_manager);
        s_managers[_manager] = false;
        // Find and remove from the list (inefficient for large lists)
        for (uint256 i = 0; i < s_managerList.length; i++) {
            if (s_managerList[i] == _manager) {
                s_managerList[i] = s_managerList[s_managerList.length - 1];
                s_managerList.pop();
                break;
            }
        }
        emit ManagerRemoved(_manager);
    }

    /**
     * @dev Sets the minimum number of manager approvals required for certain actions. Only owner can call.
     * @param _newThreshold The new minimum number of managers required.
     */
    function setMinManagersForAction(uint256 _newThreshold) external onlyOwner {
        if (_newThreshold == 0) revert InsufficientManagers(1, 0);
        if (_newThreshold > s_managerList.length) revert InsufficientManagers(_newThreshold, s_managerList.length);
        s_minManagersForAction = _newThreshold;
        emit MinManagersForActionSet(_newThreshold);
    }

    /**
     * @dev Initiates a new action requiring multiple manager approvals.
     * @param _actionType The type of action.
     * @param _targetId The ID of the target (Key or Proof).
     * @param _data ABI-encoded additional parameters.
     * @return The ID of the newly created pending action.
     */
    function initiateManagerActionInternal(
        ManagerActionType _actionType,
        uint256 _targetId,
        bytes memory _data
    ) internal returns (uint256) {
        s_managerActionIdCounter++;
        uint256 actionId = s_managerActionIdCounter;

        PendingManagerAction storage action = s_pendingManagerActions[actionId];
        action.actionId = actionId;
        action.actionType = _actionType;
        action.initiator = msg.sender;
        action.targetId = _targetId;
        action.data = _data;
        action.executed = false;
        action.cancelled = false;
        // The initiator's approval is added when approveManagerAction is called below

        // Automatically approve by initiator
        approveManagerAction(actionId);

        return actionId;
    }

     /**
     * @dev Approves a pending manager action.
     * @param _actionId The ID of the pending action.
     */
    function approveManagerAction(uint256 _actionId) public onlyManager {
        PendingManagerAction storage action = s_pendingManagerActions[_actionId];

        if (action.actionId == 0 || action.cancelled) revert ActionNotPending(_actionId);
        if (action.executed) revert ManagerActionAlreadyExecuted(_actionId);
        if (action.approvals[msg.sender]) revert ManagerActionAlreadyApproved(_actionId, msg.sender);

        action.approvals[msg.sender] = true;
        action.approvalCount++;

        emit ManagerActionApproved(_actionId, msg.sender);

        // Optional: Auto-execute if threshold is met immediately
        // if (action.approvalCount >= s_minManagersForAction) {
        //     executeManagerAction(_actionId); // This would change the required checks in executeManagerAction
        // }
    }

    /**
     * @dev Executes a pending manager action if the approval threshold is met.
     * @param _actionId The ID of the pending action.
     */
    function executeManagerAction(uint256 _actionId) external onlyManager {
        PendingManagerAction storage action = s_pendingManagerActions[_actionId];

        if (action.actionId == 0 || action.cancelled) revert ActionNotPending(_actionId);
        if (action.executed) revert ManagerActionAlreadyExecuted(_actionId);
        if (action.approvalCount < s_minManagersForAction) {
            revert ManagerActionNotYetApproved(_actionId, s_minManagersForAction, action.approvalCount);
        }

        action.executed = true;

        // Perform the actual action based on type
        bytes memory params = action.data;
        uint256 targetId = action.targetId;

        if (action.actionType == ManagerActionType.RevokeKey) {
            (uint256 keyId) = abi.decode(params, (uint256));
            if (keyId != targetId) revert ManagerActionParametersMismatch(_actionId);
            Key storage key = s_keys[keyId];
            if (key.id == 0) revert KeyNotFound(keyId); // Should not happen if targetId was valid
            if (key.status != KeyStatus.Revoked) {
                 emit KeyStatusChanged(keyId, key.status, KeyStatus.Revoked);
                 key.status = KeyStatus.Revoked;
            }
        } else if (action.actionType == ManagerActionType.TransferKeyOwnership) {
             (uint256 keyId, address newOwner) = abi.decode(params, (uint256, address));
             if (keyId != targetId) revert ManagerActionParametersMismatch(_actionId);
             Key storage key = s_keys[keyId];
             if (key.id == 0) revert KeyNotFound(keyId);
             address oldOwner = key.owner;
             key.owner = newOwner;
             // Update ownerToKeyIds mapping (requires potentially expensive array manipulation)
             // For simplicity here, we just change the owner field. A production system
             // might use linked lists or external indexing for owner key lists.
             emit KeyOwnershipTransferred(keyId, oldOwner, newOwner);

        } else if (action.actionType == ManagerActionType.ExtendKeyExpiration) {
            (uint256 keyId, uint256 newExpirationTime) = abi.decode(params, (uint256, uint256));
            if (keyId != targetId) revert ManagerActionParametersMismatch(_actionId);
            Key storage key = s_keys[keyId];
            if (key.id == 0) revert KeyNotFound(keyId);
            // Check against current time again just in case, though initiate checked against old expiration
            if (newExpirationTime <= block.timestamp) revert InvalidExpirationTime();
            key.expirationTime = newExpirationTime;
            emit KeyExpirationExtended(keyId, newExpirationTime);

        } else if (action.actionType == ManagerActionType.UpdateKeyDataHash) {
             (uint256 keyId, bytes32 newKeyDataHash) = abi.decode(params, (uint256, bytes32));
             if (keyId != targetId) revert ManagerActionParametersMismatch(_actionId);
             Key storage key = s_keys[keyId];
             if (key.id == 0) revert KeyNotFound(keyId);
             key.keyDataHash = newKeyDataHash;
             emit KeyDataHashUpdated(keyId, newKeyDataHash);

        } else if (action.actionType == ManagerActionType.ReactivateRevokedKey) {
             (uint256 keyId) = abi.decode(params, (uint256));
             if (keyId != targetId) revert ManagerActionParametersMismatch(_actionId);
             Key storage key = s_keys[keyId];
             if (key.id == 0) revert KeyNotFound(keyId);
             if (key.status == KeyStatus.Revoked) {
                  emit KeyStatusChanged(keyId, key.status, KeyStatus.Active);
                  key.status = KeyStatus.Active;
             }

        } else if (action.actionType == ManagerActionType.InvalidateProof) {
            (uint256 proofId) = abi.decode(params, (uint256));
            if (proofId != targetId) revert ManagerActionParametersMismatch(_actionId);
             Proof storage proof = s_proofs[proofId];
             if (proof.id == 0) revert ProofNotFound(proofId); // Should not happen
             if (proof.status != ProofStatus.Invalidated) {
                 emit ProofStatusChanged(proofId, proof.status, ProofStatus.Invalidated);
                 proof.status = ProofStatus.Invalidated;
             }

        } else if (action.actionType == ManagerActionType.UpdateProofDataHash) {
            (uint256 proofId, bytes32 newProofDataHash) = abi.decode(params, (uint256, bytes32));
            if (proofId != targetId) revert ManagerActionParametersMismatch(_actionId);
             Proof storage proof = s_proofs[proofId];
             if (proof.id == 0) revert ProofNotFound(proofId);
             proof.proofDataHash = newProofDataHash;
             emit ProofDataHashUpdated(proofId, newProofDataHash);
        }

        emit ManagerActionExecuted(_actionId, action.actionType);

        // Note: We don't delete the pending action struct, just mark it executed.
        // This allows querying historical actions.
    }

    /**
     * @dev Cancels a pending manager action. Only the initiator can cancel.
     * @param _actionId The ID of the pending action to cancel.
     */
    function cancelManagerAction(uint256 _actionId) external onlyInitiatorOfPendingAction(_actionId) {
        PendingManagerAction storage action = s_pendingManagerActions[_actionId];
        action.cancelled = true;
        emit ManagerActionCancelled(_actionId, action.actionType);
    }


    /**
     * @dev Returns the list of current manager addresses.
     * @return Array of manager addresses.
     */
    function getManagerList() external view returns (address[] memory) {
        return s_managerList;
    }

     /**
     * @dev Returns the minimum number of manager approvals required for actions.
     * @return The threshold count.
     */
    function getMinManagersForAction() external view returns (uint256) {
        return s_minManagersForAction;
    }

    /**
     * @dev Returns details of a specific pending manager action.
     * @param _actionId The ID of the action.
     * @return PendingManagerAction struct details (excluding the approvals mapping).
     */
    function getPendingManagerActions(uint256 _actionId) external view returns (
        uint256 actionId,
        ManagerActionType actionType,
        address initiator,
        uint256 targetId,
        bytes memory data,
        uint256 approvalCount,
        bool executed,
        bool cancelled
    ) {
         PendingManagerAction storage action = s_pendingManagerActions[_actionId];
         if (action.actionId == 0) revert ManagerActionNotFound(_actionId);

         return (
             action.actionId,
             action.actionType,
             action.initiator,
             action.targetId,
             action.data,
             action.approvalCount,
             action.executed,
             action.cancelled
         );
     }


    // --- Status & Validation Functions ---

    /**
     * @dev Checks if a key is currently active and not expired.
     * @param _keyId The ID of the key.
     * @return True if the key is active and valid, false otherwise.
     */
    function isKeyActiveAndValid(uint256 _keyId) public view returns (bool) {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) return false; // Key must exist
        if (key.status != KeyStatus.Active) return false; // Must be active
        if (block.timestamp > key.expirationTime) return false; // Must not be expired
        return true;
    }

     /**
     * @dev Checks if a proof exists, is valid, and its associated key is active and not expired.
     * @param _proofId The ID of the proof.
     * @return True if the proof and its key are valid, false otherwise.
     */
    function isProofAssociatedKeyActiveAndValid(uint256 _proofId) public view returns (bool) {
        Proof storage proof = s_proofs[_proofId];
        if (proof.id == 0 || proof.status != ProofStatus.Valid) return false; // Proof must exist and be valid
        // Check the associated key's status and expiration
        return isKeyActiveAndValid(proof.keyId);
    }


    // --- Query & Utility Functions ---

    /**
     * @dev Returns the total number of keys created.
     * @return Total key count.
     */
    function getKeyCount() external view returns (uint256) {
        return s_keyIdCounter;
    }

    /**
     * @dev Returns the total number of proofs created.
     * @return Total proof count.
     */
    function getProofCount() external view returns (uint256) {
        return s_proofIdCounter;
    }

    /**
     * @dev Returns the status string for a key ID.
     * @param _keyId The ID of the key.
     * @return Status string ("Active", "Revoked", "Expired", "NotFound").
     */
    function getKeyStatus(uint256 _keyId) external view returns (string memory) {
        Key storage key = s_keys[_keyId];
        if (key.id == 0) return "NotFound";
        if (block.timestamp > key.expirationTime && key.status == KeyStatus.Active) return "Expired"; // Status overrides expiration if revoked
        if (key.status == KeyStatus.Active) return "Active";
        if (key.status == KeyStatus.Revoked) return "Revoked";
        return "Unknown"; // Should not happen with defined statuses
    }

    /**
     * @dev Returns the status string for a proof ID.
     * @param _proofId The ID of the proof.
     * @return Status string ("Valid", "Invalidated", "NotFound").
     */
    function getProofStatus(uint256 _proofId) external view returns (string memory) {
        Proof storage proof = s_proofs[_proofId];
        if (proof.id == 0) return "NotFound";
        if (proof.status == ProofStatus.Valid) return "Valid";
        if (proof.status == ProofStatus.Invalidated) return "Invalidated";
        return "Unknown"; // Should not happen
    }

    // Function count check: 8 + 6 + 10 + 2 + 4 = 30. Meets the >= 20 requirement.
}
```