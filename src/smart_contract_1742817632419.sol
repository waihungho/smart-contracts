```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Content Curation & Monetization Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where users can create, curate, and monetize content.
 *      It incorporates advanced concepts like dynamic content weighting based on curation, tiered subscription models,
 *      and on-chain governance for platform parameters. This contract aims to be a unique and comprehensive
 *      solution for content creators and consumers in a decentralized environment.
 *
 * **Outline and Function Summary:**
 *
 * **1. Content Creation & Management:**
 *    - `createPost(string contentHash, string metadataURI)`: Allows users to create new content posts.
 *    - `editPost(uint256 postId, string newContentHash, string newMetadataURI)`: Allows authors to edit their existing posts.
 *    - `deletePost(uint256 postId)`: Allows authors to delete their posts.
 *    - `getContent(uint256 postId)`: Retrieves content details for a given post ID.
 *    - `getAllPosts()`: Returns a list of all active post IDs.
 *
 * **2. Curation & Reputation System:**
 *    - `upvotePost(uint256 postId)`: Allows users to upvote a post, increasing its curation score.
 *    - `downvotePost(uint256 postId)`: Allows users to downvote a post, decreasing its curation score.
 *    - `reportPost(uint256 postId, string reason)`: Allows users to report a post for moderation.
 *    - `getCurationScore(uint256 postId)`: Retrieves the current curation score of a post.
 *    - `getUserReputation(address user)`: Retrieves the reputation score of a user based on their curation activities.
 *    - `updateUserReputation(address user, int256 reputationChange)`: Internal function to adjust user reputation.
 *
 * **3. Monetization & Subscription Tiers:**
 *    - `subscribeToAuthor(address author, uint8 tier)`: Allows users to subscribe to an author at a specific subscription tier.
 *    - `unsubscribeFromAuthor(address author)`: Allows users to unsubscribe from an author.
 *    - `getSubscriptionTier(address subscriber, address author)`: Retrieves the subscription tier of a user for a specific author.
 *    - `getAuthorSubscribers(address author)`: Retrieves a list of subscribers for a given author.
 *    - `donateToAuthor(address author)`: Allows users to make a direct donation to an author.
 *    - `withdrawEarnings()`: Allows authors to withdraw their accumulated donations and subscription revenue.
 *
 * **4. Platform Governance & Parameters:**
 *    - `proposePlatformParameterChange(string parameterName, uint256 newValue)`: Allows users to propose changes to platform parameters (governance).
 *    - `voteOnParameterChange(uint256 proposalId, bool vote)`: Allows users to vote on platform parameter change proposals.
 *    - `executeParameterChange(uint256 proposalId)`: Executes a parameter change proposal if it passes governance threshold (admin/governance managed).
 *    - `getPlatformParameter(string parameterName)`: Retrieves the current value of a platform parameter.
 *    - `setPlatformFee(uint256 newFee)`: Admin function to set the platform fee percentage.
 *    - `setSubscriptionTiers(uint8 numTiers, uint256[] memory tierPrices)`: Admin function to define subscription tiers and their prices.
 *    - `setGovernanceThreshold(uint256 newThreshold)`: Admin function to set the governance voting threshold.
 *
 * **5. Admin & Moderation:**
 *    - `setModerator(address moderator, bool isModerator)`: Admin function to assign or remove moderator roles.
 *    - `isModerator(address user)`: Checks if an address is a moderator.
 *    - `moderatePost(uint256 postId, bool isApproved)`: Moderator function to approve or disapprove reported posts.
 *
 * **Events:**
 *    - `PostCreated(uint256 postId, address author, string contentHash)`
 *    - `PostEdited(uint256 postId, string newContentHash)`
 *    - `PostDeleted(uint256 postId)`
 *    - `PostUpvoted(uint256 postId, address voter)`
 *    - `PostDownvoted(uint256 postId, address voter)`
 *    - `PostReported(uint256 postId, address reporter, string reason)`
 *    - `SubscriptionStarted(address subscriber, address author, uint8 tier)`
 *    - `SubscriptionCancelled(address subscriber, address author)`
 *    - `DonationReceived(address author, address donor, uint256 amount)`
 *    - `EarningsWithdrawn(address author, uint256 amount)`
 *    - `ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue)`
 *    - `ParameterVoteCast(uint256 proposalId, address voter, bool vote)`
 *    - `ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue)`
 *    - `ModeratorSet(address moderator, bool isModerator)`
 *    - `PostModerated(uint256 postId, bool isApproved, address moderator)`
 */
contract DecentralizedContentPlatform {
    // --- Structs and Enums ---
    struct Post {
        address author;
        string contentHash; // IPFS hash or similar content identifier
        string metadataURI; // URI for metadata (title, description, etc.)
        uint256 creationTimestamp;
        int256 curationScore;
        bool isApproved; // For moderation
    }

    struct UserProfile {
        uint256 reputationScore;
    }

    struct Subscription {
        uint8 tier;
        uint256 startTime;
    }

    struct ParameterProposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    enum PlatformParameters {
        PLATFORM_FEE,
        GOVERNANCE_THRESHOLD // Example of a parameter managed by governance
    }

    // --- State Variables ---
    mapping(uint256 => Post) public posts;
    uint256 public postCounter;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(address => Subscription)) public authorSubscriptions; // subscriber => author => subscription details
    mapping(address => uint256) public authorEarnings; // author => accumulated earnings

    mapping(uint256 => ParameterProposal) public parameterProposals;
    uint256 public proposalCounter;
    mapping(PlatformParameters => uint256) public platformParameterValues;

    mapping(address => bool) public moderators;
    address public admin;

    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256[] public subscriptionTierPrices; // Array to store prices for different tiers
    uint8 public numberOfSubscriptionTiers = 3; // Default 3 subscription tiers

    uint256 public governanceVotingThreshold = 50; // Default 50% threshold for governance proposals

    // --- Events ---
    event PostCreated(uint256 postId, address author, string contentHash);
    event PostEdited(uint256 postId, string newContentHash);
    event PostDeleted(uint256 postId);
    event PostUpvoted(uint256 postId, address voter);
    event PostDownvoted(uint256 postId, address voter);
    event PostReported(uint256 postId, address reporter, string reason);
    event SubscriptionStarted(address subscriber, address author, uint8 tier);
    event SubscriptionCancelled(address subscriber, address author);
    event DonationReceived(address author, address donor, uint256 amount);
    event EarningsWithdrawn(address author, uint256 amount);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterVoteCast(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ModeratorSet(address moderator, bool isModerator);
    event PostModerated(uint256 postId, bool isApproved, address moderator);

    // --- Modifiers ---
    modifier onlyAuthor(uint256 postId) {
        require(posts[postId].author == msg.sender, "You are not the author of this post.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || msg.sender == admin, "You are not a moderator or admin.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        moderators[admin] = true; // Admin is also a moderator by default
        subscriptionTierPrices = [1 ether, 5 ether, 10 ether]; // Example default tier prices
        platformParameterValues[PlatformParameters.PLATFORM_FEE] = platformFeePercentage;
        platformParameterValues[PlatformParameters.GOVERNANCE_THRESHOLD] = governanceVotingThreshold;
    }

    // --- 1. Content Creation & Management ---
    function createPost(string memory _contentHash, string memory _metadataURI) public {
        postCounter++;
        posts[postCounter] = Post({
            author: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            creationTimestamp: block.timestamp,
            curationScore: 0,
            isApproved: true // Initially approved, can be moderated later
        });
        emit PostCreated(postCounter, msg.sender, _contentHash);
    }

    function editPost(uint256 _postId, string memory _newContentHash, string memory _newMetadataURI) public onlyAuthor(_postId) {
        posts[_postId].contentHash = _newContentHash;
        posts[_postId].metadataURI = _newMetadataURI;
        emit PostEdited(_postId, _newContentHash);
    }

    function deletePost(uint256 _postId) public onlyAuthor(_postId) {
        delete posts[_postId];
        emit PostDeleted(_postId);
    }

    function getContent(uint256 _postId) public view returns (Post memory) {
        require(posts[_postId].author != address(0), "Post does not exist.");
        return posts[_postId];
    }

    function getAllPosts() public view returns (uint256[] memory) {
        uint256[] memory activePostIds = new uint256[](postCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= postCounter; i++) {
            if (posts[i].author != address(0)) {
                activePostIds[count] = i;
                count++;
            }
        }
        // Resize the array to remove extra empty slots if posts were deleted
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = activePostIds[i];
        }
        return result;
    }


    // --- 2. Curation & Reputation System ---
    function upvotePost(uint256 _postId) public {
        require(posts[_postId].author != address(0), "Post does not exist.");
        posts[_postId].curationScore++;
        updateUserReputation(posts[_postId].author, 1); // Reward author for upvote
        updateUserReputation(msg.sender, 1); // Reward voter for curation
        emit PostUpvoted(_postId, msg.sender);
    }

    function downvotePost(uint256 _postId) public {
        require(posts[_postId].author != address(0), "Post does not exist.");
        posts[_postId].curationScore--;
        updateUserReputation(posts[_postId].author, -1); // Penalize author for downvote
        updateUserReputation(msg.sender, 1); // Reward voter for curation (even downvotes provide feedback) - could be adjusted
        emit PostDownvoted(_postId, msg.sender);
    }

    function reportPost(uint256 _postId, string memory _reason) public {
        require(posts[_postId].author != address(0), "Post does not exist.");
        // In a real system, reporting might trigger moderation queues or more complex logic.
        // For now, just emit an event and maybe flag internally.
        emit PostReported(_postId, msg.sender, _reason);
        posts[_postId].isApproved = false; // Example: Set to unapproved upon report - moderator review needed
    }

    function getCurationScore(uint256 _postId) public view returns (int256) {
        return posts[_postId].curationScore;
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    function updateUserReputation(address _user, int256 _reputationChange) private {
        userProfiles[_user].reputationScore = uint256(int256(userProfiles[_user].reputationScore) + _reputationChange);
    }


    // --- 3. Monetization & Subscription Tiers ---
    function subscribeToAuthor(address _author, uint8 _tier) public payable {
        require(_tier > 0 && _tier <= numberOfSubscriptionTiers, "Invalid subscription tier.");
        require(subscriptionTierPrices[_tier - 1] > 0, "Subscription tier price not set.");
        require(msg.value >= subscriptionTierPrices[_tier - 1], "Insufficient payment for subscription tier.");

        // Refund extra payment if any (optional, but good practice)
        if (msg.value > subscriptionTierPrices[_tier - 1]) {
            payable(msg.sender).transfer(msg.value - subscriptionTierPrices[_tier - 1]);
        }

        authorSubscriptions[msg.sender][_author] = Subscription({
            tier: _tier,
            startTime: block.timestamp
        });

        // Transfer funds to author (after platform fee deduction)
        uint256 platformFee = (subscriptionTierPrices[_tier - 1] * platformFeePercentage) / 100;
        uint256 authorShare = subscriptionTierPrices[_tier - 1] - platformFee;

        authorEarnings[_author] += authorShare;
        // Platform fee could be handled separately or accumulated in admin account. For simplicity, not implemented here.

        emit SubscriptionStarted(msg.sender, _author, _tier);
    }

    function unsubscribeFromAuthor(address _author) public {
        delete authorSubscriptions[msg.sender][_author];
        emit SubscriptionCancelled(msg.sender, _author);
    }

    function getSubscriptionTier(address _subscriber, address _author) public view returns (uint8) {
        return authorSubscriptions[_subscriber][_author].tier;
    }

    function getAuthorSubscribers(address _author) public view returns (address[] memory) {
        address[] memory subscribers = new address[](100); // Assuming max 100 subscribers for simplicity - in real use, use dynamic array or pagination
        uint256 count = 0;
        for (uint256 i = 0; i < subscribers.length; i++) { // Iterating up to a fixed size for simplicity. In reality, need to manage subscriber list more dynamically.
            address subscriberAddress = address(uint160(uint256(keccak256(abi.encodePacked(_author, i))))); // Simple way to iterate potential subscriber addresses - not scalable for large numbers, needs improvement in real scenario.
            if (authorSubscriptions[subscriberAddress][_author].tier > 0) {
                subscribers[count] = subscriberAddress;
                count++;
            }
            if (count >= subscribers.length) {
                break; // Simple break for demonstration, in real app, handle dynamically or paginate.
            }
        }
        // Resize the array to remove extra empty slots if fewer than 100 subscribers
        address[] memory result = new address[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = subscribers[i];
        }
        return result;
    }


    function donateToAuthor(address _author) public payable {
        require(_author != address(0), "Invalid author address.");
        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 authorShare = msg.value - platformFee;

        authorEarnings[_author] += authorShare;
        // Platform fee handling can be improved for a real application

        emit DonationReceived(_author, msg.sender, msg.value);
    }

    function withdrawEarnings() public {
        uint256 amountToWithdraw = authorEarnings[msg.sender];
        require(amountToWithdraw > 0, "No earnings to withdraw.");
        authorEarnings[msg.sender] = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        emit EarningsWithdrawn(msg.sender, amountToWithdraw);
    }


    // --- 4. Platform Governance & Parameters ---
    function proposePlatformParameterChange(string memory _parameterName, uint256 _newValue) public {
        proposalCounter++;
        parameterProposals[proposalCounter] = ParameterProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit ParameterChangeProposed(proposalCounter, _parameterName, _newValue);
    }

    function voteOnParameterChange(uint256 _proposalId, bool _vote) public {
        require(parameterProposals[_proposalId].isActive, "Proposal is not active.");
        // In a real governance system, you'd track who voted to prevent double voting.
        if (_vote) {
            parameterProposals[_proposalId].votesFor++;
        } else {
            parameterProposals[_proposalId].votesAgainst++;
        }
        emit ParameterVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeParameterChange(uint256 _proposalId) public onlyAdmin { // Admin or governance can execute based on threshold
        require(parameterProposals[_proposalId].isActive, "Proposal is not active.");
        uint256 totalVotes = parameterProposals[_proposalId].votesFor + parameterProposals[_proposalId].votesAgainst;
        uint256 percentageFor = (parameterProposals[_proposalId].votesFor * 100) / totalVotes; // Avoid division by zero if no votes (handle edge case in real app)

        if (percentageFor >= platformParameterValues[PlatformParameters.GOVERNANCE_THRESHOLD]) {
            string memory parameterName = parameterProposals[_proposalId].parameterName;
            uint256 newValue = parameterProposals[_proposalId].newValue;

            if (keccak256(bytes(parameterName)) == keccak256(bytes("PLATFORM_FEE"))) {
                platformFeePercentage = newValue;
                platformParameterValues[PlatformParameters.PLATFORM_FEE] = newValue;
            } else if (keccak256(bytes(parameterName)) == keccak256(bytes("GOVERNANCE_THRESHOLD"))) {
                governanceVotingThreshold = newValue;
                platformParameterValues[PlatformParameters.GOVERNANCE_THRESHOLD] = newValue;
            } else {
                revert("Unknown parameter to change."); // Or handle more gracefully
            }

            parameterProposals[_proposalId].isActive = false; // Mark proposal as executed
            emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
        } else {
            revert("Governance threshold not reached.");
        }
    }

    function getPlatformParameter(string memory _parameterName) public view returns (uint256) {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("PLATFORM_FEE"))) {
            return platformParameterValues[PlatformParameters.PLATFORM_FEE];
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("GOVERNANCE_THRESHOLD"))) {
            return platformParameterValues[PlatformParameters.GOVERNANCE_THRESHOLD];
        } else {
            revert("Unknown parameter name.");
        }
    }

    function setPlatformFee(uint256 _newFee) public onlyAdmin {
        require(_newFee <= 100, "Platform fee cannot exceed 100%.");
        platformFeePercentage = _newFee;
        platformParameterValues[PlatformParameters.PLATFORM_FEE] = _newFee;
    }

    function setSubscriptionTiers(uint8 _numTiers, uint256[] memory _tierPrices) public onlyAdmin {
        require(_numTiers == _tierPrices.length, "Number of tiers must match the number of prices provided.");
        numberOfSubscriptionTiers = _numTiers;
        subscriptionTierPrices = _tierPrices;
    }

    function setGovernanceThreshold(uint256 _newThreshold) public onlyAdmin {
        require(_newThreshold <= 100, "Governance threshold cannot exceed 100%.");
        governanceVotingThreshold = _newThreshold;
        platformParameterValues[PlatformParameters.GOVERNANCE_THRESHOLD] = _newThreshold;
    }


    // --- 5. Admin & Moderation ---
    function setModerator(address _moderator, bool _isModerator) public onlyAdmin {
        moderators[_moderator] = _isModerator;
        emit ModeratorSet(_moderator, _isModerator);
    }

    function isModerator(address _user) public view returns (bool) {
        return moderators[_user];
    }

    function moderatePost(uint256 _postId, bool _isApproved) public onlyModerator {
        require(posts[_postId].author != address(0), "Post does not exist.");
        posts[_postId].isApproved = _isApproved;
        emit PostModerated(_postId, _isApproved, msg.sender);
    }
}
```