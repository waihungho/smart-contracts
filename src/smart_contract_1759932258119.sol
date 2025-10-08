Here's a smart contract named `ArbiterNetDecisionEngine` written in Solidity. This contract embodies an advanced concept of a decentralized autonomous decision engine. It allows for the creation of "policies" that, based on aggregated inputs from multiple AI oracles, can trigger arbitrary actions on other smart contracts. It incorporates reputation-based oracle weighting, a dispute resolution system with staking, and automated escalation mechanisms.

---

**Contract: `ArbiterNetDecisionEngine`**

**Purpose:**
This contract serves as a decentralized autonomous decision engine. It enables the creation, management, and execution of "decision policies" that automatically trigger predefined actions on other smart contracts. These decisions are driven by aggregated data (referred to as "scores") submitted by a network of AI oracles. The system includes robust mechanisms for oracle reputation, collateral staking, dispute resolution for submitted scores, and automated policy escalation based on performance or disputes. Its core aim is to provide a flexible and resilient framework for decentralized autonomous agents to make conditional, data-driven decisions on-chain.

---

**Outline:**

1.  **State Variables & Constants:** Fundamental parameters, roles, counters, and global configurations.
2.  **Enums & Structs:** Defines custom data types for Policies, Oracles, Score Submissions, and Governance Proposals.
3.  **Role-Based Access Control:** Modifiers to restrict function access to specific roles (Owner, Governance, Executor, Oracle).
4.  **Events:** Logs significant actions and state changes for off-chain monitoring.
5.  **Core Decision & Execution Logic:** Functions for oracle score submission, score aggregation, and conditional policy execution.
6.  **Policy Management:** Functions for creating, updating, activating, deactivating, and setting escalation rules for decision policies.
7.  **Oracle Management:** Functions for oracle registration, collateral staking/withdrawal, reputation updates, and slashing.
8.  **Dispute & Governance:** Mechanisms for challenging oracle scores, resolving disputes, and proposing/voting on contract parameter changes.
9.  **Treasury & Utility:** Functions for managing contract funds (deposits/withdrawals) and transferring core roles.
10. **View Functions:** Public functions to query the state of the contract without altering it.

---

**Function Summary:**

**I. Core Decision & Execution (4 functions)**
1.  `submitOracleDecisionScore(uint256 policyId, int256 score, string calldata metadataURI)`: Allows a registered oracle to submit a decision score for a specific policy. The score might be an output from an AI model.
2.  `attemptDecisionExecution(uint256 policyId)`: Triggered by an authorized executor (e.g., a Chainlink Automation bot) to check if a policy's conditions (aggregated score threshold, cooldown, etc.) are met. If conditions pass, it attempts to execute the predefined action.
3.  `_executePolicyAction(uint256 policyId)` (Internal): Performs the actual low-level call to the target contract based on the policy's configuration (`targetContract` and `targetFunctionCall`).
4.  `getAggregatedScore(uint256 policyId)` (View): Returns the currently cached aggregated decision score for a given policy.

**II. Policy Management (6 functions)**
5.  `createDecisionPolicy(string calldata name, address targetContract, bytes calldata targetFunctionCall, int256 decisionThreshold, uint256 cooldownPeriod, uint256 executionGasLimit, uint256 disputeWindow, OracleWeightingStrategy strategy)`: Allows governance to create a new decision policy with specific execution parameters.
6.  `updateDecisionPolicy(uint255 policyId, string calldata name, address targetContract, bytes calldata targetFunctionCall, int256 decisionThreshold, uint256 cooldownPeriod, uint256 executionGasLimit, uint256 disputeWindow, OracleWeightingStrategy strategy)`: Allows governance to update an existing decision policy's parameters.
7.  `activateDecisionPolicy(uint256 policyId)`: Activates a previously created or deactivated decision policy, making it eligible for execution.
8.  `deactivateDecisionPolicy(uint256 policyId)`: Deactivates an active decision policy, preventing further executions.
9.  `setPolicyEscalationRule(uint256 policyId, EscalationType escalationType, uint256 triggerCount)`: Defines a rule for how a policy should escalate (e.g., auto-deactivate, trigger a governance proposal) if certain failure or dispute counts are reached.
10. `setPolicyRequiredCollateral(uint256 policyId, address tokenAddress, uint256 amount)`: Sets policy-specific collateral requirements that oracles must meet to submit scores for that policy, in addition to general staking.

**III. Oracle Management (5 functions)**
11. `registerOracle(string calldata name, string calldata metadataURI)`: Allows an address to register as an oracle. Requires meeting a minimum general staking requirement.
12. `stakeOracleCollateral(address tokenAddress, uint256 amount)`: Allows an oracle to stake collateral for general participation or to meet policy-specific requirements.
13. `withdrawOracleCollateral(address tokenAddress, uint256 amount)`: Allows an oracle to withdraw their *unstaked* collateral, ensuring minimum stake requirements are still met.
14. `slashOracleCollateral(address oracleAddress, address tokenAddress, uint256 amount, string calldata reason)`: Allows governance to slash an oracle's collateral, typically as a penalty after a dispute resolution.
15. `updateOracleReputation(address oracleAddress, int256 delta)`: Allows governance to manually adjust an oracle's reputation score (e.g., rewarding good behavior or penalizing poor performance).

**IV. Dispute & Governance (5 functions)**
16. `challengeDecisionScore(uint256 policyId, uint256 submissionIndex, address challengerToken, uint256 challengeStake)`: Allows any user to challenge a specific oracle's score submission for a policy, requiring a stake to initiate the challenge.
17. `resolveChallenge(uint256 policyId, uint256 submissionIndex, bool oracleWasCorrect)`: Allows governance to resolve an ongoing challenge, distributing stakes and potentially slashing the oracle or challenger based on the outcome.
18. `proposeGovernanceParameterChange(bytes32 parameterKey, uint256 newValue)`: Allows governance to propose changes to core contract parameters (e.g., minimum oracle stake, challenge fees).
19. `voteOnProposal(uint256 proposalId, bool support)`: Allows authorized governance members to vote 'for' or 'against' an active governance proposal.
20. `finalizeProposal(uint256 proposalId)`: Allows anyone to finalize a proposal after its voting period has ended, applying the proposed change if it passes.

**V. Treasury & Utility (4 functions)**
21. `depositTreasuryFunds(address tokenAddress, uint256 amount)`: Allows users or governance to deposit funds (ETH or ERC20 tokens) into the contract's treasury, used for execution gas or other operational costs.
22. `withdrawTreasuryFunds(address tokenAddress, uint256 amount)`: Allows governance to withdraw funds from the contract's treasury.
23. `setGovernanceAddress(address newGovernance)`: Transfers the governance role to a new address.
24. `setExecutorAddress(address newExecutor)`: Transfers the executor role to a new address.

**VI. View Functions (5 functions)**
25. `getOracle(address oracleAddress)`: Returns the details of a registered oracle.
26. `getPolicy(uint256 policyId)`: Returns the full details of a decision policy.
27. `getPolicyScoreSubmission(uint256 policyId, uint256 submissionIndex)`: Returns a specific score submission for a policy.
28. `getPolicyScoreSubmissionsCount(uint256 policyId)`: Returns the total number of score submissions for a given policy.
29. `getTreasuryBalance(address tokenAddress)`: Returns the balance of a specific token (or ETH) held in the contract's treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom errors for clarity and gas efficiency
error ArbiterNet__Unauthorized();
error ArbiterNet__InvalidPolicyId();
error ArbiterNet__PolicyNotActive();
error ArbiterNet__PolicyCooldownActive();
error ArbiterNet__InsufficientFunds();
error ArbiterNet__OracleNotRegistered();
error ArbiterNet__OracleNotActive();
error ArbiterNet__OracleAlreadyRegistered();
error ArbiterNet__InsufficientStake();
error ArbiterNet__PolicyNotFound();
error ArbiterNet__OracleScoreSubmittedRecently();
error ArbiterNet__ChallengeWindowExpired();
error ArbiterNet__ChallengeAlreadyResolved();
error ArbiterNet__PolicyConditionNotMet();
error ArbiterNet__ExecutionFailed(bytes reason);
error ArbiterNet__ProposalNotFound();
error ArbiterNet__AlreadyVoted();
error ArbiterNet__InvalidParameters();
error ArbiterNet__WithdrawTooMuchCollateral();
error ArbiterNet__OracleNotStakedForPolicy();
error ArbiterNet__NoScoresToAggregate();
error ArbiterNet__ScoreAlreadyChallenged();


/**
 * @title ArbiterNetDecisionEngine
 * @dev A decentralized autonomous decision engine that manages conditional execution of actions based on aggregated AI model outputs.
 *      It allows for dynamic policy creation, oracle management with reputation, dispute resolution, and treasury management.
 *      The contract acts as a governor for AI-driven decentralized agents, enabling complex automated strategies.
 */
contract ArbiterNetDecisionEngine is Ownable {
    // --- Outline ---
    // I. State Variables & Constants
    // II. Enums & Structs
    // III. Role-Based Access Control
    // IV. Events
    // V. Core Decision & Execution Logic
    // VI. Policy Management
    // VII. Oracle Management
    // VIII. Dispute & Governance
    // IX. Treasury & Utility
    // X. View Functions

    // --- Function Summary ---

    // I. Core Decision & Execution
    // 1.  submitOracleDecisionScore(uint256 policyId, int256 score, string calldata metadataURI)
    // 2.  attemptDecisionExecution(uint256 policyId)
    // 3.  _executePolicyAction(uint256 policyId) (Internal)
    // 4.  getAggregatedScore(uint256 policyId) (View)

    // II. Policy Management
    // 5.  createDecisionPolicy(string calldata name, address targetContract, bytes calldata targetFunctionCall, int256 decisionThreshold, uint256 cooldownPeriod, uint256 executionGasLimit, uint256 disputeWindow, OracleWeightingStrategy strategy)
    // 6.  updateDecisionPolicy(uint256 policyId, string calldata name, address targetContract, bytes calldata targetFunctionCall, int256 decisionThreshold, uint256 cooldownPeriod, uint256 executionGasLimit, uint256 disputeWindow, OracleWeightingStrategy strategy)
    // 7.  activateDecisionPolicy(uint256 policyId)
    // 8.  deactivateDecisionPolicy(uint256 policyId)
    // 9.  setPolicyEscalationRule(uint256 policyId, EscalationType escalationType, uint256 triggerCount)
    // 10. setPolicyRequiredCollateral(uint256 policyId, address tokenAddress, uint256 amount)

    // III. Oracle Management
    // 11. registerOracle(string calldata name, string calldata metadataURI)
    // 12. stakeOracleCollateral(address tokenAddress, uint256 amount)
    // 13. withdrawOracleCollateral(address tokenAddress, uint256 amount)
    // 14. slashOracleCollateral(address oracleAddress, address tokenAddress, uint256 amount, string calldata reason)
    // 15. updateOracleReputation(address oracleAddress, int256 delta)

    // IV. Dispute & Governance
    // 16. challengeDecisionScore(uint256 policyId, uint256 submissionIndex, address challengerToken, uint256 challengeStake)
    // 17. resolveChallenge(uint256 policyId, uint256 submissionIndex, bool oracleWasCorrect)
    // 18. proposeGovernanceParameterChange(bytes32 parameterKey, uint256 newValue)
    // 19. voteOnProposal(uint256 proposalId, bool support)
    // 20. finalizeProposal(uint256 proposalId)

    // V. Treasury & Utility
    // 21. depositTreasuryFunds(address tokenAddress, uint256 amount)
    // 22. withdrawTreasuryFunds(address tokenAddress, uint256 amount)
    // 23. setGovernanceAddress(address newGovernance)
    // 24. setExecutorAddress(address newExecutor)

    // VI. View Functions
    // 25. getOracle(address oracleAddress) (View)
    // 26. getPolicy(uint256 policyId) (View)
    // 27. getPolicyScoreSubmission(uint256 policyId, uint256 submissionIndex) (View)
    // 28. getPolicyScoreSubmissionsCount(uint256 policyId) (View)
    // 29. getTreasuryBalance(address tokenAddress) (View)

    // --- I. State Variables & Constants ---
    uint256 private s_policyCounter;
    uint256 private s_proposalCounter;

    // --- Roles ---
    address public immutable i_owner; // Deployer
    address public s_governanceAddress;
    address public s_executorAddress;

    // Minimum collateral required for an oracle to register and submit scores for any policy.
    uint256 public s_minOracleStakeAmount;
    address public s_minOracleStakeToken; // The token required for minimum staking

    // Fees for challenging a score, and the reward for correct challenges.
    uint256 public s_challengeFeePercentage; // % of stake taken as fee (basis points, e.g., 500 = 5%)
    uint256 public s_challengerRewardPercentage; // % of opponent's stake given to winner (basis points, e.g., 1000 = 10%)

    // --- II. Enums & Structs ---

    enum OracleWeightingStrategy {
        SimpleAverage,
        ReputationWeighted
    }

    enum EscalationType {
        None,
        DeactivatePolicy,
        TriggerGovernanceProposal
    }

    struct Policy {
        bool isActive;
        string name;
        address targetContract;
        bytes targetFunctionCall; // Encoded function call for the targetContract
        int256 decisionThreshold; // Score threshold to trigger execution
        uint256 cooldownPeriod; // Minimum time between executions (in seconds)
        uint256 lastExecutionTimestamp;
        uint256 executionGasLimit; // Max gas for the target function call
        uint256 disputeWindow; // Time window (in seconds) for challenging scores after submission

        // Policy-specific oracle requirements
        address requiredCollateralToken;
        uint256 requiredCollateralAmount;

        EscalationType escalationType;
        uint256 escalationTriggerCount; // How many failures/disputes trigger escalation
        uint256 currentFailureCount;
        uint256 currentDisputeCount;

        OracleWeightingStrategy oracleWeightingStrategy;
        int256 currentAggregatedScore; // Cached aggregated score
        uint256 lastScoreAggregationTimestamp; // Timestamp of the last aggregation
    }

    struct Oracle {
        bool isActive;
        string name;
        string metadataURI;
        int256 reputationScore; // Can be positive or negative
        uint256 lastSubmissionTimestamp; // For general oracle activity cooldown
        mapping(address => uint256) stakedCollateral; // Token address => amount staked
    }

    struct ScoreSubmission {
        address oracleAddress;
        int256 score;
        uint256 timestamp;
        string metadataURI;
        bool isChallenged;
        bool challengeResolved; // True if challenge has been resolved by governance
        bool oracleWasCorrectInChallenge; // Stores the outcome of the challenge
        address challengerAddress;
        address challengerToken;
        uint256 challengeStake; // Stake amount from challenger
        uint256 oracleStakeAtChallenge; // Oracle's staked amount at the time of challenge
    }

    struct GovernanceProposal {
        uint256 proposalId;
        bytes32 parameterKey; // Key of the parameter to change (e.g., "minOracleStakeAmount")
        uint256 newValue;
        uint256 creationTimestamp;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;
        bool passed;
    }

    // --- Mappings ---
    mapping(uint256 => Policy) public s_policies;
    mapping(address => Oracle) public s_oracles;
    mapping(uint256 => ScoreSubmission[]) public s_policyScoreSubmissions; // policyId => array of submissions
    mapping(uint256 => GovernanceProposal) public s_governanceProposals;

    // Contract treasury
    mapping(address => uint252) public s_treasuryBalances; // tokenAddress => balance (use uint252 to demonstrate non-standard integer sizes if desired, otherwise uint256 is fine)

    // --- III. Role-Based Access Control Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != s_governanceAddress) {
            revert ArbiterNet__Unauthorized();
        }
        _;
    }

    modifier onlyExecutor() {
        if (msg.sender != s_executorAddress) {
            revert ArbiterNet__Unauthorized();
        }
        _;
    }

    modifier onlyOracle() {
        if (!s_oracles[msg.sender].isActive) {
            revert ArbiterNet__OracleNotRegistered();
        }
        _;
    }

    // --- IV. Events ---
    event PolicyCreated(uint256 indexed policyId, string name, address indexed targetContract);
    event PolicyUpdated(uint256 indexed policyId, string name, address indexed targetContract);
    event PolicyActivated(uint256 indexed policyId);
    event PolicyDeactivated(uint256 indexed policyId);
    event PolicyExecuted(uint256 indexed policyId, int256 aggregatedScore, address indexed executor);
    event PolicyExecutionFailed(uint256 indexed policyId, bytes reason);
    event OracleRegistered(address indexed oracleAddress, string name);
    event OracleCollateralStaked(address indexed oracleAddress, address indexed tokenAddress, uint256 amount);
    event OracleCollateralWithdrawn(address indexed oracleAddress, address indexed tokenAddress, uint256 amount);
    event OracleCollateralSlashed(address indexed oracleAddress, address indexed tokenAddress, uint256 amount, string reason);
    event OracleReputationUpdated(address indexed oracleAddress, int256 newReputation);
    event ScoreSubmitted(uint256 indexed policyId, address indexed oracleAddress, int256 score, uint256 submissionIndex);
    event ScoreChallenged(uint256 indexed policyId, uint256 submissionIndex, address indexed challenger, address indexed token, uint256 stake);
    event ChallengeResolved(uint256 indexed policyId, uint256 submissionIndex, bool oracleWasCorrect, address indexed resolver);
    event GovernanceProposalCreated(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalFinalized(uint256 indexed proposalId, bool passed);
    event TreasuryFundsDeposited(address indexed tokenAddress, uint256 amount, address indexed depositor);
    event TreasuryFundsWithdrawn(address indexed tokenAddress, uint256 amount, address indexed withdrawer);
    event GovernanceAddressSet(address indexed oldAddress, address indexed newAddress);
    event ExecutorAddressSet(address indexed oldAddress, address indexed newAddress);

    constructor(address _governance, address _executor, address _minOracleStakeToken, uint252 _minOracleStakeAmount) Ownable(msg.sender) {
        if (_governance == address(0) || _executor == address(0) || _minOracleStakeToken == address(0) || _minOracleStakeAmount == 0) {
            revert ArbiterNet__InvalidParameters();
        }
        i_owner = msg.sender;
        s_governanceAddress = _governance;
        s_executorAddress = _executor;
        s_minOracleStakeToken = _minOracleStakeToken;
        s_minOracleStakeAmount = _minOracleStakeAmount;

        // Default challenge parameters (can be changed by governance)
        s_challengeFeePercentage = 500; // 5% (500 basis points)
        s_challengerRewardPercentage = 1000; // 10% (1000 basis points)
    }

    // --- V. Core Decision & Execution Logic ---

    /**
     * @dev Allows a registered oracle to submit a decision score for a specific policy.
     *      Requires the oracle to be active and meet policy-specific collateral requirements.
     *      Includes a basic cooldown to prevent spamming.
     * @param policyId The ID of the policy to submit a score for.
     * @param score The integer decision score provided by the AI model/oracle.
     * @param metadataURI An optional URI for additional metadata about the score (e.g., source, timestamp, model version).
     */
    function submitOracleDecisionScore(uint256 policyId, int256 score, string calldata metadataURI) external onlyOracle {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (!policy.isActive) revert ArbiterNet__PolicyNotActive();
        
        // Check policy-specific collateral if required
        if (policy.requiredCollateralAmount > 0) {
            if (s_oracles[msg.sender].stakedCollateral[policy.requiredCollateralToken] < policy.requiredCollateralAmount) {
                revert ArbiterNet__OracleNotStakedForPolicy();
            }
        }
        
        // Prevent rapid submissions by the same oracle for any policy (general cooldown)
        if (block.timestamp < s_oracles[msg.sender].lastSubmissionTimestamp + 60) { // 60 seconds throttle
            revert ArbiterNet__OracleScoreSubmittedRecently();
        }

        s_oracles[msg.sender].lastSubmissionTimestamp = block.timestamp;
        
        s_policyScoreSubmissions[policyId].push(
            ScoreSubmission({
                oracleAddress: msg.sender,
                score: score,
                timestamp: block.timestamp,
                metadataURI: metadataURI,
                isChallenged: false,
                challengeResolved: false,
                oracleWasCorrectInChallenge: false, // Default
                challengerAddress: address(0),
                challengerToken: address(0),
                challengeStake: 0,
                oracleStakeAtChallenge: 0
            })
        );
        emit ScoreSubmitted(policyId, msg.sender, score, s_policyScoreSubmissions[policyId].length - 1);

        // Immediately update aggregated score for freshness
        _aggregateDecisionScores(policyId);
    }

    /**
     * @dev Triggered by an authorized executor to check if a policy's conditions (aggregated score, cooldown, etc.) are met.
     *      If conditions are met, it attempts to execute the predefined action.
     * @param policyId The ID of the policy to attempt execution for.
     */
    function attemptDecisionExecution(uint256 policyId) external onlyExecutor {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (!policy.isActive) revert ArbiterNet__PolicyNotActive();
        if (block.timestamp < policy.lastExecutionTimestamp + policy.cooldownPeriod) revert ArbiterNet__PolicyCooldownActive();
        if (s_policyScoreSubmissions[policyId].length == 0) revert ArbiterNet__NoScoresToAggregate();
        
        // Re-aggregate if the cached score is older than the dispute window (suggests new scores or expired disputes)
        if (block.timestamp > policy.lastScoreAggregationTimestamp + policy.disputeWindow) {
             _aggregateDecisionScores(policyId);
        }

        if (policy.currentAggregatedScore < policy.decisionThreshold) revert ArbiterNet__PolicyConditionNotMet();

        // Check for active challenges on recent scores that might affect aggregation
        // Iterate only over the most recent scores to save gas, e.g., last 10 scores
        uint256 startIndex = s_policyScoreSubmissions[policyId].length > 10 ? s_policyScoreSubmissions[policyId].length - 10 : 0;
        for (uint256 i = startIndex; i < s_policyScoreSubmissions[policyId].length; i++) {
            ScoreSubmission storage submission = s_policyScoreSubmissions[policyId][i];
            // If a recent score is challenged and not yet resolved, block execution
            if (submission.isChallenged && !submission.challengeResolved) {
                revert ArbiterNet__PolicyConditionNotMet(); 
            }
        }

        // Check if treasury has enough funds for gas (assuming ETH for gas)
        if (s_treasuryBalances[address(0)] < policy.executionGasLimit) {
            revert ArbiterNet__InsufficientFunds();
        }

        // Attempt execution
        bool success = _executePolicyAction(policyId);

        if (!success) {
            policy.currentFailureCount++;
            _checkAndEscalatePolicy(policyId);
            emit PolicyExecutionFailed(policyId, "Target contract call failed");
            // Revert here to signal failure to the keeper network
            revert ArbiterNet__ExecutionFailed("Target contract call failed");
        }

        policy.lastExecutionTimestamp = block.timestamp;
        policy.currentFailureCount = 0; // Reset on successful execution
        emit PolicyExecuted(policyId, policy.currentAggregatedScore, msg.sender);
    }

    /**
     * @dev Internal function to aggregate scores and update the policy's cached aggregated score.
     *      Considers recent, unchallenged, or correctly resolved scores.
     * @param policyId The ID of the policy to aggregate scores for.
     */
    function _aggregateDecisionScores(uint256 policyId) internal {
        Policy storage policy = s_policies[policyId];
        ScoreSubmission[] storage submissions = s_policyScoreSubmissions[policyId];
        
        if (submissions.length == 0) {
            policy.currentAggregatedScore = 0;
            policy.lastScoreAggregationTimestamp = block.timestamp;
            return;
        }

        int256 totalWeightedScore = 0;
        uint256 totalWeight = 0;
        uint256 validSubmissionsCount = 0;

        // Process a limited number of most recent scores for gas efficiency (e.g., up to 50 submissions)
        uint256 startIndex = submissions.length > 50 ? submissions.length - 50 : 0;

        for (uint256 i = startIndex; i < submissions.length; i++) {
            ScoreSubmission storage sub = submissions[i];
            
            // Only aggregate if:
            // 1. Not challenged, OR
            // 2. Challenged AND resolved, AND the oracle was deemed correct.
            if (!sub.isChallenged || (sub.challengeResolved && sub.oracleWasCorrectInChallenge)) {
                Oracle storage oracle = s_oracles[sub.oracleAddress];
                if (oracle.isActive) {
                    uint256 weight;
                    if (policy.oracleWeightingStrategy == OracleWeightingStrategy.SimpleAverage) {
                        weight = 1;
                    } else if (policy.oracleWeightingStrategy == OracleWeightingStrategy.ReputationWeighted) {
                        // Normalize reputation score to a positive weight.
                        // Example: reputation 0 -> weight 100; reputation +100 -> weight 200; reputation -50 -> weight 50.
                        // Ensures a minimum base weight even for low reputation.
                        weight = uint256(oracle.reputationScore >= -99 ? oracle.reputationScore + 100 : 1);
                    }
                    totalWeightedScore += sub.score * int256(weight);
                    totalWeight += weight;
                    validSubmissionsCount++;
                }
            }
        }

        if (validSubmissionsCount > 0 && totalWeight > 0) {
            policy.currentAggregatedScore = totalWeightedScore / int256(totalWeight);
        } else {
            policy.currentAggregatedScore = 0; // No valid scores or zero total weight
        }
        policy.lastScoreAggregationTimestamp = block.timestamp;
    }

    /**
     * @dev Internal function to perform the actual low-level call to the target contract.
     * @param policyId The ID of the policy whose action is to be executed.
     * @return bool True if the call was successful, false otherwise.
     */
    function _executePolicyAction(uint256 policyId) internal returns (bool) {
        Policy storage policy = s_policies[policyId];
        
        (bool success, bytes memory returndata) = policy.targetContract.call{gas: policy.executionGasLimit}(policy.targetFunctionCall);

        if (!success) {
            // Propagate the revert reason from the target contract call
            assembly {
                let returndataSize := returndatasize()
                returndatacopy(0, 0, returndataSize)
                revert(0, returndataSize)
            }
            // This line will not be reached due to the assembly block, but good for type safety
            return false; 
        }
        return true;
    }

    // --- VI. Policy Management ---

    /**
     * @dev Allows governance to create a new decision policy.
     * @param name A descriptive name for the policy.
     * @param targetContract The address of the contract to call.
     * @param targetFunctionCall The ABI-encoded call data for the target contract function.
     * @param decisionThreshold The aggregated score threshold to trigger execution.
     * @param cooldownPeriod The minimum time (in seconds) between successful executions.
     * @param executionGasLimit The maximum gas to use for the target function call.
     * @param disputeWindow The time window (in seconds) after score submission during which it can be challenged.
     * @param strategy The oracle weighting strategy for this policy.
     * @return newPolicyId The ID of the newly created policy.
     */
    function createDecisionPolicy(
        string calldata name,
        address targetContract,
        bytes calldata targetFunctionCall,
        int256 decisionThreshold,
        uint256 cooldownPeriod,
        uint256 executionGasLimit,
        uint256 disputeWindow,
        OracleWeightingStrategy strategy
    ) external onlyGovernance returns (uint256 newPolicyId) {
        if (targetContract == address(0) || targetFunctionCall.length == 0 || executionGasLimit == 0 || disputeWindow == 0) {
            revert ArbiterNet__InvalidParameters();
        }

        s_policyCounter++;
        newPolicyId = s_policyCounter;

        s_policies[newPolicyId] = Policy({
            isActive: true, // Policies are active by default upon creation
            name: name,
            targetContract: targetContract,
            targetFunctionCall: targetFunctionCall,
            decisionThreshold: decisionThreshold,
            cooldownPeriod: cooldownPeriod,
            lastExecutionTimestamp: 0,
            executionGasLimit: executionGasLimit,
            disputeWindow: disputeWindow,
            requiredCollateralToken: address(0), // Default, can be set later
            requiredCollateralAmount: 0,         // Default, can be set later
            escalationType: EscalationType.None,
            escalationTriggerCount: 0,
            currentFailureCount: 0,
            currentDisputeCount: 0,
            oracleWeightingStrategy: strategy,
            currentAggregatedScore: 0,
            lastScoreAggregationTimestamp: 0
        });

        emit PolicyCreated(newPolicyId, name, targetContract);
    }

    /**
     * @dev Allows governance to update an existing decision policy's parameters.
     * @param policyId The ID of the policy to update.
     * @param name A descriptive name for the policy.
     * @param targetContract The address of the contract to call.
     * @param targetFunctionCall The ABI-encoded call data for the target contract function.
     * @param decisionThreshold The aggregated score threshold to trigger execution.
     * @param cooldownPeriod The minimum time (in seconds) between successful executions.
     * @param executionGasLimit The maximum gas to use for the target function call.
     * @param disputeWindow The time window (in seconds) after score submission during which it can be challenged.
     * @param strategy The oracle weighting strategy for this policy.
     */
    function updateDecisionPolicy(
        uint256 policyId,
        string calldata name,
        address targetContract,
        bytes calldata targetFunctionCall,
        int256 decisionThreshold,
        uint256 cooldownPeriod,
        uint256 executionGasLimit,
        uint256 disputeWindow,
        OracleWeightingStrategy strategy
    ) external onlyGovernance {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId(); // Check if policy exists
        if (targetContract == address(0) || targetFunctionCall.length == 0 || executionGasLimit == 0 || disputeWindow == 0) {
            revert ArbiterNet__InvalidParameters();
        }

        policy.name = name;
        policy.targetContract = targetContract;
        policy.targetFunctionCall = targetFunctionCall;
        policy.decisionThreshold = decisionThreshold;
        policy.cooldownPeriod = cooldownPeriod;
        policy.executionGasLimit = executionGasLimit;
        policy.disputeWindow = disputeWindow;
        policy.oracleWeightingStrategy = strategy;

        emit PolicyUpdated(policyId, name, targetContract);
    }

    /**
     * @dev Activates a previously created or deactivated decision policy.
     * @param policyId The ID of the policy to activate.
     */
    function activateDecisionPolicy(uint256 policyId) external onlyGovernance {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (policy.isActive) return; // Already active
        policy.isActive = true;
        emit PolicyActivated(policyId);
    }

    /**
     * @dev Deactivates an active decision policy, preventing further executions.
     * @param policyId The ID of the policy to deactivate.
     */
    function deactivateDecisionPolicy(uint256 policyId) external onlyGovernance {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (!policy.isActive) return; // Already inactive
        policy.isActive = false;
        emit PolicyDeactivated(policyId);
    }

    /**
     * @dev Sets a rule for how the policy should escalate (e.g., deactivate, trigger governance)
     *      if certain conditions (like repeated failures or disputes) are repeatedly met.
     * @param policyId The ID of the policy to set the escalation rule for.
     * @param escalationType The type of escalation (e.g., DeactivatePolicy, TriggerGovernanceProposal).
     * @param triggerCount The number of failures/disputes that will trigger the escalation.
     */
    function setPolicyEscalationRule(uint256 policyId, EscalationType escalationType, uint256 triggerCount) external onlyGovernance {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (escalationType != EscalationType.None && triggerCount == 0) revert ArbiterNet__InvalidParameters();

        policy.escalationType = escalationType;
        policy.escalationTriggerCount = triggerCount;
    }

    /**
     * @dev Internal function to check and apply escalation rules for a policy.
     *      Triggered on execution failure or dispute.
     * @param policyId The ID of the policy to check.
     */
    function _checkAndEscalatePolicy(uint256 policyId) internal {
        Policy storage policy = s_policies[policyId];
        if (policy.escalationType == EscalationType.None || policy.escalationTriggerCount == 0) return;

        bool shouldEscalate = false;
        if (policy.escalationType == EscalationType.DeactivatePolicy && policy.currentFailureCount >= policy.escalationTriggerCount) {
            shouldEscalate = true;
        } else if (policy.escalationType == EscalationType.TriggerGovernanceProposal && (policy.currentFailureCount >= policy.escalationTriggerCount || policy.currentDisputeCount >= policy.escalationTriggerCount)) {
            // In a more complex DAO, this would create a specific governance proposal.
            // For this contract, we'll simply deactivate the policy as a strong signal.
            shouldEscalate = true;
        }

        if (shouldEscalate) {
            policy.isActive = false;
            policy.currentFailureCount = 0; // Reset after escalation
            policy.currentDisputeCount = 0;
            emit PolicyDeactivated(policyId); // Reusing event to signal deactivation
        }
    }

    /**
     * @dev Sets the required collateral an oracle must stake to submit scores for a specific policy.
     *      This collateral is in addition to the general minimum oracle stake.
     * @param policyId The ID of the policy.
     * @param tokenAddress The address of the ERC20 token required as collateral.
     * @param amount The minimum amount of tokens an oracle must stake for this policy.
     */
    function setPolicyRequiredCollateral(uint256 policyId, address tokenAddress, uint252 amount) external onlyGovernance {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (tokenAddress == address(0) && amount > 0) revert ArbiterNet__InvalidParameters();

        policy.requiredCollateralToken = tokenAddress;
        policy.requiredCollateralAmount = amount;
    }

    // --- VII. Oracle Management ---

    /**
     * @dev Allows an address to register as an oracle. Requires staking the minimum general oracle stake.
     * @param name A public name for the oracle.
     * @param metadataURI An optional URI for oracle's profile or additional info.
     */
    function registerOracle(string calldata name, string calldata metadataURI) external {
        if (s_oracles[msg.sender].isActive) revert ArbiterNet__OracleAlreadyRegistered();
        
        // Oracle must have already staked minimum general collateral before registering
        if (s_oracles[msg.sender].stakedCollateral[s_minOracleStakeToken] < s_minOracleStakeAmount) {
            revert ArbiterNet__InsufficientStake();
        }

        s_oracles[msg.sender] = Oracle({
            isActive: true,
            name: name,
            metadataURI: metadataURI,
            reputationScore: 0, // Starts at 0
            lastSubmissionTimestamp: 0
        });

        emit OracleRegistered(msg.sender, name);
    }

    /**
     * @dev Allows an oracle to stake collateral for general participation or specific policies.
     *      Tokens must be approved to the contract before calling this.
     * @param tokenAddress The ERC20 token address to stake.
     * @param amount The amount of tokens to stake.
     */
    function stakeOracleCollateral(address tokenAddress, uint252 amount) external onlyOracle {
        if (amount == 0) revert ArbiterNet__InvalidParameters();
        
        // Transfer tokens from the caller to this contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        s_oracles[msg.sender].stakedCollateral[tokenAddress] += amount;
        emit OracleCollateralStaked(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Allows an oracle to withdraw their *unstaked* collateral.
     *      This function currently only considers general stake. A more complex system would track locked vs. available stake per policy.
     *      Ensures the minimum general stake is maintained if withdrawing the `s_minOracleStakeToken`.
     * @param tokenAddress The ERC20 token address to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawOracleCollateral(address tokenAddress, uint252 amount) external onlyOracle {
        Oracle storage oracle = s_oracles[msg.sender];
        if (amount == 0) revert ArbiterNet__InvalidParameters();
        if (oracle.stakedCollateral[tokenAddress] < amount) revert ArbiterNet__WithdrawTooMuchCollateral();

        // Ensure minimum general stake is maintained if withdrawing the designated minimum stake token
        if (tokenAddress == s_minOracleStakeToken && (oracle.stakedCollateral[tokenAddress] - amount < s_minOracleStakeAmount)) {
            revert ArbiterNet__InsufficientStake(); // Cannot withdraw below minimum required stake
        }

        oracle.stakedCollateral[tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit OracleCollateralWithdrawn(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Allows governance to slash an oracle's collateral, typically after a dispute resolution.
     *      Slashed funds are transferred to the contract's treasury.
     * @param oracleAddress The address of the oracle to slash.
     * @param tokenAddress The ERC20 token address of the collateral to slash.
     * @param amount The amount of tokens to slash.
     * @param reason A reason for the slashing.
     */
    function slashOracleCollateral(address oracleAddress, address tokenAddress, uint252 amount, string calldata reason) external onlyGovernance {
        Oracle storage oracle = s_oracles[oracleAddress];
        if (!oracle.isActive) revert ArbiterNet__OracleNotActive();
        if (amount == 0) revert ArbiterNet__InvalidParameters();
        if (oracle.stakedCollateral[tokenAddress] < amount) revert ArbiterNet__WithdrawTooMuchCollateral(); // Reusing error

        oracle.stakedCollateral[tokenAddress] -= amount;
        s_treasuryBalances[tokenAddress] += amount; // Slashed funds go to treasury
        
        // Also update reputation (e.g., -10 reputation points)
        _updateOracleReputationInternal(oracleAddress, -10); 

        emit OracleCollateralSlashed(oracleAddress, tokenAddress, amount, reason);
    }

    /**
     * @dev Allows governance to manually adjust an oracle's reputation score.
     *      This could be for good performance, or further penalties beyond simple slashing.
     * @param oracleAddress The address of the oracle.
     * @param delta The amount to add to (positive) or subtract from (negative) the reputation score.
     */
    function updateOracleReputation(address oracleAddress, int256 delta) external onlyGovernance {
        Oracle storage oracle = s_oracles[oracleAddress];
        if (!oracle.isActive) revert ArbiterNet__OracleNotActive();
        _updateOracleReputationInternal(oracleAddress, delta);
    }

    /**
     * @dev Internal function to update oracle reputation and emit an event.
     */
    function _updateOracleReputationInternal(address oracleAddress, int256 delta) internal {
        Oracle storage oracle = s_oracles[oracleAddress];
        oracle.reputationScore += delta;
        emit OracleReputationUpdated(oracleAddress, oracle.reputationScore);
    }

    // --- VIII. Dispute & Governance ---

    /**
     * @dev Allows any user to challenge a specific oracle's score submission for a policy, requiring a stake.
     *      Challenges must occur within the policy's dispute window.
     * @param policyId The ID of the policy.
     * @param submissionIndex The index of the score submission in the s_policyScoreSubmissions array.
     * @param challengerToken The ERC20 token address used for staking the challenge.
     * @param challengeStake The amount of tokens to stake for the challenge.
     */
    function challengeDecisionScore(uint256 policyId, uint256 submissionIndex, address challengerToken, uint252 challengeStake) external {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (submissionIndex >= s_policyScoreSubmissions[policyId].length) revert ArbiterNet__InvalidParameters();
        if (challengeStake == 0 || challengerToken == address(0)) revert ArbiterNet__InvalidParameters();

        ScoreSubmission storage submission = s_policyScoreSubmissions[policyId][submissionIndex];
        if (submission.isChallenged) revert ArbiterNet__ScoreAlreadyChallenged();
        if (block.timestamp > submission.timestamp + policy.disputeWindow) revert ArbiterNet__ChallengeWindowExpired();
        
        Oracle storage oracle = s_oracles[submission.oracleAddress];
        if (!oracle.isActive) revert ArbiterNet__OracleNotActive(); // Cannot challenge an inactive oracle's score

        // Take challenger's stake
        IERC20(challengerToken).transferFrom(msg.sender, address(this), challengeStake);

        submission.isChallenged = true;
        submission.challengerAddress = msg.sender;
        submission.challengerToken = challengerToken;
        submission.challengeStake = challengeStake;
        
        // Determine the relevant stake for the oracle (policy-specific or general min stake)
        address oracleCollateralToken = policy.requiredCollateralToken == address(0) ? s_minOracleStakeToken : policy.requiredCollateralToken;
        submission.oracleStakeAtChallenge = oracle.stakedCollateral[oracleCollateralToken]; // Record oracle's stake at challenge time

        policy.currentDisputeCount++;
        _checkAndEscalatePolicy(policyId); // Potentially escalate policy due to dispute count

        emit ScoreChallenged(policyId, submissionIndex, msg.sender, challengerToken, challengeStake);
    }

    /**
     * @dev Allows governance to resolve an ongoing challenge, distributing stakes and potentially slashing.
     *      This function determines the "truth" of the score and applies consequences.
     * @param policyId The ID of the policy.
     * @param submissionIndex The index of the score submission that was challenged.
     * @param oracleWasCorrect True if the oracle's submitted score was deemed correct, false otherwise.
     */
    function resolveChallenge(uint256 policyId, uint256 submissionIndex, bool oracleWasCorrect) external onlyGovernance {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__InvalidPolicyId();
        if (submissionIndex >= s_policyScoreSubmissions[policyId].length) revert ArbiterNet__InvalidParameters();

        ScoreSubmission storage submission = s_policyScoreSubmissions[policyId][submissionIndex];
        if (!submission.isChallenged || submission.challengeResolved) revert ArbiterNet__ChallengeAlreadyResolved();
        
        // Mark challenge as resolved
        submission.challengeResolved = true;
        submission.oracleWasCorrectInChallenge = oracleWasCorrect;
        policy.currentDisputeCount = policy.currentDisputeCount > 0 ? policy.currentDisputeCount - 1 : 0; // Decrement dispute count

        // Token used for challenge and oracle's stake for policy (can be different)
        address challengerStakeToken = submission.challengerToken;
        address oracleCollateralToken = policy.requiredCollateralToken == address(0) ? s_minOracleStakeToken : policy.requiredCollateralToken;

        if (oracleWasCorrect) {
            // Oracle was correct: Challenger loses stake. Oracle might be rewarded.
            uint252 governanceFee = (submission.challengeStake * s_challengeFeePercentage) / 10000;
            uint252 remainingStake = submission.challengeStake - governanceFee;
            
            // Remaining challenger stake is distributed (e.g., to oracle or treasury)
            s_oracles[submission.oracleAddress].stakedCollateral[challengerStakeToken] += remainingStake;
            s_treasuryBalances[challengerStakeToken] += governanceFee;

            _updateOracleReputationInternal(submission.oracleAddress, 5); // Reward correct oracle
            _updateOracleReputationInternal(submission.challengerAddress, -2); // Penalize failed challenger
        } else {
            // Oracle was incorrect: Oracle's stake is slashed. Challenger is rewarded.
            uint252 oracleSlashAmount = submission.oracleStakeAtChallenge; // Slash based on recorded stake at challenge
            if (oracleSlashAmount > s_oracles[submission.oracleAddress].stakedCollateral[oracleCollateralToken]) {
                oracleSlashAmount = s_oracles[submission.oracleAddress].stakedCollateral[oracleCollateralToken];
            }
            if (oracleSlashAmount > 0) {
                 s_oracles[submission.oracleAddress].stakedCollateral[oracleCollateralToken] -= oracleSlashAmount;
                 
                 uint252 challengerRewardFromOracle = (oracleSlashAmount * s_challengerRewardPercentage) / 10000;
                 uint252 governanceFeeFromOracle = oracleSlashAmount - challengerRewardFromOracle;

                 // Transfer rewards and fees
                 IERC20(challengerStakeToken).transfer(submission.challengerAddress, submission.challengeStake + challengerRewardFromOracle);
                 s_treasuryBalances[challengerStakeToken] += governanceFeeFromOracle;
            } else {
                 // Oracle had no stake to slash, challenger still gets their stake back.
                 IERC20(challengerStakeToken).transfer(submission.challengerAddress, submission.challengeStake);
            }

            _updateOracleReputationInternal(submission.oracleAddress, -15); // Penalize incorrect oracle
            _updateOracleReputationInternal(submission.challengerAddress, 10); // Reward successful challenger
        }
        
        emit ChallengeResolved(policyId, submissionIndex, oracleWasCorrect, msg.sender);
    }

    /**
     * @dev Allows governance to propose changes to core contract parameters.
     *      A voting period will follow, and if passed, the change can be finalized.
     * @param parameterKey A unique key (e.g., "minOracleStakeAmount") for the parameter.
     * @param newValue The new value for the parameter.
     * @return proposalId The ID of the newly created governance proposal.
     */
    function proposeGovernanceParameterChange(bytes32 parameterKey, uint252 newValue) external onlyGovernance returns (uint256 proposalId) {
        s_proposalCounter++;
        proposalId = s_proposalCounter;
        s_governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            parameterKey: parameterKey,
            newValue: newValue,
            creationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + 3 days, // 3-day voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        emit GovernanceProposalCreated(proposalId, parameterKey, newValue);
    }

    /**
     * @dev Allows governance members to vote on active proposals.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote 'for', false to vote 'against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external onlyGovernance {
        GovernanceProposal storage proposal = s_governanceProposals[proposalId];
        if (proposal.proposalId == 0) revert ArbiterNet__ProposalNotFound();
        if (proposal.votingEndTime < block.timestamp) revert ArbiterNet__InvalidParameters(); // Voting period ended
        if (proposal.hasVoted[msg.sender]) revert ArbiterNet__AlreadyVoted();

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VotedOnProposal(proposalId, msg.sender, support);
    }

    /**
     * @dev Allows anyone to finalize a proposal after its voting period ends, applying the change if passed.
     *      A simple majority vote is assumed here.
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 proposalId) external {
        GovernanceProposal storage proposal = s_governanceProposals[proposalId];
        if (proposal.proposalId == 0) revert ArbiterNet__ProposalNotFound();
        if (proposal.votingEndTime > block.timestamp) revert ArbiterNet__InvalidParameters(); // Voting still active
        if (proposal.executed) revert ArbiterNet__InvalidParameters(); // Already finalized/executed

        // Simple majority: For > Against
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            // Apply the change based on parameterKey
            if (proposal.parameterKey == "minOracleStakeAmount") {
                s_minOracleStakeAmount = uint252(proposal.newValue);
            } else if (proposal.parameterKey == "challengeFeePercentage") {
                s_challengeFeePercentage = uint252(proposal.newValue);
            } else if (proposal.parameterKey == "challengerRewardPercentage") {
                s_challengerRewardPercentage = uint252(proposal.newValue);
            } else if (proposal.parameterKey == "minOracleStakeToken") {
                // Special handling for address (casting from uint256 to address requires carefulness)
                s_minOracleStakeToken = address(uint160(proposal.newValue));
            } else if (proposal.parameterKey == "disputeVotingPeriod") {
                // Example: set a new governance parameter for dispute voting duration
                // This parameter itself would need to be defined in the contract
            }
            // Add more parameter updates as needed
        } else {
            proposal.passed = false;
        }
        proposal.executed = true;
        emit ProposalFinalized(proposalId, proposal.passed);
    }

    // --- IX. Treasury & Utility ---

    /**
     * @dev Allows users or governance to deposit funds into the contract's treasury.
     *      ERC20 tokens must be approved to the contract first.
     * @param tokenAddress The ERC20 token address to deposit. If address(0), it implies ETH.
     * @param amount The amount of tokens/ETH to deposit.
     */
    function depositTreasuryFunds(address tokenAddress, uint252 amount) external payable {
        if (amount == 0) revert ArbiterNet__InvalidParameters();

        if (tokenAddress == address(0)) { // ETH
            if (msg.value != amount) revert ArbiterNet__InvalidParameters();
            s_treasuryBalances[address(0)] += amount;
        } else { // ERC20
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            s_treasuryBalances[tokenAddress] += amount;
        }
        emit TreasuryFundsDeposited(tokenAddress, amount, msg.sender);
    }
    
    // Receive ETH function for direct ETH transfers (e.g., from external contracts or wallets)
    receive() external payable {
        s_treasuryBalances[address(0)] += uint252(msg.value); // Cast to uint252 for consistency
        emit TreasuryFundsDeposited(address(0), uint252(msg.value), msg.sender);
    }

    /**
     * @dev Allows governance to withdraw funds from the contract's treasury.
     *      Withdrawn funds are sent to the `s_governanceAddress`.
     * @param tokenAddress The ERC20 token address to withdraw. If address(0), it implies ETH.
     * @param amount The amount of tokens/ETH to withdraw.
     */
    function withdrawTreasuryFunds(address tokenAddress, uint252 amount) external onlyGovernance {
        if (amount == 0) revert ArbiterNet__InvalidParameters();
        if (s_treasuryBalances[tokenAddress] < amount) revert ArbiterNet__InsufficientFunds();

        s_treasuryBalances[tokenAddress] -= amount;

        if (tokenAddress == address(0)) { // ETH
            (bool success, ) = payable(s_governanceAddress).call{value: amount}("");
            if (!success) {
                // If ETH transfer fails, return funds to treasury and revert
                s_treasuryBalances[tokenAddress] += amount;
                revert ArbiterNet__ExecutionFailed("ETH withdrawal failed");
            }
        } else { // ERC20
            IERC20(tokenAddress).transfer(s_governanceAddress, amount);
        }
        emit TreasuryFundsWithdrawn(tokenAddress, amount, s_governanceAddress);
    }

    /**
     * @dev Transfers the governance role to a new address. Only callable by current governance.
     * @param newGovernance The address of the new governance entity.
     */
    function setGovernanceAddress(address newGovernance) external onlyGovernance {
        if (newGovernance == address(0)) revert ArbiterNet__InvalidParameters();
        address oldGovernance = s_governanceAddress;
        s_governanceAddress = newGovernance;
        emit GovernanceAddressSet(oldGovernance, newGovernance);
    }

    /**
     * @dev Transfers the executor role to a new address. Only callable by current governance.
     * @param newExecutor The address of the new executor entity.
     */
    function setExecutorAddress(address newExecutor) external onlyGovernance {
        if (newExecutor == address(0)) revert ArbiterNet__InvalidParameters();
        address oldExecutor = s_executorAddress;
        s_executorAddress = newExecutor;
        emit ExecutorAddressSet(oldExecutor, newExecutor);
    }
    
    // --- X. View Functions ---

    /**
     * @dev Returns the details of a registered oracle.
     * @param oracleAddress The address of the oracle.
     * @return isActive, name, metadataURI, reputationScore, lastSubmissionTimestamp, stakedCollateral (for min stake token).
     */
    function getOracle(address oracleAddress) public view returns (bool isActive, string memory name, string memory metadataURI, int256 reputationScore, uint252 lastSubmissionTimestamp, uint252 minStakeCollateral) {
        Oracle storage oracle = s_oracles[oracleAddress];
        return (oracle.isActive, oracle.name, oracle.metadataURI, oracle.reputationScore, oracle.lastSubmissionTimestamp, oracle.stakedCollateral[s_minOracleStakeToken]);
    }

    /**
     * @dev Returns the details of a decision policy.
     * @param policyId The ID of the policy.
     * @return A tuple containing all policy details.
     */
    function getPolicy(uint256 policyId) public view returns (
        bool isActive,
        string memory name,
        address targetContract,
        bytes memory targetFunctionCall,
        int256 decisionThreshold,
        uint252 cooldownPeriod,
        uint252 lastExecutionTimestamp,
        uint252 executionGasLimit,
        uint252 disputeWindow,
        address requiredCollateralToken,
        uint252 requiredCollateralAmount,
        EscalationType escalationType,
        uint252 escalationTriggerCount,
        uint252 currentFailureCount,
        uint252 currentDisputeCount,
        OracleWeightingStrategy oracleWeightingStrategy,
        int256 currentAggregatedScore,
        uint252 lastScoreAggregationTimestamp
    ) {
        Policy storage policy = s_policies[policyId];
        if (policy.targetContract == address(0)) revert ArbiterNet__PolicyNotFound();
        return (
            policy.isActive,
            policy.name,
            policy.targetContract,
            policy.targetFunctionCall,
            policy.decisionThreshold,
            policy.cooldownPeriod,
            policy.lastExecutionTimestamp,
            policy.executionGasLimit,
            policy.disputeWindow,
            policy.requiredCollateralToken,
            policy.requiredCollateralAmount,
            policy.escalationType,
            policy.escalationTriggerCount,
            policy.currentFailureCount,
            policy.currentDisputeCount,
            policy.oracleWeightingStrategy,
            policy.currentAggregatedScore,
            policy.lastScoreAggregationTimestamp
        );
    }

    /**
     * @dev Returns a specific score submission for a policy.
     * @param policyId The ID of the policy.
     * @param submissionIndex The index of the score submission.
     * @return oracleAddress, score, timestamp, metadataURI, isChallenged, challengeResolved, oracleWasCorrectInChallenge, challengerAddress, challengeStake.
     */
    function getPolicyScoreSubmission(uint256 policyId, uint256 submissionIndex) public view returns (
        address oracleAddress,
        int256 score,
        uint252 timestamp,
        string memory metadataURI,
        bool isChallenged,
        bool challengeResolved,
        bool oracleWasCorrectInChallenge,
        address challengerAddress,
        uint252 challengeStake
    ) {
        if (s_policies[policyId].targetContract == address(0)) revert ArbiterNet__PolicyNotFound();
        if (submissionIndex >= s_policyScoreSubmissions[policyId].length) revert ArbiterNet__InvalidParameters();
        ScoreSubmission storage submission = s_policyScoreSubmissions[policyId][submissionIndex];
        return (
            submission.oracleAddress,
            submission.score,
            submission.timestamp,
            submission.metadataURI,
            submission.isChallenged,
            submission.challengeResolved,
            submission.oracleWasCorrectInChallenge,
            submission.challengerAddress,
            submission.challengeStake
        );
    }

    /**
     * @dev Returns the total number of score submissions for a given policy.
     * @param policyId The ID of the policy.
     * @return The count of score submissions.
     */
    function getPolicyScoreSubmissionsCount(uint256 policyId) public view returns (uint256) {
        if (s_policies[policyId].targetContract == address(0)) revert ArbiterNet__PolicyNotFound();
        return s_policyScoreSubmissions[policyId].length;
    }

    /**
     * @dev Returns the balance of a specific token held in the contract's treasury.
     * @param tokenAddress The ERC20 token address. If address(0), it implies ETH.
     * @return The balance amount.
     */
    function getTreasuryBalance(address tokenAddress) public view returns (uint252) {
        return s_treasuryBalances[tokenAddress];
    }

    /**
     * @dev Returns the current status of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return parameterKey, newValue, creationTimestamp, votingEndTime, votesFor, votesAgainst, executed, passed.
     */
    function getGovernanceProposal(uint256 proposalId) public view returns (
        bytes32 parameterKey,
        uint252 newValue,
        uint252 creationTimestamp,
        uint252 votingEndTime,
        uint252 votesFor,
        uint252 votesAgainst,
        bool executed,
        bool passed
    ) {
        GovernanceProposal storage proposal = s_governanceProposals[proposalId];
        if (proposal.proposalId == 0) revert ArbiterNet__ProposalNotFound();
        return (
            proposal.parameterKey,
            proposal.newValue,
            proposal.creationTimestamp,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.passed
        );
    }
}
```