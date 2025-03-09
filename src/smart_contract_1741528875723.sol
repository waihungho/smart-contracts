```solidity
/**
 * @title Decentralized Social Platform with Dynamic Reputation and NFT Integration
 * @author Gemini AI (Example - Inspired by User Request)
 * @dev This contract simulates a decentralized social platform with advanced features like dynamic reputation,
 *      NFT profile integration, content monetization, decentralized moderation, and personalized feeds.
 *      It aims to showcase creative and trendy functionalities beyond basic social media contracts.
 *
 * Function Summary:
 *
 * 1.  registerUser(string _username, string _profileBio, string _profileImageUrl): Registers a new user with username, bio, and profile image.
 * 2.  updateProfile(string _newBio, string _newProfileImageUrl): Updates the user's profile bio and image URL.
 * 3.  setUsername(string _newUsername): Allows users to update their username (with checks for uniqueness).
 * 4.  createPost(string _content, string _contentType, string _metadataUri): Allows registered users to create posts with content, type, and metadata.
 * 5.  getPost(uint256 _postId): Retrieves a specific post by its ID.
 * 6.  likePost(uint256 _postId): Allows users to like a post, increasing the poster's reputation.
 * 7.  unlikePost(uint256 _postId): Allows users to unlike a post, potentially decreasing the poster's reputation.
 * 8.  commentOnPost(uint256 _postId, string _commentText): Allows users to comment on a post.
 * 9.  getPostComments(uint256 _postId): Retrieves comments for a specific post.
 * 10. followUser(address _userToFollow): Allows a user to follow another user.
 * 11. unfollowUser(address _userToUnfollow): Allows a user to unfollow another user.
 * 12. getFollowers(address _userAddress): Retrieves the list of followers for a user.
 * 13. getFollowing(address _userAddress): Retrieves the list of users a user is following.
 * 14. reportPost(uint256 _postId, string _reportReason): Allows users to report a post for moderation.
 * 15. moderatePost(uint256 _postId, bool _isApproved):  Owner-only function to moderate a reported post.
 * 16. setUserNFTProfile(address _nftContract, uint256 _tokenId): Allows users to set an NFT as their profile picture.
 * 17. getUserNFTProfile(address _userAddress): Retrieves the NFT profile details of a user.
 * 18. tipAuthor(uint256 _postId) payable: Allows users to tip post authors with Ether.
 * 19. getTrendingPosts(): Returns a list of post IDs sorted by likes in a time window (simulated trending).
 * 20. getPersonalizedFeed(): Returns a personalized feed based on followed users and liked content (simplified example).
 * 21. getReputationScore(address _userAddress): Retrieves the reputation score of a user.
 * 22. withdrawTips(): Allows contract owner to withdraw accumulated tips (for platform maintenance/development).
 * 23. setModerator(address _moderatorAddress, bool _isModerator): Owner-only function to assign/revoke moderator roles.
 * 24. isModerator(address _userAddress): Checks if an address has moderator role.
 */
pragma solidity ^0.8.0;

contract DecentralizedSocialPlatform {

    // --- Data Structures ---

    struct UserProfile {
        string username;
        string bio;
        string profileImageUrl;
        address nftProfileContract;
        uint256 nftProfileTokenId;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Post {
        uint256 postId;
        address author;
        string content;
        string contentType; // e.g., "text", "image", "video"
        string metadataUri; // IPFS hash or URL for richer content
        uint256 likes;
        uint256 createdAt;
        bool isModerated;
        bool isReported;
    }

    struct Comment {
        address commenter;
        string text;
        uint256 createdAt;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment[]) public postComments;
    mapping(address => mapping(address => bool)) public following; // User -> Followers
    mapping(address => address[]) public followersList; // User -> List of Followers
    mapping(address => address[]) public followingList; // User -> List of Following
    mapping(uint256 => address[]) public postLikes; // PostId -> List of likers
    mapping(uint256 => bool) public reportedPosts; // PostId -> Is Reported?
    mapping(address => bool) public moderators; // Address -> Is Moderator?

    uint256 public postCounter;
    address public owner;
    uint256 public totalTipsCollected;

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event UsernameUpdated(address userAddress, string newUsername);
    event PostCreated(uint256 postId, address author);
    event PostLiked(uint256 postId, address user);
    event PostUnliked(uint256 postId, address user);
    event CommentCreated(uint256 postId, address commenter);
    event UserFollowed(address follower, address followedUser);
    event UserUnfollowed(address follower, address unfollowedUser);
    event PostReported(uint256 postId, address reporter, string reason);
    event PostModerated(uint256 postId, bool isApproved, address moderator);
    event NFTProfileSet(address userAddress, address nftContract, uint256 tokenId);
    event TipReceived(uint256 postId, address tipper, uint256 amount);
    event ModeratorSet(address moderator, bool isModerator);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || msg.sender == owner, "Only moderator or owner can call this function");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        postCounter = 0;
    }

    // --- User Profile Functions ---

    function registerUser(string memory _username, string memory _profileBio, string memory _profileImageUrl) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        require(bytes(_username).length > 0 && bytes(_username).length <= 30, "Username must be 1-30 characters");
        require(isUsernameAvailable(_username), "Username already taken");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _profileBio,
            profileImageUrl: _profileImageUrl,
            nftProfileContract: address(0), // No NFT profile initially
            nftProfileTokenId: 0,
            reputationScore: 0,
            isRegistered: true
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _newBio, string memory _newProfileImageUrl) public onlyRegisteredUser {
        userProfiles[msg.sender].bio = _newBio;
        userProfiles[msg.sender].profileImageUrl = _newProfileImageUrl;
        emit ProfileUpdated(msg.sender);
    }

    function setUsername(string memory _newUsername) public onlyRegisteredUser {
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 30, "Username must be 1-30 characters");
        require(isUsernameAvailable(_newUsername), "Username already taken");
        string memory oldUsername = userProfiles[msg.sender].username;
        userProfiles[msg.sender].username = _newUsername;
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    function isUsernameAvailable(string memory _username) private view returns (bool) {
        for (address user in getUsers()) {
            if (keccak256(bytes(userProfiles[user].username)) == keccak256(bytes(_username))) {
                return false;
            }
        }
        return true;
    }

    function getUsers() private view returns (address[] memory) {
        address[] memory userList = new address[](0);
        uint256 index = 0;
        for (address userAddress in userProfiles) {
            if (userProfiles[userAddress].isRegistered) {
                address[] memory temp = new address[](index + 1);
                for (uint256 i = 0; i < index; i++) {
                    temp[i] = userList[i];
                }
                temp[index] = userAddress;
                userList = temp;
                index++;
            }
        }
        return userList;
    }


    // --- Post Functions ---

    function createPost(string memory _content, string memory _contentType, string memory _metadataUri) public onlyRegisteredUser {
        require(bytes(_content).length > 0 && bytes(_content).length <= 1000, "Post content must be 1-1000 characters");
        postCounter++;
        posts[postCounter] = Post({
            postId: postCounter,
            author: msg.sender,
            content: _content,
            contentType: _contentType,
            metadataUri: _metadataUri,
            likes: 0,
            createdAt: block.timestamp,
            isModerated: false,
            isReported: false
        });
        emit PostCreated(postCounter, msg.sender);
    }

    function getPost(uint256 _postId) public view returns (Post memory) {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        return posts[_postId];
    }

    function likePost(uint256 _postId) public onlyRegisteredUser {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(!isPostLikedByUser(_postId, msg.sender), "Post already liked");
        require(!posts[_postId].isModerated, "Post is moderated and cannot be liked");

        posts[_postId].likes++;
        postLikes[_postId].push(msg.sender);
        userProfiles[posts[_postId].author].reputationScore++; // Increase author's reputation
        emit PostLiked(_postId, msg.sender);
    }

    function unlikePost(uint256 _postId) public onlyRegisteredUser {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(isPostLikedByUser(_postId, msg.sender), "Post not liked");
        require(!posts[_postId].isModerated, "Post is moderated and cannot be unliked");

        posts[_postId].likes--;
        // Remove user from postLikes array (inefficient for large arrays, consider optimization for production)
        address[] storage likesArray = postLikes[_postId];
        for (uint256 i = 0; i < likesArray.length; i++) {
            if (likesArray[i] == msg.sender) {
                likesArray[i] = likesArray[likesArray.length - 1];
                likesArray.pop();
                break;
            }
        }
        if (userProfiles[posts[_postId].author].reputationScore > 0) { // Prevent negative reputation
            userProfiles[posts[_postId].author].reputationScore--; // Decrease author's reputation
        }
        emit PostUnliked(_postId, msg.sender);
    }

    function isPostLikedByUser(uint256 _postId, address _user) private view returns (bool) {
        address[] storage likesArray = postLikes[_postId];
        for (uint256 i = 0; i < likesArray.length; i++) {
            if (likesArray[i] == _user) {
                return true;
            }
        }
        return false;
    }


    function commentOnPost(uint256 _postId, string memory _commentText) public onlyRegisteredUser {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(bytes(_commentText).length > 0 && bytes(_commentText).length <= 500, "Comment must be 1-500 characters");
        require(!posts[_postId].isModerated, "Post is moderated and comments are disabled");

        postComments[_postId].push(Comment({
            commenter: msg.sender,
            text: _commentText,
            createdAt: block.timestamp
        }));
        emit CommentCreated(_postId, msg.sender);
    }

    function getPostComments(uint256 _postId) public view returns (Comment[] memory) {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        return postComments[_postId];
    }

    // --- Following Functions ---

    function followUser(address _userToFollow) public onlyRegisteredUser {
        require(_userToFollow != msg.sender, "Cannot follow yourself");
        require(userProfiles[_userToFollow].isRegistered, "User to follow is not registered");
        require(!following[msg.sender][_userToFollow], "Already following this user");

        following[msg.sender][_userToFollow] = true;
        followersList[_userToFollow].push(msg.sender);
        followingList[msg.sender].push(_userToFollow);
        emit UserFollowed(msg.sender, _userToFollow);
    }

    function unfollowUser(address _userToUnfollow) public onlyRegisteredUser {
        require(_userToUnfollow != msg.sender, "Cannot unfollow yourself");
        require(following[msg.sender][_userToUnfollow], "Not following this user");

        following[msg.sender][_userToFollow] = false;

        // Remove follower from followersList (inefficient, optimize in production)
        address[] storage followers = followersList[_userToUnfollow];
        for (uint256 i = 0; i < followers.length; i++) {
            if (followers[i] == msg.sender) {
                followers[i] = followers[followers.length - 1];
                followers.pop();
                break;
            }
        }
        // Remove followed user from followingList (inefficient, optimize in production)
        address[] storage followings = followingList[msg.sender];
        for (uint256 i = 0; i < followings.length; i++) {
            if (followings[i] == _userToUnfollow) {
                followings[i] = followings[followings.length - 1];
                followings.pop();
                break;
            }
        }

        emit UserUnfollowed(msg.sender, _userToFollow);
    }

    function getFollowers(address _userAddress) public view returns (address[] memory) {
        return followersList[_userAddress];
    }

    function getFollowing(address _userAddress) public view returns (address[] memory) {
        return followingList[_userAddress];
    }

    // --- Moderation Functions ---

    function reportPost(uint256 _postId, string memory _reportReason) public onlyRegisteredUser {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(!reportedPosts[_postId], "Post already reported");

        reportedPosts[_postId] = true;
        posts[_postId].isReported = true;
        emit PostReported(_postId, msg.sender, _reportReason);
    }

    function moderatePost(uint256 _postId, bool _isApproved) public onlyModerator {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(posts[_postId].isReported, "Post is not reported");

        posts[_postId].isModerated = !_isApproved; // If approved = false, then moderate (isModerated = true)
        posts[_postId].isReported = false; // Reset reported status
        reportedPosts[_postId] = false;
        emit PostModerated(_postId, _isApproved, msg.sender);
    }

    function setModerator(address _moderatorAddress, bool _isModerator) public onlyOwner {
        moderators[_moderatorAddress] = _isModerator;
        emit ModeratorSet(_moderatorAddress, _isModerator);
    }

    function isModerator(address _userAddress) public view returns (bool) {
        return moderators[_userAddress];
    }


    // --- NFT Profile Functions ---

    function setUserNFTProfile(address _nftContract, uint256 _tokenId) public onlyRegisteredUser {
        // Ideally, should check if the user actually owns the NFT. Requires external contract interaction (ERC721/1155 interface)
        // For simplicity, skipping ownership check in this example.
        userProfiles[msg.sender].nftProfileContract = _nftContract;
        userProfiles[msg.sender].nftProfileTokenId = _tokenId;
        emit NFTProfileSet(msg.sender, _nftContract, _tokenId);
    }

    function getUserNFTProfile(address _userAddress) public view returns (address, uint256) {
        return (userProfiles[_userAddress].nftProfileContract, userProfiles[_userAddress].nftProfileTokenId);
    }

    // --- Monetization Functions ---

    function tipAuthor(uint256 _postId) public payable onlyRegisteredUser {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(!posts[_postId].isModerated, "Post is moderated and cannot be tipped");
        require(msg.value > 0, "Tip amount must be greater than zero");

        address author = posts[_postId].author;
        payable(author).transfer(msg.value); // Transfer tip to author
        totalTipsCollected += msg.value;
        emit TipReceived(_postId, msg.sender, msg.value);
    }

    function withdrawTips() public onlyOwner {
        payable(owner).transfer(address(this).balance);
        totalTipsCollected = 0; // Reset collected tips after withdrawal
    }


    // --- Discovery & Feed Functions (Simplified Examples) ---

    function getTrendingPosts() public view returns (uint256[] memory) {
        // Simplified trending - based on likes within last 24 hours (example time window)
        uint256[] memory trendingPostIds = new uint256[](0);
        uint256 currentTime = block.timestamp;
        uint256 timeWindow = 24 * 3600; // 24 hours

        uint256[] memory allPostIds = getAllPostIds();
        uint256[] memory sortedPostIds = sortPostsByLikes(allPostIds);

        uint256 trendingCount = 0;
        for (uint256 i = 0; i < sortedPostIds.length; i++) {
            if (posts[sortedPostIds[i]].createdAt >= currentTime - timeWindow) {
                trendingCount++;
            }
        }

        trendingPostIds = new uint256[](trendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < sortedPostIds.length; i++) {
            if (posts[sortedPostIds[i]].createdAt >= currentTime - timeWindow) {
                 trendingPostIds[index] = sortedPostIds[i];
                 index++;
            }
        }

        return trendingPostIds;
    }

    function getAllPostIds() private view returns (uint256[] memory) {
        uint256[] memory postIds = new uint256[](postCounter);
        for (uint256 i = 1; i <= postCounter; i++) {
            postIds[i-1] = i;
        }
        return postIds;
    }

    function sortPostsByLikes(uint256[] memory _postIds) private view returns (uint256[] memory) {
        uint256 n = _postIds.length;
        uint256[] memory sortedIds = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            sortedIds[i] = _postIds[i];
        }

        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (posts[sortedIds[j]].likes < posts[sortedIds[j + 1]].likes) {
                    uint256 temp = sortedIds[j];
                    sortedIds[j] = sortedIds[j + 1];
                    sortedIds[j + 1] = temp;
                }
            }
        }
        return sortedIds;
    }


    function getPersonalizedFeed() public onlyRegisteredUser view returns (uint256[] memory) {
        // Simplified personalized feed - shows posts from followed users and liked posts (example logic)
        address[] memory followedUsers = followingList[msg.sender];
        uint256[] memory feedPostIds = new uint256[](0);
        uint256 index = 0;

        for (uint256 i = 1; i <= postCounter; i++) {
            if (!posts[i].isModerated) { // Exclude moderated posts from feed
                if (isPostLikedByUser(i, msg.sender)) { // Include liked posts
                    feedPostIds = _addToFeed(feedPostIds, index, i);
                    index++;
                } else {
                    for (uint256 j = 0; j < followedUsers.length; j++) {
                        if (posts[i].author == followedUsers[j]) { // Include posts from followed users
                            feedPostIds = _addToFeed(feedPostIds, index, i);
                            index++;
                            break; // Avoid adding same post multiple times if also liked
                        }
                    }
                }
            }
        }
        return feedPostIds;
    }

    function _addToFeed(uint256[] memory _feed, uint256 _index, uint256 _postId) private pure returns (uint256[] memory) {
        uint256[] memory tempFeed = new uint256[](_index + 1);
        for (uint256 k = 0; k < _index; k++) {
            tempFeed[k] = _feed[k];
        }
        tempFeed[_index] = _postId;
        return tempFeed;
    }


    // --- Reputation Function ---
    function getReputationScore(address _userAddress) public view returns (uint256) {
        return userProfiles[_userAddress].reputationScore;
    }

    // --- Fallback Function (Optional for receiving Ether directly) ---
    receive() external payable {}
}
```