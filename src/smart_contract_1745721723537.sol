Okay, let's design a smart contract for a **Decentralized AI Model Marketplace**, focusing on advanced features like subscription management, usage tracking (requiring off-chain integration context), versioning, and potential governance interactions, without duplicating common open-source patterns like simple ERC721 marketplaces or basic token swaps.

This contract will allow creators to list AI models, users to purchase licenses (per-use or subscriptions), and manage access. Usage tracking is inherently an off-chain problem, so the contract will provide the *mechanism* to verify license validity on-chain before off-chain usage occurs, and a way to potentially record usage or handle disputes (though precise, trustless off-chain usage counting on-chain is still an open research problem; we'll implement a model where the user *claims* usage and the contract verifies permissions).

We will use a placeholder ERC20 token for payments.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Contract Outline ---
// 1. State Variables: Storage for models, licenses, subscriptions, fees, counters.
// 2. Structs: Define data structures for Model, ModelVersion, License, Subscription.
// 3. Events: Log important actions like model creation, license purchase, etc.
// 4. Modifiers: Custom checks (e.g., only creator). (Decided against custom modifiers for simplicity, using internal checks).
// 5. Core Logic Functions:
//    - Model Management: Register, update, add versions, deactivate.
//    - Licensing & Subscription: Purchase, activate, cancel, extend, grant trial, revoke.
//    - Usage Tracking Context: Check validity, record usage (user-initiated decrement).
//    - Financials: Withdraw earnings, platform fees.
//    - Governance Interaction: Propose deactivation, dispute reporting/resolution context.
//    - Utility/View Functions: Get details, list items, check status.

// --- Function Summary ---
// 1. constructor(address _paymentTokenAddress): Initializes the contract with the payment token and sets the owner.
// 2. setPaymentToken(address _newTokenAddress): Allows the owner to change the accepted payment token.
// 3. setPlatformFeeRate(uint256 _feeRateBasisPoints): Sets the platform fee percentage (in basis points, e.g., 100 for 1%). Requires owner.
// 4. registerModel(string memory _metadataHash, string memory _description, uint256 _perUsePrice, uint256 _monthlySubscriptionPrice, uint256 _annualSubscriptionPrice): Allows a creator to list a new AI model. Stores metadata hash (e.g., IPFS CID).
// 5. updateModelDetails(uint256 _modelId, string memory _description, uint256 _perUsePrice, uint256 _monthlySubscriptionPrice, uint256 _annualSubscriptionPrice): Allows the model creator to update description and pricing.
// 6. addModelVersion(uint256 _modelId, string memory _newMetadataHash, string memory _changelogHash): Allows the model creator to add a new version (e.g., updated model weights/code) linked via a new metadata hash.
// 7. deactivateModel(uint256 _modelId): Allows the model creator or governance (context) to deactivate a model, preventing new licenses.
// 8. purchaseLicensePerUse(uint256 _modelId, uint256 _numberOfUses): Allows a user to purchase a specific number of per-use licenses for a model. Requires token approval beforehand.
// 9. activateSubscription(uint256 _modelId, uint256 _durationMonths): Allows a user to purchase a monthly or annual subscription. Requires token approval.
// 10. cancelSubscription(uint256 _subscriptionId): Allows a user to cancel a subscription. It remains active until the paid-up period ends.
// 11. extendSubscription(uint256 _subscriptionId, uint256 _additionalMonths): Allows a user to extend an existing subscription. Requires token approval.
// 12. grantTrialLicense(uint256 _modelId, address _user, uint256 _durationSeconds): Allows the model creator to grant a free, time-limited trial license to a specific user.
// 13. revokeLicense(uint256 _licenseId): Allows the model creator or governance (context) to revoke a specific per-use license immediately (e.g., for TOS violation).
// 14. revokeSubscription(uint256 _subscriptionId): Allows the model creator or governance (context) to revoke a specific subscription immediately.
// 15. checkLicenseValidity(uint256 _licenseId) view: Checks if a specific per-use license is currently valid (exists and has uses remaining).
// 16. checkSubscriptionValidity(uint256 _subscriptionId) view: Checks if a specific subscription is currently valid (exists and not expired).
// 17. checkUserAccess(address _user, uint256 _modelId) view: Checks if a user has ANY active license or subscription for a given model. Useful for off-chain access control checks.
// 18. recordUsageAndDecrement(uint256 _licenseId): Allows the *licensed user* to signal one use of a per-use license. Decrements the available uses. *Important: This relies on the user correctly reporting usage off-chain before calling this function.*
// 19. withdrawCreatorEarnings(uint256 _modelId): Allows a model creator to withdraw their accumulated earnings for a specific model.
// 20. withdrawPlatformFees(): Allows the owner/DAO treasury to withdraw accumulated platform fees.
// 21. reportUsageDiscrepancy(uint256 _licenseOrSubscriptionId, bool _isLicense, string memory _detailsHash): Allows a user or creator to report a discrepancy (e.g., usage count mismatch, access denied despite license) via a details hash (e.g., IPFS). This logs the report for off-chain or governance review.
// 22. resolveDispute(uint256 _reportIndex, address _adjudicator, string memory _resolutionHash): Placeholder function (intended for owner/DAO interaction) to mark a dispute report as resolved, linking to an off-chain resolution details hash. Does not implement complex on-chain dispute logic.
// 23. getModelVersions(uint256 _modelId) view: Returns the list of version hashes for a model.
// 24. getUserActiveLicenses(address _user) view: Returns a list of active per-use license IDs for a user.
// 25. getUserActiveSubscriptions(address _user) view: Returns a list of active subscription IDs for a user.
// 26. getModelEarnings(uint256 _modelId) view: Returns the current accumulated earnings for a specific model creator.

contract DecentralizedAIModelMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IERC20 public paymentToken;
    uint256 public platformFeeRateBasisPoints; // e.g., 100 for 1%

    struct Model {
        address creator;
        string description; // e.g., brief purpose
        string latestMetadataHash; // IPFS CID or similar for model file/details
        uint256 perUsePrice; // in paymentToken units
        uint256 monthlySubscriptionPrice; // in paymentToken units
        uint256 annualSubscriptionPrice; // in paymentToken units
        bool isActive; // Can new licenses be purchased?
        uint256 registeredTimestamp;
        Counters.Counter versionCounter;
        mapping(uint256 => ModelVersion) versions; // versionId => version details
        uint256 accumulatedEarnings; // Creator's balance awaiting withdrawal
    }

    struct ModelVersion {
        string metadataHash; // IPFS CID or similar
        string changelogHash; // IPFS CID for version notes
        uint256 timestamp;
    }

    enum LicenseType {
        PerUse,
        Subscription
    }

    struct License {
        uint256 modelId;
        address user;
        LicenseType licenseType;
        uint256 purchaseTimestamp;
        bool isActive; // Validated by validity checks, but useful flag
        uint256 usesRemaining; // For PerUse licenses
        uint256 expiryTimestamp; // For Subscription licenses
    }

    struct Subscription {
        uint256 modelId;
        address user;
        uint256 startTimestamp;
        uint256 endTimestamp; // Expiry
        bool isActive; // Validated by endTimestamp, but useful flag
    }

    struct DisputeReport {
        uint256 licenseOrSubscriptionId;
        bool isLicense; // True for License, False for Subscription
        address reporter;
        string detailsHash; // IPFS hash for report details
        uint256 timestamp;
        bool isResolved;
        string resolutionHash; // IPFS hash for resolution details
    }


    mapping(uint256 => Model) public models;
    Counters.Counter private _modelIds;

    mapping(uint256 => License) public licenses;
    Counters.Counter private _licenseIds;

    mapping(uint256 => Subscription) public subscriptions;
    Counters.Counter private _subscriptionIds;

    DisputeReport[] public disputeReports; // Simple array for reports

    // Keep track of active licenses/subscriptions for users for easier lookup
    mapping(address => uint256[]) public userActiveLicenseIds;
    mapping(address => uint256[]) public userActiveSubscriptionIds;


    event ModelRegistered(uint256 indexed modelId, address indexed creator, string metadataHash, uint256 timestamp);
    event ModelDetailsUpdated(uint256 indexed modelId, string description, uint256 perUsePrice, uint256 monthlySubPrice, uint256 annualSubPrice);
    event ModelVersionAdded(uint256 indexed modelId, uint256 versionId, string metadataHash, string changelogHash);
    event ModelDeactivated(uint256 indexed modelId, address indexed by);

    event LicensePurchased(uint256 indexed licenseId, uint256 indexed modelId, address indexed user, LicenseType licenseType, uint256 amountPaid, uint256 usesOrExpiry);
    event SubscriptionActivated(uint256 indexed subscriptionId, uint256 indexed modelId, address indexed user, uint256 startTimestamp, uint256 endTimestamp, uint256 amountPaid);
    event SubscriptionExtended(uint256 indexed subscriptionId, uint256 indexed modelId, address indexed user, uint256 newExpiryTimestamp, uint256 amountPaid);
    event SubscriptionCancelled(uint256 indexed subscriptionId, address indexed user);
    event LicenseRevoked(uint256 indexed licenseId, address indexed revokedBy);
    event SubscriptionRevoked(uint256 indexed subscriptionId, address indexed revokedBy);
    event TrialLicenseGranted(uint256 indexed licenseId, uint256 indexed modelId, address indexed user, uint256 expiryTimestamp);

    event UsageRecorded(uint256 indexed licenseId, address indexed user, uint256 usesRemaining);
    event EarningsWithdrawn(uint256 indexed modelId, address indexed creator, uint256 amount);
    event PlatformFeesWithdrawn(address indexed to, uint256 amount);
    event PlatformFeeRateUpdated(uint256 oldRate, uint256 newRate);
    event PaymentTokenUpdated(address oldToken, address newToken);

    event DisputeReported(uint256 indexed reportIndex, uint256 licenseOrSubscriptionId, bool isLicense, address indexed reporter, string detailsHash);
    event DisputeResolved(uint256 indexed reportIndex, address indexed adjudicator, string resolutionHash);


    constructor(address _paymentTokenAddress) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentTokenAddress);
        platformFeeRateBasisPoints = 100; // Default 1%
    }

    // --- Owner/Admin/Config Functions ---

    function setPaymentToken(address _newTokenAddress) external onlyOwner {
        require(_newTokenAddress != address(0), "Invalid address");
        address oldToken = address(paymentToken);
        paymentToken = IERC20(_newTokenAddress);
        emit PaymentTokenUpdated(oldToken, _newTokenAddress);
    }

    function setPlatformFeeRate(uint256 _feeRateBasisPoints) external onlyOwner {
        require(_feeRateBasisPoints <= 10000, "Fee rate exceeds 100%"); // Max 100%
        uint256 oldRate = platformFeeRateBasisPoints;
        platformFeeRateBasisPoints = _feeRateBasisPoints;
        emit PlatformFeeRateUpdated(oldRate, _feeRateBasisPoints);
    }

    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 balance = paymentToken.balanceOf(address(this)) - calculateTotalCreatorEarnings();
        require(balance > 0, "No platform fees to withdraw");

        uint256 transferAmount = balance;
        // Note: This assumes all current balance minus creator earnings is platform fee.
        // A more robust system might track this explicitly.
        // For simplicity here, we use balance check.

        require(paymentToken.transfer(owner(), transferAmount), "Token transfer failed");
        emit PlatformFeesWithdrawn(owner(), transferAmount);
    }

    // Helper to calculate total creator earnings held by the contract
    function calculateTotalCreatorEarnings() internal view returns (uint256) {
        uint256 totalEarnings = 0;
        for (uint256 i = 1; i <= _modelIds.current(); i++) {
             // Check if model exists (in case of future deletion logic)
            if(models[i].creator != address(0)) {
                 totalEarnings += models[i].accumulatedEarnings;
            }
        }
        return totalEarnings;
    }


    // --- Model Management ---

    function registerModel(
        string memory _metadataHash,
        string memory _description,
        uint256 _perUsePrice,
        uint256 _monthlySubscriptionPrice,
        uint256 _annualSubscriptionPrice
    ) external nonReentrant {
        _modelIds.increment();
        uint256 modelId = _modelIds.current();

        models[modelId].creator = msg.sender;
        models[modelId].description = _description;
        models[modelId].latestMetadataHash = _metadataHash; // Initial version
        models[modelId].perUsePrice = _perUsePrice;
        models[modelId].monthlySubscriptionPrice = _monthlySubscriptionPrice;
        models[modelId].annualSubscriptionPrice = _annualSubscriptionPrice;
        models[modelId].isActive = true;
        models[modelId].registeredTimestamp = block.timestamp;
        models[modelId].accumulatedEarnings = 0;

        // Add initial version
        models[modelId].versionCounter.increment();
        uint256 versionId = models[modelId].versionCounter.current();
        models[modelId].versions[versionId] = ModelVersion(_metadataHash, "", block.timestamp); // No changelog for initial version

        emit ModelRegistered(modelId, msg.sender, _metadataHash, block.timestamp);
        emit ModelVersionAdded(modelId, versionId, _metadataHash, "");
    }

    function updateModelDetails(
        uint256 _modelId,
        string memory _description,
        uint256 _perUsePrice,
        uint256 _monthlySubscriptionPrice,
        uint256 _annualSubscriptionPrice
    ) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Not model creator");

        model.description = _description;
        model.perUsePrice = _perUsePrice;
        model.monthlySubscriptionPrice = _monthlySubscriptionPrice;
        model.annualSubscriptionPrice = _annualSubscriptionPrice;

        // Note: Updates only affect *future* license purchases. Active licenses keep old terms.

        emit ModelDetailsUpdated(_modelId, _description, _perUsePrice, model.monthlySubscriptionPrice, model.annualSubscriptionPrice);
    }

    function addModelVersion(uint256 _modelId, string memory _newMetadataHash, string memory _changelogHash) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Not model creator");

        model.latestMetadataHash = _newMetadataHash; // Update latest pointer
        model.versionCounter.increment();
        uint256 versionId = model.versionCounter.current();

        model.versions[versionId] = ModelVersion(_newMetadataHash, _changelogHash, block.timestamp);

        emit ModelVersionAdded(_modelId, versionId, _newMetadataHash, _changelogHash);
    }

    function deactivateModel(uint256 _modelId) external nonReentrant {
        Model storage model = models[_modelId];
        // Allows creator or potentially a DAO/Owner address via a governance call
        require(model.creator == msg.sender || owner() == msg.sender /* || isGovernanceCall() */, "Unauthorized"); // Add governance check context

        require(model.isActive, "Model already inactive");
        model.isActive = false;

        // Note: Deactivation prevents *new* licenses, but existing ones remain valid until expiry/uses run out.

        emit ModelDeactivated(_modelId, msg.sender);
    }

    // --- Licensing & Subscription ---

    function purchaseLicensePerUse(uint256 _modelId, uint256 _numberOfUses) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.isActive, "Model not active");
        require(_numberOfUses > 0, "Must purchase at least one use");

        uint256 totalPrice = model.perUsePrice * _numberOfUses;
        require(totalPrice > 0, "Price is zero");

        // Calculate fees
        uint256 feeAmount = (totalPrice * platformFeeRateBasisPoints) / 10000;
        uint256 creatorAmount = totalPrice - feeAmount;

        // Transfer tokens from user to contract
        require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "Token transfer failed");

        // Credit creator's balance
        model.accumulatedEarnings += creatorAmount;

        // Create license
        _licenseIds.increment();
        uint256 licenseId = _licenseIds.current();

        licenses[licenseId] = License({
            modelId: _modelId,
            user: msg.sender,
            licenseType: LicenseType.PerUse,
            purchaseTimestamp: block.timestamp,
            isActive: true, // Active upon purchase
            usesRemaining: _numberOfUses,
            expiryTimestamp: 0 // Not applicable for per-use
        });

        // Add license ID to user's active list (simple append, requires off-chain filtering for truly active)
        userActiveLicenseIds[msg.sender].push(licenseId);

        emit LicensePurchased(licenseId, _modelId, msg.sender, LicenseType.PerUse, totalPrice, _numberOfUses);
    }

    function activateSubscription(uint256 _modelId, uint256 _durationMonths) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.isActive, "Model not active");
        require(_durationMonths == 1 || _durationMonths == 12, "Duration must be 1 (monthly) or 12 (annual) months");

        uint256 price;
        if (_durationMonths == 1) {
            price = model.monthlySubscriptionPrice;
        } else { // 12 months
            price = model.annualSubscriptionPrice;
        }
        require(price > 0, "Subscription price is zero");

        // Calculate fees
        uint256 feeAmount = (price * platformFeeRateBasisPoints) / 10000;
        uint256 creatorAmount = price - feeAmount;

        // Transfer tokens from user to contract
        require(paymentToken.transferFrom(msg.sender, address(this), price), "Token transfer failed");

        // Credit creator's balance
        model.accumulatedEarnings += creatorAmount;

        // Create subscription
        _subscriptionIds.increment();
        uint256 subscriptionId = _subscriptionIds.current();

        uint256 start = block.timestamp;
        uint256 end = start + _durationMonths * 30 days; // Approximation: 30 days per month

        subscriptions[subscriptionId] = Subscription({
            modelId: _modelId,
            user: msg.sender,
            startTimestamp: start,
            endTimestamp: end,
            isActive: true // Active upon purchase
        });

        // Add subscription ID to user's active list (simple append)
        userActiveSubscriptionIds[msg.sender].push(subscriptionId);


        emit SubscriptionActivated(subscriptionId, _modelId, msg.sender, start, end, price);
    }

    function cancelSubscription(uint256 _subscriptionId) external nonReentrant {
        Subscription storage sub = subscriptions[_subscriptionId];
        require(sub.user == msg.sender, "Not your subscription");
        require(sub.isActive, "Subscription already inactive"); // Can only cancel active ones

        // We don't set isActive to false here. The validity check relies on the endTimestamp.
        // This function just signals intent, preventing auto-renewal if implemented.
        // For this version, it primarily serves as a user action log.
        // A more complex version might handle prorated refunds or prevent future extensions.

        emit SubscriptionCancelled(_subscriptionId, msg.sender);
    }

     function extendSubscription(uint256 _subscriptionId, uint256 _additionalMonths) external nonReentrant {
        Subscription storage sub = subscriptions[_subscriptionId];
        require(sub.user == msg.sender, "Not your subscription");
        require(sub.endTimestamp >= block.timestamp, "Subscription already expired"); // Can only extend active or just-expired subs
        require(_additionalMonths == 1 || _additionalMonths == 12, "Additional duration must be 1 or 12 months");

        Model storage model = models[sub.modelId]; // Use current model price for extension
        require(model.isActive, "Model not active for extension");

        uint256 price;
        if (_additionalMonths == 1) {
            price = model.monthlySubscriptionPrice;
        } else { // 12 months
            price = model.annualSubscriptionPrice;
        }
        require(price > 0, "Subscription price is zero");

        // Calculate fees
        uint256 feeAmount = (price * platformFeeRateBasisPoints) / 10000;
        uint256 creatorAmount = price - feeAmount;

        // Transfer tokens from user to contract
        require(paymentToken.transferFrom(msg.sender, address(this), price), "Token transfer failed");

        // Credit creator's balance
        model.accumulatedEarnings += creatorAmount;

        // Extend end date - if already expired, extend from block.timestamp, otherwise extend from current end date
        uint256 currentEnd = sub.endTimestamp;
        if (currentEnd < block.timestamp) {
             currentEnd = block.timestamp;
        }
        sub.endTimestamp = currentEnd + _additionalMonths * 30 days; // Approximation

        sub.isActive = true; // Ensure it's marked active if it was just expired

        emit SubscriptionExtended(_subscriptionId, sub.modelId, msg.sender, sub.endTimestamp, price);
    }

    function grantTrialLicense(uint256 _modelId, address _user, uint256 _durationSeconds) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Not model creator");
        require(_user != address(0), "Invalid user address");
        require(_durationSeconds > 0, "Trial duration must be positive");

        // Create a temporary license entry
        _licenseIds.increment();
        uint256 licenseId = _licenseIds.current();

        licenses[licenseId] = License({
            modelId: _modelId,
            user: _user,
            licenseType: LicenseType.Subscription, // Treat trial like a time-based subscription for validity check
            purchaseTimestamp: block.timestamp, // Not really purchased, but granted
            isActive: true,
            usesRemaining: 0, // Not applicable
            expiryTimestamp: block.timestamp + _durationSeconds
        });

         // Add license ID to user's active list (simple append)
        userActiveLicenseIds[_user].push(licenseId); // Storing trial license ID here for checkUserAccess

        emit TrialLicenseGranted(licenseId, _modelId, _user, licenses[licenseId].expiryTimestamp);
    }

    function revokeLicense(uint256 _licenseId) external nonReentrant {
        License storage license = licenses[_licenseId];
        require(license.user != address(0), "License does not exist"); // Check if license exists
        Model storage model = models[license.modelId];
        // Allows creator of the model or potentially a DAO/Owner via a governance call
        require(model.creator == msg.sender || owner() == msg.sender /* || isGovernanceCall() */, "Unauthorized"); // Add governance check context

        require(license.isActive, "License already inactive");
        license.isActive = false; // Immediately invalidates

        emit LicenseRevoked(_licenseId, msg.sender);
    }

    function revokeSubscription(uint256 _subscriptionId) external nonReentrant {
        Subscription storage sub = subscriptions[_subscriptionId];
         require(sub.user != address(0), "Subscription does not exist"); // Check if sub exists
        Model storage model = models[sub.modelId];
         // Allows creator of the model or potentially a DAO/Owner via a governance call
        require(model.creator == msg.sender || owner() == msg.sender /* || isGovernanceCall() */, "Unauthorized"); // Add governance check context

        require(sub.isActive, "Subscription already inactive");
        sub.isActive = false; // Immediately invalidates

        emit SubscriptionRevoked(_subscriptionId, msg.sender);
    }


    // --- Usage Tracking Context (Off-chain integration pattern) ---

    // This function is called by off-chain services (or the user via an off-chain service)
    // to verify if a *specific* per-use license ID is valid *before* allowing off-chain usage.
    function checkLicenseValidity(uint256 _licenseId) public view returns (bool) {
        License storage license = licenses[_licenseId];
        // Check if license exists, is active (not revoked), is per-use, and has uses remaining
        return license.user != address(0) &&
               license.isActive &&
               license.licenseType == LicenseType.PerUse &&
               license.usesRemaining > 0;
    }

     // This function is called by off-chain services (or the user)
     // to verify if a *specific* subscription ID is valid *before* allowing off-chain usage.
    function checkSubscriptionValidity(uint256 _subscriptionId) public view returns (bool) {
        Subscription storage sub = subscriptions[_subscriptionId];
        // Check if subscription exists, is active (not revoked), and is not expired
         return sub.user != address(0) &&
                sub.isActive &&
                sub.endTimestamp >= block.timestamp;
    }


    // This is the *primary* on-chain check for off-chain access.
    // An off-chain service requesting access for `_user` to `_modelId` should call this function.
    // It checks if the user has *any* valid per-use license or active subscription for the model.
    function checkUserAccess(address _user, uint256 _modelId) public view returns (bool) {
        // Check all potentially active per-use licenses for this user/model
        uint256[] storage userLicenses = userActiveLicenseIds[_user];
        for (uint256 i = 0; i < userLicenses.length; i++) {
            uint256 licenseId = userLicenses[i];
             // Ensure licenseId refers to an actual license and matches the modelId
            if (licenses[licenseId].user == _user && licenses[licenseId].modelId == _modelId) {
                if (checkLicenseValidity(licenseId)) {
                    return true; // Found a valid per-use license
                }
                 // Note: If checkLicenseValidity returns false, it means expired or out of uses.
                 // We don't remove from the userActiveLicenseIds array here to save gas.
                 // Off-chain filtering or a separate cleanup function would be needed.
            }
        }

        // Check all potentially active subscriptions for this user/model
        uint256[] storage userSubscriptions = userActiveSubscriptionIds[_user];
         for (uint256 i = 0; i < userSubscriptions.length; i++) {
             uint256 subscriptionId = userSubscriptions[i];
              // Ensure subscriptionId refers to an actual subscription and matches the modelId
             if (subscriptions[subscriptionId].user == _user && subscriptions[subscriptionId].modelId == _modelId) {
                 if (checkSubscriptionValidity(subscriptionId)) {
                     return true; // Found a valid subscription
                 }
                 // Note: Similar to licenses, we don't remove expired ones here.
             }
         }

        return false; // No active license or subscription found
    }


    // This function is called by the *licensed user* (or their off-chain service)
    // *after* a successful usage verification via checkLicenseValidity,
    // and *after* the off-chain computation has completed.
    // It decrements the use count for a specific per-use license.
    // It requires the user to be the license holder and the license to still be valid.
    function recordUsageAndDecrement(uint256 _licenseId) external nonReentrant {
        License storage license = licenses[_licenseId];
        require(license.user == msg.sender, "Not your license");
        require(license.licenseType == LicenseType.PerUse, "Not a per-use license");
        require(license.isActive, "License is inactive"); // Explicitly check isActive flag
        require(license.usesRemaining > 0, "No uses remaining");

        license.usesRemaining--;

        // Optional: Remove license ID from userActiveLicenseIds array if usesRemaining becomes 0.
        // This is gas-intensive and depends on how userActiveLicenseIds is used off-chain.
        // For simplicity, we leave it for off-chain filtering or later cleanup.

        emit UsageRecorded(_licenseId, msg.sender, license.usesRemaining);
    }


    // --- Financials ---

    function withdrawCreatorEarnings(uint256 _modelId) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Not model creator");
        uint256 amount = model.accumulatedEarnings;
        require(amount > 0, "No earnings to withdraw");

        model.accumulatedEarnings = 0; // Reset balance BEFORE transfer

        require(paymentToken.transfer(msg.sender, amount), "Token transfer failed");

        emit EarningsWithdrawn(_modelId, msg.sender, amount);
    }


    // --- Dispute Reporting (Context for off-chain/governance action) ---

    function reportUsageDiscrepancy(uint256 _licenseOrSubscriptionId, bool _isLicense, string memory _detailsHash) external nonReentrant {
        // Basic validation: Check if the ID exists and belongs to the sender (reporter)
        address itemOwner = address(0);
        uint256 modelId = 0;

        if (_isLicense) {
            License storage license = licenses[_licenseOrSubscriptionId];
            require(license.user != address(0), "License does not exist");
            itemOwner = license.user;
            modelId = license.modelId;
        } else {
            Subscription storage sub = subscriptions[_licenseOrSubscriptionId];
            require(sub.user != address(0), "Subscription does not exist");
            itemOwner = sub.user;
            modelId = sub.modelId;
        }

        // Either the user who owns the license/sub or the model creator can report
        require(itemOwner == msg.sender || models[modelId].creator == msg.sender, "Not involved in this item");
        require(bytes(_detailsHash).length > 0, "Details hash required");

        disputeReports.push(DisputeReport({
            licenseOrSubscriptionId: _licenseOrSubscriptionId,
            isLicense: _isLicense,
            reporter: msg.sender,
            detailsHash: _detailsHash,
            timestamp: block.timestamp,
            isResolved: false,
            resolutionHash: ""
        }));

        emit DisputeReported(disputeReports.length - 1, _licenseOrSubscriptionId, _isLicense, msg.sender, _detailsHash);
    }

     // This function is intended to be called by the contract owner or a designated governance system
     // It doesn't contain complex resolution logic, just marks the report as resolved and logs the outcome hash.
    function resolveDispute(uint256 _reportIndex, string memory _resolutionHash) external onlyOwner {
        require(_reportIndex < disputeReports.length, "Invalid report index");
        DisputeReport storage report = disputeReports[_reportIndex];
        require(!report.isResolved, "Report already resolved");
        require(bytes(_resolutionHash).length > 0, "Resolution hash required");

        report.isResolved = true;
        report.resolutionHash = _resolutionHash;

        emit DisputeResolved(_reportIndex, msg.sender, _resolutionHash);
    }


    // --- Utility & View Functions ---

    function getModelDetails(uint256 _modelId) external view returns (
        address creator,
        string memory description,
        string memory latestMetadataHash,
        uint256 perUsePrice,
        uint256 monthlySubscriptionPrice,
        uint256 annualSubscriptionPrice,
        bool isActive,
        uint256 registeredTimestamp,
        uint256 currentVersionCount,
        uint256 accumulatedEarnings
    ) {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");

        return (
            model.creator,
            model.description,
            model.latestMetadataHash,
            model.perUsePrice,
            model.monthlySubscriptionPrice,
            model.annualSubscriptionPrice,
            model.isActive,
            model.registeredTimestamp,
            model.versionCounter.current(),
            model.accumulatedEarnings
        );
    }

    function getModelVersions(uint256 _modelId) external view returns (ModelVersion[] memory) {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");

        uint256 versionCount = model.versionCounter.current();
        ModelVersion[] memory versionsArray = new ModelVersion[](versionCount);
        for (uint256 i = 1; i <= versionCount; i++) {
            versionsArray[i-1] = model.versions[i];
        }
        return versionsArray;
    }

     function getUserActiveLicenses(address _user) external view returns (uint256[] memory) {
        // Return the raw list. Off-chain client needs to filter for truly active ones
        // using checkLicenseValidity on each ID.
        return userActiveLicenseIds[_user];
     }

     function getUserActiveSubscriptions(address _user) external view returns (uint256[] memory) {
        // Return the raw list. Off-chain client needs to filter for truly active ones
        // using checkSubscriptionValidity on each ID.
         return userActiveSubscriptionIds[_user];
     }

    function getLicenseDetails(uint256 _licenseId) external view returns (
        uint256 modelId,
        address user,
        LicenseType licenseType,
        uint256 purchaseTimestamp,
        bool isActive, // Note: This flag is for explicit revocation, not validity based on uses/expiry
        uint256 usesRemaining,
        uint256 expiryTimestamp,
        bool isValid // Validity based on uses/expiry AND isActive
    ) {
        License storage license = licenses[_licenseId];
        require(license.user != address(0), "License does not exist");

        bool isValidState;
        if (license.licenseType == LicenseType.PerUse) {
            isValidState = license.usesRemaining > 0;
        } else { // Subscription or Trial
            isValidState = license.expiryTimestamp >= block.timestamp;
        }

        return (
            license.modelId,
            license.user,
            license.licenseType,
            license.purchaseTimestamp,
            license.isActive,
            license.usesRemaining,
            license.expiryTimestamp,
            license.isActive && isValidState // Combined validity
        );
    }

    function getSubscriptionDetails(uint256 _subscriptionId) external view returns (
        uint256 modelId,
        address user,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool isActive, // Note: This flag is for explicit revocation, not validity based on time
        bool isValid // Validity based on endTimestamp AND isActive
    ) {
        Subscription storage sub = subscriptions[_subscriptionId];
         require(sub.user != address(0), "Subscription does not exist");

        bool isValidState = sub.endTimestamp >= block.timestamp;

        return (
            sub.modelId,
            sub.user,
            sub.startTimestamp,
            sub.endTimestamp,
            sub.isActive,
            sub.isActive && isValidState // Combined validity
        );
    }

     function getModelEarnings(uint256 _modelId) external view returns (uint256) {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        return model.accumulatedEarnings;
     }

    function getDisputeReport(uint256 _reportIndex) external view returns (
        uint256 licenseOrSubscriptionId,
        bool isLicense,
        address reporter,
        string memory detailsHash,
        uint256 timestamp,
        bool isResolved,
        string memory resolutionHash
    ) {
         require(_reportIndex < disputeReports.length, "Invalid report index");
         DisputeReport storage report = disputeReports[_reportIndex];
         return (
             report.licenseOrSubscriptionId,
             report.isLicense,
             report.reporter,
             report.detailsHash,
             report.timestamp,
             report.isResolved,
             report.resolutionHash
         );
     }

    function getDisputeReportCount() external view returns (uint256) {
        return disputeReports.length;
    }

    // Total number of models registered (including inactive ones)
    function getTotalModels() external view returns (uint256) {
        return _modelIds.current();
    }

     // Total number of licenses issued (per-use and trial)
    function getTotalLicenses() external view returns (uint256) {
        return _licenseIds.current();
    }

     // Total number of subscriptions issued
    function getTotalSubscriptions() external view returns (uint256) {
        return _subscriptionIds.current();
    }

     // Get the latest version hash for a model
     function getLatestModelVersionHash(uint256 _modelId) external view returns (string memory) {
         Model storage model = models[_modelId];
         require(model.creator != address(0), "Model does not exist");
         return model.latestMetadataHash;
     }

     // Check the creator of a model
     function getModelCreator(uint256 _modelId) external view returns (address) {
         Model storage model = models[_modelId];
         require(model.creator != address(0), "Model does not exist");
         return model.creator;
     }
}
```