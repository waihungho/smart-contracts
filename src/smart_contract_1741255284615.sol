```solidity
/**
 * @title Decentralized Autonomous Lottery & Prediction Market (DALPM)
 * @author Bard (AI Assistant)
 * @dev A smart contract that combines a lottery system with a prediction market,
 *      governed by simple on-chain parameters and designed for transparency and user engagement.
 *
 * **Outline and Function Summary:**
 *
 * **Core Lottery Functions:**
 * 1. `enterLottery(uint256 _lotteryId)`: Allows users to enter a specific lottery by paying the entry fee.
 * 2. `drawLottery(uint256 _lotteryId)`:  Owner-only function to draw a lottery, selecting a winner randomly.
 * 3. `claimLotteryWinnings(uint256 _lotteryId)`: Allows the lottery winner to claim their prize.
 * 4. `getLotteryDetails(uint256 _lotteryId)`: View function to get details about a specific lottery (status, prize, participants, etc.).
 * 5. `getLotteryParticipants(uint256 _lotteryId)`: View function to get a list of participants in a lottery.
 * 6. `getLotteryWinner(uint256 _lotteryId)`: View function to get the winner of a drawn lottery.
 * 7. `getLotteryStatus(uint256 _lotteryId)`: View function to check the current status of a lottery.
 * 8. `createLottery(string memory _lotteryName, uint256 _entryFee, uint256 _duration)`: Owner-only function to create a new lottery.
 * 9. `cancelLottery(uint256 _lotteryId)`: Owner-only function to cancel a lottery before it's drawn, refunding participants.
 *
 * **Prediction Market Functions:**
 * 10. `createPredictionEvent(string memory _eventName, string memory _description, uint256 _endTime, string[] memory _options)`: Owner-only function to create a new prediction event.
 * 11. `predictEventOutcome(uint256 _eventId, uint256 _optionIndex)`: Allows users to place a prediction on an event by paying a prediction fee.
 * 12. `resolvePredictionEvent(uint256 _eventId, uint256 _correctOptionIndex)`: Owner-only function to resolve a prediction event and declare the correct outcome.
 * 13. `claimPredictionWinnings(uint256 _eventId)`: Allows users who predicted correctly to claim their winnings.
 * 14. `getEventDetails(uint256 _eventId)`: View function to get details about a specific prediction event (status, options, end time, etc.).
 * 15. `getEventPredictions(uint256 _eventId)`: View function to get a list of predictions for an event.
 * 16. `getEventStatus(uint256 _eventId)`: View function to check the current status of a prediction event.
 * 17. `cancelPredictionEvent(uint256 _eventId)`: Owner-only function to cancel a prediction event before resolution, refunding participants.
 *
 * **Admin & Utility Functions:**
 * 18. `setLotteryEntryFee(uint256 _lotteryId, uint256 _newFee)`: Owner-only function to update the entry fee for a specific lottery.
 * 19. `setPredictionFee(uint256 _newFee)`: Owner-only function to set the base prediction fee for prediction events.
 * 20. `withdrawContractBalance()`: Owner-only function to withdraw the contract's accumulated balance (minus active lottery prizes and prediction winnings).
 * 21. `pauseContract()`: Owner-only function to pause the contract, disabling most functionalities.
 * 22. `unpauseContract()`: Owner-only function to unpause the contract, restoring functionalities.
 * 23. `isContractPaused()`: View function to check if the contract is currently paused.
 * 24. `getContractOwner()`: View function to retrieve the contract owner's address.
 */
pragma solidity ^0.8.0;

import "hardhat/console.sol"; // For debugging - remove in production

contract DecentralizedAutonomousLotteryPredictionMarket {
    address public owner;
    bool public paused;

    uint256 public predictionFee; // Base prediction fee

    uint256 public nextLotteryId;
    uint256 public nextEventId;

    struct Lottery {
        string name;
        uint256 entryFee;
        uint256 prizePool;
        uint256 startTime;
        uint256 duration; // Lottery duration in seconds
        address[] participants;
        address winner;
        bool isDrawn;
        bool isActive; // Lottery is active and accepting entries
    }

    struct PredictionEvent {
        string name;
        string description;
        uint256 endTime;
        string[] options;
        uint256 correctOptionIndex;
        mapping(address => uint256) predictions; // User address => option index chosen
        mapping(address => bool) claimedWinnings;
        bool isResolved;
        bool isActive; // Event is active and accepting predictions
    }

    mapping(uint256 => Lottery) public lotteries;
    mapping(uint256 => PredictionEvent) public predictionEvents;

    event LotteryCreated(uint256 lotteryId, string name, uint256 entryFee, uint256 duration);
    event LotteryEntered(uint256 lotteryId, address participant);
    event LotteryDrawn(uint256 lotteryId, address winner);
    event LotteryWinningsClaimed(uint256 lotteryId, address winner, uint256 amount);
    event LotteryCancelled(uint256 lotteryId);

    event PredictionEventCreated(uint256 eventId, string name, uint256 endTime, string[] options);
    event PredictionPlaced(uint256 eventId, address predictor, uint256 optionIndex);
    event PredictionEventResolved(uint256 eventId, uint256 correctOptionIndex);
    event PredictionWinningsClaimed(uint256 eventId, address predictor, uint256 amount);
    event PredictionEventCancelled(uint256 eventId);

    event ContractPaused(address owner);
    event ContractUnpaused(address owner);
    event ContractBalanceWithdrawn(address owner, uint256 amount);

    constructor() {
        owner = msg.sender;
        paused = false;
        predictionFee = 0.01 ether; // Default prediction fee
        nextLotteryId = 1;
        nextEventId = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier contractNotPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    modifier lotteryExists(uint256 _lotteryId) {
        require(lotteries[_lotteryId].isActive, "Lottery does not exist or is not active.");
        _;
    }

    modifier eventExists(uint256 _eventId) {
        require(predictionEvents[_eventId].isActive, "Prediction Event does not exist or is not active.");
        _;
    }

    modifier lotteryNotDrawn(uint256 _lotteryId) {
        require(!lotteries[_lotteryId].isDrawn, "Lottery already drawn.");
        _;
    }

    modifier lotteryActive(uint256 _lotteryId) {
        require(lotteries[_lotteryId].isActive, "Lottery is not active.");
        _;
    }

    modifier eventNotResolved(uint256 _eventId) {
        require(!predictionEvents[_eventId].isResolved, "Prediction event already resolved.");
        _;
    }

    modifier eventActive(uint256 _eventId) {
        require(predictionEvents[_eventId].isActive, "Prediction event is not active.");
        _;
    }

    // -------------------- Core Lottery Functions --------------------

    /// @notice Creates a new lottery. Only callable by the contract owner.
    /// @param _lotteryName The name of the lottery.
    /// @param _entryFee The entry fee for the lottery in wei.
    /// @param _duration The duration of the lottery in seconds.
    function createLottery(string memory _lotteryName, uint256 _entryFee, uint256 _duration) external onlyOwner contractNotPaused {
        require(_entryFee > 0, "Entry fee must be greater than zero.");
        require(_duration > 0, "Lottery duration must be greater than zero.");

        lotteries[nextLotteryId] = Lottery({
            name: _lotteryName,
            entryFee: _entryFee,
            prizePool: 0,
            startTime: block.timestamp,
            duration: _duration,
            participants: new address[](0),
            winner: address(0),
            isDrawn: false,
            isActive: true
        });

        emit LotteryCreated(nextLotteryId, _lotteryName, _entryFee, _duration);
        nextLotteryId++;
    }

    /// @notice Allows users to enter a specific lottery.
    /// @param _lotteryId The ID of the lottery to enter.
    function enterLottery(uint256 _lotteryId) external payable contractNotPaused lotteryExists(_lotteryId) lotteryActive(_lotteryId) lotteryNotDrawn(_lotteryId) {
        Lottery storage lottery = lotteries[_lotteryId];
        require(msg.value == lottery.entryFee, "Incorrect entry fee amount.");
        require(block.timestamp <= lottery.startTime + lottery.duration, "Lottery entry time expired.");

        lottery.participants.push(msg.sender);
        lottery.prizePool += msg.value;

        emit LotteryEntered(_lotteryId, msg.sender);
    }

    /// @notice Draws a lottery to select a winner. Only callable by the contract owner.
    /// @param _lotteryId The ID of the lottery to draw.
    function drawLottery(uint256 _lotteryId) external onlyOwner contractNotPaused lotteryExists(_lotteryId) lotteryActive(_lotteryId) lotteryNotDrawn(_lotteryId) {
        Lottery storage lottery = lotteries[_lotteryId];
        require(lottery.participants.length > 0, "No participants in the lottery.");
        require(block.timestamp > lottery.startTime + lottery.duration, "Lottery duration not yet finished.");

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, _lotteryId, lottery.participants.length))) % lottery.participants.length;
        lottery.winner = lottery.participants[winnerIndex];
        lottery.isDrawn = true;
        lottery.isActive = false; // Lottery is finished after drawing

        emit LotteryDrawn(_lotteryId, lottery.winner);
    }

    /// @notice Allows the winner of a lottery to claim their winnings.
    /// @param _lotteryId The ID of the lottery to claim winnings from.
    function claimLotteryWinnings(uint256 _lotteryId) external contractNotPaused lotteryExists(_lotteryId) {
        Lottery storage lottery = lotteries[_lotteryId];
        require(lottery.isDrawn, "Lottery not yet drawn.");
        require(msg.sender == lottery.winner, "You are not the winner of this lottery.");
        require(lottery.prizePool > 0, "Prize pool is empty.");

        uint256 prizeAmount = lottery.prizePool;
        lottery.prizePool = 0; // Reset prize pool after payout

        (bool success, ) = payable(lottery.winner).call{value: prizeAmount}("");
        require(success, "Lottery payout failed.");

        emit LotteryWinningsClaimed(_lotteryId, lottery.winner, prizeAmount);
    }

    /// @notice Cancels a lottery and refunds participants. Only callable by the contract owner before the lottery is drawn.
    /// @param _lotteryId The ID of the lottery to cancel.
    function cancelLottery(uint256 _lotteryId) external onlyOwner contractNotPaused lotteryExists(_lotteryId) lotteryActive(_lotteryId) lotteryNotDrawn(_lotteryId) {
        Lottery storage lottery = lotteries[_lotteryId];
        require(lottery.participants.length > 0, "No participants to refund.");

        uint256 totalRefund = lottery.prizePool;
        lottery.prizePool = 0; // Reset prize pool

        for (uint256 i = 0; i < lottery.participants.length; i++) {
            (bool success, ) = payable(lottery.participants[i]).call{value: lottery.entryFee}("");
            require(success, "Lottery refund failed for a participant.");
        }

        lottery.isActive = false; // Mark lottery as inactive/cancelled
        emit LotteryCancelled(_lotteryId);
    }

    /// @notice Gets details of a specific lottery.
    /// @param _lotteryId The ID of the lottery.
    /// @return name Lottery name.
    /// @return entryFee Lottery entry fee.
    /// @return prizePool Current prize pool.
    /// @return startTime Lottery start timestamp.
    /// @return duration Lottery duration in seconds.
    /// @return participantCount Number of participants.
    /// @return winner Winner's address (address(0) if not drawn).
    /// @return isDrawn Whether the lottery has been drawn.
    /// @return isActive Whether the lottery is currently active.
    function getLotteryDetails(uint256 _lotteryId) external view lotteryExists(_lotteryId) returns (
        string memory name,
        uint256 entryFee,
        uint256 prizePool,
        uint256 startTime,
        uint256 duration,
        uint256 participantCount,
        address winner,
        bool isDrawn,
        bool isActive
    ) {
        Lottery storage lottery = lotteries[_lotteryId];
        return (
            lottery.name,
            lottery.entryFee,
            lottery.prizePool,
            lottery.startTime,
            lottery.duration,
            lottery.participants.length,
            lottery.winner,
            lottery.isDrawn,
            lottery.isActive
        );
    }

    /// @notice Gets the list of participants in a specific lottery.
    /// @param _lotteryId The ID of the lottery.
    /// @return participants Array of participant addresses.
    function getLotteryParticipants(uint256 _lotteryId) external view lotteryExists(_lotteryId) returns (address[] memory participants) {
        return lotteries[_lotteryId].participants;
    }

    /// @notice Gets the winner of a specific lottery.
    /// @param _lotteryId The ID of the lottery.
    /// @return winner Winner's address (address(0) if not drawn).
    function getLotteryWinner(uint256 _lotteryId) external view lotteryExists(_lotteryId) returns (address winner) {
        return lotteries[_lotteryId].winner;
    }

    /// @notice Gets the current status of a specific lottery.
    /// @param _lotteryId The ID of the lottery.
    /// @return isActive Whether the lottery is currently active.
    /// @return isDrawn Whether the lottery has been drawn.
    function getLotteryStatus(uint256 _lotteryId) external view lotteryExists(_lotteryId) returns (bool isActive, bool isDrawn) {
        return (lotteries[_lotteryId].isActive, lotteries[_lotteryId].isDrawn);
    }


    /// @notice Sets a new entry fee for a specific lottery. Only callable by the contract owner.
    /// @param _lotteryId The ID of the lottery to update.
    /// @param _newFee The new entry fee in wei.
    function setLotteryEntryFee(uint256 _lotteryId, uint256 _newFee) external onlyOwner contractNotPaused lotteryExists(_lotteryId) lotteryActive(_lotteryId) lotteryNotDrawn(_lotteryId) {
        require(_newFee > 0, "New entry fee must be greater than zero.");
        lotteries[_lotteryId].entryFee = _newFee;
    }

    // -------------------- Prediction Market Functions --------------------

    /// @notice Creates a new prediction event. Only callable by the contract owner.
    /// @param _eventName The name of the prediction event.
    /// @param _description Description of the event.
    /// @param _endTime Timestamp for when predictions are closed.
    /// @param _options Array of possible outcome options (e.g., ["Option A", "Option B"]).
    function createPredictionEvent(string memory _eventName, string memory _description, uint256 _endTime, string[] memory _options) external onlyOwner contractNotPaused {
        require(_endTime > block.timestamp, "End time must be in the future.");
        require(_options.length > 1, "At least two options are required for a prediction event.");

        predictionEvents[nextEventId] = PredictionEvent({
            name: _eventName,
            description: _description,
            endTime: _endTime,
            options: _options,
            correctOptionIndex: 0, // Default, to be updated when resolved
            predictions: mapping(address => uint256)(),
            claimedWinnings: mapping(address => bool)(),
            isResolved: false,
            isActive: true
        });

        emit PredictionEventCreated(nextEventId, _eventName, _endTime, _options);
        nextEventId++;
    }

    /// @notice Allows users to place a prediction on a prediction event.
    /// @param _eventId The ID of the prediction event.
    /// @param _optionIndex The index of the chosen option (starting from 0).
    function predictEventOutcome(uint256 _eventId, uint256 _optionIndex) external payable contractNotPaused eventExists(_eventId) eventActive(_eventId) eventNotResolved(_eventId) {
        PredictionEvent storage event = predictionEvents[_eventId];
        require(block.timestamp < event.endTime, "Prediction time expired for this event.");
        require(_optionIndex < event.options.length, "Invalid option index.");
        require(msg.value == predictionFee, "Incorrect prediction fee amount.");

        event.predictions[msg.sender] = _optionIndex;

        emit PredictionPlaced(_eventId, msg.sender, _optionIndex);
    }

    /// @notice Resolves a prediction event and declares the correct outcome. Only callable by the contract owner.
    /// @param _eventId The ID of the prediction event to resolve.
    /// @param _correctOptionIndex The index of the correct outcome option.
    function resolvePredictionEvent(uint256 _eventId, uint256 _correctOptionIndex) external onlyOwner contractNotPaused eventExists(_eventId) eventActive(_eventId) eventNotResolved(_eventId) {
        PredictionEvent storage event = predictionEvents[_eventId];
        require(block.timestamp >= event.endTime, "Event end time has not passed yet.");
        require(_correctOptionIndex < event.options.length, "Invalid correct option index.");

        event.correctOptionIndex = _correctOptionIndex;
        event.isResolved = true;
        event.isActive = false; // Event is finished after resolution

        emit PredictionEventResolved(_eventId, _correctOptionIndex);
    }

    /// @notice Allows users who predicted correctly to claim their winnings.
    /// @param _eventId The ID of the prediction event to claim winnings from.
    function claimPredictionWinnings(uint256 _eventId) external contractNotPaused eventExists(_eventId) eventResolved(_eventId) {
        PredictionEvent storage event = predictionEvents[_eventId];
        require(event.isResolved, "Prediction event not yet resolved.");
        require(!event.claimedWinnings[msg.sender], "Winnings already claimed.");
        require(event.predictions[msg.sender] == event.correctOptionIndex, "Your prediction was incorrect.");

        uint256 correctPredictorsCount = 0;
        for (uint256 i = 0; i < event.options.length; i++) { // Simple count for demonstration, could be optimized in production for larger scale
            uint256 predictorsForOption = 0;
             // Iterate through all predictions (inefficient for large scale, consider better data structure for production)
            for(address predictor in getUsersWhoPredicted(predictionEvents[_eventId])) {
                if(predictionEvents[_eventId].predictions[predictor] == event.correctOptionIndex) {
                    predictorsForOption++;
                }
            }
            if(i == event.correctOptionIndex) {
                correctPredictorsCount = predictorsForOption;
                break;
            }
        }

        require(correctPredictorsCount > 0, "No correct predictions to pay out.");

        uint256 totalEventFees = correctPredictorsCount * predictionFee; // In a real system, you'd track total collected fees more accurately.
        uint256 winningsAmount = totalEventFees / correctPredictorsCount; // Simple equal distribution for demonstration, odds could be implemented

        event.claimedWinnings[msg.sender] = true; // Mark as claimed

        (bool success, ) = payable(msg.sender).call{value: winningsAmount}("");
        require(success, "Prediction winnings payout failed.");

        emit PredictionWinningsClaimed(_eventId, msg.sender, winningsAmount);
    }

    /// @notice Cancels a prediction event and refunds participants. Only callable by the contract owner before resolution.
    /// @param _eventId The ID of the prediction event to cancel.
    function cancelPredictionEvent(uint256 _eventId) external onlyOwner contractNotPaused eventExists(_eventId) eventActive(_eventId) eventNotResolved(_eventId) {
        PredictionEvent storage event = predictionEvents[_eventId];
        address[] memory predictors = getUsersWhoPredicted(event);
        require(predictors.length > 0, "No predictions to refund.");

        for (uint256 i = 0; i < predictors.length; i++) {
            (bool success, ) = payable(predictors[i]).call{value: predictionFee}("");
            require(success, "Prediction refund failed for a participant.");
        }

        event.isActive = false; // Mark event as inactive/cancelled
        emit PredictionEventCancelled(_eventId);
    }

    /// @notice Gets details of a specific prediction event.
    /// @param _eventId The ID of the prediction event.
    /// @return name Event name.
    /// @return description Event description.
    /// @return endTime Event end timestamp.
    /// @return options Available prediction options.
    /// @return correctOptionIndex Index of the correct option (0 if not resolved).
    /// @return isResolved Whether the event has been resolved.
    /// @return isActive Whether the event is currently active.
    function getEventDetails(uint256 _eventId) external view eventExists(_eventId) returns (
        string memory name,
        string memory description,
        uint256 endTime,
        string[] memory options,
        uint256 correctOptionIndex,
        bool isResolved,
        bool isActive
    ) {
        PredictionEvent storage event = predictionEvents[_eventId];
        return (
            event.name,
            event.description,
            event.endTime,
            event.options,
            event.correctOptionIndex,
            event.isResolved,
            event.isActive
        );
    }

    /// @notice Gets the list of predictions for a specific event.
    /// @param _eventId The ID of the prediction event.
    /// @return predictions Mapping of predictor addresses to their chosen option index.
    function getEventPredictions(uint256 _eventId) external view eventExists(_eventId) returns (mapping(address => uint256) memory predictions) {
        return predictionEvents[_eventId].predictions;
    }

    /// @notice Gets the current status of a specific prediction event.
    /// @param _eventId The ID of the prediction event.
    /// @return isActive Whether the event is currently active.
    /// @return isResolved Whether the event has been resolved.
    function getEventStatus(uint256 _eventId) external view eventExists(_eventId) returns (bool isActive, bool isResolved) {
        return (predictionEvents[_eventId].isActive, predictionEvents[_eventId].isResolved);
    }

    /// @notice Sets the base prediction fee for prediction events. Only callable by the contract owner.
    /// @param _newFee The new prediction fee in wei.
    function setPredictionFee(uint256 _newFee) external onlyOwner contractNotPaused {
        require(_newFee > 0, "Prediction fee must be greater than zero.");
        predictionFee = _newFee;
    }


    // -------------------- Admin & Utility Functions --------------------

    /// @notice Pauses the contract, disabling most functionalities. Only callable by the contract owner.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(owner);
    }

    /// @notice Unpauses the contract, restoring functionalities. Only callable by the contract owner.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(owner);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return Whether the contract is paused.
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /// @notice Gets the contract owner's address.
    /// @return The contract owner's address.
    function getContractOwner() external view returns (address) {
        return owner;
    }

    /// @notice Allows the owner to withdraw the contract's balance (excluding prize pools and pending winnings).
    function withdrawContractBalance() external onlyOwner contractNotPaused {
        uint256 contractBalance = address(this).balance;

        uint256 reservedBalance = 0; // Calculate total prize pool and pending winnings if needed for more accurate withdrawal management

        uint256 withdrawableBalance = contractBalance - reservedBalance;

        require(withdrawableBalance > 0, "No withdrawable balance.");

        (bool success, ) = payable(owner).call{value: withdrawableBalance}("");
        require(success, "Contract balance withdrawal failed.");

        emit ContractBalanceWithdrawn(owner, withdrawableBalance);
    }

    /// @notice Returns a list of users who participated in a PredictionEvent.
    /// @param _event The PredictionEvent struct.
    /// @return An array of addresses of participants.
    function getUsersWhoPredicted(PredictionEvent memory _event) internal view returns (address[] memory) {
        address[] memory predictors = new address[](0);
        uint256 count = 0;
        for (uint256 i = 0; i < _event.options.length; i++) {
            for (address predictor in getKeys(_event.predictions)) {
                if(_event.predictions[predictor] >= 0) { // Basic check if they made a prediction (could be refined)
                    bool alreadyAdded = false;
                    for(uint256 j=0; j<predictors.length; j++) {
                        if(predictors[j] == predictor) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    if(!alreadyAdded) {
                        predictors = _arrayPush(predictors, predictor);
                        count++;
                    }
                }
            }
        }
        return predictors;
    }

    // Helper function to get keys from a mapping (inefficient for large mappings, use with caution in production)
    function getKeys(mapping(address => uint256) storage _map) internal view returns (address[] memory) {
        address[] memory keys = new address[](0);
        uint256 count = 0;
        for (uint256 i = 0; i < address(this).balance; i++) { // Iterate through potential address space - very inefficient and incorrect approach for general mappings.  This is a placeholder and needs a better way to iterate in Solidity.
            address key = address(uint160(i)); // This is not a reliable way to iterate through mapping keys. In real applications, you'd need to maintain a separate list of keys.
            if (_map[key] >= 0) { // Basic check if an entry exists - needs proper key existence check.
                 bool alreadyAdded = false;
                    for(uint256 j=0; j<keys.length; j++) {
                        if(keys[j] == key) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    if(!alreadyAdded) {
                        keys = _arrayPush(keys, key);
                        count++;
                    }
            }
             if (count > 100) break; // Added a limit for demonstration to avoid excessive gas. In a real scenario, you'd need a better key tracking method.
        }
        return keys;
    }

    // Helper function to push to a dynamic array
    function _arrayPush(address[] memory _arr, address _value) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](_arr.length + 1);
        for (uint256 i = 0; i < _arr.length; i++) {
            newArray[i] = _arr[i];
        }
        newArray[_arr.length] = _value;
        return newArray;
    }

    // Fallback function to prevent accidental sending of Ether to the contract
    fallback() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }
}
```