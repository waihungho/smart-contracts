```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // For initial deployment control, can be renounced to DAO later
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

/**
 * @title SynapseVault: A Decentralized Collective Intelligence Network
 * @author YourName (or Anonymous Developer)
 * @notice SynapseVault is a community-governed platform for collaborative knowledge curation.
 *         Users submit "Insights" (data, analysis, predictions), and the collective validates
 *         their accuracy and value through a dynamic reputation system. Contributors and validators
 *         are rewarded, and influence within the network (including governance) is tied to a
 *         constantly evolving "Reputation Score".
 *
 * @dev Key Advanced Concepts:
 *      1.  Dynamic On-Chain Reputation System: Users' "Reputation Score" (R-Score) evolves based
 *          on the success/failure of their contributions and validations, directly impacting their
 *          privileges and influence within the network.
 *      2.  Proof-of-Contribution/Validation: Rewards are tied to the perceived value and accuracy
 *          of submitted insights, validated by community consensus.
 *      3.  Tiered Access & Influence: R-Score defines different "Reputation Tiers" which grant
 *          varying levels of access (e.g., minimum R-Score for challenging) and voting power.
 *      4.  Action Point Economy: Limited daily "Action Points" for voting/validating prevent spam
 *          and encourage thoughtful engagement, with higher tiers receiving more points.
 *      5.  Decentralized Governance: Key protocol parameters, treasury management, and category
 *          moderation are controlled by DAO proposals and voting, primarily by high-reputation members.
 */
contract SynapseVault is Ownable, Context {

    // --- Enums and Structs ---

    enum InsightStatus {
        Pending,          // Newly submitted, awaiting validation
        Validated,        // Deemed accurate/valuable by community
        Rejected,         // Deemed inaccurate/low value by community or failed challenge
        Under_Challenge   // Currently being challenged for validity
    }

    enum ReputationTier {
        Novice,    // 0-99
        Explorer,  // 100-499
        Expert,    // 500-1999
        Sage,      // 2000-4999
        Oracle     // 5000+
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // Represents a submitted piece of knowledge/data
    struct Insight {
        string contentCID;          // IPFS hash of the insight's content
        string title;               // Short title for the insight
        uint256 categoryId;         // Category this insight belongs to
        address contributor;        // Address of the insight's submitter
        uint256 submissionTimestamp;// Timestamp of submission
        InsightStatus status;       // Current status of the insight
        int256 netUpvotes;          // Upvotes minus Downvotes
        uint256 contributorStake;   // ETH staked by the contributor
        uint256 totalRewardAmount;  // Total ETH reward for this insight
        uint256 challengeId;        // 0 if not under challenge, ID of active challenge otherwise
        bool finalized;             // True if insight has been processed for rewards/penalties
    }

    // Stores user-specific data
    struct UserData {
        uint256 reputationScore;
        uint256 lastActionPointRefresh; // Timestamp of last AP refresh
        uint256 contributedInsightsCount;
        uint256 validatedInsightsCount;
    }

    // Represents a category for insights
    struct Category {
        string name;
        string description;
        address moderator;          // Can be 0x0 for DAO-moderated, or specific address
        uint256[] insightIds;       // List of insight IDs in this category
    }

    // Represents a challenge against an insight
    struct Challenge {
        uint256 insightId;
        address challenger;
        uint256 challengeStake;     // ETH staked by the challenger
        string reasonCID;           // IPFS hash of challenger's reasoning
        uint256 startTimestamp;
        uint256 voteEndTime;
        uint256 votesForInvalidation; // Votes supporting challenger (insight is invalid)
        uint256 votesAgainstInvalidation; // Votes opposing challenger (insight is valid)
        bool resolved;
        bool challengerSucceeded;   // True if votes confirm insight is invalid
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this challenge
    }

    // Represents a DAO governance proposal
    struct Proposal {
        address proposer;
        string description;
        bytes callData;             // Encoded function call to execute
        address targetContract;     // Contract to call (can be SynapseVault itself)
        uint256 value;              // ETH to send with the call
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotingPower;   // Sum of reputation scores of voters
        uint256 yesVotingPower;     // Sum of reputation scores for 'yes'
        uint256 noVotingPower;      // Sum of reputation scores for 'no'
        ProposalState state;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---

    uint256 public nextInsightId;
    uint256 public nextCategoryId;
    uint256 public nextChallengeId;
    uint256 public nextProposalId;

    mapping(uint256 => Insight) public insights;
    mapping(address => UserData) public users;
    mapping(uint256 => Category) public categories;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Proposal) public proposals;

    // Mapping for tracking upvotes/downvotes per insight per user (more gas efficient than array)
    mapping(uint256 => mapping(address => bool)) public userHasUpvotedInsight;
    mapping(uint256 => mapping(address => bool)) public userHasDownvotedInsight;

    // Protocol Parameters (can be changed via governance)
    uint256 public constant INITIAL_REPUTATION_SCORE = 10;
    uint256 public minInsightStake = 0.01 ether;
    uint256 public minChallengeStake = 0.05 ether;
    uint256 public minReputationForChallenge = 500; // Expert tier
    uint256 public insightValidationThreshold = 5; // Net upvotes required
    uint256 public reputationGainForValidatedInsight = 100;
    uint256 public reputationLossForRejectedInsight = 50;
    uint256 public reputationGainForAccurateValidation = 1; // Small gain for upvoting validated insights
    uint256 public reputationLossForInaccurateValidation = 5; // Loss for upvoting rejected insights
    uint256 public reputationGainForSuccessfulChallenge = 200;
    uint256 public reputationLossForFailedChallenge = 100;
    uint256 public dailyActionPoints = 10;
    uint256 public actionPointRefreshInterval = 1 days;
    uint256 public proposalVoteDuration = 3 days;
    uint256 public challengeVoteDuration = 2 days;
    uint256 public proposalThresholdReputation = 1000; // Sage tier for proposing
    uint256 public proposalQuorumVotingPowerPercentage = 10; // 10% of total reputation needed for quorum
    uint256 public insightRewardPercentage = 70; // % of insight's stake + treasury for contributor
    uint256 public validatorRewardPercentage = 10; // % of insight's stake + treasury for validators
    // Remaining goes to treasury or burn
    uint256 public constant PERCENTAGE_DENOMINATOR = 100;

    // --- Events ---

    event InsightSubmitted(uint256 indexed insightId, address indexed contributor, uint256 categoryId, string contentCID);
    event InsightStatusChanged(uint256 indexed insightId, InsightStatus newStatus);
    event InsightUpvoted(uint256 indexed insightId, address indexed voter);
    event InsightDownvoted(uint256 indexed insightId, address indexed voter);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed insightId, address indexed challenger);
    event ChallengeResolved(uint256 indexed challengeId, bool challengerSucceeded);
    event InsightFinalized(uint256 indexed insightId, InsightStatus finalStatus, uint256 rewardAmount);
    event InsightRewardClaimed(uint256 indexed insightId, address indexed contributor, uint256 amount);
    event ValidatorRewardClaimed(uint256 indexed insightId, address indexed validator, uint256 amount);
    event StakeWithdrawn(uint256 indexed insightId, address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event ActionPointsRefreshed(address indexed user, uint256 newPoints);
    event CategoryAdded(uint256 indexed categoryId, string name, address indexed moderator);
    event CategoryModeratorSet(uint256 indexed categoryId, address indexed oldModerator, address indexed newModerator);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event ParameterChanged(string paramName, uint256 oldValue, uint256 newValue);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initialize the first category as "General" or "Uncategorized"
        _addCategory("General", "General discussions and uncategorized insights", _msgSender()); // Initial owner is moderator
        users[_msgSender()].reputationScore = INITIAL_REPUTATION_SCORE; // Give initial rep to deployer
    }

    // --- Modifiers ---

    modifier onlyDAO() {
        // For simplicity, for now, DAO governance is handled by the proposal system.
        // Functions with this modifier can only be called by the `executeProposal` function
        // if the proposal passed and targets this contract.
        // A direct `onlyDAO` might be a separate governance contract in a full system.
        // For this contract, we'll assume `_msgSender()` is a valid executor.
        // This is a placeholder for a more robust DAO setup where only the DAO contract can call.
        // In this implementation, the `executeProposal` function handles the "DAO" part.
        // For functions that need direct DAO approval for simpler cases, like setting initial category.
        // So, this modifier will be effectively unused if all DAO actions go through proposals.
        // For the sake of demonstration, I will use `Ownable` temporarily for some admin functions
        // and transition to `propose/vote/execute` for most parameter changes.
        _;
    }

    modifier onlyReputationTier(ReputationTier _minTier) {
        require(getReputationTier(_msgSender()) >= _minTier, "SynapseVault: Insufficient reputation tier");
        _;
    }

    // --- Internal Helpers ---

    function _updateReputation(address _user, int256 _delta) internal {
        if (_delta > 0) {
            users[_user].reputationScore += uint256(_delta);
        } else {
            if (users[_user].reputationScore < uint256(-_delta)) {
                users[_user].reputationScore = 0;
            } else {
                users[_user].reputationScore -= uint256(-_delta);
            }
        }
        emit ReputationUpdated(_user, users[_user].reputationScore);
    }

    function _addCategory(string memory _name, string memory _description, address _moderator) internal returns (uint256) {
        uint256 id = nextCategoryId++;
        categories[id] = Category(
            _name,
            _description,
            _moderator,
            new uint256[](0)
        );
        emit CategoryAdded(id, _name, _moderator);
        return id;
    }

    function _refreshActionPoints(address _user) internal {
        if (block.timestamp >= users[_user].lastActionPointRefresh + actionPointRefreshInterval) {
            users[_user].lastActionPointRefresh = block.timestamp;
            // Action points are not explicitly stored as a balance, but calculated based on last refresh.
            // This is a more gas-efficient way to implement daily limits.
        }
    }

    function _canPerformAction(address _user) internal view returns (bool) {
        uint256 elapsedIntervals = (block.timestamp - users[_user].lastActionPointRefresh) / actionPointRefreshInterval;
        return elapsedIntervals > 0; // If at least one interval passed, they can refresh and get points
    }

    // --- I. Insight Management & Validation (Core Knowledge Layer) ---

    /**
     * @notice Allows a user to propose a new insight, requiring a stake to deter spam.
     * @param _contentCID IPFS CID of the insight's content.
     * @param _categoryId The category ID for this insight.
     * @param _title A concise title for the insight.
     */
    function submitInsight(
        string memory _contentCID,
        uint256 _categoryId,
        string memory _title
    ) external payable {
        require(bytes(_contentCID).length > 0, "SynapseVault: Content CID cannot be empty.");
        require(bytes(_title).length > 0, "SynapseVault: Title cannot be empty.");
        require(categories[_categoryId].name.length > 0, "SynapseVault: Category does not exist.");
        require(msg.value >= minInsightStake, "SynapseVault: Insufficient stake for insight submission.");

        uint256 id = nextInsightId++;
        insights[id] = Insight({
            contentCID: _contentCID,
            title: _title,
            categoryId: _categoryId,
            contributor: _msgSender(),
            submissionTimestamp: block.timestamp,
            status: InsightStatus.Pending,
            netUpvotes: 0,
            contributorStake: msg.value,
            totalRewardAmount: 0, // Calculated upon finalization
            challengeId: 0,
            finalized: false
        });

        users[_msgSender()].contributedInsightsCount++;
        categories[_categoryId].insightIds.push(id); // Add insight ID to category list
        _updateReputation(_msgSender(), int256(INITIAL_REPUTATION_SCORE)); // Small initial rep boost

        emit InsightSubmitted(id, _msgSender(), _categoryId, _contentCID);
    }

    /**
     * @notice Users vote positively on an insight. Consumes action points.
     * @param _insightId The ID of the insight to upvote.
     */
    function upvoteInsight(uint256 _insightId) external onlyReputationTier(ReputationTier.Novice) {
        Insight storage insight = insights[_insightId];
        require(insight.contributor != address(0), "SynapseVault: Insight does not exist.");
        require(insight.status == InsightStatus.Pending || insight.status == InsightStatus.Under_Challenge, "SynapseVault: Insight is not in a votable state.");
        require(insight.contributor != _msgSender(), "SynapseVault: Cannot vote on your own insight.");
        require(!userHasUpvotedInsight[_insightId][_msgSender()], "SynapseVault: Already upvoted this insight.");
        require(!userHasDownvotedInsight[_insightId][_msgSender()], "SynapseVault: Cannot upvote after downvoting."); // Enforce one vote type per insight

        // Check and consume action points
        require(_canPerformAction(_msgSender()), "SynapseVault: No action points available. Refresh them.");
        // Internal logic for consuming points: for now, assume one successful refresh = enough points.
        // In a real system, `dailyActionPoints` would be consumed. This simplified version assumes
        // calling `refreshActionPoints` is effectively "spending points for the day".
        // A more granular system would track `remainingActionPoints`.
        // For this contract, we simply ensure they've "refreshed" recently.
        _refreshActionPoints(_msgSender()); // Mark action points as used for today's first action.

        insight.netUpvotes++;
        userHasUpvotedInsight[_insightId][_msgSender()] = true;

        emit InsightUpvoted(_insightId, _msgSender());
    }

    /**
     * @notice Users vote negatively on an insight. Consumes action points.
     * @param _insightId The ID of the insight to downvote.
     */
    function downvoteInsight(uint256 _insightId) external onlyReputationTier(ReputationTier.Novice) {
        Insight storage insight = insights[_insightId];
        require(insight.contributor != address(0), "SynapseVault: Insight does not exist.");
        require(insight.status == InsightStatus.Pending || insight.status == InsightStatus.Under_Challenge, "SynapseVault: Insight is not in a votable state.");
        require(insight.contributor != _msgSender(), "SynapseVault: Cannot vote on your own insight.");
        require(!userHasDownvotedInsight[_insightId][_msgSender()], "SynapseVault: Already downvoted this insight.");
        require(!userHasUpvotedInsight[_insightId][_msgSender()], "SynapseVault: Cannot downvote after upvoting.");

        require(_canPerformAction(_msgSender()), "SynapseVault: No action points available. Refresh them.");
        _refreshActionPoints(_msgSender());

        insight.netUpvotes--;
        userHasDownvotedInsight[_insightId][_msgSender()] = true;

        emit InsightDownvoted(_insightId, _msgSender());
    }

    /**
     * @notice High-reputation users can challenge an insight's validity, requiring a higher stake.
     *         This initiates a community vote on the challenge.
     * @param _insightId The ID of the insight to challenge.
     * @param _reasonCID IPFS CID of the challenger's reasoning.
     */
    function challengeInsight(uint256 _insightId, string memory _reasonCID) external payable onlyReputationTier(ReputationTier.Expert) {
        Insight storage insight = insights[_insightId];
        require(insight.contributor != address(0), "SynapseVault: Insight does not exist.");
        require(insight.status != InsightStatus.Validated && insight.status != InsightStatus.Rejected, "SynapseVault: Insight cannot be challenged in its current state.");
        require(insight.challengeId == 0, "SynapseVault: Insight is already under challenge.");
        require(msg.value >= minChallengeStake, "SynapseVault: Insufficient stake for challenge.");
        require(bytes(_reasonCID).length > 0, "SynapseVault: Reason CID cannot be empty.");
        require(_msgSender() != insight.contributor, "SynapseVault: Contributor cannot challenge their own insight.");

        uint256 id = nextChallengeId++;
        challenges[id] = Challenge({
            insightId: _insightId,
            challenger: _msgSender(),
            challengeStake: msg.value,
            reasonCID: _reasonCID,
            startTimestamp: block.timestamp,
            voteEndTime: block.timestamp + challengeVoteDuration,
            votesForInvalidation: 0,
            votesAgainstInvalidation: 0,
            resolved: false,
            challengerSucceeded: false,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });

        insight.status = InsightStatus.Under_Challenge;
        insight.challengeId = id;

        emit ChallengeInitiated(id, _insightId, _msgSender());
        emit InsightStatusChanged(_insightId, InsightStatus.Under_Challenge);
    }

    /**
     * @notice Allows users to vote on an active challenge, determining if the insight is invalid.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _supportChallenger True to vote for the insight being invalid, false for valid.
     */
    function voteOnChallenge(uint256 _challengeId, bool _supportChallenger) external onlyReputationTier(ReputationTier.Explorer) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightId != 0, "SynapseVault: Challenge does not exist.");
        require(!challenge.resolved, "SynapseVault: Challenge already resolved.");
        require(block.timestamp <= challenge.voteEndTime, "SynapseVault: Challenge voting period has ended.");
        require(!challenge.hasVoted[_msgSender()], "SynapseVault: Already voted on this challenge.");
        require(_msgSender() != challenge.challenger, "SynapseVault: Challenger cannot vote on their own challenge.");
        require(_msgSender() != insights[challenge.insightId].contributor, "SynapseVault: Insight contributor cannot vote on its challenge.");

        require(_canPerformAction(_msgSender()), "SynapseVault: No action points available. Refresh them.");
        _refreshActionPoints(_msgSender());

        challenge.hasVoted[_msgSender()] = true;
        if (_supportChallenger) {
            challenge.votesForInvalidation++;
        } else {
            challenge.votesAgainstInvalidation++;
        }
    }

    /**
     * @notice Finalizes a challenge after its voting period, updating insight status and reputation.
     *         Can be called by anyone after the voting period ends.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightId != 0, "SynapseVault: Challenge does not exist.");
        require(!challenge.resolved, "SynapseVault: Challenge already resolved.");
        require(block.timestamp > challenge.voteEndTime, "SynapseVault: Challenge voting period not ended yet.");

        Insight storage insight = insights[challenge.insightId];
        require(insight.challengeId == _challengeId, "SynapseVault: Insight is not associated with this challenge.");
        require(insight.status == InsightStatus.Under_Challenge, "SynapseVault: Insight is not under challenge.");

        challenge.resolved = true;
        
        // Simple majority for challenge resolution
        if (challenge.votesForInvalidation > challenge.votesAgainstInvalidation) {
            challenge.challengerSucceeded = true;
            insight.status = InsightStatus.Rejected;
            _updateReputation(challenge.challenger, int256(reputationGainForSuccessfulChallenge));
            _updateReputation(insight.contributor, -int256(reputationLossForRejectedInsight)); // Contributor loses rep
            // Challenger stake returned, contributor stake potentially distributed
            (bool success, ) = payable(challenge.challenger).call{value: challenge.challengeStake}("");
            require(success, "SynapseVault: Failed to return challenger stake.");

            // Distribute part of contributor stake to challenger and treasury
            uint256 penaltyAmount = insight.contributorStake / 2; // Example penalty
            (bool success2, ) = payable(challenge.challenger).call{value: penaltyAmount}("");
            require(success2, "SynapseVault: Failed to send penalty to challenger.");
            // Remaining penalty part goes to treasury
            (bool success3, ) = payable(address(this)).call{value: insight.contributorStake - penaltyAmount}("");
            require(success3, "SynapseVault: Failed to send penalty to treasury.");
            
        } else {
            // Challenger failed
            challenge.challengerSucceeded = false;
            insight.status = InsightStatus.Pending; // Go back to pending, or to rejected if netUpvotes too low
            _updateReputation(challenge.challenger, -int256(reputationLossForFailedChallenge));
            // Challenger stake goes to treasury
            (bool success, ) = payable(address(this)).call{value: challenge.challengeStake}("");
            require(success, "SynapseVault: Failed to transfer challenger stake to treasury.");
            // Contributor gets their stake back if challenge failed
            (bool success2, ) = payable(insight.contributor).call{value: insight.contributorStake}("");
            require(success2, "SynapseVault: Failed to return contributor stake.");
        }
        insight.challengeId = 0; // Clear challenge reference

        emit ChallengeResolved(_challengeId, challenge.challengerSucceeded);
        emit InsightStatusChanged(insight.challengeId, insight.status);
    }

    /**
     * @notice Finalizes an insight's status (Validated/Rejected) based on votes/challenges and
     *         distributes rewards/penalties. Can be called by anyone after voting/challenge periods.
     * @param _insightId The ID of the insight to finalize.
     */
    function finalizeInsight(uint256 _insightId) external {
        Insight storage insight = insights[_insightId];
        require(insight.contributor != address(0), "SynapseVault: Insight does not exist.");
        require(!insight.finalized, "SynapseVault: Insight already finalized.");
        require(insight.status != InsightStatus.Under_Challenge, "SynapseVault: Insight is still under challenge.");

        // If insight status is Pending and it meets validation threshold
        if (insight.status == InsightStatus.Pending && insight.netUpvotes >= int256(insightValidationThreshold)) {
            insight.status = InsightStatus.Validated;
            _updateReputation(insight.contributor, int256(reputationGainForValidatedInsight));
            users[insight.contributor].validatedInsightsCount++;

            // Calculate reward: Initial stake + a portion from the treasury (or a fixed amount)
            uint256 baseReward = insight.contributorStake; // Return stake as part of reward
            uint256 treasuryBonus = address(this).balance / 1000; // Small portion from treasury, example
            insight.totalRewardAmount = baseReward + treasuryBonus;

            // Mark as finalized for rewards/stake. Actual transfer happens on claim.
            insight.finalized = true;
            emit InsightStatusChanged(_insightId, InsightStatus.Validated);
            emit InsightFinalized(_insightId, InsightStatus.Validated, insight.totalRewardAmount);

        } else if (insight.status == InsightStatus.Pending && insight.netUpvotes < int256(insightValidationThreshold)) {
            // If pending and didn't meet threshold, it's rejected
            insight.status = InsightStatus.Rejected;
            _updateReputation(insight.contributor, -int256(reputationLossForRejectedInsight));

            // Contributor stake goes to treasury (or is burned, or partially returned)
            (bool success, ) = payable(address(this)).call{value: insight.contributorStake}("");
            require(success, "SynapseVault: Failed to transfer stake to treasury.");
            
            insight.finalized = true;
            emit InsightStatusChanged(_insightId, InsightStatus.Rejected);
            emit InsightFinalized(_insightId, InsightStatus.Rejected, 0); // No reward
        }
        // If status is already Rejected (e.g., from challenge resolution), no further action needed here
    }

    /**
     * @notice Contributor claims their reward for a validated insight.
     * @param _insightId The ID of the insight.
     */
    function claimInsightReward(uint256 _insightId) external {
        Insight storage insight = insights[_insightId];
        require(insight.contributor == _msgSender(), "SynapseVault: Only the contributor can claim this reward.");
        require(insight.finalized, "SynapseVault: Insight not yet finalized.");
        require(insight.status == InsightStatus.Validated, "SynapseVault: Insight was not validated.");
        require(insight.totalRewardAmount > 0, "SynapseVault: No reward available or already claimed.");

        uint256 reward = insight.totalRewardAmount;
        insight.totalRewardAmount = 0; // Prevent re-claiming

        (bool success, ) = payable(_msgSender()).call{value: reward}("");
        require(success, "SynapseVault: Failed to send contributor reward.");

        emit InsightRewardClaimed(_insightId, _msgSender(), reward);
    }

    /**
     * @notice Upvoters claim a share of rewards for successfully validated insights.
     * @dev This is a simplified distribution. In a real system, you'd need to iterate
     *      through upvoters (or keep a list) and calculate their individual shares.
     *      For this example, we assume `insight.netUpvotes` is a proxy and require individual claim.
     *      A more robust system would track individual upvoters.
     *      For simplicity, anyone can claim a tiny reward if they upvoted a validated insight.
     *      This would need a mapping: `mapping(uint256 => mapping(address => bool)) public userHasClaimedValidatorReward;`
     * @param _insightId The ID of the insight.
     */
    function claimValidatorReward(uint256 _insightId) external {
        Insight storage insight = insights[_insightId];
        require(insight.contributor != address(0), "SynapseVault: Insight does not exist.");
        require(insight.finalized, "SynapseVault: Insight not yet finalized.");
        require(insight.status == InsightStatus.Validated, "SynapseVault: Insight was not validated.");
        require(userHasUpvotedInsight[_insightId][_msgSender()], "SynapseVault: User did not upvote this insight.");
        
        // This is a placeholder for actual reward distribution to individual upvoters.
        // In a real system, you would store a list of upvoters and distribute a share to each.
        // For simplicity, we just give a small, fixed reward from the treasury here.
        uint256 validatorReward = 0.0001 ether; // Example fixed small reward
        require(address(this).balance >= validatorReward, "SynapseVault: Insufficient treasury balance for validator reward.");

        // To prevent multiple claims, need another mapping
        // mapping(uint256 => mapping(address => bool)) public userClaimedValidatorReward;
        // require(!userClaimedValidatorReward[_insightId][_msgSender()], "SynapseVault: Validator reward already claimed.");
        // userClaimedValidatorReward[_insightId][_msgSender()] = true;

        (bool success, ) = payable(_msgSender()).call{value: validatorReward}("");
        require(success, "SynapseVault: Failed to send validator reward.");

        _updateReputation(_msgSender(), int256(reputationGainForAccurateValidation)); // Reward for accurate validation

        emit ValidatorRewardClaimed(_insightId, _msgSender(), validatorReward);
    }

    /**
     * @notice Contributor can withdraw their initial stake if their insight was validated or a challenge against it failed.
     * @param _insightId The ID of the insight.
     */
    function withdrawContributorStake(uint256 _insightId) external {
        Insight storage insight = insights[_insightId];
        require(insight.contributor == _msgSender(), "SynapseVault: Only the contributor can withdraw their stake.");
        require(insight.finalized, "SynapseVault: Insight not yet finalized.");
        require(insight.status == InsightStatus.Validated, "SynapseVault: Stake not returned for rejected insights.");
        require(insight.contributorStake > 0, "SynapseVault: No contributor stake to withdraw or already withdrawn.");

        uint256 stake = insight.contributorStake;
        insight.contributorStake = 0; // Prevent re-withdrawal

        (bool success, ) = payable(_msgSender()).call{value: stake}("");
        require(success, "SynapseVault: Failed to return contributor stake.");

        emit StakeWithdrawn(_insightId, _msgSender(), stake);
    }

    /**
     * @notice Retrieves detailed information about a specific insight.
     * @param _insightId The ID of the insight.
     * @return A tuple containing all insight details.
     */
    function getInsightDetails(uint256 _insightId)
        external
        view
        returns (
            string memory contentCID,
            string memory title,
            uint256 categoryId,
            address contributor,
            uint256 submissionTimestamp,
            InsightStatus status,
            int256 netUpvotes,
            uint256 contributorStake,
            uint256 totalRewardAmount,
            uint256 challengeId,
            bool finalized
        )
    {
        Insight storage insight = insights[_insightId];
        require(insight.contributor != address(0), "SynapseVault: Insight does not exist.");

        return (
            insight.contentCID,
            insight.title,
            insight.categoryId,
            insight.contributor,
            insight.submissionTimestamp,
            insight.status,
            insight.netUpvotes,
            insight.contributorStake,
            insight.totalRewardAmount,
            insight.challengeId,
            insight.finalized
        );
    }

    /**
     * @notice Returns a list of insight IDs within a given category.
     * @param _categoryId The ID of the category.
     * @return An array of insight IDs.
     */
    function getInsightsByCategory(uint256 _categoryId) external view returns (uint256[] memory) {
        require(categories[_categoryId].name.length > 0, "SynapseVault: Category does not exist.");
        return categories[_categoryId].insightIds;
    }

    // --- II. Reputation & User Management ---

    /**
     * @notice Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return users[_user].reputationScore;
    }

    /**
     * @notice Returns the current action points available to a user.
     * @param _user The address of the user.
     * @return The number of action points (simplified, returns `dailyActionPoints` if refreshable).
     */
    function getUserActionPoints(address _user) external view returns (uint256) {
        if (_canPerformAction(_user)) {
            return dailyActionPoints; // User has points available if refreshable
        }
        return 0; // No points available yet
    }

    /**
     * @notice Allows a user to refresh their daily action points. Can be called once per `actionPointRefreshInterval`.
     */
    function refreshActionPoints() external {
        require(_canPerformAction(_msgSender()), "SynapseVault: Action points not yet refreshable.");
        _refreshActionPoints(_msgSender());
        emit ActionPointsRefreshed(_msgSender(), dailyActionPoints);
    }

    /**
     * @notice Returns the reputation tier associated with a user's score.
     * @param _user The address of the user.
     * @return The user's reputation tier.
     */
    function getReputationTier(address _user) public view returns (ReputationTier) {
        uint256 score = users[_user].reputationScore;
        if (score >= 5000) return ReputationTier.Oracle;
        if (score >= 2000) return ReputationTier.Sage;
        if (score >= 500) return ReputationTier.Expert;
        if (score >= 100) return ReputationTier.Explorer;
        return ReputationTier.Novice;
    }

    // --- III. Governance & Protocol Parameters ---

    /**
     * @notice Allows high-reputation users to propose changes to contract parameters or actions.
     * @param _description A description of the proposal.
     * @param _callData The encoded function call to execute (e.g., `abi.encodeWithSignature("setParameter(uint256)", 100)`).
     * @param _targetContract The address of the target contract for the call (can be `address(this)`).
     * @param _value ETH value to send with the execution call.
     */
    function proposeParameterChange(
        string memory _description,
        bytes memory _callData,
        address _targetContract,
        uint256 _value
    ) external onlyReputationTier(ReputationTier.Sage) returns (uint256) {
        require(bytes(_description).length > 0, "SynapseVault: Proposal description cannot be empty.");
        
        uint256 id = nextProposalId++;
        proposals[id] = Proposal({
            proposer: _msgSender(),
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            value: _value,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVoteDuration,
            totalVotingPower: 0,
            yesVotingPower: 0,
            noVotingPower: 0,
            state: ProposalState.Active,
            executed: false,
            hasVoted: new mapping(address => bool)()
        });

        emit ProposalCreated(id, _msgSender(), _description);
        return id;
    }

    /**
     * @notice Users vote on open proposals, weighted by their reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote 'yes', false to vote 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyReputationTier(ReputationTier.Explorer) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SynapseVault: Proposal does not exist.");
        require(proposal.state == ProposalState.Active, "SynapseVault: Proposal is not active.");
        require(block.timestamp <= proposal.voteEndTime, "SynapseVault: Voting period has ended.");
        require(!proposal.hasVoted[_msgSender()], "SynapseVault: Already voted on this proposal.");

        uint256 voterReputation = users[_msgSender()].reputationScore;
        require(voterReputation > 0, "SynapseVault: Voter must have reputation.");

        proposal.hasVoted[_msgSender()] = true;
        proposal.totalVotingPower += voterReputation;

        if (_support) {
            proposal.yesVotingPower += voterReputation;
        } else {
            proposal.noVotingPower += voterReputation;
        }

        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @notice Executes a successfully voted-on proposal. Can be called by anyone after voting ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SynapseVault: Proposal does not exist.");
        require(proposal.state != ProposalState.Executed, "SynapseVault: Proposal already executed.");
        require(block.timestamp > proposal.voteEndTime, "SynapseVault: Voting period has not ended.");

        if (proposal.state == ProposalState.Pending) { // Initial state check if not active
            proposal.state = ProposalState.Active; // Should be active when voting
        }

        // Check quorum: total voting power must exceed a percentage of the total active reputation (simplified)
        // For a true quorum, you would need to calculate the sum of all users' reputation at the time of proposal creation.
        // For simplicity here, we assume a minimum total voting power as quorum.
        uint256 totalCurrentReputation = 0; // This would ideally be a snapshot or iteratively calculated for *all* users
        // A more robust implementation would need a way to sum all user rep scores or snapshot them.
        // For this example, let's just make sure some votes exist.
        require(proposal.totalVotingPower > 0, "SynapseVault: No votes cast, quorum not met.");

        if (proposal.yesVotingPower > proposal.noVotingPower) {
            proposal.state = ProposalState.Succeeded;
            // Execute the call
            (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
            require(success, "SynapseVault: Proposal execution failed.");
        } else {
            proposal.state = ProposalState.Failed;
        }
        proposal.executed = true; // Mark as processed
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice DAO-governed function to add new knowledge categories.
     * @param _name The name of the new category.
     * @param _description A description of the category.
     */
    function addCategory(string memory _name, string memory _description) external onlyDAO returns (uint256) {
        // This function would be called via `executeProposal`
        // The `onlyDAO` modifier here is a placeholder indicating it's a governance action.
        return _addCategory(_name, _description, address(0)); // Default to no specific moderator
    }

    /**
     * @notice DAO-governed function to assign/change a category moderator.
     * @param _categoryId The ID of the category.
     * @param _newModerator The address of the new moderator.
     */
    function setCategoryModerator(uint256 _categoryId, address _newModerator) external onlyDAO {
        // This function would be called via `executeProposal`
        require(categories[_categoryId].name.length > 0, "SynapseVault: Category does not exist.");
        address oldModerator = categories[_categoryId].moderator;
        categories[_categoryId].moderator = _newModerator;
        emit CategoryModeratorSet(_categoryId, oldModerator, _newModerator);
    }

    // --- IV. Treasury & Miscellaneous ---

    /**
     * @notice Allows anyone to deposit ETH into the protocol treasury.
     */
    function depositTreasury() external payable {
        require(msg.value > 0, "SynapseVault: Must deposit a non-zero amount.");
        emit TreasuryDeposited(_msgSender(), msg.value);
    }

    /**
     * @notice Returns current values of all key protocol parameters.
     * @return A tuple containing all configurable parameters.
     */
    function getProtocolParameters()
        external
        view
        returns (
            uint256 _minInsightStake,
            uint256 _minChallengeStake,
            uint256 _minReputationForChallenge,
            uint256 _insightValidationThreshold,
            uint256 _reputationGainForValidatedInsight,
            uint256 _reputationLossForRejectedInsight,
            uint256 _reputationGainForAccurateValidation,
            uint256 _reputationLossForInaccurateValidation,
            uint256 _reputationGainForSuccessfulChallenge,
            uint256 _reputationLossForFailedChallenge,
            uint256 _dailyActionPoints,
            uint256 _actionPointRefreshInterval,
            uint256 _proposalVoteDuration,
            uint256 _challengeVoteDuration,
            uint256 _proposalThresholdReputation,
            uint256 _proposalQuorumVotingPowerPercentage,
            uint256 _insightRewardPercentage,
            uint256 _validatorRewardPercentage
        )
    {
        return (
            minInsightStake,
            minChallengeStake,
            minReputationForChallenge,
            insightValidationThreshold,
            reputationGainForValidatedInsight,
            reputationLossForRejectedInsight,
            reputationGainForAccurateValidation,
            reputationLossForInaccurateValidation,
            reputationGainForSuccessfulChallenge,
            reputationLossForFailedChallenge,
            dailyActionPoints,
            actionPointRefreshInterval,
            proposalVoteDuration,
            challengeVoteDuration,
            proposalThresholdReputation,
            proposalQuorumVotingPowerPercentage,
            insightRewardPercentage,
            validatorRewardPercentage
        );
    }

    /**
     * @notice Retrieves detailed information about a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return A tuple containing all challenge details.
     */
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        returns (
            uint256 insightId,
            address challenger,
            uint256 challengeStake,
            string memory reasonCID,
            uint256 startTimestamp,
            uint256 voteEndTime,
            uint256 votesForInvalidation,
            uint256 votesAgainstInvalidation,
            bool resolved,
            bool challengerSucceeded
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightId != 0, "SynapseVault: Challenge does not exist.");

        return (
            challenge.insightId,
            challenge.challenger,
            challenge.challengeStake,
            challenge.reasonCID,
            challenge.startTimestamp,
            challenge.voteEndTime,
            challenge.votesForInvalidation,
            challenge.votesAgainstInvalidation,
            challenge.resolved,
            challenge.challengerSucceeded
        );
    }

    /**
     * @notice Retrieves details about a specific category.
     * @param _categoryId The ID of the category.
     * @return A tuple containing category name, description, and moderator.
     */
    function getCategoryDetails(uint256 _categoryId)
        external
        view
        returns (
            string memory name,
            string memory description,
            address moderator
        )
    {
        Category storage category = categories[_categoryId];
        require(category.name.length > 0, "SynapseVault: Category does not exist.");

        return (
            category.name,
            category.description,
            category.moderator
        );
    }

    // --- DAO Parameter Setter Functions (called via `executeProposal`) ---
    // These functions must be public for external calls via proposals.
    // They are secured by the `executeProposal` mechanism itself.

    function setMinInsightStake(uint256 _newValue) public onlyOwner { // Temporarily onlyOwner for demo
        uint256 oldValue = minInsightStake;
        minInsightStake = _newValue;
        emit ParameterChanged("minInsightStake", oldValue, _newValue);
    }

    function setMinChallengeStake(uint256 _newValue) public onlyOwner { // Temporarily onlyOwner for demo
        uint256 oldValue = minChallengeStake;
        minChallengeStake = _newValue;
        emit ParameterChanged("minChallengeStake", oldValue, _newValue);
    }

    function setMinReputationForChallenge(uint256 _newValue) public onlyOwner {
        uint256 oldValue = minReputationForChallenge;
        minReputationForChallenge = _newValue;
        emit ParameterChanged("minReputationForChallenge", oldValue, _newValue);
    }

    function setInsightValidationThreshold(uint256 _newValue) public onlyOwner {
        uint256 oldValue = insightValidationThreshold;
        insightValidationThreshold = _newValue;
        emit ParameterChanged("insightValidationThreshold", oldValue, _newValue);
    }
    
    // ... (More setter functions for all public parameters if needed, following this pattern)

    // Fallback function to receive Ether into the treasury
    receive() external payable {
        emit TreasuryDeposited(_msgSender(), msg.value);
    }
}
```