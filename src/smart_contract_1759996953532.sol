Here's a smart contract written in Solidity that embodies interesting, advanced, creative, and trendy concepts, focusing on decentralized AI model reputation and outcome prediction markets.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CognitoNexus: Decentralized AI Outcome Futures & Model Reputation
 * @author YourBlockchainDev (AI)
 * @dev This contract creates a novel platform where the performance and reputation of
 *      off-chain AI models are evaluated and managed on-chain through a system of
 *      "Outcome Futures" (prediction markets).
 *
 * Outline & Function Summary:
 *
 * I.   Core Structures & Enums:
 *      - `FutureStatus`: Enum to track the lifecycle of an Outcome Future.
 *      - `AIModel`: Struct holding metadata, stake, and reputation for registered AI models.
 *      - `OutcomeFuture`: Struct describing a prediction market based on an AI model's prediction.
 *
 * II.  Admin & Security Functions (7 functions):
 *      These functions manage core contract settings and security features.
 *      1.  `constructor()`: Initializes the contract with the payment token, primary oracle, and fee rate.
 *      2.  `pause()`: Pauses contract operations (owner only).
 *      3.  `unpause()`: Unpauses contract operations (owner only).
 *      4.  `setFeeRate(uint256 _newRate)`: Sets the platform's fee rate in basis points (owner only).
 *      5.  `setOracleAddress(address _newOracle)`: Sets the primary oracle address responsible for resolutions (owner only).
 *      6.  `withdrawProtocolFees(address _to)`: Withdraws accumulated protocol fees to a specified address (owner only).
 *      7.  `emergencyWithdrawTokens(IERC20 _token, address _to)`: Allows emergency withdrawal of non-payment tokens (owner only).
 *
 * III. AI Model Management (7 functions):
 *      Handles the registration, staking, and reputation tracking of AI models.
 *      8.  `registerAIModel(string memory _modelURI)`: Registers a new AI model with its off-chain URI.
 *      9.  `stakeOnAIModel(uint256 _modelId, uint256 _amount)`: Allows users to stake tokens endorsing an AI model.
 *      10. `unstakeFromAIModel(uint256 _modelId, uint256 _amount)`: Allows users to withdraw their stake from an AI model.
 *      11. `updateAIModelURI(uint256 _modelId, string memory _newURI)`: Updates the URI for a registered AI model (model owner only).
 *      12. `getAIModelDetails(uint256 _modelId)`: Retrieves comprehensive details about a registered AI model.
 *      13. `getUserAIModelStake(address _user, uint256 _modelId)`: Returns the amount a user has staked on a specific AI model.
 *      14. `getAIModelReputation(uint256 _modelId)`: Returns the current reputation score of an AI model.
 *
 * IV.  Outcome Future Management (9 functions):
 *      Facilitates the creation, participation, and resolution of prediction markets tied to AI models.
 *      15. `createOutcomeFuture(string memory _title, uint256 _aiModelId, uint256 _openUntil, uint256 _resolveBy, string[] memory _outcomeTitles, uint8 _predictedAIOutcomeIndex)`: Creates a new prediction market based on a specific AI model's stated prediction.
 *      16. `participateInFuture(uint256 _futureId, uint8 _outcomeIndex, uint256 _amount)`: Allows users to stake tokens on an outcome in a future.
 *      17. `resolveOutcomeFuture(uint256 _futureId, uint8 _actualOutcomeIndex)`: Resolves an Outcome Future, setting the actual outcome and updating the AI model's reputation (primary oracle only).
 *      18. `claimFutureWinnings(uint256 _futureId)`: Allows participants to claim their winnings from a resolved future.
 *      19. `getOutcomeFutureDetails(uint256 _futureId)`: Retrieves all details of a specific Outcome Future.
 *      20. `getFutureParticipantPrediction(uint256 _futureId, address _participant, uint8 _outcomeIndex)`: Returns a participant's staked amount on a specific outcome in a future.
 *      21. `getTotalAIModels()`: Returns the total count of registered AI models.
 *      22. `getTotalOutcomeFutures()`: Returns the total count of created Outcome Futures.
 *      23. `getFutureOutcomePool(uint256 _futureId, uint8 _outcomeIndex)`: Returns the total staked amount for a specific outcome in a future.
 *
 * Advanced Concepts & Creative Design:
 * - Decentralized AI Model Registry: While AI computation remains off-chain, the contract provides an on-chain registry for AI models, allowing users to discover and endorse them.
 * - AI Outcome Futures: This contract introduces a unique prediction market structure where markets are explicitly linked to a *specific prediction* made by a *registered AI model*. This enables direct evaluation of AI performance.
 * - Dynamic AI Model Reputation System: Each registered AI model maintains a reputation score that is dynamically updated based on the accuracy of its predictions in resolved Outcome Futures. This on-chain, verifiable reputation can foster trust and incentivise accurate AI development.
 * - Stake-based Endorsement: Users can "endorse" AI models by staking tokens, which could be integrated with future reward mechanisms for well-reputed models.
 * - Oracle-driven Resolution: Relies on a designated oracle to provide the definitive "actual outcome," linking real-world events to on-chain reputation updates.
 */
contract CognitoNexus is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken;
    address public primaryOracle; // The address designated to resolve future outcomes

    // Protocol fees
    uint256 public feeRate; // In basis points (e.g., 50 for 0.5%)
    uint256 public totalProtocolFeesCollected;

    // --- I. Core Structures & Enums ---

    enum FutureStatus {
        Open,                 // Predictions can be made
        ClosedForPredictions, // Predictions are closed, awaiting resolution
        Resolved,             // Outcome has been determined
        Canceled              // Future was canceled (e.g., due to unresolvable event)
    }

    struct AIModel {
        string uri;             // IPFS hash or URL pointing to model description/info
        address owner;          // Creator of the AI model entry
        uint256 stakedAmount;   // Total tokens staked on this model for general endorsement
        int256 reputation;      // Reputation score (can be negative, default 0)
        uint256 lastUpdate;     // Timestamp of last reputation update
        uint256 totalFuturesParticipated; // How many futures this model was part of
        uint256 totalCorrectPredictions;  // How many times its stated prediction was correct
    }

    struct OutcomeFuture {
        string title;                       // Description of the future/prediction market
        uint256 aiModelId;                  // The AI model this future is evaluating
        uint256 creationTime;               // Timestamp of creation
        uint256 openUntil;                  // Timestamp until which predictions can be made
        uint256 resolveBy;                  // Timestamp by which outcome MUST be resolved
        string[] outcomeTitles;             // e.g., ["Yes", "No", "Uncertain"]
        uint8 predictedAIOutcomeIndex;      // The outcome index the AI model itself predicted (as reported by future creator)
        mapping(uint8 => uint256) outcomePools; // Funds staked for each outcome index
        uint256 totalPool;                  // Total funds staked in this future
        uint8 actualOutcomeIndex;           // The resolved outcome (0 if not resolved, 1-N for actual outcome)
        FutureStatus status;                // Current status
        address oracle;                     // Oracle specifically assigned for this future (can be primaryOracle)
    }

    // --- State Variables ---

    uint256 public nextAIModelId;
    mapping(uint256 => AIModel) public aiModels;
    // userAIModelStakes is just for tracking model IDs a user has interacted with,
    // actual amounts are in userAIModelStakeAmounts
    mapping(address => uint256[]) public userAIModelStakes;
    mapping(address => mapping(uint256 => uint256)) public userAIModelStakeAmounts; // Amount user staked on specific model

    uint256 public nextFutureId;
    mapping(uint256 => OutcomeFuture) public outcomeFutures;
    mapping(uint256 => mapping(address => mapping(uint8 => uint256))) public futurePredictions; // futureId => user => outcomeIndex => amount
    mapping(uint256 => mapping(address => bool)) public hasClaimedWinnings; // futureId => user => claimed

    // --- Events ---

    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string uri);
    event AIModelStaked(uint256 indexed modelId, address indexed staker, uint256 amount);
    event AIModelUnstaked(uint256 indexed modelId, address indexed staker, uint256 amount);
    event AIModelReputationUpdated(uint256 indexed modelId, int256 newReputation, int256 reputationChange);

    event OutcomeFutureCreated(
        uint256 indexed futureId,
        string title,
        uint256 aiModelId,
        uint256 openUntil,
        uint8 predictedAIOutcomeIndex
    );
    event PredictionMade(
        uint256 indexed futureId,
        address indexed participant,
        uint8 indexed outcomeIndex,
        uint256 amount
    );
    event OutcomeFutureResolved(
        uint256 indexed futureId,
        uint8 actualOutcomeIndex,
        uint256 aiModelId,
        int256 reputationChange
    );
    event WinningsClaimed(uint256 indexed futureId, address indexed participant, uint256 amount);

    event FeeRateSet(uint256 newRate);
    event OracleSet(address indexed newOracle);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event EmergencyTokensWithdrawn(address indexed token, address indexed to, uint256 amount);

    // --- Modifiers ---

    modifier onlyPrimaryOracle() {
        require(msg.sender == primaryOracle, "CognitoNexus: Caller is not the primary oracle");
        _;
    }

    modifier onlyAIModelOwner(uint256 _modelId) {
        require(aiModels[_modelId].owner != address(0), "CognitoNexus: AI Model does not exist");
        require(aiModels[_modelId].owner == msg.sender, "CognitoNexus: Caller is not the AI model owner");
        _;
    }

    // --- II. Admin & Security Functions ---

    /**
     * @dev 1. Initializes the contract with the payment token address, an initial oracle, and fee rate.
     * @param _paymentToken The ERC20 token address used for all transactions within the contract.
     * @param _initialOracle The address of the initial trusted oracle for resolving outcomes.
     * @param _initialFeeRate The initial platform fee rate in basis points (e.g., 50 for 0.5%).
     */
    constructor(IERC20 _paymentToken, address _initialOracle, uint256 _initialFeeRate) Ownable(msg.sender) {
        require(address(_paymentToken) != address(0), "CognitoNexus: Invalid payment token address");
        require(_initialOracle != address(0), "CognitoNexus: Invalid initial oracle address");
        require(_initialFeeRate <= 10000, "CognitoNexus: Fee rate cannot exceed 100%"); // 10000 basis points

        paymentToken = _paymentToken;
        primaryOracle = _initialOracle;
        feeRate = _initialFeeRate;
        nextAIModelId = 1; // Start IDs from 1
        nextFutureId = 1;
    }

    /**
     * @dev 2. Pauses the contract. Only owner can call.
     *      No state-changing functions can be called while paused.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 3. Unpauses the contract. Only owner can call.
     *      Allows state-changing functions to be called again.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev 4. Sets the protocol fee rate. Only owner can call.
     * @param _newRate The new fee rate in basis points (e.g., 50 for 0.5%).
     */
    function setFeeRate(uint256 _newRate) public onlyOwner {
        require(_newRate <= 10000, "CognitoNexus: Fee rate cannot exceed 100%");
        feeRate = _newRate;
        emit FeeRateSet(_newRate);
    }

    /**
     * @dev 5. Sets the primary oracle address. Only owner can call.
     *      The primary oracle is responsible for resolving `OutcomeFuture`s.
     * @param _newOracle The address of the new primary oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "CognitoNexus: Invalid oracle address");
        primaryOracle = _newOracle;
        emit OracleSet(_newOracle);
    }

    /**
     * @dev 6. Withdraws accumulated protocol fees to a specified address. Only owner can call.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to) public onlyOwner nonReentrant {
        require(_to != address(0), "CognitoNexus: Invalid recipient address");
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "CognitoNexus: No fees to withdraw");

        totalProtocolFeesCollected = 0;
        paymentToken.safeTransfer(_to, amount);
        emit FeesWithdrawn(_to, amount);
    }

    /**
     * @dev 7. Emergency function to withdraw any unsupported ERC20 tokens accidentally sent to the contract.
     *      This should not be the primary payment token. Only owner can call.
     * @param _token The address of the token to withdraw.
     * @param _to The address to send the tokens to.
     */
    function emergencyWithdrawTokens(IERC20 _token, address _to) public onlyOwner nonReentrant {
        require(address(_token) != address(paymentToken), "CognitoNexus: Cannot withdraw payment token via emergency");
        require(_to != address(0), "CognitoNexus: Invalid recipient address");

        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "CognitoNexus: No tokens to withdraw");

        _token.safeTransfer(_to, balance);
        emit EmergencyTokensWithdrawn(address(_token), _to, balance);
    }

    // --- III. AI Model Management ---

    /**
     * @dev 8. Registers a new AI model with its off-chain URI.
     *      The creator of the model is recorded as its owner.
     * @param _modelURI A URI (e.g., IPFS hash, HTTPS URL) pointing to the model's description or data.
     * @return modelId The ID of the newly registered AI model.
     */
    function registerAIModel(string memory _modelURI) public whenNotPaused returns (uint256) {
        require(bytes(_modelURI).length > 0, "CognitoNexus: Model URI cannot be empty");

        uint256 modelId = nextAIModelId++;
        aiModels[modelId] = AIModel({
            uri: _modelURI,
            owner: msg.sender,
            stakedAmount: 0,
            reputation: 0, // Initial reputation is 0
            lastUpdate: block.timestamp,
            totalFuturesParticipated: 0,
            totalCorrectPredictions: 0
        });
        emit AIModelRegistered(modelId, msg.sender, _modelURI);
        return modelId;
    }

    /**
     * @dev 9. Allows users to stake payment tokens on an AI model to endorse its potential.
     *      This stake contributes to the model's overall endorsement amount and
     *      can be used for future rewards or governance weight.
     * @param _modelId The ID of the AI model to stake on.
     * @param _amount The amount of payment tokens to stake.
     */
    function stakeOnAIModel(uint256 _modelId, uint256 _amount) public whenNotPaused nonReentrant {
        require(aiModels[_modelId].owner != address(0), "CognitoNexus: AI Model does not exist");
        require(_amount > 0, "CognitoNexus: Stake amount must be greater than zero");

        paymentToken.safeTransferFrom(msg.sender, address(this), _amount);

        aiModels[_modelId].stakedAmount += _amount;
        userAIModelStakeAmounts[msg.sender][_modelId] += _amount;
        // Keep track of which models a user has staked on (for potential future queries, might be gas intensive if many)
        bool found = false;
        for (uint256 i = 0; i < userAIModelStakes[msg.sender].length; i++) {
            if (userAIModelStakes[msg.sender][i] == _modelId) {
                found = true;
                break;
            }
        }
        if (!found) {
            userAIModelStakes[msg.sender].push(_modelId);
        }

        emit AIModelStaked(_modelId, msg.sender, _amount);
    }

    /**
     * @dev 10. Allows users to unstake payment tokens from an AI model.
     * @param _modelId The ID of the AI model to unstake from.
     * @param _amount The amount of payment tokens to unstake.
     */
    function unstakeFromAIModel(uint256 _modelId, uint256 _amount) public whenNotPaused nonReentrant {
        require(aiModels[_modelId].owner != address(0), "CognitoNexus: AI Model does not exist");
        require(_amount > 0, "CognitoNexus: Unstake amount must be greater than zero");
        require(userAIModelStakeAmounts[msg.sender][_modelId] >= _amount, "CognitoNexus: Insufficient stake to unstake");

        aiModels[_modelId].stakedAmount -= _amount;
        userAIModelStakeAmounts[msg.sender][_modelId] -= _amount;

        paymentToken.safeTransfer(msg.sender, _amount);
        emit AIModelUnstaked(_modelId, msg.sender, _amount);
    }

    /**
     * @dev 11. Updates the off-chain URI for an AI model. Only the model's owner can call.
     * @param _modelId The ID of the AI model to update.
     * @param _newURI The new URI for the AI model.
     */
    function updateAIModelURI(uint256 _modelId, string memory _newURI) public whenNotPaused onlyAIModelOwner(_modelId) {
        require(bytes(_newURI).length > 0, "CognitoNexus: Model URI cannot be empty");
        aiModels[_modelId].uri = _newURI;
    }

    /**
     * @dev 12. Retrieves comprehensive details of a specific AI model.
     * @param _modelId The ID of the AI model.
     * @return uri The URI of the model.
     * @return owner The owner address of the model.
     * @return stakedAmount Total amount staked on this model.
     * @return reputation Current reputation score of the model.
     * @return lastUpdate Timestamp of the last reputation update.
     * @return totalFuturesParticipated Number of futures this model has been evaluated in.
     * @return totalCorrectPredictions Number of times its prediction was correct.
     */
    function getAIModelDetails(
        uint256 _modelId
    )
        public
        view
        returns (
            string memory uri,
            address owner,
            uint256 stakedAmount,
            int256 reputation,
            uint256 lastUpdate,
            uint256 totalFuturesParticipated,
            uint256 totalCorrectPredictions
        )
    {
        AIModel storage model = aiModels[_modelId];
        require(model.owner != address(0), "CognitoNexus: AI Model does not exist");
        return (
            model.uri,
            model.owner,
            model.stakedAmount,
            model.reputation,
            model.lastUpdate,
            model.totalFuturesParticipated,
            model.totalCorrectPredictions
        );
    }

    /**
     * @dev 13. Retrieves the amount a specific user has staked on an AI model.
     * @param _user The address of the user.
     * @param _modelId The ID of the AI model.
     * @return The amount staked by the user on the model.
     */
    function getUserAIModelStake(address _user, uint256 _modelId) public view returns (uint256) {
        return userAIModelStakeAmounts[_user][_modelId];
    }

    /**
     * @dev 14. Retrieves the current reputation score of an AI model.
     * @param _modelId The ID of the AI model.
     * @return The reputation score.
     */
    function getAIModelReputation(uint256 _modelId) public view returns (int256) {
        require(aiModels[_modelId].owner != address(0), "CognitoNexus: AI Model does not exist");
        return aiModels[_modelId].reputation;
    }

    // --- IV. Outcome Future Management ---

    /**
     * @dev 15. Creates a new Outcome Future (prediction market) based on a specific AI model's prediction.
     *      The creator defines the market title, the AI model being evaluated, the prediction window,
     *      the resolution deadline, the possible outcomes, and the AI model's specific predicted outcome for this future.
     *      This predicted AI outcome is crucial for the AI model's reputation tracking.
     * @param _title The descriptive title for the future.
     * @param _aiModelId The ID of the AI model whose prediction is being evaluated.
     * @param _openUntil Timestamp until which predictions can be made.
     * @param _resolveBy Timestamp by which the outcome must be resolved.
     * @param _outcomeTitles Array of strings describing possible outcomes (e.g., "Yes", "No", "Draw").
     * @param _predictedAIOutcomeIndex The index of the outcome that the AI model (as reported by creator) predicts.
     * @return futureId The ID of the newly created Outcome Future.
     */
    function createOutcomeFuture(
        string memory _title,
        uint256 _aiModelId,
        uint256 _openUntil,
        uint256 _resolveBy,
        string[] memory _outcomeTitles,
        uint8 _predictedAIOutcomeIndex
    ) public whenNotPaused returns (uint256) {
        require(aiModels[_aiModelId].owner != address(0), "CognitoNexus: AI Model does not exist");
        require(bytes(_title).length > 0, "CognitoNexus: Title cannot be empty");
        require(_openUntil > block.timestamp, "CognitoNexus: Open until must be in the future");
        require(_resolveBy > _openUntil, "CognitoNexus: Resolve by must be after open until");
        require(_outcomeTitles.length >= 2, "CognitoNexus: At least two outcomes required");
        require(
            _predictedAIOutcomeIndex < _outcomeTitles.length,
            "CognitoNexus: Invalid predicted AI outcome index"
        );

        uint256 futureId = nextFutureId++;
        outcomeFutures[futureId].title = _title;
        outcomeFutures[futureId].aiModelId = _aiModelId;
        outcomeFutures[futureId].creationTime = block.timestamp;
        outcomeFutures[futureId].openUntil = _openUntil;
        outcomeFutures[futureId].resolveBy = _resolveBy;
        outcomeFutures[futureId].outcomeTitles = _outcomeTitles;
        outcomeFutures[futureId].predictedAIOutcomeIndex = _predictedAIOutcomeIndex;
        outcomeFutures[futureId].totalPool = 0;
        outcomeFutures[futureId].actualOutcomeIndex = 0; // 0 indicates not resolved
        outcomeFutures[futureId].status = FutureStatus.Open;
        outcomeFutures[futureId].oracle = primaryOracle; // Default to primary oracle, could be overridden later

        // Increment the count of futures this AI model has participated in
        aiModels[_aiModelId].totalFuturesParticipated++;

        emit OutcomeFutureCreated(futureId, _title, _aiModelId, _openUntil, _predictedAIOutcomeIndex);
        return futureId;
    }

    /**
     * @dev 16. Allows a user to participate in an Outcome Future by staking tokens on a specific outcome.
     * @param _futureId The ID of the Outcome Future to participate in.
     * @param _outcomeIndex The index of the outcome the user is predicting.
     * @param _amount The amount of payment tokens to stake for this prediction.
     */
    function participateInFuture(
        uint256 _futureId,
        uint8 _outcomeIndex,
        uint256 _amount
    ) public whenNotPaused nonReentrant {
        OutcomeFuture storage future = outcomeFutures[_futureId];
        require(future.creationTime != 0, "CognitoNexus: Outcome Future does not exist");
        require(future.status == FutureStatus.Open, "CognitoNexus: Future is not open for predictions");
        require(block.timestamp <= future.openUntil, "CognitoNexus: Prediction window has closed");
        require(_outcomeIndex < future.outcomeTitles.length, "CognitoNexus: Invalid outcome index");
        require(_amount > 0, "CognitoNexus: Prediction amount must be greater than zero");

        paymentToken.safeTransferFrom(msg.sender, address(this), _amount);

        future.outcomePools[_outcomeIndex] += _amount;
        future.totalPool += _amount;
        futurePredictions[_futureId][msg.sender][_outcomeIndex] += _amount;

        emit PredictionMade(_futureId, msg.sender, _outcomeIndex, _amount);
    }

    /**
     * @dev 17. Resolves an Outcome Future, determining the actual outcome and updating AI model reputation.
     *      Only the primary oracle (or specific oracle for this future if implemented) can call this.
     *      The AI model's reputation is adjusted based on whether its `predictedAIOutcomeIndex` matches
     *      the `_actualOutcomeIndex`.
     * @param _futureId The ID of the Outcome Future to resolve.
     * @param _actualOutcomeIndex The index of the actual real-world outcome.
     */
    function resolveOutcomeFuture(uint256 _futureId, uint8 _actualOutcomeIndex) public onlyPrimaryOracle nonReentrant {
        OutcomeFuture storage future = outcomeFutures[_futureId];
        require(future.creationTime != 0, "CognitoNexus: Outcome Future does not exist");
        require(future.status == FutureStatus.Open || future.status == FutureStatus.ClosedForPredictions, "CognitoNexus: Future already resolved or canceled");
        // Ensure prediction window is closed before resolution
        if (block.timestamp > future.openUntil && future.status == FutureStatus.Open) {
            future.status = FutureStatus.ClosedForPredictions;
        }
        require(block.timestamp <= future.resolveBy, "CognitoNexus: Resolution deadline has passed");
        require(_actualOutcomeIndex < future.outcomeTitles.length, "CognitoNexus: Invalid actual outcome index");

        future.actualOutcomeIndex = _actualOutcomeIndex;
        future.status = FutureStatus.Resolved;

        // Calculate reputation change for the AI model based on its prediction accuracy
        int256 reputationChange = 0;
        // The magnitude of reputation change is proportional to the total value of the future
        // For example, 1 reputation point for every 100 paymentToken in the pool.
        uint256 reputationUnit = 1e16; // Corresponds to 0.01 tokens for calculation
        if (future.totalPool > 0) { // Avoid division by zero
             if (future.predictedAIOutcomeIndex == _actualOutcomeIndex) {
                reputationChange = int252(future.totalPool / reputationUnit); // Reputation increases
                aiModels[future.aiModelId].totalCorrectPredictions++;
            } else {
                reputationChange = -int252(future.totalPool / reputationUnit); // Reputation decreases
            }
        }
       
        AIModel storage model = aiModels[future.aiModelId];
        model.reputation += reputationChange;
        model.lastUpdate = block.timestamp; // Update last updated timestamp

        emit AIModelReputationUpdated(future.aiModelId, model.reputation, reputationChange);
        emit OutcomeFutureResolved(_futureId, _actualOutcomeIndex, future.aiModelId, reputationChange);
    }

    /**
     * @dev 18. Allows participants to claim their winnings from a resolved Outcome Future.
     *      Winnings are proportional to their stake in the winning outcome pool.
     *      A small fee is deducted from the gross winnings and collected by the protocol.
     * @param _futureId The ID of the Outcome Future.
     */
    function claimFutureWinnings(uint256 _futureId) public nonReentrant {
        OutcomeFuture storage future = outcomeFutures[_futureId];
        require(future.creationTime != 0, "CognitoNexus: Outcome Future does not exist");
        require(future.status == FutureStatus.Resolved, "CognitoNexus: Future is not resolved");
        require(!hasClaimedWinnings[_futureId][msg.sender], "CognitoNexus: Winnings already claimed");

        uint256 participantStakeInWinningOutcome = futurePredictions[_futureId][msg.sender][future.actualOutcomeIndex];
        require(participantStakeInWinningOutcome > 0, "CognitoNexus: No winning stake for this user");

        uint256 winningPool = future.outcomePools[future.actualOutcomeIndex];
        require(winningPool > 0, "CognitoNexus: No funds in winning pool to distribute");

        // Calculate gross winnings: (participant's stake / total winning pool) * total funds in the future
        uint256 grossWinnings = (participantStakeInWinningOutcome * future.totalPool) / winningPool;

        uint256 feeAmount = (grossWinnings * feeRate) / 10000; // feeRate is in basis points
        uint256 netWinnings = grossWinnings - feeAmount;

        totalProtocolFeesCollected += feeAmount; // Accumulate fees
        hasClaimedWinnings[_futureId][msg.sender] = true; // Mark as claimed

        paymentToken.safeTransfer(msg.sender, netWinnings);
        emit WinningsClaimed(_futureId, msg.sender, netWinnings);
    }

    /**
     * @dev 19. Retrieves detailed information about an Outcome Future.
     * @param _futureId The ID of the Outcome Future.
     * @return title The title of the future.
     * @return aiModelId The ID of the AI model being evaluated.
     * @return creationTime Timestamp of creation.
     * @return openUntil Timestamp until which predictions can be made.
     * @return resolveBy Timestamp by which resolution is due.
     * @return outcomeTitles Array of possible outcome titles.
     * @return predictedAIOutcomeIndex The AI model's predicted outcome index.
     * @return totalPool Total funds staked in the future.
     * @return actualOutcomeIndex The resolved outcome index (0 if not resolved).
     * @return status Current status of the future.
     * @return oracle The address of the oracle assigned to this future.
     */
    function getOutcomeFutureDetails(
        uint256 _futureId
    )
        public
        view
        returns (
            string memory title,
            uint256 aiModelId,
            uint256 creationTime,
            uint256 openUntil,
            uint256 resolveBy,
            string[] memory outcomeTitles,
            uint8 predictedAIOutcomeIndex,
            uint256 totalPool,
            uint8 actualOutcomeIndex,
            FutureStatus status,
            address oracle
        )
    {
        OutcomeFuture storage future = outcomeFutures[_futureId];
        require(future.creationTime != 0, "CognitoNexus: Outcome Future does not exist"); // Check if future exists
        return (
            future.title,
            future.aiModelId,
            future.creationTime,
            future.openUntil,
            future.resolveBy,
            future.outcomeTitles,
            future.predictedAIOutcomeIndex,
            future.totalPool,
            future.actualOutcomeIndex,
            future.status,
            future.oracle
        );
    }

    /**
     * @dev 20. Retrieves a specific participant's total staked amount for a given outcome in a future.
     * @param _futureId The ID of the Outcome Future.
     * @param _participant The address of the participant.
     * @param _outcomeIndex The index of the outcome.
     * @return The amount the participant staked on that specific outcome.
     */
    function getFutureParticipantPrediction(
        uint256 _futureId,
        address _participant,
        uint8 _outcomeIndex
    ) public view returns (uint256) {
        require(outcomeFutures[_futureId].creationTime != 0, "CognitoNexus: Outcome Future does not exist");
        return futurePredictions[_futureId][_participant][_outcomeIndex];
    }

    /**
     * @dev 21. Retrieves the total number of registered AI models.
     * @return The count of AI models.
     */
    function getTotalAIModels() public view returns (uint256) {
        return nextAIModelId - 1; // Assuming IDs start from 1
    }

    /**
     * @dev 22. Retrieves the total number of created Outcome Futures.
     * @return The count of Outcome Futures.
     */
    function getTotalOutcomeFutures() public view returns (uint256) {
        return nextFutureId - 1; // Assuming IDs start from 1
    }

    /**
     * @dev 23. Retrieves the total pool size for a specific outcome within an Outcome Future.
     * @param _futureId The ID of the Outcome Future.
     * @param _outcomeIndex The index of the outcome.
     * @return The total amount of tokens staked on the specified outcome.
     */
    function getFutureOutcomePool(uint256 _futureId, uint8 _outcomeIndex) public view returns (uint256) {
        require(outcomeFutures[_futureId].creationTime != 0, "CognitoNexus: Outcome Future does not exist");
        return outcomeFutures[_futureId].outcomePools[_outcomeIndex];
    }
}
```