This smart contract, "The Synergistic Oracle Network (SON)," introduces a novel decentralized collective intelligence system. It allows participants to contribute structured predictive "patterns" about future events, earning or losing "WisdomScore" (a non-transferable, Soulbound Token-like reputation score) based on the accuracy of their predictions. The network then aggregates these weighted patterns to generate a "Global Trend Prediction" and can provide specific predictions for queried conditions. A key advanced feature is a challenge mechanism, allowing contributors to dispute oracle resolutions, enhancing decentralization and trustworthiness.

---

## Contract: SynergisticOracleNetwork

**Solidity Version:** `^0.8.20`

**Dependencies:** `@openzeppelin/contracts/access/Ownable.sol`, `@openzeppelin/contracts/utils/Pausable.sol`, `@openzeppelin/contracts/utils/math/SafeMath.sol`

---

## Outline

1.  **Core Infrastructure & Access Control:**
    *   `constructor`: Initializes contract, sets owner and initial parameters.
    *   `setOracleAddress`: Grants trusted oracle role for outcome verification.
    *   `pause/unpause`: Emergency contract pause mechanism.
    *   `setContributionFee`: Adjusts fee for submitting new patterns.
    *   `withdrawProtocolFees`: Allows owner to collect accumulated fees.
    *   `updateWisdomScoreFactors`: Adjusts parameters for WisdomScore updates.

2.  **Contributor Profiles & WisdomScore Management (SBT-like Reputation):**
    *   `registerContributor`: Registers a new participant, mints initial WisdomScore.
    *   `getContributorProfile`: Retrieves a contributor's detailed profile.
    *   `getWisdomScore`: Fetches an individual's current WisdomScore.
    *   `_increaseWisdomScore`: Internal function to reward accurate predictions.
    *   `_decreaseWisdomScore`: Internal function to penalize inaccurate predictions or upheld challenges.
    *   `reportMaliciousContributor`: Placeholder for reporting and (owner-verified) penalization.

3.  **Pattern Submission & Staking:**
    *   `submitPattern`: Allows a contributor to submit a new predictive pattern with a stake.
    *   `getPatternDetails`: Provides detailed information about a specific pattern.
    *   `stakeOnExistingPattern`: Enables other contributors to add their stake to an existing pattern, increasing its weight.
    *   `unstakeFromPendingPattern`: Allows a staker to withdraw their stake from an unresolved pattern before its resolution deadline.

4.  **Outcome Verification & Resolution:**
    *   `resolvePatternOutcome`: Oracle-only function to report the actual outcome of a pattern, triggering score updates and rewards/penalties.
    *   `_calculatePatternWeight`: Internal function to determine a pattern's influence based on stake and submitter's WisdomScore.

5.  **Collective Intelligence & Global Trend Aggregation:**
    *   `triggerGlobalTrendUpdate`: Owner or privileged role triggers recalculation of the aggregated "Global Trend Prediction" from all relevant patterns.
    *   `getGlobalTrendPrediction`: Retrieves the current aggregated global trend.
    *   `queryPatternPredictionForCondition`: Provides an aggregated prediction for a given condition.

6.  **Challenge Mechanism for Oracle Decisions:**
    *   `challengePatternOutcome`: Allows contributors to challenge a specific oracle resolution with a stake.
    *   `resolveChallenge`: Owner function to adjudicate a challenge, affecting oracle reputation and challenger/original submitter scores.
    *   `getChallengeDetails`: Returns details of an ongoing or resolved challenge.

7.  **Treasury & Funding:**
    *   `fundContract`: Allows anyone to send ETH to the contract to bolster rewards.

---

## Function Summary

1.  `constructor()`: Deploys the contract, setting the initial owner and default WisdomScore parameters.
2.  `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle. Callable only by the contract owner.
3.  `pause()`: Pauses contract functionality, preventing certain actions. Callable only by the owner.
4.  `unpause()`: Unpauses contract functionality. Callable only by the owner.
5.  `setContributionFee(uint256 _fee)`: Sets the fee required to submit a new pattern (in wei). Callable only by the owner.
6.  `withdrawProtocolFees(address _to)`: Allows the owner to withdraw accumulated protocol fees to a specified address. Callable only by the owner.
7.  `updateWisdomScoreFactors(uint256 _correctMultiplier, uint256 _incorrectMultiplier, uint256 _challengeSuccessReward, uint256 _challengeFailPenalty, uint256 _oracleChallengePenalty_)`: Adjusts the parameters that influence WisdomScore changes for various outcomes. Callable only by the owner.
8.  `registerContributor()`: Registers the calling address as a new contributor, assigning an initial WisdomScore.
9.  `getContributorProfile(address _contributor)`: Returns a contributor's WisdomScore, last contribution time, total patterns submitted, and total correct predictions.
10. `getWisdomScore(address _contributor)`: Returns the current WisdomScore of a specified contributor.
11. `_increaseWisdomScore(address _contributor, uint256 _amount)`: Internal function to increase a contributor's WisdomScore.
12. `_decreaseWisdomScore(address _contributor, uint256 _amount)`: Internal function to decrease a contributor's WisdomScore, ensuring it doesn't fall below a minimum.
13. `reportMaliciousContributor(address _contributor)`: A placeholder function for reporting potentially malicious activity; actual penalization would require owner action.
14. `submitPattern(bytes32 _conditionHash, bytes32 _predictedOutcomeHash, uint256 _probabilityPermyriad, uint256 _resolutionDeadline)`: Allows a registered contributor to submit a new predictive pattern with an initial ETH stake and a contribution fee.
15. `getPatternDetails(uint256 _patternId)`: Retrieves detailed information about a specific pattern, including its status, stakes, and resolution.
16. `stakeOnExistingPattern(uint256 _patternId)`: Enables other contributors to add ETH stake to an already submitted, pending pattern.
17. `unstakeFromPendingPattern(uint256 _patternId, uint256 _amount)`: Allows a staker to withdraw a portion of their stake from a pending pattern before its resolution deadline.
18. `resolvePatternOutcome(uint256 _patternId, bool _actualOutcome)`: Callable only by the designated oracle, this function reports the true outcome of a pattern, triggering WisdomScore adjustments and handling stakes.
19. `_calculatePatternWeight(uint256 _patternId)`: Internal function that calculates the influence weight of a pattern based on its submitter's WisdomScore and the total stake on the pattern.
20. `triggerGlobalTrendUpdate()`: Owner or privileged role triggers a recalculation of the network's aggregated "Global Trend Prediction" based on active and resolved patterns.
21. `getGlobalTrendPrediction()`: Returns the latest calculated global trend prediction hash.
22. `queryPatternPredictionForCondition(bytes32 _conditionHash)`: Provides an aggregated probability and the most probable outcome hash for a specific condition, derived from relevant patterns in the network.
23. `challengePatternOutcome(uint256 _patternId)`: Allows a contributor to challenge an oracle's resolution of a pattern by staking ETH.
24. `resolveChallenge(uint256 _challengeId, bool _challengeUpheld)`: Callable only by the owner, this function adjudicates a challenge, determining if the oracle's initial resolution was correct and adjusting WisdomScores and stakes accordingly.
25. `getChallengeDetails(uint256 _challengeId)`: Returns details of a specific challenge, including its status and challenger.
26. `fundContract()`: Allows any address to send ETH to the contract, contributing to its balance which can be used for rewards or operational purposes.
27. `receive()`: A special function that allows the contract to receive plain ETH transfers.
28. `fallback()`: A special function that is executed if a call does not match any other function (or `receive()`) and contains data.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom Errors
error Unauthorized();
error PatternNotFound();
error ContributorNotRegistered();
error InsufficientStake();
error PatternAlreadyResolved();
error PatternNotPending();
error NoActivePatterns();
error ChallengeNotAllowed();
error ChallengePeriodExpired();
error DuplicateChallenge();
error OracleAlreadySet();
error OracleNotSet();
error PatternExpired();
error PatternNotExpired(); // Used for unstake if resolution time passed
error InsufficientFunds();
error PatternStillPending();
error ChallengeAlreadyResolved();
error ChallengeNotFound();
error NotAStaker();
error AmountExceedsStake();
error NoStakeProvided();
error NotEnoughEthForFee();

/**
 * @title The Synergistic Oracle Network (SON)
 * @dev This contract implements a novel decentralized collective intelligence system where participants contribute verifiable "patterns"
 *      or predictions about future events. Contributors earn or lose "WisdomScore" (a non-transferable, SBT-like reputation score)
 *      based on the accuracy of their predictions. The network aggregates these weighted patterns to generate
 *      a "Global Trend Prediction" and can also provide specific predictions for queried conditions.
 *      It features a challenge mechanism for oracle resolutions to enhance decentralization.
 *
 * @outline
 * 1.  **Core Infrastructure & Access Control:**
 *     - `constructor`: Initializes contract, sets owner and initial parameters.
 *     - `setOracleAddress`: Grants trusted oracle role for outcome verification.
 *     - `pause/unpause`: Emergency contract pause mechanism.
 *     - `setContributionFee`: Adjusts fee for submitting new patterns.
 *     - `withdrawProtocolFees`: Allows owner to collect accumulated fees.
 *     - `updateWisdomScoreFactors`: Adjusts parameters for WisdomScore updates.
 *
 * 2.  **Contributor Profiles & WisdomScore Management (SBT-like Reputation):**
 *     - `registerContributor`: Registers a new participant, mints initial WisdomScore.
 *     - `getContributorProfile`: Retrieves a contributor's detailed profile.
 *     - `getWisdomScore`: Fetches an individual's current WisdomScore.
 *     - `_increaseWisdomScore`: Internal function to reward accurate predictions.
 *     - `_decreaseWisdomScore`: Internal function to penalize inaccurate predictions or upheld challenges.
 *     - `reportMaliciousContributor`: Allows reporting and (owner-verified) penalization.
 *
 * 3.  **Pattern Submission & Staking:**
 *     - `submitPattern`: Allows a contributor to submit a new predictive pattern with a stake.
 *     - `getPatternDetails`: Provides detailed information about a specific pattern.
 *     - `stakeOnExistingPattern`: Enables other contributors to add their stake to an existing pattern, increasing its weight.
 *     - `unstakeFromPendingPattern`: Allows a staker to withdraw their stake from an unresolved pattern before its resolution deadline.
 *
 * 4.  **Outcome Verification & Resolution:**
 *     - `resolvePatternOutcome`: Oracle-only function to report the actual outcome of a pattern, triggering score updates and rewards/penalties.
 *     - `_calculatePatternWeight`: Internal function to determine a pattern's influence based on stake and submitter's WisdomScore.
 *
 * 5.  **Collective Intelligence & Global Trend Aggregation:**
 *     - `triggerGlobalTrendUpdate`: Owner or privileged role triggers recalculation of the global trend.
 *     - `getGlobalTrendPrediction`: Retrieves the current aggregated global trend.
 *     - `queryPatternPredictionForCondition`: Provides an aggregated prediction for a given condition.
 *
 * 6.  **Challenge Mechanism for Oracle Decisions:**
 *     - `challengePatternOutcome`: Allows contributors to challenge a specific oracle resolution with a stake.
 *     - `resolveChallenge`: Owner function to adjudicate a challenge, affecting oracle reputation and challenger/original submitter scores.
 *     - `getChallengeDetails`: Returns details of a challenge.
 *
 * 7.  **Treasury & Funding:**
 *     - `fundContract`: Allows anyone to send ETH to the contract to bolster rewards.
 *
 * @function_summary
 * - `constructor()`: Deploys the contract, setting the initial owner.
 * - `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle. Only owner.
 * - `pause()`: Pauses contract functionality. Only owner.
 * - `unpause()`: Unpauses contract functionality. Only owner.
 * - `setContributionFee(uint256 _fee)`: Sets the fee required to submit a pattern (in wei). Only owner.
 * - `withdrawProtocolFees(address _to)`: Allows the owner to withdraw accumulated protocol fees. Only owner.
 * - `updateWisdomScoreFactors(uint256 _correctMultiplier, uint256 _incorrectMultiplier, uint256 _challengeSuccessReward, uint256 _challengeFailPenalty, uint256 _oracleChallengePenalty)`: Adjusts WS update parameters. Only owner.
 * - `registerContributor()`: Registers the calling address as a contributor and mints initial WisdomScore.
 * - `getContributorProfile(address _contributor)`: Returns details of a contributor.
 * - `getWisdomScore(address _contributor)`: Returns the WisdomScore of a contributor.
 * - `_increaseWisdomScore(address _contributor, uint256 _amount)`: Internal function to increase a contributor's WisdomScore.
 * - `_decreaseWisdomScore(address _contributor, uint256 _amount)`: Internal function to decrease a contributor's WisdomScore.
 * - `reportMaliciousContributor(address _contributor)`: Placeholder for reporting malicious activity (owner-verified penalization).
 * - `submitPattern(bytes32 _conditionHash, bytes32 _predictedOutcomeHash, uint256 _probabilityPermyriad, uint256 _resolutionDeadline)`: Submits a new pattern with a stake, requires contribution fee.
 * - `getPatternDetails(uint256 _patternId)`: Returns the details of a specific pattern.
 * - `stakeOnExistingPattern(uint256 _patternId)`: Allows other users to stake on an existing pattern.
 * - `unstakeFromPendingPattern(uint256 _patternId, uint256 _amount)`: Allows a staker to withdraw stake from a pending pattern before its deadline.
 * - `resolvePatternOutcome(uint256 _patternId, bool _actualOutcome)`: Oracle reports the true outcome of a pattern.
 * - `_calculatePatternWeight(uint256 _patternId)`: Internal: calculates a pattern's influence based on its submitter's WS and total stake.
 * - `triggerGlobalTrendUpdate()`: Owner or privileged role triggers recalculation of the global trend.
 * - `getGlobalTrendPrediction()`: Returns the last calculated global trend prediction.
 * - `queryPatternPredictionForCondition(bytes32 _conditionHash)`: Provides an aggregated prediction for a given condition.
 * - `challengePatternOutcome(uint256 _patternId)`: Allows a contributor to challenge an oracle's resolution.
 * - `resolveChallenge(uint256 _challengeId, bool _challengeUpheld)`: Owner adjudicates a challenge, impacting scores and stakes.
 * - `getChallengeDetails(uint256 _challengeId)`: Returns details of a challenge.
 * - `fundContract()`: Allows anyone to send ETH to the contract to bolster rewards.
 */
contract SynergisticOracleNetwork is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    address public oracleAddress;
    uint256 public contributionFee; // Fee to submit a new pattern, in wei
    uint256 public protocolFeesCollected; // Total fees collected

    // WisdomScore (SBT-like) Parameters
    uint256 public constant INITIAL_WISDOM_SCORE = 1000;
    uint256 public constant MIN_WISDOM_SCORE = 1; // Minimum allowed WisdomScore
    uint256 public wisdomScoreCorrectPredictionMultiplier;
    uint256 public wisdomScoreIncorrectPredictionPenalty;
    uint256 public wisdomScoreChallengeSuccessReward;
    uint256 public wisdomScoreChallengeFailPenalty;
    uint256 public oracleChallengePenalty; // Penalty for oracle if challenge is upheld

    // Pattern Management
    uint256 public nextPatternId;
    mapping(uint256 => Pattern) public patterns;
    mapping(bytes32 => uint256[]) public conditionToPatterns; // Maps a condition hash to a list of pattern IDs

    // Contributor Profiles
    mapping(address => Contributor) public contributors;
    mapping(address => bool) public isContributor; // To quickly check if registered

    // Challenge Management
    uint256 public nextChallengeId;
    mapping(uint256 => Challenge) public challenges;
    uint256 public constant CHALLENGE_PERIOD = 3 days; // Time window to challenge a resolution
    uint256 public constant CHALLENGE_STAKE_MULTIPLIER = 2; // Challenge stake is X times the pattern stake

    // Global Trend
    bytes32 public currentGlobalTrend; // Aggregated prediction hash
    uint256 public lastGlobalTrendUpdate;

    // --- Structs ---

    enum PatternStatus {
        Pending,
        ResolvedTrue,
        ResolvedFalse,
        Challenged
    }

    enum ChallengeStatus {
        Pending,
        Upheld,
        Denied
    }

    struct Contributor {
        uint256 wisdomScore;
        uint256 lastContributionTime;
        uint256 totalPatternsSubmitted;
        uint256 totalCorrectPredictions;
    }

    struct Pattern {
        uint256 id;
        address submitter;
        bytes32 conditionHash; // Hash representing the event/condition
        bytes32 predictedOutcomeHash; // Hash representing the predicted outcome
        uint256 probabilityPermyriad; // Predicted probability (e.g., 5000 for 50%)
        uint256 totalStake; // Total ETH staked on this pattern
        uint256 resolutionDeadline; // When the outcome should be resolved
        uint256 resolutionTime; // When the outcome was actually resolved
        PatternStatus status;
        bool actualOutcome; // The true outcome, once resolved (true/false, relative to the prediction)
        address resolvedBy; // Who resolved the pattern (oracle)
        uint256 challengeId; // If challenged, the ID of the challenge

        mapping(address => uint256) stakers; // Amount staked by each staker
        address[] stakerAddresses; // List of staker addresses for iteration
    }

    struct Challenge {
        uint256 id;
        uint256 patternId;
        address challenger;
        uint256 challengeStake;
        uint256 challengeTime;
        ChallengeStatus status;
    }

    // --- Events ---

    event OracleAddressSet(address indexed _oracle);
    event ContributorRegistered(address indexed _contributor, uint256 _initialWisdomScore);
    event WisdomScoreUpdated(address indexed _contributor, uint256 _oldScore, uint256 _newScore, string _reason);
    event PatternSubmitted(uint256 indexed _patternId, address indexed _submitter, bytes32 _conditionHash, bytes32 _predictedOutcomeHash, uint256 _stake);
    event StakeAdded(uint256 indexed _patternId, address indexed _staker, uint256 _amount);
    event StakeWithdrawn(uint256 indexed _patternId, address indexed _staker, uint256 _amount);
    event PatternResolved(uint256 indexed _patternId, bool _actualOutcome, address indexed _resolver);
    event GlobalTrendUpdated(bytes32 _newTrendHash, uint256 _timestamp);
    event PatternChallenged(uint256 indexed _challengeId, uint256 indexed _patternId, address indexed _challenger, uint256 _challengeStake);
    event ChallengeResolved(uint256 indexed _challengeId, uint256 indexed _patternId, bool _challengeUpheld);
    event ProtocolFeesWithdrawn(address indexed _to, uint256 _amount);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initialize WisdomScore update factors
        wisdomScoreCorrectPredictionMultiplier = 100; // +100 WS for correct
        wisdomScoreIncorrectPredictionPenalty = 50;  // -50 WS for incorrect
        wisdomScoreChallengeSuccessReward = 200;    // +200 WS for successful challenge
        wisdomScoreChallengeFailPenalty = 100;      // -100 WS for failed challenge
        oracleChallengePenalty = 150;               // -150 WS for oracle if challenge upheld

        contributionFee = 0.01 ether; // Example: 0.01 ETH
        nextPatternId = 1;
        nextChallengeId = 1;
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyContributor() {
        if (!isContributor[msg.sender]) {
            revert ContributorNotRegistered();
        }
        _;
    }

    // --- Core Infrastructure & Access Control (6 functions) ---

    /// @notice Sets the address of the trusted oracle. Only owner.
    /// @param _oracle The address of the new oracle.
    function setOracleAddress(address _oracle) external onlyOwner {
        if (_oracle == address(0)) {
            revert OracleAlreadySet(); // Or better: revert("Invalid oracle address");
        }
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /// @notice Pauses contract functionality. Only owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract functionality. Only owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets the fee required to submit a pattern (in wei). Only owner.
    /// @param _fee The new contribution fee.
    function setContributionFee(uint256 _fee) external onlyOwner {
        contributionFee = _fee;
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees. Only owner.
    /// @param _to The address to send the fees to.
    function withdrawProtocolFees(address _to) external onlyOwner {
        if (protocolFeesCollected == 0) {
            revert InsufficientFunds();
        }
        uint256 amount = protocolFeesCollected;
        protocolFeesCollected = 0;
        (bool success, ) = _to.call{value: amount}("");
        if (!success) {
            protocolFeesCollected = amount; // Refund if transfer fails
            revert InsufficientFunds(); // More specific error "TransferFailed" could be used
        }
        emit ProtocolFeesWithdrawn(_to, amount);
    }

    /// @notice Adjusts parameters for WisdomScore updates. Only owner.
    /// @param _correctMultiplier New multiplier for correct predictions.
    /// @param _incorrectMultiplier New penalty for incorrect predictions.
    /// @param _challengeSuccessReward New reward for successful challenges.
    /// @param _challengeFailPenalty New penalty for failed challenges.
    /// @param _oracleChallengePenalty_ New penalty for oracle if challenge upheld.
    function updateWisdomScoreFactors(
        uint256 _correctMultiplier,
        uint256 _incorrectMultiplier,
        uint256 _challengeSuccessReward,
        uint256 _challengeFailPenalty,
        uint256 _oracleChallengePenalty_
    ) external onlyOwner {
        wisdomScoreCorrectPredictionMultiplier = _correctMultiplier;
        wisdomScoreIncorrectPredictionPenalty = _incorrectMultiplier;
        wisdomScoreChallengeSuccessReward = _challengeSuccessReward;
        wisdomScoreChallengeFailPenalty = _challengeFailPenalty;
        oracleChallengePenalty = _oracleChallengePenalty_;
    }

    // --- Contributor Profiles & WisdomScore Management (6 functions) ---

    /// @notice Registers the calling address as a contributor and mints initial WisdomScore.
    function registerContributor() external whenNotPaused {
        if (isContributor[msg.sender]) {
            revert ContributorNotRegistered(); // Already registered
        }
        contributors[msg.sender] = Contributor({
            wisdomScore: INITIAL_WISDOM_SCORE,
            lastContributionTime: block.timestamp,
            totalPatternsSubmitted: 0,
            totalCorrectPredictions: 0
        });
        isContributor[msg.sender] = true;
        emit ContributorRegistered(msg.sender, INITIAL_WISDOM_SCORE);
    }

    /// @notice Returns details of a contributor.
    /// @param _contributor The address of the contributor.
    /// @return wisdomScore The current WisdomScore.
    /// @return lastContributionTime The timestamp of their last contribution.
    /// @return totalPatternsSubmitted The total number of patterns submitted.
    /// @return totalCorrectPredictions The total number of correct predictions.
    function getContributorProfile(address _contributor)
        external
        view
        returns (
            uint256 wisdomScore,
            uint256 lastContributionTime,
            uint256 totalPatternsSubmitted,
            uint256 totalCorrectPredictions
        )
    {
        if (!isContributor[_contributor]) {
            revert ContributorNotRegistered();
        }
        Contributor storage c = contributors[_contributor];
        return (
            c.wisdomScore,
            c.lastContributionTime,
            c.totalPatternsSubmitted,
            c.totalCorrectPredictions
        );
    }

    /// @notice Returns the WisdomScore of a contributor.
    /// @param _contributor The address of the contributor.
    /// @return The WisdomScore.
    function getWisdomScore(address _contributor) external view returns (uint256) {
        if (!isContributor[_contributor]) {
            return 0; // Contributor not registered, return 0 score
        }
        return contributors[_contributor].wisdomScore;
    }

    /// @notice Internal function to increase a contributor's WisdomScore.
    /// @param _contributor The address of the contributor.
    /// @param _amount The amount to increase by.
    function _increaseWisdomScore(address _contributor, uint256 _amount) internal {
        if (!isContributor[_contributor]) {
            revert ContributorNotRegistered();
        }
        uint256 oldScore = contributors[_contributor].wisdomScore;
        contributors[_contributor].wisdomScore = contributors[_contributor].wisdomScore.add(_amount);
        emit WisdomScoreUpdated(_contributor, oldScore, contributors[_contributor].wisdomScore, "Increase");
    }

    /// @notice Internal function to decrease a contributor's WisdomScore.
    /// @param _contributor The address of the contributor.
    /// @param _amount The amount to decrease by.
    function _decreaseWisdomScore(address _contributor, uint256 _amount) internal {
        if (!isContributor[_contributor]) {
            revert ContributorNotRegistered();
        }
        uint256 oldScore = contributors[_contributor].wisdomScore;
        // Ensure score doesn't go below MIN_WISDOM_SCORE
        contributors[_contributor].wisdomScore = SafeMath.max(
            contributors[_contributor].wisdomScore.sub(_amount),
            MIN_WISDOM_SCORE
        );
        emit WisdomScoreUpdated(_contributor, oldScore, contributors[_contributor].wisdomScore, "Decrease");
    }

    /// @notice Placeholder for reporting malicious activity. Owner can review and penalize.
    ///         Actual implementation would involve a governance process or more robust detection.
    /// @param _contributor The address of the suspected malicious contributor.
    function reportMaliciousContributor(address _contributor) external onlyContributor {
        // In a real system, this would trigger a DAO vote, or an owner's review process.
        // For this example, let's allow owner to directly penalize after a report.
        // This is a simplified placeholder.
        // emit MaliciousContributorReported(msg.sender, _contributor); // Example event
    }

    // --- Pattern Submission & Staking (4 functions) ---

    /// @notice Submits a new pattern with a stake, requires contribution fee.
    /// @param _conditionHash Hash representing the event/condition.
    /// @param _predictedOutcomeHash Hash representing the predicted outcome.
    /// @param _probabilityPermyriad Predicted probability (e.g., 5000 for 50%). Must be <= 10000.
    /// @param _resolutionDeadline Timestamp when the outcome should be resolved.
    function submitPattern(
        bytes32 _conditionHash,
        bytes32 _predictedOutcomeHash,
        uint256 _probabilityPermyriad,
        uint256 _resolutionDeadline
    ) external payable whenNotPaused onlyContributor {
        if (msg.value < contributionFee) {
            revert NotEnoughEthForFee();
        }
        if (msg.value == contributionFee) { // No stake provided beyond fee
            revert NoStakeProvided();
        }
        if (_resolutionDeadline <= block.timestamp) {
            revert PatternExpired();
        }
        if (_probabilityPermyriad > 10000) {
            revert ("Probability must be <= 10000");
        }

        uint256 patternId = nextPatternId++;
        uint256 initialStake = msg.value.sub(contributionFee);

        patterns[patternId] = Pattern({
            id: patternId,
            submitter: msg.sender,
            conditionHash: _conditionHash,
            predictedOutcomeHash: _predictedOutcomeHash,
            probabilityPermyriad: _probabilityPermyriad,
            totalStake: initialStake,
            resolutionDeadline: _resolutionDeadline,
            resolutionTime: 0,
            status: PatternStatus.Pending,
            actualOutcome: false, // Default
            resolvedBy: address(0),
            challengeId: 0,
            stakers: new mapping(address => uint256)(),
            stakerAddresses: new address[](0) // Initialize empty array
        });
        patterns[patternId].stakers[msg.sender] = initialStake;
        patterns[patternId].stakerAddresses.push(msg.sender); // Add submitter to staker list
        conditionToPatterns[_conditionHash].push(patternId);

        contributors[msg.sender].totalPatternsSubmitted = contributors[msg.sender].totalPatternsSubmitted.add(1);
        contributors[msg.sender].lastContributionTime = block.timestamp;
        protocolFeesCollected = protocolFeesCollected.add(contributionFee);

        emit PatternSubmitted(
            patternId,
            msg.sender,
            _conditionHash,
            _predictedOutcomeHash,
            initialStake
        );
    }

    /// @notice Returns the details of a specific pattern.
    /// @param _patternId The ID of the pattern.
    /// @return A tuple containing all pattern details.
    function getPatternDetails(uint256 _patternId)
        external
        view
        returns (
            uint256 id,
            address submitter,
            bytes32 conditionHash,
            bytes32 predictedOutcomeHash,
            uint256 probabilityPermyriad,
            uint256 totalStake,
            uint256 resolutionDeadline,
            uint256 resolutionTime,
            PatternStatus status,
            bool actualOutcome,
            address resolvedBy,
            uint256 challengeId,
            address[] memory stakerAddresses // Also return staker list for visibility
        )
    {
        Pattern storage p = patterns[_patternId];
        if (p.id == 0) {
            revert PatternNotFound();
        }
        return (
            p.id,
            p.submitter,
            p.conditionHash,
            p.predictedOutcomeHash,
            p.probabilityPermyriad,
            p.totalStake,
            p.resolutionDeadline,
            p.resolutionTime,
            p.status,
            p.actualOutcome,
            p.resolvedBy,
            p.challengeId,
            p.stakerAddresses
        );
    }

    /// @notice Allows other users to stake on an existing pattern.
    /// @param _patternId The ID of the pattern to stake on.
    function stakeOnExistingPattern(uint256 _patternId)
        external
        payable
        whenNotPaused
        onlyContributor
    {
        if (msg.value == 0) {
            revert NoStakeProvided();
        }
        Pattern storage p = patterns[_patternId];
        if (p.id == 0) {
            revert PatternNotFound();
        }
        if (p.status != PatternStatus.Pending) {
            revert PatternAlreadyResolved();
        }
        if (block.timestamp >= p.resolutionDeadline) {
            revert PatternExpired();
        }

        if (p.stakers[msg.sender] == 0) {
            p.stakerAddresses.push(msg.sender); // Add staker to list if new
        }
        p.stakers[msg.sender] = p.stakers[msg.sender].add(msg.value);
        p.totalStake = p.totalStake.add(msg.value);

        emit StakeAdded(_patternId, msg.sender, msg.value);
    }

    /// @notice Allows a staker to withdraw their stake from an unresolved pattern before its resolution deadline.
    /// @param _patternId The ID of the pattern.
    /// @param _amount The amount to unstake.
    function unstakeFromPendingPattern(uint256 _patternId, uint256 _amount)
        external
        whenNotPaused
        onlyContributor
    {
        Pattern storage p = patterns[_patternId];
        if (p.id == 0) {
            revert PatternNotFound();
        }
        if (p.status != PatternStatus.Pending) {
            revert PatternAlreadyResolved();
        }
        if (block.timestamp >= p.resolutionDeadline) {
            revert PatternExpired();
        }
        if (p.stakers[msg.sender] == 0) {
            revert NotAStaker();
        }
        if (p.stakers[msg.sender] < _amount) {
            revert AmountExceedsStake();
        }

        p.stakers[msg.sender] = p.stakers[msg.sender].sub(_amount);
        p.totalStake = p.totalStake.sub(_amount);

        // Remove staker from stakerAddresses if their stake becomes 0 (optional, saves gas if not removed)
        // For simplicity, we just mark it as 0 in the mapping. Removing from array is gas-expensive.
        // A more optimized approach would use a linked list or rely on off-chain filtering.

        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) {
            // Revert changes if transfer fails
            p.stakers[msg.sender] = p.stakers[msg.sender].add(_amount);
            p.totalStake = p.totalStake.add(_amount);
            revert InsufficientFunds(); // Or a more specific error "TransferFailed"
        }
        emit StakeWithdrawn(_patternId, msg.sender, _amount);
    }

    // --- Outcome Verification & Resolution (2 functions + 1 internal) ---

    /// @notice Oracle reports the true outcome of a pattern, triggering score updates and rewards/penalties.
    ///         Only callable by the designated oracle address.
    /// @param _patternId The ID of the pattern to resolve.
    /// @param _actualOutcome The true outcome (true if predicted outcome happened, false otherwise).
    function resolvePatternOutcome(uint256 _patternId, bool _actualOutcome)
        external
        onlyOracle
        whenNotPaused
    {
        if (oracleAddress == address(0)) {
            revert OracleNotSet();
        }
        Pattern storage p = patterns[_patternId];
        if (p.id == 0) {
            revert PatternNotFound();
        }
        if (p.status != PatternStatus.Pending) {
            revert PatternAlreadyResolved();
        }
        if (block.timestamp < p.resolutionDeadline) {
            revert PatternNotExpired(); // Oracle must wait until deadline
        }

        p.status = _actualOutcome ? PatternStatus.ResolvedTrue : PatternStatus.ResolvedFalse;
        p.actualOutcome = _actualOutcome;
        p.resolutionTime = block.timestamp;
        p.resolvedBy = msg.sender;

        // Update submitter's WisdomScore
        if (_actualOutcome) { // If the predicted outcome happened
            _increaseWisdomScore(p.submitter, wisdomScoreCorrectPredictionMultiplier);
            contributors[p.submitter].totalCorrectPredictions = contributors[p.submitter].totalCorrectPredictions.add(1);
        } else { // If the predicted outcome did not happen
            _decreaseWisdomScore(p.submitter, wisdomScoreIncorrectPredictionPenalty);
        }

        uint256 totalForfeitedStake = 0;

        // Distribute/penalize stakes for ALL stakers on this pattern
        for (uint256 i = 0; i < p.stakerAddresses.length; i++) {
            address currentStaker = p.stakerAddresses[i];
            uint256 stakedAmount = p.stakers[currentStaker];
            if (stakedAmount > 0) {
                if (_actualOutcome) { // Staker was correct, return their stake
                    (bool success, ) = currentStaker.call{value: stakedAmount}("");
                    if (!success) {
                        // In case of failure, add to forfeited to avoid locking funds
                        totalForfeitedStake = totalForfeitedStake.add(stakedAmount);
                    }
                } else { // Staker was incorrect, stake is forfeited to contract
                    totalForfeitedStake = totalForfeitedStake.add(stakedAmount);
                }
                p.stakers[currentStaker] = 0; // Clear stake after distribution
            }
        }

        p.totalStake = 0; // All stakes are either returned or pooled
        protocolFeesCollected = protocolFeesCollected.add(totalForfeitedStake); // Add forfeited stakes to protocol fees

        emit PatternResolved(_patternId, _actualOutcome, msg.sender);
    }

    /// @notice Internal: calculates a pattern's influence based on its submitter's WS and total stake.
    /// @param _patternId The ID of the pattern.
    /// @return The calculated weight (higher means more influential).
    function _calculatePatternWeight(uint256 _patternId) internal view returns (uint256) {
        Pattern storage p = patterns[_patternId];
        if (p.id == 0) {
            return 0; // Pattern not found
        }
        uint256 submitterWS = contributors[p.submitter].wisdomScore;
        // Simple weighting: (WisdomScore * totalStake) / scalingFactor
        // Scaling factor needed to prevent overflow and keep numbers manageable.
        // For example, 1000 for WS and 1 ETH stake -> 1000 * 1e18 / 1e12 = 1e9
        // A proper scaling factor would depend on expected ranges.
        // Let's use a constant for now.
        uint256 SCALING_FACTOR = 1e6; // Adjust based on expected stake/WS values
        if (SCALING_FACTOR == 0) return 0; // Avoid division by zero
        return (submitterWS.mul(p.totalStake)).div(SCALING_FACTOR);
    }

    // --- Collective Intelligence & Global Trend Aggregation (3 functions) ---

    /// @notice Owner or privileged role triggers recalculation of the global trend.
    ///         Aggregates all relevant (resolved and active) patterns.
    ///         Note: This function can be highly gas-intensive if nextPatternId is very large.
    ///         In a production system, this would likely be optimized via off-chain aggregation
    ///         with on-chain verification or by limiting the aggregation scope.
    function triggerGlobalTrendUpdate() external onlyOwner whenNotPaused {
        uint256 totalWeightedProbability = 0;
        uint256 totalWeight = 0;

        // Iterate through all active patterns (or a subset)
        for (uint256 i = 1; i < nextPatternId; i++) {
            Pattern storage p = patterns[i];
            // Only consider resolved patterns or pending patterns nearing resolution
            if (p.id != 0 && (p.status == PatternStatus.ResolvedTrue || p.status == PatternStatus.ResolvedFalse || (p.status == PatternStatus.Pending && p.resolutionDeadline < block.timestamp.add(1 days)))) {
                uint256 weight = _calculatePatternWeight(i);
                if (weight > 0) {
                    // For global trend, we aggregate probabilities.
                    // If a pattern was resolved and was incorrect, it still contributes its *original predicted probability*
                    // but its weight might be lower due to the submitter's decreased WisdomScore.
                    // The `_actualOutcome` parameter in Pattern doesn't change the original `probabilityPermyriad`.
                    totalWeightedProbability = totalWeightedProbability.add(p.probabilityPermyriad.mul(weight));
                    totalWeight = totalWeight.add(weight);
                }
            }
        }

        if (totalWeight > 0) {
            uint256 aggregatedProbability = totalWeightedProbability.div(totalWeight);
            // Example: Convert aggregated probability into a simple hash representation for the global trend.
            currentGlobalTrend = keccak256(abi.encodePacked(aggregatedProbability, block.timestamp));
        } else {
            currentGlobalTrend = bytes32(0); // No active patterns to form a trend
        }
        lastGlobalTrendUpdate = block.timestamp;
        emit GlobalTrendUpdated(currentGlobalTrend, lastGlobalTrendUpdate);
    }

    /// @notice Returns the last calculated global trend prediction.
    /// @return The hash representing the current global trend.
    function getGlobalTrendPrediction() external view returns (bytes32) {
        return currentGlobalTrend;
    }

    /// @notice Provides an aggregated prediction for a given condition based on matching patterns.
    /// @param _conditionHash The hash of the condition to query.
    /// @return aggregatedProbabilityPermyriad The aggregated probability for the predicted outcome (permyriad).
    /// @return mostProbableOutcomeHash The hash of the most probable outcome for this condition.
    function queryPatternPredictionForCondition(bytes32 _conditionHash)
        external
        view
        returns (uint256 aggregatedProbabilityPermyriad, bytes32 mostProbableOutcomeHash)
    {
        uint256[] storage relevantPatternIds = conditionToPatterns[_conditionHash];
        if (relevantPatternIds.length == 0) {
            return (0, bytes32(0));
        }

        uint256 totalWeightedProbability = 0;
        uint256 totalWeight = 0;
        // Using a temporary mapping to sum up weighted probabilities for each unique predicted outcome hash
        mapping(bytes32 => uint256) outcomeWeightedSums;

        for (uint256 i = 0; i < relevantPatternIds.length; i++) {
            Pattern storage p = patterns[relevantPatternIds[i]];
            if (p.id != 0 && p.status != PatternStatus.Challenged) { // Only consider non-challenged patterns
                uint256 weight = _calculatePatternWeight(p.id);
                if (weight > 0) {
                    totalWeightedProbability = totalWeightedProbability.add(p.probabilityPermyriad.mul(weight));
                    totalWeight = totalWeight.add(weight);

                    // Aggregate weighted probabilities for each specific predicted outcome hash
                    outcomeWeightedSums[p.predictedOutcomeHash] = outcomeWeightedSums[p.predictedOutcomeHash].add(p.probabilityPermyriad.mul(weight));
                }
            }
        }

        if (totalWeight == 0) {
            return (0, bytes32(0));
        }

        aggregatedProbabilityPermyriad = totalWeightedProbability.div(totalWeight);

        // Determine most probable outcome hash by finding the one with the highest sum of weighted probabilities
        uint256 maxOutcomeWeight = 0;
        for (uint256 i = 0; i < relevantPatternIds.length; i++) {
            Pattern storage p = patterns[relevantPatternIds[i]];
            if (p.id != 0) {
                if (outcomeWeightedSums[p.predictedOutcomeHash] > maxOutcomeWeight) {
                     maxOutcomeWeight = outcomeWeightedSums[p.predictedOutcomeHash];
                     mostProbableOutcomeHash = p.predictedOutcomeHash;
                }
            }
        }

        return (aggregatedProbabilityPermyriad, mostProbableOutcomeHash);
    }

    // --- Challenge Mechanism for Oracle Decisions (3 functions) ---

    /// @notice Allows a contributor to challenge an oracle's resolution.
    /// @param _patternId The ID of the pattern whose resolution is being challenged.
    function challengePatternOutcome(uint256 _patternId) external payable whenNotPaused onlyContributor {
        Pattern storage p = patterns[_patternId];
        if (p.id == 0) {
            revert PatternNotFound();
        }
        if (p.status == PatternStatus.Pending) {
            revert PatternStillPending();
        }
        if (p.status == PatternStatus.Challenged) {
            revert DuplicateChallenge();
        }
        if (block.timestamp > p.resolutionTime.add(CHALLENGE_PERIOD)) {
            revert ChallengePeriodExpired();
        }

        // Challenge stake required is a multiple of the original pattern's total stake.
        // This ensures significant commitment for a challenge.
        uint256 challengeStakeRequired = p.totalStake.mul(CHALLENGE_STAKE_MULTIPLIER);
        if (msg.value < challengeStakeRequired) {
            revert InsufficientStake();
        }

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            patternId: _patternId,
            challenger: msg.sender,
            challengeStake: msg.value,
            challengeTime: block.timestamp,
            status: ChallengeStatus.Pending
        });

        p.status = PatternStatus.Challenged;
        p.challengeId = challengeId;

        emit PatternChallenged(challengeId, _patternId, msg.sender, msg.value);
    }

    /// @notice Owner adjudicates a challenge, impacting scores and stakes.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _challengeUpheld True if the challenge is upheld (oracle was wrong), false otherwise.
    function resolveChallenge(uint256 _challengeId, bool _challengeUpheld) external onlyOwner whenNotPaused {
        Challenge storage c = challenges[_challengeId];
        if (c.id == 0) {
            revert ChallengeNotFound();
        }
        if (c.status != ChallengeStatus.Pending) {
            revert ChallengeAlreadyResolved();
        }

        Pattern storage p = patterns[c.patternId];
        address oracleWhoResolved = p.resolvedBy;

        c.status = _challengeUpheld ? ChallengeStatus.Upheld : ChallengeStatus.Denied;

        if (_challengeUpheld) {
            // Challenge upheld: Challenger was right, Oracle was wrong.
            _increaseWisdomScore(c.challenger, wisdomScoreChallengeSuccessReward);
            _decreaseWisdomScore(oracleWhoResolved, oracleChallengePenalty);

            // Return challenger's stake
            (bool success, ) = c.challenger.call{value: c.challengeStake}("");
            if (!success) { /* Log or handle error: challenger's stake might be stuck if transfer fails */ }

            // If challenge upheld, the original oracle's resolution was wrong.
            // This is complex. We simplify: the pattern's actual outcome should be considered the opposite of what the oracle said.
            p.actualOutcome = !p.actualOutcome; // Flip the outcome
            p.status = p.actualOutcome ? PatternStatus.ResolvedTrue : PatternStatus.ResolvedFalse; // Set to new correct status

            // Impact on original pattern submitter and stakers:
            // Since the oracle's initial resolution was wrong, the original rewards/penalties to stakers were also based on faulty info.
            // Reversing the effect perfectly is highly complex (e.g., if stakes were already distributed).
            // For simplicity, we assume previous distributions are final for stakes, but adjust WisdomScores.
            // If the original submitter was penalized, they should now be rewarded (and vice-versa).
            if (p.actualOutcome) { // If the *new* actual outcome means the submitter was correct
                _increaseWisdomScore(p.submitter, wisdomScoreCorrectPredictionMultiplier); // Reward for correctness
            } else { // If the *new* actual outcome means the submitter was still incorrect
                _decreaseWisdomScore(p.submitter, wisdomScoreIncorrectPredictionPenalty); // Re-penalize
            }
        } else {
            // Challenge denied: Challenger was wrong.
            _decreaseWisdomScore(c.challenger, wisdomScoreChallengeFailPenalty);
            // Challenger's stake is forfeited to the protocol
            protocolFeesCollected = protocolFeesCollected.add(c.challengeStake);
            p.status = p.actualOutcome ? PatternStatus.ResolvedTrue : PatternStatus.ResolvedFalse; // Revert pattern to original resolved status
        }
        emit ChallengeResolved(_challengeId, c.patternId, _challengeUpheld);
    }

    /// @notice Returns details of a challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return A tuple containing all challenge details.
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        returns (
            uint256 id,
            uint256 patternId,
            address challenger,
            uint256 challengeStake,
            uint256 challengeTime,
            ChallengeStatus status
        )
    {
        Challenge storage c = challenges[_challengeId];
        if (c.id == 0) {
            revert ChallengeNotFound();
        }
        return (c.id, c.patternId, c.challenger, c.challengeStake, c.challengeTime, c.status);
    }

    // --- Treasury & Funding (1 function) ---

    /// @notice Allows anyone to send ETH to the contract to bolster rewards or operational funds.
    function fundContract() external payable {
        if (msg.value == 0) {
            revert InsufficientFunds(); // Or 'NoValueProvided'
        }
        // Funds are simply added to the contract balance.
        // A more complex system might have a dedicated reward pool or treasury management.
    }

    // Fallback and Receive functions to allow ETH
    receive() external payable {
        fundContract();
    }

    fallback() external payable {
        fundContract();
    }
}
```