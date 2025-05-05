Okay, let's design a smart contract for a **Decentralized AI Model & Service Marketplace**. This marketplace will allow users to list trained AI models (represented by IPFS hashes or similar off-chain references) and offer access licenses (perpetual, time-limited, pay-per-inference), handle payments, manage licenses, track usage (requiring an off-chain component/oracle), implement reputation, and allow for versioning and basic governance.

This combines elements of ERC-20 payments, licensing, state management for complex entities (models, licenses), interaction patterns with off-chain systems (via roles/events/oracles), and reputation. It aims to be creative by focusing on AI access as the tradable asset on-chain.

---

**Outline & Function Summary:**

This smart contract, `DecentralizedAIModelMarketplace`, facilitates the buying and selling of licenses for accessing AI models and services referenced off-chain.

1.  **Core State Management:** Defines structs for `Model`, `License`, etc., and mappings to store their data.
2.  **Access Control & Pausability:** Uses `Ownable` for administrative functions and `Pausable` for emergency halts. Introduces a `ComputeProvider` role for reporting model usage.
3.  **Model Management:** Functions for registering, updating, delisting, and querying AI models. Supports versioning.
4.  **License Management:** Functions for purchasing, querying, checking validity, and transferring licenses. Defines different license types.
5.  **Payment & Fees:** Handles payment for licenses using supported ERC-20 tokens, distributes earnings, and manages marketplace fees.
6.  **Usage Tracking (Requires Off-chain Interaction):** A function (`recordUsage`) intended to be called by authorized compute providers or oracles to track pay-per-inference license usage.
7.  **Reputation System:** Allows buyers to rate models, calculates average ratings.
8.  **Discounts & Refunds:** Allows model owners to offer discounts and admin to process refunds.
9.  **Configuration:** Admin functions to set fees, supported tokens, and manage compute provider roles.
10. **Querying:** Functions to retrieve various data points (models by owner, user licenses, ratings, etc.).

**Function Summary (Minimum 20+):**

1.  `constructor()`: Initializes the contract owner.
2.  `registerModel(string modelName, string modelHash, string docsHash, uint256 pricePerUse, uint256 perpetualPrice, uint256 timeBasedPrice, uint256 timeBasedDuration, uint256 discountPercentage, uint256 discountExpiry)`: Registers a new AI model with initial pricing and discount info.
3.  `updateModelDetails(uint256 modelId, string modelHash, string docsHash, string modelName)`: Updates metadata and hashes for an existing model version.
4.  `addNewModelVersion(uint256 modelId, string modelHash, string docsHash)`: Registers a new version for an existing model.
5.  `updateModelPricing(uint256 modelId, uint256 pricePerUse, uint256 perpetualPrice, uint256 timeBasedPrice, uint256 timeBasedDuration)`: Updates license pricing for a model's latest version.
6.  `updateModelDiscount(uint256 modelId, uint256 discountPercentage, uint256 discountExpiry)`: Sets or updates a model's discount.
7.  `delistModel(uint256 modelId)`: Delists a model, making new purchases unavailable.
8.  `relistModel(uint256 modelId)`: Relists a previously delisted model.
9.  `getModelDetails(uint256 modelId)`: Retrieves details for the latest version of a model.
10. `getModelVersionDetails(uint256 modelId, uint256 version)`: Retrieves details for a specific model version.
11. `listModelsByOwner(address owner)`: Lists all model IDs owned by an address.
12. `listAllActiveModels(uint256 offset, uint256 limit)`: Lists active model IDs with pagination.
13. `purchaseLicense(uint256 modelId, LicenseType licenseType, address paymentToken)`: Purchases a license for a model using a supported token (requires prior `approve`).
14. `getUserLicenses(address user)`: Lists all license IDs owned by a user.
15. `getLicenseDetails(uint256 licenseId)`: Retrieves details for a specific license.
16. `checkLicenseValidity(uint256 licenseId)`: Checks if a license is currently active and valid.
17. `recordUsage(uint256 licenseId, uint256 amount)`: Records usage for a pay-per-inference license (callable by `ComputeProvider` role).
18. `transferLicense(uint256 licenseId, address newOwner)`: Transfers ownership of a perpetual or time-based license.
19. `submitRating(uint256 modelId, uint8 rating)`: Allows a buyer to rate a model after purchase/usage.
20. `getModelAverageRating(uint256 modelId)`: Calculates and returns the average rating for a model.
21. `withdrawEarnings(address paymentToken)`: Model owner withdraws their accumulated earnings for a specific token.
22. `withdrawFees(address paymentToken)`: Admin withdraws accumulated marketplace fees for a specific token.
23. `setMarketplaceFee(uint256 feePercentage)`: Admin sets the marketplace fee percentage.
24. `addSupportedPaymentToken(address tokenAddress)`: Admin adds a token to the list of supported payment tokens.
25. `removeSupportedPaymentToken(address tokenAddress)`: Admin removes a token from the supported list.
26. `grantComputeProviderRole(address provider)`: Admin grants the compute provider role.
27. `revokeComputeProviderRole(address provider)`: Admin revokes the compute provider role.
28. `pause()`: Admin pauses contract operations.
29. `unpause()`: Admin unpauses contract operations.
30. `requestRefund(uint256 licenseId)`: (Placeholder/Initiation) User requests a refund. Requires off-chain or admin action. *Self-correction:* Let's make it an Admin-approved refund function to keep it on-chain. `processRefund(uint256 licenseId, address paymentToken)`: Admin processes a refund for a license.

Okay, we have 30 functions defined, exceeding the requirement of 20. Let's implement the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline & Function Summary (See above)

contract DecentralizedAIModelMarketplace is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    enum LicenseType { None, Perpetual, TimeBased, PayPerInference }
    enum ModelStatus { Active, Delisted }

    struct ModelVersion {
        string modelHash; // IPFS hash or similar reference to model files
        string docsHash;  // IPFS hash or similar reference to documentation
        uint256 version;
        uint256 createdAt;
    }

    struct Model {
        uint256 id;
        address owner;
        string name;
        ModelStatus status;
        uint256 currentVersion;
        mapping(uint256 => ModelVersion) versions; // Version number => details

        // Pricing for latest version
        uint256 pricePerUse;
        uint256 perpetualPrice;
        uint256 timeBasedPrice; // Price for timeBasedDuration
        uint256 timeBasedDuration; // Duration in seconds

        // Discount for latest version
        uint256 discountPercentage; // 0-10000 (for 0.00% to 100.00%)
        uint256 discountExpiry; // Timestamp until discount is valid

        // Rating
        uint256 totalRatingPoints;
        uint256 ratingCount;

        uint256 versionCount; // To track next version number
    }

    struct License {
        uint256 id;
        uint256 modelId;
        address buyer;
        LicenseType licenseType;
        uint256 purchasePrice; // Price paid for THIS license
        address paymentToken;
        uint256 purchasedAt;
        uint256 expiresAt; // Used for TimeBased licenses
        uint256 usageRemaining; // Used for PayPerInference licenses
        uint256 usageLimit; // Initial usage limit for PayPerInference
        bool isActive; // Can be set to false by admin for refunds/revocation
    }

    uint256 private modelCounter;
    uint256 private licenseCounter;

    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) private modelsByOwner;
    mapping(uint256 => License) public licenses;
    mapping(address => uint256[]) private licensesByUser;

    mapping(address => mapping(address => uint256)) public modelOwnerEarnings; // modelOwner => tokenAddress => amount
    mapping(address => mapping(address => uint256)) public marketplaceFees; // tokenAddress => amount

    uint256 public marketplaceFeePercentage; // 0-10000 (for 0.00% to 100.00%)

    mapping(address => bool) public supportedPaymentTokens;
    address[] public supportedPaymentTokenList; // To easily list supported tokens

    mapping(address => bool) public isComputeProvider; // Role allowed to record usage

    // Events
    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, string modelHash, uint256 version);
    event ModelVersionAdded(uint256 indexed modelId, uint256 version, string modelHash);
    event ModelDetailsUpdated(uint256 indexed modelId, uint256 version, string modelHash);
    event ModelPricingUpdated(uint256 indexed modelId, uint256 pricePerUse, uint256 perpetualPrice, uint256 timeBasedPrice, uint256 timeBasedDuration);
    event ModelDiscountUpdated(uint256 indexed modelId, uint256 discountPercentage, uint256 discountExpiry);
    event ModelStatusUpdated(uint256 indexed modelId, ModelStatus status);
    event LicensePurchased(uint256 indexed licenseId, uint256 indexed modelId, address indexed buyer, LicenseType licenseType, uint256 pricePaid, address paymentToken);
    event LicenseUsageRecorded(uint256 indexed licenseId, uint256 amountUsed, uint256 usageRemaining);
    event LicenseTransferred(uint256 indexed licenseId, address indexed oldOwner, address indexed newOwner);
    event RatingSubmitted(uint256 indexed modelId, address indexed rater, uint8 rating, uint256 averageRating);
    event EarningsWithdrawn(address indexed owner, address indexed token, uint256 amount);
    event FeesWithdrawn(address indexed admin, address indexed token, uint256 amount);
    event MarketplaceFeeUpdated(uint256 feePercentage);
    event SupportedPaymentTokenAdded(address indexed token);
    event SupportedPaymentTokenRemoved(address indexed token);
    event ComputeProviderRoleGranted(address indexed provider);
    event ComputeProviderRoleRevoked(address indexed provider);
    event RefundProcessed(uint256 indexed licenseId, address indexed recipient, uint256 amount, address paymentToken);

    constructor() Ownable(msg.sender) {}

    // --- Access Control & Pausability ---

    modifier onlyModelOwner(uint256 _modelId) {
        require(models[_modelId].owner == msg.sender, "Not model owner");
        _;
    }

     modifier onlyLicenseBuyer(uint256 _licenseId) {
        require(licenses[_licenseId].buyer == msg.sender, "Not license buyer");
        _;
    }

    modifier onlyComputeProvider() {
        require(isComputeProvider[msg.sender], "Not a compute provider");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function grantComputeProviderRole(address provider) public onlyOwner {
        require(provider != address(0), "Invalid address");
        isComputeProvider[provider] = true;
        emit ComputeProviderRoleGranted(provider);
    }

    function revokeComputeProviderRole(address provider) public onlyOwner {
         require(provider != address(0), "Invalid address");
        isComputeProvider[provider] = false;
        emit ComputeProviderRoleRevoked(provider);
    }

    // --- Model Management ---

    function registerModel(
        string memory modelName,
        string memory modelHash,
        string memory docsHash,
        uint256 pricePerUse,
        uint256 perpetualPrice,
        uint256 timeBasedPrice,
        uint256 timeBasedDuration, // in seconds
        uint256 discountPercentage,
        uint256 discountExpiry // timestamp
    ) public whenNotPaused nonReentrant returns (uint256 modelId) {
        require(bytes(modelName).length > 0, "Model name required");
        require(bytes(modelHash).length > 0, "Model hash required");
        require(discountPercentage <= 10000, "Discount percentage invalid");

        modelCounter = modelCounter.add(1);
        modelId = modelCounter;

        Model storage newModel = models[modelId];
        newModel.id = modelId;
        newModel.owner = msg.sender;
        newModel.name = modelName;
        newModel.status = ModelStatus.Active;
        newModel.currentVersion = 1;
        newModel.versionCount = 1;

        ModelVersion storage firstVersion = newModel.versions[1];
        firstVersion.modelHash = modelHash;
        firstVersion.docsHash = docsHash;
        firstVersion.version = 1;
        firstVersion.createdAt = block.timestamp;

        newModel.pricePerUse = pricePerUse;
        newModel.perpetualPrice = perpetualPrice;
        newModel.timeBasedPrice = timeBasedPrice;
        newModel.timeBasedDuration = timeBasedDuration;
        newModel.discountPercentage = discountPercentage;
        newModel.discountExpiry = discountExpiry;

        modelsByOwner[msg.sender].push(modelId);

        emit ModelRegistered(modelId, msg.sender, modelName, modelHash, 1);
    }

    function updateModelDetails(uint256 modelId, string memory modelHash, string memory docsHash, string memory modelName)
        public
        onlyModelOwner(modelId)
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[modelId];
        model.name = modelName;
        // These update the *current* version's details
        model.versions[model.currentVersion].modelHash = modelHash;
        model.versions[model.currentVersion].docsHash = docsHash;

        emit ModelDetailsUpdated(modelId, model.currentVersion, modelHash);
    }

     function addNewModelVersion(uint256 modelId, string memory modelHash, string memory docsHash)
        public
        onlyModelOwner(modelId)
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[modelId];
        require(bytes(modelHash).length > 0, "Model hash required");

        model.versionCount = model.versionCount.add(1);
        uint256 newVersionNumber = model.versionCount;
        model.currentVersion = newVersionNumber; // Make this the current version

        ModelVersion storage newVersion = model.versions[newVersionNumber];
        newVersion.modelHash = modelHash;
        newVersion.docsHash = docsHash;
        newVersion.version = newVersionNumber;
        newVersion.createdAt = block.timestamp;

        emit ModelVersionAdded(modelId, newVersionNumber, modelHash);
    }

    function updateModelPricing(uint256 modelId, uint256 pricePerUse, uint256 perpetualPrice, uint256 timeBasedPrice, uint256 timeBasedDuration)
        public
        onlyModelOwner(modelId)
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[modelId];
        model.pricePerUse = pricePerUse;
        model.perpetualPrice = perpetualPrice;
        model.timeBasedPrice = timeBasedPrice;
        model.timeBasedDuration = timeBasedDuration;

        emit ModelPricingUpdated(modelId, pricePerUse, perpetualPrice, timeBasedPrice, timeBasedDuration);
    }

    function updateModelDiscount(uint256 modelId, uint256 discountPercentage, uint256 discountExpiry)
        public
        onlyModelOwner(modelId)
        whenNotPaused
        nonReentrant
    {
        require(discountPercentage <= 10000, "Discount percentage invalid");
        Model storage model = models[modelId];
        model.discountPercentage = discountPercentage;
        model.discountExpiry = discountExpiry;

        emit ModelDiscountUpdated(modelId, discountPercentage, discountExpiry);
    }

    function delistModel(uint256 modelId) public onlyModelOwner(modelId) whenNotPaused {
        models[modelId].status = ModelStatus.Delisted;
        emit ModelStatusUpdated(modelId, ModelStatus.Delisted);
    }

    function relistModel(uint256 modelId) public onlyModelOwner(modelId) whenNotPaused {
        models[modelId].status = ModelStatus.Active;
        emit ModelStatusUpdated(modelId, ModelStatus.Active);
    }

    function getModelDetails(uint256 modelId)
        public
        view
        returns (uint256 id, address owner, string memory name, ModelStatus status, uint256 currentVersion, string memory modelHash, string memory docsHash, uint256 pricePerUse, uint256 perpetualPrice, uint256 timeBasedPrice, uint256 timeBasedDuration, uint256 discountPercentage, uint256 discountExpiry, uint256 averageRating, uint256 ratingCount)
    {
        Model storage model = models[modelId];
        require(model.id != 0, "Model does not exist");
        ModelVersion storage latestVersion = model.versions[model.currentVersion];

        averageRating = model.ratingCount > 0 ? model.totalRatingPoints.div(model.ratingCount) : 0;

        return (
            model.id,
            model.owner,
            model.name,
            model.status,
            model.currentVersion,
            latestVersion.modelHash,
            latestVersion.docsHash,
            model.pricePerUse,
            model.perpetualPrice,
            model.timeBasedPrice,
            model.timeBasedDuration,
            model.discountPercentage,
            model.discountExpiry,
            averageRating,
            model.ratingCount
        );
    }

     function getModelVersionDetails(uint256 modelId, uint256 version)
        public
        view
        returns (uint256 modelId_, uint256 version_, string memory modelHash, string memory docsHash, uint256 createdAt)
    {
        Model storage model = models[modelId];
        require(model.id != 0, "Model does not exist");
        require(version > 0 && version <= model.versionCount, "Invalid version");

        ModelVersion storage modelVersion = model.versions[version];

        return (
            model.id,
            modelVersion.version,
            modelVersion.modelHash,
            modelVersion.docsHash,
            modelVersion.createdAt
        );
    }

    function listModelsByOwner(address owner) public view returns (uint256[] memory) {
        return modelsByOwner[owner];
    }

     // Helper to get total active models for pagination
    function getTotalActiveModels() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= modelCounter; i = i.add(1)) {
            if (models[i].id != 0 && models[i].status == ModelStatus.Active) {
                 count = count.add(1);
            }
        }
        return count;
    }

    function listAllActiveModels(uint256 offset, uint256 limit) public view returns (uint256[] memory) {
        uint256 total = getTotalActiveModels();
        require(offset <= total, "Offset out of bounds");

        uint256 count = 0;
        uint256[] memory activeModelIds = new uint256[](Math.min(limit, total.sub(offset))); // Using Math.min from OpenZeppelin if needed, else simple check

        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= modelCounter; i = i.add(1)) {
             if (models[i].id != 0 && models[i].status == ModelStatus.Active) {
                if (currentIndex >= offset && count < limit) {
                    activeModelIds[count] = i;
                    count = count.add(1);
                }
                currentIndex = currentIndex.add(1);
            }
        }
        return activeModelIds;
    }


    // --- License Management ---

    function purchaseLicense(uint256 modelId, LicenseType licenseType, address paymentToken)
        public
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[modelId];
        require(model.id != 0, "Model does not exist");
        require(model.status == ModelStatus.Active, "Model is not active");
        require(licenseType != LicenseType.None, "Invalid license type");
        require(supportedPaymentTokens[paymentToken], "Payment token not supported");
        require(model.owner != msg.sender, "Cannot purchase your own license");

        uint256 rawPrice;
        uint256 duration = 0; // seconds
        uint256 usageLimit = 0;

        if (licenseType == LicenseType.Perpetual) {
            require(model.perpetualPrice > 0, "Perpetual license not offered or price is zero");
            rawPrice = model.perpetualPrice;
        } else if (licenseType == LicenseType.TimeBased) {
            require(model.timeBasedPrice > 0 && model.timeBasedDuration > 0, "Time-based license not offered or price/duration is zero");
            rawPrice = model.timeBasedPrice;
            duration = model.timeBasedDuration;
        } else if (licenseType == LicenseType.PayPerInference) {
            require(model.pricePerUse > 0, "Pay-per-inference license not offered or price is zero");
            // For PayPerInference, the *purchase* price might be zero or a base fee,
            // and actual usage is tracked per inference. Let's assume the 'pricePerUse'
            // here is the price *per unit of usage*, and the buyer pays for a *bundle*
            // of usage upfront, or maybe just registers intent.
            // Let's refine: The purchase price is for a *bundle* of usage. The user specifies the amount they want.
            // This requires a different function signature, or the quantity as a parameter.
            // Let's assume `pricePerUse` is the cost *per unit*, and the user pays for N units.
            // User needs to call `purchaseUsageUnits(modelId, units, paymentToken)` instead.
            // Let's stick to the three *license types* first. `pricePerUse` is the *cost* per use,
            // and payment happens *when usage is recorded* in a more advanced system, or
            // they buy a bundle of uses upfront. Let's make `PayPerInference` require buying
            // a specific `usageLimit` at the `pricePerUse` rate.
             revert("PayPerInference licenses require buying usage units. Use purchaseUsageUnits.");
        } else {
             revert("Unsupported license type");
        }

        // Calculate discounted price if applicable
        uint256 finalPrice = rawPrice;
        if (model.discountExpiry > block.timestamp && model.discountPercentage > 0) {
            uint256 discountAmount = rawPrice.mul(model.discountPercentage).div(10000);
            finalPrice = rawPrice.sub(discountAmount);
        }

        require(finalPrice > 0, "Calculated price is zero"); // Should not happen if rawPrice > 0, but safety check

        // Handle Payment using ERC20 transferFrom
        IERC20 token = IERC20(paymentToken);
        require(token.transferFrom(msg.sender, address(this), finalPrice), "Token transfer failed");

        // Calculate fees and owner earnings
        uint256 marketplaceFee = finalPrice.mul(marketplaceFeePercentage).div(10000);
        uint256 ownerEarnings = finalPrice.sub(marketplaceFee);

        marketplaceFees[paymentToken] = marketplaceFees[paymentToken].add(marketplaceFee);
        modelOwnerEarnings[model.owner][paymentToken] = modelOwnerEarnings[model.owner][paymentToken].add(ownerEarnings);

        // Create License
        licenseCounter = licenseCounter.add(1);
        uint256 licenseId = licenseCounter;

        License storage newLicense = licenses[licenseId];
        newLicense.id = licenseId;
        newLicense.modelId = modelId;
        newLicense.buyer = msg.sender;
        newLicense.licenseType = licenseType;
        newLicense.purchasePrice = finalPrice;
        newLicense.paymentToken = paymentToken;
        newLicense.purchasedAt = block.timestamp;
        newLicense.isActive = true;

        if (licenseType == LicenseType.TimeBased) {
            newLicense.expiresAt = block.timestamp.add(duration);
        }
        // PayPerInference licenses are handled by purchaseUsageUnits

        licensesByUser[msg.sender].push(licenseId);

        emit LicensePurchased(licenseId, modelId, msg.sender, licenseType, finalPrice, paymentToken);
    }

     // New function specifically for purchasing PayPerInference units
     function purchaseUsageUnits(uint256 modelId, uint256 units, address paymentToken)
        public
        whenNotPaused
        nonReentrant
     {
        Model storage model = models[modelId];
        require(model.id != 0, "Model does not exist");
        require(model.status == ModelStatus.Active, "Model is not active");
        require(model.pricePerUse > 0, "Pay-per-inference not offered or price is zero");
        require(units > 0, "Must purchase at least one unit");
        require(supportedPaymentTokens[paymentToken], "Payment token not supported");
        require(model.owner != msg.sender, "Cannot purchase your own license");

        uint256 rawPrice = model.pricePerUse.mul(units);

        // Calculate discounted price if applicable
        uint256 finalPrice = rawPrice;
        if (model.discountExpiry > block.timestamp && model.discountPercentage > 0) {
            uint256 discountAmount = rawPrice.mul(model.discountPercentage).div(10000);
            finalPrice = rawPrice.sub(discountAmount);
        }

        require(finalPrice > 0, "Calculated price is zero");

         // Handle Payment using ERC20 transferFrom
        IERC20 token = IERC20(paymentToken);
        require(token.transferFrom(msg.sender, address(this), finalPrice), "Token transfer failed");

        // Calculate fees and owner earnings
        uint256 marketplaceFee = finalPrice.mul(marketplaceFeePercentage).div(10000);
        uint256 ownerEarnings = finalPrice.sub(marketplaceFee);

        marketplaceFees[paymentToken] = marketplaceFees[paymentToken].add(marketplaceFee);
        modelOwnerEarnings[model.owner][paymentToken] = modelOwnerEarnings[model.owner][paymentToken].add(ownerEarnings);


        // Find or create a PayPerInference license for this user/model
        // It's better to have one license per user/model for PayPerInference and add units to it.
        // Or create a new license for each purchase bundle? Let's create a new license bundle for simplicity here.
        // A more advanced system might track usage per user per model across multiple bundles.

        licenseCounter = licenseCounter.add(1);
        uint256 licenseId = licenseCounter;

        License storage newLicense = licenses[licenseId];
        newLicense.id = licenseId;
        newLicense.modelId = modelId;
        newLicense.buyer = msg.sender;
        newLicense.licenseType = LicenseType.PayPerInference;
        newLicense.purchasePrice = finalPrice;
        newLicense.paymentToken = paymentToken;
        newLicense.purchasedAt = block.timestamp;
        newLicense.isActive = true;
        newLicense.usageLimit = units; // Store initial limit
        newLicense.usageRemaining = units; // Initial remaining units

        licensesByUser[msg.sender].push(licenseId);

        emit LicensePurchased(licenseId, modelId, msg.sender, LicenseType.PayPerInference, finalPrice, paymentToken);
     }


    function getUserLicenses(address user) public view returns (uint256[] memory) {
        return licensesByUser[user];
    }

    function getLicenseDetails(uint256 licenseId)
        public
        view
        returns (uint256 id, uint256 modelId, address buyer, LicenseType licenseType, uint256 purchasePrice, address paymentToken, uint256 purchasedAt, uint256 expiresAt, uint256 usageRemaining, bool isActive)
    {
        License storage license = licenses[licenseId];
        require(license.id != 0, "License does not exist");

         return (
            license.id,
            license.modelId,
            license.buyer,
            license.licenseType,
            license.purchasePrice,
            license.paymentToken,
            license.purchasedAt,
            license.expiresAt,
            license.usageRemaining,
            license.isActive
        );
    }


    function checkLicenseValidity(uint256 licenseId) public view returns (bool) {
        License storage license = licenses[licenseId];
        if (license.id == 0 || !license.isActive) {
            return false;
        }

        if (license.licenseType == LicenseType.Perpetual) {
            return true;
        } else if (license.licenseType == LicenseType.TimeBased) {
            return license.expiresAt > block.timestamp;
        } else if (license.licenseType == LicenseType.PayPerInference) {
            return license.usageRemaining > 0;
        }
         return false; // Should not reach here for valid license types
    }

    // This function is intended to be called by a trusted compute provider/oracle
    // after they have verified off-chain usage of a PayPerInference license.
    function recordUsage(uint256 licenseId, uint256 amount) public onlyComputeProvider whenNotPaused nonReentrant {
        License storage license = licenses[licenseId];
        require(license.id != 0, "License does not exist");
        require(license.licenseType == LicenseType.PayPerInference, "License is not pay-per-inference");
        require(license.isActive, "License is not active");
        require(license.usageRemaining >= amount, "Not enough usage remaining");
        require(amount > 0, "Amount must be greater than 0");

        license.usageRemaining = license.usageRemaining.sub(amount);

        // If usage hits zero, deactivate the license
        if (license.usageRemaining == 0) {
            license.isActive = false;
        }

        emit LicenseUsageRecorded(licenseId, amount, license.usageRemaining);
    }

     function transferLicense(uint256 licenseId, address newOwner) public onlyLicenseBuyer(licenseId) whenNotPaused nonReentrant {
        License storage license = licenses[licenseId];
        require(license.licenseType == LicenseType.Perpetual || license.licenseType == LicenseType.TimeBased, "Only Perpetual or Time-Based licenses can be transferred");
        require(license.isActive, "License is not active");
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != msg.sender, "Cannot transfer to yourself");

        address oldOwner = license.buyer;
        license.buyer = newOwner;

        // Remove from old owner's list (inefficient, but simple for example. A set/linked list is better for large lists)
        uint256[] storage oldOwnerLicenses = licensesByUser[oldOwner];
        for (uint i = 0; i < oldOwnerLicenses.length; i++) {
            if (oldOwnerLicenses[i] == licenseId) {
                 // Swap with last element and pop
                oldOwnerLicenses[i] = oldOwnerLicenses[oldOwnerLicenses.length - 1];
                oldOwnerLicenses.pop();
                break;
            }
        }

        // Add to new owner's list
        licensesByUser[newOwner].push(licenseId);

        emit LicenseTransferred(licenseId, oldOwner, newOwner);
     }

    // --- Reputation System ---

    function submitRating(uint256 modelId, uint8 rating) public whenNotPaused nonReentrant {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        Model storage model = models[modelId];
        require(model.id != 0, "Model does not exist");
        require(model.owner != msg.sender, "Cannot rate your own model");

        // Check if the user has ever purchased a license for this model
        // This requires iterating through user's licenses, which can be gas-intensive.
        // A better approach might be a mapping `mapping(address => mapping(uint256 => bool)) hasPurchased;`
        // Let's implement the simple check for now, but note the inefficiency.
        bool hasPurchased = false;
        uint256[] storage userLicenses = licensesByUser[msg.sender];
        for (uint i = 0; i < userLicenses.length; i++) {
            if (licenses[userLicenses[i]].modelId == modelId) {
                hasPurchased = true;
                break;
            }
        }
        require(hasPurchased, "Must purchase a license to rate this model");

        // Simple rating aggregation (average). Can only rate once per model.
        // For re-rating, you'd need more complex state (e.g., mapping user => model => rating)
        // Let's allow rating only once per model purchase history (simple check above).
        // To prevent multiple ratings per purchase *bundle* (e.g., PayPerInference bundles),
        // you'd need to track rated licenses: `mapping(uint256 => bool) licenseRated;` and check/set it here.
        // For simplicity here, let's just track if the *user* has rated the *model*. Add a mapping:
        mapping(address => mapping(uint256 => bool)) private userRatedModel;
        require(!userRatedModel[msg.sender][modelId], "Already rated this model");

        userRatedModel[msg.sender][modelId] = true;
        model.totalRatingPoints = model.totalRatingPoints.add(rating);
        model.ratingCount = model.ratingCount.add(1);

        uint256 averageRating = model.totalRatingCount > 0 ? model.totalRatingPoints.div(model.ratingCount) : 0;

        emit RatingSubmitted(modelId, msg.sender, rating, averageRating);
    }

    function getModelAverageRating(uint256 modelId) public view returns (uint256 averageRating, uint256 ratingCount) {
        Model storage model = models[modelId];
        require(model.id != 0, "Model does not exist");
        averageRating = model.ratingCount > 0 ? model.totalRatingPoints.div(model.ratingCount) : 0;
        return (averageRating, model.ratingCount);
    }

    // Note: Calculating User Average Rating (as a provider) would require iterating through
    // all models owned by the user and summing their ratings, which is gas-intensive.
    // It's better done off-chain or with a dedicated reputation system contract.
    // We'll omit getUserAverageRating as it's too complex/inefficient for a simple example.

    // --- Financials ---

    function withdrawEarnings(address paymentToken) public whenNotPaused nonReentrant {
        uint256 amount = modelOwnerEarnings[msg.sender][paymentToken];
        require(amount > 0, "No earnings to withdraw");

        modelOwnerEarnings[msg.sender][paymentToken] = 0;

        IERC20 token = IERC20(paymentToken);
        require(token.transfer(msg.sender, amount), "Earnings withdrawal failed");

        emit EarningsWithdrawn(msg.sender, paymentToken, amount);
    }

    function withdrawFees(address paymentToken) public onlyOwner whenNotPaused nonReentrant {
        uint256 amount = marketplaceFees[paymentToken];
        require(amount > 0, "No fees to withdraw");

        marketplaceFees[paymentToken] = 0;

        IERC20 token = IERC20(paymentToken);
        require(token.transfer(msg.sender, amount), "Fee withdrawal failed");

        emit FeesWithdrawn(msg.sender, paymentToken, amount);
    }

    function setMarketplaceFee(uint256 feePercentage) public onlyOwner {
        require(feePercentage <= 10000, "Fee percentage invalid");
        marketplaceFeePercentage = feePercentage;
        emit MarketplaceFeeUpdated(feePercentage);
    }

     function addSupportedPaymentToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Invalid address");
        require(!supportedPaymentTokens[tokenAddress], "Token already supported");
        supportedPaymentTokens[tokenAddress] = true;
        supportedPaymentTokenList.push(tokenAddress);
        emit SupportedPaymentTokenAdded(tokenAddress);
    }

    function removeSupportedPaymentToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Invalid address");
        require(supportedPaymentTokens[tokenAddress], "Token not supported");
        supportedPaymentTokens[tokenAddress] = false;

        // Remove from list (inefficient iteration)
        for (uint i = 0; i < supportedPaymentTokenList.length; i++) {
            if (supportedPaymentTokenList[i] == tokenAddress) {
                supportedPaymentTokenList[i] = supportedPaymentTokenList[supportedPaymentTokenList.length - 1];
                supportedPaymentTokenList.pop();
                break;
            }
        }
        emit SupportedPaymentTokenRemoved(tokenAddress);
    }

    function getSupportedPaymentTokens() public view returns (address[] memory) {
        return supportedPaymentTokenList;
    }

    // Admin initiated refund function
    function processRefund(uint256 licenseId) public onlyOwner whenNotPaused nonReentrant {
        License storage license = licenses[licenseId];
        require(license.id != 0, "License does not exist");
        require(license.isActive, "License is not active"); // Can only refund active licenses in this simple model

        license.isActive = false; // Deactivate the license

        // Calculate amount to refund. Simple model refunds the full purchase price.
        // More complex could involve partial refunds based on usage/time.
        uint256 refundAmount = license.purchasePrice;
        address paymentToken = license.paymentToken;

        // Deduct from earnings/fees (simplistic - assumes funds are still in contract)
        // In reality, need to check if owner/admin already withdrew. If withdrawn,
        // admin might need to manually cover or the system design needs escrow.
        // Let's assume funds might still be here or admin covers deficit.
        uint256 marketplaceFee = refundAmount.mul(marketplaceFeePercentage).div(10000);
        uint256 ownerEarnings = refundAmount.sub(marketplaceFee);

        // Attempt to deduct from stored earnings/fees. This is flawed if they were withdrawn.
        // A more robust system holds earnings in escrow or has a proper accounting system.
        // For this example, we deduct assuming the owner *might* have withdrawn,
        // but the admin is responsible for the actual token transfer regardless.
         if (marketplaceFees[paymentToken] >= marketplaceFee) {
             marketplaceFees[paymentToken] = marketplaceFees[paymentToken].sub(marketplaceFee);
         } else {
             marketplaceFees[paymentToken] = 0; // Admin covers the difference
         }

         address modelOwner = models[license.modelId].owner;
         if (modelOwnerEarnings[modelOwner][paymentToken] >= ownerEarnings) {
             modelOwnerEarnings[modelOwner][paymentToken] = modelOwnerEarnings[modelOwner][paymentToken].sub(ownerEarnings);
         } else {
             modelOwnerEarnings[modelOwner][paymentToken] = 0; // Admin covers the difference
         }


        // Transfer refund amount to the buyer
        IERC20 token = IERC20(paymentToken);
        // This transfer is the critical part. Admin must ensure the contract has the balance
        // or manually send tokens if the contract balance is insufficient due to prior withdrawals.
        // This function only *initiates* the refund and adjusts internal balances.
        // The actual token sending should ideally be guaranteed by having funds locked.
        // For this example, we perform the transfer from the contract's balance.
        require(token.transfer(license.buyer, refundAmount), "Refund transfer failed");

        emit RefundProcessed(licenseId, license.buyer, refundAmount, paymentToken);
    }

    // --- Querying ---

    function getUserEarnings(address ownerAddress, address paymentToken) public view returns (uint256) {
        return modelOwnerEarnings[ownerAddress][paymentToken];
    }

    function getMarketplaceFees(address paymentToken) public view returns (uint256) {
        return marketplaceFees[paymentToken];
    }

    function isAddressComputeProvider(address account) public view returns (bool) {
        return isComputeProvider[account];
    }

    // Fallback/Receive to prevent accidental ETH sends without a function
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
         revert("Calls to non-existent functions");
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **AI Model Licensing (as an Asset):** The core concept is tokenizing access rights to AI models. This isn't about selling the model files themselves on-chain (impossible/impractical) but selling *licenses* to *use* or *access* the model via off-chain infrastructure.
2.  **Multiple License Types:** Differentiating between Perpetual, Time-Based, and Pay-Per-Inference licenses adds complexity and reflects real-world software/service licensing models.
3.  **Pay-Per-Inference Tracking:** The `recordUsage` function models interaction with an off-chain compute layer or oracle network. The smart contract *cannot* run the AI or verify the computation itself. It relies on a trusted role (`ComputeProvider`) to report usage, which is a common pattern for integrating off-chain work with on-chain state.
4.  **Model Versioning:** Allowing model owners to register new versions while keeping old ones accessible (if licenses permit) is crucial for software/model lifecycle management.
5.  **Role-Based Access Control (Custom Role):** Beyond standard `Ownable`, the `ComputeProvider` role demonstrates a custom access pattern needed for specific off-chain interactions (`recordUsage`).
6.  **ERC-20 Payment Flexibility:** Supporting multiple ERC-20 tokens for payments adds flexibility compared to only using native chain currency.
7.  **Marketplace Fees & Earnings Distribution:** Automatically splitting payment between the model owner and the marketplace fee is standard but essential for a marketplace.
8.  **Basic Reputation (Ratings):** Allowing users who purchased a license to rate models adds a decentralized reputation layer.
9.  **Discounts:** Implementing temporary discounts adds a dynamic pricing element.
10. **License Transferability:** Allowing the transfer of certain license types (`Perpetual`, `TimeBased`) makes the license itself a potentially tradable asset on secondary markets (though this contract doesn't include a secondary market, the transfer function enables it).
11. **Refunds (Admin-Initiated):** While basic, having an on-chain mechanism for refunds (even if admin-approved) is important for a robust marketplace. Note the simplification in handling fund availability in this example.
12. **Pausability:** Essential for critical upgrades or responding to unexpected events in a complex contract.
13. **Reentrancy Guard:** Standard but necessary protection when dealing with token transfers.
14. **Structured Data:** Using structs and mappings to manage complex relationships between models, versions, licenses, and users is fundamental but key to organizing the marketplace state.
15. **Event Logging:** Extensive events allow off-chain applications (frontends, indexers, oracles) to track state changes efficiently without reading contract storage directly.
16. **Pagination for Listings:** `listAllActiveModels` includes basic pagination logic, important for handling potentially large lists of items on-chain efficiently for off-chain consumption.
17. **Explicit Supported Tokens List:** Managing a list of accepted payment tokens provides clarity and control.
18. **Separation of Concerns:** Distinguishing between model details (`Model`) and specific purchase instances (`License`) is good design.
19. **Calculation of Fees and Discounts On-Chain:** Performing these calculations directly in the `purchaseLicense` function ensures transparency and correctness based on the contract's state.
20. **State Changes Before External Calls:** Following the Checks-Effects-Interactions pattern (though simplified as transfers are the main interaction) is crucial for security.

This contract provides a solid framework for a decentralized AI model *access* marketplace on-chain, handling the licensing, payment, and state-tracking aspects, while acknowledging the need for off-chain components to handle the actual AI computation and usage verification.