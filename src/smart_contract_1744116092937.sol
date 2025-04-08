```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Social Media Platform (DecentraSocial)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized social media platform with advanced features.
 *
 * Outline and Function Summary:
 *
 * 1.  Platform Setup & Admin:
 *     - `initializePlatform(string _platformName, address _admin)`: Initializes the platform with a name and admin address. (Once-only setup)
 *     - `setPlatformFee(uint256 _fee)`: Sets the platform fee for certain actions. (Admin only)
 *     - `withdrawPlatformFees()`: Allows the admin to withdraw accumulated platform fees. (Admin only)
 *     - `pausePlatform()`: Pauses core platform functionalities. (Admin only)
 *     - `unpausePlatform()`: Resumes platform functionalities after pausing. (Admin only)
 *
 * 2.  User Profiles & Identities:
 *     - `createUserProfile(string _username, string _bio, string _profilePictureHash)`: Creates a user profile.
 *     - `updateUserProfile(string _bio, string _profilePictureHash)`: Updates an existing user profile.
 *     - `getUsername(address _user)`: Retrieves the username of a user.
 *     - `getProfileDetails(address _user)`: Retrieves detailed profile information of a user.
 *
 * 3.  Content Creation & Interaction:
 *     - `createPost(string _contentHash, string[] memory _tags, bool _isExclusive)`: Creates a new social media post.
 *     - `likePost(uint256 _postId)`: Allows a user to like a post.
 *     - `commentOnPost(uint256 _postId, string _commentHash)`: Allows a user to comment on a post.
 *     - `sharePost(uint256 _postId)`: Allows a user to share a post.
 *     - `reportPost(uint256 _postId, string _reportReason)`: Allows users to report inappropriate posts.
 *     - `getPostDetails(uint256 _postId)`: Retrieves detailed information about a specific post.
 *     - `getPostsByUser(address _user)`: Retrieves a list of post IDs created by a specific user.
 *
 * 4.  Subscription & Exclusive Content:
 *     - `subscribeToUser(address _creator)`: Allows a user to subscribe to another user for exclusive content.
 *     - `unsubscribeFromUser(address _creator)`: Allows a user to unsubscribe from a user.
 *     - `isSubscriber(address _subscriber, address _creator)`: Checks if a user is subscribed to another user.
 *     - `viewExclusivePost(uint256 _postId)`: Allows subscribers to view exclusive posts (requires subscription check).
 *
 * 5.  Trending & Discovery:
 *     - `getTrendingPosts(uint256 _limit)`: Retrieves a list of trending post IDs based on likes and shares.
 *     - `searchPostsByTag(string _tag)`: Retrieves a list of post IDs associated with a specific tag.
 *
 * 6.  Moderation & Governance (Basic):
 *     - `moderateReportedPost(uint256 _postId, bool _isRemoved)`: Admin function to moderate reported posts (e.g., remove or keep). (Admin only)
 *
 * 7.  Reputation System (Simple):
 *     - `upvoteUserReputation(address _user)`: Allows users to upvote another user's reputation (limited to prevent abuse).
 *     - `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 */

contract DecentraSocial {
    string public platformName;
    address public admin;
    uint256 public platformFee; // Fee for certain actions (e.g., exclusive posts, subscriptions - currently not used but can be extended)
    bool public platformPaused;

    uint256 public nextPostId;
    uint256 public nextUserId; // Not explicitly used in this version, but good for future scalability if needed

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment[]) public postComments;
    mapping(uint256 => mapping(address => bool)) public postLikes; // postId -> user -> liked?
    mapping(address => mapping(address => bool)) public userSubscriptions; // subscriber -> creator -> subscribed?
    mapping(string => uint256[]) public tagToPosts; // tag -> array of postIds
    mapping(address => uint256) public userReputation; // user -> reputation score
    mapping(uint256 => Report[]) public postReports; // postId -> reports array

    struct UserProfile {
        address userAddress;
        string username;
        string bio;
        string profilePictureHash;
        uint256 creationTimestamp;
    }

    struct Post {
        uint256 postId;
        address author;
        string contentHash;
        uint256 creationTimestamp;
        uint256 likeCount;
        uint256 shareCount;
        string[] tags;
        bool isExclusive;
    }

    struct Comment {
        address commenter;
        string commentHash;
        uint256 timestamp;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
    }

    event PlatformInitialized(string platformName, address admin);
    event PlatformFeeSet(uint256 fee);
    event PlatformPaused();
    event PlatformUnpaused();
    event FeesWithdrawn(address admin, uint256 amount);
    event ProfileCreated(address user, string username);
    event ProfileUpdated(address user);
    event PostCreated(uint256 postId, address author);
    event PostLiked(uint256 postId, address user);
    event PostCommented(uint256 postId, address user);
    event PostShared(uint256 postId, address user);
    event PostReported(uint256 postId, uint256 reportId, address reporter);
    event PostModerated(uint256 postId, bool isRemoved);
    event UserSubscribed(address subscriber, address creator);
    event UserUnsubscribed(address subscriber, address creator);
    event UserReputationUpvoted(address user, address upvoter);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier platformActive() {
        require(!platformPaused, "Platform is currently paused.");
        _;
    }

    modifier userProfileExists(address _user) {
        require(bytes(userProfiles[_user].username).length > 0, "User profile does not exist.");
        _;
    }

    modifier postExists(uint256 _postId) {
        require(posts[_postId].author != address(0), "Post does not exist.");
        _;
    }

    modifier isPostAuthor(uint256 _postId) {
        require(posts[_postId].author == msg.sender, "You are not the author of this post.");
        _;
    }

    modifier isSubscriberToCreator(address _creator) {
        require(userSubscriptions[msg.sender][_creator], "You are not subscribed to this creator.");
        _;
    }


    constructor() {
        // Platform is not initialized through constructor anymore.
        // Use initializePlatform function.
        platformName = "DecentraSocial (Uninitialized)";
        admin = msg.sender; // Default admin during deployment - should be changed in initializePlatform
        platformFee = 0;
        platformPaused = true; // Platform starts paused until initialized.
    }

    /// ------------------------ 1. Platform Setup & Admin Functions ------------------------

    /**
     * @dev Initializes the platform with a name and admin address. Can only be called once.
     * @param _platformName The name of the social media platform.
     * @param _admin The address of the platform administrator.
     */
    function initializePlatform(string memory _platformName, address _admin) external onlyAdmin {
        require(bytes(platformName).length <= 22 || bytes(platformName).length > 35, "Platform already initialized or name invalid length."); // Check if already initialized (basic check)
        platformName = _platformName;
        admin = _admin;
        platformPaused = false; // Start active after initialization
        emit PlatformInitialized(_platformName, _admin);
    }

    /**
     * @dev Sets the platform fee for certain actions (e.g., exclusive content, subscriptions - not currently used).
     * @param _fee The platform fee amount.
     */
    function setPlatformFee(uint256 _fee) external onlyAdmin {
        platformFee = _fee;
        emit PlatformFeeSet(_fee);
    }

    /**
     * @dev Allows the admin to withdraw accumulated platform fees (currently no fees are collected in this version).
     * @dev Placeholder function for future fee-based features.
     */
    function withdrawPlatformFees() external onlyAdmin {
        // In this version, no fees are collected, so this function is mostly a placeholder.
        // In a real application, you would track and collect fees and then withdraw them here.
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit FeesWithdrawn(admin, balance);
    }

    /**
     * @dev Pauses core platform functionalities.
     */
    function pausePlatform() external onlyAdmin {
        platformPaused = true;
        emit PlatformPaused();
    }

    /**
     * @dev Resumes platform functionalities after pausing.
     */
    function unpausePlatform() external onlyAdmin {
        platformPaused = false;
        emit PlatformUnpaused();
    }


    /// ------------------------ 2. User Profiles & Identities Functions ------------------------

    /**
     * @dev Creates a user profile.
     * @param _username The desired username.
     * @param _bio A short bio for the user profile.
     * @param _profilePictureHash Hash of the user's profile picture (e.g., IPFS hash).
     */
    function createUserProfile(string memory _username, string memory _bio, string memory _profilePictureHash) external platformActive {
        require(bytes(userProfiles[msg.sender].username).length == 0, "Profile already exists for this user.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 30, "Username must be between 1 and 30 characters.");
        require(bytes(_bio).length <= 200, "Bio cannot exceed 200 characters.");
        // Add more username validation if needed (e.g., uniqueness check - consider using mapping username -> address for efficient lookup)

        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            bio: _bio,
            profilePictureHash: _profilePictureHash,
            creationTimestamp: block.timestamp
        });
        emit ProfileCreated(msg.sender, _username);
    }

    /**
     * @dev Updates an existing user profile.
     * @param _bio New bio for the user profile.
     * @param _profilePictureHash New hash of the user's profile picture.
     */
    function updateUserProfile(string memory _bio, string memory _profilePictureHash) external platformActive userProfileExists(msg.sender) {
        require(bytes(_bio).length <= 200, "Bio cannot exceed 200 characters.");

        UserProfile storage profile = userProfiles[msg.sender];
        profile.bio = _bio;
        profile.profilePictureHash = _profilePictureHash;
        emit ProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves the username of a user.
     * @param _user The address of the user.
     * @return The username of the user.
     */
    function getUsername(address _user) external view userProfileExists(_user) returns (string memory) {
        return userProfiles[_user].username;
    }

    /**
     * @dev Retrieves detailed profile information of a user.
     * @param _user The address of the user.
     * @return UserProfile struct containing profile details.
     */
    function getProfileDetails(address _user) external view userProfileExists(_user) returns (UserProfile memory) {
        return userProfiles[_user];
    }


    /// ------------------------ 3. Content Creation & Interaction Functions ------------------------

    /**
     * @dev Creates a new social media post.
     * @param _contentHash Hash of the post content (e.g., IPFS hash).
     * @param _tags Array of tags associated with the post.
     * @param _isExclusive Boolean indicating if the post is exclusive for subscribers.
     */
    function createPost(string memory _contentHash, string[] memory _tags, bool _isExclusive) external platformActive userProfileExists(msg.sender) {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty.");
        require(_tags.length <= 10, "Maximum 10 tags allowed per post."); // Limit number of tags

        uint256 postId = nextPostId++;
        Post storage newPost = posts[postId];
        newPost.postId = postId;
        newPost.author = msg.sender;
        newPost.contentHash = _contentHash;
        newPost.creationTimestamp = block.timestamp;
        newPost.tags = _tags;
        newPost.isExclusive = _isExclusive;

        for (uint256 i = 0; i < _tags.length; i++) {
            tagToPosts[_tags[i]].push(postId);
        }

        emit PostCreated(postId, msg.sender);
    }

    /**
     * @dev Allows a user to like a post.
     * @param _postId The ID of the post to like.
     */
    function likePost(uint256 _postId) external platformActive userProfileExists(msg.sender) postExists(_postId) {
        require(!postLikes[_postId][msg.sender], "You have already liked this post.");
        postLikes[_postId][msg.sender] = true;
        posts[_postId].likeCount++;
        emit PostLiked(_postId, msg.sender);
    }

    /**
     * @dev Allows a user to comment on a post.
     * @param _postId The ID of the post to comment on.
     * @param _commentHash Hash of the comment content (e.g., IPFS hash).
     */
    function commentOnPost(uint256 _postId, string memory _commentHash) external platformActive userProfileExists(msg.sender) postExists(_postId) {
        require(bytes(_commentHash).length > 0, "Comment hash cannot be empty.");

        postComments[_postId].push(Comment({
            commenter: msg.sender,
            commentHash: _commentHash,
            timestamp: block.timestamp
        }));
        emit PostCommented(_postId, msg.sender);
    }

    /**
     * @dev Allows a user to share a post.
     * @param _postId The ID of the post to share.
     */
    function sharePost(uint256 _postId) external platformActive userProfileExists(msg.sender) postExists(_postId) {
        posts[_postId].shareCount++;
        emit PostShared(_postId, msg.sender);
    }

    /**
     * @dev Allows users to report inappropriate posts.
     * @param _postId The ID of the post to report.
     * @param _reportReason Reason for reporting the post.
     */
    function reportPost(uint256 _postId, string memory _reportReason) external platformActive userProfileExists(msg.sender) postExists(_postId) {
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 200, "Report reason must be between 1 and 200 characters.");

        postReports[_postId].push(Report({
            reporter: msg.sender,
            reason: _reportReason,
            timestamp: block.timestamp
        }));
        emit PostReported(_postId, postReports[_postId].length - 1, msg.sender); // Emit reportId as index in array
    }

    /**
     * @dev Retrieves detailed information about a specific post.
     * @param _postId The ID of the post.
     * @return Post struct containing post details.
     */
    function getPostDetails(uint256 _postId) external view postExists(_postId) returns (Post memory, Comment[] memory, Report[] memory) {
        return (posts[_postId], postComments[_postId], postReports[_postId]);
    }

    /**
     * @dev Retrieves a list of post IDs created by a specific user.
     * @param _user The address of the user.
     * @return Array of post IDs created by the user.
     */
    function getPostsByUser(address _user) external view userProfileExists(_user) returns (uint256[] memory) {
        uint256[] memory userPosts = new uint256[](nextPostId); // Over-allocate initially, then resize. Inefficient for very large number of posts.
        uint256 postCount = 0;
        for (uint256 i = 0; i < nextPostId; i++) {
            if (posts[i].author == _user) {
                userPosts[postCount] = i;
                postCount++;
            }
        }
        // Resize array to actual number of posts
        uint256[] memory resizedPosts = new uint256[](postCount);
        for (uint256 i = 0; i < postCount; i++) {
            resizedPosts[i] = userPosts[i];
        }
        return resizedPosts;
    }


    /// ------------------------ 4. Subscription & Exclusive Content Functions ------------------------

    /**
     * @dev Allows a user to subscribe to another user for exclusive content.
     * @param _creator The address of the creator to subscribe to.
     */
    function subscribeToUser(address _creator) external platformActive userProfileExists(msg.sender) userProfileExists(_creator) {
        require(msg.sender != _creator, "You cannot subscribe to yourself.");
        require(!userSubscriptions[msg.sender][_creator], "You are already subscribed to this user.");
        userSubscriptions[msg.sender][_creator] = true;
        emit UserSubscribed(msg.sender, _creator);
    }

    /**
     * @dev Allows a user to unsubscribe from a user.
     * @param _creator The address of the creator to unsubscribe from.
     */
    function unsubscribeFromUser(address _creator) external platformActive userProfileExists(msg.sender) userProfileExists(_creator) {
        require(userSubscriptions[msg.sender][_creator], "You are not subscribed to this user.");
        userSubscriptions[msg.sender][_creator] = false;
        emit UserUnsubscribed(msg.sender, _creator);
    }

    /**
     * @dev Checks if a user is subscribed to another user.
     * @param _subscriber The address of the subscriber.
     * @param _creator The address of the creator.
     * @return True if subscribed, false otherwise.
     */
    function isSubscriber(address _subscriber, address _creator) external view userProfileExists(_subscriber) userProfileExists(_creator) returns (bool) {
        return userSubscriptions[_subscriber][_creator];
    }

    /**
     * @dev Allows subscribers to view exclusive posts (requires subscription check).
     * @param _postId The ID of the exclusive post.
     * @return The content hash of the exclusive post if subscriber, otherwise reverts.
     */
    function viewExclusivePost(uint256 _postId) external view platformActive postExists(_postId) userProfileExists(msg.sender) isSubscriberToCreator(posts[_postId].author) returns (string memory) {
        require(posts[_postId].isExclusive, "This post is not exclusive.");
        return posts[_postId].contentHash;
    }


    /// ------------------------ 5. Trending & Discovery Functions ------------------------

    /**
     * @dev Retrieves a list of trending post IDs based on likes and shares.
     * @param _limit Maximum number of trending posts to return.
     * @return Array of trending post IDs (sorted by likes + shares).
     */
    function getTrendingPosts(uint256 _limit) external view platformActive returns (uint256[] memory) {
        uint256[] memory allPostIds = new uint256[](nextPostId);
        for (uint256 i = 0; i < nextPostId; i++) {
            allPostIds[i] = i;
        }

        // Basic sorting by (likes + shares) - could be improved with more sophisticated trending algorithms
        for (uint256 i = 0; i < nextPostId; i++) {
            for (uint256 j = i + 1; j < nextPostId; j++) {
                if (posts[allPostIds[i]].likeCount + posts[allPostIds[i]].shareCount < posts[allPostIds[j]].likeCount + posts[allPostIds[j]].shareCount) {
                    uint256 temp = allPostIds[i];
                    allPostIds[i] = allPostIds[j];
                    allPostIds[j] = temp;
                }
            }
        }

        uint256 returnLimit = _limit > nextPostId ? nextPostId : _limit;
        uint256[] memory trendingPosts = new uint256[](returnLimit);
        for (uint256 i = 0; i < returnLimit; i++) {
            trendingPosts[i] = allPostIds[i];
        }
        return trendingPosts;
    }

    /**
     * @dev Retrieves a list of post IDs associated with a specific tag.
     * @param _tag The tag to search for.
     * @return Array of post IDs with the given tag.
     */
    function searchPostsByTag(string memory _tag) external view platformActive returns (uint256[] memory) {
        return tagToPosts[_tag];
    }


    /// ------------------------ 6. Moderation & Governance (Basic) Functions ------------------------

    /**
     * @dev Admin function to moderate reported posts (e.g., remove or keep - in this version, removal is simulated by setting contentHash to empty).
     * @param _postId The ID of the post to moderate.
     * @param _isRemoved Boolean indicating if the post should be removed (true) or kept (false).
     */
    function moderateReportedPost(uint256 _postId, bool _isRemoved) external onlyAdmin postExists(_postId) {
        if (_isRemoved) {
            posts[_postId].contentHash = ""; // Simulating removal by emptying contentHash - in real app, might be more complex
        }
        emit PostModerated(_postId, _isRemoved);
    }


    /// ------------------------ 7. Reputation System (Simple) Functions ------------------------

    /**
     * @dev Allows users to upvote another user's reputation (limited to prevent abuse - simple rate limiting).
     * @param _user The address of the user to upvote.
     */
    function upvoteUserReputation(address _user) external platformActive userProfileExists(msg.sender) userProfileExists(_user) {
        require(msg.sender != _user, "You cannot upvote your own reputation.");
        require(block.timestamp - userProfiles[msg.sender].creationTimestamp > 1 days, "Users must be active for at least 1 day to upvote."); // Simple rate limiting - users need to be active for a while

        userReputation[_user]++;
        emit UserReputationUpvoted(_user, msg.sender);
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserReputation(address _user) external view userProfileExists(_user) returns (uint256) {
        return userReputation[_user];
    }
}
```