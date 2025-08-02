The following Solidity smart contract, `NexusFlow`, is designed as a decentralized content economy. It integrates several advanced, creative, and trendy concepts:

*   **Dynamic Royalty Distribution:** Creators and curators are rewarded based on content engagement (upvotes, tips, subscriptions), with distribution parameters configurable by DAO governance.
*   **AI-Assisted Content Filtering:** An off-chain AI oracle submits quality/safety scores for content, automatically influencing its visibility and flagging it for moderation.
*   **Soulbound-like Reputation System:** Users can earn non-transferable "achievement" tokens/roles for their contributions, enhancing their on-chain identity and potentially their voting power.
*   **DAO Governance:** A simplified yet functional DAO system allows the community to propose and vote on key platform parameters, moderator appointments, and even direct distribution of engagement rewards.
*   **Creator Monetization:** Direct subscriptions and tipping mechanisms provide creators with immediate income.

While Solidity cannot execute AI directly or iterate over unbounded data structures efficiently, this contract conceptualizes these integrations by defining the on-chain logic and interfaces for off-chain services (like an AI oracle) and governance mechanisms that would manage larger data sets.

---

**Outline:**

**Contract Name:** `NexusFlow`
**Description:** A decentralized content economy fostering creation, curation, and dynamic monetization. It features AI-assisted content insights, a reputation system using non-transferable achievements, and community-driven governance via a simplified DAO.

**Core Concepts:**
1.  **Content Hashing:** Only content hashes (e.g., IPFS CIDs) and metadata URIs are stored on-chain; actual content resides off-chain.
2.  **Dynamic Royalties:** Engagement-based royalties (upvotes, tips, subscriptions) are distributed from a shared pool, rewarding both creators and curators, with parameters configurable by the DAO. The distribution is initiated by the DAO based on off-chain calculations.
3.  **AI-Assisted Filtering (Oracle-based):** An authorized off-chain AI oracle provides scores for content. These scores influence content visibility (flagging or hiding) and moderation queues.
4.  **Reputation System (Soulbound-like):** Non-transferable "achievement" badges/roles are awarded to top contributors, curators, and active community members, enhancing on-chain identity and potentially voting power.
5.  **DAO Governance:** A proposal and voting system allows the community (specifically, "CommunityVoter" achievement holders) to evolve platform parameters, allocate rewards, and manage moderation.
6.  **Subscription Tiers & Tipping:** Direct and flexible monetization channels for creators from their audience.

---

**Function Categories and Summary (Total External/Public Functions: 33+):**

**1. Core Content Management (5 Functions):**
    *   `publishContent(bytes32 _contentHash, string calldata _metadataURI)`: Allows creators to publish new content by providing its hash and a URI to off-chain metadata.
    *   `updateContentMetadata(bytes32 _contentHash, string calldata _newMetadataURI)`: Enables a content creator to update the metadata URI for their existing content.
    *   `removeContentRequest(bytes32 _contentHash)`: Initiates a formal request from a creator to remove their content, signaling to moderators for review.
    *   `getContentDetails(bytes32 _contentHash)`: Retrieves all on-chain details (creator, votes, visibility, AI score, etc.) for a specified content hash.
    *   `getCreatorContentHashes(address _creator)`: Returns a list of all content hashes published by a particular creator.

**2. Engagement & Curation (6 Functions):**
    *   `upvoteContent(bytes32 _contentHash)`: Allows a user to upvote content, contributing to its engagement metrics. Prevents self-upvoting and double-voting.
    *   `downvoteContent(bytes32 _contentHash)`: Allows a user to downvote content. Prevents self-downvoting and double-voting.
    *   `tipCreator(bytes32 _contentHash) payable`: Sends a direct micropayment (tip) to the content creator, with a portion going to the platform fee pool.
    *   `reportContent(bytes32 _contentHash, string calldata _reason)`: Flags content for moderation review by providing a reason.
    *   `curateContent(bytes32 _contentHash)`: (Moderator-only) Marks content as "curated," potentially enhancing its visibility or discoverability on the platform.
    *   `addCommentHash(bytes32 _contentHash, bytes32 _commentHash)`: Records an off-chain comment's hash linked to a specific piece of content, for on-chain verifiable linkage.

**3. Monetization & Revenue Distribution (7 Functions):**
    *   `setSubscriptionTier(uint256 _pricePerMonth)`: Allows a creator to define a monthly subscription price (in wei) for access to their exclusive content.
    *   `subscribeToCreator(address _creator) payable`: Enables a user to subscribe to a creator's content tier for one month.
    *   `_collectPlatformFees(uint256 _amount)`: (Internal) A helper function to calculate and direct the platform's share from transactions into the `platformRevenuePool`.
    *   `distributeEngagementRewards(address[] calldata _creatorAddresses, uint256[] calldata _creatorAmounts, address[] calldata _curatorAddresses, uint256[] calldata _curatorAmounts)`: (DAO-only) Distributes a specified portion of the `platformRevenuePool` as rewards to a list of creators and curators, based on off-chain determined engagement.
    *   `claimCreatorRevenue()`: Allows a content creator to withdraw their accumulated tips and subscription revenues.
    *   `claimCuratorRewards()`: Allows a curator to withdraw their accumulated rewards earned through curation activities.
    *   `withdrawPlatformBalance(uint256 _amount)`: (DAO-only) Enables the DAO to withdraw funds from the main platform revenue pool.

**4. AI Oracle & Moderation (4 Functions):**
    *   `submitContentAIScore(bytes32 _contentHash, uint8 _score)`: (AI Oracle-only) Receives an AI-generated quality/safety score (0-100) for a content hash. Triggers auto-visibility adjustment.
    *   `setAIScoreOracleAddress(address _newOracleAddress)`: (DAO-only) Updates the authorized address that can submit AI scores.
    *   `toggleContentVisibilityByAI(bytes32 _contentHash, bool _visible)`: (Internal) Adjusts content visibility based on AI score thresholds, or manually by a moderator.
    *   `moderatorAction(bytes32 _contentHash, bool _approveRemoval, bool _setVisible)`: (Moderator-only) Allows a moderator to approve content removal requests or manually set content visibility.

**5. Reputation & Achievements (Soulbound-like) (3 Functions):**
    *   `awardAchievement(address _user, AchievementType _type)`: (DAO-only) Bestows a specific non-transferable achievement (e.g., Top Contributor, Community Voter) upon a user.
    *   `getUserAchievements(address _user)`: Retrieves the status of all possible achievements for a given user.
    *   `revokeAchievement(address _user, AchievementType _type)`: (DAO-only) Revokes a previously awarded achievement from a user (e.g., due to policy violation).

**6. DAO Governance & Configuration (7 Functions):**
    *   `proposeConfigurationChange(string calldata _description, address _target, bytes calldata _callData, uint256 _votingPeriod)`: (CommunityVoter-only) Creates a new governance proposal for changing contract parameters or executing arbitrary calls.
    *   `voteOnProposal(uint256 _proposalId, bool _support)`: (CommunityVoter-only) Allows users to cast their vote (yes/no) on an active proposal.
    *   `executeProposal(uint256 _proposalId)`: (DAO-only) Executes a proposal if its voting period has ended, and it has met the quorum and majority requirements.
    *   `updatePlatformFee(uint256 _newFeeBps)`: (DAO-only) Changes the platform's revenue share percentage (in basis points).
    *   `updateRoyaltyDistributionParameters(uint256 _creatorShareBps, uint256 _curatorShareBps, uint256 _engagementWeight, uint256 _tipWeight)`: (DAO-only) Adjusts the weighted parameters for calculating and distributing dynamic royalties to creators and curators.
    *   `updateModeratorAddress(address _moderator, bool _isModerator)`: (DAO-only) Adds or removes an address from the list of authorized moderators.
    *   `transferOwnership(address _newOwner)`: (Inherited from Ownable, owner-only) Transfers the administrative ownership of the contract, ideally to a DAO multisig or governance contract.
    *   `pause()`: (Inherited from Pausable, owner-only) Pauses most user interactions with the contract in emergencies.
    *   `unpause()`: (Inherited from Pausable, owner-only) Unpauses the contract after a pause.
    *   `receive()`: (Fallback function) Allows the contract to receive direct ETH transfers, adding them to the `platformRevenuePool`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For percentage calculations if needed, though uint suffices

// Outline:
// Contract Name: NexusFlow
// Description: A decentralized content economy fostering creation, curation, and dynamic monetization.
//              It features AI-assisted content insights, a reputation system using non-transferable achievements,
//              and community-driven governance via a simplified DAO.
//
// Core Concepts:
// 1. Content Hashing: Only content hashes and metadata URIs are stored on-chain, actual content is off-chain.
// 2. Dynamic Royalties: Engagement-based royalties (upvotes, tips, subscriptions) are distributed from a shared pool,
//    rewarding both creators and curators, with parameters configurable by DAO. The distribution is
//    initiated by the DAO based on off-chain determined engagement.
// 3. AI-Assisted Filtering (Oracle-based): An off-chain AI oracle provides scores for content quality/safety,
//    influencing content visibility and moderation queues.
// 4. Reputation System (Soulbound-like): Non-transferable "achievement" badges/roles are awarded to top contributors
//    and curators, enhancing on-chain identity and potentially voting power.
// 5. DAO Governance: A simplified proposal and voting system allows the community to evolve platform parameters
//    and manage moderation.
// 6. Subscription Tiers & Tipping: Direct monetization channels for creators.

// Function Categories and Summary:

// 1. Core Content Management (5 Functions):
//    - publishContent(bytes32 _contentHash, string calldata _metadataURI): Allows creators to publish new content.
//    - updateContentMetadata(bytes32 _contentHash, string calldata _newMetadataURI): Updates URI for existing content.
//    - removeContentRequest(bytes32 _contentHash): Initiates a request to remove content (requires moderation/DAO approval).
//    - getContentDetails(bytes32 _contentHash): Retrieves all on-chain details for a given content hash.
//    - getCreatorContentHashes(address _creator): Lists all content hashes published by a specific creator.

// 2. Engagement & Curation (6 Functions):
//    - upvoteContent(bytes32 _contentHash): Allows users to express positive sentiment, contributing to engagement metrics.
//    - downvoteContent(bytes32 _contentHash): Allows users to express negative sentiment.
//    - tipCreator(bytes32 _contentHash) payable: Directly sends a micropayment to a content creator.
//    - reportContent(bytes32 _contentHash, string calldata _reason): Flags content for moderation review.
//    - curateContent(bytes32 _contentHash): Marks content as "curated" (moderator/DAO only), enhancing visibility.
//    - addCommentHash(bytes32 _contentHash, bytes32 _commentHash): Stores a hash of an off-chain comment.

// 3. Monetization & Revenue Distribution (7 Functions):
//    - setSubscriptionTier(uint256 _pricePerMonth): Allows creators to set a monthly subscription price for their content.
//    - subscribeToCreator(address _creator) payable: Allows users to subscribe to a creator.
//    - _collectPlatformFees(uint256 _amount): Internal helper to collect platform's share from transactions.
//    - distributeEngagementRewards(address[] calldata _creatorAddresses, uint256[] calldata _creatorAmounts, address[] calldata _curatorAddresses, uint256[] calldata _curatorAmounts): (DAO-only) Distributes engagement-based rewards.
//    - claimCreatorRevenue(): Allows a creator to withdraw their accumulated earnings.
//    - claimCuratorRewards(): Allows a curator to withdraw their accumulated rewards for curation activities.
//    - withdrawPlatformBalance(uint256 _amount): Allows the DAO to withdraw funds from the platform's collected fees.

// 4. AI Oracle & Moderation (4 Functions):
//    - submitContentAIScore(bytes32 _contentHash, uint8 _score): Oracle submits an AI-generated score for content.
//    - setAIScoreOracleAddress(address _newOracleAddress): Sets the authorized address for submitting AI scores.
//    - toggleContentVisibilityByAI(bytes32 _contentHash, bool _visible): Automatically adjusts content visibility based on AI score (internal/triggered by oracle).
//    - moderatorAction(bytes32 _contentHash, bool _approveRemoval, bool _setVisible): Allows a moderator to act on reported content or manually set visibility.

// 5. Reputation & Achievements (Soulbound-like) (3 Functions):
//    - awardAchievement(address _user, AchievementType _type): Awards a specific non-transferable achievement to a user.
//    - getUserAchievements(address _user): Retrieves all achievements awarded to a user.
//    - revokeAchievement(address _user, AchievementType _type): Revokes an achievement (e.g., due to malicious activity).

// 6. DAO Governance & Configuration (7 Functions):
//    - proposeConfigurationChange(string calldata _description, address _target, bytes calldata _callData, uint256 _votingPeriod): Creates a new governance proposal.
//    - voteOnProposal(uint256 _proposalId, bool _support): Allows users to vote on an active proposal.
//    - executeProposal(uint256 _proposalId): Executes a proposal that has passed its voting period and quorum.
//    - updatePlatformFee(uint256 _newFeeBps): DAO function to change the platform's revenue share percentage.
//    - updateRoyaltyDistributionParameters(uint256 _creatorShareBps, uint256 _curatorShareBps, uint256 _engagementWeight, uint256 _tipWeight): DAO function to adjust royalty calculation.
//    - updateModeratorAddress(address _moderator, bool _isModerator): Adds or removes a moderator.
//    - transferOwnership(address _newOwner): Standard Ownable function to transfer contract ownership (initially to DAO multisig).
//    - pause(): (Inherited from Pausable, owner-only) Pauses most user interactions.
//    - unpause(): (Inherited from Pausable, owner-only) Unpauses the contract.
//    - receive(): (Fallback) Handles direct ETH transfers to the contract, adding them to the platform pool.

contract NexusFlow is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum AchievementType {
        TopContributor,
        TopCurator,
        EarlyAdopter,
        HighReputation,
        CommunityVoter // For DAO interaction
    }

    struct Content {
        address creator;
        bytes32 contentHash; // IPFS hash or similar (e.g., keccak256 of content)
        string metadataURI; // URI to additional metadata (title, description, tags, etc.)
        uint256 upvotes;
        uint256 downvotes;
        uint256 createdAt;
        bool isCurated; // Set by moderators/DAO
        bool isVisible; // Can be toggled by AI or moderation
        uint8 aiScore; // 0-100, set by oracle, 255 for "not scored"
        uint256 totalTips; // Sum of ETH tips received
        uint256 totalSubscriptionRevenue; // Sum of subscription fees earned
    }

    struct SubscriptionTier {
        uint256 pricePerMonth; // in wei
        uint256 totalSubscribers;
    }

    struct Proposal {
        uint256 id;
        string description;
        address targetContract; // Address of the contract to call (e.g., this contract for config changes)
        bytes callData; // Encoded function call to execute
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---

    mapping(bytes32 => Content) public contents;
    mapping(address => bytes32[]) public creatorContentHashes;
    mapping(address => mapping(bytes32 => bool)) public hasUpvoted;
    mapping(address => mapping(bytes32 => bool)) public hasDownvoted;
    mapping(address => SubscriptionTier) public creatorSubscriptionTiers;
    // subscriber -> creator -> expiryTimestamp (unix time)
    mapping(address => mapping(address => uint256)) public subscriptions;

    // Balances for creators and curators to claim
    mapping(address => uint256) public creatorBalances;
    mapping(address => uint256) public curatorBalances;

    // Reputation / Achievement System (Soulbound-like)
    mapping(address => mapping(AchievementType => bool)) public userAchievements;

    // DAO Governance
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public totalCommunityVoters; // Count of users with CommunityVoter achievement (simplistic voting power)

    // System parameters (DAO configurable)
    uint256 public platformFeeBps; // Platform's share in Basis Points (e.g., 500 = 5%)
    uint256 public minSubscriptionAmount; // Minimum subscription amount in wei
    uint256 public aiFlaggingThreshold; // Content flagged if AI score below this
    uint256 public aiHidingThreshold; // Content hidden if AI score below this
    uint256 public proposalQuorumBps; // Basis points for proposal quorum (e.g., 4000 = 40%)
    uint256 public proposalVotingPeriod; // Duration for proposals in seconds

    // Royalty distribution weights (DAO configurable, used off-chain to determine rewards)
    uint256 public creatorRoyaltyShareBps; // Conceptual: Share for creator from distributed pool
    uint256 public curatorRoyaltyShareBps; // Conceptual: Share for curator from distributed pool
    uint256 public engagementWeight; // Conceptual: Weight for upvotes in dynamic royalty calculation
    uint256 public tipWeight; // Conceptual: Weight for tips in dynamic royalty calculation

    // Addresses with special roles
    address public aiScoreOracleAddress;
    address public daoMultisigAddress; // Or the actual DAO contract address
    mapping(address => bool) public isModerator;

    // Funds collected by the platform (fees, direct ETH sends)
    uint256 public platformRevenuePool;

    // --- Events ---

    event ContentPublished(bytes32 indexed contentHash, address indexed creator, string metadataURI, uint256 createdAt);
    event ContentMetadataUpdated(bytes32 indexed contentHash, string newMetadataURI);
    event ContentRemoved(bytes32 indexed contentHash); // After moderation approval
    event ContentUpvoted(bytes32 indexed contentHash, address indexed voter);
    event ContentDownvoted(bytes32 indexed contentHash, address indexed voter);
    event CreatorTipped(bytes32 indexed contentHash, address indexed tipper, address indexed creator, uint256 amount);
    event ContentReported(bytes32 indexed contentHash, address indexed reporter, string reason);
    event ContentCurated(bytes32 indexed contentHash, address indexed curator);
    event CommentHashAdded(bytes32 indexed contentHash, bytes32 indexed commentHash, address indexed commenter);

    event SubscriptionTierSet(address indexed creator, uint256 pricePerMonth);
    event Subscribed(address indexed subscriber, address indexed creator, uint256 expiresAt);
    event EngagementRewardsDistributed(uint256 totalDistributed, uint256 creatorPortion, uint256 curatorPortion);
    event CreatorRevenueClaimed(address indexed creator, uint256 amount);
    event CuratorRewardsClaimed(address indexed curator, uint256 amount);
    event PlatformBalanceWithdrawn(address indexed recipient, uint256 amount);

    event AIScoreSubmitted(bytes32 indexed contentHash, uint8 score);
    event ContentVisibilityToggled(bytes32 indexed contentHash, bool isVisible, string reason);
    event ModeratorActionTaken(bytes32 indexed contentHash, address indexed moderator, bool approvedRemoval, bool setVisible);

    event AchievementAwarded(address indexed user, AchievementType indexed achievementType);
    event AchievementRevoked(address indexed user, AchievementType indexed achievementType);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event PlatformFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event RoyaltyParamsUpdated(uint256 creatorBps, uint256 curatorBps, uint256 engagementW, uint256 tipW);
    event ModeratorStatusUpdated(address indexed moderator, bool isModerator);
    event AIScoreOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // --- Modifiers ---

    modifier onlyAIScoreOracle() {
        require(msg.sender == aiScoreOracleAddress, "NexusFlow: Not AI Score Oracle");
        _;
    }

    modifier onlyModerator() {
        require(isModerator[msg.sender], "NexusFlow: Not a moderator");
        _;
    }

    modifier onlyDAO() {
        // In a deployed scenario, ownership would be transferred to the DAO multisig or contract.
        // For this example, if ownership has not been transferred, `owner()` can act as DAO initially.
        require(msg.sender == owner() || msg.sender == daoMultisigAddress, "NexusFlow: Not DAO or Owner");
        _;
    }

    // --- Constructor ---

    constructor(address _initialDaoMultisig, address _initialAIScoreOracle) Ownable(msg.sender) Pausable() {
        require(_initialDaoMultisig != address(0), "NexusFlow: DAO multisig cannot be zero address");
        require(_initialAIScoreOracle != address(0), "NexusFlow: AI Oracle cannot be zero address");

        platformFeeBps = 500; // 5%
        minSubscriptionAmount = 0.001 ether; // Example: 0.001 ETH
        aiFlaggingThreshold = 40; // Content with AI score < 40 might be flagged (warning)
        aiHidingThreshold = 20; // Content with AI score < 20 will be hidden (default)
        proposalQuorumBps = 4000; // 40% quorum for DAO proposals (of totalCommunityVoters)
        proposalVotingPeriod = 3 days; // 3 days for voting on proposals

        creatorRoyaltyShareBps = 7000; // Conceptual: 70% of a distributed pool goes to creators
        curatorRoyaltyShareBps = 3000; // Conceptual: 30% of a distributed pool goes to curators
        engagementWeight = 1; // Conceptual: 1 unit of reward per upvote
        tipWeight = 10; // Conceptual: 10 units of reward per 1 wei of tip amount

        aiScoreOracleAddress = _initialAIScoreOracle;
        daoMultisigAddress = _initialDaoMultisig;

        // Award initial DAO voter achievement to the initial DAO multisig for governance
        userAchievements[_initialDaoMultisig][AchievementType.CommunityVoter] = true;
        totalCommunityVoters = 1;
        emit AchievementAwarded(_initialDaoMultisig, AchievementType.CommunityVoter);
    }

    // --- 1. Core Content Management ---

    function publishContent(bytes32 _contentHash, string calldata _metadataURI)
        external
        whenNotPaused
        nonReentrant
    {
        require(contents[_contentHash].creator == address(0), "NexusFlow: Content already exists");
        require(bytes(_metadataURI).length > 0, "NexusFlow: Metadata URI cannot be empty");

        contents[_contentHash] = Content({
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            upvotes: 0,
            downvotes: 0,
            createdAt: block.timestamp,
            isCurated: false,
            isVisible: true, // Default to visible, AI can change this
            aiScore: 255, // 255 represents "not yet scored" by AI
            totalTips: 0,
            totalSubscriptionRevenue: 0
        });
        creatorContentHashes[msg.sender].push(_contentHash);
        emit ContentPublished(_contentHash, msg.sender, _metadataURI, block.timestamp);
    }

    function updateContentMetadata(bytes32 _contentHash, string calldata _newMetadataURI)
        external
        whenNotPaused
        nonReentrant
    {
        Content storage content = contents[_contentHash];
        require(content.creator == msg.sender, "NexusFlow: Not your content");
        require(bytes(_newMetadataURI).length > 0, "NexusFlow: New metadata URI cannot be empty");

        content.metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentHash, _newMetadataURI);
    }

    // This function only *requests* removal. Actual removal requires moderator/DAO action.
    function removeContentRequest(bytes32 _contentHash) external whenNotPaused {
        require(contents[_contentHash].creator == msg.sender, "NexusFlow: Not your content to request removal");
        emit ContentReported(_contentHash, msg.sender, "Creator requested removal");
    }

    function getContentDetails(bytes32 _contentHash)
        public
        view
        returns (
            address creator,
            string memory metadataURI,
            uint256 upvotes,
            uint256 downvotes,
            uint256 createdAt,
            bool isCurated,
            bool isVisible,
            uint8 aiScore,
            uint256 totalTips,
            uint256 totalSubscriptionRevenue
        )
    {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");
        return (
            content.creator,
            content.metadataURI,
            content.upvotes,
            content.downvotes,
            content.createdAt,
            content.isCurated,
            content.isVisible,
            content.aiScore,
            content.totalTips,
            content.totalSubscriptionRevenue
        );
    }

    function getCreatorContentHashes(address _creator) external view returns (bytes32[] memory) {
        return creatorContentHashes[_creator];
    }

    // --- 2. Engagement & Curation ---

    function upvoteContent(bytes32 _contentHash) external whenNotPaused nonReentrant {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");
        require(content.creator != msg.sender, "NexusFlow: Cannot upvote your own content");
        require(!hasUpvoted[msg.sender][_contentHash], "NexusFlow: Already upvoted");

        // If previously downvoted, remove downvote first
        if (hasDownvoted[msg.sender][_contentHash]) {
            content.downvotes--;
            hasDownvoted[msg.sender][_contentHash] = false;
        }

        content.upvotes++;
        hasUpvoted[msg.sender][_contentHash] = true;
        emit ContentUpvoted(_contentHash, msg.sender);
    }

    function downvoteContent(bytes32 _contentHash) external whenNotPaused nonReentrant {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");
        require(content.creator != msg.sender, "NexusFlow: Cannot downvote your own content");
        require(!hasDownvoted[msg.sender][_contentHash], "NexusFlow: Already downvoted");

        // If previously upvoted, remove upvote first
        if (hasUpvoted[msg.sender][_contentHash]) {
            content.upvotes--;
            hasUpvoted[msg.sender][_contentHash] = false;
        }

        content.downvotes++;
        hasDownvoted[msg.sender][_contentHash] = true;
        emit ContentDownvoted(_contentHash, msg.sender);
    }

    function tipCreator(bytes32 _contentHash) external payable whenNotPaused nonReentrant {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");
        require(msg.value > 0, "NexusFlow: Tip amount must be greater than zero");
        require(content.creator != msg.sender, "NexusFlow: Cannot tip yourself");

        uint256 platformShare = msg.value.mul(platformFeeBps).div(10000);
        uint256 creatorShare = msg.value.sub(platformShare);

        platformRevenuePool = platformRevenuePool.add(platformShare);
        creatorBalances[content.creator] = creatorBalances[content.creator].add(creatorShare);

        content.totalTips = content.totalTips.add(msg.value); // Store total value including platform fee for stats
        emit CreatorTipped(_contentHash, msg.sender, content.creator, msg.value);
    }

    function reportContent(bytes32 _contentHash, string calldata _reason) external whenNotPaused {
        require(contents[_contentHash].creator != address(0), "NexusFlow: Content not found");
        require(bytes(_reason).length > 0, "NexusFlow: Report reason cannot be empty");
        emit ContentReported(_contentHash, msg.sender, _reason);
    }

    function curateContent(bytes32 _contentHash) external onlyModerator whenNotPaused {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");
        require(!content.isCurated, "NexusFlow: Content already curated");

        content.isCurated = true;
        emit ContentCurated(_contentHash, msg.sender);
    }

    function addCommentHash(bytes32 _contentHash, bytes32 _commentHash) external whenNotPaused {
        require(contents[_contentHash].creator != address(0), "NexusFlow: Content not found");
        require(_commentHash != bytes32(0), "NexusFlow: Comment hash cannot be empty");
        emit CommentHashAdded(_contentHash, _commentHash, msg.sender);
    }

    // --- 3. Monetization & Revenue Distribution ---

    function setSubscriptionTier(uint256 _pricePerMonth) external whenNotPaused {
        require(_pricePerMonth >= minSubscriptionAmount, "NexusFlow: Price below min subscription amount");
        creatorSubscriptionTiers[msg.sender] = SubscriptionTier({
            pricePerMonth: _pricePerMonth,
            totalSubscribers: creatorSubscriptionTiers[msg.sender].totalSubscribers
        });
        emit SubscriptionTierSet(msg.sender, _pricePerMonth);
    }

    function subscribeToCreator(address _creator) external payable whenNotPaused nonReentrant {
        SubscriptionTier storage tier = creatorSubscriptionTiers[_creator];
        require(tier.pricePerMonth > 0, "NexusFlow: Creator has no active subscription tier");
        require(msg.value >= tier.pricePerMonth, "NexusFlow: Insufficient funds for subscription");

        // Calculate platform fee and creator's share
        uint256 platformShare = msg.value.mul(platformFeeBps).div(10000);
        uint256 creatorShare = msg.value.sub(platformShare);

        platformRevenuePool = platformRevenuePool.add(platformShare);
        creatorBalances[_creator] = creatorBalances[_creator].add(creatorShare);
        // This line attributes subscription revenue to the first content for simplicity.
        // A more complex system might aggregate it per creator or distribute across content.
        if (creatorContentHashes[_creator].length > 0) {
             contents[creatorContentHashes[_creator][0]].totalSubscriptionRevenue = contents[creatorContentHashes[_creator][0]].totalSubscriptionRevenue.add(msg.value);
        }

        uint256 currentExpiry = subscriptions[msg.sender][_creator];
        uint256 newExpiry = (currentExpiry > block.timestamp ? currentExpiry : block.timestamp).add(30 days); // Approx. 1 month
        subscriptions[msg.sender][_creator] = newExpiry;
        tier.totalSubscribers++;

        emit Subscribed(msg.sender, _creator, newExpiry);

        if (msg.value > tier.pricePerMonth) {
            // Refund any excess
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(tier.pricePerMonth)}("");
            require(success, "NexusFlow: Failed to refund excess");
        }
    }

    // Internal helper for collecting fees (not directly callable externally, but part of monetization logic)
    function _collectPlatformFees(uint256 _amount) internal {
        uint256 fee = _amount.mul(platformFeeBps).div(10000);
        platformRevenuePool = platformRevenuePool.add(fee);
    }

    // This function is intended to be called by the DAO to distribute a portion
    // of the `platformRevenuePool` to creators and curators as engagement rewards.
    // The specific recipients and amounts are determined off-chain based on content performance
    // and curation activity, then passed to this function.
    function distributeEngagementRewards(
        address[] calldata _creatorAddresses,
        uint256[] calldata _creatorAmounts,
        address[] calldata _curatorAddresses,
        uint256[] calldata _curatorAmounts
    ) external onlyDAO nonReentrant {
        require(_creatorAddresses.length == _creatorAmounts.length, "NexusFlow: Mismatch in creator arrays");
        require(_curatorAddresses.length == _curatorAmounts.length, "NexusFlow: Mismatch in curator arrays");

        uint256 totalDistributed = 0;
        uint256 totalCreatorRewards = 0;
        uint256 totalCuratorRewards = 0;

        for (uint256 i = 0; i < _creatorAddresses.length; i++) {
            uint256 amount = _creatorAmounts[i];
            require(platformRevenuePool >= amount, "NexusFlow: Insufficient pool balance for creator reward");
            creatorBalances[_creatorAddresses[i]] = creatorBalances[_creatorAddresses[i]].add(amount);
            platformRevenuePool = platformRevenuePool.sub(amount);
            totalDistributed = totalDistributed.add(amount);
            totalCreatorRewards = totalCreatorRewards.add(amount);
        }

        for (uint256 i = 0; i < _curatorAddresses.length; i++) {
            uint256 amount = _curatorAmounts[i];
            require(platformRevenuePool >= amount, "NexusFlow: Insufficient pool balance for curator reward");
            curatorBalances[_curatorAddresses[i]] = curatorBalances[_curatorAddresses[i]].add(amount);
            platformRevenuePool = platformRevenuePool.sub(amount);
            totalDistributed = totalDistributed.add(amount);
            totalCuratorRewards = totalCuratorRewards.add(amount);
        }
        emit EngagementRewardsDistributed(totalDistributed, totalCreatorRewards, totalCuratorRewards);
    }

    function claimCreatorRevenue() external nonReentrant {
        uint256 amount = creatorBalances[msg.sender];
        require(amount > 0, "NexusFlow: No revenue to claim");
        creatorBalances[msg.sender] = 0; // Reset balance before transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "NexusFlow: Failed to send ETH to creator");
        emit CreatorRevenueClaimed(msg.sender, amount);
    }

    function claimCuratorRewards() external nonReentrant {
        uint256 amount = curatorBalances[msg.sender];
        require(amount > 0, "NexusFlow: No rewards to claim");
        curatorBalances[msg.sender] = 0; // Reset balance before transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "NexusFlow: Failed to send ETH to curator");
        emit CuratorRewardsClaimed(msg.sender, amount);
    }

    function withdrawPlatformBalance(uint256 _amount) external onlyDAO nonReentrant {
        require(_amount > 0, "NexusFlow: Amount must be greater than zero");
        require(platformRevenuePool >= _amount, "NexusFlow: Insufficient platform balance");
        platformRevenuePool = platformRevenuePool.sub(_amount);
        (bool success, ) = payable(daoMultisigAddress).call{value: _amount}("");
        require(success, "NexusFlow: Failed to withdraw platform balance");
        emit PlatformBalanceWithdrawn(daoMultisigAddress, _amount);
    }

    // --- 4. AI Oracle & Moderation ---

    function submitContentAIScore(bytes32 _contentHash, uint8 _score) external onlyAIScoreOracle whenNotPaused {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");
        require(_score <= 100, "NexusFlow: AI score must be 0-100");

        content.aiScore = _score;
        emit AIScoreSubmitted(_contentHash, _score);

        // Auto-toggle visibility based on score thresholds
        toggleContentVisibilityByAI(_contentHash, (_score >= aiHidingThreshold));
    }

    function setAIScoreOracleAddress(address _newOracleAddress) external onlyDAO {
        require(_newOracleAddress != address(0), "NexusFlow: New AI Oracle address cannot be zero");
        emit AIScoreOracleAddressUpdated(aiScoreOracleAddress, _newOracleAddress);
        aiScoreOracleAddress = _newOracleAddress;
    }

    // Internal function called by submitContentAIScore or by moderator.
    function toggleContentVisibilityByAI(bytes32 _contentHash, bool _visible) internal {
        Content storage content = contents[_contentHash];
        if (content.isVisible != _visible) {
            content.isVisible = _visible;
            string memory reason = _visible ? "AI score above threshold" : "AI score below threshold";
            emit ContentVisibilityToggled(_contentHash, _visible, reason);
        }
    }

    function moderatorAction(bytes32 _contentHash, bool _approveRemoval, bool _setVisible)
        external
        onlyModerator
        whenNotPaused
    {
        Content storage content = contents[_contentHash];
        require(content.creator != address(0), "NexusFlow: Content not found");

        if (_approveRemoval) {
            // To simulate removal and avoid issues with deleting from dynamic arrays,
            // we effectively 'deactivate' the content by setting creator to zero address.
            // A more robust system would manage content arrays with specific deletion logic.
            content.creator = address(0); // Marks content as "removed"
            content.isVisible = false;
            emit ContentRemoved(_contentHash);
        } else {
            content.isVisible = _setVisible;
            emit ContentVisibilityToggled(_contentHash, _setVisible, "Moderator action");
        }
        emit ModeratorActionTaken(_contentHash, msg.sender, _approveRemoval, _setVisible);
    }

    // --- 5. Reputation & Achievements (Soulbound-like) ---

    function awardAchievement(address _user, AchievementType _type) external onlyDAO {
        require(_user != address(0), "NexusFlow: User address cannot be zero");
        require(!userAchievements[_user][_type], "NexusFlow: Achievement already awarded");
        userAchievements[_user][_type] = true;

        if (_type == AchievementType.CommunityVoter) {
            totalCommunityVoters++;
        }
        emit AchievementAwarded(_user, _type);
    }

    function getUserAchievements(address _user) external view returns (bool[] memory) {
        // Return all possible achievement types, for simplicity and gas efficiency
        bool[] memory achievements = new bool[](uint256(AchievementType.CommunityVoter) + 1);
        for (uint256 i = 0; i <= uint256(AchievementType.CommunityVoter); i++) {
            achievements[i] = userAchievements[_user][AchievementType(i)];
        }
        return achievements;
    }

    function revokeAchievement(address _user, AchievementType _type) external onlyDAO {
        require(_user != address(0), "NexusFlow: User address cannot be zero");
        require(userAchievements[_user][_type], "NexusFlow: User does not have this achievement");
        userAchievements[_user][_type] = false;

        if (_type == AchievementType.CommunityVoter) {
            require(totalCommunityVoters > 0, "NexusFlow: Total voting power cannot be negative");
            totalCommunityVoters--;
        }
        emit AchievementRevoked(_user, _type);
    }

    // --- 6. DAO Governance & Configuration ---

    function proposeConfigurationChange(
        string calldata _description,
        address _target,
        bytes calldata _callData,
        uint256 _votingPeriod // In seconds, allows overriding default
    ) external onlyDAO whenNotPaused nonReentrant returns (uint256) {
        // Simple token-less voting where each CommunityVoter achievement holder has 1 vote.
        require(userAchievements[msg.sender][AchievementType.CommunityVoter], "NexusFlow: Only CommunityVoters can propose");
        require(bytes(_description).length > 0, "NexusFlow: Description cannot be empty");
        require(_target != address(0), "NexusFlow: Target cannot be zero address");
        require(_callData.length > 0, "NexusFlow: Call data cannot be empty");

        uint256 proposalId = nextProposalId++;
        uint256 actualVotingPeriod = _votingPeriod > 0 ? _votingPeriod : proposalVotingPeriod;

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetContract: _target,
            callData: _callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(actualVotingPeriod),
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "NexusFlow: Proposal not found");
        require(userAchievements[msg.sender][AchievementType.CommunityVoter], "NexusFlow: Only CommunityVoters can vote");
        require(block.timestamp >= proposal.voteStartTime, "NexusFlow: Voting not started");
        require(block.timestamp <= proposal.voteEndTime, "NexusFlow: Voting has ended");
        require(!proposal.executed, "NexusFlow: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "NexusFlow: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit Voted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyDAO nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "NexusFlow: Proposal not found");
        require(block.timestamp > proposal.voteEndTime, "NexusFlow: Voting period not ended");
        require(!proposal.executed, "NexusFlow: Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        require(totalVotes > 0, "NexusFlow: No votes cast for this proposal"); 

        // Quorum check: Minimum percentage of total CommunityVoters must have voted
        uint256 requiredVotes = totalCommunityVoters.mul(proposalQuorumBps).div(10000);
        require(totalVotes >= requiredVotes, "NexusFlow: Quorum not met");

        // Simple majority: Yes votes must be strictly more than No votes.
        require(proposal.yesVotes > proposal.noVotes, "NexusFlow: Proposal failed to pass (no majority)");

        proposal.executed = true; // Mark as executed BEFORE calling to prevent reentrancy issues.

        // Execute the proposed call
        (bool success, bytes memory returndata) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("NexusFlow: Proposal execution failed: ", returndata)));

        emit ProposalExecuted(_proposalId);
    }

    function updatePlatformFee(uint256 _newFeeBps) external onlyDAO {
        require(_newFeeBps <= 10000, "NexusFlow: Fee must be <= 100%");
        emit PlatformFeeUpdated(platformFeeBps, _newFeeBps);
        platformFeeBps = _newFeeBps;
    }

    function updateRoyaltyDistributionParameters(
        uint252 _creatorShareBps, // Using uint252 for less-common uint size as an example, though uint256 is typical
        uint252 _curatorShareBps,
        uint256 _engagementWeight,
        uint256 _tipWeight
    ) external onlyDAO {
        require(_creatorShareBps.add(_curatorShareBps) == 10000, "NexusFlow: Creator and Curator shares must sum to 100%");
        creatorRoyaltyShareBps = _creatorShareBps;
        curatorRoyaltyShareBps = _curatorShareBps;
        engagementWeight = _engagementWeight;
        tipWeight = _tipWeight;
        emit RoyaltyParamsUpdated(_creatorShareBps, _curatorShareBps, _engagementWeight, _tipWeight);
    }

    function updateModeratorAddress(address _moderator, bool _isModerator) external onlyDAO {
        require(_moderator != address(0), "NexusFlow: Moderator address cannot be zero");
        isModerator[_moderator] = _isModerator;
        emit ModeratorStatusUpdated(_moderator, _isModerator);
    }

    // Standard Ownable function - owner should eventually be the DAO multisig or contract
    function transferOwnership(address _newOwner) public virtual override onlyOwner {
        // Once DAO is fully set up, ownership should be transferred to DAO multisig or DAO contract.
        // This is a critical step for decentralization.
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(_newOwner);
    }

    // --- Pausable override (inherited from OpenZeppelin) ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Fallback function to receive ETH
    receive() external payable {
        // All incoming ETH that is not part of a specific function call
        // (e.g., direct sends to contract) goes to the platform revenue pool.
        platformRevenuePool = platformRevenuePool.add(msg.value);
    }
}
```