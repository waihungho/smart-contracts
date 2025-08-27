This smart contract, `AdaptiveProtocolNexus`, introduces a novel approach to decentralized protocol governance and parameter management. Instead of fixed parameters or direct voting on value changes, the community proposes and activates "Adaptive Policies." These policies define dynamic rulesets for how core protocol parameters (like service fees, reward rates, or collateral ratios) automatically adjust in response to real-time on-chain data and events.

This system aims to create a more resilient, self-optimizing, and responsive protocol that can adapt to changing market conditions or community needs without constant, granular human intervention for every parameter adjustment. It incorporates elements of gamification through reputation scores for "Policy Stewards" and a challenge mechanism for ineffective policies.

---

## Smart Contract: `AdaptiveProtocolNexus.sol`

**Description:** An innovative smart contract that introduces a dynamic, adaptive governance mechanism. Instead of direct voting on fixed parameter values, the community proposes and activates "Adaptive Policies." These policies define how core protocol parameters (e.g., service fees, reward multipliers) should automatically adjust based on real-time on-chain conditions (e.g., gas prices, asset prices, TVL, time). The contract acts as an "engine" that regularly evaluates active policies and tunes the protocol's economic primitives to optimize for stability, growth, or other strategic objectives. It also includes elements of gamification and reputation for active participants.

**Advanced Concepts:**
1.  **Adaptive Policies & Meta-Governance:** Users vote on *rules* (policies) that dictate *how* parameters change, rather than just voting on new parameter *values*. This shifts governance to a higher level of abstraction.
2.  **On-Chain Oracle-Driven Adaptation:** Policies can reference various on-chain data points (Chainlink price feeds, `block.timestamp`, `block.gasprice`, internal TVL, etc.) to trigger their logic, enabling truly dynamic responses.
3.  **Policy Lifecycle Management:** A structured process for policies including proposal, voting, activation, deactivation, expiration, and extension.
4.  **Parameter Safeguards:** Min/max limits for protocol parameters to prevent extreme or malicious policy actions.
5.  **"Policy Stewards" Reputation System:** Users gain or lose reputation based on the success and effectiveness of the policies they propose, creating an incentive for thoughtful and beneficial contributions.
6.  **Challenge Mechanism:** Allows the community to challenge active policies deemed ineffective or harmful, with a bond and resolution process.
7.  **Dynamic Economic Primitives:** Fees and reward structures can automatically adjust based on policy directives, optimizing protocol economics in real-time.
8.  **Time-Series Parameter Tracking:** Records a history of all parameter changes, offering transparency and data for future analysis.

---

### Outline

1.  **Core Parameter Management:**
    *   Initialization of essential protocol parameters (e.g., `serviceFee`, `rewardRate`).
    *   Functions for safe, direct adjustment of parameters by governance/owner for emergencies.
    *   Safeguards like minimum and maximum values for parameters.
    *   Tracking and retrieval of parameter change history.

2.  **Adaptive Policy Framework:**
    *   **Policy Definition:** Structs (`PolicyCondition`, `PolicyAction`, `AdaptivePolicy`) to formally define the "if-then" logic of adaptive rules.
    *   **Policy Lifecycle:**
        *   Proposing new policies with a bonding requirement.
        *   Voting on proposed policies with support/against options.
        *   Activation of policies that meet the voting threshold.
        *   Deactivation or expiration of policies.
        *   Extension of active policy durations.
    *   **Policy Execution (`executePolicyUpdates`):** The core "crank" function that, when called, iterates through active policies, evaluates their conditions using on-chain metrics, and applies their actions to update protocol parameters.
    *   **Challenge System:** Allowing users to challenge active policies perceived as detrimental, with bonds and a resolution process.

3.  **Economic & Incentive Layer:**
    *   User deposit and withdrawal functionalities for the primary protocol token.
    *   A simplified rewards claiming mechanism for active participants.
    *   Bonding requirements for policy proposals and challenges.

4.  **Reputation & Gamification:**
    *   A `policyStewardReputation` score that increases upon successful policy activation and decreases upon failed challenges or policy deactivations.
    *   A less formal `submitOptimizationSuggestion` function for broader community input.

5.  **Oracle Integration:**
    *   Internal helper (`_getOnChainMetric`) to fetch various on-chain data: `block.timestamp`, `block.gasprice`, `ProtocolTVL`, `TreasuryBalance`, and external price data via Chainlink `AggregatorV3Interface`.

6.  **Emergency & Administration:**
    *   `Pausable` functionality for emergency halts.
    *   `Ownable` access control for critical administrative functions.
    *   Functions to adjust core governance parameters like bonding requirements and activation thresholds.

7.  **Read-Only & Transparency:**
    *   Extensive view functions to inspect the current state of parameters, policies (by ID or status), user balances, and reputation scores.

---

### Function Summary (25+ functions)

**I. Core Parameter Management:**

1.  `constructor(address _tokenAddress, address _priceFeedAddress)`: Initializes the contract with the primary token, Chainlink price feed, owner, and default protocol parameters.
2.  `updateParameter(bytes32 _paramKey, uint256 _newValue)`: (Admin/Governance) Allows the owner to directly set a specific protocol parameter. Primarily for emergency or direct governance votes on values.
3.  `setMinimumParameterValue(bytes32 _paramKey, uint256 _minValue)`: (Admin) Sets a lower bound for a parameter, acting as a safeguard for policy adjustments.
4.  `setMaximumParameterValue(bytes32 _paramKey, uint256 _maxValue)`: (Admin) Sets an upper bound for a parameter, acting as a safeguard for policy adjustments.
5.  `getParameters()`: (View) Returns all current protocol parameters (keys and values).
6.  `getLatestParameterChange(bytes32 _paramKey)`: (View) Retrieves the most recent change recorded for a specific parameter.

**II. Adaptive Policy Framework:**

7.  `proposeAdaptivePolicy(string calldata _description, bytes32 _paramKey, PolicyCondition calldata _condition, PolicyAction calldata _action, uint256 _duration)`: Allows any user to propose a new adaptive policy by specifying its conditions, actions, target parameter, description, and duration, requiring a bonding amount.
8.  `voteOnPolicyProposal(uint256 _policyId, bool _support)`: Enables users to vote for or against a proposed policy within a defined voting period.
9.  `activatePolicy(uint256 _policyId)`: Activates a policy after its voting period has ended and it has met the activation threshold. Refunds the proposer's bond and awards reputation.
10. `deactivatePolicy(uint256 _policyId)`: Deactivates an active or challenged policy. Can be called by the owner or as a result of a challenge.
11. `extendPolicyDuration(uint256 _policyId, uint256 _newDuration)`: Allows the original proposer to extend the active period of an already active policy, potentially requiring an extension fee/bond.
12. `executePolicyUpdates()`: The central "crank" function. It iterates through all active policies, evaluates their conditions using on-chain metrics, and applies their defined actions to modify protocol parameters. Rewards the caller (e.g., a keeper).
13. `challengeIneffectivePolicy(uint256 _policyId, uint256 _challengeBond)`: Allows users to challenge an active policy they believe is detrimental or ineffective, requiring a challenge bond.
14. `resolveChallenge(uint256 _policyId, bool _isChallengerCorrect)`: (Admin/Governance) Resolves a challenged policy. If the challenger is correct, the policy is deactivated, challenger is rewarded, and proposer loses reputation. If incorrect, challenger's bond is forfeited, and policy may be reactivated.

**III. Economic & Incentive Layer:**

15. `deposit(uint256 _amount)`: Allows users to deposit the protocol's native token to participate and potentially earn rewards.
16. `withdraw(uint256 _amount)`: Allows users to withdraw their deposited tokens.
17. `claimRewards()`: Enables users to claim their accumulated rewards (simplified calculation for this example).

**IV. Reputation & Gamification:**

18. `submitOptimizationSuggestion(string calldata _suggestionDetails)`: Allows users to submit informal ideas or suggestions for protocol improvement, potentially for off-chain recognition or minor on-chain rewards/reputation.

**V. Emergency & Administration:**

19. `emergencyPause()`: (Admin) Pauses all critical operations of the contract in an emergency.
20. `emergencyUnpause()`: (Admin) Resumes operations after an emergency pause.
21. `setPolicyBondingRequirement(uint256 _newAmount)`: (Admin) Sets the amount of tokens required to bond when proposing a new policy.
22. `setPolicyActivationThreshold(uint256 _newThreshold)`: (Admin) Sets the minimum percentage of support votes required for a policy to be activated.
23. `setRewardMultiplier(uint256 _multiplier)`: (Admin) Adjusts the base multiplier used in reward calculations.

**VI. Read-Only & Transparency:**

24. `getEffectiveServiceFee()`: (View) Returns the current service fee parameter, reflecting any adjustments made by active policies.
25. `getPolicyDetails(uint256 _policyId)`: (View) Provides all detailed information about a specific adaptive policy.
26. `getPoliciesByStatus(PolicyStatus _status)`: (View) Returns an array of policy IDs that currently have a specified status (e.g., `Proposed`, `Active`).
27. `getUserBalance(address _user)`: (View) Returns the deposited balance of a specific user.
28. `getEstimatedRewards(address _user)`: (View) Returns the estimated pending rewards for a specific user (simplified calculation).
29. `getPolicyStewardReputation(address _user)`: (View) Returns the reputation score of a user as a policy steward.
30. `getProtocolTreasuryBalance()`: (View) Returns the current balance of the protocol's native token held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // For price feeds

/**
 * @title AdaptiveProtocolNexus
 * @dev An innovative smart contract that introduces a dynamic, adaptive governance mechanism.
 *      Instead of direct voting on fixed parameter values, the community proposes and
 *      activates "Adaptive Policies." These policies define how core protocol parameters
 *      (e.g., service fees, reward multipliers) should automatically adjust based on
 *      real-time on-chain conditions (e.g., gas prices, asset prices, TVL, time).
 *      The contract acts as an "engine" that regularly evaluates active policies and
 *      tunes the protocol's economic primitives to optimize for stability, growth,
 *      or other strategic objectives. It also includes elements of gamification
 *      and reputation for active participants.
 *
 * @outline
 * 1.  **Core Parameter Management:** Defines and manages the fundamental adjustable
 *     parameters of the protocol (e.g., service fees, reward rates).
 * 2.  **Adaptive Policy Framework:** The heart of the contract. Allows for the creation,
 *     voting, activation, and deactivation of dynamic rulesets ("Policies") that
 *     govern how core parameters change.
 *     a.  **Policy Definition:** Structs for conditions (metrics, operators, thresholds)
 *         and actions (parameter updates).
 *     b.  **Policy Lifecycle:** Functions for proposing, voting, activating, deactivating,
 *         and extending policies.
 *     c.  **Policy Execution:** A core function (`executePolicyUpdates`) that periodically
 *         evaluates active policies and applies their changes to protocol parameters.
 * 3.  **Economic & Incentive Layer:** Mechanisms for user deposits, withdrawals,
 *     reward distribution, and the role of bonding in policy proposals.
 * 4.  **Reputation & Gamification:** System for tracking "Policy Steward" reputation
 *     based on the success of proposed policies, and a challenge mechanism for
 *     ineffective policies.
 * 5.  **Oracle Integration:** Utilizes Chainlink oracles for external price data,
 *     and internal functions for other on-chain metrics (gas, TVL).
 * 6.  **Emergency & Administration:** Standard pause/unpause, ownership management,
 *     and safety limits for parameters.
 * 7.  **Read-Only & Transparency:** Extensive view functions to inspect current
 *     protocol state, policy details, and user-specific information.
 *
 * @function_summary
 * -   `constructor`: Initializes owner, Chainlink oracle, and initial parameters.
 * -   `emergencyPause()`: Pauses protocol operations in an emergency.
 * -   `emergencyUnpause()`: Unpauses protocol operations.
 * -   `updateParameter(bytes32 _paramKey, uint256 _newValue)`: Admin/governance function to directly set a parameter.
 * -   `setMinimumParameterValue(bytes32 _paramKey, uint256 _minValue)`: Sets a minimum safeguard value for a parameter.
 * -   `setMaximumParameterValue(bytes32 _paramKey, uint256 _maxValue)`: Sets a maximum safeguard value for a parameter.
 * -   `getParameters()`: Returns all current protocol parameters.
 * -   `getLatestParameterChange(bytes32 _paramKey)`: Gets the latest recorded change for a parameter.
 * -   `proposeAdaptivePolicy(string calldata _description, bytes32 _paramKey, PolicyCondition calldata _condition, PolicyAction calldata _action, uint256 _duration)`: Propose a new policy with a bonding amount.
 * -   `voteOnPolicyProposal(uint256 _policyId, bool _support)`: Vote for or against a policy proposal.
 * -   `activatePolicy(uint256 _policyId)`: Activates a policy after successful voting.
 * -   `deactivatePolicy(uint256 _policyId)`: Deactivates an active policy.
 * -   `extendPolicyDuration(uint256 _policyId, uint256 _newDuration)`: Extends the active period of a policy.
 * -   `executePolicyUpdates()`: The "crank" function that iterates through active policies and applies their logic.
 * -   `challengeIneffectivePolicy(uint256 _policyId, uint256 _challengeBond)`: Challenges an active policy.
 * -   `resolveChallenge(uint256 _policyId, bool _isChallengerCorrect)`: Admin/governance resolves a policy challenge.
 * -   `deposit(uint256 _amount)`: Deposits funds into the protocol.
 * -   `withdraw(uint256 _amount)`: Withdraws funds from the protocol.
 * -   `claimRewards()`: Claims accumulated rewards.
 * -   `submitOptimizationSuggestion(string calldata _suggestionDetails)`: Allows for less formal suggestions.
 * -   `setPolicyBondingRequirement(uint256 _newAmount)`: Sets the required bond for policy proposals.
 * -   `setPolicyActivationThreshold(uint256 _newThreshold)`: Sets the voting threshold for policy activation.
 * -   `setRewardMultiplier(uint256 _multiplier)`: Sets the base reward multiplier.
 * -   `getEffectiveServiceFee()`: Returns the current service fee, factoring in active policies.
 * -   `getPolicyDetails(uint256 _policyId)`: Returns details of a specific policy.
 * -   `getPoliciesByStatus(PolicyStatus _status)`: Returns a list of policy IDs for a given status.
 * -   `getUserBalance(address _user)`: Returns a user's deposited balance.
 * -   `getEstimatedRewards(address _user)`: Returns a user's estimated pending rewards.
 * -   `getPolicyStewardReputation(address _user)`: Returns a user's policy steward reputation score.
 * -   `getProtocolTreasuryBalance()`: Returns the current balance of the protocol's native token treasury.
 */
contract AdaptiveProtocolNexus is Ownable, Pausable {
    using SafeMath for uint256;

    IERC20 public immutable token; // The token used for deposits, bonds, and rewards
    AggregatorV3Interface public priceFeed; // Chainlink price feed for external asset prices

    // --- Enums ---

    enum PolicyStatus {
        Proposed,
        Active,
        Deactivated,
        Expired,
        Challenged
    }

    enum MetricType {
        BlockTimestamp,
        BlockGasPrice,
        TokenPriceUSD, // Requires oracle
        ProtocolTVL, // Total Value Locked in this contract
        TreasuryBalance,
        UserCount // Number of active users
    }

    enum Operator {
        GreaterThan,
        LessThan,
        EqualTo
    }

    enum ActionType {
        Set, // Set parameter to a specific value
        IncreaseByPercentage, // Increase parameter by a percentage
        DecreaseByPercentage, // Decrease parameter by a percentage
        MultiplyByFactor, // Multiply parameter by a factor (e.g., 1.05 for 5% increase)
        DivideByFactor // Divide parameter by a factor
    }

    // --- Structs ---

    struct PolicyCondition {
        MetricType metricType;
        Operator op;
        uint256 thresholdValue; // Value to compare against (e.g., USD value * 1e8, percentage * 100)
    }

    struct PolicyAction {
        bytes32 paramKey; // Which parameter to modify
        ActionType actionType;
        uint256 actionValue; // Value for the action (e.g., percentage * 100, factor * 1000 for 3 decimal places)
    }

    struct AdaptivePolicy {
        uint256 id;
        string description;
        address proposer;
        PolicyCondition condition;
        PolicyAction action;
        PolicyStatus status;
        uint256 bondingAmount;
        uint256 proposalTimestamp;
        uint256 activationTimestamp;
        uint256 expirationTimestamp; // When the policy automatically deactivates
        mapping(address => bool) votes; // true for support, false for against
        uint256 supportVotes;
        uint256 againstVotes;
        address challenger; // Who challenged this policy
        uint256 challengeBond;
    }

    struct ProtocolParameter {
        uint256 currentValue;
        uint256 minValue; // Safety limit
        uint256 maxValue; // Safety limit
    }

    struct ParameterChange {
        uint256 timestamp;
        uint256 oldValue;
        uint256 newValue;
        bytes32 paramKey;
    }

    // --- State Variables ---

    uint256 private nextPolicyId;
    mapping(uint256 => AdaptivePolicy) public adaptivePolicies;
    mapping(PolicyStatus => uint256[]) public policiesByStatus; // For efficient lookup

    // Core protocol parameters, e.g., service fee, reward multiplier, collateral ratio
    mapping(bytes32 => ProtocolParameter) public protocolParameters;
    bytes32[] public allParameterKeys; // To iterate over all parameters

    mapping(address => uint256) public userBalances; // User deposited tokens
    mapping(address => uint252) public userRewardsPending; // Rewards pending claim (simplified, not fully implemented for dynamic calculation)
    mapping(address => uint256) public policyStewardReputation; // Reputation for policy proposers

    uint256 public policyBondingRequirement; // Tokens required to propose a policy
    uint256 public policyActivationThreshold; // Minimum support votes needed (percentage * 100)
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant CHALLENGE_RESOLUTION_PERIOD = 7 days; // Time for admin to resolve challenge

    uint256 public baseRewardMultiplier; // Factor for calculating rewards (e.g., 10000 for 1x)
    uint256 public totalProtocolValueLocked; // Tracks TVL in this contract for metrics

    ParameterChange[] public parameterHistory; // Stores all parameter changes

    // --- Events ---

    event PolicyProposed(uint256 indexed policyId, address indexed proposer, bytes32 indexed paramKey, uint256 bondingAmount);
    event PolicyVoted(uint256 indexed policyId, address indexed voter, bool support);
    event PolicyActivated(uint256 indexed policyId, address indexed activator);
    event PolicyDeactivated(uint256 indexed policyId, address indexed deactivator);
    event PolicyDurationExtended(uint256 indexed policyId, uint256 newExpirationTimestamp);
    event ParameterUpdated(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue, address indexed updater);
    event PolicyChallenged(uint256 indexed policyId, address indexed challenger, uint256 challengeBond);
    event PolicyChallengeResolved(uint256 indexed policyId, address indexed resolver, bool challengerWasCorrect);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationGained(address indexed user, uint256 amount);
    event ReputationLost(address indexed user, uint256 amount);

    // --- Constructor ---

    constructor(address _tokenAddress, address _priceFeedAddress) Ownable(msg.sender) Pausable(msg.sender) {
        token = IERC20(_tokenAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        // Initialize core parameters with default values and safety limits
        _initializeParameter("serviceFee", 100, 0, 1000); // 1% (100 = 1%)
        _initializeParameter("rewardRate", 50, 0, 1000); // 0.5% (50 = 0.5%)
        _initializeParameter("maxBorrowRatio", 7000, 0, 10000); // 70% (7000 = 70%)

        policyBondingRequirement = 10000 * (10 ** token.decimals()); // e.g., 10,000 native tokens
        policyActivationThreshold = 6000; // 60%
        baseRewardMultiplier = 10000; // 1x multiplier
    }

    // --- Internal Parameter Management ---

    function _initializeParameter(bytes32 _paramKey, uint256 _defaultValue, uint256 _minValue, uint256 _maxValue) internal {
        require(protocolParameters[_paramKey].currentValue == 0, "Param already initialized"); // Simple check
        protocolParameters[_paramKey] = ProtocolParameter(_defaultValue, _minValue, _maxValue);
        allParameterKeys.push(_paramKey);
        emit ParameterUpdated(_paramKey, 0, _defaultValue, address(0)); // Initial update
    }

    function _updateParameterInternal(bytes32 _paramKey, uint256 _newValue, address _updater) internal {
        ProtocolParameter storage param = protocolParameters[_paramKey];
        uint256 oldValue = param.currentValue;
        
        // Apply safety limits
        uint256 adjustedNewValue = _newValue;
        if (param.maxValue > 0) adjustedNewValue = Math.min(adjustedNewValue, param.maxValue);
        if (param.minValue > 0) adjustedNewValue = Math.max(adjustedNewValue, param.minValue);

        if (oldValue != adjustedNewValue) {
            param.currentValue = adjustedNewValue;
            parameterHistory.push(ParameterChange({
                timestamp: block.timestamp,
                oldValue: oldValue,
                newValue: adjustedNewValue,
                paramKey: _paramKey
            }));
            emit ParameterUpdated(_paramKey, oldValue, adjustedNewValue, _updater);
        }
    }

    // --- 1. Core Parameter Management Functions ---

    /**
     * @dev Allows owner/governance to directly update a parameter. Primarily for emergency or simple governance.
     * @param _paramKey The key identifying the parameter (e.g., "serviceFee").
     * @param _newValue The new value for the parameter.
     */
    function updateParameter(bytes32 _paramKey, uint256 _newValue) external onlyOwner whenNotPaused {
        require(protocolParameters[_paramKey].currentValue != 0, "Parameter not found");
        _updateParameterInternal(_paramKey, _newValue, msg.sender);
    }

    /**
     * @dev Sets the minimum allowed value for a parameter. Safeguard against extreme policy actions.
     * @param _paramKey The key of the parameter.
     * @param _minValue The new minimum value.
     */
    function setMinimumParameterValue(bytes32 _paramKey, uint256 _minValue) external onlyOwner {
        require(protocolParameters[_paramKey].currentValue != 0, "Parameter not found");
        protocolParameters[_paramKey].minValue = _minValue;
    }

    /**
     * @dev Sets the maximum allowed value for a parameter. Safeguard against extreme policy actions.
     * @param _paramKey The key of the parameter.
     * @param _maxValue The new maximum value.
     */
    function setMaximumParameterValue(bytes32 _paramKey, uint256 _maxValue) external onlyOwner {
        require(protocolParameters[_paramKey].currentValue != 0, "Parameter not found");
        protocolParameters[_paramKey].maxValue = _maxValue;
    }

    /**
     * @dev Returns all current protocol parameters for transparency.
     * @return An array of current parameter keys and their values.
     */
    function getParameters() external view returns (bytes32[] memory, uint256[] memory) {
        bytes32[] memory keys = allParameterKeys;
        uint256[] memory values = new uint256[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = protocolParameters[keys[i]].currentValue;
        }
        return (keys, values);
    }

    /**
     * @dev Returns the latest change recorded for a specific parameter.
     * @param _paramKey The key of the parameter.
     * @return ParameterChange struct.
     */
    function getLatestParameterChange(bytes32 _paramKey) external view returns (ParameterChange memory) {
        for(int i = int(parameterHistory.length) - 1; i >= 0; i--) {
            if (parameterHistory[uint256(i)].paramKey == _paramKey) {
                return parameterHistory[uint256(i)];
            }
        }
        revert("No changes found for parameter");
    }

    // --- 2. Adaptive Policy Framework Functions ---

    /**
     * @dev Proposes a new adaptive policy. Requires a bonding amount.
     * @param _description A human-readable description of the policy.
     * @param _paramKey The parameter this policy aims to modify.
     * @param _condition The condition that must be met for the policy to trigger.
     * @param _action The action to perform on the parameter if the condition is met.
     * @param _duration The desired active duration of the policy in seconds if activated.
     */
    function proposeAdaptivePolicy(
        string calldata _description,
        bytes32 _paramKey,
        PolicyCondition calldata _condition,
        PolicyAction calldata _action,
        uint256 _duration
    ) external whenNotPaused {
        require(token.transferFrom(msg.sender, address(this), policyBondingRequirement), "Bonding failed");
        require(protocolParameters[_paramKey].currentValue != 0, "Invalid parameter key");
        require(_duration > VOTING_PERIOD, "Policy duration must be longer than voting period");

        uint256 currentPolicyId = nextPolicyId++;
        AdaptivePolicy storage newPolicy = adaptivePolicies[currentPolicyId];
        newPolicy.id = currentPolicyId;
        newPolicy.description = _description;
        newPolicy.proposer = msg.sender;
        newPolicy.condition = _condition;
        newPolicy.action = _action;
        newPolicy.status = PolicyStatus.Proposed;
        newPolicy.bondingAmount = policyBondingRequirement;
        newPolicy.proposalTimestamp = block.timestamp;
        newPolicy.expirationTimestamp = block.timestamp + _duration; // This is a provisional expiration if activated

        policiesByStatus[PolicyStatus.Proposed].push(currentPolicyId);

        emit PolicyProposed(currentPolicyId, msg.sender, _paramKey, policyBondingRequirement);
    }

    /**
     * @dev Allows users to vote on a proposed policy. Only one vote per user per policy.
     * @param _policyId The ID of the policy to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnPolicyProposal(uint256 _policyId, bool _support) external whenNotPaused {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        require(policy.status == PolicyStatus.Proposed, "Policy not in proposed state");
        require(block.timestamp <= policy.proposalTimestamp + VOTING_PERIOD, "Voting period has ended");
        require(!policy.votes[msg.sender], "Already voted on this policy");

        policy.votes[msg.sender] = true;
        if (_support) {
            policy.supportVotes++;
        } else {
            policy.againstVotes++;
        }
        emit PolicyVoted(_policyId, msg.sender, _support);
    }

    /**
     * @dev Activates a policy if it has passed the voting threshold and voting period has ended.
     *      Anyone can call this to finalize a vote.
     * @param _policyId The ID of the policy to activate.
     */
    function activatePolicy(uint256 _policyId) external whenNotPaused {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        require(policy.status == PolicyStatus.Proposed, "Policy not in proposed state");
        require(block.timestamp > policy.proposalTimestamp + VOTING_PERIOD, "Voting period not yet ended");

        uint256 totalVotes = policy.supportVotes + policy.againstVotes;
        require(totalVotes > 0, "No votes cast for this policy");
        
        // Calculate vote percentage, multiplied by 10000 for precision (e.g., 6000 for 60%)
        uint256 supportPercentage = policy.supportVotes.mul(10000).div(totalVotes);

        require(supportPercentage >= policyActivationThreshold, "Policy did not meet activation threshold");

        policy.status = PolicyStatus.Active;
        policy.activationTimestamp = block.timestamp;
        // The expirationTimestamp was set at proposal, now it becomes effective.
        
        // Remove from Proposed list, add to Active list
        _removePolicyFromStatusList(_policyId, PolicyStatus.Proposed);
        policiesByStatus[PolicyStatus.Active].push(_policyId);

        // Refund bonding amount and reward proposer with reputation
        require(token.transfer(policy.proposer, policy.bondingAmount), "Bond refund failed");
        policyStewardReputation[policy.proposer] = policyStewardReputation[policy.proposer].add(100); // Base reputation gain
        emit ReputationGained(policy.proposer, 100);
        
        emit PolicyActivated(_policyId, msg.sender);
    }

    /**
     * @dev Deactivates an active policy. Can be called by owner or if challenged successfully.
     * @param _policyId The ID of the policy to deactivate.
     */
    function deactivatePolicy(uint256 _policyId) public whenNotPaused { // Changed to public for challenge resolution
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        require(policy.status == PolicyStatus.Active || policy.status == PolicyStatus.Challenged, "Policy not active or challenged");

        if (policy.status == PolicyStatus.Active) {
            _removePolicyFromStatusList(_policyId, PolicyStatus.Active);
        } else if (policy.status == PolicyStatus.Challenged) {
             _removePolicyFromStatusList(_policyId, PolicyStatus.Challenged);
        }
        
        policy.status = PolicyStatus.Deactivated;
        policiesByStatus[PolicyStatus.Deactivated].push(_policyId);

        emit PolicyDeactivated(_policyId, msg.sender);
    }

    /**
     * @dev Allows extending the active duration of an active policy by its proposer.
     *      Requires a new bond and potentially a small fee.
     * @param _policyId The ID of the active policy.
     * @param _newDuration The additional duration in seconds.
     */
    function extendPolicyDuration(uint256 _policyId, uint256 _newDuration) external whenNotPaused {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        require(policy.status == PolicyStatus.Active, "Policy not active");
        require(policy.proposer == msg.sender, "Only proposer can extend policy");
        require(block.timestamp < policy.expirationTimestamp, "Policy has already expired");
        require(_newDuration > 0, "New duration must be positive");

        uint256 extensionCost = policyBondingRequirement.div(10); // Example: 10% of original bond
        require(token.transferFrom(msg.sender, address(this), extensionCost), "Extension fee payment failed");

        policy.expirationTimestamp = policy.expirationTimestamp.add(_newDuration);

        emit PolicyDurationExtended(_policyId, policy.expirationTimestamp);
    }

    /**
     * @dev The main "crank" function. It iterates through all active policies,
     *      checks their conditions, and applies their actions to update protocol parameters.
     *      Can be called by any external EOA or a keeper network. Rewards caller with a small fee.
     */
    function executePolicyUpdates() external whenNotPaused {
        // In a real system, `rewardForKeeper` would be transferred from the contract's token balance.
        // For simplicity, we are just acknowledging the reward here as it's a generic IERC20.
        // A dedicated token or treasury integration would be needed for actual transfers.
        // uint256 rewardForKeeper = 0; 
        // bytes32 serviceFeeKey = "serviceFee";
        // uint256 currentServiceFee = protocolParameters[serviceFeeKey].currentValue;

        // Iterate backwards to safely remove expired policies
        for (int i = int(policiesByStatus[PolicyStatus.Active].length) - 1; i >= 0; i--) {
            uint256 policyId = policiesByStatus[PolicyStatus.Active][uint256(i)];
            AdaptivePolicy storage policy = adaptivePolicies[policyId];

            if (block.timestamp >= policy.expirationTimestamp) {
                // Policy has expired
                policy.status = PolicyStatus.Expired;
                _removePolicyFromStatusList(policyId, PolicyStatus.Active);
                policiesByStatus[PolicyStatus.Expired].push(policyId);
                // Optionally refund bond to proposer for expired policies (or keep as a fee if short-lived)
                // For now, let's keep it simple and assume bond is for successful activation only.
                continue; // Move to the next policy
            }

            // Evaluate condition and apply action
            if (_evaluatePolicyCondition(policy.condition)) {
                _applyPolicyAction(policy.action);
                // rewardForKeeper = rewardForKeeper.add(currentServiceFee.div(100)); // Small cut of fee
            }
        }
    }

    /**
     * @dev Challenges an active policy if a user believes it's ineffective or harmful.
     *      Requires a challenge bond.
     * @param _policyId The ID of the policy to challenge.
     * @param _challengeBond The amount of tokens to bond for the challenge.
     */
    function challengeIneffectivePolicy(uint256 _policyId, uint256 _challengeBond) external whenNotPaused {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        require(policy.status == PolicyStatus.Active, "Policy not active");
        require(policy.challenger == address(0), "Policy already challenged");
        require(_challengeBond > 0, "Challenge bond must be positive");
        require(token.transferFrom(msg.sender, address(this), _challengeBond), "Challenge bond transfer failed");

        policy.status = PolicyStatus.Challenged;
        policy.challenger = msg.sender;
        policy.challengeBond = _challengeBond;
        
        _removePolicyFromStatusList(_policyId, PolicyStatus.Active);
        policiesByStatus[PolicyStatus.Challenged].push(_policyId);

        emit PolicyChallenged(_policyId, msg.sender, _challengeBond);
    }

    /**
     * @dev Resolves a policy challenge. This function would typically be called by a DAO or multisig,
     *      potentially after off-chain analysis or further voting.
     * @param _policyId The ID of the challenged policy.
     * @param _isChallengerCorrect True if the challenger's claim is valid, false otherwise.
     */
    function resolveChallenge(uint256 _policyId, bool _isChallengerCorrect) external onlyOwner whenNotPaused {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        require(policy.status == PolicyStatus.Challenged, "Policy not in challenged state");
        // Add a time limit for resolution:
        require(block.timestamp <= policy.activationTimestamp + CHALLENGE_RESOLUTION_PERIOD, "Challenge resolution period expired");

        if (_isChallengerCorrect) {
            // Challenger was correct: deactivate policy, reward challenger, penalize proposer
            deactivatePolicy(_policyId); // This also removes it from Challenged list
            require(token.transfer(policy.challenger, policy.challengeBond.mul(105).div(100)), "Challenger reward failed"); // 5% profit
            // Proposer's original bond (policy.bondingAmount) could be slashed or partially refunded
            // For this example, let's just slash a portion of their reputation.
            policyStewardReputation[policy.proposer] = policyStewardReputation[policy.proposer].sub(50); // Reputation loss
            emit ReputationLost(policy.proposer, 50);
        } else {
            // Challenger was incorrect: reactivate policy, return proposer's bond (if any, as it was refunded earlier for active policies), penalize challenger
            policy.status = PolicyStatus.Active;
            _removePolicyFromStatusList(_policyId, PolicyStatus.Challenged);
            policiesByStatus[PolicyStatus.Active].push(_policyId);
            
            // Challenger's bond is forfeit and potentially distributed or burned
            // For now, it stays in the contract.
            policyStewardReputation[policy.challenger] = policyStewardReputation[policy.challenger].sub(25); // Reputation loss
            emit ReputationLost(policy.challenger, 25);
        }
        policy.challenger = address(0); // Reset challenger
        policy.challengeBond = 0; // Reset bond
        emit PolicyChallengeResolved(_policyId, msg.sender, _isChallengerCorrect);
    }

    // --- Internal Policy Helper Functions ---

    /**
     * @dev Internal function to evaluate a policy's condition.
     * @param _condition The PolicyCondition struct to evaluate.
     * @return True if the condition is met, false otherwise.
     */
    function _evaluatePolicyCondition(PolicyCondition calldata _condition) internal view returns (bool) {
        uint252 metricValue = _getOnChainMetric(_condition.metricType);

        if (_condition.op == Operator.GreaterThan) {
            return metricValue > _condition.thresholdValue;
        } else if (_condition.op == Operator.LessThan) {
            return metricValue < _condition.thresholdValue;
        } else if (_condition.op == Operator.EqualTo) {
            return metricValue == _condition.thresholdValue;
        }
        return false; // Should not happen
    }

    /**
     * @dev Internal function to apply a policy's action to the target parameter.
     * @param _action The PolicyAction struct to apply.
     */
    function _applyPolicyAction(PolicyAction calldata _action) internal {
        ProtocolParameter storage param = protocolParameters[_action.paramKey];
        uint256 currentVal = param.currentValue;
        uint256 newVal;

        if (_action.actionType == ActionType.Set) {
            newVal = _action.actionValue;
        } else if (_action.actionType == ActionType.IncreaseByPercentage) {
            // actionValue is percentage * 100 (e.g., 500 for 5%)
            newVal = currentVal.mul(10000 + _action.actionValue).div(10000);
        } else if (_action.actionType == ActionType.DecreaseByPercentage) {
            // actionValue is percentage * 100
            newVal = currentVal.mul(10000 - _action.actionValue).div(10000);
        } else if (_action.actionType == ActionType.MultiplyByFactor) {
            // actionValue is factor * 10000 (e.g., 10500 for 1.05)
            newVal = currentVal.mul(_action.actionValue).div(10000);
        } else if (_action.actionType == ActionType.DivideByFactor) {
            // actionValue is factor * 10000
            newVal = currentVal.mul(10000).div(_action.actionValue); // currentVal / factor
        } else {
            revert("Invalid action type");
        }
        _updateParameterInternal(_action.paramKey, newVal, address(this)); // Updater is the contract itself for policy actions
    }

    /**
     * @dev Helper to remove a policy ID from a status-specific list.
     * @param _policyId The ID of the policy to remove.
     * @param _status The status list from which to remove.
     */
    function _removePolicyFromStatusList(uint256 _policyId, PolicyStatus _status) internal {
        uint256[] storage policyList = policiesByStatus[_status];
        for (uint256 i = 0; i < policyList.length; i++) {
            if (policyList[i] == _policyId) {
                policyList[i] = policyList[policyList.length - 1];
                policyList.pop();
                break;
            }
        }
    }


    // --- 3. Economic & Incentive Layer Functions ---

    /**
     * @dev Deposits tokens into the protocol. These tokens are used for calculating rewards.
     * @param _amount The amount of tokens to deposit.
     */
    function deposit(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Deposit amount must be positive");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        userBalances[msg.sender] = userBalances[msg.sender].add(_amount);
        totalProtocolValueLocked = totalProtocolValueLocked.add(_amount);
        // Potentially calculate and add pending rewards here based on current state and time
        // For simplicity, rewards are calculated on claim.

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Withdraws tokens from the protocol. Users must claim rewards separately.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be positive");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");

        userBalances[msg.sender] = userBalances[msg.sender].sub(_amount);
        totalProtocolValueLocked = totalProtocolValueLocked.sub(_amount);

        emit Withdrawal(msg.sender, _amount);
    }

    /**
     * @dev Claims accumulated rewards for the user.
     *      Reward calculation logic can be complex, for this example, a simplified linear growth.
     *      In a real system, it would be based on TVL, time, active policies, etc.
     */
    function claimRewards() external whenNotPaused {
        // This is a simplified reward calculation. In a real system, this would be:
        // - Based on time since last claim/deposit
        // - Based on current 'rewardRate' parameter
        // - Potentially boosted by reputation or other factors
        uint252 estimatedRewards = getEstimatedRewards(msg.sender); // Example: 1 token for now
        require(estimatedRewards > 0, "No rewards to claim");

        userRewardsPending[msg.sender] = userRewardsPending[msg.sender].sub(estimatedRewards); // Deduct what's claimed
        require(token.transfer(msg.sender, estimatedRewards), "Reward transfer failed");
        
        emit RewardsClaimed(msg.sender, estimatedRewards);
    }

    // --- 4. Reputation & Gamification Functions ---

    /**
     * @dev Allows for a less formal submission of optimization ideas.
     *      Could be manually reviewed by governance for small ad-hoc rewards.
     * @param _suggestionDetails A string containing the suggestion.
     */
    function submitOptimizationSuggestion(string calldata _suggestionDetails) external whenNotPaused {
        // This is primarily for off-chain interaction and recognition.
        // On-chain, it could log the suggestion or allow for a small reputation gain.
        // For now, it's a simple log.
        emit Log("OptimizationSuggestion", bytes(_suggestionDetails));
        // Potentially: policyStewardReputation[msg.sender] = policyStewardReputation[msg.sender].add(1);
    }

    // --- 5. Oracle and Metric Integration (Internal/View) ---

    /**
     * @dev Internal function to get the current value of various on-chain metrics.
     *      Handles integration with Chainlink for external data.
     * @param _type The type of metric to retrieve.
     * @return The current value of the metric.
     */
    function _getOnChainMetric(MetricType _type) internal view returns (uint252) {
        if (_type == MetricType.BlockTimestamp) {
            return block.timestamp;
        } else if (_type == MetricType.BlockGasPrice) {
            return block.gasprice;
        } else if (_type == MetricType.TokenPriceUSD) {
            (, int256 price, , , ) = priceFeed.latestRoundData();
            require(price > 0, "Invalid price feed data");
            return uint252(price); // Chainlink prices are typically multiplied by 10^8, fits in uint252
        } else if (_type == MetricType.ProtocolTVL) {
            return totalProtocolValueLocked; // Simplified for this example, true TVL might involve multiple assets
        } else if (_type == MetricType.TreasuryBalance) {
            return token.balanceOf(address(this));
        } else if (_type == MetricType.UserCount) {
            // This is a simplified representation. A real user count would require
            // a more sophisticated tracking mechanism (e.g., incrementing a counter
            // on first deposit, decrementing on full withdrawal).
            // For now, we'll return a placeholder.
            return 100; // Placeholder
        }
        revert("Unknown metric type");
    }

    // --- 6. Emergency & Administration Functions ---

    /**
     * @dev Pauses contract functions in an emergency. Only callable by owner.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract functions. Only callable by owner.
     */
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the required bonding amount for proposing new policies.
     * @param _newAmount The new bonding requirement in native tokens.
     */
    function setPolicyBondingRequirement(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Bonding requirement must be positive");
        policyBondingRequirement = _newAmount;
    }

    /**
     * @dev Sets the minimum support percentage required for a policy to be activated.
     * @param _newThreshold The new threshold (e.g., 6000 for 60%).
     */
    function setPolicyActivationThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0 && _newThreshold <= 10000, "Threshold must be between 1 and 10000");
        policyActivationThreshold = _newThreshold;
    }

    /**
     * @dev Sets the base multiplier for calculating rewards.
     * @param _multiplier The new base reward multiplier (e.g., 10000 for 1x).
     */
    function setRewardMultiplier(uint256 _multiplier) external onlyOwner {
        baseRewardMultiplier = _multiplier;
    }

    // --- 7. Read-Only & Transparency Functions ---

    /**
     * @dev Returns the current effective service fee percentage.
     * @return The service fee value (e.g., 100 for 1%).
     */
    function getEffectiveServiceFee() external view returns (uint256) {
        bytes32 serviceFeeKey = "serviceFee";
        return protocolParameters[serviceFeeKey].currentValue;
    }

    /**
     * @dev Returns the details of a specific policy.
     * @param _policyId The ID of the policy.
     * @return Policy details.
     */
    function getPolicyDetails(uint256 _policyId)
        external
        view
        returns (
            uint256 id,
            string memory description,
            address proposer,
            PolicyCondition memory condition,
            PolicyAction memory action,
            PolicyStatus status,
            uint256 bondingAmount,
            uint256 proposalTimestamp,
            uint256 activationTimestamp,
            uint256 expirationTimestamp,
            uint256 supportVotes,
            uint256 againstVotes,
            address challenger,
            uint256 challengeBond
        )
    {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        return (
            policy.id,
            policy.description,
            policy.proposer,
            policy.condition,
            policy.action,
            policy.status,
            policy.bondingAmount,
            policy.proposalTimestamp,
            policy.activationTimestamp,
            policy.expirationTimestamp,
            policy.supportVotes,
            policy.againstVotes,
            policy.challenger,
            policy.challengeBond
        );
    }

    /**
     * @dev Returns a list of policy IDs that match a given status.
     * @param _status The status to filter by (e.g., Proposed, Active).
     * @return An array of policy IDs.
     */
    function getPoliciesByStatus(PolicyStatus _status) external view returns (uint256[] memory) {
        return policiesByStatus[_status];
    }

    /**
     * @dev Returns a user's current deposited balance.
     * @param _user The address of the user.
     * @return The user's balance.
     */
    function getUserBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }

    /**
     * @dev Returns a user's estimated pending rewards. (Simplified for this example)
     *      In a real system, this would involve complex calculations based on time,
     *      current reward rate, TVL, and user's stake.
     *      For now, it's a placeholder returning a static value for testing.
     *      A more robust implementation would involve a rewards per share model or
     *      accumulated interest per second for each user.
     * @param _user The address of the user.
     * @return The estimated rewards.
     */
    function getEstimatedRewards(address _user) public view returns (uint252) {
        // Simplified: 1 token reward per 100 tokens staked, for example.
        // In a real dApp, this would be:
        // (userBalances[_user] * rewardRate * timeElapsed * baseRewardMultiplier) / denomenator
        // This would require lastInteractionTimestamp per user and a global accumulated reward index.
        uint256 rewardRate = protocolParameters["rewardRate"].currentValue; // e.g., 50 (0.5%)
        uint256 userStaked = userBalances[_user];
        if (userStaked == 0) return 0;

        // Arbitrary small reward calculation to make it functional
        // e.g., 0.001% of staked amount as pending reward
        uint252 pending = uint252(userStaked.mul(rewardRate).div(100000)); // rewardRate is in basis points of percent, e.g. 50 = 0.5%
        return userRewardsPending[_user].add(pending); // Add to existing pending
    }

    /**
     * @dev Returns the policy steward reputation score for a given user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getPolicyStewardReputation(address _user) external view returns (uint256) {
        return policyStewardReputation[_user];
    }

    /**
     * @dev Returns the current balance of the protocol's native token treasury.
     * @return The treasury balance.
     */
    function getProtocolTreasuryBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Custom Error for logging
    event Log(string eventName, bytes data);
}

// Basic Math library for SafeMath functionality on modern Solidity
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```