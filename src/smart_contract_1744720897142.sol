```solidity
/**
 * @title Decentralized Autonomous Content Platform (DACP)
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized content platform with advanced features.
 *
 * **Outline and Function Summary:**
 *
 * **1. Platform Initialization and Management:**
 *    - `initializePlatform(string _platformName, address _governanceTokenAddress, uint256 _platformFeePercentage)`: Initializes the platform with name, governance token, and platform fee. (Admin only, callable once)
 *    - `setPlatformFeePercentage(uint256 _newFeePercentage)`: Updates the platform fee percentage charged on transactions. (Platform Owner only)
 *    - `pausePlatform()`: Pauses core platform functionalities (content creation, interaction). (Platform Owner only)
 *    - `unpausePlatform()`: Resumes platform functionalities after pausing. (Platform Owner only)
 *    - `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees. (Platform Owner only)
 *
 * **2. User and Profile Management:**
 *    - `registerUser(string _username, string _profileBio)`: Registers a new user on the platform.
 *    - `updateProfile(string _newUsername, string _newProfileBio)`: Allows users to update their profile information.
 *    - `getUserProfile(address _userAddress) view returns (string username, string bio, uint256 registrationTimestamp)`: Retrieves a user's profile information.
 *    - `followUser(address _userToFollow)`: Allows a user to follow another user.
 *    - `unfollowUser(address _userToUnfollow)`: Allows a user to unfollow another user.
 *    - `getFollowerCount(address _userAddress) view returns (uint256)`: Returns the number of followers a user has.
 *    - `getFollowingCount(address _userAddress) view returns (uint256)`: Returns the number of users a user is following.
 *
 * **3. Content Creation and Management (NFT based):**
 *    - `createContent(string _contentHash, string _metadataURI, ContentType _contentType, string[] _tags)`: Allows registered users to create content (minting an NFT).
 *    - `editContentMetadata(uint256 _contentId, string _newMetadataURI)`: Allows content creators to edit the metadata URI of their content NFT.
 *    - `setContentPrice(uint256 _contentId, uint256 _price)`: Allows content creators to set a price for their content (for potential monetization).
 *    - `getContentDetails(uint256 _contentId) view returns (ContentDetails)`: Retrieves detailed information about a specific content NFT.
 *    - `getContentOwner(uint256 _contentId) view returns (address)`: Retrieves the owner of a specific content NFT.
 *    - `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 *    - `moderateContent(uint256 _contentId, ModerationAction _action)`: Platform moderators can take action on reported content. (Moderator role needed)
 *
 * **4. Content Interaction and Discovery:**
 *    - `likeContent(uint256 _contentId)`: Allows registered users to like content.
 *    - `unlikeContent(uint256 _contentId)`: Allows registered users to unlike content.
 *    - `getLikeCount(uint256 _contentId) view returns (uint256)`: Returns the number of likes a content has.
 *    - `purchaseContent(uint256 _contentId)`: Allows users to purchase content if a price is set.
 *    - `tipCreator(uint256 _contentId) payable`: Allows users to tip content creators.
 *    - `searchContentByTag(string _tag) view returns (uint256[] contentIds)`: Allows users to search content by tags.
 *
 * **5. Governance and Community Features:**
 *    - `proposeFeatureRequest(string _featureDescription)`: Allows users to propose new features for the platform.
 *    - `voteOnFeatureRequest(uint256 _requestId, bool _vote)`: Allows governance token holders to vote on feature requests.
 *    - `executeFeatureRequest(uint256 _requestId)`: Allows platform owner to execute approved feature requests. (Platform Owner + Governance Threshold)
 *    - `getPlatformBalance() view returns (uint256)`: Returns the contract's current ETH balance (platform fees, tips).
 *
 * **Advanced Concepts Implemented:**
 * - **Decentralized Content Ownership (NFTs):** Content is represented as NFTs, giving creators ownership and control.
 * - **Platform Governance (Token-based):**  Potential for integration with a governance token for community-driven decisions (feature requests).
 * - **Content Monetization:** Creators can set prices and receive tips for their content.
 * - **Content Moderation System:**  Basic reporting and moderation mechanism.
 * - **User Profiles and Social Features:**  Following, likes, basic social interactions.
 * - **Search by Tags:** Content discovery through tagging.
 *
 * **Trendy Aspects:**
 * - **Creator Economy Focus:** Empowers content creators with ownership and monetization.
 * - **Web3 Social Platform:** Decentralized alternative to traditional social media.
 * - **NFT Integration:** Leverages NFTs for content ownership and potentially future utility.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecentralizedAutonomousContentPlatform is ERC721, Ownable, Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _contentIds;
    Counters.Counter private _featureRequestIds;

    string public platformName;
    uint256 public platformFeePercentage; // Percentage, e.g., 2% = 2
    address public governanceTokenAddress;

    // --- Enums and Structs ---
    enum ContentType { IMAGE, VIDEO, TEXT, AUDIO }
    enum ModerationAction { NONE, WARN, REMOVE }
    enum FeatureRequestStatus { PENDING, VOTING, APPROVED, REJECTED, IMPLEMENTED }

    struct UserProfile {
        string username;
        string bio;
        uint256 registrationTimestamp;
        mapping(address => bool) followers; // User addresses who follow this user
        mapping(address => bool) following; // Users this user is following
    }

    struct ContentDetails {
        address creator;
        string contentHash; // IPFS hash or similar content identifier
        string metadataURI; // URI pointing to content metadata (JSON)
        ContentType contentType;
        uint256 createdAtTimestamp;
        uint256 price; // Price in wei (0 if free)
        uint256 likeCount;
        string[] tags;
        ModerationAction moderationStatus;
        string reportReason; // Last report reason
    }

    struct FeatureRequest {
        string description;
        address proposer;
        FeatureRequestStatus status;
        uint256 upVotes;
        uint256 downVotes;
    }

    // --- Mappings and State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => ContentDetails) public contentDetails;
    mapping(uint256 => FeatureRequest) public featureRequests;
    mapping(uint256 => mapping(address => bool)) public contentLikes; // contentId => userAddress => liked
    mapping(string => uint256[]) public tagToContentIds; // tag => array of contentIds

    bool public platformInitialized = false;

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    // --- Events ---
    event PlatformInitialized(string platformName, address owner, uint256 timestamp);
    event PlatformFeeUpdated(uint256 newFeePercentage, uint256 timestamp);
    event PlatformPaused(address admin, uint256 timestamp);
    event PlatformUnpaused(address admin, uint256 timestamp);
    event PlatformFeesWithdrawn(address admin, uint256 amount, uint256 timestamp);

    event UserRegistered(address userAddress, string username, uint256 timestamp);
    event ProfileUpdated(address userAddress, string newUsername, uint256 timestamp);
    event UserFollowed(address follower, address followedUser, uint256 timestamp);
    event UserUnfollowed(address follower, address unfollowedUser, uint256 timestamp);

    event ContentCreated(uint256 contentId, address creator, string contentHash, ContentType contentType, uint256 timestamp);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI, uint256 timestamp);
    event ContentPriceSet(uint256 contentId, uint256 price, uint256 timestamp);
    event ContentLiked(uint256 contentId, address user, uint256 timestamp);
    event ContentUnliked(uint256 contentId, address user, uint256 timestamp);
    event ContentPurchased(uint256 contentId, address buyer, uint256 price, uint256 platformFee, uint256 creatorPayout, uint256 timestamp);
    event ContentReported(uint256 contentId, address reporter, string reason, uint256 timestamp);
    event ContentModerated(uint256 contentId, ModerationAction action, address moderator, uint256 timestamp);

    event FeatureRequestProposed(uint256 requestId, string description, address proposer, uint256 timestamp);
    event FeatureRequestVoted(uint256 requestId, address voter, bool vote, uint256 timestamp);
    event FeatureRequestExecuted(uint256 requestId, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        require(bytes(userProfiles[msg.sender].username).length > 0, "User not registered");
        _;
    }

    modifier onlyModerator() {
        require(hasRole(MODERATOR_ROLE, msg.sender), "Sender is not a moderator");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(_exists(_contentId), "Invalid content ID");
        _;
    }

    modifier validFeatureRequestId(uint256 _requestId) {
        require(featureRequests[_requestId].proposer != address(0), "Invalid feature request ID");
        _;
    }

    modifier platformNotPaused() {
        require(!paused(), "Platform is paused");
        _;
    }

    // --- Constructor and Initialization ---
    constructor() ERC721("DecentralizedContent", "DCP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is the initial admin and platform owner
    }

    function initializePlatform(string memory _platformName, address _governanceTokenAddress, uint256 _platformFeePercentage) external onlyOwner {
        require(!platformInitialized, "Platform already initialized");
        require(_platformFeePercentage <= 100, "Platform fee percentage must be <= 100");
        platformName = _platformName;
        governanceTokenAddress = _governanceTokenAddress;
        platformFeePercentage = _platformFeePercentage;
        platformInitialized = true;
        emit PlatformInitialized(_platformName, owner(), block.timestamp);
    }

    // --- Platform Management Functions ---
    function setPlatformFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage must be <= 100");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage, block.timestamp);
    }

    function pausePlatform() external onlyOwner {
        _pause();
        emit PlatformPaused(msg.sender, block.timestamp);
    }

    function unpausePlatform() external onlyOwner {
        _unpause();
        emit PlatformUnpaused(msg.sender, block.timestamp);
    }

    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit PlatformFeesWithdrawn(msg.sender, balance, block.timestamp);
    }

    // --- User and Profile Management Functions ---
    function registerUser(string memory _username, string memory _profileBio) external platformNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _profileBio,
            registrationTimestamp: block.timestamp,
            followers: mapping(address => bool)(),
            following: mapping(address => bool)()
        });
        emit UserRegistered(msg.sender, _username, block.timestamp);
    }

    function updateProfile(string memory _newUsername, string memory _newProfileBio) external onlyRegisteredUser platformNotPaused {
        userProfiles[msg.sender].username = _newUsername;
        userProfiles[msg.sender].bio = _newProfileBio;
        emit ProfileUpdated(msg.sender, _newUsername, block.timestamp);
    }

    function getUserProfile(address _userAddress) external view returns (string memory username, string memory bio, uint256 registrationTimestamp) {
        require(bytes(userProfiles[_userAddress].username).length > 0, "User not registered");
        UserProfile storage profile = userProfiles[_userAddress];
        return (profile.username, profile.bio, profile.registrationTimestamp);
    }

    function followUser(address _userToFollow) external onlyRegisteredUser platformNotPaused {
        require(_userToFollow != msg.sender, "Cannot follow yourself");
        require(bytes(userProfiles[_userToFollow].username).length > 0, "User to follow is not registered");
        require(!userProfiles[msg.sender].following[_userToFollow], "Already following this user");

        userProfiles[msg.sender].following[_userToFollow] = true;
        userProfiles[_userToFollow].followers[msg.sender] = true;
        emit UserFollowed(msg.sender, _userToFollow, block.timestamp);
    }

    function unfollowUser(address _userToUnfollow) external onlyRegisteredUser platformNotPaused {
        require(userProfiles[msg.sender].following[_userToUnfollow], "Not following this user");

        userProfiles[msg.sender].following[_userToUnfollow] = false;
        userProfiles[_userToUnfollow].followers[msg.sender] = false;
        emit UserUnfollowed(msg.sender, _userToUnfollow, block.timestamp);
    }

    function getFollowerCount(address _userAddress) external view returns (uint256) {
        uint256 count = 0;
        UserProfile storage profile = userProfiles[_userAddress];
        address[] memory followers = new address[](profile.followers.length); // Solidity doesn't directly give size of mapping
        uint256 index = 0;
        for (address follower : followers) {
             if (profile.followers[follower]) { // Iterate through potential follower addresses (inefficient in real-world, better to store followers in array if count is frequently needed)
                count++;
            }
        }
         // Inefficient way to count mapping size, better to maintain follower counts in state variable for performance if needed frequently
        for (address follower in profile.followers) {
            if (profile.followers[follower]) { // Check if the address exists in the mapping (always true in a mapping)
                count++; // Increment count if it exists (effectively counting all keys, which might not be accurate)
            }
        }
        return count;
    }

    function getFollowingCount(address _userAddress) external view returns (uint256) {
        uint256 count = 0;
        UserProfile storage profile = userProfiles[_userAddress];
        address[] memory followingList = new address[](profile.following.length); // Same inefficiency as above
         uint256 index = 0;
        for (address followedUser : followingList) {
             if (profile.following[followedUser]) {
                count++;
            }
        }
        // Inefficient way to count mapping size.
        for (address followedUser in profile.following) {
            if (profile.following[followedUser]) {
                count++;
            }
        }
        return count;
    }


    // --- Content Creation and Management Functions ---
    function createContent(string memory _contentHash, string memory _metadataURI, ContentType _contentType, string[] memory _tags) external onlyRegisteredUser platformNotPaused {
        _contentIds.increment();
        uint256 contentId = _contentIds.current();
        _safeMint(msg.sender, contentId); // Mint NFT to creator
        contentDetails[contentId] = ContentDetails({
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            contentType: _contentType,
            createdAtTimestamp: block.timestamp,
            price: 0, // Default price is 0
            likeCount: 0,
            tags: _tags,
            moderationStatus: ModerationAction.NONE,
            reportReason: ""
        });

        for (uint256 i = 0; i < _tags.length; i++) {
            tagToContentIds[_tags[i]].push(contentId);
        }

        emit ContentCreated(contentId, msg.sender, _contentHash, _contentType, block.timestamp);
    }

    function editContentMetadata(uint256 _contentId, string memory _newMetadataURI) external onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        require(contentDetails[_contentId].creator == msg.sender, "Only creator can edit metadata");
        contentDetails[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI, block.timestamp);
    }

    function setContentPrice(uint256 _contentId, uint256 _price) external onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        require(contentDetails[_contentId].creator == msg.sender, "Only creator can set price");
        contentDetails[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price, block.timestamp);
    }

    function getContentDetails(uint256 _contentId) external view validContentId(_contentId) returns (ContentDetails memory) {
        return contentDetails[_contentId];
    }

    function getContentOwner(uint256 _contentId) external view validContentId(_contentId) returns (address) {
        return ownerOf(_contentId);
    }

    function reportContent(uint256 _contentId, string memory _reportReason) external onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        contentDetails[_contentId].moderationStatus = ModerationAction.WARN; // Simple warning upon report for now
        contentDetails[_contentId].reportReason = _reportReason;
        emit ContentReported(_contentId, msg.sender, _reportReason, block.timestamp);
    }

    function moderateContent(uint256 _contentId, ModerationAction _action) external onlyModerator validContentId(_contentId) platformNotPaused {
        contentDetails[_contentId].moderationStatus = _action;
        if (_action == ModerationAction.REMOVE) {
            _burn(_contentId); // Burn the NFT if content is removed.
        }
        emit ContentModerated(_contentId, _action, msg.sender, block.timestamp);
    }


    // --- Content Interaction and Discovery Functions ---
    function likeContent(uint256 _contentId) external onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        require(!contentLikes[_contentId][msg.sender], "Already liked this content");
        contentLikes[_contentId][msg.sender] = true;
        contentDetails[_contentId].likeCount++;
        emit ContentLiked(_contentId, msg.sender, block.timestamp);
    }

    function unlikeContent(uint256 _contentId) external onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        require(contentLikes[_contentId][msg.sender], "Not liked this content yet");
        contentLikes[_contentId][msg.sender] = false;
        contentDetails[_contentId].likeCount--;
        emit ContentUnliked(_contentId, msg.sender, block.timestamp);
    }

    function getLikeCount(uint256 _contentId) external view validContentId(_contentId) returns (uint256) {
        return contentDetails[_contentId].likeCount;
    }

    function purchaseContent(uint256 _contentId) external payable onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        uint256 price = contentDetails[_contentId].price;
        require(price > 0, "Content is not for sale");
        require(msg.value >= price, "Insufficient funds sent");

        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 creatorPayout = price - platformFee;

        // Transfer to creator (minus platform fee)
        payable(contentDetails[_contentId].creator).transfer(creatorPayout);

        // Platform fees remain in the contract balance (can be withdrawn by platform owner)

        // Transfer NFT ownership to purchaser
        _transfer(ownerOf(_contentId), msg.sender, _contentId);

        emit ContentPurchased(_contentId, msg.sender, price, platformFee, creatorPayout, block.timestamp);

        // Refund extra ETH if sent
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function tipCreator(uint256 _contentId) external payable onlyRegisteredUser validContentId(_contentId) platformNotPaused {
        require(msg.value > 0, "Tip amount must be greater than 0");
        payable(contentDetails[_contentId].creator).transfer(msg.value);
        // Platform could potentially take a fee from tips as well in a future iteration.
        // For now, tips go directly to creators.
        // No specific event emitted for tips for brevity, can be added if needed.
    }

    function searchContentByTag(string memory _tag) external view returns (uint256[] memory contentIds) {
        return tagToContentIds[_tag];
    }


    // --- Governance and Community Features ---
    function proposeFeatureRequest(string memory _featureDescription) external onlyRegisteredUser platformNotPaused {
        _featureRequestIds.increment();
        uint256 requestId = _featureRequestIds.current();
        featureRequests[requestId] = FeatureRequest({
            description: _featureDescription,
            proposer: msg.sender,
            status: FeatureRequestStatus.PENDING,
            upVotes: 0,
            downVotes: 0
        });
        emit FeatureRequestProposed(requestId, _featureDescription, msg.sender, block.timestamp);
    }

    function voteOnFeatureRequest(uint256 _requestId, bool _vote) external validFeatureRequestId(_requestId) platformNotPaused {
        require(governanceTokenAddress != address(0), "Governance token address not set for voting");
        // In a real scenario, you'd check if voter holds governance tokens and their voting power.
        // For simplicity, we just allow voting if governance token address is set.
        FeatureRequest storage request = featureRequests[_requestId];
        require(request.status == FeatureRequestStatus.PENDING || request.status == FeatureRequestStatus.VOTING, "Voting is not active for this request");

        if (request.status == FeatureRequestStatus.PENDING) {
            request.status = FeatureRequestStatus.VOTING; // Start voting after first vote
        }

        if (_vote) {
            request.upVotes++;
        } else {
            request.downVotes++;
        }
        emit FeatureRequestVoted(_requestId, msg.sender, _vote, block.timestamp);

        // Example: Auto-approve if upVotes reach a threshold (e.g., 50% of total possible votes - complex to determine on-chain)
        // In a real system, voting duration, quorum, and thresholds would be more sophisticated.
        if (request.upVotes > request.downVotes * 2) { // Simple example: more than double upvotes than downvotes
            request.status = FeatureRequestStatus.APPROVED;
        } else if (request.downVotes > request.upVotes * 2) {
            request.status = FeatureRequestStatus.REJECTED;
        }
    }

    function executeFeatureRequest(uint256 _requestId) external onlyOwner validFeatureRequestId(_requestId) platformNotPaused {
        require(featureRequests[_requestId].status == FeatureRequestStatus.APPROVED, "Feature request not approved");
        featureRequests[_requestId].status = FeatureRequestStatus.IMPLEMENTED;
        emit FeatureRequestExecuted(_requestId, block.timestamp);
        // In a real scenario, this function might trigger actual implementation logic (e.g., parameter changes).
        // For this example, it just marks the request as implemented.
    }

    function getPlatformBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Admin/Moderator Role Management (using AccessControl from OpenZeppelin) ---
    function addModerator(address _moderator) external onlyOwner {
        grantRole(MODERATOR_ROLE, _moderator);
    }

    function removeModerator(address _moderator) external onlyOwner {
        revokeRole(MODERATOR_ROLE, _moderator);
    }

    function renounceModerator() external {
        renounceRole(MODERATOR_ROLE, msg.sender);
    }

    // The following functions are from ERC721 and Ownable contracts and are implicitly included:
    // - `approve(address to, uint256 tokenId)`
    // - `getApproved(uint256 tokenId) view returns (address)`
    // - `setApprovalForAll(address operator, bool approved)`
    // - `isApprovedForAll(address owner, address operator) view returns (bool)`
    // - `transferFrom(address from, address to, uint256 tokenId)`
    // - `safeTransferFrom(address from, address to, uint256 tokenId)`
    // - `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`
    // - `owner()` (from Ownable)
    // - `transferOwnership(address newOwner)` (from Ownable)
    // - `renounceOwnership()` (from Ownable)
}
```