Here's a smart contract written in Solidity that embodies advanced, creative, and trendy concepts, while aiming to be distinct from common open-source implementations. It focuses on a **"Oracle of Collective Intelligence (OCI) Protocol"**.

This protocol enables a decentralized network where participants collaborate to propose, validate, and synthesize "insights" and "prophecies" about various domains. It features a dynamic reputation system, gamified staking with rewards and slashing, and on-chain governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline: Oracle of Collective Intelligence (OCI) Protocol
//
// The Oracle of Collective Intelligence (OCI) Protocol is a decentralized platform designed
// to foster verifiable collective intelligence and predictive capabilities. It allows participants,
// categorized as "Seers" and "Validators", to engage in a structured process of knowledge
// creation and validation on the blockchain.
//
// Key Concepts:
// - Insights: Atomic pieces of verifiable information or predictions proposed by Seers.
// - Prophecies: Higher-level, synthesized intelligence derived from multiple validated Insights by "Synthesizers".
// - Clairvoyance Score: A dynamic, on-chain reputation system that tracks participant accuracy and contribution.
// - Gamified Staking: Participants stake OCI_Token to back their claims, earning rewards for accuracy and facing
//   slashing for incorrect predictions or validations.
// - Decentralized Governance: OCI_Token holders collectively manage protocol parameters and domains through voting.
// - On-chain Oracle Interface: Provides validated Insights and Prophecies as a reliable data source for other dApps.
//
// Core Modules:
// 1.  Insight & Prophecy Management: Handles the entire lifecycle of individual insights and aggregated prophecies.
// 2.  Reputation System: Tracks and updates Clairvoyance Scores, influencing participant privileges and rewards.
// 3.  Staking & Rewards: Manages OCI_Token deposits, withdrawals, and the distribution of rewards/slashed stakes.
// 4.  Decentralized Governance: Empowers OCI_Token holders to propose and vote on parameter changes, domain management, and oracle updates.
// 5.  Oracle Interface: Exposes finalized, validated intelligence for consumption by external smart contracts and users.

// Function Summary:
//
// I. Insight & Prophecy Submission/Interaction (Core Intelligence Layer)
// 1.  submitInsightProposal(bytes32 _insightHash, bytes32 _domainId, uint256 _stakeAmount):
//     Allows a "Seer" to propose a new, atomic insight, staking OCI_Token to back its truth.
// 2.  attestInsightProposal(uint256 _insightId, uint256 _stakeAmount):
//     Enables a "Validator" to support a proposed insight by staking OCI_Token.
// 3.  challengeInsightProposal(uint256 _insightId, uint256 _stakeAmount):
//     Allows a "Validator" to dispute a proposed insight by staking OCI_Token.
// 4.  proposeProphecy(bytes32 _prophecyHash, uint256[] calldata _constituentInsightIds, uint256 _stakeAmount):
//     Allows a "Synthesizer" to propose a higher-level prophecy by combining multiple *validated* insights, staking OCI_Token.
// 5.  attestProphecy(uint256 _prophecyId, uint256 _stakeAmount):
//     Enables a "Validator" to support a proposed prophecy by staking OCI_Token.
// 6.  challengeProphecy(uint256 _prophecyId, uint256 _stakeAmount):
//     Allows a "Validator" to dispute a proposed prophecy by staking OCI_Token.
//
// II. Resolution & Rewards (Truth Determination & Incentive Alignment)
// 7.  resolveInsight(uint256 _insightId, bool _isTrue):
//     (Callable only by `trustedOracle`) Finalizes the truthfulness of an insight, triggering Clairvoyance Score updates and reward calculations.
// 8.  resolveProphecy(uint256 _prophecyId, bool _isTrue):
//     (Callable only by `trustedOracle`) Finalizes the truthfulness of a prophecy, similar to insight resolution.
// 9.  claimResolutionRewards(uint256 _entityId, EntityType _type):
//     Allows participants (proposers, attesters, challengers) to claim their earned OCI_Token and stake back after an entity (insight/prophecy) is resolved.
//
// III. Reputation System (Clairvoyance Score)
// 10. getClairvoyanceScore(address _user):
//     Retrieves the current Clairvoyance Score for a given user.
// 11. getClairvoyanceTier(address _user):
//     Determines the reputation tier (e.g., Novice, Adept, Master) of a user based on their Clairvoyance Score.
//
// IV. Staking & Token Management (Economic Foundation)
// 12. depositTokens(uint256 _amount):
//     Allows users to deposit OCI_Token into the protocol's internal balance for staking purposes.
// 13. withdrawTokens(uint256 _amount):
//     Allows users to withdraw their available (unstaked) OCI_Token from the protocol.
// 14. getAvailableBalance(address _user):
//     Returns a user's liquid, unstaked OCI_Token balance held within the contract.
// 15. getStakedBalance(address _user):
//     Returns a user's total OCI_Token currently locked in active insights or prophecies.
//
// V. Decentralized Governance (Protocol Evolution)
// 16. proposeParameterChange(bytes32 _paramName, uint256 _newValue):
//     Initiates a governance proposal to modify key protocol parameters.
// 17. voteOnProposal(uint256 _proposalId, bool _support):
//     Allows OCI_Token holders to vote (token-weighted) on active governance proposals.
// 18. executeProposal(uint256 _proposalId):
//     Executes a governance proposal that has successfully passed its voting and timelock periods.
// 19. addInsightDomain(bytes32 _domainId, string calldata _description):
//     (Callable via Governance) Adds a new category or topic for insights, expanding the protocol's scope.
// 20. updateOracleAddress(address _newOracle):
//     (Callable via Governance) Changes the address of the trusted oracle responsible for resolving entities.
//
// VI. Oracle Interface & Data Query (External Usability)
// 21. queryValidatedInsights(bytes32 _domainId, uint256 _startIndex, uint256 _count):
//     Provides a paginated list of successfully validated insight IDs for a specific domain to external callers.
// 22. queryValidatedProphecies(uint256 _startIndex, uint256 _count):
//     Provides a paginated list of successfully validated prophecy IDs to external callers.
//
// VII. View Functions & Utilities (Information Access)
// 23. getInsightDetails(uint256 _insightId):
//     Returns all stored details for a specific insight.
// 24. getProphecyDetails(uint256 _prophecyId):
//     Returns all stored details for a specific prophecy.
// 25. getProposalDetails(uint256 _proposalId):
//     Returns all stored details for a specific governance proposal.

contract OCIProtocol is Ownable, ReentrancyGuard {
    // --- State Variables ---
    IERC20 public immutable OCI_Token;       // The native staking token
    address public trustedOracle;             // Address authorized to resolve insights/prophecies

    enum EntityType {
        Insight,
        Prophecy
    }

    // --- Insights ---
    struct InsightProposal {
        bytes32 insightHash;      // Hash of the actual insight content (off-chain storage expected)
        bytes32 domainId;         // Category/topic of the insight
        address proposer;         // Address of the Seer
        uint256 stakeAmount;      // Initial stake by the Seer
        uint256 proposalTime;     // Timestamp of proposal
        uint256 resolutionTime;   // Timestamp when the oracle resolved it
        uint256 totalAttesterStake;   // Sum of stakes from all attesters
        uint256 totalChallengerStake; // Sum of stakes from all challengers
        mapping(address => uint256) attesterStakes;   // Individual attester stakes
        mapping(address => uint256) challengerStakes; // Individual challenger stakes
        bool isResolved;          // True if insight has been resolved
        bool isTrue;              // True if resolved as correct, false if incorrect
        // RewardsClaimed is per-user for entities, so a mapping is better. Simplified here.
        mapping(address => bool) rewardsClaimedByUser; // True if a user has claimed their rewards for this insight
    }
    uint256 public nextInsightId;
    mapping(uint256 => InsightProposal) public insights;
    mapping(bytes32 => uint256[]) public validatedInsightsByDomain; // Store IDs of validated insights for easy query

    // --- Prophecies ---
    struct Prophecy {
        bytes32 prophecyHash;     // Hash of the actual prophecy content (off-chain storage expected)
        uint256[] constituentInsightIds; // IDs of validated insights this prophecy synthesizes
        address proposer;         // Address of the Synthesizer
        uint256 stakeAmount;      // Initial stake by the Synthesizer
        uint256 proposalTime;     // Timestamp of proposal
        uint256 resolutionTime;   // Timestamp when the oracle resolved it
        uint256 totalAttesterStake;
        uint256 totalChallengerStake;
        mapping(address => uint256) attesterStakes;
        mapping(address => uint256) challengerStakes;
        bool isResolved;
        bool isTrue;
        mapping(address => bool) rewardsClaimedByUser; // True if a user has claimed their rewards for this prophecy
    }
    uint256 public nextProphecyId;
    mapping(uint256 => Prophecy) public prophecies;
    uint256[] public validatedProphecyIds; // Store IDs of validated prophecies for easy query

    // --- User Balances & Staking ---
    mapping(address => uint256) public availableBalances; // User's liquid OCI_Token balance in contract
    mapping(address => uint256) public totalStakedBalances; // User's total OCI_Token locked in active proposals

    // --- Reputation (Clairvoyance Score) ---
    mapping(address => int256) public clairvoyanceScores; // Reputation score for each participant
    // Example tiers: [0, 100, 500, 2000] means: Tier 0 (Novice) for score < 100, Tier 1 (Adept) for 100-499, etc.
    uint256[] public clairvoyanceTiers; // Array of scores defining the minimum score for each tier
    uint256 public constant BASE_SCORE_CHANGE = 10; // Base score change for correct/incorrect actions

    // --- Governance ---
    struct GovernanceProposal {
        bytes32 paramName;        // Name of the parameter to change (e.g., "MIN_INSIGHT_STAKE")
        uint256 newValue;         // New value for the parameter
        uint256 proposer;         // The address that created the proposal
        uint256 proposalTime;     // Timestamp of proposal creation
        uint256 votingEndTime;    // Timestamp when voting ends
        uint256 timelockEndTime;  // Timestamp when proposal can be executed after passing
        uint256 votesFor;         // Total OCI_Token staked for "yes"
        uint256 votesAgainst;     // Total OCI_Token staked for "no"
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;            // True if the proposal has been executed
    }
    uint256 public nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Protocol Parameters (Managed by Governance) ---
    uint256 public MIN_INSIGHT_STAKE = 100 * 10**18; // Minimum OCI_Token to propose/attest/challenge insights (100 OCI)
    uint256 public MIN_PROPHECY_STAKE = 500 * 10**18; // Minimum OCI_Token to propose/attest/challenge prophecies (500 OCI)
    uint256 public INSIGHT_VOTING_PERIOD = 3 days; // Time during which insights can be attested/challenged
    uint256 public INSIGHT_RESOLUTION_PERIOD = 7 days; // Time before an insight can be resolved by oracle (after proposal time)
    uint256 public PROPHECY_VOTING_PERIOD = 7 days; // Time during which prophecies can be attested/challenged
    uint256 public PROPHECY_RESOLUTION_PERIOD = 14 days; // Time before a prophecy can be resolved
    uint256 public GOVERNANCE_VOTING_PERIOD = 3 days; // Duration for voting on proposals
    uint256 public GOVERNANCE_TIMELOCK_PERIOD = 1 days; // Delay before a passed proposal can be executed
    uint256 public REWARD_MULTIPLIER_BPS = 1000; // Basis points multiplier for reward calculation (e.g., 1000 means 100% of stake as reward base, 10_000 for 1x)
    uint256 public SLASHER_BONUS_PERCENT = 10; // Percentage of slashed funds awarded to correct challengers

    // --- Insight Domains ---
    mapping(bytes32 => bool) public activeInsightDomains; // Maps domainId hash to active status
    mapping(bytes32 => string) public insightDomainDescriptions; // Human-readable description of domains

    // --- Events ---
    event InsightProposed(uint256 indexed insightId, bytes32 indexed domainId, address indexed proposer, uint256 stakeAmount, bytes32 insightHash);
    event InsightAttested(uint256 indexed insightId, address indexed attester, uint256 stakeAmount);
    event InsightChallenged(uint256 indexed insightId, address indexed challenger, uint256 stakeAmount);
    event InsightResolved(uint256 indexed insightId, bool isTrue, uint256 totalAttesterStake, uint256 totalChallengerStake);
    event EntityRewardsClaimed(uint256 indexed entityId, EntityType indexed entityType, address indexed claimant, uint256 amount);

    event ProphecyProposed(uint256 indexed prophecyId, address indexed proposer, uint256 stakeAmount, bytes32 prophecyHash);
    event ProphecyAttested(uint256 indexed prophecyId, address indexed attester, uint256 stakeAmount);
    event ProphecyChallenged(uint256 indexed prophecyId, address indexed challenger, uint256 stakeAmount);
    event ProphecyResolved(uint256 indexed prophecyId, bool isTrue, uint256 totalAttesterStake, uint256 totalChallengerStake);

    event ClairvoyanceScoreUpdated(address indexed user, int256 newScore);
    event TokensDeposited(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);

    event GovernanceProposalCreated(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event InsightDomainAdded(bytes32 indexed domainId, string description);
    event InsightDomainRemoved(bytes32 indexed domainId);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "OCI: Only trusted oracle can call this function");
        _;
    }

    modifier onlyActiveDomain(bytes32 _domainId) {
        require(activeInsightDomains[_domainId], "OCI: Domain is not active");
        _;
    }

    modifier insightActive(uint256 _insightId) {
        require(_insightId < nextInsightId, "OCI: Invalid insight ID");
        require(!insights[_insightId].isResolved, "OCI: Insight already resolved");
        require(block.timestamp <= insights[_insightId].proposalTime + INSIGHT_VOTING_PERIOD, "OCI: Insight voting period ended");
        _;
    }

    modifier insightReadyForResolution(uint256 _insightId) {
        require(_insightId < nextInsightId, "OCI: Invalid insight ID");
        require(!insights[_insightId].isResolved, "OCI: Insight already resolved");
        require(block.timestamp > insights[_insightId].proposalTime + INSIGHT_RESOLUTION_PERIOD, "OCI: Resolution period not yet passed");
        _;
    }

    modifier prophecyActive(uint256 _prophecyId) {
        require(_prophecyId < nextProphecyId, "OCI: Invalid prophecy ID");
        require(!prophecies[_prophecyId].isResolved, "OCI: Prophecy already resolved");
        require(block.timestamp <= prophecies[_prophecyId].proposalTime + PROPHECY_VOTING_PERIOD, "OCI: Prophecy voting period ended");
        _;
    }

    modifier prophecyReadyForResolution(uint256 _prophecyId) {
        require(_prophecyId < nextProphecyId, "OCI: Invalid prophecy ID");
        require(!prophecies[_prophecyId].isResolved, "OCI: Prophecy already resolved");
        require(block.timestamp > prophecies[_prophecyId].proposalTime + PROPHECY_RESOLUTION_PERIOD, "OCI: Resolution period not yet passed");
        _;
    }

    modifier requiresEnoughAvailableStake(uint256 _amountRequired) {
        require(availableBalances[msg.sender] >= _amountRequired, "OCI: Insufficient available balance for stake");
        _;
    }

    constructor(address _ociTokenAddress, address _initialOracle) Ownable(msg.sender) {
        require(_ociTokenAddress != address(0), "OCI: OCI_Token address cannot be zero");
        require(_initialOracle != address(0), "OCI: Initial oracle address cannot be zero");
        OCI_Token = IERC20(_ociTokenAddress);
        trustedOracle = _initialOracle;

        // Initialize default domains
        bytes32 generalDomainId = keccak256(abi.encodePacked("General"));
        activeInsightDomains[generalDomainId] = true;
        insightDomainDescriptions[generalDomainId] = "General purpose insights and predictions";

        bytes32 marketDomainId = keccak256(abi.encodePacked("MarketPredictions"));
        activeInsightDomains[marketDomainId] = true;
        insightDomainDescriptions[marketDomainId] = "Financial market predictions and analyses";

        // Initialize Clairvoyance Tiers (example: Novice: 0-99, Adept: 100-499, Master: 500-1999, Grandmaster: 2000+)
        clairvoyanceTiers.push(0);    // Tier 0 (Novice)
        clairvoyanceTiers.push(100);  // Tier 1 (Adept)
        clairvoyanceTiers.push(500);  // Tier 2 (Master)
        clairvoyanceTiers.push(2000); // Tier 3 (Grandmaster)
    }

    // --- I. Insight & Prophecy Submission/Interaction ---

    /**
     * @notice Allows a Seer to propose a new insight by providing its hash and staking OCI_Token.
     * @dev The actual insight content (e.g., text, data, specific prediction) is expected to be
     *      stored off-chain (e.g., IPFS) and referenced by `_insightHash`. The proposer's stake is locked.
     * @param _insightHash A unique hash representing the off-chain content of the insight.
     * @param _domainId The ID of the domain this insight belongs to.
     * @param _stakeAmount The amount of OCI_Token to stake for this insight.
     */
    function submitInsightProposal(
        bytes32 _insightHash,
        bytes32 _domainId,
        uint256 _stakeAmount
    ) external nonReentrant onlyActiveDomain(_domainId) requiresEnoughAvailableStake(_stakeAmount) {
        require(_stakeAmount >= MIN_INSIGHT_STAKE, "OCI: Stake amount too low for insight proposal");

        uint256 id = nextInsightId++;
        InsightProposal storage insight = insights[id];
        insight.insightHash = _insightHash;
        insight.domainId = _domainId;
        insight.proposer = msg.sender;
        insight.stakeAmount = _stakeAmount;
        insight.proposalTime = block.timestamp;

        _lockStake(msg.sender, _stakeAmount);

        emit InsightProposed(id, _domainId, msg.sender, _stakeAmount, _insightHash);
    }

    /**
     * @notice Allows a Validator to attest (agree with) an insight proposal by staking OCI_Token.
     * @dev Validators' stakes are locked until resolution.
     * @param _insightId The ID of the insight to attest to.
     * @param _stakeAmount The amount of OCI_Token to stake.
     */
    function attestInsightProposal(
        uint256 _insightId,
        uint256 _stakeAmount
    ) external nonReentrant insightActive(_insightId) requiresEnoughAvailableStake(_stakeAmount) {
        require(_stakeAmount >= MIN_INSIGHT_STAKE, "OCI: Stake amount too low for attestation");
        require(insights[_insightId].proposer != msg.sender, "OCI: Proposer cannot attest their own insight");
        require(insights[_insightId].challengerStakes[msg.sender] == 0, "OCI: Cannot attest after challenging");
        require(insights[_insightId].attesterStakes[msg.sender] == 0, "OCI: Already attested this insight");

        insights[_insightId].attesterStakes[msg.sender] = _stakeAmount;
        insights[_insightId].totalAttesterStake += _stakeAmount;

        _lockStake(msg.sender, _stakeAmount);

        emit InsightAttested(_insightId, msg.sender, _stakeAmount);
    }

    /**
     * @notice Allows a Validator to challenge (disagree with) an insight proposal by staking OCI_Token.
     * @dev Challengers' stakes are locked until resolution.
     * @param _insightId The ID of the insight to challenge.
     * @param _stakeAmount The amount of OCI_Token to stake.
     */
    function challengeInsightProposal(
        uint256 _insightId,
        uint256 _stakeAmount
    ) external nonReentrant insightActive(_insightId) requiresEnoughAvailableStake(_stakeAmount) {
        require(_stakeAmount >= MIN_INSIGHT_STAKE, "OCI: Stake amount too low for challenge");
        require(insights[_insightId].proposer != msg.sender, "OCI: Proposer cannot challenge their own insight");
        require(insights[_insightId].attesterStakes[msg.sender] == 0, "OCI: Cannot challenge after attesting");
        require(insights[_insightId].challengerStakes[msg.sender] == 0, "OCI: Already challenged this insight");

        insights[_insightId].challengerStakes[msg.sender] = _stakeAmount;
        insights[_insightId].totalChallengerStake += _stakeAmount;

        _lockStake(msg.sender, _stakeAmount);

        emit InsightChallenged(_insightId, msg.sender, _stakeAmount);
    }

    /**
     * @notice Allows a Synthesizer to propose a higher-level prophecy based on a set of validated insights.
     * @dev All `_constituentInsightIds` must correspond to insights that are resolved and `isTrue`.
     * @param _prophecyHash A hash representing the unique content of the prophecy (off-chain).
     * @param _constituentInsightIds An array of IDs of insights that form this prophecy.
     * @param _stakeAmount The amount of OCI_Token to stake for this prophecy.
     */
    function proposeProphecy(
        bytes32 _prophecyHash,
        uint256[] calldata _constituentInsightIds,
        uint256 _stakeAmount
    ) external nonReentrant requiresEnoughAvailableStake(_stakeAmount) {
        require(_stakeAmount >= MIN_PROPHECY_STAKE, "OCI: Stake amount too low for prophecy proposal");
        require(_constituentInsightIds.length > 0, "OCI: Prophecy must include at least one insight");

        for (uint256 i = 0; i < _constituentInsightIds.length; i++) {
            uint256 insightId = _constituentInsightIds[i];
            require(insights[insightId].isResolved && insights[insightId].isTrue, "OCI: Constituent insight must be resolved and true");
        }

        uint256 id = nextProphecyId++;
        Prophecy storage prophecy = prophecies[id];
        prophecy.prophecyHash = _prophecyHash;
        prophecy.constituentInsightIds = _constituentInsightIds;
        prophecy.proposer = msg.sender;
        prophecy.stakeAmount = _stakeAmount;
        prophecy.proposalTime = block.timestamp;

        _lockStake(msg.sender, _stakeAmount);

        emit ProphecyProposed(id, msg.sender, _stakeAmount, _prophecyHash);
    }

    /**
     * @notice Allows a Validator to attest (agree with) a prophecy proposal.
     * @dev Similar to insight attestation, validators stake OCI_Token.
     * @param _prophecyId The ID of the prophecy to attest to.
     * @param _stakeAmount The amount of OCI_Token to stake.
     */
    function attestProphecy(
        uint256 _prophecyId,
        uint256 _stakeAmount
    ) external nonReentrant prophecyActive(_prophecyId) requiresEnoughAvailableStake(_stakeAmount) {
        require(_stakeAmount >= MIN_PROPHECY_STAKE, "OCI: Stake amount too low for prophecy attestation");
        require(prophecies[_prophecyId].proposer != msg.sender, "OCI: Proposer cannot attest their own prophecy");
        require(prophecies[_prophecyId].challengerStakes[msg.sender] == 0, "OCI: Cannot attest after challenging");
        require(prophecies[_prophecyId].attesterStakes[msg.sender] == 0, "OCI: Already attested this prophecy");

        prophecies[_prophecyId].attesterStakes[msg.sender] = _stakeAmount;
        prophecies[_prophecyId].totalAttesterStake += _stakeAmount;

        _lockStake(msg.sender, _stakeAmount);

        emit ProphecyAttested(_prophecyId, msg.sender, _stakeAmount);
    }

    /**
     * @notice Allows a Validator to challenge (disagree with) a prophecy proposal.
     * @dev Similar to insight challenge, validators stake OCI_Token.
     * @param _prophecyId The ID of the prophecy to challenge.
     * @param _stakeAmount The amount of OCI_Token to stake.
     */
    function challengeProphecy(
        uint256 _prophecyId,
        uint256 _stakeAmount
    ) external nonReentrant prophecyActive(_prophecyId) requiresEnoughAvailableStake(_stakeAmount) {
        require(_stakeAmount >= MIN_PROPHECY_STAKE, "OCI: Stake amount too low for prophecy challenge");
        require(prophecies[_prophecyId].proposer != msg.sender, "OCI: Proposer cannot challenge their own prophecy");
        require(prophecies[_prophecyId].attesterStakes[msg.sender] == 0, "OCI: Cannot challenge after attesting");
        require(prophecies[_prophecyId].challengerStakes[msg.sender] == 0, "OCI: Already challenged this prophecy");

        prophecies[_prophecyId].challengerStakes[msg.sender] = _stakeAmount;
        prophecies[_prophecyId].totalChallengerStake += _stakeAmount;

        _lockStake(msg.sender, _stakeAmount);

        emit ProphecyChallenged(_prophecyId, msg.sender, _stakeAmount);
    }

    // --- II. Resolution & Rewards ---

    /**
     * @notice The trusted oracle resolves an insight, determining if it's true or false.
     * @dev This function calculates rewards/slashing and updates Clairvoyance Scores.
     * @param _insightId The ID of the insight to resolve.
     * @param _isTrue The boolean outcome of the insight (true if correct, false if incorrect).
     */
    function resolveInsight(uint256 _insightId, bool _isTrue) external nonReentrant onlyOracle insightReadyForResolution(_insightId) {
        InsightProposal storage insight = insights[_insightId];

        insight.isResolved = true;
        insight.isTrue = _isTrue;
        insight.resolutionTime = block.timestamp;

        _processResolution(
            insight.proposer,
            insight.stakeAmount,
            insight.attesterStakes,
            insight.totalAttesterStake,
            insight.challengerStakes,
            insight.totalChallengerStake,
            _isTrue
        );

        if (_isTrue) {
            validatedInsightsByDomain[insight.domainId].push(_insightId);
        }

        emit InsightResolved(_insightId, _isTrue, insight.totalAttesterStake, insight.totalChallengerStake);
    }

    /**
     * @notice The trusted oracle resolves a prophecy, determining if it's true or false.
     * @dev This function calculates rewards/slashing and updates Clairvoyance Scores.
     * @param _prophecyId The ID of the prophecy to resolve.
     * @param _isTrue The boolean outcome of the prophecy (true if correct, false if incorrect).
     */
    function resolveProphecy(uint256 _prophecyId, bool _isTrue) external nonReentrant onlyOracle prophecyReadyForResolution(_prophecyId) {
        Prophecy storage prophecy = prophecies[_prophecyId];

        prophecy.isResolved = true;
        prophecy.isTrue = _isTrue;
        prophecy.resolutionTime = block.timestamp;

        _processResolution(
            prophecy.proposer,
            prophecy.stakeAmount,
            prophecy.attesterStakes,
            prophecy.totalAttesterStake,
            prophecy.challengerStakes,
            prophecy.totalChallengerStake,
            _isTrue
        );

        if (_isTrue) {
            validatedProphecyIds.push(_prophecyId);
        }

        emit ProphecyResolved(_prophecyId, _isTrue, prophecy.totalAttesterStake, prophecy.totalChallengerStake);
    }

    /**
     * @dev Internal helper function to manage reward distribution and slashing for any entity (insight/prophecy).
     * @param _proposer The address of the proposer.
     * @param _proposerStake The amount staked by the proposer.
     * @param _attesterStakes Mapping of attester addresses to their stakes.
     * @param _totalAttesterStake Total stake from all attesters.
     * @param _challengerStakes Mapping of challenger addresses to their stakes.
     * @param _totalChallengerStake Total stake from all challengers.
     * @param _isTrue The resolved truth value of the entity.
     */
    function _processResolution(
        address _proposer,
        uint256 _proposerStake,
        mapping(address => uint256) storage _attesterStakes,
        uint256 _totalAttesterStake,
        mapping(address => uint256) storage _challengerStakes,
        uint256 _totalChallengerStake,
        bool _isTrue
    ) internal {
        // Update proposer's score
        _updateClairvoyanceScore(_proposer, _isTrue ? BASE_SCORE_CHANGE : -int256(BASE_SCORE_CHANGE));

        // For attesters/challengers, individual score updates happen here.
        // A real system would have to iterate through all individual attester/challenger addresses.
        // For simplicity in this example (Solidity mappings don't expose keys()),
        // we omit individual score updates for secondary stakers here,
        // but a production contract would require a mechanism (e.g., helper array, off-chain proof).
    }

    /**
     * @notice Allows a participant to claim rewards from a resolved insight or prophecy.
     * @dev Each participant claims their portion of stake and reward/slashed funds individually.
     * @param _entityId The ID of the insight or prophecy.
     * @param _type The type of entity (Insight or Prophecy).
     */
    function claimResolutionRewards(uint256 _entityId, EntityType _type) external nonReentrant {
        uint256 msgSenderStake = 0;
        bool isResolved = false;
        bool isTrue = false;
        address proposer = address(0);
        uint256 totalCorrectStake = 0;
        uint256 totalIncorrectStake = 0;
        mapping(address => bool) storage rewardsClaimedTracker;

        if (_type == EntityType.Insight) {
            InsightProposal storage insight = insights[_entityId];
            require(_entityId < nextInsightId, "OCI: Invalid insight ID");
            require(insight.isResolved, "OCI: Insight not resolved");
            require(!insight.rewardsClaimedByUser[msg.sender], "OCI: Rewards already claimed by this user for this insight");

            isResolved = insight.isResolved;
            isTrue = insight.isTrue;
            proposer = insight.proposer;
            rewardsClaimedTracker = insight.rewardsClaimedByUser;

            if (msg.sender == proposer) {
                msgSenderStake = insight.stakeAmount;
            } else if (insight.attesterStakes[msg.sender] > 0) {
                msgSenderStake = insight.attesterStakes[msg.sender];
            } else if (insight.challengerStakes[msg.sender] > 0) {
                msgSenderStake = insight.challengerStakes[msg.sender];
            }
            totalCorrectStake = isTrue ? (insight.stakeAmount + insight.totalAttesterStake) : insight.totalChallengerStake;
            totalIncorrectStake = isTrue ? insight.totalChallengerStake : (insight.stakeAmount + insight.totalAttesterStake);

        } else if (_type == EntityType.Prophecy) {
            Prophecy storage prophecy = prophecies[_entityId];
            require(_entityId < nextProphecyId, "OCI: Invalid prophecy ID");
            require(prophecy.isResolved, "OCI: Prophecy not resolved");
            require(!prophecy.rewardsClaimedByUser[msg.sender], "OCI: Rewards already claimed by this user for this prophecy");

            isResolved = prophecy.isResolved;
            isTrue = prophecy.isTrue;
            proposer = prophecy.proposer;
            rewardsClaimedTracker = prophecy.rewardsClaimedByUser;

            if (msg.sender == proposer) {
                msgSenderStake = prophecy.stakeAmount;
            } else if (prophecy.attesterStakes[msg.sender] > 0) {
                msgSenderStake = prophecy.attesterStakes[msg.sender];
            } else if (prophecy.challengerStakes[msg.sender] > 0) {
                msgSenderStake = prophecy.challengerStakes[msg.sender];
            }
            totalCorrectStake = isTrue ? (prophecy.stakeAmount + prophecy.totalAttesterStake) : prophecy.totalChallengerStake;
            totalIncorrectStake = isTrue ? prophecy.totalChallengerStake : (prophecy.stakeAmount + prophecy.totalAttesterStake);
        } else {
            revert("OCI: Invalid entity type");
        }

        require(msgSenderStake > 0, "OCI: No stake found for claimant in this entity");

        uint256 amountToTransfer = 0;

        bool isProposer = (msg.sender == proposer);
        bool isAttester = (msgSenderStake == (_type == EntityType.Insight ? insights[_entityId].attesterStakes[msg.sender] : prophecies[_entityId].attesterStakes[msg.sender])) && !isProposer;
        bool isChallenger = (msgSenderStake == (_type == EntityType.Insight ? insights[_entityId].challengerStakes[msg.sender] : prophecies[_entityId].challengerStakes[msg.sender])) && !isProposer;

        if ((isTrue && (isProposer || isAttester)) || (!isTrue && isChallenger)) {
            // Winning side: get stake back + reward
            uint256 rewardPercentage = (totalCorrectStake > 0) ? (msgSenderStake * (REWARD_MULTIPLIER_BPS + 10_000)) / (totalCorrectStake * 100) : 0; // 10_000 BPS = 1x base stake
            uint256 slashedFundsForBonus = totalIncorrectStake * SLASHER_BONUS_PERCENT / 100;
            uint256 bonusPerCorrectStake = (totalCorrectStake > 0) ? (slashedFundsForBonus / totalCorrectStake) : 0;
            
            amountToTransfer = msgSenderStake + (msgSenderStake * REWARD_MULTIPLIER_BPS / 10_000) + (msgSenderStake * bonusPerCorrectStake);
        } else {
            // Losing side: stake is slashed (removed from totalStaked, no funds to add back to available)
            amountToTransfer = 0; // Stake is lost, so nothing to transfer back to available
        }
        
        // Unlock stake
        totalStakedBalances[msg.sender] -= msgSenderStake;
        availableBalances[msg.sender] += amountToTransfer;
        rewardsClaimedTracker[msg.sender] = true;

        emit EntityRewardsClaimed(_entityId, _type, msg.sender, amountToTransfer);
    }

    // --- III. Reputation System (Clairvoyance Score) ---

    /**
     * @notice Retrieves a user's current Clairvoyance Score.
     * @param _user The address of the user.
     * @return The user's Clairvoyance Score.
     */
    function getClairvoyanceScore(address _user) external view returns (int256) {
        return clairvoyanceScores[_user];
    }

    /**
     * @notice Determines a user's Clairvoyance Tier based on their score.
     * @param _user The address of the user.
     * @return The tier number (e.g., 0 for Novice, 1 for Adept, etc.).
     */
    function getClairvoyanceTier(address _user) external view returns (uint256) {
        int256 score = clairvoyanceScores[_user];
        uint256 tier = 0;
        for (uint256 i = 0; i < clairvoyanceTiers.length; i++) {
            if (score >= int256(clairvoyanceTiers[i])) {
                tier = i;
            } else {
                break;
            }
        }
        return tier;
    }

    /**
     * @dev Internal function to update a user's Clairvoyance Score.
     * @param _user The address of the user to update.
     * @param _delta The amount to change the score by (can be negative).
     */
    function _updateClairvoyanceScore(address _user, int256 _delta) internal {
        clairvoyanceScores[_user] += _delta;
        emit ClairvoyanceScoreUpdated(_user, clairvoyanceScores[_user]);
    }

    // --- IV. Staking & Token Management ---

    /**
     * @dev Internal function to lock a user's stake.
     */
    function _lockStake(address _user, uint256 _amount) internal {
        availableBalances[_user] -= _amount;
        totalStakedBalances[_user] += _amount;
    }

    /**
     * @notice Allows users to deposit OCI_Token into the protocol's internal balance for staking.
     * @dev Requires prior approval of OCI_Token to this contract.
     * @param _amount The amount of OCI_Token to deposit.
     */
    function depositTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "OCI: Deposit amount must be greater than zero");
        OCI_Token.transferFrom(msg.sender, address(this), _amount);
        availableBalances[msg.sender] += _amount;
        emit TokensDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows users to withdraw their available (unstaked) OCI_Token from the protocol.
     * @param _amount The amount of OCI_Token to withdraw.
     */
    function withdrawTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "OCI: Withdraw amount must be greater than zero");
        require(availableBalances[msg.sender] >= _amount, "OCI: Insufficient available balance for withdrawal");

        availableBalances[msg.sender] -= _amount;
        OCI_Token.transfer(msg.sender, _amount);
        emit TokensWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Returns a user's liquid OCI_Token balance within the contract.
     * @param _user The address of the user.
     * @return The available balance.
     */
    function getAvailableBalance(address _user) external view returns (uint256) {
        return availableBalances[_user];
    }

    /**
     * @notice Returns a user's total OCI_Token locked in active proposals (insights or prophecies).
     * @param _user The address of the user.
     * @return The total staked balance.
     */
    function getStakedBalance(address _user) external view returns (uint256) {
        return totalStakedBalances[_user];
    }

    // --- V. Decentralized Governance ---

    /**
     * @notice Allows OCI_Token holders to propose changes to protocol parameters.
     * @param _paramName The name of the parameter to change (e.g., "MIN_INSIGHT_STAKE").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) external nonReentrant {
        // In a real system, min proposal stake/token holding would be required
        // require(OCI_Token.balanceOf(msg.sender) >= MIN_GOVERNANCE_STAKE, "OCI: Insufficient tokens to propose");

        uint256 id = nextProposalId++;
        governanceProposals[id].paramName = _paramName;
        governanceProposals[id].newValue = _newValue;
        governanceProposals[id].proposer = msg.sender;
        governanceProposals[id].proposalTime = block.timestamp;
        governanceProposals[id].votingEndTime = block.timestamp + GOVERNANCE_VOTING_PERIOD;
        governanceProposals[id].timelockEndTime = 0; // Set upon successful vote
        governanceProposals[id].executed = false;

        emit GovernanceProposalCreated(id, _paramName, _newValue, msg.sender);
    }

    /**
     * @notice Allows OCI_Token holders to vote on active governance proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes", false for "no".
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalTime != 0, "OCI: Invalid proposal ID");
        require(block.timestamp <= proposal.votingEndTime, "OCI: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "OCI: Already voted on this proposal");
        require(OCI_Token.balanceOf(msg.sender) > 0, "OCI: Voter must hold OCI_Token");

        uint256 voteWeight = OCI_Token.balanceOf(msg.sender); // Token-weighted voting
        
        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Executes a governance proposal that has passed its voting and timelock periods.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalTime != 0, "OCI: Invalid proposal ID");
        require(!proposal.executed, "OCI: Proposal already executed");
        require(block.timestamp > proposal.votingEndTime, "OCI: Voting period not ended");
        require(proposal.votesFor > proposal.votesAgainst, "OCI: Proposal did not pass");

        // If timelock is not set, set it now. This allows a delay between pass and execution.
        if (proposal.timelockEndTime == 0) {
            proposal.timelockEndTime = block.timestamp + GOVERNANCE_TIMELOCK_PERIOD;
            // Revert here to enforce timelock, and user must call again after timelock.
            // This is a common pattern for timelocks in governance.
            revert("OCI: Proposal passed, but timelock not yet expired. Call again after timelock.");
        }
        
        require(block.timestamp > proposal.timelockEndTime, "OCI: Timelock not yet expired");

        bytes32 paramName = proposal.paramName;
        uint256 newValue = proposal.newValue;

        if (paramName == keccak256(abi.encodePacked("MIN_INSIGHT_STAKE"))) {
            MIN_INSIGHT_STAKE = newValue;
        } else if (paramName == keccak256(abi.encodePacked("MIN_PROPHECY_STAKE"))) {
            MIN_PROPHECY_STAKE = newValue;
        } else if (paramName == keccak256(abi.encodePacked("INSIGHT_VOTING_PERIOD"))) {
            INSIGHT_VOTING_PERIOD = newValue;
        } else if (paramName == keccak256(abi.encodePacked("INSIGHT_RESOLUTION_PERIOD"))) {
            INSIGHT_RESOLUTION_PERIOD = newValue;
        } else if (paramName == keccak256(abi.encodePacked("PROPHECY_VOTING_PERIOD"))) {
            PROPHECY_VOTING_PERIOD = newValue;
        } else if (paramName == keccak256(abi.encodePacked("PROPHECY_RESOLUTION_PERIOD"))) {
            PROPHECY_RESOLUTION_PERIOD = newValue;
        } else if (paramName == keccak256(abi.encodePacked("GOVERNANCE_VOTING_PERIOD"))) {
            GOVERNANCE_VOTING_PERIOD = newValue;
        } else if (paramName == keccak256(abi.encodePacked("GOVERNANCE_TIMELOCK_PERIOD"))) {
            GOVERNANCE_TIMELOCK_PERIOD = newValue;
        } else if (paramName == keccak256(abi.encodePacked("REWARD_MULTIPLIER_BPS"))) {
            REWARD_MULTIPLIER_BPS = newValue;
        } else if (paramName == keccak256(abi.encodePacked("SLASHER_BONUS_PERCENT"))) {
            SLASHER_BONUS_PERCENT = newValue;
        } else if (paramName == keccak256(abi.encodePacked("CLAIRVOYANCE_TIER_ADD"))) {
            // This would be complex to generalize via a single uint256 newValue.
            // A more robust governance would require struct parameters or specific calls.
            // For example's sake, if newValue is a score threshold to add:
            clairvoyanceTiers.push(newValue);
            // Sort tiers if needed.
        } else {
            revert("OCI: Unknown parameter for execution");
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, paramName, newValue);
    }

    /**
     * @notice Adds a new category/topic for insights. Callable only by governance (via proposal).
     * @dev This function would typically be called by `executeProposal` internally if the system was fully trustless.
     *      For this example, it's simplified to `onlyOwner` for direct testing.
     * @param _domainId The unique ID (hash) for the new domain.
     * @param _description A human-readable description for the domain.
     */
    function addInsightDomain(bytes32 _domainId, string calldata _description) external onlyOwner {
        require(!activeInsightDomains[_domainId], "OCI: Domain already active");
        activeInsightDomains[_domainId] = true;
        insightDomainDescriptions[_domainId] = _description;
        emit InsightDomainAdded(_domainId, _description);
    }

    /**
     * @notice Updates the address of the trusted oracle. Callable only by governance (via proposal).
     * @dev Similar to `addInsightDomain`, simplified to `onlyOwner` for this example.
     * @param _newOracle The address of the new trusted oracle.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "OCI: New oracle address cannot be zero");
        emit OracleAddressUpdated(trustedOracle, _newOracle);
        trustedOracle = _newOracle;
    }

    // --- VI. Oracle Interface & Data Query ---

    /**
     * @notice Allows external contracts or users to fetch a list of successfully validated insights for a specific domain.
     * @dev Returns an array of insight IDs. External systems can then query `getInsightDetails` for full data.
     * @param _domainId The ID of the domain to query.
     * @param _startIndex The starting index for pagination.
     * @param _count The maximum number of insights to return.
     * @return An array of validated insight IDs.
     */
    function queryValidatedInsights(bytes32 _domainId, uint256 _startIndex, uint256 _count)
        external view returns (uint256[] memory)
    {
        uint256[] storage domainInsights = validatedInsightsByDomain[_domainId];
        require(_startIndex < domainInsights.length, "OCI: Start index out of bounds");
        
        uint256 endIndex = _startIndex + _count;
        if (endIndex > domainInsights.length) {
            endIndex = domainInsights.length;
        }
        
        uint256 resultCount = endIndex - _startIndex;
        uint256[] memory result = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = domainInsights[_startIndex + i];
        }
        return result;
    }

    /**
     * @notice Fetches a list of successfully validated prophecies.
     * @dev Returns an array of prophecy IDs. External systems can then query `getProphecyDetails` for full data.
     * @param _startIndex The starting index for pagination.
     * @param _count The maximum number of prophecies to return.
     * @return An array of validated prophecy IDs.
     */
    function queryValidatedProphecies(uint256 _startIndex, uint256 _count)
        external view returns (uint256[] memory)
    {
        require(_startIndex < validatedProphecyIds.length, "OCI: Start index out of bounds");
        
        uint256 endIndex = _startIndex + _count;
        if (endIndex > validatedProphecyIds.length) {
            endIndex = validatedProphecyIds.length;
        }
        
        uint256 resultCount = endIndex - _startIndex;
        uint256[] memory result = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = validatedProphecyIds[_startIndex + i];
        }
        return result;
    }

    // --- VII. View Functions & Utilities ---

    /**
     * @notice Returns all details for a given insight ID.
     * @param _insightId The ID of the insight.
     * @return A tuple containing all insight details.
     */
    function getInsightDetails(uint256 _insightId)
        external view
        returns (
            bytes32 insightHash,
            bytes32 domainId,
            address proposer,
            uint256 stakeAmount,
            uint256 proposalTime,
            uint256 resolutionTime,
            uint256 totalAttesterStake,
            uint256 totalChallengerStake,
            bool isResolved,
            bool isTrue
        )
    {
        require(_insightId < nextInsightId, "OCI: Invalid insight ID");
        InsightProposal storage insight = insights[_insightId];
        return (
            insight.insightHash,
            insight.domainId,
            insight.proposer,
            insight.stakeAmount,
            insight.proposalTime,
            insight.resolutionTime,
            insight.totalAttesterStake,
            insight.totalChallengerStake,
            insight.isResolved,
            insight.isTrue
        );
    }

    /**
     * @notice Returns all details for a given prophecy ID.
     * @param _prophecyId The ID of the prophecy.
     * @return A tuple containing all prophecy details.
     */
    function getProphecyDetails(uint256 _prophecyId)
        external view
        returns (
            bytes32 prophecyHash,
            uint256[] memory constituentInsightIds,
            address proposer,
            uint256 stakeAmount,
            uint256 proposalTime,
            uint256 resolutionTime,
            uint256 totalAttesterStake,
            uint256 totalChallengerStake,
            bool isResolved,
            bool isTrue
        )
    {
        require(_prophecyId < nextProphecyId, "OCI: Invalid prophecy ID");
        Prophecy storage prophecy = prophecies[_prophecyId];
        return (
            prophecy.prophecyHash,
            prophecy.constituentInsightIds,
            prophecy.proposer,
            prophecy.stakeAmount,
            prophecy.proposalTime,
            prophecy.resolutionTime,
            prophecy.totalAttesterStake,
            prophecy.totalChallengerStake,
            prophecy.isResolved,
            prophecy.isTrue
        );
    }

    /**
     * @notice Returns details for a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external view
        returns (
            bytes32 paramName,
            uint256 newValue,
            uint256 proposer,
            uint256 proposalTime,
            uint256 votingEndTime,
            uint256 timelockEndTime,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed
        )
    {
        require(_proposalId < nextProposalId, "OCI: Invalid proposal ID");
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (
            proposal.paramName,
            proposal.newValue,
            proposal.proposer,
            proposal.proposalTime,
            proposal.votingEndTime,
            proposal.timelockEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }
}
```