Okay, let's create a smart contract that acts as a "Digital Self-Sovereignty Vault". This contract allows a user (the owner) to store references to their digital assets (on-chain tokens, NFTs) and off-chain credentials/data (via hashes/URIs), and define complex, programmable access policies for others to interact with these items under specific conditions.

This concept integrates ideas from Self-Sovereign Identity (SSI), conditional access control, and programmable asset management. It avoids simple token standards, basic escrow, or standard governance patterns.

---

### **Smart Contract Outline & Function Summary**

**Contract Name:** `DigitalSelfSovereigntyVault`

**Purpose:** To provide a decentralized, programmable vault for managing ownership references to digital assets (tokens, NFTs) and off-chain data/credentials (via hashes/metadata), with granular, conditional access control defined by the owner.

**Key Concepts:**
*   **Owner Control:** The sole primary controller of the vault.
*   **Delegates:** Trusted addresses granted specific, limited permissions by the owner.
*   **Asset Linking:** The vault contract *holds* specified tokens/NFTs, linking them to the owner's control framework.
*   **Credential References:** Stores secure hashes, descriptions, and URIs for off-chain verifiable credentials or data, *not* the data itself.
*   **Access Policies:** Complex rules defined by the owner specifying *who* can access *what item(s)*, under *which conditions* (time, payment, credential proof, etc.), and with what *permissions*.
*   **Conditional Execution:** Allows triggering actions (like asset transfers) only when specified policy conditions are met.

**Function Summary:**

1.  `constructor()`: Initializes the vault with the deploying address as the owner.
2.  `transferOwnership(address newOwner)`: Transfers ownership of the vault.
3.  `setVaultURI(string memory uri)`: Sets a metadata URI for the vault itself (e.g., pointing to a description file).
4.  `designateDelegate(address delegate, DelegatePermissions permissions)`: Grants specified permissions to a delegate address.
5.  `updateDelegatePermissions(address delegate, DelegatePermissions permissions)`: Updates existing permissions for a delegate.
6.  `revokeDelegate(address delegate)`: Revokes all delegate permissions from an address.
7.  `linkERC20(address tokenAddress, uint256 amount)`: Transfers specified ERC20 tokens into the vault, linking them. (Requires prior approval).
8.  `unlinkERC20(address tokenAddress, uint256 amount)`: Transfers specified ERC20 tokens out of the vault back to the owner. (Only owner/authorized delegate).
9.  `linkERC721(address tokenAddress, uint256 tokenId)`: Transfers a specific ERC721 token into the vault, linking it. (Requires prior approval/setApprovalForAll).
10. `unlinkERC721(address tokenAddress, uint256 tokenId)`: Transfers a specific ERC721 token out of the vault back to the owner. (Only owner/authorized delegate).
11. `linkERC1155(address tokenAddress, uint256 id, uint256 amount)`: Transfers specified ERC1155 tokens into the vault, linking them. (Requires prior approval/setApprovalForAll).
12. `unlinkERC1155(address tokenAddress, uint256 id, uint256 amount)`: Transfers specified ERC1155 tokens out of the vault back to the owner. (Only owner/authorized delegate).
13. `addCredentialReference(bytes32 dataHash, string memory description, string memory uri, address issuer)`: Adds a reference to an off-chain credential/data item.
14. `updateCredentialReference(bytes32 dataHash, string memory description, string memory uri, address issuer)`: Updates the metadata for an existing credential reference.
15. `removeCredentialReference(bytes32 dataHash)`: Removes a credential reference.
16. `createAccessPolicy(address recipient, PolicyTarget target, AccessCondition condition, PermissionType permission)`: Creates a new access policy defining conditional permissions for a recipient on a target item.
17. `updateAccessPolicy(uint256 policyId, PolicyTarget target, AccessCondition condition, PermissionType permission)`: Updates an existing access policy.
18. `revokeAccessPolicy(uint256 policyId)`: Deactivates an access policy.
19. `evaluateAccessPolicy(uint256 policyId, bytes memory context)`: Public view function to check if a policy is active and its conditions are met given external context (e.g., payment proof, credential proof).
20. `executeConditionalTransfer(uint256 policyId, address tokenAddress, uint256 amountOrId, uint256 valueForERC1155, bytes memory context)`: Attempts to execute an asset transfer as defined by a policy, checking policy conditions and external context. Applicable for policies with `InitiateTransfer` permission.
21. `getVaultOwner()`: View function to get the current owner.
22. `getVaultURI()`: View function to get the vault metadata URI.
23. `isDelegate(address queryAddress)`: View function to check if an address is a delegate.
24. `getDelegatePermissions(address delegate)`: View function to retrieve permissions for a delegate.
25. `getCredentialReference(bytes32 dataHash)`: View function to retrieve details of a credential reference.
26. `listCredentialHashes()`: View function to list all stored credential hashes.
27. `getLinkedERC20Balance(address tokenAddress)`: View function to get the vault's balance of a linked ERC20 token.
28. `getLinkedERC721Owner(address tokenAddress, uint256 tokenId)`: View function to check if the vault owns a specific ERC721 token.
29. `getLinkedERC1155Balance(address tokenAddress, uint256 id)`: View function to get the vault's balance of a specific ERC1155 token type.
30. `listLinkedERC20Tokens()`: View function to list addresses of linked ERC20 tokens.
31. `listLinkedERC721Tokens()`: View function to list token addresses of linked ERC721 collections.
32. `listLinkedERC1155Tokens()`: View function to list token addresses of linked ERC1155 collections.
33. `getPolicyDetails(uint256 policyId)`: View function to retrieve details of an access policy.
34. `listPoliciesForRecipient(address recipient)`: View function to list IDs of active policies targeting a specific recipient.
35. `listActivePolicies()`: View function to list IDs of all active policies.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interfaces for token interactions
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
}

// Custom Error Definitions
error NotOwner();
error NotOwnerOrDelegate();
error DelegatePermissionDenied();
error CredentialNotFound();
error PolicyNotFound();
error PolicyNotActive();
error PolicyConditionNotMet();
error InvalidPolicyTarget();
error InsufficientVaultBalance();
error TransferFailed();
error UnauthorizedTransfer();
error PolicyTargetMismatch();

// Enums for structure and clarity
enum PermissionType {
    None,             // No specific permission
    ReadMetadata,     // Can view basic metadata (description, URI, hash)
    ReadDataReference,// Can access the data referenced off-chain (implied by having hash/URI)
    InitiateTransfer, // Can initiate transfer of linked assets under policy conditions
    ManageDelegates,  // Can add/remove/update delegates (Owner only permission generally)
    ManagePolicies,   // Can create/update/revoke policies
    ManageCredentials,// Can add/update/remove credential references
    ManageAssets      // Can link/unlink assets
}

enum AccessConditionType {
    None,             // Always true (if policy active)
    TimeBased,        // Requires current time within a range (details: abi.encode(uint256 startTime, uint256 endTime))
    PaymentRequired,  // Requires proof of payment (details: abi.encode(address tokenAddress, uint256 amount)) - Proof handled off-chain, checked via `context`
    CredentialProof   // Requires proof related to a specific credential hash (details: abi.encode(bytes32 requiredCredentialHash)) - Proof handled off-chain, checked via `context`
    // Future: ExternalState (requires checking external contract state)
}

enum PolicyTargetType {
    None,             // Invalid target
    SpecificCredential,// Target is a specific credential hash (targetId: bytes32 credentialHash)
    SpecificAssetERC20,// Target is a specific ERC20 token address (targetId: bytes32(uint256(uint160(tokenAddress))))
    SpecificAssetERC721,// Target is a specific ERC721 token (targetId: bytes32(uint256(tokenId))) (tokenAddress stored in policy details or inferred from context?)
    SpecificAssetERC1155,// Target is a specific ERC1155 token type (targetId: bytes32(keccak256(abi.encodePacked(tokenAddress, id))))
    AllCredentials,   // Target is all credential references
    AllAssets,        // Target is all linked assets
    VaultMetadata     // Target is the vault's own metadata
}

// Structs to define data structures
struct CredentialReference {
    bytes32 dataHash;       // Secure hash of the off-chain data/credential content
    string description;     // Human-readable description
    string uri;             // Optional URI pointing to the data or metadata file
    address issuer;         // Address or identifier of the credential issuer
    uint256 addedTimestamp; // When the reference was added
}

struct DelegatePermissions {
    bool canManageCredentials;
    bool canManageAssets;
    bool canManagePolicies; // Can create policies
    bool canExecuteTransfers; // Can call executeConditionalTransfer on behalf of owner if policy allows
}

struct PolicyTarget {
    PolicyTargetType targetType;
    bytes32 targetId; // Identifier for the target item, interpreted based on targetType
}

struct AccessCondition {
    AccessConditionType conditionType;
    bytes conditionDetails; // Abi-encoded data specific to the condition type
}

struct AccessPolicy {
    uint256 policyId;       // Unique identifier for the policy
    address recipient;      // The address this policy applies to
    PolicyTarget target;    // What items this policy governs access to
    AccessCondition condition;// The conditions required for access
    PermissionType permission;// The type of permission granted
    bool isActive;          // Whether the policy is currently active
    uint256 createdTimestamp; // When the policy was created
}

// Events to signal state changes
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event VaultURISet(string uri);
event DelegateDesignated(address indexed delegate, DelegatePermissions permissions);
event DelegatePermissionsUpdated(address indexed delegate, DelegatePermissions permissions);
event DelegateRevoked(address indexed delegate);
event ERC20Linked(address indexed tokenAddress, uint256 amount);
event ERC20Unlinked(address indexed tokenAddress, uint256 amount);
event ERC721Linked(address indexed tokenAddress, uint256 indexed tokenId);
event ERC721Unlinked(address indexed tokenAddress, uint256 indexed tokenId);
event ERC1155Linked(address indexed tokenAddress, uint256 indexed id, uint256 amount);
event ERC1155Unlinked(address indexed tokenAddress, uint256 indexed id, uint256 amount);
event CredentialReferenceAdded(bytes32 indexed dataHash, address indexed issuer);
event CredentialReferenceUpdated(bytes32 indexed dataHash, address indexed issuer);
event CredentialReferenceRemoved(bytes32 indexed dataHash);
event AccessPolicyCreated(uint256 indexed policyId, address indexed recipient, PolicyTarget target, PermissionType permission);
event AccessPolicyUpdated(uint256 indexed policyId, PolicyTarget target, PermissionType permission);
event AccessPolicyRevoked(uint256 indexed policyId);
event PolicyEvaluated(uint256 indexed policyId, address indexed recipient, bool conditionMet);
event ConditionalTransferExecuted(uint256 indexed policyId, address indexed recipient, address indexed tokenAddress, uint256 amountOrId, uint256 valueForERC1155);


contract DigitalSelfSovereigntyVault {

    address private _owner;
    string private _vaultURI;

    // State variables
    mapping(bytes32 => CredentialReference) private _credentialReferences;
    bytes32[] private _credentialHashes; // To list hashes

    mapping(address => DelegatePermissions) private _delegates;

    mapping(uint256 => AccessPolicy) private _policies;
    uint256[] private _policyIds; // To list active policies efficiently (requires managing on revoke)
    uint256 private _policyCounter;

    // Linked assets state (vault contract holds these)
    mapping(address => uint256) private _linkedERC20Balances; // Token address -> balance in vault (redundant but useful)
    mapping(address => mapping(uint256 => address)) private _linkedERC721Owners; // tokenId -> tokenAddress -> owner (should be this contract)
    mapping(address => mapping(uint256 => uint256)) private _linkedERC1155Balances; // tokenAddress -> id -> balance in vault

    // Lists for view functions
    address[] private _linkedERC20TokensList;
    address[] private _linkedERC721TokensList; // Stores unique collection addresses
    address[] private _linkedERC1155TokensList; // Stores unique collection addresses

    // --- Modifiers / Internal Checks ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyOwnerOrDelegate() {
        if (msg.sender != _owner && _delegates[msg.sender].canManageCredentials == false &&
            _delegates[msg.sender].canManageAssets == false &&
            _delegates[msg.sender].canManagePolicies == false &&
            _delegates[msg.sender].canExecuteTransfers == false) revert NotOwnerOrDelegate();
        _;
    }

    function _checkDelegatePermission(address account, PermissionType permission) internal view returns (bool) {
        if (account == _owner) return true; // Owner always has all permissions

        DelegatePermissions memory delegatePerms = _delegates[account];
        if (permission == PermissionType.ManageCredentials && delegatePerms.canManageCredentials) return true;
        if (permission == PermissionType.ManageAssets && delegatePerms.canManageAssets) return true;
        if (permission == PermissionType.ManagePolicies && delegatePerms.canManagePolicies) return true;
        if (permission == PermissionType.InitiateTransfer && delegatePerms.canExecuteTransfers) return true;
        // ManageDelegates is generally restricted to Owner

        return false;
    }

    function _getPolicy(uint256 policyId) internal view returns (AccessPolicy storage) {
        if (policyId == 0 || policyId > _policyCounter || !_policies[policyId].isActive) revert PolicyNotFound();
        return _policies[policyId];
    }

    function _isPolicyConditionMet(AccessCondition memory condition, bytes memory context) internal view returns (bool) {
        if (condition.conditionType == AccessConditionType.None) {
            return true; // No specific condition
        } else if (condition.conditionType == AccessConditionType.TimeBased) {
            (uint256 startTime, uint256 endTime) = abi.decode(condition.conditionDetails, (uint256, uint256));
            return block.timestamp >= startTime && block.timestamp <= endTime;
        } else if (condition.conditionType == AccessConditionType.PaymentRequired) {
            // This is a proof-of-payment check. The 'context' should contain information
            // about the payment (e.g., a tx hash or a state root proving a balance).
            // For simplicity in this example, we'll assume 'context' is non-empty
            // to indicate proof was provided off-chain. A real implementation
            // might require complex ZK proofs or oracle interactions.
            // Decode expected payment details: (address tokenAddress, uint256 amount)
            (address requiredToken, uint256 requiredAmount) = abi.decode(condition.conditionDetails, (address, uint256));
            // A real check would verify the context data, maybe interact with a payment oracle or check state.
            // Placeholder: Assume context must contain *something* as proof.
            return context.length > 0;
        } else if (condition.conditionType == AccessConditionType.CredentialProof) {
             // This requires proof related to a specific credential.
             // Decode required credential hash: (bytes32 requiredCredentialHash)
            (bytes32 requiredCredentialHash) = abi.decode(condition.conditionDetails, (bytes32));
             // Check if the credential reference exists in the vault
             if (_credentialReferences[requiredCredentialHash].addedTimestamp == 0) {
                 return false; // Required credential is not even referenced in this vault
             }
             // A real check would verify the context data, e.g., a ZK-SNARK proof
             // that the recipient holds a VC related to the requiredCredentialHash.
             // Placeholder: Assume context must contain *something* as proof.
            return context.length > 0;
        }
        return false; // Unknown condition type
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _policyCounter = 0;
    }

    // --- Owner Functions ---

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert NotOwner(); // Simple check against zero address
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

     /// @notice Sets the metadata URI for the vault.
    /// @param uri The new URI string.
    function setVaultURI(string memory uri) external onlyOwner {
        _vaultURI = uri;
        emit VaultURISet(uri);
    }

    // --- Delegate Management ---

    /// @notice Designates an address as a delegate with specific permissions.
    /// @param delegate The address to designate.
    /// @param permissions The set of permissions to grant.
    function designateDelegate(address delegate, DelegatePermissions memory permissions) external onlyOwner {
        _delegates[delegate] = permissions;
        emit DelegateDesignated(delegate, permissions);
    }

    /// @notice Updates the permissions for an existing delegate.
    /// @param delegate The delegate address.
    /// @param permissions The new set of permissions.
    function updateDelegatePermissions(address delegate, DelegatePermissions memory permissions) external onlyOwner {
        if (_delegates[delegate].canManageCredentials == false &&
            _delegates[delegate].canManageAssets == false &&
            _delegates[delegate].canManagePolicies == false &&
             _delegates[delegate].canExecuteTransfers == false) {
                // Not a delegate yet, use designateDelegate
                revert NotOwner(); // Or a specific error like NotADelegate
             }
        _delegates[delegate] = permissions;
        emit DelegatePermissionsUpdated(delegate, permissions);
    }

    /// @notice Revokes all delegate permissions from an address.
    /// @param delegate The address to revoke permissions from.
    function revokeDelegate(address delegate) external onlyOwner {
         if (_delegates[delegate].canManageCredentials == false &&
            _delegates[delegate].canManageAssets == false &&
            _delegates[delegate].canManagePolicies == false &&
             _delegates[delegate].canExecuteTransfers == false) {
                // Not a delegate, nothing to revoke
                return;
             }
        delete _delegates[delegate];
        emit DelegateRevoked(delegate);
    }

    // --- Asset Linking & Unlinking (Vault holds assets) ---

    /// @notice Links ERC20 tokens by transferring them into the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to link.
    function linkERC20(address tokenAddress, uint256 amount) external {
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManageAssets)) revert DelegatePermissionDenied();
        require(amount > 0, "Amount must be positive");

        IERC20 token = IERC20(tokenAddress);
        uint256 vaultBalanceBefore = token.balanceOf(address(this));

        // transferFrom requires the caller (msg.sender) to have approved the vault contract
        // to spend `amount` tokens on behalf of msg.sender.
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        // Update internal balance tracking (optional but can be useful)
        _linkedERC20Balances[tokenAddress] = vaultBalanceBefore + amount;

        // Add token address to the list if not already present
        bool exists = false;
        for(uint i = 0; i < _linkedERC20TokensList.length; i++) {
            if (_linkedERC20TokensList[i] == tokenAddress) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _linkedERC20TokensList.push(tokenAddress);
        }

        emit ERC20Linked(tokenAddress, amount);
    }

    /// @notice Unlinks ERC20 tokens by transferring them from the vault back to the owner.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to unlink.
    function unlinkERC20(address tokenAddress, uint256 amount) external {
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManageAssets)) revert DelegatePermissionDenied();
        require(amount > 0, "Amount must be positive");
        if (_linkedERC20Balances[tokenAddress] < amount) revert InsufficientVaultBalance();

        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(_owner, amount); // Transfer back to the owner
        if (!success) revert TransferFailed();

        _linkedERC20Balances[tokenAddress] -= amount;

        // Note: Removing from _linkedERC20TokensList on zero balance is complex/expensive.
        // We'll leave it there; view functions can filter by balance > 0.

        emit ERC20Unlinked(tokenAddress, amount);
    }

    /// @notice Links an ERC721 token by transferring it into the vault.
    /// @param tokenAddress The address of the ERC721 collection.
    /// @param tokenId The ID of the token to link.
    function linkERC721(address tokenAddress, uint256 tokenId) external {
         if (!_checkDelegatePermission(msg.sender, PermissionType.ManageAssets)) revert DelegatePermissionDenied();

        IERC721 token = IERC721(tokenAddress);
        // transferFrom requires the caller (msg.sender) to be the owner or approved for the token/collection.
        // The contract must be approved or use `safeTransferFrom` from a trusted caller like the owner.
        // For simplicity, assumes msg.sender is authorized to transfer the token.
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        _linkedERC721Owners[tokenId][tokenAddress] = address(this); // Record vault ownership

         // Add token collection address to the list if not already present
        bool exists = false;
        for(uint i = 0; i < _linkedERC721TokensList.length; i++) {
            if (_linkedERC721TokensList[i] == tokenAddress) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _linkedERC721TokensList.push(tokenAddress);
        }

        emit ERC721Linked(tokenAddress, tokenId);
    }

    /// @notice Unlinks an ERC721 token by transferring it from the vault back to the owner.
    /// @param tokenAddress The address of the ERC721 collection.
    /// @param tokenId The ID of the token to unlink.
    function unlinkERC721(address tokenAddress, uint256 tokenId) external {
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManageAssets)) revert DelegatePermissionDenied();
        if (_linkedERC721Owners[tokenId][tokenAddress] != address(this)) revert InsufficientVaultBalance(); // Vault doesn't own it

        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(address(this), _owner, tokenId); // Transfer back to the owner

        delete _linkedERC721Owners[tokenId][tokenAddress]; // Clear record

        // Note: Removing from _linkedERC721TokensList on zero owned tokens in collection is complex.
        // View functions can filter by ownerOf == address(this).

        emit ERC721Unlinked(tokenAddress, tokenId);
    }

    /// @notice Links ERC1155 tokens by transferring them into the vault.
    /// @param tokenAddress The address of the ERC1155 collection.
    /// @param id The ID of the token type.
    /// @param amount The amount of tokens to link.
    function linkERC1155(address tokenAddress, uint256 id, uint256 amount) external {
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManageAssets)) revert DelegatePermissionDenied();
        require(amount > 0, "Amount must be positive");

        IERC1155 token = IERC1155(tokenAddress);
        // safeTransferFrom requires the caller (msg.sender) to be the owner or approved for the collection.
        token.safeTransferFrom(msg.sender, address(this), id, amount, ""); // Empty data payload

        _linkedERC1155Balances[tokenAddress][id] += amount; // Record vault balance

         // Add token collection address to the list if not already present
        bool exists = false;
        for(uint i = 0; i < _linkedERC1155TokensList.length; i++) {
            if (_linkedERC1155TokensList[i] == tokenAddress) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _linkedERC1155TokensList.push(tokenAddress);
        }

        emit ERC1155Linked(tokenAddress, id, amount);
    }

    /// @notice Unlinks ERC1155 tokens by transferring them from the vault back to the owner.
    /// @param tokenAddress The address of the ERC1155 collection.
    /// @param id The ID of the token type.
    /// @param amount The amount of tokens to unlink.
    function unlinkERC1155(address tokenAddress, uint256 id, uint256 amount) external {
         if (!_checkDelegatePermission(msg.sender, PermissionType.ManageAssets)) revert DelegatePermissionDenied();
         require(amount > 0, "Amount must be positive");
         if (_linkedERC1155Balances[tokenAddress][id] < amount) revert InsufficientVaultBalance();

        IERC1155 token = IERC1155(tokenAddress);
        token.safeTransferFrom(address(this), _owner, id, amount, ""); // Transfer back to the owner

        _linkedERC1155Balances[tokenAddress][id] -= amount; // Update vault balance

         // Note: Removing from _linkedERC1155TokensList is complex.

        emit ERC1155Unlinked(tokenAddress, id, amount);
    }

    // --- Credential Reference Management ---

    /// @notice Adds a reference to an off-chain credential or data item.
    /// @param dataHash Secure hash of the data.
    /// @param description Human-readable description.
    /// @param uri Optional URI.
    /// @param issuer Address or identifier of the issuer.
    function addCredentialReference(bytes32 dataHash, string memory description, string memory uri, address issuer) external {
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManageCredentials)) revert DelegatePermissionDenied();
        require(_credentialReferences[dataHash].addedTimestamp == 0, "Credential hash already exists");

        _credentialReferences[dataHash] = CredentialReference(dataHash, description, uri, issuer, block.timestamp);
        _credentialHashes.push(dataHash); // Add to list

        emit CredentialReferenceAdded(dataHash, issuer);
    }

    /// @notice Updates the metadata for an existing credential reference.
    /// @param dataHash The hash of the credential reference to update.
    /// @param description New description.
    /// @param uri New URI.
    /// @param issuer New issuer address.
    function updateCredentialReference(bytes32 dataHash, string memory description, string memory uri, address issuer) external {
         if (!_checkDelegatePermission(msg.sender, PermissionType.ManageCredentials)) revert DelegatePermissionDenied();
         if (_credentialReferences[dataHash].addedTimestamp == 0) revert CredentialNotFound();

        _credentialReferences[dataHash].description = description;
        _credentialReferences[dataHash].uri = uri;
        _credentialReferences[dataHash].issuer = issuer;

        emit CredentialReferenceUpdated(dataHash, issuer);
    }

    /// @notice Removes a credential reference.
    /// @param dataHash The hash of the credential reference to remove.
    function removeCredentialReference(bytes32 dataHash) external {
         if (!_checkDelegatePermission(msg.sender, PermissionType.ManageCredentials)) revert DelegatePermissionDenied();
         if (_credentialReferences[dataHash].addedTimestamp == 0) revert CredentialNotFound();

        delete _credentialReferences[dataHash];

        // Remove from the list (potentially expensive)
        uint256 len = _credentialHashes.length;
        for(uint i = 0; i < len; i++) {
            if (_credentialHashes[i] == dataHash) {
                // Replace with last element and shorten array (order not preserved)
                _credentialHashes[i] = _credentialHashes[len - 1];
                _credentialHashes.pop();
                break;
            }
        }

        emit CredentialReferenceRemoved(dataHash);
    }

    // --- Access Policy Management ---

    /// @notice Creates a new access policy.
    /// @param recipient The address the policy applies to.
    /// @param target The item(s) the policy governs access to.
    /// @param condition The conditions required for access.
    /// @param permission The type of permission granted.
    /// @return policyId The ID of the newly created policy.
    function createAccessPolicy(
        address recipient,
        PolicyTarget memory target,
        AccessCondition memory condition,
        PermissionType permission
    ) external returns (uint256) {
        // Only owner or delegate with policy management permission can create policies
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManagePolicies)) revert DelegatePermissionDenied();
        require(recipient != address(0), "Recipient cannot be zero address");
        require(target.targetType != PolicyTargetType.None, "Invalid target type");
        require(permission != PermissionType.None, "Invalid permission type");

        _policyCounter++;
        uint256 newPolicyId = _policyCounter;

        _policies[newPolicyId] = AccessPolicy(
            newPolicyId,
            recipient,
            target,
            condition,
            permission,
            true, // isActive
            block.timestamp
        );

        _policyIds.push(newPolicyId); // Add to list of active policies

        emit AccessPolicyCreated(newPolicyId, recipient, target, permission);
        return newPolicyId;
    }

    /// @notice Updates an existing access policy.
    /// @param policyId The ID of the policy to update.
    /// @param target The new target item(s).
    /// @param condition The new conditions required for access.
    /// @param permission The new type of permission granted.
    function updateAccessPolicy(
        uint256 policyId,
        PolicyTarget memory target,
        AccessCondition memory condition,
        PermissionType permission
    ) external {
        // Only owner or delegate with policy management permission can update policies
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManagePolicies)) revert DelegatePermissionDenied();
        AccessPolicy storage policy = _getPolicy(policyId); // Check existence and activity

        policy.target = target;
        policy.condition = condition;
        policy.permission = permission;

        emit AccessPolicyUpdated(policyId, target, permission);
    }

    /// @notice Deactivates an access policy.
    /// @param policyId The ID of the policy to revoke.
    function revokeAccessPolicy(uint256 policyId) external {
         // Only owner or delegate with policy management permission can revoke policies
        if (!_checkDelegatePermission(msg.sender, PermissionType.ManagePolicies)) revert DelegatePermissionDenied();
        AccessPolicy storage policy = _getPolicy(policyId); // Check existence and activity

        policy.isActive = false;

        // Remove from the list (potentially expensive)
        uint256 len = _policyIds.length;
        for(uint i = 0; i < len; i++) {
            if (_policyIds[i] == policyId) {
                // Replace with last element and shorten array (order not preserved)
                _policyIds[i] = _policyIds[len - 1];
                _policyIds.pop();
                break;
            }
        }

        emit AccessPolicyRevoked(policyId);
    }

    /// @notice Evaluates whether a specific access policy's conditions are met for the caller.
    /// @param policyId The ID of the policy to evaluate.
    /// @param context External data required for condition evaluation (e.g., proof of payment).
    /// @return bool True if the policy exists, is active, applies to msg.sender, and conditions are met.
    function evaluateAccessPolicy(uint256 policyId, bytes memory context) public view returns (bool) {
        if (policyId == 0 || policyId > _policyCounter) return false; // Policy doesn't exist by ID range
        AccessPolicy storage policy = _policies[policyId];

        if (!policy.isActive || policy.recipient != msg.sender) {
            return false; // Policy not active or doesn't apply to caller
        }

        bool conditionMet = _isPolicyConditionMet(policy.condition, context);
        emit PolicyEvaluated(policyId, msg.sender, conditionMet); // Emit for off-chain tracking
        return conditionMet;
    }

    /// @notice Attempts to execute an asset transfer based on a policy with InitiateTransfer permission.
    /// Requires the policy conditions to be met for the caller.
    /// @param policyId The ID of the policy authorizing the transfer.
    /// @param tokenAddress The address of the token collection (ERC20, ERC721, ERC1155).
    /// @param amountOrId For ERC20: amount; For ERC721: tokenId; For ERC1155: id.
    /// @param valueForERC1155 For ERC1155 only: the amount to transfer. Ignored for ERC20/721.
    /// @param context External data required for condition evaluation.
    function executeConditionalTransfer(
        uint256 policyId,
        address tokenAddress,
        uint256 amountOrId,
        uint256 valueForERC1155,
        bytes memory context
    ) external {
        // Check if caller is the policy recipient OR a delegate with ExecuteTransfers permission
        bool isPolicyRecipient = (_policies[policyId].isActive && _policies[policyId].recipient == msg.sender);
        bool isAuthorizedDelegate = _checkDelegatePermission(msg.sender, PermissionType.InitiateTransfer);

        if (!isPolicyRecipient && !isAuthorizedDelegate) {
            revert UnauthorizedTransfer();
        }

        AccessPolicy storage policy = _getPolicy(policyId); // Check existence and activity

        // If caller is a delegate, ensure the policy recipient is authorized
        if (isAuthorizedDelegate && policy.recipient != msg.sender) {
             // Delegate is executing *on behalf of the recipient allowed by the policy*
             // This scenario is slightly ambiguous. Let's assume delegate can trigger
             // any policy *if* the policy conditions are met for the *recipient* and
             // the delegate has the execute permission.
             // For simplicity, require msg.sender == policy.recipient OR msg.sender is authorized delegate.
             // The evaluateAccessPolicy checks if *msg.sender* meets conditions.
             // A delegate executing *for* a recipient would need a different check structure,
             // possibly requiring the delegate to pass recipient-specific context.
             // Let's stick to the simpler model for now: `msg.sender` must be the recipient or a delegate.
             // If delegate, they must evaluate for themselves? Or pass recipient address?
             // Let's require `msg.sender` is the recipient for policy execution,
             // *unless* `msg.sender` is a delegate with `canExecuteTransfers`.
             // If it's a delegate, the policy *still* must target someone (could be 0x0 if policy is public).
             // Let's simplify: `msg.sender` must be the policy recipient. Delegates only trigger policies *if they are the recipient*.
             // OR: Delegate can trigger ANY `InitiateTransfer` policy if conditions are met for `policy.recipient`.
             // Let's go with the second option, delegate acting on behalf of potential recipient.
             // The `evaluateAccessPolicy` helper needs to be called with `policy.recipient`.

             // Evaluate policy conditions for the *intended recipient*
             if (!_isPolicyConditionMet(policy.condition, context)) {
                 revert PolicyConditionNotMet();
             }

        } else { // msg.sender is the policy recipient
            if (!evaluateAccessPolicy(policyId, context)) {
                revert PolicyConditionNotMet();
            }
        }


        if (policy.permission != PermissionType.InitiateTransfer) {
            revert InvalidPolicyTarget(); // Policy does not grant transfer permission
        }

        // Execute the transfer based on policy target type and details
        if (policy.target.targetType == PolicyTargetType.SpecificAssetERC20) {
            address targetTokenAddress = address(uint160(uint256(policy.target.targetId)));
            uint256 transferAmount = amountOrId; // For ERC20, amountOrId is the amount

            if (targetTokenAddress != tokenAddress || transferAmount != amountOrId) revert PolicyTargetMismatch();
            if (_linkedERC20Balances[tokenAddress] < transferAmount) revert InsufficientVaultBalance();

            IERC20 token = IERC20(tokenAddress);
            bool success = token.transfer(policy.recipient, transferAmount); // Transfer to the policy recipient
            if (!success) revert TransferFailed();
            _linkedERC20Balances[tokenAddress] -= transferAmount;

             emit ConditionalTransferExecuted(policyId, policy.recipient, tokenAddress, transferAmount, 0);

        } else if (policy.target.targetType == PolicyTargetType.SpecificAssetERC721) {
            address targetTokenAddress = tokenAddress; // ERC721 address comes from function input
            uint256 targetTokenId = amountOrId; // ERC721 tokenId comes from function input
            bytes32 policyTargetId = bytes32(uint256(targetTokenId));

            if (policy.target.targetId != policyTargetId) revert PolicyTargetMismatch();
             if (_linkedERC721Owners[targetTokenId][targetTokenAddress] != address(this)) revert InsufficientVaultBalance(); // Vault doesn't own it

            IERC721 token = IERC721(targetTokenAddress);
            token.safeTransferFrom(address(this), policy.recipient, targetTokenId); // Transfer to the policy recipient
            delete _linkedERC721Owners[targetTokenId][targetTokenAddress];

            emit ConditionalTransferExecuted(policyId, policy.recipient, targetTokenAddress, targetTokenId, 0);

        } else if (policy.target.targetType == PolicyTargetType.SpecificAssetERC1155) {
            address targetTokenAddress = tokenAddress; // ERC1155 address comes from function input
            uint256 targetTokenId = amountOrId; // ERC1155 id comes from function input
            uint256 transferAmount = valueForERC1155; // ERC1155 amount comes from function input
            bytes32 policyTargetId = keccak256(abi.encodePacked(targetTokenAddress, targetTokenId));

             if (policy.target.targetId != policyTargetId) revert PolicyTargetMismatch();
             if (_linkedERC1155Balances[targetTokenAddress][targetTokenId] < transferAmount) revert InsufficientVaultBalance();

            IERC1155 token = IERC1155(targetTokenAddress);
            token.safeTransferFrom(address(this), policy.recipient, targetTokenId, transferAmount, ""); // Transfer to the policy recipient
            _linkedERC1155Balances[targetTokenAddress][targetTokenId] -= transferAmount;

            emit ConditionalTransferExecuted(policyId, policy.recipient, targetTokenAddress, targetTokenId, transferAmount);

        } else {
            // Policy permission is InitiateTransfer, but target is not a specific asset?
            // This case should ideally be prevented during policy creation or handled.
            // For now, consider it an invalid execution attempt.
            revert InvalidPolicyTarget();
        }
    }

    // --- View Functions (Read-only) ---

    /// @notice Gets the current owner of the vault.
    function getVaultOwner() external view returns (address) {
        return _owner;
    }

    /// @notice Gets the vault metadata URI.
    function getVaultURI() external view returns (string memory) {
        return _vaultURI;
    }

    /// @notice Checks if an address is currently designated as a delegate.
    /// @param queryAddress The address to check.
    function isDelegate(address queryAddress) external view returns (bool) {
        // Check if any permission is true
         return _delegates[queryAddress].canManageCredentials ||
                _delegates[queryAddress].canManageAssets ||
                _delegates[queryAddress].canManagePolicies ||
                _delegates[queryAddress].canExecuteTransfers;
    }

    /// @notice Retrieves the specific permissions granted to a delegate.
    /// @param delegate The delegate address.
    function getDelegatePermissions(address delegate) external view returns (DelegatePermissions memory) {
        return _delegates[delegate];
    }

    /// @notice Retrieves the details of a stored credential reference by its hash.
    /// @param dataHash The hash of the credential reference.
    function getCredentialReference(bytes32 dataHash) external view returns (CredentialReference memory) {
        if (_credentialReferences[dataHash].addedTimestamp == 0) revert CredentialNotFound();
        return _credentialReferences[dataHash];
    }

    /// @notice Lists all stored credential hashes.
    function listCredentialHashes() external view returns (bytes32[] memory) {
        return _credentialHashes;
    }

    /// @notice Gets the vault's balance for a specific linked ERC20 token.
    /// @param tokenAddress The address of the ERC20 token.
    function getLinkedERC20Balance(address tokenAddress) external view returns (uint256) {
         // While _linkedERC20Balances tracks transfers *into* the vault via linkERC20,
         // the true source of truth is the token contract itself.
         // However, accessing external contracts in view functions might be restricted depending on the environment.
         // For correctness, it should ideally be IERC20(tokenAddress).balanceOf(address(this)).
         // Let's return the internally tracked balance for demonstration, acknowledging this limitation.
        return _linkedERC20Balances[tokenAddress];
    }

    /// @notice Checks if the vault owns a specific ERC721 token.
    /// @param tokenAddress The address of the ERC721 collection.
    /// @param tokenId The ID of the token.
    function getLinkedERC721Owner(address tokenAddress, uint256 tokenId) external view returns (address) {
        // Similar to ERC20, the true owner is on the token contract.
        // Returning internal state for demonstration.
        // Ideal: IERC721(tokenAddress).ownerOf(tokenId).
        return _linkedERC721Owners[tokenId][tokenAddress];
    }

    /// @notice Gets the vault's balance for a specific ERC1155 token type.
    /// @param tokenAddress The address of the ERC1155 collection.
    /// @param id The ID of the token type.
    function getLinkedERC1155Balance(address tokenAddress, uint256 id) external view returns (uint256) {
         // Similar to ERC20, returning internal state.
         // Ideal: IERC1155(tokenAddress).balanceOf(address(this), id).
        return _linkedERC1155Balances[tokenAddress][id];
    }

     /// @notice Lists addresses of linked ERC20 tokens.
    function listLinkedERC20Tokens() external view returns (address[] memory) {
        return _linkedERC20TokensList;
    }

     /// @notice Lists addresses of linked ERC721 collections.
    function listLinkedERC721Tokens() external view returns (address[] memory) {
        return _linkedERC721TokensList;
    }

     /// @notice Lists addresses of linked ERC1155 collections.
    function listLinkedERC1155Tokens() external view returns (address[] memory) {
        return _linkedERC1155TokensList;
    }

    /// @notice Retrieves the details of an access policy.
    /// @param policyId The ID of the policy.
    function getPolicyDetails(uint256 policyId) external view returns (AccessPolicy memory) {
        if (policyId == 0 || policyId > _policyCounter) revert PolicyNotFound();
        return _policies[policyId];
    }

    /// @notice Lists IDs of active policies targeting a specific recipient.
    /// @param recipient The recipient address.
    function listPoliciesForRecipient(address recipient) external view returns (uint256[] memory) {
        uint256[] memory policiesForRecipient = new uint256[](_policyIds.length);
        uint256 count = 0;
        for (uint i = 0; i < _policyIds.length; i++) {
            uint256 policyId = _policyIds[i];
            if (_policies[policyId].isActive && _policies[policyId].recipient == recipient) {
                policiesForRecipient[count] = policyId;
                count++;
            }
        }
        bytes memory trimmedResult = new bytes(count * 32); // 32 bytes per uint256
        assembly {
            // Copy relevant portion of the array
            // mload(add(policiesForRecipient, 0x20)) gets the pointer to the first element
            // policiesForRecipient.length is at policiesForRecipient + 0
            // policiesForRecipient[i] is at policiesForRecipient + 0x20 + i * 0x20
            let src := add(policiesForRecipient, 0x20)
            let dest := add(trimmedResult, 0x20)
            let size := mul(count, 0x20)
            // Copy from src to dest, `size` bytes
            datacopy(dest, src, size)
            // Set the length of the new array
            mstore(trimmedResult, size)
        }
        return abi.decode(trimmedResult, (uint256[]))[0];
    }

     /// @notice Lists IDs of all active policies.
    function listActivePolicies() external view returns (uint256[] memory) {
        // Return a copy of the internal _policyIds array
        uint256[] memory activePolicyIds = new uint256[](_policyIds.length);
        for(uint i = 0; i < _policyIds.length; i++) {
            activePolicyIds[i] = _policyIds[i];
        }
        return activePolicyIds;
    }

    // --- Fallback/Receive (Optional, handle incoming ETH) ---
    receive() external payable {}
    fallback() external payable {}

    // --- ERC1155 Receiver Hook ---
    // Required to receive ERC1155 tokens
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data) external returns (bytes4) {
        // Accept transfer if it's from the owner or a delegate (linking process)
        // Or implement specific logic based on use case.
        // For this vault, assume transfers come from owner/delegates during linking.
        // Check if operator is owner or delegate.
        if (operator != _owner && !_checkDelegatePermission(operator, PermissionType.ManageAssets)) {
             revert UnauthorizedTransfer();
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external returns (bytes4) {
        // Accept transfer if it's from the owner or a delegate (linking process)
         if (operator != _owner && !_checkDelegatePermission(operator, PermissionType.ManageAssets)) {
             revert UnauthorizedTransfer();
        }
        return this.onERC1155BatchReceived.selector;
    }
}
```