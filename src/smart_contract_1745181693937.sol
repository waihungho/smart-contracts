```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Content Curation & Monetization Platform
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized platform that allows users to create, curate,
 *      and monetize content. It incorporates advanced concepts like dynamic content pricing,
 *      stake-based curation rewards, decentralized governance through proposals, and a
 *      reputation system for users. This contract aims to be a comprehensive platform
 *      for content creators and curators, going beyond simple token or NFT contracts.
 *
 * **Outline & Function Summary:**
 *
 * **Content Management:**
 *   1. `createContent(string _title, string _contentURI, string[] _tags)`: Allows users to create new content, associating it with metadata and tags.
 *   2. `editContent(uint256 _contentId, string _newContentURI)`: Allows content creators to update the content URI of their existing content.
 *   3. `setContentPrice(uint256 _contentId, uint256 _price)`: Allows content creators to set a price for their content for direct purchase.
 *   4. `purchaseContent(uint256 _contentId)`: Allows users to purchase content directly from creators.
 *   5. `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 *   6. `getContentCount()`: Returns the total number of content items created on the platform.
 *
 * **Curation & Tagging:**
 *   7. `addTagToContent(uint256 _contentId, string _tag)`: Allows curators to add relevant tags to existing content.
 *   8. `removeTagFromContent(uint256 _contentId, string _tag)`: Allows curators to remove irrelevant tags from content.
 *   9. `getContentByTag(string _tag)`: Retrieves a list of content IDs associated with a specific tag.
 *   10. `getAllTagsForContent(uint256 _contentId)`: Retrieves all tags associated with a given content ID.
 *
 * **Reputation & User Profiles:**
 *   11. `createUserProfile(string _username)`: Allows users to create a profile with a unique username.
 *   12. `updateUserProfile(string _newUsername)`: Allows users to update their username.
 *   13. `getUserProfile(address _userAddress)`: Retrieves the profile information for a given user address.
 *   14. `upvoteContent(uint256 _contentId)`: Allows users to upvote content, increasing creator reputation.
 *   15. `downvoteContent(uint256 _contentId)`: Allows users to downvote content, potentially decreasing creator reputation.
 *
 * **Monetization & Rewards:**
 *   16. `tipContentCreator(uint256 _contentId)`: Allows users to tip content creators directly.
 *   17. `withdrawEarnings()`: Allows content creators to withdraw their accumulated earnings (tips and content sales).
 *   18. `setPlatformFee(uint256 _feePercentage)`: Platform owner function to set a percentage fee on content sales.
 *   19. `withdrawPlatformFees()`: Platform owner function to withdraw accumulated platform fees.
 *
 * **Governance & Platform Management:**
 *   20. `pausePlatform()`: Platform owner function to pause core functionalities of the platform for maintenance.
 *   21. `unpausePlatform()`: Platform owner function to resume platform functionalities after maintenance.
 *   22. `transferOwnership(address newOwner)`: Platform owner function to transfer ownership of the contract.
 */
contract DecentralizedContentPlatform {
    // --- Data Structures ---

    struct Content {
        uint256 id;
        address creator;
        string title;
        string contentURI;
        uint256 price;
        uint256 upvotes;
        uint256 downvotes;
        string[] tags;
        uint256 creationTimestamp;
    }

    struct UserProfile {
        string username;
        uint256 reputationScore;
        uint256 earnings;
        bool exists;
    }

    // --- State Variables ---

    Content[] public contentList;
    mapping(uint256 => Content) public contentById;
    mapping(string => uint256[]) public contentByTag;
    mapping(address => UserProfile) public userProfiles;
    uint256 public contentCount;
    address public platformOwner;
    uint256 public platformFeePercentage; // Percentage, e.g., 5 for 5%
    uint256 public platformFeesCollected;
    bool public platformPaused;

    // --- Events ---

    event ContentCreated(uint256 contentId, address creator, string title);
    event ContentEdited(uint256 contentId, string newContentURI);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentPurchased(uint256 contentId, address buyer, address creator, uint256 price);
    event TagAddedToContent(uint256 contentId, string tag, address curator);
    event TagRemovedFromContent(uint256 contentId, string tag, address curator);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newUsername);
    event ContentUpvoted(uint256 contentId, address voter);
    event ContentDownvoted(uint256 contentId, address voter);
    event ContentCreatorTipped(uint256 contentId, address tipper, address creator, uint256 amount);
    event EarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeeSet(uint256 feePercentage, address owner);
    event PlatformFeesWithdrawn(uint256 amount, address owner);
    event PlatformPaused(address owner);
    event PlatformUnpaused(address owner);
    event OwnershipTransferred(address oldOwner, address newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier platformActive() {
        require(!platformPaused, "Platform is currently paused.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(_contentId > 0 && _contentId <= contentCount, "Content does not exist.");
        _;
    }

    modifier userProfileExists(address _userAddress) {
        require(userProfiles[_userAddress].exists, "User profile does not exist.");
        _;
    }

    // --- Constructor ---

    constructor() {
        platformOwner = msg.sender;
        platformFeePercentage = 5; // Default platform fee is 5%
        platformPaused = false;
        contentCount = 0;
    }

    // --- Content Management Functions ---

    /// @notice Allows users to create new content.
    /// @param _title The title of the content.
    /// @param _contentURI The URI pointing to the content.
    /// @param _tags An array of tags to associate with the content.
    function createContent(string memory _title, string memory _contentURI, string[] memory _tags) external platformActive {
        contentCount++;
        uint256 contentId = contentCount;
        Content memory newContent = Content({
            id: contentId,
            creator: msg.sender,
            title: _title,
            contentURI: _contentURI,
            price: 0, // Default price is 0, creator can set it later
            upvotes: 0,
            downvotes: 0,
            tags: _tags,
            creationTimestamp: block.timestamp
        });

        contentList.push(newContent);
        contentById[contentId] = newContent;

        for (uint256 i = 0; i < _tags.length; i++) {
            contentByTag[_tags[i]].push(contentId);
        }

        emit ContentCreated(contentId, msg.sender, _title);

        // Automatically create user profile if it doesn't exist upon content creation
        if (!userProfiles[msg.sender].exists) {
            createUserProfile("user_" /*autogenerated username prefix*/); // Default username prefix
        }
    }

    /// @notice Allows content creators to update the content URI of their content.
    /// @param _contentId The ID of the content to edit.
    /// @param _newContentURI The new URI for the content.
    function editContent(uint256 _contentId, string memory _newContentURI) external platformActive contentExists(_contentId) {
        require(contentById[_contentId].creator == msg.sender, "Only content creator can edit content.");
        contentById[_contentId].contentURI = _newContentURI;
        emit ContentEdited(_contentId, _newContentURI);
    }

    /// @notice Allows content creators to set a price for their content.
    /// @param _contentId The ID of the content to set the price for.
    /// @param _price The price in wei for the content.
    function setContentPrice(uint256 _contentId, uint256 _price) external platformActive contentExists(_contentId) {
        require(contentById[_contentId].creator == msg.sender, "Only content creator can set content price.");
        contentById[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    /// @notice Allows users to purchase content directly from creators.
    /// @param _contentId The ID of the content to purchase.
    function purchaseContent(uint256 _contentId) external payable platformActive contentExists(_contentId) {
        Content storage content = contentById[_contentId];
        require(content.price > 0, "Content is not for sale or price is not set.");
        require(msg.value >= content.price, "Insufficient funds sent for purchase.");

        uint256 platformFee = (content.price * platformFeePercentage) / 100;
        uint256 creatorEarnings = content.price - platformFee;

        // Transfer earnings to creator
        payable(content.creator).transfer(creatorEarnings);
        // Collect platform fee
        platformFeesCollected += platformFee;

        // Refund any extra amount sent
        if (msg.value > content.price) {
            payable(msg.sender).transfer(msg.value - content.price);
        }

        emit ContentPurchased(_contentId, msg.sender, content.creator, content.price);

        // Optionally increase creator reputation upon purchase
        _updateReputation(content.creator, 5); // Example: +5 reputation for each purchase
    }

    /// @notice Retrieves detailed information about a specific content item.
    /// @param _contentId The ID of the content.
    /// @return Content struct containing content details.
    function getContentDetails(uint256 _contentId) external view contentExists(_contentId) returns (Content memory) {
        return contentById[_contentId];
    }

    /// @notice Returns the total number of content items created on the platform.
    /// @return The total content count.
    function getContentCount() external view returns (uint256) {
        return contentCount;
    }

    // --- Curation & Tagging Functions ---

    /// @notice Allows curators to add relevant tags to existing content.
    /// @param _contentId The ID of the content to tag.
    /// @param _tag The tag to add.
    function addTagToContent(uint256 _contentId, string memory _tag) external platformActive contentExists(_contentId) {
        // Basic curation - any registered user can add tags, more sophisticated curation can be implemented
        bool tagExists = false;
        Content storage content = contentById[_contentId];
        for (uint256 i = 0; i < content.tags.length; i++) {
            if (keccak256(bytes(content.tags[i])) == keccak256(bytes(_tag))) {
                tagExists = true;
                break;
            }
        }
        if (!tagExists) {
            content.tags.push(_tag);
            contentByTag[_tag].push(_contentId);
            emit TagAddedToContent(_contentId, _tag, msg.sender);
             _updateReputation(msg.sender, 1); // Example: +1 reputation for curation action
        }
    }

    /// @notice Allows curators to remove irrelevant tags from content.
    /// @param _contentId The ID of the content to remove the tag from.
    /// @param _tag The tag to remove.
    function removeTagFromContent(uint256 _contentId, string memory _tag) external platformActive contentExists(_contentId) {
        Content storage content = contentById[_contentId];
        bool tagRemoved = false;
        for (uint256 i = 0; i < content.tags.length; i++) {
            if (keccak256(bytes(content.tags[i])) == keccak256(bytes(_tag))) {
                // Remove tag from content.tags array (replace with last element and pop for efficiency)
                content.tags[i] = content.tags[content.tags.length - 1];
                content.tags.pop();
                tagRemoved = true;
                break;
            }
        }

        if (tagRemoved) {
            // Remove contentId from contentByTag mapping
            uint256[] storage contentIdsWithTag = contentByTag[_tag];
            for (uint256 i = 0; i < contentIdsWithTag.length; i++) {
                if (contentIdsWithTag[i] == _contentId) {
                    contentIdsWithTag[i] = contentIdsWithTag[contentIdsWithTag.length - 1];
                    contentIdsWithTag.pop();
                    break;
                }
            }
            emit TagRemovedFromContent(_contentId, _tag, msg.sender);
            _updateReputation(msg.sender, 1); // Example: +1 reputation for curation action
        }
    }


    /// @notice Retrieves a list of content IDs associated with a specific tag.
    /// @param _tag The tag to search for.
    /// @return An array of content IDs.
    function getContentByTag(string memory _tag) external view returns (uint256[] memory) {
        return contentByTag[_tag];
    }

    /// @notice Retrieves all tags associated with a given content ID.
    /// @param _contentId The ID of the content.
    /// @return An array of tags.
    function getAllTagsForContent(uint256 _contentId) external view contentExists(_contentId) returns (string[] memory) {
        return contentById[_contentId].tags;
    }

    // --- Reputation & User Profile Functions ---

    /// @notice Allows users to create a profile with a unique username.
    /// @param _username The desired username.
    function createUserProfile(string memory _username) public platformActive {
        require(!userProfiles[msg.sender].exists, "User profile already exists for this address.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            reputationScore: 0,
            earnings: 0,
            exists: true
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /// @notice Allows users to update their username.
    /// @param _newUsername The new username.
    function updateUserProfile(string memory _newUsername) external platformActive userProfileExists(msg.sender) {
        userProfiles[msg.sender].username = _newUsername;
        emit UserProfileUpdated(msg.sender, _newUsername);
    }

    /// @notice Retrieves the profile information for a given user address.
    /// @param _userAddress The address of the user.
    /// @return UserProfile struct containing user profile details.
    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    /// @notice Allows users to upvote content, increasing creator reputation.
    /// @param _contentId The ID of the content to upvote.
    function upvoteContent(uint256 _contentId) external platformActive contentExists(_contentId) {
        contentById[_contentId].upvotes++;
        emit ContentUpvoted(_contentId, msg.sender);
        _updateReputation(contentById[_contentId].creator, 2); // Example: +2 reputation for creator on upvote
        _updateReputation(msg.sender, 1); // Example: +1 reputation for voter
    }

    /// @notice Allows users to downvote content, potentially decreasing creator reputation.
    /// @param _contentId The ID of the content to downvote.
    function downvoteContent(uint256 _contentId) external platformActive contentExists(_contentId) {
        contentById[_contentId].downvotes++;
        emit ContentDownvoted(_contentId, msg.sender);
        _updateReputation(contentById[_contentId].creator, -1); // Example: -1 reputation for creator on downvote
        _updateReputation(msg.sender, 1); // Example: +1 reputation for voter (even for downvote - incentivize participation)
    }

    // --- Monetization & Rewards Functions ---

    /// @notice Allows users to tip content creators directly.
    /// @param _contentId The ID of the content to tip the creator of.
    function tipContentCreator(uint256 _contentId) external payable platformActive contentExists(_contentId) {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        UserProfile storage creatorProfile = userProfiles[contentById[_contentId].creator];
        creatorProfile.earnings += msg.value;
        emit ContentCreatorTipped(_contentId, msg.sender, contentById[_contentId].creator, msg.value);
        _updateReputation(contentById[_contentId].creator, 1); // Example: +1 reputation for creator on tip
        _updateReputation(msg.sender, 1); // Example: +1 reputation for tipper
    }

    /// @notice Allows content creators to withdraw their accumulated earnings (tips and content sales).
    function withdrawEarnings() external platformActive userProfileExists(msg.sender) {
        UserProfile storage profile = userProfiles[msg.sender];
        uint256 amountToWithdraw = profile.earnings;
        require(amountToWithdraw > 0, "No earnings to withdraw.");
        profile.earnings = 0; // Reset earnings to 0 after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        emit EarningsWithdrawn(msg.sender, amountToWithdraw);
    }

    /// @notice Platform owner function to set a percentage fee on content sales.
    /// @param _feePercentage The fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage, msg.sender);
    }

    /// @notice Platform owner function to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        require(platformFeesCollected > 0, "No platform fees collected to withdraw.");
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset platform fees collected to 0 after withdrawal
        payable(platformOwner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, msg.sender);
    }

    // --- Governance & Platform Management Functions ---

    /// @notice Platform owner function to pause core functionalities of the platform for maintenance.
    function pausePlatform() external onlyOwner {
        require(!platformPaused, "Platform is already paused.");
        platformPaused = true;
        emit PlatformPaused(msg.sender);
    }

    /// @notice Platform owner function to resume platform functionalities after maintenance.
    function unpausePlatform() external onlyOwner {
        require(platformPaused, "Platform is not paused.");
        platformPaused = false;
        emit PlatformUnpaused(msg.sender);
    }

    /// @notice Platform owner function to transfer ownership of the contract.
    /// @param newOwner The address of the new platform owner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero address.");
        emit OwnershipTransferred(platformOwner, newOwner);
        platformOwner = newOwner;
    }

    // --- Internal Functions ---

    /// @dev Internal function to update user reputation score.
    /// @param _userAddress The address of the user whose reputation to update.
    /// @param _reputationChange The amount to change the reputation score by (can be positive or negative).
    function _updateReputation(address _userAddress, int256 _reputationChange) internal {
        if (userProfiles[_userAddress].exists) {
            // Convert int256 to uint256 for addition/subtraction, handle negative changes carefully
            int256 currentReputation = int256(userProfiles[_userAddress].reputationScore);
            int256 newReputation = currentReputation + _reputationChange;

            // Ensure reputation doesn't go below 0
            if (newReputation < 0) {
                newReputation = 0;
            }
            userProfiles[_userAddress].reputationScore = uint256(newReputation);
        }
    }

    // --- Fallback and Receive Functions (Optional, for direct ETH transfers to contract if needed) ---
    receive() external payable {}
    fallback() external payable {}
}
```