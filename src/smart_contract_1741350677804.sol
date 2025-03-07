```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Content Platform (DACP) - Smart Contract
 * @author Gemini
 * @dev A sophisticated smart contract for a decentralized content platform with advanced features.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 *   1. `registerUser(string _username, string _profileCID)`: Allows users to register on the platform with a unique username and profile metadata CID.
 *   2. `updateProfile(string _newProfileCID)`: Allows registered users to update their profile metadata CID.
 *   3. `createContentNFT(string _contentCID, string _metadataCID, string[] _tags, uint256 _royaltyFee)`: Allows registered users to create content and mint it as a unique NFT.
 *   4. `transferContentNFT(uint256 _tokenId, address _to)`: Allows content NFT owners to transfer ownership.
 *   5. `setContentPrice(uint256 _tokenId, uint256 _price)`: Allows content NFT owners to set a price for their content.
 *   6. `purchaseContentNFT(uint256 _tokenId)`: Allows users to purchase content NFTs directly from the owner.
 *   7. `likeContent(uint256 _tokenId)`: Allows registered users to "like" content, contributing to a reputation system.
 *   8. `reportContent(uint256 _tokenId, string _reportReason)`: Allows registered users to report content for moderation.
 *   9. `followUser(address _userAddress)`: Allows registered users to follow other users.
 *  10. `unfollowUser(address _userAddress)`: Allows registered users to unfollow other users.
 *
 * **Advanced Features:**
 *  11. `createSubscriptionTier(string _tierName, uint256 _monthlyFee, string _description)`: Allows content creators to create subscription tiers for exclusive content access.
 *  12. `subscribeToCreator(address _creatorAddress, uint256 _tierId)`: Allows users to subscribe to a creator's tier.
 *  13. `unsubscribeFromCreator(address _creatorAddress)`: Allows users to unsubscribe from a creator.
 *  14. `withdrawCreatorEarnings()`: Allows content creators to withdraw their accumulated earnings from content sales and subscriptions.
 *  15. `tipCreator(address _creatorAddress)`: Allows users to send tips to content creators.
 *
 * **Governance & Community Features:**
 *  16. `proposeContentCategory(string _categoryName, string _categoryDescription)`: Allows users to propose new content categories for the platform.
 *  17. `voteOnCategoryProposal(uint256 _proposalId, bool _vote)`: Allows registered users to vote on category proposals.
 *  18. `addModerator(address _moderatorAddress)`: Allows the contract owner to add moderators to the platform.
 *  19. `removeModerator(address _moderatorAddress)`: Allows the contract owner to remove moderators.
 *  20. `moderateContent(uint256 _tokenId, bool _isApproved, string _moderationReason)`: Allows moderators to review and moderate reported content.
 *  21. `setPlatformFee(uint256 _newFeePercentage)`: Allows the contract owner to set the platform fee percentage on content sales.
 *  22. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *
 * **Events:**
 *   - `UserRegistered(address userAddress, string username)`
 *   - `ProfileUpdated(address userAddress, string profileCID)`
 *   - `ContentNFTCreated(uint256 tokenId, address creator, string contentCID, string metadataCID)`
 *   - `ContentNFTTransferred(uint256 tokenId, address from, address to)`
 *   - `ContentPriceSet(uint256 tokenId, uint256 price)`
 *   - `ContentNFTPurchased(uint256 tokenId, address buyer, address seller, uint256 price)`
 *   - `ContentLiked(uint256 tokenId, address user)`
 *   - `ContentReported(uint256 tokenId, address reporter, string reason)`
 *   - `UserFollowed(address follower, address followee)`
 *   - `UserUnfollowed(address follower, address followee)`
 *   - `SubscriptionTierCreated(uint256 tierId, address creator, string tierName, uint256 monthlyFee)`
 *   - `UserSubscribed(address subscriber, address creator, uint256 tierId)`
 *   - `UserUnsubscribed(address subscriber, address creator)`
 *   - `CreatorEarningsWithdrawn(address creator, uint256 amount)`
 *   - `CreatorTipped(address tipper, address creator, uint256 amount)`
 *   - `CategoryProposed(uint256 proposalId, string categoryName)`
 *   - `CategoryProposalVoted(uint256 proposalId, address voter, bool vote)`
 *   - `ModeratorAdded(address moderator)`
 *   - `ModeratorRemoved(address moderator)`
 *   - `ContentModerated(uint256 tokenId, bool isApproved, string reason, address moderator)`
 *   - `PlatformFeeSet(uint256 newFeePercentage)`
 *   - `PlatformFeesWithdrawn(uint256 amount)`
 */
contract DecentralizedAutonomousContentPlatform {

    // State Variables

    address public owner; // Contract owner
    uint256 public platformFeePercentage = 5; // Platform fee percentage on content sales
    uint256 public platformFeesCollected = 0; // Accumulated platform fees

    uint256 public nextContentTokenId = 1; // Counter for content NFT token IDs
    uint256 public nextProposalId = 1; // Counter for category proposal IDs
    uint256 public nextSubscriptionTierId = 1; // Counter for subscription tier IDs

    mapping(address => string) public usernames; // User address to username
    mapping(address => string) public profiles; // User address to profile CID
    mapping(uint256 => ContentNFT) public contentNFTs; // Token ID to Content NFT struct
    mapping(uint256 => uint256) public contentPrices; // Token ID to price in wei
    mapping(uint256 => uint256) public contentLikes; // Token ID to like count
    mapping(uint256 => Report[]) public contentReports; // Token ID to array of reports
    mapping(address => mapping(address => bool)) public following; // Follower -> Followee -> Is Following
    mapping(address => mapping(uint256 => SubscriptionTier)) public creatorSubscriptionTiers; // Creator -> Tier ID -> Subscription Tier
    mapping(address => mapping(address => uint256)) public userSubscriptions; // Subscriber -> Creator -> Tier ID (0 if not subscribed)
    mapping(address => uint256) public creatorEarnings; // Creator address to accumulated earnings
    mapping(uint256 => CategoryProposal) public categoryProposals; // Proposal ID to Category Proposal struct
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID -> Voter -> Vote (true for yes, false for no)
    mapping(address => bool) public moderators; // Moderator address to boolean (is moderator)
    mapping(uint256 => bool) public contentModerationStatus; // Token ID to moderation approval status (true = approved)

    address[] public registeredUsers; // Array of registered user addresses
    address[] public moderatorsList; // Array of moderator addresses
    uint256[] public contentTokenIds; // Array of all content token IDs
    uint256[] public proposalIds; // Array of all proposal IDs
    uint256[] public subscriptionTierIds; // Array of all subscription tier IDs

    // Structs

    struct ContentNFT {
        uint256 tokenId;
        address creator;
        string contentCID;
        string metadataCID;
        string[] tags;
        uint256 royaltyFee; // Percentage, e.g., 5 for 5%
        uint256 createdAt;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 reportedAt;
    }

    struct SubscriptionTier {
        uint256 tierId;
        string tierName;
        uint256 monthlyFee;
        string description;
        uint256 createdAt;
    }

    struct CategoryProposal {
        uint256 proposalId;
        string categoryName;
        string categoryDescription;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 createdAt;
    }

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(bytes(usernames[msg.sender]).length > 0, "Must be a registered user.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function.");
        _;
    }

    modifier contentNFTOwner(uint256 _tokenId) {
        require(contentNFTs[_tokenId].creator == msg.sender, "Only content NFT owner can call this function.");
        _;
    }

    modifier validContentNFT(uint256 _tokenId) {
        require(contentNFTs[_tokenId].tokenId != 0, "Invalid Content NFT Token ID.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(categoryProposals[_proposalId].proposalId != 0, "Invalid Proposal ID.");
        _;
    }

    modifier validSubscriptionTier(uint256 _tierId, address _creatorAddress) {
        require(creatorSubscriptionTiers[_creatorAddress][_tierId].tierId != 0, "Invalid Subscription Tier ID.");
        _;
    }


    // Constructor
    constructor() {
        owner = msg.sender;
        moderators[owner] = true; // Owner is also a moderator initially
        moderatorsList.push(owner);
    }

    // -------------------- Core Functionality --------------------

    /**
     * @dev Registers a new user on the platform.
     * @param _username The desired username. Must be unique.
     * @param _profileCID The CID of the user's profile metadata (e.g., IPFS CID).
     */
    function registerUser(string memory _username, string memory _profileCID) public {
        require(bytes(usernames[msg.sender]).length == 0, "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        // To implement username uniqueness, you'd need to maintain a mapping of usernames to addresses or check against existing usernames.
        // For simplicity, we're skipping strict username uniqueness in this example but it's crucial in a real application.

        usernames[msg.sender] = _username;
        profiles[msg.sender] = _profileCID;
        registeredUsers.push(msg.sender);

        emit UserRegistered(msg.sender, _username);
    }

    /**
     * @dev Updates the profile metadata CID of a registered user.
     * @param _newProfileCID The new CID of the user's profile metadata.
     */
    function updateProfile(string memory _newProfileCID) public onlyRegisteredUser {
        profiles[msg.sender] = _newProfileCID;
        emit ProfileUpdated(msg.sender, _newProfileCID);
    }

    /**
     * @dev Creates content and mints it as a unique NFT.
     * @param _contentCID The CID of the content itself (e.g., IPFS CID).
     * @param _metadataCID The CID of the content metadata (e.g., title, description, thumbnail).
     * @param _tags Array of tags associated with the content.
     * @param _royaltyFee Royalty fee percentage for secondary sales (0-100).
     */
    function createContentNFT(string memory _contentCID, string memory _metadataCID, string[] memory _tags, uint256 _royaltyFee) public onlyRegisteredUser {
        require(_royaltyFee <= 100, "Royalty fee must be between 0 and 100.");

        uint256 tokenId = nextContentTokenId++;
        contentNFTs[tokenId] = ContentNFT({
            tokenId: tokenId,
            creator: msg.sender,
            contentCID: _contentCID,
            metadataCID: _metadataCID,
            tags: _tags,
            royaltyFee: _royaltyFee,
            createdAt: block.timestamp
        });
        contentModerationStatus[tokenId] = false; // Content initially unmoderated/pending
        contentTokenIds.push(tokenId);

        emit ContentNFTCreated(tokenId, msg.sender, _contentCID, _metadataCID);
    }

    /**
     * @dev Transfers ownership of a content NFT.
     * @param _tokenId The ID of the content NFT to transfer.
     * @param _to The address to transfer the NFT to.
     */
    function transferContentNFT(uint256 _tokenId, address _to) public validContentNFT contentNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        require(_to != msg.sender, "Cannot transfer to yourself.");

        contentNFTs[_tokenId].creator = _to; // Simple owner transfer for this example
        emit ContentNFTTransferred(_tokenId, msg.sender, _to);
    }

    /**
     * @dev Sets the price for a content NFT.
     * @param _tokenId The ID of the content NFT.
     * @param _price The price in wei.
     */
    function setContentPrice(uint256 _tokenId, uint256 _price) public validContentNFT contentNFTOwner(_tokenId) {
        contentPrices[_tokenId] = _price;
        emit ContentPriceSet(_tokenId, _price);
    }

    /**
     * @dev Allows users to purchase a content NFT directly from the owner.
     * @param _tokenId The ID of the content NFT to purchase.
     */
    function purchaseContentNFT(uint256 _tokenId) public payable validContentNFT {
        require(contentPrices[_tokenId] > 0, "Content NFT is not for sale.");
        uint256 price = contentPrices[_tokenId];
        require(msg.value >= price, "Insufficient funds sent.");

        address seller = contentNFTs[_tokenId].creator;
        require(seller != msg.sender, "Cannot purchase your own content.");

        // Transfer funds (with platform fee)
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 creatorShare = price - platformFee;

        payable(owner).transfer(platformFee);
        payable(seller).transfer(creatorShare);

        platformFeesCollected += platformFee;
        creatorEarnings[seller] += creatorShare;

        // Transfer NFT ownership
        contentNFTs[_tokenId].creator = msg.sender;
        delete contentPrices[_tokenId]; // Remove from sale after purchase

        emit ContentNFTPurchased(_tokenId, msg.sender, seller, price);
        emit ContentNFTTransferred(_tokenId, seller, msg.sender); // Emit transfer event again for clarity
    }

    /**
     * @dev Allows registered users to "like" content.
     * @param _tokenId The ID of the content NFT to like.
     */
    function likeContent(uint256 _tokenId) public onlyRegisteredUser validContentNFT {
        contentLikes[_tokenId]++;
        emit ContentLiked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows registered users to report content for moderation.
     * @param _tokenId The ID of the content NFT being reported.
     * @param _reportReason The reason for reporting.
     */
    function reportContent(uint256 _tokenId, string memory _reportReason) public onlyRegisteredUser validContentNFT {
        Report memory newReport = Report({
            reporter: msg.sender,
            reason: _reportReason,
            reportedAt: block.timestamp
        });
        contentReports[_tokenId].push(newReport);
        emit ContentReported(_tokenId, msg.sender, _reportReason);
    }

    /**
     * @dev Allows registered users to follow another user.
     * @param _userAddress The address of the user to follow.
     */
    function followUser(address _userAddress) public onlyRegisteredUser {
        require(_userAddress != msg.sender, "Cannot follow yourself.");
        require(bytes(usernames[_userAddress]).length > 0, "User to follow is not registered.");

        following[msg.sender][_userAddress] = true;
        emit UserFollowed(msg.sender, _userAddress);
    }

    /**
     * @dev Allows registered users to unfollow another user.
     * @param _userAddress The address of the user to unfollow.
     */
    function unfollowUser(address _userAddress) public onlyRegisteredUser {
        following[msg.sender][_userAddress] = false;
        emit UserUnfollowed(msg.sender, _userAddress);
    }

    // -------------------- Advanced Features --------------------

    /**
     * @dev Allows content creators to create subscription tiers.
     * @param _tierName The name of the subscription tier.
     * @param _monthlyFee The monthly fee in wei.
     * @param _description Description of the tier benefits.
     */
    function createSubscriptionTier(string memory _tierName, uint256 _monthlyFee, string memory _description) public onlyRegisteredUser {
        require(bytes(_tierName).length > 0, "Tier name cannot be empty.");
        require(_monthlyFee > 0, "Monthly fee must be greater than zero.");

        uint256 tierId = nextSubscriptionTierId++;
        creatorSubscriptionTiers[msg.sender][tierId] = SubscriptionTier({
            tierId: tierId,
            tierName: _tierName,
            monthlyFee: _monthlyFee,
            description: _description,
            createdAt: block.timestamp
        });
        subscriptionTierIds.push(tierId);
        emit SubscriptionTierCreated(tierId, msg.sender, _tierName, _monthlyFee);
    }

    /**
     * @dev Allows users to subscribe to a creator's subscription tier.
     * @param _creatorAddress The address of the content creator.
     * @param _tierId The ID of the subscription tier.
     */
    function subscribeToCreator(address _creatorAddress, uint256 _tierId) public payable onlyRegisteredUser validSubscriptionTier(_tierId, _creatorAddress) {
        SubscriptionTier memory tier = creatorSubscriptionTiers[_creatorAddress][_tierId];
        require(msg.value >= tier.monthlyFee, "Insufficient funds for subscription.");
        require(userSubscriptions[msg.sender][_creatorAddress] == 0, "Already subscribed to this creator.");

        payable(_creatorAddress).transfer(tier.monthlyFee);
        creatorEarnings[_creatorAddress] += tier.monthlyFee;
        userSubscriptions[msg.sender][_creatorAddress] = _tierId;

        emit UserSubscribed(msg.sender, _creatorAddress, _tierId);
    }

    /**
     * @dev Allows users to unsubscribe from a creator.
     * @param _creatorAddress The address of the content creator.
     */
    function unsubscribeFromCreator(address _creatorAddress) public onlyRegisteredUser {
        require(userSubscriptions[msg.sender][_creatorAddress] != 0, "Not subscribed to this creator.");

        userSubscriptions[msg.sender][_creatorAddress] = 0; // Set tier ID to 0 to indicate no subscription
        emit UserUnsubscribed(msg.sender, _creatorAddress);
    }

    /**
     * @dev Allows content creators to withdraw their accumulated earnings.
     */
    function withdrawCreatorEarnings() public onlyRegisteredUser {
        uint256 amount = creatorEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw.");

        creatorEarnings[msg.sender] = 0; // Reset earnings to 0 after withdrawal
        payable(msg.sender).transfer(amount);
        emit CreatorEarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows users to send tips to content creators.
     * @param _creatorAddress The address of the content creator to tip.
     */
    function tipCreator(address _creatorAddress) public payable onlyRegisteredUser {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        require(bytes(usernames[_creatorAddress]).length > 0, "Creator is not a registered user.");

        payable(_creatorAddress).transfer(msg.value);
        creatorEarnings[_creatorAddress] += msg.value;
        emit CreatorTipped(msg.sender, _creatorAddress, msg.value);
    }


    // -------------------- Governance & Community Features --------------------

    /**
     * @dev Allows users to propose new content categories.
     * @param _categoryName The name of the proposed category.
     * @param _categoryDescription A description of the category.
     */
    function proposeContentCategory(string memory _categoryName, string memory _categoryDescription) public onlyRegisteredUser {
        require(bytes(_categoryName).length > 0, "Category name cannot be empty.");

        uint256 proposalId = nextProposalId++;
        categoryProposals[proposalId] = CategoryProposal({
            proposalId: proposalId,
            categoryName: _categoryName,
            categoryDescription: _categoryDescription,
            yesVotes: 0,
            noVotes: 0,
            createdAt: block.timestamp
        });
        proposalIds.push(proposalId);
        emit CategoryProposed(proposalId, _categoryName);
    }

    /**
     * @dev Allows registered users to vote on category proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnCategoryProposal(uint256 _proposalId, bool _vote) public onlyRegisteredUser validProposal(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "User has already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true; // Record user's vote

        if (_vote) {
            categoryProposals[_proposalId].yesVotes++;
        } else {
            categoryProposals[_proposalId].noVotes++;
        }
        emit CategoryProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Adds a new moderator to the platform. Only callable by the contract owner.
     * @param _moderatorAddress The address to add as a moderator.
     */
    function addModerator(address _moderatorAddress) public onlyOwner {
        require(!moderators[_moderatorAddress], "Address is already a moderator.");
        moderators[_moderatorAddress] = true;
        moderatorsList.push(_moderatorAddress);
        emit ModeratorAdded(_moderatorAddress);
    }

    /**
     * @dev Removes a moderator from the platform. Only callable by the contract owner.
     * @param _moderatorAddress The address of the moderator to remove.
     */
    function removeModerator(address _moderatorAddress) public onlyOwner {
        require(moderators[_moderatorAddress], "Address is not a moderator.");
        require(_moderatorAddress != owner, "Cannot remove the contract owner as moderator."); // Prevent removing owner

        moderators[_moderatorAddress] = false;
        // Remove from moderatorsList array (can be optimized for gas if needed for very large lists)
        for (uint256 i = 0; i < moderatorsList.length; i++) {
            if (moderatorsList[i] == _moderatorAddress) {
                moderatorsList[i] = moderatorsList[moderatorsList.length - 1];
                moderatorsList.pop();
                break;
            }
        }
        emit ModeratorRemoved(_moderatorAddress);
    }

    /**
     * @dev Allows moderators to review and moderate reported content.
     * @param _tokenId The ID of the content NFT to moderate.
     * @param _isApproved True if content is approved, false if rejected/removed.
     * @param _moderationReason Reason for moderation action.
     */
    function moderateContent(uint256 _tokenId, bool _isApproved, string memory _moderationReason) public onlyModerator validContentNFT {
        contentModerationStatus[_tokenId] = _isApproved;
        emit ContentModerated(_tokenId, _isApproved, _moderationReason, msg.sender);
    }

    /**
     * @dev Sets the platform fee percentage on content sales. Only callable by the contract owner.
     * @param _newFeePercentage The new platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage must be between 0 and 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = platformFeesCollected;
        require(amount > 0, "No platform fees to withdraw.");

        platformFeesCollected = 0;
        payable(owner).transfer(amount);
        emit PlatformFeesWithdrawn(amount);
    }

    // Fallback function to receive Ether for tips and subscriptions
    receive() external payable {}
}
```