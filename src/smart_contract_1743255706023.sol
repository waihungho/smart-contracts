```solidity
/**
 * @title Decentralized Autonomous Content Platform (DACP) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A creative and advanced smart contract implementing a Decentralized Autonomous Content Platform.
 *      This platform allows users to create, publish, curate, and monetize content, governed by a DAO.
 *      It incorporates features like content NFTs, decentralized moderation, reputation system,
 *      and advanced subscription models, aiming for a censorship-resistant and community-driven content ecosystem.
 *
 * **Outline and Function Summary:**
 *
 * **1. Platform Management & Governance (DAO):**
 *    - `initializePlatform(address _governanceTokenAddress, uint256 _platformFeePercentage)`: Initializes platform settings and governance token.
 *    - `setPlatformFee(uint256 _platformFeePercentage)`: Updates the platform fee percentage (governed by DAO).
 *    - `pausePlatform()`: Pauses core platform functionalities (governed by DAO).
 *    - `unpausePlatform()`: Resumes platform functionalities (governed by DAO).
 *    - `proposePlatformChange(string _description, bytes _calldata)`: Allows governance token holders to propose changes.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows governance token holders to vote on proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes approved proposals (governance controlled).
 *
 * **2. User & Profile Management:**
 *    - `createUserProfile(string _username, string _profileMetadataURI)`: Creates a user profile.
 *    - `updateUserProfile(string _profileMetadataURI)`: Updates an existing user profile.
 *    - `followCreator(address _creatorAddress)`: Allows users to follow content creators.
 *    - `unfollowCreator(address _creatorAddress)`: Allows users to unfollow content creators.
 *    - `getUserProfile(address _userAddress)`: Retrieves user profile information.
 *    - `isFollowing(address _follower, address _creator)`: Checks if a user is following a creator.
 *
 * **3. Content Creation & Management:**
 *    - `publishContent(string _contentURI, string _metadataURI, string[] _tags)`: Publishes new content.
 *    - `editContent(uint256 _contentId, string _contentURI, string _metadataURI, string[] _tags)`: Edits existing content.
 *    - `setContentCategory(uint256 _contentId, string _category)`: Sets a category for content.
 *    - `getContentById(uint256 _contentId)`: Retrieves content information by ID.
 *    - `getContentByCreator(address _creatorAddress)`: Retrieves content IDs published by a creator.
 *    - `getContentByCategory(string _category)`: Retrieves content IDs within a category.
 *    - `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 *
 * **4. Content Monetization & Subscription:**
 *    - `setContentPricing(uint256 _contentId, uint256 _price)`: Sets a price for accessing specific content (pay-per-view).
 *    - `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to priced content.
 *    - `createSubscriptionPlan(string _planName, uint256 _monthlyFee, string _planDescription)`: Creators can define subscription plans.
 *    - `subscribeToCreator(address _creatorAddress, uint256 _planId)`: Users can subscribe to a creator's plan.
 *    - `unsubscribeFromCreator(address _creatorAddress)`: Users can unsubscribe from a creator.
 *    - `getSubscriptionDetails(address _subscriber, address _creator)`: Retrieves subscription details for a user-creator pair.
 *
 * **5. Content NFT & Ownership (Advanced):**
 *    - `createContentNFT(uint256 _contentId, string _nftMetadataURI)`: Creates an NFT representing ownership of specific content.
 *    - `setContentNFTPrice(uint256 _contentId, uint256 _price)`: Sets a price for the content NFT.
 *    - `purchaseContentNFT(uint256 _contentId)`: Allows users to purchase the content NFT, gaining ownership.
 *    - `transferContentNFT(uint256 _contentId, address _recipient)`: Transfers ownership of a content NFT.
 *    - `getContentNFTOwner(uint256 _contentId)`: Retrieves the owner of a content NFT.
 *
 * **6. Decentralized Moderation & Reputation (Advanced):**
 *    - `stakeForModeration(uint256 _stakeAmount)`: Users can stake tokens to become moderators (requires governance token).
 *    - `unstakeFromModeration()`: Moderators can unstake their tokens.
 *    - `submitModerationVote(uint256 _reportId, bool _isHarmful)`: Moderators vote on reported content.
 *    - `rewardModerators(uint256 _reportId)`: Rewards moderators for accurate moderation (governance controlled).
 *    - `penalizeModerators(uint256 _reportId)`: Penalizes moderators for inaccurate/malicious moderation (governance controlled).
 *    - `getModeratorStake(address _moderatorAddress)`: Retrieves the stake amount of a moderator.
 *    - `getModerationReportStatus(uint256 _reportId)`: Retrieves the status of a moderation report.
 *
 * **7. Platform Revenue & Withdrawal:**
 *    - `withdrawPlatformFees(address _recipient)`: Allows the platform owner (DAO/governance) to withdraw collected platform fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DecentralizedAutonomousContentPlatform is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ** State Variables **

    IERC20 public governanceToken; // Address of the governance token contract
    uint256 public platformFeePercentage; // Percentage of content sales taken as platform fee (e.g., 5 for 5%)
    bool public platformPaused; // Flag to pause/unpause platform functionalities
    address public platformTreasury; // Address to receive platform fees (initially owner, can be DAO controlled)

    Counters.Counter private _contentIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _reportIdCounter;
    Counters.Counter private _planIdCounter;

    // Structs to organize data

    struct UserProfile {
        string username;
        string profileMetadataURI;
        EnumerableSet.AddressSet followers; // Set of addresses following this user
        EnumerableSet.AddressSet following; // Set of addresses this user is following
    }

    struct Content {
        uint256 id;
        address creator;
        string contentURI;
        string metadataURI;
        string[] tags;
        string category;
        uint256 price; // Price for pay-per-view access (0 for free)
        bool isNFTCreated; // Flag if an NFT has been created for this content
        address nftOwner; // Address of the NFT owner (if NFT created)
    }

    struct SubscriptionPlan {
        uint256 id;
        address creator;
        string planName;
        uint256 monthlyFee;
        string planDescription;
    }

    struct Subscription {
        uint256 planId;
        uint256 startTime;
        uint256 nextBillingTime; // Timestamp for next billing cycle
        bool isActive;
    }

    struct Proposal {
        uint256 id;
        string description;
        bytes calldata;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    struct ModerationReport {
        uint256 id;
        uint256 contentId;
        address reporter;
        string reason;
        bool resolved;
        bool isHarmful; // Determined by moderators
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(address => bool) moderatorsVoted; // Track moderators who voted
    }

    struct Moderator {
        uint256 stakeAmount;
        uint256 lastActiveTime; // Timestamp of last moderation activity
    }


    // Mappings to store platform data

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Content) public contentRegistry;
    mapping(uint256 => SubscriptionPlan) public subscriptionPlans;
    mapping(address => mapping(address => Subscription)) public subscriptions; // Subscriber => Creator => Subscription
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => ModerationReport) public moderationReports;
    mapping(address => Moderator) public moderators;
    mapping(uint256 => address) public contentNFTToOwner; // Content ID to NFT Owner
    mapping(uint256 => uint256) public contentToNFTPrice; // Content ID to NFT Price

    // Events

    event PlatformInitialized(address governanceTokenAddress, uint256 platformFeePercentage, address treasury);
    event PlatformFeeUpdated(uint256 newPlatformFeePercentage);
    event PlatformPaused();
    event PlatformUnpaused();
    event ProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress);
    event CreatorFollowed(address follower, address creator);
    event CreatorUnfollowed(address follower, address creator);
    event ContentPublished(uint256 contentId, address creator);
    event ContentEdited(uint256 contentId);
    event ContentCategorySet(uint256 contentId, string category);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentAccessPurchased(uint256 contentId, address purchaser);
    event SubscriptionPlanCreated(uint256 planId, address creator, string planName);
    event SubscriptionStarted(address subscriber, address creator, uint256 planId);
    event SubscriptionCancelled(address subscriber, address creator);
    event ContentNFTCreated(uint256 contentId, address creator);
    event ContentNFTPriceSet(uint256 contentId, uint256 price);
    event ContentNFTPurchased(uint256 contentId, address purchaser);
    event ContentNFTTransferred(uint256 contentId, address from, address to);
    event ContentReported(uint256 reportId, uint256 contentId, address reporter);
    event ModeratorStaked(address moderator, uint256 stakeAmount);
    event ModeratorUnstaked(address moderator, uint256 unstakedAmount);
    event ModerationVoteSubmitted(uint256 reportId, address moderator, bool isHarmful);
    event ModeratorsRewarded(uint256 reportId);
    event ModeratorsPenalized(uint256 reportId);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);


    // ** Modifiers **

    modifier onlyPlatformOwner() {
        require(msg.sender == owner(), "Only platform owner can call this function");
        _;
    }

    modifier onlyGovernanceTokenHolders() {
        require(governanceToken.balanceOf(msg.sender) > 0, "Only governance token holders can call this function");
        _;
    }

    modifier platformNotPaused() {
        require(!platformPaused, "Platform is currently paused");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(contentRegistry[_contentId].id != 0, "Content does not exist");
        _;
    }

    modifier userProfileExists(address _userAddress) {
        require(bytes(userProfiles[_userAddress].username).length > 0, "User profile does not exist");
        _;
    }

    modifier subscriptionPlanExists(uint256 _planId) {
        require(subscriptionPlans[_planId].id != 0, "Subscription plan does not exist");
        _;
    }

    modifier isContentCreator(uint256 _contentId) {
        require(contentRegistry[_contentId].creator == msg.sender, "Only content creator can perform this action");
        _;
    }

    modifier isContentNFTOwner(uint256 _contentId) {
        require(contentNFTToOwner[_contentId] == msg.sender, "Only content NFT owner can perform this action");
        _;
    }

    modifier isSubscribedToCreator(address _subscriber, address _creator) {
        require(subscriptions[_subscriber][_creator].isActive, "Not subscribed to this creator");
        _;
    }

    modifier isNotSubscribedToCreator(address _subscriber, address _creator) {
        require(!subscriptions[_subscriber][_creator].isActive, "Already subscribed to this creator");
        _;
    }

    modifier isModerator(address _moderatorAddress) {
        require(moderators[_moderatorAddress].stakeAmount > 0, "Not a moderator");
        _;
    }

    modifier reportExists(uint256 _reportId) {
        require(moderationReports[_reportId].id != 0, "Moderation report does not exist");
        _;
    }

    modifier reportNotResolved(uint256 _reportId) {
        require(!moderationReports[_reportId].resolved, "Moderation report already resolved");
        _;
    }

    modifier moderatorHasNotVoted(uint256 _reportId, address _moderatorAddress) {
        require(!moderationReports[_reportId].moderatorsVoted[_moderatorAddress], "Moderator has already voted on this report");
        _;
    }


    // ** 1. Platform Management & Governance (DAO) **

    constructor() Ownable() {
        platformTreasury = owner(); // Initially platform treasury is the contract owner
        platformPaused = false;
    }

    function initializePlatform(address _governanceTokenAddress, uint256 _platformFeePercentage) external onlyPlatformOwner {
        require(_governanceTokenAddress != address(0), "Governance token address cannot be zero");
        require(_platformFeePercentage <= 100, "Platform fee percentage cannot exceed 100");
        governanceToken = IERC20(_governanceTokenAddress);
        platformFeePercentage = _platformFeePercentage;
        emit PlatformInitialized(_governanceTokenAddress, _platformFeePercentage, platformTreasury);
    }

    function setPlatformFee(uint256 _platformFeePercentage) external onlyGovernanceTokenHolders platformNotPaused {
        require(_platformFeePercentage <= 100, "Platform fee percentage cannot exceed 100");
        platformFeePercentage = _platformFeePercentage;
        emit PlatformFeeUpdated(_platformFeePercentage);
    }

    function pausePlatform() external onlyGovernanceTokenHolders {
        platformPaused = true;
        emit PlatformPaused();
    }

    function unpausePlatform() external onlyGovernanceTokenHolders {
        platformPaused = false;
        emit PlatformUnpaused();
    }

    function proposePlatformChange(string memory _description, bytes memory _calldata) external onlyGovernanceTokenHolders platformNotPaused {
        uint256 proposalId = _proposalIdCounter.increment();
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            calldata: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalId, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernanceTokenHolders platformNotPaused {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        if (_support) {
            proposals[_proposalId].votesFor += governanceToken.balanceOf(msg.sender);
        } else {
            proposals[_proposalId].votesAgainst += governanceToken.balanceOf(msg.sender);
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyGovernanceTokenHolders platformNotPaused {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        // Simple majority for execution (can be adjusted based on governance rules)
        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        require(proposals[_proposalId].votesFor > totalVotes / 2, "Proposal not approved");

        (bool success, ) = address(this).call(proposals[_proposalId].calldata); // Execute the proposed function call
        require(success, "Proposal execution failed");
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }


    // ** 2. User & Profile Management **

    function createUserProfile(string memory _username, string memory _profileMetadataURI) external platformNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "Profile already exists for this address");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be 1-32 characters");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileMetadataURI: _profileMetadataURI,
            followers: EnumerableSet.AddressSet(),
            following: EnumerableSet.AddressSet()
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    function updateUserProfile(string memory _profileMetadataURI) external userProfileExists(msg.sender) platformNotPaused {
        userProfiles[msg.sender].profileMetadataURI = _profileMetadataURI;
        emit UserProfileUpdated(msg.sender);
    }

    function followCreator(address _creatorAddress) external userProfileExists(msg.sender) userProfileExists(_creatorAddress) platformNotPaused {
        require(msg.sender != _creatorAddress, "Cannot follow yourself");
        require(!userProfiles[msg.sender].following.contains(_creatorAddress), "Already following this creator");
        userProfiles[msg.sender].following.add(_creatorAddress);
        userProfiles[_creatorAddress].followers.add(msg.sender);
        emit CreatorFollowed(msg.sender, _creatorAddress);
    }

    function unfollowCreator(address _creatorAddress) external userProfileExists(msg.sender) userProfileExists(_creatorAddress) platformNotPaused {
        require(userProfiles[msg.sender].following.contains(_creatorAddress), "Not following this creator");
        userProfiles[msg.sender].following.remove(_creatorAddress);
        userProfiles[_creatorAddress].followers.remove(msg.sender);
        emit CreatorUnfollowed(msg.sender, _creatorAddress);
    }

    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function isFollowing(address _follower, address _creator) external view returns (bool) {
        return userProfiles[_follower].following.contains(_creator);
    }


    // ** 3. Content Creation & Management **

    function publishContent(string memory _contentURI, string memory _metadataURI, string[] memory _tags) external userProfileExists(msg.sender) platformNotPaused returns (uint256) {
        uint256 contentId = _contentIdCounter.increment();
        contentRegistry[contentId] = Content({
            id: contentId,
            creator: msg.sender,
            contentURI: _contentURI,
            metadataURI: _metadataURI,
            tags: _tags,
            category: "", // Initially no category
            price: 0,     // Initially free
            isNFTCreated: false,
            nftOwner: address(0) // No NFT owner yet
        });
        emit ContentPublished(contentId, msg.sender);
        return contentId;
    }

    function editContent(uint256 _contentId, string memory _contentURI, string memory _metadataURI, string[] memory _tags) external contentExists(_contentId) isContentCreator(_contentId) platformNotPaused {
        contentRegistry[_contentId].contentURI = _contentURI;
        contentRegistry[_contentId].metadataURI = _metadataURI;
        contentRegistry[_contentId].tags = _tags;
        emit ContentEdited(_contentId);
    }

    function setContentCategory(uint256 _contentId, string memory _category) external contentExists(_contentId) isContentCreator(_contentId) platformNotPaused {
        contentRegistry[_contentId].category = _category;
        emit ContentCategorySet(_contentId, _category);
    }

    function getContentById(uint256 _contentId) external view contentExists(_contentId) returns (Content memory) {
        return contentRegistry[_contentId];
    }

    function getContentByCreator(address _creatorAddress) external view userProfileExists(_creatorAddress) returns (uint256[] memory) {
        uint256[] memory creatorContentIds = new uint256[](_contentIdCounter.current()); // Max size initially, will resize
        uint256 count = 0;
        for (uint256 i = 1; i <= _contentIdCounter.current(); i++) {
            if (contentRegistry[i].creator == _creatorAddress) {
                creatorContentIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of content IDs
        uint256[] memory resizedContentIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedContentIds[i] = creatorContentIds[i];
        }
        return resizedContentIds;
    }

    function getContentByCategory(string memory _category) external view returns (uint256[] memory) {
        uint256[] memory categoryContentIds = new uint256[](_contentIdCounter.current()); // Max size initially, will resize
        uint256 count = 0;
        for (uint256 i = 1; i <= _contentIdCounter.current(); i++) {
            if (keccak256(bytes(contentRegistry[i].category)) == keccak256(bytes(_category))) {
                categoryContentIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of content IDs
        uint256[] memory resizedContentIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedContentIds[i] = categoryContentIds[i];
        }
        return resizedContentIds;
    }

    function reportContent(uint256 _contentId, string memory _reportReason) external userProfileExists(msg.sender) contentExists(_contentId) platformNotPaused {
        uint256 reportId = _reportIdCounter.increment();
        moderationReports[reportId] = ModerationReport({
            id: reportId,
            contentId: _contentId,
            reporter: msg.sender,
            reason: _reportReason,
            resolved: false,
            isHarmful: false, // Initially undetermined
            positiveVotes: 0,
            negativeVotes: 0,
            moderatorsVoted: mapping(address => bool)()
        });
        emit ContentReported(reportId, _contentId, msg.sender);
    }


    // ** 4. Content Monetization & Subscription **

    function setContentPricing(uint256 _contentId, uint256 _price) external contentExists(_contentId) isContentCreator(_contentId) platformNotPaused {
        contentRegistry[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    function purchaseContentAccess(uint256 _contentId) payable external userProfileExists(msg.sender) contentExists(_contentId) platformNotPaused {
        require(contentRegistry[_contentId].price > 0, "Content is not priced");
        require(msg.value >= contentRegistry[_contentId].price, "Insufficient payment");

        // Transfer funds to creator (minus platform fee)
        uint256 platformFee = (contentRegistry[_contentId].price * platformFeePercentage) / 100;
        uint256 creatorShare = contentRegistry[_contentId].price - platformFee;

        payable(contentRegistry[_contentId].creator).transfer(creatorShare);
        payable(platformTreasury).transfer(platformFee); // Platform fee goes to treasury

        emit ContentAccessPurchased(_contentId, msg.sender);

        // Consider adding logic to track user access to content (off-chain for scalability, or on-chain limited)
        // For demonstration, access is granted upon payment in this simple example.
    }

    function createSubscriptionPlan(string memory _planName, uint256 _monthlyFee, string memory _planDescription) external userProfileExists(msg.sender) platformNotPaused returns (uint256) {
        uint256 planId = _planIdCounter.increment();
        subscriptionPlans[planId] = SubscriptionPlan({
            id: planId,
            creator: msg.sender,
            planName: _planName,
            monthlyFee: _monthlyFee,
            planDescription: _planDescription
        });
        emit SubscriptionPlanCreated(planId, msg.sender, _planName);
        return planId;
    }

    function subscribeToCreator(address _creatorAddress, uint256 _planId) payable external userProfileExists(msg.sender) userProfileExists(_creatorAddress) subscriptionPlanExists(_planId) isNotSubscribedToCreator(msg.sender, _creatorAddress) platformNotPaused {
        SubscriptionPlan storage plan = subscriptionPlans[_planId];
        require(_creatorAddress == plan.creator, "Plan creator mismatch");
        require(msg.value >= plan.monthlyFee, "Insufficient subscription fee");

        // Transfer subscription fee (minus platform fee)
        uint256 platformFee = (plan.monthlyFee * platformFeePercentage) / 100;
        uint256 creatorShare = plan.monthlyFee - platformFee;

        payable(_creatorAddress).transfer(creatorShare);
        payable(platformTreasury).transfer(platformFee);

        subscriptions[msg.sender][_creatorAddress] = Subscription({
            planId: _planId,
            startTime: block.timestamp,
            nextBillingTime: block.timestamp + (30 days), // Assuming monthly subscription
            isActive: true
        });
        emit SubscriptionStarted(msg.sender, _creatorAddress, _planId);
    }

    function unsubscribeFromCreator(address _creatorAddress) external userProfileExists(msg.sender) userProfileExists(_creatorAddress) isSubscribedToCreator(msg.sender, _creatorAddress) platformNotPaused {
        subscriptions[msg.sender][_creatorAddress].isActive = false;
        emit SubscriptionCancelled(msg.sender, _creatorAddress);
    }

    function getSubscriptionDetails(address _subscriber, address _creator) external view returns (Subscription memory) {
        return subscriptions[_subscriber][_creator];
    }


    // ** 5. Content NFT & Ownership (Advanced) **

    function createContentNFT(uint256 _contentId, string memory _nftMetadataURI) external contentExists(_contentId) isContentCreator(_contentId) platformNotPaused {
        require(!contentRegistry[_contentId].isNFTCreated, "NFT already created for this content");

        contentRegistry[_contentId].isNFTCreated = true;
        contentNFTToOwner[_contentId] = msg.sender; // Initially creator owns the NFT
        emit ContentNFTCreated(_contentId, msg.sender);
        // In a real application, you would mint an actual ERC721 token and link it to this contentId.
        // This simplified example tracks ownership within this contract.
    }

    function setContentNFTPrice(uint256 _contentId, uint256 _price) external contentExists(_contentId) isContentCreator(_contentId) platformNotPaused {
        require(contentRegistry[_contentId].isNFTCreated, "NFT not yet created for this content");
        contentToNFTPrice[_contentId] = _price;
        emit ContentNFTPriceSet(_contentId, _price);
    }

    function purchaseContentNFT(uint256 _contentId) payable external userProfileExists(msg.sender) contentExists(_contentId) platformNotPaused {
        require(contentRegistry[_contentId].isNFTCreated, "NFT not yet created for this content");
        require(contentToNFTPrice[_contentId] > 0, "Content NFT is not priced");
        require(msg.value >= contentToNFTPrice[_contentId], "Insufficient payment for NFT");

        address currentOwner = contentNFTToOwner[_contentId];
        require(currentOwner != msg.sender, "You already own this NFT");

        // Transfer funds to current NFT owner (minus platform fee)
        uint256 nftPrice = contentToNFTPrice[_contentId];
        uint256 platformFee = (nftPrice * platformFeePercentage) / 100;
        uint256 sellerShare = nftPrice - platformFee;

        payable(currentOwner).transfer(sellerShare);
        payable(platformTreasury).transfer(platformFee);

        contentNFTToOwner[_contentId] = msg.sender; // Update NFT ownership to purchaser
        emit ContentNFTPurchased(_contentId, msg.sender);
    }

    function transferContentNFT(uint256 _contentId, address _recipient) external contentExists(_contentId) isContentNFTOwner(_contentId) platformNotPaused {
        require(_recipient != address(0) && _recipient != msg.sender, "Invalid recipient address");
        contentNFTToOwner[_contentId] = _recipient;
        emit ContentNFTTransferred(_contentId, msg.sender, _recipient);
    }

    function getContentNFTOwner(uint256 _contentId) external view contentExists(_contentId) returns (address) {
        return contentNFTToOwner[_contentId];
    }


    // ** 6. Decentralized Moderation & Reputation (Advanced) **

    function stakeForModeration(uint256 _stakeAmount) external userProfileExists(msg.sender) platformNotPaused {
        require(_stakeAmount > 0, "Stake amount must be positive");
        require(governanceToken.transferFrom(msg.sender, address(this), _stakeAmount), "Governance token transfer failed"); // Transfer governance tokens to contract
        moderators[msg.sender] = Moderator({
            stakeAmount: _stakeAmount,
            lastActiveTime: block.timestamp
        });
        emit ModeratorStaked(msg.sender, _stakeAmount);
    }

    function unstakeFromModeration() external isModerator(msg.sender) platformNotPaused {
        uint256 stakedAmount = moderators[msg.sender].stakeAmount;
        delete moderators[msg.sender]; // Remove moderator status
        require(governanceToken.transfer(msg.sender, stakedAmount), "Governance token transfer back failed"); // Return staked tokens
        emit ModeratorUnstaked(msg.sender, stakedAmount);
    }

    function submitModerationVote(uint256 _reportId, bool _isHarmful) external isModerator(msg.sender) reportExists(_reportId) reportNotResolved(_reportId) moderatorHasNotVoted(_reportId, msg.sender) platformNotPaused {
        moderationReports[_reportId].moderatorsVoted[msg.sender] = true; // Mark moderator as voted
        moderators[msg.sender].lastActiveTime = block.timestamp; // Update moderator activity

        if (_isHarmful) {
            moderationReports[_reportId].positiveVotes++;
        } else {
            moderationReports[_reportId].negativeVotes++;
        }

        uint256 totalModerators = 0; // In a real system, you might track active moderators more efficiently
        for (uint256 i = 0; i < EnumerableSet.length(userProfiles[msg.sender].following); i++) { // Dummy, replace with actual active moderator count
            totalModerators++;
        }

        // Simple majority voting logic (can be adjusted)
        if (moderationReports[_reportId].positiveVotes > totalModerators / 2) {
            moderationReports[_reportId].isHarmful = true;
            _resolveModerationReport(_reportId); // Resolve report as harmful
        } else if (moderationReports[_reportId].negativeVotes > totalModerators / 2) {
            moderationReports[_reportId].isHarmful = false;
            _resolveModerationReport(_reportId); // Resolve report as not harmful
        }
        emit ModerationVoteSubmitted(_reportId, msg.sender, _isHarmful);
    }

    function _resolveModerationReport(uint256 _reportId) private {
        require(!moderationReports[_reportId].resolved, "Report already resolved");
        moderationReports[_reportId].resolved = true;

        if (moderationReports[_reportId].isHarmful) {
            // Implement actions for harmful content (e.g., content removal, creator penalty - governance controlled)
            // For example, contentRegistry[_reportId].contentURI = "Content Removed due to community moderation"; // Mark content as removed
            emit ModeratorsRewarded(_reportId); // In this example, we reward all moderators regardless of vote outcome for simplicity in demonstration.
        } else {
            emit ModeratorsPenalized(_reportId); // Similarly, penalize even if "not harmful" for demonstration - refine logic for real use
        }
    }

    function rewardModerators(uint256 _reportId) external onlyGovernanceTokenHolders reportExists(_reportId) reportNotResolved(_reportId) {
        _resolveModerationReport(_reportId); // Ensure report is resolved before rewarding
        emit ModeratorsRewarded(_reportId);
        // Distribute rewards to moderators who voted (logic can be refined based on vote accuracy, etc.)
        // Example: For each moderator who voted, transfer a small amount of governance tokens.
    }

    function penalizeModerators(uint256 _reportId) external onlyGovernanceTokenHolders reportExists(_reportId) reportNotResolved(_reportId) {
        _resolveModerationReport(_reportId); // Ensure report is resolved before penalizing
        emit ModeratorsPenalized(_reportId);
        // Implement penalty logic for moderators (e.g., reduce stake, temporary ban from moderation)
        // Example: For moderators who voted incorrectly (based on majority consensus), reduce stake by a small amount.
    }

    function getModeratorStake(address _moderatorAddress) external view isModerator(_moderatorAddress) returns (uint256) {
        return moderators[_moderatorAddress].stakeAmount;
    }

    function getModerationReportStatus(uint256 _reportId) external view reportExists(_reportId) returns (ModerationReport memory) {
        return moderationReports[_reportId];
    }


    // ** 7. Platform Revenue & Withdrawal **

    function withdrawPlatformFees(address _recipient) external onlyPlatformOwner platformNotPaused {
        require(_recipient != address(0), "Recipient address cannot be zero");
        uint256 balance = address(this).balance;
        payable(_recipient).transfer(balance);
        emit PlatformFeesWithdrawn(_recipient, balance);
    }

    // ** Fallback function to receive Ether **
    receive() external payable {}
}
```