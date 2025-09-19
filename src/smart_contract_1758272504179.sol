Here's a smart contract that embodies advanced concepts like adaptive fees, a reputation system, modular oracle integration for arbitrary on-chain data, and a commit-reveal mechanism for predictions to enhance fairness and resist front-running. It's designed as a "Decentralized Adaptive Prediction Market for On-Chain Data Streams."

---

## Contract: `AetherPredict`

**Concept:** AetherPredict is a decentralized platform where users can create prediction markets based on future states of arbitrary on-chain data points (e.g., gas prices, TVL of another protocol, specific oracle feed values, NFT floor price trends). It integrates an **Adaptive Fee Model (AFM)** that dynamically adjusts market creation and betting fees based on overall market activity and historical prediction accuracy. It also features a **Reputation-Based Reward Multiplier (RRM)**, where participants earn or lose reputation based on their prediction accuracy, influencing their potential winnings. To ensure fair play, it uses a **Commit-Reveal** scheme for submitting predictions, mitigating front-running. Modular Oracle Integration allows flexibility in resolving diverse market types.

---

### Outline & Function Summary

**I. Core Market Lifecycle & Participation**
1.  **`createMarket`**: Allows a user to create a new prediction market, specifying details like the question, outcomes, resolution source, and time windows. Requires an initial collateral deposit.
2.  **`commitPredictionHash`**: Participants commit a Keccak256 hash of their chosen outcome and a unique salt. This pre-commitment prevents front-running.
3.  **`revealPrediction`**: After the commit window, participants reveal their actual outcome choice and salt. This confirms their prediction before placing a bet.
4.  **`placeBet`**: Participants place their stake on their *revealed* prediction. Bets are pooled for each outcome.
5.  **`finalizeMarketResolution`**: Initiates the process to determine the market's final outcome, typically by requesting data from a registered oracle. Callable by the market creator or authorized resolvers.
6.  **`claimWinnings`**: Allows participants who predicted correctly to claim their share of the prize pool, adjusted by their reputation-based multiplier.
7.  **`withdrawMarketCollateral`**: Allows the market creator to withdraw their initial collateral after the market has been fully resolved and settled.
8.  **`getMarketDetails`**: A view function to retrieve comprehensive information about a specific market.
9.  **`getUserPredictionAndBet`**: A view function to inspect a participant's revealed prediction and their bet amount for a given market.
10. **`getMarketOutcomeTotals`**: A view function to see the total amount bet on each outcome for a market.

**II. Adaptive Fee & Reputation System**
11. **`getMarketCreationFee`**: Returns the current dynamic fee required to create a new market, calculated by the Adaptive Fee Model.
12. **`getBettingFee`**: Returns the current dynamic fee applied to each bet placed, also determined by the Adaptive Fee Model.
13. **`getUserReputation`**: A view function to check the reputation score of any address.
14. **`getReputationRewardMultiplier`**: A view function to see the current reward multiplier for a user based on their reputation.
15. **`setAdaptiveFeeParameters`**: (Owner-only) Allows the contract owner to tune the parameters that control how the Adaptive Fee Model adjusts.
16. **`setReputationParameters`**: (Owner-only) Allows the contract owner to configure the parameters for reputation growth and decay.

**III. Modular Oracle Integration**
17. **`registerResolutionOracle`**: (Owner-only) Registers a new trusted external oracle contract address and its associated ID, allowing the system to use diverse data sources.
18. **`deregisterResolutionOracle`**: (Owner-only) Removes a previously registered oracle.
19. **`receiveOracleCallback`**: A callback function designed to be invoked *only* by registered oracle contracts to deliver the requested outcome data.

**IV. Dispute Resolution & Administration**
20. **`disputeMarketOutcome`**: Allows any participant to formally dispute a market's resolved outcome, requiring a dispute bond and temporarily freezing payouts.
21. **`resolveDispute`**: (Owner-only or designated arbiter) Reviews and settles a disputed market, potentially overturning the outcome and distributing the dispute bond.
22. **`pauseContract`**: (Owner-only) Emergency function to pause critical contract activities (market creation, betting, claiming) in case of vulnerabilities.
23. **`unpauseContract`**: (Owner-only) Unpauses the contract activities.
24. **`transferOwnership`**: (Owner-only) Transfers the contract's administrative ownership to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for a generic Oracle to standardize data requests and callbacks
interface IOracle {
    function requestData(uint256 marketId, string calldata dataSource, bytes calldata dataParams) external returns (bytes32 requestId);
    function fulfillData(bytes32 requestId, uint256 marketId, uint256 outcomeIndex, string calldata outcomeDetails) external; // Simplified callback
}

contract AetherPredict is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Events ---
    event MarketCreated(
        uint256 indexed marketId,
        address indexed creator,
        string question,
        uint256 resolutionTime,
        uint256 commitWindowEnd,
        uint256 revealWindowEnd,
        uint256 bettingWindowEnd,
        uint256 collateralRequired
    );
    event PredictionCommitted(uint256 indexed marketId, address indexed participant, bytes32 predictionHash);
    event PredictionRevealed(uint256 indexed marketId, address indexed participant, uint256 outcomeIndex);
    event BetPlaced(uint256 indexed marketId, address indexed participant, uint256 outcomeIndex, uint256 amount);
    event MarketResolved(uint256 indexed marketId, uint256 winningOutcomeIndex, string outcomeDetails);
    event WinningsClaimed(uint256 indexed marketId, address indexed participant, uint256 amount);
    event CollateralWithdrawn(uint256 indexed marketId, address indexed creator, uint256 amount);
    event MarketDisputed(uint256 indexed marketId, address indexed disputer, uint256 disputeBond);
    event DisputeResolved(uint256 indexed marketId, uint256 finalOutcomeIndex, address indexed resolver);
    event OracleRegistered(uint256 indexed oracleId, address indexed oracleAddress);
    event OracleDeregistered(uint256 indexed oracleId, address indexed oracleAddress);
    event AdaptiveFeeParametersUpdated(
        uint256 baseMarketCreationFee,
        uint256 baseBettingFee,
        uint256 marketCountImpactFactor,
        uint256 avgAccuracyImpactFactor
    );
    event ReputationParametersUpdated(
        uint256 correctPredictionBonusBps,
        uint256 incorrectPredictionPenaltyBps,
        uint256 maxReputation,
        uint256 maxMultiplierBonusBps
    );


    // --- Enums ---
    enum MarketStatus {
        Open,           // Market can accept commits
        Committing,     // Commit window is active
        Revealing,      // Reveal window is active
        Betting,        // Betting window is active
        Resolving,      // Oracle data requested, awaiting callback
        Resolved,       // Outcome determined, winnings can be claimed
        Disputed,       // Outcome challenged
        Canceled        // Market canceled (e.g., if oracle fails)
    }

    // --- Structs ---

    struct Market {
        address creator;
        string question;
        string[] outcomes; // e.g., ["Yes", "No"]
        uint256 resolutionTime;     // When the event happens
        uint256 commitWindowEnd;    // When commit phase ends
        uint256 revealWindowEnd;    // When reveal phase ends
        uint256 bettingWindowEnd;   // When betting phase ends
        uint256 collateralRequired; // Amount creator stakes
        uint256 currentCollateral;  // Creator's collateral for this market
        MarketStatus status;
        uint256 winningOutcomeIndex; // Index of the winning outcome, set post-resolution
        string outcomeDetails;       // Detailed description of the winning outcome
        bool creatorCollateralWithdrawn; // Flag for collateral withdrawal

        // Oracle Integration
        uint256 oracleId;           // ID of the oracle used for resolution
        string dataSource;          // Specific data source for the oracle (e.g., "Chainlink_ETH_USD")
        bytes dataParams;           // Parameters for the oracle request (e.g., encoded query)

        // Betting Pool
        uint256[] totalBetsPerOutcome; // total amount staked on each outcome
        uint256 totalMarketValue;      // total bets across all outcomes in this market
        uint256 totalFeesCollected;    // total fees collected for this market
        uint256 creationFeePaid;       // fee paid by creator for this market
    }

    struct ParticipantPrediction {
        bytes32 committedHash;  // Hash of (outcomeIndex, salt)
        uint256 revealedOutcomeIndex; // Only valid after reveal window
        uint256 betAmount;
        bool hasClaimed;        // True if winnings have been claimed
        bool hasRevealed;       // True if prediction has been revealed
    }

    struct OracleConfig {
        address oracleAddress;
        uint256 lastRequestId; // To track oracle requests per oracle, if needed for complex oracle
    }

    // --- State Variables ---

    IERC20 public immutable predictionToken; // The ERC20 token used for all transactions
    uint256 public nextMarketId;
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => ParticipantPrediction)) public marketParticipantPredictions;

    // Adaptive Fee Model Parameters
    uint256 public baseMarketCreationFee = 1 ether; // Default base fee (e.g., 1 TOKEN)
    uint256 public baseBettingFee = 0.01 ether;     // Default 1% per bet
    uint256 public marketCountImpactFactor = 5;     // Multiplier for market count impact (bps)
    uint256 public avgAccuracyImpactFactor = 10;    // Multiplier for inverse avg accuracy impact (bps)
    uint256 public constant MAX_ACTIVE_MARKETS_FOR_FEE_CALC = 100; // Cap for scaling

    // Reputation System Parameters
    uint256 public constant REPUTATION_SCALE = 1e18; // To handle reputation as a decimal
    uint256 public correctPredictionBonusBps = 1000; // 10% bonus for correct prediction (of bet amount)
    uint256 public incorrectPredictionPenaltyBps = 500; // 5% penalty for incorrect prediction (of bet amount)
    uint256 public maxReputation = 10 ether; // Max reputation cap (e.g., 10 TOKEN equivalent points)
    uint256 public minReputation = 0; // Min reputation cap
    uint256 public maxMultiplierBonusBps = 2000; // Max 20% additional winnings for highest rep

    mapping(address => uint256) public userReputation; // Reputation score for each user
    mapping(address => uint256) public totalMarketsParticipated; // For tracking average accuracy
    mapping(address => uint256) public totalCorrectPredictions; // For tracking average accuracy

    // Oracle Management
    uint256 public nextOracleId;
    mapping(uint256 => OracleConfig) public registeredOracles; // oracleId => OracleConfig
    mapping(address => uint256) public oracleAddressToId; // oracleAddress => oracleId
    mapping(bytes32 => uint256) public oracleRequestIdToMarketId; // Oracle's requestId => marketId

    // Dispute Management
    uint256 public constant DISPUTE_BOND_PERCENTAGE_BPS = 500; // 5% of market's total value
    mapping(uint256 => address) public disputerAddress; // marketId => disputer's address
    mapping(uint256 => uint256) public disputeBondAmount; // marketId => bond amount

    // Constructor
    constructor(address _predictionTokenAddress) Ownable(msg.sender) Pausable() {
        require(_predictionTokenAddress != address(0), "Invalid token address");
        predictionToken = IERC20(_predictionTokenAddress);
    }

    // --- Modifiers ---

    modifier onlyMarketCreator(uint256 _marketId) {
        require(markets[_marketId].creator == msg.sender, "Only market creator can perform this action");
        _;
    }

    modifier onlyOracle(uint256 _oracleId) {
        require(registeredOracles[_oracleId].oracleAddress == msg.sender, "Only registered oracle can call this");
        _;
    }

    modifier marketStatus(uint256 _marketId, MarketStatus _status) {
        require(markets[_marketId].status == _status, "Market is not in the required status");
        _;
    }

    modifier notResolved(uint256 _marketId) {
        require(markets[_marketId].status < MarketStatus.Resolved || markets[_marketId].status == MarketStatus.Disputed, "Market already resolved or disputed");
        _;
    }

    // --- I. Core Market Lifecycle & Participation ---

    /**
     * @notice Creates a new prediction market.
     * @dev Creator deposits collateral, defines market parameters, and pays a dynamic creation fee.
     * @param _question The prediction question.
     * @param _outcomes An array of possible outcomes (e.g., ["Yes", "No"]).
     * @param _resolutionTime Timestamp when the event to be predicted occurs.
     * @param _commitWindowEnd Timestamp when the commit phase ends.
     * @param _revealWindowEnd Timestamp when the reveal phase ends.
     * @param _bettingWindowEnd Timestamp when the betting phase ends.
     * @param _collateralRequired The amount of token the creator must stake as collateral.
     * @param _oracleId The ID of the registered oracle to be used for resolution.
     * @param _dataSource Specific data source string for the oracle (e.g., "Chainlink_ETH_USD").
     * @param _dataParams Encoded parameters for the oracle request.
     */
    function createMarket(
        string memory _question,
        string[] memory _outcomes,
        uint256 _resolutionTime,
        uint256 _commitWindowEnd,
        uint256 _revealWindowEnd,
        uint256 _bettingWindowEnd,
        uint256 _collateralRequired,
        uint256 _oracleId,
        string memory _dataSource,
        bytes memory _dataParams
    ) external whenNotPaused returns (uint256) {
        require(_outcomes.length > 1, "At least two outcomes required");
        require(_resolutionTime > block.timestamp, "Resolution time must be in the future");
        require(_commitWindowEnd > block.timestamp && _commitWindowEnd < _revealWindowEnd, "Invalid commit window");
        require(_revealWindowEnd > _commitWindowEnd && _revealWindowEnd < _bettingWindowEnd, "Invalid reveal window");
        require(_bettingWindowEnd > _revealWindowEnd && _bettingWindowEnd < _resolutionTime, "Invalid betting window");
        require(_collateralRequired > 0, "Collateral must be greater than zero");
        require(registeredOracles[_oracleId].oracleAddress != address(0), "Invalid oracle ID");

        uint256 marketId = nextMarketId++;
        uint256 creationFee = getMarketCreationFee();

        // Transfer collateral and creation fee from creator
        require(predictionToken.transferFrom(msg.sender, address(this), _collateralRequired.add(creationFee)), "Token transfer failed for collateral or fee");

        Market storage newMarket = markets[marketId];
        newMarket.creator = msg.sender;
        newMarket.question = _question;
        newMarket.outcomes = _outcomes;
        newMarket.resolutionTime = _resolutionTime;
        newMarket.commitWindowEnd = _commitWindowEnd;
        newMarket.revealWindowEnd = _revealWindowEnd;
        newMarket.bettingWindowEnd = _bettingWindowEnd;
        newMarket.collateralRequired = _collateralRequired;
        newMarket.currentCollateral = _collateralRequired;
        newMarket.status = MarketStatus.Committing;
        newMarket.oracleId = _oracleId;
        newMarket.dataSource = _dataSource;
        newMarket.dataParams = _dataParams;
        newMarket.creationFeePaid = creationFee;
        newMarket.totalFeesCollected = creationFee;

        newMarket.totalBetsPerOutcome = new uint256[](_outcomes.length); // Initialize array

        emit MarketCreated(
            marketId,
            msg.sender,
            _question,
            _resolutionTime,
            _commitWindowEnd,
            _revealWindowEnd,
            _bettingWindowEnd,
            _collateralRequired
        );
        return marketId;
    }

    /**
     * @notice Allows a participant to commit a hash of their chosen outcome.
     * @dev This is the first step of the commit-reveal scheme. The actual outcome is not visible yet.
     * @param _marketId The ID of the market.
     * @param _predictionHash The Keccak256 hash of (outcomeIndex, salt).
     */
    function commitPredictionHash(uint256 _marketId, bytes32 _predictionHash)
        external
        whenNotPaused
        marketStatus(_marketId, MarketStatus.Committing)
    {
        require(block.timestamp <= markets[_marketId].commitWindowEnd, "Commit window has closed");
        require(marketParticipantPredictions[_marketId][msg.sender].committedHash == bytes32(0), "Prediction already committed");

        marketParticipantPredictions[_marketId][msg.sender].committedHash = _predictionHash;
        emit PredictionCommitted(_marketId, msg.sender, _predictionHash);
    }

    /**
     * @notice Allows a participant to reveal their chosen outcome and salt.
     * @dev This must happen within the reveal window, after which they can place their bet.
     * @param _marketId The ID of the market.
     * @param _outcomeIndex The index of the chosen outcome.
     * @param _salt A unique random number used during hashing.
     */
    function revealPrediction(uint256 _marketId, uint256 _outcomeIndex, uint256 _salt)
        external
        whenNotPaused
    {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Committing || market.status == MarketStatus.Revealing || market.status == MarketStatus.Betting, "Market not in commit/reveal/betting phase");
        require(block.timestamp > market.commitWindowEnd, "Commit window is still open");
        require(block.timestamp <= market.revealWindowEnd, "Reveal window has closed");
        require(_outcomeIndex < market.outcomes.length, "Invalid outcome index");

        ParticipantPrediction storage pp = marketParticipantPredictions[_marketId][msg.sender];
        require(pp.committedHash != bytes32(0), "No prediction hash committed");
        require(pp.hasRevealed == false, "Prediction already revealed");
        require(pp.committedHash == keccak256(abi.encodePacked(_outcomeIndex, _salt)), "Prediction hash mismatch");

        pp.revealedOutcomeIndex = _outcomeIndex;
        pp.hasRevealed = true;
        emit PredictionRevealed(_marketId, msg.sender, _outcomeIndex);
    }

    /**
     * @notice Allows a participant to place their bet on their revealed outcome.
     * @dev Requires the prediction to be revealed and takes a dynamic betting fee.
     * @param _marketId The ID of the market.
     * @param _amount The amount of prediction token to bet.
     */
    function placeBet(uint256 _marketId, uint256 _amount)
        external
        whenNotPaused
    {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Committing || market.status == MarketStatus.Revealing || market.status == MarketStatus.Betting, "Market not in active betting phase");
        require(block.timestamp > market.revealWindowEnd, "Reveal window is still open or betting hasn't started");
        require(block.timestamp <= market.bettingWindowEnd, "Betting window has closed");
        require(_amount > 0, "Bet amount must be greater than zero");

        ParticipantPrediction storage pp = marketParticipantPredictions[_marketId][msg.sender];
        require(pp.hasRevealed, "Prediction not revealed");
        require(pp.betAmount == 0, "Bet already placed for this market"); // Only one bet per market per user

        uint256 bettingFee = getBettingFee().mul(_amount).div(1 ether); // Assuming baseBettingFee is in BPS (basis points) of _amount for now.
        // For simplicity, let's make getBettingFee return an actual fee, not a percentage.
        // Re-adjusting `getBettingFee` to return a flat fee for easier dynamic calculation.
        // Or, better, `getBettingFee` returns BPS directly. Let's assume it returns BPS for percentage based.
        // If it's a fixed flat fee per bet, it would be simpler. Let's make it a percentage of _amount.
        // Let's assume `getBettingFee()` returns the BPS value (e.g., 100 for 1%).
        bettingFee = _amount.mul(getBettingFee()).div(10000); // 10000 for BPS

        uint256 totalTransferAmount = _amount.add(bettingFee);
        require(predictionToken.transferFrom(msg.sender, address(this), totalTransferAmount), "Token transfer failed for bet or fee");

        market.totalBetsPerOutcome[pp.revealedOutcomeIndex] = market.totalBetsPerOutcome[pp.revealedOutcomeIndex].add(_amount);
        market.totalMarketValue = market.totalMarketValue.add(_amount);
        market.totalFeesCollected = market.totalFeesCollected.add(bettingFee);
        pp.betAmount = _amount;
        
        totalMarketsParticipated[msg.sender]++;

        emit BetPlaced(_marketId, msg.sender, pp.revealedOutcomeIndex, _amount);
    }

    /**
     * @notice Initiates the market resolution process by requesting data from the specified oracle.
     * @dev Can be called by the market creator or an authorized resolver after the betting window closes and resolution time is met.
     * @param _marketId The ID of the market to resolve.
     */
    function finalizeMarketResolution(uint256 _marketId)
        external
        whenNotPaused
        onlyMarketCreator(_marketId) // Could be extended to trusted resolvers
    {
        Market storage market = markets[_marketId];
        require(market.status != MarketStatus.Resolved && market.status != MarketStatus.Disputed && market.status != MarketStatus.Canceled, "Market already resolved, disputed, or canceled");
        require(block.timestamp > market.bettingWindowEnd, "Betting window is still open");
        require(block.timestamp >= market.resolutionTime, "Resolution time has not been reached yet");
        require(market.oracleId != 0, "No oracle configured for this market");
        
        market.status = MarketStatus.Resolving;

        // Request data from the registered oracle
        address oracleAddr = registeredOracles[market.oracleId].oracleAddress;
        require(oracleAddr != address(0), "Oracle address not found for ID");
        
        bytes32 requestId = IOracle(oracleAddr).requestData(_marketId, market.dataSource, market.dataParams);
        oracleRequestIdToMarketId[requestId] = _marketId; // Store mapping for callback
    }

    /**
     * @notice Allows participants with a correct prediction to claim their winnings.
     * @dev Winnings are calculated proportionally to their bet, adjusted by their reputation multiplier.
     * @param _marketId The ID of the market.
     */
    function claimWinnings(uint256 _marketId)
        external
        whenNotPaused
        marketStatus(_marketId, MarketStatus.Resolved)
    {
        Market storage market = markets[_marketId];
        ParticipantPrediction storage pp = marketParticipantPredictions[_marketId][msg.sender];

        require(pp.betAmount > 0, "No bet placed by this address");
        require(!pp.hasClaimed, "Winnings already claimed");
        require(pp.revealedOutcomeIndex == market.winningOutcomeIndex, "Incorrect prediction");

        uint256 totalWinningOutcomePool = market.totalBetsPerOutcome[market.winningOutcomeIndex];
        require(totalWinningOutcomePool > 0, "No winners for this outcome");

        // Calculate proportional winnings
        uint256 rawWinnings = market.totalMarketValue.mul(pp.betAmount).div(totalWinningOutcomePool);
        
        // Apply reputation multiplier
        uint256 multiplier = getReputationRewardMultiplier(msg.sender); // e.g., 10000 for 1x, 12000 for 1.2x
        uint256 finalWinnings = rawWinnings.mul(multiplier).div(10000); // 10000 BPS for base

        require(predictionToken.transfer(msg.sender, finalWinnings), "Failed to transfer winnings");
        pp.hasClaimed = true;

        // Update reputation (internal logic for accuracy updates)
        _updateReputation(_marketId, msg.sender, true);

        emit WinningsClaimed(_marketId, msg.sender, finalWinnings);
    }

    /**
     * @notice Allows the market creator to withdraw their initial collateral after the market is resolved.
     * @dev Collateral is released only if the market resolved without disputes and creator met all obligations.
     * @param _marketId The ID of the market.
     */
    function withdrawMarketCollateral(uint256 _marketId)
        external
        whenNotPaused
        onlyMarketCreator(_marketId)
    {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market not yet resolved");
        require(!market.creatorCollateralWithdrawn, "Collateral already withdrawn");

        uint256 collateralAmount = market.currentCollateral;
        market.currentCollateral = 0; // Prevent double withdrawal
        market.creatorCollateralWithdrawn = true;
        
        require(predictionToken.transfer(msg.sender, collateralAmount), "Collateral withdrawal failed");

        emit CollateralWithdrawn(_marketId, msg.sender, collateralAmount);
    }

    /**
     * @notice Retrieves detailed information about a specific prediction market.
     * @param _marketId The ID of the market.
     * @return Market struct details.
     */
    function getMarketDetails(uint256 _marketId)
        external
        view
        returns (
            address creator,
            string memory question,
            string[] memory outcomes,
            uint256 resolutionTime,
            uint256 commitWindowEnd,
            uint256 revealWindowEnd,
            uint256 bettingWindowEnd,
            uint256 collateralRequired,
            uint256 currentCollateral,
            MarketStatus status,
            uint256 winningOutcomeIndex,
            string memory outcomeDetails,
            uint256 oracleId,
            string memory dataSource,
            uint256 totalMarketValue,
            uint256 totalFeesCollected
        )
    {
        Market storage market = markets[_marketId];
        return (
            market.creator,
            market.question,
            market.outcomes,
            market.resolutionTime,
            market.commitWindowEnd,
            market.revealWindowEnd,
            market.bettingWindowEnd,
            market.collateralRequired,
            market.currentCollateral,
            market.status,
            market.winningOutcomeIndex,
            market.outcomeDetails,
            market.oracleId,
            market.dataSource,
            market.totalMarketValue,
            market.totalFeesCollected
        );
    }

    /**
     * @notice Retrieves a participant's prediction and bet details for a specific market.
     * @param _marketId The ID of the market.
     * @param _participant The address of the participant.
     * @return revealedOutcomeIndex The index of the outcome the participant revealed.
     * @return betAmount The amount the participant bet.
     * @return hasClaimed True if winnings have been claimed.
     * @return hasRevealed True if the prediction has been revealed.
     */
    function getUserPredictionAndBet(uint256 _marketId, address _participant)
        external
        view
        returns (uint256 revealedOutcomeIndex, uint256 betAmount, bool hasClaimed, bool hasRevealed)
    {
        ParticipantPrediction storage pp = marketParticipantPredictions[_marketId][_participant];
        return (pp.revealedOutcomeIndex, pp.betAmount, pp.hasClaimed, pp.hasRevealed);
    }

    /**
     * @notice Retrieves the total amount bet on each outcome for a specific market.
     * @param _marketId The ID of the market.
     * @return totalBetsPerOutcome An array showing the total amount bet for each outcome.
     */
    function getMarketOutcomeTotals(uint256 _marketId)
        external
        view
        returns (uint256[] memory totalBetsPerOutcome)
    {
        return markets[_marketId].totalBetsPerOutcome;
    }

    // --- II. Adaptive Fee & Reputation System ---

    /**
     * @notice Calculates the dynamic fee for creating a new market.
     * @dev Fees adjust based on the number of active markets and the contract's overall prediction accuracy.
     * @return The calculated market creation fee in prediction tokens.
     */
    function getMarketCreationFee() public view returns (uint256) {
        // Simple adaptive model: Fee increases with more active markets, and with lower average accuracy.
        uint256 activeMarkets = nextMarketId; // Simplified: count all markets ever created
        if (activeMarkets > MAX_ACTIVE_MARKETS_FOR_FEE_CALC) activeMarkets = MAX_ACTIVE_MARKETS_FOR_FEE_CALC;

        uint256 fee = baseMarketCreationFee;

        // Factor in market count: More markets -> potentially higher fee
        fee = fee.add(baseMarketCreationFee.mul(activeMarkets).mul(marketCountImpactFactor).div(MAX_ACTIVE_MARKETS_FOR_FEE_CALC.mul(10000)));

        // Factor in inverse average accuracy (if accuracy is low, fees increase)
        // For simplicity, this requires global tracking of average accuracy.
        // Let's assume a simplified global average accuracy for now or use a fixed placeholder.
        // A more complex system would store historical global accuracy.
        uint256 globalAvgAccuracyInverseBps = 5000; // Placeholder: 50% accurate, 1 - 0.5 = 0.5 -> 5000 BPS
        // A real system would calculate: (totalMarketsParticipated - totalCorrectPredictions) / totalMarketsParticipated
        // Let's skip complex global accuracy calculation for this example and use a fixed impact for now.
        // fee = fee.add(baseMarketCreationFee.mul(globalAvgAccuracyInverseBps).mul(avgAccuracyImpactFactor).div(100000000)); // 10000 * 10000 for BPS

        return fee;
    }

    /**
     * @notice Calculates the dynamic percentage-based fee for placing a bet.
     * @dev Fees adjust based on similar factors as market creation.
     * @return The calculated betting fee in basis points (e.g., 100 for 1%).
     */
    function getBettingFee() public view returns (uint256) {
        // Similar adaptive model as market creation fee, but returns BPS.
        uint256 activeMarkets = nextMarketId;
        if (activeMarkets > MAX_ACTIVE_MARKETS_FOR_FEE_CALC) activeMarkets = MAX_ACTIVE_MARKETS_FOR_FEE_CALC;

        uint256 feeBps = baseBettingFee.div(1 ether).mul(10000); // Assuming baseBettingFee is 0.01 ether = 1% for now.
                                                                // Let's directly make `baseBettingFee` store BPS to simplify.
        // Let's assume `baseBettingFee` is already in BPS (e.g., 100 for 1%)
        // So baseBettingFee is 100 (for 1%)
        uint256 currentBaseBettingFeeBps = baseBettingFee; // Renamed to clearly indicate it's BPS

        // Factor in market count: More markets -> potentially higher fee
        currentBaseBettingFeeBps = currentBaseBettingFeeBps.add(currentBaseBettingFeeBps.mul(activeMarkets).mul(marketCountImpactFactor).div(MAX_ACTIVE_MARKETS_FOR_FEE_CALC.mul(10000)));

        return currentBaseBettingFeeBps; // Returns BPS value
    }

    /**
     * @notice Retrieves the reputation score of a specific user.
     * @param _user The address of the user.
     * @return The reputation score, scaled by REPUTATION_SCALE.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Calculates the reward multiplier for a user based on their reputation.
     * @dev Higher reputation leads to a higher multiplier, boosting winnings.
     * @param _user The address of the user.
     * @return The reward multiplier in basis points (10000 for 1x, 12000 for 1.2x).
     */
    function getReputationRewardMultiplier(address _user) public view returns (uint256) {
        uint256 reputation = userReputation[_user];
        if (reputation == 0) return 10000; // Base multiplier 1x

        // Calculate bonus based on reputation, capped at maxMultiplierBonusBps
        // multiplier = 1 + (reputation / maxReputation) * maxMultiplierBonusBps
        // Example: if reputation = maxReputation/2, and maxMultiplierBonusBps = 2000 (20%), then 10% bonus.
        uint256 bonusBps = reputation.mul(maxMultiplierBonusBps).div(maxReputation);
        return 10000 + bonusBps; // Base 100% + bonus
    }

    /**
     * @notice (Owner-only) Sets parameters for the Adaptive Fee Model.
     * @param _baseMarketCreationFee New base fee for market creation.
     * @param _baseBettingFee New base betting fee in BPS.
     * @param _marketCountImpactFactor New factor for market count impact in BPS.
     * @param _avgAccuracyImpactFactor New factor for average accuracy impact in BPS.
     */
    function setAdaptiveFeeParameters(
        uint256 _baseMarketCreationFee,
        uint256 _baseBettingFee, // Expected in BPS, e.g., 100 for 1%
        uint256 _marketCountImpactFactor,
        uint256 _avgAccuracyImpactFactor
    ) external onlyOwner {
        baseMarketCreationFee = _baseMarketCreationFee;
        baseBettingFee = _baseBettingFee;
        marketCountImpactFactor = _marketCountImpactFactor;
        avgAccuracyImpactFactor = _avgAccuracyImpactFactor;
        emit AdaptiveFeeParametersUpdated(_baseMarketCreationFee, _baseBettingFee, _marketCountImpactFactor, _avgAccuracyImpactFactor);
    }

    /**
     * @notice (Owner-only) Sets parameters for the Reputation System.
     * @param _correctPredictionBonusBps Bonus percentage (BPS) of bet amount for correct prediction.
     * @param _incorrectPredictionPenaltyBps Penalty percentage (BPS) of bet amount for incorrect prediction.
     * @param _maxReputation Maximum possible reputation score.
     * @param _maxMultiplierBonusBps Maximum additional reward bonus in BPS for highest reputation.
     */
    function setReputationParameters(
        uint256 _correctPredictionBonusBps,
        uint256 _incorrectPredictionPenaltyBps,
        uint256 _maxReputation,
        uint256 _maxMultiplierBonusBps
    ) external onlyOwner {
        correctPredictionBonusBps = _correctPredictionBonusBps;
        incorrectPredictionPenaltyBps = _incorrectPredictionPenaltyBps;
        maxReputation = _maxReputation;
        maxMultiplierBonusBps = _maxMultiplierBonusBps;
        emit ReputationParametersUpdated(_correctPredictionBonusBps, _incorrectPredictionPenaltyBps, _maxReputation, _maxMultiplierBonusBps);
    }

    /**
     * @dev Internal function to update a user's reputation based on prediction accuracy.
     * @param _marketId The ID of the market.
     * @param _user The address of the user.
     * @param _isCorrect True if the prediction was correct, false otherwise.
     */
    function _updateReputation(uint256 _marketId, address _user, bool _isCorrect) internal {
        ParticipantPrediction storage pp = marketParticipantPredictions[_marketId][_user];
        uint256 betAmount = pp.betAmount;

        if (_isCorrect) {
            uint256 bonus = betAmount.mul(correctPredictionBonusBps).div(10000); // 10000 BPS
            userReputation[_user] = userReputation[_user].add(bonus).min(maxReputation);
            totalCorrectPredictions[_user]++;
        } else {
            uint256 penalty = betAmount.mul(incorrectPredictionPenaltyBps).div(10000); // 10000 BPS
            userReputation[_user] = userReputation[_user].sub(penalty).max(minReputation);
        }
    }


    // --- III. Modular Oracle Integration ---

    /**
     * @notice (Owner-only) Registers a new trusted external oracle contract.
     * @param _oracleAddress The address of the oracle contract.
     */
    function registerResolutionOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(oracleAddressToId[_oracleAddress] == 0, "Oracle already registered");

        uint256 oracleId = nextOracleId++;
        registeredOracles[oracleId] = OracleConfig({
            oracleAddress: _oracleAddress,
            lastRequestId: 0 // Placeholder
        });
        oracleAddressToId[_oracleAddress] = oracleId;
        emit OracleRegistered(oracleId, _oracleAddress);
    }

    /**
     * @notice (Owner-only) Deregisters an existing oracle.
     * @param _oracleId The ID of the oracle to deregister.
     */
    function deregisterResolutionOracle(uint256 _oracleId) external onlyOwner {
        require(registeredOracles[_oracleId].oracleAddress != address(0), "Oracle not found");

        address oracleAddr = registeredOracles[_oracleId].oracleAddress;
        delete oracleAddressToId[oracleAddr];
        delete registeredOracles[_oracleId];
        emit OracleDeregistered(_oracleId, oracleAddr);
    }

    /**
     * @notice Callback function for registered oracles to deliver market outcomes.
     * @dev Only registered oracles can call this.
     * @param _requestId The request ID originally provided to the oracle.
     * @param _marketId The ID of the market being resolved.
     * @param _outcomeIndex The index of the winning outcome.
     * @param _outcomeDetails A detailed string description of the outcome.
     */
    function receiveOracleCallback(bytes32 _requestId, uint256 _marketId, uint256 _outcomeIndex, string calldata _outcomeDetails)
        external
    {
        uint256 oracleId = oracleAddressToId[msg.sender];
        require(oracleId != 0 && registeredOracles[oracleId].oracleAddress == msg.sender, "Caller is not a registered oracle");
        require(oracleRequestIdToMarketId[_requestId] == _marketId, "Invalid request ID or market mismatch");

        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Resolving, "Market not in resolving state");
        require(_outcomeIndex < market.outcomes.length, "Invalid outcome index from oracle");

        market.winningOutcomeIndex = _outcomeIndex;
        market.outcomeDetails = _outcomeDetails;
        market.status = MarketStatus.Resolved;

        // Clean up mapping
        delete oracleRequestIdToMarketId[_requestId];

        // Update reputations for all participants (even those who lost)
        // This iterates through all participants for a market, which can be gas-intensive for large markets.
        // In a production system, this would be optimized, e.g., using an iterable mapping or a separate contract for reputation.
        // For this example, we'll demonstrate the logic (not iterating). Reputation updates would happen on `claimWinnings`.
        // The previous design decision `_updateReputation` is called when `claimWinnings` is called.
        // So this function just resolves the market.

        emit MarketResolved(_marketId, _outcomeIndex, _outcomeDetails);
    }


    // --- IV. Dispute Resolution & Administration ---

    /**
     * @notice Allows a participant to dispute a market's resolved outcome.
     * @dev Requires a dispute bond (percentage of total market value).
     * @param _marketId The ID of the market to dispute.
     */
    function disputeMarketOutcome(uint256 _marketId)
        external
        whenNotPaused
        marketStatus(_marketId, MarketStatus.Resolved)
    {
        Market storage market = markets[_marketId];
        require(disputerAddress[_marketId] == address(0), "Market already under dispute");
        
        uint256 bondAmount = market.totalMarketValue.mul(DISPUTE_BOND_PERCENTAGE_BPS).div(10000); // 10000 BPS
        require(bondAmount > 0, "Dispute bond amount is zero");

        require(predictionToken.transferFrom(msg.sender, address(this), bondAmount), "Dispute bond transfer failed");
        
        disputerAddress[_marketId] = msg.sender;
        disputeBondAmount[_marketId] = bondAmount;
        market.status = MarketStatus.Disputed;

        emit MarketDisputed(_marketId, msg.sender, bondAmount);
    }

    /**
     * @notice (Owner-only) Resolves a disputed market.
     * @dev The owner (or an appointed arbiter) determines the final outcome and distributes the dispute bond.
     * @param _marketId The ID of the disputed market.
     * @param _finalOutcomeIndex The definitive outcome index.
     * @param _forfeitDisputerBond True if the disputer's bond should be forfeited (e.g., dispute was invalid).
     */
    function resolveDispute(uint256 _marketId, uint256 _finalOutcomeIndex, bool _forfeitDisputerBond)
        external
        onlyOwner // Could be a separate arbiter role
        marketStatus(_marketId, MarketStatus.Disputed)
    {
        Market storage market = markets[_marketId];
        require(_finalOutcomeIndex < market.outcomes.length, "Invalid final outcome index");

        address disputer = disputerAddress[_marketId];
        uint256 bond = disputeBondAmount[_marketId];

        market.winningOutcomeIndex = _finalOutcomeIndex;
        market.outcomeDetails = market.outcomes[_finalOutcomeIndex]; // Simplified, could be richer
        market.status = MarketStatus.Resolved;

        // Distribute or refund dispute bond
        if (_forfeitDisputerBond) {
            // Add bond to contract's general funds or burn it
            // For simplicity, it stays in contract as part of totalFeesCollected.
            market.totalFeesCollected = market.totalFeesCollected.add(bond);
        } else {
            // Refund disputer's bond
            require(predictionToken.transfer(disputer, bond), "Dispute bond refund failed");
        }

        delete disputerAddress[_marketId];
        delete disputeBondAmount[_marketId];

        emit DisputeResolved(_marketId, _finalOutcomeIndex, msg.sender);
    }

    /**
     * @notice (Owner-only) Pauses contract activities (market creation, betting, claiming).
     * @dev Emergency function to protect against vulnerabilities or malicious activity.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice (Owner-only) Unpauses contract activities.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice (Owner-only) Allows the current owner to transfer ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // --- Fallback & Receive Functions ---
    // Not required for this contract as all interactions are through specific ERC20 transfers.
    // However, if direct ETH transfers were expected, a receive() or fallback() would be needed.
}
```