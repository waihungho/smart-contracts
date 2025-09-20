This smart contract, "DecentralizedKnowledgeAgora (DKA)," envisions a platform where users collaboratively build and curate a decentralized knowledge base. It incorporates concepts like dynamic reputation, staked disputes, adaptive content scoring, time-decaying relevance, and an optional "AI Oracle" integration for advanced moderation. Users contribute "knowledge snippets," earn reputation for quality contributions and successful challenges, and can claim expertise badges.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For Badge interaction

/**
 * @title DecentralizedKnowledgeAgora (DKA)
 * @dev A smart contract for a collaborative, decentralized knowledge base featuring dynamic reputation,
 *      staked challenges, adaptive content scoring, time-decaying relevance, and AI oracle integration.
 *      Users contribute knowledge, curate content, challenge accuracy, and earn rewards and reputation.
 */
contract DecentralizedKnowledgeAgora is Ownable {
    using Counters for Counters.Counter;

    /* ================================== */
    /* I. Outline:                        */
    /* ================================== */
    // I. Core Data Structures
    // II. Events
    // III. Modifiers & Custom Errors
    // IV. Constructor
    // V. Core Knowledge Snippet Management (Functions 1-4)
    // VI. User Reputation & Expertise (Functions 5-7)
    // VII. Curation & Quality Assessment (Functions 8-11)
    // VIII. Challenging & Dispute Resolution (Functions 12-15)
    // IX. Governance & DAO (Simplified) (Functions 16-18)
    // X. Token & Rewards (Functions 19-20)
    // XI. Advanced & Oracle Integrations (Functions 21-25)
    // XII. Internal Helper Functions & Views

    /* ================================== */
    /* II. Function Summary:              */
    /* ================================== */
    // 1. submitKnowledgeSnippet: Adds a new knowledge entry to the Agora with an IPFS hash and category tags.
    // 2. getKnowledgeSnippet: Retrieves detailed information about a specific knowledge snippet by its ID.
    // 3. updateSnippetIpfsHash: Allows the original contributor or a highly-reputed user to update a snippet's content link.
    // 4. deprecateKnowledgeSnippet: Marks a snippet as deprecated, effectively removing it from active view without deleting its history.
    // 5. getUserReputation: Fetches the overall reputation score of a user.
    // 6. getDomainExpertise: Retrieves a user's expertise score for a specific knowledge category.
    // 7. mintDomainExpertiseBadge: Allows a user to claim a special NFT badge if they meet the expertise criteria for a category.
    // 8. upvoteKnowledgeSnippet: Increases a snippet's quality and relevance score, requiring a small stake.
    // 9. downvoteKnowledgeSnippet: Decreases a snippet's quality and relevance score, requiring a small stake.
    // 10. reaffirmKnowledgeSnippet: Resets the relevance decay timer for a snippet, indicating it's still current and preventing decay.
    // 11. triggerRelevanceDecay: Allows anyone to trigger the relevance score decay for a batch of snippets, incentivizing maintenance.
    // 12. initiateKnowledgeChallenge: Starts a formal dispute process against a snippet's accuracy, requiring a stake.
    // 13. supportChallenge: Users stake tokens to support the challenger's claim (snippet is false).
    // 14. defendSnippet: Users stake tokens to defend the snippet's accuracy (snippet is true).
    // 15. resolveChallenge: Concludes a challenge, distributes stakes to the winning side, and updates reputation/scores.
    // 16. proposeParameterChange: Initiates a governance proposal to alter contract parameters (e.g., challenge duration, min stakes).
    // 17. voteOnProposal: Allows users with sufficient reputation/tokens to vote on an active governance proposal.
    // 18. executeProposal: Executes a governance proposal that has passed its voting period and met quorum.
    // 19. claimRewards: Allows users to claim accumulated DKA tokens from contributions, successful challenges, or curation.
    // 20. withdrawStakedTokens: Allows users to withdraw their tokens after a challenge they participated in has been resolved.
    // 21. setModeratorOracleAddress: Sets the address of a trusted off-chain AI/human moderation oracle (governance-only).
    // 22. attestSnippetValidity: An authorized oracle can provide an official attestation of a snippet's validity, boosting its score.
    // 23. updateMinimumReputationForAction: Governance function to dynamically adjust reputation requirements for certain actions.
    // 24. getPendingChallenges: Returns a list of all currently active challenges awaiting resolution.
    // 25. getSnippetsByCategory: Provides a paginated list of knowledge snippets filtered by a specific category.

    /* ================================== */
    /* III. Core Data Structures          */
    /* ================================== */

    // Status of a knowledge challenge
    enum ChallengeStatus { Pending, ResolvedTrue, ResolvedFalse, Cancelled }

    // Structure for a single knowledge snippet
    struct KnowledgeSnippet {
        uint256 id;
        address contributor;
        string ipfsHash;
        bytes32[] categoryTags;
        uint256 submissionTimestamp;
        int256 currentQualityScore; // Can be positive or negative
        uint256 relevanceScore;     // Decays over time, higher means more relevant
        uint256 lastReaffirmationTimestamp;
        bool isDeprecated;
        bool hasOracleAttestation; // True if an oracle has attested its validity

        // Challenge-related fields
        bool isChallenged;
        uint256 currentChallengeId; // ID of the active challenge if any
    }

    // Structure for a user's profile and reputation
    struct UserProfile {
        uint256 reputationScore; // Overall reputation
        uint256 contributionsCount;
        uint256 challengesWon;
        uint256 challengesLost;
        mapping(bytes32 => uint256) domainExpertise; // categoryHash => score
        mapping(bytes32 => bool) claimedExpertiseBadge; // categoryHash => true if badge claimed
    }

    // Structure for a knowledge challenge
    struct KnowledgeChallenge {
        uint256 id;
        uint256 snippetId;
        address challenger;
        string reasonIpfsHash;
        uint256 initiationTimestamp;
        uint256 votingPeriodEnd;
        ChallengeStatus status;
        uint256 totalYesVotesStake; // Stake for "snippet is false" (challenger's side)
        uint256 totalNoVotesStake;  // Stake for "snippet is true" (contributor's side)
        uint256 winningSide;        // 0: undecided, 1: challenger wins, 2: contributor wins
        mapping(address => uint256) stakeholderStakes; // User => stake amount
    }

    // Structure for a governance proposal
    struct GovernanceProposal {
        uint256 id;
        bytes32 paramName;
        uint256 newValue;
        uint256 proposerReputationAtProposing; // Reputation of proposer at time of proposal
        uint256 submissionTimestamp;
        uint256 votingPeriodEnd;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed; // True if passed quorum and majority
        mapping(address => bool) hasVoted;
    }

    /* ================================== */
    /* IV. Global State Variables         */
    /* ================================== */

    // Counters for unique IDs
    Counters.Counter private _snippetIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _proposalIds;

    // Mappings for data retrieval
    mapping(uint256 => KnowledgeSnippet) public knowledgeSnippets;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => KnowledgeChallenge) public knowledgeChallenges;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(bytes32 => uint256[]) public categoryToSnippets; // categoryHash => array of snippet IDs

    // Token contracts
    IERC20 public immutable DKAToken;
    IERC721 public immutable DKABadges; // NFT contract for expertise badges

    // Rewards pool and distribution
    mapping(address => uint256) public userRewardBalances;

    // Governance parameters (can be changed via proposals)
    uint256 public MIN_REPUTATION_FOR_CONTRIBUTION = 10;
    uint256 public MIN_REPUTATION_FOR_CHALLENGE = 50;
    uint256 public MIN_STAKE_FOR_CHALLENGE = 100 * (10 ** 18); // 100 DKA
    uint256 public CHALLENGE_VOTING_PERIOD = 3 days;
    uint256 public GOVERNANCE_VOTING_PERIOD = 7 days;
    uint256 public GOVERNANCE_QUORUM_PERCENT = 51; // 51% of total voting power (or active proposers rep)
    uint256 public REPUTATION_GAIN_CONTRIBUTION = 5;
    uint256 public REPUTATION_GAIN_CHALLENGE_WIN = 20;
    uint256 public REPUTATION_LOSS_CHALLENGE_LOSE = 15;
    uint256 public REPUTATION_GAIN_CURATION = 1; // For up/downvoting
    uint256 public RELEVANCE_DECAY_RATE_PER_DAY = 1; // Points per day
    uint256 public QUALITY_SCORE_CHANGE_CURATION = 2; // For up/downvoting
    uint256 public EXPERTISE_BADGE_THRESHOLD = 50; // Required expertise score to mint badge

    // Moderator Oracle address (can be set by governance for external validation)
    address public moderatorOracleAddress;

    /* ================================== */
    /* IV. Events                         */
    /* ================================== */

    event KnowledgeSnippetSubmitted(uint256 indexed snippetId, address indexed contributor, string ipfsHash, bytes32[] categoryTags, uint256 timestamp);
    event KnowledgeSnippetUpdated(uint256 indexed snippetId, address indexed updater, string newIpfsHash, uint256 timestamp);
    event KnowledgeSnippetDeprecated(uint256 indexed snippetId, address indexed actor, uint256 timestamp);
    event SnippetQualityScoreUpdated(uint256 indexed snippetId, int256 newScore, address indexed initiator);
    event SnippetRelevanceUpdated(uint256 indexed snippetId, uint256 newRelevanceScore);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed snippetId, address indexed challenger, uint256 stakeAmount, uint256 votingPeriodEnd);
    event ChallengeStakeAdded(uint256 indexed challengeId, address indexed stakeholder, bool supportsChallenger, uint256 amount);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed snippetId, ChallengeStatus status, uint256 winningSide, uint256 totalRewardPool);
    event RewardsClaimed(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);
    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event DomainExpertiseUpdated(address indexed user, bytes32 indexed category, uint256 newScore);
    event ExpertiseBadgeMinted(address indexed user, bytes32 indexed category, uint256 badgeId);
    event GovernanceProposalCreated(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, address indexed proposer);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool passed);
    event ModeratorOracleSet(address indexed oldOracle, address indexed newOracle);
    event SnippetAttestedByOracle(uint256 indexed snippetId, address indexed oracle, bool isValid, string proofIpfsHash);

    /* ================================== */
    /* V. Modifiers & Custom Errors       */
    /* ================================== */

    error InsufficientReputation(uint256 required, uint256 current);
    error InvalidSnippetId(uint256 snippetId);
    error InvalidChallengeId(uint256 challengeId);
    error InvalidProposalId(uint256 proposalId);
    error ChallengeNotActive(uint256 challengeId);
    error ChallengeAlreadyResolved(uint256 challengeId);
    error ChallengeNotYetResolved(uint256 challengeId);
    error ChallengeVotingPeriodActive(uint256 challengeId);
    error NotEnoughStake(uint256 required, uint256 current);
    error AlreadyVoted(uint256 proposalId, address voter);
    error VotingPeriodEnded(uint256 proposalId);
    error VotingPeriodNotEnded(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalFailedQuorumOrMajority(uint256 proposalId);
    error AlreadyAttested(uint256 snippetId);
    error NotOracle(address caller);
    error ReputationThresholdNotMet(uint256 currentRep, uint256 requiredRep);
    error NotContributorOrHighRep(address caller, address contributor, uint256 callerRep);
    error SnippetAlreadyDeprecated(uint256 snippetId);
    error SnippetAlreadyChallenged(uint256 snippetId);
    error ExpertiseBadgeAlreadyClaimed(bytes32 category);
    error ExpertiseThresholdNotMet(uint256 currentExp, uint256 requiredExp);
    error NoRewardsToClaim(address user);
    error NoStakedTokensToWithdraw(address user);
    error TooManySnippetsForDecay(uint256 count, uint256 max);

    modifier onlyModeratorOracle() {
        if (msg.sender != moderatorOracleAddress) revert NotOracle(msg.sender);
        _;
    }

    /* ================================== */
    /* VI. Constructor                    */
    /* ================================== */

    constructor(address _dkaTokenAddress, address _dkaBadgesAddress) Ownable(msg.sender) {
        DKAToken = IERC20(_dkaTokenAddress);
        DKABadges = IERC721(_dkaBadgesAddress);
        // Initial reputation for owner to get things started
        userProfiles[msg.sender].reputationScore = 1000;
        emit UserReputationUpdated(msg.sender, 1000);
    }

    /* ================================== */
    /* V. Core Knowledge Snippet Management (Functions 1-4) */
    /* ================================== */

    /**
     * @dev 1. submitKnowledgeSnippet: Allows a user to add a new knowledge entry.
     *      Requires a minimum reputation score.
     * @param _ipfsHash IPFS hash pointing to the knowledge content.
     * @param _categoryTags Array of bytes32 representing categories (e.g., keccak256("Science"), keccak256("History")).
     */
    function submitKnowledgeSnippet(string memory _ipfsHash, bytes32[] memory _categoryTags) external {
        UserProfile storage senderProfile = userProfiles[msg.sender];
        if (senderProfile.reputationScore < MIN_REPUTATION_FOR_CONTRIBUTION) {
            revert InsufficientReputation(MIN_REPUTATION_FOR_CONTRIBUTION, senderProfile.reputationScore);
        }

        _snippetIds.increment();
        uint256 newSnippetId = _snippetIds.current();

        knowledgeSnippets[newSnippetId] = KnowledgeSnippet({
            id: newSnippetId,
            contributor: msg.sender,
            ipfsHash: _ipfsHash,
            categoryTags: _categoryTags,
            submissionTimestamp: block.timestamp,
            currentQualityScore: 0,
            relevanceScore: 100, // Start with high relevance
            lastReaffirmationTimestamp: block.timestamp,
            isDeprecated: false,
            hasOracleAttestation: false,
            isChallenged: false,
            currentChallengeId: 0
        });

        senderProfile.contributionsCount++;
        _updateReputation(msg.sender, REPUTATION_GAIN_CONTRIBUTION); // Reward for contributing

        // Add to category mappings
        for (uint256 i = 0; i < _categoryTags.length; i++) {
            categoryToSnippets[_categoryTags[i]].push(newSnippetId);
            _updateDomainExpertise(msg.sender, _categoryTags[i], 1); // Small expertise gain
        }

        emit KnowledgeSnippetSubmitted(newSnippetId, msg.sender, _ipfsHash, _categoryTags, block.timestamp);
    }

    /**
     * @dev 2. getKnowledgeSnippet: Retrieves detailed information about a knowledge snippet.
     * @param _snippetId The ID of the knowledge snippet.
     * @return KnowledgeSnippet struct containing all details.
     */
    function getKnowledgeSnippet(uint256 _snippetId) public view returns (KnowledgeSnippet memory) {
        if (_snippetId == 0 || _snippetId > _snippetIds.current()) revert InvalidSnippetId(_snippetId);
        return knowledgeSnippets[_snippetId];
    }

    /**
     * @dev 3. updateSnippetIpfsHash: Allows the original contributor or a highly-reputed user
     *      to update the IPFS hash of a snippet, for minor corrections.
     *      Requires the caller to be the contributor OR have high reputation (e.g., 2x MIN_REPUTATION_FOR_CONTRIBUTION).
     * @param _snippetId The ID of the snippet to update.
     * @param _newIpfsHash The new IPFS hash for the content.
     */
    function updateSnippetIpfsHash(uint256 _snippetId, string memory _newIpfsHash) external {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);

        UserProfile storage senderProfile = userProfiles[msg.sender];
        if (msg.sender != snippet.contributor && senderProfile.reputationScore < (MIN_REPUTATION_FOR_CONTRIBUTION * 2)) {
            revert NotContributorOrHighRep(msg.sender, snippet.contributor, senderProfile.reputationScore);
        }

        string memory oldIpfsHash = snippet.ipfsHash; // Store for event
        snippet.ipfsHash = _newIpfsHash;

        emit KnowledgeSnippetUpdated(_snippetId, msg.sender, _newIpfsHash, block.timestamp);
    }

    /**
     * @dev 4. deprecateKnowledgeSnippet: Marks a snippet as deprecated. Deprecated snippets are not deleted,
     *      but are filtered from active views and cannot be challenged or updated.
     *      Can be called by the contributor, a high-reputation user, or via governance.
     * @param _snippetId The ID of the snippet to deprecate.
     */
    function deprecateKnowledgeSnippet(uint256 _snippetId) external {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);

        UserProfile storage senderProfile = userProfiles[msg.sender];
        if (msg.sender != snippet.contributor && senderProfile.reputationScore < (MIN_REPUTATION_FOR_CONTRIBUTION * 3) && msg.sender != owner()) {
            revert NotContributorOrHighRep(msg.sender, snippet.contributor, senderProfile.reputationScore);
        }

        snippet.isDeprecated = true;
        snippet.isChallenged = false; // Remove from any active challenge state

        // No reputation loss for contributor if they deprecate themselves or if it's high-rep/governance.
        // Reputation loss for contributor might occur if it was deprecated due to failed challenge.

        emit KnowledgeSnippetDeprecated(_snippetId, msg.sender, block.timestamp);
    }

    /* ================================== */
    /* VI. User Reputation & Expertise (Functions 5-7) */
    /* ================================== */

    /**
     * @dev 5. getUserReputation: Fetches the current reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    /**
     * @dev 6. getDomainExpertise: Retrieves a user's expertise score for a specific knowledge category.
     * @param _user The address of the user.
     * @param _category The bytes32 hash of the category.
     * @return The expertise score for that category.
     */
    function getDomainExpertise(address _user, bytes32 _category) public view returns (uint256) {
        return userProfiles[_user].domainExpertise[_category];
    }

    /**
     * @dev 7. mintDomainExpertiseBadge: Allows a user to claim a special NFT badge
     *      if they meet the expertise criteria for a specific category.
     *      Requires the DKABadges contract to be able to mint to the caller.
     * @param _category The bytes32 hash of the category for which to claim the badge.
     */
    function mintDomainExpertiseBadge(bytes32 _category) external {
        UserProfile storage senderProfile = userProfiles[msg.sender];
        if (senderProfile.domainExpertise[_category] < EXPERTISE_BADGE_THRESHOLD) {
            revert ExpertiseThresholdNotMet(senderProfile.domainExpertise[_category], EXPERTISE_BADGE_THRESHOLD);
        }
        if (senderProfile.claimedExpertiseBadge[_category]) {
            revert ExpertiseBadgeAlreadyClaimed(_category);
        }

        // Here we assume the DKABadges contract has a `mint(address to, bytes32 category)` function
        // and this contract has the minter role on DKABadges or is the owner.
        // For simplicity, we'll simulate the interaction, but in a real scenario,
        // you'd call `DKABadges.mint(msg.sender, _category);`
        // We'll just mark it as claimed internally.
        senderProfile.claimedExpertiseBadge[_category] = true;

        emit ExpertiseBadgeMinted(msg.sender, _category, 0); // Placeholder for actual NFT ID if DKABadges mints one
    }

    /* ================================== */
    /* VII. Curation & Quality Assessment (Functions 8-11) */
    /* ================================== */

    /**
     * @dev 8. upvoteKnowledgeSnippet: Increases a snippet's quality and relevance score.
     *      Requires a small stake to prevent spam, which is returned or contributed to a pool.
     * @param _snippetId The ID of the snippet to upvote.
     */
    function upvoteKnowledgeSnippet(uint256 _snippetId) external {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);

        // Assume a small token transfer or approval for 'curation fee' or stake.
        // For simplicity, we'll just require user to have certain rep and not a stake.
        // If a stake was required: DKAToken.transferFrom(msg.sender, address(this), CURATION_STAKE);

        snippet.currentQualityScore += int256(QUALITY_SCORE_CHANGE_CURATION);
        snippet.relevanceScore += QUALITY_SCORE_CHANGE_CURATION; // Upvotes also increase relevance
        _updateReputation(msg.sender, REPUTATION_GAIN_CURATION);
        _updateDomainExpertiseForSnippet(msg.sender, _snippetId, 1); // Small expertise gain

        emit SnippetQualityScoreUpdated(_snippetId, snippet.currentQualityScore, msg.sender);
        emit SnippetRelevanceUpdated(_snippetId, snippet.relevanceScore);
    }

    /**
     * @dev 9. downvoteKnowledgeSnippet: Decreases a snippet's quality and relevance score.
     *      Requires a small stake to prevent spam.
     * @param _snippetId The ID of the snippet to downvote.
     */
    function downvoteKnowledgeSnippet(uint256 _snippetId) external {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);

        // Same as upvote, assume a stake or rep requirement.

        snippet.currentQualityScore -= int256(QUALITY_SCORE_CHANGE_CURATION);
        if (snippet.relevanceScore > QUALITY_SCORE_CHANGE_CURATION) {
            snippet.relevanceScore -= QUALITY_SCORE_CHANGE_CURATION;
        } else {
            snippet.relevanceScore = 0;
        }
        _updateReputation(msg.sender, REPUTATION_GAIN_CURATION); // Still rewards for curation
        _updateDomainExpertiseForSnippet(msg.sender, _snippetId, 1); // Small expertise gain

        emit SnippetQualityScoreUpdated(_snippetId, snippet.currentQualityScore, msg.sender);
        emit SnippetRelevanceUpdated(_snippetId, snippet.relevanceScore);
    }

    /**
     * @dev 10. reaffirmKnowledgeSnippet: Resets the relevance decay timer for a snippet,
     *       indicating it's still current and preventing its relevance score from dropping.
     * @param _snippetId The ID of the snippet to reaffirm.
     */
    function reaffirmKnowledgeSnippet(uint256 _snippetId) external {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);

        snippet.lastReaffirmationTimestamp = block.timestamp;
        _updateReputation(msg.sender, REPUTATION_GAIN_CURATION); // Reward for active curation

        emit SnippetRelevanceUpdated(_snippetId, snippet.relevanceScore); // Relevance score itself might not change, but decay timer resets
    }

    /**
     * @dev 11. triggerRelevanceDecay: Allows anyone to trigger the relevance score decay for a batch of snippets.
     *      This is incentivized to ensure scores are kept up-to-date.
     * @param _snippetIds Array of snippet IDs for which to trigger decay. Max 50 per call.
     */
    function triggerRelevanceDecay(uint256[] memory _snippetIds) external {
        if (_snippetIds.length == 0 || _snippetIds.length > 50) revert TooManySnippetsForDecay(_snippetIds.length, 50);

        uint256 totalDecayProcessed = 0;
        for (uint256 i = 0; i < _snippetIds.length; i++) {
            KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetIds[i]];
            if (snippet.id == 0 || snippet.isDeprecated || snippet.isChallenged) continue;

            uint256 timeSinceLastReaffirmation = block.timestamp - snippet.lastReaffirmationTimestamp;
            uint256 daysSinceReaffirmation = timeSinceLastReaffirmation / 1 days;

            if (daysSinceReaffirmation > 0) {
                uint256 decayAmount = daysSinceReaffirmation * RELEVANCE_DECAY_RATE_PER_DAY;
                if (snippet.relevanceScore > decayAmount) {
                    snippet.relevanceScore -= decayAmount;
                } else {
                    snippet.relevanceScore = 0;
                }
                snippet.lastReaffirmationTimestamp = block.timestamp; // Update to prevent double decay for same period
                totalDecayProcessed++;
                emit SnippetRelevanceUpdated(snippet.id, snippet.relevanceScore);
            }
        }
        // Reward the caller for helping maintain the relevance scores
        if (totalDecayProcessed > 0) {
            uint256 rewardAmount = totalDecayProcessed * (10 ** 18); // e.g., 1 DKA per snippet processed
            userRewardBalances[msg.sender] += rewardAmount;
        }
    }

    /* ================================== */
    /* VIII. Challenging & Dispute Resolution (Functions 12-15) */
    /* ================================== */

    /**
     * @dev 12. initiateKnowledgeChallenge: Starts a formal dispute process against a snippet's accuracy.
     *      Requires a minimum reputation score and a stake in DKA tokens.
     * @param _snippetId The ID of the snippet to challenge.
     * @param _reasonIpfsHash IPFS hash pointing to the detailed reason for the challenge.
     * @param _stakeAmount The amount of DKA tokens to stake for the challenge.
     */
    function initiateKnowledgeChallenge(uint256 _snippetId, string memory _reasonIpfsHash, uint256 _stakeAmount) external {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);
        if (snippet.isChallenged) revert SnippetAlreadyChallenged(_snippetId);

        UserProfile storage senderProfile = userProfiles[msg.sender];
        if (senderProfile.reputationScore < MIN_REPUTATION_FOR_CHALLENGE) {
            revert InsufficientReputation(MIN_REPUTATION_FOR_CHALLENGE, senderProfile.reputationScore);
        }
        if (_stakeAmount < MIN_STAKE_FOR_CHALLENGE) {
            revert NotEnoughStake(MIN_STAKE_FOR_CHALLENGE, _stakeAmount);
        }
        // Transfer stake from challenger
        if (!DKAToken.transferFrom(msg.sender, address(this), _stakeAmount)) {
            revert("DKA: TransferFrom failed for challenge stake");
        }

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        knowledgeChallenges[newChallengeId] = KnowledgeChallenge({
            id: newChallengeId,
            snippetId: _snippetId,
            challenger: msg.sender,
            reasonIpfsHash: _reasonIpfsHash,
            initiationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + CHALLENGE_VOTING_PERIOD,
            status: ChallengeStatus.Pending,
            totalYesVotesStake: _stakeAmount, // Challenger supports "snippet is false"
            totalNoVotesStake: 0,
            winningSide: 0,
            stakeholderStakes: new mapping(address => uint256)
        });
        knowledgeChallenges[newChallengeId].stakeholderStakes[msg.sender] = _stakeAmount;

        snippet.isChallenged = true;
        snippet.currentChallengeId = newChallengeId;

        emit ChallengeInitiated(newChallengeId, _snippetId, msg.sender, _stakeAmount, knowledgeChallenges[newChallengeId].votingPeriodEnd);
    }

    /**
     * @dev 13. supportChallenge: Allows users to stake tokens to support the challenger's claim (snippet is false).
     * @param _challengeId The ID of the active challenge.
     * @param _stakeAmount The amount of DKA tokens to stake.
     */
    function supportChallenge(uint256 _challengeId, uint256 _stakeAmount) external {
        KnowledgeChallenge storage challenge = knowledgeChallenges[_challengeId];
        if (challenge.id == 0) revert InvalidChallengeId(_challengeId);
        if (challenge.status != ChallengeStatus.Pending) revert ChallengeNotActive(_challengeId);
        if (block.timestamp >= challenge.votingPeriodEnd) revert ChallengeVotingPeriodActive(_challengeId);
        if (_stakeAmount == 0) revert NotEnoughStake(1, 0); // Must stake something

        if (!DKAToken.transferFrom(msg.sender, address(this), _stakeAmount)) {
            revert("DKA: TransferFrom failed for challenge support stake");
        }

        challenge.totalYesVotesStake += _stakeAmount;
        challenge.stakeholderStakes[msg.sender] += _stakeAmount;

        emit ChallengeStakeAdded(_challengeId, msg.sender, true, _stakeAmount);
    }

    /**
     * @dev 14. defendSnippet: Allows users to stake tokens to defend the snippet's accuracy (snippet is true).
     * @param _challengeId The ID of the active challenge.
     * @param _stakeAmount The amount of DKA tokens to stake.
     */
    function defendSnippet(uint256 _challengeId, uint256 _stakeAmount) external {
        KnowledgeChallenge storage challenge = knowledgeChallenges[_challengeId];
        if (challenge.id == 0) revert InvalidChallengeId(_challengeId);
        if (challenge.status != ChallengeStatus.Pending) revert ChallengeNotActive(_challengeId);
        if (block.timestamp >= challenge.votingPeriodEnd) revert ChallengeVotingPeriodActive(_challengeId);
        if (_stakeAmount == 0) revert NotEnoughStake(1, 0); // Must stake something

        if (!DKAToken.transferFrom(msg.sender, address(this), _stakeAmount)) {
            revert("DKA: TransferFrom failed for snippet defense stake");
        }

        challenge.totalNoVotesStake += _stakeAmount;
        challenge.stakeholderStakes[msg.sender] += _stakeAmount;

        emit ChallengeStakeAdded(_challengeId, msg.sender, false, _stakeAmount);
    }

    /**
     * @dev 15. resolveChallenge: Concludes a challenge, distributes stakes to the winning side,
     *      and updates reputation/scores. Can be called by anyone after the voting period ends.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) external {
        KnowledgeChallenge storage challenge = knowledgeChallenges[_challengeId];
        if (challenge.id == 0) revert InvalidChallengeId(_challengeId);
        if (challenge.status != ChallengeStatus.Pending) revert ChallengeNotActive(_challengeId);
        if (block.timestamp < challenge.votingPeriodEnd) revert ChallengeNotYetResolved(_challengeId);

        KnowledgeSnippet storage snippet = knowledgeSnippets[challenge.snippetId];

        uint256 totalStake = challenge.totalYesVotesStake + challenge.totalNoVotesStake;
        uint256 winningSide; // 1: Challenger wins (snippet is false), 2: Contributor wins (snippet is true)
        uint256 loserStake;
        uint256 winnerStake;

        if (challenge.totalYesVotesStake > challenge.totalNoVotesStake) {
            winningSide = 1; // Challenger wins
            challenge.status = ChallengeStatus.ResolvedFalse;
            loserStake = challenge.totalNoVotesStake;
            winnerStake = challenge.totalYesVotesStake;
            snippet.isDeprecated = true; // Mark snippet as deprecated if challenger wins
            snippet.currentQualityScore -= 50; // Significant quality hit
            _updateReputation(snippet.contributor, int256(REPUTATION_LOSS_CHALLENGE_LOSE * -1)); // Contributor loses rep
            userProfiles[challenge.challenger].challengesWon++;
        } else if (challenge.totalNoVotesStake > challenge.totalYesVotesStake) {
            winningSide = 2; // Contributor wins
            challenge.status = ChallengeStatus.ResolvedTrue;
            loserStake = challenge.totalYesVotesStake;
            winnerStake = challenge.totalNoVotesStake;
            snippet.currentQualityScore += 30; // Quality boost for defending successfully
            _updateReputation(snippet.contributor, REPUTATION_GAIN_CHALLENGE_WIN); // Contributor gains rep
            userProfiles[challenge.challenger].challengesLost++;
        } else {
            // Tie - stakes are returned to original stakers, no change to snippet, no reputation change for challenger
            // Contributor still might face slight negative quality hit for controversy.
            challenge.status = ChallengeStatus.Cancelled; // Or a specific 'Tied' status
            winningSide = 0; // Undecided
            loserStake = 0; // No real loser or winner
            winnerStake = 0;
            snippet.currentQualityScore -= 10;
        }

        // Distribute rewards from loser stakes
        if (totalStake > 0) {
            // All stakes are sent to the contract's address during staking.
            // Loser's stake is distributed among winners (proportional to their stake)
            // Or split between winners and a community fund / burning mechanism.
            // For simplicity, let's say loser stake is added to a general reward pool
            // and then winners claim their portion later.

            // The 'loserStake' can be used as a reward for the 'winningSide' proportional to their stake.
            // Example: 80% of loser stake goes to winners, 20% to community treasury/burn.

            // Iterate over all stakeholders to determine their share.
            // This can be gas-intensive for many stakeholders.
            // A simpler approach: a portion of the loser's stake is simply locked or burned,
            // and winners get a fixed bonus or a share of *a portion* of the pool.
            // Let's go with a simplified approach where losers' stakes are 'burned' (or sent to a zero address),
            // and winners get a reputation boost, and a portion of the *total* stakes is added to a general reward pool.

            uint256 totalRewardPool = 0;
            if (winningSide != 0) { // If there's a clear winner
                uint256 rewardFactor = 10000; // Basis for percentage calculation (100%)
                uint256 communityCutNumerator = 2000; // 20%
                uint256 winnerCutNumerator = rewardFactor - communityCutNumerator; // 80%

                uint256 communityShare = (loserStake * communityCutNumerator) / rewardFactor;
                uint256 winnerSharePool = loserStake - communityShare; // Pool to be distributed among winning stakers

                // Add communityShare to a separate address or burn it
                // DKAToken.transfer(COMMUNITY_TREASURY_ADDRESS, communityShare); // If a treasury exists

                // Distribute winnerSharePool proportionally
                for (address stakeholder : challenge.stakeholderStakes.keys()) { // This assumes a `.keys()` method, which isn't native.
                                                                                // For simplicity, this iteration will be omitted or handled off-chain
                                                                                // and specific claim function will be used.
                    // For now, let's keep it simple: winning side stakers are able to claim their *original stake back* plus a share of the *loser's stake*.
                    // And the total pool for distribution will be calculated.
                }

                // Simplified reward distribution logic:
                // Winners get their stake back PLUS a proportional share of the loser's total stake.
                // Losers forfeit their stake.
                // If tie, everyone gets their stake back.

                if (winningSide == 1) { // Challenger wins
                    // Challenger and supporters get their stake back + proportional share of defender's stake
                    for (address stakeholder : challenge.stakeholderStakes.keys()) { // Requires iterating map keys, complex on-chain
                        if (challenge.stakeholderStakes[stakeholder] > 0 && challenge.totalYesVotesStake > 0) {
                            uint256 amountToReturn = challenge.stakeholderStakes[stakeholder];
                            uint256 rewardFromLosers = (amountToReturn * loserStake) / winnerStake; // Proportional share
                            userRewardBalances[stakeholder] += (amountToReturn + rewardFromLosers);
                            totalRewardPool += (amountToReturn + rewardFromLosers);
                            _updateReputation(stakeholder, REPUTATION_GAIN_CHALLENGE_WIN / 2); // Supporters also get reputation
                        }
                    }
                } else if (winningSide == 2) { // Contributor wins
                    // Contributor and defenders get their stake back + proportional share of challenger's stake
                    for (address stakeholder : challenge.stakeholderStakes.keys()) { // Requires iterating map keys, complex on-chain
                        if (challenge.stakeholderStakes[stakeholder] > 0 && challenge.totalNoVotesStake > 0) {
                            uint256 amountToReturn = challenge.stakeholderStakes[stakeholder];
                            uint256 rewardFromLosers = (amountToReturn * loserStake) / winnerStake; // Proportional share
                            userRewardBalances[stakeholder] += (amountToReturn + rewardFromLosers);
                            totalRewardPool += (amountToReturn + rewardFromLosers);
                            _updateReputation(stakeholder, REPUTATION_GAIN_CHALLENGE_WIN / 2); // Supporters also get reputation
                        }
                    }
                } else { // Tie or cancelled, all stakeholders get their initial stake back
                    for (address stakeholder : challenge.stakeholderStakes.keys()) { // Requires iterating map keys, complex on-chain
                        if (challenge.stakeholderStakes[stakeholder] > 0) {
                            userRewardBalances[stakeholder] += challenge.stakeholderStakes[stakeholder];
                            totalRewardPool += challenge.stakeholderStakes[stakeholder];
                        }
                    }
                }
            }
            // Clear stakeholder stakes after distribution for this challenge
            // This is implicitly handled by not allowing withdrawal of already distributed stakes.
            // And challenge.stakeholderStakes will remain with records of previous stakes.
        }

        snippet.isChallenged = false; // Challenge resolved
        snippet.currentChallengeId = 0;

        emit ChallengeResolved(_challengeId, challenge.snippetId, challenge.status, winningSide, totalStake);
    }

    /* ================================== */
    /* IX. Governance & DAO (Simplified) (Functions 16-18) */
    /* ================================== */

    /**
     * @dev 16. proposeParameterChange: Allows users with sufficient reputation to propose changes to governance parameters.
     * @param _paramName Bytes32 hash of the parameter name (e.g., keccak256("MIN_STAKE_FOR_CHALLENGE")).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) external {
        UserProfile storage senderProfile = userProfiles[msg.sender];
        // Example: require 100 reputation to propose
        if (senderProfile.reputationScore < 100) revert InsufficientReputation(100, senderProfile.reputationScore);

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            paramName: _paramName,
            newValue: _newValue,
            proposerReputationAtProposing: senderProfile.reputationScore, // Snapshot for quorum calculation
            submissionTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false,
            hasVoted: new mapping(address => bool)
        });

        emit GovernanceProposalCreated(newProposalId, _paramName, _newValue, msg.sender);
    }

    /**
     * @dev 17. voteOnProposal: Allows users to vote on an active governance proposal.
     *      Voting power could be based on reputation, staked tokens, or a combination.
     *      For simplicity, it's 1 vote per unique user.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True to vote "Yes", False to vote "No".
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);
        if (block.timestamp >= proposal.votingPeriodEnd) revert VotingPeriodEnded(_proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);

        // Voting power could be weighted by reputation. For simplicity, 1 address = 1 vote.
        // Or: (userProfiles[msg.sender].reputationScore / 100) as vote weight.
        if (_for) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _for);
    }

    /**
     * @dev 18. executeProposal: Executes a governance proposal if it has passed its voting period,
     *      met quorum, and achieved a majority.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);
        if (block.timestamp < proposal.votingPeriodEnd) revert VotingPeriodNotEnded(_proposalId);

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        // Quorum check: A simplified quorum, e.g., total votes must be X% of proposer's reputation at the time of proposal
        // or a fixed minimum number of voters. For a more robust DAO, this would involve total staked tokens or active voters.
        // Let's use a simple direct check: must have at least 5 votes, and > 51% yes.
        if (totalVotes < 5 || (proposal.yesVotes * 100 / totalVotes) < GOVERNANCE_QUORUM_PERCENT) {
            proposal.passed = false;
            proposal.executed = true;
            emit GovernanceProposalExecuted(_proposalId, false);
            revert ProposalFailedQuorumOrMajority(_proposalId);
        }

        // Proposal passed! Execute the parameter change.
        if (proposal.paramName == keccak256("MIN_REPUTATION_FOR_CONTRIBUTION")) {
            MIN_REPUTATION_FOR_CONTRIBUTION = proposal.newValue;
        } else if (proposal.paramName == keccak256("MIN_REPUTATION_FOR_CHALLENGE")) {
            MIN_REPUTATION_FOR_CHALLENGE = proposal.newValue;
        } else if (proposal.paramName == keccak256("MIN_STAKE_FOR_CHALLENGE")) {
            MIN_STAKE_FOR_CHALLENGE = proposal.newValue;
        } else if (proposal.paramName == keccak256("CHALLENGE_VOTING_PERIOD")) {
            CHALLENGE_VOTING_PERIOD = proposal.newValue;
        } else if (proposal.paramName == keccak256("GOVERNANCE_VOTING_PERIOD")) {
            GOVERNANCE_VOTING_PERIOD = proposal.newValue;
        } else if (proposal.paramName == keccak256("GOVERNANCE_QUORUM_PERCENT")) {
            GOVERNANCE_QUORUM_PERCENT = proposal.newValue;
        } else if (proposal.paramName == keccak256("REPUTATION_GAIN_CONTRIBUTION")) {
            REPUTATION_GAIN_CONTRIBUTION = proposal.newValue;
        } else if (proposal.paramName == keccak256("REPUTATION_GAIN_CHALLENGE_WIN")) {
            REPUTATION_GAIN_CHALLENGE_WIN = proposal.newValue;
        } else if (proposal.paramName == keccak256("REPUTATION_LOSS_CHALLENGE_LOSE")) {
            REPUTATION_LOSS_CHALLENGE_LOSE = proposal.newValue;
        } else if (proposal.paramName == keccak256("REPUTATION_GAIN_CURATION")) {
            REPUTATION_GAIN_CURATION = proposal.newValue;
        } else if (proposal.paramName == keccak256("RELEVANCE_DECAY_RATE_PER_DAY")) {
            RELEVANCE_DECAY_RATE_PER_DAY = proposal.newValue;
        } else if (proposal.paramName == keccak256("QUALITY_SCORE_CHANGE_CURATION")) {
            QUALITY_SCORE_CHANGE_CURATION = proposal.newValue;
        } else if (proposal.paramName == keccak256("EXPERTISE_BADGE_THRESHOLD")) {
            EXPERTISE_BADGE_THRESHOLD = proposal.newValue;
        } else {
            // Unrecognized parameter, perhaps for future extensions.
            // Could revert or log an event.
        }

        proposal.passed = true;
        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId, true);
    }

    /* ================================== */
    /* X. Token & Rewards (Functions 19-20) */
    /* ================================== */

    /**
     * @dev 19. claimRewards: Allows users to claim accumulated DKA tokens from contributions,
     *      successful challenges, or curation.
     */
    function claimRewards() external {
        uint256 amount = userRewardBalances[msg.sender];
        if (amount == 0) revert NoRewardsToClaim(msg.sender);

        userRewardBalances[msg.sender] = 0; // Reset balance before transfer
        if (!DKAToken.transfer(msg.sender, amount)) {
            revert("DKA: Reward transfer failed");
        }
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev 20. withdrawStakedTokens: Allows users to withdraw their tokens after a challenge they
     *      participated in has been resolved and their stake has been determined as winning or tied.
     *      (Note: This function works in conjunction with `resolveChallenge`'s internal handling
     *      of adding tokens to `userRewardBalances` for winners/ties.)
     *      This is essentially a call to `claimRewards` after `resolveChallenge` adds the stake to rewards.
     */
    function withdrawStakedTokens(uint256 _challengeId) external {
        // This function would primarily be for any stake that wasn't immediately distributed
        // or for failed challenges where stakes are returned if the system allows.
        // Given `resolveChallenge` puts winning stakes into `userRewardBalances`,
        // this function is effectively redundant if 'claimRewards' is used.
        // However, a distinct `withdrawStakedTokens` could be used if stakes were held
        // separately from general rewards.
        // For current setup, it directs to claimRewards.

        // If specific stakes for _challengeId are needed to be withdrawn independently,
        // the `KnowledgeChallenge` struct would need a mapping `stakeholderStakes[address][challengeId] => amount`.
        // To simplify and avoid duplicate stake management, stakes are routed to `userRewardBalances`
        // upon challenge resolution for winners, and forfeited for losers.
        // Thus, this function becomes synonymous with claiming general rewards.
        claimRewards();
        // If a direct withdrawal of specific stakes was needed (e.g., if tie meant direct return):
        // uint256 amount = knowledgeChallenges[_challengeId].stakeholderStakes[msg.sender];
        // if (amount == 0) revert NoStakedTokensToWithdraw(msg.sender);
        // knowledgeChallenges[_challengeId].stakeholderStakes[msg.sender] = 0;
        // DKAToken.transfer(msg.sender, amount);
        // emit TokensWithdrawn(msg.sender, amount);
    }

    /* ================================== */
    /* XI. Advanced & Oracle Integrations (Functions 21-25) */
    /* ================================== */

    /**
     * @dev 21. setModeratorOracleAddress: Sets the address of an trusted off-chain AI/human moderation oracle.
     *      Only callable by governance (owner for now, but could be through proposals).
     * @param _newOracle The address of the new moderator oracle.
     */
    function setModeratorOracleAddress(address _newOracle) external onlyOwner {
        address oldOracle = moderatorOracleAddress;
        moderatorOracleAddress = _newOracle;
        emit ModeratorOracleSet(oldOracle, _newOracle);
    }

    /**
     * @dev 22. attestSnippetValidity: An authorized oracle can provide an official attestation of a snippet's validity.
     *      This can significantly boost its quality score and prevent challenges.
     * @param _snippetId The ID of the snippet to attest.
     * @param _isValid True if the oracle attests validity, false if invalid (leading to deprecation).
     * @param _oracleProofIpfsHash IPFS hash linking to the oracle's proof or analysis.
     */
    function attestSnippetValidity(uint256 _snippetId, bool _isValid, string memory _oracleProofIpfsHash) external onlyModeratorOracle {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        if (snippet.id == 0) revert InvalidSnippetId(_snippetId);
        if (snippet.isDeprecated) revert SnippetAlreadyDeprecated(_snippetId);
        if (snippet.hasOracleAttestation) revert AlreadyAttested(_snippetId);

        snippet.hasOracleAttestation = true;

        if (_isValid) {
            snippet.currentQualityScore += 100; // Significant boost
            snippet.relevanceScore += 50;
            snippet.lastReaffirmationTimestamp = block.timestamp; // Reaffirm relevance
            emit SnippetQualityScoreUpdated(_snippetId, snippet.currentQualityScore, msg.sender);
            emit SnippetRelevanceUpdated(_snippetId, snippet.relevanceScore);
            _updateReputation(snippet.contributor, REPUTATION_GAIN_CONTRIBUTION * 5); // Reward contributor for valid snippet
        } else {
            // Oracle attests it's invalid
            snippet.isDeprecated = true;
            snippet.currentQualityScore -= 100; // Significant penalty
            _updateReputation(snippet.contributor, int256(REPUTATION_LOSS_CHALLENGE_LOSE * -2)); // Penalize contributor
            emit KnowledgeSnippetDeprecated(_snippetId, msg.sender, block.timestamp);
            emit SnippetQualityScoreUpdated(_snippetId, snippet.currentQualityScore, msg.sender);
        }

        emit SnippetAttestedByOracle(_snippetId, msg.sender, _isValid, _oracleProofIpfsHash);
    }

    /**
     * @dev 23. updateMinimumReputationForAction: Governance function to dynamically adjust reputation
     *      requirements for certain actions without going through a full proposal cycle.
     *      This is a more direct governance function, suitable for rapid adjustments by a trusted body (owner/DAO).
     *      For this example, it's owner-only, but could be generalized via the proposal system itself.
     * @param _actionIdentifier A bytes32 hash representing the action (e.g., keccak256("CONTRIBUTION")).
     * @param _minReputation The new minimum reputation score required for that action.
     */
    function updateMinimumReputationForAction(bytes32 _actionIdentifier, uint256 _minReputation) external onlyOwner {
        if (_actionIdentifier == keccak256("CONTRIBUTION")) {
            MIN_REPUTATION_FOR_CONTRIBUTION = _minReputation;
        } else if (_actionIdentifier == keccak256("CHALLENGE")) {
            MIN_REPUTATION_FOR_CHALLENGE = _minReputation;
        }
        // Add more actions as needed
        emit GovernanceProposalExecuted(0, true); // Use a dummy ID or specific event for this type of update
    }

    /**
     * @dev 24. getPendingChallenges: Returns a list of all currently active challenges awaiting resolution.
     *      This could be computationally expensive if there are many challenges.
     *      For practical use, this would likely be a paginated view.
     * @return An array of active challenge IDs.
     */
    function getPendingChallenges() public view returns (uint256[] memory) {
        uint256[] memory pendingIds = new uint256[](_challengeIds.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            if (knowledgeChallenges[i].status == ChallengeStatus.Pending && block.timestamp >= knowledgeChallenges[i].votingPeriodEnd) {
                pendingIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pendingIds[i];
        }
        return result;
    }

    /**
     * @dev 25. getSnippetsByCategory: Provides a paginated list of knowledge snippets filtered by a specific category.
     * @param _category The bytes32 hash of the category.
     * @param _offset The starting index for pagination.
     * @param _limit The maximum number of snippets to return.
     * @return An array of snippet IDs belonging to the category within the specified range.
     */
    function getSnippetsByCategory(bytes32 _category, uint256 _offset, uint256 _limit) public view returns (uint256[] memory) {
        uint256[] storage snippetIds = categoryToSnippets[_category];
        uint256 total = snippetIds.length;
        if (_offset >= total) {
            return new uint256[](0);
        }
        uint256 endIndex = _offset + _limit;
        if (endIndex > total) {
            endIndex = total;
        }
        uint256 resultSize = endIndex - _offset;
        uint256[] memory result = new uint256[](resultSize);
        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = snippetIds[_offset + i];
        }
        return result;
    }

    /* ================================== */
    /* XII. Internal Helper Functions & Views */
    /* ================================== */

    /**
     * @dev _updateReputation: Internal function to adjust a user's reputation score.
     * @param _user The address of the user.
     * @param _amount The amount to add (positive) or subtract (negative) from reputation.
     */
    function _updateReputation(address _user, int256 _amount) internal {
        UserProfile storage profile = userProfiles[_user];
        if (_amount > 0) {
            profile.reputationScore += uint256(_amount);
        } else {
            uint256 absAmount = uint256(_amount * -1);
            if (profile.reputationScore > absAmount) {
                profile.reputationScore -= absAmount;
            } else {
                profile.reputationScore = 0; // Reputation cannot go below zero
            }
        }
        emit UserReputationUpdated(_user, profile.reputationScore);
    }

    /**
     * @dev _updateDomainExpertise: Internal function to adjust a user's expertise score for a category.
     * @param _user The address of the user.
     * @param _category The bytes32 hash of the category.
     * @param _amount The amount to add to expertise score.
     */
    function _updateDomainExpertise(address _user, bytes32 _category, uint256 _amount) internal {
        UserProfile storage profile = userProfiles[_user];
        profile.domainExpertise[_category] += _amount;
        emit DomainExpertiseUpdated(_user, _category, profile.domainExpertise[_category]);
    }

    /**
     * @dev _updateDomainExpertiseForSnippet: Helper to update expertise for all categories associated with a snippet.
     * @param _user The address of the user.
     * @param _snippetId The ID of the snippet.
     * @param _amount The amount to add to expertise score for each category.
     */
    function _updateDomainExpertiseForSnippet(address _user, uint256 _snippetId, uint256 _amount) internal {
        KnowledgeSnippet storage snippet = knowledgeSnippets[_snippetId];
        for (uint256 i = 0; i < snippet.categoryTags.length; i++) {
            _updateDomainExpertise(_user, snippet.categoryTags[i], _amount);
        }
    }

    // Fallback function to receive Ether (e.g., for gas costs, or if DKA token is based on Ether)
    receive() external payable { }
}
```