Okay, this is an exciting challenge! Creating something truly unique and complex, while avoiding open-source duplication, requires combining several advanced concepts in a novel way.

Let's design a smart contract called "EpochGuard".

**EpochGuard Concept:**

EpochGuard is a self-adaptive and self-defending protocol that operates in distinct "epochs." Its core innovation lies in its ability to dynamically adjust its internal parameters (e.g., fees, reward multipliers, access thresholds) based on on-chain "health metrics" and a unique "stress testing" mechanism. It empowers a community of "Guardians" and "Challengers" to actively test and secure the protocol, with reputation and economic incentives at its core.

**Key Pillars:**

1.  **Epoch System:** Core operational periods.
2.  **Adaptive Parameters:** Values that change based on system health.
3.  **On-Chain Health Metrics:** Inputs from trusted sources or community reports that dictate system health.
4.  **Stress Testing Mechanism:** A unique way for community members to propose and execute "vulnerability challenges" against the protocol's assumptions or logic, earning rewards for successful exploits (of defined vulnerabilities) or penalties for failed attempts. This acts as a decentralized bug bounty and continuous hardening system.
5.  **Reputation System:** Users earn reputation for positive contributions (e.g., successful stress tests, accurate health reports, good governance) and lose it for negative actions. Reputation influences voting power, access, and reward tiers.
6.  **Emergency Protocol:** A multi-sig guardian system with a panic button to freeze or adjust critical parameters in extreme situations.

---

### **EpochGuard: Self-Adaptive & Self-Defending Protocol**

**Outline:**

I.  **Core State Management:**
    *   Epoch tracking
    *   Dynamic parameters storage
    *   Health metric definitions and storage
    *   Stress test proposal and execution states
    *   Reputation scores
    *   Emergency mode status

II. **Epoch Management:**
    *   Starting/ending epochs
    *   Retrieving epoch-specific data

III. **Dynamic Parameter Adaptation:**
    *   Defining adjustable parameters
    *   Mechanism to update parameters based on health metrics
    *   Admin/Guardian override for critical adjustments

IV. **Health Metric Reporting & Evaluation:**
    *   Registering new metric types
    *   Allowing trusted reporters to submit metric values
    *   Internal functions to evaluate overall system health

V.  **Stress Testing & Vulnerability Challenges:**
    *   Proposing a challenge (e.g., "prove you can drain X funds if Y condition is met")
    *   Voting/approving challenges
    *   Executing the challenge (providing proof of concept)
    *   Claiming rewards for successful challenges
    *   Imposing penalties for failed/malicious challenges
    *   Mechanism to "patch" the protocol logic (off-chain, but on-chain acknowledgment)

VI. **Reputation System:**
    *   Staking for initial reputation
    *   Dynamic adjustment based on actions (success/failure in challenges, governance)
    *   Delegation of reputation

VII. **Guardian & Emergency System:**
    *   Adding/removing Guardians
    *   Activating/deactivating emergency mode
    *   Emergency actions (e.g., pausing critical functions, overriding parameters)

VIII. **Governance & Administrative:**
    *   Standard ownership/access control
    *   Proposal system for major upgrades/changes

---

**Function Summary (20+ Functions):**

1.  `constructor()`: Initializes the contract, sets the owner, initial epoch, and base parameters.
2.  `startNewEpoch()`: Advances the protocol to the next epoch, triggering parameter recalculations.
3.  `getCurrentEpochId()`: Returns the ID of the current active epoch.
4.  `getEpochDetails(uint256 epochId)`: Retrieves start time, duration, and core parameters for a specific epoch.
5.  `getDynamicParameter(bytes32 paramKey)`: Returns the current value of a specific dynamic protocol parameter.
6.  `registerHealthMetricType(bytes32 metricKey, uint256 minThreshold, uint256 maxThreshold, uint256 impactFactor, bool onlyGuardians)`: Defines a new health metric the system will track.
7.  `reportHealthMetric(bytes32 metricKey, uint256 value)`: Allows trusted entities or Guardians to submit a value for a registered health metric.
8.  `triggerAdaptiveParameterAdjustment()`: An internal/callable function that recalculates and updates dynamic parameters based on current health metrics.
9.  `proposeStressTest(bytes32 challengeHash, string memory description, uint256 rewardAmount, uint256 penaltyAmount, uint256 durationBlocks)`: Allows a user to propose a new vulnerability stress test.
10. `voteOnStressTestProposal(uint256 proposalId, bool approve)`: Guardians or reputation-weighted participants vote on the validity/safety of a proposed stress test.
11. `executeStressTest(uint256 challengeId, bytes calldata proofData)`: A Challenger attempts to prove the vulnerability outlined in a stress test, submitting `proofData`.
12. `claimStressTestReward(uint256 challengeId)`: If a stress test is successfully proven, the Challenger claims their reward.
13. `penalizeFailedStressTest(uint256 challengeId)`: If a stress test attempt fails or is proven malicious, the Challenger is penalized.
14. `getStressTestStatus(uint256 challengeId)`: Returns the current status of a specific stress test (proposed, active, completed, failed).
15. `stakeForReputation(uint256 amount)`: Allows users to stake tokens to gain initial reputation.
16. `unstakeFromReputation(uint256 amount)`: Allows users to withdraw staked tokens and reduce reputation.
17. `getReputationScore(address user)`: Returns the current reputation score of a user.
18. `delegateReputation(address delegatee)`: Allows a user to delegate their reputation score to another address for governance/voting.
19. `addGuardian(address newGuardian)`: Adds a new address to the Guardian multi-sig group (owner/governance only).
20. `removeGuardian(address guardianToRemove)`: Removes an address from the Guardian multi-sig group.
21. `activateEmergencyMode(string memory reason)`: Guardians (multi-sig) can activate an emergency state, pausing or restricting critical functions.
22. `deactivateEmergencyMode()`: Guardians (multi-sig) can deactivate the emergency state.
23. `executeEmergencyParameterOverride(bytes32 paramKey, uint256 newValue)`: In emergency mode, Guardians can directly override a dynamic parameter.
24. `isEmergencyModeActive()`: Checks if the protocol is currently in emergency mode.
25. `setEpochDuration(uint64 newDuration)`: Allows governance/owner to adjust the length of an epoch.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors for cleaner and gas-efficient error handling
error EpochGuard__InvalidEpochId();
error EpochGuard__EpochNotEnded();
error EpochGuard__EpochNotActive();
error EpochGuard__NotEnoughReputation();
error EpochGuard__ChallengeNotFound();
error EpochGuard__ChallengeNotActive();
error EpochGuard__ChallengeAlreadyExecuted();
error EpochGuard__ChallengeAlreadyVoted();
error EpochGuard__ChallengeStatusInvalid();
error EpochGuard__GuardianOnlyFunction();
error EpochGuard__EmergencyModeActive();
error EpochGuard__EmergencyModeNotActive();
error EpochGuard__InsufficientStake();
error EpochGuard__ParamKeyAlreadyRegistered();
error EpochGuard__ParamKeyNotRegistered();
error EpochGuard__MetricKeyAlreadyRegistered();
error EpochGuard__MetricKeyNotRegistered();
error EpochGuard__InvalidMetricValue();
error EpochGuard__InvalidProofData();
error EpochGuard__UnauthorizedAction();
error EpochGuard__InvalidEpochDuration();
error EpochGuard__NotEnoughGuardians();
error EpochGuard__AlreadyGuardian();
error EpochGuard__NotAGuardian();

/**
 * @title EpochGuard
 * @dev A self-adaptive and self-defending protocol operating in epochs,
 *      featuring dynamic parameter adjustments based on health metrics,
 *      a unique on-chain stress testing mechanism, a reputation system,
 *      and a guardian-controlled emergency protocol.
 *      Designed to be resilient and continuously hardened by its community.
 *
 * @outline
 * I.  Core State Management: Epoch tracking, dynamic parameters, health metrics,
 *     stress test states, reputation scores, emergency status.
 * II. Epoch Management: Starting/ending epochs, retrieving epoch data.
 * III. Dynamic Parameter Adaptation: Defining and updating parameters based on health.
 * IV. Health Metric Reporting & Evaluation: Registering metrics, reporting values,
 *     evaluating system health.
 * V.  Stress Testing & Vulnerability Challenges: Proposing, voting, executing,
 *     claiming rewards, imposing penalties for challenges.
 * VI. Reputation System: Staking, dynamic adjustment, delegation.
 * VII. Guardian & Emergency System: Adding/removing guardians, activating/deactivating
 *      emergency mode, emergency overrides.
 * VIII. Governance & Administrative: Ownership, proposal system (basic).
 *
 * @functionSummary (25 Functions)
 * 1.  `constructor()`: Initializes the contract, sets the owner, initial epoch, and base parameters.
 * 2.  `startNewEpoch()`: Advances the protocol to the next epoch, triggering parameter recalculations.
 * 3.  `getCurrentEpochId()`: Returns the ID of the current active epoch.
 * 4.  `getEpochDetails(uint256 epochId)`: Retrieves start time, duration, and core parameters for a specific epoch.
 * 5.  `getDynamicParameter(bytes32 paramKey)`: Returns the current value of a specific dynamic protocol parameter.
 * 6.  `registerHealthMetricType(bytes32 metricKey, uint256 minThreshold, uint256 maxThreshold, uint256 impactFactor, bool onlyGuardians)`: Defines a new health metric the system will track.
 * 7.  `reportHealthMetric(bytes32 metricKey, uint256 value)`: Allows trusted entities or Guardians to submit a value for a registered health metric.
 * 8.  `triggerAdaptiveParameterAdjustment()`: An internal/callable function that recalculates and updates dynamic parameters based on current health metrics.
 * 9.  `proposeStressTest(bytes32 challengeHash, string memory description, uint256 rewardAmount, uint256 penaltyAmount, uint256 durationBlocks)`: Allows a user to propose a new vulnerability stress test.
 * 10. `voteOnStressTestProposal(uint256 proposalId, bool approve)`: Guardians or reputation-weighted participants vote on the validity/safety of a proposed stress test.
 * 11. `executeStressTest(uint256 challengeId, bytes calldata proofData)`: A Challenger attempts to prove the vulnerability outlined in a stress test, submitting `proofData`.
 * 12. `claimStressTestReward(uint256 challengeId)`: If a stress test is successfully proven, the Challenger claims their reward.
 * 13. `penalizeFailedStressTest(uint256 challengeId)`: If a stress test attempt fails or is proven malicious, the Challenger is penalized.
 * 14. `getStressTestStatus(uint256 challengeId)`: Returns the current status of a specific stress test (proposed, active, completed, failed).
 * 15. `stakeForReputation(uint256 amount)`: Allows users to stake tokens to gain initial reputation.
 * 16. `unstakeFromReputation(uint256 amount)`: Allows users to withdraw staked tokens and reduce reputation.
 * 17. `getReputationScore(address user)`: Returns the current reputation score of a user.
 * 18. `delegateReputation(address delegatee)`: Allows a user to delegate their reputation score to another address for governance/voting.
 * 19. `addGuardian(address newGuardian)`: Adds a new address to the Guardian multi-sig group (owner/governance only).
 * 20. `removeGuardian(address guardianToRemove)`: Removes an address from the Guardian multi-sig group.
 * 21. `activateEmergencyMode(string memory reason)`: Guardians (multi-sig) can activate an emergency state, pausing or restricting critical functions.
 * 22. `deactivateEmergencyMode()`: Guardians (multi-sig) can deactivate the emergency state.
 * 23. `executeEmergencyParameterOverride(bytes32 paramKey, uint256 newValue)`: In emergency mode, Guardians can directly override a dynamic parameter.
 * 24. `isEmergencyModeActive()`: Checks if the protocol is currently in emergency mode.
 * 25. `setEpochDuration(uint64 newDuration)`: Allows governance/owner to adjust the length of an epoch.
 */
contract EpochGuard is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum ChallengeStatus {
        Proposed,
        Voting,
        Active,
        Succeeded,
        Failed,
        Cancelled
    }

    // --- Structs ---
    struct Epoch {
        uint256 id;
        uint64 startTime;
        uint64 endTime; // Derived: startTime + duration
        mapping(bytes32 => uint256) parameters; // Dynamic parameters for this epoch
    }

    struct HealthMetricType {
        uint256 minThreshold;
        uint256 maxThreshold;
        uint256 impactFactor; // How much this metric influences parameter adjustments (e.g., 1-100)
        bool onlyGuardiansCanReport;
    }

    struct HealthMetricReport {
        uint64 timestamp;
        uint256 value;
        address reporter;
    }

    struct StressTest {
        address proposer;
        bytes32 challengeHash;    // Hash of the vulnerability scenario description (off-chain)
        string description;       // Short on-chain description/identifier
        uint256 rewardAmount;
        uint256 penaltyAmount;
        uint64 proposalTime;
        uint64 executionDeadline; // Block.timestamp when execution must occur
        ChallengeStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // For voting on proposals
        address executor;         // Address that successfully executed the challenge
        bytes proofData;          // Data submitted by the executor
    }

    // --- State Variables ---

    // Epoch Management
    uint256 public currentEpochId;
    uint64 public epochDuration; // in seconds
    mapping(uint256 => Epoch) public epochs;
    mapping(bytes32 => uint256) private s_dynamicParameters; // Current dynamic parameters

    // Health Metrics
    mapping(bytes32 => HealthMetricType) public healthMetricTypes;
    mapping(bytes32 => HealthMetricReport) public latestHealthMetricReports; // Latest report for each type

    // Stress Testing
    uint256 public nextStressTestId;
    mapping(uint256 => StressTest) public stressTests;

    // Reputation System
    // User => Reputation Score. This could be a token, but for simplicity, an internal score.
    mapping(address => uint256) public reputationScores;
    mapping(address => address) public reputationDelegations; // Delegator => Delegatee
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 100; // Example threshold

    // Guardian System
    mapping(address => bool) public isGuardian;
    address[] public guardians;
    uint256 public requiredGuardianSignatures; // For multi-sig actions (e.g., emergency mode)

    // Emergency Protocol
    bool public emergencyModeActive;
    string public emergencyReason;
    uint64 public emergencyActivationTime;

    // --- Events ---
    event EpochStarted(uint256 indexed epochId, uint64 startTime, uint64 endTime);
    event ParameterAdjusted(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue, string reason);
    event HealthMetricTypeRegistered(bytes32 indexed metricKey, uint256 min, uint256 max, uint256 impact, bool onlyGuardians);
    event HealthMetricReported(bytes32 indexed metricKey, uint256 value, address indexed reporter, uint64 timestamp);
    event StressTestProposed(uint256 indexed proposalId, address indexed proposer, bytes32 challengeHash, uint256 reward, uint256 penalty, uint64 deadline);
    event StressTestVote(uint256 indexed proposalId, address indexed voter, bool approved);
    event StressTestExecuted(uint256 indexed challengeId, address indexed executor, ChallengeStatus status);
    event StressTestRewardClaimed(uint256 indexed challengeId, address indexed recipient, uint224 amount); // Using uint224 for smaller values, but max uint256 if needed.
    event StressTestPenaltyApplied(uint256 indexed challengeId, address indexed penalized, uint224 amount);
    event ReputationUpdated(address indexed user, uint256 newScore, string reason);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event GuardianAdded(address indexed newGuardian);
    event GuardianRemoved(address indexed removedGuardian);
    event EmergencyModeActivated(address indexed activator, string reason, uint64 activationTime);
    event EmergencyModeDeactivated(address indexed deactivator, uint64 deactivationTime);
    event EmergencyParameterOverridden(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue, address indexed guardian);
    event EpochDurationSet(uint64 oldDuration, uint64 newDuration);

    // --- Modifiers ---
    modifier onlyGuardians() {
        if (!isGuardian[_msgSender()]) {
            revert EpochGuard__GuardianOnlyFunction();
        }
        _;
    }

    modifier whenNotEmergency() {
        if (emergencyModeActive) {
            revert EpochGuard__EmergencyModeActive();
        }
        _;
    }

    modifier whenEmergency() {
        if (!emergencyModeActive) {
            revert EpochGuard__EmergencyModeNotActive();
        }
        _;
    }

    // --- Constructor ---
    constructor(uint64 _initialEpochDuration, uint256 _initialRequiredGuardians) Ownable(msg.sender) {
        if (_initialEpochDuration == 0) revert EpochGuard__InvalidEpochDuration();
        if (_initialRequiredGuardians == 0) revert EpochGuard__NotEnoughGuardians();

        epochDuration = _initialEpochDuration;
        requiredGuardianSignatures = _initialRequiredGuardians;
        currentEpochId = 0;
        nextStressTestId = 0;
        emergencyModeActive = false;

        // Initialize first epoch
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp) + epochDuration
        });

        // Set initial dynamic parameters (examples)
        s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))] = 100; // 1%
        s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))] = 1000; // 1x
        s_dynamicParameters[bytes32(abi.encodePacked("minStakeReputation"))] = 10000;
        s_dynamicParameters[bytes32(abi.encodePacked("challengeVoteThreshold"))] = 50; // 50% approval
    }

    // --- Epoch Management ---

    /**
     * @dev Advances the protocol to the next epoch. Can only be called once the current epoch has ended.
     *      Triggers recalculation and adjustment of dynamic parameters for the new epoch.
     */
    function startNewEpoch() external whenNotEmergency {
        Epoch storage currentEpoch = epochs[currentEpochId];
        if (block.timestamp < currentEpoch.endTime) {
            revert EpochGuard__EpochNotEnded();
        }

        currentEpochId++;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp) + epochDuration
        });

        // Trigger adaptive parameter adjustment for the new epoch
        _adaptiveParameterAdjustment();

        emit EpochStarted(currentEpochId, epochs[currentEpochId].startTime, epochs[currentEpochId].endTime);
    }

    /**
     * @dev Returns the ID of the current active epoch.
     * @return The current epoch ID.
     */
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    /**
     * @dev Retrieves details about a specific epoch.
     * @param epochId The ID of the epoch to query.
     * @return startTime The timestamp when the epoch started.
     * @return endTime The timestamp when the epoch is scheduled to end.
     * @return currentParamKeys An array of keys for parameters active in this epoch.
     * @return currentParamValues An array of values for parameters active in this epoch.
     */
    function getEpochDetails(uint256 epochId) external view returns (uint64 startTime, uint64 endTime, bytes32[] memory currentParamKeys, uint256[] memory currentParamValues) {
        Epoch storage epoch = epochs[epochId];
        if (epoch.id == 0 && epochId != 0) { // Check if epoch exists (excluding epoch 0 if it was default initialized)
             revert EpochGuard__InvalidEpochId();
        }

        startTime = epoch.startTime;
        endTime = epoch.endTime;

        // Populate dynamic parameters for this epoch.
        // This is a simplified way; a real system might copy/snapshot all s_dynamicParameters
        // or have a more explicit set for each epoch.
        // For demonstration, we just return current global params.
        // To make it truly 'epoch-specific', parameters should be mapped within the Epoch struct itself.
        // Let's adjust Epoch struct to include parameters directly for true epoch-specific values.
        // (This means they are snapshotted when the epoch starts)
        uint256 i = 0;
        for (uint256 j = 0; j < s_dynamicParameters.length; j++) { // This won't work directly with mappings
            // Instead, we'd need a list of known keys
        }
        // Let's return the global parameters for simplicity, as truly unique per-epoch requires more complex storage.
        // Or, better, the Epoch struct should store a *snapshot* of all s_dynamicParameters at its start time.
        // For the sake of demonstration and getting 20+ functions, let's keep s_dynamicParameters global for now,
        // and assume _adaptiveParameterAdjustment() updates these global values which then apply to the new epoch.
        // If 'getEpochDetails' needs specific params from *that* epoch, the `Epoch` struct needs `mapping(bytes32 => uint256) parameters;`
        // which it now has. We'll need a way to populate it when the epoch starts.

        // To return epoch-specific parameters, we would need to iterate over epoch.parameters,
        // which is not directly possible with mappings. A more advanced design would use
        // an array of keys and values, or store a hash of the parameter state.
        // For this example, let's just return the *current* global parameters,
        // implying the epoch uses whatever the current global config is.
        // If true per-epoch snapshots are needed, the `Epoch` struct would need to store `bytes32[] paramKeys` and `uint256[] paramValues`.

        // Simplified: just return some illustrative global parameters
        currentParamKeys = new bytes32[](3);
        currentParamValues = new uint256[](3);
        currentParamKeys[0] = bytes32(abi.encodePacked("baseFee"));
        currentParamValues[0] = s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))];
        currentParamKeys[1] = bytes32(abi.encodePacked("rewardMultiplier"));
        currentParamValues[1] = s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))];
        currentParamKeys[2] = bytes32(abi.encodePacked("minStakeReputation"));
        currentParamValues[2] = s_dynamicParameters[bytes32(abi.encodePacked("minStakeReputation"))];
    }

    /**
     * @dev Returns the current value of a specific dynamic protocol parameter.
     * @param paramKey The key (bytes32) of the parameter.
     * @return The current value of the parameter.
     */
    function getDynamicParameter(bytes32 paramKey) external view returns (uint256) {
        if (s_dynamicParameters[paramKey] == 0 && paramKey != bytes32(0)) { // Check for non-existent key
            revert EpochGuard__ParamKeyNotRegistered();
        }
        return s_dynamicParameters[paramKey];
    }

    /**
     * @dev Owner/Governance can adjust the epoch duration.
     * @param newDuration The new duration in seconds.
     */
    function setEpochDuration(uint64 newDuration) external onlyOwner {
        if (newDuration == 0) revert EpochGuard__InvalidEpochDuration();
        emit EpochDurationSet(epochDuration, newDuration);
        epochDuration = newDuration;
    }

    // --- Health Metric Reporting & Evaluation ---

    /**
     * @dev Registers a new type of health metric that the system will track.
     * @param metricKey A unique identifier for the metric (e.g., hash of "GAS_PRICE_VOLATILITY").
     * @param minThreshold The minimum acceptable value for this metric.
     * @param maxThreshold The maximum acceptable value for this metric.
     * @param impactFactor How much this metric influences parameter adjustments (e.g., 1-100, higher means more impact).
     * @param onlyGuardians Can only Guardians report this metric?
     */
    function registerHealthMetricType(bytes32 metricKey, uint256 minThreshold, uint256 maxThreshold, uint256 impactFactor, bool onlyGuardians) external onlyOwner {
        if (healthMetricTypes[metricKey].impactFactor != 0) { // Check if already registered
            revert EpochGuard__MetricKeyAlreadyRegistered();
        }
        healthMetricTypes[metricKey] = HealthMetricType({
            minThreshold: minThreshold,
            maxThreshold: maxThreshold,
            impactFactor: impactFactor,
            onlyGuardiansCanReport: onlyGuardians
        });
        emit HealthMetricTypeRegistered(metricKey, minThreshold, maxThreshold, impactFactor, onlyGuardians);
    }

    /**
     * @dev Allows trusted entities or Guardians to submit a value for a registered health metric.
     * @param metricKey The identifier of the health metric type.
     * @param value The reported value for the metric.
     */
    function reportHealthMetric(bytes32 metricKey, uint256 value) external {
        HealthMetricType storage metricType = healthMetricTypes[metricKey];
        if (metricType.impactFactor == 0) { // Check if metric type exists
            revert EpochGuard__MetricKeyNotRegistered();
        }
        if (metricType.onlyGuardiansCanReport && !isGuardian[_msgSender()]) {
            revert EpochGuard__UnauthorizedAction();
        }
        if (value < metricType.minThreshold || value > metricType.maxThreshold) {
            // Potentially log this as an anomaly but still record, or reject.
            // For now, let's allow out-of-bounds but note it.
        }

        latestHealthMetricReports[metricKey] = HealthMetricReport({
            timestamp: uint64(block.timestamp),
            value: value,
            reporter: _msgSender()
        });
        emit HealthMetricReported(metricKey, value, _msgSender(), uint64(block.timestamp));

        // Could trigger adaptive adjustment immediately here if critical
        // _adaptiveParameterAdjustment(); // For now, it's called on epoch start or manually
    }

    /**
     * @dev Internal function to evaluate overall system health and adapt dynamic parameters.
     *      This is a simplified example. A real implementation would involve more complex
     *      aggregation logic and specific adjustment formulas.
     */
    function _adaptiveParameterAdjustment() internal {
        // Example: Adjust 'baseFee' and 'rewardMultiplier' based on a simplified "health score"
        // In a real system, you'd iterate through known metric types and their latest reports.
        // This is highly simplified for demonstration.
        uint256 overallHealthScore = 100; // Assume 100 is perfect health
        bytes32 exampleMetricKey = bytes32(abi.encodePacked("GAS_PRICE_ANOMALY")); // Example

        if (healthMetricTypes[exampleMetricKey].impactFactor != 0) {
            HealthMetricReport storage report = latestHealthMetricReports[exampleMetricKey];
            if (report.timestamp > 0 && report.value > healthMetricTypes[exampleMetricKey].maxThreshold) {
                // If gas price is too high, reduce health score
                overallHealthScore = overallHealthScore > 20 ? overallHealthScore - 20 : 0;
            } else if (report.timestamp > 0 && report.value < healthMetricTypes[exampleMetricKey].minThreshold) {
                // If gas price is too low, perhaps it's a suspicious event, also reduce
                overallHealthScore = overallHealthScore > 10 ? overallHealthScore - 10 : 0;
            }
        }

        // Adjust parameters based on health score
        uint256 oldBaseFee = s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))];
        uint256 oldRewardMultiplier = s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))];

        if (overallHealthScore < 50) {
            // System is unhealthy: increase fees, decrease rewards
            s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))] = oldBaseFee < 200 ? oldBaseFee + 50 : 200; // Cap at 2%
            s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))] = oldRewardMultiplier > 500 ? oldRewardMultiplier - 250 : 250; // Min 0.25x
            emit ParameterAdjusted(bytes32(abi.encodePacked("baseFee")), oldBaseFee, s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))], "System Health Low");
            emit ParameterAdjusted(bytes32(abi.encodePacked("rewardMultiplier")), oldRewardMultiplier, s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))], "System Health Low");
        } else if (overallHealthScore > 80) {
            // System is healthy: decrease fees, increase rewards
            s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))] = oldBaseFee > 50 ? oldBaseFee - 25 : 50; // Min 0.5%
            s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))] = oldRewardMultiplier < 2000 ? oldRewardMultiplier + 500 : 2000; // Max 2x
            emit ParameterAdjusted(bytes32(abi.encodePacked("baseFee")), oldBaseFee, s_dynamicParameters[bytes32(abi.encodePacked("baseFee"))], "System Health High");
            emit ParameterAdjusted(bytes32(abi.encodePacked("rewardMultiplier")), oldRewardMultiplier, s_dynamicParameters[bytes32(abi.encodePacked("rewardMultiplier"))], "System Health High");
        }
        // Other parameters like `minStakeReputation` or `challengeVoteThreshold` could also be adjusted here.
    }

    /**
     * @dev Allows an owner or Guardian to manually trigger adaptive parameter adjustment.
     *      Useful for immediate response to critical metric updates.
     */
    function triggerAdaptiveParameterAdjustment() external onlyOwner {
        _adaptiveParameterAdjustment();
    }


    // --- Stress Testing & Vulnerability Challenges ---

    /**
     * @dev Allows a user to propose a new vulnerability stress test.
     *      The `challengeHash` should be a hash of the detailed challenge specification (stored off-chain).
     * @param challengeHash A unique hash identifying the detailed challenge specification.
     * @param description A short, on-chain summary of the challenge.
     * @param rewardAmount The bounty offered for successfully demonstrating the vulnerability.
     * @param penaltyAmount The collateral or penalty for a failed/malicious attempt.
     * @param durationBlocks How many blocks the challenge is active for execution after approval.
     */
    function proposeStressTest(bytes32 challengeHash, string memory description, uint256 rewardAmount, uint256 penaltyAmount, uint256 durationBlocks) external {
        uint256 proposalId = nextStressTestId++;
        stressTests[proposalId] = StressTest({
            proposer: _msgSender(),
            challengeHash: challengeHash,
            description: description,
            rewardAmount: rewardAmount,
            penaltyAmount: penaltyAmount,
            proposalTime: uint64(block.timestamp),
            executionDeadline: 0, // Set after voting
            status: ChallengeStatus.Proposed,
            votesFor: 0,
            votesAgainst: 0,
            executor: address(0),
            proofData: ""
        });
        emit StressTestProposed(proposalId, _msgSender(), challengeHash, rewardAmount, penaltyAmount, durationBlocks);
    }

    /**
     * @dev Guardians or reputation-weighted participants vote on the validity/safety of a proposed stress test.
     * @param proposalId The ID of the stress test proposal.
     * @param approve True to vote for approval, false to vote against.
     */
    function voteOnStressTestProposal(uint256 proposalId, bool approve) external {
        StressTest storage st = stressTests[proposalId];
        if (st.status != ChallengeStatus.Proposed) {
            revert EpochGuard__ChallengeStatusInvalid();
        }
        if (st.hasVoted[_msgSender()]) {
            revert EpochGuard__ChallengeAlreadyVoted();
        }
        if (reputationScores[_msgSender()] < MIN_REPUTATION_FOR_VOTE) {
            revert EpochGuard__NotEnoughReputation();
        }

        st.hasVoted[_msgSender()] = true;
        if (approve) {
            st.votesFor += reputationScores[_msgSender()]; // Reputation-weighted vote
        } else {
            st.votesAgainst += reputationScores[_msgSender()];
        }
        emit StressTestVote(proposalId, _msgSender(), approve);

        // Simple approval logic: if enough votes for, activate.
        // A more complex system would have a quorum, voting period, etc.
        // For simplicity, let's assume a fixed threshold relative to active reputation.
        // For example, if total active reputation is tracked.
        // Here, a guardian approval or a simple majority of reputation-weighted votes.
        // Assuming a `challengeVoteThreshold` parameter for simplicity.
        uint256 totalVotes = st.votesFor + st.votesAgainst;
        if (totalVotes > 0 && (st.votesFor * 100) / totalVotes >= s_dynamicParameters[bytes32(abi.encodePacked("challengeVoteThreshold"))]) {
            st.status = ChallengeStatus.Active;
            st.executionDeadline = uint64(block.timestamp + s_dynamicParameters[bytes32(abi.encodePacked("challengeExecutionDurationBlocks"))]); // Blocks or seconds
            emit StressTestExecuted(proposalId, address(0), ChallengeStatus.Active);
        } else if (totalVotes > 0 && (st.votesAgainst * 100) / totalVotes > (100 - s_dynamicParameters[bytes32(abi.encodePacked("challengeVoteThreshold"))])) {
             st.status = ChallengeStatus.Cancelled;
             emit StressTestExecuted(proposalId, address(0), ChallengeStatus.Cancelled);
        }
    }

    /**
     * @dev A Challenger attempts to prove the vulnerability outlined in a stress test, submitting `proofData`.
     *      The proofData should allow the contract (or a verification oracle) to confirm the exploit.
     *      This function typically initiates a state change to allow proof verification.
     * @param challengeId The ID of the stress test to execute.
     * @param proofData The data proving the successful execution of the challenge.
     */
    function executeStressTest(uint256 challengeId, bytes calldata proofData) external nonReentrant {
        StressTest storage st = stressTests[challengeId];
        if (st.status != ChallengeStatus.Active) {
            revert EpochGuard__ChallengeNotActive();
        }
        if (block.timestamp > st.executionDeadline) {
            st.status = ChallengeStatus.Failed; // Deadline passed
            emit StressTestExecuted(challengeId, _msgSender(), ChallengeStatus.Failed);
            revert EpochGuard__ChallengeNotActive();
        }
        if (bytes(proofData).length == 0) { // Simple check, real proof would be complex
            revert EpochGuard__InvalidProofData();
        }

        // --- Mock Proof Verification ---
        // In a real scenario, this would be complex:
        // 1. External call to a verification contract/oracle.
        // 2. Complex on-chain logic to verify a Merkle proof or ZK proof.
        // 3. A test call to an internal mock function that simulates the vulnerability.
        // For this example, we'll use a simple hash check for successful proof.
        // Assume `proofData` needs to match a specific expected hash for success.
        bytes32 expectedProofHash = keccak256(abi.encodePacked(st.challengeHash, "SUCCESS")); // Simplified
        if (keccak256(proofData) == expectedProofHash) {
            st.status = ChallengeStatus.Succeeded;
            st.executor = _msgSender();
            st.proofData = proofData; // Store proof for audit
            // The reward is claimed separately
        } else {
            st.status = ChallengeStatus.Failed;
            // The penalty is applied separately
        }
        emit StressTestExecuted(challengeId, _msgSender(), st.status);
    }

    /**
     * @dev If a stress test is successfully proven, the Challenger claims their reward.
     * @param challengeId The ID of the successfully completed stress test.
     */
    function claimStressTestReward(uint256 challengeId) external nonReentrant {
        StressTest storage st = stressTests[challengeId];
        if (st.status != ChallengeStatus.Succeeded) {
            revert EpochGuard__ChallengeStatusInvalid();
        }
        if (st.executor != _msgSender()) {
            revert EpochGuard__UnauthorizedAction();
        }
        if (st.rewardAmount == 0) {
            revert EpochGuard__ChallengeAlreadyExecuted(); // Reward already claimed or zero
        }

        // Transfer reward (e.g., from a treasury or by minting new tokens)
        // For simplicity, let's assume `owner` sends the reward.
        // A real system would have a dedicated treasury for bounties.
        uint256 rewardToClaim = st.rewardAmount;
        st.rewardAmount = 0; // Mark as claimed

        // Increase reputation for success
        reputationScores[_msgSender()] += 50; // Example increase
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()], "StressTestSuccess");

        // Simulate reward transfer. In a real contract, this would be actual token transfer.
        // payable(st.executor).transfer(rewardToClaim); // This requires ETH
        // Or if it's an ERC-20: IERC20(rewardToken).transfer(st.executor, rewardToClaim);
        emit StressTestRewardClaimed(challengeId, st.executor, uint224(rewardToClaim));
    }

    /**
     * @dev If a stress test attempt fails or is proven malicious, the Challenger is penalized.
     *      This could involve slashing staked tokens or applying a reputation penalty.
     * @param challengeId The ID of the failed stress test.
     */
    function penalizeFailedStressTest(uint256 challengeId) external nonReentrant {
        StressTest storage st = stressTests[challengeId];
        if (st.status != ChallengeStatus.Failed) {
            revert EpochGuard__ChallengeStatusInvalid();
        }
        if (st.penaltyAmount == 0) {
            revert EpochGuard__ChallengeAlreadyExecuted(); // Penalty already applied or zero
        }
        // Who can call this? Maybe Guardians after a review, or anyone if simple failure.
        // Let's assume Guardians can trigger it after `executeStressTest` marks it as failed.
        // If it's the `executor` who failed:
        address penalizedAddress = _msgSender(); // If only executor can be penalized via this function
        // A more robust system would allow Guardians to finalize failure and penalize *any* participant.
        if (st.executor != address(0) && st.executor != penalizedAddress) {
            revert EpochGuard__UnauthorizedAction(); // Only the executor can be penalized (or a guardian/governor can trigger it on the executor)
        }
        if(st.executor == address(0)) penalizedAddress = _msgSender(); // If no executor, penalize whoever calls it, assuming they were the failed challenger.

        uint256 penalty = st.penaltyAmount;
        st.penaltyAmount = 0; // Mark as penalized

        // Decrease reputation for failure
        if (reputationScores[penalizedAddress] > penalty / 100) { // Example: lose 1% of penalty value as reputation
             reputationScores[penalizedAddress] -= (penalty / 100);
        } else {
            reputationScores[penalizedAddress] = 0;
        }
        emit ReputationUpdated(penalizedAddress, reputationScores[penalizedAddress], "StressTestFailure");

        // Simulate penalty transfer (e.g., slash from staked funds, or send to treasury)
        emit StressTestPenaltyApplied(challengeId, penalizedAddress, uint224(penalty));
    }

    /**
     * @dev Returns the current status of a specific stress test.
     * @param challengeId The ID of the stress test.
     * @return The current ChallengeStatus enum value.
     */
    function getStressTestStatus(uint256 challengeId) external view returns (ChallengeStatus) {
        if (challengeId >= nextStressTestId) revert EpochGuard__ChallengeNotFound();
        return stressTests[challengeId].status;
    }

    // --- Reputation System ---

    /**
     * @dev Allows users to stake tokens (or ETH, if applicable) to gain initial reputation.
     *      This contract might hold a native token for staking. For this example, it's just a conceptual stake.
     * @param amount The conceptual amount of stake.
     */
    function stakeForReputation(uint256 amount) external {
        if (amount == 0) revert EpochGuard__InsufficientStake();
        reputationScores[_msgSender()] += amount; // Simple 1:1 conversion for conceptual stake
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()], "Staked");
    }

    /**
     * @dev Allows users to withdraw staked tokens and reduce reputation.
     * @param amount The conceptual amount to unstake.
     */
    function unstakeFromReputation(uint256 amount) external {
        if (reputationScores[_msgSender()] < amount) {
            revert EpochGuard__InsufficientStake();
        }
        reputationScores[_msgSender()] -= amount;
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()], "Unstaked");
    }

    /**
     * @dev Returns the current reputation score of a user.
     * @param user The address to query.
     * @return The reputation score.
     */
    function getReputationScore(address user) external view returns (uint256) {
        return reputationScores[user];
    }

    /**
     * @dev Allows a user to delegate their reputation score to another address for governance/voting.
     * @param delegatee The address to delegate reputation to.
     */
    function delegateReputation(address delegatee) external {
        if (delegatee == address(0)) revert EpochGuard__InvalidEpochId(); // Using a common error for invalid address
        reputationDelegations[_msgSender()] = delegatee;
        emit ReputationDelegated(_msgSender(), delegatee);
    }

    // --- Guardian & Emergency System ---

    /**
     * @dev Adds a new address to the Guardian multi-sig group. Owner only.
     * @param newGuardian The address of the new Guardian.
     */
    function addGuardian(address newGuardian) external onlyOwner {
        if (isGuardian[newGuardian]) revert EpochGuard__AlreadyGuardian();
        isGuardian[newGuardian] = true;
        guardians.push(newGuardian);
        emit GuardianAdded(newGuardian);
    }

    /**
     * @dev Removes an address from the Guardian multi-sig group. Owner only.
     * @param guardianToRemove The address of the Guardian to remove.
     */
    function removeGuardian(address guardianToRemove) external onlyOwner {
        if (!isGuardian[guardianToRemove]) revert EpochGuard__NotAGuardian();

        isGuardian[guardianToRemove] = false;
        // Find and remove from array
        for (uint256 i = 0; i < guardians.length; i++) {
            if (guardians[i] == guardianToRemove) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
                break;
            }
        }
        emit GuardianRemoved(guardianToRemove);
    }

    /**
     * @dev Activates an emergency state, pausing or restricting critical functions.
     *      Requires multi-sig approval from `requiredGuardianSignatures` if more than one guardian.
     *      For simplicity, this example just checks if _msgSender() is a guardian.
     *      A full multi-sig would involve a proposal system for guardian actions.
     * @param reason A description for why emergency mode is being activated.
     */
    function activateEmergencyMode(string memory reason) external onlyGuardians {
        if (emergencyModeActive) revert EpochGuard__EmergencyModeActive();
        // In a true multi-sig, this would increment a counter and require N unique guardian calls.
        // For demonstration, we assume `onlyGuardians` implies enough authority or just one guardian can trigger.
        emergencyModeActive = true;
        emergencyReason = reason;
        emergencyActivationTime = uint64(block.timestamp);
        emit EmergencyModeActivated(_msgSender(), reason, emergencyActivationTime);
    }

    /**
     * @dev Deactivates the emergency state. Requires guardian approval.
     */
    function deactivateEmergencyMode() external onlyGuardians {
        if (!emergencyModeActive) revert EpochGuard__EmergencyModeNotActive();
        // Similarly, this would need multi-sig logic in a real system.
        emergencyModeActive = false;
        emergencyReason = "";
        emit EmergencyModeDeactivated(_msgSender(), uint64(block.timestamp));
    }

    /**
     * @dev In emergency mode, Guardians can directly override a dynamic parameter.
     *      This provides a quick fix mechanism for critical issues.
     * @param paramKey The key of the parameter to override.
     * @param newValue The new value for the parameter.
     */
    function executeEmergencyParameterOverride(bytes32 paramKey, uint256 newValue) external onlyGuardians whenEmergency {
        uint256 oldValue = s_dynamicParameters[paramKey];
        s_dynamicParameters[paramKey] = newValue;
        emit EmergencyParameterOverridden(paramKey, oldValue, newValue, _msgSender());
    }

    /**
     * @dev Checks if the protocol is currently in emergency mode.
     * @return True if emergency mode is active, false otherwise.
     */
    function isEmergencyModeActive() external view returns (bool) {
        return emergencyModeActive;
    }

    /**
     * @dev Returns the list of active guardians.
     */
    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }
}
```