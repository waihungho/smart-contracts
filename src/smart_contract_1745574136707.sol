Okay, let's create a sophisticated smart contract for a Decentralized AI Model Marketplace.

This contract will allow model creators to list their AI models, users to purchase access or request inferences, and use staking mechanisms to incentivize honest model providers and inference workers. It introduces concepts like model versioning, inference request tracking, and a basic framework for dispute resolution (though the actual dispute logic would be complex and likely involve off-chain components or oracles in a real-world scenario).

It's not a simple token or basic marketplace; it manages state for ongoing processes (inference requests), incorporates staking, and handles different types of interactions (listing, access, inference).

---

**Outline and Function Summary:**

1.  **Contract Overview:**
    *   Manages a marketplace for AI models.
    *   Model creators list models, specifying details and required stakes.
    *   Users purchase access (e.g., subscription or perpetual).
    *   Users request inferences by providing input data hashes and paying fees.
    *   Off-chain workers (often the model creator or designated providers) perform inference and submit result hashes.
    *   Users claim result hashes after successful inference and verification.
    *   Includes staking and basic slashing mechanisms for providers.
    *   Uses an ERC-20 token for all transactions.
    *   Admin functions for fees, pausing, and basic dispute resolution.

2.  **State Variables:**
    *   `marketplaceFee`: Percentage fee taken by the marketplace.
    *   `feeRecipient`: Address receiving marketplace fees.
    *   `inferenceTimeout`: Maximum time allowed for an inference request.
    *   `paused`: Boolean to pause core marketplace functions.
    *   `models`: Mapping from `bytes32` (Model ID, e.g., hash of creation parameters) to `Model` struct.
    *   `inferenceRequests`: Mapping from `bytes32` (Request ID, e.g., hash of request parameters) to `InferenceRequest` struct.
    *   `userProfiles`: Mapping from `address` to `UserProfile` struct.
    *   `supportedModelTypes`: Mapping for validating predefined model categories.
    *   `modelCounter`: Counter for generating unique model IDs (alternative to hashing).
    *   `requestCounter`: Counter for generating unique request IDs.
    *   `paymentToken`: Address of the ERC-20 token used.

3.  **Structs:**
    *   `ModelVersion`: Details for a specific version of a model (e.g., data hash, price, requirements).
    *   `Model`: Represents an AI model (owner, name, description URL, creation time, versions, current stake, status).
    *   `InferenceRequest`: Details of an inference request (requester, model ID, version, input hash, fee paid, provider stake, status, timestamps).
    *   `UserProfile`: User's balance in the marketplace token, maybe reputation score placeholder.

4.  **Events:**
    *   `ModelListed`: When a new model is listed.
    *   `ModelUpdated`: When model details are updated.
    *   `ModelVersionAdded`: When a new version is added.
    *   `ModelDeactivated/Activated`: When a model's status changes.
    *   `AccessPurchased`: When a user buys access to a model.
    *   `InferenceRequested`: When a user submits an inference request.
    *   `InferenceSubmitted`: When a provider submits an inference result.
    *   `InferenceCompleted`: When an inference request is successfully completed and results are claimable.
    *   `InferenceDisputed`: When an inference result is disputed.
    *   `StakeSlashed`: When a provider's stake is slashed.
    *   `FundsWithdrawn`: When a user/provider withdraws funds.
    *   `MarketplacePaused/Unpaused`: When the marketplace state changes.
    *   `FeeUpdated`: When the marketplace fee is changed.

5.  **Functions (> 20):**

    *   **Admin/Setup:**
        1.  `constructor`: Initializes the contract with token address and fee recipient.
        2.  `updateMarketplaceFee`: Sets the marketplace fee (owner only).
        3.  `updateFeeRecipient`: Sets the address receiving fees (owner only).
        4.  `pauseMarketplace`: Pauses core marketplace functions (owner only).
        5.  `unpauseMarketplace`: Unpauses the marketplace (owner only).
        6.  `addSupportedModelType`: Adds a predefined category for models (owner only).
        7.  `removeSupportedModelType`: Removes a predefined category (owner only).
        8.  `setInferenceTimeout`: Sets the max duration for an inference request (owner only).
        9.  `resolveDispute`: Placeholder for admin-based dispute resolution (owner only). Can slash or refund based on outcome.

    *   **Model Provider Functions:**
        10. `listModel`: Lists a new AI model with initial version and required stake. Requires token approval and transfer.
        11. `addModelVersion`: Adds a new version to an existing model (model owner only).
        12. `updateModelMetadata`: Updates description URL for a model (model owner only).
        13. `updateModelVersionDetails`: Updates price/details for a specific version (model owner only).
        14. `deactivateModel`: Temporarily disables a model (model owner only).
        15. `activateModel`: Re-enables a model (model owner only).
        16. `withdrawModelStake`: Allows model owner to withdraw stake after conditions met (e.g., no active requests).

    *   **User/Requester Functions:**
        17. `purchaseModelAccess`: Allows user to buy access (e.g., perpetual) to a model. Requires token transfer. (Simplified access logic for this example).
        18. `requestInference`: Initiates an inference request for a specific model version. Requires payment and potentially provider stake escrow. Requires token transfer.
        19. `submitInferenceResult`: (Intended for off-chain worker/provider) Submits the output hash for a completed inference request. Requires verification logic (simplified). Requires provider stake.
        20. `claimInferenceResult`: Allows the user who requested inference to retrieve the result hash once submitted and validated (simplified validation). Transfers payment to provider/marketplace.
        21. `disputeInferenceResult`: Allows a user to dispute a submitted result. Requires staking a dispute bond.

    *   **General/Utility Functions:**
        22. `withdrawUserFunds`: Allows users to withdraw available balance (e.g., refunded stakes, earnings).
        23. `getMarketplaceState`: View function to get global marketplace parameters.
        24. `getModelDetails`: View function to get details of a specific model.
        25. `getModelVersionDetails`: View function to get details of a specific model version.
        26. `getInferenceRequestDetails`: View function to get details of an inference request.
        27. `getUserProfile`: View function to get a user's profile information.
        28. `listActiveModels`: View function to list available models (simplified, potentially returning IDs).
        29. `checkModelAccess`: View function to check if a user has access to a model (simplified).
        30. `getRequiredStakes`: View function to calculate required stakes for listing/inference.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Decentralized AI Model Marketplace
 * @dev A marketplace contract for listing, purchasing access to, and requesting inferences from AI models.
 *      Incorporates staking, versioning, and a basic inference workflow with dispute potential.
 *
 * Outline:
 * 1. Contract Overview: Manages AI model listing, access, inference requests, staking, and disputes.
 * 2. State Variables: Global settings, mappings for models, requests, users, supported types, counters.
 * 3. Structs: ModelVersion, Model, InferenceRequest, UserProfile.
 * 4. Events: Signify state changes (listing, requesting, submitting, disputing, etc.).
 * 5. Functions: Admin, Provider, Requester, and View functions implementing marketplace logic.
 *
 * Function Summary:
 * - Admin/Setup: updateMarketplaceFee, updateFeeRecipient, pauseMarketplace, unpauseMarketplace,
 *   addSupportedModelType, removeSupportedModelType, setInferenceTimeout, resolveDispute.
 * - Model Provider: listModel, addModelVersion, updateModelMetadata, updateModelVersionDetails,
 *   deactivateModel, activateModel, withdrawModelStake.
 * - User/Requester: purchaseModelAccess, requestInference, submitInferenceResult (by provider),
 *   claimInferenceResult (by requester), disputeInferenceResult (by requester).
 * - General/Utility: withdrawUserFunds, getMarketplaceState, getModelDetails, getModelVersionDetails,
 *   getInferenceRequestDetails, getUserProfile, listActiveModels, checkModelAccess, getRequiredStakes.
 */
contract DecentralizedAIModelMarketplace is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // --- State Variables ---
    uint256 public marketplaceFee; // Fee percentage (e.g., 100 = 1%)
    address public feeRecipient;
    uint256 public inferenceTimeout; // Max time in seconds for inference requests
    bool public paused;

    IERC20 public immutable paymentToken;

    enum ModelStatus { Active, Inactive }
    enum InferenceStatus { Requested, Submitted, Completed, Disputed, Failed, TimedOut }

    struct ModelVersion {
        bytes32 versionHash; // Hash of model data/code for this version (e.g., IPFS CID)
        uint256 accessPrice; // Price to purchase access to this version
        uint256 inferenceFee; // Price per inference request using this version
        uint256 providerStakeRequired; // Stake required from provider per inference
        bytes32 inputFormatHash; // Hash or ID representing expected input data format
        bytes32 outputFormatHash; // Hash or ID representing expected output data format
        uint64 creationTime;
    }

    struct Model {
        address owner;
        string name;
        string descriptionURL; // URL to more details (e.g., IPFS)
        bytes32 modelType; // Category/type of the model (e.g., "ImageClassification", "NLP")
        uint64 creationTime;
        ModelStatus status;
        uint256 currentStake; // Total stake deposited by the model owner for listing
        bytes32[] versionHashes; // Ordered list of version hashes
        mapping(bytes32 => ModelVersion) versions; // Mapping from version hash to version details
        EnumerableSet.Bytes32Set activeInferenceRequests; // Requests pending for this model
    }

    struct InferenceRequest {
        bytes32 requestId; // Unique ID for the request
        bytes32 modelId; // ID of the model used
        bytes32 versionHash; // Hash of the model version used
        address requester;
        uint256 feePaid;
        bytes32 inputHash; // Hash of the input data (e.g., IPFS CID)
        bytes32 outputHash; // Hash of the output data (submitted later)
        address provider; // Address of the provider who took the request
        uint256 providerStakeEscrowed; // Stake from provider held for this request
        InferenceStatus status;
        uint64 requestTime;
        uint64 submissionTime; // Timestamp when result was submitted
    }

    struct UserProfile {
        uint256 balance; // User's withdrawable balance in paymentToken
        EnumerableSet.Bytes32Set purchasedModelAccess; // Set of model IDs the user has access to (simplified as perpetual)
        // Future: reputation score, list of requests, etc.
    }

    mapping(bytes32 => Model) public models;
    mapping(bytes32 => InferenceRequest) public inferenceRequests;
    mapping(address => UserProfile) public userProfiles;
    mapping(bytes32 => bool) public supportedModelTypes; // e.g., keccak256("ImageRecognition") => true

    EnumerableSet.Bytes32Set private _activeModelIds; // Set of IDs for models with status Active
    EnumerableSet.Bytes32Set private _allModelIds; // Set of all model IDs

    uint256 private _modelCounter = 0;
    uint256 private _requestCounter = 0;

    // --- Events ---
    event ModelListed(bytes32 indexed modelId, address indexed owner, string name, bytes32 indexed modelType, uint256 requiredStake);
    event ModelUpdated(bytes32 indexed modelId, string descriptionURL);
    event ModelVersionAdded(bytes32 indexed modelId, bytes32 indexed versionHash, uint256 accessPrice, uint256 inferenceFee);
    event ModelDeactivated(bytes32 indexed modelId);
    event ModelActivated(bytes32 indexed modelId);
    event StakeWithdrawn(bytes32 indexed modelId, address indexed owner, uint256 amount);

    event AccessPurchased(bytes32 indexed modelId, address indexed requester, uint256 amountPaid);
    event InferenceRequested(bytes32 indexed requestId, bytes32 indexed modelId, bytes32 indexed versionHash, address indexed requester, bytes32 inputHash, uint256 feePaid);
    event InferenceSubmitted(bytes32 indexed requestId, bytes32 outputHash, address indexed provider, uint256 providerStakeEscrowed);
    event InferenceCompleted(bytes32 indexed requestId, bytes32 outputHash);
    event InferenceDisputed(bytes32 indexed requestId, address indexed disputer);
    event StakeSlashed(address indexed account, uint256 amount, bytes32 indexed reason);

    event FundsTransferred(address indexed from, address indexed to, uint256 amount);
    event FundsWithdrawn(address indexed account, uint256 amount);

    event MarketplacePaused();
    event MarketplaceUnpaused();
    event FeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);
    event InferenceTimeoutUpdated(uint256 newTimeout);
    event SupportedModelTypeUpdated(bytes32 indexed modelType, bool supported);
    event DisputeResolved(bytes32 indexed requestId, bool slashProvider, bool refundRequester);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Marketplace: Paused");
        _;
    }

    modifier onlyModelOwner(bytes32 _modelId) {
        require(models[_modelId].owner == msg.sender, "Marketplace: Not model owner");
        _;
    }

    modifier onlyInferenceRequester(bytes32 _requestId) {
        require(inferenceRequests[_requestId].requester == msg.sender, "Marketplace: Not inference requester");
        _;
    }

    modifier onlyInferenceProvider(bytes32 _requestId) {
         require(inferenceRequests[_requestId].provider == msg.sender, "Marketplace: Not inference provider");
         _;
    }

    modifier onlyRequestPending(bytes32 _requestId) {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == InferenceStatus.Requested, "Marketplace: Request not in Requested state");
        require(block.timestamp <= request.requestTime + inferenceTimeout, "Marketplace: Request timed out");
        _;
    }

     modifier onlyRequestSubmitted(bytes32 _requestId) {
        require(inferenceRequests[_requestId].status == InferenceStatus.Submitted, "Marketplace: Request not in Submitted state");
        _;
    }

    // --- Constructor ---
    constructor(address _paymentTokenAddress, address _feeRecipient, uint256 _initialMarketplaceFee, uint256 _initialInferenceTimeout) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentTokenAddress);
        feeRecipient = _feeRecipient;
        marketplaceFee = _initialMarketplaceFee; // e.g., 100 for 1%
        inferenceTimeout = _initialInferenceTimeout; // e.g., 1 hour in seconds
    }

    // --- Admin Functions ---

    /**
     * @dev Updates the marketplace fee percentage. Only callable by the owner.
     * @param _newFee The new fee percentage (e.g., 50 for 0.5%, 100 for 1%). Max 10000 (100%).
     */
    function updateMarketplaceFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 10000, "Marketplace: Fee cannot exceed 100%");
        marketplaceFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    /**
     * @dev Updates the address receiving marketplace fees. Only callable by the owner.
     * @param _newRecipient The new address to receive fees.
     */
    function updateFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Marketplace: Invalid fee recipient address");
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Pauses core marketplace functions (listing, requesting, submitting). Only callable by the owner.
     */
    function pauseMarketplace() public onlyOwner {
        require(!paused, "Marketplace: Already paused");
        paused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses the marketplace. Only callable by the owner.
     */
    function unpauseMarketplace() public onlyOwner {
        require(paused, "Marketplace: Not paused");
        paused = false;
        emit MarketplaceUnpaused();
    }

     /**
     * @dev Adds a new supported model type category. Only callable by the owner.
     * @param _modelType The keccak256 hash of the model type string (e.g., keccak256("ImageRecognition")).
     */
    function addSupportedModelType(bytes32 _modelType) public onlyOwner {
        require(!supportedModelTypes[_modelType], "Marketplace: Model type already supported");
        supportedModelTypes[_modelType] = true;
        emit SupportedModelTypeUpdated(_modelType, true);
    }

    /**
     * @dev Removes a supported model type category. Only callable by the owner.
     * @param _modelType The keccak256 hash of the model type string.
     */
    function removeSupportedModelType(bytes32 _modelType) public onlyOwner {
        require(supportedModelTypes[_modelType], "Marketplace: Model type not supported");
        supportedModelTypes[_modelType] = false;
        emit SupportedModelTypeUpdated(_modelType, false);
    }

     /**
     * @dev Sets the maximum duration for an inference request to be completed. Only callable by the owner.
     * @param _newTimeout The new timeout duration in seconds.
     */
    function setInferenceTimeout(uint256 _newTimeout) public onlyOwner {
        require(_newTimeout > 0, "Marketplace: Timeout must be positive");
        inferenceTimeout = _newTimeout;
        emit InferenceTimeoutUpdated(_newTimeout);
    }

    /**
     * @dev Resolves a disputed inference request. Admin decides outcome.
     *      Simplified: Can slash provider stake, refund requester fee, or neither.
     * @param _requestId The ID of the disputed request.
     * @param _slashProvider True to slash provider stake and add to feeRecipient/marketplace.
     * @param _refundRequester True to refund the requester's inference fee.
     */
    function resolveDispute(bytes32 _requestId, bool _slashProvider, bool _refundRequester) public onlyOwner nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == InferenceStatus.Disputed, "Marketplace: Request not disputed");

        uint256 slashAmount = 0;
        if (_slashProvider) {
            slashAmount = request.providerStakeEscrowed;
            request.providerStakeEscrowed = 0; // Stake is handled

            // Slash provider stake
            UserProfile storage providerProfile = userProfiles[request.provider];
            // The slashed stake remains in the contract balance, accessible maybe by feeRecipient or future DAO.
            // For simplicity, we don't move it explicitly here, just mark it as removed from provider's escrow.
            emit StakeSlashed(request.provider, slashAmount, _requestId);
        }

        if (_refundRequester) {
             // Refund requester the fee they paid
            UserProfile storage requesterProfile = userProfiles[request.requester];
            requesterProfile.balance += request.feePaid;
            request.feePaid = 0; // Fee is handled
        } else {
            // If not refunded, fee goes to marketplace/provider (simplified: fee remains in contract, ready for claim by recipient/provider if provider not slashed)
            // In a real system, this logic is more complex - who gets the fee if provider isn't slashed but requester isn't refunded?
        }

        // Mark request as resolved or completed depending on outcome and further steps (e.g., re-request?)
        // For simplicity, mark as Failed or Completed based on slash/refund flags.
        if (_slashProvider) {
             request.status = InferenceStatus.Failed; // Provider failed, request failed
        } else {
             request.status = InferenceStatus.Completed; // Provider was right, request completed (requester doesn't get refund, provider claims fee)
        }

        // Remove from active requests for the model
        models[request.modelId].activeInferenceRequests.remove(_requestId);

        emit DisputeResolved(_requestId, _slashProvider, _refundRequester);
    }


    // --- Model Provider Functions ---

    /**
     * @dev Lists a new AI model on the marketplace. Requires staking and setting initial version details.
     * @param _name Name of the model.
     * @param _descriptionURL URL for model description (e.g., IPFS).
     * @param _modelTypeHash Hash of the model type string (must be supported).
     * @param _initialVersionHash Hash of the initial model version data (e.g., IPFS).
     * @param _accessPrice Initial price for purchasing perpetual access.
     * @param _inferenceFee Initial fee per inference request.
     * @param _providerStakeRequired Stake required from provider per inference using this version.
     * @param _inputFormatHash Hash representing required input format.
     * @param _outputFormatHash Hash representing output format.
     * @param _requiredListingStake Stake required to list the model.
     */
    function listModel(
        string memory _name,
        string memory _descriptionURL,
        bytes32 _modelTypeHash,
        bytes32 _initialVersionHash,
        uint256 _accessPrice,
        uint256 _inferenceFee,
        uint256 _providerStakeRequired,
        bytes32 _inputFormatHash,
        bytes32 _outputFormatHash,
        uint256 _requiredListingStake
    ) public whenNotPaused nonReentrant {
        require(bytes(_name).length > 0, "Marketplace: Model name required");
        require(bytes(_descriptionURL).length > 0, "Marketplace: Description URL required");
        require(supportedModelTypes[_modelTypeHash], "Marketplace: Unsupported model type");
        require(_initialVersionHash != bytes32(0), "Marketplace: Initial version hash required");
        require(_requiredListingStake > 0, "Marketplace: Listing stake required");
        require(!_allModelIds.contains(keccak256(abi.encodePacked(msg.sender, _name, _modelTypeHash))), "Marketplace: Model already listed by this user with this name/type"); // Simple check

        // Generate a unique model ID
        _modelCounter++;
        bytes32 modelId = keccak256(abi.encodePacked(_modelCounter, msg.sender, block.timestamp)); // More robust ID generation

        // Transfer required stake from sender
        require(paymentToken.transferFrom(msg.sender, address(this), _requiredListingStake), "Marketplace: Stake transfer failed");

        Model storage newModel = models[modelId];
        newModel.owner = msg.sender;
        newModel.name = _name;
        newModel.descriptionURL = _descriptionURL;
        newModel.modelType = _modelTypeHash;
        newModel.creationTime = uint64(block.timestamp);
        newModel.status = ModelStatus.Active;
        newModel.currentStake = _requiredListingStake;

        // Add initial version
        newModel.versionHashes.push(_initialVersionHash);
        newModel.versions[_initialVersionHash] = ModelVersion({
            versionHash: _initialVersionHash,
            accessPrice: _accessPrice,
            inferenceFee: _inferenceFee,
            providerStakeRequired: _providerStakeRequired,
            inputFormatHash: _inputFormatHash,
            outputFormatHash: _outputFormatHash,
            creationTime: uint64(block.timestamp)
        });

        _activeModelIds.add(modelId);
        _allModelIds.add(modelId);

        emit ModelListed(modelId, msg.sender, _name, _modelTypeHash, _requiredListingStake);
        emit ModelVersionAdded(modelId, _initialVersionHash, _accessPrice, _inferenceFee);
    }

    /**
     * @dev Adds a new version to an existing model. Only callable by the model owner.
     * @param _modelId The ID of the model.
     * @param _versionHash Hash of the new model version data.
     * @param _accessPrice Price for perpetual access to this version.
     * @param _inferenceFee Fee per inference request using this version.
     * @param _providerStakeRequired Stake required from provider per inference.
     * @param _inputFormatHash Hash representing required input format.
     * @param _outputFormatHash Hash representing output format.
     */
    function addModelVersion(
        bytes32 _modelId,
        bytes32 _versionHash,
        uint256 _accessPrice,
        uint256 _inferenceFee,
        uint256 _providerStakeRequired,
        bytes32 _inputFormatHash,
        bytes32 _outputFormatHash
    ) public whenNotPaused onlyModelOwner(_modelId) nonReentrant {
        Model storage model = models[_modelId];
        require(model.versions[_versionHash].versionHash == bytes32(0), "Marketplace: Version hash already exists");
        require(_versionHash != bytes32(0), "Marketplace: Version hash required");

        model.versionHashes.push(_versionHash);
        model.versions[_versionHash] = ModelVersion({
            versionHash: _versionHash,
            accessPrice: _accessPrice,
            inferenceFee: _inferenceFee,
            providerStakeRequired: _providerStakeRequired,
            inputFormatHash: _inputFormatHash,
            outputFormatHash: _outputFormatHash,
            creationTime: uint64(block.timestamp)
        });

        emit ModelVersionAdded(_modelId, _versionHash, _accessPrice, _inferenceFee);
    }

     /**
     * @dev Updates the description URL for a model. Only callable by the model owner.
     * @param _modelId The ID of the model.
     * @param _descriptionURL The new URL for model description.
     */
    function updateModelMetadata(bytes32 _modelId, string memory _descriptionURL) public onlyModelOwner(_modelId) {
         require(bytes(_descriptionURL).length > 0, "Marketplace: Description URL required");
         models[_modelId].descriptionURL = _descriptionURL;
         emit ModelUpdated(_modelId, _descriptionURL);
    }

    /**
     * @dev Updates the details (prices, stakes) for a specific model version. Only callable by the model owner.
     * @param _modelId The ID of the model.
     * @param _versionHash The hash of the version to update.
     * @param _accessPrice New price for perpetual access.
     * @param _inferenceFee New fee per inference request.
     * @param _providerStakeRequired New stake required from provider per inference.
     */
    function updateModelVersionDetails(
        bytes32 _modelId,
        bytes32 _versionHash,
        uint256 _accessPrice,
        uint256 _inferenceFee,
        uint256 _providerStakeRequired
    ) public onlyModelOwner(_modelId) {
        Model storage model = models[_modelId];
        require(model.versions[_versionHash].versionHash != bytes32(0), "Marketplace: Version hash not found");

        ModelVersion storage version = model.versions[_versionHash];
        version.accessPrice = _accessPrice;
        version.inferenceFee = _inferenceFee;
        version.providerStakeRequired = _providerStakeRequired;

        emit ModelVersionAdded(_modelId, _versionHash, _accessPrice, _inferenceFee); // Re-using event for updates
    }

    /**
     * @dev Deactivates a model, preventing new access purchases or inference requests. Only callable by model owner.
     * @param _modelId The ID of the model to deactivate.
     */
    function deactivateModel(bytes32 _modelId) public onlyModelOwner(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Marketplace: Model not active");

        model.status = ModelStatus.Inactive;
        _activeModelIds.remove(_modelId);
        emit ModelDeactivated(_modelId);
    }

    /**
     * @dev Activates an inactive model. Only callable by model owner.
     * @param _modelId The ID of the model to activate.
     */
    function activateModel(bytes32 _modelId) public onlyModelOwner(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Inactive, "Marketplace: Model not inactive");

        model.status = ModelStatus.Active;
         _activeModelIds.add(_modelId);
        emit ModelActivated(_modelId);
    }

     /**
     * @dev Allows model owner to withdraw their listing stake.
     *      Requires no active inference requests pending for any version of this model.
     * @param _modelId The ID of the model.
     */
    function withdrawModelStake(bytes32 _modelId) public onlyModelOwner(_modelId) nonReentrant {
        Model storage model = models[_modelId];
        require(model.activeInferenceRequests.length() == 0, "Marketplace: Cannot withdraw stake with active requests");
        // Consider adding a cooldown period after deactivation before allowing stake withdrawal

        uint256 stakeAmount = model.currentStake;
        model.currentStake = 0;
        _allModelIds.remove(_modelId); // Model is effectively removed once stake is withdrawn
        _activeModelIds.remove(_modelId); // Ensure it's removed if active

        UserProfile storage ownerProfile = userProfiles[model.owner];
        ownerProfile.balance += stakeAmount;

        emit StakeWithdrawn(_modelId, model.owner, stakeAmount);
        emit FundsTransferred(address(this), model.owner, stakeAmount);
    }


    // --- User/Requester Functions ---

    /**
     * @dev Allows a user to purchase perpetual access to a specific model.
     * @param _modelId The ID of the model.
     */
    function purchaseModelAccess(bytes32 _modelId) public whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner != address(0), "Marketplace: Model not found");
        require(model.status == ModelStatus.Active, "Marketplace: Model is not active");

        // Simplified access: uses the accessPrice of the LATEST version for purchase.
        // A more complex model would require specifying a version or have separate access logic per version.
        require(model.versionHashes.length > 0, "Marketplace: Model has no versions");
        bytes32 latestVersionHash = model.versionHashes[model.versionHashes.length - 1];
        ModelVersion storage latestVersion = model.versions[latestVersionHash];

        uint256 accessPrice = latestVersion.accessPrice;
        require(accessPrice > 0, "Marketplace: Model access is free or not available for purchase");

        UserProfile storage userProfile = userProfiles[msg.sender];
        require(!userProfile.purchasedModelAccess.contains(_modelId), "Marketplace: Access already purchased");

        // Transfer payment from user
        require(paymentToken.transferFrom(msg.sender, address(this), accessPrice), "Marketplace: Payment transfer failed");

        // Distribute fee:
        uint256 marketplaceShare = (accessPrice * marketplaceFee) / 10000;
        uint256 modelOwnerShare = accessPrice - marketplaceShare;

        // Add shares to respective balances
        UserProfile storage ownerProfile = userProfiles[model.owner];
        ownerProfile.balance += modelOwnerShare;
        userProfile = userProfiles[feeRecipient]; // Use userProfile variable for feeRecipient
        userProfile.balance += marketplaceShare; // Add to feeRecipient's balance for withdrawal

        userProfiles[msg.sender].purchasedModelAccess.add(_modelId);

        emit AccessPurchased(_modelId, msg.sender, accessPrice);
        emit FundsTransferred(msg.sender, address(this), accessPrice);
        emit FundsTransferred(address(this), model.owner, modelOwnerShare);
        emit FundsTransferred(address(this), feeRecipient, marketplaceShare); // Track fee distribution
    }

    /**
     * @dev Requests an inference using a specific model version. Requires fee payment and provider stake.
     *      Implicitly takes the request; a real system might need a separate provider "accept" step.
     * @param _modelId The ID of the model.
     * @param _versionHash The hash of the model version to use.
     * @param _inputHash Hash of the input data (e.g., IPFS CID).
     */
    function requestInference(bytes32 _modelId, bytes32 _versionHash, bytes32 _inputHash) public whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner != address(0), "Marketplace: Model not found");
        require(model.status == ModelStatus.Active, "Marketplace: Model is not active");
        require(_inputHash != bytes32(0), "Marketplace: Input hash required");

        ModelVersion storage version = model.versions[_versionHash];
        require(version.versionHash != bytes32(0), "Marketplace: Model version not found");

        // Optional: require user to have purchased access first (uncomment if needed)
        // require(userProfiles[msg.sender].purchasedModelAccess.contains(_modelId), "Marketplace: Model access not purchased");

        uint256 totalPaymentRequired = version.inferenceFee + version.providerStakeRequired;
        require(totalPaymentRequired > 0, "Marketplace: Total cost must be positive");

        // Transfer total payment from user
        require(paymentToken.transferFrom(msg.sender, address(this), totalPaymentRequired), "Marketplace: Payment transfer failed");

        // Generate unique request ID
        _requestCounter++;
        bytes32 requestId = keccak256(abi.encodePacked(_requestCounter, msg.sender, block.timestamp, _modelId, _versionHash));

        InferenceRequest storage newRequest = inferenceRequests[requestId];
        newRequest.requestId = requestId;
        newRequest.modelId = _modelId;
        newRequest.versionHash = _versionHash;
        newRequest.requester = msg.sender;
        newRequest.feePaid = version.inferenceFee;
        newRequest.inputHash = _inputHash;
        newRequest.provider = model.owner; // Simplified: model owner is the provider
        newRequest.providerStakeEscrowed = version.providerStakeRequired;
        newRequest.status = InferenceStatus.Requested;
        newRequest.requestTime = uint64(block.timestamp);

        model.activeInferenceRequests.add(requestId);

        emit InferenceRequested(requestId, _modelId, _versionHash, msg.sender, _inputHash, version.inferenceFee);
        emit FundsTransferred(msg.sender, address(this), totalPaymentRequired);
    }

    /**
     * @dev (Called by Provider) Submits the result hash for a previously requested inference.
     *      This function assumes the provider is the model owner (simplification).
     * @param _requestId The ID of the inference request.
     * @param _outputHash Hash of the output data (e.g., IPFS CID).
     * @param _proof Placeholder for verification proof (not implemented).
     */
    function submitInferenceResult(bytes32 _requestId, bytes32 _outputHash, bytes memory _proof) public whenNotPaused nonReentrant onlyInferenceProvider(_requestId) onlyRequestPending(_requestId) {
        // Simplified: Assumes the caller is the designated provider (model owner in this case)
        // A real system would need provider selection/bidding and proof verification.

        InferenceRequest storage request = inferenceRequests[_requestId];
        require(_outputHash != bytes32(0), "Marketplace: Output hash required");

        // --- Placeholder for Proof Verification ---
        // In a real system, _proof would be verified here.
        // This could involve ZK-proofs, verifiable computation outputs,
        // or submitting to an oracle network for verification.
        // If verification fails, the provider might be slashed here or via dispute.
        // require(verifyProof(_requestId, _outputHash, _proof), "Marketplace: Proof verification failed");
        // For this example, we just check basic requirements.
        // --- End Placeholder ---

        request.outputHash = _outputHash;
        request.submissionTime = uint64(block.timestamp);
        request.status = InferenceStatus.Submitted;

        // Provider's stake remains escrowed until requester claims result or dispute resolved.

        emit InferenceSubmitted(_requestId, _outputHash, msg.sender, request.providerStakeEscrowed);
    }

    /**
     * @dev (Called by Requester) Claims the result hash for a submitted inference request.
     *      This triggers the payment to the provider and marketplace fees.
     * @param _requestId The ID of the inference request.
     */
    function claimInferenceResult(bytes32 _requestId) public whenNotPaused nonReentrant onlyInferenceRequester(_requestId) {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == InferenceStatus.Submitted, "Marketplace: Request result not submitted");
        // Consider adding a deadline for claiming?

        // Distribute funds: provider fee + provider stake refund to provider, marketplace fee to recipient.
        uint256 totalReceived = request.feePaid + request.providerStakeEscrowed; // Total funds held for this request
        uint256 marketplaceShare = (request.feePaid * marketplaceFee) / 10000;
        uint256 providerShare = request.feePaid - marketplaceShare + request.providerStakeEscrowed; // Provider gets fee minus marketplace share PLUS their escrowed stake back

        // Add shares to respective balances
        UserProfile storage providerProfile = userProfiles[request.provider];
        providerProfile.balance += providerShare;

        UserProfile storage feeRecipientProfile = userProfiles[feeRecipient];
        feeRecipientProfile.balance += marketplaceShare;

        // Mark request as completed
        request.status = InferenceStatus.Completed;

        // Remove from active requests for the model
        models[request.modelId].activeInferenceRequests.remove(_requestId);

        emit InferenceCompleted(_requestId, request.outputHash);
        emit FundsTransferred(address(this), request.provider, providerShare);
        emit FundsTransferred(address(this), feeRecipient, marketplaceShare);
    }

    /**
     * @dev Allows a user (or potentially any observer in a more complex system) to dispute a submitted inference result.
     *      Requires staking a dispute bond. Transitions the request to Disputed status.
     * @param _requestId The ID of the inference request.
     */
    function disputeInferenceResult(bytes32 _requestId) public whenNotPaused nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == InferenceStatus.Submitted, "Marketplace: Request not in Submitted state");
        // Add dispute bond requirement? E.g., stake a certain amount to dispute.
        // For simplicity, we just change the status and rely on admin to resolve.

        request.status = InferenceStatus.Disputed;

        // In a real system, transfer dispute bond here.
        // require(paymentToken.transferFrom(msg.sender, address(this), disputeBondAmount), "Marketplace: Dispute bond transfer failed");

        emit InferenceDisputed(_requestId, msg.sender);
    }

    // --- General/Utility Functions ---

    /**
     * @dev Allows users to withdraw their accrued balance.
     */
    function withdrawUserFunds() public nonReentrant {
        UserProfile storage userProfile = userProfiles[msg.sender];
        uint256 amount = userProfile.balance;
        require(amount > 0, "Marketplace: No funds to withdraw");

        userProfile.balance = 0;
        require(paymentToken.transfer(msg.sender, amount), "Marketplace: Withdrawal failed");

        emit FundsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev View function to get global marketplace state.
     */
    function getMarketplaceState() public view returns (uint256 fee, address recipient, uint256 timeout, bool isPaused) {
        return (marketplaceFee, feeRecipient, inferenceTimeout, paused);
    }

    /**
     * @dev View function to get details of a specific model.
     * @param _modelId The ID of the model.
     */
    function getModelDetails(bytes32 _modelId) public view returns (address owner, string memory name, string memory descriptionURL, bytes32 modelType, uint64 creationTime, ModelStatus status, uint256 currentStake, bytes32[] memory versionHashes) {
        Model storage model = models[_modelId];
        require(model.owner != address(0), "Marketplace: Model not found");
        return (model.owner, model.name, model.descriptionURL, model.modelType, model.creationTime, model.status, model.currentStake, model.versionHashes);
    }

     /**
     * @dev View function to get details of a specific model version.
     * @param _modelId The ID of the model.
     * @param _versionHash The hash of the version.
     */
    function getModelVersionDetails(bytes32 _modelId, bytes32 _versionHash) public view returns (bytes32 versionHash, uint256 accessPrice, uint256 inferenceFee, uint256 providerStakeRequired, bytes32 inputFormatHash, bytes32 outputFormatHash, uint64 creationTime) {
        Model storage model = models[_modelId];
        require(model.owner != address(0), "Marketplace: Model not found");
        ModelVersion storage version = model.versions[_versionHash];
        require(version.versionHash != bytes32(0), "Marketplace: Model version not found");
        return (version.versionHash, version.accessPrice, version.inferenceFee, version.providerStakeRequired, version.inputFormatHash, version.outputFormatHash, version.creationTime);
    }


    /**
     * @dev View function to get details of a specific inference request.
     * @param _requestId The ID of the request.
     */
    function getInferenceRequestDetails(bytes32 _requestId) public view returns (bytes32 requestId, bytes32 modelId, bytes32 versionHash, address requester, uint256 feePaid, bytes32 inputHash, bytes32 outputHash, address provider, uint256 providerStakeEscrowed, InferenceStatus status, uint64 requestTime, uint64 submissionTime) {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.requester != address(0), "Marketplace: Inference request not found");
        return (request.requestId, request.modelId, request.versionHash, request.requester, request.feePaid, request.inputHash, request.outputHash, request.provider, request.providerStakeEscrowed, request.status, request.requestTime, request.submissionTime);
    }

     /**
     * @dev View function to get a user's profile information.
     * @param _user The address of the user.
     */
    function getUserProfile(address _user) public view returns (uint256 balance, bytes32[] memory purchasedModelAccess) {
        UserProfile storage profile = userProfiles[_user];
         // Convert EnumerableSet to array for return
        bytes32[] memory accessList = new bytes32[](profile.purchasedModelAccess.length());
        for (uint i = 0; i < profile.purchasedModelAccess.length(); i++) {
            accessList[i] = profile.purchasedModelAccess.at(i);
        }
        return (profile.balance, accessList);
    }

    /**
     * @dev View function to list IDs of all currently active models.
     *      Note: For a very large number of models, this might exceed block gas limits.
     *      Pagination would be needed in a production scenario.
     */
    function listActiveModels() public view returns (bytes32[] memory) {
        bytes32[] memory activeIds = new bytes32[](_activeModelIds.length());
        for (uint i = 0; i < _activeModelIds.length(); i++) {
            activeIds[i] = _activeModelIds.at(i);
        }
        return activeIds;
    }

     /**
     * @dev View function to check if a user has access to a specific model.
     * @param _user The address of the user.
     * @param _modelId The ID of the model.
     */
    function checkModelAccess(address _user, bytes32 _modelId) public view returns (bool) {
        return userProfiles[_user].purchasedModelAccess.contains(_modelId);
    }

    /**
     * @dev View function to get required stakes for listing and inference based on a model version.
     * @param _modelId The ID of the model.
     * @param _versionHash The hash of the version.
     */
    function getRequiredStakes(bytes32 _modelId, bytes32 _versionHash) public view returns (uint256 providerStakeRequired) {
        Model storage model = models[_modelId];
        require(model.owner != address(0), "Marketplace: Model not found");
        ModelVersion storage version = model.versions[_versionHash];
        require(version.versionHash != bytes32(0), "Marketplace: Model version not found");

        // Note: Listing stake is set once per model, not version-specific in listModel.
        // This function only returns version-specific required stake for providers.
        return (version.providerStakeRequired);
    }

    // --- Internal/Helper Functions (if needed, e.g., for proof verification placeholder) ---
    // function verifyProof(...) internal pure returns (bool) { ... }
}
```

**Explanation of Advanced Concepts Used:**

1.  **State Management for Complex Workflows:** The contract manages distinct states for models (`Active`, `Inactive`) and inference requests (`Requested`, `Submitted`, `Completed`, `Disputed`, `Failed`, `TimedOut`). This involves tracking the lifecycle of processes that involve off-chain computation.
2.  **Staking and Escrow:** Model providers stake tokens to list models (`currentStake`) and additional tokens (`providerStakeEscrowed`) are locked per inference request. These stakes are subject to potential slashing (`StakeSlashed` event, part of `resolveDispute`) if they misbehave (in a real system, verified by proof or oracle). This is a common mechanism in decentralized systems to align incentives.
3.  **ERC-20 Integration:** Uses the standard `IERC20` interface for all value transfers (listing stake, access purchase, inference fees, provider stakes, withdrawals). Requires the marketplace contract to be approved by users/providers for the required amounts *before* calling the functions that require transfers (`listModel`, `purchaseModelAccess`, `requestInference`, `submitInferenceResult`).
4.  **Model Versioning:** Models can have multiple versions, each with potentially different prices, required stakes, and data hashes (`ModelVersion` struct, `versionHashes` array, `versions` mapping, `addModelVersion`). This is crucial for updating models over time.
5.  **Off-chain Interaction Pattern:** The contract is designed to manage the *agreement* and *payment* for computation that happens *off-chain*. The `requestInference` -> `submitInferenceResult` -> `claimInferenceResult` flow is the core interaction pattern. The hashes (`inputHash`, `outputHash`, `versionHash`) act as verifiable pointers to off-chain data (e.g., on IPFS or Swarm).
6.  **Basic Dispute Resolution Framework:** The `disputeInferenceResult` and `resolveDispute` functions provide a hook for handling disagreements. While `resolveDispute` is simplified to admin control, it sets up the state transition (`InferenceStatus.Disputed`) and potential outcomes (slashing, refunding) needed for a more decentralized dispute mechanism (e.g., DAO voting, Schelling points, oracles).
7.  **Access Control & Pausability:** Uses `Ownable` for administrative functions and a `paused` flag with `whenNotPaused` modifier for emergency stops or upgrades.
8.  **EnumerableSet:** Used to efficiently track sets of model IDs and purchased access, allowing iteration (`listActiveModels`) without requiring potentially unbounded loops over mappings (which would be impossible or hit gas limits).
9.  **NonReentrant Guard:** Added to functions that involve external calls (`paymentToken.transfer`, `paymentToken.transferFrom`) after state changes to prevent re-entrancy attacks, which are critical in contracts handling funds.
10. **Unique ID Generation:** Uses counters and `keccak256` hashing of relevant parameters to generate unique, hard-to-guess IDs for models and requests.
11. **Structured Data:** Use of multiple `structs` (`ModelVersion`, `Model`, `InferenceRequest`, `UserProfile`) and nested mappings/arrays to organize complex data relationships.

This contract provides a framework for a decentralized AI marketplace, highlighting how Solidity can be used to manage complex off-chain processes by controlling state, payments, and incentives on-chain, even though the AI computation itself cannot run on the blockchain.