```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For managing sets of addresses

// --- Contract: EvolverProtocol ---
//
// Description:
// The Evolver Protocol is an advanced, adaptive, and self-governing decentralized
// ecosystem designed to dynamically incentivize desired on-chain behaviors, manage
// resource allocation, and foster a reputation-based social credit system.
//
// It introduces an evolving tokenomics model where parameters like staking yields
// and supply adjustments are not fixed, but rather adapt based on real-time
// protocol health metrics and community governance. Participants earn "Influence Points"
// through positive contributions, which grant them tiered access, enhanced voting power,
// and greater benefits within the ecosystem. The protocol's core rules and incentivized
// behaviors are themselves subject to decentralized governance, allowing the system
// to "evolve" based on the collective intelligence and needs of its community.
//
// Core Concepts:
// 1.  Adaptive Tokenomics: Staking APY and token supply adjust based on protocol metrics.
// 2.  On-Chain Reputation (Influence Points): Earned via positive behavior, decays over time, offers tiered access.
// 3.  Dynamic Behavioral Incentivization: DAO defines specific on-chain actions to reward/penalize, making the incentive structure evolve.
// 4.  Meta-Governance: The DAO governs not just funds, but the protocol's core rules and incentive mechanisms.
// 5.  Permissioned Action Recording: Certain behaviors can only be recorded by designated roles (e.g., Oracles/Keepers).
// 6.  Ecosystem Health Metrics: On-chain metrics that inform adaptive mechanisms, allowing data-driven adjustments.
//
// Outline:
// I. Core Token (EVL) & Staking:
//    - ERC-20 token with voting capabilities for governance and burnable functionality.
//    - Adaptive staking pool where yield (APY) dynamically adjusts based on protocol health and rules.
// II. Influence & Reputation System:
//    - "Influence Points" (IPs) for participants, awarded/penalized for behaviors and decaying over time.
//    - IP tiers determine access levels and proportional benefits.
// III. Adaptive Rules Engine & Behaviors:
//    - Protocol parameters (rules) are dynamic and modifiable only through DAO governance.
//    - Mechanism for defining and activating new incentivized or penalized on-chain behaviors.
//    - System to record and process behavior completions, triggering IP and token effects.
// IV. DAO Governance (OpenZeppelin Governor & Timelock):
//    - Standardized, secure decentralized decision-making process.
//    - Supports proposals for all major protocol changes, including rule adjustments, behavior definitions, and fund allocation.
// V. Protocol Metrics & Dynamic Economics:
//    - On-chain tracking of key ecosystem health metrics (e.g., active users, total staked).
//    - Automated or DAO-triggered functions to adjust token supply (mint/burn) based on these metrics.
// VI. System Control & Utility:
//    - Pausable functionality for emergency situations.
//    - Role-Based Access Control (RBAC) for managing permissions, designed to be progressively decentralized.

// Function Summary:
// I. Core Token (EVL) & Staking
//    1.  constructor(address initialOwner): Initializes ERC20 token, access control roles, and sets up governance components (Governor, Timelock).
//    2.  mint(address recipient, uint256 amount): Allows MINTER_ROLE to create new tokens, primarily for initial distribution or supply adjustments.
//    3.  burn(uint256 amount): Allows any token holder to burn their own tokens, potentially for deflationary purposes or specific benefits.
//    4.  stake(uint256 amount): Deposits sender's tokens into the staking pool, enabling participation in yield generation.
//    5.  unstake(uint256 amount): Withdraws tokens from the staking pool.
//    6.  claimStakingRewards(): Allows stakers to claim their accumulated adaptive staking rewards.
//    7.  getAdaptiveStakingAPY(): Calculates and returns the current Annual Percentage Yield (APY) for staking, dynamically adjusted by protocol metrics.
//    8.  getParticipantStakingInfo(address participant): Provides comprehensive staking details for a given participant, including pending rewards.
// II. Influence & Reputation System
//    9.  registerParticipant(): Allows an address to opt-in to the Influence Points system, initializing their reputation profile.
//    10. awardInfluence(address participant, uint256 amount, bytes32 source): Awards influence points to a participant. Restricted to INFLUENCE_MANAGER_ROLE.
//    11. penalizeInfluence(address participant, uint256 amount, bytes32 source): Reduces influence points from a participant. Restricted to INFLUENCE_MANAGER_ROLE.
//    12. getInfluenceScore(address participant): Returns the current, decay-adjusted influence score of a participant.
//    13. getInfluenceTier(address participant): Determines and returns the influence tier (e.g., "Tier 1") of a participant based on their score.
//    14. triggerInfluenceDecay(): Callable by anyone to trigger the global decay of influence points for registered participants.
// III. Adaptive Rules Engine & Behaviors
//    15. proposeRuleChange(bytes32 ruleKey, uint256 newValue, string description): Creates a governance proposal to modify a core protocol rule.
//    16. setRule(bytes32 ruleKey, uint256 newValue): Internal function called by the Governor to enact a rule change after a successful vote.
//    17. defineBehavior(bytes32 behaviorId, BehaviorConfig memory config): Creates a governance proposal to define a new incentivized or penalized on-chain behavior.
//    18. _defineBehavior(bytes32 behaviorId, BehaviorConfig memory config): Internal function called by the Governor to enact a new behavior definition.
//    19. recordBehaviorCompletion(bytes32 behaviorId, address participant, bytes memory proof): Records completion of a defined behavior, triggering influence and token effects. Restricted to BEHAVIOR_RECORDER_ROLE (e.g., an oracle).
//    20. getRule(bytes32 ruleKey): Returns the current value of a specified protocol rule.
//    21. getBehaviorDetails(bytes32 behaviorId): Returns the configuration details of a specified defined behavior.
// IV. DAO Governance (inherited from Governor and TimelockController)
//    22. propose(address[] targets, uint256[] values, bytes[] calldatas, string description): Standard OpenZeppelin function to create a general governance proposal.
//    23. vote(uint256 proposalId, uint8 support): Casts a vote on an active proposal.
//    24. queue(uint256 proposalId): Queues a successfully voted proposal for execution in the Timelock.
//    25. execute(uint256 proposalId): Executes a queued proposal after its timelock delay has passed.
//    26. cancel(uint256 proposalId): Allows a proposal to be cancelled under specific conditions (e.g., by proposer if conditions change).
// V. Protocol Metrics & Dynamic Economics
//    27. updateMetric(bytes32 metricKey, uint256 value): Allows METRIC_UPDATER_ROLE to update protocol health metrics.
//    28. getMetricValue(bytes32 metricKey): Returns the current value of a specified protocol metric.
//    29. triggerDynamicSupplyAdjustment(): Initiates a token supply adjustment (mint/burn) based on predefined rules and current protocol metrics. Restricted to AUTOMATION_ROLE.
// VI. System Control & Utility
//    30. togglePause(): Pauses or unpauses the contract in case of an emergency or maintenance. Restricted to PAUSER_ROLE.
//    31. grantRole(bytes32 role, address account): Grants a specified role to an account. Restricted to DEFAULT_ADMIN_ROLE.
//    32. revokeRole(bytes32 role, address account): Revokes a specified role from an account. Restricted to DEFAULT_ADMIN_ROLE.

contract EvolverProtocol is ERC20, ERC20Burnable, ERC20Votes, AccessControl, Pausable, Governor {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant INFLUENCE_MANAGER_ROLE = keccak256("INFLUENCE_MANAGER_ROLE");
    bytes32 public constant BEHAVIOR_RECORDER_ROLE = keccak256("BEHAVIOR_RECORDER_ROLE");
    bytes32 public constant METRIC_UPDATER_ROLE = keccak256("METRIC_UPDATER_ROLE");
    bytes32 public constant AUTOMATION_ROLE = keccak256("AUTOMATION_ROLE"); // For automated tasks like supply adjustment

    // --- State Variables ---

    // I. Core Token (EVL) & Staking
    struct StakingInfo {
        uint256 amount;
        uint256 lastRewardClaimTime;
        uint256 rewardDebt; // Tracks rewards accumulated but not yet minted/transferred
        uint256 initialStakeTime; // For potential time-based staking bonuses or analytics
    }
    mapping(address => StakingInfo) public stakers;
    EnumerableSet.AddressSet private _activeStakers; // Tracks addresses that have staked, for iteration
    uint256 public totalStakedSupply;

    // II. Influence & Reputation System
    struct ParticipantInfluence {
        uint256 score;
        uint256 lastUpdateTimestamp;
        bool registered; // True if the participant has opted into the influence system
    }
    mapping(address => ParticipantInfluence) public influenceScores;

    // III. Adaptive Rules Engine & Behaviors
    // Dynamic protocol parameters that can be changed via governance
    mapping(bytes32 => uint256) public protocolRules;

    // Configuration for a specific incentivized/penalized behavior
    struct BehaviorConfig {
        bytes32 behaviorType;    // e.g., keccak256("COMMUNITY_PROPOSAL"), keccak256("BUG_REPORT")
        uint256 influenceEffect; // Amount of influence points to add/remove
        uint256 tokenReward;     // Amount of EVL tokens to reward (can be 0)
        uint256 cooldown;        // Cooldown period in seconds for repeating this behavior (0 for no cooldown)
        bool    active;          // Is this behavior currently active and recognized?
        bool    penalizing;      // True if this behavior penalizes, false if it rewards
        string  description;
    }
    mapping(bytes32 => BehaviorConfig) public behaviors; // behaviorId => BehaviorConfig
    mapping(address => mapping(bytes32 => uint256)) public lastBehaviorCompletionTime; // participant => behaviorId => timestamp

    // IV. DAO Governance
    TimelockController public timelock;
    uint255 public constant MIN_QUORUM_NUMERATOR = 4; // 4% quorum of total voting power
    uint255 public constant VOTING_DELAY = 1;         // 1 block voting delay before a proposal can be voted on
    uint255 public constant VOTING_PERIOD = 50400;    // ~1 week (assuming 12s block time) for voting duration

    // V. Protocol Metrics & Dynamic Economics
    mapping(bytes32 => uint256) public protocolMetrics; // e.g., keccak256("activeUsers"), keccak256("totalTransactions"), keccak256("treasuryBalance")

    // --- Events ---
    event TokensStaked(address indexed participant, uint256 amount);
    event TokensUnstaked(address indexed participant, uint256 amount);
    event StakingRewardsClaimed(address indexed participant, uint256 amount);
    event InfluenceAwarded(address indexed participant, uint256 amount, bytes32 source);
    event InfluencePenalized(address indexed participant, uint256 amount, bytes32 source);
    event InfluenceDecayed(address indexed participant, uint256 oldScore, uint256 newScore);
    event RuleChanged(bytes32 indexed ruleKey, uint256 oldValue, uint256 newValue);
    event BehaviorDefined(bytes32 indexed behaviorId, BehaviorConfig config);
    event BehaviorCompleted(address indexed participant, bytes32 indexed behaviorId, uint256 influenceEffect, uint256 tokenReward);
    event MetricUpdated(bytes32 indexed metricKey, uint256 oldValue, uint256 newValue);
    event SupplyAdjusted(uint256 oldSupply, uint256 newSupply, bool minted);

    // --- Constructor ---
    /// @param initialOwner The address that will initially hold the DEFAULT_ADMIN_ROLE and control setup.
    constructor(address initialOwner)
        ERC20("Evolver Protocol Token", "EVL")
        ERC20Votes(
            "Evolver Protocol Token", // ERC712 name for voting signature
            "EVL"                     // ERC712 version for voting signature
        )
        Pausable()
    {
        // Grant initial roles to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(PAUSER_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner); // Allow initial minting by owner

        // Deploy TimelockController
        // minDelay: 0 initially for testing, should be a significant value (e.g., 2 days for mainnet)
        // proposers/executors: Initially empty, Governor contract will be granted these roles externally.
        // admin: InitialOwner manages Timelock permissions (can be renounced to DAO later).
        timelock = new TimelockController(
            0,            // minDelay (0 for instant execution in dev; set to e.g., 2 days in production)
            new address[](0), // proposers (will be Governor contract)
            new address[](0), // executors (can be 0x0 for anyone, or a specific set, or Governor)
            initialOwner  // admin (can renounce to 0x0 or DAO for full decentralization)
        );

        // Initialize Governor
        // The timelock address is set as the executor of proposals.
        // This contract (EvolverProtocol, which is ERC20Votes) serves as the voting token.
        __Governor_init("Evolver Governor", VOTING_DELAY, VOTING_PERIOD, MIN_QUORUM_NUMERATOR);

        // Initial EVL supply for treasury or initial distribution (e.g., to initialOwner)
        _mint(initialOwner, 100_000_000 * (10 ** decimals())); // 100 Million EVL

        // Set initial protocol rules (example values). These are DAO-governed.
        protocolRules[keccak256("INFLUENCE_DECAY_RATE_PER_DAY")] = 10; // 10 basis points (0.1%) decay per day
        protocolRules[keccak256("MIN_INFLUENCE_TIER1")] = 1000;      // Influence needed for Tier 1
        protocolRules[keccak256("MIN_INFLUENCE_TIER2")] = 5000;      // Influence needed for Tier 2
        protocolRules[keccak256("MIN_INFLUENCE_TIER3")] = 10000;     // Influence needed for Tier 3
        protocolRules[keccak256("BASE_STAKING_APY_BPS")] = 500;      // 5% base APY in Basis Points
        protocolRules[keccak256("MAX_STAKING_APY_BPS")] = 2000;      // 20% max APY
        protocolRules[keccak256("MIN_SUPPLY_TARGET_RATIO_BPS")] = 9500; // Min supply target: 95% of initial supply
        protocolRules[keccak256("MAX_SUPPLY_TARGET_RATIO_BPS")] = 10500; // Max supply target: 105% of initial supply
        protocolRules[keccak256("SUPPLY_ADJUSTMENT_PERCENT_BPS")] = 100; // 1% adjustment per trigger

        // Grant initial operational roles to initialOwner. These roles enable core protocol functions
        // and can later be granted to other addresses or even renounced to the DAO itself for full decentralization.
        _grantRole(INFLUENCE_MANAGER_ROLE, initialOwner);
        _grantRole(BEHAVIOR_RECORDER_ROLE, initialOwner);
        _grantRole(METRIC_UPDATER_ROLE, initialOwner);
        _grantRole(AUTOMATION_ROLE, initialOwner);
    }

    // --- Override for Governor compatibility ---
    /// @dev Returns the voting token used by this Governor.
    function votingToken() public view override returns (ERC20Votes) {
        return this;
    }

    /// @dev Returns the TimelockController used by this Governor.
    function __timelock() internal view override returns (ITimelockController) {
        return timelock;
    }

    // --- I. Core Token (EVL) & Staking ---

    /// @notice Allows the MINTER_ROLE to mint new tokens.
    /// @param recipient The address to receive the new tokens.
    /// @param amount The amount of tokens to mint (in smallest unit, e.g., wei).
    function mint(address recipient, uint256 amount) public virtual onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(recipient, amount);
    }

    /// @notice Allows any token holder to burn their own tokens.
    /// @param amount The amount of tokens to burn (in smallest unit, e.g., wei).
    function burn(uint256 amount) public virtual override whenNotPaused {
        _burn(msg.sender, amount);
    }

    /// @notice Deposits tokens from the sender into the staking pool.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Evolver: Must stake non-zero amount");
        require(balanceOf(msg.sender) >= amount, "Evolver: Insufficient balance");

        _updateStakingRewards(msg.sender); // Settle pending rewards before new stake to prevent manipulation

        _transfer(msg.sender, address(this), amount); // Transfer tokens to contract's balance
        stakers[msg.sender].amount = stakers[msg.sender].amount.add(amount);
        totalStakedSupply = totalStakedSupply.add(amount);

        // If staking for the first time or re-staking after full unstake
        if (stakers[msg.sender].initialStakeTime == 0) {
            stakers[msg.sender].initialStakeTime = block.timestamp;
            _activeStakers.add(msg.sender); // Add to active stakers set
        }
        stakers[msg.sender].lastRewardClaimTime = block.timestamp; // Reset claim time to now

        emit TokensStaked(msg.sender, amount);
    }

    /// @notice Withdraws tokens from the staking pool.
    /// @param amount The amount of tokens to unstake.
    function unstake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Evolver: Must unstake non-zero amount");
        require(stakers[msg.sender].amount >= amount, "Evolver: Not enough staked");

        _updateStakingRewards(msg.sender); // Settle pending rewards before unstake

        stakers[msg.sender].amount = stakers[msg.sender].amount.sub(amount);
        totalStakedSupply = totalStakedSupply.sub(amount);
        _transfer(address(this), msg.sender, amount); // Transfer tokens back to staker

        if (stakers[msg.sender].amount == 0) { // If all tokens unstaked
            stakers[msg.sender].initialStakeTime = 0; // Reset initial stake time
            _activeStakers.remove(msg.sender); // Remove from active stakers set
        }
        stakers[msg.sender].lastRewardClaimTime = block.timestamp; // Reset claim time to now

        emit TokensUnstaked(msg.sender, amount);
    }

    /// @notice Allows stakers to claim their accumulated rewards. Rewards are minted to the staker.
    function claimStakingRewards() public whenNotPaused {
        _updateStakingRewards(msg.sender); // Calculate and distribute rewards
        uint256 rewardsToClaim = stakers[msg.sender].rewardDebt;
        stakers[msg.sender].rewardDebt = 0; // Reset debt after claiming

        if (rewardsToClaim > 0) {
            _mint(msg.sender, rewardsToClaim); // Mint rewards to the staker
            emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
        }
    }

    /// @notice Internal function to calculate and update a participant's staking rewards.
    /// @param participant The address of the participant whose rewards are to be updated.
    function _updateStakingRewards(address participant) internal {
        uint256 stakedAmount = stakers[participant].amount;
        if (stakedAmount == 0) return; // No tokens staked, no rewards

        uint256 timeElapsed = block.timestamp.sub(stakers[participant].lastRewardClaimTime);
        if (timeElapsed == 0) return; // No time has passed since last update

        uint256 currentAPY_BPS = getAdaptiveStakingAPY();
        // Reward formula: stakedAmount * APY_BPS / 10000 * (timeElapsed / 365 days in seconds)
        // 31,536,000 seconds in a non-leap year (365 days * 24 hours * 60 minutes * 60 seconds)
        uint256 rewards = (stakedAmount.mul(currentAPY_BPS).mul(timeElapsed)) / (10_000 * 31_536_000);

        stakers[participant].rewardDebt = stakers[participant].rewardDebt.add(rewards);
        stakers[participant].lastRewardClaimTime = block.timestamp;
    }

    /// @notice Calculates the current adaptive Annual Percentage Yield (APY) for staking.
    /// @dev APY adapts based on protocol health metrics like active users, total staked supply, and treasury balance.
    /// @return The calculated APY in basis points (e.g., 500 for 5%).
    function getAdaptiveStakingAPY() public view returns (uint256) {
        uint256 baseAPY = protocolRules[keccak256("BASE_STAKING_APY_BPS")];
        uint256 maxAPY = protocolRules[keccak256("MAX_STAKING_APY_BPS")];

        uint256 activeUsers = protocolMetrics[keccak256("activeUsers")];
        uint256 currentTotalSupply = totalSupply();
        uint256 totalEVLStaked = totalStakedSupply;
        // Remaining EVL in contract not currently staked or earmarked for something else.
        // This is a simplistic view; a real treasury might be in a separate contract.
        uint256 availableTreasuryBalance = balanceOf(address(this)).sub(totalEVLStaked);

        uint256 dynamicAdjustment = 0;

        // Example adaptive logic: Adjust APY based on various metrics
        // 1. User Activity: Boost APY if active users are low, to incentivize participation.
        if (activeUsers < 500 && activeUsers != 0) {
            dynamicAdjustment = dynamicAdjustment.add(50); // Add 0.5% (50 BPS)
        } else if (activeUsers >= 1000) {
            dynamicAdjustment = dynamicAdjustment.sub(25); // Subtract 0.25% (25 BPS)
        }

        // 2. Staking Ratio: If total staked is low relative to total supply, boost APY to encourage more staking.
        if (currentTotalSupply > 0 && totalEVLStaked.mul(10000).div(currentTotalSupply) < 3000) { // If less than 30% supply is staked
             dynamicAdjustment = dynamicAdjustment.add(75); // Add 0.75%
        }

        // 3. Treasury Health: If available treasury balance is high, the protocol can afford higher APY.
        if (availableTreasuryBalance > (currentTotalSupply.div(5)) ) { // If treasury has more than 20% of total supply (available)
            dynamicAdjustment = dynamicAdjustment.add(100); // Add 1%
        }

        uint256 finalAPY = baseAPY.add(dynamicAdjustment);
        // Ensure final APY does not exceed the maximum defined by governance
        return finalAPY > maxAPY ? maxAPY : finalAPY;
    }

    /// @notice Returns a participant's staking details, including pending rewards.
    /// @param participant The address of the participant.
    /// @return amount The current amount of tokens staked by the participant.
    /// @return lastRewardClaimTime The timestamp of the last time rewards were claimed or updated for this participant.
    /// @return rewardDebt The amount of pending rewards for the participant.
    /// @return initialStakeTime The timestamp when the participant first started staking.
    function getParticipantStakingInfo(address participant) public view returns (uint256 amount, uint256 lastRewardClaimTime, uint256 rewardDebt, uint256 initialStakeTime) {
        // Calculate pending rewards for view purposes without updating state
        uint256 stakedAmount = stakers[participant].amount;
        uint256 timeElapsed = block.timestamp.sub(stakers[participant].lastRewardClaimTime);
        uint256 currentAPY_BPS = getAdaptiveStakingAPY();
        uint256 calculatedRewards = 0;

        if (stakedAmount > 0 && timeElapsed > 0) {
            calculatedRewards = (stakedAmount.mul(currentAPY_BPS).mul(timeElapsed)) / (10_000 * 31_536_000);
        }

        return (
            stakers[participant].amount,
            stakers[participant].lastRewardClaimTime,
            stakers[participant].rewardDebt.add(calculatedRewards), // Include currently uncommitted pending rewards
            stakers[participant].initialStakeTime
        );
    }

    // --- II. Influence & Reputation System ---

    /// @notice Allows an address to opt-in and initialize their influence score.
    /// A participant must register before they can accumulate or lose influence points.
    function registerParticipant() public whenNotPaused {
        require(!influenceScores[msg.sender].registered, "Evolver: Participant already registered for influence");
        influenceScores[msg.sender].registered = true;
        influenceScores[msg.sender].score = 0; // Starts with a base score of 0
        influenceScores[msg.sender].lastUpdateTimestamp = block.timestamp;
    }

    /// @notice Awards influence points to a participant.
    /// @param participant The address to award influence to.
    /// @param amount The amount of influence points to add.
    /// @param source A bytes32 identifier for the source of influence (e.g., keccak256("DAO_VOTE"), keccak256("BOUNTY_COMPLETION")).
    function awardInfluence(address participant, uint256 amount, bytes32 source) public onlyRole(INFLUENCE_MANAGER_ROLE) whenNotPaused {
        require(influenceScores[participant].registered, "Evolver: Participant not registered for influence");
        _calculateInfluenceDecay(participant); // Apply decay before adding new points
        influenceScores[participant].score = influenceScores[participant].score.add(amount);
        influenceScores[participant].lastUpdateTimestamp = block.timestamp;
        emit InfluenceAwarded(participant, amount, source);
    }

    /// @notice Reduces influence points from a participant.
    /// @param participant The address to penalize.
    /// @param amount The amount of influence points to remove.
    /// @param source A bytes32 identifier for the source of penalty (e.g., keccak256("SLASHING_EVENT"), keccak256("MALICIOUS_BEHAVIOR")).
    function penalizeInfluence(address participant, uint256 amount, bytes32 source) public onlyRole(INFLUENCE_MANAGER_ROLE) whenNotPaused {
        require(influenceScores[participant].registered, "Evolver: Participant not registered for influence");
        _calculateInfluenceDecay(participant); // Apply decay before penalizing
        if (influenceScores[participant].score < amount) {
            influenceScores[participant].score = 0; // Ensure score doesn't go negative
        } else {
            influenceScores[participant].score = influenceScores[participant].score.sub(amount);
        }
        influenceScores[participant].lastUpdateTimestamp = block.timestamp;
        emit InfluencePenalized(participant, amount, source);
    }

    /// @notice Returns the current, decay-adjusted influence score of a participant.
    /// @param participant The address of the participant.
    /// @return The current influence score.
    function getInfluenceScore(address participant) public view returns (uint256) {
        if (!influenceScores[participant].registered) return 0; // Unregistered participants have 0 influence
        uint256 score = influenceScores[participant].score;
        uint256 lastUpdate = influenceScores[participant].lastUpdateTimestamp;
        uint256 decayRatePerDayBPS = protocolRules[keccak256("INFLUENCE_DECAY_RATE_PER_DAY")]; // in basis points (e.g., 10 for 0.1%)

        if (decayRatePerDayBPS == 0 || score == 0) return score;

        uint256 timeSinceLastUpdate = block.timestamp.sub(lastUpdate);
        uint256 daysElapsed = timeSinceLastUpdate.div(1 days); // 1 day = 86400 seconds

        if (daysElapsed > 0) {
            // Decay amount = score * (decayRatePerDayBPS / 10000) * daysElapsed
            uint256 decayAmount = (score.mul(decayRatePerDayBPS).mul(daysElapsed)).div(10_000);
            if (score < decayAmount) return 0;
            return score.sub(decayAmount);
        }
        return score;
    }

    /// @notice Internal function to apply influence decay for a single participant.
    /// This is called before any modification to a participant's score to ensure it's up-to-date.
    /// @param participant The address of the participant.
    function _calculateInfluenceDecay(address participant) internal {
        if (!influenceScores[participant].registered) return;
        uint256 currentScore = getInfluenceScore(participant); // This handles the decay calculation based on `block.timestamp`
        if (influenceScores[participant].score != currentScore) {
            emit InfluenceDecayed(participant, influenceScores[participant].score, currentScore);
            influenceScores[participant].score = currentScore;
            influenceScores[participant].lastUpdateTimestamp = block.timestamp; // Reset timestamp after applying decay
        }
    }

    /// @notice Determines the influence tier of a participant based on their current score.
    /// @param participant The address of the participant.
    /// @return A string indicating the tier (e.g., "Tier 0: Explorer", "Tier 3: Elite Contributor").
    function getInfluenceTier(address participant) public view returns (string memory) {
        uint256 score = getInfluenceScore(participant);
        if (score >= protocolRules[keccak256("MIN_INFLUENCE_TIER3")]) {
            return "Tier 3: Elite Contributor";
        } else if (score >= protocolRules[keccak256("MIN_INFLUENCE_TIER2")]) {
            return "Tier 2: Core Member";
        } else if (score >= protocolRules[keccak256("MIN_INFLUENCE_TIER1")]) {
            return "Tier 1: Active Participant";
        } else {
            return "Tier 0: Explorer";
        }
    }

    /// @notice Triggers influence decay for all active participants.
    /// @dev This function can be called by anyone (e.g., a keeper bot or an interested user)
    ///      to periodically update influence scores. For very large numbers of participants,
    ///      this might exceed gas limits and would require batching or an external keeper system
    ///      to call it incrementally. Here, it iterates over the `_activeStakers` set as a proxy for active participants.
    function triggerInfluenceDecay() public {
        uint256 numParticipants = _activeStakers.length();
        for (uint256 i = 0; i < numParticipants; i++) {
            address participant = _activeStakers.at(i);
            _calculateInfluenceDecay(participant); // Apply decay for each active staker
        }
    }

    // --- III. Adaptive Rules Engine & Behaviors ---

    /// @notice Creates a governance proposal to change a protocol rule.
    /// @param ruleKey The keccak256 hash of the rule name (e.g., keccak256("INFLUENCE_DECAY_RATE_PER_DAY")).
    /// @param newValue The new uint256 value for the rule.
    /// @param description A descriptive string for the governance proposal.
    /// @dev This function constructs and submits a proposal that, if successful, will call `setRule` on this contract.
    function proposeRuleChange(bytes32 ruleKey, uint256 newValue, string memory description) public returns (uint256) {
        bytes memory callData = abi.encodeWithSelector(this.setRule.selector, ruleKey, newValue);
        // `propose` expects arrays for targets, values, calldatas, and optional signatures (for arbitrary calls).
        // For a single call to `setRule` on this contract, these will be arrays of length 1.
        return propose(
            new address[](1),
            new uint256[](1),
            new bytes[](1),
            new string[](1), // signatures are not needed if target is `address(this)`
            new bytes[](1),  // calldatas for external calls, here `setRule`
            description
        );
    }

    /// @notice Sets a protocol rule. This function is designed to be called only by the Governor contract
    ///         after a successful governance proposal.
    /// @param ruleKey The keccak256 hash of the rule name.
    /// @param newValue The new value for the rule.
    function setRule(bytes32 ruleKey, uint256 newValue) public {
        // Enforce that only the Governor contract can directly call this function,
        // ensuring changes go through the DAO process.
        // This check is important as this function is public but internal to the governance flow.
        require(msg.sender == address(this), "Evolver: Only Governor can set rules");
        uint256 oldValue = protocolRules[ruleKey];
        protocolRules[ruleKey] = newValue;
        emit RuleChanged(ruleKey, oldValue, newValue);
    }

    /// @notice Creates a governance proposal to define a new incentivized/penalized behavior.
    /// @param behaviorId A unique bytes32 identifier for the behavior (e.g., keccak256("CONTRIBUTE_CODE")).
    /// @param config The `BehaviorConfig` struct containing details for the new behavior.
    /// @dev This function constructs and submits a proposal that, if successful, will call `_defineBehavior` on this contract.
    function defineBehavior(bytes32 behaviorId, BehaviorConfig memory config) public returns (uint256) {
        bytes memory callData = abi.encodeWithSelector(this._defineBehavior.selector, behaviorId, config);
        return propose(
            new address[](1),
            new uint256[](1),
            new bytes[](1),
            new string[](1),
            new bytes[](1),
            string(abi.encodePacked("Define new behavior: ", config.description))
        );
    }

    /// @notice Defines a new behavior. This function is designed to be called only by the Governor contract
    ///         after a successful governance proposal.
    /// @param behaviorId A unique identifier for the behavior.
    /// @param config The configuration struct for the new behavior.
    function _defineBehavior(bytes32 behaviorId, BehaviorConfig memory config) public {
        // Enforce that only the Governor contract can directly call this function.
        require(msg.sender == address(this), "Evolver: Only Governor can define behaviors");
        behaviors[behaviorId] = config;
        emit BehaviorDefined(behaviorId, config);
    }

    /// @notice Records completion of a defined behavior, triggering influence and token effects.
    /// @param behaviorId The unique identifier of the completed behavior.
    /// @param participant The address of the participant who completed the behavior.
    /// @param proof Optional proof data (e.g., signed oracle data, transaction hash, or cryptographic proof).
    /// @dev This function is restricted to BEHAVIOR_RECORDER_ROLE (e.g., an oracle contract or a trusted keeper)
    ///      to ensure only verified completions are recorded. Includes a cooldown mechanism to prevent spamming.
    function recordBehaviorCompletion(bytes32 behaviorId, address participant, bytes memory proof) public onlyRole(BEHAVIOR_RECORDER_ROLE) whenNotPaused {
        BehaviorConfig storage behavior = behaviors[behaviorId];
        require(behavior.active, "Evolver: Behavior is not active or defined");
        require(influenceScores[participant].registered, "Evolver: Participant not registered for influence");

        // Enforce cooldown if defined for this behavior
        if (behavior.cooldown > 0) {
            require(block.timestamp >= lastBehaviorCompletionTime[participant][behaviorId].add(behavior.cooldown), "Evolver: Behavior on cooldown for participant");
            lastBehaviorCompletionTime[participant][behaviorId] = block.timestamp; // Update last completion time
        }

        _calculateInfluenceDecay(participant); // Apply any pending influence decay before applying new effects

        uint256 currentInfluence = influenceScores[participant].score;
        uint256 actualInfluenceChange = 0;
        uint256 actualTokenReward = 0;

        if (behavior.penalizing) {
            actualInfluenceChange = behavior.influenceEffect;
            if (currentInfluence < actualInfluenceChange) {
                influenceScores[participant].score = 0; // Score cannot go below zero
            } else {
                influenceScores[participant].score = currentInfluence.sub(actualInfluenceChange);
            }
            emit InfluencePenalized(participant, actualInfluenceChange, behaviorId);
        } else {
            actualInfluenceChange = behavior.influenceEffect;
            influenceScores[participant].score = currentInfluence.add(actualInfluenceChange);
            emit InfluenceAwarded(participant, actualInfluenceChange, behaviorId);
        }
        influenceScores[participant].lastUpdateTimestamp = block.timestamp; // Update timestamp after score change

        // Mint token rewards if defined for this behavior
        if (behavior.tokenReward > 0) {
            _mint(participant, behavior.tokenReward);
            actualTokenReward = behavior.tokenReward;
        }

        emit BehaviorCompleted(participant, behaviorId, actualInfluenceChange, actualTokenReward);
    }

    /// @notice Returns the current value of a specified protocol rule.
    /// @param ruleKey The keccak256 hash of the rule name.
    /// @return The uint256 value of the rule.
    function getRule(bytes32 ruleKey) public view returns (uint256) {
        return protocolRules[ruleKey];
    }

    /// @notice Returns the configuration details of a specified defined behavior.
    /// @param behaviorId The unique identifier of the behavior.
    /// @return The `BehaviorConfig` struct containing all its properties.
    function getBehaviorDetails(bytes32 behaviorId) public view returns (BehaviorConfig memory) {
        return behaviors[behaviorId];
    }

    // --- IV. DAO Governance (Inherited from Governor) ---
    // The `propose`, `vote`, `queue`, `execute`, `cancel` functions are inherited directly from
    // OpenZeppelin's `Governor` contract. They orchestrate the decentralized decision-making process
    // by interacting with the `TimelockController` (returned by `__timelock()`).
    // No additional implementation is typically needed here unless custom execution logic is required.

    // --- V. Protocol Metrics & Dynamic Economics ---

    /// @notice Allows METRIC_UPDATER_ROLE to update protocol health metrics.
    /// @param metricKey The keccak256 hash of the metric name (e.g., keccak256("activeUsers"), keccak256("totalTransactions")).
    /// @param value The new uint256 value for the metric.
    /// @dev This function would typically be called by an off-chain oracle or a trusted keeper to feed data to the contract.
    function updateMetric(bytes32 metricKey, uint256 value) public onlyRole(METRIC_UPDATER_ROLE) whenNotPaused {
        uint256 oldValue = protocolMetrics[metricKey];
        protocolMetrics[metricKey] = value;
        emit MetricUpdated(metricKey, oldValue, value);
    }

    /// @notice Returns the current value of a specified protocol metric.
    /// @param metricKey The keccak256 hash of the metric name.
    /// @return The uint256 value of the metric.
    function getMetricValue(bytes32 metricKey) public view returns (uint256) {
        return protocolMetrics[metricKey];
    }

    /// @notice Initiates a token supply adjustment (mint or burn) based on protocol metrics and predefined rules.
    /// @dev This function is intended to be called by an automated system (e.g., a keeper bot with AUTOMATION_ROLE)
    ///      or periodically by the DAO. It enforces adaptive tokenomics to maintain supply targets.
    function triggerDynamicSupplyAdjustment() public onlyRole(AUTOMATION_ROLE) whenNotPaused {
        uint256 currentSupply = totalSupply();
        // The initial supply is a fixed reference point for calculating target bounds.
        // This value should ideally be defined as a constant or immutable in a production system.
        uint252 initialSupply = 100_000_000 * (10 ** decimals()); 
        
        uint256 minTargetRatioBPS = protocolRules[keccak256("MIN_SUPPLY_TARGET_RATIO_BPS")];
        uint256 maxTargetRatioBPS = protocolRules[keccak256("MAX_SUPPLY_TARGET_RATIO_BPS")];
        uint256 adjustmentPercentBPS = protocolRules[keccak256("SUPPLY_ADJUSTMENT_PERCENT_BPS")]; // In Basis Points (e.g., 100 for 1%)

        uint256 lowerBound = initialSupply.mul(minTargetRatioBPS).div(10_000);
        uint256 upperBound = initialSupply.mul(maxTargetRatioBPS).div(10_000);

        uint256 adjustmentAmount = currentSupply.mul(adjustmentPercentBPS).div(10_000);
        require(adjustmentAmount > 0, "Evolver: Adjustment amount too small for meaningful change");

        bool minted = false;
        uint256 newSupply;

        if (currentSupply < lowerBound) {
            // Supply is below target range, mint tokens to increase it.
            _mint(address(this), adjustmentAmount); // Mint to contract, can be distributed later by DAO/treasury
            newSupply = currentSupply.add(adjustmentAmount);
            minted = true;
        } else if (currentSupply > upperBound) {
            // Supply is above target range, burn tokens to decrease it.
            // Ensure the contract has enough balance to burn.
            require(balanceOf(address(this)) >= adjustmentAmount, "Evolver: Insufficient contract balance to burn");
            _burn(address(this), adjustmentAmount); // Burn from contract's balance
            newSupply = currentSupply.sub(adjustmentAmount);
            minted = false;
        } else {
            // Supply is already within the desired bounds, no adjustment needed.
            return;
        }

        emit SupplyAdjusted(currentSupply, newSupply, minted);
    }

    // --- VI. System Control & Utility ---

    /// @notice Pauses or unpauses the contract in case of emergency.
    /// @dev Restricted to PAUSER_ROLE. When paused, most state-changing functions are blocked.
    function togglePause() public onlyRole(PAUSER_ROLE) {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Grants a specified role to an account.
    /// @param role The role to grant (e.g., MINTER_ROLE, PAUSER_ROLE).
    /// @param account The address to grant the role to.
    /// @dev Restricted to DEFAULT_ADMIN_ROLE.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @notice Revokes a specified role from an account.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    /// @dev Restricted to DEFAULT_ADMIN_ROLE. Note: Default admin cannot revoke its own admin role without specific logic.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    // --- Internal OpenZeppelin overrides for ERC20Votes compatibility ---
    /// @dev Hook that is called after any token transfer.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Hook that is called before any token transfer.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
```