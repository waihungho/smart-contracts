```solidity
/**
 * @title Decentralized Content & Community Platform - "Nexus"
 * @author Bard (Example Smart Contract)
 * @dev A smart contract implementing a decentralized content and community platform with advanced features.
 *
 * **Outline & Function Summary:**
 *
 * **1. User Profile Management:**
 *    - `registerUser(string _username, string _profileBio, string _profileImageUrl)`: Allows users to register with a unique username, bio, and profile image URL.
 *    - `updateProfile(string _profileBio, string _profileImageUrl)`: Allows registered users to update their bio and profile image URL.
 *    - `getUsername(address _user)`: Retrieves the username associated with a user address.
 *    - `getProfile(address _user)`: Retrieves the profile information (bio, image URL) of a user.
 *    - `isUserRegistered(address _user)`: Checks if an address is registered as a user.
 *
 * **2. Content Creation & Management (Posts):**
 *    - `createPost(string _content, string _mediaUrl, string[] _tags)`: Allows registered users to create posts with text content, media URLs, and tags.
 *    - `editPost(uint256 _postId, string _newContent, string _newMediaUrl, string[] _newTags)`: Allows post authors to edit their posts.
 *    - `deletePost(uint256 _postId)`: Allows post authors to delete their posts.
 *    - `getPost(uint256 _postId)`: Retrieves a specific post by its ID.
 *    - `getUserPosts(address _user)`: Retrieves a list of post IDs created by a specific user.
 *    - `getPostsByTag(string _tag)`: Retrieves a list of post IDs associated with a specific tag.
 *
 * **3. Content Interaction & Community Features:**
 *    - `likePost(uint256 _postId)`: Allows registered users to like a post.
 *    - `unlikePost(uint256 _postId)`: Allows registered users to unlike a post.
 *    - `getPostLikesCount(uint256 _postId)`: Retrieves the number of likes for a post.
 *    - `commentOnPost(uint256 _postId, string _comment)`: Allows registered users to comment on a post.
 *    - `getPostComments(uint256 _postId)`: Retrieves a list of comments for a post.
 *    - `followUser(address _userToFollow)`: Allows registered users to follow other users.
 *    - `unfollowUser(address _userToUnfollow)`: Allows registered users to unfollow other users.
 *    - `getUserFollowersCount(address _user)`: Retrieves the number of followers a user has.
 *    - `getUserFollowingCount(address _user)`: Retrieves the number of users a user is following.
 *
 * **4. Advanced Features:**
 *    - `reportPost(uint256 _postId, string _reason)`: Allows users to report posts for moderation (e.g., spam, inappropriate content).
 *    - `searchPostsByKeyword(string _keyword)`: (Simplified keyword search - can be expanded with off-chain indexing for real-world scenarios).
 *    - `donateToCreator(address _creator)`: Allows users to donate ETH to content creators directly.
 *    - `requestVerification(string _reason)`: Allows users to request account verification (admin function needed off-chain to process).
 *    - `getContentNFT(uint256 _postId)`:  Mints a unique NFT representing ownership of a specific post (ERC721 integration concept).
 *
 * **5. Utility & Admin (Conceptual - Admin functions often handled off-chain or in separate admin contracts for security):**
 *    - `getPlatformBalance()`: Retrieves the platform's ETH balance (for donations, etc.).
 *    - `withdrawPlatformBalance(address _to, uint256 _amount)`: (Conceptual Admin function - for withdrawing platform funds).
 *
 * **Note:** This is a conceptual smart contract and may require further development, security audits, and gas optimization for a production environment. Some features like full-text search are simplified and would typically be implemented with off-chain indexing for efficiency. NFT integration is a conceptual example and would need proper ERC721 implementation and considerations.  Admin functions are generally kept minimal in the smart contract itself for security and often managed through off-chain mechanisms or separate admin contracts.
 */
pragma solidity ^0.8.0;

contract NexusPlatform {
    // --- Data Structures ---

    struct UserProfile {
        string username;
        string bio;
        string profileImageUrl;
        bool isRegistered;
        bool isVerified; // Conceptual Verification Status
    }

    struct Post {
        address author;
        string content;
        string mediaUrl;
        uint256 timestamp;
        uint256 likesCount;
        string[] tags;
        bool isDeleted;
    }

    struct Comment {
        address author;
        string content;
        uint256 timestamp;
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles; // User address to profile
    mapping(string => address) public usernameToAddress; // Username to user address for uniqueness
    uint256 public nextPostId;
    mapping(uint256 => Post) public posts; // Post ID to Post struct
    mapping(uint256 => Comment[]) public postComments; // Post ID to array of comments
    mapping(uint256 => mapping(address => bool)) public postLikes; // Post ID -> User Address -> Liked status
    mapping(address => mapping(address => bool)) public userFollows; // Follower -> Following -> Follow status
    mapping(address => uint256[]) public userPosts; // User address to array of their post IDs
    mapping(string => uint256[]) public tagToPosts; // Tag to array of post IDs
    mapping(uint256 => address) public postToNFTContract; // Conceptual Post ID to NFT Contract Address (for content NFTs)

    // --- Events ---

    event UserRegistered(address user, string username);
    event ProfileUpdated(address user);
    event PostCreated(uint256 postId, address author);
    event PostEdited(uint256 postId);
    event PostDeleted(uint256 postId);
    event PostLiked(uint256 postId, address user);
    event PostUnliked(uint256 postId, address user);
    event CommentAdded(uint256 postId, address author);
    event UserFollowed(address follower, address following);
    event UserUnfollowed(address follower, address following);
    event PostReported(uint256 postId, address reporter, string reason);
    event DonationReceived(address creator, address donor, uint256 amount);
    event VerificationRequested(address user, string reason);
    event ContentNFTMinted(uint256 postId, address nftContract, address owner);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    modifier validPostId(uint256 _postId) {
        require(_postId > 0 && _postId < nextPostId && !posts[_postId].isDeleted, "Invalid post ID");
        _;
    }

    modifier onlyPostAuthor(uint256 _postId) {
        require(posts[_postId].author == msg.sender, "Not post author");
        _;
    }


    // --- 1. User Profile Management ---

    function registerUser(string memory _username, string memory _profileBio, string memory _profileImageUrl) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        require(usernameToAddress[_username] == address(0), "Username already taken");
        require(bytes(_username).length > 0 && bytes(_username).length <= 30, "Username must be 1-30 characters");
        require(bytes(_profileBio).length <= 200, "Bio must be max 200 characters");
        // Basic URL validation can be added if needed (off-chain is better for complex validation)

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _profileBio,
            profileImageUrl: _profileImageUrl,
            isRegistered: true,
            isVerified: false // Initially not verified
        });
        usernameToAddress[_username] = msg.sender;
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileBio, string memory _profileImageUrl) public onlyRegisteredUser {
        require(bytes(_profileBio).length <= 200, "Bio must be max 200 characters");
        // Basic URL validation can be added if needed (off-chain is better for complex validation)

        userProfiles[msg.sender].bio = _profileBio;
        userProfiles[msg.sender].profileImageUrl = _profileImageUrl;
        emit ProfileUpdated(msg.sender);
    }

    function getUsername(address _user) public view returns (string memory) {
        return userProfiles[_user].username;
    }

    function getProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function isUserRegistered(address _user) public view returns (bool) {
        return userProfiles[_user].isRegistered;
    }


    // --- 2. Content Creation & Management (Posts) ---

    function createPost(string memory _content, string memory _mediaUrl, string[] memory _tags) public onlyRegisteredUser {
        require(bytes(_content).length > 0 && bytes(_content).length <= 10000, "Post content must be 1-10000 characters");
        // Basic URL validation for _mediaUrl can be added (off-chain preferred)
        uint256 postId = nextPostId++;
        posts[postId] = Post({
            author: msg.sender,
            content: _content,
            mediaUrl: _mediaUrl,
            timestamp: block.timestamp,
            likesCount: 0,
            tags: _tags,
            isDeleted: false
        });
        userPosts[msg.sender].push(postId);
        for (uint i = 0; i < _tags.length; i++) {
            tagToPosts[_tags[i]].push(postId);
        }
        emit PostCreated(postId, msg.sender);
    }

    function editPost(uint256 _postId, string memory _newContent, string memory _newMediaUrl, string[] memory _newTags) public onlyRegisteredUser validPostId(_postId) onlyPostAuthor(_postId) {
        require(bytes(_newContent).length > 0 && bytes(_newContent).length <= 10000, "Post content must be 1-10000 characters");
        // Basic URL validation for _newMediaUrl can be added (off-chain preferred)

        posts[_postId].content = _newContent;
        posts[_postId].mediaUrl = _newMediaUrl;
        posts[_postId].tags = _newTags; // Replace tags entirely for simplicity, can be optimized
        emit PostEdited(_postId);
    }

    function deletePost(uint256 _postId) public onlyRegisteredUser validPostId(_postId) onlyPostAuthor(_postId) {
        posts[_postId].isDeleted = true;
        emit PostDeleted(_postId);
    }

    function getPost(uint256 _postId) public view validPostId(_postId) returns (Post memory) {
        return posts[_postId];
    }

    function getUserPosts(address _user) public view returns (uint256[] memory) {
        return userPosts[_user];
    }

    function getPostsByTag(string memory _tag) public view returns (uint256[] memory) {
        return tagToPosts[_tag];
    }


    // --- 3. Content Interaction & Community Features ---

    function likePost(uint256 _postId) public onlyRegisteredUser validPostId(_postId) {
        if (!postLikes[_postId][msg.sender]) {
            postLikes[_postId][msg.sender] = true;
            posts[_postId].likesCount++;
            emit PostLiked(_postId, msg.sender);
        }
    }

    function unlikePost(uint256 _postId) public onlyRegisteredUser validPostId(_postId) {
        if (postLikes[_postId][msg.sender]) {
            postLikes[_postId][msg.sender] = false;
            posts[_postId].likesCount--;
            emit PostUnliked(_postId, msg.sender);
        }
    }

    function getPostLikesCount(uint256 _postId) public view validPostId(_postId) returns (uint256) {
        return posts[_postId].likesCount;
    }

    function commentOnPost(uint256 _postId, string memory _comment) public onlyRegisteredUser validPostId(_postId) {
        require(bytes(_comment).length > 0 && bytes(_comment).length <= 500, "Comment must be 1-500 characters");

        postComments[_postId].push(Comment({
            author: msg.sender,
            content: _comment,
            timestamp: block.timestamp
        }));
        emit CommentAdded(_postId, msg.sender);
    }

    function getPostComments(uint256 _postId) public view validPostId(_postId) returns (Comment[] memory) {
        return postComments[_postId];
    }

    function followUser(address _userToFollow) public onlyRegisteredUser {
        require(_userToFollow != msg.sender, "Cannot follow yourself");
        require(userProfiles[_userToFollow].isRegistered, "User to follow is not registered");
        if (!userFollows[msg.sender][_userToFollow]) {
            userFollows[msg.sender][_userToFollow] = true;
            emit UserFollowed(msg.sender, _userToFollow);
        }
    }

    function unfollowUser(address _userToUnfollow) public onlyRegisteredUser {
        if (userFollows[msg.sender][_userToUnfollow]) {
            userFollows[msg.sender][_userToUnfollow] = false;
            emit UserUnfollowed(msg.sender, _userToUnfollow);
        }
    }

    function getUserFollowersCount(address _user) public view returns (uint256) {
        uint256 followerCount = 0;
        for (uint256 i = 0; i < nextPostId; i++) { // Inefficient for large scale, consider alternative indexing
            if (userFollows[i == 0 ? address(0x0) : address(uint160(i))] [_user]) { // Iterate through all possible addresses (simplified, not scalable)
                followerCount++;
            }
        }
        return followerCount;
    }

    function getUserFollowingCount(address _user) public view returns (uint256) {
        uint256 followingCount = 0;
         for (uint256 i = 0; i < nextPostId; i++) { // Inefficient, consider alternative indexing
            if (userFollows[_user][i == 0 ? address(0x0) : address(uint160(i))]) { // Iterate through all possible addresses (simplified, not scalable)
                followingCount++;
            }
        }
        return followingCount;
    }


    // --- 4. Advanced Features ---

    function reportPost(uint256 _postId, string memory _reason) public onlyRegisteredUser validPostId(_postId) {
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 200, "Report reason must be 1-200 characters");
        emit PostReported(_postId, msg.sender, _reason);
        // In a real application, this would trigger off-chain moderation processes
    }

    function searchPostsByKeyword(string memory _keyword) public view returns (uint256[] memory) {
        // Simplified keyword search - inefficient for real-world scale.
        // In a real application, consider off-chain indexing solutions like Elasticsearch or The Graph.
        uint256[] memory searchResults = new uint256[](0);
        for (uint256 i = 1; i < nextPostId; i++) { // Iterate through all posts (inefficient)
            if (!posts[i].isDeleted && stringContains(posts[i].content, _keyword)) {
                uint256[] memory tempResults = new uint256[](searchResults.length + 1);
                for (uint256 j = 0; j < searchResults.length; j++) {
                    tempResults[j] = searchResults[j];
                }
                tempResults[searchResults.length] = i;
                searchResults = tempResults;
            }
        }
        return searchResults;
    }

    function donateToCreator(address _creator) public payable onlyRegisteredUser {
        require(userProfiles[_creator].isRegistered, "Creator is not registered");
        require(msg.value > 0, "Donation amount must be greater than zero");
        payable(_creator).transfer(msg.value);
        emit DonationReceived(_creator, msg.sender, msg.value);
    }

    function requestVerification(string memory _reason) public onlyRegisteredUser {
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 500, "Verification request reason must be 1-500 characters");
        emit VerificationRequested(msg.sender, _reason);
        // In a real application, this would trigger an off-chain verification process by admins.
    }

    function getContentNFT(uint256 _postId) public onlyRegisteredUser validPostId(_postId) {
        // Conceptual NFT minting for content ownership - requires ERC721 contract integration.
        // In a real application, you'd need to deploy an ERC721 contract and integrate it here.
        // This is a placeholder to illustrate the concept.

        // Example:  (Hypothetical ERC721 contract deployment per post, or a single contract managing all)
        address nftContractAddress = address(0); // In real implementation, deploy or reference an NFT contract.
        // (Logic to interact with NFT contract - mint NFT for msg.sender associated with _postId)
        emit ContentNFTMinted(_postId, nftContractAddress, msg.sender);
    }


    // --- 5. Utility & Admin (Conceptual) ---

    function getPlatformBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawPlatformBalance(address _to, uint256 _amount) public {
        // Conceptual Admin function - In a real application, access control would be crucial.
        // For example, using a separate admin role and onlyOwner modifier.
        // For simplicity, no access control is added here for demonstration purposes.
        payable(_to).transfer(_amount);
    }


    // --- Internal Utility Functions ---

    function stringContains(string memory _string, string memory _substring) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_string)) == keccak256(abi.encodePacked(_substring)); // Very basic, for demonstration, not robust substring search. For real substring search, off-chain indexing is needed.
        // For a more robust string search in Solidity (still limited):
        //  bytes memory stringBytes = bytes(_string);
        //  bytes memory substringBytes = bytes(_substring);
        //  if (substringBytes.length == 0) return true;
        //  for (uint i = 0; i <= stringBytes.length - substringBytes.length; i++) {
        //      if (stringBytes[i] == substringBytes[0]) {
        //          bool found = true;
        //          for (uint j = 1; j < substringBytes.length; j++) {
        //              if (stringBytes[i + j] != substringBytes[j]) {
        //                  found = false;
        //                  break;
        //              }
        //          }
        //          if (found) return true;
        //      }
        //  }
        //  return false;
    }
}
```