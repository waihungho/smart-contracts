```solidity
/**
 * @title Decentralized Content Creation and Monetization Platform - "ContentVerse"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform enabling creators to publish, monetize, and manage their digital content.
 *      This contract incorporates advanced concepts like dynamic NFTs, tiered subscriptions, on-chain reputation, content curation, and basic governance elements.
 *      It aims to provide a comprehensive ecosystem for creators and consumers within a decentralized environment.
 *
 * **Outline & Function Summary:**
 *
 * **Content Management:**
 * 1. `createContent(string _metadataURI, ContentType _contentType)`: Allows creators to register new content by providing metadata URI and content type. Mints a Content NFT.
 * 2. `updateContentMetadata(uint256 _contentId, string _newMetadataURI)`: Allows creators to update the metadata URI of their content.
 * 3. `setContentPrice(uint256 _contentId, uint256 _price)`: Allows creators to set or update the price of their content for direct purchase.
 * 4. `setContentSubscriptionTier(uint256 _contentId, uint256 _tierId)`: Allows creators to associate content with a specific subscription tier.
 * 5. `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content, including metadata URI, price, creator, etc.
 * 6. `getContentCreator(uint256 _contentId)`: Retrieves the creator address of a specific content.
 * 7. `getContentType(uint256 _contentId)`: Retrieves the content type of a specific content.
 * 8. `getContentPrice(uint256 _contentId)`: Retrieves the purchase price of a specific content.
 * 9. `getContentSubscriptionTier(uint256 _contentId)`: Retrieves the subscription tier ID associated with a content.
 * 10. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for policy violations.
 * 11. `moderateContent(uint256 _contentId, ContentStatus _newStatus)`: Platform admin function to moderate content and change its status (e.g., Active, Flagged, Removed).
 * 12. `getContentStatus(uint256 _contentId)`: Retrieves the current status of a content.
 *
 * **Monetization & Subscription:**
 * 13. `purchaseContent(uint256 _contentId)`: Allows users to purchase content directly from creators.
 * 14. `createSubscriptionTier(string _tierName, uint256 _monthlyFee, string _tierDescription)`: Platform admin function to create new subscription tiers with names, fees, and descriptions.
 * 15. `getSubscriptionTierDetails(uint256 _tierId)`: Retrieves details of a specific subscription tier.
 * 16. `subscribeToTier(uint256 _tierId)`: Allows users to subscribe to a specific subscription tier.
 * 17. `cancelSubscription()`: Allows users to cancel their active subscription.
 * 18. `isSubscriber(address _user)`: Checks if a user is currently subscribed to any tier.
 * 19. `getActiveSubscriptionTier(address _user)`: Retrieves the ID of the subscription tier a user is subscribed to, if any.
 * 20. `withdrawCreatorEarnings()`: Allows creators to withdraw their accumulated earnings from content sales and subscriptions.
 * 21. `setPlatformFee(uint256 _feePercentage)`: Platform admin function to set the platform fee percentage on content sales and subscriptions.
 * 22. `withdrawPlatformFees()`: Platform admin function to withdraw accumulated platform fees.
 *
 * **Community & Reputation (Basic):**
 * 23. `likeContent(uint256 _contentId)`: Allows users to "like" content, contributing to a basic on-chain reputation metric.
 * 24. `getContentLikes(uint256 _contentId)`: Retrieves the number of likes a content has received.
 * 25. `commentOnContent(uint256 _contentId, string _commentText)`: Allows users to leave comments on content (Note: Comments are stored as events for simplicity in this example, a real-world implementation might use off-chain storage or more complex on-chain structures).
 *
 * **Admin & Utility:**
 * 26. `setPlatformAdmin(address _newAdmin)`: Allows the current admin to change the platform administrator.
 * 27. `pauseContract()`: Platform admin function to pause the contract, halting critical functions in case of emergency.
 * 28. `unpauseContract()`: Platform admin function to unpause the contract.
 * 29. `isContractPaused()`: Checks if the contract is currently paused.
 * 30. `getContentCount()`: Returns the total number of content items registered on the platform.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ContentVerse is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _contentIds;
    Counters.Counter private _tierIds;

    // Enums
    enum ContentType { Article, Video, Audio, Image, Document, Other }
    enum ContentStatus { Active, Flagged, Removed }
    enum SubscriptionStatus { Active, Inactive }

    // Structs
    struct Content {
        uint256 contentId;
        address creator;
        string metadataURI;
        ContentType contentType;
        uint256 price; // Price in wei for direct purchase
        uint256 subscriptionTierId; // Tier ID if content is behind a subscription
        ContentStatus status;
        uint256 likeCount;
    }

    struct SubscriptionTier {
        uint256 tierId;
        string tierName;
        uint256 monthlyFee; // Fee in wei per month
        string tierDescription;
        uint256 subscriberCount;
    }

    struct Subscription {
        uint256 tierId;
        address subscriber;
        uint256 startTime;
        SubscriptionStatus status;
    }

    // Mappings
    mapping(uint256 => Content) public contentRegistry;
    mapping(uint256 => SubscriptionTier) public subscriptionTiers;
    mapping(address => Subscription) public userSubscriptions;
    mapping(uint256 => address[]) public contentLikes; // Map content ID to array of likers
    mapping(uint256 => uint256) public contentLikeCounts; // Map content ID to like count

    // State Variables
    uint256 public platformFeePercentage = 5; // Platform fee percentage (e.g., 5%)
    address public platformAdmin;
    uint256 public platformFeesCollected;

    // Events
    event ContentCreated(uint256 contentId, address creator, string metadataURI, ContentType contentType);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentSubscriptionTierSet(uint256 contentId, uint256 tierId);
    event ContentPurchased(uint256 contentId, address buyer, address creator, uint256 price);
    event SubscriptionTierCreated(uint256 tierId, string tierName, uint256 monthlyFee);
    event SubscriptionStarted(uint256 tierId, address subscriber);
    event SubscriptionCancelled(address subscriber);
    event CreatorEarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeesWithdrawn(address admin, uint256 amount);
    event ContentLiked(uint256 contentId, address liker);
    event ContentCommented(uint256 contentId, address commenter, string commentText);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, ContentStatus newStatus, address moderator);
    event PlatformFeePercentageSet(uint256 newFeePercentage, address admin);
    event PlatformAdminChanged(address newAdmin, address oldAdmin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);


    // Modifiers
    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can perform this action");
        _;
    }

    modifier onlyContentCreator(uint256 _contentId) {
        require(contentRegistry[_contentId].creator == msg.sender, "Only content creator can perform this action");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(_contentIds.current() >= _contentId && _contentId > 0, "Invalid content ID");
        _;
    }

    modifier validTierId(uint256 _tierId) {
        require(_tierIds.current() >= _tierId && _tierId > 0, "Invalid tier ID");
        _;
    }

    modifier isSubscribedUser() {
        require(userSubscriptions[msg.sender].status == SubscriptionStatus.Active, "User is not subscribed");
        _;
    }

    modifier isNotSubscribedUser() {
        require(userSubscriptions[msg.sender].status == SubscriptionStatus.Inactive || userSubscriptions[msg.sender].status == SubscriptionStatus.Inactive, "User is already subscribed");
        _;
    }


    constructor() ERC721("ContentVerse Content", "CVC") {
        platformAdmin = msg.sender;
    }

    /**
     * @dev Function to set a new platform administrator. Only current admin can call.
     * @param _newAdmin Address of the new platform administrator.
     */
    function setPlatformAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "New admin address cannot be zero address");
        emit PlatformAdminChanged(_newAdmin, platformAdmin);
        platformAdmin = _newAdmin;
    }

    /**
     * @dev Function to set the platform fee percentage. Only platform admin can call.
     * @param _feePercentage New platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100");
        emit PlatformFeePercentageSet(_feePercentage, msg.sender);
        platformFeePercentage = _feePercentage;
    }

    /**
     * @dev Allows creators to register new content. Mints a Content NFT.
     * @param _metadataURI URI pointing to the content's metadata.
     * @param _contentType Type of the content (Article, Video, etc.).
     */
    function createContent(string memory _metadataURI, ContentType _contentType) external whenNotPaused {
        _contentIds.increment();
        uint256 contentId = _contentIds.current();

        _mint(msg.sender, contentId); // Mint NFT to the creator

        contentRegistry[contentId] = Content({
            contentId: contentId,
            creator: msg.sender,
            metadataURI: _metadataURI,
            contentType: _contentType,
            price: 0, // Default price is 0, creator can set later
            subscriptionTierId: 0, // Not associated with a tier initially
            status: ContentStatus.Active,
            likeCount: 0
        });

        emit ContentCreated(contentId, msg.sender, _metadataURI, _contentType);
    }

    /**
     * @dev Allows creators to update the metadata URI of their content.
     * @param _contentId ID of the content to update.
     * @param _newMetadataURI New URI for the content metadata.
     */
    function updateContentMetadata(uint256 _contentId, string memory _newMetadataURI) external onlyContentCreator(_contentId) validContentId(_contentId) whenNotPaused {
        contentRegistry[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    /**
     * @dev Allows creators to set or update the price of their content for direct purchase.
     * @param _contentId ID of the content to set price for.
     * @param _price Price in wei.
     */
    function setContentPrice(uint256 _contentId, uint256 _price) external onlyContentCreator(_contentId) validContentId(_contentId) whenNotPaused {
        contentRegistry[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    /**
     * @dev Allows creators to associate content with a specific subscription tier.
     * @param _contentId ID of the content.
     * @param _tierId ID of the subscription tier to associate with.
     */
    function setContentSubscriptionTier(uint256 _contentId, uint256 _tierId) external onlyContentCreator(_contentId) validContentId(_contentId) validTierId(_tierId) whenNotPaused {
        contentRegistry[_contentId].subscriptionTierId = _tierId;
        emit ContentSubscriptionTierSet(_contentId, _tierId);
    }

    /**
     * @dev Allows users to purchase content directly.
     * @param _contentId ID of the content to purchase.
     */
    function purchaseContent(uint256 _contentId) external payable validContentId(_contentId) whenNotPaused {
        Content storage content = contentRegistry[_contentId];
        require(content.price > 0, "Content is not for sale or price is not set");
        require(msg.value >= content.price, "Insufficient payment");

        uint256 platformFee = (content.price * platformFeePercentage) / 100;
        uint256 creatorEarning = content.price - platformFee;

        platformFeesCollected += platformFee;

        payable(content.creator).transfer(creatorEarning); // Send earnings to creator
        payable(platformAdmin).transfer(platformFee); // Send platform fees to admin

        emit ContentPurchased(_contentId, msg.sender, content.creator, content.price);
    }

    /**
     * @dev Platform admin function to create a new subscription tier.
     * @param _tierName Name of the subscription tier.
     * @param _monthlyFee Monthly fee in wei for the tier.
     * @param _tierDescription Description of the tier benefits.
     */
    function createSubscriptionTier(string memory _tierName, uint256 _monthlyFee, string memory _tierDescription) external onlyPlatformAdmin whenNotPaused {
        _tierIds.increment();
        uint256 tierId = _tierIds.current();

        subscriptionTiers[tierId] = SubscriptionTier({
            tierId: tierId,
            tierName: _tierName,
            monthlyFee: _monthlyFee,
            tierDescription: _tierDescription,
            subscriberCount: 0
        });

        emit SubscriptionTierCreated(tierId, _tierName, _monthlyFee);
    }

    /**
     * @dev Allows users to subscribe to a specific subscription tier.
     * @param _tierId ID of the subscription tier to subscribe to.
     */
    function subscribeToTier(uint256 _tierId) external payable validTierId(_tierId) isNotSubscribedUser whenNotPaused {
        SubscriptionTier storage tier = subscriptionTiers[_tierId];
        require(msg.value >= tier.monthlyFee, "Insufficient subscription fee");

        // Refund extra payment if any (optional, can be removed for simplicity)
        if (msg.value > tier.monthlyFee) {
            payable(msg.sender).transfer(msg.value - tier.monthlyFee);
        }

        // Handle platform fee for subscriptions
        uint256 platformFee = (tier.monthlyFee * platformFeePercentage) / 100;
        uint256 platformEarning = tier.monthlyFee - platformFee;

        platformFeesCollected += platformFee;
        payable(platformAdmin).transfer(platformFee); // Send platform fees to admin


        userSubscriptions[msg.sender] = Subscription({
            tierId: _tierId,
            subscriber: msg.sender,
            startTime: block.timestamp,
            status: SubscriptionStatus.Active
        });
        subscriptionTiers[_tierId].subscriberCount++;

        emit SubscriptionStarted(_tierId, msg.sender);
    }

    /**
     * @dev Allows users to cancel their active subscription.
     */
    function cancelSubscription() external isSubscribedUser whenNotPaused {
        userSubscriptions[msg.sender].status = SubscriptionStatus.Inactive;
        subscriptionTiers[userSubscriptions[msg.sender].tierId].subscriberCount--;
        emit SubscriptionCancelled(msg.sender);
    }

    /**
     * @dev Allows creators to withdraw their accumulated earnings.
     */
    function withdrawCreatorEarnings() external whenNotPaused {
        // In a real-world scenario, earnings tracking would be more complex.
        // For simplicity, this example assumes all funds received by the contract (excluding platform fees and subscription fees)
        // are creator earnings and can be withdrawn by the creator.
        // In a robust system, you'd likely need to track earnings per content and per creator more precisely.

        // This is a simplified example - in a real system, you'd track creator balances.
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableAmount = contractBalance - platformFeesCollected; // Simplified withdrawal logic.

        require(withdrawableAmount > 0, "No earnings to withdraw");

        platformFeesCollected = 0; // Reset platform fees (in this simplified example)
        payable(msg.sender).transfer(withdrawableAmount); // Creator withdraws all contract balance minus platform fees.

        emit CreatorEarningsWithdrawn(msg.sender, withdrawableAmount);
    }

    /**
     * @dev Allows platform admin to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyPlatformAdmin whenNotPaused {
        require(platformFeesCollected > 0, "No platform fees to withdraw");
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset platform fees after withdrawal
        payable(platformAdmin).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Allows users to "like" content.
     * @param _contentId ID of the content to like.
     */
    function likeContent(uint256 _contentId) external validContentId(_contentId) whenNotPaused {
        // Prevent duplicate likes from the same user
        bool alreadyLiked = false;
        for (uint i = 0; i < contentLikes[_contentId].length; i++) {
            if (contentLikes[_contentId][i] == msg.sender) {
                alreadyLiked = true;
                break;
            }
        }
        require(!alreadyLiked, "You have already liked this content");

        contentLikes[_contentId].push(msg.sender);
        contentLikeCounts[_contentId]++;
        contentRegistry[_contentId].likeCount++;
        emit ContentLiked(_contentId, msg.sender);
    }

    /**
     * @dev Allows users to comment on content. Comments are emitted as events.
     * @param _contentId ID of the content to comment on.
     * @param _commentText Text of the comment.
     */
    function commentOnContent(uint256 _contentId, string memory _commentText) external validContentId(_contentId) whenNotPaused {
        emit ContentCommented(_contentId, msg.sender, _commentText);
    }

    /**
     * @dev Allows users to report content for policy violations.
     * @param _contentId ID of the content being reported.
     * @param _reportReason Reason for reporting the content.
     */
    function reportContent(uint256 _contentId, string memory _reportReason) external validContentId(_contentId) whenNotPaused {
        emit ContentReported(_contentId, msg.sender, _reportReason);
        // In a real application, you would likely store reports for admin review.
    }

    /**
     * @dev Platform admin function to moderate content and change its status.
     * @param _contentId ID of the content to moderate.
     * @param _newStatus New status for the content (Active, Flagged, Removed).
     */
    function moderateContent(uint256 _contentId, ContentStatus _newStatus) external onlyPlatformAdmin validContentId(_contentId) whenNotPaused {
        contentRegistry[_contentId].status = _newStatus;
        emit ContentModerated(_contentId, _newStatus, msg.sender);
    }

    /**
     * @dev Retrieves detailed information about a specific content.
     * @param _contentId ID of the content.
     * @return Content struct containing content details.
     */
    function getContentDetails(uint256 _contentId) external view validContentId(_contentId) returns (Content memory) {
        return contentRegistry[_contentId];
    }

    /**
     * @dev Retrieves the creator address of a specific content.
     * @param _contentId ID of the content.
     * @return Address of the content creator.
     */
    function getContentCreator(uint256 _contentId) external view validContentId(_contentId) returns (address) {
        return contentRegistry[_contentId].creator;
    }

    /**
     * @dev Retrieves the content type of a specific content.
     * @param _contentId ID of the content.
     * @return ContentType enum value.
     */
    function getContentType(uint256 _contentId) external view validContentId(_contentId) returns (ContentType) {
        return contentRegistry[_contentId].contentType;
    }

    /**
     * @dev Retrieves the purchase price of a specific content.
     * @param _contentId ID of the content.
     * @return Price of the content in wei.
     */
    function getContentPrice(uint256 _contentId) external view validContentId(_contentId) returns (uint256) {
        return contentRegistry[_contentId].price;
    }

    /**
     * @dev Retrieves the subscription tier ID associated with a content.
     * @param _contentId ID of the content.
     * @return Subscription tier ID. Returns 0 if not associated with a tier.
     */
    function getContentSubscriptionTier(uint256 _contentId) external view validContentId(_contentId) returns (uint256) {
        return contentRegistry[_contentId].subscriptionTierId;
    }

    /**
     * @dev Retrieves the current status of a content.
     * @param _contentId ID of the content.
     * @return ContentStatus enum value.
     */
    function getContentStatus(uint256 _contentId) external view validContentId(_contentId) returns (ContentStatus) {
        return contentRegistry[_contentId].status;
    }

    /**
     * @dev Retrieves details of a specific subscription tier.
     * @param _tierId ID of the subscription tier.
     * @return SubscriptionTier struct containing tier details.
     */
    function getSubscriptionTierDetails(uint256 _tierId) external view validTierId(_tierId) returns (SubscriptionTier memory) {
        return subscriptionTiers[_tierId];
    }

    /**
     * @dev Checks if a user is currently subscribed to any tier.
     * @param _user Address of the user to check.
     * @return True if subscribed, false otherwise.
     */
    function isSubscriber(address _user) external view returns (bool) {
        return userSubscriptions[_user].status == SubscriptionStatus.Active;
    }

    /**
     * @dev Retrieves the ID of the subscription tier a user is subscribed to, if any.
     * @param _user Address of the user.
     * @return Tier ID if subscribed, 0 otherwise.
     */
    function getActiveSubscriptionTier(address _user) external view returns (uint256) {
        if (userSubscriptions[_user].status == SubscriptionStatus.Active) {
            return userSubscriptions[_user].tierId;
        }
        return 0;
    }

    /**
     * @dev Retrieves the number of likes a content has received.
     * @param _contentId ID of the content.
     * @return Number of likes.
     */
    function getContentLikes(uint256 _contentId) external view validContentId(_contentId) returns (uint256) {
        return contentLikeCounts[_contentId];
    }

    /**
     * @dev Returns the total number of content items registered on the platform.
     * @return Total content count.
     */
    function getContentCount() external view returns (uint256) {
        return _contentIds.current();
    }


    /**
     * @dev Pauses the contract, preventing certain actions. Only admin can call.
     */
    function pauseContract() external onlyPlatformAdmin {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality. Only admin can call.
     */
    function unpauseContract() external onlyPlatformAdmin {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() external view returns (bool) {
        return paused();
    }

    // The following functions are overrides required by OpenZeppelin ERC721
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return contentRegistry[tokenId].metadataURI;
    }

    // Add fallback and receive functions to handle direct ETH transfers (optional, for tipping etc.)
    receive() external payable {}
    fallback() external payable {}
}
```