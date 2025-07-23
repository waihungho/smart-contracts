The smart contract presented below, **AetherForge**, is designed as a **Cognitive Asset Synthesis Protocol**. It allows users to stake collateral and make predictions on real-world events. In return, they "forge" **CogniTokens**, which are synthetic shares whose value upon event resolution is directly tied to the accuracy of the aggregate predictions against the actual outcome, leveraging decentralized oracles (Chainlink) for outcome verification.

This design aims to be advanced, creative, and distinct by combining elements of prediction markets, synthetic assets, and decentralized oracle integration with a unique "accuracy-weighted" collateral distribution mechanism and a multi-stage event lifecycle including a moderation-based dispute system.

---

## Smart Contract: AetherForge - Cognitive Asset Synthesis Protocol

### Outline

1.  **SPDX License & Pragma**
2.  **Imports:** Necessary OpenZeppelin contracts (Context, Ownable, Pausable) and Chainlink contracts (ChainlinkClient).
3.  **Interfaces:** `IERC20` for collateral token interaction.
4.  **Enums:** `EventStatus` to track the state of prediction events, `OutcomeType` for different prediction outcome formats.
5.  **Structs:**
    *   `PredictionEvent`: Stores all data related to a specific prediction event (topic, resolution time, outcome, status, etc.).
    *   `UserPrediction`: Records a user's individual prediction, staked collateral, and minted CogniToken shares for an event.
6.  **Events:** Emitted for key actions like event creation, prediction submission, resolution, and disputes.
7.  **State Variables:**
    *   **Administrative:** `owner`, `eventModerators`, `protocolFeeRecipient`, `collateralToken`.
    *   **Chainlink Configuration:** `oracle`, `jobId`, `linkToken`.
    *   **Event Management:** `nextEventId`, `events` mapping, `userPredictions` mapping.
    *   **Dispute Management:** `disputes` mapping, `disputeThreshold` (for moderation-based dispute resolution).
8.  **Constructor:** Initializes the contract with Chainlink configuration, protocol fee recipient, and collateral token.
9.  **Modifiers:** `onlyOwner`, `onlyModerator`, `whenNotPaused`, `whenPaused`.
10. **Functions (Grouped by Category):**
    *   **I. Core Setup & Configuration (Administrative)**
    *   **II. Prediction Event Management (Moderator Controlled)**
    *   **III. Participant Actions (Public)**
    *   **IV. Event Resolution & Oracle Interaction**
    *   **V. Dispute Mechanism (Moderator/Owner Controlled)**
    *   **VI. Protocol Analytics & Views (Public)**

---

### Function Summary (26 functions)

**I. Core Setup & Configuration (Administrative)**

1.  `constructor(address _link, address _oracle, bytes32 _jobId, address _feeRecipient, address _collateralToken)`: Initializes the contract with Chainlink configuration, protocol fee recipient, and the accepted collateral token.
2.  `setChainlinkOracleConfig(address _oracle, bytes32 _jobId)`: Allows the owner to update the Chainlink oracle address and job ID.
3.  `setCollateralToken(address _collateralToken)`: Allows the owner to change the accepted ERC20 collateral token.
4.  `setProtocolFeeRecipient(address _recipient)`: Allows the owner to update the address where protocol fees are sent.
5.  `addEventModerator(address _moderator)`: Grants moderator privileges to an address, allowing them to create and manage prediction events.
6.  `removeEventModerator(address _moderator)`: Revokes moderator privileges from an address.
7.  `pauseContract()`: Emergency function to pause the contract, preventing most operations.
8.  `unpauseContract()`: Unpauses the contract, allowing operations to resume.

**II. Prediction Event Management (Moderator Controlled)**

9.  `createPredictionEvent(string memory _topic, string memory _description, uint256 _resolutionTime, uint256 _submissionCutoffTime, OutcomeType _outcomeType, uint256 _outcomePrecision, bytes32 _chainlinkSpecIdForOutcome)`: Creates a new prediction event with specified details, including its resolution timeline and Chainlink job ID for outcome retrieval.
10. `cancelPredictionEvent(uint256 _eventId)`: Allows a moderator to cancel an event before its resolution, refunding all staked collateral.
11. `updateEventDetails(uint256 _eventId, string memory _newTopic, string memory _newDescription, uint256 _newSubmissionCutoffTime)`: Allows a moderator to update certain event metadata before the prediction submission cutoff time.

**III. Participant Actions (Public)**

12. `submitPredictionAndForge(uint256 _eventId, int256 _predictedValue, uint256 _collateralAmount)`: Allows a user to submit their prediction for an event, stake `_collateralAmount` of the designated collateral token, and in return, mint a proportional share of "CogniTokens" for that event.
13. `redeemCogniTokensPreResolution(uint256 _eventId, uint256 _cogniTokenAmount)`: Enables users to burn their CogniTokens for an event before its resolution, receiving a pro-rata share of the current collateral pool.
14. `claimSettledCollateral(uint256 _eventId)`: Allows users to claim their share of collateral and rewards for an event after it has been finalized and resolved.

**IV. Event Resolution & Oracle Interaction**

15. `requestOutcomeFromChainlink(uint256 _eventId, bytes32 _chainlinkSpecId)`: Triggers a Chainlink request to fetch the actual outcome of a resolved event using the specified Chainlink job ID.
16. `fulfillOracleOutcome(bytes32 _requestId, int256 _outcome)`: Chainlink callback function that receives the reported outcome for a specific request ID. This updates the event's status and outcome.
17. `finalizeEventAndDistribute(uint256 _eventId)`: Finalizes a resolved event, calculates prediction accuracies, and distributes the underlying collateral pool among CogniToken holders based on their accurate prediction shares.

**V. Dispute Mechanism (Moderator/Owner Controlled)**

18. `initiateOutcomeDispute(uint256 _eventId)`: Allows a user to initiate a dispute against a Chainlink-reported outcome, requiring a small collateral stake.
19. `voteOnDispute(uint256 _eventId, bool _agreeWithOracle)`: Allows designated dispute resolvers (currently moderators/owner for simplicity) to vote on the validity of the reported oracle outcome.
20. `resolveDispute(uint256 _eventId, int256 _overrideOutcome)`: Resolves a dispute. If the dispute passes (based on internal logic or moderator decision), it allows overriding the initial oracle outcome and proceeds with distribution.

**VI. Protocol Analytics & Views (Public)**

21. `getEventStatus(uint256 _eventId)`: Returns the current status of a given prediction event.
22. `getEventConsensusPrediction(uint256 _eventId)`: Calculates and returns the current weighted average (consensus) prediction for an active event based on all submitted predictions.
23. `getCollateralBalance(uint256 _eventId)`: Returns the total amount of collateral locked in a specific event.
24. `getUserPredictionDetails(uint256 _eventId, address _user)`: Retrieves a user's specific prediction, staked collateral, and CogniToken shares for a given event.
25. `getAccruedProtocolFees()`: Returns the total amount of protocol fees accumulated from all events.
26. `withdrawProtocolFees()`: Allows the designated `protocolFeeRecipient` to withdraw the accumulated fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title AetherForge - Cognitive Asset Synthesis Protocol
 * @dev This contract enables users to make predictions on real-world events,
 *      stake collateral, and mint "CogniTokens" whose value is tied to the
 *      accuracy of aggregate predictions vs. the actual outcome. It leverages
 *      Chainlink oracles for event outcome resolution and includes a dispute system.
 */
contract AetherForge is Ownable, Pausable, ChainlinkClient {

    // --- Enums ---

    enum EventStatus {
        Active,          // Open for predictions
        SubmissionClosed, // Predictions closed, awaiting outcome request
        OutcomeRequested, // Outcome request sent to Chainlink
        OutcomeReceived,  // Outcome received from Chainlink, awaiting finalization or dispute
        Disputed,         // Outcome is under dispute
        Resolved,         // Event finalized, collateral distributed
        Canceled          // Event canceled, collateral refunded
    }

    enum OutcomeType {
        Numeric, // e.g., temperature, stock price
        Binary   // e.g., yes/no, win/loss (represented as 0 or 1 for numeric)
    }

    // --- Structs ---

    struct PredictionEvent {
        string topic;               // Brief description of the event
        string description;         // More detailed description
        uint256 creationTime;       // Timestamp of event creation
        uint256 submissionCutoffTime; // When prediction submissions close
        uint256 resolutionTime;     // Expected time for outcome resolution
        OutcomeType outcomeType;    // Type of outcome (numeric, binary)
        uint256 outcomePrecision;   // Decimal places for numeric outcome (e.g., 2 for 12.34 means 1234)
        EventStatus status;         // Current status of the event
        int256 actualOutcome;       // The final, verified outcome
        uint256 totalCollateral;    // Total collateral staked for this event
        uint256 totalCogniTokens;   // Total CogniTokens minted for this event
        bytes32 chainlinkRequestId; // Chainlink request ID for outcome (0 if not requested yet)
        bytes32 chainlinkSpecIdForOutcome; // The job ID used to request the outcome
        address creator;            // Address that created the event
    }

    struct UserPrediction {
        int256 predictedValue;      // The user's specific prediction
        uint256 stakedCollateral;   // Amount of collateral staked by the user
        uint256 cogniTokenShares;   // Shares of CogniTokens minted by the user
        bool hasClaimed;            // Whether the user has claimed their share post-resolution
    }

    struct Dispute {
        uint256 initiationTime;     // When the dispute was initiated
        address initiator;          // Address that initiated the dispute
        uint256 initiatorStake;     // Collateral staked by the initiator
        bool active;                // Is the dispute currently active?
        bool resolvedByOverride;    // True if resolved by moderator override, false if original outcome confirmed
        int256 overrideOutcome;     // The outcome if the dispute is resolved by override
    }

    // --- State Variables ---

    uint256 public nextEventId; // Counter for unique event IDs

    mapping(uint255 => PredictionEvent) public events;
    // eventId => userAddress => UserPrediction
    mapping(uint256 => mapping(address => UserPrediction)) public userPredictions;

    // Mapping for moderator roles
    mapping(address => bool) public eventModerators;

    // Protocol Fees
    address public protocolFeeRecipient;
    uint256 public protocolFeesAccrued;
    uint256 public protocolFeePercentage = 10; // 10 = 1% fee (x/1000)
    // Example: 1000 collateral * 10/1000 = 10 fee.

    // Collateral Token
    IERC20 public collateralToken;

    // Dispute System
    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeInitiationFee = 0.1 ether; // Fee in LINK, or collateral token, for simplicity using collateral token for now.
    uint256 public disputeVoteThreshold = 51; // Percentage needed for dispute to pass (e.g., 51 for 51%)

    // --- Events ---

    event EventCreated(
        uint256 indexed eventId,
        string topic,
        uint256 creationTime,
        address indexed creator
    );
    event PredictionSubmitted(
        uint256 indexed eventId,
        address indexed user,
        int256 predictedValue,
        uint256 stakedCollateral,
        uint256 cogniTokenShares
    );
    event EventOutcomeRequested(uint256 indexed eventId, bytes32 indexed requestId);
    event EventOutcomeReceived(uint256 indexed eventId, int256 outcome, bytes32 indexed requestId);
    event EventResolved(uint256 indexed eventId, int256 actualOutcome, uint256 totalDistributed);
    event EventCanceled(uint256 indexed eventId, uint256 refundedCollateral);
    event DisputeInitiated(uint256 indexed eventId, address indexed initiator);
    event DisputeResolved(uint256 indexed eventId, bool overruled, int256 newOutcome);
    event CollateralClaimed(uint256 indexed eventId, address indexed user, uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyModerator() {
        require(eventModerators[msg.sender] || msg.sender == owner(), "AetherForge: Only moderator or owner can perform this action");
        _;
    }

    // --- Constructor ---

    constructor(
        address _link,
        address _oracle,
        bytes32 _jobId,
        address _feeRecipient,
        address _collateralToken
    ) ChainlinkClient() {
        setChainlinkToken(_link); // LINK token address
        setOracle(_oracle);      // Chainlink Oracle address
        setJobId(_jobId);        // Default job ID for Chainlink requests

        protocolFeeRecipient = _feeRecipient;
        collateralToken = IERC20(_collateralToken);
        eventModerators[msg.sender] = true; // Owner is a moderator by default
        nextEventId = 1;
    }

    // --- I. Core Setup & Configuration (Administrative) ---

    /**
     * @dev Allows the owner to update the Chainlink oracle address and job ID.
     * @param _oracle The new Chainlink oracle address.
     * @param _jobId The new default Chainlink job ID.
     */
    function setChainlinkOracleConfig(address _oracle, bytes32 _jobId) external onlyOwner {
        setOracle(_oracle);
        setJobId(_jobId);
    }

    /**
     * @dev Allows the owner to change the accepted ERC20 collateral token.
     * @param _collateralToken The address of the new collateral token.
     */
    function setCollateralToken(address _collateralToken) external onlyOwner {
        require(address(collateralToken) == address(0), "AetherForge: Collateral token already set. Cannot change after initial setup.");
        collateralToken = IERC20(_collateralToken);
    }

    /**
     * @dev Allows the owner to update the address where protocol fees are sent.
     * @param _recipient The new address for protocol fee recipient.
     */
    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "AetherForge: Invalid fee recipient address");
        protocolFeeRecipient = _recipient;
    }

    /**
     * @dev Grants moderator privileges to an address.
     * @param _moderator The address to grant moderator privileges.
     */
    function addEventModerator(address _moderator) external onlyOwner {
        require(_moderator != address(0), "AetherForge: Invalid address");
        eventModerators[_moderator] = true;
    }

    /**
     * @dev Revokes moderator privileges from an address.
     * @param _moderator The address to revoke moderator privileges from.
     */
    function removeEventModerator(address _moderator) external onlyOwner {
        require(_moderator != owner(), "AetherForge: Cannot remove owner as moderator");
        eventModerators[_moderator] = false;
    }

    /**
     * @dev Emergency function to pause the contract, preventing most operations.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    // --- II. Prediction Event Management (Moderator Controlled) ---

    /**
     * @dev Creates a new prediction event.
     * @param _topic A brief title for the event.
     * @param _description A detailed description of the event.
     * @param _resolutionTime The expected timestamp when the event's outcome will be available.
     * @param _submissionCutoffTime The timestamp when prediction submissions will close.
     * @param _outcomeType The type of outcome (Numeric or Binary).
     * @param _outcomePrecision The number of decimal places for numeric outcomes (e.g., 2 for $12.34 means 1234).
     * @param _chainlinkSpecIdForOutcome The Chainlink Job ID specifically for resolving this event's outcome.
     */
    function createPredictionEvent(
        string memory _topic,
        string memory _description,
        uint256 _resolutionTime,
        uint256 _submissionCutoffTime,
        OutcomeType _outcomeType,
        uint256 _outcomePrecision,
        bytes32 _chainlinkSpecIdForOutcome
    ) external onlyModerator whenNotPaused returns (uint256) {
        require(bytes(_topic).length > 0, "AetherForge: Event topic cannot be empty");
        require(_submissionCutoffTime > block.timestamp, "AetherForge: Submission cutoff must be in the future");
        require(_resolutionTime > _submissionCutoffTime, "AetherForge: Resolution time must be after submission cutoff");
        require(_outcomePrecision <= 18, "AetherForge: Outcome precision too high");

        uint256 currentEventId = nextEventId++;
        events[currentEventId] = PredictionEvent({
            topic: _topic,
            description: _description,
            creationTime: block.timestamp,
            submissionCutoffTime: _submissionCutoffTime,
            resolutionTime: _resolutionTime,
            outcomeType: _outcomeType,
            outcomePrecision: _outcomePrecision,
            status: EventStatus.Active,
            actualOutcome: 0, // Placeholder
            totalCollateral: 0,
            totalCogniTokens: 0,
            chainlinkRequestId: bytes32(0),
            chainlinkSpecIdForOutcome: _chainlinkSpecIdForOutcome,
            creator: msg.sender
        });

        emit EventCreated(currentEventId, _topic, block.timestamp, msg.sender);
        return currentEventId;
    }

    /**
     * @dev Cancels an event before its resolution, refunding all staked collateral.
     * @param _eventId The ID of the event to cancel.
     */
    function cancelPredictionEvent(uint256 _eventId) external onlyModerator whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status < EventStatus.OutcomeReceived, "AetherForge: Event already past cancelation point");
        require(_event.status != EventStatus.Canceled, "AetherForge: Event already canceled");

        _event.status = EventStatus.Canceled;
        
        // Refund all staked collateral
        uint256 totalRefunded = 0;
        for (uint256 i = 1; i < nextEventId; i++) { // Iterate through all users for this event (not efficient for many users, but illustrative)
            address user = address(0); // Placeholder for user discovery, in a real system this would be a list of participants
            // This loop is purely conceptual for refunding. A real system would need to track participants more directly.
            // For now, let's assume `userPredictions` mapping is iterated by tracking all addresses that have submitted predictions.
            // This would require an additional mapping `mapping(uint256 => address[]) public eventParticipants;`
            // For this example, let's just make sure the `totalCollateral` is accounted for.
        }

        // Simplistic refund: Just allow users to withdraw their original stake, assuming they are tracked.
        // A more robust system would iterate over all participants for the event and refund.
        // For simplicity and gas, `cancel` will change status, and `claimSettledCollateral` (modified) will allow pre-resolution refund for canceled events.
        
        emit EventCanceled(_eventId, _event.totalCollateral); // totalCollateral represents the amount available for refund
    }

    /**
     * @dev Allows a moderator to update certain event metadata before the prediction submission cutoff time.
     * @param _eventId The ID of the event to update.
     * @param _newTopic The new topic string.
     * @param _newDescription The new description string.
     * @param _newSubmissionCutoffTime The new submission cutoff timestamp.
     */
    function updateEventDetails(
        uint256 _eventId,
        string memory _newTopic,
        string memory _newDescription,
        uint256 _newSubmissionCutoffTime
    ) external onlyModerator whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status == EventStatus.Active, "AetherForge: Event not in active status for updates");
        require(_newSubmissionCutoffTime > block.timestamp, "AetherForge: New submission cutoff must be in the future");
        require(_event.resolutionTime > _newSubmissionCutoffTime, "AetherForge: Resolution time must be after new submission cutoff");

        _event.topic = _newTopic;
        _event.description = _newDescription;
        _event.submissionCutoffTime = _newSubmissionCutoffTime;
        // No explicit event for update, but changes will be reflected in `getEventDetails`
    }

    // --- III. Participant Actions (Public) ---

    /**
     * @dev Allows a user to submit their prediction for an event, stake collateral, and forge CogniTokens.
     * @param _eventId The ID of the event to predict on.
     * @param _predictedValue The user's prediction (scaled by outcomePrecision for numeric).
     * @param _collateralAmount The amount of collateral token to stake.
     */
    function submitPredictionAndForge(
        uint256 _eventId,
        int256 _predictedValue,
        uint256 _collateralAmount
    ) external whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status == EventStatus.Active, "AetherForge: Event not active for predictions");
        require(block.timestamp <= _event.submissionCutoffTime, "AetherForge: Prediction submission period has ended");
        require(_collateralAmount > 0, "AetherForge: Collateral amount must be greater than zero");
        require(userPredictions[_eventId][msg.sender].stakedCollateral == 0, "AetherForge: User already submitted a prediction for this event");

        // Transfer collateral from user to contract
        require(collateralToken.transferFrom(msg.sender, address(this), _collateralAmount), "AetherForge: Collateral transfer failed");

        // Calculate CogniToken shares based on collateral (1:1 for simplicity)
        uint256 cogniShares = _collateralAmount;

        userPredictions[_eventId][msg.sender] = UserPrediction({
            predictedValue: _predictedValue,
            stakedCollateral: _collateralAmount,
            cogniTokenShares: cogniShares,
            hasClaimed: false
        });

        _event.totalCollateral += _collateralAmount;
        _event.totalCogniTokens += cogniShares;

        emit PredictionSubmitted(_eventId, msg.sender, _predictedValue, _collateralAmount, cogniShares);
    }

    /**
     * @dev Enables users to burn their CogniTokens for an event before its resolution,
     *      receiving a pro-rata share of the current collateral pool.
     * @param _eventId The ID of the event.
     * @param _cogniTokenAmount The amount of CogniTokens to redeem.
     */
    function redeemCogniTokensPreResolution(uint256 _eventId, uint256 _cogniTokenAmount) external whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        UserPrediction storage userPred = userPredictions[_eventId][msg.sender];

        require(_event.status == EventStatus.Active || _event.status == EventStatus.SubmissionClosed, "AetherForge: Event not in a redeemable state pre-resolution");
        require(userPred.cogniTokenShares >= _cogniTokenAmount, "AetherForge: Insufficient CogniTokens to redeem");
        require(_cogniTokenAmount > 0, "AetherForge: Redemption amount must be greater than zero");

        // Calculate the proportional collateral to refund
        uint256 collateralToRefund = (_cogniTokenAmount * _event.totalCollateral) / _event.totalCogniTokens;

        // Update balances
        userPred.cogniTokenShares -= _cogniTokenAmount;
        userPred.stakedCollateral -= collateralToRefund; // This might be slightly off if CogniToken shares are not perfectly 1:1 with collateral due to fees
        
        _event.totalCollateral -= collateralToRefund;
        _event.totalCogniTokens -= _cogniTokenAmount;

        // Transfer collateral back to user
        require(collateralToken.transfer(msg.sender, collateralToRefund), "AetherForge: Collateral refund failed");

        // Emit an event (can be combined with PredictionSubmitted if it's a "change" event)
    }


    /**
     * @dev Allows users to claim their share of collateral and rewards for an event
     *      after it has been finalized and resolved.
     * @param _eventId The ID of the event.
     */
    function claimSettledCollateral(uint256 _eventId) external whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        UserPrediction storage userPred = userPredictions[_eventId][msg.sender];

        require(_event.status == EventStatus.Resolved || _event.status == EventStatus.Canceled, "AetherForge: Event not yet resolved or canceled");
        require(userPred.stakedCollateral > 0, "AetherForge: No collateral or prediction for this event");
        require(!userPred.hasClaimed, "AetherForge: Collateral already claimed");

        uint256 amountToClaim;
        if (_event.status == EventStatus.Canceled) {
            // For canceled events, simply refund the original staked amount
            amountToClaim = userPred.stakedCollateral;
        } else { // EventStatus.Resolved
            // For resolved events, calculate based on accuracy (done in finalizeEventAndDistribute)
            // userPred.stakedCollateral already holds the final distributed amount for the user
            amountToClaim = userPred.stakedCollateral; // This should be the updated amount after distribution
        }

        require(amountToClaim > 0, "AetherForge: No amount to claim");

        userPred.hasClaimed = true;
        userPred.stakedCollateral = 0; // Reset user's holding for this event

        require(collateralToken.transfer(msg.sender, amountToClaim), "AetherForge: Claim transfer failed");

        emit CollateralClaimed(_eventId, msg.sender, amountToClaim);
    }

    // --- IV. Event Resolution & Oracle Interaction ---

    /**
     * @dev Triggers a Chainlink request to fetch the actual outcome of a resolved event.
     * @param _eventId The ID of the event to request outcome for.
     * @param _chainlinkSpecId The Chainlink Job ID to use for this specific outcome request.
     */
    function requestOutcomeFromChainlink(uint256 _eventId, bytes32 _chainlinkSpecId) external onlyModerator whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status == EventStatus.SubmissionClosed, "AetherForge: Event not ready for outcome request (status must be SubmissionClosed)");
        require(block.timestamp >= _event.submissionCutoffTime, "AetherForge: Cannot request outcome before submission cutoff");
        require(_event.chainlinkRequestId == bytes32(0), "AetherForge: Outcome already requested");

        Chainlink.Request memory req = buildChainlinkRequest(_chainlinkSpecId, address(this), this.fulfillOracleOutcome.selector);
        // Add parameters to the request based on the event's topic/description to guide the oracle.
        // Example: req.add("topic", _event.topic);
        // This would depend on the specific external adapter capabilities.
        // For numeric, we'd request a specific value, e.g., req.add("get", "https://api.example.com/data"); req.add("path", "price");
        // For binary, it could be a boolean or 0/1, e.g., req.add("get", "https://api.example.com/weather"); req.add("path", "rain");
        // This is highly specific to the Chainlink Job definition. For a generic contract, we assume the job ID knows what to fetch.
        
        // Store eventId in the request for callback context
        string memory eventIdStr = Strings.toString(_eventId);
        req.add("eventId", eventIdStr); // Custom param for tracking in fulfill

        _event.chainlinkRequestId = sendChainlinkRequest(req, LINK_TOKEN_FEE);
        _event.status = EventStatus.OutcomeRequested;

        emit EventOutcomeRequested(_eventId, _event.chainlinkRequestId);
    }

    /**
     * @dev Chainlink callback function that receives the reported outcome for a specific request ID.
     * @param _requestId The Chainlink request ID.
     * @param _outcome The actual outcome value reported by Chainlink.
     */
    function fulfillOracleOutcome(bytes32 _requestId, int256 _outcome) internal override recordChainlinkFulfillment(_requestId) {
        // Find the event ID associated with this request
        uint256 eventId;
        bool found = false;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (events[i].chainlinkRequestId == _requestId) {
                eventId = i;
                found = true;
                break;
            }
        }
        require(found, "AetherForge: Event not found for Chainlink request ID");

        PredictionEvent storage _event = events[eventId];
        require(_event.status == EventStatus.OutcomeRequested, "AetherForge: Event not awaiting outcome");

        _event.actualOutcome = _outcome;
        _event.status = EventStatus.OutcomeReceived;

        emit EventOutcomeReceived(eventId, _outcome, _requestId);
    }

    /**
     * @dev Finalizes a resolved event, calculates prediction accuracies, and distributes
     *      the underlying collateral pool among CogniToken holders based on their accurate prediction shares.
     * @param _eventId The ID of the event to finalize.
     */
    function finalizeEventAndDistribute(uint256 _eventId) external onlyModerator whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status == EventStatus.OutcomeReceived, "AetherForge: Event not ready for finalization (outcome not received)");
        require(block.timestamp >= _event.resolutionTime, "AetherForge: Cannot finalize before resolution time");
        require(disputes[_eventId].active == false, "AetherForge: Event is currently under dispute");

        _event.status = EventStatus.Resolved;

        int256 actualOutcome = _event.actualOutcome;
        uint256 totalAccurateShares = 0; // Sum of accuracy-weighted shares

        // First pass: Calculate accuracy scores and total accurate shares
        for (uint256 i = 1; i < nextEventId; i++) { // Iterate all possible users (inefficient, see note below)
            address user = address(uint160(i)); // Placeholder for user discovery
            if (userPredictions[_eventId][user].stakedCollateral > 0) {
                UserPrediction storage userPred = userPredictions[_eventId][user];
                int256 predictionDiff = actualOutcome - userPred.predictedValue;
                // Simple accuracy metric: inverse of absolute difference.
                // Scaled up to avoid division by zero or very small numbers
                uint256 accuracyScore = 0;
                if (predictionDiff == 0) {
                    accuracyScore = 1000000; // Max accuracy
                } else {
                    accuracyScore = 1000000 / (uint256(predictionDiff > 0 ? predictionDiff : -predictionDiff) + 1); // +1 to avoid div by zero
                }
                
                // Weight CogniTokens by accuracy
                uint256 weightedShares = (userPred.cogniTokenShares * accuracyScore) / 1000000; // Normalize back
                userPred.cogniTokenShares = weightedShares; // Temporarily store weighted shares
                totalAccurateShares += weightedShares;
            }
        }

        uint256 remainingCollateral = _event.totalCollateral;

        // Apply protocol fees (e.g., 1% of total collateral)
        uint256 protocolFee = (remainingCollateral * protocolFeePercentage) / 1000; // 10/1000 = 1%
        protocolFeesAccrued += protocolFee;
        remainingCollateral -= protocolFee;

        // Second pass: Distribute collateral based on weighted shares
        for (uint256 i = 1; i < nextEventId; i++) { // Iterate all possible users (inefficient, see note below)
            address user = address(uint160(i)); // Placeholder
            if (userPredictions[_eventId][user].stakedCollateral > 0) {
                UserPrediction storage userPred = userPredictions[_eventId][user];
                if (totalAccurateShares > 0) {
                    uint256 shareOfCollateral = (userPred.cogniTokenShares * remainingCollateral) / totalAccurateShares;
                    userPred.stakedCollateral = shareOfCollateral; // Update stakedCollateral to be the final claimable amount
                } else {
                    userPred.stakedCollateral = 0; // No accurate predictions, no reward
                }
            }
        }
        
        emit EventResolved(_eventId, actualOutcome, remainingCollateral);
    }
    
    // NOTE ON ITERATING USERS:
    // Iterating through all possible addresses (like `for (uint256 i = 1; i < nextEventId; i++) { address user = address(uint160(i)); ... }`)
    // is highly inefficient and not practical on EVM. A real-world contract would need:
    // 1. A dynamic array of participating addresses for each event.
    // 2. A Merkle tree or similar off-chain computation with on-chain verification for large participant sets.
    // For this example, it serves to illustrate the logic of processing all predictions.

    // --- V. Dispute Mechanism (Moderator/Owner Controlled) ---

    /**
     * @dev Allows a user to initiate a dispute against a Chainlink-reported outcome.
     *      Requires a small collateral stake.
     * @param _eventId The ID of the event to dispute.
     */
    function initiateOutcomeDispute(uint256 _eventId) external payable whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status == EventStatus.OutcomeReceived, "AetherForge: Event not in a state to be disputed");
        require(!disputes[_eventId].active, "AetherForge: Dispute already active for this event");
        require(msg.value == disputeInitiationFee, "AetherForge: Incorrect dispute initiation fee");
        // For simplicity, dispute fee is `msg.value` (ETH) here, but could be collateral token.

        disputes[_eventId] = Dispute({
            initiationTime: block.timestamp,
            initiator: msg.sender,
            initiatorStake: msg.value, // In ETH for now
            active: true,
            resolvedByOverride: false,
            overrideOutcome: 0 // Placeholder
        });

        _event.status = EventStatus.Disputed;
        emit DisputeInitiated(_eventId, msg.sender);
    }

    /**
     * @dev Allows designated dispute resolvers (currently moderators/owner for simplicity)
     *      to vote on the validity of the reported oracle outcome.
     *      This is a simplified voting mechanism. A full DAO would have separate logic.
     * @param _eventId The ID of the event under dispute.
     * @param _agreeWithOracle True if the voter agrees with the original oracle outcome, false to disagree.
     */
    function voteOnDispute(uint256 _eventId, bool _agreeWithOracle) external onlyModerator whenNotPaused {
        // In a real system, this would involve a more robust voting mechanism (e.g., token-weighted voting, conviction voting).
        // For this example, it's just a placeholder to acknowledge the dispute process.
        // A simple implementation could track votes per moderator, and a subsequent `resolveDispute` call checks counts.
        // As a conceptual example, we'll assume the moderator calling `resolveDispute` acts on behalf of the majority.
    }

    /**
     * @dev Resolves a dispute. If the dispute passes, it allows overriding the initial
     *      oracle outcome and proceeds with distribution. Only callable by owner/moderator after dispute.
     * @param _eventId The ID of the event.
     * @param _overrideOutcome The new, corrected outcome if the dispute leads to an override.
     */
    function resolveDispute(uint256 _eventId, int256 _overrideOutcome) external onlyModerator whenNotPaused {
        PredictionEvent storage _event = events[_eventId];
        Dispute storage currentDispute = disputes[_eventId];
        
        require(_event.status == EventStatus.Disputed, "AetherForge: Event not currently under dispute");
        require(currentDispute.active, "AetherForge: No active dispute for this event");

        // Simulate dispute outcome (e.g., based on majority vote from `voteOnDispute` calls, or moderator's decision)
        bool disputePassed = true; // Placeholder: In a real system, this would be determined by vote counts.

        currentDispute.active = false; // Mark dispute as resolved

        if (disputePassed) {
            _event.actualOutcome = _overrideOutcome;
            currentDispute.resolvedByOverride = true;
            // Optionally, refund dispute initiator's stake.
            // payable(currentDispute.initiator).transfer(currentDispute.initiatorStake);
        } else {
            // Original oracle outcome stands.
            currentDispute.resolvedByOverride = false;
            // Optionally, penalize dispute initiator (e.g., forfeit stake).
        }

        _event.status = EventStatus.OutcomeReceived; // Revert to OutcomeReceived to allow `finalizeEventAndDistribute`
        emit DisputeResolved(_eventId, disputePassed, _event.actualOutcome);
    }

    // --- VI. Protocol Analytics & Views (Public) ---

    /**
     * @dev Returns the current status of a given prediction event.
     * @param _eventId The ID of the event.
     * @return The EventStatus enum value.
     */
    function getEventStatus(uint256 _eventId) external view returns (EventStatus) {
        require(_eventId > 0 && _eventId < nextEventId, "AetherForge: Invalid event ID");
        return events[_eventId].status;
    }

    /**
     * @dev Calculates and returns the current weighted average (consensus) prediction
     *      for an active event based on all submitted predictions.
     * @param _eventId The ID of the event.
     * @return The aggregated consensus prediction.
     */
    function getEventConsensusPrediction(uint256 _eventId) external view returns (int256) {
        PredictionEvent storage _event = events[_eventId];
        require(_event.status == EventStatus.Active || _event.status == EventStatus.SubmissionClosed, "AetherForge: Event not in active prediction phase");

        int256 totalWeightedPrediction = 0;
        uint256 totalShares = 0;

        // This loop is for illustrative purposes only.
        // In a production environment, iterating over all possible addresses like this
        // is extremely gas-inefficient and not practical.
        // A practical solution would involve maintaining a list of participants for each event.
        for (uint256 i = 1; i < nextEventId; i++) { // Placeholder loop for users
            address user = address(uint160(i));
            UserPrediction storage userPred = userPredictions[_eventId][user];
            if (userPred.stakedCollateral > 0) {
                totalWeightedPrediction += userPred.predictedValue * int256(userPred.cogniTokenShares);
                totalShares += userPred.cogniTokenShares;
            }
        }

        if (totalShares == 0) {
            return 0; // No predictions yet
        }
        return totalWeightedPrediction / int256(totalShares);
    }

    /**
     * @dev Returns the total amount of collateral locked in a specific event.
     * @param _eventId The ID of the event.
     * @return The total collateral amount.
     */
    function getCollateralBalance(uint256 _eventId) external view returns (uint256) {
        require(_eventId > 0 && _eventId < nextEventId, "AetherForge: Invalid event ID");
        return events[_eventId].totalCollateral;
    }

    /**
     * @dev Retrieves a user's specific prediction, staked collateral, and CogniToken shares for a given event.
     * @param _eventId The ID of the event.
     * @param _user The address of the user.
     * @return predictedValue The user's prediction.
     * @return stakedCollateral The amount of collateral staked by the user.
     * @return cogniTokenShares The shares of CogniTokens minted by the user.
     * @return hasClaimed Whether the user has claimed their share.
     */
    function getUserPredictionDetails(uint256 _eventId, address _user)
        external
        view
        returns (int256 predictedValue, uint256 stakedCollateral, uint256 cogniTokenShares, bool hasClaimed)
    {
        require(_eventId > 0 && _eventId < nextEventId, "AetherForge: Invalid event ID");
        UserPrediction storage userPred = userPredictions[_eventId][_user];
        return (userPred.predictedValue, userPred.stakedCollateral, userPred.cogniTokenShares, userPred.hasClaimed);
    }

    /**
     * @dev Returns the total amount of protocol fees accumulated.
     * @return The total accrued protocol fees.
     */
    function getAccruedProtocolFees() external view returns (uint256) {
        return protocolFeesAccrued;
    }

    /**
     * @dev Allows the designated `protocolFeeRecipient` to withdraw the accumulated fees.
     */
    function withdrawProtocolFees() external whenNotPaused {
        require(msg.sender == protocolFeeRecipient, "AetherForge: Only fee recipient can withdraw fees");
        uint256 fees = protocolFeesAccrued;
        require(fees > 0, "AetherForge: No fees to withdraw");
        protocolFeesAccrued = 0;
        require(collateralToken.transfer(protocolFeeRecipient, fees), "AetherForge: Fee withdrawal failed");
        emit FeesWithdrawn(protocolFeeRecipient, fees);
    }
}
```