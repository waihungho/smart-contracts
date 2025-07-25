Here's a Solidity smart contract named `AIEthosHub` that implements an advanced, creative, and trendy concept: a **Decentralized AI Model Evaluation & Collaboration Platform**. It introduces mechanisms for AI model providers and evaluators to participate, a reputation system, dispute resolution, collaborative AI training pools, and AI Asset NFTs.

The contract aims for uniqueness by combining these elements in a specific protocol design, focusing on on-chain orchestration of off-chain AI activities and reputation building.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Custom errors for better UX and gas efficiency
error InvalidStakeAmount();
error NotAuthorized();
error ModelNotFound();
error EvaluatorNotFound();
error TaskNotFound();
error InvalidTaskState();
error AlreadyRegistered();
error NotRegistered();
error InsufficientStake();
error DuplicateSubmission();
error InvalidScore();
error NotEnoughEvaluations();
error DisputeAlreadyResolved();
error NoActiveDispute();
error PoolNotFound();
error AlreadyInPool();
error NotInPool();
error PoolNotActive();
error NoContributions();
error NotPoolCreator();
error AlreadyClaimed();
error DelegationMismatch();
error CannotDelegateToSelf();
error AlreadyDelegated();
error DelegateeAlreadyDelegated();
error NoActiveDelegation();
error StakeRequired();
error ZeroAmount();
error RecipientIsZeroAddress();
error AmountTooLow();
error InvalidIndex();
error InvalidPreferenceWeight();
error MintingCriteriaNotMet();
error NotWinningModel();
error ModelStillHasStake();
error EvaluatorStillHasStake();
error EvaluationPeriodNotEnded();


/**
 * @title AIEthosHub
 * @dev A Decentralized AI Model Evaluation & Collaboration Platform.
 *      This contract facilitates the registration, evaluation, and collaboration around AI models.
 *      It incorporates a robust reputation system, dispute resolution mechanism, and advanced
 *      features like collaborative training pools and AI Asset NFTs.
 *
 * Outline:
 * I. Core Registry & Management: Functions for AI model providers and evaluators to register, stake, and manage their presence on the platform.
 * II. AI Task & Inference Management: Handles the lifecycle of AI inference tasks, from request to result submission and evaluation.
 * III. Reputation & Dispute System: Manages dynamic reputation scores for participants and a formalized process for dispute resolution.
 * IV. Advanced Concepts & Gamification: Introduces collaborative training pools, AI Asset NFTs for unique AI entities, delegation, and user preferences.
 * V. Administrative & Utility: Essential functions for protocol governance (initially by owner, later via DAO) and general utilities.
 *
 * Function Summary:
 *
 * I. Core Registry & Management
 * 1. registerAIModel(string memory _metadataCID): Allows an AI model provider to register their model's metadata (e.g., description, capabilities) stored off-chain.
 * 2. updateAIModelMetadata(uint256 _modelId, string memory _newMetadataCID): Updates the metadata for an already registered model.
 * 3. deregisterAIModel(uint256 _modelId): Allows a model provider to deregister their model, removing it from active participation. Requires no active stake.
 * 4. stakeModelProvider(uint256 _modelId, uint256 _amount): Model providers stake tokens to activate their model for inference tasks.
 * 5. unstakeModelProvider(uint256 _modelId): Model providers unstake their tokens from a deactivated or deregistered model.
 * 6. registerEvaluator(): Allows a user to register as an AI model evaluator.
 * 7. stakeEvaluator(uint256 _amount): Evaluators stake tokens to participate in evaluation tasks.
 * 8. unstakeEvaluator(): Evaluators unstake their tokens. Requires no active delegation or stake.
 *
 * II. AI Task & Inference Management
 * 9. requestInferenceTask(uint256[] memory _preferredModelIds, string memory _inputDataCID, uint256 _rewardAmount): A requester submits a new AI inference task, specifying preferred models and a reward.
 * 10. submitInferenceResult(uint256 _taskId, string memory _outputDataCID, uint256 _modelId): An AI model provider submits the hash of their off-chain inference result for a given task.
 * 11. assignEvaluatorsToTask(uint256 _taskId, uint256[] memory _evaluatorIds): Protocol (or future DAO) assigns qualified evaluators to an inference task.
 * 12. submitEvaluationScore(uint256 _taskId, uint256 _score): An assigned evaluator submits their score for an inference result.
 * 13. finalizeTaskEvaluation(uint256 _taskId): Finalizes the evaluation of a task, calculates the consensus score, updates reputations, and distributes rewards.
 *
 * III. Reputation & Dispute System
 * 14. challengeEvaluationScore(uint256 _taskId, uint256 _evaluationIndex, string memory _evidenceCID): A participant can challenge a specific evaluator's score on a task.
 * 15. challengeInferenceResult(uint256 _taskId, uint256 _modelId, string memory _evidenceCID): A participant can challenge the submitted inference result of a model.
 * 16. resolveDispute(uint256 _disputeId, bool _challengerWins, string memory _resolutionDetailsCID): The dispute resolution committee (or DAO) resolves an active dispute.
 * 17. getModelReputation(uint256 _modelId): Queries the current reputation score of an AI model.
 * 18. getEvaluatorReputation(uint256 _evaluatorId): Queries the current reputation score of an evaluator.
 *
 * IV. Advanced Concepts & Gamification
 * 19. proposeCollaborativeTrainingPool(string memory _poolMetadataCID, uint256 _rewardSplitBasis): Allows a user to propose a new collaborative pool for shared AI training or data collection.
 * 20. joinCollaborativePool(uint256 _poolId): Allows a user to join an existing collaborative training pool.
 * 21. submitPooledDataContribution(uint256 _poolId, string memory _dataCID, uint256 _contributionWeight): Participants contribute data/resources to a collaborative pool.
 * 22. depositPoolReward(uint256 _poolId, uint256 _amount): Allows anyone (e.g., pool creator or sponsor) to deposit rewards for a collaborative pool.
 * 23. finalizeCollaborativePool(uint256 _poolId, string memory _resultCID): The pool creator finalizes the pool, making its accumulated rewards distributable.
 * 24. claimPoolContributionReward(uint256 _poolId): Allows participants to claim their share of rewards from a finalized collaborative pool.
 * 25. mintAIAAssetNFT(uint256 _targetId, AIAAssetType _assetType, string memory _assetMetadataCID): Mints an AI Asset NFT for high-reputation models, datasets, or top evaluators.
 * 26. burnAIAAssetNFT(uint256 _tokenId): Burns an AI Asset NFT (e.g., if the underlying model is deprecated or reputation drops significantly).
 * 27. delegateEvaluationVotingPower(uint256 _evaluatorIdToDelegateTo): Allows an evaluator to delegate their evaluation power (reputation influence) to another evaluator.
 * 28. withdrawDelegatedEvaluationPower(): Allows an evaluator to withdraw their previously delegated power.
 * 29. signalModelPreference(bytes32 _modelTypeHash, uint256 _preferenceWeight): Users can signal their preference for certain model types, influencing dynamic rewards or discovery.
 *
 * V. Administrative & Utility
 * 30. setProtocolParameters(uint256 _minModelStake, uint256 _minEvaluatorStake, uint256 _disputeChallengeFee, uint256 _evaluationPeriod): Allows the owner to adjust core protocol parameters.
 * 31. withdrawProtocolFees(address _recipient): Allows the owner to withdraw accumulated protocol fees.
 * 32. emergencyPause(): Allows the owner to pause critical functions in an emergency.
 * 33. emergencyUnpause(): Allows the owner to unpause critical functions.
 */
contract AIEthosHub is Ownable, ERC721 {
    using Counters for Counters.Counter;

    IERC20 public immutable paymentToken;

    // --- State Variables & Data Structures ---

    // Constants for default parameters (can be updated by owner/DAO)
    uint256 public minModelStake;
    uint256 public minEvaluatorStake;
    uint256 public disputeChallengeFee; // Fee to challenge a score/result
    uint256 public evaluationPeriod;    // Time window for evaluators to submit scores
    uint256 public accumulatedProtocolFees; // Tracks fees collected by the protocol

    // Counters for unique IDs
    Counters.Counter private _modelIds;
    Counters.Counter private _evaluatorIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _poolIds;
    Counters.Counter private _aiaAssetTokenIds;

    // --- Enums ---
    enum ModelStatus { Inactive, Staked, Deregistered }
    enum EvaluatorStatus { Inactive, Staked }
    enum TaskStatus { Requested, ResultSubmitted, EvaluationAssigned, Evaluated, Disputed, Finalized }
    enum DisputeStatus { Open, ResolvedSuccessful, ResolvedUnsuccessful }
    enum PoolStatus { Open, Finalized, Distributed }
    enum AIAAssetType { ModelNFT, DatasetNFT, EvaluatorBadge } // Types of AI Asset NFTs

    // --- Structs ---

    struct AIModel {
        address provider;
        string metadataCID;     // IPFS CID for model description, capabilities etc.
        uint256 stakeAmount;
        ModelStatus status;
        int256 reputation;      // Signed integer for reputation
        uint256 registeredTimestamp;
        uint256 lastActivityTimestamp;
    }

    struct Evaluator {
        address wallet;
        uint256 stakeAmount;
        EvaluatorStatus status;
        int256 reputation;      // Signed integer for reputation
        uint256 registeredTimestamp;
        uint256 lastActivityTimestamp;
        uint256 delegatedTo;    // Evaluator ID to whom power is delegated (0 if not delegated)
    }

    struct InferenceTask {
        address requester;
        uint256[] preferredModelIds;
        string inputDataCID;    // IPFS CID for input data
        uint256 rewardAmount;   // Reward for successful model
        uint256 protocolFee;    // Protocol fee from the reward
        uint256 modelIdWinner;  // ID of the model that won the task
        string outputDataCIDWinner; // IPFS CID for winning output data
        TaskStatus status;
        uint256 submissionTimestamp;
        uint256 evaluationDeadline;
        mapping(uint256 => Evaluation) evaluations; // evaluatorId => Evaluation
        uint256[] assignedEvaluatorIds;
        uint256 evaluationCount;
        bool finalized;
    }

    struct Evaluation {
        uint256 evaluatorId;
        uint256 score;          // Raw score from evaluator (e.g., 0-100)
        string feedbackCID;     // IPFS CID for detailed feedback (optional)
        uint256 submissionTimestamp;
        bool challenged;
        bool agreedWithConsensus; // Whether this evaluation matched the final consensus after finalization
    }

    struct Dispute {
        uint256 taskId;
        uint256 challengedParticipantId; // Model ID or Evaluator ID
        bool isModelChallenge;           // True if model, false if evaluator
        uint256 challengeStake;          // Stake paid by challenger
        address challengerAddress;       // Address of the challenger
        string evidenceCID;              // IPFS CID for evidence
        DisputeStatus status;
        uint256 timestamp;
        string resolutionDetailsCID;     // IPFS CID for resolution details
    }

    struct CollaborativePool {
        address creator;
        string poolMetadataCID; // IPFS CID for pool description, goal, etc.
        uint256 rewardSplitBasis; // E.g., 100 for even split, or based on contributions (advanced)
        PoolStatus status;
        mapping(address => uint256) contributions; // Participant address => contribution weight/value
        mapping(address => bool) hasClaimedReward;
        uint256 totalContributionsWeight;
        string resultCID; // IPFS CID for the final output/result of the pool
        uint256 rewardBalance; // Specific balance for this pool
    }

    // --- Mappings ---
    mapping(uint256 => AIModel) public aiModels;
    mapping(address => uint256) public modelIdByProvider; // 0 if not registered
    mapping(uint256 => Evaluator) public evaluators;
    mapping(address => uint256) public evaluatorIdByWallet; // 0 if not registered
    mapping(uint256 => InferenceTask) public inferenceTasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => CollaborativePool) public collaborativePools;
    mapping(address => mapping(bytes32 => uint256)) public userModelPreferences; // user => modelTypeHash => preferenceWeight

    // --- Events ---
    event AIModelRegistered(uint256 indexed modelId, address indexed provider, string metadataCID);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newMetadataCID);
    event AIModelDeregistered(uint256 indexed modelId, address indexed provider);
    event ModelProviderStaked(uint256 indexed modelId, address indexed provider, uint256 amount);
    event ModelProviderUnstaked(uint256 indexed modelId, address indexed provider, uint256 amount);

    event EvaluatorRegistered(uint256 indexed evaluatorId, address indexed wallet);
    event EvaluatorStaked(uint256 indexed evaluatorId, address indexed wallet, uint256 amount);
    event EvaluatorUnstaked(uint256 indexed evaluatorId, address indexed wallet, uint256 amount);

    event InferenceTaskRequested(uint256 indexed taskId, address indexed requester, string inputDataCID, uint256 rewardAmount);
    event InferenceResultSubmitted(uint256 indexed taskId, uint256 indexed modelId, string outputDataCID);
    event EvaluatorsAssigned(uint256 indexed taskId, uint256[] evaluatorIds);
    event EvaluationScoreSubmitted(uint256 indexed taskId, uint256 indexed evaluatorId, uint256 score);
    event TaskEvaluationFinalized(uint256 indexed taskId, uint256 indexed winningModelId, int256 winningModelReputationChange);

    event EvaluationScoreChallenged(uint256 indexed disputeId, uint256 indexed taskId, uint256 indexed evaluatorId, address indexed challenger);
    event InferenceResultChallenged(uint256 indexed disputeId, uint256 indexed taskId, uint256 indexed modelId, address indexed challenger);
    event DisputeResolved(uint256 indexed disputeId, bool challengerWins);
    event ReputationUpdated(uint256 indexed participantId, bool isModel, int256 newReputation, int256 change);

    event CollaborativePoolProposed(uint256 indexed poolId, address indexed creator, string metadataCID);
    event CollaborativePoolJoined(uint256 indexed poolId, address indexed participant);
    event PooledDataContributed(uint256 indexed poolId, address indexed participant, string dataCID, uint256 weight);
    event PoolRewardDeposited(uint256 indexed poolId, address indexed depositor, uint256 amount);
    event CollaborativePoolFinalized(uint256 indexed poolId, string resultCID);
    event PoolContributionRewardClaimed(uint256 indexed poolId, address indexed participant, uint256 amount);

    event AIAAssetMinted(uint256 indexed tokenId, AIAAssetType indexed assetType, uint256 indexed targetId, address indexed owner);
    event AIAAssetBurned(uint256 indexed tokenId);

    event EvaluationVotingPowerDelegated(uint256 indexed fromEvaluatorId, uint256 indexed toEvaluatorId);
    event EvaluationVotingPowerWithdrawn(uint256 indexed evaluatorId);

    event ModelPreferenceSignaled(address indexed user, bytes32 indexed modelTypeHash, uint256 preferenceWeight);

    event ProtocolParametersUpdated(uint256 minModelStake, uint256 minEvaluatorStake, uint256 disputeChallengeFee, uint256 evaluationPeriod);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Pausable Modifier ---
    bool private _paused;

    modifier whenNotPaused() {
        if (_paused) revert("Pausable: paused");
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert("Pausable: not paused");
        _;
    }

    function emergencyPause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function emergencyUnpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Constructor ---
    constructor(address _paymentTokenAddress) ERC721("AI Ethos Asset", "AIA") Ownable(msg.sender) {
        if (_paymentTokenAddress == address(0)) revert RecipientIsZeroAddress();
        paymentToken = IERC20(_paymentTokenAddress);
        minModelStake = 100 * 10 ** 18;       // Example value (100 tokens with 18 decimals)
        minEvaluatorStake = 50 * 10 ** 18;    // Example value (50 tokens with 18 decimals)
        disputeChallengeFee = 10 * 10 ** 18;  // Example value (10 tokens with 18 decimals)
        evaluationPeriod = 72 hours;     // Example value (3 days)
        accumulatedProtocolFees = 0;
    }

    // --- Helper Functions ---
    function _updateModelReputation(uint256 _modelId, int256 _change) internal {
        AIModel storage model = aiModels[_modelId];
        model.reputation += _change;
        emit ReputationUpdated(_modelId, true, model.reputation, _change);
    }

    function _updateEvaluatorReputation(uint256 _evaluatorId, int256 _change) internal {
        Evaluator storage evaluator = evaluators[_evaluatorId];
        evaluator.reputation += _change;
        emit ReputationUpdated(_evaluatorId, false, evaluator.reputation, _change);
    }

    function _calculateConsensusScore(uint256 _taskId) internal view returns (uint256 consensusScore, uint256 totalEvaluationsSubmitted) {
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.evaluationCount == 0) {
            return (0, 0);
        }

        uint256 sumScores = 0;
        for (uint256 i = 0; i < task.assignedEvaluatorIds.length; i++) {
            uint256 evaluatorId = task.assignedEvaluatorIds[i];
            Evaluation storage eval = task.evaluations[evaluatorId];
            if (eval.evaluatorId != 0) { // Check if an evaluation was submitted
                 sumScores += eval.score;
            }
        }
        return (sumScores / task.evaluationCount, task.evaluationCount);
    }

    function _chargeTokens(address _from, uint256 _amount) internal {
        if (_amount == 0) revert ZeroAmount();
        require(paymentToken.transferFrom(_from, address(this), _amount), "Token transfer failed");
    }

    // --- I. Core Registry & Management ---

    /// @notice Registers a new AI model with its metadata.
    /// @param _metadataCID IPFS CID pointing to the model's description and capabilities.
    function registerAIModel(string memory _metadataCID) public whenNotPaused {
        if (modelIdByProvider[msg.sender] != 0) revert AlreadyRegistered();
        _modelIds.increment();
        uint256 newModelId = _modelIds.current();
        aiModels[newModelId] = AIModel({
            provider: msg.sender,
            metadataCID: _metadataCID,
            stakeAmount: 0,
            status: ModelStatus.Inactive,
            reputation: 0,
            registeredTimestamp: block.timestamp,
            lastActivityTimestamp: block.timestamp
        });
        modelIdByProvider[msg.sender] = newModelId;
        emit AIModelRegistered(newModelId, msg.sender, _metadataCID);
    }

    /// @notice Updates the metadata for an already registered AI model.
    /// @param _modelId The ID of the model to update.
    /// @param _newMetadataCID New IPFS CID for the model's metadata.
    function updateAIModelMetadata(uint256 _modelId, string memory _newMetadataCID) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotAuthorized();
        if (model.status == ModelStatus.Deregistered) revert InvalidTaskState(); // Cannot update if deregistered
        model.metadataCID = _newMetadataCID;
        emit AIModelMetadataUpdated(_modelId, _newMetadataCID);
    }

    /// @notice Deregisters an AI model, removing it from active participation.
    ///         Requires unstaking any staked tokens first.
    /// @param _modelId The ID of the model to deregister.
    function deregisterAIModel(uint256 _modelId) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotAuthorized();
        if (model.status == ModelStatus.Deregistered) revert InvalidTaskState();
        if (model.stakeAmount > 0) revert ModelStillHasStake();
        model.status = ModelStatus.Deregistered;
        modelIdByProvider[msg.sender] = 0; // Clear mapping for provider
        emit AIModelDeregistered(_modelId, msg.sender);
    }

    /// @notice Model providers stake tokens to activate their model for inference tasks.
    /// @param _modelId The ID of the model to stake for.
    /// @param _amount The amount of tokens to stake.
    function stakeModelProvider(uint256 _modelId, uint256 _amount) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotAuthorized();
        if (model.status == ModelStatus.Deregistered) revert InvalidTaskState();
        if (_amount < minModelStake) revert AmountTooLow();

        _chargeTokens(msg.sender, _amount);
        model.stakeAmount += _amount;
        model.status = ModelStatus.Staked;
        emit ModelProviderStaked(_modelId, msg.sender, _amount);
    }

    /// @notice Model providers unstake their tokens from a deactivated or deregistered model.
    ///         Requires the model to be Inactive or Deregistered.
    /// @param _modelId The ID of the model to unstake from.
    function unstakeModelProvider(uint256 _modelId) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotAuthorized();
        if (model.stakeAmount == 0) revert InsufficientStake();
        
        uint256 amountToTransfer = model.stakeAmount;
        model.stakeAmount = 0;
        if (model.status == ModelStatus.Staked) { // If was staked, now inactive. If deregistered, stays deregistered.
            model.status = ModelStatus.Inactive;
        }
        require(paymentToken.transfer(msg.sender, amountToTransfer), "Unstake transfer failed");
        emit ModelProviderUnstaked(_modelId, msg.sender, amountToTransfer);
    }

    /// @notice Allows a user to register as an AI model evaluator.
    function registerEvaluator() public whenNotPaused {
        if (evaluatorIdByWallet[msg.sender] != 0) revert AlreadyRegistered();
        _evaluatorIds.increment();
        uint256 newEvaluatorId = _evaluatorIds.current();
        evaluators[newEvaluatorId] = Evaluator({
            wallet: msg.sender,
            stakeAmount: 0,
            status: EvaluatorStatus.Inactive,
            reputation: 0,
            registeredTimestamp: block.timestamp,
            lastActivityTimestamp: block.timestamp,
            delegatedTo: 0
        });
        evaluatorIdByWallet[msg.sender] = newEvaluatorId;
        emit EvaluatorRegistered(newEvaluatorId, msg.sender);
    }

    /// @notice Evaluators stake tokens to participate in evaluation tasks.
    /// @param _amount The amount of tokens to stake.
    function stakeEvaluator(uint256 _amount) public whenNotPaused {
        uint256 evaluatorId = evaluatorIdByWallet[msg.sender];
        if (evaluatorId == 0) revert NotRegistered();
        if (_amount < minEvaluatorStake) revert AmountTooLow();

        _chargeTokens(msg.sender, _amount);
        Evaluator storage evaluator = evaluators[evaluatorId];
        evaluator.stakeAmount += _amount;
        evaluator.status = EvaluatorStatus.Staked;
        emit EvaluatorStaked(evaluatorId, msg.sender, _amount);
    }

    /// @notice Evaluators unstake their tokens. Requires no active evaluations or delegations.
    function unstakeEvaluator() public whenNotPaused {
        uint256 evaluatorId = evaluatorIdByWallet[msg.sender];
        if (evaluatorId == 0) revert NotRegistered();
        Evaluator storage evaluator = evaluators[evaluatorId];
        if (evaluator.stakeAmount == 0) revert InsufficientStake();
        if (evaluator.delegatedTo != 0) revert NoActiveDelegation(); // Cannot unstake if power is delegated
        // TODO: Add check if any active tasks are assigned to this evaluator

        uint256 amountToTransfer = evaluator.stakeAmount;
        evaluator.stakeAmount = 0;
        evaluator.status = EvaluatorStatus.Inactive;
        require(paymentToken.transfer(msg.sender, amountToTransfer), "Unstake transfer failed");
        emit EvaluatorUnstaked(evaluatorId, msg.sender, amountToTransfer);
    }


    // --- II. AI Task & Inference Management ---

    /// @notice A requester submits a new AI inference task.
    /// @param _preferredModelIds Optional array of preferred model IDs.
    /// @param _inputDataCID IPFS CID for the input data.
    /// @param _rewardAmount The total reward for the winning model.
    function requestInferenceTask(uint256[] memory _preferredModelIds, string memory _inputDataCID, uint256 _rewardAmount) public whenNotPaused {
        if (_rewardAmount == 0) revert ZeroAmount();
        
        // Calculate protocol fee (e.g., 10%)
        uint256 protocolFee = _rewardAmount / 10; // 10%
        uint256 totalAmount = _rewardAmount + protocolFee;

        _chargeTokens(msg.sender, totalAmount); // Requester pays total amount including fee

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        inferenceTasks[newTaskId] = InferenceTask({
            requester: msg.sender,
            preferredModelIds: _preferredModelIds,
            inputDataCID: _inputDataCID,
            rewardAmount: _rewardAmount,
            protocolFee: protocolFee,
            modelIdWinner: 0,
            outputDataCIDWinner: "",
            status: TaskStatus.Requested,
            submissionTimestamp: block.timestamp,
            evaluationDeadline: 0, // Set later when evaluators assigned
            evaluationCount: 0,
            finalized: false,
            evaluations: new Mapping(uint256 => Evaluation),
            assignedEvaluatorIds: new uint256[](0)
        });

        emit InferenceTaskRequested(newTaskId, msg.sender, _inputDataCID, _rewardAmount);
    }

    /// @notice An AI model provider submits the hash of their off-chain inference result.
    /// @param _taskId The ID of the task.
    /// @param _outputDataCID IPFS CID for the inference result.
    /// @param _modelId The ID of the model submitting the result.
    function submitInferenceResult(uint256 _taskId, string memory _outputDataCID, uint256 _modelId) public whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Requested) revert InvalidTaskState();

        AIModel storage model = aiModels[_modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotAuthorized();
        if (model.status != ModelStatus.Staked) revert StakeRequired();

        // For simplicity, assuming a single model submits. In a competitive setup, multiple could submit.
        task.modelIdWinner = _modelId;
        task.outputDataCIDWinner = _outputDataCID;
        task.status = TaskStatus.ResultSubmitted; // Ready for evaluation assignment
        task.submissionTimestamp = block.timestamp;

        emit InferenceResultSubmitted(_taskId, _modelId, _outputDataCID);
    }

    /// @notice Assigns qualified evaluators to an inference task.
    ///         This function would typically be called by an off-chain oracle, a DAO, or an admin.
    /// @param _taskId The ID of the task to assign evaluators for.
    /// @param _evaluatorIds An array of evaluator IDs chosen for this task.
    function assignEvaluatorsToTask(uint256 _taskId, uint256[] memory _evaluatorIds) public onlyOwner whenNotPaused { // Could be DAO in future
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.ResultSubmitted) revert InvalidTaskState();
        if (_evaluatorIds.length == 0) revert InvalidStakeAmount(); // Using InvalidStakeAmount as a generic "empty array" error

        for (uint256 i = 0; i < _evaluatorIds.length; i++) {
            uint256 evaluatorId = _evaluatorIds[i];
            Evaluator storage evaluator = evaluators[evaluatorId];
            if (evaluator.wallet == address(0)) revert EvaluatorNotFound();
            if (evaluator.status != EvaluatorStatus.Staked) revert StakeRequired();
            
            task.assignedEvaluatorIds.push(evaluatorId);
        }

        task.evaluationDeadline = block.timestamp + evaluationPeriod;
        task.status = TaskStatus.EvaluationAssigned;
        emit EvaluatorsAssigned(_taskId, _evaluatorIds);
    }

    /// @notice An assigned evaluator submits their score for an inference result.
    /// @param _taskId The ID of the task being evaluated.
    /// @param _score The numerical score (e.g., 0-100).
    function submitEvaluationScore(uint256 _taskId, uint256 _score) public whenNotPaused {
        uint256 evaluatorId = evaluatorIdByWallet[msg.sender];
        if (evaluatorId == 0) revert NotRegistered();
        
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.EvaluationAssigned) revert InvalidTaskState();
        if (block.timestamp > task.evaluationDeadline) revert EvaluationPeriodNotEnded();
        if (_score > 100) revert InvalidScore(); // Assuming 0-100 range

        bool isAssigned = false;
        for (uint256 i = 0; i < task.assignedEvaluatorIds.length; i++) {
            if (task.assignedEvaluatorIds[i] == evaluatorId) {
                isAssigned = true;
                break;
            }
        }
        if (!isAssigned) revert NotAuthorized(); // Evaluator not assigned to this task
        if (task.evaluations[evaluatorId].evaluatorId != 0) revert DuplicateSubmission();

        task.evaluations[evaluatorId] = Evaluation({
            evaluatorId: evaluatorId,
            score: _score,
            feedbackCID: "", // Optional, can add as param
            submissionTimestamp: block.timestamp,
            challenged: false,
            agreedWithConsensus: false
        });
        task.evaluationCount++;
        evaluators[evaluatorId].lastActivityTimestamp = block.timestamp;
        emit EvaluationScoreSubmitted(_taskId, evaluatorId, _score);
    }

    /// @notice Finalizes the evaluation of a task, calculates consensus, updates reputations, and distributes rewards.
    ///         Can be called by anyone after the evaluation deadline, or by admin if all evaluations are in early.
    /// @param _taskId The ID of the task to finalize.
    function finalizeTaskEvaluation(uint256 _taskId) public whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.EvaluationAssigned) revert InvalidTaskState();
        if (block.timestamp <= task.evaluationDeadline && task.evaluationCount < task.assignedEvaluatorIds.length) revert EvaluationPeriodNotEnded();
        if (task.finalized) revert InvalidTaskState(); // Already finalized
        if (task.evaluationCount == 0) revert NotEnoughEvaluations();

        (uint256 consensusScore, ) = _calculateConsensusScore(_taskId);
        
        // Reward model winner
        AIModel storage winningModel = aiModels[task.modelIdWinner];
        if (winningModel.provider == address(0)) revert ModelNotFound();
        require(paymentToken.transfer(winningModel.provider, task.rewardAmount), "Reward transfer failed");
        
        // Example: Reputation change is proportional to reward amount (e.g., 1 point for every 10 tokens)
        int256 winningModelReputationChange = int256(task.rewardAmount / (10 ** 18 * 10)); 
        _updateModelReputation(task.modelIdWinner, winningModelReputationChange);

        // Update evaluator reputations based on consensus
        for (uint256 i = 0; i < task.assignedEvaluatorIds.length; i++) {
            uint256 evaluatorId = task.assignedEvaluatorIds[i];
            Evaluation storage eval = task.evaluations[evaluatorId];
            if (eval.evaluatorId != 0) { // If evaluator submitted a score
                // Check how close the score is to consensus (e.g., within +/- 10 points)
                if (eval.score >= consensusScore - 10 && eval.score <= consensusScore + 10) {
                    _updateEvaluatorReputation(evaluatorId, 1); // Positive reputation for agreeing
                    eval.agreedWithConsensus = true;
                } else {
                    _updateEvaluatorReputation(evaluatorId, -1); // Negative reputation for disagreeing
                    eval.agreedWithConsensus = false;
                }
            }
        }
        
        task.status = TaskStatus.Finalized;
        task.finalized = true;

        // Accumulate protocol fees
        accumulatedProtocolFees += task.protocolFee;

        emit TaskEvaluationFinalized(_taskId, task.modelIdWinner, winningModelReputationChange);
    }

    // --- III. Reputation & Dispute System ---

    /// @notice Allows a participant to challenge a specific evaluator's score on a task.
    /// @param _taskId The ID of the task.
    /// @param _evaluationIndex The index of the evaluation (position in assignedEvaluatorIds array).
    /// @param _evidenceCID IPFS CID for evidence supporting the challenge.
    function challengeEvaluationScore(uint256 _taskId, uint256 _evaluationIndex, string memory _evidenceCID) public whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Finalized) revert InvalidTaskState();
        if (_evaluationIndex >= task.assignedEvaluatorIds.length) revert InvalidIndex();

        uint256 evaluatorIdToChallenge = task.assignedEvaluatorIds[_evaluationIndex];
        Evaluation storage eval = task.evaluations[evaluatorIdToChallenge];
        if (eval.evaluatorId == 0) revert EvaluatorNotFound(); // No evaluation at this index
        if (eval.challenged) revert DisputeAlreadyResolved(); 

        _chargeTokens(msg.sender, disputeChallengeFee);

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            taskId: _taskId,
            challengedParticipantId: evaluatorIdToChallenge,
            isModelChallenge: false,
            challengeStake: disputeChallengeFee,
            challengerAddress: msg.sender,
            evidenceCID: _evidenceCID,
            status: DisputeStatus.Open,
            timestamp: block.timestamp,
            resolutionDetailsCID: ""
        });
        eval.challenged = true;
        task.status = TaskStatus.Disputed; // Set task status to disputed
        emit EvaluationScoreChallenged(newDisputeId, _taskId, evaluatorIdToChallenge, msg.sender);
    }

    /// @notice Allows a participant to challenge the submitted inference result of a model.
    /// @param _taskId The ID of the task.
    /// @param _modelId The ID of the model whose result is challenged.
    /// @param _evidenceCID IPFS CID for evidence supporting the challenge.
    function challengeInferenceResult(uint256 _taskId, uint256 _modelId, string memory _evidenceCID) public whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Finalized) revert InvalidTaskState();
        if (task.modelIdWinner != _modelId) revert NotWinningModel();

        // Prevent double challenging the same model for the same task
        for (uint256 i = 1; i <= _disputeIds.current(); i++) {
            Dispute storage existingDispute = disputes[i];
            if (existingDispute.taskId == _taskId && existingDispute.isModelChallenge && existingDispute.challengedParticipantId == _modelId && existingDispute.status == DisputeStatus.Open) {
                revert DisputeAlreadyResolved(); // Already under dispute
            }
        }

        _chargeTokens(msg.sender, disputeChallengeFee);

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            taskId: _taskId,
            challengedParticipantId: _modelId,
            isModelChallenge: true,
            challengeStake: disputeChallengeFee,
            challengerAddress: msg.sender,
            evidenceCID: _evidenceCID,
            status: DisputeStatus.Open,
            timestamp: block.timestamp,
            resolutionDetailsCID: ""
        });
        task.status = TaskStatus.Disputed; // Set task status to disputed
        emit InferenceResultChallenged(newDisputeId, _taskId, _modelId, msg.sender);
    }

    /// @notice The dispute resolution committee (or DAO) resolves an active dispute.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _challengerWins True if the challenger's claim is upheld, false otherwise.
    /// @param _resolutionDetailsCID IPFS CID for details of the resolution.
    function resolveDispute(uint256 _disputeId, bool _challengerWins, string memory _resolutionDetailsCID) public onlyOwner whenNotPaused { // Should be DAO/committee in production
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.taskId == 0) revert NoActiveDispute();
        if (dispute.status != DisputeStatus.Open) revert DisputeAlreadyResolved();

        InferenceTask storage task = inferenceTasks[dispute.taskId];
        uint256 participantId = dispute.challengedParticipantId;

        if (_challengerWins) {
            // Challenger wins: Challenger gets stake back + reward. Loser is penalized.
            require(paymentToken.transfer(dispute.challengerAddress, dispute.challengeStake), "Challenger reward failed");
            if (dispute.isModelChallenge) {
                _updateModelReputation(participantId, -10); // Significant reputation loss
                // Example: take a fixed penalty from the model's stake if sufficient
                AIModel storage model = aiModels[participantId];
                uint256 penaltyAmount = model.stakeAmount > 0 ? model.stakeAmount / 10 : 0; // 10% of stake
                if (penaltyAmount > 0) {
                     require(paymentToken.transfer(dispute.challengerAddress, penaltyAmount), "Model penalty transfer failed");
                     model.stakeAmount -= penaltyAmount;
                }
            } else {
                _updateEvaluatorReputation(participantId, -5); // Moderate reputation loss
                // Example: seize part of evaluator's stake
                Evaluator storage evaluator = evaluators[participantId];
                uint256 penaltyAmount = evaluator.stakeAmount > 0 ? evaluator.stakeAmount / 10 : 0; // 10% of stake
                if (penaltyAmount > 0) {
                    require(paymentToken.transfer(dispute.challengerAddress, penaltyAmount), "Evaluator penalty transfer failed");
                    evaluator.stakeAmount -= penaltyAmount;
                }
            }
            dispute.status = DisputeStatus.ResolvedSuccessful;
        } else {
            // Challenger loses: Challenger's stake is transferred to accumulated protocol fees.
            accumulatedProtocolFees += dispute.challengeStake;
            if (dispute.isModelChallenge) {
                _updateModelReputation(participantId, 1);
            } else {
                _updateEvaluatorReputation(participantId, 1);
            }
            dispute.status = DisputeStatus.ResolvedUnsuccessful;
        }
        dispute.resolutionDetailsCID = _resolutionDetailsCID;
        // After dispute, set task status back to Finalized (or a new status if results need correction)
        task.status = TaskStatus.Finalized;
        emit DisputeResolved(_disputeId, _challengerWins);
    }

    /// @notice Queries the current reputation score of an AI model.
    /// @param _modelId The ID of the AI model.
    /// @return The reputation score.
    function getModelReputation(uint256 _modelId) public view returns (int256) {
        if (aiModels[_modelId].provider == address(0)) revert ModelNotFound();
        return aiModels[_modelId].reputation;
    }

    /// @notice Queries the current reputation score of an evaluator.
    /// @param _evaluatorId The ID of the evaluator.
    /// @return The reputation score.
    function getEvaluatorReputation(uint256 _evaluatorId) public view returns (int256) {
        if (evaluators[_evaluatorId].wallet == address(0)) revert EvaluatorNotFound();
        return evaluators[_evaluatorId].reputation;
    }

    // --- IV. Advanced Concepts & Gamification ---

    /// @notice Allows a user to propose a new collaborative pool for shared AI training or data collection.
    /// @param _poolMetadataCID IPFS CID for the pool's description, goals, and rules.
    /// @param _rewardSplitBasis Defines how rewards will be split (e.g., 100 for even, or based on contributions).
    function proposeCollaborativeTrainingPool(string memory _poolMetadataCID, uint256 _rewardSplitBasis) public whenNotPaused {
        _poolIds.increment();
        uint256 newPoolId = _poolIds.current();

        collaborativePools[newPoolId] = CollaborativePool({
            creator: msg.sender,
            poolMetadataCID: _poolMetadataCID,
            rewardSplitBasis: _rewardSplitBasis,
            status: PoolStatus.Open,
            contributions: new Mapping(address => uint256), // Initialize mapping
            hasClaimedReward: new Mapping(address => bool), // Initialize mapping
            totalContributionsWeight: 0,
            resultCID: "",
            rewardBalance: 0
        });
        emit CollaborativePoolProposed(newPoolId, msg.sender, _poolMetadataCID);
    }

    /// @notice Allows a user to join an existing collaborative training pool.
    /// @param _poolId The ID of the collaborative pool to join.
    function joinCollaborativePool(uint256 _poolId) public whenNotPaused {
        CollaborativePool storage pool = collaborativePools[_poolId];
        if (pool.creator == address(0)) revert PoolNotFound();
        if (pool.status != PoolStatus.Open) revert PoolNotActive();
        if (pool.contributions[msg.sender] != 0) revert AlreadyInPool(); // If they have any contribution, they're "in"

        pool.contributions[msg.sender] = 0; // Initialize contribution to 0 for tracking participation
        emit CollaborativePoolJoined(_poolId, msg.sender);
    }

    /// @notice Participants contribute data/resources to a collaborative pool.
    /// @param _poolId The ID of the collaborative pool.
    /// @param _dataCID IPFS CID for the contributed data/resource.
    /// @param _contributionWeight Numerical weight representing the value/impact of the contribution.
    function submitPooledDataContribution(uint256 _poolId, string memory _dataCID, uint256 _contributionWeight) public whenNotPaused {
        CollaborativePool storage pool = collaborativePools[_poolId];
        if (pool.creator == address(0)) revert PoolNotFound();
        if (pool.status != PoolStatus.Open) revert PoolNotActive();
        if (pool.contributions[msg.sender] == 0 && pool.creator != msg.sender) revert NotInPool(); // Must have joined or be creator
        if (_contributionWeight == 0) revert NoContributions();

        pool.contributions[msg.sender] += _contributionWeight;
        pool.totalContributionsWeight += _contributionWeight;
        emit PooledDataContributed(_poolId, msg.sender, _dataCID, _contributionWeight);
    }

    /// @notice Allows anyone (e.g., pool creator or sponsor) to deposit rewards for a collaborative pool.
    /// @param _poolId The ID of the collaborative pool.
    /// @param _amount The amount of tokens to deposit as reward.
    function depositPoolReward(uint256 _poolId, uint256 _amount) public whenNotPaused {
        CollaborativePool storage pool = collaborativePools[_poolId];
        if (pool.creator == address(0)) revert PoolNotFound();
        if (_amount == 0) revert ZeroAmount();

        _chargeTokens(msg.sender, _amount);
        pool.rewardBalance += _amount;
        emit PoolRewardDeposited(_poolId, msg.sender, _amount);
    }

    /// @notice The pool creator finalizes the pool, making its accumulated rewards distributable.
    ///         This means the collaborative work is complete and results are available.
    /// @param _poolId The ID of the collaborative pool.
    /// @param _resultCID IPFS CID for the final output/result of the pool.
    function finalizeCollaborativePool(uint256 _poolId, string memory _resultCID) public whenNotPaused {
        CollaborativePool storage pool = collaborativePools[_poolId];
        if (pool.creator == address(0)) revert PoolNotFound();
        if (pool.creator != msg.sender) revert NotPoolCreator();
        if (pool.status != PoolStatus.Open) revert InvalidTaskState(); // Not open for finalization
        if (pool.totalContributionsWeight == 0) revert NoContributions();

        pool.status = PoolStatus.Finalized;
        pool.resultCID = _resultCID;
        emit CollaborativePoolFinalized(_poolId, _resultCID);
    }

    /// @notice Allows participants to claim their share of rewards from a finalized collaborative pool.
    /// @param _poolId The ID of the collaborative pool.
    function claimPoolContributionReward(uint256 _poolId) public whenNotPaused {
        CollaborativePool storage pool = collaborativePools[_poolId];
        if (pool.creator == address(0)) revert PoolNotFound();
        if (pool.status != PoolStatus.Finalized) revert InvalidTaskState(); // Pool not finalized
        if (pool.contributions[msg.sender] == 0) revert NotInPool();
        if (pool.hasClaimedReward[msg.sender]) revert AlreadyClaimed();
        if (pool.totalContributionsWeight == 0) revert NoContributions(); // Should not happen if finalized

        uint256 participantShare = (pool.rewardBalance * pool.contributions[msg.sender]) / pool.totalContributionsWeight;
        if (participantShare == 0) revert NoContributions(); // Must have a positive share

        pool.hasClaimedReward[msg.sender] = true;
        pool.rewardBalance -= participantShare; // Deduct from pool's balance

        require(paymentToken.transfer(msg.sender, participantShare), "Reward transfer failed");
        emit PoolContributionRewardClaimed(_poolId, msg.sender, participantShare);
    }

    /// @notice Mints an AI Asset NFT for high-reputation models or top evaluators.
    ///         These NFTs can signify achievement, ownership, or special access.
    /// @param _targetId The ID of the model or evaluator to mint for.
    /// @param _assetType The type of AI Asset (ModelNFT, DatasetNFT, EvaluatorBadge).
    /// @param _assetMetadataCID IPFS CID for NFT-specific metadata.
    function mintAIAAssetNFT(uint256 _targetId, AIAAssetType _assetType, string memory _assetMetadataCID) public onlyOwner whenNotPaused { // Could be DAO decision
        address recipient = address(0);
        bool canMint = false;

        if (_assetType == AIAAssetType.ModelNFT) {
            AIModel storage model = aiModels[_targetId];
            if (model.provider != address(0) && model.reputation >= 100) { // Example threshold
                canMint = true;
                recipient = model.provider;
            }
        } else if (_assetType == AIAAssetType.EvaluatorBadge) {
            Evaluator storage evaluator = evaluators[_targetId];
            if (evaluator.wallet != address(0) && evaluator.reputation >= 50) { // Example threshold
                canMint = true;
                recipient = evaluator.wallet;
            }
        } else if (_assetType == AIAAssetType.DatasetNFT) {
            // For DatasetNFT, _targetId would refer to a dataset ID, and criteria
            // would involve verification (e.g., quality, uniqueness).
            // Placeholder: Assume _targetId is a valid dataset ID and conditions are met.
            canMint = true;
            recipient = owner(); // For demonstration, mint to the contract owner who called this.
                                // In a real scenario, this would be the dataset's verified owner.
        }
        if (!canMint || recipient == address(0)) revert MintingCriteriaNotMet();

        _aiaAssetTokenIds.increment();
        uint256 newTokenId = _aiaAssetTokenIds.current();
        
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, _assetMetadataCID); // Set URI for this specific NFT

        emit AIAAssetMinted(newTokenId, _assetType, _targetId, recipient);
    }
    
    /// @notice Burns an AI Asset NFT (e.g., if the underlying model is deprecated or reputation drops significantly).
    /// @param _tokenId The ID of the NFT to burn.
    function burnAIAAssetNFT(uint256 _tokenId) public onlyOwner whenNotPaused { // Could be DAO decision
        if (!_exists(_tokenId)) revert InvalidIndex(); // Reusing InvalidIndex for "token does not exist"
        _burn(_tokenId);
        emit AIAAssetBurned(_tokenId);
    }


    /// @notice Allows an evaluator to delegate their evaluation power (reputation influence) to another evaluator.
    ///         The delegatee's performance will indirectly affect the delegator's standing.
    /// @param _evaluatorIdToDelegateTo The ID of the evaluator to whom power is delegated.
    function delegateEvaluationVotingPower(uint256 _evaluatorIdToDelegateTo) public whenNotPaused {
        uint256 delegatorId = evaluatorIdByWallet[msg.sender];
        if (delegatorId == 0) revert NotRegistered();
        if (_evaluatorIdToDelegateTo == 0) revert EvaluatorNotFound();
        if (delegatorId == _evaluatorIdToDelegateTo) revert CannotDelegateToSelf();

        Evaluator storage delegator = evaluators[delegatorId];
        Evaluator storage delegatee = evaluators[_evaluatorIdToDelegateTo];

        if (delegator.status != EvaluatorStatus.Staked) revert StakeRequired();
        if (delegatee.status != EvaluatorStatus.Staked) revert StakeRequired();
        if (delegator.delegatedTo != 0) revert AlreadyDelegated();
        if (delegatee.delegatedTo != 0) revert DelegateeAlreadyDelegated(); // Disallow chaining delegation

        delegator.delegatedTo = _evaluatorIdToDelegateTo;
        // The reputation changes on `_updateEvaluatorReputation` for the delegatee
        // could be designed to indirectly impact the delegator's reputation or a separate "delegated reputation" score.
        // For this version, delegation primarily means the delegatee can act on behalf of the delegator's stake/influence.
        emit EvaluationVotingPowerDelegated(delegatorId, _evaluatorIdToDelegateTo);
    }

    /// @notice Allows an evaluator to withdraw their previously delegated power.
    function withdrawDelegatedEvaluationPower() public whenNotPaused {
        uint256 delegatorId = evaluatorIdByWallet[msg.sender];
        if (delegatorId == 0) revert NotRegistered();
        
        Evaluator storage delegator = evaluators[delegatorId];
        if (delegator.delegatedTo == 0) revert NoActiveDelegation();

        delegator.delegatedTo = 0; // Clear delegation
        emit EvaluationVotingPowerWithdrawn(delegatorId);
    }

    /// @notice Users can signal their preference for certain model types or attributes.
    ///         This could influence dynamic reward allocation or model discovery by off-chain systems or future DAO.
    /// @param _modelTypeHash Hash representing a desired model type/attribute (e.g., from an enum or string).
    /// @param _preferenceWeight A numerical weight for this preference (e.g., 1-10).
    function signalModelPreference(bytes32 _modelTypeHash, uint256 _preferenceWeight) public whenNotPaused {
        if (_preferenceWeight == 0) revert InvalidPreferenceWeight(); 
        userModelPreferences[msg.sender][_modelTypeHash] = _preferenceWeight;
        emit ModelPreferenceSignaled(msg.sender, _modelTypeHash, _preferenceWeight);
    }


    // --- V. Administrative & Utility ---

    /// @notice Allows the owner to adjust core protocol parameters. Will be replaced by DAO governance.
    function setProtocolParameters(uint256 _minModelStake, uint256 _minEvaluatorStake, uint256 _disputeChallengeFee, uint256 _evaluationPeriod) public onlyOwner {
        minModelStake = _minModelStake;
        minEvaluatorStake = _minEvaluatorStake;
        disputeChallengeFee = _disputeChallengeFee;
        evaluationPeriod = _evaluationPeriod;
        emit ProtocolParametersUpdated(_minModelStake, _minEvaluatorStake, _disputeChallengeFee, _evaluationPeriod);
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    /// @param _recipient The address to send the fees to.
    function withdrawProtocolFees(address _recipient) public onlyOwner {
        if (_recipient == address(0)) revert RecipientIsZeroAddress();
        if (accumulatedProtocolFees == 0) revert ZeroAmount();

        uint256 amount = accumulatedProtocolFees;
        accumulatedProtocolFees = 0; // Reset accumulated fees

        require(paymentToken.transfer(_recipient, amount), "Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }
}
```