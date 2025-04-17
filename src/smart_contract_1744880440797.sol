```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Prediction Market (DDPM) - Smart Contract Outline and Functions Summary
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized prediction market with dynamic elements,
 *      going beyond simple betting platforms. It focuses on user engagement, market robustness,
 *      and incorporates advanced concepts like dynamic fees, decentralized dispute resolution,
 *      and tiered prediction outcomes.  This is a conceptual example and may require further
 *      security audits and refinements for production use.
 *
 * **Outline and Function Summary:**
 *
 * **Market Management:**
 * 1. `createEvent(string _eventName, uint256 _endTime, string[] _outcomes, address _oracle)`: Allows admin to create a new prediction event with multiple outcomes, end time, and assigned oracle.
 * 2. `resolveEvent(uint256 _eventId, uint256 _winningOutcomeIndex)`: Allows assigned oracle to resolve an event by selecting the winning outcome index.
 * 3. `cancelEvent(uint256 _eventId)`: Allows admin to cancel an event before it ends, refunding participants.
 * 4. `pauseMarket()`: Allows admin to pause the entire market for maintenance or emergency.
 * 5. `unpauseMarket()`: Allows admin to resume the market operations.
 * 6. `setOracleAddress(uint256 _eventId, address _newOracle)`: Allows admin to change the oracle for a specific event.
 * 7. `setMarketFee(uint256 _newFeePercentage)`: Allows admin to set the market fee percentage applied to winnings.
 * 8. `setDisputeFee(uint256 _newDisputeFee)`: Allows admin to set the fee for initiating a dispute.
 *
 * **Prediction & Participation:**
 * 9. `placePrediction(uint256 _eventId, uint256 _outcomeIndex, uint256 _amount)`: Allows users to place a prediction on an event outcome, contributing funds to the pool.
 * 10. `claimWinnings(uint256 _eventId)`: Allows users to claim their winnings if they predicted the correct outcome after event resolution.
 * 11. `getUserBalance(address _user)`: View function to check a user's claimable balance across all events.
 * 12. `getEventDetails(uint256 _eventId)`: View function to retrieve detailed information about a specific event.
 * 13. `getPredictionDetails(uint256 _predictionId)`: View function to retrieve details about a specific user's prediction.
 * 14. `getUserPredictionHistory(address _user)`: View function to retrieve a user's history of predictions.
 *
 * **Dispute Resolution (Decentralized - Example with simple voting):**
 * 15. `initiateDispute(uint256 _eventId, string _disputeReason)`: Allows users to initiate a dispute for a resolved event if they disagree with the oracle's outcome. Requires paying a dispute fee.
 * 16. `voteOnDispute(uint256 _disputeId, bool _supportOriginalOutcome)`: Allows users to vote on an active dispute, influencing the final outcome. (Simple voting example, can be replaced with more sophisticated mechanisms).
 * 17. `resolveDispute(uint256 _disputeId)`: Allows admin (or a designated dispute resolver) to finalize a dispute based on voting results or further investigation.
 *
 * **Advanced & Trendy Features:**
 * 18. `dynamicOutcomeOdds(uint256 _eventId, uint256 _outcomeIndex)`: View function to calculate and return dynamic odds for an outcome based on the current prediction pool distribution.
 * 19. `getTrendingEvents()`: View function to return a list of events that are currently trending (e.g., most predictions placed, highest participation).
 * 20. `emergencyWithdraw(uint256 _eventId)`: Allows users to withdraw their prediction amount from an event if it's cancelled or facing unforeseen issues (with admin approval in some cases).
 * 21. `getMarketStats()`: View function to return overall market statistics like total events, total participants, total volume, etc. (Bonus function, exceeding 20).
 */

contract DecentralizedDynamicPredictionMarket {
    // -------- State Variables --------

    address public admin;
    uint256 public marketFeePercentage; // Fee applied to winnings
    uint256 public disputeFee;         // Fee to initiate a dispute
    bool public paused;

    uint256 public nextEventId;
    mapping(uint256 => Event) public events;

    uint256 public nextPredictionId;
    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => mapping(address => uint256)) public eventUserPredictions; // eventId => user => predictionId

    uint256 public nextDisputeId;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public disputeVotes; // disputeId => user => vote (true for original outcome, false against)

    // -------- Structs --------

    struct Event {
        uint256 eventId;
        string eventName;
        uint256 endTime;
        string[] outcomes;
        address oracle;
        uint256 winningOutcomeIndex; // Index of the winning outcome, set after resolution
        bool isResolved;
        bool isCancelled;
        uint256 totalPoolAmount;
        uint256 disputeId; // ID of associated dispute if any, 0 if none
    }

    struct Prediction {
        uint256 predictionId;
        uint256 eventId;
        address user;
        uint256 outcomeIndex;
        uint256 amount;
        bool hasClaimedWinnings;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 eventId;
        string disputeReason;
        address initiator;
        bool isOpen;
        uint256 votesForOriginalOutcome;
        uint256 votesAgainstOriginalOutcome;
        uint256 resolutionOutcomeIndex; // Outcome index after dispute resolution (can be different from oracle's)
    }

    // -------- Events --------

    event EventCreated(uint256 eventId, string eventName, uint256 endTime, address oracle);
    event EventResolved(uint256 eventId, uint256 winningOutcomeIndex);
    event EventCancelled(uint256 eventId);
    event MarketPaused();
    event MarketUnpaused();
    event OracleAddressSet(uint256 eventId, address newOracle);
    event MarketFeeSet(uint256 newFeePercentage);
    event DisputeFeeSet(uint256 newDisputeFee);

    event PredictionPlaced(uint256 predictionId, uint256 eventId, address user, uint256 outcomeIndex, uint256 amount);
    event WinningsClaimed(uint256 eventId, address user, uint256 amount);

    event DisputeInitiated(uint256 disputeId, uint256 eventId, address initiator, string disputeReason);
    event VoteCastOnDispute(uint256 disputeId, address voter, bool supportOriginalOutcome);
    event DisputeResolved(uint256 disputeId, uint256 eventId, uint256 resolutionOutcomeIndex);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyOracle(uint256 _eventId) {
        require(msg.sender == events[_eventId].oracle, "Only the assigned oracle can call this function.");
        _;
    }

    modifier eventExists(uint256 _eventId) {
        require(events[_eventId].eventId != 0, "Event does not exist.");
        _;
    }

    modifier eventNotResolved(uint256 _eventId) {
        require(!events[_eventId].isResolved, "Event is already resolved.");
        _;
    }

    modifier eventNotCancelled(uint256 _eventId) {
        require(!events[_eventId].isCancelled, "Event is cancelled.");
        _;
    }

    modifier marketNotPaused() {
        require(!paused, "Market is currently paused.");
        _;
    }

    modifier disputeOpen(uint256 _disputeId) {
        require(disputes[_disputeId].isOpen, "Dispute is not open.");
        _;
    }

    modifier disputeNotExists(uint256 _eventId) {
        require(events[_eventId].disputeId == 0, "Dispute already exists for this event.");
        _;
    }


    // -------- Constructor --------

    constructor(uint256 _initialFeePercentage, uint256 _initialDisputeFee) {
        admin = msg.sender;
        marketFeePercentage = _initialFeePercentage;
        disputeFee = _initialDisputeFee;
        paused = false;
        nextEventId = 1;
        nextPredictionId = 1;
        nextDisputeId = 1;
    }

    // -------- Market Management Functions --------

    /// @notice Allows admin to create a new prediction event.
    /// @param _eventName Name of the event.
    /// @param _endTime Unix timestamp for when the event ends.
    /// @param _outcomes Array of possible outcomes for the event.
    /// @param _oracle Address of the oracle responsible for resolving the event.
    function createEvent(
        string memory _eventName,
        uint256 _endTime,
        string[] memory _outcomes,
        address _oracle
    ) external onlyAdmin marketNotPaused {
        require(_endTime > block.timestamp, "End time must be in the future.");
        require(_outcomes.length > 1, "At least two outcomes are required.");
        require(_oracle != address(0), "Oracle address cannot be zero.");

        events[nextEventId] = Event({
            eventId: nextEventId,
            eventName: _eventName,
            endTime: _endTime,
            outcomes: _outcomes,
            oracle: _oracle,
            winningOutcomeIndex: 0, // Initially no winning outcome
            isResolved: false,
            isCancelled: false,
            totalPoolAmount: 0,
            disputeId: 0
        });

        emit EventCreated(nextEventId, _eventName, _endTime, _oracle);
        nextEventId++;
    }

    /// @notice Allows the assigned oracle to resolve an event by selecting the winning outcome.
    /// @param _eventId ID of the event to resolve.
    /// @param _winningOutcomeIndex Index of the winning outcome in the outcomes array.
    function resolveEvent(uint256 _eventId, uint256 _winningOutcomeIndex)
        external
        onlyOracle(_eventId)
        eventExists(_eventId)
        eventNotResolved(_eventId)
        eventNotCancelled(_eventId)
        marketNotPaused
    {
        require(_winningOutcomeIndex < events[_eventId].outcomes.length, "Invalid outcome index.");
        require(block.timestamp > events[_eventId].endTime, "Event end time has not passed.");

        events[_eventId].winningOutcomeIndex = _winningOutcomeIndex;
        events[_eventId].isResolved = true;

        emit EventResolved(_eventId, _winningOutcomeIndex);
    }

    /// @notice Allows admin to cancel an event before it ends, refunding participants.
    /// @param _eventId ID of the event to cancel.
    function cancelEvent(uint256 _eventId)
        external
        onlyAdmin
        eventExists(_eventId)
        eventNotResolved(_eventId)
        eventNotCancelled(_eventId)
        marketNotPaused
    {
        events[_eventId].isCancelled = true;
        emit EventCancelled(_eventId);
        // Refund logic would typically be implemented here (complex, might need withdrawal function)
        // For simplicity, refund logic is omitted in this example outline.
    }

    /// @notice Pauses the entire market operations.
    function pauseMarket() external onlyAdmin {
        paused = true;
        emit MarketPaused();
    }

    /// @notice Resumes the market operations.
    function unpauseMarket() external onlyAdmin {
        paused = false;
        emit MarketUnpaused();
    }

    /// @notice Allows admin to change the oracle for a specific event.
    /// @param _eventId ID of the event.
    /// @param _newOracle Address of the new oracle.
    function setOracleAddress(uint256 _eventId, address _newOracle) external onlyAdmin eventExists(_eventId) marketNotPaused {
        require(_newOracle != address(0), "New oracle address cannot be zero.");
        events[_eventId].oracle = _newOracle;
        emit OracleAddressSet(_eventId, _newOracle);
    }

    /// @notice Allows admin to set the market fee percentage.
    /// @param _newFeePercentage New market fee percentage (e.g., 5 for 5%).
    function setMarketFee(uint256 _newFeePercentage) external onlyAdmin marketNotPaused {
        marketFeePercentage = _newFeePercentage;
        emit MarketFeeSet(_newFeePercentage);
    }

    /// @notice Allows admin to set the dispute fee.
    /// @param _newDisputeFee New dispute fee amount.
    function setDisputeFee(uint256 _newDisputeFee) external onlyAdmin marketNotPaused {
        disputeFee = _newDisputeFee;
        emit DisputeFeeSet(_newDisputeFee);
    }


    // -------- Prediction & Participation Functions --------

    /// @notice Allows users to place a prediction on an event outcome.
    /// @param _eventId ID of the event.
    /// @param _outcomeIndex Index of the outcome to predict.
    /// @param _amount Amount to bet in wei.
    function placePrediction(uint256 _eventId, uint256 _outcomeIndex, uint256 _amount)
        external
        payable
        eventExists(_eventId)
        eventNotResolved(_eventId)
        eventNotCancelled(_eventId)
        marketNotPaused
    {
        require(_outcomeIndex < events[_eventId].outcomes.length, "Invalid outcome index.");
        require(block.timestamp < events[_eventId].endTime, "Event has already ended.");
        require(msg.value == _amount, "Incorrect amount sent.");
        require(_amount > 0, "Prediction amount must be greater than zero.");

        uint256 predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            predictionId: predictionId,
            eventId: _eventId,
            user: msg.sender,
            outcomeIndex: _outcomeIndex,
            amount: _amount,
            hasClaimedWinnings: false
        });
        eventUserPredictions[_eventId][msg.sender] = predictionId; // Store the latest prediction ID for user and event
        events[_eventId].totalPoolAmount += _amount;

        emit PredictionPlaced(predictionId, _eventId, msg.sender, _outcomeIndex, _amount);
    }

    /// @notice Allows users to claim their winnings if they predicted correctly.
    /// @param _eventId ID of the resolved event.
    function claimWinnings(uint256 _eventId)
        external
        eventExists(_eventId)
        eventNotCancelled(_eventId)
        marketNotPaused
    {
        require(events[_eventId].isResolved, "Event is not yet resolved.");

        uint256 predictionId = eventUserPredictions[_eventId][msg.sender];
        require(predictionId != 0, "No prediction found for this event.");
        Prediction storage userPrediction = predictions[predictionId];

        require(!userPrediction.hasClaimedWinnings, "Winnings already claimed.");
        require(userPrediction.outcomeIndex == events[_eventId].winningOutcomeIndex, "Incorrect prediction outcome.");

        uint256 totalPoolForOutcome = 0;
        uint256 totalCorrectPredictions = 0;

        // Calculate total pool and correct predictions for the winning outcome
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].eventId == _eventId && predictions[i].outcomeIndex == events[_eventId].winningOutcomeIndex) {
                totalPoolForOutcome += predictions[i].amount;
                totalCorrectPredictions++;
            }
        }

        uint256 userWinnings;
        if (totalCorrectPredictions > 0) {
            userWinnings = (userPrediction.amount * events[_eventId].totalPoolAmount) / totalPoolForOutcome; // Proportional winnings
            uint256 marketFee = (userWinnings * marketFeePercentage) / 100;
            userWinnings -= marketFee; // Apply market fee

            payable(msg.sender).transfer(userWinnings);
            userPrediction.hasClaimedWinnings = true;
            emit WinningsClaimed(_eventId, msg.sender, userWinnings);
        } else {
            // No correct predictions, refund user's bet (or handle differently as per design)
            payable(msg.sender).transfer(userPrediction.amount); // Refund bet if no winners for outcome
            userPrediction.hasClaimedWinnings = true; // Mark as claimed (even if it's a refund)
            emit WinningsClaimed(_eventId, msg.sender, userPrediction.amount); // Event for refund too
        }
    }

    /// @notice View function to check a user's claimable balance across all events.
    /// @param _user Address of the user.
    /// @return Total claimable balance for the user.
    function getUserBalance(address _user) external view returns (uint256) {
        uint256 totalClaimableBalance = 0;
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].user == _user && !predictions[i].hasClaimedWinnings && events[predictions[i].eventId].isResolved && predictions[i].outcomeIndex == events[predictions[i].eventId].winningOutcomeIndex) {
                // Simplified balance calculation for outline - actual calculation needs to consider pool distribution
                totalClaimableBalance += predictions[i].amount; // Placeholder, actual winnings calculation needed
            }
        }
        return totalClaimableBalance;
    }

    /// @notice View function to retrieve detailed information about a specific event.
    /// @param _eventId ID of the event.
    /// @return Event struct containing event details.
    function getEventDetails(uint256 _eventId) external view eventExists(_eventId) returns (Event memory) {
        return events[_eventId];
    }

    /// @notice View function to retrieve details about a specific user's prediction.
    /// @param _predictionId ID of the prediction.
    /// @return Prediction struct containing prediction details.
    function getPredictionDetails(uint256 _predictionId) external view returns (Prediction memory) {
        return predictions[_predictionId];
    }

    /// @notice View function to retrieve a user's history of predictions.
    /// @param _user Address of the user.
    /// @return Array of prediction IDs made by the user.
    function getUserPredictionHistory(address _user) external view returns (uint256[] memory) {
        uint256[] memory userPredictions = new uint256[](nextPredictionId); // Over-allocate, then resize
        uint256 count = 0;
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].user == _user) {
                userPredictions[count++] = predictions[i].predictionId;
            }
        }
        // Resize array to actual number of predictions
        assembly {
            mstore(userPredictions, count) // Store actual length at the beginning of array
        }
        return userPredictions;
    }


    // -------- Dispute Resolution Functions --------

    /// @notice Allows users to initiate a dispute for a resolved event.
    /// @param _eventId ID of the event in dispute.
    /// @param _disputeReason Reason for initiating the dispute.
    function initiateDispute(uint256 _eventId, string memory _disputeReason)
        external
        payable
        eventExists(_eventId)
        eventNotCancelled(_eventId)
        marketNotPaused
        disputeNotExists(_eventId)
    {
        require(events[_eventId].isResolved, "Event must be resolved to initiate dispute.");
        require(msg.value == disputeFee, "Dispute fee is required.");

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            eventId: _eventId,
            disputeReason: _disputeReason,
            initiator: msg.sender,
            isOpen: true,
            votesForOriginalOutcome: 0,
            votesAgainstOriginalOutcome: 0,
            resolutionOutcomeIndex: 0 // Initially no resolution outcome set
        });
        events[_eventId].disputeId = disputeId; // Link dispute to event

        emit DisputeInitiated(disputeId, _eventId, msg.sender, _disputeReason);
        nextDisputeId++;
    }

    /// @notice Allows users to vote on an active dispute.
    /// @param _disputeId ID of the dispute to vote on.
    /// @param _supportOriginalOutcome True to support the oracle's original outcome, false to vote against.
    function voteOnDispute(uint256 _disputeId, bool _supportOriginalOutcome)
        external
        disputeOpen(_disputeId)
        marketNotPaused
    {
        require(!disputeVotes[_disputeId][msg.sender], "User has already voted on this dispute.");
        disputeVotes[_disputeId][msg.sender] = true; // Mark user as voted

        if (_supportOriginalOutcome) {
            disputes[_disputeId].votesForOriginalOutcome++;
        } else {
            disputes[_disputeId].votesAgainstOriginalOutcome++;
        }

        emit VoteCastOnDispute(_disputeId, msg.sender, _supportOriginalOutcome);
    }

    /// @notice Allows admin (or designated resolver) to finalize a dispute based on votes or investigation.
    /// @param _disputeId ID of the dispute to resolve.
    function resolveDispute(uint256 _disputeId)
        external
        onlyAdmin // Or could be a designated dispute resolver role
        disputeOpen(_disputeId)
        marketNotPaused
    {
        disputes[_disputeId].isOpen = false; // Close the dispute

        uint256 resolutionOutcome;
        if (disputes[_disputeId].votesAgainstOriginalOutcome > disputes[_disputeId].votesForOriginalOutcome) {
            // Example: Majority vote against original outcome.  Admin could decide new outcome or re-resolve.
            resolutionOutcome = 0; // Example: Set to index 0 as a "no result" or re-evaluation needed.
            // In a real system, more sophisticated logic would be here (e.g., admin manually sets outcome, or triggers re-resolution)
        } else {
            resolutionOutcome = events[disputes[_disputeId].eventId].winningOutcomeIndex; // Keep original oracle outcome if vote is tied or in favor.
        }

        disputes[_disputeId].resolutionOutcomeIndex = resolutionOutcome;
        emit DisputeResolved(_disputeId, disputes[_disputeId].eventId, resolutionOutcome);

        // Optionally, handle refunds/re-distribution of pool based on dispute resolution here.
        // This is complex and depends on the desired dispute resolution mechanism.
    }


    // -------- Advanced & Trendy Features --------

    /// @notice View function to calculate dynamic odds for an outcome based on current prediction pool.
    /// @param _eventId ID of the event.
    /// @param _outcomeIndex Index of the outcome to calculate odds for.
    /// @return Dynamic odds for the outcome (simplified calculation - needs refinement).
    function dynamicOutcomeOdds(uint256 _eventId, uint256 _outcomeIndex)
        external
        view
        eventExists(_eventId)
        returns (uint256)
    {
        uint256 totalPool = events[_eventId].totalPoolAmount;
        uint256 outcomePool = 0;

        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].eventId == _eventId && predictions[i].outcomeIndex == _outcomeIndex) {
                outcomePool += predictions[i].amount;
            }
        }

        if (outcomePool == 0 || totalPool == 0) {
            return 0; // Or return a default odds value
        }

        // Simplified odds calculation: (Total Pool / Outcome Pool) * 100 (for percentage representation)
        // Needs more sophisticated odds calculation in a real-world scenario considering overround, etc.
        return (totalPool * 100) / outcomePool;
    }

    /// @notice View function to get a list of trending events (example: based on pool size).
    /// @return Array of event IDs of trending events.
    function getTrendingEvents() external view returns (uint256[] memory) {
        uint256[] memory trendingEvents = new uint256[](nextEventId); // Over-allocate
        uint256 count = 0;
        uint256 maxEventsToReturn = 5; // Example limit to top 5 trending events

        // Simple trending logic: events with highest totalPoolAmount
        uint256[] memory eventPoolAmounts = new uint256[](nextEventId);
        for (uint256 i = 1; i < nextEventId; i++) {
            eventPoolAmounts[i] = events[i].totalPoolAmount;
        }

        // Basic sorting (inefficient for large number of events, use more efficient sorting for production)
        for (uint256 i = 0; i < nextEventId -1; i++) {
            for (uint256 j = i + 1; j < nextEventId; j++) {
                if (eventPoolAmounts[i+1] < eventPoolAmounts[j+1]) {
                    uint256 tempAmount = eventPoolAmounts[i+1];
                    eventPoolAmounts[i+1] = eventPoolAmounts[j+1];
                    eventPoolAmounts[j+1] = tempAmount;

                    uint256 tempEventId = trendingEvents[i];
                    trendingEvents[i] = trendingEvents[j];
                    trendingEvents[j] = tempEventId;
                }
            }
        }

        for (uint256 i = 0; i < nextEventId-1 && count < maxEventsToReturn; i++) {
            if (events[i+1].eventId != 0) { // Check if event exists (to skip empty slots)
                trendingEvents[count++] = events[i+1].eventId;
            }
        }


        // Resize array to actual number of trending events
        assembly {
            mstore(trendingEvents, count)
        }
        return trendingEvents;
    }

    /// @notice Allows users to request emergency withdrawal of their bet if an event is cancelled (admin approval might be needed).
    /// @param _eventId ID of the cancelled event.
    function emergencyWithdraw(uint256 _eventId)
        external
        eventExists(_eventId)
        eventNotResolved(_eventId)
        marketNotPaused
    {
        require(events[_eventId].isCancelled, "Event is not cancelled.");
        uint256 predictionId = eventUserPredictions[_eventId][msg.sender];
        require(predictionId != 0, "No prediction found for this event.");
        Prediction storage userPrediction = predictions[predictionId];

        require(!userPrediction.hasClaimedWinnings, "Withdrawal already processed or winnings claimed.");

        // In a real system, admin approval or specific conditions might be added before withdrawal.
        payable(msg.sender).transfer(userPrediction.amount);
        userPrediction.hasClaimedWinnings = true; // Mark as claimed (withdrawal processed)
        emit WinningsClaimed(_eventId, msg.sender, userPrediction.amount); // Use WinningsClaimed event for withdrawal too
    }

    /// @notice View function to get overall market statistics.
    /// @return Total events created, total participants, total volume.
    function getMarketStats() external view returns (uint256 totalEvents, uint256 totalParticipants, uint256 totalVolume) {
        totalEvents = nextEventId - 1; // Events created
        // To get accurate participant count, we'd need to track unique users per event or across market
        // This example provides a very rough estimate based on prediction count (may overestimate)
        totalParticipants = nextPredictionId -1; // Approximated by total predictions (not unique users)
        totalVolume = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            totalVolume += events[i].totalPoolAmount;
        }
    }
}
```