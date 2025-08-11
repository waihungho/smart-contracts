Here's a Solidity smart contract for a "Decentralized AI Model Co-creation and Inference Protocol (DAICIP)". This contract aims to provide a unique, advanced, and trendy ecosystem for AI models by leveraging blockchain for coordination, ownership, and value distribution, while assuming off-chain computation for the heavy lifting of AI training and inference.

**Core Concepts & Advanced Features:**

1.  **Tokenized AI Models:** Models are represented as unique digital assets (conceptually similar to NFTs, though not a full ERC721 implementation for brevity), allowing for clear ownership and tradability.
2.  **Collaborative Training Incentives:** Data providers are incentivized with a share of model inference fees for their approved dataset contributions.
3.  **Off-chain Computation, On-chain Coordination:** The actual AI training/inference happens off-chain, but key events (training sessions, performance updates, inference requests) are logged and processed on-chain to trigger royalty distribution and model evolution.
4.  **Dynamic Royalty Distribution:** Inference fees are automatically split between the platform, the model owner, and approved data contributors.
5.  **Reputation System (Basic):** Users can endorse contributors, building a simple on-chain reputation that could be expanded for weighted voting or access control.
6.  **DAO-Lite Governance:** A basic proposal and voting mechanism for model improvements allows for decentralized evolution of AI models.
7.  **Dispute Resolution:** A mechanism for reporting and resolving disputes related to training sessions or data quality, handled by the platform owner (or eventually a full DAO).
8.  **Pausable Mechanism:** Standard best practice for emergency shutdowns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DAICIP - Decentralized AI Model Co-creation and Inference Protocol
 * @author BlockchainAI Innovator
 * @notice This contract facilitates a decentralized ecosystem for AI model creation,
 *         collaborative training, and monetization. It allows users to register AI models,
 *         contribute datasets for training, log successful off-chain training sessions,
 *         and pay for model inference. It includes a basic royalty distribution mechanism,
 *         a reputation system, and a light governance framework.
 *
 *         Note: For brevity and to focus on the unique logic, this contract does not
 *         implement a full ERC721 standard. Models are identified by a unique `modelId`
 *         and are conceptually treated as non-fungible assets within this protocol.
 *         Actual AI model computation (training/inference) is assumed to happen off-chain,
 *         with results and actions being recorded and coordinated on-chain.
 *
 * Outline:
 * I. Core Platform Management & Configuration
 * II. AI Model Lifecycle Management
 * III. Data & Training Contribution System
 * IV. Model Inference & Royalty Distribution
 * V. Reputation & Decentralized Governance (DAO-Lite)
 * VI. Dispute Resolution Mechanism
 * VII. Utility & Query Functions
 */
contract DAICIP is Ownable {

    /*
     * Function Summary:
     *
     * I. Core Platform Management & Configuration:
     * - `updatePlatformFee(uint256 _newFeePercentage)`: Allows the platform owner to update the platform's service fee percentage.
     * - `pausePlatform()`: Pauses core platform operations (e.g., model registration, inference requests) in emergencies.
     * - `unpausePlatform()`: Resumes operations after a pause.
     * - `withdrawPlatformFees()`: Enables the platform owner to withdraw accumulated platform fees.
     *
     * II. AI Model Lifecycle Management:
     * - `registerAIModel(string calldata _name, string calldata _description, string calldata _metadataURI, uint256 _initialAccessPrice)`: Registers a new AI model, assigning it a unique ID and setting its initial properties.
     * - `updateModelMetadata(uint256 _modelId, string calldata _newMetadataURI, uint256 _newAccessPrice)`: Allows the model owner to update model details like metadata URI or access price.
     * - `deactivateModel(uint256 _modelId)`: Temporarily disables a model from being used for inference.
     * - `reactivateModel(uint256 _modelId)`: Re-enables a deactivated model.
     * - `setModelAccessPrice(uint256 _modelId, uint256 _newAccessPrice)`: Directly sets or changes the price users pay to use a model.
     *
     * III. Data & Training Contribution System:
     * - `submitDataset(uint256 _modelId, string calldata _dataURI)`: Allows users to submit dataset references for a specific AI model.
     * - `approveDataset(uint256 _datasetId)`: Approves a submitted dataset for use in model training, making it eligible for royalties.
     * - `logTrainingSession(uint256 _modelId, uint256[] calldata _datasetIdsUsed, uint256 _performanceUplift, string calldata _detailsURI)`: Records an off-chain training event, updating the model's performance and linking data contributors.
     * - `updateModelPerformanceMetric(uint256 _modelId, uint256 _newMetric)`: Directly updates a model's performance metric, potentially for initial setup or external validation.
     *
     * IV. Model Inference & Royalty Distribution:
     * - `requestInference(uint256 _modelId)`: Users pay to use a model, triggering the distribution of fees to the model owner, data contributors, and the platform.
     * - `claimInferenceRoyalty()`: Allows model owners and data contributors to withdraw their accumulated royalty earnings.
     * - `getPendingRoyalties(address _user)`: Queries the amount of royalties pending for a specific user.
     *
     * V. Reputation & Decentralized Governance (DAO-Lite):
     * - `endorseModelContributor(address _endorsedUser, uint256 _reputationGain)`: Allows users to grant reputation points to other contributors.
     * - `submitModelImprovementProposal(uint256 _modelId, string calldata _description, string calldata _proposalURI)`: Users with sufficient reputation can propose improvements or changes for a model.
     * - `voteOnProposal(uint256 _proposalId, bool _voteFor)`: Allows users to cast their vote on active proposals.
     *
     * VI. Dispute Resolution Mechanism:
     * - `disputeTrainingSession(uint256 _sessionId, string calldata _reason)`: Users can open a dispute against a logged training session.
     * - `resolveDispute(uint256 _disputeId, DisputeStatus _resolvedStatus)`: The platform owner resolves an open dispute.
     *
     * VII. Utility & Query Functions:
     * - `getModelDetails(uint256 _modelId)`: Retrieves comprehensive details about a specific AI model.
     * - `getUserModels(address _user)`: Returns a list of all model IDs owned by a given address.
     * - `getUserContributionDetails(address _user)`: Returns the reputation score of a user.
     * - `getLatestModelVersion(uint256 _modelId)`: Returns the current performance metric of a model (representing its "version").
     * - `getDatasetDetails(uint256 _datasetId)`: Retrieves all details of a specific dataset.
     * - `getTrainingSessionDetails(uint256 _sessionId)`: Retrieves all details of a specific training session.
     * - `getProposalDetails(uint256 _proposalId)`: Retrieves all details of a specific model improvement proposal.
     */

    // --- Custom Errors ---
    error PlatformPaused();
    error PlatformNotPaused();
    error InvalidFeePercentage();
    error ModelNotFound(uint256 modelId);
    error ModelNotOwned(uint256 modelId, address caller);
    error ModelInactive(uint256 modelId);
    error ModelActive(uint256 modelId);
    error InsufficientFundsPaid();
    error DatasetNotFound(uint256 datasetId);
    error DatasetAlreadyApproved(uint256 datasetId);
    error DatasetNotApproved(uint256 datasetId);
    error DatasetModelMismatch(uint256 datasetId, uint256 expectedModelId);
    error TrainingSessionNotFound(uint256 sessionId);
    error ProposalNotFound(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address voter);
    error NotEnoughReputation(uint256 required, uint256 current);
    error NotEnoughFundsToClaim(address claimant);
    error DisputeNotFound(uint256 disputeId);
    error DisputeAlreadyResolved(uint256 disputeId);
    error UnauthorizedAction(string reason);
    error InvalidInput();


    // --- State Variables ---
    uint256 private _nextModelId;
    uint256 private _nextDatasetId;
    uint256 private _nextTrainingSessionId;
    uint256 private _nextProposalId;
    uint256 private _nextDisputeId;

    uint256 public platformFeePercentage; // e.g., 500 for 5% (scaled by 10000)
    bool public paused;
    uint256 public platformFeeBalance; // Explicitly track platform's collected fees

    // Fixed royalty split percentages (scaled by 10000)
    uint256 public constant MODEL_OWNER_ROYALTY_PERCENTAGE = 7000; // 70% of distributable
    uint256 public constant DATA_CONTRIBUTOR_ROYALTY_PERCENTAGE = 3000; // 30% of distributable

    // Minimum reputation required to submit proposals
    uint256 public MIN_REPUTATION_FOR_PROPOSAL = 100; // Arbitrary reputation score

    // --- Structs ---
    struct AIModel {
        address owner;
        string name;
        string description;
        string metadataURI; // IPFS hash or similar for more detailed off-chain info (e.g., model card)
        uint256 accessPrice; // Price to use the model for inference (in Wei)
        uint256 performanceMetric; // A simplified metric, e.g., accuracy score (scaled by 10000 to allow decimals)
        uint256 lastTrainingSessionId; // ID of the last logged training session that improved this model
        bool isActive;
        uint256 cumulativeRevenue; // Total revenue generated by this model (including platform fees)
    }

    struct Dataset {
        address contributor;
        uint256 modelId; // Model this dataset is intended for
        string dataURI; // IPFS hash or similar for the dataset (or a description)
        bool isApproved; // Approved by model owner or governance for training
        uint256 approvalTimestamp; // When the dataset was approved
    }

    struct TrainingSession {
        uint256 modelId;
        address trainer; // Address that conducted/logged the training
        uint256[] datasetIdsUsed; // IDs of approved datasets used in this session
        uint256 performanceUplift; // How much the performance metric improved (scaled by 10000)
        uint256 timestamp;
        string detailsURI; // URI to off-chain training logs/proofs
    }

    enum ProposalStatus { Pending, Approved, Rejected }

    struct ModelImprovementProposal {
        uint256 modelId;
        address proposer;
        string description;
        string proposalURI; // Link to detailed proposal off-chain
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks who has voted for a specific proposal
    }

    enum DisputeStatus { Open, ResolvedValid, ResolvedInvalid } // ResolvedValid: dispute was invalid, ResolvedInvalid: dispute was valid

    struct Dispute {
        uint256 targetSessionId; // The training session being disputed
        address disputer;
        string reason;
        DisputeStatus status;
        address resolver; // Who resolved it (admin)
        uint256 resolutionTimestamp;
    }

    // --- Mappings ---
    mapping(uint256 => AIModel) public models; // modelId => AIModel struct
    mapping(address => uint256[]) public userModels; // ownerAddress => array of model IDs owned
    mapping(uint256 => uint256[]) public modelDatasets; // modelId => array of dataset IDs submitted for it

    mapping(uint256 => Dataset) public datasets; // datasetId => Dataset struct
    mapping(uint256 => TrainingSession) public trainingSessions; // sessionId => TrainingSession struct

    mapping(address => uint256) public contributorReputation; // contributorAddress => reputation score
    mapping(address => uint256) public pendingRoyalties; // userAddress => Ether pending to claim

    mapping(uint256 => ModelImprovementProposal) public proposals; // proposalId => ModelImprovementProposal struct
    mapping(uint256 => uint256) public proposalModelIds; // Convenience mapping: proposalId => modelId

    mapping(uint256 => Dispute) public disputes; // disputeId => Dispute struct

    // --- Events ---
    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 accessPrice);
    event ModelUpdated(uint256 indexed modelId, string newMetadataURI, uint256 newAccessPrice);
    event ModelDeactivated(uint256 indexed modelId);
    event ModelReactivated(uint256 indexed modelId);
    event ModelPerformanceUpdated(uint256 indexed modelId, uint256 newMetric, uint256 sessionId);

    event DatasetSubmitted(uint256 indexed datasetId, uint256 indexed modelId, address indexed contributor, string dataURI);
    event DatasetApproved(uint256 indexed datasetId, uint256 indexed modelId, address indexed approver);

    event TrainingSessionLogged(uint256 indexed sessionId, uint256 indexed modelId, address indexed trainer, uint256 performanceUplift);

    event InferenceRequested(uint256 indexed modelId, address indexed user, uint256 amountPaid);
    event RoyaltyClaimed(address indexed beneficiary, uint256 amount);

    event ContributorEndorsed(address indexed endorser, address indexed endorsed, uint256 reputationGain);

    event ProposalSubmitted(uint256 indexed proposalId, uint256 indexed modelId, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool decision); // True for For, False for Against
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);

    event DisputeOpened(uint256 indexed disputeId, uint256 indexed targetSessionId, address indexed disputer);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus newStatus, address indexed resolver);

    // --- Constructor ---
    constructor(uint256 _platformFeePercentage) Ownable(msg.sender) {
        if (_platformFeePercentage > 10000) revert InvalidFeePercentage(); // Max 100% (10000/10000 = 100%)
        platformFeePercentage = _platformFeePercentage;
        paused = false;
        _nextModelId = 1; // Start IDs from 1
        _nextDatasetId = 1;
        _nextTrainingSessionId = 1;
        _nextProposalId = 1;
        _nextDisputeId = 1;
        platformFeeBalance = 0; // Initialize platform's collected fees
    }

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert PlatformPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert PlatformNotPaused();
        _;
    }

    modifier modelExists(uint256 _modelId) {
        if (models[_modelId].owner == address(0)) revert ModelNotFound(_modelId);
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        if (models[_modelId].owner != msg.sender) revert ModelNotOwned(_modelId, msg.sender);
        _;
    }

    modifier datasetExists(uint256 _datasetId) {
        if (datasets[_datasetId].contributor == address(0)) revert DatasetNotFound(_datasetId);
        _;
    }

    modifier trainingSessionExists(uint256 _sessionId) {
        if (trainingSessions[_sessionId].modelId == 0) revert TrainingSessionNotFound(_sessionId);
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        if (proposals[_proposalId].proposer == address(0)) revert ProposalNotFound(_proposalId);
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        if (disputes[_disputeId].disputer == address(0)) revert DisputeNotFound(_disputeId);
        _;
    }

    // ====================================================================
    // I. Core Platform Management & Configuration (4 functions)
    // ====================================================================

    /**
     * @notice Allows the platform owner to update the platform fee percentage.
     * @param _newFeePercentage The new fee percentage (scaled by 10000, e.g., 500 for 5%).
     */
    function updatePlatformFee(uint256 _newFeePercentage) external onlyOwner {
        if (_newFeePercentage > 10000) revert InvalidFeePercentage(); // Max 100%
        platformFeePercentage = _newFeePercentage;
    }

    /**
     * @notice Pauses platform operations (e.g., model registration, inference requests).
     *         Only callable by the platform owner.
     */
    function pausePlatform() external onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @notice Unpauses platform operations. Only callable by the platform owner.
     */
    function unpausePlatform() external onlyOwner whenPaused {
        paused = false;
    }

    /**
     * @notice Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = platformFeeBalance;
        if (amount == 0) revert InsufficientFundsPaid();
        platformFeeBalance = 0; // Reset balance before transfer
        payable(owner()).transfer(amount);
    }

    // ====================================================================
    // II. AI Model Lifecycle Management (5 functions)
    // ====================================================================

    /**
     * @notice Registers a new AI model on the platform. Mints a unique model ID.
     * @param _name The name of the AI model.
     * @param _description A brief description of the model.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS hash of model card).
     * @param _initialAccessPrice The initial price to use the model for inference (in Wei).
     * @dev The model creator (msg.sender) becomes the owner.
     * @return The unique ID of the newly registered model.
     */
    function registerAIModel(
        string calldata _name,
        string calldata _description,
        string calldata _metadataURI,
        uint256 _initialAccessPrice
    ) external whenNotPaused returns (uint256) {
        if (bytes(_name).length == 0 || bytes(_description).length == 0 || bytes(_metadataURI).length == 0) revert InvalidInput();

        uint256 modelId = _nextModelId++;
        models[modelId] = AIModel({
            owner: msg.sender,
            name: _name,
            description: _description,
            metadataURI: _metadataURI,
            accessPrice: _initialAccessPrice,
            performanceMetric: 0, // Initial performance
            lastTrainingSessionId: 0,
            isActive: true,
            cumulativeRevenue: 0
        });
        userModels[msg.sender].push(modelId);
        emit ModelRegistered(modelId, msg.sender, _name, _initialAccessPrice);
        return modelId;
    }

    /**
     * @notice Updates the metadata URI and/or access price of an existing model.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new URI for metadata (empty string to keep current).
     * @param _newAccessPrice The new access price (0 to keep current).
     */
    function updateModelMetadata(
        uint256 _modelId,
        string calldata _newMetadataURI,
        uint256 _newAccessPrice
    ) external modelExists(_modelId) onlyModelOwner(_modelId) whenNotPaused {
        AIModel storage model = models[_modelId];
        if (bytes(_newMetadataURI).length > 0) { // Only update if a new URI is provided
            model.metadataURI = _newMetadataURI;
        }
        if (_newAccessPrice > 0) { // Only update if a new price is provided
            model.accessPrice = _newAccessPrice;
        }
        // If neither is provided, the function effectively does nothing but consume gas
        if (bytes(_newMetadataURI).length == 0 && _newAccessPrice == 0) revert InvalidInput();
        emit ModelUpdated(_modelId, model.metadataURI, model.accessPrice);
    }

    /**
     * @notice Deactivates a model, preventing further inference requests.
     * @param _modelId The ID of the model to deactivate.
     */
    function deactivateModel(uint256 _modelId) external modelExists(_modelId) onlyModelOwner(_modelId) {
        AIModel storage model = models[_modelId];
        if (!model.isActive) revert ModelInactive(_modelId);
        model.isActive = false;
        emit ModelDeactivated(_modelId);
    }

    /**
     * @notice Reactivates a previously deactivated model.
     * @param _modelId The ID of the model to reactivate.
     */
    function reactivateModel(uint256 _modelId) external modelExists(_modelId) onlyModelOwner(_modelId) {
        AIModel storage model = models[_modelId];
        if (model.isActive) revert ModelActive(_modelId);
        model.isActive = true;
        emit ModelReactivated(_modelId);
    }

    /**
     * @notice Sets the access price for a specific model.
     * @param _modelId The ID of the model.
     * @param _newAccessPrice The new price in Wei.
     */
    function setModelAccessPrice(uint256 _modelId, uint256 _newAccessPrice)
        external
        modelExists(_modelId)
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        models[_modelId].accessPrice = _newAccessPrice;
        emit ModelUpdated(_modelId, models[_modelId].metadataURI, _newAccessPrice);
    }

    // ====================================================================
    // III. Data & Training Contribution System (4 functions)
    // ====================================================================

    /**
     * @notice Allows users to submit datasets intended for a specific model.
     *         The dataset is not automatically approved for training.
     * @param _modelId The ID of the model this dataset is for.
     * @param _dataURI URI pointing to the dataset (e.g., IPFS hash of data file/description).
     * @return The unique ID of the submitted dataset.
     */
    function submitDataset(
        uint256 _modelId,
        string calldata _dataURI
    ) external modelExists(_modelId) whenNotPaused returns (uint256) {
        if (bytes(_dataURI).length == 0) revert InvalidInput();

        uint256 datasetId = _nextDatasetId++;
        datasets[datasetId] = Dataset({
            contributor: msg.sender,
            modelId: _modelId,
            dataURI: _dataURI,
            isApproved: false,
            approvalTimestamp: 0
        });
        modelDatasets[_modelId].push(datasetId);
        emit DatasetSubmitted(datasetId, _modelId, msg.sender, _dataURI);
        return datasetId;
    }

    /**
     * @notice Approves a submitted dataset for use in training a model.
     *         Can be called by the model owner or the platform owner.
     * @param _datasetId The ID of the dataset to approve.
     */
    function approveDataset(uint256 _datasetId) external datasetExists(_datasetId) {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.isApproved) revert DatasetAlreadyApproved(_datasetId);
        if (models[dataset.modelId].owner != msg.sender && owner() != msg.sender) {
            revert UnauthorizedAction("Only model owner or platform owner can approve dataset.");
        }

        dataset.isApproved = true;
        dataset.approvalTimestamp = block.timestamp;
        emit DatasetApproved(_datasetId, dataset.modelId, msg.sender);
    }

    /**
     * @notice Logs an off-chain training session for a model.
     *         This function simulates the on-chain recording of off-chain training results.
     *         It updates the model's performance metric and contributes to data contributor rewards.
     * @param _modelId The ID of the model that was trained.
     * @param _datasetIdsUsed An array of IDs of approved datasets used in this session.
     * @param _performanceUplift The improvement in the model's performance metric (scaled by 10000).
     *                           This value is added to the model's current performance.
     * @param _detailsURI URI to off-chain training logs or proof of computation.
     * @dev Only the model owner can log training for their model.
     * @return The unique ID of the logged training session.
     */
    function logTrainingSession(
        uint256 _modelId,
        uint256[] calldata _datasetIdsUsed,
        uint256 _performanceUplift,
        string calldata _detailsURI
    ) external modelExists(_modelId) onlyModelOwner(_modelId) whenNotPaused returns (uint256) {
        if (_performanceUplift == 0 || bytes(_detailsURI).length == 0) revert InvalidInput();

        // Validate all dataset IDs are for this model and are approved
        for (uint256 i = 0; i < _datasetIdsUsed.length; i++) {
            uint256 currentDatasetId = _datasetIdsUsed[i];
            Dataset storage dataset = datasets[currentDatasetId];
            if (dataset.contributor == address(0) || dataset.modelId != _modelId) {
                revert DatasetModelMismatch(currentDatasetId, _modelId);
            }
            if (!dataset.isApproved) {
                revert DatasetNotApproved(currentDatasetId);
            }
        }

        uint256 sessionId = _nextTrainingSessionId++;
        trainingSessions[sessionId] = TrainingSession({
            modelId: _modelId,
            trainer: msg.sender,
            datasetIdsUsed: _datasetIdsUsed,
            performanceUplift: _performanceUplift,
            timestamp: block.timestamp,
            detailsURI: _detailsURI
        });

        // Update model performance and last training session
        AIModel storage model = models[_modelId];
        model.performanceMetric += _performanceUplift;
        model.lastTrainingSessionId = sessionId;

        emit TrainingSessionLogged(sessionId, _modelId, msg.sender, _performanceUplift);
        emit ModelPerformanceUpdated(_modelId, model.performanceMetric, sessionId);
        return sessionId;
    }

    /**
     * @notice Updates a model's performance metric directly. This could be used for initial setup
     *         or in cases where performance is measured externally without a specific training session log.
     *         Less preferred than `logTrainingSession` for ongoing improvements.
     * @param _modelId The ID of the model.
     * @param _newMetric The new total performance metric (scaled by 10000).
     * @dev Only the model owner can update this.
     */
    function updateModelPerformanceMetric(uint256 _modelId, uint256 _newMetric)
        external
        modelExists(_modelId)
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        models[_modelId].performanceMetric = _newMetric;
        emit ModelPerformanceUpdated(_modelId, _newMetric, 0); // Session ID 0 indicates direct update
    }

    // ====================================================================
    // IV. Model Inference & Royalty Distribution (3 functions)
    // ====================================================================

    /**
     * @notice Allows a user to request an inference from a model by paying its access price.
     *         Distributes royalties to the model owner and data contributors.
     * @param _modelId The ID of the model to use for inference.
     */
    function requestInference(uint256 _modelId) external payable modelExists(_modelId) whenNotPaused {
        AIModel storage model = models[_modelId];
        if (!model.isActive) revert ModelInactive(_modelId);
        if (msg.value < model.accessPrice) revert InsufficientFundsPaid();

        uint256 totalPayment = model.accessPrice; // Only use the exact access price for distribution
        uint256 platformShare = (totalPayment * platformFeePercentage) / 10000;
        uint256 distributableAmount = totalPayment - platformShare;

        platformFeeBalance += platformShare;

        // Distribute to model owner
        uint256 modelOwnerShare = (distributableAmount * MODEL_OWNER_ROYALTY_PERCENTAGE) / 10000;
        pendingRoyalties[model.owner] += modelOwnerShare;

        // Collect all unique approved data contributors for the model
        address[] memory uniqueApprovedContributors;
        // Temporary mapping to track seen contributors within this function call
        // This is necessary because state variables (like mappings) cannot be directly assigned to memory mappings.
        // And we need to ensure each unique contributor gets a share, not per dataset.
        mapping(address => bool) private _seenContributorMap;

        // Populate uniqueApprovedContributors and _seenContributorMap
        for (uint256 i = 0; i < modelDatasets[_modelId].length; i++) {
            uint256 datasetId = modelDatasets[_modelId][i];
            // Ensure dataset exists and is approved
            if (datasets[datasetId].contributor != address(0) && datasets[datasetId].isApproved) {
                address contributorAddress = datasets[datasetId].contributor;
                if (!_seenContributorMap[contributorAddress]) {
                    _seenContributorMap[contributorAddress] = true;
                    uniqueApprovedContributors.push(contributorAddress);
                }
            }
        }

        if (uniqueApprovedContributors.length > 0) {
            uint256 dataContributorShare = (distributableAmount * DATA_CONTRIBUTOR_ROYALTY_PERCENTAGE) / 10000;
            // Distribute equally among unique approved data contributors
            uint256 sharePerContributor = dataContributorShare / uniqueApprovedContributors.length;
            for (uint256 i = 0; i < uniqueApprovedContributors.length; i++) {
                pendingRoyalties[uniqueApprovedContributors[i]] += sharePerContributor;
            }
        }

        model.cumulativeRevenue += totalPayment;

        // Refund any excess payment
        if (msg.value > model.accessPrice) {
            payable(msg.sender).transfer(msg.value - model.accessPrice);
        }

        emit InferenceRequested(_modelId, msg.sender, model.accessPrice);
    }

    /**
     * @notice Allows a user to claim their accumulated royalties.
     */
    function claimInferenceRoyalty() external {
        uint256 amount = pendingRoyalties[msg.sender];
        if (amount == 0) revert NotEnoughFundsToClaim(msg.sender);

        pendingRoyalties[msg.sender] = 0; // Reset balance before transfer to prevent re-entrancy
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // Revert the state change if transfer fails to prevent loss of funds
            pendingRoyalties[msg.sender] = amount;
            revert UnauthorizedAction("Royalty transfer failed.");
        }
        emit RoyaltyClaimed(msg.sender, amount);
    }

    /**
     * @notice Gets the amount of pending royalties for a specific user.
     * @param _user The address of the user.
     * @return The amount of pending royalties in Wei.
     */
    function getPendingRoyalties(address _user) external view returns (uint256) {
        return pendingRoyalties[_user];
    }

    // ====================================================================
    // V. Reputation & Decentralized Governance (DAO-Lite) (3 functions)
    // ====================================================================

    /**
     * @notice Allows a user to endorse another contributor, increasing their reputation.
     *         This is a basic reputation system where endorsements add a fixed amount.
     * @param _endorsedUser The address of the user to endorse.
     * @param _reputationGain The amount of reputation to grant.
     * @dev To prevent spam, advanced implementations would add cooldowns, proof-of-contribution checks,
     *      or weight endorsements by the endorser's own reputation.
     */
    function endorseModelContributor(address _endorsedUser, uint256 _reputationGain) external {
        if (_endorsedUser == address(0) || _endorsedUser == msg.sender) revert InvalidInput();
        if (_reputationGain == 0) revert InvalidInput();

        contributorReputation[_endorsedUser] += _reputationGain;
        emit ContributorEndorsed(msg.sender, _endorsedUser, _reputationGain);
    }

    /**
     * @notice Allows a user with sufficient reputation to submit a proposal for a model improvement.
     * @param _modelId The ID of the model the proposal is for.
     * @param _description A brief description of the proposal.
     * @param _proposalURI URI pointing to detailed proposal information (e.g., IPFS link to governance doc).
     * @return The unique ID of the submitted proposal.
     */
    function submitModelImprovementProposal(
        uint256 _modelId,
        string calldata _description,
        string calldata _proposalURI
    ) external modelExists(_modelId) whenNotPaused returns (uint256) {
        if (contributorReputation[msg.sender] < MIN_REPUTATION_FOR_PROPOSAL) {
            revert NotEnoughReputation(MIN_REPUTATION_FOR_PROPOSAL, contributorReputation[msg.sender]);
        }
        if (bytes(_description).length == 0 || bytes(_proposalURI).length == 0) revert InvalidInput();

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = ModelImprovementProposal({
            modelId: _modelId,
            proposer: msg.sender,
            description: _description,
            proposalURI: _proposalURI,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending
            // hasVoted mapping is initialized with default values when the struct is created
        });
        proposalModelIds[proposalId] = _modelId; // Store mapping for easy lookup

        emit ProposalSubmitted(proposalId, _modelId, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows a user to vote on an open model improvement proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteFor True if voting 'for', false if voting 'against'.
     * @dev For simplicity, this is a direct vote. A more robust DAO would include voting periods,
     *      quorum requirements, and potentially weighted votes based on stake or reputation.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteFor)
        external
        proposalExists(_proposalId)
        whenNotPaused
    {
        ModelImprovementProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Pending) revert UnauthorizedAction("Proposal not pending.");
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);

        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        // Simplified logic for proposal status change:
        // A proposal passes if 'votesFor' is at least double 'votesAgainst' AND total votes >= 5.
        // A proposal fails if 'votesAgainst' is at least 'votesFor' AND total votes >= 5.
        // This is purely illustrative.
        if (proposal.votesFor >= proposal.votesAgainst * 2 && (proposal.votesFor + proposal.votesAgainst) >= 5) {
             proposal.status = ProposalStatus.Approved;
             emit ProposalStatusChanged(_proposalId, ProposalStatus.Approved);
        } else if (proposal.votesAgainst >= proposal.votesFor && (proposal.votesFor + proposal.votesAgainst) >= 5) {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Rejected);
        }

        emit VoteCast(_proposalId, msg.sender, _voteFor);
    }

    // ====================================================================
    // VI. Dispute Resolution Mechanism (2 functions)
    // ====================================================================

    /**
     * @notice Allows a user to open a dispute against a logged training session.
     *         Could be for fraudulent performance claims, misuse of data, etc.
     * @param _sessionId The ID of the training session being disputed.
     * @param _reason A string describing the reason for the dispute.
     * @return The unique ID of the opened dispute.
     */
    function disputeTrainingSession(uint256 _sessionId, string calldata _reason)
        external
        trainingSessionExists(_sessionId)
        whenNotPaused
        returns (uint256)
    {
        if (bytes(_reason).length == 0) revert InvalidInput();

        uint256 disputeId = _nextDisputeId++;
        disputes[disputeId] = Dispute({
            targetSessionId: _sessionId,
            disputer: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            resolver: address(0), // No resolver yet
            resolutionTimestamp: 0
        });
        emit DisputeOpened(disputeId, _sessionId, msg.sender);
        return disputeId;
    }

    /**
     * @notice Resolves an open dispute. Only callable by the platform owner.
     *         Resolution could involve rolling back performance metrics or reallocating rewards
     *         (these advanced actions are commented out for brevity but are conceptual extensions).
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolvedStatus The new status (e.g., DisputeStatus.ResolvedValid or DisputeStatus.ResolvedInvalid).
     */
    function resolveDispute(uint256 _disputeId, DisputeStatus _resolvedStatus)
        external
        onlyOwner
        disputeExists(_disputeId)
    {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.status != DisputeStatus.Open) revert DisputeAlreadyResolved(_disputeId);
        if (_resolvedStatus == DisputeStatus.Open) revert InvalidInput(); // Cannot resolve to Open

        dispute.status = _resolvedStatus;
        dispute.resolver = msg.sender;
        dispute.resolutionTimestamp = block.timestamp;

        // Potential actions based on resolution (example, not fully implemented):
        // if (_resolvedStatus == DisputeStatus.ResolvedInvalid) {
        //     // If the dispute is valid (i.e., the training session was fraudulent/invalid):
        //     // You might want to:
        //     // 1. Revert the performance uplift from the disputed session:
        //     //    TrainingSession storage session = trainingSessions[dispute.targetSessionId];
        //     //    models[session.modelId].performanceMetric -= session.performanceUplift;
        //     // 2. Potentially penalize the `trainer` by reducing their reputation.
        //     // 3. Re-evaluate or redistribute royalties from inferences made based on that invalid session.
        //     // These actions require more complex state management and history tracking.
        // }

        emit DisputeResolved(_disputeId, _resolvedStatus, msg.sender);
    }

    // ====================================================================
    // VII. Utility & Query Functions (7 functions)
    // ====================================================================

    /**
     * @notice Retrieves all details of a specific AI model.
     * @param _modelId The ID of the model.
     * @return A tuple containing all model properties.
     */
    function getModelDetails(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (address owner, string memory name, string memory description, string memory metadataURI, uint256 accessPrice, uint256 performanceMetric, uint256 lastTrainingSessionId, bool isActive, uint256 cumulativeRevenue)
    {
        AIModel storage model = models[_modelId];
        return (model.owner, model.name, model.description, model.metadataURI, model.accessPrice, model.performanceMetric, model.lastTrainingSessionId, model.isActive, model.cumulativeRevenue);
    }

    /**
     * @notice Retrieves the IDs of all models owned by a specific user.
     * @param _user The address of the user.
     * @return An array of model IDs.
     */
    function getUserModels(address _user) external view returns (uint256[] memory) {
        return userModels[_user];
    }

    /**
     * @notice Retrieves details about a user's contributions (reputation).
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserContributionDetails(address _user) external view returns (uint256 reputationScore) {
        return contributorReputation[_user];
    }

    /**
     * @notice Returns the current performance metric for a given model.
     * @param _modelId The ID of the model.
     * @return The performance metric of the model.
     */
    function getLatestModelVersion(uint256 _modelId) external view modelExists(_modelId) returns (uint256) {
        return models[_modelId].performanceMetric;
    }

    /**
     * @notice Retrieves all details of a specific dataset.
     * @param _datasetId The ID of the dataset.
     * @return A tuple containing all dataset properties.
     */
    function getDatasetDetails(uint256 _datasetId)
        external
        view
        datasetExists(_datasetId)
        returns (address contributor, uint256 modelId, string memory dataURI, bool isApproved, uint256 approvalTimestamp)
    {
        Dataset storage dataset = datasets[_datasetId];
        return (dataset.contributor, dataset.modelId, dataset.dataURI, dataset.isApproved, dataset.approvalTimestamp);
    }

    /**
     * @notice Retrieves all details of a specific training session.
     * @param _sessionId The ID of the training session.
     * @return A tuple containing all training session properties.
     */
    function getTrainingSessionDetails(uint256 _sessionId)
        external
        view
        trainingSessionExists(_sessionId)
        returns (uint256 modelId, address trainer, uint256[] memory datasetIdsUsed, uint256 performanceUplift, uint256 timestamp, string memory detailsURI)
    {
        TrainingSession storage session = trainingSessions[_sessionId];
        return (session.modelId, session.trainer, session.datasetIdsUsed, session.performanceUplift, session.timestamp, session.detailsURI);
    }

    /**
     * @notice Retrieves all details of a specific model improvement proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal properties.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        proposalExists(_proposalId)
        returns (uint256 modelId, address proposer, string memory description, string memory proposalURI, uint256 votesFor, uint256 votesAgainst, ProposalStatus status)
    {
        ModelImprovementProposal storage proposal = proposals[_proposalId];
        return (proposal.modelId, proposal.proposer, proposal.description, proposal.proposalURI, proposal.votesFor, proposal.votesAgainst, proposal.status);
    }
}
```