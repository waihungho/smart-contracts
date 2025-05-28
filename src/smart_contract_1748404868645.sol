Okay, let's design a smart contract concept that is interesting, advanced, creative, and trendy, avoiding standard open-source patterns.

The concept will be a "Quantum Fluctuation Market" (QFM). It's a decentralized market where users predict the outcome of complex, potentially unpredictable "quantum fluctuations" – represented metaphorically by events whose resolution depends on aggregated, potentially weighted, and dynamically interpreted off-chain data or even pseudorandomness influenced by external factors.

It combines elements of:
1.  **Prediction Markets:** Users commit funds to predicted outcomes.
2.  **Advanced Oracles:** Reliance on complex off-chain data inputs, potentially from multiple sources or aggregated via a specific oracle protocol.
3.  **Mechanism Design:** Incentivizing participation and potentially influencing outcomes or data reporting.
4.  **Probabilistic Outcomes:** Outcomes might not be binary or simply based on a single data point, but potentially weighted or determined by a threshold of multiple factors.
5.  **State Transitions:** Events move through distinct phases based on time and external data inputs.

**Contract Name:** `QuantumFluctuationMarket`

**Outline:**

1.  **State Variables:** Define core contract parameters, owner, oracle address, fee percentages, event counter, mapping for events.
2.  **Structs:** Define `FluctuationEvent` structure, including state, timing, outcomes, commitments, oracle requirements, etc. Define `Outcome` structure.
3.  **Enums:** Define `EventState` (e.g., Created, Commitment, Resolving, Collapsed, PaidOut, Cancelled).
4.  **Events:** Define events for key actions (creation, commitment, resolution, payout, etc.).
5.  **Modifiers:** Define modifiers for access control (`onlyOwner`, `onlyOracle`, `whenState`).
6.  **Core Logic:**
    *   Initialization and Setup (`initialize`).
    *   Event Lifecycle Management (Create, Commit, Resolve, Claim).
    *   Oracle Interaction (Requesting data, handling callback).
    *   State Transitions.
    *   Payout Calculation.
    *   Fee Collection.
    *   Governance/Owner Functions (Setting parameters, cancelling events, emergency controls).
    *   View Functions (Reading event details, user commitments, potential payouts).

**Function Summary (25+ Functions):**

1.  `initialize()`: Sets initial owner, token address (e.g., WETH), and oracle address.
2.  `createFluctuationEvent()`: Owner/DAO creates a new event with description, outcomes, commitment/resolution/payout deadlines, and required oracle data.
3.  `commitToOutcome()`: Users commit a specified amount of the approved token to a specific outcome within an event during the commitment phase.
4.  `reCommitToOutcome()`: Allows a user to add more funds to an existing commitment for a specific outcome in an event.
5.  `cancelCommitment()`: Allows users to cancel their commitment before the commitment deadline, potentially with a penalty.
6.  `requestOracleResolution()`: Callable by anyone (or specific roles) after the commitment deadline to trigger the oracle data request process for an event.
7.  `oracleCallback(uint256 _eventId, bytes memory _oracleData)`: Internal/Protected function called by the trusted Oracle contract. Processes the received data to determine the winning outcome and transition the event state to `Collapsed`.
8.  `resolveOutcomeManually(uint256 _eventId, uint8 _winningOutcomeIndex)`: Owner/Gov override for resolution in case of oracle failure (with strict conditions/delays).
9.  `claimWinnings()`: Participants who committed to the winning outcome can claim their proportional share of the total committed pool (minus fees) during the payout period.
10. `claimRefund()`: Participants of a cancelled event can claim back their committed funds.
11. `distributeProtocolFees()`: Owner/DAO can withdraw collected protocol fees after payouts/refunds are processed for an event.
12. `emergencyWithdraw()`: Owner can withdraw all funds from the contract in an emergency scenario (should be very restricted/auditable).
13. `setOracleAddress()`: Owner/DAO sets the trusted oracle contract address.
14. `setFeePercentage()`: Owner/DAO sets the protocol fee percentage on winning pools.
15. `setCommitmentCancellationFee()`: Owner/DAO sets the percentage fee for cancelling commitments early.
16. `pauseEvent()`: Owner/DAO can pause an event (e.g., if there are issues with the oracle or parameters).
17. `unpauseEvent()`: Owner/DAO can unpause a paused event.
18. `cancelEvent()`: Owner/DAO can cancel an event before resolution, allowing participants to claim refunds.
19. `updateEventDeadlines()`: Owner/DAO can adjust commitment/resolution/payout deadlines for an event (with restrictions based on state).
20. `addOutcomeToEvent()`: Owner/DAO can add a new outcome to an event *before* commitments start.
21. `removeOutcomeFromEvent()`: Owner/DAO can remove an outcome from an event *before* commitments start.
22. `getEventDetails()`: View function to retrieve all details of a specific event.
23. `getUserCommitment()`: View function to get the committed amount for a user for a specific outcome in an event.
24. `getTotalCommittedInEvent()`: View function to get the total amount committed across all outcomes for an event.
25. `getTotalCommittedForOutcome()`: View function to get the total amount committed to a specific outcome in an event.
26. `getEventState()`: View function to get the current state of an event.
27. `calculatePotentialWinnings()`: View function to calculate the potential winning amount for a user's commitment *after* the event has collapsed, but before claiming.
28. `getRequiredOracleData()`: View function to see the oracle data identifier required for an event.
29. `getResolvedOracleData()`: View function to see the actual oracle data received after resolution.
30. `getOwner()`: View function to get the contract owner/governance address.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline ---
// 1. State Variables: owner, trusted oracle address, fee percentages, event counter, event mapping.
// 2. Structs: FluctuationEvent, Outcome, OracleDataRequirement.
// 3. Enums: EventState.
// 4. Events: Lifecycle and action events.
// 5. Modifiers: State checks, access control.
// 6. Core Logic:
//    - Initialization & Setup
//    - Event Lifecycle (Create, Commit, Resolve, Claim)
//    - Oracle Interaction (Request, Callback)
//    - State Transitions
//    - Payout Calculation
//    - Fee Collection
//    - Governance/Owner Functions
//    - View Functions

// --- Function Summary ---
// 1.  initialize(): Setup contract owner, token, oracle.
// 2.  createFluctuationEvent(): Create a new event.
// 3.  commitToOutcome(): Commit funds to an outcome.
// 4.  reCommitToOutcome(): Add funds to an existing commitment.
// 5.  cancelCommitment(): Cancel commitment before deadline with penalty.
// 6.  requestOracleResolution(): Trigger oracle data request.
// 7.  oracleCallback(): Handle oracle data return and resolve event.
// 8.  resolveOutcomeManually(): Manual resolution override (owner only).
// 9.  claimWinnings(): Claim payout for winning outcome.
// 10. claimRefund(): Claim refund for cancelled event.
// 11. distributeProtocolFees(): Owner withdraws accumulated fees.
// 12. emergencyWithdraw(): Owner withdraws all funds in emergency.
// 13. setOracleAddress(): Set the trusted oracle address.
// 14. setFeePercentage(): Set the protocol fee percentage.
// 15. setCommitmentCancellationFee(): Set early cancellation fee percentage.
// 16. pauseEvent(): Pause an event.
// 17. unpauseEvent(): Unpause an event.
// 18. cancelEvent(): Cancel an event.
// 19. updateEventDeadlines(): Adjust event deadlines.
// 20. addOutcomeToEvent(): Add outcome before commitments start.
// 21. removeOutcomeFromEvent(): Remove outcome before commitments start.
// 22. getEventDetails(): Get full event data.
// 23. getUserCommitment(): Get user's commitment for an outcome.
// 24. getTotalCommittedInEvent(): Get total committed value for event.
// 25. getTotalCommittedForOutcome(): Get total committed value for a specific outcome.
// 26. getEventState(): Get current event state.
// 27. calculatePotentialWinnings(): Calculate potential payout.
// 28. getRequiredOracleData(): Get oracle data requirement details.
// 29. getResolvedOracleData(): Get the data received from oracle.
// 30. getOwner(): Get contract owner.

// Assuming an interface for the trusted oracle
interface IAdvancedOracle {
    // Example function to request data
    // The oracle implementation would handle the off-chain query and callback
    function requestData(uint256 _queryId, address _callbackAddress, bytes memory _dataParams) external;

    // Example callback function that this contract expects the oracle to call
    // function oracleCallback(uint256 _queryId, bytes memory _result, uint256 _errorCode) external;
    // Note: The actual callback signature depends on the oracle service.
    // We will simulate this with a direct call to our contract's internal oracleCallback function,
    // but in a real system, this would be a verified call from the oracle contract itself.
}


contract QuantumFluctuationMarket is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    IERC20 public commitmentToken; // The token used for commitments (e.g., WETH)
    address public trustedOracle;   // Address of the trusted off-chain oracle contract
    uint256 public protocolFeeBps;  // Protocol fee in Basis Points (e.g., 100 = 1%)
    uint256 public cancellationFeeBps; // Fee for early commitment cancellation in Basis Points
    uint256 private _eventCounter;  // Counter for unique event IDs

    mapping(uint256 => FluctuationEvent) public fluctuationEvents;
    // Mapping: eventId -> outcomeIndex -> participant -> committedAmount
    mapping(uint256 => mapping(uint8 => mapping(address => uint256))) public userCommitments;
    // Keep track of claimed amounts to prevent double claims
    mapping(uint256 => mapping(address => bool)) private hasClaimed;

    // Store accumulated fees before withdrawal
    uint256 public accumulatedProtocolFees;

    // --- Structs ---
    struct OracleDataRequirement {
        uint256 queryId;     // Identifier for the specific data query the oracle needs to perform
        bytes dataParams;    // Parameters for the oracle query (e.g., API endpoint, specific value key)
        uint8 outcomeMappingLogic; // Defines how oracle result maps to outcomes (e.g., 0: exact value, 1: threshold, 2: index)
        bytes expectedValue; // Expected value or threshold for mapping logic
    }

    struct Outcome {
        string description; // e.g., "BTC above $50k", "Team A Wins", "Rain in London"
        uint256 totalCommitted; // Total funds committed to this outcome
    }

    enum EventState {
        Created,         // Event created, awaiting commitments
        Commitment,      // Open for user commitments
        Resolving,       // Commitment period ended, oracle data requested/awaited
        Collapsed,       // Oracle data received, outcome determined
        Payout,          // Winners can claim, losers cannot
        Cancelled,       // Event cancelled, users can claim refunds
        PaidOut          // Payout period ended, event is finalized
    }

    struct FluctuationEvent {
        string description;      // Overall description of the event
        uint256 creationTime;    // Timestamp of event creation
        uint256 commitmentEndTime; // Timestamp when commitment phase ends
        uint256 resolutionEndTime; // Timestamp when oracle must resolve
        uint256 payoutEndTime;   // Timestamp when payout phase ends
        Outcome[] outcomes;      // List of possible outcomes
        uint256 totalCommitted;  // Total funds committed across all outcomes
        EventState state;        // Current state of the event
        uint8 winningOutcomeIndex; // Index of the winning outcome once collapsed (or max uint8 if cancelled/no winner)
        OracleDataRequirement oracleReq; // Details about the oracle data needed for resolution
        bytes resolvedOracleData; // The actual data received from the oracle
        bool isPaused;           // Allows pausing/unpausing
    }

    // --- Events ---
    event EventCreated(uint256 indexed eventId, string description, uint256 commitmentEndTime, uint256 resolutionEndTime, uint256 payoutEndTime);
    event CommitmentMade(uint256 indexed eventId, uint8 indexed outcomeIndex, address indexed user, uint256 amount);
    event CommitmentCancelled(uint256 indexed eventId, uint8 indexed outcomeIndex, address indexed user, uint256 amountRefunded, uint256 feePaid);
    event OracleResolutionRequested(uint256 indexed eventId, uint256 queryId);
    event EventCollapsed(uint256 indexed eventId, uint8 winningOutcomeIndex, bytes resolvedData);
    event EventResolvedManually(uint256 indexed eventId, uint8 winningOutcomeIndex);
    event WinningsClaimed(uint256 indexed eventId, address indexed user, uint256 amountClaimed);
    event RefundClaimed(uint256 indexed eventId, address indexed user, uint256 amountClaimed);
    event EventCancelled(uint256 indexed eventId);
    event EventPaused(uint256 indexed eventId);
    event EventUnpaused(uint256 indexed eventId);
    event ProtocolFeesDistributed(address indexed receiver, uint256 amount);
    event OracleAddressUpdated(address indexed newOracle);
    event FeePercentageUpdated(uint256 newFeeBps);
    event CancellationFeePercentageUpdated(uint256 newFeeBps);
    event OutcomeAdded(uint256 indexed eventId, uint8 indexed outcomeIndex, string description);
    event OutcomeRemoved(uint256 indexed eventId, uint8 indexed outcomeIndex);
    event EventDeadlinesUpdated(uint256 indexed eventId, uint256 commitmentEndTime, uint256 resolutionEndTime, uint256 payoutEndTime);


    // --- Modifiers ---
    modifier whenState(uint256 _eventId, EventState _expectedState) {
        require(fluctuationEvents[_eventId].state == _expectedState, "QFM: Invalid state for action");
        _;
    }

    modifier notPaused(uint256 _eventId) {
        require(!fluctuationEvents[_eventId].isPaused, "QFM: Event is paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "QFM: Caller is not the trusted oracle");
        _;
    }

    // --- Constructor & Initialization ---
    // The constructor is kept minimal, initialization is done via initialize()
    // This is good practice for upgradeable contracts, though not strictly necessary here.
    constructor() Ownable(msg.sender) {} // Set initial owner

    function initialize(address _commitmentToken, address _trustedOracle, uint256 _protocolFeeBps, uint256 _cancellationFeeBps) external onlyOwner {
        require(_commitmentToken != address(0), "QFM: Commitment token address cannot be zero");
        require(_trustedOracle != address(0), "QFM: Oracle address cannot be zero");
        require(_protocolFeeBps <= 10000, "QFM: Protocol fee cannot exceed 100%");
        require(_cancellationFeeBps <= 10000, "QFM: Cancellation fee cannot exceed 100%");

        commitmentToken = IERC20(_commitmentToken);
        trustedOracle = _trustedOracle;
        protocolFeeBps = _protocolFeeBps;
        cancellationFeeBps = _cancellationFeeBps;
        _eventCounter = 0; // Start event IDs from 1 or 0? Let's use 1 for clarity.
        transferOwnership(msg.sender); // Ensure owner is set if inheriting Ownable
    }

    // --- Core Event Lifecycle Functions ---

    /**
     * @notice Creates a new fluctuation event. Only callable by the contract owner.
     * @param _description Event description.
     * @param _outcomeDescriptions Descriptions of possible outcomes.
     * @param _commitmentEndTime Timestamp when commitment period ends.
     * @param _resolutionEndTime Timestamp when oracle resolution must complete.
     * @param _payoutEndTime Timestamp when payout period ends.
     * @param _oracleQueryId Oracle query ID for resolution data.
     * @param _oracleDataParams Parameters for the oracle query.
     * @param _oracleOutcomeMappingLogic Logic identifier for mapping oracle data to outcomes.
     * @param _oracleExpectedValue Expected value/threshold for mapping logic.
     */
    function createFluctuationEvent(
        string calldata _description,
        string[] calldata _outcomeDescriptions,
        uint256 _commitmentEndTime,
        uint256 _resolutionEndTime,
        uint256 _payoutEndTime,
        uint256 _oracleQueryId,
        bytes calldata _oracleDataParams,
        uint8 _oracleOutcomeMappingLogic,
        bytes calldata _oracleExpectedValue
    ) external onlyOwner {
        require(_outcomeDescriptions.length > 1, "QFM: Must have at least 2 outcomes");
        require(_commitmentEndTime > block.timestamp, "QFM: Commitment end time must be in the future");
        require(_resolutionEndTime > _commitmentEndTime, "QFM: Resolution end time must be after commitment end");
        require(_payoutEndTime > _resolutionEndTime, "QFM: Payout end time must be after resolution end");

        _eventCounter++;
        uint256 eventId = _eventCounter;

        Outcome[] memory outcomes = new Outcome[](_outcomeDescriptions.length);
        for (uint8 i = 0; i < _outcomeDescriptions.length; i++) {
            outcomes[i] = Outcome({
                description: _outcomeDescriptions[i],
                totalCommitted: 0
            });
        }

        fluctuationEvents[eventId] = FluctuationEvent({
            description: _description,
            creationTime: block.timestamp,
            commitmentEndTime: _commitmentEndTime,
            resolutionEndTime: _resolutionEndTime,
            payoutEndTime: _payoutEndTime,
            outcomes: outcomes,
            totalCommitted: 0,
            state: EventState.Created, // Starts as Created, needs explicit state transition to Commitment
            winningOutcomeIndex: type(uint8).max, // Sentinel value
            oracleReq: OracleDataRequirement({
                queryId: _oracleQueryId,
                dataParams: _oracleDataParams,
                outcomeMappingLogic: _oracleOutcomeMappingLogic,
                expectedValue: _oracleExpectedValue
            }),
            resolvedOracleData: "", // Initialize empty
            isPaused: false
        });

        // Transition to Commitment state immediately after creation is valid
        _transitionState(eventId, EventState.Created, EventState.Commitment);

        emit EventCreated(eventId, _description, _commitmentEndTime, _resolutionEndTime, _payoutEndTime);
    }

    /**
     * @notice Allows a user to commit funds to a specific outcome for an event.
     * @param _eventId The ID of the event.
     * @param _outcomeIndex The index of the outcome to commit to.
     * @param _amount The amount of tokens to commit.
     */
    function commitToOutcome(uint256 _eventId, uint8 _outcomeIndex, uint256 _amount)
        external
        nonReentrant
        whenState(_eventId, EventState.Commitment)
        notPaused(_eventId)
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(_outcomeIndex < eventData.outcomes.length, "QFM: Invalid outcome index");
        require(_amount > 0, "QFM: Commitment amount must be greater than zero");
        require(block.timestamp <= eventData.commitmentEndTime, "QFM: Commitment period has ended");

        // Pull tokens from user
        commitmentToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update state
        userCommitments[_eventId][_outcomeIndex][msg.sender] += _amount;
        eventData.outcomes[_outcomeIndex].totalCommitted += _amount;
        eventData.totalCommitted += _amount;

        emit CommitmentMade(_eventId, _outcomeIndex, msg.sender, _amount);
    }

    /**
     * @notice Allows a user to add more funds to an existing commitment.
     * @param _eventId The ID of the event.
     * @param _outcomeIndex The index of the outcome of the existing commitment.
     * @param _additionalAmount The additional amount to commit.
     */
    function reCommitToOutcome(uint256 _eventId, uint8 _outcomeIndex, uint256 _additionalAmount)
        external
        nonReentrant
        whenState(_eventId, EventState.Commitment)
        notPaused(_eventId)
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(_outcomeIndex < eventData.outcomes.length, "QFM: Invalid outcome index");
        require(_additionalAmount > 0, "QFM: Additional amount must be greater than zero");
        require(block.timestamp <= eventData.commitmentEndTime, "QFM: Commitment period has ended");
        require(userCommitments[_eventId][_outcomeIndex][msg.sender] > 0, "QFM: No existing commitment found for this outcome");


        // Pull tokens from user
        commitmentToken.safeTransferFrom(msg.sender, address(this), _additionalAmount);

        // Update state
        userCommitments[_eventId][_outcomeIndex][msg.sender] += _additionalAmount;
        eventData.outcomes[_outcomeIndex].totalCommitted += _additionalAmount;
        eventData.totalCommitted += _additionalAmount;

        emit CommitmentMade(_eventId, _outcomeIndex, msg.sender, _additionalAmount); // Use the same event
    }


    /**
     * @notice Allows a user to cancel their commitment before the deadline.
     * @param _eventId The ID of the event.
     * @param _outcomeIndex The index of the outcome the user committed to.
     */
    function cancelCommitment(uint256 _eventId, uint8 _outcomeIndex)
        external
        nonReentrant
        whenState(_eventId, EventState.Commitment)
        notPaused(_eventId)
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(block.timestamp <= eventData.commitmentEndTime, "QFM: Commitment period has ended"); // Double check state check
        require(_outcomeIndex < eventData.outcomes.length, "QFM: Invalid outcome index");

        uint256 committedAmount = userCommitments[_eventId][_outcomeIndex][msg.sender];
        require(committedAmount > 0, "QFM: No commitment found for this user/outcome");

        // Calculate fee and refund amount
        uint256 feeAmount = (committedAmount * cancellationFeeBps) / 10000;
        uint256 refundAmount = committedAmount - feeAmount;

        // Update state
        userCommitments[_eventId][_outcomeIndex][msg.sender] = 0; // Clear commitment
        eventData.outcomes[_outcomeIndex].totalCommitted -= committedAmount; // Deduct full amount from outcome total
        eventData.totalCommitted -= committedAmount; // Deduct full amount from event total

        // Transfer refund to user
        if (refundAmount > 0) {
            commitmentToken.safeTransfer(msg.sender, refundAmount);
        }

        // Add fee to accumulated fees
        accumulatedProtocolFees += feeAmount;

        emit CommitmentCancelled(_eventId, _outcomeIndex, msg.sender, refundAmount, feeAmount);
    }

    /**
     * @notice Triggers the request for oracle resolution data.
     * Callable after the commitment period ends, before resolution end time.
     * Could be callable by anyone to trigger the process, relying on the oracle to handle verification.
     * @param _eventId The ID of the event to request resolution for.
     */
    function requestOracleResolution(uint256 _eventId)
        external
        nonReentrant // Protect against reentrancy in case oracle callback happens immediately
        whenState(_eventId, EventState.Commitment) // Must be in Commitment state to request resolution
        notPaused(_eventId)
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(block.timestamp > eventData.commitmentEndTime, "QFM: Commitment period is not yet over");
        require(block.timestamp <= eventData.resolutionEndTime, "QFM: Resolution period has ended");
        require(trustedOracle != address(0), "QFM: Trusted oracle address not set");

        // Transition state to Resolving
        _transitionState(_eventId, EventState.Commitment, EventState.Resolving);

        // Request data from the trusted oracle contract
        // This assumes the oracle contract has a requestData function
        IAdvancedOracle(trustedOracle).requestData(
            eventData.oracleReq.queryId,
            address(this), // Callback address
            eventData.oracleReq.dataParams // Parameters for the oracle query
        );

        emit OracleResolutionRequested(_eventId, eventData.oracleReq.queryId);
    }

    /**
     * @notice Callback function intended to be called *only* by the trusted oracle contract.
     * Processes the oracle data and determines the winning outcome, collapsing the event.
     * In a real system, this would need robust authentication that `msg.sender == trustedOracle`
     * is sufficient, potentially with an additional request ID check if the oracle supports it.
     * We are simulating this with a direct call from the `trustedOracle` address.
     * @param _eventId The ID of the event being resolved.
     * @param _oracleData The data received from the oracle.
     */
    function oracleCallback(uint256 _eventId, bytes calldata _oracleData)
        external // External because it's called by the oracle contract
        onlyOracle() // Only the trusted oracle can call this
        whenState(_eventId, EventState.Resolving) // Must be in Resolving state
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(block.timestamp <= eventData.resolutionEndTime, "QFM: Oracle resolution timed out");

        eventData.resolvedOracleData = _oracleData;

        // --- Advanced: Logic to determine winning outcome from oracle data ---
        // This is the core of the "advanced" concept.
        // The specific logic here depends heavily on the _oracleOutcomeMappingLogic
        // and _oracleExpectedValue defined in the event's OracleDataRequirement.
        // This is a simplified example. A real implementation would need to
        // decode _oracleData based on the format expected for eventData.oracleReq.queryId
        // and apply the mapping logic (_oracleOutcomeMappingLogic).

        uint8 winningOutcomeIndex = type(uint8).max; // Default to no winner

        // Example Mapping Logic (Highly simplified - expand based on actual oracle data structure)
        // Logic 0: Exact Value Match (e.g., oracle returns bytes32 hash, compare to expected)
        // Logic 1: Threshold (e.g., oracle returns uint256 price, check > or < expectedValue)
        // Logic 2: Direct Index (e.g., oracle returns uint8 index directly)
        // Logic 3: Complex data analysis/aggregation based on dataParams...

        // For this example, let's assume mappingLogic 2: oracle returns a uint8 which is the winning index.
        if (eventData.oracleReq.outcomeMappingLogic == 2) {
            require(_oracleData.length >= 1, "QFM: Oracle data too short for index mapping");
            // Decode the first byte as the outcome index
            winningOutcomeIndex = uint8(_oracleData[0]);
            require(winningOutcomeIndex < eventData.outcomes.length, "QFM: Oracle returned invalid outcome index");
        } else {
            // Add other complex mapping logic here...
            // For now, default to no winner if logic isn't implemented
             revert("QFM: Unsupported oracle outcome mapping logic");
        }

        eventData.winningOutcomeIndex = winningOutcomeIndex;

        // Transition state to Collapsed
        _transitionState(_eventId, EventState.Resolving, EventState.Collapsed);

        emit EventCollapsed(_eventId, winningOutcomeIndex, _oracleData);

        // Optional: Could immediately transition to Payout here if desired
        // _transitionState(_eventId, EventState.Collapsed, EventState.Payout);
        // Or require a separate call to enable payout? Let's make Payout automatic based on resolution.
        // Payout is implicitly enabled once state is Collapsed and time is right (which it is).
    }


    /**
     * @notice Owner/DAO override to manually resolve an event outcome.
     * Use with extreme caution, potentially with a time delay or governance vote requirement.
     * @param _eventId The ID of the event.
     * @param _winningOutcomeIndex The index of the outcome determined as the winner.
     */
    function resolveOutcomeManually(uint256 _eventId, uint8 _winningOutcomeIndex)
        external
        onlyOwner() // Only owner can manually resolve
        whenState(_eventId, EventState.Resolving) // Must be in Resolving state
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        // Add a delay requirement here in a real system, e.g., require(block.timestamp > eventData.resolutionEndTime + manualResolutionDelay)
        require(_winningOutcomeIndex < eventData.outcomes.length, "QFM: Invalid winning outcome index");

        eventData.winningOutcomeIndex = _winningOutcomeIndex;
        eventData.resolvedOracleData = "MANUAL_OVERRIDE"; // Indicate manual override

        // Transition state to Collapsed
        _transitionState(_eventId, EventState.Resolving, EventState.Collapsed);

        emit EventResolvedManually(_eventId, _winningOutcomeIndex);

        // Payout implicitly enabled
    }

    /**
     * @notice Allows a user to claim their winnings for a collapsed event.
     * @param _eventId The ID of the event.
     */
    function claimWinnings(uint256 _eventId)
        external
        nonReentrant
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(eventData.state == EventState.Collapsed || eventData.state == EventState.Payout, "QFM: Event is not in a claimable state (Collapsed/Payout)");
        require(block.timestamp <= eventData.payoutEndTime, "QFM: Payout period has ended");
        require(!hasClaimed[_eventId][msg.sender], "QFM: Winnings already claimed for this event");
        require(eventData.winningOutcomeIndex != type(uint8).max, "QFM: Event did not have a winning outcome assigned"); // Should be set if Collapsed

        uint256 userCommitment = userCommitments[_eventId][eventData.winningOutcomeIndex][msg.sender];
        require(userCommitment > 0, "QFM: User did not commit to the winning outcome");

        uint256 totalWinningCommitment = eventData.outcomes[eventData.winningOutcomeIndex].totalCommitted;
        uint256 totalPool = eventData.totalCommitted;

        require(totalWinningCommitment > 0, "QFM: No one won this outcome?"); // Should not happen if userCommitment > 0

        // Calculate gross winnings: (user_commitment / total_winning_commitment) * total_pool
        uint256 grossWinnings = (userCommitment * totalPool) / totalWinningCommitment;

        // Calculate protocol fee on gross winnings
        uint256 fee = (grossWinnings * protocolFeeBps) / 10000;
        uint256 netWinnings = grossWinnings - fee;

        // Update state BEFORE transferring tokens
        userCommitments[_eventId][eventData.winningOutcomeIndex][msg.sender] = 0; // Mark commitment as claimed/used
        hasClaimed[_eventId][msg.sender] = true;
        accumulatedProtocolFees += fee; // Add fee to accumulated fees

        // Transfer net winnings to user
        if (netWinnings > 0) {
            commitmentToken.safeTransfer(msg.sender, netWinnings);
        }

        emit WinningsClaimed(_eventId, msg.sender, netWinnings);
    }

     /**
     * @notice Allows a user to claim a refund for a cancelled event.
     * @param _eventId The ID of the event.
     */
    function claimRefund(uint256 _eventId)
        external
        nonReentrant
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(eventData.state == EventState.Cancelled, "QFM: Event was not cancelled");
        require(!hasClaimed[_eventId][msg.sender], "QFM: Refund already claimed for this event"); // Prevent double claims

        uint256 totalUserCommitment = 0;
        // Sum up commitments across all outcomes for the user in this event
        for (uint8 i = 0; i < eventData.outcomes.length; i++) {
             totalUserCommitment += userCommitments[_eventId][i][msg.sender];
        }

        require(totalUserCommitment > 0, "QFM: No commitment found for this user in this event");

        // Update state BEFORE transferring tokens
        // Clear all user commitments for this event
        for (uint8 i = 0; i < eventData.outcomes.length; i++) {
             userCommitments[_eventId][i][msg.sender] = 0;
        }
        hasClaimed[_eventId][msg.sender] = true;

        // Transfer refund to user
        commitmentToken.safeTransfer(msg.sender, totalUserCommitment);

        emit RefundClaimed(_eventId, msg.sender, totalUserCommitment);
    }


    // --- Governance/Owner Functions ---

    /**
     * @notice Allows the owner to withdraw accumulated protocol fees.
     */
    function distributeProtocolFees() external onlyOwner nonReentrant {
        uint256 feeAmount = accumulatedProtocolFees;
        accumulatedProtocolFees = 0; // Reset fee counter BEFORE transfer

        if (feeAmount > 0) {
            commitmentToken.safeTransfer(owner(), feeAmount);
            emit ProtocolFeesDistributed(owner(), feeAmount);
        }
    }

     /**
     * @notice Emergency function for the owner to withdraw all contract balance.
     * Use only in extreme emergencies. This bypasses event logic.
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = commitmentToken.balanceOf(address(this));
        require(balance > 0, "QFM: No tokens to withdraw");
        commitmentToken.safeTransfer(owner(), balance);
        // Note: This does NOT update internal state about events.
        // It's a last resort and requires off-chain cleanup/accounting.
    }


    /**
     * @notice Sets the address of the trusted oracle contract.
     * @param _newOracle The address of the new trusted oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "QFM: New oracle address cannot be zero");
        trustedOracle = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @notice Sets the protocol fee percentage on winnings.
     * @param _newFeeBps New fee percentage in Basis Points (0-10000).
     */
    function setFeePercentage(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "QFM: Fee percentage cannot exceed 100%");
        protocolFeeBps = _newFeeBps;
        emit FeePercentageUpdated(_newFeeBps);
    }

    /**
     * @notice Sets the percentage fee for early commitment cancellation.
     * @param _newFeeBps New fee percentage in Basis Points (0-10000).
     */
    function setCommitmentCancellationFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "QFM: Cancellation fee percentage cannot exceed 100%");
        cancellationFeeBps = _newFeeBps;
        emit CancellationFeePercentageUpdated(_newFeeBps);
    }

    /**
     * @notice Pauses an ongoing event.
     * @param _eventId The ID of the event to pause.
     */
    function pauseEvent(uint256 _eventId) external onlyOwner {
         FluctuationEvent storage eventData = fluctuationEvents[_eventId];
         require(eventData.state != EventState.PaidOut && eventData.state != EventState.Cancelled, "QFM: Event cannot be paused in terminal state");
         require(!eventData.isPaused, "QFM: Event is already paused");
         eventData.isPaused = true;
         emit EventPaused(_eventId);
    }

     /**
     * @notice Unpauses a paused event.
     * @param _eventId The ID of the event to unpause.
     */
    function unpauseEvent(uint256 _eventId) external onlyOwner {
         FluctuationEvent storage eventData = fluctuationEvents[_eventId];
         require(eventData.isPaused, "QFM: Event is not paused");
         eventData.isPaused = false;
         emit EventUnpaused(_eventId);
    }

    /**
     * @notice Cancels an event. Allows users to claim refunds.
     * Can only be cancelled before resolution.
     * @param _eventId The ID of the event to cancel.
     */
    function cancelEvent(uint256 _eventId)
        external
        onlyOwner()
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(eventData.state < EventState.Collapsed, "QFM: Event cannot be cancelled after collapse");
        require(eventData.state != EventState.Cancelled, "QFM: Event is already cancelled");

        _transitionState(_eventId, eventData.state, EventState.Cancelled);

        emit EventCancelled(_eventId);
    }

    /**
     * @notice Updates the deadlines for an event. Restricted based on current state.
     * @param _eventId The ID of the event.
     * @param _newCommitmentEndTime New commitment end time (0 to keep current).
     * @param _newResolutionEndTime New resolution end time (0 to keep current).
     * @param _newPayoutEndTime New payout end time (0 to keep current).
     */
    function updateEventDeadlines(uint256 _eventId, uint256 _newCommitmentEndTime, uint256 _newResolutionEndTime, uint256 _newPayoutEndTime)
        external
        onlyOwner()
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(eventData.state < EventState.Collapsed, "QFM: Cannot update deadlines after collapse");
        require(eventData.state != EventState.Cancelled, "QFM: Cannot update deadlines for cancelled event");

        uint256 currentCommitmentEndTime = eventData.commitmentEndTime;
        uint256 currentResolutionEndTime = eventData.resolutionEndTime;
        uint256 currentPayoutEndTime = eventData.payoutEndTime;

        uint256 updatedCommitmentEndTime = (_newCommitmentEndTime == 0) ? currentCommitmentEndTime : _newCommitmentEndTime;
        uint256 updatedResolutionEndTime = (_newResolutionEndTime == 0) ? currentResolutionEndTime : _newResolutionEndTime;
        uint256 updatedPayoutEndTime = (_newPayoutEndTime == 0) ? currentPayoutEndTime : _newPayoutEndTime;

        // Strict checks for state transitions
        if (eventData.state == EventState.Created || eventData.state == EventState.Commitment) {
             require(updatedCommitmentEndTime > block.timestamp, "QFM: New commitment end must be in future");
             require(updatedResolutionEndTime > updatedCommitmentEndTime, "QFM: New resolution end must be after new commitment end");
             require(updatedPayoutEndTime > updatedResolutionEndTime, "QFM: New payout end must be after new resolution end");
        } else if (eventData.state == EventState.Resolving) {
             // Can only extend resolution/payout, not go back to commitment
             require(_newCommitmentEndTime == 0 || _newCommitmentEndTime == currentCommitmentEndTime, "QFM: Cannot change commitment end after resolution starts");
             require(updatedResolutionEndTime > block.timestamp, "QFM: New resolution end must be in future");
             require(updatedPayoutEndTime > updatedResolutionEndTime, "QFM: New payout end must be after new resolution end");
        } // No updates possible in Collapsed/Payout states via this function

        eventData.commitmentEndTime = updatedCommitmentEndTime;
        eventData.resolutionEndTime = updatedResolutionEndTime;
        eventData.payoutEndTime = updatedPayoutEndTime;

        emit EventDeadlinesUpdated(_eventId, updatedCommitmentEndTime, updatedResolutionEndTime, updatedPayoutEndTime);
    }

     /**
     * @notice Adds a new outcome to an event. Can only be done before commitments start.
     * @param _eventId The ID of the event.
     * @param _description Description of the new outcome.
     */
    function addOutcomeToEvent(uint256 _eventId, string calldata _description)
        external
        onlyOwner()
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        // Only allowed if the event is in Created or Commitment state AND commitment period hasn't started or has just started
        require(eventData.state <= EventState.Commitment, "QFM: Cannot add outcome after commitment period starts or state progresses");
        require(eventData.totalCommitted == 0, "QFM: Cannot add outcome after commitments are made"); // Ensure no commitments exist yet

        eventData.outcomes.push(Outcome({
            description: _description,
            totalCommitted: 0
        }));

        emit OutcomeAdded(_eventId, uint8(eventData.outcomes.length - 1), _description);
    }

    /**
     * @notice Removes an outcome from an event. Can only be done before commitments start.
     * Reordering happens, so use the new indices carefully.
     * @param _eventId The ID of the event.
     * @param _outcomeIndex The index of the outcome to remove.
     */
    function removeOutcomeFromEvent(uint256 _eventId, uint8 _outcomeIndex)
        external
        onlyOwner()
    {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        // Only allowed if the event is in Created or Commitment state AND commitment period hasn't started or has just started
        require(eventData.state <= EventState.Commitment, "QFM: Cannot remove outcome after commitment period starts or state progresses");
        require(eventData.totalCommitted == 0, "QFM: Cannot remove outcome after commitments are made"); // Ensure no commitments exist yet
        require(_outcomeIndex < eventData.outcomes.length, "QFM: Invalid outcome index");
        require(eventData.outcomes.length > 2, "QFM: Cannot reduce to fewer than 2 outcomes"); // Must maintain at least 2 outcomes

        // Simple removal by swapping with the last element and popping
        uint8 lastIndex = uint8(eventData.outcomes.length - 1);
        if (_outcomeIndex != lastIndex) {
            eventData.outcomes[_outcomeIndex] = eventData.outcomes[lastIndex];
            // Note: Mappings like userCommitments are NOT shifted. This means
            // userCommitments[_eventId][_outcomeIndex] will now correspond to the
            // *new* outcome at that index. This is acceptable because we require
            // totalCommitted == 0, meaning no user commitments exist yet to be corrupted.
        }
        eventData.outcomes.pop();

        emit OutcomeRemoved(_eventId, _outcomeIndex);
    }


    // --- View Functions ---

    /**
     * @notice Gets all details for a specific event.
     * @param _eventId The ID of the event.
     * @return Event details struct.
     */
    function getEventDetails(uint256 _eventId)
        public
        view
        returns (FluctuationEvent memory)
    {
        require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
        return fluctuationEvents[_eventId];
    }

     /**
     * @notice Gets the committed amount for a specific user and outcome in an event.
     * @param _eventId The ID of the event.
     * @param _outcomeIndex The index of the outcome.
     * @param _user The address of the user.
     * @return The committed amount.
     */
    function getUserCommitment(uint256 _eventId, uint8 _outcomeIndex, address _user)
        public
        view
        returns (uint256)
    {
        require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
        require(_outcomeIndex < fluctuationEvents[_eventId].outcomes.length, "QFM: Invalid outcome index");
        return userCommitments[_eventId][_outcomeIndex][_user];
    }

     /**
     * @notice Gets the total amount committed across all outcomes for an event.
     * @param _eventId The ID of the event.
     * @return The total committed amount.
     */
    function getTotalCommittedInEvent(uint256 _eventId)
        public
        view
        returns (uint256)
    {
        require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
        return fluctuationEvents[_eventId].totalCommitted;
    }

     /**
     * @notice Gets the total amount committed to a specific outcome in an event.
     * @param _eventId The ID of the event.
     * @param _outcomeIndex The index of the outcome.
     * @return The total committed amount for the outcome.
     */
    function getTotalCommittedForOutcome(uint256 _eventId, uint8 _outcomeIndex)
        public
        view
        returns (uint256)
    {
         require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
         require(_outcomeIndex < fluctuationEvents[_eventId].outcomes.length, "QFM: Invalid outcome index");
         return fluctuationEvents[_eventId].outcomes[_outcomeIndex].totalCommitted;
    }

    /**
     * @notice Gets the current state of an event.
     * @param _eventId The ID of the event.
     * @return The current state enum value.
     */
    function getEventState(uint256 _eventId)
        public
        view
        returns (EventState)
    {
         require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
         return fluctuationEvents[_eventId].state;
    }


    /**
     * @notice Calculates the potential winning amount for a user in a collapsed event.
     * This is a hypothetical calculation before claiming.
     * @param _eventId The ID of the event.
     * @param _user The address of the user.
     * @return The potential winning amount. Returns 0 if not winning, or before collapse.
     */
    function calculatePotentialWinnings(uint256 _eventId, address _user)
        public
        view
        returns (uint256)
    {
        require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];

        // Can only calculate potential winnings if the event has collapsed
        if (eventData.state != EventState.Collapsed && eventData.state != EventState.Payout) {
            return 0;
        }

        // Check if the user committed to the winning outcome
        uint8 winningOutcomeIndex = eventData.winningOutcomeIndex;
         if (winningOutcomeIndex == type(uint8).max || winningOutcomeIndex >= eventData.outcomes.length) {
             return 0; // No winning outcome set, or invalid index
         }

        uint256 userCommitment = userCommitments[_eventId][winningOutcomeIndex][_user];
        if (userCommitment == 0) {
            return 0; // User did not commit to the winning outcome
        }

        uint256 totalWinningCommitment = eventData.outcomes[winningOutcomeIndex].totalCommitted;
        uint256 totalPool = eventData.totalCommitted;

        if (totalWinningCommitment == 0) {
            return 0; // Should not happen if userCommitment > 0, but safety check
        }

        // Calculate gross winnings: (user_commitment / total_winning_commitment) * total_pool
        uint256 grossWinnings = (userCommitment * totalPool) / totalWinningCommitment;

        // Calculate protocol fee on gross winnings
        uint256 fee = (grossWinnings * protocolFeeBps) / 10000;
        uint256 netWinnings = grossWinnings - fee;

        // Note: This calculation does not account for whether the user has already claimed.
        // Use hasClaimed[_eventId][_user] to check claimed status.
        return netWinnings;
    }

     /**
     * @notice Gets the oracle data requirement details for an event.
     * @param _eventId The ID of the event.
     * @return The OracleDataRequirement struct.
     */
    function getRequiredOracleData(uint256 _eventId)
        public
        view
        returns (OracleDataRequirement memory)
    {
         require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
         return fluctuationEvents[_eventId].oracleReq;
    }

     /**
     * @notice Gets the actual data received from the oracle for a resolved event.
     * @param _eventId The ID of the event.
     * @return The raw resolved oracle data.
     */
    function getResolvedOracleData(uint256 _eventId)
        public
        view
        returns (bytes memory)
    {
         require(_eventId > 0 && _eventId <= _eventCounter, "QFM: Invalid event ID");
         require(fluctuationEvents[_eventId].state >= EventState.Collapsed, "QFM: Oracle data not resolved yet");
         return fluctuationEvents[_eventId].resolvedOracleData;
    }

    /**
     * @notice Returns the address of the contract owner.
     */
    function getOwner() public view returns (address) {
        return owner();
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to manage state transitions with basic validation.
     * Can be extended with more complex transition logic if needed.
     * @param _eventId The ID of the event.
     * @param _from The expected current state.
     * @param _to The target state.
     */
    function _transitionState(uint256 _eventId, EventState _from, EventState _to) internal {
        FluctuationEvent storage eventData = fluctuationEvents[_eventId];
        require(eventData.state == _from, "QFM: State transition validation failed (from)");
        // Add additional checks here if specific transitions are disallowed (e.g., cannot go from Collapsed back to Commitment)
        eventData.state = _to;
        // Potentially emit a state transition event here if helpful for off-chain monitoring
    }

    // Note: No need for explicit _calculatePayout internal function as it's integrated into claimWinnings
}
```