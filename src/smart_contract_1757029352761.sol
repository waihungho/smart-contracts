## QuantumLeap Protocol: Adaptive & Reputational Governance Engine

This contract implements an advanced, self-adjusting decentralized autonomous organization (DAO) where core governance parameters, user influence, and reward structures dynamically adapt based on a holistic "Protocol Health Index" (PHI) and individual user "Reputation Scores". It integrates a gamified bounty system to incentivize contributions, directly linking successful participation to reputation and governance power.

### Outline & Function Summary

**I. Core Configuration & Protocol State (5 functions)**
1.  **`initializeProtocol`**: Sets the initial owner, the address of the ERC-20 token used for staking and rewards, and initial core governance thresholds.
2.  **`updateProtocolSetting`**: Allows the current owner or DAO to modify various non-dynamic protocol settings (e.g., oracle address, default reputation values).
3.  **`setHealthMetricWeights`**: Configures the weight of each component metric when calculating the Protocol Health Index (PHI).
4.  **`updateExternalOracleMetrics`**: Callable by the designated oracle to push up-to-date external health metrics (e.g., market sentiment, external TVL) into the protocol.
5.  **`getProtocolHealthIndex`**: Calculates and returns the current holistic Protocol Health Index (PHI) based on weighted internal and external metrics.

**II. Reputation & Stake Management (5 functions)**
6.  **`stakeForReputation`**: Allows users to deposit the protocol's ERC-20 token into the contract to gain reputation and governance influence. Reputation accrual may be time-based or action-based.
7.  **`unstakeFromReputation`**: Enables users to withdraw their staked tokens, potentially incurring a small reputation penalty or loss of influence.
8.  **`getReputationScore`**: Returns a user's current raw reputation score within the protocol.
9.  **`_adjustReputation`**: An internal function used to mint or burn a specified amount of reputation for a user, triggered by protocol actions (e.g., successful proposal, failed vote, bounty completion).
10. **`getEffectiveVotingPower`**: Calculates a user's adjusted voting power for governance, dynamically considering their staked tokens and their current reputation score.

**III. Dynamic Governance & Adaptive Parameters (6 functions)**
11. **`submitDynamicProposal`**: Allows users to submit proposals to modify specific protocol parameters dynamically. Submission requires meeting dynamically adjusted reputation and stake thresholds.
12. **`voteOnDynamicProposal`**: Enables users to cast their vote (for or against) on an active dynamic proposal. Their vote weight is determined by their `getEffectiveVotingPower`.
13. **`executeDynamicProposal`**: Executes a passed dynamic proposal, automatically applying the proposed changes to the relevant protocol parameter. Callable by anyone after the voting period ends and passes.
14. **`getDynamicProposalThreshold`**: Returns the current dynamically adjusted minimum reputation and stake required for a user to submit a new proposal, adapting based on PHI.
15. **`getDynamicVotingDuration`**: Returns the current dynamically adjusted minimum voting duration for proposals, adapting based on PHI.
16. **`proposeEmergencyShutdown`**: Allows high-reputation users (meeting a specific threshold) to initiate a critical vote to pause core protocol functions in an emergency.

**IV. Decentralized Task & Contribution System (Gamified Quests) (4 functions)**
17. **`createProtocolBounty`**: Allows the DAO or designated administrators to create a bounty for specific development, research, or marketing tasks, defining token and reputation rewards.
18. **`submitBountySolution`**: Users submit their work or a link/CID (e.g., IPFS hash) to their solution for an open bounty.
19. **`evaluateBountySolution`**: The DAO or designated reviewers evaluate submitted solutions. If accepted, the submitter is awarded tokens and reputation.
20. **`claimBountyReward`**: Enables successful bounty submitters to claim their token rewards and receive their reputation increase after their solution has been evaluated and accepted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit use, though Solidity >=0.8.0 handles overflow
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// Custom errors for better debugging and user experience
error InvalidParameters(string message);
error InsufficientStake(uint256 required, uint256 provided);
error InsufficientReputation(uint256 required, uint256 provided);
error ProposalAlreadyExists();
error ProposalNotFound();
error VotingPeriodNotActive();
error VotingPeriodExpired();
error AlreadyVoted();
error NotAuthorized(string message);
error BountyNotFound();
error SolutionAlreadySubmitted();
error BountyNotYetEvaluated();
error BountyAlreadyClaimed();
error SelfAdjustmentFailed();
error EmergencyShutdownActive();
error OracleCallFailed(string message);
error ProposalNotPassed();
error ProposalAlreadyExecuted();
error BountyStillOpen();

/**
 * @title QuantumLeap Protocol: Adaptive & Reputational Governance Engine
 * @dev This contract implements an advanced, self-adjusting decentralized autonomous organization (DAO)
 *      where core governance parameters, user influence, and reward structures dynamically adapt
 *      based on a holistic "Protocol Health Index" (PHI) and individual user "Reputation Scores".
 *      It integrates a gamified bounty system to incentivize contributions, directly linking
 *      successful participation to reputation and governance power.
 *
 *      Key Concepts:
 *      1.  **Dynamic Governance Parameters:** Proposal thresholds, voting durations, and other
 *          governance-critical values are not fixed but can be adjusted automatically or
 *          through proposals based on PHI and reputation.
 *      2.  **Reputation System:** Users earn reputation through constructive participation
 *          (e.g., submitting successful proposals, voting aligned with outcomes, completing bounties)
 *          and may lose it for negative actions. Reputation directly amplifies voting power and
 *          influences the ability to propose.
 *      3.  **Protocol Health Index (PHI):** A composite score derived from internal (e.g., TVL,
 *          transaction volume) and external (e.g., market sentiment via oracle) metrics,
 *          indicating the overall health and stability of the protocol. PHI is a primary
 *          driver for dynamic parameter adjustments.
 *      4.  **Gamified Bounties:** A system to crowdsource tasks and reward contributors with tokens
 *          and reputation, fostering active community engagement.
 *      5.  **Adaptive Voting Power:** A user's vote weight is a function of their staked tokens
 *          and their reputation score, incentivizing long-term, positive engagement.
 */
contract QuantumLeapProtocol is Ownable, Pausable {
    using SafeMath for uint256; // Explicitly use SafeMath for older versions, though 0.8.0+ has native checks

    IERC20 public quantumLeapToken; // The token used for staking and rewards

    // --- I. Core Configuration & Protocol State ---
    address public _oracleAddress; // Address of the trusted oracle
    uint256 public constant TOTAL_WEIGHT_PERCENT = 10000; // Total percentage for health metric weights (100.00%)

    // Health metrics and their weights
    mapping(string => uint256) public rawHealthMetrics; // e.g., "TVL", "Volume", "Sentiment"
    mapping(string => uint256) public healthMetricWeights; // e.g., "TVL" => 5000 (50.00%)

    // Dynamically adjustable parameters
    mapping(string => uint256) public protocolParameters; // e.g., "minReputationForProposal", "minStakeForProposal", "minVotingDuration"

    // --- II. Reputation & Stake Management ---
    mapping(address => uint256) public userReputation;
    mapping(address => uint256) public stakedBalances;

    // --- III. Dynamic Governance & Adaptive Parameters ---
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 submissionTimestamp;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
        bool passed;
        string paramToAdjust; // The parameter key (from protocolParameters)
        uint256 newValue;    // The new value proposed for the parameter
        bool isEmergencyShutdown;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public proposalQuorumThresholdPercent; // e.g., 5000 for 50%
    uint256 public proposalVoteDifferenceRequiredPercent; // e.g., 1000 for 10% more 'for' than 'against'

    // --- IV. Decentralized Task & Contribution System (Gamified Quests) ---
    struct Bounty {
        uint256 bountyId;
        address creator;
        string description;
        uint256 rewardAmount; // In QuantumLeapToken
        uint256 reputationReward;
        address solutionSubmitter;
        string solutionCID; // IPFS CID for the solution
        bool evaluated;
        bool solutionAccepted; // True if solution was accepted
        bool claimed;
        uint256 creationTimestamp;
        uint256 evaluationTimestamp;
    }
    mapping(uint256 => Bounty) public bounties;
    uint256 public nextBountyId;

    // Events
    event ProtocolInitialized(address indexed owner, address indexed token);
    event ProtocolSettingUpdated(string indexed settingKey, uint256 newValue);
    event HealthMetricWeightsUpdated(string indexed metric, uint256 weight);
    event ExternalMetricsUpdated(string indexed metric, uint256 value);
    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 amount);
    event ReputationAdjusted(address indexed user, uint256 oldScore, uint256 newScore);
    event DynamicProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, string param, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool decision, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, uint256 reputationReward);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed submitter, string solutionCID);
    event BountyEvaluated(uint256 indexed bountyId, address indexed submitter, bool accepted);
    event BountyClaimed(uint256 indexed bountyId, address indexed submitter);
    event EmergencyShutdownProposed(uint256 indexed proposalId, address indexed proposer);

    /**
     * @dev Constructor is removed as best practice for upgradeability.
     *      `initializeProtocol` serves as the constructor-like function.
     */
    constructor() {
        // Owner is set by Ownable's constructor
    }

    modifier onlyOracle() {
        if (_msgSender() != _oracleAddress) {
            revert NotAuthorized("Only the designated oracle can call this function.");
        }
        _;
    }

    /**
     * @dev Initializes the protocol with the ERC20 token, initial owner, and default parameters.
     *      Can only be called once.
     * @param tokenAddress The address of the ERC-20 token to be used for staking and rewards.
     * @param initialMinRepForProposal Initial minimum reputation required to submit a proposal.
     * @param initialMinStakeForProposal Initial minimum stake required to submit a proposal.
     * @param initialMinVotingDuration Initial minimum voting duration in seconds.
     * @param initialMaxVotingDuration Initial maximum voting duration in seconds.
     * @param initialRepRewardForVote Initial reputation reward for a successful vote.
     * @param initialRepPenaltyForFailed Initial reputation penalty for a failed proposal.
     * @param initialRepPenaltyForMisaligned Initial reputation penalty for a misaligned vote.
     * @param initialRepBoostPerStakedToken Initial reputation boost per staked token.
     * @param initialEmergencyShutdownRep Initial reputation required to propose emergency shutdown.
     */
    function initializeProtocol(
        address tokenAddress,
        uint256 initialMinRepForProposal,
        uint256 initialMinStakeForProposal,
        uint256 initialMinVotingDuration,
        uint256 initialMaxVotingDuration,
        uint256 initialRepRewardForVote,
        uint256 initialRepPenaltyForFailed,
        uint256 initialRepPenaltyForMisaligned,
        uint256 initialRepBoostPerStakedToken,
        uint256 initialEmergencyShutdownRep,
        uint256 initialProposalQuorumThresholdPercent,
        uint256 initialProposalVoteDifferenceRequiredPercent
    ) external onlyOwner {
        if (quantumLeapToken != IERC20(address(0))) {
            revert InvalidParameters("Protocol already initialized.");
        }
        if (tokenAddress == address(0)) {
            revert InvalidParameters("Token address cannot be zero.");
        }
        quantumLeapToken = IERC20(tokenAddress);

        _oracleAddress = owner(); // Default oracle to owner, can be changed later

        protocolParameters["minReputationForProposal"] = initialMinRepForProposal;
        protocolParameters["minStakeForProposal"] = initialMinStakeForProposal;
        protocolParameters["minVotingDuration"] = initialMinVotingDuration;
        protocolParameters["maxVotingDuration"] = initialMaxVotingDuration;
        protocolParameters["reputationRewardForSuccessfulVote"] = initialRepRewardForVote;
        protocolParameters["reputationPenaltyForFailedProposal"] = initialRepPenaltyForFailed;
        protocolParameters["reputationPenaltyForMisalignedVote"] = initialRepPenaltyForMisaligned;
        protocolParameters["reputationBoostPerStakedToken"] = initialRepBoostPerStakedToken; // E.g., 1 reputation per 1000 tokens
        protocolParameters["emergencyShutdownThresholdReputation"] = initialEmergencyShutdownRep;

        proposalQuorumThresholdPercent = initialProposalQuorumThresholdPercent; // e.g., 5000 = 50%
        proposalVoteDifferenceRequiredPercent = initialProposalVoteDifferenceRequiredPercent; // e.g., 1000 = 10%

        emit ProtocolInitialized(_msgSender(), tokenAddress);
    }

    /**
     * @dev Allows the current owner or DAO to modify various non-dynamic protocol settings.
     *      For dynamic parameters, use the governance system.
     * @param settingKey A string key for the setting to update (e.g., "_oracleAddress", "proposalQuorumThresholdPercent").
     * @param newValue The new value for the setting.
     */
    function updateProtocolSetting(string calldata settingKey, uint256 newValue) external onlyOwner {
        // Can be extended with DAO voting for this later
        if (keccak256(abi.encodePacked(settingKey)) == keccak256(abi.encodePacked("_oracleAddress"))) {
            _oracleAddress = address(uint160(newValue));
        } else if (keccak256(abi.encodePacked(settingKey)) == keccak256(abi.encodePacked("proposalQuorumThresholdPercent"))) {
            proposalQuorumThresholdPercent = newValue;
        } else if (keccak256(abi.encodePacked(settingKey)) == keccak256(abi.encodePacked("proposalVoteDifferenceRequiredPercent"))) {
            proposalVoteDifferenceRequiredPercent = newValue;
        } else {
            revert InvalidParameters("Unknown setting key.");
        }
        emit ProtocolSettingUpdated(settingKey, newValue);
    }

    /**
     * @dev Configures the weight of each component metric when calculating the Protocol Health Index (PHI).
     *      Weights must sum up to TOTAL_WEIGHT_PERCENT (100.00%).
     * @param metrics An array of metric keys (e.g., "TVL", "Volume").
     * @param weights An array of corresponding weights (e.g., 5000 for 50%).
     */
    function setHealthMetricWeights(string[] calldata metrics, uint256[] calldata weights) external onlyOwner {
        if (metrics.length != weights.length || metrics.length == 0) {
            revert InvalidParameters("Metric and weight arrays must have matching non-zero lengths.");
        }

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < metrics.length; i++) {
            totalWeight = totalWeight.add(weights[i]);
        }

        if (totalWeight != TOTAL_WEIGHT_PERCENT) {
            revert InvalidParameters("Total weights must sum to 100.00% (TOTAL_WEIGHT_PERCENT).");
        }

        for (uint256 i = 0; i < metrics.length; i++) {
            healthMetricWeights[metrics[i]] = weights[i];
            emit HealthMetricWeightsUpdated(metrics[i], weights[i]);
        }
    }

    /**
     * @dev Callable by the designated oracle to push up-to-date external health metrics.
     * @param metricKey The key for the health metric (e.g., "MarketSentiment", "ExternalTVL").
     * @param value The latest value for this metric.
     */
    function updateExternalOracleMetrics(string calldata metricKey, uint256 value) external onlyOracle {
        rawHealthMetrics[metricKey] = value;
        emit ExternalMetricsUpdated(metricKey, value);
    }

    /**
     * @dev Calculates and returns the current holistic Protocol Health Index (PHI).
     *      PHI is a weighted average of all configured internal and external metrics.
     *      Returns a value normalized, e.g., to 10000 for 100%.
     */
    function getProtocolHealthIndex() public view returns (uint256) {
        uint256 weightedSum = 0;
        uint256 activeWeights = 0;

        // Iterate through all possible health metric keys. This assumes some predefined keys.
        // For dynamic metric keys, a list of keys would need to be stored or passed.
        // For simplicity, we'll assume `healthMetricWeights` only contains valid keys.
        // A more robust system would store a list of active metric keys.
        
        // Example: hardcoded common metric keys for demonstration
        string[] memory commonMetricKeys = new string[](3); // Adjust size as needed
        commonMetricKeys[0] = "TVL";
        commonMetricKeys[1] = "Volume";
        commonMetricKeys[2] = "Sentiment";

        for (uint256 i = 0; i < commonMetricKeys.length; i++) {
            string memory key = commonMetricKeys[i];
            if (healthMetricWeights[key] > 0) {
                weightedSum = weightedSum.add(rawHealthMetrics[key].mul(healthMetricWeights[key]));
                activeWeights = activeWeights.add(healthMetricWeights[key]);
            }
        }

        if (activeWeights == 0) return 0; // Avoid division by zero

        // PHI is normalized to 10000 (representing 100%)
        // So, if raw metrics are 0-100 and weights sum to 10000, then PHI is 0-10000
        return weightedSum.div(activeWeights);
    }

    /**
     * @dev Allows users to deposit the protocol's ERC-20 token into the contract to gain reputation and governance influence.
     * @param amount The amount of tokens to stake.
     */
    function stakeForReputation(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidParameters("Stake amount must be greater than zero.");
        if (!quantumLeapToken.transferFrom(_msgSender(), address(this), amount)) {
            revert InsufficientStake("Token transfer failed.", amount, 0); // No min required here
        }
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].add(amount);

        // Optional: Immediately adjust reputation based on new stake, or over time
        // For simplicity, let's assume initial reputation boost on stake.
        // A more complex system might distribute reputation over time.
        uint256 currentRep = userReputation[_msgSender()];
        uint256 reputationBoost = amount.mul(protocolParameters["reputationBoostPerStakedToken"]).div(1e18); // Example: 1 token = X reputation
        _adjustReputation(_msgSender(), reputationBoost, true);

        emit ReputationStaked(_msgSender(), amount);
    }

    /**
     * @dev Enables users to withdraw their staked tokens.
     * @param amount The amount of tokens to unstake.
     */
    function unstakeFromReputation(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidParameters("Unstake amount must be greater than zero.");
        if (stakedBalances[_msgSender()] < amount) {
            revert InsufficientStake("Not enough staked balance.", amount, stakedBalances[_msgSender()]);
        }

        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].sub(amount);

        // Optional: Penalize reputation on unstake or reduce reputation boost
        uint256 reputationPenalty = amount.mul(protocolParameters["reputationBoostPerStakedToken"]).div(2e18); // Example: half of boost removed
        _adjustReputation(_msgSender(), reputationPenalty, false); // Burn reputation

        if (!quantumLeapToken.transfer(_msgSender(), amount)) {
            revert SelfAdjustmentFailed(); // Should not fail if transferFrom succeeded
        }
        emit ReputationUnstaked(_msgSender(), amount);
    }

    /**
     * @dev Returns a user's current raw reputation score within the protocol.
     * @param user The address of the user.
     */
    function getReputationScore(address user) public view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @dev Internal function to mint or burn a specified amount of reputation for a user.
     * @param user The address whose reputation to adjust.
     * @param amount The amount of reputation to adjust by.
     * @param mint True to add reputation, false to burn.
     */
    function _adjustReputation(address user, uint256 amount, bool mint) internal {
        uint256 oldRep = userReputation[user];
        if (mint) {
            userReputation[user] = userReputation[user].add(amount);
        } else {
            userReputation[user] = userReputation[user] > amount ? userReputation[user].sub(amount) : 0;
        }
        emit ReputationAdjusted(user, oldRep, userReputation[user]);
    }

    /**
     * @dev Calculates a user's adjusted voting power for governance, dynamically considering their staked tokens and their current reputation score.
     *      Formula: `stakedAmount * (1 + (reputationScore / 10000))` (assuming max reputation score is around 10000 for 1x multiplier)
     *      This could be made more complex (e.g., logarithmic) if needed.
     * @param user The address of the user.
     */
    function getEffectiveVotingPower(address user) public view returns (uint256) {
        uint256 stake = stakedBalances[user];
        uint256 reputation = userReputation[user];
        if (stake == 0) return 0;

        // Simple linear boost: 100 reputation points = 1% boost
        // This means 10,000 reputation points would double voting power
        // scaled factor: (10000 + reputation) / 10000
        return stake.mul(TOTAL_WEIGHT_PERCENT.add(reputation)).div(TOTAL_WEIGHT_PERCENT);
    }

    /**
     * @dev Returns the current dynamically adjusted minimum reputation and stake required to submit a proposal.
     *      Adapts based on the current Protocol Health Index (PHI).
     *      Higher PHI -> lower requirements, lower PHI -> higher requirements.
     */
    function getDynamicProposalThreshold() public view returns (uint256 minRep, uint256 minStake) {
        uint256 phi = getProtocolHealthIndex(); // PHI is 0-10000 (0-100%)
        uint256 baseMinRep = protocolParameters["minReputationForProposal"];
        uint256 baseMinStake = protocolParameters["minStakeForProposal"];

        // Adjust based on PHI: Inverse relationship
        // When PHI is 100% (10000), adjustment is minimal (e.g., 0.5x base)
        // When PHI is 0% (0), adjustment is maximal (e.g., 2x base)
        // Adjustment factor = (TOTAL_WEIGHT_PERCENT + (TOTAL_WEIGHT_PERCENT - PHI)) / TOTAL_WEIGHT_PERCENT * some_factor
        // Simpler: let's do a linear scaling from 0.5x to 1.5x based on PHI.
        // If PHI = 10000 (100%), factor = 0.5. If PHI = 0, factor = 1.5.
        // (15000 - phi) / 10000 -> (1.5 - phi/10000)
        uint256 adjustmentFactor = (15000 - phi).mul(100).div(10000); // 150 (for 1.5x) to 50 (for 0.5x)

        minRep = baseMinRep.mul(adjustmentFactor).div(100);
        minStake = baseMinStake.mul(adjustmentFactor).div(100);
        return (minRep, minStake);
    }

    /**
     * @dev Returns the current dynamically adjusted minimum voting duration for proposals.
     *      Adapts based on the current Protocol Health Index (PHI).
     *      Higher PHI -> shorter duration, lower PHI -> longer duration (for more deliberation).
     */
    function getDynamicVotingDuration() public view returns (uint256 minDuration, uint256 maxDuration) {
        uint256 phi = getProtocolHealthIndex();
        uint256 baseMinDur = protocolParameters["minVotingDuration"];
        uint256 baseMaxDur = protocolParameters["maxVotingDuration"];

        // Adjustment: Direct relationship
        // When PHI is 100% (10000), shorter duration (e.g., 0.8x base)
        // When PHI is 0% (0), longer duration (e.g., 1.2x base)
        // (12000 - phi*0.4) / 10000 -> (1.2 - phi*0.00004)
        uint256 adjustmentFactor = (12000 - phi.div(10).mul(4)).div(100); // e.g., 120 (1.2x) to 80 (0.8x)

        minDuration = baseMinDur.mul(adjustmentFactor).div(100);
        maxDuration = baseMaxDur.mul(adjustmentFactor).div(100);
        return (minDuration, maxDuration);
    }

    /**
     * @dev Allows users to submit proposals to modify specific protocol parameters dynamically.
     *      Submission requires meeting dynamically adjusted reputation and stake thresholds.
     * @param description A brief description of the proposal.
     * @param paramToAdjust The key of the parameter to be adjusted (e.g., "minReputationForProposal").
     * @param newValue The new value proposed for the parameter.
     */
    function submitDynamicProposal(
        string calldata description,
        string calldata paramToAdjust,
        uint256 newValue
    ) external whenNotPaused returns (uint256) {
        (uint256 minRepRequired, uint256 minStakeRequired) = getDynamicProposalThreshold();

        if (userReputation[_msgSender()] < minRepRequired) {
            revert InsufficientReputation(minRepRequired, userReputation[_msgSender()]);
        }
        if (stakedBalances[_msgSender()] < minStakeRequired) {
            revert InsufficientStake(minStakeRequired, stakedBalances[_msgSender()]);
        }
        if (bytes(paramToAdjust).length == 0) {
            revert InvalidParameters("Parameter to adjust cannot be empty.");
        }
        if (newValue == 0 && !(_isZeroAllowed(paramToAdjust))) {
             revert InvalidParameters("New value cannot be zero for this parameter.");
        }
        
        uint256 currentProposalId = nextProposalId++;
        (uint256 minDur, ) = getDynamicVotingDuration();

        proposals[currentProposalId] = Proposal({
            proposalId: currentProposalId,
            proposer: _msgSender(),
            description: description,
            submissionTimestamp: block.timestamp,
            votingStart: block.timestamp,
            votingEnd: block.timestamp.add(minDur),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            paramToAdjust: paramToAdjust,
            newValue: newValue,
            isEmergencyShutdown: false
        });

        emit DynamicProposalSubmitted(currentProposalId, _msgSender(), description, paramToAdjust, newValue);
        return currentProposalId;
    }

    // Helper for checking if 0 is allowed for a parameter
    function _isZeroAllowed(string memory paramKey) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(paramKey)) == keccak256(abi.encodePacked("reputationPenaltyForFailedProposal")) ||
                keccak256(abi.encodePacked(paramKey)) == keccak256(abi.encodePacked("reputationPenaltyForMisalignedVote")));
    }


    /**
     * @dev Allows users to cast their vote (for or against) on an active dynamic proposal.
     *      Their vote weight is determined by their `getEffectiveVotingPower`.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteFor True to vote 'for', false to vote 'against'.
     */
    function voteOnDynamicProposal(uint256 proposalId, bool voteFor) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0 && proposalId != 0) { // Check if proposal exists (nextProposalId starts at 0, so 0 is a valid id if submitted)
            revert ProposalNotFound();
        }
        if (proposal.votingStart == 0 || block.timestamp < proposal.votingStart) {
            revert VotingPeriodNotActive();
        }
        if (block.timestamp > proposal.votingEnd) {
            revert VotingPeriodExpired();
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert AlreadyVoted();
        }

        uint256 voterPower = getEffectiveVotingPower(_msgSender());
        if (voterPower == 0) {
            revert InsufficientStake("User has no effective voting power.", 1, 0); // Placeholder values
        }

        proposal.hasVoted[_msgSender()] = true;
        if (voteFor) {
            proposal.votesFor = proposal.votesFor.add(voterPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterPower);
        }

        emit VoteCast(proposalId, _msgSender(), voteFor, voterPower);
    }

    /**
     * @dev Executes a passed dynamic proposal, automatically applying the proposed changes
     *      to the relevant protocol parameter. Callable by anyone after the voting period ends.
     *      Rewards/penalizes reputation for proposer and voters.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeDynamicProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0 && proposalId != 0) {
            revert ProposalNotFound();
        }
        if (block.timestamp <= proposal.votingEnd) {
            revert VotingPeriodNotActive(); // Voting period not yet over
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes == 0) {
            proposal.passed = false; // No votes, no pass
        } else {
            // Check quorum: percentage of total possible voting power that participated
            // For simplicity, we'll check against total votes cast here.
            // A more complex system would track total active voting power in the system.
            bool quorumReached = proposal.votesFor.add(proposal.votesAgainst) >= (getTotalVotingPowerInSystem().mul(proposalQuorumThresholdPercent).div(TOTAL_WEIGHT_PERCENT));
            
            // Check vote difference: votesFor must be X% higher than votesAgainst
            bool sufficientDifference = proposal.votesFor.mul(TOTAL_WEIGHT_PERCENT).div(totalVotes) >=
                                        (5000 + proposalVoteDifferenceRequiredPercent); // 50% + difference %

            if (proposal.isEmergencyShutdown) {
                // Emergency shutdown only requires quorum and simple majority for simplicity here.
                // Could be higher threshold.
                proposal.passed = quorumReached && (proposal.votesFor > proposal.votesAgainst);
            } else {
                proposal.passed = quorumReached && sufficientDifference;
            }
        }

        if (proposal.passed) {
            // Execute the parameter adjustment
            if (proposal.isEmergencyShutdown) {
                _pause(); // Pauses the contract
                emit ProposalExecuted(proposalId, true);
                return; // Exit after emergency pause
            } else {
                protocolParameters[proposal.paramToAdjust] = proposal.newValue;
                _adjustReputation(proposal.proposer, protocolParameters["reputationRewardForSuccessfulVote"], true);
            }
        } else {
            // Penalize proposer if proposal failed
            _adjustReputation(proposal.proposer, protocolParameters["reputationPenaltyForFailedProposal"], false);
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.passed);
    }
    
    // Placeholder function: In a real system, this would iterate over all staked users
    // or keep a running total of effective voting power.
    function getTotalVotingPowerInSystem() public view returns (uint256) {
        // For simplicity, return sum of staked tokens.
        // A more advanced system might need to sum getEffectiveVotingPower for all users.
        // This is a placeholder and would need a robust mechanism to scale.
        return quantumLeapToken.balanceOf(address(this)); // Simple approximation
    }


    /**
     * @dev Allows high-reputation users (meeting a specific threshold) to initiate
     *      a critical vote to pause core protocol functions in an emergency.
     * @param description A brief description of the emergency.
     */
    function proposeEmergencyShutdown(string calldata description) external whenNotPaused returns (uint256) {
        uint256 requiredRep = protocolParameters["emergencyShutdownThresholdReputation"];
        if (userReputation[_msgSender()] < requiredRep) {
            revert InsufficientReputation(requiredRep, userReputation[_msgSender()]);
        }

        uint256 currentProposalId = nextProposalId++;
        (uint256 minDur, ) = getDynamicVotingDuration(); // Use dynamic duration for shutdown vote

        proposals[currentProposalId] = Proposal({
            proposalId: currentProposalId,
            proposer: _msgSender(),
            description: description,
            submissionTimestamp: block.timestamp,
            votingStart: block.timestamp,
            votingEnd: block.timestamp.add(minDur),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            paramToAdjust: "", // N/A for emergency shutdown direct action
            newValue: 0,      // N/A
            isEmergencyShutdown: true
        });

        emit EmergencyShutdownProposed(currentProposalId, _msgSender());
        return currentProposalId;
    }

    /**
     * @dev Allows the DAO or designated administrators to create a bounty for specific tasks.
     * @param description A description of the bounty task.
     * @param rewardAmount The token amount to be rewarded.
     * @param reputationReward The reputation points to be rewarded.
     */
    function createProtocolBounty(
        string calldata description,
        uint256 rewardAmount,
        uint256 reputationReward
    ) external onlyOwner whenNotPaused returns (uint256) { // Can be extended to DAO only
        if (rewardAmount == 0 && reputationReward == 0) {
            revert InvalidParameters("Bounty must offer token or reputation reward.");
        }
        if (quantumLeapToken.balanceOf(address(this)) < rewardAmount) {
            revert InsufficientStake("Protocol has insufficient tokens for this bounty.", rewardAmount, quantumLeapToken.balanceOf(address(this)));
        }

        uint256 currentBountyId = nextBountyId++;
        bounties[currentBountyId] = Bounty({
            bountyId: currentBountyId,
            creator: _msgSender(),
            description: description,
            rewardAmount: rewardAmount,
            reputationReward: reputationReward,
            solutionSubmitter: address(0),
            solutionCID: "",
            evaluated: false,
            solutionAccepted: false,
            claimed: false,
            creationTimestamp: block.timestamp,
            evaluationTimestamp: 0
        });

        emit BountyCreated(currentBountyId, _msgSender(), rewardAmount, reputationReward);
        return currentBountyId;
    }

    /**
     * @dev Users submit their work or a link/CID (e.g., IPFS hash) to their solution for an open bounty.
     * @param bountyId The ID of the bounty.
     * @param solutionCID The IPFS CID or URL pointing to the solution.
     */
    function submitBountySolution(uint256 bountyId, string calldata solutionCID) external whenNotPaused {
        Bounty storage bounty = bounties[bountyId];
        if (bounty.bountyId == 0 && bountyId != 0) {
            revert BountyNotFound();
        }
        if (bounty.solutionSubmitter != address(0)) {
            revert SolutionAlreadySubmitted();
        }
        if (bytes(solutionCID).length == 0) {
            revert InvalidParameters("Solution CID cannot be empty.");
        }

        bounty.solutionSubmitter = _msgSender();
        bounty.solutionCID = solutionCID;
        
        emit BountySolutionSubmitted(bountyId, _msgSender(), solutionCID);
    }

    /**
     * @dev The DAO or designated reviewers evaluate submitted solutions. If accepted, the submitter is awarded tokens and reputation.
     * @param bountyId The ID of the bounty.
     * @param accepted True if the solution is accepted, false otherwise.
     */
    function evaluateBountySolution(uint256 bountyId, bool accepted) external onlyOwner whenNotPaused { // Can be extended to DAO reviewers
        Bounty storage bounty = bounties[bountyId];
        if (bounty.bountyId == 0 && bountyId != 0) {
            revert BountyNotFound();
        }
        if (bounty.solutionSubmitter == address(0)) {
            revert BountyStillOpen(); // No solution submitted yet
        }
        if (bounty.evaluated) {
            revert InvalidParameters("Bounty already evaluated.");
        }

        bounty.evaluated = true;
        bounty.solutionAccepted = accepted;
        bounty.evaluationTimestamp = block.timestamp;

        // If accepted, reputation is given. Tokens are claimed separately.
        if (accepted) {
            _adjustReputation(bounty.solutionSubmitter, bounty.reputationReward, true);
        }

        emit BountyEvaluated(bountyId, bounty.solutionSubmitter, accepted);
    }

    /**
     * @dev Enables successful bounty submitters to claim their token rewards after their solution has been evaluated and accepted.
     * @param bountyId The ID of the bounty.
     */
    function claimBountyReward(uint256 bountyId) external whenNotPaused {
        Bounty storage bounty = bounties[bountyId];
        if (bounty.bountyId == 0 && bountyId != 0) {
            revert BountyNotFound();
        }
        if (_msgSender() != bounty.solutionSubmitter) {
            revert NotAuthorized("Only the solution submitter can claim this bounty.");
        }
        if (!bounty.evaluated) {
            revert BountyNotYetEvaluated();
        }
        if (!bounty.solutionAccepted) {
            revert InvalidParameters("Bounty solution was not accepted.");
        }
        if (bounty.claimed) {
            revert BountyAlreadyClaimed();
        }

        bounty.claimed = true;
        if (bounty.rewardAmount > 0) {
            if (!quantumLeapToken.transfer(_msgSender(), bounty.rewardAmount)) {
                revert SelfAdjustmentFailed(); // Should not fail if balance check passed
            }
        }

        emit BountyClaimed(bountyId, _msgSender());
    }

    // --- Pausable functions (inherited from OpenZeppelin Pausable) ---
    /**
     * @dev Pauses the contract. Can only be called by the owner.
     *      Used for emergencies or upgrades.
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Can only be called by the owner.
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }
}
```