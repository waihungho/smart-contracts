Okay, let's design a smart contract that acts as a **Decentralized AI Model Marketplace with Oracle Integration, Reputation, and Dispute Resolution**.

This concept is advanced because it involves:
1.  **Managing Access to Off-chain Resources:** The AI models themselves run off-chain due to computational limitations, but the *access rights* and *payment logic* are on-chain.
2.  **Oracle Interaction:** It relies on an oracle to trigger off-chain computation and receive results.
3.  **Reputation System:** Incorporates on-chain ratings for models and providers.
4.  **Dispute Resolution:** Provides a mechanism for users/providers to dispute results or access issues, managed by a decentralized governing body.
5.  **Stakeholder Roles:** Defines roles like Model Providers, Users, and Governors.

We will avoid duplicating standard ERC20/ERC721 logic directly but build marketplace mechanics around assumed resources (like payments in Ether, or access grants which could *eventually* be represented by non-transferable NFTs or SFTs, but we'll keep it simpler with struct mapping for this example).

---

**Contract: DecentralizedAIModelMarketplace**

**Outline:**

1.  **State Variables & Data Structures:** Define core mappings, structs (Model, AccessGrant, InferenceRequest, Rating, Dispute), enums, counters, and addresses for roles (Governors, Oracle).
2.  **Events:** Declare events for tracking key actions (Model Registered, Access Purchased, Inference Requested, Result Fulfilled, Dispute Filed, etc.).
3.  **Modifiers:** Define access control modifiers (`onlyGovernor`, `onlyModelProvider`, `onlyOracle`).
4.  **Constructor:** Initialize the contract, setting the initial owner/governor.
5.  **Governor/Admin Functions:** Functions for managing governors, setting platform fees, and withdrawing platform fees.
6.  **Oracle Management:** Function to set the trusted oracle address.
7.  **Model Provider Functions:**
    *   Registering new models.
    *   Updating model metadata and parameters (price, stake).
    *   Staking collateral for a model.
    *   Withdrawing staked collateral.
    *   Deprecating or activating models.
    *   Updating model versions (e.g., pointing to a new IPFS hash).
    *   Withdrawing earnings from model usage.
8.  **Model User Functions:**
    *   Purchasing access grants.
    *   Requesting off-chain inference using a purchased grant.
    *   Submitting ratings for models and providers after usage.
    *   Disputing inference results or access issues.
9.  **Oracle Callback Function:** A function exclusively callable by the trusted oracle to fulfill inference requests.
10. **Dispute Resolution Functions:** Functions for governors to review and resolve filed disputes.
11. **View Functions:** Functions to query contract state (model details, user grants, etc.).
12. **Pause/Unpause:** Emergency functions.

**Function Summary (27 Functions):**

*   `constructor()`: Initializes the contract with an owner who is also the first governor.
*   `setPlatformFee(uint256 _feePercentage)`: Governor sets the percentage of earnings taken as platform fee.
*   `withdrawPlatformFees()`: Governor withdraws accumulated platform fees.
*   `addGovernor(address _newGovernor)`: Governor adds a new approved governor.
*   `removeGovernor(address _governor)`: Governor removes an approved governor.
*   `renounceGovernor()`: A governor removes themselves.
*   `setOracleAddress(address _oracleAddress)`: Governor sets the address of the trusted oracle contract.
*   `registerModel(string memory _metadataHash, uint256 _pricePerUse, uint256 _stakeRequired)`: Provider registers a new AI model.
*   `updateModelMetadata(uint256 _modelId, string memory _metadataHash)`: Provider updates the metadata hash (e.g., IPFS) for a model.
*   `updateModelParameters(uint256 _modelId, uint256 _newPricePerUse, uint256 _newStakeRequired)`: Provider updates price and stake requirements.
*   `stakeForModel(uint256 _modelId)`: Provider stakes the required Ether collateral for their model.
*   `withdrawStake(uint256 _modelId)`: Provider withdraws their stake (subject to conditions like no open disputes).
*   `setModelActiveStatus(uint256 _modelId, bool _isActive)`: Provider or governor activates/deactivates a model.
*   `setModelVersion(uint256 _modelId, uint256 _newVersion, string memory _newMetadataHash)`: Provider registers a new version of an existing model.
*   `withdrawEarnings(uint256 _modelId)`: Provider withdraws their accumulated earnings from model usage.
*   `purchaseModelAccess(uint256 _modelId, uint256 _numberOfUses)`: User pays Ether to purchase a certain number of uses for a model.
*   `requestInference(uint256 _grantId, string memory _inputDataHash)`: User requests an off-chain inference execution using an access grant. Calls the trusted oracle.
*   `fulfillInferenceCallback(bytes32 _oracleRequestId, string memory _resultDataHash, string memory _error)`: *Callable only by the trusted Oracle.* Processes the result received from the off-chain computation.
*   `submitModelRating(uint256 _modelId, uint8 _score, string memory _commentHash)`: User submits a rating for a model (e.g., after inference).
*   `submitProviderRating(address _providerAddress, uint8 _score, string memory _commentHash)`: User submits a rating for a model provider.
*   `disputeInferenceResult(uint256 _inferenceRequestId, string memory _reasonHash)`: User disputes the result of an inference request.
*   `disputeAccessGrant(uint256 _grantId, string memory _reasonHash)`: User disputes an issue with an access grant (e.g., couldn't use it).
*   `resolveDispute(uint256 _disputeId, bool _grantFavorSubmitter, string memory _resolutionDetailsHash)`: Governor resolves a dispute, potentially refunding user or penalizing provider stake.
*   `getModelDetails(uint256 _modelId)`: View function: Gets details of a specific model.
*   `listActiveModels()`: View function: Gets a list of active model IDs and basic info.
*   `getUserAccessGrants(address _user)`: View function: Gets a list of access grants for a user.
*   `getAccessGrantDetails(uint256 _grantId)`: View function: Gets details of a specific access grant.
*   `pause()`: Governor pauses the contract in case of emergency.
*   `unpause()`: Governor unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial ownership, Governors handle ongoing management

// --- OUTLINE ---
// 1. State Variables & Data Structures
// 2. Events
// 3. Modifiers
// 4. Constructor
// 5. Governor/Admin Functions
// 6. Oracle Management
// 7. Model Provider Functions
// 8. Model User Functions
// 9. Oracle Callback Function
// 10. Dispute Resolution Functions
// 11. View Functions
// 12. Pause/Unpause

// --- FUNCTION SUMMARY (27 Functions) ---
// constructor()
// setPlatformFee(uint256 _feePercentage)
// withdrawPlatformFees()
// addGovernor(address _newGovernor)
// removeGovernor(address _governor)
// renounceGovernor()
// setOracleAddress(address _oracleAddress)
// registerModel(string memory _metadataHash, uint256 _pricePerUse, uint256 _stakeRequired)
// updateModelMetadata(uint256 _modelId, string memory _metadataHash)
// updateModelParameters(uint256 _modelId, uint256 _newPricePerUse, uint256 _newStakeRequired)
// stakeForModel(uint256 _modelId)
// withdrawStake(uint256 _modelId)
// setModelActiveStatus(uint256 _modelId, bool _isActive)
// setModelVersion(uint256 _modelId, uint256 _newVersion, string memory _newMetadataHash)
// withdrawEarnings(uint256 _modelId)
// purchaseModelAccess(uint256 _modelId, uint256 _numberOfUses)
// requestInference(uint256 _grantId, string memory _inputDataHash)
// fulfillInferenceCallback(bytes32 _oracleRequestId, string memory _resultDataHash, string memory _error)
// submitModelRating(uint256 _modelId, uint8 _score, string memory _commentHash)
// submitProviderRating(address _providerAddress, uint8 _score, string memory _commentHash)
// disputeInferenceResult(uint256 _inferenceRequestId, string memory _reasonHash)
// disputeAccessGrant(uint256 _grantId, string memory _reasonHash)
// resolveDispute(uint256 _disputeId, bool _grantFavorSubmitter, string memory _resolutionDetailsHash)
// getModelDetails(uint256 _modelId)
// listActiveModels()
// getUserAccessGrants(address _user)
// getAccessGrantDetails(uint256 _grantId)
// pause()
// unpause()

contract DecentralizedAIModelMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- 1. State Variables & Data Structures ---

    address private oracleAddress; // Trusted oracle contract address
    uint256 public platformFeePercentage; // Percentage fee taken by the platform (0-10000 for 0-100%)
    uint256 public totalPlatformFees; // Accumulated fees

    Counters.Counter private _modelIds;
    Counters.Counter private _grantIds;
    Counters.Counter private _inferenceRequestIds;
    Counters.Counter private _disputeIds;

    mapping(uint256 => Model) public models;
    mapping(uint256 => AccessGrant) public accessGrants;
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => bool) public isGovernor;
    mapping(uint256 => mapping(bytes32 => uint256)) private oracleRequestIdToInferenceId; // Mapping to link oracle request ID back

    struct Model {
        address provider;
        string metadataHash; // e.g., IPFS hash pointing to model details/interface spec
        uint256 pricePerUse; // Price in Ether
        uint256 stakeRequired; // Stake in Ether
        uint256 stakedAmount; // Current staked amount
        bool isActive; // Can be purchased and used
        uint256 version; // Model version number
        uint256 totalUses; // Total successful inferences
        uint256 totalEarnings; // Total earnings before fee
        uint256 disputeCount; // Number of disputes related to this model
        uint256 registeredTime;
        uint256 averageRatingNumerator; // Sum of ratings for average calculation
        uint256 averageRatingDenominator; // Count of ratings for average calculation
    }

    enum AccessGrantStatus { Active, UsedUp, Expired, Revoked, Disputed }

    struct AccessGrant {
        address user;
        uint256 modelId;
        uint256 initialUses; // Total uses purchased
        uint256 remainingUses; // Uses left
        uint256 purchaseTime;
        AccessGrantStatus status;
    }

    enum InferenceStatus { Pending, Fulfilled, Disputed, Failed }

    struct InferenceRequest {
        address user;
        uint256 modelId;
        uint256 grantId; // The access grant used
        string inputDataHash; // e.g., IPFS hash of input data
        string resultDataHash; // e.g., IPFS hash of result data
        uint256 requestTime;
        uint256 fulfillmentTime;
        InferenceStatus status;
        string errorMessage; // If status is Failed
        bytes32 oracleRequestId; // ID used by the oracle system
    }

    enum DisputeStatus { Open, Resolved, Canceled }
    enum DisputeType { InferenceResult, AccessGrant }

    struct Dispute {
        uint256 id; // Dispute ID
        DisputeType disputeType;
        uint256 entityId; // inferenceRequestId or grantId
        address submitter;
        string reasonHash; // e.g., IPFS hash explaining the dispute
        uint256 submissionTime;
        DisputeStatus status;
        address resolver; // Governor who resolved it
        string resolutionDetailsHash; // e.g., IPFS hash explaining the resolution
        bool favorSubmitter; // Was the dispute ruled in favor of the submitter?
    }

    // --- 2. Events ---

    event ModelRegistered(uint256 modelId, address provider, string metadataHash, uint256 pricePerUse, uint256 stakeRequired);
    event ModelUpdated(uint256 modelId, string metadataHash, uint256 pricePerUse, uint256 stakeRequired);
    event ModelStaked(uint256 modelId, address provider, uint256 amount);
    event StakeWithdrawn(uint256 modelId, address provider, uint256 amount);
    event ModelActiveStatusChanged(uint256 modelId, bool isActive);
    event ModelVersionUpdated(uint256 modelId, uint256 newVersion, string newMetadataHash);
    event EarningsWithdrawn(uint256 modelId, address provider, uint256 amount);
    event AccessGrantPurchased(uint256 grantId, uint256 modelId, address user, uint256 numberOfUses, uint256 pricePaid);
    event InferenceRequested(uint256 inferenceRequestId, uint256 grantId, uint256 modelId, address user, string inputDataHash, bytes32 oracleRequestId);
    event InferenceFulfilled(uint256 inferenceRequestId, string resultDataHash, string error);
    event ModelRatingSubmitted(uint256 modelId, address rater, uint8 score);
    event ProviderRatingSubmitted(address provider, address rater, uint8 score);
    event DisputeFiled(uint256 disputeId, DisputeType disputeType, uint256 entityId, address submitter);
    event DisputeResolved(uint256 disputeId, DisputeStatus status, bool favorSubmitter);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount);
    event GovernorAdded(address governor);
    event GovernorRemoved(address governor);
    event OracleAddressSet(address oracleAddress);
    event Paused(address by);
    event Unpaused(address by);

    // --- 3. Modifiers ---

    modifier onlyGovernor() {
        require(isGovernor[msg.sender], "Not a governor");
        _;
    }

    modifier onlyModelProvider(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Not the model provider");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not the trusted oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // Pausability state
    bool public paused;

    // --- 4. Constructor ---

    constructor() Ownable(msg.sender) {
        isGovernor[msg.sender] = true; // Initial owner is also a governor
        paused = false;
        platformFeePercentage = 0; // Start with no fee
    }

    // --- 5. Governor/Admin Functions ---

    function setPlatformFee(uint256 _feePercentage) external onlyGovernor {
        require(_feePercentage <= 10000, "Fee percentage must be <= 10000 (100%)");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() external onlyGovernor {
        uint256 amount = totalPlatformFees;
        require(amount > 0, "No fees to withdraw");
        totalPlatformFees = 0;
        // Use call for robustness, check success
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit PlatformFeesWithdrawn(amount);
    }

    function addGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Invalid address");
        isGovernor[_newGovernor] = true;
        emit GovernorAdded(_newGovernor);
    }

    function removeGovernor(address _governor) external onlyGovernor {
        require(_governor != msg.sender, "Cannot remove yourself this way");
        require(isGovernor[_governor], "Address is not a governor");
        isGovernor[_governor] = false;
        emit GovernorRemoved(_governor);
    }

    function renounceGovernor() external onlyGovernor {
         isGovernor[msg.sender] = false;
         emit GovernorRemoved(msg.sender);
    }

    // --- 6. Oracle Management ---

    function setOracleAddress(address _oracleAddress) external onlyGovernor {
        require(_oracleAddress != address(0), "Invalid address");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    // --- 7. Model Provider Functions ---

    function registerModel(string memory _metadataHash, uint256 _pricePerUse, uint256 _stakeRequired)
        external
        whenNotPaused
    {
        _modelIds.increment();
        uint256 modelId = _modelIds.current();

        models[modelId] = Model({
            provider: msg.sender,
            metadataHash: _metadataHash,
            pricePerUse: _pricePerUse,
            stakeRequired: _stakeRequired,
            stakedAmount: 0, // Stake must be added separately
            isActive: false, // Must be staked before becoming active
            version: 1,
            totalUses: 0,
            totalEarnings: 0,
            disputeCount: 0,
            registeredTime: block.timestamp,
            averageRatingNumerator: 0,
            averageRatingDenominator: 0
        });

        emit ModelRegistered(modelId, msg.sender, _metadataHash, _pricePerUse, _stakeRequired);
    }

    function updateModelMetadata(uint256 _modelId, string memory _metadataHash)
        external
        onlyModelProvider(_modelId)
        whenNotPaused
    {
        models[_modelId].metadataHash = _metadataHash;
        // Note: This doesn't update the version counter automatically
        emit ModelUpdated(_modelId, _metadataHash, models[_modelId].pricePerUse, models[_modelId].stakeRequired);
    }

    function updateModelParameters(uint256 _modelId, uint256 _newPricePerUse, uint256 _newStakeRequired)
        external
        onlyModelProvider(_modelId)
        whenNotPaused
    {
        models[_modelId].pricePerUse = _newPricePerUse;
        models[_modelId].stakeRequired = _newStakeRequired;
        // Provider might need to add more stake if requirement increased
        emit ModelUpdated(_modelId, models[_modelId].metadataHash, _newPricePerUse, _newStakeRequired);
    }

    function stakeForModel(uint256 _modelId) external payable onlyModelProvider(_modelId) whenNotPaused {
        Model storage model = models[_modelId];
        uint256 amountToStake = msg.value;
        require(amountToStake > 0, "Must stake a positive amount");

        model.stakedAmount += amountToStake;

        // Automatically activate if stake requirement is met and it was inactive
        if (!model.isActive && model.stakedAmount >= model.stakeRequired) {
            model.isActive = true;
            emit ModelActiveStatusChanged(_modelId, true);
        }

        emit ModelStaked(_modelId, msg.sender, amountToStake);
    }

    function withdrawStake(uint256 _modelId) external onlyModelProvider(_modelId) whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.disputeCount == 0, "Cannot withdraw stake with open disputes");
        require(model.stakedAmount > 0, "No stake to withdraw");
        // Optionally add checks like minimum uptime since last withdrawal, etc.

        uint256 amount = model.stakedAmount;
        model.stakedAmount = 0;
        model.isActive = false; // Deactivate when stake is fully withdrawn
        emit ModelActiveStatusChanged(_modelId, false);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Stake withdrawal failed");

        emit StakeWithdrawn(_modelId, msg.sender, amount);
    }

    function setModelActiveStatus(uint256 _modelId, bool _isActive) external onlyModelProvider(_modelId) whenNotPaused {
        Model storage model = models[_modelId];
        // Allow deactivation anytime by provider
        if (_isActive) {
             // Activation by provider requires minimum stake
            require(model.stakedAmount >= model.stakeRequired, "Insufficient stake to activate model");
        }
        model.isActive = _isActive;
        emit ModelActiveStatusChanged(_modelId, _isActive);
    }

    function setModelVersion(uint256 _modelId, uint256 _newVersion, string memory _newMetadataHash)
        external
        onlyModelProvider(_modelId)
        whenNotPaused
    {
        Model storage model = models[_modelId];
        require(_newVersion > model.version, "New version must be greater than current version");
        model.version = _newVersion;
        model.metadataHash = _newMetadataHash;
        // Potentially require additional stake or deposit for major version changes
        emit ModelVersionUpdated(_modelId, _newVersion, _newMetadataHash);
        emit ModelUpdated(_modelId, _newMetadataHash, model.pricePerUse, model.stakeRequired);
    }

    function withdrawEarnings(uint256 _modelId) external onlyModelProvider(_modelId) whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        uint256 amount = model.totalEarnings;
        require(amount > 0, "No earnings to withdraw");

        model.totalEarnings = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Earnings withdrawal failed");

        emit EarningsWithdrawn(_modelId, msg.sender, amount);
    }

    // --- 8. Model User Functions ---

    function purchaseModelAccess(uint256 _modelId, uint256 _numberOfUses)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Model storage model = models[_modelId];
        require(model.isActive, "Model is not active");
        require(_numberOfUses > 0, "Must purchase at least one use");

        uint256 totalPrice = model.pricePerUse * _numberOfUses;
        require(msg.value >= totalPrice, "Insufficient Ether sent");

        uint256 refund = msg.value - totalPrice;
        if (refund > 0) {
             // Return any excess Ether
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }

        _grantIds.increment();
        uint256 grantId = _grantIds.current();

        accessGrants[grantId] = AccessGrant({
            user: msg.sender,
            modelId: _modelId,
            initialUses: _numberOfUses,
            remainingUses: _numberOfUses,
            purchaseTime: block.timestamp,
            status: AccessGrantStatus.Active
        });

        // Calculate platform fee and provider earnings
        uint256 platformFee = (totalPrice * platformFeePercentage) / 10000;
        uint256 providerEarnings = totalPrice - platformFee;

        totalPlatformFees += platformFee;
        model.totalEarnings += providerEarnings;

        emit AccessGrantPurchased(grantId, _modelId, msg.sender, _numberOfUses, totalPrice);
    }

    function requestInference(uint256 _grantId, string memory _inputDataHash)
        external
        whenNotPaused
    {
        AccessGrant storage grant = accessGrants[_grantId];
        require(grant.user == msg.sender, "Not the owner of this grant");
        require(grant.status == AccessGrantStatus.Active, "Access grant is not active");
        require(grant.remainingUses > 0, "Access grant has no remaining uses");
        require(oracleAddress != address(0), "Oracle address not set");

        Model storage model = models[grant.modelId];
        require(model.isActive, "Associated model is not active");

        grant.remainingUses--;
        if (grant.remainingUses == 0) {
            grant.status = AccessGrantStatus.UsedUp;
        }

        _inferenceRequestIds.increment();
        uint256 inferenceRequestId = _inferenceRequestIds.current();

        // Simulate generating an oracle request ID (in a real system this would be from Chainlink VRF or similar)
        bytes32 oracleReqId = keccak256(abi.encodePacked(msg.sender, grant.modelId, block.timestamp, inferenceRequestId));

        inferenceRequests[inferenceRequestId] = InferenceRequest({
            user: msg.sender,
            modelId: grant.modelId,
            grantId: _grantId,
            inputDataHash: _inputDataHash,
            resultDataHash: "", // Will be filled by oracle
            requestTime: block.timestamp,
            fulfillmentTime: 0,
            status: InferenceStatus.Pending,
            errorMessage: "",
            oracleRequestId: oracleReqId // Store the simulated oracle ID
        });

        oracleRequestIdToInferenceId[_modelId][oracleReqId] = inferenceRequestId; // Map oracle ID back

        // In a real implementation, you would now call the oracle contract:
        // IOra cle(oracleAddress).requestComputation(oracleReqId, model.metadataHash, _inputDataHash);
        // For this example, we just emit an event.
        emit InferenceRequested(inferenceRequestId, _grantId, grant.modelId, msg.sender, _inputDataHash, oracleReqId);
    }

    // --- 9. Oracle Callback Function ---

    // This function is called by the trusted oracle contract after off-chain computation
    function fulfillInferenceCallback(bytes32 _oracleRequestId, string memory _resultDataHash, string memory _error)
        external
        onlyOracle
        whenNotPaused
    {
         // We need the modelId to look up the inference request efficiently
         // A real oracle callback might include extra data to help identify the request,
         // or we might need a different mapping approach if multiple models use the same oracle.
         // For simplicity here, we assume the oracle can provide the modelId or we find the request via oracleRequestId.
         // Let's refine the mapping: oracleRequestId -> inferenceRequestId

         // Find the inference request associated with the oracleRequestId
         // This assumes oracleRequestId is globally unique or sufficiently unique within a time window
         // A more robust mapping might be needed depending on the oracle implementation.
         uint256 inferenceRequestId = 0;
         bool found = false;
         // NOTE: Iterating mappings is inefficient. A better approach would be if the oracle
         // callback included the inferenceRequestId or modelId directly.
         // Let's modify the requestInference to pass the inferenceRequestId to the oracle
         // and have the oracle return it. Or, rely on the oracleRequestId->inferenceId mapping.
         // Given the constraint of not duplicating open-source, let's keep the oracleRequestId mapping
         // but acknowledge it might need refinement based on the actual oracle API.
         // Let's assume the oracle sends back the inferenceRequestId it was given.
         // Modifying requestInference: pass inferenceRequestId and have oracle return it.

         // --- REFINEMENT: Oracle Interaction ---
         // `requestInference` will pass `inferenceRequestId` to oracle.
         // `fulfillInferenceCallback` will receive `inferenceRequestId` back.
         // The `oracleRequestIdToInferenceId` mapping is no longer strictly necessary if the oracle returns the original ID.
         // Let's adjust `fulfillInferenceCallback` to expect the inferenceRequestId.

         // --- REVISED fulfillInferenceCallback ---
         // This function name needs to change if it expects inferenceRequestId directly.
         // Let's assume the oracle *does* return the original inferenceRequestId.
         // We need to remove the `oracleRequestIdToInferenceId` mapping and adjust the callback.

         // (Self-correction: Let's stick to the *original* plan of using `oracleRequestId` as a handle,
         // but acknowledge the lookup needs improvement if `oracleRequestId` isn't globally unique or easily mapped.
         // For this example, we will *simulate* finding the request by `oracleRequestId`.)
         // A real system would likely pass the inferenceRequestId to the oracle for direct callback lookup.
         // Let's revert to the oracleRequestId mapping, but acknowledge the complexity.
         // The current mapping `oracleRequestIdToInferenceId[_modelId][oracleReqId]` is problematic
         // as the callback doesn't inherently know the modelId easily without extra data.
         // Let's use a simpler `mapping(bytes32 => uint256)` if we *assume* the oracleRequestId is globally unique enough.
         // Okay, removing the modelId from the mapping key for simplicity in this example.

         uint256 inferId = oracleRequestIdToInferenceId[_oracleRequestId];
         require(inferId != 0, "Inference request not found for oracle ID");

         InferenceRequest storage request = inferenceRequests[inferId];
         require(request.status == InferenceStatus.Pending, "Inference request is not pending");

         request.fulfillmentTime = block.timestamp;

         if (bytes(_error).length == 0) {
             // Success
             request.status = InferenceStatus.Fulfilled;
             request.resultDataHash = _resultDataHash;
             models[request.modelId].totalUses++; // Increment successful uses
             emit InferenceFulfilled(inferId, _resultDataHash, "");
         } else {
             // Failure
             request.status = InferenceStatus.Failed;
             request.errorMessage = _error;
             // Should the grant uses be refunded? Depends on marketplace rules.
             // For now, assume failure consumes the use. Could be a dispute reason.
             emit InferenceFulfilled(inferId, "", _error);
         }

         // Remove from mapping to save gas/state over time (optional, requires Solidity >0.6 for map delete)
         // delete oracleRequestIdToInferenceId[_oracleRequestId]; // Not safe if requests could share oracle IDs (unlikely for good oracles)
         // Better: mark as fulfilled/processed and keep historical record. The mapping remains as a historical lookup.
    }

    // --- 9.bis Rating Functions --- (Added after Oracle Callback)

    function submitModelRating(uint256 _modelId, uint8 _score, string memory _commentHash)
        external
        whenNotPaused
    {
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5");
        Model storage model = models[_modelId];
        require(model.registeredTime > 0, "Model does not exist"); // Check if model exists

        // Optional: Add check if msg.sender actually *used* this model recently via a grant/inference
        // require(hasUserUsedModel(_modelId, msg.sender), "User must have used the model to rate it");

        model.averageRatingNumerator += _score;
        model.averageRatingDenominator++;

        // Store rating details if commentHash is provided (off-chain storage implied for hash)
        // Rating storage logic is complex (preventing multiple ratings, linking to specific uses).
        // For simplicity, we just update aggregate stats here. Storing full ratings
        // in a mapping would require a unique rating ID or composite key.
        // Let's just emit the event for traceability without storing individual ratings on-chain.

        emit ModelRatingSubmitted(_modelId, msg.sender, _score);
    }

    function submitProviderRating(address _providerAddress, uint8 _score, string memory _commentHash)
        external
        whenNotPaused
    {
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5");
        // Check if _providerAddress is actually a registered provider (optional)
        // require(isRegisteredProvider(_providerAddress), "Address is not a registered provider");

        // Similar to model rating, just emit for traceability
        // Aggregate provider rating storage would require a mapping: address => {numerator, denominator}

        emit ProviderRatingSubmitted(_providerAddress, msg.sender, _score);
    }

    // --- 10. Dispute Resolution Functions ---

    function disputeInferenceResult(uint256 _inferenceRequestId, string memory _reasonHash)
        external
        whenNotPaused
    {
        InferenceRequest storage request = inferenceRequests[_inferenceRequestId];
        require(request.user == msg.sender || models[request.modelId].provider == msg.sender, "Not involved in this request");
        require(request.status == InferenceStatus.Fulfilled || request.status == InferenceStatus.Failed, "Can only dispute fulfilled or failed requests");
        // Prevent multiple disputes for the same request
        require(request.status != InferenceStatus.Disputed, "Request is already under dispute");

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            disputeType: DisputeType.InferenceResult,
            entityId: _inferenceRequestId,
            submitter: msg.sender,
            reasonHash: _reasonHash,
            submissionTime: block.timestamp,
            status: DisputeStatus.Open,
            resolver: address(0),
            resolutionDetailsHash: "",
            favorSubmitter: false
        });

        request.status = InferenceStatus.Disputed; // Mark inference request as disputed
        models[request.modelId].disputeCount++; // Increment model dispute counter

        emit DisputeFiled(disputeId, DisputeType.InferenceResult, _inferenceRequestId, msg.sender);
    }

    function disputeAccessGrant(uint256 _grantId, string memory _reasonHash)
        external
        whenNotPaused
    {
        AccessGrant storage grant = accessGrants[_grantId];
        require(grant.user == msg.sender, "Not the owner of this grant");
        require(grant.status != AccessGrantStatus.Disputed, "Access grant is already under dispute");
        // Add checks like "within a reasonable time after purchase/attempted use"

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            disputeType: DisputeType.AccessGrant,
            entityId: _grantId,
            submitter: msg.sender,
            reasonHash: _reasonHash,
            submissionTime: block.timestamp,
            status: DisputeStatus.Open,
            resolver: address(0),
            resolutionDetailsHash: "",
            favorSubmitter: false
        });

        grant.status = AccessGrantStatus.Disputed; // Mark grant as disputed
        models[grant.modelId].disputeCount++; // Increment model dispute counter

        emit DisputeFiled(disputeId, DisputeType.AccessGrant, _grantId, msg.sender);
    }

    function resolveDispute(uint256 _disputeId, bool _grantFavorSubmitter, string memory _resolutionDetailsHash)
        external
        onlyGovernor
        whenNotPaused
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");

        dispute.status = DisputeStatus.Resolved;
        dispute.resolver = msg.sender;
        dispute.resolutionDetailsHash = _resolutionDetailsHash;
        dispute.favorSubmitter = _grantFavorSubmitter;

        if (dispute.disputeType == DisputeType.InferenceResult) {
            InferenceRequest storage request = inferenceRequests[dispute.entityId];
            require(request.status == InferenceStatus.Disputed, "Disputed request status mismatch");
            // Resolve the status based on the resolution
            request.status = _grantFavorSubmitter ? InferenceStatus.Failed : InferenceStatus.Fulfilled;
             if (_grantFavorSubmitter) {
                 // If user wins dispute, maybe refund the use or part of the payment
                 // This is complex and depends on rules. For this example, we might:
                 // 1. Refund the price per use to the user from provider stake.
                 // 2. Re-add the use to the grant (if not expired/used up otherwise).
                 // Let's implement simple refund from provider stake.
                 Model storage model = models[request.modelId];
                 uint256 refundAmount = model.pricePerUse; // Refund the cost of this single use
                 // Ensure provider has enough stake or earnings first
                 uint256 amountToTakeFromEarnings = 0;
                 uint256 amountToTakeFromStake = 0;

                 if (model.totalEarnings >= refundAmount) {
                     amountToTakeFromEarnings = refundAmount;
                 } else {
                     amountToTakeFromEarnings = model.totalEarnings;
                     amountToTakeFromStake = refundAmount - amountToTakeFromEarnings;
                 }

                 require(model.stakedAmount >= amountToTakeFromStake, "Provider stake insufficient for refund");

                 model.totalEarnings -= amountToTakeFromEarnings;
                 model.stakedAmount -= amountToTakeFromStake;

                 // Refund user - use call
                 (bool success, ) = payable(request.user).call{value: refundAmount}("");
                 // This require might revert the *resolution*, which could be bad.
                 // A better approach is to track failed refunds and allow users to claim later.
                 // For simplicity here, we will allow the resolution to proceed even if call fails,
                 // assuming off-chain monitoring handles failed transfers. Or, require success.
                 // Let's require success for now.
                 require(success, "Refund to user failed during dispute resolution");

                 // Decrease model use count if it was incorrectly incremented upon fulfillment
                 // (Only applicable if fulfillment incremented uses even on failure, which it didn't in our `fulfill` logic)
                 // If dispute favors submitter on a 'Fulfilled' request, we might decrease totalUses.
                 // If dispute favors submitter on a 'Failed' request, totalUses wasn't incremented, nothing to do there.
                 // Let's assume winning a dispute on a 'Fulfilled' result negates that 'use'.
                 if (request.status == InferenceStatus.Fulfilled) { // This status is before the resolution logic above
                      models[request.modelId].totalUses--;
                 }
             } else {
                 // If provider wins dispute, ensure totalUses was correctly incremented (it was in fulfill if successful)
                 // Nothing else needed here.
             }
        } else if (dispute.disputeType == DisputeType.AccessGrant) {
            AccessGrant storage grant = accessGrants[dispute.entityId];
            require(grant.status == AccessGrantStatus.Disputed, "Disputed grant status mismatch");
             // Resolve the status based on the resolution
             if (_grantFavorSubmitter) {
                 // If user wins dispute on access grant, refund the grant's value from provider stake/earnings.
                 // Calculate the value based on remaining uses or initial cost.
                 // Let's refund the *full* initial price of the grant for simplicity.
                 Model storage model = models[grant.modelId];
                 uint256 refundAmount = model.pricePerUse * grant.initialUses;

                 uint256 amountToTakeFromEarnings = 0;
                 uint256 amountToTakeFromStake = 0;

                 if (model.totalEarnings >= refundAmount) {
                     amountToTakeFromEarnings = refundAmount;
                 } else {
                     amountToTakeFromEarnings = model.totalEarnings;
                     amountToTakeFromStake = refundAmount - amountToTakeFromEarnings;
                 }

                 require(model.stakedAmount >= amountToTakeFromStake, "Provider stake insufficient for refund");

                 model.totalEarnings -= amountToTakeFromEarnings;
                 model.stakedAmount -= amountToTakeFromStake;

                 // Refund user
                 (bool success, ) = payable(grant.user).call{value: refundAmount}("");
                 require(success, "Refund to user failed during dispute resolution");

                 grant.status = AccessGrantStatus.Revoked; // Grant is now invalid
             } else {
                 // If provider wins, restore grant status if appropriate (e.g., back to Active if it was just pending use)
                 // Or leave as Disputed but resolved in provider's favor. Let's set to Revoked to prevent future use.
                 grant.status = AccessGrantStatus.Revoked; // Still can't use a disputed grant
             }
        }

        // Decrement model dispute counter
        models[dispute.disputeType == DisputeType.InferenceResult ? inferenceRequests[dispute.entityId].modelId : accessGrants[dispute.entityId].modelId].disputeCount--;


        emit DisputeResolved(_disputeId, DisputeStatus.Resolved, _grantFavorSubmitter);
    }

    // --- 11. View Functions ---

    function getModelDetails(uint256 _modelId)
        external
        view
        returns (address provider, string memory metadataHash, uint256 pricePerUse, uint256 stakeRequired, uint256 stakedAmount, bool isActive, uint256 version, uint256 totalUses, uint256 totalEarnings, uint256 disputeCount, uint256 registeredTime, uint256 averageRatingNumerator, uint256 averageRatingDenominator)
    {
        Model storage model = models[_modelId];
        // Basic check if model exists
        require(model.registeredTime > 0, "Model does not exist");

        return (
            model.provider,
            model.metadataHash,
            model.pricePerUse,
            model.stakeRequired,
            model.stakedAmount,
            model.isActive,
            model.version,
            model.totalUses,
            model.totalEarnings,
            model.disputeCount,
            model.registeredTime,
            model.averageRatingNumerator,
            model.averageRatingDenominator
        );
    }

    function listActiveModels()
        external
        view
        returns (uint256[] memory activeModelIds, string[] memory metadataHashes, uint256[] memory pricePerUses, uint256[] memory averageRatings)
    {
        uint256[] memory tempActiveModelIds = new uint256[](_modelIds.current());
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= _modelIds.current(); i++) {
            if (models[i].isActive) {
                tempActiveModelIds[activeCount] = i;
                activeCount++;
            }
        }

        uint256[] memory resultModelIds = new uint256[](activeCount);
        string[] memory resultMetadataHashes = new string[](activeCount);
        uint256[] memory resultPricePerUses = new uint256[](activeCount);
        uint256[] memory resultAverageRatings = new uint256[](activeCount);

        for (uint256 i = 0; i < activeCount; i++) {
            uint256 modelId = tempActiveModelIds[i];
            resultModelIds[i] = modelId;
            resultMetadataHashes[i] = models[modelId].metadataHash;
            resultPricePerUses[i] = models[modelId].pricePerUse;
            resultAverageRatings[i] = models[modelId].averageRatingDenominator > 0 ?
                                     models[modelId].averageRatingNumerator / models[modelId].averageRatingDenominator : 0; // Calculate average (integer division)
        }

        return (resultModelIds, resultMetadataHashes, resultPricePerUses, resultAverageRatings);
    }

    function getUserAccessGrants(address _user)
        external
        view
        returns (uint256[] memory grantIds, uint256[] memory modelIds, uint256[] memory remainingUses, AccessGrantStatus[] memory statuses)
    {
        // NOTE: Iterating through all grants is inefficient for large number of grants.
        // A better approach in production would be a separate mapping or external indexer.
        // For demonstration, we iterate up to the current grant ID counter.

        uint256[] memory tempGrantIds = new uint256[](_grantIds.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _grantIds.current(); i++) {
            if (accessGrants[i].user == _user) {
                tempGrantIds[count] = i;
                count++;
            }
        }

        uint256[] memory resultGrantIds = new uint256[](count);
        uint256[] memory resultModelIds = new uint256[](count);
        uint256[] memory resultRemainingUses = new uint256[](count);
        AccessGrantStatus[] memory resultStatuses = new AccessGrantStatus[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 grantId = tempGrantIds[i];
            AccessGrant storage grant = accessGrants[grantId];
            resultGrantIds[i] = grantId;
            resultModelIds[i] = grant.modelId;
            resultRemainingUses[i] = grant.remainingUses;
            resultStatuses[i] = grant.status;
        }

        return (resultGrantIds, resultModelIds, resultRemainingUses, resultStatuses);
    }


    function getAccessGrantDetails(uint256 _grantId)
        external
        view
        returns (address user, uint256 modelId, uint256 initialUses, uint256 remainingUses, uint256 purchaseTime, AccessGrantStatus status)
    {
        AccessGrant storage grant = accessGrants[_grantId];
        // Basic check if grant exists
        require(grant.purchaseTime > 0, "Access grant does not exist");

        return (
            grant.user,
            grant.modelId,
            grant.initialUses,
            grant.remainingUses,
            grant.purchaseTime,
            grant.status
        );
    }

    // Optional: View to check if an address is a governor
    function isGovernorAddress(address _addr) external view returns (bool) {
        return isGovernor[_addr];
    }

    // Optional: View to get dispute details
    function getDisputeDetails(uint256 _disputeId)
        external
        view
        returns (uint256 id, DisputeType disputeType, uint256 entityId, address submitter, string memory reasonHash, uint256 submissionTime, DisputeStatus status, address resolver, string memory resolutionDetailsHash, bool favorSubmitter)
    {
        Dispute storage dispute = disputes[_disputeId];
         // Basic check if dispute exists
        require(dispute.submissionTime > 0, "Dispute does not exist");

        return (
            dispute.id,
            dispute.disputeType,
            dispute.entityId,
            dispute.submitter,
            dispute.reasonHash,
            dispute.submissionTime,
            dispute.status,
            dispute.resolver,
            dispute.resolutionDetailsHash,
            dispute.favorSubmitter
        );
    }


    // --- 12. Pause/Unpause ---

    function pause() external onlyGovernor whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyGovernor whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Off-chain Computation Management:** The contract doesn't *run* AI, but it's the central ledger for *who can request* AI computation (`purchaseModelAccess`, `requestInference`) and *how results are recorded and paid for* (`fulfillInferenceCallback`, `withdrawEarnings`). This pattern is essential for integrating blockchain with computationally heavy off-chain services.
2.  **Oracle Integration:** The explicit reliance on a trusted `oracleAddress` and a `fulfillInferenceCallback` models the interaction needed for a smart contract to trigger and receive results from external systems (like AI model runners). The `oracleRequestId` is a standard pattern for linking async requests/responses.
3.  **Staking for Provider Reliability:** The `stakeForModel` and `withdrawStake` functions, tied to `stakeRequired` and penalizable via disputes, create an economic incentive for providers to be honest and keep their models accessible and functional. This builds trust in a decentralized setting.
4.  **Reputation System:** While simple aggregation (`averageRatingNumerator`, `averageRatingDenominator`) is used, the `submitModelRating` and `submitProviderRating` functions lay the groundwork for an on-chain reputation system. This could be extended with quadratic voting, time-decaying scores, or tying ratings to specific, verified usage events.
5.  **Dispute Resolution:** The `disputeInferenceResult`, `disputeAccessGrant`, and `resolveDispute` functions provide a structured, on-chain mechanism for handling disagreements. Governance (the Governors) acts as the decentralized judiciary. The ability to potentially penalize provider stake or refund users based on dispute outcomes adds significant complexity and economic interaction.
6.  **Access Grants:** Instead of just a one-time payment, the `AccessGrant` with `remainingUses` introduces a simple form of usage-based licensing managed on-chain. This could be extended to time-based subscriptions or other models.
7.  **Separation of Roles:** Clearly defining Provider, User, and Governor roles with specific permissions adds structure necessary for a complex decentralized application.
8.  **Versioning:** `setModelVersion` allows providers to update their models while maintaining a history or clear transition point, important for evolving AI models.

This contract goes beyond basic token transfers or simple interactions by managing access to external services, incorporating economic incentives for reliability, building a reputation layer, and including a governance-based dispute system, all while handling multi-party payment flows. The design choices (like using Ether, simple structs, a conceptual oracle) keep the code manageable for demonstration but highlight the core advanced concepts.