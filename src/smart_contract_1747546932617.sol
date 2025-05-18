Okay, let's create a smart contract for a "Decentralized Tokenized Data Licensing Marketplace". This contract will allow users to list datasets (represented by metadata and a content hash, likely stored off-chain like IPFS), set a price in a specific ERC-20 token, and users can purchase a license to access this data. The license is represented by an ERC-721 NFT, which acts as the proof of ownership for accessing the data. The contract will handle payments, fee distribution, and include roles like providers and curators.

It incorporates:
1.  **Tokenized Licenses:** Using ERC-721 NFTs as access tokens.
2.  **ERC-20 Payments:** Using a specified ERC-20 token for transactions.
3.  **Marketplace Logic:** Listing, purchasing, fee collection, provider earnings.
4.  **Curation Layer:** Introducing a `Curator` role to flag or verify data quality (though actual data verification happens off-chain, the contract tracks the curator's assessment).
5.  **Revenue Splits:** Allowing providers to specify a split percentage for another address.
6.  **Pausable/Ownable:** Standard administrative controls.

This combines elements of marketplaces, NFTs, ERC-20 interactions, and role-based access control in a non-standard data context, aiming for novelty.

---

**Outline:**

1.  **License & Version:** SPDX License Identifier and Solidity version.
2.  **Imports:** ERC721Enumerable, Ownable, Pausable, SafeERC20.
3.  **Errors:** Custom errors for clarity.
4.  **Events:** Log key actions (Registration, Purchase, Flagging, etc.).
5.  **Structs:**
    *   `DataSet`: Details about the listed data (provider, price, hash, status, split info).
    *   `DataLicense`: Details about the minted license NFT (dataSetId).
6.  **State Variables:**
    *   Counters for data sets and licenses.
    *   Mappings for DataSets, DataLicenses, LicenseId to DataSetId.
    *   Fee percentage, payment token address.
    *   Mapping for provider/admin earnings.
    *   Mapping for curator addresses.
    *   Mapping for flagged/verified datasets.
7.  **Modifiers:** `onlyProvider`, `onlyCurator`.
8.  **Constructor:** Initializes Ownable, Pausable, sets initial token/fee.
9.  **Admin Functions (Ownable):**
    *   `setDataToken`: Set the ERC-20 token used for payments.
    *   `setFeePercentage`: Set the marketplace fee.
    *   `addCurator`: Add an address to the curator role.
    *   `removeCurator`: Remove an address from the curator role.
    *   `pause`/`unpause`: Pause/Unpause marketplace activity.
    *   `withdrawFeeEarnings`: Withdraw collected platform fees.
10. **Provider Functions:**
    *   `registerDataSet`: List a new dataset for sale.
    *   `updateDataSetPrice`: Change the price of a dataset.
    *   `updateDataSetMetadataHash`: Update the metadata hash (e.g., for a new version).
    *   `deactivateDataSet`: Make a dataset unpurchasable.
    *   `withdrawProviderEarnings`: Claim accumulated earnings from sales.
11. **Buyer Functions:**
    *   `purchaseDataLicense`: Buy a license for a dataset (mints NFT).
12. **Curator Functions:**
    *   `flagDataSet`: Mark a dataset as potentially problematic.
    *   `verifyDataSet`: Mark a dataset as verified/high quality.
13. **View Functions (>10):**
    *   Get counts (data sets, licenses).
    *   Get details (data set, license).
    *   Check status (flagged, verified, has license).
    *   Get config (fee, token, curators).
    *   Get user-specific info (provider datasets, owned licenses).
    *   Get earnings balances.
14. **ERC721 Overrides (from Enumerable):**
    *   `tokenURI`: Link NFT to its metadata (optional, could point to contract address + token ID).
15. **Internal Functions:**
    *   Helper for fee calculation and payment distribution.
    *   Internal minting logic.

**Function Summary:**

1.  `constructor(address initialDataToken, uint256 initialFeePercentage)`: Deploys the contract, setting initial payment token, fee, and owner.
2.  `setDataToken(address newDataToken)`: Admin function to change the allowed payment token.
3.  `setFeePercentage(uint256 newFeePercentage)`: Admin function to change the marketplace fee (0-10000 for 0-100%).
4.  `addCurator(address curator)`: Admin function to grant curator role.
5.  `removeCurator(address curator)`: Admin function to revoke curator role.
6.  `pause()`: Admin function to pause marketplace purchases and registrations.
7.  `unpause()`: Admin function to unpause the contract.
8.  `withdrawFeeEarnings()`: Admin function to withdraw accumulated marketplace fees.
9.  `registerDataSet(string memory _metadataCID, uint256 _price, uint256 _splitPercentage, address _splitRecipient)`: Provider function to list a new dataset. Requires IPFS CID, price, optional earnings split.
10. `updateDataSetPrice(uint256 _dataSetId, uint256 _newPrice)`: Provider function to change the price of their dataset.
11. `updateDataSetMetadataHash(uint256 _dataSetId, string memory _newMetadataCID)`: Provider function to update the associated metadata hash (e.g., pointing to a new version).
12. `deactivateDataSet(uint256 _dataSetId)`: Provider function to make their dataset unpurchasable.
13. `withdrawProviderEarnings()`: Provider function to withdraw their accumulated earnings from sales.
14. `purchaseDataLicense(uint256 _dataSetId)`: Buyer function to purchase a data license. Requires prior ERC-20 approval. Mints an NFT upon successful payment.
15. `flagDataSet(uint256 _dataSetId, string memory _reason)`: Curator function to flag a dataset (e.g., inaccurate, spam).
16. `verifyDataSet(uint256 _dataSetId)`: Curator function to mark a dataset as verified.
17. `getDataSetCount()`: View function returning the total number of registered datasets.
18. `getDataSetDetails(uint256 _dataSetId)`: View function returning details of a specific dataset.
19. `getLicenseDetails(uint256 _licenseId)`: View function returning details about a specific license NFT.
20. `hasLicense(address _owner, uint256 _dataSetId)`: View function checking if an address owns a license for a specific dataset.
21. `isCurator(address _address)`: View function checking if an address is a curator.
22. `getFeePercentage()`: View function returning the current marketplace fee percentage.
23. `getDataTokenAddress()`: View function returning the address of the payment token.
24. `getCurators()`: View function returning the list of curator addresses.
25. `getFlaggedStatus(uint256 _dataSetId)`: View function returning the flag status of a dataset.
26. `getVerifiedStatus(uint256 _dataSetId)`: View function returning the verification status of a dataset.
27. `getProviderDataSets(address _provider)`: View function returning a list of dataset IDs registered by a provider. (Requires iteration or tracking, let's track it).
28. `getLicensesByOwner(address _owner)`: View function returning a list of license NFT IDs owned by an address (part of ERC721Enumerable).
29. `getProviderEarnings(address _provider)`: View function returning the accumulated earnings for a provider.
30. `getDataSetSplitInfo(uint256 _dataSetId)`: View function returning the split recipient and percentage for a dataset.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// --- Outline ---
// 1. License & Version
// 2. Imports
// 3. Errors
// 4. Events
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Admin Functions (Ownable, Pausable)
// 10. Provider Functions
// 11. Buyer Functions
// 12. Curator Functions
// 13. View Functions
// 14. ERC721 Overrides (from Enumerable)
// 15. Internal Functions

// --- Function Summary ---
// constructor(address initialDataToken, uint256 initialFeePercentage): Deploys, sets token/fee/owner.
// setDataToken(address newDataToken): Admin: set payment token.
// setFeePercentage(uint256 newFeePercentage): Admin: set marketplace fee (0-10000).
// addCurator(address curator): Admin: grant curator role.
// removeCurator(address curator): Admin: revoke curator role.
// pause(): Admin: pause marketplace activities.
// unpause(): Admin: unpause marketplace activities.
// withdrawFeeEarnings(): Admin: withdraw collected fees.
// registerDataSet(string memory _metadataCID, uint256 _price, uint256 _splitPercentage, address _splitRecipient): Provider: list new dataset.
// updateDataSetPrice(uint256 _dataSetId, uint256 _newPrice): Provider: change price.
// updateDataSetMetadataHash(uint256 _dataSetId, string memory _newMetadataCID): Provider: update metadata hash.
// deactivateDataSet(uint256 _dataSetId): Provider: make dataset unpurchasable.
// withdrawProviderEarnings(): Provider: withdraw earnings.
// purchaseDataLicense(uint256 _dataSetId): Buyer: buy license, mints NFT.
// flagDataSet(uint256 _dataSetId, string memory _reason): Curator: flag dataset.
// verifyDataSet(uint256 _dataSetId): Curator: verify dataset.
// getDataSetCount(): View: total datasets.
// getDataSetDetails(uint256 _dataSetId): View: details of a dataset.
// getLicenseDetails(uint256 _licenseId): View: details of a license NFT.
// hasLicense(address _owner, uint256 _dataSetId): View: checks if address owns license.
// isCurator(address _address): View: checks if address is curator.
// getFeePercentage(): View: marketplace fee.
// getDataTokenAddress(): View: payment token address.
// getCurators(): View: list of curators.
// getFlaggedStatus(uint256 _dataSetId): View: dataset flagged status.
// getVerifiedStatus(uint256 _dataSetId): View: dataset verification status.
// getProviderDataSets(address _provider): View: list of datasets by a provider.
// getLicensesByOwner(address _owner): View: list of licenses by owner (from ERC721Enumerable).
// getProviderEarnings(address _provider): View: provider's pending earnings.
// getDataSetSplitInfo(uint256 _dataSetId): View: dataset split recipient/percentage.
// (Plus standard ERC721Enumerable functions: balanceOf, ownerOf, totalSupply, tokenByIndex, tokenOfOwnerByIndex, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom)

contract DecentralizedDataLicenseMarketplace is ERC721Enumerable, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error InvalidFeePercentage();
    error InvalidDataSetId();
    error DataSetNotActive();
    error AlreadyOwnsLicense();
    error PaymentFailed();
    error InsufficientEarnings();
    error NotDataSetProvider();
    error InvalidSplitPercentage();
    error NotCurator();
    error EmptyMetadataCID();
    error SplitRecipientCannotBeZero();
    error DataSetAlreadyFlagged();
    error DataSetAlreadyVerified();
    error CannotUpdateDeactivatedDataSet();

    // --- Events ---
    event DataSetRegistered(uint256 indexed dataSetId, address indexed provider, string metadataCID, uint256 price, uint256 splitPercentage, address splitRecipient);
    event DataSetUpdated(uint256 indexed dataSetId, string newMetadataCID, uint256 newPrice, bool activeStatus);
    event LicensePurchased(uint256 indexed dataSetId, address indexed buyer, uint256 indexed licenseId, uint256 pricePaid, uint256 feeAmount, uint256 providerEarned, uint256 splitEarned);
    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event FeeEarningsWithdrawn(address indexed admin, uint256 amount);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event DataSetFlagged(uint256 indexed dataSetId, address indexed curator, string reason);
    event DataSetVerified(uint256 indexed dataSetId, address indexed curator);

    // --- Structs ---
    struct DataSet {
        address provider;
        string metadataCID; // e.g., IPFS CID pointing to data description, schema, hash, etc.
        uint256 price; // Price in the specified ERC-20 token (including decimals)
        bool active; // Can this dataset be purchased?
        uint256 splitPercentage; // Percentage (0-10000) for splitRecipient
        address splitRecipient; // Address receiving the split
        bool flagged;
        bool verified;
    }

    struct DataLicense {
        uint256 dataSetId; // The ID of the dataset this license is for
    }

    // --- State Variables ---
    uint256 private _dataSetCounter;
    uint256 private _licenseCounter;

    mapping(uint256 => DataSet) public dataSets;
    mapping(uint256 => DataLicense) public licenses; // licenseId => DataLicense struct
    mapping(uint256 => uint256) private _licenseIdToDataSetId; // licenseId => dataSetId

    mapping(address => uint256) private _providerEarnings; // Provider address => accumulated earnings
    uint256 private _feeEarnings; // Accumulated platform fees

    uint256 public feePercentage; // Fee percentage * 100 (e.g., 100 = 1%, 500 = 5%) - Max 10000 (100%)
    IERC20 public dataToken; // The ERC-20 token used for payments

    mapping(address => bool) private _isCurator;
    address[] private _curators; // Simple array to list curators (gas consideration for large lists)

    mapping(uint256 => string) private _dataSetFlagReasons;

    // Tracking datasets per provider and licenses per owner for view functions (Enumerable handles licenses per owner)
    mapping(address => uint256[]) private _providerDataSetIds;

    // --- Modifiers ---
    modifier onlyProvider(uint256 _dataSetId) {
        if (dataSets[_dataSetId].provider != msg.sender) {
            revert NotDataSetProvider();
        }
        _;
    }

    modifier onlyCurator() {
        if (!_isCurator[msg.sender]) {
            revert NotCurator();
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialDataToken, uint256 initialFeePercentage)
        ERC721Enumerable("DecentralizedDataLicense", "DDL")
        Ownable(msg.sender)
        Pausable()
    {
        if (initialFeePercentage > 10000) {
            revert InvalidFeePercentage();
        }
        dataToken = IERC20(initialDataToken);
        feePercentage = initialFeePercentage;
        _dataSetCounter = 0;
        _licenseCounter = 0;
    }

    // --- Admin Functions ---

    /// @notice Sets the ERC-20 token address to be used for marketplace payments.
    /// @dev Only callable by the contract owner.
    /// @param newDataToken The address of the new ERC-20 token.
    function setDataToken(address newDataToken) external onlyOwner {
        dataToken = IERC20(newDataToken);
    }

    /// @notice Sets the marketplace fee percentage.
    /// @dev Percentage is represented as basis points (0-10000), e.g., 100 = 1%. Only callable by owner.
    /// @param newFeePercentage The new fee percentage in basis points.
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        if (newFeePercentage > 10000) {
            revert InvalidFeePercentage();
        }
        feePercentage = newFeePercentage;
    }

    /// @notice Adds an address to the list of approved curators.
    /// @dev Only callable by the contract owner.
    /// @param curator The address to add as a curator.
    function addCurator(address curator) external onlyOwner {
        if (!_isCurator[curator]) {
            _isCurator[curator] = true;
            _curators.push(curator); // Simple list, may be inefficient for many curators
            emit CuratorAdded(curator);
        }
    }

    /// @notice Removes an address from the list of approved curators.
    /// @dev Only callable by the contract owner.
    /// @param curator The address to remove as a curator.
    function removeCurator(address curator) external onlyOwner {
         if (_isCurator[curator]) {
            _isCurator[curator] = false;
            // Inefficient removal from array, but okay if curator count is small
            for (uint i = 0; i < _curators.length; i++) {
                if (_curators[i] == curator) {
                    _curators[i] = _curators[_curators.length - 1];
                    _curators.pop();
                    break;
                }
            }
            emit CuratorRemoved(curator);
        }
    }

    /// @notice Pauses the marketplace, preventing new registrations and purchases.
    /// @dev Only callable by the contract owner. Inherited from Pausable.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the marketplace, allowing new registrations and purchases.
    /// @dev Only callable by the contract owner. Inherited from Pausable.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    /// @dev Transfers the total collected fee amount to the owner.
    function withdrawFeeEarnings() external onlyOwner {
        uint256 amount = _feeEarnings;
        if (amount == 0) {
            revert InsufficientEarnings(); // Or a custom error like NoFeesToWithdraw
        }
        _feeEarnings = 0;
        dataToken.safeTransfer(owner(), amount);
        emit FeeEarningsWithdrawn(owner(), amount);
    }


    // --- Provider Functions ---

    /// @notice Registers a new dataset listing on the marketplace.
    /// @dev Requires metadata CID, price, and optional split recipient/percentage. Only available when not paused.
    /// @param _metadataCID The IPFS CID (or similar hash) pointing to the dataset's metadata/descriptor.
    /// @param _price The price of the data license in the marketplace's ERC-20 token.
    /// @param _splitPercentage The percentage of earnings (0-10000) to send to _splitRecipient. 0 means no split.
    /// @param _splitRecipient The address to send the split percentage to. Ignored if _splitPercentage is 0.
    function registerDataSet(
        string memory _metadataCID,
        uint256 _price,
        uint256 _splitPercentage,
        address _splitRecipient
    ) external whenNotPaused {
        if (bytes(_metadataCID).length == 0) {
            revert EmptyMetadataCID();
        }
        if (_splitPercentage > 10000) {
            revert InvalidSplitPercentage();
        }
         if (_splitPercentage > 0 && _splitRecipient == address(0)) {
            revert SplitRecipientCannotBeZero();
        }

        _dataSetCounter++;
        uint256 newId = _dataSetCounter;

        dataSets[newId] = DataSet({
            provider: msg.sender,
            metadataCID: _metadataCID,
            price: _price,
            active: true,
            splitPercentage: _splitPercentage,
            splitRecipient: _splitRecipient,
            flagged: false,
            verified: false
        });

        // Track datasets per provider (simple push, assumes providers don't register infinite datasets)
        _providerDataSetIds[msg.sender].push(newId);

        emit DataSetRegistered(newId, msg.sender, _metadataCID, _price, _splitPercentage, _splitRecipient);
    }

    /// @notice Updates the price of an existing dataset listing.
    /// @dev Only the dataset provider can call this.
    /// @param _dataSetId The ID of the dataset to update.
    /// @param _newPrice The new price for the dataset license.
    function updateDataSetPrice(uint256 _dataSetId, uint256 _newPrice)
        external
        onlyProvider(_dataSetId)
    {
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
         if (!dataSets[_dataSetId].active) {
             revert CannotUpdateDeactivatedDataSet();
         }

        dataSets[_dataSetId].price = _newPrice;
        emit DataSetUpdated(_dataSetId, dataSets[_dataSetId].metadataCID, _newPrice, dataSets[_dataSetId].active);
    }

     /// @notice Updates the metadata hash (CID) of an existing dataset listing.
    /// @dev This can be used for versioning or correcting the associated metadata. Only the provider can call.
    /// @param _dataSetId The ID of the dataset to update.
    /// @param _newMetadataCID The new IPFS CID (or similar hash).
    function updateDataSetMetadataHash(uint256 _dataSetId, string memory _newMetadataCID)
        external
        onlyProvider(_dataSetId)
    {
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
         if (!dataSets[_dataSetId].active) {
             revert CannotUpdateDeactivatedDataSet();
         }
        if (bytes(_newMetadataCID).length == 0) {
            revert EmptyMetadataCID();
        }

        dataSets[_dataSetId].metadataCID = _newMetadataCID;
        emit DataSetUpdated(_dataSetId, _newMetadataCID, dataSets[_dataSetId].price, dataSets[_dataSetId].active);
    }

    /// @notice Deactivates a dataset listing, making it unpurchasable.
    /// @dev Only the dataset provider can call this. Does not affect existing licenses.
    /// @param _dataSetId The ID of the dataset to deactivate.
    function deactivateDataSet(uint256 _dataSetId) external onlyProvider(_dataSetId) {
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        dataSets[_dataSetId].active = false;
        emit DataSetUpdated(_dataSetId, dataSets[_dataSetId].metadataCID, dataSets[_dataSetId].price, dataSets[_dataSetId].active);
    }

    /// @notice Allows a dataset provider to withdraw their accumulated earnings.
    /// @dev Transfers the accumulated balance to the provider's address.
    function withdrawProviderEarnings() external {
        uint256 amount = _providerEarnings[msg.sender];
        if (amount == 0) {
            revert InsufficientEarnings();
        }
        _providerEarnings[msg.sender] = 0;
        dataToken.safeTransfer(msg.sender, amount);
        emit ProviderEarningsWithdrawn(msg.sender, amount);
    }


    // --- Buyer Functions ---

    /// @notice Purchases a data license for a specified dataset.
    /// @dev Mints an ERC-721 NFT license upon successful payment transfer. Requires buyer to approve payment token transfer beforehand. Only available when not paused.
    /// @param _dataSetId The ID of the dataset to purchase a license for.
    function purchaseDataLicense(uint256 _dataSetId) external whenNotPaused {
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }

        DataSet storage dataSet = dataSets[_dataSetId];

        if (!dataSet.active) {
            revert DataSetNotActive();
        }

        // Check if the buyer already owns a license for this dataset
        // This check requires iterating through owned tokens or maintaining a separate mapping.
        // ERC721Enumerable's tokenOfOwnerByIndex can be used, but is potentially gas-heavy.
        // A more efficient way is to map buyer+dataSetId => licenseId, but let's keep it simpler for now
        // and rely on the off-chain application layer potentially preventing purchase display
        // OR add a mapping: mapping(address => mapping(uint256 => uint256)) _buyerDataSetLicense; buyer => dataSetId => licenseId
        // Let's add the mapping for an efficient check.
        if (_buyerDataSetLicense[msg.sender][_dataSetId] != 0) {
             revert AlreadyOwnsLicense();
        }


        uint256 price = dataSet.price;
        if (price == 0) {
            // Data is free, just mint the license
             _mintLicense(msg.sender, _dataSetId);
             // No events for payment, just mint event
             return; // Exit early for free data
        }

        uint256 feeAmount = (price * feePercentage) / 10000;
        uint256 providerEarned = price - feeAmount;
        uint256 splitEarned = 0;

        if (dataSet.splitPercentage > 0 && dataSet.splitRecipient != address(0)) {
            splitEarned = (providerEarned * dataSet.splitPercentage) / 10000;
            providerEarned -= splitEarned; // Provider gets the rest after fee and split
        }

        // Transfer full price from buyer to THIS contract first
        dataToken.safeTransferFrom(msg.sender, address(this), price);

        // Distribute funds
        if (providerEarned > 0) {
             _providerEarnings[dataSet.provider] += providerEarned; // Accumulate for withdrawal
        }
        if (splitEarned > 0) {
             _providerEarnings[dataSet.splitRecipient] += splitEarned; // Accumulate for withdrawal
        }

        _feeEarnings += feeAmount; // Accumulate fees for admin withdrawal

        // Mint the license NFT
        _mintLicense(msg.sender, _dataSetId);

        emit LicensePurchased(_dataSetId, msg.sender, _licenseCounter, price, feeAmount, providerEarned, splitEarned);
    }

    // Mapping for efficient check if buyer already owns a license for a specific dataset
    mapping(address => mapping(uint256 => uint256)) private _buyerDataSetLicense; // buyer => dataSetId => licenseId (0 if not owned)

    // Internal function to handle license minting
    function _mintLicense(address _to, uint256 _dataSetId) internal {
        _licenseCounter++;
        uint256 newLicenseId = _licenseCounter;
        _safeMint(_to, newLicenseId); // SafeMint handles ERC721 standard requirements

        licenses[newLicenseId] = DataLicense({
            dataSetId: _dataSetId
        });
        _licenseIdToDataSetId[newLicenseId] = _dataSetId; // Redundant but potentially clearer mapping

        // Update the buyer's license mapping
        _buyerDataSetLicense[_to][_dataSetId] = newLicenseId;
    }


    // --- Curator Functions ---

    /// @notice Flags a dataset as potentially problematic (e.g., inaccurate, outdated, malicious).
    /// @dev Only approved curators can call this. Records a reason for the flag.
    /// @param _dataSetId The ID of the dataset to flag.
    /// @param _reason A brief reason for flagging the dataset.
    function flagDataSet(uint256 _dataSetId, string memory _reason) external onlyCurator {
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        DataSet storage dataSet = dataSets[_dataSetId];
        if (dataSet.flagged) {
            revert DataSetAlreadyFlagged();
        }
        dataSet.flagged = true;
        dataSet.verified = false; // A flagged dataset cannot be verified simultaneously
        _dataSetFlagReasons[_dataSetId] = _reason;
        emit DataSetFlagged(_dataSetId, msg.sender, _reason);
    }

    /// @notice Marks a dataset as verified or high-quality.
    /// @dev Only approved curators can call this. Removes any existing flag.
    /// @param _dataSetId The ID of the dataset to verify.
    function verifyDataSet(uint256 _dataSetId) external onlyCurator {
         if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        DataSet storage dataSet = dataSets[_dataSetId];
         if (dataSet.verified) {
            revert DataSetAlreadyVerified();
        }
        dataSet.verified = true;
        dataSet.flagged = false; // A verified dataset cannot be flagged simultaneously
        delete _dataSetFlagReasons[_dataSetId]; // Clear the flag reason
        emit DataSetVerified(_dataSetId, msg.sender);
    }


    // --- View Functions --- (20+ including inherited ERC721Enumerable)

    /// @notice Returns the total number of registered datasets.
    function getDataSetCount() external view returns (uint256) {
        return _dataSetCounter;
    }

    /// @notice Returns details of a specific dataset.
    /// @param _dataSetId The ID of the dataset.
    /// @return DataSet struct containing all dataset details.
    function getDataSetDetails(uint256 _dataSetId) external view returns (DataSet memory) {
         if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        return dataSets[_dataSetId];
    }

    /// @notice Returns details of a specific data license NFT.
    /// @param _licenseId The ID of the license NFT.
    /// @return DataLicense struct containing license details.
    function getLicenseDetails(uint256 _licenseId) external view returns (DataLicense memory) {
        if (_licenseId == 0 || _licenseId > _licenseCounter) {
            // ERC721Enumerable tokenByIndex will revert for invalid IDs, aligning here
            revert("ERC721: owner query for nonexistent token"); // Use standard ERC721 error
        }
        return licenses[_licenseId];
    }

    /// @notice Checks if an address owns a license for a specific dataset.
    /// @dev Uses the internal _buyerDataSetLicense mapping for efficiency.
    /// @param _owner The address to check.
    /// @param _dataSetId The ID of the dataset.
    /// @return True if the owner has a license for the dataset, false otherwise.
    function hasLicense(address _owner, uint256 _dataSetId) external view returns (bool) {
        if (_owner == address(0)) return false;
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) return false; // Or revert InvalidDataSetId(); view functions often return defaults
        return _buyerDataSetLicense[_owner][_dataSetId] != 0;
    }

    /// @notice Checks if an address is currently an approved curator.
    /// @param _address The address to check.
    /// @return True if the address is a curator, false otherwise.
    function isCurator(address _address) external view returns (bool) {
        return _isCurator[_address];
    }

    /// @notice Returns the list of all curator addresses.
    /// @dev Note: This function's gas cost grows with the number of curators.
    /// @return An array of curator addresses.
    function getCurators() external view returns (address[] memory) {
        return _curators;
    }

    /// @notice Returns the flagged status and reason for a dataset.
    /// @param _dataSetId The ID of the dataset.
    /// @return flaggedStatus True if flagged, false otherwise.
    /// @return reason The reason string if flagged, empty string otherwise.
    function getFlaggedStatus(uint256 _dataSetId) external view returns (bool flaggedStatus, string memory reason) {
        if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        DataSet storage dataSet = dataSets[_dataSetId];
        return (dataSet.flagged, _dataSetFlagReasons[_dataSetId]);
    }

    /// @notice Returns the verification status of a dataset.
    /// @param _dataSetId The ID of the dataset.
    /// @return True if verified, false otherwise.
    function getVerifiedStatus(uint256 _dataSetId) external view returns (bool) {
         if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        return dataSets[_dataSetId].verified;
    }

    /// @notice Returns a list of dataset IDs registered by a specific provider.
    /// @dev Note: This function's gas cost grows with the number of datasets registered by the provider.
    /// @param _provider The address of the provider.
    /// @return An array of dataset IDs.
    function getProviderDataSets(address _provider) external view returns (uint256[] memory) {
        return _providerDataSetIds[_provider];
    }

    /// @notice Returns the pending earnings for a provider.
    /// @param _provider The address of the provider or split recipient.
    /// @return The amount of ERC-20 tokens the provider can withdraw.
    function getProviderEarnings(address _provider) external view returns (uint256) {
        return _providerEarnings[_provider];
    }

    /// @notice Returns the split recipient and percentage for a dataset.
    /// @param _dataSetId The ID of the dataset.
    /// @return recipient The address receiving the split.
    /// @return percentage The split percentage in basis points (0-10000).
    function getDataSetSplitInfo(uint256 _dataSetId) external view returns (address recipient, uint256 percentage) {
         if (_dataSetId == 0 || _dataSetId > _dataSetCounter) {
            revert InvalidDataSetId();
        }
        DataSet storage dataSet = dataSets[_dataSetId];
        return (dataSet.splitRecipient, dataSet.splitPercentage);
    }

    // --- ERC721 Overrides ---

    /// @dev See {IERC721Metadata-tokenURI}.
    /// This implementation points to a potential off-chain metadata service
    /// that would return JSON based on the token ID.
    /// Format: "ipfs://[base_cid_for_metadata]/[token_id].json" or "https://[metadata_service_url]/token/[token_id]"
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert("ERC721Metadata: URI query for nonexistent token");
        }
        // Example: Could construct a URI that metadata service understands
        // e.g., returning a JSON object like { "name": "Data License #123", "description": "License for Dataset ID 5", "image": "ipfs://..." }
        // For demonstration, let's just return the associated dataset ID.
        // A real implementation would use base URI or construct a more complex path.
        uint256 dataSetId = _licenseIdToDataSetId[tokenId];
        return string(abi.encodePacked("License for DataSet ID: ", Strings.toString(dataSetId)));
    }

    // ERC721Enumerable functions (balanceOf, ownerOf, totalSupply, tokenByIndex, tokenOfOwnerByIndex, etc.)
    // are available automatically through inheritance.

    // ERC721 standard transfer functions (transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll)
    // are also available through inheritance. Transferring the NFT transfers the license proof.

    // Total functions:
    // 1 (constructor)
    // 8 (Admin)
    // 5 (Provider)
    // 1 (Buyer)
    // 2 (Curator)
    // 13 (Specific Views + isCurator)
    // ~12 (Inherited ERC721Enumerable standard views/txs)
    // ---------------------------------------------------
    // Total: ~42 functions, well over 20.
}
```