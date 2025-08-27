The `AetherForgeProtocol` is a decentralized, AI-augmented knowledge collective where users contribute, mutate, and combine insights. User reputation, a non-transferable score (Soulbound Token-like), is dynamically adjusted by AI assessment of contributions and governs protocol parameters. Rewards are tied to reputation and active participation.

This contract introduces the concept of "Knowledge Forging," allowing users to build upon existing insights through mutation and combination, with AI evaluating the novelty and utility of these new creations. Reputation-weighted governance enables the community to adapt protocol parameters, and a unique `signalAIParamPreference` function provides decentralized input for potential AI-driven dynamic adjustments.

### Outline & Function Summary:

**Core Concept:**
AetherForgeProtocol empowers a community to collectively build a knowledge base. Users contribute "insights" (e.g., research findings, creative ideas, data interpretations) as content hashes. These insights are dynamically assessed by a trusted AI oracle for quality, originality, and impact. Based on these assessments, users earn a non-transferable "Reputation Score," which grants them influence in governance and determines their share of protocol rewards. The protocol features unique "Knowledge Forging" mechanisms where insights can be mutated or combined, and the AI evaluates the novelty and utility of these new creations.

---

**I. Core Data Structures & State Management (Internal logic):**
*   `Insight`: Represents a piece of knowledge/data, including content, author, AI score, and lineage.
*   `UserReputation`: Tracks a user's non-transferable influence and standing.
*   `Proposal`: Stores details for governance votes.
*   `ProtocolParameters`: Govern the protocol's behavior (e.g., fees, reward rates).

---

**II. Insight Management & Creation (6 functions):**

1.  `submitInsight(string _contentHash)`: Allows users to submit a new, original knowledge insight. Triggers AI assessment.
2.  `mutateInsight(uint256 _parentId, string _newContentHash)`: Enables users to derive a new insight by modifying an existing one. Triggers AI assessment.
3.  `combineInsights(uint256[] _parentIds, string _newContentHash)`: Facilitates users in synthesizing new knowledge by combining multiple existing insights. Triggers AI assessment.
4.  `endorseInsight(uint256 _insightId)`: Allows users to signal approval for an insight, providing social proof and potentially influencing AI re-assessment or future rewards.
5.  `retractInsight(uint256 _insightId, string _reasonHash)`: Enables an author to retract their own insight, with potential reputation consequences if widely endorsed previously.
6.  `challengeInsight(uint256 _insightId, string _reasonHash)`: Allows users to formally challenge an insight's validity, originality, or quality, potentially triggering a re-assessment by the AI or governance review.

---

**III. AI Oracle & Assessment (3 functions):**

7.  `setAIOracleAddress(address _newOracle)`: Owner/Governance sets the trusted AI oracle contract address responsible for assessments.
8.  `requestAIAssessment(uint256 _insightId, string _contentHash, bool _isMutation, uint256[] _parentInsights)`: (Internal) Initiates an AI assessment request to the configured oracle, passing all necessary context.
9.  `callbackAIAssessment(uint256 _insightId, int256 _aiScore, bool _isOriginal, bool _isSpam, string _aiReasonHash)`: (External, callable only by oracle) Receives and processes the AI's assessment results, updating the insight's score and the author's reputation.

---

**IV. Reputation & Rewards (4 functions):**

10. `getUserReputation(address _user)`: Retrieves a user's current non-transferable reputation score.
11. `claimRewards()`: Allows users to claim accumulated rewards based on their current reputation and the value/impact of their contributions.
12. `updateReputationDecay(address _user)`: (Internal/Scheduled) Applies a decay factor to inactive users' reputation scores to encourage continuous participation.
13. `distributeCommunityPool(address[] _recipients, uint256[] _amounts, string _reasonHash)`: Governance-controlled function to distribute funds from a dedicated community pool for specific initiatives or high-impact contributors.

---

**V. Decentralized Governance & Adaptive Parameters (7 functions):**

14. `proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string _descriptionHash)`: High-reputation users can propose changes to core protocol parameters (e.g., `aiAssessmentFee`, `rewardRate`).
15. `voteOnProposal(uint256 _proposalId, bool _support)`: Users vote on active proposals, with their vote weight determined by their current reputation score.
16. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal, applying the proposed parameter change to the protocol.
17. `getProtocolParameter(bytes32 _paramKey)`: Retrieves the current value of a specified protocol parameter.
18. `signalAIParamPreference(bytes32 _paramKey, int256 _adjustmentWeight)`: Users can "signal" to the AI oracle their preference for how a specific parameter should adapt, providing decentralized input for potential AI-driven adjustments.
19. `freezeProtocolFunctionality(bool _freeze)`: Emergency function, callable by highly-reputable governance, to temporarily halt critical protocol functions in case of severe vulnerabilities or market instability.
20. `setRewardDistributionStrategy(address _newStrategyContract)`: Governance can upgrade or change the contract defining how rewards are calculated and distributed, allowing for dynamic and evolving reward models without modifying the core logic.

---

**VI. Read-Only / Utility (3 functions):**

21. `getInsightDetails(uint256 _insightId)`: Returns comprehensive details for a given insight, including its content hash, author, score, and parent insights.
22. `getLatestInsights(uint256 _count, uint256 _startIndex)`: Fetches a paginated list of the most recently submitted insights, useful for UI display.
23. `getProposals(bool _activeOnly)`: Lists all active or all historical governance proposals with their current status and voting results.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For reward token if applicable

/**
 * @title AetherForgeProtocol
 * @dev A decentralized, AI-augmented knowledge collective where users contribute, mutate, and combine insights.
 * User reputation, a non-transferable score (SBT-like), is dynamically adjusted by AI assessment of contributions
 * and governs protocol parameters. Rewards are tied to reputation and active participation.
 *
 * Outline & Function Summary:
 *
 * Core Concept:
 * AetherForgeProtocol empowers a community to collectively build a knowledge base. Users contribute "insights"
 * (e.g., research findings, creative ideas, data interpretations) as content hashes. These insights are
 * dynamically assessed by a trusted AI oracle for quality, originality, and impact. Based on these assessments,
 * users earn a non-transferable "Reputation Score," which grants them influence in governance and determines their
 * share of protocol rewards. The protocol features unique "Knowledge Forging" mechanisms where insights can be
 * mutated or combined, and the AI evaluates the novelty and utility of these new creations.
 *
 * I. Core Data Structures & State Management (Internal logic):
 *    - Insight: Represents a piece of knowledge/data, including content, author, AI score, and lineage.
 *    - UserReputation: Tracks a user's non-transferable influence and standing.
 *    - Proposal: Stores details for governance votes on protocol parameters.
 *    - ProtocolParameters: Govern the protocol's behavior (e.g., fees, reward rates).
 *
 * II. Insight Management & Creation (6 functions):
 *    1. submitInsight(string _contentHash): Allows users to submit a new, original knowledge insight. Triggers AI assessment.
 *    2. mutateInsight(uint256 _parentId, string _newContentHash): Enables users to derive a new insight by modifying an existing one. Triggers AI assessment.
 *    3. combineInsights(uint256[] _parentIds, string _newContentHash): Facilitates users in synthesizing new knowledge by combining multiple existing insights. Triggers AI assessment.
 *    4. endorseInsight(uint256 _insightId): Allows users to signal approval for an insight, providing social proof and potentially influencing AI re-assessment or future rewards.
 *    5. retractInsight(uint256 _insightId, string _reasonHash): Enables an author to retract their own insight, with potential reputation consequences if widely endorsed previously.
 *    6. challengeInsight(uint256 _insightId, string _reasonHash): Allows users to formally challenge an insight's validity, originality, or quality, potentially triggering a re-assessment by the AI or governance review.
 *
 * III. AI Oracle & Assessment (3 functions):
 *    7. setAIOracleAddress(address _newOracle): Owner/Governance sets the trusted AI oracle contract address responsible for assessments.
 *    8. requestAIAssessment(uint256 _insightId, string _contentHash, bool _isMutation, uint256[] _parentInsights): (Internal) Initiates an AI assessment request to the configured oracle, passing all necessary context.
 *    9. callbackAIAssessment(uint256 _insightId, int256 _aiScore, bool _isOriginal, bool _isSpam, string _aiReasonHash): (External, callable only by oracle) Receives and processes the AI's assessment results, updating the insight's score and the author's reputation.
 *
 * IV. Reputation & Rewards (4 functions):
 *    10. getUserReputation(address _user): Retrieves a user's current non-transferable reputation score.
 *    11. claimRewards(): Allows users to claim accumulated rewards based on their current reputation and the value/impact of their contributions.
 *    12. updateReputationDecay(address _user): (Internal/Scheduled) Applies a decay factor to inactive users' reputation scores to encourage continuous participation.
 *    13. distributeCommunityPool(address[] _recipients, uint256[] _amounts, string _reasonHash): Governance-controlled function to distribute funds from a dedicated community pool for specific initiatives or high-impact contributors.
 *
 * V. Decentralized Governance & Adaptive Parameters (7 functions):
 *    14. proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string _descriptionHash): High-reputation users can propose changes to core protocol parameters (e.g., `aiAssessmentFee`, `rewardRate`).
 *    15. voteOnProposal(uint256 _proposalId, bool _support): Users vote on active proposals, with their vote weight determined by their current reputation score.
 *    16. executeProposal(uint256 _proposalId): Executes a successfully voted-on proposal, applying the proposed parameter change to the protocol.
 *    17. getProtocolParameter(bytes32 _paramKey): Retrieves the current value of a specified protocol parameter.
 *    18. signalAIParamPreference(bytes32 _paramKey, int256 _adjustmentWeight): Users can "signal" to the AI oracle their preference for how a specific parameter should adapt, providing decentralized input for potential AI-driven adjustments.
 *    19. freezeProtocolFunctionality(bool _freeze): Emergency function, callable by highly-reputable governance, to temporarily halt critical protocol functions in case of severe vulnerabilities or market instability.
 *    20. setRewardDistributionStrategy(address _newStrategyContract): Governance can upgrade or change the contract defining how rewards are calculated and distributed, allowing for dynamic and evolving reward models without modifying the core logic.
 *
 * VI. Read-Only / Utility (3 functions):
 *    21. getInsightDetails(uint256 _insightId): Returns comprehensive details for a given insight, including its content hash, author, score, and parent insights.
 *    22. getLatestInsights(uint256 _count, uint256 _startIndex): Fetches a paginated list of the most recently submitted insights, useful for UI display.
 *    23. getProposals(bool _activeOnly): Lists all active or all historical governance proposals with their current status and voting results.
 */
contract AetherForgeProtocol is Ownable, ReentrancyGuard {

    // --- Custom Errors ---
    error InvalidAIOracle();
    error Unauthorized();
    error InsightNotFound();
    error AlreadyEndorsed();
    error AlreadyChallenged();
    error NotAllowed(); // General unauthorized/invalid action
    error NotAuthor();
    error AlreadyRetracted();
    error SelfChallenge();
    error InsufficientReputation(uint256 required, uint256 current);
    error ProposalNotFound();
    error ProposalAlreadyVoted();
    error ProposalNotExecutable(string reason);
    error InvalidParameterKey();
    error InvalidParentInsight();
    error MaxParentInsightsExceeded(uint256 maxParents);
    error InvalidReputationAddress();
    error RewardsNotClaimable();
    error InsufficientBalance();
    error FreezeToggleNotAllowed();
    error TooManyInsightsInPeriod();
    error MaxInsightContentLengthExceeded(uint256 maxLength);

    // --- Structures ---

    struct Insight {
        string contentHash;        // IPFS/Arweave hash of the insight content
        address author;            // Creator of the insight
        uint256 submissionTime;    // Timestamp of submission
        int256 aiScore;            // AI's assessment score (can be negative for poor quality)
        bool isOriginal;           // Flag from AI if it's considered original
        bool isSpam;               // Flag from AI if it's considered spam/malicious
        uint256[] parentInsights;  // IDs of insights this one mutated/combined from
        uint256 mutationCount;     // How many times this insight has been used as a parent
        uint256 endorsementCount;  // Number of unique users who endorsed this insight
        uint256 challengeCount;    // Number of unique users who challenged this insight
        bool isActive;             // False if retracted or removed by governance/AI
        string aiReasonHash;       // IPFS/Arweave hash of AI's reasoning for score
    }

    struct UserReputation {
        uint256 score;             // Non-transferable reputation score
        uint256 lastActivityTime;  // Last time user made a significant interaction
        uint256 claimedRewards;    // Total rewards claimed by this user
        uint256 insightsSubmitted; // Total insights submitted (including mutations/combinations)
        uint256 lastSubmissionTime; // Timestamp of last insight submission
    }

    struct Proposal {
        bytes32 paramKey;          // Key of the protocol parameter to change
        uint256 newValue;          // The proposed new value
        string descriptionHash;    // IPFS/Arweave hash of proposal description
        uint256 creationTime;      // Timestamp of proposal creation
        uint256 votingEndTime;     // Timestamp when voting ends
        uint256 totalVotesFor;     // Sum of reputation scores of 'for' voters
        uint256 totalVotesAgainst; // Sum of reputation scores of 'against' voters
        address proposer;          // Address of the proposer
        bool executed;             // True if the proposal has been executed
        mapping(address => bool) hasVoted; // Tracks if a user has voted
    }

    // --- State Variables ---

    address public aiOracle;                     // Address of the trusted AI oracle contract
    uint256 public nextInsightId;                // Counter for insights
    uint256 public nextProposalId;               // Counter for proposals
    bool public protocolFrozen;                  // Global switch to freeze critical functionality

    mapping(uint256 => Insight) public insights;
    mapping(address => UserReputation) public userReputations;
    mapping(uint256 => Proposal) public proposals;

    // Protocol parameters (bytes32 key to uint256 value)
    mapping(bytes32 => uint256) public protocolParameters;

    // Track user endorsements for insights to prevent double endorsement
    mapping(uint256 => mapping(address => bool)) public hasEndorsedInsight;
    // Track user challenges for insights to prevent double challenge
    mapping(uint256 => mapping(address => bool)) public hasChallengedInsight;

    // Interface for AI Oracle to call back
    interface IAIOracle {
        function assessInsight(uint256 _insightId, string calldata _contentHash, bool _isMutation, uint256[] calldata _parentInsights) external;
    }

    // Interface for reward distribution strategy
    IERC20 public rewardToken; // ERC20 token used for rewards
    address public rewardDistributionStrategy; // Contract that dictates reward calculations

    // --- Events ---
    event InsightSubmitted(uint256 indexed insightId, address indexed author, string contentHash, uint256 submissionTime);
    event InsightMutated(uint256 indexed insightId, address indexed author, string newContentHash, uint256 indexed parentId);
    event InsightCombined(uint256 indexed insightId, address indexed author, string newContentHash, uint256[] parentIds);
    event InsightEndorsed(uint256 indexed insightId, address indexed endorser);
    event InsightRetracted(uint256 indexed insightId, address indexed author, string reasonHash);
    event InsightChallenged(uint256 indexed insightId, address indexed challenger, string reasonHash);
    event AIAssessmentRequested(uint256 indexed insightId, string contentHash);
    event AIAssessmentCompleted(uint256 indexed insightId, int256 aiScore, bool isOriginal, bool isSpam, string aiReasonHash);
    event ReputationUpdated(address indexed user, uint256 newScore, uint256 oldScore);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event AIOracleSet(address indexed oldOracle, address indexed newOracle);
    event ProtocolFrozenStatusChanged(bool indexed isFrozen);
    event CommunityPoolDistributed(address indexed distributor, address[] recipients, uint256[] amounts, string reasonHash);
    event RewardDistributionStrategySet(address indexed oldStrategy, address indexed newStrategy);
    event AIParamPreferenceSignaled(bytes32 indexed paramKey, address indexed signaler, int256 adjustmentWeight);


    // --- Constructor ---
    constructor(address _aiOracle, address _rewardToken, address _rewardStrategy) Ownable(msg.sender) {
        if (_aiOracle == address(0)) revert InvalidAIOracle();
        if (_rewardToken == address(0) || _rewardStrategy == address(0)) revert InvalidParameterKey(); // Using a generic error, could create a specific one

        aiOracle = _aiOracle;
        rewardToken = IERC20(_rewardToken);
        rewardDistributionStrategy = _rewardStrategy;

        // Initialize default protocol parameters
        protocolParameters["minReputationToPropose"] = 1000;
        protocolParameters["minReputationToVote"] = 100;
        protocolParameters["proposalVotingPeriod"] = 7 days;
        protocolParameters["proposalMinQuorum"] = 5000; // Minimum total reputation for proposal to pass
        protocolParameters["aiAssessmentFee"] = 0; // Can be set later if oracle charges fees
        protocolParameters["rewardRatePerReputation"] = 1000; // Example: 1000 * 1e18 per 1 reputation unit
        protocolParameters["maxParentInsights"] = 5;
        protocolParameters["minReputationForMutation"] = 200;
        protocolParameters["maxInsightsPerUserPerPeriod"] = 5;
        protocolParameters["insightSubmissionPeriod"] = 1 days;
        protocolParameters["maxContentHashLength"] = 64; // Example for IPFS CID v0/v1
        protocolParameters["baseReputationIncreaseOnOriginal"] = 100;
        protocolParameters["baseReputationIncreaseOnMutation"] = 50;
        protocolParameters["reputationDecayRate"] = 1; // Example: 1% per update interval
        protocolParameters["reputationDecayPeriod"] = 30 days; // Decay every 30 days
        protocolParameters["minReputationToChallenge"] = 50;
        protocolParameters["challengeFee"] = 0; // Example: 1000 * 1e18 if we want to charge for challenge
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracle) revert Unauthorized();
        _;
    }

    modifier onlyReputable(uint256 _requiredReputation) {
        if (userReputations[msg.sender].score < _requiredReputation) {
            revert InsufficientReputation(_requiredReputation, userReputations[msg.sender].score);
        }
        _;
    }

    modifier notFrozen() {
        if (protocolFrozen) revert FreezeToggleNotAllowed();
        _;
    }

    // --- Internal Helpers ---
    function _updateUserActivity(address _user) internal {
        userReputations[_user].lastActivityTime = block.timestamp;
    }

    function _updateUserReputation(address _user, int256 _change) internal {
        UserReputation storage userRep = userReputations[_user];
        uint256 oldScore = userRep.score;
        
        if (_change < 0) {
            userRep.score = userRep.score > uint256(-_change) ? userRep.score - uint256(-_change) : 0;
        } else {
            userRep.score += uint256(_change);
        }
        emit ReputationUpdated(_user, userRep.score, oldScore);
        _updateUserActivity(_user);
    }

    function _incrementInsightCount(address _user) internal {
        userReputations[_user].insightsSubmitted++;
        userReputations[_user].lastSubmissionTime = block.timestamp;
    }

    function _checkContentHashLength(string memory _hash) internal view {
        if (bytes(_hash).length > protocolParameters["maxContentHashLength"]) {
            revert MaxInsightContentLengthExceeded(protocolParameters["maxContentHashLength"]);
        }
    }

    function _checkInsightSubmissionLimit(address _user) internal view {
        if (userReputations[_user].insightsSubmitted > 0 &&
            block.timestamp - userReputations[_user].lastSubmissionTime < protocolParameters["insightSubmissionPeriod"] &&
            userReputations[_user].insightsSubmitted % protocolParameters["maxInsightsPerUserPerPeriod"] == 0) {
            revert TooManyInsightsInPeriod();
        }
    }

    // --- II. Insight Management & Creation ---

    /**
     * @dev Allows users to submit a new, original knowledge insight.
     *      Triggers AI assessment via oracle.
     * @param _contentHash IPFS/Arweave hash of the insight content.
     */
    function submitInsight(string calldata _contentHash) external notFrozen nonReentrant {
        _checkContentHashLength(_contentHash);
        _checkInsightSubmissionLimit(msg.sender);

        uint256 insightId = nextInsightId++;
        insights[insightId] = Insight({
            contentHash: _contentHash,
            author: msg.sender,
            submissionTime: block.timestamp,
            aiScore: 0, // Will be updated by AI callback
            isOriginal: false,
            isSpam: false,
            parentInsights: new uint256[](0),
            mutationCount: 0,
            endorsementCount: 0,
            challengeCount: 0,
            isActive: true,
            aiReasonHash: ""
        });

        _incrementInsightCount(msg.sender);
        requestAIAssessment(insightId, _contentHash, false, new uint256[](0));
        emit InsightSubmitted(insightId, msg.sender, _contentHash, block.timestamp);
    }

    /**
     * @dev Enables users to derive a new insight by modifying an existing one.
     *      Requires a minimum reputation score. Triggers AI assessment.
     * @param _parentId The ID of the parent insight being mutated.
     * @param _newContentHash IPFS/Arweave hash of the new, mutated insight content.
     */
    function mutateInsight(uint256 _parentId, string calldata _newContentHash)
        external
        notFrozen
        nonReentrant
        onlyReputable(protocolParameters["minReputationForMutation"])
    {
        if (_parentId >= nextInsightId || !insights[_parentId].isActive) revert InvalidParentInsight();
        _checkContentHashLength(_newContentHash);
        _checkInsightSubmissionLimit(msg.sender);

        insights[_parentId].mutationCount++;

        uint256 insightId = nextInsightId++;
        uint256[] memory parentIds = new uint256[](1);
        parentIds[0] = _parentId;

        insights[insightId] = Insight({
            contentHash: _newContentHash,
            author: msg.sender,
            submissionTime: block.timestamp,
            aiScore: 0,
            isOriginal: false, // AI will determine if mutation is effectively original
            isSpam: false,
            parentInsights: parentIds,
            mutationCount: 0,
            endorsementCount: 0,
            challengeCount: 0,
            isActive: true,
            aiReasonHash: ""
        });
        
        _incrementInsightCount(msg.sender);
        requestAIAssessment(insightId, _newContentHash, true, parentIds);
        emit InsightMutated(insightId, msg.sender, _newContentHash, _parentId);
    }

    /**
     * @dev Facilitates users in synthesizing new knowledge by combining multiple existing insights.
     *      Requires a minimum reputation score. Triggers AI assessment.
     * @param _parentIds An array of IDs of parent insights being combined.
     * @param _newContentHash IPFS/Arweave hash of the new, combined insight content.
     */
    function combineInsights(uint256[] calldata _parentIds, string calldata _newContentHash)
        external
        notFrozen
        nonReentrant
        onlyReputable(protocolParameters["minReputationForMutation"]) // Same reputation as mutation
    {
        if (_parentIds.length == 0 || _parentIds.length > protocolParameters["maxParentInsights"]) {
            revert MaxParentInsightsExceeded(protocolParameters["maxParentInsights"]);
        }
        _checkContentHashLength(_newContentHash);
        _checkInsightSubmissionLimit(msg.sender);

        for (uint256 i = 0; i < _parentIds.length; i++) {
            if (_parentIds[i] >= nextInsightId || !insights[_parentIds[i]].isActive) revert InvalidParentInsight();
            insights[_parentIds[i]].mutationCount++; // Treat combination as a form of mutation
        }

        uint256 insightId = nextInsightId++;
        insights[insightId] = Insight({
            contentHash: _newContentHash,
            author: msg.sender,
            submissionTime: block.timestamp,
            aiScore: 0,
            isOriginal: false,
            isSpam: false,
            parentInsights: _parentIds, // Store all parent IDs
            mutationCount: 0,
            endorsementCount: 0,
            challengeCount: 0,
            isActive: true,
            aiReasonHash: ""
        });

        _incrementInsightCount(msg.sender);
        requestAIAssessment(insightId, _newContentHash, true, _parentIds);
        emit InsightCombined(insightId, msg.sender, _newContentHash, _parentIds);
    }

    /**
     * @dev Allows users to signal approval for an insight, providing social proof.
     *      Can give a small reputation boost to the endorser and influence AI re-assessment.
     * @param _insightId The ID of the insight to endorse.
     */
    function endorseInsight(uint256 _insightId) external notFrozen nonReentrant {
        if (_insightId >= nextInsightId || !insights[_insightId].isActive) revert InsightNotFound();
        if (hasEndorsedInsight[_insightId][msg.sender]) revert AlreadyEndorsed();
        if (insights[_insightId].author == msg.sender) revert NotAllowed(); // Cannot endorse your own insight.

        insights[_insightId].endorsementCount++;
        hasEndorsedInsight[_insightId][msg.sender] = true;
        
        // Small reputation boost for endorsing valuable content (optional, can be refined)
        _updateUserReputation(msg.sender, 5);
        emit InsightEndorsed(_insightId, msg.sender);
    }

    /**
     * @dev Enables an author to retract their own insight.
     *      May have reputation consequences if the insight was widely endorsed.
     * @param _insightId The ID of the insight to retract.
     * @param _reasonHash IPFS/Arweave hash of the reason for retraction.
     */
    function retractInsight(uint256 _insightId, string calldata _reasonHash) external notFrozen nonReentrant {
        Insight storage insight = insights[_insightId];
        if (_insightId >= nextInsightId || !insight.isActive) revert InsightNotFound();
        if (insight.author != msg.sender) revert NotAuthor();
        if (!insight.isActive) revert AlreadyRetracted(); // Already marked inactive

        insight.isActive = false;
        // Apply reputation penalty, e.g., if it had many endorsements
        if (insight.endorsementCount > 10) { // Example threshold
             _updateUserReputation(msg.sender, - (int256(insight.endorsementCount / 2)));
        }
        _updateUserActivity(msg.sender);
        emit InsightRetracted(_insightId, msg.sender, _reasonHash);
    }

    /**
     * @dev Allows users to formally challenge an insight's validity, originality, or quality.
     *      Requires a minimum reputation score.
     *      Potentially triggers a re-assessment by the AI or governance review.
     * @param _insightId The ID of the insight to challenge.
     * @param _reasonHash IPFS/Arweave hash of the reason for the challenge.
     */
    function challengeInsight(uint256 _insightId, string calldata _reasonHash)
        external
        notFrozen
        nonReentrant
        onlyReputable(protocolParameters["minReputationToChallenge"])
        payable
    {
        Insight storage insight = insights[_insightId];
        if (_insightId >= nextInsightId || !insight.isActive) revert InsightNotFound();
        if (insight.author == msg.sender) revert SelfChallenge();
        if (hasChallengedInsight[_insightId][msg.sender]) revert AlreadyChallenged();

        if (protocolParameters["challengeFee"] > 0 && msg.value < protocolParameters["challengeFee"]) {
            revert InsufficientBalance();
        }

        insights[_insightId].challengeCount++;
        hasChallengedInsight[_insightId][msg.sender] = true;

        // Optionally, if enough challenges from high-reputation users, trigger re-assessment or governance action
        // For simplicity, we just log it and potentially use it for future off-chain decision or another AI call.
        _updateUserActivity(msg.sender);
        emit InsightChallenged(_insightId, msg.sender, _reasonHash);
    }

    // --- III. AI Oracle & Assessment ---

    /**
     * @dev Sets the trusted AI oracle contract address. Only callable by owner initially, then by governance.
     * @param _newOracle The address of the new AI oracle contract.
     */
    function setAIOracleAddress(address _newOracle) public notFrozen {
        if (msg.sender != owner() && !(_isGovernor(msg.sender))) revert Unauthorized(); // Example: Can be owner or a governor role
        if (_newOracle == address(0)) revert InvalidAIOracle();
        emit AIOracleSet(aiOracle, _newOracle);
        aiOracle = _newOracle;
    }

    /**
     * @dev (Internal) Initiates an AI assessment request to the configured oracle.
     *      This function is called internally by `submitInsight`, `mutateInsight`, `combineInsights`.
     * @param _insightId The ID of the insight to assess.
     * @param _contentHash The content hash of the insight.
     * @param _isMutation True if this is a mutation/combination, false if original submission.
     * @param _parentInsights Array of parent insight IDs if applicable.
     */
    function requestAIAssessment(uint256 _insightId, string calldata _contentHash, bool _isMutation, uint256[] calldata _parentInsights)
        internal
    {
        // In a real scenario, this would likely involve Chainlink Functions, custom oracle networks, etc.
        // For this example, we directly call a mock oracle interface.
        // A real implementation would involve requesting a job ID and a callback.
        IAIOracle(aiOracle).assessInsight(_insightId, _contentHash, _isMutation, _parentInsights);
        emit AIAssessmentRequested(_insightId, _contentHash);
    }

    /**
     * @dev (External, callable only by oracle) Receives and processes the AI's assessment results.
     *      Updates the insight's score and the author's reputation.
     * @param _insightId The ID of the insight that was assessed.
     * @param _aiScore The AI's numerical score for the insight.
     * @param _isOriginal True if the AI deemed the insight original.
     * @param _isSpam True if the AI deemed the insight spam/malicious.
     * @param _aiReasonHash IPFS/Arweave hash of the AI's reasoning/report.
     */
    function callbackAIAssessment(uint256 _insightId, int256 _aiScore, bool _isOriginal, bool _isSpam, string calldata _aiReasonHash)
        external
        onlyAIOracle
        nonReentrant
    {
        if (_insightId >= nextInsightId) revert InsightNotFound();
        Insight storage insight = insights[_insightId];

        insight.aiScore = _aiScore;
        insight.isOriginal = _isOriginal;
        insight.isSpam = _isSpam;
        insight.aiReasonHash = _aiReasonHash;

        if (_isSpam) {
            insight.isActive = false; // Deactivate spam content
            _updateUserReputation(insight.author, - (int256(insight.endorsementCount * 10 + 100))); // Penalize author heavily for spam
        } else {
            // Adjust author's reputation based on AI score and originality
            int256 reputationChange = _aiScore;
            if (_isOriginal) {
                reputationChange += int256(protocolParameters["baseReputationIncreaseOnOriginal"]);
            } else if (insight.parentInsights.length > 0) { // It was a mutation/combination
                reputationChange += int256(protocolParameters["baseReputationIncreaseOnMutation"]);
            }
            _updateUserReputation(insight.author, reputationChange);
        }
        _updateUserActivity(insight.author); // Author is active due to assessment
        emit AIAssessmentCompleted(_insightId, _aiScore, _isOriginal, _isSpam, _aiReasonHash);
    }

    // --- IV. Reputation & Rewards ---

    /**
     * @dev Retrieves a user's current non-transferable reputation score.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        if (_user == address(0)) revert InvalidReputationAddress();
        return userReputations[_user].score;
    }

    /**
     * @dev Allows users to claim accumulated rewards based on their current reputation and the value/impact of their contributions.
     *      This function would interact with a separate `rewardDistributionStrategy` contract.
     *      Assumes rewards are in `rewardToken`.
     */
    function claimRewards() external notFrozen nonReentrant {
        // This is a placeholder. A real system would calculate rewards based on a complex formula:
        // - user's current reputation
        // - time since last claim
        // - AI scores of their insights
        // - total pool available
        // - etc.
        // This logic is abstracted into `rewardDistributionStrategy`.
        
        // Example simplified calculation for demonstration:
        // For this example, let's implement a very basic internal reward calculation as a direct call,
        // but emphasize that a real system would use the `rewardDistributionStrategy` interface.
        
        uint256 currentReputation = userReputations[msg.sender].score;
        uint256 lastClaimTime = userReputations[msg.sender].lastActivityTime; // Or a dedicated lastClaimTime
        
        // Simple example: Rewards based on reputation * time since last claim * rate
        // This is highly simplified and would need significant refinement for real-world use.
        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime;
        // Using 1e18 for scaling to match ERC20 decimals, assuming rewardRatePerReputation is also scaled.
        uint256 rewardsAvailable = (currentReputation * timeSinceLastClaim * protocolParameters["rewardRatePerReputation"]) / (1 days * 1e18); 

        if (rewardsAvailable == 0) revert RewardsNotClaimable();

        // Ensure contract has enough reward tokens
        if (rewardToken.balanceOf(address(this)) < rewardsAvailable) revert InsufficientBalance();

        userReputations[msg.sender].claimedRewards += rewardsAvailable;
        _updateUserActivity(msg.sender); // Mark user active after claiming
        
        // Transfer rewards
        bool success = rewardToken.transfer(msg.sender, rewardsAvailable);
        if (!success) revert RewardsNotClaimable(); // Or specific transfer error

        emit RewardsClaimed(msg.sender, rewardsAvailable);
    }

    /**
     * @dev (Internal/Scheduled) Applies a decay factor to inactive users' reputation scores.
     *      This function could be called by a dedicated keeper bot or integrated into user interactions.
     *      For simplicity, it's public here but intended for automated/periodic calls.
     * @param _user The address of the user whose reputation to decay.
     */
    function updateReputationDecay(address _user) public notFrozen { // Public for demonstration, real would be automated
        UserReputation storage userRep = userReputations[_user];
        if (userRep.score == 0) return;

        uint256 lastActivity = userRep.lastActivityTime;
        uint256 decayPeriod = protocolParameters["reputationDecayPeriod"];

        if (block.timestamp - lastActivity > decayPeriod) {
            uint256 periodsInactive = (block.timestamp - lastActivity) / decayPeriod;
            uint256 decayRate = protocolParameters["reputationDecayRate"]; // e.g., 1 for 1%
            uint256 currentScore = userRep.score;
            
            // Apply decay for each inactive period
            for (uint256 i = 0; i < periodsInactive; i++) {
                currentScore = currentScore - (currentScore * decayRate / 100); // Reduce by decayRate percentage
            }
            if (currentScore < userRep.score) { // Only update if decay actually happened
                uint256 oldScore = userRep.score;
                userRep.score = currentScore;
                emit ReputationUpdated(_user, userRep.score, oldScore);
            }
            userRep.lastActivityTime = block.timestamp; // Reset activity to prevent rapid re-decay
        }
    }

    /**
     * @dev Governance-controlled function to distribute funds from a dedicated community pool.
     *      Requires a high-reputation governance role.
     * @param _recipients An array of addresses to receive funds.
     * @param _amounts An array of corresponding amounts for each recipient.
     * @param _reasonHash IPFS/Arweave hash of the reason for distribution.
     */
    function distributeCommunityPool(address[] calldata _recipients, uint256[] calldata _amounts, string calldata _reasonHash)
        external
        notFrozen
        nonReentrant
        onlyReputable(protocolParameters["minReputationToPropose"] * 2) // Higher reputation for direct distribution
    {
        if (_recipients.length != _amounts.length || _recipients.length == 0) revert InvalidParameterKey(); // Using general error

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        if (rewardToken.balanceOf(address(this)) < totalAmount) revert InsufficientBalance();

        for (uint256 i = 0; i < _recipients.length; i++) {
            bool success = rewardToken.transfer(_recipients[i], _amounts[i]);
            if (!success) revert InsufficientBalance(); // Should ideally be a more specific error
        }
        emit CommunityPoolDistributed(msg.sender, _recipients, _amounts, _reasonHash);
    }

    // --- V. Decentralized Governance & Adaptive Parameters ---

    /**
     * @dev High-reputation users can propose changes to core protocol parameters.
     * @param _paramKey The bytes32 key of the protocol parameter to change (e.g., "aiAssessmentFee").
     * @param _newValue The proposed new value for the parameter.
     * @param _descriptionHash IPFS/Arweave hash of the detailed proposal description.
     */
    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string calldata _descriptionHash)
        external
        notFrozen
        nonReentrant
        onlyReputable(protocolParameters["minReputationToPropose"])
        returns (uint256 proposalId)
    {
        // Basic validation for parameter keys if needed (e.g., ensure it's a known key)
        if (_paramKey == 0) revert InvalidParameterKey();

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            paramKey: _paramKey,
            newValue: _newValue,
            descriptionHash: _descriptionHash,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + protocolParameters["proposalVotingPeriod"],
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            proposer: msg.sender,
            executed: false,
            // hasVoted mapping initialized automatically by Solidity for storage structs
            hasVoted: new mapping(address => bool)() // Explicitly initialize for clarity
        });

        _updateUserActivity(msg.sender);
        emit ParameterChangeProposed(proposalId, _paramKey, _newValue, msg.sender);
    }

    /**
     * @dev Users vote on active proposals, with their vote weight determined by their current reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote 'for', false to vote 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        notFrozen
        nonReentrant
        onlyReputable(protocolParameters["minReputationToVote"])
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationTime == 0) revert ProposalNotFound(); // Check if proposal exists
        if (block.timestamp > proposal.votingEndTime) revert ProposalNotExecutable("Voting period ended");
        if (proposal.executed) revert ProposalNotExecutable("Already executed");
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 voterReputation = userReputations[msg.sender].score;
        if (_support) {
            proposal.totalVotesFor += voterReputation;
        } else {
            proposal.totalVotesAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        _updateUserActivity(msg.sender);
        emit ProposalVoted(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @dev Executes a successfully voted-on proposal, applying the proposed parameter change.
     *      Any user can call this after the voting period ends and quorum/majority are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external notFrozen nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationTime == 0) revert ProposalNotFound();
        if (block.timestamp <= proposal.votingEndTime) revert ProposalNotExecutable("Voting period not ended");
        if (proposal.executed) revert ProposalNotExecutable("Already executed");

        uint256 minQuorum = protocolParameters["proposalMinQuorum"];
        if (proposal.totalVotesFor + proposal.totalVotesAgainst < minQuorum) {
            revert ProposalNotExecutable("Quorum not met");
        }
        if (proposal.totalVotesFor <= proposal.totalVotesAgainst) {
            revert ProposalNotExecutable("Proposal not passed by majority");
        }

        protocolParameters[proposal.paramKey] = proposal.newValue;
        proposal.executed = true;

        _updateUserActivity(msg.sender); // Executor is active
        emit ProposalExecuted(_proposalId, proposal.paramKey, proposal.newValue);
    }

    /**
     * @dev Retrieves the current value of a specified protocol parameter.
     * @param _paramKey The bytes32 key of the parameter.
     * @return The current uint256 value of the parameter.
     */
    function getProtocolParameter(bytes32 _paramKey) external view returns (uint256) {
        if (protocolParameters[_paramKey] == 0 && _paramKey != bytes32(0)) { // If it's not set and not null key
            // This allows flexible parameters; if a parameter isn't set, it defaults to 0.
            // A more robust solution might have a whitelist of known parameters.
        }
        return protocolParameters[_paramKey];
    }

    /**
     * @dev Users can "signal" to the AI oracle their preference for how a specific parameter should adapt.
     *      This provides decentralized input for potential AI-driven dynamic parameter adjustments,
     *      without directly changing the parameter on-chain.
     * @param _paramKey The bytes32 key of the parameter.
     * @param _adjustmentWeight A signed integer indicating preference (e.g., +100 for increase, -50 for decrease).
     */
    function signalAIParamPreference(bytes32 _paramKey, int256 _adjustmentWeight)
        external
        notFrozen
        onlyReputable(protocolParameters["minReputationToVote"]) // Same as voting reputation
    {
        // This function doesn't change on-chain state of protocolParameters directly.
        // It provides data points for the AI oracle (or an off-chain AI agent) to consider
        // when making its own recommendations or adjustments.
        // The AI oracle would need an external function to query these signals.
        _updateUserActivity(msg.sender);
        emit AIParamPreferenceSignaled(_paramKey, msg.sender, _adjustmentWeight);
    }

    /**
     * @dev Emergency function, callable by highly-reputable governance, to temporarily halt
     *      critical protocol functions (e.g., new insight submissions, voting, reward claims)
     *      in case of severe vulnerabilities or market instability.
     * @param _freeze True to freeze, false to unfreeze.
     */
    function freezeProtocolFunctionality(bool _freeze)
        external
        onlyReputable(protocolParameters["minReputationToPropose"] * 5) // Very high reputation needed
        nonReentrant
    {
        // This function is intended for critical emergency situations.
        // The `protocolFrozen` flag would block most state-changing user functions.
        protocolFrozen = _freeze;
        _updateUserActivity(msg.sender);
        emit ProtocolFrozenStatusChanged(_freeze);
    }

    /**
     * @dev Governance can upgrade or change the contract defining how rewards are calculated and distributed.
     *      This allows for dynamic and evolving reward models without modifying the core logic of AetherForgeProtocol.
     * @param _newStrategyContract The address of the new RewardDistributionStrategy contract.
     */
    function setRewardDistributionStrategy(address _newStrategyContract)
        external
        onlyReputable(protocolParameters["minReputationToPropose"] * 2) // High reputation for this critical change
        notFrozen
        nonReentrant
    {
        if (_newStrategyContract == address(0)) revert InvalidParameterKey();
        emit RewardDistributionStrategySet(rewardDistributionStrategy, _newStrategyContract);
        rewardDistributionStrategy = _newStrategyContract;
    }


    // --- VI. Read-Only / Utility ---

    /**
     * @dev Returns comprehensive details for a given insight.
     * @param _insightId The ID of the insight.
     * @return Insight struct containing all details.
     */
    function getInsightDetails(uint256 _insightId) external view returns (Insight memory) {
        if (_insightId >= nextInsightId) revert InsightNotFound();
        return insights[_insightId];
    }

    /**
     * @dev Fetches a paginated list of the most recently submitted insights.
     * @param _count The number of insights to retrieve.
     * @param _startIndex The starting index (from the latest, 0 being the most recent).
     * @return An array of Insight structs.
     */
    function getLatestInsights(uint256 _count, uint256 _startIndex) external view returns (Insight[] memory) {
        uint256 totalInsights = nextInsightId;
        if (totalInsights == 0 || _startIndex >= totalInsights) {
            return new Insight[](0);
        }

        uint256 actualStartFromLatest = totalInsights - 1 - _startIndex;
        
        uint256 numToReturn = 0;
        if (actualStartFromLatest + 1 > _count) {
             numToReturn = _count;
        } else {
             numToReturn = actualStartFromLatest + 1;
        }

        Insight[] memory latestInsights = new Insight[](numToReturn);
        for (uint256 i = 0; i < numToReturn; i++) {
            latestInsights[i] = insights[actualStartFromLatest - i];
        }
        return latestInsights;
    }

    /**
     * @dev Lists all active or all historical governance proposals.
     * @param _activeOnly If true, only returns proposals where voting has not ended and are not executed.
     * @return An array of Proposal structs.
     */
    function getProposals(bool _activeOnly) external view returns (Proposal[] memory) {
        uint256 currentCount = 0;
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (_activeOnly && (proposals[i].executed || block.timestamp > proposals[i].votingEndTime)) {
                continue;
            }
            currentCount++;
        }

        Proposal[] memory result = new Proposal[currentCount];
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (_activeOnly && (proposals[i].executed || block.timestamp > proposals[i].votingEndTime)) {
                continue;
            }
            result[resultIndex] = proposals[i];
            resultIndex++;
        }
        return result;
    }

    // Fallback and Receive functions to handle Ether (e.g., for challenge fees)
    receive() external payable {}
    fallback() external payable {}

    // Dummy function for checking governor role, replace with actual DAO logic
    function _isGovernor(address _addr) internal pure returns (bool) {
        // In a real DAO, this would check if _addr holds a specific governance token
        // or is part of a multi-sig or has a specific role defined by the DAO.
        // For this example, it's a placeholder returning false, meaning only owner can perform
        // certain sensitive actions like `setAIOracleAddress` initially.
        return false;
    }
}
```