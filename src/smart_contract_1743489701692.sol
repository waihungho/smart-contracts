```solidity
/**
 * @title ContentVerse - Decentralized Content Creation and Monetization Platform
 * @author Gemini AI Assistant
 * @dev This smart contract implements a decentralized platform for content creators to upload, manage, and monetize their content.
 * It incorporates advanced concepts like subscription models, content licensing, collaboration, content bundles, voting, and basic content recommendation.
 * It aims to be a creative and feature-rich platform, distinct from existing open-source contracts.
 *
 * **Outline:**
 * 1. **Content Creation and Management:**
 *    - Create Content (with metadata, tags, license)
 *    - Get Content Metadata
 *    - Update Content Metadata (title, description, tags)
 *    - Set Content License
 *    - Add Content Tag
 *    - Remove Content Tag
 *    - Moderate Content (Admin only)
 * 2. **Monetization Features:**
 *    - Tip Creator
 *    - Subscribe to Creator (Recurring Subscriptions)
 *    - Cancel Subscription
 *    - Withdraw Earnings (Creator)
 *    - Purchase Content Bundle
 * 3. **Collaboration Features:**
 *    - Add Collaborator to Content
 *    - Remove Collaborator from Content
 *    - Get Content Collaborators
 * 4. **Content Discovery and Community Features:**
 *    - Get Content by Tag
 *    - Vote on Content (Upvote/Downvote)
 *    - Get Trending Content (Based on votes)
 *    - Report Content
 *    - Follow Creator
 *    - Get Creator Followers Count
 * 5. **User Profile Management:**
 *    - Set User Profile (Username, Bio)
 *    - Get User Profile
 * 6. **Platform Administration:**
 *    - Set Platform Fee (Percentage)
 *    - Withdraw Platform Fees (Admin only)
 *
 * **Function Summary:**
 * | Function Name                 | Description                                                                 |
 * |------------------------------|-----------------------------------------------------------------------------|
 * | `createContent`               | Allows creators to upload new content with metadata and tags.               |
 * | `getContentMetadata`          | Retrieves detailed metadata of a specific content.                          |
 * | `updateContentMetadata`       | Allows creators to modify title and description of their content.         |
 * | `setContentLicense`           | Sets a specific license type for content (e.g., Creative Commons).           |
 * | `addContentTag`               | Adds a tag to categorize content for better discovery.                       |
 * | `removeContentTag`            | Removes a tag from content.                                                  |
 * | `moderateContent`             | Admin function to approve or reject content based on moderation.          |
 * | `tipCreator`                  | Allows users to send tips to content creators for appreciation.              |
 * | `subscribeToCreator`          | Enables users to subscribe to creators for recurring access or support.      |
 * | `cancelSubscription`          | Allows users to cancel their subscriptions to creators.                    |
 * | `withdrawEarnings`            | Creators can withdraw their accumulated earnings from tips and subscriptions. |
 * | `purchaseContentBundle`       | Allows users to purchase a bundle of multiple content pieces at once.       |
 * | `addCollaborator`           | Allows content creators to add collaborators to their content.              |
 * | `removeCollaborator`        | Removes a collaborator from content.                                        |
 * | `getContentCollaborators`     | Retrieves the list of collaborators for a specific content.                |
 * | `getContentByTag`             | Fetches content IDs that are associated with a specific tag.               |
 * | `voteOnContent`               | Allows users to upvote or downvote content to influence trending.          |
 * | `getTrendingContent`          | Returns a list of content IDs considered trending based on votes.         |
 * | `reportContent`               | Allows users to report inappropriate or violating content.                  |
 * | `followCreator`               | Enables users to follow their favorite creators.                           |
 * | `getCreatorFollowersCount`    | Returns the number of followers a creator has.                              |
 * | `setUserProfile`              | Allows users to set up their profile with username and bio.                |
 * | `getUserProfile`              | Retrieves user profile information.                                         |
 * | `setPlatformFee`              | Admin function to set the platform's service fee percentage.               |
 * | `withdrawPlatformFees`        | Admin function to withdraw accumulated platform fees.                      |
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ContentVerse is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs ---
    struct Content {
        uint256 id;
        address creator;
        string title;
        string description;
        string contentHash; // IPFS hash, Arweave ID, etc.
        string licenseType;
        uint256 createdAt;
        bool isApproved; // For moderation
    }

    struct UserProfile {
        string username;
        string bio;
    }

    struct Subscription {
        address subscriber;
        uint256 expiryTime;
    }

    struct ContentBundle {
        uint256 id;
        string bundleName;
        uint256[] contentIds;
        address creator;
        uint256 createdAt;
    }

    // --- State Variables ---
    Counters.Counter private _contentCounter;
    Counters.Counter private _bundleCounter;

    mapping(uint256 => Content) public contentMap;
    mapping(uint256 => ContentBundle) public contentBundles;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => address[]) public contentCollaborators;
    mapping(uint256 => string[]) public contentTags;
    mapping(string => uint256[]) public tagToContentIds; // For efficient tag-based content retrieval
    mapping(address => mapping(address => Subscription)) public creatorSubscriptions; // Creator -> Subscriber -> Subscription
    mapping(uint256 => mapping(address => int256)) public contentVotes; // ContentId -> Voter -> Vote (1 for upvote, -1 for downvote)
    mapping(uint256 => uint256) public contentVoteScore; // ContentId -> Total Vote Score
    mapping(address => mapping(address => bool)) public creatorFollowers; // Creator -> Follower -> IsFollowing
    mapping(uint256 => address[]) public reportedContent; // ContentId -> Reporters

    uint256 public platformFeePercentage = 5; // Default platform fee percentage
    address payable public platformFeeWallet;

    // --- Events ---
    event ContentCreated(uint256 contentId, address creator, string title);
    event ContentUpdated(uint256 contentId, string title);
    event ContentLicensed(uint256 contentId, string licenseType);
    event ContentTagged(uint256 contentId, string tag);
    event ContentModerated(uint256 contentId, bool isApproved, address moderator);
    event TipReceived(uint256 contentId, address tipper, uint256 amount);
    event SubscriptionCreated(address creator, address subscriber, uint256 expiryTime);
    event SubscriptionCancelled(address creator, address subscriber);
    event EarningsWithdrawn(address creator, uint256 amount);
    event CollaboratorAdded(uint256 contentId, address collaborator);
    event CollaboratorRemoved(uint256 contentId, address collaborator);
    event ContentVoted(uint256 contentId, address voter, int256 vote);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event CreatorFollowed(address creator, address follower);
    event CreatorUnfollowed(address creator, address follower);
    event UserProfileUpdated(address user, string username);
    event PlatformFeeSet(uint256 percentage, address admin);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContentBundleCreated(uint256 bundleId, string bundleName, address creator);
    event ContentBundlePurchased(uint256 bundleId, address purchaser, uint256 amount);

    // --- Modifiers ---
    modifier contentExists(uint256 _contentId) {
        require(contentMap[_contentId].id != 0, "Content does not exist");
        _;
    }

    modifier onlyCreator(uint256 _contentId) {
        require(contentMap[_contentId].creator == msg.sender, "Only content creator allowed");
        _;
    }

    modifier validSubscription(address _creatorAddress) {
        require(creatorSubscriptions[_creatorAddress][msg.sender].expiryTime > block.timestamp, "Subscription expired or not active");
        _;
    }

    modifier onlyCollaborator(uint256 _contentId) {
        bool isCollaborator = false;
        for (uint256 i = 0; i < contentCollaborators[_contentId].length; i++) {
            if (contentCollaborators[_contentId][i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(contentMap[_contentId].creator == msg.sender || isCollaborator, "Not a creator or collaborator");
        _;
    }

    // --- Constructor ---
    constructor(address payable _platformFeeWallet) payable Ownable() {
        platformFeeWallet = _platformFeeWallet;
    }

    // --- 1. Content Creation and Management ---
    function createContent(
        string memory _title,
        string memory _description,
        string memory _contentHash,
        string memory _licenseType,
        string[] memory _tags
    ) public {
        _contentCounter.increment();
        uint256 contentId = _contentCounter.current();

        Content storage newContent = contentMap[contentId];
        newContent.id = contentId;
        newContent.creator = msg.sender;
        newContent.title = _title;
        newContent.description = _description;
        newContent.contentHash = _contentHash;
        newContent.licenseType = _licenseType;
        newContent.createdAt = block.timestamp;
        newContent.isApproved = false; // Needs admin approval

        for (uint256 i = 0; i < _tags.length; i++) {
            _addTagToContent(contentId, _tags[i]);
        }

        emit ContentCreated(contentId, msg.sender, _title);
    }

    function getContentMetadata(uint256 _contentId) public view contentExists(_contentId) returns (Content memory) {
        return contentMap[_contentId];
    }

    function updateContentMetadata(
        uint256 _contentId,
        string memory _title,
        string memory _description
    ) public contentExists(_contentId) onlyCreator(_contentId) {
        contentMap[_contentId].title = _title;
        contentMap[_contentId].description = _description;
        emit ContentUpdated(_contentId, _title);
    }

    function setContentLicense(uint256 _contentId, string memory _licenseType) public contentExists(_contentId) onlyCreator(_contentId) {
        contentMap[_contentId].licenseType = _licenseType;
        emit ContentLicensed(_contentId, _licenseType);
    }

    function addContentTag(uint256 _contentId, string memory _tag) public contentExists(_contentId) onlyCreator(_contentId) {
        _addTagToContent(_contentId, _tag);
        emit ContentTagged(_contentId, _tag);
    }

    function removeContentTag(uint256 _contentId, string memory _tag) public contentExists(_contentId) onlyCreator(_contentId) {
        _removeTagFromContent(_contentId, _tag);
    }

    function moderateContent(uint256 _contentId, bool _isApproved) public onlyOwner contentExists(_contentId) {
        contentMap[_contentId].isApproved = _isApproved;
        emit ContentModerated(_contentId, _isApproved, msg.sender);
    }

    // --- 2. Monetization Features ---
    function tipCreator(uint256 _contentId) public payable contentExists(_contentId) {
        require(contentMap[_contentId].isApproved, "Content is not yet approved");
        address payable creator = payable(contentMap[_contentId].creator);
        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 creatorAmount = msg.value - platformFee;

        (bool successCreator, ) = creator.call{value: creatorAmount}("");
        require(successCreator, "Tip transfer to creator failed");

        (bool successPlatform, ) = platformFeeWallet.call{value: platformFee}("");
        require(successPlatform, "Platform fee transfer failed");

        emit TipReceived(_contentId, msg.sender, msg.value);
    }

    function subscribeToCreator(address _creatorAddress, uint256 _subscriptionMonths) public payable {
        require(_creatorAddress != address(0) && _creatorAddress != msg.sender, "Invalid creator address");
        require(_subscriptionMonths > 0, "Subscription months must be greater than 0");
        uint256 subscriptionCost = 1 ether * _subscriptionMonths; // Example: 1 ETH per month
        require(msg.value >= subscriptionCost, "Insufficient subscription fee");

        uint256 expiryTime = block.timestamp + (_subscriptionMonths * 30 days); // Approximate month as 30 days

        creatorSubscriptions[_creatorAddress][msg.sender] = Subscription({
            subscriber: msg.sender,
            expiryTime: expiryTime
        });

        address payable creator = payable(_creatorAddress);
        uint256 platformFee = (subscriptionCost * platformFeePercentage) / 100;
        uint256 creatorAmount = subscriptionCost - platformFee;

        (bool successCreator, ) = creator.call{value: creatorAmount}("");
        require(successCreator, "Subscription payment to creator failed");

        (bool successPlatform, ) = platformFeeWallet.call{value: platformFee}("");
        require(successPlatform, "Platform fee transfer failed");

        emit SubscriptionCreated(_creatorAddress, msg.sender, expiryTime);
    }

    function cancelSubscription(address _creatorAddress) public {
        require(_creatorAddress != address(0) && _creatorAddress != msg.sender, "Invalid creator address");
        delete creatorSubscriptions[_creatorAddress][msg.sender];
        emit SubscriptionCancelled(_creatorAddress, msg.sender);
    }

    function withdrawEarnings() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No earnings to withdraw");
        uint256 amountToWithdraw = balance; // Creator withdraws all available balance
        payable(msg.sender).transfer(amountToWithdraw);
        emit EarningsWithdrawn(msg.sender, amountToWithdraw);
    }

    function purchaseContentBundle(uint256 _bundleId) public payable {
        require(contentBundles[_bundleId].id != 0, "Bundle does not exist");
        ContentBundle memory bundle = contentBundles[_bundleId];
        uint256 totalBundlePrice = bundle.contentIds.length * 0.5 ether; // Example price: 0.5 ETH per content in bundle
        require(msg.value >= totalBundlePrice, "Insufficient funds for bundle purchase");

        address payable creator = payable(bundle.creator);
        uint256 platformFee = (totalBundlePrice * platformFeePercentage) / 100;
        uint256 creatorAmount = totalBundlePrice - platformFee;

        (bool successCreator, ) = creator.call{value: creatorAmount}("");
        require(successCreator, "Bundle purchase payment to creator failed");

        (bool successPlatform, ) = platformFeeWallet.call{value: platformFee}("");
        require(successPlatform, "Platform fee transfer failed");

        emit ContentBundlePurchased(_bundleId, msg.sender, totalBundlePrice);
    }


    // --- 3. Collaboration Features ---
    function addCollaborator(uint256 _contentId, address _collaborator) public contentExists(_contentId) onlyCreator(_contentId) {
        require(_collaborator != address(0) && _collaborator != contentMap[_contentId].creator, "Invalid collaborator address");
        contentCollaborators[_contentId].push(_collaborator);
        emit CollaboratorAdded(_contentId, _collaborator);
    }

    function removeCollaborator(uint256 _contentId, address _collaborator) public contentExists(_contentId) onlyCreator(_contentId) {
        address[] storage collaborators = contentCollaborators[_contentId];
        for (uint256 i = 0; i < collaborators.length; i++) {
            if (collaborators[i] == _collaborator) {
                collaborators[i] = collaborators[collaborators.length - 1];
                collaborators.pop();
                emit CollaboratorRemoved(_contentId, _collaborator);
                return;
            }
        }
        revert("Collaborator not found");
    }

    function getContentCollaborators(uint256 _contentId) public view contentExists(_contentId) returns (address[] memory) {
        return contentCollaborators[_contentId];
    }

    // --- 4. Content Discovery and Community Features ---
    function getContentByTag(string memory _tag) public view returns (uint256[] memory) {
        return tagToContentIds[_tag];
    }

    function voteOnContent(uint256 _contentId, bool _upvote) public contentExists(_contentId) {
        require(contentMap[_contentId].isApproved, "Content is not yet approved");
        int256 voteValue = _upvote ? 1 : -1;

        if (contentVotes[_contentId][msg.sender] != 0) {
            // User has already voted, revert or update vote (for simplicity, we'll allow updating)
            contentVoteScore[_contentId] -= contentVotes[_contentId][msg.sender]; // Remove previous vote
        }
        contentVotes[_contentId][msg.sender] = voteValue;
        contentVoteScore[_contentId] += voteValue;

        emit ContentVoted(_contentId, msg.sender, voteValue);
    }

    function getTrendingContent() public view returns (uint256[] memory) {
        uint256[] memory trendingContentIds = new uint256[](_contentCounter.current()); // Max size, will trim later
        uint256 count = 0;
        for (uint256 i = 1; i <= _contentCounter.current(); i++) {
            if (contentMap[i].id != 0 && contentMap[i].isApproved && contentVoteScore[i] > 10) { // Example threshold: > 10 upvotes
                trendingContentIds[count] = i;
                count++;
            }
        }

        // Trim array to actual size
        uint256[] memory trimmedTrendingContentIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedTrendingContentIds[i] = trendingContentIds[i];
        }
        return trimmedTrendingContentIds;
    }

    function reportContent(uint256 _contentId, string memory _reason) public contentExists(_contentId) {
        reportedContent[_contentId].push(msg.sender);
        // In a real-world scenario, trigger off-chain moderation process based on reports
        emit ContentReported(_contentId, msg.sender, _reason);
    }

    function followCreator(address _creatorAddress) public {
        require(_creatorAddress != address(0) && _creatorAddress != msg.sender, "Invalid creator address");
        creatorFollowers[_creatorAddress][msg.sender] = true;
        emit CreatorFollowed(_creatorAddress, msg.sender);
    }

    function getCreatorFollowersCount(address _creatorAddress) public view returns (uint256) {
        uint256 followerCount = 0;
        address[] memory followers = _getCreatorFollowers(_creatorAddress);
        followerCount = followers.length;
        return followerCount;
    }

    function _getCreatorFollowers(address _creatorAddress) private view returns (address[] memory) {
        address[] memory followers = new address[](1000); // Assuming max 1000 followers for simplicity, adjust if needed
        uint256 followerIndex = 0;
        for (uint256 i = 0; i < _contentCounter.current() + 1; i++) { // Iterate over potential users (not efficient for large scale, consider better indexing)
            if (creatorFollowers[_creatorAddress][address(uint160(i))] == true) { // Iterate through all possible addresses (not efficient for large scale, consider better indexing)
                followers[followerIndex] = address(uint160(i));
                followerIndex++;
            }
        }
         // Trim array to actual size
        address[] memory trimmedFollowers = new address[](followerIndex);
        for (uint256 i = 0; i < followerIndex; i++) {
            trimmedFollowers[i] = followers[i];
        }
        return trimmedFollowers;
    }


    function unfollowCreator(address _creatorAddress) public {
        require(_creatorAddress != address(0) && _creatorAddress != msg.sender, "Invalid creator address");
        delete creatorFollowers[_creatorAddress][msg.sender];
        emit CreatorUnfollowed(_creatorAddress, msg.sender);
    }

    // --- 5. User Profile Management ---
    function setUserProfile(string memory _username, string memory _bio) public {
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio
        });
        emit UserProfileUpdated(msg.sender, _username);
    }

    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    // --- 6. Platform Administration ---
    function setPlatformFee(uint256 _percentage) public onlyOwner {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100");
        platformFeePercentage = _percentage;
        emit PlatformFeeSet(_percentage, msg.sender);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 platformBalance = address(this).balance;
        require(platformBalance > 0, "No platform fees to withdraw");
        uint256 amountToWithdraw = platformBalance;
        (bool success, ) = platformFeeWallet.call{value: amountToWithdraw}("");
        require(success, "Platform fee withdrawal failed");
        emit PlatformFeesWithdrawn(amountToWithdraw, msg.sender);
    }

    // --- 7. Content Bundles ---
    function createContentBundle(string memory _bundleName, uint256[] memory _contentIds) public {
        require(_contentIds.length > 0, "Bundle must contain at least one content");
        for (uint256 i = 0; i < _contentIds.length; i++) {
            require(contentMap[_contentIds[i]].creator == msg.sender, "Bundle can only contain your own content");
        }

        _bundleCounter.increment();
        uint256 bundleId = _bundleCounter.current();

        contentBundles[bundleId] = ContentBundle({
            id: bundleId,
            bundleName: _bundleName,
            contentIds: _contentIds,
            creator: msg.sender,
            createdAt: block.timestamp
        });

        emit ContentBundleCreated(bundleId, _bundleName, msg.sender);
    }

    function getContentBundleMetadata(uint256 _bundleId) public view returns (ContentBundle memory) {
        return contentBundles[_bundleId];
    }


    // --- Internal Helper Functions ---
    function _addTagToContent(uint256 _contentId, string memory _tag) private {
        contentTags[_contentId].push(_tag);
        tagToContentIds[_tag].push(_contentId);
    }

    function _removeTagFromContent(uint256 _contentId, string memory _tag) private {
        string[] storage tags = contentTags[_contentId];
        for (uint256 i = 0; i < tags.length; i++) {
            if (keccak256(bytes(tags[i])) == keccak256(bytes(_tag))) {
                tags[i] = tags[tags.length - 1];
                tags.pop();

                // Remove from tagToContentIds mapping as well
                uint256[] storage contentIdList = tagToContentIds[_tag];
                for (uint256 j = 0; j < contentIdList.length; j++) {
                    if (contentIdList[j] == _contentId) {
                        contentIdList[j] = contentIdList[contentIdList.length - 1];
                        contentIdList.pop();
                        break;
                    }
                }
                break;
            }
        }
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```