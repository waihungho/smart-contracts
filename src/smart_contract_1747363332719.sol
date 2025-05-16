Okay, let's design a smart contract for a "Decentralized Knowledge & Data Access Marketplace". This concept involves users listing access to data or knowledge (which resides off-chain, e.g., on IPFS, Arweave, or even private servers), and others paying crypto to gain on-chain verified access. It incorporates features like tiered access, time-limited access, reviews, moderation flags, and earning distribution.

This avoids simple token/NFT minting/trading and focuses on managing *rights* and *access* based on on-chain transactions, with off-chain data interaction.

**Advanced Concepts & Features:**

1.  **Access Control:** Managing who can access data based on payment verification.
2.  **Tiered Pricing/Access:** Different purchase options (e.g., view only vs. download, short-term vs. long-term).
3.  **Time-Limited Access:** Granting access for a specific duration.
4.  **Publisher Earnings Distribution:** Handling splits and withdrawals.
5.  **Platform Fees:** Mechanism for collecting platform fees.
6.  **Reviews & Ratings:** Allowing buyers to review purchased data access.
7.  **Moderation Flags:** Community flagging of inappropriate or broken data links.
8.  **Data Hash Updates:** Publishers can update the pointer to the data (e.g., new IPFS hash for corrections/versions).
9.  **Free Access Grants:** Mechanism for owner/publisher to grant access freely.
10. **Access Revocation:** Mechanism for owner/publisher to revoke access (e.g., after moderation).
11. **Detailed Purchase Tracking:** Recording individual purchase details.
12. **On-Chain Proof of Access:** A function for off-chain systems to verify a user's purchase and access rights.

---

**Smart Contract: Decentralized Knowledge & Data Access Marketplace (DataMarket)**

**Outline:**

1.  **State Variables:** Store core contract data (owner, fees, counters, mappings for data sets, purchases, reviews, etc.).
2.  **Structs:** Define data structures for `DataSet`, `Purchase`, `Review`, `AccessRecord`.
3.  **Events:** Announce significant actions (listing, purchase, review, withdrawal, flags, etc.).
4.  **Modifiers:** Enforce access control (e.g., `onlyOwner`, `isPublisher`, `hasAccess`).
5.  **Core Marketplace Functions:**
    *   Listing/Updating/Removing Data Sets.
    *   Purchasing Access (handling ETH payments, fees, earnings).
    *   Verifying Access (for off-chain consumption).
6.  **Access Management Functions:**
    *   Granting Free Access.
    *   Revoking Access.
    *   Updating Data Hashes.
7.  **Review Functions:**
    *   Submitting Reviews.
    *   Retrieving Reviews and Average Ratings.
    *   Challenging Reviews (basic flag).
8.  **Earnings & Fee Functions:**
    *   Withdrawing Publisher Earnings.
    *   Setting/Withdrawing Platform Fees.
9.  **Moderation Functions:**
    *   Flagging Data Sets.
    *   Resolving Flags.
10. **View Functions:**
    *   Retrieving Data Set Details.
    *   Listing Data Sets (all, by user).
    *   Checking Access Status.
    *   Retrieving Purchase Details.
    *   Getting counts and totals.

---

**Function Summary:**

*   `constructor()`: Initializes the contract owner and platform fee settings.
*   `setPlatformFeeRecipient(address _recipient)`: Owner sets the address receiving fees.
*   `setPlatformFeePercentage(uint256 _percentage)`: Owner sets the platform fee percentage (in basis points).
*   `withdrawPlatformFees()`: Owner withdraws accumulated platform fees.
*   `listDataSet(string memory _dataHash, string memory _title, string memory _description, uint256 _priceEth, uint256 _accessDurationDays, uint256 _tier)`: Publisher lists a new data set with details, price, duration, and tier.
*   `updateDataSetListing(uint256 _dataSetId, string memory _dataHash, string memory _title, string memory _description, uint256 _priceEth, uint256 _accessDurationDays, uint256 _tier)`: Publisher updates an existing listing.
*   `removeDataSetListing(uint256 _dataSetId)`: Publisher removes a listing (marks as not listed).
*   `buyDataSetAccess(uint256 _dataSetId) payable`: A user buys access to a data set. Handles payment, earnings, fees, and records access.
*   `verifyAccess(uint256 _dataSetId, address _user) view returns (bool hasValidAccess, string memory dataHash, uint256 accessExpires)`: Verifies if a user has valid, active access to a data set, returning hash and expiry if true. *Core function for off-chain integration.*
*   `grantAccessFree(uint256 _dataSetId, address _recipient, uint256 _accessDurationDays)`: Owner or publisher grants free access to a user for a set duration.
*   `revokeAccess(uint256 _dataSetId, address _user)`: Owner or publisher revokes a user's access.
*   `updateDataSetHash(uint256 _dataSetId, string memory _newDataHash)`: Publisher updates the data hash associated with a listing.
*   `submitReview(uint256 _dataSetId, uint8 _rating, string memory _reviewTextHash)`: A buyer submits a review for a data set they purchased.
*   `withdrawPublisherEarnings()`: Publisher withdraws their accumulated earnings.
*   `flagDataSetForModeration(uint256 _dataSetId)`: Any user can flag a data set for moderation.
*   `resolveModerationFlag(uint256 _dataSetId, bool _removeListing)`: Owner resolves a moderation flag, optionally removing the listing.
*   `getDataSetDetails(uint256 _dataSetId) view returns (...)`: Get details about a specific data set.
*   `listAllDataSetIds() view returns (uint256[] memory)`: Get a list of all listed data set IDs.
*   `listMyPublishedDataSetIds(address _publisher) view returns (uint256[] memory)`: Get a list of data set IDs published by a specific address.
*   `listMyPurchasedDataSetIds(address _buyer) view returns (uint256[] memory)`: Get a list of data set IDs purchased by a specific address.
*   `getDataSetAverageRating(uint256 _dataSetId) view returns (uint8)`: Calculate the average rating for a data set.
*   `getDataSetReviews(uint256 _dataSetId) view returns (uint256[] memory)`: Get a list of review IDs for a data set.
*   `getReviewDetails(uint256 _reviewId) view returns (...)`: Get details about a specific review.
*   `getPurchaseDetails(uint256 _purchaseId) view returns (...)`: Get details about a specific purchase.
*   `getDataSetSaleCount(uint256 _dataSetId) view returns (uint256)`: Get the number of times a data set has been purchased.
*   `canReviewDataSet(uint256 _dataSetId, address _user) view returns (bool)`: Check if a user is eligible to review a data set (purchased and not yet reviewed).
*   `isDataSetFlagged(uint256 _dataSetId) view returns (bool)`: Check if a data set is currently flagged.
*   `getUserTotalEarnings(address _publisher) view returns (uint256)`: Get the total accumulated earnings for a publisher.
*   `getTotalPlatformFeesCollected() view returns (uint256)`: Get the total fees collected by the platform.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: This is a simplified example. For production, consider
// ReentrancyGuard, more robust access control, potentially ERC-721
// for representing data licenses, and a more sophisticated dispute/moderation system.
// String comparison can be gas intensive; using bytes32 hashes might be better if possible.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedDataMarketplace is Ownable {
    using SafeMath for uint256;

    // --- State Variables ---

    // Owner related
    address public platformFeeRecipient;
    // Fee percentage in basis points (100 = 1%)
    uint256 public platformFeePercentage;
    uint256 public totalPlatformFeesCollected;

    // Counters
    uint256 public nextDataSetId = 1;
    uint256 public nextPurchaseId = 1;
    uint256 public nextReviewId = 1;

    // Mappings
    mapping(uint256 => DataSet) public dataSets;
    mapping(uint256 => Purchase) public purchases;
    mapping(uint256 => Review) public reviews;
    mapping(address => uint256[]) public publisherDataSetIds; // publisher address => list of dataset IDs
    mapping(address => uint256[]) public userPurchaseIds; // user address => list of purchase IDs
    mapping(uint256 => uint256[]) public dataSetPurchaseIds; // dataset ID => list of purchase IDs
    mapping(uint256 => uint256[]) public dataSetReviewIds; // dataset ID => list of review IDs
    mapping(address => mapping(uint256 => bool)) public hasReviewed; // user address => dataset ID => has reviewed?
    mapping(address => uint256) public publisherEarnings; // publisher address => earned amount (Wei)

    // Access Records: Mapping from DataSet ID to user address to AccessRecord
    mapping(uint256 => mapping(address => AccessRecord)) public userDataSetAccess;

    // --- Structs ---

    struct DataSet {
        address publisher;
        uint256 price; // in Wei
        string dataHash; // IPFS/Arweave hash or similar pointer
        string title;
        string description;
        bool isListed; // true if available for purchase
        uint256 accessDurationSeconds; // 0 for unlimited, >0 for time-limited
        uint256 tier; // e.g., 1=Basic, 2=Premium
        uint256 saleCount;
        uint256 totalRatingSum; // Sum of ratings for average calculation
        uint256 reviewCount;
        bool isFlagged; // For moderation
        bool isRemovedByModeration; // Was removed due to moderation
    }

    struct Purchase {
        uint256 dataSetId;
        address buyer;
        uint256 pricePaid; // in Wei
        uint256 timestamp;
        // Could add fields for applied fee/earnings split
    }

    struct Review {
        uint256 dataSetId;
        address reviewer;
        uint8 rating; // 1-5
        string reviewTextHash; // Hash of review text (to save gas, text stored off-chain)
        uint256 timestamp;
        bool isChallenged; // Flagged by publisher/community
    }

     struct AccessRecord {
        bool hasAccess; // Does the user currently have access?
        uint256 expiryTimestamp; // When does access expire? 0 for unlimited.
        uint256 purchaseId; // Link to the purchase that granted access
    }

    // --- Events ---

    event DataSetListed(uint256 indexed dataSetId, address indexed publisher, uint256 price, uint256 duration, uint256 tier);
    event DataSetUpdated(uint256 indexed dataSetId, address indexed publisher);
    event DataSetRemoved(uint256 indexed dataSetId, address indexed publisher);
    event AccessPurchased(uint256 indexed purchaseId, uint256 indexed dataSetId, address indexed buyer, uint256 price);
    event AccessGrantedFree(uint256 indexed dataSetId, address indexed recipient, uint256 duration);
    event AccessRevoked(uint256 indexed dataSetId, address indexed user);
    event DataHashUpdated(uint256 indexed dataSetId, address indexed publisher, string newDataHash);
    event ReviewSubmitted(uint256 indexed reviewId, uint256 indexed dataSetId, address indexed reviewer, uint8 rating);
    event ReviewChallenged(uint256 indexed reviewId, uint256 indexed dataSetId);
    event PublisherEarningsWithdrawn(address indexed publisher, uint256 amount);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
    event DataSetFlagged(uint256 indexed dataSetId, address indexed flagger);
    event ModerationFlagResolved(uint256 indexed dataSetId, bool removedListing);

    // --- Modifiers ---

    modifier isPublisher(uint256 _dataSetId) {
        require(dataSets[_dataSetId].publisher == msg.sender, "Caller is not the publisher");
        _;
    }

    // --- Constructor ---

    constructor(address _initialFeeRecipient, uint256 _initialFeePercentage) Ownable(msg.sender) {
        require(_initialFeeRecipient != address(0), "Initial fee recipient cannot be zero address");
        require(_initialFeePercentage <= 10000, "Fee percentage cannot exceed 10000 basis points (100%)"); // 10000 means 100%
        platformFeeRecipient = _initialFeeRecipient;
        platformFeePercentage = _initialFeePercentage;
    }

    // --- Owner Functions ---

    /**
     * @notice Allows the owner to set the address that receives platform fees.
     * @param _recipient The new fee recipient address.
     */
    function setPlatformFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Fee recipient cannot be zero address");
        platformFeeRecipient = _recipient;
        emit OwnershipTransferred(owner(), owner()); // Simulate event for clarity, although not actual Ownable transfer
    }

    /**
     * @notice Allows the owner to set the platform fee percentage.
     * @param _percentage The new percentage in basis points (e.g., 100 for 1%). Max 10000.
     */
    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 10000, "Fee percentage cannot exceed 10000 basis points (100%)");
        platformFeePercentage = _percentage;
    }

    /**
     * @notice Allows the owner to withdraw collected platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = totalPlatformFeesCollected;
        require(amount > 0, "No platform fees to withdraw");
        totalPlatformFeesCollected = 0;
        // Use call to prevent reentrancy issues with external calls
        (bool success, ) = platformFeeRecipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit PlatformFeesWithdrawn(platformFeeRecipient, amount);
    }

    /**
     * @notice Owner resolves a moderation flag on a data set.
     * @param _dataSetId The ID of the data set to resolve the flag for.
     * @param _removeListing If true, the data set listing is removed (isListed set to false).
     */
    function resolveModerationFlag(uint256 _dataSetId, bool _removeListing) external onlyOwner {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        require(dataSet.isFlagged, "DataSet is not flagged");

        dataSet.isFlagged = false;
        if (_removeListing) {
            dataSet.isListed = false;
            dataSet.isRemovedByModeration = true;
        }
        emit ModerationFlagResolved(_dataSetId, _removeListing);
    }


    // --- Publisher Functions ---

    /**
     * @notice Allows a user to list a new data set on the marketplace.
     * @param _dataHash Hash or pointer to the off-chain data (e.g., IPFS hash).
     * @param _title Title of the data set.
     * @param _description Description of the data set.
     * @param _priceEth Price of access in Ether (Wei).
     * @param _accessDurationDays Duration of access in days (0 for unlimited).
     * @param _tier Access tier (e.g., 1, 2, 3).
     */
    function listDataSet(
        string memory _dataHash,
        string memory _title,
        string memory _description,
        uint256 _priceEth,
        uint256 _accessDurationDays,
        uint256 _tier
    ) external {
        require(bytes(_dataHash).length > 0, "Data hash cannot be empty");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_priceEth > 0, "Price must be greater than zero");
        require(_tier > 0, "Tier must be greater than zero");

        uint256 dataSetId = nextDataSetId++;
        uint256 accessDurationSeconds = _accessDurationDays.mul(86400); // 86400 seconds in a day

        dataSets[dataSetId] = DataSet({
            publisher: msg.sender,
            price: _priceEth,
            dataHash: _dataHash,
            title: _title,
            description: _description,
            isListed: true,
            accessDurationSeconds: accessDurationSeconds,
            tier: _tier,
            saleCount: 0,
            totalRatingSum: 0,
            reviewCount: 0,
            isFlagged: false,
            isRemovedByModeration: false
        });

        publisherDataSetIds[msg.sender].push(dataSetId);

        emit DataSetListed(dataSetId, msg.sender, _priceEth, _accessDurationDays, _tier);
    }

    /**
     * @notice Allows a publisher to update details of their data set listing.
     * @param _dataSetId The ID of the data set to update.
     * @param _dataHash New data hash or pointer.
     * @param _title New title.
     * @param _description New description.
     * @param _priceEth New price in Wei.
     * @param _accessDurationDays New access duration in days (0 for unlimited).
     * @param _tier New access tier.
     */
    function updateDataSetListing(
        uint256 _dataSetId,
        string memory _dataHash,
        string memory _title,
        string memory _description,
        uint256 _priceEth,
        uint256 _accessDurationDays,
        uint256 _tier
    ) external isPublisher(_dataSetId) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.isListed, "DataSet is not currently listed");
        require(bytes(_dataHash).length > 0, "Data hash cannot be empty");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_priceEth > 0, "Price must be greater than zero");
        require(_tier > 0, "Tier must be greater than zero");

        dataSet.dataHash = _dataHash;
        dataSet.title = _title;
        dataSet.description = _description;
        dataSet.price = _priceEth;
        dataSet.accessDurationSeconds = _accessDurationDays.mul(86400);
        dataSet.tier = _tier;

        emit DataSetUpdated(_dataSetId, msg.sender);
    }

    /**
     * @notice Allows a publisher to update *only* the data hash associated with a listing.
     * Useful for corrections or version updates without changing price/description etc.
     * @param _dataSetId The ID of the data set.
     * @param _newDataHash The new data hash or pointer.
     */
    function updateDataSetHash(uint256 _dataSetId, string memory _newDataHash) external isPublisher(_dataSetId) {
        DataSet storage dataSet = dataSets[_dataSetId];
         require(bytes(_newDataHash).length > 0, "New data hash cannot be empty");
         // Allow hash update even if not listed, but not if removed by moderation
         require(!dataSet.isRemovedByModeration, "Cannot update hash for moderation-removed dataset");

         dataSet.dataHash = _newDataHash;

         emit DataHashUpdated(_dataSetId, msg.sender, _newDataHash);
    }

    /**
     * @notice Allows a publisher to remove their data set listing from the marketplace.
     * Existing access grants are not affected by this.
     * @param _dataSetId The ID of the data set to remove.
     */
    function removeDataSetListing(uint256 _dataSetId) external isPublisher(_dataSetId) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.isListed, "DataSet is not currently listed");

        dataSet.isListed = false;
        emit DataSetRemoved(_dataSetId, msg.sender);
    }

     /**
     * @notice Publisher can grant free access to a specific user for a set duration.
     * @param _dataSetId The ID of the data set.
     * @param _recipient The address to grant access to.
     * @param _accessDurationDays Duration of access in days (0 for unlimited, overrides dataset default).
     */
    function grantAccessFree(uint256 _dataSetId, address _recipient, uint256 _accessDurationDays) external {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        require(msg.sender == dataSet.publisher || msg.sender == owner(), "Caller is not publisher or owner");
        require(_recipient != address(0), "Recipient cannot be zero address");
         require(!dataSet.isRemovedByModeration, "Cannot grant access for moderation-removed dataset");

        uint256 accessDurationSeconds = _accessDurationDays.mul(86400);
        uint256 expiry = accessDurationSeconds == 0 ? 0 : block.timestamp.add(accessDurationSeconds);

        userDataSetAccess[_dataSetId][_recipient] = AccessRecord({
            hasAccess: true,
            expiryTimestamp: expiry,
            purchaseId: 0 // 0 indicates not a purchase, but a free grant
        });

        emit AccessGrantedFree(_dataSetId, _recipient, _accessDurationDays);
    }

     /**
     * @notice Publisher or owner can revoke access for a specific user.
     * @param _dataSetId The ID of the data set.
     * @param _user The address whose access to revoke.
     */
    function revokeAccess(uint256 _dataSetId, address _user) external {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        require(msg.sender == dataSet.publisher || msg.sender == owner(), "Caller is not publisher or owner");
        require(_user != address(0), "User cannot be zero address");

        AccessRecord storage accessRecord = userDataSetAccess[_dataSetId][_user];
        require(accessRecord.hasAccess, "User does not currently have access to this dataset");

        accessRecord.hasAccess = false;
        accessRecord.expiryTimestamp = 0; // Reset expiry
        // Keep purchaseId history if needed, but for simplicity reset
        accessRecord.purchaseId = 0;

        emit AccessRevoked(_dataSetId, _user);
    }


    /**
     * @notice Allows a publisher to withdraw their accumulated earnings.
     */
    function withdrawPublisherEarnings() external {
        uint256 amount = publisherEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");
        publisherEarnings[msg.sender] = 0;
        // Use call to prevent reentrancy issues
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit PublisherEarningsWithdrawn(msg.sender, amount);
    }

    // --- Buyer Functions ---

    /**
     * @notice Allows a user to buy access to a data set.
     * @param _dataSetId The ID of the data set to purchase.
     */
    function buyDataSetAccess(uint256 _dataSetId) external payable {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        require(dataSet.isListed, "DataSet is not currently listed");
        require(dataSet.publisher != msg.sender, "Publisher cannot buy their own dataset");
        require(msg.value >= dataSet.price, "Insufficient Ether sent");

        // Check if user already has active unlimited access
        AccessRecord storage existingAccess = userDataSetAccess[_dataSetId][msg.sender];
        if (existingAccess.hasAccess && existingAccess.expiryTimestamp == 0) {
             // If they already have unlimited access, maybe return excess ETH or disallow purchase?
             // For simplicity, disallow repeat purchase for unlimited access.
             revert("User already has unlimited access");
        }
        // If time-limited access exists, a new purchase extends or replaces it depending on logic.
        // Here, we grant new access that starts now and potentially overrides old access.

        uint256 price = dataSet.price;
        uint256 feeAmount = price.mul(platformFeePercentage).div(10000);
        uint256 publisherShare = price.sub(feeAmount);

        // Record fee and earnings before transfer
        totalPlatformFeesCollected = totalPlatformFeesCollected.add(feeAmount);
        publisherEarnings[dataSet.publisher] = publisherEarnings[dataSet.publisher].add(publisherShare);

        // Record purchase
        uint256 purchaseId = nextPurchaseId++;
        purchases[purchaseId] = Purchase({
            dataSetId: _dataSetId,
            buyer: msg.sender,
            pricePaid: price,
            timestamp: block.timestamp
        });

        userPurchaseIds[msg.sender].push(purchaseId);
        dataSetPurchaseIds[_dataSetId].push(purchaseId);

        // Update dataset stats
        dataSet.saleCount = dataSet.saleCount.add(1);

        // Grant/Update Access Record
        uint256 expiry = 0; // Default to unlimited if duration is 0
        if (dataSet.accessDurationSeconds > 0) {
             // Access starts now and lasts for the specified duration
             expiry = block.timestamp.add(dataSet.accessDurationSeconds);
        }

        userDataSetAccess[_dataSetId][msg.sender] = AccessRecord({
             hasAccess: true,
             expiryTimestamp: expiry,
             purchaseId: purchaseId
        });


        // Refund excess ETH if any (Checks-Effects-Interactions Pattern)
        if (msg.value > price) {
            uint256 refundAmount = msg.value.sub(price);
            // Use call for external transfer
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success, "Refund failed");
        }

        emit AccessPurchased(purchaseId, _dataSetId, msg.sender, price);
    }

    /**
     * @notice Allows a buyer who purchased a data set to submit a review.
     * @param _dataSetId The ID of the data set to review.
     * @param _rating The rating (1-5).
     * @param _reviewTextHash Hash of the review text (for off-chain verification).
     */
    function submitReview(uint256 _dataSetId, uint8 _rating, string memory _reviewTextHash) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_reviewTextHash).length > 0, "Review text hash cannot be empty");
        require(!hasReviewed[msg.sender][_dataSetId], "User has already reviewed this dataset");

        // Check if user has purchased access to this dataset (simple check via access record)
        AccessRecord storage accessRecord = userDataSetAccess[_dataSetId][msg.sender];
        require(accessRecord.hasAccess, "User must have access to review this dataset");
        // Optionally add time limit - e.g., must review within X days of purchase/access expiry
        // For simplicity, we just check if they have access now.

        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");

        uint256 reviewId = nextReviewId++;
        reviews[reviewId] = Review({
            dataSetId: _dataSetId,
            reviewer: msg.sender,
            rating: _rating,
            reviewTextHash: _reviewTextHash,
            timestamp: block.timestamp,
            isChallenged: false
        });

        dataSetReviewIds[_dataSetId].push(reviewId);
        userReviewIds[msg.sender].push(reviewId);
        hasReviewed[msg.sender][_dataSetId] = true;

        // Update data set rating stats
        dataSet.totalRatingSum = dataSet.totalRatingSum.add(_rating);
        dataSet.reviewCount = dataSet.reviewCount.add(1);

        emit ReviewSubmitted(reviewId, _dataSetId, msg.sender, _rating);
    }

    /**
     * @notice Allows the publisher of a data set or the owner to flag a review as potentially problematic.
     * This doesn't remove the review, just flags it for potential off-chain moderation or community review.
     * @param _reviewId The ID of the review to challenge.
     */
     function challengeReview(uint256 _reviewId) external {
         Review storage review = reviews[_reviewId];
         require(review.reviewer != address(0), "Review does not exist");

         DataSet storage dataSet = dataSets[review.dataSetId];
         require(msg.sender == dataSet.publisher || msg.sender == owner(), "Caller is not publisher or owner");

         require(!review.isChallenged, "Review is already challenged");

         review.isChallenged = true;
         emit ReviewChallenged(_reviewId, review.dataSetId);
     }

    /**
     * @notice Allows any user to flag a data set for moderation (e.g., broken link, inappropriate content).
     * @param _dataSetId The ID of the data set to flag.
     */
    function flagDataSetForModeration(uint256 _dataSetId) external {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        require(!dataSet.isFlagged, "DataSet is already flagged");

        dataSet.isFlagged = true;
        emit DataSetFlagged(_dataSetId, msg.sender);
    }


    // --- View Functions ---

    /**
     * @notice Verifies if a user has active access to a data set.
     * This function is crucial for off-chain applications to check access rights.
     * @param _dataSetId The ID of the data set.
     * @param _user The address of the user.
     * @return hasValidAccess True if the user has active access.
     * @return dataHash The data hash if access is valid, empty string otherwise.
     * @return accessExpires The timestamp when access expires (0 for unlimited access).
     */
    function verifyAccess(uint256 _dataSetId, address _user) external view returns (bool hasValidAccess, string memory dataHash, uint256 accessExpires) {
         DataSet storage dataSet = dataSets[_dataSetId];
         // Check if dataset exists and is not removed by moderation
         if (dataSet.publisher == address(0) || dataSet.isRemovedByModeration) {
             return (false, "", 0);
         }

         AccessRecord storage accessRecord = userDataSetAccess[_dataSetId][_user];

         // Check if user has access recorded
         if (!accessRecord.hasAccess) {
             return (false, "", 0);
         }

         // Check if time-limited access has expired
         if (accessRecord.expiryTimestamp > 0 && accessRecord.expiryTimestamp < block.timestamp) {
             // Access has expired
             return (false, "", accessRecord.expiryTimestamp); // Return expiry even if expired
         }

         // Access is valid
         return (true, dataSet.dataHash, accessRecord.expiryTimestamp);
    }


    /**
     * @notice Gets details for a specific data set.
     * @param _dataSetId The ID of the data set.
     * @return publisher The publisher's address.
     * @return price The price in Wei.
     * @return dataHash The data hash.
     * @return title The title.
     * @return description The description.
     * @return isListed Whether the data set is currently listed.
     * @return accessDurationSeconds The access duration in seconds (0 for unlimited).
     * @return tier The access tier.
     * @return saleCount The number of times purchased.
     * @return averageRating The average rating (scaled by 100 to return integer).
     * @return reviewCount The number of reviews.
     * @return isFlagged Whether the data set is flagged for moderation.
     * @return isRemovedByModeration Whether the data set was removed by moderation.
     */
    function getDataSetDetails(uint256 _dataSetId) external view returns (
        address publisher,
        uint256 price,
        string memory dataHash,
        string memory title,
        string memory description,
        bool isListed,
        uint256 accessDurationSeconds,
        uint256 tier,
        uint256 saleCount,
        uint8 averageRating,
        uint256 reviewCount,
        bool isFlagged,
        bool isRemovedByModeration
    ) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");

        uint8 avgRating = 0;
        if (dataSet.reviewCount > 0) {
            // Calculate average rating, scale by 100 to avoid float
            avgRating = uint8((dataSet.totalRatingSum.mul(100)).div(dataSet.reviewCount));
        }

        return (
            dataSet.publisher,
            dataSet.price,
            dataSet.dataHash,
            dataSet.title,
            dataSet.description,
            dataSet.isListed,
            dataSet.accessDurationSeconds,
            dataSet.tier,
            dataSet.saleCount,
            avgRating, // Return scaled average
            dataSet.reviewCount,
            dataSet.isFlagged,
            dataSet.isRemovedByModeration
        );
    }

    /**
     * @notice Gets a list of all active data set IDs.
     * @return A dynamic array of data set IDs.
     */
    function listAllDataSetIds() external view returns (uint256[] memory) {
        uint256[] memory listedIds = new uint256[](nextDataSetId - 1);
        uint256 counter = 0;
        for (uint256 i = 1; i < nextDataSetId; i++) {
            if (dataSets[i].isListed && !dataSets[i].isRemovedByModeration) {
                listedIds[counter] = i;
                counter++;
            }
        }
        // Resize array to actual number of listed datasets
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = listedIds[i];
        }
        return result;
    }

    /**
     * @notice Gets a list of data set IDs published by a specific address.
     * @param _publisher The publisher's address.
     * @return A dynamic array of data set IDs.
     */
    function listMyPublishedDataSetIds(address _publisher) external view returns (uint256[] memory) {
        return publisherDataSetIds[_publisher];
    }

     /**
     * @notice Gets a list of data set IDs purchased by a specific address.
     * Note: This lists datasets for which a *purchase* occurred, not necessarily *active* access.
     * Use `verifyAccess` to check active access.
     * @param _buyer The buyer's address.
     * @return A dynamic array of data set IDs.
     */
    function listMyPurchasedDataSetIds(address _buyer) external view returns (uint256[] memory) {
        uint256[] memory purchaseIds = userPurchaseIds[_buyer];
        uint256[] memory dataSetIds = new uint256[](purchaseIds.length);
        for(uint i = 0; i < purchaseIds.length; i++) {
            dataSetIds[i] = purchases[purchaseIds[i]].dataSetId;
        }
        return dataSetIds;
    }

    /**
     * @notice Calculates the average rating for a data set.
     * @param _dataSetId The ID of the data set.
     * @return The average rating (1-5), scaled by 100 (e.g., 450 for 4.5). Returns 0 if no reviews.
     */
    function getDataSetAverageRating(uint256 _dataSetId) external view returns (uint8) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");

        if (dataSet.reviewCount == 0) {
            return 0;
        }
        return uint8((dataSet.totalRatingSum.mul(100)).div(dataSet.reviewCount));
    }

    /**
     * @notice Gets a list of review IDs for a specific data set.
     * @param _dataSetId The ID of the data set.
     * @return A dynamic array of review IDs.
     */
    function getDataSetReviews(uint256 _dataSetId) external view returns (uint256[] memory) {
        require(dataSets[_dataSetId].publisher != address(0), "DataSet does not exist");
        return dataSetReviewIds[_dataSetId];
    }

     /**
     * @notice Gets details for a specific review.
     * @param _reviewId The ID of the review.
     * @return dataSetId The ID of the reviewed data set.
     * @return reviewer The address of the reviewer.
     * @return rating The rating (1-5).
     * @return reviewTextHash Hash of the review text.
     * @return timestamp The timestamp of the review.
     * @return isChallenged Whether the review is challenged.
     */
    function getReviewDetails(uint256 _reviewId) external view returns (
        uint256 dataSetId,
        address reviewer,
        uint8 rating,
        string memory reviewTextHash,
        uint256 timestamp,
        bool isChallenged
    ) {
        Review storage review = reviews[_reviewId];
        require(review.reviewer != address(0), "Review does not exist");
        return (
            review.dataSetId,
            review.reviewer,
            review.rating,
            review.reviewTextHash,
            review.timestamp,
            review.isChallenged
        );
    }

     /**
     * @notice Gets details for a specific purchase record.
     * @param _purchaseId The ID of the purchase.
     * @return dataSetId The ID of the data set purchased.
     * @return buyer The address of the buyer.
     * @return pricePaid The price paid in Wei.
     * @return timestamp The timestamp of the purchase.
     */
    function getPurchaseDetails(uint256 _purchaseId) external view returns (
        uint256 dataSetId,
        address buyer,
        uint256 pricePaid,
        uint256 timestamp
    ) {
        Purchase storage purchase = purchases[_purchaseId];
        require(purchase.buyer != address(0), "Purchase does not exist");
        return (
            purchase.dataSetId,
            purchase.buyer,
            purchase.pricePaid,
            purchase.timestamp
        );
    }

    /**
     * @notice Gets the number of times a data set has been successfully purchased.
     * @param _dataSetId The ID of the data set.
     * @return The sale count.
     */
    function getDataSetSaleCount(uint256 _dataSetId) external view returns (uint256) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        return dataSet.saleCount;
    }

    /**
     * @notice Checks if a user is eligible to review a data set (has access AND hasn't reviewed).
     * @param _dataSetId The ID of the data set.
     * @param _user The address of the user.
     * @return True if the user is eligible to review, false otherwise.
     */
    function canReviewDataSet(uint256 _dataSetId, address _user) external view returns (bool) {
        DataSet storage dataSet = dataSets[_dataSetId];
        if (dataSet.publisher == address(0)) { return false; }

        AccessRecord storage accessRecord = userDataSetAccess[_dataSetId][_user];

        // User must currently have access (purchased or granted)
        if (!accessRecord.hasAccess) { return false; }
        // Access must not be expired (if time-limited)
        if (accessRecord.expiryTimestamp > 0 && accessRecord.expiryTimestamp < block.timestamp) { return false; }
        // User must not have reviewed already
        if (hasReviewed[_user][_dataSetId]) { return false; }

        return true;
    }

     /**
     * @notice Checks if a data set is currently flagged for moderation.
     * @param _dataSetId The ID of the data set.
     * @return True if flagged, false otherwise.
     */
    function isDataSetFlagged(uint256 _dataSetId) external view returns (bool) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.publisher != address(0), "DataSet does not exist");
        return dataSet.isFlagged;
    }

     /**
     * @notice Gets the total accumulated earnings for a specific publisher.
     * @param _publisher The publisher's address.
     * @return The total earnings amount in Wei.
     */
    function getUserTotalEarnings(address _publisher) external view returns (uint256) {
         return publisherEarnings[_publisher];
     }

     /**
     * @notice Gets the total platform fees collected by the contract.
     * @return The total collected amount in Wei.
     */
     function getTotalPlatformFeesCollected() external view returns (uint256) {
         return totalPlatformFeesCollected;
     }

    /**
     * @notice Gets the current platform fee recipient address.
     * @return The fee recipient address.
     */
    function getPlatformFeeRecipient() external view returns (address) {
        return platformFeeRecipient;
    }

    /**
     * @notice Gets the current platform fee percentage.
     * @return The fee percentage in basis points.
     */
    function getPlatformFeePercentage() external view returns (uint256) {
        return platformFeePercentage;
    }
}
```