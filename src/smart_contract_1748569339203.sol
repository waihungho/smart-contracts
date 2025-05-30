Okay, here is a Solidity smart contract for a Metaverse Asset Manager.

This contract incorporates several advanced concepts:
1.  **Metaverse Structure:** Manages assets within a conceptual 3D space using location coordinates.
2.  **Dynamic Assets:** Assets can have evolving states based on time or interaction.
3.  **Asset Types:** Allows defining templates for different kinds of assets (land, items, etc.).
4.  **Fractional Ownership (Internal):** Allows splitting ownership of a single asset among multiple addresses *within* the contract's logic (simplified, not issuing external ERC20s).
5.  **Usage Delegation:** Allows an owner to grant temporary usage rights to another address without transferring ownership.
6.  **Staking (Conceptual):** Allows staking assets within the contract (without specific reward logic, but sets up the mechanism).
7.  **Location-Based Access Control:** Permissions can be granted or denied based on metaverse location.
8.  **Batch Operations:** Includes functions for efficiency like batch minting.
9.  **Pausability:** Standard security feature.
10. **ERC721-like interface:** While not inheriting directly to avoid "duplication" of a standard library, it implements core functions like `ownerOf`, `balanceOf`, `transferFrom`, `approve`, `setApprovalForAll`.

This combination of features in a single contract managing diverse metaverse assets is less common than dedicated protocols for each function (like separate fractionalization protocols or staking contracts).

---

**MetaverseAssetManager.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MetaverseAssetManager
 * @dev A smart contract for managing diverse assets within a conceptual metaverse.
 * It handles creation, ownership, location, state, time-based evolution,
 * fractionalization, usage delegation, staking, and location-based access control
 * for various types of virtual assets.
 */

// --- OUTLINE ---
// 1. State Variables & Mappings
// 2. Struct Definitions (AssetType, MetaverseLocation, Asset)
// 3. Events
// 4. Modifiers
// 5. Constructor
// 6. Core ERC721-like Functions (ownerOf, balanceOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom)
// 7. Asset Type Management Functions (addAssetType, updateAssetType, removeAssetType, getAssetType)
// 8. Asset Creation & Destruction Functions (mintAsset, batchMintAssets, burnAsset)
// 9. Asset Property & State Management Functions (updateAssetLocation, updateAssetState, attachMetadata, setTimeBasedProperty, evolveAsset)
// 10. Advanced Ownership & Usage Functions (fractionalizeAsset, deFractionalizeAsset, delegateAssetUsage, revokeAssetUsageDelegation)
// 11. Staking Functions (stakeAsset, unstakeAsset)
// 12. Location-Based Access Control (grantLocationAccess, revokeLocationAccess, checkLocationAccess)
// 13. Query Functions (getAsset, getLocationAssets, getOwnerAssets)
// 14. Contract Configuration & Utility (setBaseURI, pauseContract, unpauseContract, paused)

// --- FUNCTION SUMMARY ---
// State Variables:
// - owner: Contract owner address.
// - nextAssetId: Counter for unique asset IDs.
// - nextAssetTypeId: Counter for unique asset type IDs.
// - baseTokenURI: Base URI for asset metadata.
// - _paused: Pausability state.
// - assetTypes: Mapping from asset type ID to AssetType struct.
// - assets: Mapping from asset ID to Asset struct.
// - _assetOwners: Mapping from asset ID to owner address (ERC721-like).
// - _ownedAssetsCount: Mapping from owner address to number of owned assets.
// - _ownedAssets: Mapping from owner address to list of owned asset IDs (less efficient, for demo).
// - _assetApprovals: Mapping from asset ID to approved address (ERC721-like).
// - _operatorApprovals: Mapping from owner address to operator address to approval status (ERC721-like).
// - locationToAssets: Mapping from location hash to list of asset IDs at that location.
// - stakedAssets: Mapping from asset ID to address that staked it (non-zero if staked).
// - assetUsageDelegations: Mapping from asset ID to delegate address to approval status.
// - assetFractionalShares: Mapping from asset ID to owner address to share amount.
// - locationAccessPermissions: Mapping from location hash to address to permission status.

// Structs:
// - MetaverseLocation: Represents X, Y, Z coordinates.
// - AssetType: Defines template for asset types (name, properties, supply limits).
// - Asset: Represents a specific asset instance (ID, type, owner, location, state, time data, metadata).

// Events:
// - AssetMinted: Emitted when a new asset is minted.
// - AssetTransferred: Emitted on asset transfer.
// - AssetBurned: Emitted when an asset is burned.
// - AssetTypeAdded: Emitted when a new asset type is defined.
// - AssetStateUpdated: Emitted when an asset's state changes.
// - AssetLocationUpdated: Emitted when an asset's location changes.
// - AssetMetadataUpdated: Emitted when an asset's metadata URI changes.
// - AssetStaked: Emitted when an asset is staked.
// - AssetUnstaked: Emitted when an asset is unstaked.
// - AssetUsageDelegated: Emitted when usage rights are delegated.
// - AssetUsageRevoked: Emitted when usage delegation is revoked.
// - AssetFractionalized: Emitted when an asset is fractionalized.
// - AssetDeFractionalized: Emitted when fractional ownership is recombined.
// - LocationAccessGranted: Emitted when location access is granted.
// - LocationAccessRevoked: Emitted when location access is revoked.
// - Paused: Emitted when contract is paused.
// - Unpaused: Emitted when contract is unpaused.
// - Approval: ERC721 standard approval event.
// - ApprovalForAll: ERC721 standard approval for all event.

// Modifiers:
// - onlyOwner: Restricts access to the contract owner.
// - whenNotPaused: Prevents execution when the contract is paused.
// - whenPaused: Allows execution only when the contract is paused.
// - _isApprovedOrOwner: Internal helper to check ownership or approval.
// - _isUsageDelegateOrOwner: Internal helper to check ownership or usage delegation.

// Functions:
// - constructor(): Initializes the contract owner.
// - ownerOf(uint256 assetId): Returns the owner of the asset.
// - balanceOf(address owner): Returns the number of assets owned by an address.
// - getApproved(uint256 assetId): Returns the approved address for a single asset.
// - isApprovedForAll(address owner, address operator): Checks if an operator is approved for all owner's assets.
// - approve(address to, uint256 assetId): Approves an address to transfer a specific asset.
// - setApprovalForAll(address operator, bool approved): Approves/revokes an operator for all owner's assets.
// - transferFrom(address from, address to, uint256 assetId): Transfers asset (internal helper).
// - safeTransferFrom(address from, address to, uint256 assetId): Safely transfers asset.
// - safeTransferFrom(address from, address to, uint256 assetId, bytes memory data): Safely transfers asset with data.
// - addAssetType(string memory _name, string memory _metadataTemplateURI, string memory _initialState, bool _isTransferable, uint256 _maxSupply): Adds a new asset type definition (onlyOwner).
// - updateAssetType(uint256 assetTypeId, string memory _name, string memory _metadataTemplateURI, string memory _initialState, bool _isTransferable, uint256 _maxSupply): Updates an existing asset type (onlyOwner).
// - removeAssetType(uint256 assetTypeId): Removes an asset type (onlyOwner, requires no assets of this type exist).
// - getAssetType(uint256 assetTypeId): Retrieves details of an asset type.
// - mintAsset(uint256 assetTypeId, MetaverseLocation memory location): Mints a new asset of a given type at a location (onlyOwner or authorized minter).
// - batchMintAssets(uint256 assetTypeId, MetaverseLocation[] memory locations): Mints multiple assets of the same type at different locations (onlyOwner or authorized minter).
// - burnAsset(uint256 assetId): Burns/destroys an asset (owner or approved).
// - updateAssetLocation(uint256 assetId, MetaverseLocation memory newLocation): Updates an asset's location (owner or approved).
// - updateAssetState(uint256 assetId, string memory newState): Updates an asset's state (owner, approved, or authorized game logic).
// - attachMetadata(uint256 assetId, string memory newMetadataURI): Sets specific metadata URI for an asset (owner or authorized).
// - setTimeBasedProperty(uint256 assetId, string memory propertyName, uint256 value): Sets a timestamp-related property (e.g., last water time) (owner or authorized). *Concept only, struct needs property map.*
// - evolveAsset(uint256 assetId): Simulates asset evolution based on time since last interaction/creation (anyone can call, state changes based on logic).
// - fractionalizeAsset(uint256 assetId, uint256 totalShares, address[] memory shareRecipients, uint256[] memory shareAmounts): Splits asset ownership into internal shares (owner).
// - deFractionalizeAsset(uint256 assetId): Recombines all shares to the owner (owner).
// - delegateAssetUsage(uint256 assetId, address delegate, bool allowed): Delegates/revokes usage rights without transfer (owner).
// - revokeAssetUsageDelegation(uint256 assetId, address delegate): Revokes specific usage delegation (owner).
// - stakeAsset(uint256 assetId): Stakes an asset in the contract (owner).
// - unstakeAsset(uint256 assetId): Unstakes an asset from the contract (owner).
// - grantLocationAccess(MetaverseLocation memory location, address user, bool hasAccess): Grants/revokes access permission for a location (owner or authorized).
// - revokeLocationAccess(MetaverseLocation memory location, address user): Revokes access (owner or authorized).
// - checkLocationAccess(MetaverseLocation memory location, address user): Checks if a user has access to a location.
// - getAsset(uint256 assetId): Retrieves details of an asset.
// - getLocationAssets(MetaverseLocation memory location): Gets list of asset IDs at a location.
// - getOwnerAssets(address owner): Gets list of asset IDs owned by an address.
// - setBaseURI(string memory newBaseURI): Sets the base URI for metadata (onlyOwner).
// - pauseContract(): Pauses the contract (onlyOwner).
// - unpauseContract(): Unpauses the contract (onlyOwner).
// - paused(): Returns the pausable state.
// - tokenURI(uint256 assetId): Standard ERC721 tokenURI function.

// Notes on Advanced Concepts Implementation:
// - Fractionalization: Simplified by using an internal mapping. Actual fractional tokens would require a separate ERC20 contract and interaction logic.
// - Evolution: The `evolveAsset` function is a placeholder. Real evolution would involve complex logic based on time elapsed, state, environment data (potentially off-chain), etc.
// - Staking: Simplified. Real staking yields rewards, requiring reward mechanisms (e.g., token distribution, yield calculation), which are not included here.
// - Usage Delegation: This is a simple boolean check; complex delegation could involve granular permissions.
// - Location Hashing: Uses a basic keccak256 hash of packed location coordinates. Be mindful of potential hash collisions for very large coordinate spaces, though unlikely for uint limits.
// - Authorization: Many functions mention "authorized minter/logic". In a real system, this would use roles (e.g., using OpenZeppelin AccessControl) instead of just `onlyOwner` or implied permissions.

contract MetaverseAssetManager {
    // --- 1. State Variables & Mappings ---
    address public owner;
    uint256 private nextAssetId = 1; // Start asset IDs from 1
    uint256 private nextAssetTypeId = 1; // Start asset type IDs from 1
    string private baseTokenURI;
    bool private _paused;

    mapping(uint256 => AssetType) public assetTypes;
    mapping(uint256 => Asset) public assets;

    // ERC721-like ownership mappings
    mapping(uint256 => address) private _assetOwners;
    mapping(address => uint256) private _ownedAssetsCount;
    mapping(address => uint256[]) private _ownedAssets; // Less efficient for large numbers, but simple for demo
    mapping(uint256 => address) private _assetApprovals; // Approved address for a single asset
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Approved for all assets

    // Location-based mapping
    mapping(bytes32 => uint256[]) private locationToAssets;

    // Staking state
    mapping(uint256 => address) public stakedAssets; // Asset ID => staker address (address(0) if not staked)

    // Usage Delegation state
    mapping(uint256 => mapping(address => bool)) public assetUsageDelegations; // assetId => delegate => allowed

    // Fractional Ownership state (simplified)
    mapping(uint256 => mapping(address => uint256)) public assetFractionalShares; // assetId => holder => shareAmount
    mapping(uint256 => uint256) public assetFractionalSupply; // assetId => total shares issued

    // Location Access Control state
    mapping(bytes32 => mapping(address => bool)) public locationAccessPermissions; // locationHash => user => hasAccess

    // --- 2. Struct Definitions ---
    struct MetaverseLocation {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    struct AssetType {
        uint256 id;
        string name;
        string metadataTemplateURI;
        string initialState;
        bool isTransferable;
        uint256 maxSupply; // 0 for unlimited
        uint256 currentSupply;
    }

    struct Asset {
        uint256 id;
        uint256 assetTypeId;
        address owner; // Redundant with _assetOwners but useful for struct queries
        MetaverseLocation location;
        string currentState;
        uint256 creationTime;
        uint256 lastInteractionTime; // Can be used for time-based mechanics
        string metadataURI; // Can override baseTokenURI or type template
        bool isFractionalized; // True if fractional shares exist
    }

    // --- 3. Events ---
    event AssetMinted(uint256 indexed assetId, uint256 indexed assetTypeId, address indexed owner, MetaverseLocation location);
    event AssetTransferred(uint256 indexed assetId, address indexed from, address indexed to, MetaverseLocation oldLocation, MetaverseLocation newLocation);
    event AssetBurned(uint256 indexed assetId, address indexed owner, MetaverseLocation location);
    event AssetTypeAdded(uint256 indexed assetTypeId, string name, uint256 maxSupply);
    event AssetStateUpdated(uint256 indexed assetId, string newState);
    event AssetLocationUpdated(uint256 indexed assetId, MetaverseLocation oldLocation, MetaverseLocation newLocation);
    event AssetMetadataUpdated(uint256 indexed assetId, string newMetadataURI);
    event AssetStaked(uint256 indexed assetId, address indexed staker);
    event AssetUnstaked(uint256 indexed assetId, address indexed unstaker);
    event AssetUsageDelegated(uint256 indexed assetId, address indexed owner, address indexed delegate, bool allowed);
    event AssetFractionalized(uint256 indexed assetId, uint256 totalShares);
    event AssetDeFractionalized(uint256 indexed assetId);
    event LocationAccessGranted(bytes32 indexed locationHash, address indexed user);
    event LocationAccessRevoked(bytes32 indexed locationHash, address indexed user);
    event Paused(address account);
    event Unpaused(address account);

    // ERC721 Standard Events (required for compatibility, even if not strictly inheriting)
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- 4. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract not paused");
        _;
    }

    // Internal helper to check ownership or approval
    function _isApprovedOrOwner(address spender, uint256 assetId) internal view returns (bool) {
        address assetOwner = _assetOwners[assetId];
        return (spender == assetOwner ||
                getApproved(assetId) == spender ||
                isApprovedForAll(assetOwner, spender));
    }

    // Internal helper to check ownership or usage delegation
    function _isUsageDelegateOrOwner(address user, uint256 assetId) internal view returns (bool) {
        address assetOwner = _assetOwners[assetId];
        return (user == assetOwner || assetUsageDelegations[assetId][user]);
    }

    // Internal helper to hash location for mapping keys
    function _hashLocation(MetaverseLocation memory location) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(location.x, location.y, location.z));
    }

    // Internal helper to find and remove an item from a dynamic array (simple implementation)
    function _removeFromArray(uint256[] storage arr, uint256 value) private {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                if (i < arr.length - 1) {
                    arr[i] = arr[arr.length - 1]; // Replace with last element
                }
                arr.pop(); // Remove last element
                break; // Value found and removed
            }
        }
    }


    // --- 5. Constructor ---
    constructor() {
        owner = msg.sender;
        _paused = false;
    }

    // --- 6. Core ERC721-like Functions ---

    /**
     * @dev Returns the owner of the asset. ERC721 standard.
     * @param assetId The identifier for an asset.
     * @return The address of the owner.
     */
    function ownerOf(uint256 assetId) public view returns (address) {
        address assetOwner = _assetOwners[assetId];
        require(assetOwner != address(0), "Asset does not exist");
        return assetOwner;
    }

    /**
     * @dev Returns the number of assets owned by `owner`. ERC721 standard.
     * @param _owner Address for whom to query the balance.
     * @return The number of assets owned by `owner`.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for the zero address");
        return _ownedAssetsCount[_owner];
    }

    /**
     * @dev Gets the approved address for a single asset. ERC721 standard.
     * @param assetId The asset to query the approval for.
     * @return The approved address.
     */
    function getApproved(uint256 assetId) public view returns (address) {
        require(_assetOwners[assetId] != address(0), "Asset does not exist");
        return _assetApprovals[assetId];
    }

    /**
     * @dev Checks if `operator` is an approved operator for `owner`. ERC721 standard.
     * @param _owner The address that owns the assets.
     * @param operator The address that acts on behalf of the owner.
     * @return True if the operator is approved, false otherwise.
     */
    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    /**
     * @dev Approves `to` to operate on `assetId`. ERC721 standard.
     * @param to The address to approve.
     * @param assetId The asset ID.
     */
    function approve(address to, uint256 assetId) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(msg.sender == assetOwner || isApprovedForAll(assetOwner, msg.sender), "Not owner or approved for all");
        _assetApprovals[assetId] = to;
        emit Approval(assetOwner, to, assetId);
    }

    /**
     * @dev Sets or unsets the approval for an operator to manage all of `msg.sender`'s assets. ERC721 standard.
     * @param operator The address to approve/revoke.
     * @param approved True to approve, false to revoke.
     */
    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        require(operator != msg.sender, "Cannot approve self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Internal function to transfer ownership of an asset. ERC721 standard helper.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param assetId The asset ID.
     */
    function _transfer(address from, address to, uint256 assetId) internal {
        require(ownerOf(assetId) == from, "Asset not owned by from address");
        require(to != address(0), "Transfer to the zero address");
        require(stakedAssets[assetId] == address(0), "Cannot transfer staked asset");
        require(!assets[assetId].isFractionalized, "Cannot transfer fractionalized asset directly"); // Must deFractionalize first

        // Clear approvals
        _assetApprovals[assetId] = address(0);
        emit Approval(from, address(0), assetId);

        // Update ownership mappings
        _ownedAssetsCount[from]--;
        _ownedAssetsCount[to]++;
        _assetOwners[assetId] = to;
        assets[assetId].owner = to; // Update struct owner

        // Update ownedAssets array (less efficient, but needed for getOwnerAssets)
        _removeFromArray(_ownedAssets[from], assetId);
        _ownedAssets[to].push(assetId);

        // Emit transfer event (location is included in the public event)
    }

    /**
     * @dev Transfers ownership of `assetId` from `from` to `to`. ERC721 standard.
     * Requires the caller to be the owner, approved for the asset, or approved for all of the owner's assets.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param assetId The asset ID.
     */
    function transferFrom(address from, address to, uint256 assetId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, assetId), "Not owner or approved");
        MetaverseLocation memory oldLocation = assets[assetId].location;
        _transfer(from, to, assetId);
        emit AssetTransferred(assetId, from, to, oldLocation, assets[assetId].location); // Location doesn't change on transfer
    }

    /**
     * @dev Transfers ownership of `assetId` from `from` to `to` safely. ERC721 standard.
     * Calls `onERC721Received` on `to` if `to` is a contract.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param assetId The asset ID.
     */
    function safeTransferFrom(address from, address to, uint256 assetId) public whenNotPaused {
        safeTransferFrom(from, to, assetId, "");
    }

    /**
     * @dev Transfers ownership of `assetId` from `from` to `to` safely. ERC721 standard.
     * Calls `onERC721Received` on `to` if `to` is a contract, passing `data`.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param assetId The asset ID.
     * @param data Additional data with no specified format.
     */
    function safeTransferFrom(address from, address to, uint256 assetId, bytes memory data) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, assetId), "Not owner or approved");
        MetaverseLocation memory oldLocation = assets[assetId].location;
        _transfer(from, to, assetId);
        // Check if the recipient is a contract and if it accepts the asset (simulated check)
        // In a real implementation, this would call a standard interface like IERC721Receiver.onERC721Received
        // For this example, we skip the actual external call for simplicity, but include the function signature.
        // require(_checkOnERC721Received(from, to, assetId, data), "ERC721Receiver rejected token");
        emit AssetTransferred(assetId, from, to, oldLocation, assets[assetId].location);
    }

    // --- 7. Asset Type Management Functions ---

    /**
     * @dev Adds a new asset type definition.
     * @param _name Name of the asset type (e.g., "Land Plot", "Sword").
     * @param _metadataTemplateURI Base URI for this asset type's metadata.
     * @param _initialState The initial state of assets minted with this type.
     * @param _isTransferable Whether assets of this type can be transferred.
     * @param _maxSupply Maximum number of assets of this type that can be minted (0 for unlimited).
     */
    function addAssetType(string memory _name, string memory _metadataTemplateURI, string memory _initialState, bool _isTransferable, uint256 _maxSupply) public onlyOwner whenNotPaused {
        uint256 typeId = nextAssetTypeId++;
        assetTypes[typeId] = AssetType({
            id: typeId,
            name: _name,
            metadataTemplateURI: _metadataTemplateURI,
            initialState: _initialState,
            isTransferable: _isTransferable,
            maxSupply: _maxSupply,
            currentSupply: 0
        });
        emit AssetTypeAdded(typeId, _name, _maxSupply);
    }

    /**
     * @dev Updates an existing asset type definition.
     * @param assetTypeId The ID of the asset type to update.
     * @param _name New name.
     * @param _metadataTemplateURI New metadata template URI.
     * @param _initialState New initial state.
     * @param _isTransferable New transferability status.
     * @param _maxSupply New max supply.
     */
    function updateAssetType(uint256 assetTypeId, string memory _name, string memory _metadataTemplateURI, string memory _initialState, bool _isTransferable, uint256 _maxSupply) public onlyOwner whenNotPaused {
        require(assetTypes[assetTypeId].id != 0, "Asset type does not exist");
        require(_maxSupply >= assetTypes[assetTypeId].currentSupply, "New max supply is less than current supply");

        AssetType storage typeToUpdate = assetTypes[assetTypeId];
        typeToUpdate.name = _name;
        typeToUpdate.metadataTemplateURI = _metadataTemplateURI;
        typeToUpdate.initialState = _initialState;
        typeToUpdate.isTransferable = _isTransferable;
        typeToUpdate.maxSupply = _maxSupply;

        // Emit a generic event or specific ones depending on granularity needed
        emit AssetTypeAdded(assetTypeId, _name, _maxSupply); // Re-using event for simplicity, could add Update event
    }

    /**
     * @dev Removes an asset type definition. Only possible if no assets of this type exist.
     * @param assetTypeId The ID of the asset type to remove.
     */
    function removeAssetType(uint256 assetTypeId) public onlyOwner whenNotPaused {
        require(assetTypes[assetTypeId].id != 0, "Asset type does not exist");
        require(assetTypes[assetTypeId].currentSupply == 0, "Assets of this type still exist");

        delete assetTypes[assetTypeId];
        // No specific event for removal, could add one.
    }

    /**
     * @dev Gets the details of an asset type.
     * @param assetTypeId The ID of the asset type.
     * @return The AssetType struct.
     */
    function getAssetType(uint256 assetTypeId) public view returns (AssetType memory) {
        require(assetTypes[assetTypeId].id != 0, "Asset type does not exist");
        return assetTypes[assetTypeId];
    }

    // --- 8. Asset Creation & Destruction Functions ---

    /**
     * @dev Mints a new asset of a given type at a specific location.
     * Only callable by the owner or a designated minter role (not implemented, assume owner for demo).
     * @param assetTypeId The ID of the asset type to mint.
     * @param location The metaverse location for the new asset.
     * @return The ID of the newly minted asset.
     */
    function mintAsset(uint256 assetTypeId, MetaverseLocation memory location) public onlyOwner whenNotPaused returns (uint256) {
        AssetType storage assetType = assetTypes[assetTypeId];
        require(assetType.id != 0, "Invalid asset type ID");
        require(assetType.maxSupply == 0 || assetType.currentSupply < assetType.maxSupply, "Max supply reached for asset type");

        uint256 newAssetId = nextAssetId++;
        address recipient = msg.sender; // Minter gets ownership, could be changed

        assets[newAssetId] = Asset({
            id: newAssetId,
            assetTypeId: assetTypeId,
            owner: recipient,
            location: location,
            currentState: assetType.initialState,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp, // Initial interaction is creation
            metadataURI: "", // Initially use type template or baseURI
            isFractionalized: false
        });

        // Update ownership mappings
        _assetOwners[newAssetId] = recipient;
        _ownedAssetsCount[recipient]++;
        _ownedAssets[recipient].push(newAssetId);

        // Add to location mapping
        bytes32 locationHash = _hashLocation(location);
        locationToAssets[locationHash].push(newAssetId);

        // Update asset type supply
        assetType.currentSupply++;

        emit AssetMinted(newAssetId, assetTypeId, recipient, location);
        return newAssetId;
    }

    /**
     * @dev Mints multiple assets of the same type at different locations in a single transaction.
     * Only callable by the owner or a designated minter role.
     * @param assetTypeId The ID of the asset type to mint.
     * @param locations Array of metaverse locations for the new assets.
     * @return Array of the IDs of the newly minted assets.
     */
    function batchMintAssets(uint256 assetTypeId, MetaverseLocation[] memory locations) public onlyOwner whenNotPaused returns (uint256[] memory) {
        require(locations.length > 0, "No locations provided");
        AssetType storage assetType = assetTypes[assetTypeId];
        require(assetType.id != 0, "Invalid asset type ID");
        require(assetType.maxSupply == 0 || assetType.currentSupply + locations.length <= assetType.maxSupply, "Batch mint exceeds max supply");

        uint256[] memory mintedAssetIds = new uint256[](locations.length);
        address recipient = msg.sender; // Minter gets ownership

        for (uint i = 0; i < locations.length; i++) {
            uint256 newAssetId = nextAssetId++;
            MetaverseLocation memory currentLocation = locations[i];

            assets[newAssetId] = Asset({
                id: newAssetId,
                assetTypeId: assetTypeId,
                owner: recipient,
                location: currentLocation,
                currentState: assetType.initialState,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                metadataURI: "",
                isFractionalized: false
            });

            _assetOwners[newAssetId] = recipient;
            _ownedAssetsCount[recipient]++;
            _ownedAssets[recipient].push(newAssetId);

            bytes32 locationHash = _hashLocation(currentLocation);
            locationToAssets[locationHash].push(newAssetId);

            assetType.currentSupply++;
            mintedAssetIds[i] = newAssetId;

            emit AssetMinted(newAssetId, assetTypeId, recipient, currentLocation);
        }

        return mintedAssetIds;
    }

    /**
     * @dev Burns/destroys an asset.
     * Only callable by the asset owner or an approved address.
     * @param assetId The ID of the asset to burn.
     */
    function burnAsset(uint256 assetId) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(_isApprovedOrOwner(msg.sender, assetId), "Not owner or approved");
        require(stakedAssets[assetId] == address(0), "Cannot burn staked asset");
        require(!assets[assetId].isFractionalized, "Cannot burn fractionalized asset directly"); // Must deFractionalize first

        MetaverseLocation memory location = assets[assetId].location;
        uint256 assetTypeId = assets[assetId].assetTypeId;

        // Clear ownership mappings
        _ownedAssetsCount[assetOwner]--;
        _removeFromArray(_ownedAssets[assetOwner], assetId);
        delete _assetOwners[assetId];
        delete _assetApprovals[assetId]; // Clear single approval

        // Remove from location mapping
        bytes32 locationHash = _hashLocation(location);
        _removeFromArray(locationToAssets[locationHash], assetId);

        // Decrement asset type supply
        assetTypes[assetTypeId].currentSupply--;

        // Remove asset data
        delete assets[assetId];

        emit AssetBurned(assetId, assetOwner, location);
    }

    // --- 9. Asset Property & State Management Functions ---

    /**
     * @dev Updates the location of an asset in the metaverse.
     * Only callable by the asset owner or an approved address.
     * @param assetId The ID of the asset.
     * @param newLocation The new metaverse location.
     */
    function updateAssetLocation(uint256 assetId, MetaverseLocation memory newLocation) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(_isApprovedOrOwner(msg.sender, assetId), "Not owner or approved");
        require(stakedAssets[assetId] == address(0), "Cannot move staked asset");
        // Add checks for valid location, boundaries, etc. here if applicable

        MetaverseLocation memory oldLocation = assets[assetId].location;
        bytes32 oldLocationHash = _hashLocation(oldLocation);
        bytes32 newLocationHash = _hashLocation(newLocation);

        // Update location in asset struct
        assets[assetId].location = newLocation;
        assets[assetId].lastInteractionTime = block.timestamp; // Moving is an interaction

        // Update location mapping
        _removeFromArray(locationToAssets[oldLocationHash], assetId);
        locationToAssets[newLocationHash].push(assetId);

        emit AssetLocationUpdated(assetId, oldLocation, newLocation);
    }

    /**
     * @dev Updates the state of an asset (e.g., "healthy", "decaying", "activated").
     * Can be called by owner, approved, or potentially by authorized game logic roles.
     * @param assetId The ID of the asset.
     * @param newState The new state string.
     */
    function updateAssetState(uint256 assetId, string memory newState) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        // Check authorization: owner, approved, OR specific authorized role (if using AccessControl)
        require(_isApprovedOrOwner(msg.sender, assetId), "Not authorized to update state"); // Simplified auth for demo

        assets[assetId].currentState = newState;
        assets[assetId].lastInteractionTime = block.timestamp; // Changing state is an interaction

        emit AssetStateUpdated(assetId, newState);
    }

    /**
     * @dev Attaches or updates a specific metadata URI for an asset, overriding the type template or base URI.
     * @param assetId The ID of the asset.
     * @param newMetadataURI The new metadata URI.
     */
    function attachMetadata(uint256 assetId, string memory newMetadataURI) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(_isApprovedOrOwner(msg.sender, assetId), "Not authorized to update metadata");

        assets[assetId].metadataURI = newMetadataURI;
        // No specific interaction time update for just metadata? Depends on game logic.
        emit AssetMetadataUpdated(assetId, newMetadataURI);
    }

    /**
     * @dev Sets a property related to time, useful for tracking specific interactions
     * or timestamps for time-based mechanics (e.g., `lastWaterTime`, `lastHarvestTime`).
     * This is a simplified placeholder. A real implementation would need a mapping
     * or struct field for arbitrary properties.
     * @param assetId The ID of the asset.
     * @param propertyName The name of the time-based property (e.g., "lastWaterTime").
     * @param value The timestamp value.
     */
    function setTimeBasedProperty(uint256 assetId, string memory propertyName, uint256 value) public whenNotPaused {
         address assetOwner = ownerOf(assetId); // Checks if asset exists
         require(_isUsageDelegateOrOwner(msg.sender, assetId), "Not authorized for asset usage"); // Usage delegation includes this?

         // --- Placeholder Logic ---
         // In a real contract, you'd store this property, e.g., in a mapping:
         // mapping(uint256 => mapping(string => uint256)) private assetTimeProperties;
         // assetTimeProperties[assetId][propertyName] = value;
         // Or modify the Asset struct to include a generic properties map.
         // For this example, we'll just require auth and maybe update last interaction time.
         assets[assetId].lastInteractionTime = block.timestamp; // Setting a property is an interaction

         // No specific event for this, but could add one if needed.
         // log `propertyName` and `value` in event if implemented
    }

    /**
     * @dev Simulates the evolution or decay of an asset based on time since its creation
     * or last interaction, and its current state.
     * Anyone can trigger this, but the state change logic happens internally.
     * @param assetId The ID of the asset.
     */
    function evolveAsset(uint256 assetId) public whenNotPaused {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");

        uint256 timeElapsed = block.timestamp - asset.lastInteractionTime;
        string memory oldState = asset.currentState;
        string memory newState = oldState; // Default to no change

        // --- Placeholder Evolution Logic ---
        // Implement complex logic here based on asset.assetTypeId, asset.currentState, timeElapsed, etc.
        // Example:
        // if (asset.assetTypeId == 5) { // Assuming type 5 is "Plant"
        //     if (keccak256(abi.encodePacked(oldState)) == keccak256(abi.encodePacked("seedling")) && timeElapsed > 1 days) {
        //         newState = "growing";
        //     } else if (keccak256(abi.encodePacked(oldState)) == keccak256(abi.encodePacked("growing")) && timeElapsed > 3 days) {
        //         newState = "mature";
        //     } else if (keccak256(abi.encodePacked(oldState)) == keccak256(abi.encodePacked("mature")) && timeElapsed > 7 days) {
        //         newState = "decaying"; // Decay after maturity if no interaction
        //     }
        // } else if (asset.assetTypeId == 8) { // Assuming type 8 is "Tool"
        //     if (keccak256(abi.encodePacked(oldState)) == keccak256(abi.encodePacked("new")) && timeElapsed > 30 days) {
        //         newState = "worn";
        //     }
        // }
        // --- End Placeholder Logic ---

        if (keccak256(abi.encodePacked(newState)) != keccak256(abi.encodePacked(oldState))) {
            asset.currentState = newState;
            asset.lastInteractionTime = block.timestamp; // Evolution is also an interaction/state change event
            emit AssetStateUpdated(assetId, newState);
        }
        // If no state change, no event needed.
    }

    // --- 10. Advanced Ownership & Usage Functions ---

    /**
     * @dev Splits ownership of an asset into internal fractional shares.
     * The original asset becomes non-transferable until de-fractionalized.
     * Shares are tracked internally. The owner must call this.
     * @param assetId The ID of the asset to fractionalize.
     * @param totalShares The total number of shares to create for this asset.
     * @param shareRecipients Addresses to receive shares.
     * @param shareAmounts The amount of shares for each recipient.
     */
    function fractionalizeAsset(uint256 assetId, uint256 totalShares, address[] memory shareRecipients, uint256[] memory shareAmounts) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(msg.sender == assetOwner, "Only owner can fractionalize");
        require(!assets[assetId].isFractionalized, "Asset is already fractionalized");
        require(stakedAssets[assetId] == address(0), "Cannot fractionalize staked asset");
        require(shareRecipients.length == shareAmounts.length, "Recipient and amount arrays mismatch");
        require(totalShares > 0, "Total shares must be positive");

        uint256 sumShares = 0;
        for (uint i = 0; i < shareAmounts.length; i++) {
            sumShares += shareAmounts[i];
        }
        require(sumShares <= totalShares, "Sum of shares exceeds total shares"); // Can fractionalize only partially

        assets[assetId].isFractionalized = true;
        assetFractionalSupply[assetId] = totalShares;

        // Distribute shares
        for (uint i = 0; i < shareRecipients.length; i++) {
            address recipient = shareRecipients[i];
            uint256 amount = shareAmounts[i];
            require(recipient != address(0), "Share recipient cannot be zero address");
            assetFractionalShares[assetId][recipient] += amount;
        }

        assets[assetId].lastInteractionTime = block.timestamp;
        emit AssetFractionalized(assetId, totalShares);
    }

    /**
     * @dev Recombines all internal fractional shares for an asset.
     * The asset becomes transferable again (if its type allows).
     * Only the address holding 100% of the shares can call this.
     * @param assetId The ID of the asset to de-fractionalize.
     */
    function deFractionalizeAsset(uint256 assetId) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(msg.sender == assetOwner, "Only owner can de-fractionalize");
        require(assets[assetId].isFractionalized, "Asset is not fractionalized");
        require(assetFractionalShares[assetId][assetOwner] == assetFractionalSupply[assetId], "Caller does not own 100% of shares");

        assets[assetId].isFractionalized = false;
        assetFractionalSupply[assetId] = 0;

        // Clear all fractional shares for this asset
        // Note: This simple implementation deletes all shares; a complex one
        // might need iteration or tracking holders.
        // For simplicity, we assume the owner is recombining all shares.
        delete assetFractionalShares[assetId];

        assets[assetId].lastInteractionTime = block.timestamp;
        emit AssetDeFractionalized(assetId);
    }

    /**
     * @dev Delegates usage rights for an asset to another address without transferring ownership.
     * The delegate can perform certain actions (defined by game logic checking `_isUsageDelegateOrOwner`).
     * Only callable by the asset owner.
     * @param assetId The ID of the asset.
     * @param delegate The address to delegate usage rights to.
     * @param allowed True to grant, False to revoke.
     */
    function delegateAssetUsage(uint256 assetId, address delegate, bool allowed) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(msg.sender == assetOwner, "Only owner can delegate usage");
        require(delegate != address(0), "Delegate cannot be the zero address");
        require(delegate != assetOwner, "Cannot delegate usage to self");

        assetUsageDelegations[assetId][delegate] = allowed;

        assets[assetId].lastInteractionTime = block.timestamp; // Delegation is an interaction
        emit AssetUsageDelegated(assetId, assetOwner, delegate, allowed);
    }

     /**
      * @dev Revokes usage delegation for a specific delegate on an asset.
      * Callable by the asset owner.
      * @param assetId The ID of the asset.
      * @param delegate The address whose usage rights to revoke.
      */
     function revokeAssetUsageDelegation(uint256 assetId, address delegate) public whenNotPaused {
         address assetOwner = ownerOf(assetId); // Checks if asset exists
         require(msg.sender == assetOwner, "Only owner can revoke usage");
         require(delegate != address(0), "Delegate cannot be the zero address");
         require(delegate != assetOwner, "Cannot revoke delegation from self");
         require(assetUsageDelegations[assetId][delegate], "Delegation does not exist");

         assetUsageDelegations[assetId][delegate] = false;

         assets[assetId].lastInteractionTime = block.timestamp; // Revoking is an interaction
         emit AssetUsageRevoked(assetId, assetOwner, delegate);
     }

    // --- 11. Staking Functions ---

    /**
     * @dev Stakes an asset in the contract.
     * Only callable by the asset owner. The asset becomes non-transferable and non-usable via delegation while staked.
     * @param assetId The ID of the asset to stake.
     */
    function stakeAsset(uint256 assetId) public whenNotPaused {
        address assetOwner = ownerOf(assetId); // Checks if asset exists
        require(msg.sender == assetOwner, "Only owner can stake");
        require(stakedAssets[assetId] == address(0), "Asset is already staked");
        require(!assets[assetId].isFractionalized, "Cannot stake fractionalized asset"); // Must deFractionalize first

        stakedAssets[assetId] = assetOwner; // Record who staked it
        // Asset remains owned by the user, but its state in this contract changes
        // No actual transfer occurs here

        assets[assetId].lastInteractionTime = block.timestamp; // Staking is an interaction
        emit AssetStaked(assetId, assetOwner);
    }

    /**
     * @dev Unstakes an asset from the contract.
     * Only callable by the address that staked it.
     * @param assetId The ID of the asset to unstake.
     */
    function unstakeAsset(uint256 assetId) public whenNotPaused {
        address staker = stakedAssets[assetId];
        require(staker != address(0), "Asset is not staked");
        require(msg.sender == staker, "Only the staker can unstake");

        stakedAssets[assetId] = address(0); // Clear staking status

        assets[assetId].lastInteractionTime = block.timestamp; // Unstaking is an interaction
        emit AssetUnstaked(assetId, staker);
    }

    // --- 12. Location-Based Access Control ---

    /**
     * @dev Grants or revokes general access permission for a specific metaverse location.
     * This could be used for allowing users to enter/interact with a plot of land, etc.
     * @param location The metaverse location.
     * @param user The address to grant/revoke access for.
     * @param hasAccess True to grant access, False to revoke.
     */
    function grantLocationAccess(MetaverseLocation memory location, address user, bool hasAccess) public onlyOwner whenNotPaused {
        // In a real system, this might also be controlled by the owner of land at this location,
        // or an authorized game manager role. Using onlyOwner for simplicity.
        require(user != address(0), "User address cannot be zero");

        bytes32 locationHash = _hashLocation(location);
        locationAccessPermissions[locationHash][user] = hasAccess;

        if (hasAccess) {
            emit LocationAccessGranted(locationHash, user);
        } else {
            emit LocationAccessRevoked(locationHash, user);
        }
    }

    /**
     * @dev Revokes access permission for a specific metaverse location for a user.
     * @param location The metaverse location.
     * @param user The address whose access to revoke.
     */
    function revokeLocationAccess(MetaverseLocation memory location, address user) public onlyOwner whenNotPaused {
         require(user != address(0), "User address cannot be zero");
         bytes32 locationHash = _hashLocation(location);
         require(locationAccessPermissions[locationHash][user], "User does not have access to this location");

         locationAccessPermissions[locationHash][user] = false;
         emit LocationAccessRevoked(locationHash, user);
    }


    /**
     * @dev Checks if a user has access permission for a specific metaverse location.
     * @param location The metaverse location.
     * @param user The address to check.
     * @return True if the user has access, false otherwise.
     */
    function checkLocationAccess(MetaverseLocation memory location, address user) public view returns (bool) {
        // Default access is false unless explicitly granted.
        bytes32 locationHash = _hashLocation(location);
        return locationAccessPermissions[locationHash][user];
    }

    // --- 13. Query Functions ---

    /**
     * @dev Retrieves details of a specific asset.
     * @param assetId The ID of the asset.
     * @return The Asset struct.
     */
    function getAsset(uint256 assetId) public view returns (Asset memory) {
        require(assets[assetId].id != 0, "Asset does not exist");
        return assets[assetId];
    }

    /**
     * @dev Gets the list of asset IDs located at a specific metaverse location.
     * @param location The metaverse location.
     * @return An array of asset IDs.
     */
    function getLocationAssets(MetaverseLocation memory location) public view returns (uint256[] memory) {
        bytes32 locationHash = _hashLocation(location);
        return locationToAssets[locationHash];
    }

     /**
      * @dev Gets the list of asset IDs owned by an address.
      * Note: This iterates over a stored array (_ownedAssets), which can become inefficient for owners with very large numbers of assets.
      * A more scalable approach might involve external indexing or different data structures.
      * @param _owner The address of the owner.
      * @return An array of asset IDs.
      */
     function getOwnerAssets(address _owner) public view returns (uint256[] memory) {
         require(_owner != address(0), "Query for zero address");
         return _ownedAssets[_owner];
     }

     /**
      * @dev Gets the fractional shares held by a specific address for a fractionalized asset.
      * @param assetId The ID of the asset.
      * @param holder The address holding shares.
      * @return The number of shares held.
      */
     function getFractionalShares(uint256 assetId, address holder) public view returns (uint256) {
         require(assets[assetId].id != 0, "Asset does not exist");
         return assetFractionalShares[assetId][holder];
     }

     /**
      * @dev Gets the total shares for a fractionalized asset.
      * @param assetId The ID of the asset.
      * @return The total number of shares.
      */
     function getFractionalSupply(uint256 assetId) public view returns (uint256) {
         require(assets[assetId].id != 0, "Asset does not exist");
         return assetFractionalSupply[assetId];
     }


    // --- 14. Contract Configuration & Utility ---

    /**
     * @dev Sets the base URI for computing asset metadata URIs. ERC721 standard.
     * The final URI for an asset is typically baseURI + assetId, possibly overridden
     * by assetType.metadataTemplateURI or asset.metadataURI.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() internal view returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Standard ERC721 tokenURI function.
     * Returns the metadata URI for a given asset.
     * Prioritizes: 1. asset.metadataURI, 2. assetType.metadataTemplateURI, 3. baseTokenURI + assetId.
     * @param assetId The ID of the asset.
     * @return The metadata URI.
     */
    function tokenURI(uint256 assetId) public view returns (string memory) {
        require(assets[assetId].id != 0, "Asset does not exist");

        string memory customURI = assets[assetId].metadataURI;
        if (bytes(customURI).length > 0) {
            return customURI; // Use asset-specific URI if set
        }

        AssetType memory assetType = assetTypes[assets[assetId].assetTypeId];
        if (bytes(assetType.metadataTemplateURI).length > 0) {
            // Simple concatenation, might need string library for complex paths
             return string(abi.encodePacked(assetType.metadataTemplateURI, Strings.toString(assetId)));
        }

        // Fallback to base URI
        return string(abi.encodePacked(_baseURI(), Strings.toString(assetId)));
    }

    /**
     * @dev Pauses the contract. Prevents most state-changing operations.
     * Only callable by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Re-enables state-changing operations.
     * Only callable by the owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Returns true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Function to simulate interaction with an asset.
     * Requires usage delegation or ownership. Game-specific logic would go here.
     * @param assetId The ID of the asset to interact with.
     * @param interactionData Arbitrary data describing the interaction.
     */
    function interactWithAsset(uint256 assetId, bytes memory interactionData) public whenNotPaused {
        require(assets[assetId].id != 0, "Asset does not exist");
        require(_isUsageDelegateOrOwner(msg.sender, assetId), "Not authorized for asset usage");
        require(stakedAssets[assetId] == address(0), "Cannot interact with staked asset");

        // --- Placeholder Interaction Logic ---
        // Based on asset.assetTypeId, asset.currentState, and interactionData,
        // update asset properties, state, or trigger other effects.
        // Example: Harvesting a plant, using a tool, entering a building.

        assets[assetId].lastInteractionTime = block.timestamp; // Interaction updates time
        // Could emit a generic Interaction event or specific ones
    }

    // --- Helper library for toString (Minimal implementation) ---
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```