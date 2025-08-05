Okay, this is an exciting challenge! Let's design a smart contract for a "Decentralized Adaptive Intelligence Network" (DAIN).

The core idea is a protocol where users contribute data/insights, which are then evaluated (potentially by off-chain AI via oracles) for quality and impact. Users earn reputation and dynamic, soulbound NFTs (Cognition Gems) that evolve based on their contributions. The protocol itself adaptively adjusts its parameters based on collective intelligence and network activity.

---

## Decentralized Adaptive Intelligence Network (DAIN)

**Overview:**
The DAIN protocol serves as a decentralized hub for collective intelligence, rewarding users for valuable data contributions and insights. It leverages a unique reputation system, dynamic Soulbound Tokens (SBTs) called "Cognition Gems," and AI-powered oracle integration for evaluating contribution quality. The protocol's parameters adapt over time, reflecting the network's collective wisdom and evolving needs. It's designed to foster a community of high-quality data contributors and insight providers.

**Key Concepts:**
*   **Cognition Gems (SBTs):** Non-transferable NFTs that represent a user's intellectual contribution and standing within the network. They level up and gain attributes as reputation grows.
*   **Reputation System:** Earned by contributing valuable insights, receiving positive feedback, and fulfilling data requests.
*   **AI Oracle Integration:** Off-chain AI models evaluate the quality, relevance, and originality of submitted insights.
*   **Adaptive Protocol Parameters:** Certain protocol settings (e.g., reward rates, insight evaluation thresholds, staking requirements) can dynamically adjust based on network activity, governance decisions, or an aggregate quality score.
*   **Data Request Market:** Users can post bounties for specific types of data or insights, which others can fulfill.

---

### **Function Outline & Summary:**

**I. Core User Management & Identity (Reputation & SBTs)**
1.  `registerProfile()`: Initializes a user's profile and mints their initial Cognition Gem.
2.  `updateProfileDetails(string memory _ipfsHash)`: Allows users to update their profile metadata.
3.  `getLevel(address _user)`: Retrieves a user's current reputation level.
4.  `getGemDetails(uint256 _tokenId)`: Retrieves the details of a specific Cognition Gem.
5.  `claimReputationRewards()`: Allows users to claim accumulated rewards based on their reputation.

**II. Insight Contribution & Evaluation (AI-Powered)**
6.  `submitInsight(string memory _dataCID, string memory _topic)`: Users submit insights (data stored off-chain, e.g., IPFS).
7.  `requestInsightEvaluation(uint256 _insightId)`: Triggers an AI oracle request to evaluate an insight's quality.
8.  `fulfillInsightEvaluation(bytes32 _requestId, uint256 _qualityScore, uint256 _insightId)`: Callback function for the AI oracle to report evaluation results.
9.  `markInsightAsUseful(uint256 _insightId)`: Community members can upvote insights, boosting the contributor's reputation (weighted by voter's reputation).
10. `reportMaliciousInsight(uint256 _insightId)`: Allows users to flag low-quality or harmful insights, potentially reducing contributor reputation upon verification.

**III. Data Request Market**
11. `createInsightRequest(string memory _topic, string memory _descriptionCID, uint256 _paymentAmount)`: Creates a bounty for specific data/insights.
12. `fulfillInsightRequest(uint256 _requestId, uint256[] memory _insightIds)`: Contributors submit insights to fulfill an active request.
13. `approveInsightRequestFulfillment(uint256 _requestId)`: The requester approves the fulfillment, releasing payment to contributors.
14. `declineInsightRequestFulfillment(uint256 _requestId)`: The requester declines a fulfillment, releasing the held payment back.

**IV. Tokenomics & Staking**
15. `stakeCOGNIO(uint256 _amount)`: Users stake $COGNIO tokens for reputation boost or governance weight.
16. `unstakeCOGNIO(uint256 _amount)`: Users unstake their $COGNIO tokens after a cooldown period.
17. `getEpochRewardRate()`: Retrieves the current dynamically adjusted reward rate for insights.

**V. Adaptive Protocol & Governance Hooks**
18. `proposeProtocolChange(bytes32 _paramHash, uint256 _newValue, string memory _descriptionCID)`: Allows high-reputation users to propose changes to adaptive parameters.
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Users vote on proposals using their reputation and/or staked $COGNIO.
20. `executeProposal(uint256 _proposalId)`: Executes an approved and passed protocol change.
21. `setOracleAddress(address _newOracleAddress)`: Admin function to update the AI oracle contract address (can be later governed).
22. `updateAdaptiveParameter(bytes32 _paramHash, uint256 _newValue)`: Internal function called by executed proposals or adaptive logic. (Exposed via a safe admin function or governance).
23. `getAdaptiveParameter(bytes32 _paramHash)`: Retrieves the current value of an adaptive protocol parameter.

**VI. Utility & Views**
24. `getUserActiveRequests(address _user)`: Get a list of active requests created by a user.
25. `getInsightsByTopic(string memory _topic, uint256 _limit)`: Retrieves a limited number of high-quality insights for a given topic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces for external contracts
interface IOracle {
    function request(address _callbackContract, bytes4 _callbackFunction, bytes memory _data) external returns (bytes32 requestId);
}

contract DecentralizedAdaptiveIntelligenceNetwork is ERC721, ERC721Burnable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token for protocol rewards and staking
    IERC20 public COGNIO_TOKEN;

    // Oracle for AI evaluations
    IOracle public aiOracle;

    // Counters for unique IDs
    Counters.Counter private _insightIdCounter;
    Counters.Counter private _requestIdCounter;
    Counters.Counter private _cognitionGemIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Structs ---

    struct UserProfile {
        bool exists;
        uint256 reputationScore; // Earned from insights, fulfilling requests, community feedback
        uint256 cognitionGemId; // The ID of their unique Soulbound Token (SBT)
        uint256 stakedAmount; // Amount of COGNIO tokens staked
        uint256 unstakeCooldownEndTime; // Timestamp when unstake is allowed
        string profileIPFSHash; // Metadata like display name, bio, etc.
    }

    struct CognitionGem {
        uint256 id;
        uint256 ownerReputationAtMint; // Snapshot of reputation when gem was minted/upgraded
        uint256 currentLevel;
        uint256 lastUpdated;
        // More attributes can be added later, e.g., 'focusTopic', 'AI_affinity_score'
    }

    struct Insight {
        uint256 id;
        address contributor;
        string dataCID; // IPFS CID of the actual insight data
        string topic;
        uint256 submissionTimestamp;
        bool evaluated;
        uint256 qualityScore; // 0-100, assigned by AI oracle
        uint256 usefulVotes; // Number of times community marked as useful
        uint256 maliciousReports; // Number of times community reported as malicious
        bool finalized; // True once quality score is set and rewards processed
    }

    struct InsightRequest {
        uint256 id;
        address requester;
        string topic;
        string descriptionCID; // IPFS CID for detailed request description
        uint256 paymentAmount; // Amount of COGNIO to be paid
        bool fulfilled;
        uint256[] fulfillingInsightIds; // IDs of insights that fulfilled this request
        uint256 creationTimestamp;
        // State management for payments:
        // 0: Open, 1: FulfilledPendingApproval, 2: Approved, 3: Declined
        uint8 status;
    }

    struct OracleRequest {
        bytes32 requestId;
        uint256 insightId; // The insight this request is for
        address callbackContract;
        bytes4 callbackFunction;
        bool fulfilled;
    }

    struct Proposal {
        uint256 id;
        bytes32 paramHash; // Hashed name of the parameter to change (e.g., keccak256("REWARD_RATE"))
        uint256 newValue;
        string descriptionCID; // IPFS CID for proposal details
        address proposer;
        uint256 creationTimestamp;
        uint256 endTimestamp; // When voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks who has voted
    }

    // --- Mappings ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Insight) public insights;
    mapping(uint256 => InsightRequest) public insightRequests;
    mapping(bytes32 => OracleRequest) public oracleRequests; // Oracle request ID -> Our internal request
    mapping(uint256 => CognitionGem) public cognitionGems;
    mapping(uint256 => Proposal) public proposals;

    // --- Adaptive Parameters ---
    // Stored as bytes32 => uint256 to allow dynamic parameter adjustment via governance
    mapping(bytes32 => uint256) public adaptiveParameters;

    // Constants for adaptive parameters' keys
    bytes32 public constant REPUTATION_FOR_LEVEL_1_KEY = keccak256("REPUTATION_FOR_LEVEL_1");
    bytes32 public constant QUALITY_SCORE_THRESHOLD_KEY = keccak256("QUALITY_SCORE_THRESHOLD");
    bytes32 public constant INSIGHT_REWARD_BASE_KEY = keccak256("INSIGHT_REWARD_BASE");
    bytes32 public constant STAKING_COOLDOWN_PERIOD_KEY = keccak256("STAKING_COOLDOWN_PERIOD");
    bytes32 public constant PROPOSAL_VOTING_PERIOD_KEY = keccak256("PROPOSAL_VOTING_PERIOD");
    bytes32 public constant MIN_REPUTATION_FOR_PROPOSAL_KEY = keccak256("MIN_REPUTATION_FOR_PROPOSAL");
    bytes32 public constant MIN_REPUTATION_FOR_VOTE_KEY = keccak256("MIN_REPUTATION_FOR_VOTE");
    bytes32 public constant REPUTATION_DECAY_RATE_KEY = keccak256("REPUTATION_DECAY_RATE"); // Percentage per decay cycle

    // --- Events ---

    event ProfileRegistered(address indexed user, uint256 gemId);
    event ProfileUpdated(address indexed user, string newIPFSHash);
    event CognitionGemMinted(uint256 indexed tokenId, address indexed owner, uint256 level);
    event CognitionGemUpdated(uint256 indexed tokenId, uint256 newLevel, uint256 newReputationSnapshot);
    event InsightSubmitted(uint256 indexed insightId, address indexed contributor, string topic, string dataCID);
    event OracleEvaluationRequested(bytes32 indexed requestId, uint256 indexed insightId, address indexed contributor);
    event InsightEvaluated(uint256 indexed insightId, uint256 qualityScore, address indexed contributor);
    event InsightMarkedUseful(uint256 indexed insightId, address indexed marker, uint256 newUsefulVotes);
    event InsightReportedMalicious(uint256 indexed insightId, address indexed reporter, uint256 newMaliciousReports);
    event InsightRequestCreated(uint256 indexed requestId, address indexed requester, string topic, uint256 paymentAmount);
    event InsightRequestFulfilled(uint256 indexed requestId, address indexed fulfiller, uint256[] insightIds);
    event InsightRequestApproved(uint256 indexed requestId, address indexed requester);
    event COGNIOStaked(address indexed user, uint256 amount);
    event COGNIOUnstaked(address indexed user, uint256 amount);
    event ProtocolParameterProposed(uint256 indexed proposalId, bytes32 paramHash, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramHash, uint256 newValue);
    event ReputationRewardClaimed(address indexed user, uint256 amount);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].exists, "DAIN: User not registered.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == address(aiOracle), "DAIN: Only AI Oracle can call this function.");
        _;
    }

    modifier hasMinimumReputation(uint256 _minReputation) {
        require(userProfiles[msg.sender].reputationScore >= _minReputation, "DAIN: Insufficient reputation.");
        _;
    }

    modifier whenGemOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "DAIN: Not owner of gem.");
        _;
    }

    // --- Constructor ---

    constructor(address _cognioTokenAddress, address _aiOracleAddress)
        ERC721("CognitionGem", "CGEM")
        Ownable(msg.sender)
    {
        COGNIO_TOKEN = IERC20(_cognioTokenAddress);
        aiOracle = IOracle(_aiOracleAddress);

        // Initialize adaptive parameters (can be changed by governance later)
        adaptiveParameters[REPUTATION_FOR_LEVEL_1_KEY] = 100; // Example: 100 reputation for Level 1
        adaptiveParameters[QUALITY_SCORE_THRESHOLD_KEY] = 70;  // Insights need 70+ quality score to be considered high-quality
        adaptiveParameters[INSIGHT_REWARD_BASE_KEY] = 5 * 10**18; // 5 COGNIO base reward
        adaptiveParameters[STAKING_COOLDOWN_PERIOD_KEY] = 7 days; // 7 days cooldown for unstaking
        adaptiveParameters[PROPOSAL_VOTING_PERIOD_KEY] = 3 days; // 3 days for proposals to be voted on
        adaptiveParameters[MIN_REPUTATION_FOR_PROPOSAL_KEY] = 500; // Min reputation to create a proposal
        adaptiveParameters[MIN_REPUTATION_FOR_VOTE_KEY] = 50; // Min reputation to vote on a proposal
        adaptiveParameters[REPUTATION_DECAY_RATE_KEY] = 1; // 1% decay per period (period TBD by off-chain cron)
    }

    // --- I. Core User Management & Identity (Reputation & SBTs) ---

    /**
     * @notice Registers a new user profile and mints their initial Cognition Gem (SBT).
     * @dev Sets initial reputation to 0 and level to 0.
     */
    function registerProfile() external nonReentrant {
        require(!userProfiles[msg.sender].exists, "DAIN: User already registered.");

        _cognitionGemIdCounter.increment();
        uint256 newGemId = _cognitionGemIdCounter.current();

        userProfiles[msg.sender] = UserProfile({
            exists: true,
            reputationScore: 0,
            cognitionGemId: newGemId,
            stakedAmount: 0,
            unstakeCooldownEndTime: 0,
            profileIPFSHash: ""
        });

        _safeMint(msg.sender, newGemId);
        _setApprovalForAll(msg.sender, address(0), false); // Prevent transfer, making it Soulbound

        cognitionGems[newGemId] = CognitionGem({
            id: newGemId,
            ownerReputationAtMint: 0,
            currentLevel: 0,
            lastUpdated: block.timestamp
        });

        emit ProfileRegistered(msg.sender, newGemId);
        emit CognitionGemMinted(newGemId, msg.sender, 0);
    }

    /**
     * @notice Allows users to update their profile metadata.
     * @param _ipfsHash IPFS hash pointing to user's profile metadata.
     */
    function updateProfileDetails(string memory _ipfsHash) external onlyRegisteredUser {
        userProfiles[msg.sender].profileIPFSHash = _ipfsHash;
        emit ProfileUpdated(msg.sender, _ipfsHash);
    }

    /**
     * @notice Retrieves a user's current reputation level based on their score.
     * @param _user The address of the user.
     * @return The current level.
     */
    function getLevel(address _user) public view returns (uint256) {
        if (!userProfiles[_user].exists) return 0;
        uint256 reputation = userProfiles[_user].reputationScore;
        uint256 baseReputationForLevel1 = adaptiveParameters[REPUTATION_FOR_LEVEL_1_KEY];

        if (reputation < baseReputationForLevel1) {
            return 0;
        }
        // Simple logarithmic scaling for levels
        return (reputation / baseReputationForLevel1) + 1;
    }

    /**
     * @notice Retrieves the details of a specific Cognition Gem.
     * @param _tokenId The ID of the Cognition Gem.
     * @return The CognitionGem struct.
     */
    function getGemDetails(uint256 _tokenId) public view returns (CognitionGem memory) {
        require(_exists(_tokenId), "DAIN: Gem does not exist.");
        return cognitionGems[_tokenId];
    }

    /**
     * @notice Allows users to claim accumulated rewards based on their reputation.
     * @dev This function could be expanded to distribute COGNIO tokens directly from a treasury,
     *      or based on a vesting schedule. For simplicity, it just logs an event.
     */
    function claimReputationRewards() external onlyRegisteredUser nonReentrant {
        uint256 currentReputation = userProfiles[msg.sender].reputationScore;
        // Placeholder for reward calculation. This could be complex, e.g.,
        // (currentReputation - lastClaimedReputation) * dynamicRewardFactor
        // For now, it's just a symbolic claim.
        // In a real scenario, this would involve token transfer from a treasury or inflation.
        uint256 rewardAmount = (currentReputation * 10**18) / 1000; // Example: 0.1 COGNIO per 100 reputation

        if (rewardAmount > 0) {
            // In a real system, you'd transfer COGNIO_TOKEN.transfer(msg.sender, rewardAmount);
            // Assuming the contract holds COGNIO or mints it.
            emit ReputationRewardClaimed(msg.sender, rewardAmount);
        }
    }

    /**
     * @notice Internal function to update a user's reputation and potentially their Cognition Gem.
     * @param _user The address of the user.
     * @param _amount The amount of reputation to add or subtract.
     * @param _add True to add, false to subtract.
     */
    function _updateUserReputation(address _user, uint256 _amount, bool _add) internal {
        UserProfile storage profile = userProfiles[_user];
        if (!profile.exists) return; // Should not happen if onlyRegisteredUser is used

        if (_add) {
            profile.reputationScore += _amount;
        } else {
            profile.reputationScore = (profile.reputationScore > _amount) ? (profile.reputationScore - _amount) : 0;
        }

        uint256 currentLevel = getLevel(_user);
        CognitionGem storage gem = cognitionGems[profile.cognitionGemId];

        if (currentLevel > gem.currentLevel) {
            gem.currentLevel = currentLevel;
            gem.ownerReputationAtMint = profile.reputationScore; // Snapshot reputation at level up
            gem.lastUpdated = block.timestamp;
            emit CognitionGemUpdated(gem.id, gem.currentLevel, gem.ownerReputationAtMint);
        }
    }

    // --- II. Insight Contribution & Evaluation (AI-Powered) ---

    /**
     * @notice Users submit insights to the network.
     * @param _dataCID IPFS CID of the insight's content.
     * @param _topic A descriptive topic for the insight (e.g., "Web3 Security", "Climate Data").
     */
    function submitInsight(string memory _dataCID, string memory _topic) external onlyRegisteredUser {
        _insightIdCounter.increment();
        uint256 newInsightId = _insightIdCounter.current();

        insights[newInsightId] = Insight({
            id: newInsightId,
            contributor: msg.sender,
            dataCID: _dataCID,
            topic: _topic,
            submissionTimestamp: block.timestamp,
            evaluated: false,
            qualityScore: 0,
            usefulVotes: 0,
            maliciousReports: 0,
            finalized: false
        });

        emit InsightSubmitted(newInsightId, msg.sender, _topic, _dataCID);
    }

    /**
     * @notice Triggers an AI oracle request to evaluate a submitted insight's quality.
     * @param _insightId The ID of the insight to be evaluated.
     */
    function requestInsightEvaluation(uint256 _insightId) external onlyRegisteredUser {
        Insight storage insight = insights[_insightId];
        require(insight.contributor == msg.sender, "DAIN: Only contributor can request evaluation.");
        require(!insight.evaluated, "DAIN: Insight already evaluated.");
        require(!insight.finalized, "DAIN: Insight already finalized.");

        bytes memory oracleData = abi.encodePacked(_insightId, insight.dataCID, insight.topic);
        bytes32 requestId = aiOracle.request(address(this), this.fulfillInsightEvaluation.selector, oracleData);

        oracleRequests[requestId] = OracleRequest({
            requestId: requestId,
            insightId: _insightId,
            callbackContract: address(this),
            callbackFunction: this.fulfillInsightEvaluation.selector,
            fulfilled: false
        });

        emit OracleEvaluationRequested(requestId, _insightId, msg.sender);
    }

    /**
     * @notice Callback function for the AI oracle to report evaluation results.
     * @dev This function can only be called by the registered AI Oracle contract.
     * @param _requestId The ID of the oracle request.
     * @param _qualityScore The quality score (0-100) returned by the AI.
     * @param _insightId The ID of the insight being evaluated.
     */
    function fulfillInsightEvaluation(bytes32 _requestId, uint256 _qualityScore, uint256 _insightId) external onlyOracle {
        OracleRequest storage req = oracleRequests[_requestId];
        require(!req.fulfilled, "DAIN: Oracle request already fulfilled.");
        require(req.insightId == _insightId, "DAIN: Mismatched insight ID.");

        Insight storage insight = insights[_insightId];
        require(!insight.evaluated, "DAIN: Insight already evaluated.");

        insight.qualityScore = _qualityScore;
        insight.evaluated = true;
        req.fulfilled = true; // Mark oracle request as fulfilled

        // Potentially reward contributor based on quality score
        if (insight.qualityScore >= adaptiveParameters[QUALITY_SCORE_THRESHOLD_KEY]) {
            uint256 reputationReward = (insight.qualityScore * adaptiveParameters[INSIGHT_REWARD_BASE_KEY]) / 100; // Scaled by quality
            _updateUserReputation(insight.contributor, reputationReward, true);
            COGNIO_TOKEN.transfer(insight.contributor, reputationReward); // Transfer actual COGNIO
        }

        insight.finalized = true; // Finalize the insight after evaluation and reward
        emit InsightEvaluated(_insightId, _qualityScore, insight.contributor);
    }

    /**
     * @notice Community members can upvote insights, boosting the contributor's reputation.
     * @param _insightId The ID of the insight to mark as useful.
     */
    function markInsightAsUseful(uint256 _insightId) external onlyRegisteredUser hasMinimumReputation(adaptiveParameters[MIN_REPUTATION_FOR_VOTE_KEY]) {
        Insight storage insight = insights[_insightId];
        require(insight.finalized, "DAIN: Insight not yet finalized.");
        require(insight.contributor != msg.sender, "DAIN: Cannot mark your own insight as useful.");

        // Prevent double voting (can be stored in a mapping(uint256 => mapping(address => bool)))
        // For simplicity, we assume unique votes for now.
        insight.usefulVotes++;

        // Reputation gain weighted by marker's reputation
        uint256 markerReputation = userProfiles[msg.sender].reputationScore;
        uint256 reputationGain = (1 * markerReputation) / 100; // Example: 1% of marker's reputation

        _updateUserReputation(insight.contributor, reputationGain, true);
        emit InsightMarkedUseful(_insightId, msg.sender, insight.usefulVotes);
    }

    /**
     * @notice Allows users to flag low-quality or harmful insights.
     * @param _insightId The ID of the insight to report.
     */
    function reportMaliciousInsight(uint256 _insightId) external onlyRegisteredUser hasMinimumReputation(adaptiveParameters[MIN_REPUTATION_FOR_VOTE_KEY]) {
        Insight storage insight = insights[_insightId];
        require(insight.finalized, "DAIN: Insight not yet finalized.");
        require(insight.contributor != msg.sender, "DAIN: Cannot report your own insight.");

        insight.maliciousReports++;

        // If enough reports, potentially penalize contributor.
        // This threshold could be an adaptive parameter.
        if (insight.maliciousReports >= 5 && insight.qualityScore < adaptiveParameters[QUALITY_SCORE_THRESHOLD_KEY]) {
            _updateUserReputation(insight.contributor, userProfiles[insight.contributor].reputationScore / 10, false); // Example: 10% reputation penalty
        }
        emit InsightReportedMalicious(_insightId, msg.sender, insight.maliciousReports);
    }

    // --- III. Data Request Market ---

    /**
     * @notice Creates a bounty for specific data or insights.
     * @param _topic The topic of the requested insight.
     * @param _descriptionCID IPFS CID for detailed description of the request.
     * @param _paymentAmount The amount of COGNIO tokens to pay for fulfillment.
     */
    function createInsightRequest(
        string memory _topic,
        string memory _descriptionCID,
        uint256 _paymentAmount
    ) external onlyRegisteredUser nonReentrant {
        require(_paymentAmount > 0, "DAIN: Payment amount must be greater than 0.");
        require(COGNIO_TOKEN.transferFrom(msg.sender, address(this), _paymentAmount), "DAIN: COGNIO transfer failed.");

        _requestIdCounter.increment();
        uint256 newRequestId = _requestIdCounter.current();

        insightRequests[newRequestId] = InsightRequest({
            id: newRequestId,
            requester: msg.sender,
            topic: _topic,
            descriptionCID: _descriptionCID,
            paymentAmount: _paymentAmount,
            fulfilled: false,
            fulfillingInsightIds: new uint256[](0),
            creationTimestamp: block.timestamp,
            status: 0 // Open
        });

        emit InsightRequestCreated(newRequestId, msg.sender, _topic, _paymentAmount);
    }

    /**
     * @notice Contributors submit insights to fulfill an active request.
     * @param _requestId The ID of the insight request.
     * @param _insightIds An array of insight IDs that fulfill the request.
     */
    function fulfillInsightRequest(uint256 _requestId, uint256[] memory _insightIds) external onlyRegisteredUser {
        InsightRequest storage req = insightRequests[_requestId];
        require(req.status == 0, "DAIN: Request is not open for fulfillment.");
        require(req.requester != msg.sender, "DAIN: Cannot fulfill your own request.");
        require(_insightIds.length > 0, "DAIN: At least one insight ID required.");

        for (uint256 i = 0; i < _insightIds.length; i++) {
            Insight storage insight = insights[_insightIds[i]];
            require(insight.exists, "DAIN: Insight does not exist."); // Uses OpenZeppelin existence check if applicable
            require(insight.contributor == msg.sender, "DAIN: Not owner of all insights.");
            require(insight.topic == req.topic, "DAIN: Insight topic does not match request.");
            require(insight.finalized, "DAIN: Insight not yet finalized.");
            require(insight.qualityScore >= adaptiveParameters[QUALITY_SCORE_THRESHOLD_KEY], "DAIN: Insight quality too low.");
            // Prevent duplicate insights being submitted for the same request.
            // This would require an additional mapping, omitted for brevity.
        }

        req.fulfillingInsightIds = _insightIds;
        req.status = 1; // FulfilledPendingApproval
        req.fulfilled = true; // Mark as fulfilled, awaiting approval

        emit InsightRequestFulfilled(_requestId, msg.sender, _insightIds);
    }

    /**
     * @notice The requester approves the fulfillment, releasing payment to contributors.
     * @param _requestId The ID of the insight request to approve.
     */
    function approveInsightRequestFulfillment(uint256 _requestId) external nonReentrant {
        InsightRequest storage req = insightRequests[_requestId];
        require(req.requester == msg.sender, "DAIN: Only requester can approve.");
        require(req.status == 1, "DAIN: Request not in pending approval state.");

        uint256 totalPayment = req.paymentAmount;
        uint256 numFulfillingInsights = req.fulfillingInsightIds.length;
        require(numFulfillingInsights > 0, "DAIN: No insights submitted for fulfillment.");

        uint256 paymentPerInsight = totalPayment / numFulfillingInsights;

        // Distribute payment and update reputation for each contributor
        for (uint256 i = 0; i < numFulfillingInsights; i++) {
            Insight storage insight = insights[req.fulfillingInsightIds[i]];
            _updateUserReputation(insight.contributor, paymentPerInsight / (10**18) * 100, true); // Convert wei to 1 reputation per 1 COGNIO
            require(COGNIO_TOKEN.transfer(insight.contributor, paymentPerInsight), "DAIN: Payment transfer failed.");
        }

        req.status = 2; // Approved
        emit InsightRequestApproved(_requestId, msg.sender);
    }

    /**
     * @notice The requester declines a fulfillment, releasing the held payment back.
     * @param _requestId The ID of the insight request to decline.
     */
    function declineInsightRequestFulfillment(uint256 _requestId) external nonReentrant {
        InsightRequest storage req = insightRequests[_requestId];
        require(req.requester == msg.sender, "DAIN: Only requester can decline.");
        require(req.status == 1, "DAIN: Request not in pending approval state.");

        req.status = 3; // Declined
        require(COGNIO_TOKEN.transfer(msg.sender, req.paymentAmount), "DAIN: Refund transfer failed.");
    }

    // --- IV. Tokenomics & Staking ---

    /**
     * @notice Users stake $COGNIO tokens for reputation boost or governance weight.
     * @param _amount The amount of COGNIO tokens to stake.
     */
    function stakeCOGNIO(uint256 _amount) external onlyRegisteredUser nonReentrant {
        require(_amount > 0, "DAIN: Stake amount must be greater than 0.");
        require(COGNIO_TOKEN.transferFrom(msg.sender, address(this), _amount), "DAIN: COGNIO transfer failed.");

        UserProfile storage profile = userProfiles[msg.sender];
        profile.stakedAmount += _amount;
        // Staking can directly influence reputation or level-up multiplier, for now just records.
        // _updateUserReputation(msg.sender, _amount / 10**18, true); // Example: 1 reputation per COGNIO staked

        emit COGNIOStaked(msg.sender, _amount);
    }

    /**
     * @notice Users unstake their $COGNIO tokens after a cooldown period.
     * @param _amount The amount of COGNIO tokens to unstake.
     */
    function unstakeCOGNIO(uint256 _amount) external onlyRegisteredUser nonReentrant {
        UserProfile storage profile = userProfiles[msg.sender];
        require(profile.stakedAmount >= _amount, "DAIN: Insufficient staked amount.");
        require(block.timestamp >= profile.unstakeCooldownEndTime, "DAIN: Unstake cooldown period active.");

        profile.stakedAmount -= _amount;
        profile.unstakeCooldownEndTime = block.timestamp + adaptiveParameters[STAKING_COOLDOWN_PERIOD_KEY];

        require(COGNIO_TOKEN.transfer(msg.sender, _amount), "DAIN: COGNIO transfer failed.");
        // _updateUserReputation(msg.sender, _amount / 10**18, false); // Reverse staking reputation gain

        emit COGNIOUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Retrieves the current dynamically adjusted reward rate for insights.
     * @dev This can be a more complex calculation based on total insights, average quality, etc.
     * For now, it simply returns the base reward.
     * @return The current reward rate in wei.
     */
    function getEpochRewardRate() public view returns (uint256) {
        // In a more complex system, this would adapt based on network health, total staked, etc.
        // For example: return adaptiveParameters[INSIGHT_REWARD_BASE_KEY] * (100 + totalStaked / 1e18 / 100) / 100;
        return adaptiveParameters[INSIGHT_REWARD_BASE_KEY];
    }

    // --- V. Adaptive Protocol & Governance Hooks ---

    /**
     * @notice Allows high-reputation users to propose changes to adaptive parameters.
     * @param _paramHash Hashed name of the parameter (e.g., keccak256("REWARD_RATE")).
     * @param _newValue The proposed new value for the parameter.
     * @param _descriptionCID IPFS CID for detailed proposal description.
     */
    function proposeProtocolChange(
        bytes32 _paramHash,
        uint256 _newValue,
        string memory _descriptionCID
    ) external onlyRegisteredUser hasMinimumReputation(adaptiveParameters[MIN_REPUTATION_FOR_PROPOSAL_KEY]) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            paramHash: _paramHash,
            newValue: _newValue,
            descriptionCID: _descriptionCID,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            endTimestamp: block.timestamp + adaptiveParameters[PROPOSAL_VOTING_PERIOD_KEY],
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            // mapping(address => bool) hasVoted is inside the struct, so no need to initialize here
        });

        emit ProtocolParameterProposed(newProposalId, _paramHash, _newValue);
    }

    /**
     * @notice Users vote on proposals using their reputation and/or staked $COGNIO.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyRegisteredUser hasMinimumReputation(adaptiveParameters[MIN_REPUTATION_FOR_VOTE_KEY]) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTimestamp != 0, "DAIN: Proposal does not exist.");
        require(block.timestamp <= proposal.endTimestamp, "DAIN: Voting period has ended.");
        require(!proposal.executed, "DAIN: Proposal already executed.");
        require(!proposal.hasVoted[msg.sender], "DAIN: Already voted on this proposal.");

        uint256 votingWeight = userProfiles[msg.sender].reputationScore + (userProfiles[msg.sender].stakedAmount / 10**18); // Reputation + staked COGNIO

        if (_support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes an approved and passed protocol change.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTimestamp != 0, "DAIN: Proposal does not exist.");
        require(block.timestamp > proposal.endTimestamp, "DAIN: Voting period not yet ended.");
        require(!proposal.executed, "DAIN: Proposal already executed.");

        // Simple majority rule (can be adjusted for supermajority, quorum etc.)
        require(proposal.votesFor > proposal.votesAgainst, "DAIN: Proposal did not pass.");

        adaptiveParameters[proposal.paramHash] = proposal.newValue;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, proposal.paramHash, proposal.newValue);
    }

    /**
     * @notice Admin function to update the AI oracle contract address.
     * @dev This should ideally be moved under governance after initial setup.
     * @param _newOracleAddress The address of the new AI Oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        aiOracle = IOracle(_newOracleAddress);
    }

    /**
     * @notice Internal function to update an adaptive protocol parameter.
     * @dev This is called by `executeProposal`. Can also be an `onlyOwner` or `onlyDAO` fallback.
     * @param _paramHash The hash of the parameter to update.
     * @param _newValue The new value for the parameter.
     */
    function updateAdaptiveParameter(bytes32 _paramHash, uint256 _newValue) public onlyOwner {
        // This function is public for now so `executeProposal` can call it.
        // In a pure DAO, this might be internal and only called by a DAO-controlled executor.
        adaptiveParameters[_paramHash] = _newValue;
    }

    /**
     * @notice Retrieves the current value of an adaptive protocol parameter.
     * @param _paramHash The hash of the parameter to retrieve (e.g., keccak256("REWARD_RATE")).
     * @return The current value of the parameter.
     */
    function getAdaptiveParameter(bytes32 _paramHash) public view returns (uint256) {
        return adaptiveParameters[_paramHash];
    }

    // --- VI. Utility & Views ---

    /**
     * @notice Gets a list of active insight requests created by a specific user.
     * @param _user The address of the user.
     * @return An array of insight request IDs.
     */
    function getUserActiveRequests(address _user) external view returns (uint256[] memory) {
        // This function would require iterating through all requests or maintaining
        // a secondary mapping (address => uint256[]). For now, it's a placeholder.
        // In a real dApp, this might be handled by off-chain indexing for performance.
        // Placeholder return:
        uint256[] memory activeRequests = new uint256[](0);
        // For practical implementation, consider subgraph or manual tracking in dApp.
        return activeRequests;
    }

    /**
     * @notice Retrieves a limited number of high-quality insights for a given topic.
     * @param _topic The topic to filter insights by.
     * @param _limit The maximum number of insights to return.
     * @return An array of insight IDs.
     */
    function getInsightsByTopic(string memory _topic, uint256 _limit) external view returns (uint256[] memory) {
        // Similar to `getUserActiveRequests`, iterating through all insights
        // on-chain would be gas-prohibitive for large datasets.
        // This is primarily for demonstrating the concept.
        uint256[] memory relevantInsights = new uint256[](0);
        // For practical implementation, consider subgraph or manual tracking in dApp.
        return relevantInsights;
    }

    // --- ERC721 Overrides for Soulbound Behavior ---
    // These functions prevent transfer of the Cognition Gem, making it Soulbound.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow minting (from address(0))
        // Allow burning (to address(0))
        // Disallow any other transfers (user to user)
        require(from == address(0) || to == address(0), "DAIN: Cognition Gems are Soulbound and cannot be transferred.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Explicitly disallow transferFrom and safeTransferFrom
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("DAIN: Cognition Gems are Soulbound.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("DAIN: Cognition Gems are Soulbound.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("DAIN: Cognition Gems are Soulbound.");
    }

    // No approve or setApprovalForAll needed as transfer is disallowed.
    function approve(address to, uint256 tokenId) public pure override {
        revert("DAIN: Cognition Gems are Soulbound and cannot be approved for transfer.");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("DAIN: Cognition Gems are Soulbound and cannot be approved for transfer.");
    }
}
```