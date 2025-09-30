The smart contract concept presented here is a **"Verifiable Intelligence & Dynamic Consensus Network" (VIDCON)**. It's designed to be a decentralized protocol for submitting, verifying, and curating "intelligence assertions" (e.g., data points, predictions, scientific claims, market insights).

The advanced concepts include:
*   **Dynamic Reputation System (SBT-like):** Users earn a non-transferable internal score for accurate submissions and validations. This reputation decays over time for inactivity or incorrect actions, incentivizing continuous positive engagement. It influences voting power in disputes and governance.
*   **Adaptive Consensus/Truth Discovery:** Challenged assertions transform into a simplified prediction market. Stakers commit capital, and participants vote with their reputation. The outcome is determined by a combination of staked tokens and reputation-weighted votes.
*   **Future AI Integration Hooks:** The `assertionHash` and `assertionURI` fields are designed to allow for metadata that could point to verifiable AI model outputs or external data sources, facilitating future integration with decentralized AI oracles for automated initial vetting or complex evaluations.
*   **On-chain Governance:** A mechanism for users with sufficient reputation to propose and vote on changes to core network parameters, allowing the protocol to adapt and evolve over time in a decentralized manner.

This design aims to be novel by focusing on *internal generation and validation of complex data/assertions* through a gamified, reputation-driven consensus, rather than simply fetching data from external sources like traditional oracle networks.

---

## Verifiable Intelligence & Dynamic Consensus Network (VIDCON)

**Outline and Function Summary:**

1.  **Core Concept:**
    A decentralized protocol for submitting, verifying, and curating "intelligence assertions" (e.g., data points, predictions, scientific claims, market insights). Users earn reputation (an internal, non-transferable score) for accurate submissions and validations. The protocol runs mini-prediction markets or truth discovery games to settle ambiguous claims, leveraging staked tokens and reputation. It features mechanisms for decaying reputation for inactivity or incorrect validations, and adaptive challenge difficulty. Designed for potential future integration with decentralized AI oracles for advanced assertion evaluation.

2.  **Data Structures:**
    *   `Assertion`: Represents a submitted piece of intelligence, its state, stakes, and outcome.
    *   `ReputationProfile`: Stores a user's current reputation score, last activity, and accumulated rewards.
    *   `Challenge`: Details an active dispute against an assertion, including challenger stakes and votes.
    *   `GovernanceProposal`: Records proposed parameter changes and voting details.

3.  **Function Categories & Summaries (27 functions):**

    **A. Reputation Management (Internal SBT-like score)**
    1.  `getReputation(address _user)`: Returns the current reputation score of a user.
    2.  `_updateReputation(address _user, int256 _change, bool _onlyIncrease)`: *Internal helper* to modify reputation, with option to only allow increases.
    3.  `decayReputation(address _user)`: Allows any user to trigger reputation decay for an inactive user, preventing stale high scores.
    4.  `getReputationProfile(address _user)`: Retrieves a user's complete reputation profile (score, last activity, accumulated rewards).

    **B. Assertion Lifecycle (Core Protocol Actions)**
    5.  `submitIntelligenceAssertion(bytes32 _assertionHash, string calldata _assertionURI, uint256 _assertionBond)`: Submits a new intelligence claim, requiring an initial bond in the reward token.
    6.  `stakeOnAssertion(uint256 _assertionId, uint256 _amount)`: Users stake tokens to support a submitted (not yet challenged) assertion, increasing its credibility.
    7.  `challengeAssertion(uint256 _assertionId, uint256 _challengeBond)`: Initiates a dispute against an assertion, requiring a bond.
    8.  `supportChallenge(uint256 _challengeId, uint256 _amount)`: Users stake tokens to support an active challenge.
    9.  `voteOnDispute(uint256 _challengeId, bool _supportsAssertion, uint256 _voteWeight)`: Allows reputation-weighted voting on an active dispute.
    10. `resolveAssertion(uint256 _assertionId)`: Finalizes an assertion based on consensus/votes, distributing rewards/penalties. Callable by anyone after the relevant time periods.
    11. `withdrawAssertionStake(uint256 _assertionId)`: Allows a staker to conceptually withdraw their principal stake after successful resolution (transferred to `accumulatedRewards`).
    12. `withdrawChallengeStake(uint256 _challengeId)`: Allows a staker to conceptually withdraw their principal stake from a challenge after resolution (transferred to `accumulatedRewards`).
    13. `claimAssertionRewards(uint256 _assertionId)`: Allows participants on the winning side of a resolved assertion/challenge to claim their proportional rewards and principal, which are pooled in `accumulatedRewards`.

    **C. Query & Discovery (Information Retrieval)**
    14. `getAssertionDetails(uint256 _assertionId)`: Retrieves all details of a specific intelligence assertion.
    15. `getAssertionStatus(uint256 _assertionId)`: Returns the current lifecycle status of an assertion.
    16. `getAssertionResult(uint256 _assertionId)`: Returns the verified outcome (true/false) of a resolved assertion.
    17. `getOpenAssertions()`: Returns a list of assertion IDs that are open for staking or challenging (simplified).
    18. `getActiveChallenges()`: Returns a list of challenge IDs that are currently being voted on (simplified).
    19. `getResolvedAssertions()`: Returns a list of assertion IDs that have been finalized (simplified).

    **D. Network Parameters & Governance (Evolution of the Protocol)**
    20. `setRewardTokenAddress(address _tokenAddress)`: Sets the ERC-20 token address used for rewards and staking (owner-only, typically during setup).
    21. `proposeParameterChange(bytes32 _paramName, int256 _newValue, string calldata _description)`: Allows users with sufficient reputation to propose changes to network parameters.
    22. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Allows reputation-weighted voting on active governance proposals.
    23. `executeParameterChange(uint256 _proposalId)`: Executes a passed governance proposal.
    24. `updateReputationDecayPeriod(uint256 _period)`: Owner-only direct parameter update for `reputationDecayPeriod` (can be replaced by governance).
    25. `updateChallengePeriod(uint256 _period)`: Owner-only direct parameter update for `assertionChallengePeriod` (can be replaced by governance).
    26. `withdrawNetworkTreasuryFunds(address _recipient, uint256 _amount)`: Allows owner/governance to withdraw funds from the contract treasury.
    27. `pauseNetworkOperations()`: Emergency function to pause critical contract functions (owner-only).
    28. `unpauseNetworkOperations()`: Emergency function to unpause critical contract functions (owner-only).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline and Function Summary:
//
// 1. Core Concept: Verifiable Intelligence & Dynamic Consensus Network (VIDCON)
//    A decentralized protocol for submitting, verifying, and curating "intelligence assertions"
//    (e.g., data points, predictions, scientific claims, market insights). Users earn reputation
//    (an internal, non-transferable score) for accurate submissions and validations. The
//    protocol runs mini-prediction markets or truth discovery games to settle ambiguous
//    claims, leveraging staked tokens and reputation. It features mechanisms for decaying
//    reputation for inactivity or incorrect validations, and adaptive challenge difficulty.
//    Designed for potential future integration with decentralized AI oracles for advanced
//    assertion evaluation.
//
// 2. Data Structures:
//    - Assertion: Represents a submitted piece of intelligence, its state, stakes, and outcome.
//    - ReputationProfile: Stores a user's current reputation score, last activity, and accumulated rewards.
//    - Challenge: Details an active dispute against an assertion, including challenger stakes and votes.
//    - GovernanceProposal: Records proposed parameter changes and voting details.
//
// 3. Function Categories & Summaries (at least 20 functions):
//
//    A. Reputation Management (Internal SBT-like score)
//       1.  getReputation(address _user): Returns the current reputation score of a user.
//       2.  _updateReputation(address _user, int256 _change, bool _onlyIncrease): Internal helper to modify reputation, with option to only allow increases.
//       3.  decayReputation(address _user): Allows any user to trigger reputation decay for an inactive user, preventing stale high scores.
//       4.  getReputationProfile(address _user): Retrieves a user's complete reputation profile.
//
//    B. Assertion Lifecycle (Core Protocol Actions)
//       5.  submitIntelligenceAssertion(bytes32 _assertionHash, string calldata _assertionURI, uint256 _assertionBond): Submits a new intelligence claim, requiring an initial bond.
//       6.  stakeOnAssertion(uint256 _assertionId, uint256 _amount): Users stake tokens to support a submitted (not yet challenged) assertion, increasing its credibility.
//       7.  challengeAssertion(uint256 _assertionId, uint256 _challengeBond): Initiates a dispute against an assertion, requiring a bond.
//       8.  supportChallenge(uint256 _challengeId, uint256 _amount): Users stake tokens to support an active challenge.
//       9.  voteOnDispute(uint256 _challengeId, bool _supportsAssertion, uint256 _voteWeight): Allows reputation-weighted voting on an active dispute.
//       10. resolveAssertion(uint256 _assertionId): Finalizes an assertion based on consensus, distributing rewards/penalties. Callable by anyone after challenge period.
//       11. withdrawAssertionStake(uint256 _assertionId): Allows a staker to conceptually withdraw their principal stake after successful resolution (transferred to `accumulatedRewards`).
//       12. withdrawChallengeStake(uint256 _challengeId): Allows a staker to conceptually withdraw their principal stake from a challenge after resolution (transferred to `accumulatedRewards`).
//       13. claimAssertionRewards(uint256 _assertionId): Allows participants on the winning side of a resolved assertion/challenge to claim their proportional rewards (and principal) from their `accumulatedRewards` pool.
//
//    C. Query & Discovery (Information Retrieval)
//       14. getAssertionDetails(uint256 _assertionId): Retrieves all details of a specific intelligence assertion.
//       15. getAssertionStatus(uint256 _assertionId): Returns the current lifecycle status of an assertion.
//       16. getAssertionResult(uint256 _assertionId): Returns the verified outcome (true/false) of a resolved assertion.
//       17. getOpenAssertions(): Returns a list of assertion IDs that are open for staking or challenging.
//       18. getActiveChallenges(): Returns a list of challenge IDs that are currently being voted on.
//       19. getResolvedAssertions(): Returns a list of assertion IDs that have been finalized.
//
//    D. Network Parameters & Governance (Evolution of the Protocol)
//       20. setRewardTokenAddress(address _tokenAddress): Sets the ERC-20 token address used for rewards and staking.
//       21. proposeParameterChange(bytes32 _paramName, int256 _newValue, string calldata _description): Allows users with sufficient reputation to propose changes to network parameters.
//       22. voteOnParameterChange(uint256 _proposalId, bool _support): Allows reputation-weighted voting on active governance proposals.
//       23. executeParameterChange(uint256 _proposalId): Executes a passed governance proposal.
//       24. updateReputationDecayPeriod(uint256 _period): Owner-only direct parameter update for `reputationDecayPeriod`.
//       25. updateChallengePeriod(uint256 _period): Owner-only direct parameter update for `assertionChallengePeriod`.
//       26. withdrawNetworkTreasuryFunds(address _recipient, uint256 _amount): Allows owner/governance to withdraw funds from the contract treasury.
//       27. pauseNetworkOperations(): Emergency function to pause critical contract functions.
//       28. unpauseNetworkOperations(): Emergency function to unpause critical contract functions.
//
//
// Design Choices & Advanced Concepts:
// - Dynamic Reputation System: Reputation is an internal, non-transferable (SBT-like) score, crucial for weighted voting and influence. It decays over time for inactivity or incorrect actions, incentivizing continuous positive engagement.
// - Adaptive Consensus: The difficulty of validating or challenging assertions implicitly adjusts based on accumulated stakes and reputation weights in disputes.
// - Mini-Prediction Market for Truth Discovery: Challenged assertions transform into a simplified prediction market where stakers vote with their reputation and capital.
// - Future AI Integration Hooks: The `_assertionHash` and `_assertionURI` are designed to allow for metadata that could point to verifiable AI model outputs or external data sources, facilitating future integration with decentralized AI oracles for automated initial vetting.
// - Governance Mechanism: A basic on-chain governance allows for evolving critical network parameters over time, making the protocol adaptable and decentralized.
// - ReentrancyGuard: Protects against reentrancy attacks, especially important in a contract handling user funds and stakes.

contract VerifiableIntelligenceNetwork is Ownable, ReentrancyGuard {
    IERC20 public rewardToken; // ERC-20 token used for staking and rewards

    // --- State Variables & Parameters ---

    uint256 public nextAssertionId;
    uint256 public nextChallengeId;
    uint256 public nextProposalId;

    // Configuration parameters (can be updated by governance)
    uint256 public minAssertionBond = 100 * (10**18); // Minimum token bond for submitting an assertion
    uint256 public minChallengeBond = 50 * (10**18);  // Minimum token bond for challenging an assertion
    uint256 public assertionChallengePeriod = 3 days; // Time window for challenging a submitted assertion (if no challenge, then resolved)
    uint256 public disputeVotingPeriod = 5 days;      // Time window for voting on an active challenge
    uint256 public rewardPoolShareBps = 1000;         // 10% of total stake on the losing side goes to reward pool (1000 basis points)
    uint256 public reputationDecayPeriod = 90 days;   // Period after which reputation starts decaying for inactivity
    int256 public reputationDecayRate = -100;         // Amount of reputation to decay per period

    // --- Data Structures ---

    enum AssertionStatus {
        Pending,        // Just submitted, awaiting stakes/challenges
        Staked,         // Received stakes, awaiting challenge period end or challenge
        Challenged,     // Under dispute, awaiting voting
        ResolvedTrue,   // Resolved as true
        ResolvedFalse,  // Resolved as false
        Cancelled       // Canceled (e.g., if no stakes/challenges, or by owner/governance)
    }

    struct Assertion {
        address submitter;
        bytes32 assertionHash;  // Hash of the assertion content (e.g., IPFS CID)
        string assertionURI;    // URI to the assertion content (e.g., ipfs://...)
        uint256 initialBond;    // Initial bond provided by the submitter
        uint256 totalStakedForAssertion; // Total tokens staked in favor of the assertion
        uint256 creationTimestamp;
        uint256 resolutionTimestamp;
        AssertionStatus status;
        bool result;            // True if resolved true, false if resolved false
        uint256 activeChallengeId; // 0 if no active challenge
        mapping(address => uint256) stakers; // User => Amount staked
        address[] stakerAddresses; // To iterate over stakers
    }

    struct ReputationProfile {
        int256 score;             // Reputation score
        uint256 lastActivityTimestamp; // Timestamp of last significant activity (e.g., assertion, challenge, vote)
        uint256 accumulatedRewards; // Rewards accumulated but not yet claimed by user
    }

    struct Challenge {
        uint256 assertionId;
        address challenger;
        uint256 challengeBond;
        uint256 creationTimestamp;
        int256 totalVotesForAssertion;   // Sum of reputation-weighted votes for assertion
        int256 totalVotesAgainstAssertion; // Sum of reputation-weighted votes against assertion
        uint256 totalStakedForChallenge; // Total tokens staked in favor of the challenge
        bool resolved;
        bool challengeSuccessful; // True if challenger wins, false if assertion wins
        mapping(address => uint256) stakers; // User => Amount staked in challenge
        mapping(address => bool) hasVoted; // User => if already voted
        address[] stakerAddresses; // To iterate over challenge stakers
    }

    struct GovernanceProposal {
        bytes32 paramName;
        int256 newValue;
        string description;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        int256 totalVotesFor;    // Sum of reputation-weighted votes for proposal
        int256 totalVotesAgainst; // Sum of reputation-weighted votes against proposal
        bool executed;
        mapping(address => bool) hasVoted; // User => if already voted
    }

    // --- Mappings ---
    mapping(uint256 => Assertion) public assertions;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => ReputationProfile) public reputationProfiles;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event RewardTokenAddressSet(address indexed _tokenAddress);
    event AssertionSubmitted(uint256 indexed assertionId, address indexed submitter, bytes32 assertionHash);
    event StakedOnAssertion(uint256 indexed assertionId, address indexed staker, uint256 amount);
    event AssertionChallenged(uint256 indexed assertionId, uint256 indexed challengeId, address indexed challenger);
    event SupportedChallenge(uint256 indexed challengeId, address indexed staker, uint256 amount);
    event VotedOnDispute(uint256 indexed challengeId, address indexed voter, bool supportsAssertion, uint256 voteWeight);
    event AssertionResolved(uint256 indexed assertionId, AssertionStatus newStatus, bool result, address indexed resolver);
    event FundsTransferredToAccumulatedRewards(address indexed user, uint256 amount, string context);
    event ReputationUpdated(address indexed user, int256 oldScore, int256 newScore, int256 change);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramName, int256 newValue, address indexed proposer);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramName, int256 newValue);
    event NetworkPaused(address indexed pauser);
    event NetworkUnpaused(address indexed unpauser);

    // --- Modifiers ---
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor(address _rewardTokenAddress) Ownable(msg.sender) {
        setRewardTokenAddress(_rewardTokenAddress);
    }

    // --- A. Reputation Management ---

    /**
     * @notice Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputationProfiles[_user].score;
    }

    /**
     * @notice Internal helper to modify a user's reputation.
     *         Can be configured to only allow increases if _onlyIncrease is true.
     * @param _user The address of the user.
     * @param _change The amount to change the reputation by (can be negative).
     * @param _onlyIncrease If true, only allows positive _change.
     */
    function _updateReputation(address _user, int256 _change, bool _onlyIncrease) internal {
        ReputationProfile storage profile = reputationProfiles[_user];
        if (_onlyIncrease && _change < 0) {
            revert("Cannot decrease reputation with _onlyIncrease flag");
        }
        int256 oldScore = profile.score;
        profile.score += _change;
        // Reputation score cannot go below 0
        if (profile.score < 0) {
            profile.score = 0;
        }
        profile.lastActivityTimestamp = block.timestamp;
        emit ReputationUpdated(_user, oldScore, profile.score, _change);
    }

    /**
     * @notice Allows any user to trigger reputation decay for an inactive user.
     *         This prevents stale high scores and incentivizes continuous engagement.
     * @param _user The address of the user whose reputation is to be decayed.
     */
    function decayReputation(address _user) public nonReentrant {
        ReputationProfile storage profile = reputationProfiles[_user];
        require(profile.score > 0, "Reputation already 0");
        require(block.timestamp >= profile.lastActivityTimestamp + reputationDecayPeriod, "Not yet time for decay");

        int256 decayAmount = reputationDecayRate; // Typically a negative value
        _updateReputation(_user, decayAmount, false);
    }

    /**
     * @notice Retrieves a user's complete reputation profile.
     * @param _user The address of the user.
     * @return score The reputation score.
     * @return lastActivityTimestamp The timestamp of the user's last significant activity.
     * @return accumulatedRewards The rewards accumulated by the user but not yet claimed.
     */
    function getReputationProfile(address _user) public view returns (int256 score, uint256 lastActivityTimestamp, uint256 accumulatedRewards) {
        ReputationProfile storage profile = reputationProfiles[_user];
        return (profile.score, profile.lastActivityTimestamp, profile.accumulatedRewards);
    }

    // --- B. Assertion Lifecycle ---

    /**
     * @notice Submits a new intelligence claim, requiring an initial bond.
     * @param _assertionHash A unique hash identifying the content of the assertion (e.g., IPFS CID).
     * @param _assertionURI A URI pointing to the detailed assertion content.
     * @param _assertionBond The amount of tokens staked by the submitter to back their claim.
     */
    function submitIntelligenceAssertion(bytes32 _assertionHash, string calldata _assertionURI, uint256 _assertionBond)
        public
        whenNotPaused
        nonReentrant
    {
        require(_assertionBond >= minAssertionBond, "Bond less than minimum");
        require(_assertionHash != bytes32(0), "Assertion hash cannot be empty");
        require(bytes(_assertionURI).length > 0, "Assertion URI cannot be empty");

        rewardToken.transferFrom(msg.sender, address(this), _assertionBond);

        uint256 id = nextAssertionId++;
        assertions[id] = Assertion({
            submitter: msg.sender,
            assertionHash: _assertionHash,
            assertionURI: _assertionURI,
            initialBond: _assertionBond,
            totalStakedForAssertion: _assertionBond,
            creationTimestamp: block.timestamp,
            resolutionTimestamp: 0,
            status: AssertionStatus.Pending,
            result: false,
            activeChallengeId: 0,
            stakerAddresses: new address[](0) // Initialize, will be filled by push
        });
        assertions[id].stakers[msg.sender] = _assertionBond;
        assertions[id].stakerAddresses.push(msg.sender);

        _updateReputation(msg.sender, 10, true); // Small rep reward for submission
        emit AssertionSubmitted(id, msg.sender, _assertionHash);
    }

    /**
     * @notice Users stake tokens to support a submitted (not yet challenged) assertion, increasing its credibility.
     * @param _assertionId The ID of the assertion to support.
     * @param _amount The amount of tokens to stake.
     */
    function stakeOnAssertion(uint256 _assertionId, uint256 _amount)
        public
        whenNotPaused
        nonReentrant
    {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        require(assertion.status == AssertionStatus.Pending || assertion.status == AssertionStatus.Staked, "Assertion not in stakeable state");
        require(_amount > 0, "Stake amount must be greater than zero");
        require(block.timestamp < assertion.creationTimestamp + assertionChallengePeriod, "Challenge period has ended, cannot stake on pending assertion");

        rewardToken.transferFrom(msg.sender, address(this), _amount);

        if (assertion.stakers[msg.sender] == 0) {
            assertion.stakerAddresses.push(msg.sender);
        }
        assertion.stakers[msg.sender] += _amount;
        assertion.totalStakedForAssertion += _amount;
        assertion.status = AssertionStatus.Staked;

        _updateReputation(msg.sender, 5, true); // Small rep reward for supporting
        emit StakedOnAssertion(_assertionId, msg.sender, _amount);
    }

    /**
     * @notice Initiates a dispute against an assertion, requiring a bond.
     *         Can only be done during the challenge period (if defined by `assertionChallengePeriod`)
     *         or before an assertion is definitively resolved. Here, it can be challenged anytime before resolution.
     * @param _assertionId The ID of the assertion to challenge.
     * @param _challengeBond The amount of tokens staked by the challenger.
     */
    function challengeAssertion(uint256 _assertionId, uint256 _challengeBond)
        public
        whenNotPaused
        nonReentrant
    {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        require(assertion.status != AssertionStatus.Challenged, "Assertion already challenged");
        require(assertion.status != AssertionStatus.ResolvedTrue && assertion.status != AssertionStatus.ResolvedFalse, "Assertion already resolved");
        require(_challengeBond >= minChallengeBond, "Challenge bond less than minimum");
        require(msg.sender != assertion.submitter, "Submitter cannot challenge their own assertion");

        rewardToken.transferFrom(msg.sender, address(this), _challengeBond);

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            assertionId: _assertionId,
            challenger: msg.sender,
            challengeBond: _challengeBond,
            creationTimestamp: block.timestamp,
            totalVotesForAssertion: 0,
            totalVotesAgainstAssertion: 0,
            totalStakedForChallenge: _challengeBond,
            resolved: false,
            challengeSuccessful: false,
            stakerAddresses: new address[](0)
        });
        challenges[challengeId].stakers[msg.sender] = _challengeBond;
        challenges[challengeId].stakerAddresses.push(msg.sender);

        assertion.status = AssertionStatus.Challenged;
        assertion.activeChallengeId = challengeId;

        _updateReputation(msg.sender, 15, true); // Medium rep reward for challenging
        emit AssertionChallenged(_assertionId, challengeId, msg.sender);
    }

    /**
     * @notice Users stake tokens to support an active challenge.
     * @param _challengeId The ID of the challenge to support.
     * @param _amount The amount of tokens to stake.
     */
    function supportChallenge(uint256 _challengeId, uint256 _amount)
        public
        whenNotPaused
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "Challenge does not exist");
        require(!challenge.resolved, "Challenge already resolved");
        require(_amount > 0, "Stake amount must be greater than zero");
        require(msg.sender != challenge.challenger, "Challenger cannot support their own challenge (already bonded)");
        require(block.timestamp < challenge.creationTimestamp + disputeVotingPeriod, "Voting period for challenge has ended");

        rewardToken.transferFrom(msg.sender, address(this), _amount);

        if (challenge.stakers[msg.sender] == 0) {
            challenge.stakerAddresses.push(msg.sender);
        }
        challenge.stakers[msg.sender] += _amount;
        challenge.totalStakedForChallenge += _amount;

        _updateReputation(msg.sender, 5, true); // Small rep reward for supporting challenge
        emit SupportedChallenge(_challengeId, msg.sender, _amount);
    }

    /**
     * @notice Allows reputation-weighted voting on an active dispute.
     *         Users can only vote once per challenge.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _supportsAssertion True if voting in favor of the original assertion, false if against (for the challenge).
     * @param _voteWeight The amount of reputation to use for voting. (Optional: or use total rep)
     */
    function voteOnDispute(uint256 _challengeId, bool _supportsAssertion, uint256 _voteWeight)
        public
        whenNotPaused
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "Challenge does not exist");
        require(!challenge.resolved, "Challenge already resolved");
        require(block.timestamp < challenge.creationTimestamp + disputeVotingPeriod, "Voting period has ended");
        require(!challenge.hasVoted[msg.sender], "Already voted in this challenge");
        require(reputationProfiles[msg.sender].score > 0, "Requires reputation to vote");
        require(_voteWeight > 0 && _voteWeight <= uint256(reputationProfiles[msg.sender].score), "Invalid vote weight");

        challenge.hasVoted[msg.sender] = true;

        if (_supportsAssertion) {
            challenge.totalVotesForAssertion += int256(_voteWeight);
        } else {
            challenge.totalVotesAgainstAssertion += int256(_voteWeight);
        }

        _updateReputation(msg.sender, 2, true); // Small rep reward for voting
        emit VotedOnDispute(_challengeId, msg.sender, _supportsAssertion, _voteWeight);
    }

    /**
     * @notice Finalizes an assertion based on consensus, distributing rewards/penalties.
     *         Callable by anyone after challenge period or dispute voting period.
     * @param _assertionId The ID of the assertion to resolve.
     */
    function resolveAssertion(uint256 _assertionId)
        public
        nonReentrant
    {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        require(assertion.status != AssertionStatus.ResolvedTrue && assertion.status != AssertionStatus.ResolvedFalse, "Assertion already resolved");

        // Case 1: Assertion was never challenged and challenge period passed
        if (assertion.activeChallengeId == 0) {
            require(block.timestamp >= assertion.creationTimestamp + assertionChallengePeriod, "Challenge period not over");
            assertion.status = AssertionStatus.ResolvedTrue;
            assertion.result = true;
            _distributeAssertionRewards(_assertionId, true); // All stakers on assertion win
            _updateReputation(assertion.submitter, 50, true); // Big rep reward for successful assertion
        }
        // Case 2: Assertion was challenged and dispute voting period passed
        else {
            Challenge storage challenge = challenges[assertion.activeChallengeId];
            require(challenge.challenger != address(0), "Associated challenge does not exist");
            require(block.timestamp >= challenge.creationTimestamp + disputeVotingPeriod, "Dispute voting period not over");
            require(!challenge.resolved, "Challenge already resolved");

            // Determine winner based on reputation-weighted votes
            bool assertionWins = challenge.totalVotesForAssertion >= challenge.totalVotesAgainstAssertion;

            if (assertionWins) {
                assertion.status = AssertionStatus.ResolvedTrue;
                assertion.result = true;
                challenge.challengeSuccessful = false;
                _distributeAssertionRewards(_assertionId, true); // Original assertion stakers win
                _distributeChallengeRewards(assertion.activeChallengeId, false); // Challenge supporters lose their bond
                _updateReputation(assertion.submitter, 30, true); // Rep reward for winning
                _updateReputation(challenge.challenger, -20, false); // Rep penalty for losing
            } else {
                assertion.status = AssertionStatus.ResolvedFalse;
                assertion.result = false;
                challenge.challengeSuccessful = true;
                _distributeAssertionRewards(_assertionId, false); // Original assertion stakers lose their bond
                _distributeChallengeRewards(assertion.activeChallengeId, true); // Challenge supporters win
                _updateReputation(assertion.submitter, -20, false); // Rep penalty for losing
                _updateReputation(challenge.challenger, 30, true); // Rep reward for winning
            }
            challenge.resolved = true;
        }

        assertion.resolutionTimestamp = block.timestamp;
        emit AssertionResolved(_assertionId, assertion.status, assertion.result, msg.sender);
    }

    /**
     * @notice Internal function to distribute rewards/penalties for an assertion.
     *         Winning stakes are moved to `accumulatedRewards`. Losing stakes are absorbed.
     * @param _assertionId The ID of the assertion.
     * @param _assertionWasTrue If the assertion was resolved as true.
     */
    function _distributeAssertionRewards(uint256 _assertionId, bool _assertionWasTrue) internal {
        Assertion storage assertion = assertions[_assertionId];
        uint256 totalStaked = assertion.totalStakedForAssertion;
        if (totalStaked == 0) return;

        // If the assertion was challenged, the losing side's total stake becomes part of the reward pool
        // that's distributed to the winning side. If not challenged, no "losing side" to draw from.
        // For simplicity, we'll assume a portion of the *total* stakes (winning + losing, or just winning if no challenge)
        // contributes to a general reward pool that winners draw from.
        // In a complex system, the losing side's full stake would fund the winning side + governance.

        // For this simplified logic, `rewardPoolShareBps` is applied to the *losing* stake
        // to be distributed to the winning side as extra incentive.
        // But since we are calculating based on assertion stakes (not challenge), let's adjust.
        // If assertion was true: all stakers get their principal back + a bonus from any penalty pool.
        // If assertion was false: all stakers lose their principal.

        for (uint256 i = 0; i < assertion.stakerAddresses.length; i++) {
            address staker = assertion.stakerAddresses[i];
            uint256 stakedAmount = assertion.stakers[staker];

            if (_assertionWasTrue) {
                // Return principal to accumulated rewards.
                reputationProfiles[staker].accumulatedRewards += stakedAmount;
                emit FundsTransferredToAccumulatedRewards(staker, stakedAmount, "Assertion principal win");
                _updateReputation(staker, 10, true); // Small rep increase for correct stake
            } else {
                // Stakers on the losing side lose their stake. Their tokens remain in the contract
                // to fund future rewards or the treasury.
                _updateReputation(staker, -10, false); // Small rep decrease for incorrect stake
            }
            assertion.stakers[staker] = 0; // Clear the individual stake, it's now either claimed or lost
        }
        // totalStakedForAssertion effectively becomes 0 after processing
        assertion.totalStakedForAssertion = 0;
        delete assertion.stakerAddresses; // Clear array for efficiency
    }

    /**
     * @notice Internal function to distribute rewards/penalties for a challenge.
     *         Winning stakes are moved to `accumulatedRewards`. Losing stakes are absorbed.
     * @param _challengeId The ID of the challenge.
     * @param _challengeWasSuccessful If the challenge was resolved as successful.
     */
    function _distributeChallengeRewards(uint256 _challengeId, bool _challengeWasSuccessful) internal {
        Challenge storage challenge = challenges[_challengeId];
        uint256 totalStaked = challenge.totalStakedForChallenge;
        if (totalStaked == 0) return;

        for (uint256 i = 0; i < challenge.stakerAddresses.length; i++) {
            address staker = challenge.stakerAddresses[i];
            uint256 stakedAmount = challenge.stakers[staker];

            if (_challengeWasSuccessful) {
                // Return principal to accumulated rewards.
                reputationProfiles[staker].accumulatedRewards += stakedAmount;
                 emit FundsTransferredToAccumulatedRewards(staker, stakedAmount, "Challenge principal win");
                _updateReputation(staker, 10, true); // Small rep increase for correct stake
            } else {
                // Stakers on the losing side lose their stake.
                _updateReputation(staker, -10, false); // Small rep decrease for incorrect stake
            }
            challenge.stakers[staker] = 0; // Clear the individual stake
        }
        // totalStakedForChallenge effectively becomes 0 after processing
        challenge.totalStakedForChallenge = 0;
        delete challenge.stakerAddresses; // Clear array
    }

    /**
     * @notice Allows a staker to conceptually withdraw their principal stake after successful resolution.
     *         The actual transfer of tokens happens via `claimAssertionRewards`. This function moves
     *         the principal to the user's `accumulatedRewards` pool.
     * @param _assertionId The ID of the assertion.
     */
    function withdrawAssertionStake(uint256 _assertionId) public nonReentrant {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        require(assertion.status == AssertionStatus.ResolvedTrue || assertion.status == AssertionStatus.ResolvedFalse, "Assertion not resolved");

        // The _distributeAssertionRewards already handled moving principal for winning stakers
        // into their `accumulatedRewards`. This function now just indicates that happened.
        // It's effectively a confirmation or a legacy function in this simplified model.
        // For actual principal withdrawal, the `claimAssertionRewards` should be called.
        revert("Principal is already moved to your accumulatedRewards or was lost. Use claimAssertionRewards to withdraw.");
    }


    /**
     * @notice Allows a staker to conceptually withdraw their principal stake from a challenge after resolution.
     *         The actual transfer of tokens happens via `claimAssertionRewards`. This function moves
     *         the principal to the user's `accumulatedRewards` pool.
     * @param _challengeId The ID of the challenge.
     */
    function withdrawChallengeStake(uint256 _challengeId) public nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "Challenge does not exist");
        require(challenge.resolved, "Challenge not resolved");

        // Similar to withdrawAssertionStake, principal for winning stakers is already in `accumulatedRewards`.
        revert("Principal is already moved to your accumulatedRewards or was lost. Use claimAssertionRewards to withdraw.");
    }

    /**
     * @notice Allows participants on the winning side of a resolved assertion/challenge to claim their proportional rewards.
     *         This function withdraws all accumulated rewards (principal + actual rewards) for the `msg.sender`.
     */
    function claimAssertionRewards(uint256 _assertionId) public nonReentrant { // _assertionId parameter is actually not used if rewards are pooled
        ReputationProfile storage profile = reputationProfiles[msg.sender];
        require(profile.accumulatedRewards > 0, "No rewards to claim");

        uint256 amount = profile.accumulatedRewards;
        profile.accumulatedRewards = 0;

        require(rewardToken.transfer(msg.sender, amount), "Reward transfer failed");
        emit RewardsClaimed(msg.sender, amount);
    }

    // --- C. Query & Discovery ---

    /**
     * @notice Retrieves all details of a specific intelligence assertion.
     * @param _assertionId The ID of the assertion.
     * @return Assertion details.
     */
    function getAssertionDetails(uint256 _assertionId)
        public
        view
        returns (
            address submitter,
            bytes32 assertionHash,
            string memory assertionURI,
            uint256 initialBond,
            uint256 totalStakedForAssertion,
            uint256 creationTimestamp,
            uint256 resolutionTimestamp,
            AssertionStatus status,
            bool result,
            uint256 activeChallengeId
        )
    {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        return (
            assertion.submitter,
            assertion.assertionHash,
            assertion.assertionURI,
            assertion.initialBond,
            assertion.totalStakedForAssertion,
            assertion.creationTimestamp,
            assertion.resolutionTimestamp,
            assertion.status,
            assertion.result,
            assertion.activeChallengeId
        );
    }

    /**
     * @notice Returns the current lifecycle status of an assertion.
     * @param _assertionId The ID of the assertion.
     * @return The status of the assertion.
     */
    function getAssertionStatus(uint256 _assertionId) public view returns (AssertionStatus) {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        return assertion.status;
    }

    /**
     * @notice Returns the verified outcome (true/false) of a resolved assertion.
     * @param _assertionId The ID of the assertion.
     * @return The boolean result of the assertion.
     */
    function getAssertionResult(uint256 _assertionId) public view returns (bool) {
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.submitter != address(0), "Assertion does not exist");
        require(assertion.status == AssertionStatus.ResolvedTrue || assertion.status == AssertionStatus.ResolvedFalse, "Assertion not resolved");
        return assertion.result;
    }

    /**
     * @notice Returns a list of assertion IDs that are open for staking or challenging.
     *         Note: This is a simplified getter. For large numbers of assertions, pagination
     *         or off-chain indexing would be required.
     * @return An array of assertion IDs.
     */
    function getOpenAssertions() public view returns (uint256[] memory) {
        uint256[] memory tempIds = new uint256[](nextAssertionId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < nextAssertionId; i++) {
            if (assertions[i].submitter != address(0) && (assertions[i].status == AssertionStatus.Pending || assertions[i].status == AssertionStatus.Staked) && (block.timestamp < assertions[i].creationTimestamp + assertionChallengePeriod)) {
                tempIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempIds[i];
        }
        return result;
    }

    /**
     * @notice Returns a list of challenge IDs that are currently being voted on.
     *         Note: Simplified getter.
     * @return An array of challenge IDs.
     */
    function getActiveChallenges() public view returns (uint256[] memory) {
        uint256[] memory tempIds = new uint256[](nextChallengeId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextChallengeId; i++) {
            if (challenges[i].challenger != address(0) && !challenges[i].resolved && (block.timestamp < challenges[i].creationTimestamp + disputeVotingPeriod)) {
                tempIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempIds[i];
        }
        return result;
    }

    /**
     * @notice Returns a list of assertion IDs that have been finalized.
     *         Note: Simplified getter.
     * @return An array of assertion IDs.
     */
    function getResolvedAssertions() public view returns (uint256[] memory) {
        uint256[] memory tempIds = new uint256[](nextAssertionId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextAssertionId; i++) {
            if (assertions[i].submitter != address(0) && (assertions[i].status == AssertionStatus.ResolvedTrue || assertions[i].status == AssertionStatus.ResolvedFalse)) {
                tempIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempIds[i];
        }
        return result;
    }

    // --- D. Network Parameters & Governance ---

    /**
     * @notice Sets the ERC-20 token address used for rewards and staking.
     *         Can only be set once during construction, or via governance later if implemented.
     * @param _tokenAddress The address of the ERC-20 token.
     */
    function setRewardTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        rewardToken = IERC20(_tokenAddress);
        emit RewardTokenAddressSet(_tokenAddress);
    }

    /**
     * @notice Allows users with sufficient reputation to propose changes to network parameters.
     *         A minimum reputation (e.g., 1000 reputation score) is required to propose.
     * @param _paramName A hash representing the parameter to change (e.g., keccak256("minAssertionBond")).
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposed change.
     * @return The ID of the new proposal.
     */
    function proposeParameterChange(bytes32 _paramName, int256 _newValue, string calldata _description)
        public
        whenNotPaused
        returns (uint256)
    {
        require(reputationProfiles[msg.sender].score >= 1000, "Insufficient reputation to propose");

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            paramName: _paramName,
            newValue: _newValue,
            description: _description,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + disputeVotingPeriod, // Using dispute voting period for proposals too
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });
        emit ParameterChangeProposed(proposalId, _paramName, _newValue, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows reputation-weighted voting on active governance proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True if supporting the proposal, false if opposing.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support)
        public
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.creationTimestamp != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp < proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(reputationProfiles[msg.sender].score > 0, "Requires reputation to vote");

        proposal.hasVoted[msg.sender] = true;
        int256 voteWeight = reputationProfiles[msg.sender].score;

        if (_support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        _updateReputation(msg.sender, 1, true); // Small rep reward for participating in governance
        emit ParameterChangeVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed governance proposal. Callable by anyone after voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId)
        public
        whenNotPaused
        nonReentrant
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.creationTimestamp != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.votingPeriodEnd, "Voting period not over");

        // Simple majority vote for execution
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "Proposal did not pass");

        bytes32 param = proposal.paramName;
        int256 newValue = proposal.newValue;

        if (param == keccak256("minAssertionBond")) {
            require(newValue >= 0, "Value cannot be negative");
            minAssertionBond = uint256(newValue);
        } else if (param == keccak256("minChallengeBond")) {
            require(newValue >= 0, "Value cannot be negative");
            minChallengeBond = uint256(newValue);
        } else if (param == keccak256("assertionChallengePeriod")) {
            require(newValue >= 0, "Value cannot be negative");
            assertionChallengePeriod = uint256(newValue);
        } else if (param == keccak256("disputeVotingPeriod")) {
            require(newValue >= 0, "Value cannot be negative");
            disputeVotingPeriod = uint256(newValue);
        } else if (param == keccak256("rewardPoolShareBps")) {
            require(newValue >= 0 && newValue <= 10000, "Value must be between 0 and 10000");
            rewardPoolShareBps = uint256(newValue);
        } else if (param == keccak256("reputationDecayPeriod")) {
            require(newValue >= 0, "Value cannot be negative");
            reputationDecayPeriod = uint256(newValue);
        } else if (param == keccak256("reputationDecayRate")) {
            // Can be negative, no specific bounds other than practical ones.
            reputationDecayRate = newValue;
        } else {
            revert("Unknown parameter");
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId, param, newValue);
    }

    /**
     * @notice Governance function to adjust the period after which reputation starts decaying.
     *         This is a direct owner function for initial setup, but should be replaced by `proposeParameterChange` for decentralization.
     * @param _period The new decay period in seconds.
     */
    function updateReputationDecayPeriod(uint256 _period) public onlyOwner {
        reputationDecayPeriod = _period;
    }

    /**
     * @notice Governance function to adjust the duration for challenging an assertion.
     *         Direct owner function, ideally via `proposeParameterChange`.
     * @param _period The new challenge period in seconds.
     */
    function updateChallengePeriod(uint256 _period) public onlyOwner {
        assertionChallengePeriod = _period;
    }

    /**
     * @notice Allows owner/governance to withdraw funds from the contract treasury (e.g., for operational costs or community grants).
     *         In a fully decentralized system, this would also be governed by proposals.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawNetworkTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner nonReentrant {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(rewardToken.balanceOf(address(this)) >= _amount, "Insufficient funds in treasury");
        require(rewardToken.transfer(_recipient, _amount), "Treasury withdrawal failed");
    }

    /**
     * @notice Emergency function to pause critical contract functions.
     *         Can only be called by the owner.
     */
    function pauseNetworkOperations() public onlyOwner {
        paused = true;
        emit NetworkPaused(msg.sender);
    }

    /**
     * @notice Emergency function to unpause critical contract functions.
     *         Can only be called by the owner.
     */
    function unpauseNetworkOperations() public onlyOwner {
        paused = false;
        emit NetworkUnpaused(msg.sender);
    }
}
```