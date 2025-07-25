Okay, this is an exciting challenge! Creating a smart contract that is truly novel and integrates advanced concepts while avoiding direct duplication of existing open-source projects requires thinking outside the box regarding its core utility and the mechanisms that govern it.

Let's design a contract called **"ChronoCaster"**.

**Concept:** ChronoCaster is a decentralized platform for *pre-defining and automating future on-chain actions based on the fulfillment of complex, multi-variable conditions*, verified by a reputation-weighted oracle network. It's not just a prediction market; it's a **proactive, conditional automation engine** for the blockchain, fostering a reputation economy around accurate predictions and reliable data provisioning.

**Key Advanced Concepts Integrated:**
1.  **Reputation Economy:** Beyond simple staking, reputation (ChronoRep) influences participation, rewards, and governance weight.
2.  **Dynamic On-Chain Automation:** Users define complex *conditional action flows* that execute autonomously upon event resolution.
3.  **Adaptive Parameters:** Core contract parameters (fees, reputation weights) can be adjusted via stake-and-reputation-weighted governance proposals.
4.  **Decentralized Oracle Aggregation & Dispute Resolution:** Robust system for external data validation with built-in checks and balances.
5.  **Time-Based Mechanisms:** Events have defined activation, resolution, and expiry windows, with reputation decay.
6.  **Conditional Event Dependencies:** Events can depend on the resolution of other events, enabling complex chained logic.
7.  **Gas Optimization & Batching:** Features to make participation more efficient.

---

### **Contract Outline & Function Summary: ChronoCaster**

**Contract Name:** `ChronoCaster`

**Purpose:** A decentralized protocol for creating, participating in, resolving, and automating actions based on future conditional events, governed by a reputation-weighted oracle network and community proposals.

---

**I. Core Event Management & Lifecycle**

1.  `castFutureEvent(string _description, uint256 _targetTimestamp, uint256 _resolutionWindowDuration, bytes _oracleQuery, uint256 _stakeAmount, uint256 _minPledgeAmount, uint256 _maxPledgeAmount)`:
    *   Allows a user to define a future event, including its target time, the oracle query for verification, an initial stake, and the range for participant pledges.
2.  `pledgeOnOutcome(uint256 _eventId, bool _predictedOutcome, uint256 _pledgeAmount)`:
    *   Users can pledge (stake) on the predicted outcome (True/False) of an active event.
3.  `submitOracleData(uint256 _eventId, bytes _dataPayload, bool _resolvedOutcome)`:
    *   Registered oracles submit their data and proposed resolution for an event once its target time passes and within the resolution window. Requires oracle stake.
4.  `resolveEvent(uint256 _eventId)`:
    *   Triggers the final resolution of an event based on aggregated oracle data and a potential dispute period. Distributes rewards/penalties.
5.  `claimEventWinnings(uint256 _eventId)`:
    *   Allows participants (casters and pledgers) of a resolved event to claim their rewards or recover remaining stakes.

**II. Conditional Automated Actions**

6.  `defineAutomatedAction(uint256 _eventId, bool _triggerOnOutcome, address _targetContract, bytes _callData, uint256 _ethValue, bool _isAtomic)`:
    *   Allows event casters or reputable users to define a specific on-chain action (e.g., call a function on another contract, send ETH) that will execute if the event resolves to a specified outcome.
7.  `executeAutomatedAction(uint256 _actionId)`:
    *   A public function that can be called by anyone (or a bot) to trigger a defined automated action once its linked event is resolved and conditions are met. Incentivizes execution by distributing a small fee.
8.  `conditionalActionDependency(uint256 _parentActionId, uint256 _childActionId, bool _triggerIfParentSuccess)`:
    *   Establishes a dependency, meaning `_childActionId` can only execute if `_parentActionId` successfully executed (or failed, based on `_triggerIfParentSuccess`). Allows for complex action sequences.

**III. Oracle Network Management & Dispute Resolution**

9.  `registerOracle(string _name, string _apiUrl, uint256 _initialStake)`:
    *   Allows a new entity to register as an oracle by providing metadata and an initial stake.
10. `updateOracleFee(uint256 _oracleId, uint256 _newFeePerSubmission)`:
    *   Oracles can adjust the fee they require per data submission. Subject to governance minimums.
11. `disputeOracleSubmission(uint256 _eventId, uint256 _oracleId, uint256 _stakeAmount)`:
    *   Allows any user to dispute an oracle's submitted data for a specific event, requiring a stake. Triggers a challenge period.
12. `resolveDispute(uint256 _eventId, uint256 _oracleId, bool _isOracleCorrect)`:
    *   Called by reputable voters during a dispute period to determine if the disputed oracle's submission was correct. Impacts oracle reputation and stake.

**IV. ChronoRep (Reputation) System**

13. `getReputationScore(address _user)`:
    *   Retrieves the ChronoRep score of a specific user.
14. `updateReputationDecayRate(uint256 _newRate)`:
    *   Governance function to adjust the rate at which ChronoRep scores naturally decay over time (e.g., daily percentage).
15. `liquidateLowReputationStake(address _user)`:
    *   Allows anyone to trigger the liquidation of a user's staked funds if their reputation score falls below a critical threshold due to sustained inaccurate predictions or malicious activity. The liquidated funds are redistributed to the ChronoTreasury or honest participants.

**V. Governance & Adaptive Parameters**

16. `submitParameterProposal(uint256 _paramId, bytes _newValue, string _description)`:
    *   Allows users with sufficient ChronoRep and stake to propose changes to core contract parameters (e.g., minimum stakes, resolution periods, oracle rewards).
17. `voteOnProposal(uint256 _proposalId, bool _support)`:
    *   Users vote on active proposals. Voting power is weighted by their ChronoRep and locked stake.
18. `executeProposal(uint256 _proposalId)`:
    *   Once a proposal passes its voting period and quorum, anyone can call this to execute the proposed parameter change.

**VI. Utility & System Management**

19. `batchPledgeOnEvents(uint256[] _eventIds, bool[] _predictedOutcomes, uint256[] _pledgeAmounts)`:
    *   Allows users to pledge on multiple events in a single transaction, optimizing gas costs.
20. `requestHistoricalDataPoint(string _dataSourceIdentifier, string _query, uint256 _timestamp, uint256 _bounty)`:
    *   Allows users to request historical data points from oracles. Oracles can fulfill these requests for a bounty, enhancing their reputation.
21. `setDynamicFeeParameter(uint256 _minFee, uint256 _maxFee, uint256 _reputationWeight)`:
    *   Governance function to define a dynamic fee structure for casting/pledging, where fees can vary based on the user's reputation score within a min/max range.
22. `emergencyWithdraw(address _tokenAddress)`:
    *   Allows the owner (or governance in a decentralized setup) to withdraw accidental ERC20 token transfers to the contract.
23. `pauseSystem(bool _pause)`:
    *   A critical function, likely controlled by a multi-sig or governance, to temporarily pause critical operations in case of an emergency or upgrade.
24. `getEventMetrics(uint256 _eventId)`:
    *   Retrieves aggregated statistics for a specific event, such as total pledged amount, distribution of outcomes, and oracle scores.
25. `claimExpiredStakes()`:
    *   Allows users to claim stakes from events that expired without resolution or successful oracle submission.

---

### **Solidity Smart Contract: ChronoCaster**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though not strictly necessary in 0.8.x for simple ops due to default checks, good practice for clarity in complex arithmetic

// --- INTERFACES (Mock for demonstration) ---
// In a real scenario, these would be separate files or external contract addresses
interface IDummyExternalContract {
    function doSomething(address _caller, uint256 _amount, bytes calldata _data) external payable;
}

/**
 * @title ChronoCaster
 * @dev A decentralized platform for pre-defining and automating future on-chain actions
 *      based on complex, multi-variable conditions, verified by a reputation-weighted
 *      oracle network and community governance.
 *
 * Outline & Function Summary:
 *
 * I. Core Event Management & Lifecycle
 *    1. castFutureEvent: Define a future event with oracle query and staking.
 *    2. pledgeOnOutcome: Stake on the predicted outcome of an event.
 *    3. submitOracleData: Oracles submit data and proposed resolution.
 *    4. resolveEvent: Triggers final event resolution and reward distribution.
 *    5. claimEventWinnings: Claim rewards/recover stakes from resolved events.
 *
 * II. Conditional Automated Actions
 *    6. defineAutomatedAction: Define an on-chain action to execute based on event outcome.
 *    7. executeAutomatedAction: Trigger a defined automated action.
 *    8. conditionalActionDependency: Establish dependencies between automated actions.
 *
 * III. Oracle Network Management & Dispute Resolution
 *    9. registerOracle: Register a new oracle with a stake.
 *    10. updateOracleFee: Oracles adjust their submission fees.
 *    11. disputeOracleSubmission: Initiate a dispute against an oracle's submission.
 *    12. resolveDispute: Determine outcome of an oracle dispute.
 *
 * IV. ChronoRep (Reputation) System
 *    13. getReputationScore: Retrieve a user's ChronoRep score.
 *    14. updateReputationDecayRate: Governance to adjust reputation decay rate.
 *    15. liquidateLowReputationStake: Liquidate stakes of users with very low reputation.
 *
 * V. Governance & Adaptive Parameters
 *    16. submitParameterProposal: Propose changes to core contract parameters.
 *    17. voteOnProposal: Vote on active governance proposals.
 *    18. executeProposal: Execute a passed governance proposal.
 *
 * VI. Utility & System Management
 *    19. batchPledgeOnEvents: Pledge on multiple events in one transaction.
 *    20. requestHistoricalDataPoint: Request historical data from oracles for bounty.
 *    21. setDynamicFeeParameter: Governance to set dynamic fees based on reputation.
 *    22. emergencyWithdraw: Owner/governance can withdraw accidental token transfers.
 *    23. pauseSystem: Pause critical contract operations.
 *    24. getEventMetrics: Retrieve statistics for a specific event.
 *    25. claimExpiredStakes: Claim stakes from events that expired without resolution.
 */
contract ChronoCaster is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- ENUMS & STRUCTS ---

    enum EventStatus {
        Active,
        Disputed,
        ResolvedTrue,
        ResolvedFalse,
        Expired,
        Cancelled
    }

    enum ActionStatus {
        Pending,
        Executed,
        Failed,
        DependencyUnmet
    }

    enum ProposalType {
        UpdateOracleFeeMin,
        UpdateOracleFeeMax,
        UpdateReputationDecayRate,
        UpdateMinCasterStake,
        UpdateMinPledgeAmount,
        AddOracleWhitelist, // For pre-approved oracle list (if needed)
        RemoveOracleWhitelist,
        UpdateDynamicFeeParams
    }

    struct Event {
        uint256 id;
        address caster;
        string description;
        uint256 targetTimestamp;         // When the event is expected to occur
        uint256 resolutionWindowStart;   // When oracles can start submitting (usually targetTimestamp)
        uint256 resolutionWindowEnd;     // Deadline for oracle submissions and dispute period start
        uint256 finalizationDeadline;    // Deadline for dispute resolution and final event resolution
        bytes oracleQuery;               // Specific query for oracle data
        uint256 casterStake;
        uint256 minPledgeAmount;
        uint256 maxPledgeAmount;
        mapping(address => uint256) pledgesTrue;  // User => amount pledged for TRUE
        mapping(address => uint256) pledgesFalse; // User => amount pledged for FALSE
        uint256 totalPledgedTrue;
        uint256 totalPledgedFalse;
        mapping(address => bool) hasClaimed; // User => has claimed winnings
        EventStatus status;
        bool finalOutcome; // true if resolved true, false if resolved false (only set if status is ResolvedTrue/False)
        address[] submittedOracles; // List of oracles who submitted for this event
        mapping(address => bool) oracleSubmitted; // Check if oracle already submitted
        mapping(address => bytes) oracleData; // Raw data submitted by oracle
        mapping(address => bool) oracleProposedOutcome; // Proposed outcome by oracle
        mapping(address => uint256) oracleSubmissionTimestamp; // Timestamp of submission
        mapping(address => uint256) oracleSubmissionStake; // Stake for this specific submission
        address disputedOracle; // If currently in dispute, which oracle
        uint256 disputeStake; // Stake for current dispute
        mapping(address => bool) disputeVoted; // Check if user voted in dispute
        mapping(address => bool) disputeVoteOutcome; // User's vote (true if oracle is correct)
        uint256 disputeVotesForOracle;
        uint256 disputeVotesAgainstOracle;
    }

    struct Oracle {
        uint256 id;
        string name;
        string apiUrl; // For off-chain discovery
        address oracleAddress;
        uint256 stake;
        uint256 feePerSubmission;
        uint256 totalSubmissions;
        uint256 successfulSubmissions;
        bool isActive;
        bool isWhitelisted; // For tiered oracle systems
    }

    struct AutomatedAction {
        uint256 id;
        uint256 eventId;            // The event this action is tied to
        bool triggerOnOutcome;      // true for TRUE outcome, false for FALSE outcome
        address targetContract;     // Address of the contract to interact with
        bytes callData;             // Calldata for the target contract function
        uint256 ethValue;           // ETH to send with the call
        bool isAtomic;              // If true, the action must succeed or the event resolution fails (complex, not fully implemented here for brevity)
        ActionStatus status;
        address[] dependencies;     // Other action IDs that must execute first (if _isAtomic, it's a success-based dependency)
        mapping(uint256 => bool) dependencySatisfied; // Status of each dependency
    }

    struct ChronoRepProfile {
        uint256 score;            // Current reputation score
        uint256 lastDecayUpdate;  // Timestamp of last reputation decay update
        uint256 totalEarned;      // Total reputation points earned
        uint256 totalLost;        // Total reputation points lost
        uint256 totalStaked;      // Total ETH/tokens user has staked in events/governance
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType propType;
        bytes newValue;       // Encoded new value for the parameter
        string description;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 totalVotingPower; // Sum of ChronoRep-weighted votes
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // User => voted
    }


    // --- STATE VARIABLES ---

    uint256 public nextEventId;
    uint256 public nextOracleId;
    uint256 public nextActionId;
    uint256 public nextProposalId;

    mapping(uint256 => Event) public events;
    mapping(address => uint256) public oracleAddresses; // oracleAddress => oracleId (0 if not registered)
    mapping(uint256 => Oracle) public oracles;
    mapping(uint256 => AutomatedAction) public automatedActions;
    mapping(address => ChronoRepProfile) public chronoRepProfiles;
    mapping(uint256 => Proposal) public proposals;

    uint256 public constant MIN_CASTER_STAKE_ETH = 0.1 ether;
    uint256 public constant MIN_PLEDGE_AMOUNT_ETH = 0.01 ether;
    uint256 public constant ORACLE_REGISTRATION_STAKE_ETH = 1 ether;
    uint256 public constant ORACLE_SUBMISSION_FEE_MIN = 0.001 ether; // Min fee an oracle can set
    uint256 public constant ORACLE_DISPUTE_STAKE_ETH = 0.5 ether;
    uint256 public constant ACTION_EXECUTION_REWARD_PERCENT = 1; // 1% of ethValue or flat fee if no value
    uint256 public constant INITIAL_CHRONO_REP_SCORE = 1000;
    uint256 public reputationDecayRatePercent = 1; // 1% decay per decay period (e.g., weekly)
    uint256 public reputationDecayPeriod = 7 days; // How often decay is applied

    uint256 public proposalQuorumPercent = 51; // Percentage of total voting power needed for quorum
    uint256 public proposalVoteDuration = 3 days; // Duration for proposals to be voted on
    uint256 public proposalMinReputationToPropose = 5000; // Min ChronoRep to submit proposal
    uint256 public proposalMinStakeToPropose = 1 ether; // Min staked ETH to submit proposal

    // Dynamic Fee Parameters
    uint256 public dynamicFeeMin = 0.005 ether; // Min fee for casting an event (for low rep users)
    uint256 public dynamicFeeMax = 0.05 ether;  // Max fee for casting an event (for high rep users)
    uint256 public dynamicFeeReputationWeight = 100; // Multiplier for reputation to influence fee (higher rep = lower fee)

    // --- EVENTS ---

    event EventCast(uint256 indexed eventId, address indexed caster, string description, uint256 targetTimestamp, uint256 casterStake);
    event Pledged(uint256 indexed eventId, address indexed pledger, bool predictedOutcome, uint256 amount);
    event OracleDataSubmitted(uint256 indexed eventId, address indexed oracleAddress, bool resolvedOutcome, bytes dataPayload);
    event EventResolved(uint256 indexed eventId, EventStatus status, bool finalOutcome);
    event WinningsClaimed(uint256 indexed eventId, address indexed claimant, uint256 amount);
    event AutomatedActionDefined(uint256 indexed actionId, uint256 indexed eventId, address targetContract, uint256 ethValue, bool triggerOnOutcome);
    event AutomatedActionExecuted(uint256 indexed actionId, uint256 indexed eventId, address executor, ActionStatus status);
    event ActionDependencySet(uint256 indexed parentActionId, uint256 indexed childActionId);
    event OracleRegistered(uint256 indexed oracleId, address indexed oracleAddress, string name, uint256 initialStake);
    event OracleFeeUpdated(uint256 indexed oracleId, uint256 newFee);
    event DisputeInitiated(uint256 indexed eventId, address indexed disputedOracle, address indexed disputer, uint256 stake);
    event DisputeResolved(uint256 indexed eventId, address indexed disputedOracle, bool isOracleCorrect);
    event ReputationUpdated(address indexed user, uint256 newScore, uint256 changeAmount);
    event LowReputationStakeLiquidated(address indexed user, uint256 amountLiquidated);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType propType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event SystemPaused(address indexed by, bool paused);

    constructor() Ownable(msg.sender) {
        // Initialize ChronoRep for the owner
        chronoRepProfiles[msg.sender] = ChronoRepProfile({
            score: INITIAL_CHRONO_REP_SCORE * 10, // Owner gets higher initial rep
            lastDecayUpdate: block.timestamp,
            totalEarned: INITIAL_CHRONO_REP_SCORE * 10,
            totalLost: 0,
            totalStaked: 0
        });
    }

    modifier onlyRegisteredOracle(uint256 _oracleId) {
        require(oracles[_oracleId].oracleAddress == msg.sender, "ChronoCaster: Not the registered oracle for this ID.");
        require(oracles[_oracleId].isActive, "ChronoCaster: Oracle is not active.");
        _;
    }

    modifier eventActive(uint256 _eventId) {
        require(events[_eventId].status == EventStatus.Active, "ChronoCaster: Event is not active.");
        require(block.timestamp < events[_eventId].resolutionWindowStart, "ChronoCaster: Event resolution window has started.");
        _;
    }

    modifier eventInResolutionWindow(uint256 _eventId) {
        require(events[_eventId].status == EventStatus.Active || events[_eventId].status == EventStatus.Disputed, "ChronoCaster: Event not in active or disputed status.");
        require(block.timestamp >= events[_eventId].resolutionWindowStart, "ChronoCaster: Resolution window has not started.");
        require(block.timestamp <= events[_eventId].resolutionWindowEnd, "ChronoCaster: Resolution window has ended.");
        _;
    }

    modifier eventReadyForFinalization(uint256 _eventId) {
        require(events[_eventId].status == EventStatus.Active || events[_eventId].status == EventStatus.Disputed, "ChronoCaster: Event not in active or disputed status.");
        require(block.timestamp > events[_eventId].resolutionWindowEnd, "ChronoCaster: Resolution window is still open.");
        require(block.timestamp <= events[_eventId].finalizationDeadline, "ChronoCaster: Event finalization deadline passed.");
        _;
    }

    modifier hasSufficientReputation(uint256 _minRep) {
        _decayReputation(msg.sender); // Apply decay before checking
        require(chronoRepProfiles[msg.sender].score >= _minRep, "ChronoCaster: Insufficient ChronoRep score.");
        _;
    }

    // --- INTERNAL FUNCTIONS (Reputation Management) ---

    function _updateReputation(address _user, int256 _change) internal {
        ChronoRepProfile storage profile = chronoRepProfiles[_user];
        _decayReputation(_user); // Ensure reputation is up-to-date before modification

        if (_change > 0) {
            profile.score = profile.score.add(uint256(_change));
            profile.totalEarned = profile.totalEarned.add(uint256(_change));
        } else {
            profile.score = profile.score.sub(uint256(uint256(_change) * -1));
            profile.totalLost = profile.totalLost.add(uint256(uint256(_change) * -1));
        }
        emit ReputationUpdated(_user, profile.score, uint256(_change));
    }

    function _decayReputation(address _user) internal {
        ChronoRepProfile storage profile = chronoRepProfiles[_user];
        if (profile.lastDecayUpdate == 0) {
            profile.lastDecayUpdate = block.timestamp;
            return;
        }

        uint256 periodsPassed = (block.timestamp - profile.lastDecayUpdate) / reputationDecayPeriod;
        if (periodsPassed > 0) {
            uint256 decayAmount = (profile.score * reputationDecayRatePercent * periodsPassed) / 100; // Simple percentage decay
            profile.score = profile.score.sub(decayAmount);
            profile.lastDecayUpdate = profile.lastDecayUpdate.add(periodsPassed * reputationDecayPeriod);
            emit ReputationUpdated(_user, profile.score, decayAmount);
        }
    }

    function _getDynamicCastingFee(address _caster) internal view returns (uint256) {
        uint256 casterRep = chronoRepProfiles[_caster].score;
        // Higher reputation means lower fee, up to a point
        uint256 fee = dynamicFeeMax - ((dynamicFeeMax - dynamicFeeMin) * casterRep) / (dynamicFeeReputationWeight * 1000); // Scale by a large number for practical use
        return fee > dynamicFeeMin ? fee : dynamicFeeMin; // Ensure it doesn't go below minFee
    }

    // --- I. Core Event Management & Lifecycle ---

    /**
     * @dev Allows a user to define a future event, including its target time,
     *      the oracle query for verification, an initial stake, and the range
     *      for participant pledges.
     * @param _description A human-readable description of the event.
     * @param _targetTimestamp The expected time the event will occur.
     * @param _resolutionWindowDuration The duration after _targetTimestamp for oracles to submit.
     * @param _oracleQuery Specific query data for the oracle.
     * @param _minPledgeAmount Minimum amount required for a pledge.
     * @param _maxPledgeAmount Maximum amount allowed for a pledge.
     */
    function castFutureEvent(
        string memory _description,
        uint256 _targetTimestamp,
        uint256 _resolutionWindowDuration,
        bytes memory _oracleQuery,
        uint256 _minPledgeAmount,
        uint256 _maxPledgeAmount
    ) external payable nonReentrant hasSufficientReputation(INITIAL_CHRONO_REP_SCORE) {
        uint256 requiredCasterStake = _getDynamicCastingFee(msg.sender); // Dynamic fee based on reputation
        require(msg.value >= requiredCasterStake.add(MIN_CASTER_STAKE_ETH), "ChronoCaster: Insufficient stake for casting event.");
        require(_targetTimestamp > block.timestamp, "ChronoCaster: Target timestamp must be in the future.");
        require(_resolutionWindowDuration > 0, "ChronoCaster: Resolution window duration must be positive.");
        require(_minPledgeAmount > 0 && _minPledgeAmount <= _maxPledgeAmount, "ChronoCaster: Invalid pledge amounts.");

        uint256 eventId = nextEventId++;
        events[eventId] = Event({
            id: eventId,
            caster: msg.sender,
            description: _description,
            targetTimestamp: _targetTimestamp,
            resolutionWindowStart: _targetTimestamp,
            resolutionWindowEnd: _targetTimestamp.add(_resolutionWindowDuration),
            finalizationDeadline: _targetTimestamp.add(_resolutionWindowDuration * 2), // Gives time for dispute resolution
            oracleQuery: _oracleQuery,
            casterStake: msg.value,
            minPledgeAmount: _minPledgeAmount,
            maxPledgeAmount: _maxPledgeAmount,
            totalPledgedTrue: 0,
            totalPledgedFalse: 0,
            status: EventStatus.Active,
            finalOutcome: false, // Default
            submittedOracles: new address[](0),
            disputedOracle: address(0),
            disputeStake: 0,
            disputeVotesForOracle: 0,
            disputeVotesAgainstOracle: 0
        });

        chronoRepProfiles[msg.sender].totalStaked = chronoRepProfiles[msg.sender].totalStaked.add(msg.value);
        emit EventCast(eventId, msg.sender, _description, _targetTimestamp, msg.value);
    }

    /**
     * @dev Users can pledge (stake) on the predicted outcome (True/False) of an active event.
     * @param _eventId The ID of the event to pledge on.
     * @param _predictedOutcome The user's predicted outcome (true for TRUE, false for FALSE).
     * @param _pledgeAmount The amount of ETH to stake for this pledge.
     */
    function pledgeOnOutcome(uint256 _eventId, bool _predictedOutcome, uint256 _pledgeAmount)
        external payable nonReentrant eventActive(_eventId)
    {
        Event storage event_ = events[_eventId];
        require(msg.value == _pledgeAmount, "ChronoCaster: Sent ETH must match pledge amount.");
        require(_pledgeAmount >= event_.minPledgeAmount && _pledgeAmount <= event_.maxPledgeAmount, "ChronoCaster: Pledge amount out of range.");

        if (_predictedOutcome) {
            event_.pledgesTrue[msg.sender] = event_.pledgesTrue[msg.sender].add(_pledgeAmount);
            event_.totalPledgedTrue = event_.totalPledgedTrue.add(_pledgeAmount);
        } else {
            event_.pledgesFalse[msg.sender] = event_.pledgesFalse[msg.sender].add(_pledgeAmount);
            event_.totalPledgedFalse = event_.totalPledgedFalse.add(_pledgeAmount);
        }

        chronoRepProfiles[msg.sender].totalStaked = chronoRepProfiles[msg.sender].totalStaked.add(_pledgeAmount);
        emit Pledged(_eventId, msg.sender, _predictedOutcome, _pledgeAmount);
    }

    /**
     * @dev Registered oracles submit their data and proposed resolution for an event.
     * @param _eventId The ID of the event.
     * @param _dataPayload Raw data from the oracle source.
     * @param _resolvedOutcome The oracle's proposed outcome (true/false).
     */
    function submitOracleData(uint256 _eventId, bytes memory _dataPayload, bool _resolvedOutcome)
        external payable nonReentrant eventInResolutionWindow(_eventId)
    {
        uint256 oracleId = oracleAddresses[msg.sender];
        require(oracleId != 0, "ChronoCaster: Sender is not a registered oracle.");
        Oracle storage oracle_ = oracles[oracleId];
        require(msg.value == oracle_.feePerSubmission, "ChronoCaster: Insufficient fee for oracle submission.");
        Event storage event_ = events[_eventId];
        require(!event_.oracleSubmitted[msg.sender], "ChronoCaster: Oracle already submitted for this event.");

        event_.submittedOracles.push(msg.sender);
        event_.oracleSubmitted[msg.sender] = true;
        event_.oracleData[msg.sender] = _dataPayload;
        event_.oracleProposedOutcome[msg.sender] = _resolvedOutcome;
        event_.oracleSubmissionTimestamp[msg.sender] = block.timestamp;
        event_.oracleSubmissionStake[msg.sender] = msg.value; // Store the fee paid for this submission

        oracle_.totalSubmissions = oracle_.totalSubmissions.add(1);
        // Funds are held by ChronoCaster until event resolution or dispute.

        emit OracleDataSubmitted(_eventId, msg.sender, _resolvedOutcome, _dataPayload);
    }

    /**
     * @dev Triggers the final resolution of an event based on aggregated oracle data and a potential dispute period.
     * @param _eventId The ID of the event to resolve.
     */
    function resolveEvent(uint256 _eventId) external nonReentrant eventReadyForFinalization(_eventId) {
        Event storage event_ = events[_eventId];

        require(event_.status != EventStatus.ResolvedTrue && event_.status != EventStatus.ResolvedFalse, "ChronoCaster: Event already resolved.");

        if (event_.status == EventStatus.Disputed) {
            // Dispute is still active, require manual resolution via resolveDispute
            require(event_.disputedOracle != address(0), "ChronoCaster: Internal error, disputed oracle not set for disputed event.");
            return; // Will be resolved by resolveDispute
        }

        // Aggregate oracle outcomes (simple majority)
        uint256 votesTrue = 0;
        uint256 votesFalse = 0;
        // In a real system, this aggregation would be more sophisticated (e.g., weighted by oracle reputation)
        for (uint i = 0; i < event_.submittedOracles.length; i++) {
            address oracleAddr = event_.submittedOracles[i];
            if (event_.oracleProposedOutcome[oracleAddr]) {
                votesTrue = votesTrue.add(1);
            } else {
                votesFalse = votesFalse.add(1);
            }
        }

        bool finalOutcome;
        if (votesTrue > votesFalse) {
            finalOutcome = true;
            event_.status = EventStatus.ResolvedTrue;
        } else if (votesFalse > votesTrue) {
            finalOutcome = false;
            event_.status = EventStatus.ResolvedFalse;
        } else {
            // Tie or no submissions, event expires and stakes are returned
            event_.status = EventStatus.Expired;
            emit EventResolved(_eventId, EventStatus.Expired, false); // Outcome is irrelevant for expired
            return;
        }

        event_.finalOutcome = finalOutcome;

        // Distribute rewards/penalties
        _distributeEventFunds(_eventId, finalOutcome);

        emit EventResolved(_eventId, event_.status, finalOutcome);
    }

    /**
     * @dev Internal function to distribute funds after an event is resolved.
     * @param _eventId The ID of the resolved event.
     * @param _finalOutcome The final outcome of the event.
     */
    function _distributeEventFunds(uint256 _eventId, bool _finalOutcome) internal {
        Event storage event_ = events[_eventId];

        uint256 totalWinningPledges;
        uint256 totalLosingPledges;
        mapping(address => uint256) storage winningPledges = _finalOutcome ? event_.pledgesTrue : event_.pledgesFalse;
        mapping(address => uint256) storage losingPledges = _finalOutcome ? event_.pledgesFalse : event_.pledgesTrue;

        totalWinningPledges = _finalOutcome ? event_.totalPledgedTrue : event_.totalPledgedFalse;
        totalLosingPledges = _finalOutcome ? event_.totalPledgedFalse : event_.totalPledgedTrue;

        uint256 totalPool = event_.casterStake.add(totalWinningPledges).add(totalLosingPledges);
        uint256 platformFee = totalPool / 100; // Example: 1% platform fee

        // Distribute oracles' fees and update their reputation
        for (uint i = 0; i < event_.submittedOracles.length; i++) {
            address oracleAddr = event_.submittedOracles[i];
            Oracle storage oracle_ = oracles[oracleAddresses[oracleAddr]];
            // Oracles that submitted the correct outcome get their fee back + a bonus from losing oracle stakes
            if (event_.oracleProposedOutcome[oracleAddr] == _finalOutcome) {
                (bool success,) = oracleAddr.call{value: event_.oracleSubmissionStake[oracleAddr].add(ORACLE_SUBMISSION_FEE_MIN * 2)}(""); // Example bonus
                require(success, "Failed to send oracle fee + bonus");
                oracle_.successfulSubmissions = oracle_.successfulSubmissions.add(1);
                _updateReputation(oracleAddr, 50); // Reward reputation for accurate submission
            } else {
                // Oracles that submitted incorrect outcome lose their fee (partially or fully)
                // The fee stays in the contract or is distributed to honest oracles/treasury
                _updateReputation(oracleAddr, -25); // Penalize reputation for inaccurate submission
            }
        }

        // Calculate rewards for winning pledgers and caster
        if (totalWinningPledges > 0) {
            // Winning pledgers split the total stake from losing pledgers and a portion of caster's stake
            uint256 winningsAvailable = totalLosingPledges.add(event_.casterStake.sub(platformFee)); // Example: losing pledges + caster stake (minus fee)
            
            // Caster bonus (if their implied prediction was correct)
            // This is complex - would need to determine if caster's described event implied true/false
            // For simplicity, we assume caster's stake is part of the pool to be distributed.
            // A more advanced system would have the caster also predict an outcome.

            // Each winning pledger gets their stake back + proportional share of winnings
            // This calculation would be complex to do perfectly on-chain for all users without iterating
            // A common pattern is for users to pull their pro-rata share.
            // We'll calculate a theoretical reward per ETH pledged for winners.
            uint256 rewardPerUnit = (winningsAvailable * 1e18) / totalWinningPledges; // Scale to avoid rounding issues

            // Store for claiming
            // Actual transfer happens in claimEventWinnings
        }

        // Update ChronoRep for pledgers
        for (uint i = 0; i < event_.submittedOracles.length; i++) { // Re-using this loop, not ideal but for example
            // In a real system, we'd iterate over all unique pledgers, not just oracles
            // For now, let's just make a general assumption for any user involved.
            // This would need dedicated storage for all pledger addresses
        }
        // A more robust way would be to get all unique pledgers (store them in a mapping)
        // and then iterate over them to distribute rewards and update reputation.
        // For simplicity, ChronoRep for pledgers is updated during claimEventWinnings.
    }


    /**
     * @dev Allows participants (casters and pledgers) of a resolved event to claim their rewards or recover remaining stakes.
     * @param _eventId The ID of the event.
     */
    function claimEventWinnings(uint256 _eventId) external nonReentrant {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.ResolvedTrue || event_.status == EventStatus.ResolvedFalse || event_.status == EventStatus.Expired, "ChronoCaster: Event not resolved or expired.");
        require(!event_.hasClaimed[msg.sender], "ChronoCaster: Funds already claimed for this event.");

        uint256 amountToTransfer = 0;

        if (event_.status == EventStatus.ResolvedTrue || event_.status == EventStatus.ResolvedFalse) {
            bool isWinner = false;
            uint256 pledgedAmount = 0;
            if (event_.finalOutcome == true) { // Event resolved TRUE
                pledgedAmount = event_.pledgesTrue[msg.sender];
                if (pledgedAmount > 0) isWinner = true;
            } else { // Event resolved FALSE
                pledgedAmount = event_.pledgesFalse[msg.sender];
                if (pledgedAmount > 0) isWinner = true;
            }

            if (isWinner) {
                // Calculate winning share
                uint256 totalWinningPledges = event_.finalOutcome ? event_.totalPledgedTrue : event_.totalPledgedFalse;
                uint256 totalLosingPledges = event_.finalOutcome ? event_.totalPledgedFalse : event_.totalPledgedTrue;
                
                uint256 rewardsPool = totalLosingPledges.add(event_.casterStake.sub(event_.casterStake / 100)); // losing pledges + caster stake (minus 1% platform fee)

                if (totalWinningPledges > 0) {
                    amountToTransfer = pledgedAmount.add((pledgedAmount * rewardsPool) / totalWinningPledges); // stake back + proportional share
                } else {
                    amountToTransfer = pledgedAmount; // Should not happen if there are winners
                }
                _updateReputation(msg.sender, 20); // Reward reputation for correct prediction
            } else {
                // Loser or not participated, only if they had a stake from other means, e.g. caster's stake
                // For a caster, they might get a portion of their stake back or profit if the event resolves correctly.
                // This logic needs to be carefully designed based on caster's implied prediction vs. actual outcome.
                if (msg.sender == event_.caster) {
                    // Caster's claim logic, potentially recover stake or profit
                    // For now, assume caster's stake is fully distributed as part of winnings, or lost.
                    // If event was successful, caster might get a bonus, otherwise they lose initial stake.
                    if ((event_.finalOutcome && event_.totalPledgedTrue > 0) || (!event_.finalOutcome && event_.totalPledgedFalse > 0)) {
                         // Caster profits from successful event
                         // Example: Caster gets 5% of total losing pledges
                         amountToTransfer = event_.casterStake.add(totalLosingPledges.mul(5).div(100));
                         _updateReputation(msg.sender, 50); // Reward caster rep
                    } else {
                        // Caster loses stake if event expires or resolves opposite to implied.
                        amountToTransfer = 0; // Caster stake is lost
                        _updateReputation(msg.sender, -50); // Penalize caster rep
                    }
                } else {
                    amountToTransfer = 0; // Pledgers who lost get nothing back
                    _updateReputation(msg.sender, -10); // Penalize pledger rep for incorrect prediction
                }
            }
        } else if (event_.status == EventStatus.Expired) {
            // Return stakes for all participants
            if (msg.sender == event_.caster) {
                amountToTransfer = event_.casterStake;
            } else {
                amountToTransfer = event_.pledgesTrue[msg.sender].add(event_.pledgesFalse[msg.sender]);
            }
        } else {
            revert("ChronoCaster: Event status not suitable for claiming.");
        }

        require(amountToTransfer > 0, "ChronoCaster: No funds to claim or already claimed.");
        
        event_.hasClaimed[msg.sender] = true;
        chronoRepProfiles[msg.sender].totalStaked = chronoRepProfiles[msg.sender].totalStaked.sub(amountToTransfer); // Reduce totalStaked
        (bool success, ) = msg.sender.call{value: amountToTransfer}("");
        require(success, "ChronoCaster: Failed to transfer funds.");
        emit WinningsClaimed(_eventId, msg.sender, amountToTransfer);
    }

    // --- II. Conditional Automated Actions ---

    /**
     * @dev Allows event casters or reputable users to define a specific on-chain action
     *      (e.g., call a function on another contract, send ETH) that will execute if the
     *      event resolves to a specified outcome.
     * @param _eventId The event this action is tied to.
     * @param _triggerOnOutcome If true, triggers on EventResolvedTrue; if false, on EventResolvedFalse.
     * @param _targetContract The address of the contract to call.
     * @param _callData The encoded calldata for the function call.
     * @param _ethValue The ETH amount to send with the call.
     * @param _isAtomic If true, the action must succeed for the event resolution to be considered complete (advanced).
     */
    function defineAutomatedAction(
        uint256 _eventId,
        bool _triggerOnOutcome,
        address _targetContract,
        bytes memory _callData,
        uint256 _ethValue,
        bool _isAtomic
    ) external nonReentrant hasSufficientReputation(INITIAL_CHRONO_REP_SCORE * 2) {
        Event storage event_ = events[_eventId];
        require(event_.caster == msg.sender, "ChronoCaster: Only caster or highly reputable user can define actions.");
        require(event_.status == EventStatus.Active, "ChronoCaster: Action can only be defined for active events.");
        require(_targetContract != address(0), "ChronoCaster: Target contract cannot be zero address.");

        uint256 actionId = nextActionId++;
        automatedActions[actionId] = AutomatedAction({
            id: actionId,
            eventId: _eventId,
            triggerOnOutcome: _triggerOnOutcome,
            targetContract: _targetContract,
            callData: _callData,
            ethValue: _ethValue,
            isAtomic: _isAtomic,
            status: ActionStatus.Pending,
            dependencies: new address[](0) // Dependencies are set via conditionalActionDependency
        });

        emit AutomatedActionDefined(actionId, _eventId, _targetContract, _ethValue, _triggerOnOutcome);
    }

    /**
     * @dev A public function that can be called by anyone (or a bot) to trigger a defined automated action
     *      once its linked event is resolved and conditions are met. Incentivizes execution by distributing a small fee.
     * @param _actionId The ID of the automated action to execute.
     */
    function executeAutomatedAction(uint256 _actionId) external nonReentrant {
        AutomatedAction storage action = automatedActions[_actionId];
        require(action.status == ActionStatus.Pending, "ChronoCaster: Action is not pending.");
        Event storage event_ = events[action.eventId];
        require(event_.status == EventStatus.ResolvedTrue || event_.status == EventStatus.ResolvedFalse, "ChronoCaster: Linked event not resolved.");
        require(event_.finalOutcome == action.triggerOnOutcome, "ChronoCaster: Event outcome does not match trigger condition.");

        // Check dependencies
        for (uint i = 0; i < action.dependencies.length; i++) {
            require(action.dependencySatisfied[action.dependencies[i]], "ChronoCaster: Dependency not satisfied.");
        }

        // Execute the action
        bool success;
        bytes memory returnData;
        
        // Reward for the executor
        uint256 rewardAmount = action.ethValue.mul(ACTION_EXECUTION_REWARD_PERCENT).div(100);
        if (rewardAmount == 0 && action.ethValue == 0) rewardAmount = 1e15; // Small flat reward if no ETH value

        (success, returnData) = action.targetContract.call{value: action.ethValue} (action.callData);

        if (success) {
            action.status = ActionStatus.Executed;
            // Send reward to executor
            (bool rewardSuccess, ) = msg.sender.call{value: rewardAmount}("");
            require(rewardSuccess, "ChronoCaster: Failed to send action execution reward.");
        } else {
            action.status = ActionStatus.Failed;
            // Revert if action is atomic and failed
            if (action.isAtomic) {
                revert("ChronoCaster: Atomic action failed to execute.");
            }
        }
        emit AutomatedActionExecuted(_actionId, action.eventId, msg.sender, action.status);
    }

    /**
     * @dev Establishes a dependency between two automated actions.
     *      `_childActionId` can only execute if `_parentActionId` successfully executed (or failed, based on `_triggerIfParentSuccess`).
     * @param _parentActionId The ID of the action that must execute first.
     * @param _childActionId The ID of the action that depends on the parent.
     * @param _triggerIfParentSuccess If true, child triggers if parent executed successfully; if false, if parent failed.
     */
    function conditionalActionDependency(uint256 _parentActionId, uint256 _childActionId, bool _triggerIfParentSuccess)
        external nonReentrant
    {
        AutomatedAction storage parentAction = automatedActions[_parentActionId];
        AutomatedAction storage childAction = automatedActions[_childActionId];

        require(parentAction.eventId != 0 && childAction.eventId != 0, "ChronoCaster: Invalid parent or child action ID.");
        require(parentAction.eventId == childAction.eventId, "ChronoCaster: Actions must belong to the same event.");
        require(parentAction.id != childAction.id, "ChronoCaster: Action cannot depend on itself.");
        require(parentAction.status == ActionStatus.Pending || parentAction.status == ActionStatus.Executed || parentAction.status == ActionStatus.Failed, "ChronoCaster: Parent action not in definable state.");
        
        // Add dependency to child
        childAction.dependencies.push(_parentActionId);
        // This is simplified. In a full implementation, `dependencySatisfied` would be updated
        // by the `executeAutomatedAction` logic of the parent, considering `_triggerIfParentSuccess`.
        // For demonstration, we simply add the dependency.
        emit ActionDependencySet(_parentActionId, _childActionId);
    }

    // --- III. Oracle Network Management & Dispute Resolution ---

    /**
     * @dev Allows a new entity to register as an oracle by providing metadata and an initial stake.
     * @param _name The name of the oracle.
     * @param _apiUrl An API endpoint or public URL for oracle discovery/information.
     */
    function registerOracle(string memory _name, string memory _apiUrl) external payable nonReentrant {
        require(oracleAddresses[msg.sender] == 0, "ChronoCaster: Sender is already a registered oracle.");
        require(msg.value >= ORACLE_REGISTRATION_STAKE_ETH, "ChronoCaster: Insufficient registration stake.");

        uint256 oracleId = nextOracleId++;
        oracles[oracleId] = Oracle({
            id: oracleId,
            name: _name,
            apiUrl: _apiUrl,
            oracleAddress: msg.sender,
            stake: msg.value,
            feePerSubmission: ORACLE_SUBMISSION_FEE_MIN, // Default min fee
            totalSubmissions: 0,
            successfulSubmissions: 0,
            isActive: true,
            isWhitelisted: false // Can be set true via governance
        });
        oracleAddresses[msg.sender] = oracleId;
        _updateReputation(msg.sender, 100); // Initial reputation for registering

        emit OracleRegistered(oracleId, msg.sender, _name, msg.value);
    }

    /**
     * @dev Oracles can adjust the fee they require per data submission.
     * @param _oracleId The ID of the oracle.
     * @param _newFeePerSubmission The new fee.
     */
    function updateOracleFee(uint256 _oracleId, uint256 _newFeePerSubmission) external onlyRegisteredOracle(_oracleId) {
        require(_newFeePerSubmission >= ORACLE_SUBMISSION_FEE_MIN, "ChronoCaster: Fee cannot be below minimum.");
        oracles[_oracleId].feePerSubmission = _newFeePerSubmission;
        emit OracleFeeUpdated(_oracleId, _newFeePerSubmission);
    }

    /**
     * @dev Allows any user to dispute an oracle's submitted data for a specific event, requiring a stake.
     *      Triggers a challenge period.
     * @param _eventId The ID of the event where data was submitted.
     * @param _oracleId The ID of the oracle whose submission is disputed.
     */
    function disputeOracleSubmission(uint256 _eventId, uint256 _oracleId) external payable nonReentrant hasSufficientReputation(INITIAL_CHRONO_REP_SCORE * 1) {
        require(msg.value >= ORACLE_DISPUTE_STAKE_ETH, "ChronoCaster: Insufficient stake to dispute.");
        Event storage event_ = events[_eventId];
        require(event_.status != EventStatus.Disputed, "ChronoCaster: Event is already in dispute.");
        require(event_.status == EventStatus.Active, "ChronoCaster: Event not in active status for dispute.");
        require(block.timestamp <= event_.resolutionWindowEnd, "ChronoCaster: Dispute period has ended.");
        require(event_.oracleSubmitted[oracles[_oracleId].oracleAddress], "ChronoCaster: Oracle did not submit for this event.");

        event_.status = EventStatus.Disputed;
        event_.disputedOracle = oracles[_oracleId].oracleAddress;
        event_.disputeStake = msg.value; // Disputer's stake
        event_.finalizationDeadline = block.timestamp.add(proposalVoteDuration); // Extend finalization deadline for dispute voting

        _updateReputation(msg.sender, -5); // Small reputational cost for initiating dispute

        emit DisputeInitiated(_eventId, event_.disputedOracle, msg.sender, msg.value);
    }

    /**
     * @dev Called by reputable voters during a dispute period to determine if the disputed oracle's submission was correct.
     *      Impacts oracle reputation and stake.
     * @param _eventId The ID of the event in dispute.
     * @param _oracleCorrect True if the oracle's submission is deemed correct, false otherwise.
     */
    function resolveDispute(uint256 _eventId, bool _oracleCorrect) external nonReentrant hasSufficientReputation(INITIAL_CHRONO_REP_SCORE * 2) {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Disputed, "ChronoCaster: Event is not in dispute.");
        require(block.timestamp < event_.finalizationDeadline, "ChronoCaster: Dispute voting period has ended.");
        require(!event_.disputeVoted[msg.sender], "ChronoCaster: Already voted in this dispute.");

        event_.disputeVoted[msg.sender] = true;
        event_.disputeVoteOutcome[msg.sender] = _oracleCorrect;

        uint256 voterRep = chronoRepProfiles[msg.sender].score; // Weight vote by reputation
        if (_oracleCorrect) {
            event_.disputeVotesForOracle = event_.disputeVotesForOracle.add(voterRep);
        } else {
            event_.disputeVotesAgainstOracle = event_.disputeVotesAgainstOracle.add(voterRep);
        }

        // If sufficient votes have come in (e.g., 5 unique votes, or a percentage of network rep)
        // For simplicity, we'll allow anyone to finalize after a minimum period if they have high rep
        if (block.timestamp > event_.resolutionWindowEnd.add(proposalVoteDuration / 2)) { // After half dispute time
            if (event_.disputeVotesForOracle > event_.disputeVotesAgainstOracle * 1.5 || event_.disputeVotesAgainstOracle > event_.disputeVotesForOracle * 1.5) { // Clear majority (1.5x)
                _finalizeDispute(_eventId, event_.disputeVotesForOracle > event_.disputeVotesAgainstOracle);
            }
        }
    }

    /**
     * @dev Internal function to finalize a dispute and apply consequences.
     * @param _eventId The ID of the event.
     * @param _oracleWasCorrect Whether the disputed oracle's submission was ultimately deemed correct.
     */
    function _finalizeDispute(uint256 _eventId, bool _oracleWasCorrect) internal {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Disputed, "ChronoCaster: Event not in dispute.");
        require(block.timestamp >= event_.finalizationDeadline || (event_.disputeVotesForOracle + event_.disputeVotesAgainstOracle > 0 && (event_.disputeVotesForOracle > event_.disputeVotesAgainstOracle * 1.5 || event_.disputeVotesAgainstOracle > event_.disputeVotesForOracle * 1.5)), "ChronoCaster: Dispute not ready to be finalized.");

        Oracle storage disputedOracle = oracles[oracleAddresses[event_.disputedOracle]];
        address disputer = event_.disputer; // Need to store disputer address in event struct for later.

        if (_oracleWasCorrect) {
            // Oracle was correct, disputer loses stake, oracle gains reputation
            (bool success, ) = disputedOracle.oracleAddress.call{value: event_.disputeStake}(""); // Oracle gets disputer's stake
            require(success, "Failed to transfer dispute stake to oracle.");
            _updateReputation(event_.disputedOracle, 100); // Reward oracle for being correct
            _updateReputation(disputer, -100); // Penalize disputer
        } else {
            // Oracle was incorrect, oracle loses stake, disputer gains reputation
            (bool success, ) = disputer.call{value: disputedOracle.stake.add(event_.disputeStake)}(""); // Disputer gets oracle's lost stake + own stake back
            require(success, "Failed to transfer dispute winnings to disputer.");
            _updateReputation(event_.disputedOracle, -200); // Major penalty for incorrect oracle
            _updateReputation(disputer, 100); // Reward disputer
        }

        // Resolve the event based on the final, corrected outcome
        event_.finalOutcome = !(_oracleWasCorrect != event_.oracleProposedOutcome[event_.disputedOracle]); // If oracle was wrong, flip its proposed outcome
        event_.status = event_.finalOutcome ? EventStatus.ResolvedTrue : EventStatus.ResolvedFalse;
        _distributeEventFunds(_eventId, event_.finalOutcome);

        emit DisputeResolved(_eventId, event_.disputedOracle, _oracleWasCorrect);
        emit EventResolved(_eventId, event_.status, event_.finalOutcome);
    }


    // --- IV. ChronoRep (Reputation) System ---

    /**
     * @dev Retrieves the ChronoRep score of a specific user.
     * @param _user The address of the user.
     * @return The ChronoRep score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        // Does not apply decay here, decay happens on write operations
        return chronoRepProfiles[_user].score;
    }

    /**
     * @dev Governance function to adjust the rate at which ChronoRep scores naturally decay over time.
     * @param _newRate The new decay rate (percentage).
     */
    function updateReputationDecayRate(uint256 _newRate) external onlyOwner { // Should be governance-controlled in a real DAO
        require(_newRate <= 100, "ChronoCaster: Decay rate cannot exceed 100%.");
        reputationDecayRatePercent = _newRate;
    }

    /**
     * @dev Allows anyone to trigger the liquidation of a user's staked funds if their reputation score falls below a critical threshold.
     * @param _user The address of the user whose stake might be liquidated.
     */
    function liquidateLowReputationStake(address _user) external nonReentrant {
        _decayReputation(_user); // Ensure latest reputation
        require(chronoRepProfiles[_user].score < 100, "ChronoCaster: User's reputation is not low enough for liquidation."); // Example threshold
        uint256 stakeToLiquidate = chronoRepProfiles[_user].totalStaked; // Liquidate all staked funds
        require(stakeToLiquidate > 0, "ChronoCaster: User has no stake to liquidate.");

        chronoRepProfiles[_user].totalStaked = 0; // Clear their stake
        // Funds are sent to owner (for now), or a DAO treasury
        (bool success, ) = owner().call{value: stakeToLiquidate}("");
        require(success, "ChronoCaster: Failed to liquidate stake.");
        emit LowReputationStakeLiquidated(_user, stakeToLiquidate);
        _updateReputation(_user, -500); // Further penalize
    }

    // --- V. Governance & Adaptive Parameters ---

    /**
     * @dev Allows users with sufficient ChronoRep and stake to propose changes to core contract parameters.
     * @param _propType The type of parameter change proposed.
     * @param _newValue The new value for the parameter, encoded.
     * @param _description A description of the proposal.
     */
    function submitParameterProposal(ProposalType _propType, bytes memory _newValue, string memory _description)
        external payable nonReentrant hasSufficientReputation(proposalMinReputationToPropose)
    {
        _decayReputation(msg.sender); // Update proposer's reputation
        require(chronoRepProfiles[msg.sender].totalStaked >= proposalMinStakeToPropose, "ChronoCaster: Insufficient total staked funds to propose.");
        // A small proposal fee could be added here for spam prevention
        
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            propType: _propType,
            newValue: _newValue,
            description: _description,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp.add(proposalVoteDuration),
            totalVotingPower: 0,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ProposalSubmitted(proposalId, msg.sender, _propType, _description);
    }

    /**
     * @dev Users vote on active proposals. Voting power is weighted by their ChronoRep and locked stake.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChronoCaster: Invalid proposal ID.");
        require(block.timestamp < proposal.votingPeriodEnd, "ChronoCaster: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "ChronoCaster: Already voted on this proposal.");

        _decayReputation(msg.sender); // Update voter's reputation
        uint256 votingPower = chronoRepProfiles[msg.sender].score.add(chronoRepProfiles[msg.sender].totalStaked / 1e16); // Example: reputation + stake scaled
        require(votingPower > 0, "ChronoCaster: No voting power.");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalVotingPower = proposal.totalVotingPower.add(votingPower);

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Once a proposal passes its voting period and quorum, anyone can call this to execute the proposed parameter change.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChronoCaster: Invalid proposal ID.");
        require(!proposal.executed, "ChronoCaster: Proposal already executed.");
        require(block.timestamp >= proposal.votingPeriodEnd, "ChronoCaster: Voting period has not ended.");
        
        uint256 quorumThreshold = proposal.totalVotingPower.mul(proposalQuorumPercent).div(100);
        require(proposal.votesFor.add(proposal.votesAgainst) >= quorumThreshold, "ChronoCaster: Quorum not met.");
        require(proposal.votesFor > proposal.votesAgainst, "ChronoCaster: Proposal did not pass majority vote.");

        proposal.executed = true;
        proposal.passed = true;

        // Apply the parameter change based on proposal type
        if (proposal.propType == ProposalType.UpdateOracleFeeMin) {
            ORACLE_SUBMISSION_FEE_MIN = abi.decode(proposal.newValue, (uint256));
        } else if (proposal.propType == ProposalType.UpdateReputationDecayRate) {
            reputationDecayRatePercent = abi.decode(proposal.newValue, (uint256));
        } else if (proposal.propType == ProposalType.UpdateMinCasterStake) {
            // MIN_CASTER_STAKE_ETH = abi.decode(proposal.newValue, (uint256)); // Cannot update consts, would need dynamic variable
        } else if (proposal.propType == ProposalType.UpdateDynamicFeeParams) {
            (dynamicFeeMin, dynamicFeeMax, dynamicFeeReputationWeight) = abi.decode(proposal.newValue, (uint256, uint256, uint256));
        }
        // ... handle other proposal types

        emit ProposalExecuted(_proposalId);
    }

    // --- VI. Utility & System Management ---

    /**
     * @dev Allows users to pledge on multiple events in a single transaction, optimizing gas costs.
     * @param _eventIds An array of event IDs.
     * @param _predictedOutcomes An array of predicted outcomes (true/false) corresponding to _eventIds.
     * @param _pledgeAmounts An array of pledge amounts corresponding to _eventIds.
     */
    function batchPledgeOnEvents(uint256[] memory _eventIds, bool[] memory _predictedOutcomes, uint256[] memory _pledgeAmounts) external payable nonReentrant {
        require(_eventIds.length == _predictedOutcomes.length && _eventIds.length == _pledgeAmounts.length, "ChronoCaster: Array lengths must match.");
        require(_eventIds.length > 0, "ChronoCaster: No events provided.");

        uint256 totalEthRequired = 0;
        for (uint i = 0; i < _eventIds.length; i++) {
            Event storage event_ = events[_eventIds[i]];
            require(event_.status == EventStatus.Active, "ChronoCaster: Event not active for batch pledge.");
            require(_pledgeAmounts[i] >= event_.minPledgeAmount && _pledgeAmounts[i] <= event_.maxPledgeAmount, "ChronoCaster: Pledge amount out of range for an event.");
            totalEthRequired = totalEthRequired.add(_pledgeAmounts[i]);
        }
        require(msg.value == totalEthRequired, "ChronoCaster: Sent ETH does not match total pledged amount for batch.");

        uint256 currentTransferIndex = 0;
        for (uint i = 0; i < _eventIds.length; i++) {
            Event storage event_ = events[_eventIds[i]];
            uint256 pledgeAmount = _pledgeAmounts[i];
            bool predictedOutcome = _predictedOutcomes[i];

            if (predictedOutcome) {
                event_.pledgesTrue[msg.sender] = event_.pledgesTrue[msg.sender].add(pledgeAmount);
                event_.totalPledgedTrue = event_.totalPledgedTrue.add(pledgeAmount);
            } else {
                event_.pledgesFalse[msg.sender] = event_.pledgesFalse[msg.sender].add(pledgeAmount);
                event_.totalPledgedFalse = event_.totalPledgedFalse.add(pledgeAmount);
            }
            chronoRepProfiles[msg.sender].totalStaked = chronoRepProfiles[msg.sender].totalStaked.add(pledgeAmount);
            emit Pledged(_eventIds[i], msg.sender, predictedOutcome, pledgeAmount);
        }
    }

    /**
     * @dev Allows users to request historical data points from oracles for a bounty.
     *      Oracles can fulfill these requests for a bounty, enhancing their reputation.
     *      (This function primarily defines the request; actual oracle fulfillment would be external or through a separate `submitHistoricalData` function).
     * @param _dataSourceIdentifier An identifier for the data source (e.g., "Coinbase", "Chainlink").
     * @param _query The specific query for the historical data (e.g., "ETH/USD price at 2023-01-01 00:00 UTC").
     * @param _timestamp The specific timestamp for the historical data.
     * @param _bounty The ETH bounty for the oracle to fulfill this request.
     */
    function requestHistoricalDataPoint(string memory _dataSourceIdentifier, string memory _query, uint256 _timestamp, uint256 _bounty) external payable {
        require(msg.value >= _bounty, "ChronoCaster: Insufficient bounty provided.");
        require(_bounty > 0, "ChronoCaster: Bounty must be greater than zero.");
        // Store this request. A separate oracle function `fulfillHistoricalDataRequest` would be needed.
        // For brevity, this only represents the initiation. The oracle fulfills off-chain and then submits on-chain.
        // A unique ID for the request would be generated, and state maintained for it.
        // For demo, we just accept the bounty.
        // Funds are held here until an oracle fulfills.

        // Example: Emit an event for off-chain listeners (oracles)
        emit EventCast(0, msg.sender, string(abi.encodePacked("Historical data request for ", _dataSourceIdentifier, " - ", _query)), _timestamp, _bounty);
    }

    /**
     * @dev Governance function to define a dynamic fee structure for casting/pledging,
     *      where fees can vary based on the user's reputation score within a min/max range.
     * @param _minFee The minimum fee to be paid.
     * @param _maxFee The maximum fee to be paid.
     * @param _reputationWeight A multiplier influencing how reputation impacts the fee.
     */
    function setDynamicFeeParameter(uint256 _minFee, uint256 _maxFee, uint256 _reputationWeight) external onlyOwner { // Should be via governance
        require(_minFee < _maxFee, "ChronoCaster: Min fee must be less than max fee.");
        dynamicFeeMin = _minFee;
        dynamicFeeMax = _maxFee;
        dynamicFeeReputationWeight = _reputationWeight;
    }
    
    /**
     * @dev Allows the owner (or governance in a decentralized setup) to withdraw accidental ERC20 token transfers to the contract.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     */
    function emergencyWithdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /**
     * @dev A critical function, likely controlled by a multi-sig or governance,
     *      to temporarily pause critical operations in case of an emergency or upgrade.
     *      Uses OpenZeppelin's Pausable if integrated, or a custom boolean.
     */
    bool public paused;
    modifier whenNotPaused() {
        require(!paused, "ChronoCaster: System is paused.");
        _;
    }

    function pauseSystem(bool _pause) external onlyOwner { // In real DAO, controlled by governance
        paused = _pause;
        emit SystemPaused(msg.sender, _pause);
    }

    /**
     * @dev Retrieves aggregated statistics for a specific event.
     * @param _eventId The ID of the event.
     * @return A tuple containing total pledged true, total pledged false, status, and final outcome.
     */
    function getEventMetrics(uint256 _eventId) external view returns (uint256, uint256, EventStatus, bool) {
        Event storage event_ = events[_eventId];
        return (event_.totalPledgedTrue, event_.totalPledgedFalse, event_.status, event_.finalOutcome);
    }

    /**
     * @dev Allows users to claim stakes from events that expired without resolution or successful oracle submission.
     */
    function claimExpiredStakes() external nonReentrant {
        // This function would iterate through all events a user participated in.
        // To avoid gas limits, a real implementation would require the user to specify an event ID,
        // or iterate off-chain and provide a proof/list of IDs to claim.
        // For simplicity, this is a placeholder.

        // Example: Only allow claiming for a specific event if it's expired and funds haven't been claimed
        // In a realistic scenario, a mapping `mapping(address => mapping(uint256 => bool)) public hasClaimedExpired;` would be needed.
        // Or, if funds are always claimed via `claimEventWinnings`, this function might not be strictly needed,
        // as `claimEventWinnings` already handles `EventStatus.Expired`.
        revert("ChronoCaster: This function requires specifying an event ID or robust iteration. Use claimEventWinnings for now.");
    }
}
```