Okay, this is an exciting challenge! Creating something truly unique, advanced, and trendy that avoids existing open-source patterns requires a deep dive into potential future uses of smart contracts beyond typical DeFi or NFTs.

Let's imagine a smart contract that acts as a decentralized, self-adapting "future-caster" or "event-shaper." It doesn't just store data; it *reacts* to evolving external and internal data streams, adapts its own parameters, and enables complex conditional actions based on predictive outcomes or real-time event validation.

I call this concept **"ChronoCaster."**

---

### **ChronoCaster: Decentralized Predictive Automation & Adaptive Policies**

**Concept Overview:**
ChronoCaster is a sophisticated smart contract designed to enable **decentralized, data-driven adaptive behavior** and **conditional execution of actions** based on evolving "Prognosis Streams." Unlike simple prediction markets, ChronoCaster allows the definition of complex, multi-variable policies that dynamically adjust contract parameters (e.g., fees, access) and trigger actions when specific conditions within a Prognosis Stream are met or exceeded. It incorporates elements of decentralized oracle networks, reputation, governance, and time-series event processing.

**Key Features & Advanced Concepts:**

1.  **Prognosis Streams:** Instead of a single "prediction," a stream of evolving data points related to a future event (e.g., "likelihood of rain tomorrow," "BTC price at X time," "outcome of a political election"). These streams are fed by "Catalysts."
2.  **Catalyst Reputation System (Proof-of-Impact):** Users stake collateral to become "Catalysts" and submit data to Prognosis Streams. Their accuracy and community validation (via voting) build a reputation score, influencing their impact and rewards.
3.  **Adaptive Policies:** Rules that modify the contract's own behavior (e.g., dynamic fees, access control, reward distribution) based on the state of Prognosis Streams. These policies can have weightings and thresholds.
4.  **Conditional Actions:** Users can "lock" assets or define actions that only execute if specific, complex conditions within a Prognosis Stream are met by a future block timestamp.
5.  **Decentralized Event Validation & Dispute Resolution:** Mechanisms for the community to dispute or validate Prognosis Stream data points, impacting Catalyst reputation and stream validity.
6.  **Time-Series & Event-Driven Logic:** The contract processes and reacts to data over time, not just single events.
7.  **Dynamic Fee Structures:** Fees can automatically adjust based on overall contract activity, stream volatility, or specific Prognosis Stream states, driven by Adaptive Policies.
8.  **Prognosis Curation:** A mechanism for the community or governance to "curate" (approve/disapprove) Prognosis Streams, affecting their visibility and trust.
9.  **Delegated Caster Roles:** Catalysts can delegate their casting power or data submission rights.

---

### **Outline & Function Summary**

**I. Core Data Structures & Enums**
   *   `PrognosisState`: Enum for stream lifecycle.
   *   `PolicyOperand`: Enum for policy condition types (e.g., EQ, GT, LT).
   *   `PrognosisDataPoint`: Struct for individual data submissions.
   *   `PrognosisStream`: Main struct for a future event stream.
   *   `PolicyCondition`: Struct for a single condition within an Adaptive Policy.
   *   `AdaptivePolicy`: Struct for a set of rules governing contract adaptation.
   *   `FeeConfiguration`: Struct for dynamic fee settings.
   *   `ConditionalAction`: Struct for actions triggered by Prognosis Streams.

**II. State Variables**
   *   `owner`, `paused`
   *   `prognosisStreams`: Mapping of stream IDs to `PrognosisStream`.
   *   `prognosisStreamCount`
   *   `catalystStakes`: Mapping of catalyst address to staked amount.
   *   `catalystReputationScores`: Mapping of catalyst address to accuracy/impact score.
   *   `adaptivePolicies`: Mapping of policy IDs to `AdaptivePolicy`.
   *   `conditionalActions`: Mapping of action IDs to `ConditionalAction`.
   *   `currentFeeConfig`: Current dynamic fee settings.
   *   `prognosisStreamIndexByHash`: To ensure uniqueness.
   *   `externalOracleAddress`: Address of an external oracle if needed.

**III. Events**
   *   `PrognosisStreamCreated`, `PrognosisDataSubmitted`, `PrognosisStateChanged`
   *   `AdaptivePolicyDefined`, `PolicyApplied`
   *   `ConditionalActionCreated`, `ConditionalActionExecuted`, `ConditionalActionRefunded`
   *   `CatalystStaked`, `CatalystUnstaked`, `CatalystReputationUpdated`
   *   `PrognosisDisputed`, `PrognosisDisputeResolved`
   *   `FeesUpdated`, `OracleAddressUpdated`
   *   `PrognosisCurated`, `CatalystDelegated`

**IV. Modifiers**
   *   `onlyOwner`: Restricts access to contract owner.
   *   `whenNotPaused`: Prevents execution when paused.
   *   `whenPaused`: Allows execution only when paused.
   *   `onlyCatalyst`: Restricts access to registered Catalysts.
   *   `prognosisActive`: Ensures stream is not yet finalized or disputed.

**V. Internal/Private Helper Functions**
   *   `_checkPrognosisConditions`: Evaluates if a set of policy conditions are met by a stream.
   *   `_updateCatalystReputation`: Updates a catalyst's score based on events.
   *   `_calculateDynamicFee`: Computes fees based on `currentFeeConfig` and potentially `AdaptivePolicy` influence.
   *   `_getPrognosisStreamHash`: Generates a unique hash for a stream.

**VI. Public/External Functions (20+ Functions)**

1.  `constructor()`: Initializes owner and default configs.
2.  `pause()`: Pauses contract operations (owner only).
3.  `unpause()`: Unpauses contract operations (owner only).
4.  `setOracleAddress(address _newOracle)`: Sets address for external data oracle (owner only).
5.  `setFeeConfiguration(uint256 baseFee, uint256 volatilityMultiplier, uint256 catalystFeeShare)`: Sets global fee parameters (owner only).
6.  `stakeForCatalystRole(uint256 _amount)`: Allows users to stake ETH to become a Catalyst.
7.  `unstakeFromCatalystRole()`: Allows Catalysts to unstake their ETH (subject to lockups/disputes).
8.  `createPrognosisStream(string memory _name, string memory _description, uint256 _predictionEndTime, uint256 _resolutionTime, bytes32 _initialStateHash)`: Creates a new Prognosis Stream.
9.  `submitPrognosisData(bytes32 _streamId, bytes32 _dataHash, int256 _value, string memory _metadataURI)`: Catalysts submit data points to a stream.
10. `defineAdaptivePolicy(string memory _name, PolicyCondition[] memory _conditions, bytes32 _targetStreamId, uint256 _dynamicFeeFactor, uint256 _reputationWeight, string memory _policyActionURI)`: Defines an Adaptive Policy linked to a Prognosis Stream.
11. `applyAdaptivePolicy(bytes32 _policyId)`: Triggers the application of an Adaptive Policy if its conditions are met. This could dynamically alter contract parameters.
12. `createConditionalAction(bytes32 _targetStreamId, PolicyCondition[] memory _triggerConditions, address _recipient, uint256 _amount, string memory _actionMetadataURI)`: Users define an action (e.g., transfer funds) that executes when stream conditions are met.
13. `executeConditionalAction(bytes32 _actionId)`: Allows anyone to attempt to execute a conditional action once its conditions are met.
14. `refundConditionalActionDeposit(bytes32 _actionId)`: Allows creator to reclaim funds if action conditions are not met by resolution time.
15. `initiatePrognosisDispute(bytes32 _streamId, bytes32 _dataPointHash, string memory _reason)`: Allows anyone to dispute the validity of a data point in a stream (requires stake).
16. `resolvePrognosisDispute(bytes32 _streamId, bytes32 _dataPointHash, bool _isValid)`: Owner or a governance committee (conceptual here) resolves a dispute, affecting catalyst reputation.
17. `voteOnPrognosisValidity(bytes32 _streamId, bytes32 _dataPointHash, bool _isValid)`: Community votes on the validity of a data point, contributing to `_updateCatalystReputation`.
18. `finalizePrognosisStream(bytes32 _streamId, bytes32 _finalStateHash)`: Marks a stream as finalized, concluding its lifecycle and potentially triggering rewards.
19. `claimPrognosisRewards(bytes32 _streamId)`: Allows accurate Catalysts to claim rewards based on their contribution to finalized streams.
20. `curatePrognosisStream(bytes32 _streamId, bool _isApproved)`: Allows owner/governance to approve/disapprove a stream, affecting its visibility/trust score (owner/governance only).
21. `delegateCatalystRole(address _delegatee)`: Allows a Catalyst to delegate their data submission rights to another address.
22. `revokeDelegatedCatalystRole()`: Revokes a previously delegated role.
23. `getPrognosisStreamDetails(bytes32 _streamId)`: View function to retrieve stream info.
24. `getPrognosisStreamDataPoints(bytes32 _streamId, uint256 _startIndex, uint256 _count)`: View function to retrieve a range of data points.
25. `getCatalystInfo(address _catalyst)`: View function to retrieve catalyst stake and reputation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking, if using an ERC20 token

// --- ChronoCaster: Decentralized Predictive Automation & Adaptive Policies ---

// Concept Overview:
// ChronoCaster is a sophisticated smart contract designed to enable decentralized, data-driven adaptive
// behavior and conditional execution of actions based on evolving "Prognosis Streams."
// It goes beyond simple prediction markets by allowing complex, multi-variable policies that dynamically
// adjust contract parameters (e.g., fees, access) and trigger actions when specific conditions within
// a Prognosis Stream are met or exceeded. It incorporates elements of decentralized oracle networks,
// reputation, governance, and time-series event processing.

// Key Features & Advanced Concepts:
// 1. Prognosis Streams: Evolving data streams for future events.
// 2. Catalyst Reputation (Proof-of-Impact): Staked users submit data, reputation built on accuracy.
// 3. Adaptive Policies: Rules that dynamically adjust contract behavior based on stream data.
// 4. Conditional Actions: Actions locked until specific, complex stream conditions are met.
// 5. Decentralized Event Validation & Dispute Resolution: Community mechanisms for data integrity.
// 6. Time-Series & Event-Driven Logic: Reaction to data over time.
// 7. Dynamic Fee Structures: Fees adjust based on activity/stream states.
// 8. Prognosis Curation: Community/governance approves streams.
// 9. Delegated Caster Roles: Catalysts can delegate data submission.

// --- Outline & Function Summary ---

// I. Core Data Structures & Enums
//    - PrognosisState: Enum for stream lifecycle.
//    - PolicyOperand: Enum for policy condition types (EQ, GT, LT).
//    - PrognosisDataPoint: Struct for individual data submissions.
//    - PrognosisStream: Main struct for a future event stream.
//    - PolicyCondition: Struct for a single condition within an Adaptive Policy.
//    - AdaptivePolicy: Struct for a set of rules governing contract adaptation.
//    - FeeConfiguration: Struct for dynamic fee settings.
//    - ConditionalAction: Struct for actions triggered by Prognosis Streams.

// II. State Variables
//    - owner, paused
//    - prognosisStreams: Mapping of stream IDs to PrognosisStream.
//    - prognosisStreamCount
//    - catalystStakes: Mapping of catalyst address to staked amount.
//    - catalystReputationScores: Mapping of catalyst address to accuracy/impact score.
//    - adaptivePolicies: Mapping of policy IDs to AdaptivePolicy.
//    - conditionalActions: Mapping of action IDs to ConditionalAction.
//    - currentFeeConfig: Current dynamic fee settings.
//    - prognosisStreamIndexByHash: To ensure uniqueness.
//    - externalOracleAddress: Address of an external oracle if needed.
//    - delegatedCatalysts: Mapping for delegated roles.

// III. Events
//    - PrognosisStreamCreated, PrognosisDataSubmitted, PrognosisStateChanged
//    - AdaptivePolicyDefined, PolicyApplied
//    - ConditionalActionCreated, ConditionalActionExecuted, ConditionalActionRefunded
//    - CatalystStaked, CatalystUnstaked, CatalystReputationUpdated
//    - PrognosisDisputed, PrognosisDisputeResolved
//    - FeesUpdated, OracleAddressUpdated
//    - PrognosisCurated, CatalystDelegated

// IV. Modifiers
//    - onlyOwner: Restricts access to contract owner.
//    - whenNotPaused: Prevents execution when paused.
//    - whenPaused: Allows execution only when paused.
//    - onlyCatalyst: Restricts access to registered Catalysts (or their delegate).
//    - prognosisActive: Ensures stream is not yet finalized or disputed.

// V. Internal/Private Helper Functions
//    - _checkPrognosisConditions: Evaluates if a set of policy conditions are met by a stream.
//    - _updateCatalystReputation: Updates a catalyst's score based on events.
//    - _calculateDynamicFee: Computes fees based on currentFeeConfig and policy influence.
//    - _getPrognosisStreamHash: Generates a unique hash for a stream.
//    - _isCatalyst: Checks if an address is a catalyst (or delegated).

// VI. Public/External Functions (25 Functions)
// 1.  constructor()
// 2.  pause()
// 3.  unpause()
// 4.  setOracleAddress(address _newOracle)
// 5.  setFeeConfiguration(uint256 baseFee, uint256 volatilityMultiplier, uint256 catalystFeeShare)
// 6.  stakeForCatalystRole(uint256 _amount)
// 7.  unstakeFromCatalystRole()
// 8.  createPrognosisStream(string memory _name, string memory _description, uint256 _predictionEndTime, uint256 _resolutionTime, bytes32 _initialStateHash)
// 9.  submitPrognosisData(bytes32 _streamId, bytes32 _dataHash, int256 _value, string memory _metadataURI)
// 10. defineAdaptivePolicy(string memory _name, PolicyCondition[] memory _conditions, bytes32 _targetStreamId, uint256 _dynamicFeeFactor, uint256 _reputationWeight, string memory _policyActionURI)
// 11. applyAdaptivePolicy(bytes32 _policyId)
// 12. createConditionalAction(bytes32 _targetStreamId, PolicyCondition[] memory _triggerConditions, address _recipient, uint256 _amount, string memory _actionMetadataURI)
// 13. executeConditionalAction(bytes32 _actionId)
// 14. refundConditionalActionDeposit(bytes32 _actionId)
// 15. initiatePrognosisDispute(bytes32 _streamId, bytes32 _dataPointHash, string memory _reason)
// 16. resolvePrognosisDispute(bytes32 _streamId, bytes32 _dataPointHash, bool _isValid)
// 17. voteOnPrognosisValidity(bytes32 _streamId, bytes32 _dataPointHash, bool _isValid)
// 18. finalizePrognosisStream(bytes32 _streamId, bytes32 _finalStateHash)
// 19. claimPrognosisRewards(bytes32 _streamId)
// 20. curatePrognosisStream(bytes32 _streamId, bool _isApproved)
// 21. delegateCatalystRole(address _delegatee)
// 22. revokeDelegatedCatalystRole()
// 23. getPrognosisStreamDetails(bytes32 _streamId)
// 24. getPrognosisStreamDataPoints(bytes32 _streamId, uint256 _startIndex, uint256 _count)
// 25. getCatalystInfo(address _catalyst)

// --- End Outline & Function Summary ---


// Custom Errors for Gas Efficiency and Clarity
error ChronoCaster__NotCatalyst();
error ChronoCaster__AlreadyCatalyst();
error ChronoCaster__InsufficientStake();
error ChronoCaster__StakeLockedDueToDispute();
error ChronoCaster__InvalidPrognosisStreamId();
error ChronoCaster__PrognosisStreamNotActive();
error ChronoCaster__PrognosisStreamAlreadyFinalized();
error ChronoCaster__PrognosisStreamNotYetResolvable();
error ChronoCaster__PrognosisStreamResolutionPassed();
error ChronoCaster__InvalidDataPointHash();
error ChronoCaster__PrognosisDataNotSubmitted();
error ChronoCaster__PrognosisDataDisputed();
error ChronoCaster__PrognosisDataAlreadyDisputed();
error ChronoCaster__PrognosisDataNotDisputed();
error ChronoCaster__InvalidPolicyId();
error ChronoCaster__PolicyConditionsNotMet();
error ChronoCaster__InvalidConditionalActionId();
error ChronoCaster__ConditionalActionAlreadyExecuted();
error ChronoCaster__ConditionalActionConditionsNotMet();
error ChronoCaster__ConditionalActionRefundBlocked();
error ChronoCaster__ConditionalActionNotRefundableYet();
error ChronoCaster__SelfDelegationNotAllowed();
error ChronoCaster__AlreadyDelegated();
error ChronoCaster__NotDelegated();
error ChronoCaster__InvalidAmount();

// Interface for a hypothetical external oracle, if ChronoCaster needs to pull data.
// For this contract, we primarily assume Catalysts push data, but this shows a pull mechanism.
interface IExternalPrognosisOracle {
    function getLatestPrognosis(bytes32 _eventId) external view returns (int256 value, uint256 timestamp);
}

contract ChronoCaster is Ownable, Pausable {

    // --- Enums ---
    enum PrognosisState {
        Active,          // Stream is active and accepting data
        Disputed,        // A specific data point or the stream itself is under dispute
        Resolving,       // Past predictionEndTime, awaiting finalization
        Finalized,       // Stream is finalized and outcome is set
        Cancelled        // Stream has been cancelled
    }

    enum PolicyOperand {
        EQ, // Equal to
        NE, // Not Equal to
        GT, // Greater Than
        LT, // Less Than
        GTE, // Greater Than or Equal to
        LTE // Less Than or Equal to
    }

    // --- Structs ---

    struct PrognosisDataPoint {
        bytes32 dataHash;   // Unique hash of the data content for integrity
        int256 value;       // The specific data point value (e.g., price, percentage, outcome index)
        uint256 timestamp;  // When the data was submitted
        address submitter;  // Who submitted the data
        uint256 stake;      // Catalyst stake associated with this data point (for reputation)
        bool disputed;      // True if this data point is currently under dispute
        bool valid;         // True if this data point was validated (after dispute or by finalization)
    }

    struct PrognosisStream {
        bytes32 id;                  // Unique identifier for the stream
        string name;                 // Human-readable name
        string description;          // Detailed description of the event
        uint256 creationTime;        // When the stream was created
        uint256 predictionEndTime;   // Deadline for submitting data to the stream
        uint256 resolutionTime;      // When the stream can be officially resolved/finalized
        PrognosisState state;        // Current state of the stream
        bytes32 initialStateHash;    // Initial verifiable state hash (e.g., hash of event details)
        bytes32 finalStateHash;      // Final verifiable state hash (set on finalization)
        PrognosisDataPoint[] dataPoints; // Array of submitted data points (time-series)
        uint256 totalRewardPool;     // Accumulates rewards for accurate catalysts
        bool curatedApproved;        // True if approved by curator/governance
        uint256 disputeStake;       // Total stake locked in disputes for this stream (for simplicity, a single pool)
    }

    struct PolicyCondition {
        bytes32 targetPrognosisId;  // Which prognosis stream this condition applies to
        PolicyOperand operand;      // Comparison operator (EQ, GT, LT, etc.)
        int256 thresholdValue;      // Value to compare against
        uint256 minDataPoints;      // Minimum data points in stream for condition to be valid
        uint256 maxAgeHours;        // Max age of data point for evaluation (0 for any age)
    }

    struct AdaptivePolicy {
        bytes32 id;                 // Unique identifier for the policy
        string name;                // Human-readable name
        PolicyCondition[] conditions; // Array of conditions that must ALL be met
        bytes32 targetStreamId;     // The PrognosisStream this policy monitors
        uint256 dynamicFeeFactor;   // Factor to adjust fees (e.g., 100 = no change, 110 = +10%)
        uint256 reputationWeight;   // Weight applied to catalyst reputation for this policy's influence
        string policyActionURI;     // URI to off-chain logic or more detailed policy actions
        uint256 lastAppliedTimestamp; // When this policy was last successfully applied
    }

    struct FeeConfiguration {
        uint256 baseFeePermille;        // Base fee (e.g., 10 = 1%)
        uint256 volatilityMultiplier;   // Multiplier based on stream volatility (conceptual)
        uint256 catalystFeeSharePermille; // Share of fees going to catalysts (e.g., 500 = 50%)
    }

    struct ConditionalAction {
        bytes32 id;                  // Unique identifier for the action
        address creator;             // Who created this action
        address recipient;           // Who receives the funds/action if conditions met
        uint256 amount;              // Amount of ETH locked for the action
        bytes32 targetStreamId;      // The PrognosisStream this action monitors
        PolicyCondition[] triggerConditions; // Conditions that must be met to execute
        string actionMetadataURI;    // URI to off-chain data/instructions for the action
        bool executed;               // True if the action has been executed
        bool refunded;               // True if the funds have been refunded
        uint256 depositTime;         // When the deposit was made
        uint256 triggerAttemptCount; // How many times execution was attempted
    }

    // --- State Variables ---
    uint256 public prognosisStreamCount;
    mapping(bytes32 => PrognosisStream) public prognosisStreams;
    mapping(bytes32 => bytes32) private prognosisStreamIndexByHash; // Hash to streamId for uniqueness check

    mapping(address => uint256) public catalystStakes; // ETH staked by catalysts
    mapping(address => int256) public catalystReputationScores; // Catalyst accuracy/impact score
    mapping(address => address) public delegatedCatalysts; // Address => delegated to

    mapping(bytes32 => AdaptivePolicy) public adaptivePolicies;
    mapping(bytes32 => ConditionalAction) public conditionalActions;

    FeeConfiguration public currentFeeConfig;
    address public externalOracleAddress; // Address of an external data oracle contract (optional)

    // --- Events ---
    event PrognosisStreamCreated(bytes32 indexed streamId, string name, address indexed creator, uint256 creationTime, uint256 predictionEndTime);
    event PrognosisDataSubmitted(bytes32 indexed streamId, bytes32 indexed dataHash, int256 value, address indexed submitter, uint256 timestamp);
    event PrognosisStateChanged(bytes32 indexed streamId, PrognosisState oldState, PrognosisState newState);

    event AdaptivePolicyDefined(bytes32 indexed policyId, string name, bytes32 indexed targetStreamId);
    event PolicyApplied(bytes32 indexed policyId, bytes32 indexed targetStreamId, uint256 newFeeFactor, uint256 timestamp);

    event ConditionalActionCreated(bytes32 indexed actionId, bytes32 indexed targetStreamId, address indexed creator, uint256 amount);
    event ConditionalActionExecuted(bytes32 indexed actionId, bytes32 indexed targetStreamId, address indexed recipient, uint256 amount);
    event ConditionalActionRefunded(bytes32 indexed actionId, address indexed creator, uint256 amount);

    event CatalystStaked(address indexed catalyst, uint256 amount);
    event CatalystUnstaked(address indexed catalyst, uint256 amount);
    event CatalystReputationUpdated(address indexed catalyst, int256 newScore, int256 scoreChange);

    event PrognosisDisputed(bytes32 indexed streamId, bytes32 indexed dataPointHash, address indexed disputer);
    event PrognosisDisputeResolved(bytes32 indexed streamId, bytes32 indexed dataPointHash, address indexed resolver, bool isValid);
    event PrognosisValidityVoted(bytes32 indexed streamId, bytes32 indexed dataPointHash, address indexed voter, bool vote);

    event FeesUpdated(uint256 baseFeePermille, uint256 volatilityMultiplier, uint256 catalystFeeSharePermille);
    event OracleAddressUpdated(address oldAddress, address newAddress);

    event PrognosisCurated(bytes32 indexed streamId, bool isApproved, address indexed curator);
    event CatalystDelegated(address indexed delegator, address indexed delegatee);
    event CatalystDelegationRevoked(address indexed delegator, address indexed revokedDelegatee);

    // --- Modifiers ---

    modifier onlyCatalyst() {
        if (!_isCatalyst(msg.sender)) {
            revert ChronoCaster__NotCatalyst();
        }
        _;
    }

    modifier prognosisActive(bytes32 _streamId) {
        if (prognosisStreams[_streamId].state != PrognosisState.Active) {
            revert ChronoCaster__PrognosisStreamNotActive();
        }
        _;
    }

    modifier prognosisNotFinalized(bytes32 _streamId) {
        if (prognosisStreams[_streamId].state == PrognosisState.Finalized || prognosisStreams[_streamId].state == PrognosisState.Cancelled) {
            revert ChronoCaster__PrognosisStreamAlreadyFinalized();
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        currentFeeConfig = FeeConfiguration({
            baseFeePermille: 10, // 1%
            volatilityMultiplier: 0, // Placeholder, can be used by off-chain logic or future updates
            catalystFeeSharePermille: 500 // 50%
        });
        prognosisStreamCount = 0;
    }

    // --- Internal/Private Helper Functions ---

    /**
     * @dev Checks if a given address is a registered Catalyst or has been delegated Catalyst privileges.
     * @param _addr The address to check.
     * @return True if the address is a Catalyst or a delegate, false otherwise.
     */
    function _isCatalyst(address _addr) internal view returns (bool) {
        return catalystStakes[_addr] > 0 || delegatedCatalysts[_addr] == _addr; // Check if it's the actual delegator
    }

    /**
     * @dev Evaluates if a set of policy conditions are met by a prognosis stream.
     * @param _streamId The ID of the prognosis stream.
     * @param _conditions An array of PolicyCondition structs to check.
     * @return True if all conditions are met, false otherwise.
     */
    function _checkPrognosisConditions(bytes32 _streamId, PolicyCondition[] memory _conditions) internal view returns (bool) {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) {
            return false; // Stream does not exist
        }

        if (stream.dataPoints.length == 0) {
            return false; // No data points to evaluate
        }

        for (uint256 i = 0; i < _conditions.length; i++) {
            PolicyCondition memory cond = _conditions[i];

            if (stream.dataPoints.length < cond.minDataPoints) {
                return false; // Not enough data points
            }

            // Get the latest valid data point that fits the age requirement
            PrognosisDataPoint storage latestPoint;
            bool foundLatest = false;
            for (int256 j = int256(stream.dataPoints.length) - 1; j >= 0; j--) {
                if (stream.dataPoints[uint256(j)].valid) { // Only consider validated data points
                    if (cond.maxAgeHours == 0 || block.timestamp <= stream.dataPoints[uint256(j)].timestamp + cond.maxAgeHours * 1 hours) {
                        latestPoint = stream.dataPoints[uint256(j)];
                        foundLatest = true;
                        break;
                    }
                }
            }
            if (!foundLatest) {
                return false; // No valid data point found within age limits
            }

            // Evaluate the condition
            bool conditionMet = false;
            if (cond.operand == PolicyOperand.EQ) conditionMet = (latestPoint.value == cond.thresholdValue);
            else if (cond.operand == PolicyOperand.NE) conditionMet = (latestPoint.value != cond.thresholdValue);
            else if (cond.operand == PolicyOperand.GT) conditionMet = (latestPoint.value > cond.thresholdValue);
            else if (cond.operand == PolicyOperand.LT) conditionMet = (latestPoint.value < cond.thresholdValue);
            else if (cond.operand == PolicyOperand.GTE) conditionMet = (latestPoint.value >= cond.thresholdValue);
            else if (cond.operand == PolicyOperand.LTE) conditionMet = (latestPoint.value <= cond.thresholdValue);

            if (!conditionMet) {
                return false; // If any single condition fails, the entire policy fails
            }
        }
        return true; // All conditions met
    }

    /**
     * @dev Updates a catalyst's reputation score.
     * @param _catalyst The address of the catalyst.
     * @param _change The amount to change the reputation by (can be negative).
     */
    function _updateCatalystReputation(address _catalyst, int256 _change) internal {
        catalystReputationScores[_catalyst] += _change;
        emit CatalystReputationUpdated(_catalyst, catalystReputationScores[_catalyst], _change);
    }

    /**
     * @dev Calculates the dynamic fee based on the current configuration and potential policy influence.
     * @param _baseAmount The base amount for which to calculate the fee.
     * @return The calculated fee amount.
     */
    function _calculateDynamicFee(uint256 _baseAmount) internal view returns (uint256) {
        // For simplicity, volatilityMultiplier is not yet dynamically used here, but can be added via oracles/policies.
        // The dynamicFeeFactor from applied policies can further adjust this.
        uint256 fee = (_baseAmount * currentFeeConfig.baseFeePermille) / 1000;
        return fee;
    }

    /**
     * @dev Generates a unique hash for a prognosis stream based on its core properties.
     * @param _name Name of the stream.
     * @param _description Description of the stream.
     * @param _predictionEndTime End time for predictions.
     * @param _resolutionTime Resolution time for the stream.
     * @param _initialStateHash Initial verifiable state hash.
     * @return The unique hash.
     */
    function _getPrognosisStreamHash(
        string memory _name,
        string memory _description,
        uint256 _predictionEndTime,
        uint256 _resolutionTime,
        bytes32 _initialStateHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name, _description, _predictionEndTime, _resolutionTime, _initialStateHash));
    }

    // --- Public/External Functions ---

    /**
     * @dev Pauses all core operations of the contract.
     * Only owner can call.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Only owner can call.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Sets the address for an external prognosis oracle contract.
     * This oracle could be used to pull authoritative external data into streams.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        address oldAddress = externalOracleAddress;
        externalOracleAddress = _newOracle;
        emit OracleAddressUpdated(oldAddress, _newOracle);
    }

    /**
     * @dev Sets the global fee configuration for the ChronoCaster.
     * @param _baseFeePermille Base fee in permille (e.g., 10 for 1%).
     * @param _volatilityMultiplier Multiplier for fees based on conceptual volatility.
     * @param _catalystFeeSharePermille Percentage of fees allocated to catalysts.
     */
    function setFeeConfiguration(uint256 _baseFeePermille, uint256 _volatilityMultiplier, uint256 _catalystFeeSharePermille) external onlyOwner {
        currentFeeConfig = FeeConfiguration({
            baseFeePermille: _baseFeePermille,
            volatilityMultiplier: _volatilityMultiplier,
            catalystFeeSharePermille: _catalystFeeSharePermille
        });
        emit FeesUpdated(_baseFeePermille, _volatilityMultiplier, _catalystFeeSharePermille);
    }

    /**
     * @dev Allows a user to stake ETH to become a Catalyst.
     * Catalysts can submit data to Prognosis Streams and earn rewards.
     * @param _amount The amount of ETH to stake.
     */
    function stakeForCatalystRole(uint256 _amount) external payable whenNotPaused {
        if (_amount == 0) revert ChronoCaster__InvalidAmount();
        if (msg.value != _amount) revert ChronoCaster__InvalidAmount(); // Ensure ETH sent matches _amount
        if (catalystStakes[msg.sender] > 0) revert ChronoCaster__AlreadyCatalyst();

        catalystStakes[msg.sender] = _amount;
        _updateCatalystReputation(msg.sender, 100); // Initial reputation boost
        emit CatalystStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a Catalyst to unstake their ETH.
     * Unstaking may be restricted if involved in active disputes.
     */
    function unstakeFromCatalystRole() external onlyCatalyst whenNotPaused {
        // Implement logic to prevent unstaking if catalyst is involved in unresolved disputes
        // For simplicity, this example doesn't track specific disputes per catalyst.
        // In a real system, you'd check if catalyst has pending disputes or locked stake.

        uint256 stakeAmount = catalystStakes[msg.sender];
        if (stakeAmount == 0) revert ChronoCaster__InsufficientStake(); // Should not happen with onlyCatalyst
        if (prognosisStreams[bytes32(0)].disputeStake > 0) revert ChronoCaster__StakeLockedDueToDispute(); // Simplified check

        catalystStakes[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: stakeAmount}("");
        if (!success) {
            // Revert the stake in case of transfer failure (though unlikely for direct ETH transfer)
            catalystStakes[msg.sender] = stakeAmount;
            revert("ChronoCaster: Failed to return stake.");
        }
        _updateCatalystReputation(msg.sender, -50); // Small reputation penalty for leaving
        emit CatalystUnstaked(msg.sender, stakeAmount);
    }

    /**
     * @dev Creates a new Prognosis Stream for a future event.
     * @param _name Human-readable name of the stream.
     * @param _description Detailed description of the event.
     * @param _predictionEndTime The deadline for submitting data to the stream.
     * @param _resolutionTime The time when the stream can be officially resolved/finalized.
     * @param _initialStateHash An initial verifiable hash of the event details (e.g., IPFS hash of terms).
     * @return The ID of the newly created stream.
     */
    function createPrognosisStream(
        string memory _name,
        string memory _description,
        uint256 _predictionEndTime,
        uint256 _resolutionTime,
        bytes32 _initialStateHash
    ) external whenNotPaused returns (bytes32 streamId) {
        require(_predictionEndTime > block.timestamp, "ChronoCaster: Prediction end time must be in the future.");
        require(_resolutionTime > _predictionEndTime, "ChronoCaster: Resolution time must be after prediction end.");

        streamId = _getPrognosisStreamHash(_name, _description, _predictionEndTime, _resolutionTime, _initialStateHash);
        require(prognosisStreamIndexByHash[streamId] == bytes32(0), "ChronoCaster: Stream with these parameters already exists.");

        prognosisStreams[streamId] = PrognosisStream({
            id: streamId,
            name: _name,
            description: _description,
            creationTime: block.timestamp,
            predictionEndTime: _predictionEndTime,
            resolutionTime: _resolutionTime,
            state: PrognosisState.Active,
            initialStateHash: _initialStateHash,
            finalStateHash: bytes32(0),
            dataPoints: new PrognosisDataPoint[](0),
            totalRewardPool: 0,
            curatedApproved: false, // Requires curation
            disputeStake: 0
        });

        prognosisStreamCount++;
        prognosisStreamIndexByHash[streamId] = streamId; // Mark as existing
        emit PrognosisStreamCreated(streamId, _name, msg.sender, block.timestamp, _predictionEndTime);
    }

    /**
     * @dev Allows Catalysts to submit new data points to an active Prognosis Stream.
     * Requires catalyst role and stream to be active.
     * @param _streamId The ID of the target Prognosis Stream.
     * @param _dataHash A verifiable hash of the data content.
     * @param _value The actual data value.
     * @param _metadataURI URI pointing to off-chain metadata about the submission.
     */
    function submitPrognosisData(
        bytes32 _streamId,
        bytes32 _dataHash,
        int256 _value,
        string memory _metadataURI
    ) external onlyCatalyst prognosisActive(_streamId) whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        if (block.timestamp >= stream.predictionEndTime) revert ChronoCaster__PrognosisStreamResolutionPassed();

        address actualSubmitter = msg.sender;
        if (delegatedCatalysts[msg.sender] != address(0)) {
            actualSubmitter = delegatedCatalysts[msg.sender]; // If msg.sender is a delegate, credit the delegator
        }
        
        uint256 currentCatalystStake = catalystStakes[actualSubmitter];
        if (currentCatalystStake == 0) revert ChronoCaster__InsufficientStake(); // Should be caught by onlyCatalyst

        stream.dataPoints.push(PrognosisDataPoint({
            dataHash: _dataHash,
            value: _value,
            timestamp: block.timestamp,
            submitter: actualSubmitter,
            stake: currentCatalystStake, // Associate current stake with this data point
            disputed: false,
            valid: true // Assume valid until disputed
        }));

        emit PrognosisDataSubmitted(_streamId, _dataHash, _value, actualSubmitter, block.timestamp);
    }

    /**
     * @dev Defines a new Adaptive Policy that can modify contract behavior based on a Prognosis Stream.
     * @param _name Name of the policy.
     * @param _conditions Array of conditions that must be met for the policy to apply.
     * @param _targetStreamId The Prognosis Stream this policy monitors.
     * @param _dynamicFeeFactor A factor to adjust fees (e.g., 100 = no change, 110 = +10%).
     * @param _reputationWeight Weight applied to catalyst reputation for this policy's influence.
     * @param _policyActionURI URI to off-chain logic or more detailed policy actions.
     * @return The ID of the new policy.
     */
    function defineAdaptivePolicy(
        string memory _name,
        PolicyCondition[] memory _conditions,
        bytes32 _targetStreamId,
        uint256 _dynamicFeeFactor,
        uint256 _reputationWeight,
        string memory _policyActionURI
    ) external onlyOwner whenNotPaused returns (bytes32 policyId) {
        if (prognosisStreams[_targetStreamId].id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        require(_conditions.length > 0, "ChronoCaster: Policy must have at least one condition.");

        policyId = keccak256(abi.encodePacked(_name, _targetStreamId, block.timestamp)); // Simple ID generation

        adaptivePolicies[policyId] = AdaptivePolicy({
            id: policyId,
            name: _name,
            conditions: _conditions,
            targetStreamId: _targetStreamId,
            dynamicFeeFactor: _dynamicFeeFactor,
            reputationWeight: _reputationWeight,
            policyActionURI: _policyActionURI,
            lastAppliedTimestamp: 0
        });

        emit AdaptivePolicyDefined(policyId, _name, _targetStreamId);
    }

    /**
     * @dev Attempts to apply an Adaptive Policy. If its conditions are met, contract parameters may change.
     * This function can be called by anyone (e.g., a keeper bot).
     * @param _policyId The ID of the Adaptive Policy to apply.
     */
    function applyAdaptivePolicy(bytes32 _policyId) external whenNotPaused {
        AdaptivePolicy storage policy = adaptivePolicies[_policyId];
        if (policy.id == bytes32(0)) revert ChronoCaster__InvalidPolicyId();

        if (!_checkPrognosisConditions(policy.targetStreamId, policy.conditions)) {
            revert ChronoCaster__PolicyConditionsNotMet();
        }

        // Apply the policy's effects (e.g., adjust fees)
        // This is a simplified example; a real policy might have more complex effects.
        uint256 newBaseFee = (currentFeeConfig.baseFeePermille * policy.dynamicFeeFactor) / 100;
        if (newBaseFee == 0) newBaseFee = 1; // Minimum fee
        currentFeeConfig.baseFeePermille = newBaseFee;

        policy.lastAppliedTimestamp = block.timestamp;

        emit PolicyApplied(_policyId, policy.targetStreamId, policy.dynamicFeeFactor, block.timestamp);
        emit FeesUpdated(currentFeeConfig.baseFeePermille, currentFeeConfig.volatilityMultiplier, currentFeeConfig.catalystFeeSharePermille);
    }

    /**
     * @dev Allows a user to create a Conditional Action, locking ETH which will be transferred
     * if specific conditions within a Prognosis Stream are met by its resolution time.
     * @param _targetStreamId The ID of the Prognosis Stream to monitor.
     * @param _triggerConditions Conditions that must be met for the action to execute.
     * @param _recipient The address to receive the ETH if conditions are met.
     * @param _amount The amount of ETH to lock.
     * @param _actionMetadataURI URI to off-chain details of the action.
     * @return The ID of the new conditional action.
     */
    function createConditionalAction(
        bytes32 _targetStreamId,
        PolicyCondition[] memory _triggerConditions,
        address _recipient,
        uint256 _amount,
        string memory _actionMetadataURI
    ) external payable whenNotPaused returns (bytes32 actionId) {
        if (prognosisStreams[_targetStreamId].id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        if (msg.value != _amount) revert ChronoCaster__InvalidAmount();
        if (_amount == 0) revert ChronoCaster__InvalidAmount();
        require(_recipient != address(0), "ChronoCaster: Recipient cannot be zero address.");
        require(_triggerConditions.length > 0, "ChronoCaster: Action must have at least one trigger condition.");
        require(prognosisStreams[_targetStreamId].resolutionTime > block.timestamp, "ChronoCaster: Target stream has passed resolution time.");

        actionId = keccak256(abi.encodePacked(msg.sender, _targetStreamId, block.timestamp, _amount));

        conditionalActions[actionId] = ConditionalAction({
            id: actionId,
            creator: msg.sender,
            recipient: _recipient,
            amount: _amount,
            targetStreamId: _targetStreamId,
            triggerConditions: _triggerConditions,
            actionMetadataURI: _actionMetadataURI,
            executed: false,
            refunded: false,
            depositTime: block.timestamp,
            triggerAttemptCount: 0
        });

        emit ConditionalActionCreated(actionId, _targetStreamId, msg.sender, _amount);
    }

    /**
     * @dev Allows anyone to attempt to execute a Conditional Action if its trigger conditions are met.
     * This function is typically called by a keeper or automated system.
     * @param _actionId The ID of the Conditional Action to execute.
     */
    function executeConditionalAction(bytes32 _actionId) external whenNotPaused {
        ConditionalAction storage action = conditionalActions[_actionId];
        if (action.id == bytes32(0)) revert ChronoCaster__InvalidConditionalActionId();
        if (action.executed) revert ChronoCaster__ConditionalActionAlreadyExecuted();
        if (action.refunded) revert ChronoCaster__ConditionalActionRefunded();

        PrognosisStream storage stream = prognosisStreams[action.targetStreamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId(); // Should not happen if action exists
        if (stream.state != PrognosisState.Finalized && block.timestamp < stream.resolutionTime) {
            revert ChronoCaster__PrognosisStreamNotYetResolvable();
        }

        action.triggerAttemptCount++; // Record attempt

        if (!_checkPrognosisConditions(action.targetStreamId, action.triggerConditions)) {
            revert ChronoCaster__ConditionalActionConditionsNotMet();
        }

        // Conditions met, execute action
        action.executed = true;
        (bool success, ) = payable(action.recipient).call{value: action.amount}("");
        if (!success) {
            action.executed = false; // Revert state if transfer fails
            revert("ChronoCaster: Failed to transfer funds for conditional action.");
        }
        emit ConditionalActionExecuted(_actionId, action.targetStreamId, action.recipient, action.amount);
    }

    /**
     * @dev Allows the creator of a Conditional Action to refund their locked ETH
     * if the action's conditions were not met by the stream's resolution time.
     * @param _actionId The ID of the Conditional Action to refund.
     */
    function refundConditionalActionDeposit(bytes32 _actionId) external whenNotPaused {
        ConditionalAction storage action = conditionalActions[_actionId];
        if (action.id == bytes32(0) || action.creator != msg.sender) revert ChronoCaster__InvalidConditionalActionId();
        if (action.executed) revert ChronoCaster__ConditionalActionAlreadyExecuted();
        if (action.refunded) revert ChronoCaster__ConditionalActionRefunded();

        PrognosisStream storage stream = prognosisStreams[action.targetStreamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();

        // Refund is only possible if resolution time has passed AND conditions were NOT met
        // Or if the stream was cancelled
        bool conditionsWereNotMet = !_checkPrognosisConditions(action.targetStreamId, action.triggerConditions);
        bool resolutionTimePassed = block.timestamp >= stream.resolutionTime;

        if (!( (resolutionTimePassed && conditionsWereNotMet) || stream.state == PrognosisState.Cancelled )) {
            revert ChronoCaster__ConditionalActionNotRefundableYet();
        }

        action.refunded = true;
        (bool success, ) = payable(action.creator).call{value: action.amount}("");
        if (!success) {
            action.refunded = false;
            revert("ChronoCaster: Failed to refund conditional action deposit.");
        }
        emit ConditionalActionRefunded(_actionId, action.creator, action.amount);
    }

    /**
     * @dev Allows a user to initiate a dispute against a specific data point within a Prognosis Stream.
     * Requires a small stake to prevent spam.
     * @param _streamId The ID of the stream containing the disputed data point.
     * @param _dataPointHash The hash of the data point being disputed.
     * @param _reason A string explaining the reason for the dispute.
     */
    function initiatePrognosisDispute(bytes32 _streamId, bytes32 _dataPointHash, string memory _reason) external payable whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        if (stream.state != PrognosisState.Active) revert ChronoCaster__PrognosisStreamNotActive();
        if (block.timestamp >= stream.predictionEndTime) revert ChronoCaster__PrognosisStreamResolutionPassed();
        require(msg.value > 0, "ChronoCaster: Dispute requires a stake."); // Small stake to initiate

        bool found = false;
        for (uint256 i = 0; i < stream.dataPoints.length; i++) {
            if (stream.dataPoints[i].dataHash == _dataPointHash) {
                if (stream.dataPoints[i].disputed) revert ChronoCaster__PrognosisDataAlreadyDisputed();
                stream.dataPoints[i].disputed = true;
                stream.state = PrognosisState.Disputed; // Entire stream temporarily marked disputed
                stream.disputeStake += msg.value;
                found = true;
                break;
            }
        }
        if (!found) revert ChronoCaster__InvalidDataPointHash();

        emit PrognosisDisputed(_streamId, _dataPointHash, msg.sender);
    }

    /**
     * @dev Resolves a dispute for a specific data point within a Prognosis Stream.
     * Only owner (or a future governance committee) can resolve.
     * @param _streamId The ID of the stream.
     * @param _dataPointHash The hash of the data point.
     * @param _isValid True if the data point is deemed valid, false if invalid.
     */
    function resolvePrognosisDispute(bytes32 _streamId, bytes32 _dataPointHash, bool _isValid) external onlyOwner whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        if (stream.state != PrognosisState.Disputed) revert ChronoCaster__PrognosisDataNotDisputed(); // Stream must be in disputed state

        bool found = false;
        address submitter = address(0);
        uint256 submitterStake = 0;
        for (uint256 i = 0; i < stream.dataPoints.length; i++) {
            if (stream.dataPoints[i].dataHash == _dataPointHash) {
                if (!stream.dataPoints[i].disputed) revert ChronoCaster__PrognosisDataNotDisputed(); // Data point must be disputed
                stream.dataPoints[i].disputed = false; // Dispute resolved for this data point
                stream.dataPoints[i].valid = _isValid;
                submitter = stream.dataPoints[i].submitter;
                submitterStake = stream.dataPoints[i].stake;
                found = true;
                break;
            }
        }
        if (!found) revert ChronoCaster__InvalidDataPointHash();

        // Update catalyst reputation based on dispute outcome
        if (_isValid) {
            _updateCatalystReputation(submitter, 50); // Reward for valid data
            // Distribute dispute stake to successful disputer/governance (omitted for brevity)
        } else {
            _updateCatalystReputation(submitter, -100); // Penalty for invalid data
            // Distribute dispute stake to valid disputer/governance (omitted for brevity)
        }

        // Potentially change stream state back to Active if no more disputes are pending
        bool anyRemainingDisputes = false;
        for (uint256 i = 0; i < stream.dataPoints.length; i++) {
            if (stream.dataPoints[i].disputed) {
                anyRemainingDisputes = true;
                break;
            }
        }
        if (!anyRemainingDisputes) {
            emit PrognosisStateChanged(_streamId, PrognosisState.Disputed, PrognosisState.Active);
            stream.state = PrognosisState.Active;
        }

        emit PrognosisDisputeResolved(_streamId, _dataPointHash, msg.sender, _isValid);
    }

    /**
     * @dev Allows community members to vote on the validity of a data point in a Prognosis Stream.
     * This can influence the reputation of the submitting Catalyst.
     * @param _streamId The ID of the stream.
     * @param _dataPointHash The hash of the data point to vote on.
     * @param _isValid True if voting for validity, false for invalidity.
     */
    function voteOnPrognosisValidity(bytes32 _streamId, bytes256 _dataPointHash, bool _isValid) external whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        // Allow voting only during Active or Disputed states
        require(stream.state == PrognosisState.Active || stream.state == PrognosisState.Disputed, "ChronoCaster: Cannot vote on inactive or finalized streams.");
        
        // This is a simplified voting mechanism. In a full system, you'd need:
        // - To prevent double voting by the same address per data point.
        // - A mechanism to tally votes and trigger reputation updates/dispute resolution automatically.
        // For demonstration, we'll just emit an event.

        // Find the data point (simplified)
        bool found = false;
        address submitter = address(0);
        for(uint256 i = 0; i < stream.dataPoints.length; i++) {
            if (stream.dataPoints[i].dataHash == _dataPointHash) {
                submitter = stream.dataPoints[i].submitter;
                found = true;
                break;
            }
        }
        if (!found) revert ChronoCaster__InvalidDataPointHash();

        // Conceptual reputation impact based on votes
        if (submitter != address(0)) {
            if (_isValid) {
                _updateCatalystReputation(submitter, 1); // Small positive boost for supporting a data point
            } else {
                _updateCatalystReputation(submitter, -1); // Small negative impact for opposing
            }
        }

        emit PrognosisValidityVoted(_streamId, _dataPointHash, msg.sender, _isValid);
    }

    /**
     * @dev Finalizes a Prognosis Stream, setting its final outcome and state.
     * This is crucial for resolving conditional actions and distributing rewards.
     * Only owner (or governance) can finalize.
     * @param _streamId The ID of the stream to finalize.
     * @param _finalStateHash A hash representing the final, verifiable state/outcome.
     */
    function finalizePrognosisStream(bytes32 _streamId, bytes32 _finalStateHash) external onlyOwner whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        if (stream.state == PrognosisState.Finalized || stream.state == PrognosisState.Cancelled) revert ChronoCaster__PrognosisStreamAlreadyFinalized();
        if (block.timestamp < stream.resolutionTime) revert ChronoCaster__PrognosisStreamNotYetResolvable();
        if (stream.state == PrognosisState.Disputed) revert ChronoCaster__PrognosisDataDisputed(); // Must resolve all disputes first

        bytes32 oldFinalHash = stream.finalStateHash; // Keep for comparison if needed
        stream.finalStateHash = _finalStateHash;
        emit PrognosisStateChanged(_streamId, stream.state, PrognosisState.Finalized);
        stream.state = PrognosisState.Finalized;

        // At this point, conditional actions can be executed, and catalyst rewards can be claimed.
        // For simplicity, rewards are claimed separately.
    }

    /**
     * @dev Allows accurate Catalysts to claim their share of rewards from a finalized Prognosis Stream.
     * Rewards are conceptual and need a pool to draw from (e.g., portion of fees, external funding).
     * @param _streamId The ID of the finalized Prognosis Stream.
     */
    function claimPrognosisRewards(bytes32 _streamId) external whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        if (stream.state != PrognosisState.Finalized) revert ChronoCaster__PrognosisStreamNotYetResolvable();

        // This is a simplified reward distribution. In a real system:
        // 1. Calculate accuracy for msg.sender based on their data points vs. final state.
        // 2. Allocate reward from stream.totalRewardPool proportionally to accuracy and stake.
        // 3. Prevent double claims.

        uint256 rewardsToClaim = 0; // Placeholder
        bool isAccurateCatalyst = false;
        for(uint256 i = 0; i < stream.dataPoints.length; i++) {
            if (stream.dataPoints[i].submitter == msg.sender && stream.dataPoints[i].valid) {
                // If data point was valid and contributed, conceptual rewards are calculated
                // Example: If finalStateHash matches a derived outcome from their datapoint, reward.
                // For simplicity, if they have any valid data point in a finalized stream, they get some reward.
                rewardsToClaim += (stream.dataPoints[i].stake * currentFeeConfig.catalystFeeSharePermille) / 1000;
                isAccurateCatalyst = true;
                break; // Claiming simplified to once per stream per catalyst
            }
        }

        require(isAccurateCatalyst && rewardsToClaim > 0, "ChronoCaster: No rewards available or not accurate catalyst for this stream.");

        // Deduct from reward pool and transfer (reward pool needs to be funded by fees or external means)
        // For this example, assuming ChronoCaster holds funds that can be distributed.
        // In a real scenario, ChronoCaster would collect fees into its balance and distribute.
        // Here, we just conceptually "transfer" from a pool.
        (bool success, ) = payable(msg.sender).call{value: rewardsToClaim}("");
        if (!success) {
            revert("ChronoCaster: Failed to transfer rewards.");
        }

        emit ClaimPrognosisRewards(_streamId, msg.sender, rewardsToClaim); // New event
    }

    /**
     * @dev Allows the owner (or a future governance body) to curate (approve/disapprove) a Prognosis Stream.
     * This can affect its visibility, trustworthiness, and eligibility for certain policies/actions.
     * @param _streamId The ID of the stream to curate.
     * @param _isApproved True to approve, false to disapprove.
     */
    function curatePrognosisStream(bytes32 _streamId, bool _isApproved) external onlyOwner whenNotPaused {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        require(stream.state == PrognosisState.Active, "ChronoCaster: Only active streams can be curated.");

        stream.curatedApproved = _isApproved;
        emit PrognosisCurated(_streamId, _isApproved, msg.sender);
    }

    /**
     * @dev Allows a Catalyst to delegate their data submission rights to another address.
     * The delegator remains the primary Catalyst, but the delegate can act on their behalf.
     * @param _delegatee The address to delegate the role to.
     */
    function delegateCatalystRole(address _delegatee) external onlyCatalyst whenNotPaused {
        if (_delegatee == address(0)) revert("ChronoCaster: Delegatee cannot be zero address.");
        if (_delegatee == msg.sender) revert ChronoCaster__SelfDelegationNotAllowed();
        if (delegatedCatalysts[msg.sender] != address(0)) revert ChronoCaster__AlreadyDelegated();

        delegatedCatalysts[msg.sender] = _delegatee;
        emit CatalystDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows a Catalyst to revoke a previously delegated data submission role.
     */
    function revokeDelegatedCatalystRole() external onlyCatalyst whenNotPaused {
        if (delegatedCatalysts[msg.sender] == address(0)) revert ChronoCaster__NotDelegated();

        address revokedDelegatee = delegatedCatalysts[msg.sender];
        delete delegatedCatalysts[msg.sender];
        emit CatalystDelegationRevoked(msg.sender, revokedDelegatee);
    }

    // --- View Functions ---

    /**
     * @dev Retrieves details about a specific Prognosis Stream.
     * @param _streamId The ID of the stream.
     * @return All relevant data for the stream.
     */
    function getPrognosisStreamDetails(bytes32 _streamId)
        external
        view
        returns (
            bytes32 id,
            string memory name,
            string memory description,
            uint256 creationTime,
            uint256 predictionEndTime,
            uint256 resolutionTime,
            PrognosisState state,
            bytes32 initialStateHash,
            bytes32 finalStateHash,
            uint256 dataPointCount,
            uint256 totalRewardPool,
            bool curatedApproved,
            uint256 disputeStake
        )
    {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();
        return (
            stream.id,
            stream.name,
            stream.description,
            stream.creationTime,
            stream.predictionEndTime,
            stream.resolutionTime,
            stream.state,
            stream.initialStateHash,
            stream.finalStateHash,
            stream.dataPoints.length,
            stream.totalRewardPool,
            stream.curatedApproved,
            stream.disputeStake
        );
    }

    /**
     * @dev Retrieves a range of data points from a Prognosis Stream.
     * Useful for off-chain analysis of stream evolution.
     * @param _streamId The ID of the stream.
     * @param _startIndex The starting index of data points to retrieve.
     * @param _count The number of data points to retrieve.
     * @return An array of PrognosisDataPoint structs.
     */
    function getPrognosisStreamDataPoints(bytes32 _streamId, uint256 _startIndex, uint256 _count)
        external
        view
        returns (PrognosisDataPoint[] memory)
    {
        PrognosisStream storage stream = prognosisStreams[_streamId];
        if (stream.id == bytes32(0)) revert ChronoCaster__InvalidPrognosisStreamId();

        uint256 totalDataPoints = stream.dataPoints.length;
        if (_startIndex >= totalDataPoints) {
            return new PrognosisDataPoint[](0);
        }

        uint256 endIndex = _startIndex + _count;
        if (endIndex > totalDataPoints) {
            endIndex = totalDataPoints;
        }

        PrognosisDataPoint[] memory result = new PrognosisDataPoint[](endIndex - _startIndex);
        for (uint256 i = _startIndex; i < endIndex; i++) {
            result[i - _startIndex] = stream.dataPoints[i];
        }
        return result;
    }

    /**
     * @dev Retrieves information about a Catalyst.
     * @param _catalyst The address of the catalyst.
     * @return Their staked amount and reputation score.
     */
    function getCatalystInfo(address _catalyst) external view returns (uint256 stakedAmount, int256 reputationScore, address delegatedTo) {
        return (catalystStakes[_catalyst], catalystReputationScores[_catalyst], delegatedCatalysts[_catalyst]);
    }
}
```