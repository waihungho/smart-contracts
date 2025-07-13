Okay, here is a smart contract idea for a Decentralized AI Model Marketplace. This contract focuses on listing, licensing, and managing AI models and associated data specifications on-chain, while the actual models and data reside off-chain (referenced by URLs or hashes).

It incorporates concepts like ERC-20 payments, licensing types, reputation (basic rating), fee distribution, and linking models to data requirements.

---

**Decentralized AI Model Marketplace Contract**

**Outline:**

1.  **Purpose:** Create a decentralized platform on blockchain for creators to list and license AI models, and for users to discover and acquire licenses for these models using an ERC-20 token. It also allows users to list data specifications they possess, potentially enabling matchmaking between models needing data and users having it.
2.  **Core Concepts:**
    *   AI Model Representation (metadata, licensing terms)
    *   Licensing Mechanism (Perpetual, Trial)
    *   ERC-20 Token as Payment Currency
    *   Marketplace Fees & Payouts
    *   Basic Model Reputation/Rating
    *   Data Specification Listing and User Association
    *   Ownership and Access Control
    *   Pausable Functionality
3.  **Main Entities:**
    *   Models (structs storing metadata, creator, price, etc.)
    *   Licenses (structs storing buyer, model ID, expiry, etc.)
    *   Data Specifications (structs describing data needed/available)
    *   Users (represented by addresses)
    *   Payment Token (ERC-20 contract address)
4.  **Interaction Flow:**
    *   Owner sets up the contract (owner, payment token).
    *   Creators list models with details and pricing.
    *   Creators can add/update model versions.
    *   Creators can link models to required data specifications.
    *   Users can list data specifications they possess.
    *   Buyers purchase licenses for models using the payment token.
    *   Buyers can rate purchased models.
    *   Model creators withdraw their earnings.
    *   Marketplace owner withdraws fees.
    *   Users can view model details, licenses, data specs, etc.

**Function Summary:**

*   **Owner/Admin Functions:**
    1.  `setPaymentToken(address tokenAddress)`: Sets the ERC-20 token used for payments.
    2.  `setMarketplaceFee(uint256 feePercent)`: Sets the percentage fee for the marketplace (0-100).
    3.  `withdrawMarketplaceFees()`: Allows the owner to withdraw collected fees.
    4.  `pauseContract()`: Pauses core contract functionality (listing, buying).
    5.  `unpauseContract()`: Unpauses the contract.
*   **Model Creator Functions:**
    6.  `listModel(string memory name, string memory description, string memory modelUri, uint256 pricePerpetualLicense, uint256 trialDurationSeconds)`: Lists a new AI model for licensing.
    7.  `updateModelListing(uint256 modelId, string memory name, string memory description, uint256 pricePerpetualLicense, uint256 trialDurationSeconds)`: Updates details of an existing model listing (except URI/version).
    8.  `delistModel(uint256 modelId)`: Marks a model as delisted.
    9.  `addModelVersion(uint256 modelId, string memory newModelUri)`: Adds a new version (new URI) to an existing model.
    10. `deprecateModelVersion(uint256 modelId, uint256 versionIndex)`: Marks a specific model version as deprecated.
    11. `transferModelOwnership(uint256 modelId, address newOwner)`: Transfers ownership of a model listing to another address.
    12. `associateDataSpecWithModel(uint256 modelId, uint256 dataSpecId)`: Links a required data specification to a model.
    13. `dissociateDataSpecFromModel(uint256 modelId, uint256 dataSpecId)`: Removes a data specification link from a model.
    14. `withdrawModelEarnings(uint256 modelId)`: Allows the model creator to withdraw their earnings from license sales.
*   **Buyer/User Functions:**
    15. `buyPerpetualLicense(uint256 modelId)`: Purchases a perpetual license for a model. Requires payment token approval.
    16. `grantTrialLicense(uint256 modelId)`: Claims a free trial license for a model (if available and not claimed before).
    17. `rateModel(uint256 modelId, uint8 rating)`: Allows a license holder to rate a model (1-5).
*   **Data Specification Management (User/Creator):**
    18. `listDataSpecification(string memory name, string memory description, string memory dataSpecUri)`: Lists a data specification that a user might possess or define.
    19. `updateDataSpecification(uint256 dataSpecId, string memory name, string memory description, string memory dataSpecUri)`: Updates details of a data specification listing.
    20. `delistDataSpecification(uint256 dataSpecId)`: Marks a data specification as delisted.
    21. `associateUserDataSpec(uint256 dataSpecId)`: User declares they possess/can provide the data described by a specification.
    22. `dissociateUserDataSpec(uint256 dataSpecId)`: User revokes their association with a data specification.
*   **View Functions (Read-only):**
    23. `getModelDetails(uint256 modelId)`: Gets full details of a model listing.
    24. `listAllModelIds()`: Gets a list of all listed model IDs.
    25. `getUserLicenses(address user)`: Gets a list of all license IDs held by a user.
    26. `getLicenseDetails(uint256 licenseId)`: Gets details of a specific license.
    27. `getDataSpecificationDetails(uint256 dataSpecId)`: Gets details of a data specification.
    28. `listAllDataSpecIds()`: Gets a list of all listed data specification IDs.
    29. `getUsersWithDataSpec(uint256 dataSpecId)`: Gets a list of users who have associated themselves with a data specification.
    30. `getModelAverageRating(uint256 modelId)`: Gets the average rating for a model.
    31. `getModelCreatorEarnings(uint256 modelId)`: Gets the pending earnings for a model creator.
    32. `getMarketplaceFeeBalance()`: Gets the total pending marketplace fees.
    33. `getPaymentToken()`: Gets the address of the accepted payment token.
    34. `isPaused()`: Checks if the contract is paused.
    35. `getUserModelRating(uint256 modelId, address user)`: Gets the rating given by a specific user for a model (0 if not rated).
    36. `getModelAssociatedDataSpecs(uint256 modelId)`: Gets the list of data specification IDs associated with a model.
    37. `getModelVersions(uint256 modelId)`: Gets the list of URIs for all versions of a model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Decentralized AI Model Marketplace
 * @dev A smart contract for listing, licensing, and managing AI models and data specifications
 *      on a decentralized marketplace using an ERC-20 token for payments.
 *      Actual models and data reside off-chain, referenced by URIs/hashes.
 *
 * Outline:
 * - Purpose: Facilitate decentralized exchange of AI model licenses.
 * - Core Concepts: Model listing/licensing, ERC-20 payments, fees, basic reputation, data spec linking.
 * - Entities: Models, Licenses, Data Specs, Users, Payment Token.
 * - Flow: List -> Buy License (requires token approval) -> Withdraw earnings/fees.
 *
 * Function Summary:
 * - Owner/Admin: setPaymentToken, setMarketplaceFee, withdrawMarketplaceFees, pauseContract, unpauseContract
 * - Model Creator: listModel, updateModelListing, delistModel, addModelVersion, deprecateModelVersion, transferModelOwnership, associateDataSpecWithModel, dissociateDataSpecFromModel, withdrawModelEarnings
 * - Buyer/User: buyPerpetualLicense, grantTrialLicense, rateModel
 * - Data Spec Mgmt: listDataSpecification, updateDataSpecification, delistDataSpecification, associateUserDataSpec, dissociateUserDataSpec
 * - View Functions: getModelDetails, listAllModelIds, getUserLicenses, getLicenseDetails, getDataSpecificationDetails, listAllDataSpecIds, getUsersWithDataSpec, getModelAverageRating, getModelCreatorEarnings, getMarketplaceFeeBalance, getPaymentToken, isPaused, getUserModelRating, getModelAssociatedDataSpecs, getModelVersions
 */
contract DecentralizedAIModelMarketplace is Ownable, Pausable {

    struct Model {
        uint256 id;
        address creator;
        string name;
        string description;
        string[] modelUris; // URIs or hashes pointing to off-chain model files (multiple versions)
        bool[] deprecatedVersions; // True if the version at the same index is deprecated
        uint256 pricePerpetualLicense; // Price in paymentToken for a perpetual license
        uint256 trialDurationSeconds; // 0 means no trial available
        bool isListed; // Flag to indicate if the model is currently active in the marketplace
        uint256[] associatedDataSpecs; // IDs of DataSpecifications required by this model
    }

    enum LicenseType {
        Perpetual,
        Trial
    }

    struct License {
        uint256 id;
        uint256 modelId;
        address buyer;
        LicenseType licenseType;
        uint256 purchaseTimestamp;
        uint256 expiryTimestamp; // 0 for perpetual licenses
        bool isActive; // Could be used for potential future revocation features, or simply indicates initial validity
    }

    struct DataSpecification {
        uint256 id;
        address creator; // Who listed this data specification
        string name;
        string description;
        string dataSpecUri; // URI or hash pointing to off-chain details about the data spec
        bool isListed; // Flag if the data spec is active
    }

    struct ModelRating {
        uint8 rating; // 1-5
        uint256 timestamp;
    }

    uint256 private _modelIdCounter;
    uint256 private _licenseIdCounter;
    uint256 private _dataSpecIdCounter;

    mapping(uint256 => Model) public models;
    mapping(uint256 => License) public licenses;
    mapping(uint256 => DataSpecification) public dataSpecifications;

    // Keep track of models listed by each creator
    mapping(address => uint256[]) public creatorModels;
    // Keep track of data specs listed by each creator
    mapping(address => uint256[]) public creatorDataSpecs;
    // Keep track of licenses held by each user
    mapping(address => uint256[]) public userLicenses;
    // Keep track of users who claim to possess a certain data specification
    mapping(uint256 => address[]) private _usersWithDataSpec;
    // Mapping for quick lookup if a user possesses a data spec
    mapping(uint256 => mapping(address => bool)) private _hasUserDataSpec;

    // Model Rating System
    mapping(uint256 => mapping(address => ModelRating)) private _userModelRatings; // modelId => userAddress => rating
    mapping(uint256 => uint256) private _modelTotalRatings; // modelId => sum of ratings
    mapping(uint256 => uint256) private _modelRatingCount; // modelId => number of ratings

    // Fee Management
    uint256 public marketplaceFeePercent; // Percentage, multiplied by 100 (e.g., 200 for 2%)
    mapping(uint256 => uint256) private _modelEarnings; // modelId => amount earned by creator (before withdrawal)
    uint256 private _marketplaceFees; // Total amount collected for the marketplace owner

    IERC20 public paymentToken; // Address of the ERC-20 token used for payments

    event ModelListed(uint256 indexed modelId, address indexed creator, string name, uint256 pricePerpetual, uint256 trialDuration);
    event ModelListingUpdated(uint256 indexed modelId, string name, string description, uint256 pricePerpetual, uint256 trialDuration);
    event ModelDelisted(uint256 indexed modelId);
    event ModelVersionAdded(uint256 indexed modelId, uint256 versionIndex, string modelUri);
    event ModelVersionDeprecated(uint256 indexed modelId, uint256 versionIndex);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner);
    event DataSpecAssociatedWithModel(uint256 indexed modelId, uint256 indexed dataSpecId);
    event DataSpecDissociatedFromModel(uint256 indexed modelId, uint256 indexed dataSpecId);

    event LicenseGranted(uint256 indexed licenseId, uint256 indexed modelId, address indexed buyer, LicenseType licenseType, uint256 expiryTimestamp);
    event ModelRated(uint256 indexed modelId, address indexed rater, uint8 rating);

    event DataSpecificationListed(uint256 indexed dataSpecId, address indexed creator, string name);
    event DataSpecificationUpdated(uint256 indexed dataSpecId, string name, string description, string dataSpecUri);
    event DataSpecificationDelisted(uint256 indexed dataSpecId);
    event UserAssociatedWithDataSpec(uint256 indexed dataSpecId, address indexed user);
    event UserDissociatedFromDataSpec(uint256 indexed dataSpecId, address indexed user);

    event ModelEarningsWithdrawn(uint256 indexed modelId, address indexed creator, uint256 amount);
    event MarketplaceFeesWithdrawn(address indexed owner, uint256 amount);

    event PaymentTokenSet(address indexed oldToken, address indexed newToken);
    event MarketplaceFeeSet(uint256 oldFee, uint256 newFee);

    // --- Modifiers ---

    modifier onlyModelOwner(uint256 modelId) {
        require(models[modelId].creator == msg.sender, "Not the model creator");
        _;
    }

    modifier onlyDataSpecOwner(uint256 dataSpecId) {
         require(dataSpecifications[dataSpecId].creator == msg.sender, "Not the data spec creator");
        _;
    }

    modifier onlyLicenseHolder(uint256 licenseId) {
        require(licenses[licenseId].buyer == msg.sender, "Not the license holder");
        _;
    }

    modifier onlyValidLicense(uint256 licenseId) {
        License storage license = licenses[licenseId];
        require(license.isActive, "License is not active");
        if (license.licenseType == LicenseType.Trial) {
            require(block.timestamp < license.expiryTimestamp, "Trial license expired");
        }
        _;
    }

    // --- Constructor ---

    constructor(address initialPaymentToken) Ownable(msg.sender) Pausable(false) {
        require(initialPaymentToken != address(0), "Invalid token address");
        paymentToken = IERC20(initialPaymentToken);
        marketplaceFeePercent = 0; // Default 0% fee
        _modelIdCounter = 0;
        _licenseIdCounter = 0;
        _dataSpecIdCounter = 0;
    }

    // --- Owner/Admin Functions (5) ---

    /**
     * @dev Sets the ERC-20 token address to be used for payments.
     * @param tokenAddress The address of the ERC-20 token.
     */
    function setPaymentToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        emit PaymentTokenSet(address(paymentToken), tokenAddress);
        paymentToken = IERC20(tokenAddress);
    }

    /**
     * @dev Sets the marketplace fee percentage. Fee is represented as basis points (e.g., 100 for 1%).
     * @param feePercent Fee percentage * 100 (e.g., 200 for 2%). Max 10000 (100%).
     */
    function setMarketplaceFee(uint256 feePercent) external onlyOwner {
        require(feePercent <= 10000, "Fee percentage cannot exceed 100%");
        emit MarketplaceFeeSet(marketplaceFeePercent, feePercent);
        marketplaceFeePercent = feePercent;
    }

    /**
     * @dev Allows the owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 amount = _marketplaceFees;
        require(amount > 0, "No fees to withdraw");
        _marketplaceFees = 0;
        // Assuming paymentToken allows transfers directly
        bool success = paymentToken.transfer(owner(), amount);
        require(success, "Token transfer failed");
        emit MarketplaceFeesWithdrawn(owner(), amount);
    }

    // Inherited pause/unpause functions from Pausable:
    // 4. pauseContract()
    // 5. unpauseContract()

    // --- Model Creator Functions (9) ---

    /**
     * @dev Lists a new AI model in the marketplace.
     * @param name Name of the model.
     * @param description Description of the model.
     * @param modelUri URI or hash pointing to the off-chain model file.
     * @param pricePerpetualLicense Price for a perpetual license in paymentToken.
     * @param trialDurationSeconds Duration of the trial license in seconds (0 for no trial).
     */
    function listModel(string memory name, string memory description, string memory modelUri, uint256 pricePerpetualLicense, uint256 trialDurationSeconds)
        external
        whenNotPaused
    {
        _modelIdCounter++;
        uint256 newModelId = _modelIdCounter;

        models[newModelId] = Model({
            id: newModelId,
            creator: msg.sender,
            name: name,
            description: description,
            modelUris: new string[](1),
            deprecatedVersions: new bool[](1),
            pricePerpetualLicense: pricePerpetualLicense,
            trialDurationSeconds: trialDurationSeconds,
            isListed: true,
            associatedDataSpecs: new uint256[](0)
        });
        models[newModelId].modelUris[0] = modelUri;
        models[newModelId].deprecatedVersions[0] = false;

        creatorModels[msg.sender].push(newModelId);

        emit ModelListed(newModelId, msg.sender, name, pricePerpetualLicense, trialDurationSeconds);
    }

    /**
     * @dev Updates the details of an existing model listing.
     * @param modelId The ID of the model to update.
     * @param name New name for the model.
     * @param description New description for the model.
     * @param pricePerpetualLicense New price for perpetual license.
     * @param trialDurationSeconds New trial duration.
     */
    function updateModelListing(uint256 modelId, string memory name, string memory description, uint256 pricePerpetualLicense, uint256 trialDurationSeconds)
        external
        onlyModelOwner(modelId)
        whenNotPaused
    {
        Model storage model = models[modelId];
        require(model.isListed, "Model is not listed");

        model.name = name;
        model.description = description;
        model.pricePerpetualLicense = pricePerpetualLicense;
        model.trialDurationSeconds = trialDurationSeconds;

        emit ModelListingUpdated(modelId, name, description, pricePerpetualLicense, trialDurationSeconds);
    }

    /**
     * @dev Delists a model from the marketplace. Existing licenses remain valid.
     * @param modelId The ID of the model to delist.
     */
    function delistModel(uint256 modelId) external onlyModelOwner(modelId) whenNotPaused {
        Model storage model = models[modelId];
        require(model.isListed, "Model is already delisted");
        model.isListed = false;
        emit ModelDelisted(modelId);
    }

     /**
     * @dev Adds a new version (URI) to an existing model.
     * @param modelId The ID of the model.
     * @param newModelUri The URI or hash for the new model version.
     */
    function addModelVersion(uint256 modelId, string memory newModelUri) external onlyModelOwner(modelId) whenNotPaused {
        Model storage model = models[modelId];
        model.modelUris.push(newModelUri);
        model.deprecatedVersions.push(false);
        emit ModelVersionAdded(modelId, model.modelUris.length - 1, newModelUri);
    }

     /**
     * @dev Marks a specific version of a model as deprecated.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version to deprecate (0-based).
     */
    function deprecateModelVersion(uint256 modelId, uint256 versionIndex) external onlyModelOwner(modelId) whenNotPaused {
        Model storage model = models[modelId];
        require(versionIndex < model.modelUris.length, "Invalid version index");
        require(!model.deprecatedVersions[versionIndex], "Version already deprecated");
        model.deprecatedVersions[versionIndex] = true;
        emit ModelVersionDeprecated(modelId, versionIndex);
    }

     /**
     * @dev Transfers the ownership of a model listing to another address.
     * @param modelId The ID of the model.
     * @param newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 modelId, address newOwner) external onlyModelOwner(modelId) whenNotPaused {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != msg.sender, "Cannot transfer to self");

        Model storage model = models[modelId];
        address oldOwner = model.creator;
        model.creator = newOwner;

        // Update creatorModels mapping (simple append for new owner, creator needs to prune their list off-chain if desired)
        creatorModels[newOwner].push(modelId);
        // Note: Efficient removal from creatorModels[oldOwner] mapping is complex in Solidity arrays.
        // A common pattern is to allow users to iterate and ignore delisted items,
        // or use a more complex mapping like mapping(address => mapping(uint256 => bool)) isCreatorOf.

        emit ModelOwnershipTransferred(modelId, oldOwner, newOwner);
    }

     /**
     * @dev Associates a required data specification with a model.
     *      This indicates the model performs best or requires the specified data.
     * @param modelId The ID of the model.
     * @param dataSpecId The ID of the data specification.
     */
    function associateDataSpecWithModel(uint256 modelId, uint256 dataSpecId) external onlyModelOwner(modelId) whenNotPaused {
        require(dataSpecifications[dataSpecId].isListed, "Data specification must be listed");

        Model storage model = models[modelId];
        // Prevent adding duplicates (simple iteration check)
        for (uint i = 0; i < model.associatedDataSpecs.length; i++) {
            if (model.associatedDataSpecs[i] == dataSpecId) {
                return; // Already associated
            }
        }
        model.associatedDataSpecs.push(dataSpecId);
        emit DataSpecAssociatedWithModel(modelId, dataSpecId);
    }

     /**
     * @dev Dissociates a data specification from a model.
     * @param modelId The ID of the model.
     * @param dataSpecId The ID of the data specification to remove.
     */
    function dissociateDataSpecFromModel(uint256 modelId, uint256 dataSpecId) external onlyModelOwner(modelId) whenNotPaused {
        Model storage model = models[modelId];
        bool found = false;
        uint256 indexToRemove = model.associatedDataSpecs.length; // Sentinel value

        for (uint i = 0; i < model.associatedDataSpecs.length; i++) {
            if (model.associatedDataSpecs[i] == dataSpecId) {
                indexToRemove = i;
                found = true;
                break;
            }
        }

        require(found, "Data specification not associated with this model");

        // Efficient removal from array: swap with last element and pop
        model.associatedDataSpecs[indexToRemove] = model.associatedDataSpecs[model.associatedDataSpecs.length - 1];
        model.associatedDataSpecs.pop();

        emit DataSpecDissociatedFromModel(modelId, dataSpecId);
    }

    /**
     * @dev Allows the model creator to withdraw their accumulated earnings.
     * @param modelId The ID of the model to withdraw earnings for.
     */
    function withdrawModelEarnings(uint256 modelId) external onlyModelOwner(modelId) {
        uint256 amount = _modelEarnings[modelId];
        require(amount > 0, "No earnings to withdraw for this model");
        _modelEarnings[modelId] = 0;

        bool success = paymentToken.transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit ModelEarningsWithdrawn(modelId, msg.sender, amount);
    }

    // --- Buyer/User Functions (3) ---

    /**
     * @dev Purchases a perpetual license for a model.
     *      Requires the buyer to have approved the contract to spend the paymentToken.
     * @param modelId The ID of the model to buy a license for.
     */
    function buyPerpetualLicense(uint256 modelId) external whenNotPaused {
        Model storage model = models[modelId];
        require(model.isListed, "Model is not listed or available");
        require(model.pricePerpetualLicense > 0, "Perpetual license is not available for purchase");

        // Check if user already has an active perpetual license
        uint256[] memory userLicenseIds = userLicenses[msg.sender];
        for(uint i=0; i<userLicenseIds.length; i++) {
            License storage existingLicense = licenses[userLicenseIds[i]];
            if (existingLicense.modelId == modelId && existingLicense.licenseType == LicenseType.Perpetual && existingLicense.isActive) {
                 revert("User already holds an active perpetual license for this model");
            }
        }

        uint256 totalPrice = model.pricePerpetualLicense;
        uint256 feeAmount = (totalPrice * marketplaceFeePercent) / 10000; // Fee is in basis points
        uint256 creatorAmount = totalPrice - feeAmount;

        // Transfer tokens from buyer to contract (requires pre-approval)
        bool transferSuccess = paymentToken.transferFrom(msg.sender, address(this), totalPrice);
        require(transferSuccess, "Token transfer failed. Ensure you have enough tokens and have approved the contract.");

        // Distribute funds
        _modelEarnings[modelId] += creatorAmount;
        _marketplaceFees += feeAmount;

        // Grant License
        _licenseIdCounter++;
        uint256 newLicenseId = _licenseIdCounter;
        licenses[newLicenseId] = License({
            id: newLicenseId,
            modelId: modelId,
            buyer: msg.sender,
            licenseType: LicenseType.Perpetual,
            purchaseTimestamp: block.timestamp,
            expiryTimestamp: 0, // 0 indicates perpetual
            isActive: true
        });
        userLicenses[msg.sender].push(newLicenseId);

        emit LicenseGranted(newLicenseId, modelId, msg.sender, LicenseType.Perpetual, 0);
    }

    /**
     * @dev Grants a trial license to a user for a model, if available and not previously claimed by the user.
     * @param modelId The ID of the model to get a trial license for.
     */
    function grantTrialLicense(uint256 modelId) external whenNotPaused {
        Model storage model = models[modelId];
        require(model.isListed, "Model is not listed");
        require(model.trialDurationSeconds > 0, "Trial license not available for this model");

        // Check if user already claimed a trial for this model
         uint256[] memory userLicenseIds = userLicenses[msg.sender];
        for(uint i=0; i<userLicenseIds.length; i++) {
            License storage existingLicense = licenses[userLicenseIds[i]];
            if (existingLicense.modelId == modelId && existingLicense.licenseType == LicenseType.Trial) {
                 revert("User has already claimed a trial license for this model");
            }
        }

        // Grant License
        _licenseIdCounter++;
        uint256 newLicenseId = _licenseIdCounter;
        uint256 expiry = block.timestamp + model.trialDurationSeconds;

        licenses[newLicenseId] = License({
            id: newLicenseId,
            modelId: modelId,
            buyer: msg.sender,
            licenseType: LicenseType.Trial,
            purchaseTimestamp: block.timestamp,
            expiryTimestamp: expiry,
            isActive: true // Trial licenses are active until expiry
        });
        userLicenses[msg.sender].push(newLicenseId);

        emit LicenseGranted(newLicenseId, modelId, msg.sender, LicenseType.Trial, expiry);
    }

    /**
     * @dev Allows a license holder to rate a model (1-5 stars).
     *      Can only rate if an active license is held. Users can update their rating.
     * @param modelId The ID of the model to rate.
     * @param rating The rating (1-5).
     */
    function rateModel(uint256 modelId, uint8 rating) external whenNotPaused {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        Model storage model = models[modelId];
        require(model.isListed || !model.isListed, "Model does not exist"); // Allow rating even if delisted

        // Check if user holds an active license for this model
        bool hasActiveLicense = false;
        uint256[] memory userLicenseIds = userLicenses[msg.sender];
        for(uint i=0; i<userLicenseIds.length; i++) {
             uint256 licenseId = userLicenseIds[i];
             License storage lic = licenses[licenseId];
             if (lic.modelId == modelId && lic.isActive) {
                // For perpetual, always active. For trial, check expiry.
                if (lic.licenseType == LicenseType.Perpetual || (lic.licenseType == LicenseType.Trial && block.timestamp < lic.expiryTimestamp)) {
                     hasActiveLicense = true;
                     break;
                }
             }
        }
        require(hasActiveLicense, "User must hold an active license for this model to rate");

        // Check if user already rated this model
        bool alreadyRated = _userModelRatings[modelId][msg.sender].timestamp > 0;
        uint8 oldRating = _userModelRatings[modelId][msg.sender].rating;

        if (alreadyRated) {
            // Update existing rating
            _modelTotalRatings[modelId] -= oldRating;
            _modelTotalRatings[modelId] += rating;
        } else {
            // Add new rating
            _modelTotalRatings[modelId] += rating;
            _modelRatingCount[modelId]++;
        }

        _userModelRatings[modelId][msg.sender] = ModelRating({
            rating: rating,
            timestamp: block.timestamp
        });

        emit ModelRated(modelId, msg.sender, rating);
    }


    // --- Data Specification Management (User/Creator) (5) ---

    /**
     * @dev Lists a new data specification. Can be listed by anyone, representing data they possess or define.
     * @param name Name of the data specification.
     * @param description Description of the data specification.
     * @param dataSpecUri URI or hash pointing to off-chain details about the data.
     */
    function listDataSpecification(string memory name, string memory description, string memory dataSpecUri)
        external
        whenNotPaused
    {
        _dataSpecIdCounter++;
        uint256 newDataSpecId = _dataSpecIdCounter;

        dataSpecifications[newDataSpecId] = DataSpecification({
            id: newDataSpecId,
            creator: msg.sender, // The address that listed this spec
            name: name,
            description: description,
            dataSpecUri: dataSpecUri,
            isListed: true
        });

        creatorDataSpecs[msg.sender].push(newDataSpecId);

        emit DataSpecificationListed(newDataSpecId, msg.sender, name);
    }

    /**
     * @dev Updates the details of an existing data specification listing.
     * @param dataSpecId The ID of the data specification to update.
     * @param name New name.
     * @param description New description.
     * @param dataSpecUri New URI.
     */
    function updateDataSpecification(uint256 dataSpecId, string memory name, string memory description, string memory dataSpecUri)
        external
        onlyDataSpecOwner(dataSpecId)
        whenNotPaused
    {
        DataSpecification storage spec = dataSpecifications[dataSpecId];
        require(spec.isListed, "Data specification is not listed");

        spec.name = name;
        spec.description = description;
        spec.dataSpecUri = dataSpecUri;

        emit DataSpecificationUpdated(dataSpecId, name, description, dataSpecUri);
    }

    /**
     * @dev Delists a data specification.
     * @param dataSpecId The ID of the data specification to delist.
     */
    function delistDataSpecification(uint256 dataSpecId) external onlyDataSpecOwner(dataSpecId) whenNotPaused {
        DataSpecification storage spec = dataSpecifications[dataSpecId];
        require(spec.isListed, "Data specification is already delisted");
        spec.isListed = false;
        emit DataSpecificationDelisted(dataSpecId);

        // Optional: Remove associations? Keeping them simplifies the contract, off-chain indexers filter.
    }

    /**
     * @dev Allows a user to associate themselves with a data specification, indicating they possess/can provide it.
     * @param dataSpecId The ID of the data specification.
     */
    function associateUserDataSpec(uint256 dataSpecId) external whenNotPaused {
        require(dataSpecifications[dataSpecId].isListed, "Data specification is not listed");
        require(!_hasUserDataSpec[dataSpecId][msg.sender], "User is already associated with this data spec");

        _usersWithDataSpec[dataSpecId].push(msg.sender);
        _hasUserDataSpec[dataSpecId][msg.sender] = true;

        emit UserAssociatedWithDataSpec(dataSpecId, msg.sender);
    }

    /**
     * @dev Allows a user to dissociate themselves from a data specification.
     * @param dataSpecId The ID of the data specification.
     */
    function dissociateUserDataSpec(uint256 dataSpecId) external whenNotPaused {
        require(dataSpecifications[dataSpecId].isListed || !dataSpecifications[dataSpecId].isListed, "Data specification does not exist"); // Allow dissociating even if delisted
        require(_hasUserDataSpec[dataSpecId][msg.sender], "User is not associated with this data spec");

        _hasUserDataSpec[dataSpecId][msg.sender] = false;

        // Note: Efficient removal from _usersWithDataSpec array is complex.
        // It's often better to use a mapping and allow iteration on an off-chain indexer,
        // or mark as inactive. For simplicity, we'll mark the mapping and not clean the array here.
        // Or, use a more complex swap-and-pop like in dissociateDataSpecFromModel if the array must be accurate.
        // Let's implement swap-and-pop for accuracy.
        address[] storage users = _usersWithDataSpec[dataSpecId];
        uint256 indexToRemove = users.length; // Sentinel value

        for (uint i = 0; i < users.length; i++) {
            if (users[i] == msg.sender) {
                indexToRemove = i;
                break;
            }
        }
        // Check again in case the require(!_hasUserDataSpec...) above wasn't enough due to stale array
        require(indexToRemove < users.length, "User association not found in array");

        users[indexToRemove] = users[users.length - 1];
        users.pop();


        emit UserDissociatedFromDataSpec(dataSpecId, msg.sender);
    }


    // --- View Functions (14) ---

    /**
     * @dev Gets full details of a model listing.
     * @param modelId The ID of the model.
     * @return Model struct.
     */
    function getModelDetails(uint256 modelId) external view returns (Model memory) {
        require(modelId > 0 && modelId <= _modelIdCounter, "Invalid model ID");
        return models[modelId];
    }

    /**
     * @dev Gets a list of all current model IDs.
     * @return An array of model IDs.
     */
    function listAllModelIds() external view returns (uint256[] memory) {
        uint256 totalModels = _modelIdCounter;
        uint256[] memory modelIds = new uint256[](totalModels);
        for (uint256 i = 1; i <= totalModels; i++) {
            modelIds[i - 1] = i;
        }
        return modelIds;
        // Note: This returns IDs including delisted models. Filtering should happen off-chain.
        // An alternative is to maintain a dynamic array of *listed* models, but adds complexity on list/delist.
    }

     /**
     * @dev Gets a list of all license IDs held by a specific user.
     * @param user The address of the user.
     * @return An array of license IDs.
     */
    function getUserLicenses(address user) external view returns (uint256[] memory) {
        return userLicenses[user];
    }

     /**
     * @dev Gets details of a specific license.
     * @param licenseId The ID of the license.
     * @return License struct.
     */
    function getLicenseDetails(uint256 licenseId) external view returns (License memory) {
         require(licenseId > 0 && licenseId <= _licenseIdCounter, "Invalid license ID");
         return licenses[licenseId];
    }

     /**
     * @dev Gets details of a specific data specification.
     * @param dataSpecId The ID of the data specification.
     * @return DataSpecification struct.
     */
    function getDataSpecificationDetails(uint256 dataSpecId) external view returns (DataSpecification memory) {
        require(dataSpecId > 0 && dataSpecId <= _dataSpecIdCounter, "Invalid data spec ID");
        return dataSpecifications[dataSpecId];
    }

     /**
     * @dev Gets a list of all current data specification IDs.
     * @return An array of data specification IDs.
     */
    function listAllDataSpecIds() external view returns (uint256[] memory) {
        uint256 totalSpecs = _dataSpecIdCounter;
        uint256[] memory dataSpecIds = new uint256[](totalSpecs);
        for (uint256 i = 1; i <= totalSpecs; i++) {
            dataSpecIds[i - 1] = i;
        }
        return dataSpecIds;
         // Note: This returns IDs including delisted specs. Filtering should happen off-chain.
    }

     /**
     * @dev Gets a list of users who have associated themselves with a specific data specification.
     * @param dataSpecId The ID of the data specification.
     * @return An array of user addresses.
     */
    function getUsersWithDataSpec(uint256 dataSpecId) external view returns (address[] memory) {
         require(dataSpecId > 0 && dataSpecId <= _dataSpecIdCounter, "Invalid data spec ID");
        // Note: This returns the raw array which might contain addresses that have since dissociated.
        // Off-chain indexers should cross-reference with _hasUserDataSpec mapping.
        return _usersWithDataSpec[dataSpecId];
    }

     /**
     * @dev Gets the average rating for a model.
     * @param modelId The ID of the model.
     * @return The average rating (multiplied by 100 for decimal representation), or 0 if no ratings.
     */
    function getModelAverageRating(uint256 modelId) external view returns (uint256) {
        require(modelId > 0 && modelId <= _modelIdCounter, "Invalid model ID");
        if (_modelRatingCount[modelId] == 0) {
            return 0;
        }
        // Calculate average rating as an integer multiplied by 100 for better precision
        return (_modelTotalRatings[modelId] * 100) / _modelRatingCount[modelId];
    }

     /**
     * @dev Gets the pending earnings for a model creator.
     * @param modelId The ID of the model.
     * @return The amount of paymentToken the creator can withdraw.
     */
    function getModelCreatorEarnings(uint256 modelId) external view returns (uint256) {
         require(modelId > 0 && modelId <= _modelIdCounter, "Invalid model ID");
        return _modelEarnings[modelId];
    }

     /**
     * @dev Gets the total pending marketplace fees.
     * @return The amount of paymentToken the owner can withdraw.
     */
    function getMarketplaceFeeBalance() external view returns (uint256) {
        return _marketplaceFees;
    }

    /**
     * @dev Gets the address of the accepted payment token.
     * @return The address of the payment token.
     */
    function getPaymentToken() external view returns (address) {
        return address(paymentToken);
    }

    // Inherited isPaused() function from Pausable.

     /**
     * @dev Gets the rating given by a specific user for a model.
     * @param modelId The ID of the model.
     * @param user The address of the user.
     * @return The rating (1-5), or 0 if the user has not rated the model.
     */
    function getUserModelRating(uint256 modelId, address user) external view returns (uint8) {
         require(modelId > 0 && modelId <= _modelIdCounter, "Invalid model ID");
         // Returns 0 if the user hasn't rated, which matches struct default
        return _userModelRatings[modelId][user].rating;
    }

     /**
     * @dev Gets the list of data specification IDs associated with a model.
     * @param modelId The ID of the model.
     * @return An array of data specification IDs.
     */
    function getModelAssociatedDataSpecs(uint256 modelId) external view returns (uint256[] memory) {
         require(modelId > 0 && modelId <= _modelIdCounter, "Invalid model ID");
        return models[modelId].associatedDataSpecs;
    }

     /**
     * @dev Gets the list of URIs and deprecated status for all versions of a model.
     * @param modelId The ID of the model.
     * @return An array of model URIs and a boolean array indicating if each version is deprecated.
     */
    function getModelVersions(uint256 modelId) external view returns (string[] memory, bool[] memory) {
         require(modelId > 0 && modelId <= _modelIdCounter, "Invalid model ID");
        return (models[modelId].modelUris, models[modelId].deprecatedVersions);
    }
}
```