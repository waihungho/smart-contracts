```solidity
/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized content platform with dynamic features,
 *      advanced functionalities, and trendy concepts.  This contract allows users to
 *      create, interact with, and monetize content in innovative ways.

 * Function Summary:

 * **Core Content Management:**
 * 1.  `createContent(string _contentHash, string _metadataURI, string[] _tags)`: Allows users to create new content on the platform.
 * 2.  `editContent(uint256 _contentId, string _newContentHash, string _newMetadataURI, string[] _newTags)`: Allows content creators to edit their existing content.
 * 3.  `deleteContent(uint256 _contentId)`: Allows content creators to delete their content (with potential governance restrictions).
 * 4.  `getContent(uint256 _contentId)`: Retrieves content details by its ID.
 * 5.  `getContentByAuthor(address _author)`: Retrieves a list of content IDs created by a specific author.
 * 6.  `getContentByTag(string _tag)`: Retrieves a list of content IDs associated with a specific tag.
 * 7.  `getAllContent()`: Retrieves a list of all content IDs on the platform.

 * **User Interaction & Engagement:**
 * 8.  `likeContent(uint256 _contentId)`: Allows users to like content.
 * 9.  `unlikeContent(uint256 _contentId)`: Allows users to unlike content.
 * 10. `getContentLikesCount(uint256 _contentId)`: Retrieves the number of likes for a specific content.
 * 11. `commentOnContent(uint256 _contentId, string _comment)`: Allows users to comment on content.
 * 12. `getContentComments(uint256 _contentId)`: Retrieves comments for a specific content ID.
 * 13. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.

 * **Monetization & Rewards:**
 * 14. `tipContentCreator(uint256 _contentId)`: Allows users to tip content creators with native tokens.
 * 15. `setContentSubscriptionPrice(uint256 _contentId, uint256 _price)`: Allows content creators to set a subscription price for their content.
 * 16. `subscribeToContent(uint256 _contentId)`: Allows users to subscribe to premium content.
 * 17. `isSubscriber(uint256 _contentId, address _user)`: Checks if a user is subscribed to specific content.
 * 18. `withdrawCreatorEarnings()`: Allows content creators to withdraw their accumulated earnings (tips, subscriptions).

 * **Advanced Features & Platform Management:**
 * 19. `addContentTag(uint256 _contentId, string _tag)`: Allows content creators to add new tags to their content (potentially admin-controlled in a real-world scenario).
 * 20. `removeContentTag(uint256 _contentId, string _tag)`: Allows content creators to remove tags from their content (potentially admin-controlled).
 * 21. `platformFeePercentage()`: Returns the current platform fee percentage (can be dynamically adjustable via governance).
 * 22. `setPlatformFeePercentage(uint256 _newFeePercentage)`: Allows the platform owner/governance to set the platform fee percentage.
 * 23. `getContentCreator(uint256 _contentId)`: Retrieves the creator address of a specific content.
 * 24. `getContentTags(uint256 _contentId)`: Retrieves the tags associated with a specific content.
 * 25. `getContentCreationTimestamp(uint256 _contentId)`: Retrieves the timestamp of when content was created.
 * 26. `getContentLastEditedTimestamp(uint256 _contentId)`: Retrieves the timestamp of the last edit for content.
 * 27. `getContentStatus(uint256 _contentId)`: Retrieves the status of content (e.g., active, deleted, reported - for future moderation).
 * 28. `pauseContract()`: Allows the contract owner to pause core functionalities in case of emergency.
 * 29. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 30. `isContractPaused()`: Checks if the contract is currently paused.


 *  This contract is designed to be extensible and can be further enhanced with features like:
 *  - Decentralized moderation and content curation mechanisms.
 *  - Integration with IPFS or other decentralized storage solutions for content hashes.
 *  - Advanced subscription tiers and content access control.
 *  - DAO governance for platform parameters and feature upgrades.
 *  - NFT integration for content ownership and monetization.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DecentralizedContentPlatform is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _contentIdCounter;

    // Struct to represent content
    struct Content {
        uint256 id;
        address creator;
        string contentHash; // Hash of the content stored off-chain (e.g., IPFS hash)
        string metadataURI; // URI for content metadata (e.g., JSON file)
        string[] tags;
        uint256 creationTimestamp;
        uint256 lastEditedTimestamp;
        uint256 subscriptionPrice; // 0 for free content
        ContentStatus status;
    }

    enum ContentStatus { Active, Deleted, Reported }

    // Mappings to store content and related data
    mapping(uint256 => Content) public contentMap;
    mapping(uint256 => address[]) private _contentLikes;
    mapping(uint256 => string[]) private _contentComments;
    mapping(uint256 => address[]) private _contentSubscribers;
    mapping(address => uint256) private _creatorEarnings; // Total earnings for each creator
    mapping(uint256 => address) private _contentCreator; // Map contentId to creator address for quick lookup
    mapping(uint256 => ContentStatus) private _contentStatus;

    uint256 public platformFeePercentage = 5; // Platform fee percentage (e.g., 5% of tips/subscriptions)

    event ContentCreated(uint256 contentId, address creator, string contentHash);
    event ContentEdited(uint256 contentId, address editor, string newContentHash);
    event ContentDeleted(uint256 contentId, address deleter);
    event ContentLiked(uint256 contentId, address liker);
    event ContentUnliked(uint256 contentId, address unliker);
    event ContentCommented(uint256 contentId, address commenter, string comment);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentTipped(uint256 contentId, address tipper, uint256 amount);
    event ContentSubscriptionSet(uint256 contentId, uint256 price);
    event ContentSubscribed(uint256 contentId, address subscriber);
    event EarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeePercentageUpdated(uint256 newPercentage);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);


    modifier nonZeroContentId(uint256 _contentId) {
        require(_contentId != 0, "Content ID cannot be zero.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(_contentIdCounter.current() >= _contentId && _contentId > 0 && contentMap[_contentId].id == _contentId, "Content does not exist.");
        _;
    }

    modifier onlyContentCreator(uint256 _contentId) {
        require(msg.sender == contentMap[_contentId].creator, "Only content creator can perform this action.");
        _;
    }

    modifier onlySubscriber(uint256 _contentId) {
        require(isSubscriber(_contentId, msg.sender), "Must be a subscriber to access this content.");
        _;
    }

    modifier notDeletedContent(uint256 _contentId) {
        require(contentMap[_contentId].status != ContentStatus.Deleted, "Content is deleted and cannot be interacted with.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused.");
        _;
    }


    // 1. Create Content
    function createContent(string memory _contentHash, string memory _metadataURI, string[] memory _tags)
        public
        whenNotPaused
        returns (uint256 contentId)
    {
        _contentIdCounter.increment();
        contentId = _contentIdCounter.current();

        Content storage newContent = contentMap[contentId];
        newContent.id = contentId;
        newContent.creator = msg.sender;
        newContent.contentHash = _contentHash;
        newContent.metadataURI = _metadataURI;
        newContent.tags = _tags;
        newContent.creationTimestamp = block.timestamp;
        newContent.lastEditedTimestamp = block.timestamp;
        newContent.subscriptionPrice = 0; // Default to free content
        newContent.status = ContentStatus.Active;

        _contentCreator[contentId] = msg.sender;
        _contentStatus[contentId] = ContentStatus.Active;

        emit ContentCreated(contentId, msg.sender, _contentHash);
        return contentId;
    }

    // 2. Edit Content
    function editContent(uint256 _contentId, string memory _newContentHash, string memory _newMetadataURI, string[] memory _newTags)
        public
        whenNotPaused
        contentExists(_contentId)
        onlyContentCreator(_contentId)
        returns (bool)
    {
        contentMap[_contentId].contentHash = _newContentHash;
        contentMap[_contentId].metadataURI = _newMetadataURI;
        contentMap[_contentId].tags = _newTags;
        contentMap[_contentId].lastEditedTimestamp = block.timestamp;

        emit ContentEdited(_contentId, msg.sender, _newContentHash);
        return true;
    }

    // 3. Delete Content
    function deleteContent(uint256 _contentId)
        public
        whenNotPaused
        contentExists(_contentId)
        onlyContentCreator(_contentId)
        returns (bool)
    {
        contentMap[_contentId].status = ContentStatus.Deleted;
        _contentStatus[_contentId] = ContentStatus.Deleted; // Update status mapping too for consistency

        emit ContentDeleted(_contentId, msg.sender);
        return true;
    }

    // 4. Get Content
    function getContent(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (Content memory)
    {
        return contentMap[_contentId];
    }

    // 5. Get Content by Author
    function getContentByAuthor(address _author)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory contentIds = new uint256[](_contentIdCounter.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _contentIdCounter.current(); i++) {
            if (_contentCreator[i] == _author) {
                contentIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of content IDs found
        assembly {
            mstore(contentIds, count) // Update the length prefix of the dynamic array
        }
        return contentIds;
    }

    // 6. Get Content by Tag
    function getContentByTag(string memory _tag)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory contentIds = new uint256[](_contentIdCounter.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _contentIdCounter.current(); i++) {
            for (uint256 j = 0; j < contentMap[i].tags.length; j++) {
                if (keccak256(bytes(contentMap[i].tags[j])) == keccak256(bytes(_tag))) {
                    contentIds[count] = i;
                    count++;
                    break; // Move to the next content once a tag match is found
                }
            }
        }
        assembly {
            mstore(contentIds, count)
        }
        return contentIds;
    }

    // 7. Get All Content
    function getAllContent()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory contentIds = new uint256[](_contentIdCounter.current());
        for (uint256 i = 1; i <= _contentIdCounter.current(); i++) {
            contentIds[i-1] = i;
        }
        return contentIds;
    }

    // 8. Like Content
    function likeContent(uint256 _contentId)
        public
        whenNotPaused
        contentExists(_contentId)
        notDeletedContent(_contentId)
        returns (bool)
    {
        address[] storage likes = _contentLikes[_contentId];
        for (uint256 i = 0; i < likes.length; i++) {
            if (likes[i] == msg.sender) {
                return false; // Already liked
            }
        }
        likes.push(msg.sender);
        emit ContentLiked(_contentId, msg.sender);
        return true;
    }

    // 9. Unlike Content
    function unlikeContent(uint256 _contentId)
        public
        whenNotPaused
        contentExists(_contentId)
        notDeletedContent(_contentId)
        returns (bool)
    {
        address[] storage likes = _contentLikes[_contentId];
        for (uint256 i = 0; i < likes.length; i++) {
            if (likes[i] == msg.sender) {
                likes[i] = likes[likes.length - 1]; // Replace with last element for efficiency
                likes.pop();
                emit ContentUnliked(_contentId, msg.sender);
                return true;
            }
        }
        return false; // Not liked before
    }

    // 10. Get Content Likes Count
    function getContentLikesCount(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (uint256)
    {
        return _contentLikes[_contentId].length;
    }

    // 11. Comment on Content
    function commentOnContent(uint256 _contentId, string memory _comment)
        public
        whenNotPaused
        contentExists(_contentId)
        notDeletedContent(_contentId)
        returns (bool)
    {
        _contentComments[_contentId].push(_comment);
        emit ContentCommented(_contentId, msg.sender, _comment);
        return true;
    }

    // 12. Get Content Comments
    function getContentComments(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (string[] memory)
    {
        return _contentComments[_contentId];
    }

    // 13. Report Content
    function reportContent(uint256 _contentId, string memory _reportReason)
        public
        whenNotPaused
        contentExists(_contentId)
        notDeletedContent(_contentId)
        returns (bool)
    {
        contentMap[_contentId].status = ContentStatus.Reported;
        _contentStatus[_contentId] = ContentStatus.Reported; // Update status mapping
        emit ContentReported(_contentId, msg.sender, _reportReason);
        // In a real application, trigger moderation process here (e.g., emit event for off-chain moderator)
        return true;
    }

    // 14. Tip Content Creator
    function tipContentCreator(uint256 _contentId)
        public
        payable
        whenNotPaused
        contentExists(_contentId)
        notDeletedContent(_contentId)
        returns (bool)
    {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        address creator = contentMap[_contentId].creator;
        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 creatorAmount = msg.value - platformFee;

        _creatorEarnings[creator] += creatorAmount;
        payable(owner()).transfer(platformFee); // Platform fee goes to owner (or designated platform address)

        emit ContentTipped(_contentId, msg.sender, msg.value);
        return true;
    }

    // 15. Set Content Subscription Price
    function setContentSubscriptionPrice(uint256 _contentId, uint256 _price)
        public
        whenNotPaused
        contentExists(_contentId)
        onlyContentCreator(_contentId)
        returns (bool)
    {
        contentMap[_contentId].subscriptionPrice = _price;
        emit ContentSubscriptionSet(_contentId, _price);
        return true;
    }

    // 16. Subscribe to Content
    function subscribeToContent(uint256 _contentId)
        public
        payable
        whenNotPaused
        contentExists(_contentId)
        notDeletedContent(_contentId)
        returns (bool)
    {
        uint256 subscriptionPrice = contentMap[_contentId].subscriptionPrice;
        require(subscriptionPrice > 0, "Content is not subscription-based.");
        require(msg.value >= subscriptionPrice, "Insufficient subscription fee.");

        address creator = contentMap[_contentId].creator;
        uint256 platformFee = (subscriptionPrice * platformFeePercentage) / 100;
        uint256 creatorAmount = subscriptionPrice - platformFee;

        _creatorEarnings[creator] += creatorAmount;
        payable(owner()).transfer(platformFee);

        _contentSubscribers[_contentId].push(msg.sender);
        emit ContentSubscribed(_contentId, msg.sender);
        return true;
    }

    // 17. Is Subscriber
    function isSubscriber(uint256 _contentId, address _user)
        public
        view
        contentExists(_contentId)
        returns (bool)
    {
        for (uint256 i = 0; i < _contentSubscribers[_contentId].length; i++) {
            if (_contentSubscribers[_contentId][i] == _user) {
                return true;
            }
        }
        return false;
    }

    // 18. Withdraw Creator Earnings
    function withdrawCreatorEarnings()
        public
        whenNotPaused
        returns (bool)
    {
        uint256 earnings = _creatorEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        _creatorEarnings[msg.sender] = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(earnings);
        emit EarningsWithdrawn(msg.sender, earnings);
        return true;
    }

    // 19. Add Content Tag
    function addContentTag(uint256 _contentId, string memory _tag)
        public
        whenNotPaused
        contentExists(_contentId)
        onlyContentCreator(_contentId)
        returns (bool)
    {
        contentMap[_contentId].tags.push(_tag);
        return true;
    }

    // 20. Remove Content Tag
    function removeContentTag(uint256 _contentId, string memory _tag)
        public
        whenNotPaused
        contentExists(_contentId)
        onlyContentCreator(_contentId)
        returns (bool)
    {
        string[] storage tags = contentMap[_contentId].tags;
        for (uint256 i = 0; i < tags.length; i++) {
            if (keccak256(bytes(tags[i])) == keccak256(bytes(_tag))) {
                tags[i] = tags[tags.length - 1];
                tags.pop();
                return true;
            }
        }
        return false; // Tag not found
    }

    // 21. Platform Fee Percentage
    function platformFeePercentage()
        public
        view
        returns (uint256)
    {
        return platformFeePercentage;
    }

    // 22. Set Platform Fee Percentage
    function setPlatformFeePercentage(uint256 _newFeePercentage)
        public
        whenNotPaused
         onlyOwner
        returns (bool)
    {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageUpdated(_newFeePercentage);
        return true;
    }

    // 23. Get Content Creator
    function getContentCreator(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (address)
    {
        return _contentCreator[_contentId];
    }

    // 24. Get Content Tags
    function getContentTags(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (string[] memory)
    {
        return contentMap[_contentId].tags;
    }

    // 25. Get Content Creation Timestamp
    function getContentCreationTimestamp(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (uint256)
    {
        return contentMap[_contentId].creationTimestamp;
    }

    // 26. Get Content Last Edited Timestamp
    function getContentLastEditedTimestamp(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (uint256)
    {
        return contentMap[_contentId].lastEditedTimestamp;
    }

    // 27. Get Content Status
    function getContentStatus(uint256 _contentId)
        public
        view
        contentExists(_contentId)
        returns (ContentStatus)
    {
        return _contentStatus[_contentId];
    }

    // 28. Pause Contract
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    // 29. Unpause Contract
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // 30. Is Contract Paused
    function isContractPaused() public view returns (bool) {
        return paused();
    }

    // Fallback function to reject direct ether transfers (for security best practices)
    receive() external payable {
        revert("Direct ether transfers are not allowed. Use tipContentCreator or subscribeToContent.");
    }

    fallback() external {}
}
```