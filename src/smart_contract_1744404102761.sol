```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Content Platform (DACP) Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev A sophisticated smart contract for a decentralized content platform with advanced features.
 *
 * Outline and Function Summary:
 *
 * 1.  **Initialization and Platform Settings:**
 *     - `constructor(string _platformName, address _admin)`: Initializes the platform with a name and admin address.
 *     - `setPlatformFee(uint256 _feePercentage)`: Allows the admin to set the platform fee percentage.
 *     - `setSupportedContentTypes(string[] memory _contentTypes)`: Allows the admin to set supported content types.
 *     - `pausePlatform()`: Allows the admin to pause core functionalities of the platform.
 *     - `unpausePlatform()`: Allows the admin to unpause the platform.
 *
 * 2.  **User and Profile Management:**
 *     - `registerUser(string memory _username, string memory _profileHash)`: Registers a new user on the platform.
 *     - `updateUserProfile(string memory _newProfileHash)`: Allows a user to update their profile information.
 *     - `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 *     - `followUser(address _targetUser)`: Allows a user to follow another user.
 *     - `unfollowUser(address _targetUser)`: Allows a user to unfollow another user.
 *     - `getFollowerCount(address _userAddress)`: Gets the number of followers for a user.
 *     - `getFollowingCount(address _userAddress)`: Gets the number of users a user is following.
 *
 * 3.  **Content Creation and Management:**
 *     - `createContent(string memory _contentHash, string memory _contentType, string[] memory _tags)`: Allows a registered user to create and publish content.
 *     - `updateContentTags(uint256 _contentId, string[] memory _newTags)`: Allows the content creator to update tags of their content.
 *     - `getContentMetadata(uint256 _contentId)`: Retrieves metadata for a specific content item.
 *     - `reportContent(uint256 _contentId, string memory _reportReason)`: Allows users to report content for moderation.
 *     - `moderateContent(uint256 _contentId, bool _isApproved)`: Admin function to moderate reported content (approve or remove).
 *
 * 4.  **Content Monetization and Reward System:**
 *     - `tipContentCreator(uint256 _contentId)`: Allows users to tip content creators with ETH.
 *     - `subscribeToCreator(address _creatorAddress, uint256 _subscriptionTier)`: Allows users to subscribe to a creator for exclusive content access (tiers can be defined off-chain).
 *     - `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to premium content (pay-per-view).
 *     - `withdrawCreatorEarnings()`: Allows content creators to withdraw their accumulated platform earnings.
 *
 * 5.  **Advanced Features and Community Interaction:**
 *     - `createPoll(string memory _question, string[] memory _options, uint256 _durationInBlocks)`: Allows creators to create polls for their followers.
 *     - `voteInPoll(uint256 _pollId, uint256 _optionIndex)`: Allows users to vote in active polls.
 *     - `getPollResults(uint256 _pollId)`: Retrieves the results of a poll after it has ended.
 *     - `createChallenge(string memory _challengeDescription, uint256 _submissionDeadline)`: Allows creators to create content creation challenges.
 *     - `submitChallengeEntry(uint256 _challengeId, string memory _entryHash)`: Allows users to submit entries for active challenges.
 *     - `rewardChallengeWinner(uint256 _challengeId, address _winner, uint256 _rewardAmount)`: Creator or admin function to reward the winner of a challenge.
 *
 * 6.  **Platform Governance (Basic Example - Can be extended):**
 *     - `proposePlatformChange(string memory _proposalDescription)`: Allows users (or token holders in a more advanced version) to propose platform changes.
 *     - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on platform change proposals.
 *     - `executeProposal(uint256 _proposalId)`: Admin function to execute approved platform change proposals.
 */
contract DecentralizedAutonomousContentPlatform {

    // --- State Variables ---

    string public platformName;
    address public admin;
    uint256 public platformFeePercentage; // Fee percentage for platform operations (e.g., subscriptions, purchases)
    string[] public supportedContentTypes;
    bool public platformPaused;

    struct UserProfile {
        string username;
        string profileHash; // IPFS hash or similar for profile data
        uint256 registrationTimestamp;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => bool) public isUserRegistered;
    mapping(address => mapping(address => bool)) public following; // user -> targetUser -> isFollowing
    mapping(address => uint256) public followerCounts;
    mapping(address => uint256) public followingCounts;

    struct ContentItem {
        address creator;
        string contentHash; // IPFS hash or similar for content data
        string contentType;
        string[] tags;
        uint256 creationTimestamp;
        uint256 tipAmount;
        bool isModerated;
        bool isApproved; // After moderation
        string reportReason; // Last reported reason
    }
    ContentItem[] public contentItems;
    uint256 public nextContentId = 1;
    mapping(uint256 => address[]) public contentReports; // contentId -> reporters addresses

    struct Subscription {
        address subscriber;
        address creator;
        uint256 tier; // Subscription tier level
        uint256 startTime;
        uint256 endTime; // Based on subscription duration (can be extended)
    }
    Subscription[] public subscriptions;
    uint256 public nextSubscriptionId = 1;
    mapping(address => mapping(address => uint256)) public activeSubscriptions; // subscriber -> creator -> subscriptionId

    struct Poll {
        address creator;
        string question;
        string[] options;
        uint256 endTime; // Block number when poll ends
        mapping(address => uint256) public votes; // voter -> option index
        uint256[] voteCounts; // Count for each option
        bool isActive;
    }
    Poll[] public polls;
    uint256 public nextPollId = 1;

    struct Challenge {
        address creator;
        string description;
        uint256 submissionDeadline; // Block number for submission deadline
        string winnerEntryHash;
        address winner;
        uint256 rewardAmount;
        bool isActive;
    }
    Challenge[] public challenges;
    uint256 public nextChallengeId = 1;
    mapping(uint256 => string[]) public challengeEntries; // challengeId -> entryHashes

    struct PlatformChangeProposal {
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime; // Voting duration
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
    }
    PlatformChangeProposal[] public platformChangeProposals;
    uint256 public nextProposalId = 1;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId -> voter -> support (true for yes)


    // --- Events ---

    event PlatformInitialized(string platformName, address admin);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event SupportedContentTypesUpdated(string[] contentTypes);
    event PlatformPaused();
    event PlatformUnpaused();

    event UserRegistered(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newProfileHash);
    event UserFollowed(address follower, address targetUser);
    event UserUnfollowed(address follower, address targetUser);

    event ContentCreated(uint256 contentId, address creator, string contentType, string contentHash);
    event ContentTagsUpdated(uint256 contentId, string[] newTags);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, bool isApproved, address moderator);

    event TipReceived(uint256 contentId, address tipper, uint256 amount);
    event SubscriptionCreated(uint256 subscriptionId, address subscriber, address creator, uint256 tier);
    event ContentPurchased(uint256 contentId, address purchaser);
    event EarningsWithdrawn(address creator, uint256 amount);

    event PollCreated(uint256 pollId, address creator, string question);
    event VoteCast(uint256 pollId, address voter, uint256 optionIndex);
    event PollEnded(uint256 pollId);

    event ChallengeCreated(uint256 challengeId, address creator, string description);
    event ChallengeEntrySubmitted(uint256 challengeId, address submitter, string entryHash);
    event ChallengeWinnerRewarded(uint256 challengeId, address winner, uint256 rewardAmount);

    event PlatformChangeProposed(uint256 proposalId, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isUserRegistered[msg.sender], "User not registered");
        _;
    }

    modifier platformNotPaused() {
        require(!platformPaused, "Platform is currently paused");
        _;
    }

    modifier validContentType(string memory _contentType) {
        bool supported = false;
        for (uint256 i = 0; i < supportedContentTypes.length; i++) {
            if (keccak256(bytes(supportedContentTypes[i])) == keccak256(bytes(_contentType))) {
                supported = true;
                break;
            }
        }
        require(supported, "Unsupported content type");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(_contentId > 0 && _contentId < nextContentId, "Content does not exist");
        _;
    }

    modifier pollExists(uint256 _pollId) {
        require(_pollId > 0 && _pollId < nextPollId, "Poll does not exist");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId < nextChallengeId, "Challenge does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Proposal does not exist");
        _;
    }

    modifier pollActive(uint256 _pollId) {
        require(polls[_pollId - 1].isActive, "Poll is not active");
        require(block.number <= polls[_pollId - 1].endTime, "Poll has ended");
        _;
    }

    modifier challengeActive(uint256 _challengeId) {
        require(challenges[_challengeId - 1].isActive, "Challenge is not active");
        require(block.number <= challenges[_challengeId - 1].submissionDeadline, "Challenge submission deadline passed");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!platformChangeProposals[_proposalId - 1].isExecuted, "Proposal already executed");
        _;
    }


    // --- 1. Initialization and Platform Settings ---

    constructor(string memory _platformName, address _admin) {
        platformName = _platformName;
        admin = _admin;
        platformFeePercentage = 5; // Default 5% platform fee
        supportedContentTypes = ["text", "image", "video", "audio"]; // Default supported types
        platformPaused = false;
        emit PlatformInitialized(_platformName, _admin);
    }

    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    function setSupportedContentTypes(string[] memory _contentTypes) external onlyOwner {
        supportedContentTypes = _contentTypes;
        emit SupportedContentTypesUpdated(_contentTypes);
    }

    function pausePlatform() external onlyOwner {
        platformPaused = true;
        emit PlatformPaused();
    }

    function unpausePlatform() external onlyOwner {
        platformPaused = false;
        emit PlatformUnpaused();
    }


    // --- 2. User and Profile Management ---

    function registerUser(string memory _username, string memory _profileHash) external platformNotPaused {
        require(!isUserRegistered[msg.sender], "User already registered");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters");
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            registrationTimestamp: block.timestamp
        });
        isUserRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender, _username);
    }

    function updateUserProfile(string memory _newProfileHash) external onlyRegisteredUser platformNotPaused {
        require(bytes(_newProfileHash).length > 0, "Profile hash cannot be empty");
        userProfiles[msg.sender].profileHash = _newProfileHash;
        emit UserProfileUpdated(msg.sender, _newProfileHash);
    }

    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        require(isUserRegistered[_userAddress], "User not registered");
        return userProfiles[_userAddress];
    }

    function followUser(address _targetUser) external onlyRegisteredUser platformNotPaused {
        require(isUserRegistered[_targetUser], "Cannot follow unregistered user");
        require(msg.sender != _targetUser, "Cannot follow yourself");
        if (!following[msg.sender][_targetUser]) {
            following[msg.sender][_targetUser] = true;
            followerCounts[_targetUser]++;
            followingCounts[msg.sender]++;
            emit UserFollowed(msg.sender, _targetUser);
        }
    }

    function unfollowUser(address _targetUser) external onlyRegisteredUser platformNotPaused {
        require(isUserRegistered[_targetUser], "Cannot unfollow unregistered user");
        if (following[msg.sender][_targetUser]) {
            following[msg.sender][_targetUser] = false;
            followerCounts[_targetUser]--;
            followingCounts[msg.sender]--;
            emit UserUnfollowed(msg.sender, _targetUser);
        }
    }

    function getFollowerCount(address _userAddress) external view returns (uint256) {
        require(isUserRegistered[_userAddress], "User not registered");
        return followerCounts[_userAddress];
    }

    function getFollowingCount(address _userAddress) external view returns (uint256) {
        require(isUserRegistered[_userAddress], "User not registered");
        return followingCounts[_userAddress];
    }


    // --- 3. Content Creation and Management ---

    function createContent(string memory _contentHash, string memory _contentType, string[] memory _tags)
        external
        onlyRegisteredUser
        platformNotPaused
        validContentType(_contentType)
    {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(_tags.length <= 10, "Maximum 10 tags allowed per content");

        contentItems.push(ContentItem({
            creator: msg.sender,
            contentHash: _contentHash,
            contentType: _contentType,
            tags: _tags,
            creationTimestamp: block.timestamp,
            tipAmount: 0,
            isModerated: false,
            isApproved: true, // Initially approved, can be moderated later
            reportReason: ""
        }));
        emit ContentCreated(nextContentId, msg.sender, _contentType, _contentHash);
        nextContentId++;
    }

    function updateContentTags(uint256 _contentId, string[] memory _newTags)
        external
        onlyRegisteredUser
        contentExists(_contentId)
        platformNotPaused
    {
        require(contentItems[_contentId - 1].creator == msg.sender, "Only content creator can update tags");
        require(_newTags.length <= 10, "Maximum 10 tags allowed per content");
        contentItems[_contentId - 1].tags = _newTags;
        emit ContentTagsUpdated(_contentId, _newTags);
    }

    function getContentMetadata(uint256 _contentId) external view contentExists(_contentId) returns (ContentItem memory) {
        return contentItems[_contentId - 1];
    }

    function reportContent(uint256 _contentId, string memory _reportReason)
        external
        onlyRegisteredUser
        contentExists(_contentId)
        platformNotPaused
    {
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 256, "Report reason must be between 1 and 256 characters");
        bool alreadyReported = false;
        for (uint256 i = 0; i < contentReports[_contentId].length; i++) {
            if (contentReports[_contentId][i] == msg.sender) {
                alreadyReported = true;
                break;
            }
        }
        require(!alreadyReported, "Content already reported by you");

        contentReports[_contentId].push(msg.sender);
        contentItems[_contentId - 1].isModerated = true; // Mark as moderated (pending admin action)
        contentItems[_contentId - 1].reportReason = _reportReason;
        emit ContentReported(_contentId, msg.sender, _reportReason);
    }

    function moderateContent(uint256 _contentId, bool _isApproved)
        external
        onlyOwner
        contentExists(_contentId)
    {
        require(contentItems[_contentId - 1].isModerated, "Content not reported or already moderated");
        contentItems[_contentId - 1].isApproved = _isApproved;
        emit ContentModerated(_contentId, _isApproved, msg.sender);
    }


    // --- 4. Content Monetization and Reward System ---

    function tipContentCreator(uint256 _contentId)
        external
        payable
        onlyRegisteredUser
        contentExists(_contentId)
        platformNotPaused
    {
        require(contentItems[_contentId - 1].isApproved, "Content is not approved");
        require(msg.value > 0, "Tip amount must be greater than 0");

        address creator = contentItems[_contentId - 1].creator;
        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 creatorAmount = msg.value - platformFee;

        payable(creator).transfer(creatorAmount); // Transfer to creator
        payable(admin).transfer(platformFee);      // Transfer platform fee to admin

        contentItems[_contentId - 1].tipAmount += creatorAmount; // Track creator's earnings
        emit TipReceived(_contentId, msg.sender, msg.value);
    }

    function subscribeToCreator(address _creatorAddress, uint256 _subscriptionTier)
        external
        payable
        onlyRegisteredUser
        platformNotPaused
    {
        require(isUserRegistered[_creatorAddress], "Cannot subscribe to unregistered user");
        require(msg.sender != _creatorAddress, "Cannot subscribe to yourself");
        require(_subscriptionTier > 0 && _subscriptionTier <= 3, "Invalid subscription tier (must be 1, 2, or 3)"); // Example tiers

        uint256 subscriptionCost;
        if (_subscriptionTier == 1) subscriptionCost = 0.01 ether;
        else if (_subscriptionTier == 2) subscriptionCost = 0.05 ether;
        else if (_subscriptionTier == 3) subscriptionCost = 0.1 ether;
        else revert("Invalid subscription tier cost"); // Should not reach here due to previous require

        require(msg.value == subscriptionCost, "Incorrect subscription cost sent");

        // End previous subscription if exists
        if (activeSubscriptions[msg.sender][_creatorAddress] != 0) {
            subscriptions[activeSubscriptions[msg.sender][_creatorAddress] - 1].endTime = block.timestamp; // End current subscription
        }

        uint256 platformFee = (subscriptionCost * platformFeePercentage) / 100;
        uint256 creatorAmount = subscriptionCost - platformFee;

        payable(_creatorAddress).transfer(creatorAmount); // Transfer to creator
        payable(admin).transfer(platformFee);      // Transfer platform fee to admin

        subscriptions.push(Subscription({
            subscriber: msg.sender,
            creator: _creatorAddress,
            tier: _subscriptionTier,
            startTime: block.timestamp,
            endTime: block.timestamp + (30 days) // Example: 30 days subscription duration
        }));
        activeSubscriptions[msg.sender][_creatorAddress] = nextSubscriptionId;
        emit SubscriptionCreated(nextSubscriptionId, msg.sender, _creatorAddress, _subscriptionTier);
        nextSubscriptionId++;
    }

    function purchaseContentAccess(uint256 _contentId)
        external
        payable
        onlyRegisteredUser
        contentExists(_contentId)
        platformNotPaused
    {
        require(contentItems[_contentId - 1].isApproved, "Content is not approved");
        uint256 purchasePrice = 0.02 ether; // Example purchase price
        require(msg.value == purchasePrice, "Incorrect purchase price sent");

        address creator = contentItems[_contentId - 1].creator;
        uint256 platformFee = (purchasePrice * platformFeePercentage) / 100;
        uint256 creatorAmount = purchasePrice - platformFee;

        payable(creator).transfer(creatorAmount); // Transfer to creator
        payable(admin).transfer(platformFee);      // Transfer platform fee to admin

        emit ContentPurchased(_contentId, msg.sender);
    }

    function withdrawCreatorEarnings() external onlyRegisteredUser platformNotPaused {
        uint256 totalEarnings = 0;
        for (uint256 i = 0; i < contentItems.length; i++) {
            if (contentItems[i].creator == msg.sender) {
                totalEarnings += contentItems[i].tipAmount;
                contentItems[i].tipAmount = 0; // Reset tip amount after withdrawal (optional)
            }
        }
        require(totalEarnings > 0, "No earnings to withdraw");
        payable(msg.sender).transfer(totalEarnings);
        emit EarningsWithdrawn(msg.sender, totalEarnings);
    }


    // --- 5. Advanced Features and Community Interaction ---

    function createPoll(string memory _question, string[] memory _options, uint256 _durationInBlocks)
        external
        onlyRegisteredUser
        platformNotPaused
    {
        require(bytes(_question).length > 0 && bytes(_question).length <= 256, "Poll question must be between 1 and 256 characters");
        require(_options.length >= 2 && _options.length <= 5, "Poll must have between 2 and 5 options");
        require(_durationInBlocks > 0 && _durationInBlocks <= 10000, "Poll duration must be between 1 and 10000 blocks");

        polls.push(Poll({
            creator: msg.sender,
            question: _question,
            options: _options,
            endTime: block.number + _durationInBlocks,
            voteCounts: new uint256[](_options.length), // Initialize vote counts to 0
            isActive: true
        }));
        emit PollCreated(nextPollId, msg.sender, _question);
        nextPollId++;
    }

    function voteInPoll(uint256 _pollId, uint256 _optionIndex)
        external
        onlyRegisteredUser
        pollExists(_pollId)
        pollActive(_pollId)
    {
        require(_optionIndex < polls[_pollId - 1].options.length, "Invalid option index");
        require(polls[_pollId - 1].votes[msg.sender] == 0, "Already voted in this poll"); // 0 indicates no vote yet

        polls[_pollId - 1].votes[msg.sender] = _optionIndex + 1; // Store option index (1-based for easier checking of 'no vote')
        polls[_pollId - 1].voteCounts[_optionIndex]++;
        emit VoteCast(_pollId, msg.sender, _optionIndex);
    }

    function getPollResults(uint256 _pollId)
        external
        view
        pollExists(_pollId)
    returns (string[] memory options, uint256[] memory voteCounts, bool isActive)
    {
        Poll storage poll = polls[_pollId - 1];
        isActive = poll.isActive;
        options = poll.options;
        voteCounts = poll.voteCounts;

        if (poll.isActive && block.number > poll.endTime) {
            poll.isActive = false; // Mark poll as inactive once ended
            emit PollEnded(_pollId);
        }
        return (options, voteCounts, isActive);
    }

    function createChallenge(string memory _challengeDescription, uint256 _submissionDeadline)
        external
        onlyRegisteredUser
        platformNotPaused
    {
        require(bytes(_challengeDescription).length > 0 && bytes(_challengeDescription).length <= 512, "Challenge description must be between 1 and 512 characters");
        require(_submissionDeadline > block.number && _submissionDeadline <= block.number + 30 days / 12 seconds, "Submission deadline must be in the future and within 30 days"); // Example: 30 days in blocks

        challenges.push(Challenge({
            creator: msg.sender,
            description: _challengeDescription,
            submissionDeadline: _submissionDeadline,
            winnerEntryHash: "",
            winner: address(0),
            rewardAmount: 0,
            isActive: true
        }));
        emit ChallengeCreated(nextChallengeId, msg.sender, _challengeDescription);
        nextChallengeId++;
    }

    function submitChallengeEntry(uint256 _challengeId, string memory _entryHash)
        external
        onlyRegisteredUser
        challengeExists(_challengeId)
        challengeActive(_challengeId)
    {
        require(bytes(_entryHash).length > 0, "Entry hash cannot be empty");
        challengeEntries[_challengeId].push(_entryHash);
        emit ChallengeEntrySubmitted(_challengeId, msg.sender, _entryHash);
    }

    function rewardChallengeWinner(uint256 _challengeId, address _winner, uint256 _rewardAmount)
        external
        onlyRegisteredUser // Creator or Admin can reward in this example, adjust as needed
        challengeExists(_challengeId)
    {
        require(challenges[_challengeId - 1].creator == msg.sender || msg.sender == admin, "Only challenge creator or admin can reward winner");
        require(challenges[_challengeId - 1].isActive, "Challenge is not active anymore"); // Prevent rewarding after challenge end? Or allow after deadline?
        require(_winner != address(0), "Winner address cannot be zero address");
        require(_rewardAmount > 0, "Reward amount must be greater than 0");

        challenges[_challengeId - 1].winner = _winner;
        challenges[_challengeId - 1].winnerEntryHash = challengeEntries[_challengeId][0]; // Example: reward based on first entry submitted - adjust logic as needed
        challenges[_challengeId - 1].rewardAmount = _rewardAmount;
        challenges[_challengeId - 1].isActive = false; // Mark challenge as inactive after rewarding
        payable(_winner).transfer(_rewardAmount);
        emit ChallengeWinnerRewarded(_challengeId, _winner, _rewardAmount);
    }


    // --- 6. Platform Governance (Basic Example - Can be extended) ---

    function proposePlatformChange(string memory _proposalDescription)
        external
        onlyRegisteredUser
        platformNotPaused
    {
        require(bytes(_proposalDescription).length > 0 && bytes(_proposalDescription).length <= 512, "Proposal description must be between 1 and 512 characters");

        platformChangeProposals.push(PlatformChangeProposal({
            proposer: msg.sender,
            description: _proposalDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + (7 days) / 12 seconds, // Example: 7 days voting duration
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false
        }));
        emit PlatformChangeProposed(nextProposalId, msg.sender, _proposalDescription);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyRegisteredUser
        proposalExists(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        require(platformChangeProposals[_proposalId - 1].endTime > block.timestamp, "Voting period has ended");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true; // Mark as voted
        if (_support) {
            platformChangeProposals[_proposalId - 1].yesVotes++;
        } else {
            platformChangeProposals[_proposalId - 1].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId)
        external
        onlyOwner
        proposalExists(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        PlatformChangeProposal storage proposal = platformChangeProposals[_proposalId - 1];
        require(proposal.endTime <= block.timestamp, "Voting period has not ended");
        require(proposal.yesVotes > proposal.noVotes, "Proposal not approved (more No votes or equal)"); // Simple majority for execution

        proposal.isExecuted = true;
        // --- Implement proposal execution logic here based on proposal.description ---
        // This is a placeholder. Actual execution logic depends on what platform changes are allowed to be proposed.
        // Examples: Change platform fee, add/remove content types, update governance parameters, etc.
        // For now, just emit an event indicating execution.
        emit ProposalExecuted(_proposalId);
    }

    // --- Fallback function to receive ETH for tips, subscriptions, etc. ---
    receive() external payable {}
}
```