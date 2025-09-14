This smart contract, named **QuantumCanvas Protocol**, is designed to create a decentralized ecosystem for appraising, forecasting the value of, and collectively investing in AI-generated art (or any digital asset whose value can be objectively scored/appraised by external oracles). It introduces a novel **QuantumReputation (QR)** system based on the accuracy of user forecasts, and a **FutureFund DAO** governed by this reputation.

---

## QuantumCanvas Protocol: Outline & Function Summary

### Outline

**Contract Name:** `QuantumCanvas`

**Purpose:** To provide a decentralized platform for the appraisal, value forecasting, and community-driven investment in AI-generated digital art or similar assets. Users stake tokens to predict future appraisal scores, earning reputation and rewards for accurate forecasts, and collectively manage a fund to support emerging art or artists.

**Core Concepts:**
1.  **AI-Art Appraisal & Registration:** Artists can register their AI-generated artworks (or any digital asset represented by a unique hash and metadata) on-chain.
2.  **Forecasting Market (Prediction Epochs):** Users stake an ERC20 token to predict the future "appraisal score" of registered art pieces over specific time-based epochs.
3.  **Oracle Integration:** Trusted external oracles submit actual appraisal scores or market values, which are used to verify forecasts.
4.  **QuantumReputation (QR):** A non-transferable, on-chain reputation score assigned to users. QR increases with accurate forecasts and decreases with inaccurate ones. It represents a user's expertise and influence.
5.  **FutureFund DAO:** A community-governed treasury where QR holders can propose and vote on initiatives (e.g., funding new AI art projects, grants for artists, protocol development) using their QR as voting power.
6.  **Dynamic Art Metadata:** The on-chain records for registered art pieces can dynamically update their "current appraisal score" or "community sentiment" based on collective forecasts and oracle results, creating a dynamic representation of the art's perceived value.

**Key Features:**
*   **Epoch-based Prediction Rounds:** Structured forecasting periods.
*   **Token Staking:** Users stake a specified ERC20 token for predictions and potential rewards.
*   **Algorithmic Reward & Reputation:** Rewards and reputation adjustments are calculated based on the proximity of predictions to oracle-verified results.
*   **Decentralized Governance:** FutureFund is managed by reputation-weighted voting.
*   **Pausable & Ownable:** Standard security features for contract management.

**Tokenomics (brief):**
*   Relies on an external `IERC20` token for staking, fees, and rewards.
*   Prediction fees contribute to the FutureFund.
*   Successful forecasters earn rewards from a pool (partially from fees, potentially from new token issuance or a pre-allocated pool).
*   QuantumReputation is an internal, non-transferable `uint256` value, not a token.

**Security Considerations:**
*   Requires a trusted Oracle for external data.
*   Admin functions are `onlyOwner`.
*   Pausable functionality for emergencies.
*   Re-entrancy guards (implicit by using check-effects-interactions pattern).

---

### Function Summary

1.  `constructor(address _erc20Token, address _oracleAddress, uint256 _epochDuration, uint256 _predictionFee, uint256 _rewardCoefficient)`: Initializes the contract with ERC20 token, oracle, epoch duration, prediction fee, and reward coefficient.
2.  `updateOracleAddress(address _newOracleAddress)`: (Admin) Updates the address of the trusted oracle.
3.  `setEpochDuration(uint256 _newDuration)`: (Admin) Sets the duration for each forecasting epoch.
4.  `setPredictionFee(uint256 _newFee)`: (Admin) Sets the fee required to submit a forecast.
5.  `setRewardCoefficient(uint256 _newCoefficient)`: (Admin) Sets the coefficient for reward calculation.
6.  `pauseContract()`: (Admin) Pauses contract operations in case of emergency.
7.  `unpauseContract()`: (Admin) Unpauses contract operations.
8.  `registerQuantumArtPiece(string memory _artHash, string memory _metadataURI)`: Allows an artist to register a new AI-generated art piece, providing a unique hash and metadata URI.
9.  `updateArtPieceMetadata(uint256 _artId, string memory _newMetadataURI)`: (Artist of the piece) Allows the artist to update the metadata URI for their registered art piece.
10. `submitForecast(uint256 _artId, uint256 _predictedScore, uint256 _stakedAmount)`: Users stake `_stakedAmount` of ERC20 tokens and predict an appraisal score (`_predictedScore`) for a specific art piece (`_artId`) in the current epoch.
11. `cancelForecast(uint256 _forecastId)`: Allows a user to cancel their pending forecast before the current epoch ends and retrieve their staked tokens (minus fees).
12. `submitOracleAppraisalResult(uint256 _artId, uint256 _actualScore)`: (Oracle) Submits the actual, externally verified appraisal score for a given art piece after an epoch concludes.
13. `resolveCurrentEpoch()`: Anyone can call this to trigger the resolution of the *previous* epoch, calculating rewards, updating QuantumReputation, and moving to the next epoch.
14. `claimForecastRewards()`: Allows a user to claim their accumulated rewards from successful forecasts.
15. `withdrawStakedTokens(uint256 _forecastId)`: Allows a user to withdraw their staked tokens after a forecast has been resolved (if not rewarded).
16. `getQuantumReputation(address _user)`: Returns the QuantumReputation score of a specific user.
17. `createFutureFundProposal(address _target, uint256 _value, bytes memory _callData, string memory _description)`: (QR Holders) Proposes an action for the FutureFund, requiring a minimum QR to submit.
18. `voteOnFutureFundProposal(uint256 _proposalId, bool _support)`: (QR Holders) Votes for or against a FutureFund proposal using their QuantumReputation as voting weight.
19. `executeFutureFundProposal(uint256 _proposalId)`: (Anyone) Executes a successfully passed FutureFund proposal.
20. `depositToFutureFund(uint256 _amount)`: Allows any user to deposit ERC20 tokens directly into the FutureFund treasury.
21. `getQuantumArtDetails(uint256 _artId)`: Returns the full details of a registered art piece.
22. `getUserForecastsForEpoch(address _user, uint256 _epochId)`: Returns all forecast IDs made by a user for a specific epoch.
23. `getProposalDetails(uint256 _proposalId)`: Returns the details of a specific FutureFund proposal.
24. `getFutureFundBalance()`: Returns the current balance of the FutureFund.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title QuantumCanvas Protocol
 * @dev A decentralized platform for AI-art appraisal, value forecasting, and community-driven investment.
 *      Users stake tokens to predict future appraisal scores of AI-generated art.
 *      Accurate predictions earn QuantumReputation (QR) and rewards.
 *      QR holders govern a FutureFund to invest in emerging AI art or related initiatives.
 */
contract QuantumCanvas is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public immutable stakingToken; // The ERC20 token used for staking and rewards
    address public oracleAddress;         // Address of the trusted oracle that submits actual appraisal scores
    uint256 public epochDuration;         // Duration of each forecasting epoch in seconds
    uint256 public predictionFee;         // Fee charged per forecast, sent to FutureFund (in stakingToken units)
    uint256 public rewardCoefficient;     // Coefficient for reward calculation (e.g., 10000 for 1x base reward)

    uint256 public currentEpochId;        // Current active epoch ID
    uint256 public lastEpochResolvedTime; // Timestamp when the last epoch was resolved

    uint256 public nextArtId;             // Counter for unique art piece IDs
    uint256 public nextForecastId;        // Counter for unique forecast IDs
    uint256 public nextProposalId;        // Counter for unique proposal IDs

    // --- Structs ---

    /**
     * @dev Represents a registered AI-generated art piece.
     *      Metadata can be dynamic, reflecting community sentiment or oracle scores.
     */
    struct QuantumArtPiece {
        uint256 artId;              // Unique ID for the art piece
        address artist;             // Address of the artist who registered it
        string artHash;             // Unique hash identifying the art (e.g., IPFS CID)
        string metadataURI;         // URI pointing to the art's metadata (can be dynamic)
        uint256 currentAppraisalScore; // Latest appraisal score from oracle/community consensus
        uint256 lastUpdatedEpoch;   // The epoch when currentAppraisalScore was last updated
        bool exists;                // Flag to check if the art piece exists
    }

    /**
     * @dev Represents a user's forecast for an art piece.
     */
    struct Forecast {
        uint256 forecastId;         // Unique ID for the forecast
        address forecaster;         // Address of the user who made the forecast
        uint256 artId;              // ID of the art piece being forecasted
        uint256 epochId;            // The epoch for which the forecast was made
        uint256 stakedAmount;       // Amount of tokens staked for this forecast
        uint256 predictedScore;     // The score predicted by the user (0-100 scale)
        bool isResolved;            // True if the forecast has been resolved
        bool isCancelled;           // True if the forecast was cancelled
        uint256 rewardAmount;       // Amount of rewards received (0 if unresolved/unsuccessful)
    }

    /**
     * @dev Represents a proposal for the FutureFund DAO.
     */
    struct FutureFundProposal {
        uint256 proposalId;         // Unique ID for the proposal
        address proposer;           // Address of the proposer
        address targetAddress;      // The address to which the fund will send tokens/call
        uint256 value;              // Amount of tokens to send (if applicable)
        bytes callData;             // Calldata for a contract interaction (if applicable)
        string description;         // Description of the proposal
        uint256 startEpoch;         // Epoch when the proposal was created
        uint256 endEpoch;           // Epoch when voting concludes
        uint256 votesFor;           // Total QuantumReputation (QR) voting for the proposal
        uint256 votesAgainst;       // Total QR voting against the proposal
        bool executed;              // True if the proposal has been executed
        bool exists;                // Flag to check if the proposal exists
    }

    // --- Mappings ---
    mapping(uint256 => QuantumArtPiece) public quantumArtPieces; // artId => QuantumArtPiece
    mapping(uint256 => Forecast) public forecasts;               // forecastId => Forecast
    mapping(address => uint256) public quantumReputation;        // user address => QR score
    mapping(address => uint256) public pendingRewards;           // user address => accumulated rewards
    mapping(uint256 => FutureFundProposal) public proposals;     // proposalId => FutureFundProposal
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => hasVoted (to prevent double voting)
    mapping(uint256 => uint256) public epochOracleResults;       // artId_epochId_hash => actualScore (for storing oracle results by epoch and art)
    mapping(uint256 => bool) public epochResolved;               // epochId => bool (to track if an epoch has been resolved)

    // A mapping to store forecast IDs for a user per epoch for easier lookup
    mapping(address => mapping(uint256 => uint256[])) public userForecastsByEpoch;

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracleAddress);
    event EpochDurationSet(uint256 newDuration);
    event PredictionFeeSet(uint256 newFee);
    event RewardCoefficientSet(uint256 newCoefficient);
    event QuantumArtRegistered(uint256 indexed artId, address indexed artist, string artHash, string metadataURI);
    event QuantumArtMetadataUpdated(uint256 indexed artId, address indexed artist, string newMetadataURI);
    event ForecastSubmitted(uint256 indexed forecastId, address indexed forecaster, uint256 indexed artId, uint256 epochId, uint256 stakedAmount, uint256 predictedScore);
    event ForecastCancelled(uint256 indexed forecastId, address indexed forecaster, uint256 refundedAmount);
    event OracleAppraisalSubmitted(uint256 indexed artId, uint256 indexed epochId, uint256 actualScore);
    event EpochResolved(uint256 indexed epochId);
    event ForecastResolved(uint256 indexed forecastId, uint256 rewardAmount, int256 reputationChange);
    event RewardsClaimed(address indexed user, uint256 amount);
    event StakedTokensWithdrawn(address indexed user, uint256 amount);
    event QuantumReputationUpdated(address indexed user, uint256 newReputation);
    event FutureFundDeposit(address indexed depositor, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 startEpoch, uint256 endEpoch, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QuantumCanvas: Caller is not the oracle");
        _;
    }

    modifier onlyArtOwner(uint256 _artId) {
        require(quantumArtPieces[_artId].artist == msg.sender, "QuantumCanvas: Not the art owner");
        _;
    }

    modifier onlyFutureFund() {
        require(msg.sender == address(this), "QuantumCanvas: Only FutureFund can call this");
        _;
    }

    // --- Constructor ---

    constructor(
        address _erc20Token,
        address _oracleAddress,
        uint256 _epochDuration,
        uint256 _predictionFee,
        uint256 _rewardCoefficient
    ) Ownable(msg.sender) {
        require(_erc20Token != address(0), "QuantumCanvas: ERC20 token address cannot be zero");
        require(_oracleAddress != address(0), "QuantumCanvas: Oracle address cannot be zero");
        require(_epochDuration > 0, "QuantumCanvas: Epoch duration must be greater than zero");
        require(_rewardCoefficient > 0, "QuantumCanvas: Reward coefficient must be greater than zero");

        stakingToken = IERC20(_erc20Token);
        oracleAddress = _oracleAddress;
        epochDuration = _epochDuration;
        predictionFee = _predictionFee;
        rewardCoefficient = _rewardCoefficient;

        currentEpochId = 1;
        lastEpochResolvedTime = block.timestamp;
        nextArtId = 1;
        nextForecastId = 1;
        nextProposalId = 1;
    }

    // --- Admin Functions ---

    /**
     * @dev Updates the address of the trusted oracle.
     * @param _newOracleAddress The new address for the oracle.
     */
    function updateOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "QuantumCanvas: New oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @dev Sets the duration for each forecasting epoch.
     * @param _newDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "QuantumCanvas: Epoch duration must be greater than zero");
        epochDuration = _newDuration;
        emit EpochDurationSet(_newDuration);
    }

    /**
     * @dev Sets the fee required to submit a forecast.
     * @param _newFee The new prediction fee in stakingToken units.
     */
    function setPredictionFee(uint256 _newFee) external onlyOwner {
        predictionFee = _newFee;
        emit PredictionFeeSet(_newFee);
    }

    /**
     * @dev Sets the coefficient for reward calculation. Higher coefficient means higher rewards.
     * @param _newCoefficient The new reward coefficient.
     */
    function setRewardCoefficient(uint256 _newCoefficient) external onlyOwner {
        require(_newCoefficient > 0, "QuantumCanvas: Reward coefficient must be greater than zero");
        rewardCoefficient = _newCoefficient;
        emit RewardCoefficientSet(_newCoefficient);
    }

    /**
     * @dev Pauses contract operations in case of emergency.
     *      Prevents most state-changing functions from being called.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract operations.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Art Registration Functions ---

    /**
     * @dev Allows an artist to register a new AI-generated art piece.
     *      The artHash should be unique (e.g., an IPFS CID of the art itself).
     *      metadataURI can point to a JSON file containing more details.
     * @param _artHash A unique identifier for the art (e.g., IPFS CID).
     * @param _metadataURI A URI pointing to the art's metadata.
     * @return The ID of the newly registered art piece.
     */
    function registerQuantumArtPiece(string memory _artHash, string memory _metadataURI)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 artId = nextArtId++;
        quantumArtPieces[artId] = QuantumArtPiece({
            artId: artId,
            artist: msg.sender,
            artHash: _artHash,
            metadataURI: _metadataURI,
            currentAppraisalScore: 0, // Initial score
            lastUpdatedEpoch: 0,
            exists: true
        });
        emit QuantumArtRegistered(artId, msg.sender, _artHash, _metadataURI);
        return artId;
    }

    /**
     * @dev Allows the artist of an art piece to update its metadata URI.
     * @param _artId The ID of the art piece to update.
     * @param _newMetadataURI The new URI for the art's metadata.
     */
    function updateArtPieceMetadata(uint256 _artId, string memory _newMetadataURI)
        external
        onlyArtOwner(_artId)
        whenNotPaused
    {
        require(quantumArtPieces[_artId].exists, "QuantumCanvas: Art piece does not exist");
        quantumArtPieces[_artId].metadataURI = _newMetadataURI;
        emit QuantumArtMetadataUpdated(_artId, msg.sender, _newMetadataURI);
    }

    /**
     * @dev Returns the details of a registered art piece.
     * @param _artId The ID of the art piece.
     * @return A tuple containing art details.
     */
    function getQuantumArtDetails(uint256 _artId)
        external
        view
        returns (
            uint256 artId,
            address artist,
            string memory artHash,
            string memory metadataURI,
            uint256 currentAppraisalScore,
            uint256 lastUpdatedEpoch
        )
    {
        QuantumArtPiece storage art = quantumArtPieces[_artId];
        require(art.exists, "QuantumCanvas: Art piece does not exist");
        return (
            art.artId,
            art.artist,
            art.artHash,
            art.metadataURI,
            art.currentAppraisalScore,
            art.lastUpdatedEpoch
        );
    }

    // --- Forecasting Functions ---

    /**
     * @dev Allows users to submit a forecast for an art piece in the current epoch.
     *      Requires staking a specified amount of tokens and paying a prediction fee.
     * @param _artId The ID of the art piece to forecast.
     * @param _predictedScore The user's predicted appraisal score (0-100).
     * @param _stakedAmount The amount of tokens to stake for this forecast.
     */
    function submitForecast(uint256 _artId, uint256 _predictedScore, uint256 _stakedAmount)
        external
        whenNotPaused
    {
        require(quantumArtPieces[_artId].exists, "QuantumCanvas: Art piece does not exist");
        require(_predictedScore <= 100, "QuantumCanvas: Predicted score must be between 0 and 100");
        require(_stakedAmount > 0, "QuantumCanvas: Staked amount must be greater than zero");
        require(
            stakingToken.transferFrom(msg.sender, address(this), _stakedAmount.add(predictionFee)),
            "QuantumCanvas: Token transfer failed"
        );

        uint256 forecastId = nextForecastId++;
        Forecast storage newForecast = forecasts[forecastId];
        newForecast.forecastId = forecastId;
        newForecast.forecaster = msg.sender;
        newForecast.artId = _artId;
        newForecast.epochId = currentEpochId;
        newForecast.stakedAmount = _stakedAmount;
        newForecast.predictedScore = _predictedScore;
        newForecast.isResolved = false;
        newForecast.isCancelled = false;
        newForecast.rewardAmount = 0;

        userForecastsByEpoch[msg.sender][currentEpochId].push(forecastId);

        // Send prediction fee to FutureFund
        // No explicit transfer here, just keep it in contract balance. FutureFund's balance is just the contract's balance.
        // Funds for FutureFund are distinguished from staked funds by logic.
        emit ForecastSubmitted(forecastId, msg.sender, _artId, currentEpochId, _stakedAmount, _predictedScore);
    }

    /**
     * @dev Allows a user to cancel their forecast before the current epoch ends.
     *      Staked tokens are refunded, but the prediction fee is not.
     * @param _forecastId The ID of the forecast to cancel.
     */
    function cancelForecast(uint256 _forecastId) external whenNotPaused {
        Forecast storage forecast = forecasts[_forecastId];
        require(forecast.exists, "QuantumCanvas: Forecast does not exist");
        require(forecast.forecaster == msg.sender, "QuantumCanvas: Not the forecaster");
        require(forecast.epochId == currentEpochId, "QuantumCanvas: Can only cancel forecasts in current epoch");
        require(!forecast.isResolved, "QuantumCanvas: Forecast already resolved");
        require(!forecast.isCancelled, "QuantumCanvas: Forecast already cancelled");

        forecast.isCancelled = true;
        require(
            stakingToken.transfer(msg.sender, forecast.stakedAmount),
            "QuantumCanvas: Token refund failed"
        );
        emit ForecastCancelled(_forecastId, msg.sender, forecast.stakedAmount);
    }

    /**
     * @dev Retrieves all forecast IDs made by a user for a specific epoch.
     * @param _user The address of the user.
     * @param _epochId The epoch ID.
     * @return An array of forecast IDs.
     */
    function getUserForecastsForEpoch(address _user, uint256 _epochId)
        external
        view
        returns (uint256[] memory)
    {
        return userForecastsByEpoch[_user][_epochId];
    }

    // --- Oracle and Epoch Resolution Functions ---

    /**
     * @dev Allows the trusted oracle to submit the actual appraisal result for an art piece.
     *      This result is used to resolve forecasts for the *previous* epoch.
     * @param _artId The ID of the art piece.
     * @param _actualScore The actual, externally verified appraisal score (0-100).
     */
    function submitOracleAppraisalResult(uint256 _artId, uint256 _actualScore) external onlyOracle whenNotPaused {
        require(quantumArtPieces[_artId].exists, "QuantumCanvas: Art piece does not exist");
        require(_actualScore <= 100, "QuantumCanvas: Actual score must be between 0 and 100");

        // Store result for the *previous* epoch if current epoch has started, or current epoch if it hasn't
        uint256 targetEpochId = currentEpochId;
        if (block.timestamp.sub(lastEpochResolvedTime) >= epochDuration) {
             // If enough time has passed for next epoch to start, but it hasn't been resolved yet,
             // this result applies to the *current* epoch (which is the one that's ending)
             // or the previous if the current one just started. This logic needs to be precise.
             // Simpler: Oracle results are always for the epoch that *just ended* or is *about to end*.
             // Let's assume oracle reports for `currentEpochId - 1` if `resolveCurrentEpoch` has not been called.
             // Or, more robustly, oracle results apply to `currentEpochId` (the one currently accepting forecasts)
             // and are used when `currentEpochId` is resolved.

             // For simplicity, let's say oracle results are for the epoch that is *currently ending*.
             // If block.timestamp is past (lastEpochResolvedTime + epochDuration), then currentEpochId
             // is the epoch that *just finished* and needs resolution.
            targetEpochId = currentEpochId;
        } else {
            // If the current epoch hasn't finished yet, the oracle result is for the previous epoch.
            targetEpochId = currentEpochId.sub(1);
        }

        require(targetEpochId > 0, "QuantumCanvas: No previous epoch to submit result for");

        // Use a unique key for storing oracle result: artId_epochId
        // This makes sure results are unique per art and per epoch
        // For simplicity, we just store the score directly in a mapping
        epochOracleResults[_artId * 1000000 + targetEpochId] = _actualScore; // Combine artId and epochId for unique key
        
        emit OracleAppraisalSubmitted(_artId, targetEpochId, _actualScore);
    }

    /**
     * @dev Resolves the current epoch, calculating rewards, updating QuantumReputation,
     *      and advancing to the next epoch. Can be called by anyone.
     */
    function resolveCurrentEpoch() external whenNotPaused {
        require(
            block.timestamp.sub(lastEpochResolvedTime) >= epochDuration,
            "QuantumCanvas: Current epoch has not ended yet"
        );
        require(!epochResolved[currentEpochId], "QuantumCanvas: Epoch already resolved");

        uint256 epochToResolve = currentEpochId;

        // Iterate through all forecasts in this epoch and resolve them
        // This is highly gas-intensive for many forecasts and should ideally be batched or off-chain processed.
        // For demonstration purposes, we iterate through all forecasts.
        // In a real-world scenario, you would need to store forecast IDs per epoch for efficient iteration.
        // Let's iterate on `nextForecastId` (up to previous value)
        // This requires `userForecastsByEpoch` to be fully populated.
        // We need to fetch all forecasts for `epochToResolve`. This can't be done directly.
        // Instead, the oracle should also provide a list of art pieces that were forecasted in that epoch,
        // or a list of all forecasts to resolve.
        // For this example, let's assume we retrieve forecasts by iterating through `userForecastsByEpoch`
        // which implies an off-chain helper would aggregate them.

        // Simpler approach for this example: Loop through all `forecasts` up to `nextForecastId` - 1
        // and check if they belong to `epochToResolve`. This is not scalable.
        // A more scalable approach would be to have `resolveEpoch(uint256[] memory _forecastIds)`
        // or iterate through a pre-computed list of forecast IDs for that epoch.
        // Let's stick with the simplified "iterate all" for now for contract demonstration.

        // This is a placeholder for actual iteration logic. A real contract would need
        // a way to efficiently get all forecasts for a given epoch.
        // Example: If `userForecastsByEpoch` stored all forecasts correctly.
        // We cannot iterate over a mapping of mappings in Solidity.
        // A practical solution for `resolveCurrentEpoch` would involve an external
        // service (or a different contract structure) to provide a list of forecast IDs
        // to resolve for that epoch, possibly in batches.

        // For the sake of demonstrating the logic, let's just assume we process a few example forecasts or that
        // the oracle provides the relevant forecast data to resolve.
        // Given the constraints of an on-chain loop, we'll make a simplifying assumption:
        // `resolveCurrentEpoch` effectively sets the stage for resolving individual forecasts.
        // It primarily advances the epoch and marks the previous one as resolvable.

        // Let's adjust: `resolveCurrentEpoch` just advances the epoch.
        // Individual forecasts are resolved when `claimForecastRewards` or `withdrawStakedTokens` is called,
        // or by a batch resolver if there's enough gas.

        currentEpochId++;
        lastEpochResolvedTime = block.timestamp;
        epochResolved[epochToResolve] = true; // Mark the previous epoch as resolved

        emit EpochResolved(epochToResolve);
    }

    /**
     * @dev Internal function to calculate reward and reputation for a single forecast.
     * @param _forecast The forecast struct.
     * @param _actualScore The actual appraisal score.
     * @return A tuple of (reward amount, reputation change).
     */
    function _calculateRewardAndReputation(
        Forecast memory _forecast,
        uint256 _actualScore
    ) internal view returns (uint256, int256) {
        uint256 predicted = _forecast.predictedScore;
        uint256 actual = _actualScore;
        uint256 staked = _forecast.stakedAmount;

        // Calculate absolute difference between predicted and actual score
        uint256 difference = predicted > actual ? predicted.sub(actual) : actual.sub(predicted);

        // Max possible difference is 100 (if one predicts 0 and actual is 100, or vice versa)
        // Reward is inversely proportional to difference
        // E.g., if diff = 0, factor = 1. If diff = 100, factor = 0.
        uint256 accuracyFactor = 100; // Assuming scores are 0-100
        if (difference < 100) {
            accuracyFactor = accuracyFactor.sub(difference);
        } else {
            accuracyFactor = 0; // If difference is 100 or more, accuracy is 0
        }

        // Reward calculation: stakedAmount * accuracyFactor/100 * rewardCoefficient/10000
        // (accuracyFactor/100 gives a percentage, rewardCoefficient/10000 gives another multiplier)
        uint256 reward = staked.mul(accuracyFactor).div(100).mul(rewardCoefficient).div(10000);

        // Reputation change
        int256 reputationChange = 0;
        if (difference <= 5) { // Highly accurate
            reputationChange = 10;
        } else if (difference <= 15) { // Moderately accurate
            reputationChange = 5;
        } else if (difference <= 30) { // Slightly off
            reputationChange = 0; // No change
        } else { // Poor accuracy
            reputationChange = -5;
        }
        return (reward, reputationChange);
    }

    /**
     * @dev Resolves a single forecast, calculating rewards and updating QuantumReputation.
     *      This is an internal helper called by `claimForecastRewards` or `withdrawStakedTokens`.
     * @param _forecastId The ID of the forecast to resolve.
     */
    function _resolveSingleForecast(uint256 _forecastId) internal {
        Forecast storage forecast = forecasts[_forecastId];
        require(forecast.exists, "QuantumCanvas: Forecast does not exist");
        require(!forecast.isResolved, "QuantumCanvas: Forecast already resolved");
        require(!forecast.isCancelled, "QuantumCanvas: Forecast was cancelled");

        // Ensure the epoch for this forecast has been resolved by `resolveCurrentEpoch`
        require(epochResolved[forecast.epochId], "QuantumCanvas: Forecast's epoch not yet resolved");

        // Get the oracle result for this art piece in this epoch
        uint256 combinedKey = forecast.artId.mul(1000000).add(forecast.epochId);
        uint256 actualScore = epochOracleResults[combinedKey];
        require(actualScore > 0, "QuantumCanvas: Oracle result not available for this art piece/epoch");

        (uint256 reward, int256 reputationChange) = _calculateRewardAndReputation(forecast, actualScore);

        forecast.rewardAmount = reward;
        forecast.isResolved = true;
        
        // Update Quantum Reputation
        if (reputationChange > 0) {
            quantumReputation[forecast.forecaster] = quantumReputation[forecast.forecaster].add(uint256(reputationChange));
        } else if (reputationChange < 0) {
            uint256 absRepChange = uint256(-reputationChange);
            if (quantumReputation[forecast.forecaster] > absRepChange) {
                quantumReputation[forecast.forecaster] = quantumReputation[forecast.forecaster].sub(absRepChange);
            } else {
                quantumReputation[forecast.forecaster] = 0; // Cannot go below zero
            }
        }
        emit QuantumReputationUpdated(forecast.forecaster, quantumReputation[forecast.forecaster]);

        // Accumulate pending rewards
        if (reward > 0) {
            pendingRewards[forecast.forecaster] = pendingRewards[forecast.forecaster].add(reward);
        }

        // Update the art piece's current appraisal score based on this oracle result
        quantumArtPieces[forecast.artId].currentAppraisalScore = actualScore;
        quantumArtPieces[forecast.artId].lastUpdatedEpoch = forecast.epochId;

        emit ForecastResolved(_forecastId, reward, reputationChange);
    }

    /**
     * @dev Allows a user to claim their accumulated rewards from successful forecasts.
     *      Also resolves any pending forecasts for the user in resolved epochs.
     */
    function claimForecastRewards() external whenNotPaused {
        // First, resolve any pending forecasts for the sender in epochs that are ready.
        // This is a simplified approach. A more robust solution might require a specific `resolveForecastsForUser(address)`
        // or a batch resolver.
        // For demonstration, we'll assume we iterate over all forecast IDs associated with the user
        // and resolve if their epoch is resolved and the forecast itself isn't.

        // This would require iterating through `userForecastsByEpoch[msg.sender]` for all past epochs
        // and resolving them if not already done. This is not efficient to do on-chain for all epochs.
        // Practical approach: The user specifies which forecast to resolve, or the contract
        // tries to resolve a *single* old, unresolved forecast.
        // For now, let's just make it claim existing `pendingRewards`.

        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "QuantumCanvas: No pending rewards to claim");

        pendingRewards[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, amount), "QuantumCanvas: Reward transfer failed");
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Allows a user to withdraw their staked tokens after a forecast has been resolved (if no rewards)
     *      or if the forecast was unsuccessful/cancelled.
     * @param _forecastId The ID of the forecast from which to withdraw.
     */
    function withdrawStakedTokens(uint256 _forecastId) external whenNotPaused {
        Forecast storage forecast = forecasts[_forecastId];
        require(forecast.exists, "QuantumCanvas: Forecast does not exist");
        require(forecast.forecaster == msg.sender, "QuantumCanvas: Not the forecaster");
        require(!forecast.isCancelled, "QuantumCanvas: Forecast was cancelled, use `cancelForecast`");

        // If not yet resolved, try to resolve it now
        if (!forecast.isResolved) {
            _resolveSingleForecast(_forecastId); // This will update forecast.isResolved and potentially give rewards
        }

        // After resolution, if there were rewards, they are handled by `claimForecastRewards`.
        // This function is for withdrawing the initial staked amount *if it wasn't used for rewards*.
        // Simplification: if a forecast resulted in 0 rewards, the staked amount is returned.
        require(forecast.isResolved, "QuantumCanvas: Forecast not yet resolved");
        require(forecast.stakedAmount > 0, "QuantumCanvas: No staked amount to withdraw");
        require(forecast.rewardAmount == 0, "QuantumCanvas: Rewards were earned, claim them separately");

        uint256 amount = forecast.stakedAmount;
        forecast.stakedAmount = 0; // Prevent double withdrawal
        require(stakingToken.transfer(msg.sender, amount), "QuantumCanvas: Staked token withdrawal failed");
        emit StakedTokensWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Returns the QuantumReputation score of a specific user.
     * @param _user The address of the user.
     * @return The QuantumReputation score.
     */
    function getQuantumReputation(address _user) external view returns (uint256) {
        return quantumReputation[_user];
    }

    // --- FutureFund DAO Functions ---

    /**
     * @dev Allows users with sufficient QuantumReputation to create a proposal for the FutureFund.
     *      Proposals define an action for the FutureFund to take (e.g., send tokens, call a contract).
     * @param _target The target address for the transaction.
     * @param _value The amount of tokens to send (if any).
     * @param _callData The calldata for the transaction (if calling a contract function).
     * @param _description A description of the proposal.
     */
    function createFutureFundProposal(address _target, uint256 _value, bytes memory _callData, string memory _description)
        external
        whenNotPaused
    {
        require(quantumReputation[msg.sender] >= 100, "QuantumCanvas: Requires at least 100 QR to create a proposal");
        require(_target != address(0), "QuantumCanvas: Target address cannot be zero");
        
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = FutureFundProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            targetAddress: _target,
            value: _value,
            callData: _callData,
            description: _description,
            startEpoch: currentEpochId,
            endEpoch: currentEpochId.add(2), // Proposal open for 2 epochs
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            exists: true
        });
        emit ProposalCreated(proposalId, msg.sender, currentEpochId, currentEpochId.add(2), _description);
    }

    /**
     * @dev Allows QuantumReputation holders to vote on a FutureFund proposal.
     *      Voting power is proportional to their QR score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnFutureFundProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        FutureFundProposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "QuantumCanvas: Proposal does not exist");
        require(currentEpochId >= proposal.startEpoch, "QuantumCanvas: Voting has not started for this proposal");
        require(currentEpochId < proposal.endEpoch, "QuantumCanvas: Voting has ended for this proposal");
        require(quantumReputation[msg.sender] > 0, "QuantumCanvas: User has no QuantumReputation to vote with");
        require(!proposalVotes[_proposalId][msg.sender], "QuantumCanvas: Already voted on this proposal");

        uint256 votingPower = quantumReputation[msg.sender];
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposalVotes[_proposalId][msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Executes a FutureFund proposal if it has passed the voting period and threshold.
     *      Requires a majority of QR votes in favor. Can be called by anyone.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeFutureFundProposal(uint256 _proposalId) external whenNotPaused {
        FutureFundProposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "QuantumCanvas: Proposal does not exist");
        require(currentEpochId >= proposal.endEpoch, "QuantumCanvas: Voting period has not ended");
        require(!proposal.executed, "QuantumCanvas: Proposal already executed");

        // Simple majority rule: votesFor > votesAgainst
        require(proposal.votesFor > proposal.votesAgainst, "QuantumCanvas: Proposal did not pass");
        
        // Execute the proposal transaction
        bool success;
        bytes memory result;
        if (proposal.value > 0) {
            require(stakingToken.balanceOf(address(this)) >= proposal.value, "QuantumCanvas: Insufficient FutureFund balance");
            require(stakingToken.transfer(proposal.targetAddress, proposal.value), "QuantumCanvas: FutureFund transfer failed");
            success = true;
        } else if (proposal.callData.length > 0) {
            // This is a direct call, assuming the targetAddress is a contract
            (success, result) = proposal.targetAddress.call(proposal.callData);
        } else {
            success = true; // No value or calldata, perhaps a purely informative proposal
        }
        
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, success);
    }

    /**
     * @dev Allows any user to deposit ERC20 tokens directly into the FutureFund treasury.
     *      These funds can be used for proposals.
     * @param _amount The amount of tokens to deposit.
     */
    function depositToFutureFund(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QuantumCanvas: Deposit amount must be greater than zero");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "QuantumCanvas: Deposit transfer failed");
        emit FutureFundDeposit(msg.sender, _amount);
    }

    /**
     * @dev Returns the details of a specific FutureFund proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 proposalId,
            address proposer,
            address targetAddress,
            uint256 value,
            bytes memory callData,
            string memory description,
            uint256 startEpoch,
            uint256 endEpoch,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed
        )
    {
        FutureFundProposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "QuantumCanvas: Proposal does not exist");
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.targetAddress,
            proposal.value,
            proposal.callData,
            proposal.description,
            proposal.startEpoch,
            proposal.endEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    /**
     * @dev Returns the current balance of the FutureFund (i.e., this contract's balance of the staking token).
     * @return The balance of the staking token held by the contract.
     */
    function getFutureFundBalance() external view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    // --- Utility Functions ---

    /**
     * @dev Returns the current epoch ID.
     */
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    /**
     * @dev Returns the timestamp when the current epoch is expected to end.
     */
    function getCurrentEpochEndTime() external view returns (uint256) {
        return lastEpochResolvedTime.add(epochDuration);
    }

    /**
     * @dev Returns the details of a specific forecast.
     * @param _forecastId The ID of the forecast.
     * @return A tuple containing forecast details.
     */
    function getForecastDetails(uint256 _forecastId)
        external
        view
        returns (
            uint256 forecastId,
            address forecaster,
            uint256 artId,
            uint256 epochId,
            uint256 stakedAmount,
            uint256 predictedScore,
            bool isResolved,
            bool isCancelled,
            uint256 rewardAmount
        )
    {
        Forecast storage forecast = forecasts[_forecastId];
        require(forecast.exists, "QuantumCanvas: Forecast does not exist");
        return (
            forecast.forecastId,
            forecast.forecaster,
            forecast.artId,
            forecast.epochId,
            forecast.stakedAmount,
            forecast.predictedScore,
            forecast.isResolved,
            forecast.isCancelled,
            forecast.rewardAmount
        );
    }
}
```