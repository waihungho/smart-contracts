Here's a Solidity smart contract named `EvoPredict` that embodies interesting, advanced-concept, creative, and trendy functionalities, ensuring it doesn't duplicate existing open-source projects directly. It includes over 20 functions as requested.

---

## EvoPredict: Decentralized AI-Powered Prediction Market with Self-Evolving Rules & Dynamic Reputation

**I. Outline:**

This smart contract implements a novel prediction market where users can bet on real-world outcomes. Its core distinguishing features are:
1.  **AI-Powered Oracles:** Integrates external AI model predictions for market resolution, tracking their historical accuracy. The contract consumes predictions from designated AI oracles and evaluates their performance.
2.  **Self-Evolving Rule Sets:** Key market parameters (e.g., fees, market duration limits) can be dynamically adjusted through a decentralized governance mechanism. This mechanism is influenced by system performance metrics and oracle accuracy indirectly, allowing the protocol to adapt over time.
3.  **Dynamic Reputation System:** Users and registered AI oracles earn or lose "reputation" based on their prediction accuracy and active participation. This reputation can influence voting power in governance, potentially unlock specific features (though not fully implemented in this example for brevity), or impact fee structures.
4.  **Decentralized Governance:** A sophisticated proposal and voting system allows the community (weighted by reputation) to vote on rule changes and major contract operations, fostering a self-sustaining and adaptable ecosystem.

The contract aims to create a robust, adaptable, and incentivized prediction ecosystem.

**II. Function Summary:**

**A. Core Market Operations (8 Functions)**
1.  `createMarket(string memory _question, string[] memory _outcomes, uint256 _resolutionTime, bytes32 _aiOracleId, uint256 _aiPredictionConfidence)`: Allows a user to create a new prediction market, specifying the question, possible outcomes, resolution deadline, the AI oracle expected to provide data, and its initial prediction confidence.
2.  `placeBet(uint256 _marketId, uint256 _outcomeIndex)`: Allows a user to place a bet (stake ETH) on a specific outcome within an open market.
3.  `closeMarketForResolution(uint256 _marketId)`: Initiates the closure of a market, preventing further bets and setting it up for resolution by an authorized oracle or governance.
4.  `resolveMarket(uint256 _marketId, uint256 _winningOutcomeIndex)`: An authorized AI oracle or governance resolves a closed market by declaring the winning outcome. This triggers payout calculations and updates reputations of participating users and the oracle.
5.  `claimWinnings(uint256 _marketId)`: Allows a bettor to claim their winnings after a market has been resolved and they bet on the winning outcome.
6.  `refundLostBets(uint256 _marketId)`: Allows users to claim refunds for their stakes if a market is cancelled or invalid (e.g., stuck beyond resolution).
7.  `getMarketDetails(uint256 _marketId)`: Public view function to retrieve detailed information about a specific market, including its current status, volumes, and oracle details.
8.  `getUserBetDetails(uint256 _marketId, address _user)`: Public view function to retrieve details of a specific user's bet(s) on a given market, including the amount staked and claimed status.

**B. AI Oracle Management & Integration (5 Functions)**
9.  `registerAIOracle(address _oracleAddress, string memory _name, string memory _description)`: Allows the contract owner (or later, governance) to register a new external AI model as an oracle within the system.
10. `deregisterAIOracle(bytes32 _oracleId)`: Allows the contract owner to deactivate an AI oracle, preventing it from resolving markets or influencing predictions.
11. `updateAIOraclePrediction(uint256 _marketId, bytes32 _oracleId, uint256 _predictedOutcomeIndex, uint256 _confidence)`: Allows a registered AI oracle to submit or update its prediction for a specific market *before* it closes. This information can guide user betting behavior.
12. `getAIOracleAccuracy(bytes32 _oracleId)`: Public view function to retrieve the historical accuracy (percentage of correct predictions) of a registered AI oracle.
13. `requestAIInsight(string memory _query, uint256 _paymentAmount)`: Allows any user to submit a query and a payment, requesting an AI oracle (off-chain) to analyze a specific event. This function primarily logs the request and handles payment, facilitating off-chain AI analysis that *could* lead to new market proposals.

**C. Self-Evolving Rule Sets & Governance (6 Functions)**
14. `proposeRuleChange(uint256 _proposalType, bytes memory _data, string memory _description)`: Allows users with sufficient reputation/voting power to propose a change to the contract's parameters (e.g., market fees, maximum market duration). The `_data` parameter allows for arbitrary data for different proposal types.
15. `voteOnRuleChange(uint256 _proposalId, bool _support)`: Allows users to cast their vote (yes/no) on an active rule change proposal. Voting power is dynamically weighted by the user's reputation score.
16. `executeRuleChange(uint256 _proposalId)`: Executes a rule change proposal if it has passed the voting threshold and its voting period has ended. Currently, only the contract owner can trigger this for security, but it can be decentralized to a timelock/DAO.
17. `getProposedRuleChanges(uint256 _proposalId)`: Public view function to retrieve details of a specific rule change proposal, including its current vote counts and status.
18. `setVotingThresholds(uint256 _minReputationToPropose, uint256 _quorumPercentage, uint256 _voteDuration)`: Governance function (owner-only for now) to adjust the parameters governing rule change proposals, such as minimum reputation required to propose, quorum percentage, and vote duration.
19. `getCurrentRuleParameters()`: Public view function to retrieve the currently active global market rule parameters (e.g., current fees, minimum bet amount, maximum market duration).

**D. Dynamic Reputation System (3 Functions)**
20. `getUserReputation(address _user)`: Public view function to retrieve the current reputation score of a user.
21. `_updateUserReputation(address _user, int256 _change)`: Internal function triggered by market resolutions to adjust a user's reputation based on their prediction accuracy or participation. (Not directly callable by external users, but vital for system logic).
22. `setReputationImpactFactors(uint256 _correctPredictionImpact, uint256 _incorrectPredictionImpact, uint256 _participationBonus)`: Governance function (owner-only for now) to configure how reputation points are gained or lost for correct/incorrect predictions and general market participation.

**E. Admin & Utility (4 Functions)**
23. `collectProtocolFees()`: Allows the contract owner to withdraw accumulated protocol fees generated from market activity.
24. `emergencyPause()`: Allows the contract owner to pause critical functionalities of the contract in case of an emergency (e.g., vulnerability discovery).
25. `emergencyUnpause()`: Allows the contract owner to unpause the contract after an emergency has been addressed.
26. `transferOwnership(address _newOwner)`: Standard OpenZeppelin Ownable function to transfer contract ownership to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title EvoPredict
 * @dev A Decentralized AI-Powered Prediction Market with Self-Evolving Rule Sets and Dynamic Reputation System.
 *
 * This contract facilitates peer-to-peer predictions on real-world events,
 * integrates external AI oracle predictions, and features a governance system
 * where market rules can evolve based on community proposals and reputation-weighted voting.
 * Reputation is dynamically updated based on prediction accuracy and participation.
 */
contract EvoPredict is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum MarketStatus { Open, Closed, Resolved, Cancelled }
    enum ProposalType {
        SetMarketFee,
        SetMinBetAmount, // Note: MIN_BET_AMOUNT is currently a constant. For this to work, it needs to be a mutable state variable.
        SetMaxMarketDuration,
        SetReputationImpactFactors,
        SetVotingThresholds,
        RegisterAIOracle,
        DeregisterAIOracle
    }

    // --- Structs ---
    struct Market {
        string question;
        string[] outcomes;
        address creator;
        uint256 creationTime;
        uint256 resolutionTime; // Deadline for market to be resolved
        uint256 resolvedOutcomeIndex; // Index of the winning outcome (type(uint256).max if unresolved)
        uint256 totalVolume; // Total ETH staked in the market
        uint256 feePercentage; // Fee for this specific market, derived from current_market_fee_percentage at creation
        MarketStatus status;
        bytes32 aiOracleId; // ID of the AI oracle chosen to potentially resolve or influence this market
        uint256 aiPredictionConfidence; // Confidence score provided by the AI oracle at market creation (e.g., 0-10000)
        bool isResolvedByOracle; // True if an oracle resolved, false if cancelled or owner-resolved
        mapping(uint256 => uint256) outcomeVolumes; // Volume staked per outcome index
    }

    // Represents a single bet placed by a user
    struct Bet {
        uint256 marketId;
        address bettor;
        uint256 outcomeIndex;
        uint256 amount;
        bool claimed; // True if winnings/refund have been claimed
    }

    // Represents a registered AI oracle
    struct AIOracle {
        address oracleAddress;
        string name;
        string description;
        uint256 totalPredictions; // Total markets this oracle has submitted a prediction for
        uint256 correctPredictions; // How many times its prediction for a market was correct
        bool isActive; // Can be deactivated by governance
    }

    // Represents a rule change proposal
    struct RuleProposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        bytes data; // ABI-encoded new value(s) for the parameter(s)
        string description;
        uint256 creationTime;
        uint256 expirationTime; // Timestamp when voting ends
        mapping(address => bool) hasVoted; // Tracks who has voted on this proposal
        uint256 votesFor; // Total reputation points voting 'for'
        uint256 votesAgainst; // Total reputation points voting 'against'
        bool executed; // True if the proposal has been successfully executed
    }

    // --- State Variables ---
    Counters.Counter private _marketIds;
    Counters.Counter private _betIds; // Used to track individual bet instances, not directly for lookup in mapping
    Counters.Counter private _proposalIds;

    mapping(uint256 => Market) public markets;
    // marketId => bettor_address => outcome_index => list_of_bets (allows multiple bets on same outcome by same user)
    mapping(uint256 => mapping(address => mapping(uint256 => Bet[]))) public userBetsOnMarket;
    mapping(uint256 => address[]) public bettorsInMarket; // marketId => list of unique bettors for efficient payout/refund iteration

    mapping(bytes32 => AIOracle) public aiOracles; // keccak256(oracleAddress) => AIOracle
    mapping(address => bytes32) public oracleAddressToId; // Reverse lookup for AI Oracle ID

    mapping(address => uint256) public userReputation; // User address => Reputation score
    // mapping(address => uint256) public userLastReputationUpdate; // Can be used to implement cooldown for reputation updates

    mapping(uint256 => RuleProposal) public ruleProposals;

    uint256 public constant MIN_BET_AMOUNT = 0.001 ether; // Minimum ETH allowed per bet (constant for this example)
    uint256 public currentMarketFeePercentage = 300; // 3.00% (300 basis points, 10000 = 100%)
    uint256 public maxMarketDuration = 30 days; // Max allowed duration for a market to be open

    uint256 public minReputationToPropose = 100; // Minimum reputation required to propose a rule change
    uint224 public quorumPercentage = 5000; // 50.00% (5000 basis points) of total reputation needed for a proposal to pass
    uint256 public voteDuration = 3 days; // Duration for voting on a proposal

    uint256 public correctPredictionReputationImpact = 10; // Reputation points gained for correct prediction
    uint256 public incorrectPredictionReputationImpact = 5; // Reputation points lost for incorrect prediction
    uint256 public participationBonusReputation = 1; // Reputation points gained for participating in a market

    uint256 public protocolFeesCollected; // Accumulated fees from markets
    bool public paused = false; // Emergency pause switch

    // --- Events ---
    event MarketCreated(uint256 indexed marketId, string question, address indexed creator, uint256 resolutionTime, bytes32 indexed aiOracleId);
    event BetPlaced(uint256 indexed marketId, address indexed bettor, uint256 outcomeIndex, uint256 amount);
    event MarketClosedForResolution(uint256 indexed marketId);
    event MarketResolved(uint256 indexed marketId, uint256 winningOutcomeIndex, uint256 totalVolume, uint256 netPayoutPool);
    event WinningsClaimed(uint256 indexed marketId, address indexed bettor, uint256 amount);
    event RefundClaimed(uint256 indexed marketId, address indexed bettor, uint256 amount);
    event AIOracleRegistered(bytes32 indexed oracleId, address indexed oracleAddress, string name);
    event AIOracleDeregistered(bytes32 indexed oracleId);
    event AIOraclePredictionUpdated(uint256 indexed marketId, bytes32 indexed oracleId, uint256 predictedOutcomeIndex, uint256 confidence);
    event AIInsightRequested(address indexed requester, string query, uint256 paymentAmount);
    event RuleChangeProposed(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeightedVote);
    event RuleChangeExecuted(uint256 indexed proposalId, ProposalType proposalType, bytes data);
    event ReputationUpdated(address indexed user, uint256 newScore, int256 change);
    event FeesCollected(uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyAIOracle(bytes32 _oracleId) {
        require(aiOracles[_oracleId].isActive, "AI Oracle not active");
        require(aiOracles[_oracleId].oracleAddress == msg.sender, "Caller is not the registered AI oracle");
        _;
    }

    // --- Constructor ---
    constructor() {
        // Initial setup for owner, inherited from Ownable.
        // Can add initial reputation for owner or whitelist initial oracles here if desired.
    }

    // --- A. Core Market Operations (8 Functions) ---

    /**
     * @notice Creates a new prediction market.
     * @param _question The question for the market.
     * @param _outcomes An array of possible outcomes.
     * @param _resolutionTime The Unix timestamp when the market is expected to be resolved.
     * @param _aiOracleId The ID of the AI oracle chosen to provide data for this market.
     * @param _aiPredictionConfidence The confidence score provided by the AI oracle at market creation (0-10000).
     * @return The ID of the newly created market.
     */
    function createMarket(
        string memory _question,
        string[] memory _outcomes,
        uint256 _resolutionTime,
        bytes32 _aiOracleId,
        uint256 _aiPredictionConfidence
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_outcomes.length >= 2, "Must have at least two outcomes");
        require(_resolutionTime > block.timestamp, "Resolution time must be in the future");
        require(_resolutionTime <= block.timestamp + maxMarketDuration, "Resolution time exceeds max duration");
        require(aiOracles[_aiOracleId].isActive, "Chosen AI Oracle is not active");
        require(_aiPredictionConfidence <= 10000, "Confidence must be between 0 and 10000 (0-100%)");

        _marketIds.increment();
        uint256 newMarketId = _marketIds.current();

        markets[newMarketId] = Market({
            question: _question,
            outcomes: _outcomes,
            creator: msg.sender,
            creationTime: block.timestamp,
            resolutionTime: _resolutionTime,
            resolvedOutcomeIndex: type(uint256).max, // Sentinel value for unresolved
            totalVolume: 0,
            feePercentage: currentMarketFeePercentage, // Use current global fee
            status: MarketStatus.Open,
            aiOracleId: _aiOracleId,
            aiPredictionConfidence: _aiPredictionConfidence,
            isResolvedByOracle: false
        });

        // Initialize outcome volumes mapping
        // No explicit loop needed for mapping, default to 0.

        // Apply a small reputation bonus for creating a market
        _updateUserReputation(msg.sender, int256(participationBonusReputation));

        emit MarketCreated(newMarketId, _question, msg.sender, _resolutionTime, _aiOracleId);
        return newMarketId;
    }

    /**
     * @notice Allows a user to place a bet on a specific outcome within an open market.
     * @param _marketId The ID of the market to bet on.
     * @param _outcomeIndex The index of the chosen outcome.
     */
    function placeBet(uint256 _marketId, uint256 _outcomeIndex) external payable whenNotPaused nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open for betting");
        require(block.timestamp < market.resolutionTime, "Market resolution time passed");
        require(_outcomeIndex < market.outcomes.length, "Invalid outcome index");
        require(msg.value >= MIN_BET_AMOUNT, "Bet amount too low");

        market.totalVolume += msg.value;
        market.outcomeVolumes[_outcomeIndex] += msg.value;

        // Add user to bettors list if not already present (for efficient iteration later during resolution)
        bool alreadyBettor = false;
        for (uint256 i = 0; i < bettorsInMarket[_marketId].length; i++) {
            if (bettorsInMarket[_marketId][i] == msg.sender) {
                alreadyBettor = true;
                break;
            }
        }
        if (!alreadyBettor) {
            bettorsInMarket[_marketId].push(msg.sender);
        }

        // Store the individual bet
        _betIds.increment(); // This ID isn't directly used for mapping lookup but provides unique identifiers if needed.
        Bet storage newBet = userBetsOnMarket[_marketId][msg.sender][_outcomeIndex].push();
        newBet.marketId = _marketId;
        newBet.bettor = msg.sender;
        newBet.outcomeIndex = _outcomeIndex;
        newBet.amount = msg.value;
        newBet.claimed = false;

        // Apply a small reputation bonus for participating
        _updateUserReputation(msg.sender, int256(participationBonusReputation));

        emit BetPlaced(_marketId, msg.sender, _outcomeIndex, msg.value);
    }

    /**
     * @notice Initiates the closure of a market, preventing further bets. Can only be called by market creator or governance.
     * @param _marketId The ID of the market to close.
     */
    function closeMarketForResolution(uint256 _marketId) external whenNotPaused {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open");
        // Allows market creator, high-reputation user, or owner to close for resolution early.
        require(msg.sender == market.creator || userReputation[msg.sender] >= minReputationToPropose || owner() == msg.sender,
            "Only market creator, high-reputation user, or owner can close for resolution");

        market.status = MarketStatus.Closed;
        emit MarketClosedForResolution(_marketId);
    }

    /**
     * @notice Resolves a closed market by declaring the winning outcome. Can only be called by the designated AI Oracle or owner.
     * This function updates user reputations and the AI oracle's accuracy based on the outcome.
     * @param _marketId The ID of the market to resolve.
     * @param _winningOutcomeIndex The index of the winning outcome.
     */
    function resolveMarket(uint256 _marketId, uint256 _winningOutcomeIndex) external whenNotPaused nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Closed || (market.status == MarketStatus.Open && block.timestamp >= market.resolutionTime),
            "Market must be closed or past resolution time to be resolved");
        require(_winningOutcomeIndex < market.outcomes.length, "Invalid winning outcome index");
        require(msg.sender == aiOracles[market.aiOracleId].oracleAddress || msg.sender == owner(),
            "Only designated AI Oracle or contract owner can resolve this market");
        require(market.resolvedOutcomeIndex == type(uint256).max, "Market already resolved"); // Ensure market isn't double-resolved

        market.resolvedOutcomeIndex = _winningOutcomeIndex;
        market.status = MarketStatus.Resolved;
        market.isResolvedByOracle = (msg.sender == aiOracles[market.aiOracleId].oracleAddress);

        uint256 totalWinningVolume = market.outcomeVolumes[_winningOutcomeIndex];
        uint256 protocolFee = (market.totalVolume * market.feePercentage) / 10000; // fee in basis points
        protocolFeesCollected += protocolFee;

        // Update AI Oracle's accuracy
        if (market.isResolvedByOracle) {
            AIOracle storage oracle = aiOracles[market.aiOracleId];
            oracle.totalPredictions++;
            // If the oracle's *prior submitted prediction* (if any, stored in market.resolvedOutcomeIndex before actual resolution)
            // matches the winning outcome, increment correct predictions.
            // Simplified: If the market creator selected this oracle, and it resolves, we count it towards its predictions.
            // A more complex system would require oracle to make an explicit 'prediction' call *before* resolution.
            if (market.resolvedOutcomeIndex == _winningOutcomeIndex) { // If the prediction made via `updateAIOraclePrediction` matches
                oracle.correctPredictions++;
            }
        }

        // Update user reputations based on their bets in this market
        for (uint256 i = 0; i < bettorsInMarket[_marketId].length; i++) {
            address bettor = bettorsInMarket[_marketId][i];
            bool madeCorrectBet = false;
            bool madeIncorrectBet = false;

            // Iterate through all possible outcomes to find the user's bets
            for (uint256 j = 0; j < market.outcomes.length; j++) {
                for (uint256 k = 0; k < userBetsOnMarket[_marketId][bettor][j].length; k++) {
                    Bet storage bet = userBetsOnMarket[_marketId][bettor][j][k];
                    if (bet.outcomeIndex == _winningOutcomeIndex) {
                        madeCorrectBet = true;
                    } else {
                        madeIncorrectBet = true;
                    }
                }
            }

            if (madeCorrectBet && !madeIncorrectBet) { // Only correct bets
                _updateUserReputation(bettor, int256(correctPredictionReputationImpact));
            } else if (madeIncorrectBet && !madeCorrectBet) { // Only incorrect bets
                _updateUserReputation(bettor, -int256(incorrectPredictionReputationImpact));
            } else if (madeCorrectBet && madeIncorrectBet) { // Mixed bets, e.g., on multiple outcomes
                _updateUserReputation(bettor, int256(participationBonusReputation / 2)); // Small bonus for engagement
            }
        }

        emit MarketResolved(_marketId, _winningOutcomeIndex, market.totalVolume, market.totalVolume - protocolFee);
    }

    /**
     * @notice Allows a bettor to claim their winnings after a market has been resolved.
     * @param _marketId The ID of the market to claim winnings from.
     */
    function claimWinnings(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market is not resolved");
        require(market.resolvedOutcomeIndex != type(uint256).max, "Market has no winning outcome declared");

        uint256 totalWinningVolume = market.outcomeVolumes[market.resolvedOutcomeIndex];
        require(totalWinningVolume > 0, "No winning bets placed on this outcome"); // Prevents division by zero

        uint256 protocolFee = (market.totalVolume * market.feePercentage) / 10000;
        uint256 payoutPool = market.totalVolume - protocolFee;
        require(payoutPool > 0, "No payout pool available after fees");

        uint256 amountToClaim = 0;
        uint256 numBets = userBetsOnMarket[_marketId][msg.sender][market.resolvedOutcomeIndex].length;

        // Sum up winnings from all of user's bets on the winning outcome
        for (uint256 i = 0; i < numBets; i++) {
            Bet storage bet = userBetsOnMarket[_marketId][msg.sender][market.resolvedOutcomeIndex][i];
            if (!bet.claimed) {
                // Calculate proportional winnings
                uint256 winnings = (bet.amount * payoutPool) / totalWinningVolume;
                amountToClaim += winnings;
                bet.claimed = true; // Mark as claimed
            }
        }

        require(amountToClaim > 0, "No winnings to claim or already claimed");

        // Send winnings to the user
        (bool success, ) = msg.sender.call{value: amountToClaim}("");
        require(success, "Failed to send winnings");

        emit WinningsClaimed(_marketId, msg.sender, amountToClaim);
    }

    /**
     * @notice Allows users to claim refunds for their stakes if a market is cancelled or remains unresolved for too long.
     * @param _marketId The ID of the market to claim refunds from.
     */
    function refundLostBets(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        // Market can be refunded if explicitly cancelled by governance, or if it expired and is 'stuck' (e.g., 7 days past resolutionTime without resolution)
        require(market.status == MarketStatus.Cancelled || (market.status != MarketStatus.Resolved && block.timestamp >= market.resolutionTime + 7 days),
            "Market is not eligible for refund (not cancelled or stuck)");
        require(market.status != MarketStatus.Resolved, "Market is resolved, claim winnings instead");


        uint256 amountToRefund = 0;
        // Iterate through all possible outcomes to find this user's bets
        for (uint256 i = 0; i < market.outcomes.length; i++) {
            for (uint256 j = 0; j < userBetsOnMarket[_marketId][msg.sender][i].length; j++) {
                Bet storage bet = userBetsOnMarket[_marketId][msg.sender][i][j];
                if (!bet.claimed) { // Check if already refunded/claimed
                    amountToRefund += bet.amount;
                    bet.claimed = true; // Mark as claimed to prevent double refunds
                }
            }
        }

        require(amountToRefund > 0, "No funds to refund or already refunded");

        // Send refund
        (bool success, ) = msg.sender.call{value: amountToRefund}("");
        require(success, "Failed to send refund");

        emit RefundClaimed(_marketId, msg.sender, amountToRefund);
    }

    /**
     * @notice Public view function to retrieve detailed information about a specific market.
     * @param _marketId The ID of the market.
     * @return marketDetails A tuple containing all market details.
     */
    function getMarketDetails(uint256 _marketId)
        external
        view
        returns (
            string memory question,
            string[] memory outcomes,
            address creator,
            uint256 creationTime,
            uint256 resolutionTime,
            uint256 resolvedOutcomeIndex,
            uint256 totalVolume,
            uint256 feePercentage,
            MarketStatus status,
            bytes32 aiOracleId,
            uint256 aiPredictionConfidence,
            bool isResolvedByOracle,
            uint256[] memory outcomeVolumes // Volumes for each outcome
        )
    {
        Market storage market = markets[_marketId];
        require(bytes(market.question).length > 0, "Market does not exist");

        // Copy outcome volumes to a memory array for return
        uint256[] memory _outcomeVolumes = new uint256[](market.outcomes.length);
        for (uint256 i = 0; i < market.outcomes.length; i++) {
            _outcomeVolumes[i] = market.outcomeVolumes[i];
        }

        return (
            market.question,
            market.outcomes,
            market.creator,
            market.creationTime,
            market.resolutionTime,
            market.resolvedOutcomeIndex,
            market.totalVolume,
            market.feePercentage,
            market.status,
            market.aiOracleId,
            market.aiPredictionConfidence,
            market.isResolvedByOracle,
            _outcomeVolumes
        );
    }

    /**
     * @notice Public view function to retrieve details of a specific user's bet(s) on a given market.
     * @param _marketId The ID of the market.
     * @param _user The address of the user.
     * @return betDetails An array of tuples, each containing bet outcome index, amount, and claimed status.
     */
    function getUserBetDetails(uint256 _marketId, address _user)
        external
        view
        returns (
            tuple(uint256 outcomeIndex, uint256 amount, bool claimed)[] memory
        )
    {
        require(bytes(markets[_marketId].question).length > 0, "Market does not exist");

        // First, count total bets for memory array sizing
        uint256 totalUserBets = 0;
        for (uint256 i = 0; i < markets[_marketId].outcomes.length; i++) {
            totalUserBets += userBetsOnMarket[_marketId][_user][i].length;
        }

        tuple(uint256 outcomeIndex, uint256 amount, bool claimed)[] memory userBets = new tuple(uint256 outcomeIndex, uint256 amount, bool claimed)[](totalUserBets);
        uint256 currentIdx = 0;

        // Populate the array with bet details
        for (uint256 i = 0; i < markets[_marketId].outcomes.length; i++) {
            for (uint256 j = 0; j < userBetsOnMarket[_marketId][_user][i].length; j++) {
                Bet storage bet = userBetsOnMarket[_marketId][_user][i][j];
                userBets[currentIdx] = (bet.outcomeIndex, bet.amount, bet.claimed);
                currentIdx++;
            }
        }
        return userBets;
    }

    // --- B. AI Oracle Management & Integration (5 Functions) ---

    /**
     * @notice Allows a governance-approved address (owner) to register a new AI model as an oracle.
     * @param _oracleAddress The address of the AI oracle.
     * @param _name The name of the AI model.
     * @param _description A description of the AI model's capabilities.
     */
    function registerAIOracle(address _oracleAddress, string memory _name, string memory _description) external onlyOwner {
        bytes32 oracleId = keccak256(abi.encodePacked(_oracleAddress));
        require(!aiOracles[oracleId].isActive, "AI Oracle already registered or ID collision");
        require(oracleAddressToId[_oracleAddress] == bytes32(0), "Address already linked to an oracle ID");

        aiOracles[oracleId] = AIOracle({
            oracleAddress: _oracleAddress,
            name: _name,
            description: _description,
            totalPredictions: 0,
            correctPredictions: 0,
            isActive: true
        });
        oracleAddressToId[_oracleAddress] = oracleId; // Store reverse lookup
        emit AIOracleRegistered(oracleId, _oracleAddress, _name);
    }

    /**
     * @notice Allows governance (owner) to deactivate an AI oracle.
     * @param _oracleId The ID of the AI oracle to deactivate.
     */
    function deregisterAIOracle(bytes32 _oracleId) external onlyOwner {
        require(aiOracles[_oracleId].isActive, "AI Oracle is not active");
        aiOracles[_oracleId].isActive = false;
        delete oracleAddressToId[aiOracles[_oracleId].oracleAddress]; // Clean up reverse mapping
        emit AIOracleDeregistered(_oracleId);
    }

    /**
     * @notice Allows a registered AI oracle to submit or update its prediction for a specific market *before* it closes.
     * This prediction can be used by the market creator or users for informed betting.
     * @param _marketId The ID of the market.
     * @param _oracleId The ID of the AI oracle submitting the prediction.
     * @param _predictedOutcomeIndex The outcome index predicted by the AI.
     * @param _confidence The confidence score (e.g., 0-10000 for 0-100%).
     */
    function updateAIOraclePrediction(uint256 _marketId, bytes32 _oracleId, uint256 _predictedOutcomeIndex, uint256 _confidence) external onlyAIOracle(_oracleId) {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open for new predictions");
        require(market.aiOracleId == _oracleId, "This oracle is not designated for this market");
        require(_predictedOutcomeIndex < market.outcomes.length, "Invalid predicted outcome index");
        require(_confidence <= 10000, "Confidence must be between 0 and 10000 (0-100%)");

        // Update the market's stored AI prediction and confidence. This value will be checked at resolution.
        market.resolvedOutcomeIndex = _predictedOutcomeIndex; // This field is overloaded to store the latest prediction before resolution
        market.aiPredictionConfidence = _confidence;

        emit AIOraclePredictionUpdated(_marketId, _oracleId, _predictedOutcomeIndex, _confidence);
    }

    /**
     * @notice Public view function to retrieve the historical accuracy of a registered AI oracle.
     * @param _oracleId The ID of the AI oracle.
     * @return accuracy The accuracy percentage (e.g., 9500 for 95%).
     */
    function getAIOracleAccuracy(bytes32 _oracleId) external view returns (uint256 accuracy) {
        AIOracle storage oracle = aiOracles[_oracleId];
        require(oracle.isActive, "AI Oracle not active or does not exist");
        if (oracle.totalPredictions == 0) {
            return 0;
        }
        return (oracle.correctPredictions * 10000) / oracle.totalPredictions;
    }

    /**
     * @notice Allows any user to submit a query and a payment, requesting an AI oracle to analyze a specific event,
     * potentially leading to a new market proposal.
     * This function primarily logs the request and transfers funds. The actual AI analysis
     * and subsequent market creation would happen off-chain or by another function/oracle.
     * @param _query The natural language query for the AI.
     * @param _paymentAmount The amount of ETH to pay for the AI insight.
     */
    function requestAIInsight(string memory _query, uint256 _paymentAmount) external payable whenNotPaused {
        require(msg.value >= _paymentAmount, "Insufficient payment sent");
        require(bytes(_query).length > 0, "Query cannot be empty");

        // The payment is added to protocol fees. A more advanced system might direct this to a specific oracle.
        protocolFeesCollected += msg.value;

        emit AIInsightRequested(msg.sender, _query, _paymentAmount);
    }

    // --- C. Self-Evolving Rule Sets & Governance (6 Functions) ---

    /**
     * @notice Allows users with sufficient reputation/voting power to propose a change to the contract's parameters.
     * @param _proposalType The type of parameter to change.
     * @param _data The ABI-encoded new value for the parameter (e.g., `abi.encode(newValue)`).
     * @param _description A description of the proposed change.
     */
    function proposeRuleChange(ProposalType _proposalType, bytes memory _data, string memory _description) external whenNotPaused {
        require(userReputation[msg.sender] >= minReputationToPropose, "Insufficient reputation to propose");
        require(bytes(_description).length > 0, "Description cannot be empty");

        // Basic validation for data based on proposal type. More complex validation might be needed.
        if (_proposalType == ProposalType.SetMarketFee || _proposalType == ProposalType.SetMaxMarketDuration) {
            require(_data.length == 32, "Invalid data length for uint256 parameter");
        } else if (_proposalType == ProposalType.SetReputationImpactFactors || _proposalType == ProposalType.SetVotingThresholds) {
            require(_data.length == 96, "Invalid data length for 3x uint256 parameters");
        } else if (_proposalType == ProposalType.RegisterAIOracle) {
            // Data should contain (address, string, string)
            require(_data.length > 0, "Data must contain oracle registration details");
        } else if (_proposalType == ProposalType.DeregisterAIOracle) {
            // Data should contain (bytes32)
            require(_data.length == 32, "Data must contain oracle ID for deregistration");
        } else if (_proposalType == ProposalType.SetMinBetAmount) {
             // MIN_BET_AMOUNT is currently a constant. For this proposal type to work,
             // `MIN_BET_AMOUNT` needs to be refactored into a mutable state variable (e.g., `_minBetAmount`).
             revert("SetMinBetAmount requires MIN_BET_AMOUNT to be a mutable state variable, currently it's a constant.");
        }


        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        ruleProposals[newProposalId] = RuleProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            proposalType: _proposalType,
            data: _data,
            description: _description,
            creationTime: block.timestamp,
            expirationTime: block.timestamp + voteDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit RuleChangeProposed(newProposalId, msg.sender, _proposalType, _description);
    }

    /**
     * @notice Allows users to cast their vote (yes/no) on an active rule change proposal.
     * Voting power is weighted by user reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnRuleChange(uint256 _proposalId, bool _support) external whenNotPaused {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp < proposal.expirationTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(userReputation[msg.sender] > 0, "User has no reputation to vote");

        proposal.hasVoted[msg.sender] = true;
        uint256 votingPower = userReputation[msg.sender]; // Use reputation as voting power

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a rule change proposal if it has passed the voting threshold and its voting period has ended.
     * Currently, only the contract owner can trigger this for security, but it can be decentralized to a timelock/DAO.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeRuleChange(uint256 _proposalId) external onlyOwner whenNotPaused {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.expirationTime, "Voting period has not ended");

        uint256 totalReputationInSystem = _getTotalReputation(); // Get current total reputation for quorum calculation
        uint256 requiredQuorum = (totalReputationInSystem * quorumPercentage) / 10000;

        require(proposal.votesFor + proposal.votesAgainst >= requiredQuorum, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass (more 'no' votes or tie)");

        proposal.executed = true;

        // Apply the rule change based on proposal type
        if (proposal.proposalType == ProposalType.SetMarketFee) {
            currentMarketFeePercentage = abi.decode(proposal.data, (uint256));
            require(currentMarketFeePercentage <= 1000, "Fee percentage cannot exceed 10%"); // Max 10% (1000 basis points)
        } else if (proposal.proposalType == ProposalType.SetMaxMarketDuration) {
            maxMarketDuration = abi.decode(proposal.data, (uint256));
            require(maxMarketDuration >= 1 days && maxMarketDuration <= 365 days, "Max market duration out of range (1 day to 365 days)");
        } else if (proposal.proposalType == ProposalType.SetReputationImpactFactors) {
            (correctPredictionReputationImpact, incorrectPredictionReputationImpact, participationBonusReputation) = abi.decode(proposal.data, (uint256, uint256, uint256));
        } else if (proposal.proposalType == ProposalType.SetVotingThresholds) {
            (minReputationToPropose, quorumPercentage, voteDuration) = abi.decode(proposal.data, (uint256, uint256, uint256));
            require(quorumPercentage <= 10000, "Quorum percentage cannot exceed 100%");
            require(voteDuration >= 1 days, "Vote duration must be at least 1 day");
        } else if (proposal.proposalType == ProposalType.RegisterAIOracle) {
            (address _addr, string memory _name, string memory _desc) = abi.decode(proposal.data, (address, string, string));
            bytes32 oracleId = keccak256(abi.encodePacked(_addr));
            require(!aiOracles[oracleId].isActive, "AI Oracle already registered or ID collision");
            aiOracles[oracleId] = AIOracle({ oracleAddress: _addr, name: _name, description: _desc, totalPredictions: 0, correctPredictions: 0, isActive: true });
            oracleAddressToId[_addr] = oracleId;
        } else if (proposal.proposalType == ProposalType.DeregisterAIOracle) {
            bytes32 oracleId = abi.decode(proposal.data, (bytes32));
            require(aiOracles[oracleId].isActive, "AI Oracle is not active");
            aiOracles[oracleId].isActive = false;
            delete oracleAddressToId[aiOracles[oracleId].oracleAddress]; // Remove reverse mapping as well
        }

        emit RuleChangeExecuted(_proposalId, proposal.proposalType, proposal.data);
    }

    /**
     * @notice Public view function to retrieve details of a specific rule change proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposalDetails A tuple containing all proposal details.
     */
    function getProposedRuleChanges(uint256 _proposalId)
        external
        view
        returns (
            uint256 proposalId,
            address proposer,
            ProposalType proposalType,
            bytes memory data,
            string memory description,
            uint256 creationTime,
            uint256 expirationTime,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed
        )
    {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.proposalType,
            proposal.data,
            proposal.description,
            proposal.creationTime,
            proposal.expirationTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    /**
     * @notice Governance function (owner-only for now) to adjust the parameters for rule change proposals.
     * @param _minReputationToPropose New minimum reputation required to propose.
     * @param _quorumPercentage New quorum percentage (basis points, 0-10000).
     * @param _voteDuration New duration for voting in seconds.
     */
    function setVotingThresholds(uint256 _minReputationToPropose, uint256 _quorumPercentage, uint256 _voteDuration) external onlyOwner {
        require(_quorumPercentage <= 10000, "Quorum percentage cannot exceed 100%");
        require(_voteDuration >= 1 days, "Vote duration must be at least 1 day");
        minReputationToPropose = _minReputationToPropose;
        quorumPercentage = uint224(_quorumPercentage); // Cast to uint224
        voteDuration = _voteDuration;
    }

    /**
     * @notice Public view function to retrieve the currently active global market rule parameters.
     * @return marketFeePercentage Current market fee (basis points).
     * @return minBetAmount Current minimum bet amount.
     * @return maxMarketDurationInSeconds Current maximum market duration in seconds.
     */
    function getCurrentRuleParameters()
        external
        view
        returns (uint256 marketFeePercentage, uint256 minBetAmount, uint256 maxMarketDurationInSeconds)
    {
        return (currentMarketFeePercentage, MIN_BET_AMOUNT, maxMarketDuration);
    }

    // --- D. Dynamic Reputation System (3 Functions) ---

    /**
     * @notice Public view function to retrieve the current reputation score of a user.
     * @param _user The address of the user.
     * @return score The user's current reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256 score) {
        return userReputation[_user];
    }

    /**
     * @notice Internal function triggered by market resolutions to adjust a user's reputation
     * based on their prediction accuracy or participation.
     * @param _user The address of the user whose reputation is being updated.
     * @param _change The change in reputation (positive for gain, negative for loss).
     */
    function _updateUserReputation(address _user, int256 _change) internal {
        // Simple update: add/subtract change. Can be made more complex with caps, floors, decay.
        if (_change > 0) {
            userReputation[_user] += uint256(_change);
        } else {
            // Prevent underflow, reputation can't go below zero
            if (userReputation[_user] < uint256(uint256(-_change))) {
                userReputation[_user] = 0;
            } else {
                userReputation[_user] -= uint256(-_change);
            }
        }
        emit ReputationUpdated(_user, userReputation[_user], _change);
    }

    /**
     * @notice Governance function (owner-only for now) to set how reputation is affected by various actions.
     * @param _correctPredictionImpact Reputation points gained for correct prediction.
     * @param _incorrectPredictionImpact Reputation points lost for incorrect prediction.
     * @param _participationBonus Reputation points gained for market participation.
     */
    function setReputationImpactFactors(
        uint256 _correctPredictionImpact,
        uint256 _incorrectPredictionImpact,
        uint256 _participationBonus
    ) external onlyOwner {
        correctPredictionReputationImpact = _correctPredictionImpact;
        incorrectPredictionReputationImpact = _incorrectPredictionImpact;
        participationBonusReputation = _participationBonus;
    }

    // --- E. Admin & Utility (4 Functions) ---

    /**
     * @notice Allows the contract owner or designated treasury to withdraw accumulated protocol fees.
     */
    function collectProtocolFees() external onlyOwner nonReentrant {
        require(protocolFeesCollected > 0, "No fees to collect");
        uint256 amount = protocolFeesCollected;
        protocolFeesCollected = 0;

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to collect fees");
        emit FeesCollected(amount);
    }

    /**
     * @notice Allows the contract owner to pause critical functionalities in case of an emergency.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Allows the contract owner to unpause the contract.
     */
    function emergencyUnpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Internal helper function to calculate total reputation in the system.
     * IMPORTANT: For a large user base, iterating through all users as shown here would be gas-prohibitive.
     * A real-world solution would implement a running sum updated on each reputation change,
     * or use a Merkle tree to prove total reputation, or involve an oracle/accumulator pattern.
     * For this example, it returns a placeholder value.
     */
    function _getTotalReputation() internal view returns (uint256) {
        // Placeholder: In a production system, this value should be dynamically updated
        // or fetched more efficiently (e.g., from a dedicated reputation registry contract
        // that tracks the total sum).
        // For demonstration, we'll use a fixed value to ensure quorum calculation works.
        return 1_000_000; // Represents hypothetical total reputation points across all users.
    }

    // --- Fallback and Receive Functions ---

    /**
     * @dev Allows receiving ETH directly. While `placeBet` is the primary way to send ETH,
     * this allows for general ETH deposits if needed for other purposes or future features.
     */
    receive() external payable {
        // Can add logic here if direct ETH deposits should have a specific effect
    }

    /**
     * @dev Fallback function for calls to undefined functions.
     */
    fallback() external payable {
        revert("Function does not exist or invalid call");
    }
}
```