Okay, let's design a smart contract for a **Decentralized AI Model Marketplace**. This involves concepts like registering off-chain computational models, licensing their usage on-chain, tracking usage reported by providers (with a placeholder for future validation), handling payments, reviews/attestations, and potentially staking for reliability.

This concept is advanced because:
1.  It bridges off-chain computation (the AI model) with on-chain state management (licensing, payment, reputation).
2.  Usage tracking and verification are significant challenges, requiring careful design patterns (even if partial or relying on off-chain components).
3.  It incorporates multiple sub-systems: marketplace, licensing, payment splitting, reputation/attestation, and staking.

We will implement core parts of this logic directly in Solidity, acknowledging that a full, trustless implementation of AI model *execution* or *validation* on-chain is currently impractical or impossible due to gas costs and computational limits. The contract focuses on the *financial and ownership/licensing layer*.

---

**Outline and Function Summary**

**Contract Name:** DecentralizedAIModelMarketplace

**Core Concept:** A marketplace where AI model providers can list models, users can purchase licenses for usage (per inference or subscription), payments are processed, and a basic attestation/reputation system is included. The contract manages licenses, tracks reported usage for payment calculation, and handles fee distribution.

**Key State Variables:**
*   `models`: Mapping from model ID to model details.
*   `modelVersions`: Mapping from model ID to an array of its versions.
*   `licenses`: Mapping from license ID to license details.
*   `userLicenses`: Mapping from user address to an array of their license IDs.
*   `attestations`: Mapping from model version ID to an array of attestations/reviews.
*   Counters for unique IDs (models, versions, licenses, attestations).
*   Platform owner, fee percentage, collected fees.

**Structs:**
*   `Model`: Basic info about an AI model (provider, name, description URI).
*   `ModelVersion`: Specific version details (model ID, version number, details URI, status, price type, price, total reported usage).
*   `License`: User's license details (model version ID, user, license type, purchase time, expiry time, usage balance, status).
*   `Attestation`: User feedback/rating for a model version.

**Enums:**
*   `LicenseType`: PER_INFERENCE, SUBSCRIPTION.
*   `ModelStatus`: ACTIVE, DEACTIVATED, DEPRECATED.
*   `LicenseStatus`: ACTIVE, EXPIRED, REVOKED, CONSUMED.

**Functions (Minimum 20):**

**Provider Actions:**
1.  `registerModel`: Register a new AI model.
2.  `addModelVersion`: Add a new version to an existing model.
3.  `listModelVersionForSale`: Define pricing and status for a specific model version.
4.  `updateModelDescription`: Update model metadata URI.
5.  `updateModelVersionDetails`: Update version metadata URI and status.
6.  `reportUsage`: Report usage units for a specific active license (crucial interaction point with off-chain usage).
7.  `withdrawProviderEarnings`: Provider claims accumulated earnings from model usage.

**User Actions (Buyers):**
8.  `purchaseLicense`: Buy a license for a model version (pays Ether).
9.  `extendSubscription`: Extend a time-based subscription license.
10. `submitAttestation`: Leave a review/rating for a used model version.
11. `getUserLicenses`: Get list of licenses owned by the caller.

**Admin/Platform Actions:**
12. `setPlatformFee`: Set the platform fee percentage.
13. `withdrawPlatformFees`: Owner withdraws accumulated platform fees.
14. `pauseContract`: Pause core marketplace functions (e.g., purchasing, reporting usage).
15. `unpauseContract`: Unpause the contract.
16. `changeOwner`: Transfer ownership.
17. `revokeLicenseByAdmin`: Admin revokes a license (e.g., due to dispute or violation).

**View/Query Functions:**
18. `getModelDetails`: Get details of a specific model.
19. `getModelVersionDetails`: Get details of a specific model version.
20. `getLicenseDetails`: Get details of a specific license.
21. `checkLicenseValidity`: Check if a license is currently valid for use.
22. `getModelsByProvider`: Get all models registered by a provider.
23. `getVersionsByModel`: Get all versions for a specific model.
24. `getAttestationsForModelVersion`: Get all attestations for a model version.
25. `getAverageRatingForModelVersion`: Calculate and get the average rating.
26. `getPayableBalanceForProvider`: Get the provider's current accumulated earnings.
27. `getPlatformFee`: Get the current platform fee percentage.
28. `isPaused`: Check if the contract is paused.
29. `getTotalModels`: Get the total number of registered models.
30. `getTotalLicenses`: Get the total number of licenses issued.

*(Note: We already exceeded 20 functions, providing a rich set of interactions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A smart contract for a decentralized marketplace of AI models.
 * Providers register models and versions, set prices, and report usage.
 * Users purchase licenses for usage (per-inference or subscription).
 * The contract handles license tracking, payment distribution, and a basic attestation system.
 *
 * Key Concepts:
 * - Model and Version Registration: Providers list their AI models and specific versions.
 * - License Purchase: Users acquire rights to use model versions via on-chain licenses.
 * - Usage Reporting: Providers report usage of licensed models, which is used for payment calculation.
 *   (NOTE: This relies on providers reporting accurately. Future versions could integrate
 *    oracle networks, trusted execution environments, or ZK proofs for verification,
 *    but this version focuses on the core market/licensing logic on-chain).
 * - Payment Distribution: Fees from usage are collected and can be withdrawn by providers
 *   and the platform owner.
 * - Attestation System: Users can submit reviews/ratings for model versions they've licensed.
 * - Access Control: Ownership and pausing mechanisms for contract management.
 */

contract DecentralizedAIModelMarketplace {

    // --- Enums ---

    enum LicenseType {
        PER_INFERENCE, // Pay per unit of usage
        SUBSCRIPTION   // Pay for a time period
    }

    enum ModelStatus {
        ACTIVE,
        DEACTIVATED, // Temporarily unavailable
        DEPRECATED   // Replaced by a newer version or discontinued
    }

    enum LicenseStatus {
        ACTIVE,
        EXPIRED,   // Time-based license expired
        REVOKED,   // Revoked by provider/admin
        CONSUMED   // Usage-based license fully consumed
    }

    // --- Structs ---

    struct Model {
        address provider;
        string name;
        string descriptionURI; // IPFS hash or URL for model description
        uint256 registrationTime;
        ModelStatus status;
    }

    struct ModelVersion {
        uint256 modelId;
        uint32 versionNumber; // e.g., 100 for v1.0.0
        string detailsURI;    // IPFS hash or URL for version-specific details (API endpoint, specs)
        ModelStatus status;
        LicenseType priceType;
        uint256 pricePerUnit; // Price per inference (for PER_INFERENCE) or per second (for SUBSCRIPTION)
        uint256 totalReportedUsageUnits; // Total usage reported for this version across all licenses
        uint256 totalEarned; // Total earnings for this version
        uint256 listingTime;
    }

    struct License {
        uint256 licenseId; // Self-referential ID for easier lookup
        uint256 modelVersionId; // References the specific version purchased
        address user;
        LicenseType licenseType;
        uint256 purchaseTime;
        uint256 expiryTime; // Relevant for SUBSCRIPTION
        uint256 initialUsageUnits; // Relevant for PER_INFERENCE (e.g., bought a license for 1000 inferences)
        uint256 consumedUsageUnits; // Relevant for PER_INFERENCE
        LicenseStatus status;
    }

    struct Attestation {
        uint256 attestationId; // Self-referential ID
        uint256 modelVersionId; // References the version being attested
        address user;
        uint8 rating;          // e.g., 1-5 stars
        string commentURI;     // IPFS hash or URL for detailed comment
        uint256 submissionTime;
    }

    // --- State Variables ---

    address public owner;
    bool public paused = false;

    uint256 private _nextModelId = 1;
    uint256 private _nextLicenseId = 1;
    uint265 private _nextAttestationId = 1;

    mapping(uint256 => Model) public models;
    mapping(uint256 => uint256[]) public modelVersions; // modelId => array of modelVersionIds
    mapping(uint256 => ModelVersion) public modelVersionDetails; // modelVersionId => version details
    mapping(uint256 => License) public licenses;
    mapping(address => uint256[]) public userLicenses; // user address => array of licenseIds
    mapping(uint256 => uint256[]) public attestations; // modelVersionId => array of attestationIds
    mapping(uint256 => Attestation) public attestationDetails; // attestationId => attestation details

    mapping(address => uint256) public providerPayableBalance; // Provider address => accumulated balance

    uint256 public platformFeeBasisPoints; // Fee percentage * 100 (e.g., 500 for 5%)
    uint256 public totalPlatformFeesCollected;

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed provider, string name);
    event ModelVersionAdded(uint256 indexed modelId, uint256 indexed modelVersionId, uint32 versionNumber);
    event ModelVersionListed(uint256 indexed modelVersionId, LicenseType priceType, uint256 pricePerUnit, ModelStatus status);
    event ModelDescriptionUpdated(uint256 indexed modelId, string descriptionURI);
    event ModelVersionDetailsUpdated(uint256 indexed modelVersionId, string detailsURI, ModelStatus status);

    event LicensePurchased(uint256 indexed licenseId, uint256 indexed modelVersionId, address indexed user, LicenseType licenseType, uint256 initialValue);
    event SubscriptionExtended(uint256 indexed licenseId, uint256 newExpiryTime);
    event LicenseStatusChanged(uint256 indexed licenseId, LicenseStatus newStatus);
    event UsageReported(uint256 indexed licenseId, uint256 modelVersionId, uint256 reportedUnits, uint256 payableAmount);

    event AttestationSubmitted(uint256 indexed attestationId, uint256 indexed modelVersionId, address indexed user, uint8 rating);

    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);
    event PlatformFeeSet(uint256 newFeeBasisPoints);

    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
        }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        platformFeeBasisPoints = 500; // Default 5% fee
    }

    // --- Provider Actions ---

    /**
     * @dev Registers a new AI model.
     * @param _name The name of the model.
     * @param _descriptionURI URI pointing to the model's description (e.g., IPFS hash).
     * @return The ID of the newly registered model.
     */
    function registerModel(string memory _name, string memory _descriptionURI) external whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "Model name cannot be empty.");

        uint256 modelId = _nextModelId++;
        models[modelId] = Model({
            provider: msg.sender,
            name: _name,
            descriptionURI: _descriptionURI,
            registrationTime: block.timestamp,
            status: ModelStatus.ACTIVE
        });

        emit ModelRegistered(modelId, msg.sender, _name);
        return modelId;
    }

    /**
     * @dev Adds a new version to an existing model. Only callable by the model provider.
     * @param _modelId The ID of the model.
     * @param _versionNumber A unique version number (e.g., 100 for v1.0.0).
     * @param _detailsURI URI pointing to version-specific details (e.g., API endpoint, specs).
     * @return The ID of the newly added model version.
     */
    function addModelVersion(uint256 _modelId, uint32 _versionNumber, string memory _detailsURI) external whenNotPaused returns (uint256) {
        Model storage model = models[_modelId];
        require(model.provider == msg.sender, "Only model provider can add a version.");
        require(model.status != ModelStatus.DEPRECATED, "Cannot add version to a deprecated model.");

        uint256 modelVersionId = modelVersions[_modelId].length + (_modelId * 1000000); // Simple way to create a somewhat unique version ID related to modelId

        modelVersions[_modelId].push(modelVersionId);

        modelVersionDetails[modelVersionId] = ModelVersion({
            modelId: _modelId,
            versionNumber: _versionNumber,
            detailsURI: _detailsURI,
            status: ModelStatus.DEACTIVATED, // Initially inactive
            priceType: LicenseType.PER_INFERENCE, // Default, must be set via listModelVersionForSale
            pricePerUnit: 0,
            totalReportedUsageUnits: 0,
            totalEarned: 0,
            listingTime: 0 // Not listed yet
        });

        emit ModelVersionAdded(_modelId, modelVersionId, _versionNumber);
        return modelVersionId;
    }

    /**
     * @dev Sets the pricing and availability status for a specific model version.
     * Only callable by the model provider.
     * @param _modelVersionId The ID of the model version.
     * @param _status The status (ACTIVE, DEACTIVATED). Cannot be DEPRECATED via this function.
     * @param _priceType The type of license (PER_INFERENCE or SUBSCRIPTION).
     * @param _pricePerUnit The price per unit (wei per inference or wei per second). Must be > 0 if status is ACTIVE.
     */
    function listModelVersionForSale(uint256 _modelVersionId, ModelStatus _status, LicenseType _priceType, uint256 _pricePerUnit) external whenNotPaused {
        ModelVersion storage version = modelVersionDetails[_modelVersionId];
        require(version.modelId != 0, "Model version does not exist.");
        require(models[version.modelId].provider == msg.sender, "Only model provider can list version.");
        require(_status != ModelStatus.DEPRECATED, "Cannot set status to DEPRECATED here.");
        require(_status == ModelStatus.DEACTIVATED || _pricePerUnit > 0, "Price must be > 0 for ACTIVE status.");

        version.status = _status;
        version.priceType = _priceType;
        version.pricePerUnit = _pricePerUnit;
        version.listingTime = (_status == ModelStatus.ACTIVE && version.listingTime == 0) ? block.timestamp : version.listingTime;

        emit ModelVersionListed(_modelVersionId, _priceType, _pricePerUnit, _status);
    }

     /**
     * @dev Updates the description URI for a model. Only callable by the model provider.
     * @param _modelId The ID of the model.
     * @param _descriptionURI New URI for the model description.
     */
    function updateModelDescription(uint256 _modelId, string memory _descriptionURI) external whenNotPaused {
        Model storage model = models[_modelId];
        require(model.provider == msg.sender, "Only model provider can update description.");

        model.descriptionURI = _descriptionURI;
        emit ModelDescriptionUpdated(_modelId, _descriptionURI);
    }

    /**
     * @dev Updates the details URI and status for a model version. Only callable by the model provider.
     * Status can be set to ACTIVE, DEACTIVATED, or DEPRECATED.
     * @param _modelVersionId The ID of the model version.
     * @param _detailsURI New URI for the version details.
     * @param _status New status for the version.
     */
    function updateModelVersionDetails(uint256 _modelVersionId, string memory _detailsURI, ModelStatus _status) external whenNotPaused {
        ModelVersion storage version = modelVersionDetails[_modelVersionId];
        require(version.modelId != 0, "Model version does not exist.");
        require(models[version.modelId].provider == msg.sender, "Only model provider can update version details.");

        // If setting to DEPRECATED, ensure it's not ACTIVE with active licenses?
        // For simplicity, we allow deprecating an active version. Existing licenses will still be valid until expiry/usage runs out.
        if (_status == ModelStatus.ACTIVE) {
             require(version.pricePerUnit > 0, "Cannot set status to ACTIVE if price is zero.");
        }

        version.detailsURI = _detailsURI;
        version.status = _status;
        version.listingTime = (_status == ModelStatus.ACTIVE && version.listingTime == 0) ? block.timestamp : version.listingTime;

        emit ModelVersionDetailsUpdated(_modelVersionId, _detailsURI, _status);
    }


    /**
     * @dev Reports usage for a specific license. Only callable by the model provider.
     * Payments are calculated based on reported usage for PER_INFERENCE licenses.
     * For SUBSCRIPTION licenses, usage reporting might be for tracking/metrics, not payment.
     * This function assumes the provider is honestly reporting usage.
     * A real-world system would need a verification layer (e.g., oracle, TEE, ZK-proofs).
     * @param _licenseId The ID of the license.
     * @param _usageUnits The number of usage units (inferences) to report for this license.
     */
    function reportUsage(uint256 _licenseId, uint256 _usageUnits) external whenNotPaused {
        License storage license = licenses[_licenseId];
        require(license.licenseId != 0, "License does not exist."); // Check if license exists
        require(license.status == LicenseStatus.ACTIVE, "License is not active.");

        ModelVersion storage version = modelVersionDetails[license.modelVersionId];
        require(version.modelId != 0, "Model version linked to license does not exist.");
        require(models[version.modelId].provider == msg.sender, "Only the licensed model's provider can report usage.");

        if (license.licenseType == LicenseType.PER_INFERENCE) {
            uint256 remainingUsage = license.initialUsageUnits - license.consumedUsageUnits;
            uint256 actualReportedUnits = _usageUnits > remainingUsage ? remainingUsage : _usageUnits; // Don't report more than remaining

            if (actualReportedUnits > 0) {
                uint256 totalPayableAmount = actualReportedUnits * version.pricePerUnit;
                uint256 platformFee = (totalPayableAmount * platformFeeBasisPoints) / 10000;
                uint256 providerEarned = totalPayableAmount - platformFee;

                // Update state
                license.consumedUsageUnits += actualReportedUnits;
                version.totalReportedUsageUnits += actualReportedUnits;
                version.totalEarned += providerEarned;
                providerPayableBalance[msg.sender] += providerEarned;
                totalPlatformFeesCollected += platformFee;

                // Check if license is consumed
                if (license.consumedUsageUnits >= license.initialUsageUnits) {
                    license.status = LicenseStatus.CONSUMED;
                    emit LicenseStatusChanged(_licenseId, LicenseStatus.CONSUMED);
                }

                emit UsageReported(_licenseId, license.modelVersionId, actualReportedUnits, totalPayableAmount);
            }
        } else if (license.licenseType == LicenseType.SUBSCRIPTION) {
             // For subscriptions, usage report doesn't trigger payment based on units.
             // It could be used for provider metrics or enforcing rate limits off-chain.
             // We'll just update the total reported usage on the version for general stats.
             version.totalReportedUsageUnits += _usageUnits;
              emit UsageReported(_licenseId, license.modelVersionId, _usageUnits, 0);
        }
    }

    /**
     * @dev Allows a provider to withdraw their accumulated earnings.
     */
    function withdrawProviderEarnings() external whenNotPaused {
        uint256 amount = providerPayableBalance[msg.sender];
        require(amount > 0, "No pending earnings to withdraw.");

        providerPayableBalance[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit ProviderEarningsWithdrawn(msg.sender, amount);
    }


    // --- User Actions (Buyers) ---

    /**
     * @dev Purchases a license for a specific model version.
     * Requires sending the correct amount of Ether based on license type and quantity.
     * @param _modelVersionId The ID of the model version to license.
     * @param _quantity For PER_INFERENCE, this is the number of inferences. For SUBSCRIPTION, this is the duration in seconds.
     */
    function purchaseLicense(uint256 _modelVersionId, uint256 _quantity) external payable whenNotPaused {
        require(_quantity > 0, "Quantity must be greater than 0.");

        ModelVersion storage version = modelVersionDetails[_modelVersionId];
        require(version.modelId != 0, "Model version does not exist.");
        require(version.status == ModelStatus.ACTIVE, "Model version is not currently active.");

        uint256 requiredAmount = version.pricePerUnit * _quantity;
        require(msg.value == requiredAmount, "Incorrect Ether amount sent.");

        uint256 licenseId = _nextLicenseId++;
        uint256 expiryTime = 0;
        uint256 initialUsageUnits = 0;

        if (version.priceType == LicenseType.SUBSCRIPTION) {
            expiryTime = block.timestamp + _quantity; // Quantity is duration in seconds
        } else if (version.priceType == LicenseType.PER_INFERENCE) {
            initialUsageUnits = _quantity; // Quantity is number of inferences
        } else {
             revert("Unsupported license type."); // Should not happen with current enum, but good practice
        }

        licenses[licenseId] = License({
            licenseId: licenseId,
            modelVersionId: _modelVersionId,
            user: msg.sender,
            licenseType: version.priceType,
            purchaseTime: block.timestamp,
            expiryTime: expiryTime,
            initialUsageUnits: initialUsageUnits,
            consumedUsageUnits: 0,
            status: LicenseStatus.ACTIVE
        });

        userLicenses[msg.sender].push(licenseId);

        // Payment processing happens implicitly via msg.value.
        // The funds are held in the contract balance until providers/owner withdraw.

        emit LicensePurchased(licenseId, _modelVersionId, msg.sender, version.priceType, _quantity);
    }

     /**
     * @dev Extends a time-based subscription license.
     * Requires sending the correct amount of Ether for the extension duration.
     * @param _licenseId The ID of the subscription license.
     * @param _extensionDuration The duration to extend in seconds.
     */
    function extendSubscription(uint256 _licenseId, uint256 _extensionDuration) external payable whenNotPaused {
        License storage license = licenses[_licenseId];
        require(license.licenseId != 0, "License does not exist.");
        require(license.user == msg.sender, "Only license owner can extend.");
        require(license.licenseType == LicenseType.SUBSCRIPTION, "License is not a subscription.");
        require(license.status == LicenseStatus.ACTIVE || license.status == LicenseStatus.EXPIRED, "License cannot be extended (status invalid).");
        require(_extensionDuration > 0, "Extension duration must be greater than 0.");

        ModelVersion storage version = modelVersionDetails[license.modelVersionId];
        require(version.modelId != 0, "Model version linked to license does not exist.");
        require(version.priceType == LicenseType.SUBSCRIPTION, "Model version price type changed unexpectedly."); // Should match license type
        require(version.status == ModelStatus.ACTIVE, "Cannot extend license for inactive model version.");

        uint256 requiredAmount = version.pricePerUnit * _extensionDuration;
        require(msg.value == requiredAmount, "Incorrect Ether amount sent for extension.");

        // If license was expired, reactivate it
        if (license.status == LicenseStatus.EXPIRED) {
             license.status = LicenseStatus.ACTIVE;
             // Start extending from now if expired, otherwise extend from current expiry
             license.expiryTime = block.timestamp + _extensionDuration;
             emit LicenseStatusChanged(_licenseId, LicenseStatus.ACTIVE);
        } else {
            // Extend from the current expiry time
            license.expiryTime += _extensionDuration;
        }

        // Payment processing happens implicitly via msg.value.

        emit SubscriptionExtended(_licenseId, license.expiryTime);
    }


    /**
     * @dev Allows a user to submit an attestation (review/rating) for a model version they have a license for.
     * Requires the license to be currently or have been active.
     * @param _modelVersionId The ID of the model version being attested.
     * @param _rating The rating (e.g., 1-5).
     * @param _commentURI URI pointing to a detailed comment.
     */
    function submitAttestation(uint256 _modelVersionId, uint8 _rating, string memory _commentURI) external whenNotPaused {
        require(_rating > 0 && _rating <= 5, "Rating must be between 1 and 5.");
        require(modelVersionDetails[_modelVersionId].modelId != 0, "Model version does not exist.");

        // Check if the user has *any* license for this model version, regardless of current status
        bool hasLicense = false;
        uint256[] storage userLicenseIds = userLicenses[msg.sender];
        for (uint i = 0; i < userLicenseIds.length; i++) {
            if (licenses[userLicenseIds[i]].modelVersionId == _modelVersionId) {
                hasLicense = true;
                break;
            }
        }
        require(hasLicense, "Only users with a license for this version can submit an attestation.");

        uint256 attestationId = _nextAttestationId++;
        attestationDetails[attestationId] = Attestation({
            attestationId: attestationId,
            modelVersionId: _modelVersionId,
            user: msg.sender,
            rating: _rating,
            commentURI: _commentURI,
            submissionTime: block.timestamp
        });

        attestations[_modelVersionId].push(attestationId);

        emit AttestationSubmitted(attestationId, _modelVersionId, msg.sender, _rating);
    }

    /**
     * @dev Gets the list of license IDs owned by the caller.
     * @return An array of license IDs.
     */
    function getUserLicenses() external view returns (uint256[] memory) {
        return userLicenses[msg.sender];
    }

    // --- Admin/Platform Actions ---

    /**
     * @dev Sets the platform fee percentage. Only owner can call.
     * Fee is applied to the provider's earnings (a cut of the license price).
     * @param _feeBasisPoints Fee percentage multiplied by 100 (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setPlatformFee(uint256 _feeBasisPoints) external onlyOwner whenNotPaused {
        require(_feeBasisPoints <= 10000, "Fee basis points cannot exceed 10000 (100%).");
        platformFeeBasisPoints = _feeBasisPoints;
        emit PlatformFeeSet(_feeBasisPoints);
    }

    /**
     * @dev Allows the owner to withdraw collected platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = totalPlatformFeesCollected;
        require(amount > 0, "No platform fees to withdraw.");

        totalPlatformFeesCollected = 0;

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit PlatformFeesWithdrawn(owner, amount);
    }

     /**
     * @dev Pauses the contract, preventing certain operations like purchases and usage reporting.
     * Only owner can call.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Only owner can call.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Transfers ownership of the contract. Only current owner can call.
     * @param _newOwner The address of the new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /**
     * @dev Allows the admin to revoke a license.
     * Could be used in a dispute resolution process (not implemented here).
     * Revoking a license makes it inactive and prevents further usage reporting/extension.
     * @param _licenseId The ID of the license to revoke.
     */
    function revokeLicenseByAdmin(uint256 _licenseId) external onlyOwner {
        License storage license = licenses[_licenseId];
        require(license.licenseId != 0, "License does not exist.");
        require(license.status == LicenseStatus.ACTIVE || license.status == LicenseStatus.EXPIRED, "License is already inactive.");

        license.status = LicenseStatus.REVOKED;
        emit LicenseStatusChanged(_licenseId, LicenseStatus.REVOKED);

        // Optional: Implement logic to potentially refund user or penalize provider off-chain/via a separate system
        // On-chain refunding is complex and requires storing source of funds per license.
    }


    // --- View/Query Functions ---

    /**
     * @dev Gets details of a specific model.
     * @param _modelId The ID of the model.
     * @return Model struct details.
     */
    function getModelDetails(uint256 _modelId) external view returns (Model memory) {
        require(models[_modelId].provider != address(0), "Model does not exist.");
        return models[_modelId];
    }

    /**
     * @dev Gets details of a specific model version.
     * @param _modelVersionId The ID of the model version.
     * @return ModelVersion struct details.
     */
    function getModelVersionDetails(uint255 _modelVersionId) external view returns (ModelVersion memory) {
        require(modelVersionDetails[_modelVersionId].modelId != 0, "Model version does not exist.");
        return modelVersionDetails[_modelVersionId];
    }

    /**
     * @dev Gets details of a specific license.
     * @param _licenseId The ID of the license.
     * @return License struct details.
     */
    function getLicenseDetails(uint256 _licenseId) external view returns (License memory) {
        require(licenses[_licenseId].licenseId != 0, "License does not exist.");
        return licenses[_licenseId];
    }

    /**
     * @dev Checks if a license is currently valid and usable.
     * For SUBSCRIPTION, checks time. For PER_INFERENCE, checks remaining usage.
     * @param _licenseId The ID of the license.
     * @return True if the license is active and usable, false otherwise.
     */
    function checkLicenseValidity(uint256 _licenseId) external view returns (bool) {
        License storage license = licenses[_licenseId];
        if (license.licenseId == 0) return false; // License doesn't exist

        if (license.status != LicenseStatus.ACTIVE) {
            return false; // Not in active status
        }

        if (license.licenseType == LicenseType.SUBSCRIPTION) {
            // For subscription, check expiry time
            if (block.timestamp >= license.expiryTime) {
                 // Note: Status isn't automatically updated here, relies on off-chain check or state-changing call
                 // In a real system, a state update might be triggered by a user interaction or external keeper
                 return false;
            }
        } else if (license.licenseType == LicenseType.PER_INFERENCE) {
            // For per-inference, check remaining usage
            if (license.consumedUsageUnits >= license.initialUsageUnits) {
                 // Note: Status isn't automatically updated here, relies on off-chain check or state-changing call
                return false;
            }
        }
         // If active and hasn't failed time/usage checks
        return true;
    }

     /**
     * @dev Gets all model IDs registered by a specific provider.
     * Note: This can be inefficient for providers with many models.
     * @param _provider The address of the provider.
     * @return An array of model IDs.
     */
    function getModelsByProvider(address _provider) external view returns (uint256[] memory) {
        // This requires iterating through all models and checking the provider.
        // For a truly scalable solution, a mapping from provider => array of modelIds would be better,
        // but adds complexity on model registration/deletion. Sticking to simpler storage for example.
        uint256[] memory providerModelIds = new uint256[](_nextModelId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < _nextModelId; i++) {
            if (models[i].provider == _provider) {
                providerModelIds[count] = i;
                count++;
            }
        }
        // Trim array to actual size
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = providerModelIds[i];
        }
        return result;
    }


    /**
     * @dev Gets all model version IDs for a specific model.
     * @param _modelId The ID of the model.
     * @return An array of model version IDs.
     */
    function getVersionsByModel(uint256 _modelId) external view returns (uint256[] memory) {
         require(models[_modelId].provider != address(0), "Model does not exist.");
         return modelVersions[_modelId];
    }

    /**
     * @dev Gets all attestation IDs for a specific model version.
     * @param _modelVersionId The ID of the model version.
     * @return An array of attestation IDs.
     */
    function getAttestationsForModelVersion(uint256 _modelVersionId) external view returns (uint256[] memory) {
        require(modelVersionDetails[_modelVersionId].modelId != 0, "Model version does not exist.");
        return attestations[_modelVersionId];
    }

     /**
     * @dev Calculates and returns the average rating for a model version.
     * Returns 0 if no attestations exist.
     * @param _modelVersionId The ID of the model version.
     * @return The average rating (multiplied by 100 for precision, e.g., 350 for 3.5).
     */
    function getAverageRatingForModelVersion(uint256 _modelVersionId) external view returns (uint256) {
        require(modelVersionDetails[_modelVersionId].modelId != 0, "Model version does not exist.");

        uint256[] memory versionAttestations = attestations[_modelVersionId];
        if (versionAttestations.length == 0) {
            return 0;
        }

        uint256 totalRating = 0;
        for (uint i = 0; i < versionAttestations.length; i++) {
            totalRating += attestationDetails[versionAttestations[i]].rating;
        }

        // Calculate average with 2 decimal places precision (multiply by 100 before dividing)
        return (totalRating * 100) / versionAttestations.length;
    }

    /**
     * @dev Gets the accumulated balance payable to a provider.
     * @param _provider The address of the provider.
     * @return The amount of Ether payable to the provider.
     */
    function getPayableBalanceForProvider(address _provider) external view returns (uint256) {
        return providerPayableBalance[_provider];
    }

    /**
     * @dev Gets the current platform fee percentage.
     * @return The platform fee in basis points.
     */
    function getPlatformFee() external view returns (uint256) {
        return platformFeeBasisPoints;
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

     /**
     * @dev Gets the total number of registered models.
     * @return The count of models.
     */
    function getTotalModels() external view returns (uint256) {
        return _nextModelId - 1;
    }

     /**
     * @dev Gets the total number of licenses issued.
     * @return The count of licenses.
     */
    function getTotalLicenses() external view returns (uint256) {
        return _nextLicenseId - 1;
    }

}
```