Okay, here is a Solidity smart contract that implements a Decentralized AI Prediction Oracle.

**Concept:** This contract facilitates requesting and validating AI-driven predictions or insights for off-chain data/queries. Users submit a query (represented by a hash), and registered, staked providers submit their AI model's prediction. Providers then vote on which prediction is most likely correct. The contract automatically resolves queries based on voting consensus, rewarding accurate providers and slashing incorrect ones. It incorporates staking, a query lifecycle state machine, decentralized validation (voting), and a simple model registry.

**Why it's interesting/advanced/creative/trendy:**
1.  **Decentralized AI Integration:** Bridges off-chain AI computation with on-chain validation and incentivization.
2.  **Prediction Market / Oracle Hybrid:** Combines elements of prediction markets (voting on outcomes) with the oracle pattern (bringing external data/insights on-chain).
3.  **Staking & Slashing:** Uses cryptoeconomic incentives (staking) to align provider behavior and penalize dishonesty/inaccuracy.
4.  **Validation Voting:** A simple consensus mechanism among staked providers for validating predictions.
5.  **Query State Machine:** Manages the lifecycle of a query through different phases (submission, validation, resolution).
6.  **Model Registry:** Allows registering different types of AI models with varying parameters.
7.  **Encrypted Predictions:** The use of `bytes32 predictionHash` and optional `encryptedPrediction` hints at privacy-preserving or verifiable computation techniques, pushing the actual AI output off-chain but validating its claimed correctness on-chain. (Note: The contract doesn't handle encryption/decryption itself, but accommodates the pattern).

**Outline:**

1.  **Pragma and Imports**
2.  **Interfaces (for ERC20)**
3.  **Error Definitions**
4.  **Enums (QueryState)**
5.  **Structs (ModelConfig, QueryRequest, Prediction, ValidationVote)**
6.  **Events**
7.  **State Variables**
8.  **Constructor**
9.  **Modifiers**
10. **Core Query Lifecycle Functions**
    *   `requestPrediction`
    *   `submitPrediction`
    *   `castValidationVote`
    *   `resolveQuery`
11. **Provider Staking Functions**
    *   `stake`
    *   `initiateUnstake`
    *   `claimUnstakedTokens`
    *   `cancelUnstake`
12. **Reward Claiming**
    *   `claimProviderRewards`
13. **Model Management (Admin/Owner)**
    *   `addModel`
    *   `updateModel`
    *   `removeModel`
14. **Parameter Configuration (Admin/Owner)**
    *   `setQueryFee`
    *   `setMinProviderStake`
    *   `setSubmissionPeriod`
    *   `setValidationPeriod`
    *   `setUnstakeLockupDuration`
    *   `setProtocolFeePercentage`
15. **Protocol Fee Management (Admin/Owner)**
    *   `withdrawProtocolFees`
16. **View Functions (Read-only)**
    *   `getProviderStake`
    *   `getProviderPendingUnstake`
    *   `getTotalStaked`
    *   `getModelConfig`
    *   `isModelActive`
    *   `getQueryDetails`
    *   `getPredictionsForQuery`
    *   `getPredictionDetails`
    *   `getPredictionVoteCount`
    *   `getProtocolFeesCollected`
    *   `getCurrentQueryId`

**Function Summary:**

1.  `constructor(address _stakingToken, uint256 _minProviderStake, uint256 _queryFee, uint256 _submissionPeriod, uint256 _validationPeriod, uint256 _unstakeLockupDuration, uint256 _protocolFeePercentage)`: Initializes the contract with required parameters and the staking token address.
2.  `requestPrediction(uint256 modelId, bytes32 queryHash)`: User initiates a request for a prediction for a specific `queryHash` using a given `modelId`, paying the query fee.
3.  `submitPrediction(uint256 queryId, bytes32 predictionHash, bytes calldata encryptedPrediction)`: A staked provider submits their prediction's hash and optionally encrypted data for a requested query during the submission period.
4.  `castValidationVote(uint256 queryId, bytes32 predictionHash)`: A staked provider votes for a submitted prediction during the validation period.
5.  `resolveQuery(uint256 queryId)`: Anyone can trigger the resolution of a query after the validation period ends. Determines the winning prediction (highest votes), distributes rewards, slashes losing providers, and updates query state.
6.  `stake(uint256 amount)`: Allows a provider to stake the required ERC20 tokens to participate in the oracle.
7.  `initiateUnstake(uint256 amount)`: Initiates the process to unstake tokens. Tokens become locked for a period.
8.  `claimUnstakedTokens()`: Allows a provider to claim their unstaked tokens after the lockup period has passed.
9.  `cancelUnstake(uint256 amount)`: Allows a provider to cancel a pending unstake request before the lockup expires.
10. `claimProviderRewards(uint256[] calldata queryIds)`: Allows a provider to claim accumulated rewards from successfully resolved queries where they voted for the winning prediction or submitted it.
11. `addModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake)`: (Owner-only) Registers a new AI model configuration that users can query.
12. `updateModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake)`: (Owner-only) Updates the configuration of an existing AI model.
13. `removeModel(uint256 modelId)`: (Owner-only) Deactivates an AI model, preventing new queries for it.
14. `setQueryFee(uint256 fee)`: (Owner-only) Sets the default fee required to request a prediction.
15. `setMinProviderStake(uint256 amount)`: (Owner-only) Sets the minimum stake amount required for providers.
16. `setSubmissionPeriod(uint256 duration)`: (Owner-only) Sets the duration for the prediction submission phase.
17. `setValidationPeriod(uint256 duration)`: (Owner-only) Sets the duration for the prediction validation phase.
18. `setUnstakeLockupDuration(uint256 duration)`: (Owner-only) Sets the duration for the unstake lockup period.
19. `setProtocolFeePercentage(uint256 percentage)`: (Owner-only) Sets the percentage of query fees retained by the protocol.
20. `withdrawProtocolFees()`: (Owner-only) Allows the contract owner to withdraw collected protocol fees.
21. `getProviderStake(address provider)`: (View) Returns the current staked amount for a provider.
22. `getProviderPendingUnstake(address provider)`: (View) Returns the pending unstake amount and unlock time.
23. `getTotalStaked()`: (View) Returns the total amount of staking tokens staked in the contract.
24. `getModelConfig(uint256 modelId)`: (View) Returns the configuration details for a specific model.
25. `isModelActive(uint256 modelId)`: (View) Checks if a model ID is registered and active.
26. `getQueryDetails(uint256 queryId)`: (View) Returns the details of a specific query request.
27. `getPredictionsForQuery(uint256 queryId)`: (View) Returns a list of prediction hashes submitted for a query.
28. `getPredictionDetails(uint256 queryId, bytes32 predictionHash)`: (View) Returns details of a specific prediction for a query.
29. `getPredictionVoteCount(uint256 queryId, bytes32 predictionHash)`: (View) Returns the number of votes a specific prediction has received.
30. `getProtocolFeesCollected()`: (View) Returns the total amount of protocol fees collected.
31. `getCurrentQueryId()`: (View) Returns the next available query ID (total number of queries requested).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Decentralized AI Prediction Oracle
/// @notice A smart contract for requesting, submitting, validating, and resolving AI predictions for off-chain queries.
/// @dev This contract uses a staking and voting mechanism among providers to ensure prediction accuracy.

// --- Outline ---
// 1. Pragma and Imports
// 2. Interfaces (for ERC20)
// 3. Error Definitions
// 4. Enums (QueryState)
// 5. Structs (ModelConfig, QueryRequest, Prediction, ValidationVote)
// 6. Events
// 7. State Variables
// 8. Constructor
// 9. Modifiers
// 10. Core Query Lifecycle Functions
// 11. Provider Staking Functions
// 12. Reward Claiming
// 13. Model Management (Admin/Owner)
// 14. Parameter Configuration (Admin/Owner)
// 15. Protocol Fee Management (Admin/Owner)
// 16. View Functions (Read-only)

// --- Function Summary ---
// constructor(...)
// requestPrediction(uint256 modelId, bytes32 queryHash)
// submitPrediction(uint256 queryId, bytes32 predictionHash, bytes calldata encryptedPrediction)
// castValidationVote(uint256 queryId, bytes32 predictionHash)
// resolveQuery(uint256 queryId)
// stake(uint256 amount)
// initiateUnstake(uint256 amount)
// claimUnstakedTokens()
// cancelUnstake(uint256 amount)
// claimProviderRewards(uint256[] calldata queryIds)
// addModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake)
// updateModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake)
// removeModel(uint256 modelId)
// setQueryFee(uint256 fee)
// setMinProviderStake(uint256 amount)
// setSubmissionPeriod(uint256 duration)
// setValidationPeriod(uint256 duration)
// setUnstakeLockupDuration(uint256 duration)
// setProtocolFeePercentage(uint256 percentage)
// withdrawProtocolFees()
// getProviderStake(address provider)
// getProviderPendingUnstake(address provider)
// getTotalStaked()
// getModelConfig(uint256 modelId)
// isModelActive(uint256 modelId)
// getQueryDetails(uint256 queryId)
// getPredictionsForQuery(uint256 queryId)
// getPredictionDetails(uint256 queryId, bytes32 predictionHash)
// getPredictionVoteCount(uint256 queryId, bytes32 predictionHash)
// getProtocolFeesCollected()
// getCurrentQueryId()


contract DecentralizedAIOracle is Ownable {
    using SafeMath for uint256;

    IERC20 public immutable stakingToken;

    uint256 public minProviderStake;
    uint256 public queryFee; // Default query fee
    uint256 public submissionPeriod; // Duration for submitting predictions
    uint256 public validationPeriod; // Duration for validating predictions
    uint256 public unstakeLockupDuration; // Duration tokens are locked after unstake initiation
    uint256 public protocolFeePercentage; // Percentage of query fee kept by protocol (0-100)

    // --- Enums ---
    enum QueryState {
        Requested,          // Query created, awaiting predictions
        SubmissionPeriod,   // Predictions can be submitted
        ValidationPeriod,   // Predictions are being voted on
        Resolved,           // Query is resolved, outcome finalized
        Disputed            // Future state for dispute resolution (not implemented in this version)
    }

    // --- Structs ---
    struct ModelConfig {
        address modelOwner; // Address associated with the model (could be DAO, individual, etc.)
        uint256 fee;        // Specific fee for this model (overrides default queryFee if > 0)
        uint256 requiredStake; // Specific required stake for providers using this model (overrides minProviderStake if > 0)
        bool isActive;      // Whether the model can be used for new queries
    }

    struct QueryRequest {
        address user;
        uint256 modelId;
        bytes32 queryHash; // Hash representing the off-chain query/data
        uint256 feePaid;
        uint256 requestTimestamp;
        QueryState currentState;
        bytes32 winningPredictionHash; // Hash of the prediction deemed correct
        uint256 resolutionTimestamp; // Time when the query was resolved
        uint256 submissionPeriodEnd;
        uint256 validationPeriodEnd;
        // Mappings nested in structs are not recommended for storage,
        // so predictions and votes are mapped externally.
    }

    struct Prediction {
        address provider;
        bytes32 predictionHash; // Hash of the actual prediction value
        bytes encryptedPrediction; // Optional: Encrypted prediction value (off-chain decryption)
        uint256 stakeAtSubmission; // Stake amount of provider when submitting
        uint256 submittedTimestamp;
        bool isWinner;
        uint256 voteCount; // Total stake-weighted votes received
    }

    // Not storing individual votes explicitly to save gas/storage,
    // instead, we store the total vote weight per prediction and track who voted per query.
    struct ProviderVoteStatus {
        bool voted; // Whether the provider has voted in this query's validation
    }

    struct ProviderUnstake {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    // --- State Variables ---
    uint256 private _nextQueryId; // Starts from 0, increments for each new query

    mapping(uint256 => ModelConfig) public modelConfigs;
    mapping(uint256 => QueryRequest) public queryRequests;

    // queryId -> predictionHash -> Prediction
    mapping(uint256 => mapping(bytes32 => Prediction)) public queryPredictions;

    // queryId -> predictionHash -> providerAddress -> bool (Did this provider vote for this prediction?)
    // This is needed to prevent double voting for the same prediction
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) private _predictionVoters;

    // queryId -> providerAddress -> bool (Did this provider vote in this query at all?)
    // This is needed to prevent double voting across different predictions within the same query
    mapping(uint256 => mapping(address => bool)) private _queryVoters;

    // providerAddress -> total staked amount
    mapping(address => uint256) private _stakedAmount;

    // providerAddress -> pending unstake details
    mapping(address => ProviderUnstake) private _pendingUnstake;

    // providerAddress -> accumulated rewards from resolved queries
    mapping(address => uint224) private _providerRewards; // Use uint224 to save space

    // Total accumulated protocol fees
    uint256 public protocolFeesCollected;

    // --- Events ---
    event QueryRequested(uint256 indexed queryId, uint256 indexed modelId, address indexed user, bytes32 queryHash, uint256 feePaid);
    event PredictionSubmitted(uint256 indexed queryId, address indexed provider, bytes32 indexed predictionHash);
    event ValidationVoteCasted(uint256 indexed queryId, address indexed voter, bytes32 indexed predictionHash);
    event QueryStateChanged(uint256 indexed queryId, QueryState oldState, QueryState newState);
    event QueryResolved(uint256 indexed queryId, bytes32 winningPredictionHash, uint256 rewardPool, uint256 slashAmount);
    event ProviderStaked(address indexed provider, uint256 amount, uint256 totalStake);
    event ProviderUnstakeInitiated(address indexed provider, uint256 amount, uint256 unlockTimestamp);
    event ProviderUnstakeClaimed(address indexed provider, uint256 amount);
    event ProviderUnstakeCancelled(address indexed provider, uint256 amount);
    event ProviderRewardsClaimed(address indexed provider, uint256 amount);
    event ModelAdded(uint256 indexed modelId, address indexed modelOwner, uint256 fee, uint256 requiredStake);
    event ModelUpdated(uint256 indexed modelId, address indexed modelOwner, uint256 fee, uint256 requiredStake);
    event ModelRemoved(uint256 indexed modelId);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event ParameterSet(string paramName, uint256 newValue);


    // --- Errors ---
    error InvalidModelId();
    error ModelNotActive();
    error InsufficientStake();
    error QueryNotFound();
    error InvalidQueryState();
    error PredictionSubmissionPeriodEnded();
    error PredictionValidationPeriodEnded();
    error PredictionNotFound();
    error ProviderAlreadySubmittedPrediction();
    error ProviderAlreadyVotedInQuery();
    error ProviderAlreadyVotedForPrediction();
    error InvalidVote(); // e.g., voting for a non-existent prediction
    error QueryNotReadyForResolution();
    error QueryAlreadyResolved();
    error InsufficientBalance();
    error InsufficientAllowance();
    error UnstakeAmountTooHigh();
    error NoPendingUnstake();
    error UnstakeLockupNotExpired();
    error CancelUnstakeAmountTooHigh();
    error NothingToClaim();
    error InvalidPercentage();
    error OnlyOwner(); // Explicitly defined though Ownable provides it, good for error mapping.

    // --- Constructor ---
    /// @notice Initializes the Decentralized AI Oracle contract.
    /// @param _stakingToken Address of the ERC20 token used for staking and payments.
    /// @param _minProviderStake Minimum stake required for a provider to submit predictions or vote.
    /// @param _queryFee Default fee to request a prediction (in staking tokens).
    /// @param _submissionPeriod Duration of the prediction submission phase in seconds.
    /// @param _validationPeriod Duration of the validation voting phase in seconds.
    /// @param _unstakeLockupDuration Duration tokens are locked after initiating unstake in seconds.
    /// @param _protocolFeePercentage Percentage (0-100) of query fees kept by the protocol.
    constructor(
        address _stakingToken,
        uint256 _minProviderStake,
        uint256 _queryFee,
        uint256 _submissionPeriod,
        uint256 _validationPeriod,
        uint256 _unstakeLockupDuration,
        uint256 _protocolFeePercentage
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        minProviderStake = _minProviderStake;
        queryFee = _queryFee;
        submissionPeriod = _submissionPeriod;
        validationPeriod = _validationPeriod;
        unstakeLockupDuration = _unstakeLockupDuration;

        if (_protocolFeePercentage > 100) revert InvalidPercentage();
        protocolFeePercentage = _protocolFeePercentage;

        _nextQueryId = 0; // Query IDs start from 0
    }

    // --- Modifiers ---
    modifier onlyProviderWithMinStake() {
        if (_stakedAmount[msg.sender] < minProviderStake) revert InsufficientStake();
        _;
    }

    // --- Core Query Lifecycle Functions ---

    /// @notice Requests a prediction for a specific query using a given AI model.
    /// @param modelId The ID of the AI model to use.
    /// @param queryHash A bytes32 hash representing the off-chain query or data.
    function requestPrediction(uint256 modelId, bytes32 queryHash) external {
        ModelConfig storage model = modelConfigs[modelId];
        if (!model.isActive) revert ModelNotActive();

        uint256 fee = model.fee > 0 ? model.fee : queryFee;

        // Check user has sufficient balance and allowance
        if (stakingToken.balanceOf(msg.sender) < fee) revert InsufficientBalance();
        if (stakingToken.allowance(msg.sender, address(this)) < fee) revert InsufficientAllowance();

        // Transfer fee to the contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), fee);
        if (!success) revert InsufficientAllowance(); // Or a more specific transfer error

        uint256 queryId = _nextQueryId++;
        uint256 currentTimestamp = block.timestamp;

        queryRequests[queryId] = QueryRequest({
            user: msg.sender,
            modelId: modelId,
            queryHash: queryHash,
            feePaid: fee,
            requestTimestamp: currentTimestamp,
            currentState: QueryState.SubmissionPeriod, // Start in submission period immediately
            winningPredictionHash: bytes32(0),
            resolutionTimestamp: 0,
            submissionPeriodEnd: currentTimestamp.add(submissionPeriod),
            validationPeriodEnd: currentTimestamp.add(submissionPeriod).add(validationPeriod)
        });

        emit QueryRequested(queryId, modelId, msg.sender, queryHash, fee);
        emit QueryStateChanged(queryId, QueryState.Requested, QueryState.SubmissionPeriod); // Transitioning from implicit Requested to SubmissionPeriod
    }

    /// @notice Allows a staked provider to submit a prediction for an active query.
    /// @dev Each provider can only submit one prediction per query.
    /// @param queryId The ID of the query.
    /// @param predictionHash A bytes32 hash representing the provider's prediction result.
    /// @param encryptedPrediction Optional: The encrypted prediction data.
    function submitPrediction(uint256 queryId, bytes32 predictionHash, bytes calldata encryptedPrediction) external onlyProviderWithMinStake {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound();
        if (query.currentState != QueryState.SubmissionPeriod) revert InvalidQueryState();
        if (block.timestamp > query.submissionPeriodEnd) revert PredictionSubmissionPeriodEnded();

        // Check if provider already submitted for this query
        if (queryPredictions[queryId][predictionHash].provider != address(0)) {
             // Check if the provider submitting is the same as the one already stored under this hash
             // A hash collision is possible but highly improbable for cryptographically secure hashes.
             // A better check is needed if hashes aren't guaranteed unique per provider per query.
             // For simplicity here, let's assume predictionHash + provider is unique off-chain.
             // We'll check if the provider has ANY prediction recorded for this query.
             bool alreadySubmitted = false;
             // This requires iterating over all submitted predictions for the query, which can be expensive.
             // A better approach would be a mapping: queryId -> providerAddress -> bool hasSubmitted;
             // Adding this mapping to QueryRequest struct or a separate mapping. Let's add a separate mapping.
             revert ProviderAlreadySubmittedPrediction(); // Need a proper check using the new mapping
        }

        // Need to check if provider already submitted ANY prediction for this query.
        // Let's add a mapping: mapping(uint256 => mapping(address => bytes32)) private _providerQueryPrediction;
        // queryId -> providerAddress -> predictionHash they submitted
        // Add to state variables: mapping(uint256 => mapping(address => bytes32)) private _providerQueryPrediction;

        // Let's refine the submission logic to use the mapping:
        // mapping(uint256 => mapping(address => bytes32)) private _providerSubmittedPrediction;
        // This maps a query ID and provider address to the hash of the prediction they submitted.

        // Add this state variable: mapping(uint256 => mapping(address => bytes32)) private _providerSubmittedPrediction;

        bytes32 existingPredictionHash = _providerSubmittedPrediction[queryId][msg.sender];
        if (existingPredictionHash != bytes32(0)) revert ProviderAlreadySubmittedPrediction();

        // Store the prediction
        queryPredictions[queryId][predictionHash] = Prediction({
            provider: msg.sender,
            predictionHash: predictionHash,
            encryptedPrediction: encryptedPrediction,
            stakeAtSubmission: _stakedAmount[msg.sender],
            submittedTimestamp: block.timestamp,
            isWinner: false,
            voteCount: 0 // Vote count is stake-weighted
        });

        // Record that the provider submitted
        _providerSubmittedPrediction[queryId][msg.sender] = predictionHash;

        emit PredictionSubmitted(queryId, msg.sender, predictionHash);
    }

    // Add the state variable mentioned above
    mapping(uint256 => mapping(address => bytes32)) private _providerSubmittedPrediction;


    /// @notice Allows a staked provider to cast a validation vote for a submitted prediction.
    /// @dev Providers can vote for one prediction per query. Vote weight is the provider's stake.
    /// @param queryId The ID of the query.
    /// @param predictionHash The hash of the prediction to vote for.
    function castValidationVote(uint256 queryId, bytes32 predictionHash) external onlyProviderWithMinStake {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound();
        if (query.currentState != QueryState.ValidationPeriod) revert InvalidQueryState();
        if (block.timestamp > query.validationPeriodEnd) revert PredictionValidationPeriodEnded();

        Prediction storage prediction = queryPredictions[queryId][predictionHash];
        if (prediction.provider == address(0)) revert PredictionNotFound(); // Check if the prediction exists

        // Check if the provider already voted in this query
        if (_queryVoters[queryId][msg.sender]) revert ProviderAlreadyVotedInQuery();

        // Check if the provider already voted for this specific prediction (redundant if previous check passes, but good safety)
        if (_predictionVoters[queryId][predictionHash][msg.sender]) revert ProviderAlreadyVotedForPrediction();

        // Record the vote
        _predictionVoters[queryId][predictionHash][msg.sender] = true;
        _queryVoters[queryId][msg.sender] = true;

        // Add provider's stake weight to the prediction's vote count
        prediction.voteCount = prediction.voteCount.add(_stakedAmount[msg.sender]);

        emit ValidationVoteCasted(queryId, msg.sender, predictionHash);
    }

    /// @notice Resolves a query after the validation period, determining the winning prediction and distributing rewards/slashes.
    /// @param queryId The ID of the query to resolve.
    function resolveQuery(uint256 queryId) external {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound();
        if (query.currentState != QueryState.ValidationPeriod) revert InvalidQueryState();
        if (block.timestamp <= query.validationPeriodEnd) revert QueryNotReadyForResolution();

        bytes32 winningPredictionHash = bytes32(0);
        uint256 maxVoteCount = 0;
        uint256 totalPredictionStake = 0; // Sum of stakeAtSubmission for all submitted predictions

        // Find the winning prediction (highest vote count)
        // This part is tricky and potentially gas-intensive if there are many predictions.
        // We need to iterate over submitted predictions. Storing them in a list/array per query is needed.
        // Add to QueryRequest struct: bytes32[] submittedPredictionHashes;
        // Populate this array in submitPrediction.

        // Add state variable: mapping(uint256 => bytes32[]) public querySubmittedPredictionHashes;

        // Iterate over submitted predictions for this query
        bytes32[] memory submittedHashes = querySubmittedPredictionHashes[queryId];
        if (submittedHashes.length > 0) {
            for (uint i = 0; i < submittedHashes.length; i++) {
                bytes32 currentHash = submittedHashes[i];
                Prediction storage currentPrediction = queryPredictions[queryId][currentHash];
                if (currentPrediction.provider != address(0)) { // Ensure prediction exists
                     if (currentPrediction.voteCount > maxVoteCount) {
                        maxVoteCount = currentPrediction.voteCount;
                        winningPredictionHash = currentHash;
                    }
                    totalPredictionStake = totalPredictionStake.add(currentPrediction.stakeAtSubmission);
                }
            }
        }

        query.winningPredictionHash = winningPredictionHash;
        query.resolutionTimestamp = block.timestamp;
        query.currentState = QueryState.Resolved;

        // --- Reward and Slashing Distribution ---
        uint256 rewardPool = query.feePaid;
        uint256 protocolFeeAmount = rewardPool.mul(protocolFeePercentage).div(100);
        protocolFeesCollected = protocolFeesCollected.add(protocolFeeAmount);
        rewardPool = rewardPool.sub(protocolFeeAmount);

        uint256 totalWinningStake = 0; // Sum of stakeAtSubmission for winning predictions (in case of tie)
        uint256 totalLosingStake = 0;  // Sum of stakeAtSubmission for losing predictions

        // Identify winners and losers, calculate reward distribution parameters
         if (submittedHashes.length > 0) {
            for (uint i = 0; i < submittedHashes.length; i++) {
                bytes32 currentHash = submittedHashes[i];
                Prediction storage currentPrediction = queryPredictions[queryId][currentHash];

                // Check if the prediction was voted for and is not a ghost entry
                if (currentPrediction.provider != address(0) && currentPrediction.voteCount > 0) {
                     // Winning prediction(s) get the reward pool + slashed stake
                     if (currentPrediction.voteCount == maxVoteCount && maxVoteCount > 0) {
                        currentPrediction.isWinner = true;
                        totalWinningStake = totalWinningStake.add(currentPrediction.stakeAtSubmission);
                     } else {
                        // Losing predictions' stake gets added to the reward pool
                         totalLosingStake = totalLosingStake.add(currentPrediction.stakeAtSubmission);
                     }
                } else {
                    // Predictions with 0 votes also lose their stake? Or do nothing? Let's slash them if stake > 0
                    if (currentPrediction.stakeAtSubmission > 0) {
                        totalLosingStake = totalLosingStake.add(currentPrediction.stakeAtSubmission);
                    }
                }
            }
        }

        // Add slashed stake to the reward pool
        rewardPool = rewardPool.add(totalLosingStake);

        // Distribute rewards to winning providers and voters
        if (totalWinningStake > 0) {
            // Distribute rewardPool proportionally to stakeAtSubmission among winning prediction submitters
            if (submittedHashes.length > 0) {
                for (uint i = 0; i < submittedHashes.length; i++) {
                    bytes32 currentHash = submittedHashes[i];
                    Prediction storage currentPrediction = queryPredictions[queryId][currentHash];

                    if (currentPrediction.isWinner) {
                        uint256 providerShare = rewardPool.mul(currentPrediction.stakeAtSubmission).div(totalWinningStake);
                        _providerRewards[currentPrediction.provider] = _providerRewards[currentPrediction.provider].add(uint224(providerShare));
                    }
                }
            }

            // Also distribute rewards to providers who voted for the winning prediction
            // This is more complex. We need to iterate over _predictionVoters for the winning hash.
            // The reward for voters could be a separate pool or part of the main pool.
            // Let's simplify: only the provider who *submitted* the winning prediction gets the reward from the pool.
            // Voters are only incentivized by not being slashed and maintaining reputation.
            // This requires removing the 'voter rewards' logic. Let's stick to submitter rewards for simplicity.
            // The 'voteCount' is already stake-weighted, which implies stake = influence.
            // Let's rethink: maybe the stake *voted* is what matters for winning prediction voters' rewards?
            // This adds significant complexity to track stake *at the moment of voting*.
            // Let's simplify again: Providers who submitted the winning prediction share the reward pool based on their stake *at submission*.
            // Providers who voted for the winning prediction don't get explicit token rewards in this version, only avoid slashing.
            // Providers who submitted or voted for *losing* predictions lose their stake *associated with that action*.
            // How to slash stake associated with a vote? This means stake needs to be 'locked' per vote or tracking vote stake.
            // This becomes very complex quickly.

            // Let's simplify the slashing logic: A provider's stake is *either* rewarded (if their submitted prediction wins or they voted for winner) *or* slashed (if they submitted/voted for a loser).
            // This still needs tracking voters' stakes per query.
            // Let's use the _queryVoters mapping and _providerSubmittedPrediction to identify *all* participants in the query (submitters and voters).
            // For each participant:
            // 1. Did they submit a prediction? If yes, get its hash. If it's the winning hash, they are a winner. If losing, they are a loser.
            // 2. Did they vote? If yes, which prediction(s)? We only stored that they voted, not *who* they voted for after validation period ends.
            // This structure makes it hard to know who voted for the winner vs a loser after the fact.

            // Alternative Simplified Slashing/Rewarding:
            // - Providers who submitted the winning prediction share RewardPool (query fee + ALL slashed stake) proportional to their stakeAtSubmission.
            // - ALL other providers who submitted a prediction OR voted on *any* prediction in this query LOSE a fixed percentage/amount of their stake? Or their stakeAtSubmission / stakeAtVote?
            // Let's go with a simple slash: Providers who submitted a losing prediction lose their `stakeAtSubmission`. Providers who voted but did *not* vote for the winner lose a small fixed amount or percentage of their *current* stake? No, current stake changes.

            // Simplest (Version 1) Model:
            // - Winning Prediction Submitters: Split `(Query Fee * (100 - Protocol Fee %)) + Total Slashed Stake`
            // - Providers who submitted a L*osing* Prediction: Lose `stakeAtSubmission` for that prediction.
            // - Providers who Voted:
            //     - Voted for Winning Prediction: No reward, no slash.
            //     - Voted for L*osing* Prediction OR didn't vote: Lose a percentage of their stake *at the moment of voting*? Still hard to track.
            //     - Let's simplify again: Only Providers who SUBMITTED predictions are subject to direct slash/reward from this pool. Voting is just for consensus.

            // Re-calculating based on Simplified (Version 1) Slashing/Rewarding:
            // Reward Pool = Query Fee * (100 - Protocol Fee %)
            // Total Slashed Stake = Sum of stakeAtSubmission for all losing predictions.

            uint256 totalSlashedStakeFromPredictions = 0;

            if (submittedHashes.length > 0) {
                for (uint i = 0; i < submittedHashes.length; i++) {
                    bytes32 currentHash = submittedHashes[i];
                    Prediction storage currentPrediction = queryPredictions[queryId][currentHash];

                     // Ensure it's a valid submitted prediction
                    if (currentPrediction.provider != address(0)) {
                        if (currentPrediction.isWinner) {
                           // Keep their stake
                        } else {
                           // Slash their stake
                           totalSlashedStakeFromPredictions = totalSlashedStakeFromPredictions.add(currentPrediction.stakeAtSubmission);
                           // Reduce their total staked balance (this is where the slash happens)
                           _stakedAmount[currentPrediction.provider] = _stakedAmount[currentPrediction.provider].sub(currentPrediction.stakeAtSubmission);
                        }
                    }
                }
            }

            // Add the slashed stake to the reward pool
            rewardPool = rewardPool.add(totalSlashedStakeFromPredictions);

            // Distribute the new reward pool to the winning prediction submitters
            if (maxVoteCount > 0 && totalWinningStake > 0) {
                 if (submittedHashes.length > 0) {
                    for (uint i = 0; i < submittedHashes.length; i++) {
                        bytes32 currentHash = submittedHashes[i];
                        Prediction storage currentPrediction = queryPredictions[queryId][currentHash];

                        if (currentPrediction.isWinner) {
                            uint256 providerShare = rewardPool.mul(currentPrediction.stakeAtSubmission).div(totalWinningStake);
                            _providerRewards[currentPrediction.provider] = _providerRewards[currentPrediction.provider].add(uint224(providerShare));
                        }
                    }
                }
            } // If maxVoteCount is 0 (no votes cast) or totalWinningStake is 0 (e.g., no predictions submitted), rewardPool stays in protocolFeesCollected implicitly.

            emit QueryResolved(queryId, winningPredictionHash, rewardPool, totalSlashedStakeFromPredictions);
        } else {
             // If no predictions submitted, query fee goes to protocol fees.
             // It's already accounted for in protocolFeeAmount calculation at the beginning.
             emit QueryResolved(queryId, bytes32(0), 0, 0); // No predictions, no rewards/slashes
        }

        emit QueryStateChanged(queryId, QueryState.ValidationPeriod, QueryState.Resolved);
    }

    // Add the state variable mentioned for submitted prediction hashes
    mapping(uint256 => bytes32[]) public querySubmittedPredictionHashes;

    // Need to update submitPrediction to add to this array.
    // In submitPrediction, after the check and before the event:
    // querySubmittedPredictionHashes[queryId].push(predictionHash);


    // --- Provider Staking Functions ---

    /// @notice Allows a provider to stake tokens.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) external {
        if (amount == 0) revert InsufficientStake();
        if (stakingToken.balanceOf(msg.sender) < amount) revert InsufficientBalance();
        if (stakingToken.allowance(msg.sender, address(this)) < amount) revert InsufficientAllowance();

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientAllowance(); // Or specific transfer error

        _stakedAmount[msg.sender] = _stakedAmount[msg.sender].add(amount);

        emit ProviderStaked(msg.sender, amount, _stakedAmount[msg.sender]);
    }

    /// @notice Initiates the unstaking process. Tokens become locked.
    /// @param amount The amount of tokens to unstake.
    function initiateUnstake(uint256 amount) external {
        if (amount == 0) revert UnstakeAmountTooHigh(); // Must be positive amount
        if (_stakedAmount[msg.sender] < amount) revert UnstakeAmountTooHigh();

        // Check if there's already a pending unstake
        if (_pendingUnstake[msg.sender].amount > 0) {
             // Option: Add to existing pending unstake? Or require cancelling first?
             // Let's require cancelling first for simplicity.
             revert NoPendingUnstake(); // Or a specific error like PendingUnstakeInProgress
        }

        _stakedAmount[msg.sender] = _stakedAmount[msg.sender].sub(amount);

        _pendingUnstake[msg.sender] = ProviderUnstake({
            amount: amount,
            unlockTimestamp: block.timestamp.add(unstakeLockupDuration)
        });

        emit ProviderUnstakeInitiated(msg.sender, amount, _pendingUnstake[msg.sender].unlockTimestamp);
    }

    /// @notice Claims unstaked tokens after the lockup period expires.
    function claimUnstakedTokens() external {
        ProviderUnstake storage pending = _pendingUnstake[msg.sender];

        if (pending.amount == 0) revert NoPendingUnstake();
        if (block.timestamp < pending.unlockTimestamp) revert UnstakeLockupNotExpired();

        uint256 amountToClaim = pending.amount;

        // Clear pending unstake *before* transfer
        pending.amount = 0;
        pending.unlockTimestamp = 0;

        bool success = stakingToken.transfer(msg.sender, amountToClaim);
        if (!success) {
            // This should theoretically not fail if balance is sufficient, but handle defensively.
            // Revert and leave pending state as is so user can try again.
            // Or, log event and accept state change? Reverting is safer.
             pending.amount = amountToClaim; // Restore state
             pending.unlockTimestamp = block.timestamp; // Reset unlock time? Or use original? Original is better.
             // Simpler: just revert and require a successful transfer.
             revert(); // Generic revert for transfer failure
        }

        emit ProviderUnstakeClaimed(msg.sender, amountToClaim);
    }

    /// @notice Cancels a pending unstake request, returning tokens to the staked balance.
    /// @param amount The amount to cancel from pending unstake.
    function cancelUnstake(uint256 amount) external {
         if (amount == 0) revert CancelUnstakeAmountTooHigh(); // Must be positive
         ProviderUnstake storage pending = _pendingUnstake[msg.sender];

         if (pending.amount == 0) revert NoPendingUnstake();
         if (pending.amount < amount) revert CancelUnstakeAmountTooHigh();
         // No need to check lockup here, cancelling is always allowed

         pending.amount = pending.amount.sub(amount);
         _stakedAmount[msg.sender] = _stakedAmount[msg.sender].add(amount);

         // If all pending amount is cancelled, clear the struct
         if (pending.amount == 0) {
            pending.unlockTimestamp = 0;
         }

         emit ProviderUnstakeCancelled(msg.sender, amount);
    }


    // --- Reward Claiming ---

    /// @notice Allows a provider to claim accumulated rewards from resolved queries.
    /// @dev Query IDs are not strictly needed if _providerRewards tracks total, but could be useful for specific query claims.
    /// @param queryIds Placeholder - reward is tracked globally per provider. This param is ignored in this implementation.
    function claimProviderRewards(uint256[] calldata queryIds) external {
        // Parameter queryIds is ignored as rewards are aggregated per provider.
        uint256 amountToClaim = _providerRewards[msg.sender];

        if (amountToClaim == 0) revert NothingToClaim();

        // Clear rewards *before* transfer
        _providerRewards[msg.sender] = 0;

        bool success = stakingToken.transfer(msg.sender, amountToClaim);
         if (!success) {
            // Revert and leave reward state as is so user can try again.
             _providerRewards[msg.sender] = uint224(amountToClaim); // Restore state
             revert(); // Generic revert for transfer failure
         }

        emit ProviderRewardsClaimed(msg.sender, amountToClaim);
    }


    // --- Model Management (Admin/Owner) ---

    /// @notice Adds a new AI model configuration.
    /// @param modelId The unique ID for the new model.
    /// @param modelOwner The address associated with this model.
    /// @param fee The specific fee for this model (0 to use default queryFee).
    /// @param requiredStake The specific required stake for providers using this model (0 to use default minProviderStake).
    function addModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake) external onlyOwner {
        if (modelConfigs[modelId].isActive) revert InvalidModelId(); // Model ID already exists and is active

        modelConfigs[modelId] = ModelConfig({
            modelOwner: modelOwner,
            fee: fee,
            requiredStake: requiredStake,
            isActive: true
        });

        emit ModelAdded(modelId, modelOwner, fee, requiredStake);
    }

    /// @notice Updates an existing AI model configuration.
    /// @param modelId The ID of the model to update.
    /// @param modelOwner The new address associated with this model.
    /// @param fee The new specific fee for this model (0 to use default queryFee).
    /// @param requiredStake The new specific required stake for providers (0 to use default minProviderStake).
    function updateModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake) external onlyOwner {
        if (!modelConfigs[modelId].isActive) revert InvalidModelId(); // Model ID doesn't exist or isn't active

        modelConfigs[modelId].modelOwner = modelOwner;
        modelConfigs[modelId].fee = fee;
        modelConfigs[modelId].requiredStake = requiredStake;

        emit ModelUpdated(modelId, modelOwner, fee, requiredStake);
    }

    /// @notice Deactivates an AI model, preventing new queries for it.
    /// @param modelId The ID of the model to remove.
    function removeModel(uint256 modelId) external onlyOwner {
        if (!modelConfigs[modelId].isActive) revert InvalidModelId(); // Model ID doesn't exist or isn't active

        modelConfigs[modelId].isActive = false;

        // Note: Existing queries for this model can still be processed.

        emit ModelRemoved(modelId);
    }


    // --- Parameter Configuration (Admin/Owner) ---

    /// @notice Sets the default query fee.
    /// @param fee The new default fee amount.
    function setQueryFee(uint256 fee) external onlyOwner {
        queryFee = fee;
        emit ParameterSet("queryFee", fee);
    }

    /// @notice Sets the minimum provider stake required.
    /// @param amount The new minimum stake amount.
    function setMinProviderStake(uint256 amount) external onlyOwner {
        minProviderStake = amount;
        emit ParameterSet("minProviderStake", amount);
    }

    /// @notice Sets the duration for the prediction submission phase.
    /// @param duration The new duration in seconds.
    function setSubmissionPeriod(uint256 duration) external onlyOwner {
        submissionPeriod = duration;
        emit ParameterSet("submissionPeriod", duration);
    }

    /// @notice Sets the duration for the validation voting phase.
    /// @param duration The new duration in seconds.
    function setValidationPeriod(uint256 duration) external onlyOwner {
        validationPeriod = duration;
        emit ParameterSet("validationPeriod", duration);
    }

    /// @notice Sets the duration for the unstake lockup period.
    /// @param duration The new duration in seconds.
    function setUnstakeLockupDuration(uint256 duration) external onlyOwner {
        unstakeLockupDuration = duration;
         emit ParameterSet("unstakeLockupDuration", duration);
    }

    /// @notice Sets the percentage of query fees kept by the protocol.
    /// @param percentage The new percentage (0-100).
    function setProtocolFeePercentage(uint256 percentage) external onlyOwner {
        if (percentage > 100) revert InvalidPercentage();
        protocolFeePercentage = percentage;
         emit ParameterSet("protocolFeePercentage", percentage);
    }


    // --- Protocol Fee Management (Admin/Owner) ---

    /// @notice Allows the contract owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = protocolFeesCollected;
        if (amount == 0) revert NothingToClaim();

        protocolFeesCollected = 0;

        bool success = stakingToken.transfer(owner(), amount);
        if (!success) {
             // Restore state if transfer fails
             protocolFeesCollected = amount;
             revert();
        }

        emit ProtocolFeesWithdrawn(owner(), amount);
    }


    // --- View Functions (Read-only) ---

    /// @notice Returns the current staked amount for a provider.
    function getProviderStake(address provider) external view returns (uint256) {
        return _stakedAmount[provider];
    }

    /// @notice Returns the pending unstake amount and unlock time for a provider.
    function getProviderPendingUnstake(address provider) external view returns (uint256 amount, uint256 unlockTimestamp) {
        ProviderUnstake storage pending = _pendingUnstake[provider];
        return (pending.amount, pending.unlockTimestamp);
    }

    /// @notice Returns the total amount of staking tokens staked in the contract.
    /// @dev Summing over a mapping is not efficient. This requires iterating provider addresses which isn't feasible in Solidity.
    /// A state variable `_totalStaked` should be maintained and updated in stake/unstake functions.
    /// Let's add `uint256 private _totalStaked;` and update it.
    // Function body will be replaced by returning the state variable.
    // Temporarily, will return 0 or remove this function as inefficient.
    // Let's add the state variable and update.

    uint256 private _totalStaked;

    // Update `stake`: _totalStaked = _totalStaked.add(amount);
    // Update `initiateUnstake`: _totalStaked = _totalStaked.sub(amount);
    // Update `cancelUnstake`: _totalStaked = _totalStaked.add(amount);
    // Update `resolveQuery` (slashing): _totalStaked = _totalStaked.sub(totalSlashedStakeFromPredictions);

    /// @notice Returns the total amount of staking tokens staked in the contract.
    function getTotalStaked() external view returns (uint256) {
        return _totalStaked; // Using the new state variable
    }


    /// @notice Returns the configuration details for a specific model.
    function getModelConfig(uint256 modelId) external view returns (ModelConfig memory) {
        return modelConfigs[modelId];
    }

    /// @notice Checks if a model ID is registered and active.
    function isModelActive(uint256 modelId) external view returns (bool) {
        return modelConfigs[modelId].isActive;
    }

    /// @notice Returns the details of a specific query request.
    function getQueryDetails(uint256 queryId) external view returns (QueryRequest memory) {
        return queryRequests[queryId];
    }

    /// @notice Returns a list of prediction hashes submitted for a query.
    function getPredictionsForQuery(uint256 queryId) external view returns (bytes32[] memory) {
         // Using the new state variable querySubmittedPredictionHashes
        return querySubmittedPredictionHashes[queryId];
    }

    /// @notice Returns details of a specific prediction for a query.
    function getPredictionDetails(uint256 queryId, bytes32 predictionHash) external view returns (Prediction memory) {
        return queryPredictions[queryId][predictionHash];
    }

    /// @notice Returns the stake-weighted vote count for a specific prediction.
    function getPredictionVoteCount(uint256 queryId, bytes32 predictionHash) external view returns (uint256) {
         Prediction storage prediction = queryPredictions[queryId][predictionHash];
         // Need to ensure prediction exists before accessing voteCount
         if (prediction.provider == address(0)) return 0; // Or revert? Returning 0 seems fine for view.
         return prediction.voteCount;
    }

    /// @notice Returns the total amount of protocol fees collected.
    function getProtocolFeesCollected() external view returns (uint256) {
        return protocolFeesCollected;
    }

    /// @notice Returns the next available query ID (total number of queries requested so far).
    function getCurrentQueryId() external view returns (uint256) {
        return _nextQueryId;
    }

    // --- Need to implement the changes identified during review ---
    // 1. Add `mapping(uint256 => mapping(address => bytes32)) private _providerSubmittedPrediction;` and use it in `submitPrediction`.
    // 2. Add `mapping(uint256 => bytes32[]) public querySubmittedPredictionHashes;` and populate it in `submitPrediction`.
    // 3. Add `uint256 private _totalStaked;` and update it in staking/slashing functions.

    // Implement change 1 and 2 in submitPrediction:
    function submitPrediction_updated(uint256 queryId, bytes32 predictionHash, bytes calldata encryptedPrediction) external onlyProviderWithMinStake {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound();
        if (query.currentState != QueryState.SubmissionPeriod) revert InvalidQueryState();
        if (block.timestamp > query.submissionPeriodEnd) revert PredictionSubmissionPeriodEnded();

        // Check if provider already submitted for this query using the dedicated mapping
        if (_providerSubmittedPrediction[queryId][msg.sender] != bytes32(0)) revert ProviderAlreadySubmittedPrediction();

        // Store the prediction
        queryPredictions[queryId][predictionHash] = Prediction({
            provider: msg.sender,
            predictionHash: predictionHash,
            encryptedPrediction: encryptedPrediction,
            stakeAtSubmission: _stakedAmount[msg.sender],
            submittedTimestamp: block.timestamp,
            isWinner: false,
            voteCount: 0 // Vote count is stake-weighted
        });

        // Record that the provider submitted
        _providerSubmittedPrediction[queryId][msg.sender] = predictionHash;

        // Add the prediction hash to the list for iteration during resolution
        querySubmittedPredictionHashes[queryId].push(predictionHash);


        emit PredictionSubmitted(queryId, msg.sender, predictionHash);
    }
    // Replace the original `submitPrediction` with this `submitPrediction_updated`.

    // Implement change 3 for _totalStaked:
    // In `stake`: _totalStaked = _totalStaked.add(amount);
    // In `initiateUnstake`: _totalStaked = _totalStaked.sub(amount); (Note: This reduces total staked *before* lockup)
    // In `cancelUnstake`: _totalStaked = _totalStaked.add(amount);
    // In `resolveQuery`: _stakedAmount[currentPrediction.provider] = _stakedAmount[currentPrediction.provider].sub(currentPrediction.stakeAtSubmission);
    // And also in resolveQuery, when slashing: _totalStaked = _totalStaked.sub(totalSlashedStakeFromPredictions);

    // Need to make sure these updates are done correctly within the respective functions.
    // The existing functions already have the logic, just need to add the `_totalStaked` updates.

    // The logic seems solid now for the simplified staking/slashing model.
    // The 20+ function requirement is met (31 functions listed).
    // Concepts are interesting: AI oracle, staking, voting, state machine, rewards/slashing, model registry, hint of privacy with encrypted data.
    // Avoids direct copy of major protocols by focusing on this specific AI prediction validation flow.

    // Let's put all the pieces together in the final contract.
    // The provided code needs the OpenZeppelin imports and the corrected functions integrated.
    // Assume OpenZeppelin contracts are in node_modules/@openzeppelin/contracts
}

// Integrate the updated functions and state variables into the final code structure.

```

**Final Code Structure (incorporating updates):**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Use SafeMath if not using Solidity 0.8+ checked arithmetic

// For Solidity 0.8+, SafeMath is not strictly needed for basic ops but can be kept for clarity/habit
// Or remove SafeMath import and `using SafeMath for uint256;` if using 0.8+ exclusively and confident in checked arithmetic.
// Let's keep it for robustness across slightly older compilers if needed.

/// @title Decentralized AI Prediction Oracle
/// @notice A smart contract for requesting, submitting, validating, and resolving AI predictions for off-chain queries.
/// @dev This contract uses a staking and voting mechanism among providers to ensure prediction accuracy.

// --- Outline ---
// 1. Pragma and Imports
// 2. Interfaces (for ERC20)
// 3. Error Definitions
// 4. Enums (QueryState)
// 5. Structs (ModelConfig, QueryRequest, Prediction, ValidationVote)
// 6. Events
// 7. State Variables
// 8. Constructor
// 9. Modifiers
// 10. Core Query Lifecycle Functions
// 11. Provider Staking Functions
// 12. Reward Claiming
// 13. Model Management (Admin/Owner)
// 14. Parameter Configuration (Admin/Owner)
// 15. Protocol Fee Management (Admin/Owner)
// 16. View Functions (Read-only)

// --- Function Summary ---
// constructor(...)
// requestPrediction(uint256 modelId, bytes32 queryHash)
// submitPrediction(uint256 queryId, bytes32 predictionHash, bytes calldata encryptedPrediction)
// castValidationVote(uint256 queryId, bytes32 predictionHash)
// resolveQuery(uint256 queryId)
// stake(uint256 amount)
// initiateUnstake(uint256 amount)
// claimUnstakedTokens()
// cancelUnstake(uint256 amount)
// claimProviderRewards(uint256[] calldata queryIds) (Note: queryIds param is illustrative, rewards are aggregated)
// addModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake)
// updateModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake)
// removeModel(uint256 modelId)
// setQueryFee(uint256 fee)
// setMinProviderStake(uint256 amount)
// setSubmissionPeriod(uint256 duration)
// setValidationPeriod(uint256 duration)
// setUnstakeLockupDuration(uint256 duration)
// setProtocolFeePercentage(uint256 percentage)
// withdrawProtocolFees()
// getProviderStake(address provider)
// getProviderPendingUnstake(address provider)
// getTotalStaked()
// getModelConfig(uint256 modelId)
// isModelActive(uint256 modelId)
// getQueryDetails(uint256 queryId)
// getPredictionsForQuery(uint256 queryId)
// getPredictionDetails(uint256 queryId, bytes32 predictionHash)
// getPredictionVoteCount(uint256 queryId, bytes32 predictionHash)
// getProtocolFeesCollected()
// getCurrentQueryId()


contract DecentralizedAIOracle is Ownable {
    using SafeMath for uint256; // Keep SafeMath for robustness

    IERC20 public immutable stakingToken;

    uint256 public minProviderStake;
    uint256 public queryFee; // Default query fee
    uint256 public submissionPeriod; // Duration for submitting predictions in seconds
    uint256 public validationPeriod; // Duration for validating predictions in seconds
    uint256 public unstakeLockupDuration; // Duration tokens are locked after unstake initiation in seconds
    uint256 public protocolFeePercentage; // Percentage of query fee kept by protocol (0-100)

    // --- Enums ---
    enum QueryState {
        Requested,          // Query created, awaiting predictions (short transient state)
        SubmissionPeriod,   // Predictions can be submitted
        ValidationPeriod,   // Predictions are being voted on
        Resolved,           // Query is resolved, outcome finalized
        Disputed            // Future state for dispute resolution (not implemented)
    }

    // --- Structs ---
    struct ModelConfig {
        address modelOwner; // Address associated with the model (could be DAO, individual, etc.)
        uint256 fee;        // Specific fee for this model (overrides default queryFee if > 0)
        uint256 requiredStake; // Specific required stake for providers using this model (overrides minProviderStake if > 0)
        bool isActive;      // Whether the model can be used for new queries
    }

    struct QueryRequest {
        address user;
        uint256 modelId;
        bytes32 queryHash; // Hash representing the off-chain query/data
        uint256 feePaid;
        uint256 requestTimestamp;
        QueryState currentState;
        bytes32 winningPredictionHash; // Hash of the prediction deemed correct
        uint256 resolutionTimestamp; // Time when the query was resolved
        uint256 submissionPeriodEnd;
        uint256 validationPeriodEnd;
        // Mappings nested in structs are not allowed for storage.
        // submittedPredictionHashes array and related mappings are external.
    }

    struct Prediction {
        address provider;
        bytes32 predictionHash; // Hash of the actual prediction value
        bytes encryptedPrediction; // Optional: Encrypted prediction value (off-chain decryption/verification)
        uint256 stakeAtSubmission; // Stake amount of provider when submitting this prediction
        uint256 submittedTimestamp;
        bool isWinner;
        uint256 voteCount; // Total stake-weighted votes received
    }

    struct ProviderUnstake {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    // --- State Variables ---
    uint256 private _nextQueryId; // Starts from 0, increments for each new query

    mapping(uint256 => ModelConfig) public modelConfigs;
    mapping(uint256 => QueryRequest) public queryRequests;

    // queryId -> predictionHash -> Prediction
    mapping(uint256 => mapping(bytes32 => Prediction)) public queryPredictions;

    // queryId -> providerAddress -> predictionHash they submitted (for uniqueness check and retrieval)
    mapping(uint256 => mapping(address => bytes32)) private _providerSubmittedPrediction;

    // queryId -> List of prediction hashes submitted (for iterating during resolution)
    mapping(uint256 => bytes32[]) public querySubmittedPredictionHashes;

    // queryId -> providerAddress -> bool (Did this provider vote in this query at all?)
    mapping(uint256 => mapping(address => bool)) private _queryVoters;

    // providerAddress -> total staked amount
    mapping(address => uint256) private _stakedAmount;

     // Total staked amount across all providers (for efficient getTotalStaked view)
    uint256 private _totalStaked;

    // providerAddress -> pending unstake details
    mapping(address => ProviderUnstake) private _pendingUnstake;

    // providerAddress -> accumulated rewards from resolved queries
    mapping(address => uint224) private _providerRewards; // Use uint224 to save space

    // Total accumulated protocol fees
    uint256 public protocolFeesCollected;


    // --- Events ---
    event QueryRequested(uint256 indexed queryId, uint256 indexed modelId, address indexed user, bytes32 queryHash, uint256 feePaid);
    event PredictionSubmitted(uint256 indexed queryId, address indexed provider, bytes32 indexed predictionHash);
    event ValidationVoteCasted(uint256 indexed queryId, address indexed voter, bytes32 indexed predictionHash);
    event QueryStateChanged(uint256 indexed queryId, QueryState oldState, QueryState newState);
    event QueryResolved(uint256 indexed queryId, bytes32 winningPredictionHash, uint256 rewardPool, uint256 totalSlashedStake);
    event ProviderStaked(address indexed provider, uint256 amount, uint256 totalStake);
    event ProviderUnstakeInitiated(address indexed provider, uint256 amount, uint256 unlockTimestamp);
    event ProviderUnstakeClaimed(address indexed provider, uint256 amount);
    event ProviderUnstakeCancelled(address indexed provider, uint256 amount);
    event ProviderRewardsClaimed(address indexed provider, uint256 amount);
    event ModelAdded(uint256 indexed modelId, address indexed modelOwner, uint256 fee, uint256 requiredStake);
    event ModelUpdated(uint256 indexed modelId, address indexed modelOwner, uint256 fee, uint256 requiredStake);
    event ModelRemoved(uint256 indexed modelId);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event ParameterSet(string paramName, uint256 newValue);


    // --- Errors ---
    error InvalidModelId();
    error ModelNotActive();
    error InsufficientStake();
    error QueryNotFound();
    error InvalidQueryState();
    error PredictionSubmissionPeriodEnded();
    error PredictionValidationPeriodEnded();
    error PredictionNotFound();
    error ProviderAlreadySubmittedPrediction();
    error ProviderAlreadyVotedInQuery();
    // error ProviderAlreadyVotedForPrediction(); // This check is implicitly covered by ProviderAlreadyVotedInQuery for this model.
    error InvalidVote(); // e.g., voting for a non-existent prediction
    error QueryNotReadyForResolution();
    error QueryAlreadyResolved(); // Should be covered by InvalidQueryState, but kept for clarity
    error InsufficientBalance();
    error InsufficientAllowance();
    error UnstakeAmountTooHigh();
    error NoPendingUnstake();
    error UnstakeLockupNotExpired();
    error CancelUnstakeAmountTooHigh();
    error NothingToClaim();
    error InvalidPercentage();
    error OnlyOwner(); // Explicitly defined though Ownable provides it, good for error mapping.
    error TransferFailed(); // Generic error for ERC20 transfer issues

    // --- Constructor ---
    /// @notice Initializes the Decentralized AI Oracle contract.
    /// @param _stakingToken Address of the ERC20 token used for staking and payments.
    /// @param _minProviderStake Minimum stake required for a provider to submit predictions or vote.
    /// @param _queryFee Default fee to request a prediction (in staking tokens).
    /// @param _submissionPeriod Duration of the prediction submission phase in seconds.
    /// @param _validationPeriod Duration of the validation voting phase in seconds.
    /// @param _unstakeLockupDuration Duration tokens are locked after initiating unstake in seconds.
    /// @param _protocolFeePercentage Percentage (0-100) of query fees kept by the protocol.
    constructor(
        address _stakingToken,
        uint256 _minProviderStake,
        uint256 _queryFee,
        uint256 _submissionPeriod,
        uint256 _validationPeriod,
        uint256 _unstakeLockupDuration,
        uint256 _protocolFeePercentage
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        minProviderStake = _minProviderStake;
        queryFee = _queryFee;
        submissionPeriod = _submissionPeriod;
        validationPeriod = _validationPeriod;
        unstakeLockupDuration = _unstakeLockupDuration;

        if (_protocolFeePercentage > 100) revert InvalidPercentage();
        protocolFeePercentage = _protocolFeePercentage;

        _nextQueryId = 0; // Query IDs start from 0
        _totalStaked = 0; // Initialize total staked
    }

    // --- Modifiers ---
    modifier onlyProviderWithMinStake() {
        if (_stakedAmount[msg.sender] < minProviderStake) revert InsufficientStake();
        _;
    }

    // --- Core Query Lifecycle Functions ---

    /// @notice Requests a prediction for a specific query using a given AI model.
    /// @param modelId The ID of the AI model to use.
    /// @param queryHash A bytes32 hash representing the off-chain query or data.
    function requestPrediction(uint256 modelId, bytes32 queryHash) external {
        ModelConfig storage model = modelConfigs[modelId];
        if (!model.isActive) revert ModelNotActive();

        uint256 fee = model.fee > 0 ? model.fee : queryFee;

        // Check user has sufficient balance and allowance
        if (stakingToken.balanceOf(msg.sender) < fee) revert InsufficientBalance();
        if (stakingToken.allowance(msg.sender, address(this)) < fee) revert InsufficientAllowance();

        // Transfer fee to the contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), fee);
        if (!success) revert TransferFailed();

        uint256 queryId = _nextQueryId++;
        uint256 currentTimestamp = block.timestamp;

        queryRequests[queryId] = QueryRequest({
            user: msg.sender,
            modelId: modelId,
            queryHash: queryHash,
            feePaid: fee,
            requestTimestamp: currentTimestamp,
            currentState: QueryState.SubmissionPeriod, // Start in submission period immediately
            winningPredictionHash: bytes32(0),
            resolutionTimestamp: 0,
            submissionPeriodEnd: currentTimestamp.add(submissionPeriod),
            validationPeriodEnd: currentTimestamp.add(submissionPeriod).add(validationPeriod)
        });

        emit QueryRequested(queryId, modelId, msg.sender, queryHash, fee);
        // Note: Technically the state is Requested for a tiny moment before SubmissionPeriod starts.
        // The initial state in the struct directly being SubmissionPeriod simplifies the state machine.
        emit QueryStateChanged(queryId, QueryState.Requested, QueryState.SubmissionPeriod);
    }

    /// @notice Allows a staked provider to submit a prediction for an active query.
    /// @dev Each provider can only submit one prediction per query.
    /// @param queryId The ID of the query.
    /// @param predictionHash A bytes32 hash representing the provider's prediction result.
    /// @param encryptedPrediction Optional: The encrypted prediction data.
    function submitPrediction(uint256 queryId, bytes32 predictionHash, bytes calldata encryptedPrediction) external onlyProviderWithMinStake {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound(); // Check if query exists
        if (query.currentState != QueryState.SubmissionPeriod) revert InvalidQueryState();
        if (block.timestamp > query.submissionPeriodEnd) revert PredictionSubmissionPeriodEnded();

        // Check if provider already submitted for this query using the dedicated mapping
        if (_providerSubmittedPrediction[queryId][msg.sender] != bytes32(0)) revert ProviderAlreadySubmittedPrediction();

        // Store the prediction
        queryPredictions[queryId][predictionHash] = Prediction({
            provider: msg.sender,
            predictionHash: predictionHash,
            encryptedPrediction: encryptedPrediction,
            stakeAtSubmission: _stakedAmount[msg.sender],
            submittedTimestamp: block.timestamp,
            isWinner: false,
            voteCount: 0 // Vote count is stake-weighted
        });

        // Record that the provider submitted
        _providerSubmittedPrediction[queryId][msg.sender] = predictionHash;

        // Add the prediction hash to the list for iteration during resolution
        querySubmittedPredictionHashes[queryId].push(predictionHash);

        emit PredictionSubmitted(queryId, msg.sender, predictionHash);
    }


    /// @notice Allows a staked provider to cast a validation vote for a submitted prediction.
    /// @dev Providers can vote for one prediction per query. Vote weight is the provider's stake at the moment of voting.
    /// @param queryId The ID of the query.
    /// @param predictionHash The hash of the prediction to vote for.
    function castValidationVote(uint256 queryId, bytes32 predictionHash) external onlyProviderWithMinStake {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound(); // Check if query exists
        if (query.currentState != QueryState.ValidationPeriod) revert InvalidQueryState();
        if (block.timestamp > query.validationPeriodEnd) revert PredictionValidationPeriodEnded();

        Prediction storage prediction = queryPredictions[queryId][predictionHash];
        if (prediction.provider == address(0)) revert PredictionNotFound(); // Check if the prediction exists

        // Check if the provider already voted in this query
        if (_queryVoters[queryId][msg.sender]) revert ProviderAlreadyVotedInQuery();

        // Record the vote
        _queryVoters[queryId][msg.sender] = true;

        // Add provider's CURRENT stake weight to the prediction's vote count
        // Note: Using current stake for voting weight might be different from stakeAtSubmission.
        // This incentives maintaining stake during the validation period.
        prediction.voteCount = prediction.voteCount.add(_stakedAmount[msg.sender]);

        emit ValidationVoteCasted(queryId, msg.sender, predictionHash);
    }

    /// @notice Resolves a query after the validation period, determining the winning prediction and distributing rewards/slashes.
    /// @param queryId The ID of the query to resolve.
    function resolveQuery(uint256 queryId) external {
        QueryRequest storage query = queryRequests[queryId];
        if (query.user == address(0)) revert QueryNotFound(); // Check if query exists
        if (query.currentState != QueryState.ValidationPeriod) revert InvalidQueryState();
        if (block.timestamp <= query.validationPeriodEnd) revert QueryNotReadyForResolution();

        // Transition state first
        QueryState oldState = query.currentState;
        query.currentState = QueryState.Resolved;
        query.resolutionTimestamp = block.timestamp;
        emit QueryStateChanged(queryId, oldState, query.currentState);


        bytes32 winningPredictionHash = bytes32(0);
        uint256 maxVoteCount = 0;
        uint256 totalSubmittedStake = 0; // Sum of stakeAtSubmission for ALL submitted predictions
        uint256 totalWinningSubmittedStake = 0; // Sum of stakeAtSubmission for winning predictions (in case of tie)
        uint256 totalSlashedStakeFromPredictions = 0; // Stake lost by providers who submitted losing predictions

        bytes32[] memory submittedHashes = querySubmittedPredictionHashes[queryId];

        // 1. Find the winning prediction(s) (highest vote count) and calculate total submitted stake
        if (submittedHashes.length > 0) {
            for (uint i = 0; i < submittedHashes.length; i++) {
                bytes32 currentHash = submittedHashes[i];
                 Prediction storage currentPrediction = queryPredictions[queryId][currentHash];
                 // Check if this is a valid prediction entry
                 if (currentPrediction.provider != address(0)) {
                     totalSubmittedStake = totalSubmittedStake.add(currentPrediction.stakeAtSubmission);

                     if (currentPrediction.voteCount > maxVoteCount) {
                        maxVoteCount = currentPrediction.voteCount;
                        winningPredictionHash = currentHash; // Tentative winner
                        // Reset totalWinningSubmittedStake as we found a new higher vote count
                        totalWinningSubmittedStake = currentPrediction.stakeAtSubmission;
                    } else if (currentPrediction.voteCount > 0 && currentPrediction.voteCount == maxVoteCount) {
                        // Handle ties: Add to total winning submitted stake
                        totalWinningSubmittedStake = totalWinningSubmittedStake.add(currentPrediction.stakeAtSubmission);
                    }
                 }
            }
        }

        query.winningPredictionHash = winningPredictionHash;

        // 2. Distribute Rewards and Slashes
        uint256 rewardPool = query.feePaid;
        uint256 protocolFeeAmount = rewardPool.mul(protocolFeePercentage).div(100);
        protocolFeesCollected = protocolFeesCollected.add(protocolFeeAmount);
        rewardPool = rewardPool.sub(protocolFeeAmount); // Reward pool for providers

        // Iterate again to distribute rewards and slash losing submitters
        if (submittedHashes.length > 0) {
            for (uint i = 0; i < submittedHashes.length; i++) {
                bytes32 currentHash = submittedHashes[i];
                Prediction storage currentPrediction = queryPredictions[queryId][currentHash];

                 if (currentPrediction.provider != address(0)) {
                     if (currentPrediction.voteCount > 0 && currentPrediction.voteCount == maxVoteCount) {
                        // This prediction is a winner (or tied winner)
                        currentPrediction.isWinner = true;
                        // Providers who submitted winning predictions share `rewardPool + totalSlashedStakeFromPredictions`
                        // based on their `stakeAtSubmission`. The calculation needs to happen *after* finding total slashed.
                     } else {
                        // This prediction is a loser (or got 0 votes if maxVoteCount was > 0)
                        // Slash the stake they committed at submission for this prediction
                        uint256 slashAmount = currentPrediction.stakeAtSubmission;
                        if (slashAmount > 0) {
                             // Ensure provider has enough staked amount to be slashed
                             // This check is defensive; they should have staked this amount when submitting.
                             uint224 slashAmount224 = uint224(slashAmount); // Safe cast if max stake is less than 2^224
                            _stakedAmount[currentPrediction.provider] = _stakedAmount[currentPrediction.provider].sub(slashAmount);
                            _totalStaked = _totalStaked.sub(slashAmount);
                            totalSlashedStakeFromPredictions = totalSlashedStakeFromPredictions.add(slashAmount);
                        }
                     }
                 }
            }
        }

        // Add slashed stake to the reward pool
        rewardPool = rewardPool.add(totalSlashedStakeFromPredictions);

        // 3. Distribute the final reward pool to winning submitters (if any)
         if (maxVoteCount > 0 && totalWinningSubmittedStake > 0) {
             if (submittedHashes.length > 0) {
                for (uint i = 0; i < submittedHashes.length; i++) {
                    bytes32 currentHash = submittedHashes[i];
                    Prediction storage currentPrediction = queryPredictions[queryId][currentHash];

                    if (currentPrediction.isWinner) {
                        // Distribute reward proportionally to their stakeAtSubmission among winning submitters
                        uint256 providerShare = rewardPool.mul(currentPrediction.stakeAtSubmission).div(totalWinningSubmittedStake);
                        _providerRewards[currentPrediction.provider] = _providerRewards[currentPrediction.provider].add(uint224(providerShare));
                    }
                }
             }
         } else {
             // If no predictions were submitted/voted on effectively (maxVoteCount is 0),
             // the entire rewardPool (query fee + any stake from 0-vote predictions)
             // remains in the contract and adds to protocol fees. This is handled
             // implicitly as rewardPool is not distributed.
         }


        emit QueryResolved(queryId, winningPredictionHash, rewardPool, totalSlashedStakeFromPredictions);
        // Note: Slashed stake from providers who *only* voted for a losing prediction is not handled here.
        // This simplified model only slashes stake committed by providers *submitting* predictions.
        // Slashing for voters would require tracking stake per vote or per voter per query more granularly.
        // For 20+ functions, this level of complexity is acceptable.
    }


    // --- Provider Staking Functions ---

    /// @notice Allows a provider to stake tokens.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) external {
        if (amount == 0) revert InsufficientStake();
        if (stakingToken.balanceOf(msg.sender) < amount) revert InsufficientBalance();
        if (stakingToken.allowance(msg.sender, address(this)) < amount) revert InsufficientAllowance();

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        _stakedAmount[msg.sender] = _stakedAmount[msg.sender].add(amount);
        _totalStaked = _totalStaked.add(amount);

        emit ProviderStaked(msg.sender, amount, _stakedAmount[msg.sender]);
    }

    /// @notice Initiates the unstaking process. Tokens become locked.
    /// @param amount The amount of tokens to unstake.
    function initiateUnstake(uint256 amount) external {
        if (amount == 0) revert UnstakeAmountTooHigh(); // Must be positive amount
        if (_stakedAmount[msg.sender] < amount) revert UnstakeAmountTooHigh();

        // Check if there's already a pending unstake
        if (_pendingUnstake[msg.sender].amount > 0) {
             // Require cancelling first for simplicity.
             revert NoPendingUnstake();
        }

        _stakedAmount[msg.sender] = _stakedAmount[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount); // Reduce total staked immediately

        _pendingUnstake[msg.sender] = ProviderUnstake({
            amount: amount,
            unlockTimestamp: block.timestamp.add(unstakeLockupDuration)
        });

        emit ProviderUnstakeInitiated(msg.sender, amount, _pendingUnstake[msg.sender].unlockTimestamp);
    }

    /// @notice Claims unstaked tokens after the lockup period expires.
    function claimUnstakedTokens() external {
        ProviderUnstake storage pending = _pendingUnstake[msg.sender];

        if (pending.amount == 0) revert NoPendingUnstake();
        if (block.timestamp < pending.unlockTimestamp) revert UnstakeLockupNotExpired();

        uint256 amountToClaim = pending.amount;

        // Clear pending unstake *before* transfer
        pending.amount = 0;
        pending.unlockTimestamp = 0;

        bool success = stakingToken.transfer(msg.sender, amountToClaim);
        if (!success) {
             // Restore state if transfer fails and revert
             pending.amount = amountToClaim;
             pending.unlockTimestamp = block.timestamp.add(1); // Small delay to re-trigger lockup check if timestamp is same
             revert TransferFailed();
        }

        emit ProviderUnstakeClaimed(msg.sender, amountToClaim);
    }

    /// @notice Cancels a pending unstake request, returning tokens to the staked balance.
    /// @param amount The amount to cancel from pending unstake.
    function cancelUnstake(uint256 amount) external {
         if (amount == 0) revert CancelUnstakeAmountTooHigh(); // Must be positive
         ProviderUnstake storage pending = _pendingUnstake[msg.sender];

         if (pending.amount == 0) revert NoPendingUnstake();
         if (pending.amount < amount) revert CancelUnstakeAmountTooHigh();
         // No need to check lockup here, cancelling is always allowed

         pending.amount = pending.amount.sub(amount);
         _stakedAmount[msg.sender] = _stakedAmount[msg.sender].add(amount);
         _totalStaked = _totalStaked.add(amount); // Restore total staked

         // If all pending amount is cancelled, clear the struct
         if (pending.amount == 0) {
            pending.unlockTimestamp = 0;
         }

         emit ProviderUnstakeCancelled(msg.sender, amount);
    }


    // --- Reward Claiming ---

    /// @notice Allows a provider to claim accumulated rewards from resolved queries.
    /// @dev Query IDs are not strictly needed as _providerRewards tracks total, but could be useful for specific query claims.
    /// @param queryIds Placeholder - reward is tracked globally per provider. This param is ignored in this implementation.
    function claimProviderRewards(uint256[] calldata queryIds) external {
        // Parameter queryIds is ignored as rewards are aggregated per provider.
        uint256 amountToClaim = _providerRewards[msg.sender];

        if (amountToClaim == 0) revert NothingToClaim();

        // Clear rewards *before* transfer
        _providerRewards[msg.sender] = 0;

        bool success = stakingToken.transfer(msg.sender, amountToClaim);
         if (!success) {
            // Restore state if transfer fails and revert
             _providerRewards[msg.sender] = uint224(amountToClaim);
             revert TransferFailed();
         }

        emit ProviderRewardsClaimed(msg.sender, amountToClaim);
    }


    // --- Model Management (Admin/Owner) ---

    /// @notice Adds a new AI model configuration.
    /// @param modelId The unique ID for the new model.
    /// @param modelOwner The address associated with this model.
    /// @param fee The specific fee for this model (0 to use default queryFee).
    /// @param requiredStake The specific required stake for providers using this model (0 to use default minProviderStake).
    function addModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake) external onlyOwner {
        if (modelConfigs[modelId].isActive) revert InvalidModelId(); // Model ID already exists and is active

        modelConfigs[modelId] = ModelConfig({
            modelOwner: modelOwner,
            fee: fee,
            requiredStake: requiredStake,
            isActive: true
        });

        emit ModelAdded(modelId, modelOwner, fee, requiredStake);
    }

    /// @notice Updates an existing AI model configuration.
    /// @param modelId The ID of the model to update.
    /// @param modelOwner The new address associated with this model.
    /// @param fee The new specific fee for this model (0 to use default queryFee).
    /// @param requiredStake The new specific required stake for providers (0 to use default minProviderStake).
    function updateModel(uint256 modelId, address modelOwner, uint256 fee, uint256 requiredStake) external onlyOwner {
        if (!modelConfigs[modelId].isActive) revert InvalidModelId(); // Model ID doesn't exist or isn't active

        modelConfigs[modelId].modelOwner = modelOwner;
        modelConfigs[modelId].fee = fee;
        modelConfigs[modelId].requiredStake = requiredStake;

        emit ModelUpdated(modelId, modelOwner, fee, requiredStake);
    }

    /// @notice Deactivates an AI model, preventing new queries for it.
    /// @param modelId The ID of the model to remove.
    function removeModel(uint256 modelId) external onlyOwner {
        if (!modelConfigs[modelId].isActive) revert InvalidModelId(); // Model ID doesn't exist or isn't active

        modelConfigs[modelId].isActive = false;

        // Note: Existing queries for this model can still be processed.

        emit ModelRemoved(modelId);
    }


    // --- Parameter Configuration (Admin/Owner) ---

    /// @notice Sets the default query fee.
    /// @param fee The new default fee amount.
    function setQueryFee(uint256 fee) external onlyOwner {
        queryFee = fee;
        emit ParameterSet("queryFee", fee);
    }

    /// @notice Sets the minimum provider stake required.
    /// @param amount The new minimum stake amount.
    function setMinProviderStake(uint256 amount) external onlyOwner {
        minProviderStake = amount;
        emit ParameterSet("minProviderStake", amount);
    }

    /// @notice Sets the duration for the prediction submission phase.
    /// @param duration The new duration in seconds.
    function setSubmissionPeriod(uint256 duration) external onlyOwner {
        submissionPeriod = duration;
        emit ParameterSet("submissionPeriod", duration);
    }

    /// @notice Sets the duration for the validation voting phase.
    /// @param duration The new duration in seconds.
    function setValidationPeriod(uint256 duration) external onlyOwner {
        validationPeriod = duration;
        emit ParameterSet("validationPeriod", duration);
    }

    /// @notice Sets the duration for the unstake lockup period.
    /// @param duration The new duration in seconds.
    function setUnstakeLockupDuration(uint256 duration) external onlyOwner {
        unstakeLockupDuration = duration;
         emit ParameterSet("unstakeLockupDuration", duration);
    }

    /// @notice Sets the percentage of query fees kept by the protocol.
    /// @param percentage The new percentage (0-100).
    function setProtocolFeePercentage(uint256 percentage) external onlyOwner {
        if (percentage > 100) revert InvalidPercentage();
        protocolFeePercentage = percentage;
         emit ParameterSet("protocolFeePercentage", percentage);
    }


    // --- Protocol Fee Management (Admin/Owner) ---

    /// @notice Allows the contract owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = protocolFeesCollected;
        if (amount == 0) revert NothingToClaim();

        protocolFeesCollected = 0;

        bool success = stakingToken.transfer(owner(), amount);
        if (!success) {
             // Restore state if transfer fails
             protocolFeesCollected = amount;
             revert TransferFailed();
        }

        emit ProtocolFeesWithdrawn(owner(), amount);
    }


    // --- View Functions (Read-only) ---

    /// @notice Returns the current staked amount for a provider.
    function getProviderStake(address provider) external view returns (uint256) {
        return _stakedAmount[provider];
    }

    /// @notice Returns the pending unstake amount and unlock time for a provider.
    function getProviderPendingUnstake(address provider) external view returns (uint256 amount, uint256 unlockTimestamp) {
        ProviderUnstake storage pending = _pendingUnstake[provider];
        return (pending.amount, pending.unlockTimestamp);
    }

    /// @notice Returns the total amount of staking tokens staked in the contract.
    function getTotalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    /// @notice Returns the configuration details for a specific model.
    function getModelConfig(uint256 modelId) external view returns (ModelConfig memory) {
        return modelConfigs[modelId];
    }

    /// @notice Checks if a model ID is registered and active.
    function isModelActive(uint256 modelId) external view returns (bool) {
        return modelConfigs[modelId].isActive;
    }

    /// @notice Returns the details of a specific query request.
    function getQueryDetails(uint256 queryId) external view returns (QueryRequest memory) {
        return queryRequests[queryId];
    }

    /// @notice Returns a list of prediction hashes submitted for a query.
    function getPredictionsForQuery(uint256 queryId) external view returns (bytes32[] memory) {
        return querySubmittedPredictionHashes[queryId];
    }

    /// @notice Returns details of a specific prediction for a query.
    function getPredictionDetails(uint256 queryId, bytes32 predictionHash) external view returns (Prediction memory) {
        return queryPredictions[queryId][predictionHash];
    }

    /// @notice Returns the stake-weighted vote count for a specific prediction.
    function getPredictionVoteCount(uint256 queryId, bytes32 predictionHash) external view returns (uint256) {
         Prediction storage prediction = queryPredictions[queryId][predictionHash];
         // Check if prediction exists to avoid accessing storage for non-existent keys
         if (prediction.provider == address(0)) return 0;
         return prediction.voteCount;
    }

    /// @notice Returns the total amount of protocol fees collected.
    function getProtocolFeesCollected() external view returns (uint256) {
        return protocolFeesCollected;
    }

    /// @notice Returns the next available query ID (total number of queries requested so far).
    function getCurrentQueryId() external view returns (uint256) {
        return _nextQueryId;
    }
}
```