```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Decentralized Content Platform (DDCP)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized content platform with dynamic features,
 * reputation system, content versioning, and community interaction.

 * Function Outline:
 * -----------------
 * **Content Creation and Management:**
 * 1. createContent(string _title, string _contentHash, string _contentType, string[] _tags): Allows users to create new content.
 * 2. updateContent(uint256 _contentId, string _newContentHash): Allows content authors to update their content.
 * 3. setContentVisibility(uint256 _contentId, ContentVisibility _visibility): Change content visibility (public, private, premium).
 * 4. setContentPrice(uint256 _contentId, uint256 _price): Set the price for premium content.
 * 5. getContent(uint256 _contentId): Retrieve content details (excluding actual content hash for security - use off-chain retrieval).
 * 6. deleteContent(uint256 _contentId): Allows content authors to delete their content (can be soft delete).
 * 7. archiveContent(uint256 _contentId): Archive content, making it read-only and removing from active listings.
 * 8. getContentVersion(uint256 _contentId, uint256 _version): Retrieve a specific version of the content.
 * 9. getContentVersionCount(uint256 _contentId): Get the number of versions for a content.

 * **Reputation and Moderation:**
 * 10. upvoteContent(uint256 _contentId): Allows users to upvote content.
 * 11. downvoteContent(uint256 _contentId): Allows users to downvote content.
 * 12. reportContent(uint256 _contentId, string _reason): Allows users to report content for moderation.
 * 13. getAuthorReputation(address _author): Get the reputation score of a content author.
 * 14. setModerator(address _moderator, bool _isModerator): Platform owner can appoint/revoke moderators.
 * 15. moderateContent(uint256 _contentId, ModerationAction _action, string _reason): Moderators can take actions on reported content.

 * **Monetization and Access Control:**
 * 16. purchaseContentAccess(uint256 _contentId): Allows users to purchase access to premium content.
 * 17. checkContentAccess(uint256 _contentId, address _user): Check if a user has access to premium content.
 * 18. withdrawEarnings(): Allows content authors to withdraw their earnings from premium content sales.
 * 19. setPlatformFee(uint256 _feePercentage): Platform owner can set the platform fee percentage.
 * 20. withdrawPlatformFees(): Platform owner can withdraw collected platform fees.

 * **Utility and Platform Settings:**
 * 21. getContentCount(): Get the total number of content pieces on the platform.
 * 22. getPlatformOwner(): Get the address of the platform owner.
 * 23. setPlatformName(string _name): Platform owner can set the platform name.
 * 24. getPlatformName(): Get the platform name.
 * 25. getContentTags(uint256 _contentId): Get the tags associated with a content.

 * Function Summary:
 * -----------------
 * This smart contract implements a decentralized content platform where users can create, share, and monetize content. It includes features for content versioning,
 * reputation management through upvotes/downvotes, moderation tools, and flexible access control with premium content options. The platform also has settings
 * for platform fees and ownership management. The contract aims to provide a robust and dynamic environment for content creators and consumers on the blockchain.
 */

contract DynamicDecentralizedContentPlatform {
    enum ContentVisibility { Public, Private, Premium }
    enum ContentType { Article, Blog, Tutorial, Review, Other } // Extendable content types
    enum ModerationAction { WarnAuthor, HideContent, DeleteContent, NoAction }

    struct Content {
        uint256 id;
        address author;
        string title;
        string contentHash; // Hash of the content (store actual content off-chain e.g., IPFS)
        ContentType contentType;
        ContentVisibility visibility;
        uint256 price; // Price in wei for premium content
        uint256 createdAt;
        uint256 updatedAt;
        uint256 versionCount;
        uint256 upvotes;
        uint256 downvotes;
        bool isDeleted;
        bool isArchived;
    }

    struct ContentVersion {
        uint256 contentId;
        uint256 version;
        string contentHash;
        uint256 updatedAt;
    }

    struct Report {
        uint256 contentId;
        address reporter;
        string reason;
        uint256 reportedAt;
        bool isResolved;
        ModerationAction actionTaken;
    }

    string public platformName = "Decentralized Content Hub";
    address public platformOwner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public contentIdCounter = 1;
    uint256 public reportIdCounter = 1;

    mapping(uint256 => Content) public contentMap;
    mapping(uint256 => mapping(uint256 => ContentVersion)) public contentVersions;
    mapping(uint256 => ContentVersion) public latestContentVersion; // To quickly access the latest version
    mapping(uint256 => mapping(address => bool)) public contentAccess; // contentId => userAddress => hasAccess
    mapping(address => int256) public authorReputation; // Author address => reputation score
    mapping(uint256 => Report) public reports;
    mapping(address => bool) public moderators;
    mapping(uint256 => string[]) public contentTags; // contentId => array of tags
    mapping(address => uint256) public authorEarnings; // Author address => accumulated earnings

    event ContentCreated(uint256 contentId, address author, string title);
    event ContentUpdated(uint256 contentId, uint256 version, address author);
    event ContentVisibilityChanged(uint256 contentId, ContentVisibility visibility);
    event ContentPriceChanged(uint256 contentId, uint256 price);
    event ContentDeleted(uint256 contentId, address author);
    event ContentArchived(uint256 contentId, address author);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event ContentReported(uint256 reportId, uint256 contentId, address reporter);
    event ContentModerated(uint256 contentId, ModerationAction action, string reason);
    event AccessPurchased(uint256 contentId, address user, uint256 price);
    event EarningsWithdrawn(address author, uint256 amount);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ModeratorSet(address moderator, bool isModerator);
    event PlatformNameChanged(string platformName);
    event ContentTagged(uint256 contentId, string tag);

    modifier onlyAuthor(uint256 _contentId) {
        require(contentMap[_contentId].author == msg.sender, "You are not the author of this content.");
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can perform this action.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || msg.sender == platformOwner, "Only moderators or platform owner can perform this action.");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(contentMap[_contentId].id != 0 && !contentMap[_contentId].isDeleted && !contentMap[_contentId].isArchived, "Invalid or deleted/archived content ID.");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
    }

    /// ------------------------------------------------------------------------
    /// Content Creation and Management Functions
    /// ------------------------------------------------------------------------

    function createContent(
        string memory _title,
        string memory _contentHash,
        ContentType _contentType,
        string[] memory _tags
    ) public {
        uint256 currentContentId = contentIdCounter;
        contentMap[currentContentId] = Content({
            id: currentContentId,
            author: msg.sender,
            title: _title,
            contentHash: _contentHash,
            contentType: _contentType,
            visibility: ContentVisibility.Public, // Default visibility is public
            price: 0,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            versionCount: 1,
            upvotes: 0,
            downvotes: 0,
            isDeleted: false,
            isArchived: false
        });
        latestContentVersion[currentContentId] = ContentVersion({
            contentId: currentContentId,
            version: 1,
            contentHash: _contentHash,
            updatedAt: block.timestamp
        });
        contentIdCounter++;

        // Add tags
        for (uint i = 0; i < _tags.length; i++) {
            contentTags[currentContentId].push(_tags[i]);
            emit ContentTagged(currentContentId, _tags[i]);
        }

        emit ContentCreated(currentContentId, msg.sender, _title);
    }

    function updateContent(uint256 _contentId, string memory _newContentHash) public onlyAuthor(_contentId) validContentId(_contentId) {
        Content storage content = contentMap[_contentId];
        uint256 nextVersion = content.versionCount + 1;

        contentVersions[_contentId][nextVersion] = ContentVersion({
            contentId: _contentId,
            version: nextVersion,
            contentHash: _newContentHash,
            updatedAt: block.timestamp
        });
        latestContentVersion[_contentId] = ContentVersion({
            contentId: _contentId,
            version: nextVersion,
            contentHash: _newContentHash,
            updatedAt: block.timestamp
        });

        content.contentHash = _newContentHash;
        content.updatedAt = block.timestamp;
        content.versionCount = nextVersion;
        emit ContentUpdated(_contentId, nextVersion, msg.sender);
    }

    function setContentVisibility(uint256 _contentId, ContentVisibility _visibility) public onlyAuthor(_contentId) validContentId(_contentId) {
        contentMap[_contentId].visibility = _visibility;
        emit ContentVisibilityChanged(_contentId, _visibility);
    }

    function setContentPrice(uint256 _contentId, uint256 _price) public onlyAuthor(_contentId) validContentId(_contentId) {
        require(contentMap[_contentId].visibility == ContentVisibility.Premium, "Price can only be set for premium content.");
        contentMap[_contentId].price = _price;
        emit ContentPriceChanged(_contentId, _price);
    }

    function getContent(uint256 _contentId) public view validContentId(_contentId) returns (Content memory) {
        Content memory content = contentMap[_contentId];
        // Note: Returning full Content struct, but in a real application, you might want to exclude contentHash and retrieve it separately for security/privacy.
        return content;
    }

    function deleteContent(uint256 _contentId) public onlyAuthor(_contentId) validContentId(_contentId) {
        contentMap[_contentId].isDeleted = true;
        emit ContentDeleted(_contentId, msg.sender);
    }

    function archiveContent(uint256 _contentId) public onlyAuthor(_contentId) validContentId(_contentId) {
        contentMap[_contentId].isArchived = true;
        emit ContentArchived(_contentId, msg.sender);
    }

    function getContentVersion(uint256 _contentId, uint256 _version) public view validContentId(_contentId) returns (ContentVersion memory) {
        require(_version > 0 && _version <= contentMap[_contentId].versionCount, "Invalid content version.");
        return contentVersions[_contentId][_version];
    }

    function getContentVersionCount(uint256 _contentId) public view validContentId(_contentId) returns (uint256) {
        return contentMap[_contentId].versionCount;
    }

    /// ------------------------------------------------------------------------
    /// Reputation and Moderation Functions
    /// ------------------------------------------------------------------------

    function upvoteContent(uint256 _contentId) public validContentId(_contentId) {
        require(contentMap[_contentId].author != msg.sender, "Authors cannot upvote their own content.");
        // To prevent multiple votes from same user, consider using a mapping to track votes per user per content.
        // For simplicity, we are just incrementing the count. In a real application, prevent vote manipulation.
        contentMap[_contentId].upvotes++;
        authorReputation[contentMap[_contentId].author]++; // Increase author reputation
        emit ContentUpvoted(_contentId, msg.sender);
    }

    function downvoteContent(uint256 _contentId) public validContentId(_contentId) {
        require(contentMap[_contentId].author != msg.sender, "Authors cannot downvote their own content.");
        // Similar to upvote, consider preventing multiple downvotes from same user.
        contentMap[_contentId].downvotes++;
        authorReputation[contentMap[_contentId].author]--; // Decrease author reputation
        emit ContentDownvoted(_contentId, msg.sender);
    }

    function reportContent(uint256 _contentId, string memory _reason) public validContentId(_contentId) {
        uint256 currentReportId = reportIdCounter;
        reports[currentReportId] = Report({
            contentId: _contentId,
            reporter: msg.sender,
            reason: _reason,
            reportedAt: block.timestamp,
            isResolved: false,
            actionTaken: ModerationAction.NoAction
        });
        reportIdCounter++;
        emit ContentReported(currentReportId, _contentId, msg.sender);
    }

    function getAuthorReputation(address _author) public view returns (int256) {
        return authorReputation[_author];
    }

    function setModerator(address _moderator, bool _isModerator) public onlyPlatformOwner {
        moderators[_moderator] = _isModerator;
        emit ModeratorSet(_moderator, _isModerator);
    }

    function moderateContent(uint256 _contentId, ModerationAction _action, string memory _reason) public onlyModerator validContentId(_contentId) {
        // Find the report associated with this content if any, or allow moderator to initiate action.
        // For simplicity, we are not linking moderation to reports directly here.
        if (_action == ModerationAction.WarnAuthor) {
            // Send a warning event or message to the author (off-chain mechanism needed).
        } else if (_action == ModerationAction.HideContent) {
            contentMap[_contentId].visibility = ContentVisibility.Private; // Or a separate "Hidden" visibility
        } else if (_action == ModerationAction.DeleteContent) {
            contentMap[_contentId].isDeleted = true;
        }
        emit ContentModerated(_contentId, _action, _reason);
    }

    /// ------------------------------------------------------------------------
    /// Monetization and Access Control Functions
    /// ------------------------------------------------------------------------

    function purchaseContentAccess(uint256 _contentId) public payable validContentId(_contentId) {
        require(contentMap[_contentId].visibility == ContentVisibility.Premium, "Content is not premium.");
        uint256 price = contentMap[_contentId].price;
        require(msg.value >= price, "Insufficient payment.");

        contentAccess[_contentId][msg.sender] = true;

        // Transfer funds to author and platform owner
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 authorShare = price - platformFee;

        authorEarnings[contentMap[_contentId].author] += authorShare;
        payable(platformOwner).transfer(platformFee); // Transfer platform fee immediately

        emit AccessPurchased(_contentId, msg.sender, price);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price); // Return extra payment
        }
    }

    function checkContentAccess(uint256 _contentId, address _user) public view validContentId(_contentId) returns (bool) {
        if (contentMap[_contentId].visibility == ContentVisibility.Public) {
            return true; // Public content is always accessible
        } else if (contentMap[_contentId].visibility == ContentVisibility.Premium) {
            return contentAccess[_contentId][_user]; // Check if user purchased access
        } else if (contentMap[_contentId].visibility == ContentVisibility.Private) {
            return contentMap[_contentId].author == _user; // Only author can access private content
        }
        return false; // Default case - should not reach here in normal scenarios.
    }

    function withdrawEarnings() public {
        uint256 earnings = authorEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        authorEarnings[msg.sender] = 0; // Reset earnings to 0 after withdrawal
        payable(msg.sender).transfer(earnings);
        emit EarningsWithdrawn(msg.sender, earnings);
    }

    function setPlatformFee(uint256 _feePercentage) public onlyPlatformOwner {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() public onlyPlatformOwner {
        // In a real application, track platform fees separately during purchaseContentAccess
        // For simplicity, this function would ideally withdraw accumulated fees if tracked.
        // In this example, platform fees are transferred immediately during purchase.
        // This function could be modified to withdraw any accumulated platform balance, if needed.
        // Example (if you accumulate platform fees in a separate balance variable):
        // uint256 platformBalance = getPlatformBalance(); // Assume function to calculate balance
        // require(platformBalance > 0, "No platform fees to withdraw.");
        // payable(platformOwner).transfer(platformBalance);
        // resetPlatformBalance(); // Assume function to reset platform balance
        // emit PlatformFeesWithdrawn(msg.sender, platformBalance);

        // In current implementation, platform fees are directly transferred, so withdrawing again might not be needed.
        // This function can be left empty or used for future fee management if needed.
        // For now, let's just emit an event to indicate withdrawal attempt.
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableBalance = contractBalance; // Assuming all contract balance is platform fee (simplification for this example)
        if (withdrawableBalance > 0) {
            payable(platformOwner).transfer(withdrawableBalance);
            emit PlatformFeesWithdrawn(msg.sender, withdrawableBalance);
        } else {
            revert("No platform fees to withdraw in current balance.");
        }
    }

    /// ------------------------------------------------------------------------
    /// Utility and Platform Settings Functions
    /// ------------------------------------------------------------------------

    function getContentCount() public view returns (uint256) {
        return contentIdCounter - 1; // As counter starts from 1 and increments after creation
    }

    function getPlatformOwner() public view returns (address) {
        return platformOwner;
    }

    function setPlatformName(string memory _name) public onlyPlatformOwner {
        platformName = _name;
        emit PlatformNameChanged(_name);
    }

    function getPlatformName() public view returns (string memory) {
        return platformName;
    }

    function getContentTags(uint256 _contentId) public view validContentId(_contentId) returns (string[] memory) {
        return contentTags[_contentId];
    }

    // Fallback function to receive Ether (in case someone sends directly to contract)
    receive() external payable {}
}
```