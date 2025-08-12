This smart contract, **"EvoMind Nexus,"** pioneers a decentralized marketplace for AI models, datasets, and inference services. It leverages **dynamic Non-Fungible Tokens (NFTs)** to represent AI models, allowing their on-chain attributes (like accuracy or latency) to evolve based on real-world performance validated by a decentralized oracle/validator network. Furthermore, it incorporates a **reputation system** to incentivize trustworthy participation from model developers, data providers, and validators, fostering a more transparent and reliable AI ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Note: SafeMath is largely obsolete in Solidity 0.8+ due to default overflow checks, but kept for explicit safety in divisions/multiplications if needed.

/**
 * @title EvoMindNexus
 * @dev An On-Chain Protocol for Dynamic AI Model NFTs and Reputation-Based Access.
 *
 * This contract facilitates a decentralized market for AI models and data, featuring:
 * - Dynamic AI Model NFTs (EvoMind NFTs): NFTs whose metadata (e.g., accuracy, training progress, usage statistics)
 *   can be updated on-chain via oracle-fed data or validation results.
 * - Reputation System (NexusRep): A multi-faceted reputation system for participants (model developers,
 *   data providers, validators, users) that influences access, rewards, and potentially voting power.
 * - Staked Model Security: Developers stake tokens to demonstrate confidence in their model's integrity/performance.
 * - Curated Data Sets: A mechanism for data providers to register and get paid for quality datasets.
 * - Inference Request & Payment Orchestration: Users request model inferences, payments are held in escrow,
 *   and released upon verified completion, including automated royalties.
 * - Decentralized Oracle Integration (conceptual): Functions are designed to be callable by a trusted validator
 *   role, conceptually representing a decentralized oracle network.
 */
contract EvoMindNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicit SafeMath for clarity, though 0.8+ has built-in overflow checks.

    // --- Outline and Function Summary ---

    // I. Core Components & State Management
    // 1.  constructor(): Initializes the contract, sets the deployer as the owner.
    // 2.  updateNexusConfig(): Allows the contract owner to modify key system configuration parameters like fees, periods.
    // 3.  registerModelDeveloper(address _developer): Registers a new address as a certified AI model developer.
    // 4.  registerDataProvider(address _provider): Registers a new address as a certified data provider.
    // 5.  registerValidator(address _validator): Registers a new address as a certified system validator.

    // II. AI Model Management (EvoMind NFTs)
    // EvoMind NFTs represent ownership/licensing of AI models, with metadata that can dynamically update.
    // 6.  registerAIModel(string memory _metadataURI, uint256 _requiredStake): Allows a developer to register an AI model, minting an EvoMind NFT, requiring a security stake.
    // 7.  updateModelMetadata(uint256 _tokenId, string memory _newMetadataURI): Allows the model owner to update the off-chain metadata URI for their model's NFT.
    // 8.  updateModelPerformanceMetrics(uint256 _tokenId, uint256 _newAccuracy, uint256 _newLatency, address _reporter): Allows a validator/oracle to update on-chain performance metrics of a model, dynamically affecting its NFT.
    // 9.  challengeModelPerformance(uint256 _tokenId, uint256 _inferenceRequestId, string memory _reason): Allows a user to challenge a model's reported performance, initiating a dispute.
    // 10. resolveModelChallenge(uint256 _challengeId, bool _isChallengerCorrect, string memory _resolutionDetails): Allows a validator to resolve an ongoing model performance challenge.
    // 11. decommissionModel(uint256 _tokenId): Allows the model owner or governance to decommission an AI model, refunding stake.
    // 12. getModelDetails(uint256 _tokenId): Retrieves comprehensive details about a registered AI model.

    // III. Data Management
    // Manages the registration and quality control of datasets.
    // 13. registerDataSet(string memory _metadataURI): Allows a data provider to register a new dataset.
    // 14. updateDataSetMetadata(uint256 _dataSetId, string memory _newMetadataURI): Allows the data provider to update the off-chain metadata URI for their registered dataset.
    // 15. challengeDataSetQuality(uint256 _dataSetId, string memory _reason): Allows any participant to challenge the quality of a registered dataset.
    // 16. resolveDataSetChallenge(uint256 _challengeId, bool _isChallengerCorrect, string memory _resolutionDetails): Allows a validator to resolve a dataset quality challenge.

    // IV. Reputation System (NexusRep)
    // A dynamic reputation system for participants, influencing privileges and rewards.
    // 17. getReputationScore(address _user, UserRole _role): Retrieves the current reputation score of a user for a specific role.
    // 18. stakeForReputationBoost(UserRole _role, uint256 _amount): Allows a user to stake tokens to temporarily boost their reputation.
    // 19. withdrawReputationStake(UserRole _role): Allows a user to withdraw their staked tokens for reputation.
    // 20. _updateReputationScore(address _user, UserRole _role, int256 _delta, string memory _reason): Internal function to modify a user's reputation score.

    // V. Inference & Payment Orchestration
    // Facilitates the request, execution, and payment for AI model inferences.
    // 21. requestModelInference(uint256 _tokenId, string memory _inputDataURI): Allows a user to request an AI model inference, locking up payment in escrow.
    // 22. submitInferenceResult(uint256 _requestId, string memory _outputDataURI, address _computeProvider): Allows the off-chain compute provider to submit the result.
    // 23. verifyInferenceResult(uint256 _requestId, bool _isCorrect, address _reporter): Allows a validator to verify the submitted result, releasing payments or initiating refunds/penalties.
    // 24. refundInferenceRequest(uint256 _requestId): Allows the requester to get a refund if an inference request fails or is incorrect.

    // VI. Standard ERC721 Functions (Inherited from OpenZeppelin)
    // Standard functions for NFT management (balanceOf, ownerOf, transferFrom, approve, etc.) are available through inheritance.


    // --- Enums and Structs ---

    /** @dev Defines the different roles a user can have within the EvoMind Nexus. */
    enum UserRole {
        None,           // Default role for unregistered addresses
        ModelDeveloper, // Registers and manages AI models
        DataProvider,   // Registers and manages datasets
        Validator       // Verifies challenges and inference results
    }

    /** @dev Statuses for AI models. */
    enum ModelStatus {
        Active,         // Model is available for inference requests
        Challenged,     // Model's performance is under dispute
        Decommissioned  // Model is no longer active for new requests
    }

    /** @dev Statuses for challenges. */
    enum ChallengeStatus {
        Open,               // Challenge is active and awaiting resolution
        ResolvedCorrect,    // Challenger's claim was validated as true
        ResolvedIncorrect   // Challenger's claim was validated as false
    }

    /** @dev Statuses for inference requests. */
    enum InferenceStatus {
        Requested,          // Request made, payment held in escrow
        ResultSubmitted,    // Compute provider has submitted an off-chain result
        VerifiedSuccess,    // Result verified as correct, payments distributed
        VerifiedFailure,    // Result verified as incorrect, refund issued, penalties applied
        Refunded            // Request has been refunded due to failure or timeout
    }

    /** @dev Represents a user's profile and reputation. */
    struct UserProfile {
        UserRole role;                  // The primary role of the user
        uint256 reputation;             // Base reputation score (can be 0)
        uint256 stakedReputationTokens; // Tokens staked for a reputation boost (in ETH for simplicity)
    }

    /** @dev Represents an AI model, associated with an EvoMind NFT. */
    struct AIModel {
        uint256 tokenId;                // Corresponding EvoMind NFT ID
        address developer;              // Address of the model developer
        string metadataURI;             // URI to off-chain metadata (e.g., IPFS)
        uint256 creationTime;           // Timestamp of model registration
        uint256 requiredStake;          // Tokens staked by developer for integrity (in ETH)
        uint256 currentAccuracy;        // On-chain metric, e.g., 0-10000 (representing 0.00% to 100.00%)
        uint256 currentLatency;         // On-chain metric, e.g., in milliseconds
        ModelStatus status;             // Current status of the model
        uint256 totalInferences;        // Total inference requests for this model
        uint256 successfulInferences;   // Count of successfully verified inferences
    }

    /** @dev Represents a dataset registered within the Nexus. */
    struct DataSet {
        uint256 dataSetId;              // Unique ID for the dataset
        address provider;               // Address of the data provider
        string metadataURI;             // URI to off-chain dataset details (e.g., IPFS)
        uint256 creationTime;           // Timestamp of dataset registration
        uint256 totalUsages;            // Number of times this dataset was used (e.g., for training/inference)
    }

    /** @dev Details of a challenge against an AI model's performance. */
    struct ModelChallenge {
        uint256 challengeId;            // Unique ID for the challenge
        uint256 modelTokenId;           // ID of the challenged AI model NFT
        address challenger;             // Address initiating the challenge
        address validator;              // Address of the validator who resolved the challenge (0x0 if not resolved)
        uint256 challengeTime;          // Timestamp when the challenge was initiated
        string reason;                  // Description of the challenge reason
        ChallengeStatus status;         // Current status of the challenge
        uint256 inferenceRequestId;     // If applicable, related inference request demonstrating the issue
    }

    /** @dev Details of a challenge against a dataset's quality. */
    struct DataSetChallenge {
        uint256 challengeId;            // Unique ID for the challenge
        uint256 dataSetId;              // ID of the challenged dataset
        address challenger;             // Address initiating the challenge
        address validator;              // Address of the validator who resolved the challenge (0x0 if not resolved)
        uint256 challengeTime;          // Timestamp when the challenge was initiated
        string reason;                  // Description of the challenge reason
        ChallengeStatus status;         // Current status of the challenge
    }

    /** @dev Details of an AI model inference request. */
    struct InferenceRequest {
        uint256 requestId;              // Unique ID for the inference request
        uint256 modelTokenId;           // ID of the model used for inference
        address requester;              // Address requesting the inference
        string inputDataURI;            // URI to off-chain input data for inference
        uint256 requestTime;            // Timestamp when the request was made
        uint256 paymentAmount;          // Amount of ETH held in escrow for the inference
        address computeProvider;        // Address of the off-chain entity performing computation
        string outputDataURI;           // URI to off-chain output result
        InferenceStatus status;         // Current status of the inference request
        uint256 verificationTime;       // Timestamp when the result was verified
        uint256 refundDeadline;         // Latest time for result submission/verification before requester can claim refund
    }

    // --- State Variables ---

    Counters.Counter private _modelTokenIds;        // Counter for unique EvoMind NFT IDs
    Counters.Counter private _dataSetIds;           // Counter for unique dataset IDs
    Counters.Counter private _modelChallengeIds;    // Counter for unique model challenge IDs
    Counters.Counter private _dataSetChallengeIds;  // Counter for unique dataset challenge IDs
    Counters.Counter private _inferenceRequestIds;  // Counter for unique inference request IDs

    mapping(address => UserProfile) public userProfiles;        // Maps user addresses to their profiles
    mapping(uint256 => AIModel) public aiModels;                // Maps EvoMind NFT IDs to AIModel structs
    mapping(uint256 => DataSet) public dataSets;                // Maps dataset IDs to DataSet structs
    mapping(uint256 => ModelChallenge) public modelChallenges;  // Maps model challenge IDs to ModelChallenge structs
    mapping(uint256 => DataSetChallenge) public dataSetChallenges; // Maps dataset challenge IDs to DataSetChallenge structs
    mapping(uint256 => InferenceRequest) public inferenceRequests; // Maps inference request IDs to InferenceRequest structs

    // Configuration parameters (can be updated by owner for dynamic adjustments)
    uint256 public minModelStake = 1 ether; // Minimum ETH developer must stake per model
    uint256 public minReputationStake = 0.1 ether; // Minimum ETH a user can stake for reputation boost
    uint256 public inferenceFeePercent = 5; // Percentage (e.g., 5 for 5%) of inference payment taken as platform fee
    uint256 public dataProviderRoyaltyPercent = 2; // Percentage of the *platform fee* allocated as royalty to data providers
    uint256 public challengePeriodSeconds = 7 days; // Time (in seconds) for challenges to be resolved
    uint256 public inferenceTimeoutSeconds = 2 days; // Max time (in seconds) for inference to be submitted/verified

    // --- Events ---
    event ConfigUpdated(uint256 newInferenceFee, uint256 newDataRoyalty, uint256 newChallengePeriod, uint256 newInferenceTimeout);
    event UserRegistered(address indexed user, UserRole role);
    event ReputationUpdated(address indexed user, UserRole role, uint256 newScore, string reason);
    event ReputationStakeUpdated(address indexed user, UserRole role, uint256 amount, bool isStaked);

    event AIModelRegistered(uint256 indexed tokenId, address indexed developer, string metadataURI);
    event ModelMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event ModelPerformanceUpdated(uint256 indexed tokenId, uint256 newAccuracy, uint256 newLatency, address indexed reporter);
    event ModelChallenged(uint256 indexed challengeId, uint256 indexed modelTokenId, address indexed challenger, string reason);
    event ModelChallengeResolved(uint256 indexed challengeId, bool isChallengerCorrect, string resolutionDetails);
    event ModelDecommissioned(uint256 indexed tokenId, address indexed by);

    event DataSetRegistered(uint256 indexed dataSetId, address indexed provider, string metadataURI);
    event DataSetMetadataUpdated(uint256 indexed dataSetId, string newMetadataURI);
    event DataSetChallenged(uint256 indexed challengeId, uint256 indexed dataSetId, address indexed challenger, string reason);
    event DataSetChallengeResolved(uint256 indexed challengeId, bool isChallengerCorrect, string resolutionDetails);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelTokenId, address indexed requester, uint256 paymentAmount);
    event InferenceResultSubmitted(uint256 indexed requestId, address indexed computeProvider, string outputDataURI);
    event InferenceResultVerified(uint256 indexed requestId, bool isCorrect, address indexed verifier);
    event InferenceRefunded(uint256 indexed requestId, address indexed requester, uint256 amount);

    // --- Modifiers ---
    /** @dev Restricts access to functions to only callers with a specific `UserRole`. */
    modifier onlyRole(UserRole _role) {
        require(userProfiles[msg.sender].role == _role, "EvoMindNexus: Not authorized for this role.");
        _;
    }

    /** @dev Restricts access to functions to only the owner of a specific EvoMind NFT. */
    modifier onlyModelOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "EvoMindNexus: NFT does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "EvoMindNexus: Not the owner of this model NFT.");
        _;
    }

    /** @dev Restricts access to functions to any registered user (developer, provider, or validator). */
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].role != UserRole.None, "EvoMindNexus: Not a registered user.");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the EvoMindNexus contract.
     * Mints EvoMind AI Model NFTs with name "EvoMindNexus AI Model NFT" and symbol "EVOMIND".
     * Sets the deployer as the initial owner of the contract.
     */
    constructor() ERC721Enumerable("EvoMindNexus AI Model NFT", "EVOMIND") Ownable(msg.sender) {}

    // --- I. Core Components & State Management ---

    /**
     * @dev Allows the contract owner to update key configuration parameters of the Nexus.
     * @param _newInferenceFee New percentage for inference fees (e.g., 5 for 5%).
     * @param _newDataRoyalty New percentage for data provider royalty from inference fees.
     * @param _newChallengePeriod New duration in seconds for challenge resolution.
     * @param _newInferenceTimeout New duration in seconds for inference completion timeout.
     */
    function updateNexusConfig(
        uint256 _newInferenceFee,
        uint256 _newDataRoyalty,
        uint256 _newChallengePeriod,
        uint256 _newInferenceTimeout
    ) external onlyOwner {
        require(_newInferenceFee <= 100 && _newDataRoyalty <= 100, "EvoMindNexus: Percentage cannot exceed 100.");
        // Ensure that the sum of platform fee and data provider royalty does not exceed 100% of the platform fee itself.
        // If dataProviderRoyaltyPercent is a percentage of the *total payment*, this check needs adjustment.
        // Currently, it's a percentage of `platformFee`.
        require(_newDataRoyalty <= 100, "EvoMindNexus: Data royalty percentage cannot exceed 100.");

        inferenceFeePercent = _newInferenceFee;
        dataProviderRoyaltyPercent = _newDataRoyalty;
        challengePeriodSeconds = _newChallengePeriod;
        inferenceTimeoutSeconds = _newInferenceTimeout;

        emit ConfigUpdated(_newInferenceFee, _newDataRoyalty, _newChallengePeriod, _newInferenceTimeout);
    }

    /**
     * @dev Registers a new address as an AI model developer.
     * Only callable by the contract owner.
     * @param _developer The address to register as a model developer.
     */
    function registerModelDeveloper(address _developer) external onlyOwner {
        require(userProfiles[_developer].role == UserRole.None, "EvoMindNexus: Address already registered.");
        userProfiles[_developer].role = UserRole.ModelDeveloper;
        emit UserRegistered(_developer, UserRole.ModelDeveloper);
    }

    /**
     * @dev Registers a new address as a data provider.
     * Only callable by the contract owner.
     * @param _provider The address to register as a data provider.
     */
    function registerDataProvider(address _provider) external onlyOwner {
        require(userProfiles[_provider].role == UserRole.None, "EvoMindNexus: Address already registered.");
        userProfiles[_provider].role = UserRole.DataProvider;
        emit UserRegistered(_provider, UserRole.DataProvider);
    }

    /**
     * @dev Registers a new address as a system validator. Validators resolve disputes and verify results.
     * Only callable by the contract owner.
     * @param _validator The address to register as a validator.
     */
    function registerValidator(address _validator) external onlyOwner {
        require(userProfiles[_validator].role == UserRole.None, "EvoMindNexus: Address already registered.");
        userProfiles[_validator].role = UserRole.Validator;
        emit UserRegistered(_validator, UserRole.Validator);
    }

    // --- II. AI Model Management (EvoMind NFTs) ---

    /**
     * @dev Registers a new AI model, mints an EvoMind NFT to the caller, and requires a security stake.
     * The stake serves as collateral for model integrity and performance.
     * @param _metadataURI Link to the off-chain metadata (e.g., IPFS) describing the model's details.
     * @param _requiredStake The amount of ETH the developer must stake (sent with transaction).
     */
    function registerAIModel(string memory _metadataURI, uint256 _requiredStake) external payable onlyRole(UserRole.ModelDeveloper) {
        require(_requiredStake >= minModelStake, "EvoMindNexus: Stake amount too low.");
        require(msg.value == _requiredStake, "EvoMindNexus: Incorrect stake amount sent. Must match _requiredStake.");

        _modelTokenIds.increment();
        uint256 newItemId = _modelTokenIds.current();

        _safeMint(msg.sender, newItemId); // Mints the NFT to the developer (msg.sender)

        aiModels[newItemId] = AIModel({
            tokenId: newItemId,
            developer: msg.sender,
            metadataURI: _metadataURI,
            creationTime: block.timestamp,
            requiredStake: _requiredStake,
            currentAccuracy: 0, // Initial accuracy, to be updated by validators/oracles
            currentLatency: type(uint256).max, // Initial high latency, to be updated
            status: ModelStatus.Active,
            totalInferences: 0,
            successfulInferences: 0
        });

        // The sent ETH is held by the contract's balance
        emit AIModelRegistered(newItemId, msg.sender, _metadataURI);
    }

    /**
     * @dev Allows the owner of an EvoMind NFT to update its off-chain metadata URI.
     * This allows updating external information about the model without changing its on-chain ID.
     * @param _tokenId The ID of the EvoMind NFT.
     * @param _newMetadataURI The new URI for the model's metadata.
     */
    function updateModelMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyModelOwner(_tokenId) {
        aiModels[_tokenId].metadataURI = _newMetadataURI;
        emit ModelMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Allows a validator to update on-chain performance metrics of a model.
     * This dynamically changes the NFT's underlying data, reflecting real-world performance.
     * In a production system, this would typically be called by a decentralized oracle network.
     * @param _tokenId The ID of the EvoMind NFT.
     * @param _newAccuracy New accuracy score (e.g., 0-10000 where 10000 = 100%).
     * @param _newLatency New latency in milliseconds.
     * @param _reporter The address of the entity reporting the metrics (for auditing).
     */
    function updateModelPerformanceMetrics(
        uint256 _tokenId,
        uint256 _newAccuracy,
        uint256 _newLatency,
        address _reporter
    ) external onlyRole(UserRole.Validator) {
        require(aiModels[_tokenId].developer != address(0), "EvoMindNexus: Model does not exist.");
        require(aiModels[_tokenId].status == ModelStatus.Active, "EvoMindNexus: Model is not active and cannot have metrics updated.");
        aiModels[_tokenId].currentAccuracy = _newAccuracy;
        aiModels[_tokenId].currentLatency = _newLatency;
        emit ModelPerformanceUpdated(_tokenId, _newAccuracy, _newLatency, _reporter);
    }

    /**
     * @dev Allows any registered user to formally challenge the reported performance of an AI model.
     * This initiates a dispute process, potentially leading to penalties for the developer.
     * @param _tokenId The ID of the EvoMind NFT being challenged.
     * @param _inferenceRequestId The ID of a specific inference request that demonstrates the poor performance.
     * @param _reason A description of why the model's performance is challenged.
     */
    function challengeModelPerformance(
        uint256 _tokenId,
        uint256 _inferenceRequestId,
        string memory _reason
    ) external onlyRegisteredUser {
        require(aiModels[_tokenId].developer != address(0), "EvoMindNexus: Model does not exist.");
        require(aiModels[_tokenId].status == ModelStatus.Active, "EvoMindNexus: Model cannot be challenged in current status.");
        require(inferenceRequests[_inferenceRequestId].modelTokenId == _tokenId, "EvoMindNexus: Inference request does not match model.");
        require(inferenceRequests[_inferenceRequestId].status == InferenceStatus.VerifiedFailure, "EvoMindNexus: Only failed inferences can trigger a challenge.");

        aiModels[_tokenId].status = ModelStatus.Challenged; // Mark model as challenged

        _modelChallengeIds.increment();
        uint256 newChallengeId = _modelChallengeIds.current();

        modelChallenges[newChallengeId] = ModelChallenge({
            challengeId: newChallengeId,
            modelTokenId: _tokenId,
            challenger: msg.sender,
            validator: address(0), // Validator is assigned/selected upon resolution
            challengeTime: block.timestamp,
            reason: _reason,
            status: ChallengeStatus.Open,
            inferenceRequestId: _inferenceRequestId
        });

        emit ModelChallenged(newChallengeId, _tokenId, msg.sender, _reason);
    }

    /**
     * @dev Allows a validator to resolve an ongoing model performance challenge.
     * Updates reputation scores and potentially distributes/penalizes developer stake (simplified here).
     * @param _challengeId The ID of the model challenge to resolve.
     * @param _isChallengerCorrect True if the challenger's claim (that the model performed poorly) is valid.
     * @param _resolutionDetails A detailed description of the resolution.
     */
    function resolveModelChallenge(
        uint256 _challengeId,
        bool _isChallengerCorrect,
        string memory _resolutionDetails
    ) external onlyRole(UserRole.Validator) {
        ModelChallenge storage challenge = modelChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "EvoMindNexus: Challenge is not open or does not exist.");
        require(block.timestamp <= challenge.challengeTime + challengePeriodSeconds, "EvoMindNexus: Challenge resolution period has expired.");

        AIModel storage model = aiModels[challenge.modelTokenId];
        model.status = ModelStatus.Active; // Set model back to active after resolution

        challenge.status = _isChallengerCorrect ? ChallengeStatus.ResolvedCorrect : ChallengeStatus.ResolvedIncorrect;
        challenge.validator = msg.sender; // Record the validator who resolved it

        if (_isChallengerCorrect) {
            // Challenger was correct: Reward challenger, penalize developer.
            _updateReputationScore(challenge.challenger, userProfiles[challenge.challenger].role, 50, "Model challenge successful.");
            _updateReputationScore(model.developer, UserRole.ModelDeveloper, -100, "Model performance challenge failed.");
            // A portion of model.requiredStake would be transferred from the contract to challenger and/or validator here.
        } else {
            // Challenger was incorrect: Penalize challenger, potentially reward developer.
            _updateReputationScore(challenge.challenger, userProfiles[challenge.challenger].role, -20, "Model challenge unsuccessful.");
            _updateReputationScore(model.developer, UserRole.ModelDeveloper, 10, "Model performance challenge withstood.");
        }
        _updateReputationScore(msg.sender, UserRole.Validator, 20, "Resolved model challenge correctly."); // Validator always rewarded for resolution
        emit ModelChallengeResolved(_challengeId, _isChallengerCorrect, _resolutionDetails);
    }

    /**
     * @dev Allows the model owner or contract owner to decommission an AI model.
     * This renders the model inactive for new inference requests and refunds the developer's stake.
     * @param _tokenId The ID of the EvoMind NFT to decommission.
     */
    function decommissionModel(uint256 _tokenId) external onlyModelOwner(_tokenId) {
        AIModel storage model = aiModels[_tokenId];
        require(model.status == ModelStatus.Active, "EvoMindNexus: Model is not active and cannot be decommissioned.");

        model.status = ModelStatus.Decommissioned;

        // Refund the developer's stake.
        // In a production contract, consider a pull payment mechanism (`call`) instead of `transfer`
        // to mitigate re-entrancy risks and avoid gas limit issues.
        (bool success, ) = payable(model.developer).call{value: model.requiredStake}("");
        require(success, "EvoMindNexus: Failed to refund model stake.");

        emit ModelDecommissioned(_tokenId, msg.sender);
    }

    /**
     * @dev Retrieves comprehensive details about a registered AI model.
     * @param _tokenId The ID of the EvoMind NFT.
     * @return An `AIModel` struct containing all model-related details.
     */
    function getModelDetails(uint256 _tokenId) external view returns (AIModel memory) {
        require(aiModels[_tokenId].developer != address(0), "EvoMindNexus: Model NFT does not exist.");
        return aiModels[_tokenId];
    }

    // --- III. Data Management ---

    /**
     * @dev Allows a registered data provider to register a new dataset.
     * @param _metadataURI Link to the off-chain metadata (e.g., IPFS) describing the dataset.
     */
    function registerDataSet(string memory _metadataURI) external onlyRole(UserRole.DataProvider) {
        _dataSetIds.increment();
        uint256 newDataSetId = _dataSetIds.current();

        dataSets[newDataSetId] = DataSet({
            dataSetId: newDataSetId,
            provider: msg.sender,
            metadataURI: _metadataURI,
            creationTime: block.timestamp,
            totalUsages: 0
        });
        emit DataSetRegistered(newDataSetId, msg.sender, _metadataURI);
    }

    /**
     * @dev Allows the data provider to update the off-chain metadata URI for their registered dataset.
     * @param _dataSetId The ID of the dataset.
     * @param _newMetadataURI The new URI for the dataset's metadata.
     */
    function updateDataSetMetadata(uint256 _dataSetId, string memory _newMetadataURI) external onlyRole(UserRole.DataProvider) {
        require(dataSets[_dataSetId].provider == msg.sender, "EvoMindNexus: Not the owner of this dataset.");
        dataSets[_dataSetId].metadataURI = _newMetadataURI;
        emit DataSetMetadataUpdated(_dataSetId, _newMetadataURI);
    }

    /**
     * @dev Allows any registered participant to challenge the quality or integrity of a registered dataset.
     * @param _dataSetId The ID of the dataset being challenged.
     * @param _reason A description of why the dataset's quality is challenged.
     */
    function challengeDataSetQuality(uint256 _dataSetId, string memory _reason) external onlyRegisteredUser {
        require(dataSets[_dataSetId].provider != address(0), "EvoMindNexus: Dataset does not exist.");
        _dataSetChallengeIds.increment();
        uint256 newChallengeId = _dataSetChallengeIds.current();

        dataSetChallenges[newChallengeId] = DataSetChallenge({
            challengeId: newChallengeId,
            dataSetId: _dataSetId,
            challenger: msg.sender,
            validator: address(0), // Validator assigned/selected upon resolution
            challengeTime: block.timestamp,
            reason: _reason,
            status: ChallengeStatus.Open
        });
        emit DataSetChallenged(newChallengeId, _dataSetId, msg.sender, _reason);
    }

    /**
     * @dev Allows a validator to resolve a dataset quality challenge, affecting data provider reputation.
     * @param _challengeId The ID of the dataset challenge to resolve.
     * @param _isChallengerCorrect True if the challenger's claim (about poor dataset quality) is valid.
     * @param _resolutionDetails A detailed description of the resolution.
     */
    function resolveDataSetChallenge(
        uint256 _challengeId,
        bool _isChallengerCorrect,
        string memory _resolutionDetails
    ) external onlyRole(UserRole.Validator) {
        DataSetChallenge storage challenge = dataSetChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "EvoMindNexus: Challenge is not open or does not exist.");
        require(block.timestamp <= challenge.challengeTime + challengePeriodSeconds, "EvoMindNexus: Challenge period has expired.");

        challenge.status = _isChallengerCorrect ? ChallengeStatus.ResolvedCorrect : ChallengeStatus.ResolvedIncorrect;
        challenge.validator = msg.sender;

        if (_isChallengerCorrect) {
            _updateReputationScore(challenge.challenger, userProfiles[challenge.challenger].role, 30, "Dataset challenge successful.");
            _updateReputationScore(dataSets[challenge.dataSetId].provider, UserRole.DataProvider, -50, "Dataset quality challenge failed.");
        } else {
            _updateReputationScore(challenge.challenger, userProfiles[challenge.challenger].role, -10, "Dataset challenge unsuccessful.");
            _updateReputationScore(dataSets[challenge.dataSetId].provider, UserRole.DataProvider, 5, "Dataset quality challenge withstood.");
        }
        _updateReputationScore(msg.sender, UserRole.Validator, 15, "Resolved dataset challenge correctly."); // Validator always rewarded for resolution
        emit DataSetChallengeResolved(_challengeId, _isChallengerCorrect, _resolutionDetails);
    }

    // --- IV. Reputation System (NexusRep) ---

    /**
     * @dev Retrieves the current reputation score of a user for a specific role.
     * The score is a combination of base reputation and a scaled value of staked tokens.
     * @param _user The address of the user.
     * @param _role The role for which to get the reputation.
     * @return The combined reputation score.
     */
    function getReputationScore(address _user, UserRole _role) external view returns (uint256) {
        require(userProfiles[_user].role == _role, "EvoMindNexus: User not registered for this role or role mismatch.");
        // Simple additive model: base reputation + (staked tokens / 1 ETH divisor for scaling)
        return userProfiles[_user].reputation.add(userProfiles[_user].stakedReputationTokens.div(1 ether)); // 1 ETH staked adds 1 to reputation
    }

    /**
     * @dev Allows a user to stake ETH to temporarily boost their reputation score for a specific role.
     * The staked ETH is held by the contract.
     * @param _role The role for which reputation is being boosted.
     * @param _amount The amount of ETH to stake (sent with transaction).
     */
    function stakeForReputationBoost(UserRole _role, uint256 _amount) external payable onlyRole(_role) {
        require(_amount >= minReputationStake, "EvoMindNexus: Stake amount too low.");
        require(msg.value == _amount, "EvoMindNexus: Incorrect stake amount sent. Must match _amount.");
        userProfiles[msg.sender].stakedReputationTokens = userProfiles[msg.sender].stakedReputationTokens.add(_amount);
        emit ReputationStakeUpdated(msg.sender, _role, _amount, true);
    }

    /**
     * @dev Allows a user to withdraw their staked ETH for reputation.
     * In a more complex system, this could have cooldowns or penalties.
     * @param _role The role for which reputation tokens were staked.
     */
    function withdrawReputationStake(UserRole _role) external onlyRole(_role) {
        uint256 stakedAmount = userProfiles[msg.sender].stakedReputationTokens;
        require(stakedAmount > 0, "EvoMindNexus: No tokens staked for this role.");
        userProfiles[msg.sender].stakedReputationTokens = 0;
        // In a production contract, consider a pull payment mechanism (`call`) instead of `transfer`.
        (bool success, ) = payable(msg.sender).call{value: stakedAmount}("");
        require(success, "EvoMindNexus: Failed to withdraw reputation stake.");
        emit ReputationStakeUpdated(msg.sender, _role, stakedAmount, false);
    }

    /**
     * @dev Internal function to modify a user's reputation score based on on-chain events.
     * @param _user The address whose reputation is being updated.
     * @param _role The role for which reputation is being updated.
     * @param _delta The change in reputation (positive for gain, negative for loss).
     * @param _reason A description for the reputation change.
     */
    function _updateReputationScore(address _user, UserRole _role, int256 _delta, string memory _reason) internal {
        require(userProfiles[_user].role == _role, "EvoMindNexus: User role mismatch for reputation update.");

        if (_delta > 0) {
            userProfiles[_user].reputation = userProfiles[_user].reputation.add(uint256(_delta));
        } else if (_delta < 0) {
            uint256 absDelta = uint256(-_delta);
            if (userProfiles[_user].reputation <= absDelta) {
                userProfiles[_user].reputation = 0; // Reputation cannot go below zero
            } else {
                userProfiles[_user].reputation = userProfiles[_user].reputation.sub(absDelta);
            }
        }
        emit ReputationUpdated(_user, _role, userProfiles[_user].reputation, _reason);
    }

    // --- V. Inference & Payment Orchestration ---

    /**
     * @dev Allows a user to request an AI model inference, locking up payment in escrow.
     * The payment covers the compute provider's fee, platform fee, and data provider royalties.
     * @param _tokenId The ID of the AI model NFT to request inference from.
     * @param _inputDataURI Link to the off-chain input data for the inference.
     */
    function requestModelInference(uint256 _tokenId, string memory _inputDataURI) external payable {
        AIModel storage model = aiModels[_tokenId];
        require(model.developer != address(0), "EvoMindNexus: Model does not exist.");
        require(model.status == ModelStatus.Active, "EvoMindNexus: Model is not active or available for inference.");
        require(msg.value > 0, "EvoMindNexus: Inference fee must be greater than zero.");

        _inferenceRequestIds.increment();
        uint256 newRequestId = _inferenceRequestIds.current();

        inferenceRequests[newRequestId] = InferenceRequest({
            requestId: newRequestId,
            modelTokenId: _tokenId,
            requester: msg.sender,
            inputDataURI: _inputDataURI,
            requestTime: block.timestamp,
            paymentAmount: msg.value,
            computeProvider: address(0), // To be specified by the entity submitting the result
            outputDataURI: "",
            status: InferenceStatus.Requested,
            verificationTime: 0,
            refundDeadline: block.timestamp + inferenceTimeoutSeconds
        });
        emit InferenceRequested(newRequestId, _tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Allows an off-chain compute provider to submit the result of an inference request.
     * The compute provider does not need to be pre-registered, but their address is recorded.
     * @param _requestId The ID of the inference request.
     * @param _outputDataURI Link to the off-chain output data resulting from the inference.
     * @param _computeProvider The address of the entity that performed the computation.
     */
    function submitInferenceResult(
        uint256 _requestId,
        string memory _outputDataURI,
        address _computeProvider
    ) external { // Any address can submit, but a validator will verify.
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == InferenceStatus.Requested, "EvoMindNexus: Request not in 'Requested' state or does not exist.");
        require(block.timestamp <= request.refundDeadline, "EvoMindNexus: Inference submission deadline has passed.");
        require(_computeProvider != address(0), "EvoMindNexus: Compute provider cannot be the zero address.");

        request.outputDataURI = _outputDataURI;
        request.computeProvider = _computeProvider;
        request.status = InferenceStatus.ResultSubmitted;

        emit InferenceResultSubmitted(_requestId, _computeProvider, _outputDataURI);
    }

    /**
     * @dev Allows a validator to verify the submitted inference result.
     * If correct, payments are released; if incorrect, the user is refunded and penalties may apply.
     * @param _requestId The ID of the inference request to verify.
     * @param _isCorrect True if the inference result is deemed correct and valid.
     * @param _reporter The address of the validator performing the verification.
     */
    function verifyInferenceResult(
        uint256 _requestId,
        bool _isCorrect,
        address _reporter
    ) external onlyRole(UserRole.Validator) {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == InferenceStatus.ResultSubmitted, "EvoMindNexus: Result not submitted or already verified.");
        require(_reporter != address(0), "EvoMindNexus: Reporter (validator) cannot be the zero address.");

        request.verificationTime = block.timestamp;

        AIModel storage model = aiModels[request.modelTokenId];
        model.totalInferences++; // Increment total inferences for the model

        if (_isCorrect) {
            request.status = InferenceStatus.VerifiedSuccess;
            model.successfulInferences++; // Increment successful inferences

            // Distribute payments
            uint256 totalAmount = request.paymentAmount;
            uint256 platformFee = totalAmount.mul(inferenceFeePercent).div(100);
            uint256 dataProviderRoyalty = platformFee.mul(dataProviderRoyaltyPercent).div(100); // Royalty from platform fee for simplicity
            uint256 computeProviderShare = totalAmount.sub(platformFee);

            // Send to compute provider
            (bool successCompute, ) = payable(request.computeProvider).call{value: computeProviderShare}("");
            require(successCompute, "EvoMindNexus: Failed to pay compute provider.");

            // Send data provider royalty.
            // In a more advanced system, data provider(s) would be linked from model metadata or explicitly specified.
            // For this example, assuming a generic data provider (can be extended to multiple or specific).
            // This is a placeholder; a real system needs a robust way to attribute data usage.
            address dataProvider = dataSets[_dataSetIds.current()].provider; // Example: using the latest registered data set's provider
            if(dataProvider != address(0) && userProfiles[dataProvider].role == UserRole.DataProvider) {
                (bool successData, ) = payable(dataProvider).call{value: dataProviderRoyalty}("");
                require(successData, "EvoMindNexus: Failed to pay data provider royalty.");
            }
            // Remainder of platformFee goes to contract owner/treasury
            (bool successOwner, ) = payable(owner()).call{value: platformFee.sub(dataProviderRoyalty)}("");
            require(successOwner, "EvoMindNexus: Failed to send platform fee.");

            // Update reputation scores based on successful verification
            _updateReputationScore(request.computeProvider, userProfiles[request.computeProvider].role, 10, "Successful inference completion.");
            _updateReputationScore(model.developer, UserRole.ModelDeveloper, 5, "Model used successfully for inference.");
            _updateReputationScore(msg.sender, UserRole.Validator, 5, "Verified inference correctly.");

        } else {
            request.status = InferenceStatus.VerifiedFailure;
            // Refund requester for incorrect inference
            (bool successRefund, ) = payable(request.requester).call{value: request.paymentAmount}("");
            require(successRefund, "EvoMindNexus: Failed to refund requester.");

            // Penalize compute provider and model developer for incorrectness
            _updateReputationScore(request.computeProvider, userProfiles[request.computeProvider].role, -20, "Inference result incorrect.");
            _updateReputationScore(model.developer, UserRole.ModelDeveloper, -10, "Model provided incorrect inference.");
            _updateReputationScore(msg.sender, UserRole.Validator, 5, "Verified inference failure correctly."); // Validator still rewarded for correct verification
        }
        emit InferenceResultVerified(_requestId, _isCorrect, _reporter);
    }

    /**
     * @dev Allows the requester to get a refund if an inference request fails to complete
     * within the timeout or is explicitly verified as incorrect.
     * @param _requestId The ID of the inference request to refund.
     */
    function refundInferenceRequest(uint256 _requestId) external {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.requester == msg.sender, "EvoMindNexus: Not the requester.");
        require(request.status == InferenceStatus.Requested || request.status == InferenceStatus.ResultSubmitted || request.status == InferenceStatus.VerifiedFailure, "EvoMindNexus: Request not in a refundable state.");
        
        // Conditions for refund:
        // 1. If result was never submitted before deadline: `request.status == InferenceStatus.Requested && block.timestamp > request.refundDeadline`
        // 2. If result was submitted but not verified before deadline: `request.status == InferenceStatus.ResultSubmitted && block.timestamp > request.refundDeadline`
        // 3. If result was verified as a failure: `request.status == InferenceStatus.VerifiedFailure`
        require(
            (request.status != InferenceStatus.Refunded) && // Not already refunded
            (
                (request.status == InferenceStatus.VerifiedFailure) || // Explicitly failed
                (request.status <= InferenceStatus.ResultSubmitted && block.timestamp > request.refundDeadline) // Timed out before verification/submission
            ),
            "EvoMindNexus: Not eligible for refund yet, or already processed."
        );

        request.status = InferenceStatus.Refunded;
        (bool success, ) = payable(request.requester).call{value: request.paymentAmount}("");
        require(success, "EvoMindNexus: Failed to send refund.");
        emit InferenceRefunded(_requestId, msg.sender, request.paymentAmount);

        // If refund due to timeout after result submitted, penalize compute provider
        if (request.status == InferenceStatus.ResultSubmitted && block.timestamp > request.refundDeadline && request.computeProvider != address(0)) {
             _updateReputationScore(request.computeProvider, userProfiles[request.computeProvider].role, -15, "Inference timed out after submission.");
        }
    }

    // --- ERC721 Overrides (required for ERC721Enumerable) ---
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```