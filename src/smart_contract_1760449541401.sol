Here's a smart contract written in Solidity for a "Decentralized AI Model Marketplace & Collaborative Training Platform." It aims to be interesting, advanced, creative, and trendy by combining concepts like on-chain metadata for off-chain AI models, collaborative training incentives, reputation building via staking and ratings, and a basic dispute resolution mechanism, all while avoiding direct replication of well-known open-source projects.

The actual heavy computation, data storage, and AI inference would occur off-chain (e.g., via IPFS, decentralized compute networks like Akash, Golem, Render, etc.), with the smart contract serving as the trust layer for managing metadata, payments, incentives, and governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for older Solidity versions, but 0.8+ has built-in checks
import "@openzeppelin/contracts/utils/Strings.sol";      // For converting uint256 to string for unique IDs
import "@openzeppelin/contracts/utils/Counters.sol";     // For generating unique sequential IDs

// --- Outline and Function Summary ---
// This smart contract establishes a Decentralized AI Model Marketplace and Collaborative Training Platform.
// It enables AI model providers to list their models, data providers to contribute datasets, and compute
// providers to bid on and execute training jobs. Users can purchase model access or inference credits.
// The platform incorporates a reputation system (via staking and ratings), and a basic dispute mechanism
// for governance. While core AI operations (inference, training, data storage) are off-chain, the
// contract manages metadata, payments, incentives, and the overall trust layer.

// I. Core Protocol Management (7 functions)
//    1. `initialize(address _protocolFeeRecipient, uint256 _protocolFeePercentageBps)`: Sets up initial contract parameters (protocol fee recipient, fee percentage). Callable once by the owner.
//    2. `transferOwnership(address newOwner)`: Transfers contract ownership (inherited from OpenZeppelin's Ownable).
//    3. `pause()`: Pauses core functionalities in emergencies (inherited from OpenZeppelin's Pausable).
//    4. `unpause()`: Unpauses core functionalities (inherited from OpenZeppelin's Pausable).
//    5. `updateProtocolFeeRecipient(address newRecipient)`: Allows the owner to change the address receiving protocol fees.
//    6. `updateProtocolFeePercentage(uint256 newFeeBps)`: Allows the owner to adjust the percentage of fees collected by the protocol (in basis points).
//    7. `withdrawProtocolFees(address tokenAddress)`: Enables the owner to withdraw accumulated protocol fees for a specific ERC20 token.

// II. AI Model Management (Provider Focused) (6 functions)
//    8. `registerAIModel(string calldata _name, string calldata _description, string calldata _ipfsHashMetadata, string[] calldata _categories, uint256 _pricePerInference, uint256 _royaltyShareBps, address _tokenAddress)`: Registers a new AI model, providing its metadata, pricing, and royalty structure. Returns a unique `modelId`.
//    9. `updateAIModelPricing(bytes32 _modelId, uint256 _newPricePerInference)`: Allows the model provider to adjust the price per inference for their model.
//    10. `updateAIModelMetadataHash(bytes32 _modelId, string calldata _newIpfsHashMetadata)`: Allows the model provider to update the IPFS hash pointing to the model's off-chain definition or inference endpoint.
//    11. `deactivateAIModel(bytes32 _modelId)`: Temporarily deactivates a model, making it unavailable for new purchases or inferences.
//    12. `reactivateAIModel(bytes32 _modelId)`: Reactivates a previously deactivated model, making it available again.
//    13. `stakeForModelAvailability(bytes32 _modelId, uint256 _amount)`: Allows a model provider to stake tokens as a guarantee for their model's uptime, performance, or quality.

// III. Collaborative Training & Data Management (7 functions)
//    14. `submitDatasetMetadata(string calldata _name, string calldata _description, string calldata _ipfsHashDataset, string[] calldata _targetModelCategories, address _tokenAddress, uint256 _rewardPerUse)`: Registers a new dataset with its metadata and defines rewards for its usage in training jobs. Returns a unique `datasetId`.
//    15. `stakeForDataQuality(bytes32 _datasetId, uint256 _amount)`: Allows a data provider to stake tokens as a guarantee for the quality or integrity of their submitted dataset.
//    16. `requestModelFineTuningJob(bytes32 _modelId, bytes32 _datasetId, uint256 _budget, string calldata _jobDetailsIpfsHash, address _tokenAddress)`: Initiates a fine-tuning job request for an existing model using a specific dataset, allocating a budget. Returns a unique `jobId`.
//    17. `bidForTrainingJob(bytes32 _jobId, uint256 _bidAmount, string calldata _computeProofDescriptorIpfsHash)`: Allows compute providers to submit bids to execute open training jobs.
//    18. `selectWinningBid(bytes32 _jobId, address _bidderAddress)`: The model owner (or governance) selects a winning bid for a training job.
//    19. `submitTrainingJobResult(bytes32 _jobId, string calldata _resultIpfsHash, string calldata _proofOfComputeIpfsHash)`: The winning bidder submits the results (e.g., trained model weights) and proof of compute for a completed job.
//    20. `verifyAndCompleteTrainingJob(bytes32 _jobId)`: Verifies the submitted training result (assumed off-chain), pays the winning bidder, and rewards the dataset provider. Callable by model owner.

// IV. Marketplace Interaction & Payments (4 functions)
//    21. `purchaseInferenceCredits(bytes32 _modelId, uint256 _numInferences, address _tokenAddress)`: Users purchase credits to perform off-chain AI model inferences. Funds are transferred to the contract.
//    22. `consumeInferenceCredit(bytes32 _modelId)`: Records the consumption of an inference credit by a user. This assumes an off-chain system verifies the actual inference and then calls this function (or a trusted relay does).
//    23. `claimModelInferenceEarnings(bytes32 _modelId, address _tokenAddress)`: Model providers can claim their accumulated earnings from inference purchases (after protocol fees).
//    24. `claimDatasetUsageRewards(bytes32 _datasetId, address _tokenAddress)`: Data providers can claim rewards for their datasets being used in training jobs.

// V. Reputation & Disputes (3 functions)
//    25. `submitModelRating(bytes32 _modelId, uint8 _rating, string calldata _reviewIpfsHash)`: Users can submit a rating (1-5) and an optional IPFS-linked review for an AI model.
//    26. `proposeDispute(bytes32 _entityId, DisputeType _type, string calldata _detailsIpfsHash)`: Allows any user or provider to formally propose a dispute regarding model quality, data integrity, or training job outcomes. Returns a unique `disputeId`.
//    27. `voteOnDispute(bytes32 _disputeId, bool _isLegitimate)`: Allows governance participants (or any address in this simplified example) to vote on proposed disputes.

// VI. Query Functions (View/Pure) (4 functions)
//    28. `getAIModelDetails(bytes32 _modelId)`: Retrieves comprehensive details for a given AI model ID.
//    29. `getDatasetDetails(bytes32 _datasetId)`: Retrieves comprehensive details for a given dataset ID.
//    30. `getUserInferenceCreditBalance(address _user, bytes32 _modelId)`: Checks the remaining inference credits a specific user has for a particular model.
//    31. `getTrainingJobDetails(bytes32 _jobId)`: Retrieves comprehensive details for a given training job ID.

contract DecentralizedAIMarketplace is Ownable, Pausable {
    using SafeMath for uint256; // Standard library for safe arithmetic operations
    using Strings for uint256;  // Utility to convert uint256 to string
    using Counters for Counters.Counter; // Utility to generate unique, sequential IDs

    // --- State Variables ---
    address public protocolFeeRecipient;
    uint256 public protocolFeePercentageBps; // Protocol fee in basis points (e.g., 100 = 1%)

    // Counters for generating unique IDs for various entities
    Counters.Counter private _modelIdCounter;
    Counters.Counter private _datasetIdCounter;
    Counters.Counter private _trainingJobIdCounter;
    Counters.Counter private _disputeIdCounter;

    // --- Enums ---
    // Statuses for a training job lifecycle
    enum TrainingJobStatus {
        Requested,       // Job is created
        BiddingOpen,     // Compute providers can submit bids
        BidAccepted,     // A winning bidder has been selected
        InProgress,      // Training is actively being performed off-chain
        ResultSubmitted, // Trainer has submitted results and proof
        Completed,       // Results verified, trainer paid, job finalized
        Failed,          // Job failed (e.g., no successful bid, bad result)
        Disputed         // Job results are under dispute
    }

    // Types of disputes that can be proposed
    enum DisputeType {
        ModelQuality,
        DataIntegrity,
        TrainingResult
    }

    // --- Structs ---
    // Represents an AI Model registered on the platform
    struct AIModel {
        bytes32 modelId;               // Unique ID of the model
        address provider;              // Address of the model owner/provider
        string name;                   // Human-readable name
        string description;            // Description of the model
        string ipfsHashMetadata;       // IPFS hash to off-chain metadata (e.g., architecture, inference endpoint, usage guide)
        string[] categories;           // Categorization (e.g., "NLP", "Computer Vision")
        uint256 pricePerInference;     // Cost per inference unit or access
        address paymentToken;          // ERC20 token for payments (address(0) for native token)
        uint256 royaltyShareBps;       // Share (in bps) of earnings from collaborative fine-tuning for original model provider
        uint256 stakedAmount;          // Tokens staked by provider for quality/availability guarantees
        bool isActive;                 // Whether the model is currently active and available
        
        mapping(address => uint256) inferenceCredits;     // User => remaining inference credits
        mapping(address => uint256) earnedInferenceFees;  // Accumulated fees for the model provider from inferences
        mapping(address => uint8) userRatings;            // User => their rating (1-5) for the model
        mapping(address => string) userReviewsIpfsHash;   // User => IPFS hash of their detailed review
        uint256 totalRatingSum;                           // Sum of all ratings for calculating average
        uint256 numRatings;                               // Total number of ratings received
    }

    // Represents a Dataset registered for collaborative training
    struct Dataset {
        bytes32 datasetId;           // Unique ID of the dataset
        address provider;            // Address of the dataset owner/provider
        string name;                 // Human-readable name
        string description;          // Description of the dataset
        string ipfsHashDataset;      // IPFS hash to the off-chain dataset location
        string[] targetModelCategories; // Categories of models this dataset is suitable for
        address rewardToken;         // ERC20 token for rewards (address(0) for native token)
        uint256 rewardPerUse;        // Reward amount for each time the dataset is used in a training job
        uint256 stakedAmount;        // Tokens staked by provider for data quality guarantees
        mapping(address => uint256) earnedUsageRewards; // Accumulated rewards for the dataset provider
    }

    // Represents a collaborative training (fine-tuning) job
    struct TrainingJob {
        bytes32 jobId;                 // Unique ID of the training job
        bytes32 modelId;               // The AI model to be fine-tuned
        bytes32 datasetId;             // The dataset to be used for training
        address requestor;             // Who initiated this training job
        uint256 budget;                // Total budget allocated for this job
        address budgetToken;           // ERC20 token for the budget (address(0) for native token)
        string jobDetailsIpfsHash;     // IPFS hash for detailed training requirements/specifications
        TrainingJobStatus status;      // Current status of the job
        address winnerBidder;          // The address of the compute provider awarded the job
        uint256 winningBidAmount;      // The amount the winner will be paid
        string resultIpfsHash;         // IPFS hash of the trained model/fine-tuned weights
        string proofOfComputeIpfsHash; // IPFS hash of the verifiable compute proof (e.g., ZKP output)
        
        mapping(address => uint256) bids;                         // Bidder address => bid amount
        mapping(address => string) bidComputeProofDescriptors;    // Bidder address => IPFS hash of compute capabilities/proof method
    }

    // Represents a proposed dispute within the platform
    struct Dispute {
        bytes32 disputeId;          // Unique ID of the dispute
        address proposer;           // Address who proposed the dispute
        bytes32 entityId;           // ID of the entity in dispute (modelId, datasetId, or jobId)
        DisputeType disputeType;    // The type of issue being disputed
        string detailsIpfsHash;     // IPFS hash to detailed dispute reasoning and evidence
        bool resolved;              // Whether the dispute has been resolved
        bool result;                // True if proposer wins, false if proposer loses
        mapping(address => bool) hasVoted; // Governance participant => has voted on this dispute
        uint256 votesFor;           // Count of votes supporting the proposer's claim
        uint256 votesAgainst;       // Count of votes against the proposer's claim
    }

    // --- Mappings to store entities by their unique IDs ---
    mapping(bytes32 => AIModel) public aiModels;
    mapping(bytes32 => Dataset) public datasets;
    mapping(bytes32 => TrainingJob) public trainingJobs;
    mapping(bytes32 => Dispute) public disputes;

    // --- Events ---
    // Protocol Management Events
    event Initialized(address indexed owner, address indexed protocolFeeRecipient, uint256 protocolFeeBps);
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, address indexed owner, uint256 amount);

    // AI Model Management Events
    event AIModelRegistered(bytes32 indexed modelId, address indexed provider, string name, address paymentToken, uint256 pricePerInference);
    event AIModelPricingUpdated(bytes32 indexed modelId, uint256 newPricePerInference);
    event AIModelMetadataHashUpdated(bytes32 indexed modelId, string newIpfsHash);
    event AIModelDeactivated(bytes32 indexed modelId);
    event AIModelReactivated(bytes32 indexed modelId);
    event AIModelAvailabilityStaked(bytes32 indexed modelId, address indexed staker, uint256 amount);

    // Dataset & Training Job Events
    event DatasetSubmitted(bytes32 indexed datasetId, address indexed provider, string name, address rewardToken, uint256 rewardPerUse);
    event DataQualityStaked(bytes32 indexed datasetId, address indexed staker, uint256 amount);
    event FineTuningJobRequested(bytes32 indexed jobId, bytes32 indexed modelId, bytes32 indexed datasetId, address indexed requestor, uint256 budget, address budgetToken);
    event TrainingJobBidSubmitted(bytes32 indexed jobId, address indexed bidder, uint256 bidAmount);
    event WinningBidSelected(bytes32 indexed jobId, address indexed winner, uint256 winningBidAmount);
    event TrainingJobResultSubmitted(bytes32 indexed jobId, string resultIpfsHash, string proofOfComputeIpfsHash);
    event TrainingJobCompleted(bytes32 indexed jobId, address indexed winner, uint256 paidAmount);

    // Marketplace Interaction Events
    event InferenceCreditsPurchased(bytes32 indexed modelId, address indexed buyer, address tokenAddress, uint256 amount, uint256 numCredits);
    event InferenceCreditConsumed(bytes32 indexed modelId, address indexed consumer);
    event ModelEarningsClaimed(bytes32 indexed modelId, address indexed receiver, address tokenAddress, uint256 amount);
    event DatasetRewardsClaimed(bytes32 indexed datasetId, address indexed receiver, address tokenAddress, uint256 amount);

    // Reputation & Dispute Events
    event ModelRatingSubmitted(bytes32 indexed modelId, address indexed rater, uint8 rating);
    event DisputeProposed(bytes32 indexed disputeId, bytes32 indexed entityId, DisputeType disputeType, address indexed proposer);
    event DisputeVoted(bytes32 indexed disputeId, address indexed voter, bool vote);
    event DisputeResolved(bytes32 indexed disputeId, bool result);

    // --- Modifiers ---
    modifier onlyModelProvider(bytes32 _modelId) {
        require(aiModels[_modelId].provider == msg.sender, "DAMA: Caller is not the model provider");
        _;
    }

    modifier onlyDatasetProvider(bytes32 _datasetId) {
        require(datasets[_datasetId].provider == msg.sender, "DAMA: Caller is not the dataset provider");
        _;
    }

    // modifier onlyTrainingJobRequestor(bytes32 _jobId) { // Not used in current simplified version, but useful
    //     require(trainingJobs[_jobId].requestor == msg.sender, "DAMA: Caller is not the job requestor");
    //     _;
    // }

    modifier onlyTrainingJobWinner(bytes32 _jobId) {
        require(trainingJobs[_jobId].winnerBidder == msg.sender, "DAMA: Caller is not the winning bidder");
        _;
    }

    // modifier onlyDisputeProposer(bytes32 _disputeId) { // Not used in current simplified version, but useful
    //     require(disputes[_disputeId].proposer == msg.sender, "DAMA: Caller is not the dispute proposer");
    //     _;
    // }

    // --- Constructor & Initialization ---

    constructor() Ownable(msg.sender) Pausable() {}

    // @notice Initializes the contract with protocol fee recipient and percentage.
    // @param _protocolFeeRecipient The address to receive protocol fees.
    // @param _protocolFeePercentageBps The protocol fee percentage in basis points (e.g., 100 for 1%).
    function initialize(address _protocolFeeRecipient, uint256 _protocolFeePercentageBps) external onlyOwner {
        require(!_isInitialized, "DAMA: Contract already initialized");
        require(_protocolFeeRecipient != address(0), "DAMA: Fee recipient cannot be zero address");
        require(_protocolFeePercentageBps <= 10000, "DAMA: Fee percentage cannot exceed 100%"); // 10000 bps = 100%

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeePercentageBps = _protocolFeePercentageBps;
        _isInitialized = true; // Internal flag to prevent re-initialization
        emit Initialized(owner(), _protocolFeeRecipient, _protocolFeePercentageBps);
    }
    bool private _isInitialized = false; // Prevents re-initialization

    // --- I. Core Protocol Management ---

    // `transferOwnership`, `pause`, `unpause` are inherited from Ownable and Pausable respectively.

    // @notice Updates the address that receives protocol fees. Only callable by the owner.
    // @param _newRecipient The new address for protocol fees.
    function updateProtocolFeeRecipient(address _newRecipient) external onlyOwner whenNotPaused {
        require(_newRecipient != address(0), "DAMA: New recipient cannot be zero address");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    // @notice Updates the percentage of fees collected by the protocol. Only callable by the owner.
    // @param _newFeeBps The new protocol fee percentage in basis points.
    function updateProtocolFeePercentage(uint256 _newFeeBps) external onlyOwner whenNotPaused {
        require(_newFeeBps <= 10000, "DAMA: Fee percentage cannot exceed 100%");
        emit ProtocolFeePercentageUpdated(protocolFeePercentageBps, _newFeeBps);
        protocolFeePercentageBps = _newFeeBps;
    }

    // @notice Allows the owner to withdraw accumulated protocol fees for a specific token.
    // @param _tokenAddress The address of the ERC20 token to withdraw.
    function withdrawProtocolFees(address _tokenAddress) external onlyOwner {
        // SafeMath handles potential underflow/overflow implicitly if `balance` is zero
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance > 0, "DAMA: No fees to withdraw for this token");
        
        IERC20(_tokenAddress).transfer(protocolFeeRecipient, balance);
        emit ProtocolFeesWithdrawn(_tokenAddress, protocolFeeRecipient, balance);
    }

    // --- II. AI Model Management ---

    // @notice Registers a new AI model in the marketplace.
    // @param _name The name of the AI model.
    // @param _description A brief description of the model.
    // @param _ipfsHashMetadata IPFS hash pointing to the model's off-chain metadata, architecture, inference API details.
    // @param _categories An array of categories the model belongs to (e.g., "NLP", "Computer Vision").
    // @param _pricePerInference The price for a single inference or unit of access.
    // @param _royaltyShareBps The percentage (in basis points) of future collaborative earnings for the model owner.
    // @param _tokenAddress The ERC20 token address for payments to this model (address(0) for native token).
    // @return modelId The unique ID of the registered model.
    function registerAIModel(
        string calldata _name,
        string calldata _description,
        string calldata _ipfsHashMetadata,
        string[] calldata _categories,
        uint256 _pricePerInference,
        uint256 _royaltyShareBps,
        address _tokenAddress
    ) external whenNotPaused returns (bytes32 modelId) {
        require(bytes(_name).length > 0, "DAMA: Model name cannot be empty");
        require(bytes(_ipfsHashMetadata).length > 0, "DAMA: IPFS metadata hash cannot be empty");
        require(_royaltyShareBps <= 10000, "DAMA: Royalty share cannot exceed 100%"); // 10000 bps = 100%

        _modelIdCounter.increment();
        // Generate a unique bytes32 ID
        modelId = keccak256(abi.encodePacked("AIModel-", _modelIdCounter.current().toString(), msg.sender, block.timestamp));

        aiModels[modelId] = AIModel({
            modelId: modelId,
            provider: msg.sender,
            name: _name,
            description: _description,
            ipfsHashMetadata: _ipfsHashMetadata,
            categories: _categories,
            pricePerInference: _pricePerInference,
            paymentToken: _tokenAddress,
            royaltyShareBps: _royaltyShareBps,
            stakedAmount: 0,
            isActive: true,
            // Initialize mappings, these are implicitly empty
            // earnedInferenceFees: new mapping(address => uint256), 
            // inferenceCredits: new mapping(address => uint256),
            // userRatings: new mapping(address => uint8),
            // userReviewsIpfsHash: new mapping(address => string),
            totalRatingSum: 0,
            numRatings: 0
        });

        emit AIModelRegistered(modelId, msg.sender, _name, _tokenAddress, _pricePerInference);
        return modelId;
    }

    // @notice Updates the inference price for an existing AI model. Only callable by the model provider.
    // @param _modelId The ID of the model to update.
    // @param _newPricePerInference The new price per inference.
    function updateAIModelPricing(bytes32 _modelId, uint256 _newPricePerInference) external onlyModelProvider(_modelId) whenNotPaused {
        aiModels[_modelId].pricePerInference = _newPricePerInference;
        emit AIModelPricingUpdated(_modelId, _newPricePerInference);
    }

    // @notice Updates the IPFS hash for a model's off-chain metadata. Only callable by the model provider.
    // @param _modelId The ID of the model to update.
    // @param _newIpfsHashMetadata The new IPFS hash.
    function updateAIModelMetadataHash(bytes32 _modelId, string calldata _newIpfsHashMetadata) external onlyModelProvider(_modelId) whenNotPaused {
        require(bytes(_newIpfsHashMetadata).length > 0, "DAMA: IPFS metadata hash cannot be empty");
        aiModels[_modelId].ipfsHashMetadata = _newIpfsHashMetadata;
        emit AIModelMetadataHashUpdated(_modelId, _newIpfsHashMetadata);
    }

    // @notice Deactivates an AI model, making it unavailable. Only callable by the model provider.
    // @param _modelId The ID of the model to deactivate.
    function deactivateAIModel(bytes32 _modelId) external onlyModelProvider(_modelId) whenNotPaused {
        require(aiModels[_modelId].isActive, "DAMA: Model is already deactivated");
        aiModels[_modelId].isActive = false;
        emit AIModelDeactivated(_modelId);
    }

    // @notice Reactivates a deactivated AI model. Only callable by the model provider.
    // @param _modelId The ID of the model to reactivate.
    function reactivateAIModel(bytes32 _modelId) external onlyModelProvider(_modelId) whenNotPaused {
        require(!aiModels[_modelId].isActive, "DAMA: Model is already active");
        aiModels[_modelId].isActive = true;
        emit AIModelReactivated(_modelId);
    }

    // @notice Allows a model provider to stake tokens to guarantee model availability/quality.
    // @param _modelId The ID of the model.
    // @param _amount The amount of tokens to stake. Must be approved beforehand if ERC20.
    function stakeForModelAvailability(bytes32 _modelId, uint256 _amount) external onlyModelProvider(_modelId) whenNotPaused {
        require(_amount > 0, "DAMA: Stake amount must be greater than zero");
        
        AIModel storage model = aiModels[_modelId];
        // For ERC20, require caller to approve transferFrom first.
        IERC20(model.paymentToken).transferFrom(msg.sender, address(this), _amount);
        model.stakedAmount = model.stakedAmount.add(_amount);
        emit AIModelAvailabilityStaked(_modelId, msg.sender, _amount);
    }

    // --- III. Collaborative Training & Data Management ---

    // @notice Registers a new dataset for use in collaborative training.
    // @param _name The name of the dataset.
    // @param _description A brief description of the dataset.
    // @param _ipfsHashDataset IPFS hash pointing to the dataset's off-chain location.
    // @param _targetModelCategories Categories of AI models this dataset is suitable for.
    // @param _tokenAddress The ERC20 token address for rewards (address(0) for native token).
    // @param _rewardPerUse The reward amount for each time the dataset is used in a training job.
    // @return datasetId The unique ID of the registered dataset.
    function submitDatasetMetadata(
        string calldata _name,
        string calldata _description,
        string calldata _ipfsHashDataset,
        string[] calldata _targetModelCategories,
        address _tokenAddress,
        uint256 _rewardPerUse
    ) external whenNotPaused returns (bytes32 datasetId) {
        require(bytes(_name).length > 0, "DAMA: Dataset name cannot be empty");
        require(bytes(_ipfsHashDataset).length > 0, "DAMA: IPFS dataset hash cannot be empty");

        _datasetIdCounter.increment();
        datasetId = keccak256(abi.encodePacked("Dataset-", _datasetIdCounter.current().toString(), msg.sender, block.timestamp));

        datasets[datasetId] = Dataset({
            datasetId: datasetId,
            provider: msg.sender,
            name: _name,
            description: _description,
            ipfsHashDataset: _ipfsHashDataset,
            targetModelCategories: _targetModelCategories,
            rewardToken: _tokenAddress,
            rewardPerUse: _rewardPerUse,
            stakedAmount: 0
            // earnedUsageRewards: new mapping(address => uint256) // Implicitly empty
        });

        emit DatasetSubmitted(datasetId, msg.sender, _name, _tokenAddress, _rewardPerUse);
        return datasetId;
    }

    // @notice Allows a data provider to stake tokens to guarantee data quality.
    // @param _datasetId The ID of the dataset.
    // @param _amount The amount of tokens to stake. Must be approved beforehand if ERC20.
    function stakeForDataQuality(bytes32 _datasetId, uint256 _amount) external onlyDatasetProvider(_datasetId) whenNotPaused {
        require(_amount > 0, "DAMA: Stake amount must be greater than zero");
        
        Dataset storage dataset = datasets[_datasetId];
        IERC20(dataset.rewardToken).transferFrom(msg.sender, address(this), _amount);
        dataset.stakedAmount = dataset.stakedAmount.add(_amount);
        emit DataQualityStaked(_datasetId, msg.sender, _amount);
    }

    // @notice Requests a fine-tuning job for an existing AI model using a specific dataset.
    // The requestor must provide the budget.
    // @param _modelId The ID of the model to fine-tune.
    // @param _datasetId The ID of the dataset to use.
    // @param _budget The total budget allocated for this training job.
    // @param _jobDetailsIpfsHash IPFS hash for detailed training requirements and specifications.
    // @param _tokenAddress The ERC20 token address for the budget (address(0) for native token).
    // @return jobId The unique ID of the requested training job.
    function requestModelFineTuningJob(
        bytes32 _modelId,
        bytes32 _datasetId,
        uint256 _budget,
        string calldata _jobDetailsIpfsHash,
        address _tokenAddress
    ) external payable whenNotPaused returns (bytes32 jobId) {
        require(aiModels[_modelId].modelId == _modelId, "DAMA: Model not found");
        require(datasets[_datasetId].datasetId == _datasetId, "DAMA: Dataset not found");
        require(_budget > 0, "DAMA: Budget must be greater than zero");
        require(bytes(_jobDetailsIpfsHash).length > 0, "DAMA: Job details IPFS hash cannot be empty");

        if (_tokenAddress == address(0)) { // Native token payment
            require(msg.value == _budget, "DAMA: Native token value must match budget");
        } else { // ERC20 token payment
            // Caller must have approved this contract to spend _budget amount beforehand
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _budget);
        }

        _trainingJobIdCounter.increment();
        jobId = keccak256(abi.encodePacked("TrainingJob-", _trainingJobIdCounter.current().toString(), msg.sender, block.timestamp));

        trainingJobs[jobId] = TrainingJob({
            jobId: jobId,
            modelId: _modelId,
            datasetId: _datasetId,
            requestor: msg.sender,
            budget: _budget,
            budgetToken: _tokenAddress,
            jobDetailsIpfsHash: _jobDetailsIpfsHash,
            status: TrainingJobStatus.BiddingOpen,
            winnerBidder: address(0),
            winningBidAmount: 0,
            resultIpfsHash: "",
            proofOfComputeIpfsHash: ""
            // bids: new mapping(address => uint256), // Implicitly empty
            // bidComputeProofDescriptors: new mapping(address => string) // Implicitly empty
        });

        emit FineTuningJobRequested(jobId, _modelId, _datasetId, msg.sender, _budget, _tokenAddress);
        return jobId;
    }

    // @notice Allows compute providers to submit bids for open training jobs.
    // @param _jobId The ID of the training job.
    // @param _bidAmount The amount the bidder requests for completing the job (must be within budget).
    // @param _computeProofDescriptorIpfsHash IPFS hash describing the compute environment/proof method offered.
    function bidForTrainingJob(
        bytes32 _jobId,
        uint256 _bidAmount,
        string calldata _computeProofDescriptorIpfsHash
    ) external whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.jobId == _jobId, "DAMA: Training job not found");
        require(job.status == TrainingJobStatus.BiddingOpen, "DAMA: Bidding is not open for this job");
        require(msg.sender != job.requestor, "DAMA: Requestor cannot bid on their own job"); // Prevent self-bidding
        require(_bidAmount > 0, "DAMA: Bid amount must be greater than zero");
        require(job.budget >= _bidAmount, "DAMA: Bid amount exceeds job budget");
        require(bytes(_computeProofDescriptorIpfsHash).length > 0, "DAMA: Compute proof descriptor hash cannot be empty");
        require(job.bids[msg.sender] == 0, "DAMA: You have already placed a bid for this job"); // Only one bid per bidder

        job.bids[msg.sender] = _bidAmount;
        job.bidComputeProofDescriptors[msg.sender] = _computeProofDescriptorIpfsHash;

        emit TrainingJobBidSubmitted(_jobId, msg.sender, _bidAmount);
    }

    // @notice The model owner (or governance in a more complex setup) selects a winning bid for a training job.
    // @param _jobId The ID of the training job.
    // @param _bidderAddress The address of the winning bidder.
    function selectWinningBid(bytes32 _jobId, address _bidderAddress) external onlyModelProvider(trainingJobs[_jobId].modelId) whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.jobId == _jobId, "DAMA: Training job not found");
        require(job.status == TrainingJobStatus.BiddingOpen, "DAMA: Bidding is not open or already closed");
        require(job.bids[_bidderAddress] > 0, "DAMA: Bidder has not placed a valid bid");

        job.winnerBidder = _bidderAddress;
        job.winningBidAmount = job.bids[_bidderAddress];
        job.status = TrainingJobStatus.InProgress;

        emit WinningBidSelected(_jobId, _bidderAddress, job.winningBidAmount);
    }

    // @notice The winning bidder submits the results and proof of compute for a completed training job.
    // @param _jobId The ID of the training job.
    // @param _resultIpfsHash IPFS hash of the trained model/fine-tuned weights.
    // @param _proofOfComputeIpfsHash IPFS hash of the verifiable compute proof.
    function submitTrainingJobResult(
        bytes32 _jobId,
        string calldata _resultIpfsHash,
        string calldata _proofOfComputeIpfsHash
    ) external onlyTrainingJobWinner(_jobId) whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.status == TrainingJobStatus.InProgress, "DAMA: Job is not in progress");
        require(bytes(_resultIpfsHash).length > 0, "DAMA: Result IPFS hash cannot be empty");
        require(bytes(_proofOfComputeIpfsHash).length > 0, "DAMA: Proof of compute IPFS hash cannot be empty");

        job.resultIpfsHash = _resultIpfsHash;
        job.proofOfComputeIpfsHash = _proofOfComputeIpfsHash;
        job.status = TrainingJobStatus.ResultSubmitted;

        emit TrainingJobResultSubmitted(_jobId, _resultIpfsHash, _proofOfComputeIpfsHash);
    }

    // @notice Verifies the submitted training result and completes the job, paying the winner.
    // This function typically involves off-chain verification (e.g., by the model owner or governance)
    // and is then called on-chain to finalize. Only callable by the model provider.
    // @param _jobId The ID of the training job.
    function verifyAndCompleteTrainingJob(bytes32 _jobId) external onlyModelProvider(trainingJobs[_jobId].modelId) whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.jobId == _jobId, "DAMA: Training job not found");
        require(job.status == TrainingJobStatus.ResultSubmitted, "DAMA: Training job result not submitted or already completed/failed");

        // Calculate protocol fee
        uint256 totalPayment = job.winningBidAmount;
        uint256 feeAmount = totalPayment.mul(protocolFeePercentageBps).div(10000);
        uint256 amountToWinner = totalPayment.sub(feeAmount);

        // Distribute protocol fees
        if (feeAmount > 0) {
            if (job.budgetToken == address(0)) { // Native token
                payable(protocolFeeRecipient).transfer(feeAmount);
            } else { // ERC20 token
                IERC20(job.budgetToken).transfer(protocolFeeRecipient, feeAmount);
            }
        }

        // Pay the winner
        if (job.budgetToken == address(0)) { // Native token
            payable(job.winnerBidder).transfer(amountToWinner);
        } else { // ERC20 token
            IERC20(job.budgetToken).transfer(job.winnerBidder, amountToWinner);
        }

        // Reward dataset provider
        Dataset storage dataset = datasets[job.datasetId];
        if (dataset.rewardPerUse > 0) {
            dataset.earnedUsageRewards[dataset.provider] = dataset.earnedUsageRewards[dataset.provider].add(dataset.rewardPerUse);
        }

        job.status = TrainingJobStatus.Completed;
        emit TrainingJobCompleted(_jobId, job.winnerBidder, amountToWinner);
    }

    // --- IV. Marketplace Interaction & Payments ---

    // @notice Users purchase credits for off-chain AI model inferences.
    // @param _modelId The ID of the AI model.
    // @param _numInferences The number of inferences to purchase credits for.
    // @param _tokenAddress The ERC20 token address for payment (address(0) for native token).
    function purchaseInferenceCredits(bytes32 _modelId, uint256 _numInferences, address _tokenAddress) external payable whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.modelId == _modelId, "DAMA: Model not found");
        require(model.isActive, "DAMA: Model is not active");
        require(model.paymentToken == _tokenAddress, "DAMA: Incorrect payment token for this model");
        require(_numInferences > 0, "DAMA: Must purchase at least one inference");

        uint256 totalCost = model.pricePerInference.mul(_numInferences);
        require(totalCost > 0, "DAMA: Cost must be greater than zero");

        // Calculate protocol fee
        uint256 feeAmount = totalCost.mul(protocolFeePercentageBps).div(10000);
        uint256 amountToModel = totalCost.sub(feeAmount);

        if (_tokenAddress == address(0)) { // Native token payment
            require(msg.value == totalCost, "DAMA: Native token value must match total cost");
            if (feeAmount > 0) {
                payable(protocolFeeRecipient).transfer(feeAmount);
            }
            // Store model earnings for later claim
            model.earnedInferenceFees[model.provider] = model.earnedInferenceFees[model.provider].add(amountToModel);
        } else { // ERC20 token payment
            // Caller must have approved this contract to spend `totalCost` amount beforehand
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), totalCost);
            if (feeAmount > 0) {
                IERC20(_tokenAddress).transfer(protocolFeeRecipient, feeAmount);
            }
            // Store model earnings for later claim
            model.earnedInferenceFees[model.provider] = model.earnedInferenceFees[model.provider].add(amountToModel);
        }

        model.inferenceCredits[msg.sender] = model.inferenceCredits[msg.sender].add(_numInferences);
        emit InferenceCreditsPurchased(_modelId, msg.sender, _tokenAddress, totalCost, _numInferences);
    }

    // @notice Records the consumption of an inference credit.
    // This function is intended to be called by a trusted off-chain service or a secure relay
    // after an actual inference has been performed, linked to `msg.sender` as the consumer.
    // For a fully decentralized system, a more complex signed message verification by the user
    // would be required if the user calls this directly, but is omitted for brevity in this example.
    // @param _modelId The ID of the AI model.
    function consumeInferenceCredit(bytes32 _modelId) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.modelId == _modelId, "DAMA: Model not found");
        require(model.isActive, "DAMA: Model is not active");
        require(model.inferenceCredits[msg.sender] > 0, "DAMA: No inference credits available for this model");

        model.inferenceCredits[msg.sender] = model.inferenceCredits[msg.sender].sub(1);
        emit InferenceCreditConsumed(_modelId, msg.sender);
    }

    // @notice Allows model providers to claim their share of accumulated inference fees.
    // Currently, only the original provider claims all earnings. Royalty distribution to collaborators
    // (`royaltyShareBps`) serves as an on-chain record for future, more complex distribution mechanisms.
    // @param _modelId The ID of the model.
    // @param _tokenAddress The ERC20 token address of the earnings (address(0) for native token).
    function claimModelInferenceEarnings(bytes32 _modelId, address _tokenAddress) external onlyModelProvider(_modelId) whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.paymentToken == _tokenAddress, "DAMA: Incorrect token address for this model's earnings");

        uint256 amount = model.earnedInferenceFees[msg.sender];
        require(amount > 0, "DAMA: No earnings to claim");

        model.earnedInferenceFees[msg.sender] = 0; // Reset claimed amount

        if (_tokenAddress == address(0)) { // Native token
            payable(msg.sender).transfer(amount);
        } else { // ERC20 token
            IERC20(_tokenAddress).transfer(msg.sender, amount);
        }
        emit ModelEarningsClaimed(_modelId, msg.sender, _tokenAddress, amount);
    }

    // @notice Allows data providers to claim rewards for their datasets being used in training jobs.
    // @param _datasetId The ID of the dataset.
    // @param _tokenAddress The ERC20 token address of the rewards (address(0) for native token).
    function claimDatasetUsageRewards(bytes32 _datasetId, address _tokenAddress) external onlyDatasetProvider(_datasetId) whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.rewardToken == _tokenAddress, "DAMA: Incorrect token address for this dataset's rewards");

        uint256 amount = dataset.earnedUsageRewards[msg.sender];
        require(amount > 0, "DAMA: No rewards to claim");

        dataset.earnedUsageRewards[msg.sender] = 0; // Reset claimed amount

        if (_tokenAddress == address(0)) { // Native token
            payable(msg.sender).transfer(amount);
        } else { // ERC20 token
            IERC20(_tokenAddress).transfer(msg.sender, amount);
        }
        emit DatasetRewardsClaimed(_datasetId, msg.sender, _tokenAddress, amount);
    }

    // --- V. Reputation & Disputes ---

    // @notice Users can submit a rating and an optional review for an AI model.
    // Users can update their rating; only the latest one counts.
    // @param _modelId The ID of the model to rate.
    // @param _rating The rating (1-5).
    // @param _reviewIpfsHash IPFS hash pointing to an off-chain review text/media. Can be empty.
    function submitModelRating(bytes32 _modelId, uint8 _rating, string calldata _reviewIpfsHash) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.modelId == _modelId, "DAMA: Model not found");
        require(_rating >= 1 && _rating <= 5, "DAMA: Rating must be between 1 and 5");
        // Optional: add a requirement that the user must have purchased/consumed inferences for this model.

        if (model.userRatings[msg.sender] == 0) {
            // First time rating by this user
            model.numRatings = model.numRatings.add(1);
        } else {
            // User updating a previous rating
            model.totalRatingSum = model.totalRatingSum.sub(model.userRatings[msg.sender]); // Subtract previous rating
        }

        model.userRatings[msg.sender] = _rating;
        model.userReviewsIpfsHash[msg.sender] = _reviewIpfsHash;
        model.totalRatingSum = model.totalRatingSum.add(_rating);

        emit ModelRatingSubmitted(_modelId, msg.sender, _rating);
    }

    // @notice Users or providers can propose a dispute regarding model quality, data integrity, or training job outcomes.
    // This initiates a governance process.
    // @param _entityId The ID of the entity in dispute (model, dataset, or training job).
    // @param _type The type of dispute.
    // @param _detailsIpfsHash IPFS hash pointing to the detailed dispute reasoning and evidence.
    // @return disputeId The unique ID of the proposed dispute.
    function proposeDispute(bytes32 _entityId, DisputeType _type, string calldata _detailsIpfsHash) external whenNotPaused returns (bytes32 disputeId) {
        require(bytes(_detailsIpfsHash).length > 0, "DAMA: Dispute details IPFS hash cannot be empty");
        // In a full implementation, add `require` statements to verify `_entityId` exists and corresponds to `_type`.

        _disputeIdCounter.increment();
        disputeId = keccak256(abi.encodePacked("Dispute-", _disputeIdCounter.current().toString(), msg.sender, block.timestamp));

        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            proposer: msg.sender,
            entityId: _entityId,
            disputeType: _type,
            detailsIpfsHash: _detailsIpfsHash,
            resolved: false,
            result: false, // Default to false, updated upon resolution
            // hasVoted: new mapping(address => bool), // Implicitly empty
            votesFor: 0,
            votesAgainst: 0
        });

        emit DisputeProposed(disputeId, _entityId, _type, msg.sender);
        return disputeId;
    }

    // @notice Governance participants vote on proposed disputes.
    // For simplicity in this conceptual contract, any address can vote. In a real DAO, this would be
    // restricted to token holders, delegates, or a specific set of recognized governance participants.
    // @param _disputeId The ID of the dispute.
    // @param _isLegitimate True if the voter believes the dispute is legitimate (proposer wins), false otherwise.
    function voteOnDispute(bytes32 _disputeId, bool _isLegitimate) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId == _disputeId, "DAMA: Dispute not found");
        require(!dispute.resolved, "DAMA: Dispute already resolved");
        require(!dispute.hasVoted[msg.sender], "DAMA: Already voted on this dispute");

        dispute.hasVoted[msg.sender] = true;
        if (_isLegitimate) {
            dispute.votesFor = dispute.votesFor.add(1);
        } else {
            dispute.votesAgainst = dispute.votesAgainst.add(1);
        }

        // --- Simplified Dispute Resolution ---
        // In a real system, `resolveDispute` would be a separate function called by a governance entity
        // after a voting period ends and certain thresholds are met.
        // For this example, if votes reach a certain simplified threshold (e.g., first 5 votes determine outcome),
        // or a timer, or a dedicated `resolveDispute` by `owner`/`governance` with more complex logic.
        // Here, we don't have a timed voting period, so `resolveDispute` would need to be called explicitly
        // by the owner, which is okay for a conceptual contract demonstration.
        
        emit DisputeVoted(_disputeId, msg.sender, _isLegitimate);
    }

    // @notice Resolves a dispute based on voting results (simplified for demonstration).
    // This function would ideally be called by a governance multisig or a time-locked mechanism
    // after a voting period ends and sufficient votes are cast.
    // @param _disputeId The ID of the dispute to resolve.
    function resolveDispute(bytes32 _disputeId) external onlyOwner whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId == _disputeId, "DAMA: Dispute not found");
        require(!dispute.resolved, "DAMA: Dispute already resolved");
        require(dispute.votesFor + dispute.votesAgainst > 0, "DAMA: No votes cast yet for this dispute"); // Ensure some votes exist

        if (dispute.votesFor > dispute.votesAgainst) {
            dispute.result = true; // Proposer wins
            // Placeholder for implementing consequences (e.g., slash staked tokens, mark entity as bad)
            // This would be a complex logic branch based on dispute.disputeType and dispute.entityId
        } else {
            dispute.result = false; // Proposer loses
            // No direct consequences usually, just a resolution of the claim
        }

        dispute.resolved = true;
        emit DisputeResolved(_disputeId, dispute.result);
    }

    // --- VI. Query Functions (View/Pure) ---

    // @notice Retrieves all relevant details for a given AI model ID.
    // @param _modelId The ID of the AI model.
    // @return modelDetails A tuple containing the model's details.
    function getAIModelDetails(bytes32 _modelId)
        external
        view
        returns (
            bytes32 modelId,
            address provider,
            string memory name,
            string memory description,
            string memory ipfsHashMetadata,
            string[] memory categories,
            uint256 pricePerInference,
            address paymentToken,
            uint256 royaltyShareBps,
            uint256 stakedAmount,
            bool isActive,
            uint256 averageRating,
            uint256 numRatings
        )
    {
        AIModel storage model = aiModels[_modelId];
        require(model.modelId == _modelId, "DAMA: Model not found");

        uint256 avgRating = 0;
        if (model.numRatings > 0) {
            avgRating = model.totalRatingSum.div(model.numRatings);
        }

        return (
            model.modelId,
            model.provider,
            model.name,
            model.description,
            model.ipfsHashMetadata,
            model.categories,
            model.pricePerInference,
            model.paymentToken,
            model.royaltyShareBps,
            model.stakedAmount,
            model.isActive,
            avgRating,
            model.numRatings
        );
    }

    // @notice Retrieves all relevant details for a given dataset ID.
    // @param _datasetId The ID of the dataset.
    // @return datasetDetails A tuple containing the dataset's details.
    function getDatasetDetails(bytes32 _datasetId)
        external
        view
        returns (
            bytes32 datasetId,
            address provider,
            string memory name,
            string memory description,
            string memory ipfsHashDataset,
            string[] memory targetModelCategories,
            address rewardToken,
            uint256 rewardPerUse,
            uint256 stakedAmount
        )
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.datasetId == _datasetId, "DAMA: Dataset not found");

        return (
            dataset.datasetId,
            dataset.provider,
            dataset.name,
            dataset.description,
            dataset.ipfsHashDataset,
            dataset.targetModelCategories,
            dataset.rewardToken,
            dataset.rewardPerUse,
            dataset.stakedAmount
        );
    }

    // @notice Checks the remaining inference credits a user has for a specific model.
    // @param _user The address of the user.
    // @param _modelId The ID of the AI model.
    // @return remainingCredits The number of remaining inference credits.
    function getUserInferenceCreditBalance(address _user, bytes32 _modelId) external view returns (uint256 remainingCredits) {
        AIModel storage model = aiModels[_modelId];
        require(model.modelId == _modelId, "DAMA: Model not found"); // Basic check if model exists
        return model.inferenceCredits[_user];
    }

    // @notice Retrieves all relevant details for a given training job ID.
    // @param _jobId The ID of the training job.
    // @return jobDetails A tuple containing the training job's details.
    function getTrainingJobDetails(bytes32 _jobId)
        external
        view
        returns (
            bytes32 jobId,
            bytes32 modelId,
            bytes32 datasetId,
            address requestor,
            uint256 budget,
            address budgetToken,
            string memory jobDetailsIpfsHash,
            TrainingJobStatus status,
            address winnerBidder,
            uint256 winningBidAmount,
            string memory resultIpfsHash,
            string memory proofOfComputeIpfsHash
        )
    {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.jobId == _jobId, "DAMA: Training job not found");

        return (
            job.jobId,
            job.modelId,
            job.datasetId,
            job.requestor,
            job.budget,
            job.budgetToken,
            job.jobDetailsIpfsHash,
            job.status,
            job.winnerBidder,
            job.winningBidAmount,
            job.resultIpfsHash,
            job.proofOfComputeIpfsHash
        );
    }
}
```