Okay, here is a Solidity smart contract for a Decentralized AI Model Marketplace. This contract focuses on licensing AI models for usage, incorporating features like usage tracking via an oracle, rating systems, staking for model quality, and a basic dispute mechanism.

It aims to be creative by moving beyond simple ownership transfer (like NFTs) to managing complex usage licenses, leveraging an oracle for off-chain interaction (usage reporting), and integrating reputation/quality mechanisms (rating, staking). It avoids standard patterns like ERC-20/721 implementation itself, basic crowdfunding, or simple auctions.

---

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and necessary libraries (like `Ownable` for admin roles).
2.  **Error Definitions:** Custom errors for clearer error handling.
3.  **Enums:** Define possible states/types (LicenseType, DisputeStatus).
4.  **Structs:** Define data structures for Models, License Options, Licenses, and Disputes.
5.  **State Variables:** Store contract owner/admin, marketplace parameters (fees, oracle address), counters, and mappings for all entities.
6.  **Events:** Define events to signal important actions.
7.  **Modifiers:** Define access control and state-checking modifiers.
8.  **Core Logic Functions:**
    *   Model Management (Registration, Updates, Options)
    *   Licensing (Purchase)
    *   Usage Tracking (via Oracle)
    *   Rating System
    *   Staking System
    *   Dispute Mechanism
    *   Financials (Withdrawals, Fee Collection)
    *   Admin Functions
9.  **Read Functions:** Get details of models, licenses, etc.

**Function Summary:**

*   `constructor()`: Deploys the contract, setting admin and initial parameters.
*   `setOracleAddress(address _oracleAddress)`: Admin sets the trusted oracle address.
*   `setMarketplaceFeeBasisPoints(uint16 _basisPoints)`: Admin sets the marketplace fee (in basis points).
*   `setFeeRecipient(address _recipient)`: Admin sets the address receiving marketplace fees.
*   `collectMarketplaceFees()`: Admin withdraws accumulated marketplace fees.
*   `registerModel(string memory _metadataURI)`: Model owner registers a new AI model.
*   `updateModelMetadata(uint256 _modelId, string memory _newMetadataURI)`: Model owner updates model details URI.
*   `addLicenseOption(uint256 _modelId, LicenseType _optionType, uint256 _price, uint256 _duration, uint256 _maxUses)`: Model owner adds a new licensing option for their model.
*   `deactivateLicenseOption(uint256 _modelId, uint256 _optionIndex)`: Model owner deactivates a license option.
*   `updateLicenseOptionPrice(uint256 _modelId, uint256 _optionIndex, uint256 _newPrice)`: Model owner updates the price of a license option.
*   `purchaseLicense(uint256 _modelId, uint256 _optionIndex) payable`: User purchases a license for a specific model and option.
*   `processOracleUsageReport(uint256 _licenseId, uint256 _usesReported)`: Oracle reports usage for a usage-based license.
*   `rateModel(uint256 _modelId, uint8 _rating)`: User rates a model they have a license for.
*   `stakeForQuality(uint256 _modelId) payable`: Model owner stakes funds on their model as a quality signal.
*   `withdrawStake(uint256 _modelId)`: Model owner withdraws their stake (subject to potential dispute locks).
*   `withdrawModelOwnerEarnings(uint256 _modelId)`: Model owner withdraws earnings from license sales (after fees).
*   `transferModelOwnership(uint256 _modelId, address _newOwner)`: Current model owner transfers model ownership.
*   `raiseDispute(uint256 _modelId, uint256 _licenseId, string memory _reason)`: User or owner raises a dispute related to a model or license.
*   `resolveDispute(uint256 _disputeId, bool _resolvedInFavorOfRaiser, string memory _resolutionDetails)`: Admin/Arbiter resolves a dispute.
*   `getAvailableModels()`: Read-only: Gets a list of all registered model IDs.
*   `getModelDetails(uint256 _modelId)`: Read-only: Gets details of a specific model.
*   `getLicenseOptions(uint256 _modelId)`: Read-only: Gets all license options for a model.
*   `getUserLicenses(address _user)`: Read-only: Gets all license IDs owned by a user.
*   `getLicenseDetails(uint256 _licenseId)`: Read-only: Gets details of a specific license.
*   `getDisputeDetails(uint256 _disputeId)`: Read-only: Gets details of a specific dispute.
*   `isLicenseActive(uint256 _licenseId)`: Read-only: Checks if a license is currently active based on type (time/usage).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Using OpenZeppelin's Ownable and ReentrancyGuard for standard patterns,
// but the core contract logic and concept are custom.

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A marketplace for licensing AI models with usage tracking via oracle,
 *      rating, staking, and dispute resolution.
 */
contract DecentralizedAIModelMarketplace is Ownable, ReentrancyGuard {
    using Address for address payable;

    // --- Errors ---
    error DACMM_InvalidRating(uint8 rating);
    error DACMM_ModelNotFound(uint256 modelId);
    error DACMM_NotModelOwner(uint256 modelId);
    error DACMM_LicenseNotFound(uint256 licenseId);
    error DACMM_NotLicenseOwner(uint256 licenseId);
    error DACMM_LicenseOptionNotFound(uint256 modelId, uint256 optionIndex);
    error DACMM_LicenseOptionInactive();
    error DACMM_InsufficientPayment(uint256 required, uint256 sent);
    error DACMM_LicenseAlreadyRated();
    error DACMM_DisputeNotFound(uint256 disputeId);
    error DACMM_DisputeNotOpen();
    error DACMM_OracleNotSet();
    error DACMM_NotOracle();
    error DACMM_LicenseNotUsageBased();
    error DACMM_LicenseNotTimeBased();
    error DACMM_LicenseExpiredOrUsedUp();
    error DACMM_NoEarningsToWithdraw();
    error DACMM_StakeWithdrawalLocked();
    error DACMM_StakeAmountZero();

    // --- Enums ---
    enum LicenseType { Perpetual, TimeLimited, UsageBased }
    enum DisputeStatus { Open, Resolved, Rejected }

    // --- Structs ---
    struct LicenseOption {
        LicenseType optionType;
        uint256 price;          // Price in native currency (wei)
        uint256 duration;       // For TimeLimited, in seconds
        uint256 maxUses;        // For UsageBased
        bool isActive;
    }

    struct Model {
        address owner;
        string metadataURI;     // Link to off-chain model details, access info, etc.
        LicenseOption[] licenseOptions;
        uint256 totalRatingPoints; // Sum of all ratings (1-5)
        uint255 ratingCount;       // Number of ratings
        uint256 stakeAmount;       // Amount staked by owner
        mapping(address => bool) ratedBy; // Track who rated
    }

    struct License {
        uint256 modelId;
        address owner;
        uint256 optionIndex;    // Index in the model's licenseOptions array
        uint64 purchaseTime;    // Timestamp of purchase
        uint64 expiryTime;      // For TimeLimited
        uint256 usesRemaining;  // For UsageBased
        bool isActive;          // Can be deactivated by owner or oracle (e.g. dispute)
    }

    struct Dispute {
        uint256 modelId;
        uint256 licenseId;      // Optional: If dispute relates to a specific license
        address raiser;         // Address who raised the dispute
        string reason;
        DisputeStatus status;
        string resolutionDetails; // Details of resolution
    }

    // --- State Variables ---
    address public admin; // Separate admin role from Ownable deployer if needed, or just use owner()
    address public oracleAddress;
    uint16 public marketplaceFeeBasisPoints; // e.g., 100 for 1% (100/10000)
    address payable public feeRecipient;

    uint256 private modelIdCounter;
    mapping(uint255 => Model) public models;
    uint255[] private _allModelIds; // To iterate through models

    uint256 private licenseIdCounter;
    mapping(uint255 => License) public licenses;
    mapping(address => uint255[]) private userLicenses; // Track licenses per user

    uint256 private disputeIdCounter;
    mapping(uint255 => Dispute) public disputes;
    mapping(uint255 => bool) private modelDisputeActive; // True if a dispute is open for a model
    mapping(uint255 => bool) private licenseDisputeActive; // True if a dispute is open for a license

    mapping(uint255 => uint256) public modelOwnerEarnings; // Unwithdrawn earnings per model owner

    // --- Events ---
    event OracleAddressUpdated(address indexed newAddress);
    event MarketplaceFeeUpdated(uint16 newFeeBasisPoints);
    event FeeRecipientUpdated(address indexed newRecipient);
    event MarketplaceFeesCollected(uint256 amount);

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string metadataURI);
    event ModelMetadataUpdated(uint256 indexed modelId, string newMetadataURI);
    event LicenseOptionAdded(uint256 indexed modelId, uint256 optionIndex, LicenseType optionType, uint256 price);
    event LicenseOptionDeactivated(uint256 indexed modelId, uint256 optionIndex);
    event LicenseOptionPriceUpdated(uint256 indexed modelId, uint256 optionIndex, uint256 newPrice);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner);

    event LicensePurchased(uint256 indexed licenseId, uint256 indexed modelId, address indexed buyer, uint256 purchasePrice);
    event LicenseDeactivated(uint256 indexed licenseId, string reason);

    event OracleUsageReported(uint256 indexed licenseId, uint256 usesReported, uint256 usesRemaining);
    event ModelRated(uint256 indexed modelId, address indexed rater, uint8 rating);
    event StakeDeposited(uint256 indexed modelId, address indexed owner, uint256 amount);
    event StakeWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);
    event ModelOwnerEarningsWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed modelId, uint256 indexed licenseId, address indexed raiser);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status, string resolutionDetails);

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
        if (models[_modelId].owner != msg.sender) revert DACMM_NotModelOwner(_modelId);
        _;
    }

    modifier onlyLicenseOwner(uint256 _licenseId) {
        if (_licenseId >= licenseIdCounter) revert DACMM_LicenseNotFound(_licenseId);
        if (licenses[_licenseId].owner != msg.sender) revert DACMM_NotLicenseOwner(_licenseId);
        _;
    }

    modifier onlyOracle() {
        if (oracleAddress == address(0)) revert DACMM_OracleNotSet();
        if (msg.sender != oracleAddress) revert DACMM_NotOracle();
        _;
    }

    modifier whenModelActive(uint256 _modelId) {
         if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
         if (modelDisputeActive[_modelId]) revert DACMM_StakeWithdrawalLocked(); // Generic lock for simplicity
         _;
    }

     modifier whenLicenseActive(uint256 _licenseId) {
        if (_licenseId >= licenseIdCounter) revert DACMM_LicenseNotFound(_licenseId);
        License storage license = licenses[_licenseId];
        if (!license.isActive) revert DACMM_LicenseDeactivated(_licenseId, "License is inactive");
        if (licenseDisputeActive[_licenseId]) revert DACMM_StakeWithdrawalLocked(); // Generic lock
        _;
    }


    // --- Constructor ---
    constructor(address _admin, address _initialOracle, uint16 _initialFeeBasisPoints, address payable _initialFeeRecipient) Ownable(msg.sender) {
        // Transfer ownership from deployer to a dedicated admin address if needed,
        // or just use msg.sender as admin and use Ownable's owner(). Let's use Ownable's owner() as admin.
        admin = owner();
        setOracleAddress(_initialOracle);
        setMarketplaceFeeBasisPoints(_initialFeeBasisPoints);
        setFeeRecipient(_initialFeeRecipient);
        modelIdCounter = 0;
        licenseIdCounter = 0;
        disputeIdCounter = 0;
    }

    // --- Admin Functions ---
    /**
     * @dev Sets the trusted oracle address. Only admin can call.
     * @param _oracleAddress The address of the oracle contract or service.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress);
    }

    /**
     * @dev Sets the marketplace fee percentage. Only admin can call.
     * @param _basisPoints Fee in basis points (1/100th of a percent), max 10000 (100%).
     */
    function setMarketplaceFeeBasisPoints(uint16 _basisPoints) public onlyOwner {
        require(_basisPoints <= 10000, "DACMM: Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = _basisPoints;
        emit MarketplaceFeeUpdated(_basisPoints);
    }

    /**
     * @dev Sets the recipient address for marketplace fees. Only admin can call.
     * @param _recipient The address to send fees to.
     */
    function setFeeRecipient(address payable _recipient) public onlyOwner {
        feeRecipient = _recipient;
        emit FeeRecipientUpdated(_recipient);
    }

    /**
     * @dev Allows the admin to collect accumulated marketplace fees.
     */
    function collectMarketplaceFees() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance - totalStaked() - totalInDispute(); // Ensure stakes and funds in dispute are not collected
        if (amount > 0) {
            feeRecipient.sendValue(amount);
            emit MarketplaceFeesCollected(amount);
        }
    }

    // --- Model Management (by Owner) ---
    /**
     * @dev Registers a new AI model in the marketplace.
     * @param _metadataURI URI pointing to off-chain metadata about the model.
     * @return The ID of the newly registered model.
     */
    function registerModel(string memory _metadataURI) public returns (uint256) {
        uint256 newModelId = modelIdCounter++;
        models[uint255(newModelId)].owner = msg.sender;
        models[uint255(newModelId)].metadataURI = _metadataURI;
        _allModelIds.push(newModelId); // Add to iterable list
        emit ModelRegistered(newModelId, msg.sender, _metadataURI);
        return newModelId;
    }

    /**
     * @dev Updates the metadata URI for an existing model.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new URI.
     */
    function updateModelMetadata(uint256 _modelId, string memory _newMetadataURI) public onlyModelOwner(_modelId) {
        models[uint255(_modelId)].metadataURI = _newMetadataURI;
        emit ModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @dev Adds a new licensing option for a model.
     * @param _modelId The ID of the model.
     * @param _optionType The type of license (Perpetual, TimeLimited, UsageBased).
     * @param _price Price in native currency (wei).
     * @param _duration Duration in seconds for TimeLimited licenses.
     * @param _maxUses Maximum uses for UsageBased licenses.
     */
    function addLicenseOption(
        uint256 _modelId,
        LicenseType _optionType,
        uint256 _price,
        uint256 _duration,
        uint256 _maxUses
    ) public onlyModelOwner(_modelId) {
        uint256 optionIndex = models[uint255(_modelId)].licenseOptions.length;
        models[uint255(_modelId)].licenseOptions.push(LicenseOption({
            optionType: _optionType,
            price: _price,
            duration: _duration,
            maxUses: _maxUses,
            isActive: true
        }));
        emit LicenseOptionAdded(_modelId, optionIndex, _optionType, _price);
    }

    /**
     * @dev Deactivates an existing license option for a model.
     *      Existing licenses based on this option remain valid according to their terms.
     * @param _modelId The ID of the model.
     * @param _optionIndex The index of the option to deactivate.
     */
    function deactivateLicenseOption(uint256 _modelId, uint256 _optionIndex) public onlyModelOwner(_modelId) {
         if (_optionIndex >= models[uint255(_modelId)].licenseOptions.length) revert DACMM_LicenseOptionNotFound(_modelId, _optionIndex);
         models[uint255(_modelId)].licenseOptions[_optionIndex].isActive = false;
         emit LicenseOptionDeactivated(_modelId, _optionIndex);
    }

     /**
     * @dev Updates the price of an existing license option for a model.
     * @param _modelId The ID of the model.
     * @param _optionIndex The index of the option to update.
     * @param _newPrice The new price in native currency (wei).
     */
    function updateLicenseOptionPrice(uint256 _modelId, uint256 _optionIndex, uint256 _newPrice) public onlyModelOwner(_modelId) {
        if (_optionIndex >= models[uint255(_modelId)].licenseOptions.length) revert DACMM_LicenseOptionNotFound(_modelId, _optionIndex);
        models[uint255(_modelId)].licenseOptions[_optionIndex].price = _newPrice;
        // Note: Does not affect existing licenses.
        emit LicenseOptionPriceUpdated(_modelId, _optionIndex, _newPrice);
    }


    /**
     * @dev Allows the model owner to withdraw their accumulated earnings.
     *      This is the payment received from license sales minus the marketplace fee.
     * @param _modelId The ID of the model to withdraw earnings for.
     */
    function withdrawModelOwnerEarnings(uint256 _modelId) public onlyModelOwner(_modelId) nonReentrant {
        uint256 amount = modelOwnerEarnings[uint255(_modelId)];
        if (amount == 0) revert DACMM_NoEarningsToWithdraw();

        modelOwnerEarnings[uint255(_modelId)] = 0;
        // Use sendValue which handles payable address and checks for re-entrancy risks
        payable(msg.sender).sendValue(amount);

        emit ModelOwnerEarningsWithdrawn(_modelId, msg.sender, amount);
    }

    /**
     * @dev Allows the current model owner to transfer ownership to a new address.
     * @param _modelId The ID of the model.
     * @param _newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 _modelId, address _newOwner) public onlyModelOwner(_modelId) {
        address oldOwner = models[uint255(_modelId)].owner;
        models[uint255(_modelId)].owner = _newOwner;
        emit ModelOwnershipTransferred(_modelId, oldOwner, _newOwner);
    }


    // --- User Interaction (Buying/Using) ---
    /**
     * @dev Allows a user to purchase a license for a model.
     * @param _modelId The ID of the model.
     * @param _optionIndex The index of the desired license option.
     */
    function purchaseLicense(uint256 _modelId, uint256 _optionIndex) public payable nonReentrant whenModelActive(_modelId) returns (uint256) {
        if (_optionIndex >= models[uint255(_modelId)].licenseOptions.length) revert DACMM_LicenseOptionNotFound(_modelId, _optionIndex);
        LicenseOption storage option = models[uint255(_modelId)].licenseOptions[_optionIndex];
        if (!option.isActive) revert DACMM_LicenseOptionInactive();

        if (msg.value < option.price) revert DACMM_InsufficientPayment(option.price, msg.value);

        uint256 purchasePrice = option.price;
        uint256 marketplaceFee = (purchasePrice * marketplaceFeeBasisPoints) / 10000;
        uint256 ownerEarnings = purchasePrice - marketplaceFee;

        // Accumulate owner earnings and marketplace fees
        modelOwnerEarnings[uint255(_modelId)] += ownerEarnings;
        // Marketplace fees are sent to the feeRecipient upon collection by admin

        uint256 newLicenseId = licenseIdCounter++;
        uint64 purchaseTime = uint64(block.timestamp);

        uint64 expiryTime = 0;
        uint256 usesRemaining = 0;

        if (option.optionType == LicenseType.TimeLimited) {
            expiryTime = purchaseTime + uint64(option.duration);
        } else if (option.optionType == LicenseType.UsageBased) {
            usesRemaining = option.maxUses;
        }
        // Perpetual licenses have expiryTime and usesRemaining set to 0 (or effectively infinite)

        licenses[uint255(newLicenseId)] = License({
            modelId: _modelId,
            owner: msg.sender,
            optionIndex: _optionIndex,
            purchaseTime: purchaseTime,
            expiryTime: expiryTime,
            usesRemaining: usesRemaining,
            isActive: true
        });

        userLicenses[msg.sender].push(uint255(newLicenseId));

        // Refund any excess payment
        if (msg.value > purchasePrice) {
            payable(msg.sender).sendValue(msg.value - purchasePrice);
        }

        emit LicensePurchased(newLicenseId, _modelId, msg.sender, purchasePrice);
        return newLicenseId;
    }

    /**
     * @dev Allows the trusted oracle to report usage for a usage-based license.
     *      This is the core function for usage-based licensing fulfillment.
     * @param _licenseId The ID of the license being used.
     * @param _usesReported The number of uses to report.
     */
    function processOracleUsageReport(uint256 _licenseId, uint256 _usesReported) public onlyOracle nonReentrant whenLicenseActive(_licenseId) {
        License storage license = licenses[uint255(_licenseId)];
        Model storage model = models[uint255(license.modelId)];

        // Ensure the license option still exists and is UsageBased (though this check might be redundant if oracle is trusted)
        if (license.optionIndex >= model.licenseOptions.length || model.licenseOptions[license.optionIndex].optionType != LicenseType.UsageBased) {
             revert DACMM_LicenseNotUsageBased(); // Should not happen with correct oracle integration
        }

        if (license.usesRemaining < _usesReported) {
            // This indicates an issue or fraudulent report. Handle appropriately.
            // For now, simply set remaining uses to 0 and potentially deactivate the license.
            // A more complex system might involve slashing oracle stake or triggering a dispute.
             license.usesRemaining = 0;
             license.isActive = false; // Deactivate license on over-reporting
             emit LicenseDeactivated(_licenseId, "Usage exceeded reported max");
        } else {
            license.usesRemaining -= _usesReported;
            if (license.usesRemaining == 0) {
                 license.isActive = false; // Deactivate if uses are exhausted
                 emit LicenseDeactivated(_licenseId, "Usage exhausted");
            }
        }

        emit OracleUsageReported(_licenseId, _usesReported, license.usesRemaining);
    }

    /**
     * @dev Allows a user who holds a license for a model to rate it.
     *      Users can only rate a model once.
     * @param _modelId The ID of the model to rate.
     * @param _rating The rating from 1 to 5.
     */
    function rateModel(uint256 _modelId, uint8 _rating) public nonReentrant {
        if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
        if (_rating < 1 || _rating > 5) revert DACMM_InvalidRating(_rating);

        Model storage model = models[uint255(_modelId)];

        // Check if the user has an active license for this model
        bool hasActiveLicense = false;
        uint255[] storage userLicenseIds = userLicenses[msg.sender];
        for (uint i = 0; i < userLicenseIds.length; i++) {
            uint256 licenseId = userLicenseIds[i];
            if (licenseId < licenseIdCounter && licenses[uint255(licenseId)].modelId == _modelId) {
                 // Check if license is still active based on type logic
                 if (isLicenseActive(licenseId)) {
                    hasActiveLicense = true;
                    break; // Found an active license
                 }
            }
        }
        require(hasActiveLicense, "DACMM: User must have an active license to rate the model");

        // Check if the user has already rated this model
        if (model.ratedBy[msg.sender]) revert DACMM_LicenseAlreadyRated();

        model.totalRatingPoints += _rating;
        model.ratingCount++;
        model.ratedBy[msg.sender] = true;

        emit ModelRated(_modelId, msg.sender, _rating);
    }

    /**
     * @dev Allows the model owner to stake funds on their model.
     *      This can signal quality or be used in dispute resolution.
     * @param _modelId The ID of the model to stake on.
     */
    function stakeForQuality(uint256 _modelId) public payable onlyModelOwner(_modelId) nonReentrant {
        if (msg.value == 0) revert DACMM_StakeAmountZero();
        models[uint255(_modelId)].stakeAmount += msg.value;
        emit StakeDeposited(_modelId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the model owner to withdraw their stake.
     *      May be restricted if there's an active dispute involving the model.
     * @param _modelId The ID of the model to withdraw stake from.
     */
    function withdrawStake(uint256 _modelId) public onlyModelOwner(_modelId) nonReentrant {
        Model storage model = models[uint255(_modelId)];
        if (modelDisputeActive[_modelId]) revert DACMM_StakeWithdrawalLocked();

        uint256 amount = model.stakeAmount;
        if (amount == 0) revert DACMM_StakeAmountZero();

        model.stakeAmount = 0;
        payable(msg.sender).sendValue(amount);

        emit StakeWithdrawn(_modelId, msg.sender, amount);
    }

    // --- Dispute Mechanism ---
    /**
     * @dev Allows a user (license owner) or a model owner to raise a dispute.
     *      Raising a dispute on a license/model might lock stakes or payouts.
     * @param _modelId The ID of the model the dispute is about.
     * @param _licenseId The ID of the license the dispute is about (0 if none).
     * @param _reason Description of the dispute.
     * @return The ID of the newly created dispute.
     */
    function raiseDispute(uint256 _modelId, uint256 _licenseId, string memory _reason) public nonReentrant returns (uint256) {
        // Basic check: Must be related to an existing model
        if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
        // If licenseId > 0, check if it exists and relates to the model, and msg.sender is owner or model owner
        if (_licenseId > 0) {
             if (_licenseId >= licenseIdCounter) revert DACMM_LicenseNotFound(_licenseId);
             require(licenses[uint255(_licenseId)].modelId == _modelId, "DACMM: License does not belong to model");
             require(licenses[uint255(_licenseId)].owner == msg.sender || models[uint255(_modelId)].owner == msg.sender, "DACMM: Must be license or model owner to raise dispute");
        } else {
             // If no license ID, must be the model owner raising a dispute about the model itself
             require(models[uint255(_modelId)].owner == msg.sender, "DACMM: Must be model owner to raise model dispute without license");
        }

        uint256 newDisputeId = disputeIdCounter++;
        disputes[uint255(newDisputeId)] = Dispute({
            modelId: _modelId,
            licenseId: _licenseId,
            raiser: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            resolutionDetails: ""
        });

        // Set flags to lock related entities
        modelDisputeActive[uint255(_modelId)] = true;
        if (_licenseId > 0) {
            licenseDisputeActive[uint255(_licenseId)] = true;
            // Optionally deactivate the license during dispute? Depends on dispute type.
            // For simplicity, license remains active but flagged.
        }

        emit DisputeRaised(newDisputeId, _modelId, _licenseId, msg.sender);
        return newDisputeId;
    }

    /**
     * @dev Allows the admin/arbiter to resolve an open dispute.
     *      Resolution might affect stakes, license validity, or owner earnings.
     *      This is a simplified resolution - a real system would need complex logic.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolvedInFavorOfRaiser True if the dispute is resolved in favor of the raiser.
     * @param _resolutionDetails Details of how the dispute was resolved.
     */
    function resolveDispute(uint256 _disputeId, bool _resolvedInFavorOfRaiser, string memory _resolutionDetails) public onlyOwner nonReentrant {
        if (_disputeId >= disputeIdCounter) revert DACMM_DisputeNotFound(_disputeId);
        Dispute storage dispute = disputes[uint255(_disputeId)];
        if (dispute.status != DisputeStatus.Open) revert DACMM_DisputeNotOpen();

        // Example simplified resolution logic:
        // If resolved in favor of raiser AND related to a license, potentially deactivate license
        // If resolved against raiser AND raiser was model owner, potentially slash stake (complex)
        // If resolved against raiser AND raiser was user, no action needed

        if (_resolvedInFavorOfRaiser) {
             dispute.status = DisputeStatus.Resolved;
             // If license dispute resolved for raiser (user), potentially deactivate license
             if (dispute.licenseId > 0) {
                 licenses[uint255(dispute.licenseId)].isActive = false;
                 emit LicenseDeactivated(dispute.licenseId, "Resolved via dispute");
             }
             // More complex logic needed for stake slashing or fund transfers based on dispute type
        } else {
             dispute.status = DisputeStatus.Rejected;
             // No specific action on entities if dispute rejected, unless stakes were involved.
        }

        dispute.resolutionDetails = _resolutionDetails;

        // Unlock related entities
        modelDisputeActive[uint255(dispute.modelId)] = false;
        if (dispute.licenseId > 0) {
            licenseDisputeActive[uint255(dispute.licenseId)] = false;
        }

        emit DisputeResolved(_disputeId, dispute.status, _resolutionDetails);
    }


    // --- Read Functions ---
    /**
     * @dev Gets a list of all registered model IDs.
     * @return An array of all model IDs.
     */
    function getAvailableModels() public view returns (uint255[] memory) {
        return _allModelIds;
    }

    /**
     * @dev Gets details of a specific model.
     * @param _modelId The ID of the model.
     * @return owner, metadataURI, licenseOptions length, totalRatingPoints, ratingCount, stakeAmount.
     */
    function getModelDetails(uint256 _modelId) public view returns (
        address owner,
        string memory metadataURI,
        uint256 licenseOptionCount,
        uint256 totalRatingPoints,
        uint256 ratingCount,
        uint256 stakeAmount
    ) {
        if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
        Model storage model = models[uint255(_modelId)];
        return (
            model.owner,
            model.metadataURI,
            model.licenseOptions.length,
            model.totalRatingPoints,
            model.ratingCount,
            model.stakeAmount
        );
    }

    /**
     * @dev Gets all license options for a model.
     * @param _modelId The ID of the model.
     * @return An array of LicenseOption structs.
     */
    function getLicenseOptions(uint256 _modelId) public view returns (LicenseOption[] memory) {
        if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
        return models[uint255(_modelId)].licenseOptions;
    }

    /**
     * @dev Gets a list of all license IDs owned by a specific user.
     * @param _user The address of the user.
     * @return An array of license IDs.
     */
    function getUserLicenses(address _user) public view returns (uint255[] memory) {
        return userLicenses[_user];
    }

    /**
     * @dev Gets details of a specific license.
     * @param _licenseId The ID of the license.
     * @return modelId, owner, optionIndex, purchaseTime, expiryTime, usesRemaining, isActive.
     */
    function getLicenseDetails(uint256 _licenseId) public view returns (
        uint256 modelId,
        address owner,
        uint256 optionIndex,
        uint64 purchaseTime,
        uint64 expiryTime,
        uint256 usesRemaining,
        bool isActive
    ) {
        if (_licenseId >= licenseIdCounter) revert DACMM_LicenseNotFound(_licenseId);
         License storage license = licenses[uint255(_licenseId)];
         return (
             license.modelId,
             license.owner,
             license.optionIndex,
             license.purchaseTime,
             license.expiryTime,
             license.usesRemaining,
             license.isActive
         );
    }

    /**
     * @dev Gets the current average rating for a model.
     * @param _modelId The ID of the model.
     * @return The average rating (e.g., 450 for 4.5) or 0 if no ratings.
     */
    function getModelAverageRating(uint256 _modelId) public view returns (uint256) {
         if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
         Model storage model = models[uint255(_modelId)];
         if (model.ratingCount == 0) {
             return 0;
         }
         // Return average * 100 to maintain precision (e.g., 4.5 becomes 450)
         return (model.totalRatingPoints * 100) / model.ratingCount;
    }

     /**
     * @dev Gets the current stake amount for a model.
     * @param _modelId The ID of the model.
     * @return The amount of native currency staked on the model.
     */
    function getModelStake(uint256 _modelId) public view returns (uint256) {
        if (_modelId >= modelIdCounter) revert DACMM_ModelNotFound(_modelId);
        return models[uint255(_modelId)].stakeAmount;
    }

    /**
     * @dev Checks if a license is currently active based on its type, expiry time, or uses remaining.
     * @param _licenseId The ID of the license.
     * @return True if the license is active and valid according to its terms, false otherwise.
     */
    function isLicenseActive(uint256 _licenseId) public view returns (bool) {
        if (_licenseId >= licenseIdCounter) return false; // License doesn't exist
        License storage license = licenses[uint255(_licenseId)];
        if (!license.isActive) return false; // Explicitly deactivated

        Model storage model = models[uint255(license.modelId)]; // Model must exist for options
        if (license.optionIndex >= model.licenseOptions.length) return false; // Option removed? Should not happen if license points to original option

        LicenseOption storage option = model.licenseOptions[license.optionIndex];

        if (option.optionType == LicenseType.TimeLimited) {
            return uint64(block.timestamp) < license.expiryTime;
        } else if (option.optionType == LicenseType.UsageBased) {
            return license.usesRemaining > 0;
        } else { // Perpetual
            return true; // Perpetual licenses are active unless explicitly deactivated
        }
    }

     /**
     * @dev Gets details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return modelId, licenseId, raiser, reason, status, resolutionDetails.
     */
    function getDisputeDetails(uint256 _disputeId) public view returns (
        uint256 modelId,
        uint256 licenseId,
        address raiser,
        string memory reason,
        DisputeStatus status,
        string memory resolutionDetails
    ) {
         if (_disputeId >= disputeIdCounter) revert DACMM_DisputeNotFound(_disputeId);
         Dispute storage dispute = disputes[uint255(_disputeId)];
         return (
             dispute.modelId,
             dispute.licenseId,
             dispute.raiser,
             dispute.reason,
             dispute.status,
             dispute.resolutionDetails
         );
    }

    /**
     * @dev Internal helper to calculate total staked funds in the contract.
     * @return Total amount staked across all models.
     */
    function totalStaked() internal view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < _allModelIds.length; i++) {
            total += models[uint255(_allModelIds[i])].stakeAmount;
        }
        return total;
    }

    /**
     * @dev Internal helper to calculate total funds currently locked due to active disputes.
     *      Simplified: Returns 0. A real system would track locked funds per dispute.
     * @return Total amount locked in disputes.
     */
    function totalInDispute() internal view returns (uint256) {
        // This is a placeholder. A real system would need complex logic to track
        // funds locked per dispute, potentially involving staked amounts or license payments.
        return 0;
    }

    // Add any necessary receive or fallback functions
    receive() external payable {}
    fallback() external payable {}

    // --- Total function count check ---
    // 27 functions:
    // constructor
    // setOracleAddress, setMarketplaceFeeBasisPoints, setFeeRecipient, collectMarketplaceFees (5 admin)
    // registerModel, updateModelMetadata, addLicenseOption, deactivateLicenseOption, updateLicenseOptionPrice, withdrawModelOwnerEarnings, transferModelOwnership (7 model owner)
    // purchaseLicense, processOracleUsageReport, rateModel (3 user/oracle interaction)
    // stakeForQuality, withdrawStake (2 staking)
    // raiseDispute, resolveDispute (2 dispute)
    // getAvailableModels, getModelDetails, getLicenseOptions, getUserLicenses, getLicenseDetails, getModelAverageRating, getModelStake, isLicenseActive, getDisputeDetails (9 read/getters)
    // totalStaked, totalInDispute (2 internal helpers)
    // receive, fallback (2 standard)
    // Total = 1 + 5 + 7 + 3 + 2 + 2 + 9 + 2 + 2 = 33 functions. Well over 20.
}
```