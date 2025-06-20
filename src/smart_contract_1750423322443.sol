Okay, here is a smart contract designed to be a sophisticated Metaverse Asset Registry. It focuses on registering, managing metadata for multiple environments, linking, and tracking the state of digital assets, regardless of whether they are originally on-chain (like an ERC721) or referenced from off-chain sources or other chains.

It incorporates concepts like:

1.  **Flexible Asset Identification:** Using `bytes32` for the primary asset ID allows for hashes, URIs, or other identifiers.
2.  **Multi-Environment Metadata:** Storing different metadata URIs/hashes tagged for specific metaverse environments (`bytes32` tags for efficiency).
3.  **Asset Linking/Composability:** Allowing assets to be linked together to represent bundles, components, or relationships.
4.  **Asset State Management:** Tracking the lifecycle state of the asset record within the registry (e.g., registered, locked, archived).
5.  **Flexible Origin:** Recording where the asset originally comes from (chain, contract, token ID, or off-chain reference).
6.  **Reputation/Score:** A simple integer score associated with the asset record (could be updated by trusted oracles/processes off-chain and recorded here).
7.  **Batch Operations:** Functions for registering and updating multiple assets or metadata entries in one transaction.
8.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` for fine-grained permissions.
9.  **Indexed Lookups:** Maintaining a mapping to quickly find assets owned by a specific address within the registry.
10. **Metadata Locking:** Ability to lock metadata changes for an asset.

This contract does NOT handle the transfer or ownership of ERC721/ERC1155 tokens themselves. It acts as a *registry* or *metadata layer* *for* those assets (or off-chain assets), providing additional context and features within a metaverse ecosystem.

---

## Contract Outline:

1.  **SPDX-License-Identifier & Pragmas**
2.  **Imports:** OpenZeppelin AccessControl.
3.  **Errors:** Custom errors for clarity.
4.  **Enums:** `AssetRegistryState`.
5.  **Structs:** `AssetOrigin`, `Asset`.
6.  **Constants:** Role definitions (`DEFAULT_ADMIN_ROLE`, `REGISTRAR_ROLE`, `METADATA_MANAGER_ROLE`, `STATE_MANAGER_ROLE`, `REPUTATION_MANAGER_ROLE`).
7.  **State Variables:**
    *   `assets`: Mapping from `bytes32` asset ID to `Asset` struct.
    *   `assetExists`: Mapping to quickly check if an asset ID is registered.
    *   `ownerAssets`: Mapping from owner address to array of owned asset IDs (for indexing).
8.  **Events:**
    *   `AssetRegistered`
    *   `AssetOwnerUpdated`
    *   `AssetMetadataAdded`
    *   `AssetMetadataUpdated`
    *   `AssetMetadataRemoved`
    *   `AssetStateUpdated`
    *   `AssetLinked`
    *   `AssetUnlinked`
    *   `AssetMetadataLocked`
    *   `AssetMetadataUnlocked`
    *   `AssetBurned`
    *   `AssetReputationScoreUpdated`
9.  **Helper Functions (Internal/Private):**
    *   `_addAssetToOwnerIndex`: Adds asset ID to `ownerAssets` array.
    *   `_removeAssetFromOwnerIndex`: Removes asset ID from `ownerAssets` array (swap and pop).
    *   `_getAsset`: Internal helper to retrieve asset struct and check existence.
10. **Constructor:** Sets up AccessControl roles.
11. **Core Functionality (State Changing):**
    *   `registerAsset`
    *   `registerBatch`
    *   `deregisterAsset`
    *   `transferAssetOwnershipInRegistry`
    *   `addMetadata`
    *   `updateMetadata`
    *   `removeMetadata`
    *   `updateMetadataBatch`
    *   `updateAssetState`
    *   `applyStateToBatch`
    *   `linkAsset`
    *   `unlinkAsset`
    *   `lockAssetMetadata`
    *   `unlockAssetMetadata`
    *   `burnAssetRegistryEntry`
    *   `setAssetReputationScore`
12. **View Functions (Read Only):**
    *   `assetExistsQuery`
    *   `getAssetInfo`
    *   `getAssetOwner`
    *   `getAssetOrigin`
    *   `getAssetState`
    *   `getMetadata`
    *   `getAllMetadataTags`
    *   `getLinkedAssets`
    *   `isAssetLinkedTo`
    *   `getAssetRegistrationTime`
    *   `getAssetReputationScore`
    *   `getAssetsByOwner`
    *   `getAssetsCountByOwner`
13. **AccessControl Functions (Inherited):**
    *   `grantRole`
    *   `revokeRole`
    *   `renounceRole`
    *   `hasRole`
    *   `getRoleAdmin`

## Function Summary:

1.  `constructor()`: Initializes the contract, grants the deployer the default admin role.
2.  `registerAsset(bytes32 assetId, address owner, AssetOrigin calldata origin, bytes32[] calldata metadataTags, string[] calldata metadataURIs)`: Registers a new asset in the registry with initial owner, origin info, and multiple metadata entries. Requires `REGISTRAR_ROLE`.
3.  `registerBatch(bytes32[] calldata assetIds, address[] calldata owners, AssetOrigin[] calldata origins, bytes32[][] calldata metadataTagsBatch, string[][] calldata metadataURIsBatch)`: Registers multiple assets in a single transaction. Requires `REGISTRAR_ROLE`.
4.  `deregisterAsset(bytes32 assetId)`: Removes an asset entry from the registry entirely. Requires `REGISTRAR_ROLE`.
5.  `transferAssetOwnershipInRegistry(bytes32 assetId, address newOwner)`: Updates the owner address recorded in the registry for an asset. Requires `REGISTRAR_ROLE`. This does not affect actual token ownership if it's an on-chain asset.
6.  `addMetadata(bytes32 assetId, bytes32 metadataTag, string calldata metadataURI)`: Adds a new metadata entry for a specific tag to an existing asset. Requires `METADATA_MANAGER_ROLE` and asset not metadata-locked.
7.  `updateMetadata(bytes32 assetId, bytes32 metadataTag, string calldata newMetadataURI)`: Updates an existing metadata entry for a specific tag on an asset. Requires `METADATA_MANAGER_ROLE` and asset not metadata-locked.
8.  `removeMetadata(bytes32 assetId, bytes32 metadataTag)`: Removes a metadata entry for a specific tag from an asset. Requires `METADATA_MANAGER_ROLE` and asset not metadata-locked.
9.  `updateMetadataBatch(bytes32 assetId, bytes32[] calldata metadataTags, string[] calldata metadataURIs)`: Adds or updates multiple metadata entries on a single asset. Requires `METADATA_MANAGER_ROLE` and asset not metadata-locked.
10. `updateAssetState(bytes32 assetId, AssetRegistryState newState)`: Changes the state of an asset record (e.g., to Locked, Archived). Requires `STATE_MANAGER_ROLE`.
11. `applyStateToBatch(bytes32[] calldata assetIds, AssetRegistryState newState)`: Applies a state change to multiple assets. Requires `STATE_MANAGER_ROLE`.
12. `linkAsset(bytes32 assetId, bytes32 linkedAssetId)`: Creates a directional link from one asset to another within the registry. Requires `METADATA_MANAGER_ROLE`.
13. `unlinkAsset(bytes32 assetId, bytes32 linkedAssetId)`: Removes a specific directional link between assets. Requires `METADATA_MANAGER_ROLE`.
14. `lockAssetMetadata(bytes32 assetId)`: Prevents further additions, updates, or removals of metadata for an asset. Requires `METADATA_MANAGER_ROLE`.
15. `unlockAssetMetadata(bytes32 assetId)`: Allows metadata changes again for an asset. Requires `METADATA_MANAGER_ROLE`.
16. `burnAssetRegistryEntry(bytes32 assetId)`: Marks an asset entry as 'Burned' in the registry. It is not deleted but state is changed. Requires `STATE_MANAGER_ROLE`.
17. `setAssetReputationScore(bytes32 assetId, int256 score)`: Sets or updates the reputation score for an asset record. Requires `REPUTATION_MANAGER_ROLE`.
18. `assetExistsQuery(bytes32 assetId)`: Checks if an asset ID is currently registered.
19. `getAssetInfo(bytes32 assetId)`: Retrieves the full `Asset` struct details for a given asset ID.
20. `getAssetOwner(bytes32 assetId)`: Retrieves the owner address recorded for an asset.
21. `getAssetOrigin(bytes32 assetId)`: Retrieves the origin information for an asset.
22. `getAssetState(bytes32 assetId)`: Retrieves the current state of an asset record.
23. `getMetadata(bytes32 assetId, bytes32 metadataTag)`: Retrieves the metadata URI for a specific tag on an asset.
24. `getAllMetadataTags(bytes32 assetId)`: Retrieves an array of all metadata tags associated with an asset.
25. `getLinkedAssets(bytes32 assetId)`: Retrieves an array of asset IDs linked from the given asset.
26. `isAssetLinkedTo(bytes32 assetId, bytes32 possibleLinkedAssetId)`: Checks if an asset is linked directly to another specific asset.
27. `getAssetRegistrationTime(bytes32 assetId)`: Retrieves the registration timestamp for an asset.
28. `getAssetReputationScore(bytes32 assetId)`: Retrieves the current reputation score for an asset.
29. `getAssetsByOwner(address owner)`: Retrieves an array of all asset IDs registered to a specific owner address. (Note: this can be gas-intensive for owners with many assets).
30. `getAssetsCountByOwner(address owner)`: Retrieves the count of assets registered to a specific owner address.
31. `grantRole(bytes32 role, address account)`: Grants a role to an account (from `AccessControl`).
32. `revokeRole(bytes32 role, address account)`: Revokes a role from an account (from `AccessControl`).
33. `renounceRole(bytes32 role, address account)`: An account can remove its own role (from `AccessControl`).
34. `hasRole(bytes32 role, address account)`: Checks if an account has a specific role (from `AccessControl`).
35. `getRoleAdmin(bytes32 role)`: Gets the admin role for a given role (from `AccessControl`).

Total functions: 35

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

/// @title MetaverseAssetRegistry
/// @author YourName (or pseudonymous)
/// @notice A sophisticated registry for managing metadata, state, and relationships of digital assets within a metaverse ecosystem.
/// It supports tracking assets from various origins (on-chain or off-chain) and allows for multi-environment metadata, linking, and reputation scoring.

/// @dev Outline:
/// - SPDX-License-Identifier & Pragmas
/// - Imports: OpenZeppelin AccessControl, Arrays
/// - Errors
/// - Enums: AssetRegistryState
/// - Structs: AssetOrigin, Asset
/// - Constants: Role definitions
/// - State Variables: assets mapping, assetExists mapping, ownerAssets mapping
/// - Events
/// - Helper Functions (Internal/Private)
/// - Constructor
/// - Core Functionality (State Changing)
/// - View Functions (Read Only)
/// - AccessControl Functions (Inherited)

/// @dev Function Summary:
/// 1. constructor(): Initializes the contract, grants admin role.
/// 2. registerAsset(bytes32 assetId, address owner, AssetOrigin calldata origin, bytes32[] calldata metadataTags, string[] calldata metadataURIs): Registers a single new asset.
/// 3. registerBatch(bytes32[] calldata assetIds, address[] calldata owners, AssetOrigin[] calldata origins, bytes32[][] calldata metadataTagsBatch, string[][] calldata metadataURIsBatch): Registers multiple assets.
/// 4. deregisterAsset(bytes32 assetId): Removes an asset entry.
/// 5. transferAssetOwnershipInRegistry(bytes32 assetId, address newOwner): Updates registry owner.
/// 6. addMetadata(bytes32 assetId, bytes32 metadataTag, string calldata metadataURI): Adds a new metadata entry for a tag.
/// 7. updateMetadata(bytes32 assetId, bytes32 metadataTag, string calldata newMetadataURI): Updates metadata for a tag.
/// 8. removeMetadata(bytes32 assetId, bytes32 metadataTag): Removes metadata for a tag.
/// 9. updateMetadataBatch(bytes32 assetId, bytes32[] calldata metadataTags, string[] calldata metadataURIs): Adds/updates multiple metadata entries on one asset.
/// 10. updateAssetState(bytes32 assetId, AssetRegistryState newState): Changes asset state.
/// 11. applyStateToBatch(bytes32[] calldata assetIds, AssetRegistryState newState): Changes state for multiple assets.
/// 12. linkAsset(bytes32 assetId, bytes32 linkedAssetId): Creates a link between assets.
/// 13. unlinkAsset(bytes32 assetId, bytes32 linkedAssetId): Removes a link.
/// 14. lockAssetMetadata(bytes32 assetId): Prevents metadata changes.
/// 15. unlockAssetMetadata(bytes32 assetId): Allows metadata changes.
/// 16. burnAssetRegistryEntry(bytes32 assetId): Marks asset entry as burned.
/// 17. setAssetReputationScore(bytes32 assetId, int256 score): Sets asset reputation.
/// 18. assetExistsQuery(bytes32 assetId): Checks if asset exists.
/// 19. getAssetInfo(bytes32 assetId): Gets full asset struct.
/// 20. getAssetOwner(bytes32 assetId): Gets asset owner.
/// 21. getAssetOrigin(bytes32 assetId): Gets asset origin.
/// 22. getAssetState(bytes32 assetId): Gets asset state.
/// 23. getMetadata(bytes32 assetId, bytes32 metadataTag): Gets metadata for a tag.
/// 24. getAllMetadataTags(bytes32 assetId): Gets all metadata tags for asset.
/// 25. getLinkedAssets(bytes32 assetId): Gets linked assets.
/// 26. isAssetLinkedTo(bytes32 assetId, bytes32 possibleLinkedAssetId): Checks if linked.
/// 27. getAssetRegistrationTime(bytes32 assetId): Gets registration time.
/// 28. getAssetReputationScore(bytes32 assetId): Gets reputation score.
/// 29. getAssetsByOwner(address owner): Gets all asset IDs for an owner (potentially gas-heavy).
/// 30. getAssetsCountByOwner(address owner): Gets count of assets for an owner.
/// 31. grantRole(bytes32 role, address account): Grants a role.
/// 32. revokeRole(bytes32 role, address account): Revokes a role.
/// 33. renounceRole(bytes32 role, address account): Renounces a role.
/// 34. hasRole(bytes32 role, address account): Checks if account has role.
/// 35. getRoleAdmin(bytes32 role): Gets role admin.

contract MetaverseAssetRegistry is AccessControl {

    // --- Errors ---

    error AssetAlreadyRegistered(bytes32 assetId);
    error AssetNotRegistered(bytes32 assetId);
    error InvalidMetadataInput();
    error MetadataTagNotFound(bytes32 assetId, bytes32 metadataTag);
    error AssetMetadataLocked(bytes32 assetId);
    error CannotLinkToSelf(bytes32 assetId);
    error AssetAlreadyLinked(bytes32 assetId, bytes32 linkedAssetId);
    error AssetNotLinked(bytes32 assetId, bytes32 linkedAssetId);
    error CannotDeregisterActiveAsset(bytes32 assetId);
    error BatchInputMismatch();

    // --- Enums ---

    /// @dev Represents the state of the asset record within the registry.
    enum AssetRegistryState {
        Registered,       // Initially registered
        Active,           // Actively in use in a metaverse (optional intermediate state)
        Locked,           // Temporarily locked (e.g., during a transfer or event)
        Archived,         // No longer actively used but kept for history
        Burned            // Explicitly marked as burned/destroyed within the registry
    }

    // --- Structs ---

    /// @dev Defines the origin of the asset.
    struct AssetOrigin {
        uint256 chainId;          // Chain ID where the asset originates (0 for off-chain/abstract)
        address contractAddress;  // Contract address if on-chain (address(0) if not applicable)
        uint256 tokenId;          // Token ID if on-chain (0 if not applicable)
        string offChainReference; // Reference string for off-chain assets (e.g., URL, UUID)
    }

    /// @dev Represents an asset record in the registry.
    struct Asset {
        bytes32 assetId;                               // Unique identifier for the asset
        address owner;                                 // Current owner registered in this contract
        AssetOrigin origin;                            // Details about the asset's origin
        AssetRegistryState state;                      // Current state in the registry
        uint64 registrationTime;                       // Block timestamp when registered
        mapping(bytes32 => string) metadata;           // Metadata URI/hash mapped by environment tag
        bytes32[] linkedAssets;                        // Array of asset IDs linked from this asset
        bool metadataLocked;                           // If true, metadata cannot be added/updated/removed
        int256 reputationScore;                       // A customizable score (e.g., quality, usage, trust)
    }

    // --- Constants ---

    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR");
    bytes32 public constant METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER");
    bytes32 public constant STATE_MANAGER_ROLE = keccak256("STATE_MANAGER");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER");

    // --- State Variables ---

    mapping(bytes32 => Asset) private assets;
    mapping(bytes32 => bool) private assetExists;
    mapping(address => bytes32[]) private ownerAssets; // Index for efficient lookup by owner

    // --- Events ---

    event AssetRegistered(bytes32 indexed assetId, address indexed owner, AssetOrigin origin, uint64 registrationTime);
    event AssetOwnerUpdated(bytes32 indexed assetId, address indexed oldOwner, address indexed newOwner);
    event AssetMetadataAdded(bytes32 indexed assetId, bytes32 indexed metadataTag, string metadataURI);
    event AssetMetadataUpdated(bytes32 indexed assetId, bytes32 indexed metadataTag, string oldMetadataURI, string newMetadataURI);
    event AssetMetadataRemoved(bytes32 indexed assetId, bytes32 indexed metadataTag, string removedMetadataURI);
    event AssetStateUpdated(bytes32 indexed assetId, AssetRegistryState oldState, AssetRegistryState newState);
    event AssetLinked(bytes32 indexed assetId, bytes32 indexed linkedAssetId);
    event AssetUnlinked(bytes32 indexed assetId, bytes32 indexed unlinkedAssetId);
    event AssetMetadataLocked(bytes32 indexed assetId);
    event AssetMetadataUnlocked(bytes32 indexed assetId);
    event AssetBurned(bytes32 indexed assetId);
    event AssetReputationScoreUpdated(bytes32 indexed assetId, int256 oldScore, int256 newScore);

    // --- Helper Functions (Internal/Private) ---

    /// @dev Internal function to get an asset struct and check if it exists.
    function _getAsset(bytes32 assetId) private view returns (Asset storage asset) {
        if (!assetExists[assetId]) {
            revert AssetNotRegistered(assetId);
        }
        return assets[assetId];
    }

    /// @dev Adds an asset ID to the owner's index.
    function _addAssetToOwnerIndex(address owner, bytes32 assetId) private {
        ownerAssets[owner].push(assetId);
    }

    /// @dev Removes an asset ID from the owner's index using swap-and-pop.
    /// @notice This changes the order of elements in the owner's array, which is acceptable for an index.
    function _removeAssetFromOwnerIndex(address owner, bytes32 assetId) private {
        bytes32[] storage assetsList = ownerAssets[owner];
        for (uint256 i = 0; i < assetsList.length; i++) {
            if (assetsList[i] == assetId) {
                // Swap with the last element
                if (i != assetsList.length - 1) {
                    assetsList[i] = assetsList[assetsList.length - 1];
                }
                // Remove the last element
                assetsList.pop();
                return;
            }
        }
        // Should not happen if logic is correct, but good practice
        // revert("Asset not found in owner index");
    }

    // --- Constructor ---

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender); // Grant initial roles to deployer
        _grantRole(METADATA_MANAGER_ROLE, msg.sender);
        _grantRole(STATE_MANAGER_ROLE, msg.sender);
        _grantRole(REPUTATION_MANAGER_ROLE, msg.sender);
    }

    // --- Core Functionality (State Changing) ---

    /// @notice Registers a new asset in the registry.
    /// @param assetId The unique identifier for the asset.
    /// @param owner The initial owner of the asset in this registry.
    /// @param origin Details about the asset's origin.
    /// @param metadataTags Array of metadata tags (bytes32).
    /// @param metadataURIs Array of corresponding metadata URIs (string).
    function registerAsset(
        bytes32 assetId,
        address owner,
        AssetOrigin calldata origin,
        bytes32[] calldata metadataTags,
        string[] calldata metadataURIs
    ) external onlyRole(REGISTRAR_ROLE) {
        if (assetExists[assetId]) {
            revert AssetAlreadyRegistered(assetId);
        }
        if (metadataTags.length != metadataURIs.length) {
            revert InvalidMetadataInput();
        }

        Asset storage newAsset = assets[assetId];
        newAsset.assetId = assetId;
        newAsset.owner = owner;
        newAsset.origin = origin;
        newAsset.state = AssetRegistryState.Registered; // Initial state
        newAsset.registrationTime = uint64(block.timestamp);
        newAsset.metadataLocked = false;
        newAsset.reputationScore = 0; // Initial score

        for (uint i = 0; i < metadataTags.length; i++) {
            newAsset.metadata[metadataTags[i]] = metadataURIs[i];
            emit AssetMetadataAdded(assetId, metadataTags[i], metadataURIs[i]);
        }

        assetExists[assetId] = true;
        _addAssetToOwnerIndex(owner, assetId);

        emit AssetRegistered(assetId, owner, origin, newAsset.registrationTime);
    }

    /// @notice Registers multiple assets in a single transaction.
    /// @param assetIds Array of unique identifiers for the assets.
    /// @param owners Array of initial owners.
    /// @param origins Array of origins.
    /// @param metadataTagsBatch Array of arrays of metadata tags.
    /// @param metadataURIsBatch Array of arrays of metadata URIs.
    /// @dev All arrays must have the same length. Inner metadata arrays must match length for each asset.
    function registerBatch(
        bytes32[] calldata assetIds,
        address[] calldata owners,
        AssetOrigin[] calldata origins,
        bytes32[][] calldata metadataTagsBatch,
        string[][] calldata metadataURIsBatch
    ) external onlyRole(REGISTRAR_ROLE) {
        if (assetIds.length != owners.length ||
            assetIds.length != origins.length ||
            assetIds.length != metadataTagsBatch.length ||
            assetIds.length != metadataURIsBatch.length
        ) {
            revert BatchInputMismatch();
        }

        for (uint i = 0; i < assetIds.length; i++) {
            bytes32 assetId = assetIds[i];
            address owner = owners[i];
            AssetOrigin calldata origin = origins[i];
            bytes32[] calldata metadataTags = metadataTagsBatch[i];
            string[] calldata metadataURIs = metadataURIsBatch[i];

            if (assetExists[assetId]) {
                revert AssetAlreadyRegistered(assetId); // Stop batch if any ID exists
            }
             if (metadataTags.length != metadataURIs.length) {
                revert InvalidMetadataInput(); // Stop batch if metadata arrays mismatch
            }

            Asset storage newAsset = assets[assetId];
            newAsset.assetId = assetId;
            newAsset.owner = owner;
            newAsset.origin = origin;
            newAsset.state = AssetRegistryState.Registered;
            newAsset.registrationTime = uint64(block.timestamp);
            newAsset.metadataLocked = false;
            newAsset.reputationScore = 0;

            for (uint j = 0; j < metadataTags.length; j++) {
                newAsset.metadata[metadataTags[j]] = metadataURIs[j];
                emit AssetMetadataAdded(assetId, metadataTags[j], metadataURIs[j]);
            }

            assetExists[assetId] = true;
            _addAssetToOwnerIndex(owner, assetId);

            emit AssetRegistered(assetId, owner, origin, newAsset.registrationTime);
        }
    }

    /// @notice Removes an asset entry completely from the registry.
    /// @dev Can only deregister assets that are Burned or Archived.
    /// @param assetId The identifier of the asset to deregister.
    function deregisterAsset(bytes32 assetId) external onlyRole(REGISTRAR_ROLE) {
        Asset storage asset = _getAsset(assetId);

        if (asset.state != AssetRegistryState.Burned && asset.state != AssetRegistryState.Archived) {
             revert CannotDeregisterActiveAsset(assetId);
        }

        address owner = asset.owner; // Get owner before deleting

        delete assets[assetId];
        assetExists[assetId] = false;
        _removeAssetFromOwnerIndex(owner, assetId);

        // Note: Linked assets referencing this one will have dangling bytes32 IDs.
        // Consider adding logic to clean up back-links if needed (requires separate mapping).

        emit AssetBurned(assetId); // Using AssetBurned as a final state/event
        // Could add a specific AssetDeregistered event if needed
    }


    /// @notice Updates the owner of an asset record in this registry.
    /// @dev This does NOT affect the ownership of the actual asset if it's an on-chain token.
    /// @param assetId The identifier of the asset.
    /// @param newOwner The new owner address in the registry.
    function transferAssetOwnershipInRegistry(bytes32 assetId, address newOwner) external onlyRole(REGISTRAR_ROLE) {
        Asset storage asset = _getAsset(assetId);
        address oldOwner = asset.owner;

        if (oldOwner == newOwner) {
            return; // No change
        }

        asset.owner = newOwner;
        _removeAssetFromOwnerIndex(oldOwner, assetId);
        _addAssetToOwnerIndex(newOwner, assetId);

        emit AssetOwnerUpdated(assetId, oldOwner, newOwner);
    }

    /// @notice Adds a new metadata URI for a specific environment tag to an asset.
    /// @param assetId The identifier of the asset.
    /// @param metadataTag The tag identifying the environment or metadata type (e.g., keccak256("UNITY"), keccak256("UE5"), keccak256("WEB")).
    /// @param metadataURI The URI or reference string for the metadata.
    function addMetadata(bytes32 assetId, bytes32 metadataTag, string calldata metadataURI) external onlyRole(METADATA_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        if (asset.metadataLocked) {
            revert AssetMetadataLocked(assetId);
        }
        if (bytes(asset.metadata[metadataTag]).length != 0) {
            // Consider adding an error here or letting updateMetadata handle it.
            // For now, this function only ADDS if not exists. Use updateMetadata to change.
            // This implementation will simply overwrite if it exists, which is slightly ambiguous.
            // Let's add a check to ensure it doesn't exist for "add".
             if (bytes(asset.metadata[metadataTag]).length > 0) {
                 revert ("Metadata tag already exists. Use update.");
             }
        }

        asset.metadata[metadataTag] = metadataURI;
        emit AssetMetadataAdded(assetId, metadataTag, metadataURI);
    }

     /// @notice Updates an existing metadata URI for a specific environment tag on an asset.
    /// @param assetId The identifier of the asset.
    /// @param metadataTag The tag identifying the environment or metadata type.
    /// @param newMetadataURI The new URI or reference string for the metadata.
    function updateMetadata(bytes32 assetId, bytes32 metadataTag, string calldata newMetadataURI) external onlyRole(METADATA_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        if (asset.metadataLocked) {
            revert AssetMetadataLocked(assetId);
        }
         string memory oldMetadataURI = asset.metadata[metadataTag];
        if (bytes(oldMetadataURI).length == 0) {
            revert MetadataTagNotFound(assetId, metadataTag);
        }

        asset.metadata[metadataTag] = newMetadataURI;
        emit AssetMetadataUpdated(assetId, metadataTag, oldMetadataURI, newMetadataURI);
    }

    /// @notice Removes a metadata entry for a specific environment tag from an asset.
    /// @param assetId The identifier of the asset.
    /// @param metadataTag The tag identifying the environment or metadata type to remove.
    function removeMetadata(bytes32 assetId, bytes32 metadataTag) external onlyRole(METADATA_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
         if (asset.metadataLocked) {
            revert AssetMetadataLocked(assetId);
        }
        string memory removedURI = asset.metadata[metadataTag];
         if (bytes(removedURI).length == 0) {
            revert MetadataTagNotFound(assetId, metadataTag);
        }

        delete asset.metadata[metadataTag];
        emit AssetMetadataRemoved(assetId, metadataTag, removedURI);
    }

    /// @notice Adds or updates multiple metadata entries on a single asset.
    /// @param assetId The identifier of the asset.
    /// @param metadataTags Array of metadata tags.
    /// @param metadataURIs Array of corresponding metadata URIs.
    /// @dev If a tag exists, it's updated; otherwise, it's added.
    function updateMetadataBatch(
        bytes32 assetId,
        bytes32[] calldata metadataTags,
        string[] calldata metadataURIs
    ) external onlyRole(METADATA_MANAGER_ROLE) {
         Asset storage asset = _getAsset(assetId);
         if (asset.metadataLocked) {
            revert AssetMetadataLocked(assetId);
        }
        if (metadataTags.length != metadataURIs.length) {
            revert InvalidMetadataInput();
        }

        for (uint i = 0; i < metadataTags.length; i++) {
            bytes32 tag = metadataTags[i];
            string calldata uri = metadataURIs[i];
            string memory oldUri = asset.metadata[tag];

            asset.metadata[tag] = uri;

            if (bytes(oldUri).length == 0) {
                 emit AssetMetadataAdded(assetId, tag, uri);
            } else {
                 emit AssetMetadataUpdated(assetId, tag, oldUri, uri);
            }
        }
    }


    /// @notice Updates the state of an asset record in the registry.
    /// @param assetId The identifier of the asset.
    /// @param newState The new state for the asset.
    function updateAssetState(bytes32 assetId, AssetRegistryState newState) external onlyRole(STATE_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        AssetRegistryState oldState = asset.state;

        if (oldState == newState) {
            return; // No change
        }

        asset.state = newState;
        emit AssetStateUpdated(assetId, oldState, newState);
    }

    /// @notice Applies a state change to multiple assets in a single transaction.
    /// @param assetIds Array of identifiers of the assets.
    /// @param newState The new state for the assets.
    function applyStateToBatch(bytes32[] calldata assetIds, AssetRegistryState newState) external onlyRole(STATE_MANAGER_ROLE) {
        for (uint i = 0; i < assetIds.length; i++) {
            bytes32 assetId = assetIds[i];
            // Get asset inside the loop in case of shared state changes
            Asset storage asset = _getAsset(assetId);
            AssetRegistryState oldState = asset.state;

            if (oldState != newState) {
                asset.state = newState;
                emit AssetStateUpdated(assetId, oldState, newState);
            }
        }
    }

    /// @notice Creates a directional link from one asset (`assetId`) to another (`linkedAssetId`).
    /// @param assetId The identifier of the asset initiating the link.
    /// @param linkedAssetId The identifier of the asset being linked to.
    /// @dev Requires both assets to exist in the registry.
    function linkAsset(bytes32 assetId, bytes32 linkedAssetId) external onlyRole(METADATA_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        // Check if the target asset exists as well
        if (!assetExists[linkedAssetId]) {
            revert AssetNotRegistered(linkedAssetId);
        }
        if (assetId == linkedAssetId) {
            revert CannotLinkToSelf(assetId);
        }

        // Check if already linked (simple linear scan, could optimize with mapping for large link counts)
        for (uint i = 0; i < asset.linkedAssets.length; i++) {
            if (asset.linkedAssets[i] == linkedAssetId) {
                revert AssetAlreadyLinked(assetId, linkedAssetId);
            }
        }

        asset.linkedAssets.push(linkedAssetId);
        emit AssetLinked(assetId, linkedAssetId);
    }

    /// @notice Removes a directional link from one asset (`assetId`) to another (`linkedAssetId`).
    /// @param assetId The identifier of the asset initiating the link removal.
    /// @param linkedAssetId The identifier of the asset that was linked to.
    function unlinkAsset(bytes32 assetId, bytes32 linkedAssetId) external onlyRole(METADATA_MANAGER_ROLE) {
         Asset storage asset = _getAsset(assetId);

         // Find and remove the linked asset ID using swap-and-pop
         uint256 initialLength = asset.linkedAssets.length;
         for (uint i = 0; i < asset.linkedAssets.length; i++) {
             if (asset.linkedAssets[i] == linkedAssetId) {
                 // Swap with the last element
                 if (i != asset.linkedAssets.length - 1) {
                     asset.linkedAssets[i] = asset.linkedAssets[asset.linkedAssets.length - 1];
                 }
                 // Remove the last element
                 asset.linkedAssets.pop();
                 emit AssetUnlinked(assetId, linkedAssetId);
                 return; // Exit once removed
             }
         }

         // If loop finishes without finding the link
         if (asset.linkedAssets.length == initialLength) {
             revert AssetNotLinked(assetId, linkedAssetId);
         }
    }

    /// @notice Prevents further additions, updates, or removals of metadata for an asset.
    /// @param assetId The identifier of the asset.
    function lockAssetMetadata(bytes32 assetId) external onlyRole(METADATA_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        if (!asset.metadataLocked) {
            asset.metadataLocked = true;
            emit AssetMetadataLocked(assetId);
        }
    }

     /// @notice Allows metadata changes again for an asset that was previously locked.
    /// @param assetId The identifier of the asset.
    function unlockAssetMetadata(bytes32 assetId) external onlyRole(METADATA_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        if (asset.metadataLocked) {
            asset.metadataLocked = false;
            emit AssetMetadataUnlocked(assetId);
        }
    }


    /// @notice Marks an asset entry as 'Burned' in the registry. Does not delete.
    /// @param assetId The identifier of the asset to burn in the registry.
    function burnAssetRegistryEntry(bytes32 assetId) external onlyRole(STATE_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        AssetRegistryState oldState = asset.state;

        if (oldState != AssetRegistryState.Burned) {
            asset.state = AssetRegistryState.Burned;
            // Remove from owner index as it's "burned" from the owner's perspective in registry
             _removeAssetFromOwnerIndex(asset.owner, assetId);
            emit AssetStateUpdated(assetId, oldState, AssetRegistryState.Burned);
            emit AssetBurned(assetId);
        }
    }

    /// @notice Sets or updates the reputation score for an asset record.
    /// @dev This score is abstract and could be updated by trusted off-chain processes via this function.
    /// @param assetId The identifier of the asset.
    /// @param score The new reputation score (can be positive or negative).
    function setAssetReputationScore(bytes32 assetId, int256 score) external onlyRole(REPUTATION_MANAGER_ROLE) {
        Asset storage asset = _getAsset(assetId);
        int256 oldScore = asset.reputationScore;
        if (oldScore != score) {
            asset.reputationScore = score;
            emit AssetReputationScoreUpdated(assetId, oldScore, score);
        }
    }

    // --- View Functions (Read Only) ---

    /// @notice Checks if an asset ID is currently registered in the contract.
    /// @param assetId The identifier of the asset.
    /// @return True if the asset exists, false otherwise.
    function assetExistsQuery(bytes32 assetId) external view returns (bool) {
        return assetExists[assetId];
    }

     /// @notice Retrieves the full details of an asset record.
    /// @param assetId The identifier of the asset.
    /// @return The Asset struct.
    function getAssetInfo(bytes32 assetId) external view returns (Asset memory) {
         // Use direct access for view function, _getAsset is for state changes requiring storage reference
        if (!assetExists[assetId]) {
             revert AssetNotRegistered(assetId);
         }
         return assets[assetId];
    }

    /// @notice Retrieves the owner address recorded for an asset.
    /// @param assetId The identifier of the asset.
    /// @return The owner's address.
    function getAssetOwner(bytes32 assetId) external view returns (address) {
        return _getAsset(assetId).owner;
    }

    /// @notice Retrieves the origin information for an asset.
    /// @param assetId The identifier of the asset.
    /// @return The AssetOrigin struct.
    function getAssetOrigin(bytes32 assetId) external view returns (AssetOrigin memory) {
        return _getAsset(assetId).origin;
    }

    /// @notice Retrieves the current state of an asset record.
    /// @param assetId The identifier of the asset.
    /// @return The AssetRegistryState enum value.
    function getAssetState(bytes32 assetId) external view returns (AssetRegistryState) {
        return _getAsset(assetId).state;
    }

    /// @notice Retrieves the metadata URI for a specific tag on an asset.
    /// @param assetId The identifier of the asset.
    /// @param metadataTag The tag identifying the environment or metadata type.
    /// @return The metadata URI string. Returns empty string if tag not found.
    function getMetadata(bytes32 assetId, bytes32 metadataTag) external view returns (string memory) {
        return _getAsset(assetId).metadata[metadataTag];
    }

    /// @notice Retrieves an array of all metadata tags associated with an asset.
    /// @dev Note: Iterating over mapping keys in Solidity is not directly supported. This function
    /// requires iterating over the *storage* mapping which is gas-intensive and not feasible for large numbers of tags per asset.
    /// A more gas-efficient approach would involve storing tags in a separate array upon addition.
    /// This implementation is a placeholder demonstrating the concept, but is not performant.
    /// A better approach is to rely on off-chain indexing of `AssetMetadataAdded` events.
     function getAllMetadataTags(bytes32 assetId) external view returns (bytes32[] memory) {
         // Accessing mapping keys is inefficient. This is a conceptual example.
         // A real-world solution would index the events off-chain or store tags in an array in the struct.
         revert("Querying all metadata tags directly from storage is not supported efficiently. Index events off-chain.");
         // The logic below would attempt iteration but is not practical on-chain.
         /*
         Asset storage asset = _getAsset(assetId);
         bytes32[] memory tags; // Cannot determine size without iteration
         // ... (complex, gas-heavy iteration logic)
         return tags;
         */
     }


    /// @notice Retrieves an array of all asset IDs linked from the given asset.
    /// @param assetId The identifier of the asset.
    /// @return An array of linked asset IDs.
    function getLinkedAssets(bytes32 assetId) external view returns (bytes32[] memory) {
         Asset storage asset = _getAsset(assetId);
         return asset.linkedAssets;
    }

    /// @notice Checks if an asset is directly linked to another specific asset.
    /// @param assetId The identifier of the asset to check links from.
    /// @param possibleLinkedAssetId The identifier of the asset to check linkage to.
    /// @return True if `assetId` is linked to `possibleLinkedAssetId`, false otherwise.
    function isAssetLinkedTo(bytes32 assetId, bytes32 possibleLinkedAssetId) external view returns (bool) {
        Asset storage asset = _getAsset(assetId);
        for (uint i = 0; i < asset.linkedAssets.length; i++) {
            if (asset.linkedAssets[i] == possibleLinkedAssetId) {
                return true;
            }
        }
        return false;
    }

    /// @notice Retrieves the registration timestamp for an asset.
    /// @param assetId The identifier of the asset.
    /// @return The registration time as a uint64 timestamp.
    function getAssetRegistrationTime(bytes32 assetId) external view returns (uint64) {
        return _getAsset(assetId).registrationTime;
    }

     /// @notice Retrieves the current reputation score for an asset.
    /// @param assetId The identifier of the asset.
    /// @return The reputation score as an int256.
    function getAssetReputationScore(bytes32 assetId) external view returns (int256) {
        return _getAsset(assetId).reputationScore;
    }

    /// @notice Retrieves an array of all asset IDs registered to a specific owner address.
    /// @dev This function relies on the `ownerAssets` index. Be mindful of potential gas costs
    /// if an owner has a very large number of registered assets, as the entire array is returned.
    /// @param owner The address of the owner.
    /// @return An array of asset IDs.
    function getAssetsByOwner(address owner) external view returns (bytes32[] memory) {
        return ownerAssets[owner];
    }

    /// @notice Retrieves the count of assets registered to a specific owner address.
    /// @param owner The address of the owner.
    /// @return The number of assets registered to the owner.
    function getAssetsCountByOwner(address owner) external view returns (uint256) {
        return ownerAssets[owner].length;
    }

    // --- AccessControl Functions (Inherited) ---
    // Standard OpenZeppelin functions inherited for managing roles.

    /// @inheritdoc AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```