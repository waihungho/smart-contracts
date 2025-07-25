Okay, this is an exciting challenge! Let's design a smart contract for a "QuantumLeap Insights Protocol" – a decentralized platform for collaborative research and knowledge validation, featuring dynamic insight valuation, AI-assisted curation, and a unique reputation system.

The core idea is that users submit "insights" (research findings, data analyses, hypotheses). These insights are then subject to a multi-layered validation process involving human curators and an AI oracle. The "value" of an insight isn't static; it dynamically adjusts based on its perceived utility, accuracy, and ongoing engagement, incentivizing valuable, evolving contributions.

---

## QuantumLeap Insights Protocol (QLIP) - Smart Contract Outline & Function Summary

**Contract Name:** `QuantumLeapInsightsProtocol`

**Description:**
A decentralized protocol enabling the submission, AI-assisted validation, dynamic valuation, and collaborative refinement of research insights. It rewards accurate contributors and effective curators, fostering a high-quality, evolving knowledge base. Insights gain or lose "Impact Score" based on ongoing utility, external citations (simulated/oracle-fed), and continued validation, with a built-in mechanism for obsolescence and challenging.

---

### **Function Summary:**

**I. Core Insight Management**
1.  `submitInsight(bytes32 _contentHash, string calldata _metadataURI, string[] calldata _tags)`: Allows a user to submit a new research insight, attaching a content hash (e.g., IPFS CID) and metadata URI.
2.  `updateInsightMetadata(uint256 _insightId, string calldata _newMetadataURI, string[] calldata _newTags)`: Allows the original contributor to update an insight's metadata (e.g., description, related links) without changing core content.
3.  `retractInsight(uint256 _insightId)`: Allows the contributor to remove their insight, potentially incurring a penalty or forfeiture of earned rewards.
4.  `getInsightDetails(uint256 _insightId)`: Retrieves all detailed information about a specific insight.
5.  `getInsightsByContributor(address _contributor)`: Returns a list of insight IDs submitted by a specific address.

**II. Validation & Curation**
6.  `stakeAndValidateInsight(uint256 _insightId, bool _isAccurate, uint256 _stakeAmount)`: Allows a registered curator to stake QLI tokens and cast a vote on the accuracy/utility of an insight.
7.  `requestAIEvaluation(uint256 _insightId)`: Triggers a request to the external AI Oracle for an objective evaluation score of an insight.
8.  `fulfillAIEvaluation(uint256 _insightId, uint256 _aiScore, bytes32 _requestId)`: **(Only Callable by AI Oracle)** Callback function to receive the AI evaluation score.
9.  `finalizeValidationRound(uint256 _insightId)`: Combines human validation votes and AI score to calculate the initial `humanValidationScore` and `aiScore`, and determines curator rewards/penalties.
10. `challengeValidationOutcome(uint256 _insightId, address _challenger, uint256 _stakeAmount)`: Allows any user to challenge the final validation outcome of an insight, requiring a stake to initiate a re-evaluation process.

**III. Dynamic Value & Rewards**
11. `distributeInsightRewards(uint256 _insightId)`: Distributes QLI rewards to the contributor and successful validators of a sufficiently validated insight.
12. `claimValidationStakes(uint256 _insightId)`: Allows validators to claim their staked QLI back after the validation round is finalized.
13. `recalibrateInsightImpact(uint256 _insightId, uint256 _externalImpactScore)`: A unique function that periodically updates an insight's `impactScore` based on external metrics (e.g., simulated citation count, real-world utility reported via oracle).
14. `burnStaleInsights(uint256 _insightId)`: Flags or removes insights that fall below a minimum `impactScore` threshold for a prolonged period, ensuring data hygiene.

**IV. Reputation System**
15. `getContributorReputation(address _contributor)`: Retrieves the overall reputation score of a contributor, based on the success and impact of their insights.
16. `getCuratorPerformance(address _curator)`: Retrieves the accuracy/consistency score of a curator's past validations.

**V. Governance & Protocol Parameters**
17. `proposeProtocolChange(string calldata _description, address _targetContract, bytes calldata _callData)`: Allows users with sufficient governance token holdings to propose changes to protocol parameters (e.g., reward weights, validation periods).
18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows governance token holders to vote on active proposals.
19. `executeProposal(uint256 _proposalId)`: Executes an approved and passed governance proposal.
20. `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: An internal/governance-callable function to update specific protocol parameters (e.g., `MIN_STAKE_AMOUNT`, `VALIDATION_PERIOD`).

**VI. Discovery & Utility**
21. `searchInsightsByTag(string calldata _tag)`: Returns a list of insight IDs associated with a given tag.
22. `getTopInsightsByImpact(uint256 _limit)`: Returns the top `_limit` insights ordered by their current `impactScore`.
23. `fundInsightResearch(string calldata _researchTopic, uint256 _amount)`: Allows users to stake QLI tokens towards a *future* research topic, creating a bounty for contributors.
24. `claimResearchBounty(uint256 _bountyId, uint256 _insightId)`: Allows a contributor to claim a research bounty by submitting an insight that meets the bounty's criteria.

**VII. Access Control & System Management**
25. `pauseProtocol()`: Allows the protocol admin or governance to pause critical functions in case of an emergency.
26. `unpauseProtocol()`: Allows the protocol admin or governance to unpause the protocol.
27. `setAIOracleAddress(address _newOracle)`: Allows the protocol admin to update the address of the AI Oracle.

---

### **Solidity Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for a hypothetical AI Oracle
interface IAIOracle {
    function requestEvaluation(uint256 _insightId, string calldata _contentHash, string calldata _metadataURI) external returns (bytes32 requestId);
    // Function for the oracle to call back, potentially emitting an event
    function fulfillEvaluation(uint256 _insightId, uint256 _aiScore, bytes32 _requestId) external;
}

// Interface for Governance Token (assuming a separate ERC20 for voting)
interface IGovernanceToken is IERC20 {
    function getVotes(address account) external view returns (uint256);
}

contract QuantumLeapInsightsProtocol is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum InsightStatus {
        Submitted,
        PendingAIEvaluation,
        PendingHumanValidation,
        ValidationFinalized,
        Challenged,
        Retracted,
        Stale
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---
    struct Insight {
        uint256 id;
        address contributor;
        bytes32 contentHash;      // e.g., IPFS CID
        string metadataURI;       // e.g., URI to JSON describing the insight
        string[] tags;
        uint256 submissionTimestamp;
        uint256 aiScore;          // Score from AI oracle (0-1000)
        uint256 humanValidationScore; // Aggregated score from human validators (0-1000)
        uint256 impactScore;      // Dynamic score reflecting overall utility, citations, etc. (0-10000)
        InsightStatus status;
        uint256 totalValidationStake; // Total QLI staked by validators
        mapping(address => ValidationVote) validationVotes;
        address[] currentValidators; // List of addresses who voted in the current round
        uint256 positiveVotes;
        uint256 negativeVotes;
        bytes32 aiRequestId;      // Stores the request ID for the AI oracle call
        uint256 lastImpactRecalibration; // Timestamp of last impact score update
    }

    struct ValidationVote {
        bool hasVoted;
        bool isAccurate;          // True for positive, False for negative
        uint256 stakeAmount;
        uint256 timestamp;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yayVotes;
        uint256 nayVotes;
        uint256 quorumRequired;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }

    struct ResearchBounty {
        uint256 id;
        string topic;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 expiryTimestamp;
        address funder;
        bool claimed;
        uint256 insightIdClaimedBy;
    }

    // --- State Variables ---
    IERC20 public QLIToken; // The native utility token of the protocol
    IGovernanceToken public governanceToken; // The governance token (could be QLIToken itself, or separate)
    IAIOracle public aiOracle;

    uint256 private _insightCounter;
    uint256 private _proposalCounter;
    uint256 private _bountyCounter;

    mapping(uint256 => Insight) public insights;
    mapping(address => uint256) public contributorReputation; // Contributor's overall reputation score
    mapping(address => uint256) public curatorPerformance;   // Curator's validation accuracy/consistency

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => ResearchBounty) public researchBounties;

    // Protocol Parameters (can be updated via governance)
    uint256 public MIN_INSIGHT_STAKE = 100 * (10 ** 18); // Minimum QLI to stake for an insight
    uint256 public MIN_VALIDATOR_STAKE = 10 * (10 ** 18); // Minimum QLI to stake for validation
    uint256 public VALIDATION_PERIOD = 3 days;           // How long an insight is open for human validation
    uint224 public AI_EVALUATION_FEE = 1 * (10 ** 18);   // Fee for AI evaluation, paid in QLI
    uint256 public INSIGHT_REWARD_POOL_PERCENT = 50;     // % of AI evaluation fee goes to contributor/validators
    uint256 public CHALLENGE_STAKE_MULTIPLIER = 2;       // Multiplier for challenge stake vs. original validation stake
    uint256 public IMPACT_DECAY_RATE_PER_DAY = 1;        // Points of impact score decay per day
    uint256 public MIN_IMPACT_SCORE_FOR_ACTIVE = 100;    // Insights below this might be flagged as stale
    uint256 public PROTOCOL_FEE_BPS = 500;               // 5% (500 basis points) protocol fee on certain actions

    // --- Events ---
    event InsightSubmitted(uint256 indexed insightId, address indexed contributor, bytes32 contentHash, string metadataURI);
    event InsightUpdated(uint256 indexed insightId, string newMetadataURI, string[] newTags);
    event InsightRetracted(uint256 indexed insightId, address indexed contributor);
    event ValidationVoteCast(uint256 indexed insightId, address indexed validator, bool isAccurate, uint256 stakeAmount);
    event AIEvaluationRequested(uint256 indexed insightId, bytes32 requestId);
    event AIEvaluationFulfilled(uint256 indexed insightId, uint256 aiScore, bytes32 requestId);
    event ValidationRoundFinalized(uint256 indexed insightId, uint256 humanValidationScore, uint256 aiScore, InsightStatus newStatus);
    event InsightRewardsDistributed(uint256 indexed insightId, address indexed contributor, uint256 contributorReward, uint256 totalValidatorReward);
    event ValidationStakesClaimed(uint256 indexed insightId, address indexed validator, uint256 amount);
    event InsightImpactRecalibrated(uint256 indexed insightId, uint256 oldImpactScore, uint256 newImpactScore, uint256 externalImpactScore);
    event StaleInsightBurned(uint256 indexed insightId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterUpdated(bytes32 paramName, uint256 oldValue, uint256 newValue);
    event ResearchBountyFunded(uint256 indexed bountyId, string topic, uint256 amount, address indexed funder);
    event ResearchBountyClaimed(uint256 indexed bountyId, uint256 indexed insightId, address indexed claimant);
    event ChallengeInitiated(uint256 indexed insightId, address indexed challenger, uint256 stakeAmount);

    // --- Constructor ---
    constructor(address _qLITokenAddress, address _governanceTokenAddress, address _aiOracleAddress) Ownable(msg.sender) {
        QLIToken = IERC20(_qLITokenAddress);
        governanceToken = IGovernanceToken(_governanceTokenAddress);
        aiOracle = IAIOracle(_aiOracleAddress);
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "QLIP: Only AI Oracle can call this function.");
        _;
    }

    modifier onlyInsightContributor(uint256 _insightId) {
        require(insights[_insightId].contributor == msg.sender, "QLIP: Not the insight contributor.");
        _;
    }

    modifier insightExists(uint256 _insightId) {
        require(_insightId > 0 && _insightId <= _insightCounter, "QLIP: Insight does not exist.");
        _;
    }

    modifier canBeValidated(uint256 _insightId) {
        require(
            insights[_insightId].status == InsightStatus.Submitted ||
            insights[_insightId].status == InsightStatus.PendingHumanValidation,
            "QLIP: Insight not in a valid state for validation."
        );
        require(block.timestamp < insights[_insightId].submissionTimestamp + VALIDATION_PERIOD, "QLIP: Validation period has ended.");
        _;
    }

    // --- I. Core Insight Management ---

    /**
     * @notice Allows a user to submit a new research insight.
     * @param _contentHash A hash identifying the insight's core content (e.g., IPFS CID).
     * @param _metadataURI A URI pointing to additional metadata (e.g., description, links).
     * @param _tags An array of keywords for discoverability.
     */
    function submitInsight(bytes32 _contentHash, string calldata _metadataURI, string[] calldata _tags)
        external
        whenNotPaused
        nonReentrant
    {
        require(bytes(_contentHash).length > 0, "QLIP: Content hash cannot be empty.");
        require(bytes(_metadataURI).length > 0, "QLIP: Metadata URI cannot be empty.");
        require(_tags.length > 0, "QLIP: At least one tag required.");
        require(QLIToken.transferFrom(msg.sender, address(this), MIN_INSIGHT_STAKE), "QLIP: Failed to transfer insight stake.");

        _insightCounter++;
        Insight storage newInsight = insights[_insightCounter];
        newInsight.id = _insightCounter;
        newInsight.contributor = msg.sender;
        newInsight.contentHash = _contentHash;
        newInsight.metadataURI = _metadataURI;
        newInsight.tags = _tags;
        newInsight.submissionTimestamp = block.timestamp;
        newInsight.status = InsightStatus.Submitted;
        newInsight.impactScore = 0; // Initial impact score
        newInsight.lastImpactRecalibration = block.timestamp;

        // Immediately request AI evaluation
        newInsight.aiRequestId = aiOracle.requestEvaluation(newInsight.id, _contentHash, _metadataURI);
        newInsight.status = InsightStatus.PendingAIEvaluation;

        emit InsightSubmitted(newInsight.id, msg.sender, _contentHash, _metadataURI);
    }

    /**
     * @notice Allows the original contributor to update an insight's non-core metadata.
     * @param _insightId The ID of the insight to update.
     * @param _newMetadataURI The new URI for metadata.
     * @param _newTags New tags for the insight.
     */
    function updateInsightMetadata(uint256 _insightId, string calldata _newMetadataURI, string[] calldata _newTags)
        external
        whenNotPaused
        onlyInsightContributor(_insightId)
        insightExists(_insightId)
    {
        require(
            insights[_insightId].status != InsightStatus.Retracted && insights[_insightId].status != InsightStatus.Stale,
            "QLIP: Cannot update retracted or stale insights."
        );
        insights[_insightId].metadataURI = _newMetadataURI;
        insights[_insightId].tags = _newTags;
        emit InsightUpdated(_insightId, _newMetadataURI, _newTags);
    }

    /**
     * @notice Allows the contributor to retract their insight, potentially with a penalty.
     * @param _insightId The ID of the insight to retract.
     */
    function retractInsight(uint256 _insightId)
        external
        whenNotPaused
        onlyInsightContributor(_insightId)
        insightExists(_insightId)
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(insight.status != InsightStatus.Retracted && insight.status != InsightStatus.Stale, "QLIP: Insight already retracted or stale.");

        // Forfeit a portion of the initial stake, or all if retracted early
        uint256 returnAmount = MIN_INSIGHT_STAKE / 2; // Example: return 50%
        if (insight.status == InsightStatus.Submitted || insight.status == InsightStatus.PendingAIEvaluation) {
            returnAmount = 0; // No return if retracted before validation
        }
        
        if (returnAmount > 0) {
            require(QLIToken.transfer(msg.sender, returnAmount), "QLIP: Failed to return partial stake.");
        }

        insight.status = InsightStatus.Retracted;
        emit InsightRetracted(_insightId, msg.sender);
    }

    /**
     * @notice Retrieves all detailed information about a specific insight.
     * @param _insightId The ID of the insight.
     * @return All fields of the Insight struct.
     */
    function getInsightDetails(uint256 _insightId)
        public
        view
        insightExists(_insightId)
        returns (
            uint256 id,
            address contributor,
            bytes32 contentHash,
            string memory metadataURI,
            string[] memory tags,
            uint256 submissionTimestamp,
            uint256 aiScore,
            uint256 humanValidationScore,
            uint256 impactScore,
            InsightStatus status,
            uint256 totalValidationStake,
            uint256 positiveVotes,
            uint256 negativeVotes
        )
    {
        Insight storage insight = insights[_insightId];
        return (
            insight.id,
            insight.contributor,
            insight.contentHash,
            insight.metadataURI,
            insight.tags,
            insight.submissionTimestamp,
            insight.aiScore,
            insight.humanValidationScore,
            insight.impactScore,
            insight.status,
            insight.totalValidationStake,
            insight.positiveVotes,
            insight.negativeVotes
        );
    }

    /**
     * @notice Returns a list of insight IDs submitted by a specific address.
     * @param _contributor The address of the contributor.
     * @return An array of insight IDs.
     */
    function getInsightsByContributor(address _contributor)
        public
        view
        returns (uint256[] memory)
    {
        // This is inefficient for many insights; for a real Dapp, use subgraph or off-chain index.
        // For contract demo purposes, we'll iterate up to _insightCounter.
        // A more efficient on-chain solution would require a mapping of address to an array of insight IDs.
        // For simplicity and adhering to the prompt, we'll return a dynamic array of IDs here.
        uint256[] memory contributorInsights = new uint256[](0); // Placeholder, will be dynamically sized
        uint256 count = 0;
        for (uint256 i = 1; i <= _insightCounter; i++) {
            if (insights[i].contributor == _contributor) {
                count++;
            }
        }
        contributorInsights = new uint256[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= _insightCounter; i++) {
            if (insights[i].contributor == _contributor) {
                contributorInsights[currentIdx] = i;
                currentIdx++;
            }
        }
        return contributorInsights;
    }

    // --- II. Validation & Curation ---

    /**
     * @notice Allows a registered curator to stake QLI and cast a vote on an insight's accuracy.
     * @param _insightId The ID of the insight to validate.
     * @param _isAccurate True if the validator believes the insight is accurate/useful, false otherwise.
     * @param _stakeAmount The amount of QLI to stake.
     */
    function stakeAndValidateInsight(uint256 _insightId, bool _isAccurate, uint256 _stakeAmount)
        external
        whenNotPaused
        insightExists(_insightId)
        canBeValidated(_insightId)
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(_stakeAmount >= MIN_VALIDATOR_STAKE, "QLIP: Stake amount too low.");
        require(insight.validationVotes[msg.sender].hasVoted == false, "QLIP: You have already voted on this insight.");
        require(QLIToken.transferFrom(msg.sender, address(this), _stakeAmount), "QLIP: Failed to transfer stake.");

        insight.validationVotes[msg.sender] = ValidationVote({
            hasVoted: true,
            isAccurate: _isAccurate,
            stakeAmount: _stakeAmount,
            timestamp: block.timestamp
        });
        insight.totalValidationStake += _stakeAmount;
        insight.currentValidators.push(msg.sender);

        if (_isAccurate) {
            insight.positiveVotes++;
        } else {
            insight.negativeVotes++;
        }

        emit ValidationVoteCast(_insightId, msg.sender, _isAccurate, _stakeAmount);
    }

    /**
     * @notice This function is a placeholder for external AI oracle interaction.
     *         It would typically be called by the `submitInsight` or `challengeValidationOutcome` functions.
     *         For a real implementation, this would involve Chainlink Automation or a similar oracle.
     * @param _insightId The ID of the insight to evaluate.
     */
    function requestAIEvaluation(uint256 _insightId)
        public
        whenNotPaused
        insightExists(_insightId)
        // This function will be called internally by submitInsight initially.
        // Could be made callable by anyone willing to pay the fee for an existing insight.
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Submitted || insight.status == InsightStatus.Challenged, "QLIP: AI evaluation not applicable for current status.");
        require(QLIToken.transferFrom(msg.sender, address(this), AI_EVALUATION_FEE), "QLIP: Failed to pay AI evaluation fee.");

        insight.aiRequestId = aiOracle.requestEvaluation(_insightId, insight.contentHash, insight.metadataURI);
        insight.status = InsightStatus.PendingAIEvaluation; // Or back to this state if challenged

        emit AIEvaluationRequested(_insightId, insight.aiRequestId);
    }

    /**
     * @notice Callback function for the AI Oracle to fulfill an evaluation request.
     * @dev ONLY callable by the registered AI Oracle address.
     * @param _insightId The ID of the insight that was evaluated.
     * @param _aiScore The AI's evaluation score (0-1000).
     * @param _requestId The request ID associated with the original request.
     */
    function fulfillAIEvaluation(uint256 _insightId, uint256 _aiScore, bytes32 _requestId)
        external
        onlyAIOracle
        insightExists(_insightId)
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.PendingAIEvaluation, "QLIP: Insight not awaiting AI evaluation.");
        require(insight.aiRequestId == _requestId, "QLIP: Mismatched AI request ID.");
        
        insight.aiScore = _aiScore;
        insight.status = InsightStatus.PendingHumanValidation; // Now open for human validation

        emit AIEvaluationFulfilled(_insightId, _aiScore, _requestId);
    }

    /**
     * @notice Finalizes the validation round for an insight, calculating scores and handling stakes.
     *         Can be called by anyone after the validation period has passed or sufficient votes.
     * @param _insightId The ID of the insight to finalize.
     */
    function finalizeValidationRound(uint256 _insightId)
        public
        whenNotPaused
        insightExists(_insightId)
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.PendingHumanValidation, "QLIP: Insight not in pending human validation state.");
        require(block.timestamp >= insight.submissionTimestamp + VALIDATION_PERIOD, "QLIP: Validation period not over yet.");
        require(insight.aiScore > 0, "QLIP: AI evaluation not yet received."); // Ensure AI score is present

        uint256 totalVotes = insight.positiveVotes + insight.negativeVotes;
        require(totalVotes > 0, "QLIP: No votes cast to finalize.");

        // Calculate human validation score (e.g., weighted average or simple ratio)
        insight.humanValidationScore = (insight.positiveVotes * 1000) / totalVotes;

        // Combine AI and human score to set initial impact score
        // Example: 70% human, 30% AI, scaled to 10000 max
        insight.impactScore = (insight.humanValidationScore * 70 + insight.aiScore * 30) * 10; // Scaled to 10000

        // Process validator stakes
        uint256 successfulStakePool = 0;
        uint256 losingStakePool = 0;
        uint256 totalCorrectVotes = 0;
        uint256 totalIncorrectVotes = 0;

        for (uint256 i = 0; i < insight.currentValidators.length; i++) {
            address validator = insight.currentValidators[i];
            ValidationVote storage vote = insight.validationVotes[validator];

            // For simplicity, success means agreeing with the overall majority of human + AI consensus
            bool isCorrect = (insight.humanValidationScore >= 500 && vote.isAccurate) ||
                             (insight.humanValidationScore < 500 && !vote.isAccurate);

            // A more advanced system would compare individual vote to the *final* outcome including AI.
            // For now, let's just make it simple: if human majority is positive and they voted positive, they're correct.
            // If human majority is negative and they voted negative, they're correct.
            // And penalize if they voted opposite to the AI score being high.

            if (isCorrect) {
                successfulStakePool += vote.stakeAmount;
                totalCorrectVotes++;
            } else {
                losingStakePool += vote.stakeAmount;
                totalIncorrectVotes++;
            }
        }

        // Distribute portion of losing stakes to winners, and some to protocol
        uint256 winningShareFromLosers = losingStakePool / 2; // Example: 50% of losing stakes redistributed
        uint256 protocolFeeFromLosers = losingStakePool - winningShareFromLosers;

        if (successfulStakePool > 0) {
            uint256 rewardPerUnitStake = winningShareFromLosers / successfulStakePool;
            for (uint256 i = 0; i < insight.currentValidators.length; i++) {
                address validator = insight.currentValidators[i];
                ValidationVote storage vote = insight.validationVotes[validator];
                bool isCorrect = (insight.humanValidationScore >= 500 && vote.isAccurate) ||
                             (insight.humanValidationScore < 500 && !vote.isAccurate);
                if (isCorrect) {
                    // Update curator performance: simple accuracy tracking
                    curatorPerformance[validator] += 1;
                    // Reward is their stake + proportional share of the winning pool
                    // For simplicity, funds are only claimable via claimValidationStakes.
                } else {
                    curatorPerformance[validator] = curatorPerformance[validator] > 0 ? curatorPerformance[validator] - 1 : 0;
                }
            }
        }

        if (protocolFeeFromLosers > 0) {
            // Send protocol fee to owner or a treasury contract
            QLIToken.transfer(owner(), protocolFeeFromLosers);
        }

        insight.status = InsightStatus.ValidationFinalized;
        emit ValidationRoundFinalized(_insightId, insight.humanValidationScore, insight.aiScore, insight.status);
    }

    /**
     * @notice Allows any user to challenge the final validation outcome of an insight.
     *         Requires a significant stake to prevent spam. This would re-trigger AI and possibly new human validation.
     * @param _insightId The ID of the insight to challenge.
     * @param _challenger The address initiating the challenge.
     * @param _stakeAmount The amount of QLI to stake for the challenge.
     */
    function challengeValidationOutcome(uint256 _insightId, address _challenger, uint256 _stakeAmount)
        external
        whenNotPaused
        insightExists(_insightId)
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.ValidationFinalized, "QLIP: Only finalized insights can be challenged.");
        require(_stakeAmount >= insight.totalValidationStake * CHALLENGE_STAKE_MULTIPLIER / 10000, "QLIP: Challenge stake too low."); // Example calculation
        
        require(QLIToken.transferFrom(msg.sender, address(this), _stakeAmount), "QLIP: Failed to transfer challenge stake.");

        // Reset for re-evaluation
        insight.status = InsightStatus.Challenged;
        insight.humanValidationScore = 0;
        insight.aiScore = 0;
        insight.totalValidationStake = 0;
        delete insight.currentValidators; // Clear old validators
        insight.positiveVotes = 0;
        insight.negativeVotes = 0;

        // Trigger new AI evaluation
        insight.aiRequestId = aiOracle.requestEvaluation(_insightId, insight.contentHash, insight.metadataURI);
        insight.status = InsightStatus.PendingAIEvaluation; // Back to initial evaluation state

        emit ChallengeInitiated(_insightId, _challenger, _stakeAmount);
    }

    // --- III. Dynamic Value & Rewards ---

    /**
     * @notice Distributes QLI rewards to the contributor and successful validators of a validated insight.
     *         Callable by anyone once validation is finalized.
     * @param _insightId The ID of the insight to distribute rewards for.
     */
    function distributeInsightRewards(uint256 _insightId)
        public
        whenNotPaused
        insightExists(_insightId)
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.ValidationFinalized, "QLIP: Insight not finalized for reward distribution.");
        
        // Calculate total rewards based on AI evaluation fee and overall performance
        uint256 totalRewardPool = AI_EVALUATION_FEE; // Initial pool from submitter's fee
        
        // Add potential bonus from losing validator stakes if finalizedValidationRound didn't transfer it directly
        // (Simplified for now, assume finalizeValidationRound handles redistribution internally)

        uint256 contributorShare = totalRewardPool * INSIGHT_REWARD_POOL_PERCENT / 10000; // e.g., 50%
        uint256 validatorShare = totalRewardPool - contributorShare;

        // Update contributor reputation based on impactScore
        contributorReputation[insight.contributor] += insight.impactScore / 100; // Example: 1 point per 100 impact score

        require(QLIToken.transfer(insight.contributor, contributorShare), "QLIP: Failed to transfer contributor reward.");

        // Validator rewards are claimable separately via claimValidationStakes

        emit InsightRewardsDistributed(_insightId, insight.contributor, contributorShare, validatorShare);
    }

    /**
     * @notice Allows validators to claim their staked QLI back after the validation round is finalized.
     *         Successful validators might receive a bonus from losing stakes.
     * @param _insightId The ID of the insight.
     */
    function claimValidationStakes(uint256 _insightId)
        public
        whenNotPaused
        insightExists(_insightId)
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.ValidationFinalized || insight.status == InsightStatus.Challenged, "QLIP: Validation not finalized or challenged.");
        
        ValidationVote storage vote = insight.validationVotes[msg.sender];
        require(vote.hasVoted, "QLIP: You did not vote on this insight.");
        require(vote.stakeAmount > 0, "QLIP: Stake already claimed or not present.");

        uint256 returnAmount = vote.stakeAmount;
        
        // Determine if validator was 'correct' relative to final outcome
        // This logic needs to be consistent with finalizeValidationRound's outcome
        bool isCorrect = (insight.humanValidationScore >= 500 && vote.isAccurate) ||
                         (insight.humanValidationScore < 500 && !vote.isAccurate);

        if (isCorrect && insight.totalValidationStake > 0) {
            // Reward bonus from protocol or losing stakes (simplified)
            // A real system would calculate this more precisely, potentially from a pool of forfeited stakes
            returnAmount += (vote.stakeAmount * 100) / insight.totalValidationStake; // Example: small bonus relative to stake
        } else {
            // If incorrect, they might lose a portion or all their stake.
            // For simplicity, they only get their stake back if correct, otherwise it's absorbed by protocol/winners.
            // This design makes 'losing' validators forfeit their stake.
            require(isCorrect, "QLIP: Your vote was incorrect, stake forfeited.");
        }

        vote.stakeAmount = 0; // Mark as claimed
        vote.hasVoted = false; // Allow re-voting if challenged again and status changes

        require(QLIToken.transfer(msg.sender, returnAmount), "QLIP: Failed to transfer stake back.");

        emit ValidationStakesClaimed(_insightId, msg.sender, returnAmount);
    }

    /**
     * @notice Periodically adjusts an insight's "impact score" based on ongoing usage, citations, etc.
     *         This function would typically be called by a decentralized oracle or a time-based automation.
     * @param _insightId The ID of the insight to recalibrate.
     * @param _externalImpactScore An external oracle-provided score (e.g., simulated citations, real-world usage).
     */
    function recalibrateInsightImpact(uint256 _insightId, uint256 _externalImpactScore)
        external
        whenNotPaused
        insightExists(_insightId)
        // This could be restricted to an 'Impact Oracle' role or a governance trigger
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.ValidationFinalized, "QLIP: Insight not finalized.");

        uint256 oldImpactScore = insight.impactScore;
        
        // Apply natural decay based on time since last recalibration
        uint256 timePassed = block.timestamp - insight.lastImpactRecalibration;
        uint256 decayAmount = (timePassed / 1 days) * IMPACT_DECAY_RATE_PER_DAY;
        if (insight.impactScore > decayAmount) {
            insight.impactScore -= decayAmount;
        } else {
            insight.impactScore = 0;
        }

        // Incorporate new external impact score (e.g., 50% current, 50% new external)
        insight.impactScore = (insight.impactScore + _externalImpactScore) / 2;
        
        // Ensure score doesn't exceed max or fall below 0
        if (insight.impactScore > 10000) insight.impactScore = 10000;
        
        insight.lastImpactRecalibration = block.timestamp;

        // Check for staleness
        if (insight.impactScore < MIN_IMPACT_SCORE_FOR_ACTIVE) {
            insight.status = InsightStatus.Stale;
        }

        emit InsightImpactRecalibrated(_insightId, oldImpactScore, insight.impactScore, _externalImpactScore);
    }

    /**
     * @notice Marks or removes insights that consistently perform poorly or are challenged/outdated.
     *         This ensures data hygiene and reduces storage burden for extremely old/irrelevant insights.
     *         Can be called by anyone for a stale insight.
     * @param _insightId The ID of the insight to burn.
     */
    function burnStaleInsights(uint256 _insightId)
        external
        whenNotPaused
        insightExists(_insightId)
    {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Stale, "QLIP: Insight is not marked as stale.");
        
        // For a public function, add a condition to prevent abuse, e.g., only after a very long time
        require(block.timestamp > insight.lastImpactRecalibration + (30 * 1 days), "QLIP: Too soon to burn stale insight.");

        // Clear sensitive or large data to save gas/storage if not completely deleting
        insight.contentHash = 0x0; // Clear the hash
        insight.metadataURI = ""; // Clear the URI
        delete insight.tags;     // Clear the array
        insight.status = InsightStatus.Stale; // Confirm status as 'burned/stale'

        // Note: For full deletion, `delete insights[_insightId];` could be used, but this impacts `_insightCounter`.
        // Marking as stale and clearing data is often preferred for auditing.
        // For actual gas refund, `delete insights[_insightId]` is needed, but this implies re-indexing insight IDs.
        // For this example, we mark it as 'Stale' and remove pointers to off-chain data.

        emit StaleInsightBurned(_insightId);
    }

    // --- IV. Reputation System ---

    /**
     * @notice Retrieves the overall reputation score of a contributor.
     *         This score is a cumulative sum based on the impact of their insights.
     * @param _contributor The address of the contributor.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributorReputation[_contributor];
    }

    /**
     * @notice Retrieves the accuracy/consistency score of a curator's past validations.
     *         This score indicates how often their votes aligned with the final outcome.
     * @param _curator The address of the curator.
     * @return The performance score.
     */
    function getCuratorPerformance(address _curator) public view returns (uint256) {
        return curatorPerformance[_curator];
    }

    // --- V. Governance & Protocol Parameters ---

    /**
     * @notice Allows users with sufficient governance token holdings to propose changes to protocol parameters.
     * @param _description A description of the proposed change.
     * @param _targetContract The address of the contract to call (e.g., this contract itself).
     * @param _callData The encoded function call data for the proposed action.
     */
    function proposeProtocolChange(string calldata _description, address _targetContract, bytes calldata _callData)
        external
        whenNotPaused
    {
        uint256 proposerVotes = governanceToken.getVotes(msg.sender);
        require(proposerVotes > 0, "QLIP: Proposer must hold governance tokens.");
        // Add a minimum vote threshold to propose

        _proposalCounter++;
        Proposal storage newProposal = proposals[_proposalCounter];
        newProposal.id = _proposalCounter;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.targetContract = _targetContract;
        newProposal.callData = _callData;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + 7 days; // Example: 7-day voting period
        newProposal.quorumRequired = governanceToken.totalSupply() / 10; // Example: 10% quorum
        newProposal.status = ProposalStatus.Active;

        emit ProposalCreated(newProposal.id, msg.sender, _description);
    }

    /**
     * @notice Allows governance token holders to vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yay', false for 'nay'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "QLIP: Proposal is not active.");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "QLIP: Voting period not open.");
        require(!proposal.hasVoted[msg.sender], "QLIP: You have already voted on this proposal.");

        uint256 voterVotes = governanceToken.getVotes(msg.sender);
        require(voterVotes > 0, "QLIP: Voter must hold governance tokens.");

        if (_support) {
            proposal.yayVotes += voterVotes;
        } else {
            proposal.nayVotes += voterVotes;
        }
        proposal.hasVoted[msg.sender] = true;

        // Check if quorum or simple majority is met
        if (proposal.yayVotes + proposal.nayVotes >= proposal.quorumRequired) {
             if (proposal.yayVotes > proposal.nayVotes) {
                 proposal.status = ProposalStatus.Succeeded;
             } else {
                 proposal.status = ProposalStatus.Failed;
             }
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes an approved and passed governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "QLIP: Proposal has not succeeded.");
        require(block.timestamp > proposal.voteEndTime, "QLIP: Voting period must be over.");
        
        proposal.status = ProposalStatus.Executed; // Mark as executed before calling external contract

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "QLIP: Proposal execution failed.");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Internal/governance-callable function to update specific protocol parameters.
     * @dev Should only be called via a successful governance proposal.
     * @param _paramName The name of the parameter to update (e.g., "MIN_VALIDATOR_STAKE").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue)
        external
        onlyOwner // Temporarily onlyOwner; in a real system, this is governance-only.
        whenNotPaused
    {
        uint256 oldValue;
        if (_paramName == "MIN_INSIGHT_STAKE") {
            oldValue = MIN_INSIGHT_STAKE;
            MIN_INSIGHT_STAKE = _newValue;
        } else if (_paramName == "MIN_VALIDATOR_STAKE") {
            oldValue = MIN_VALIDATOR_STAKE;
            MIN_VALIDATOR_STAKE = _newValue;
        } else if (_paramName == "VALIDATION_PERIOD") {
            oldValue = VALIDATION_PERIOD;
            VALIDATION_PERIOD = _newValue;
        } else if (_paramName == "AI_EVALUATION_FEE") {
            oldValue = AI_EVALUATION_FEE;
            AI_EVALUATION_FEE = _newValue;
        } else if (_paramName == "INSIGHT_REWARD_POOL_PERCENT") {
            oldValue = INSIGHT_REWARD_POOL_PERCENT;
            INSIGHT_REWARD_POOL_PERCENT = _newValue;
        } else if (_paramName == "CHALLENGE_STAKE_MULTIPLIER") {
            oldValue = CHALLENGE_STAKE_MULTIPLIER;
            CHALLENGE_STAKE_MULTIPLIER = _newValue;
        } else if (_paramName == "IMPACT_DECAY_RATE_PER_DAY") {
            oldValue = IMPACT_DECAY_RATE_PER_DAY;
            IMPACT_DECAY_RATE_PER_DAY = _newValue;
        } else if (_paramName == "MIN_IMPACT_SCORE_FOR_ACTIVE") {
            oldValue = MIN_IMPACT_SCORE_FOR_ACTIVE;
            MIN_IMPACT_SCORE_FOR_ACTIVE = _newValue;
        } else if (_paramName == "PROTOCOL_FEE_BPS") {
            oldValue = PROTOCOL_FEE_BPS;
            PROTOCOL_FEE_BPS = _newValue;
        } else {
            revert("QLIP: Unknown protocol parameter.");
        }
        emit ProtocolParameterUpdated(_paramName, oldValue, _newValue);
    }

    // --- VI. Discovery & Utility ---

    /**
     * @notice Returns a list of insight IDs associated with a given tag.
     * @param _tag The tag to search for.
     * @return An array of insight IDs matching the tag.
     */
    function searchInsightsByTag(string calldata _tag)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory taggedInsights = new uint256[](0);
        uint256 count = 0;
        // This is highly inefficient on-chain. A real Dapp would use a subgraph for this.
        for (uint256 i = 1; i <= _insightCounter; i++) {
            Insight storage insight = insights[i];
            for (uint256 j = 0; j < insight.tags.length; j++) {
                if (keccak256(abi.encodePacked(insight.tags[j])) == keccak256(abi.encodePacked(_tag))) {
                    count++;
                    break; // Found tag, move to next insight
                }
            }
        }
        taggedInsights = new uint256[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= _insightCounter; i++) {
            Insight storage insight = insights[i];
            for (uint256 j = 0; j < insight.tags.length; j++) {
                if (keccak256(abi.encodePacked(insight.tags[j])) == keccak256(abi.encodePacked(_tag))) {
                    taggedInsights[currentIdx] = i;
                    currentIdx++;
                    break;
                }
            }
        }
        return taggedInsights;
    }

    /**
     * @notice Returns the top insights ordered by their current `impactScore`.
     * @param _limit The maximum number of insights to return.
     * @return An array of insight IDs.
     */
    function getTopInsightsByImpact(uint256 _limit)
        public
        view
        returns (uint256[] memory)
    {
        // This is highly inefficient for many insights; a subgraph is necessary for real-world use.
        // For demonstration, we'll implement a basic bubble sort-like approach (very gas-intensive).
        uint256 actualLimit = _limit > _insightCounter ? _insightCounter : _limit;
        uint256[] memory topInsights = new uint256[](actualLimit);
        uint256[] memory currentImpacts = new uint256[](actualLimit);

        for (uint256 i = 1; i <= _insightCounter; i++) {
            Insight storage insight = insights[i];
            if (insight.status != InsightStatus.ValidationFinalized) continue; // Only consider finalized insights

            // Simple insertion sort to keep top N insights
            for (uint256 j = 0; j < actualLimit; j++) {
                if (insight.impactScore > currentImpacts[j]) {
                    // Shift elements down to make space
                    for (uint256 k = actualLimit - 1; k > j; k--) {
                        topInsights[k] = topInsights[k - 1];
                        currentImpacts[k] = currentImpacts[k - 1];
                    }
                    topInsights[j] = i;
                    currentImpacts[j] = insight.impactScore;
                    break;
                }
            }
        }
        return topInsights;
    }

    /**
     * @notice Allows users to stake QLI tokens towards a future research topic, creating a bounty.
     * @param _researchTopic A description of the research topic.
     * @param _amount The amount of QLI to fund the bounty with.
     */
    function fundInsightResearch(string calldata _researchTopic, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "QLIP: Bounty amount must be greater than zero.");
        require(QLIToken.transferFrom(msg.sender, address(this), _amount), "QLIP: Failed to transfer bounty funds.");

        _bountyCounter++;
        researchBounties[_bountyCounter] = ResearchBounty({
            id: _bountyCounter,
            topic: _researchTopic,
            totalAmount: _amount,
            claimedAmount: 0,
            expiryTimestamp: block.timestamp + 365 days, // Bounty expires in 1 year
            funder: msg.sender,
            claimed: false,
            insightIdClaimedBy: 0
        });

        emit ResearchBountyFunded(_bountyCounter, _researchTopic, _amount, msg.sender);
    }

    /**
     * @notice Allows a contributor to claim a research bounty by submitting an insight that meets the bounty's criteria.
     *         Requires an existing, finalized insight.
     * @param _bountyId The ID of the research bounty.
     * @param _insightId The ID of the insight to link to the bounty.
     */
    function claimResearchBounty(uint256 _bountyId, uint256 _insightId)
        external
        whenNotPaused
        insightExists(_insightId)
        nonReentrant
    {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        Insight storage insight = insights[_insightId];

        require(bounty.id > 0 && !bounty.claimed, "QLIP: Bounty does not exist or already claimed.");
        require(block.timestamp <= bounty.expiryTimestamp, "QLIP: Bounty has expired.");
        require(insight.status == InsightStatus.ValidationFinalized, "QLIP: Linked insight must be finalized.");
        require(insight.contributor == msg.sender, "QLIP: Only the insight contributor can claim.");

        // Additional checks: Does the insight content/tags meaningfully address the bounty topic?
        // This is complex for on-chain. A simple check could be: does the insight have the bounty's topic as a tag?
        // Or, more realistically, it would involve a human review committee or a more sophisticated AI oracle integration.
        // For this example, we'll assume the contributor self-attests and social consensus handles disputes.
        bool topicMatch = false;
        bytes32 bountyTopicHash = keccak256(abi.encodePacked(bounty.topic));
        for (uint256 i = 0; i < insight.tags.length; i++) {
            if (keccak256(abi.encodePacked(insight.tags[i])) == bountyTopicHash) {
                topicMatch = true;
                break;
            }
        }
        require(topicMatch, "QLIP: Insight does not match bounty topic tag.");
        require(insight.impactScore >= MIN_IMPACT_SCORE_FOR_ACTIVE, "QLIP: Insight must have sufficient impact score.");

        uint256 amountToClaim = bounty.totalAmount - bounty.claimedAmount; // In case of partial claims (not implemented here)
        require(amountToClaim > 0, "QLIP: No remaining bounty amount to claim.");

        bounty.claimed = true;
        bounty.claimedAmount = bounty.totalAmount;
        bounty.insightIdClaimedBy = _insightId;

        require(QLIToken.transfer(msg.sender, amountToClaim), "QLIP: Failed to transfer bounty reward.");

        emit ResearchBountyClaimed(_bountyId, _insightId, msg.sender);
    }

    // --- VII. Access Control & System Management ---

    /**
     * @notice Pauses the protocol's core functionality. Only callable by the owner (or governance).
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the protocol's core functionality. Only callable by the owner (or governance).
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner (or governance) to update the address of the AI Oracle.
     * @param _newOracle The new address of the AI Oracle contract.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "QLIP: New AI Oracle address cannot be zero.");
        aiOracle = IAIOracle(_newOracle);
    }

    // --- Fallback & Receive ---
    receive() external payable {
        revert("QLIP: Contract does not accept direct ETH transfers. Only QLI tokens.");
    }

    fallback() external payable {
        revert("QLIP: Fallback not implemented. Call specific functions.");
    }
}
```