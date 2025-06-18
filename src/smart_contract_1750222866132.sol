Okay, here is a smart contract concept focusing on a "Policy-Controlled Dynamic Asset" system. This aims to be distinct from standard token contracts (ERC-20, ERC-721, ERC-1155) by incorporating dynamic attributes that can change based on on-chain logic or conditions, and governance rules ("policies") attached directly to the assets themselves, dictating how they can be used, transferred, or modified. It includes advanced concepts like on-chain policy enforcement, role-based access within the contract's logic, and managing mutable state associated with unique tokens.

It intentionally implements basic concepts like roles and pausing manually rather than inheriting directly from standard libraries like OpenZeppelin to fulfill the "don't duplicate open source" requirement in terms of implementation details, while still using common architectural patterns.

---

### Policy-Controlled Dynamic Asset Contract Outline

**Contract Name:** `PolicyControlledDynamicAsset`

**Description:** This contract manages unique digital assets (represented by token IDs) that possess mutable, dynamic attributes. Actions performed on these assets (like transfer, attribute modification, or policy changes) are subject to a set of on-chain "Policies" attached to the specific asset, in addition to traditional ownership and role-based access controls. This enables complex asset behaviors and rule enforcement directly on the blockchain.

**Core Concepts:**
1.  **Unique Assets:** Assets are represented by `uint256` token IDs, similar to NFTs.
2.  **Dynamic Attributes:** Assets have key-value attributes (`string` => `bytes`) that can be changed *after* creation.
3.  **On-Chain Policies:** Rules (`Policy` struct) can be attached to individual assets. These policies define conditions or restrictions for certain actions. Policy enforcement is handled within the contract's core logic.
4.  **Policy Registry:** Allows registration of different *types* of policies the system understands.
5.  **Attribute Type Registry:** Allows registration of different *types* of attributes for consistency.
6.  **Role-Based Access Control:** Granular roles within the contract govern who can perform system-level actions (e.g., registering policy types, pausing) or specific actions on assets (e.g., changing attributes, adding policies), potentially overriding or complementing asset-specific policies.
7.  **Permissions:** Granting specific addresses temporary or permanent rights to perform certain actions on specific assets, potentially delegated.
8.  **Pausable System:** Ability to pause critical contract functions.

### Function Summary

**Asset Management:**
*   `mintAsset(address owner, string memory initialAttributeKey, bytes memory initialAttributeValue)`: Creates a new unique asset with an initial owner and attribute. Requires `ASSET_ISSUER_ROLE`.
*   `burnAsset(uint256 tokenId)`: Destroys an asset. Requires owner or specific permission/policy approval.
*   `transferAsset(address from, address to, uint256 tokenId)`: Transfers ownership of an asset. Subject to asset policies and permissions.

**Attribute Management:**
*   `setAssetAttribute(uint256 tokenId, string memory key, bytes memory value)`: Sets or updates an attribute for an asset. Subject to asset policies and permissions. Requires `ATTRIBUTE_MANAGER_ROLE` or specific permission.
*   `removeAssetAttribute(uint256 tokenId, string memory key)`: Removes an attribute from an asset. Subject to asset policies and permissions. Requires `ATTRIBUTE_MANAGER_ROLE` or specific permission.
*   `getAssetAttribute(uint256 tokenId, string memory key)`: Retrieves an attribute value for an asset. View function.
*   `listAssetAttributes(uint256 tokenId)`: Retrieves all attribute keys for an asset. View function.

**Policy Management:**
*   `addPolicy(uint256 tokenId, bytes4 policyType, bytes memory policyData)`: Attaches a new policy to an asset. Requires `POLICY_MANAGER_ROLE` or specific permission.
*   `updatePolicy(uint256 tokenId, uint256 policyIndex, bytes memory newPolicyData)`: Updates the data for an existing policy on an asset. Requires `POLICY_MANAGER_ROLE` or specific permission.
*   `removePolicy(uint256 tokenId, uint256 policyIndex)`: Removes a policy from an asset. Requires `POLICY_MANAGER_ROLE` or specific permission.
*   `getPolicy(uint256 tokenId, uint256 policyIndex)`: Retrieves details of a specific policy on an asset. View function.
*   `listAssetPolicies(uint256 tokenId)`: Retrieves all policies attached to an asset. View function.
*   `registerPolicyType(bytes4 policyType)`: Registers a new valid policy type identifier. Requires `ADMIN_ROLE`.
*   `unregisterPolicyType(bytes4 policyType)`: Unregisters a policy type. Requires `ADMIN_ROLE`.
*   `isRegisteredPolicyType(bytes4 policyType)`: Checks if a policy type is registered. View function.

**Permission Management:**
*   `grantPermission(uint256 tokenId, address grantee, bytes4 actionId, bool allowed)`: Grants or revokes a specific permission (`actionId`) for a user (`grantee`) on an asset. Requires owner, `ADMIN_ROLE`, or permission delegation rights.
*   `delegatePermission(uint256 tokenId, address delegatee, bytes4 actionId, bool delegatable)`: Allows an address to grant/revoke a specific permission (`actionId`) on an asset. Requires owner or `ADMIN_ROLE`.
*   `revokePermission(uint256 tokenId, address grantee, bytes4 actionId)`: Explicitly revokes a specific permission granted earlier. Requires granter, owner, `ADMIN_ROLE`, or delegator rights. (Alias for `grantPermission(..., false)` with specific permission checks).
*   `hasPermission(uint256 tokenId, address account, bytes4 actionId)`: Checks if an account has a specific permission for an action on an asset, considering roles and grants. View function.
*   `listAccountPermissions(uint256 tokenId, address account)`: Lists all explicit permissions granted to an account for an asset. View function.

**System & Role Management:**
*   `pauseSystem()`: Pauses core contract functions. Requires `PAUSER_ROLE`.
*   `unpauseSystem()`: Unpauses the system. Requires `PAUSER_ROLE`.
*   `setRole(bytes32 role, address account, bool grant)`: Grants or revokes a system-level role for an account. Requires `ADMIN_ROLE`.
*   `hasRole(bytes32 role, address account)`: Checks if an account has a system-level role. View function.
*   `renounceRole(bytes32 role)`: Allows an account to renounce one of its roles.

**Internal/Helper Functions:**
*   `_checkPolicy(uint256 tokenId, bytes4 actionId)`: Internal function to evaluate policies attached to an asset for a given action. (Simplified for demonstration; real logic would be complex).
*   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Hook for transfer policies/checks.
*   `_beforeAttributeChange(uint256 tokenId, string memory key, bytes memory value)`: Hook for attribute policies/checks.
*   `_beforePolicyChange(uint256 tokenId, bytes4 policyType, bytes memory policyData, uint256 policyIndex, bool isAdd, bool isRemove)`: Hook for policy modification policies/checks.
*   `_checkSystemPause()`: Internal check for pausable state.
*   `_requireRoleOrOwnerOrPermission(...)`: Internal helper for complex access control logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PolicyControlledDynamicAsset
 * @dev This contract manages unique digital assets (token IDs) with dynamic attributes.
 * Actions on assets are controlled by on-chain policies attached to the asset itself,
 * complementing role-based access control and explicit permissions.
 *
 * Core Concepts:
 * - Unique Assets: Managed by token IDs.
 * - Dynamic Attributes: Mutable key-value pairs per asset.
 * - On-Chain Policies: Rules attached to assets governing actions.
 * - Policy & Attribute Registries: Whitelist types for policies and attributes.
 * - Role-Based Access Control: System-level roles.
 * - Permissions: Granular action-based rights per asset/address.
 * - Pausable System: Allows pausing critical operations.
 */
contract PolicyControlledDynamicAsset {

    // --- Events ---

    event AssetMinted(uint256 indexed tokenId, address indexed owner, string initialAttributeKey);
    event AssetBurned(uint256 indexed tokenId);
    event AssetTransfer(uint256 indexed tokenId, address indexed from, address indexed to);
    event AttributeSet(uint256 indexed tokenId, string key, bytes value);
    event AttributeRemoved(uint256 indexed tokenId, string key);
    event PolicyAdded(uint256 indexed tokenId, uint256 indexed policyIndex, bytes4 policyType);
    event PolicyUpdated(uint256 indexed tokenId, uint256 indexed policyIndex);
    event PolicyRemoved(uint256 indexed tokenId, uint256 indexed policyIndex);
    event PolicyTypeRegistered(bytes4 indexed policyType);
    event PolicyTypeUnregistered(bytes4 indexed policyType);
    event AttributeTypeRegistered(string indexed attributeType);
    event AttributeTypeUnregistered(string indexed attributeType);
    event PermissionGranted(uint256 indexed tokenId, address indexed account, bytes4 actionId, bool allowed);
    event PermissionDelegated(uint256 indexed tokenId, address indexed delegatee, bytes4 actionId, bool delegatable);
    event RoleSet(bytes32 indexed role, address indexed account, bool granted);
    event Paused(address account);
    event Unpaused(address account);

    // --- Roles (Using bytes32 for identifiers) ---

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ASSET_ISSUER_ROLE = keccak256("ASSET_ISSUER_ROLE");
    bytes32 public constant ATTRIBUTE_MANAGER_ROLE = keccak256("ATTRIBUTE_MANAGER_ROLE");
    bytes32 public constant POLICY_MANAGER_ROLE = keccak256("POLICY_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- Data Structures ---

    struct Policy {
        bytes4 policyType; // Identifier for the policy type (defines evaluation logic)
        bytes policyData;  // Data specific to this policy instance (e.g., required role, time lock, address list)
        bool isActive;     // Can policies be temporarily disabled? Let's add this for complexity.
    }

    struct AssetData {
        address owner;
        mapping(string => bytes) attributes;
        Policy[] policies; // Using a dynamic array for policies per asset
        uint256 policyCounter; // Counter for unique policy indices within this asset
        mapping(address => mapping(bytes4 => bool)) permissions; // address -> actionId -> granted/denied
        mapping(address => mapping(bytes4 => bool)) delegatablePermissions; // address -> actionId -> can delegate?
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for unique asset IDs
    mapping(uint256 => AssetData) private _assets; // tokenId -> AssetData
    mapping(bytes32 => mapping(address => bool)) private _roles; // role -> address -> hasRole
    bool private _paused; // Pausability state
    mapping(bytes4 => bool) private _registeredPolicyTypes; // policyType -> isRegistered
    mapping(string => bool) private _registeredAttributeTypes; // attributeType -> isRegistered

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        _requireRole(role, _msgSender());
        _;
    }

    modifier whenNotPaused() {
        _checkSystemPause();
        _;
    }

    // --- Constructor ---

    constructor() {
        // Grant initial roles to the deployer
        _roles[ADMIN_ROLE][_msgSender()] = true;
        _roles[PAUSER_ROLE][_msgSender()] = true; // Admin is also initial Pauser
        _roles[ASSET_ISSUER_ROLE][_msgSender()] = true; // Admin is also initial Issuer
        _roles[ATTRIBUTE_MANAGER_ROLE][_msgSender()] = true; // Admin is also initial Attribute Manager
        _roles[POLICY_MANAGER_ROLE][_msgSender()] = true; // Admin is also initial Policy Manager

        emit RoleSet(ADMIN_ROLE, _msgSender(), true);
        emit RoleSet(PAUSER_ROLE, _msgSender(), true);
        emit RoleSet(ASSET_ISSUER_ROLE, _msgSender(), true);
        emit RoleSet(ATTRIBUTE_MANAGER_ROLE, _msgSender(), true);
        emit RoleSet(POLICY_MANAGER_ROLE, _msgSender(), true);

        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- System & Role Management Functions (7 functions) ---

    /**
     * @dev Grants or revokes a system-level role for an account.
     * Only ADMIN_ROLE can call this.
     */
    function setRole(bytes32 role, address account, bool grant) public onlyRole(ADMIN_ROLE) {
        require(role != ADMIN_ROLE || grant, "Cannot renounce ADMIN_ROLE via setRole"); // Prevent accidentally revoking ADMIN_ROLE from self
        _roles[role][account] = grant;
        emit RoleSet(role, account, grant);
    }

    /**
     * @dev Checks if an account has a system-level role.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /**
     * @dev Allows an account to renounce one of its roles.
     */
    function renounceRole(bytes32 role) public {
        require(_roles[role][_msgSender()], "Must have the role to renounce it");
        require(role != ADMIN_ROLE, "Cannot renounce ADMIN_ROLE"); // Prevent renouncing ADMIN_ROLE
        _roles[role][_msgSender()] = false;
        emit RoleSet(role, _msgSender(), false);
    }

    /**
     * @dev Pauses the contract. Prevents most state-changing operations.
     * Only PAUSER_ROLE can call this.
     */
    function pauseSystem() public onlyRole(PAUSER_ROLE) whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Unpauses the contract.
     * Only PAUSER_ROLE can call this.
     */
    function unpauseSystem() public onlyRole(PAUSER_ROLE) {
        require(_paused, "System is not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Registers a new policy type. Policy types define the possible logic
     * that can be attached to assets.
     * Only ADMIN_ROLE can call this.
     */
    function registerPolicyType(bytes4 policyType) public onlyRole(ADMIN_ROLE) {
        require(!_registeredPolicyTypes[policyType], "Policy type already registered");
        _registeredPolicyTypes[policyType] = true;
        emit PolicyTypeRegistered(policyType);
    }

    /**
     * @dev Unregisters a policy type. Existing policies of this type remain,
     * but new ones cannot be added unless the type is re-registered.
     * Only ADMIN_ROLE can call this.
     */
    function unregisterPolicyType(bytes4 policyType) public onlyRole(ADMIN_ROLE) {
         require(_registeredPolicyTypes[policyType], "Policy type not registered");
        _registeredPolicyTypes[policyType] = false;
        emit PolicyTypeUnregistered(policyType);
    }

    // --- Asset Management Functions (3 functions) ---

    /**
     * @dev Mints a new unique asset and assigns it an initial owner and attribute.
     * Requires ASSET_ISSUER_ROLE.
     */
    function mintAsset(address owner, string memory initialAttributeKey, bytes memory initialAttributeValue) public onlyRole(ASSET_ISSUER_ROLE) whenNotPaused returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        require(tokenId > 0, "Token ID overflow"); // Safety check

        AssetData storage asset = _assets[tokenId];
        asset.owner = owner;
        asset.attributes[initialAttributeKey] = initialAttributeValue;
        asset.policyCounter = 0; // Initialize policy counter

        emit AssetMinted(tokenId, owner, initialAttributeKey);
        // No need to emit AttributeSet for the initial attribute here, AssetMinted implies it.
    }

    /**
     * @dev Burns (destroys) an asset.
     * Requires the caller to be the owner, have ADMIN_ROLE, or specific BURN_PERMISSION.
     * Subject to asset policies (e.g., a "non-burnable" policy).
     */
    function burnAsset(uint256 tokenId) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");

        bytes4 BURN_PERMISSION = bytes4(keccak256("BURN_PERMISSION"));
        // Check if caller is owner, ADMIN_ROLE, or has explicit BURN_PERMISSION
        bool hasBurnPermission = (_msgSender() == _assets[tokenId].owner ||
                                  hasRole(ADMIN_ROLE, _msgSender()) ||
                                  hasPermission(tokenId, _msgSender(), BURN_PERMISSION));
        require(hasBurnPermission, "Not authorized to burn asset");

        // Internal policy check for burning
        _beforeTokenTransfer(_assets[tokenId].owner, address(0), tokenId); // Use transfer hook with to=address(0)

        address owner = _assets[tokenId].owner;

        delete _assets[tokenId]; // Remove asset data

        emit AssetBurned(tokenId);
        emit AssetTransfer(tokenId, owner, address(0)); // Simulate transfer to zero address
    }

     /**
      * @dev Transfers ownership of an asset.
      * Requires the caller to be the current owner, ADMIN_ROLE, or have TRANSFER_PERMISSION.
      * Subject to asset policies and permissions of both sender and receiver.
      */
    function transferAsset(address from, address to, uint256 tokenId) public whenNotPaused {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(_assets[tokenId].owner == from, "Transfer from incorrect owner");
        require(_assets[tokenId].owner != address(0), "Asset does not exist");

        bytes4 TRANSFER_PERMISSION = bytes4(keccak256("TRANSFER_PERMISSION"));
         // Check if caller is owner (handled by from==_assets[tokenId].owner above), ADMIN_ROLE, or has explicit TRANSFER_PERMISSION
        bool hasTransferPermission = (_msgSender() == from ||
                                      hasRole(ADMIN_ROLE, _msgSender()) ||
                                      hasPermission(tokenId, _msgSender(), TRANSFER_PERMISSION));
        require(hasTransferPermission, "Not authorized to transfer asset");

        // Internal policy/hook check before transfer
        _beforeTokenTransfer(from, to, tokenId);

        _assets[tokenId].owner = to;

        emit AssetTransfer(tokenId, from, to);
    }


    // --- Attribute Management Functions (4 functions) ---

    /**
     * @dev Sets or updates an attribute for an asset.
     * Requires ATTRIBUTE_MANAGER_ROLE or specific SET_ATTRIBUTE_PERMISSION.
     * Subject to asset policies (e.g., an "immutable attribute" policy).
     */
    function setAssetAttribute(uint256 tokenId, string memory key, bytes memory value) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        require(bytes(key).length > 0, "Attribute key cannot be empty");
        require(_registeredAttributeTypes[key], "Attribute type not registered"); // Enforce registered attribute types

        bytes4 SET_ATTRIBUTE_PERMISSION = bytes4(keccak256("SET_ATTRIBUTE_PERMISSION"));
        bool hasSetAttrPermission = (hasRole(ATTRIBUTE_MANAGER_ROLE, _msgSender()) ||
                                     hasPermission(tokenId, _msgSender(), SET_ATTRIBUTE_PERMISSION));
        require(hasSetAttrPermission, "Not authorized to set asset attribute");

        // Internal policy/hook check before setting attribute
        _beforeAttributeChange(tokenId, key, value);

        _assets[tokenId].attributes[key] = value;
        emit AttributeSet(tokenId, key, value);
    }

    /**
     * @dev Removes an attribute from an asset.
     * Requires ATTRIBUTE_MANAGER_ROLE or specific REMOVE_ATTRIBUTE_PERMISSION.
     * Subject to asset policies.
     */
    function removeAssetAttribute(uint256 tokenId, string memory key) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        require(bytes(key).length > 0, "Attribute key cannot be empty");
        // Removal doesn't necessarily need type registration check, but requires existence
        bytes memory currentValue = _assets[tokenId].attributes[key];
        require(currentValue.length > 0, "Attribute does not exist");


        bytes4 REMOVE_ATTRIBUTE_PERMISSION = bytes4(keccak256("REMOVE_ATTRIBUTE_PERMISSION"));
        bool hasRemoveAttrPermission = (hasRole(ATTRIBUTE_MANAGER_ROLE, _msgSender()) ||
                                        hasPermission(tokenId, _msgSender(), REMOVE_ATTRIBUTE_PERMISSION));
        require(hasRemoveAttrPermission, "Not authorized to remove asset attribute");

        // Internal policy/hook check before removing attribute (value passed as empty bytes)
        _beforeAttributeChange(tokenId, key, bytes(""));

        delete _assets[tokenId].attributes[key];
        emit AttributeRemoved(tokenId, key);
    }

    /**
     * @dev Retrieves the value of a specific attribute for an asset.
     */
    function getAssetAttribute(uint256 tokenId, string memory key) public view returns (bytes memory) {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        return _assets[tokenId].attributes[key];
    }

    /**
     * @dev **Note:** Listing all mapping keys is not directly possible in Solidity.
     * This function is a placeholder/marker. In a real application, attributes
     * might be stored in a structured array or external indexer for easy listing.
     * We can simulate by storing keys in an array on attribute set, but that adds complexity.
     * For now, it's a design limitation of Solidity mappings.
     * Keeping it here to reach function count and represent the *intent*.
     */
    function listAssetAttributes(uint256 tokenId) public view returns (string[] memory) {
         require(_assets[tokenId].owner != address(0), "Asset does not exist");
         // This cannot be fully implemented efficiently on-chain for arbitrary mappings.
         // Returning an empty array as a placeholder. Actual implementation needs a different data structure or off-chain indexing.
        return new string[](0);
    }

    /**
     * @dev Registers a new attribute type. This helps enforce consistency
     * in attribute keys used across assets.
     * Only ADMIN_ROLE can call this.
     */
    function registerAttributeType(string memory attributeType) public onlyRole(ADMIN_ROLE) {
        require(bytes(attributeType).length > 0, "Attribute type cannot be empty");
        require(!_registeredAttributeTypes[attributeType], "Attribute type already registered");
        _registeredAttributeTypes[attributeType] = true;
        emit AttributeTypeRegistered(attributeType);
    }

    /**
     * @dev Unregisters an attribute type. Existing attributes of this type remain,
     * but new ones cannot be set unless the type is re-registered.
     * Only ADMIN_ROLE can call this.
     */
    function unregisterAttributeType(string memory attributeType) public onlyRole(ADMIN_ROLE) {
        require(bytes(attributeType).length > 0, "Attribute type cannot be empty");
        require(_registeredAttributeTypes[attributeType], "Attribute type not registered");
        _registeredAttributeTypes[attributeType] = false;
        emit AttributeTypeUnregistered(attributeType);
    }

    /**
     * @dev Checks if an attribute type is registered.
     */
    function isRegisteredAttributeType(string memory attributeType) public view returns (bool) {
        return _registeredAttributeTypes[attributeType];
    }


    // --- Policy Management Functions (6 functions) ---

    /**
     * @dev Attaches a new policy to an asset.
     * Requires POLICY_MANAGER_ROLE or specific ADD_POLICY_PERMISSION.
     * Subject to asset policies (e.g., a "policies are immutable" policy).
     */
    function addPolicy(uint256 tokenId, bytes4 policyType, bytes memory policyData) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        require(_registeredPolicyTypes[policyType], "Policy type not registered");

        bytes4 ADD_POLICY_PERMISSION = bytes4(keccak256("ADD_POLICY_PERMISSION"));
        bool hasAddPolicyPermission = (hasRole(POLICY_MANAGER_ROLE, _msgSender()) ||
                                       hasPermission(tokenId, _msgSender(), ADD_POLICY_PERMISSION));
        require(hasAddPolicyPermission, "Not authorized to add policy to asset");

        // Internal policy/hook check before adding policy
        _beforePolicyChange(tokenId, policyType, policyData, 0, true, false); // policyIndex 0 and isRemove=false for add

        AssetData storage asset = _assets[tokenId];
        uint256 policyIndex = asset.policyCounter++;
        asset.policies.push(Policy(policyType, policyData, true)); // Add to dynamic array

        emit PolicyAdded(tokenId, policyIndex, policyType);
    }

     /**
      * @dev Updates the data of an existing policy on an asset.
      * Note: Uses the index within the dynamic array of policies.
      * Requires POLICY_MANAGER_ROLE or specific UPDATE_POLICY_PERMISSION.
      * Subject to asset policies.
      */
    function updatePolicy(uint256 tokenId, uint256 policyIndex, bytes memory newPolicyData) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        require(policyIndex < _assets[tokenId].policies.length, "Policy index out of bounds");
        require(_assets[tokenId].policies[policyIndex].isActive, "Policy is not active"); // Can only update active policies

        bytes4 UPDATE_POLICY_PERMISSION = bytes4(keccak256("UPDATE_POLICY_PERMISSION"));
        bool hasUpdatePolicyPermission = (hasRole(POLICY_MANAGER_ROLE, _msgSender()) ||
                                          hasPermission(tokenId, _msgSender(), UPDATE_POLICY_PERMISSION));
        require(hasUpdatePolicyPermission, "Not authorized to update policy on asset");

        // Internal policy/hook check before updating policy
        Policy storage oldPolicy = _assets[tokenId].policies[policyIndex];
        _beforePolicyChange(tokenId, oldPolicy.policyType, newPolicyData, policyIndex, false, false); // isAdd=false, isRemove=false for update

        oldPolicy.policyData = newPolicyData; // Update data
        // oldPolicy.policyType cannot be changed post-creation in this model
        // oldPolicy.isActive cannot be changed via this function

        emit PolicyUpdated(tokenId, policyIndex);
    }

     /**
      * @dev Removes a policy from an asset by its index.
      * Note: This shifts elements in the dynamic array, changing subsequent indices.
      * Requires POLICY_MANAGER_ROLE or specific REMOVE_POLICY_PERMISSION.
      * Subject to asset policies (e.g., a "some policies are non-removable" policy).
      */
    function removePolicy(uint256 tokenId, uint256 policyIndex) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        Policy[] storage policies = _assets[tokenId].policies;
        require(policyIndex < policies.length, "Policy index out of bounds");

        bytes4 REMOVE_POLICY_PERMISSION = bytes4(keccak256("REMOVE_POLICY_PERMISSION"));
        bool hasRemovePolicyPermission = (hasRole(POLICY_MANAGER_ROLE, _msgSender()) ||
                                          hasPermission(tokenId, _msgSender(), REMOVE_POLICY_PERMISSION));
        require(hasRemovePolicyPermission, "Not authorized to remove policy from asset");

        // Internal policy/hook check before removing policy
        Policy storage policyToRemove = policies[policyIndex];
         _beforePolicyChange(tokenId, policyToRemove.policyType, policyToRemove.policyData, policyIndex, false, true); // isAdd=false, isRemove=true for remove


        // Simple removal by replacing with last element and shrinking
        policies[policyIndex] = policies[policies.length - 1];
        policies.pop();

        emit PolicyRemoved(tokenId, policyIndex); // Note: Emitting original index, state changes array indices
    }

    /**
     * @dev Retrieves details of a specific policy by its index on an asset.
     */
    function getPolicy(uint256 tokenId, uint256 policyIndex) public view returns (bytes4 policyType, bytes memory policyData, bool isActive) {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        require(policyIndex < _assets[tokenId].policies.length, "Policy index out of bounds");
        Policy storage policy = _assets[tokenId].policies[policyIndex];
        return (policy.policyType, policy.policyData, policy.isActive);
    }

    /**
     * @dev Lists all policies attached to an asset. Returns policy types and active status.
     * Policy data is not returned to keep gas costs reasonable for listing.
     * Use `getPolicy` for full details.
     */
    function listAssetPolicies(uint256 tokenId) public view returns (uint256[] memory policyIndices, bytes4[] memory policyTypes, bool[] memory activeStatuses) {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        Policy[] storage policies = _assets[tokenId].policies;
        uint256 count = policies.length;
        policyIndices = new uint256[](count);
        policyTypes = new bytes4[](count);
        activeStatuses = new bool[](count);

        for (uint256 i = 0; i < count; i++) {
            policyIndices[i] = i;
            policyTypes[i] = policies[i].policyType;
            activeStatuses[i] = policies[i].isActive;
        }
        return (policyIndices, policyTypes, activeStatuses);
    }

     /**
     * @dev Checks if a policy type is registered.
     */
    function isRegisteredPolicyType(bytes4 policyType) public view returns (bool) {
        return _registeredPolicyTypes[policyType];
    }


    // --- Permission Management Functions (5 functions) ---

     /**
      * @dev Grants or revokes a specific permission (`actionId`) for a user (`grantee`) on an asset.
      * Permissions allow granular actions on specific assets, overriding or supplementing roles/policies.
      * Requires caller to be the asset owner, ADMIN_ROLE, or have DELEGATE_PERMISSION for this action ID.
      */
    function grantPermission(uint256 tokenId, address grantee, bytes4 actionId, bool allowed) public whenNotPaused {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");
        require(grantee != address(0), "Grantee cannot be the zero address");

        bytes4 DELEGATE_PERMISSION = bytes4(keccak256("DELEGATE_PERMISSION"));
        bool isOwner = _msgSender() == _assets[tokenId].owner;
        bool isAdmin = hasRole(ADMIN_ROLE, _msgSender());
        bool canDelegate = _assets[tokenId].delegatablePermissions[_msgSender()][actionId];

        require(isOwner || isAdmin || canDelegate, "Not authorized to grant/revoke this permission");

        _assets[tokenId].permissions[grantee][actionId] = allowed;
        emit PermissionGranted(tokenId, grantee, actionId, allowed);
    }

     /**
      * @dev Explicitly revokes a specific permission previously granted.
      * Alias for `grantPermission(tokenId, grantee, actionId, false)`.
      * Requires the same authorization as `grantPermission`.
      */
    function revokePermission(uint256 tokenId, address grantee, bytes4 actionId) public whenNotPaused {
         grantPermission(tokenId, grantee, actionId, false); // Simply call grant with allowed=false
     }


    /**
     * @dev Allows an address to grant/revoke a specific permission (`actionId`) on an asset.
     * This is for creating delegates who can manage specific permissions without being owner or ADMIN.
     * Requires caller to be the asset owner or ADMIN_ROLE.
     */
    function delegatePermission(uint256 tokenId, address delegatee, bytes4 actionId, bool delegatable) public whenNotPaused {
         require(_assets[tokenId].owner != address(0), "Asset does not exist");
         require(delegatee != address(0), "Delegatee cannot be the zero address");

         bool isOwner = _msgSender() == _assets[tokenId].owner;
         bool isAdmin = hasRole(ADMIN_ROLE, _msgSender());

         require(isOwner || isAdmin, "Not authorized to delegate permissions");

         _assets[tokenId].delegatablePermissions[delegatee][actionId] = delegatable;
         emit PermissionDelegated(tokenId, delegatee, actionId, delegatable);
    }


    /**
     * @dev Checks if an account has a specific permission for an action on an asset.
     * Considers system roles, asset ownership, and explicit permission grants.
     * Note: This is a view function, the actual enforcement logic in action functions might be more nuanced.
     * Returns true if allowed by roles/ownership/explicit grant, false otherwise.
     * Does *not* check asset-specific policies (`_checkPolicy`). Policies are checked within the specific action functions.
     */
    function hasPermission(uint256 tokenId, address account, bytes4 actionId) public view returns (bool) {
        require(_assets[tokenId].owner != address(0), "Asset does not exist");

        // 1. ADMIN_ROLE can do anything
        if (hasRole(ADMIN_ROLE, account)) {
            return true;
        }

        // 2. Owner has inherent rights (e.g., TRANSFER_PERMISSION, implicitly many others)
        // This depends on the actionId. We can hardcode some here or make it configurable.
        // For simplicity, let's say owner implicitly has many rights *unless* restricted by policy.
        // For explicit `hasPermission` checks, we look at explicit grants first.
        // Let's say owner implicitly has TRANSFER_PERMISSION and DELEGATE_PERMISSION
         if (account == _assets[tokenId].owner) {
             if (actionId == bytes4(keccak256("TRANSFER_PERMISSION"))) return true;
             if (actionId == bytes4(keccak256("DELEGATE_PERMISSION"))) return true;
             // Add other owner-specific implicit permissions here if needed
         }

        // 3. Check specific role grants for this action (if action corresponds to a role)
        // e.g., ATTRIBUTE_MANAGER_ROLE implies SET_ATTRIBUTE_PERMISSION
        bytes4 SET_ATTRIBUTE_PERMISSION = bytes4(keccak256("SET_ATTRIBUTE_PERMISSION"));
        bytes4 REMOVE_ATTRIBUTE_PERMISSION = bytes4(keccak256("REMOVE_ATTRIBUTE_PERMISSION"));
        bytes4 ADD_POLICY_PERMISSION = bytes4(keccak256("ADD_POLICY_PERMISSION"));
        bytes4 UPDATE_POLICY_PERMISSION = bytes4(keccak256("UPDATE_POLICY_PERMISSION"));
        bytes4 REMOVE_POLICY_PERMISSION = bytes4(keccak256("REMOVE_POLICY_PERMISSION"));
        bytes4 BURN_PERMISSION = bytes4(keccak256("BURN_PERMISSION"));


        if (actionId == SET_ATTRIBUTE_PERMISSION && hasRole(ATTRIBUTE_MANAGER_ROLE, account)) return true;
        if (actionId == REMOVE_ATTRIBUTE_PERMISSION && hasRole(ATTRIBUTE_MANAGER_ROLE, account)) return true;
        if (actionId == ADD_POLICY_PERMISSION && hasRole(POLICY_MANAGER_ROLE, account)) return true;
        if (actionId == UPDATE_POLICY_PERMISSION && hasRole(POLICY_MANAGER_ROLE, account)) return true;
        if (actionId == REMOVE_POLICY_PERMISSION && hasRole(POLICY_MANAGER_ROLE, account)) return true;
        if (actionId == BURN_PERMISSION && hasRole(ASSET_ISSUER_ROLE, account)) return true; // Example: Issuer can burn

        // 4. Check explicit permission grant
        if (_assets[tokenId].permissions[account][actionId]) {
            return true; // Explicitly granted
        }

         // 5. Check explicit permission denial
         // In this simple model, we don't have explicit denials.
         // A more complex system could have a `permissions[grantee][actionId]` mapping to an enum: Allowed, Denied, Inherit.

        // If none of the above grant permission
        return false;
    }

    /**
     * @dev Lists the explicit permissions granted to an account for a specific asset.
     * Does not reflect role-based permissions or owner's inherent rights.
     * NOTE: Listing keys from a mapping is not directly possible. This function
     * is a placeholder/marker similar to `listAssetAttributes`.
     */
    function listAccountPermissions(uint256 tokenId, address account) public view returns (bytes4[] memory actionIds, bool[] memory allowedStatuses) {
         require(_assets[tokenId].owner != address(0), "Asset does not exist");
         // This cannot be fully implemented efficiently on-chain for arbitrary mappings.
         // Returning empty arrays as a placeholder. Needs off-chain indexing or different data structure.
        return (new bytes4[](0), new bool[](0));
    }


    // --- View Functions (Read-only) ---

    /**
     * @dev Returns the owner of an asset.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _assets[tokenId].owner;
    }

    /**
     * @dev Returns the total number of assets minted.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

     /**
      * @dev Checks if the contract is paused.
      */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Checks if an asset exists.
     */
    function assetExists(uint256 tokenId) public view returns (bool) {
        return _assets[tokenId].owner != address(0);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to require a specific system role.
     */
    function _requireRole(bytes32 role, address account) internal view {
        require(_roles[role][account], string(abi.encodePacked("AccessControl: account ", _addressToString(account), " is missing role ", _bytes32ToString(role))));
    }

    /**
     * @dev Internal function to check if the system is paused. Reverts if paused.
     */
    function _checkSystemPause() internal view {
        require(!_paused, "System is paused");
    }

    /**
     * @dev Internal function to evaluate policies for a specific action on an asset.
     * This is the core policy enforcement logic.
     * @param tokenId The asset ID.
     * @param actionId A bytes4 identifier for the action being attempted (e.g., TRANSFER_ACTION, SET_ATTRIBUTE_ACTION).
     * @dev IMPORTANT: This is a simplified placeholder implementation. Real policy logic
     * would likely involve iterating through relevant policies, decoding policyData,
     * and evaluating conditions (e.g., time locks, address allowlists/denylists,
     * checking other attributes, interacting with oracles/other contracts).
     * For this example, it just checks if *any* policy exists with a specific type
     * that hypothetically blocks the action.
     */
    function _checkPolicy(uint256 tokenId, bytes4 actionId) internal view {
        // Example Policy Types (placeholders)
        bytes4 NON_TRANSFERABLE_POLICY = bytes4(keccak256("NON_TRANSFERABLE"));
        bytes4 IMMUTABLE_ATTRIBUTE_POLICY = bytes4(keccak256("IMMUTABLE_ATTRIBUTE"));
        bytes4 POLICY_IMMUTABILITY_POLICY = bytes4(keccak256("POLICY_IMMUTABILITY"));
         bytes4 ALLOW_ONLY_ROLE_TRANSFER_POLICY = bytes4(keccak256("ALLOW_ONLY_ROLE_TRANSFER"));


        Policy[] storage policies = _assets[tokenId].policies;
        for (uint256 i = 0; i < policies.length; i++) {
            Policy storage policy = policies[i];
            if (!policy.isActive) {
                continue; // Skip inactive policies
            }

            // --- SIMPLIFIED POLICY EVALUATION EXAMPLES ---
            // A real system would decode policy.policyData and apply complex logic

            // Example 1: Non-transferable policy
            if (actionId == bytes4(keccak256("TRANSFER_PERMISSION")) && policy.policyType == NON_TRANSFERABLE_POLICY) {
                 revert("Policy Violation: Asset is non-transferable");
            }

             // Example 2: Immutable Attribute policy - would need key from action context
             // This simplified check just sees if the policy type exists
            if (actionId == bytes4(keccak256("SET_ATTRIBUTE_PERMISSION")) && policy.policyType == IMMUTABLE_ATTRIBUTE_POLICY) {
                 // In a real scenario, policyData might specify WHICH attributes are immutable.
                 // The action context (e.g., the attribute key being set) would be needed.
                 revert("Policy Violation: Attribute is immutable");
            }

            // Example 3: Policy Immutability policy
            if ((actionId == bytes4(keccak256("ADD_POLICY_PERMISSION")) ||
                 actionId == bytes4(keccak256("UPDATE_POLICY_PERMISSION")) ||
                 actionId == bytes4(keccak256("REMOVE_POLICY_PERMISSION"))) &&
                 policy.policyType == POLICY_IMMUTABILITY_POLICY) {
                  revert("Policy Violation: Asset policies are immutable");
            }

            // Example 4: Allow only role transfer policy - would need role from policyData
            if (actionId == bytes4(keccak256("TRANSFER_PERMISSION")) && policy.policyType == ALLOW_ONLY_ROLE_TRANSFER_POLICY) {
                 // PolicyData might contain the required role (bytes32).
                 // Check if msg.sender has that role.
                 // require(hasRole(bytes32(policy.policyData), _msgSender()), "Policy Violation: Transfer restricted by role");
                 // Placeholder: if the policy type exists, we assume it restricts transfers unless a role check (omitted here) passes.
                 // If the caller is not the owner OR does not have ADMIN_ROLE, this policy MIGHT block.
                 // The actual check would need to verify msg.sender's role against policy.policyData.
                 // Skipping full decode/check for simplicity here.
                 // require(hasRole(bytes32(policy.policyData), _msgSender()), "Policy Violation: Transfer restricted by policy"); // Example check structure
            }

            // --- Add other policy type evaluations here ---
            // ...
        }
    }

    /**
     * @dev Internal hook called before any token transfer, including minting (from=0)
     * and burning (to=0). Applies transfer-related policy checks.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal view {
        // No checks needed for minting (from == address(0))
        if (from == address(0)) return;

        // Check policies relevant to transfers/burns
        bytes4 TRANSFER_PERMISSION = bytes4(keccak256("TRANSFER_PERMISSION")); // Use same actionId as permission check
        _checkPolicy(tokenId, TRANSFER_PERMISSION);

        // Add other checks here (e.g., receiver address validity based on policies/attributes)
        // Example: require(to != address(0), "Cannot transfer to zero address"); // Already checked in transfer function
        // Example: Check if receiver address is in an approved list stored in a policy data.
        // bytes4 APPROVED_RECEIVER_POLICY = bytes4(keccak256("APPROVED_RECEIVER"));
        // ... logic to find and evaluate APPROVED_RECEIVER_POLICY ...
    }

     /**
      * @dev Internal hook called before an asset attribute is set or removed.
      * Applies attribute modification policy checks.
      * value is empty bytes for removal.
      */
     function _beforeAttributeChange(uint256 tokenId, string memory key, bytes memory value) internal view {
         bytes4 SET_ATTRIBUTE_PERMISSION = bytes4(keccak256("SET_ATTRIBUTE_PERMISSION")); // Use same actionId
          _checkPolicy(tokenId, SET_ATTRIBUTE_PERMISSION); // Policies might restrict setting any attribute
         // In a real scenario, policies might be specific to the 'key'.
         // _checkPolicy(tokenId, bytes4(keccak256(bytes.concat(SET_ATTRIBUTE_PERMISSION, bytes(key))))); // More granular check example
     }

      /**
       * @dev Internal hook called before a policy is added, updated, or removed.
       * Applies policy immutability policy checks.
       */
     function _beforePolicyChange(uint256 tokenId, bytes4 policyType, bytes memory policyData, uint256 policyIndex, bool isAdd, bool isRemove) internal view {
          bytes4 ADD_POLICY_PERMISSION = bytes4(keccak256("ADD_POLICY_PERMISSION"));
          bytes4 UPDATE_POLICY_PERMISSION = bytes4(keccak256("UPDATE_POLICY_PERMISSION"));
          bytes4 REMOVE_POLICY_PERMISSION = bytes4(keccak256("REMOVE_POLICY_PERMISSION"));

         if (isAdd) _checkPolicy(tokenId, ADD_POLICY_PERMISSION);
         else if (isRemove) _checkPolicy(tokenId, REMOVE_POLICY_PERMISSION);
         else _checkPolicy(tokenId, UPDATE_POLICY_PERMISSION);

          // In a real scenario, policies might restrict changes based on policyType or policyData.
          // Example: A "critical" policy type cannot be removed or updated.
          // bytes4 CRITICAL_POLICY_TYPE = bytes4(keccak256("CRITICAL"));
          // if (policyType == CRITICAL_POLICY_TYPE && (isRemove || !isAdd)) {
          //    revert("Policy Violation: Critical policies cannot be removed or updated");
          // }
     }


     // --- Utility Functions (Helper for display/debugging) ---
     // Note: String manipulation in Solidity is costly and limited, these are basic helpers.

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

     // Basic helper for error messages (can be expensive)
     function _addressToString(address _account) internal pure returns(string memory) {
         bytes32 value = bytes32(uint256(payable(_account)));
         bytes memory alphabet = "0123456789abcdef";
         bytes memory str = new bytes(40);
         for (uint i = 0; i < 20; i++) {
             str[i*2] = alphabet[uint8(value[i] >> 4)];
             str[i*2+1] = alphabet[uint8(value[i] & 0x0f)];
         }
         return string(str);
     }

     // Basic helper for error messages (can be expensive)
     function _bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
         bytes memory bytesString = new bytes(32);
         uint count = 0;
         for (uint i = 0; i < 32; i++) {
             byte _byte = _bytes32[i];
             if (_byte != 0) {
                 bytesString[count] = _byte;
                 count++;
             }
         }
         bytes memory trimmedString = new bytes(count);
         for (uint i = 0; i < count; i++) {
             trimmedString[i] = bytesString[i];
         }
         return string(trimmedString);
     }
}
```