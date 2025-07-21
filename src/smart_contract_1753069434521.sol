Okay, this is an exciting challenge! Creating something truly "non-duplicate of open source" while hitting 20+ advanced functions requires combining several concepts in novel ways.

My proposal is "AetherNexus" – a decentralized, adaptive, and self-regulating network. It incorporates a dynamic reputation system, a gamified "insight" (prediction) module, a dynamic governance system where parameters can adapt based on network performance, and "Dynamic Nexus Badges" (dNFTs) whose perks evolve with user reputation.

---

## AetherNexus Smart Contract Outline & Function Summary

**Core Concept:** AetherNexus is designed as a decentralized autonomous network that learns and adapts its own operational parameters based on collective participant behavior and successful outcomes. It fosters a meritocratic ecosystem driven by a dynamic reputation system and an "insight" mechanism, where participants earn influence and privileges through valuable contributions.

**I. Core Infrastructure:**
    - Handles foundational elements: contract initialization, general parameter management, emergency pausing, and treasury operations.
    - Security features: `Ownable` (for initial setup and emergency, transitioning to governance control), `Pausable`, `ReentrancyGuard`.

**II. Nexus Profile & Reputation System:**
    - **Nexus Profile:** Each participant creates a unique, on-chain profile. This is distinct from a simple address, holding metadata and their reputation score.
    - **Reputation Dynamics:** Reputation is a non-transferable, mutable score. It's the core currency of influence within the network, directly affecting voting power, access to advanced features, and the tier of Dynamic Nexus Badges a user holds. It increases with accurate contributions and decreases with errors or malicious actions.

**III. Insight & Prediction Module:**
    - **Gamified Data Collection:** Participants submit "insights" (hashed predictions) on future events, staking a utility token. This acts as a lightweight, decentralized forecasting mechanism.
    - **Truth Resolution:** After the event, participants reveal their prediction, and a designated entity (initially governance, evolving to community or oracle) proposes the true outcome.
    - **Reward & Punishment:** Accurate predictors are rewarded with utility tokens and boosted reputation. Inaccurate predictions lead to stake forfeiture and reputation loss.
    - **Adaptation Score Contribution:** Successfully resolved insights contribute to the network's overall `adaptationScore`, a key metric for self-optimization.
    - **Challenging:** A mechanism for participants to dispute proposed outcomes, ensuring data integrity.

**IV. Adaptive Governance Module:**
    - **Proposal Lifecycle:** Standard DAO-like proposal creation and voting.
    - **Reputation-Weighted Voting:** Voting power is not just 1 token = 1 vote; it's proportional to a participant's reputation and their Dynamic Nexus Badge perks.
    - **Dynamic Quorum:** The minimum participation required for a proposal to pass adjusts dynamically based on the network's `adaptationScore`. A higher score might imply a more mature and efficient network, allowing for a more agile governance process (e.g., lower quorum percentage).
    - **Advanced Concept: Adaptive Parameter Adjustment (`triggerAdaptiveParameterAdjustment`):** This is the heart of the "self-optimizing" feature. Based on the accumulated `adaptationScore` (derived from successful insights and governance executions), governance (or a sufficiently high-reputation/DAO vote) can trigger an *adaptive adjustment* of a core system parameter (e.g., proposal duration, minimum stake). The magnitude of this adjustment is proportional to the `adaptationScore`, allowing the network to "learn" and move faster towards optimal parameters when its performance is high. This simulates an on-chain automated feedback loop, a form of pseudo-AI.

**V. Dynamic Nexus Badges (dNFT-like):**
    - **Soul-Bound Privileges:** Non-transferable tokens (similar to Soul-Bound Tokens) that represent a user's standing and achievements.
    - **Reputation-Driven Perks:** Unlike static NFTs, the perks (e.g., voting multipliers, fee discounts) associated with a Nexus Badge are **dynamically determined** by the owner's *current* reputation score. As reputation changes, the effective utility of the badge evolves without needing a new NFT to be minted or transferred.
    - **Tiered System:** Badges exist in tiers, and a user's badge can conceptually "upgrade" or "downgrade" its displayed type/perks as their reputation crosses defined thresholds.

**VI. Incentive & Treasury Management:**
    - Manages the distribution of utility tokens as rewards for valuable contributions and provides governance control over the contract's treasury.

**VII. Dispute Resolution & Slashing:**
    - A mechanism to formally resolve challenges, applying reputation adjustments and stake forfeiture/redistribution based on the dispute outcome.

---

### Functions List:

**I. Core Infrastructure:**
1.  `constructor()`: Initializes the contract, deploys NexusToken, sets initial owner and core parameters.
2.  `updateCoreParameter(bytes32 _key, uint256 _newValue)`: Allows governance to update a specific core parameter (e.g., minimum stake, duration).
3.  `pauseContract()`: Emergency function to pause contract operations. Callable by governance.
4.  `unpauseContract()`: Unpauses the contract. Callable by governance.
5.  `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the contract's treasury.

**II. Nexus Profile & Reputation System:**
6.  `createNexusProfile()`: Allows a user to create their unique on-chain Nexus Profile.
7.  `getNexusProfile(address _user)`: Returns a user's Nexus Profile data (profile ID, reputation, metadata URI).
8.  `updateProfileMetadata(string calldata _newURI)`: Allows a profile owner to update their profile's metadata URI.
9.  `getReputationTier(address _user)`: Returns the current reputation tier name of a user based on their score.
10. `getReputationScore(address _user)`: Returns the raw reputation score of a user.

**III. Insight & Prediction Module:**
11. `submitInsight(string calldata _description, bytes32 _predictionHash, uint256 _valueStake, uint256 _revealPeriodEnd)`: Users submit a hashed prediction about a future event, staking NexusTokens.
12. `revealInsight(bytes32 _insightId, string calldata _secretValue)`: Users reveal their prediction after the submission period but before the reveal period ends.
13. `proposeInsightOutcome(bytes32 _insightId, string calldata _trueOutcome)`: Governance or designated oracle proposes the true outcome of an event.
14. `resolveInsight(bytes32 _insightId)`: Finalizes an insight, distributes rewards, adjusts reputation based on accuracy, and contributes to the Adaptation Score.
15. `challengeInsightOutcome(bytes32 _insightId, string calldata _challengerOutcome, uint256 _challengeStake)`: Allows users to challenge a proposed outcome.

**IV. Adaptive Governance Module:**
16. `createGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _callData, uint256 _stakeAmount, uint256 _duration)`: Users create a governance proposal.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Users cast their vote on a proposal, weighted by their reputation and badge perks.
18. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal.
19. `getDynamicQuorum(uint256 _proposalId)`: Calculates the required quorum for a proposal, dynamically adjusted based on the system's Adaptation Score and overall network activity. (View function)
20. `triggerAdaptiveParameterAdjustment(bytes32 _paramKey, uint256 _targetValue)`: **The advanced function.** Based on accumulated Adaptation Score and current system state, this function allows governance to initiate a weighted average adjustment of a system parameter towards a `_targetValue`, contributing to the "self-optimization" of the network.

**V. Dynamic Nexus Badges (dNFT-like):**
21. `mintNexusBadge(address _to, uint256 _badgeType)`: Allows governance or the system to mint a specific type of non-transferable Nexus Badge to a user. (Internal function called upon profile creation/admin action).
22. `upgradeNexusBadge(uint256 _tokenId)`: Allows a user to 'upgrade' their badge if their reputation tier qualifies them for a higher-tier badge. (This updates the badge's internal type reference).
23. `getBadgePerks(uint256 _tokenId)`: Returns the current perks (e.g., voting multiplier, reduced fees) associated with a specific Nexus Badge, dynamically determined by the owner's reputation.
24. `updateBadgeTypes(uint256 _badgeType, uint256 _minReputation, uint256 _votingMultiplier, uint256 _feeDiscount)`: Governance updates the definitions and perks for different badge types.

**VI. Incentive & Treasury Management:**
25. `claimRewards()`: (Placeholder) For a more complex reward accrual system. In this implementation, rewards are distributed directly.
26. `distributeTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to distribute funds from the contract's treasury to a specific recipient.

**VII. Dispute Resolution & Slashing:**
27. `resolveChallenge(bytes32 _challengeId, bool _challengerWins)`: Governance resolves an ongoing challenge, distributing stakes and applying reputation adjustments/slashing.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
Outline & Function Summary:

I. Core Infrastructure:
    - Centralized governance for initial setup and emergency controls, gradually decentralized via the Adaptive Governance Module.
    - Manages contract pausing, treasury withdrawals, and core parameter updates.

II. Nexus Profile & Reputation System:
    - Users create unique on-chain profiles.
    - Reputation is a non-transferable, dynamic score linked to a profile.
    - Reputation directly impacts voting power, access to features, and eligibility for badges.

III. Insight & Prediction Module:
    - Users submit hashed predictions (insights) on future events, staking utility tokens.
    - After an event, users reveal their predictions.
    - Governance (or a designated oracle) proposes the true outcome.
    - The system resolves insights, rewarding accurate predictors and adjusting their reputation.
    - A challenging mechanism allows users to dispute proposed outcomes.

IV. Adaptive Governance Module:
    - Users create and vote on governance proposals.
    - Voting power is weighted by reputation.
    - **Advanced Concept: Adaptive Parameter Adjustment**: Key system parameters (e.g., proposal duration, required stake) can be dynamically adjusted based on a calculated "Adaptation Score" derived from the collective success/accuracy of insights and governance outcomes. This aims to make the system self-optimizing.

V. Dynamic Nexus Badges (dNFT-like):
    - Non-transferable "badges" representing reputation tiers or specific achievements.
    - These badges dynamically update their "perks" (e.g., voting multipliers, fee reductions) based on the linked user's current reputation.
    - Cannot be traded, acting as Soul-Bound Tokens for privileges.

VI. Incentive & Treasury Management:
    - Manages rewards distribution for active and successful participation.
    - Provides governance control over treasury funds.

VII. Dispute Resolution & Slashing:
    - Mechanism to resolve challenges related to insights or other system data.
    - Implements slashing for malicious or inaccurate challenges.

---

Functions List:

I. Core Infrastructure:
1.  `constructor()`: Initializes the contract, deploys NexusToken, sets initial owner and core parameters.
2.  `updateCoreParameter(bytes32 _key, uint256 _newValue)`: Allows governance to update a specific core parameter (e.g., minimum stake, duration).
3.  `pauseContract()`: Emergency function to pause contract operations. Callable by governance.
4.  `unpauseContract()`: Unpauses the contract. Callable by governance.
5.  `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the contract's treasury.

II. Nexus Profile & Reputation System:
6.  `createNexusProfile()`: Allows a user to create their unique on-chain Nexus Profile.
7.  `getNexusProfile(address _user)`: Returns a user's Nexus Profile data (profile ID, reputation, metadata URI).
8.  `updateProfileMetadata(string calldata _newURI)`: Allows a profile owner to update their profile's metadata URI.
9.  `getReputationTier(address _user)`: Returns the current reputation tier of a user based on their score.
10. `getReputationScore(address _user)`: Returns the raw reputation score of a user.

III. Insight & Prediction Module:
11. `submitInsight(string calldata _description, bytes32 _predictionHash, uint256 _valueStake, uint256 _revealPeriodEnd)`: Users submit a hashed prediction about a future event, staking NexusTokens.
12. `revealInsight(bytes32 _insightId, string calldata _secretValue)`: Users reveal their prediction after the submission period but before the reveal period ends.
13. `proposeInsightOutcome(bytes32 _insightId, string calldata _trueOutcome)`: Governance or designated oracle proposes the true outcome of an event.
14. `resolveInsight(bytes32 _insightId)`: Finalizes an insight, distributes rewards, adjusts reputation based on accuracy, and contributes to the Adaptation Score.
15. `challengeInsightOutcome(bytes32 _insightId, string calldata _challengerOutcome, uint256 _challengeStake)`: Allows users to challenge a proposed outcome.

IV. Adaptive Governance Module:
16. `createGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _callData, uint256 _stakeAmount, uint256 _duration)`: Users create a governance proposal.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Users cast their vote on a proposal, weighted by their reputation.
18. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal.
19. `getDynamicQuorum(uint256 _proposalId)`: Calculates the required quorum for a proposal, dynamically adjusted based on the system's Adaptation Score and overall network activity. (View function)
20. `triggerAdaptiveParameterAdjustment(bytes32 _paramKey, uint256 _targetValue)`: **The advanced function.** Based on accumulated Adaptation Score and current system state, this function allows governance to initiate a weighted average adjustment of a system parameter towards a `_targetValue`, contributing to the "self-optimization" of the network.

V. Dynamic Nexus Badges (dNFT-like):
21. `mintNexusBadge(address _to, uint256 _badgeType)`: Allows governance or the system to mint a specific type of non-transferable Nexus Badge to a user.
22. `upgradeNexusBadge(uint256 _tokenId)`: Allows a user to 'upgrade' their badge if their reputation tier qualifies them for a higher-tier badge. (This is a conceptual upgrade, potentially burning old and minting new, or just updating internal state).
23. `getBadgePerks(uint256 _tokenId)`: Returns the current perks (e.g., voting multiplier, reduced fees) associated with a specific Nexus Badge, dynamically determined by the owner's reputation.
24. `updateBadgeTypes(uint256 _badgeType, uint256 _minReputation, uint256 _votingMultiplier, uint256 _feeDiscount)`: Governance updates the definitions and perks for different badge types.

VI. Incentive & Treasury Management:
25. `claimRewards()`: Users claim accumulated NexusToken rewards from successful insights or other contributions.
26. `distributeTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to distribute funds from the contract's treasury to a specific recipient.

VII. Dispute Resolution & Slashing:
27. `resolveChallenge(bytes32 _challengeId, bool _challengerWins)`: Governance resolves an ongoing challenge, distributing stakes and applying reputation adjustments/slashing.

*/

// Simple ERC-20 token for the AetherNexus ecosystem
contract NexusToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Function to allow AetherNexus contract to mint tokens for rewards
    // This allows the main contract to act as a privileged minter for rewards
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract AetherNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Core Configuration & State Variables ---

    // Nexus Token instance
    NexusToken public nexusToken;

    // Stores adjustable system parameters mapped by their keccak256 hash (e.g., keccak256("MIN_PROPOSAL_STAKE"))
    mapping(bytes32 => uint256) public coreParameters;

    // Reputation tiers and their corresponding score thresholds
    struct ReputationTier {
        uint256 minScore;
        string name;
    }
    ReputationTier[] public reputationTiers;

    // Adaptation Score: A metric reflecting the collective success/health of the network.
    // Higher scores allow for more aggressive adaptive parameter adjustments and more agile governance.
    uint256 public adaptationScore; // Accumulates points from successful insights, good governance, etc.

    // --- Nexus Profile & Reputation System ---
    struct NexusProfile {
        uint256 profileId;
        uint256 reputation; // Reputation score
        string metadataURI; // IPFS hash or similar for off-chain profile data
        bool exists; // Flag to check if profile exists
    }
    mapping(address => NexusProfile) public nexusProfiles;
    mapping(uint256 => address) public profileIdToAddress; // Map Profile ID back to address
    uint256 private nextProfileId; // Counter for unique profile IDs

    // --- Insight & Prediction Module ---
    enum InsightState { Submitted, Revealed, OutcomeProposed, Resolved, Challenged }
    struct Insight {
        bytes32 insightId;
        address creator;
        string description;
        bytes32 predictionHash; // keccak256(secretValue) for commitment scheme
        uint256 valueStake;     // NexusTokens staked by the creator
        uint256 submissionTime;
        uint256 revealPeriodEnd; // Unix timestamp by which secretValue must be revealed
        string revealedValue;   // The actual revealed string after the reveal phase
        string proposedOutcome; // The outcome proposed by governance/oracle
        InsightState state;
        bool isAccurate; // Flag set upon resolution to indicate accuracy
    }
    mapping(bytes32 => Insight) public insights;
    bytes32[] public activeInsights; // Array of insight IDs currently active or awaiting resolution

    // --- Adaptive Governance Module ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 proposalId;
        address creator;
        string description;
        address targetContract; // Contract to call if proposal passes
        bytes callData;         // Encoded function call to execute
        uint256 creationTime;
        uint256 duration;       // How long the proposal is active for voting
        uint256 yesVotes;       // Sum of reputation-weighted 'yes' votes
        uint256 noVotes;        // Sum of reputation-weighted 'no' votes
        uint256 requiredStake;  // Stake required from the creator to propose
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private nextProposalId; // Counter for unique proposal IDs

    // --- Dynamic Nexus Badges ---
    // BadgeTypes define the base properties and perks for different badge tiers
    struct BadgeType {
        uint256 minReputation;      // Minimum reputation score required for this badge type
        uint256 votingMultiplier;   // Multiplier for voting power (e.g., 100 = 1x, 150 = 1.5x)
        uint256 feeDiscountBps;     // Basis points discount on fees, e.g., 100 = 1%
        string name;                // Name of the badge type (e.g., "Aether Initiate")
        string metadataURI;         // Base IPFS URI for this badge type's metadata
    }
    mapping(uint256 => BadgeType) public badgeTypes; // Type ID => BadgeType data
    uint256 public nextBadgeTypeId; // Counter for adding new badge types

    // Nexus Badges (conceptual dNFTs - non-transferable and dynamic)
    struct NexusBadge {
        uint256 badgeId;
        address owner;
        uint256 badgeType; // Reference to badgeTypes mapping, defines current tier/perks
        string metadataURI; // Individual badge URI, can change with type upgrades/downgrades
        bool exists;
    }
    mapping(uint256 => NexusBadge) public nexusBadges; // Individual badge ID => Badge data
    mapping(address => uint256[]) public userBadges; // User address => Array of their badge IDs (since one user can have multiple badges)
    uint256 private nextBadgeId; // Counter for unique badge IDs

    // --- Dispute Resolution ---
    enum ChallengeState { Open, Resolved }
    struct Challenge {
        bytes32 challengeId;
        bytes32 insightId; // The insight being challenged
        address challenger;
        string challengerOutcome; // The outcome proposed by the challenger
        uint256 challengeStake;
        uint256 creationTime;
        ChallengeState state;
    }
    mapping(bytes32 => Challenge) public challenges;

    // --- Events ---
    event ParameterUpdated(bytes32 indexed key, uint256 newValue);
    event NexusProfileCreated(address indexed user, uint256 profileId);
    event ProfileMetadataUpdated(address indexed user, string newURI);
    event ReputationAdjusted(address indexed user, int256 adjustment, uint256 newScore);
    event InsightSubmitted(bytes32 indexed insightId, address indexed creator, uint256 valueStake);
    event InsightRevealed(bytes32 indexed insightId, address indexed creator);
    event InsightOutcomeProposed(bytes32 indexed insightId, string trueOutcome);
    event InsightResolved(bytes32 indexed insightId, bool isAccurate, uint256 adaptationScoreImpact);
    event InsightChallenged(bytes32 indexed insightId, address indexed challenger);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed creator, uint256 stakeAmount);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event AdaptiveParameterAdjustmentTriggered(bytes32 indexed paramKey, uint256 targetValue, uint256 adaptationScoreAtAdjustment);
    event NexusBadgeMinted(uint256 indexed badgeId, address indexed to, uint256 badgeType);
    event NexusBadgeUpgraded(uint256 indexed badgeId, uint256 oldType, uint256 newType); // Also used for downgrades
    event BadgeTypeUpdated(uint256 indexed badgeType, uint256 minReputation, uint256 votingMultiplier, uint256 feeDiscountBps);
    event RewardsClaimed(address indexed user, uint256 amount); // For future complex reward system
    event FundsDistributed(address indexed recipient, uint256 amount);
    event ChallengeResolved(bytes32 indexed challengeId, bool challengerWins);

    // --- Modifiers ---
    modifier onlyProfileOwner(address _user) {
        require(msg.sender == _user, "AetherNexus: Not profile owner");
        _;
    }

    // This modifier allows either the contract owner (initial governance) or the system
    // itself (if adaptationScore meets a threshold) to trigger adaptive adjustments.
    modifier onlyGovernanceOrSelfAdapting(bytes32 _paramKey) {
        // Here, we check if the caller is the owner, OR if the adaptationScore is above a certain threshold,
        // which implies the system is "mature" enough for adaptive adjustments potentially initiated by DAO votes.
        // A real DAO would call this via `executeProposal` after a vote.
        require(owner() == msg.sender || adaptationScore >= coreParameters[keccak256("ADAPT_THRESHOLD")], "AetherNexus: Unauthorized parameter adjustment");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        // Deploy NexusToken and transfer initial supply to the deployer
        nexusToken = new NexusToken("Nexus Token", "NXS", 100000000 * 10**18); // 100 Million NXS
        adaptationScore = 0;
        nextProfileId = 1;
        nextProposalId = 1;
        nextBadgeId = 1;
        nextBadgeTypeId = 1;

        // Initialize core system parameters (examples, can be updated via governance)
        coreParameters[keccak256("MIN_REPUTATION_CREATE_PROFILE")] = 0; // No reputation needed to create profile initially
        coreParameters[keccak256("MIN_REPUTATION_SUBMIT_INSIGHT")] = 100; // Reputation needed to submit insights
        coreParameters[keccak256("MIN_INSIGHT_STAKE")] = 1 * 10**18; // 1 NXS minimum stake for insights
        coreParameters[keccak256("INSIGHT_REVEAL_GRACE_PERIOD")] = 1 days; // Time after submission to reveal secret
        coreParameters[keccak256("INSIGHT_CHALLENGE_WINDOW")] = 2 days; // Window after outcome proposed to challenge
        coreParameters[keccak256("INSIGHT_ACCURACY_REPUTATION_GAIN")] = 10; // Reputation gained for accurate insight
        coreParameters[keccak256("INSIGHT_INACCURACY_REPUTATION_LOSS")] = 5; // Reputation lost for inaccurate insight
        coreParameters[keccak256("INSIGHT_REWARD_MULTIPLIER_BPS")] = 12000; // 120% reward of stake (12000 basis points)
        coreParameters[keccak256("MIN_PROPOSAL_STAKE")] = 10 * 10**18; // 10 NXS minimum stake for proposals
        coreParameters[keccak256("DEFAULT_PROPOSAL_DURATION")] = 3 days; // Default voting duration for proposals
        coreParameters[keccak256("REPUTATION_VOTING_MULTIPLIER_BPS")] = 100; // Base: 1 reputation point = 1 vote unit
        coreParameters[keccak256("ADAPTATION_SCORE_SUCCESS_INSIGHT")] = 1; // Points gained for Adaptation Score per accurate insight
        coreParameters[keccak256("ADAPTATION_SCORE_SUCCESS_PROPOSAL")] = 2; // Points gained for Adaptation Score per executed proposal
        coreParameters[keccak256("ADAPT_THRESHOLD")] = 50; // Threshold for Adaptation Score to enable 'self-adaptive' parameter changes

        // Setup initial reputation tiers (can be updated by governance)
        reputationTiers.push(ReputationTier(0, "Initiate"));
        reputationTiers.push(ReputationTier(100, "Apprentice"));
        reputationTiers.push(ReputationTier(500, "Journeyman"));
        reputationTiers.push(ReputationTier(1000, "Master"));
        reputationTiers.push(ReputationTier(5000, "Grandmaster"));

        // Setup initial badge types (can be updated/added by governance)
        // Type 0: Basic, for all users who create a profile (no min reputation requirement)
        badgeTypes[0] = BadgeType(0, 100, 0, "Aether Initiate", "ipfs://Qmaetherinitiate");
        // Type 1: Apprentice, for users with at least 100 reputation
        badgeTypes[1] = BadgeType(100, 110, 500, "Apprentice Nexus", "ipfs://Qmapprenticenexus"); // 10% voting boost, 5% fee discount
        nextBadgeTypeId = 2; // Next available ID for a new badge type
    }

    // --- I. Core Infrastructure ---

    /**
     * @notice Allows governance to update a specific core parameter.
     * @param _key The keccak256 hash of the parameter name (e.g., keccak256("MIN_PROPOSAL_STAKE")).
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(bytes32 _key, uint256 _newValue) external onlyOwner {
        coreParameters[_key] = _newValue;
        emit ParameterUpdated(_key, _newValue);
    }

    /**
     * @notice Emergency function to pause contract operations.
     * Callable only by the contract owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * Callable only by the contract owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows governance to withdraw funds from the contract's treasury.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of NexusToken to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "AetherNexus: Amount must be greater than zero");
        require(nexusToken.balanceOf(address(this)) >= _amount, "AetherNexus: Insufficient treasury balance");
        nexusToken.transfer(_recipient, _amount);
        emit FundsDistributed(_recipient, _amount);
    }

    // --- II. Nexus Profile & Reputation System ---

    /**
     * @notice Allows a user to create their unique on-chain Nexus Profile.
     * Requires minimum reputation if set by core parameters (currently 0).
     */
    function createNexusProfile() external whenNotPaused nonReentrant {
        require(!nexusProfiles[msg.sender].exists, "AetherNexus: Profile already exists");
        require(nexusProfiles[msg.sender].reputation >= coreParameters[keccak256("MIN_REPUTATION_CREATE_PROFILE")], "AetherNexus: Insufficient reputation to create profile");

        nexusProfiles[msg.sender] = NexusProfile({
            profileId: nextProfileId,
            reputation: 0, // New profiles start with 0 reputation
            metadataURI: "",
            exists: true
        });
        profileIdToAddress[nextProfileId] = msg.sender;
        emit NexusProfileCreated(msg.sender, nextProfileId);
        nextProfileId++;

        // Mint a basic badge upon profile creation (type 0)
        _mintNexusBadge(msg.sender, 0);
    }

    /**
     * @notice Returns a user's Nexus Profile data.
     * @param _user The address of the user.
     * @return profileId The unique ID of the profile.
     * @return reputation The current reputation score.
     * @return metadataURI The URI pointing to off-chain profile metadata.
     * @return exists True if the profile exists.
     */
    function getNexusProfile(address _user) external view returns (uint256 profileId, uint256 reputation, string memory metadataURI, bool exists) {
        NexusProfile storage profile = nexusProfiles[_user];
        return (profile.profileId, profile.reputation, profile.metadataURI, profile.exists);
    }

    /**
     * @notice Allows a profile owner to update their profile's metadata URI.
     * @param _newURI The new URI pointing to off-chain metadata.
     */
    function updateProfileMetadata(string calldata _newURI) external whenNotPaused onlyProfileOwner(msg.sender) {
        require(nexusProfiles[msg.sender].exists, "AetherNexus: Profile does not exist");
        nexusProfiles[msg.sender].metadataURI = _newURI;
        emit ProfileMetadataUpdated(msg.sender, _newURI);
    }

    /**
     * @notice Returns the current reputation tier name of a user.
     * @param _user The address of the user.
     * @return The name of the reputation tier.
     */
    function getReputationTier(address _user) public view returns (string memory) {
        require(nexusProfiles[_user].exists, "AetherNexus: Profile does not exist");
        uint256 currentReputation = nexusProfiles[_user].reputation;
        string memory tierName = "Unknown";
        // Iterate from highest tier downwards to find the most appropriate tier
        for (uint256 i = reputationTiers.length; i > 0; i--) {
            if (currentReputation >= reputationTiers[i-1].minScore) {
                tierName = reputationTiers[i-1].name;
                break;
            }
        }
        return tierName;
    }

    /**
     * @notice Returns the raw reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        require(nexusProfiles[_user].exists, "AetherNexus: Profile does not exist");
        return nexusProfiles[_user].reputation;
    }

    /**
     * @notice Internal function to adjust a user's reputation.
     * @param _user The address of the user whose reputation is to be adjusted.
     * @param _amount The amount to adjust reputation by (can be negative).
     * @dev Only callable by the contract itself (e.g., after insight resolution, challenge resolution).
     */
    function _adjustReputation(address _user, int256 _amount) internal {
        require(nexusProfiles[_user].exists, "AetherNexus: Profile does not exist");
        uint256 currentRep = nexusProfiles[_user].reputation;

        if (_amount > 0) {
            nexusProfiles[_user].reputation = currentRep + uint256(_amount);
        } else {
            // Prevent underflow: reputation cannot go below zero
            if (currentRep < uint256(-_amount)) {
                nexusProfiles[_user].reputation = 0;
            } else {
                nexusProfiles[_user].reputation = currentRep - uint256(-_amount);
            }
        }
        emit ReputationAdjusted(_user, _amount, nexusProfiles[_user].reputation);
        // Automatically check and adjust user's badges based on new reputation
        _checkAndAdjustBadges(_user);
    }

    // --- III. Insight & Prediction Module ---

    /**
     * @notice Users submit a hashed prediction about a future event, staking NexusTokens.
     * The `_predictionHash` is `keccak256(secretValue)`. `_secretValue` is revealed later.
     * @param _description A brief description of the event to predict.
     * @param _predictionHash The cryptographic hash of the prediction string.
     * @param _valueStake The amount of NexusTokens to stake as commitment.
     * @param _revealPeriodEnd Unix timestamp when the reveal period for this insight ends.
     */
    function submitInsight(
        string calldata _description,
        bytes32 _predictionHash,
        uint256 _valueStake,
        uint256 _revealPeriodEnd
    ) external whenNotPaused nonReentrant {
        require(nexusProfiles[msg.sender].exists, "AetherNexus: Creator must have a profile");
        require(nexusProfiles[msg.sender].reputation >= coreParameters[keccak256("MIN_REPUTATION_SUBMIT_INSIGHT")], "AetherNexus: Insufficient reputation to submit insight");
        require(_valueStake >= coreParameters[keccak256("MIN_INSIGHT_STAKE")], "AetherNexus: Stake too low");
        require(_revealPeriodEnd > block.timestamp + coreParameters[keccak256("INSIGHT_REVEAL_GRACE_PERIOD")], "AetherNexus: Reveal period must be sufficiently in the future");

        nexusToken.transferFrom(msg.sender, address(this), _valueStake);

        bytes32 insightId = keccak256(abi.encodePacked(msg.sender, _predictionHash, block.timestamp));

        insights[insightId] = Insight({
            insightId: insightId,
            creator: msg.sender,
            description: _description,
            predictionHash: _predictionHash,
            valueStake: _valueStake,
            submissionTime: block.timestamp,
            revealPeriodEnd: _revealPeriodEnd,
            revealedValue: "", // Initialized empty
            proposedOutcome: "", // Initialized empty
            state: InsightState.Submitted,
            isAccurate: false
        });
        activeInsights.push(insightId); // Add to list of insights awaiting resolution
        emit InsightSubmitted(insightId, msg.sender, _valueStake);
    }

    /**
     * @notice Users reveal their original prediction string (`_secretValue`) after submission but before the `_revealPeriodEnd`.
     * This allows the system to compare the revealed value to the initially submitted hash.
     * @param _insightId The ID of the insight to reveal.
     * @param _secretValue The original string that was hashed to create `predictionHash`.
     */
    function revealInsight(bytes32 _insightId, string calldata _secretValue) external whenNotPaused {
        Insight storage insight = insights[_insightId];
        require(insight.state == InsightState.Submitted, "AetherNexus: Insight not in submitted state or already revealed");
        require(insight.creator == msg.sender, "AetherNexus: Only creator can reveal their insight");
        require(keccak256(abi.encodePacked(_secretValue)) == insight.predictionHash, "AetherNexus: Invalid secret value. Hash mismatch.");
        require(block.timestamp <= insight.revealPeriodEnd, "AetherNexus: Reveal period has ended");

        insight.revealedValue = _secretValue;
        insight.state = InsightState.Revealed;
        emit InsightRevealed(_insightId, msg.sender);
    }

    /**
     * @notice Governance or a designated oracle proposes the true outcome of an event.
     * This function should be called after the reveal period has ended.
     * @param _insightId The ID of the insight.
     * @param _trueOutcome The actual, agreed-upon outcome of the event.
     */
    function proposeInsightOutcome(bytes32 _insightId, string calldata _trueOutcome) external onlyOwner whenNotPaused {
        Insight storage insight = insights[_insightId];
        require(insight.state == InsightState.Revealed, "AetherNexus: Insight not in revealed state or already has proposed outcome");
        require(block.timestamp > insight.revealPeriodEnd, "AetherNexus: Reveal period has not ended");

        insight.proposedOutcome = _trueOutcome;
        insight.state = InsightState.OutcomeProposed;
        emit InsightOutcomeProposed(_insightId, _trueOutcome);
    }

    /**
     * @notice Finalizes an insight, distributes rewards, adjusts reputation based on accuracy,
     * and contributes to the Adaptation Score. This can be called by anyone once the challenge window closes.
     * @param _insightId The ID of the insight to resolve.
     */
    function resolveInsight(bytes32 _insightId) external whenNotPaused nonReentrant {
        Insight storage insight = insights[_insightId];
        require(insight.state == InsightState.OutcomeProposed, "AetherNexus: Insight not ready for resolution (must have proposed outcome)");
        // Ensure the challenge window has passed
        require(block.timestamp > insight.revealPeriodEnd + coreParameters[keccak256("INSIGHT_CHALLENGE_WINDOW")], "AetherNexus: Challenge window still open");

        bool accurate = (keccak256(abi.encodePacked(insight.revealedValue)) == keccak256(abi.encodePacked(insight.proposedOutcome)));
        insight.isAccurate = accurate;

        if (accurate) {
            uint256 rewardAmount = (insight.valueStake * coreParameters[keccak256("INSIGHT_REWARD_MULTIPLIER_BPS")]) / 10000;
            nexusToken.transfer(insight.creator, insight.valueStake + rewardAmount); // Return stake + reward
            _adjustReputation(insight.creator, int256(coreParameters[keccak256("INSIGHT_ACCURACY_REPUTATION_GAIN")]));
            adaptationScore += coreParameters[keccak256("ADAPTATION_SCORE_SUCCESS_INSIGHT")]; // Boost Adaptation Score
        } else {
            // If inaccurate, the staked tokens remain in the contract's treasury (they are not returned)
            _adjustReputation(insight.creator, -int256(coreParameters[keccak256("INSIGHT_INACCURACY_REPUTATION_LOSS")]));
            // No adaptationScore increase for inaccurate insights
        }

        insight.state = InsightState.Resolved;
        _removeActiveInsight(_insightId); // Remove from active insights list
        emit InsightResolved(_insightId, accurate, adaptationScore);
    }

    /**
     * @notice Allows users to challenge a proposed outcome for an insight.
     * Requires staking a challenge amount, which is locked until the dispute is resolved by governance.
     * @param _insightId The ID of the insight to challenge.
     * @param _challengerOutcome The outcome the challenger believes is correct.
     * @param _challengeStake The amount of NexusTokens to stake for the challenge.
     */
    function challengeInsightOutcome(
        bytes32 _insightId,
        string calldata _challengerOutcome,
        uint256 _challengeStake
    ) external whenNotPaused nonReentrant {
        Insight storage insight = insights[_insightId];
        require(insight.state == InsightState.OutcomeProposed, "AetherNexus: Insight not in outcome proposed state");
        require(block.timestamp < insight.revealPeriodEnd + coreParameters[keccak256("INSIGHT_CHALLENGE_WINDOW")], "AetherNexus: Challenge window closed");
        require(_challengeStake >= coreParameters[keccak256("MIN_INSIGHT_STAKE")], "AetherNexus: Challenge stake too low"); // Reuse insight stake parameter
        require(nexusProfiles[msg.sender].exists, "AetherNexus: Challenger must have a profile");

        nexusToken.transferFrom(msg.sender, address(this), _challengeStake);

        bytes32 challengeId = keccak256(abi.encodePacked(_insightId, msg.sender, block.timestamp));
        challenges[challengeId] = Challenge({
            challengeId: challengeId,
            insightId: _insightId,
            challenger: msg.sender,
            challengerOutcome: _challengerOutcome,
            challengeStake: _challengeStake,
            creationTime: block.timestamp,
            state: ChallengeState.Open
        });
        insight.state = InsightState.Challenged; // Mark insight as challenged, preventing resolution until dispute is settled
        emit InsightChallenged(_insightId, msg.sender);
    }

    /**
     * @dev Internal helper to remove an insight from the active list.
     * This is called once an insight is fully resolved.
     */
    function _removeActiveInsight(bytes32 _insightId) internal {
        for (uint i = 0; i < activeInsights.length; i++) {
            if (activeInsights[i] == _insightId) {
                activeInsights[i] = activeInsights[activeInsights.length - 1]; // Replace with last element
                activeInsights.pop(); // Remove last element
                break;
            }
        }
    }


    // --- IV. Adaptive Governance Module ---

    /**
     * @notice Users create a governance proposal.
     * Proposing requires staking NexusTokens, returned if proposal passes.
     * @param _description A detailed description of the proposal.
     * @param _targetContract The address of the contract whose function will be called if the proposal passes.
     * @param _callData The ABI-encoded function call (function signature + arguments) to execute.
     * @param _stakeAmount The amount of NexusTokens to stake for the proposal.
     * @param _duration The duration of the voting period in seconds.
     */
    function createGovernanceProposal(
        string calldata _description,
        address _targetContract,
        bytes calldata _callData,
        uint256 _stakeAmount,
        uint256 _duration
    ) external whenNotPaused nonReentrant {
        require(nexusProfiles[msg.sender].exists, "AetherNexus: Creator must have a profile");
        require(_stakeAmount >= coreParameters[keccak256("MIN_PROPOSAL_STAKE")], "AetherNexus: Proposal stake too low");
        require(_duration > 0 && _duration <= 30 days, "AetherNexus: Invalid proposal duration (max 30 days)");

        nexusToken.transferFrom(msg.sender, address(this), _stakeAmount);

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            creator: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            creationTime: block.timestamp,
            duration: _duration,
            yesVotes: 0,
            noVotes: 0,
            requiredStake: _stakeAmount,
            state: ProposalState.Active
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _stakeAmount);
    }

    /**
     * @notice Users cast their vote on a proposal. Voting power is weighted by their reputation
     * and amplified by their Dynamic Nexus Badge perks.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "AetherNexus: Proposal not active");
        require(nexusProfiles[msg.sender].exists, "AetherNexus: Voter must have a profile");
        require(!proposal.hasVoted[msg.sender], "AetherNexus: Already voted on this proposal");
        require(block.timestamp < proposal.creationTime + proposal.duration, "AetherNexus: Voting period has ended");

        uint256 reputationWeight = nexusProfiles[msg.sender].reputation;

        // Apply base reputation multiplier (e.g., if set to scale reputation effect)
        reputationWeight = (reputationWeight * coreParameters[keccak256("REPUTATION_VOTING_MULTIPLIER_BPS")]) / 100;

        // Apply additional badge multipliers for active badges
        for (uint256 i = 0; i < userBadges[msg.sender].length; i++) {
            NexusBadge storage badge = nexusBadges[userBadges[msg.sender][i]];
            BadgeType storage bType = badgeTypes[badge.badgeType];
            // Dynamically apply multiplier based on *current* reputation and badge type definition
            // A badge's perks are only active if the user still meets its minimum reputation requirement
            if (getReputationScore(msg.sender) >= bType.minReputation) {
                 reputationWeight = (reputationWeight * bType.votingMultiplier) / 100;
            }
        }

        if (_support) {
            proposal.yesVotes += reputationWeight;
        } else {
            proposal.noVotes += reputationWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support, reputationWeight);
    }

    /**
     * @notice Executes a successfully voted-on proposal.
     * Any participant can call this function once the voting period has ended and conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "AetherNexus: Proposal not active");
        require(block.timestamp >= proposal.creationTime + proposal.duration, "AetherNexus: Voting period not ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 requiredQuorum = getDynamicQuorum(_proposalId); // Calculate dynamic quorum

        if (totalVotes >= requiredQuorum && proposal.yesVotes > proposal.noVotes) {
            // Proposal Succeeded
            proposal.state = ProposalState.Succeeded;
            // Return creator's stake
            nexusToken.transfer(proposal.creator, proposal.requiredStake);

            // Execute the payload (call to target contract)
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "AetherNexus: Proposal execution failed");
            proposal.state = ProposalState.Executed;
            // Increase Adaptation Score for successful governance
            adaptationScore += coreParameters[keccak256("ADAPTATION_SCORE_SUCCESS_PROPOSAL")];
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal Failed
            proposal.state = ProposalState.Failed;
            // Creator's stake is forfeited and remains in the contract's treasury
        }
    }

    /**
     * @notice Calculates the required quorum (minimum total vote weight) for a proposal
     * to pass. This quorum is dynamically adjusted based on the system's overall
     * `adaptationScore` and a theoretical "total active reputation" in the system.
     * Higher `adaptationScore` indicates a more efficient and mature system, allowing for a lower
     * required quorum percentage to facilitate faster decision-making.
     * @param _proposalId The ID of the proposal.
     * @return The required total vote weight (reputation units) for the proposal to pass.
     */
    function getDynamicQuorum(uint256 _proposalId) public view returns (uint256) {
        // This quorum calculation is a simplified example of an adaptive mechanism.
        // In a live system, `totalReputationInSystem` would need to be a constantly
        // updated aggregate of all active profiles' reputation or a similar metric
        // that reflects overall network engagement. For demonstration, it's a proxy.

        // Proxy for total active reputation in the system.
        // It's assumed to be at least 100,000 reputation points, plus 1000 for every point of adaptation score.
        // This implies the network grows in reputation with its success.
        uint256 totalReputationInSystem = adaptationScore * 1000 + 100000;

        uint256 baseQuorumBps = 3000; // Start with a 30% base quorum (3000 basis points)

        // Adjust quorum percentage based on adaptationScore.
        // Every 10 points of adaptationScore reduces the base quorum percentage by 1% (100 bps).
        uint256 dynamicAdjustmentFactor = adaptationScore / 10;
        uint256 maxAdjustmentBps = 2000; // Cap adjustment to 20% (e.g., 30% - 20% = 10% min quorum)
        if (dynamicAdjustmentFactor * 100 > maxAdjustmentBps) {
            dynamicAdjustmentFactor = maxAdjustmentBps / 100;
        }

        uint256 adjustedQuorumBps = baseQuorumBps - (dynamicAdjustmentFactor * 100);
        if (adjustedQuorumBps < 1000) { // Ensure a minimum quorum of 10% (1000 bps)
            adjustedQuorumBps = 1000;
        }

        return (totalReputationInSystem * adjustedQuorumBps) / 10000;
    }

    /**
     * @notice **Advanced Concept: Adaptive Parameter Adjustment.**
     * This function allows a system parameter to gradually adapt towards a `_targetValue`.
     * The speed of adaptation (the 'step size') is determined by the `adaptationScore`.
     * A higher `adaptationScore` allows for larger adjustment steps, simulating the network
     * "learning" and accelerating its optimization process when performing well.
     * This function would typically be called via a successful governance proposal.
     * @param _paramKey The keccak256 hash of the parameter name to adjust (e.g., keccak256("DEFAULT_PROPOSAL_DURATION")).
     * @param _targetValue The desired value the parameter should move towards.
     * @dev Callable by owner or if `adaptationScore` meets `ADAPT_THRESHOLD`.
     */
    function triggerAdaptiveParameterAdjustment(bytes32 _paramKey, uint256 _targetValue) external onlyGovernanceOrSelfAdapting(_paramKey) {
        uint256 currentValue = coreParameters[_paramKey];
        uint256 adjustmentStep = 0;

        // Define a maximum adaptation factor to normalize the impact of adaptationScore.
        // E.g., if adaptationScore reaches this max, the adjustment will be 100% of the difference.
        uint256 maxAdaptationFactor = 500; // Example: After 500 adaptation points, full step can be taken
        uint256 effectiveAdaptationScore = adaptationScore;
        if (effectiveAdaptationScore > maxAdaptationFactor) {
            effectiveAdaptationScore = maxAdaptationFactor;
        }

        if (_targetValue > currentValue) {
            adjustmentStep = (_targetValue - currentValue) * effectiveAdaptationScore / maxAdaptationFactor;
            // Ensure at least a minimum step if there's a difference and adaptationScore > 0
            if (adjustmentStep == 0 && _targetValue > currentValue && effectiveAdaptationScore > 0) adjustmentStep = 1;
            coreParameters[_paramKey] = currentValue + adjustmentStep;
        } else if (_targetValue < currentValue) {
            adjustmentStep = (currentValue - _targetValue) * effectiveAdaptationScore / maxAdaptationFactor;
            // Ensure at least a minimum step if there's a difference and adaptationScore > 0
            if (adjustmentStep == 0 && _targetValue < currentValue && effectiveAdaptationScore > 0) adjustmentStep = 1;
            // Prevent underflow, ensure parameter doesn't go below target or zero
            if (currentValue < adjustmentStep) coreParameters[_paramKey] = 0;
            else coreParameters[_paramKey] = currentValue - adjustmentStep;
        }
        // If _targetValue == currentValue, no adjustment is made.

        emit AdaptiveParameterAdjustmentTriggered(_paramKey, coreParameters[_paramKey], adaptationScore);
    }


    // --- V. Dynamic Nexus Badges ---

    /**
     * @notice Internal helper to mint a non-transferable Nexus Badge to a user.
     * This is called by `createNexusProfile` and potentially other system functions.
     * @param _to The address to mint the badge to.
     * @param _badgeType The type of badge to mint (references `badgeTypes` mapping).
     */
    function _mintNexusBadge(address _to, uint256 _badgeType) internal {
        // Ensure the badge type exists, or if it's type 0 (basic initiate badge) which has minReputation 0.
        require(_badgeType < nextBadgeTypeId, "AetherNexus: Invalid badge type ID for minting");
        require(badgeTypes[_badgeType].minReputation <= nexusProfiles[_to].reputation || _badgeType == 0, "AetherNexus: User does not meet minimum reputation for this badge type");

        uint256 badgeId = nextBadgeId++;
        nexusBadges[badgeId] = NexusBadge({
            badgeId: badgeId,
            owner: _to,
            badgeType: _badgeType,
            metadataURI: badgeTypes[_badgeType].metadataURI, // Initial metadata from type
            exists: true
        });
        userBadges[_to].push(badgeId);
        emit NexusBadgeMinted(badgeId, _to, _badgeType);
    }

    /**
     * @notice Allows a user to 'upgrade' their badge. This function checks the user's current
     * reputation and updates their existing badge's `badgeType` to the highest eligible tier.
     * This is a "conceptual" upgrade; the same badgeId persists, but its properties change.
     * @param _tokenId The ID of the badge to attempt to upgrade.
     */
    function upgradeNexusBadge(uint256 _tokenId) external whenNotPaused nonReentrant {
        NexusBadge storage badge = nexusBadges[_tokenId];
        require(badge.exists, "AetherNexus: Badge does not exist");
        require(badge.owner == msg.sender, "AetherNexus: Not badge owner");

        uint256 currentReputation = nexusProfiles[msg.sender].reputation;
        uint256 currentBadgeType = badge.badgeType;
        uint256 potentialNewBadgeType = currentBadgeType;

        // Iterate through all defined badge types to find the highest eligible one for the current reputation
        for (uint256 i = 0; i < nextBadgeTypeId; i++) {
            BadgeType storage bType = badgeTypes[i];
            if (currentReputation >= bType.minReputation) {
                // If this badge type is higher than the current potential and eligible
                if (i > potentialNewBadgeType) {
                    potentialNewBadgeType = i;
                }
            }
        }

        if (potentialNewBadgeType != currentBadgeType) {
            badge.badgeType = potentialNewBadgeType;
            badge.metadataURI = badgeTypes[potentialNewBadgeType].metadataURI; // Update metadata URI to reflect new type
            emit NexusBadgeUpgraded(_tokenId, currentBadgeType, potentialNewBadgeType);
        } else {
            revert("AetherNexus: No eligible badge upgrade available or already at highest eligible tier.");
        }
    }

    /**
     * @notice Internal helper to check and adjust a user's badges based on their current reputation.
     * This function is crucial for the "dynamic" aspect, ensuring badges reflect current reputation.
     * It will "downgrade" a badge's effective type if reputation drops, or upgrade if it rises.
     * @param _user The user's address.
     */
    function _checkAndAdjustBadges(address _user) internal {
        uint256 currentReputation = nexusProfiles[_user].reputation;
        uint256[] storage badges = userBadges[_user];

        for (uint256 i = 0; i < badges.length; i++) {
            NexusBadge storage badge = nexusBadges[badges[i]];
            uint256 currentBadgeType = badge.badgeType;
            uint256 highestEligibleTypeForCurrentRep = 0; // Default to the base type (Type 0)

            // Find the highest badge type the user is currently eligible for
            for (uint256 j = 0; j < nextBadgeTypeId; j++) {
                BadgeType storage bType = badgeTypes[j];
                if (currentReputation >= bType.minReputation) {
                    if (j > highestEligibleTypeForCurrentRep) {
                        highestEligibleTypeForCurrentRep = j;
                    }
                }
            }
            
            // If the current badge type is different from the highest eligible type, adjust it
            if (currentBadgeType != highestEligibleTypeForCurrentRep) {
                badge.badgeType = highestEligibleTypeForCurrentRep;
                badge.metadataURI = badgeTypes[highestEligibleTypeForCurrentRep].metadataURI;
                emit NexusBadgeUpgraded(badges[i], currentBadgeType, highestEligibleTypeForCurrentRep); // Re-use event for any type change (up/down)
            }
        }
    }

    /**
     * @notice Returns the current perks (e.g., voting multiplier, fee discount) associated with a specific Nexus Badge.
     * These perks are dynamically determined by the owner's current reputation relative to the badge type.
     * @param _tokenId The ID of the badge.
     * @return votingMultiplier The multiplier for voting power (e.g., 100 for 1x, 150 for 1.5x).
     * @return feeDiscountBps The discount in basis points (e.g., 100 for 1%).
     * @return name The name of the badge's current tier.
     */
    function getBadgePerks(uint256 _tokenId) public view returns (uint256 votingMultiplier, uint256 feeDiscountBps, string memory name) {
        NexusBadge storage badge = nexusBadges[_tokenId];
        require(badge.exists, "AetherNexus: Badge does not exist");
        require(nexusProfiles[badge.owner].exists, "AetherNexus: Badge owner profile does not exist");

        // The perks are directly tied to the badge's current `badgeType`
        BadgeType storage bType = badgeTypes[badge.badgeType];
        return (bType.votingMultiplier, bType.feeDiscountBps, bType.name);
    }

    /**
     * @notice Governance updates the definitions and perks for different badge types.
     * Can add new types or modify existing ones.
     * @param _badgeType The ID of the badge type to update/add. Use `nextBadgeTypeId` for a brand new type.
     * @param _minReputation The minimum reputation score required for this badge type.
     * @param _votingMultiplier The multiplier for voting power (e.g., 100 = 1x).
     * @param _feeDiscountBps The discount in basis points on fees (e.g., 100 = 1%).
     * @param _name The human-readable name of the badge type.
     * @param _metadataURI The base URI for this badge type's metadata (e.g., IPFS hash).
     */
    function updateBadgeTypes(
        uint256 _badgeType,
        uint256 _minReputation,
        uint256 _votingMultiplier,
        uint256 _feeDiscountBps,
        string calldata _name,
        string calldata _metadataURI
    ) external onlyOwner {
        require(_badgeType <= nextBadgeTypeId, "AetherNexus: Invalid badge type ID (can't skip IDs)");
        if (_badgeType == nextBadgeTypeId) {
            nextBadgeTypeId++; // Increment if a new badge type is being created
        }
        badgeTypes[_badgeType] = BadgeType({
            minReputation: _minReputation,
            votingMultiplier: _votingMultiplier,
            feeDiscountBps: _feeDiscountBps,
            name: _name,
            metadataURI: _metadataURI
        });
        emit BadgeTypeUpdated(_badgeType, _minReputation, _votingMultiplier, _feeDiscountBps);
    }


    // --- VI. Incentive & Treasury Management ---

    /**
     * @notice Allows users to claim accumulated NexusToken rewards from successful insights or other contributions.
     * This is a placeholder function. In this specific contract, rewards from insights are
     * distributed immediately upon resolution. For more complex reward systems (e.g.,
     * staking rewards, retrospective grants), this function would manage pending balances.
     */
    function claimRewards() external pure {
        // In this implementation, rewards are distributed directly in `resolveInsight`.
        // This function would be implemented if there were a `mapping(address => uint256) public pendingRewards;`
        // and users had to explicitly claim them.
        revert("AetherNexus: Rewards are distributed directly upon insight resolution or system event.");
    }

    /**
     * @notice Allows governance to distribute funds from the contract's treasury to a specific recipient.
     * This is intended for general treasury management, operational expenses, or grants voted on by the DAO.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of NexusToken to distribute.
     */
    function distributeTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "AetherNexus: Amount must be greater than zero");
        require(nexusToken.balanceOf(address(this)) >= _amount, "AetherNexus: Insufficient treasury balance");
        nexusToken.transfer(_recipient, _amount);
        emit FundsDistributed(_recipient, _amount);
    }


    // --- VII. Dispute Resolution & Slashing ---

    /**
     * @notice Governance resolves an ongoing challenge related to an insight, distributing stakes
     * and applying reputation adjustments (slashing or rewards) based on the resolution outcome.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger's proposed outcome is deemed correct.
     */
    function resolveChallenge(bytes32 _challengeId, bool _challengerWins) external onlyOwner nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.state == ChallengeState.Open, "AetherNexus: Challenge not open or already resolved");
        Insight storage insight = insights[challenge.insightId];
        require(insight.state == InsightState.Challenged, "AetherNexus: Insight not in challenged state");

        // The challenge stake is now released.
        // It's either returned to challenger or forfeited.
        if (_challengerWins) {
            // Challenger wins: Their proposed outcome was correct.
            // Return challenger's stake.
            nexusToken.transfer(challenge.challenger, challenge.challengeStake);
            
            // Reward challenger (e.g., a portion of original insight stake, or a fixed amount from treasury)
            // For simplicity, take a portion of the original insight's creator stake as challenger reward.
            uint256 challengerReward = insight.valueStake / 2;
            nexusToken.transfer(challenge.challenger, challengerReward);
            
            _adjustReputation(challenge.challenger, int256(coreParameters[keccak256("INSIGHT_ACCURACY_REPUTATION_GAIN")])); // Reward challenger's reputation
            _adjustReputation(insight.creator, -int256(coreParameters[keccak256("INSIGHT_INACCURACY_REPUTATION_LOSS")] * 2)); // Penalize original insight creator more severely

            // The original insight creator's prediction was essentially wrong, and their proposed outcome was also wrong (or successfully challenged).
            // Their staked `insight.valueStake` is forfeited to the treasury (or used for challenger reward).
            insight.isAccurate = false; // Mark insight as inaccurate
            insight.state = InsightState.Resolved; // Insight is now resolved via challenge outcome
        } else {
            // Challenger loses: Their challenge was unsuccessful.
            // Challenger's stake is forfeited and remains in the contract's treasury.
            _adjustReputation(challenge.challenger, -int256(coreParameters[keccak256("INSIGHT_INACCURACY_REPUTATION_LOSS")] * 2)); // Penalize challenger more severely

            // The original insight creator's outcome stands (implicitly correct, as challenge failed).
            // Re-process the original insight as if it was correct (or was not successfully challenged).
            // This requires re-evaluating if `insight.revealedValue` matches `insight.proposedOutcome` and then returning stake/reward.
            bool originalInsightAccurate = (keccak256(abi.encodePacked(insight.revealedValue)) == keccak256(abi.encodePacked(insight.proposedOutcome)));
            if (originalInsightAccurate) {
                 uint256 rewardAmount = (insight.valueStake * coreParameters[keccak256("INSIGHT_REWARD_MULTIPLIER_BPS")]) / 10000;
                 nexusToken.transfer(insight.creator, insight.valueStake + rewardAmount);
                 _adjustReputation(insight.creator, int256(coreParameters[keccak256("INSIGHT_ACCURACY_REPUTATION_GAIN")]));
                 adaptationScore += coreParameters[keccak256("ADAPTATION_SCORE_SUCCESS_INSIGHT")];
                 insight.isAccurate = true;
            } else {
                // If original insight was inaccurate AND challenge failed, original creator still loses.
                _adjustReputation(insight.creator, -int256(coreParameters[keccak256("INSIGHT_INACCURACY_REPUTATION_LOSS")]));
                insight.isAccurate = false;
            }
            insight.state = InsightState.Resolved; // Insight is now resolved
        }

        challenge.state = ChallengeState.Resolved;
        _removeActiveInsight(insight.insightId); // Ensure insight is removed from active list
        emit ChallengeResolved(_challengeId, _challengerWins);
    }
}
```