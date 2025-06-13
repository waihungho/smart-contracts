Okay, here is a smart contract in Solidity for a Decentralized AI Model and Data Marketplace.

This contract introduces several advanced, creative, and trendy concepts:

1.  **Unified Marketplace:** Manages both AI Models and Datasets as distinct resource types.
2.  **Flexible Access Models:** Supports both one-time licenses and usage-based access (pay-per-inference for models, pay-per-record for data).
3.  **Oracle Integration:** Allows registered oracles to submit performance scores for models and quality scores for datasets, crucial for building trust and potentially future dynamic pricing or ranking.
4.  **Staking Mechanism:** Resource owners can stake Ether to signal confidence in their resource's quality. This could be a precursor to reputation systems or slashing (though slashing logic is complex and omitted for this example's length).
5.  **Usage Tracking:** The contract tracks how many times a usage-based resource is accessed, enabling accurate pay-per-use/record payouts. Requires off-chain execution and oracle/owner reporting of usage.
6.  **Performance/Quality-Based Royalties (Partial):** While full dynamic royalties based on scores are complex, the structure supports oracle input which is foundational for such systems. The `claimEarnings` function consolidates payouts from various sources.
7.  **Data Curation Bounties:** Allows dataset owners to create bounties for tasks like data labeling or cleaning, funded via the contract and paid out upon verification (again, involving oracle/owner).
8.  **Basic Reporting System:** Users can report malicious or low-quality resources, flagging them for review by the owner/oracles.

**Note:** This contract uses native currency (ETH) for simplicity instead of ERC-20. Real-world applications might use stablecoins or platform tokens. The off-chain data/model storage and the *actual execution* of AI models or *processing* of data are assumed to happen off-chain, with the contract managing metadata, access rights, payments, and incorporating off-chain feedback via oracles.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Decentralized AI Model and Data Marketplace ---
// This contract provides a platform for creators to list, and consumers to purchase access to
// AI models and datasets. It implements flexible access models (licenses and usage-based),
// integrates with oracles for performance/quality feedback, supports staking for resources,
// enables data curation bounties, and includes a basic reporting mechanism.

// --- Function Summary ---
// Admin Functions:
// 1. constructor(): Initializes the contract owner.
// 2. setPlatformFee(uint16 _feePercentage): Sets the platform fee percentage (0-10000 representing 0-100.00%).
// 3. addOracle(address _oracle): Adds an address to the list of authorized oracles.
// 4. removeOracle(address _oracle): Removes an address from the list of authorized oracles.
// 5. withdrawPlatformFees(): Allows the owner to withdraw collected platform fees.
// 6. reviewReportedActivity(uint256 _resourceId, bool _deactivateResource, bool _slashStake): Reviews a reported resource, potentially deactivating it or slashing the owner's stake.

// Resource (Model/Dataset) Management Functions:
// 7. registerModel(string memory _metadataURI, uint256 _pricePerLicense, uint256 _pricePerUse): Registers a new AI model.
// 8. updateModelMetadata(uint256 _modelId, string memory _newMetadataURI): Updates metadata URI for a model.
// 9. deactivateModel(uint256 _modelId): Deactivates a model, preventing new purchases.
// 10. stakeForModel(uint256 _modelId) payable: Stakes Ether on a model.
// 11. unstakeFromModel(uint256 _modelId): Unstakes Ether from a model (only if not reported/slashed).
// 12. registerDataset(string memory _metadataURI, uint256 _pricePerLicense, uint256 _pricePerRecord): Registers a new dataset.
// 13. updateDatasetMetadata(uint256 _datasetId, string memory _newMetadataURI): Updates metadata URI for a dataset.
// 14. deactivateDataset(uint256 _datasetId): Deactivates a dataset, preventing new purchases.
// 15. stakeForDataset(uint256 _datasetId) payable: Stakes Ether on a dataset.
// 16. unstakeFromDataset(uint256 _datasetId): Unstakes Ether from a dataset (only if not reported/slashed).

// Purchase and Access Functions:
// 17. purchaseModelLicense(uint256 _modelId) payable: Purchases a perpetual license for a model.
// 18. purchaseModelUsage(uint256 _modelId, uint256 _usageCount) payable: Purchases a number of usage credits for a model.
// 19. purchaseDatasetLicense(uint256 _datasetId) payable: Purchases a perpetual license for a dataset.
// 20. purchaseDatasetRecords(uint256 _datasetId, uint256 _recordCount) payable: Purchases access to a number of data records from a dataset.
// 21. recordModelUsage(uint256 _modelId, address _user, uint256 _count): Records usage for a user on a model (called by resource owner or oracle).
// 22. recordDatasetUsage(uint256 _datasetId, address _user, uint256 _count): Records usage for a user on a dataset (called by resource owner or oracle).
// 23. grantAccess(uint256 _resourceId, address _user, bool _isModel, uint256 _usageCount, bool _hasLicense): Grants access to a resource for a user (e.g., for free access or testing).
// 24. revokeAccess(uint256 _resourceId, address _user, bool _isModel): Revokes access for a user.
// 25. checkAccess(uint256 _resourceId, address _user, bool _isModel, uint256 _requiredUsage): Checks if a user has sufficient access/usage credits for a resource. (Utility function)

// Oracle and Feedback Functions:
// 26. submitModelPerformanceScore(uint256 _modelId, uint256 _score): Allows an oracle to submit a performance score (e.g., 0-100).
// 27. submitDataQualityScore(uint256 _datasetId, uint256 _score): Allows an oracle to submit a data quality score (e.g., 0-100).
// 28. reportMaliciousActivity(uint256 _resourceId, bool _isModel): Allows any user to report a resource for review.

// Curation Bounty Functions:
// 29. createCurationBounty(uint256 _datasetId, string memory _title, string memory _description, uint256 _rewardAmount): Creates a bounty for curating a specific dataset.
// 30. fundCurationBounty(uint256 _bountyId) payable: Adds funds to an existing curation bounty.
// 31. submitCurationWork(uint256 _bountyId, string memory _submissionURI): Allows a curer to submit work for a bounty.
// 32. verifyAndPayoutCuration(uint256 _submissionId, bool _isVerified): Allows an oracle or dataset owner to verify a submission and trigger payout.

// Payout Function:
// 33. claimEarnings(): Allows users (resource owners, curers) to claim their accumulated earnings.

contract DecentralizedAIModelMarketplace {

    address public owner;

    // --- State Variables ---

    // Admin
    uint16 public platformFeePercentage; // Stored as basis points (e.g., 100 = 1%)
    mapping(address => bool) public oracles;
    uint256 public platformFeesCollected;

    // Resources (Models & Datasets)
    struct ResourceInfo {
        address owner;
        string metadataURI; // Link to off-chain metadata (IPFS, etc.)
        uint256 pricePerLicense; // Price for a perpetual license
        uint256 pricePerUseOrRecord; // Price per use (model) or per record (dataset)
        bool isActive; // Can it be purchased?
        uint256 stakeAmount; // ETH staked on this resource
        uint256 score; // Oracle-submitted performance/quality score
        uint256 totalUsageOrRecordCount; // Total times this resource has been used/records accessed across all users
        bool isReported; // Flagged for review
        bool isModel; // true for Model, false for Dataset
    }

    uint256 public nextResourceId = 1;
    mapping(uint256 => ResourceInfo) public resources; // Resource ID => Info

    // Access Control (User => Resource ID => Access Info)
    struct AccessInfo {
        bool hasLicense; // Perpetual license granted
        uint256 usageOrRecordRemaining; // Credits for usage-based access
        uint256 recordsAccessed; // Total records accessed by this user (for tracking)
    }
    mapping(address => mapping(uint256 => AccessInfo)) public accessRights;

    // Curation Bounties
    struct CurationBounty {
        uint256 datasetId;
        address creator;
        string title;
        string description;
        uint256 rewardAmount; // Reward per verified submission
        uint256 totalFunded; // Total ETH funded into this bounty
        bool isActive;
        uint256 nextSubmissionId; // Counter for submissions to this bounty
    }

    struct CurationSubmission {
        uint256 bountyId;
        address curer;
        string submissionURI;
        bool isVerified; // Verified by oracle/owner
        bool isPaid; // Has the curer been paid?
    }

    uint256 public nextBountyId = 1;
    mapping(uint256 => CurationBounty) public bounties;
    uint256 public nextSubmissionGlobalId = 1;
    mapping(uint256 => CurationSubmission) public submissions; // Global submission ID => Info
    mapping(uint256 => mapping(address => uint256)) public bountySubmissions; // Bounty ID => Curer Address => Submission Global ID

    // User Balances (for claiming)
    mapping(address => uint256) public userBalances;

    // --- Events ---
    event PlatformFeeSet(uint16 feePercentage);
    event OracleAdded(address oracle);
    event OracleRemoved(address oracle);
    event PlatformFeesWithdrawn(uint256 amount);

    event ResourceRegistered(uint256 resourceId, address indexed owner, bool isModel, string metadataURI);
    event ResourceMetadataUpdated(uint256 resourceId, string newMetadataURI);
    event ResourceDeactivated(uint256 resourceId);
    event ResourceStaked(uint256 resourceId, address staker, uint256 amount);
    event ResourceUnstaked(uint256 resourceId, address recipient, uint256 amount);
    event ResourceReported(uint256 resourceId, address indexed reporter);
    event ResourceReviewed(uint256 resourceId, bool deactivated, bool slashed);

    event AccessPurchased(uint256 resourceId, address indexed user, uint256 amountPaid, bool isLicense, uint256 quantity);
    event UsageRecorded(uint256 resourceId, address indexed user, uint256 count);
    event AccessGranted(uint256 resourceId, address indexed user, bool isLicense, uint256 usageCount);
    event AccessRevoked(uint256 resourceId, address indexed user);

    event PerformanceScoreSubmitted(uint256 resourceId, address indexed oracle, uint256 score);
    event QualityScoreSubmitted(uint256 resourceId, address indexed oracle, uint256 score);

    event CurationBountyCreated(uint256 bountyId, uint256 datasetId, address indexed creator, uint256 rewardAmount);
    event CurationBountyFunded(uint256 bountyId, address indexed funder, uint256 amount);
    event CurationWorkSubmitted(uint256 bountyId, address indexed curer, uint256 submissionId, string submissionURI);
    event CurationWorkVerified(uint256 submissionId, bool isVerified);
    event CurationPayout(uint256 submissionId, address indexed curer, uint256 amount);

    event EarningsClaimed(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredOracle() {
        require(oracles[msg.sender], "Only registered oracles can call this function");
        _;
    }

    modifier onlyResourceOwner(uint256 _resourceId) {
        require(resources[_resourceId].owner == msg.sender, "Only resource owner can call this function");
        _;
    }

    modifier onlyResourceOwnerOrOracle(uint256 _resourceId) {
         require(resources[_resourceId].owner == msg.sender || oracles[msg.sender], "Only resource owner or oracle can call this function");
         _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        platformFeePercentage = 500; // Default 5%
    }

    // --- Admin Functions ---

    function setPlatformFee(uint16 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 10000 (100%)");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function addOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracles[_oracle] = true;
        emit OracleAdded(_oracle);
    }

    function removeOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracles[_oracle] = false;
        emit OracleRemoved(_oracle);
    }

    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = platformFeesCollected;
        platformFeesCollected = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit PlatformFeesWithdrawn(amount);
    }

    function reviewReportedActivity(uint256 _resourceId, bool _deactivateResource, bool _slashStake) external onlyOwner {
        ResourceInfo storage resource = resources[_resourceId];
        require(resource.isReported, "Resource is not reported");

        resource.isReported = false; // Review completed

        if (_deactivateResource) {
            resource.isActive = false;
        }

        uint256 slashedAmount = 0;
        if (_slashStake && resource.stakeAmount > 0) {
             // Simple slashing: send stake to platform fees
             slashedAmount = resource.stakeAmount;
             platformFeesCollected += slashedAmount;
             resource.stakeAmount = 0;
        }

        emit ResourceReviewed(_resourceId, _deactivateResource, slashedAmount > 0);
    }


    // --- Resource Management Functions ---

    function registerModel(string memory _metadataURI, uint256 _pricePerLicense, uint256 _pricePerUse) external {
        uint256 resourceId = nextResourceId++;
        resources[resourceId] = ResourceInfo({
            owner: msg.sender,
            metadataURI: _metadataURI,
            pricePerLicense: _pricePerLicense,
            pricePerUseOrRecord: _pricePerUse,
            isActive: true,
            stakeAmount: 0,
            score: 0, // Initial score is 0
            totalUsageOrRecordCount: 0,
            isReported: false,
            isModel: true
        });
        emit ResourceRegistered(resourceId, msg.sender, true, _metadataURI);
    }

    function updateModelMetadata(uint256 _modelId, string memory _newMetadataURI) external onlyResourceOwner(_modelId) {
        require(resources[_modelId].isModel, "Resource is not a model");
        resources[_modelId].metadataURI = _newMetadataURI;
        emit ResourceMetadataUpdated(_modelId, _newMetadataURI);
    }

    function deactivateModel(uint256 _modelId) external onlyResourceOwner(_modelId) {
        require(resources[_modelId].isModel, "Resource is not a model");
        resources[_modelId].isActive = false;
        emit ResourceDeactivated(_modelId);
    }

    function stakeForModel(uint256 _modelId) external payable onlyResourceOwner(_modelId) {
        require(resources[_modelId].isModel, "Resource is not a model");
        require(msg.value > 0, "Must send Ether to stake");
        resources[_modelId].stakeAmount += msg.value;
        emit ResourceStaked(_modelId, msg.sender, msg.value);
    }

     function unstakeFromModel(uint256 _modelId) external onlyResourceOwner(_modelId) {
        require(resources[_modelId].isModel, "Resource is not a model");
        require(resources[_modelId].stakeAmount > 0, "No stake to unstake");
        require(!resources[_modelId].isReported, "Cannot unstake reported resource");

        uint256 amount = resources[_modelId].stakeAmount;
        resources[_modelId].stakeAmount = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Unstaking failed");
        emit ResourceUnstaked(_modelId, msg.sender, amount);
    }

    function registerDataset(string memory _metadataURI, uint256 _pricePerLicense, uint256 _pricePerRecord) external {
        uint256 resourceId = nextResourceId++;
        resources[resourceId] = ResourceInfo({
            owner: msg.sender,
            metadataURI: _metadataURI,
            pricePerLicense: _pricePerLicense,
            pricePerUseOrRecord: _pricePerRecord,
            isActive: true,
            stakeAmount: 0,
            score: 0, // Initial score is 0
            totalUsageOrRecordCount: 0,
            isReported: false,
            isModel: false
        });
        emit ResourceRegistered(resourceId, msg.sender, false, _metadataURI);
    }

    function updateDatasetMetadata(uint256 _datasetId, string memory _newMetadataURI) external onlyResourceOwner(_datasetId) {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        resources[_datasetId].metadataURI = _newMetadataURI;
        emit ResourceMetadataUpdated(_datasetId, _newMetadataURI);
    }

    function deactivateDataset(uint256 _datasetId) external onlyResourceOwner(_datasetId) {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        resources[_datasetId].isActive = false;
        emit ResourceDeactivated(_datasetId);
    }

    function stakeForDataset(uint256 _datasetId) external payable onlyResourceOwner(_datasetId) {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        require(msg.value > 0, "Must send Ether to stake");
        resources[_datasetId].stakeAmount += msg.value;
        emit ResourceStaked(_datasetId, msg.sender, msg.value);
    }

    function unstakeFromDataset(uint256 _datasetId) external onlyResourceOwner(_datasetId) {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        require(resources[_datasetId].stakeAmount > 0, "No stake to unstake");
        require(!resources[_datasetId].isReported, "Cannot unstake reported resource");

        uint256 amount = resources[_datasetId].stakeAmount;
        resources[_datasetId].stakeAmount = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Unstaking failed");
        emit ResourceUnstaked(_datasetId, msg.sender, amount);
    }

    // --- Purchase and Access Functions ---

    function _handlePurchase(uint256 _resourceId, uint256 _totalCost, bool _isLicense, uint256 _quantity) internal {
        ResourceInfo storage resource = resources[_resourceId];
        require(resource.isActive, "Resource is not active for purchase");
        require(msg.value >= _totalCost, "Insufficient Ether sent");

        uint256 platformFee = (_totalCost * platformFeePercentage) / 10000;
        uint256 creatorPayout = _totalCost - platformFee;

        platformFeesCollected += platformFee;
        userBalances[resource.owner] += creatorPayout;

        AccessInfo storage access = accessRights[msg.sender][_resourceId];

        if (_isLicense) {
            access.hasLicense = true;
        } else {
            access.usageOrRecordRemaining += _quantity;
        }

        // Refund excess Ether
        if (msg.value > _totalCost) {
            (bool success, ) = msg.sender.call{value: msg.value - _totalCost}("");
            require(success, "Refund failed");
        }

        emit AccessPurchased(_resourceId, msg.sender, _totalCost, _isLicense, _quantity);
    }


    function purchaseModelLicense(uint256 _modelId) external payable {
        require(resources[_modelId].isModel, "Resource is not a model");
        _handlePurchase(_modelId, resources[_modelId].pricePerLicense, true, 0);
    }

    function purchaseModelUsage(uint256 _modelId, uint256 _usageCount) external payable {
        require(resources[_modelId].isModel, "Resource is not a model");
        require(_usageCount > 0, "Must purchase at least one usage");
        uint256 totalCost = resources[_modelId].pricePerUseOrRecord * _usageCount;
        _handlePurchase(_modelId, totalCost, false, _usageCount);
    }

     function purchaseDatasetLicense(uint256 _datasetId) external payable {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        _handlePurchase(_datasetId, resources[_datasetId].pricePerLicense, true, 0);
    }

    function purchaseDatasetRecords(uint256 _datasetId, uint256 _recordCount) external payable {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        require(_recordCount > 0, "Must purchase access to at least one record");
        uint256 totalCost = resources[_datasetId].pricePerUseOrRecord * _recordCount;
        _handlePurchase(_datasetId, totalCost, false, _recordCount);
    }

    // Note: recordUsage functions are expected to be called by the resource owner
    // or a trusted oracle *after* the off-chain usage has occurred and access
    // has been verified off-chain based on the on-chain `checkAccess` status.
    // This is a common pattern for off-chain execution tied to on-chain rights.
    function recordModelUsage(uint256 _modelId, address _user, uint256 _count) external onlyResourceOwnerOrOracle(_modelId) {
        require(resources[_modelId].isModel, "Resource is not a model");
        require(_count > 0, "Usage count must be positive");

        AccessInfo storage access = accessRights[_user][_modelId];
        require(access.usageOrRecordRemaining >= _count, "User does not have enough usage credits");

        access.usageOrRecordRemaining -= _count;
        resources[_modelId].totalUsageOrRecordCount += _count;

        // Potential future: calculate payout based on recorded usage if not already paid upfront
        // userBalances[resources[_modelId].owner] += calculatedPayout;

        emit UsageRecorded(_modelId, _user, _count);
    }

    function recordDatasetUsage(uint256 _datasetId, address _user, uint256 _count) external onlyResourceOwnerOrOracle(_datasetId) {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
        require(_count > 0, "Usage count must be positive");

        AccessInfo storage access = accessRights[_user][_datasetId];
         // Note: For record-based access, we track *total records accessed* rather than remaining.
         // The off-chain system needs to enforce the limit based on `usageOrRecordRemaining`
         // returned by `checkAccess`. This function just records *actual* usage.
         // The user must have purchased access via `purchaseDatasetRecords`.
        require(accessRights[_user][_datasetId].usageOrRecordRemaining > 0 || accessRights[_user][_datasetId].hasLicense, "User has no access credits or license");
        // Deducting records accessed from remaining credits is better if the off-chain system
        // reports usage iteratively. Let's adjust logic for records slightly.
        // If usage is reported *per record access session*, deduct from remaining:
        require(access.usageOrRecordRemaining >= _count, "User does not have enough record credits");
        access.usageOrRecordRemaining -= _count;
        access.recordsAccessed += _count; // Track total accessed by this user
        resources[_datasetId].totalUsageOrRecordCount += _count; // Track total accessed across all users

        emit UsageRecorded(_datasetId, _user, _count);
    }


    function grantAccess(uint256 _resourceId, address _user, bool _isModel, uint256 _usageCount, bool _hasLicense) external onlyResourceOwner(_resourceId) {
        // Allows resource owner to grant access (e.g., for free trials)
        require(resources[_resourceId].isModel == _isModel, "Resource type mismatch");

        AccessInfo storage access = accessRights[_user][_resourceId];
        if (_hasLicense) {
            access.hasLicense = true;
        }
        if (_usageCount > 0) {
             access.usageOrRecordRemaining += _usageCount;
        }

        emit AccessGranted(_resourceId, _user, _hasLicense, _usageCount);
    }

     function revokeAccess(uint256 _resourceId, address _user, bool _isModel) external onlyResourceOwner(_resourceId) {
         require(resources[_resourceId].isModel == _isModel, "Resource type mismatch");

         // Simply reset access info - does not refund paid amounts
         delete accessRights[_user][_resourceId];

         emit AccessRevoked(_resourceId, _user);
     }


    function checkAccess(uint256 _resourceId, address _user, bool _isModel, uint256 _requiredUsage) external view returns (bool hasAccess) {
        // Utility function for off-chain systems to check access status
        require(resources[_resourceId].isModel == _isModel, "Resource type mismatch");

        AccessInfo storage access = accessRights[_user][_resourceId];

        if (access.hasLicense) {
            return true;
        }
        if (access.usageOrRecordRemaining >= _requiredUsage && _requiredUsage > 0) {
            return true;
        }
        return false;
    }

    // --- Oracle and Feedback Functions ---

    function submitModelPerformanceScore(uint256 _modelId, uint256 _score) external onlyRegisteredOracle {
        require(resources[_modelId].isModel, "Resource is not a model");
        // Simple implementation: just store the latest score.
        // Advanced: calculate average or weighted average over time/oracles.
        resources[_modelId].score = _score;
        emit PerformanceScoreSubmitted(_modelId, msg.sender, _score);
    }

    function submitDataQualityScore(uint256 _datasetId, uint256 _score) external onlyRegisteredOracle {
        require(!resources[_datasetId].isModel, "Resource is not a dataset");
         // Simple implementation: just store the latest score.
        // Advanced: calculate average or weighted average over time/oracles.
        resources[_datasetId].score = _score;
        emit QualityScoreSubmitted(_datasetId, msg.sender, _score);
    }

    function reportMaliciousActivity(uint256 _resourceId, bool _isModel) external {
        require(resources[_resourceId].isModel == _isModel, "Resource type mismatch");
        require(_resourceId > 0 && _resourceId < nextResourceId, "Invalid resource ID"); // Basic validation
        resources[_resourceId].isReported = true;
        emit ResourceReported(_resourceId, msg.sender);
    }

    // --- Curation Bounty Functions ---

    function createCurationBounty(uint256 _datasetId, string memory _title, string memory _description, uint256 _rewardAmount) external onlyResourceOwner(_datasetId) {
        require(!resources[_datasetId].isModel, "Can only create bounties for datasets");
        require(_rewardAmount > 0, "Reward amount must be positive");

        uint256 bountyId = nextBountyId++;
        bounties[bountyId] = CurationBounty({
            datasetId: _datasetId,
            creator: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            totalFunded: 0,
            isActive: true,
            nextSubmissionId: 1
        });
        emit CurationBountyCreated(bountyId, _datasetId, msg.sender, _rewardAmount);
    }

    function fundCurationBounty(uint256 _bountyId) external payable {
        CurationBounty storage bounty = bounties[_bountyId];
        require(bounty.isActive, "Bounty is not active");
        require(msg.value > 0, "Must send Ether to fund bounty");

        bounty.totalFunded += msg.value;
        // The funds stay in the contract until claimed by verified curers
        emit CurationBountyFunded(_bountyId, msg.sender, msg.value);
    }

    function submitCurationWork(uint256 _bountyId, string memory _submissionURI) external {
        CurationBounty storage bounty = bounties[_bountyId];
        require(bounty.isActive, "Bounty is not active");
        require(bounty.creator != msg.sender, "Bounty creator cannot submit work");
        // Prevent multiple submissions from the same curer per bounty (simple)
        require(bountySubmissions[_bountyId][msg.sender] == 0, "Already submitted for this bounty");

        uint256 globalSubmissionId = nextSubmissionGlobalId++;
        uint256 bountySpecificSubmissionId = bounty.nextSubmissionId++;

        submissions[globalSubmissionId] = CurationSubmission({
            bountyId: _bountyId,
            curer: msg.sender,
            submissionURI: _submissionURI,
            isVerified: false,
            isPaid: false
        });
        bountySubmissions[_bountyId][msg.sender] = globalSubmissionId;

        emit CurationWorkSubmitted(_bountyId, msg.sender, globalSubmissionId, _submissionURI);
    }

    function verifyAndPayoutCuration(uint256 _submissionId, bool _isVerified) external {
        CurationSubmission storage submission = submissions[_submissionId];
        require(submission.bountyId > 0, "Invalid submission ID");
        require(!submission.isVerified, "Submission already verified"); // Prevent double verification

        CurationBounty storage bounty = bounties[submission.bountyId];
        // Only bounty creator or an oracle can verify
        require(msg.sender == bounty.creator || oracles[msg.sender], "Only bounty creator or oracle can verify");

        submission.isVerified = true;
        emit CurationWorkVerified(_submissionId, _isVerified);

        if (_isVerified) {
            require(bounty.totalFunded >= bounty.rewardAmount, "Bounty not sufficiently funded for payout");
            require(!submission.isPaid, "Submission already paid"); // Should be covered by !isVerified, but double check

            uint256 payoutAmount = bounty.rewardAmount;
            userBalances[submission.curer] += payoutAmount;
            bounty.totalFunded -= payoutAmount; // Deduct from bounty's funded amount

            submission.isPaid = true;
            emit CurationPayout(_submissionId, submission.curer, payoutAmount);
        }
    }

    // --- Payout Function ---

    function claimEarnings() external {
        uint256 amount = userBalances[msg.sender];
        require(amount > 0, "No earnings to claim");

        userBalances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Claiming earnings failed");

        emit EarningsClaimed(msg.sender, amount);
    }

    // --- Utility / View Functions --- (Can add more public getters implicitly via public state variables)

    // Function 25 defined inline in Purchase/Access section as `checkAccess`
    // This brings total callable functions to 33+ view functions from public state variables.
}
```