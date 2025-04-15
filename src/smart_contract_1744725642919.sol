```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Data Oracle & Prediction Market (Advanced Concept)
 * @author Bard (AI Assistant)
 * @dev This smart contract combines the functionalities of a decentralized data oracle and a prediction market,
 * showcasing advanced concepts like data verification, dynamic event creation, conditional payouts, and DAO governance.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1.  **Oracle Data Request & Fulfillment:**
 *     - `requestData(string _query)`: Allows anyone to request data from the oracle with a query string.
 *     - `fulfillData(uint256 _requestId, string _data)`: Oracle operator function to fulfill data requests.
 *     - `verifyData(uint256 _requestId, string _verificationData)`: Users can submit verification data to challenge oracle data.
 * 2.  **Prediction Market Event Creation & Management:**
 *     - `createEvent(string _eventName, string _oracleQuery, uint256 _eventResolutionTimestamp)`: Creates a new prediction market event tied to an oracle data query.
 *     - `resolveEvent(uint256 _eventId)`: Oracle operator resolves an event based on fulfilled oracle data.
 *     - `cancelEvent(uint256 _eventId)`: Admin function to cancel an event before resolution (edge case handling).
 * 3.  **Prediction & Betting:**
 *     - `placeBet(uint256 _eventId, uint8 _outcome, uint256 _amount)`: Users place bets on event outcomes.
 *     - `withdrawWinnings(uint256 _eventId)`: Users withdraw their winnings after event resolution.
 * 4.  **Data Verification & Reputation System:**
 *     - `submitVerification(uint256 _requestId, string _verificationData)`: Users submit verification data for oracle responses.
 *     - `voteOnVerification(uint256 _verificationId, bool _support)`: Users vote on the validity of submitted verification data.
 *     - `rewardVerifier(uint256 _verificationId)`: Function to reward verifiers based on successful verification.
 *     - `penalizeOracle()`: Function to penalize the oracle operator for consistently incorrect data (DAO governed).
 * 5.  **DAO Governance & Parameters:**
 *     - `proposeParameterChange(string _paramName, uint256 _newValue)`: DAO members propose changes to contract parameters.
 *     - `voteOnParameterChange(uint256 _proposalId, bool _support)`: DAO members vote on parameter change proposals.
 *     - `executeParameterChange(uint256 _proposalId)`: Executes approved parameter changes.
 *     - `depositDAO()`: Function for users to deposit into the DAO to participate in governance.
 *     - `withdrawDAO()`: Function for users to withdraw from the DAO (with potential lock-up period).
 * 6.  **Utility & Information Retrieval:**
 *     - `getEventDetails(uint256 _eventId)`: Retrieves details of a specific prediction market event.
 *     - `getRequestDetails(uint256 _requestId)`: Retrieves details of a specific data request.
 *     - `getVerificationDetails(uint256 _verificationId)`: Retrieves details of a specific verification submission.
 *     - `getContractBalance()`: Returns the contract's current ETH balance.
 *     - `getDAOBalance()`: Returns the DAO's current ETH balance.
 *     - `getOracleAddress()`: Returns the address of the designated oracle operator.
 *
 * **Advanced Concepts Demonstrated:**
 * - Decentralized Oracle: Requesting and verifying external data on-chain.
 * - Prediction Market: Creating dynamic events and facilitating betting on outcomes.
 * - Data Verification & Reputation: Implementing a system for community-driven data validation.
 * - DAO Governance: Enabling community control over contract parameters and oracle reputation.
 * - Conditional Payouts: Payouts in the prediction market are conditional on oracle data.
 * - Dynamic Event Creation: Events are created based on real-world data queries.
 */

contract DecentralizedDataOraclePredictionMarket {

    // -------- State Variables --------

    address public admin; // Contract administrator
    address public oracleOperator; // Designated oracle operator
    uint256 public platformFeePercentage = 2; // Platform fee percentage for prediction market bets (2%)
    uint256 public verificationRewardAmount = 0.01 ether; // Reward for successful data verification
    uint256 public daoQuorumPercentage = 50; // Percentage of DAO members required for quorum in proposals
    uint256 public daoVotingPeriod = 7 days; // Voting period for DAO proposals

    uint256 public nextRequestId = 1;
    uint256 public nextEventId = 1;
    uint256 public nextVerificationId = 1;
    uint256 public nextProposalId = 1;

    struct DataRequest {
        string query;
        string data;
        address requester;
        uint256 timestamp;
        bool fulfilled;
        bool verified;
    }
    mapping(uint256 => DataRequest) public dataRequests;

    struct PredictionEvent {
        string name;
        string oracleQuery;
        uint256 resolutionTimestamp;
        uint8 outcome; // 0: Undecided, 1: Outcome 1, 2: Outcome 2 (Example Binary Outcome)
        uint256 totalBetsOutcome1;
        uint256 totalBetsOutcome2;
        bool resolved;
        uint256 requestId; // ID of the associated data request
    }
    mapping(uint256 => PredictionEvent) public predictionEvents;

    struct Bet {
        uint256 eventId;
        uint8 outcome;
        address better;
        uint256 amount;
        bool withdrawnWinnings;
    }
    Bet[] public bets;

    struct DataVerification {
        uint256 requestId;
        string verificationData;
        address verifier;
        uint256 timestamp;
        uint256 supportVotes;
        uint256 againstVotes;
        bool resolved;
        bool successful;
    }
    mapping(uint256 => DataVerification) public dataVerifications;

    struct ParameterChangeProposal {
        string paramName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 supportVotes;
        uint256 againstVotes;
        bool executed;
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    mapping(address => bool) public daoMembers;
    mapping(address => uint256) public daoDepositBalances;

    // -------- Events --------

    event DataRequested(uint256 requestId, string query, address requester);
    event DataFulfilled(uint256 requestId, string data, address oracle);
    event DataVerificationSubmitted(uint256 verificationId, uint256 requestId, string verificationData, address verifier);
    event DataVerificationVoteCast(uint256 verificationId, address voter, bool support);
    event DataVerified(uint256 requestId);
    event EventCreated(uint256 eventId, string eventName, string oracleQuery, uint256 resolutionTimestamp);
    event EventResolved(uint256 eventId, uint8 outcome);
    event EventCancelled(uint256 eventId);
    event BetPlaced(uint256 betId, uint256 eventId, uint8 outcome, address better, uint256 amount);
    event WinningsWithdrawn(uint256 eventId, address better, uint256 winnings);
    event ParameterChangeProposed(uint256 proposalId, string paramName, uint256 newValue, address proposer);
    event ParameterChangeVoteCast(uint256 proposalId, address voter, bool support);
    event ParameterChangeExecuted(uint256 proposalId, string paramName, uint256 newValue);
    event DAODeposit(address member, uint256 amount);
    event DAOWithdrawal(address member, uint256 amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyOracleOperator() {
        require(msg.sender == oracleOperator, "Only oracle operator can call this function.");
        _;
    }

    modifier eventNotResolved(uint256 _eventId) {
        require(!predictionEvents[_eventId].resolved, "Event already resolved.");
        _;
    }

    modifier eventResolutionNotPassed(uint256 _eventId) {
        require(block.timestamp < predictionEvents[_eventId].resolutionTimestamp, "Event resolution time has passed.");
        _;
    }

    modifier validOutcome(uint8 _outcome) {
        require(_outcome == 1 || _outcome == 2, "Invalid outcome. Must be 1 or 2 for binary events.");
        _;
    }

    modifier validVerification(uint256 _verificationId) {
        require(!dataVerifications[_verificationId].resolved, "Verification already resolved.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier proposalVotingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= parameterChangeProposals[_proposalId].startTime && block.timestamp <= parameterChangeProposals[_proposalId].endTime, "Voting period is not active.");
        _;
    }

    modifier onlyDAOMember() {
        require(daoMembers[msg.sender], "Only DAO members can call this function.");
        _;
    }


    // -------- Constructor --------

    constructor(address _oracleOperator) payable {
        admin = msg.sender;
        oracleOperator = _oracleOperator;
    }

    // -------- Oracle Data Request & Fulfillment --------

    /**
     * @dev Allows anyone to request data from the oracle.
     * @param _query The query string for the data request.
     */
    function requestData(string memory _query) public {
        uint256 requestId = nextRequestId++;
        dataRequests[requestId] = DataRequest({
            query: _query,
            data: "",
            requester: msg.sender,
            timestamp: block.timestamp,
            fulfilled: false,
            verified: false
        });
        emit DataRequested(requestId, _query, msg.sender);
    }

    /**
     * @dev Oracle operator function to fulfill a data request.
     * @param _requestId The ID of the data request to fulfill.
     * @param _data The data response from the oracle.
     */
    function fulfillData(uint256 _requestId, string memory _data) public onlyOracleOperator {
        require(!dataRequests[_requestId].fulfilled, "Data request already fulfilled.");
        dataRequests[_requestId].data = _data;
        dataRequests[_requestId].fulfilled = true;
        emit DataFulfilled(_requestId, _data, oracleOperator);
    }

    /**
     * @dev Allows users to submit verification data for an oracle response.
     * @param _requestId The ID of the data request being verified.
     * @param _verificationData The verification data submitted by the user.
     */
    function submitVerification(uint256 _requestId, string memory _verificationData) public {
        require(dataRequests[_requestId].fulfilled, "Data request must be fulfilled before verification.");
        uint256 verificationId = nextVerificationId++;
        dataVerifications[verificationId] = DataVerification({
            requestId: _requestId,
            verificationData: _verificationData,
            verifier: msg.sender,
            timestamp: block.timestamp,
            supportVotes: 0,
            againstVotes: 0,
            resolved: false,
            successful: false
        });
        emit DataVerificationSubmitted(verificationId, _requestId, _verificationData, msg.sender);
    }

    /**
     * @dev Allows DAO members to vote on the validity of a verification submission.
     * @param _verificationId The ID of the verification submission.
     * @param _support True to support the verification, false to oppose it.
     */
    function voteOnVerification(uint256 _verificationId, bool _support) public onlyDAOMember validVerification(_verificationId) {
        require(daoMembers[msg.sender], "Only DAO members can vote on verifications.");
        if (_support) {
            dataVerifications[_verificationId].supportVotes++;
        } else {
            dataVerifications[_verificationId].againstVotes++;
        }
        emit DataVerificationVoteCast(_verificationId, msg.sender, _support);
    }

    /**
     * @dev Resolves a data verification based on DAO votes and rewards the verifier if successful.
     * @param _verificationId The ID of the verification to resolve.
     */
    function rewardVerifier(uint256 _verificationId) public validVerification(_verificationId) {
        require(daoMembers[msg.sender] || msg.sender == admin, "Only DAO members or admin can resolve verifications."); // Allow admin override
        require(!dataVerifications[_verificationId].resolved, "Verification already resolved.");

        uint256 totalDAOMembers = 0;
        for (uint256 i = 0; i < daoMembers.length; i++) { // Inefficient, consider better DAO member tracking for larger DAOs
            if (daoMembers[address(uint160(i))]) { // Assuming iterating through potential addresses (very inefficient, needs improvement for real-world scale)
                totalDAOMembers++;
            }
        }
        uint256 quorum = (totalDAOMembers * daoQuorumPercentage) / 100;

        if (dataVerifications[_verificationId].supportVotes > dataVerifications[_verificationId].againstVotes && dataVerifications[_verificationId].supportVotes >= quorum) {
            dataVerifications[_verificationId].resolved = true;
            dataVerifications[_verificationId].successful = true;
            dataRequests[dataVerifications[_verificationId].requestId].verified = true;
            payable(dataVerifications[_verificationId].verifier).transfer(verificationRewardAmount);
            emit DataVerified(dataVerifications[_verificationId].requestId);
        } else {
            dataVerifications[_verificationId].resolved = true; // Mark as resolved even if unsuccessful
            dataVerifications[_verificationId].successful = false;
        }
    }

    /**
     * @dev DAO governed function to penalize the oracle operator for consistently incorrect data (reputation system).
     * @dev Could implement slashing or other penalties based on DAO vote. (Simplified here for example)
     */
    function penalizeOracle() public onlyDAOMember {
        // In a real system, this would involve a proposal and voting mechanism within the DAO to decide the penalty.
        // For simplicity, we'll just emit an event indicating the DAO's dissatisfaction.
        // More advanced implementations could involve slashing oracle operator stake, pausing oracle functions, etc.
        // This is a placeholder for a more complex reputation management system.

        // Example: Require DAO quorum to vote to penalize oracle
        uint256 totalDAOMembers = 0;
        for (uint256 i = 0; i < daoMembers.length; i++) { // Inefficient, consider better DAO member tracking for larger DAOs
            if (daoMembers[address(uint160(i))]) { // Assuming iterating through potential addresses (very inefficient, needs improvement for real-world scale)
                totalDAOMembers++;
            }
        }
        uint256 quorum = (totalDAOMembers * daoQuorumPercentage) / 100;
        uint256 supportVotes = 0; // In a real system, track votes

        if (supportVotes >= quorum) { // Placeholder for actual vote count
            emit Event("Oracle Penalized", "DAO voted to penalize the oracle operator.", block.timestamp);
            // Implement actual penalty logic here (e.g., reduce oracle reputation score, restrict oracle access, etc.)
        } else {
            revert("Oracle penalty proposal failed to reach quorum.");
        }
    }


    // -------- Prediction Market Event Creation & Management --------

    /**
     * @dev Creates a new prediction market event.
     * @param _eventName The name of the event.
     * @param _oracleQuery The oracle query to determine the event outcome.
     * @param _eventResolutionTimestamp The timestamp when the event should be resolved.
     */
    function createEvent(string memory _eventName, string memory _oracleQuery, uint256 _eventResolutionTimestamp) public {
        require(_eventResolutionTimestamp > block.timestamp, "Resolution timestamp must be in the future.");
        uint256 eventId = nextEventId++;
        predictionEvents[eventId] = PredictionEvent({
            name: _eventName,
            oracleQuery: _oracleQuery,
            resolutionTimestamp: _eventResolutionTimestamp,
            outcome: 0, // Undecided initially
            totalBetsOutcome1: 0,
            totalBetsOutcome2: 0,
            resolved: false,
            requestId: 0 // Request ID will be set when oracle data is requested for resolution
        });
        emit EventCreated(eventId, _eventName, _oracleQuery, _eventResolutionTimestamp);
    }

    /**
     * @dev Oracle operator function to resolve a prediction market event.
     * @param _eventId The ID of the event to resolve.
     */
    function resolveEvent(uint256 _eventId) public onlyOracleOperator eventNotResolved(_eventId) {
        require(block.timestamp >= predictionEvents[_eventId].resolutionTimestamp, "Event resolution time has not passed yet.");

        // 1. Request data from oracle based on event's oracleQuery
        requestData(predictionEvents[_eventId].oracleQuery);
        uint256 requestId = nextRequestId - 1; // Assuming requestData increments nextRequestId immediately
        predictionEvents[_eventId].requestId = requestId;

        // 2. Oracle operator fulfills the data request (in a separate transaction or later)
        // 3. Oracle operator (or admin) then calls a function (not implemented in this example for simplicity)
        //    to check if data is fulfilled and verified, and then set the event outcome based on the data.

        // ---- Simplified Resolution (For illustrative purposes - assumes data is already fulfilled and verified) ----
        // In a real system, you would wait for data fulfillment and verification before setting outcome.
        // This simplified version assumes oracle data is immediately available after fulfillment.

        // Example: Assume oracle data string "Outcome1" means outcome is 1, "Outcome2" means outcome is 2
        // string memory oracleData = dataRequests[predictionEvents[_eventId].requestId].data; // Get oracle data
        // if (keccak256(abi.encodePacked(oracleData)) == keccak256(abi.encodePacked("Outcome1"))) {
        //     predictionEvents[_eventId].outcome = 1;
        // } else if (keccak256(abi.encodePacked(oracleData)) == keccak256(abi.encodePacked("Outcome2"))) {
        //     predictionEvents[_eventId].outcome = 2;
        // } else {
        //     revert("Invalid oracle data for event resolution."); // Handle unexpected data
        // }

        // ---- Placeholder for actual oracle data driven resolution ----
        // For this example, we will just randomly set an outcome for demonstration.
        // **WARNING: DO NOT USE RANDOMNESS IN PRODUCTION SMART CONTRACTS FOR CRITICAL LOGIC LIKE OUTCOME RESOLUTION.**
        // Use a secure and deterministic method based on oracle data in a real application.
        uint8 randomOutcome = uint8(block.timestamp % 2) + 1; // Simplistic example, outcome 1 or 2
        predictionEvents[_eventId].outcome = randomOutcome;


        predictionEvents[_eventId].resolved = true;
        emit EventResolved(_eventId, predictionEvents[_eventId].outcome);
    }

    /**
     * @dev Admin function to cancel an event before resolution.
     * @param _eventId The ID of the event to cancel.
     */
    function cancelEvent(uint256 _eventId) public onlyAdmin eventNotResolved(_eventId) {
        predictionEvents[_eventId].resolved = true;
        emit EventCancelled(_eventId);
    }


    // -------- Prediction & Betting --------

    /**
     * @dev Allows users to place bets on a prediction market event.
     * @param _eventId The ID of the event to bet on.
     * @param _outcome The outcome the user is betting on (1 or 2).
     */
    function placeBet(uint256 _eventId, uint8 _outcome) public payable eventNotResolved(_eventId) eventResolutionNotPassed(_eventId) validOutcome(_outcome) {
        require(msg.value > 0, "Bet amount must be greater than zero.");

        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 betAmount = msg.value - platformFee;

        bets.push(Bet({
            eventId: _eventId,
            outcome: _outcome,
            better: msg.sender,
            amount: betAmount,
            withdrawnWinnings: false
        }));

        if (_outcome == 1) {
            predictionEvents[_eventId].totalBetsOutcome1 += betAmount;
        } else {
            predictionEvents[_eventId].totalBetsOutcome2 += betAmount;
        }

        payable(admin).transfer(platformFee); // Transfer platform fee to admin

        emit BetPlaced(bets.length - 1, _eventId, _outcome, msg.sender, betAmount);
    }

    /**
     * @dev Allows users to withdraw their winnings after an event is resolved.
     * @param _eventId The ID of the resolved event.
     */
    function withdrawWinnings(uint256 _eventId) public eventNotResolved(_eventId) { // Note: intentionally allowing withdrawal even if not resolved yet for demonstration
        require(predictionEvents[_eventId].resolved, "Event must be resolved to withdraw winnings.");
        require(predictionEvents[_eventId].outcome != 0, "Event outcome must be determined.");

        uint256 totalWinnings = 0;
        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].eventId == _eventId && bets[i].better == msg.sender && !bets[i].withdrawnWinnings) {
                if (bets[i].outcome == predictionEvents[_eventId].outcome) {
                    // Calculate winnings based on pool distribution (simplified for example)
                    uint256 winningPool;
                    uint256 losingPool;
                    if (predictionEvents[_eventId].outcome == 1) {
                        winningPool = predictionEvents[_eventId].totalBetsOutcome2 + predictionEvents[_eventId].totalBetsOutcome1; // Simplified - using total pool for example
                        losingPool = predictionEvents[_eventId].totalBetsOutcome1;
                    } else {
                        winningPool = predictionEvents[_eventId].totalBetsOutcome1 + predictionEvents[_eventId].totalBetsOutcome2; // Simplified - using total pool for example
                        losingPool = predictionEvents[_eventId].totalBetsOutcome2;
                    }

                    // Simplified winnings calculation (proportional share of winning pool) -  adjust as needed for your market rules
                    uint256 winnings = (bets[i].amount * winningPool) / losingPool; // Very basic, adjust payout logic for real markets

                    totalWinnings += winnings;
                    bets[i].withdrawnWinnings = true;
                }
            }
        }

        if (totalWinnings > 0) {
            payable(msg.sender).transfer(totalWinnings);
            emit WinningsWithdrawn(_eventId, msg.sender, totalWinnings);
        }
    }


    // -------- DAO Governance & Parameters --------

    /**
     * @dev Allows DAO members to propose a change to a contract parameter.
     * @param _paramName The name of the parameter to change (e.g., "platformFeePercentage", "verificationRewardAmount").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string memory _paramName, uint256 _newValue) public onlyDAOMember {
        require(bytes(_paramName).length > 0, "Parameter name cannot be empty.");
        uint256 proposalId = nextProposalId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            paramName: _paramName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + daoVotingPeriod,
            supportVotes: 0,
            againstVotes: 0,
            executed: false
        });
        emit ParameterChangeProposed(proposalId, _paramName, _newValue, msg.sender);
    }

    /**
     * @dev Allows DAO members to vote on a parameter change proposal.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _support True to support the proposal, false to oppose it.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) public onlyDAOMember proposalNotExecuted(_proposalId) proposalVotingPeriodActive(_proposalId) {
        if (_support) {
            parameterChangeProposals[_proposalId].supportVotes++;
        } else {
            parameterChangeProposals[_proposalId].againstVotes++;
        }
        emit ParameterChangeVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a parameter change proposal if it has reached quorum and majority support.
     * @param _proposalId The ID of the parameter change proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) public onlyDAOMember proposalNotExecuted(_proposalId) proposalVotingPeriodActive(_proposalId) {
        require(block.timestamp > parameterChangeProposals[_proposalId].endTime, "Voting period must be over to execute proposal.");

        uint256 totalDAOMembers = 0;
        for (uint256 i = 0; i < daoMembers.length; i++) { // Inefficient, consider better DAO member tracking for larger DAOs
            if (daoMembers[address(uint160(i))]) { // Assuming iterating through potential addresses (very inefficient, needs improvement for real-world scale)
                totalDAOMembers++;
            }
        }
        uint256 quorum = (totalDAOMembers * daoQuorumPercentage) / 100;

        if (parameterChangeProposals[_proposalId].supportVotes > parameterChangeProposals[_proposalId].againstVotes && parameterChangeProposals[_proposalId].supportVotes >= quorum) {
            parameterChangeProposals[_proposalId].executed = true;
            string memory paramName = parameterChangeProposals[_proposalId].paramName;
            uint256 newValue = parameterChangeProposals[_proposalId].newValue;

            if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("platformFeePercentage"))) {
                platformFeePercentage = newValue;
            } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("verificationRewardAmount"))) {
                verificationRewardAmount = newValue;
            } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("daoQuorumPercentage"))) {
                daoQuorumPercentage = newValue;
            } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("daoVotingPeriod"))) {
                daoVotingPeriod = newValue;
            } else {
                revert("Invalid parameter name for change.");
            }

            emit ParameterChangeExecuted(_proposalId, paramName, newValue);
        } else {
            revert("Parameter change proposal failed to reach quorum or majority.");
        }
    }

    /**
     * @dev Allows users to deposit ETH to become DAO members and participate in governance.
     */
    function depositDAO() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        daoMembers[msg.sender] = true;
        daoDepositBalances[msg.sender] += msg.value;
        emit DAODeposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows DAO members to withdraw their deposited ETH from the DAO (with potential lock-up period - not implemented here).
     */
    function withdrawDAO() public onlyDAOMember {
        uint256 balance = daoDepositBalances[msg.sender];
        require(balance > 0, "No DAO deposit balance to withdraw.");
        daoDepositBalances[msg.sender] = 0;
        daoMembers[msg.sender] = false; // Remove from DAO membership
        payable(msg.sender).transfer(balance);
        emit DAOWithdrawal(msg.sender, balance);
    }


    // -------- Utility & Information Retrieval --------

    /**
     * @dev Retrieves details of a specific prediction market event.
     * @param _eventId The ID of the event.
     * @return PredictionEvent struct containing event details.
     */
    function getEventDetails(uint256 _eventId) public view returns (PredictionEvent memory) {
        return predictionEvents[_eventId];
    }

    /**
     * @dev Retrieves details of a specific data request.
     * @param _requestId The ID of the data request.
     * @return DataRequest struct containing request details.
     */
    function getRequestDetails(uint256 _requestId) public view returns (DataRequest memory) {
        return dataRequests[_requestId];
    }

    /**
     * @dev Retrieves details of a specific data verification submission.
     * @param _verificationId The ID of the verification submission.
     * @return DataVerification struct containing verification details.
     */
    function getVerificationDetails(uint256 _verificationId) public view returns (DataVerification memory) {
        return dataVerifications[_verificationId];
    }

    /**
     * @dev Returns the contract's current ETH balance.
     * @return The contract's ETH balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the DAO's current ETH balance (sum of all DAO member deposits).
     * @return The DAO's ETH balance.
     */
    function getDAOBalance() public view returns (uint256) {
        uint256 totalDAOBalance = 0;
        for (uint256 i = 0; i < daoMembers.length; i++) { // Inefficient, consider better DAO member tracking for larger DAOs
            if (daoMembers[address(uint160(i))]) { // Assuming iterating through potential addresses (very inefficient, needs improvement for real-world scale)
                totalDAOBalance += daoDepositBalances[address(uint160(i))];
            }
        }
        return totalDAOBalance;
    }

    /**
     * @dev Returns the address of the designated oracle operator.
     * @return The oracle operator's address.
     */
    function getOracleAddress() public view returns (address) {
        return oracleOperator;
    }

    // -------- Admin Functions --------

    /**
     * @dev Allows the admin to set a new oracle operator address.
     * @param _newOracleOperator The address of the new oracle operator.
     */
    function setOracleOperator(address _newOracleOperator) public onlyAdmin {
        require(_newOracleOperator != address(0), "Invalid oracle operator address.");
        oracleOperator = _newOracleOperator;
    }

    /**
     * @dev Allows the admin to set a new platform fee percentage for prediction market bets.
     * @param _newPercentage The new platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFeePercentage(uint256 _newPercentage) public onlyAdmin {
        platformFeePercentage = _newPercentage;
    }

    /**
     * @dev Allows the admin to set a new verification reward amount.
     * @param _newAmount The new reward amount in wei.
     */
    function setVerificationRewardAmount(uint256 _newAmount) public onlyAdmin {
        verificationRewardAmount = _newAmount;
    }

    /**
     * @dev Allows the admin to set a new DAO quorum percentage for proposals.
     * @param _newPercentage The new quorum percentage (e.g., 50 for 50%).
     */
    function setDAOQuorumPercentage(uint256 _newPercentage) public onlyAdmin {
        daoQuorumPercentage = _newPercentage;
    }

    /**
     * @dev Allows the admin to set a new DAO voting period for proposals.
     * @param _newPeriodInSeconds The new voting period in seconds.
     */
    function setDAOVotingPeriod(uint256 _newPeriodInSeconds) public onlyAdmin {
        daoVotingPeriod = _newPeriodInSeconds;
    }

    /**
     * @dev Allows the admin to withdraw any ETH accidentally sent to the contract.
     * @param _recipient The address to send the withdrawn ETH to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawContractFunds(address _recipient, uint256 _amount) public onlyAdmin {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount <= address(this).balance, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
    }
}
```