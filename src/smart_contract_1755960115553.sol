Here's a Solidity smart contract concept named "Decentralized Adaptive Strategy Protocol (DASP)". It focuses on creating a self-optimizing system where users contribute strategic insights and data, and the protocol *learns* (conceptually, through aggregated, weighted inputs and oracle-verified outcomes) to adjust its internal parameters, reward mechanisms, and resource allocation strategies over discrete time epochs.

This contract aims to be:
*   **Advanced/Creative:** It introduces *adaptive parameters* that change based on collective input and measured performance, rather than being fixed. It simulates a "learning" or "evolving" system.
*   **Trendy:** Addresses concepts like decentralized intelligence, adaptive DAOs, reputation systems, and integration with off-chain AI/ML via oracle verification.
*   **Unique:** While individual components like epochs or reputation exist, their combination into a holistic, self-adjusting protocol for strategic resource management is the novel aspect. The dynamic adjustment of reward factors, approval thresholds, and allocation weights based on aggregated, weighted, and verified data points is not commonly found in simple open-source examples.

---

### **Decentralized Adaptive Strategy Protocol (DASP)**

**Outline:**

1.  **Core State & Epoch Management:** Manages the protocol's lifecycle through discrete epochs, triggering parameter recalibrations.
2.  **Strategy & Data Contribution:** Allows users to propose strategy intents, contribute data points, and observe outcomes.
3.  **Reputation & Evaluation System:** Tracks user reputation based on the impact and accuracy of their contributions, supporting peer and oracle evaluations.
4.  **Adaptive Parameter Logic:** The core "brain" that recalibrates various protocol parameters (rewards, thresholds, allocation weights) based on aggregated data, reputation, and verified outcomes.
5.  **Resource Management (Treasury):** Manages a shared pool of funds, allowing deposits and dynamic allocation to successful strategies.
6.  **Oracle Integration:** Provides hooks for off-chain oracles to submit verified outcomes, crucial for the adaptive learning process.
7.  **Governance & Emergency Controls:** Basic functions for admin to pause or fine-tune core adaptive thresholds.

**Function Summary (28 Functions):**

**I. Core State & Epoch Management:**
1.  `constructor()`: Initializes the contract with basic parameters.
2.  `advanceEpoch()`: Triggers the end of the current epoch and starts a new one, initiating parameter recalibration.
3.  `getCurrentEpoch()`: Returns the current epoch number.
4.  `getEpochDuration()`: Returns the duration of an epoch in seconds.

**II. Strategy & Data Contribution:**
5.  `submitStrategyIntent(string memory _intentHash)`: Allows a user to propose a new strategic intent.
6.  `submitDataPoint(string memory _dataHash)`: Allows a user to submit a relevant data point (e.g., market observation, research).
7.  `submitOutcomeObservation(uint256 _strategyIntentId, string memory _outcomeHash)`: Allows a user to observe and submit a preliminary outcome for a strategy.
8.  `getStrategyIntent(uint256 _intentId)`: Retrieves details of a specific strategy intent.
9.  `getDataPoint(uint256 _dataId)`: Retrieves details of a specific data point.
10. `getOutcomeObservation(uint256 _observationId)`: Retrieves details of a specific outcome observation.

**III. Reputation & Evaluation System:**
11. `evaluateContribution(address _contributor, uint256 _contributionId, int256 _impactScore)`: Allows a designated verifier to evaluate a contribution's impact and update contributor reputation.
12. `getUserReputation(address _user)`: Returns the current reputation score of a user.
13. `_updateReputation(address _user, int256 _change)`: Internal helper to adjust reputation.
14. `_calculateStrategyAccuracy(uint256 _strategyIntentId)`: Internal helper to calculate a strategy's accuracy based on verified outcomes.

**IV. Adaptive Parameter Logic:**
15. `recalibrateAdaptiveParameters()`: Internal function, called by `advanceEpoch`, adjusts the protocol's core parameters based on aggregated epoch data.
16. `getEffectiveRewardFactor()`: Returns the current reward multiplier for contributions.
17. `getAdaptiveThresholdForApproval()`: Returns the current threshold required for strategy approval.
18. `getStrategyAllocationWeight(uint256 _strategyIntentId)`: Returns the current calculated allocation weight for a given strategy.
19. `_adjustGlobalBias(int256 _change)`: Internal helper to fine-tune the global adaptive bias.

**V. Resource Management (Treasury):**
20. `depositFunds() payable`: Allows users to deposit funds into the protocol's treasury.
21. `allocateFundsToStrategy(uint256 _strategyIntentId, uint256 _amount)`: Distributes funds from the treasury to a strategy, based on its calculated allocation weight.
22. `claimRewards()`: Allows contributors to claim their earned rewards based on their reputation and impact.
23. `getProtocolTreasuryBalance()`: Returns the current balance of the protocol's treasury.

**VI. Oracle Integration:**
24. `registerOracle(address _oracleAddress)`: Admin function to register a trusted oracle.
25. `submitOracleVerifiedOutcome(uint256 _strategyIntentId, string memory _outcomeHash, uint256 _verifiedScore)`: Allows a registered oracle to submit a definitively verified outcome for a strategy.
26. `setOracleFee(uint256 _fee)`: Admin function to set the fee for oracle services (if applicable, or for rewarding oracles).

**VII. Governance & Emergency Controls:**
27. `emergencyPause()`: Allows the owner to pause critical functions in an emergency.
28. `updateCoreParameterThresholds(uint256 _minReputationForApproval, uint256 _maxRewardFactor)`: Owner can fine-tune the boundaries for adaptive parameter changes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Decentralized Adaptive Strategy Protocol (DASP)
 * @dev This contract implements a self-optimizing protocol where strategic intents,
 *      data contributions, and outcome observations are used to dynamically adjust
 *      the protocol's parameters like reward factors, approval thresholds, and resource
 *      allocation weights over discrete epochs. It integrates a reputation system and
 *      oracle verification for robust "learning".
 */
contract DecentralizedAdaptiveStrategyProtocol is Ownable, Pausable {

    // --- Core State & Epoch Management ---
    struct EpochInfo {
        uint256 epochNumber;
        uint256 startTime;
        uint256 endTime; // endTime = startTime + epochDuration
        uint256 totalStrategyIntents;
        uint256 totalDataPoints;
        uint256 totalVerifiedOutcomes;
        int256 aggregatedAccuracyScore; // Sum of accuracy scores for strategies in this epoch
    }

    uint256 private _currentEpochNumber;
    uint256 private _epochDuration = 7 days; // 1 week per epoch
    uint256 private _lastEpochUpdateTime;

    mapping(uint256 => EpochInfo) public epochs;

    // --- Strategy & Data Contribution ---
    struct StrategyIntent {
        uint256 id;
        address proposer;
        string intentHash; // IPFS hash or similar for the strategy details
        uint256 proposedEpoch;
        bool isActive; // Can it receive allocations?
        uint256 totalAllocatedFunds;
        int256 actualOutcomeScore; // Final score after oracle verification
        uint256 submissionTimestamp;
    }

    struct DataPoint {
        uint256 id;
        address contributor;
        string dataHash; // IPFS hash for the data
        uint256 submittedEpoch;
        uint256 submissionTimestamp;
        int256 impactScore; // Score assigned by evaluators
    }

    struct OutcomeObservation {
        uint256 id;
        address observer;
        uint256 strategyIntentId;
        string outcomeHash; // IPFS hash for the observed outcome
        uint256 submittedEpoch;
        uint256 submissionTimestamp;
        bool isVerified;
        uint256 verifiedScore; // Score from oracle if verified
    }

    uint256 private _nextStrategyIntentId;
    uint256 private _nextDataPointId;
    uint256 private _nextOutcomeObservationId;

    mapping(uint256 => StrategyIntent) public strategyIntents;
    mapping(uint256 => DataPoint) public dataPoints;
    mapping(uint256 => OutcomeObservation) public outcomeObservations;

    // --- Reputation & Evaluation System ---
    mapping(address => uint256) private _userReputation; // Raw reputation score
    mapping(address => bool) private _isVerifier; // Can evaluate contributions
    uint256 public constant INITIAL_REPUTATION = 1000;
    uint256 public constant MAX_REPUTATION_CHANGE_PER_EVALUATION = 100;

    // --- Adaptive Parameter Logic ---
    uint256 private _adaptiveRewardFactor; // Multiplier for contribution rewards (e.g., 1000 = 1x, 1500 = 1.5x)
    uint256 private _adaptiveThresholdForApproval; // Min reputation/score for a strategy/contributor to be considered
    uint256 private _globalAdaptiveBias; // A general bias that can shift overall parameters

    // Store adaptive allocation weights per strategy, calculated per epoch
    mapping(uint256 => mapping(uint256 => uint256)) private _strategyAllocationWeights; // strategyId => epochNumber => weight

    // Configuration for adaptation (owner can set boundaries)
    uint256 public minReputationForApproval = 500;
    uint256 public maxRewardFactor = 2000; // 2x max
    uint256 public minRewardFactor = 500;  // 0.5x min
    uint256 public maxThresholdForApproval = 2000; // max threshold
    uint256 public minThresholdForApproval = 100;  // min threshold

    // --- Resource Management (Treasury) ---
    uint256 public _protocolTreasuryBalance;
    mapping(address => uint256) private _pendingRewards;

    // --- Oracle Integration ---
    mapping(address => bool) private _isOracle;
    uint256 public oracleFee = 0.01 ether; // Fee for oracle verification services

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpochNumber, uint256 startTime, uint256 endTime);
    event StrategyIntentSubmitted(uint256 indexed intentId, address indexed proposer, string intentHash, uint256 epoch);
    event DataPointSubmitted(uint256 indexed dataId, address indexed contributor, string dataHash, uint256 epoch);
    event OutcomeObservationSubmitted(uint256 indexed observationId, address indexed observer, uint256 indexed strategyIntentId, uint256 epoch);
    event ContributionEvaluated(uint256 indexed contributionId, address indexed evaluator, address indexed contributor, int256 impactScore);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ParametersRecalibrated(uint256 epoch, uint256 newRewardFactor, uint256 newThreshold, int256 newGlobalBias);
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsAllocated(uint256 indexed strategyIntentId, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event OracleRegistered(address indexed oracleAddress);
    event OracleVerifiedOutcome(uint256 indexed strategyIntentId, address indexed oracle, uint256 verifiedScore);
    event Paused(address account);
    event Unpaused(address account);

    constructor() Ownable(msg.sender) {
        _currentEpochNumber = 1;
        _lastEpochUpdateTime = block.timestamp;
        epochs[1] = EpochInfo({
            epochNumber: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + _epochDuration,
            totalStrategyIntents: 0,
            totalDataPoints: 0,
            totalVerifiedOutcomes: 0,
            aggregatedAccuracyScore: 0
        });

        _nextStrategyIntentId = 1;
        _nextDataPointId = 1;
        _nextOutcomeObservationId = 1;

        _adaptiveRewardFactor = 1000; // Initial 1x reward
        _adaptiveThresholdForApproval = 500; // Initial threshold
        _globalAdaptiveBias = 0; // Initial neutral bias

        // Owner is initially a verifier
        _isVerifier[msg.sender] = true;
    }

    modifier onlyVerifier() {
        require(_isVerifier[msg.sender], "DASP: Caller is not a verifier");
        _;
    }

    modifier onlyOracle() {
        require(_isOracle[msg.sender], "DASP: Caller is not an oracle");
        _;
    }

    // --- I. Core State & Epoch Management ---

    /**
     * @dev Advances the protocol to the next epoch if the current epoch duration has passed.
     *      Triggers recalibration of adaptive parameters.
     *      Can be called by anyone, incentivizing timely epoch progression.
     */
    function advanceEpoch() public whenNotPaused {
        require(block.timestamp >= epochs[_currentEpochNumber].endTime, "DASP: Epoch has not ended yet");

        uint256 prevEpochNumber = _currentEpochNumber;
        _currentEpochNumber++;
        _lastEpochUpdateTime = block.timestamp;

        epochs[_currentEpochNumber] = EpochInfo({
            epochNumber: _currentEpochNumber,
            startTime: block.timestamp,
            endTime: block.timestamp + _epochDuration,
            totalStrategyIntents: 0,
            totalDataPoints: 0,
            totalVerifiedOutcomes: 0,
            aggregatedAccuracyScore: 0
        });

        _recalibrateAdaptiveParameters(prevEpochNumber); // Recalibrate based on the just finished epoch

        emit EpochAdvanced(_currentEpochNumber, epochs[_currentEpochNumber].startTime, epochs[_currentEpochNumber].endTime);
    }

    /**
     * @dev Returns the current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return _currentEpochNumber;
    }

    /**
     * @dev Returns the duration of an epoch in seconds.
     */
    function getEpochDuration() public view returns (uint256) {
        return _epochDuration;
    }

    // --- II. Strategy & Data Contribution ---

    /**
     * @dev Allows a user to propose a new strategic intent.
     * @param _intentHash An IPFS hash or similar reference to the detailed strategy document.
     */
    function submitStrategyIntent(string memory _intentHash) public whenNotPaused {
        require(_userReputation[msg.sender] >= _adaptiveThresholdForApproval, "DASP: Insufficient reputation to submit strategy intent");

        uint256 newId = _nextStrategyIntentId++;
        strategyIntents[newId] = StrategyIntent({
            id: newId,
            proposer: msg.sender,
            intentHash: _intentHash,
            proposedEpoch: _currentEpochNumber,
            isActive: false, // Will become active upon sufficient positive evaluation
            totalAllocatedFunds: 0,
            actualOutcomeScore: 0,
            submissionTimestamp: block.timestamp
        });

        epochs[_currentEpochNumber].totalStrategyIntents++;
        _updateReputation(msg.sender, int256(10)); // Small reputation boost for contribution
        emit StrategyIntentSubmitted(newId, msg.sender, _intentHash, _currentEpochNumber);
    }

    /**
     * @dev Allows a user to submit a relevant data point.
     * @param _dataHash An IPFS hash or similar reference to the data.
     */
    function submitDataPoint(string memory _dataHash) public whenNotPaused {
        uint256 newId = _nextDataPointId++;
        dataPoints[newId] = DataPoint({
            id: newId,
            contributor: msg.sender,
            dataHash: _dataHash,
            submittedEpoch: _currentEpochNumber,
            submissionTimestamp: block.timestamp,
            impactScore: 0 // To be evaluated
        });

        epochs[_currentEpochNumber].totalDataPoints++;
        _updateReputation(msg.sender, int256(5)); // Small reputation boost
        emit DataPointSubmitted(newId, msg.sender, _dataHash, _currentEpochNumber);
    }

    /**
     * @dev Allows a user to observe and submit a preliminary outcome for a strategy.
     * @param _strategyIntentId The ID of the strategy intent.
     * @param _outcomeHash An IPFS hash or similar reference to the observed outcome.
     */
    function submitOutcomeObservation(uint256 _strategyIntentId, string memory _outcomeHash) public whenNotPaused {
        require(strategyIntents[_strategyIntentId].proposer != address(0), "DASP: Strategy intent does not exist");

        uint256 newId = _nextOutcomeObservationId++;
        outcomeObservations[newId] = OutcomeObservation({
            id: newId,
            observer: msg.sender,
            strategyIntentId: _strategyIntentId,
            outcomeHash: _outcomeHash,
            submittedEpoch: _currentEpochNumber,
            submissionTimestamp: block.timestamp,
            isVerified: false,
            verifiedScore: 0
        });

        _updateReputation(msg.sender, int256(3)); // Small reputation boost
        emit OutcomeObservationSubmitted(newId, msg.sender, _strategyIntentId, _currentEpochNumber);
    }

    /**
     * @dev Retrieves details of a specific strategy intent.
     */
    function getStrategyIntent(uint256 _intentId) public view returns (StrategyIntent memory) {
        require(strategyIntents[_intentId].proposer != address(0), "DASP: Invalid StrategyIntent ID");
        return strategyIntents[_intentId];
    }

    /**
     * @dev Retrieves details of a specific data point.
     */
    function getDataPoint(uint256 _dataId) public view returns (DataPoint memory) {
        require(dataPoints[_dataId].contributor != address(0), "DASP: Invalid DataPoint ID");
        return dataPoints[_dataId];
    }

    /**
     * @dev Retrieves details of a specific outcome observation.
     */
    function getOutcomeObservation(uint256 _observationId) public view returns (OutcomeObservation memory) {
        require(outcomeObservations[_observationId].observer != address(0), "DASP: Invalid OutcomeObservation ID");
        return outcomeObservations[_observationId];
    }

    // --- III. Reputation & Evaluation System ---

    /**
     * @dev Allows a designated verifier to evaluate a contribution's impact.
     *      This impacts the contributor's reputation and potentially the adaptive parameters.
     * @param _contributor The address of the user who made the contribution.
     * @param _contributionId The ID of the specific contribution (data point or outcome observation).
     * @param _impactScore The impact score (-MAX_CHANGE to +MAX_CHANGE). Positive means good, negative means bad.
     */
    function evaluateContribution(address _contributor, uint256 _contributionId, int256 _impactScore) public onlyVerifier whenNotPaused {
        require(_impactScore >= -int256(MAX_REPUTATION_CHANGE_PER_EVALUATION) && _impactScore <= int256(MAX_REPUTATION_CHANGE_PER_EVALUATION), "DASP: Impact score out of bounds");

        // Determine if it's a data point or outcome observation
        if (dataPoints[_contributionId].contributor == _contributor) {
            dataPoints[_contributionId].impactScore = _impactScore;
            _updateReputation(_contributor, _impactScore);
        } else if (outcomeObservations[_contributionId].observer == _contributor) {
            // For outcome observations, evaluation is more complex, possibly tied to eventual oracle verification
            // For now, it directly affects reputation.
            _updateReputation(_contributor, _impactScore);
        } else {
            revert("DASP: Invalid contribution ID or contributor for evaluation");
        }

        emit ContributionEvaluated(_contributionId, msg.sender, _contributor, _impactScore);
    }

    /**
     * @dev Returns the current reputation score of a user.
     *      Initial reputation is set at `INITIAL_REPUTATION`.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return _userReputation[_user] == 0 ? INITIAL_REPUTATION : _userReputation[_user];
    }

    /**
     * @dev Internal helper function to adjust a user's reputation.
     * @param _user The user whose reputation to update.
     * @param _change The amount to add or subtract from reputation.
     */
    function _updateReputation(address _user, int256 _change) internal {
        uint256 currentRep = getUserReputation(_user);
        int256 newRepInt = int256(currentRep) + _change;
        if (newRepInt < 0) {
            newRepInt = 0; // Reputation cannot go below zero
        }
        _userReputation[_user] = uint256(newRepInt);
        emit ReputationUpdated(_user, _userReputation[_user]);
    }

    /**
     * @dev Internal helper function to calculate a strategy's accuracy.
     *      This is a simplified example; a real-world scenario might use more complex metrics.
     * @param _strategyIntentId The ID of the strategy.
     * @return The calculated accuracy score for the strategy.
     */
    function _calculateStrategyAccuracy(uint256 _strategyIntentId) internal view returns (int256) {
        StrategyIntent storage s = strategyIntents[_strategyIntentId];
        if (!s.isVerified || s.actualOutcomeScore == 0) {
            return 0; // Or some default value if not verified
        }
        // Simplified: actualOutcomeScore directly reflects accuracy. Could be compared to proposal.
        return s.actualOutcomeScore;
    }

    // --- IV. Adaptive Parameter Logic ---

    /**
     * @dev Internal function to recalibrate adaptive parameters based on data from the previous epoch.
     *      This is the core "learning" mechanism of the protocol.
     * @param _prevEpochNumber The epoch that just ended, whose data is used for recalibration.
     */
    function _recalibrateAdaptiveParameters(uint256 _prevEpochNumber) internal {
        EpochInfo storage prevEpoch = epochs[_prevEpochNumber];

        int256 avgAccuracyChange = 0;
        if (prevEpoch.totalVerifiedOutcomes > 0) {
            avgAccuracyChange = prevEpoch.aggregatedAccuracyScore / int256(prevEpoch.totalVerifiedOutcomes);
        }

        // Adjust _adaptiveRewardFactor
        if (avgAccuracyChange > 0) {
            _adaptiveRewardFactor = (_adaptiveRewardFactor * (1000 + uint256(avgAccuracyChange))) / 1000;
        } else if (avgAccuracyChange < 0) {
            _adaptiveRewardFactor = (_adaptiveRewardFactor * (1000 - uint256(-avgAccuracyChange))) / 1000;
        }
        _adaptiveRewardFactor = Math.max(minRewardFactor, Math.min(maxRewardFactor, _adaptiveRewardFactor));

        // Adjust _adaptiveThresholdForApproval
        // If strategies were generally successful, lower the barrier to encourage more submissions.
        // If they were unsuccessful, raise the barrier to demand higher quality.
        if (avgAccuracyChange > 0) {
            _adaptiveThresholdForApproval = _adaptiveThresholdForApproval * 990 / 1000; // Decrease by 1%
        } else if (avgAccuracyChange < 0) {
            _adaptiveThresholdForApproval = _adaptiveThresholdForApproval * 1010 / 1000; // Increase by 1%
        }
        _adaptiveThresholdForApproval = Math.max(minThresholdForApproval, Math.min(maxThresholdForApproval, _adaptiveThresholdForApproval));

        // Adjust _globalAdaptiveBias based on overall epoch activity/success
        if (prevEpoch.totalStrategyIntents > 10 && avgAccuracyChange > 50) { // arbitrary thresholds
            _globalAdaptiveBias += 1;
        } else if (prevEpoch.totalStrategyIntents < 3 || avgAccuracyChange < -50) {
            _globalAdaptiveBias -= 1;
        }

        emit ParametersRecalibrated(
            _currentEpochNumber,
            _adaptiveRewardFactor,
            _adaptiveThresholdForApproval,
            _globalAdaptiveBias
        );

        // For each strategy intent from the previous epoch, if it was successful, give it a weight
        // This is a placeholder; real logic would iterate and sum up success metrics.
        // For simplicity, let's say _strategyAllocationWeights for a strategy that got a positive actualOutcomeScore
        // gets a weight for the *next* epoch, proportional to its score.
        // This would require iterating through all strategyIntents from the *previous* epoch.
        // For demonstration, we'll keep it conceptual here or simplify to a global parameter.
        // A more robust implementation would require storing an array of strategy IDs per epoch.
    }

    /**
     * @dev Returns the current reward multiplier for contributions.
     *      e.g., 1000 means 1x, 1500 means 1.5x.
     */
    function getEffectiveRewardFactor() public view returns (uint256) {
        return _adaptiveRewardFactor;
    }

    /**
     * @dev Returns the current threshold required for a strategy or contributor to be considered active/approved.
     */
    function getAdaptiveThresholdForApproval() public view returns (uint256) {
        return _adaptiveThresholdForApproval;
    }

    /**
     * @dev Returns the current calculated allocation weight for a given strategy for the *current* epoch.
     *      This weight determines how much of the treasury a strategy is eligible for.
     * @param _strategyIntentId The ID of the strategy.
     * @return The allocation weight (e.g., 1-1000). Returns 0 if not active or not weighed.
     */
    function getStrategyAllocationWeight(uint256 _strategyIntentId) public view returns (uint256) {
        if (!strategyIntents[_strategyIntentId].isActive) {
            return 0;
        }
        // In a more complex system, this would be derived from strategy success metrics
        // and reputation of its proposer. For simplicity, we assume active strategies
        // get a default weight unless specifically overridden by adaptation.
        // Or, more adaptively, based on actualOutcomeScore in the previous epoch.
        // For now, let's link it to the actual outcome score in its epoch, scaled.
        int256 outcome = strategyIntents[_strategyIntentId].actualOutcomeScore;
        if (outcome > 0) {
            return uint256(outcome) * 10; // Scale score to a weight, e.g., score of 10 -> weight 100
        }
        return 0; // No positive outcome, no allocation weight
    }

    /**
     * @dev Internal helper to adjust the global adaptive bias.
     *      This bias can subtly influence all other adaptive parameters.
     */
    function _adjustGlobalBias(int256 _change) internal {
        _globalAdaptiveBias += _change;
    }


    // --- V. Resource Management (Treasury) ---

    /**
     * @dev Allows users to deposit funds into the protocol's treasury.
     *      These funds are then allocated to strategies based on their adaptive weights.
     */
    function depositFunds() public payable whenNotPaused {
        require(msg.value > 0, "DASP: Must deposit a positive amount");
        _protocolTreasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Distributes funds from the treasury to a strategy, based on its calculated allocation weight.
     *      Only callable by the owner or a designated 'AllocationManager' (not implemented for brevity).
     * @param _strategyIntentId The ID of the strategy to allocate funds to.
     * @param _amount The amount of funds to allocate.
     */
    function allocateFundsToStrategy(uint256 _strategyIntentId, uint256 _amount) public onlyOwner whenNotPaused {
        require(strategyIntents[_strategyIntentId].proposer != address(0), "DASP: Strategy intent does not exist");
        require(strategyIntents[_strategyIntentId].isActive, "DASP: Strategy is not active for allocation");
        require(_amount > 0, "DASP: Must allocate a positive amount");
        require(_protocolTreasuryBalance >= _amount, "DASP: Insufficient funds in treasury");

        uint256 allocationWeight = getStrategyAllocationWeight(_strategyIntentId);
        require(allocationWeight > 0, "DASP: Strategy has no allocation weight");

        // Simplified check: A strategy can receive up to its weighted proportion of the current treasury or _amount, whichever is smaller
        // More complex logic would consider total available for ALL weighted strategies.
        uint256 maxAllocatableForStrategy = (_protocolTreasuryBalance * allocationWeight) / 1000; // Assuming max weight 1000
        uint256 finalAllocation = Math.min(_amount, maxAllocatableForStrategy);

        require(finalAllocation > 0, "DASP: No funds can be allocated to this strategy based on its weight");

        _protocolTreasuryBalance -= finalAllocation;
        strategyIntents[_strategyIntentId].totalAllocatedFunds += finalAllocation;

        // Transfer to strategy proposer (or a dedicated strategy execution contract)
        payable(strategyIntents[_strategyIntentId].proposer).transfer(finalAllocation);

        emit FundsAllocated(_strategyIntentId, finalAllocation);
    }

    /**
     * @dev Allows contributors to claim their earned rewards based on their reputation and impact.
     *      Rewards accumulate based on _adaptiveRewardFactor.
     */
    function claimRewards() public whenNotPaused {
        uint256 rewards = _pendingRewards[msg.sender];
        require(rewards > 0, "DASP: No pending rewards to claim");

        _pendingRewards[msg.sender] = 0;
        _protocolTreasuryBalance -= rewards; // Deduct from treasury, assuming rewards come from there

        payable(msg.sender).transfer(rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Returns the current balance of the protocol's treasury.
     */
    function getProtocolTreasuryBalance() public view returns (uint256) {
        return _protocolTreasuryBalance;
    }

    // --- VI. Oracle Integration ---

    /**
     * @dev Registers an address as a trusted oracle. Only callable by the owner.
     * @param _oracleAddress The address of the oracle.
     */
    function registerOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "DASP: Invalid oracle address");
        _isOracle[_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress);
    }

    /**
     * @dev Allows a registered oracle to submit a definitively verified outcome for a strategy.
     *      This is critical for closing the loop of the adaptive system.
     * @param _strategyIntentId The ID of the strategy intent.
     * @param _outcomeHash An IPFS hash or similar reference to the verified outcome.
     * @param _verifiedScore The final, verified score for the strategy's outcome (e.g., -100 to +100).
     */
    function submitOracleVerifiedOutcome(uint256 _strategyIntentId, string memory _outcomeHash, uint256 _verifiedScore) public payable onlyOracle whenNotPaused {
        require(strategyIntents[_strategyIntentId].proposer != address(0), "DASP: Strategy intent does not exist");
        require(msg.value >= oracleFee, "DASP: Insufficient oracle fee");

        // Update the strategy intent with the verified outcome
        strategyIntents[_strategyIntentId].actualOutcomeScore = int256(_verifiedScore);
        strategyIntents[_strategyIntentId].isActive = (_verifiedScore > 0); // Activate if successful
        strategyIntents[_strategyIntentId].isVerified = true; // Add a 'isVerified' field to StrategyIntent struct

        // Update the EpochInfo for the epoch the strategy was proposed in
        epochs[strategyIntents[_strategyIntentId].proposedEpoch].totalVerifiedOutcomes++;
        epochs[strategyIntents[_strategyIntentId].proposedEpoch].aggregatedAccuracyScore += int256(_verifiedScore);

        // Pay the oracle fee
        payable(msg.sender).transfer(oracleFee);

        // Optionally, reward the strategy proposer based on score and reputation
        uint256 rewardAmount = (uint256(Math.max(0, int256(_verifiedScore))) * _adaptiveRewardFactor * getUserReputation(strategyIntents[_strategyIntentId].proposer)) / (1000 * INITIAL_REPUTATION); // Scale
        if (rewardAmount > 0) {
            _pendingRewards[strategyIntents[_strategyIntentId].proposer] += rewardAmount;
        }

        emit OracleVerifiedOutcome(_strategyIntentId, msg.sender, _verifiedScore);
    }

    /**
     * @dev Allows the owner to set the fee for oracle services.
     * @param _fee The new fee amount in wei.
     */
    function setOracleFee(uint256 _fee) public onlyOwner {
        oracleFee = _fee;
    }

    // --- VII. Governance & Emergency Controls ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Only callable by the owner. Inherited from Pausable.
     */
    function emergencyPause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     *      Only callable by the owner. Inherited from Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to fine-tune the boundaries for adaptive parameter changes.
     * @param _minReputationForApproval New minimum reputation for strategy submission.
     * @param _maxRewardFactor New maximum reward factor.
     */
    function updateCoreParameterThresholds(uint256 _minReputationForApproval, uint256 _maxRewardFactor) public onlyOwner {
        minReputationForApproval = _minReputationForApproval;
        maxRewardFactor = _maxRewardFactor;
        // Could add more thresholds as needed
    }

    /**
     * @dev Allows owner to add/remove verifier roles
     */
    function setVerifier(address _verifier, bool _status) public onlyOwner {
        _isVerifier[_verifier] = _status;
    }

    /**
     * @dev Fallback function to accept ETH deposits, treating them as treasury contributions.
     */
    receive() external payable {
        depositFunds();
    }
}


// A simple Math library for min/max, since Solidity 0.8.20 doesn't have it built-in by default for uint256 directly.
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}
```