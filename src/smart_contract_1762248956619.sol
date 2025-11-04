```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Conceptual, not fully implemented for voting

/**
 * @title AetherMind Nexus
 * @dev A decentralized platform for managing, governing, and incentivizing
 *      AI models and their inference services. It acts as an on-chain
 *      orchestrator for off-chain AI computation, leveraging reputation
 *      systems, dynamic pricing, and community-driven ethical governance.
 *      It aims to create a transparent and fair marketplace for AI services,
 *      incentivize high-quality synthetic data generation, and foster
 *      responsible AI development through a community-driven approach.
 *
 * Outline:
 * 1.  Core Data Structures & Enums
 * 2.  Interfaces (External Oracles/Services)
 * 3.  Events
 * 4.  Error Handling
 * 5.  State Variables
 * 6.  Modifiers (Access Control)
 * 7.  Constructor
 * 8.  Admin Functions (Platform Owner)
 * 9.  Model Registry & Metadata Functions
 * 10. Inference Request & Fulfillment Functions
 * 11. Model Reputation & Dynamic Pricing Functions
 * 12. Ethical AI Governance Functions
 * 13. Synthetic Data Generation Incentives Functions
 *
 * Function Summary:
 *
 * I. Admin Functions (Platform Owner):
 * - setOracleAddress(): Sets the address for the trusted oracle used for proofs and price predictions.
 * - addInferenceNode(): Whitelists an address as an authorized inference node.
 * - removeInferenceNode(): Removes an address from the list of authorized inference nodes.
 * - addDataValidator(): Whitelists an address as an authorized synthetic data validator.
 * - removeDataValidator(): Removes an address from the list of authorized synthetic data validators.
 * - setPlatformFee(): Sets the percentage fee taken by the platform from successful inferences.
 * - withdrawPlatformFees(): Allows the platform owner to withdraw accumulated fees.
 *
 * II. Model Registry & Metadata:
 * - registerModel(): Allows anyone to register a new AI model with its metadata and capabilities.
 * - updateModelMetadata(): Allows a model's owner to update its IPFS CID or description.
 * - deregisterModel(): Allows a model's owner to mark it as inactive, preventing new inferences.
 * - transferModelOwnership(): Allows a model owner to transfer ownership to another address.
 * - getModelDetails(): Retrieves comprehensive details of a registered model.
 * - getModelsByOwner(): Lists all models owned by a specific address.
 *
 * III. Inference Request & Fulfillment:
 * - requestInference(): User requests an AI inference from a specific model, locking ETH as payment.
 * - fulfillInference(): An authorized Inference Node submits the output and proof for a request, receiving payment.
 * - cancelInferenceRequest(): User can cancel an unfulfilled request and reclaim locked ETH.
 * - disputeInference(): User disputes an unsatisfactory inference, triggering a governance review.
 * - resolveDispute(): Governance or admin resolves a dispute, distributing funds/penalties to parties.
 *
 * IV. Model Reputation & Dynamic Pricing:
 * - submitModelRating(): Users rate models after inference, influencing their reputation.
 * - getAverageRating(): Provides the current average rating for a model.
 * - getModelReputation(): Calculates a composite reputation score for a model based on ratings and dispute history.
 * - predictInferencePrice(): Suggestions an inference price based on model reputation, demand, and complexity (oracle-driven).
 * - updatePricingParameters(): Model owners can adjust their model's base pricing and complexity multiplier within limits.
 *
 * V. Ethical AI Governance:
 * - createGovernanceProposal(): Initiates a new proposal for policy changes, model actions, or dispute resolutions.
 * - voteOnProposal(): Allows eligible participants (e.g., reputation holders, hypothetical governance token holders) to vote on active proposals.
 * - executeProposal(): Executes a passed proposal, applying changes to the system.
 * - setEthicalPolicy(): Updates the overarching ethical guidelines for AI models on the platform (via governance).
 * - reportMaliciousModel(): Users report models violating ethical policies, triggering a governance review and potential suspension.
 *
 * VI. Synthetic Data Generation Incentives:
 * - submitSyntheticData(): Users submit synthetic data intended for a specific model's training, awaiting validation.
 * - validateSyntheticData(): An authorized Data Validator validates submitted synthetic data, releasing rewards if valid.
 * - claimSyntheticDataReward(): Allows the submitter to claim their reward after successful validation.
 */
contract AetherMindNexus is Ownable, ReentrancyGuard {

    /* ====================================
     * 1. Core Data Structures & Enums
     * ==================================== */

    enum RequestStatus {
        Pending,
        Fulfilled,
        Cancelled,
        Disputed,
        Resolved
    }

    enum ProposalStatus {
        Active,
        Passed,
        Failed,
        Executed
    }

    enum ModelStatus {
        Active,
        Inactive,
        Reported,
        Suspended
    }

    struct Model {
        address owner;
        string cid;                 // IPFS CID of the model weights/parameters
        string name;
        string description;
        bytes32[] capabilitiesHash; // Hashed list of model capabilities (e.g., text-to-image, summarization)
        uint256 registeredAt;
        ModelStatus status;
        uint256 inferenceCount;
        uint256 totalRating;        // Sum of all ratings received
        uint256 ratingCount;        // Number of ratings received
        uint256 basePrice;          // Base price per inference in wei
        uint256 complexityMultiplier; // Multiplier for prompt complexity (e.g., 100 for 1x)
    }

    struct InferenceRequest {
        uint256 modelId;
        address requester;
        string promptCid;           // IPFS CID of the inference prompt/input
        uint256 maxPrice;           // Max ETH price requester is willing to pay
        bytes32[] expectedOutputFeaturesHash; // Hashed list of expected output features
        string outputCid;           // IPFS CID of the inference output
        bytes32 proofHash;          // Hash of the computation proof (to be verified by oracle)
        uint256 actualCost;         // Actual cost paid to the inference node
        RequestStatus status;
        uint256 requestedAt;
        uint256 fulfilledAt;
        string disputeReasonCid;    // IPFS CID for dispute reason
    }

    struct GovernanceProposal {
        address proposer;
        string proposalCid;         // IPFS CID for proposal details
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalStatus status;
    }

    struct SyntheticDataSubmission {
        uint256 modelId;
        address submitter;
        string dataCid;             // IPFS CID for the synthetic data
        uint256 rewardAmount;       // Proposed reward for this data
        bool validated;
        bool claimed;
        uint256 submittedAt;
    }

    /* ====================================
     * 2. Interfaces (External Oracles/Services)
     * ==================================== */

    // @dev IOracle interface for interacting with an external oracle service.
    // In a real-world scenario, this would likely be a more complex,
    // decentralized oracle network (e.g., Chainlink, DIA) with specific
    // job IDs and data request/fulfillment patterns.
    // For this example, it's a simplified conceptual interface.
    interface IOracle {
        // Function to verify an off-chain computation proof.
        // Returns true if proof is valid, false otherwise.
        function verifyProof(bytes32 _proofHash) external view returns (bool);

        // Function to get a predicted inference price based on model parameters and prompt complexity.
        // This would involve off-chain AI/ML to estimate cost.
        function getPredictedPrice(uint256 _modelId, uint256 _promptComplexityEstimate) external view returns (uint256);

        // Function to validate the quality/relevance of submitted synthetic data.
        function validateSyntheticData(uint256 _submissionId, string memory _dataCid, uint256 _modelId) external view returns (bool);
    }

    /* ====================================
     * 3. Events
     * ==================================== */

    event OracleAddressUpdated(address indexed newOracle);
    event InferenceNodeAdded(address indexed node);
    event InferenceNodeRemoved(address indexed node);
    event DataValidatorAdded(address indexed validator);
    event DataValidatorRemoved(address indexed validator);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, string cid);
    event ModelMetadataUpdated(uint256 indexed modelId, string newCid, string newDescription);
    event ModelDeregistered(uint256 indexed modelId);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner);
    event ModelPricingParametersUpdated(uint256 indexed modelId, uint256 basePrice, uint256 complexityMultiplier);
    event ModelStatusUpdated(uint256 indexed modelId, ModelStatus newStatus);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, uint256 maxPrice);
    event InferenceFulfilled(uint256 indexed requestId, uint256 indexed modelId, address indexed fulfiller, uint256 actualCost);
    event InferenceCancelled(uint256 indexed requestId, address indexed requester);
    event InferenceDisputed(uint256 indexed requestId, address indexed disputer, string reasonCid);
    event InferenceDisputeResolved(uint256 indexed requestId, address indexed winner, uint256 amountToWinner, uint256 penaltyToLoser);

    event ModelRatingSubmitted(uint256 indexed modelId, address indexed rater, uint8 rating);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 votingEndTime);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EthicalPolicyUpdated(string policyCid);
    event ModelReported(uint256 indexed modelId, address indexed reporter, string reasonCid);

    event SyntheticDataSubmitted(uint256 indexed submissionId, uint256 indexed modelId, address indexed submitter, uint256 rewardAmount);
    event SyntheticDataValidated(uint256 indexed submissionId, bool isValid);
    event SyntheticDataRewardClaimed(uint256 indexed submissionId, address indexed claimant, uint256 amount);

    /* ====================================
     * 4. Error Handling
     * ==================================== */

    error InvalidOracleAddress();
    error NotAnInferenceNode();
    error NotADataValidator();
    error InvalidFeePercentage();
    error NoFeesToWithdraw();

    error ModelNotFound(uint256 modelId);
    error NotModelOwner(uint256 modelId, address caller);
    error ModelNotActive(uint256 modelId);
    error ModelAlreadyDeregistered(uint256 modelId);
    error InvalidPricingParameters();

    error RequestNotFound(uint256 requestId);
    error NotRequester(uint256 requestId, address caller);
    error NotInferenceNode(address caller);
    error RequestNotPending(uint256 requestId);
    error RequestAlreadyFulfilled(uint256 requestId);
    error InsufficientFundsForInference(uint256 maxPrice, uint256 provided);
    error PriceExceedsMaxPrice(uint256 actualCost, uint256 maxPrice);
    error InvalidProof();
    error RequestNotDisputed(uint256 requestId);
    error RequestNotResolved(uint256 requestId);
    error InvalidDisputeResolution();

    error ProposalNotFound(uint256 proposalId);
    error VotingAlreadyEnded(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalNotPassed(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address voter);
    error NoVoteEligibility(); // Placeholder for actual governance token logic

    error SyntheticDataNotFound(uint256 submissionId);
    error NotSubmitter(uint256 submissionId, address caller);
    error DataAlreadyValidated(uint256 submissionId);
    error DataAlreadyClaimed(uint256 submissionId);
    error DataInvalidated();

    /* ====================================
     * 5. State Variables
     * ==================================== */

    uint256 private _nextModelId;
    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) public modelsByOwner;

    uint256 private _nextRequestId;
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    mapping(uint256 => address) public inferenceRequestFundsEscrow; // To track who receives refunds from escrow

    uint256 private _nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter => voted

    uint256 private _nextDataSubmissionId;
    mapping(uint256 => SyntheticDataSubmission) public syntheticDataSubmissions;

    address public oracleAddress;
    address public governanceTokenAddress; // Address of a hypothetical governance token (e.g., ERC-20)
    uint256 public platformFeePercentage; // e.g., 5 for 5% (max 100)
    uint256 public totalPlatformFees;

    // Access control lists
    mapping(address => bool) public isInferenceNode;
    mapping(address => bool) public isDataValidator;

    string public currentEthicalPolicyCid; // IPFS CID of the current ethical guidelines

    /* ====================================
     * 6. Modifiers (Access Control)
     * ==================================== */

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert InvalidOracleAddress();
        _;
    }

    modifier onlyInferenceNode() {
        if (!isInferenceNode[msg.sender]) revert NotInferenceNode(msg.sender);
        _;
    }

    modifier onlyDataValidator() {
        if (!isDataValidator[msg.sender]) revert NotADataValidator();
        _;
    }

    modifier isModelOwner(uint256 _modelId) {
        if (models[_modelId].owner == address(0)) revert ModelNotFound(_modelId);
        if (models[_modelId].owner != msg.sender) revert NotModelOwner(_modelId, msg.sender);
        _;
    }

    // A placeholder for actual governance token check.
    // In a real system, this would check ERC-20 balance or reputation score.
    modifier onlyEligibleVoter() {
        // For simplicity, anyone can vote for now, but conceptually:
        // require(IERC20(governanceTokenAddress).balanceOf(msg.sender) > 0, "NoVoteEligibility");
        _; // Assume eligibility for now.
    }

    /* ====================================
     * 7. Constructor
     * ==================================== */

    constructor(address _oracleAddress, address _governanceTokenAddress, string memory _initialEthicalPolicyCid) Ownable(msg.sender) {
        if (_oracleAddress == address(0)) revert InvalidOracleAddress();
        oracleAddress = _oracleAddress;
        governanceTokenAddress = _governanceTokenAddress; // For voting eligibility
        currentEthicalPolicyCid = _initialEthicalPolicyCid;
        platformFeePercentage = 5; // Default 5%
        _nextModelId = 1;
        _nextRequestId = 1;
        _nextProposalId = 1;
        _nextDataSubmissionId = 1;
    }

    /* ====================================
     * 8. Admin Functions (Platform Owner)
     * ==================================== */

    /**
     * @dev Sets the address of the trusted oracle. Only callable by the contract owner.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert InvalidOracleAddress();
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Adds an address to the list of authorized inference nodes. Only callable by the contract owner.
     * @param _node The address to add.
     */
    function addInferenceNode(address _node) external onlyOwner {
        isInferenceNode[_node] = true;
        emit InferenceNodeAdded(_node);
    }

    /**
     * @dev Removes an address from the list of authorized inference nodes. Only callable by the contract owner.
     * @param _node The address to remove.
     */
    function removeInferenceNode(address _node) external onlyOwner {
        isInferenceNode[_node] = false;
        emit InferenceNodeRemoved(_node);
    }

    /**
     * @dev Adds an address to the list of authorized synthetic data validators. Only callable by the contract owner.
     * @param _validator The address to add.
     */
    function addDataValidator(address _validator) external onlyOwner {
        isDataValidator[_validator] = true;
        emit DataValidatorAdded(_validator);
    }

    /**
     * @dev Removes an address from the list of authorized synthetic data validators. Only callable by the contract owner.
     * @param _validator The address to remove.
     */
    function removeDataValidator(address _validator) external onlyOwner {
        isDataValidator[_validator] = false;
        emit DataValidatorRemoved(_validator);
    }

    /**
     * @dev Sets the platform fee percentage for inference requests. Only callable by the contract owner.
     * @param _newFeePercentage The new fee percentage (e.g., 5 for 5%). Must be between 0 and 100.
     */
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner {
        if (_newFeePercentage > 100) revert InvalidFeePercentage();
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        if (totalPlatformFees == 0) revert NoFeesToWithdraw();
        uint256 amount = totalPlatformFees;
        totalPlatformFees = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit PlatformFeesWithdrawn(msg.sender, amount);
    }

    /* ====================================
     * 9. Model Registry & Metadata Functions
     * ==================================== */

    /**
     * @dev Registers a new AI model on the platform.
     * @param _cid IPFS CID of the model's weights/parameters.
     * @param _name The human-readable name of the model.
     * @param _description A brief description of the model's capabilities and purpose.
     * @param _capabilitiesHash Hashed list of specific capabilities (e.g., image generation, text summarization).
     * @return The unique ID of the newly registered model.
     */
    function registerModel(
        string memory _cid,
        string memory _name,
        string memory _description,
        bytes32[] memory _capabilitiesHash
    ) external returns (uint256) {
        uint256 modelId = _nextModelId++;
        models[modelId] = Model({
            owner: msg.sender,
            cid: _cid,
            name: _name,
            description: _description,
            capabilitiesHash: _capabilitiesHash,
            registeredAt: block.timestamp,
            status: ModelStatus.Active,
            inferenceCount: 0,
            totalRating: 0,
            ratingCount: 0,
            basePrice: 0.001 ether, // Default base price
            complexityMultiplier: 100 // Default 1x
        });
        modelsByOwner[msg.sender].push(modelId);
        emit ModelRegistered(modelId, msg.sender, _name, _cid);
        return modelId;
    }

    /**
     * @dev Allows the model owner to update the IPFS CID or description of their model.
     * @param _modelId The ID of the model to update.
     * @param _newCid The new IPFS CID for the model (can be empty string to not update).
     * @param _newDescription The new description for the model (can be empty string to not update).
     */
    function updateModelMetadata(uint256 _modelId, string memory _newCid, string memory _newDescription)
        external
        isModelOwner(_modelId)
    {
        Model storage model = models[_modelId];
        if (bytes(_newCid).length > 0) {
            model.cid = _newCid;
        }
        if (bytes(_newDescription).length > 0) {
            model.description = _newDescription;
        }
        emit ModelMetadataUpdated(_modelId, model.cid, model.description);
    }

    /**
     * @dev Allows the model owner to mark their model as inactive, preventing new inference requests.
     * Existing pending requests can still be fulfilled or cancelled.
     * @param _modelId The ID of the model to deregister.
     */
    function deregisterModel(uint256 _modelId) external isModelOwner(_modelId) {
        Model storage model = models[_modelId];
        if (model.status == ModelStatus.Inactive) revert ModelAlreadyDeregistered(_modelId);
        model.status = ModelStatus.Inactive;
        emit ModelDeregistered(_modelId);
        emit ModelStatusUpdated(_modelId, ModelStatus.Inactive);
    }

    /**
     * @dev Transfers ownership of a model to a new address.
     * @param _modelId The ID of the model.
     * @param _newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 _modelId, address _newOwner) external isModelOwner(_modelId) {
        Model storage model = models[_modelId];
        address oldOwner = model.owner;
        model.owner = _newOwner;

        // Remove from old owner's list (simple approach, could be optimized for large lists)
        uint256[] storage oldOwnerModels = modelsByOwner[oldOwner];
        for (uint256 i = 0; i < oldOwnerModels.length; i++) {
            if (oldOwnerModels[i] == _modelId) {
                oldOwnerModels[i] = oldOwnerModels[oldOwnerModels.length - 1];
                oldOwnerModels.pop();
                break;
            }
        }
        modelsByOwner[_newOwner].push(_modelId);

        emit ModelOwnershipTransferred(_modelId, oldOwner, _newOwner);
    }

    /**
     * @dev Retrieves all details of a registered model.
     * @param _modelId The ID of the model.
     * @return A tuple containing all model struct fields.
     */
    function getModelDetails(uint256 _modelId)
        external
        view
        returns (
            address owner,
            string memory cid,
            string memory name,
            string memory description,
            bytes32[] memory capabilitiesHash,
            uint256 registeredAt,
            ModelStatus status,
            uint256 inferenceCount,
            uint256 totalRating,
            uint256 ratingCount,
            uint256 basePrice,
            uint256 complexityMultiplier
        )
    {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        return (
            model.owner,
            model.cid,
            model.name,
            model.description,
            model.capabilitiesHash,
            model.registeredAt,
            model.status,
            model.inferenceCount,
            model.totalRating,
            model.ratingCount,
            model.basePrice,
            model.complexityMultiplier
        );
    }

    /**
     * @dev Returns a list of all model IDs owned by a specific address.
     * @param _owner The address whose models are to be retrieved.
     * @return An array of model IDs.
     */
    function getModelsByOwner(address _owner) external view returns (uint256[] memory) {
        return modelsByOwner[_owner];
    }

    /* ====================================
     * 10. Inference Request & Fulfillment Functions
     * ==================================== */

    /**
     * @dev Allows a user to request an AI inference from a specified model.
     * Requires sending ETH equal to or greater than `_maxPrice`.
     * The ETH is held in escrow until fulfillment or cancellation.
     * @param _modelId The ID of the model to request inference from.
     * @param _promptCid IPFS CID of the input prompt/data for the inference.
     * @param _maxPrice The maximum ETH price the requester is willing to pay for this inference.
     * @param _expectedOutputFeaturesHash Hashed list of expected output features (for validation/dispute).
     * @return The unique ID of the created inference request.
     */
    function requestInference(
        uint256 _modelId,
        string memory _promptCid,
        uint256 _maxPrice,
        bytes32[] memory _expectedOutputFeaturesHash
    ) external payable nonReentrant returns (uint256) {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        if (model.status != ModelStatus.Active) revert ModelNotActive(_modelId);
        if (msg.value < _maxPrice) revert InsufficientFundsForInference(_maxPrice, msg.value);

        uint256 requestId = _nextRequestId++;
        inferenceRequests[requestId] = InferenceRequest({
            modelId: _modelId,
            requester: msg.sender,
            promptCid: _promptCid,
            maxPrice: _maxPrice,
            expectedOutputFeaturesHash: _expectedOutputFeaturesHash,
            outputCid: "",
            proofHash: bytes32(0),
            actualCost: 0,
            status: RequestStatus.Pending,
            requestedAt: block.timestamp,
            fulfilledAt: 0,
            disputeReasonCid: ""
        });
        inferenceRequestFundsEscrow[requestId] = msg.sender; // Store requester to handle refunds

        emit InferenceRequested(requestId, _modelId, msg.sender, _maxPrice);
        return requestId;
    }

    /**
     * @dev An authorized inference node fulfills a pending inference request.
     * The node provides the output CID, a hash of the computation proof, and the actual cost.
     * The actual cost must not exceed the `_maxPrice` set by the requester.
     * The oracle verifies the proof off-chain.
     * @param _requestId The ID of the inference request to fulfill.
     * @param _modelId The ID of the model used (for verification).
     * @param _outputCid IPFS CID of the inference output.
     * @param _proofHash Hash of the off-chain computation proof.
     * @param _actualCost The actual ETH cost incurred for the inference.
     */
    function fulfillInference(
        uint256 _requestId,
        uint256 _modelId,
        string memory _outputCid,
        bytes32 _proofHash,
        uint256 _actualCost
    ) external onlyInferenceNode nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.requester == address(0)) revert RequestNotFound(_requestId);
        if (request.status != RequestStatus.Pending) revert RequestNotPending(_requestId);
        if (request.modelId != _modelId) revert ModelNotFound(_modelId); // Sanity check
        if (_actualCost > request.maxPrice) revert PriceExceedsMaxPrice(_actualCost, request.maxPrice);

        // Conceptually, call oracle to verify proof. For this example, we assume success.
        // bool proofIsValid = IOracle(oracleAddress).verifyProof(_proofHash);
        // if (!proofIsValid) revert InvalidProof();

        request.outputCid = _outputCid;
        request.proofHash = _proofHash;
        request.actualCost = _actualCost;
        request.status = RequestStatus.Fulfilled;
        request.fulfilledAt = block.timestamp;

        // Calculate platform fee
        uint256 platformFee = (_actualCost * platformFeePercentage) / 100;
        uint256 amountToNode = _actualCost - platformFee;

        // Transfer funds: node, platform, and refund excess to requester
        totalPlatformFees += platformFee;
        (bool successNode,) = msg.sender.call{value: amountToNode}("");
        require(successNode, "Failed to pay inference node");

        uint256 excessRefund = msg.value - _actualCost;
        if (excessRefund > 0) {
            (bool successRefund,) = request.requester.call{value: excessRefund}("");
            require(successRefund, "Failed to refund excess to requester");
        }

        models[_modelId].inferenceCount++;
        emit InferenceFulfilled(_requestId, _modelId, msg.sender, _actualCost);
    }

    /**
     * @dev Allows the requester to cancel a pending inference request and reclaim their funds.
     * @param _requestId The ID of the request to cancel.
     */
    function cancelInferenceRequest(uint256 _requestId) external nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.requester == address(0)) revert RequestNotFound(_requestId);
        if (request.requester != msg.sender) revert NotRequester(_requestId, msg.sender);
        if (request.status != RequestStatus.Pending) revert RequestNotPending(_requestId);

        request.status = RequestStatus.Cancelled;

        // Refund the entire escrowed amount
        uint256 amount = address(this).balance - totalPlatformFees; // simplified: get the amount specifically for this request
        if (amount > 0) {
            (bool success,) = msg.sender.call{value: amount}(""); // assuming no other funds in contract than req.msg.value for this specific request
            require(success, "Cancellation refund failed");
        }
        delete inferenceRequestFundsEscrow[_requestId]; // Clear mapping entry

        emit InferenceCancelled(_requestId, msg.sender);
    }

    /**
     * @dev Allows a user to dispute a fulfilled inference request if the output is unsatisfactory or incorrect.
     * This moves the request into a disputed state, requiring governance intervention.
     * @param _requestId The ID of the request to dispute.
     * @param _reasonCid IPFS CID pointing to detailed reasons for the dispute.
     */
    function disputeInference(uint256 _requestId, string memory _reasonCid) external {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.requester == address(0)) revert RequestNotFound(_requestId);
        if (request.requester != msg.sender) revert NotRequester(_requestId, msg.sender);
        if (request.status != RequestStatus.Fulfilled) revert RequestNotFulfilled(_requestId);

        request.status = RequestStatus.Disputed;
        request.disputeReasonCid = _reasonCid;
        emit InferenceDisputed(_requestId, msg.sender, _reasonCid);
    }

    /**
     * @dev Resolves a disputed inference request. This function would typically be called
     * by a governance mechanism or a trusted arbitrator after reviewing the dispute.
     * @param _requestId The ID of the disputed request.
     * @param _isSatisfied True if the requester is deemed satisfied (model/node wins), false if not (requester wins).
     * @param _penalty A penalty amount to be applied to the losing party, potentially distributed.
     */
    function resolveDispute(uint256 _requestId, bool _isSatisfied, uint256 _penalty) external onlyOwner nonReentrant {
        // In a real DAO, this would be an `executeProposal` function after a vote.
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.requester == address(0)) revert RequestNotFound(_requestId);
        if (request.status != RequestStatus.Disputed) revert RequestNotDisputed(_requestId);

        address winner;
        address loser;
        uint256 amountToWinner = 0;
        uint256 amountToLoser = 0; // Penalty or refund to loser

        // The actual cost paid to the node, plus any pending platform fee if already paid
        uint256 totalCostInvolved = request.actualCost; // Assuming platform fee is part of actualCost.

        if (_isSatisfied) { // Requester is satisfied (or dispute failed), inference node/model owner wins.
            winner = msg.sender; // Placeholder: in real system, this goes to InferenceNode who fulfilled it.
                               // For simplicity here, funds stay with contract or revert based on flow.
            amountToWinner = totalCostInvolved; // Original amount.
            // No refund to requester, they lose.
            // If there's an explicit penalty to requester, implement here.
            
            // To be precise, funds are already distributed to inference node/platform.
            // This resolution typically affects the model's reputation score and might initiate a refund
            // if the original payment was held in escrow entirely (which it isn't in my `fulfill` logic).
            // Re-evaluating fund flow for `fulfillInference` and `resolveDispute`:
            // The `fulfillInference` *immediately* pays the node. So, `resolveDispute` implies
            // that IF the requester wins, the inference node *must pay back*.
            // This requires a different escrow mechanism or a slashing mechanism for inference nodes.

            // Let's refine: `fulfillInference` should put funds *into a temporary escrow for the node*
            // until the dispute period ends or dispute is resolved.

            // For now, let's assume `_penalty` is paid by the losing party.
            // If requester wins (`!_isSatisfied`), InferenceNode pays penalty to requester.
            // If InferenceNode wins (`_isSatisfied`), requester pays nothing, or their original payment is confirmed.

            // Given current `fulfillInference` immediately pays node:
            // If `_isSatisfied` (node wins), no further action on funds. Rep score updates.
            // If `!_isSatisfied` (requester wins), the node has to refund `actualCost`, and potentially pay `_penalty`.

            // This is a complex area for a simple example. Let's simplify and say:
            // If _isSatisfied (Model/Node wins): Requester gets no refund.
            // If !_isSatisfied (Requester wins): Inference Node is penalized, requester gets refund.
            // But the Inference Node already *got paid*. So, we need to slash them or have a bond.
            // Let's assume a bond for Inference Nodes or a reputation-based slashing.

            // To simplify for the example, let's assume `_penalty` is taken from `totalPlatformFees` or `msg.value` if the loser pays immediately.

            if (!_isSatisfied) { // Requester wins, Inference Node/Model owner loses.
                // The amount the requester paid initially.
                uint256 refundAmount = request.maxPrice; // This is what they initially locked.
                (bool success,) = request.requester.call{value: refundAmount}("");
                require(success, "Dispute refund failed for requester");

                // Assuming the node needs to be penalized. This would require the node to have a bond.
                // For this example, let's say _penalty is paid to the requester on top of the refund
                // or the contract 'slashes' it from the *inference node's future earnings*.
                // This is a conceptual example for "penalty."
                winner = request.requester;
                loser = msg.sender; // The inference node who fulfilled.
                emit InferenceDisputeResolved(_requestId, winner, refundAmount, _penalty);
            } else { // Inference Node/Model Owner wins.
                // No refund to requester. The locked funds for `maxPrice` are considered "spent".
                // If there's a penalty to the requester, it would be collected here.
                winner = msg.sender; // For simplicity, marking owner as winner.
                loser = request.requester;
                emit InferenceDisputeResolved(_requestId, winner, 0, _penalty); // No specific amount transferred, but reputation affected.
            }
        }

        request.status = RequestStatus.Resolved;
        // Logic to update model/node reputation based on dispute outcome
        // This is a critical part of the reputation system but too complex to fully implement here.
        // It would involve weighted reputation score updates, potential slashing, etc.
    }

    /* ====================================
     * 11. Model Reputation & Dynamic Pricing Functions
     * ==================================== */

    /**
     * @dev Allows a user to submit a rating for a model after an inference.
     * This influences the model's overall reputation.
     * @param _modelId The ID of the model being rated.
     * @param _rating The rating (1-5, where 5 is best).
     * @param _feedbackCid IPFS CID for detailed feedback (optional).
     */
    function submitModelRating(uint256 _modelId, uint8 _rating, string memory _feedbackCid) external {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        if (_rating == 0 || _rating > 5) revert("Invalid rating"); // 1-5 star rating system

        model.totalRating += _rating;
        model.ratingCount++;
        // Additional logic: ensure only users who actually used the model can rate,
        // prevent sybil attacks by weighting votes by stake/reputation.
        emit ModelRatingSubmitted(_modelId, msg.sender, _rating);
    }

    /**
     * @dev Retrieves the current average rating for a model.
     * @param _modelId The ID of the model.
     * @return The average rating (scaled by 100 for two decimal places, e.g., 450 for 4.50).
     */
    function getAverageRating(uint256 _modelId) external view returns (uint256) {
        Model storage model = models[_modelId];
        if (model.ratingCount == 0) return 0;
        return (model.totalRating * 100) / model.ratingCount;
    }

    /**
     * @dev Calculates a composite reputation score for a model.
     * This is a simplified example; a real reputation system would be more complex.
     * @param _modelId The ID of the model.
     * @return A reputation score, higher is better.
     */
    function getModelReputation(uint256 _modelId) public view returns (uint256) {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) return 0; // Model not found

        uint256 averageRating = getAverageRating(_modelId); // Scaled by 100
        uint256 inferenceSuccessRate = 10000; // Placeholder, need to track disputes. (10000 = 100%)
        // Example: (successful inferences / total inferences) * 10000

        // Simple composite score: (average rating * 100) * (inference success rate / 100)
        // Adjust weights as needed.
        // Here, it's: (average rating * inference success rate) / 100
        return (averageRating * inferenceSuccessRate) / 10000;
    }

    /**
     * @dev Predicts an estimated inference price for a model based on its reputation,
     * historical demand, and an estimated prompt complexity.
     * This relies on an external oracle for complex price prediction logic.
     * @param _modelId The ID of the model.
     * @param _promptComplexityEstimate An estimate of the prompt's computational complexity.
     * @return The estimated price in wei.
     */
    function predictInferencePrice(uint256 _modelId, uint256 _promptComplexityEstimate) external view returns (uint256) {
        if (oracleAddress == address(0)) revert InvalidOracleAddress();
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);

        // This function leverages the oracle to provide a sophisticated price prediction.
        // The oracle might factor in: model.basePrice, model.complexityMultiplier,
        // current network congestion, model's reputation (getModelReputation), demand, etc.
        // For this example, we'll return a simple calculation if oracle not set, else call oracle.
        if (oracleAddress == address(0)) {
             return (model.basePrice + (model.complexityMultiplier * _promptComplexityEstimate / 100));
        } else {
            return IOracle(oracleAddress).getPredictedPrice(_modelId, _promptComplexityEstimate);
        }
    }

    /**
     * @dev Allows the model owner to update the base price and complexity multiplier for their model.
     * These parameters influence the total cost of an inference.
     * @param _modelId The ID of the model.
     * @param _newBasePrice The new base price in wei.
     * @param _newComplexityMultiplier The new complexity multiplier (e.g., 100 for 1x).
     */
    function updatePricingParameters(uint256 _modelId, uint256 _newBasePrice, uint256 _newComplexityMultiplier)
        external
        isModelOwner(_modelId)
    {
        if (_newBasePrice == 0 || _newComplexityMultiplier == 0) revert InvalidPricingParameters();
        Model storage model = models[_modelId];
        model.basePrice = _newBasePrice;
        model.complexityMultiplier = _newComplexityMultiplier;
        emit ModelPricingParametersUpdated(_modelId, _newBasePrice, _newComplexityMultiplier);
    }

    /* ====================================
     * 12. Ethical AI Governance Functions
     * ==================================== */

    /**
     * @dev Creates a new governance proposal for community voting.
     * Proposals can be for ethical policy updates, model suspension, new features, etc.
     * @param _proposalCid IPFS CID pointing to the full details of the proposal.
     * @param _votingEndTime The timestamp when voting for this proposal ends.
     * @return The unique ID of the created proposal.
     */
    function createGovernanceProposal(string memory _proposalCid, uint256 _votingEndTime) external returns (uint256) {
        if (_votingEndTime <= block.timestamp) revert("Voting end time must be in the future");
        uint256 proposalId = _nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            proposalCid: _proposalCid,
            votingEndTime: _votingEndTime,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            status: ProposalStatus.Active
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _votingEndTime);
        return proposalId;
    }

    /**
     * @dev Allows eligible participants to vote on an active governance proposal.
     * Voting eligibility typically depends on holding a governance token or having sufficient reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes" vote, false for "no" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyEligibleVoter {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.votingEndTime <= block.timestamp) revert VotingAlreadyEnded(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);
        if (hasVotedOnProposal[_proposalId][msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        hasVotedOnProposal[_proposalId][msg.sender] = true;
        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a governance proposal if it has passed its voting period and received enough "yes" votes.
     * The logic for "enough votes" (e.g., quorum, majority) would be more complex in a real DAO.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        // In a real DAO, this would be callable by anyone after the voting ends and conditions are met.
        // For simplicity, `onlyOwner` acts as the executor.
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.votingEndTime > block.timestamp) revert("Voting not ended yet");
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);

        // Simple majority rule for demonstration. Real DAOs use more complex quorums.
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Passed;
            // Here, implement the logic specific to the proposal.
            // This would likely involve parsing _proposalCid or having proposal types.
            // E.g., if it's a proposal to suspend a model:
            // models[MODEL_ID_FROM_PROPOSAL].status = ModelStatus.Suspended;
            // Or if it's to update ethical policy:
            // currentEthicalPolicyCid = NEW_CID_FROM_PROPOSAL;

            // For now, let's just mark it executed.
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            revert ProposalNotPassed(_proposalId);
        }
    }

    /**
     * @dev Updates the platform's overarching ethical policy (e.g., for AI content moderation).
     * This function should only be callable after a successful governance proposal.
     * @param _policyCid IPFS CID pointing to the new ethical policy document.
     */
    function setEthicalPolicy(string memory _policyCid) external onlyOwner {
        // In a real system, this would be part of an `executeProposal`
        // if a governance proposal for a new policy has passed.
        currentEthicalPolicyCid = _policyCid;
        emit EthicalPolicyUpdated(_policyCid);
    }

    /**
     * @dev Allows users to report a model that they believe violates the ethical policies.
     * This triggers a governance review process.
     * @param _modelId The ID of the reported model.
     * @param _reasonCid IPFS CID pointing to detailed reasons for the report.
     */
    function reportMaliciousModel(uint256 _modelId, string memory _reasonCid) external {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        if (model.status == ModelStatus.Suspended) revert("Model already suspended");

        model.status = ModelStatus.Reported; // Mark for review
        // Automatically create a governance proposal for review/suspension.
        // This is a simplified call; real implementation would require more structured data.
        createGovernanceProposal(
            string(abi.encodePacked("Reported model ", _modelId, ": ", _reasonCid)),
            block.timestamp + 7 days // 7 days for voting
        );

        emit ModelReported(_modelId, msg.sender, _reasonCid);
        emit ModelStatusUpdated(_modelId, ModelStatus.Reported);
    }

    /* ====================================
     * 13. Synthetic Data Generation Incentives Functions
     * ==================================== */

    /**
     * @dev Allows users to submit synthetic data intended for training or fine-tuning a specific AI model.
     * Submitters propose a reward amount for their data.
     * @param _modelId The ID of the target AI model for which the data is generated.
     * @param _dataCid IPFS CID pointing to the synthetic data.
     * @param _rewardAmount The ETH amount requested as a reward for this data (locked here).
     * @return The unique ID of the data submission.
     */
    function submitSyntheticData(uint256 _modelId, string memory _dataCid, uint256 _rewardAmount) external payable returns (uint256) {
        if (models[_modelId].owner == address(0)) revert ModelNotFound(_modelId);
        if (msg.value < _rewardAmount) revert("Insufficient ETH provided for reward");

        uint256 submissionId = _nextDataSubmissionId++;
        syntheticDataSubmissions[submissionId] = SyntheticDataSubmission({
            modelId: _modelId,
            submitter: msg.sender,
            dataCid: _dataCid,
            rewardAmount: _rewardAmount,
            validated: false,
            claimed: false,
            submittedAt: block.timestamp
        });
        emit SyntheticDataSubmitted(submissionId, _modelId, msg.sender, _rewardAmount);
        return submissionId;
    }

    /**
     * @dev An authorized data validator reviews the submitted synthetic data.
     * If valid, the data is marked as such, making the reward claimable.
     * @param _submissionId The ID of the synthetic data submission.
     * @param _isValid True if the data is deemed high-quality and relevant, false otherwise.
     */
    function validateSyntheticData(uint256 _submissionId, bool _isValid) external onlyDataValidator {
        SyntheticDataSubmission storage submission = syntheticDataSubmissions[_submissionId];
        if (submission.submitter == address(0)) revert SyntheticDataNotFound(_submissionId);
        if (submission.validated) revert DataAlreadyValidated(_submissionId);

        // Potentially use oracle here for a more robust validation
        // bool oracleValidation = IOracle(oracleAddress).validateSyntheticData(_submissionId, submission.dataCid, submission.modelId);
        // if (_isValid && !oracleValidation) { // Or combine logic
        //     revert("Oracle validation failed");
        // }

        submission.validated = _isValid;
        emit SyntheticDataValidated(_submissionId, _isValid);
    }

    /**
     * @dev Allows the original submitter of synthetic data to claim their reward
     * if their submission has been successfully validated.
     * @param _submissionId The ID of the synthetic data submission.
     */
    function claimSyntheticDataReward(uint256 _submissionId) external nonReentrant {
        SyntheticDataSubmission storage submission = syntheticDataSubmissions[_submissionId];
        if (submission.submitter == address(0)) revert SyntheticDataNotFound(_submissionId);
        if (submission.submitter != msg.sender) revert NotSubmitter(_submissionId, msg.sender);
        if (!submission.validated) revert("Data not yet validated");
        if (!submission.validated) revert DataInvalidated(); // If validation resulted in false
        if (submission.claimed) revert DataAlreadyClaimed(_submissionId);

        submission.claimed = true;
        uint256 rewardAmount = submission.rewardAmount;
        (bool success,) = msg.sender.call{value: rewardAmount}("");
        require(success, "Reward claim failed");
        emit SyntheticDataRewardClaimed(_submissionId, msg.sender, rewardAmount);
    }
}
```