Okay, here is a Solidity smart contract implementing a concept I'll call "Decentralized Creative Commons & Collaboration Platform". It allows creators to register digital assets, assign on-chain licenses (similar to Creative Commons), track derivatives (remixes, adaptations), manage multiple contributors with revenue splits, and handle simple on-chain revenue distribution.

This contract is designed to be interesting by:

1.  **On-Chain Licensing:** Representing and checking license compatibility for derivatives.
2.  **Provenance Tracking:** Linking derivatives back to parent assets, creating a chain of creation.
3.  **Collaborative Ownership/Revenue Sharing:** Handling multiple contributors and automated revenue distribution based on splits.
4.  **Role-Based Access:** Specific actions restricted to owners, contributors, or the contract owner.
5.  **Moderation Hooks:** Simple reporting and flagging mechanism.

It aims to be advanced and non-standard by combining these features in a single contract, going beyond typical token or simple DAO patterns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedCreativeCommons
 * @dev A smart contract for registering digital assets, managing on-chain licenses,
 *      tracking derivatives, and handling collaborative revenue sharing.
 *      This contract is NOT a replacement for off-chain legal agreements or copyright law,
 *      but provides an on-chain mechanism to record, track, and facilitate collaboration
 *      and revenue distribution based on defined licenses.
 */

/**
 * @dev OUTLINE:
 * 1. License Types (Enum)
 * 2. Structs for Asset and Contributor
 * 3. State Variables (Assets, Contributors, Provenance, etc.)
 * 4. Events
 * 5. Modifiers (Ownership, Pausable, Contributor Check)
 * 6. Core Logic Functions:
 *    - Asset Registration (Original & Derivative)
 *    - License Management (Setting & Compatibility)
 *    - Contributor Management (Add, Remove, Update Splits)
 *    - Revenue Sharing (Funding & Distribution)
 * 7. Query/View Functions
 * 8. Reporting/Moderation Functions
 * 9. Admin Functions (Pause, Ownership)
 */

/**
 * @dev FUNCTION SUMMARY:
 *
 * --- CORE ASSET & LICENSE ---
 * - registerAsset(string _metadataURI, LicenseType _licenseType, address[] _contributors, uint256[] _splitPercentages): Registers a new original asset.
 * - registerDerivative(uint256 _parentAssetId, string _metadataURI, LicenseType _derivativeLicenseType, address[] _contributors, uint256[] _splitPercentages): Registers an asset as a derivative of an existing one, checking license compatibility.
 * - updateAssetMetadata(uint256 _assetId, string _newMetadataURI): Updates the metadata URI for an asset (owner/contributor only).
 * - updateAssetLicense(uint256 _assetId, LicenseType _newLicenseType): Updates the license for an asset (owner only, potentially restricted).
 * - transferAssetOwnership(uint256 _assetId, address _newOwner): Transfers ownership of an asset (current owner only).
 *
 * --- CONTRIBUTOR MANAGEMENT ---
 * - addContributor(uint256 _assetId, address _contributor, uint256 _splitPercentage): Adds a contributor to an asset (owner/existing contributor only).
 * - removeContributor(uint256 _assetId, address _contributor): Removes a contributor from an asset (owner/existing contributor only).
 * - updateContributorSplit(uint256 _assetId, address _contributor, uint256 _newSplitPercentage): Updates a contributor's revenue split (owner/existing contributor only).
 *
 * --- REVENUE SHARING ---
 * - fundAsset(uint256 _assetId): Allows sending Ether to the contract for a specific asset's revenue distribution.
 * - distributeRevenue(uint256 _assetId): Distributes collected Ether for an asset among its contributors based on their splits.
 *
 * --- QUERY / VIEW FUNCTIONS ---
 * - getAsset(uint256 _assetId): Gets all details for a given asset.
 * - getAssetLicense(uint256 _assetId): Gets the license type of an asset.
 * - getAssetOwner(uint256 _assetId): Gets the owner address of an asset.
 * - getAssetMetadataURI(uint256 _assetId): Gets the metadata URI of an asset.
 * - isDerivative(uint256 _assetId): Checks if an asset is a derivative.
 * - getParentAsset(uint256 _assetId): Gets the parent asset ID if it's a derivative (returns 0 otherwise).
 * - getContributors(uint256 _assetId): Gets the list of contributor addresses for an asset.
 * - getContributorSplit(uint256 _assetId, address _contributor): Gets the split percentage for a specific contributor.
 * - getAssetsByOwner(address _owner): Gets a list of asset IDs owned by an address. (Simplified: fetches up to a limit or requires external indexer) - *Note: Returning large arrays is gas intensive. This is a simplified example.*
 * - getDerivatives(uint256 _parentAssetId): Gets a list of asset IDs that are derivatives of a parent. (Simplified: similar gas note as above).
 * - getTotalAssets(): Gets the total number of registered assets.
 * - checkContributorExists(uint256 _assetId, address _contributor): Checks if an address is a contributor for an asset.
 * - isLicenseCompatibleView(LicenseType _parentLicense, LicenseType _derivativeLicense): Public view function to check license compatibility.
 *
 * --- REPORTING / MODERATION ---
 * - reportAsset(uint256 _assetId, string _reason): Allows anyone to report an asset.
 * - getAssetReports(uint256 _assetId): Gets the list of reasons an asset has been reported.
 * - flagAsset(uint256 _assetId): Admin function to officially flag a reported asset.
 * - resolveFlag(uint256 _assetId): Admin function to unflag an asset.
 * - getFlaggedAssets(): Gets a list of currently flagged asset IDs.
 *
 * --- ADMIN ---
 * - pauseContract(): Pauses core functionality (Owner only).
 * - unpauseContract(): Unpauses the contract (Owner only).
 * - renounceOwnership(): Renounce contract ownership (Owner only).
 * - transferOwnership(address _newOwner): Transfer contract ownership (Owner only).
 *
 * Total Functions: 5 (Asset Core) + 3 (Contributor) + 2 (Revenue) + 13 (Query) + 5 (Reporting) + 4 (Admin) = 32 functions.
 */

contract DecentralizedCreativeCommons {

    // --- 1. License Types ---
    // Simplistic Creative Commons-like licenses for on-chain representation.
    // Note: Real CC licenses have more nuances (e.g., SA needs same license type),
    // and this is a simplified interpretation for smart contract logic.
    enum LicenseType {
        NoRightsReserved,       // Effectively Public Domain (CCO)
        Attribution,            // Must give credit
        AttributionShareAlike,  // Must give credit, new work must be under same license
        AttributionNoDerivatives // Must give credit, no changes allowed
    }

    // --- 2. Structs ---
    struct Asset {
        uint256 id;                 // Unique identifier for the asset
        address payable owner;      // Wallet address of the primary owner (can be a multisig or another contract)
        string metadataURI;         // URI pointing to off-chain metadata (e.g., IPFS hash, URL)
        LicenseType licenseType;    // The license applied to this asset
        bool isDerivative;          // True if this asset is derived from another
        uint256 parentAssetId;      // ID of the parent asset if isDerivative is true (0 otherwise)
        uint256 creationTimestamp;  // Timestamp when the asset was registered
        bool active;                // Is the asset currently active and not flagged/removed?
        address[] contributorAddresses; // List of contributor addresses
        mapping(address => uint256) contributorSplits; // Map of contributor address to their percentage split (out of 10000)
        uint256 totalSplitPercentage; // Sum of all contributor splits for quick validation
    }

    // --- 3. State Variables ---
    uint256 public nextAssetId = 1; // Counter for unique asset IDs
    mapping(uint256 => Asset) public assets; // Mapping from asset ID to Asset struct
    mapping(uint256 => uint256) public assetBalances; // Balance of Ether held for revenue distribution per asset
    mapping(address => uint256[]) private ownerToAssets; // Mapping from owner address to list of owned asset IDs (Simplified)
    mapping(uint256 => uint256[]) private parentToDerivatives; // Mapping from parent asset ID to list of derivative asset IDs (Simplified)
    mapping(uint256 => string[]) private assetReports; // Mapping from asset ID to list of report reasons
    mapping(uint256 => bool) public isAssetFlagged; // Mapping to track flagged assets
    uint256[] private flaggedAssetIds; // List of currently flagged asset IDs

    address private _owner; // Contract owner for admin functions
    bool private _paused;   // Paused state

    // --- 4. Events ---
    event AssetRegistered(uint256 indexed assetId, address indexed owner, LicenseType licenseType, string metadataURI, bool isDerivative, uint256 parentAssetId);
    event MetadataUpdated(uint256 indexed assetId, string newMetadataURI);
    event LicenseUpdated(uint256 indexed assetId, LicenseType newLicenseType);
    event OwnershipTransferred(uint256 indexed assetId, address indexed oldOwner, address indexed newOwner);
    event ContributorAdded(uint256 indexed assetId, address indexed contributor, uint256 splitPercentage);
    event ContributorRemoved(uint256 indexed assetId, address indexed contributor);
    event ContributorSplitUpdated(uint256 indexed assetId, address indexed contributor, uint256 newSplitPercentage);
    event RevenueFunded(uint256 indexed assetId, address indexed funder, uint256 amount);
    event RevenueDistributed(uint256 indexed assetId, uint256 totalAmount, address indexed initiator);
    event AssetReported(uint256 indexed assetId, address indexed reporter, string reason);
    event AssetFlagged(uint256 indexed assetId, address indexed flagger);
    event AssetUnflagged(uint256 indexed assetId, address indexed unflaggedBy);
    event Paused(address account);
    event Unpaused(address account);
    event ContractOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- 5. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyAssetOwnerOrContributor(uint256 _assetId) {
        Asset storage asset = assets[_assetId];
        require(asset.active, "Asset not active"); // Implicit check if asset exists (id > 0) and is active
        bool isContributor = false;
        for(uint i = 0; i < asset.contributorAddresses.length; i++) {
            if (asset.contributorAddresses[i] == msg.sender) {
                isContributor = true;
                break;
            }
        }
        require(msg.sender == asset.owner || isContributor, "Only asset owner or contributor can call");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
    }

    // --- Admin Functions (Manual Ownable Implementation) ---
    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit ContractOwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit ContractOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // --- Admin Functions (Manual Pausable Implementation) ---
    function paused() public view returns (bool) {
        return _paused;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- INTERNAL HELPERS ---

    /**
     * @dev Checks if a derivative license is compatible with a parent license.
     * Simplified logic based loosely on CC principles:
     * - NoRightsReserved (CCO) allows anything.
     * - Attribution allows Attribution or more permissive.
     * - AttributionShareAlike requires AttributionShareAlike.
     * - AttributionNoDerivatives allows only AttributionNoDerivatives (effectively, no changes allowed).
     */
    function _isLicenseCompatible(LicenseType _parentLicense, LicenseType _derivativeLicense) internal pure returns (bool) {
        if (_parentLicense == LicenseType.NoRightsReserved) {
            return true; // Anything is compatible with Public Domain / CCO
        }
        if (_parentLicense == LicenseType.Attribution) {
            // Attribution allows Attribution, AttributionShareAlike, or NoRightsReserved (more permissive)
            return _derivativeLicense == LicenseType.Attribution ||
                   _derivativeLicense == LicenseType.AttributionShareAlike ||
                   _derivativeLicense == LicenseType.NoRightsReserved;
        }
        if (_parentLicense == LicenseType.AttributionShareAlike) {
            // AttributionShareAlike requires the derivative to also be ShareAlike or Public Domain (more permissive)
            return _derivativeLicense == LicenseType.AttributionShareAlike ||
                   _derivativeLicense == LicenseType.NoRightsReserved;
        }
        if (_parentLicense == LicenseType.AttributionNoDerivatives) {
            // NoDerivatives allows ONLY AttributionNoDerivatives (no changes) or Public Domain
            return _derivativeLicense == LicenseType.AttributionNoDerivatives ||
                   _derivativeLicense == LicenseType.NoRightsReserved;
        }
        return false; // Should not reach here
    }

     /**
      * @dev Adds a contributor to the asset's internal lists.
      * @param _assetId The ID of the asset.
      * @param _contributor The address of the contributor to add.
      * @param _splitPercentage The revenue split percentage for the contributor (out of 10000).
      */
    function _addContributorInternal(uint256 _assetId, address _contributor, uint256 _splitPercentage) internal {
        Asset storage asset = assets[_assetId];
        require(asset.contributorSplits[_contributor] == 0, "Contributor already exists");
        require(_splitPercentage > 0, "Split percentage must be greater than 0");

        asset.contributorAddresses.push(_contributor);
        asset.contributorSplits[_contributor] = _splitPercentage;
        asset.totalSplitPercentage += _splitPercentage;

        emit ContributorAdded(_assetId, _contributor, _splitPercentage);
    }

    /**
     * @dev Updates a contributor's split percentage.
     * @param _assetId The ID of the asset.
     * @param _contributor The address of the contributor.
     * @param _newSplitPercentage The new revenue split percentage (out of 10000).
     */
    function _updateContributorSplitInternal(uint256 _assetId, address _contributor, uint256 _newSplitPercentage) internal {
         Asset storage asset = assets[_assetId];
         uint256 oldSplit = asset.contributorSplits[_contributor];
         require(oldSplit > 0, "Contributor does not exist");
         require(_newSplitPercentage > 0, "New split percentage must be greater than 0");

         asset.totalSplitPercentage -= oldSplit;
         asset.contributorSplits[_contributor] = _newSplitPercentage;
         asset.totalSplitPercentage += _newSplitPercentage;

         emit ContributorSplitUpdated(_assetId, _contributor, _newSplitPercentage);
    }

     /**
      * @dev Removes a contributor from the asset's internal lists.
      * @param _assetId The ID of the asset.
      * @param _contributor The address of the contributor to remove.
      */
    function _removeContributorInternal(uint256 _assetId, address _contributor) internal {
         Asset storage asset = assets[_assetId];
         uint256 oldSplit = asset.contributorSplits[_contributor];
         require(oldSplit > 0, "Contributor does not exist");
         require(asset.contributorAddresses.length > 1, "Cannot remove the only contributor"); // Ensure at least one remains

         // Find and remove from dynamic array
         bool found = false;
         for(uint i = 0; i < asset.contributorAddresses.length; i++) {
             if (asset.contributorAddresses[i] == _contributor) {
                 // Swap with last element and pop
                 asset.contributorAddresses[i] = asset.contributorAddresses[asset.contributorAddresses.length - 1];
                 asset.contributorAddresses.pop();
                 found = true;
                 break;
             }
         }
         require(found, "Contributor not found in list"); // Should not happen if oldSplit > 0

         // Remove from mapping and update total
         delete asset.contributorSplits[_contributor];
         asset.totalSplitPercentage -= oldSplit;

         emit ContributorRemoved(_assetId, _contributor);
    }

    // --- 6. Core Logic Functions ---

    /**
     * @dev Registers a new original asset.
     * @param _metadataURI URI pointing to off-chain metadata.
     * @param _licenseType The license type for this asset.
     * @param _contributors Array of contributor addresses.
     * @param _splitPercentages Array of split percentages (out of 10000) corresponding to contributors.
     */
    function registerAsset(
        string memory _metadataURI,
        LicenseType _licenseType,
        address[] memory _contributors,
        uint256[] memory _splitPercentages
    ) public whenNotPaused returns (uint256) {
        require(bytes(_metadataURI).length > 0, "Metadata URI is required");
        require(_contributors.length > 0, "At least one contributor is required");
        require(_contributors.length == _splitPercentages.length, "Contributor and split arrays must match");

        uint256 currentAssetId = nextAssetId;

        // Create the asset struct
        Asset storage newAsset = assets[currentAssetId];
        newAsset.id = currentAssetId;
        newAsset.owner = payable(msg.sender); // Creator is initially the owner
        newAsset.metadataURI = _metadataURI;
        newAsset.licenseType = _licenseType;
        newAsset.isDerivative = false;
        newAsset.parentAssetId = 0; // No parent
        newAsset.creationTimestamp = block.timestamp;
        newAsset.active = true;

        // Add contributors and calculate total split
        uint256 totalSplit = 0;
        for (uint i = 0; i < _contributors.length; i++) {
            address contributor = _contributors[i];
            uint256 split = _splitPercentages[i];
            require(contributor != address(0), "Contributor address cannot be zero");
            require(newAsset.contributorSplits[contributor] == 0, "Duplicate contributor in list");
            require(split > 0, "Split percentage must be positive");

            newAsset.contributorAddresses.push(contributor);
            newAsset.contributorSplits[contributor] = split;
            totalSplit += split;
        }
        require(totalSplit <= 10000, "Total split percentage exceeds 100%");
        newAsset.totalSplitPercentage = totalSplit;


        // Update internal tracking mappings (Simplified)
        ownerToAssets[msg.sender].push(currentAssetId);

        emit AssetRegistered(
            currentAssetId,
            msg.sender,
            _licenseType,
            _metadataURI,
            false,
            0
        );

        nextAssetId++;
        return currentAssetId;
    }

     /**
     * @dev Registers an asset as a derivative of an existing one.
     * Checks for license compatibility between parent and derivative.
     * @param _parentAssetId The ID of the asset this new asset is derived from.
     * @param _metadataURI URI pointing to off-chain metadata for the derivative.
     * @param _derivativeLicenseType The license type for this derivative asset.
     * @param _contributors Array of contributor addresses for the derivative.
     * @param _splitPercentages Array of split percentages (out of 10000) for the derivative's contributors.
     */
    function registerDerivative(
        uint256 _parentAssetId,
        string memory _metadataURI,
        LicenseType _derivativeLicenseType,
        address[] memory _contributors,
        uint256[] memory _splitPercentages
    ) public whenNotPaused returns (uint256) {
        require(_parentAssetId > 0 && _parentAssetId < nextAssetId && assets[_parentAssetId].active, "Parent asset does not exist or is inactive");
        require(bytes(_metadataURI).length > 0, "Metadata URI is required");
        require(_contributors.length > 0, "At least one contributor is required");
        require(_contributors.length == _splitPercentages.length, "Contributor and split arrays must match");

        Asset storage parentAsset = assets[_parentAssetId];

        // Check license compatibility
        require(_isLicenseCompatible(parentAsset.licenseType, _derivativeLicenseType), "Derivative license is not compatible with parent license");

        uint256 currentAssetId = nextAssetId;

        // Create the derivative asset struct
        Asset storage newAsset = assets[currentAssetId];
        newAsset.id = currentAssetId;
        newAsset.owner = payable(msg.sender); // Creator is initially the owner
        newAsset.metadataURI = _metadataURI;
        newAsset.licenseType = _derivativeLicenseType;
        newAsset.isDerivative = true;
        newAsset.parentAssetId = _parentAssetId;
        newAsset.creationTimestamp = block.timestamp;
        newAsset.active = true;

         // Add contributors and calculate total split
        uint256 totalSplit = 0;
        for (uint i = 0; i < _contributors.length; i++) {
            address contributor = _contributors[i];
            uint256 split = _splitPercentages[i];
            require(contributor != address(0), "Contributor address cannot be zero");
            require(newAsset.contributorSplits[contributor] == 0, "Duplicate contributor in list");
            require(split > 0, "Split percentage must be positive");

            newAsset.contributorAddresses.push(contributor);
            newAsset.contributorSplits[contributor] = split;
            totalSplit += split;
        }
        require(totalSplit <= 10000, "Total split percentage exceeds 100%");
        newAsset.totalSplitPercentage = totalSplit;


        // Update internal tracking mappings (Simplified)
        ownerToAssets[msg.sender].push(currentAssetId);
        parentToDerivatives[_parentAssetId].push(currentAssetId);

        emit AssetRegistered(
            currentAssetId,
            msg.sender,
            _derivativeLicenseType,
            _metadataURI,
            true,
            _parentAssetId
        );

        nextAssetId++;
        return currentAssetId;
    }

    /**
     * @dev Updates the metadata URI for an asset.
     * Only the asset owner or a contributor can call this (with owner ultimately controlling).
     * @param _assetId The ID of the asset to update.
     * @param _newMetadataURI The new URI pointing to metadata.
     */
    function updateAssetMetadata(uint256 _assetId, string memory _newMetadataURI)
        public whenNotPaused onlyAssetOwnerOrContributor(_assetId)
    {
        require(bytes(_newMetadataURI).length > 0, "Metadata URI is required");
        assets[_assetId].metadataURI = _newMetadataURI;
        emit MetadataUpdated(_assetId, _newMetadataURI);
    }

    /**
     * @dev Updates the license type for an asset.
     * Only the asset owner can call this.
     * Note: Changing licenses *after* derivatives exist can be complex legally.
     * This contract only enforces compatibility *at the time of derivative registration*.
     * @param _assetId The ID of the asset to update.
     * @param _newLicenseType The new license type.
     */
    function updateAssetLicense(uint256 _assetId, LicenseType _newLicenseType)
        public whenNotPaused
    {
        Asset storage asset = assets[_assetId];
        require(asset.active, "Asset not active");
        require(msg.sender == asset.owner, "Only asset owner can update license");

        asset.licenseType = _newLicenseType;
        emit LicenseUpdated(_assetId, _newLicenseType);
    }

    /**
     * @dev Transfers ownership of an asset to a new address.
     * Only the current asset owner can call this.
     * @param _assetId The ID of the asset.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferAssetOwnership(uint256 _assetId, address payable _newOwner)
        public whenNotPaused
    {
        Asset storage asset = assets[_assetId];
        require(asset.active, "Asset not active");
        require(msg.sender == asset.owner, "Only asset owner can transfer ownership");
        require(_newOwner != address(0), "New owner cannot be the zero address");

        address oldOwner = asset.owner;
        asset.owner = _newOwner;

        // Update owner mapping (Simplified - requires rebuilding or external indexer for efficiency)
        // In a real application, iterating and removing from ownerToAssets[_oldOwner] would be gas intensive.
        // For this example, we'll just note that _newOwner now owns it and accept the inefficiency of querying.
        ownerToAssets[_newOwner].push(_assetId); // Simply add to new owner's list

        emit OwnershipTransferred(_assetId, oldOwner, _newOwner);
    }

    // --- Contributor Management ---

    /**
     * @dev Adds a contributor to an asset.
     * Only the asset owner or an existing contributor can call this.
     * Requires that adding the contributor doesn't exceed 100% total split.
     * @param _assetId The ID of the asset.
     * @param _contributor The address of the contributor to add.
     * @param _splitPercentage The revenue split percentage for the new contributor (out of 10000).
     */
    function addContributor(uint256 _assetId, address _contributor, uint256 _splitPercentage)
        public whenNotPaused onlyAssetOwnerOrContributor(_assetId)
    {
        Asset storage asset = assets[_assetId];
        require(asset.totalSplitPercentage + _splitPercentage <= 10000, "Adding contributor exceeds 100% total split");
        _addContributorInternal(_assetId, _contributor, _splitPercentage);
    }

     /**
     * @dev Removes a contributor from an asset.
     * Only the asset owner or an existing contributor can call this.
     * Cannot remove the only contributor.
     * @param _assetId The ID of the asset.
     * @param _contributor The address of the contributor to remove.
     */
    function removeContributor(uint256 _assetId, address _contributor)
        public whenNotPaused onlyAssetOwnerOrContributor(_assetId)
    {
         // Prevent removing the owner if they are also a contributor
         require(assets[_assetId].owner != _contributor, "Cannot remove owner as a contributor via this function");
         _removeContributorInternal(_assetId, _contributor);
    }

     /**
     * @dev Updates a contributor's split percentage.
     * Only the asset owner or an existing contributor can call this.
     * Requires that the new split doesn't cause the total split to exceed 100%.
     * @param _assetId The ID of the asset.
     * @param _contributor The address of the contributor.
     * @param _newSplitPercentage The new revenue split percentage (out of 10000).
     */
    function updateContributorSplit(uint256 _assetId, address _contributor, uint256 _newSplitPercentage)
        public whenNotPaused onlyAssetOwnerOrContributor(_assetId)
    {
        Asset storage asset = assets[_assetId];
        uint256 oldSplit = asset.contributorSplits[_contributor];
        require(oldSplit > 0, "Contributor does not exist for this asset");
        require(asset.totalSplitPercentage - oldSplit + _newSplitPercentage <= 10000, "Updating split exceeds 100% total split");
        _updateContributorSplitInternal(_assetId, _contributor, _newSplitPercentage);
    }


    // --- Revenue Sharing ---

    /**
     * @dev Allows sending Ether to the contract earmarked for a specific asset's revenue.
     * @param _assetId The ID of the asset to fund.
     */
    function fundAsset(uint256 _assetId) public payable whenNotPaused {
        require(_assetId > 0 && _assetId < nextAssetId && assets[_assetId].active, "Asset does not exist or is inactive");
        require(msg.value > 0, "Amount must be greater than 0");

        assetBalances[_assetId] += msg.value;

        emit RevenueFunded(_assetId, msg.sender, msg.value);
    }

    /**
     * @dev Distributes the collected Ether for an asset among its contributors.
     * Any contributor or the owner can trigger this.
     * Distributes based on current splits. The entire balance for the asset is sent.
     * Reverts if total split is 0 or > 100%.
     * Uses call{value: ...} for safer Ether transfer.
     * @param _assetId The ID of the asset to distribute revenue for.
     */
    function distributeRevenue(uint256 _assetId)
        public whenNotPaused onlyAssetOwnerOrContributor(_assetId)
    {
        Asset storage asset = assets[_assetId];
        uint256 balanceToDistribute = assetBalances[_assetId];
        require(balanceToDistribute > 0, "No balance to distribute for this asset");
        require(asset.totalSplitPercentage > 0, "No contributors or total split is zero");
        require(asset.totalSplitPercentage <= 10000, "Total split percentage exceeds 100%");

        assetBalances[_assetId] = 0; // Reset balance before sending to prevent reentrancy issues

        uint256 remainingBalance = balanceToDistribute;
        uint256 distributedAmount = 0;

        for (uint i = 0; i < asset.contributorAddresses.length; i++) {
            address payable contributor = payable(asset.contributorAddresses[i]);
            uint256 split = asset.contributorSplits[contributor];
            if (split > 0) { // Only distribute to contributors with a positive split
                uint256 share = (balanceToDistribute * split) / 10000;

                // Ensure we don't try to send more than remaining or introduce rounding errors by sending less on the last one
                if (i == asset.contributorAddresses.length - 1) {
                     share = remainingBalance; // Send remaining balance to the last contributor
                } else {
                    // Cap share to remaining balance if floating point arithmetic issues somehow occurred
                     if (share > remainingBalance) {
                         share = remainingBalance;
                     }
                }

                if (share > 0) {
                    (bool success, ) = contributor.call{value: share}("");
                    // Log success/failure? For simplicity, we'll just proceed.
                    // A failed transfer means that contributor doesn't get their share in this round.
                    // The remainingBalance calculation below accounts for successful sends.
                    if (success) {
                         remainingBalance -= share;
                         distributedAmount += share;
                    }
                }
            }
        }

        // Optional: Handle any dust remaining in remainingBalance if transfers failed unexpectedly
        // For simplicity, we'll let it stay in the contract unless explicitly handled.
        // In a robust system, remainingBalance should be 0 or sent to a fallback.

        emit RevenueDistributed(_assetId, distributedAmount, msg.sender);
    }

    // --- 7. Query / View Functions ---

    /**
     * @dev Gets all details for a given asset.
     * @param _assetId The ID of the asset.
     * @return Asset struct data.
     */
    function getAsset(uint256 _assetId) public view returns (
        uint256 id,
        address owner,
        string memory metadataURI,
        LicenseType licenseType,
        bool isDerivative,
        uint256 parentAssetId,
        uint256 creationTimestamp,
        bool active,
        address[] memory contributorAddresses
    ) {
        require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
        Asset storage asset = assets[_assetId];
        return (
            asset.id,
            asset.owner,
            asset.metadataURI,
            asset.licenseType,
            asset.isDerivative,
            asset.parentAssetId,
            asset.creationTimestamp,
            asset.active,
            asset.contributorAddresses // Note: This returns a copy of the dynamic array
        );
    }

    /**
     * @dev Gets the license type of an asset.
     * @param _assetId The ID of the asset.
     * @return The license type.
     */
    function getAssetLicense(uint256 _assetId) public view returns (LicenseType) {
         require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
         return assets[_assetId].licenseType;
    }

    /**
     * @dev Gets the owner address of an asset.
     * @param _assetId The ID of the asset.
     * @return The owner address.
     */
    function getAssetOwner(uint256 _assetId) public view returns (address) {
         require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
         return assets[_assetId].owner;
    }

    /**
     * @dev Gets the metadata URI of an asset.
     * @param _assetId The ID of the asset.
     * @return The metadata URI.
     */
    function getAssetMetadataURI(uint256 _assetId) public view returns (string memory) {
         require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
         return assets[_assetId].metadataURI;
    }

    /**
     * @dev Checks if an asset is a derivative.
     * @param _assetId The ID of the asset.
     * @return True if it's a derivative, false otherwise.
     */
    function isDerivative(uint256 _assetId) public view returns (bool) {
         require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
         return assets[_assetId].isDerivative;
    }

    /**
     * @dev Gets the parent asset ID if the asset is a derivative.
     * @param _assetId The ID of the asset.
     * @return The parent asset ID, or 0 if it's not a derivative.
     */
    function getParentAsset(uint256 _assetId) public view returns (uint256) {
        require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
        return assets[_assetId].parentAssetId;
    }

    /**
     * @dev Gets the list of contributor addresses for an asset.
     * @param _assetId The ID of the asset.
     * @return An array of contributor addresses.
     */
    function getContributors(uint256 _assetId) public view returns (address[] memory) {
        require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
        return assets[_assetId].contributorAddresses;
    }

     /**
     * @dev Gets the split percentage for a specific contributor of an asset.
     * @param _assetId The ID of the asset.
     * @param _contributor The address of the contributor.
     * @return The split percentage (out of 10000). Returns 0 if not a contributor.
     */
    function getContributorSplit(uint256 _assetId, address _contributor) public view returns (uint256) {
        require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
        return assets[_assetId].contributorSplits[_contributor];
    }

    /**
     * @dev Gets a list of asset IDs owned by a specific address.
     * NOTE: This can be gas-intensive if an address owns many assets.
     * In a production system, consider pagination or rely on off-chain indexing.
     * @param _owner The address to query.
     * @return An array of asset IDs.
     */
    function getAssetsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerToAssets[_owner];
    }

    /**
     * @dev Gets a list of asset IDs that are derivatives of a parent asset.
     * NOTE: This can be gas-intensive if an asset has many derivatives.
     * In a production system, consider pagination or rely on off-chain indexing.
     * @param _parentAssetId The ID of the parent asset.
     * @return An array of derivative asset IDs.
     */
    function getDerivatives(uint256 _parentAssetId) public view returns (uint256[] memory) {
        require(_parentAssetId > 0 && _parentAssetId < nextAssetId, "Parent asset does not exist");
        return parentToDerivatives[_parentAssetId];
    }

    /**
     * @dev Gets the total number of registered assets.
     * @return The total count of assets.
     */
    function getTotalAssets() public view returns (uint256) {
        return nextAssetId - 1; // nextAssetId is 1-based counter
    }

    /**
     * @dev Checks if an address is a contributor for a specific asset.
     * @param _assetId The ID of the asset.
     * @param _contributor The address to check.
     * @return True if the address is a contributor, false otherwise.
     */
    function checkContributorExists(uint256 _assetId, address _contributor) public view returns (bool) {
         require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
         return assets[_assetId].contributorSplits[_contributor] > 0;
    }

     /**
     * @dev Public view function to check license compatibility using the internal helper.
     * @param _parentLicense The license of the potential parent asset.
     * @param _derivativeLicense The license of the potential derivative asset.
     * @return True if the derivative license is compatible with the parent license.
     */
    function isLicenseCompatibleView(LicenseType _parentLicense, LicenseType _derivativeLicense) public pure returns (bool) {
        return _isLicenseCompatible(_parentLicense, _derivativeLicense);
    }

    // --- 8. Reporting / Moderation ---

    /**
     * @dev Allows anyone to report an asset, e.g., for violating terms, containing illegal content etc.
     * This is a basic reporting mechanism, not an on-chain content filter.
     * @param _assetId The ID of the asset to report.
     * @param _reason The reason for the report.
     */
    function reportAsset(uint256 _assetId, string memory _reason) public whenNotPaused {
        require(_assetId > 0 && _assetId < nextAssetId && assets[_assetId].active, "Asset does not exist or is inactive");
        require(bytes(_reason).length > 0, "Report reason cannot be empty");

        assetReports[_assetId].push(_reason);

        emit AssetReported(_assetId, msg.sender, _reason);
    }

    /**
     * @dev Gets the list of reasons an asset has been reported.
     * @param _assetId The ID of the asset.
     * @return An array of report reasons.
     */
    function getAssetReports(uint256 _assetId) public view returns (string[] memory) {
        require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
        return assetReports[_assetId];
    }

    /**
     * @dev Admin function to officially flag a reported asset.
     * Flagging could indicate it's under review or potentially hidden by frontends.
     * Does not automatically disable the asset.
     * @param _assetId The ID of the asset to flag.
     */
    function flagAsset(uint256 _assetId) public onlyOwner whenNotPaused {
        require(_assetId > 0 && _assetId < nextAssetId && assets[_assetId].active, "Asset does not exist or is inactive");
        require(!isAssetFlagged[_assetId], "Asset is already flagged");

        isAssetFlagged[_assetId] = true;
        flaggedAssetIds.push(_assetId);

        emit AssetFlagged(_assetId, msg.sender);
    }

    /**
     * @dev Admin function to unflag an asset.
     * @param _assetId The ID of the asset to unflag.
     */
    function resolveFlag(uint256 _assetId) public onlyOwner whenNotPaused {
        require(_assetId > 0 && _assetId < nextAssetId, "Asset does not exist");
        require(isAssetFlagged[_assetId], "Asset is not flagged");

        isAssetFlagged[_assetId] = false;

        // Remove from flaggedAssetIds list (inefficient for large lists)
        for(uint i = 0; i < flaggedAssetIds.length; i++) {
            if (flaggedAssetIds[i] == _assetId) {
                flaggedAssetIds[i] = flaggedAssetIds[flaggedAssetIds.length - 1];
                flaggedAssetIds.pop();
                break;
            }
        }

        emit AssetUnflagged(_assetId, msg.sender);
    }

    /**
     * @dev Gets a list of currently flagged asset IDs.
     * NOTE: This can be gas-intensive for large numbers of flagged assets.
     * @return An array of flagged asset IDs.
     */
    function getFlaggedAssets() public view returns (uint256[] memory) {
        return flaggedAssetIds;
    }

    // --- Receive Ether ---
    // Allows the contract to receive raw ETH, though funding should preferably use fundAsset
    receive() external payable {
        // Optionally log or handle received funds not associated with an asset ID
        // For this example, we'll just let it increase the contract's balance
        // without associating it to a specific asset balance unless fundAsset is called.
    }
}
```