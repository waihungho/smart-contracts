```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    DecentralizedInnovationMarketplace (DIM)
    ======================================

    This smart contract provides a decentralized platform for creators to tokenize, license,
    and sell algorithmic IP, research papers, or novel ideas as "Innovation Units" (IUs).
    It supports advanced concepts such as:

    1.  **Dynamic Innovation Units:** IUs are NFT-like tokens representing intellectual property.
        They can be updated with new versions by their creators and have flexible licensing models.
    2.  **Flexible Licensing Models:** Creators can choose from one-time purchases, time-based subscriptions,
        revenue-sharing agreements, and usage-based payments.
    3.  **On-Chain Proof of Concept (PoC) Validation:** Users can initiate a validation process for an
        innovation, escrowing funds. Creators submit validation results, and users can dispute them.
    4.  **Decentralized Dispute Resolution:** A mechanism for arbitrators to resolve disagreements
        over PoC validation, ensuring fairness and trust.
    5.  **Innovation Bounties:** Users can post bounties for specific innovation needs, and creators
        can submit their IUs to fulfill these bounties.
    6.  **Community Curation:** Users can rate innovations, contributing to their visibility and perceived value.
    7.  **Creator Economy Focus:** Provides tools for creators to manage their IP, prices, and earnings,
        with built-in royalty distribution.

    Outline:
    --------
    I.  State Variables & Mappings
    II. Enums & Structs
    III.Events
    IV. Access Control & Non-Reentrancy (Custom Implementations)
    V.  Constructor
    VI. Core Innovation Unit Management (NFT-like + Dynamic Content)
    VII. Licensing & Access Management
    VIII.Proof of Concept (PoC) Validation & Dispute Resolution
    IX. Innovation Bounties
    X.  Platform Administration & Utilities
    XI. Community Curation
    XII. Fallback Function

    Function Summary:
    -----------------

    I.  Core Innovation Unit Management (NFT-like + Dynamic Content)
        1.  `createInnovationUnit(bytes32 _metadataHash, uint256 _price, LicenseType _licensingModel, uint256 _licenseParams)`: Mints a new Innovation Unit (IU) with specified details (ID, creator, metadata, price, licensing type, and parameters).
        2.  `updateInnovationUnit(uint256 _innovationId, bytes32 _newMetadataHash)`: Allows the IU creator to update its underlying IP/metadata hash, incrementing the version.
        3.  `setInnovationUnitPrice(uint256 _innovationId, uint256 _newPrice)`: Allows the IU creator to adjust the price of their innovation unit.
        4.  `setInnovationUnitLicenseModel(uint256 _innovationId, LicenseType _newModel, uint256 _newLicenseParams)`: Allows the IU creator to change the licensing terms and parameters for their innovation unit.
        5.  `transferInnovationUnitOwnership(uint256 _innovationId, address _newOwner)`: Transfers the ownership of the IU token itself (which includes creator rights) to a new address.
        6.  `deactivateInnovationUnit(uint256 _innovationId)`: Allows the creator to temporarily deactivate an IU, preventing new purchases/subscriptions.
        7.  `activateInnovationUnit(uint256 _innovationId)`: Reactivates a previously deactivated IU, making it available again.

    II. Licensing & Access Management
        8.  `purchaseInnovationUnit(uint256 _innovationId)`: Allows a user to purchase a perpetual license for an IU based on a one-time payment model.
        9.  `subscribeToInnovationUnit(uint256 _innovationId, uint256 _durationInSeconds)`: Enables users to subscribe to an IU for a specified duration (for SubscriptionBased IUs).
        10. `renewSubscription(uint256 _innovationId, uint256 _additionalDurationInSeconds)`: Extends an existing subscription for an IU, adding duration to the current expiry.
        11. `payPerUseInnovationUnit(uint256 _innovationId, uint256 _numUses)`: Allows users to pay for a specific number of uses of an IU (for UsageBased IUs).
        12. `getLicensedAccessStatus(uint256 _innovationId, address _user)`: Checks and returns the current licensing status (has access, expiry/uses remaining) for a user and an IU.
        13. `withdrawCreatorEarnings()`: Allows IU creators to withdraw their accumulated earnings from sales, subscriptions, and bounties.

    III. Proof of Concept (PoC) Validation & Dispute Resolution
        14. `initiatePoCValidation(uint256 _innovationId, bytes calldata _validationData)`: User initiates a PoC for an IU, escrowing funds as a bond for testing its functionality.
        15. `submitPoCValidationResult(uint256 _innovationId, uint256 _attemptId, bool _success, bytes calldata _proof)`: Creator or designated validator submits the outcome (success/failure) of a PoC attempt.
        16. `disputePoCValidationResult(uint256 _innovationId, uint256 _attemptId)`: User disputes the submitted PoC validation result if they believe it's incorrect.
        17. `resolvePoCDispute(uint256 _innovationId, uint256 _attemptId, bool _creatorWins)`: An approved arbitrator resolves a PoC dispute, determining who wins the escrowed funds.
        18. `claimPoCEscrow(uint256 _innovationId, uint256 _attemptId)`: Releases escrowed funds to the appropriate party (creator or initiator) after PoC validation or dispute resolution.

    IV. Innovation Bounties
        19. `postInnovationBounty(string calldata _description, uint256 _bountyAmount, uint256 _deadline)`: Allows users to post a bounty for a desired innovation, depositing funds into escrow.
        20. `submitToInnovationBounty(uint256 _bountyId, uint256 _innovationId)`: Creator submits their existing IU as a fulfillment for an open bounty.
        21. `acceptBountySubmission(uint256 _bountyId, uint256 _innovationId)`: Bounty issuer accepts an IU submission, transferring bounty funds (minus platform fees) to the creator.

    V.  Platform Administration & Utilities
        22. `setPlatformFee(uint256 _newFeeBps)`: Owner sets the platform fee percentage for all transactions (in basis points).
        23. `updateArbitrators(address[] calldata _newArbitrators)`: Owner updates the entire list of authorized arbitrators for dispute resolution.
        24. `withdrawPlatformFees()`: Owner withdraws all accumulated platform fees from various transactions.

    VI. Community Curation
        25. `rateInnovationUnit(uint256 _innovationId, uint8 _rating)`: Users can provide a rating (1-5 stars) for an innovation unit, contributing to its public perception.
        26. `getAverageRating(uint256 _innovationId)`: Retrieves the current average rating for an innovation unit, calculated from all user ratings.

    XII. Fallback Function
        27. `receive()`: Prevents accidental direct Ether transfers to the contract, ensuring all value transfers go through designated functions.

*/

contract DecentralizedInnovationMarketplace {

    // I. State Variables & Mappings
    address public immutable i_owner; // Platform owner
    uint256 public s_innovationUnitCounter; // Auto-incrementing ID for Innovation Units
    uint256 public s_pocAttemptCounter; // Auto-incrementing ID for PoC attempts
    uint256 public s_bountyCounter; // Auto-incrementing ID for bounties

    uint256 public s_platformFeeBps; // Platform fee in basis points (e.g., 100 = 1%)
    uint256 public s_totalPlatformFeesAccumulated;

    mapping(uint256 => InnovationUnit) public s_innovationUnits;
    mapping(address => uint256) public s_creatorEarnings; // Funds owed to creators
    mapping(address => mapping(uint256 => UserLicense)) public s_userLicenses; // user => innovationId => license
    mapping(uint256 => PoCAttempt) public s_pocAttempts;
    mapping(uint256 => PoCDispute) public s_pocDisputes; // Maps pocAttemptId to dispute details if it exists
    mapping(uint256 => InnovationBounty) public s_innovationBounties;

    // Custom NFT-like storage for Innovation Units
    mapping(uint256 => address) private _innovationUnitOwners; // innovationId => owner address
    mapping(address => uint256) private _innovationUnitBalances; // owner address => count of owned IUs

    mapping(address => bool) public s_isArbitrator; // Address => is arbitrator
    address[] internal _currentArbitrators; // Tracks the actual list of arbitrator addresses
    mapping(address => mapping(uint256 => bool)) public s_hasRated; // user => innovationId => hasRated

    // II. Enums & Structs
    enum LicenseType {
        OneTimePurchase,    // User buys perpetual access
        SubscriptionBased,  // User subscribes for a duration
        RevenueShare,       // User gets a share of future revenue generated by the IU (advanced, less direct in this impl)
        UsageBased          // User pays per use, `_licenseParams` specifies price per use
    }

    enum PoCStatus {
        Initiated,
        CreatorSubmittedResult,
        Disputed,
        ResolvedSuccess,
        ResolvedFailure,
        ClaimedFunds
    }

    enum DisputeStatus {
        Open,
        Resolved
    }

    struct InnovationUnit {
        uint256 id;
        address creator;
        address currentOwner; // Owner of the IU NFT itself, usually the creator initially
        bytes32 metadataHash; // IPFS hash or similar for actual algorithm/paper
        uint256 price;
        LicenseType licenseType;
        // licenseParams meaning depends on LicenseType:
        // - SubscriptionBased: Duration in seconds for a standard subscription period (used for pricing)
        // - RevenueShare: Basis points (BPS) for revenue sharing (e.g., 100 = 1%)
        // - UsageBased: Price per single use
        uint256 licenseParams; 
        uint256 creationTimestamp;
        uint256 lastUpdatedTimestamp;
        uint256 version;
        bool isActive; // Can be deactivated by creator/platform
        uint256 totalRevenueEarned; // For this specific IU
        uint256 totalRatings;
        uint256 sumOfRatings;
    }

    struct UserLicense {
        uint256 innovationId;
        address user;
        uint256 purchaseTimestamp;
        uint256 expiryTimestamp; // For subscriptions (0 if not applicable)
        uint256 usesRemaining; // For pay-per-use (0 if not applicable)
        uint256 revenueShareAccumulated; // If user acquired a revenue share license (more advanced, not fully implemented for distribution here)
        bool perpetual; // True for OneTimePurchase
    }

    struct PoCAttempt {
        uint256 id;
        uint256 innovationId;
        address initiator;
        uint256 escrowAmount;
        bytes validationData; // Data provided by initiator for validation
        bytes creatorProof; // Data provided by creator for validation success
        PoCStatus status;
        uint256 creationTimestamp;
        uint256 lastUpdateTimestamp;
        bool creatorValidatedSuccess; // Creator's submission
    }

    struct PoCDispute {
        uint256 attemptId; // Links back to the PoCAttempt
        address initiator;
        address creator;
        uint256 resolutionTimestamp;
        bool creatorWins; // True if arbitrators ruled in favor of creator
        DisputeStatus status;
    }

    struct InnovationBounty {
        uint256 id;
        address issuer;
        string description;
        uint256 bountyAmount; // Funds held in escrow for the bounty
        uint256 deadline;
        uint256 submissionInnovationId; // ID of the accepted submission
        address submitter; // Creator of the accepted submission
        bool claimed;
        bool active;
        uint256 creationTimestamp;
    }

    // III. Events
    event InnovationUnitCreated(uint256 indexed innovationId, address indexed creator, bytes32 metadataHash, uint256 price, LicenseType licenseType);
    event InnovationUnitUpdated(uint256 indexed innovationId, bytes32 newMetadataHash, uint256 version);
    event InnovationUnitPriceUpdated(uint256 indexed innovationId, uint256 oldPrice, uint256 newPrice);
    event InnovationUnitLicenseModelUpdated(uint256 indexed innovationId, LicenseType oldModel, LicenseType newModel, uint256 oldParams, uint256 newParams);
    event InnovationUnitTransferred(uint256 indexed innovationId, address indexed from, address indexed to);
    event InnovationUnitActivated(uint256 indexed innovationId);
    event InnovationUnitDeactivated(uint256 indexed innovationId);

    event LicensePurchased(uint256 indexed innovationId, address indexed user, LicenseType licenseType, uint256 amountPaid, uint256 expiryTimestamp, bool perpetual);
    event SubscriptionRenewed(uint256 indexed innovationId, address indexed user, uint256 newExpiryTimestamp);
    event UsesPaid(uint256 indexed innovationId, address indexed user, uint256 numUses, uint256 amountPaid);
    event CreatorEarningsWithdrawn(address indexed creator, uint256 amount);

    event PoCValidationInitiated(uint256 indexed pocAttemptId, uint256 indexed innovationId, address indexed initiator, uint256 escrowAmount);
    event PoCValidationResultSubmitted(uint256 indexed pocAttemptId, uint256 indexed innovationId, address indexed submitter, bool success);
    event PoCValidationDisputed(uint256 indexed pocAttemptId, uint256 indexed innovationId, address indexed initiator);
    event PoCDisputeResolved(uint256 indexed pocAttemptId, uint256 indexed innovationId, bool creatorWins);
    event PoCEscrowClaimed(uint256 indexed pocAttemptId, uint256 indexed innovationId, address recipient, uint256 amount);

    event InnovationBountyPosted(uint256 indexed bountyId, address indexed issuer, uint256 amount, uint256 deadline);
    event InnovationSubmittedToBounty(uint256 indexed bountyId, uint256 indexed innovationId, address indexed submitter);
    event BountySubmissionAccepted(uint256 indexed bountyId, uint256 indexed innovationId, address indexed submitter, address indexed issuer, uint256 amount);

    event PlatformFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event ArbitratorsUpdated(address[] newArbitrators);
    event PlatformFeesWithdrawn(uint256 amount);

    event InnovationUnitRated(uint256 indexed innovationId, address indexed user, uint8 rating);

    // IV. Access Control & Non-Reentrancy (Custom Implementations)
    // Custom Ownable logic
    modifier onlyOwner() {
        require(msg.sender == i_owner, "DIM: Not the owner");
        _;
    }

    // Custom ReentrancyGuard logic
    uint256 private _locked;
    modifier nonReentrant() {
        require(_locked == 0, "DIM: Reentrant call");
        _locked = 1;
        _;
        _locked = 0;
    }

    modifier onlyCreator(uint256 _innovationId) {
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(s_innovationUnits[_innovationId].creator == msg.sender, "DIM: Not the creator of this IU");
        _;
    }

    modifier onlyIUOwner(uint256 _innovationId) {
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(_innovationUnitOwners[_innovationId] == msg.sender, "DIM: Not the owner of this IU token");
        _;
    }

    modifier onlyArbitrator() {
        require(s_isArbitrator[msg.sender], "DIM: Not an authorized arbitrator");
        _;
    }

    // V. Constructor
    constructor(uint256 _initialPlatformFeeBps, address[] calldata _initialArbitrators) {
        i_owner = msg.sender;
        require(_initialPlatformFeeBps <= 10000, "DIM: Fee BPS cannot exceed 100%"); // 10000 BPS = 100%
        s_platformFeeBps = _initialPlatformFeeBps;

        for (uint256 i = 0; i < _initialArbitrators.length; i++) {
            require(_initialArbitrators[i] != address(0), "DIM: Arbitrator cannot be zero address");
            s_isArbitrator[_initialArbitrators[i]] = true;
            _currentArbitrators.push(_initialArbitrators[i]);
        }
    }

    // Internal helper for IU existence
    function _innovationUnitExists(uint256 _innovationId) internal view returns (bool) {
        return s_innovationUnits[_innovationId].creator != address(0);
    }

    // Internal Custom NFT-like mint/transfer for Innovation Units
    function _mintInnovationUnit(address _to, uint256 _innovationId) internal {
        require(_to != address(0), "DIM: Mint to zero address");
        require(!_innovationUnitExists(_innovationId), "DIM: Innovation Unit already exists with this ID");

        _innovationUnitOwners[_innovationId] = _to;
        _innovationUnitBalances[_to]++;
    }

    function _transferInnovationUnit(address _from, address _to, uint256 _innovationId) internal {
        require(_from != address(0), "DIM: Transfer from zero address");
        require(_to != address(0), "DIM: Transfer to zero address");
        require(_innovationUnitOwners[_innovationId] == _from, "DIM: Sender does not own this IU token");

        _innovationUnitBalances[_from]--;
        _innovationUnitOwners[_innovationId] = _to;
        _innovationUnitBalances[_to]++;
    }

    // VI. Core Innovation Unit Management (NFT-like + Dynamic Content)
    // 1. `createInnovationUnit`
    function createInnovationUnit(
        bytes32 _metadataHash,
        uint256 _price,
        LicenseType _licensingModel,
        uint256 _licenseParams // Duration for Subscription, BPS for RevenueShare, PricePerUse for UsageBased
    ) external nonReentrant returns (uint256) {
        s_innovationUnitCounter++;
        uint256 newId = s_innovationUnitCounter;
        uint256 currentTimestamp = block.timestamp;

        // Basic validation for license params
        if (_licensingModel == LicenseType.SubscriptionBased) {
            require(_licenseParams > 0, "DIM: Subscription duration must be positive");
        } else if (_licensingModel == LicenseType.RevenueShare) {
            require(_licenseParams > 0 && _licenseParams <= 10000, "DIM: Revenue share BPS invalid (0-10000)");
        } else if (_licensingModel == LicenseType.UsageBased) {
             require(_licenseParams > 0, "DIM: Usage price must be positive");
        }

        s_innovationUnits[newId] = InnovationUnit({
            id: newId,
            creator: msg.sender,
            currentOwner: msg.sender, // Creator is the initial owner of the IU token
            metadataHash: _metadataHash,
            price: _price,
            licenseType: _licensingModel,
            licenseParams: _licenseParams,
            creationTimestamp: currentTimestamp,
            lastUpdatedTimestamp: currentTimestamp,
            version: 1,
            isActive: true,
            totalRevenueEarned: 0,
            totalRatings: 0,
            sumOfRatings: 0
        });

        _mintInnovationUnit(msg.sender, newId); // Mint the custom IU token

        emit InnovationUnitCreated(newId, msg.sender, _metadataHash, _price, _licensingModel);
        return newId;
    }

    // 2. `updateInnovationUnit`
    function updateInnovationUnit(uint256 _innovationId, bytes32 _newMetadataHash)
        external
        nonReentrant
        onlyCreator(_innovationId)
    {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(iu.isActive, "DIM: IU is not active");
        require(iu.metadataHash != _newMetadataHash, "DIM: New metadata hash is same as old");

        iu.metadataHash = _newMetadataHash;
        iu.version++;
        iu.lastUpdatedTimestamp = block.timestamp;

        emit InnovationUnitUpdated(_innovationId, _newMetadataHash, iu.version);
    }

    // 3. `setInnovationUnitPrice`
    function setInnovationUnitPrice(uint256 _innovationId, uint256 _newPrice)
        external
        nonReentrant
        onlyCreator(_innovationId)
    {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(iu.isActive, "DIM: IU is not active");
        require(iu.price != _newPrice, "DIM: New price is same as old");

        uint256 oldPrice = iu.price;
        iu.price = _newPrice;

        emit InnovationUnitPriceUpdated(_innovationId, oldPrice, _newPrice);
    }

    // 4. `setInnovationUnitLicenseModel`
    function setInnovationUnitLicenseModel(uint256 _innovationId, LicenseType _newModel, uint256 _newLicenseParams)
        external
        nonReentrant
        onlyCreator(_innovationId)
    {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(iu.isActive, "DIM: IU is not active");

        // Basic validation for license params
        if (_newModel == LicenseType.SubscriptionBased) {
            require(_newLicenseParams > 0, "DIM: Subscription duration must be positive");
        } else if (_newModel == LicenseType.RevenueShare) {
            require(_newLicenseParams > 0 && _newLicenseParams <= 10000, "DIM: Revenue share BPS invalid (0-10000)");
        } else if (_newModel == LicenseType.UsageBased) {
             require(_newLicenseParams > 0, "DIM: Usage price must be positive");
        }

        LicenseType oldModel = iu.licenseType;
        uint256 oldParams = iu.licenseParams;

        iu.licenseType = _newModel;
        iu.licenseParams = _newLicenseParams;

        emit InnovationUnitLicenseModelUpdated(_innovationId, oldModel, _newModel, oldParams, _newLicenseParams);
    }

    // 5. `transferInnovationUnitOwnership`
    function transferInnovationUnitOwnership(uint256 _innovationId, address _newOwner)
        external
        nonReentrant
        onlyIUOwner(_innovationId)
    {
        require(_newOwner != address(0), "DIM: Cannot transfer to zero address");
        require(_newOwner != msg.sender, "DIM: Cannot transfer to self");

        address oldOwner = _innovationUnitOwners[_innovationId];
        s_innovationUnits[_innovationId].currentOwner = _newOwner; // Update currentOwner in the struct
        s_innovationUnits[_innovationId].creator = _newOwner; // New owner becomes the creator of the IP

        _transferInnovationUnit(oldOwner, _newOwner, _innovationId);

        emit InnovationUnitTransferred(_innovationId, oldOwner, _newOwner);
    }

    // 6. `deactivateInnovationUnit`
    function deactivateInnovationUnit(uint256 _innovationId) external onlyCreator(_innovationId) {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(iu.isActive, "DIM: IU is already inactive");
        iu.isActive = false;
        emit InnovationUnitDeactivated(_innovationId);
    }

    // 7. `activateInnovationUnit`
    function activateInnovationUnit(uint256 _innovationId) external onlyCreator(_innovationId) {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(!iu.isActive, "DIM: IU is already active");
        iu.isActive = true;
        emit InnovationUnitActivated(_innovationId);
    }

    // VII. Licensing & Access Management
    // Internal helper to process payment and distribute funds
    function _processPayment(uint256 _innovationId, uint256 _amount) internal {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        uint256 platformFee = (_amount * s_platformFeeBps) / 10000;
        uint256 creatorShare = _amount - platformFee;

        s_totalPlatformFeesAccumulated += platformFee;
        s_creatorEarnings[iu.creator] += creatorShare;
        iu.totalRevenueEarned += _amount;
    }

    // 8. `purchaseInnovationUnit`
    function purchaseInnovationUnit(uint256 _innovationId) external payable nonReentrant {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(iu.isActive, "DIM: IU is not active");
        require(iu.licenseType == LicenseType.OneTimePurchase, "DIM: IU not for one-time purchase");
        require(msg.value == iu.price, "DIM: Incorrect payment amount");
        require(s_userLicenses[msg.sender][_innovationId].perpetual == false, "DIM: User already owns perpetual license");

        _processPayment(_innovationId, msg.value);

        s_userLicenses[msg.sender][_innovationId] = UserLicense({
            innovationId: _innovationId,
            user: msg.sender,
            purchaseTimestamp: block.timestamp,
            expiryTimestamp: 0, // Not applicable for perpetual
            usesRemaining: 0, // Not applicable
            revenueShareAccumulated: 0, // Not applicable
            perpetual: true
        });

        emit LicensePurchased(_innovationId, msg.sender, iu.licenseType, msg.value, 0, true);
    }

    // 9. `subscribeToInnovationUnit`
    function subscribeToInnovationUnit(uint256 _innovationId, uint256 _durationInSeconds) external payable nonReentrant {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(iu.isActive, "DIM: IU is not active");
        require(iu.licenseType == LicenseType.SubscriptionBased, "DIM: IU not for subscription");
        require(iu.licenseParams > 0, "DIM: Creator has not set a base duration for subscription pricing");
        require(_durationInSeconds > 0, "DIM: Subscription duration must be positive");

        // Price scales with requested duration relative to the base duration set by creator
        uint256 totalCost = (iu.price * _durationInSeconds) / iu.licenseParams; 
        require(msg.value == totalCost, "DIM: Incorrect payment amount for subscription duration");

        _processPayment(_innovationId, msg.value);

        UserLicense storage userLicense = s_userLicenses[msg.sender][_innovationId];
        uint256 newExpiry = block.timestamp + _durationInSeconds;
        
        // If user already has an active subscription, extend it from its current expiry, not from now.
        if (userLicense.expiryTimestamp > block.timestamp) {
            newExpiry = userLicense.expiryTimestamp + _durationInSeconds;
        }

        userLicense.innovationId = _innovationId;
        userLicense.user = msg.sender;
        userLicense.purchaseTimestamp = block.timestamp;
        userLicense.expiryTimestamp = newExpiry;
        userLicense.perpetual = false;

        emit LicensePurchased(_innovationId, msg.sender, iu.licenseType, msg.value, newExpiry, false);
    }

    // 10. `renewSubscription`
    function renewSubscription(uint256 _innovationId, uint256 _additionalDurationInSeconds) external payable nonReentrant {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        UserLicense storage userLicense = s_userLicenses[msg.sender][_innovationId];

        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(iu.isActive, "DIM: IU is not active");
        require(iu.licenseType == LicenseType.SubscriptionBased, "DIM: IU not for subscription");
        require(userLicense.expiryTimestamp > 0, "DIM: No active subscription to renew"); 
        require(iu.licenseParams > 0, "DIM: Creator has not set a base duration for subscription pricing");
        require(_additionalDurationInSeconds > 0, "DIM: Additional duration must be positive");
        
        uint256 totalCost = (iu.price * _additionalDurationInSeconds) / iu.licenseParams;
        require(msg.value == totalCost, "DIM: Incorrect payment amount for renewal duration");

        _processPayment(_innovationId, msg.value);

        userLicense.expiryTimestamp += _additionalDurationInSeconds;

        emit SubscriptionRenewed(_innovationId, msg.sender, userLicense.expiryTimestamp);
    }

    // 11. `payPerUseInnovationUnit`
    function payPerUseInnovationUnit(uint256 _innovationId, uint256 _numUses) external payable nonReentrant {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(iu.isActive, "DIM: IU is not active");
        require(iu.licenseType == LicenseType.UsageBased, "DIM: IU not for usage-based payments");
        require(_numUses > 0, "DIM: Number of uses must be positive");
        require(iu.licenseParams > 0, "DIM: Creator has not set a price per use");

        uint256 pricePerUse = iu.licenseParams; // Price per use is stored in licenseParams
        uint256 totalCost = pricePerUse * _numUses;
        require(msg.value == totalCost, "DIM: Incorrect payment for specified uses");

        _processPayment(_innovationId, msg.value);

        UserLicense storage userLicense = s_userLicenses[msg.sender][_innovationId];
        userLicense.innovationId = _innovationId;
        userLicense.user = msg.sender;
        userLicense.purchaseTimestamp = block.timestamp;
        userLicense.usesRemaining += _numUses; // Add to existing uses
        userLicense.perpetual = false;

        emit UsesPaid(_innovationId, msg.sender, _numUses, msg.value);
    }

    // 12. `getLicensedAccessStatus`
    function getLicensedAccessStatus(uint256 _innovationId, address _user)
        external
        view
        returns (bool hasAccess, uint256 expiryOrUsesRemaining, LicenseType licenseType)
    {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        UserLicense storage userLicense = s_userLicenses[_user][_innovationId];

        licenseType = iu.licenseType;

        if (iu.licenseType == LicenseType.OneTimePurchase) {
            hasAccess = userLicense.perpetual;
            expiryOrUsesRemaining = 0; // Not applicable
        } else if (iu.licenseType == LicenseType.SubscriptionBased) {
            hasAccess = userLicense.expiryTimestamp > block.timestamp;
            expiryOrUsesRemaining = userLicense.expiryTimestamp;
        } else if (iu.licenseType == LicenseType.UsageBased) {
            hasAccess = userLicense.usesRemaining > 0;
            expiryOrUsesRemaining = userLicense.usesRemaining;
        } else if (iu.licenseType == LicenseType.RevenueShare) {
            // For revenue share, access might be perpetual. Status here implies perpetual access to underlying IP.
            hasAccess = userLicense.perpetual; // Assuming a revenue share purchase grants perpetual access
            expiryOrUsesRemaining = userLicense.revenueShareAccumulated; // Could return accumulated share
        }
        return (hasAccess, expiryOrUsesRemaining, licenseType);
    }

    // 13. `withdrawCreatorEarnings`
    function withdrawCreatorEarnings() external nonReentrant {
        uint256 amount = s_creatorEarnings[msg.sender];
        require(amount > 0, "DIM: No earnings to withdraw");
        s_creatorEarnings[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "DIM: Failed to withdraw earnings");

        emit CreatorEarningsWithdrawn(msg.sender, amount);
    }

    // VIII. Proof of Concept (PoC) Validation & Dispute Resolution
    // 14. `initiatePoCValidation`
    function initiatePoCValidation(uint256 _innovationId, bytes calldata _validationData) external payable nonReentrant returns (uint256) {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(iu.isActive, "DIM: IU is not active");
        require(msg.value > 0, "DIM: Escrow amount must be positive");
        require(msg.sender != iu.creator, "DIM: Creator cannot initiate PoC for their own IU");

        s_pocAttemptCounter++;
        uint256 newAttemptId = s_pocAttemptCounter;

        s_pocAttempts[newAttemptId] = PoCAttempt({
            id: newAttemptId,
            innovationId: _innovationId,
            initiator: msg.sender,
            escrowAmount: msg.value,
            validationData: _validationData,
            creatorProof: "",
            status: PoCStatus.Initiated,
            creationTimestamp: block.timestamp,
            lastUpdateTimestamp: block.timestamp,
            creatorValidatedSuccess: false
        });

        emit PoCValidationInitiated(newAttemptId, _innovationId, msg.sender, msg.value);
        return newAttemptId;
    }

    // 15. `submitPoCValidationResult`
    function submitPoCValidationResult(uint256 _innovationId, uint256 _attemptId, bool _success, bytes calldata _proof)
        external
        nonReentrant
        onlyCreator(_innovationId)
    {
        PoCAttempt storage attempt = s_pocAttempts[_attemptId];
        require(attempt.innovationId == _innovationId, "DIM: Attempt ID mismatch for innovation");
        require(attempt.initiator != address(0), "DIM: PoC Attempt not found");
        require(attempt.status == PoCStatus.Initiated, "DIM: PoC attempt not in initiated state");

        attempt.creatorProof = _proof;
        attempt.creatorValidatedSuccess = _success;
        attempt.status = PoCStatus.CreatorSubmittedResult;
        attempt.lastUpdateTimestamp = block.timestamp;

        emit PoCValidationResultSubmitted(_attemptId, _innovationId, msg.sender, _success);
    }

    // 16. `disputePoCValidationResult`
    function disputePoCValidationResult(uint256 _innovationId, uint256 _attemptId) external nonReentrant {
        PoCAttempt storage attempt = s_pocAttempts[_attemptId];
        require(attempt.innovationId == _innovationId, "DIM: Attempt ID mismatch for innovation");
        require(attempt.initiator == msg.sender, "DIM: Only initiator can dispute");
        require(attempt.status == PoCStatus.CreatorSubmittedResult, "DIM: PoC attempt not in submitted result state");
        require(_currentArbitrators.length > 0, "DIM: No arbitrators setup by platform owner");

        attempt.status = PoCStatus.Disputed;
        attempt.lastUpdateTimestamp = block.timestamp;

        // Create a new dispute entry. For simplicity, disputeId will just match attemptId.
        s_pocDisputes[_attemptId] = PoCDispute({
            attemptId: _attemptId,
            initiator: attempt.initiator,
            creator: s_innovationUnits[_innovationId].creator,
            resolutionTimestamp: 0,
            creatorWins: false,
            status: DisputeStatus.Open
        });

        emit PoCValidationDisputed(_attemptId, _innovationId, msg.sender);
    }

    // 17. `resolvePoCDispute`
    function resolvePoCDispute(uint256 _innovationId, uint256 _attemptId, bool _creatorWins) external nonReentrant onlyArbitrator {
        PoCAttempt storage attempt = s_pocAttempts[_attemptId];
        PoCDispute storage dispute = s_pocDisputes[_attemptId];

        require(attempt.innovationId == _innovationId, "DIM: Attempt ID mismatch for innovation");
        require(attempt.initiator != address(0), "DIM: PoC Attempt not found");
        require(attempt.status == PoCStatus.Disputed, "DIM: PoC attempt not in disputed state");
        require(dispute.status == DisputeStatus.Open, "DIM: Dispute is not open");

        attempt.status = _creatorWins ? PoCStatus.ResolvedSuccess : PoCStatus.ResolvedFailure;
        attempt.lastUpdateTimestamp = block.timestamp;

        dispute.creatorWins = _creatorWins;
        dispute.resolutionTimestamp = block.timestamp;
        dispute.status = DisputeStatus.Resolved;
        // In a real system, multiple arbitrators would vote, and _creatorWins would be a result of that vote.
        // Here, a single arbitrator can make the call.

        emit PoCDisputeResolved(_attemptId, _innovationId, _creatorWins);
    }

    // 18. `claimPoCEscrow`
    function claimPoCEscrow(uint256 _innovationId, uint256 _attemptId) external nonReentrant {
        PoCAttempt storage attempt = s_pocAttempts[_attemptId];
        require(attempt.innovationId == _innovationId, "DIM: Attempt ID mismatch for innovation");
        require(attempt.initiator != address(0), "DIM: PoC Attempt not found");
        require(
            attempt.status == PoCStatus.CreatorSubmittedResult ||
            attempt.status == PoCStatus.ResolvedSuccess ||
            attempt.status == PoCStatus.ResolvedFailure,
            "DIM: PoC attempt not in a claimable state"
        );
        require(attempt.status != PoCStatus.ClaimedFunds, "DIM: Funds already claimed");

        address creatorAddress = s_innovationUnits[_innovationId].creator;
        uint256 amountInEscrow = attempt.escrowAmount;

        bool creatorWinsDecision;

        if (attempt.status == PoCStatus.CreatorSubmittedResult) {
            // No dispute, result based on creator's submission.
            creatorWinsDecision = attempt.creatorValidatedSuccess;
        } else { // PoCStatus.ResolvedSuccess or PoCStatus.ResolvedFailure
            // Result based on arbitrator's decision.
            PoCDispute storage dispute = s_pocDisputes[_attemptId];
            require(dispute.status == DisputeStatus.Resolved, "DIM: Dispute not resolved yet");
            creatorWinsDecision = dispute.creatorWins;
        }

        attempt.status = PoCStatus.ClaimedFunds;
        attempt.lastUpdateTimestamp = block.timestamp;

        if (creatorWinsDecision) {
            // Creator wins: funds go to creator's earnings, subject to platform fees.
            _processPayment(_innovationId, amountInEscrow);
            emit PoCEscrowClaimed(_attemptId, _innovationId, creatorAddress, amountInEscrow); // Emit total escrow, creator will withdraw their share.
        } else {
            // Initiator wins: funds returned to initiator, no platform fees.
            (bool success, ) = attempt.initiator.call{value: amountInEscrow}("");
            require(success, "DIM: Failed to return funds to initiator");
            emit PoCEscrowClaimed(_attemptId, _innovationId, attempt.initiator, amountInEscrow);
        }
    }

    // IX. Innovation Bounties
    // 19. `postInnovationBounty`
    function postInnovationBounty(string calldata _description, uint256 _bountyAmount, uint256 _deadline) external payable nonReentrant returns (uint256) {
        require(bytes(_description).length > 0, "DIM: Description cannot be empty");
        require(_bountyAmount > 0, "DIM: Bounty amount must be positive");
        require(msg.value == _bountyAmount, "DIM: Sent amount must match bounty amount");
        require(_deadline > block.timestamp, "DIM: Deadline must be in the future");

        s_bountyCounter++;
        uint256 newBountyId = s_bountyCounter;

        s_innovationBounties[newBountyId] = InnovationBounty({
            id: newBountyId,
            issuer: msg.sender,
            description: _description,
            bountyAmount: _bountyAmount,
            deadline: _deadline,
            submissionInnovationId: 0,
            submitter: address(0),
            claimed: false,
            active: true,
            creationTimestamp: block.timestamp
        });

        emit InnovationBountyPosted(newBountyId, msg.sender, _bountyAmount, _deadline);
        return newBountyId;
    }

    // 20. `submitToInnovationBounty`
    function submitToInnovationBounty(uint256 _bountyId, uint256 _innovationId) external onlyCreator(_innovationId) {
        InnovationBounty storage bounty = s_innovationBounties[_bountyId];
        require(bounty.active, "DIM: Bounty is not active");
        require(bounty.issuer != address(0), "DIM: Bounty not found"); // checks existence
        require(bounty.deadline > block.timestamp, "DIM: Bounty deadline passed");
        require(s_innovationUnits[_innovationId].isActive, "DIM: Submitted IU is not active");
        require(bounty.submitter != msg.sender, "DIM: You have already submitted to this bounty"); // Only one submission per creator

        bounty.submissionInnovationId = _innovationId;
        bounty.submitter = msg.sender;

        emit InnovationSubmittedToBounty(_bountyId, _innovationId, msg.sender);
    }

    // 21. `acceptBountySubmission`
    function acceptBountySubmission(uint256 _bountyId, uint256 _innovationId) external nonReentrant {
        InnovationBounty storage bounty = s_innovationBounties[_bountyId];
        require(bounty.issuer == msg.sender, "DIM: Only bounty issuer can accept submission");
        require(bounty.active, "DIM: Bounty is not active");
        require(bounty.issuer != address(0), "DIM: Bounty not found");
        require(bounty.submissionInnovationId == _innovationId, "DIM: Specified IU is not the accepted submission for this bounty");
        require(bounty.submitter != address(0), "DIM: No submission to accept");
        require(!bounty.claimed, "DIM: Bounty already claimed");

        bounty.claimed = true;
        bounty.active = false; // Deactivate the bounty after acceptance

        address creator = bounty.submitter;
        uint256 amount = bounty.bountyAmount;

        // The bounty funds are directly sent to the creator of the accepted IU,
        // subject to platform fees.
        uint256 platformFee = (amount * s_platformFeeBps) / 10000;
        uint256 creatorShare = amount - platformFee;

        s_totalPlatformFeesAccumulated += platformFee;
        s_creatorEarnings[creator] += creatorShare;

        // Creator will withdraw using `withdrawCreatorEarnings`

        emit BountySubmissionAccepted(_bountyId, _innovationId, creator, msg.sender, amount);
    }

    // X. Platform Administration & Utilities
    // 22. `setPlatformFee`
    function setPlatformFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "DIM: Fee BPS cannot exceed 100%"); // 10000 BPS = 100%
        uint256 oldFeeBps = s_platformFeeBps;
        s_platformFeeBps = _newFeeBps;
        emit PlatformFeeUpdated(oldFeeBps, _newFeeBps);
    }

    // 23. `updateArbitrators`
    function updateArbitrators(address[] calldata _newArbitrators) external onlyOwner {
        // Clear existing arbitrators in the mapping
        for (uint256 i = 0; i < _currentArbitrators.length; i++) {
            s_isArbitrator[_currentArbitrators[i]] = false;
        }
        
        // Clear the array of current arbitrators
        delete _currentArbitrators;

        // Add new arbitrators to both the mapping and the array
        for (uint256 i = 0; i < _newArbitrators.length; i++) {
            require(_newArbitrators[i] != address(0), "DIM: Arbitrator cannot be zero address");
            s_isArbitrator[_newArbitrators[i]] = true;
            _currentArbitrators.push(_newArbitrators[i]);
        }
        emit ArbitratorsUpdated(_newArbitrators);
    }

    // 24. `withdrawPlatformFees`
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = s_totalPlatformFeesAccumulated;
        require(amount > 0, "DIM: No platform fees to withdraw");
        s_totalPlatformFeesAccumulated = 0;

        (bool success, ) = i_owner.call{value: amount}("");
        require(success, "DIM: Failed to withdraw platform fees");

        emit PlatformFeesWithdrawn(amount);
    }

    // XI. Community Curation
    // 25. `rateInnovationUnit`
    function rateInnovationUnit(uint256 _innovationId, uint8 _rating) external nonReentrant {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");
        require(iu.isActive, "DIM: IU is not active");
        require(_rating >= 1 && _rating <= 5, "DIM: Rating must be between 1 and 5");
        require(!s_hasRated[msg.sender][_innovationId], "DIM: User has already rated this IU");

        iu.sumOfRatings += _rating;
        iu.totalRatings++;
        s_hasRated[msg.sender][_innovationId] = true;

        emit InnovationUnitRated(_innovationId, msg.sender, _rating);
    }

    // 26. `getAverageRating`
    function getAverageRating(uint256 _innovationId) external view returns (uint256) {
        InnovationUnit storage iu = s_innovationUnits[_innovationId];
        require(_innovationUnitExists(_innovationId), "DIM: IU does not exist");

        if (iu.totalRatings == 0) {
            return 0; // No ratings yet
        }
        return iu.sumOfRatings / iu.totalRatings;
    }

    // XII. Fallback Function
    // 27. `receive()`
    receive() external payable {
        revert("DIM: Direct Ether transfers not supported. Use specific functions.");
    }
}
```