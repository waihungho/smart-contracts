```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

/**
 * @title CogniChain_Nexus
 * @dev A decentralized, crypto-economically incentivized platform for AI model and dataset
 *      registration, validation, and access tokenization. It leverages a staked validator
 *      network to verify performance claims about off-chain AI models and curate datasets,
 *      ensuring trust and quality within a decentralized ecosystem.
 *      This contract focuses on the on-chain orchestration of metadata, tokenized access,
 *      and a crypto-economic challenge/validation mechanism, with the actual heavy
 *      computation (AI inference, model validation) happening off-chain.
 *
 * Key Features:
 * - AI Model Tokenization: Creators can register AI models, declare performance claims,
 *   and tokenize access or fractional ownership using ERC-1155.
 * - Dataset Curation & Tokenization: Users can contribute datasets, which can be certified
 *   for quality, and then tokenized for access.
 * - Decentralized Validation Network: A network of staked validators performs off-chain
 *   verification of AI model performance claims based on specified datasets.
 * - Challenge & Dispute Mechanism: Users can challenge model claims, triggering a validation
 *   process. Validators are rewarded for honest submissions and slashed for dishonest ones.
 * - Reputation System: Tracks the reliability and quality contribution of participants
 *   (creators, validators, dataset contributors).
 * - Protocol Fees: Sustainable fee model for platform operation and treasury.
 */

// Function Summary:

// I. Administrative & Configuration
// 1. constructor(address _protocolToken, string memory _baseTokenURI): Initializes the contract, sets the owner, protocol token, and base URI for ERC1155 tokens.
// 2. updateProtocolParameter(uint256 _paramId, uint256 _newValue): Allows the owner to adjust critical protocol parameters (e.g., fees, stake amounts).
// 3. pause(): Pauses core contract functionalities in emergencies.
// 4. unpause(): Resumes core contract functionalities.
// 5. withdrawProtocolFees(address _tokenAddress): Allows the owner to withdraw accumulated protocol fees in a specific token.

// II. AI Model Management
// 6. submitModel(string memory _modelURI, string memory _performanceClaimURI, string memory _description): Registers a new AI model with its off-chain URI, performance claims, and description.
// 7. updateModel(uint256 _modelId, string memory _modelURI, string memory _performanceClaimURI, string memory _description): Updates metadata for an existing model.
// 8. tokenizeModelAccess(uint256 _modelId, uint256 _initialSupply, uint256 _pricePerToken, string memory _tokenURI): Mints ERC-1155 tokens representing access rights or fractional ownership for a validated model.
// 9. setModelInferencePrice(uint256 _modelId, uint256 _priceInWei): Sets the price for consuming inference services from a specific model.
// 10. retireModel(uint256 _modelId): Marks a model as retired, preventing new access token minting or challenges.

// III. Dataset Management
// 11. submitDataset(string memory _datasetURI, string memory _description): Registers a new dataset with its off-chain URI and description.
// 12. updateDataset(uint256 _datasetId, string memory _datasetURI, string memory _description): Updates metadata for an existing dataset.
// 13. certifyDataset(uint256 _datasetId, uint256 _qualityScore, string memory _certificationURI, uint256 _certificationStake): Allows users to provide a quality certification for a dataset, potentially backed by a stake.
// 14. tokenizeDatasetAccess(uint256 _datasetId, uint256 _initialSupply, uint256 _pricePerToken, string memory _tokenURI): Mints ERC-1155 tokens for access to a certified dataset.

// IV. Validation Network & Challenge System
// 15. stakeAsValidator(uint256 _amount): Allows an account to stake tokens to become a potential model validator.
// 16. unstakeAsValidator(uint256 _amount): Allows a validator to unstake their tokens (subject to locking periods if active in challenges).
// 17. challengeModelPerformance(uint256 _modelId, uint256 _datasetId, string memory _challengeDetailsURI, uint256 _challengeStake): Initiates a performance challenge for a model using a specified dataset, requiring a challenge stake.
// 18. submitValidationResult(uint256 _challengeId, bytes32 _resultHash, uint256 _accuracyScore): A selected validator submits their off-chain validation result for a challenge.
// 19. disputeValidationResult(uint256 _challengeId, address _targetValidator, uint256 _disputeStake): Allows any participant to dispute a submitted validation result, triggering further scrutiny.
// 20. finalizeChallenge(uint256 _challengeId): Finalizes a challenge, distributing rewards to honest validators/challengers and slashing dishonest ones based on consensus. (Owner-only or DAO-governed for security).

// V. Marketplace & Engagement
// 21. purchaseModelAccessTokens(uint256 _modelId, uint256 _amount): Allows users to buy access tokens for a model.
// 22. purchaseDatasetAccessTokens(uint256 _datasetId, uint256 _amount): Allows users to buy access tokens for a dataset.
// 23. logInferenceRequest(uint256 _modelId, bytes32 _inputHash, bytes32 _outputHash): Records an off-chain inference request and its result hash (after successful payment/token usage).
// 24. submitFeedback(uint256 _entityId, EntityType _entityType, uint8 _rating, string memory _commentURI): Users provide feedback (rating, comment) on models, datasets, or validators.

// VI. Reputation Management
// 25. getReputationScore(address _entityAddress): Retrieves the current reputation score for a given address.

contract CogniChain_Nexus is ERC1155, Ownable, Pausable {
    using SafeMath for uint256;

    // --- Enums and Constants ---
    enum ChallengeStatus {
        Pending,
        ValidationSubmitted, // At least one result submitted
        Disputed,
        Resolved
    }

    enum EntityType {
        Model,
        Dataset,
        Validator,
        Creator
    }

    // Parameter IDs for updateProtocolParameter function
    enum ParameterID {
        MIN_VALIDATOR_STAKE,
        CHALLENGE_FEE,
        VALIDATION_REWARD_PERCENT, // % of total stake to reward
        SLASHING_PERCENT, // % of validator stake to slash
        CONSENSUS_THRESHOLD_PERCENT, // % of validators needed for consensus
        VALIDATOR_SELECTION_COUNT, // Number of validators selected per challenge
        MAX_CHALLENGE_DURATION, // Time in seconds before challenge can be finalized
        DATASET_CERT_STAKE, // Stake for dataset certification
        PROTOCOL_FEE_PERCENT // % of sales that go to protocol
    }

    // --- State Variables ---
    IERC20 public immutable protocolToken;
    uint256 private _nextTokenId; // For unique ERC1155 token IDs

    // Protocol parameters, configurable by owner
    mapping(uint256 => uint256) public protocolParameters;

    uint256 public nextModelId;
    uint256 public nextDatasetId;
    uint256 public nextChallengeId;

    // --- Structs ---

    struct Model {
        address creator;
        string modelURI;
        string performanceClaimURI;
        string description;
        uint256 inferencePrice; // Price in protocolToken for inference
        bool isRetired;
        bool isTokenized;
        uint256 accessTokenId; // ERC1155 token ID for access
    }

    struct Dataset {
        address contributor;
        string datasetURI;
        string description;
        uint256 qualityScore; // Aggregated score from certifications
        string certificationURI; // URI to latest certification details
        bool isTokenized;
        uint256 accessTokenId; // ERC1155 token ID for access
        uint256 certificationStake; // Total stake locked in certifications
    }

    struct Validator {
        address stakerAddress;
        uint256 stakeAmount;
        uint256 lockedStake; // Stake locked during active challenges
        uint256 lastActivity; // Timestamp of last stake/unstake
        bool isActive; // Is currently an active validator
    }

    struct Challenge {
        address challenger;
        uint256 modelId;
        uint256 datasetId;
        string challengeDetailsURI;
        uint256 challengeStake;
        ChallengeStatus status;
        address[] selectedValidators; // Validators chosen for this challenge
        mapping(address => bytes32) validatorResultHashes; // Validator address => hash of off-chain result
        mapping(address => uint256) validatorAccuracyScores; // Validator address => reported accuracy score
        mapping(address => bool) hasSubmittedResult; // Track if a validator has submitted
        uint256 creationTime;
        uint256 resultSubmissionCount;
    }

    struct Reputation {
        int256 score;
        uint256 lastUpdate;
    }

    // --- Mappings ---
    mapping(uint256 => Model) public models;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => Validator) public validators;
    mapping(address => Reputation) public reputationScores;

    // ERC1155 token ID to Model/Dataset ID mapping
    mapping(uint256 => uint256) public erc1155TokenToModelId;
    mapping(uint256 => uint256) public erc1155TokenToDatasetId;

    // Accumulated protocol fees per token
    mapping(address => uint256) public protocolFees;

    // --- Events ---
    event ModelSubmitted(uint256 indexed modelId, address indexed creator, string modelURI);
    event ModelUpdated(uint256 indexed modelId, string modelURI);
    event ModelTokenized(uint256 indexed modelId, uint256 indexed tokenId, uint256 initialSupply, uint256 pricePerToken);
    event ModelInferencePriceSet(uint256 indexed modelId, uint256 price);
    event ModelRetired(uint256 indexed modelId);

    event DatasetSubmitted(uint256 indexed datasetId, address indexed contributor, string datasetURI);
    event DatasetUpdated(uint256 indexed datasetId, string datasetURI);
    event DatasetCertified(uint256 indexed datasetId, address indexed certifier, uint256 qualityScore);
    event DatasetTokenized(uint256 indexed datasetId, uint256 indexed tokenId, uint256 initialSupply, uint256 pricePerToken);

    event ValidatorStaked(address indexed staker, uint256 amount, uint256 totalStake);
    event ValidatorUnstaked(address indexed staker, uint256 amount, uint256 totalStake);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed modelId, uint256 indexed datasetId, address challenger, uint256 challengeStake);
    event ValidationResultSubmitted(uint256 indexed challengeId, address indexed validator, bytes32 resultHash, uint256 accuracyScore);
    event ValidationResultDisputed(uint256 indexed challengeId, address indexed disputer, address indexed targetValidator);
    event ChallengeFinalized(uint256 indexed challengeId, ChallengeStatus finalStatus);

    event AccessTokensPurchased(address indexed buyer, uint256 indexed entityId, EntityType entityType, uint256 tokenId, uint256 amount, uint256 totalPrice);
    event InferenceRequestLogged(uint256 indexed modelId, address indexed user, bytes32 inputHash);
    event FeedbackSubmitted(uint256 indexed entityId, EntityType entityType, address indexed sender, uint8 rating);

    event ProtocolParameterUpdated(uint256 indexed paramId, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);

    constructor(address _protocolToken, string memory _baseTokenURI)
        ERC1155(_baseTokenURI)
        Ownable(msg.sender) // Initialize Ownable
    {
        require(_protocolToken != address(0), "Protocol token cannot be zero address");
        protocolToken = IERC20(_protocolToken);

        // Set initial protocol parameters (can be updated later by owner)
        protocolParameters[uint256(ParameterID.MIN_VALIDATOR_STAKE)] = 1000 * 10 ** 18; // 1000 tokens
        protocolParameters[uint256(ParameterID.CHALLENGE_FEE)] = 100 * 10 ** 18; // 100 tokens
        protocolParameters[uint256(ParameterID.VALIDATION_REWARD_PERCENT)] = 70; // 70% of challenge stake
        protocolParameters[uint256(ParameterID.SLASHING_PERCENT)] = 50; // 50% of validator stake
        protocolParameters[uint256(ParameterID.CONSENSUS_THRESHOLD_PERCENT)] = 60; // 60% agreement needed
        protocolParameters[uint256(ParameterID.VALIDATOR_SELECTION_COUNT)] = 5; // Select 5 validators
        protocolParameters[uint256(ParameterID.MAX_CHALLENGE_DURATION)] = 7 days; // 7 days for validation
        protocolParameters[uint256(ParameterID.DATASET_CERT_STAKE)] = 50 * 10 ** 18; // 50 tokens
        protocolParameters[uint256(ParameterID.PROTOCOL_FEE_PERCENT)] = 5; // 5% of sales
    }

    // --- I. Administrative & Configuration ---

    /**
     * @dev Allows the owner to adjust critical protocol parameters.
     * @param _paramId The ID of the parameter to update (see ParameterID enum).
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(uint256 _paramId, uint256 _newValue) public onlyOwner {
        protocolParameters[_paramId] = _newValue;
        emit ProtocolParameterUpdated(_paramId, _newValue);
    }

    /**
     * @dev Pauses the contract in case of an emergency.
     * Only owner can call.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency.
     * Only owner can call.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * @param _tokenAddress The address of the token to withdraw.
     */
    function withdrawProtocolFees(address _tokenAddress) public onlyOwner {
        uint256 amount = protocolFees[_tokenAddress];
        require(amount > 0, "No fees to withdraw for this token");
        protocolFees[_tokenAddress] = 0;
        require(IERC20(_tokenAddress).transfer(owner(), amount), "Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_tokenAddress, owner(), amount);
    }

    // --- II. AI Model Management ---

    /**
     * @dev Registers a new AI model with its off-chain URI, performance claims, and description.
     * @param _modelURI URI pointing to the model artifact (e.g., IPFS hash, URL).
     * @param _performanceClaimURI URI pointing to the creator's initial performance claims.
     * @param _description A brief description of the model.
     * @return modelId The ID of the newly registered model.
     */
    function submitModel(string memory _modelURI, string memory _performanceClaimURI, string memory _description)
        public
        whenNotPaused
        returns (uint256)
    {
        nextModelId = nextModelId.add(1);
        models[nextModelId] = Model({
            creator: msg.sender,
            modelURI: _modelURI,
            performanceClaimURI: _performanceClaimURI,
            description: _description,
            inferencePrice: 0,
            isRetired: false,
            isTokenized: false,
            accessTokenId: 0
        });
        _updateReputation(msg.sender, 5); // Reward creator for submitting a model
        emit ModelSubmitted(nextModelId, msg.sender, _modelURI);
        return nextModelId;
    }

    /**
     * @dev Updates metadata for an existing model. Only the creator can update their model.
     * @param _modelId The ID of the model to update.
     * @param _modelURI New URI for the model artifact.
     * @param _performanceClaimURI New URI for performance claims.
     * @param _description New description for the model.
     */
    function updateModel(uint256 _modelId, string memory _modelURI, string memory _performanceClaimURI, string memory _description)
        public
        whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only model creator can update");
        require(!model.isRetired, "Cannot update a retired model");

        model.modelURI = _modelURI;
        model.performanceClaimURI = _performanceClaimURI;
        model.description = _description;
        emit ModelUpdated(_modelId, _modelURI);
    }

    /**
     * @dev Mints ERC-1155 tokens representing access rights or fractional ownership for a validated model.
     * Requires the model to not be tokenized already.
     * @param _modelId The ID of the model to tokenize.
     * @param _initialSupply The total initial supply of access tokens to mint.
     * @param _pricePerToken The price for each token in `protocolToken`.
     * @param _tokenURI A specific URI for this access token (e.g., linking to terms of use).
     * @return tokenId The ERC1155 token ID generated for this model's access.
     */
    function tokenizeModelAccess(uint256 _modelId, uint256 _initialSupply, uint256 _pricePerToken, string memory _tokenURI)
        public
        whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only model creator can tokenize their model");
        require(!model.isTokenized, "Model already has access tokens");
        require(!model.isRetired, "Cannot tokenize a retired model");
        require(_initialSupply > 0, "Initial supply must be greater than zero");

        _nextTokenId = _nextTokenId.add(1);
        model.accessTokenId = _nextTokenId;
        model.isTokenized = true;
        modelAccessPrices[_modelId] = _pricePerToken;
        erc1155TokenToModelId[_nextTokenId] = _modelId;

        // Set the URI for this specific token ID
        _setURI(_tokenURI); // ERC1155 _setURI sets for the base, assuming IDs are appended.
                           // For specific token URIs, a more complex _setTokenURI is needed
                           // or the baseURI must handle concatenation with ID.
                           // For simplicity, we'll assume a base URI that can resolve specific token metadata.

        _mint(msg.sender, _nextTokenId, _initialSupply, ""); // Mint tokens to the creator
        emit ModelTokenized(_modelId, _nextTokenId, _initialSupply, _pricePerToken);
        return _nextTokenId;
    }

    /**
     * @dev Sets the price for consuming inference services from a specific model.
     * This price is for direct inference requests, not necessarily for access tokens.
     * @param _modelId The ID of the model.
     * @param _priceInWei The price per inference in `protocolToken` wei.
     */
    function setModelInferencePrice(uint256 _modelId, uint256 _priceInWei) public whenNotPaused {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only model creator can set inference price");
        require(!model.isRetired, "Cannot set inference price for a retired model");
        model.inferencePrice = _priceInWei;
        emit ModelInferencePriceSet(_modelId, _priceInWei);
    }

    /**
     * @dev Marks a model as retired, preventing new access token minting or challenges.
     * Existing tokens remain valid until expiration, if any.
     * @param _modelId The ID of the model to retire.
     */
    function retireModel(uint256 _modelId) public whenNotPaused {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only model creator can retire their model");
        require(!model.isRetired, "Model is already retired");
        model.isRetired = true;
        emit ModelRetired(_modelId);
    }

    // --- III. Dataset Management ---

    /**
     * @dev Registers a new dataset with its off-chain URI and description.
     * @param _datasetURI URI pointing to the dataset (e.g., IPFS hash, URL).
     * @param _description A brief description of the dataset.
     * @return datasetId The ID of the newly registered dataset.
     */
    function submitDataset(string memory _datasetURI, string memory _description)
        public
        whenNotPaused
        returns (uint256)
    {
        nextDatasetId = nextDatasetId.add(1);
        datasets[nextDatasetId] = Dataset({
            contributor: msg.sender,
            datasetURI: _datasetURI,
            description: _description,
            qualityScore: 0,
            certificationURI: "",
            isTokenized: false,
            accessTokenId: 0,
            certificationStake: 0
        });
        _updateReputation(msg.sender, 3); // Reward contributor
        emit DatasetSubmitted(nextDatasetId, msg.sender, _datasetURI);
        return nextDatasetId;
    }

    /**
     * @dev Updates metadata for an existing dataset. Only the contributor can update.
     * @param _datasetId The ID of the dataset to update.
     * @param _datasetURI New URI for the dataset.
     * @param _description New description for the dataset.
     */
    function updateDataset(uint256 _datasetId, string memory _datasetURI, string memory _description)
        public
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.contributor == msg.sender, "Only dataset contributor can update");
        dataset.datasetURI = _datasetURI;
        dataset.description = _description;
        emit DatasetUpdated(_datasetId, _datasetURI);
    }

    /**
     * @dev Allows users to provide a quality certification for a dataset, potentially backed by a stake.
     * This contributes to the dataset's aggregated quality score.
     * @param _datasetId The ID of the dataset to certify.
     * @param _qualityScore A score from 0-100 indicating quality.
     * @param _certificationURI URI pointing to the detailed certification report.
     * @param _certificationStake The amount of `protocolToken` to stake for this certification.
     */
    function certifyDataset(uint256 _datasetId, uint256 _qualityScore, string memory _certificationURI, uint256 _certificationStake)
        public
        whenNotPaused
    {
        require(_qualityScore <= 100, "Quality score must be between 0 and 100");
        require(_certificationStake >= protocolParameters[uint256(ParameterID.DATASET_CERT_STAKE)], "Stake too low for certification");

        Dataset storage dataset = datasets[_datasetId];
        require(dataset.datasetURI != "", "Dataset not found");

        // Transfer stake
        require(protocolToken.transferFrom(msg.sender, address(this), _certificationStake), "Stake transfer failed");
        dataset.certificationStake = dataset.certificationStake.add(_certificationStake);

        // Simple aggregation for quality score (can be more complex with weighted average, etc.)
        if (dataset.qualityScore == 0) {
            dataset.qualityScore = _qualityScore;
        } else {
            dataset.qualityScore = (dataset.qualityScore.add(_qualityScore)).div(2);
        }
        dataset.certificationURI = _certificationURI; // Update to latest certification URI
        _updateReputation(msg.sender, 2); // Reward certifier

        emit DatasetCertified(_datasetId, msg.sender, _qualityScore);
    }

    /**
     * @dev Mints ERC-1155 tokens for access to a certified dataset.
     * Requires the dataset to not be tokenized already.
     * @param _datasetId The ID of the dataset to tokenize.
     * @param _initialSupply The total initial supply of access tokens to mint.
     * @param _pricePerToken The price for each token in `protocolToken`.
     * @param _tokenURI A specific URI for this access token.
     * @return tokenId The ERC1155 token ID generated for this dataset's access.
     */
    function tokenizeDatasetAccess(uint256 _datasetId, uint256 _initialSupply, uint256 _pricePerToken, string memory _tokenURI)
        public
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.contributor == msg.sender, "Only dataset contributor can tokenize their dataset");
        require(!dataset.isTokenized, "Dataset already has access tokens");
        require(_initialSupply > 0, "Initial supply must be greater than zero");

        _nextTokenId = _nextTokenId.add(1);
        dataset.accessTokenId = _nextTokenId;
        dataset.isTokenized = true;
        datasetAccessPrices[_datasetId] = _pricePerToken;
        erc1155TokenToDatasetId[_nextTokenId] = _datasetId;

        _setURI(_tokenURI);
        _mint(msg.sender, _nextTokenId, _initialSupply, "");
        emit DatasetTokenized(_datasetId, _nextTokenId, _initialSupply, _pricePerToken);
        return _nextTokenId;
    }

    // --- IV. Validation Network & Challenge System ---

    /**
     * @dev Allows an account to stake tokens to become a potential model validator.
     * @param _amount The amount of `protocolToken` to stake.
     */
    function stakeAsValidator(uint256 _amount) public whenNotPaused {
        require(_amount >= protocolParameters[uint256(ParameterID.MIN_VALIDATOR_STAKE)], "Stake amount too low");

        Validator storage validator = validators[msg.sender];
        if (validator.stakerAddress == address(0)) {
            validator.stakerAddress = msg.sender;
        }

        // Transfer stake
        require(protocolToken.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed");

        validator.stakeAmount = validator.stakeAmount.add(_amount);
        validator.lastActivity = block.timestamp;
        validator.isActive = true;
        _updateReputation(msg.sender, 1); // Small reputation boost for staking
        emit ValidatorStaked(msg.sender, _amount, validator.stakeAmount);
    }

    /**
     * @dev Allows a validator to unstake their tokens.
     * Subject to locking periods if actively participating in challenges.
     * @param _amount The amount of `protocolToken` to unstake.
     */
    function unstakeAsValidator(uint256 _amount) public whenNotPaused {
        Validator storage validator = validators[msg.sender];
        require(validator.stakerAddress == msg.sender, "Not a registered validator");
        require(validator.stakeAmount.sub(validator.lockedStake) >= _amount, "Amount exceeds available unstaked balance");
        require(protocolToken.transfer(msg.sender, _amount), "Unstake transfer failed");

        validator.stakeAmount = validator.stakeAmount.sub(_amount);
        if (validator.stakeAmount == 0) {
            validator.isActive = false; // Deactivate if stake is zero
        }
        validator.lastActivity = block.timestamp;
        _updateReputation(msg.sender, -1); // Small reputation decrease for unstaking
        emit ValidatorUnstaked(msg.sender, _amount, validator.stakeAmount);
    }

    /**
     * @dev Initiates a performance challenge for a model using a specified dataset.
     * The challenger must pay a challenge stake.
     * @param _modelId The ID of the model to challenge.
     * @param _datasetId The ID of the dataset to use for validation.
     * @param _challengeDetailsURI URI pointing to detailed challenge specifications.
     * @param _challengeStake The amount of `protocolToken` to stake for the challenge.
     * @return challengeId The ID of the newly created challenge.
     */
    function challengeModelPerformance(uint256 _modelId, uint256 _datasetId, string memory _challengeDetailsURI, uint256 _challengeStake)
        public
        whenNotPaused
        returns (uint256)
    {
        Model storage model = models[_modelId];
        require(model.modelURI != "", "Model not found");
        require(!model.isRetired, "Cannot challenge a retired model");
        require(datasets[_datasetId].datasetURI != "", "Dataset not found");
        require(_challengeStake >= protocolParameters[uint256(ParameterID.CHALLENGE_FEE)], "Challenge stake too low");

        // Transfer challenge stake
        require(protocolToken.transferFrom(msg.sender, address(this), _challengeStake), "Challenge stake transfer failed");

        nextChallengeId = nextChallengeId.add(1);
        challenges[nextChallengeId] = Challenge({
            challenger: msg.sender,
            modelId: _modelId,
            datasetId: _datasetId,
            challengeDetailsURI: _challengeDetailsURI,
            challengeStake: _challengeStake,
            status: ChallengeStatus.Pending,
            selectedValidators: new address[](0), // Validators selected off-chain/via helper
            creationTime: block.timestamp,
            resultSubmissionCount: 0
        });

        // Simplified validator selection: In a real system, this would involve randomness
        // or a more sophisticated selection algorithm from the active validator pool.
        // For this example, we will assume off-chain selection that then calls submitValidationResult.
        // A more complex on-chain selection would require iterating over validator map, which is expensive.
        // Or, a decentralized oracle network would coordinate and submit.

        emit ChallengeInitiated(nextChallengeId, _modelId, _datasetId, msg.sender, _challengeStake);
        _updateReputation(msg.sender, 2); // Reward challenger for initiating validation
        return nextChallengeId;
    }

    /**
     * @dev A selected validator submits their off-chain validation result for a challenge.
     * This function assumes validators are selected and notified off-chain.
     * @param _challengeId The ID of the challenge.
     * @param _resultHash A hash of the full off-chain validation results.
     * @param _accuracyScore The reported accuracy score (e.g., 0-100).
     */
    function submitValidationResult(uint256 _challengeId, bytes32 _resultHash, uint256 _accuracyScore)
        public
        whenNotPaused
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Pending || challenge.status == ChallengeStatus.ValidationSubmitted, "Challenge not in valid state for submission");
        require(validators[msg.sender].isActive, "Sender is not an active validator");
        require(!challenge.hasSubmittedResult[msg.sender], "Validator already submitted result for this challenge");
        require(block.timestamp <= challenge.creationTime.add(protocolParameters[uint256(ParameterID.MAX_CHALLENGE_DURATION)]), "Challenge submission window expired");

        // Lock validator's stake for the duration of the challenge
        // This is a simplified lock, in reality, a portion of the stake would be dedicated to this challenge.
        // For this contract, we'll assume the stake is implicitly backing all active challenges.
        // An explicit 'lock' would involve moving stake into a challenge-specific escrow.

        challenge.validatorResultHashes[msg.sender] = _resultHash;
        challenge.validatorAccuracyScores[msg.sender] = _accuracyScore;
        challenge.hasSubmittedResult[msg.sender] = true;
        challenge.resultSubmissionCount = challenge.resultSubmissionCount.add(1);

        if (challenge.status == ChallengeStatus.Pending) {
            challenge.status = ChallengeStatus.ValidationSubmitted;
        }

        // Add to selected validators if not already present (simplified selection logic)
        bool alreadySelected = false;
        for (uint i = 0; i < challenge.selectedValidators.length; i++) {
            if (challenge.selectedValidators[i] == msg.sender) {
                alreadySelected = true;
                break;
            }
        }
        if (!alreadySelected) {
            challenge.selectedValidators.push(msg.sender);
        }

        _updateReputation(msg.sender, 3); // Reward validator for contributing result
        emit ValidationResultSubmitted(_challengeId, msg.sender, _resultHash, _accuracyScore);
    }

    /**
     * @dev Allows any participant to dispute a submitted validation result.
     * This triggers further scrutiny or a re-evaluation process (handled off-chain or by owner).
     * @param _challengeId The ID of the challenge.
     * @param _targetValidator The address of the validator whose result is being disputed.
     * @param _disputeStake The amount of `protocolToken` to stake for the dispute.
     */
    function disputeValidationResult(uint256 _challengeId, address _targetValidator, uint256 _disputeStake)
        public
        whenNotPaused
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.ValidationSubmitted, "Challenge not in validation submission state");
        require(challenge.hasSubmittedResult[_targetValidator], "Target validator has not submitted a result");
        require(validators[_targetValidator].isActive, "Target is not an active validator");
        require(_disputeStake > 0, "Dispute stake must be positive");

        // Transfer dispute stake
        require(protocolToken.transferFrom(msg.sender, address(this), _disputeStake), "Dispute stake transfer failed");

        challenge.status = ChallengeStatus.Disputed;
        // In a real system, this would queue for a re-evaluation by a super-set of validators
        // or a specific dispute resolution committee.
        // For simplicity, here it just flags the challenge.
        _updateReputation(msg.sender, -1); // Small penalty for disputer, to prevent spam
        emit ValidationResultDisputed(_challengeId, msg.sender, _targetValidator);
    }

    /**
     * @dev Finalizes a challenge, distributing rewards to honest participants and slashing dishonest ones.
     * This function is crucial and should ideally be callable by a DAO or after a robust
     * off-chain consensus mechanism has concluded, not just the owner. For this example,
     * it is restricted to owner for simplicity of demonstration.
     * @param _challengeId The ID of the challenge to finalize.
     */
    function finalizeChallenge(uint256 _challengeId) public onlyOwner whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status != ChallengeStatus.Resolved, "Challenge already resolved");
        require(challenge.creationTime.add(protocolParameters[uint256(ParameterID.MAX_CHALLENGE_DURATION)]) <= block.timestamp ||
                challenge.status == ChallengeStatus.Disputed ||
                challenge.resultSubmissionCount >= protocolParameters[uint256(ParameterID.VALIDATOR_SELECTION_COUNT)],
                "Challenge not ready for finalization (duration, dispute or sufficient submissions)");

        uint256 totalRewardPool = challenge.challengeStake;
        uint256 protocolFee = totalRewardPool.mul(protocolParameters[uint256(ParameterID.PROTOCOL_FEE_PERCENT)]).div(100);
        protocolFees[address(protocolToken)] = protocolFees[address(protocolToken)].add(protocolFee);
        totalRewardPool = totalRewardPool.sub(protocolFee);

        // Determine consensus for accuracy scores
        // This is a simplified consensus mechanism: median or mean of submitted scores.
        // A robust system would compare results against a ground truth or use more complex statistical methods.
        uint256[] memory scores = new uint256[](challenge.resultSubmissionCount);
        address[] memory submittedValidators = new address[](challenge.resultSubmissionCount);
        uint256 count = 0;
        for (uint i = 0; i < challenge.selectedValidators.length; i++) {
            address validatorAddress = challenge.selectedValidators[i];
            if (challenge.hasSubmittedResult[validatorAddress]) {
                scores[count] = challenge.validatorAccuracyScores[validatorAddress];
                submittedValidators[count] = validatorAddress;
                count++;
            }
        }

        // Calculate average score (simplified consensus)
        uint256 sumScores = 0;
        for (uint i = 0; i < count; i++) {
            sumScores = sumScores.add(scores[i]);
        }
        uint256 averageScore = count > 0 ? sumScores.div(count) : 0;

        // Reward/Slashing logic based on consensus
        uint256 rewardPerValidator = 0;
        uint256 slashingAmount = 0;
        if (count > 0) {
            rewardPerValidator = totalRewardPool.mul(protocolParameters[uint256(ParameterID.VALIDATION_REWARD_PERCENT)]).div(100).div(count);
            slashingAmount = protocolParameters[uint256(ParameterID.MIN_VALIDATOR_STAKE)].mul(protocolParameters[uint256(ParameterID.SLASHING_PERCENT)]).div(100);
        }

        for (uint i = 0; i < count; i++) {
            address validatorAddress = submittedValidators[i];
            Validator storage validator = validators[validatorAddress];

            // If a validator's score is significantly off the average, they get slashed
            // Otherwise, they get rewarded
            uint256 scoreDiff = scores[i] > averageScore ? scores[i].sub(averageScore) : averageScore.sub(scores[i]);
            if (scoreDiff > 10) { // Simple threshold for being "dishonest"
                if (validator.stakeAmount >= slashingAmount) {
                    validator.stakeAmount = validator.stakeAmount.sub(slashingAmount);
                    // Slashing also contributes to protocol fees or a community pool
                    protocolFees[address(protocolToken)] = protocolFees[address(protocolToken)].add(slashingAmount);
                    _updateReputation(validatorAddress, -10); // Significant reputation loss
                }
            } else {
                require(protocolToken.transfer(validatorAddress, rewardPerValidator), "Validator reward transfer failed");
                _updateReputation(validatorAddress, 5); // Reputation boost for honest validation
            }
        }

        // Refund challenger if model claim was false, otherwise challenger loses stake (already transferred)
        // This part needs a deeper logic to define "false claim". For example, if averageScore is too low.
        // Here, we'll assume the challenge stake is mostly for rewarding validators and discouraging frivolous challenges.
        // A portion could be returned if the model truly underperformed, but this would require more complex scoring logic.
        // For simplicity, we'll assume the challenge stake primarily funds the validation process.

        challenge.status = ChallengeStatus.Resolved;
        _updateReputation(challenge.challenger, 5); // Reward challenger for successful challenge outcome or for contributing to validation

        emit ChallengeFinalized(_challengeId, ChallengeStatus.Resolved);
    }

    // --- V. Marketplace & Engagement ---

    /**
     * @dev Allows users to buy access tokens for a model.
     * @param _modelId The ID of the model.
     * @param _amount The amount of access tokens to purchase.
     */
    function purchaseModelAccessTokens(uint256 _modelId, uint256 _amount) public whenNotPaused {
        Model storage model = models[_modelId];
        require(model.isTokenized, "Model access not tokenized");
        require(!model.isRetired, "Cannot purchase access for a retired model");

        uint256 totalPrice = modelAccessPrices[_modelId].mul(_amount);
        require(totalPrice > 0, "Price must be positive");
        require(protocolToken.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");

        uint256 protocolFee = totalPrice.mul(protocolParameters[uint256(ParameterID.PROTOCOL_FEE_PERCENT)]).div(100);
        protocolFees[address(protocolToken)] = protocolFees[address(protocolToken)].add(protocolFee);

        uint256 creatorRevenue = totalPrice.sub(protocolFee);
        require(protocolToken.transfer(model.creator, creatorRevenue), "Creator revenue transfer failed");

        _mint(msg.sender, model.accessTokenId, _amount, ""); // Mint tokens to the buyer
        emit AccessTokensPurchased(msg.sender, _modelId, EntityType.Model, model.accessTokenId, _amount, totalPrice);
        _updateReputation(msg.sender, 1); // Small reputation for purchasing
    }

    /**
     * @dev Allows users to buy access tokens for a dataset.
     * @param _datasetId The ID of the dataset.
     * @param _amount The amount of access tokens to purchase.
     */
    function purchaseDatasetAccessTokens(uint256 _datasetId, uint256 _amount) public whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.isTokenized, "Dataset access not tokenized");

        uint256 totalPrice = datasetAccessPrices[_datasetId].mul(_amount);
        require(totalPrice > 0, "Price must be positive");
        require(protocolToken.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");

        uint256 protocolFee = totalPrice.mul(protocolParameters[uint256(ParameterID.PROTOCOL_FEE_PERCENT)]).div(100);
        protocolFees[address(protocolToken)] = protocolFees[address(protocolToken)].add(protocolFee);

        uint256 contributorRevenue = totalPrice.sub(protocolFee);
        require(protocolToken.transfer(dataset.contributor, contributorRevenue), "Contributor revenue transfer failed");

        _mint(msg.sender, dataset.accessTokenId, _amount, ""); // Mint tokens to the buyer
        emit AccessTokensPurchased(msg.sender, _datasetId, EntityType.Dataset, dataset.accessTokenId, _amount, totalPrice);
        _updateReputation(msg.sender, 1); // Small reputation for purchasing
    }

    /**
     * @dev Records an off-chain inference request and its result hash, typically after successful payment/token usage.
     * This logs usage for potential future analytics or reputation scoring.
     * @param _modelId The ID of the model used for inference.
     * @param _inputHash A hash of the input data used for inference.
     * @param _outputHash A hash of the output result from inference.
     */
    function logInferenceRequest(uint256 _modelId, bytes32 _inputHash, bytes32 _outputHash) public whenNotPaused {
        Model storage model = models[_modelId];
        require(model.modelURI != "", "Model not found");
        // In a real system, this would require validation of token ownership or direct payment.
        // For simplicity, we assume an off-chain service verifies and then calls this.
        // It could also require the caller to burn an inference token.
        _updateReputation(msg.sender, 0); // No change for logging, but logs activity
        // emit event with outputHash if needed for off-chain listeners
        emit InferenceRequestLogged(_modelId, msg.sender, _inputHash);
    }

    /**
     * @dev Allows users to provide feedback (rating, comment) on models, datasets, or validators.
     * This influences the entity's reputation score.
     * @param _entityId The ID of the entity (model, dataset, validator's address).
     * @param _entityType The type of entity being reviewed.
     * @param _rating A rating from 1 to 5.
     * @param _commentURI URI pointing to the detailed feedback comment.
     */
    function submitFeedback(uint256 _entityId, EntityType _entityType, uint8 _rating, string memory _commentURI)
        public
        whenNotPaused
    {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        address targetAddress = address(0);
        if (_entityType == EntityType.Model) {
            require(models[_entityId].modelURI != "", "Model not found");
            targetAddress = models[_entityId].creator;
        } else if (_entityType == EntityType.Dataset) {
            require(datasets[_entityId].datasetURI != "", "Dataset not found");
            targetAddress = datasets[_entityId].contributor;
        } else if (_entityType == EntityType.Validator) {
            require(validators[address(uint160(_entityId))].isActive, "Validator not found");
            targetAddress = address(uint160(_entityId)); // Convert ID to address for validator
        } else if (_entityType == EntityType.Creator) { // Direct feedback to a creator address
            targetAddress = address(uint160(_entityId));
        } else {
            revert("Invalid entity type");
        }
        require(targetAddress != address(0), "Target address for feedback is invalid");

        int256 reputationImpact = int256(_rating).sub(3).mul(int256(protocolParameters[uint256(ParameterID.FEEDBACK_REPUTATION_IMPACT)]));
        _updateReputation(targetAddress, reputationImpact);

        emit FeedbackSubmitted(_entityId, _entityType, msg.sender, _rating);
    }

    // --- VI. Reputation Management ---

    /**
     * @dev Retrieves the current reputation score for a given address.
     * @param _entityAddress The address whose reputation score is to be retrieved.
     * @return The reputation score (can be positive or negative).
     */
    function getReputationScore(address _entityAddress) public view returns (int256) {
        return reputationScores[_entityAddress].score;
    }

    /**
     * @dev Internal function to update an address's reputation score.
     * @param _target The address whose reputation to update.
     * @param _change The amount to add or subtract from the reputation score.
     */
    function _updateReputation(address _target, int256 _change) internal {
        Reputation storage rep = reputationScores[_target];
        rep.score = rep.score.add(_change);
        rep.lastUpdate = block.timestamp;
        // Further logic could normalize scores, apply decay, etc.
    }

    // --- ERC1155 Overrides ---
    // ERC1155 needs _beforeTokenTransfer to restrict transfers.
    // For this contract, we'll assume tokens are freely transferable once minted,
    // and off-chain services will check ownership for access.
    // If tokens represented *non-transferable* access, this would be a custom ERC1155 implementation.
    // For fractional ownership, transferability is key.

    // A custom ERC1155 URI function to handle token-specific URIs
    function uri(uint256 _tokenId) public view override returns (string memory) {
        // This is a placeholder. In a real application, you'd store token-specific URIs
        // in a mapping or construct them dynamically based on entity IDs.
        // For example:
        // if (erc1155TokenToModelId[_tokenId] != 0) {
        //     uint256 modelId = erc1155TokenToModelId[_tokenId];
        //     return models[modelId].tokenURI; // assuming model has a tokenURI field
        // }
        // For simplicity, we use the base URI set in the constructor.
        return super.uri(_tokenId);
    }

    // This contract receives tokens for staking and fees
    receive() external payable {}
}
```