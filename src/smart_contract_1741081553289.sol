```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Content Platform with Decentralized Curation and Monetization
 * @author Bard (AI Assistant)
 * @dev A smart contract for a platform that allows creators to publish dynamic content (text, images, data feeds),
 *      decentralized curation by community voting, and various monetization models for creators.
 *
 * **Outline and Function Summary:**
 *
 * **Content Management:**
 * 1. `createContent(string memory _contentType, string memory _initialContentURI, string memory _metadataURI)`: Allows creators to publish new content with content type, initial URI, and metadata URI.
 * 2. `updateContentURI(uint256 _contentId, string memory _newContentURI)`: Allows creators to update the URI of their content.
 * 3. `setContentMetadataURI(uint256 _contentId, string memory _newMetadataURI)`: Allows creators to update the metadata URI of their content.
 * 4. `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 * 5. `getContentCount()`: Returns the total number of content items created on the platform.
 * 6. `getContentCreator(uint256 _contentId)`: Returns the address of the creator of a specific content item.
 * 7. `getContentType(uint256 _contentId)`: Returns the content type of a specific content item.
 * 8. `getContentURI(uint256 _contentId)`: Returns the current content URI of a specific content item.
 * 9. `getMetadataURI(uint256 _contentId)`: Returns the metadata URI of a specific content item.
 * 10. `isContentActive(uint256 _contentId)`: Checks if a content item is currently active (not flagged or removed).
 *
 * **Curation and Voting:**
 * 11. `upvoteContent(uint256 _contentId)`: Allows users to upvote content.
 * 12. `downvoteContent(uint256 _contentId)`: Allows users to downvote content.
 * 13. `getContentVotes(uint256 _contentId)`: Returns the upvote and downvote counts for a specific content item.
 * 14. `getUserVote(uint256 _contentId, address _user)`: Returns the vote status (upvoted, downvoted, or none) of a user for a specific content item.
 * 15. `flagContent(uint256 _contentId, string memory _reason)`: Allows users to flag content for review, providing a reason. (Requires moderation to remove)
 *
 * **Monetization and Access Control:**
 * 16. `setContentSubscriptionFee(uint256 _contentId, uint256 _fee)`: Allows creators to set a subscription fee for their content.
 * 17. `subscribeToContent(uint256 _contentId)`: Allows users to subscribe to content by paying the subscription fee.
 * 18. `isSubscribed(uint256 _contentId, address _user)`: Checks if a user is subscribed to a specific content item.
 * 19. `withdrawCreatorEarnings(uint256 _contentId)`: Allows creators to withdraw their earnings from subscriptions.
 * 20. `setPlatformFee(uint256 _feePercentage)`: Allows the platform owner to set a platform fee percentage on subscriptions.
 * 21. `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees.
 * 22. `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 * 23. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 24. `setModerator(address _moderatorAddress)`: Allows the contract owner to set a moderator address.
 * 25. `removeContent(uint256 _contentId)`: Allows the moderator to remove flagged content.
 * 26. `getContractBalance()`:  Returns the contract's current Ether balance.
 * 27. `getVersion()`: Returns the contract version.
 */
contract DynamicContentPlatform {
    // State variables
    address public owner;
    address public moderator;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public contentCount = 0;
    bool public paused = false;

    struct Content {
        address creator;
        string contentType;
        string contentURI;
        string metadataURI;
        uint256 upvotes;
        uint256 downvotes;
        uint256 subscriptionFee;
        uint256 earnings;
        bool isActive;
    }

    mapping(uint256 => Content) public contents;
    mapping(uint256 => mapping(address => VoteStatus)) public userVotes;
    mapping(uint256 => address[]) public subscribers;
    mapping(uint256 => string[]) public flaggedReasons;

    enum VoteStatus {
        NONE,
        UPVOTED,
        DOWNVOTED
    }

    // Events
    event ContentCreated(uint256 contentId, address creator, string contentType, string contentURI);
    event ContentURIUpdated(uint256 contentId, string newContentURI);
    event ContentMetadataURIUpdated(uint256 contentId, string newMetadataURI);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event ContentFlagged(uint256 contentId, address user, string reason);
    event ContentSubscriptionFeeSet(uint256 contentId, uint256 fee);
    event ContentSubscribed(uint256 contentId, address user);
    event CreatorEarningsWithdrawn(uint256 contentId, address creator, uint256 amount);
    event PlatformFeePercentageSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ContractPaused(address owner);
    event ContractUnpaused(address owner);
    event ModeratorSet(address moderatorAddress);
    event ContentRemoved(uint256 contentId, address moderator);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator, "Only moderator can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(_contentId < contentCount && contents[_contentId].creator != address(0), "Content does not exist.");
        _;
    }

    modifier onlyContentCreator(uint256 _contentId) {
        require(contents[_contentId].creator == msg.sender, "Only content creator can call this function.");
        _;
    }


    // Constructor
    constructor() {
        owner = msg.sender;
        moderator = msg.sender; // Initially owner is also the moderator
    }

    /**
     * @dev Returns the contract version.
     * @return string Contract version.
     */
    function getVersion() public pure returns (string memory) {
        return "1.0";
    }

    /**
     * @dev Returns the contract's current Ether balance.
     * @return uint256 Contract balance in Wei.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    /**
     * @dev Allows creators to publish new content.
     * @param _contentType Type of the content (e.g., "article", "image", "data-feed").
     * @param _initialContentURI URI pointing to the content itself (e.g., IPFS hash, URL).
     * @param _metadataURI URI pointing to the content metadata (e.g., title, description).
     */
    function createContent(
        string memory _contentType,
        string memory _initialContentURI,
        string memory _metadataURI
    ) public whenNotPaused {
        contents[contentCount] = Content({
            creator: msg.sender,
            contentType: _contentType,
            contentURI: _initialContentURI,
            metadataURI: _metadataURI,
            upvotes: 0,
            downvotes: 0,
            subscriptionFee: 0, // Default to free
            earnings: 0,
            isActive: true
        });
        emit ContentCreated(contentCount, msg.sender, _contentType, _initialContentURI);
        contentCount++;
    }

    /**
     * @dev Allows creators to update the URI of their content.
     * @param _contentId ID of the content to update.
     * @param _newContentURI New URI for the content.
     */
    function updateContentURI(uint256 _contentId, string memory _newContentURI) public whenNotPaused contentExists(_contentId) onlyContentCreator(_contentId) {
        contents[_contentId].contentURI = _newContentURI;
        emit ContentURIUpdated(_contentId, _newContentURI);
    }

    /**
     * @dev Allows creators to update the metadata URI of their content.
     * @param _contentId ID of the content to update.
     * @param _newMetadataURI New metadata URI for the content.
     */
    function setContentMetadataURI(uint256 _contentId, string memory _newMetadataURI) public whenNotPaused contentExists(_contentId) onlyContentCreator(_contentId) {
        contents[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataURIUpdated(_contentId, _newMetadataURI);
    }

    /**
     * @dev Retrieves detailed information about a specific content item.
     * @param _contentId ID of the content to retrieve.
     * @return Content struct containing content details.
     */
    function getContentDetails(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (Content memory) {
        return contents[_contentId];
    }

    /**
     * @dev Returns the total number of content items created on the platform.
     * @return uint256 Total content count.
     */
    function getContentCount() public view whenNotPaused returns (uint256) {
        return contentCount;
    }

    /**
     * @dev Returns the address of the creator of a specific content item.
     * @param _contentId ID of the content.
     * @return address Creator's address.
     */
    function getContentCreator(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (address) {
        return contents[_contentId].creator;
    }

    /**
     * @dev Returns the content type of a specific content item.
     * @param _contentId ID of the content.
     * @return string Content type.
     */
    function getContentType(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (string memory) {
        return contents[_contentId].contentType;
    }

    /**
     * @dev Returns the current content URI of a specific content item.
     * @param _contentId ID of the content.
     * @return string Content URI.
     */
    function getContentURI(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (string memory) {
        return contents[_contentId].contentURI;
    }

    /**
     * @dev Returns the metadata URI of a specific content item.
     * @param _contentId ID of the content.
     * @return string Metadata URI.
     */
    function getMetadataURI(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (string memory) {
        return contents[_contentId].metadataURI;
    }

    /**
     * @dev Checks if a content item is currently active.
     * @param _contentId ID of the content.
     * @return bool True if content is active, false otherwise.
     */
    function isContentActive(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (bool) {
        return contents[_contentId].isActive;
    }

    /**
     * @dev Allows users to upvote content.
     * @param _contentId ID of the content to upvote.
     */
    function upvoteContent(uint256 _contentId) public whenNotPaused contentExists(_contentId) {
        require(userVotes[_contentId][msg.sender] != VoteStatus.UPVOTED, "You have already upvoted this content.");
        if (userVotes[_contentId][msg.sender] == VoteStatus.DOWNVOTED) {
            contents[_contentId].downvotes--; // Remove downvote if previously downvoted
        }
        contents[_contentId].upvotes++;
        userVotes[_contentId][msg.sender] = VoteStatus.UPVOTED;
        emit ContentUpvoted(_contentId, msg.sender);
    }

    /**
     * @dev Allows users to downvote content.
     * @param _contentId ID of the content to downvote.
     */
    function downvoteContent(uint256 _contentId) public whenNotPaused contentExists(_contentId) {
        require(userVotes[_contentId][msg.sender] != VoteStatus.DOWNVOTED, "You have already downvoted this content.");
        if (userVotes[_contentId][msg.sender] == VoteStatus.UPVOTED) {
            contents[_contentId].upvotes--; // Remove upvote if previously upvoted
        }
        contents[_contentId].downvotes++;
        userVotes[_contentId][msg.sender] = VoteStatus.DOWNVOTED;
        emit ContentDownvoted(_contentId, msg.sender);
    }

    /**
     * @dev Returns the upvote and downvote counts for a specific content item.
     * @param _contentId ID of the content.
     * @return uint256 Upvote count, uint256 Downvote count.
     */
    function getContentVotes(uint256 _contentId) public view whenNotPaused contentExists(_contentId) returns (uint256 upvotes, uint256 downvotes) {
        return (contents[_contentId].upvotes, contents[_contentId].downvotes);
    }

    /**
     * @dev Returns the vote status of a user for a specific content item.
     * @param _contentId ID of the content.
     * @param _user Address of the user.
     * @return VoteStatus User's vote status (NONE, UPVOTED, DOWNVOTED).
     */
    function getUserVote(uint256 _contentId, address _user) public view whenNotPaused contentExists(_contentId) returns (VoteStatus) {
        return userVotes[_contentId][_user];
    }

    /**
     * @dev Allows users to flag content for review by moderators.
     * @param _contentId ID of the content to flag.
     * @param _reason Reason for flagging the content.
     */
    function flagContent(uint256 _contentId, string memory _reason) public whenNotPaused contentExists(_contentId) {
        flaggedReasons[_contentId].push(_reason); // Store reasons, could be improved with more detailed reporting
        emit ContentFlagged(_contentId, msg.sender, _reason);
    }

    /**
     * @dev Allows creators to set a subscription fee for their content.
     * @param _contentId ID of the content.
     * @param _fee Subscription fee in Wei.
     */
    function setContentSubscriptionFee(uint256 _contentId, uint256 _fee) public whenNotPaused contentExists(_contentId) onlyContentCreator(_contentId) {
        contents[_contentId].subscriptionFee = _fee;
        emit ContentSubscriptionFeeSet(_contentId, _fee);
    }

    /**
     * @dev Allows users to subscribe to content by paying the subscription fee.
     * @param _contentId ID of the content to subscribe to.
     */
    function subscribeToContent(uint256 _contentId) public payable whenNotPaused contentExists(_contentId) {
        require(contents[_contentId].subscriptionFee > 0, "Content is not subscribable.");
        require(msg.value >= contents[_contentId].subscriptionFee, "Insufficient subscription fee.");
        require(!isSubscribed(_contentId, msg.sender), "Already subscribed to this content.");

        subscribers[_contentId].push(msg.sender);
        contents[_contentId].earnings += contents[_contentId].subscriptionFee * (100 - platformFeePercentage) / 100; // Creator earnings after platform fee
        payable(owner).transfer(contents[_contentId].subscriptionFee * platformFeePercentage / 100); // Platform fee
        emit ContentSubscribed(_contentId, msg.sender);
    }

    /**
     * @dev Checks if a user is subscribed to a specific content item.
     * @param _contentId ID of the content.
     * @param _user Address of the user.
     * @return bool True if subscribed, false otherwise.
     */
    function isSubscribed(uint256 _contentId, address _user) public view whenNotPaused contentExists(_contentId) returns (bool) {
        for (uint256 i = 0; i < subscribers[_contentId].length; i++) {
            if (subscribers[_contentId][i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Allows creators to withdraw their accumulated earnings from subscriptions.
     * @param _contentId ID of the content.
     */
    function withdrawCreatorEarnings(uint256 _contentId) public whenNotPaused contentExists(_contentId) onlyContentCreator(_contentId) {
        uint256 amountToWithdraw = contents[_contentId].earnings;
        require(amountToWithdraw > 0, "No earnings to withdraw.");
        contents[_contentId].earnings = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        emit CreatorEarningsWithdrawn(_contentId, msg.sender, amountToWithdraw);
    }

    /**
     * @dev Allows the platform owner to set the platform fee percentage for subscriptions.
     * @param _feePercentage New platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 platformBalance = address(this).balance;
        uint256 creatorEarningsSum = 0;
        for(uint256 i = 0; i < contentCount; i++) {
            creatorEarningsSum += contents[i].earnings;
        }
        uint256 withdrawablePlatformFees = platformBalance - creatorEarningsSum;

        require(withdrawablePlatformFees > 0, "No platform fees to withdraw.");
        payable(owner).transfer(withdrawablePlatformFees);
        emit PlatformFeesWithdrawn(owner, withdrawablePlatformFees);
    }


    /**
     * @dev Allows the contract owner to pause the contract in case of emergency.
     */
    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused(owner);
    }

    /**
     * @dev Allows the contract owner to unpause the contract.
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused(owner);
    }

    /**
     * @dev Allows the contract owner to set a moderator address.
     * @param _moderatorAddress Address of the new moderator.
     */
    function setModerator(address _moderatorAddress) public onlyOwner {
        require(_moderatorAddress != address(0), "Moderator address cannot be zero address.");
        moderator = _moderatorAddress;
        emit ModeratorSet(_moderatorAddress);
    }

    /**
     * @dev Allows the moderator to remove flagged content.
     * @param _contentId ID of the content to remove.
     */
    function removeContent(uint256 _contentId) public onlyModerator whenNotPaused contentExists(_contentId) {
        contents[_contentId].isActive = false; // Mark as inactive instead of deleting data
        emit ContentRemoved(_contentId, msg.sender);
    }
}
```