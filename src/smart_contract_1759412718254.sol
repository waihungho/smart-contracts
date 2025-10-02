Here is a smart contract in Solidity called `Synthetikon`. It embodies a decentralized AI-augmented innovation oracle and predictive capital DAO, featuring a comprehensive set of functions beyond typical open-source patterns.

---

**OUTLINE**

**Contract Name:** `Synthetikon`

**Core Concept:**
Synthetikon is a decentralized innovation oracle and predictive capital DAO. It enables users to propose "innovation forecasts" (ideas/projects), stake tokens on their predicted success or failure, and earn rewards based on the outcome. The system incorporates an abstracted "AI-augmented oracle" for evaluation, a dynamic reputation system for participants, and "Insight NFTs" to recognize significant contributions. Governance is handled by DAO proposals, allowing for adaptive parameter tuning. This contract aims to predict the success of novel ideas rather than market prices, offering a unique blend of collective intelligence, AI evaluation, and decentralized governance.

---

**FUNCTION SUMMARY**

**I. Innovation Forecast Management (Prediction Market Core)**
1.  `submitInnovationForecast(string memory _descriptionHash, string memory _targetMetricDescription, uint256 _evaluationPeriodDays)`: Allows users to propose a new innovation forecast for the community to stake on.
2.  `stakeOnForecast(uint256 _forecastId, uint256 _amount, bool _forSuccess)`: Users stake tokens for or against a specific innovation forecast.
3.  `requestOracleEvaluation(uint256 _forecastId)`: Initiates the external oracle evaluation process for a forecast that has reached its evaluation period.
4.  `receiveOracleEvaluation(uint256 _forecastId, int256 _aiEvaluationScore, bool _isSuccess, string memory _evaluationProofHash)`: Callback function for the trusted oracle to report the evaluation outcome, including an AI-generated score and final success determination.
5.  `distributeForecastRewards(uint256 _forecastId)`: Processes the distribution of staked funds and updates reputation based on the forecast outcome. Can only be called after evaluation.
6.  `claimForecastWinnings(uint256 _forecastId)`: Allows stakers to acknowledge their credited winnings from a successfully evaluated forecast (actual withdrawal is via `withdrawUnstakedBalance`).
7.  `withdrawUnstakedBalance()`: Allows users to withdraw any tokens they have deposited but are not currently staked.
8.  `getForecastDetails(uint256 _forecastId)`: View function to retrieve all details of a specific innovation forecast.

**II. Reputation & Insight NFT System**
9.  `mintInsightNFT(address _recipient, uint256 _forecastId, string memory _tokenURI)`: Mints a unique Insight NFT to a recipient, typically awarded for exceptional predictive accuracy or successful forecast proposal.
10. `getReputationScore(address _user)`: View function to check a user's current reputation score.
11. `getTopPredictors(uint256 _limit)`: View function to retrieve a leaderboard of top predictors based on reputation (on-chain sorting for demonstration, ideally off-chain for large scale).
12. `_updateReputation(address _user, int256 _delta)`: Internal function to adjust a user's reputation score based on their prediction performance.

**III. DAO Governance & System Parameters**
13. `proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata, address _targetContract)`: Allows users (with sufficient reputation) to propose changes to contract parameters or logic.
14. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Users vote on active governance proposals. Voting power is tied to reputation.
15. `executeGovernanceProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal.
16. `setForecastEvaluationPeriod(uint256 _newPeriodDays)`: DAO-governed function to adjust the default evaluation period for new forecasts.
17. `setRewardDistributionFactors(uint256 _winnerShare, uint256 _loserPenalty, uint256 _treasuryFee)`: DAO-governed function to update the percentages for reward distribution, penalties, and treasury fees.
18. `setOracleAddress(address _newOracle)`: DAO-governed function to update the trusted oracle contract address.
19. `setMinimumStakeAmount(uint256 _newAmount)`: DAO-governed function to set the minimum amount required to stake on a forecast.
20. `pauseSystem()`: DAO-governed function to pause critical contract functionalities in case of an emergency.
21. `unpauseSystem()`: DAO-governed function to unpause the system.

**IV. Treasury Management & ERC20 Interactions**
22. `depositTokens(uint256 _amount)`: Allows users to deposit tokens into their internal balance within the contract, making them available for staking.
23. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: DAO-governed function to withdraw funds from the contract's treasury (derived from fees and penalties).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For iterating over users with reputation
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit arithmetic safety

// --- OUTLINE ---
// Contract Name: Synthetikon
// Core Concept:
// Synthetikon is a decentralized innovation oracle and predictive capital DAO. It enables users to propose
// "innovation forecasts" (ideas/projects), stake tokens on their predicted success or failure, and earn
// rewards based on the outcome. The system incorporates an abstracted "AI-augmented oracle" for evaluation,
// a dynamic reputation system for participants, and "Insight NFTs" to recognize significant contributions.
// Governance is handled by DAO proposals, allowing for adaptive parameter tuning.
//
// --- FUNCTION SUMMARY ---
// I. Innovation Forecast Management (Prediction Market Core)
// 1. submitInnovationForecast(string memory _descriptionHash, string memory _targetMetricDescription, uint256 _evaluationPeriodDays): Propose a new innovation forecast.
// 2. stakeOnForecast(uint256 _forecastId, uint256 _amount, bool _forSuccess): Stake tokens for or against a forecast.
// 3. requestOracleEvaluation(uint256 _forecastId): Initiate external oracle evaluation for a forecast.
// 4. receiveOracleEvaluation(uint256 _forecastId, int256 _aiEvaluationScore, bool _isSuccess, string memory _evaluationProofHash): Callback for trusted oracle to report evaluation outcome.
// 5. distributeForecastRewards(uint256 _forecastId): Process rewards/penalties and update reputation after evaluation.
// 6. claimForecastWinnings(uint256 _forecastId): Acknowledge credited winnings from evaluated forecasts (actual withdrawal via `withdrawUnstakedBalance`).
// 7. withdrawUnstakedBalance(): Allow users to withdraw their general (unstaked) balance.
// 8. getForecastDetails(uint256 _forecastId): View function for forecast details.
//
// II. Reputation & Insight NFT System
// 9. mintInsightNFT(address _recipient, uint256 _forecastId, string memory _tokenURI): Mints an Insight NFT for exceptional contributions.
// 10. getReputationScore(address _user): View function for a user's reputation.
// 11. getTopPredictors(uint256 _limit): View function to retrieve a leaderboard of top predictors.
// 12. _updateReputation(address _user, int256 _delta): Internal function to adjust reputation.
//
// III. DAO Governance & System Parameters
// 13. proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata, address _targetContract): Propose changes to contract parameters or logic.
// 14. voteOnGovernanceProposal(uint256 _proposalId, bool _support): Vote on active governance proposals.
// 15. executeGovernanceProposal(uint256 _proposalId): Execute a successfully passed governance proposal.
// 16. setForecastEvaluationPeriod(uint256 _newPeriodDays): DAO-governed function to adjust default evaluation period.
// 17. setRewardDistributionFactors(uint256 _winnerShare, uint256 _loserPenalty, uint256 _treasuryFee): DAO-governed function to update reward/penalty/fee percentages.
// 18. setOracleAddress(address _newOracle): DAO-governed function to update the trusted oracle address.
// 19. setMinimumStakeAmount(uint256 _newAmount): DAO-governed function to set the minimum stake.
// 20. pauseSystem(): DAO-governed function to pause critical functionalities.
// 21. unpauseSystem(): DAO-governed function to unpause the system.
//
// IV. Treasury Management & ERC20 Interactions
// 22. depositTokens(uint256 _amount): Deposit tokens into internal balance for staking.
// 23. withdrawTreasuryFunds(address _recipient, uint256 _amount): DAO-governed withdrawal from the contract's treasury.

// --- Helper Contracts / Interfaces ---

interface IInsightNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function getNextTokenId() external view returns (uint256);
}

// InsightNFT contract for unique recognition
contract InsightNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    // The owner of the NFT contract should be the Synthetikon contract
    constructor(address synthetikonContractAddress)
        ERC721("Synthetikon Insight NFT", "S-INSIGHT")
        Ownable(synthetikonContractAddress)
    {
        _nextTokenId = 1; // Start token IDs from 1
    }

    /// @notice Mints a new Insight NFT. Only callable by the owner (Synthetikon contract).
    /// @param to The recipient of the NFT.
    /// @param tokenId The specific token ID to mint. Should match `_nextTokenId`.
    /// @param tokenURI The URI for the NFT's metadata.
    function mint(address to, uint256 tokenId, string calldata tokenURI) external onlyOwner {
        require(tokenId == _nextTokenId, "InsightNFT: Token ID mismatch");
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _nextTokenId++;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Base URI for metadata, expects path after this.
    }

    /// @notice Returns the next available token ID without incrementing.
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }
}

contract Synthetikon is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    IERC20 public stakingToken; // The ERC20 token used for staking
    IInsightNFT public insightNFT; // The ERC721 contract for Insight NFTs

    address public trustedOracle; // Address of the trusted oracle contract/service
    uint256 public forecastCounter; // Unique ID for each forecast
    uint256 public governanceProposalCounter; // Unique ID for governance proposals

    // Configuration parameters (DAO-governed)
    uint256 public defaultEvaluationPeriodDays; // Default days before a forecast can be evaluated
    uint256 public minimumStakeAmount; // Minimum amount required to stake on a forecast
    uint256 public winnerRewardShareBasisPoints; // % of total staked for winners (e.g., 8000 for 80%)
    uint256 public loserPenaltyShareBasisPoints; // % of staked amount lost by losers (e.g., 2000 for 20%)
    uint256 public treasuryFeeShareBasisPoints; // % of total staked funds that goes to treasury (e.g., 500 for 5%)
    uint256 public daoVoteMinReputation; // Minimum reputation to propose/vote on governance

    // Internal balances for users (tokens deposited but not yet staked)
    mapping(address => uint256) public userBalances;
    // Tracks total funds currently locked in active forecasts (before distribution)
    uint256 public totalStakedFundsAtRisk;
    // Dedicated treasury balance from fees/penalties
    uint256 public treasuryBalance;

    // Reputation scores
    mapping(address => uint252) public reputationScores; // Using uint252 to signify it's a score, not direct balance
    EnumerableSet.AddressSet private _reputationHolders; // To efficiently iterate over users with reputation

    // Forecasts storage
    enum ForecastStatus { Proposed, Active, Evaluating, Completed, Rejected }
    struct InnovationForecast {
        address proposer;
        string descriptionHash; // IPFS hash of the detailed proposal
        string targetMetricDescription; // What success looks like (e.g., "market cap > $1B by 2025")
        uint256 predictionTimestamp; // Block.timestamp when submitted
        uint252 evaluationPeriodEnd; // Block.timestamp when evaluation period ends
        uint252 totalStakedFor;
        uint252 totalStakedAgainst;
        bool isEvaluated;
        bool evaluationResult; // true for success, false for failure
        bool distributed; // True if rewards have been distributed
        ForecastStatus status;
        int256 aiEvaluationScore; // Score provided by the AI oracle
        string evaluationProofHash; // IPFS hash or similar for oracle proof
    }
    mapping(uint256 => InnovationForecast) public innovationForecasts;

    // Stakes storage
    struct PredictionStake {
        address staker;
        uint252 amount;
        bool forSuccess; // true for backing success, false for backing failure
        bool claimed; // true if rewards/penalty have been processed for this stake
    }
    mapping(uint256 => mapping(address => mapping(bool => PredictionStake))) public userForecastStakes;
    mapping(uint256 => address[]) public forecastStakersFor;
    mapping(uint256 => address[]) public forecastStakersAgainst;


    // Governance proposals storage
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        address proposer;
        string description;
        bytes calldataPayload; // The ABI-encoded function call to execute
        address targetContract; // The contract to call (e.g., Synthetikon itself for parameter changes)
        uint252 voteStartTime;
        uint252 voteEndTime;
        uint252 votesFor;
        uint252 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalStatus status;
        uint252 requiredReputation; // Minimum reputation to vote on this proposal
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Events
    event ForecastSubmitted(uint256 indexed forecastId, address indexed proposer, string descriptionHash, uint256 evaluationPeriodEnd);
    event TokensStaked(uint256 indexed forecastId, address indexed staker, uint256 amount, bool forSuccess);
    event OracleEvaluationRequested(uint256 indexed forecastId, address indexed requester);
    event OracleEvaluationReceived(uint256 indexed forecastId, int256 aiEvaluationScore, bool isSuccess, string evaluationProofHash);
    event RewardsDistributed(uint256 indexed forecastId, uint256 totalWinnerPool, uint256 totalLoserPenalty, uint256 totalTreasuryFee);
    event WinningsCredited(uint256 indexed forecastId, address indexed staker);
    event UnstakedBalanceWithdrawn(address indexed user, uint256 amount);
    event InsightNFTMinted(address indexed recipient, uint256 indexed tokenId, uint256 indexed forecastId, string tokenURI);
    event ReputationUpdated(address indexed user, int256 delta, uint256 newScore);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votesFor, uint256 votesAgainst);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event SystemPaused(address indexed by);
    event SystemUnpaused(address indexed by);
    event ParameterUpdated(string indexed paramName, uint256 newValue); // Generic event for parameter changes

    // --- Constructor ---

    constructor(
        address _stakingTokenAddress,
        address _insightNFTAddress,
        address _trustedOracleAddress,
        uint256 _defaultEvaluationPeriodDays,
        uint256 _minimumStakeAmount,
        uint256 _winnerRewardShareBasisPoints,
        uint256 _loserPenaltyShareBasisPoints,
        uint256 _treasuryFeeShareBasisPoints,
        uint256 _daoVoteMinReputation
    ) Ownable(msg.sender) Pausable(false) {
        require(_stakingTokenAddress != address(0), "Synthetikon: Invalid staking token address");
        require(_insightNFTAddress != address(0), "Synthetikon: Invalid Insight NFT address");
        require(_trustedOracleAddress != address(0), "Synthetikon: Invalid oracle address");
        require(_winnerRewardShareBasisPoints.add(_treasuryFeeShareBasisPoints) <= 10000, "Synthetikon: Invalid reward/fee shares sum");
        require(_loserPenaltyShareBasisPoints <= 10000, "Synthetikon: Invalid loser penalty");

        stakingToken = IERC20(_stakingTokenAddress);
        insightNFT = IInsightNFT(_insightNFTAddress);
        trustedOracle = _trustedOracleAddress;
        defaultEvaluationPeriodDays = _defaultEvaluationPeriodDays;
        minimumStakeAmount = _minimumStakeAmount;
        winnerRewardShareBasisPoints = _winnerRewardShareBasisPoints;
        loserPenaltyShareBasisPoints = _loserPenaltyShareBasisPoints;
        treasuryFeeShareBasisPoints = _treasuryFeeShareBasisPoints;
        daoVoteMinReputation = _daoVoteMinReputation;

        forecastCounter = 0;
        governanceProposalCounter = 0;
        totalStakedFundsAtRisk = 0;
        treasuryBalance = 0;
    }

    // --- Modifiers ---

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracle, "Synthetikon: Only trusted oracle can call this function");
        _;
    }

    modifier onlyActiveForecast(uint256 _forecastId) {
        require(_forecastId > 0 && _forecastId <= forecastCounter, "Synthetikon: Invalid forecast ID");
        require(innovationForecasts[_forecastId].status == ForecastStatus.Active, "Synthetikon: Forecast is not active");
        _;
    }

    modifier onlyEvaluatedForecast(uint256 _forecastId) {
        require(_forecastId > 0 && _forecastId <= forecastCounter, "Synthetikon: Invalid forecast ID");
        require(innovationForecasts[_forecastId].status == ForecastStatus.Completed, "Synthetikon: Forecast not yet evaluated or in pending state");
        require(innovationForecasts[_forecastId].isEvaluated, "Synthetikon: Forecast not yet evaluated");
        _;
    }

    modifier notDistributed(uint256 _forecastId) {
        require(!innovationForecasts[_forecastId].distributed, "Synthetikon: Rewards already distributed for this forecast");
        _;
    }

    // --- I. Innovation Forecast Management (Prediction Market Core) ---

    /// @notice Allows users to propose a new innovation forecast for the community to stake on.
    /// @param _descriptionHash IPFS hash of the detailed proposal description.
    /// @param _targetMetricDescription A clear, measurable description of what constitutes success for this forecast.
    /// @param _evaluationPeriodDays The number of days after which this forecast can be evaluated. Defaults to system-wide if 0.
    function submitInnovationForecast(
        string memory _descriptionHash,
        string memory _targetMetricDescription,
        uint256 _evaluationPeriodDays
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_descriptionHash).length > 0, "Synthetikon: Description hash cannot be empty");
        require(bytes(_targetMetricDescription).length > 0, "Synthetikon: Target metric cannot be empty");
        
        uint256 actualEvaluationPeriod = _evaluationPeriodDays == 0 ? defaultEvaluationPeriodDays : _evaluationPeriodDays;
        require(actualEvaluationPeriod > 0, "Synthetikon: Evaluation period must be greater than 0");

        forecastCounter++;
        uint256 newForecastId = forecastCounter;

        innovationForecasts[newForecastId] = InnovationForecast({
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            targetMetricDescription: _targetMetricDescription,
            predictionTimestamp: block.timestamp,
            evaluationPeriodEnd: uint252(block.timestamp.add(actualEvaluationPeriod.mul(1 days))),
            totalStakedFor: 0,
            totalStakedAgainst: 0,
            isEvaluated: false,
            evaluationResult: false, // Default to false
            distributed: false,
            status: ForecastStatus.Active,
            aiEvaluationScore: 0,
            evaluationProofHash: ""
        });

        emit ForecastSubmitted(newForecastId, msg.sender, _descriptionHash, innovationForecasts[newForecastId].evaluationPeriodEnd);
        return newForecastId;
    }

    /// @notice Allows users to stake tokens for or against a specific innovation forecast.
    /// @param _forecastId The ID of the forecast to stake on.
    /// @param _amount The amount of tokens to stake.
    /// @param _forSuccess True to stake for success, false to stake against success (for failure).
    function stakeOnForecast(
        uint256 _forecastId,
        uint256 _amount,
        bool _forSuccess
    ) external whenNotPaused nonReentrant onlyActiveForecast(_forecastId) {
        require(_amount >= minimumStakeAmount, "Synthetikon: Stake amount too low");
        require(userBalances[msg.sender] >= _amount, "Synthetikon: Insufficient balance to stake. Deposit more tokens.");
        require(innovationForecasts[_forecastId].evaluationPeriodEnd > block.timestamp, "Synthetikon: Cannot stake, evaluation period has ended.");
        
        // Prevent staking twice in the same direction on the same forecast.
        require(userForecastStakes[_forecastId][msg.sender][_forSuccess].amount == 0, "Synthetikon: Already staked in this direction. Unstake first to change, or add to existing stake using a dedicated function.");

        userBalances[msg.sender] = userBalances[msg.sender].sub(_amount);

        PredictionStake storage currentStake = userForecastStakes[_forecastId][msg.sender][_forSuccess];
        currentStake.staker = msg.sender;
        currentStake.amount = uint252(currentStake.amount.add(_amount)); // Cast to uint252 if type is different
        currentStake.forSuccess = _forSuccess;
        currentStake.claimed = false;

        InnovationForecast storage forecast = innovationForecasts[_forecastId];
        if (_forSuccess) {
            forecast.totalStakedFor = uint252(forecast.totalStakedFor.add(_amount));
            forecastStakersFor[_forecastId].push(msg.sender);
        } else {
            forecast.totalStakedAgainst = uint252(forecast.totalStakedAgainst.add(_amount));
            forecastStakersAgainst[_forecastId].push(msg.sender);
        }
        totalStakedFundsAtRisk = totalStakedFundsAtRisk.add(_amount);

        emit TokensStaked(_forecastId, msg.sender, _amount, _forSuccess);
    }

    /// @notice Initiates the external oracle evaluation process for a forecast that has reached its evaluation period.
    /// This function is typically called by the proposer, a DAO member, or an automated keeper.
    /// It sends a request to the trusted oracle (off-chain) to perform the actual evaluation.
    /// The oracle then calls `receiveOracleEvaluation` with the result.
    /// @param _forecastId The ID of the forecast to request evaluation for.
    function requestOracleEvaluation(uint256 _forecastId) external whenNotPaused nonReentrant {
        InnovationForecast storage forecast = innovationForecasts[_forecastId];
        require(_forecastId > 0 && _forecastId <= forecastCounter, "Synthetikon: Invalid forecast ID");
        require(forecast.status == ForecastStatus.Active, "Synthetikon: Forecast not in active state");
        require(block.timestamp >= forecast.evaluationPeriodEnd, "Synthetikon: Evaluation period not yet ended");
        require(!forecast.isEvaluated, "Synthetikon: Forecast already evaluated");

        forecast.status = ForecastStatus.Evaluating;
        emit OracleEvaluationRequested(_forecastId, msg.sender);
    }

    /// @notice Callback function for the trusted oracle to report the evaluation outcome.
    /// This function is restricted to the `trustedOracle` address.
    /// @param _forecastId The ID of the forecast being evaluated.
    /// @param _aiEvaluationScore A score provided by the AI oracle (e.g., 0-100, or a probability).
    /// @param _isSuccess True if the forecast is deemed successful, false otherwise.
    /// @param _evaluationProofHash An IPFS hash or similar pointing to the detailed oracle report/proof.
    function receiveOracleEvaluation(
        uint256 _forecastId,
        int256 _aiEvaluationScore,
        bool _isSuccess,
        string memory _evaluationProofHash
    ) external nonReentrant onlyTrustedOracle {
        InnovationForecast storage forecast = innovationForecasts[_forecastId];
        require(_forecastId > 0 && _forecastId <= forecastCounter, "Synthetikon: Invalid forecast ID");
        require(forecast.status == ForecastStatus.Evaluating, "Synthetikon: Forecast not in evaluating state");
        require(!forecast.isEvaluated, "Synthetikon: Forecast already evaluated");
        require(bytes(_evaluationProofHash).length > 0, "Synthetikon: Evaluation proof hash cannot be empty");

        forecast.isEvaluated = true;
        forecast.evaluationResult = _isSuccess;
        forecast.aiEvaluationScore = _aiEvaluationScore;
        forecast.evaluationProofHash = _evaluationProofHash;
        forecast.status = ForecastStatus.Completed;

        emit OracleEvaluationReceived(_forecastId, _aiEvaluationScore, _isSuccess, _evaluationProofHash);
    }

    /// @notice Processes the distribution of staked funds and updates reputation based on the forecast outcome.
    /// Can only be called after evaluation and only once.
    /// @param _forecastId The ID of the forecast to distribute rewards for.
    function distributeForecastRewards(uint256 _forecastId) external whenNotPaused nonReentrant onlyEvaluatedForecast(_forecastId) notDistributed(_forecastId) {
        InnovationForecast storage forecast = innovationForecasts[_forecastId];
        forecast.distributed = true;

        uint256 totalStakedFor = forecast.totalStakedFor;
        uint256 totalStakedAgainst = forecast.totalStakedAgainst;
        uint256 totalFundsInForecast = totalStakedFor.add(totalStakedAgainst);

        uint256 treasuryFee = totalFundsInForecast.mul(treasuryFeeShareBasisPoints).div(10000);
        treasuryBalance = treasuryBalance.add(treasuryFee);

        uint256 totalLoserPenalty = 0;
        address[] memory winnerStakers;
        address[] memory loserStakers;
        uint256 totalWinnerPoolForCalculation; // Total amount staked by the winning side

        if (forecast.evaluationResult) { // Forecast was a success
            winnerStakers = forecastStakersFor[_forecastId];
            loserStakers = forecastStakersAgainst[_forecastId];
            totalWinnerPoolForCalculation = totalStakedFor;
            totalLoserPenalty = totalStakedAgainst.mul(loserPenaltyShareBasisPoints).div(10000);
        } else { // Forecast was a failure
            winnerStakers = forecastStakersAgainst[_forecastId];
            loserStakers = forecastStakersFor[_forecastId];
            totalWinnerPoolForCalculation = totalStakedAgainst;
            totalLoserPenalty = totalStakedFor.mul(loserPenaltyShareBasisPoints).div(10000);
        }
        
        uint256 availableForWinners = totalFundsInForecast.sub(treasuryFee).sub(totalLoserPenalty);

        // Distribute to winners
        for (uint256 i = 0; i < winnerStakers.length; i++) {
            address staker = winnerStakers[i];
            bool stakedForSuccessDirection = forecast.evaluationResult; // True if forecast succeeded, implying staked for success
            if (!forecast.evaluationResult) stakedForSuccessDirection = false; // If forecast failed, winners staked for failure

            PredictionStake storage stake = userForecastStakes[_forecastId][staker][stakedForSuccessDirection];
            if (stake.amount > 0 && !stake.claimed) {
                uint224 share = uint224(availableForWinners.mul(stake.amount).div(totalWinnerPoolForCalculation)); // Cast to uint224
                userBalances[staker] = userBalances[staker].add(share);
                stake.claimed = true;
                _updateReputation(staker, 10); // Reward reputation for correct prediction
                emit WinningsCredited(_forecastId, staker);
            }
        }

        // Apply penalties to losers and mark as claimed. Loser penalties already added to treasury/winner pool.
        for (uint256 i = 0; i < loserStakers.length; i++) {
            address staker = loserStakers[i];
            bool stakedForSuccessDirection = !forecast.evaluationResult; // True if forecast succeeded, implying loser staked against success
            if (!forecast.evaluationResult) stakedForSuccessDirection = true; // If forecast failed, losers staked for success

            PredictionStake storage stake = userForecastStakes[_forecastId][staker][stakedForSuccessDirection];
            if (stake.amount > 0 && !stake.claimed) {
                stake.claimed = true;
                _updateReputation(staker, -5); // Penalize reputation for incorrect prediction
            }
        }

        // Proposer reputation update (e.g., if their forecast was successful)
        if (forecast.evaluationResult) {
            _updateReputation(forecast.proposer, 15); // Higher reward for successful proposal
        } else {
            _updateReputation(forecast.proposer, -7); // Penalty for failed proposal
        }

        totalStakedFundsAtRisk = totalStakedFundsAtRisk.sub(totalFundsInForecast);

        emit RewardsDistributed(_forecastId, availableForWinners, totalLoserPenalty, treasuryFee);
    }

    /// @notice Allows stakers to acknowledge their credited winnings from a successfully evaluated forecast.
    /// Funds are moved to the user's general `userBalances` by `distributeForecastRewards`.
    /// The actual token transfer to the user's wallet is handled by `withdrawUnstakedBalance`.
    /// This function acts as a confirmation that winnings are available internally.
    /// @param _forecastId The ID of the forecast to claim winnings from.
    function claimForecastWinnings(uint256 _forecastId) external view whenNotPaused {
        InnovationForecast storage forecast = innovationForecasts[_forecastId];
        require(forecast.isEvaluated && forecast.status == ForecastStatus.Completed, "Synthetikon: Forecast not evaluated or distributed.");
        
        bool userWasWinner = false;
        if (forecast.evaluationResult) {
            if (userForecastStakes[_forecastId][msg.sender][true].amount > 0 && userForecastStakes[_forecastId][msg.sender][true].claimed) {
                userWasWinner = true;
            }
        } else {
            if (userForecastStakes[_forecastId][msg.sender][false].amount > 0 && userForecastStakes[_forecastId][msg.sender][false].claimed) {
                userWasWinner = true;
            }
        }
        require(userWasWinner, "Synthetikon: Not a winning staker for this forecast or winnings already processed.");
        // Winnings are already credited to `userBalances` by `distributeForecastRewards`.
        // This function simply confirms the user had winnings for this forecast and they are ready for withdrawal.
    }


    /// @notice Allows users to withdraw any tokens they have deposited but are not currently staked.
    function withdrawUnstakedBalance() external whenNotPaused nonReentrant {
        uint252 amountToWithdraw = uint252(userBalances[msg.sender]);
        require(amountToWithdraw > 0, "Synthetikon: No unstaked balance to withdraw");

        userBalances[msg.sender] = 0;
        stakingToken.transfer(msg.sender, amountToWithdraw);
        emit UnstakedBalanceWithdrawn(msg.sender, amountToWithdraw);
    }

    /// @notice View function to retrieve all details of a specific innovation forecast.
    /// @param _forecastId The ID of the forecast.
    /// @return The InnovationForecast struct details.
    function getForecastDetails(uint256 _forecastId) external view returns (InnovationForecast memory) {
        require(_forecastId > 0 && _forecastId <= forecastCounter, "Synthetikon: Invalid forecast ID");
        return innovationForecasts[_forecastId];
    }

    // --- II. Reputation & Insight NFT System ---

    /// @notice Mints a unique Insight NFT to a recipient, typically awarded for exceptional predictive accuracy or successful forecast proposal.
    /// Can only be called by the contract owner (DAO).
    /// @param _recipient The address to mint the NFT to.
    /// @param _forecastId The ID of the forecast associated with this Insight NFT.
    /// @param _tokenURI The URI pointing to the NFT's metadata (e.g., IPFS hash).
    function mintInsightNFT(address _recipient, uint256 _forecastId, string memory _tokenURI) external onlyOwner whenNotPaused {
        uint256 nextId = insightNFT.getNextTokenId(); // Get next available ID from the NFT contract
        insightNFT.mint(_recipient, nextId, _tokenURI);
        emit InsightNFTMinted(_recipient, nextId, _forecastId, _tokenURI);
    }

    /// @notice View function to check a user's current reputation score.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /// @notice View function to retrieve a leaderboard of top predictors based on reputation.
    /// This implementation performs an on-chain sort, which is gas-intensive for large N.
    /// In a production dApp, a truly scalable leaderboard would typically be handled off-chain.
    /// @param _limit The maximum number of top predictors to return.
    /// @return An array of addresses and their corresponding reputation scores, sorted descending.
    function getTopPredictors(uint256 _limit) external view returns (address[] memory, uint256[] memory) {
        uint256 numHolders = _reputationHolders.length();
        if (numHolders == 0) {
            return (new address[](0), new uint256[](0));
        }

        uint256 effectiveLimit = _limit > numHolders ? numHolders : _limit;
        
        struct UserReputation {
            address user;
            uint252 score;
        }
        UserReputation[] memory allUsersReputation = new UserReputation[](numHolders);

        for (uint256 i = 0; i < numHolders; i++) {
            address user = _reputationHolders.at(i);
            allUsersReputation[i] = UserReputation(user, reputationScores[user]);
        }

        // Basic bubble sort for demonstration. Inefficient for large arrays.
        for (uint256 i = 0; i < numHolders; i++) {
            for (uint256 j = i + 1; j < numHolders; j++) {
                if (allUsersReputation[i].score < allUsersReputation[j].score) {
                    UserReputation memory temp = allUsersReputation[i];
                    allUsersReputation[i] = allUsersReputation[j];
                    allUsersReputation[j] = temp;
                }
            }
        }

        address[] memory topUsers = new address[](effectiveLimit);
        uint252[] memory topScores = new uint252[](effectiveLimit);

        for (uint256 i = 0; i < effectiveLimit; i++) {
            topUsers[i] = allUsersReputation[i].user;
            topScores[i] = allUsersReputation[i].score;
        }

        return (topUsers, topScores);
    }

    /// @notice Internal function to adjust a user's reputation score based on their prediction performance.
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _delta The amount to add or subtract from the reputation score. Can be negative.
    function _updateReputation(address _user, int256 _delta) internal {
        uint252 currentScore = reputationScores[_user];
        if (_delta > 0) {
            reputationScores[_user] = uint252(currentScore.add(uint256(_delta)));
        } else {
            uint256 absDelta = uint256(_delta * -1);
            if (currentScore > absDelta) {
                reputationScores[_user] = uint252(currentScore.sub(absDelta));
            } else {
                reputationScores[_user] = 0;
            }
        }
        
        if (reputationScores[_user] > 0) {
            _reputationHolders.add(_user);
        } else {
            _reputationHolders.remove(_user); // Remove if reputation drops to 0
        }
        emit ReputationUpdated(_user, _delta, reputationScores[_user]);
    }

    // --- III. DAO Governance & System Parameters ---

    /// @notice Allows users (with sufficient reputation) to propose changes to contract parameters or logic.
    /// @param _proposalDescription A clear description of the proposed change.
    /// @param _calldata AABI-encoded calldata for the function call to be executed if the proposal passes.
    /// @param _targetContract The address of the contract that will receive the function call (often `address(this)`).
    function proposeGovernanceChange(
        string memory _proposalDescription,
        bytes memory _calldata,
        address _targetContract
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(reputationScores[msg.sender] >= daoVoteMinReputation, "Synthetikon: Insufficient reputation to propose");
        require(bytes(_proposalDescription).length > 0, "Synthetikon: Proposal description cannot be empty");
        require(_targetContract != address(0), "Synthetikon: Target contract cannot be zero address");
        require(_calldata.length > 0, "Synthetikon: Calldata cannot be empty");

        governanceProposalCounter++;
        uint256 newProposalId = governanceProposalCounter;

        governanceProposals[newProposalId] = GovernanceProposal({
            proposer: msg.sender,
            description: _proposalDescription,
            calldataPayload: _calldata,
            targetContract: _targetContract,
            voteStartTime: uint252(block.timestamp),
            voteEndTime: uint252(block.timestamp.add(7 days)), // 7 days voting period for example
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty map
            status: ProposalStatus.Active,
            requiredReputation: uint252(daoVoteMinReputation)
        });

        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _proposalDescription);
        return newProposalId;
    }

    /// @notice Users vote on active governance proposals. Voting power is tied to reputation.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(_proposalId > 0 && _proposalId <= governanceProposalCounter, "Synthetikon: Invalid proposal ID");
        require(proposal.status == ProposalStatus.Active, "Synthetikon: Proposal is not active for voting");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Synthetikon: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Synthetikon: Already voted on this proposal");
        require(reputationScores[msg.sender] >= proposal.requiredReputation, "Synthetikon: Insufficient reputation to vote");
        
        proposal.hasVoted[msg.sender] = true;
        uint252 voteWeight = reputationScores[msg.sender];
        require(voteWeight > 0, "Synthetikon: Cannot vote with zero reputation.");

        if (_support) {
            proposal.votesFor = uint252(proposal.votesFor.add(voteWeight));
        } else {
            proposal.votesAgainst = uint252(proposal.votesAgainst.add(voteWeight));
        }

        emit VoteCast(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    /// @notice Executes a successfully passed governance proposal. Only callable after voting period ends.
    /// @param _proposalId The ID of the proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(_proposalId > 0 && _proposalId <= governanceProposalCounter, "Synthetikon: Invalid proposal ID");
        require(proposal.status == ProposalStatus.Active, "Synthetikon: Proposal is not active for execution");
        require(block.timestamp > proposal.voteEndTime, "Synthetikon: Voting period not ended yet");
        require(proposal.votesFor > proposal.votesAgainst, "Synthetikon: Proposal did not pass");

        proposal.status = ProposalStatus.Succeeded; // Mark as succeeded before execution attempt

        (bool success, ) = proposal.targetContract.call(proposal.calldataPayload);
        require(success, "Synthetikon: Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice DAO-governed function to adjust the default evaluation period for new forecasts.
    /// @param _newPeriodDays The new default evaluation period in days.
    function setForecastEvaluationPeriod(uint256 _newPeriodDays) external onlyOwner whenNotPaused {
        require(_newPeriodDays > 0, "Synthetikon: Evaluation period must be greater than zero");
        defaultEvaluationPeriodDays = _newPeriodDays;
        emit ParameterUpdated("defaultEvaluationPeriodDays", _newPeriodDays);
    }

    /// @notice DAO-governed function to update the percentages for reward distribution, penalties, and treasury fees.
    /// @param _winnerShareBasisPoints Percentage of total staked for winners (e.g., 8000 for 80%).
    /// @param _loserPenaltyBasisPoints Percentage of staked amount lost by losers (e.g., 2000 for 20%).
    /// @param _treasuryFeeBasisPoints Percentage of total staked funds that goes to treasury (e.g., 500 for 5%).
    function setRewardDistributionFactors(
        uint256 _winnerShareBasisPoints,
        uint256 _loserPenaltyBasisPoints,
        uint256 _treasuryFeeBasisPoints
    ) external onlyOwner whenNotPaused {
        require(_winnerShareBasisPoints.add(_treasuryFeeBasisPoints) <= 10000, "Synthetikon: Invalid reward/fee shares sum");
        require(_loserPenaltyBasisPoints <= 10000, "Synthetikon: Invalid loser penalty");

        winnerRewardShareBasisPoints = _winnerShareBasisPoints;
        loserPenaltyShareBasisPoints = _loserPenaltyBasisPoints;
        treasuryFeeShareBasisPoints = _treasuryFeeShareBasisPoints;
        
        emit ParameterUpdated("winnerRewardShareBasisPoints", _winnerShareBasisPoints);
        emit ParameterUpdated("loserPenaltyShareBasisPoints", _loserPenaltyBasisPoints);
        emit ParameterUpdated("treasuryFeeShareBasisPoints", _treasuryFeeBasisPoints);
    }

    /// @notice DAO-governed function to update the trusted oracle contract address.
    /// @param _newOracle The address of the new trusted oracle contract.
    function setOracleAddress(address _newOracle) external onlyOwner whenNotPaused {
        require(_newOracle != address(0), "Synthetikon: New oracle address cannot be zero");
        trustedOracle = _newOracle;
        emit ParameterUpdated("trustedOracle", uint256(uint160(_newOracle))); // Cast address to uint256 for event
    }

    /// @notice DAO-governed function to set the minimum amount required to stake on a forecast.
    /// @param _newAmount The new minimum stake amount.
    function setMinimumStakeAmount(uint256 _newAmount) external onlyOwner whenNotPaused {
        minimumStakeAmount = _newAmount;
        emit ParameterUpdated("minimumStakeAmount", _newAmount);
    }

    /// @notice DAO-governed function to pause critical contract functionalities in case of an emergency.
    function pauseSystem() external onlyOwner {
        _pause();
        emit SystemPaused(msg.sender);
    }

    /// @notice DAO-governed function to unpause the system.
    function unpauseSystem() external onlyOwner {
        _unpause();
        emit SystemUnpaused(msg.sender);
    }

    // --- IV. Treasury Management & ERC20 Interactions ---

    /// @notice Allows users to deposit tokens into their internal balance within the contract, making them available for staking.
    /// @param _amount The amount of tokens to deposit.
    function depositTokens(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Synthetikon: Deposit amount must be greater than zero");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        userBalances[msg.sender] = userBalances[msg.sender].add(_amount);
    }

    /// @notice DAO-governed function to withdraw funds from the contract's treasury.
    /// These funds typically come from fees or penalties.
    /// @param _recipient The address to send the treasury funds to.
    /// @param _amount The amount of tokens to withdraw from the treasury.
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Synthetikon: Withdrawal amount must be greater than zero");
        require(treasuryBalance >= _amount, "Synthetikon: Insufficient funds in treasury");
        require(_recipient != address(0), "Synthetikon: Recipient cannot be zero address");

        treasuryBalance = treasuryBalance.sub(_amount);
        stakingToken.transfer(_recipient, _amount);
        emit UnstakedBalanceWithdrawn(_recipient, _amount); // Re-use event for treasury for simplicity
    }
    
    // --- Helper Views ---
    
    /// @notice Returns the total current balance of the staking token held by this contract.
    function getContractStakingTokenBalance() external view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }
    
    /// @notice Returns the total number of governance proposals submitted.
    function getGovernanceProposalCount() external view returns (uint256) {
        return governanceProposalCounter;
    }
}
```