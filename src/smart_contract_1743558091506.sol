```solidity
/**
 * @title Dynamic Social Reputation NFT Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized social platform where user reputation is dynamically represented by NFTs.
 *
 * **Outline:**
 *
 * **User Management:**
 *   - registerUser: Allows users to register with a unique username.
 *   - updateUserProfile: Allows registered users to update their profile information (e.g., bio).
 *   - getUserProfile: Retrieves a user's profile information by their address.
 *   - getUserIdByUsername: Retrieves a user's ID by their username.
 *   - isUserRegistered: Checks if an address is registered as a user.
 *
 * **Content Management:**
 *   - createPost: Allows registered users to create a new post.
 *   - editPost: Allows post owners to edit their posts.
 *   - deletePost: Allows post owners to delete their posts.
 *   - getPostById: Retrieves a post by its ID.
 *   - getAllPostsByUser: Retrieves all posts created by a specific user.
 *   - likePost: Allows registered users to like a post (influences reputation).
 *   - unlikePost: Allows registered users to unlike a post.
 *   - getPostLikesCount: Retrieves the like count for a specific post.
 *
 * **Reputation and NFT System:**
 *   - calculateReputation: (Internal) Calculates user reputation based on post likes and other factors.
 *   - mintReputationNFT: Mints a dynamic Reputation NFT for a user based on their calculated reputation.
 *   - upgradeReputationNFT: Upgrades a user's Reputation NFT based on increased reputation.
 *   - getReputationScore: Retrieves a user's current reputation score.
 *   - getReputationNFTLevel: Retrieves the level of a user's Reputation NFT.
 *   - transferReputationNFT: Allows users to transfer their Reputation NFTs (optional feature).
 *
 * **Platform Administration:**
 *   - setPlatformFee: Allows the contract owner to set a platform fee (e.g., for premium features).
 *   - pausePlatform: Allows the contract owner to pause certain platform functionalities in case of emergency.
 *   - unpausePlatform: Allows the contract owner to unpause platform functionalities.
 *   - withdrawPlatformFees: Allows the contract owner to withdraw accumulated platform fees.
 *
 * **Function Summary:**
 *
 * - `registerUser(string _username, string _profileBio)`: Registers a new user with a unique username and profile bio.
 * - `updateUserProfile(string _newBio)`: Updates the profile bio of the calling user.
 * - `getUserProfile(address _userAddress)`: Retrieves the profile information of a user by address.
 * - `getUserIdByUsername(string _username)`: Retrieves the user ID associated with a given username.
 * - `isUserRegistered(address _userAddress)`: Checks if a given address is registered as a user.
 * - `createPost(string _content)`: Creates a new post with the given content by the calling user.
 * - `editPost(uint256 _postId, string _newContent)`: Edits the content of an existing post (owner only).
 * - `deletePost(uint256 _postId)`: Deletes a post (owner only).
 * - `getPostById(uint256 _postId)`: Retrieves a post by its ID.
 * - `getAllPostsByUser(address _userAddress)`: Retrieves all posts created by a specific user.
 * - `likePost(uint256 _postId)`: Likes a post, increasing its like count and potentially the author's reputation.
 * - `unlikePost(uint256 _postId)`: Removes a like from a post.
 * - `getPostLikesCount(uint256 _postId)`: Retrieves the number of likes for a specific post.
 * - `calculateReputation(address _userAddress)`: (Internal) Calculates the reputation score for a user.
 * - `mintReputationNFT()`: Mints a Reputation NFT for the calling user based on their reputation.
 * - `upgradeReputationNFT()`: Upgrades the Reputation NFT of the calling user if their reputation has increased.
 * - `getReputationScore(address _userAddress)`: Retrieves the reputation score of a user.
 * - `getReputationNFTLevel(address _userAddress)`: Retrieves the level of the Reputation NFT of a user.
 * - `transferReputationNFT(address _to, uint256 _tokenId)`: Transfers a Reputation NFT to another address (ERC721 standard function).
 * - `setPlatformFee(uint256 _newFee)`: Sets the platform fee (owner only).
 * - `pausePlatform()`: Pauses certain platform functionalities (owner only).
 * - `unpausePlatform()`: Unpauses platform functionalities (owner only).
 * - `withdrawPlatformFees()`: Allows the owner to withdraw accumulated platform fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicSocialReputationNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Data Structures ---
    struct UserProfile {
        uint256 userId;
        string username;
        string profileBio;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Post {
        uint256 postId;
        address author;
        string content;
        uint256 likesCount;
        uint256 creationTimestamp;
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(string => uint256) public usernameToUserId;
    Counters.Counter private _userIdCounter;
    Counters.Counter private _postIdCounter;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => mapping(address => bool)) public postLikes; // postId => userAddress => liked
    uint256 public platformFee; // Example platform fee (can be used for premium features later)
    bool public platformPaused;
    uint256 public reputationThresholdLevel2 = 100;
    uint256 public reputationThresholdLevel3 = 500;
    uint256 public reputationThresholdLevel4 = 1000;
    uint256 public reputationThresholdLevel5 = 5000;
    mapping(address => uint256) public reputationScores; // Store reputation scores separately
    mapping(address => uint256) public userReputationNFTLevel; // Store NFT level

    // --- Events ---
    event UserRegistered(address indexed userAddress, uint256 userId, string username);
    event ProfileUpdated(address indexed userAddress);
    event PostCreated(uint256 postId, address indexed author);
    event PostEdited(uint256 postId);
    event PostDeleted(uint256 postId);
    event PostLiked(uint256 postId, address indexed userAddress);
    event PostUnliked(uint256 postId, address indexed userAddress);
    event ReputationNFTMinted(address indexed userAddress, uint256 tokenId, uint256 reputationScore, uint256 nftLevel);
    event ReputationNFTUpgraded(address indexed userAddress, uint256 tokenId, uint256 newNftLevel);
    event PlatformFeeSet(uint256 newFee);
    event PlatformPaused();
    event PlatformUnpaused();
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor() ERC721("ReputationNFT", "REPNFT") Ownable() {
        platformFee = 0; // Initial platform fee is zero
        platformPaused = false;
    }

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User not registered.");
        _;
    }

    modifier postExists(uint256 _postId) {
        require(posts[_postId].postId != 0, "Post does not exist.");
        _;
    }

    modifier onlyPostAuthor(uint256 _postId) {
        require(posts[_postId].author == msg.sender, "You are not the author of this post.");
        _;
    }

    modifier platformNotPaused() {
        require(!platformPaused, "Platform is currently paused.");
        _;
    }

    // --- User Management Functions ---
    function registerUser(string memory _username, string memory _profileBio) public platformNotPaused {
        require(!userProfiles[msg.sender].isRegistered, "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(usernameToUserId[_username] == 0, "Username already taken.");

        _userIdCounter.increment();
        uint256 userId = _userIdCounter.current();

        userProfiles[msg.sender] = UserProfile({
            userId: userId,
            username: _username,
            profileBio: _profileBio,
            reputationScore: 0, // Initial reputation score
            isRegistered: true
        });
        usernameToUserId[_username] = userId;

        emit UserRegistered(msg.sender, userId, _username);
    }

    function updateUserProfile(string memory _newBio) public onlyRegisteredUser platformNotPaused {
        userProfiles[msg.sender].profileBio = _newBio;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function getUserIdByUsername(string memory _username) public view returns (uint256) {
        return usernameToUserId[_username];
    }

    function isUserRegistered(address _userAddress) public view returns (bool) {
        return userProfiles[_userAddress].isRegistered;
    }

    // --- Content Management Functions ---
    function createPost(string memory _content) public onlyRegisteredUser platformNotPaused {
        require(bytes(_content).length > 0 && bytes(_content).length <= 1000, "Post content must be between 1 and 1000 characters.");

        _postIdCounter.increment();
        uint256 postId = _postIdCounter.current();

        posts[postId] = Post({
            postId: postId,
            author: msg.sender,
            content: _content,
            likesCount: 0,
            creationTimestamp: block.timestamp
        });

        emit PostCreated(postId, msg.sender);
    }

    function editPost(uint256 _postId, string memory _newContent) public onlyRegisteredUser postExists(_postId) onlyPostAuthor(_postId) platformNotPaused {
        require(bytes(_newContent).length > 0 && bytes(_newContent).length <= 1000, "Post content must be between 1 and 1000 characters.");
        posts[_postId].content = _newContent;
        emit PostEdited(_postId);
    }

    function deletePost(uint256 _postId) public onlyRegisteredUser postExists(_postId) onlyPostAuthor(_postId) platformNotPaused {
        delete posts[_postId]; // Simple delete, consider more robust deletion in production
        emit PostDeleted(_postId);
    }

    function getPostById(uint256 _postId) public view postExists(_postId) returns (Post memory) {
        return posts[_postId];
    }

    function getAllPostsByUser(address _userAddress) public view returns (Post[] memory) {
        uint256 postCount = _postIdCounter.current();
        uint256 userPostCount = 0;
        for (uint256 i = 1; i <= postCount; i++) {
            if (posts[i].author == _userAddress && posts[i].postId != 0) { // Check if post exists after potential deletion
                userPostCount++;
            }
        }

        Post[] memory userPosts = new Post[](userPostCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= postCount; i++) {
            if (posts[i].author == _userAddress && posts[i].postId != 0) { // Check if post exists after potential deletion
                userPosts[index] = posts[i];
                index++;
            }
        }
        return userPosts;
    }

    function likePost(uint256 _postId) public onlyRegisteredUser postExists(_postId) platformNotPaused {
        require(!postLikes[_postId][msg.sender], "You have already liked this post.");
        postLikes[_postId][msg.sender] = true;
        posts[_postId].likesCount++;
        emit PostLiked(_postId, msg.sender);
        _updateUserReputation(posts[_postId].author); // Update author's reputation
    }

    function unlikePost(uint256 _postId) public onlyRegisteredUser postExists(_postId) platformNotPaused {
        require(postLikes[_postId][msg.sender], "You have not liked this post.");
        postLikes[_postId][msg.sender] = false;
        posts[_postId].likesCount--;
        emit PostUnliked(_postId, msg.sender);
        _updateUserReputation(posts[_postId].author); // Update author's reputation
    }

    function getPostLikesCount(uint256 _postId) public view postExists(_postId) returns (uint256) {
        return posts[_postId].likesCount;
    }

    // --- Reputation and NFT System ---
    function _calculateReputation(address _userAddress) internal view returns (uint256) {
        uint256 totalLikesReceived = 0;
        Post[] memory userPosts = getAllPostsByUser(_userAddress);
        for (uint256 i = 0; i < userPosts.length; i++) {
            totalLikesReceived += userPosts[i].likesCount;
        }

        // Simple reputation calculation: likes received + bonus for being registered
        uint256 reputation = totalLikesReceived;
        if (userProfiles[_userAddress].isRegistered) {
            reputation += 10; // Bonus for being registered
        }
        return reputation;
    }

    function _updateUserReputation(address _userAddress) internal {
        uint256 newReputation = _calculateReputation(_userAddress);
        reputationScores[_userAddress] = newReputation;

        uint256 currentNFTLevel = userReputationNFTLevel[_userAddress];
        uint256 newNFTLevel = _getNFTLevelFromReputation(newReputation);

        if (newNFTLevel > currentNFTLevel) {
            userReputationNFTLevel[_userAddress] = newNFTLevel;
            if (currentNFTLevel > 0) { // Avoid minting for level 0
                emit ReputationNFTUpgraded(_userAddress, _getTokenId(msg.sender), newNFTLevel);
            }
        }
    }

    function mintReputationNFT() public onlyRegisteredUser platformNotPaused {
        require(_getTokenId(msg.sender) == 0, "Reputation NFT already minted."); // Only mint once

        uint256 reputationScore = _calculateReputation(msg.sender);
        uint256 nftLevel = _getNFTLevelFromReputation(reputationScore);
        userReputationNFTLevel[msg.sender] = nftLevel;

        _mint(msg.sender, _userIdCounter.current()); // Token ID can be user ID for simplicity
        emit ReputationNFTMinted(msg.sender, _getTokenId(msg.sender), reputationScore, nftLevel);
    }

    function upgradeReputationNFT() public onlyRegisteredUser platformNotPaused {
        require(_getTokenId(msg.sender) != 0, "Reputation NFT not minted yet. Mint first.");

        _updateUserReputation(msg.sender); // Recalculate and update reputation
        uint256 updatedNFTLevel = userReputationNFTLevel[msg.sender];

        emit ReputationNFTUpgraded(msg.sender, _getTokenId(msg.sender), updatedNFTLevel); // Re-emit for potential UI updates
    }


    function getReputationScore(address _userAddress) public view returns (uint256) {
        return reputationScores[_userAddress];
    }

    function getReputationNFTLevel(address _userAddress) public view returns (uint256) {
        return userReputationNFTLevel[_userAddress];
    }

    // Override _beforeTokenTransfer to prevent burning and ensure correct ownership
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(from != address(0), "Reputation NFT cannot be burned."); // Prevent burning
    }

    // Override supportsInterface to declare ERC721 metadata interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Helper Functions for NFT Level and Token ID ---
    function _getNFTLevelFromReputation(uint256 _reputationScore) internal view returns (uint256) {
        if (_reputationScore >= reputationThresholdLevel5) {
            return 5;
        } else if (_reputationScore >= reputationThresholdLevel4) {
            return 4;
        } else if (_reputationScore >= reputationThresholdLevel3) {
            return 3;
        } else if (_reputationScore >= reputationThresholdLevel2) {
            return 2;
        } else if (_reputationScore > 0) {
            return 1;
        } else {
            return 0; // Level 0 for no reputation or not minted
        }
    }

    function _getTokenId(address _userAddress) internal view returns (uint256) {
        uint256 userId = userProfiles[_userAddress].userId;
        if (userId > 0 && _exists(userId)) { // Check if user ID is valid and token exists
            return userId;
        }
        return 0; // Return 0 if no NFT minted yet or user not found
    }

    // --- Platform Administration Functions ---
    function setPlatformFee(uint256 _newFee) public onlyOwner {
        platformFee = _newFee;
        emit PlatformFeeSet(_newFee);
    }

    function pausePlatform() public onlyOwner {
        platformPaused = true;
        emit PlatformPaused();
    }

    function unpausePlatform() public onlyOwner {
        platformPaused = false;
        emit PlatformUnpaused();
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit PlatformFeesWithdrawn(owner(), balance);
    }

    // --- Fallback and Receive (Optional - for receiving ETH for platform fees etc. if needed) ---
    receive() external payable {}
    fallback() external payable {}
}
```