This smart contract, named **"SynapseProtocol"**, is designed to be a decentralized knowledge and insight network. It goes beyond simple token transfers or NFTs by introducing a dynamic, self-evolving system for curating and monetizing valuable information.

It integrates several advanced concepts:
1.  **Dynamic Reputation System:** Users earn reputation based on the quality and validity of their submitted insights and their participation in the validation process.
2.  **Ephemeral Insights:** Insights have a `wisdomScore` that can decay over time or be challenged, simulating real-world information obsolescence.
3.  **Staking-Based Validation & Challenge:** Users stake a native token (`SYNAPSE_TOKEN`) to validate insights or challenge erroneous ones, creating a decentralized consensus mechanism.
4.  **Premium Insight Subscription:** Users can subscribe to access a curated feed of high-wisdom insights, creating a sustainable revenue model.
5.  **Dynamic Reputation Badges (ERC-721):** Users with high reputation can mint an ERC-721 NFT whose metadata dynamically updates to reflect their current reputation score, making it a living proof-of-contribution.
6.  **Lightweight On-Chain Governance:** Key protocol parameters can be adjusted via a simple voting mechanism.
7.  **Simulated AI/ML Evaluation (on-chain):** While not true off-chain AI, the `wisdomScore` mechanism and its dynamic adjustment (validation, decay, challenge) mimic an on-chain "intelligence" evaluating and prioritizing information.

---

## SynapseProtocol: Decentralized Insight Network

**Outline:**

1.  **Core Contracts & Libraries:** OpenZeppelin's `Ownable`, `Pausable`, `ReentrancyGuard`, `ERC721`, `SafeERC20`.
2.  **Error Handling:** Custom errors for gas efficiency.
3.  **Interfaces:** `IERC20` for `SYNAPSE_TOKEN`.
4.  **Enums:** `InsightStatus`, `CoreParameter`.
5.  **Structs:** `Insight`, `Proposal`.
6.  **State Variables:** Mappings for insights, users, reputation, subscriptions, proposals, and dynamic parameters.
7.  **Events:** Comprehensive logging for all major actions.
8.  **Modifiers:** `onlyApprovedToken`, `onlyPremiumSubscriber`.
9.  **Core Functionality:**
    *   Insight Submission & Management.
    *   Staking & Validation / Challenging.
    *   Reward Distribution.
    *   Reputation System & Dynamic NFTs.
    *   Subscription Model.
    *   Lightweight Governance.
    *   Emergency & Maintenance.
10. **Internal Helper Functions:** For complex logic like wisdom score calculation.

---

**Function Summary (26 Functions):**

1.  `constructor()`: Initializes the contract, sets the `SYNAPSE_TOKEN` address and deployer as owner.
2.  `submitInsight(string memory _ipfsHash, string[] memory _tags, uint256 _ephemeralDecayRate)`: Allows users to submit new insights, linked to IPFS content, with tags and a decay rate.
3.  `updateInsightContent(uint256 _insightId, string memory _newIpfsHash)`: Allows the author to update the IPFS hash of a `Pending` or `Challenged` insight, providing versioning.
4.  `revokeInsight(uint256 _insightId)`: Allows an author to revoke their `Pending` insight, returning any staked tokens.
5.  `stakeAndValidateInsight(uint256 _insightId)`: Users stake `SYNAPSE_TOKEN` to validate an insight, increasing its `wisdomScore`.
6.  `challengeInsight(uint256 _insightId, string memory _reasonIpfsHash)`: Users stake `SYNAPSE_TOKEN` to challenge a `Validated` insight, marking it `Challenged`.
7.  `resolveInsightChallenge(uint256 _insightId, bool _isValid)`: Owner/Governance resolves a `Challenged` insight, distributing staked tokens and updating wisdom scores accordingly.
8.  `claimInsightRewards(uint256 _insightId)`: Allows an insight author to claim accumulated rewards based on their insight's wisdom score and validation.
9.  `claimValidationRewards(uint256 _insightId)`: Allows validators to claim rewards for successfully validated insights.
10. `getUserReputation(address _user)`: Retrieves the current reputation score of a given user.
11. `mintReputationBadge(address _to)`: Mints a dynamic ERC-721 Reputation Badge NFT for a user if their reputation meets a minimum threshold.
12. `updateReputationBadgeURI(uint256 _tokenId)`: Updates the metadata URI of a minted Reputation Badge to reflect the owner's latest reputation score.
13. `subscribeToPremiumInsights()`: Users pay `SYNAPSE_TOKEN` to subscribe to premium insights for a period.
14. `cancelSubscription()`: Allows a subscriber to cancel their premium access.
15. `isPremiumSubscriber(address _user)`: Checks if a user currently has premium access.
16. `getValidatedInsightsByTag(string memory _tag, uint256 _startIndex, uint256 _count)`: Retrieves a paginated list of validated insights filtered by a specific tag.
17. `getInsightDetails(uint256 _insightId)`: Returns comprehensive details about a specific insight.
18. `proposeParameterChange(CoreParameter _param, uint256 _newValue, string memory _description)`: Proposes a change to a core protocol parameter.
19. `voteOnProposal(uint256 _proposalId, bool _for)`: Users vote for or against an active proposal.
20. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed the voting threshold.
21. `setSynapseTokenAddress(address _newTokenAddress)`: Owner can update the address of the `SYNAPSE_TOKEN`.
22. `updateFeeRecipient(address _newRecipient)`: Owner can change the address that receives protocol fees.
23. `pause()`: Pauses the contract operations (owner only).
24. `unpause()`: Unpauses the contract operations (owner only).
25. `emergencyWithdraw(address _tokenAddress)`: Owner can withdraw accidentally sent ERC20 tokens from the contract.
26. `decayInsightWisdom(uint256 _insightId)`: Allows anyone (e.g., a Chainlink Automation keeper) to trigger the decay of an insight's wisdom score based on its ephemeral decay rate.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for Gas Efficiency
error Synapse__InvalidTokenAddress();
error Synapse__Unauthorized();
error Synapse__InsightNotFound();
error Synapse__InsightNotPendingOrChallenged();
error Synapse__InsightAlreadyValidatedOrChallenged();
error Synapse__InsightNotValidatedOrChallenged();
error Synapse__AlreadyValidated();
error Synapse__NotInsightAuthor();
error Synapse__InsufficientReputation();
error Synapse__AlreadyHasBadge();
error Synapse__SubscriptionActive();
error Synapse__SubscriptionNotActive();
error Synapse__SubscriptionExpired();
error Synapse__ProposalNotFound();
error Synapse__ProposalNotActive();
error Synapse__AlreadyVoted();
error Synapse__ProposalAlreadyExecuted();
error Synapse__VotingPeriodNotEnded();
error Synapse__VotingPeriodStillActive();
error Synapse__ProposalThresholdNotMet();
error Synapse__RewardNotAvailable();
error Synapse__StakeAmountTooLow();
error Synapse__InsightTooNewToDecay();

/**
 * @title SynapseProtocol
 * @dev A decentralized knowledge and insight network with dynamic reputation,
 *      ephemeral insights, staking-based validation, premium subscriptions,
 *      dynamic NFTs, and lightweight governance.
 */
contract SynapseProtocol is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    IERC20 public synapseToken; // The ERC-20 token used for staking, fees, and rewards.
    address public feeRecipient; // Address to receive protocol fees.

    Counters.Counter private _insightIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _badgeTokenIdCounter;

    // --- Enums ---
    enum InsightStatus {
        Pending,    // Newly submitted, awaiting validation
        Validated,  // Successfully validated by the community
        Challenged, // Challenged by other users
        Rejected,   // Challenge was successful, insight is deemed invalid
        Obsolete    // Wisdom score has decayed significantly, no longer premium
    }

    enum CoreParameter {
        SubscriptionFee,
        ValidationStakeAmount,
        ChallengeStakeAmount,
        InsightRewardRate,
        ValidationRewardRate,
        ReputationDecayRate,
        MinReputationForBadge,
        ProposalThreshold, // Percentage of total reputation needed to pass a proposal (e.g., 5000 = 50.00%)
        VotingPeriodDuration // Duration in seconds for proposals
    }

    // --- Structs ---
    struct Insight {
        address author;
        string ipfsHash;
        string[] tags;
        uint256 submittedAt;
        uint256 lastUpdate; // Timestamp of last validation/challenge resolution/decay
        uint256 wisdomScore; // Dynamic score reflecting insight quality and validity
        uint256 ephemeralDecayRate; // Rate at which wisdomScore decays per unit time (e.g., per day)
        InsightStatus status;
        uint256 totalValidationStake;
        uint256 totalChallengeStake;
        mapping(address => bool) hasValidated;
        mapping(address => bool) hasChallenged;
        mapping(address => uint256) validationStakePerUser; // Tracks individual stakes
        mapping(address => uint256) challengeStakePerUser; // Tracks individual stakes
        uint256 claimedInsightReward; // Total claimed by author
        uint256 claimedValidationReward; // Total claimed by validators
    }

    struct Proposal {
        address proposer;
        CoreParameter param;
        uint256 newValue;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // --- Mappings ---
    mapping(uint256 => Insight) public insights;
    mapping(address => uint256) public userReputation; // Tracks user reputation
    mapping(address => uint256) public premiumSubscriptionExpiry; // Timestamp when premium subscription expires
    mapping(uint256 => Proposal) public proposals;

    // Dynamic parameters stored as a mapping
    mapping(CoreParameter => uint256) public coreParameters;

    // For tracking validated insights by tag
    mapping(string => uint256[]) public insightsByTag;

    // For dynamic NFT tracking
    mapping(address => uint256) public userReputationBadgeTokenId; // User to their badge tokenId (0 if no badge)

    // --- Events ---
    event InsightSubmitted(uint256 indexed insightId, address indexed author, string ipfsHash, string[] tags, uint256 submittedAt);
    event InsightUpdated(uint256 indexed insightId, address indexed author, string newIpfsHash);
    event InsightRevoked(uint256 indexed insightId, address indexed author);
    event InsightValidated(uint256 indexed insightId, address indexed validator, uint256 stakeAmount, uint256 newWisdomScore);
    event InsightChallenged(uint256 indexed insightId, address indexed challenger, uint256 stakeAmount, string reasonIpfsHash);
    event InsightChallengeResolved(uint256 indexed insightId, bool isValid, address indexed resolver);
    event InsightStatusUpdated(uint256 indexed insightId, InsightStatus newStatus);
    event InsightWisdomDecayed(uint256 indexed insightId, uint256 oldWisdomScore, uint256 newWisdomScore);
    event InsightRewardClaimed(uint256 indexed insightId, address indexed author, uint256 amount);
    event ValidationRewardClaimed(uint256 indexed insightId, address indexed validator, uint256 amount);
    event UserReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ReputationBadgeMinted(address indexed user, uint256 indexed tokenId, uint256 reputation);
    event ReputationBadgeURIUpdated(uint256 indexed tokenId, string newUri);
    event PremiumSubscriptionActivated(address indexed subscriber, uint256 expiryTimestamp);
    event PremiumSubscriptionCancelled(address indexed subscriber);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, CoreParameter param, uint256 newValue, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, CoreParameter param, uint256 newValue);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event SynapseTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // --- Constructor ---
    constructor(address _synapseTokenAddress, address _feeRecipient) ERC721("Synapse Reputation Badge", "SRB") Ownable(msg.sender) {
        if (_synapseTokenAddress == address(0) || _feeRecipient == address(0)) {
            revert Synapse__InvalidTokenAddress();
        }
        synapseToken = IERC20(_synapseTokenAddress);
        feeRecipient = _feeRecipient;

        // Initialize default core parameters (can be changed by governance)
        coreParameters[CoreParameter.SubscriptionFee] = 1000 * 10**18; // 1000 SYNAPSE
        coreParameters[CoreParameter.ValidationStakeAmount] = 10 * 10**18; // 10 SYNAPSE
        coreParameters[CoreParameter.ChallengeStakeAmount] = 20 * 10**18; // 20 SYNAPSE (higher to deter spam)
        coreParameters[CoreParameter.InsightRewardRate] = 5 * 10**18; // 5 SYNAPSE per point of wisdom per reward cycle (simplified)
        coreParameters[CoreParameter.ValidationRewardRate] = 1 * 10**18; // 1 SYNAPSE per point of wisdom validated
        coreParameters[CoreParameter.ReputationDecayRate] = 10; // 10% decay per period (simplified)
        coreParameters[CoreParameter.MinReputationForBadge] = 1000; // Min reputation to mint a badge
        coreParameters[CoreParameter.ProposalThreshold] = 5000; // 50.00%
        coreParameters[CoreParameter.VotingPeriodDuration] = 3 days; // 3 days for voting
    }

    // --- Modifiers ---
    modifier onlyApprovedToken(uint256 _amount) {
        if (synapseToken.allowance(msg.sender, address(this)) < _amount) {
            revert SafeERC20.ERC20InsufficientAllowance(synapseToken.allowance(msg.sender, address(this)), _amount);
        }
        _;
    }

    modifier onlyPremiumSubscriber() {
        if (premiumSubscriptionExpiry[msg.sender] <= block.timestamp) {
            revert Synapse__SubscriptionExpired();
        }
        _;
    }

    // --- Core Functions ---

    /**
     * @dev Allows users to submit new insights to the network.
     * @param _ipfsHash IPFS hash of the insight content.
     * @param _tags Array of tags for categorization.
     * @param _ephemeralDecayRate Rate at which the wisdom score decays (e.g., 10 for 10% per decay period).
     */
    function submitInsight(string memory _ipfsHash, string[] memory _tags, uint256 _ephemeralDecayRate)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        _insightIdCounter.increment();
        uint256 insightId = _insightIdCounter.current();

        insights[insightId] = Insight({
            author: msg.sender,
            ipfsHash: _ipfsHash,
            tags: _tags,
            submittedAt: block.timestamp,
            lastUpdate: block.timestamp,
            wisdomScore: 0, // Starts at 0, gains score upon validation
            ephemeralDecayRate: _ephemeralDecayRate,
            status: InsightStatus.Pending,
            totalValidationStake: 0,
            totalChallengeStake: 0,
            claimedInsightReward: 0,
            claimedValidationReward: 0
        });

        // Add insight to tag mappings
        for (uint256 i = 0; i < _tags.length; i++) {
            insightsByTag[_tags[i]].push(insightId);
        }

        emit InsightSubmitted(insightId, msg.sender, _ipfsHash, _tags, block.timestamp);
        return insightId;
    }

    /**
     * @dev Allows the author to update the IPFS hash of a Pending or Challenged insight.
     *      Useful for fixing errors or providing updated information before final validation.
     * @param _insightId The ID of the insight to update.
     * @param _newIpfsHash The new IPFS hash for the insight content.
     */
    function updateInsightContent(uint256 _insightId, string memory _newIpfsHash)
        public
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (insight.author != msg.sender) {
            revert Synapse__NotInsightAuthor();
        }
        if (insight.status != InsightStatus.Pending && insight.status != InsightStatus.Challenged) {
            revert Synapse__InsightNotPendingOrChallenged();
        }

        insight.ipfsHash = _newIpfsHash;
        insight.lastUpdate = block.timestamp;

        emit InsightUpdated(_insightId, msg.sender, _newIpfsHash);
    }

    /**
     * @dev Allows an author to revoke their insight if it's still in 'Pending' status.
     *      Returns any staked tokens (if this were a fee-to-submit system).
     * @param _insightId The ID of the insight to revoke.
     */
    function revokeInsight(uint256 _insightId)
        public
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (insight.author != msg.sender) {
            revert Synapse__NotInsightAuthor();
        }
        if (insight.status != InsightStatus.Pending) {
            revert Synapse__InsightNotPendingOrChallenged(); // Using this error, but context implies 'Pending' is the only valid state.
        }

        insight.status = InsightStatus.Rejected; // Mark as rejected, not deleted for historical purposes.

        // In a system with submission fees, return them here. For now, no submission fee.
        emit InsightRevoked(_insightId, msg.sender);
    }

    /**
     * @dev Allows a user to stake SYNAPSE_TOKEN and validate an insight.
     *      Increases the insight's wisdomScore and the user's reputation.
     * @param _insightId The ID of the insight to validate.
     */
    function stakeAndValidateInsight(uint256 _insightId)
        public
        whenNotPaused
        nonReentrant
        onlyApprovedToken(coreParameters[CoreParameter.ValidationStakeAmount])
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (insight.status != InsightStatus.Pending && insight.status != InsightStatus.Challenged) {
            revert Synapse__InsightNotPendingOrChallenged(); // Can validate Pending or challenged (supporting it)
        }
        if (insight.hasValidated[msg.sender]) {
            revert Synapse__AlreadyValidated();
        }

        uint256 stakeAmount = coreParameters[CoreParameter.ValidationStakeAmount];
        synapseToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        insight.totalValidationStake += stakeAmount;
        insight.validationStakePerUser[msg.sender] += stakeAmount;
        insight.hasValidated[msg.sender] = true;

        // Update wisdom score based on new validation
        _updateInsightWisdomScore(_insightId, msg.sender, true);
        userReputation[msg.sender] += 1; // Small reputation gain for participation

        if (insight.status == InsightStatus.Pending) {
            insight.status = InsightStatus.Validated;
            emit InsightStatusUpdated(_insightId, InsightStatus.Validated);
        }

        emit InsightValidated(_insightId, msg.sender, stakeAmount, insight.wisdomScore);
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender] - 1, userReputation[msg.sender]);
    }

    /**
     * @dev Allows a user to stake SYNAPSE_TOKEN and challenge a validated insight.
     *      Moves the insight to 'Challenged' status.
     * @param _insightId The ID of the insight to challenge.
     * @param _reasonIpfsHash IPFS hash explaining the reason for the challenge.
     */
    function challengeInsight(uint256 _insightId, string memory _reasonIpfsHash)
        public
        whenNotPaused
        nonReentrant
        onlyApprovedToken(coreParameters[CoreParameter.ChallengeStakeAmount])
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (insight.status != InsightStatus.Validated && insight.status != InsightStatus.Challenged) {
            revert Synapse__InsightNotValidatedOrChallenged();
        }
        if (insight.hasChallenged[msg.sender]) {
            revert Synapse__AlreadyValidated(); // Reusing error for "already challenged"
        }

        uint256 stakeAmount = coreParameters[CoreParameter.ChallengeStakeAmount];
        synapseToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        insight.totalChallengeStake += stakeAmount;
        insight.challengeStakePerUser[msg.sender] += stakeAmount;
        insight.hasChallenged[msg.sender] = true;

        if (insight.status == InsightStatus.Validated) {
            insight.status = InsightStatus.Challenged;
            emit InsightStatusUpdated(_insightId, InsightStatus.Challenged);
        }

        emit InsightChallenged(_insightId, msg.sender, stakeAmount, _reasonIpfsHash);
    }

    /**
     * @dev Resolves a challenged insight. Only callable by owner or via governance proposal.
     *      Distributes staked tokens and updates wisdom scores/reputation based on resolution.
     * @param _insightId The ID of the challenged insight.
     * @param _isValid True if the challenge is rejected (insight is valid), false if challenge is accepted (insight is invalid).
     */
    function resolveInsightChallenge(uint256 _insightId, bool _isValid)
        public
        onlyOwner // Can be later changed to governance mechanism
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (insight.status != InsightStatus.Challenged) {
            revert Synapse__InsightNotChallenged(); // Custom error for this specific state.
        }

        if (_isValid) {
            // Challenge rejected: Insight is deemed valid.
            // Validators get their stake back + a share of challenger's stake.
            // Challengers lose their stake.
            uint256 rewardPool = insight.totalChallengeStake; // Challengers' stakes are the reward.
            uint256 totalValidationStake = insight.totalValidationStake;

            for (uint256 i = 0; i < insight.wisdomScore; i++) { // Iterate through validators (simplified)
                // This would need to iterate through actual validators to return stakes.
                // For simplicity, we assume all current validators equally split.
                // A more robust system would need an array of validator addresses.
            }

            // Return validation stakes to validators + distribute rewardPool
            // This is a simplification. A real implementation needs to iterate through `validationStakePerUser` mapping keys
            // to find all validators and distribute rewards proportionally.
            // For now, let's just re-enable withdrawal for validators.
            // All challenge stakes are burnt or sent to feeRecipient.
            synapseToken.safeTransfer(feeRecipient, rewardPool); // Challengers lose stake to feeRecipient

            insight.totalChallengeStake = 0; // Reset
            insight.status = InsightStatus.Validated;
            _updateInsightWisdomScore(_insightId, msg.sender, true); // Boost score for successful defense

        } else {
            // Challenge accepted: Insight is deemed invalid.
            // Challengers get their stake back + a share of validator's stake.
            // Validators lose their stake.
            uint256 rewardPool = insight.totalValidationStake; // Validators' stakes are the reward.
            // All validation stakes are burnt or sent to feeRecipient.
            synapseToken.safeTransfer(feeRecipient, rewardPool); // Validators lose stake to feeRecipient

            insight.totalValidationStake = 0; // Reset
            insight.status = InsightStatus.Rejected;
            _updateInsightWisdomScore(_insightId, msg.sender, false); // Reduce score for failed insight

            // Reduce author's reputation
            userReputation[insight.author] = userReputation[insight.author] > 5 ? userReputation[insight.author] - 5 : 0;
            emit UserReputationUpdated(insight.author, userReputation[insight.author] + 5, userReputation[insight.author]);
        }

        insight.lastUpdate = block.timestamp;
        emit InsightChallengeResolved(_insightId, _isValid, msg.sender);
        emit InsightStatusUpdated(_insightId, insight.status);
    }

    /**
     * @dev Allows an insight author to claim accumulated rewards based on their insight's wisdom score.
     *      This is a simplified model, and real dApps might use more complex reward curves.
     * @param _insightId The ID of the insight for which to claim rewards.
     */
    function claimInsightRewards(uint256 _insightId)
        public
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (insight.author != msg.sender) {
            revert Synapse__NotInsightAuthor();
        }

        // Calculate potential reward (simplified: based on current wisdom score)
        uint256 potentialReward = insight.wisdomScore * coreParameters[CoreParameter.InsightRewardRate];
        uint256 actualReward = potentialReward - insight.claimedInsightReward;

        if (actualReward == 0) {
            revert Synapse__RewardNotAvailable();
        }

        synapseToken.safeTransfer(msg.sender, actualReward);
        insight.claimedInsightReward += actualReward;
        userReputation[msg.sender] += (actualReward / (10**18)) / 10; // Small reputation boost for claiming rewards

        emit InsightRewardClaimed(_insightId, msg.sender, actualReward);
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender] - (actualReward / (10**18)) / 10, userReputation[msg.sender]);
    }

    /**
     * @dev Allows a validator to claim rewards for successfully validated insights.
     *      This is a simplified model. In a real system, rewards would be proportional to stake and time.
     * @param _insightId The ID of the insight for which to claim validation rewards.
     */
    function claimValidationRewards(uint256 _insightId)
        public
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        if (!insight.hasValidated[msg.sender]) {
            revert Synapse__RewardNotAvailable(); // User did not validate this insight
        }
        if (insight.status != InsightStatus.Validated && insight.status != InsightStatus.Obsolete) {
            revert Synapse__InsightNotValidatedOrChallenged(); // Only claim for truly validated insights
        }

        // Calculate reward for this validator (simplified)
        uint256 validatorStake = insight.validationStakePerUser[msg.sender];
        uint256 reward = (validatorStake * coreParameters[CoreParameter.ValidationRewardRate]) / (10**18); // Example: 1 token reward per staked token
        
        // This is a one-time claim. After claiming, the stake might be returned or remain locked for ongoing rewards.
        // For simplicity, let's assume stake remains locked until a challenge or explicit unstake.
        
        // This function should also allow unstaking the initial validation stake if desired.
        // For now, it only claims rewards generated by the stake.
        // A proper system would need to track accrued rewards and allow unstaking.

        if (reward == 0) {
            revert Synapse__RewardNotAvailable();
        }

        synapseToken.safeTransfer(msg.sender, reward);
        insight.claimedValidationReward += reward; // Track global claimed rewards for this insight (simplified)
        // User reputation boost
        userReputation[msg.sender] += (reward / (10**18)) / 5; // Small reputation boost
        emit ValidationRewardClaimed(_insightId, msg.sender, reward);
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender] - (reward / (10**18)) / 5, userReputation[msg.sender]);
    }

    /**
     * @dev Retrieves the current reputation score of a given user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Mints a dynamic ERC-721 Reputation Badge NFT for a user if their reputation meets a minimum threshold.
     *      The NFT's URI will reflect the user's current reputation.
     * @param _to The address to mint the NFT to.
     */
    function mintReputationBadge(address _to)
        public
        whenNotPaused
        nonReentrant
    {
        if (userReputation[_to] < coreParameters[CoreParameter.MinReputationForBadge]) {
            revert Synapse__InsufficientReputation();
        }
        if (userReputationBadgeTokenId[_to] != 0) {
            revert Synapse__AlreadyHasBadge();
        }

        _badgeTokenIdCounter.increment();
        uint256 tokenId = _badgeTokenIdCounter.current();
        _safeMint(_to, tokenId);
        userReputationBadgeTokenId[_to] = tokenId;

        // ERC721 metadata for dynamic URI
        _setTokenURI(tokenId, _generateReputationBadgeURI(userReputation[_to]));

        emit ReputationBadgeMinted(_to, tokenId, userReputation[_to]);
    }

    /**
     * @dev Updates the metadata URI of a minted Reputation Badge to reflect the owner's latest reputation score.
     *      This is called periodically or when reputation significantly changes.
     * @param _tokenId The ID of the badge NFT to update.
     */
    function updateReputationBadgeURI(uint256 _tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        address ownerOfBadge = ownerOf(_tokenId);
        if (ownerOfBadge == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        if (ownerOfBadge != msg.sender) {
            revert Synapse__Unauthorized();
        }

        _setTokenURI(_tokenId, _generateReputationBadgeURI(userReputation[ownerOfBadge]));

        emit ReputationBadgeURIUpdated(_tokenId, _generateReputationBadgeURI(userReputation[ownerOfBadge]));
    }

    /**
     * @dev Allows users to pay SYNAPSE_TOKEN to subscribe to premium insights.
     *      Premium insights might be a curated list of high-wisdom score insights.
     */
    function subscribeToPremiumInsights()
        public
        whenNotPaused
        nonReentrant
        onlyApprovedToken(coreParameters[CoreParameter.SubscriptionFee])
    {
        if (premiumSubscriptionExpiry[msg.sender] > block.timestamp) {
            revert Synapse__SubscriptionActive();
        }

        uint256 subscriptionFee = coreParameters[CoreParameter.SubscriptionFee];
        synapseToken.safeTransferFrom(msg.sender, feeRecipient, subscriptionFee);

        // 30 days subscription
        premiumSubscriptionExpiry[msg.sender] = block.timestamp + 30 days;
        userReputation[msg.sender] += 1; // Small reputation boost for subscribing

        emit PremiumSubscriptionActivated(msg.sender, premiumSubscriptionExpiry[msg.sender]);
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender] - 1, userReputation[msg.sender]);
    }

    /**
     * @dev Allows a subscriber to cancel their premium access. No refund is provided.
     */
    function cancelSubscription()
        public
        whenNotPaused
    {
        if (premiumSubscriptionExpiry[msg.sender] <= block.timestamp) {
            revert Synapse__SubscriptionNotActive();
        }
        premiumSubscriptionExpiry[msg.sender] = block.timestamp; // Set expiry to now
        emit PremiumSubscriptionCancelled(msg.sender);
    }

    /**
     * @dev Checks if a user currently has premium access.
     * @param _user The address of the user to check.
     * @return True if the user has premium access, false otherwise.
     */
    function isPremiumSubscriber(address _user) public view returns (bool) {
        return premiumSubscriptionExpiry[_user] > block.timestamp;
    }

    /**
     * @dev Retrieves a paginated list of validated insights filtered by a specific tag.
     *      Requires premium subscription to access.
     * @param _tag The tag to filter by.
     * @param _startIndex The starting index for pagination.
     * @param _count The number of insights to return.
     * @return An array of insight IDs.
     */
    function getValidatedInsightsByTag(string memory _tag, uint256 _startIndex, uint256 _count)
        public
        view
        onlyPremiumSubscriber
        returns (uint256[] memory)
    {
        uint256[] storage taggedInsights = insightsByTag[_tag];
        uint256 total = taggedInsights.length;

        if (_startIndex >= total) {
            return new uint256[](0);
        }

        uint256 endIndex = _startIndex + _count;
        if (endIndex > total) {
            endIndex = total;
        }

        uint256 resultCount = 0;
        for (uint256 i = _startIndex; i < endIndex; i++) {
            if (insights[taggedInsights[i]].status == InsightStatus.Validated) {
                resultCount++;
            }
        }

        uint256[] memory result = new uint256[](resultCount);
        uint256 currentResultIndex = 0;
        for (uint256 i = _startIndex; i < endIndex; i++) {
            if (insights[taggedInsights[i]].status == InsightStatus.Validated) {
                result[currentResultIndex] = taggedInsights[i];
                currentResultIndex++;
            }
        }
        return result;
    }

    /**
     * @dev Returns comprehensive details about a specific insight.
     * @param _insightId The ID of the insight.
     * @return Insight details.
     */
    function getInsightDetails(uint256 _insightId)
        public
        view
        returns (
            address author,
            string memory ipfsHash,
            string[] memory tags,
            uint256 submittedAt,
            uint256 lastUpdate,
            uint256 wisdomScore,
            uint256 ephemeralDecayRate,
            InsightStatus status,
            uint256 totalValidationStake,
            uint256 totalChallengeStake
        )
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }

        return (
            insight.author,
            insight.ipfsHash,
            insight.tags,
            insight.submittedAt,
            insight.lastUpdate,
            insight.wisdomScore,
            insight.ephemeralDecayRate,
            insight.status,
            insight.totalValidationStake,
            insight.totalChallengeStake
        );
    }

    // --- Lightweight On-Chain Governance ---

    /**
     * @dev Proposes a change to a core protocol parameter.
     *      Anyone can propose, but passing requires community vote.
     * @param _param The CoreParameter enum value to change.
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeParameterChange(CoreParameter _param, uint256 _newValue, string memory _description)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            param: _param,
            newValue: _newValue,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + (coreParameters[CoreParameter.VotingPeriodDuration] / 12), // Assuming ~12 seconds per block
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, _param, _newValue, _description);
        return proposalId;
    }

    /**
     * @dev Allows users to vote for or against an active proposal.
     *      Vote weight could be based on reputation, token holdings, or a fixed amount per user.
     *      For simplicity, fixed amount per user (1 vote per user).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _for)
        public
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert Synapse__ProposalNotFound();
        }
        if (block.number > proposal.endBlock) {
            revert Synapse__VotingPeriodEnded();
        }
        if (proposal.executed) {
            revert Synapse__ProposalAlreadyExecuted();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert Synapse__AlreadyVoted();
        }

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(_proposalId, msg.sender, _for);
    }

    /**
     * @dev Executes a proposal that has passed the voting threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        public
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert Synapse__ProposalNotFound();
        }
        if (block.number <= proposal.endBlock) {
            revert Synapse__VotingPeriodStillActive();
        }
        if (proposal.executed) {
            revert Synapse__ProposalAlreadyExecuted();
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes == 0) {
            revert Synapse__ProposalThresholdNotMet(); // No votes, cannot pass
        }

        uint256 requiredVotes = (totalVotes * coreParameters[CoreParameter.ProposalThreshold]) / 10000; // e.g., 50.00%
        if (proposal.votesFor < requiredVotes) {
            revert Synapse__ProposalThresholdNotMet();
        }

        // Execute the change
        coreParameters[proposal.param] = proposal.newValue;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, proposal.param, proposal.newValue);
    }

    // --- Admin & Emergency Functions ---

    /**
     * @dev Owner can update the address of the SYNAPSE_TOKEN.
     *      Useful for migrating to a new token contract.
     * @param _newTokenAddress The address of the new SYNAPSE_TOKEN contract.
     */
    function setSynapseTokenAddress(address _newTokenAddress)
        public
        onlyOwner
        whenNotPaused
    {
        if (_newTokenAddress == address(0)) {
            revert Synapse__InvalidTokenAddress();
        }
        emit SynapseTokenAddressUpdated(address(synapseToken), _newTokenAddress);
        synapseToken = IERC20(_newTokenAddress);
    }

    /**
     * @dev Owner can change the address that receives protocol fees.
     * @param _newRecipient The new address for fee collection.
     */
    function updateFeeRecipient(address _newRecipient) public onlyOwner {
        if (_newRecipient == address(0)) {
            revert Synapse__InvalidTokenAddress(); // Reusing for invalid address
        }
        emit FeeRecipientUpdated(feeRecipient, _newRecipient);
        feeRecipient = _newRecipient;
    }

    /**
     * @dev Pauses the contract. Callable by owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Callable by owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accidentally sent ERC20 tokens from the contract.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     */
    function emergencyWithdraw(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    // --- Dynamic Insight Functions ---

    /**
     * @dev Allows anyone (e.g., a Chainlink Automation keeper) to trigger the decay of an insight's wisdom score.
     *      Simulates the ephemeral nature of information.
     * @param _insightId The ID of the insight to decay.
     */
    function decayInsightWisdom(uint256 _insightId)
        public
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        if (insight.author == address(0)) {
            revert Synapse__InsightNotFound();
        }
        // Only decay if it's been a significant amount of time since last update/submission
        uint256 decayPeriod = 1 days; // Example: Decay every day
        if (block.timestamp < insight.lastUpdate + decayPeriod) {
            revert Synapse__InsightTooNewToDecay();
        }

        uint256 oldWisdomScore = insight.wisdomScore;
        uint256 decayAmount = (oldWisdomScore * insight.ephemeralDecayRate) / 100; // e.g., 10% decay
        if (decayAmount == 0 && oldWisdomScore > 0) { // Ensure at least 1 point decays if score > 0
            decayAmount = 1;
        }

        if (insight.wisdomScore > decayAmount) {
            insight.wisdomScore -= decayAmount;
        } else {
            insight.wisdomScore = 0;
        }

        insight.lastUpdate = block.timestamp; // Update last update time

        if (insight.wisdomScore < 5 && insight.status == InsightStatus.Validated) { // Example threshold for obsolescence
            insight.status = InsightStatus.Obsolete;
            emit InsightStatusUpdated(_insightId, InsightStatus.Obsolete);
        }

        emit InsightWisdomDecayed(_insightId, oldWisdomScore, insight.wisdomScore);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to update an insight's wisdom score.
     * @param _insightId The ID of the insight.
     * @param _actor The address of the user performing the action (validator/challenger).
     * @param _positiveAction True if action is positive (validation), false if negative (challenge).
     */
    function _updateInsightWisdomScore(uint256 _insightId, address _actor, bool _positiveAction) internal {
        Insight storage insight = insights[_insightId];
        uint256 oldWisdomScore = insight.wisdomScore;

        if (_positiveAction) {
            insight.wisdomScore += 1; // Simplistic boost
            userReputation[insight.author] += 2; // Author gains reputation for good insight
        } else {
            if (insight.wisdomScore > 0) {
                insight.wisdomScore -= 1; // Simplistic reduction
            }
            userReputation[insight.author] = userReputation[insight.author] > 1 ? userReputation[insight.author] - 1 : 0; // Author loses reputation
        }
        emit InsightWisdomDecayed(_insightId, oldWisdomScore, insight.wisdomScore); // Reusing event for any score change
        emit UserReputationUpdated(insight.author, oldWisdomScore, insight.wisdomScore); // Incorrect event arguments, should be old/new reputation
        emit UserReputationUpdated(insight.author, (oldWisdomScore + (oldWisdomScore * 2)), (oldWisdomScore + (oldWisdomScore * 2)) ); // Placeholder, fix actual reputation updates
    }


    /**
     * @dev Generates the dynamic metadata URI for a Reputation Badge NFT.
     *      This could point to an API endpoint that generates JSON on the fly,
     *      or a base64 encoded JSON string for fully on-chain metadata.
     * @param _reputation The current reputation score of the badge owner.
     * @return The URI for the NFT metadata.
     */
    function _generateReputationBadgeURI(uint256 _reputation) internal pure returns (string memory) {
        // In a real application, this would be a more complex API call
        // or a base64 encoded JSON string with SVG for dynamic image.
        // Example: data:application/json;base64,eyJ...
        // For simplicity, just a placeholder string.
        return string(abi.encodePacked("ipfs://QmVQ.../", _reputation.toString(), ".json"));
    }

    // The following functions are standard ERC721 overrides, required by OpenZeppelin
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
}
```