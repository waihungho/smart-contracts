Okay, let's design a complex, non-standard smart contract incorporating multiple advanced concepts. We'll create a "MultiDimensional Asset Registry" that manages unique assets with customizable, dynamic properties ("dimensions"), nested relationships (assets can own other assets), granular asset-specific permissions, state transitions, and potentially time-bound attributes.

This contract goes beyond standard ERC-721 by allowing dynamic, non-fixed properties per asset, defining relationships between assets, and implementing a flexible permission system at the asset level.

---

**Contract Name:** `MultiDimensionalAssetRegistry`

**Overview:**
This contract acts as a registry for unique, non-fungible assets. Unlike simple NFTs, assets managed here can have multiple named properties ("dimensions") with dynamic values, can be composed of other assets from the registry (forming hierarchical structures), support asset-specific permissioning for granular control over modifications and relationships, and can exist in defined states with controlled transitions.

**Core Concepts:**
1.  **Multi-Dimensional Assets:** Assets are identified by a unique ID but have a dynamic set of named "dimensions", each storing a value. These dimensions can represent anything from metadata attributes to game stats, configuration parameters, or physical properties.
2.  **Recursive Composability:** Assets can own other assets, creating parent-child relationships and potentially complex trees or graphs (though cyclic relationships are prevented or undefined behavior). Transferring a parent can recursively transfer children.
3.  **Granular Asset-Specific Permissions:** Users (addresses) can be granted specific permissions (defined by `bytes32` keys, e.g., `CAN_EDIT_DIMENSION`, `CAN_ADD_CHILD`, `CAN_CHANGE_STATE`) on individual assets, allowing fine-grained access control beyond simple ownership.
4.  **Asset States:** Assets can have a defined "state" (represented by `bytes32`), which can be changed based on permissions, potentially enabling state-dependent logic off-chain or in integrated contracts.
5.  **Time-Bound Attributes (Illustrative):** Dimensions *could* be designed to expire, adding a time-sensitive dynamic element (implemented here via expiry timestamps).

**Data Structures:**
*   `_owners`: Maps `assetId` to `owner address`.
*   `_nextAssetId`: Counter for unique asset IDs.
*   `_assetDimensions`: Maps `assetId` to `dimensionName (bytes32)` to `dimensionValue (bytes)`. Stores the actual dimension data.
*   `_assetDimensionKeys`: Maps `assetId` to an array of `dimensionName (bytes32)`. Helps retrieve all dimension keys for an asset.
*   `_assetChildren`: Maps `parentAssetId` to a mapping of `childAssetId` to `bool`. Represents the parent-child relationship.
*   `_assetParent`: Maps `childAssetId` to `parentAssetId`. Represents the inverse parent-child relationship (0 for root assets).
*   `_assetPermissions`: Maps `assetId` to `address` to `permissionName (bytes32)` to `bool`. Stores which address has which permission on which asset.
*   `_assetStates`: Maps `assetId` to `stateName (bytes32)`. Stores the current state of an asset.
*   `_dimensionExpiries`: Maps `assetId` to `dimensionName (bytes32)` to `expiryTimestamp (uint64)`. Stores expiry times for dimensions.
*   `_totalAssets`: Count of *all* created assets (including nested ones).
*   `_rootAssetsByOwner`: Maps `owner address` to a mapping of `rootAssetId` to `bool`. Tracks root assets owned by an address.

**Key Functions (>= 20 total):**

1.  `createAsset`: Creates a new root asset.
2.  `transferAsset`: Transfers a root asset and recursively its children.
3.  `burnAsset`: Burns a root asset and recursively its children.
4.  `ownerOf`: Gets the owner of an asset.
5.  `exists`: Checks if an asset ID exists.
6.  `setDimensionValue`: Sets or updates a dimension's value for an asset (requires permission).
7.  `getDimensionValue`: Retrieves a dimension's value.
8.  `removeDimension`: Removes a dimension from an asset (requires permission).
9.  `getDimensions`: Gets all dimension keys for an asset.
10. `addChildAsset`: Adds an existing asset as a child to another (requires permissions on both parent and child).
11. `removeChildAsset`: Removes a child asset, making it a new root asset (requires permission).
12. `isChildOf`: Checks if an asset is a child of another.
13. `getChildrenOf`: Gets a list of direct children of an asset.
14. `getParentOf`: Gets the parent of an asset (0 if root).
15. `grantPermission`: Grants a specific permission on an asset to an address (requires permission to manage permissions).
16. `revokePermission`: Revokes a specific permission on an asset from an address (requires permission to manage permissions).
17. `hasPermission`: Checks if an address has a specific permission on an asset.
18. `setAssetState`: Sets the state of an asset (requires permission).
19. `getAssetState`: Gets the state of an asset.
20. `setDimensionValueWithExpiry`: Sets a dimension value with an associated expiry timestamp (requires permission).
21. `getDimensionExpiry`: Gets the expiry timestamp for a dimension.
22. `isDimensionExpired`: Checks if a dimension's value has expired.
23. `getTotalAssets`: Gets the total count of assets created.
24. `getRootAssetsOf`: Gets a list of root assets owned by an address.
25. `pauseRegistry`: Pauses core registry operations (admin function).
26. `unpauseRegistry`: Unpauses the registry (admin function).
27. `transferOwnership`: Transfers contract admin ownership (admin function).

**Events:**
*   `AssetCreated`
*   `Transfer` (Mimics ERC-721, for root assets)
*   `AssetBurned`
*   `DimensionValueSet`
*   `DimensionRemoved`
*   `ChildAdded`
*   `ChildRemoved`
*   `PermissionGranted`
*   `PermissionRevoked`
*   `AssetStateChanged`
*   `DimensionExpirySet`

**Errors:**
*   `AssetDoesNotExist`
*   `NotAssetOwner`
*   `PermissionDenied`
*   `ZeroAddress`
*   `AssetAlreadyRoot`
*   `AssetAlreadyChild`
*   `CannotAddSelfAsChild`
*   `NotAParentOf`
*   `AssetIsNotRoot`
*   `DimensionDoesNotExist`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// Custom Errors
error AssetDoesNotExist(uint256 assetId);
error NotAssetOwner(uint256 assetId, address caller);
error PermissionDenied(uint256 assetId, address account, bytes32 permission);
error ZeroAddress();
error AssetAlreadyRoot(uint256 assetId);
error AssetAlreadyChild(uint256 assetId, uint256 parentId);
error CannotAddSelfAsChild(uint256 assetId);
error NotAParentOf(uint256 parentId, uint256 childId);
error AssetIsNotRoot(uint256 assetId);
error DimensionDoesNotExist(uint256 assetId, bytes32 dimensionName);

contract MultiDimensionalAssetRegistry is Ownable, Pausable, IERC165 {

    // --- State Variables ---

    mapping(uint256 => address) internal _owners;
    uint256 private _nextAssetId = 1;
    uint256 private _totalAssets = 0; // Includes root and child assets

    // Asset Dimensions: assetId -> dimensionName -> dimensionValue
    mapping(uint256 => mapping(bytes32 => bytes)) internal _assetDimensions;
    // Keep track of dimension keys for enumeration: assetId -> list of dimensionNames
    mapping(uint256 => bytes32[]) internal _assetDimensionKeys;
    // Track index for quick removal from _assetDimensionKeys
    mapping(uint256 => mapping(bytes32 => uint256)) internal _assetDimensionKeyIndex;

    // Asset Composability: parentId -> childId -> isChild
    mapping(uint256 => mapping(uint256 => bool)) internal _assetChildren;
    // Track children IDs for enumeration: parentId -> list of childIds
    mapping(uint256 => uint256[]) internal _assetChildrenList;
    // Track index for quick removal from _assetChildrenList
    mapping(uint256 => mapping(uint256 => uint256)) internal _assetChildIndex;
    // Asset Parent: childId -> parentId (0 for root assets)
    mapping(uint256 => uint256) internal _assetParent;

    // Granular Asset Permissions: assetId -> account -> permissionName -> hasPermission
    mapping(uint256 => mapping(address => mapping(bytes32 => bool))) internal _assetPermissions;

    // Asset State: assetId -> stateName
    mapping(uint256 => bytes32) internal _assetStates;

    // Time-Bound Dimensions: assetId -> dimensionName -> expiryTimestamp (uint64)
    mapping(uint256 => mapping(bytes32 => uint64)) internal _dimensionExpiries;

    // Keep track of root assets per owner for easier lookup (root assets have parentId 0)
    mapping(address => mapping(uint256 => bool)) internal _rootAssetsByOwner;
    mapping(address => uint256[]) internal _rootAssetListByOwner;
    mapping(address => mapping(uint256 => uint256)) internal _rootAssetIndexByOwner;

    // --- Permission Definitions (using bytes32 constants) ---
    // These are example permissions, contract logic checks for these keys
    bytes32 public constant CAN_EDIT_DIMENSION = "CAN_EDIT_DIMENSION"; // Allows setting/removing dimensions
    bytes32 public constant CAN_ADD_CHILD = "CAN_ADD_CHILD"; // Allows adding a child to this asset (parent side)
    bytes32 public constant CAN_BECOME_CHILD = "CAN_BECOME_CHILD"; // Allows this asset to be added as a child (child side)
    bytes32 public constant CAN_REMOVE_CHILD = "CAN_REMOVE_CHILD"; // Allows removing a child from this asset (parent side)
    bytes32 public constant CAN_TRANSFER_ASSET = "CAN_TRANSFER_ASSET"; // Allows transferring this specific asset (only applicable to root assets)
    bytes32 public constant CAN_BURN_ASSET = "CAN_BURN_ASSET"; // Allows burning this specific asset (only applicable to root assets)
    bytes32 public constant CAN_CHANGE_STATE = "CAN_CHANGE_STATE"; // Allows changing the asset's state
    bytes32 public constant CAN_MANAGE_PERMISSIONS = "CAN_MANAGE_PERMISSIONS"; // Allows granting/revoking other permissions on this asset

    // --- Events ---

    /// @dev Emitted when a new asset is created.
    event AssetCreated(uint256 indexed assetId, address indexed owner, uint256 parentId);

    /// @dev Emitted when ownership of a root asset changes.
    /// @dev Note: This event is only for the top-level transfer, recursive transfers of children
    /// @dev are implied but not explicitly emitted via this event for every child to save gas.
    event Transfer(address indexed from, address indexed to, uint256 indexed assetId);

    /// @dev Emitted when an asset is burned.
    /// @dev Note: This is only for the top-level burn, recursive burns of children
    /// @dev are implied but not explicitly emitted via this event for every child to save gas.
    event AssetBurned(uint256 indexed assetId, address indexed owner, uint256 parentId);

    /// @dev Emitted when a dimension's value is set or updated.
    event DimensionValueSet(uint256 indexed assetId, bytes32 indexed dimensionName, bytes value);

    /// @dev Emitted when a dimension is removed.
    event DimensionRemoved(uint256 indexed assetId, bytes32 indexed dimensionName);

    /// @dev Emitted when an asset is added as a child to another.
    event ChildAdded(uint256 indexed parentId, uint256 indexed childId);

    /// @dev Emitted when a child asset is removed from its parent.
    event ChildRemoved(uint256 indexed parentId, uint256 indexed childId);

    /// @dev Emitted when a permission is granted for an asset.
    event PermissionGranted(uint256 indexed assetId, address indexed account, bytes32 permission);

    /// @dev Emitted when a permission is revoked for an asset.
    event PermissionRevoked(uint256 indexed assetId, address indexed account, bytes32 permission);

    /// @dev Emitted when an asset's state changes.
    event AssetStateChanged(uint256 indexed assetId, bytes32 oldState, bytes32 newState);

    /// @dev Emitted when a dimension value is set with an expiry time.
    event DimensionExpirySet(uint256 indexed assetId, bytes32 indexed dimensionName, uint64 expiryTimestamp);

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) Pausable(false) {}

    // --- IERC165 Support ---

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        // This contract doesn't implement a standard like ERC721 fully due to its complexity,
        // but we can still signal support for ERC165 itself.
        // Add other interfaces supported if applicable (e.g., a custom interface for this registry).
        return interfaceId == type(IERC165).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Access Control Helpers ---

    /// @dev Internal function to check if an asset exists.
    function _exists(uint256 assetId) internal view returns (bool) {
        return _owners[assetId] != address(0);
    }

    /// @dev Requires that an asset with `assetId` exists.
    modifier assetExists(uint256 assetId) {
        if (!_exists(assetId)) revert AssetDoesNotExist(assetId);
        _;
    }

    /// @dev Requires that `account` is the owner of `assetId`.
    modifier onlyAssetOwner(uint256 assetId) {
        if (_owners[assetId] != msg.sender) revert NotAssetOwner(assetId, msg.sender);
        _;
    }

    /// @dev Internal function to check if an account has a specific permission on an asset.
    /// @param account The address to check permissions for.
    /// @param assetId The asset ID.
    /// @param permission The permission name (bytes32).
    /// @return True if the account has the permission, false otherwise. Note: Owner implicitly has all permissions unless explicitly revoked?
    /// @dev For simplicity, in this implementation, the owner always has all permissions (unless explicitly revoked, which this contract doesn't support yet).
    /// @dev A more complex version might require the owner to explicitly grant permissions to themselves for certain actions.
    /// @dev Let's simplify: Owner *is* checked against the permission mapping like any other address.
    function _checkPermission(address account, uint256 assetId, bytes32 permission) internal view returns (bool) {
        return _assetPermissions[assetId][account][permission];
    }

    /// @dev Requires that the calling account has a specific permission on an asset.
    modifier hasPermission(uint256 assetId, bytes32 permission) {
        if (!_checkPermission(msg.sender, assetId, permission)) revert PermissionDenied(assetId, msg.sender, permission);
        _;
    }

    // --- Core Registry Functions ---

    /// @summary Creates a new root asset and assigns ownership.
    /// @param owner The address that will own the new asset.
    /// @return The ID of the newly created asset.
    function createAsset(address owner) external onlyOwner whenNotPaused returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();

        uint256 newAssetId = _nextAssetId++;
        _owners[newAssetId] = owner;
        _assetParent[newAssetId] = 0; // 0 indicates a root asset
        _totalAssets++;

        // Track as root asset for the owner
        _rootAssetsByOwner[owner][newAssetId] = true;
        _rootAssetListByOwner[owner].push(newAssetId);
        _rootAssetIndexByOwner[owner][newAssetId] = _rootAssetListByOwner[owner].length - 1;

        // Grant initial permissions to the owner
        _assetPermissions[newAssetId][owner][CAN_EDIT_DIMENSION] = true;
        _assetPermissions[newAssetId][owner][CAN_ADD_CHILD] = true;
        _assetPermissions[newAssetId][owner][CAN_BECOME_CHILD] = true; // Can be added as a child by others if owner allows
        _assetPermissions[newAssetId][owner][CAN_REMOVE_CHILD] = true;
        _assetPermissions[newAssetId][owner][CAN_TRANSFER_ASSET] = true;
        _assetPermissions[newAssetId][owner][CAN_BURN_ASSET] = true;
        _assetPermissions[newAssetId][owner][CAN_CHANGE_STATE] = true;
        _assetPermissions[newAssetId][owner][CAN_MANAGE_PERMISSIONS] = true; // Owner can manage permissions by default

        emit AssetCreated(newAssetId, owner, 0); // ParentId 0 for root

        return newAssetId;
    }

    /// @summary Transfers a root asset and its entire child tree to a new owner.
    /// @dev Only root assets can be transferred directly. Transferring a child requires removing it first.
    /// @param to The address to transfer the asset to.
    /// @param assetId The ID of the root asset to transfer.
    function transferAsset(address to, uint256 assetId) external whenNotPaused assetExists(assetId) {
        if (to == address(0)) revert ZeroAddress();
        if (_assetParent[assetId] != 0) revert AssetIsNotRoot(assetId); // Only root assets transferable via this function

        // Check if caller is the owner OR has the CAN_TRANSFER_ASSET permission
        if (_owners[assetId] != msg.sender && !_checkPermission(msg.sender, assetId, CAN_TRANSFER_ASSET)) {
             revert PermissionDenied(assetId, msg.sender, CAN_TRANSFER_ASSET);
        }

        address from = _owners[assetId];
        if (from == to) return; // No-op

        // Perform recursive transfer
        _transferRecursive(assetId, from, to);

        emit Transfer(from, to, assetId);
    }

    /// @dev Internal recursive function to transfer an asset and its children.
    /// @param assetId The asset ID to transfer.
    /// @param from The current owner.
    /// @param to The new owner.
    function _transferRecursive(uint256 assetId, address from, address to) internal {
        require(_exists(assetId), "Asset does not exist during recursive transfer"); // Should not happen if called correctly

        _owners[assetId] = to;

        // Update root asset tracking ONLY IF this is a root asset
        if (_assetParent[assetId] == 0) {
            // Remove from old owner's root list
            delete _rootAssetsByOwner[from][assetId];
            uint256 lastIndex = _rootAssetListByOwner[from].length - 1;
            uint256 assetIndex = _rootAssetIndexByOwner[from][assetId];
            if (assetIndex != lastIndex) {
                uint256 lastAssetId = _rootAssetListByOwner[from][lastIndex];
                _rootAssetListByOwner[from][assetIndex] = lastAssetId;
                _rootAssetIndexByOwner[from][lastAssetId] = assetIndex;
            }
            _rootAssetListByOwner[from].pop();
            delete _rootAssetIndexByOwner[from][assetId];

            // Add to new owner's root list
            _rootAssetsByOwner[to][assetId] = true;
            _rootAssetListByOwner[to].push(assetId);
            _rootAssetIndexByOwner[to][assetId] = _rootAssetListByOwner[to].length - 1;
        }
        // Note: If it's a child asset, its parent doesn't change, only its owner does.

        // Recursively transfer children
        uint256[] memory children = _assetChildrenList[assetId];
        for (uint i = 0; i < children.length; i++) {
            _transferRecursive(children[i], from, to);
        }
    }


    /// @summary Burns a root asset and recursively burns its children.
    /// @dev Only root assets can be burned directly. Burning a child requires removing it first.
    /// @param assetId The ID of the root asset to burn.
    function burnAsset(uint256 assetId) external whenNotPaused assetExists(assetId) {
         if (_assetParent[assetId] != 0) revert AssetIsNotRoot(assetId); // Only root assets burnable via this function

        // Check if caller is the owner OR has the CAN_BURN_ASSET permission
        if (_owners[assetId] != msg.sender && !_checkPermission(msg.sender, assetId, CAN_BURN_ASSET)) {
             revert PermissionDenied(assetId, msg.sender, CAN_BURN_ASSET);
        }

        address owner = _owners[assetId];

        // Perform recursive burn
        _burnRecursive(assetId);

        emit AssetBurned(assetId, owner, 0); // ParentId 0 for root
    }

    /// @dev Internal recursive function to burn an asset and its children.
    /// @param assetId The asset ID to burn.
    function _burnRecursive(uint256 assetId) internal {
        require(_exists(assetId), "Asset does not exist during recursive burn"); // Should not happen

        address owner = _owners[assetId];
        uint256 parentId = _assetParent[assetId];

        // Recursively burn children first
        uint256[] memory children = _assetChildrenList[assetId];
        // Iterate backwards because we'll be modifying _assetChildrenList in recursive calls
        for (int i = int(children.length) - 1; i >= 0; i--) {
             _burnRecursive(children[uint(i)]);
        }

        // Clean up this asset's data
        delete _owners[assetId];
        delete _assetParent[assetId];
        delete _assetDimensions[assetId];
        delete _assetDimensionKeys[assetId];
        delete _assetDimensionKeyIndex[assetId];
        delete _assetChildren[assetId]; // Should already be empty after burning children
        delete _assetChildrenList[assetId]; // Should already be empty
        delete _assetChildIndex[assetId]; // Should already be empty
        delete _assetPermissions[assetId];
        delete _assetStates[assetId];
        delete _dimensionExpiries[assetId];

        _totalAssets--;

        // Remove from root asset tracking ONLY IF it was a root asset
        if (parentId == 0) {
            delete _rootAssetsByOwner[owner][assetId];
            uint256 lastIndex = _rootAssetListByOwner[owner].length - 1;
            uint256 assetIndex = _rootAssetIndexByOwner[owner][assetId];
             if (assetIndex != lastIndex) {
                uint256 lastAssetId = _rootAssetListByOwner[owner][lastIndex];
                _rootAssetListByOwner[owner][assetIndex] = lastAssetId;
                _rootAssetIndexByOwner[owner][lastAssetId] = assetIndex;
            }
            _rootAssetListByOwner[owner].pop();
            delete _rootAssetIndexByOwner[owner][assetId];
        }
        // Note: If it was a child, it would have been removed from parent's child list
        // before calling burnAsset on the root, or during the parent's _burnRecursive.
        // The recursive burning order ensures parent clean up happens after children are processed.
    }


    /// @summary Gets the owner of a specific asset.
    /// @param assetId The ID of the asset.
    /// @return The address of the asset's owner.
    function ownerOf(uint256 assetId) public view assetExists(assetId) returns (address) {
        return _owners[assetId];
    }

    /// @summary Checks if a specific asset ID exists in the registry.
    /// @param assetId The ID of the asset.
    /// @return True if the asset exists, false otherwise.
    function exists(uint256 assetId) public view returns (bool) {
        return _exists(assetId);
    }

    // --- Dimension Management Functions ---

    /// @summary Sets or updates a dimension's value for an asset.
    /// @dev Requires the caller to have the CAN_EDIT_DIMENSION permission for the asset.
    /// @param assetId The ID of the asset.
    /// @param dimensionName The name of the dimension (bytes32).
    /// @param value The value of the dimension (bytes). Can encode any data type.
    function setDimensionValue(uint256 assetId, bytes32 dimensionName, bytes calldata value)
        external
        whenNotPaused
        assetExists(assetId)
        hasPermission(assetId, CAN_EDIT_DIMENSION)
    {
        // Check if dimension key already exists to manage the list
        bool keyExists = _assetDimensions[assetId][dimensionName].length > 0;

        _assetDimensions[assetId][dimensionName] = value;

        if (!keyExists) {
             _assetDimensionKeyIndex[assetId][dimensionName] = _assetDimensionKeys[assetId].length;
            _assetDimensionKeys[assetId].push(dimensionName);
        }

        emit DimensionValueSet(assetId, dimensionName, value);
    }

    /// @summary Gets the value of a specific dimension for an asset.
    /// @param assetId The ID of the asset.
    /// @param dimensionName The name of the dimension (bytes32).
    /// @return The value of the dimension (bytes). Returns empty bytes if dimension doesn't exist.
    function getDimensionValue(uint256 assetId, bytes32 dimensionName) public view assetExists(assetId) returns (bytes memory) {
        return _assetDimensions[assetId][dimensionName];
    }

     /// @summary Removes a dimension from an asset.
    /// @dev Requires the caller to have the CAN_EDIT_DIMENSION permission for the asset.
    /// @param assetId The ID of the asset.
    /// @param dimensionName The name of the dimension (bytes32).
    function removeDimension(uint256 assetId, bytes32 dimensionName)
        external
        whenNotPaused
        assetExists(assetId)
        hasPermission(assetId, CAN_EDIT_DIMENSION)
    {
         if (_assetDimensions[assetId][dimensionName].length == 0) revert DimensionDoesNotExist(assetId, dimensionName);

        delete _assetDimensions[assetId][dimensionName];
        delete _dimensionExpiries[assetId][dimensionName]; // Also remove expiry if set

        // Remove from dimension keys list
        uint256 index = _assetDimensionKeyIndex[assetId][dimensionName];
        uint256 lastIndex = _assetDimensionKeys[assetId].length - 1;
        if (index != lastIndex) {
            bytes32 lastDimensionName = _assetDimensionKeys[assetId][lastIndex];
            _assetDimensionKeys[assetId][index] = lastDimensionName;
            _assetDimensionKeyIndex[assetId][lastDimensionName] = index;
        }
        _assetDimensionKeys[assetId].pop();
        delete _assetDimensionKeyIndex[assetId][dimensionName];

        emit DimensionRemoved(assetId, dimensionName);
    }

    /// @summary Gets all dimension names (keys) for a specific asset.
    /// @param assetId The ID of the asset.
    /// @return An array of bytes32 representing the dimension names.
    function getDimensions(uint256 assetId) public view assetExists(assetId) returns (bytes32[] memory) {
        return _assetDimensionKeys[assetId];
    }

    // --- Composability Functions ---

    /// @summary Adds an existing asset as a child to another asset.
    /// @dev Requires CAN_ADD_CHILD permission on the parent and CAN_BECOME_CHILD permission on the child.
    /// @dev The child must not already be a child or parent of the parent.
    /// @param parentId The ID of the asset to become the parent.
    /// @param childId The ID of the asset to become the child.
    function addChildAsset(uint256 parentId, uint256 childId)
        external
        whenNotPaused
        assetExists(parentId)
        assetExists(childId)
        hasPermission(parentId, CAN_ADD_CHILD)
        hasPermission(childId, CAN_BECOME_CHILD)
    {
        if (parentId == childId) revert CannotAddSelfAsChild(parentId);
        if (_assetParent[childId] != 0) revert AssetAlreadyChild(childId, _assetParent[childId]);
        if (_assetChildren[childId][parentId]) revert NotAParentOf(childId, parentId); // Prevent simple A->B and B->A cycles at depth 1

        address childOwner = _owners[childId];
        address parentOwner = _owners[parentId];

        // Transfer child ownership to parent owner (standard for nested NFTs)
        // If child owner requires explicit transfer permission, that should be checked off-chain
        // or via a separate approval mechanism before calling this function.
        // Here we assume CAN_BECOME_CHILD permission implies consent to ownership transfer.
        if (childOwner != parentOwner) {
             // Update ownership
             _owners[childId] = parentOwner;

            // Remove child from its old owner's root list
            delete _rootAssetsByOwner[childOwner][childId];
            uint256 lastIndex = _rootAssetListByOwner[childOwner].length - 1;
            uint256 assetIndex = _rootAssetIndexByOwner[childOwner][childId];
            if (assetIndex != lastIndex) {
                uint256 lastAssetId = _rootAssetListByOwner[childOwner][lastIndex];
                _rootAssetListByOwner[childOwner][assetIndex] = lastAssetId;
                _rootAssetIndexByOwner[childOwner][lastAssetId] = assetIndex;
            }
            _rootAssetListByOwner[childOwner].pop();
            delete _rootAssetIndexByOwner[childOwner][childId];
            // No need to add to parent owner's root list as it's now a child
        }


        _assetChildren[parentId][childId] = true;
        _assetParent[childId] = parentId;

        // Add child to parent's children list
        _assetChildIndex[parentId][childId] = _assetChildrenList[parentId].length;
        _assetChildrenList[parentId].push(childId);

        emit ChildAdded(parentId, childId);
    }

    /// @summary Removes a child asset from its parent, making the child a new root asset.
    /// @dev Requires CAN_REMOVE_CHILD permission on the parent. The caller becomes the owner of the now-root child.
    /// @param childId The ID of the child asset to remove.
    function removeChildAsset(uint256 childId)
        external
        whenNotPaused
        assetExists(childId)
    {
        uint256 parentId = _assetParent[childId];
        if (parentId == 0) revert AssetAlreadyRoot(childId); // Cannot remove if already root

        // Check permission on the PARENT asset
        if (!_checkPermission(msg.sender, parentId, CAN_REMOVE_CHILD)) {
             revert PermissionDenied(parentId, msg.sender, CAN_REMOVE_CHILD);
        }

        address oldParentOwner = _owners[parentId]; // The owner of the parent (who granted CAN_REMOVE_CHILD)
        address childOwner = _owners[childId]; // Should be the same as oldParentOwner if added via addChildAsset

        // Ensure the caller has rights to take ownership of the child.
        // Here, we assume having CAN_REMOVE_CHILD on the parent implicitly grants this,
        // and the caller becomes the new owner of the detached asset.
        // A more complex implementation might require a separate permission on the child,
        // or the child owner to be the caller. Let's assume caller takes ownership.
        address newOwner = msg.sender;
        if (newOwner == address(0)) revert ZeroAddress();

        // Update parent-child mappings
        delete _assetChildren[parentId][childId];

        // Remove child from parent's children list
        uint256 index = _assetChildIndex[parentId][childId];
        uint256 lastIndex = _assetChildrenList[parentId].length - 1;
        if (index != lastIndex) {
            uint256 lastChildId = _assetChildrenList[parentId][lastIndex];
            _assetChildrenList[parentId][index] = lastChildId;
            _assetChildIndex[parentId][lastChildId] = index;
        }
        _assetChildrenList[parentId].pop();
        delete _assetChildIndex[parentId][childId];

        _assetParent[childId] = 0; // Make it a root asset

        // Transfer ownership of the now-root child to the caller
        if (childOwner != newOwner) {
             _owners[childId] = newOwner;
        }

        // Add child to new owner's root list
        _rootAssetsByOwner[newOwner][childId] = true;
        _rootAssetListByOwner[newOwner].push(childId);
        _rootAssetIndexByOwner[newOwner][childId] = _rootAssetListByOwner[newOwner].length - 1;

        emit ChildRemoved(parentId, childId);
        if (childOwner != newOwner) {
             // Emit a Transfer event for the child now that it's a root asset
             emit Transfer(childOwner, newOwner, childId);
        }
    }

    /// @summary Checks if a potential child asset is a direct child of a potential parent asset.
    /// @param parentId The potential parent asset ID.
    /// @param childId The potential child asset ID.
    /// @return True if `childId` is a direct child of `parentId`, false otherwise.
    function isChildOf(uint256 parentId, uint256 childId) public view returns (bool) {
        return _assetChildren[parentId][childId];
    }

    /// @summary Gets the list of direct child asset IDs for a given parent asset.
    /// @param parentId The ID of the parent asset.
    /// @return An array of child asset IDs.
    function getChildrenOf(uint256 parentId) public view assetExists(parentId) returns (uint256[] memory) {
        return _assetChildrenList[parentId];
    }

    /// @summary Gets the parent asset ID for a given child asset.
    /// @param childId The ID of the child asset.
    /// @return The parent asset ID, or 0 if the asset is a root asset.
    function getParentOf(uint256 childId) public view assetExists(childId) returns (uint256) {
        return _assetParent[childId];
    }

    // --- Permission Management Functions ---

    /// @summary Grants a specific permission on an asset to an address.
    /// @dev Requires the caller to have the CAN_MANAGE_PERMISSIONS permission for the asset.
    /// @param assetId The ID of the asset.
    /// @param account The address to grant the permission to.
    /// @param permission The permission name (bytes32).
    function grantPermission(uint256 assetId, address account, bytes32 permission)
        external
        whenNotPaused
        assetExists(assetId)
        hasPermission(assetId, CAN_MANAGE_PERMISSIONS)
    {
        if (account == address(0)) revert ZeroAddress();
        _assetPermissions[assetId][account][permission] = true;
        emit PermissionGranted(assetId, account, permission);
    }

    /// @summary Revokes a specific permission on an asset from an address.
    /// @dev Requires the caller to have the CAN_MANAGE_PERMISSIONS permission for the asset.
    /// @param assetId The ID of the asset.
    /// @param account The address to revoke the permission from.
    /// @param permission The permission name (bytes32).
    function revokePermission(uint256 assetId, address account, bytes32 permission)
        external
        whenNotPaused
        assetExists(assetId)
        hasPermission(assetId, CAN_MANAGE_PERMISSIONS)
    {
        if (account == address(0)) revert ZeroAddress();
        _assetPermissions[assetId][account][permission] = false;
        emit PermissionRevoked(assetId, account, permission);
    }

    /// @summary Checks if an address has a specific permission on an asset.
    /// @param assetId The ID of the asset.
    /// @param account The address to check.
    /// @param permission The permission name (bytes32).
    /// @return True if the account has the permission, false otherwise.
    function hasPermission(uint256 assetId, address account, bytes32 permission)
        public
        view
        assetExists(assetId)
        returns (bool)
    {
        if (account == address(0)) revert ZeroAddress(); // Cannot check permission for zero address
        return _checkPermission(account, assetId, permission);
    }

    // --- State Management Functions ---

    /// @summary Sets the state of an asset.
    /// @dev Requires the caller to have the CAN_CHANGE_STATE permission for the asset.
    /// @param assetId The ID of the asset.
    /// @param newState The new state name (bytes32).
    function setAssetState(uint256 assetId, bytes32 newState)
        external
        whenNotPaused
        assetExists(assetId)
        hasPermission(assetId, CAN_CHANGE_STATE)
    {
        bytes32 oldState = _assetStates[assetId];
        if (oldState != newState) {
            _assetStates[assetId] = newState;
            emit AssetStateChanged(assetId, oldState, newState);
        }
    }

    /// @summary Gets the current state of an asset.
    /// @param assetId The ID of the asset.
    /// @return The current state name (bytes32). Returns empty bytes32 if state has never been set.
    function getAssetState(uint256 assetId) public view assetExists(assetId) returns (bytes32) {
        return _assetStates[assetId];
    }

    // --- Time-Bound Dimension Functions ---

    /// @summary Sets a dimension value with an associated expiry timestamp.
    /// @dev Requires the caller to have the CAN_EDIT_DIMENSION permission for the asset.
    /// @param assetId The ID of the asset.
    /// @param dimensionName The name of the dimension (bytes32).
    /// @param value The value of the dimension (bytes).
    /// @param expiryTimestamp The Unix timestamp when the dimension value expires.
    function setDimensionValueWithExpiry(uint256 assetId, bytes32 dimensionName, bytes calldata value, uint64 expiryTimestamp)
        external
        whenNotPaused
        assetExists(assetId)
        hasPermission(assetId, CAN_EDIT_DIMENSION)
    {
        // Check if dimension key already exists to manage the list
        bool keyExists = _assetDimensions[assetId][dimensionName].length > 0;

        _assetDimensions[assetId][dimensionName] = value;
        _dimensionExpiries[assetId][dimensionName] = expiryTimestamp;

         if (!keyExists) {
             _assetDimensionKeyIndex[assetId][dimensionName] = _assetDimensionKeys[assetId].length;
            _assetDimensionKeys[assetId].push(dimensionName);
        }

        emit DimensionValueSet(assetId, dimensionName, value);
        emit DimensionExpirySet(assetId, dimensionName, expiryTimestamp);
    }

    /// @summary Gets the expiry timestamp for a specific dimension.
    /// @param assetId The ID of the asset.
    /// @param dimensionName The name of the dimension (bytes32).
    /// @return The Unix timestamp of expiry, or 0 if no expiry is set.
    function getDimensionExpiry(uint256 assetId, bytes32 dimensionName) public view assetExists(assetId) returns (uint64) {
        return _dimensionExpiries[assetId][dimensionName];
    }

    /// @summary Checks if a dimension's value has expired.
    /// @param assetId The ID of the asset.
    /// @param dimensionName The name of the dimension (bytes32).
    /// @return True if the dimension exists, has an expiry set, and the current time is past the expiry, false otherwise.
    function isDimensionExpired(uint256 assetId, bytes32 dimensionName) public view returns (bool) {
        // No need for assetExists here, function works fine returning false for non-existent assets/dimensions
        uint64 expiry = _dimensionExpiries[assetId][dimensionName];
        // Dimension exists and has expiry set if expiry > 0
        // Check if current block timestamp is greater than expiry
        return expiry > 0 && block.timestamp >= expiry;
    }

    // --- Query Functions ---

    /// @summary Gets the total number of assets created in the registry (including nested).
    /// @return The total asset count.
    function getTotalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    /// @summary Gets the list of root assets owned by a specific address.
    /// @param owner The address whose root assets to retrieve.
    /// @return An array of root asset IDs owned by the address.
    function getRootAssetsOf(address owner) public view returns (uint256[] memory) {
        return _rootAssetListByOwner[owner];
    }

    // --- Pausable Functions ---

    /// @summary Pauses the contract, preventing core operations.
    function pauseRegistry() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @summary Unpauses the contract, allowing core operations.
    function unpauseRegistry() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Ownable Functions (from inherited Ownable) ---
    // transferOwnership is inherited
}
```

**Explanation of Advanced Concepts and Implementation Choices:**

1.  **Multi-Dimensional Assets:**
    *   Implemented using `mapping(uint256 => mapping(bytes32 => bytes)) _assetDimensions`. `bytes32` as key is gas-efficient for fixed-size names compared to `string`. `bytes` allows storing various data types (integers, strings, boolean flags, etc.) by encoding them before storing and decoding after retrieving.
    *   `_assetDimensionKeys` and `_assetDimensionKeyIndex` mappings are added to allow iterating over the dimension names for a given asset, which is not directly possible with just the nested mapping. This adds complexity but provides necessary off-chain usability.
    *   Permissions (`CAN_EDIT_DIMENSION`) are checked before modifying dimensions.

2.  **Recursive Composability:**
    *   Implemented using `_assetChildren`, `_assetChildrenList`, `_assetChildIndex`, and `_assetParent` mappings.
    *   `addChildAsset` and `removeChildAsset` manage these relationships. `addChildAsset` transfers ownership of the child to the parent's owner, which is a common pattern for nested NFTs to maintain a single owner for a composite structure.
    *   `transferAsset` and `burnAsset` are recursive, transferring or burning the entire subtree. This is handled by internal `_transferRecursive` and `_burnRecursive` functions.
    *   Basic cycle prevention (`CannotAddSelfAsChild`, check against direct parent) is included, but preventing arbitrary complex cycles (A->B->C->A) is computationally expensive and not fully implemented, often left to off-chain logic or assumed constraint.

3.  **Granular Asset-Specific Permissions:**
    *   Implemented using `mapping(uint256 => mapping(address => mapping(bytes32 => bool))) _assetPermissions`. This allows specifying permissions like `CAN_EDIT_DIMENSION` *for asset 123* *for address X*.
    *   `bytes32` constants are used for permission names.
    *   `grantPermission` and `revokePermission` allow an address with `CAN_MANAGE_PERMISSIONS` on an asset to control who has other permissions on that specific asset.
    *   The `hasPermission` modifier enforces these checks before executing sensitive functions like `setDimensionValue`, `addChildAsset`, `setAssetState`, etc.

4.  **Asset States:**
    *   Implemented simply with `mapping(uint256 => bytes32) _assetStates`. `bytes32` allows flexible state names.
    *   `setAssetState` requires the `CAN_CHANGE_STATE` permission.

5.  **Time-Bound Attributes:**
    *   Implemented with `mapping(uint256 => mapping(bytes32 => uint64)) _dimensionExpiries`. Stores a Unix timestamp per dimension.
    *   `setDimensionValueWithExpiry` allows setting an expiry time.
    *   `isDimensionExpired` allows checking against `block.timestamp`. This enables off-chain systems or other contracts to interpret dimensions as expired even if the value is still stored. The contract *doesn't* automatically clear expired dimensions to save gas, but relies on `isDimensionExpired` for checks.

6.  **Tracking Root Assets:**
    *   `_rootAssetsByOwner`, `_rootAssetListByOwner`, `_rootAssetIndexByOwner` are added to efficiently retrieve only the top-level assets owned by an address, which is useful for wallets/UIs displaying owned items. Managing these lists on modifications (create, transfer, removeChildAsset) adds complexity but is necessary for this query function.

**Limitations and Considerations:**

*   **Gas Costs:** Complex operations like recursive transfer/burn can be expensive, especially for deep or wide asset trees. Iterating over lists of dimensions or children also has gas costs proportional to the list size.
*   **Storage Costs:** Storing all dimensions, permissions, and relationships on-chain is storage-intensive.
*   **Security:** The permission system is flexible but complex. Any bug in the `_checkPermission` logic or in how permissions are granted/revoked could have significant consequences. The owner initially gets all permissions, which might be too broad depending on the use case.
*   **Scalability:** Large numbers of assets, dimensions per asset, or deep/wide trees could hit block gas limits or become prohibitively expensive to query or modify.
*   **Off-chain Interpretation:** The `bytes` data for dimensions and `bytes32` keys for dimensions, permissions, and states require off-chain systems to interpret their meaning and structure.
*   **Cycle Prevention:** Only basic cycle prevention is included. Full cycle detection during `addChildAsset` is complex and gas-intensive.

This contract demonstrates how Solidity can be used to build a registry for rich, interconnected, and dynamically controlled digital assets, moving beyond the simpler models of ERC-20 or standard ERC-721. It provides a framework for sophisticated asset management scenarios like complex games, supply chain tracking, digital twins, or tokenized rights where assets have varying properties and relationships.